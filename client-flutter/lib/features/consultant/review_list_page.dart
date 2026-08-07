import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_response.dart';
import '../../core/theme/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_loading_hud.dart';
import '../../core/widgets/app_nav_bar.dart';
import '../../core/widgets/app_paged_list.dart';
import '../../core/widgets/app_states.dart';
import '../../core/widgets/app_toast.dart';
import '../../utils/load_image.dart';
import '../report/report_models.dart';
import '../report/report_reason_sheet.dart';
import '../report/report_service.dart';
import 'consultant_api.dart';
import 'consultant_models.dart';

/// 全部评价分页页（/app/consultant/review-list）。
/// 主路径已改为咨询师主页内「更多评价」内嵌分页；本页保留兼容深链。
class ReviewListPage extends ConsumerStatefulWidget {
  const ReviewListPage({super.key, required this.consultantId});

  final int consultantId;

  @override
  ConsumerState<ReviewListPage> createState() => _ReviewListPageState();
}

class _ReviewListPageState extends ConsumerState<ReviewListPage> {
  bool _reporting = false;

  Future<void> _reportReview(int reviewId) async {
    final reason = await ReportReasonSheet.show(context);
    if (!mounted || reason == null) return;
    setState(() => _reporting = true);
    try {
      await ref.read(reportServiceProvider).submitReport(
            targetType: ReportTargetType.review,
            targetId: '$reviewId',
            reason: reason,
          );
      if (!mounted) return;
      setState(() => _reporting = false);
      AppToast.show(context, '举报已收到，我们将在 24 小时内处理');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _reporting = false);
      AppToast.show(context, e.msg.isEmpty ? '举报失败' : e.msg);
    } catch (_) {
      if (!mounted) return;
      setState(() => _reporting = false);
      AppToast.show(context, '举报失败');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                const AppNavBar(title: '来访者评价', transparent: true),
                Expanded(
                  child: AppPagedListView<ConsultantReview>(
                    pageSize: 5,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.screenPadding,
                      vertical: AppDimens.gap10,
                    ),
                    emptyWidget: const AppEmptyView(message: '暂无评价'),
                    fetcher: (pageNum, pageSize) =>
                        ref.read(consultantApiProvider).fetchReviewList(
                              consultantId: widget.consultantId,
                              pageNum: pageNum,
                              pageSize: pageSize,
                            ),
                    itemBuilder: (context, item, index) => Container(
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      padding: const EdgeInsets.all(AppDimens.cardPadding),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius:
                            BorderRadius.circular(AppDimens.cardRadius),
                      ),
                      child: ReviewItemTile(
                        review: item,
                        onReport: item.reviewId == null
                            ? null
                            : () => _reportReview(item.reviewId!),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_reporting)
            const Positioned.fill(
              child: AppLoadingHud(message: '提交中'),
            ),
        ],
      ),
    );
  }
}

/// 单条评价条目（头像/昵称/时间/举报/正文/「Ta认为咨询师」标签）。
/// iOS 参照：XYCounselorDetailViewController.makeReviewItem。
class ReviewItemTile extends StatelessWidget {
  const ReviewItemTile({
    super.key,
    required this.review,
    this.onReport,
  });

  final ConsultantReview review;

  /// 举报回调；仅 [review.reviewId] 有效且本回调非空时展示举报入口。
  final VoidCallback? onReport;

  @override
  Widget build(BuildContext context) {
    final tags = review.tagNames.where((t) => t.isNotEmpty).toList();
    final showReport = onReport != null && review.reviewId != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 顶部信息行（头像 + 昵称 + 时间 + 举报，高 24）
        SizedBox(
          height: 24,
          child: Row(
            children: [
              _avatar(),
              const SizedBox(width: AppDimens.gap8),
              Expanded(
                child: Text(
                  review.displayNickName,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                reviewDateText(review.createTime),
                style: AppTextStyles.caption,
              ),
              if (showReport) ...[
                const SizedBox(width: AppDimens.gap8),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onReport,
                  child: Padding(
                    // 扩大点击热区（对齐 iOS make.height = header）
                    padding: const EdgeInsets.symmetric(
                      horizontal: 2,
                      vertical: 4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 12,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '举报',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppDimens.gap10),
        // 评价正文
        Text(
          review.content ?? '',
          style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
        ),
        // 「Ta认为咨询师：xxx」标签（多条用「、」拼接；无则收起）
        if (tags.isNotEmpty) ...[
          const SizedBox(height: AppDimens.gap10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.innerBackground,
              borderRadius: BorderRadius.circular(AppDimens.radiusTiny),
            ),
            child: Text(
              'Ta认为咨询师：${tags.join('、')}',
              style: AppTextStyles.badge.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textTertiary,
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// 评价头像（有 URL 用网络图，无 URL 用匿名头像 ic_review_anonymous 24×24）
  /// iOS 参照：XYCounselorDetailViewController.makeReviewAvatar
  Widget _avatar() {
    if (review.hasAvatar) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: LoadImage(
          review.userAvatar!,
          width: 24,
          height: 24,
          fit: BoxFit.cover,
          errorWidget: _anonymousAvatar(),
        ),
      );
    }
    return _anonymousAvatar();
  }

  Widget _anonymousAvatar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: LoadImage(
        AppAssets.icReviewAnonymous,
        width: 24,
        height: 24,
        fit: BoxFit.cover,
      ),
    );
  }
}
