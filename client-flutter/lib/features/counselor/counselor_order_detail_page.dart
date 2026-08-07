import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_response.dart';
import '../../core/router/route_paths.dart';
import '../../core/theme/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_background.dart';
import '../../core/widgets/app_dialog.dart';
import '../../core/widgets/app_loading_hud.dart';
import '../../core/widgets/app_nav_bar.dart';
import '../../core/widgets/app_toast.dart';
import '../../utils/image_utils.dart';
import '../../utils/load_image.dart';
import '../message/message_view_model.dart';
import '../report/more_action_sheet.dart';
import '../report/report_models.dart';
import '../report/report_reason_sheet.dart';
import '../report/report_service.dart';
import 'counselor_api.dart';
import 'counselor_models.dart';
import 'counselor_widgets.dart';

/// 咨询师端预约详情页（路由 /counselor/order-detail?orderId=）。
/// iOS 参照：XYCounselorModule/XYCounselorModule/Classes/ViewController/
/// XYCounselorAppointmentDetailViewController.swift（Figma 571:4833）——
/// 顶部时段渐变头图（时段 28 semibold + 日期 + 咨询方式描边徽标）+
/// 来访用户卡片（点击 → 数字心理画像 9005）+ 用户主诉标签 + AI 情绪初判摘要 +
/// 过往接待记录（查看全部展开分页）+ 底部「返回列表 / 联系用户」。
///
/// ⚠ 底部操作说明：iOS 详情页底部为「返回列表 / 联系用户」（见
/// setupBottomBar）；「开始咨询」入口在工作台预约单 cell「进入咨询室」
/// （→ /consultant/order/start → 咨询室），「写小结」入口在已咨询 cell
/// 「写小结与建议」（→ 1010），与本页一致不重复放置。
class CounselorOrderDetailPage extends ConsumerStatefulWidget {
  const CounselorOrderDetailPage({super.key, required this.orderId});

  /// 订单 ID（路由 query orderId 解析；null 表示缺失）
  final int? orderId;

  @override
  ConsumerState<CounselorOrderDetailPage> createState() =>
      _CounselorOrderDetailPageState();
}

