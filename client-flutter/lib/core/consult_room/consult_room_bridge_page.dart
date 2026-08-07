import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/navigation.dart';
import 'consult_room_launcher.dart';
import 'consult_room_service.dart';

/// /consult-room 深链入口（1006）：**不可见**，立即校验并 present 原生会议后 pop 自身。
///
/// 业务入口（工作台/订单）应直接调 [launchConsultRoom]，不要 push 本页。
/// 本页仅服务深链 / 聊天卡片 link / 旧路由兼容，用户无感知。
class ConsultRoomBridgePage extends ConsumerStatefulWidget {
  const ConsultRoomBridgePage({super.key, required this.query});

  final Map<String, String> query;

  @override
  ConsumerState<ConsultRoomBridgePage> createState() =>
      _ConsultRoomBridgePageState();
}

class _ConsultRoomBridgePageState extends ConsumerState<ConsultRoomBridgePage> {
  bool _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    if (_started || !mounted) return;
    _started = true;
    final params = ConsultRoomParams.fromQuery(widget.query);
    final router = GoRouter.of(context);
    // 先 pop 不可见桥接页，Toast 改走根导航 context
    final toastContext = rootNavigatorKey.currentContext;
    if (router.canPop()) {
      router.pop();
    }
    await launchConsultRoom(
      ref,
      params,
      context: toastContext,
    );
  }

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(color: Colors.transparent);
  }
}
