import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_text_styles.dart';
import '../../utils/image_utils.dart';
import '../../utils/load_image.dart';
import 'counselor_models.dart';

/// 咨询方式徽标：渐变底 + 图标 + 文案（高 18，圆角 9，11 w600）。
/// iOS 参照：XYCounselorSupportModeBadgeView（Figma 571:5777）。
class CounselorModeBadge extends StatelessWidget {
  const CounselorModeBadge({
    super.key,
    required this.mode,
    this.showsIcon = true,
  });

  final CounselorSupportMode mode;

  /// 详情页描边徽标以外的场景均带图标；false 时仅文案（左右 inset 10）
  final bool showsIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 18,
      padding: showsIcon
          ? const EdgeInsets.only(left: 6, right: 8)
          : const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: mode.gradientColors),
        borderRadius: BorderRadius.circular(AppDimens.radiusConsultTag),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showsIcon) ...[
            LoadImage(
              mode.iconAsset,
              width: 12,
              height: 12,
              errorWidget: const SizedBox(width: 12, height: 12),
            ),
            const SizedBox(width: 3),
          ],
          Text(
            mode.title,
            style: AppTextStyles.label.copyWith(
              fontWeight: FontWeight.w600,
              color: mode.textColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// 详情页顶部咨询方式描边徽标（描边 #999 0.5、圆角 9、高 18、图标 12 + 11 #222）。
/// iOS 参照：XYCounselorDetailOutlineModeBadgeView（Figma 571:5011）。
class CounselorOutlineModeBadge extends StatelessWidget {
  const CounselorOutlineModeBadge({super.key, required this.mode});

  final CounselorSupportMode mode;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 18,
      padding: const EdgeInsets.only(left: 6, right: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimens.radiusConsultTag),
        border: Border.all(color: AppColors.textTertiary, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          LoadImage(
            mode.iconAsset,
            width: 12,
            height: 12,
            errorWidget: const SizedBox(width: 12, height: 12),
          ),
          const SizedBox(width: 3),
          Text(
            mode.detailTitle,
            style: AppTextStyles.label.copyWith(color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

/// 订单卡片顶部信息行：时段 20 w600 + 日期 12 w600 + 分隔线 + 头像 18 +
/// 昵称 12 + 右侧咨询方式徽标。
/// iOS 参照：XYCounselorPendingOrderCell.setupHeaderRow——
/// 行高 24；日期与时段 lastBaseline 对齐（offset -2）；头像/徽标 centerY。
class CounselorOrderCardHeader extends StatelessWidget {
  const CounselorOrderCardHeader({
    super.key,
    required this.timeText,
    required this.dayText,
    required this.userName,
    this.userAvatar,
    required this.mode,
  });

  final String timeText;
  final String dayText;
  final String userName;
  final String? userAvatar;
  final CounselorSupportMode mode;

  /// iOS timeLabel 固定高度 24
  static const double _headerHeight = 24;

  @override
  Widget build(BuildContext context) {
    final hasDay = dayText.isNotEmpty;
    return SizedBox(
      height: _headerHeight,
      child: Row(
        children: [
          // 时段 + 日期：基线对齐（对齐 iOS lastBaseline -2）
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                timeText,
                style: AppTextStyles.titleXLarge.copyWith(height: 1),
              ),
              if (hasDay) ...[
                const SizedBox(width: AppDimens.gap8),
                Transform.translate(
                  offset: const Offset(0, -2),
                  child: Text(
                    dayText,
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      height: 1,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (hasDay) ...[
            const SizedBox(width: AppDimens.gap8),
            Container(
              width: 1,
              height: 12,
              color: AppColors.lightPurpleDivider,
            ),
            const SizedBox(width: AppDimens.gap8),
          ] else
            const SizedBox(width: AppDimens.gap8),
          // 头像 / 昵称 / 徽标：相对行高垂直居中（对齐 iOS centerY）
          CircleAvatar(
            radius: 9,
            backgroundColor: AppColors.dividerDark,
            backgroundImage:
                (userAvatar != null && userAvatar!.isNotEmpty)
                    ? ImageUtils.getImageProvider(userAvatar!)
                    : null,
            child: (userAvatar == null || userAvatar!.isEmpty)
                ? const Icon(Icons.person, size: 12, color: Colors.white)
                : null,
          ),
          const SizedBox(width: AppDimens.gap6),
          Expanded(
            child: Text(
              userName,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textPrimary,
                height: 1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppDimens.gap8),
          CounselorModeBadge(mode: mode),
        ],
      ),
    );
  }
}

/// 用户标签流式布局（自动换行；标签 10 #666、描边 #CCCCCC 0.5、圆角 3、高 15）。
/// iOS 参照：XYCounselorOrderTagFlowView（水平 4.5、垂直 6）。
///
/// ⚠ 不可给标签 Container 设 `alignment`：Wrap 给子项「0～父宽」松约束时，
/// 带 alignment 的 Container 会先撑满最大宽再对齐子项，表现为「一标签占满一行」。
class CounselorTagFlow extends StatelessWidget {
  const CounselorTagFlow({super.key, required this.tags});

  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 4.5,
      runSpacing: 6,
      children: [
        for (final tag in tags) _CounselorTagChip(text: tag),
      ],
    );
  }
}

/// 单个列表标签（固有宽度 = 左右 padding + 文字宽）。
class _CounselorTagChip extends StatelessWidget {
  const _CounselorTagChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 15,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimens.radiusTiny),
        border: Border.all(color: AppColors.placeholder, width: 0.5),
      ),
      // 用行高撑满 15，字形垂直居中；勿设 alignment（见类注释）
      child: Text(
        text,
        softWrap: false,
        style: const TextStyle(
          fontSize: 10,
          height: 15 / 10,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

/// 右箭头图标（ic_workbench_chevron_right 为 svg 迁移产物，
/// 未引入 flutter_svg 依赖，用内置图标近似——视觉差异已记录，
/// 与 chat_input_bar 面板图标同一约定）。
class CounselorChevronRight extends StatelessWidget {
  const CounselorChevronRight({super.key, this.size = 12, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.chevron_right,
      size: size * 1.5,
      color: color ?? AppColors.textPrimary,
    );
  }
}
