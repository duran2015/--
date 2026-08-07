import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../core/im/im_config.dart';
import '../../core/network/api_response.dart';
import '../../core/router/route_paths.dart';
import '../../core/theme/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_background.dart';
import '../../core/widgets/app_loading_hud.dart';
import '../../core/widgets/app_toast.dart';
import '../../utils/load_image.dart';
import '../report/more_action_sheet.dart';
import '../report/report_models.dart';
import '../report/report_reason_sheet.dart';
import '../report/report_service.dart';
import '../order/order_action.dart';
import '../order/order_api.dart';
import '../order/order_models.dart';
import 'widgets/chat_conversation_view.dart';
import 'widgets/chat_user_header_view.dart';

/// 1v1 C2C 聊天页（/chat，契约 routeTypeCode=1005）。
/// iOS 参照：XYChatModule XYChatContainerViewController（聊天容器，
/// 机器人会话与咨询师会话复用同一页）。
/// Android 参照：RobotChatFragment（targetUserId 空 → 默认机器人）。
///
/// 参数（query）：
/// - targetUserId / imUserId：对方 IM userId（空 → 机器人 @RBT#xinyu001）；
/// - userName：对方昵称（导航标题）；
/// - avatar：对方头像 URL（可选）；
/// - tags：对方标签（可选，逗号分隔）。
class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({
    super.key,
    this.targetUserId,
    this.userName,
    this.avatar,
    this.tags,
    this.consultantId,
    this.orderId,
    this.consultantIntro,
    this.bookedSku,
  });

  final String? targetUserId;
  final String? userName;
  final String? avatar;
  final List<String>? tags;
  final int? consultantId;
  final String? orderId;
  final String? consultantIntro;
  final String? bookedSku;

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  bool _actionBusy = false;
  AppointmentOrderItem? _order;
  final GlobalKey<ChatConversationViewState> _conversationKey =
      GlobalKey<ChatConversationViewState>();

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    final orderId = widget.orderId?.trim() ?? '';
    if (orderId.isEmpty) return;
    try {
      final order = await ref.read(orderApiProvider).findOrderById(orderId);
      if (!mounted) return;
      setState(() => _order = order);
    } catch (_) {
      // 头部状态属于辅助信息，加载失败不阻断聊天。
    }
  }

  void _handleOrderAction() {
    final item = _order;
    if (item == null) return;
    final action = OrderActionRouter.primaryAction(item);
    switch (action) {
      case OrderPrimaryAction.fillIntake:
        context.push(
          Uri(path: RoutePaths.paymentIntake, queryParameters: {
            'orderId': item.orderId,
            'imUserId': widget.targetUserId ?? '',
            'name': widget.userName ?? '',
            if ((widget.avatar ?? '').isNotEmpty) 'avatar': widget.avatar!,
          }).toString(),
        );
        return;
      case OrderPrimaryAction.viewRecap:
      case OrderPrimaryAction.viewArchivedRecap:
        context.push('${RoutePaths.summaryDetail}?orderId=${item.orderId}');
        return;
      case OrderPrimaryAction.evaluate:
        context.push(
          Uri(path: RoutePaths.evaluate, queryParameters: {
            'orderId': item.orderId,
            if (widget.consultantId != null)
              'counselorId': widget.consultantId.toString(),
            'counselorName': widget.userName ?? '',
            if ((widget.avatar ?? '').isNotEmpty)
              'counselorAvatar': widget.avatar!,
          }).toString(),
        );
        return;
      case OrderPrimaryAction.pay:
      case OrderPrimaryAction.enterSession:
      case OrderPrimaryAction.contact:
        context.push('${RoutePaths.orderDetail}?orderId=${item.orderId}');
        return;
      case OrderPrimaryAction.none:
        return;
    }
  }

  /// 点击导航右上角「更多」：真人咨询师会话支持举报与直接拉黑。
  Future<void> _moreTapped() async {
    final peerId = (widget.targetUserId == null || widget.targetUserId!.isEmpty)
        ? ImConfig.robotUserId
        : widget.targetUserId!;
    final action = await MoreActionSheet.show(
      context,
      showBlock: !peerId.startsWith(ImConfig.robotPrefix),
    );
    if (!mounted || action == null) return;
    if (action == MoreSheetAction.report) {
      await _openReportReasonSheet();
    } else if (action == MoreSheetAction.block) {
      await _blockPeer(peerId);
    }
  }

  /// 直接拉黑对方，不增加二次确认；成功后当前会话立即进入禁发态。
  Future<void> _blockPeer(String peerId) async {
    setState(() => _actionBusy = true);
    try {
      await ref.read(reportServiceProvider).blockUser(
            imUserId: peerId,
            consultantId: widget.consultantId?.toString(),
          );
      if (!mounted) return;
      ref.read(counselorBlockedTickProvider.notifier).state++;
      ref.read(imPeerBlockedTickProvider.notifier).state++;
      _conversationKey.currentState?.applyBlockedState();
      setState(() => _actionBusy = false);
      AppToast.show(context, '已拉黑该咨询师');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _actionBusy = false);
      AppToast.show(context, e.msg.isEmpty ? '拉黑失败' : e.msg);
    } catch (_) {
      if (!mounted) return;
      setState(() => _actionBusy = false);
      AppToast.show(context, '拉黑失败，请稍后重试');
    }
  }

  /// 弹出举报理由并提交
  Future<void> _openReportReasonSheet() async {
    final reason = await ReportReasonSheet.show(context);
    if (!mounted || reason == null) return;
    await _submitReport(reason: reason);
  }

  /// 提交举报
  Future<void> _submitReport({required ReportReason reason}) async {
    final peerId = (widget.targetUserId == null || widget.targetUserId!.isEmpty)
        ? ImConfig.robotUserId
        : widget.targetUserId!;
    if (peerId.isEmpty) {
      AppToast.show(context, '举报失败：缺少对象信息');
      return;
    }
    setState(() => _actionBusy = true);
    try {
      await ref.read(reportServiceProvider).submitReport(
            targetType: ReportTargetType.chat,
            targetId: peerId,
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

  @override
  Widget build(BuildContext context) {
    final peerId = (widget.targetUserId == null || widget.targetUserId!.isEmpty)
        ? ImConfig.robotUserId
        : widget.targetUserId!;
    final isRobot = peerId.startsWith(ImConfig.robotPrefix);
    final title = (widget.userName == null || widget.userName!.isEmpty)
        ? (isRobot ? '心愈小鹿' : peerId)
        : widget.userName!;
    final order = _order;
    final orderAction = order == null
        ? OrderPrimaryAction.none
        : OrderActionRouter.primaryAction(order);
    return Scaffold(
      // 键盘弹起时压缩 body，消息区 + 输入栏整体上移
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          AppPageBackground(
            // bottom: false —— 拉黑遮罩 / 输入栏白底延伸盖住 Home 指示条（对齐 iOS）
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _buildNavBar(context, title),
                  ChatUserHeaderView(
                    userName: title,
                    avatar: widget.avatar,
                    avatarSeed: peerId,
                    tags: widget.tags,
                    consultantIntro: widget.consultantIntro,
                    bookedSku: widget.bookedSku,
                    orderStatus: order == null
                        ? null
                        : OrderActionRouter.statusLabel(order),
                    actionText:
                        order == null || orderAction == OrderPrimaryAction.none
                            ? null
                            : OrderActionRouter.detailPrimaryTitle(order),
                    onActionTap: _handleOrderAction,
                    onAvatarTap: widget.consultantId == null
                        ? null
                        : () => context.push(
                              '${RoutePaths.consultantDetail}?consultantId=${widget.consultantId}',
                            ),
                    onOrderTap:
                        widget.orderId == null || widget.orderId!.isEmpty
                            ? null
                            : () => context.push(
                                  '${RoutePaths.orderDetail}?orderId=${Uri.encodeComponent(widget.orderId!)}',
                                ),
                  ),
                  Expanded(
                    child: ChatConversationView(
                      key: _conversationKey,
                      peerUserId: peerId,
                      peerName: title,
                      peerAvatar: widget.avatar,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_actionBusy)
            const Positioned.fill(
              child: AppLoadingHud(message: '提交中'),
            ),
        ],
      ),
    );
  }

  /// 导航栏（44 高，返回键 + 右侧更多按钮，参照 Figma 视觉稿布局）
  Widget _buildNavBar(BuildContext context, String title) {
    return SizedBox(
      height: 44,
      child: Stack(
        children: [
          Center(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).maybePop(),
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  Icons.arrow_back_ios_new,
                  size: 20,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          Positioned(
            right: 8.w,
            top: 0,
            bottom: 0,
            child: GestureDetector(
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
          ),
        ],
      ),
    );
  }
}
