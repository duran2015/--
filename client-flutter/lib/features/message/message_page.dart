import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/im/im_models.dart';
import '../../core/router/route_paths.dart';
import '../../core/theme/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/message_time_formatter.dart';
import '../../core/widgets/app_background.dart';
import '../../core/widgets/app_nav_bar.dart';
import '../../core/widgets/person_avatar.dart';
import '../../utils/load_image.dart';
import 'message_view_model.dart';

/// 用户端消息 Tab 根页面。
/// iOS 参照：XYMessageViewController.swift（1:1 布局还原）。
///
/// 结构：透明导航「消息」+ 共享背景 → 顶部「系统通知」卡 →「对话」分区标题
/// → 普通会话列表（白底圆角卡 + 分隔线）→ 空态「暂无对话」。
class MessagePage extends ConsumerWidget {
  const MessagePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(messageViewModelProvider);
    return Scaffold(
      // 共享背景 + 透明导航（与预约订单/系统通知等页一致）
      body: AppPageBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppNavBar(
                title: '消息',
                showBack: false,
                transparent: true,
              ),
              const SizedBox(height: AppDimens.gap12),
              // 系统通知入口卡
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.messageHorizontalInset,
                ),
                child: SystemNotificationCard(
                  unreadCount: state.systemNotification?.unreadCount ?? 0,
                  onTap: () => context.push(RoutePaths.systemNotification),
                ),
              ),
              const SizedBox(height: AppDimens.gap12),
              // 「对话」分区标题（13pt #999999）
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.messageHorizontalInset,
                ),
                child: Text(
                  '对话',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
              const SizedBox(height: AppDimens.gap8),
              Expanded(
                child: state.conversations.isEmpty
                    ? const _EmptyConversations()
                    : _ConversationList(conversations: state.conversations),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 系统通知入口卡片。
/// iOS 参照：XYSystemNotificationCardView（白底圆角 12、铃铛 40、标题 15 w600、
/// 副标题 12 #666、右箭头 A5ABBD）+ 红点（Android fragment_message v_red_dot）。
///
/// 副标题按 iOS 基准为固定文案「查看预约提醒与系统广播」，
/// 不展示最新一条通知预览（iOS 截图 ios/02_message_tab.png）。
class SystemNotificationCard extends StatelessWidget {
  const SystemNotificationCard({
    super.key,
    required this.unreadCount,
    required this.onTap,
  });

  /// 系统通知未读数（>0 显示数字角标）
  final int unreadCount;

  final VoidCallback onTap;

  /// 固定副标题（iOS 基准文案）
  static const String subtitle = '预约、优惠、活动与账户通知';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppDimens.cardRadius),
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.gap15),
        child: Row(
          children: [
            // 铃铛图标 40 + 未读红点（右上角）
            Stack(
              clipBehavior: Clip.none,
              children: [
                LoadImage(
                  AppAssets.icSysNoti,
                  width: AppDimens.messageSysIconSize,
                  height: AppDimens.messageSysIconSize,
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: UnreadBadge(count: unreadCount),
                  ),
              ],
            ),
            const SizedBox(width: AppDimens.gap12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(
                  top: AppDimens.gap16,
                  bottom: 13,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('系统通知', style: AppTextStyles.titleSmall),
                    const SizedBox(height: AppDimens.gap4),
                    Text(
                      // 固定副标题（iOS 卡片固定文案，不随最新通知变化）
                      subtitle,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppDimens.gap8),
            const Icon(
              Icons.chevron_right,
              size: 18,
              color: AppColors.messageChevron,
            ),
          ],
        ),
      ),
    );
  }
}

/// 空态（iOS 参照：XYMessageViewController emptyLabel「暂无对话」居中于列表区）。
class _EmptyConversations extends StatelessWidget {
  const _EmptyConversations();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '暂无对话',
        style: AppTextStyles.bodyLarge.copyWith(
          color: AppColors.textTertiary,
        ),
      ),
    );
  }
}

/// 普通会话列表：每条独立白底圆角胶囊，条目间距 10。
/// Figma 1473:1613（对话区不再包整块大白底）。
class _ConversationList extends StatelessWidget {
  const _ConversationList({required this.conversations});

  final List<ImConversation> conversations;

