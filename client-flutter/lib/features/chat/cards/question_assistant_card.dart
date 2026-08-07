import 'package:flutter/material.dart';

import '../../../core/im/im_models.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../utils/load_image.dart';
import 'chat_card_logic.dart';
import 'chat_card_style.dart';

/// question_assistant（咨询小助手·工具推荐）方向性白卡（靠发送方）。
/// iOS 参照：TUIKit/TUIChat/UI_Minimalist/Cell/Custom/
/// TUIQuestionAssistantCell_Minimalist.swift
/// （Figma 441:1763：#EBFEFF→#FDFDFE 渐变卡 + 工具图标 48（按 type）+
/// 标题/描述居中 + 128×40 青绿渐变主按钮；⚠ Android MsgAdapter 按居中
/// 渲染，与 iOS 方向性渲染存在双端差异，以 iOS 为准，见契约 §7.3）。
class QuestionAssistantCard extends StatelessWidget {
  const QuestionAssistantCard({super.key, required this.card});

  final ImCustomCard card;

  @override
  Widget build(BuildContext context) {
    final tool = resolveAssistantToolType(card);
    return Container(
      width: ChatCardStyle.resolvedDirectionWidth(context),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: AppColors.chatCardGradient,
        borderRadius: BorderRadius.circular(ChatCardStyle.cardRadius),
        boxShadow: ChatCardStyle.cardShadow(opacity: 1),
      ),
      child: Column(
        children: [
          // 工具图标（48，按 type 切换；iOS 参照：toolIcon(for: toolType)）
          LoadImage(
            AppAssets.questionAssistantToolIcon(tool.rawValue),
            width: 48,
            height: 48,
          ),
          const SizedBox(height: 15),
          // 主标题（15 semibold #222 居中，可多行）
          Text(
            assistantCardTitle(card),
            textAlign: TextAlign.center,
            style: AppTextStyles.titleSmall,
          ),
          const SizedBox(height: 10),
          // 描述（12 #666 居中，行距 4）
          Text(
            card.desc ?? '',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 15),
          // 主按钮（128×40 青绿渐变）→ link https → /webview
          GestureDetector(
            onTap: () => ChatCardStyle.openCardLink(context, card.link),
            child: Container(
              width: 128,
              height: 40,
              decoration: BoxDecoration(
                gradient: ChatCardStyle.tealButtonGradient,
                borderRadius: BorderRadius.circular(ChatCardStyle.buttonRadius),
              ),
              alignment: Alignment.center,
              child: Text(
                assistantButtonTitle(card),
                style: AppTextStyles.body.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
