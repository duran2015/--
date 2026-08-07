import 'order_models.dart';

/// 订单主按钮动作（iOS XYAppointmentOrderActionRouter.handlePrimary 的分发结果）。
enum OrderPrimaryAction {
  /// 去支付（未支付订单）
  pay,

  /// 填写选填的咨询前资料。
  fillIntake,

  /// 进入文字或音视频咨询。
  enterSession,

  /// 查看咨询师已分享的用户回顾。
  viewRecap,

  /// 联系咨询师 / 进咨询室（待咨询 / 咨询中；已咨询已评价）
  contact,

  /// 评价咨询师（已咨询未评价）
  evaluate,

  /// 已评价后查看归档回顾。
  viewArchivedRecap,

  /// 无主按钮（已取消等）
  none,
}

/// 预约订单状态 → 按钮/动作映射（列表 Cell 与详情页共用）。
///
/// iOS 参照：XYAIModule/XYAIModule/Classes/Service/XYAppointmentOrderActionRouter.swift
/// + XYAppointmentOrderCell.configureStatusButtons
/// + XYAppointmentOrderDetailViewController.configureBottomButtons。
class OrderActionRouter {
  OrderActionRouter._();

  // ---------- 状态码常量（iOS displayStatus） ----------
  static const String statusUnpaid = 'unpaid';
  static const String statusCancelled = 'cancelled';
  static const String statusNotConsulted = 'not_consulted';
  static const String statusConsulting = 'consulting';
  static const String statusConsulted = 'consulted';
  static const String statusRefunded = 'refunded';

  static bool _isCancelled(AppointmentOrderItem item) =>
      item.displayStatus == statusCancelled ||
      item.displayStatus == statusRefunded;

  /// 用户侧唯一当前节点。优先使用独立生命周期字段，兼容旧订单状态。
  static OrderPrimaryAction primaryAction(AppointmentOrderItem item) {
    if (_isCancelled(item)) return OrderPrimaryAction.none;
    if (item.displayStatus == statusUnpaid) return OrderPrimaryAction.pay;
    if (item.rescheduleStatus == 'pending') return OrderPrimaryAction.none;
    if (item.confirmationStatus == 'pending') return OrderPrimaryAction.none;
    if (item.sessionStatus == 'completed') {
      if (item.summaryStatus != 'shared') return OrderPrimaryAction.none;
      if (!item.recapRead) return OrderPrimaryAction.viewRecap;
      if (!item.hasReview) return OrderPrimaryAction.evaluate;
      return OrderPrimaryAction.viewArchivedRecap;
    }
    if (item.intakeStatus == 'pending') return OrderPrimaryAction.fillIntake;
    if (item.sessionStatus == 'ready' ||
        item.sessionStatus == 'in_progress' ||
        item.displayStatus == statusConsulting) {
      return OrderPrimaryAction.enterSession;
    }
    return switch (item.displayStatus) {
      statusNotConsulted => OrderPrimaryAction.enterSession,
      statusConsulted => item.hasReview
          ? OrderPrimaryAction.viewArchivedRecap
          : OrderPrimaryAction.evaluate,
      _ => OrderPrimaryAction.none,
    };
  }

  /// 纯订单状态文案。
  ///
  /// 注意：咨询前资料、咨询回顾、查看回顾和评价属于工作流事项，不能覆盖
  /// 订单交易/履约状态。列表徽标与详情页「订单状态」只能调用本方法；工作流
  /// 当前事项继续由 [currentTitle]、[currentDescription] 与 [primaryAction] 表达。
  static String statusLabel(AppointmentOrderItem item) {
    return switch (item.displayStatus) {
      statusUnpaid => '待支付',
      statusCancelled => '已取消',
      statusRefunded => '已退款',
      statusConsulting => '咨询中',
      statusConsulted => '已完成',
      statusNotConsulted =>
        item.confirmationStatus == 'pending' ? '待咨询师确认' : '待咨询',
      _ => item.statusText,
    };
  }

