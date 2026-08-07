import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_response.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_background.dart';
import '../../core/widgets/app_loading_hud.dart';
import '../../core/widgets/app_nav_bar.dart';
import '../../core/widgets/app_toast.dart';
import '../../utils/image_utils.dart';
import '../counselor/counselor_api.dart';
import 'personality_models.dart';

/// 数字心理画像页（路由 /mine/personality?userId=，深链 9005）。
/// iOS 参照：XYPersonalityViewController（Figma 571:5157）。
/// - userId 非空：咨询师端查看指定用户（POST /consultant/home/userProfile）
/// - userId 空：用户端自身画像（POST /app/mine/profile；当前入口仅咨询师详情）
class PersonalityPage extends ConsumerStatefulWidget {
  const PersonalityPage({super.key, this.userId});

  final int? userId;

  @override
  ConsumerState<PersonalityPage> createState() => _PersonalityPageState();
}

class _PersonalityPageState extends ConsumerState<PersonalityPage> {
  PersonalityDisplay? _display;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final profile = await ref
          .read(counselorApiProvider)
          .fetchPersonality(userId: widget.userId);
      if (!mounted) return;
      setState(() {
        _display = PersonalityDisplay.fromProfile(profile);
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      AppToast.show(context, e.msg);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      AppToast.show(context, '加载失败，请稍后重试');
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _display;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      body: AppPageBackground(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 滚动区贴屏幕底（对齐其他详情页；底部安全距由 list padding 承担）
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  const AppNavBar(
                    title: '数字心理画像',
                    transparent: true,
                    lineHidden: true,
                  ),
                  Expanded(
                    child: d == null
                        ? const SizedBox.shrink()
                        : ListView(
                            padding: EdgeInsets.fromLTRB(
                              AppDimens.screenPadding,
                              16,
                              AppDimens.screenPadding,
                              24 + bottomInset,
                            ),
                            children: [
                              _UserInfoRow(display: d),
                              const SizedBox(height: AppDimens.gap10),
                              _MetricsBar(display: d),
                              const SizedBox(height: AppDimens.gap10),
                              _ProfileReportCard(display: d),
                              const SizedBox(height: AppDimens.gap10),
                              _TraitsCard(display: d),
                              const SizedBox(height: AppDimens.gap10),
                              _TrendCard(display: d),
                              const SizedBox(height: AppDimens.gap10),
                              _PastSummariesCard(display: d),
                              const SizedBox(height: AppDimens.gap10),
                              _PastWarningsCard(display: d),
                            ],
                          ),
                  ),
                ],
              ),
            ),
            if (_loading)
              const Positioned.fill(
                child: AppLoadingHud(message: '加载中'),
              ),
          ],
        ),
      ),
    );
  }
}

class _UserInfoRow extends StatelessWidget {
  const _UserInfoRow({required this.display});

  final PersonalityDisplay display;

  static const double _avatarSize = 58;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: _avatarSize,
          height: _avatarSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE5E5E5)),
            color: AppColors.dividerDark,
            image: (display.avatarUrl != null && display.avatarUrl!.isNotEmpty)
                ? DecorationImage(
                    image: ImageUtils.getImageProvider(display.avatarUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: (display.avatarUrl == null || display.avatarUrl!.isEmpty)
              ? const Icon(Icons.person, size: 32, color: Colors.white)
              : null,
        ),
        const SizedBox(width: AppDimens.gap12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                display.nickName.isEmpty ? '—' : display.nickName,
                style: AppTextStyles.title,
              ),
              const SizedBox(height: 4),
              Text(
                display.subtitle,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricsBar extends StatelessWidget {
  const _MetricsBar({required this.display});

  final PersonalityDisplay display;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimens.cardRadius),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFFF9F7FE), Color(0xFFFDFDFE)],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _MetricCol(
              title: '当前风险',
              value: display.currentRisk,
              color: PersonalityDisplay.riskColor,
            ),
          ),
          Container(width: 1, height: 40, color: AppColors.lightPurpleDivider),
          Expanded(
            child: _MetricCol(
              title: '近期测评',
              value: display.latestAssessment,
              color: PersonalityDisplay.assessmentColor,
            ),
          ),
          Container(width: 1, height: 40, color: AppColors.lightPurpleDivider),
          Expanded(
            child: _MetricCol(
              title: '心理韧性',
              value: display.resilience,
              color: PersonalityDisplay.resilienceColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCol extends StatelessWidget {
  const _MetricCol({
    required this.title,
    required this.value,
    required this.color,
  });

  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(title, style: TextStyle(fontSize: 12, color: color)),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.gradient});

  final String title;
  final List<Color> gradient;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(1.5),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: gradient,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(title, style: AppTextStyles.titleSmall),
      ],
    );
  }
}

class _WhiteCard extends StatelessWidget {
  const _WhiteCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimens.cardRadius),
      ),
      child: child,
    );
  }
}

Widget _emptyHint(String text) => Text(
      text,
      style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
    );

class _ProfileReportCard extends StatelessWidget {
  const _ProfileReportCard({required this.display});

  final PersonalityDisplay display;

