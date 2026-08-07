import 'dart:async';
import 'dart:convert';

import 'im_config.dart';
import 'im_models.dart';
import 'im_preview.dart';
import 'im_service.dart';

/// 内存假 IM 服务：无网易云信环境/无后端时演示消息 Tab 与聊天页全链路。
/// 生效条件：`ApiClient.useMock = true`（dev mock，见 imServiceProvider）。
///
/// 假数据：
/// - 3 个普通会话（林小满 2 条未读、周牧野 0、苏晚晴 3 条未读）；
/// - 1 个机器人会话 @RBT#xinyu001（5 条未读，不进列表、不计未读总数）；
/// - 1 个 sysNotification 会话（2 条未读，含 2 条系统通知自定义卡 JSON：
///   第一条 desc、第二条仅 label，演示 desc→label 解析优先级）。
///
/// 阶段 5B 扩展（聊天页）：
/// - 林小满会话（xy_mock_counselor_101）历史消息覆盖 6 种 businessID 卡片
///   各 ≥1 条金样本（JSON 与契约 §4 字段一致）+ 文本/图片/语音消息；
/// - 机器人会话历史为机器人/本人文本 + 图片消息（GREETING 欢迎条为页面层
///   本地构造，非 IM 消息，Android 参照：RobotChatFragment position 0）；
/// - send* 方法本地回显（isSelf=true），并经 [newMessageStream] 推送；
/// - 历史分页：无 lastMsgId 返回最新 count 条；有 lastMsgId 返回其之前
///   count 条（旧→新），语义对齐 getC2CHistoryMessageList。
class MockImService implements ImService {
  final StreamController<List<ImConversation>> _conversationController =
      StreamController<List<ImConversation>>.broadcast();
  final StreamController<int> _unreadController =
      StreamController<int>.broadcast();
  final StreamController<ImMessage> _newMessageController =
      StreamController<ImMessage>.broadcast();

  bool _loggedIn = false;
  String? _userId;
  List<ImConversation> _conversations = const [];

  /// 系统通知历史（旧→新，与 IM SDK 返回顺序一致）。
  List<ImMessage> _systemMessages = const [];

  /// 各会话历史消息（key=对方 userId，旧→新）。
  final Map<String, List<ImMessage>> _userMessages = {};

  /// 本地黑名单（拉黑演示；isUserBlocked / addToBlackList / 管理页共用）
  final Map<String, ImBlockedUser> _blacklist = {};

  /// 本地自增消息 ID 种子（发送回显用）
  int _msgSeq = 0;

  @override
  void Function()? onUserSigExpired;

  @override
  void Function()? onKickedOffline;

  @override
  void Function()? onLoginSuccess;

  @override
  bool get isLoggedIn => _loggedIn;

  @override
  String? get currentUserId => _userId;

  @override
  Stream<List<ImConversation>> get conversationStream =>
      _conversationController.stream;

  @override
  Stream<int> get unreadTotalStream => _unreadController.stream;

  @override
  Stream<ImMessage> get newMessageStream => _newMessageController.stream;

  @override
  Future<void> initSDK(int sdkAppId) async {
    // mock 无需初始化
  }

  @override
  Future<void> login({
    required String imUserId,
    required String imUserSig,
  }) async {
    _loggedIn = true;
    _userId = imUserId;
    _seed();
    _emit();
    onLoginSuccess?.call();
  }

  @override
  Future<void> logout() async {
    _loggedIn = false;
    _userId = null;
    _conversations = const [];
    _systemMessages = const [];
    _userMessages.clear();
    _emit();
    // 让出一轮事件循环再返回，避免「logout 完成 → 立即 login」竞态
    await Future<void>.delayed(Duration.zero);
  }

  @override
  Future<List<ImConversation>> fetchConversations() async =>
      List.unmodifiable(_visibleConversations());

  /// 对外可见会话（剔除黑名单）。
  List<ImConversation> _visibleConversations() => [
        for (final c in _conversations)
          if (!_blacklist.containsKey(c.userId)) c,
      ];

  @override
  Future<void> markConversationRead(String conversationId) async {
    _conversations = [
      for (final c in _conversations)
        c.conversationId == conversationId ? c.copyWith(unreadCount: 0) : c,
    ];
    _emit();
  }

  @override
  Future<List<ImMessage>> historyMessages({
    required String userId,
    int count = 20,
    String? lastMsgId,
  }) async {
    if (userId == ImConfig.systemNotificationUserId) {
      return List.unmodifiable(_systemMessages.take(count));
    }
    final all = _userMessages[userId] ?? const <ImMessage>[];
    // 分页（旧→新返回）：lastMsgId 为空 → 最新 count 条；
    // 否则返回该消息之前的 count 条（Android 参照：RobotChatFragment
    // getC2CHistoryMessageList count=20 下拉加载更早）。
    if (lastMsgId == null) {
      final start = all.length > count ? all.length - count : 0;
      return List.unmodifiable(all.sublist(start));
    }
    final idx = all.indexWhere((m) => m.msgId == lastMsgId);
    if (idx <= 0) return const [];
    final start = idx > count ? idx - count : 0;
    return List.unmodifiable(all.sublist(start, idx));
  }

