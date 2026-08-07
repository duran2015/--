import 'package:flutter/material.dart';

/// 设计 token：颜色。
/// 来源：xinyuiOS 各模块 Style 枚举硬编码值（UIColor+Hex），以 iOS 为准。
/// 详见 flutter_master_plan.md 阶段 0.1。
class AppColors {
  AppColors._();

  // ---------- 文字（三级文字体系） ----------
  static const Color textPrimary = Color(0xFF191C1B);
  static const Color textSecondary = Color(0xFF3F4947);
  static const Color textTertiary = Color(0xFF6F7977);
  static const Color placeholder = Color(0xFFBEC9C6);
  static const Color textDark = Color(0xFF1A1A2E); // 异常页主文字/按钮底

  // ---------- 品牌青绿 ----------
  static const Color brandTeal = Color(0xFF006A67); // Material 3 品牌主色
  static const Color brandGradientStart = Color(0xFF00D8E0);
  static const Color brandGradientEnd = Color(0xFF00AFBE);

  /// 登录/注销/绑定主按钮三色渐变
  static const Color brandGradient3Start = Color(0xFF00E0C7);
  static const Color brandGradient3Mid = Color(0xFF00BCCE);
  // 终点同 brandGradientEnd (#00AFBE)

  static const Color brandTealLight = Color(0xFFD9F4F0); // 青绿浅底 tag/badge
  static const Color brandTealSelected = Color(0xFF9EF2EC); // 选中态浅底
  static const Color avatarTintTeal = Color(0xFF006A67); // 头像占位 tint

  // ---------- 靛蓝/紫（第二主题：咨询师/视频/等级） ----------
  static const Color indigo = Color(0xFF525EE1);
  static const Color indigoGradientStart = Color(0xFF4A56D9);
  static const Color indigoGradientEnd = Color(0xFF717DFF);
  static const Color bannerGradientStart = Color(0xFF4D5CFF);
  static const Color bannerGradientEnd = Color(0xFFA8A8FF);
  static const Color purpleTagBg = Color(0xFFF2EFFF);

  // ---------- 红/警示 ----------
  static const Color priceRed = Color(0xFFFF3D3D); // 价格/危险操作
  static const Color badgeRed = Color(0xFFFF3B30); // 未读角标
  static const Color counselorBadgeRed = Color(0xFFFF2E00); // 咨询师徽标
  static const Color countdownText = Color(0xFFFF6257); // 支付倒计时
  static const Color countdownBg = Color(0xFFFFF3F2);

  // ---------- 背景/分割 ----------
  static const Color pageBackground = Color(0xFFF8FAF8); // Material 3 surface

  /// 页面渐变顶色（左上）。
  /// iOS 参照：XYCoreModule XYOrderBackgroundView（#ECEFFF → #F1F4FB，114.8°）
  static const Color pageGradientStart = Color(0xFFEEF4F2);

