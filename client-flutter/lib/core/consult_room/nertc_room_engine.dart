import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:nertc_core/nertc_core.dart';

import 'consult_room_service.dart';

/// 网易云信 NERtc 咨询室引擎封装（1v1 语音/视频咨询）。
///
/// 持有 NERtc 引擎生命周期与会话状态，作为 [ChangeNotifier] 供咨询室页面监听重建。
/// 引擎由 [ConsultRoomService] 在会话级持有（最小化悬浮时仅 pop 页面，引擎与会话保留，
/// 恢复时重新 push 页面即可重连渲染），避免通话因页面切换中断。
///
/// 关键约定（ADR-0006）：
/// - channelName = `xy_room_{orderId}`，进后端 mode=2 持久房；
/// - 安全模式下 uid/token 由业务服务端签发并回传（uid = 服务端从登录身份推导，
///   防冒充 + 规避 Dart/Java hashCode 不一致），客户端须原样用于 joinChannel；
///   调试模式（无服务端 token）回退本地 uid = accid.hashCode() & 0x7fffffff；
/// - 1v1 模式（mode1v1Enabled）+ AI 降噪（audioAINSEnabled）+ 语音场景；
/// - token 过期不踢已进房用户，故单 token 覆盖整场会话即可。
///
/// ⚠️ 本环境无设备/无真实 NERtc 房间，仅静态类型校验；真机需联调视频/音频/字幕。
class NertcRoomEngine extends ChangeNotifier {
  NertcRoomEngine({
    required this.appKey,
    this.orderId,
    this.captionUploader,
    this.onPeerLeft,
    this.onError,
  });

  /// NERtc 应用 AppKey（与 IM 同一网易云信应用，控制台分配；非密钥）。
  final String appKey;

  /// 当前订单号（字幕上报打标用；为空则仅本地缓冲、不上报）。
  final String? orderId;

  /// 字幕批量上报回调（上层注入 Node 客户端；为空则仅本地缓冲、不上报）。
  final CaptionUploader? captionUploader;

  /// 对端离开/断线/被踢 → 业务层收尾（pop 咨询室页）。
  final void Function(int reason)? onPeerLeft;

  /// 引擎/进房错误（非致命可忽略的 warning 不触发）。
  final void Function(int code, String? msg)? onError;

  final _RoomCallback _cb = _RoomCallback();

  bool _engineCreated = false;
  bool _joining = false;
  bool _joined = false;
  ConsultRoomMediaType? _mediaType;

  int? _remoteUid;
  bool _remoteVideo = false;
  /// 远端是否曾发布过视频（曾发布后停止 = 对端关了摄像头；从未发布 = 连接中）。
  /// 配合 toggleCamera 用 enableLocalVideo（关采集→对端收 onUserVideoStop），
  /// 让 UI 能区分「连接中」与「对方已关闭摄像头」两种无视频状态。
  bool _remoteVideoEverStarted = false;

  bool _micMuted = false;
  bool _camOff = false; // 仅视频模式有意义
  bool _speakerOn = true;
  /// 大小画面是否已切换（true=本端大/对端小）。会话级状态，最小化悬浮窗据此
  /// 决定右上小窗显示自己还是对方。全屏页点小窗时由 toggleSwap 翻转。
  bool _swapped = false;
  /// 通话已建立时长（秒）。对端加入后开始计时，每秒 +1 并通知 UI 刷新。
  int _callSeconds = 0;
  Timer? _callTimer;

  int _localVolume = 0;
  int _remoteVolume = 0;

  /// 最近字幕（旧→新；UI 取末尾若干条）。
  final List<String> _captions = <String>[];

  // ---------------- 字幕上报缓冲 ----------------
  /// 字幕功能总开关（默认开启）。开：启动 ASR、采集并经 Java 网关上报到归档服务（**不依赖打包参数**）。
  /// 关：不启动 ASR、不采集、不上报。浮层是否展示另见 consult_room_page 的 _showCaptionsOverlay。
  static const bool enableCaptions = true;

