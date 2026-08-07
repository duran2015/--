import 'package:flutter/material.dart';

/// 表情面板（内置 emoji 网格）。
/// iOS 参照：XYChatModule XYFacePanel（封装 TUIChat TUIFaceVerticalView，
/// 高 287 = TFaceView_Height；8 列网格 + 底部删除键，点击插入输入框）。
///
/// 注：iOS 使用 TUIChat 内置表情图组（图片表情），Flutter 版用系统 emoji
/// 字符（纯文本消息内联，协议仍为 textElem，双端兼容）。
class ChatFacePanel extends StatelessWidget {
  const ChatFacePanel({
    super.key,
    required this.onEmoji,
    this.onDelete,
  });

  /// 面板高度（iOS 参照：XYFacePanel.standardHeight = 287）
  static const double panelHeight = 287;

  final ValueChanged<String> onEmoji;
  final VoidCallback? onDelete;

  /// 内置 emoji 集（按使用频率排列，覆盖喜怒/手势/心情场景）
  static const List<String> emojis = [
    '😀', '😁', '😂', '🤣', '😃', '😄', '😅', '😆',
    '😉', '😊', '😋', '😎', '😍', '😘', '🥰', '😗',
    '😙', '😚', '🙂', '🤗', '🤔', '😐', '😑', '😶',
    '🙄', '😏', '😣', '😥', '😮', '🤐', '😯', '😪',
    '😫', '🥱', '😴', '😌', '😛', '😜', '😝', '🤤',
    '😒', '😓', '😔', '😕', '🙃', '🤑', '😲', '☹️',
    '🙁', '😖', '😞', '😟', '😤', '😢', '😭', '😦',
    '😧', '😨', '😩', '🤯', '😬', '😰', '😱', '🥵',
    '🥶', '😳', '🤪', '😵', '🥴', '😠', '😡', '🤬',
    '👍', '👎', '👏', '🙌', '🙏', '💪', '🤝', '✌️',
    '❤️', '💔', '💕', '💖', '💯', '🎉', '🌹', '🌈',
    '☀️', '🌙', '⭐', '🔥', '💧', '🍀', '🍎', '☕',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: GridView.builder(
        padding: EdgeInsets.fromLTRB(
          10,
          10,
          10,
          10 + MediaQuery.of(context).padding.bottom,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 8,
        ),
        itemCount: emojis.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onEmoji(emojis[index]),
            child: Center(
              child: Text(
                emojis[index],
                style: const TextStyle(fontSize: 28),
              ),
            ),
          );
        },
      ),
    );
  }
}
