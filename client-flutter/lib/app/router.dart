import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'navigation.dart';
import '../core/auth/auth_controller.dart';
import '../core/auth/auth_state.dart';
import '../core/consult_room/consult_room_bridge_page.dart';
import '../core/router/route_guards.dart';
import '../core/router/route_paths.dart';
import '../core/webview/app_webview_page.dart';
import '../features/auth/bind_phone_page.dart';
import '../features/auth/login_page.dart';
import '../features/auth/select_identity_page.dart';
import '../features/auth/consultant_onboarding_page.dart';
import '../features/auth/consultant_portal_page.dart';
import '../features/auth/splash_page.dart';
import '../features/auth/verify_code_page.dart';
import '../features/ai/ai_consult_page.dart';
import '../features/chat/chat_page.dart';
import '../features/consultant/consultant_detail_page.dart';
import '../features/consultant/review_list_page.dart';
import '../features/counselor/consult_record_page.dart';
import '../features/counselor/counselor_order_detail_page.dart';
import '../features/evaluate/evaluate_page.dart';
import '../features/home/assessment_list_page.dart';
import '../features/home/assessment_report_page.dart';
import '../features/home/assessment_webview_page.dart';
import '../features/message/system_notification_page.dart';
import '../features/mine/account_security_page.dart';
import '../features/mine/assessment_record_page.dart';
import '../features/mine/blacklist_page.dart';
import '../features/mine/cancel_account_page.dart';
import '../features/mine/about_page.dart';
import '../features/mine/feedback_page.dart';
import '../features/mine/mine_summaries_page.dart';
import '../features/mine/personality_page.dart';
import '../features/order/my_orders_page.dart';
import '../features/order/order_detail_page.dart';
import '../features/payment/intake_webview_page.dart';
import '../features/payment/order_exception_page.dart';
import '../features/payment/payment_page.dart';
import '../features/payment/payment_success_page.dart';
import '../features/payment/payment_view_model.dart';
import '../features/profile/support_profile_page.dart';
import '../features/profile/support_profile_state.dart';
import '../features/profile/user_profile_edit_page.dart';
import '../features/summary/summary_detail_page.dart';
import '../features/shell/main_shell_page.dart';

