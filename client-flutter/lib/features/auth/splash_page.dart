import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/network/api_env.dart';
import '../../core/network/dev_mock.dart';
import '../../core/storage/account_store.dart';
import '../../core/storage/local_flags.dart';
import '../../core/theme/app_assets.dart';
import '../../core/theme/app_dimens.dart';
import '../../utils/load_image.dart';
import '../../utils/ly_cache.dart';
import 'auth_view_model.dart';

/// 启动页：恢复登录态 + 约 2s 启动图展示后按状态全局分流。
/// iOS 参照：HeartHealingMain LaunchScreen.storyboard（launch_bg 满屏 +
/// launch_content 居中 169×245）+ SceneDelegate.scene(willConnect:) 分流。
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  /// 启动图最短展示时长（iOS 原生 LaunchScreen 展示至首帧渲染完成，约 2s）
  static const Duration _minDisplay = Duration(seconds: 2);

  /// LaunchScreen 底色（storyboard #F0F8FC）
  static const Color _backgroundColor = Color(0xFFF0F8FC);

  /// DEV_AUTO_LOGIN 开关（--dart-define=DEV_AUTO_LOGIN=1 或 =true）。
  static const bool _devAutoLoginEnabled =
      bool.fromEnvironment('DEV_AUTO_LOGIN') ||
          String.fromEnvironment('DEV_AUTO_LOGIN') == '1';

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  /// 恢复登录态（异常视为未登录）+ 保证启动图至少展示约 2s，然后分流。
  Future<void> _bootstrap() async {
    await Future.wait([
      ref.read(authControllerProvider.notifier).restore(),
      Future<void>.delayed(SplashPage._minDisplay),
    ]);
    if (!mounted) return;
    // 可分发 Mock 演示包等价于用户已在登录页勾选协议；必须先落标记，
    // 否则账号自动登录成功后 IM 会因隐私协议门禁跳过，导致会话种子不加载。
    if (ApiEnv.isMock && SplashPage._devAutoLoginEnabled) {
      await LyCache.put(
        key: LocalFlags.agreementAccepted,
        value: true,
      );
      if (!mounted) return;
    }
    // DEV_AUTO_LOGIN（仅显式 mock 演示模式，默认关闭）：无登录态时
    // 直接以 dev_mock 单身份 user 假数据登录，跳过登录页直达主端。
    // 开启方式：flutter run/build 加 --dart-define=DEV_AUTO_LOGIN=1。
    // API_ENV=live 真实联调下不生效（必须用真实短信登录）。
    if (ApiEnv.isMock &&
        SplashPage._devAutoLoginEnabled &&
        ref.read(authControllerProvider) == null) {
      try {
        await ref.read(authControllerProvider.notifier).applyLogin(
              LoginData.fromJson(devMockLoginData('13800000000', dual: false)),
            );
      } catch (_) {
        // 存储不可用时忽略，按未登录分流
      }
      if (!mounted) return;
    }
    final data = ref.read(authControllerProvider);
    context.go(resolveEntryRoute(data));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SplashPage._backgroundColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 底图满屏裁切（iOS contentMode scaleAspectFill）
          LoadImage(AppAssets.launchBg, fit: BoxFit.cover),
          // 内容图居中 169×245（iOS contentMode scaleAspectFit）
          Center(
            child: LoadImage(
              AppAssets.launchContent,
              width: AppDimens.launchContentWidth,
              height: AppDimens.launchContentHeight,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}
