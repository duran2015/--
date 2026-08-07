import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_response.dart';
import '../../core/router/route_paths.dart';
import '../../core/storage/local_flags.dart';
import '../../core/theme/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_background.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_loading_hud.dart';
import '../../core/widgets/app_toast.dart';
import '../../utils/load_image.dart';
import 'apple_auth_service.dart';
import 'auth_api.dart';
import 'auth_view_model.dart';
import 'wechat_auth_service.dart';
import 'widgets/agreement_dialog.dart';

/// 注释：手机号登录页（全屏幕 ScreenUtil 响应式规范）
/// 时间：2026/8/4
/// 作者：郭翰林
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final TextEditingController _phoneController = TextEditingController();
  bool _agreed = false;
  bool _phoneValid = false;
  bool _consultantIntent = false;

  bool? _wechatInstalled;
  bool _thirdPartyLoading = false;
  String _thirdPartyLoadingMessage = '';

  bool get _showAppleLogin => !kIsWeb && Platform.isIOS;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_onPhoneChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(authViewModelProvider.notifier).loadLatestAgreements();
      await _maybeShowAgreementDialog();
      if (!mounted) return;
      final flags = await ref.read(localFlagsProvider.future);
      if (mounted) {
        setState(() =>
            _consultantIntent = flags.loginIdentityIntent == 'consultant');
      }
      if (flags.isAgreementAccepted) {
        await ref.read(wechatAuthServiceProvider).initialize();
        _refreshWechatInstalled();
      }
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _refreshWechatInstalled() async {
    final installed =
        await ref.read(wechatAuthServiceProvider).isWeChatInstalled();
    if (mounted) setState(() => _wechatInstalled = installed);
  }

  Future<void> _maybeShowAgreementDialog() async {
    final flags = await ref.read(localFlagsProvider.future);
    if (!mounted || flags.isAgreementAccepted) return;
    final vmState = ref.read(authViewModelProvider);
    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AgreementDialog(
        serviceUrl: vmState.serviceAgreementUrl,
        privacyUrl: vmState.privacyPolicyUrl,
      ),
    );
    if (accepted == true) {
      await flags.markAgreementAccepted();
      if (mounted) setState(() => _agreed = true);
    } else {
      await SystemNavigator.pop();
    }
  }

  void _onPhoneChanged() {
    final valid =
        _PhoneUtils.isValid(_PhoneUtils.digits(_phoneController.text));
    if (valid != _phoneValid) setState(() => _phoneValid = valid);
  }

  /// 将登录页当前展示的身份模式写成一次性登录意图。
  ///
  /// 不能只在点击“我是咨询师/切换为用户”时写入：页面默认展示用户模式时，
  /// 用户可能直接输入手机号提交；若不写入 user，分流会错误回退到历史身份。
  Future<void> _persistVisibleLoginIdentity() async {
    final flags = await ref.read(localFlagsProvider.future);
    await flags.setLoginIdentityIntent(
      _consultantIntent ? 'consultant' : 'user',
    );
  }

  Future<void> _onGetCodeTapped() async {
    if (!_agreed) {
      AppToast.show(context, '请同意用户协议和隐私政策');
      return;
    }
    final phone = _PhoneUtils.digits(_phoneController.text);
    if (!_PhoneUtils.isValid(phone)) {
      AppToast.show(context, '请输入正确的手机号');
      return;
    }
    if (ref.read(authViewModelProvider).sending) return;
    try {
      await _persistVisibleLoginIdentity();
      await ref.read(authViewModelProvider.notifier).sendLoginSmsCode(phone);
      if (!mounted) return;
      context.push('${RoutePaths.loginVerify}?phone=$phone');
    } on ApiException catch (e) {
      if (mounted) AppToast.show(context, e.msg);
    } catch (_) {
      if (mounted) AppToast.show(context, '网络异常，请稍后重试');
    }
  }

  Future<void> _routeAfterThirdPartyLogin(WechatLoginData result) async {
    if (result.needBindPhone) {
      context.push(
        Uri(
          path: RoutePaths.loginBindPhone,
          queryParameters: {
            'preAuthToken': result.preAuthToken ?? '',
            if (result.nickName?.isNotEmpty ?? false)
              'nickName': result.nickName!,
            if (result.avatar?.isNotEmpty ?? false) 'avatar': result.avatar!,
          },
        ).toString(),
      );
    } else {
      final route = await ref
          .read(authViewModelProvider.notifier)
          .resolveAfterExternalLogin(result.loginData!);
      if (!mounted) return;
      context.go(route);
    }
  }

  Future<void> _onWechatTapped() async {
    if (!_agreed) {
      AppToast.show(context, '请同意用户协议和隐私政策');
      return;
    }
    setState(() {
      _thirdPartyLoading = true;
      _thirdPartyLoadingMessage = '微信登录中';
    });
    try {
      await _persistVisibleLoginIdentity();
      final code = await ref.read(wechatAuthServiceProvider).authCode();
      if (!mounted) return;
      final result =
          await ref.read(authViewModelProvider.notifier).loginByWechat(code);
      if (!mounted) return;
      await _routeAfterThirdPartyLogin(result);
    } on WechatAuthException catch (e) {
      if (mounted) AppToast.show(context, e.message);
    } on ApiException catch (e) {
      if (mounted) AppToast.show(context, e.msg);
    } finally {
      if (mounted) setState(() => _thirdPartyLoading = false);
    }
  }

  Future<void> _onAppleTapped() async {
    if (!_agreed) {
      AppToast.show(context, '请同意用户协议和隐私政策');
      return;
    }
    setState(() {
      _thirdPartyLoading = true;
      _thirdPartyLoadingMessage = 'Apple 登录中';
    });
    try {
      await _persistVisibleLoginIdentity();
      final credential = await ref.read(appleAuthServiceProvider).authorize();
      if (!mounted) return;
      final result =
          await ref.read(authViewModelProvider.notifier).loginByApple(
                identityToken: credential.identityToken,
                nickName: credential.nickName,
              );
      if (!mounted) return;
      await _routeAfterThirdPartyLogin(result);
    } on AppleAuthException catch (e) {
      if (e.canceled) return;
      if (mounted) AppToast.show(context, e.message);
    } on ApiException catch (e) {
      if (mounted) AppToast.show(context, e.msg);
    } finally {
      if (mounted) setState(() => _thirdPartyLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vmState = ref.watch(authViewModelProvider);
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: AppPageBackground(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => FocusScope.of(context).unfocus(),
                child: SafeArea(
                  child: _ScrollableColumn(
                    children: [
                      AppDimens.loginTopPicTopOffset.verticalSpace,
                      LoadImage(
                        AppAssets.loginTopPic,
                        width: AppDimens.loginTopPicWidth.w,
                        height: AppDimens.loginTopPicHeight.h,
                        fit: BoxFit.contain,
                      ),
                      AppDimens.loginPhoneToTopPicGap.verticalSpace,
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppDimens.loginPadding.w,
                        ),
                        child: _buildPhoneInput(),
                      ),
                      AppDimens.gap15.verticalSpace,
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppDimens.loginPadding.w,
                        ),
                        child: Opacity(
                          opacity: _phoneValid
                              ? 1
                              : AppDimens.loginButtonDisabledAlpha,
                          child: AppPrimaryButton(
                            text: '获取验证码',
                            onPressed: _onGetCodeTapped,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final next = !_consultantIntent;
                          final flags =
                              await ref.read(localFlagsProvider.future);
                          await flags.setLoginIdentityIntent(
                            // 切回用户端必须写入明确的 user 意图。若写空，
                            // 登录分流会继续回退到上一次使用的 consultant 身份。
                            next ? 'consultant' : 'user',
                          );
                          if (mounted) {
                            setState(() => _consultantIntent = next);
                          }
                        },
                        child: Text(
                          _consultantIntent ? '咨询师登录模式 · 切换为用户' : '我是咨询师',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      const Spacer(),
                      _buildThirdPartySection(),
                      AppDimens.thirdPartyToAgreementGap.verticalSpace,
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppDimens.loginAgreementInset.w,
                        ),
                        child: AgreementConsentRow(
                          agreed: _agreed,
                          serviceUrl: vmState.serviceAgreementUrl,
                          privacyUrl: vmState.privacyPolicyUrl,
                          onChanged: (agreed) =>
                              setState(() => _agreed = agreed),
                        ),
                      ),
                      AppDimens.gap8.verticalSpace,
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (vmState.sending)
            const Positioned.fill(
              child: AppLoadingHud(message: '发送中'),
            ),
          if (_thirdPartyLoading)
            Positioned.fill(
              child: AppLoadingHud(message: _thirdPartyLoadingMessage),
            ),
        ],
      ),
    );
  }

  Widget _buildThirdPartySection() {
    final showWechat = _wechatInstalled == true;
    final showApple = _showAppleLogin;
    if (!showWechat && !showApple) return const SizedBox.shrink();

    final children = <Widget>[
      if (showWechat)
        GestureDetector(
          onTap: _onWechatTapped,
          child: LoadImage(
            AppAssets.loginWechat,
            width: AppDimens.thirdPartyIconSize.w,
            height: AppDimens.thirdPartyIconSize.w,
            fit: BoxFit.contain,
          ),
        ),
      if (showApple)
        GestureDetector(
          onTap: _onAppleTapped,
          child: const _AppleLoginButton(),
        ),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) AppDimens.thirdPartyIconGap.horizontalSpace,
          children[i],
        ],
      ],
    );
  }

  Widget _buildPhoneInput() {
    final colors = Theme.of(context).colorScheme;
    return Container(
      height: AppDimens.loginInputHeight.h,
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          Positioned(
            left: AppDimens.gap20.w,
            child: Text(
              '+86',
              style: AppTextStyles.titleLarge.copyWith(fontSize: 18.sp),
            ),
          ),
          Positioned(
            left: AppDimens.loginCountryCodeDividerLeft.w,
            child: SizedBox(
              width: 1.w,
              height: AppDimens.loginCountryCodeDividerHeight.h,
              child: const ColoredBox(color: AppColors.lightPurpleDivider),
            ),
          ),
          Positioned(
            left:
                (AppDimens.loginCountryCodeDividerLeft + 1 + AppDimens.gap12).w,
            right: AppDimens.gap16.w,
            top: 0,
            bottom: 0,
            child: Center(
              child: TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [_PhoneInputFormatter()],
                style: AppTextStyles.titleLarge.copyWith(fontSize: 18.sp),
                cursorColor: AppColors.brandTeal,
                decoration: InputDecoration(
                  filled: false,
                  hintText: '请输入手机号',
                  hintStyle: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.w400,
                    color: AppColors.placeholder,
                    fontSize: 18.sp,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  isCollapsed: true,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppleLoginButton extends StatelessWidget {
  const _AppleLoginButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppDimens.thirdPartyIconSize.w,
      height: AppDimens.thirdPartyIconSize.w,
      decoration: const BoxDecoration(
        color: Colors.black,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.apple,
        color: Colors.white,
        size: AppDimens.appleIconPointSize.r,
      ),
    );
  }
}

class _PhoneUtils {
  _PhoneUtils._();

  static const int maxDigits = 11;
  static final RegExp _pattern = RegExp(r'^1[3-9]\d{9}$');

  static String digits(String text) {
    final all = text.replaceAll(RegExp(r'\D'), '');
    return all.length > maxDigits ? all.substring(0, maxDigits) : all;
  }

  static bool isValid(String phone) => _pattern.hasMatch(phone);
}

class _PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = _PhoneUtils.digits(newValue.text);
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i == 3 || i == 7) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class _ScrollableColumn extends StatelessWidget {
  const _ScrollableColumn({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: IntrinsicHeight(
            child: Column(children: children),
          ),
        ),
      ),
    );
  }
}
