import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../auth/auth_controller.dart';
import '../router/deep_link_parser.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_background.dart';
import '../widgets/app_nav_bar.dart';
import 'xy_js_bridge.dart';

/// 容器暴露给扩展方的句柄（对应 iOS 子类可调用的原生能力）。
/// iOS 参照：XYWebViewController 子类扩展点
/// （evaluateJavaScriptInPage / navigationController.pop）。
class AppWebViewHandle {
  const AppWebViewHandle({
    required this.evaluateJavaScript,
    required this.close,
  });

  /// 在 H5 页面执行 JS（原生 → H5，如 window.XY_H5.exitAssessment）
  final void Function(String javaScript) evaluateJavaScript;

  /// 关闭当前页（iOS popViewController(animated: true)）
  final void Function() close;
}

/// 通用 WebView 容器：加载 H5、提供 JS 双向交互（XYJSBridge）、
/// 注入登录态（window.XY_APP）。
/// iOS 参照：XYCoreModule/XYCoreModule/Classes/Web/XYWebViewController.swift。
/// Android 对照：webview/WebViewActivity.kt。
///
/// 与 iOS 的一致点：
/// - AppNavBar 标题：外部传入 > 网页 title > relax 链接 slug 映射；
/// - 顶部 2px 进度条 #2AB8E6，加载完成隐藏；
/// - 加载失败占位「页面加载失败 + 重新加载」（1:1 iOS XYWebErrorView）；
/// - 内置 JS action：getUserInfo / close / setTitle / openLink / log；
/// - didFinish 后重注入 window.XY_APP 与扩展脚本（iOS syncBootstrapToPage）；
/// - 登出时自动关闭页面（iOS observeLogout）；
/// - http(s) 页面内导航不拦截（iOS 未实现 decidePolicy，全部内开），
///   openLink action 走 DeepLinkParser（iOS XYURLRouter.open：http→内开新容器）。
///
/// 与 iOS 的差异（平台能力所限）：
/// - iOS 在 documentStart 注入脚本（WKUserScript）；webview_flutter 无
///   documentStart 钩子，改为 onPageStarted / onPageFinished 注入（与 Android
///   WebViewActivity 策略一致），didFinish 重注入兜底与 iOS 相同；
/// - iOS 注入 forMainFrameOnly=false（含 iframe）；Flutter 仅主框架；
/// - iOS 无下拉刷新（代码确认），故不实现；
/// - 网页 title 只在 onPageFinished 读取一次（iOS KVO 持续观测），
///   SPA 运行期改 document.title 不会回填导航栏。
class AppWebViewPage extends ConsumerStatefulWidget {
  const AppWebViewPage({
    super.key,
    required this.url,
    this.title,
    this.extraScripts = const [],
    this.extraActions = const {},
    this.backInterceptor,
    this.bottomBarBuilder,
    this.useSharedBackground = false,
  });

  /// 待加载的 H5 链接（需带 scheme，如 https://）
  final String url;

  /// 外部传入的导航栏标题（为空时用网页 title / 链接映射）
  final String? title;

  /// 扩展 documentStart 脚本（iOS extraUserScripts，排在 XY_APP /
  /// XYJSBridge 之后注入，didFinish 后重注入）
  final List<String> extraScripts;

  /// 扩展 JS action（iOS registerActions(in:)）
  final Map<
      String,
      Future<Object?> Function(
        AppWebViewHandle handle,
        Map<String, dynamic>? data,
      )> extraActions;

  /// 返回拦截器（iOS navigationShouldPop 子类重写点）：
  /// 返回 true 表示已处理（容器不再 pop），false/null 走默认 pop。
  final FutureOr<bool> Function(AppWebViewHandle handle)? backInterceptor;

  /// 底部固定面板构建器（iOS XYWebViewController.bottomInset 扩展点；
  /// 参照 XYIntakeWebViewController 底部提交按钮面板：
  /// webContainer 底部对齐面板顶部，面板随页面固定）。
  /// 传入 [AppWebViewHandle] 便于面板按钮执行 JS / 关闭页面。
  final Widget Function(AppWebViewHandle handle)? bottomBarBuilder;

