import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../core/consult_room/consult_room_launcher.dart';
import '../../core/consult_room/consult_room_service.dart';
import '../../core/im/im_models.dart';
import '../../core/network/api_response.dart';
import '../../core/router/route_paths.dart';
import '../../core/theme/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/message_time_formatter.dart';
import '../../core/widgets/app_background.dart';
import '../../core/widgets/app_loading_hud.dart';
import '../../core/widgets/app_paged_list.dart';
import '../../core/widgets/app_refresh_indicator.dart';
import '../../core/widgets/app_states.dart';
import '../../core/widgets/app_toast.dart';
import '../../utils/image_utils.dart';
import '../../utils/load_image.dart';
import '../auth/auth_view_model.dart';
import '../message/message_view_model.dart';
import '../report/report_service.dart';
import 'counselor_api.dart';
import 'counselor_models.dart';
import 'counselor_widgets.dart';

/// 咨询师端工作台首页（路由 /counselor）。
/// iOS 参照：XYCounselorModule/XYCounselorModule/Classes/ViewController/
/// XYCounselorWorkbenchViewController.swift（Figma 571:5777）——
/// 头部（咨询师信息卡 + 数据统计卡 + 三 Tab：预约单/已咨询/消息）+
/// 各 Tab 内嵌分页列表；右上角设置入口（→ 9006 账号与安全）。
///
/// 与 iOS 的结构差异（Flutter 惯用等价物）：
/// - iOS 外层 TableView tableHeader/tableFooter 嵌三列表 → Column + IndexedStack；
/// - iOS 外层下拉刷新 index → 进入页面 / 切回预约单 Tab 时重拉 index；
/// - 下拉刷新与上拉分页复用 AppPagedListView（MJRefresh 语义）。
class CounselorWorkbenchPage extends ConsumerStatefulWidget {
  const CounselorWorkbenchPage({super.key});

  @override
  ConsumerState<CounselorWorkbenchPage> createState() =>
      _CounselorWorkbenchPageState();
}

/// 联调驱动接口（阶段 2b live 走查专用）：供 app/navigation.dart 的元素树
/// 查找器定位工作台 State 并切换 Tab。不参与业务逻辑。
abstract class CounselorWorkbenchDebugHandle {
  /// 切换工作台 Tab（等价于点击 Tab；0 预约单 / 1 已咨询 / 2 消息）
  void selectTabForDebug(int tab);
}