  static const _teal = [Color(0xFF00D8E0), Color(0xFF00AFBE)];

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(title: '用户心理画像报告', gradient: _teal),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.innerBackground,
              borderRadius: BorderRadius.circular(AppDimens.radiusInner),
            ),
            child: display.profileParagraphs.isEmpty
                ? _emptyHint('暂无画像报告')
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0;
                          i < display.profileParagraphs.length;
                          i++) ...[
                        if (i > 0) const SizedBox(height: 16),
                        Text(
                          display.profileParagraphs[i],
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textPrimary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _TraitsCard extends StatelessWidget {
  const _TraitsCard({required this.display});

  final PersonalityDisplay display;

  static const _teal = [Color(0xFF00D8E0), Color(0xFF00AFBE)];

  @override
  Widget build(BuildContext context) {
    final tags = display.traitTags;
    return _WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(title: '主导人格与特质', gradient: _teal),
          const SizedBox(height: 12),
          if (tags.isEmpty)
            _emptyHint('暂无人格特质')
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in tags)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.innerBackground,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFE5E5E5)),
                    ),
                    child: Text(
                      t,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.display});

  final PersonalityDisplay display;

  static const _teal = [Color(0xFF00D8E0), Color(0xFF00AFBE)];

  @override
  Widget build(BuildContext context) {
    final hasScore = display.trendScores.any((s) => s != null);
    return _WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(title: '状态趋势（7次）', gradient: _teal),
          const SizedBox(height: 12),
          Container(
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppDimens.radiusInner),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF1F4FB), Color(0xFFF9F7FE)],
              ),
            ),
            child: hasScore
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(8, 10, 8, 6),
                    child: Column(
                      children: [
                        Expanded(
                          child: CustomPaint(
                            painter: _TrendLinePainter(display.trendScores),
                            size: Size.infinite,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            for (final label in display.trendLabels)
                              Expanded(
                                child: Text(
                                  label,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  )
                : Center(child: _emptyHint('暂无趋势数据')),
          ),
        ],
      ),
    );
  }
}

class _TrendLinePainter extends CustomPainter {
  _TrendLinePainter(this.scores);

  final List<int?> scores;

  @override
  void paint(Canvas canvas, Size size) {
    final pts = <Offset>[];
    final values = <double>[];
    for (var i = 0; i < scores.length; i++) {
      final s = scores[i];
      if (s == null) continue;
      values.add(s.toDouble());
      final x = scores.length <= 1
          ? size.width / 2
          : i * size.width / (scores.length - 1);
      pts.add(Offset(x, 0)); // y filled after min/max
    }
    if (values.isEmpty) return;
    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final span = (maxV - minV).abs() < 0.001 ? 1.0 : (maxV - minV);
    var vi = 0;
    for (var i = 0; i < scores.length; i++) {
      final s = scores[i];
      if (s == null) continue;
      final y = size.height - ((s - minV) / span) * size.height;
      pts[vi] = Offset(pts[vi].dx, y.clamp(2.0, size.height - 2));
      vi++;
    }
    final line = Paint()
      ..color = AppColors.brandTeal
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      path.lineTo(pts[i].dx, pts[i].dy);
    }
    canvas.drawPath(path, line);
    final dot = Paint()..color = AppColors.brandTeal;
    for (final p in pts) {
      canvas.drawCircle(p, 3, dot);
    }
  }

  @override
  bool shouldRepaint(covariant _TrendLinePainter oldDelegate) =>
      oldDelegate.scores != scores;
}

class _PastSummariesCard extends StatelessWidget {
  const _PastSummariesCard({required this.display});

  final PersonalityDisplay display;

  static const _orange = [Color(0xFFFFB371), Color(0xFFFF9200)];

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(title: '过往定性总结（内部）', gradient: _orange),
          const SizedBox(height: 12),
          if (display.pastSummaries.isEmpty)
            _emptyHint('暂无总结记录')
          else
            ...[
              for (var i = 0; i < display.pastSummaries.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                _PastSummaryItem(item: display.pastSummaries[i]),
              ],
            ],
        ],
      ),
    );
  }
}

class _PastSummaryItem extends StatelessWidget {
  const _PastSummaryItem({required this.item});

  final ({String date, String channel, String content}) item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFAF4),
        borderRadius: BorderRadius.circular(AppDimens.radiusInner),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                item.date,
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: const Color(0xFFE5E5E5)),
                ),
                child: Text(
                  item.channel,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          if (item.content.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              item.content,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PastWarningsCard extends StatelessWidget {
  const _PastWarningsCard({required this.display});

  final PersonalityDisplay display;

  static const _orange = [Color(0xFFFFB371), Color(0xFFFF9200)];

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(title: '过往预警记录', gradient: _orange),
          const SizedBox(height: 12),
          if (display.pastWarnings.isEmpty)
            _emptyHint('暂无预警记录')
          else
            ...[
              for (var i = 0; i < display.pastWarnings.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                _WarningItem(item: display.pastWarnings[i]),
              ],
            ],
        ],
      ),
    );
  }
}

class _WarningItem extends StatelessWidget {
  const _WarningItem({required this.item});

  final ({String title, String description, String date}) item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFAF4),
        borderRadius: BorderRadius.circular(AppDimens.radiusInner),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.title.isNotEmpty)
            Text(
              item.title,
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          if (item.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              item.description,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
          if (item.date.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              item.date,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
