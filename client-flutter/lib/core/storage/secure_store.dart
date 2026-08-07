import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/ly_cache.dart';

final secureStoreProvider = Provider<SecureStore>((ref) => SecureStore());

/// 注释：敏感/账户凭证数据存储类（已统一重构为基于 Hive/LyCache）
/// 时间：2026/8/4
/// 作者：郭翰林
class SecureStore {
  SecureStore();

  static const _kAccessToken = 'access_token';
  static const _kImUserId = 'im_user_id';
  static const _kImUserSig = 'im_user_sig';
  static const _kRefreshToken = 'refresh_token';

  Future<String?> readToken() => LyCache.get<String>(key: _kAccessToken);
  Future<void> writeToken(String? value) => write(_kAccessToken, value);

  Future<String?> readImUserId() => LyCache.get<String>(key: _kImUserId);
  Future<void> writeImUserId(String? value) => write(_kImUserId, value);

  Future<String?> readImUserSig() => LyCache.get<String>(key: _kImUserSig);
  Future<void> writeImUserSig(String? value) => write(_kImUserSig, value);

  Future<String?> readRefreshToken() => LyCache.get<String>(key: _kRefreshToken);
  Future<void> writeRefreshToken(String? value) => write(_kRefreshToken, value);

  /// 通用读写（供 AccountStore 存 JSON 等）
  Future<String?> read(String key) => LyCache.get<String>(key: key);

  Future<void> write(String key, String? value) async {
    if (value == null) {
      await LyCache.remove(key: key);
    } else {
      await LyCache.put(key: key, value: value);
    }
  }

  Future<void> delete(String key) => LyCache.remove(key: key);

  /// 清空鉴权相关数据（登出 / 401 / 注销）
  Future<void> clearAuth() async {
    await Future.wait([
      LyCache.remove(key: _kAccessToken),
      LyCache.remove(key: _kImUserId),
      LyCache.remove(key: _kImUserSig),
      LyCache.remove(key: _kRefreshToken),
    ]);
  }
}