  @override
  Future<ImMessage> sendTextMessage({
    required String userId,
    required String text,
  }) async {
    _msgSeq += 1;
    final msg = ImMessage(
      msgId: 'mock_local_${_msgSeq.toString().padLeft(4, '0')}',
      senderId: _userId,
      kind: ImMessageKind.text,
      text: text,
      timestamp: DateTime.now(),
      isSelf: true,
      peerId: userId,
    );
    (_userMessages[userId] ??= []).add(msg);
    if (!_newMessageController.isClosed) _newMessageController.add(msg);
    return msg;
  }

  @override
  Future<ImMessage> sendImageMessage({
    required String userId,
    required String imagePath,
  }) async {
    _msgSeq += 1;
    final msg = ImMessage(
      msgId: 'mock_local_${_msgSeq.toString().padLeft(4, '0')}',
      senderId: _userId,
      kind: ImMessageKind.image,
      imagePath: imagePath,
      timestamp: DateTime.now(),
      isSelf: true,
      peerId: userId,
    );
    (_userMessages[userId] ??= []).add(msg);
    if (!_newMessageController.isClosed) _newMessageController.add(msg);
    return msg;
  }

  @override
  Future<ImMessage> sendFileMessage({
    required String userId,
    required String filePath,
    String? fileName,
    int? fileSize,
  }) async {
    _msgSeq += 1;
    final msg = ImMessage(
      msgId: 'mock_local_${_msgSeq.toString().padLeft(4, '0')}',
      senderId: _userId,
      kind: ImMessageKind.file,
      filePath: filePath,
      fileName: fileName,
      fileSize: fileSize,
      timestamp: DateTime.now(),
      isSelf: true,
      peerId: userId,
    );
    (_userMessages[userId] ??= []).add(msg);
    if (!_newMessageController.isClosed) _newMessageController.add(msg);
    return msg;
  }

  @override
  Future<ImMessage> reSendMessage({required String msgId}) async {
    for (final entry in _userMessages.entries) {
      final list = entry.value;
      final idx = list.indexWhere((m) => m.msgId == msgId);
      if (idx < 0) continue;
      final prev = list[idx];
      if (prev.sendStatus != ImMessageSendStatus.failed) {
        throw const ImException(code: -1, desc: 'message is not failed');
      }
      final sent = prev.copyWith(sendStatus: ImMessageSendStatus.sent);
      list[idx] = sent;
      if (!_newMessageController.isClosed) _newMessageController.add(sent);
      return sent;
    }
    throw const ImException(code: -1, desc: 'message not found');
  }

  @override
  Future<ImMessage> sendSoundMessage({
    required String userId,
    required String soundPath,
    required int duration,
  }) async {
    _msgSeq += 1;
    final msg = ImMessage(
      msgId: 'mock_local_${_msgSeq.toString().padLeft(4, '0')}',
      senderId: _userId,
      kind: ImMessageKind.sound,
      soundPath: soundPath,
      soundDuration: duration,
      timestamp: DateTime.now(),
      isSelf: true,
      peerId: userId,
    );
    (_userMessages[userId] ??= []).add(msg);
    if (!_newMessageController.isClosed) _newMessageController.add(msg);
    return msg;
  }

  @override
  Future<String?> resolveSoundPlayablePath(ImMessage message) async {
    // mock 历史语音无真实文件；仅本地刚发送的 soundPath 可播
    final path = message.soundPath;
    if (path != null && path.isNotEmpty) return path;
    return message.soundUrl;
  }

  @override
  Future<String?> resolveImageDisplaySource(ImMessage message) async {
    final path = message.imagePath?.trim();
    if (path != null && path.isNotEmpty) return path;
    final url = message.imageUrl?.trim();
    if (url != null && url.isNotEmpty) return url;
    return null;
  }

  @override
  Future<String?> resolveImagePreviewSource(ImMessage message) async {
    return resolveImageDisplaySource(message);
  }

  @override
  Future<ImMessage> sendCustomMessage({
    required String userId,
    required String customJson,
  }) async {
    _msgSeq += 1;
    final msg = ImMessage(
      msgId: 'mock_local_${_msgSeq.toString().padLeft(4, '0')}',
      senderId: _userId,
      kind: ImMessageKind.custom,
      customJson: customJson,
      timestamp: DateTime.now(),
      isSelf: true,
      peerId: userId,
    );
    (_userMessages[userId] ??= []).add(msg);
    if (!_newMessageController.isClosed) _newMessageController.add(msg);
    return msg;
  }

