import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:nim_core_v2/nim_core.dart';

import 'im_config.dart';
import 'im_models.dart';
import 'im_preview.dart';
import 'im_service.dart';
import 'middle_card_unread.dart';
import '../../utils/ly_cache.dart';
import '../storage/local_flags.dart';

/// 网易云信 NIM 实现：nim_core_v2 V2 SDK。
///
/// 登录凭证由后端 provision（网易云信 NIM token）。
///
/// 平台配置待办（真机联调前）：
/// - iOS：Info.plist 无需额外权限；Pod 由插件自动集成；
/// - Android：nim_core_v2 已内置 manifest 合并；离线推送证书属阶段 8。
class NeteaseImService implements ImService {
  bool _initialized = false;
  bool _loggedIn = false;
  String? _userId;

  /// userSig 过期近似节流（网易云信无独立 token 过期流，由 server kick 近似；
  /// 60s 节流，避免回调风暴触发多次弹窗）。
  static const Duration _userSigExpiredThrottle = Duration(seconds: 60);
  DateTime? _lastUserSigExpiredAt;

  final StreamController<List<ImConversation>> _conversationController =
      StreamController<List<ImConversation>>.broadcast();
  final StreamController<int> _unreadController =
      StreamController<int>.broadcast();
  final StreamController<ImMessage> _newMessageController =
      StreamController<ImMessage>.broadcast();

  /// userId → NIM 会话 ID 缓存（NIM conversationId 为 native 构造的不透明串，
  /// 须经 ConversationIdUtil.p2pConversationId 换算；按 userId 缓存避免每次发送都打 method channel）。
  final Map<String, String> _cidCache = {};

  /// messageClientId → NIMMessage 缓存（重发 / 附件下载需要原始 NIMMessage）。
  final Map<String, NIMMessage> _msgCache = {};

  /// 全屏预览图源缓存（msgId → path/url），气泡预取与预览页共享。
  final Map<String, String> _previewSourceCache = {};
  final Map<String, Future<String?>> _previewSourceInflight = {};

  // SDK 事件流订阅（dispose 时取消）。
  StreamSubscription<NIMKickedOfflineDetail>? _kickedSub;
  StreamSubscription<NIMConversation>? _convCreatedSub;
  StreamSubscription<List<NIMConversation>>? _convChangedSub;
  StreamSubscription<List<String>>? _convDeletedSub;
  StreamSubscription<int>? _unreadSub;
  StreamSubscription<List<NIMMessage>>? _recvSub;
  StreamSubscription<void>? _localSyncFinishedSub;
  // 对端用户资料变更（含 SDK 异步补全的昵称/头像）——用来刷新会话展示名。
  StreamSubscription<List<NIMUserInfo>>? _userProfileSub;

  /// 会话列表刷新防抖（会话变更 / 未读变更 / 收消息常同帧连发）。
  Timer? _refreshDebounce;

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
    if (_initialized) return;

    // 隐私协议强校验：未同意隐私协议前禁止初始化网易云信 SDK（符合 App 隐私合规要求）
    final accepted =
        LyCache.getSync<bool>(key: LocalFlags.agreementAccepted) ?? false;
    if (!accepted) {
      debugPrint('🟡 [NIM initSDK] 未同意隐私协议，暂停网易云信 SDK 初始化');
      return;
    }