class _CounselorOrderDetailPageState
    extends ConsumerState<CounselorOrderDetailPage> {
  /// 当前展示数据（先用 Figma 静态示例，详情接口成功后回填；
  /// iOS 参照：init(preview:) → staticSample → applyOrderDetail）
  late CounselorOrderDetailItem _item =
      CounselorOrderDetailItem.staticSample(orderId: widget.orderId);

  final ScrollController _scrollController = ScrollController();

  /// 过往记录是否已展开（iOS isHistoryExpanded）
  bool _historyExpanded = false;

  /// 展开态分页状态（iOS historyPageNum/historyHasMore/historyIsLoading）
  int _historyPageNum = 1;
  bool _historyHasMore = true;
  bool _historyLoading = false;
  List<CounselorHistoryItem> _expandedRecords = const [];

  /// 过往记录分页大小（iOS loadHistoryPage pageSize 10）
  static const int _historyPageSize = 10;

  /// 滚动距底多少像素内加载过往记录下一页（iOS threshold 100）
  static const double _historyLoadThreshold = 100;

  /// 举报提交 / 拉黑中
  bool _actionBusy = false;
  String _actionBusyMessage = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetchOrderDetail();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 拉取订单详情（#34）：成功后回填 UI，失败 toast。
  /// iOS 参照：fetchOrderDetail。
  Future<void> _fetchOrderDetail() async {
    final orderId = widget.orderId;
    if (orderId == null) return;
    try {
      final detail =
          await ref.read(counselorApiProvider).fetchOrderDetail(orderId);
      if (!mounted) return;
      setState(() {
        _item = CounselorOrderDetailItem.fromDetail(
          detail,
          fallbackOrderId: orderId,
        );
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      AppToast.show(context, e.msg);
    }
  }

  /// 滚动接近底部时加载过往记录下一页（仅展开态、且有更多、且未在请求中）。
  /// iOS 参照：scrollViewDidScroll。
  void _onScroll() {
    if (!_historyExpanded || !_historyHasMore || _historyLoading) return;
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >=
        position.maxScrollExtent - _historyLoadThreshold) {
      _historyPageNum += 1;
      _loadHistoryPage(reset: false);
    }
  }

  /// 点击查看全部 / 收起全部（iOS historyAllTapped）
  void _toggleHistory() {
    if (_historyExpanded) {
      // 收起：恢复默认前 2 条（iOS collapseHistory）
      setState(() {
        _historyExpanded = false;
        _historyLoading = false;
      });
    } else {
      // 展开：拉取第一页分页数据（iOS expandHistory）
      final orderId = _item.orderId;
      if (orderId == null) {
        AppToast.show(context, '订单信息缺失');
        return;
      }
      setState(() {
        _historyExpanded = true;
        _historyPageNum = 1;
        _historyHasMore = true;
      });
      _loadHistoryPage(reset: true);
    }
  }

  /// 拉取一页过往记录（#35 /consultant/home/pastConsultations）。
  /// iOS 参照：loadHistoryPage。
  /// ⚠ iOS API.md 未列此接口，已按 Android 契约实现，待后端确认。
  Future<void> _loadHistoryPage({required bool reset}) async {
    if (_historyLoading) return;
    final orderId = _item.orderId;
    if (orderId == null) return;
    setState(() => _historyLoading = true);
    try {
      final result =
          await ref.read(counselorApiProvider).fetchPastConsultations(
                orderId: orderId,
                pageNum: _historyPageNum,
                pageSize: _historyPageSize,
              );
      if (!mounted) return;
      setState(() {
        _historyLoading = false;
        _expandedRecords =
            reset ? result.rows : [..._expandedRecords, ...result.rows];
        _historyHasMore = _expandedRecords.length < result.total;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _historyLoading = false;
        if (reset) _historyExpanded = false; // 首页失败回退收起态
      });
      AppToast.show(context, e.msg);
    }
  }

  /// 联系用户（iOS contactUserTapped → 1v1 聊天页；imUserId 空提示）
  void _contactUser() {
    final imUserId = _item.imUserId?.trim() ?? '';
    if (imUserId.isEmpty) {
      AppToast.show(context, '暂无法联系该用户');
      return;
    }
    context.push(
      Uri(path: RoutePaths.chat, queryParameters: {
        'targetUserId': imUserId,
        'userName': _item.userName,
        if (_item.userAvatar != null && _item.userAvatar!.isNotEmpty)
          'avatar': _item.userAvatar!,
      }).toString(),
    );
  }

  /// 导航栏「更多」：举报 / 拉黑。
  /// iOS 参照：moreTapped → XYCounselorMoreSheetViewController。
  Future<void> _moreTapped() async {
    final action = await MoreActionSheet.show(context);
    if (!mounted || action == null) return;
    switch (action) {
      case MoreSheetAction.report:
        await _openReportReasonSheet();
      case MoreSheetAction.block:
        await _confirmBlockUser();
    }
  }

  Future<void> _openReportReasonSheet() async {
    final reason = await ReportReasonSheet.show(context);
    if (!mounted || reason == null) return;
    await _submitReport(reason: reason);
  }

  /// 提交举报（targetType=user）。iOS 参照：submitReport。
  Future<void> _submitReport({required ReportReason reason}) async {
    final userId = _item.userId;
    if (userId == null) {
      AppToast.show(context, '举报失败：缺少用户信息');
      return;
    }
    setState(() {
      _actionBusy = true;
      _actionBusyMessage = '提交中';
    });
    try {
      await ref.read(reportServiceProvider).submitReport(
            targetType: ReportTargetType.user,
            targetId: '$userId',
            reason: reason,
          );
      if (!mounted) return;
      setState(() => _actionBusy = false);
      AppToast.show(context, '举报已收到，我们将在 24 小时内处理');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _actionBusy = false);
      AppToast.show(context, e.msg.isEmpty ? '举报失败' : e.msg);
    } catch (_) {
      if (!mounted) return;
      setState(() => _actionBusy = false);
      AppToast.show(context, '举报失败');
    }
  }

  /// 拉黑前二次确认。iOS 参照：confirmBlockUser。
  Future<void> _confirmBlockUser() async {
    final confirmed = await AppCenterDialog.show(
      context,
      title: '拉黑 ${_item.userName}',
      content: '拉黑后将不再接收对方消息，且会通知平台核查。确定拉黑吗？',
      cancelText: '取消',
      confirmText: '拉黑',
      confirmColor: AppColors.priceRed,
    );
    if (confirmed != true || !mounted) return;
    await _blockUser();
  }

  /// 执行拉黑。iOS 参照：blockUser。
  Future<void> _blockUser() async {
    final imUserId = _item.imUserId?.trim() ?? '';
    final userId = _item.userId;
    if (imUserId.isEmpty || userId == null) {
      AppToast.show(context, '拉黑失败：缺少用户信息');
      return;
    }
    setState(() {
      _actionBusy = true;
      _actionBusyMessage = '拉黑中';
    });
    try {
      await ref.read(reportServiceProvider).blockUser(
            imUserId: imUserId,
            blockedUserId: '$userId',
          );
      if (!mounted) return;
      setState(() => _actionBusy = false);
      AppToast.show(context, '已拉黑');
      // 删会话后刷新工作台「消息」Tab（与 ReportService.deleteC2CConversation 配套）
      ref.invalidate(conversationListProvider);
      ref.read(imPeerBlockedTickProvider.notifier).state++;
      Navigator.of(context).maybePop();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _actionBusy = false);
      AppToast.show(context, e.msg.isEmpty ? '拉黑失败' : e.msg);
    } catch (_) {
      if (!mounted) return;
      setState(() => _actionBusy = false);
      AppToast.show(context, '拉黑失败');
    }
  }

  /// 来访用户卡片点击 → 数字心理画像（route 9005 + userId）。
  /// iOS 参照：userCardTapped；userId 空 Toast「用户信息缺失」。
  void _openPersonality() {
    final userId = _item.userId;
    if (userId == null) {
      AppToast.show(context, '用户信息缺失');
      return;
    }
    context.push(
      Uri(
        path: RoutePaths.personality,
        queryParameters: {'userId': '$userId'},
      ).toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.pageBackground,
          // 底部操作栏（iOS setupBottomBar：白底 + 上投影）
          bottomNavigationBar: _DetailBottomBar(
            onBackTapped: () => Navigator.of(context).maybePop(),
            onContactTapped: _contactUser,
          ),
          body: AppPageBackground(
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // 透明导航（iOS gk_navBackgroundColor clear + 标题「预约详情」）
                  // 右侧「更多」：举报 / 拉黑（iOS setupMoreButton）
                  AppNavBar(
                    title: '预约详情',
                    transparent: true,
                    actions: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _moreTapped,
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: Center(
                            child: LoadImage(
                              AppAssets.navBarMore,
                              width: 24,
                              height: 24,
                              errorWidget: const Icon(
                                Icons.more_horiz,
                                size: 24,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(
                        top: 14,
                        left: AppDimens.screenPadding,
                        right: AppDimens.screenPadding,
                        bottom: 20,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 顶部预约信息卡（渐变头图 + 来访用户卡片）
                          _AppointmentHeaderCard(
                            item: _item,
                            onUserCardTapped: _openPersonality,
                          ),
                          // 「就诊档案」分区标题（卡片间距 15，标题下 22）
                          const SizedBox(height: AppDimens.gap15),
                          Text(
                            '就诊档案',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 22),
                          _ComplaintCard(item: _item),
                          if (_item.historyRecords.isNotEmpty ||
                              _item.historyTotal > 0) ...[
                            const SizedBox(height: AppDimens.gap10),
                            _HistoryCard(
                              item: _item,
                              expanded: _historyExpanded,
                              expandedRecords: _expandedRecords,
                              onToggle: _toggleHistory,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_historyLoading)
          const Positioned.fill(
            child: AppLoadingHud(message: '加载中'),
          ),
        if (_actionBusy)
          Positioned.fill(
            child: AppLoadingHud(message: _actionBusyMessage),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 底部操作栏
// ---------------------------------------------------------------------------

/// 底部操作栏：「返回列表」（宽 115，#F7F8FC 底 #525EE1 字）+
/// 「联系用户」（靛蓝渐变撑满），45 高圆角 22.5。
/// iOS 参照：XYCounselorAppointmentDetailViewController.setupBottomBar。
class _DetailBottomBar extends StatelessWidget {
  const _DetailBottomBar({
    required this.onBackTapped,
    required this.onContactTapped,
  });

  final VoidCallback onBackTapped;
  final VoidCallback onContactTapped;

  /// 返回列表按钮宽（Figma 230 ÷ 2）
  static const double _backButtonWidth = 115;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        boxShadow: [
          BoxShadow(
            color: Color(0x66EAEAEA),
            offset: Offset(0, -4),
            blurRadius: 4,
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: AppDimens.screenPadding,
        right: AppDimens.screenPadding,
        top: AppDimens.gap15,
        bottom: AppDimens.gap15 + MediaQuery.of(context).padding.bottom,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBackTapped,
            child: Container(
              width: _backButtonWidth,
              height: AppDimens.buttonHeight,
              decoration: BoxDecoration(
                color: AppColors.innerBackground,
                borderRadius:
                    BorderRadius.circular(AppDimens.buttonRadiusCapsule),
              ),
              alignment: Alignment.center,
              child: Text(
                '返回列表',
                style: AppTextStyles.title.copyWith(color: AppColors.indigo),
              ),
            ),
          ),
          const SizedBox(width: AppDimens.gap10),
          Expanded(
            child: GestureDetector(
              onTap: onContactTapped,
              child: Container(
                height: AppDimens.buttonHeight,
                decoration: BoxDecoration(
                  gradient: AppColors.indigoButtonGradient,
                  borderRadius:
                      BorderRadius.circular(AppDimens.buttonRadiusCapsule),
                ),
                alignment: Alignment.center,
                child: Text(
                  '联系用户',
                  style: AppTextStyles.title.copyWith(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 顶部预约信息卡
// ---------------------------------------------------------------------------

/// 时段 + 日期 + 描边徽标：按 iOS SnapKit 约束精确定位。
/// - day.lastBaseline = time.lastBaseline - 2
/// - modeBadge.bottom = time.lastBaseline + 2（视觉下调 2pt）
class _AppointmentTimeRow extends StatelessWidget {
  const _AppointmentTimeRow({
    required this.timeText,
    required this.dayText,
    required this.mode,
  });

  final String timeText;
  final String dayText;
  final CounselorSupportMode mode;

  static const double _gap = AppDimens.gap8;
  static const double _badgeHeight = 18;
  static const double _dayBaselineOffset = -2;

  @override
  Widget build(BuildContext context) {
    final timeStyle = AppTextStyles.displayLarge.copyWith(height: 1);
    final dayStyle = AppTextStyles.titleSmall.copyWith(
      color: AppColors.textSecondary,
      height: 1,
    );

    final timePainter = TextPainter(
      text: TextSpan(text: timeText, style: timeStyle),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();

    final timeBaseline =
        timePainter.computeDistanceToActualBaseline(TextBaseline.alphabetic) ??
            timePainter.height;

    double dayWidth = 0;
    double dayTop = 0;
    if (dayText.isNotEmpty) {
      final dayPainter = TextPainter(
        text: TextSpan(text: dayText, style: dayStyle),
        textDirection: TextDirection.ltr,
        textScaler: MediaQuery.textScalerOf(context),
      )..layout();
      final dayBaseline =
          dayPainter.computeDistanceToActualBaseline(TextBaseline.alphabetic) ??
              dayPainter.height;
      dayWidth = dayPainter.width;
      // day.lastBaseline = time.lastBaseline - 2
      dayTop = timeBaseline + _dayBaselineOffset - dayBaseline;
    }

    final badgeLeft =
        timePainter.width + _gap + (dayText.isEmpty ? 0 : dayWidth + _gap);
    // modeBadge.bottom = time.lastBaseline + 2（视觉下调 2pt）
    final badgeTop = timeBaseline - _badgeHeight + 2;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 非定位：用时段撑开 Stack 尺寸
        Text(timeText, style: timeStyle),
        if (dayText.isNotEmpty)
          Positioned(
            left: timePainter.width + _gap,
            top: dayTop,
            child: Text(dayText, style: dayStyle),
          ),
        Positioned(
          left: badgeLeft,
          top: badgeTop,
          child: CounselorOutlineModeBadge(mode: mode),
        ),
      ],
    );
  }
}

/// 顶部预约信息卡：渐变头图（时段/日期/描边徽标/装饰图）+ 来访用户卡片
/// （与头图底部重叠 19；点击进数字心理画像）。
/// iOS 参照：setupAppointmentHeader + userCardTapped（Figma 571:4863）。
class _AppointmentHeaderCard extends StatelessWidget {
  const _AppointmentHeaderCard({
    required this.item,
    required this.onUserCardTapped,
  });

  final CounselorOrderDetailItem item;
  final VoidCallback onUserCardTapped;

  /// 渐变头图高（Figma 154 ÷ 2）
  static const double _headerHeight = 77;

  /// 用户卡片与头图底部重叠量（Figma 38 ÷ 2）
  static const double _userCardOverlap = 19;

  /// 用户卡片高（Figma 140 ÷ 2）
  static const double _userCardHeight = 70;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _headerHeight - _userCardOverlap + _userCardHeight,
      child: Stack(
        children: [
          // 渐变头图（白 0.2 → 白 0.6，下 → 上；仅顶部圆角 16）
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: _headerHeight,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.2),
                    Colors.white.withValues(alpha: 0.6),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppDimens.cardRadiusLarge),
                ),
              ),
              child: Stack(
                children: [
                  // 时段 + 日期 + 咨询方式：对齐 iOS
                  // day.lastBaseline = time.lastBaseline - 2；
                  // modeBadge.bottom = time.lastBaseline
                  Positioned(
                    left: AppDimens.gap15,
                    top: AppDimens.gap15,
                    child: _AppointmentTimeRow(
                      timeText: item.timeText,
                      dayText: item.dayText,
                      mode: item.supportMode,
                    ),
                  ),
                  // 顶部装饰图（64，alpha 0.17）
                  Positioned(
                    right: 4,
                    top: 2,
                    child: Opacity(
                      opacity: 0.17,
                      child: LoadImage(
                        AppAssets.icAppointmentDetailDecor,
                        width: 64,
                        height: 64,
                        errorWidget: const SizedBox(width: 64, height: 64),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 来访用户卡片（#F7F8FC 底圆角 16，高 70；点击 → 心理画像）
          Positioned(
            top: _headerHeight - _userCardOverlap,
            left: 0,
            right: 0,
            height: _userCardHeight,
            child: Material(
              color: AppColors.innerBackground,
              borderRadius:
                  BorderRadius.circular(AppDimens.cardRadiusLarge),
              child: InkWell(
                borderRadius:
                    BorderRadius.circular(AppDimens.cardRadiusLarge),
                onTap: onUserCardTapped,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.gap15,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.dividerDark,
                        backgroundImage: (item.userAvatar != null &&
                                item.userAvatar!.isNotEmpty)
                            ? ImageUtils.getImageProvider(item.userAvatar!)
                            : null,
                        child: (item.userAvatar == null ||
                                item.userAvatar!.isEmpty)
                            ? const Icon(Icons.person,
                                size: 24, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: AppDimens.gap12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.userName,
                                style: AppTextStyles.titleSmall),
                            if (item.userSubtitle.isNotEmpty) ...[
                              const SizedBox(height: AppDimens.gap4),
                              Text(
                                item.userSubtitle,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const CounselorChevronRight(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 用户主诉标签 + AI 情绪摘要卡片
// ---------------------------------------------------------------------------

/// 用户主诉标签卡片（含 AI 情绪初判摘要渐变块）。
/// iOS 参照：setupComplaintCard（Figma 571:4951 / 571:4968）。
class _ComplaintCard extends StatelessWidget {
  const _ComplaintCard({required this.item});

  final CounselorOrderDetailItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimens.cardRadius),
      ),
      padding: const EdgeInsets.all(AppDimens.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 区块标题行（图标 15 + 文案 15 w600）
          const _SectionTitleRow(
            icon: AppAssets.icAppointmentDetailTag,
            title: '用户主诉标签',
          ),
          if (item.tags.isNotEmpty) ...[
            const SizedBox(height: AppDimens.gap12),
            // 主诉标签流（iOS XYCounselorDetailTagFlowView：
            // #F7F8FC 底、#CCCCCC 0.5 描边、圆角 6、12 #222、间距 8）
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tag in item.tags)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.innerBackground,
                      borderRadius:
                          BorderRadius.circular(AppDimens.radiusTag),
                      border: Border.all(
                        color: AppColors.placeholder,
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      tag,
                      softWrap: false,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textPrimary,
                        height: 1,
                      ),
                    ),
                  ),
              ],
            ),
          ],
          if (item.emotionSummary.isNotEmpty) ...[
            const SizedBox(height: AppDimens.gap12),
            // AI 情绪初判摘要（顶部 #E9FAFF → 底部白渐变，
            // 描边 #30DFC7 50% 0.5、圆角 10）
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.brandTealLight, Colors.white],
                ),
                borderRadius:
                    BorderRadius.circular(AppDimens.radiusInner),
                border: Border.all(
                  color: const Color(0x8030DFC7),
                  width: 0.5,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      LoadImage(
                        AppAssets.icAppointmentDetailAi,
                        width: 14,
                        height: 14,
                        errorWidget: const Icon(
                          Icons.auto_awesome,
                          size: 14,
                          color: AppColors.brandTeal,
                        ),
                      ),
                      const SizedBox(width: AppDimens.gap6),
                      Text(
                        'AI 情绪初判摘要',
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.brandTeal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimens.gap10),
                  Text(
                    item.emotionSummary,
                    style: AppTextStyles.titleSmall,
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 过往接待记录卡片
// ---------------------------------------------------------------------------

/// 过往接待记录卡片（收起态前 2 条；total > 2 时展示「查看全部」，
/// 展开后分页加载全部）。
/// iOS 参照：setupHistoryCard / rebuildHistoryRecords / expandHistory。
class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.item,
    required this.expanded,
    required this.expandedRecords,
    required this.onToggle,
  });

  final CounselorOrderDetailItem item;
  final bool expanded;
  final List<CounselorHistoryItem> expandedRecords;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final records =
        expanded ? expandedRecords : item.historyRecords.take(2).toList();
    // 仅当记录总数 > 2 时展示「查看全部」（iOS historyAllButton.isHidden）
    final showToggle = item.historyTotal > 2;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimens.cardRadius),
      ),
      padding: const EdgeInsets.all(AppDimens.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _SectionTitleRow(
                icon: AppAssets.icAppointmentDetailHistory,
                title: '过往接待记录',
              ),
              if (item.historyTotal > 0)
                Text(
                  '（${item.historyTotal}）',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              const Spacer(),
              if (showToggle)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onToggle,
                  child: Padding(
                    // 命中区向外扩展（iOS hitInsets）
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          expanded ? '收起全部' : '查看全部',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: AppDimens.gap4),
                        // 右箭头旋转：收起态 90°（下）、展开态 -90°（上）
                        Transform.rotate(
                          angle: expanded ? -math.pi / 2 : math.pi / 2,
                          child: const CounselorChevronRight(size: 12),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppDimens.gap12),
          for (var i = 0; i < records.length; i++) ...[
            if (i > 0) const SizedBox(height: AppDimens.gap10),
            _HistoryRecordView(record: records[i]),
          ],
        ],
      ),
    );
  }
}

/// 单条过往记录（#F7F8FC 底圆角 10：日期 14 w600 + 沟通方式徽标 +
/// 摘要 12 #666）。
/// iOS 参照：makeHistoryRecordView（Figma 571:4998）。
class _HistoryRecordView extends StatelessWidget {
  const _HistoryRecordView({required this.record});

  final CounselorHistoryItem record;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.innerBackground,
        borderRadius: BorderRadius.circular(AppDimens.radiusInner),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  record.dateText,
                  style: AppTextStyles.bodyLargeStrong,
                ),
              ),
              // 沟通方式徽标（白底圆角 9、#E5E5E5 0.5 描边、11 #222）
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius:
                      BorderRadius.circular(AppDimens.radiusConsultTag),
                  border: Border.all(
                    color: AppColors.navDivider,
                    width: 0.5,
                  ),
                ),
                child: Text(
                  record.modeText,
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.gap8),
          Text(
            record.summary,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// 区块标题行（图标 15 + 文案 15 w600 #222）。
/// iOS 参照：makeSectionTitleRow。
class _SectionTitleRow extends StatelessWidget {
  const _SectionTitleRow({required this.icon, required this.title});

  final String icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        LoadImage(
          icon,
          width: 15,
          height: 15,
          errorWidget: const SizedBox(width: 15, height: 15),
        ),
        const SizedBox(width: AppDimens.gap6),
        Text(title, style: AppTextStyles.titleSmall),
      ],
    );
  }
}
