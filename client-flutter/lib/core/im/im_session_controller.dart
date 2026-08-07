import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../app/navigation.dart';
import '../../utils/ly_cache.dart';
import '../auth/auth_controller.dart';
import '../consult_room/consult_room_service.dart';
import '../services/app_badge_service.dart';
import '../storage/account_store.dart';
import '../storage/local_flags.dart';
import '../widgets/app_dialog.dart';
import 'im_service.dart';

/// IM 登录闭环接线（iOS 参照：HeartHealingMain SceneDelegate +
/// XYSessionManager + XYAccountManager 联动）。
///
/// 职责：
/// 1. 登录态变化 → IM login/logout：
///    - applyLogin / restore 后有 imUserId+imUserSig → IM 登录
///      （iOS 参照：SceneDelegate.setupIMSDK；imUserId 缺失回退 app userId，
///      imUserSig 缺失跳过 IM 登录）；
///    - selectIdentity 换凭证（imUserId/imUserSig 变化）→ 先登出再以新凭证
///      登录（iOS 参照：SceneDelegate.reloginIMForSwitchedRole）；
///    - logout → IM 登出（经 AuthController.onImLogout 钩子接入）。
/// 2. userSig 过期（服务层已 60s 节流）→ 弹「登录已过期」→ 确认 → 登出
///    （iOS 参照：XYSessionManager.handleSessionExpired(.imUserSigExpired)）。
/// 3. 被踢下线 → 弹「账号已下线」→ 确认 → 登出回 /login
///    （iOS 参照：XYSessionManager.handleSessionExpired(.imKickedOffline)；
///    回登录页由路由层监听登录态自动 redirect 完成）。
class ImSessionController extends Notifier<bool> {
  /// 当前已登录 IM 的凭证指纹（imUserId + imUserSig），用于检测身份切换
  String? _loggedCreds;

  /// 过期弹窗防抖（iOS 参照：XYSessionManager.isHandlingExpired）
  bool _handlingExpired = false;

  ImService get _im => ref.read(imServiceProvider);

  @override
  bool build() {
    final service = _im;
    // 提前捕获：onDispose 回调触发时容器可能已开始销毁，不能再 read
    final auth = ref.read(authControllerProvider.notifier);

    // IM 事件回调 → 业务闭环
    service.onLoginSuccess = () {
      state = true;
    };
    service.onUserSigExpired = () {
      unawaited(_handleSessionExpired(
        title: '登录已过期',
        content: 'IM 登录凭证已过期，请重新登录',
      ));
    };
    service.onKickedOffline = () {
      unawaited(_handleSessionExpired(
        title: '账号已下线',
        content: '您的账号在另一台设备登录，请重新登录',
      ));
    };

    // AuthController.logout → IM 登出（iOS 参照：XYSessionManager.performLogout
    // 内 XYIMManager.logout 后台执行，失败不影响切登录页）
    auth.onImLogout = () {
      unawaited(_logoutIm());
    };

    // 登录态变化 → 同步 IM（登录/身份切换/登出）
    ref.listen(authControllerProvider, (previous, next) {
      unawaited(_syncWithAuth(next));
    });

    // 启动恢复（restore）后若已有登录态，立即后台登录 IM
    // （iOS 参照：SceneDelegate.setupIMSDK 用本地缓存凭证后台登录）
    unawaited(_syncWithAuth(ref.read(authControllerProvider)));

    ref.onDispose(() {
      service.onLoginSuccess = null;
      service.onUserSigExpired = null;
      service.onKickedOffline = null;
      auth.onImLogout = null;
    });

    return false;
  }

