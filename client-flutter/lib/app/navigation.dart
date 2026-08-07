import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/auth/auth_controller.dart';
import '../core/consult_room/consult_room_service.dart';
import '../core/im/im_config.dart';
import '../core/im/im_service.dart';
import '../core/im/im_session_controller.dart';
import '../core/router/route_paths.dart';
import '../core/widgets/app_toast.dart';
import '../features/auth/auth_view_model.dart';
import '../features/consultant/consultant_api.dart';
import '../features/counselor/counselor_api.dart';
import '../features/counselor/counselor_models.dart';
import '../features/counselor/counselor_workbench_page.dart';
import '../features/home/home_view_model.dart';
import '../features/message/message_view_model.dart';
import '../features/order/order_api.dart';
import '../features/shell/main_shell_page.dart';

/// 根导航器 key：路由外的全局弹窗（如 IM userSig 过期/被踢下线的
/// 「登录已过期」「账号已下线」）需要脱离页面 context 弹 AppCenterDialog。
/// iOS 参照：XYSessionManager.topViewController/appRootViewController 取弹窗依托。
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// 绑定咨询室原生回调的全局导航（App 启动后挂一次即可）。
/// 「聊天」不依赖 /consult-room 桥接页存活，悬浮窗恢复会议后可再次进入聊天。
void bindConsultRoomNavigation(ConsultRoomService service) {
  service.onOpenChat = ({
    required String imUserId,
    String? userName,
    String? userAvatar,
  }) {
    debugPrint(
      '🟢 [ConsultRoom] onOpenChat imUserId=$imUserId '
      'name=$userName active=${service.activeParams?.imUserId}',
    );
    // 勿用 addPostFrameCallback：全屏原生 modal 盖住时可能永不触发下一帧。
    // 稍延后让 dismiss 动画开始，再 push，避免被会议页挡住。
    Future<void>.delayed(const Duration(milliseconds: 120), () {
      openConsultRoomPeerChat(
        service: service,
        imUserId: imUserId,
        userName: userName,
        userAvatar: userAvatar,
      );
    });
  };
}

/// 会议内点「聊天」：打开 Flutter IM 1v1（通话保持在悬浮窗）。
///
/// 若栈顶已是与会议对方的聊天页则不再 push（go_router 的 push 为
/// ImperativeRouteMatch，必须用 [GoRouter.state.uri] 判断，不能用
/// currentConfiguration.uri——后者不包含 imperative push 的页面）。
void openConsultRoomPeerChat({
  required ConsultRoomService service,
  required String imUserId,
  String? userName,
  String? userAvatar,
}) {
  final ctx = rootNavigatorKey.currentContext;
  if (ctx == null) {
    debugPrint('🔴 [ConsultRoom] openChat 失败：rootNavigatorKey.context 为空');
    return;
  }

  final fallback = service.activeParams;
  final peerId = imUserId.trim().isNotEmpty
      ? imUserId.trim()
      : (fallback?.imUserId?.trim() ?? '');
  if (peerId.isEmpty) {
    debugPrint('🔴 [ConsultRoom] openChat 失败：对方 imUserId 为空');
    AppToast.show(ctx, '对方信息缺失');
    return;
  }
  final name = (userName?.trim().isNotEmpty ?? false)
      ? userName!.trim()
      : (fallback?.userName?.trim() ?? '');
  final avatar = (userAvatar?.trim().isNotEmpty ?? false)
      ? userAvatar!.trim()
      : (fallback?.userAvatar?.trim() ?? '');

  final router = GoRouter.of(ctx);
  if (isTopChatWithPeer(router.state.uri, peerId)) {
    debugPrint('🟠 [ConsultRoom] openChat 跳过：已在与 $peerId 的聊天页');
    return;
  }

  final location = Uri(path: RoutePaths.chat, queryParameters: {
    'targetUserId': peerId,
    if (name.isNotEmpty) 'userName': name,
    if (avatar.isNotEmpty) 'avatar': avatar,
  }).toString();
  debugPrint('🟢 [ConsultRoom] push chat → $location');
  router.push(location);
}

