import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/network/api_response.dart';
import '../auth/auth_view_model.dart';
import 'mine_api.dart';

/// 注销账号页 ViewModel provider：按当前登录态装配手机号/身份与接口依赖。
/// iOS 参照：XYCancelAccountViewModel（XYAccountManager 取手机号与身份）。
final cancelAccountViewModelProvider = Provider<CancelAccountViewModel>((ref) {
  final account = ref.watch(accountProvider);
  final authApi = ref.read(authApiProvider);
  final mineApi = ref.read(mineApiProvider);
  return CancelAccountViewModel(
    phone: account?.phone,
    identity: account?.currentIdentity,
    sendSmsCodeFn: authApi.sendSmsCode,
    deactivateFn: mineApi.deactivate,
    logoutFn: () => ref.read(authControllerProvider.notifier).logout(),
  );
});

/// 注销账号页 ViewModel。
/// iOS 参照：XYMineModule/XYMineModule/Classes/ViewModel/
/// XYCancelAccountViewModel.swift。
///
/// 依赖全部可注入，便于单测（scene 按身份、注销后 logout 调用）。
class CancelAccountViewModel {
  CancelAccountViewModel({
    required this.phone,
    required this.identity,
    required Future<String> Function(String phone, {String? scene})
        sendSmsCodeFn,
    required Future<void> Function({required String phone, required String smsCode})
        deactivateFn,
    required Future<void> Function() logoutFn,
  })  : _sendSmsCodeFn = sendSmsCodeFn,
        _deactivateFn = deactivateFn,
        _logoutFn = logoutFn;

  /// 当前绑定手机号（本地登录态读取）
  final String? phone;

  /// 当前身份（user / consultant）
  final String? identity;

  final Future<String> Function(String phone, {String? scene}) _sendSmsCodeFn;
  final Future<void> Function({required String phone, required String smsCode})
      _deactivateFn;
  final Future<void> Function() _logoutFn;

  /// 当前绑定手机号（脱敏展示）。
  /// iOS 参照：XYCancelAccountViewModel.maskedPhone。
  String get maskedPhone {
    final p = phone ?? '';
    if (p.length != 11) return '已绑定手机号：$p';
    return '已绑定手机号：${p.substring(0, 3)}****${p.substring(7)}';
  }

  /// 注销场景 scene：咨询师端 deactivate_consultant，其余 deactivate_user。
  /// iOS 参照：XYCancelAccountViewModel.sendSMSCode（role == .counselor）。
  String get scene =>
      identity == 'consultant' ? 'deactivate_consultant' : 'deactivate_user';

  /// 发送短信验证码（POST /app/auth/sendSmsCode，带 scene，requireAuth=true）。
  /// iOS 参照：XYCancelAccountViewModel.sendSMSCode。
  Future<String> sendSmsCode() async {
    final p = phone ?? '';
    if (p.isEmpty) {
      throw const ApiException(code: -1, msg: '手机号缺失');
    }
    return _sendSmsCodeFn(p, scene: scene);
  }

  /// 验证并注销账号（POST /app/mine/deactivate）。
  /// iOS 参照：XYCancelAccountViewModel.cancelAccount。
  Future<void> deactivate(String code) async {
    final p = phone ?? '';
    if (p.isEmpty) {
      throw const ApiException(code: -1, msg: '手机号缺失');
    }
    if (code.length != 6) {
      throw const ApiException(code: -1, msg: '请输入6位验证码');
    }
    return _deactivateFn(phone: p, smsCode: code);
  }

  /// 注销成功后的登出调度：延迟后清登录态（AuthController.logout 内含 IM 登出钩子，
  /// 路由监听登录态自动回 /login）。
  /// iOS 参照：XYCancelAccountViewController.confirmTapped——延迟 2s 再
  /// XYAccountManager.logout + XYIMManager.logout，避免转场吞掉「注销成功」toast。
  Future<void> logoutAfterSuccess({
    Duration delay = const Duration(seconds: 2),
  }) async {
    await Future<void>.delayed(delay);
    await _logoutFn();
  }
}
