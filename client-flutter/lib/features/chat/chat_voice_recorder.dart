import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// 聊天语音录制封装（按住说话）。
/// iOS 参照：XYVoiceRecorder（start / stop 产出 path+duration / cancel）。
class ChatVoiceRecorder {
  ChatVoiceRecorder();

  final AudioRecorder _recorder = AudioRecorder();
  String? _path;
  DateTime? _startedAt;
  bool _started = false;

  /// 是否已真正开录（拿到权限并 start 成功）
  bool get isStarted => _started;

  /// 开始录音；无麦克风权限时返回 false。
  Future<bool> start() async {
    await cancel();
    final granted = await _recorder.hasPermission();
    if (!granted) return false;

    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/chat_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
        numChannels: 1,
      ),
      path: path,
    );
    _path = path;
    _startedAt = DateTime.now();
    _started = true;
    return true;
  }

  /// 结束录音，返回 (path, durationSeconds)；未开录返回 null。
  Future<({String path, int duration})?> stop() async {
    if (!_started) {
      await cancel();
      return null;
    }
    final path = await _recorder.stop() ?? _path;
    final startedAt = _startedAt;
    _started = false;
    _path = null;
    _startedAt = null;
    if (path == null || path.isEmpty || !File(path).existsSync()) {
      return null;
    }
    final elapsed = startedAt == null
        ? 1
        : DateTime.now().difference(startedAt).inMilliseconds;
    // iOS voiceDuration：至少 1 秒，最多 60 秒
    final duration = (elapsed / 1000).floor().clamp(1, 60);
    return (path: path, duration: duration);
  }

  /// 取消并删除临时文件。
  Future<void> cancel() async {
    try {
      if (await _recorder.isRecording()) {
        await _recorder.stop();
      }
    } catch (_) {}
    final path = _path;
    _path = null;
    _startedAt = null;
    _started = false;
    if (path != null) {
      try {
        final file = File(path);
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
  }

  Future<void> dispose() => _recorder.dispose();
}
