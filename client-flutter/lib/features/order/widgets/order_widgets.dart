import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/person_avatar.dart';
import '../order_action.dart';

/// 擅长（青）+ 风格（紫）标签自动换行流。
/// iOS 参照：XYAIModule/XYAIModule/Classes/View/XYOrderTagFlowView.swift
/// （字号 11、内边距 6/3、圆角 3、行/列间距 6）。
class OrderTagFlow extends StatelessWidget {
  const OrderTagFlow({
    super.key,
    required this.specialtyTags,
    required this.styleTags,
  });

  final List<String> specialtyTags;
  final List<String> styleTags;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final tag in specialtyTags)
          _chip(tag, AppColors.brandTeal, AppColors.brandTealLight),
        for (final tag in styleTags)
          _chip(tag, AppColors.indigo, AppColors.purpleTagBg),
      ],
    );
  }

  Widget _chip(String text, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppDimens.radiusTiny),
      ),
      child: Text(
        text,
        style: AppTextStyles.label.copyWith(color: textColor),
      ),
    );
  }
}

/// 累计服务时长胶囊（#F1F4FB 底、10 号 #666、圆角 3、内边距 6/2；空文案不展示）。
/// iOS 参照：XYAppointmentOrderCell servicePill。
class OrderServicePill extends StatelessWidget {
  const OrderServicePill({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.pageBackground,
        borderRadius: BorderRadius.circular(AppDimens.radiusTiny),
      ),
      child: Text(
        text,
        style: AppTextStyles.badge.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}

/// 订单咨询师圆形头像（#E8E8E8 底；无 URL 时青色人形占位）。
/// iOS 参照：XYAppointmentOrderCell.configureAvatar。
class OrderAvatar extends StatelessWidget {
  const OrderAvatar({
    super.key,
    this.url,
    required this.size,
    this.name = '',
    this.seed = '',
  });

  final String? url;
  final double size;
  final String name;
  final String seed;

  @override
  Widget build(BuildContext context) {
    return PersonAvatar(
      name: name,
      seed: seed.isEmpty ? name : seed,
      size: size,
      imageUrl: url,
    );
  }
}

/// 订单状态徽标（右上角，高 20、11 号、左右内边距 10、贴卡片右上圆角）。
/// iOS 参照：XYAppointmentOrderCell.configureStatusBadge——
/// unpaid → #FF3D3D/#FFECE9；not_consulted/consulting → #00A6A1/#E9FAFF；
/// 其他 → #666/#F6F6F6。
class OrderStatusBadge extends StatelessWidget {
  const OrderStatusBadge({
    super.key,
    required this.text,
    required this.displayStatus,
  });

  final String text;
  final String? displayStatus;

  /// 状态文字颜色（详情页状态文案同规则）。
  static Color textColorOf(String? displayStatus) {
    switch (displayStatus) {
      case OrderActionRouter.statusUnpaid:
        return AppColors.priceRed;
      case OrderActionRouter.statusNotConsulted:
      case OrderActionRouter.statusConsulting:
        return AppColors.brandTeal;
      default:
        return AppColors.textSecondary;
    }
  }

  static Color _bgColorOf(String? displayStatus) {
    switch (displayStatus) {
      case OrderActionRouter.statusUnpaid:
        return AppColors.badgeBgRed;
      case OrderActionRouter.statusNotConsulted:
      case OrderActionRouter.statusConsulting:
        return AppColors.brandTealLight;
      default:
        return AppColors.badgeBgGray;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: _bgColorOf(displayStatus),
        // 与卡片右上角圆角贴合：仅右上/左下圆角（iOS maskedCorners）
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(AppDimens.cardRadius),
          bottomLeft: Radius.circular(AppDimens.cardRadius),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: AppTextStyles.label.copyWith(color: textColorOf(displayStatus)),
      ),
    );
  }
}

/// 订单渐变胶囊按钮（32 高、13 semibold 白字、左右内边距 16、圆角 16）。
/// iOS 参照：XYAppointmentOrderCell setupStatusButton——
/// 去支付用红渐变 #FF7B5E→#FF5C71；联系/评价用青渐变 #00D8E0→#00AFBE。
class OrderGradientPillButton extends StatelessWidget {
  const OrderGradientPillButton({
    super.key,
    required this.title,
    required this.gradient,
    this.onTap,
    this.height = 32,
    this.fontSize = 13,
  });

  final String title;
  final Gradient gradient;
  final VoidCallback? onTap;
  final double height;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(height / 2),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// 主按钮动作 → 按钮标题（iOS Cell 固定标题：去支付/联系咨询师/评价咨询师）。
String orderPrimaryActionTitle(OrderPrimaryAction action) {
  switch (action) {
    case OrderPrimaryAction.pay:
      return '去支付';
    case OrderPrimaryAction.fillIntake:
      return '填写资料';
    case OrderPrimaryAction.enterSession:
      return '进入咨询';
    case OrderPrimaryAction.viewRecap:
      return '查看回顾';
    case OrderPrimaryAction.contact:
      return '联系咨询师';
    case OrderPrimaryAction.evaluate:
      return '评价咨询师';
    case OrderPrimaryAction.viewArchivedRecap:
      return '查看回顾';
    case OrderPrimaryAction.none:
      return '';
  }
}

/// 主按钮动作 → 渐变（pay 红渐变，其余青渐变）。
/// iOS 参照：XYAppointmentOrderCell buttonRed / buttonTeal。
Gradient orderPrimaryActionGradient(OrderPrimaryAction action) {
  return action == OrderPrimaryAction.pay
      ? AppColors.redButtonGradient
      : AppColors.brandGradient;
}
