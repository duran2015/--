import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';
import '../../core/storage/account_store.dart';

/// 鉴权与协议接口封装（契约 contracts/api_contract.md §1 #1-#8）。
/// iOS 参照：XYLoginModule XYLoginViewModel 中各 postJSON 调用。
class AuthApi {
  AuthApi(this._client);

  final ApiClient _client;

  /// postData 返回可空：data 缺失时按失败处理（iOS 网络层判 data 非空）。
  Future<T> _required<T>(Future<T?> call, String what) async {
    final data = await call;
    if (data == null) {
      throw ApiException(code: -1, msg: '$what失败：返回数据为空');
    }
    return data;
  }

  // ---------- 路径常量（契约 §1） ----------
  static const loginByPhonePath = '/app/auth/loginByPhone'; // #1
  static const sendSmsCodePath = '/app/auth/sendSmsCode'; // #2
  static const wechatLoginPath = '/app/auth/wechatLogin'; // #3
  static const appleLoginPath = '/app/auth/appleLogin'; // Apple（iOS XYLoginViewModel）
  static const bindPhoneLoginPath = '/app/auth/bindPhoneLogin'; // #4
  static const selectIdentityPath = '/app/auth/selectIdentity'; // #5
  static const logoutPath = '/app/auth/logout'; // #6
  static const agreementLatestPath = '/app/agreement/latest'; // #7
  static const agreementConsentPath = '/app/agreement/consent'; // #8

  /// 协议 consent 上报 channel：iOS=2（iOS XYLoginViewModel 实传 2）。
  static const agreementChannelIos = 2;

  /// 协议 consent 上报 channel：Android/Flutter 值。
  /// ⚠ 待后端确认（契约 §1 #8：Android 前端未见该接口，暂定义为 1）。
  static const agreementChannel = 1;

  /// #1 手机号验证码登录（免鉴权）。
  Future<LoginData> loginByPhone({
    required String phone,
    required String smsCode,
  }) {
    return _required(
      _client.postData<LoginData>(
        loginByPhonePath,
        {'phone': phone, 'smsCode': smsCode},
        requireAuth: false,
        decoder: (json) =>
            LoginData.fromJson(Map<String, dynamic>.from(json as Map)),
      ),
      '登录',
    );
  }

  /// #2 发送短信验证码。
  /// [scene]：注销场景传 `deactivate_user` / `deactivate_consultant`
  /// （iOS XYCancelAccountViewModel 实传且 requireAuth=true）；
  /// 登录场景不传（免鉴权）。
  Future<String> sendSmsCode(String phone, {String? scene}) {
    return _client.postMessage(
      sendSmsCodePath,
      {
        'phone': phone,
        if (scene != null) 'scene': scene,
      },
      requireAuth: scene != null,
    );
  }

  /// #3 微信授权登录（免鉴权）。
  /// needBindPhone=true → nickName/avatar/preAuthToken；false → 登录态平铺同节点。
  Future<WechatLoginData> wechatLogin(String code) {
    return _required(
      _client.postData<WechatLoginData>(
        wechatLoginPath,
        {'code': code, 'platform': 'app'},
        requireAuth: false,
        decoder: (json) =>
            WechatLoginData.fromJson(Map<String, dynamic>.from(json as Map)),
      ),
      '微信登录',
    );
  }

  /// Apple 授权登录（免鉴权）。
  /// iOS 参照：XYLoginViewModel.loginByApple（POST /app/auth/appleLogin）。
  /// 响应形态与微信一致（复用 [WechatLoginData]）。
  Future<WechatLoginData> appleLogin({
    required String identityToken,
    String? nickName,
  }) {
    return _required(
      _client.postData<WechatLoginData>(
        appleLoginPath,
        {
          'identityToken': identityToken,
          if (nickName != null && nickName.isNotEmpty) 'nickName': nickName,
        },
        requireAuth: false,
        decoder: (json) =>
            WechatLoginData.fromJson(Map<String, dynamic>.from(json as Map)),
      ),
      'Apple 登录',
    );
  }

  /// #4 微信/Apple 登录绑定手机号（免鉴权）。
  Future<LoginData> bindPhoneLogin({
    required String preAuthToken,
    required String phone,
    required String smsCode,
  }) {
    return _required(
      _client.postData<LoginData>(
        bindPhoneLoginPath,
        {'preAuthToken': preAuthToken, 'phone': phone, 'smsCode': smsCode},
        requireAuth: false,
        decoder: (json) =>
            LoginData.fromJson(Map<String, dynamic>.from(json as Map)),
      ),
      '绑定',
    );
  }