  /// 胶囊间距（Figma 两卡间距 20px @2x → 10）
  static const double _cellGap = 10;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.messageHorizontalInset,
      ),
      itemCount: conversations.length,
      separatorBuilder: (_, __) => const SizedBox(height: _cellGap),
      itemBuilder: (context, index) {
        final item = conversations[index];
        return ConversationTile(
          conversation: item,
          onTap: () {
            // 1005 聊天页（阶段 5B 已实现）：targetUserId + 昵称/头像透传
            context.push(
              '${RoutePaths.chat}?targetUserId=${Uri.encodeComponent(item.userId)}'
              '&userName=${Uri.encodeComponent(item.showName)}'
              '&avatar=${Uri.encodeComponent(item.faceUrl ?? '')}'
              '&consultantId=${item.consultantId ?? ''}'
              '&orderId=${Uri.encodeComponent(item.orderId ?? '')}'
              '&consultantIntro=${Uri.encodeComponent(item.consultantIntro ?? '')}'
              '&bookedSku=${Uri.encodeComponent(item.bookedSku ?? '')}',
            );
          },
        );
      },
    );
  }
}

/// 会话列表项（独立白底圆角胶囊）。
/// Figma 1473:1696 / 1473:1717；头像与预览图标沿用现有资源，不新切图。
class ConversationTile extends StatelessWidget {
  const ConversationTile({
    super.key,
    required this.conversation,
    required this.onTap,
  });

  final ImConversation conversation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppDimens.cardRadius),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.gap15,
          vertical: AppDimens.gap14,
        ),
        child: Row(
          children: [
            // 头像 + 未读角标（骑跨右上角，iOS XYUnreadBadgeView：
            // 红底白字、1.5pt 白描边、>99 显示 99+）
            Stack(
              clipBehavior: Clip.none,
              children: [
                _ConversationAvatar(conversation: conversation),
                if (conversation.unreadCount > 0)
                  Positioned(
                    right: -3,
                    top: -8,
                    child: UnreadBadge(count: conversation.unreadCount),
                  ),
              ],
            ),
            const SizedBox(width: AppDimens.gap12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.showName,
                          style: AppTextStyles.titleSmall.copyWith(
                            color: AppColors.messageNameText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppDimens.gap8),
                      Text(
                        MessageTimeFormatter.text(conversation.timestamp),
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimens.gap8),
                  Row(
                    children: [
                      ColorFiltered(
                        colorFilter: const ColorFilter.mode(
                          AppColors.messagePreviewIcon,
                          BlendMode.srcIn,
                        ),
                        child: LoadImage(
                          AppAssets.icMessageConversation,
                          width: AppDimens.messagePreviewIconSize,
                          height: AppDimens.messagePreviewIconSize,
                        ),
                      ),
                      const SizedBox(width: AppDimens.gap4),
                      Expanded(
                        child: Text(
                          conversation.lastMessagePreview,
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textTertiary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 咨询师头像：优先使用真实头像，网络加载失败时展示稳定的姓名首字头像。
/// 避免 Mock/弱网场景退化成整排相同的灰色默认头像。
class _ConversationAvatar extends StatelessWidget {
  const _ConversationAvatar({required this.conversation});

  final ImConversation conversation;

  @override
  Widget build(BuildContext context) {
    return PersonAvatar(
      name: conversation.showName,
      seed: conversation.userId,
      size: AppDimens.messageAvatarSize,
      imageUrl: conversation.faceUrl,
      showOnline: conversation.userId.startsWith('xy_mock_counselor_'),
    );
  }
}

/// 未读数角标（红底白字，>99 显示 99+）。
/// iOS 参照：XYUnreadBadgeView（高 18、最小宽 18、白描边 1.5、字号 11 w600）。
class UnreadBadge extends StatelessWidget {
  const UnreadBadge({super.key, required this.count});

  final int count;

  static const int _badgeMax = 99;

  @override
  Widget build(BuildContext context) {
    final text = count > _badgeMax ? '99+' : '$count';
    return Container(
      height: AppDimens.messageUnreadBadgeHeight,
      constraints: const BoxConstraints(
        minWidth: AppDimens.messageUnreadBadgeHeight,
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.gap6),
      decoration: BoxDecoration(
        color: AppColors.badgeRed,
        borderRadius:
            BorderRadius.circular(AppDimens.messageUnreadBadgeHeight / 2),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: AppTextStyles.badgeSmall.copyWith(fontSize: 11),
        textAlign: TextAlign.center,
      ),
    );
  }
}
