import 'dart:ui' show Size;

/// 聊天气泡图片展示尺寸（对齐 iOS TUIImageMessageCell_Minimalist.getContentSize）。
///
/// - 手机端按 `180 * (screenWidth / 390)` 缩放，宽屏最多 240，避免 Web
///   聊天流被单张图片占满；
/// - 竖图：高顶满，宽按比例；横图/方图：宽顶满，高按比例；
/// - 无尺寸时退回正方形最长边。
Size chatImageBubbleSize({
  required double screenWidth,
  double? imageWidth,
  double? imageHeight,
}) {
  final maxSide = (180.0 * (screenWidth / 390.0)).clamp(140.0, 240.0);
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
