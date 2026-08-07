// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';

/// Flutter Web 中承载既有咨询前资料 H5；移动端仍使用 AppWebViewPage。
class IntakeH5Frame extends StatefulWidget {
  const IntakeH5Frame({super.key, required this.url});

  final String url;

  @override
  State<IntakeH5Frame> createState() => _IntakeH5FrameState();
}

class _IntakeH5FrameState extends State<IntakeH5Frame> {
  late final String _viewType;

  @override
  void initState() {
    super.initState();
    _viewType = 'intake-h5-${identityHashCode(this)}';
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (_) {
      return html.IFrameElement()
        ..src = widget.url
        ..style.border = '0'
        ..style.width = '100%'
        ..style.height = '100%'
        ..allow = 'camera; microphone'
        ..setAttribute('title', '咨询前情况了解');
    });
  }

  @override
  Widget build(BuildContext context) => HtmlElementView(viewType: _viewType);
}
