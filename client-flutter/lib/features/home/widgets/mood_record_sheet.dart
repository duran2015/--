import 'package:flutter/material.dart';

import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../utils/load_image.dart';
import '../home_models.dart';

/// 记录今天心情的底部弹窗：选择情绪后点「确认」提交。
/// iOS 参照：XYHomeModule/Classes/View/XYMoodRecordSheetView.swift。
///
/// 用法：
/// ```dart
/// final option = await MoodRecordSheet.show(context);
/// if (option != null) { ... submit ... }
/// ```
class MoodRecordSheet extends StatefulWidget {
  const MoodRecordSheet({super.key, this.options = kMoodOptions});

  /// 可选情绪列表
  final List<MoodOption> options;

  /// 从底部弹出情绪选择弹窗；返回选中的情绪（取消为 null）。
  static Future<MoodOption?> show(BuildContext context) {
    return showModalBottomSheet<MoodOption>(
      context: context,
      backgroundColor: Colors.transparent,
      // iOS 遮罩：黑色 alpha 0.7
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (_) => const MoodRecordSheet(),
    );
  }

  @override
  State<MoodRecordSheet> createState() => _MoodRecordSheetState();
}

class _MoodRecordSheetState extends State<MoodRecordSheet> {
  /// 当前选中索引
  int? _selectedIndex;

  /// 确认按钮渐变方向（iOS applyBrandGradient：startPoint (1,0.5) → (0,0.5)，
  /// 即 start 色在右、end 色在左）。
  static const LinearGradient _brandGradient = LinearGradient(
    begin: Alignment.centerRight,
    end: Alignment.centerLeft,
    colors: [AppColors.brandGradientStart, AppColors.brandGradientEnd],
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.innerBackground, // #F7F8FC
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimens.gap20), // iOS 顶部圆角 20
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题行：top 24，16 w600 居中；关闭按钮与标题同中线，右 15，图 16×16
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Center(
                    child: Text('今天感觉怎么样？', style: AppTextStyles.title),
                  ),
                  Positioned(
                    right: AppDimens.screenPadding,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => Navigator.of(context).pop(),
                      child: LoadImage(
                        AppAssets.homeSheetClose,
                        width: 16,
                        height: 16,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // 情绪选项横向容器：top 标题底 +24，左右 15，高 96，间距 8
            Padding(
              padding: const EdgeInsets.only(
                top: 24,
                left: AppDimens.screenPadding,
                right: AppDimens.screenPadding,
              ),
              child: SizedBox(
                height: 96,
                child: Row(
                  children: [
                    for (var i = 0; i < widget.options.length; i++) ...[
                      if (i > 0) const SizedBox(width: AppDimens.gap8),
                      Expanded(
                        child: _MoodOptionItem(
                          option: widget.options[i],
                          selected: _selectedIndex == i,
                          onTap: () => setState(() => _selectedIndex = i),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // 确认按钮：top 选项底 +24，左右 15，高 53 圆角 26.5，bottom 34
            Padding(
              padding: const EdgeInsets.only(
                top: 24,
                bottom: 34,
                left: AppDimens.screenPadding,
                right: AppDimens.screenPadding,
              ),
              child: Opacity(
                // iOS：未选中 alpha 0.3 且不可点
                opacity: _selectedIndex == null ? 0.3 : 1,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _selectedIndex == null
                      ? null
                      : () => Navigator.of(context)
                          .pop(widget.options[_selectedIndex!]),
                  child: Container(
                    height: AppDimens.confirmButtonHeight, // 53
                    decoration: BoxDecoration(
                      gradient: _brandGradient,
                      borderRadius: BorderRadius.circular(
                        AppDimens.confirmButtonRadius, // 26.5
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '确认',
                      style: AppTextStyles.title.copyWith(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 单个情绪选项。
/// iOS 参照：XYMoodRecordSheetView.makeOptionItem / optionTapped
/// （选中：白底 + #E2ECFF 投影 offset(0,2) blur 10 + 标题 w600；
/// 未选中：透明底 + alpha 0.5）。
class _MoodOptionItem extends StatelessWidget {
  const _MoodOptionItem({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final MoodOption option;
  final bool selected;
  final VoidCallback onTap;

  /// 选中投影色（iOS #E2ECFF）
  static const Color _selectedShadow = Color(0xFFE2ECFF);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Opacity(
        opacity: selected ? 1 : 0.5,
        child: Container(
          decoration: BoxDecoration(
            color: selected ? AppColors.cardBackground : Colors.transparent,
            borderRadius: BorderRadius.circular(AppDimens.cardRadiusLarge),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: _selectedShadow,
                      offset: Offset(0, 2),
                      blurRadius: 10,
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              const SizedBox(height: AppDimens.gap8),
              // 图标 34
              LoadImage(
                option.iconAsset,
                width: 34,
                height: 34,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: AppDimens.gap8),
              // 文案 13，选中 w600
              Text(
                option.title,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              const SizedBox(height: AppDimens.gap8),
            ],
          ),
        ),
      ),
    );
  }
}
