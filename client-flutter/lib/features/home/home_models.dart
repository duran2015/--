import '../../core/theme/app_assets.dart';

/// 首页模型层。
/// iOS 参照：XYHomeModule/Classes/ViewModel/XYHomeViewModel.swift（内嵌
/// XYHomeMoodRecordItem）+ Model/XYHomeAssessmentModels.swift +
/// Model/XYHomeAssessmentMapper.swift。
///
/// 说明：字段全部按 iOS Decodable 结构手写，int 兼容字符串/数字两种返回。

/// 解析 int（兼容 num / 数字字符串），对应 iOS xyDecodeInt。
int? asInt(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

/// 解析 String（兼容非字符串类型），对应 iOS xyDecodeString。
String? asString(dynamic value) {
  if (value == null) return null;
  if (value is String) return value;
  return value.toString();
}

// ---------------------------------------------------------------------------
// 情绪（契约 §5 #26-28）
// ---------------------------------------------------------------------------

/// 情绪记录（/app/user/mood/trend、/app/user/mood/calendar 的 data 数组元素）。
/// iOS 参照：XYHomeMoodRecordItem。
class MoodRecordItem {
  const MoodRecordItem({
    this.trendId,
    this.userId,
    this.recordDate,
    this.moodScore,
    this.moodTags,
    this.moodIcon,
    this.note,
    this.createTime,
  });

  /// 趋势记录 ID
  final int? trendId;

  /// 用户 ID
  final int? userId;

  /// 记录日期（yyyy-MM-dd 或 yyyy-MM-dd HH:mm:ss 等）
  final String? recordDate;

  /// 情绪分值（5 超棒、4 还行、3 一般、2 不爽、1 低落）
  final int? moodScore;

  /// 情绪标签
  final String? moodTags;

  /// 情绪 emoji
  final String? moodIcon;

  /// 备注
  final String? note;

  /// 创建时间
  final String? createTime;

  factory MoodRecordItem.fromJson(Map<String, dynamic> json) {
    return MoodRecordItem(
      trendId: asInt(json['trendId']),
      userId: asInt(json['userId']),
      recordDate: asString(json['recordDate']),
      moodScore: asInt(json['moodScore']),
      moodTags: asString(json['moodTags']),
      moodIcon: asString(json['moodIcon']),
      note: asString(json['note']),
      createTime: asString(json['createTime']),
    );
  }

  /// 规范为 yyyy-MM-dd，供首页按日匹配。
  /// iOS 参照：XYHomeMoodRecordItem.normalizedDateKey（前 10 位含 "-" 直接取，
  /// 否则按若干格式解析后输出 yyyy-MM-dd）。
  String? get normalizedDateKey {
    final raw = recordDate?.trim();
    if (raw == null || raw.isEmpty) return null;
    if (raw.length >= 10) {
      final prefix = raw.substring(0, 10);
      if (prefix.contains('-')) return prefix;
    }
    final normalized = raw.replaceAll('/', '-');
    final datePart =
        normalized.length >= 10 ? normalized.substring(0, 10) : normalized;
    final parsed = DateTime.tryParse(datePart);
    if (parsed == null) return null;
    return formatDateKey(parsed);
  }
}

/// 生成 yyyy-MM-dd 键（iOS dateKeyFormatter）。
String formatDateKey(DateTime date) {
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '${date.year}-$m-$d';
}

/// 生成 yyyy-MM-dd HH:mm:ss（iOS recordDateTimeFormatter，提交情绪用）。
String formatRecordDateTime(DateTime date) {
  final h = date.hour.toString().padLeft(2, '0');
  final min = date.minute.toString().padLeft(2, '0');
  final s = date.second.toString().padLeft(2, '0');
  return '${formatDateKey(date)} $h:$min:$s';
}

/// 可选情绪项（记录弹窗用）。
/// iOS 参照：XYHomeViewModel.MoodOption。
class MoodOption {
  const MoodOption({
    required this.iconAsset,
    required this.title,
    required this.storageEmoji,
    required this.moodScore,
  });

  /// 情绪 3D 图标资源（AppAssets 路径）
  final String iconAsset;

  /// 情绪文案
  final String title;

  /// 写入月历的占位 emoji
  final String storageEmoji;

  /// 接口 moodScore（5 超棒 … 1 低落）
  final int moodScore;
}

/// 可选情绪（记录弹窗 5 个，moodScore 5→1）。
/// iOS 参照：XYHomeViewModel.moodOptions。
const List<MoodOption> kMoodOptions = [
  MoodOption(
    iconAsset: AppAssets.homeMoodGreat,
    title: '超棒',
    storageEmoji: '😄',
    moodScore: 5,
  ),
  MoodOption(
    iconAsset: AppAssets.homeMoodOk,
    title: '还行',
    storageEmoji: '😐',
    moodScore: 4,
  ),
  MoodOption(
    iconAsset: AppAssets.homeMoodNormal,
    title: '一般',
    storageEmoji: '😌',
    moodScore: 3,
  ),
  MoodOption(
    iconAsset: AppAssets.homeMoodBad,
    title: '不爽',
    storageEmoji: '😡',
    moodScore: 2,
  ),
  MoodOption(
    iconAsset: AppAssets.homeMoodLow,
    title: '低落',
    storageEmoji: '😔',
    moodScore: 1,
  ),
];

/// 按 moodScore 查找情绪选项（iOS moodOption(forScore:)）。
MoodOption? moodOptionForScore(int score) {
  for (final option in kMoodOptions) {
    if (option.moodScore == score) return option;
  }
  return null;
}

/// 最近一天的情绪记录（7 日行展示数据）。
/// iOS 参照：XYHomeViewModel.MoodDay。
class MoodDay {
  const MoodDay({
    required this.weekday,
    this.iconAsset,
    this.title,
    required this.isToday,
    required this.isRecordable,
  });

  /// 星期文字（一/二/…/日）
  final String weekday;

  /// 情绪图标资源（无记录时为今天/未录入占位图）
  final String? iconAsset;

  /// 情绪文字
  final String? title;

  /// 是否为今天
  final bool isToday;

  /// 是否可点击录入（仅「今天且未录入」为 true）
  final bool isRecordable;
}

/// 月历单日情绪。
/// iOS 参照：XYHomeViewModel.MonthMood。
class MonthMood {
  const MonthMood({required this.day, required this.iconAsset});

  /// 日期（1...31）
  final int day;

  /// 情绪 3D 图标资源（由 moodScore 映射）
  final String iconAsset;
}

/// 缓解小工具项。
/// iOS 参照：XYHomeViewModel.ToolItem + tools。
class HomeToolItem {
  const HomeToolItem({
    required this.title,
    required this.iconAsset,
    required this.linkUrl,
  });

  /// 工具名
  final String title;

  /// 图标资源
  final String iconAsset;

  /// 点击跳转链接（H5）
  final String linkUrl;
}

/// 缓解小工具列表（iOS XYHomeViewModel.tools 逐项对照）。
const List<HomeToolItem> kHomeTools = [
  HomeToolItem(
    title: '呼吸训练',
    iconAsset: AppAssets.homeToolBreath,
    linkUrl: 'https://admin.currantmind.cn/relax/huxi.html',
  ),
  HomeToolItem(
    title: '白噪音',
    iconAsset: AppAssets.homeToolNoise,
    linkUrl: 'https://admin.currantmind.cn/relax/baizaoyin.html',
  ),
  HomeToolItem(
    title: '敲木鱼',
    iconAsset: AppAssets.homeToolWoodfish,
    linkUrl: 'https://admin.currantmind.cn/relax/muyu.html',
  ),
  HomeToolItem(
    title: '冥想放松',
    iconAsset: AppAssets.homeToolMeditation,
    linkUrl: 'https://admin.currantmind.cn/relax/mingxiang.html',
  ),
  HomeToolItem(
    title: '睡眠引导',
    iconAsset: AppAssets.homeToolSleep,
    linkUrl: 'https://admin.currantmind.cn/relax/shuiqian.html',
  ),
  HomeToolItem(
    title: '捏泡泡',
    iconAsset: AppAssets.homeToolBubble,
    linkUrl: 'https://admin.currantmind.cn/relax/paopao.html',
  ),
];

// ---------------------------------------------------------------------------
// 测评（契约 §3 #17-19）
// ---------------------------------------------------------------------------

/// 测评完成状态。
/// iOS 参照：XYHomeViewModel.AssessmentStatus。
enum AssessmentStatus { untested, tested }

/// 测评问卷列表单条（POST /app/assessment/list 的 data[] 元素）。
/// iOS 参照：XYHomeAssessmentItem。
class AssessmentItem {
  const AssessmentItem({
    this.backgroundImage,
    this.category,
    this.description,
    this.h5Link,
    this.icon,
    this.name,
    this.questionCount,
    this.questionnaireId,
    this.questionnaireKey,
    this.sortOrder,
    this.status,
    this.userAssessStatus,
    this.userAssessId,
    this.testedCount,
  });

  /// 卡片背景图 URL
  final String? backgroundImage;

  /// 分类（如 clinical）
  final String? category;

  /// 问卷描述（首页卡片副标题，单行截断展示）
  final String? description;

  /// 答题 H5 链接
  final String? h5Link;

  /// 左上角图标 URL
  final String? icon;

  /// 问卷名称（首页卡片标题）
  final String? name;

  /// 题目数量
  final int? questionCount;

  /// 问卷 ID
  final int? questionnaireId;

  /// 问卷 key（如 sds / sas）
  final String? questionnaireKey;

  /// 排序值
  final int? sortOrder;

  /// 问卷状态（上下架等）
  final String? status;

  /// 用户测评状态（"1" 已测，其他未测）
  final String? userAssessStatus;

  /// 用户测评记录 ID（已测时作为 assessmentId 调 /app/assessment/detail）
  final int? userAssessId;

  /// 已测人数
  final int? testedCount;

  factory AssessmentItem.fromJson(Map<String, dynamic> json) {
    return AssessmentItem(
      backgroundImage: asString(json['backgroundImage']),
      category: asString(json['category']),
      description: asString(json['description']),
      h5Link: asString(json['h5Link']),
      icon: asString(json['icon']),
      name: asString(json['name']),
      questionCount: asInt(json['questionCount']),
      questionnaireId: asInt(json['questionnaireId']),
      questionnaireKey: asString(json['questionnaireKey']),
      sortOrder: asInt(json['sortOrder']),
      status: asString(json['status']),
      userAssessStatus: asString(json['userAssessStatus']),
      userAssessId: asInt(json['userAssessId']),
      testedCount: asInt(json['testedCount']),
    );
  }

  /// 是否已测（userAssessStatus 为 "1" 已测，其他未测）。
  bool get isTested => userAssessStatus == '1';
}

/// 首页测评横向卡片展示数据。
/// iOS 参照：XYHomeViewModel.Assessment。
class HomeAssessment {
  const HomeAssessment({
    this.questionnaireId,
    this.questionnaireKey,
    required this.title,
    required this.subtitle,
    this.backgroundImageUrl,
    this.iconUrl,
    this.h5Link,
    this.userAssessId,
    required this.status,
  });

  /// 问卷 ID
  final int? questionnaireId;

  /// 问卷 key（本地占位图映射用）
  final String? questionnaireKey;

  /// 测评标题（name）
  final String title;

  /// 副标题（description，单行截断）
  final String subtitle;

  /// 卡片背景图 URL（backgroundImage）
  final String? backgroundImageUrl;

  /// 左上角图标 URL（icon）
  final String? iconUrl;

  /// 答题 H5 链接（h5Link）
  final String? h5Link;

  /// 用户测评记录 ID
  final int? userAssessId;

  /// 测评状态
  final AssessmentStatus status;
}

/// 全部测评列表单条展示数据。
/// iOS 参照：XYHomeAssessmentListItem。
class AssessmentListItem {
  const AssessmentListItem({
    this.questionnaireId,
    this.questionnaireKey,
    required this.title,
    required this.subtitle,
    this.iconUrl,
    this.h5Link,
    this.userAssessId,
    required this.questionCountText,
    required this.participantText,
    required this.status,
  });

  /// 问卷 ID
  final int? questionnaireId;

  /// 问卷 key（本地占位图映射用）
  final String? questionnaireKey;

  /// 测评标题
  final String title;

  /// 副标题
  final String subtitle;

  /// 图标 URL
  final String? iconUrl;

  /// 答题 H5 链接
  final String? h5Link;

  /// 用户测评记录 ID
  final int? userAssessId;

  /// 题目数文案（questionCount 总题数）
  final String questionCountText;

  /// 已测数文案（testedCount）
  final String participantText;

  /// 用户测评状态
  final AssessmentStatus status;

  /// 右侧操作按钮文案（userAssessStatus 为 1 看结果，否则去测试）。
  String get actionTitle =>
      status == AssessmentStatus.tested ? '看结果' : '去测试';
}

/// 测评接口数据映射（首页卡片 / 全部测评列表共用）。
/// iOS 参照：XYHomeAssessmentMapper。
class AssessmentMapper {
  AssessmentMapper._();

  /// 按 sortOrder 排序接口列表（sortOrder 相同按 questionnaireId 升序）。
  static List<AssessmentItem> sortedItems(List<AssessmentItem> items) {
    final sorted = List<AssessmentItem>.of(items);
    sorted.sort((lhs, rhs) {
      final left = lhs.sortOrder ?? 1 << 31;
      final right = rhs.sortOrder ?? 1 << 31;
      if (left == right) {
        return (lhs.questionnaireId ?? 0).compareTo(rhs.questionnaireId ?? 0);
      }
      return left.compareTo(right);
    });
    return sorted;
  }

  /// 将接口记录映射为首页测评卡片数据。
  static HomeAssessment? homeAssessment(AssessmentItem item) {
    final title = _normalizedTitle(item);
    if (title == null) return null;
    return HomeAssessment(
      questionnaireId: item.questionnaireId,
      questionnaireKey: item.questionnaireKey,
      title: title,
      subtitle: _normalizedSubtitle(item),
      backgroundImageUrl: item.backgroundImage,
      iconUrl: item.icon,
      h5Link: item.h5Link,
      userAssessId: item.userAssessId,
      status: _statusOf(item),
    );
  }

  /// 将接口记录映射为全部测评列表项。
  static AssessmentListItem? listItem(AssessmentItem item) {
    final title = _normalizedTitle(item);
    if (title == null) return null;
    return AssessmentListItem(
      questionnaireId: item.questionnaireId,
      questionnaireKey: item.questionnaireKey,
      title: title,
      subtitle: _normalizedSubtitle(item),
      iconUrl: item.icon,
      h5Link: item.h5Link,
      userAssessId: item.userAssessId,
      questionCountText: questionCountText(item.questionCount),
      participantText: participantText(item.testedCount),
      status: _statusOf(item),
    );
  }

  static AssessmentStatus _statusOf(AssessmentItem item) =>
      item.isTested ? AssessmentStatus.tested : AssessmentStatus.untested;

  /// 解析并校验标题。
  static String? _normalizedTitle(AssessmentItem item) {
    final title = item.name?.trim() ?? '';
    return title.isEmpty ? null : title;
  }

  /// 解析副标题（description，空时回退默认文案）。
  static String _normalizedSubtitle(AssessmentItem item) {
    final subtitle = item.description?.trim() ?? '';
    return subtitle.isEmpty ? '专业心理测评' : subtitle;
  }

  /// 格式化总题数文案。
  static String questionCountText(int? count) => '${count ?? 0}题';

  /// 格式化已测数文案（iOS participantText：≥10w 取整，≥1w 保留 1 位小数）。
  static String participantText(int? count) {
    final value = count ?? 0;
    if (value >= 10000) {
      final scaled = value / 10000.0;
      if (scaled >= 10) {
        return '${scaled.toStringAsFixed(0)}w人已测';
      }
      return '${scaled.toStringAsFixed(1)}w人已测';
    }
    return '$value人已测';
  }
}

/// 测评报告详情（POST /app/assessment/detail 的 data，契约 §3 #19）。
/// iOS 参照：XYHomeAssessmentDetail。
class AssessmentDetail {
  const AssessmentDetail({
    this.assessDate,
    this.totalScore,
    this.level,
    this.interpretation,
    this.symptomTags,
    this.suggestions,
    this.sourceUrl,
  });

  /// 测评日期（如 "2026-07-11"）
  final String? assessDate;

  /// 总分
  final int? totalScore;

  /// 结果定性（如 "无抑郁症状"）
  final String? level;

  /// 结果解读
  final String? interpretation;

  /// 维度标签
  final List<String>? symptomTags;

  /// 专业建议
  final List<String>? suggestions;

  /// 内容出处链接（点击「内容出处」跳转；为空不展示入口）
  final String? sourceUrl;

  factory AssessmentDetail.fromJson(Map<String, dynamic> json) {
    List<String>? stringList(dynamic value) => value is List
        ? value.map((e) => e.toString()).toList()
        : null;
    // 兼容 sourceUrl / source_url；空白视为无
    final rawSource = asString(json['sourceUrl'] ?? json['source_url'])?.trim();
    final sourceUrl =
        (rawSource == null || rawSource.isEmpty) ? null : rawSource;
    return AssessmentDetail(
      assessDate: asString(json['assessDate']),
      totalScore: asInt(json['totalScore']),
      level: asString(json['level']),
      interpretation: asString(json['interpretation']),
      symptomTags: stringList(json['symptomTags']),
      suggestions: stringList(json['suggestions']),
      sourceUrl: sourceUrl,
    );
  }
}

/// 测评报告展示数据（Figma 518:2017）。
/// iOS 参照：XYHomeAssessmentReport。
class AssessmentReport {
  const AssessmentReport({
    required this.scaleTitle,
    required this.testDateText,
    required this.scoreText,
    required this.levelTitle,
    required this.tags,
    required this.interpretation,
    required this.suggestions,
    required this.retestHint,
    this.sourceUrl,
  });

  /// 量表名称
  final String scaleTitle;

  /// 测评时间文案
  final String testDateText;

  /// 得分
  final String scoreText;

  /// 结果等级标题
  final String levelTitle;

  /// 结果标签
  final List<String> tags;

  /// 结果解读正文
  final String interpretation;

  /// 专业建议列表
  final List<String> suggestions;

  /// 复测提示文案
  final String retestHint;

  /// 内容出处链接（为空则不展示「内容出处」入口）
  final String? sourceUrl;

  /// 静态展示数据（detail 返回前的占位）。
  /// iOS 参照：XYHomeAssessmentReport.mock(for:)。
  factory AssessmentReport.mock({String? assessmentTitle}) {
    return AssessmentReport(
      scaleTitle: assessmentTitle ?? '抑郁症筛查量表 (PHQ-9)',
      testDateText: '测评时间：2026-06-22',
      scoreText: '8',
      levelTitle: '轻度抑郁倾向',
      tags: const ['轻度情绪失落', '睡眠困扰'],
      interpretation:
          '根据您的得分情况，您目前存在一定程度的轻度抑郁。这可能与近期生活压力、学业压力或人际关系变化有关。这种状态比较常见，不必过度恐慌，但建议开始关注并进行适当的自我调节。',
      suggestions: const [
        '保持规律作息，尽量保证每天7-8小时的高质量睡眠。',
        '可以尝试应用内的“呼吸引导”或“正念冥想”工具来放松身心。',
        '若负面情绪持续超过两周且影响正常生活，建议预约专业咨询师进行沟通。',
      ],
      retestHint: '建议每2周-1个月复测一次，以观察状态变化',
      sourceUrl: null,
    );
  }

  /// 用 detail 详情覆盖 mock 报告（量表名/复测提示 detail 无，沿用现状）。
  /// iOS 参照：XYHomeAssessmentReportViewController.applyDetail。
  AssessmentReport mergedWithDetail(AssessmentDetail detail) {
    final mergedSource = detail.sourceUrl?.trim();
    return AssessmentReport(
      scaleTitle: scaleTitle,
      testDateText: detail.assessDate != null
          ? '测评时间：${detail.assessDate}'
          : testDateText,
      scoreText: detail.totalScore?.toString() ?? scoreText,
      levelTitle: detail.level ?? levelTitle,
      tags: detail.symptomTags ?? tags,
      interpretation: detail.interpretation ?? interpretation,
      suggestions: detail.suggestions ?? suggestions,
      retestHint: retestHint,
      // detail 有非空 sourceUrl 时覆盖；否则保留原值（路由兜底 / 上次合并）
      sourceUrl: (mergedSource != null && mergedSource.isNotEmpty)
          ? mergedSource
          : sourceUrl,
    );
  }
}

/// 测评卡片/列表本地占位图（backgroundImage / icon 为空时按 questionnaireKey
/// 映射到 iOS Home.xcassets 迁来的切图）。
/// iOS 参照：XYHomeAsset.assessment* / assessmentList*。
String? assessmentLocalCardImage(String? questionnaireKey) {
  switch (questionnaireKey) {
    case 'sds':
      return AppAssets.homeAssessmentDepression;
    case 'sas':
      return AppAssets.homeAssessmentAnxiety;
    case 'mbti':
      return AppAssets.homeAssessmentMbti;
    default:
      return null;
  }
}

/// 测评列表行本地占位图标（按 questionnaireKey）。
/// iOS 参照：XYHomeAsset.assessmentList*。
String? assessmentLocalListIcon(String? questionnaireKey) {
  switch (questionnaireKey) {
    case 'sds':
      return AppAssets.homeAssessmentListDepression;
    case 'sas':
      return AppAssets.homeAssessmentListAnxiety;
    case 'mbti':
      return AppAssets.homeAssessmentListEfficacy;
    case 'gad7':
      return AppAssets.homeAssessmentListGad;
    case 'psqi':
      return AppAssets.homeAssessmentListInsomnia;
    case 'scl90':
      return AppAssets.homeAssessmentListHealth;
    default:
      return null;
  }
}
