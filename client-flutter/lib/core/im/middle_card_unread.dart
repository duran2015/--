import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/chat/cards/chat_card_logic.dart';
import '../../utils/ly_cache.dart';
import '../auth/auth_controller.dart';
import '../auth/auth_state.dart';
import '../router/route_guards.dart';
import 'im_models.dart';
import 'im_service.dart';
import 'im_session_controller.dart';

/// 当前打开的 1v1 聊天对端（null=不在聊天页）。
/// 在聊时收到伪装本端的 *_middle 卡不计入本地未读（进页即已读）。
final activeChatPeerIdProvider = StateProvider<String?>((ref) => null);

/// 咨询师端对「后台伪装本端发出的 *_middle 卡」的本地未读补偿。
///
/// SDK 对 isSelf 消息不计 unreadCount；这类居中卡对咨询师无感知，
/// 不在聊天页时应计入消息 Tab / 会话行未读。
class MiddleCardUnreadState {
  const MiddleCardUnreadState({
    this.counts = const {},
    this.clearedAtMs = const {},
  });

  /// peerUserId → 本地补偿未读数
  final Map<String, int> counts;

  /// peerUserId → 最近一次进聊天清未读的时间戳（ms）
  final Map<String, int> clearedAtMs;

  int countFor(String peerUserId) => counts[peerUserId] ?? 0;

  MiddleCardUnreadState copyWith({
    Map<String, int>? counts,
    Map<String, int>? clearedAtMs,
  }) {
    return MiddleCardUnreadState(
      counts: counts ?? this.counts,
      clearedAtMs: clearedAtMs ?? this.clearedAtMs,
    );
  }
}

/// 一条消息是否为「本端发出的 *_middle 居中卡」（需本地未读补偿）。
bool isSelfMiddleCardMessage(ImMessage msg) {
  if (!msg.isSelf || msg.kind != ImMessageKind.custom) return false;
  final businessId = ImCustomCard.tryParse(msg.customJson)?.businessID;
  return isMiddleCardBusinessId(businessId);
}

class MiddleCardUnreadNotifier extends Notifier<MiddleCardUnreadState> {
  static const _prefsKeyPrefix = 'im_middle_card_unread_v1_';

  String? _storageKey;
  bool _loaded = false;

  @override
  MiddleCardUnreadState build() {
    ref.listen(authControllerProvider, (prev, next) {
      final imId = next?.imUserId;
      if (imId == null || imId.isEmpty) {
        _storageKey = null;
        _loaded = false;
        state = const MiddleCardUnreadState();
        return;
      }
      unawaited(_loadForAccount(imId));
    });
    final imId = ref.read(authControllerProvider)?.imUserId;
    if (imId != null && imId.isNotEmpty) {
      unawaited(_loadForAccount(imId));
    }
    return const MiddleCardUnreadState();
  }

  Future<void> _loadForAccount(String imUserId) async {
    final key = '$_prefsKeyPrefix$imUserId';
    if (_storageKey == key && _loaded) return;
    _storageKey = key;
    try {
      final raw = await LyCache.get<String>(key: key);
      if (raw == null || raw.isEmpty) {
        _loaded = true;
        state = const MiddleCardUnreadState();
        return;
      }
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final counts = <String, int>{
        for (final e in (map['counts'] as Map<String, dynamic>? ?? {}).entries)
          e.key: (e.value as num).toInt(),
      };
      final cleared = <String, int>{
        for (final e
            in (map['clearedAtMs'] as Map<String, dynamic>? ?? {}).entries)
          e.key: (e.value as num).toInt(),
      };
      _loaded = true;
      state = MiddleCardUnreadState(counts: counts, clearedAtMs: cleared);
    } catch (e) {
      debugPrint('🟠 [MiddleCardUnread] 加载失败：$e');
      _loaded = true;
      state = const MiddleCardUnreadState();
    }
  }

  Future<void> _persist() async {
    final key = _storageKey;
    if (key == null) return;
    try {
      await LyCache.put(
        key: key,
        value: jsonEncode({
          'counts': state.counts,
          'clearedAtMs': state.clearedAtMs,
        }),
      );
    } catch (e) {
      debugPrint('🟠 [MiddleCardUnread] 持久化失败：$e');
    }
  }