/// 全局路由。
/// 契约来源：contracts/route_code_contract.md §3：
/// 1. 深链解析层（DeepLinkParser）与页面路由层分离；
/// 2. 1006 咨询室先落 PlaceholderPage 并打印透传参数（原生桥接属阶段 8）；
/// 4. 跳转前经 RouteGuards 校验登录态与身份（未登录 → /login；
///    咨询师专属码 1010 在用户端拦截 → /home）。
final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: RoutePaths.splash,
    redirect: (context, state) {
      final loggedIn = ref.read(authControllerProvider) != null;
      final identity = ref.read(currentIdentityProvider);
      return RouteGuards.guardRedirect(
        path: state.uri.path,
        loggedIn: loggedIn,
        identity: identity,
      );
    },
    routes: [
      // ---------- 启动 / 登录链路 ----------
      GoRoute(
        path: RoutePaths.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: RoutePaths.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: RoutePaths.loginVerify,
        builder: (context, state) => VerifyCodePage(
          phone: state.uri.queryParameters['phone'] ?? '',
          // mode=wechatBind → 微信绑定模式（iOS Mode.wechatBind），携带 preAuthToken
          mode: state.uri.queryParameters['mode'] == 'wechatBind'
              ? VerifyCodeMode.wechatBind
              : VerifyCodeMode.login,
          preAuthToken: state.uri.queryParameters['preAuthToken'] ?? '',
        ),
      ),
      GoRoute(
        path: RoutePaths.loginBindPhone,
        // 微信登录未绑定手机号 → 绑定页（iOS push XYWechatBindPhoneViewController）
        builder: (context, state) => BindPhonePage(
          preAuthToken: state.uri.queryParameters['preAuthToken'] ?? '',
          nickName: state.uri.queryParameters['nickName'],
          avatar: state.uri.queryParameters['avatar'],
        ),
      ),
      GoRoute(
        path: RoutePaths.loginSelectIdentity,
        builder: (context, state) => const SelectIdentityPage(),
      ),
      GoRoute(
        path: RoutePaths.consultantOnboarding,
        builder: (context, state) => const ConsultantOnboardingPage(),
      ),

      // ---------- 主壳 ----------
      GoRoute(
        path: RoutePaths.home,
        // 用户端主壳：首页/消息/我的三 Tab + 小鹿中央按钮（iOS XYMainTabBarController）
        builder: (context, state) => const MainShellPage(),
      ),
      GoRoute(
        path: RoutePaths.counselor,
        // 咨询师端使用独立 Web 原型；Flutter 只承载用户端。
        builder: (context, state) => const ConsultantPortalPage(),
      ),
      GoRoute(
        path: RoutePaths.counselorOrderDetail,
        // 咨询师端预约单详情（阶段 7）：orderId
        // iOS 参照：XYCounselorAppointmentDetailViewController
        builder: (context, state) => CounselorOrderDetailPage(
          orderId: int.tryParse(state.uri.queryParameters['orderId'] ?? ''),
        ),
      ),
      GoRoute(
        path: RoutePaths.assessmentList,
        builder: (context, state) => const AssessmentListPage(),
      ),

      // ---------- 9000 段（契约 §2） ----------
      GoRoute(
        path: RoutePaths.ai,
        // 9000 小鹿 AI 咨询页（阶段 4 上半：聊天壳 + guidance + 真人倾听师 Tab）
        builder: (context, state) => const AiConsultPage(),
      ),
      GoRoute(
        path: RoutePaths.orders,
        // 9001 我的预约订单（阶段 4 下半实现）
        // iOS 参照：XYMyAppointmentOrdersViewController
        builder: (context, state) => const MyOrdersPage(),
      ),
      GoRoute(
        path: RoutePaths.orderDetail,
        // 预约订单详情：orderId（回查 my-list 补齐展示数据）
        // iOS 参照：XYAppointmentOrderDetailViewController
        builder: (context, state) => OrderDetailPage(
          orderId: state.uri.queryParameters['orderId'] ?? '',
        ),
      ),
      GoRoute(
        path: RoutePaths.mineSummaries,
        // 9002 小结与建议列表（阶段 6）
        // iOS 参照：XYMineSummariesViewController
        builder: (context, state) => const MineSummariesPage(),
      ),
      GoRoute(
        path: RoutePaths.mineAssessments,
        // 9003 量表测试记录（阶段 6）
        // iOS 参照：XYMineAssessmentRecordViewController
        builder: (context, state) => const AssessmentRecordPage(),
      ),
      GoRoute(
        path: RoutePaths.assessmentReport,
        // 9004 测评报告页：assessmentId（=userAssessId）+ title/h5Link 可选
        // iOS 参照：XYHomeAssessmentReportViewController(routeParams:)
        builder: (context, state) {
          final q = state.uri.queryParameters;
          final rawId = q['userAssessId'] ?? q['assessmentId'];
          String? nonEmpty(String? v) {
            final t = v?.trim();
            return (t == null || t.isEmpty) ? null : t;
          }

          return AssessmentReportPage(
            userAssessId: int.tryParse(rawId?.trim() ?? ''),
            assessmentTitle:
                nonEmpty(q['title'] ?? q['assessmentTitle'] ?? q['name']),
            h5Link: nonEmpty(q['h5Link']),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.personality,
        // 9005 数字心理画像：userId（咨询师端查看指定用户）
        // iOS 参照：XYPersonalityViewController(userId:)
        builder: (context, state) {
          final raw = state.uri.queryParameters['userId'];
          return PersonalityPage(userId: int.tryParse(raw?.trim() ?? ''));
        },
      ),
      GoRoute(
        path: RoutePaths.mineSecurity,
        // 9006 账号与安全（阶段 6）
        // iOS 参照：XYAccountSecurityViewController
        builder: (context, state) => const AccountSecurityPage(),
      ),
      GoRoute(
        path: RoutePaths.mineCancelAccount,
        // 注销账号（阶段 6，账号与安全页 push）
        // iOS 参照：XYCancelAccountViewController
        builder: (context, state) => const CancelAccountPage(),
      ),
      GoRoute(
        path: RoutePaths.mineBlacklist,
        // 黑名单管理（仅 debug 入口）
        builder: (context, state) => const BlacklistPage(),
      ),
      GoRoute(
        path: RoutePaths.mineFeedback,
        // 9007 意见反馈（我的 → 更多）
        // iOS 参照：XYFeedbackViewController
        builder: (context, state) => const FeedbackPage(),
      ),
      GoRoute(
        path: RoutePaths.mineAbout,
        // 关于我们
        builder: (context, state) => const AboutPage(),
      ),
      GoRoute(
        path: RoutePaths.supportProfile,
        builder: (context, state) {
          final section = switch (state.uri.queryParameters['section']) {
            'basic' => SupportProfileSection.basic,
            'preference' => SupportProfileSection.preference,
            'support' => SupportProfileSection.support,
            _ => null,
          };
          return SupportProfilePage(initialSection: section);
        },
      ),
      GoRoute(
        path: RoutePaths.userProfileEdit,
        builder: (context, state) => const UserProfileEditPage(),
      ),

      // ---------- 通用 ----------
      GoRoute(
        path: RoutePaths.webview,
        // http(s) 链接统一落地 WebView 容器（契约 §0）；
        // mode=assessment → 测评答题容器（iOS XYAssessmentWebViewController）
        builder: (context, state) {
          final url = state.uri.queryParameters['url'] ?? '';
          final title = state.uri.queryParameters['title'];
          if (state.uri.queryParameters['mode'] == 'assessment') {
            return AssessmentWebViewPage(url: url, title: title);
          }
          return AppWebViewPage(url: url, title: title);
        },
      ),

      // ---------- 1000 段（契约 §1） ----------
      GoRoute(
        path: RoutePaths.chat,
        // 1005 IM 聊天：targetUserId/imUserId（空→机器人）、userName、avatar、tags
        // iOS 参照：XYChatContainerViewController（XYChatRouter 打开）
        builder: (context, state) {
          final q = state.uri.queryParameters;
          final tagsStr = q['tags'];
          return ChatPage(
            targetUserId: q['targetUserId'] ?? q['imUserId'],
            userName: q['userName'],
            avatar: q['avatar'],
            consultantId: int.tryParse(q['consultantId'] ?? ''),
            orderId: q['orderId'],
            consultantIntro: q['consultantIntro'],
            bookedSku: q['bookedSku'],
            tags: (tagsStr != null && tagsStr.isNotEmpty)
                ? tagsStr.split(',')
                : null,
          );
        },
      ),
      GoRoute(
        path: RoutePaths.systemNotification,
        // 系统通知列表页（阶段 5A）
        // iOS 参照：XYSystemNotificationViewController
        builder: (context, state) => const SystemNotificationPage(),
      ),
      GoRoute(
        path: RoutePaths.consultRoom,
        // 1006：深链兼容入口。透明零动画页，立刻 present 原生会议并自 pop。
        // 业务入口请直接 launchConsultRoom，勿 push 本路由。
        pageBuilder: (context, state) {
          return CustomTransitionPage<void>(
            key: state.pageKey,
            opaque: false,
            barrierDismissible: false,
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
            transitionsBuilder: (_, __, ___, child) => child,
            child: ConsultRoomBridgePage(
              query: state.uri.queryParameters,
            ),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.summaryDetail,
        // 1007 咨询小结与建议详情：orderId 多键兼容
        // iOS 参照：XYSummaryAdviseViewController(routeParams:)
        builder: (context, state) {
          final q = state.uri.queryParameters;
          final rawId = q['orderId'] ?? q['orderID'] ?? q['order_id'];
          return SummaryDetailPage(orderId: int.tryParse(rawId ?? ''));
        },
      ),
      GoRoute(
        path: RoutePaths.evaluate,
        // 1008 评价咨询师：orderId + counselorId/consultantId 多键兼容
        // iOS 参照：XYEvaluateViewController resolved* 系列方法
        builder: (context, state) {
          final q = state.uri.queryParameters;
          String firstNonEmpty(List<String> keys, [String fallback = '']) {
            for (final k in keys) {
              final v = q[k]?.trim();
              if (v != null && v.isNotEmpty) return v;
            }
            return fallback;
          }

          return EvaluatePage(
            orderId: firstNonEmpty(const ['orderId', 'order_id', 'orderID']),
            counselorId:
                firstNonEmpty(const ['counselorId', 'userId', 'consultantId']),
            counselorName: firstNonEmpty(
              const ['counselorName', 'name', 'consultantName'],
              '咨询师',
            ),
            counselorAvatar: firstNonEmpty(
              const ['counselorAvatar', 'avatar', 'consultantAvatar'],
            ).isEmpty
                ? null
                : firstNonEmpty(
                    const ['counselorAvatar', 'avatar', 'consultantAvatar']),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.consultRecord,
        // 1010 写咨询小结（阶段 7，咨询师专属）：orderId 多键兼容
        // iOS 参照：XYCounselorConsultRecordViewController resolvedOrderId
        builder: (context, state) {
          final q = state.uri.queryParameters;
          final rawId = q['orderId'] ?? q['order_id'] ?? q['orderID'];
          return ConsultRecordPage(orderId: int.tryParse(rawId ?? ''));
        },
      ),
      GoRoute(
        path: RoutePaths.consultantDetail,
        // 1004 咨询师主页，参数 consultantId（阶段 4 上半实现）
        builder: (context, state) => ConsultantDetailPage(
          consultantId:
              int.tryParse(state.uri.queryParameters['consultantId'] ?? '') ??
                  0,
        ),
      ),
      GoRoute(
        path: RoutePaths.consultantReviews,
        builder: (context, state) => ReviewListPage(
          consultantId:
              int.tryParse(state.uri.queryParameters['consultantId'] ?? '') ??
                  0,
        ),
      ),
      GoRoute(
        path: RoutePaths.payment,
        // 支付页（阶段 4 下半）：orderId 必传，其余展示参数可选
        // （预约下单入口仅 orderId，页面回查 my-list 补齐）
        // iOS 参照：XYPaymentViewController
        builder: (context, state) => PaymentPage(
          args: PaymentPageArgs.fromQuery(state.uri.queryParameters),
        ),
      ),
      GoRoute(
        path: RoutePaths.paymentSuccess,
        // 支付成功页：name/time/orderId（+imUserId/avatar 供咨询前问卷跳聊天）
        // iOS 参照：XYPaymentSuccessViewController
        builder: (context, state) {
          final q = state.uri.queryParameters;
          return PaymentSuccessPage(
            counselorName: q['name'] ?? '',
            appointmentTime: q['time'] ?? '',
            orderId: q['orderId'] ?? '',
            counselorIMUserID: q['imUserId'] ?? '',
            counselorAvatar: q['avatar'],
          );
        },
      ),
      GoRoute(
        path: RoutePaths.paymentIntake,
        // 咨询前问卷 H5 容器：orderId/imUserId/name/avatar
        // iOS 参照：XYIntakeWebViewController
        builder: (context, state) {
          final q = state.uri.queryParameters;
          return IntakeWebViewPage(
            orderId: q['orderId'] ?? '',
            counselorIMUserID: q['imUserId'] ?? '',
            counselorName: q['name'] ?? '',
            counselorAvatar: q['avatar'],
          );
        },
      ),
      GoRoute(
        path: RoutePaths.paymentException,
        // 订单异常页（支付超时/失败）
        // iOS 参照：XYOrderExceptionViewController
        builder: (context, state) => const OrderExceptionPage(),
      ),
    ],
  );

  // 登录态变化时重新执行 redirect（如 401 登出 → 自动回 /login）
  ref.listen(authControllerProvider, (_, __) => router.refresh());

  return router;
});
