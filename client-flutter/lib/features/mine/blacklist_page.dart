import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_response.dart';
import '../../core/theme/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_background.dart';
import '../../core/widgets/app_nav_bar.dart';
import '../../core/widgets/app_paged_list.dart';
import '../../core/widgets/app_states.dart';
import '../../core/widgets/app_toast.dart';
import '../../utils/image_utils.dart';
import '../../utils/load_image.dart';
import '../message/message_view_model.dart';
import '../report/report_api.dart';
import '../report/report_models.dart';
import '../report/report_service.dart';

/// 黑名单管理页（仅 debug 入口，账号与安全 / 账号设置与反馈进入）。
/// 数据源：后端拉黑留档记录 POST /app/block/list（分页）。
/// 「解除黑名单」走 IM-first：先 IM removeFromBlackList（门控），失败则提示且
/// 不调后端、不刷新；成功后才静默调 POST /app/block/cancel 并刷新列表。
class BlacklistPage extends ConsumerStatefulWidget {
  const BlacklistPage({super.key});

  static const double _avatarSize = 40;
  static const double _rowMinHeight = 64;

  @override
  ConsumerState<BlacklistPage> createState() => _BlacklistPageState();
}

class _BlacklistPageState extends ConsumerState<BlacklistPage> {
  final _listKey = GlobalKey<AppPagedListViewState<BlockedUserItem>>();
  final Set<String> _removing = {}; // 进行中的 imUserId

  Future<void> _unblock(BlockedUserItem item) async {
    final imUserId = item.imUserId;
    final targetId = item.blockedUserId;
    if (imUserId == null || imUserId.isEmpty || targetId == null) {
      AppToast.show(context, '用户信息缺失，无法解除');
      return;
    }
    if (_removing.contains(imUserId)) return;
    setState(() => _removing.add(imUserId));
    try {
      await ref.read(reportServiceProvider).unblockUser(
            imUserId: imUserId,
            blockedUserId: targetId,
          );
      if (!mounted) return;
      setState(() => _removing.remove(imUserId));
      // IM 解除后，会话列表的黑名单过滤需重拉
      ref.read(imPeerBlockedTickProvider.notifier).state++;
      ref.invalidate(conversationListProvider);
      _listKey.currentState?.refresh();
      AppToast.show(context, '已解除黑名单');
    } catch (e) {
      // IM 解除失败：提示，不调后端、不刷新列表
      if (!mounted) return;
      setState(() => _removing.remove(imUserId));
      final msg = e is ApiException && e.msg.isNotEmpty ? e.msg : '解除失败';
      AppToast.show(context, msg);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppPageBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const AppNavBar(
                title: '黑名单管理',
                transparent: true,
                lineHidden: true,
              ),
              Expanded(
                child: AppPagedListView<BlockedUserItem>(
                  key: _listKey,
                  pageSize: 10,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.screenPadding,
                    vertical: AppDimens.gap16,
                  ),
                  separator: const SizedBox(height: AppDimens.gap10),
                  emptyWidget: const AppEmptyView(message: '暂无黑名单用户'),
                  fetcher: (pageNum, pageSize) => ref
                      .read(reportApiProvider)
                      .fetchBlockList(pageNum: pageNum, pageSize: pageSize),
                  itemBuilder: (context, item, index) {
                    final busy = item.imUserId != null &&
                        _removing.contains(item.imUserId);
                    return _BlacklistCell(
                      item: item,
                      busy: busy,
                      onUnblock: () => _unblock(item),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BlacklistCell extends StatelessWidget {
  const _BlacklistCell({
    required this.item,
    required this.busy,
    required this.onUnblock,
  });

  final BlockedUserItem item;
  final bool busy;
  final VoidCallback onUnblock;

  @override
  Widget build(BuildContext context) {
    final face = item.avatar?.trim();
    // 副标题：身份标签 · 手机号 · 时间（缺省项自动跳过）
    final subParts = <String>[
      if (item.userTypeLabel.isNotEmpty) item.userTypeLabel,
      if ((item.phonenumber ?? '').isNotEmpty) item.phonenumber!,
      if ((item.createTime ?? '').isNotEmpty) item.createTime!,
    ];
    final subtitle = subParts.join(' · ');
    return Container(
      constraints: const BoxConstraints(
        minHeight: BlacklistPage._rowMinHeight,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.gap16,
        vertical: AppDimens.gap12,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimens.cardRadius),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: BlacklistPage._avatarSize / 2,
            backgroundColor: AppColors.messageAvatarBg,
            backgroundImage:
                (face != null && face.isNotEmpty) ? ImageUtils.getImageProvider(face) : null,
            child: (face == null || face.isEmpty)
                ? const LoadImage(
                    AppAssets.icDefaultAvatar,
                    width: BlacklistPage._avatarSize,
                    height: BlacklistPage._avatarSize,
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          const SizedBox(width: AppDimens.gap12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: AppDimens.gap4),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppDimens.gap8),
          TextButton(
            onPressed: busy ? null : onUnblock,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.brandTeal,
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.gap8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.brandTeal,
                    ),
                  )
                : Text(
                    '解除黑名单',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.brandTeal,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
