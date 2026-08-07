import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/ly_cache.dart';

/// 注释：按用户维度的本地布尔标记与配置（已统一重构为基于 Hive/LyCache）
/// 时间：2026/8/4
/// 作者：郭翰林
class LocalFlags {
  LocalFlags();

  static Future<LocalFlags> create() async => LocalFlags();

  /// AI 引导已触发标记名（实际 key 为 ai_guidance_triggered_{userId}）。
  static const aiGuidanceTriggered = 'ai_guidance_triggered';

  /// 协议弹窗「已同意」标记（全局，非用户维度）。
  static const agreementAccepted = 'agreement_accepted';

  /// AI 服务数据分享同意标记（全局，非用户维度；对齐 iOS
  /// xy_ai_sharing_consented——设备级、登出不清，仅首次装/清数据才重弹）。
  static const aiSharingConsented = 'ai_sharing_consented';

  /// 临时设备唯一标识。
  static const deviceIdKey = 'device_id';

  /// 最近一次实际使用身份；登出不清，用于下次登录自动恢复。
  static const lastIdentityKey = 'last_identity';

  /// 登录页主动选择的身份意图，仅作用于下一次登录。
  static const loginIdentityIntentKey = 'login_identity_intent';

  String _scoped(String flag, String userId) => '${flag}_$userId';

  bool getFlag(String flag, String userId) =>
      LyCache.getSync<bool>(key: _scoped(flag, userId)) ?? false;

  Future<void> setFlag(String flag, String userId, bool value) async =>
      await LyCache.put(key: _scoped(flag, userId), value: value);

  bool isAiGuidanceTriggered(String userId) =>
      getFlag(aiGuidanceTriggered, userId);

  Future<void> markAiGuidanceTriggered(String userId) =>
      setFlag(aiGuidanceTriggered, userId, true);

  // ---------- 协议弹窗 ----------

  /// 是否已同意过协议弹窗（同意后首次进登录页不再弹）。
  bool get isAgreementAccepted =>
      LyCache.getSync<bool>(key: agreementAccepted) ?? false;

  /// 记录「已同意协议」。
  Future<void> markAgreementAccepted() async =>
      await LyCache.put(key: agreementAccepted, value: true);

  // ---------- AI 服务数据分享同意（iOS xy_ai_sharing_consented） ----------

  /// 是否已同意 AI 服务数据分享（同意后进 AI 页不再弹；设备全局、登出不清）。
  bool get isAiSharingConsented =>
      LyCache.getSync<bool>(key: aiSharingConsented) ?? false;

  /// 记录「已同意 AI 服务数据分享」。
  Future<void> markAiSharingConsented() async =>
      await LyCache.put(key: aiSharingConsented, value: true);

  String _identityKey(String accountId) => '${lastIdentityKey}_$accountId';

  String? lastIdentityFor(String accountId) =>
      LyCache.getSync<String>(key: _identityKey(accountId));

  Future<void> saveLastIdentity(String accountId, String identity) =>
      LyCache.put(key: _identityKey(accountId), value: identity);

  String? get loginIdentityIntent =>
      LyCache.getSync<String>(key: loginIdentityIntentKey);

  Future<void> setLoginIdentityIntent(String? identity) async {
    await LyCache.put(key: loginIdentityIntentKey, value: identity ?? '');
  }

  Future<String?> consumeLoginIdentityIntent() async {
    final value = loginIdentityIntent;
    await setLoginIdentityIntent(null);
    return value == null || value.isEmpty ? null : value;
  }

  /// 取临时设备 ID；不存在则生成 uuid v4 并持久化。
  Future<String> ensureDeviceId() async {
    final existing = LyCache.getSync<String>(key: deviceIdKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final id = _generateUuidV4();
    await LyCache.put(key: deviceIdKey, value: id);
    return id;
  }

  /// 生成 uuid v4（无第三方依赖的临时实现）。
  static String _generateUuidV4() {
    final rand = Random.secure();
    final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant 10
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }
}

/// 异步初始化；读取处用 `ref.watch(localFlagsProvider)` 取 AsyncValue。
final localFlagsProvider = FutureProvider<LocalFlags>(
  (ref) => LocalFlags.create(),
);
