import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/network/api_env.dart';
import 'core/network/dev_mock.dart';
import 'core/webview/webview_prewarm.dart';

import 'utils/ly_cache.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化本地存储 LyCache (Hive)
  await LyCache.init();

  // 开启 Android / iOS Edge-to-Edge 边到边全屏沉浸式
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // 设置 Android / iOS 沉浸式状态栏与底部导航栏全透明背景及默认图标深色样式
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarContrastEnforced: false,
    ),
  );

  // 默认 API_ENV=live：debug / release 均直连真实后端。
  // 显式 API_ENV=mock 时，调试运行与可分发的演示构建都注册本地 Mock。
  if (ApiEnv.isMock) registerDevMocks();
  // WebView 预热（iOS 参照：XYWebViewPrewarmManager.prewarmIfNeeded）
  if (!kIsWeb) WebViewPrewarm.prewarmIfNeeded();
  runApp(const ProviderScope(child: XinyuApp()));
}