  /// 待上报字幕（ASR 回调频繁含中间结果，缓冲后批量上报，避免逐条 HTTP）。
  final List<CaptionItem> _captionBuffer = <CaptionItem>[];
  /// 定时 flush 上报（进房成功起、离房停 + 收尾 flush）。
  Timer? _captionFlushTimer;
  /// 本端进房 uid（start() 里确定，字幕批次打标用）。
  int? _uid;
  /// 本端 IM accid（标说话人：isLocalUser=true 的字幕归它）。
  String? _localAccid;
  /// 对端 IM accid（标说话人：isLocalUser=false 的字幕归它）。
  String? _peerAccid;

  // ---------------- 对外状态 ----------------

  bool get isJoining => _joining;
  bool get isJoined => _joined;
  ConsultRoomMediaType? get mediaType => _mediaType;

  /// 对端 uid（已加入则有值）。
  int? get remoteUid => _remoteUid;

  /// 对端是否已发布视频流（视频咨询下用于切换大画面）。
  bool get remoteVideoActive => _remoteVideo;

  /// 对端是否曾发布过视频。用于 UI 区分「连接中」（未发过）与
  /// 「对方已关闭摄像头」（发过又停）。
  bool get remoteVideoEverStarted => _remoteVideoEverStarted;

  bool get micMuted => _micMuted;
  bool get camOff => _camOff;

  /// 大小画面是否已切换（true=本端大/对端小）。
  bool get swapped => _swapped;
  /// 通话已建立时长（秒）。对端加入后开始计时。
  int get callSeconds => _callSeconds;
  bool get speakerOn => _speakerOn;
  int get localVolume => _localVolume;
  int get remoteVolume => _remoteVolume;
  List<String> get captions => List.unmodifiable(_captions);

  // ---------------- 生命周期 ----------------

  /// 创建引擎（幂等）+ 进房。返回 NERtc 结果码（0=成功）。
  Future<int> start({
    required ConsultRoomParams params,
    required String localImUserId,
    String? token,
    int? uid,
  }) async {
    _mediaType = params.mediaType;
    _joining = true;
    notifyListeners();

    final engine = NERtcEngine.instance;
    int code = NERtcErrorCode.ok;
    if (!_engineCreated) {
      _cb._engine = this;
      code = await engine.create(
        appKey: appKey,
        channelEventCallback: _cb,
        options: NERtcOptions(
          audioAINSEnabled: true, // AI 降噪
          mode1v1Enabled: true, // 1v1 咨询房
          // 强制 IPv4：SDK 默认会尝试 IPv6 信令/媒体地址，IPv4-only 网络
          //（本机这台 WiFi：ping6 NERtc 服务器 No route to host）下进房会黑屏。
          // 显式传 serverAddresses(valid=true) + useIPv6:false 让 SDK 只走 IPv4；
          // 其余服务器字段留空 = 沿用 SDK 默认地址。
          serverAddresses: NERtcServerAddresses(useIPv6: false),
        ),
      );
      if (code != NERtcErrorCode.ok) {
        _joining = false;
        notifyListeners();
        return code;
      }
      _engineCreated = true;
    }

    // 语音场景：流畅优先
    await engine.setAudioProfile(
      NERtcAudioProfile.profileMiddleQuality,
      NERtcAudioScenario.scenarioSpeech,
    );
    await engine.enableLocalAudio(true);
    // 说话音量指示（驱动波形/活跃态），300ms 间隔
    try {
      await engine.enableAudioVolumeIndication(true, 300, vad: true);
    } catch (_) {}
    if (params.mediaType == ConsultRoomMediaType.video) {
      await engine.enableLocalVideo(true);
      debugPrint('🟢 [NERtc] enableLocalVideo(true) 已开启（视频模式，本端发布视频）');
    }

    // 云端录制（合流）：joinChannel 前在 NERtcParameters 配置，进房后服务端自动开录、离房停录。
    // 需网易云信控制台开通「云端录制」并配好合流布局；失败静默，不阻断通话。
    try {
      final recordParams = NERtcParameters();
      recordParams.setParameter(
          NERtcParameters.KEY_SERVER_RECORD_AUDIO, true); // 语音/视频咨询均录音频
      recordParams.setParameter(NERtcParameters.KEY_SERVER_RECORD_VIDEO,
          params.mediaType == ConsultRoomMediaType.video); // 仅视频咨询录视频
      recordParams.setParameter(
          NERtcParameters.KEY_SERVER_RECORD_MODE, ServerRecordMode.mix); // 合流
      final rc = await engine.setParameters(recordParams);
      debugPrint('🎥 [NERtc] setParameters(云端录制) code=$rc '
          'audio=true video=${params.mediaType == ConsultRoomMediaType.video} mode=mix');
    } catch (e) {
      debugPrint('🟠 [NERtc] setParameters(云端录制) 失败：$e');
    }

    // uid 优先用服务端安全模式回传值（与 token 配对，须完全一致）；
    // 无服务端 uid（调试模式）时回退本地推导。
    final effectiveUid = uid ?? (localImUserId.hashCode & 0x7fffffff);
    _localAccid = localImUserId;
    _peerAccid = params.imUserId;
    final channelName = 'xy_room_${params.orderId}';
    debugPrint('🌐 [NERtc] joinChannel channel=$channelName uid=$effectiveUid '
        'uidSrc=${uid == null ? "local" : "server"} '
        'token=${token == null ? "<null>" : "set(${token.length})"} media=${params.mediaType} ipv6=false');
    code = await engine.joinChannel(token, channelName, effectiveUid, null);
    debugPrint('🌐 [NERtc] joinChannel result code=$code');

    _joining = false;
    if (code == NERtcErrorCode.ok) {
      _joined = true;
      _uid = effectiveUid;
      if (enableCaptions) {
        _startCaptionFlush();
        // 实时字幕（需网易云信控制台开通「实时字幕」；失败静默，不阻断通话）
        try {
          await engine.startASRCaption(
            NERtcASRCaptionConfig(srcLanguage: 'AUTO'),
          );
        } catch (_) {}
      }
    } else {
      onError?.call(code, 'joinChannel 失败');
    }
    notifyListeners();
    return code;
  }

