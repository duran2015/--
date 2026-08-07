import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';

/// 轻提示 Toast：纯 Dart 实现（不依赖第三方）。
/// iOS 参照：xinyuiOS HUD 提示（黑底 0.8、白字 14、圆角 8、屏幕居中、2s 消失）。
///
/// 用法：`AppToast.show(context, '文案')`
class AppToast {
  AppToast._();

  /// Toast 圆角
  static const double _radius = 8;

  /// 默认展示时长 2s
  static const Duration _duration = Duration(seconds: 2);

  /// 淡入淡出时长
  static const Duration _fadeDuration = Duration(milliseconds: 200);

  /// 黑底透明度 0.8
  static const double _backgroundOpacity = 0.8;

  static OverlayEntry? _currentEntry;
  static Timer? _dismissTimer;

  /// 展示 Toast。重复调用时替换上一条。
  ///
  /// [context] 可为页面或根 Navigator：Navigator 自身在 Overlay 之上，
  /// `Overlay.maybeOf` 会失败，需回退到 `Navigator.overlay`。
  static void show(BuildContext context, String message) {
    _dismiss();

    final OverlayState? overlay =
        Overlay.maybeOf(context) ?? Navigator.maybeOf(context)?.overlay;
    if (overlay == null) return;

    final OverlayEntry entry = OverlayEntry(
      builder: (_) => _ToastView(message: message),
    );
    _currentEntry = entry;
    overlay.insert(entry);

    _dismissTimer = Timer(_duration, _dismiss);
  }

  static void _dismiss() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _currentEntry?.remove();
    _currentEntry = null;
  }
}

class _ToastView extends StatefulWidget {
  const _ToastView({required this.message});

  final String message;

  @override
  State<_ToastView> createState() => _ToastViewState();
}

class _ToastViewState extends State<_ToastView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppToast._fadeDuration,
      reverseDuration: AppToast._fadeDuration,
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
    // 展示 2s，末尾留出淡出时间
    Timer(AppToast._duration - AppToast._fadeDuration, () {
      if (mounted) _controller.reverse();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Material 包裹：Overlay 内无 Material 祖先时 Text 会画双黄下划线。
    return IgnorePointer(
      child: FadeTransition(
        opacity: _opacity,
        child: Material(
          type: MaterialType.transparency,
          child: Align(
            alignment: Alignment.center,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.7,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.gap16,
                vertical: AppDimens.gap10,
              ),
              decoration: BoxDecoration(
                color: Colors.black
                    .withValues(alpha: AppToast._backgroundOpacity),
                borderRadius: BorderRadius.circular(AppToast._radius),
              ),
              child: Text(
                widget.message,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: Colors.white,
                  decoration: TextDecoration.none,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
