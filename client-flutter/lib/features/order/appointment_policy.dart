/// 用户侧预约规则投影。
///
/// Builder 接真实后端时，由咨询师的 schedule rule 快照写入订单；用户端始终读取
/// 下单时快照，避免咨询师后续修改规则导致历史订单口径变化。
class AppointmentPolicy {
  const AppointmentPolicy({
    required this.advanceBookingHours,
    required this.freeCancelHours,
    required this.lateCancelFeePercent,
    required this.rescheduleHours,
    required this.roomOpenMinutes,
  });

  final int advanceBookingHours;
  final int freeCancelHours;
  final int lateCancelFeePercent;
  final int rescheduleHours;
  final int roomOpenMinutes;

  /// 当前 Mock 咨询师规则，对齐 4311 预约规则的默认配置。
  static const current = AppointmentPolicy(
    advanceBookingHours: 2,
    freeCancelHours: 24,
    lateCancelFeePercent: 50,
    rescheduleHours: 24,
    roomOpenMinutes: 10,
  );

  List<String> get userFacingLines => [
        '需至少提前 $advanceBookingHours 小时预约。',
        '开诊前 $freeCancelHours 小时以上取消，可全额退款。',
        '不足 $freeCancelHours 小时取消，将收取 $lateCancelFeePercent% 服务费用；开始后取消不退款。',
        '改期请至少提前 $rescheduleHours 小时申请，并以咨询师确认结果为准。',
        '咨询室将在预约开始前 $roomOpenMinutes 分钟开放。',
      ];
}
