import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../app/navigation.dart';
import '../../features/order/order_api.dart';
import '../im/im_config.dart';
import '../storage/account_store.dart';
import 'consult_room_page.dart';
import 'nertc_room_engine.dart'
    if (dart.library.html) 'nertc_room_engine_web.dart';

/// 咨询室原生桥（路由契约 1006）Riverpod provider。
///
/// 使用 [ref.read] 取 AccountStore，避免 watch 导致登录态刷新时重建实例，
/// 从而丢掉进行中的会议会话态与 [ConsultRoomService.onOpenChat] 绑定。
final consultRoomServiceProvider = ChangeNotifierProvider<ConsultRoomService>(
  (ref) => ConsultRoomService(
    ref.read(accountStoreProvider),
    loginDataReader: () => ref.read(accountStoreProvider).read(),
    consultTokenReader: (orderId) =>
        ref.read(orderApiProvider).fetchConsultRoomToken(orderId),
    captionUploader: (batch) => ref.read(orderApiProvider).uploadConsultCaptions(
          orderId: batch.orderId,
          channelName: batch.channelName,
          uid: batch.uid,
          captions: batch.captions.map((c) => c.toJson()).toList(),
        ),
  ),
);

/// 咨询室媒体类型（语音/视频）。
/// iOS 参照：xinyuiOS XYChatModule/Classes/ConsultRoom/XYConsultRoomTypes.swift
/// 的 XYConsultMediaType（语音咨询只通话不画面，视频咨询双向画面）。
enum ConsultRoomMediaType {
  /// 语音咨询：仅音频，无视频画面（supportMode=2）
  voice,

  /// 视频咨询：双向音视频（supportMode=3）
  video;

  /// 由 supportMode 原始值解析：'3'/'video' → 视频，'2'/'voice' → 语音，
  /// 未知值兜底语音（与 iOS XYConsultMediaType.parse 一致）。
  /// 工作台传入的是枚举名（'voice'/'video'/'text'），同样兼容。
  static ConsultRoomMediaType parse(String? raw) {
    switch (raw?.toLowerCase()) {
      case '3':
      case 'video':
        return ConsultRoomMediaType.video;
      case '2':
      case 'voice':
      default:
        return ConsultRoomMediaType.voice;
    }
  }
}

/// 咨询室进房参数：对照路由契约 1006 全参数
/// （contracts/route_code_contract.md §1）。
class ConsultRoomParams {
  const ConsultRoomParams({
    this.orderId,
    this.supportMode,
    this.roomId,
    this.roomName,
    this.startTime,
    this.endTime,
    this.imUserId,
    this.userName,
    this.userAvatar,
  });

  final String? orderId;
  final String? supportMode;
  final String? roomId;
  final String? roomName;
  final String? startTime;
  final String? endTime;
  final String? imUserId;
  final String? userName;
  final String? userAvatar;

  ConsultRoomMediaType get mediaType => ConsultRoomMediaType.parse(supportMode);

  factory ConsultRoomParams.fromQuery(Map<String, String> query) {
    String? v(String key) {
      final raw = query[key];
      return (raw == null || raw.isEmpty) ? null : raw;
    }

    return ConsultRoomParams(
      orderId: v('orderId'),
      supportMode: v('supportMode'),
      roomId: v('roomId'),
      roomName: v('roomName'),
      startTime: v('startTime'),
      endTime: v('endTime'),
      imUserId: v('imUserId'),
      userName: v('userName'),
      // 兼容 avatar / counselorAvatar（卡片/订单深链多键）
      userAvatar: v('userAvatar') ?? v('avatar') ?? v('counselorAvatar'),
    );
  }

}

enum ConsultRoomEnterStatus {
  entered,
  invalidParams,
  permissionDenied,
  failed,
}

class ConsultRoomEnterResult {
  const ConsultRoomEnterResult(this.status, [this.message = '']);

  final ConsultRoomEnterStatus status;
  final String message;

  bool get ok => status == ConsultRoomEnterStatus.entered;
}

/// 咨询室服务（网易云信 NERtc：Flutter 全屏页 + 最小化悬浮窗）。
///
/// 进房 push 全屏 [ConsultRoomPage]；悬浮窗态再次进入 → [restoreRoom] 恢复全屏，不重复进房。
///
/// 继承 [ChangeNotifier]：最小化/会话状态变化时 [notifyListeners]，驱动根悬浮窗
/// （见 consult_room_float_widget.dart）显隐。
class ConsultRoomService extends ChangeNotifier {
  ConsultRoomService(
    AccountStore accountStore, {
    Future<bool> Function(ConsultRoomMediaType mediaType)? permissionRequester,
    Future<LoginData?> Function()? loginDataReader,
    Future<({String token, int uid})?> Function(String orderId)?
        consultTokenReader,
    CaptionUploader? captionUploader,
  })  : _permissionRequester = permissionRequester ?? _requestPermissions,
        _loginDataReader = loginDataReader ?? accountStore.read,
        _consultTokenReader = consultTokenReader ?? ((_) async => null),
        _captionUploader = captionUploader;