  /// 离开房间（保留引擎，供再次进入或最小化后恢复）。
  Future<void> end() async {
    if (!_engineCreated) return;
    _stopCallTimer();
    _captionFlushTimer?.cancel();
    _captionFlushTimer = null;
    final engine = NERtcEngine.instance;
    try {
      await engine.stopASRCaption();
    } catch (_) {}
    await _flushCaptions(); // 收尾上报剩余字幕（best-effort）
    if (_joined) {
      try {
        await engine.leaveChannel();
      } catch (_) {}
      _joined = false;
    }
    _remoteUid = null;
    _remoteVideo = false;
    _captions.clear();
    _captionBuffer.clear();
    notifyListeners();
  }

  /// 销毁引擎（整个咨询室特性不再使用时调用）。
  Future<void> releaseEngine() async {
    await end();
    if (_engineCreated) {
      try {
        await NERtcEngine.instance.release();
      } catch (_) {}
      _engineCreated = false;
    }
  }

  // ---------------- 控制 ----------------

  Future<void> toggleMic() async {
    if (!_joined) return;
    _micMuted = !_micMuted;
    try {
      await NERtcEngine.instance.muteLocalAudioStream(_micMuted);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> toggleCamera() async {
    if (!_joined || _mediaType != ConsultRoomMediaType.video) return;
    _camOff = !_camOff;
    // 用 enableLocalVideo 而非 muteLocalVideoStream：真正关闭采集（摄像头灯灭、更保护隐私），
    // 且对端会收到 onUserVideoStop → 本端 remoteVideoActive=false → 切到「对方已关摄像头」占位。
    // muteLocalVideoStream 只发 onUserVideoMute、不禁用采集，对端画面会定格在最后一帧（旧 bug）。
    try {
      await NERtcEngine.instance.enableLocalVideo(!_camOff);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> toggleSpeaker() async {
    _speakerOn = !_speakerOn;
    try {
      await NERtcEngine.instance.deviceManager.setSpeakerphoneOn(_speakerOn);
    } catch (_) {}
    notifyListeners();
  }

  /// 切换大小画面（本端大 ↔ 对端大）。会话级，最小化悬浮窗复用同一状态。
  void toggleSwap() {
    _swapped = !_swapped;
    notifyListeners();
  }

  /// 开始计通话时长（对端加入、通话建立后调用）。每秒 +1 并通知监听者刷新 UI。
  void _startCallTimer() {
    _callTimer?.cancel();
    _callSeconds = 0;
    _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _callSeconds++;
      notifyListeners();
    });
  }

  /// 停止并归零通话时长。
  void _stopCallTimer() {
    _callTimer?.cancel();
    _callTimer = null;
    _callSeconds = 0;
  }

  // ---------------- 事件回调（由 _RoomCallback 反调） ----------------

  void _onUserJoined(int uid) {
    debugPrint('🟢 [NERtc] onUserJoined uid=$uid');
    _remoteUid = uid;
    _startCallTimer();
    notifyListeners();
  }

  Future<void> _onUserVideoStart(int uid) async {
    debugPrint('🟢 [NERtc] onUserVideoStart uid=$uid（对端发布视频，开始订阅）');
    _remoteUid = uid;
    _remoteVideo = true;
    _remoteVideoEverStarted = true;
    notifyListeners();
    // 远端视频需显式订阅（默认不自动订阅）
    try {
      await NERtcEngine.instance
          .subscribeRemoteVideoStream(uid, NERtcRemoteVideoStreamType.high, true);
      debugPrint('🟢 [NERtc] subscribeRemoteVideoStream OK uid=$uid');
    } catch (e) {
      debugPrint('🔴 [NERtc] subscribeRemoteVideoStream 失败 uid=$uid err=$e');
    }
  }

  void _onUserVideoStop(int uid) {
    debugPrint('🟡 [NERtc] onUserVideoStop uid=$uid');
    _remoteVideo = false;
    notifyListeners();
  }

  void _onUserLeave(int uid, int reason) {
    _remoteUid = null;
    _remoteVideo = false;
    _remoteVideoEverStarted = false;
    _stopCallTimer();
    notifyListeners();
    onPeerLeft?.call(reason);
  }

  void _onDisconnect(int reason) {
    onPeerLeft?.call(reason);
  }

  void _onLocalVolume(int volume) {
    _localVolume = volume;
    notifyListeners();
  }

  void _onRemoteVolume(int volume) {
    _remoteVolume = volume;
    notifyListeners();
  }

  void _onCaption(List<Map<Object?, Object?>?> result) {
    if (result.isEmpty) return;
    // 每条 ASR 结果含 content + 说话人(uid/isLocalUser) + isFinal + timestamp（见 NERtcAsrCaptionResult）
    for (final m in result) {
      if (m == null) continue;
      final text = _readString(m, 'content') ??
          _readString(m, 'text') ??
          _readString(m, 'translateContent');
      if (text == null || text.isEmpty) continue;
      _captions.add(text); // UI 用（含中间结果；浮层默认隐藏）
      if (_captions.length > 50) _captions.removeAt(0);

      // 只上报定稿结果（isFinal 缺失按定稿处理，避免丢字幕）；中间结果仅刷新 UI、不上报
      final isFinal = (m['isFinal'] as bool?) ?? true;
      if (!isFinal) continue;

      // 说话人：isLocalUser=true→本端 accid，否则对端 accid（isLocalUser 缺失时按 uid 比对）
      final isLocal = (m['isLocalUser'] as bool?) ??
          ((m['uid'] as num?)?.toInt() == _uid);
      final speakerAccid = isLocal ? (_localAccid ?? '') : (_peerAccid ?? '');
      final ts = (m['timestamp'] as num?)?.toInt() ??
          DateTime.now().millisecondsSinceEpoch;
      _captionBuffer.add(CaptionItem(
        text: text,
        ts: ts,
        speakerAccid: speakerAccid,
        isFinal: isFinal,
      ));
    }
    notifyListeners();
  }

  static String? _readString(Map<Object?, Object?> m, String key) {
    final v = m[key];
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  // ---------------- 字幕批量上报 ----------------
  static const Duration _captionFlushInterval = Duration(seconds: 5);

  /// 进房成功后起定时 flush（离房 end() 里 cancel + 收尾 flush）。
  void _startCaptionFlush() {
    _captionFlushTimer?.cancel();
    _captionFlushTimer =
        Timer.periodic(_captionFlushInterval, (_) => _flushCaptions());
  }

  /// 取缓冲快照上报（best-effort：失败吞掉记日志，不阻断通话/字幕展示）。
  /// 未配置 orderId/uploader 时仅清空缓冲。
  Future<void> _flushCaptions() async {
    final uploader = captionUploader;
    final oid = orderId;
    if (uploader == null || oid == null || oid.isEmpty) {
      _captionBuffer.clear();
      return;
    }
    if (_captionBuffer.isEmpty) return;
    final batch = CaptionBatch(
      orderId: oid,
      channelName: 'xy_room_$oid',
      uid: _uid ?? 0,
      captions: List<CaptionItem>.from(_captionBuffer),
    );
    _captionBuffer.clear();
    try {
      await uploader(batch);
    } catch (e) {
      debugPrint('🟠 [NERtc] 字幕上报失败：$e');
    }
  }
}

/// 一条字幕（文本 + 采集时间戳毫秒 + 说话人 accid + 是否定稿）。
class CaptionItem {
  const CaptionItem({
    required this.text,
    required this.ts,
    this.speakerAccid = '',
    this.isFinal = true,
  });
  final String text;
  final int ts;
  /// 说话人 IM accid（xy_{userId} / cst_{consultantId}）；空 = 未能判定。
  final String speakerAccid;
  final bool isFinal;
  Map<String, dynamic> toJson() => {
        'text': text,
        'ts': ts,
        'speakerAccid': speakerAccid,
        'isFinal': isFinal,
      };
}

/// 字幕上报批次：附订单/频道/uid 打标，批量 POST 到 Node `/nertc/caption`。
class CaptionBatch {
  const CaptionBatch({
    required this.orderId,
    required this.channelName,
    required this.uid,
    required this.captions,
  });
  final String orderId;
  final String channelName;
  final int uid;
  final List<CaptionItem> captions;
  Map<String, dynamic> toJson() => {
        'orderId': orderId,
        'channelName': channelName,
        'uid': uid,
        'captions': captions.map((c) => c.toJson()).toList(),
      };
}

/// 字幕上报回调：引擎缓冲到点或离房收尾时调用，best-effort（失败由引擎吞掉记日志）。
typedef CaptionUploader = Future<void> Function(CaptionBatch batch);

/// NERtc 通道事件回调 → 转发到 [NertcRoomEngine]。
class _RoomCallback extends NERtcChannelEventCallback {
  NertcRoomEngine? _engine;

  @override
  void onUserJoined(int uid, NERtcUserJoinExtraInfo? joinExtraInfo) =>
      _engine?._onUserJoined(uid);

  @override
  void onUserVideoStart(int uid, int maxProfile) => _engine?._onUserVideoStart(uid);

  @override
  void onUserVideoStop(int uid) => _engine?._onUserVideoStop(uid);

  @override
  void onUserLeave(int uid, int reason, NERtcUserLeaveExtraInfo? leaveExtraInfo) =>
      _engine?._onUserLeave(uid, reason);

  @override
  void onDisconnect(int reason) => _engine?._onDisconnect(reason);

  @override
  void onLocalAudioVolumeIndication(int volume, bool vadFlag) =>
      _engine?._onLocalVolume(volume);

  @override
  void onRemoteAudioVolumeIndication(
          List<NERtcAudioVolumeInfo> volumeList, int totalVolume) =>
      _engine?._onRemoteVolume(
          volumeList.isEmpty ? 0 : (volumeList.first.volume ?? 0));

  @override
  void onAsrCaptionResult(List<Map<Object?, Object?>?> result, int resultCount) =>
      _engine?._onCaption(result);
}