/// 当前顶层路由是否已是与 [peerId] 的 IM 聊天页。
@visibleForTesting
bool isTopChatWithPeer(Uri uri, String peerId) {
  if (uri.path != RoutePaths.chat) return false;
  final current = (uri.queryParameters['targetUserId'] ??
          uri.queryParameters['imUserId'] ??
          '')
      .trim();
  return current.isNotEmpty && current == peerId.trim();
}

/// 调试/自动化走查用：全局跳转（供 VM Service evaluate 驱动，见 xinyu/tools/vm_nav.dart）。
void debugNavigate(String location) {
  final ctx = rootNavigatorKey.currentContext;
  if (ctx != null) GoRouter.of(ctx).push(location);
}

/// 调试/联调用：清登录态（secure storage + 内存），路由 redirect 自动回登录页。
/// 供 VM Service evaluate 驱动，解决模拟器 keychain 卸载残留导致的旧登录态。
Future<void> debugLogout() async {
  final ctx = rootNavigatorKey.currentContext;
  if (ctx == null) return;
  final container = ProviderScope.containerOf(ctx, listen: false);
  await container.read(authControllerProvider.notifier).logout();
}

// ---------------------------------------------------------------------------
// 联调验证驱动（阶段 2a，API_ENV=live）：供 tools/vm_nav.dart evaluate 调用。
// 异步结果写入 [debugLiveResult]，调用方延时后读取。
// ---------------------------------------------------------------------------

/// 最近一次联调驱动的结果（JSON / 错误文本）。
String debugLiveResult = '';

ProviderContainer _debugContainer() => ProviderScope.containerOf(
      rootNavigatorKey.currentContext!,
      listen: false,
    );

void _debugRun(Future<Object?> Function() action) {
  debugLiveResult = '';
  action().then((v) {
    debugLiveResult = '$v';
    debugPrint('[DEBUG_LIVE] $debugLiveResult'); // flutter run 日志取全量
  }).catchError((Object e) {
    debugLiveResult = 'ERR: $e';
    debugPrint('[DEBUG_LIVE] $debugLiveResult');
  });
}

/// 提交今日情绪（POST /app/user/mood）并强制刷新趋势。
void debugSubmitMood(String note) {
  _debugRun(() async {
    final vm = _debugContainer().read(homeViewModelProvider.notifier);
    final msg = await vm.submitTodayMood(note: note);
    await vm.fetchMoodTrend(force: true);
    return msg;
  });
}

/// 拉取本月情绪月历（POST /app/user/mood/calendar）。
void debugFetchMoodCalendar() {
  _debugRun(() async {
    final vm = _debugContainer().read(homeViewModelProvider.notifier);
    await vm.fetchMoodCalendar(
      year: vm.calendarYear,
      month: vm.calendarMonth,
    );
    final days = vm.monthMoods(vm.calendarYear, vm.calendarMonth);
    return jsonEncode({
      'year': vm.calendarYear,
      'month': vm.calendarMonth,
      'days': days.map((e) => e.day).toList(),
    });
  });
}

/// 测评列表（POST /app/assessment/list）：id/名称/状态/userAssessId/h5Link。
void debugAssessmentListJson() {
  _debugRun(() async {
    final items =
        await _debugContainer().read(homeApiProvider).fetchAssessmentList();
    return jsonEncode([
      for (final e in items)
        {
          'questionnaireId': e.questionnaireId,
          'key': e.questionnaireKey,
          'name': e.name,
          'status': e.userAssessStatus,
          'userAssessId': e.userAssessId,
          'h5Link': e.h5Link,
          'questionCount': e.questionCount,
          'testedCount': e.testedCount,
        },
    ]);
  });
}

/// 测评报告详情（POST /app/assessment/detail）。
void debugAssessmentDetailJson(int userAssessId) {
  _debugRun(() async {
    final d = await _debugContainer()
        .read(homeApiProvider)
        .fetchAssessmentDetail(userAssessId);
    return jsonEncode({
      'assessDate': d?.assessDate,
      'totalScore': d?.totalScore,
      'level': d?.level,
      'tags': d?.symptomTags,
      'suggestionsCount': d?.suggestions?.length,
      'interpretationLen': d?.interpretation?.length,
      'sourceUrl': d?.sourceUrl,
    });
  });
}

