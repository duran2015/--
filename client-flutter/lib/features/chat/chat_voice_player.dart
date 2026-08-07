import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../../core/im/im_models.dart';
import '../../core/im/im_service.dart';

/// 聊天语音播放器（全局单例：同时只播一条）。
/// iOS 参照：TUIVoiceMessageCellData.playVoiceMessage + TUIAudioPlaybackManager。
class ChatVoicePlayer extends ChangeNotifier {
  ChatVoicePlayer._() {
    _player.onPlayerComplete.listen((_) => unawaited(stop()));
    _player.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.stopped || state == PlayerState.completed) {
        if (_playingMsgId != null) {
          _playingMsgId = null;
          notifyListeners();
        }
      }
    });
  }

  static final ChatVoicePlayer instance = ChatVoicePlayer._();

  final AudioPlayer _player = AudioPlayer();
  String? _playingMsgId;
  bool _busy = false;

  /// 当前正在播放的消息 id（null 表示空闲）
  String? get playingMsgId => _playingMsgId;

  bool isPlaying(String msgId) => _playingMsgId == msgId;

  /// 点击语音气泡：同条再点停止；切到另一条先停再播。
  Future<String?> toggle({
    required ImMessage message,
    required ImService im,
  }) async {
    if (message.kind != ImMessageKind.sound) return '非语音消息';
    if (_busy) return null;
    if (isPlaying(message.msgId)) {
      await stop();
      return null;
    }

    _busy = true;
    try {
      await stop();
      final source = await im.resolveSoundSource(message);
      if (source == null) {
        return '语音文件不可用';
      }
      _playingMsgId = message.msgId;
      notifyListeners();
      await _player.play(source);
      return null;
    } catch (_) {
      await stop();
      return '播放失败';
    } finally {
      _busy = false;
    }
  }

  Future<void> stop() async {
    _playingMsgId = null;
    notifyListeners();
    try {
      await _player.stop();
    } catch (_) {}
  }
}

/// 解析可播放源：优先本地文件，其次在线 URL。
extension SoundSourceResolve on ImService {
  Future<Source?> resolveSoundSource(ImMessage message) async {
    final local = message.soundPath;
    if (local != null && local.isNotEmpty && File(local).existsSync()) {
      return DeviceFileSource(local);
    }
    final resolved = await resolveSoundPlayablePath(message);
    if (resolved != null && resolved.isNotEmpty) {
      if (resolved.startsWith('http://') || resolved.startsWith('https://')) {
        return UrlSource(resolved);
      }
      if (File(resolved).existsSync()) {
        return DeviceFileSource(resolved);
      }
    }
    return null;
  }
}
