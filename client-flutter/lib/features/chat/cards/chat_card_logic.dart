import '../../../core/im/im_models.dart';

/// 自定义卡片业务逻辑（纯 Dart，不依赖 widget，供卡片渲染与金样本测试共用）。
///
/// 契约：contracts/im_custom_message_contract.md §4（6 种 businessID）。
/// iOS 参照：TUIKit/TUIChat/BaseCellData/Custom/*.swift +
/// CommonModel/TUICustomMessageTypeParser.swift。
/// Android 参照：aichat/adpter/MsgAdapter.kt 卡片分发。

/// 6 种业务卡片 + 未知兜底
enum ChatCardKind {
  beginChatMiddle,
  remindWindowMiddle,
  forEvaluateMiddle,
  forSummaryMiddle,
  summaryAdvise,
  questionAssistant,

  /// 未识别 businessID（含内置 text_link/order 等），走兜底渲染
  unknown,
}

/// 按 businessID 解析卡片类型（契约 §4 白名单）。
ChatCardKind resolveChatCardKind(String? businessID) {
  switch (businessID) {
    case 'begin_chat_middle':
      return ChatCardKind.beginChatMiddle;
    case 'remind_window_middle':
      return ChatCardKind.remindWindowMiddle;
    case 'for_evaluate_middle':
      return ChatCardKind.forEvaluateMiddle;
    case 'for_summary_middle':
      return ChatCardKind.forSummaryMiddle;
    case 'summary_advise':
      return ChatCardKind.summaryAdvise;
    case 'question_assistant':
      return ChatCardKind.questionAssistant;
    default:
      return ChatCardKind.unknown;
  }
}

/// 是否居中系统卡（无头像、不属于任一方）。
/// 契约 §4 分流规则：businessID 以 `_middle` 结尾 → 居中卡；
/// question_assistant 以 iOS 语义为方向性白卡
/// （⚠ Android MsgAdapter 按居中渲染，视为双端差异，见契约 §7.3 待确认项）。
bool isMiddleCard(ChatCardKind kind) {
  return kind == ChatCardKind.beginChatMiddle ||
      kind == ChatCardKind.remindWindowMiddle ||
      kind == ChatCardKind.forEvaluateMiddle ||
      kind == ChatCardKind.forSummaryMiddle;
}

/// businessID 是否为 `*_middle` 居中系统卡（含未来新增的 middle 卡）。
bool isMiddleCardBusinessId(String? businessID) {
  return businessID != null && businessID.endsWith('_middle');
}

/// 与咨询师端统一：卡片先按服务端下发 audience 做身份过滤，再进入类型分发。
/// legacy 卡片没有 audience，继续兼容原来的角色专属 businessID。
bool isCardVisibleForIdentity(ImCustomCard card, String? identity) {
  final audience = card.audience;
  if (audience != null && audience.isNotEmpty && audience != identity) {
    return false;
  }
  if (card.businessID == 'for_summary_middle') return identity == 'consultant';
  if (card.businessID == 'for_evaluate_middle') return identity == 'user';
  return true;
}

// ---------------- begin_chat_middle ----------------

/// 咨询方式（type：1 文字 / 2 语音 / 3 视频）。
/// iOS 参照：TUIBeginChatConsultType。
enum BeginChatConsultType {
  text,
  voice,
  video,
}

/// 从 json type 或 desc 文案推断咨询方式（缺省语音，兼容旧消息）。
/// iOS 参照：TUIBeginChatConsultType.resolve(type:desc:)。
BeginChatConsultType resolveBeginChatConsultType(ImCustomCard card) {
  switch (card.type) {
    case 1:
      return BeginChatConsultType.text;
    case 2:
      return BeginChatConsultType.voice;
    case 3:
      return BeginChatConsultType.video;
  }
  final desc = card.desc ?? '';
  if (desc.contains('文')) return BeginChatConsultType.text;
  if (desc.contains('视')) return BeginChatConsultType.video;
  if (desc.contains('语')) return BeginChatConsultType.voice;
  return BeginChatConsultType.voice;
}

/// title 含「取消」时隐藏时间区（Android MsgAdapter 语义；
/// iOS 未做该判定、按 type+desc 渲染——双端差异，保留 Android 行为并注释）。
bool beginChatHidesTimeSection(ImCustomCard card) {
  return (card.title ?? '').contains('取消');
}

// ---------------- remind_window_middle ----------------

/// 咨询室是否生效（type=1 生效显示「进入咨询室」；0 失效隐藏按钮）。
/// iOS 参照：TUIRemindWindowMiddleCellData.isRoomActive = bizType == 1。
bool isRemindWindowActive(ImCustomCard card) => card.type == 1;

