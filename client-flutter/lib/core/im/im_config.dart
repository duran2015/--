import 'package:flutter/foundation.dart';

/// IM 全局配置（网易云信 NIM SDK）。
///
/// 须与后端 `im.provider` 一致（凭证/账号/robot accid 同源）。
class ImConfig {
  ImConfig._();

  /// 网易云信应用 AppKey（控制台分配，与后端 `netease.im.app-key` 同源；非密钥，可入端）。
  static const String neteaseAppKey = 'c3ace11c66e4215dfbbc0f610c35b8ec';

  // ===== 网易云信离线推送凭证（控制台「证书管理」开通后填入）=====
  // 留空/为 null 表示该端/该厂商未开通，SDK 自动跳过对应推送通道。

  /// iOS APNs 推送证书名（须与网易云信控制台 p8 证书名完全一致）。
  /// 控制台配了两张 p8：kelu_push_dev（测试环境）/ kelu_push_prod（生产环境）。
  /// 按 App 构建类型自动选——只有 release（发布构建，distribution 签名→production token）走 prod；
  /// debug 和 profile（开发签名→sandbox token）都走 dev。
  /// 与 iOS entitlements 对齐（Xcode 按 Configuration 自动切换，无需手改）：
  /// - Debug / Profile → Runner/Runner.entitlements → aps-environment=development
  /// - Release → Runner/RunnerRelease.entitlements → aps-environment=production
  static const String neteaseApnsCername =
      kReleaseMode ? 'kelu_push_prod' : 'kelu_push_dev';

  // ---- Android 厂商混合推送（仅 Android 生效；只填你在控制台已开通的厂商，其余保持 null）----
  /// 小米推送（控制台需填小米证书名）
  static const String? neteaseXmAppId = null;
  static const String? neteaseXmAppKey = null;
  static const String? neteaseXmCerName = null;
  /// 华为推送（appId 即 agconnect services 里的 app_id）
  static const String? neteaseHwAppId = null;
  static const String? neteaseHwCerName = null;
  /// OPPO 推送
  static const String? neteaseOppoAppId = null;
  static const String? neteaseOppoAppKey = null;
  static const String? neteaseOppoAppSecret = null;
  static const String? neteaseOppoCerName = null;
  /// vivo 推送（appId/appKey 在 AndroidManifest 配置，这里只填证书名）
  static const String? neteaseVivoCerName = null;
  /// 魅族推送
  static const String? neteaseMzAppId = null;
  static const String? neteaseMzAppKey = null;
  static const String? neteaseMzCerName = null;
  /// 荣耀推送
  static const String? neteaseHonorCerName = null;

  /// AI 机器人账号。
  /// 机器人会话有专属入口（底部小鹿 Tab），不进入消息 Tab 普通对话列表，也不计入未读总数。
  /// 网易云信 accid 强制小写，机器人实际为 `rbt_xinyu001`（发送/接收 senderId 均为小写，
  /// 与之比较的会话过滤务必同侧小写，否则消息会被静默丢弃）。
  static String get robotUserId => 'rbt_xinyu001';

  /// 机器人账号前缀（过滤所有机器人会话用，不止 [robotUserId] 一个）。
  /// 云信 accid 小写，前缀用 `rbt_`。
  static String get robotPrefix => 'rbt_';

  /// 系统通知账号（后端约定的系统消息发送者 IM userID）。
  /// 该账号会话在消息 Tab 顶部「系统通知」入口展示，不进普通对话列表。
  /// 云信 accid 强制小写，实际为 `sysnotification`。
  static const String systemNotificationUserId = 'sysnotification';

  /// 系统通知会话 ID（C2C 会话 ID 规则 `c2c_` + userID）。
  /// 注：网易云信的 conversationId 格式不同，NeteaseImService 内部按 `c2c_` 前缀
  /// 解析出 userId 再换算为 NIM 会话 ID，故此处沿用 `c2c_` 约定不变。
  static const String systemNotificationConversationId =
      'c2c_$systemNotificationUserId';

  /// 系统通知历史拉取上限。
  static const int systemNotificationHistoryCount = 50;
}
