import '../../core/theme/app_assets.dart';
import '../consultant/consultant_models.dart';

/// 我的预约订单展示模型（由 /app/consultant/order/my-list 行映射，
/// 供订单卡片/详情/支付页展示与按钮动作判断）。
///
/// iOS 参照：XYAIModule/XYAIModule/Classes/ViewModel/XYAppointmentOrderItem.swift
/// + XYMyAppointmentOrdersViewModel.displayItem（行 → 展示模型的全部派生逻辑）。
class AppointmentOrderItem {
  const AppointmentOrderItem({
    this.orderId,
    this.consultantId,
    required this.counselorName,
    this.counselorAvatar,
    this.counselorIMUserID = '',
    this.supportMode,
    this.supportModeDesc,
    required this.appointmentTimeDisplay,
    this.appointmentTimeRangeDisplay = '',
    required this.durationDisplay,
    this.counselorTitle,
    this.orderNo,
    this.price,
    this.displayStatus,
    this.statusText = '',
    this.specialtyTags = const [],
    this.styleTags = const [],
    this.serviceHoursText = '',
    this.paymentDeadline,
    this.hasReview = true,
    this.roomId,
    this.roomName,
    this.confirmationStatus,
    this.intakeStatus,
    this.sessionStatus,
    this.summaryStatus,
    this.recapRead = false,
    this.sessionId,
    this.draftId,
    this.rescheduleStatus,
    this.requestedAppointmentTime,
  });

  /// 订单 ID（字符串承载：真实后端为数字，mock 为 "mock_order_1001"）
  final String? orderId;

  /// 咨询师业务 ID（评价页 counselorId）
  final int? consultantId;

  /// 咨询师姓名
  final String counselorName;

  /// 咨询师头像 URL
  final String? counselorAvatar;

  /// 咨询师 IM 用户 ID（进入咨询用，my-list 可能无该字段）
  final String counselorIMUserID;

  /// 支持方式编码（1 文字 / 2 语音 / 3 视频）
  final String? supportMode;

  /// 支持方式描述（语音咨询 / 视频咨询）
  final String? supportModeDesc;

  /// 预约时间展示文案（MM-dd HH:mm）
  final String appointmentTimeDisplay;

  /// 预约时间区间展示文案（MM-dd HH:mm～HH:mm，详情页用）
  final String appointmentTimeRangeDisplay;

  /// 咨询时长展示文案（X分钟）
  final String durationDisplay;

  /// 咨询师职称/头衔（详情页展示）
  final String? counselorTitle;

  /// 订单编号（详情页展示）
  final String? orderNo;

  /// 支付金额（元）
  final double? price;

  /// 展示状态码（unpaid/cancelled/not_consulted/consulting/consulted）
  final String? displayStatus;

  /// 展示状态文案（徽标文字）
  final String statusText;

  /// 擅长领域标签
  final List<String> specialtyTags;

  /// 咨询风格标签
  final List<String> styleTags;

  /// 累计服务时长展示文案（累计服务 X小时；无数据为空）
  final String serviceHoursText;

  /// 支付截止时间（yyyy-MM-dd HH:mm:ss；未支付订单倒计时用）
  final String? paymentDeadline;

  /// 是否已评价（已咨询订单：false 展示「评价咨询师」）
  final bool hasReview;

  /// 咨询室 roomId（音视频进房；缺省则无法进房）
  final String? roomId;

  /// 咨询室名称
  final String? roomName;

  /// 双侧咨询生命周期字段。页面只消费这些投影字段，不再各自猜测节点。
  final String? confirmationStatus;
  final String? intakeStatus;
  final String? sessionStatus;
  final String? summaryStatus;
  final bool recapRead;
  final String? sessionId;
  final String? draftId;

  /// 改期属于订单上的工作流申请，不是订单状态。
  final String? rescheduleStatus;
  final String? requestedAppointmentTime;

  /// 咨询方式展示文案：supportModeDesc 优先，缺失按 supportMode 兜底。
  /// iOS 参照：XYAppointmentOrderDetailViewController.fallbackSupportModeDesc
  String get supportModeText {
    final desc = supportModeDesc;
    if (desc != null && desc.isNotEmpty) return desc;
    switch (supportMode) {
      case '1':
        return '文字咨询';
      case '2':
        return '语音咨询';
      case '3':
        return '视频咨询';
      default:
        return '在线咨询';
    }
  }

  /// 卡片时长行文案：时长优先，空则退化为咨询方式描述。
  /// iOS 参照：XYAppointmentOrderCell.configure durationLabel
  String get durationRowText =>
      durationDisplay.isEmpty ? (supportModeDesc ?? '') : durationDisplay;

  // ---------------- 行 JSON → 展示模型 ----------------

