import 'package:flutter/material.dart';

import '../../../core/im/im_models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'chat_card_style.dart';

/// summary_advise（咨询小结与建议）方向性白卡（靠发送方）。
/// iOS 参照：TUIKit/TUIChat/UI_Minimalist/Cell/Custom/
/// TUISummaryAdviseCell_Minimalist.swift
/// （Figma 441:1638：标题行（图标 30）+ 青绿左条段落块（小结段 desc /
/// 建议段 label，各最多 2 行）+ 靛蓝渐变主按钮；高度随正文动态变化）。
class SummaryAdviseCard extends StatelessWidget {
  const SummaryAdviseCard({super.key, required this.card});

  final ImCustomCard card;

  @override
  Widget build(BuildContext context) {
    final peerName = ChatPeerScope.of(context)?.peerName?.trim();
    return Container(
      width: ChatCardStyle.resolvedMiddleWidth(context),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F2FA),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            peerName == null || peerName.isEmpty ? '来自咨询师' : '来自$peerName咨询师',
            style: AppTextStyles.label.copyWith(
              color: const Color(0xFF6F4FB3),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(card.title ?? '本次咨询回顾', style: AppTextStyles.titleSmall),
          if ((card.desc ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '“${card.desc!}”',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0xFFD8CFDF)),
          InkWell(
            onTap: () => ChatCardStyle.openCardLink(context, card.link),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '查看完整回顾与作业',
                      style: AppTextStyles.body.copyWith(
                        color: const Color(0xFF6F4FB3),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: Color(0xFF6F4FB3),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
