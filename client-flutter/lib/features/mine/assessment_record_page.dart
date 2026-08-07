import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_response.dart';
import '../../core/router/route_paths.dart';
import '../../core/theme/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_background.dart';
import '../../core/widgets/app_nav_bar.dart';
import '../../core/widgets/app_refresh_indicator.dart';
import '../../core/widgets/app_states.dart';
import '../../core/widgets/app_toast.dart';
import '../../utils/load_image.dart';
import 'mine_api.dart';
import 'mine_models.dart';

/// 用户端「量表测试记录」列表页（路由 /mine/assessments，深链 9003）。
/// iOS 参照：XYMineModule/XYMineModule/Classes/ViewController/
/// XYMineAssessmentRecordViewController.swift（Figma 970:2707）——
/// 共享渐变背景 + 透明导航栏；列表卡片 + 空态「暂无量表测试记录」15 #999 居中。
class AssessmentRecordPage extends ConsumerStatefulWidget {
  const AssessmentRecordPage({super.key});

  @override
  ConsumerState<AssessmentRecordPage> createState() =>
      _AssessmentRecordPageState();
}

class _AssessmentRecordPageState extends ConsumerState<AssessmentRecordPage> {
  List<AssessmentRecordItem> _items = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  /// 拉取量表测试记录（iOS 参照：loadRecords；失败 toast 保留旧数据）。
  Future<void> _loadRecords() async {
    try {
      final items = await ref.read(mineApiProvider).fetchAssessmentRecords();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      AppToast.show(
        context,
        e is ApiException ? e.msg : '加载失败，请稍后重试',
      );
    }
  }

