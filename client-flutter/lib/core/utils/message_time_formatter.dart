/// IM 消息时间展示格式化（会话摘要、系统通知列表通用）。
/// 行为语义以 iOS 为准：XYCoreModule/XYMessageTimeFormatter.swift
/// （今天 HH:mm，昨天「昨天」，本年 MM-dd，跨年 yyyy-MM-dd）。
/// 注：Android MessageTimeFormatter 有「周X HH:mm」分支，与 iOS 不一致，
/// 按总原则取 iOS 语义。
class MessageTimeFormatter {
  MessageTimeFormatter._();

  static String _two(int v) => v.toString().padLeft(2, '0');

  /// 格式化消息时间；null 返回空串（iOS guard let date else return ""）。
  static String text(DateTime? date, {DateTime? now}) {
    if (date == null) return '';
    final current = now ?? DateTime.now();
    final today = DateTime(current.year, current.month, current.day);
    final day = DateTime(date.year, date.month, date.day);
    if (day == today) {
      return '${_two(date.hour)}:${_two(date.minute)}';
    }
    if (day == today.subtract(const Duration(days: 1))) {
      return '昨天';
    }
    if (date.year == current.year) {
      return '${_two(date.month)}-${_two(date.day)}';
    }
    return '${date.year}-${_two(date.month)}-${_two(date.day)}';
  }

  /// 聊天消息间时间分隔用：今天 `HH:mm`；非今天**带上日期 + 时间**
  /// （昨天「昨天 HH:mm」、本年「MM-dd HH:mm」、跨年「yyyy-MM-dd HH:mm」）。
  /// 与 [text] 区分：[text] 供会话列表摘要，非今天只给日期；聊天分隔条需精确到分钟。
  static String chatSeparator(DateTime? date, {DateTime? now}) {
    if (date == null) return '';
    final current = now ?? DateTime.now();
    final today = DateTime(current.year, current.month, current.day);
    final day = DateTime(date.year, date.month, date.day);
    final hm = '${_two(date.hour)}:${_two(date.minute)}';
    if (day == today) return hm;
    if (day == today.subtract(const Duration(days: 1))) return '昨天 $hm';
    if (date.year == current.year) {
      return '${_two(date.month)}-${_two(date.day)} $hm';
    }
    return '${date.year}-${_two(date.month)}-${_two(date.day)} $hm';
  }
}