/// 咨询师列表（POST /app/consultant/list，pageSize 50 一页看全）。
void debugConsultantListJson() {
  _debugRun(() async {
    final r = await _debugContainer()
        .read(consultantApiProvider)
        .fetchList(pageNum: 1, pageSize: 50);
    return jsonEncode({
      'total': r.total,
      'rows': [
        for (final e in r.rows)
          {
            'consultantId': e.consultantId,
            'realName': e.realName,
            'title': e.title,
            'minPrice': e.minPrice,
            'rating': e.ratingScore,
            'serviceCount': e.serviceCount,
            'hours': e.totalServiceHours,
            'specialty': e.specialtyTags,
            'status': e.status,
          },
      ],
    });
  });
}

/// 咨询师详情（POST /app/consultant/detail）：能力/排期/评价概要。
void debugConsultantDetailJson(int consultantId) {
  _debugRun(() async {
    final d = await _debugContainer()
        .read(consultantApiProvider)
        .fetchDetail(consultantId: consultantId);
    return jsonEncode({
      'consultantId': d.consultantId,
      'realName': d.realName,
      'title': d.title,
      'introLen': d.introduction?.length,
      'capabilities': [
        for (final c in d.capabilities)
          {
            'capabilityId': c.capabilityId,
            'name': c.capabilityName,
            'price': c.price,
            'duration': c.duration,
            'supportMode': c.supportMode,
          },
      ],
      'reviewStats': d.reviewStats == null
          ? null
          : {
              'avgStar': d.reviewStats!.avgStar,
              'goodRate': d.reviewStats!.goodRate,
              'totalCount': d.reviewStats!.totalCount,
            },
      'certCount': d.certifications.length,
      'availabilityCount': d.recentAvailability.length,
      'freeSlots': d.recentAvailability
          .where((e) => (e.isBooked ?? '0') == '0')
          .length,
      'reviewsCount': d.reviews.length,
      'imUserId': d.imUserId,
    });
  });
}

/// 咨询师评价列表（POST /app/consultant/review-list）。
void debugReviewListJson(int consultantId) {
  _debugRun(() async {
    final r = await _debugContainer()
        .read(consultantApiProvider)
        .fetchReviewList(consultantId: consultantId, pageNum: 1);
    return jsonEncode({
      'total': r.total,
      'rows': [
        for (final e in r.rows)
          {
            'reviewId': e.reviewId,
            'nick': e.userNickName,
            'rating': e.rating,
            'contentLen': e.content?.length,
            'tags': e.tagNames,
            'createTime': e.createTime,
          },
      ],
    });
  });
}

/// 预约下单（POST /app/consultant/book）：
/// 列表取最低价咨询师 → 详情取最便宜能力与首个未约时段组 body；
/// price > 0 只返回 body（不真实提交），0 元单真实提交。
/// 下单参数构造对齐 iOS XYAppointmentTimeSheetViewModel.book（契约 §2.3 #12）。
void debugBookCheapest({bool submitIfFree = true}) {
  _debugRun(() async {
    final api = _debugContainer().read(consultantApiProvider);
    final list = await api.fetchList(pageNum: 1, pageSize: 50);
    final rows = list.rows
        .where((e) => e.consultantId != null)
        .toList()
      ..sort((a, b) => (a.minPrice ?? 1e9).compareTo(b.minPrice ?? 1e9));
    if (rows.isEmpty) return 'ERR: 咨询师列表为空';
    final target = rows.first;
    final detail =
        await api.fetchDetail(consultantId: target.consultantId!);
    final caps = detail.capabilities
        .where((c) => c.capabilityId != null)
        .toList()
      ..sort((a, b) => (a.price ?? 1e9).compareTo(b.price ?? 1e9));
    final slot = detail.recentAvailability.firstWhere(
      (e) => (e.isBooked ?? '0') == '0' && e.availabilityId != null,
      orElse: () => throw StateError('无可约时段'),
    );
    if (caps.isEmpty) return 'ERR: 无咨询能力';
    final cap = caps.first;
    final body = <String, dynamic>{
      'consultantId': target.consultantId,
      'capabilityId': cap.capabilityId ?? 0,
      'availabilityId': slot.availabilityId ?? 0,
      'supportMode': cap.supportMode ?? '',
      'appointmentTime': '${slot.availableDate} ${slot.startTime}',
    };
    final price = cap.price ?? 0;
    if (price > 0 || !submitIfFree) {
      return jsonEncode({
        'dryRun': true,
        'reason': 'price=$price > 0，按约定不真实提交',
        'consultant': target.realName,
        'body': body,
      });
    }
    final order = await api.book(body);
    return jsonEncode({
      'dryRun': false,
      'consultant': target.realName,
      'body': body,
      'orderId': order.orderId,
      'orderNo': order.orderNo,
      'payStatus': order.payStatus,
      'price': order.price,
      'paymentDeadline': order.paymentDeadline,
      'appointmentStartTime': order.appointmentStartTime,
      'statusDesc': order.statusDesc,
    });
  });
}