class _CounselorWorkbenchPageState extends ConsumerState<CounselorWorkbenchPage>
    implements CounselorWorkbenchDebugHandle {
  /// 工作台 Tab（iOS WorkbenchTab：0 预约单 / 1 已咨询 / 2 消息）
  int _tab = 0;

  /// 首页数据（/consultant/home/index）
  CounselorHomeIndex? _index;

  /// 预约单 Tab 角标数（index.pendingCount → 列表刷新后按 total 同步，
  /// iOS 参照：fetchPendingList 内同步 pendingCount = pendingTotal）
  int _pendingCount = 0;

  /// 身份切换请求中标志（防重复点击；iOS isSubmitting）
  bool _switching = false;

  final _pendingListKey =
      GlobalKey<AppPagedListViewState<CounselorPendingOrderItem>>();
  final _completedListKey =
      GlobalKey<AppPagedListViewState<CounselorCompletedOrderItem>>();

  /// 是否已拉过已咨询列表（iOS：切到已咨询 Tab 且为空时才首拉；
  /// AppPagedListView 首次可见即自拉，这里仅记录 Tab 是否激活过）
  bool _completedActivated = false;

  @override
  void initState() {
    super.initState();
    _loadHomeIndex();
  }

  /// 拉取工作台首页数据并刷新头部（iOS loadHomeIndex）
  Future<void> _loadHomeIndex() async {
    try {
      final index = await ref.read(counselorApiProvider).fetchHomeIndex();
      if (!mounted) return;
      setState(() {
        _index = index;
        _pendingCount = index.pendingCount ?? _pendingCount;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      AppToast.show(context, e.msg);
    }
  }

  /// 切换 Tab（iOS selectTab）
  void _selectTab(int tab) {
    if (_tab == tab) return;
    setState(() {
      _tab = tab;
      if (tab == 1) _completedActivated = true;
    });
  }

  /// 联调驱动（阶段 2b）：等价于点击 Tab。
  @override
  void selectTabForDebug(int tab) => _selectTab(tab);

  /// 切换为用户身份（iOS switchToUser → selectIdentity("user") → 回用户端）
  Future<void> _switchToUser() async {
    if (_switching) return;
    setState(() => _switching = true);
    try {
      final route =
          await ref.read(authViewModelProvider.notifier).selectIdentity('user');
      if (!mounted) return;
      context.go(route);
    } on ApiException catch (e) {
      if (!mounted) return;
      AppToast.show(context, e.msg);
    } finally {
      if (mounted) setState(() => _switching = false);
    }
  }

  /// 设置按钮 → 账号与安全（iOS rightItemTapped → XYRouteCode.accountSecurity，
  /// 与用户端「我的」共用同一页）
  void _openAccountSecurity() {
    context.push(RoutePaths.mineSecurity);
  }

  /// 打开预约单详情（iOS openAppointmentDetail）
  void _openOrderDetail(CounselorPendingOrderItem item) {
    final orderId = item.orderId;
    if (orderId == null) {
      AppToast.show(context, '订单信息缺失');
      return;
    }
    context.push('${RoutePaths.counselorOrderDetail}?orderId=$orderId');
  }

  /// 进入咨询室（iOS 预约单 cell「进入咨询室」：
  /// 文字咨询 → 与来访用户的 1v1 聊天页；语音/视频 → 音视频会议咨询室）。
  /// 进房前时段校验统一由 [launchConsultRoom] 完成（咨询师
  /// /consultant/order/start；对齐 iOS XYConsultRoomService.checkRoomEnter）。
  Future<void> _enterConsultRoom(CounselorPendingOrderItem item) async {
    if (item.supportMode == CounselorSupportMode.text) {
      _openUserChat(
        imUserId: item.imUserId,
        userName: item.userName,
        userAvatar: item.userAvatar,
      );
      return;
    }
    final roomId = item.roomId?.trim() ?? '';
    if (roomId.isEmpty) {
      debugPrint(
        '🟠 [ConsultRoom] 工作台拒绝进房：roomId 为空 '
        'orderId=${item.orderId} supportMode=${item.supportMode.name} '
        'userName=${item.userName} roomName=${item.roomName}',
      );
      AppToast.show(context, '咨询室信息缺失，无法进入');
      return;
    }
    final orderId = item.orderId;
    if (orderId == null) {
      debugPrint(
        '🟠 [ConsultRoom] 工作台拒绝进房：orderId 为空 '
        'roomId=$roomId supportMode=${item.supportMode.name} '
        'userName=${item.userName}',
      );
      AppToast.show(context, '订单信息缺失');
      return;
    }
    if (!mounted) return;
    await launchConsultRoom(
      ref,
      ConsultRoomParams(
        orderId: '$orderId',
        supportMode: item.supportMode.name,
        roomId: roomId,
        roomName: item.roomName,
        imUserId: item.imUserId?.trim().isNotEmpty == true
            ? item.imUserId!.trim()
            : null,
        userName: item.userName,
        userAvatar: item.userAvatar,
      ),
      context: context,
    );
  }

  /// 打开与来访用户的 1v1 文字聊天页（iOS openUserChat；
  /// imUserId 空 →「用户信息缺失」）
  void _openUserChat({
    String? imUserId,
    required String userName,
    String? userAvatar,
  }) {
    final trimmed = imUserId?.trim() ?? '';
    if (trimmed.isEmpty) {
      AppToast.show(context, '用户信息缺失');
      return;
    }
    context.push(
      Uri(path: RoutePaths.chat, queryParameters: {
        'targetUserId': trimmed,
        'userName': userName,
        if (userAvatar != null && userAvatar.isNotEmpty) 'avatar': userAvatar,
      }).toString(),
    );
  }

  /// 已咨询 cell 底部操作（iOS：已写小结 → 查看记录（聊天页）；
  /// 未写小结 → 写小结与建议（1010），返回后刷新列表）
  Future<void> _handleCompletedAction(CounselorCompletedOrderItem item) async {
    if (item.hasSummary) {
      _openUserChat(
        imUserId: item.imUserId,
        userName: item.userName,
        userAvatar: item.userAvatar,
      );
      return;
    }
    final orderId = item.orderId;
    if (orderId == null) {
      AppToast.show(context, '订单信息缺失');
      return;
    }
    final saved = await context
        .push<bool>('${RoutePaths.consultRecord}?orderId=$orderId');
    if (saved == true) {
      _completedListKey.currentState?.refresh();
      _loadHomeIndex();
    }
  }

  /// 打开消息对应的 1v1 聊天页（iOS openMessageChat）
  void _openMessageChat(ImConversation conversation) {
    _openUserChat(
      imUserId: conversation.userId,
      userName: conversation.showName,
      userAvatar: conversation.faceUrl,
    );
  }

  @override
  Widget build(BuildContext context) {
    // 拉黑用户后重拉会话（预约详情删 C2C 后工作台消息 Tab 须同步）
    ref.listen<int>(imPeerBlockedTickProvider, (_, __) {
      ref.invalidate(conversationListProvider);
    });

    // 消息 Tab 角标：IM 普通会话未读之和（不含机器人与系统通知）。
    // iOS 参照：XYCounselorWorkbenchViewModel.messageUnreadTotal →
    // updateMessageBadge（不以 /consultant/home/index.unreadMessageCount 为准）。
    final messageBadge = ref.watch(messageUnreadTotalProvider);

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: AppPageBackground(
        child: Stack(
          children: [
            Column(
              children: [
                // 头部：信息卡 + 统计卡 + Tab（iOS tableHeaderView）
                _WorkbenchHeader(
                  index: _index,
                  tab: _tab,
                  pendingBadge: _pendingCount,
                  messageBadge: messageBadge,
                  onTabTapped: _selectTab,
                  onSwitchRoleTapped: _switchToUser,
                ),
                // 三 Tab 列表（iOS footerContainerView 内嵌列表）
                Expanded(
                  child: IndexedStack(
                    index: _tab,
                    children: [
                      _buildPendingList(),
                      _buildCompletedList(),
                      _buildMessageList(),
                    ],
                  ),
                ),
              ],
            ),
            // 右上角设置按钮（iOS setupLogoutButton：top 58.5、44 热区、16 图标）
            Positioned(
              top: 58.5 - (44 - 16) / 2,
              right: AppDimens.screenPadding,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _openAccountSecurity,
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(
                    child: LoadImage(
                      AppAssets.icWorkbenchSettings,
                      width: 16,
                      height: 16,
                      errorWidget: const Icon(
                        Icons.settings_outlined,
                        size: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // 切换身份加载遮罩（iOS XYLoading.show("切换中")）
            if (_switching)
              const Positioned.fill(
                child: AppLoadingHud(message: '切换中'),
              ),
          ],
        ),
      ),
    );
  }

  /// 预约单列表（#32 分页；iOS pendingTableView）
  Widget _buildPendingList() {
    return AppPagedListView<CounselorPendingOrderItem>(
      key: _pendingListKey,
      pageSize: CounselorApi.pageSize,
      padding: const EdgeInsets.only(
        left: AppDimens.screenPadding,
        right: AppDimens.screenPadding,
        bottom: AppDimens.gap16,
      ),
      separator: const SizedBox(height: 10),
      emptyWidget: const AppEmptyView(message: '暂无预约单'),
      fetcher: (pageNum, pageSize) async {
        final result = await ref
            .read(counselorApiProvider)
            .fetchPendingList(pageNum: pageNum, pageSize: pageSize);
        // iOS：下拉刷新列表时同步预约单 Tab 角标（pendingCount = pendingTotal）
        if (mounted && pageNum == 1) {
          setState(() => _pendingCount = result.total);
        }
        return result;
      },
      itemBuilder: (context, item, index) => CounselorPendingOrderCard(
        item: item,
        onDetailTapped: () => _openOrderDetail(item),
        onMeetingTapped: () => _enterConsultRoom(item),
      ),
    );
  }

  /// 已咨询列表（#33 分页；iOS completedTableView）
  Widget _buildCompletedList() {
    // iOS：切到已咨询 Tab 且列表为空才首拉；IndexedStack 下首帧即构建，
    // 未激活过则先展示空态，激活后由 AppPagedListView 自拉
    if (!_completedActivated) {
      return const SizedBox.shrink();
    }
    return AppPagedListView<CounselorCompletedOrderItem>(
      key: _completedListKey,
      pageSize: CounselorApi.pageSize,
      padding: const EdgeInsets.only(
        left: AppDimens.screenPadding,
        right: AppDimens.screenPadding,
        bottom: AppDimens.gap16,
      ),
      separator: const SizedBox(height: 10),
      emptyWidget: const AppEmptyView(message: '暂无已咨询订单'),
      fetcher: (pageNum, pageSize) => ref
          .read(counselorApiProvider)
          .fetchCompletedList(pageNum: pageNum, pageSize: pageSize),
      itemBuilder: (context, item, index) => CounselorCompletedOrderCard(
        item: item,
        onActionTapped: () => _handleCompletedAction(item),
      ),
    );
  }

  /// 消息列表（iOS messageTableView：IM 会话，剔除机器人与系统通知账号，
  /// 复用 features/message 的 messageViewModelProvider 过滤逻辑）
  Widget _buildMessageList() {
    final conversations = ref.watch(messageViewModelProvider).conversations;
    return AppRefreshIndicator(
      onRefresh: () async {
        ref.invalidate(conversationListProvider);
        await ref.read(conversationListProvider.future);
      },
      child: conversations.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 120),
                AppEmptyView(message: '暂无消息'),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(
                left: AppDimens.screenPadding,
                right: AppDimens.screenPadding,
                bottom: AppDimens.gap16,
              ),
              itemCount: conversations.length,
              // 与用户端消息 Tab 会话间距一致（Figma 10）
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) => CounselorMessageCard(
                conversation: conversations[index],
                onTap: () => _openMessageChat(conversations[index]),
              ),
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// 头部（信息卡 + 统计卡 + Tab 栏）
// ---------------------------------------------------------------------------

/// 工作台头部。
/// iOS 参照：XYCounselorWorkbenchTableHeaderView（信息卡 XYCounselorInfoCardView
/// + 统计卡 XYCounselorStatsCardView + Tab 栏与渐变指示条）。
class _WorkbenchHeader extends StatelessWidget {
  const _WorkbenchHeader({
    required this.index,
    required this.tab,
    required this.pendingBadge,
    required this.messageBadge,
    required this.onTabTapped,
    required this.onSwitchRoleTapped,
  });

  final CounselorHomeIndex? index;
  final int tab;
  final int pendingBadge;
  final int messageBadge;
  final ValueChanged<int> onTabTapped;
  final VoidCallback onSwitchRoleTapped;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.screenPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 信息卡：距屏顶 102（iOS infoRowTopInset，含状态栏）
          Padding(
            padding: const EdgeInsets.only(top: 102),
            child: _CounselorInfoCard(
              index: index,
              onSwitchRoleTapped: onSwitchRoleTapped,
            ),
          ),
          const SizedBox(height: AppDimens.gap10),
          _CounselorStatsCard(index: index),
          const SizedBox(height: AppDimens.gap10),
          // Tab 栏（预约单 / 已咨询 / 消息，左对齐，间距 24）
          Padding(
            padding: const EdgeInsets.only(bottom: AppDimens.gap8),
            child: Row(
              children: [
                _WorkbenchTabButton(
                  title: '预约单',
                  active: tab == 0,
                  badgeCount: pendingBadge,
                  onTap: () => onTabTapped(0),
                ),
                const SizedBox(width: 24),
                _WorkbenchTabButton(
                  title: '已咨询',
                  active: tab == 1,
                  badgeCount: 0,
                  onTap: () => onTabTapped(1),
                ),
                const SizedBox(width: 24),
                _WorkbenchTabButton(
                  title: '消息',
                  active: tab == 2,
                  badgeCount: messageBadge,
                  onTap: () => onTabTapped(2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 咨询师信息卡：头像 58 + 昵称 16 w600 / 头衔 12 #666 + 右侧「切换身份」。
/// iOS 参照：XYCounselorInfoCardView。
class _CounselorInfoCard extends StatelessWidget {
  const _CounselorInfoCard({
    required this.index,
    required this.onSwitchRoleTapped,
  });

  final CounselorHomeIndex? index;
  final VoidCallback onSwitchRoleTapped;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = index?.avatar;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 头像 58 圆形（占位：iOS person.circle.fill tint #12D6C8）
        CircleAvatar(
          radius: 29,
          backgroundColor: AppColors.dividerDark,
          backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
              ? ImageUtils.getImageProvider(avatarUrl)
              : null,
          child: (avatarUrl == null || avatarUrl.isEmpty)
              ? const Icon(Icons.person,
                  size: 40, color: AppColors.avatarTintTeal)
              : null,
        ),
        const SizedBox(width: AppDimens.gap12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  index?.name ?? '',
                  style: AppTextStyles.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppDimens.gap6),
                Text(
                  index?.title ?? '',
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
        // 切换身份按钮：24 高、圆角 12、#F7F8FC 底、白色 2px 描边
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onSwitchRoleTapped,
          child: Container(
            height: 24,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: AppColors.innerBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                LoadImage(
                  AppAssets.mineSwitch,
                  width: 13,
                  height: 13,
                  fit: BoxFit.contain,
                ),
                4.horizontalSpace,
                Text(
                  '切换身份',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// 数据统计卡：用户评价 / 待服务 / 接单率（渐变 #F9F7FE → #FDFDFE 竖向）。
/// iOS 参照：XYCounselorStatsCardView。
class _CounselorStatsCard extends StatelessWidget {
  const _CounselorStatsCard({required this.index});

  final CounselorHomeIndex? index;

  @override
  Widget build(BuildContext context) {
    final satisfactionText = index?.satisfactionText ?? '暂无';
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.statsGradientTop, AppColors.statsGradientBottom],
        ),
        borderRadius: BorderRadius.circular(AppDimens.cardRadius),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            _StatItem(
              title: '用户评价',
              value: satisfactionText,
              valueColor: satisfactionText == '暂无'
                  ? AppColors.textTertiary
                  : AppColors.textPrimary,
            ),
            const _StatDivider(),
            _StatItem(
              title: '待服务',
              value: index?.pendingText ?? '0',
              valueColor: AppColors.priceRed,
            ),
            const _StatDivider(),
            _StatItem(
              title: '接单率',
              value: (index?.acceptRateText ?? '0%').replaceAll('%', ''),
              valueColor: AppColors.textPrimary,
              suffix: '%',
            ),
          ],
        ),
      ),
    );
  }
}

/// 单个统计项（标题 12 #666 + 数值 20 bold）。
/// iOS 参照：XYCounselorStatsCardView.makeStatItem / makeRateItem。
class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.title,
    required this.value,
    required this.valueColor,
    this.suffix,
  });

  final String title;
  final String value;
  final Color valueColor;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppDimens.gap16),
        child: Column(
          children: [
            Text(
              title,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppDimens.gap6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: valueColor,
                  ),
                ),
                if (suffix != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      suffix!,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textPrimary,
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
}

/// 统计栏间分隔线（1 × 40 #EBECF6）
class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 40,
      color: AppColors.lightPurpleDivider,
    );
  }
}

/// 单个 Tab 按钮：文案（激活 16 w600 #222 / 未激活 14 #999）+
/// 渐变指示条（28 × 3，#4A56D9 → #717DFF）+ 角标（>99 显示 99+）。
/// iOS 参照：XYCounselorWorkbenchTableHeaderView.makeTabButton / selectTab /
/// updateBadge。
class _WorkbenchTabButton extends StatelessWidget {
  const _WorkbenchTabButton({
    required this.title,
    required this.active,
    required this.badgeCount,
    required this.onTap,
  });

  final String title;
  final bool active;
  final int badgeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: active ? 16 : 14,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                  color:
                      active ? AppColors.textPrimary : AppColors.textTertiary,
                ),
              ),
              // 角标（iOS：红底 #FF2E00 高 14，10 w600 白字，挂标题右上）
              if (badgeCount > 0)
                Positioned(
                  left: null,
                  right: -10,
                  top: -8,
                  child: Container(
                    height: 14,
                    constraints: const BoxConstraints(minWidth: 14),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: AppColors.counselorBadgeRed,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      badgeCount > 99 ? '99+' : '$badgeCount',
                      style: AppTextStyles.badge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Container(
            width: 28,
            height: 3,
            decoration: BoxDecoration(
              gradient: active ? AppColors.indigoButtonGradient : null,
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 列表 Cell
// ---------------------------------------------------------------------------

/// 预约单列表项卡片。
/// iOS 参照：XYCounselorPendingOrderCell（Figma 571:5777）——
/// 头部行 + 用户标签 + 问题摘要 + 底部双按钮（查看详情 240 / 进入咨询室 368，
/// 靛蓝渐变 #4A56D9 → #717DFF）。
class CounselorPendingOrderCard extends StatelessWidget {
  const CounselorPendingOrderCard({
    super.key,
    required this.item,
    this.onDetailTapped,
    this.onMeetingTapped,
  });

  final CounselorPendingOrderItem item;
  final VoidCallback? onDetailTapped;
  final VoidCallback? onMeetingTapped;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimens.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CounselorOrderCardHeader(
            timeText: item.timeText,
            dayText: item.dayText,
            userName: item.userName,
            userAvatar: item.userAvatar,
            mode: item.supportMode,
          ),
          if (item.tags.isNotEmpty) ...[
            const SizedBox(height: AppDimens.gap12),
            CounselorTagFlow(tags: item.tags),
          ],
          if (item.emotionSummary.isNotEmpty) ...[
            const SizedBox(height: AppDimens.gap12),
            // AI 情绪摘要（iOS：#F7F8FC 底圆角 10 + ic_generate_summary 16）
            Container(
              padding: const EdgeInsets.fromLTRB(10, 13, 10, 13),
              decoration: BoxDecoration(
                color: AppColors.innerBackground,
                borderRadius: BorderRadius.circular(AppDimens.radiusInner),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: LoadImage(
                      AppAssets.icGenerateSummary,
                      width: 16,
                      height: 16,
                      errorWidget: const Icon(
                        Icons.auto_awesome,
                        size: 16,
                        color: AppColors.brandTeal,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimens.gap6),
                  Expanded(
                    child: Text(
                      item.emotionSummary,
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        height: 18 / 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppDimens.gap12),
          // 底部双按钮（iOS：查看详情 240 + 间距 11 + 进入咨询室 368）
          Row(
            children: [
              Expanded(
                flex: 240,
                child: GestureDetector(
                  onTap: onDetailTapped,
                  child: Container(
                    height: AppDimens.buttonHeightSmall,
                    decoration: BoxDecoration(
                      color: AppColors.innerBackground,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '查看详情',
                      style: AppTextStyles.bodyLargeStrong.copyWith(
                        color: AppColors.indigo,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                flex: 368,
                child: GestureDetector(
                  onTap: onMeetingTapped,
                  child: Container(
                    height: AppDimens.buttonHeightSmall,
                    decoration: BoxDecoration(
                      gradient: AppColors.indigoButtonGradient,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '进入咨询室',
                      style: AppTextStyles.bodyLargeStrong.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 已咨询列表项卡片。
/// iOS 参照：XYCounselorCompletedOrderCell（Figma 571:5500）——
/// 头部行 + 用户标签 + 完成状态条（咨询已完成 + 查看记录/写小结与建议）。
class CounselorCompletedOrderCard extends StatelessWidget {
  const CounselorCompletedOrderCard({
    super.key,
    required this.item,
    this.onActionTapped,
  });

  final CounselorCompletedOrderItem item;
  final VoidCallback? onActionTapped;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimens.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CounselorOrderCardHeader(
            timeText: item.timeText,
            dayText: item.dayText,
            userName: item.userName,
            userAvatar: item.userAvatar,
            mode: item.supportMode,
          ),
          if (item.tags.isNotEmpty) ...[
            const SizedBox(height: AppDimens.gap12),
            CounselorTagFlow(tags: item.tags),
          ],
          const SizedBox(height: AppDimens.gap10),
          // 完成状态条（iOS：#F7F8FC 底圆角 10、高 36）
          Container(
            height: AppDimens.buttonHeightSmall,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: AppColors.innerBackground,
              borderRadius: BorderRadius.circular(AppDimens.radiusInner),
            ),
            child: Row(
              children: [
                LoadImage(
                  AppAssets.icGenerateSummary,
                  width: 16,
                  height: 16,
                  errorWidget: const Icon(
                    Icons.check_circle_outline,
                    size: 16,
                    color: AppColors.brandTeal,
                  ),
                ),
                const SizedBox(width: AppDimens.gap6),
                Text(
                  '咨询已完成',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                // 操作区（已写小结 → 查看记录；未写 → 写小结与建议）
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onActionTapped,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.hasSummary ? '查看记录' : '写小结与建议',
                          style: AppTextStyles.caption.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.indigo,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const CounselorChevronRight(size: 12),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 消息列表项卡片。
/// iOS 参照：XYCounselorMessageCell（Figma 571:5368）——
/// 头像 40（右上角未读角标 #FF2E00）+ 昵称 15 w600 + 时间 11 #999 +
/// 预览 12（未读 #222 / 已读 #666）。
class CounselorMessageCard extends StatelessWidget {
  const CounselorMessageCard({
    super.key,
    required this.conversation,
    this.onTap,
  });

  final ImConversation conversation;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final unread = conversation.unreadCount > 0;
    final avatarUrl = conversation.faceUrl;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.cardPadding,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppDimens.cardRadius),
        ),
        child: Row(
          children: [
            // 头像 + 未读角标（骑跨右上角）
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.dividerDark,
                  backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                      ? ImageUtils.getImageProvider(avatarUrl)
                      : null,
                  child: (avatarUrl == null || avatarUrl.isEmpty)
                      ? const Icon(Icons.person, size: 24, color: Colors.white)
                      : null,
                ),
                if (unread)
                  Positioned(
                    right: -3,
                    top: -3,
                    child: Container(
                      height: 14,
                      constraints: const BoxConstraints(minWidth: 14),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: AppColors.counselorBadgeRed,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        conversation.unreadCount > 99
                            ? '99+'
                            : '${conversation.unreadCount}',
                        style: AppTextStyles.badge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
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
                          style: AppTextStyles.titleSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        MessageTimeFormatter.text(conversation.timestamp),
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimens.gap8),
                  Text(
                    conversation.lastMessagePreview,
                    style: AppTextStyles.caption.copyWith(
                      color: unread
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
