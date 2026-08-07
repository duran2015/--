/// 我的模块数据模型（契约 §3 #18、§5 #22）。
/// iOS 参照：XYMineModule/XYMineModule/Classes/Model/
/// XYMineAssessmentRecordModels.swift、XYMineSummaryModels.swift。
library;

import '../consultant/consultant_models.dart';

// ---------------- 量表测试记录（契约 §3 #18） ----------------

/// POST /app/assessment/list-by-status 的 data[] 元素（接口原始字段）。
/// iOS 参照：XYMineAssessmentListByStatusItem（Int/String 宽松解析）。
class AssessmentRecordRow {
  const AssessmentRecordRow({
    this.h5Link,
    this.name,
    this.questionnaireId,
    this.updateTime,
    this.userAssessId,
    this.userAssessStatus,
    this.userScore,
    this.userLevel,
  });

  /// 答题 H5 链接
  final String? h5Link;

  /// 量表名称
  final String? name;

  /// 问卷 ID
  final int? questionnaireId;

  /// 问卷更新时间
  final String? updateTime;

  /// 用户测评记录 ID
  final int? userAssessId;

  /// 用户测评状态
  final String? userAssessStatus;

  /// 用户得分
  final int? userScore;

  /// 用户症状等级
  final String? userLevel;

  factory AssessmentRecordRow.fromJson(Map<String, dynamic> json) {
    return AssessmentRecordRow(
      h5Link: asStringOrNull(json['h5Link']),
      name: asStringOrNull(json['name']),
      questionnaireId: asIntOrNull(json['questionnaireId']),
      updateTime: asStringOrNull(json['updateTime']),
      userAssessId: asIntOrNull(json['userAssessId']),
      userAssessStatus: asStringOrNull(json['userAssessStatus']),
      userScore: asIntOrNull(json['userScore']),
      userLevel: asStringOrNull(json['userLevel']),
    );
  }
}

/// 量表测试记录列表行（展示模型）。
/// iOS 参照：XYMineAssessmentRecordItem + XYMineAssessmentRecordMapper。
class AssessmentRecordItem {
  const AssessmentRecordItem({
    this.userAssessId,
    this.questionnaireId,
    required this.title,
    required this.dateText,
    this.score,
    this.levelText,
    this.h5Link,
  });

  /// 用户测评记录 ID（跳报告用）
  final int? userAssessId;

  /// 问卷 ID
  final int? questionnaireId;

  /// 量表名称
  final String title;

  /// 日期展示文案（yyyy-MM-dd）
  final String dateText;

  /// 得分（null → 隐藏得分胶囊）
  final int? score;

  /// 结果等级文案（null/空 → 隐藏等级区）
  final String? levelText;

  /// 答题 H5 链接
  final String? h5Link;

  /// list-by-status 单条 → 展示模型；名称为空丢弃该条（iOS recordItem）。
  static AssessmentRecordItem? fromRow(AssessmentRecordRow row) {
    final title = row.name?.trim() ?? '';
    if (title.isEmpty) return null;
    return AssessmentRecordItem(
      userAssessId: row.userAssessId,
      questionnaireId: row.questionnaireId,
      title: title,
      dateText: _normalizedDate(row.updateTime),
      score: row.userScore,
      levelText: _normalizedLevel(row.userLevel),
      h5Link: row.h5Link,
    );
  }

  /// 截取症状等级展示文案（iOS normalizedLevel）
  static String? _normalizedLevel(String? raw) {
    final text = raw?.trim() ?? '';
    return text.isEmpty ? null : text;
  }

  /// 截取 yyyy-MM-dd 日期部分（iOS normalizedDate）
  static String _normalizedDate(String? raw) {
    final text = raw?.trim() ?? '';
    if (text.isEmpty) return '';
    return text.length >= 10 ? text.substring(0, 10) : text;
  }
}

// ---------------- 小结与建议列表（契约 §5 #22） ----------------

String? _firstString(Map<String, dynamic> json, List<String> keys) {
  for (final k in keys) {
    final v = json[k];
    if (v != null) return v.toString();
  }
  return null;
}

int? _firstInt(Map<String, dynamic> json, List<String> keys) {
  for (final k in keys) {
    final v = asIntOrNull(json[k]);
    if (v != null) return v;
  }
  return null;
}

/// `/app/mine/summaries` 分页列表单行（接口原始字段，兼容多种后端命名）。
/// iOS 参照：XYMineSummaryRow。
class SummaryRow {
  const SummaryRow({
    this.orderId,
    this.consultantId,
    this.consultantName,
    this.consultantTitle,
    this.consultantAvatar,
    this.appointmentStartTime,
    this.appointmentEndTime,
    this.appointmentTime,
    this.content,
    this.summary,
    this.adviceCount,
  });

  /// 订单 ID（跳转详情用）
  final int? orderId;

