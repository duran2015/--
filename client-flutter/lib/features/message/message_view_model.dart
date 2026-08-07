import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/im/im_config.dart';
import '../../core/im/im_models.dart';
import '../../core/im/im_service.dart';
import '../../core/im/middle_card_unread.dart';

/// 会话列表数据源：先拉一次，随后跟随服务层推送流。
/// iOS 参照：XYMessageViewModel.loadAndObserve（拉会话 + 监听变化）；
/// Android 参照：MessageFragment.conversationListener。
final conversationListProvider = StreamProvider<List<ImConversation>>(
  (ref) async* {
    final service = ref.watch(imServiceProvider);
    yield await service.fetchConversations();
    yield* service.conversationStream;
  },
);

/// 消息页状态（iOS 参照：XYMessageViewModel 的私有字段与派生属性）。
class MessageViewState {
  const MessageViewState({
    this.systemNotification,
    this.conversations = const [],
    this.robotUnreadCount = 0,
  });

  /// 系统通知会话摘要（sysNotification 账号，驱动顶部系统通知卡片）
  final ImConversation? systemNotification;

  /// 普通对话列表（已剔除机器人 rbt_ 前缀与系统通知账号），按最后消息时间倒序
  final List<ImConversation> conversations;

  /// 机器人（rbt_xinyu001）会话未读数（驱动底部小鹿按钮角标）
  final int robotUnreadCount;

  /// 系统通知是否有未读（红点，由 sysNotification 会话未读数决定）
  bool get hasSystemNotificationUnread =>
      (systemNotification?.unreadCount ?? 0) > 0;

  /// 对话列表未读总数 = 普通对话 unreadCount 之和（不含机器人与系统通知）。
  /// iOS 参照：XYMessageViewModel.conversationUnreadTotal →
  /// XYUnreadMessageTotalChanged 通知驱动消息 Tab 角标。
  /// 含咨询师端对伪装本端 *_middle 卡的本地未读补偿。
  int get conversationUnreadTotal =>
      conversations.fold(0, (sum, c) => sum + c.unreadCount);
}

/// 消息页 ViewModel：拉会话 → 分离 sysNotification → 过滤 rbt_ → 普通对话列表。
/// iOS 参照：XYMessageViewModel.fetch。
final messageViewModelProvider = Provider<MessageViewState>((ref) {
  final summaries =
      ref.watch(conversationListProvider).valueOrNull ?? const <ImConversation>[];
  final middleExtra = ref.watch(middleCardUnreadProvider);

  ImConversation? systemNotification;
  int robotUnread = 0;
  final humans = <ImConversation>[];
  for (final s in summaries) {
    // 提取系统通知账号会话，驱动顶部「系统通知」入口
    if (s.userId == ImConfig.systemNotificationUserId) {
      systemNotification = s;
      continue;
    }
    // 过滤 AI 机器人会话（accid `rbt_xinyu001` / 前缀 `rbt_`）：
    // 机器人有专属入口（底部小鹿 Tab），不进普通对话列表、不计未读。
    // 云信 accid 强制小写，会话对端解析出的 userId 即 `rbt_xinyu001`，前缀匹配即可命中。
    if (s.userId == ImConfig.robotUserId ||
        s.userId.startsWith(ImConfig.robotPrefix)) {
      // 机器人未读：驱动底部小鹿按钮角标（不计入消息 Tab 总数）
      robotUnread = s.unreadCount;
      continue;
    }
    final extra = middleExtra.countFor(s.userId);
    humans.add(extra > 0 ? s.copyWith(unreadCount: s.unreadCount + extra) : s);
  }
  // 排序：按最后消息时间倒序（Android 参照：MessageFragment.handleConversations；
  // iOS 依赖 SDK 返回序，同样是 timestamp 倒序，此处显式排序保证确定性）
  humans.sort((a, b) {
    final ta = a.timestamp?.millisecondsSinceEpoch ?? 0;
    final tb = b.timestamp?.millisecondsSinceEpoch ?? 0;
    return tb.compareTo(ta);
  });
  return MessageViewState(
    systemNotification: systemNotification,
    conversations: humans,
    robotUnreadCount: robotUnread,
  );
});

/// 消息 Tab 未读角标 = 普通对话未读 + 系统通知未读（不含机器人；机器人走底部小鹿按钮）。
/// iOS 参照：XYUnreadMessageTotalChanged 通知语义。
final messageUnreadTotalProvider = Provider<int>((ref) {
  final s = ref.watch(messageViewModelProvider);
  return s.conversationUnreadTotal + (s.systemNotification?.unreadCount ?? 0);
});

/// 机器人（小鹿）未读角标（仅用户端底部小鹿按钮消费；咨询师端无机器人会话，恒为 0）。
final robotUnreadCountProvider = Provider<int>(
  (ref) => ref.watch(messageViewModelProvider).robotUnreadCount,
);

/// App 桌面图标角标总值 = 消息 Tab（普通对话 + 系统通知） + 小鹿（机器人）。
/// 与 App 内展示同源：用户端为三者合计；咨询师端无机器人/系统，即普通对话未读。
/// 由 AppBadgeService 写入 iOS 图标角标，覆盖云信 APNS aps.badge，使图标与 App 内一致。
final appIconBadgeProvider = Provider<int>(
  (ref) =>
      ref.watch(messageUnreadTotalProvider) + ref.watch(robotUnreadCountProvider),
);
