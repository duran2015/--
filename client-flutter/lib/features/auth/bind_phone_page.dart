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
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_loading_hud.dart';
import '../../core/widgets/app_nav_bar.dart';
import '../../core/widgets/app_toast.dart';
import '../../utils/load_image.dart';
import 'auth_view_model.dart';

/// 注释：微信登录后绑定手机号页（全屏幕 ScreenUtil 响应式规范）
/// 时间：2026/8/4
/// 作者：郭翰林
class BindPhonePage extends ConsumerStatefulWidget {
  const BindPhonePage({
    super.key,
    required this.preAuthToken,
    this.nickName,
    this.avatar,
  });

  final String preAuthToken;
  final String? nickName;
  final String? avatar;

  @override
  ConsumerState<BindPhonePage> createState() => _BindPhonePageState();
}

class _BindPhonePageState extends ConsumerState<BindPhonePage> {
  final TextEditingController _phoneController = TextEditingController();
  bool _phoneValid = false;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_onPhoneChanged);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _onPhoneChanged() {
    final valid = _BindPhoneValidators.isValid(_phoneController.text);
    if (valid != _phoneValid) setState(() => _phoneValid = valid);
  }

  Future<void> _onGetCodeTapped() async {
    final phone = _phoneController.text;
    if (!_BindPhoneValidators.isValid(phone)) {
      AppToast.show(context, '请输入正确的手机号');
      return;
    }
    try {
      await ref.read(authViewModelProvider.notifier).sendLoginSmsCode(phone);
      if (!mounted) return;
      context.push(
        Uri(
          path: RoutePaths.loginVerify,
          queryParameters: {
            'phone': phone,
            'mode': 'wechatBind',
            'preAuthToken': widget.preAuthToken,
          },
        ).toString(),
      );
    } on ApiException catch (e) {
      if (mounted) AppToast.show(context, e.msg);
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
                  child: Column(
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
                          '绑定手机号',
                          style: AppTextStyles.titleXLarge
                              .copyWith(fontSize: 20.sp),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                          top: AppDimens.gap8.h,
                          left: AppDimens.loginPadding.w,
                          right: AppDimens.loginPadding.w,
                        ),
                        child: Text(
                          '应国家网络安全相关法律法规要求，继续使用需绑定您的真实手机号。',
                          style: AppTextStyles.body.copyWith(fontSize: 13.sp),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                          top: AppDimens.bindCardTopGap.h,
                          left: AppDimens.loginPadding.w,
                          right: AppDimens.loginPadding.w,
                        ),
                        child: _buildUserInfoCard(),
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                          top: AppDimens.bindInputTopGap.h,
                          left: AppDimens.loginPadding.w,
                          right: AppDimens.loginPadding.w,
                        ),
                        child: _buildPhoneInput(),
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                          top: AppDimens.gap15.h,
                          left: AppDimens.loginPadding.w,
                          right: AppDimens.loginPadding.w,
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
        ],
      ),
    );
  }

  Widget _buildUserInfoCard() {
    final nickName = widget.nickName;
    return Container(
      height: AppDimens.bindCardHeight.h,
      decoration: BoxDecoration(
        color: AppColors.brandTealLight,
        borderRadius: BorderRadius.circular(AppDimens.cardRadius.r),
      ),
      child: Row(
        children: [
          AppDimens.bindAvatarLeading.horizontalSpace,
          _buildAvatar(),
          AppDimens.gap10.horizontalSpace,
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                (nickName != null && nickName.isNotEmpty) ? nickName : '微信用户',
                style: AppTextStyles.bodyLargeStrong.copyWith(fontSize: 14.sp),
              ),
              2.verticalSpace,
              Text(
                '已授权获取基础信息',
                style: AppTextStyles.label.copyWith(fontSize: 11.sp),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    final url = widget.avatar;
    const placeholder = _AvatarPlaceholder();
    if (url == null || url.isEmpty) return placeholder;
    return ClipOval(
      child: LoadImage(
        url,
        width: AppDimens.bindAvatarSize.w,
        height: AppDimens.bindAvatarSize.w,
        fit: BoxFit.cover,
        errorWidget: placeholder,
      ),
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
                inputFormatters: [LengthLimitingTextInputFormatter(11)],
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

class _AvatarPlaceholder extends StatelessWidget {
  const _AvatarPlaceholder();

  static const Color _bg = Color(0xFFE4E4E4);
  static const Color _tint = Color(0xFFBFBFBF);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppDimens.bindAvatarSize.w,
      height: AppDimens.bindAvatarSize.w,
      decoration: const BoxDecoration(color: _bg, shape: BoxShape.circle),
      child: Icon(Icons.account_circle, color: _tint, size: 32.r),
    );
  }
}

class _BindPhoneValidators {
  _BindPhoneValidators._();

  static final RegExp _pattern = RegExp(r'^1[3-9]\d{9}$');

  static bool isValid(String phone) => _pattern.hasMatch(phone);
}
