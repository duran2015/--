import 'dart:async';

import 'package:fluwx/fluwx.dart' as fluwx;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/network/dev_mock.dart';
import '../../core/storage/local_flags.dart';
import '../../utils/ly_cache.dart';

/// 微信授权登录服务抽象（对齐 iOS XYWechatLoginManager 三段能力：
/// 注册 SDK / 检查安装 / 发起授权拿 code）。
abstract class WechatAuthService {
  /// 注册微信 SDK（AppID + Universal Link）。
  /// iOS 参照：XYWechatLoginManager.registerApp（SceneDelegate 启动序列调用）。
  Future<bool> initialize();

  /// 是否已安装微信。
  /// iOS 参照：XYWechatLoginManager.isWXAppInstalled。
  Future<bool> isWeChatInstalled();

  /// 发起微信授权（snsapi_userinfo），成功返回授权 code（送后端换登录态）。
  /// 用户取消 / 拉起失败 / 授权失败均抛 [WechatAuthException]。
  /// iOS 参照：XYWechatLoginManager.sendAuthRequest。
  Future<String> authCode();

  /// 释放资源（fluwx 取消订阅）。
  void dispose();
}

/// 微信授权异常：[message] 直接用于 AppToast。
class WechatAuthException implements Exception {
  const WechatAuthException(this.message, {this.errCode});

  /// Toast 文案（对齐 iOS/Android 原生提示）
  final String message;

  /// 微信 SDK errCode（-2 用户取消 / -4 拒绝授权等），可为空（如拉起失败）
  final int? errCode;

  @override
  String toString() => 'WechatAuthException($errCode): $message';
}

/// fluwx 真实实现。
/// iOS 参照：XYWechatLoginManager（单例长生命周期持有回调；
/// 此处由 [wechatAuthServiceProvider] 持有，生命周期同 App）。
class FluwxWechatAuthService implements WechatAuthService {
  FluwxWechatAuthService({fluwx.Fluwx? fluwxInstance})
      : _fluwx = fluwxInstance ?? fluwx.Fluwx();

  final fluwx.Fluwx _fluwx;

  /// 微信开放平台 AppID（同步配置在 iOS URL Types / Android WXEntryActivity scheme）
  static const String appId = 'wx75ec09d76033e394';

  /// Universal Link（iOS 微信 SDK 2.0+ 回调方式，需 entitlements applinks +
  /// 服务器 apple-app-site-association；对齐 iOS XYWechatLoginManager）
  static const String universalLink = 'https://api.currantmind.cn/';

  fluwx.FluwxCancelable? _subscription;
  Future<bool>? _registerFuture;

  /// 待处理的授权回调（发起授权时存入，响应时取出并清空，对齐 iOS pendingCompletion）
  Completer<String>? _pendingAuth;

  /// 本次授权请求的 state（响应时校验防串扰，对齐 iOS currentState）
  String? _currentState;

  @override
  Future<bool> initialize() => _ensureRegistered();

  /// 注册只需一次（fluwx registerApi 幂等）；失败不缓存，下次调用重试。
  Future<bool> _ensureRegistered() {
    final accepted =
        LyCache.getSync<bool>(key: LocalFlags.agreementAccepted) ?? false;
    if (!accepted) {
      if (kDebugMode) {
        debugPrint('[WechatAuth] 用户未同意隐私协议，禁止初始化微信 SDK');
      }
      return Future.value(false);
    }
    final pending = _registerFuture;
    if (pending != null) return pending;
    _subscribe();
    final future = _fluwx
        .registerApi(appId: appId, universalLink: universalLink)
        .then((success) {
      if (kDebugMode) {
        debugPrint('[WechatAuth] registerApi success=$success, appId=$appId');
      }
      return success;
    }).catchError((Object e) {
      // 平台通道不可用（如测试环境）时不阻塞：清空缓存待下次重试
      _registerFuture = null;
      if (kDebugMode) debugPrint('[WechatAuth] registerApi error: $e');
      return false;
    });
    _registerFuture = future;
    return future;
  }

  /// 订阅微信响应（服务存活期常驻，对齐 iOS 单例持有 WXApiDelegate）
  void _subscribe() {
    _subscription ??= _fluwx.addSubscriber(_onResponse);
  }