/// 我的预约订单（POST /app/consultant/order/my-list）。
void debugOrderListJson() {
  _debugRun(() async {
    final r = await _debugContainer()
        .read(orderApiProvider)
        .fetchMyOrders(pageNum: 1, pageSize: 20);
    return jsonEncode({
      'total': r.total,
      'rows': [
        for (final e in r.rows)
          {
            'orderId': e.orderId,
            'consultantName': e.counselorName,
            'displayStatus': e.displayStatus,
            'statusText': e.statusText,
            'appointmentTime': e.appointmentTimeDisplay,
            'price': e.price,
            'duration': e.durationDisplay,
            'supportModeDesc': e.supportModeDesc,
          },
      ],
    });
  });
}

// ---------------------------------------------------------------------------
// 联调验证驱动（阶段 2b，咨询师端，API_ENV=live）
// ---------------------------------------------------------------------------

/// 切换身份（POST /app/auth/selectIdentity）：'consultant' / 'user'。
void debugSwitchIdentity(String identity) {
  _debugRun(() async {
    final route = await _debugContainer()
        .read(authViewModelProvider.notifier)
        .selectIdentity(identity);
    final auth = _debugContainer().read(authControllerProvider);
    return jsonEncode({
      'route': route,
      'currentIdentity': auth?.currentIdentity,
      'consultantId': auth?.consultantId,
      'availableIdentities': auth?.availableIdentities,
      'imUserId': auth?.imUserId,
    });
  });
}

/// 工作台首页（POST /consultant/home/index）。
void debugCounselorHomeJson() {
  _debugRun(() async {
    final d = await _debugContainer().read(counselorApiProvider).fetchHomeIndex();
    return jsonEncode({
      'name': d.name,
      'title': d.title,
      'avatarLen': d.avatar?.length,
      'satisfactionText': d.satisfactionText,
      'pendingCount': d.pendingCount,
      'completedCount': d.completedCount,
      'unreadMessageCount': d.unreadMessageCount,
      'acceptRateText': d.acceptRateText,
    });
  });
}

/// 待处理预约（POST /consultant/home/pendingList）。
void debugCounselorPendingJson() {
  _debugRun(() async {
    final r = await _debugContainer()
        .read(counselorApiProvider)
        .fetchPendingList(pageNum: 1);
    return jsonEncode({
      'total': r.total,
      'rows': [
        for (final e in r.rows)
          {
            'orderId': e.orderId,
            'userName': e.userName,
            'timeText': e.timeText,
            'dayText': e.dayText,
            'supportMode': e.supportMode.name,
            'tags': e.tags,
            'emotionSummary': e.emotionSummary,
            'roomId': e.roomId,
            'roomName': e.roomName,
            'imUserId': e.imUserId,
          },
      ],
    });
  });
}

/// 已咨询列表（POST /consultant/home/completedList）。
void debugCounselorCompletedJson() {
  _debugRun(() async {
    final r = await _debugContainer()
        .read(counselorApiProvider)
        .fetchCompletedList(pageNum: 1);
    return jsonEncode({
      'total': r.total,
      'rows': [
        for (final e in r.rows)
          {
            'orderId': e.orderId,
            'userName': e.userName,
            'timeText': e.timeText,
            'dayText': e.dayText,
            'supportMode': e.supportMode.name,
            'tags': e.tags,
            'hasSummary': e.hasSummary,
            'imUserId': e.imUserId,
          },
      ],
    });
  });
}

