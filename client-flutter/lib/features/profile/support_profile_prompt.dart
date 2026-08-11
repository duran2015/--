import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/route_paths.dart';
import 'support_profile_state.dart';

class SupportProfilePrompt extends ConsumerWidget {
  const SupportProfilePrompt({
    super.key,
    this.compact = false,
    this.allowDismiss = false,
  });

  final bool compact;
  final bool allowDismiss;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(supportProfileProvider);
    if (!profile.preferenceNeedsAttention ||
        (allowDismiss && profile.homePromptDismissed)) {
      return const SizedBox.shrink();
    }
    final colors = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () => context.push(
            '${RoutePaths.supportProfile}?section=preference',
          ),
          child: Padding(
            padding: EdgeInsets.all(compact ? 12 : 16),
            child: Row(
              children: [
                Container(
                  width: compact ? 36 : 40,
                  height: compact ? 36 : 40,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.tune_rounded, color: colors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        compact ? '完善偏好，匹配会更准确' : '告诉我们你更需要怎样的支持',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colors.onSurface,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        compact ? '约 1 分钟，可随时修改' : '完善咨询偏好，帮助推荐更适合你的咨询师。',
                        maxLines: compact ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                if (allowDismiss)
                  IconButton(
                    tooltip: '稍后再说',
                    onPressed: () => ref
                        .read(supportProfileProvider.notifier)
                        .dismissHomePrompt(),
                    icon: Icon(Icons.close_rounded, size: 18, color: colors.onSurfaceVariant),
                  )
                else
                  Icon(Icons.chevron_right_rounded,
                      color: colors.onSurfaceVariant, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
