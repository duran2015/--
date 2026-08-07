import 'package:flutter/widgets.dart';

enum NERtcVideoViewFitType { cover }

/// Web 原型不加载原生 NERTC FFI，仅保留视频区域的布局占位。
class NERtcVideoView extends StatelessWidget {
  const NERtcVideoView.withInternalRenderer({
    super.key,
    this.uid,
    this.fitType = NERtcVideoViewFitType.cover,
  });

  final int? uid;
  final NERtcVideoViewFitType fitType;

  @override
  Widget build(BuildContext context) => const ColoredBox(
        color: Color(0xFF151515),
        child: SizedBox.expand(),
      );
}