/// 预约单详情（POST /consultant/home/orderDetail）。
void debugCounselorOrderDetailJson(int orderId) {
  _debugRun(() async {
    final d = await _debugContainer()
        .read(counselorApiProvider)
        .fetchOrderDetail(orderId);
    final item = CounselorOrderDetailItem.fromDetail(d);
    return jsonEncode({
      'orderId': item.orderId,
      'timeText': item.timeText,
      'dayText': item.dayText,
      'supportMode': item.supportMode.name,
      'userName': item.userName,
      'userSubtitle': item.userSubtitle,
      'imUserId': item.imUserId,
      'userId': item.userId,
      'tags': item.tags,
      'emotionSummary': item.emotionSummary,
      'historyTotal': item.historyTotal,
      'historyPreview': [
        for (final h in item.historyRecords)
          {'date': h.dateText, 'mode': h.modeText, 'summaryLen': h.summary.length},
      ],
    });
  });
}

/// 过往接待（POST /consultant/home/pastConsultations）。
void debugCounselorPastConsultationsJson(int orderId) {
  _debugRun(() async {
    final r = await _debugContainer()
        .read(counselorApiProvider)
        .fetchPastConsultations(orderId: orderId, pageNum: 1);
    return jsonEncode({
      'total': r.total,
      'rows': [
        for (final e in r.rows)
          {'date': e.dateText, 'mode': e.modeText, 'summaryLen': e.summary.length},
      ],
    });
  });
}

/// 小结详情（POST /consultant/summary/detail）：AI 提取三段回填。
void debugCounselorSummaryDetailJson(int orderId) {
  _debugRun(() async {
    final d = await _debugContainer()
        .read(counselorApiProvider)
        .fetchSummaryDetail(orderId);
    return jsonEncode({
      'aiMainTopic': d?.aiMainTopic,
      'aiEmotionalState': d?.aiEmotionalState,
      'aiCoreConflict': d?.aiCoreConflict,
    });
  });
}

/// 开始咨询校验（POST /consultant/order/start）。⚠ 写接口：仅对到时间的
/// 真实预约单调用；未到时间预期后端返回失败 msg（同样验证请求构造与解析）。
void debugCounselorStartOrder(int orderId) {
  _debugRun(() async {
    await _debugContainer().read(counselorApiProvider).startOrder(orderId);
    return 'OK: 校验通过（code==200）';
  });
}

/// 咨询室进房校验（POST /app/consultant/room/join，参数透传验证；不进房）。
void debugRoomJoinMessage(int orderId) {
  _debugRun(() async {
    await _debugContainer().read(orderApiProvider).joinConsultRoom(orderId);
    return 'OK: 校验通过（code==200）';
  });
}

/// 保存小结 dry-run：只构造请求体并返回，不提交（避免污染真实数据）。
void debugCounselorSaveSummaryDryRun(int orderId) {
  _debugRun(() async {
    final body = <String, dynamic>{
      'orderId': orderId,
      'content': '（dry-run 构造验证，未提交）',
      'advice': ['建议一', '建议二'],
    };
    return jsonEncode({'dryRun': true, 'path': CounselorApi.summarySavePath, 'body': body});
  });
}

/// 切换咨询师工作台 Tab（0 预约单 / 1 已咨询 / 2 消息）。
void debugSelectCounselorTab(int tab) {
  final ctx = rootNavigatorKey.currentContext;
  if (ctx == null) return;
  void visit(Element e) {
    if (e is StatefulElement && e.state is CounselorWorkbenchDebugHandle) {
      (e.state as CounselorWorkbenchDebugHandle).selectTabForDebug(tab);
      return;
    }
    e.visitChildren(visit);
  }

  visit(ctx as Element);
}

// ---------------------------------------------------------------------------
// 联调验证驱动（IM 复验，SDKAppID 修正为 1600153349 后）
// ---------------------------------------------------------------------------

/// 切换用户端主壳底部 Tab（0 首页 / 1 消息 / 2 我的）。
void debugSelectMainTab(int index) {
  final ctx = rootNavigatorKey.currentContext;
  if (ctx == null) return;
  void visit(Element e) {
    if (e is StatefulElement && e.state is MainShellDebugHandle) {
      (e.state as MainShellDebugHandle).selectTabForDebug(index);
      return;
    }
    e.visitChildren(visit);
  }

  visit(ctx as Element);
}