/// 进入咨询室按钮文案（缺省「进入咨询室」）。
/// iOS 参照：TUIRemindWindowMiddleCellData.buttonTitle 缺省值。
String remindWindowButtonTitle(ImCustomCard card) {
  final t = card.buttonText;
  return (t == null || t.isEmpty) ? '进入咨询室' : t;
}

// ---------------- for_evaluate_middle / for_summary_middle ----------------

/// 行动卡是否已完成（按钮置灰「已完成」且不可点）。
/// iOS 参照：TUICustomMessageActionCardStatus.isCompleted。
///
/// ADR-0005：「已完成」以应用自有数据为准，不再依赖 IM 消息原地编辑。
/// [appCompleted] 为 app 数据判定（评价已提交 / 小结已发布）；非空时覆盖 IM 消息 type，
/// 为 null（尚未拉到 app 数据）时回退 card.type，避免渲染闪烁。
bool isActionCardCompleted(ImCustomCard card, {bool? appCompleted}) =>
    appCompleted ?? card.type == 2;

/// 「去评价」按钮是否展示：仅用户端。
/// iOS 参照：XYChatModule.setup 注入 isUserEndProvider（role == .user）。
bool showsEvaluateButton(String? identity) => identity == 'user';

/// 「填写小结」按钮是否展示：仅咨询师端。
/// iOS 参照：XYChatModule.setup 注入 isCounselorEndProvider（role == .counselor）。
bool showsSummaryButton(String? identity) => identity == 'consultant';

/// 去评价按钮文案（未完成缺省「评价本次咨询」；已完成缺省「已完成」）。
/// iOS 参照：TUIForEvaluateMiddleCellData.resolvedButtonTitle。
String evaluateButtonTitle(ImCustomCard card, {bool? appCompleted}) {
  final t = card.buttonText;
  if (isActionCardCompleted(card, appCompleted: appCompleted)) {
    return (t == null || t.isEmpty) ? '已完成' : t;
  }
  return (t == null || t.isEmpty) ? '评价本次咨询' : t;
}

/// 填写小结按钮文案（未完成缺省「填写小结」；已完成缺省「已完成」）。
/// iOS 参照：TUIForSummaryMiddleCellData.resolvedButtonTitle。
String summaryButtonTitle(ImCustomCard card, {bool? appCompleted}) {
  final t = card.buttonText;
  if (isActionCardCompleted(card, appCompleted: appCompleted)) {
    return (t == null || t.isEmpty) ? '已完成' : t;
  }
  return (t == null || t.isEmpty) ? '填写小结' : t;
}

// ---------------- summary_advise ----------------

/// 详情按钮文案（缺省「查看更多详情」）。
/// iOS 参照：TUISummaryAdviseCellData.buttonTitle 缺省值。
String summaryAdviseButtonTitle(ImCustomCard card) {
  final t = card.buttonText;
  return (t == null || t.isEmpty) ? '查看更多详情' : t;
}

/// 是否展示小结段（json desc 非空）。
/// iOS 参照：TUISummaryAdviseCellData.showsSummarySection。
bool showsSummarySection(ImCustomCard card) =>
    card.desc != null && card.desc!.isNotEmpty;

/// 是否展示建议段（json label 非空）。
/// iOS 参照：TUISummaryAdviseCellData.showsAdviseSection。
bool showsAdviseSection(ImCustomCard card) =>
    card.label != null && card.label!.isNotEmpty;

// ---------------- question_assistant ----------------

/// 工具类型（type：1 呼吸训练 / 2 白噪音 / 3 木鱼 / 4 冥想 / 5 睡眠引导 /
/// 6 情绪日记 / 7 捏泡泡）。
/// iOS 参照：TUIQuestionAssistantToolType。
enum AssistantToolType {
  breathing(1),
  whiteNoise(2),
  woodenFish(3),
  meditation(4),
  sleepGuide(5),
  moodDiary(6),
  bubblePop(7);

  const AssistantToolType(this.rawValue);
  final int rawValue;

  /// 服务端未下发 title 时的兜底名称。
  /// iOS 参照：TUIQuestionAssistantToolType.defaultTitle。
  String get defaultTitle {
    switch (this) {
      case AssistantToolType.breathing:
        return '呼吸训练';
      case AssistantToolType.whiteNoise:
        return '白噪音';
      case AssistantToolType.woodenFish:
        return '敲木鱼';
      case AssistantToolType.meditation:
        return '冥想放松';
      case AssistantToolType.sleepGuide:
        return '睡眠引导';
      case AssistantToolType.moodDiary:
        return '情绪日记';
      case AssistantToolType.bubblePop:
        return '捏泡泡';
    }
  }
}

