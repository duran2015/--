import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/im/im_models.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../consult_status_api.dart';
import '../../../utils/load_image.dart';
import 'chat_card_logic.dart';
import 'chat_card_style.dart';

/// for_evaluate_middle / for_summary_middle 共用布局壳。
/// iOS 参照：TUIForEvaluateMiddleCell_Minimalist / TUIForSummaryMiddleCell_
/// Minimalist（共用 Figma 441:1777：#EBFEFF→#FDFDFE 渐变卡 + 图标 + 标题/描述
/// + 渐变主按钮；type=2 已完成置灰 #F6F6F6/#666）。
class _ActionMiddleCard extends StatelessWidget {
  const _ActionMiddleCard({
    required this.card,
    required this.iconAsset,
    required this.iconWithBadge,
    required this.buttonTitle,
    required this.visible,
    required this.onTap,
    this.appCompleted,
  });

  final ImCustomCard card;
  final String iconAsset;

  /// 是否带白圆底（evaluate 有 48 白圆 badge + 图标 30；summary 图标 48 直出，
  /// iOS 参照：TUIForSummaryMiddleCell iconBadgeView backgroundColor .clear）
  final bool iconWithBadge;
  final String buttonTitle;

  /// 操作按钮是否可见（身份语义由调用方按 chat_card_logic 判定）
  final bool visible;
  final VoidCallback onTap;

  /// app 自有数据判定的「已完成」（ADR-0005）；null=尚未拉到，回退 IM 消息 type。
  final bool? appCompleted;

  @override
  Widget build(BuildContext context) {
    final completed = isActionCardCompleted(card, appCompleted: appCompleted);
    return Container(
      width: ChatCardStyle.resolvedMiddleWidth(context),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F3F7),
        borderRadius: BorderRadius.circular(ChatCardStyle.cardRadius),
        boxShadow: ChatCardStyle.cardShadow(opacity: 1),
      ),
      child: Column(
        children: [
          // 图标区（evaluate：48 白圆 badge + 30 图标；summary：48 直出）
          if (iconWithBadge)
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AppColors.cardBackground,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.chatIconBadgeShadow,
                    offset: Offset(0, 2),
                    blurRadius: 5,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: LoadImage(iconAsset, width: 22, height: 22),
            )
          else
            LoadImage(iconAsset, width: 36, height: 36),
          const SizedBox(height: 8),
          // 主标题（15 semibold #222 居中）
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Text(
              card.title ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTextStyles.titleSmall,
            ),
          ),
          const SizedBox(height: 5),
          // 副标题（12 #666 居中）
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Text(
              card.desc ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary),
            ),
          ),
          if (visible) ...[
            const SizedBox(height: 10),
            // 主按钮（170×40；未完成青绿渐变白字；已完成灰底 #F6F6F6 + #666 不可点）
            GestureDetector(
              onTap: completed ? null : onTap,
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  gradient: completed ? null : ChatCardStyle.tealButtonGradient,
                  color: completed ? AppColors.badgeBgGray : null,
                  borderRadius: BorderRadius.circular(18),
                ),
                alignment: Alignment.center,
                child: Text(
                  buttonTitle,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: completed ? AppColors.textSecondary : Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 按 card.link 的 orderId 拉取咨询完成状态，驱动「已完成」渲染（ADR-0005）。
/// 拉取前 appCompleted=null（回退 IM 消息 type，避免闪烁）；拉到后用 app 数据覆盖。
/// 无 orderId（旧消息 / 异常 link）或拉取失败：保持回退，不阻断渲染。
class _AppDoneStatusCard extends ConsumerStatefulWidget {
  const _AppDoneStatusCard({
    required this.card,
    required this.appCompletedOf,
    required this.builder,
  });

  final ImCustomCard card;

  /// 从完成状态取本卡片关心的布尔（评价卡取 reviewDone，小结卡取 summaryDone）。
  final bool Function(ConsultStatus) appCompletedOf;

  final Widget Function(bool? appCompleted) builder;

  @override
  ConsumerState<_AppDoneStatusCard> createState() => _AppDoneStatusCardState();
}

class _AppDoneStatusCardState extends ConsumerState<_AppDoneStatusCard> {
  bool? _appCompleted;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final orderIdStr = parseCardLinkParams(widget.card.link)['orderId'];
    final orderId = orderIdStr == null ? null : int.tryParse(orderIdStr);
    if (orderId == null) return; // 无 orderId → 保持回退 card.type
    final s = await ref.read(consultStatusApiProvider).fetchByOrder(orderId);
    if (!mounted) return;
    setState(() => _appCompleted = widget.appCompletedOf(s));
  }

  @override
  Widget build(BuildContext context) => widget.builder(_appCompleted);
}

/// for_evaluate_middle（咨询结束·去评价）居中系统卡片。
/// 「去评价」按钮仅用户端展示（iOS 参照：TUIForEvaluateMiddleCellData
/// isUserEndProvider）；已完成=用户已评价（app 数据，ADR-0005）；link → routeTypeCode=1008。
class ForEvaluateMiddleCard extends StatelessWidget {
  const ForEvaluateMiddleCard({
    super.key,
    required this.card,
    required this.identity,
  });

  final ImCustomCard card;

  /// 当前身份（user / consultant），决定「去评价」按钮可见性
  final String? identity;

  @override
  Widget build(BuildContext context) {
    return _AppDoneStatusCard(
      card: card,
      appCompletedOf: (s) => s.reviewDone,
      builder: (appCompleted) => _ActionMiddleCard(
        card: card,
        iconAsset: AppAssets.forEvaluateMiddleIcon,
        iconWithBadge: true,
        buttonTitle: evaluateButtonTitle(card, appCompleted: appCompleted),
        visible: showsEvaluateButton(identity),
        appCompleted: appCompleted,
        onTap: () => ChatCardStyle.openCardLink(context, card.link),
      ),
    );
  }
}

/// for_summary_middle（咨询结束·写小结）居中系统卡片。
/// 「填写小结」按钮仅咨询师端展示（iOS 参照：TUIForSummaryMiddleCellData
/// isCounselorEndProvider）；已完成=小结已发布（app 数据，ADR-0005）；link → routeTypeCode=1010。
class ForSummaryMiddleCard extends StatelessWidget {
  const ForSummaryMiddleCard({
    super.key,
    required this.card,
    required this.identity,
  });

  final ImCustomCard card;

  /// 当前身份（user / consultant），决定「填写小结」按钮可见性
  final String? identity;

  @override
  Widget build(BuildContext context) {
    return _AppDoneStatusCard(
      card: card,
      appCompletedOf: (s) => s.summaryDone,
      builder: (appCompleted) => _ActionMiddleCard(
        card: card,
        iconAsset: AppAssets.forSummaryMiddleIcon,
        iconWithBadge: false,
        buttonTitle: summaryButtonTitle(card, appCompleted: appCompleted),
        visible: showsSummaryButton(identity),
        appCompleted: appCompleted,
        onTap: () => ChatCardStyle.openCardLink(context, card.link),
      ),
    );
  }
}