  @override
  Future<void> addToBlackList(String imUserId) async {
    ImConversation? conv;
    for (final c in _conversations) {
      if (c.userId == imUserId) {
        conv = c;
        break;
      }
    }
    _blacklist[imUserId] = ImBlockedUser(
      userId: imUserId,
      nickName: conv?.showName,
      faceUrl: conv?.faceUrl,
    );
    // 拉黑后会话列表立即不可见（即使尚未 deleteC2C）
    _emit();
  }

  @override
  Future<void> deleteC2CConversation(String imUserId) async {
    _conversations = _conversations.where((c) => c.userId != imUserId).toList();
    _userMessages.remove(imUserId);
    _emit();
  }

  @override
  Future<bool> isUserBlocked(String imUserId) async =>
      _blacklist.containsKey(imUserId);

  @override
  Future<List<ImBlockedUser>> fetchBlackList() async =>
      List.unmodifiable(_blacklist.values.toList());

  @override
  Future<void> removeFromBlackList(String imUserId) async {
    _blacklist.remove(imUserId);
    _emit();
  }

  @override
  Future<void> dispose() async {
    await _conversationController.close();
    await _unreadController.close();
    await _newMessageController.close();
  }

  // ---------------- 调试辅助（手工演示 userSig 过期/被踢） ----------------

  /// 模拟 userSig 过期（演示「登录已过期」弹窗登出链路）
  void debugSimulateUserSigExpired() => onUserSigExpired?.call();

  /// 模拟被踢下线（演示「账号已下线」弹窗登出链路）
  void debugSimulateKickedOffline() => onKickedOffline?.call();

  // ---------------- 内部 ----------------

  void _emit() {
    final visible = _visibleConversations();
    if (!_conversationController.isClosed) {
      _conversationController.add(List.unmodifiable(visible));
    }
    if (!_unreadController.isClosed) {
      _unreadController.add(
        visible.fold(0, (sum, c) => sum + c.unreadCount),
      );
    }
  }