  static String currentTitle(AppointmentOrderItem item) =>
      item.rescheduleStatus == 'pending'
          ? '改期申请待确认'
          : switch (primaryAction(item)) {
              OrderPrimaryAction.pay => '完成订单支付',
              OrderPrimaryAction.fillIntake => '填写咨询前资料',
              OrderPrimaryAction.enterSession =>
                item.sessionStatus == 'in_progress' ? '咨询正在进行' : '等待开始咨询',
              OrderPrimaryAction.viewRecap => '查看本次咨询回顾',
              OrderPrimaryAction.evaluate => '评价本次咨询',
              OrderPrimaryAction.viewArchivedRecap => '本次咨询已完成',
              OrderPrimaryAction.contact => '联系咨询师',
              OrderPrimaryAction.none => item.confirmationStatus == 'pending'
                  ? '等待咨询师确认预约'
                  : '等待咨询师确认回顾',
            };

  static String currentDescription(AppointmentOrderItem item) =>
      item.rescheduleStatus == 'pending'
          ? '咨询师确认后才更新时间，确认前原预约仍然有效。'
          : switch (primaryAction(item)) {
              OrderPrimaryAction.pay => '支付成功后，预约申请将发送给咨询师。',
              OrderPrimaryAction.fillIntake => '资料为选填，可帮助咨询师提前了解你的情况。',
              OrderPrimaryAction.enterSession => '请在预约开放时间内进入咨询室。',
              OrderPrimaryAction.viewRecap => '咨询师已分享回顾，查看后可以进行评价。',
              OrderPrimaryAction.evaluate => '回顾已查看，请为本次咨询留下反馈。',
              OrderPrimaryAction.viewArchivedRecap => '回顾和评价均已完成，可随时再次查看。',
              OrderPrimaryAction.contact => '如有问题，可以先与咨询师沟通。',
              OrderPrimaryAction.none => item.confirmationStatus == 'pending'
                  ? '确认后将开放咨询前资料和咨询入口。'
                  : '咨询师正在整理回顾，完成后会通过消息通知你。',
            };

  /// 列表 Cell 主按钮动作。
  /// iOS 参照：XYAppointmentOrderCell.configureStatusButtons——
  /// unpaid→去支付；not_consulted/consulting→联系咨询师；
  /// consulted 未评价→评价咨询师；consulted 已评价 / cancelled→无按钮。
  static OrderPrimaryAction cellPrimaryAction(AppointmentOrderItem item) {
    return primaryAction(item);
  }

  /// 详情页主按钮动作。
  /// iOS 参照：XYAppointmentOrderDetailViewController.configurePrimaryButton——
  /// 与 Cell 唯一差别：consulted 已评价→联系咨询师（Cell 无按钮）。
  static OrderPrimaryAction detailPrimaryAction(AppointmentOrderItem item) {
    return primaryAction(item);
  }

  /// 详情页主按钮标题（iOS 参照：configurePrimaryButton）。
  static String detailPrimaryTitle(AppointmentOrderItem item) {
    switch (detailPrimaryAction(item)) {
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

  /// 详情页次按钮（取消预约）显隐：仅 unpaid / not_consulted 展示。
  /// iOS 参照：configureSecondaryButton。
  static bool showCancelButton(AppointmentOrderItem item) {
    return item.displayStatus == statusUnpaid ||
        item.confirmationStatus == 'pending' ||
        (item.displayStatus == statusNotConsulted &&
            item.sessionStatus != 'in_progress');
  }

  /// 只有已确认、尚未开始且没有待处理改期申请的订单允许申请改期。
  static bool canRequestReschedule(AppointmentOrderItem item) {
    return item.displayStatus == statusNotConsulted &&
        item.confirmationStatus != 'pending' &&
        item.sessionStatus != 'in_progress' &&
        item.sessionStatus != 'completed' &&
        item.rescheduleStatus == null;
  }

  /// 咨询师已同意改期申请后，才允许用户选择新时间。
  static bool canSelectRescheduleTime(AppointmentOrderItem item) =>
      item.displayStatus == statusNotConsulted &&
      item.rescheduleStatus == 'approved';

  /// 详情页是否展示取消政策温馨提示卡（仅未支付 / 待咨询）。
  /// iOS 参照：shouldShowTipCard。
  static bool showTipCard(AppointmentOrderItem item) {
    return item.displayStatus == statusUnpaid ||
        item.displayStatus == statusNotConsulted;
  }

  /// 详情页是否创建底部操作栏（已取消/已退款订单无底部栏）。
  /// iOS 参照：setupBottomBar guard。
  static bool showBottomBar(AppointmentOrderItem item) {
    return item.displayStatus != statusCancelled &&
        item.displayStatus != statusRefunded;
  }
}
