import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';

/// 通用卡片：1:1 还原 iOS 白色圆角卡片。
/// iOS 参照：xinyuiOS XYHomeStyle 卡片样式
/// （白底、圆角 12/16、投影 #E6EAEE @50% offset(0,3) blur 6、内边距 15）。
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppDimens.cardPadding),
    this.radius = AppDimens.cardRadius,
    this.color,
    this.onTap,
  });

  final Widget child;

  /// 内边距，默认 15（AppDimens.cardPadding）
  final EdgeInsetsGeometry padding;

  /// 圆角，默认 12，大卡片可传 AppDimens.cardRadiusLarge（16）
  final double radius;

  /// 底色，默认白色卡片底
  final Color? color;

  /// 可选点击回调（整个卡片热区）
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Widget card = Container(
      decoration: BoxDecoration(
        color: color ?? AppColors.cardBackground,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow.withValues(
              alpha: AppDimens.cardShadowOpacity,
            ),
            offset: const Offset(0, AppDimens.cardShadowOffsetY),
            blurRadius: AppDimens.cardShadowBlur,
          ),
        ],
      ),
      padding: padding,
      child: child,
    );
    if (onTap == null) return card;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: card,
    );
  }
}