  /// 按登录态同步 IM 登录状态。
  Future<void> _syncWithAuth(LoginData? data) async {
    final service = _im;
    if (data == null) {
      // 登出由 onImLogout 钩子统一处理，这里兜底（state 直接置空的路径）
      if (service.isLoggedIn) await _logoutIm();
      return;
    }
    // 校验隐私协议是否已同意
    final accepted =
        LyCache.getSync<bool>(key: LocalFlags.agreementAccepted) ?? false;
    if (!accepted) {
      debugPrint('⚠️ [XYIM] 未同意隐私协议，跳过 IM SDK 登录');
      return;
    }
    // iOS 参照：SceneDelegate.setupIMSDK —— userID 缺失回退 app userId；
    // imUserSig 缺失跳过 IM 登录
    final imUserId = (data.imUserId == null || data.imUserId!.isEmpty)
        ? data.userId
        : data.imUserId;
    final imUserSig = data.imUserSig;
    if (imUserId == null ||
        imUserId.isEmpty ||
        imUserSig == null ||
        imUserSig.isEmpty) {
      debugPrint('⚠️ [XYIM] 跳过 IM 登录：本地缺少 imUserId/imUserSig');
      return;
    }
    final creds = '$imUserId|$imUserSig';
    if (service.isLoggedIn && _loggedCreds == creds) return;

    if (service.isLoggedIn && _loggedCreds != creds) {
      // 身份切换：先登出再以新凭证登录
      // （iOS 参照：SceneDelegate.reloginIMForSwitchedRole；
      // logout 内部已让出一轮事件循环规避 unInitSDK 竞态）
      await _logoutIm();
    }
    try {
      await service.login(imUserId: imUserId, imUserSig: imUserSig);
      _loggedCreds = creds;
      state = true;
      // Android 13+（API 33）需运行期申请通知权限，否则离线推送到达也不显示横幅。
      // best-effort：拒绝不影响 IM 收发（仅无系统通知）；iOS 授权在 AppDelegate 内处理。
      if (!kIsWeb && Platform.isAndroid) {
        unawaited(Permission.notification.request().catchError((_) => PermissionStatus.denied));
      }
    } on ImException catch (e) {
      debugPrint('🔴 [XYIM] IM 登录失败：${e.code} ${e.desc}');
    } catch (e) {
      debugPrint('🔴 [XYIM] IM 登录异常：$e');
    }
  }

  Future<void> _logoutIm() async {
    _loggedCreds = null;
    state = false;
    // 身份切换/登出：咨询室通话绑定的是旧 IM 身份（NERtc uid 由 imUserId 推导），
    // 必须挂断当前通话，否则会残留一个用旧身份的会话/悬浮窗。exitRoom 对无会话态是 no-op。
    try {
      await ref.read(consultRoomServiceProvider).exitRoom();
    } catch (e) {
      debugPrint('🟠 [XYIM] 身份切换/登出挂断咨询室异常：$e');
    }
    try {
      await _im.logout();
    } catch (e) {
      debugPrint('🔴 [XYIM] IM 登出异常（不影响本地登出）：$e');
    }
    // 登出/身份切换：清除桌面图标角标（本地总未读已无意义，避免残留上一个账号的数字）。
    unawaited(AppBadgeService.setCount(0));
  }

  /// 过期统一处理：弹提示 → 确认 → 本地登出（防抖）。
  /// iOS 参照：XYSessionManager.handleSessionExpired + performLogout。
  Future<void> _handleSessionExpired({
    required String title,
    required String content,
  }) async {
    if (_handlingExpired) return;
    _handlingExpired = true;
    try {
      final context = rootNavigatorKey.currentContext;
      if (context != null) {
        await AppCenterDialog.show(
          context,
          title: title,
          content: content,
          confirmText: '确认',
        );
      }
      // 立即清账号 → 路由监听登录态自动回 /login（不等 IM，token 已失效
      // 不调服务端 logout；IM 登出经 onImLogout 钩子后台完成）
      await ref.read(authControllerProvider.notifier).logout();
    } finally {
      _handlingExpired = false;
    }
  }
}

/// IM 登录闭环控制器（state = IM 是否已登录）。
/// 在 app 根部 watch 一次即完成全部接线。
final imSessionControllerProvider =
    NotifierProvider<ImSessionController, bool>(ImSessionController.new);