  /// /app/consultant/order/my-list 行元素 → 展示模型。
  /// iOS 参照：XYMyAppointmentOrdersViewModel.displayItem。
  factory AppointmentOrderItem.fromJson(Map<String, dynamic> json) {
    final appointmentTime = asStringOrNull(json['appointmentTime']) ??
        asStringOrNull(json['appointmentStartTime']);
    final duration = asIntOrNull(json['duration']);
    final totalHours = asDoubleOrNull(json['totalServiceHours']);
    return AppointmentOrderItem(
      orderId: asStringOrNull(json['orderId']),
      consultantId: asIntOrNull(json['consultantId']),
      counselorName: asStringOrNull(json['consultantName']) ?? '',
      counselorAvatar: asStringOrNull(json['consultantAvatar']),
      counselorIMUserID: asStringOrNull(json['consultantImUserId']) ??
          asStringOrNull(json['consultantIMUserId']) ??
          asStringOrNull(json['imUserId']) ??
          '',
      supportMode: asStringOrNull(json['supportMode']),
      supportModeDesc: asStringOrNull(json['supportModeDesc']),
      appointmentTimeDisplay: formatAppointmentTime(appointmentTime),
      appointmentTimeRangeDisplay:
          formatAppointmentTimeRange(appointmentTime, duration),
      durationDisplay: duration == null ? '' : '$duration分钟',
      counselorTitle: asStringOrNull(json['consultantTitle']),
      orderNo: asStringOrNull(json['orderNo']),
      price: asDoubleOrNull(json['price']),
      displayStatus: asStringOrNull(json['displayStatus']),
      statusText: asStringOrNull(json['displayStatusDesc']) ??
          asStringOrNull(json['statusDesc']) ??
          '',
      specialtyTags: asStringList(json['specialtyTags']),
      styleTags: asStringList(json['styleTags']),
      serviceHoursText: formatServiceHours(totalHours),
      paymentDeadline: asStringOrNull(json['paymentDeadline']),
      hasReview: json['hasReview'] as bool? ?? true,
      roomId: asStringOrNull(json['roomId']) ?? asStringOrNull(json['rtId']),
      roomName: asStringOrNull(json['roomName']),
      confirmationStatus: asStringOrNull(json['confirmationStatus']),
      intakeStatus: asStringOrNull(json['intakeStatus']),
      sessionStatus: asStringOrNull(json['sessionStatus']),
      summaryStatus: asStringOrNull(json['summaryStatus']),
      recapRead: json['recapRead'] as bool? ?? false,
      sessionId: asStringOrNull(json['sessionId']),
      draftId: asStringOrNull(json['draftId']),
      rescheduleStatus: asStringOrNull(json['rescheduleStatus']),
      requestedAppointmentTime:
          asStringOrNull(json['requestedAppointmentTime']),
    );
  }
}

/// 累计服务时长文案：1000.0 → "累计服务 1000小时"（无数据为空）。
/// iOS 参照：XYMyAppointmentOrdersViewModel.formatServiceHours。
String formatServiceHours(double? hours) {
  if (hours == null) return '';
  return '累计服务 ${hours.toInt()}小时';
}

/// yyyy-MM-dd HH:mm:ss → MM-dd HH:mm（解析失败原样返回）。
/// iOS 参照：XYMyAppointmentOrdersViewModel.formatAppointmentTime。
String formatAppointmentTime(String? raw) {
  if (raw == null || raw.isEmpty) return '';
  final date = DateTime.tryParse(raw.trim());
  if (date == null) return raw;
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(date.month)}-${two(date.day)} ${two(date.hour)}:${two(date.minute)}';
}

/// 预约时间区间：开始 + 时长（分钟）→ "MM-dd HH:mm～HH:mm"
/// （无结束时间退化为开始时间）。
/// iOS 参照：XYMyAppointmentOrdersViewModel.formatAppointmentTimeRange。
String formatAppointmentTimeRange(String? start, int? durationMinutes) {
  if (start == null || start.isEmpty) return '';
  final startDate = DateTime.tryParse(start.trim());
  if (startDate == null) return formatAppointmentTime(start);
  String two(int v) => v.toString().padLeft(2, '0');
  final startText =
      '${two(startDate.month)}-${two(startDate.day)} ${two(startDate.hour)}:${two(startDate.minute)}';
  if (durationMinutes == null || durationMinutes <= 0) return startText;
  final end = startDate.add(Duration(minutes: durationMinutes));
  return '$startText～${two(end.hour)}:${two(end.minute)}';
}

/// 咨询方式编码 → 图标资源（1 文字 / 2 语音 / 3 视频，默认文字）。
/// iOS 参照：XYAppointmentOrderCell.methodIconName。
String methodIconAsset(String? supportMode) {
  switch (supportMode) {
    case '2':
      return AppAssets.icMethodVoice;
    case '3':
      return AppAssets.icMethodVideo;
    case '1':
    default:
      return AppAssets.icMethodText;
  }
}
