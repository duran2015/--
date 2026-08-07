import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/route_paths.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_background.dart';
import '../../core/widgets/app_paged_list.dart';
import '../../core/widgets/person_avatar.dart';
import '../report/report_service.dart';
import '../profile/support_profile_prompt.dart';
import 'consultant_api.dart';
import 'consultant_models.dart';

/// 底部导航中的真人咨询独立页。
class ConsultantTabPage extends StatelessWidget {
  const ConsultantTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppPageBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '真人倾听师',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '先看擅长与可约时间，再选择适合你的咨询师',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: SupportProfilePrompt(compact: true),
              ),
              const Expanded(child: ConsultantListView()),
            ],
          ),
        ),
      ),
    );
  }
}

class ConsultantListView extends ConsumerWidget {
  const ConsultantListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blockedTick = ref.watch(counselorBlockedTickProvider);
    final bottomInset = MediaQuery.of(context).padding.bottom + 16;
    return AppPagedListView<Consultant>(
      key: ValueKey('consultant_list_$blockedTick'),
      pageSize: 10,
      padding: EdgeInsets.only(top: 4, bottom: bottomInset),
      fetcher: (pageNum, pageSize) => ref
          .read(consultantApiProvider)
          .fetchList(pageNum: pageNum, pageSize: pageSize),
      itemBuilder: (context, item, index) => ConsultantCell(
        consultant: item,
        onTap: () {
          final id = item.consultantId;
          if (id == null) return;
          context.push('${RoutePaths.consultantDetail}?consultantId=$id');
        },
      ),
    );
  }
}

/// 用户决策优先级：擅长匹配 → 资质 → 可约时间/方式 → 经验口碑 → 价格。
/// 列表只呈现能帮助初筛的信息，完整受训与介绍仍在详情页查看。
class ConsultantCell extends StatelessWidget {
  const ConsultantCell({super.key, required this.consultant, this.onTap});

  final Consultant consultant;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final specialties = consultant.specialtyTags.take(3).toList();
    final style = consultant.styleTags.firstOrNull;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: Colors.white.withValues(alpha: 0.96),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.7)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PersonAvatar(
                  name: consultant.displayName,
                  seed: '${consultant.consultantId}',
                  imageUrl: consultant.avatar,
                  size: 60,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _nameAndRating(context),
                      if ((consultant.title ?? '').isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (consultant.isVerified) ...[
                              Icon(
                                Icons.verified_rounded,
                                size: 15,
                                color: colors.primary,
                              ),
                              const SizedBox(width: 4),
                            ],
                            Expanded(
                              child: Text(
                                consultant.title!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: colors.onSurfaceVariant,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (specialties.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final item in specialties)
                              _tag(item, colors.primaryContainer,
                                  colors.onPrimaryContainer),
                            if (style != null)
                              _tag(style, colors.secondaryContainer,
                                  colors.onSecondaryContainer),
                          ],
                        ),
                      ],
                      const SizedBox(height: 12),
                      _availabilityRow(context),
                      const SizedBox(height: 10),
                      _trustAndPriceRow(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _nameAndRating(BuildContext context) {
    final rating = consultant.ratingScore;
    final reviews = consultant.reviewCount;
    return Row(
      children: [
        Expanded(
          child: Text(
            consultant.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
          ),
        ),
        if (rating != null) ...[
          const Icon(Icons.star_rounded, size: 17, color: Color(0xFFFFB02E)),
          const SizedBox(width: 2),
          Text(
            '${rating.toStringAsFixed(1)}${reviews == null ? '' : ' ($reviews)'}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _tag(String text, Color background, Color foreground) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: foreground,
        ),
      ),
    );
  }

  Widget _availabilityRow(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final modes = consultant.supportModes.join('/');
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFE6F6EF),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.schedule_rounded,
                size: 14,
                color: Color(0xFF16835F),
              ),
              const SizedBox(width: 4),
              Text(
                '${consultant.nextAvailableTime ?? '近期'} 可约',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF126B50),
                ),
              ),
            ],
          ),
        ),
        if (modes.isNotEmpty) ...[
          const SizedBox(width: 8),
          Icon(Icons.headset_mic_outlined,
              size: 15, color: colors.onSurfaceVariant),
          const SizedBox(width: 3),
          Expanded(
            child: Text(
              modes,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
            ),
          ),
        ],
      ],
    );
  }

  Widget _trustAndPriceRow(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final facts = <String>[
      if ((consultant.experienceYears ?? 0) > 0)
        '${consultant.experienceYears}年经验',
      if ((consultant.totalServiceHours ?? 0) > 0)
        '${consultant.totalServiceHours}+小时',
    ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Text(
            facts.join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
          ),
        ),
        if (consultant.priceText != null)
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: '¥', style: TextStyle(fontSize: 13)),
                TextSpan(
                  text: consultant.priceText,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const TextSpan(
                  text: '/50分钟起',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w400),
                ),
              ],
              style: TextStyle(color: colors.primary),
            ),
          ),
      ],
    );
  }
}
