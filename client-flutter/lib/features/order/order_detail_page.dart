import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/consult_room/consult_room_launcher.dart';
import '../../core/consult_room/consult_room_service.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';
import '../../core/router/route_paths.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/deadline_countdown.dart';
import '../../core/widgets/app_dialog.dart';
import '../../core/widgets/app_loading_hud.dart';
import '../../core/widgets/app_nav_bar.dart';
import '../../core/widgets/app_states.dart';
import '../../core/widgets/app_toast.dart';
import '../../utils/load_image.dart';
import '../consultant/consultant_models.dart';
import '../payment/payment_view_model.dart';
import 'order_action.dart';
import 'appointment_policy.dart';
import 'order_api.dart';
import 'order_models.dart';
import 'widgets/order_widgets.dart';

/// 预约订单详情页（路由 /orders/detail?orderId=）。
/// iOS 参照：XYAIModule/XYAIModule/Classes/ViewController/
/// XYAppointmentOrderDetailViewController.swift（Figma 457:1972「预约详情-待咨询」）——
/// 顶部状态文案（未支付拼倒计时）+ 订单信息卡 + 取消政策温馨提示卡 + 底部双按钮。
class OrderDetailPage extends ConsumerStatefulWidget {
  const OrderDetailPage({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends ConsumerState<OrderDetailPage> {
  static const _pageColor = Color(0xFFFAF8F5);
  static const _outlineColor = Color(0xFFECE6DC);
  static const _labelColor = Color(0xFF7A756C);
  static const _primaryColor = Color(0xFF6750A4);
  AppointmentOrderItem? _item;
  Object? _error;
  bool _loading = true;
  bool _cancelling = false;
  bool _rescheduling = false;

  late DeadlineCountdown _countdown;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _countdown = DeadlineCountdown(null);
    _load();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final item =
          await ref.read(orderApiProvider).findOrderById(widget.orderId);
      if (!mounted) return;
      setState(() {
        _item = item;
        _loading = false;
        _error = item == null ? '订单不存在' : null;
      });
      _setupCountdown();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  /// 未支付订单带支付截止时间时，启动每秒倒计时刷新顶部状态文案。
  /// iOS 参照：viewDidLoad 中 countdown/startCountdown。
  /// 时钟用服务器时间（ApiClient.serverNow，对应 iOS XYServerTime.now）。
  void _setupCountdown() {
    final item = _item;
    _countdownTimer?.cancel();
    if (item == null) return;
    _countdown = DeadlineCountdown(
      item.paymentDeadline,
      clock: () => ref.read(apiClientProvider).serverNow(),
    );
    if (item.displayStatus == OrderActionRouter.statusUnpaid &&
        _countdown.hasDeadline) {
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() {
          if (!_countdown.tick()) _countdownTimer?.cancel();
        });
      });
    }
  }

  /// 顶部状态文案：未支付订单拼倒计时（如「待支付，剩余14:55」），其余按 statusText。
  /// iOS 参照：unpaidStatusText。
  String get _statusText {
    final item = _item!;
    if (item.displayStatus == OrderActionRouter.statusUnpaid &&
        _countdown.hasDeadline) {
      return '${OrderActionRouter.statusLabel(item)}，剩余${_countdown.countdownText}';
    }
    return OrderActionRouter.statusLabel(item);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: _pageColor,
          bottomNavigationBar: _buildBottomBar(),
          body: SafeArea(
            child: Column(
              children: [
                const AppNavBar(title: '订单详情'),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ),
        if (_cancelling || _rescheduling)
          Positioned.fill(
            child: AppLoadingHud(message: _rescheduling ? '提交改期申请' : '取消中'),
          ),
      ],
    );
  }

