import 'package:webview_flutter/webview_flutter.dart';

import '../../utils/ly_cache.dart';
import '../storage/local_flags.dart';

/// WebView 预热管理。
/// iOS 参照：XYCoreModule/Classes/Web/XYWebViewPrewarmManager.swift
/// （共享 WKProcessPool + 启动后加载 about:blank，降低首次打开 H5 的卡顿）。
///
/// 与 iOS 的差异（平台能力所限，按任务书允许降级）：
/// - webview_flutter 不暴露 WKProcessPool / 共享进程配置，无法复刻
///   「共享进程池 + 各页注入独立 JSBridge」；
/// - 降级为「首屏加载优化」：启动后提前创建 keeper WebViewController 并加载
///   about:blank，预热平台 WebView 进程与渲染管线；各页仍创建独立
///   controller（iOS 各页同样是独立 WKWebView，仅共享进程池）。
class WebViewPrewarm {
  WebViewPrewarm._();

  /// 是否已完成预热
  static bool _didPrewarm = false;

  /// 持有预热用 controller，避免被回收（iOS keeperWebView 语义，
  /// 字段本身不读取，仅作强引用保活）
  // ignore: unused_field
  static WebViewController? _keeper;

  /// 启动后调用一次，预热 WebView 进程。
  /// iOS 参照：XYWebViewPrewarmManager.prewarmIfNeeded。
  static void prewarmIfNeeded() {
    if (_didPrewarm) return;
    final accepted =
        LyCache.getSync<bool>(key: LocalFlags.agreementAccepted) ?? false;
    if (!accepted) return;
    _didPrewarm = true;
    final controller = WebViewController()
      ..loadRequest(Uri.parse('about:blank'));
    _keeper = controller;
  }
}
