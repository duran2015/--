# XINYU_NOTES（Flutter 工程跨阶段注意事项）

本文件记录 Flutter 迁移过程中与原生工程不一致、发布前必须处理的事项。

## 1. Android applicationId 与微信登记（已统一）

- 已按「方案 1」执行：`android/app/build.gradle.kts` 的 `namespace` /
  `applicationId` 已改为 `com.currantmind.kelu`，与微信开放平台登记一致；
  kotlin 包路径与 `wxapi.WXEntryActivity` 已一并移动到
  `com/currantmind/kelu/...`。
- 微信要求回调入口位于 `${applicationId}.wxapi.WXEntryActivity`，
  AndroidManifest 以 `.wxapi.WXEntryActivity` 相对类名声明，随 applicationId
  自动解析，无需改动。
- **剩余待办**：在微信开放平台为 debug 签名（debug.keystore）与发布签名
  （kelu_release.jks）分别登记包名 `com.currantmind.kelu` 对应的
  签名 MD5，否则微信登录/支付报 `errCode=-1` 或唤起失败。
- 改包名后旧包 `cn.currantmind.xinyu_flutter` 用户无法增量升级（需重装），
  如线上已发布请评估灰度策略。

## 2. iOS Runner.entitlements 未加入 Xcode 工程引用

- 阶段 1 下半新建 `ios/Runner/Runner.entitlements`（Associated Domains =
  `applinks:api.currantmind.cn`），并在 pbxproj 三个构建设置写入
  `CODE_SIGN_ENTITLEMENTS`（构建生效）。
- 文件本身未加入 Xcode 工程文件列表（不影响构建）；如需在 Xcode 导航可见，
  手动拖入 Runner 组即可。首次打包前在 Signing & Capabilities 确认
  Associated Domains 已勾选生效。

## 3. iOS Bundle ID 与原生不一致

- Flutter 版 bundle id = `cn.currantmind.xinyuFlutter`（新建工程），原生 iOS
  为 `com.currantmind.kelu`（HeartHealingMain）。微信 Universal Link 按
  TeamID + bundle id 匹配 apple-app-site-association，发布前需确认服务器
  AASA 文件包含 Flutter 版 bundle id，或将 bundle id 改回与原生一致。
