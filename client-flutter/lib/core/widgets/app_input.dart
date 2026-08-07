import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';

/// 注释：通用输入框（全屏幕 ScreenUtil 响应式规范）
/// 时间：2026/8/4
/// 作者：郭翰林
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.hintText,
    this.keyboardType,
    this.obscureText = false,
    this.maxLength,
    this.onChanged,
    this.suffix,
  });

  final TextEditingController? controller;
  final String? hintText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int? maxLength;
  final ValueChanged<String>? onChanged;

  /// 右侧附加内容（如清除按钮、眼睛开关）
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    final inputStyle = AppTextStyles.titleLarge.copyWith(
      fontWeight: FontWeight.w400,
      fontSize: 18.sp,
    );
    final hintStyle = inputStyle.copyWith(
      color: AppColors.placeholder,
    );

    return Container(
      height: AppDimens.loginInputHeight.h,
      decoration: BoxDecoration(
        color: AppColors.innerBackground,
        borderRadius: BorderRadius.circular(AppDimens.cardRadius.r),
      ),
      padding: EdgeInsets.symmetric(horizontal: AppDimens.cardPadding.w),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              obscureText: obscureText,
              maxLength: maxLength,
              onChanged: onChanged,
              style: inputStyle,
              cursorColor: AppColors.brandTeal,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: hintStyle,
                border: InputBorder.none,
                isCollapsed: true,
                counterText: '',
              ),
            ),
          ),
          if (suffix != null) ...[
            AppDimens.gap8.horizontalSpace,
            suffix!,
          ],
        ],
      ),
    );
  }
}

/// 注释：验证码输入框
/// 时间：2026/8/4
/// 作者：郭翰林
class AppSmsCodeField extends StatefulWidget {
  const AppSmsCodeField({
    super.key,
    this.controller,
    this.hintText = '请输入验证码',
    required this.onSend,
    this.countdownSeconds = 60,
  });

  final TextEditingController? controller;
  final String hintText;
  final VoidCallback onSend;
  final int countdownSeconds;

  @override
  State<AppSmsCodeField> createState() => _AppSmsCodeFieldState();
}

class _AppSmsCodeFieldState extends State<AppSmsCodeField> {
  Timer? _timer;
  int _remain = 0;

  bool get _countingDown => _remain > 0;

  void _handleSend() {
    if (_countingDown) return;
    widget.onSend();
    _startCountdown();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _remain = widget.countdownSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
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

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: widget.controller,
      hintText: widget.hintText,
      keyboardType: TextInputType.number,
      suffix: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _handleSend,
        child: Text(
          _countingDown ? '${_remain}s 重发' : '获取验证码',
          style: AppTextStyles.bodyLarge.copyWith(
            color: _countingDown
                ? AppColors.textTertiary
                : AppColors.brandTeal,
            fontSize: 14.sp,
          ),
        ),
      ),
    );
  }
}