/// IM 登录状态 + 未读总数 + 会话列表概览。
void debugImConversationJson() {
  _debugRun(() async {
    final c = _debugContainer();
    final loggedIn = c.read(imSessionControllerProvider);
    final state = c.read(messageViewModelProvider);
    // 触发一次主动拉取，确保拿到最新会话
    await c.read(imServiceProvider).fetchConversations();
    return jsonEncode({
      'imLoggedIn': loggedIn,
      'unreadTotal': state.conversationUnreadTotal,
      'systemNotification': state.systemNotification == null
          ? null
          : {
              'userId': state.systemNotification!.userId,
              'preview': state.systemNotification!.lastMessagePreview,
              'unread': state.systemNotification!.unreadCount,
              'timestamp': state.systemNotification!.timestamp?.toIso8601String(),
            },
      'conversations': [
        for (final e in state.conversations)
          {
            'userId': e.userId,
            'showName': e.showName,
            'preview': e.lastMessagePreview,
            'unread': e.unreadCount,
            'timestamp': e.timestamp?.toIso8601String(),
          },
      ],
    });
  });
}

/// 系统通知会话历史消息（c2c_sysnotification，最近 count 条）。
void debugSystemNotificationJson({int count = 20}) {
  _debugRun(() async {
    final msgs = await _debugContainer()
        .read(imServiceProvider)
        .historyMessages(userId: ImConfig.systemNotificationUserId, count: count);
    return jsonEncode([
      for (final m in msgs)
        {
          'msgId': m.msgId,
          'kind': m.kind.name,
          'text': m.text,
          'customLen': m.customJson?.length,
          'timestamp': m.timestamp?.toIso8601String(),
          'isSelf': m.isSelf,
        },
    ]);
  });
}

/// 指定会话历史消息（最近 count 条）。
void debugChatHistoryJson(String userId, {int count = 20}) {
  _debugRun(() async {
    final msgs = await _debugContainer()
        .read(imServiceProvider)
        .historyMessages(userId: userId, count: count);
    return jsonEncode([
      for (final m in msgs)
        {
          'msgId': m.msgId,
          'kind': m.kind.name,
          'text': m.text,
          'customLen': m.customJson?.length,
          'sender': m.senderId,
          'isSelf': m.isSelf,
        },
    ]);
  });
}

/// 给小鹿 AI（@RBT#xinyu001）发文本并等待回复（最长 30s，每 3s 轮询历史）。
/// 返回发送回执 + 最终检测到的 AI 回复。
void debugAiChatRoundTrip(String text) {
  _debugRun(() async {
    final service = _debugContainer().read(imServiceProvider);
    final sent = await service.sendTextMessage(
      userId: ImConfig.robotUserId,
      text: text,
    );
    final sentId = sent.msgId;
    String? reply;
    for (var i = 0; i < 10 && reply == null; i++) {
      await Future<void>.delayed(const Duration(seconds: 3));
      final history =
          await service.historyMessages(userId: ImConfig.robotUserId, count: 10);
      for (final m in history.reversed) {
        if (!m.isSelf && (m.text?.isNotEmpty ?? false)) {
          // 排除发送前的旧回复：只认发送时间之后的消息
          if (m.timestamp != null &&
              sent.timestamp != null &&
              m.timestamp!.isAfter(sent.timestamp!)) {
            reply = m.text;
            break;
          }
        }
      }
    }
    return jsonEncode({
      'sent': {'msgId': sentId, 'text': sent.text, 'isSelf': sent.isSelf},
      'aiReply': reply,
    });
  });
}

/// 咨询室进房实测（IM 复验项）：验证 enterRoom 错误传播。
/// ⚠ 需要 roomId 的订单；当前账号无到时间预约单，仅验证进房行为不进真实会议。
void debugEnterRoomBridge(String orderId, String roomId, String supportMode) {
  _debugRun(() async {
    final service = _debugContainer().read(consultRoomServiceProvider);
    final r = await service.enterRoom(ConsultRoomParams(
      orderId: orderId,
      roomId: roomId,
      supportMode: supportMode,
      roomName: '联调验证',
    ));
    return '${r.status.name}: ${r.message}';
  });
}
