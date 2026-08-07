import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/im/im_models.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'chat_card_logic.dart';
import 'chat_card_style.dart';

/// begin_chat_middle（开始咨询）居中系统卡片。
/// iOS 参照：TUIKit/TUIChat/UI_Minimalist/Cell/Custom/
/// TUIBeginChatMiddleCell_Minimalist.swift
/// （白卡圆角 16 + 标题行（图标 28 + 16 semibold）+ 底部行
/// （咨询方式图标 14 + desc + 分割线 1×12 + 时钟图标 + date），固定高 88）。
class BeginChatMiddleCard extends StatelessWidget {
  const BeginChatMiddleCard({super.key, required this.card});

  final ImCustomCard card;

  @override
  Widget build(BuildContext context) {
    // title 含「取消」隐藏时间区（Android MsgAdapter 语义；iOS 未做该判定，
    // 按 type+desc 渲染——双端差异，保留 Android 行为，见契约 §4 注）
    final hideTimeSection = beginChatHidesTimeSection(card);
    return Container(
      width: ChatCardStyle.resolvedMiddleWidth(context),
      // iOS 固定高 88；用 minHeight 兼容不同字体度量（内容约 86-88）
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F3F7),
        borderRadius: BorderRadius.circular(ChatCardStyle.cardRadius),
        boxShadow: ChatCardStyle.beginChatShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            card.title ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.titleSmall,
          ),
          if (!hideTimeSection) ...[
            const SizedBox(height: 8),
            const Divider(height: 1, color: Color(0xFFE2E0E6)),
            const SizedBox(height: 8),
            Text(
              card.desc ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            if ((card.date ?? '').isNotEmpty &&
                (card.buttonText ?? '').isEmpty) ...[
              const SizedBox(height: 6),
              Text(
                card.date!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
            if ((card.buttonText ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () {
                    final orderId = card.orderId;
                    if (orderId == null || orderId.isEmpty) return;
                    final isIntakeAction = card.status == 'pending_intake' ||
                        card.buttonText == '填写资料';
                    if (isIntakeAction) {
                      final peer = ChatPeerScope.of(context);
                      context.push(
                        Uri(
                          path: RoutePaths.paymentIntake,
                          queryParameters: {
                            'orderId': orderId,
                            if ((peer?.peerImUserId ?? '').isNotEmpty)
                              'imUserId': peer!.peerImUserId,
                            if ((peer?.peerName ?? '').isNotEmpty)
                              'name': peer!.peerName,
                            if ((peer?.peerAvatar ?? '').isNotEmpty)
                              'avatar': peer!.peerAvatar,
                          },
                        ).toString(),
                      );
                      return;
                    }
                    context.push(
                      '${RoutePaths.orderDetail}?orderId=${Uri.encodeComponent(orderId)}',
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF006A67),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 32),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(card.buttonText!),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