  /// 使用共享订单背景（iOS useSharedBackground）：
  /// view 铺 XYOrderBackgroundView（= Flutter [AppPageBackground] 渐变 + 光晕）、
  /// 导航栏透明无分割线（gk_navBackgroundColor = clear + gk_navLineHidden）、
  /// WebView 透明非不透明（isOpaque = false）透出背景。
  /// false 时为白底白导航（默认，与 iOS 一致）。
  final bool useSharedBackground;

  @override
  ConsumerState<AppWebViewPage> createState() => AppWebViewPageState();
}

class AppWebViewPageState extends ConsumerState<AppWebViewPage> {
  /// 进度条颜色（iOS progressTintColor #2AB8E6）
  static const Color _progressColor = Color(0xFF2AB8E6);

  /// 顶部加载进度条高度（iOS progressBarHeight 2）
  static const double _progressBarHeight = 2;

  late final WebViewController _controller;
  late final XyJsBridge _bridge;
  late final AppWebViewHandle _handle;

  /// 当前导航栏标题
  late String _title;

  /// 加载进度 0~1
  double _progress = 0;

  /// 进度条是否可见（iOS progressBar.isHidden，初始隐藏）
  bool _progressVisible = false;

  /// 是否展示加载失败占位
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _title = _resolvedNavTitle(webTitle: null);
    _handle = AppWebViewHandle(
      evaluateJavaScript: _evaluateInPage,
      close: _closePage,
    );
    _bridge = XyJsBridge(jsExecutor: _evaluateInPage);
    _registerBuiltinActions();
    _initController();
  }

  // MARK: - WebView 初始化

  void _initController() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      // iOS useSharedBackground：wv.isOpaque = false + clear 透出共享背景
      ..setBackgroundColor(
        widget.useSharedBackground ? Colors.transparent : Colors.white,
      )
      ..addJavaScriptChannel(
        XyJsBridge.messageHandlerName,
        onMessageReceived: (message) => _bridge.handleMessage(message.message),
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => _injectScripts(),
          onProgress: (progress) {
            setState(() {
              _progress = progress / 100.0;
              _progressVisible = progress < 100;
            });
          },
          onPageFinished: (_) => _onPageFinished(),
          onWebResourceError: (error) {
            // 仅主框架失败展示错误占位（iOS didFail(Provisional)Navigation）
            if (error.isForMainFrame ?? true) _showError();
          },
          // iOS 未实现 decidePolicyForNavigationAction：页面内导航全部内开
          onNavigationRequest: (_) => NavigationDecision.navigate,
        ),
      );
    _loadUrl();
  }

  /// 加载目标链接，非法链接直接展示错误占位（iOS loadURL）。
  void _loadUrl() {
    final parsed = Uri.tryParse(widget.url);
    if (parsed == null || parsed.scheme.isEmpty) {
      debugPrint('🌐 [WebVC] 非法 url，无法构造 URL：${widget.url}');
      _loadFailed = true;
      return;
    }
    _controller.loadRequest(_withBootstrapToken(parsed));
  }

  /// 把登录态 token 拼进 H5 链接，供 H5 `captureTokenFromUrl()` 在挂载前写入
  /// localStorage，作为 `window.XY_APP` 注入的兜底（防时序竞态）。
  ///
  /// 为什么需要：webview_flutter 无 iOS WKUserScript 的 documentStart 钩子，
  /// window.XY_APP 只能在 onPageStarted/onPageFinished 注入，且经平台通道往返
  /// 有延迟。H5 挂载即发首个请求（如 intake 拉题目 /app/assessment/questions-by-key），
  /// 可能抢在 XY_APP 注入落地之前 → getToken() 取空 → 401 → 「暂无问卷信息」
  /// （时好时坏的竞态；提交等稍晚的请求因 token 已注入而正常）。
  /// 带 token 的 URL 经 captureTokenFromUrl（main.js，挂载前同步执行）写入
  /// localStorage，绕开竞态。注入到 hash 路由的 fragment query（fragment 不进
  /// Referer，比 location.search 更安全；与小程序 web-view ?token 场景同一机制）。
  Uri _withBootstrapToken(Uri uri) {
    final token = ref.read(authControllerProvider)?.accessToken ?? '';
    if (token.isEmpty) return uri;
    if (uri.fragment.isNotEmpty) {
      final frag = uri.fragment;
      final join = frag.contains('?') ? '&' : '?';
      return uri.replace(
        fragment: '$frag${join}token=${Uri.encodeQueryComponent(token)}',
      );
    }
    return uri.replace(
      queryParameters: {...uri.queryParameters, 'token': token},
    );
  }

  // MARK: - 脚本注入

  /// 注入 window.XY_APP + 传输垫片 + XYJSBridge helper + 扩展脚本。
  /// iOS documentStart 注入（Flutter 降级为 onPageStarted，同 Android）。
  void _injectScripts() {
    _evaluateInPage(XyJsBridge.bootstrapScript(_bootstrapData()));
    _evaluateInPage(XyJsBridge.transportShimScript);
    _evaluateInPage(XyJsBridge.bridgeHelperScript);
    for (final script in widget.extraScripts) {
      _evaluateInPage(script);
    }
  }

  /// iOS didFinish：进度条收满隐藏、隐藏错误占位、重注入登录态与扩展脚本、
  /// 回填网页标题。
  Future<void> _onPageFinished() async {
    // iOS syncBootstrapToPage + syncExtraScriptsToPage（重写 XY_APP 后重挂方法）
    _injectScripts();
    // 网页标题回填（仅未外部指定标题时，iOS observeTitleIfNeeded）
    if (widget.title == null) {
      final webTitle = await _controller.getTitle();
      if (!mounted) return;
      final title = _resolvedNavTitle(webTitle: webTitle);
      if (title.isNotEmpty && title != _title) {
        setState(() => _title = title);
      }
    }
    if (!mounted) return;
    setState(() {
      _progress = 1;
      _progressVisible = false;
      _loadFailed = false;
    });
    // 诊断（仅 debug）：5s 后回读页面桥接注入状态，排查 H5↔原生通道
    if (kDebugMode) {
      unawaited(
        Future<void>.delayed(const Duration(seconds: 5), _probeBridgeState),
      );
    }
  }

  /// 回读页面注入状态（window.XY_APP / XYJSBridge / XY_H5 / 传输通道）。
  Future<void> _probeBridgeState() async {
    try {
      final result = await _controller.runJavaScriptReturningResult(
        '(function(){return JSON.stringify({'
        'url: location.href,'
        'XY_APP: typeof window.XY_APP,'
        'XYJSBridge: typeof window.XYJSBridge,'
        'XY_H5: typeof window.XY_H5,'
        'webkit: typeof window.webkit,'
        'wkApp: !!(window.webkit && window.webkit.messageHandlers && '
        'window.webkit.messageHandlers.app),'
        'appCh: typeof window.app'
        '});})()',
      );
      debugPrint('🌐 [WebProbe] $result');
      // 传输通道直测：经 helper / 经 webkit 原生通道各发一条 log action，
      // 若 Dart 侧能收到会打印 🌐 [H5 log]（内置 log action）
      _evaluateInPage(
        "window.XYJSBridge.call('log', {via: 'helper'});",
      );
      _evaluateInPage(
        'window.webkit.messageHandlers.app.postMessage('
        "{action: 'log', data: {via: 'webkit'}});",
      );
    } catch (e) {
      debugPrint('🌐 [WebProbe] failed: $e');
    }
  }

  void _evaluateInPage(String javaScript) {
    // controller 未加载完成前调用会静默失败（与 iOS evaluateJavaScript 容错一致）
    unawaited(_controller.runJavaScript(javaScript));
  }

  // MARK: - 注入数据

  /// 注入 H5 的登录态 bootstrap（window.XY_APP），实时读登录态。
  /// iOS 参照：XYWebViewController.bootstrapData()；Android 对照：
  /// WebViewActivity.injectXYApp（appVersion 同为硬编码 "1.0"）。
  Map<String, dynamic> _bootstrapData() {
    final login = ref.read(authControllerProvider);
    final token = login?.accessToken ?? '';
    return <String, dynamic>{
      'token': token,
      'userId': login?.userId ?? '',
      'role': login?.currentIdentity ?? '',
      'appVersion': '1.0',
      'isLogined': token.isNotEmpty,
    };
  }

  // MARK: - 内置 JS action

  /// 注册通用内置 action（iOS registerBuiltinActions + 扩展 action）。
  void _registerBuiltinActions() {
    _bridge.register('getUserInfo', (_) async => _bootstrapData());
    _bridge.register('close', (_) async {
      _closePage();
      return null;
    });
    _bridge.register('setTitle', (data) async {
      final title = data?['title'];
      if (title is String && mounted) {
        setState(() => _title = title);
      }
      return null;
    });
    _bridge.register('openLink', (data) async {
      final url = data?['url'];
      if (url is! String || url.isEmpty) return null;
      // iOS XYURLRouter.shared.open：http(s)→push 新 WebView 容器；
      // nanjingxinyu://→深链解析跳原生页；无法识别仅打印
      final target = DeepLinkParser.parse(url);
      if (target != null && mounted) {
        context.push(target.toLocation());
      }
      return null;
    });
    _bridge.register('log', (data) async {
      debugPrint('🌐 [H5 log] ${data ?? {}}');
      return null;
    });

    // 扩展 action（测评页等，iOS registerActions(in:)）
    widget.extraActions.forEach((action, handler) {
      _bridge.register(action, (data) => handler(_handle, data));
    });
  }

  // MARK: - 导航

  /// 解析导航栏标题（iOS resolvedNavTitle：外部传入 > 网页 title > 链接映射）。
  String _resolvedNavTitle({String? webTitle}) {
    final input = widget.title;
    if (input != null && input.isNotEmpty) return input;
    final trimmed = webTitle?.trim();
    if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    return _fallbackTitle(widget.url);
  }

  /// 按 relax 链接路径映射默认标题（iOS fallbackTitle(for:)）。
  static String _fallbackTitle(String urlString) {
    final uri = Uri.tryParse(urlString);
    if (uri == null) return '';
    var slug = uri.pathSegments.isEmpty ? '' : uri.pathSegments.last;
    final dot = slug.lastIndexOf('.');
    if (dot > 0) slug = slug.substring(0, dot);
    const titles = <String, String>{
      'huxi': '呼吸训练',
      'baizaoyin': '白噪音',
      'muyu': '敲木鱼',
      'mingxiang': '冥想放松',
      'shuiqian': '睡眠引导',
      'paopao': '捏泡泡',
    };
    return titles[slug] ?? '';
  }

  /// 展示加载失败占位、隐藏进度条（iOS showError）。
  void _showError() {
    if (!mounted) return;
    setState(() {
      _progressVisible = false;
      _loadFailed = true;
    });
  }

  /// 程序化关闭放行标记：PopScope(canPop: false) 会同时阻断系统返回与
  /// 程序化 maybePop，导致拦截器分支下导航栏返回 / H5 close action /
  /// onAssessmentClose / observeLogout 全部无法退出页面（实测 Android
  /// 系统返回键在测评 H5 页连按无效）。程序化关闭前置位放行一次。
  bool _allowProgrammaticPop = false;

  /// 返回按钮 / 系统返回：先给扩展方拦截机会（iOS navigationShouldPop）。
  Future<void> _onBack() async {
    final interceptor = widget.backInterceptor;
    if (interceptor != null) {
      final handled = await interceptor(_handle);
      if (handled) return;
    }
    _closePage();
  }

  void _closePage() {
    if (!mounted) return;
    setState(() => _allowProgrammaticPop = true);
    // setState 不会同步刷新 PopScope 的 canPop：直接 maybePop 时仍带着旧值 false，
    // 被 PopScope 拦截（onPopInvokedWithResult didPop=false）→ 页面退不出
    // （导航栏返回 / H5 close / onAssessmentClose 实测无效）。
    // 等下一帧 canPop 生效后再 pop。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).maybePop().then((didPop) {
        // 未 pop（如已是根路由）时复位，恢复返回拦截语义
        if (mounted && !didPop) {
          setState(() => _allowProgrammaticPop = false);
        }
      });
    });
  }

  // MARK: - UI

  @override
  Widget build(BuildContext context) {
    // 登出时关闭当前页（iOS observeLogout，避免持有旧 token 的页面残留）
    ref.listen(authControllerProvider, (previous, next) {
      if (next == null) _closePage();
    });

    final body = Column(
      children: [
        // iOS useSharedBackground：gk_navBackgroundColor = clear + 隐藏分割线
        AppNavBar(
          title: _title,
          onBack: _onBack,
          transparent: widget.useSharedBackground,
        ),
        // 顶部加载进度条（2px #2AB8E6，透明轨道，仿 iOS UIProgressView）
        SizedBox(
          height: _progressBarHeight,
          child: _progressVisible
              ? TweenAnimationBuilder<double>(
                  tween: Tween<double>(end: _progress),
                  duration: const Duration(milliseconds: 200),
                  builder: (context, value, _) => LinearProgressIndicator(
                    value: value,
                    backgroundColor: Colors.transparent,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(_progressColor),
                  ),
                )
              : null,
        ),
        Expanded(
          child: ColoredBox(
            // iOS useSharedBackground：webContainer 透明透出共享背景
            color:
                widget.useSharedBackground ? Colors.transparent : Colors.white,
            child: Stack(
              fit: StackFit.expand,
              children: [
                WebViewWidget(controller: _controller),
                if (_loadFailed)
                  _WebErrorView(
                    onRetry: () {
                      setState(() => _loadFailed = false);
                      _controller.reload();
                    },
                  ),
              ],
            ),
          ),
        ),
        // 底部固定面板（iOS bottomInset 扩展点；intake 问卷提交按钮面板）。
        // 有 bottomBar 时外层 SafeArea(bottom: false)，由面板自身垫底部安全区，
        // 白底贴齐屏幕底边（与 iOS setupBottomBar 一致）。
        if (widget.bottomBarBuilder != null) widget.bottomBarBuilder!(_handle),
      ],
    );

    // iOS useSharedBackground：XYOrderBackgroundView.install(in: view)
    // → 共享渐变 + 光晕底（Flutter AppPageBackground），Scaffold 透明透出。
    // 有底部面板时 bottom: false，避免安全区空隙露在白底下方。
    final safeBody = SafeArea(
      bottom: widget.bottomBarBuilder == null,
      child: body,
    );
    final content = widget.useSharedBackground
        ? AppPageBackground(child: safeBody)
        : safeBody;
    final scaffoldBackground =
        widget.useSharedBackground ? Colors.transparent : Colors.white;

    // 有返回拦截器时接管系统返回（iOS navigationShouldPop 返回 false 阻断默认 pop）；
    // 程序化关闭（_closePage）时 _allowProgrammaticPop 置位放行一次。
    if (widget.backInterceptor != null) {
      return PopScope(
        canPop: _allowProgrammaticPop,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _onBack();
        },
        child: Scaffold(backgroundColor: scaffoldBackground, body: content),
      );
    }
    return Scaffold(backgroundColor: scaffoldBackground, body: content);
  }
}

/// WebView 加载失败时的占位视图，含「重新加载」按钮。
/// iOS 参照：XYWebViewController.swift 内私有 XYWebErrorView
/// （「页面加载失败」15 #999999 居中；按钮 120×36 底 #2AB8E6 圆角 4 白字 14）。
///
/// 说明：未复用通用 AppErrorView（160×50 深色胶囊样式），因总原则要求
/// UI 1:1 还原 iOS，此处按 iOS 实值实现。
class _WebErrorView extends StatelessWidget {
  const _WebErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '页面加载失败',
              style: TextStyle(fontSize: 15, color: AppColors.textTertiary),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onRetry,
              child: Container(
                width: 120,
                height: 36,
                decoration: BoxDecoration(
                  color: _retryColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                alignment: Alignment.center,
                child: Text(
                  '重新加载',
                  style: AppTextStyles.bodyLarge.copyWith(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 重试按钮底色（iOS UIColor(hex: "2AB8E6")）
  static const Color _retryColor = Color(0xFF2AB8E6);
}
