import 'dart:math' as math;

/// 支付/订单倒计时助手：解析服务端 +8 截止时间字符串（yyyy-MM-dd HH:mm:ss），
/// 按「时钟」倒计时。
///
/// iOS 参照：XYAIModule/XYAIModule/Classes/ViewModel/XYDeadlineCountdown.swift。
/// iOS 用 XYServerTime.now（服务器时间）作为权威时钟；Flutter 侧由调用方注入
/// [clock]——页面层传 `() => apiClient.serverNow()`，测试注入固定时钟。
class DeadlineCountdown {
  DeadlineCountdown(String? deadlineText, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now,
        deadline = _parse(deadlineText);

  final DateTime Function() _clock;

  /// 解析后的截止时间（空或解析失败为 null）
  final DateTime? deadline;

  /// yyyy-MM-dd HH:mm:ss → DateTime（本地时区，对应 iOS Asia/Shanghai 解析；
  /// 解析失败返回 null）
  static DateTime? _parse(String? text) {
    if (text == null || text.isEmpty) return null;
    // DateTime.tryParse 兼容 "yyyy-MM-dd HH:mm:ss"（空格分隔）
    return DateTime.tryParse(text.trim());
  }

  /// 是否配置了截止时间（决定倒计时是否展示）
  bool get hasDeadline => deadline != null;

  /// 距截止的剩余秒数（基于注入时钟实时计算；无截止时间返回 null）
  int? get remainingSeconds {
    final d = deadline;
    if (d == null) return null;
    return math.max(0, d.difference(_clock()).inSeconds);
  }

  /// 是否已超时（截止时间已过；无截止时间视为未超时）
  bool get isExpired {
    final d = deadline;
    if (d == null) return false;
    return !d.isAfter(_clock());
  }

  /// mm:ss 展示文案（无截止时间返回空串）
  String get countdownText {
    final secs = remainingSeconds;
    if (secs == null) return '';
    final m = (secs ~/ 60).toString().padLeft(2, '0');
    final s = (secs % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  /// 每秒刷新：返回是否仍未超时（无截止时间返回 false）
  bool tick() {
    final secs = remainingSeconds;
    if (secs == null) return false;
    return secs > 0;
  }
}
