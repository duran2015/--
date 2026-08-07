import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_background.dart';
import '../../core/widgets/app_nav_bar.dart';
import '../../core/widgets/app_toast.dart';
import 'support_profile_state.dart';

class SupportProfilePage extends ConsumerStatefulWidget {
  const SupportProfilePage({super.key, this.initialSection});

  final SupportProfileSection? initialSection;

  @override
  ConsumerState<SupportProfilePage> createState() => _SupportProfilePageState();
}

class _SupportProfilePageState extends ConsumerState<SupportProfilePage> {
  @override
  void initState() {
    super.initState();
    if (widget.initialSection != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openEditor(widget.initialSection!);
      });
    }
  }

  Future<void> _openEditor(SupportProfileSection section) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SupportProfileEditor(section: section),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(supportProfileProvider);
    return Scaffold(
      body: AppPageBackground(
        child: SafeArea(
          child: Column(
            children: [
              const AppNavBar(
                title: '我的支持档案',
                transparent: true,
                lineHidden: true,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _introCard(context),
                      const SizedBox(height: 18),
                      _sectionLabel(context, '按用途管理'),
                      const SizedBox(height: 10),
                      _ProfilePurposeCard(
                        icon: Icons.badge_outlined,
                        title: '基础资料',
                        purpose: '用于账号与必要联系',
                        summary: profile.basicCompletion == 100
                            ? '${profile.preferredName} · ${profile.ageRange} · ${profile.city}'
                            : '补充紧急联系人，遇到特殊情况时使用',
                        completion: profile.basicCompletion,
                        tone: const Color(0xFFE2F4F1),
                        onTap: () => _openEditor(SupportProfileSection.basic),
                      ),
                      const SizedBox(height: 12),
                      _ProfilePurposeCard(
                        icon: Icons.tune_rounded,
                        title: '咨询偏好',
                        purpose: '用于匹配更合适的咨询师',
                        summary: profile.preferenceCompletion >= 75
                            ? '${profile.concerns.join('、')} · ${profile.preferredModes.join('、')}'
                            : '完善关注方向、咨询方式、风格与可约时间',
                        completion: profile.preferenceCompletion,
                        tone: const Color(0xFFEADDFF),
                        onTap: () =>
                            _openEditor(SupportProfileSection.preference),
                      ),
                      const SizedBox(height: 12),
                      _ProfilePurposeCard(
                        icon: Icons.volunteer_activism_outlined,
                        title: '支持档案',
                        purpose: '经授权提供给本次咨询师',
                        summary: profile.supportIsStale
                            ? '你的情况可能发生了变化，建议更新近况'
                            : profile.authorizedForBooking
                                ? '已授权在预约时生成本次资料快照'
                                : '默认仅自己可见，授权后才会分享',
                        completion: profile.supportCompletion,
                        tone: const Color(0xFFFFE8CC),
                        attention: profile.supportIsStale,
                        onTap: () => _openEditor(SupportProfileSection.support),
                      ),
                      const SizedBox(height: 18),
                      _privacyCard(context),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _introCard(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('你决定填写什么，也决定分享给谁',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(
            '资料按用途分开保存。咨询偏好用于推荐；支持档案默认仅自己可见，预约时需单独授权。',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String text) => Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
      );

  Widget _privacyCard(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, color: colors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '正式环境中，每次预约会生成独立授权快照。咨询师只能查看本次服务需要且由你确认分享的内容。',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.5,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfilePurposeCard extends StatelessWidget {
  const _ProfilePurposeCard({
    required this.icon,
    required this.title,
    required this.purpose,
    required this.summary,
    required this.completion,
    required this.tone,
    required this.onTap,
    this.attention = false,
  });

  final IconData icon;
  final String title;
  final String purpose;
  final String summary;
  final int completion;
  final Color tone;
  final VoidCallback onTap;
  final bool attention;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: tone,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, color: const Color(0xFF3D3652)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(title,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800)),
                            if (attention) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: colors.errorContainer,
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                child: Text('建议更新',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                            color: colors.onErrorContainer)),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(purpose,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: colors.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(summary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall),
                  ),
                  const SizedBox(width: 12),
                  Text('$completion%',
                      style: Theme.of(context)
                          .textTheme
                          .labelMedium
                          ?.copyWith(color: colors.primary)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: completion / 100,
                  minHeight: 5,
                  backgroundColor: colors.surfaceContainerHighest,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SupportProfileEditor extends ConsumerStatefulWidget {
  const _SupportProfileEditor({required this.section});
  final SupportProfileSection section;

  @override
  ConsumerState<_SupportProfileEditor> createState() =>
      _SupportProfileEditorState();
}

class _SupportProfileEditorState extends ConsumerState<_SupportProfileEditor> {
  late final TextEditingController _first;
  late final TextEditingController _second;
  late final TextEditingController _third;
  late final TextEditingController _fourth;
  late List<String> _selectedConcerns;
  late List<String> _selectedModes;
  late bool _authorized;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(supportProfileProvider);
    _selectedConcerns = [...profile.concerns];
    _selectedModes = [...profile.preferredModes];
    _authorized = profile.authorizedForBooking;
    switch (widget.section) {
      case SupportProfileSection.basic:
        _first = TextEditingController(text: profile.preferredName);
        _second = TextEditingController(text: profile.ageRange);
        _third = TextEditingController(text: profile.city);
        _fourth = TextEditingController(text: profile.emergencyContact);
      case SupportProfileSection.preference:
        _first = TextEditingController(text: profile.preferredStyle);
        _second = TextEditingController(text: profile.availableTime);
        _third = TextEditingController();
        _fourth = TextEditingController();
      case SupportProfileSection.support:
        _first = TextEditingController(text: profile.currentGoal);
        _second = TextEditingController(text: profile.counselingHistory);
        _third = TextEditingController(text: profile.currentSupport);
        _fourth = TextEditingController();
    }
  }

  @override
  void dispose() {
    _first.dispose();
    _second.dispose();
    _third.dispose();
    _fourth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (widget.section) {
      SupportProfileSection.basic => '编辑基础资料',
      SupportProfileSection.preference => '编辑咨询偏好',
      SupportProfileSection.support => '更新支持档案',
    };
    return Container(
      height: MediaQuery.sizeOf(context).height * .86,
      decoration: const BoxDecoration(
        color: Color(0xFFFAF8FC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 12, 12),
            child: Row(
              children: [
                Expanded(
                    child: Text(title,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800))),
                IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded)),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              child: switch (widget.section) {
                SupportProfileSection.basic => _basicFields(),
                SupportProfileSection.preference => _preferenceFields(),
                SupportProfileSection.support => _supportFields(),
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              child: const Text('保存'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _basicFields() => Column(
        children: [
          _field(_first, '希望如何称呼你', '例如：小鹿'),
          _field(_second, '年龄段', '例如：25–34 岁'),
          _field(_third, '所在城市', '用于时区与服务匹配'),
          _field(_fourth, '紧急联系人（可选）', '姓名与联系方式'),
        ],
      );

  Widget _preferenceFields() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('最近主要关注'),
          _chips(['工作压力', '情绪困扰', '亲密关系', '睡眠问题', '个人成长'], _selectedConcerns),
          const SizedBox(height: 20),
          _label('偏好的咨询方式'),
          _chips(['文字咨询', '语音咨询', '视频咨询'], _selectedModes),
          const SizedBox(height: 12),
          _field(_first, '偏好的咨询风格', '例如：温和倾听、结构化'),
          _field(_second, '通常方便的时间', '例如：工作日晚间'),
        ],
      );

  Widget _supportFields() => Column(
        children: [
          _notice('这里只填写你愿意提前告诉咨询师的概况，不需要描述创伤细节。'),
          _field(_first, '目前最希望改善什么', '用自己的话简要描述', lines: 3),
          _field(_second, '过往咨询经历（可选）', '是否咨询过、哪些方式对你有帮助', lines: 3),
          _field(_third, '正在获得的其他支持（可选）', '例如医疗、药物或亲友支持', lines: 3),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('预约时允许生成授权资料快照'),
            subtitle: const Text('提交前仍会展示具体分享内容，可再次确认'),
            value: _authorized,
            onChanged: (value) => setState(() => _authorized = value),
          ),
        ],
      );

  Widget _field(TextEditingController controller, String label, String hint,
      {int lines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        maxLines: lines,
        decoration: InputDecoration(labelText: label, hintText: hint),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w700)),
      );

  Widget _chips(List<String> options, List<String> selected) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: options
            .map((option) => FilterChip(
                  label: Text(option),
                  selected: selected.contains(option),
                  onSelected: (value) => setState(() {
                    value ? selected.add(option) : selected.remove(option);
                  }),
                ))
            .toList(),
      );

  Widget _notice(String text) => Container(
        margin: const EdgeInsets.only(bottom: 18),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF5F3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline_rounded,
                size: 20, color: AppColors.brandTeal),
            const SizedBox(width: 10),
            Expanded(child: Text(text)),
          ],
        ),
      );

  void _save() {
    final controller = ref.read(supportProfileProvider.notifier);
    switch (widget.section) {
      case SupportProfileSection.basic:
        controller.saveBasic(
          preferredName: _first.text.trim(),
          ageRange: _second.text.trim(),
          city: _third.text.trim(),
          emergencyContact: _fourth.text.trim(),
        );
      case SupportProfileSection.preference:
        controller.savePreference(
          concerns: _selectedConcerns,
          modes: _selectedModes,
          style: _first.text.trim(),
          availableTime: _second.text.trim(),
        );
      case SupportProfileSection.support:
        controller.saveSupport(
          goal: _first.text.trim(),
          counselingHistory: _second.text.trim(),
          currentSupport: _third.text.trim(),
          authorized: _authorized,
        );
    }
    AppToast.show(context, '已保存');
    Navigator.pop(context);
  }
}