    // NIM 用 appKey（非腾讯 SDKAppID）；按平台选 options。
    // 离线推送：iOS 传 apnsCername（控制台证书名），Android 传 mixPushConfig（厂商通道）。
    // autoUpdateApnsToken 默认 true，SDK 会自动把 APNs token 上报云信，无需手动处理 token。
    final options = Platform.isIOS
        ? NIMIOSSDKOptions(
            appKey: ImConfig.neteaseAppKey,
            apnsCername: ImConfig.neteaseApnsCername.isEmpty
                ? null
                : ImConfig.neteaseApnsCername,
          )
        : NIMAndroidSDKOptions(
            appKey: ImConfig.neteaseAppKey,
            mixPushConfig: _buildMixPushConfig(),
          );
    final res = await NimCore.instance.initialize(options);
    if (!res.isSuccess) {
      throw ImException(
          code: res.code, desc: res.errorDetails ?? 'NIM initSDK 失败');
    }
    _initialized = true;
    // 排障日志：确认离线推送证书名已传入（为空则 iOS 不会注册 APNs）
    debugPrint(
        '🟣 [NIM initSDK] apnsCername="${ImConfig.neteaseApnsCername}"（须与网易云信控制台 p8/p12 证书名完全一致）');
    _registerListeners();
  }

  /// 构建 Android 厂商混合推送配置（仅配置在 ImConfig 中填了证书名的厂商）。
  /// 全部未配置时返回 null，SDK 不启用厂商通道（仍可走云信自有推送，但进程被杀后不可靠）。
  static NIMMixPushConfig? _buildMixPushConfig() {
    if (ImConfig.neteaseXmCerName == null &&
        ImConfig.neteaseHwCerName == null &&
        ImConfig.neteaseOppoCerName == null &&
        ImConfig.neteaseVivoCerName == null &&
        ImConfig.neteaseMzCerName == null &&
        ImConfig.neteaseHonorCerName == null) {
      return null;
    }
    return NIMMixPushConfig(
      xmAppId: ImConfig.neteaseXmAppId,
      xmAppKey: ImConfig.neteaseXmAppKey,
      xmCertificateName: ImConfig.neteaseXmCerName,
      hwAppId: ImConfig.neteaseHwAppId,
      hwCertificateName: ImConfig.neteaseHwCerName,
      oppoAppId: ImConfig.neteaseOppoAppId,
      oppoAppKey: ImConfig.neteaseOppoAppKey,
      oppoAppSecret: ImConfig.neteaseOppoAppSecret,
      oppoCertificateName: ImConfig.neteaseOppoCerName,
      vivoCertificateName: ImConfig.neteaseVivoCerName,
      mzAppId: ImConfig.neteaseMzAppId,
      mzAppKey: ImConfig.neteaseMzAppKey,
      mzCertificateName: ImConfig.neteaseMzCerName,
      honorCertificateName: ImConfig.neteaseHonorCerName,
    );
  }

  /// 注册 NIM 事件流监听（initSDK 后调用一次）。
  ///
  /// 会话读/写/事件一律走 `localConversationService`（本地会话，登录后自动同步到
  /// 本地库）——消息 Tab 的会话列表来自本地库。云端的 `conversationService`
  /// 是「漫游会话」服务，其 getConversationList 需开通且会回 191001 misuse，
  /// 不适合做会话列表数据源。
  void _registerListeners() {
    final conv = NimCore.instance.localConversationService;
    _kickedSub = NimCore.instance.loginService.onKickedOffline
        .listen(_handleKickedOffline);
    _convCreatedSub =
        conv.onConversationCreated.listen((_) => _scheduleRefreshConversations());
    _convChangedSub =
        conv.onConversationChanged.listen((_) => _scheduleRefreshConversations());
    _convDeletedSub =
        conv.onConversationDeleted.listen((_) => _scheduleRefreshConversations());
    _unreadSub = conv.onTotalUnreadCountChanged.listen((total) {
      if (!_unreadController.isClosed) _unreadController.add(total);
      // 总未读变更时补拉会话列表：个别消息类型（如自定义卡）可能只推 total、
      // 会话行 unreadCount 滞后，导致工作台消息 Tab / 会话角标不刷新。
      _scheduleRefreshConversations();
    });
    _recvSub = NimCore.instance.messageService.onReceiveMessages.listen((list) {
      for (final m in list) {
        if (!_newMessageController.isClosed) {
          _newMessageController.add(_toImMessage(m));
        }
      }
      // 收到消息后补拉一次，确保自定义卡等场景会话 unreadCount 及时同步。
      if (list.isNotEmpty) _scheduleRefreshConversations();
    });
    // 登录后会话同步完成时补拉一次：覆盖「登录后立即 fetch 仍空、sync 期间未逐条
    // 推 onConversationChanged」的窗口，确保消息 Tab 能拿到完整列表。
    _localSyncFinishedSub =
        conv.onSyncFinished.listen((_) => _refreshConversations());
    // 对端资料变更时补拉会话列表：首次收到消息瞬间 SDK 尚未把对端昵称同步进
    // NIMConversation.name，会话先以 accid（如 cst_109）兜底展示；SDK 随后异步
    // 补全资料会触发 onUserProfileChanged，借此重拉即可在停留消息页时显示真名，
    // 无需依赖进入小鹿（markConversationRead）间接触发的刷新。
    _userProfileSub = NimCore.instance.userService.onUserProfileChanged
        .listen((_) => _scheduleRefreshConversations());
  }

  @override
  Future<void> login({
    required String imUserId,
    required String imUserSig,
  }) async {
    debugPrint('🟢 [NIM login] 走到网易云信登录 imUserId=$imUserId sigLen=${imUserSig.length}');
    await initSDK(0); // sdkAppId 仅占位，NIM 用 appKey。
    final res = await NimCore.instance.loginService
        .login(imUserId, imUserSig, NIMLoginOption());
    debugPrint('🟢 [NIM login] 登录结果 success=${res.isSuccess} code=${res.code} '
        'error=${res.errorDetails}');
    if (!res.isSuccess) {
      throw ImException(code: res.code, desc: res.errorDetails ?? 'NIM 登录失败');
    }
    _loggedIn = true;
    _userId = imUserId;
    _lastUserSigExpiredAt = null;
    onLoginSuccess?.call();
    await _refreshConversations();
  }

  @override
  Future<void> logout() async {
    if (!_loggedIn) return;
    _loggedIn = false;
    _userId = null;
    try {
      await NimCore.instance.loginService.logout();
    } catch (e) {
      debugPrint('🔴 [NIM] logout 异常：$e');
    }
    // 让出一轮事件循环，规避登出竞态。
    await Future<void>.delayed(Duration.zero);
  }

  @override
  Future<List<ImConversation>> fetchConversations() async {
    if (!_loggedIn) return const [];
    final res = await NimCore.instance.localConversationService
        .getConversationList(0, 100);
    if (!res.isSuccess) {
      debugPrint('🔴 [NIM] 拉会话列表失败 ${res.code} ${res.errorDetails}');
      return const [];
    }
    final list = res.data?.conversationList ?? const <NIMConversation>[];
    final blocked = await _blackListUserIds();
    // 并发解析各会话对端 userId（NIM conversationId 为不透明串，须 ConversationIdUtil 换算）。
    final entries = await Future.wait(
      list.map((c) async => MapEntry<NIMConversation, String>(
          c, await _conversationPeerId(c.conversationId))),
    );
    // 过滤黑名单 / 空对端后的可见会话。
    final visible = <MapEntry<NIMConversation, String>>[
      for (final e in entries)
        if (e.value.isEmpty || !blocked.contains(e.value)) e,
    ];
    // 首次进线消息时 SDK 可能尚未把对端昵称同步进 NIMConversation.name，导致会话先以
    // accid（如 cst_109）兜底展示。对 name 缺失的会话主动拉一次网易云信用户资料补
    // 昵称/头像（与 fetchBlackList 同一套 IM 接口，不涉业务后端）。
    // name 为空、或 SDK 退化为把 name 填成对端 accid（未拉到真实昵称的兜底）时都需
    // 主动拉资料补全——否则历史会话（创建时昵称尚未同步、name 被存成 accid）会一直显示 accid。
    final needProfile = <String>[
      for (final e in visible)
        if (e.value.isNotEmpty &&
            (e.key.name == null ||
                e.key.name!.isEmpty ||
                e.key.name == e.value))
          e.value,
    ];
    final profileById = await _fetchUserProfiles(needProfile);
    return [
      for (final e in visible)
        _toImConversation(e.key, e.value, profileById[e.value]),
    ];
  }

  /// 批量拉网易云信用户资料（昵称/头像）；失败返回空表，不阻断会话列表。
  Future<Map<String, NIMUserInfo>> _fetchUserProfiles(
      List<String> accids) async {
    if (accids.isEmpty) return const {};
    final res = await NimCore.instance.userService.getUserList(accids);
    if (!res.isSuccess) {
      debugPrint('🟡 [NIM] getUserList 失败 accids=$accids code=${res.code}');
      return const {};
    }
    final byId = <String, NIMUserInfo>{};
    for (final u in res.data ?? const <NIMUserInfo>[]) {
      if (u.accountId != null) byId[u.accountId!] = u;
    }
    final resolved = byId.values
        .where((u) => u.name != null && u.name!.isNotEmpty)
        .length;
    debugPrint(
        '🟢 [NIM] getUserList 请求 ${accids.length} 个、命中昵称 $resolved 个 accids=$accids');
    return byId;
  }

  /// 当前黑名单 userId 集合；失败返回空（不阻断会话列表）。
  Future<Set<String>> _blackListUserIds() async {
    final res = await NimCore.instance.userService.getBlockList();
    if (!res.isSuccess) return const {};
    return {
      for (final id in res.data ?? const <String>[])
        if (id.isNotEmpty) id,
    };
  }

  Future<String> _conversationPeerId(String? cid) async {
    if (cid == null || cid.isEmpty) return '';
    final r =
        await NimCore.instance.conversationIdUtil.conversationTargetId(cid);
    return r.data ?? '';
  }

  @override
  Future<void> markConversationRead(String conversationId) async {
    final cid = await _resolveConversationId(conversationId);
    if (cid.isEmpty) return;
    await NimCore.instance.localConversationService.markConversationRead(cid);
    await _refreshConversations();
  }

  @override
  Future<List<ImMessage>> historyMessages({
    required String userId,
    int count = 20,
    String? lastMsgId,
  }) async {
    if (!_loggedIn) return const [];
    final cid = await _p2pCid(userId);
    final anchor = (lastMsgId != null && lastMsgId.isNotEmpty)
        ? _msgCache[lastMsgId]
        : null;
    final option = NIMMessageListOption(
      conversationId: cid,
      anchorMessage: anchor,
      direction: NIMQueryDirection.desc,
      limit: count,
    );
    final res =
        await NimCore.instance.messageService.getMessageList(option: option);
    if (!res.isSuccess) {
      throw ImException(code: res.code, desc: res.errorDetails ?? 'NIM 拉取历史失败');
    }
    // SDK desc 返回新→旧；翻转为旧→新，与 ImService 契约对齐。
    final raw = res.data ?? const <NIMMessage>[];
    final mapped = [for (final m in raw.reversed) _toImMessage(m)];
    return _withoutSupersededFailedImages(mapped);
  }

  /// 去重：同 uuid/path 已有成功条时，从返回列表隐藏被取代的失败图。
  /// （NIM 侧本地孤儿清理待补，此处先按 UI 隐藏。）
  List<ImMessage> _withoutSupersededFailedImages(List<ImMessage> messages) {
    final successUuids = <String>{};
    final successPaths = <String>{};
    for (final m in messages) {
      if (!(m.isSelf &&
          m.kind == ImMessageKind.image &&
          m.sendStatus == ImMessageSendStatus.sent)) {
        continue;
      }
      final uuid = m.imageUuid?.trim();
      if (uuid != null && uuid.isNotEmpty) successUuids.add(uuid);
      final path = m.imagePath?.trim();
      if (path != null && path.isNotEmpty) successPaths.add(path);
    }
    if (successUuids.isEmpty && successPaths.isEmpty) return messages;
    final kept = <ImMessage>[];
    for (final m in messages) {
      final isFailedImg = m.isSelf &&
          m.kind == ImMessageKind.image &&
          m.sendStatus == ImMessageSendStatus.failed;
      if (!isFailedImg) {
        kept.add(m);
        continue;
      }
      final uuid = m.imageUuid?.trim();
      final path = m.imagePath?.trim();
      final superseded =
          (uuid != null && uuid.isNotEmpty && successUuids.contains(uuid)) ||
              (path != null && path.isNotEmpty && successPaths.contains(path));
      if (superseded) continue;
      kept.add(m);
    }
    return kept;
  }

  @override
  Future<ImMessage> sendTextMessage({
    required String userId,
    required String text,
  }) async {
    final created = await MessageCreator.createTextMessage(text);
    if (!created.isSuccess || created.data == null) {
      throw ImException(
          code: created.code, desc: created.errorDetails ?? 'createText 失败');
    }
    return _send(userId, created.data!);
  }

  @override
  Future<ImMessage> sendImageMessage({
    required String userId,
    required String imagePath,
  }) async {
    // NIM createImageMessage 需显式宽高（腾讯 SDK 自动探测）；本地解码取尺寸。
    final (w, h) = await _imageDimensions(imagePath);
    final created =
        await MessageCreator.createImageMessage(imagePath, null, null, w, h);
    if (!created.isSuccess || created.data == null) {
      throw ImException(
          code: created.code, desc: created.errorDetails ?? 'createImage 失败');
    }
    return _send(userId, created.data!);
  }

  @override
  Future<ImMessage> reSendMessage({required String msgId}) async {
    // NIM 无 resendMessage：用同一 NIMMessage 再次 sendMessage（已携带 messageClientId）。
    final original = _msgCache[msgId];
    if (original == null) {
      throw const ImException(code: -1, desc: '原消息不存在，无法重发');
    }
    final cid =
        (original.conversationId != null && original.conversationId!.isNotEmpty)
            ? original.conversationId!
            : await _p2pCid(original.receiverId ?? '');
    final res = await NimCore.instance.messageService
        .sendMessage(message: original, conversationId: cid);
    if (!res.isSuccess || res.data?.message == null) {
      throw ImException(code: res.code, desc: res.errorDetails ?? '重发失败');
    }
    final sent = _toImMessage(res.data!.message!).copyWith(
      sendStatus: ImMessageSendStatus.sent,
    );
    if (!_newMessageController.isClosed) _newMessageController.add(sent);
    return sent;
  }

  @override
  Future<ImMessage> sendSoundMessage({
    required String userId,
    required String soundPath,
    required int duration,
  }) async {
    // 入参 duration 为秒；NIM createAudioMessage 需毫秒。
    final created = await MessageCreator.createAudioMessage(
        soundPath, null, null, duration * 1000);
    if (!created.isSuccess || created.data == null) {
      throw ImException(
          code: created.code, desc: created.errorDetails ?? 'createAudio 失败');
    }
    return _send(userId, created.data!);
  }

  @override
  Future<ImMessage> sendFileMessage({
    required String userId,
    required String filePath,
    String? fileName,
    int? fileSize,
  }) async {
    final created =
        await MessageCreator.createFileMessage(filePath, fileName, null);
    if (!created.isSuccess || created.data == null) {
      throw ImException(
          code: created.code, desc: created.errorDetails ?? 'createFile 失败');
    }
    return _send(userId, created.data!);
  }

  @override
  Future<ImMessage> sendCustomMessage({
    required String userId,
    required String customJson,
  }) async {
    // NIM 自定义消息：text 为短标签（可空），rawAttachment 为卡片 JSON。
    final created = await MessageCreator.createCustomMessage('', customJson);
    if (!created.isSuccess || created.data == null) {
      throw ImException(
          code: created.code, desc: created.errorDetails ?? 'createCustom 失败');
    }
    final message = created.data!;
    // V2NIMMessageConfig 各开关文档默认均为 NO。createCustomMessage 若不显式打开
    // unreadEnabled，对端会话 unreadCount 不增加 → 咨询师工作台消息 Tab / 会话行
    // 角标均为 0。须与历史/漫游/离线/会话更新一并打开，保证卡片与文本一致计入未读。
    final messageConfig = NIMMessageConfig(
      unreadEnabled: true,
      historyEnabled: true,
      roamingEnabled: true,
      offlineEnabled: true,
      onlineSyncEnabled: true,
      lastMessageUpdateEnabled: true,
    );
    message.messageConfig = messageConfig;
    return _send(
      userId,
      message,
      params: NIMSendMessageParams(messageConfig: messageConfig),
    );
  }

  /// 统一发送入口：解析 C2C 会话 ID 后发送，成功则本地回显推入 newMessageStream。
  Future<ImMessage> _send(
    String userId,
    NIMMessage message, {
    NIMSendMessageParams? params,
  }) async {
    final cid = await _p2pCid(userId);
    if (cid.isEmpty) {
      throw const ImException(code: -1, desc: '会话 ID 解析失败');
    }
    final res = await NimCore.instance.messageService.sendMessage(
      message: message,
      conversationId: cid,
      params: params,
    );
    if (!res.isSuccess || res.data?.message == null) {
      ImMessage? failed;
      if (res.data?.message != null) {
        failed = _toImMessage(res.data!.message!).copyWith(
          sendStatus: ImMessageSendStatus.failed,
        );
      }
      throw ImException(
        code: res.code,
        desc: res.errorDetails ?? '发送失败',
        failedMessage: failed,
      );
    }
    final sent = _toImMessage(res.data!.message!);
    // 本地回显：发送成功不触发 onReceiveMessages，需主动推给聊天页。
    if (!_newMessageController.isClosed) _newMessageController.add(sent);
    return sent;
  }

  @override
  Future<String?> resolveSoundPlayablePath(ImMessage message) async {
    final local = _normalizeLocalPath(message.soundPath);
    if (local != null && await File(local).exists()) return local;
    if (message.soundUrl != null && message.soundUrl!.isNotEmpty) {
      return message.soundUrl;
    }
    final att = _msgCache[message.msgId]?.attachment;
    if (att is! NIMMessageAudioAttachment) return null;
    return _downloadAttachmentPath(
        att, NIMDownloadAttachmentType.nimDownloadAttachmentTypeSource);
  }

  @override
  Future<String?> resolveImageDisplaySource(ImMessage message) async {
    final immediate = _immediateImageSource(message);
    if (immediate != null) return immediate;
    final att = _msgCache[message.msgId]?.attachment;
    if (att is! NIMMessageImageAttachment) return message.imageUrl;
    if (att.url != null && att.url!.isNotEmpty) return att.url;
    // 下载缩略图到缓存。
    return _downloadAttachmentPath(
        att, NIMDownloadAttachmentType.nimDownloadAttachmentTypeThumbnail);
  }

  @override
  Future<String?> resolveImagePreviewSource(ImMessage message) {
    final msgId = message.msgId;
    if (msgId.isNotEmpty) {
      final cached = _previewSourceCache[msgId];
      if (cached != null && cached.isNotEmpty) {
        return Future<String?>.value(cached);
      }
      final inflight = _previewSourceInflight[msgId];
      if (inflight != null) return inflight;
    }
    final future = _resolveImagePreviewSourceImpl(message).then((source) {
      if (msgId.isNotEmpty) {
        _previewSourceInflight.remove(msgId);
        if (source != null && source.isNotEmpty) {
          _previewSourceCache[msgId] = source;
        }
      }
      return source;
    });
    if (msgId.isNotEmpty) {
      _previewSourceInflight[msgId] = future;
    }
    return future;
  }

  Future<String?> _resolveImagePreviewSourceImpl(ImMessage message) async {
    // 本端本地原图（发送中/刚发出）。
    final localFull = _normalizeLocalPath(message.imagePath);
    if (localFull != null &&
        !localFull.startsWith('assets/') &&
        message.isSelf &&
        File(localFull).existsSync() &&
        _looksLikeFullImageFile(localFull)) {
      return localFull;
    }
    final att = _msgCache[message.msgId]?.attachment;
    if (att is NIMMessageImageAttachment) {
      // 网络大图优先（清晰且小于原图）。
      if (att.url != null && att.url!.isNotEmpty) return att.url;
      // 下载原图到本地。
      final p = await _downloadAttachmentPath(
          att, NIMDownloadAttachmentType.nimDownloadAttachmentTypeSource);
      if (p != null && p.isNotEmpty) return p;
    }
    if (localFull != null) {
      if (localFull.startsWith('assets/')) return localFull;
      if (File(localFull).existsSync()) return localFull;
    }
    return resolveImageDisplaySource(message);
  }

  /// 下载附件到默认缓存路径，返回本地路径（失败/超时返回 null）。
  Future<String?> _downloadAttachmentPath(
      NIMMessageFileAttachment att, NIMDownloadAttachmentType type) async {
    try {
      final res = await NimCore.instance.storageService.downloadAttachment(
        NIMDownloadMessageAttachmentParams(
          attachment: att,
          type: type,
          thumbSize: NIMSize(),
        ),
      );
      if (res.isSuccess && res.data != null && res.data!.isNotEmpty) {
        return res.data;
      }
    } catch (_) {}
    return null;
  }

  static bool _looksLikeFullImageFile(String path) {
    try {
      return File(path).lengthSync() >= 150 * 1024;
    } catch (_) {
      return false;
    }
  }

  /// 同步可展示源（本地文件 / https / assets），无需网络。
  static String? _immediateImageSource(ImMessage message) {
    final path = _normalizeLocalPath(message.imagePath);
    if (path != null) {
      if (path.startsWith('assets/')) return path;
      if (File(path).existsSync()) return path;
    }
    final url = message.imageUrl?.trim();
    if (url != null && url.isNotEmpty) return url;
    return null;
  }

  static String? _normalizeLocalPath(String? raw) {
    if (raw == null) return null;
    var path = raw.trim();
    if (path.isEmpty) return null;
    if (path.startsWith('file://')) {
      try {
        path = Uri.parse(path).toFilePath();
      } catch (_) {}
    }
    return path;
  }

  /// 解码本地图片像素尺寸（createImageMessage 需显式宽高；失败回退 0）。
  Future<(int, int)> _imageDimensions(String path) async {
    try {
      final bytes = await File(path).readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      return (frame.image.width, frame.image.height);
    } catch (_) {
      return (0, 0);
    }
  }

  @override
  Future<void> addToBlackList(String imUserId) async {
    if (kDebugMode) debugPrint('[NIMBlock] 拉黑 imUserId=$imUserId');
    final res = await NimCore.instance.userService.addUserToBlockList(imUserId);
    if (!res.isSuccess) {
      throw ImException(
          code: res.code,
          desc: res.errorDetails?.isNotEmpty == true
              ? res.errorDetails!
              : '拉黑失败');
    }
    await _refreshConversations();
  }

  @override
  Future<void> deleteC2CConversation(String imUserId) async {
    final cid = await _p2pCid(imUserId);
    if (cid.isEmpty) return;
    if (kDebugMode) debugPrint('[NIMBlock] 删除会话 cid=$cid');
    await NimCore.instance.localConversationService
        .deleteConversation(cid, true);
    await _refreshConversations();
  }

  @override
  Future<bool> isUserBlocked(String imUserId) async {
    final res = await NimCore.instance.userService.checkBlock([imUserId]);
    if (!res.isSuccess) return false;
    return res.data?[imUserId] ?? false;
  }

  @override
  Future<List<ImBlockedUser>> fetchBlackList() async {
    final res = await NimCore.instance.userService.getBlockList();
    if (!res.isSuccess) {
      throw ImException(
        code: res.code,
        desc: res.errorDetails?.isNotEmpty == true
            ? res.errorDetails!
            : '获取黑名单失败',
      );
    }
    final ids = res.data ?? const <String>[];
    if (ids.isEmpty) return const [];
    // getBlockList 仅返回 accid；昵称/头像需 getUserList 补全。
    final infoRes = await NimCore.instance.userService.getUserList(ids);
    final byId = <String, NIMUserInfo>{};
    for (final u in infoRes.data ?? const <NIMUserInfo>[]) {
      if (u.accountId != null) byId[u.accountId!] = u;
    }
    return [
      for (final id in ids)
        ImBlockedUser(
          userId: id,
          nickName: byId[id]?.name,
          faceUrl: byId[id]?.avatar,
        ),
    ];
  }

  @override
  Future<void> removeFromBlackList(String imUserId) async {
    if (kDebugMode) debugPrint('[NIMBlock] 解除拉黑 imUserId=$imUserId');
    final res =
        await NimCore.instance.userService.removeUserFromBlockList(imUserId);
    if (!res.isSuccess) {
      throw ImException(
        code: res.code,
        desc:
            res.errorDetails?.isNotEmpty == true ? res.errorDetails! : '解除拉黑失败',
      );
    }
    await _refreshConversations();
  }

  @override
  Future<void> dispose() async {
    _refreshDebounce?.cancel();
    await _kickedSub?.cancel();
    await _convCreatedSub?.cancel();
    await _convChangedSub?.cancel();
    await _convDeletedSub?.cancel();
    await _unreadSub?.cancel();
    await _recvSub?.cancel();
    await _localSyncFinishedSub?.cancel();
    await _userProfileSub?.cancel();
    await _conversationController.close();
    await _unreadController.close();
    await _newMessageController.close();
  }

  // ---------------- 内部 ----------------

  /// 被踢下线：任意原因 → onKickedOffline；server 踢（鉴权失效近似）→ 节流后 onUserSigExpired。
  void _handleKickedOffline(NIMKickedOfflineDetail detail) {
    debugPrint(
        '🔴 [NIM] 被踢下线 reason=${detail.reason} desc=${detail.reasonDesc}');
    _loggedIn = false;
    if (detail.reason == NIMKickedOfflineReason.kickedOfflineReasonServer) {
      final now = DateTime.now();
      final last = _lastUserSigExpiredAt;
      if (last == null || now.difference(last) >= _userSigExpiredThrottle) {
        _lastUserSigExpiredAt = now;
        onUserSigExpired?.call();
      }
    }
    onKickedOffline?.call();
  }

  Future<void> _refreshConversations() async {
    final list = await fetchConversations();
    if (!_conversationController.isClosed) {
      _conversationController.add(list);
    }
  }

  /// 合并同帧内多次会话/未读/收消息事件，避免连续 getConversationList。
  void _scheduleRefreshConversations() {
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(const Duration(milliseconds: 80), () {
      _refreshConversations();
    });
  }

  /// app 约定 `c2c_<userId>` → 解析为 NIM 会话 ID；否则视为已是 NIM cid 直用。
  Future<String> _resolveConversationId(String input) async {
    if (input.startsWith('c2c_')) {
      return _p2pCid(input.substring(4));
    }
    return input;
  }

  Future<String> _p2pCid(String userId) async {
    if (userId.isEmpty) return '';
    final cached = _cidCache[userId];
    if (cached != null && cached.isNotEmpty) return cached;
    final res =
        await NimCore.instance.conversationIdUtil.p2pConversationId(userId);
    final cid = res.data ?? '';
    if (cid.isNotEmpty) _cidCache[userId] = cid;
    return cid;
  }

  /// NIMConversation → 本层模型。
  ///
  /// [peer] 为对端网易云信用户资料（fetchConversations 对 name 缺失的会话主动拉取），
  /// 仅在 SDK 尚未把昵称/头像同步进会话本身时用作兜底。
  ImConversation _toImConversation(NIMConversation c, String peerUserId,
      [NIMUserInfo? peer]) {
    final lastIm =
        c.lastMessage == null ? null : _lastMessageToIm(c.lastMessage!);
    // 真实昵称来源：会话自带 name，或 getUserList 拉到的对端昵称。
    // 注意：SDK 未拿到对端昵称时可能把 name 填成对端 accid 本身，须排除（不算真名）。
    final cName = c.name;
    final peerName = peer?.name;
    final bool cNameValid =
        cName != null && cName.isNotEmpty && cName != peerUserId;
    final String? name = cNameValid
        ? cName
        : ((peerName != null && peerName.isNotEmpty) ? peerName : null);
    final String? avatar = (c.avatar != null && c.avatar!.isNotEmpty)
        ? c.avatar
        : peer?.avatar;
    return ImConversation(
      conversationId: c.conversationId,
      type: (c.type == NIMConversationType.team ||
              c.type == NIMConversationType.superTeam)
          ? ImConversationType.group
          : ImConversationType.c2c,
      userId: peerUserId.isNotEmpty ? peerUserId : (name ?? ''),
      showName: (name == null || name.isEmpty) ? peerUserId : name,
      faceUrl: (avatar == null || avatar.isEmpty) ? null : avatar,
      lastMessagePreview: previewOfMessage(lastIm),
      unreadCount: c.unreadCount ?? 0,
      timestamp: lastIm?.timestamp ??
          (c.updateTime > 0
              ? DateTime.fromMillisecondsSinceEpoch(c.updateTime)
              : null),
      lastMessageIsSelfMiddle: lastIm != null && isSelfMiddleCardMessage(lastIm),
    );
  }

  /// NIMLastMessage（会话摘要用）→ 本层模型（仅预览所需字段）。
  ImMessage _lastMessageToIm(NIMLastMessage lm) {
    final sender = lm.messageRefer?.senderId;
    return ImMessage(
      msgId: lm.messageRefer?.messageClientId ?? '',
      senderId: sender,
      kind: _kindFromType(lm.messageType, lm.attachment),
      text: lm.text,
      // 与历史消息映射对齐：自定义卡 JSON 在 attachment.raw，缺失则预览退化为 [通知]。
      customJson: lm.messageType == NIMMessageType.custom
          ? lm.attachment?.raw
          : null,
      timestamp: lm.messageRefer?.createTime == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(lm.messageRefer!.createTime!),
      isSelf: sender != null && sender.isNotEmpty && sender == _userId,
    );
  }

  /// NIMMessage → 本层模型，并缓存原始消息（供重发 / 附件下载）。
  ImMessage _toImMessage(NIMMessage m) {
    final id = m.messageClientId ?? '';
    if (id.isNotEmpty) _msgCache[id] = m;
    if (kDebugMode) {
      // 诊断：自定义卡 attachment.raw + 是否计入未读（unreadEnabled）。
      debugPrint('🌐 [NIM recv] type=${m.messageType} self=${m.isSelf} '
          'sender=${m.senderId} unreadEnabled=${m.messageConfig?.unreadEnabled} '
          'text=${m.text} '
          'attType=${m.attachment?.runtimeType} '
          'attRaw=${m.attachment?.raw == null ? "<null>" : (m.attachment!.raw!.length > 120 ? "${m.attachment!.raw!.substring(0, 120)}…" : m.attachment!.raw)}');
    }
    final imgAtt = m.attachment is NIMMessageImageAttachment
        ? m.attachment as NIMMessageImageAttachment
        : null;
    final sndAtt = m.attachment is NIMMessageAudioAttachment
        ? m.attachment as NIMMessageAudioAttachment
        : null;
    final fileAtt = m.attachment is NIMMessageFileAttachment
        ? m.attachment as NIMMessageFileAttachment
        : null;
    return ImMessage(
      msgId: id,
      senderId: m.senderId,
      kind: _messageKind(m),
      text: m.text,
      // 自定义卡片 JSON 走 attachment.raw（V2 无 data 字段）。
      customJson:
          m.messageType == NIMMessageType.custom ? m.attachment?.raw : null,
      timestamp: m.createTime == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(m.createTime!),
      isSelf: m.isSelf ?? false,
      // C2C 对端：自发的取 receiverId，收到的取 senderId。
      peerId: (m.isSelf ?? false) ? m.receiverId : m.senderId,
      imagePath: _normalizeLocalPath(imgAtt?.path),
      imageUrl: imgAtt?.url,
      imageUuid: imgAtt?.md5,
      imageWidth: imgAtt?.width,
      imageHeight: imgAtt?.height,
      soundPath: _normalizeLocalPath(sndAtt?.path),
      soundUuid: sndAtt?.md5,
      soundUrl: sndAtt?.url,
      soundDuration:
          sndAtt?.duration == null ? null : sndAtt!.duration! ~/ 1000,
      filePath: _normalizeLocalPath(fileAtt?.path),
      fileName: fileAtt?.name,
      fileSize: fileAtt?.size,
      fileUrl: fileAtt?.url,
      sendStatus: _sendStatus(m.sendingState),
    );
  }

  ImMessageKind _messageKind(NIMMessage m) =>
      _kindFromType(m.messageType, m.attachment);

  ImMessageKind _kindFromType(
      NIMMessageType? type, NIMMessageAttachment? attachment) {
    switch (type) {
      case NIMMessageType.text:
        return ImMessageKind.text;
      case NIMMessageType.custom:
        return ImMessageKind.custom;
      case NIMMessageType.image:
        return ImMessageKind.image;
      case NIMMessageType.audio:
        return ImMessageKind.sound;
      case NIMMessageType.video:
        return ImMessageKind.video;
      case NIMMessageType.file:
        return ImMessageKind.file;
      default:
        if (attachment is NIMMessageImageAttachment) return ImMessageKind.image;
        if (attachment is NIMMessageAudioAttachment) return ImMessageKind.sound;
        return ImMessageKind.other;
    }
  }

  ImMessageSendStatus _sendStatus(NIMMessageSendingState? s) {
    switch (s) {
      case NIMMessageSendingState.sending:
        return ImMessageSendStatus.sending;
      case NIMMessageSendingState.failed:
        return ImMessageSendStatus.failed;
      default:
        return ImMessageSendStatus.sent;
    }
  }
}
