import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // 网易云信 NIM 离线推送：请求通知授权并注册 APNs。
    // apnsCername 在 nim_core_v2 initialize 时传入；autoUpdateApnsToken=true 会自动把
    // APNs token 上报云信，故此处无需手动处理 didRegisterForRemoteNotificationsWithDeviceToken。
    // requestAuthorization 仅首次弹授权弹窗（系统记忆后续决定），与 NIM SDK 内部请求互不重复。
    UNUserNotificationCenter.current().delegate = self
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in
      DispatchQueue.main.async {
        UIApplication.shared.registerForRemoteNotifications()
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  /// APNs 注册成功：拿到 deviceToken。NIM 插件靠 FlutterAppDelegate 转发本回调来抓 token
  /// 上报云信，故**必须调用 super** 让转发继续；只打日志不调 super 会导致 token 拿到却不上报、
  /// 离线推送收不到（这就是之前不弹横幅的根因）。
  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
    print("🟢 [NIM APNs] deviceToken 获取成功（转发给 NIM 插件上报）: \(token)")
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  /// APNs 注册失败：离线推送排障最关键的一条日志，error 会直接说明根因。
  /// 常见：未开启 Push Notifications 能力、aps-environment entitlement 无效、Bundle ID 不匹配。
  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    print("🔴 [NIM APNs] 注册远程通知失败: \(error.localizedDescription)")
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    _registerBadgeChannel(engineBridge)
  }

  /// App 接管桌面图标角标：Dart 侧用本地总未读通过本通道写入图标角标，
  /// 覆盖网易云信 APNS aps.badge（服务端总未读），使桌面角标与 App 内未读同源同值。
  /// 取 implicit engine 的 applicationRegistrar.messenger，避免依赖 rootViewController 时序
  /// （回调时 rootViewController 未必已是 FlutterViewController，旧实现会因 as? 失败而漏注册）。
  private func _registerBadgeChannel(_ engineBridge: FlutterImplicitEngineBridge) {
    let channel = FlutterMethodChannel(
      name: "cn.currantmind.xinyu/badge",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      guard call.method == "setBadge", let count = call.arguments as? Int else {
        result(FlutterMethodNotImplemented)
        return
      }
      let safe = max(0, count)
      if #available(iOS 16.0, *) {
        UNUserNotificationCenter.current().setBadgeCount(safe)
      } else {
        UIApplication.shared.applicationIconBadgeNumber = safe
      }
      result(nil)
    }
  }
}
