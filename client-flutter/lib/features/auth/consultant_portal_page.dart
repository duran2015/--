import 'package:flutter/material.dart';

import '../../core/platform/consultant_portal_launcher.dart';

/// 咨询师端统一出口。
///
/// 用户端由当前 Flutter 工程承载；咨询师端由独立 Web 原型承载。身份选择、
/// 最近身份恢复和用户端“切换为咨询师”均进入本页，再跳转 Web 咨询师端。
class ConsultantPortalPage extends StatefulWidget {
  const ConsultantPortalPage({super.key});

  @override
  State<ConsultantPortalPage> createState() => _ConsultantPortalPageState();
}

class _ConsultantPortalPageState extends State<ConsultantPortalPage> {
  late final bool _redirected;

  @override
  void initState() {
    super.initState();
    _redirected = openConsultantPortal();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_redirected) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                const Text('正在进入咨询师工作台…'),
              ] else ...[
                const Icon(Icons.devices_rounded, size: 48),
                const SizedBox(height: 16),
                const Text(
                  '咨询师工作台由 Web 端提供',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                SelectableText(consultantPortalUrl),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
