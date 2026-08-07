import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_controller.dart';

/// 兼容层：登录 token，由 AuthController 派生（原 StateProvider 已整合进
/// auth_controller.dart，写入请走 AuthController.applyLogin / logout）。
final authTokenProvider = Provider<String?>(
  (ref) => ref.watch(authControllerProvider)?.accessToken,
);

/// 兼容层：当前身份 user / consultant，由 AuthController 派生。
final currentIdentityProvider = Provider<String?>(
  (ref) => ref.watch(authControllerProvider)?.currentIdentity,
);
