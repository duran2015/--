import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/auth/auth_state.dart';
import '../../../core/im/im_config.dart';
import '../../../core/im/im_models.dart';
import '../../../core/im/im_service.dart';
import '../../../core/im/middle_card_unread.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/utils/message_time_formatter.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/person_avatar.dart';
import '../../../utils/load_image.dart';
import '../cards/chat_card_logic.dart';
import '../cards/chat_card_style.dart';
import '../cards/custom_card_view.dart';
import 'chat_input_bar.dart';
import 'chat_message_bubble.dart';

/// 1v1 C2C 会话视图（消息区 + 快捷回复 + 输入栏），供 /chat 页与
/// 小鹿 AI 页（/ai）复用。
///
/// iOS 参照：XYChatModule XYChatContainerViewController（聊天容器）+
/// XYAIModule XYAIConsultViewController（AI 页即机器人 IM 会话）。
/// Android 参照：RobotChatFragment（同一页复用机器人与 C2C：
/// 机器人会话 position 0 固定本地 GREETING 欢迎条（非 IM 消息）+
/// 快捷回复两条（与 iOS 一致）+ 历史 20 条/页下拉加载）。
class ChatConversationView extends ConsumerStatefulWidget {
  const ChatConversationView({
    super.key,
    required this.peerUserId,
    required this.peerName,
    this.peerAvatar,
    this.inputEnabled = true,
  });

  /// 对方 IM userId（机器人会话 = @RBT#xinyu001）
  final String peerUserId;

  /// 对方昵称（头像旁无昵称展示，仅语义保留）
  final String peerName;

  /// 对方头像 URL（可选）
  final String? peerAvatar;

  /// 输入是否可用。AI 页未同意「AI 服务数据说明」时传 false，禁用快捷回复
  /// 与输入栏（对齐 iOS isUserInteractionEnabled=false）。默认 true。
  final bool inputEnabled;

  /// 历史分页大小（Android getC2CHistoryMessageList count=20）
  static const int pageSize = 20;

  /// 机器人会话本地欢迎条文案（GREETING，非 IM 消息。
  /// Android 参照：RobotChatFragment MsgType.GREETING 本地构造）
  static const String greetingText =
      '嗨，我是小鹿🦌 很高兴见到你～不管是想倾诉、想放松，还是随便聊聊，我都在这里陪着你。';

  /// 快捷回复两条（iOS 基准 ios/04_ai.png：「敲木鱼静静心」「带我深呼吸」，
  /// 图标与文案均以 iOS 为准）。
  /// 注意：展示文案 ≠ 发送文本（iOS XYAIConsultViewController / Android
  /// RobotChatFragment 一致）——「敲木鱼静静心」实际发送「我想敲木鱼」，
  /// 机器人按发送文本匹配技能，直接发展示文案会导致机器人回复错乱。
  /// 元素为 (展示文案, 发送文本, 图标)。
  static const List<(String, String, String)> quickReplies = [
    ('敲木鱼静静心', '我想敲木鱼', AppAssets.quickWoodfish),
    ('带我深呼吸', '带我深呼吸', AppAssets.quickBreath),
  ];

  @override
  ConsumerState<ChatConversationView> createState() =>
      ChatConversationViewState();
}

