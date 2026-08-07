import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../order_action.dart';
import '../order_models.dart';
import 'order_widgets.dart';

/// 用户端预约订单紧凑卡片。
///
/// 视觉结构与咨询师工作台“业务待办”一致，但内容按用户角色投影：咨询师、
/// 当前节点、节点说明、预约时间/SKU 和一个当前可用操作。完整字段进入详情页查看。
class AppointmentOrderCard extends StatelessWidget {
  const AppointmentOrderCard({
    super.key,
    required this.item,
    this.onTap,
    this.onAction,
  });

  final AppointmentOrderItem item;

  /// 点击整卡 → 订单详情
  final VoidCallback? onTap;

  /// 点击状态按钮（去支付 / 联系咨询师 / 评价咨询师）
  final VoidCallback? onAction;

  static const _outline = Color(0xFFECE6DC);
  static const _secondary = Color(0xFF7A756C);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _outline),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.035),
              offset: const Offset(0, 2),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OrderAvatar(
              url: item.counselorAvatar,
              name: item.counselorName,
              seed: item.counselorIMUserID.isEmpty
                  ? 'consultant_${item.consultantId}'
                  : item.counselorIMUserID,
              size: 44,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _titleRow(),
                  const SizedBox(height: 7),
                  Text(
                    OrderActionRouter.currentDescription(item),
                    style: AppTextStyles.label.copyWith(
                      color: _secondary,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  _metaAndAction(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _titleRow() {
    final color = _nodeColor();
    return Row(
      children: [
        Expanded(
          child: Text(
            item.counselorName,
            style: AppTextStyles.titleSmall.copyWith(
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            OrderActionRouter.statusLabel(item),
            style: AppTextStyles.badge.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _metaAndAction() {
    final action = OrderActionRouter.cellPrimaryAction(item);
    final hasAction = action != OrderPrimaryAction.none;
    final title = hasAction ? orderPrimaryActionTitle(action) : '查看详情';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.schedule_rounded,
                      size: 14, color: _secondary),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      item.appointmentTimeDisplay,
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                [item.supportModeText, item.durationDisplay]
                    .where((text) => text.isNotEmpty)
                    .join(' · '),
                style: AppTextStyles.badge.copyWith(color: _secondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: hasAction ? onAction : onTap,
          child: Container(
            height: 34,
            constraints: const BoxConstraints(minWidth: 72),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: hasAction ? _nodeColor() : const Color(0xFFFAF8F5),
              borderRadius: BorderRadius.circular(17),
              border: hasAction ? null : Border.all(color: _outline),
            ),
            alignment: Alignment.center,
            child: Text(
              title,
              style: AppTextStyles.label.copyWith(
                color: hasAction ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _nodeColor() {
    return switch (OrderActionRouter.cellPrimaryAction(item)) {
      OrderPrimaryAction.pay => const Color(0xFFA23F1E),
      OrderPrimaryAction.enterSession => const Color(0xFF00796F),
      OrderPrimaryAction.viewRecap ||
      OrderPrimaryAction.viewArchivedRecap ||
      OrderPrimaryAction.evaluate =>
        const Color(0xFF6750A4),
      OrderPrimaryAction.fillIntake => const Color(0xFF6750A4),
      _ => const Color(0xFF8A6116),
    };
  }
}
