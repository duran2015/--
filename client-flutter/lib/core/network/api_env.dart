/// API 环境开关（dart-define）。
///
/// - `API_ENV=live`（默认）：走真实 HTTP（[baseUrl]），debug / release 一致，
///   不注册 dev_mock。
/// - `API_ENV=mock`：仅用于本地断网演示或单测；debug 下由 main.dart
///   注册 [registerDevMocks]，release 仍不注册。
///
/// 使用方式：
/// ```bash
/// flutter run                              # 默认 live，直连后端
/// flutter run --dart-define=API_ENV=mock   # 本地 mock
/// ```
class ApiEnv {
  ApiEnv._();

  /// 编译期环境值（--dart-define=API_ENV=live|mock，默认 live）。
  static const String current =
      String.fromEnvironment('API_ENV', defaultValue: 'live');

  /// 真实联调：所有请求直连线上后端。
  static const bool isLive = current == 'live';

  /// mock 开发：仅在显式 `--dart-define=API_ENV=mock` 且 debug 时注册
  ///（见 main.dart / dev_mock.dart）。
  static const bool isMock = !isLive;

  /// 网关 baseURL（契约 api_inventory.md §一，全模式同值；
  /// mock 模式不发真实请求，仅作单一事实源保留）。
  /// 默认线上；本地真机联调用 `--dart-define=API_BASE_URL=http://<mac-lan-ip>:18080` 覆盖。
  static const String baseUrl = String.fromEnvironment('API_BASE_URL',
      // defaultValue: 'https://api.currantmind.cn');
         defaultValue: 'http://192.168.9.45');
}
