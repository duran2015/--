import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'secure_store.dart';

final accountStoreProvider = Provider<AccountStore>(
  (ref) => AccountStore(ref.watch(secureStoreProvider)),
);

/// 登录响应 LoginData（契约 §1 表 #1）。
/// 字段对应 iOS XYAccountManager 持久化的 13 个 key：
/// access_token / imUserId / imUserSig / availableIdentities /
/// currentIdentity / consultantId / expires_in / phone / nickName /
/// userId / avatar / firstLogin / userName / needPersonalityGuide。
class LoginData {
  const LoginData({
    required this.accessToken,
    this.imUserId,
    this.imUserSig,
    this.availableIdentities = const [],
    this.currentIdentity,
    this.consultantId,
    this.expiresIn,
    this.phone,
    this.nickName,
    this.userId,
    this.avatar,
    this.firstLogin,
    this.userName,
    this.needPersonalityGuide,
  });

  /// access_token
  final String accessToken;
  final String? imUserId;
  final String? imUserSig;

  /// 可用身份：user / consultant
  final List<String> availableIdentities;
  final String? currentIdentity;
  final String? consultantId;

  /// expires_in（秒）
  final int? expiresIn;
  final String? phone;
  final String? nickName;
  final String? userId;
  final String? avatar;
  final bool? firstLogin;
  final String? userName;
  final bool? needPersonalityGuide;

  factory LoginData.fromJson(Map<String, dynamic> json) {
    // 真实后端把用户资料嵌在 userInfo{userId, phonenumber, nickName, avatar}
    // （契约 api_inventory.md §2.1，对齐 iOS XYLoginData 平铺解析）；
    // 顶层同名字段优先（mock / 旧结构兼容）。
    final userInfo = json['userInfo'];
    final info = userInfo is Map ? Map<String, dynamic>.from(userInfo) : null;
    return LoginData(
      accessToken: json['access_token'] as String? ?? '',
      imUserId: json['imUserId']?.toString(),
      imUserSig: json['imUserSig']?.toString(),
      availableIdentities: (json['availableIdentities'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      currentIdentity: json['currentIdentity']?.toString(),
      consultantId: json['consultantId']?.toString(),
      expiresIn: (json['expires_in'] as num?)?.toInt(),
      phone: json['phone']?.toString() ?? info?['phonenumber']?.toString(),
      nickName: json['nickName']?.toString() ?? info?['nickName']?.toString(),
      userId: json['userId']?.toString() ?? info?['userId']?.toString(),
      avatar: json['avatar']?.toString() ?? info?['avatar']?.toString(),
      firstLogin: json['firstLogin'] as bool?,
      userName: json['userName']?.toString(),
      needPersonalityGuide: json['needPersonalityGuide'] as bool?,
    );
  }

  Map<String, dynamic> toJson() => {
        'access_token': accessToken,
        'imUserId': imUserId,
        'imUserSig': imUserSig,
        'availableIdentities': availableIdentities,
        'currentIdentity': currentIdentity,
        'consultantId': consultantId,
        'expires_in': expiresIn,
        'phone': phone,
        'nickName': nickName,
        'userId': userId,
        'avatar': avatar,
        'firstLogin': firstLogin,
        'userName': userName,
        'needPersonalityGuide': needPersonalityGuide,
      };

  /// 切换身份后局部更新（契约 §1 #5 selectIdentity 返回新
  /// currentIdentity / availableIdentities / consultantId /
  /// imUserId / imUserSig，iOS 全量刷新本地身份与 IM 凭证）。
  LoginData copyWith({
    String? currentIdentity,
    List<String>? availableIdentities,
    String? consultantId,
    String? imUserId,
    String? imUserSig,
  }) {
    return LoginData(
      accessToken: accessToken,
      imUserId: imUserId ?? this.imUserId,
      imUserSig: imUserSig ?? this.imUserSig,
      availableIdentities: availableIdentities ?? this.availableIdentities,
      currentIdentity: currentIdentity ?? this.currentIdentity,
      consultantId: consultantId ?? this.consultantId,
      expiresIn: expiresIn,
      phone: phone,
      nickName: nickName,
      userId: userId,
      avatar: avatar,
      firstLogin: firstLogin,
      userName: userName,
      needPersonalityGuide: needPersonalityGuide,
    );
  }
}

/// LoginData 持久化：整体 JSON 存 secure storage（对应 iOS XYAccountManager
/// 的 13 个 key 统一落库），并同步 token / IM 凭证单项 key 便于取用。
class AccountStore {
  AccountStore(this._secure);

  final SecureStore _secure;

  static const _kLoginData = 'login_data';

  Future<void> save(LoginData data) async {
    await _secure.write(_kLoginData, jsonEncode(data.toJson()));
    await _secure.writeToken(data.accessToken);
    await _secure.writeImUserId(data.imUserId);
    await _secure.writeImUserSig(data.imUserSig);
  }

  /// 启动恢复；无数据或 JSON 损坏时返回 null。
  Future<LoginData?> read() async {
    final raw = await _secure.read(_kLoginData);
    if (raw == null || raw.isEmpty) return null;
    try {
      return LoginData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// 清空登录数据（登出 / 401 / 注销账号）。
  Future<void> clear() async {
    await _secure.delete(_kLoginData);
    await _secure.clearAuth();
  }
}
