# xinyu_flutter

心愈/可鹿心理 Flutter 统一前端骨架。

## 本地运行

环境准备（Flutter SDK 在 `~/Developer/flutter`，pub 走国内镜像）：

```bash
export PATH="$HOME/Developer/flutter/bin:$PATH"
export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
flutter pub get
```

方式一：flutter run（选 iOS 模拟器）

```bash
flutter devices                                   # 查看可用设备
flutter run -d <device-id>                        # debug 默认 live，与 release 同走真实接口 
# flutter run -d <device-id> --dart-define=API_ENV=mock   # 本地 mock 演示
```

> 直连**本地后端**联调（网关 18080 + 网易云信 + 本地问卷 H5）见下文
> [本地后端联调](#本地后端联调dart-define)，需额外带 `API_BASE_URL` /
> `IM_VENDOR` / `INTAKE_H5_BASE` 三个 define。

方式二：构建 .app + simctl 安装（适合保留安装状态随时点开）

```bash
# 构建模拟器 debug 产物（免签名；mock + 自动登录见下文）
flutter build ios --simulator --debug \
  --dart-define=API_ENV=mock --dart-define=DEV_AUTO_LOGIN=1

# 选一台模拟器 boot → install → launch（bundle id：com.currantmind.kelu）
xcrun simctl list devices available | grep iPhone   # 选 iOS 26.5 的机型
xcrun simctl boot <device-udid>
xcrun simctl install booted build/ios/iphonesimulator/Runner.app
xcrun simctl launch booted com.currantmind.kelu

# 截图
xcrun simctl io booted screenshot /tmp/xxx.png
```

> 注意：若工程放在 iCloud 同步的 `~/Documents` 下，构建期 codesign 会因
> 同步守护进程注入的扩展属性报 `resource fork, Finder information, or
> similar detritus not allowed`。规避：把 build 目录软链到非同步位置——
> `rm -rf build && ln -s ~/Library/Caches/xinyu_flutter_build build`。

迁移契约见上级目录 `../contracts/`：

- `api_contract.md`：接口契约
- `route_code_contract.md`：路由契约
- `im_custom_message_contract.md`：IM 自定义消息契约

## API 环境

默认 **`API_ENV=live`**：debug / release 均直连 `https://api.currantmind.cn`。

本地 mock（断网演示 / 部分走查）需显式开启：

```bash
flutter run --dart-define=API_ENV=mock
```

详见 `lib/core/network/api_env.dart`、`lib/core/network/dev_mock.dart`：

- 手机号 `13800000002` → 双身份，登录后进身份选择页；其他合法手机号 → 单身份。
- 微信登录（MockWechatAuthService）：
  - 默认 code `mock_dev_code` → 已绑定，直接登录；
  - 置 `MockWechatAuthService.debugNextCode = 'mock_unbind'` → 未绑定，
    走通绑定手机号页 → 验证码页（绑定模式）→ bindPhoneLogin 登录。
- **DEV_AUTO_LOGIN（仅 mock + debug 走查，默认关闭）**：同时加
  `--dart-define=API_ENV=mock --dart-define=DEV_AUTO_LOGIN=1` 后，splash
  无登录态时自动以 mock 假数据登录。live 模式下不生效。
- 跨阶段注意事项（包名/签名/entitlements）见 `XINYU_NOTES.md`；微信接入
  说明见 `../wechat_login_setup.md`。

## 本地后端联调（dart-define）

直连本地跑起来的后端（`xinyuService`，网关 `18080`）时，三个编译期开关要对齐，
否则会出现「消息列表为空 / 咨询前问卷为空」：

| dart-define | 作用 | 本地联调值 |
| --- | --- | --- |
| `API_BASE_URL` | 网关地址（覆盖 `api_env.dart` 的线上默认值） | `http://localhost:18080`（真机改 Mac 局域网 IP） |
| `IM_VENDOR` | IM 厂商，**须与后端 nacos `im.provider` 一致** | `netease`（dev 已切网易云信） |
| `INTAKE_H5_BASE` | 咨询前问卷 H5 根地址 | 指向本地那份 H5 |

VS Code 直接选 **`flutter (local dev)`** 配置（`.vscode/launch.json`，已含前两项）；
命令行：

```bash
flutter run -d <device-id> \
  --dart-define=API_BASE_URL=http://localhost:18080 \
  --dart-define=IM_VENDOR=netease \
  --dart-define=INTAKE_H5_BASE=http://<本地 H5 地址>
```

要点：

- **IM 厂商必须对齐**：dev nacos 是 `im.provider: netease`（`xinyu-app-dev.yml`），
  客户端默认却是 `IM_VENDOR=tencent`（[im_config.dart](lib/core/im/im_config.dart)）。
  不显式切 netease → 后端按网易云信签发 `imUserSig`、客户端拿它登腾讯 IM → 登录失败
  → `fetchConversations()` 直接返回空 → 消息列表永远空。test/prod 都是 tencent，
  **发布构建不要带 `IM_VENDOR` 这个 define**。
- **真机地址**：模拟器下 `localhost` 即宿主机；真机要用 Mac 局域网 IP（如
  `http://192.168.x.x:18080`），并确保后端网关放行该端口。
- **问卷 H5**：题目定义在 H5 前端、且 H5 直连它自己的后端（见后端
  `AppQuestionnaireController`「题目前端化方案」）。本地 token 打测试 H5 会
  `401 → 暂无问卷信息`。要让问卷本地有内容，需起一份「连本地后端」的 H5，再用
  `INTAKE_H5_BASE` 指过去（本仓库不含 H5 源码）。