  void _seed() {
    final now = DateTime.now();
    final sysCustomJson = jsonEncode({
      'businessID': 'sys_notice',
      'title': '预约成功提醒：林静 咨询师',
      'desc': '您预约的 06月21日 13:00 语音咨询已确认。',
    });

    _conversations = [
      ImConversation(
        conversationId: 'c2c_xy_mock_counselor_101',
        type: ImConversationType.c2c,
        userId: 'xy_mock_counselor_101',
        showName: '林小满',
        faceUrl: 'https://i.pravatar.cc/150?u=consultant_101',
        lastMessagePreview: '[待支付] 请在 15 分钟内完成支付',
        unreadCount: 1,
        timestamp: now.subtract(const Duration(minutes: 2)),
        consultantId: 101,
        orderId: 'mock_order_1001',
        consultantIntro: '国家二级心理咨询师 · 注册心理师',
        bookedSku: '语音咨询 · 50分钟',
      ),
      ImConversation(
        conversationId: 'c2c_xy_mock_counselor_102',
        type: ImConversationType.c2c,
        userId: 'xy_mock_counselor_102',
        showName: '陈安之',
        faceUrl: 'https://i.pravatar.cc/150?u=consultant_102',
        lastMessagePreview: '[等待确认] 预约申请已发送给咨询师',
        unreadCount: 1,
        timestamp: now.subtract(const Duration(minutes: 4)),
        consultantId: 102,
        orderId: '2003',
        consultantIntro: '婚姻家庭咨询师（中级）',
        bookedSku: '语音咨询 · 50分钟',
      ),
      ImConversation(
        conversationId: 'c2c_xy_mock_counselor_103',
        type: ImConversationType.c2c,
        userId: 'xy_mock_counselor_103',
        showName: '苏晚晴',
        faceUrl: 'https://i.pravatar.cc/150?u=consultant_103',
        lastMessagePreview: '[资料待填写] 提前填写可帮助咨询师了解你',
        unreadCount: 1,
        timestamp: now.subtract(const Duration(minutes: 6)),
        consultantId: 103,
        orderId: '2004',
        consultantIntro: '国家三级心理咨询师',
        bookedSku: '文字咨询 · 50分钟',
      ),
      ImConversation(
        conversationId: 'c2c_xy_mock_counselor_107',
        type: ImConversationType.c2c,
        userId: 'xy_mock_counselor_107',
        showName: '韩青梧',
        faceUrl: 'https://i.pravatar.cc/150?u=consultant_107',
        lastMessagePreview: '[咨询室已开放] 点击进入语音咨询',
        unreadCount: 2,
        timestamp: now.subtract(const Duration(minutes: 8)),
        consultantId: 107,
        orderId: '2006',
        consultantIntro: '精神动力学取向咨询师',
        bookedSku: '语音咨询 · 50分钟',
      ),
      ImConversation(
        conversationId: 'c2c_xy_mock_counselor_106',
        type: ImConversationType.c2c,
        userId: 'xy_mock_counselor_106',
        showName: '沈知遥',
        faceUrl: 'https://i.pravatar.cc/150?u=consultant_106',
        lastMessagePreview: '[等待回顾] 咨询师正在整理本次回顾',
        unreadCount: 1,
        timestamp: now.subtract(const Duration(minutes: 10)),
        consultantId: 106,
        orderId: '2007',
        consultantIntro: '人本主义取向心理咨询师',
        bookedSku: '语音咨询 · 50分钟',
      ),
      ImConversation(
        conversationId: 'c2c_xy_mock_counselor_108',
        type: ImConversationType.c2c,
        userId: 'xy_mock_counselor_108',
        showName: '陈子健',
        faceUrl: 'https://i.pravatar.cc/150?u=consultant_108',
        lastMessagePreview: '[视频咨询中] 点击进入预约会议',
        unreadCount: 1,
        timestamp: now.subtract(const Duration(minutes: 9)),
        consultantId: 108,
        orderId: '2011',
        consultantIntro: '临床与咨询心理学硕士',
        bookedSku: '视频咨询 · 50分钟',
      ),
      ImConversation(
        conversationId: 'c2c_xy_mock_counselor_105',
        type: ImConversationType.c2c,
        userId: 'xy_mock_counselor_105',
        showName: '顾一帆',
        faceUrl: 'https://i.pravatar.cc/150?u=consultant_105',
        lastMessagePreview: '[本次咨询回顾] 已生成，点击查看',
        unreadCount: 1,
        timestamp: now.subtract(const Duration(minutes: 12)),
        consultantId: 105,
        orderId: '2008',
        consultantIntro: '青少年心理发展咨询师',
        bookedSku: '视频咨询 · 50分钟',
      ),
      ImConversation(
        conversationId: 'c2c_xy_mock_counselor_109',
        type: ImConversationType.c2c,
        userId: 'xy_mock_counselor_109',
        showName: '白鹭洲',
        faceUrl: 'https://i.pravatar.cc/150?u=consultant_109',
        lastMessagePreview: '[待评价] 回顾已查看，期待你的反馈',
        unreadCount: 1,
        timestamp: now.subtract(const Duration(minutes: 14)),
        consultantId: 109,
        orderId: '2009',
        consultantIntro: '正念减压（MBSR）引导师',
        bookedSku: '语音咨询 · 50分钟',
      ),
      // 机器人会话：消息 Tab 过滤（@RBT# 前缀），不计未读总数
      ImConversation(
        conversationId: 'c2c_${ImConfig.robotUserId}',
        type: ImConversationType.c2c,
        userId: ImConfig.robotUserId,
        showName: '心愈小鹿',
        faceUrl: null,
        lastMessagePreview: '我在呢，想聊点什么？',
        unreadCount: 5,
        timestamp: now.subtract(const Duration(minutes: 3)),
      ),
      // 系统通知会话：顶部「系统通知」卡，独立红点，不进列表、不计未读总数
      ImConversation(
        conversationId: ImConfig.systemNotificationConversationId,
        type: ImConversationType.c2c,
        userId: ImConfig.systemNotificationUserId,
        showName: '系统通知',
        faceUrl: null,
        lastMessagePreview: customCardPreview(sysCustomJson),
        unreadCount: 2,
        timestamp: now.subtract(const Duration(minutes: 30)),
      ),
    ];

    _systemMessages = [
      // 旧（仅 label，演示 desc 缺失时 label 兜底）
      ImMessage(
        msgId: 'mock_sys_1',
        senderId: ImConfig.systemNotificationUserId,
        kind: ImMessageKind.custom,
        customJson: jsonEncode({
          'businessID': 'sys_notice',
          'title': '版本更新通知 v2.0',
          'label': '换新皮肤啦，还有全新的快速评估体验。',
        }),
        timestamp: now.subtract(const Duration(days: 2)),
      ),
      // 新（desc）
      ImMessage(
        msgId: 'mock_sys_2',
        senderId: ImConfig.systemNotificationUserId,
        kind: ImMessageKind.custom,
        customJson: sysCustomJson,
        timestamp: now.subtract(const Duration(minutes: 30)),
      ),
    ];

    _seedChatHistories(now);
  }

