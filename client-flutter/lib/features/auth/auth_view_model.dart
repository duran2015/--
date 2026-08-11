import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';
import '../../core/router/route_guards.dart';
import '../../core/router/route_paths.dart';
import '../../core/storage/account_store.dart';
import '../../core/storage/local_flags.dart';
import 'auth_api.dart';

final authApiProvider =
    Provider<AuthApi>((ref) => AuthApi(ref.read(apiClientProvider)));

/// 启动/恢复登录态后的入口分流（iOS 参照：HeartHealingMain SceneDelegate）。
/// - 未登录 → /login；
/// - currentIdentity == consultant → /counselor（咨询师工作台）；
/// - availableIdentities 含双身份且未选定（currentIdentity 为空）→ /login/select-identity；
/// - 否则 → /home。
String resolveEntryRoute(LoginData? data) {
  if (data == null || data.accessToken.isEmpty) return RoutePaths.login;
  if (data.currentIdentity == RouteGuards.identityConsultant) {
    return RoutePaths.counselor;
  }
  final identities = data.availableIdentities;
  final current = data.currentIdentity;
  if (identities.length > 1 && (current == null || current.isEmpty)) {
    return RoutePaths.loginSelectIdentity;
  }
  return RoutePaths.home;
}

/// 登录成功后的分流（iOS 参照：XYLoginViewModel.routeByIdentity）。
/// 与启动分流不同：刚登录时只要可用身份多于一个，一律进身份选择页；
/// 单身份按 currentIdentity 直接进对应端。
String resolvePostLoginRoute(LoginData data) {
  return data.currentIdentity == RouteGuards.identityConsultant
      ? RoutePaths.counselor
      : RoutePaths.home;
}

/// 登录流程 ViewModel 状态。
class AuthViewState {
  const AuthViewState({
    this.sending = false,
    this.submitting = false,
    this.serviceAgreementUrl,
    this.serviceAgreementVersion,
    this.privacyPolicyUrl,
    this.privacyPolicyVersion,
  });

  /// 正在发送验证码（登录页主按钮 loading）
  final bool sending;

  /// 正在提交登录/身份选择（验证码页、身份选择页防重复点击）
  final bool submitting;

  /// 用户服务协议链接/版本（agreement/latest 返回，失败用默认链接）
  final String? serviceAgreementUrl;
  final String? serviceAgreementVersion;

  /// 隐私政策链接/版本
  final String? privacyPolicyUrl;
  final String? privacyPolicyVersion;

  AuthViewState copyWith({
    bool? sending,
    bool? submitting,
    String? serviceAgreementUrl,
    String? serviceAgreementVersion,
    String? privacyPolicyUrl,
    String? privacyPolicyVersion,
  }) {
    return AuthViewState(
      sending: sending ?? this.sending,
      submitting: submitting ?? this.submitting,
      serviceAgreementUrl: serviceAgreementUrl ?? this.serviceAgreementUrl,
      serviceAgreementVersion:
          serviceAgreementVersion ?? this.serviceAgreementVersion,
      privacyPolicyUrl: privacyPolicyUrl ?? this.privacyPolicyUrl,
      privacyPolicyVersion: privacyPolicyVersion ?? this.privacyPolicyVersion,
    );
  }
}

/// 登录流程 ViewModel（iOS 参照：XYLoginViewModel + SceneDelegate 分流）。
class AuthViewModel extends Notifier<AuthViewState> {
  @override
  AuthViewState build() => const AuthViewState();

  AuthApi get _api => ref.read(authApiProvider);
  AuthController get _auth => ref.read(authControllerProvider.notifier);
  Future<LocalFlags> get _flags => ref.read(localFlagsProvider.future);

  /// 拉取最新协议跳转地址与版本号（失败保留默认链接，静默处理）。
  /// iOS 参照：XYLoginViewController.loadLatestAgreements。
  Future<void> loadLatestAgreements() async {
    try {
      final latest = await _api.agreementLatest();
      state = state.copyWith(
        serviceAgreementUrl: latest.serviceUrl,
        serviceAgreementVersion: latest.serviceVersion,
        privacyPolicyUrl: latest.privacyUrl,
        privacyPolicyVersion: latest.privacyVersion,
      );
    } catch (_) {
      // 接口失败时保留默认链接（iOS failure 分支为空实现）
    }
  }

