import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// App 桌面图标角标写入（iOS）。
///
/// 桌面图标角标原先完全由网易云信 APNS 的 `aps.badge`（服务端总未读）驱动，
/// 读消息后不随之下降 → 与 App 内未读不一致。改为 App 侧用本地总未读
/// （[appIconBadgeProvider]）覆盖，使图标角标与 App 内展示同源同值。
///
/// 仅 iOS 接管；Android 角标由各厂商启动器决定，不在本服务范围。
class AppBadgeService {
  AppBadgeService._();

  static const _channel = MethodChannel('cn.currantmind.xinyu/badge');

  /// 设置桌面图标角标为 [count]（<0 视为 0；0 清除）。
  ///
  /// iOS 专用，Android 直接返回；原生异常静默——角标为体验性增强，不阻断主流程。
  static Future<void> setCount(int count) async {
    if (kIsWeb || !Platform.isIOS) return;
    try {
      await _channel.invokeMethod<void>('setBadge', count < 0 ? 0 : count);
    } on MissingPluginException {
      // 原生端尚未注册通道（如未重新构建 iOS 宿主）：忽略。
    } catch (_) {
      // 其余原生异常静默。
    }
  }
}
