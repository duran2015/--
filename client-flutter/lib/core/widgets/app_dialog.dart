import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';

/// 居中弹窗：1:1 还原 iOS XYCenterAlertView。
/// iOS 参照：xinyuiOS XYCenterAlertView
/// （白底圆角 16，标题 16 w600、内容 14 #666、按钮区高 44 顶部分割线；
/// 支持单按钮 / 左右双按钮：左取消 #666、右确认 brandTeal）。
class AppCenterDialog extends StatelessWidget {
  const AppCenterDialog({
    super.key,
    required this.title,
    required this.content,
    this.cancelText,
    this.confirmText = '确定',
    this.confirmColor,
  });

  final String title;
  final String content;

  /// 取消按钮文案；为 null 时只显示单个确认按钮
  final String? cancelText;

  final String confirmText;

  /// 确认按钮颜色；默认 brandTeal。
  /// iOS 参照：XYCenterAlertView confirmDestructive → systemRed。
  final Color? confirmColor;

  /// 弹窗固定宽度（iOS XYCenterAlertView 宽度）
  static const double _dialogWidth = 280;

  /// 按钮间竖向分割线宽
  static const double _dividerWidth = 0.5;

  /// 弹出居中弹窗。
  /// 返回 `Future<bool?>`：确认 true，取消 false，遮罩关闭 null。
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String content,
    String? cancelText,
    String confirmText = '确定',
    Color? confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AppCenterDialog(
        title: title,
        content: content,
        cancelText: cancelText,
        confirmText: confirmText,
        confirmColor: confirmColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Container(
        width: _dialogWidth,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppDimens.cardRadiusLarge),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题 16 w600
            Padding(
              padding: const EdgeInsets.only(
                top: AppDimens.gap20,
                left: AppDimens.gap20,
                right: AppDimens.gap20,
              ),
              child: Text(
                title,
                style: AppTextStyles.title,
                textAlign: TextAlign.center,
              ),
            ),
            // 内容 14 #666
            Padding(
              padding: const EdgeInsets.only(
                top: AppDimens.gap12,
                bottom: AppDimens.gap20,
                left: AppDimens.gap20,
                right: AppDimens.gap20,
              ),
              child: Text(
                content,
                style: AppTextStyles.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ),
            // 按钮区：高 44，顶部分割线
            const Divider(
              height: _dividerWidth,
              thickness: _dividerWidth,
              color: AppColors.divider,
            ),
            SizedBox(
              height: AppDimens.dialogButtonHeight,
              child: cancelText == null
                  ? _buildButton(
                      context,
                      text: confirmText,
                      color: confirmColor ?? AppColors.brandTeal,
                      result: true,
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: _buildButton(
                            context,
                            text: cancelText!,
                            color: AppColors.textSecondary,
                            result: false,
                          ),
                        ),
                        const VerticalDivider(
                          width: _dividerWidth,
                          thickness: _dividerWidth,
                          color: AppColors.divider,
                        ),
                        Expanded(
                          child: _buildButton(
                            context,
                            text: confirmText,
                            color: confirmColor ?? AppColors.brandTeal,
                            result: true,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(
    BuildContext context, {
    required String text,
    required Color color,
    required bool result,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).pop(result),
      child: Center(
        child: Text(
          text,
          style: AppTextStyles.bodyLargeStrong.copyWith(color: color),
        ),
      ),
    );
  }
}