  /// 收到本端 *_middle 卡且当前不在该会话聊天页 → +1。
  void onSelfMiddleCard(ImMessage msg) {
    if (!isSelfMiddleCardMessage(msg)) return;
    final peer = msg.peerId?.trim();
    if (peer == null || peer.isEmpty) return;
    if (ref.read(activeChatPeerIdProvider) == peer) return;
    final msgMs = msg.timestamp?.millisecondsSinceEpoch ?? 0;
    final cleared = state.clearedAtMs[peer] ?? 0;
    if (msgMs > 0 && msgMs <= cleared) return;
    final next = (state.counts[peer] ?? 0) + 1;
    state = state.copyWith(counts: {...state.counts, peer: next});
    unawaited(_persist());
  }

  /// 会话列表兜底：末条为本端 *_middle 且晚于上次清未读、本地计数为 0 → 记 1。
  void reconcileFromConversations(List<ImConversation> conversations) {
    var changed = false;
    final counts = Map<String, int>.from(state.counts);
    for (final c in conversations) {
      if (!c.lastMessageIsSelfMiddle) continue;
      final cleared = state.clearedAtMs[c.userId] ?? 0;
      final msgMs = c.timestamp?.millisecondsSinceEpoch ?? 0;
      if (msgMs > 0 && msgMs <= cleared) continue;
      if (ref.read(activeChatPeerIdProvider) == c.userId) continue;
      if ((counts[c.userId] ?? 0) > 0) continue;
      counts[c.userId] = 1;
      changed = true;
    }
    if (!changed) return;
    state = state.copyWith(counts: counts);
    unawaited(_persist());
  }

  /// 进入聊天 / 标记已读：清掉该对端的本地补偿未读。
  void clearPeer(String peerUserId, {DateTime? at}) {
    final peer = peerUserId.trim();
    if (peer.isEmpty) return;
    final ms = (at ?? DateTime.now()).millisecondsSinceEpoch;
    final counts = Map<String, int>.from(state.counts)..remove(peer);
    final cleared = Map<String, int>.from(state.clearedAtMs);
    final prev = cleared[peer] ?? 0;
    cleared[peer] = ms > prev ? ms : prev;
    if (state.counts[peer] == null && cleared[peer] == prev) return;
    state = state.copyWith(counts: counts, clearedAtMs: cleared);
    unawaited(_persist());
  }
}

final middleCardUnreadProvider =
    NotifierProvider<MiddleCardUnreadNotifier, MiddleCardUnreadState>(
  MiddleCardUnreadNotifier.new,
);

/// 接线：监听新消息 + 会话流，仅咨询师身份补偿 *_middle 本地未读。
/// 在 [XinyuApp] watch 一次即可。
final middleCardUnreadBinderProvider = Provider<void>((ref) {
  ref.watch(middleCardUnreadProvider);
  // 始终订阅；回调内再判断身份，避免切到咨询师后未重新 bind。
  final im = ref.watch(imServiceProvider);

  ref.listen<bool>(imSessionControllerProvider, (prev, loggedIn) {
    if (!loggedIn) return;
    if (ref.read(currentIdentityProvider) != RouteGuards.identityConsultant) {
      return;
    }
    unawaited(() async {
      final list = await im.fetchConversations();
      ref
          .read(middleCardUnreadProvider.notifier)
          .reconcileFromConversations(list);
    }());
  });

  final convSub = im.conversationStream.listen((list) {
    if (ref.read(currentIdentityProvider) != RouteGuards.identityConsultant) {
      return;
    }
    ref
        .read(middleCardUnreadProvider.notifier)
        .reconcileFromConversations(list);
  });
  final msgSub = im.newMessageStream.listen((msg) {
    if (ref.read(currentIdentityProvider) != RouteGuards.identityConsultant) {
      return;
    }
    ref.read(middleCardUnreadProvider.notifier).onSelfMiddleCard(msg);
  });
  ref.onDispose(() {
    convSub.cancel();
    msgSub.cancel();
  });
});