  /// 当前进房会话参数（会议最小化期间仍保留；会话结束后清空）。
  ConsultRoomParams? activeParams;

  /// 是否已有进行中的咨询室会话（含悬浮窗态）。
  bool get isSessionActive => _sessionActive;

  /// 会议是否已最小化为悬浮窗。
  bool get isMinimized => _minimized;

  bool _sessionActive = false;
  bool _minimized = false;

  /// NERtc 引擎（仅网易云信模式持有；会话级，最小化时保留、恢复时复用）。
  NertcRoomEngine? _nertcEngine;

  /// 暴露引擎给悬浮窗渲染视频（remoteUid/mediaType/连接态等）。
  /// 仅在会话进行中（isSessionActive）非空。
  NertcRoomEngine? get nertcEngine => _nertcEngine;

  /// 最小化回调（保留字段）：网易云信 Flutter 路径下，悬浮窗可见性由 [notifyListeners]
  /// 驱动（见 consult_room_float_widget.dart），本回调在 app 层不再接线；保留以兼容
  /// 未来可能的 native 悬浮窗扩展。
  VoidCallback? onMinimized;

  /// 原生「聊天」：打开 Flutter IM（App 级全局绑定）。
  void Function({
    required String imUserId,
    String? userName,
    String? userAvatar,
  })? onOpenChat;

  final Future<bool> Function(ConsultRoomMediaType mediaType)
      _permissionRequester;
  final Future<LoginData?> Function() _loginDataReader;
  final Future<({String token, int uid})?> Function(String) _consultTokenReader;
  /// 字幕批量上报回调（经 Java 网关转发至归档服务）；为空则不采集上报。
  final CaptionUploader? _captionUploader;

  /// 有悬浮窗则恢复全屏；否则 present 进入咨询室。
  ///
  /// UI 层应调用本方法，且 **不要** push 可见的 /consult-room 页。
  Future<ConsultRoomEnterResult> presentOrRestore(
      ConsultRoomParams params) async {
    if (_sessionActive) {
      if (_minimized) {
        return restoreRoom();
      }
      // 已在全屏会议中：忽略重复点击
      return const ConsultRoomEnterResult(ConsultRoomEnterStatus.entered);
    }
    return enterRoom(params);
  }

  /// 从悬浮窗恢复全屏会议（原生 present，无 Flutter push）。
  Future<ConsultRoomEnterResult> restoreRoom() async {
    if (!_sessionActive) {
      return const ConsultRoomEnterResult(
        ConsultRoomEnterStatus.failed,
        '咨询室已结束',
      );
    }
    return _restoreNertc();
  }

  /// 进入咨询室（语音/视频）。原生 present；await 直到会议结束/失败。
  Future<ConsultRoomEnterResult> enterRoom(ConsultRoomParams params) async {
    if ((params.orderId ?? '').isEmpty) {
      return const ConsultRoomEnterResult(
        ConsultRoomEnterStatus.invalidParams,
        '订单信息缺失，无法进入咨询室',
      );
    }
    if ((params.roomId ?? '').isEmpty) {
      return const ConsultRoomEnterResult(
        ConsultRoomEnterStatus.invalidParams,
        '咨询室信息缺失，无法进入',
      );
    }

    final granted = await _permissionRequester(params.mediaType);
    if (!granted) {
      return ConsultRoomEnterResult(
        ConsultRoomEnterStatus.permissionDenied,
        params.mediaType == ConsultRoomMediaType.video
            ? '请先在系统设置中开启麦克风与摄像头权限'
            : '请先在系统设置中开启麦克风权限',
      );
    }

    final loginData = await _loginDataReader();
    final imUserSig = loginData?.imUserSig;
    final loginImUserId = loginData?.imUserId;
    if (loginImUserId == null ||
        loginImUserId.isEmpty ||
        imUserSig == null ||
        imUserSig.isEmpty) {
      return const ConsultRoomEnterResult(
        ConsultRoomEnterStatus.failed,
        'IM 未登录，请重新登录后再试',
      );
    }

    activeParams = params;
    _sessionActive = true;
    _minimized = false;
    notifyListeners();

    // 网易云信 NERtc 咨询室：进房 + push 全屏页
    return _enterNertc(params, loginData!);
  }

  // ============================================================
  // 网易云信 NERtc 咨询室（Flutter）
  // ============================================================

