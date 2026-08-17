import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/platform/consultant_portal_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_background.dart';
import '../../core/widgets/app_loading_hud.dart';
import '../../core/widgets/app_nav_bar.dart';
import '../../core/widgets/app_toast.dart';
import 'auth_view_model.dart';

/// 咨询师入驻 Mock 闭环。真实环境由 Builder 替换提交/审核接口，页面字段可复用。
class ConsultantOnboardingPage extends ConsumerStatefulWidget {
  const ConsultantOnboardingPage({super.key});

  @override
  ConsumerState<ConsultantOnboardingPage> createState() =>
      _ConsultantOnboardingPageState();
}

class _ConsultantOnboardingPageState
    extends ConsumerState<ConsultantOnboardingPage> {
  final _nameController = TextEditingController();
  final _certificateController = TextEditingController();
  String _qualification = '国家心理咨询师';
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _certificateController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty ||
        _certificateController.text.trim().isEmpty) {
      AppToast.show(context, '请完整填写姓名与证书编号');
      return;
    }
    setState(() => _submitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    try {
      final route = await ref
          .read(authViewModelProvider.notifier)
          .selectIdentity('consultant');
      if (!mounted) return;
      AppToast.show(context, '演示审核已通过，欢迎进入咨询师工作台');
      navigateOrOpenPortal(context, route);
    } catch (_) {
      if (mounted) AppToast.show(context, '提交失败，请稍后重试');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          AppPageBackground(
            child: SafeArea(
              child: Column(
                children: [
                  const AppNavBar(title: '咨询师入驻', transparent: true),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        Text('申请咨询师身份',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        Text(
                          '账号主体保持不变。审核通过后，可在用户端与咨询师端之间随时切换。',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: '真实姓名',
                            prefixIcon: Icon(Icons.person_outline_rounded),
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: _qualification,
                          decoration: const InputDecoration(
                            labelText: '资质类型',
                            prefixIcon: Icon(Icons.workspace_premium_outlined),
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: '国家心理咨询师', child: Text('国家心理咨询师')),
                            DropdownMenuItem(
                                value: '注册心理师', child: Text('注册心理师')),
                            DropdownMenuItem(
                                value: '精神科医师', child: Text('精神科医师')),
                            DropdownMenuItem(value: '其他', child: Text('其他资质')),
                          ],
                          onChanged: (value) => setState(
                              () => _qualification = value ?? _qualification),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _certificateController,
                          decoration: const InputDecoration(
                            labelText: '证书编号',
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () =>
                              AppToast.show(context, '演示环境已模拟上传证书'),
                          icon: const Icon(Icons.upload_file_rounded),
                          label: const Text('上传资质证明'),
                        ),
                        const SizedBox(height: 28),
                        FilledButton(
                          onPressed: _submitting ? null : _submit,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            backgroundColor: const Color(0xFF6750A4),
                          ),
                          child: const Text('提交入驻申请'),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '正式环境：提交后进入“审核中”，审核通过才会开通咨询师身份。',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 11, color: AppColors.textTertiary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_submitting)
            const Positioned.fill(child: AppLoadingHud(message: '提交审核中')),
        ],
      ),
    );
  }
}
