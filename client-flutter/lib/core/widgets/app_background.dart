import 'package:flutter/material.dart';

import '../../utils/load_image.dart';
import '../theme/app_assets.dart';
import '../theme/app_colors.dart';

/// 页面通用背景：#ECEFFF → #F1F4FB 渐变底 + 右上/左侧两枚青色光晕。
/// iOS 参照：XYCoreModule XYOrderBackgroundView
/// （login/verify/role 等页面 `XYOrderBackgroundView.install(in: view)`）。
///
/// 用法：作为页面根布局底层包裹内容：
/// ```dart
/// Scaffold(body: AppPageBackground(child: ...))
/// ```
class AppPageBackground extends StatelessWidget {
  const AppPageBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        LoadAssetImage(
          'img_bg',
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
        child
      ],
    );
  }
}