  Widget _buildBody() {
    if (_loading) return const AppLoadingView();
    if (_error != null || _item == null) {
      return AppErrorView(
        message: _error is String ? '$_error' : '加载失败，请稍后重试',
        onRetry: _load,
      );
    }
    final item = _item!;
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _statusCard(item),
          const SizedBox(height: 14),
          _appointmentCard(item),
          const SizedBox(height: 14),
          _paymentCard(item),
          if (OrderActionRouter.showTipCard(item)) ...[
            const SizedBox(height: 14),
            _tipCard(),
          ],
        ],
      ),
    );
  }

  Widget _surfaceCard({required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _outlineColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _statusCard(AppointmentOrderItem item) {
    return _surfaceCard(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            _detailRow(
              label: '订单状态',
              valueWidget: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: OrderStatusBadge.textColorOf(item.displayStatus)
                      .withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  _statusText,
                  style: AppTextStyles.label.copyWith(
                    color: OrderStatusBadge.textColorOf(item.displayStatus),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Divider(height: 1, color: _outlineColor),
            ),
            _detailRow(
              label: '订单编号',
              value: (item.orderNo ?? '').isEmpty ? '—' : item.orderNo!,
              valueStyle: _infoValueStyle.copyWith(
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 18, color: _primaryColor),
        const SizedBox(width: 8),
        Text(title,
            style: AppTextStyles.titleSmall.copyWith(
              fontWeight: FontWeight.w700,
            )),
      ],
    );
  }

  Widget _appointmentCard(AppointmentOrderItem item) {
    final sku = [item.supportModeText, item.durationDisplay]
        .where((value) => value.isNotEmpty)
        .join(' · ');
    return _surfaceCard(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Align(
              alignment: Alignment.centerLeft,
              child: _sectionTitle(Icons.calendar_month_outlined, '预约明细'),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18),
            child: Divider(height: 1, color: _outlineColor),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                _detailRow(
                  label: '咨询师',
                  valueWidget: Row(mainAxisSize: MainAxisSize.min, children: [
                    OrderAvatar(
                      url: item.counselorAvatar,
                      name: item.counselorName,
                      seed: item.counselorIMUserID,
                      size: 32,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(item.counselorName,
                          style: _infoValueStyle,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ]),
                ),
                const SizedBox(height: 16),
                _detailRow(
                  label: '服务项目',
                  value: sku.isEmpty ? '在线心理咨询' : sku,
                ),
                const SizedBox(height: 16),
                _detailRow(
                  label: '预约时间',
                  value: item.appointmentTimeRangeDisplay.isNotEmpty
                      ? item.appointmentTimeRangeDisplay
                      : item.appointmentTimeDisplay,
                ),
                if (item.rescheduleStatus == 'pending' ||
                    item.rescheduleStatus == 'approved') ...[
                  const SizedBox(height: 16),
                  _detailRow(
                    label: '改期状态',
                    value: item.rescheduleStatus == 'approved'
                        ? '咨询师已同意，请选择新时间'
                        : '申请待咨询师确认',
                    valueStyle: _infoValueStyle.copyWith(color: _primaryColor),
                  ),
                ],
                const SizedBox(height: 16),
                _detailRow(
                  label: '咨询形式',
                  valueWidget: Row(mainAxisSize: MainAxisSize.min, children: [
                    LoadImage(methodIconAsset(item.supportMode),
                        width: 15, height: 15, color: _primaryColor),
                    const SizedBox(width: 5),
                    Text(item.supportModeText, style: _infoValueStyle),
                  ]),
                ),
                if ((item.counselorTitle ?? '').isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _detailRow(
                    label: '咨询师介绍',
                    value: item.counselorTitle!,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openRescheduleSheet({required bool selectTime}) async {
    final item = _item;
    if (item == null || item.orderId == null) return;
    final request = await showModalBottomSheet<_RescheduleRequest>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RescheduleSheet(
        selectTime: selectTime,
        currentAppointment: item.appointmentTimeRangeDisplay.isNotEmpty
            ? item.appointmentTimeRangeDisplay
            : item.appointmentTimeDisplay,
      ),
    );
    if (request == null || !mounted) return;
    setState(() => _rescheduling = true);
    try {
      if (selectTime) {
        await ref.read(orderApiProvider).selectRescheduleTime(
              orderId: item.orderId!,
              appointmentTime: request.appointmentTime!,
            );
      } else {
        await ref.read(orderApiProvider).requestReschedule(
              orderId: item.orderId!,
              reason: request.reason,
            );
      }
      if (!mounted) return;
      AppToast.show(context, selectTime ? '预约时间已更新' : '改期申请已发送给咨询师');
      await _load();
    } on ApiException catch (error) {
      if (mounted) AppToast.show(context, error.msg);
    } catch (_) {
      if (mounted) AppToast.show(context, '提交失败，请稍后重试');
    } finally {
      if (mounted) setState(() => _rescheduling = false);
    }
  }

  Widget _paymentCard(AppointmentOrderItem item) {
    final price = '¥${formatPrice(item.price ?? 0)}';
    return _surfaceCard(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Align(
              alignment: Alignment.centerLeft,
              child: _sectionTitle(Icons.receipt_long_outlined, '费用明细'),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18),
            child: Divider(height: 1, color: _outlineColor),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                _detailRow(label: '服务金额', value: price),
                const SizedBox(height: 14),
                _detailRow(
                  label: '实付金额',
                  value: price,
                  valueStyle: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static TextStyle get _infoValueStyle => AppTextStyles.body.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  Widget _detailRow({
    required String label,
    String? value,
    Widget? valueWidget,
    TextStyle? valueStyle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.body.copyWith(color: _labelColor)),
        const SizedBox(width: 16),
        valueWidget ??
            Expanded(
              child: Text(
                value ?? '',
                style: valueStyle ?? _infoValueStyle,
                textAlign: TextAlign.right,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
      ],
    );
  }

  /// 温馨提示卡片（取消政策）：仅未支付 / 待咨询订单展示。
  /// iOS 参照：tipCard + tipAttributedString（#FFF9F4 底、#FF6C00 11 号、行高 18）。
  Widget _tipCard() {
    final lines = AppointmentPolicy.current.userFacingLines;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.tipBackground,
        borderRadius: BorderRadius.circular(AppDimens.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('预约与取消规则',
              style: AppTextStyles.titleSmall.copyWith(
                color: AppColors.tipText,
              )),
          const SizedBox(height: 8),
          Text(
            lines.map((line) => '• $line').join('\n'),
            style: AppTextStyles.label.copyWith(
              color: AppColors.tipText,
              height: 18 / 11,
            ),
          ),
        ],
      ),
    );
  }

  /// 底部操作栏（已取消订单不创建；次按钮 取消预约 / 主按钮按状态）。
  /// iOS 参照：setupBottomBar + configureBottomButtons（45 高、圆角 22、16 semibold）。
  Widget? _buildBottomBar() {
    final item = _item;
    if (_loading || item == null) return null;
    if (!OrderActionRouter.showBottomBar(item)) return null;

    final primaryAction = OrderActionRouter.detailPrimaryAction(item);
    final showSecondary = OrderActionRouter.showCancelButton(item);
    final canApply = OrderActionRouter.canRequestReschedule(item);
    final canSelectTime = OrderActionRouter.canSelectRescheduleTime(item);
    final reschedulePending = item.rescheduleStatus == 'pending';
    final showReschedule = canApply || canSelectTime || reschedulePending;
    if (!showSecondary &&
        primaryAction == OrderPrimaryAction.none &&
        !showReschedule) {
      return null;
    }
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        boxShadow: [
          BoxShadow(
            color: AppColors.divider.withValues(alpha: 0.4),
            offset: const Offset(0, -8),
            blurRadius: 8,
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(15, 12, 15, 12 + bottomInset),
      child: Row(
        children: [
          if (showSecondary)
            Expanded(child: _secondaryButton())
          else
            const SizedBox.shrink(),
          if (showSecondary &&
              (showReschedule || primaryAction != OrderPrimaryAction.none))
            const SizedBox(width: 10),
          if (showReschedule)
            Expanded(
              child: _rescheduleBottomButton(
                pending: reschedulePending,
                selectTime: canSelectTime,
              ),
            )
          else if (primaryAction != OrderPrimaryAction.none)
            Expanded(
              child: _primaryButton(item, primaryAction, full: !showSecondary),
            ),
        ],
      ),
    );
  }

  Widget _rescheduleBottomButton({
    required bool pending,
    required bool selectTime,
  }) {
    return GestureDetector(
      key: const Key('request_reschedule'),
      onTap:
          pending ? null : () => _openRescheduleSheet(selectTime: selectTime),
      child: Container(
        height: 45,
        decoration: BoxDecoration(
          color: pending ? const Color(0xFFF3EDF7) : _primaryColor,
          borderRadius: BorderRadius.circular(22),
        ),
        alignment: Alignment.center,
        child: Text(
          pending ? '申请待确认' : (selectTime ? '选择新时间' : '申请改期'),
          style: AppTextStyles.title.copyWith(
            color: pending ? _primaryColor : Colors.white,
          ),
        ),
      ),
    );
  }

  /// 次按钮（取消预约）：#F1F4FB 底、#666 16 semibold。
  Widget _secondaryButton() {
    return GestureDetector(
      onTap: _cancelling ? null : _cancelOrder,
      child: Container(
        height: 45,
        decoration: BoxDecoration(
          color: AppColors.pageBackground,
          borderRadius: BorderRadius.circular(22),
        ),
        alignment: Alignment.center,
        child: Text(
          '取消预约',
          style: AppTextStyles.title.copyWith(color: AppColors.textSecondary),
        ),
      ),
    );
  }

  /// 主按钮（45 高、圆角 22、白字 16 semibold；去支付红渐变，其余青渐变）。
  Widget _primaryButton(
    AppointmentOrderItem item,
    OrderPrimaryAction action, {
    required bool full,
  }) {
    return GestureDetector(
      onTap: () => _handlePrimary(item, action),
      child: Container(
        height: 45,
        decoration: BoxDecoration(
          gradient: orderPrimaryActionGradient(action),
          borderRadius: BorderRadius.circular(22),
        ),
        alignment: Alignment.center,
        child: Text(
          OrderActionRouter.detailPrimaryTitle(item),
          style: AppTextStyles.title.copyWith(color: Colors.white),
        ),
      ),
    );
  }

  /// 主按钮点击：按状态分发（iOS XYAppointmentOrderActionRouter.handlePrimary）。
  Future<void> _handlePrimary(
    AppointmentOrderItem item,
    OrderPrimaryAction action,
  ) async {
    switch (action) {
      case OrderPrimaryAction.pay:
        final args = PaymentPageArgs.fromOrder(item);
        await context.push(
          Uri(path: RoutePaths.payment, queryParameters: args.toQuery())
              .toString(),
        );
        if (mounted) _load(); // 支付返回后刷新状态
      case OrderPrimaryAction.fillIntake:
        await context.push(
          Uri(path: RoutePaths.paymentIntake, queryParameters: {
            'orderId': item.orderId ?? '',
            'imUserId': item.counselorIMUserID,
            'name': item.counselorName,
            if (item.counselorAvatar != null) 'avatar': item.counselorAvatar!,
          }).toString(),
        );
        if (mounted) _load();
      case OrderPrimaryAction.enterSession:
        if (item.supportMode == '1') {
          await openOrderCounselorChat(context, item);
        } else {
          await launchConsultRoom(
            ref,
            ConsultRoomParams(
              orderId: item.orderId,
              supportMode: item.supportMode,
              roomId: item.roomId,
              roomName: item.roomName ?? item.supportModeText,
              imUserId: item.counselorIMUserID,
              userName: item.counselorName,
              userAvatar: item.counselorAvatar,
            ),
            context: context,
          );
        }
        if (mounted) _load();
      case OrderPrimaryAction.viewRecap:
      case OrderPrimaryAction.viewArchivedRecap:
        final id = int.tryParse(item.orderId ?? '');
        if (id == null) {
          AppToast.show(context, '回顾信息暂未生成');
          return;
        }
        await context.push('${RoutePaths.summaryDetail}?orderId=$id');
        if (mounted) _load();
      case OrderPrimaryAction.contact:
        await openOrderCounselorChat(context, item);
      case OrderPrimaryAction.evaluate:
        final consultantId = item.consultantId;
        if (item.orderId == null || consultantId == null) {
          AppToast.show(context, '订单信息无效');
          return;
        }
        final submitted = await context.push<bool>(
          Uri(
            path: RoutePaths.evaluate,
            queryParameters: {
              'orderId': item.orderId!,
              'counselorId': '$consultantId',
              'counselorName': item.counselorName,
              if (item.counselorAvatar != null &&
                  item.counselorAvatar!.isNotEmpty)
                'counselorAvatar': item.counselorAvatar!,
            },
          ).toString(),
        );
        if (submitted == true && mounted) _load();
      case OrderPrimaryAction.none:
        break;
    }
  }

  /// 取消预约：确认弹窗 → /app/consultant/order/cancel → Toast + pop 刷新列表。
  /// iOS 参照：XYAppointmentOrderActionRouter.cancelOrder + secondaryTapped。
  Future<void> _cancelOrder() async {
    final item = _item;
    final orderId = item?.orderId;
    if (item == null || orderId == null || orderId.isEmpty) {
      AppToast.show(context, '订单信息无效');
      return;
    }
    final confirmed = await AppCenterDialog.show(
      context,
      title: '取消预约',
      content: '确定要取消本次预约吗？',
      cancelText: '再想想',
      confirmText: '确定取消',
    );
    if (confirmed != true || !mounted) return;

    setState(() => _cancelling = true);
    try {
      await ref.read(orderApiProvider).cancelOrder(orderId);
      if (!mounted) return;
      AppToast.show(context, '取消成功');
      context.pop(true); // 通知列表刷新（iOS onOrderStatusChanged）
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _cancelling = false);
      AppToast.show(context, e.msg.isEmpty ? '取消失败' : e.msg);
    } catch (_) {
      if (!mounted) return;
      setState(() => _cancelling = false);
      AppToast.show(context, '取消失败');
    }
  }
}

class _RescheduleRequest {
  const _RescheduleRequest({
    this.appointmentTime,
    required this.reason,
  });

  final String? appointmentTime;
  final String reason;
}

class _RescheduleSheet extends StatefulWidget {
  const _RescheduleSheet({
    required this.currentAppointment,
    required this.selectTime,
  });

  final String currentAppointment;
  final bool selectTime;

  @override
  State<_RescheduleSheet> createState() => _RescheduleSheetState();
}

class _RescheduleSheetState extends State<_RescheduleSheet> {
  late final List<DateTime> _slots;
  int? _selectedIndex;
  String _reason = '时间冲突';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _slots = [
      DateTime(now.year, now.month, now.day + 2, 10),
      DateTime(now.year, now.month, now.day + 2, 19, 30),
      DateTime(now.year, now.month, now.day + 3, 14),
      DateTime(now.year, now.month, now.day + 4, 20),
      DateTime(now.year, now.month, now.day + 5, 9, 30),
      DateTime(now.year, now.month, now.day + 6, 16),
    ];
  }

  String _two(int value) => value.toString().padLeft(2, '0');

  String _display(DateTime slot) =>
      '${_two(slot.month)}月${_two(slot.day)}日  ${_two(slot.hour)}:${_two(slot.minute)}';

  String _apiValue(DateTime slot) =>
      '${slot.year}-${_two(slot.month)}-${_two(slot.day)} ${_two(slot.hour)}:${_two(slot.minute)}:00';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      height: MediaQuery.sizeOf(context).height * .72,
      decoration: const BoxDecoration(
        color: Color(0xFFFAF8F5),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: colors.outlineVariant,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 8, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(widget.selectTime ? '选择新时间' : '申请改期',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800)),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text('当前预约：${widget.currentAppointment}',
                        style: Theme.of(context).textTheme.bodyMedium),
                  ),
                  if (widget.selectTime) ...[
                    const SizedBox(height: 20),
                    Text('选择希望调整到的时间',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisExtent: 48,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: _slots.length,
                      itemBuilder: (context, index) {
                        final selected = _selectedIndex == index;
                        return ChoiceChip(
                          label: SizedBox(
                            width: double.infinity,
                            child: Text(_display(_slots[index]),
                                textAlign: TextAlign.center),
                          ),
                          selected: selected,
                          onSelected: (_) =>
                              setState(() => _selectedIndex = index),
                        );
                      },
                    ),
                  ] else ...[
                    const SizedBox(height: 20),
                    Text('改期原因',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: ['时间冲突', '临时事务', '身体不适', '其他原因']
                          .map((reason) => ChoiceChip(
                                label: Text(reason),
                                selected: _reason == reason,
                                onSelected: (_) =>
                                    setState(() => _reason = reason),
                              ))
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    widget.selectTime
                        ? '咨询师已同意本次改期。请从咨询师可服务时间中选择新时段。'
                        : '改期请至少提前 ${AppointmentPolicy.current.rescheduleHours} 小时申请。申请会发送给咨询师，对方同意后才能选择新时间；确认前原预约仍然有效。',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                          height: 1.5,
                        ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: FilledButton(
              onPressed: widget.selectTime && _selectedIndex == null
                  ? null
                  : () {
                      final slot =
                          widget.selectTime ? _slots[_selectedIndex!] : null;
                      Navigator.pop(
                        context,
                        _RescheduleRequest(
                          appointmentTime:
                              slot == null ? null : _apiValue(slot),
                          reason: _reason,
                        ),
                      );
                    },
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              child: Text(widget.selectTime ? '确认新时间' : '发送改期申请'),
            ),
          ),
        ],
      ),
    );
  }
}