class ChatConversationViewState extends ConsumerState<ChatConversationView> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ChatInputBarState> _inputBarKey =
      GlobalKey<ChatInputBarState>();

  /// 消息列表（旧→新）
  List<ImMessage> _messages = const [];
  bool _loading = true;
  bool _hasMore = false;
  bool _loadingMore = false;
  StreamSubscription<ImMessage>? _newMessageSub;

  /// 消息区最近一帧高度；变矮时（键盘/面板弹起）把记录顶到输入栏上方。
  double? _lastMessageViewportHeight;

  /// 本端是否已拉黑对方（屏蔽输入栏）。
  /// iOS 参照：XYChatContainerViewController.isBlocked。
  bool _isBlocked = false;

  ImService get _im => ref.read(imServiceProvider);

  bool get _isRobot => widget.peerUserId.startsWith(ImConfig.robotPrefix);

  @override
  void initState() {
    super.initState();
    // 新消息监听追加（Android 参照：onRecvNewMessage → msgList.add）
    _newMessageSub = _im.newMessageStream.listen(_onNewMessage);
    _loadInitial();
    unawaited(_checkBlockedState());
    // Riverpod 禁止在 initState 改 provider：进页清未读 / 登记 active peer 延后到帧末。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(activeChatPeerIdProvider.notifier).state = widget.peerUserId;
      unawaited(_markPeerRead());
    });
  }

  /// SDK 已读 + 清掉 *_middle 本地未读补偿。
  Future<void> _markPeerRead() async {
    ref.read(middleCardUnreadProvider.notifier).clearPeer(widget.peerUserId);
    await _im.markConversationRead('c2c_${widget.peerUserId}');
  }

  /// 进入会话查黑名单：已拉黑则覆盖输入栏禁止发送。
  /// iOS 参照：checkAndApplyBlockedState（IM 黑名单只拦接收，发送侧由本页兜底）。
  Future<void> _checkBlockedState() async {
    if (_isRobot) return;
    try {
      final blocked = await _im.isUserBlocked(widget.peerUserId);
      if (!mounted || !blocked) return;
      _inputBarKey.currentState?.dismissActiveInputState();
      setState(() => _isBlocked = true);
    } catch (_) {
      // 查询失败按未拉黑，不阻断进入会话（对齐 iOS isUserBlocked fail → false）
    }
  }

  /// 父页面完成拉黑后立即切换禁发态，无需重新进入会话。
  void applyBlockedState() {
    if (_isBlocked) return;
    _inputBarKey.currentState?.dismissActiveInputState();
    setState(() => _isBlocked = true);
  }

  @override
  void dispose() {
    _newMessageSub?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void deactivate() {
    // deactivate 可能落在父级 build 期间；用 container + Future 延后清 active peer。
    final peer = widget.peerUserId;
    final container = ProviderScope.containerOf(context, listen: false);
    Future(() {
      if (container.read(activeChatPeerIdProvider) == peer) {
        container.read(activeChatPeerIdProvider.notifier).state = null;
      }
    });
    super.deactivate();
  }

  Future<void> _loadInitial() async {
    try {
      final list = await _im.historyMessages(
        userId: widget.peerUserId,
        count: ChatConversationView.pageSize,
      );
      if (!mounted) return;
      setState(() {
        _messages = list;
        _hasMore = list.length >= ChatConversationView.pageSize;
        _loading = false;
      });
      // 进入页：无动画贴底，保证最新消息在视口底部（非 animateTo）
      _scrollToBottom(jump: true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  /// 下拉加载更早（正向列表滚到顶部触发；前置插入后校正 offset 防跳动）
  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _messages.isEmpty) return;
    _loadingMore = true;
    final oldExtent = _scrollController.hasClients
        ? _scrollController.position.maxScrollExtent
        : 0.0;
    final oldOffset =
        _scrollController.hasClients ? _scrollController.offset : 0.0;
    try {
      final earlier = await _im.historyMessages(
        userId: widget.peerUserId,
        count: ChatConversationView.pageSize,
        lastMsgId: _messages.first.msgId,
      );
      if (!mounted) return;
      setState(() {
        _messages = [...earlier, ..._messages];
        _hasMore = earlier.length >= ChatConversationView.pageSize;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollController.hasClients) return;
        final newExtent = _scrollController.position.maxScrollExtent;
        _scrollController.jumpTo(oldOffset + (newExtent - oldExtent));
      });
    } catch (_) {
      // 分页失败保持现状
    } finally {
      _loadingMore = false;
    }
  }

  void _onNewMessage(ImMessage msg) {
    // 只追加本会话消息（peerId 为 C2C 对端；mock/NIM 均已填充）
    final peer = msg.peerId ?? msg.senderId;
    if (peer != widget.peerUserId) return;

    // 同 msgId：失败重发成功时 SDK 仍推同一条，原地更新（勿因「已存在」丢弃）
    final sameIdIdx = _messages.indexWhere((m) => m.msgId == msg.msgId);
    if (sameIdIdx >= 0) {
      setState(() {
        final next = [..._messages];
        final prev = next[sameIdIdx];
        next[sameIdIdx] = msg.copyWith(
          // 本端已有本地原图时保留，避免被 SDK 缩略路径替换导致气泡比例变化
          imagePath: (prev.isSelf &&
                  prev.imagePath != null &&
                  prev.imagePath!.trim().isNotEmpty)
              ? prev.imagePath
              : (msg.imagePath ?? prev.imagePath),
          imageUrl: msg.imageUrl ?? prev.imageUrl,
          imageUuid: msg.imageUuid ?? prev.imageUuid,
          sendStatus: ImMessageSendStatus.sent,
        );
        _messages = next;
      });
      unawaited(_markPeerRead());
      _scrollToBottom();
      return;
    }

    // 本端图片：若已有乐观 sending 条目，替换之，避免成功回推再插一条
    if (msg.isSelf && msg.kind == ImMessageKind.image) {
      final pendingIdx = _messages.lastIndexWhere(
        (m) =>
            m.isSelf &&
            m.kind == ImMessageKind.image &&
            m.sendStatus == ImMessageSendStatus.sending &&
            (msg.imagePath == null ||
                msg.imagePath!.isEmpty ||
                m.imagePath == msg.imagePath),
      );
      if (pendingIdx >= 0) {
        final localPath = _messages[pendingIdx].imagePath;
        setState(() {
          final next = [..._messages];
          next[pendingIdx] = msg.copyWith(
            // 本端发送：继续用本地原图路径展示，避免切到 SDK 缩略缓存后比例跳变
            imagePath: localPath ?? msg.imagePath,
            sendStatus: ImMessageSendStatus.sent,
          );
          _messages = next;
        });
        unawaited(_markPeerRead());
        _scrollToBottom();
        return;
      }
    }

    setState(() => _messages = [..._messages, msg]);
    // 收到新消息即已读（当前正在会话内）
    unawaited(_markPeerRead());
    _scrollToBottom();
  }

  /// 滚到最新（正向列表 = maxScrollExtent；不足一屏时为 0，保持置顶）。
  /// [jump]：进入页 / 键盘弹起用无动画跳转；新消息默认短动画。
  void _scrollToBottom({bool jump = false}) {
    void pin() {
      if (!_scrollController.hasClients) return;
      final position = _scrollController.position;
      final target = position.maxScrollExtent;
      if ((position.pixels - target).abs() < 1.0) return;
      if (jump) {
        _scrollController.jumpTo(target);
      } else {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      pin();
      // 进入页再补一帧：首帧 extent 可能未算全（气泡/图片），避免停在旧消息顶部
      if (jump) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          pin();
        });
      }
    });
  }

  /// 消息区变矮（键盘 / 表情 /「+」面板）时贴底，保证最新消息在输入框上方。
  void _onMessageViewportHeight(double height) {
    final prev = _lastMessageViewportHeight;
    _lastMessageViewportHeight = height;
    if (prev == null) return;
    // 忽略亚像素抖动；仅在明显变矮时贴底
    if (height < prev - 1.0) {
      _scrollToBottom(jump: true);
    }
  }

  // ---------------- 发送 ----------------

  Future<void> _sendText(String text) async {
    if (_isBlocked) return;
    try {
      await _im.sendTextMessage(userId: widget.peerUserId, text: text);
      // 回显经 newMessageStream 统一追加（mock/NIM 发送成功均推流）
      _scrollToBottom();
    } catch (_) {
      if (mounted) AppToast.show(context, '发送失败，请稍后重试');
    }
  }

  Future<void> _sendImage(String path, {String? existingMsgId}) async {
    if (_isBlocked) return;
    final localId =
        existingMsgId ?? 'local_img_${DateTime.now().microsecondsSinceEpoch}';
    if (existingMsgId != null) {
      // 重发：同一条改回 sending
      setState(() {
        _messages = [
          for (final m in _messages)
            if (m.msgId == localId)
              m.copyWith(sendStatus: ImMessageSendStatus.sending)
            else
              m,
        ];
      });
    } else {
      // 乐观上屏：先插入本地图 + sending，再等 IM 上传
      final pending = ImMessage(
        msgId: localId,
        senderId: _im.currentUserId,
        kind: ImMessageKind.image,
        imagePath: path,
        timestamp: DateTime.now(),
        isSelf: true,
        peerId: widget.peerUserId,
        sendStatus: ImMessageSendStatus.sending,
      );
      setState(() => _messages = [..._messages, pending]);
      _scrollToBottom(jump: true);
    }
    try {
      final sent = await _im.sendImageMessage(
        userId: widget.peerUserId,
        imagePath: path,
      );
      if (!mounted) return;
      setState(() {
        final hasLocal = _messages.any((m) => m.msgId == localId);
        if (!hasLocal) {
          // 已被 newMessageStream 按路径替换
          return;
        }
        // 若流已先插入正式消息，去掉乐观条，避免双条
        if (_messages.any((m) => m.msgId == sent.msgId && m.msgId != localId)) {
          _messages = [
            for (final m in _messages)
              if (m.msgId != localId) m,
          ];
          return;
        }
        _messages = [
          for (final m in _messages)
            if (m.msgId == localId)
              sent.copyWith(
                // 继续展示拍摄/相册原文件，尺寸与发送中一致
                imagePath: path,
                sendStatus: ImMessageSendStatus.sent,
              )
            else
              m,
        ];
      });
    } on ImException catch (e) {
      if (!mounted) return;
      // SDK 失败落库后带回真实 msgId，后续重发走 reSend 合并为一条
      final failed = e.failedMessage;
      setState(() {
        if (failed != null && failed.msgId.isNotEmpty) {
          _messages = [
            for (final m in _messages)
              if (m.msgId == localId)
                failed.copyWith(
                  imagePath: failed.imagePath ?? path,
                  sendStatus: ImMessageSendStatus.failed,
                )
              else
                m,
          ];
        } else {
          _messages = [
            for (final m in _messages)
              if (m.msgId == localId)
                m.copyWith(sendStatus: ImMessageSendStatus.failed)
              else
                m,
          ];
        }
      });
      AppToast.show(context, '图片发送失败');
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _messages = [
          for (final m in _messages)
            if (m.msgId == localId)
              m.copyWith(sendStatus: ImMessageSendStatus.failed)
            else
              m,
        ];
      });
      AppToast.show(context, '图片发送失败');
    }
  }

  /// 失败图片点击感叹号重发。
  /// SDK 已落库（非 local_img_*）→ 同 msgId reSend，合并为一条成功消息；
  /// 仅乐观本地条 → 再走 create+send。
  Future<void> _resendImage(ImMessage message) async {
    if (_isBlocked) return;
    if (message.sendStatus != ImMessageSendStatus.failed) return;
    final path = message.imagePath;
    final isLocalOptimistic = message.msgId.startsWith('local_img_');

    if (!isLocalOptimistic) {
      setState(() {
        _messages = [
          for (final m in _messages)
            if (m.msgId == message.msgId)
              m.copyWith(sendStatus: ImMessageSendStatus.sending)
            else
              m,
        ];
      });
      try {
        final sent = await _im.reSendMessage(msgId: message.msgId);
        if (!mounted) return;
        setState(() {
          _messages = [
            for (final m in _messages)
              if (m.msgId == message.msgId)
                sent.copyWith(
                  imagePath: path ?? sent.imagePath,
                  sendStatus: ImMessageSendStatus.sent,
                )
              else
                m,
          ];
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _messages = [
            for (final m in _messages)
              if (m.msgId == message.msgId)
                m.copyWith(sendStatus: ImMessageSendStatus.failed)
              else
                m,
          ];
        });
        AppToast.show(context, '图片发送失败');
      }
      return;
    }

    if (path == null || path.isEmpty) {
      AppToast.show(context, '图片发送失败');
      return;
    }
    await _sendImage(path, existingMsgId: message.msgId);
  }

  Future<void> _sendSound(String path, int duration) async {
    if (_isBlocked) return;
    try {
      await _im.sendSoundMessage(
        userId: widget.peerUserId,
        soundPath: path,
        duration: duration,
      );
      _scrollToBottom();
    } catch (_) {
      if (mounted) AppToast.show(context, '语音发送失败');
    }
  }

  Future<void> _sendFile(String path, String name, int size) async {
    if (_isBlocked) return;
    try {
      await _im.sendFileMessage(
        userId: widget.peerUserId,
        filePath: path,
        fileName: name,
        fileSize: size,
      );
      if (!mounted) return;
      _scrollToBottom();
    } catch (_) {
      if (mounted) AppToast.show(context, '文件发送失败，请稍后重试');
    }
  }

  Future<void> _sendAssistantCard(Map<String, Object> payload) async {
    if (_isBlocked) return;
    try {
      await _im.sendCustomMessage(
        userId: widget.peerUserId,
        customJson: jsonEncode(payload),
      );
      _scrollToBottom();
    } catch (_) {
      if (mounted) AppToast.show(context, '发送失败，请稍后重试');
    }
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    final identity = ref.watch(currentIdentityProvider);
    return Column(
      children: [
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            // 点击聊天区空白收起键盘与面板
            // （iOS 参照：XYChatContainerViewController handleChatAreaTap）
            onTap: () => _inputBarKey.currentState?.dismissActiveInputState(),
            child: _buildMessageList(identity),
          ),
        ),
        if (_isRobot && !_isBlocked)
          // 未同意 AI 服务数据说明时禁用快捷回复（对齐 iOS
          // isUserInteractionEnabled=false；弹窗遮罩阻断时此态不可见）
          IgnorePointer(
            ignoring: !widget.inputEnabled,
            child: _buildQuickReplyBar(),
          ),
        // 拉黑态：提示条盖住输入栏（iOS blockedBannerView.edges = inputBar）
        if (_isBlocked)
          const _BlockedInputBanner()
        else
          IgnorePointer(
            ignoring: !widget.inputEnabled,
            child: ChatInputBar(
              key: _inputBarKey,
              // 咨询师工具面板仅咨询师端可见
              // （iOS 参照：XYChatInputBar(counselorToolsEnabled:)）
              counselorToolsEnabled: identity == 'consultant' && !_isRobot,
              onComposerHeightChanged: () => _scrollToBottom(jump: true),
              onSendText: (text) => unawaited(_sendText(text)),
              onSendImage: (path) => unawaited(_sendImage(path)),
              onSendSound: (path, duration) =>
                  unawaited(_sendSound(path, duration)),
              onSendFile: (path, name, size) =>
                  unawaited(_sendFile(path, name, size)),
              onSendAssistantCard: (payload) =>
                  unawaited(_sendAssistantCard(payload)),
            ),
          ),
      ],
    );
  }

  Widget _buildMessageList(String? identity) {
    if (_loading) {
      return LayoutBuilder(
        builder: (context, constraints) {
          _onMessageViewportHeight(constraints.maxHeight);
          return const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
      );
    }
    // 正向列表（旧→新）：不足一屏置顶；超出后滚到底看最新。
    // 机器人会话首位追加本地欢迎消息；“内容由 AI 生成”已移至紧凑头部，
    // 不再占用消息列表底部空间。
    final greetingCount = _isRobot ? 1 : 0;
    final securityReminderCount = _isRobot ? 0 : 1;
    return LayoutBuilder(
      builder: (context, constraints) {
        _onMessageViewportHeight(constraints.maxHeight);
        return NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollUpdateNotification &&
                notification.metrics.pixels <= 60) {
              unawaited(_loadMore());
            }
            return false;
          },
          child: ChatPeerScope(
            peerImUserId: widget.peerUserId,
            peerName: widget.peerName,
            peerAvatar: widget.peerAvatar,
            child: ListView.builder(
              controller: _scrollController,
              // 不足一屏也可拖动（沿用平台默认回弹/阻尼）
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              itemCount:
                  _messages.length + greetingCount + securityReminderCount,
              itemBuilder: (context, index) {
                if (_isRobot && index == 0) {
                  return _buildGreeting();
                }
                if (!_isRobot && index == 0) {
                  return _buildSecurityReminder();
                }
                final messageIndex =
                    index - greetingCount - securityReminderCount;
                final message = _messages[messageIndex];
                final row = _buildMessageRow(message, identity);
                // 时间分隔：首条 / 跨天 / 与上一条间隔≥5min 时，消息上方居中显示时间
                // （iOS TUIKit showMessageTime 规范；Flutter 自建 UI 此前缺失，补齐）。
                if (!_isStatusNoticeMessage(message) &&
                    _shouldShowTimeSeparator(messageIndex)) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [_timeSeparator(message.timestamp), row],
                  );
                }
                return row;
              },
            ),
          ),
        );
      },
    );
  }

  bool _isStatusNoticeMessage(ImMessage message) {
    if (message.kind != ImMessageKind.custom) return false;
    final card = ImCustomCard.tryParse(message.customJson);
    return card?.businessID == 'begin_chat_middle' &&
        (card?.buttonText ?? '').isEmpty;
  }

  /// 真人咨询聊天室固定安全提醒：最高视觉层级，但不承载业务操作。
  Widget _buildSecurityReminder() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4D6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8D39B)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, size: 18, color: Color(0xFF765B00)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '安全提醒：请勿私下转账，或发送身份证、银行卡等敏感信息。',
              textAlign: TextAlign.left,
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: Color(0xFF5D4500),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 机器人会话本地欢迎条（GREETING，非 IM 消息。
  /// Android 参照：RobotChatFragment position 0）
  Widget _buildGreeting() {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: AppColors.chatBubbleOther,
                borderRadius: ChatMessageBubble.bubbleRadius(false),
              ),
              child: Text(
                ChatConversationView.greetingText,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 该消息上方是否需要时间分隔：首条、跨天、或与上一条间隔≥5min
  /// （对齐 iOS TUIKit showMessageTime 规范）。
  bool _shouldShowTimeSeparator(int messageIndex) {
    if (messageIndex < 0 || messageIndex >= _messages.length) return false;
    final ts = _messages[messageIndex].timestamp;
    if (ts == null) return false;
    if (messageIndex == 0) return true;
    final prev = _messages[messageIndex - 1].timestamp;
    if (prev == null) return true;
    if (prev.year != ts.year || prev.month != ts.month || prev.day != ts.day) {
      return true; // 跨天
    }
    return ts.difference(prev).inMinutes.abs() >= 5;
  }

  /// 消息间居中时间分隔条（11pt #999；复用 [MessageTimeFormatter]：
  /// 今天 HH:mm、昨天「昨天」、本年 MM-dd、跨年 yyyy-MM-dd）。
  Widget _timeSeparator(DateTime? ts) {
    final label = MessageTimeFormatter.chatSeparator(ts);
    if (label.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
        ),
      ),
    );
  }

  /// 消息行：居中卡（*_middle）无头像；其余按方向带头像。
  /// Android 参照：MsgAdapter（LEFT/RIGHT/MIDDLE/LEFT_CARD 分发）。
  Widget _buildMessageRow(ImMessage message, String? identity) {
    if (message.kind == ImMessageKind.custom) {
      final card = ImCustomCard.tryParse(message.customJson);
      if (card != null && !isCardVisibleForIdentity(card, identity)) {
        return const SizedBox.shrink();
      }
      if (card != null &&
          card.businessID == 'begin_chat_middle' &&
          (card.buttonText ?? '').isEmpty) {
        return _statusNotice(card, message.timestamp);
      }
      if (card != null && CustomCardView.isCentered(card)) {
        return Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 12),
          child: Center(
            child: CustomCardView(
              card: card,
              identity: identity,
              isSelf: message.isSelf,
            ),
          ),
        );
      }
      if (card != null) {
        // 方向性白卡（summary_advise / question_assistant）：靠发送方
        return _directionalRow(
          message: message,
          child: CustomCardView(
            card: card,
            identity: identity,
            isSelf: message.isSelf,
          ),
        );
      }
      // 解析失败兜底：按文本展示
    }
    // 双端统一采用“我方/对方”视角：我方永远右侧绿色无头像，
    // 对方永远左侧白色带头像；用户端与咨询师端自然镜像。
    final isOutgoingMessage = message.isSelf;
    return _directionalRow(
      message: message,
      isOutgoingMessage: isOutgoingMessage,
      child: ChatMessageBubble(
        message: message,
        isCounselorMessage: isOutgoingMessage,
        imageGallery: _imageGallery,
        onResend: message.kind == ImMessageKind.image &&
                message.sendStatus == ImMessageSendStatus.failed
            ? () => unawaited(_resendImage(message))
            : null,
      ),
    );
  }

  /// 会话内可预览图片（时间序，供全屏左右滑）。
  List<ImMessage> get _imageGallery {
    return [
      for (final m in _messages)
        if (m.kind == ImMessageKind.image &&
            ((m.imagePath != null && m.imagePath!.trim().isNotEmpty) ||
                (m.imageUrl != null && m.imageUrl!.trim().isNotEmpty)))
          m,
    ];
  }

  /// 方向性消息行（头像 + 内容，按 isSelf 左右排布）
  Widget _directionalRow({
    required ImMessage message,
    required Widget child,
    bool? isOutgoingMessage,
  }) {
    final outgoing = isOutgoingMessage ?? message.isSelf;
    // AI 会话已在紧凑头部明确展示小鹿身份，消息流不重复显示头像。
    final avatar = outgoing || _isRobot
        ? null
        : _avatar(
            isSelf: false,
            isRobot: _isRobot,
            senderId: message.senderId,
          );
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Row(
        mainAxisAlignment:
            outgoing ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        textDirection: outgoing ? TextDirection.rtl : TextDirection.ltr,
        children: [
          if (avatar != null) ...[avatar, const SizedBox(width: 8)],
          Flexible(
            child: Align(
              alignment:
                  outgoing ? Alignment.centerRight : Alignment.centerLeft,
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusNotice(ImCustomCard card, DateTime? timestamp) {
    final time = MessageTimeFormatter.chatSeparator(timestamp);
    final text = [
      if (time.isNotEmpty) time,
      if ((card.title ?? '').isNotEmpty) card.title!,
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF777B7A),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: Colors.white),
          ),
        ),
      ),
    );
  }

  /// 头像（40 圆形）。
  /// 点咨询师头像 → /consultant/detail（按 sender imUserId。
  /// iOS 参照：XYCounselorAvatarTapListener.onUserIconClicked：
  /// 仅用户端 + 点击对方头像 + 非机器人会话生效）。
  Widget _avatar({
    required bool isSelf,
    required bool isRobot,
    String? senderId,
  }) {
    Widget image;
    if (isRobot) {
      image = const LoadImage(
        AppAssets.aiDeerGreeting,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
      );
    } else if (isSelf) {
      final avatarUrl = ref.watch(authControllerProvider)?.avatar;
      image = (avatarUrl != null && avatarUrl.isNotEmpty)
          ? LoadImage(
              avatarUrl,
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              errorWidget: _defaultAvatar(),
            )
          : _defaultAvatar();
    } else {
      final url = widget.peerAvatar;
      image = PersonAvatar(
        name: widget.peerName,
        seed: widget.peerUserId,
        imageUrl: url,
        size: 40,
      );
    }
    final avatar = isRobot || isSelf ? ClipOval(child: image) : image;
    // 点击对方头像跳咨询师详情（仅用户端、非机器人会话）
    final identity = ref.watch(currentIdentityProvider);
    if (!isSelf && !isRobot && identity == 'user') {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          final id = senderId ?? widget.peerUserId;
          // iOS 按 imUserId 经服务查咨询师详情；Flutter 详情页参数为
          // consultantId（int），imUserId 非数字时由详情页兜底
          // （限制记录：mock 会话 imUserId 为字符串，真机为数值映射）。
          context.push(
            '${RoutePaths.consultantDetail}?consultantId=${Uri.encodeComponent(id)}',
          );
        },
        child: avatar,
      );
    }
    return avatar;
  }

  Widget _defaultAvatar() {
    return const LoadImage(
      AppAssets.icDefaultAvatar,
      width: 40,
      height: 40,
      fit: BoxFit.cover,
    );
  }

  // ---------------- 快捷回复栏（机器人会话） ----------------

  /// 快捷回复两条（与 iOS 一致）：点击直接发送文本（替换 AI 壳阶段 Toast 占位）
  Widget _buildQuickReplyBar() {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        itemCount: ChatConversationView.quickReplies.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final (title, sendText, icon) =
              ChatConversationView.quickReplies[index];
          return Center(
            child: _quickReplyChip(
              title: title,
              sendText: sendText,
              iconAsset: icon,
            ),
          );
        },
      ),
    );
  }

  /// 快捷回复胶囊（#F1F4FB→白 渐变 + 1.5 白边 + 圆角 16 + 图标 18 + 文案 13。
  /// iOS 参照：XYAIQuickActionButton）
  /// 点击发送 sendText（≠ 展示文案，见 quickReplies 注释）。
  Widget _quickReplyChip({
    required String title,
    required String sendText,
    required String iconAsset,
  }) {
    return GestureDetector(
      key: Key('quick_reply_$title'),
      behavior: HitTestBehavior.opaque,
      onTap: () => unawaited(_sendText(sendText)),
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.pageBackground, Colors.white],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            LoadImage(iconAsset, width: 18, height: 18),
            const SizedBox(width: 5),
            Text(
              title,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 拉黑态输入栏遮罩：盖住输入区并延伸至底部安全区。
/// iOS 参照：XYChatContainerViewController.blockedBannerView
/// （底 #F7F8FA 贴屏幕底，文案 14pt #999「已拉黑对方，无法发送消息」）。
class _BlockedInputBanner extends StatelessWidget {
  const _BlockedInputBanner();

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Container(
      width: double.infinity,
      color: const Color(0xFFF7F8FA),
      // 灰底延伸盖住 Home 指示条；文案仍落在安全区之上的内容行
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SizedBox(
        height: ChatInputBar.inputRowHeight + 6,
        child: Center(
          child: Text(
            '已拉黑对方，无法发送消息',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ),
      ),
    );
  }
}