  /// 咨询师业务 ID
  final int? consultantId;

  /// 咨询师姓名
  final String? consultantName;

  /// 咨询师职称（如「医生」「心理咨询师」）
  final String? consultantTitle;

  /// 咨询师头像 URL
  final String? consultantAvatar;

  /// 预约开始/结束时间
  final String? appointmentStartTime;
  final String? appointmentEndTime;

  /// 预约时间（单行字段，部分接口仅返回此项）
  final String? appointmentTime;

  /// 小结正文预览
  final String? content;

  /// 小结正文（备用字段名）
  final String? summary;

  /// 行动建议条数（取 advice 数组元素个数）
  final int? adviceCount;

  factory SummaryRow.fromJson(Map<String, dynamic> json) {
    return SummaryRow(
      orderId: _firstInt(json, const ['orderId', 'orderID']),
      consultantId: _firstInt(json, const ['consultantId', 'counselorId']),
      consultantName:
          _firstString(json, const ['consultantName', 'counselorName', 'name']),
      consultantTitle: _firstString(
          json, const ['consultantTitle', 'counselorTitle', 'title']),
      consultantAvatar: _firstString(
          json, const ['consultantAvatar', 'counselorAvatar', 'avatar']),
      appointmentStartTime: _firstString(json,
          const ['appointmentStartTime', 'startTime', 'consultStartTime']),
      appointmentEndTime: _firstString(
          json, const ['appointmentEndTime', 'endTime', 'consultEndTime']),
      appointmentTime:
          _firstString(json, const ['appointmentTime', 'consultTime', 'date']),
      content: _firstString(
          json, const ['content', 'desc', 'summaryContent', 'preview']),
      summary: _firstString(
          json, const ['summary', 'consultantSummary', 'counselorSummary']),
      adviceCount: _adviceArrayCount(json['advice']),
    );
  }

  /// 取 advice 字段对应数组的元素个数（iOS adviceArrayCount）
  static int? _adviceArrayCount(dynamic advice) {
    if (advice is List) return advice.length;
    return null;
  }
}

/// 小结与建议列表展示模型。
/// iOS 参照：XYMineSummaryItem。
class SummaryItem {
  const SummaryItem({
    this.orderId,
    this.consultantId,
    required this.title,
    required this.timeDisplay,
    required this.preview,
    required this.adviceCount,
    this.consultantAvatar,
  });

  /// 订单 ID
  final int? orderId;

  /// 咨询师业务 ID
  final int? consultantId;

  /// 卡片标题（如「林静 医生的小结」）
  final String title;

  /// 咨询时间展示（iOS 为单一时间点，如「06-05 14:00」）
  final String timeDisplay;

  /// 小结正文预览
  final String preview;

  /// 行动建议条数
  final int adviceCount;

  /// 咨询师头像 URL
  final String? consultantAvatar;

  /// 接口行 → 展示模型（iOS displayItem）
  static SummaryItem fromRow(SummaryRow row) {
    final name = row.consultantName?.trim() ?? '';
    final titlePart = (row.consultantTitle?.trim() ?? '').isEmpty
        ? '咨询师'
        : row.consultantTitle!.trim();
    final cardTitle =
        name.isEmpty ? '$titlePart的小结' : '$name $titlePart的小结';
    return SummaryItem(
      orderId: row.orderId,
      consultantId: row.consultantId,
      title: cardTitle,
      timeDisplay: formatSummaryTime(
        start: row.appointmentStartTime,
        fallback: row.appointmentTime,
      ),
      preview: (row.content ?? row.summary ?? '').trim(),
      adviceCount: row.adviceCount ?? 0,
      consultantAvatar: row.consultantAvatar,
    );
  }
}

String _two(int v) => v.toString().padLeft(2, '0');

/// 解析接口时间（兼容 yyyy-MM-dd HH:mm:ss 与 ISO8601；含时区转本地）。
/// iOS 参照：XYMineSummaryItem.parseDate。
DateTime? _parseDate(String? raw) {
  final text = raw?.trim() ?? '';
  if (text.isEmpty) return null;
  return DateTime.tryParse(text)?.toLocal();
}

/// 格式化为单一时间点「MM-dd HH:mm」（iOS 小结列表为单时间形态，
/// 见 ios/06_summaries.png「07-16 14:00」）。
String formatSummaryTime({String? start, String? fallback}) {
  final s = _parseDate(start);
  if (start != null && start.isNotEmpty && s != null) {
    return '${_two(s.month)}-${_two(s.day)} ${_two(s.hour)}:${_two(s.minute)}';
  }
  final fb = fallback ?? '';
  if (fb.isEmpty) return '';
  final d = _parseDate(fb);
  if (d != null) {
    return '${_two(d.month)}-${_two(d.day)} ${_two(d.hour)}:${_two(d.minute)}';
  }
  return fb;
}