  /// #5 选择/切换身份（鉴权）。返回新 currentIdentity / imUserId / imUserSig。
  Future<SelectIdentityResult> selectIdentity(String identity) {
    return _required(
      _client.postData<SelectIdentityResult>(
        selectIdentityPath,
        {'identity': identity},
        decoder: (json) => SelectIdentityResult.fromJson(
            Map<String, dynamic>.from(json as Map)),
      ),
      '切换身份',
    );
  }

  /// #6 登出（鉴权）。
  Future<String> logout() => _client.postMessage(logoutPath, const {});

  /// #7 最新协议跳转地址与版本（免鉴权）。
  Future<AgreementLatest> agreementLatest() {
    return _required(
      _client.postData<AgreementLatest>(
        agreementLatestPath,
        const {},
        requireAuth: false,
        decoder: (json) =>
            AgreementLatest.fromJson(Map<String, dynamic>.from(json as Map)),
      ),
      '获取协议',
    );
  }

  /// #8 提交协议勾选同意（鉴权，登录成功后调用）。
  /// iOS 参照：XYLoginViewModel.submitAgreementConsent（items 固定两项：
  /// 1=用户服务协议，2=隐私政策；userId 可转 Int 时按数字上传）。
  Future<String> agreementConsent({
    required String serviceVersion,
    required String privacyVersion,
    required String phone,
    required String deviceId,
    String? userId,
  }) {
    final userIdInt = int.tryParse(userId ?? '');
    return _client.postMessage(
      agreementConsentPath,
      {
        'items': [
          {'agreementType': 1, 'version': serviceVersion},
          {'agreementType': 2, 'version': privacyVersion},
        ],
        'channel': agreementChannel,
        'deviceId': deviceId,
        'phone': phone,
        'userId': userIdInt ?? userId,
      },
    );
  }
}

/// 微信登录接口返回（契约 §1 #3）。
/// iOS 参照：XYLoginModels.XYWechatLoginData。
class WechatLoginData {
  const WechatLoginData({
    required this.needBindPhone,
    this.nickName,
    this.avatar,
    this.preAuthToken,
    this.loginData,
  });

  /// 是否需要绑定手机号（true → 跳绑定页；false → 已绑定，loginData 含登录态）
  final bool needBindPhone;
  final String? nickName;
  final String? avatar;

  /// 绑定临时凭证（needBindPhone=true 时有值）
  final String? preAuthToken;

  /// 登录态（needBindPhone=false 时从同节点平铺字段解析，同 loginByPhone 结构）
  final LoginData? loginData;

  factory WechatLoginData.fromJson(Map<String, dynamic> json) {
    final needBind = json['needBindPhone'] as bool? ?? false;
    return WechatLoginData(
      needBindPhone: needBind,
      nickName: json['nickName']?.toString(),
      avatar: json['avatar']?.toString(),
      preAuthToken: json['preAuthToken']?.toString(),
      // 已绑定时 data 平铺登录态字段，复用 LoginData 从同节点解析
      loginData: needBind ? null : LoginData.fromJson(json),
    );
  }
}

/// selectIdentity 返回（契约 §1 #5）：
/// 新 currentIdentity / availableIdentities / consultantId / imUserId / imUserSig
/// （iOS XYSelectIdentityData：全量刷新本地身份与 IM 凭证）。
class SelectIdentityResult {
  const SelectIdentityResult({
    this.currentIdentity,
    this.availableIdentities,
    this.consultantId,
    this.imUserId,
    this.imUserSig,
  });

  final String? currentIdentity;
  final List<String>? availableIdentities;
  final String? consultantId;
  final String? imUserId;
  final String? imUserSig;

  factory SelectIdentityResult.fromJson(Map<String, dynamic> json) {
    return SelectIdentityResult(
      currentIdentity: json['currentIdentity']?.toString(),
      availableIdentities: (json['availableIdentities'] as List?)
          ?.map((e) => e.toString())
          .toList(),
      consultantId: json['consultantId']?.toString(),
      imUserId: json['imUserId']?.toString(),
      imUserSig: json['imUserSig']?.toString(),
    );
  }
}

/// 最新协议跳转地址与版本（契约 §1 #7：data.user / data.privacy）。
/// iOS 参照：XYLoginModels.XYAgreementLatestData。
class AgreementLatest {
  const AgreementLatest({
    this.serviceUrl,
    this.serviceVersion,
    this.privacyUrl,
    this.privacyVersion,
  });

  final String? serviceUrl;
  final String? serviceVersion;
  final String? privacyUrl;
  final String? privacyVersion;

  factory AgreementLatest.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    final privacy = json['privacy'];
    return AgreementLatest(
      serviceUrl: user is Map ? user['url']?.toString() : null,
      serviceVersion: user is Map ? user['version']?.toString() : null,
      privacyUrl: privacy is Map ? privacy['url']?.toString() : null,
      privacyVersion: privacy is Map ? privacy['version']?.toString() : null,
    );
  }
}