  Future<ConsultRoomEnterResult> _enterNertc(
      ConsultRoomParams params, LoginData login) async {
    final engine = NertcRoomEngine(
      appKey: ImConfig.neteaseAppKey,
      orderId: params.orderId,
      captionUploader: _captionUploader,
      onPeerLeft: (reason) => _onNertcPeerLeft(),
      onError: (code, msg) =>
          debugPrint('🌐 [NERtc] onError code=$code msg=$msg'),
    );
    _nertcEngine = engine;

    // 安全模式：进房前向业务服务端申请 NERTC Token（uid 由服务端推导，回传后须原样用于 joinChannel）。
    // 取不到（如调试模式 / 后端未就绪）则回退空 token + 本地 uid，保证调试链路不被阻断。
    String? token;
    int? uid;
    final orderId = params.orderId;
    if (orderId != null && orderId.isNotEmpty) {
      try {
        final t = await _consultTokenReader(orderId);
        token = t?.token;
        uid = t?.uid;
      } catch (e) {
        debugPrint('🟠 [ConsultRoom] 获取 NERTC Token 失败，回退空 token：$e');
      }
    }
    final code = await engine.start(
      params: params,
      localImUserId: login.imUserId!,
      token: token,
      uid: uid,
    );
    if (code != 0) {
      await engine.releaseEngine();
      _nertcEngine = null;
      _sessionActive = false;
      _minimized = false;
      activeParams = null;
      notifyListeners();
      return ConsultRoomEnterResult(
        ConsultRoomEnterStatus.failed,
        _nertcErrMsg(code),
      );
    }
    await _pushNertcPage(params, engine);
    // 页面关闭：最小化则保留会话（引擎仍在线）；否则结束
    if (_minimized) {
      return const ConsultRoomEnterResult(ConsultRoomEnterStatus.entered);
    }
    await _teardownNertc();
    return const ConsultRoomEnterResult(ConsultRoomEnterStatus.entered);
  }

  Future<ConsultRoomEnterResult> _restoreNertc() async {
    final engine = _nertcEngine;
    final params = activeParams;
    if (engine == null || params == null) {
      return const ConsultRoomEnterResult(
        ConsultRoomEnterStatus.failed,
        '咨询室已结束',
      );
    }
    // 先置 _minimized=false 并通知：让悬浮窗子树（含其 NERtcVideoView）先离开树、
    // dispose 掉 renderer，再由页面重新 attach，避免两视图同时挂同 uid 的短暂重叠。
    _minimized = false;
    notifyListeners();
    await _pushNertcPage(params, engine);
    if (_minimized) {
      return const ConsultRoomEnterResult(ConsultRoomEnterStatus.entered);
    }
    await _teardownNertc();
    return const ConsultRoomEnterResult(ConsultRoomEnterStatus.entered);
  }

  Future<void> _pushNertcPage(
      ConsultRoomParams params, NertcRoomEngine engine) async {
    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null) {
      debugPrint('🔴 [ConsultRoom] rootNavigator context 为空，无法 push 咨询室页');
      return;
    }
    await Navigator.of(ctx, rootNavigator: true).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => ConsultRoomPage(
          engine: engine,
          params: params,
          onLeave: () async {
            _minimized = false;
            await engine.end();
            _popNertcPage();
          },
          onMinimize: () {
            _minimized = true;
            notifyListeners();
            onMinimized?.call();
            _popNertcPage();
          },
          // 会议内「聊天」：隐含最小化（与原生桥一致），再打开对端 IM 会话
          onOpenChat: () {
            _minimized = true;
            notifyListeners();
            onMinimized?.call();
            _popNertcPage();
            final peerId = params.imUserId ?? '';
            if (peerId.isNotEmpty) {
              onOpenChat?.call(
                imUserId: peerId,
                userName: params.userName,
                userAvatar: params.userAvatar,
              );
            }
          },
        ),
      ),
    );
  }

  void _popNertcPage() {
    final ctx = rootNavigatorKey.currentContext;
    if (ctx != null) {
      Navigator.of(ctx, rootNavigator: true).maybePop();
    }
  }

  /// 对端离开/断线/被踢：收尾会话。
  ///
  /// 全屏态：咨询室页还在栈里 → 置非最小化后 pop，_enterNertc/_restoreNertc 收尾时自然 teardown。
  /// 最小化态：页面已不在栈（早被 pop）→ **必须这里主动 teardown**，否则会话残留
  /// （_sessionActive 仍 true、引擎不释放、悬浮窗消失却无法挂断 → 卡死）。
  void _onNertcPeerLeft() {
    if (_minimized) {
      _teardownNertc();
      return;
    }
    _minimized = false;
    notifyListeners();
    _popNertcPage();
  }

  Future<void> _teardownNertc() async {
    final engine = _nertcEngine;
    _nertcEngine = null;
    _sessionActive = false;
    _minimized = false;
    activeParams = null;
    // 先通知悬浮窗消失（其 NERtcVideoView dispose），再释放引擎。
    notifyListeners();
    if (engine != null) {
      await engine.releaseEngine();
    }
  }

  static String _nertcErrMsg(int code) {
    return '进入咨询室失败（code=$code），请稍后重试';
  }

  Future<void> exitRoom() async {
    // 最小化态下咨询室页已不在栈顶（被 pop 过），挂断只做 teardown + 通知悬浮窗消失，
    // 不能再 _popNertcPage —— 否则会误 pop 当前页（如聊天页）。
    // 仅全屏态（非最小化）才需 pop 咨询室页。
    final wasMinimized = _minimized;
    await _teardownNertc();
    if (!wasMinimized) {
      _popNertcPage();
    }
  }

  static Future<bool> _requestPermissions(
      ConsultRoomMediaType mediaType) async {
    final permissions = <Permission>[
      Permission.microphone,
      if (mediaType == ConsultRoomMediaType.video) Permission.camera,
    ];
    final statuses = await permissions.request();
    return statuses.values.every((s) => s.isGranted);
  }
}
