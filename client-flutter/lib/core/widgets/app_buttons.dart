import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';

/// 注释：渐变胶囊主按钮（全屏幕 ScreenUtil 响应式规范）
/// 时间：2026/8/4
/// 作者：郭翰林
class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.loading = false,
    this.width,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool loading;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return _GradientCapsuleButton(
      text: text,
      onPressed: onPressed,
      loading: loading,
      width: width,
      height: AppDimens.buttonHeight.h,
      radius: AppDimens.buttonRadiusCapsule.r,
      gradient: AppColors.brandButtonGradient,
    );
  }
}

/// 注释：咨询师端渐变主按钮
/// 时间：2026/8/4
/// 作者：郭翰林
class AppIndigoButton extends StatelessWidget {
  const AppIndigoButton({
    super.key,
    required this.text,
    this.onPressed,
    this.loading = false,
    this.width,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool loading;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return _GradientCapsuleButton(
      text: text,
      onPressed: onPressed,
      loading: loading,
      width: width,
      height: AppDimens.buttonHeight.h,
      radius: AppDimens.buttonRadiusCapsule.r,
      gradient: AppColors.indigoButtonGradient,
    );
  }
}

/// 注释：次按钮
/// 时间：2026/8/4
/// 作者：郭翰林
class AppSecondaryButton extends StatelessWidget {
  const AppSecondaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.width,
  });

  final String text;
  final VoidCallback? onPressed;
  final double? width;

  static const double _borderWidth = 1;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null;
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: width ?? double.infinity,
        height: AppDimens.buttonHeightSmall.h,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular((AppDimens.buttonHeightSmall / 2).r),
          border: Border.all(
            color: enabled ? AppColors.brandTeal : AppColors.placeholder,
            width: _borderWidth,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: AppTextStyles.bodyLarge.copyWith(
            color: enabled ? AppColors.brandTeal : AppColors.placeholder,
            fontSize: 14.sp,
          ),
        ),
      ),
    );
  }
}

/// 注释：渐变胶囊按钮内部实现
/// 时间：2026/8/4
/// 作者：郭翰林
class _GradientCapsuleButton extends StatelessWidget {
  const _GradientCapsuleButton({
    required this.text,
    required this.onPressed,
    required this.loading,
    required this.width,
    required this.height,
    required this.radius,
    required this.gradient,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool loading;
  final double? width;
  final double height;
  final double radius;
  final Gradient gradient;

  static const double _loadingStrokeWidth = 2;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null && !loading;
    return GestureDetector(
      onTap: enabled ? onPressed : null,
      child: Container(
        width: width ?? double.infinity,
        height: height,
        decoration: BoxDecoration(
          gradient: enabled ? gradient : null,
          color: enabled ? null : AppColors.placeholder,
          borderRadius: BorderRadius.circular(radius),
        ),
        alignment: Alignment.center,
        child: loading
            ? SizedBox(
                width: 20.w,
                height: 20.w,
                child: const CircularProgressIndicator(
                  strokeWidth: _loadingStrokeWidth,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                text,
                style: AppTextStyles.title.copyWith(
                  color: Colors.white,
                  fontSize: 16.sp,
                ),
              ),
      ),
    );
  }
}
