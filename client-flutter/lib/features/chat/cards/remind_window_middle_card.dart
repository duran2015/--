import 'package:flutter/material.dart';

import '../../../core/im/im_models.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../utils/load_image.dart';
import 'chat_card_logic.dart';
import 'chat_card_style.dart';

/// remind_window_middle（咨询室开放提醒）居中系统卡片。
/// iOS 参照：TUIKit/TUIChat/UI_Minimalist/Cell/Custom/
/// TUIRemindWindowMiddleCell_Minimalist.swift
/// （Figma 441:1602：左对齐标题行（图标 30）+ 描述（最多 2 行）+
/// 通栏靛蓝渐变主按钮；type=0 失效时隐藏按钮，高度随内容自适应）。
class RemindWindowMiddleCard extends StatelessWidget {
  const RemindWindowMiddleCard({super.key, required this.card});

  final ImCustomCard card;

  @override
  Widget build(BuildContext context) {
    final active = isRemindWindowActive(card);
    return Container(
      width: ChatCardStyle.resolvedMiddleWidth(context),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F3F7),
        borderRadius: BorderRadius.circular(ChatCardStyle.cardRadius),
        boxShadow: ChatCardStyle.cardShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题行（图标 30 + title 16 semibold #222 左对齐）
          Row(
            children: [
              LoadImage(
                AppAssets.remindWindowMiddleIcon,
                width: 30,
                height: 30,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  card.title ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.title,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          // 描述（13 #222 左对齐，最多 2 行；iOS descAttributedText #222）
          Text(
            card.desc ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
          ),
          if (active) ...[
            const SizedBox(height: 15),
            // 「进入咨询室」通栏渐变按钮（40 高，#4D5CFF→#A8A8FF）
            // → link routeTypeCode=1006，supportMode=1 仅 Toast
            // （拦截语义见 ChatCardStyle.openCardLink）
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () => ChatCardStyle.openCardLink(context, card.link),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF006A67),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Text(remindWindowButtonTitle(card)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
