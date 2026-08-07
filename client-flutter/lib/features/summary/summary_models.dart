import '../consultant/consultant_models.dart';

/// `/app/mine/summary/detail` 详情数据（按后端真实字段建模）。
/// iOS 参照：XYMessageModule/XYMessageModule/Classes/ViewModel/
/// XYSummaryAdviseViewModel.swift（XYSummaryAdviseDetail）。
class SummaryAdviseDetail {
  const SummaryAdviseDetail({
    this.content,
    this.advice = const [],
    this.nextDirection,
    this.consultantName,
    this.consultantTitle,
    this.consultantAvatar,
    this.appointmentTime,
    this.duration,
    this.supportModeText,
    this.supportMode,
  });

  /// 小结正文
  final String? content;

  /// 行动建议条目（字符串数组）
  final List<String> advice;

  /// 咨询师建议下次继续探讨的方向。
  final String? nextDirection;

  /// 咨询师姓名 / 职称 / 头像
  final String? consultantName;
  final String? consultantTitle;
  final String? consultantAvatar;

  /// 预约（咨询）时间，格式 yyyy-MM-dd HH:mm:ss
  final String? appointmentTime;

  /// 咨询时长（分钟）
  final int? duration;

  /// 咨询方式文案（如「语音咨询」）
  final String? supportModeText;

  /// 咨询方式代码（1 文字 / 2 语音 / 3 视频），决定方式图标
  final String? supportMode;

  factory SummaryAdviseDetail.fromJson(Map<String, dynamic> json) {
    return SummaryAdviseDetail(
      content: asStringOrNull(json['content']),
      advice: asStringList(json['advice']),
      nextDirection: asStringOrNull(json['nextDirection']),
      consultantName: asStringOrNull(json['consultantName']),
      consultantTitle: asStringOrNull(json['consultantTitle']),
      consultantAvatar: asStringOrNull(json['consultantAvatar']),
      appointmentTime: asStringOrNull(json['appointmentTime']),
      duration: asIntOrNull(json['duration']),
      supportModeText: asStringOrNull(json['supportModeText']),
      supportMode: asStringOrNull(json['supportMode']),
    );
  }

  /// 咨询日期展示文案（yyyy-MM-dd；解析失败原样返回）。
  /// iOS 参照：XYSummaryAdviseViewController.formatDate。
  String get dateText => formatSummaryDate(appointmentTime);

  /// 过滤空白后的有效建议列表（iOS 参照：buildAdviceCard 的 trim/filter）。
  List<String> get validAdvice =>
      advice.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
}

/// 将预约时间格式化为「yyyy-MM-dd」，兼容 yyyy-MM-dd HH:mm:ss / ISO8601 /
/// yyyy-MM-dd，解析失败原样返回。
/// iOS 参照：XYSummaryAdviseViewController.formatDate。
String formatSummaryDate(String? raw) {
  if (raw == null || raw.isEmpty) return '';
  final text = raw.trim();
  final date = DateTime.tryParse(text);
  if (date == null) return raw;
  String two(int v) => v.toString().padLeft(2, '0');
  return '${date.year}-${two(date.month)}-${two(date.day)}';
}
