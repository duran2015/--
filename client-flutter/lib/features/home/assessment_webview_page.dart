import 'package:flutter/material.dart';

import '../../core/webview/app_webview_page.dart';

/// 测评答题 H5 容器：在通用 [AppWebViewPage] 基础上提供测评专属的关闭双向桥。
/// iOS 参照：XYHomeModule/Classes/ViewController/XYAssessmentWebViewController.swift。
/// Android 对照：webview/AssessmentWebViewActivity.kt。
///
/// - H5 → 原生：`window.XY_APP.onAssessmentClose()`（无参）→ 返回上一页；
/// - 原生 → H5：点返回按钮 / 系统返回前，先调用
///   `window.XY_H5.exitAssessment()`（H5 侧用 keepalive fetch 存草稿，
///   与客户端无关），再返回上一页。
class AssessmentWebViewPage extends StatefulWidget {
  const AssessmentWebViewPage({super.key, required this.url, this.title});

  /// 答题 H5 链接（接口下发的 h5Link，原样加载，不做参数拼接——与 iOS 一致：
  /// iOS XYHomeAssessmentWebOpener.openH5 直接用 link push 容器，
  /// 登录态由容器经 window.XY_APP 注入）
  final String url;

  /// 导航栏标题（测评标题）
  final String? title;

  @override
  State<AssessmentWebViewPage> createState() => _AssessmentWebViewPageState();
}

class _AssessmentWebViewPageState extends State<AssessmentWebViewPage> {
  /// 是否已发起退出流程（拦截返回按钮 / 系统返回的重复触发，
  /// iOS didInitiateExitFlow）
  bool _didInitiateExitFlow = false;

  /// 点返回按钮 / 系统返回触发：先通知 H5 存草稿，再返回上一页。
  /// iOS 参照：navigationShouldPop（返回 false 阻断默认 pop，下一轮 runloop
  /// 手动 pop，给 evaluateJavaScript 派发与 keepalive fetch 发起留时间）。
  bool _interceptBack(AppWebViewHandle handle) {
    if (_didInitiateExitFlow) return true;
    _didInitiateExitFlow = true;
    // 1) 通知 H5 存草稿（H5 侧 window.XY_H5.exitAssessment）
    handle.evaluateJavaScript(
      'window.XY_H5 && window.XY_H5.exitAssessment && '
      'window.XY_H5.exitAssessment();',
    );
    // 2) 延迟 pop，给 JS 派发与 keepalive fetch 发起留一拍
    // （iOS 为下一轮 runloop；Flutter 显式给 150ms）
    Future<void>.delayed(const Duration(milliseconds: 150), handle.close);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return AppWebViewPage(
      url: widget.url,
      title: widget.title,
      extraScripts: const [_assessmentMethodScript],
      extraActions: {
        // 测评专属 action：onAssessmentClose → 返回上一页
        // iOS 参照：registerActions(in:) 注册 XYAssessmentBridgeAction.onAssessmentClose
        'onAssessmentClose': (handle, _) async {
          handle.close();
          return null;
        },
      },
      backInterceptor: (handle) => _interceptBack(handle),
    );
  }
}

/// `window.XY_APP.onAssessmentClose` 方法挂载脚本（documentStart 注入与
/// didFinish 重注入共用）。与 iOS assessmentMethodScript 逐字节一致。
///
/// 守卫 `window.XY_APP && window.XYJSBridge` 确保二者已注入；
/// `typeof ... !== 'function'` 保证幂等。
const String _assessmentMethodScript = '''
(function () {
  if (window.XY_APP && window.XYJSBridge && typeof window.XY_APP.onAssessmentClose !== 'function') {
    window.XY_APP.onAssessmentClose = function () {
      return window.XYJSBridge.call('onAssessmentClose');
    };
  }
})();
''';
