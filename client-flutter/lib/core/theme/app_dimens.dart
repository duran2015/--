/// 设计 token：尺寸/间距/圆角。
/// 来源：xinyuiOS XYHomeStyle 及各 VC Style 枚举（Figma÷2 后 pt 值）。
class AppDimens {
  AppDimens._();

  // ---------- 全局布局（XYHomeStyle） ----------
  static const double screenPadding = 15; // 屏幕左右留白（Figma 30→15）
  static const double sectionGap = 18; // 区块纵向间距（Figma 36→18）
  static const double cardPadding = 15; // 卡片内边距（Figma 30→15）
  static const double cardRadius = 20; // Material 3 标准卡片圆角
  static const double cardRadiusLarge = 28; // 大卡片/弹层圆角

  /// 卡片投影：#E6EAEE @50%，offset(0,3)，radius 6
  static const double cardShadowBlur = 6;
  static const double cardShadowOffsetY = 3;
  static const double cardShadowOpacity = 0.5;

  // ---------- 间距阶（SnapKit 高频值） ----------
  static const double gap4 = 4;
  static const double gap6 = 6;
  static const double gap8 = 8;
  static const double gap10 = 10;
  static const double gap12 = 12;
  static const double gap14 = 14;
  static const double gap15 = 15;
  static const double gap16 = 16;
  static const double gap18 = 18;
  static const double gap20 = 20;

  // ---------- 按钮 ----------
  static const double buttonHeight = 45; // 主按钮高
  static const double buttonRadiusCapsule = 22.5; // 主按钮胶囊圆角（45/2）
  static const double buttonHeightSmall = 36; // 次按钮
  static const double confirmButtonHeight = 53; // 心情弹窗确认按钮
  static const double confirmButtonRadius = 26.5; // 53/2
  static const double dialogButtonHeight = 44; // 弹窗按钮
  static const double retryButtonHeight = 50; // 异常页重试

  // ---------- 输入 ----------
  static const double loginInputHeight = 52; // 登录输入框，圆角 12
  static const double chatInputHeight = 51; // 聊天输入条
  static const double chatInputRadius = 25.5; // 51/2

  // ---------- TabBar（XYCustomTabBar） ----------
  /// 内容区高（不含 SafeArea）= 顶距 10 + 图标 22 + 间距 6 + 文案 11
  static const double tabBarContentHeight = 49;

  /// 图标距内容区顶
  static const double tabBarIconTop = 10;
  static const double tabIconSize = 22; // 22×22
  static const double tabIconTextGap = 6;
  static const double tabItemHeight = 39;

  // ---------- 小圆角 ----------
  static const double radiusTiny = 3; // 小竖条/小标签
  static const double radiusTag = 8;
  static const double radiusConsultTag = 12;
  static const double radiusInner = 16;
  static const double radiusMedium = 18;
  static const double radiusSpecial = 15;

  // ---------- 登录页特殊 ----------
  static const double loginPadding = 30; // 左右留白（Figma 60→30）
  static const double thirdPartyIconSize = 58; // 第三方登录图标 58×58
  static const double thirdPartyIconGap = 60;
  static const double appleIconPointSize = 26; // Apple 白苹果图标字号（圆内）

  // ---------- 登录流程（iOS XYLoginViewController / XYVerificationCodeViewController /
  // XYRoleSelectionViewController 各自 Style 枚举，Figma÷2 后 pt 值） ----------
  static const double loginTopPicTopOffset = 60; // 顶部欢迎图距安全区顶
  static const double loginTopPicWidth = 143; // 顶部欢迎图（Figma 286→143）
  static const double loginTopPicHeight = 141; // Figma 282→141
  static const double loginPhoneToTopPicGap = 36; // 输入区距顶部图底部
  static const double loginAgreementInset = 40; // 协议行左右留白（Figma 80→40）
  static const double loginCheckBoxSize = 14; // 协议勾选框视觉尺寸（Figma 28→14）
  static const double loginCheckBoxTapSize = 44; // 勾选热区（Apple 推荐最小点击区）
  static const double thirdPartyToAgreementGap = 20; // 第三方区距协议行（Figma 40→20）
  static const double loginCountryCodeDividerLeft = 68; // +86 分隔线距输入容器左
  static const double loginCountryCodeDividerHeight = 22; // 分隔线高
  static const double loginButtonDisabledAlpha = 0.3; // 未填手机号主按钮透明度
  static const double verifyCodeBoxGap = 15; // 验证码格间距
  static const double verifyCodeBoxRadius = 12; // 验证码格圆角（Figma 24→12）

  // ---------- 微信绑定手机号页（iOS XYWechatBindPhoneViewController Style 枚举） ----------
  static const double bindCardTopGap = 30; // 微信信息卡距副标题底
  static const double bindCardHeight = 64; // 微信信息卡高（Figma 128→64）
  static const double bindAvatarSize = 40; // 微信头像（Figma 80→40）
  static const double bindAvatarLeading = 15; // 头像距卡片左
  static const double bindInputTopGap = 32; // 手机号输入框距卡片底
  static const double roleCardHeight = 78; // 身份卡片高（Figma 156→78）
  static const double roleIconSize = 48; // 身份卡片图标（Figma 96→48）
  static const double roleCardTextGap = 9; // 卡片标题-描述间距（Figma 18→9）
  static const double roleCardBorderWidth = 0.5; // 卡片细边（iOS 1/scale）
  static const double launchContentWidth =
      169; // 启动页内容图（LaunchScreen.storyboard）
  static const double launchContentHeight = 245;

  // ---------- 阶段 5A：消息 Tab / 系统通知（XYMessageModule，Figma÷2） ----------
  static const double messageHorizontalInset = 16; // 页面左右留白（iOS 16pt）
  static const double messageSysIconSize = 40; // 系统通知铃铛图标（Figma 80→40）
  static const double messageAvatarSize = 44; // 会话头像
  static const double messageUnreadBadgeHeight =
      18; // 会话未读角标高（iOS XYUnreadBadgeView）
  static const double messagePreviewIconSize = 14; // 会话预览气泡图标
}
