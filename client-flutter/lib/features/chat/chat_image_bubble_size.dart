import 'dart:ui' show Size;

/// 聊天气泡图片展示尺寸（对齐 iOS TUIImageMessageCell_Minimalist.getContentSize）。
///
/// - 最长边 = `180 * (screenWidth / 390)`，避免聊天流被单张图片占满；
/// - 竖图：高顶满，宽按比例；横图/方图：宽顶满，高按比例；
/// - 无尺寸时退回正方形最长边。
Size chatImageBubbleSize({
  required double screenWidth,
  double? imageWidth,
  double? imageHeight,
}) {
  final maxSide = 180.0 * (screenWidth / 390.0);
  final w = imageWidth ?? 0;
  final h = imageHeight ?? 0;
  if (w <= 0 || h <= 0) {
    return Size(maxSide, maxSide);
  }
  if (h > w) {
    return Size(w / h * maxSide, maxSide);
  }
  return Size(maxSide, h / w * maxSide);
}