  /// 打开测评报告详情（9004）。
  /// iOS 参照：openRecordDetail——userAssessId 缺失 toast「测评信息缺失」，
  /// 透传 userAssessId/title/h5Link。
  void _openRecordDetail(AssessmentRecordItem item) {
    final userAssessId = item.userAssessId;
    if (userAssessId == null) {
      AppToast.show(context, '测评信息缺失');
      return;
    }
    context.push(
      Uri(path: RoutePaths.assessmentReport, queryParameters: {
        'userAssessId': '$userAssessId',
        'title': item.title,
        if (item.h5Link != null && item.h5Link!.isNotEmpty)
          'h5Link': item.h5Link!,
      }).toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      // iOS：XYOrderBackgroundView + 透明导航栏，标题「量表测试记录」
      // 列表贴屏幕底（对齐 iOS tableView.bottom = superview）
      body: AppPageBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const AppNavBar(title: '量表测试记录', transparent: true),
              Expanded(
                child: _loading
                    ? const AppLoadingView()
                    : _items.isEmpty
                        // 空态：「暂无量表测试记录」15 #999 居中（iOS emptyLabel）
                        ? const Center(
                            child: Text(
                              '暂无量表测试记录',
                              style: TextStyle(
                                fontSize: 15,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          )
                        : AppRefreshIndicator(
                            onRefresh: _loadRecords,
                            child: ListView.builder(
                              physics:
                                  const AlwaysScrollableScrollPhysics(),
                              // iOS：tableHeaderView 顶部留白 10，contentInset 底部 16
                              padding: EdgeInsets.only(
                                top: AppDimens.gap10,
                                bottom: AppDimens.gap16 + bottomInset,
                              ),
                              itemCount: _items.length,
                              itemBuilder: (context, index) =>
                                  _AssessmentRecordCell(
                                item: _items[index],
                                onDetailTap: () =>
                                    _openRecordDetail(_items[index]),
                              ),
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 量表测试记录列表卡片 Cell。
/// iOS 参照：XYMineAssessmentRecordCell（Figma 970:2723）——
/// 白卡 108 高圆角 12（投影 黑5% offset(0,2) blur10），左右外边距 15、卡片间距 10；
/// 标题 16 w600 #222 距顶 18；得分胶囊（#F7F8FC 圆角 9 高 18，图标 14 + 分数 14 bold #666）
/// 右上距顶 19；日期 11 #999 距标题 8；等级 14 w600 #525EE1 + 底部渐变条 4 高
/// （右#DCE5FF→左#C9E0EF）左下；「查看详情」12 #00A6A1 + 箭头 12 右下与等级中线对齐。
class _AssessmentRecordCell extends StatelessWidget {
  const _AssessmentRecordCell({required this.item, required this.onDetailTap});

  final AssessmentRecordItem item;
  final VoidCallback onDetailTap;

  /// 卡片高度（iOS cardHeight，Figma 216 → 108）
  static const double _cardHeight = 108;

  /// 卡片内边距（iOS innerPadding）
  static const double _innerPadding = 15;

  /// 得分胶囊高度/圆角（iOS scoreHeight/scoreCorner）
  static const double _scoreHeight = 18;
  static const double _scoreCorner = 9;

  /// 卡片投影（iOS：黑 5%，offset(0,2)，blur 10）
  static const List<BoxShadow> _cardShadow = [
    BoxShadow(
      color: Color(0x0D000000),
      offset: Offset(0, 2),
      blurRadius: 10,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      // iOS：卡片左右外边距 15（cardInset），底间距 10（cardGap）
      padding: const EdgeInsets.only(
        left: AppDimens.screenPadding,
        right: AppDimens.screenPadding,
        bottom: AppDimens.gap10,
      ),
      child: Container(
        height: _cardHeight,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppDimens.cardRadius),
          boxShadow: _cardShadow,
        ),
        padding: const EdgeInsets.all(_innerPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // iOS：标题距卡片顶 18（内边距 15 + 3），得分胶囊距顶 19（再 +1）
            // 修复 108 固定卡高内 2px 溢出：顶部 3→2、详情热区 30→26（视觉不变）
            const SizedBox(height: 2),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 量表名称 16 w600 #222（右界不超过得分胶囊左 -8）
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: AppTextStyles.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppDimens.gap8),
                      // 测评日期 11 #999
                      Text(
                        item.dateText,
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.textTertiary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppDimens.gap8),
                // 得分胶囊：#F7F8FC 圆角 9 高 18，图标 14 左 8 + 分数 14 bold #666 右 10
                if (item.score != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Container(
                      height: _scoreHeight,
                      decoration: BoxDecoration(
                        color: AppColors.innerBackground,
                        borderRadius: BorderRadius.circular(_scoreCorner),
                      ),
                      padding: const EdgeInsets.only(left: 8, right: 10),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          LoadImage(
                            AppAssets.mineAssessmentRecordGauge,
                            width: 14,
                            height: 14,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(width: AppDimens.gap4),
                          Text(
                            '${item.score}',
                            // iOS：DINAlternate-Bold → 等宽数字 bold
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 等级文案 14 w600 #525EE1 + 底部渐变条（Figma 970:2727 标签样式）
                if (item.levelText != null)
                  IntrinsicWidth(
                    child: Stack(
                      children: [
                        // 底部渐变条 4 高（右 #DCE5FF → 左 #C9E0EF）
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            height: 4,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerRight,
                                end: Alignment.centerLeft,
                                colors: [
                                  AppColors.recordLevelGradientStart,
                                  AppColors.recordLevelGradientEnd,
                                ],
                              ),
                            ),
                          ),
                        ),
                        Text(
                          item.levelText!,
                          style: AppTextStyles.bodyLargeStrong.copyWith(
                            color: AppColors.indigo,
                          ),
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                const Spacer(),
                // 「查看详情」12 #00A6A1 + 箭头 12，热区高 30（iOS detailTapControl）
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onDetailTap,
                  child: SizedBox(
                    height: 26,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '查看详情',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.brandTeal,
                          ),
                        ),
                        const SizedBox(width: 2),
                        LoadImage(
                          AppAssets.mineAssessmentRecordArrow,
                          width: 12,
                          height: 12,
                          fit: BoxFit.contain,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
