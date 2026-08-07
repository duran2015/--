import 'package:flutter/material.dart';

import '../../../core/im/im_models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'action_middle_card.dart';
import 'begin_chat_middle_card.dart';
import 'chat_card_logic.dart';
import 'question_assistant_card.dart';
import 'remind_window_middle_card.dart';
import 'summary_advise_card.dart';

/// 自定义卡片统一分发（复用 ImCustomCard 白名单解析）。
///
/// 契约 §4：6 种 businessID 各对应一个卡片 widget；
/// 居中卡（*_middle）无头像、不属于任一方；
/// 方向性卡（summary_advise / question_assistant）靠发送方展示。
///
/// Android 参照：MsgAdapter.getItemViewType 按 businessID 分发。
class CustomCardView extends StatelessWidget {
  const CustomCardView({
    super.key,
    required this.card,
    required this.identity,
    required this.isSelf,
  });

  final ImCustomCard card;

  /// 当前身份（user / consultant），决定行动卡按钮可见性
  final String? identity;

  /// 是否本人发送（方向性卡贴右/贴左由外层消息行控制）
  final bool isSelf;

  /// 是否为居中系统卡（外层据此决定行布局：居中无头像 / 方向性带头像）
  static bool isCentered(ImCustomCard card) =>
      isMiddleCard(resolveChatCardKind(card.businessID)) ||
      resolveChatCardKind(card.businessID) == ChatCardKind.summaryAdvise;

  @override
  Widget build(BuildContext context) {
    switch (resolveChatCardKind(card.businessID)) {
      case ChatCardKind.beginChatMiddle:
        return BeginChatMiddleCard(card: card);
      case ChatCardKind.remindWindowMiddle:
        return RemindWindowMiddleCard(card: card);
      case ChatCardKind.forEvaluateMiddle:
        if (!showsEvaluateButton(identity)) return const SizedBox.shrink();
        return ForEvaluateMiddleCard(card: card, identity: identity);
      case ChatCardKind.forSummaryMiddle:
        if (!showsSummaryButton(identity)) return const SizedBox.shrink();
        return ForSummaryMiddleCard(card: card, identity: identity);
      case ChatCardKind.summaryAdvise:
        return SummaryAdviseCard(card: card);
      case ChatCardKind.questionAssistant:
        return QuestionAssistantCard(card: card);
      case ChatCardKind.unknown:
        // 内置 businessID（text_link/order 等）与未识别卡兜底：
        // 居中窄条展示 title/desc（iOS 参照：TUILinkCell/系统消息兜底语义）
        final text = card.title ?? card.desc ?? card.label ?? '[自定义消息]';
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.cardBackground.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption,
          ),
        );
    }
  }
}
