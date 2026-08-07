import 'dart:async';

import 'package:flutter/foundation.dart';

import 'consult_room_service.dart';

class CaptionItem {
  const CaptionItem({
    required this.text,
    required this.ts,
    this.speakerAccid = '',
    this.isFinal = true,
  });

  final String text;
  final int ts;
  final String speakerAccid;
  final bool isFinal;

  Map<String, dynamic> toJson() => {
        'text': text,
        'ts': ts,
        'speakerAccid': speakerAccid,
        'isFinal': isFinal,
      };
}

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
}

typedef CaptionUploader = Future<void> Function(CaptionBatch batch);

/// 浏览器原型引擎：只驱动咨询室 UI 状态，不访问麦克风、摄像头或 NERTC。
class NertcRoomEngine extends ChangeNotifier {
  NertcRoomEngine({
    required this.appKey,
    this.orderId,
    this.captionUploader,
    this.onPeerLeft,
    this.onError,
  });

  final String appKey;
  final String? orderId;
  final CaptionUploader? captionUploader;
  final void Function(int reason)? onPeerLeft;
  final void Function(int code, String? msg)? onError;

  ConsultRoomMediaType? _mediaType;
  int? _remoteUid;
  bool _joining = false;
  bool _joined = false;
  bool _micMuted = false;
  bool _camOff = false;
  bool _speakerOn = true;
  bool _swapped = false;
  int _callSeconds = 0;
  Timer? _timer;

  bool get isJoining => _joining;
  bool get isJoined => _joined;
  ConsultRoomMediaType? get mediaType => _mediaType;
  int? get remoteUid => _remoteUid;
  bool get remoteVideoActive => _remoteUid != null && !_camOff;
  bool get remoteVideoEverStarted => _remoteUid != null;
  bool get micMuted => _micMuted;
  bool get camOff => _camOff;
  bool get speakerOn => _speakerOn;
  bool get swapped => _swapped;
  int get callSeconds => _callSeconds;
  int get localVolume => 0;
  int get remoteVolume => 0;
  List<String> get captions => const [
        '咨询师：最近一周最明显的变化是什么？',
        '来访者：晚上会反复想第二天的工作。',
      ];

  Future<int> start({
    required ConsultRoomParams params,
    required String localImUserId,
    String? token,
    int? uid,
  }) async {
    _mediaType = params.mediaType;
    _joining = true;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 450));
    _joining = false;
    _joined = true;
    _remoteUid = 3821;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _callSeconds += 1;
      notifyListeners();
    });
    notifyListeners();
    return 0;
  }

  Future<void> end() async => releaseEngine();

  Future<void> releaseEngine() async {
    _timer?.cancel();
    _timer = null;
    _joined = false;
    _remoteUid = null;
    notifyListeners();
  }

  Future<void> toggleMic() async {
    _micMuted = !_micMuted;
    notifyListeners();
  }

  Future<void> toggleCamera() async {
    _camOff = !_camOff;
    notifyListeners();
  }

  Future<void> toggleSpeaker() async {
    _speakerOn = !_speakerOn;
    notifyListeners();
  }

  void toggleSwap() {
    _swapped = !_swapped;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
