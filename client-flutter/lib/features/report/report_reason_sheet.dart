import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_response.dart';
import '../../core/theme/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_toast.dart';
import '../../utils/load_image.dart';
import 'report_models.dart';
import 'report_service.dart';

/// 举报理由选择弹层。
/// iOS 参照：XYReportReasonSheetViewController（Figma 1530:2004 / 1530:2025）。
class ReportReasonSheet extends ConsumerStatefulWidget {
  const ReportReasonSheet({super.key});

  static const double _headerHeight = 60;
  static const double _rowHeight = 45;
  static const double _listHeight = _rowHeight * 6;
  static const double _gapHeight = 10;
  static const double _bottomRowHeight = 47;
  static const double _topRadius = 20;
  static const double _checkSize = 16;

  /// iOS：理由行 / 底部按钮 UIFont.systemFont(ofSize: 15) regular #222
  static const TextStyle _rowTextStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  /// 选中理由 +「提交」：#00A6A1（与 iOS accent / 勾选图标同色）。
  /// 用 w500：Flutter 中文 regular 渲染偏细，medium 更贴近 iOS PingFang 观感。
  static const TextStyle _accentTextStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppColors.brandTeal,
    height: 1.2,
  );

  /// 弹出；返回选中理由，取消/失败关闭为 null。
  static Future<ReportReason?> show(BuildContext context) {
    return showModalBottomSheet<ReportReason>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      isScrollControlled: true,
      builder: (_) => const ReportReasonSheet(),
    );
  }

  @override
  ConsumerState<ReportReasonSheet> createState() => _ReportReasonSheetState();
}

class _ReportReasonSheetState extends ConsumerState<ReportReasonSheet> {
  List<ReportReason> _reasons = const [];
  int? _selectedIndex;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchReasons());
  }

  Future<void> _fetchReasons() async {
    try {
      final reasons =
          await ref.read(reportServiceProvider).fetchReportReasons();
      if (!mounted) return;
      setState(() {
        _reasons = reasons;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      AppToast.show(context, e.msg.isEmpty ? '加载失败' : e.msg);
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      AppToast.show(context, '加载失败');
      Navigator.of(context).pop();
    }
  }

  void _bottomTapped() {
    final index = _selectedIndex;
    if (index != null && index >= 0 && index < _reasons.length) {
      Navigator.of(context).pop(_reasons[index]);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final selected = _selectedIndex != null;
    return Material(
      color: AppColors.innerBackground,
      surfaceTintColor: Colors.transparent,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(ReportReasonSheet._topRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: ReportReasonSheet._headerHeight,
            width: double.infinity,
            color: Colors.white,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '请选择举报理由',
              style: AppTextStyles.title.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            height: ReportReasonSheet._listHeight,
            width: double.infinity,
            color: Colors.white,
            child: _loading
                ? const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _reasons.length,
                    itemBuilder: (context, index) {
                      final reason = _reasons[index];
                      final isSelected = _selectedIndex == index;
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => setState(() => _selectedIndex = index),
                        child: SizedBox(
                          height: ReportReasonSheet._rowHeight,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    reason.label,
                                    style: isSelected
                                        ? ReportReasonSheet._accentTextStyle
                                        : ReportReasonSheet._rowTextStyle,
                                  ),
                                ),
                                if (isSelected)
                                  LoadImage(
                                    AppAssets.reportReasonCheck,
                                    width: ReportReasonSheet._checkSize,
                                    height: ReportReasonSheet._checkSize,
                                    errorWidget: const Icon(
                                      Icons.check,
                                      size: ReportReasonSheet._checkSize,
                                      color: AppColors.brandTeal,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: ReportReasonSheet._gapHeight),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _bottomTapped,
            child: Container(
              width: double.infinity,
              color: Colors.white,
              padding: EdgeInsets.only(bottom: bottomInset),
              child: SizedBox(
                height: ReportReasonSheet._bottomRowHeight,
                child: Center(
                  child: Text(
                    selected ? '提交' : '取消',
                    style: selected
                        ? ReportReasonSheet._accentTextStyle
                        : ReportReasonSheet._rowTextStyle,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