  /// 页面通用渐变背景：#ECEFFF → #F1F4FB，左上 → 右下。
  /// iOS 参照：XYCoreModule XYOrderBackgroundView bgGradientLayer。
  static const LinearGradient pageGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [pageGradientStart, pageBackground],
  );
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color innerBackground = Color(0xFFF2F5F3); // surfaceContainer
  static const Color divider = Color(0xFFDDE5E2);
  static const Color dividerDark = Color(0xFFD5DEDB);
  static const Color navDivider = Color(0xFFDDE5E2); // 导航分割线
  static const Color cardShadow = Color(0xFFDCE4E1); // 低层级投影
  static const Color lightPurpleDivider = Color(0xFFEBECF6);

  /// 验证码格投影（黑 3%，offset(0,1)，blur 2）。
  /// iOS 参照：XYVerificationCodeViewController codeBox shadowOpacity 0.03
  static const Color codeBoxShadow = Color(0x08000000);

  // ---------- 咨询方式三色 ----------
  static const Color consultVoice = brandTeal; // 语音 #00A6A1，底 #E9FFF8→#E9FAFF
  static const Color consultVoiceBg = Color(0xFFE9FFF8);
  static const Color consultVideo = indigo; // 视频 #525EE1，底 #F9F7FE→#F1ECFF
  static const Color consultVideoBg = Color(0xFFF9F7FE);
  static const Color consultText = Color(0xFF52A8E1); // 文字，底 #F4F9FF→#EAF5FF
  static const Color consultTextBg = Color(0xFFF4F9FF);

  // ---------- 功能图标（tint + 浅底配对） ----------
  static const Color funcGreen = Color(0xFF34C759);
  static const Color funcGreenBg = Color(0xFFE8F8EE);
  static const Color funcPurple = Color(0xFF8B7CF6);
  static const Color funcPurpleBg = Color(0xFFF0EDFF);
  static const Color funcPink = Color(0xFFFF7B9C);
  static const Color funcPinkBg = Color(0xFFFFEDF2);
  static const Color funcBlue = Color(0xFF4DA3FF);
  static const Color funcBlueBg = Color(0xFFEAF4FF);

  // ---------- 品牌渐变 ----------
  static const LinearGradient brandGradient = LinearGradient(
    colors: [brandGradientStart, brandGradientEnd],
  );

  /// 登录/注销/绑定主按钮渐变（三色）
  static const LinearGradient brandButtonGradient = LinearGradient(
    colors: [brandGradient3Start, brandGradient3Mid, brandGradientEnd],
  );

  /// 咨询师端主按钮渐变
  static const LinearGradient indigoButtonGradient = LinearGradient(
    colors: [indigoGradientStart, indigoGradientEnd],
  );

  /// 首页咨询横幅渐变
  static const LinearGradient bannerGradient = LinearGradient(
    colors: [bannerGradientStart, bannerGradientEnd],
  );

  // ---------- 阶段 4：小鹿 AI 页 / 咨询师详情 / 排期弹层（XYAIModule） ----------

  /// 详情页链接/时段强调青（iOS 参照：XYCounselorDetailViewController Style.accentText）
  static const Color accentTeal = Color(0xFF00BBC8);

  /// 卡片内分隔线 0.5pt（iOS 参照：XYCounselorDetailViewController makeHairline）
  static const Color hairline = Color(0xFFF0F0F0);

  /// 聊天输入胶囊描边（iOS 参照：XYChatInputBar containerView borderColor）
  static const Color inputCapsuleBorder = Color(0xFFF9F9F9);

  /// 详情统计栏渐变顶/底（iOS 参照：XYCounselorDetailViewController statsInnerGradient）
  static const Color statsGradientTop = Color(0xFFF9F7FE);
  static const Color statsGradientBottom = Color(0xFFFDFDFE);

  /// 排期弹层选中态投影 rgba(180,204,204,0.22)
  /// （iOS 参照：XYAppointmentTimeSheetView Style.selectedShadow）
  static const Color selectedChipShadow = Color(0x38B4CCCC);

  /// AI 页 Tab 指示条三色渐变 #21DAE3 → #3EEEDA → #1DC8DF
  /// （iOS 参照：XYAIConsultViewController tabIndicatorGradient）
  static const LinearGradient aiTabIndicatorGradient = LinearGradient(
    colors: [Color(0xFF21DAE3), Color(0xFF3EEEDA), Color(0xFF1DC8DF)],
  );

  // ---------- 阶段 4 下半：订单 / 支付 / 评价 / 小结（XYAIModule/XYMessageModule） ----------

  /// 待支付状态徽标浅红底（iOS 参照：XYAppointmentOrderCell badgeBgRed）
  static const Color badgeBgRed = Color(0xFFFFECE9);

  /// 已取消/已完成状态徽标灰底（iOS 参照：XYAppointmentOrderCell badgeBgGray）
  static const Color badgeBgGray = Color(0xFFF6F6F6);

  /// 红色渐变按钮起点（去支付/退款类；iOS 参照：XYAppointmentOrderCell buttonRed）
  static const Color redGradientStart = Color(0xFFFF7B5E);

  /// 红色渐变按钮终点
  static const Color redGradientEnd = Color(0xFFFF5C71);

  /// 红色渐变按钮（左→右 #FF7B5E → #FF5C71）
  static const LinearGradient redButtonGradient = LinearGradient(
    colors: [redGradientStart, redGradientEnd],
  );

  /// 取消政策温馨提示卡底色（iOS 参照：XYAppointmentOrderDetailViewController tipBackground）
  static const Color tipBackground = Color(0xFFFFF9F4);

  /// 取消政策温馨提示文案（iOS 参照：同上 tipText）
  static const Color tipText = Color(0xFFFF6C00);

  /// 订单信息行图标灰 tint（iOS 参照：XYAppointmentOrderCell iconTint #9B9B9B）
  static const Color iconGray = Color(0xFF9B9B9B);

  /// 订单异常页图标外圈浅红底（iOS 参照：XYOrderExceptionViewController iconOuterBg）
  static const Color exceptionIconBg = Color(0xFFFDECEC);

  // ---------- 阶段 5A：消息 Tab / 系统通知（XYMessageModule） ----------

  /// 消息页背景（iOS 参照：XYMessageViewController Style.backgroundColor F5F7FA）
  static const Color messageBackground = Color(0xFFF5F7FA);

  /// 系统通知卡右侧箭头（iOS 参照：XYSystemNotificationCardView chevron A5ABBD）
  static const Color messageChevron = Color(0xFFA5ABBD);

  /// 会话头像占位底（iOS 参照：XYMessageConversationCell avatarIV E8E8E8）
  static const Color messageAvatarBg = Color(0xFFE8E8E8);

  /// 会话昵称（iOS 参照：XYMessageConversationCell nameLabel #333333）
  static const Color messageNameText = Color(0xFF333333);

  /// 会话预览图标 tint（iOS 参照：XYMessageConversationCell previewIconIV #BBBBBB）
  static const Color messagePreviewIcon = Color(0xFFBBBBBB);

  // ---------- 阶段 5B：聊天页气泡 / 卡片（TUIKit Minimalist / XYChatModule） ----------

  /// 自己发出的气泡底色（iOS 参照：TIMCommon/UI_Minimalist/
  /// TUIBubbleMessageCell_Minimalist.swift bubbleColor outgoing #00C5D5，Figma 558-3639）
  static const Color chatBubbleSelf = Color(0xFF00C5D5);

  /// 对方气泡底色（iOS 参照：同上 incomming #FFFFFF）
  static const Color chatBubbleOther = Color(0xFFFFFFFF);

  /// 语音录音中胶囊底色（iOS 参照：XYChatInputBar applyRecordingState #E5E5E5）
  static const Color chatRecordingBg = Color(0xFFE5E5E5);

  /// 语音上滑取消态胶囊底色（iOS 参照：XYChatInputBar isCancelZone #FF7B64）
  static const Color chatRecordingCancelBg = Color(0xFFFF7B64);

  /// 行动卡渐变底起点（iOS 参照：TUIForEvaluateMiddleCell/TUIQuestionAssistantCell
  /// cardGradientLayer #EBFEFF → #FDFDFE）
  static const Color chatCardGradientStart = Color(0xFFEBFEFF);

  /// 行动卡渐变底终点
  static const Color chatCardGradientEnd = Color(0xFFFDFDFE);

  /// 行动卡渐变（自上而下 #EBFEFF → #FDFDFE）
  static const LinearGradient chatCardGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [chatCardGradientStart, chatCardGradientEnd],
  );

  /// 评价/小结卡白圆底图标阴影（iOS 参照：TUIForEvaluateMiddleCell iconBadge #E2ECFF 70%）
  static const Color chatIconBadgeShadow = Color(0xB3E2ECFF);

  /// 面板 tile 底卡阴影（iOS 参照：XYChatInputBar tile card #9AA3B2 16%）
  static const Color chatPanelTileShadow = Color(0x299AA3B2);

  /// begin_chat_middle 底部行分割线（iOS 参照：TUIBeginChatMiddleCell divider #EBECF6，
  /// 与既有 lightPurpleDivider 同值）
  static const Color chatCardDivider = lightPurpleDivider;

  // ---------- 阶段 6：量表记录 / 账号与安全（XYMineModule） ----------

  /// 量表记录等级文字底部渐变条起点（右侧 #DCE5FF）
  /// （iOS 参照：XYMineAssessmentRecordCell levelGradientLayer，右→左渐变）
  static const Color recordLevelGradientStart = Color(0xFFDCE5FF);

  /// 量表记录等级文字底部渐变条终点（左侧 #C9E0EF）
  static const Color recordLevelGradientEnd = Color(0xFFC9E0EF);
}