  @override
  Future<bool> isWeChatInstalled() async {
    final accepted =
        LyCache.getSync<bool>(key: LocalFlags.agreementAccepted) ?? false;
    if (!accepted) {
      if (kDebugMode) {
        debugPrint('[WechatAuth] 用户未同意隐私协议，禁止检测微信安装状态');
      }
      return false;
    }
    try {
      return await _fluwx.isWeChatInstalled;
    } catch (_) {
      // 通道不可用（如测试环境）时按未安装处理，走 toast 提示
      return false;
    }
  }

  @override
  Future<String> authCode() async {
    final accepted =
        LyCache.getSync<bool>(key: LocalFlags.agreementAccepted) ?? false;
    if (!accepted) {
      throw const WechatAuthException('请先同意用户协议和隐私政策');
    }
    final registered = await _ensureRegistered();
    if (!registered) {
      throw const WechatAuthException('微信 SDK 初始化失败，请稍后重试');
    }
    if (_pendingAuth != null) {
      throw const WechatAuthException('微信授权处理中，请稍候');
    }
    // state 防串扰（iOS 用 UUID，这里用微秒时间戳即可保证唯一）
    final state = DateTime.now().microsecondsSinceEpoch.toString();
    _currentState = state;
    final completer = Completer<String>();
    _pendingAuth = completer;
    bool sent;
    try {
      sent = await _fluwx.authBy(
        which: fluwx.NormalAuth(scope: 'snsapi_userinfo', state: state),
      );
    } catch (_) {
      sent = false;
    }
    if (!sent) {
      // 拉起失败：清空待处理状态并立即失败（对齐 iOS send(req) completion false）
      _pendingAuth = null;
      _currentState = null;
      throw const WechatAuthException('拉起微信失败');
    }
    return completer.future;
  }

  /// 微信响应回调（对齐 iOS WXApiDelegate.onResp + Android WXEntryActivity.onResp）
  void _onResponse(fluwx.WeChatResponse response) {
    if (response is! fluwx.WeChatAuthResponse) return;
    // 校验 state 防串扰（与发起时一致才处理，对齐 iOS）
    if (response.state != _currentState) return;
    final completer = _pendingAuth;
    _pendingAuth = null;
    _currentState = null;
    if (completer == null) return;
    final code = response.code;
    if (response.isSuccessful && code != null && code.isNotEmpty) {
      if (kDebugMode) debugPrint('[WechatAuth] 授权成功，拿到 code');
      completer.complete(code);
      return;
    }
    completer.completeError(
      WechatAuthException(_failMessage(response), errCode: response.errCode),
    );
  }

  /// 失败文案：用户取消给明确提示（Android WXEntryActivity 文案）；
  /// 其余优先微信 errStr，空则通用文案（对齐 iOS onResp failure 分支）。
  String _failMessage(fluwx.WeChatAuthResponse response) {
    const errUserCancel = -2; // BaseResp.ErrCode.ERR_USER_CANCEL
    if (response.errCode == errUserCancel) return '用户取消授权';
    final errStr = response.errStr;
    if (errStr != null && errStr.isNotEmpty) return errStr;
    return '微信授权失败（code=${response.errCode}）';
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}

/// dev mock 实现：固定 code，免微信环境跑通 wechatLogin 全链路。
class MockWechatAuthService implements WechatAuthService {
  MockWechatAuthService({String? codeToReturn})
      : codeToReturn = codeToReturn ?? debugNextCode;

  /// 调试开关：下次 [authCode] 返回的 code。
  /// - [mockWechatBoundCode]（默认）→ wechatLogin 已绑定，直接登录；
  /// - [mockWechatUnboundCode] → needBindPhone=true，走绑定手机号页。
  static String debugNextCode = mockWechatBoundCode;

  /// 本次 [authCode] 返回的 code
  final String codeToReturn;

  bool _initialized = false;

  @override
  Future<bool> initialize() async {
    _initialized = true;
    return true;
  }

  @override
  Future<bool> isWeChatInstalled() async => true;

  @override
  Future<String> authCode() async {
    if (!_initialized) await initialize();
    return codeToReturn;
  }

  @override
  void dispose() {}
}

/// 按 ApiClient.useMock 选择实现（仅 API_ENV=mock 的 debug / 单测走 mock；
/// 默认 live 与 release 下 useMock=false → 走 fluwx 真实授权）。
final wechatAuthServiceProvider = Provider<WechatAuthService>((ref) {
  final WechatAuthService service =
      ApiClient.useMock ? MockWechatAuthService() : FluwxWechatAuthService();
  ref.onDispose(service.dispose);
  return service;
});
