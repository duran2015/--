import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client.dart';
import '../storage/account_store.dart';

/// 登录态控制器（整合原 auth_state.dart，参照 iOS XYAccountManager）。
/// 持有 LoginData?：
/// - 登录成功 → 写存储 + 更新状态（具体登录接口调用属阶段 1，不在此实现）；
/// - 登出 → 清存储 + 清状态 + IM 登出回调钩子；
/// - restore() → 启动时从存储恢复；
/// - 向 ApiClient 注册 onSessionExpired → HTTP 401 / 业务 code==401 统一登出
///   （契约 §0，回登录页由路由层监听登录态完成）。
class AuthController extends Notifier<LoginData?> {
  @override
  LoginData? build() {
    ApiClient.onSessionExpired = _handleSessionExpired;
    return null;
  }

  AccountStore get _accountStore => ref.read(accountStoreProvider);

  /// IM 登出回调钩子：由 IM 模块注册（对应 iOS 登出时同步登出 IM）。
  void Function()? onImLogout;

  /// 登录成功落库：持久化 + 更新状态。
  Future<void> applyLogin(LoginData data) async {
    await _accountStore.save(data);
    state = data;
  }

  /// 启动恢复：从 secure storage 还原登录态（无登录态时为 null）。
  /// 存储不可用（如测试环境无平台通道）时吞掉异常，视为未登录；
  /// 加超时兜底：平台通道无响应（挂起）时同样按未登录处理。
  /// Android 适配：EncryptedSharedPreferences 首次初始化（Keystore 主密钥 +
  /// Tink keyset）在冷启动可超过 3s，实测 3s 超时会把真实登录态误判为
  /// 未登录而掉回登录页（token 实际完好）。放宽到 12s，避免「读得慢」
  /// 被当作「没登录」。
  Future<void> restore() async {
    try {
      state = await _accountStore.read().timeout(
            const Duration(seconds: 12),
            onTimeout: () => null,
          );
    } catch (_) {
      state = null;
    }
  }

  /// 登出：先清内存态（路由立刻回登录页），再后台清存储 + IM 登出。
  /// iOS 参照：XYAccountSecurityViewModel.logout——本地态立即清空，
  /// 存储/IM 不阻塞切登录页。存储异常不阻断状态清理。
  Future<void> logout() async {
    // 先清内存态，GoRouter redirect 立刻回 /login（不等待 secure storage）
    state = null;
    onImLogout?.call();
    try {
      await _accountStore.clear();
    } catch (_) {
      // 忽略存储异常
    }
  }

  /// 网络层 401 统一入口 → 登出（契约 §0）。
  void _handleSessionExpired() {
    logout();
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, LoginData?>(AuthController.new);

/// accountProvider：登录态读取入口（存储见 account_store.dart；
/// 启动时经 `ref.read(authControllerProvider.notifier).restore()` 恢复）。
final accountProvider = authControllerProvider;
