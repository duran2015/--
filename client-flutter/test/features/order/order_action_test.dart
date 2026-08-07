import 'package:flutter_test/flutter_test.dart';
import 'package:xinyu_flutter/features/order/order_action.dart';
import 'package:xinyu_flutter/features/order/order_models.dart';

AppointmentOrderItem order({
  required String displayStatus,
  String confirmationStatus = 'confirmed',
  String intakeStatus = 'submitted',
  String sessionStatus = 'ready',
  String summaryStatus = 'none',
  bool recapRead = false,
  bool hasReview = false,
  String? rescheduleStatus,
}) {
  return AppointmentOrderItem(
    counselorName: '林小满',
    appointmentTimeDisplay: '08-11 11:46',
    durationDisplay: '50分钟',
    displayStatus: displayStatus,
    statusText: '后端旧文案',
    confirmationStatus: confirmationStatus,
    intakeStatus: intakeStatus,
    sessionStatus: sessionStatus,
    summaryStatus: summaryStatus,
    recapRead: recapRead,
    hasReview: hasReview,
    rescheduleStatus: rescheduleStatus,
  );
}

void main() {
  test('资料待填写只影响工作流动作，不覆盖订单状态', () {
    final item = order(
      displayStatus: OrderActionRouter.statusNotConsulted,
      intakeStatus: 'pending',
    );

    expect(OrderActionRouter.statusLabel(item), '待咨询');
    expect(OrderActionRouter.currentTitle(item), '填写咨询前资料');
  });

  test('等待回顾只影响工作流事项，已履约订单仍显示已完成', () {
    final item = order(
      displayStatus: OrderActionRouter.statusConsulted,
      sessionStatus: 'completed',
      summaryStatus: 'pending',
    );

    expect(OrderActionRouter.statusLabel(item), '已完成');
    expect(OrderActionRouter.currentTitle(item), '等待咨询师确认回顾');
  });

  test('回顾查看和评价阶段不改变已完成订单状态', () {
    final recap = order(
      displayStatus: OrderActionRouter.statusConsulted,
      sessionStatus: 'completed',
      summaryStatus: 'shared',
    );
    final evaluation = order(
      displayStatus: OrderActionRouter.statusConsulted,
      sessionStatus: 'completed',
      summaryStatus: 'shared',
      recapRead: true,
    );

    expect(OrderActionRouter.statusLabel(recap), '已完成');
    expect(OrderActionRouter.currentTitle(recap), '查看本次咨询回顾');
    expect(OrderActionRouter.statusLabel(evaluation), '已完成');
    expect(OrderActionRouter.currentTitle(evaluation), '评价本次咨询');
  });

  test('待咨询订单可申请改期，待确认期间不重复提交', () {
    final scheduled = order(
      displayStatus: OrderActionRouter.statusNotConsulted,
    );
    final pending = order(
      displayStatus: OrderActionRouter.statusNotConsulted,
      rescheduleStatus: 'pending',
    );

    expect(OrderActionRouter.canRequestReschedule(scheduled), isTrue);
    expect(OrderActionRouter.canRequestReschedule(pending), isFalse);
    expect(OrderActionRouter.statusLabel(pending), '待咨询');
    expect(OrderActionRouter.currentTitle(pending), '改期申请待确认');
  });

  test('只有咨询师同意改期后才可选择新时间', () {
    final pending = order(
      displayStatus: OrderActionRouter.statusNotConsulted,
      rescheduleStatus: 'pending',
    );
    final approved = order(
      displayStatus: OrderActionRouter.statusNotConsulted,
      rescheduleStatus: 'approved',
    );

    expect(OrderActionRouter.canSelectRescheduleTime(pending), isFalse);
    expect(OrderActionRouter.canSelectRescheduleTime(approved), isTrue);
    expect(OrderActionRouter.canRequestReschedule(approved), isFalse);
  });

  test('咨询中和已完成订单不允许申请改期', () {
    final inProgress = order(
      displayStatus: OrderActionRouter.statusConsulting,
      sessionStatus: 'in_progress',
    );
    final completed = order(
      displayStatus: OrderActionRouter.statusConsulted,
      sessionStatus: 'completed',
    );

    expect(OrderActionRouter.canRequestReschedule(inProgress), isFalse);
    expect(OrderActionRouter.canRequestReschedule(completed), isFalse);
  });
}