  /// 登录页发送验证码（契约 §1 #2 登录场景，免鉴权）。
  Future<void> sendLoginSmsCode(String phone) async {
    state = state.copyWith(sending: true);
    try {
      await _api.sendSmsCode(phone);
    } finally {
      state = state.copyWith(sending: false);
    }
  }

  /// 验证码页重发验证码（不含页面 loading 态）。
  Future<void> resendSmsCode(String phone) => _api.sendSmsCode(phone);

  /// 手机号验证码登录：成功持久化登录态 + 上报协议同意，返回分流路由。
  /// iOS 参照：XYVerificationCodeViewController.submitVerification（login 模式）。
  Future<String> loginByPhone({
    required String phone,
    required String smsCode,
  }) async {
    state = state.copyWith(submitting: true);
    try {
      final data = await _api.loginByPhone(phone: phone, smsCode: smsCode);
      // token 校验（iOS：返回数据缺少 token 判失败）
      if (data.accessToken.isEmpty) {
        throw const ApiException(code: -1, msg: '登录失败：返回数据缺少 token');
      }
      await _auth.applyLogin(data);
      // 登录成功后提交协议同意记录（仅当已勾选且版本号齐全，失败静默）
      await _submitAgreementConsentIfNeeded(phone: phone, data: data);
      return _resolveAfterLogin(data);
    } finally {
      state = state.copyWith(submitting: false);
    }
  }

  /// 微信授权登录（契约 §1 #3）。
  /// iOS 参照：XYLoginViewController.handleWeChatLoginCode +
  /// XYLoginViewModel.loginByWeChat。
  /// needBindPhone=false 时校验并持久化登录态（iOS persistLogin 在成功回调内
  /// 完成），路由由页面按 [resolvePostLoginRoute] 决定；
  /// needBindPhone=true 时原样返回（含 nickName/avatar/preAuthToken），
  /// 由页面跳绑定手机号页。
  Future<WechatLoginData> loginByWechat(String code) async {
    state = state.copyWith(submitting: true);
    try {
      final result = await _api.wechatLogin(code);
      if (!result.needBindPhone) {
        final data = result.loginData;
        if (data == null || data.accessToken.isEmpty) {
          throw const ApiException(code: -1, msg: '微信登录态异常');
        }
        await _auth.applyLogin(data);
      }
      return result;
    } finally {
      state = state.copyWith(submitting: false);
    }
  }

  /// Apple 授权登录（POST /app/auth/appleLogin）。
  /// iOS 参照：XYLoginViewController.handleAppleLoginCredential +
  /// XYLoginViewModel.loginByApple。分流同 [loginByWechat]。
  Future<WechatLoginData> loginByApple({
    required String identityToken,
    String? nickName,
  }) async {
    state = state.copyWith(submitting: true);
    try {
      final result = await _api.appleLogin(
        identityToken: identityToken,
        nickName: nickName,
      );
      if (!result.needBindPhone) {
        final data = result.loginData;
        if (data == null || data.accessToken.isEmpty) {
          throw const ApiException(code: -1, msg: 'Apple 登录态异常');
        }
        await _auth.applyLogin(data);
      }
      return result;
    } finally {
      state = state.copyWith(submitting: false);
    }
  }

  /// 微信/Apple 绑定手机号登录（契约 §1 #4）：成功持久化登录态，返回分流路由。
  /// iOS 参照：XYVerificationCodeViewController.submitVerification
  /// （wechatBind 模式）+ XYLoginViewModel.bindPhoneByWeChat。
  /// 绑定场景不提交协议同意记录（iOS 仅 login 模式提交）。
  Future<String> bindPhoneByWechat({
    required String phone,
    required String smsCode,
    required String preAuthToken,
  }) async {
    state = state.copyWith(submitting: true);
    try {
      final data = await _api.bindPhoneLogin(
        preAuthToken: preAuthToken,
        phone: phone,
        smsCode: smsCode,
      );
      if (data.accessToken.isEmpty) {
        throw const ApiException(code: -1, msg: '绑定失败：返回数据缺少 token');
      }
      await _auth.applyLogin(data);
      return _resolveAfterLogin(data);
    } finally {
      state = state.copyWith(submitting: false);
    }
  }

