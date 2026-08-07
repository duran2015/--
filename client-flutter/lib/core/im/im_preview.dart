import 'im_models.dart';

/// 消息预览与系统通知解析规则。
/// 契约：im_custom_message_contract.md §6；
/// Android 参照：MessageFragment.messagePreview /
/// SystemNotificationActivity.parseMessage；
/// iOS 参照：系统通知卡 title/desc→label→textElem→getDisplayString 兜底。

/// 会话列表最后一条消息预览文案。
///
/// 规则（Android MessageFragment.messagePreview，契约 §6）：
/// - 图片/语音/文件/视频 → [图片]/[语音]/[文件]/[视频]
/// - 文本 → 原文
/// - 自定义卡 → desc → label → [通知]
/// - 其他 → [消息]
String previewOfMessage(ImMessage? msg) {
  if (msg == null) return '';
  switch (msg.kind) {
    case ImMessageKind.image:
      return '[图片]';
    case ImMessageKind.sound:
      return '[语音]';
    case ImMessageKind.file:
      return '[文件]';
    case ImMessageKind.video:
      return '[视频]';
    case ImMessageKind.text:
      return msg.text ?? '';
    case ImMessageKind.custom:
      return customCardPreview(msg.customJson);
    case ImMessageKind.other:
      return '[消息]';
  }
}

/// 自定义卡预览：desc → label → [通知]（契约 §6；空串视为缺失顺延）。
String customCardPreview(String? customJson) {
  final card = ImCustomCard.tryParse(customJson);
  if (card == null) return '[通知]';
  return card.desc ?? card.label ?? '[通知]';
}

/// 系统通知列表项（系统通知页展示用）。
/// iOS 参照：XYSystemNotificationViewModel.XYSystemNotificationItem。
class SystemNotificationItem {
  const SystemNotificationItem({
    required this.title,
    required this.content,
    this.timestamp,
  });

  /// 通知标题（自定义卡 title，缺失回退「系统通知」）
  final String title;

  /// 通知正文（desc → label → 文本消息原文）
  final String content;

  /// 消息时间（页面格式化为 timeText）
  final DateTime? timestamp;
}

/// 解析一条系统通知消息（sysNotification 账号历史消息）。
///
/// 规则（iOS 语义：自定义卡 title/desc→label→textElem→兜底；
/// Android SystemNotificationActivity.parseMessage 同义）：
/// - 自定义卡 JSON：title = card.title（缺失回退「系统通知」），
///   content = desc → label；为空则继续走文本兜底；
/// - 文本消息：title = 「系统通知」，content = 原文；
/// - 最终 content 为空 → 返回 null（列表跳过该条，Android content.isBlank() continue）。
SystemNotificationItem? parseSystemNotification(ImMessage msg) {
  if (msg.kind == ImMessageKind.custom) {
    final card = ImCustomCard.tryParse(msg.customJson);
    if (card != null) {
      final content = card.desc ?? card.label;
      if (content != null && content.isNotEmpty) {
        return SystemNotificationItem(
          title: (card.title == null || card.title!.isEmpty)
              ? '系统通知'
              : card.title!,
          content: content,
          timestamp: msg.timestamp,
        );
      }
    }
  }
  // 文本兜底（对应 iOS textElem → getDisplayString 链路的 textElem 段）
  final text = msg.text;
  if (text != null && text.isNotEmpty) {
    return SystemNotificationItem(
      title: '系统通知',
      content: text,
      timestamp: msg.timestamp,
    );
  }
  return null;
}