  /// 阶段 5B：聊天页历史消息金样本。
  ///
  /// 6 种 businessID 卡片 JSON 与契约 §4 字段一一对应：
  /// begin_chat_middle / remind_window_middle / for_evaluate_middle /
  /// for_summary_middle / summary_advise / question_assistant。
  void _seedChatHistories(DateTime now) {
    const counselor = 'xy_mock_counselor_101';
    final self = _userId ?? 'xy_mock_1001';

    _userMessages[counselor] = [
      // 1. begin_chat_middle：type=2 语音咨询（金样本：title/desc/date/type）
      ImMessage(
        msgId: 'mock_c101_01',
        senderId: counselor,
        kind: ImMessageKind.custom,
        customJson: jsonEncode({
          'businessID': 'begin_chat_middle',
          'title': '预约成功',
          'desc': '语音咨询',
          'date': '06-10 14:00～14:50',
          'type': 2,
        }),
        timestamp: now.subtract(const Duration(days: 3, minutes: 50)),
      ),
      // 2. 对方文本
      ImMessage(
        msgId: 'mock_c101_02',
        senderId: counselor,
        kind: ImMessageKind.text,
        text: '你好，我是林小满，很高兴这次能陪你一起聊聊。',
        timestamp: now.subtract(const Duration(days: 3, minutes: 49)),
      ),
      // 3. 本人文本
      ImMessage(
        msgId: 'mock_c101_03',
        senderId: self,
        kind: ImMessageKind.text,
        text: '老师好，最近睡眠不太好，想请您帮我看看。',
        timestamp: now.subtract(const Duration(days: 3, minutes: 45)),
        isSelf: true,
      ),
      // 4. 对方图片消息（mock 用内置资源回显；真实环境为 imageElem 本地路径/URL）
      ImMessage(
        msgId: 'mock_c101_04',
        senderId: counselor,
        kind: ImMessageKind.image,
        imagePath: 'assets/images/home_mascot.png',
        timestamp: now.subtract(const Duration(days: 3, minutes: 40)),
      ),
      // 5. 对方语音消息（mock 无真实文件，仅演示气泡渲染与时长展示）
      ImMessage(
        msgId: 'mock_c101_05',
        senderId: counselor,
        kind: ImMessageKind.sound,
        soundDuration: 8,
        timestamp: now.subtract(const Duration(days: 3, minutes: 38)),
      ),
      // 6. remind_window_middle：type=1 生效，link → 1006 全参数（金样本）
      ImMessage(
        msgId: 'mock_c101_06',
        senderId: counselor,
        kind: ImMessageKind.custom,
        customJson: jsonEncode({
          'businessID': 'remind_window_middle',
          'title': '咨询室已开放',
          'desc': '您的语音咨询即将开始，请在预约时间内进入咨询室。',
          'type': 1,
          'buttonText': '进入咨询室',
          'link': 'nanjingxinyu://currantmind?routeTypeCode=1006'
              '&orderId=2006&supportMode=2&roomId=room-2006'
              '&roomName=语音咨询&startTime=1718000000&endTime=1718003000'
              '&imUserId=$counselor&userName=林小满',
        }),
        timestamp: now.subtract(const Duration(days: 3, minutes: 35)),
      ),
      // 7. for_evaluate_middle：未完成（按钮可点）；link → 1008（金样本）
      ImMessage(
        msgId: 'mock_c101_07',
        senderId: counselor,
        kind: ImMessageKind.custom,
        customJson: jsonEncode({
          'businessID': 'for_evaluate_middle',
          'title': '本次咨询已结束',
          'desc': '咨询感受如何？期待你的评价',
          'type': 1,
          'buttonText': '评价本次咨询',
          'link': 'nanjingxinyu://currantmind?routeTypeCode=1008'
              '&orderId=2009&counselorId=101'
              '&counselorName=林小满',
        }),
        timestamp: now.subtract(const Duration(days: 3, minutes: 30)),
      ),
      // 8. for_evaluate_middle：type=2 已完成置灰（金样本）
      ImMessage(
        msgId: 'mock_c101_08',
        senderId: counselor,
        kind: ImMessageKind.custom,
        customJson: jsonEncode({
          'businessID': 'for_evaluate_middle',
          'title': '本次咨询已结束',
          'desc': '感谢你的评价与反馈',
          'type': 2,
          'buttonText': '已完成',
          'link': 'nanjingxinyu://currantmind?routeTypeCode=1008'
              '&orderId=2009&counselorId=101'
              '&counselorName=林小满',
        }),
        timestamp: now.subtract(const Duration(days: 3, minutes: 29)),
      ),
      // 9. for_summary_middle：填写小结（仅咨询师端可见按钮）；link → 1010（金样本）
      ImMessage(
        msgId: 'mock_c101_09',
        senderId: counselor,
        kind: ImMessageKind.custom,
        customJson: jsonEncode({
          'businessID': 'for_summary_middle',
          'title': '请填写咨询小结',
          'desc': '及时完成小结，帮助来访者更好地成长',
          'type': 1,
          'buttonText': '填写小结',
          'link': 'nanjingxinyu://currantmind?routeTypeCode=1010&RtId=2007',
        }),
        timestamp: now.subtract(const Duration(days: 3, minutes: 28)),
      ),
      // 10. summary_advise：方向性白卡，desc 小结段 + label 建议段（金样本）
      ImMessage(
        msgId: 'mock_c101_10',
        senderId: counselor,
        kind: ImMessageKind.custom,
        customJson: jsonEncode({
          'businessID': 'summary_advise',
          'title': '咨询小结与建议',
          'desc': '本次咨询围绕睡眠困扰展开，来访者近期入睡困难、易醒，'
              '与工作压力相关性较高，咨询中已完成初步情绪疏导。',
          'label': '建议保持规律作息，睡前 1 小时远离屏幕；'
              '可配合呼吸放松练习，必要时预约下一次咨询。',
          'buttonText': '点击查看详情',
          'link': 'nanjingxinyu://currantmind?routeTypeCode=1007&RtId=2008',
        }),
        timestamp: now.subtract(const Duration(days: 3, minutes: 27)),
      ),
      // 11. question_assistant：方向性工具卡（type=3 木鱼；金样本，
      // payload 与 XYChatInputBar.swift:858 下发格式一致）
      ImMessage(
        msgId: 'mock_c101_11',
        senderId: counselor,
        kind: ImMessageKind.custom,
        customJson: jsonEncode({
          'businessID': 'question_assistant',
          'type': 3,
          'title': '电子木鱼',
          'desc': '轻触屏幕敲击木鱼，舒缓情绪、释放压力。',
          'buttonText': '敲击木鱼',
          'link': 'https://admin.currantmind.cn/relax/muyu.html',
        }),
        timestamp: now.subtract(const Duration(days: 3, minutes: 26)),
      ),
      // 12. 最近一条对方文本（与会话列表预览一致）
      ImMessage(
        msgId: 'mock_c101_12',
        senderId: counselor,
        kind: ImMessageKind.text,
        text: '好的，那我们周六见～',
        timestamp: now.subtract(const Duration(minutes: 8)),
      ),
    ];

    // 机器人会话：机器人/本人文本 + 图片（GREETING 欢迎条为页面层本地构造）
    _userMessages[ImConfig.robotUserId] = [
      ImMessage(
        msgId: 'mock_rbt_01',
        senderId: ImConfig.robotUserId,
        kind: ImMessageKind.text,
        text: '最近感觉怎么样？有什么想聊的都可以告诉我。',
        timestamp: now.subtract(const Duration(hours: 1, minutes: 5)),
      ),
      ImMessage(
        msgId: 'mock_rbt_02',
        senderId: self,
        kind: ImMessageKind.text,
        text: '有点焦虑，想先深呼吸放松一下。',
        timestamp: now.subtract(const Duration(hours: 1)),
        isSelf: true,
      ),
      ImMessage(
        msgId: 'mock_rbt_03',
        senderId: self,
        kind: ImMessageKind.image,
        imagePath: 'assets/images/home_mascot.png',
        timestamp: now.subtract(const Duration(minutes: 55)),
        isSelf: true,
      ),
      ImMessage(
        msgId: 'mock_rbt_04',
        senderId: ImConfig.robotUserId,
        kind: ImMessageKind.text,
        text: '可以，我们先慢慢吸气 4 秒，再呼气 6 秒。现在身体哪里最紧绷？',
        timestamp: now.subtract(const Duration(minutes: 12)),
      ),
      ImMessage(
        msgId: 'mock_rbt_05',
        senderId: self,
        kind: ImMessageKind.text,
        text: '肩膀有点紧，想到明天的工作就担心做不好。',
        timestamp: now.subtract(const Duration(minutes: 9)),
        isSelf: true,
      ),
      ImMessage(
        msgId: 'mock_rbt_06',
        senderId: ImConfig.robotUserId,
        kind: ImMessageKind.text,
        text: '听起来你既紧张，也很在意把事情做好。先不用解决全部，我们只找明天最小的一步。',
        timestamp: now.subtract(const Duration(minutes: 7)),
      ),
      ImMessage(
        msgId: 'mock_rbt_07',
        senderId: self,
        kind: ImMessageKind.text,
        text: '我可以先列出最重要的三件事。',
        timestamp: now.subtract(const Duration(minutes: 5)),
        isSelf: true,
      ),
      ImMessage(
        msgId: 'mock_rbt_08',
        senderId: ImConfig.robotUserId,
        kind: ImMessageKind.text,
        text: '这个开始很具体。写完后告诉我，我们再一起看看哪件最适合先做。',
        timestamp: now.subtract(const Duration(minutes: 3)),
      ),
    ];

    // 保留六类协议金样本，但不暴露在业务会话列表中。
    _userMessages['xy_mock_contract_samples'] = _userMessages[counselor]!;
    _seedLifecycleChatHistories(now);
  }