  /// 身份选择：调 selectIdentity，用返回的新身份/IM 凭证局部更新登录态。
  /// iOS 参照：XYRoleSelectionViewController.roleCardTapped +
  /// XYAccountManager.selectIdentity。
  /// 返回分流路由（consultant → /counselor，否则 /home）。
  Future<String> selectIdentity(String identity) async {
    state = state.copyWith(submitting: true);
    try {
      final result = await _api.selectIdentity(identity);
      final current = ref.read(authControllerProvider);
      if (current == null) {
        throw const ApiException(code: -1, msg: '登录态缺失，请重新登录');
      }
      final updated = current.copyWith(
        currentIdentity: result.currentIdentity ?? identity,
        availableIdentities: result.availableIdentities,
        consultantId: result.consultantId,
        imUserId: result.imUserId,
        imUserSig: result.imUserSig,
      );
      await _auth.applyLogin(updated);
      final flags = await _flags;
      await flags.saveLastIdentity(
        updated.userId ?? updated.phone ?? 'local',
        updated.currentIdentity ?? identity,
      );
      return updated.currentIdentity == RouteGuards.identityConsultant
          ? RoutePaths.counselor
          : RoutePaths.home;
    } finally {
      state = state.copyWith(submitting: false);
    }
  }

  /// 登录后自动恢复身份：显式登录意图 > 本机最近身份 > 服务端当前身份 > 用户。
  /// 尚无咨询师身份但选择咨询师时进入入驻流程，不伪造咨询师权限。
  Future<String> _resolveAfterLogin(LoginData data) async {
    final flags = await _flags;
    final intent = await flags.consumeLoginIdentityIntent();
    final accountId = data.userId ?? data.phone ?? 'local';
    final desired = intent ??
        flags.lastIdentityFor(accountId) ??
        data.currentIdentity ??
        RouteGuards.identityUser;
    if (desired == RouteGuards.identityConsultant &&
        !data.availableIdentities.contains(RouteGuards.identityConsultant)) {
      if (data.currentIdentity != RouteGuards.identityUser) {
        await _auth.applyLogin(
          data.copyWith(currentIdentity: RouteGuards.identityUser),
        );
      }
      return RoutePaths.counselor;
    }
    if (data.currentIdentity != desired) {
      return selectIdentity(desired);
    }
    await flags.saveLastIdentity(accountId, desired);
    return desired == RouteGuards.identityConsultant
        ? RoutePaths.counselor
        : RoutePaths.home;
  }

  /// 第三方登录已完成落库后复用同一身份恢复策略。
  Future<String> resolveAfterExternalLogin(LoginData data) =>
      _resolveAfterLogin(data);

  /// 登录成功后提交协议同意记录（契约 §1 #8；失败静默）。
  /// iOS 参照：XYVerificationCodeViewController.submitAgreementConsentIfNeeded
  /// （仅登录模式提交；userId 缺失则跳过）。
  Future<void> _submitAgreementConsentIfNeeded({
    required String phone,
    required LoginData data,
  }) async {
    final serviceVersion = state.serviceAgreementVersion;
    final privacyVersion = state.privacyPolicyVersion;
    final userId = data.userId;
    if (serviceVersion == null ||
        serviceVersion.isEmpty ||
        privacyVersion == null ||
        privacyVersion.isEmpty ||
        userId == null ||
        userId.isEmpty) {
      return;
    }
    try {
      final flags = await _flags;
      final deviceId = await flags.ensureDeviceId();
      await _api.agreementConsent(
        serviceVersion: serviceVersion,
        privacyVersion: privacyVersion,
        phone: phone,
        deviceId: deviceId,
        userId: userId,
      );
    } catch (_) {
      // iOS success/failure 均为空实现：consent 上报失败不阻断登录
    }
  }
}

final authViewModelProvider =
    NotifierProvider<AuthViewModel, AuthViewState>(AuthViewModel.new);
