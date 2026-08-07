import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/route_paths.dart';
import '../../core/theme/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_background.dart';
import '../../core/widgets/app_nav_bar.dart';
import '../../core/widgets/app_paged_list.dart';
import '../../core/widgets/app_toast.dart';
import '../../utils/load_image.dart';
import 'mine_api.dart';
import 'mine_models.dart';

/// 用户端「小结与建议」列表页（路由 /mine/summaries，深链 9002）。
/// iOS 参照：XYMineModule/XYMineModule/Classes/ViewController/
/// XYMineSummariesViewController.swift（Figma 457:2609）——
/// 下拉刷新 + 上拉分页（pageSize 10），空态「暂无小结与建议」15 #999 居中。
class MineSummariesPage extends ConsumerWidget {
  const MineSummariesPage({super.key});

  /// 打开小结详情页（1007）。
  /// iOS 参照：openSummaryDetail——orderId 缺失 toast「订单信息缺失」，
  /// 透传 orderId/counselorId。
  void _openSummaryDetail(BuildContext context, SummaryItem item) {
    final orderId = item.orderId;
    if (orderId == null) {
      AppToast.show(context, '订单信息缺失');
      return;
    }
    context.push(
      Uri(path: RoutePaths.summaryDetail, queryParameters: {
        'orderId': '$orderId',
        if (item.consultantId != null) 'counselorId': '${item.consultantId}',
      }).toString(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      // iOS：XYOrderBackgroundView + 透明导航栏，标题「咨询小结与建议」
      // 列表贴屏幕底（对齐 iOS tableView.bottom = superview）
      body: AppPageBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const AppNavBar(title: '咨询小结与建议', transparent: true),
              Expanded(
                child: AppPagedListView<SummaryItem>(
                  pageSize: 10, // iOS XYMineSummariesViewModel.pageSize
                  padding: EdgeInsets.only(
                    bottom: AppDimens.gap16 + bottomInset,
                  ),
                  // 空态：「暂无小结与建议」15 #999 居中（iOS emptyLabel）
                  emptyWidget: const Center(
                    child: Text(
                      '暂无小结与建议',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                  fetcher: (pageNum, pageSize) => ref
                      .read(mineApiProvider)
                      .fetchSummaries(pageNum: pageNum, pageSize: pageSize),
                  itemBuilder: (context, item, index) => _SummaryCell(
                    item: item,
                    onDetailTap: () => _openSummaryDetail(context, item),
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

/// 小结与建议列表卡片 Cell。
/// iOS 参照：XYMineSummaryCell（Figma 457:2625）——
/// 白卡圆角 12（投影 黑5% offset(0,2) blur10），左右外边距 15、上下各 6；
/// 头像 40 圆形（占位 person.circle.fill tint #12D6C8）+ 标题 15 w600 #222 +
/// 时间 12 #666；分隔线 0.5 #EEEEEE 距头像底 14；小结预览 12 #666 多行；
/// 建议徽标 #E9FAFF 圆角 8 高 22「包含 N 项建议」11 #00A6A1；
/// 「查看详情」12 #00BBC8 + 箭头 12 与徽标中线对齐。
class _SummaryCell extends StatelessWidget {
  const _SummaryCell({required this.item, required this.onDetailTap});

  final SummaryItem item;
  final VoidCallback onDetailTap;

  /// 头像直径（iOS avatarSize）
  static const double _avatarSize = 40;

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
      // iOS：卡片左右外边距 15（cardInset），上下各 6（cardTopGap）
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.screenPadding,
        vertical: AppDimens.gap6,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppDimens.cardRadius),
          boxShadow: _cardShadow,
        ),
        padding: const EdgeInsets.all(AppDimens.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // 咨询师头像 40 圆形（占位 tint #12D6C8）
                ClipOval(
                  child: SizedBox(
                    width: _avatarSize,
                    height: _avatarSize,
                    child: _buildAvatar(),
                  ),
                ),
                const SizedBox(width: AppDimens.gap10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 标题 15 w600 #222（如「林静 医生的小结」）
                      Text(
                        item.title,
                        style: AppTextStyles.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppDimens.gap6),
                      // 咨询时间 12 #666（如「06-05 14:00～14:50」）
                      Text(
                        item.timeDisplay,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // 分隔线 0.5 #EEEEEE，距头像底 14（iOS divider top = avatar.bottom + 14）
            const SizedBox(height: AppDimens.gap14),
            const Divider(
              height: 0.5,
              thickness: 0.5,
              color: AppColors.divider,
            ),
            const SizedBox(height: AppDimens.gap12),
            // 小结预览正文 12 #666 多行
            Text(
              item.preview,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppDimens.gap12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 建议条数徽标：#E9FAFF 圆角 8 高 22，文字 11 #00A6A1 左右各 8
                Container(
                  height: 22,
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppDimens.gap8),
                  decoration: BoxDecoration(
                    color: AppColors.brandTealLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '包含 ${item.adviceCount} 项建议',
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.brandTeal,
                    ),
                  ),
                ),
                const Spacer(),
                // 「查看详情」12 #00BBC8 + 箭头 12，热区高 30（iOS detailTapControl）
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onDetailTap,
                  child: SizedBox(
                    height: 30,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '查看详情',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.accentTeal,
                          ),
                        ),
                        const SizedBox(width: 2),
                        LoadImage(
                          AppAssets.mineSummaryDetailArrow,
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

  /// 头像：网络图（失败回退占位）或占位（person.circle.fill tint #12D6C8）。
  /// iOS 参照：XYMineSummaryCell.configure。
  Widget _buildAvatar() {
    final url = item.consultantAvatar;
    const placeholder = Icon(
      Icons.account_circle,
      size: _avatarSize,
      color: AppColors.avatarTintTeal,
    );
    if (url == null || url.isEmpty) return placeholder;
    return LoadImage(
      url,
      width: _avatarSize,
      height: _avatarSize,
      fit: BoxFit.cover,
      errorWidget: placeholder,
    );
  }
}