/// 从 json type 或 title/desc 文案推断工具类型（缺省呼吸训练，兼容旧消息）。
/// iOS 参照：TUIQuestionAssistantToolType.resolve(type:title:desc:)。
AssistantToolType resolveAssistantToolType(ImCustomCard card) {
  final t = card.type;
  if (t != null && t >= 1 && t <= 7) {
    return AssistantToolType.values[t - 1];
  }
  final text = (card.title ?? '') + (card.desc ?? '');
  if (text.contains('白噪音')) return AssistantToolType.whiteNoise;
  if (text.contains('木鱼')) return AssistantToolType.woodenFish;
  if (text.contains('冥想')) return AssistantToolType.meditation;
  if (text.contains('睡眠')) return AssistantToolType.sleepGuide;
  if (text.contains('日记') || text.contains('情绪')) {
    return AssistantToolType.moodDiary;
  }
  if (text.contains('泡泡')) return AssistantToolType.bubblePop;
  if (text.contains('呼吸')) return AssistantToolType.breathing;
  return AssistantToolType.breathing;
}

/// 工具卡标题（服务端未下发 title 时按工具类型兜底）。
/// iOS 参照：TUIQuestionAssistantCellData.getCellData title 兜底。
String assistantCardTitle(ImCustomCard card) {
  final t = card.title;
  if (t != null && t.isNotEmpty) return t;
  return resolveAssistantToolType(card).defaultTitle;
}

/// 工具卡按钮文案（缺省「开始练习」）。
/// iOS 参照：TUIQuestionAssistantCellData.rightAction 缺省值。
String assistantButtonTitle(ImCustomCard card) {
  final t = card.buttonText;
  return (t == null || t.isEmpty) ? '开始练习' : t;
}

// ---------------- link 参数 ----------------

/// 解析卡片 link 的 query 参数（nanjingxinyu:// 或 https 均可，
/// 只取 query；契约 §3：业务参数一律放 link query）。
Map<String, String> parseCardLinkParams(String? link) {
  if (link == null || link.trim().isEmpty) return const {};
  final uri = Uri.tryParse(link.trim());
  if (uri == null) return const {};
  return uri.queryParameters;
}

/// 1006 拦截判定：link 为咨询室码且 supportMode=1（文字咨询）时，
/// 仅提示不进咨询室（iOS 参照：XYChatModule.observeRemindWindowAction）。
bool isTextConsultLink(Map<String, String> params) {
  return params['routeTypeCode'] == '1006' && params['supportMode'] == '1';
}

/// 咨询师工具面板 payload（发送 question_assistant 卡片）。
/// iOS 参照：XYChatInputBar.swift:851-884 AssistantTool.payload
/// （字段严格对齐：businessID/type/title/desc/buttonText/link，无多余字段）。
class AssistantToolPayload {
  const AssistantToolPayload._();

  /// 深呼吸（type=1）
  static const Map<String, Object> breathing = {
    'businessID': 'question_assistant',
    'type': 1,
    'title': '深呼吸',
    'desc': '跟随呼吸节奏，快速放松身心。',
    'buttonText': '开始呼吸',
    'link': 'https://admin.currantmind.cn/relax/huxi.html',
  };

  /// 白噪音（type=2）
  static const Map<String, Object> whiteNoise = {
    'businessID': 'question_assistant',
    'type': 2,
    'title': '白噪音',
    'desc': '隔绝环境干扰，帮助专注或入睡。',
    'buttonText': '播放声音',
    'link': 'https://admin.currantmind.cn/relax/baizaoyin.html',
  };

  /// 电子木鱼（type=3）
  static const Map<String, Object> woodenFish = {
    'businessID': 'question_assistant',
    'type': 3,
    'title': '电子木鱼',
    'desc': '轻触屏幕敲击木鱼，舒缓情绪、释放压力。',
    'buttonText': '敲击木鱼',
    'link': 'https://admin.currantmind.cn/relax/muyu.html',
  };

  /// 冥想（type=4）
  static const Map<String, Object> meditation = {
    'businessID': 'question_assistant',
    'type': 4,
    'title': '冥想',
    'desc': '跟随语音放松身心，平复情绪。',
    'buttonText': '开始冥想',
    'link': 'https://admin.currantmind.cn/relax/mingxiang.html',
  };

  /// 睡眠引导（type=5）
  static const Map<String, Object> sleepGuide = {
    'businessID': 'question_assistant',
    'type': 5,
    'title': '睡眠引导',
    'desc': '放松身体与呼吸，帮助快速入睡。',
    'buttonText': '开始助眠',
    'link': 'https://admin.currantmind.cn/relax/shuiqian.html',
  };
}
