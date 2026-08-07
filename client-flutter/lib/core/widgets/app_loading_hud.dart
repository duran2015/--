import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';

/// 全屏加载 HUD：居中深色小卡片（转圈 + 文案），无灰色大遮罩；
/// 外层仍拦截点击防重复操作。
/// iOS 参照：XYLoading.show("登录中"/"切换中"/…)。
///
/// 用法：叠在页面 Stack 上
/// ```dart
/// if (busy) const Positioned.fill(child: AppLoadingHud(message: '登录中'))
/// ```
class AppLoadingHud extends StatelessWidget {
  const AppLoadingHud({
    super.key,
    this.message = '加载中',
  });

  /// HUD 文案（空串则只显示转圈）
  final String message;

  /// HUD 黑底透明度
  static const double _hudOpacity = 0.75;

  static const double _hudRadius = 10;
  static const double _spinnerSize = 24;
  static const double _spinnerStroke = 2.5;

  @override
  Widget build(BuildContext context) {
    // 仅居中深色小卡片；不铺灰色大遮罩（仍 AbsorbPointer 拦截点击）。
    return AbsorbPointer(
      child: Material(
        type: MaterialType.transparency,
        child: Center(
          child: Container(
            constraints: const BoxConstraints(minWidth: 100),
            padding: EdgeInsets.symmetric(
              horizontal: message.isEmpty ? 22 : 24,
              vertical: message.isEmpty ? 22 : 18,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: _hudOpacity),
              borderRadius: BorderRadius.circular(_hudRadius),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: _spinnerSize,
                  height: _spinnerSize,
                  child: CircularProgressIndicator(
                    strokeWidth: _spinnerStroke,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                if (message.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    message,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: Colors.white,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
