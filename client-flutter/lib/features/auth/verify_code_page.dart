import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_response.dart';
import '../../core/router/route_paths.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_background.dart';
import '../../core/widgets/app_loading_hud.dart';
import '../../core/widgets/app_nav_bar.dart';
import '../../core/widgets/app_toast.dart';
import 'auth_view_model.dart';

/// 验证码页用途
enum VerifyCodeMode {
  login,
  wechatBind,
}

/// 注释：短信验证码输入页（全屏幕 ScreenUtil 响应式规范）
/// 时间：2026/8/4
/// 作者：郭翰林
class VerifyCodePage extends ConsumerStatefulWidget {
  const VerifyCodePage({
    super.key,
    required this.phone,
    this.mode = VerifyCodeMode.login,
    this.preAuthToken = '',
  });

  final String phone;
  final VerifyCodeMode mode;
  final String preAuthToken;

  static const int codeLength = 6;
  static const int countdownSeconds = 60;

  @override
  ConsumerState<VerifyCodePage> createState() => _VerifyCodePageState();
}

class _VerifyCodePageState extends ConsumerState<VerifyCodePage> {
  final TextEditingController _codeController = TextEditingController();
  final FocusNode _codeFocusNode = FocusNode();

  Timer? _countdownTimer;
  int _remain = VerifyCodePage.countdownSeconds;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _codeFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _codeController.dispose();
    _codeFocusNode.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() => _remain = VerifyCodePage.countdownSeconds);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _remain -= 1;
        if (_remain <= 0) {
          _remain = 0;
          timer.cancel();
        }
      });
    });
  }

  void _onCodeChanged(String code) {
    setState(() {});
    if (code.length == VerifyCodePage.codeLength && !_submitting) {
      _submit(code);
    }
  }

  Future<void> _submit(String code) async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      final vm = ref.read(authViewModelProvider.notifier);
      final route = widget.mode == VerifyCodeMode.wechatBind
          ? await vm.bindPhoneByWechat(
              phone: widget.phone,
              smsCode: code,
              preAuthToken: widget.preAuthToken,
            )
          : await vm.loginByPhone(phone: widget.phone, smsCode: code);
      if (!mounted) return;
      _codeFocusNode.unfocus();
      if (route == RoutePaths.loginSelectIdentity) {
        context.push(route);
      } else {
        context.go(route);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      AppToast.show(context, e.msg);
    } catch (_) {
      if (!mounted) return;
      AppToast.show(context, '网络异常，请稍后重试');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _onResendTapped() async {
    if (_remain > 0) return;
    _codeController.clear();
    _onCodeChanged('');
    _codeFocusNode.requestFocus();
    try {
      await ref
          .read(authViewModelProvider.notifier)
          .resendSmsCode(widget.phone);
      if (!mounted) return;
      _startCountdown();
      AppToast.show(context, '验证码已发送');
    } on ApiException catch (e) {
      if (mounted) AppToast.show(context, e.msg);
    }
  }

  String get _maskedPhone {
    final phone = widget.phone;
    if (phone.length != 11) return '+86 $phone';
    return '+86 ${phone.substring(0, 3)}****${phone.substring(7)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppPageBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppNavBar(title: '', transparent: true),
                  Padding(
                    padding: EdgeInsets.only(
                      top: AppDimens.gap16.h,
                      left: AppDimens.loginPadding.w,
                      right: AppDimens.loginPadding.w,
                    ),
                    child: Text(
                      '请输入验证码',
                      style: AppTextStyles.titleXLarge.copyWith(fontSize: 20.sp),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                      top: AppDimens.gap12.h,
                      left: AppDimens.loginPadding.w,
                      right: AppDimens.loginPadding.w,
                    ),
                    child: Text(
                      '验证码已发送至 $_maskedPhone',
                      style: AppTextStyles.body.copyWith(fontSize: 13.sp),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                      top: AppDimens.loginPhoneToTopPicGap.h,
                      left: AppDimens.loginPadding.w,
                      right: AppDimens.loginPadding.w,
                    ),
                    child: _buildCodeInput(),
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                      top: AppDimens.gap16.h,
                      right: AppDimens.loginPadding.w,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '接收不到验证码？',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textTertiary,
                            fontSize: 13.sp,
                          ),
                        ),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _onResendTapped,
                          child: Text(
                            _remain > 0 ? '${_remain}s' : '重新获取',
                            style: AppTextStyles.body.copyWith(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w500,
                              color: _remain > 0
                                  ? AppColors.textTertiary
                                  : AppColors.brandTeal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_submitting)
                const Positioned.fill(
                  child: AppLoadingHud(message: '登录中'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCodeInput() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxSide = ((constraints.maxWidth -
                    (VerifyCodePage.codeLength - 1) *
                        AppDimens.verifyCodeBoxGap.w) /
                VerifyCodePage.codeLength)
            .floorToDouble();
        final code = _codeController.text;
        final activeIndex =
            code.length >= VerifyCodePage.codeLength - 1 ? 5 : code.length;
        return GestureDetector(
          onTap: () => _codeFocusNode.requestFocus(),
          child: SizedBox(
            height: boxSide,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Opacity(
                    opacity: 0,
                    child: TextField(
                      controller: _codeController,
                      focusNode: _codeFocusNode,
                      keyboardType: TextInputType.number,
                      maxLength: VerifyCodePage.codeLength,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: _onCodeChanged,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        counterText: '',
                      ),
                    ),
                  ),
                ),
                IgnorePointer(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(VerifyCodePage.codeLength, (index) {
                      final active = index == activeIndex;
                      return Container(
                        width: boxSide,
                        height: boxSide,
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(
                            AppDimens.verifyCodeBoxRadius.r,
                          ),
                          border: active
                              ? Border.all(color: AppColors.brandTeal)
                              : null,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.codeBoxShadow,
                              offset: Offset(0, 1.h),
                              blurRadius: 2.r,
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          index < code.length ? code[index] : '',
                          style: AppTextStyles.codeDigit.copyWith(fontSize: 24.sp),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
