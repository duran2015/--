import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../core/network/api_client.dart';
import '../../core/network/dev_mock.dart';

/// Apple 授权凭证（identityToken + 昵称）。
/// iOS 参照：XYAppleLoginCredential。
class AppleAuthCredential {
  const AppleAuthCredential({
    required this.identityToken,
    this.nickName,
  });

  /// Apple 签发的身份 JWT（供后端验签换登录态）
  final String identityToken;

  /// 用户昵称（仅首次授权时系统才返回，之后为 null）
  final String? nickName;
}

/// Apple 授权登录服务抽象（对齐 iOS XYAppleLoginManager）。
abstract class AppleAuthService {
  /// 发起 Apple 授权：弹出系统面板，成功回传 identityToken + 昵称。
  /// 用户取消 / 凭证异常 / 系统错误均抛 [AppleAuthException]。
  /// iOS 参照：XYAppleLoginManager.sendAuthRequest。
  Future<AppleAuthCredential> authorize();
}

/// Apple 授权异常：[message] 直接用于 AppToast；[canceled] 为 true 时页面静默。
class AppleAuthException implements Exception {
  const AppleAuthException(this.message, {this.canceled = false});

  /// Toast 文案（用户取消时为「已取消」，页面按 [canceled] 静默）
  final String message;

  /// 用户主动取消（对齐 iOS code == -1001，不弹 toast）
  final bool canceled;

  @override
  String toString() => 'AppleAuthException(canceled=$canceled): $message';
}

/// sign_in_with_apple 真实实现。
/// iOS 参照：XYAppleLoginManager（scopes=[fullName, email]，昵称=姓+名拼接）。
class SignInWithAppleAuthService implements AppleAuthService {
  @override
  Future<AppleAuthCredential> authorize() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final identityToken = credential.identityToken;
      if (identityToken == null || identityToken.isEmpty) {
        throw const AppleAuthException('Apple 授权凭证异常');
      }
      // 昵称仅首次授权返回；中文习惯姓在前（对齐 iOS familyName+givenName）
      final nickName = [
        credential.familyName,
        credential.givenName,
      ].whereType<String>().where((s) => s.isNotEmpty).join();
      if (kDebugMode) {
        debugPrint(
          '[AppleAuth] 授权成功，nickName=${nickName.isEmpty ? 'nil' : nickName}，'
          'identityToken长度=${identityToken.length}',
        );
      }
      return AppleAuthCredential(
        identityToken: identityToken,
        nickName: nickName.isEmpty ? null : nickName,
      );
    } on AppleAuthException {
      rethrow;
    } on SignInWithAppleAuthorizationException catch (e) {
      // 用户主动取消：对齐 iOS ASAuthorizationError.canceled → code -1001
      if (e.code == AuthorizationErrorCode.canceled) {
        if (kDebugMode) debugPrint('[AppleAuth] 用户取消授权');
        throw const AppleAuthException('已取消', canceled: true);
      }
      if (kDebugMode) {
        debugPrint('[AppleAuth] 授权失败：${e.code} ${e.message}');
      }
      throw AppleAuthException(
        e.message.isNotEmpty ? e.message : 'Apple 授权失败',
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[AppleAuth] 授权异常：$e');
      throw AppleAuthException(e.toString());
    }
  }
}

/// dev mock 实现：固定 identityToken，免 Apple 环境跑通 appleLogin 全链路。
class MockAppleAuthService implements AppleAuthService {
  MockAppleAuthService({String? identityTokenToReturn})
      : identityTokenToReturn = identityTokenToReturn ?? debugNextToken;

  /// 调试开关：下次 [authorize] 返回的 identityToken。
  /// - [mockAppleBoundToken]（默认）→ appleLogin 已绑定，直接登录；
  /// - [mockAppleUnboundToken] → needBindPhone=true，走绑定手机号页。
  static String debugNextToken = mockAppleBoundToken;

  final String identityTokenToReturn;

  @override
  Future<AppleAuthCredential> authorize() async {
    return AppleAuthCredential(
      identityToken: identityTokenToReturn,
      nickName: 'AppleMock用户',
    );
  }
}

/// 按 ApiClient.useMock 选择实现（仅 API_ENV=mock 的 debug / 单测走 mock）。
final appleAuthServiceProvider = Provider<AppleAuthService>((ref) {
  return ApiClient.useMock
      ? MockAppleAuthService()
      : SignInWithAppleAuthService();
});
