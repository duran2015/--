import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_nav_bar.dart';
import '../../utils/ly_cache.dart';

/// Flutter 复用原型 `src/client-app/pages/Main/AISettings.tsx` 的信息结构：
/// 聊天显示（字号/背景）+ 语音与语调（小鹿音色）。
class AiSettingsSnapshot {
  const AiSettingsSnapshot({
    required this.fontScale,
    required this.theme,
    required this.voice,
  });

  final double fontScale;
  final String theme;
  final String voice;

  static AiSettingsSnapshot load() {
    final storedVoice = LyCache.getSync<String>(key: 'ai_chat_voice');
    return AiSettingsSnapshot(
      fontScale: LyCache.getSync<double>(key: 'ai_chat_font_scale') ?? 1,
      theme: LyCache.getSync<String>(key: 'ai_chat_theme') ?? 'light',
      // 兼容刚才错误弹层曾写入的中文临时值，恢复原页面枚举。
      voice: const {'gentle', 'sexy', 'neutral'}.contains(storedVoice)
          ? storedVoice!
          : 'gentle',
    );
  }
}

class AiSettingsPage extends StatefulWidget {
  const AiSettingsPage({super.key});

  @override
  State<AiSettingsPage> createState() => _AiSettingsPageState();
}

class _AiSettingsPageState extends State<AiSettingsPage> {
  late double _fontScale;
  late String _theme;
  late String _voice;
  String? _expanded = 'fontSize';

  bool get _isDark => _theme == 'dark';

  @override
  void initState() {
    super.initState();
    final settings = AiSettingsSnapshot.load();
    _fontScale = settings.fontScale;
    _theme = settings.theme;
    _voice = settings.voice;
  }

  Future<void> _setFont(double value) async {
    setState(() => _fontScale = value);
    await LyCache.put(key: 'ai_chat_font_scale', value: value);
  }

  Future<void> _setTheme(String value) async {
    setState(() => _theme = value);
    await LyCache.put(key: 'ai_chat_theme', value: value);
  }

  Future<void> _setVoice(String value) async {
    setState(() => _voice = value);
    await LyCache.put(key: 'ai_chat_voice', value: value);
  }

  void _back() => Navigator.of(context).pop(AiSettingsSnapshot.load());

  @override
  Widget build(BuildContext context) {
    final background =
        _isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA);
    final surface = _isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final primaryText = _isDark ? Colors.white : AppColors.textPrimary;
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            AppNavBar(
              title: '小鹿偏好设置',
              onBack: _back,
              lineHidden: true,
              transparent: _isDark,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
                children: [
                  _section(
                    title: '聊天显示',
                    surface: surface,
                    primaryText: primaryText,
                    children: [
                      _settingRow(
                        id: 'fontSize',
                        icon: Icons.text_fields_rounded,
                        iconColor: Colors.orange,
                        title: '字号大小',
                        value: _fontScale == 0.9
                            ? '小号'
                            : _fontScale == 1.15
                                ? '大号'
                                : '中号（标准）',
                        primaryText: primaryText,
                        child: _segmented<double>(
                          values: const [0.9, 1, 1.15],
                          label: (value) => value == 0.9
                              ? '小号'
                              : value == 1.15
                                  ? '大号'
                                  : '标准',
                          selected: _fontScale,
                          onSelected: _setFont,
                        ),
                      ),
                      _divider(),
                      _settingRow(
                        id: 'theme',
                        icon: Icons.palette_outlined,
                        iconColor: Colors.purple,
                        title: '聊天背景',
                        value: _isDark ? '深色模式' : '浅色模式',
                        primaryText: primaryText,
                        child: _optionList(
                          values: const ['light', 'dark'],
                          selected: _theme,
                          label: (value) =>
                              value == 'dark' ? '深色模式（暗夜沉浸）' : '浅色模式（治愈浅蓝）',
                          onSelected: _setTheme,
                          primaryText: primaryText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _section(
                    title: '语音与语调（咨询师类型）',
                    surface: surface,
                    primaryText: primaryText,
                    children: [
                      _settingRow(
                        id: 'voice',
                        icon: Icons.mic_none_rounded,
                        iconColor: Colors.green,
                        title: '小鹿语音设置',
                        value: switch (_voice) {
                          'sexy' => '性感细腻',
                          'neutral' => '中性建议',
                          _ => '温柔知性',
                        },
                        primaryText: primaryText,
                        child: _optionList(
                          values: const ['gentle', 'sexy', 'neutral'],
                          selected: _voice,
                          label: (value) => switch (value) {
                            'sexy' => '性感细腻',
                            'neutral' => '中性建议',
                            _ => '温柔知性',
                          },
                          onSelected: _setVoice,
                          primaryText: primaryText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section({
    required String title,
    required Color surface,
    required Color primaryText,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _isDark ? const Color(0xFF303033) : const Color(0xFFEFEFF1),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 15, 16, 7),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: _isDark ? Colors.grey.shade500 : AppColors.textTertiary,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _settingRow({
    required String id,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required Color primaryText,
    required Widget child,
  }) {
    final expanded = _expanded == id;
    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = expanded ? null : id),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 20, color: iconColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: primaryText,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 12,
                          color: _isDark
                              ? Colors.grey.shade400
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: expanded ? 0.25 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
          ),
        ),
        if (expanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: child,
          ),
      ],
    );
  }

  Widget _segmented<T>({
    required List<T> values,
    required String Function(T) label,
    required T selected,
    required ValueChanged<T> onSelected,
  }) {
    return SegmentedButton<T>(
      segments: [
        for (final value in values)
          ButtonSegment<T>(value: value, label: Text(label(value))),
      ],
      selected: {selected},
      onSelectionChanged: (values) => onSelected(values.first),
      showSelectedIcon: false,
      expandedInsets: EdgeInsets.zero,
    );
  }

  Widget _optionList<T>({
    required List<T> values,
    required T selected,
    required String Function(T) label,
    required ValueChanged<T> onSelected,
    required Color primaryText,
  }) {
    return Column(
      children: [
        for (final value in values)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(label(value), style: TextStyle(color: primaryText)),
            trailing: value == selected
                ? const Icon(Icons.check_rounded, size: 19, color: Colors.blue)
                : null,
            onTap: () => onSelected(value),
          ),
      ],
    );
  }

  Widget _divider() => Divider(
        height: 1,
        indent: 68,
        color: _isDark ? const Color(0xFF303033) : const Color(0xFFF0EFF1),
      );
}
