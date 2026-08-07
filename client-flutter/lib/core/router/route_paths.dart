/// 内部路由路径常量。
/// 契约来源：contracts/route_code_contract.md §1（1001-1010 双端契约码）、
/// §2（9000 段 iOS 内部导航码）、§3（路由实现要点）。
class RoutePaths {
  RoutePaths._();

  // ---------- 启动 / 登录链路 ----------
  /// 启动页
  static const String splash = '/splash';

  /// 登录页（保持现有占位实现）
  static const String login = '/login';

  /// 短信验证码校验
  static const String loginVerify = '/login/verify';

  /// 绑定手机号
  static const String loginBindPhone = '/login/bind-phone';

  /// 选择身份（用户 / 咨询师）
  static const String loginSelectIdentity = '/login/select-identity';

  /// 咨询师入驻与资质申请（登录后，尚无 consultant 身份时进入）。
  static const String consultantOnboarding = '/consultant/onboarding';

  // ---------- 主壳 ----------
  /// 用户端主壳（含 tab）
  static const String home = '/home';

  /// 咨询师端统一出口（Web 环境跳转独立咨询师端）。
  static const String counselor = '/counselor';

  /// 咨询师端预约单详情，参数 orderId
  /// （iOS 参照：XYCounselorAppointmentDetailViewController，
  /// 工作台预约单 cell「查看详情」push；咨询师端内部导航，不占契约码）
  static const String counselorOrderDetail = '/counselor/order-detail';

  // ---------- 9000 段：iOS 内部导航码（契约 §2） ----------
  /// 9000：AI 咨询页（小鹿 Tab）
  static const String ai = '/ai';

  /// 9001：我的预约订单
  static const String orders = '/orders';

  /// 9002：小结与建议列表
  static const String mineSummaries = '/mine/summaries';

  /// 9003：量表测试记录
  static const String mineAssessments = '/mine/assessments';

  /// 9004：测评报告页，参数 assessmentId（=userAssessId）
  static const String assessmentReport = '/assessment/report';

  /// 全部测评列表（iOS XYHomeAssessmentListViewController，
  /// 首页「专业测评-全部」入口 push）
  static const String assessmentList = '/assessment/list';

  /// 9005：数字心理画像，参数 userId（咨询师端查看指定用户；
  /// iOS XYPersonalityViewController）
  static const String personality = '/mine/personality';

  /// 9006：账号与安全
  static const String mineSecurity = '/mine/security';

  /// 注销账号（账号与安全页 push；iOS XYCancelAccountViewController）
  static const String mineCancelAccount = '/mine/cancel-account';

  /// 黑名单管理（仅 debug 入口，账号与安全页 push）
  static const String mineBlacklist = '/mine/blacklist';

  /// 9007：意见反馈
  static const String mineFeedback = '/mine/feedback';

  /// 关于我们
  static const String mineAbout = '/mine/about';

  /// 我的支持档案：基础资料 / 咨询偏好 / 经授权支持档案。
  static const String supportProfile = '/mine/support-profile';

  /// 用户个人资料编辑（头像、昵称及基础展示信息）。
  static const String userProfileEdit = '/mine/profile-edit';

  // ---------- 通用 ----------
  /// http(s) 链接统一落地 WebView，参数 url（契约 §0）
  static const String webview = '/webview';

  // ---------- 1000 段：双端契约码（契约 §1） ----------
  /// 1005：IM 聊天
  static const String chat = '/chat';

  /// 系统通知列表页（消息 Tab 顶部入口 push；
  /// iOS 参照：XYSystemNotificationViewController，属 XYMessageModule 内部导航）
  static const String systemNotification = '/message/system-notification';

  /// 1006：咨询室薄壳页（深链入口 → consult_room_service 进房，
  /// 见 core/consult_room/consult_room_service.dart）
  static const String consultRoom = '/consult-room';

  /// 1007：咨询小结与建议详情，参数 orderId
  static const String summaryDetail = '/summary/detail';

  /// 1008：去评价，参数 orderId / counselorId
  static const String evaluate = '/evaluate';

  /// 1010：写咨询小结（咨询师端专属，守卫拦截用户端）
  static const String consultRecord = '/consultant/record';

  /// 1004：咨询师主页，参数 consultantId
  static const String consultantDetail = '/consultant/detail';

  /// 咨询师全部评价（分页页），参数 consultantId
  static const String consultantReviews = '/consultant/reviews';

  /// 排期预约（iOS 为详情页底部弹层 XYAppointmentTimeSheetView，
  /// 非常规路由页；常量预留给契约/深链对齐）
  static const String booking = '/booking';

  /// 支付页，参数 orderId（阶段 4 下半实现）
  static const String payment = '/payment';

  /// 支付成功页，参数 name/time/orderId（iOS 参照：XYPaymentSuccessViewController）
  static const String paymentSuccess = '/payment/success';

  /// 咨询前问卷 H5 容器，参数 orderId/imUserId/name/avatar
  ///（iOS 参照：XYIntakeWebViewController，H5 链接 h5.currantmind.cn/#/intake/{orderId}）
  static const String paymentIntake = '/payment/intake';

  /// 订单异常页（支付超时/失败；iOS 参照：XYOrderExceptionViewController）
  static const String paymentException = '/payment/exception';

  /// 预约订单详情，参数 orderId（iOS 参照：XYAppointmentOrderDetailViewController；
  /// 无独立详情接口，按 orderId 回查 my-list）
  static const String orderDetail = '/orders/detail';
}