  /// 七个独立咨询师分别演示用户生命周期的一个当前节点。
  void _seedLifecycleChatHistories(DateTime now) {
    ImMessage card(
      String peer,
      String id,
      Map<String, Object> payload,
      int minutesAgo,
    ) {
      final normalized = <String, Object>{
        ...payload,
        'messageType': payload['businessID'] == 'summary_advise'
            ? 'summary_card'
            : 'workflow_card',
        if (payload['desc'] case final String description)
          'description': description,
        if (payload['buttonText'] case final String actionLabel)
          'actionLabel': actionLabel,
      };
      return ImMessage(
        msgId: id,
        senderId: peer,
        kind: ImMessageKind.custom,
        customJson: jsonEncode(normalized),
        timestamp: now.subtract(Duration(minutes: minutesAgo)),
      );
    }

    ImMessage text(
      String peer,
      String id,
      String content,
      int minutesAgo, {
      bool isSelf = false,
    }) =>
        ImMessage(
          msgId: id,
          senderId: isSelf ? 'xy_mock_user_001' : peer,
          kind: ImMessageKind.text,
          text: content,
          isSelf: isSelf,
          timestamp: now.subtract(Duration(minutes: minutesAgo)),
        );

    _userMessages['xy_mock_counselor_101'] = [
      text('xy_mock_counselor_101', 'pay_user_01', '老师您好，我想预约这周的咨询。', 8,
          isSelf: true),
      text('xy_mock_counselor_101', 'pay_counselor_01', '你好，完成支付后预约会立即发给我确认。',
          6),
      card(
          'xy_mock_counselor_101',
          'workflow_pay_1001',
          {
            'businessID': 'begin_chat_middle',
            'audience': 'user',
            'status': 'pending_payment',
            'orderId': 'mock_order_1001',
            'title': '预约申请已创建',
            'desc': '请在 15 分钟内支付，支付后等待确认。',
            'date': '订单号 MOCK2024001001',
            'buttonText': '去支付',
            'type': 2,
          },
          2),
    ];
    _userMessages['xy_mock_counselor_102'] = [
      text('xy_mock_counselor_102', 'confirm_user_01', '我已经支付完成了，请问接下来需要做什么？',
          10,
          isSelf: true),
      text('xy_mock_counselor_102', 'confirm_counselor_01',
          '预约申请已收到，我会尽快确认本次时间。', 7),
      card(
          'xy_mock_counselor_102',
          'workflow_confirm_2003',
          {
            'businessID': 'begin_chat_middle',
            'audience': 'user',
            'status': 'pending_confirmation',
            'orderId': '2003',
            'title': '等待咨询师确认',
            'desc': '支付已完成，确认后会开放咨询前资料与咨询入口',
            'date': '08-10 11:46～12:36',
            'type': 2,
          },
          4),
    ];
    _userMessages['xy_mock_counselor_103'] = [
      text('xy_mock_counselor_103', 'intake_counselor_01',
          '咨询前资料不是强制项，但提前填写能帮助我更快了解你的情况。', 12),
      text('xy_mock_counselor_103', 'intake_user_01', '好的，我稍后补充。', 9,
          isSelf: true),
      card(
          'xy_mock_counselor_103',
          'workflow_intake_2004',
          {
            'businessID': 'begin_chat_middle',
            'audience': 'user',
            'status': 'pending_intake',
            'orderId': '2004',
            'title': '预约已确认',
            'desc': '咨询前资料为选填，提前填写可帮助咨询师了解你',
            'date': '08-11 11:46～12:36',
            'buttonText': '填写资料',
            'type': 1,
          },
          6),
    ];
    _userMessages['xy_mock_counselor_107'] = [
      card(
          'xy_mock_counselor_107',
          'room_notice_2006',
          {
            'businessID': 'begin_chat_middle',
            'audience': 'user',
            'status': 'confirmed',
            'orderId': '2006',
            'title': '咨询师已确认预约',
            'desc': '本次预约已确认',
            'date': '今天 11:50',
            'type': 2,
          },
          16),
      text('xy_mock_counselor_107', 'room_counselor_01',
          '我已经进入咨询室，你准备好后可以直接进入。', 11),
      card(
          'xy_mock_counselor_107',
          'workflow_room_2006',
          {
            'businessID': 'remind_window_middle',
            'audience': 'user',
            'status': 'session_open',
            'orderId': '2006',
            'sessionId': 'session-2006',
            'title': '咨询室已开放',
            'desc': '本次语音咨询正在进行，请进入咨询室',
            'type': 1,
            'buttonText': '进入咨询室',
            'link': 'nanjingxinyu://currantmind?routeTypeCode=1006'
                '&orderId=2006&sessionId=session-2006&supportMode=2'
                '&roomId=room-2006&roomName=语音咨询'
                '&imUserId=xy_mock_counselor_107&userName=韩青梧',
          },
          8),
    ];
    _userMessages['xy_mock_counselor_108'] = [
      card(
          'xy_mock_counselor_108',
          'video_room_notice_2011',
          {
            'businessID': 'begin_chat_middle',
            'audience': 'user',
            'status': 'confirmed',
            'orderId': '2011',
            'title': '视频咨询已开始',
            'desc': '咨询师已进入预约会议',
            'date': '今天 15:23',
            'type': 2,
          },
          16),
      text('xy_mock_counselor_108', 'video_room_counselor_01',
          '我已经进入视频咨询室，你准备好后可以直接加入。', 12),
      text('xy_mock_counselor_108', 'video_room_user_01', '好的，我现在进入。', 10,
          isSelf: true),
      card(
          'xy_mock_counselor_108',
          'workflow_video_room_2011',
          {
            'businessID': 'remind_window_middle',
            'audience': 'user',
            'status': 'session_open',
            'orderId': '2011',
            'sessionId': 'session-2011',
            'title': '视频咨询室已开放',
            'desc': '本次视频咨询正在进行，请进入预约会议',
            'type': 1,
            'buttonText': '进入视频会议',
            'link': 'nanjingxinyu://currantmind?routeTypeCode=1006'
                '&orderId=2011&sessionId=session-2011&supportMode=3'
                '&roomId=room-2011&roomName=视频咨询'
                '&imUserId=xy_mock_counselor_108&userName=陈子健',
          },
          8),
    ];
    _userMessages['xy_mock_counselor_106'] = [
      text('xy_mock_counselor_106', 'wait_user_01', '谢谢老师，今天聊完轻松了一些。', 16,
          isSelf: true),
      text('xy_mock_counselor_106', 'wait_counselor_01',
          '辛苦了，我会整理本次回顾和接下来的行动建议。', 13),
      card(
          'xy_mock_counselor_106',
          'workflow_wait_recap_2007',
          {
            'businessID': 'begin_chat_middle',
            'audience': 'user',
            'status': 'pending_review',
            'orderId': '2007',
            'sessionId': 'session-2007',
            'draftId': 'draft-2007',
            'title': '本次咨询已结束',
            'desc': '咨询师正在整理用户可见回顾，完成后会通过消息通知你',
            'date': '等待咨询回顾',
            'type': 2,
          },
          10),
    ];
    _userMessages['xy_mock_counselor_105'] = [
      text('xy_mock_counselor_105', 'recap_counselor_01',
          '本次回顾已经确认并分享给你，只包含用户可见内容。', 16),
      card(
          'xy_mock_counselor_105',
          'workflow_recap_2008',
          {
            'businessID': 'summary_advise',
            'audience': 'user',
            'status': 'shared',
            'orderId': '2008',
            'sessionId': 'session-2008',
            'draftId': 'draft-2008',
            'title': '本次咨询回顾',
            'desc': '本次一起梳理了工作压力、睡眠和自我评价之间的联系，也找到了一种更贴近事实的看法。',
            'label': '睡前记录一次自动想法，完成四轮呼吸练习。',
            'buttonText': '查看完整回顾与作业',
            'link': 'nanjingxinyu://currantmind?routeTypeCode=1007'
                '&orderId=2008&sessionId=session-2008&draftId=draft-2008',
          },
          12),
    ];
    _userMessages['xy_mock_counselor_109'] = [
      text('xy_mock_counselor_109', 'evaluate_user_01', '我已经看完回顾了，建议很清楚。', 18,
          isSelf: true),
      text('xy_mock_counselor_109', 'evaluate_counselor_01',
          '感谢你的反馈，也欢迎完成本次咨询评价。', 16),
      card(
          'xy_mock_counselor_109',
          'workflow_evaluate_2009',
          {
            'businessID': 'for_evaluate_middle',
            'audience': 'user',
            'status': 'pending_review',
            'orderId': '2009',
            'sessionId': 'session-2009',
            'draftId': 'draft-2009',
            'title': '回顾已查看',
            'desc': '咨询感受如何？期待你的真实反馈',
            'type': 1,
            'buttonText': '评价本次咨询',
            'link': 'nanjingxinyu://currantmind?routeTypeCode=1008'
                '&orderId=2009&counselorId=109&counselorName=白鹭洲',
          },
          14),
    ];
  }
}
