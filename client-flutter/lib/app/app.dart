import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../core/consult_room/consult_room_float_widget.dart';
import '../core/consult_room/consult_room_service.dart';
import '../core/im/im_session_controller.dart';
import '../core/im/middle_card_unread.dart';
import '../core/services/app_badge_service.dart';
import '../features/message/message_view_model.dart';
import '../core/theme/app_colors.dart';
import 'navigation.dart';
import 'router.dart';

class XinyuApp extends ConsumerStatefulWidget {
  const XinyuApp({super.key});

  @override
  ConsumerState<XinyuApp> createState() => _XinyuAppState();
}

class _XinyuAppState extends ConsumerState<XinyuApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    // 回前台时云信 APNS 可能已把图标设成服务端值，用本地总未读重新覆盖。
    WidgetsBinding.instance.addObserver(this);
    // 冷启动即用本地总未读覆盖上次推送残留的图标数字。
    AppBadgeService.setCount(ref.read(appIconBadgeProvider));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      AppBadgeService.setCount(ref.read(appIconBadgeProvider));
    }
  }

  @override
  Widget build(BuildContext context) {
    // 桌面图标角标 = 本地总未读（消息 Tab 普通+系统 + 小鹿机器人），
    // 覆盖云信 APNS aps.badge，使图标与 App 内同源同值。
    // 初值在 initState 已写入；此处随未读变化持续同步。
    ref.listen<int>(
      appIconBadgeProvider,
      (_, count) => AppBadgeService.setCount(count),
    );
    // IM 登录闭环接线（登录/登出/身份切换/userSig 过期/被踢下线；
    // iOS 参照：SceneDelegate.setupIMSDK + XYSessionManager）
    ref.watch(imSessionControllerProvider);
    // 咨询师端：后台伪装本端发出的 *_middle 卡本地未读补偿
    ref.watch(middleCardUnreadBinderProvider);
    // 咨询室「聊天」全局导航：不依赖 /consult-room 桥接页存活
    // 用 ref.read（非 watch）：service 已是 ChangeNotifier，watch 会让每次
    // notifyListeners 重建整个 MaterialApp.router；悬浮窗子树自行 ListenableBuilder
    // 监听，把重建隔离到悬浮窗范围内。
    final consultRoomService = ref.read(consultRoomServiceProvider);
    bindConsultRoomNavigation(consultRoomService);
    final router = ref.watch(routerProvider);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.brandTeal,
      brightness: Brightness.light,
    ).copyWith(
      primary: const Color(0xFF006A67),
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFF9EF2EC),
      onPrimaryContainer: const Color(0xFF00201F),
      secondary: const Color(0xFF65558F),
      secondaryContainer: const Color(0xFFE9DDFF),
      surface: const Color(0xFFF8FAF8),
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: const Color(0xFFF2F5F3),
      surfaceContainer: const Color(0xFFECF0EE),
      surfaceContainerHigh: const Color(0xFFE6EAE8),
      outline: const Color(0xFF6F7977),
      outlineVariant: const Color(0xFFBEC9C6),
      error: const Color(0xFFBA1A1A),
    );
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      child: MaterialApp.router(
        title: '可鹿心理',
        debugShowCheckedModeBanner: false,
        routerConfig: router,
        // 全局关闭系统「更大字体」缩放：app 按 iOS 固定度量绘制，文字保持原始尺寸。
        // 图片本就不受 textScaler 影响（固定尺寸图照旧、满宽/满高图照常铺满）。
        builder: (context, child) {
          final mq = MediaQuery.of(context);
          // 通话最小化悬浮窗挂在所有路由之上（含 /chat、fullscreenDialog 咨询页）；
          // 不可见时 ConsultRoomFloatHost 返回 SizedBox.shrink()，零开销。
          return Stack(
            children: [
              Positioned.fill(
                child: MediaQuery(
                  data: mq.copyWith(
                    textScaler: mq.textScaler.clamp(maxScaleFactor: 1.0),
                  ),
                  child: child!,
                ),
              ),
              ConsultRoomFloatHost(service: consultRoomService),
            ],
          );
        },
        theme: ThemeData(
          colorScheme: colorScheme,
          useMaterial3: true,
          scaffoldBackgroundColor: colorScheme.surface,
          splashFactory: InkSparkle.splashFactory,
          visualDensity: VisualDensity.standard,
          textTheme: const TextTheme(
            displaySmall: TextStyle(fontSize: 32, fontWeight: FontWeight.w600),
            headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
            titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            bodyLarge: TextStyle(fontSize: 16, height: 1.5),
            bodyMedium: TextStyle(fontSize: 14, height: 1.45),
            labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ).apply(
            bodyColor: const Color(0xFF191C1B),
            displayColor: const Color(0xFF191C1B),
          ),
          cardTheme: CardThemeData(
            color: colorScheme.surfaceContainerLowest,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.55)),
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              minimumSize: const Size(64, 52),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              textStyle:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(64, 52),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              side: BorderSide(color: colorScheme.outline),
              textStyle:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: colorScheme.surfaceContainerLow,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: colorScheme.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
          ),
          navigationBarTheme: NavigationBarThemeData(
            height: 72,
            elevation: 0,
            backgroundColor: colorScheme.surfaceContainerLowest,
            indicatorColor: colorScheme.primaryContainer,
            indicatorShape: const StadiumBorder(),
            labelTextStyle:
                WidgetStateProperty.resolveWith((states) => TextStyle(
                      fontSize: 12,
                      fontWeight: states.contains(WidgetState.selected)
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: states.contains(WidgetState.selected)
                          ? colorScheme.onSurface
                          : colorScheme.onSurfaceVariant,
                    )),
          ),
          bottomSheetTheme: BottomSheetThemeData(
            backgroundColor: colorScheme.surfaceContainerLowest,
            surfaceTintColor: Colors.transparent,
            showDragHandle: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
          ),
          dialogTheme: DialogThemeData(
            backgroundColor: colorScheme.surfaceContainerHigh,
            surfaceTintColor: Colors.transparent,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            centerTitle: false,
            systemOverlayStyle: SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.dark,
              statusBarBrightness: Brightness.light,
              systemNavigationBarColor: Colors.transparent,
              systemNavigationBarDividerColor: Colors.transparent,
              systemNavigationBarIconBrightness: Brightness.dark,
              systemNavigationBarContrastEnforced: false,
            ),
          ),
        ),
      ),
    );
  }
}
