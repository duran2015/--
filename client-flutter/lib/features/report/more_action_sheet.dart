import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// 「更多」弹层选项
enum MoreSheetAction { report, block }

/// 咨询师主页 / 预约详情「更多」操作弹层：举报 / 拉黑 / 取消。
/// iOS 参照：XYCounselorMoreSheetViewController（Figma 1530:1988）——
/// 行文案 15pt regular #222（非 semibold）。
class MoreActionSheet extends StatelessWidget {
  const MoreActionSheet({
    super.key,
    this.showBlock = true,
  });

  final bool showBlock;

  static const double _rowHeight = 47;
  static const double _gapHeight = 10;
  static const double _topRadius = 20;

  /// iOS：UIFont.systemFont(ofSize: 15) + #222222
  static final TextStyle _rowTextStyle = AppTextStyles.titleSmall.copyWith(
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  /// 弹出；返回所选操作，取消/蒙层关闭为 null。
  static Future<MoreSheetAction?> show(
    BuildContext context, {
    bool showBlock = true,
  }) {
    return showModalBottomSheet<MoreSheetAction>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      isScrollControlled: true,
      builder: (_) => MoreActionSheet(showBlock: showBlock),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Material(
      color: AppColors.innerBackground,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(_topRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _row(
            title: '举报',
            onTap: () => Navigator.of(context).pop(MoreSheetAction.report),
          ),
          if (showBlock) ...[
            const Divider(
                height: 0.5, thickness: 0.5, color: AppColors.hairline),
            _row(
              title: '拉黑',
              onTap: () => Navigator.of(context).pop(MoreSheetAction.block),
            ),
          ],
          const SizedBox(height: _gapHeight),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: double.infinity,
              color: Colors.white,
              padding: EdgeInsets.only(bottom: bottomInset),
              child: SizedBox(
                height: _rowHeight,
                child: Center(
                  child: Text('取消', style: _rowTextStyle),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row({required String title, required VoidCallback onTap}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: _rowHeight,
        color: Colors.white,
        alignment: Alignment.center,
        child: Text(title, style: _rowTextStyle),
      ),
    );
  }
}
