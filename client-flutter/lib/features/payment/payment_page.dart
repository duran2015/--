import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_client.dart';
import '../../core/router/route_paths.dart';
import '../../core/theme/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_loading_hud.dart';
import '../../core/widgets/app_nav_bar.dart';
import '../../core/widgets/app_states.dart';
import '../../core/widgets/app_toast.dart';
import '../../utils/load_image.dart';
import '../order/order_api.dart';
import '../order/appointment_policy.dart';
import '../order/widgets/order_widgets.dart';
import 'payment_api.dart';
import 'payment_view_model.dart';

/// 支付页（路由 /payment）。
/// iOS 参照：XYAIModule/XYAIModule/Classes/ViewController/
/// XYPaymentViewController.swift（Figma 0:979「确认订单」）——
/// 倒计时条（#FF6257/#FFF3F2）+ 订单信息卡 + 支付方式选择（默认支付宝）
/// + 底部实付款（24 bold）与「立即支付」青渐变按钮（182×45）。
///
/// 支付倒计时基于服务器时间（ApiClient.serverNow，对应 iOS XYServerTimeMonitor）。
class PaymentPage extends ConsumerStatefulWidget {
  const PaymentPage({super.key, required this.args});

  final PaymentPageArgs args;

  @override
  ConsumerState<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends ConsumerState<PaymentPage> {
  late PaymentPageArgs _args;
  PaymentViewModel? _vm;
  Timer? _countdownTimer;
  bool _paying = false;
  bool _didShowException = false;
  bool _policyAccepted = false;

  @override
  void initState() {
    super.initState();
    _args = widget.args;
    if (_args.needsOrderLookup) {
      _lookupOrder();
    } else {
      _buildViewModel();
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  /// 预约下单入口仅有 orderId：回查 my-list 补齐展示数据
  /// （无独立订单详情接口，契约 §2；iOS 由上一页直传完整 ViewModel）。
  Future<void> _lookupOrder() async {
    try {
      final item =
          await ref.read(orderApiProvider).findOrderById(_args.orderId);
      if (!mounted) return;
      if (item != null) {
        _args = PaymentPageArgs.fromOrder(item);
      }
      _buildViewModel();
    } catch (_) {
      if (!mounted) return;
      _buildViewModel(); // 兜底：仅订单号 + 金额，仍可支付
    }
  }

  void _buildViewModel() {
    setState(() {
      // 倒计时时钟：服务器时间（iOS 参照：XYServerTime.now）
      _vm = PaymentViewModel(
        args: _args,
        gateway: ref.read(paymentApiProvider),
        clock: () => ref.read(apiClientProvider).serverNow(),
      );
    });
    _startCountdown();
  }

  /// 仅当订单带支付截止时间时启动每秒倒计时；归零跳订单异常页。
  /// iOS 参照：XYPaymentViewController.startCountdown / tickCountdown。
  void _startCountdown() {
    _countdownTimer?.cancel();
    final vm = _vm;
    if (vm == null || !vm.hasPaymentDeadline) return;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (vm.countdown.tick()) {
        setState(() {});
      } else {
        setState(() {});
        _showException();
      }
    });
  }

  /// 订单超时/失败后跳转异常页（仅一次）；返回时重置标记。
  /// iOS 参照：showOrderExceptionIfNeeded + viewWillAppear 重置。
  Future<void> _showException() async {
    if (_didShowException) return;
    _didShowException = true;
    _countdownTimer?.cancel();
    await context.push(RoutePaths.paymentException);
    // 异常页「重新支付」返回：重置标记并恢复倒计时
    // （iOS 参照：XYOrderExceptionViewController.retryPaymentTapped → restartCountdown）
    _didShowException = false;
    _startCountdown();
  }

  /// 立即支付：create → mock-success → 成功跳支付成功页，失败/超时跳异常页。
  /// iOS 参照：XYPaymentViewController.payTapped。
  Future<void> _pay() async {
    final vm = _vm;
    if (vm == null || _paying) return;
    if (!_policyAccepted) {
      AppToast.show(context, '请先阅读并同意预约与取消规则');
      return;
    }
    if (vm.isExpired) {
      await _showException();
      return;
    }
    setState(() => _paying = true);
    try {
      await vm.pay();
      if (!mounted) return;
      _countdownTimer?.cancel();
      // iOS 参照：XYPaymentSuccessViewController(payment:)
      //（imUserId/avatar 供成功页「填写咨询前问卷」提交后跳转聊天）
      final params = <String, String>{
        'name': _args.counselorName,
        'time': _args.time,
        'orderId': _args.orderId,
        if (_args.counselorIMUserID.isNotEmpty)
          'imUserId': _args.counselorIMUserID,
        if (_args.counselorAvatar != null && _args.counselorAvatar!.isNotEmpty)
          'avatar': _args.counselorAvatar!,
      };
      await context.push(
        Uri(path: RoutePaths.paymentSuccess, queryParameters: params)
            .toString(),
      );
      if (mounted) context.pop(true); // 支付成功后离开支付页，通知上一页刷新
    } on PaymentFlowException catch (e) {
      if (!mounted) return;
      setState(() => _paying = false);
      if (e.isConfirming) {
        // 「支付结果确认中」：用户已扣款但本地确认未完成，订单列表最终状态兜底；
        // 禁止进入「重新支付」异常页（重复支付会违背服务端订单级幂等设计）
        await _showConfirmingNotice();
        return;
      }
      await _showException();
    } catch (_) {
      if (!mounted) return;
      setState(() => _paying = false);
      await _showException();
    }
  }

  /// 「支付结果确认中」提示：确认对话框引导去订单列表查询，
  /// 确定后离开支付页（iOS 参照：订单列表兜底刷新，不走重新支付）。
  Future<void> _showConfirmingNotice() async {
    // 弹确认对话框引导去订单列表查询；两个按钮均关闭对话框
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('支付结果确认中'),
        content: const Text('支付已受理，结果稍后确认，请前往订单列表查看最终状态。'),
        actions: [
          TextButton(
            onPressed: () => dialogContext.pop(false),
            child: const Text('返回'),
          ),
          TextButton(
            onPressed: () => dialogContext.pop(true),
            child: const Text('去订单列表'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    // 去订单列表 / 返回均离开支付页（返回时订单列表刷新兜底）
    context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.pageBackground,
          bottomNavigationBar: _buildBottomBar(),
          // 导航栏内嵌 body 顶部 + SafeArea（参照 06/07/10 页写法）
          body: SafeArea(
            child: Column(
              children: [
                const AppNavBar(title: '确认订单', transparent: true),
                Expanded(
                  child: _vm == null
                      ? const AppLoadingView()
                      : SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(0, 10, 0, 16),
                          child: Column(
                            children: [
                              if (_vm!.hasPaymentDeadline) _countdownBanner(),
                              const SizedBox(height: 10),
                              _orderInfoCard(),
                              const SizedBox(height: 10),
                              _policyCard(),
                              const SizedBox(height: 10),
                              _paymentMethodCard(),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
        if (_paying)
          const Positioned.fill(
            child: AppLoadingHud(message: '支付中'),
          ),
      ],
    );
  }

  Widget _policyCard() {
    const policy = AppointmentPolicy.current;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimens.cardRadius),
        border: Border.all(color: const Color(0xFFECE6DC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.policy_outlined,
                  size: 18, color: Color(0xFF6750A4)),
              const SizedBox(width: 8),
              Text('预约与取消规则', style: AppTextStyles.titleSmall),
            ],
          ),
          const SizedBox(height: 10),
          for (final line in policy.userFacingLines) ...[
            Text('• $line',
                style: AppTextStyles.label.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.45,
                )),
            const SizedBox(height: 4),
          ],
          const Divider(height: 18),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _policyAccepted = !_policyAccepted),
            child: Row(
              children: [
                Checkbox(
                  value: _policyAccepted,
                  onChanged: (value) =>
                      setState(() => _policyAccepted = value ?? false),
                ),
                const Expanded(
                  child: Text('我已阅读并同意上述预约、改期与取消规则'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 支付剩余时间倒计时条（36 高、#FFF3F2 底、#FF6257 13 medium 居中）。
  /// iOS 参照：setupCountdownSection。
  Widget _countdownBanner() {
    return Container(
      height: 36,
      margin: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: AppColors.countdownBg,
        borderRadius: BorderRadius.circular(AppDimens.cardRadius),
      ),
      alignment: Alignment.center,
      child: Text(
        '支付剩余时间 ${_vm!.countdownText}',
        style: AppTextStyles.body.copyWith(
          fontWeight: FontWeight.w500,
          color: AppColors.countdownText,
        ),
      ),
    );
  }

  /// 订单信息卡：咨询师头部（头像 72 + 姓名/胶囊 + 标签 + 职称）
  /// + 分隔线 + 咨询方式/预约时间（青）/支持时长。
  /// iOS 参照：setupOrderInfoSection。
  Widget _orderInfoCard() {
    final args = _args;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimens.cardRadius),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OrderAvatar(
                  url: args.counselorAvatar,
                  name: args.counselorName,
                  seed: args.counselorName,
                  size: 72,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              args.counselorName,
                              style: AppTextStyles.titleSmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (args.serviceHoursText.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            OrderServicePill(text: args.serviceHoursText),
                          ],
                        ],
                      ),
                      if (args.specialtyTags.isNotEmpty ||
                          args.styleTags.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        OrderTagFlow(
                          specialtyTags: args.specialtyTags,
                          styleTags: args.styleTags,
                        ),
                      ],
                      if (args.counselorTitle.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          args.counselorTitle,
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 15),
            child: Divider(
              height: 0.5,
              thickness: 0.5,
              color: AppColors.dividerDark,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              children: [
                _infoRow('咨询方式', args.method, highlight: false),
                const SizedBox(height: 12),
                _infoRow('预约时间', args.time, highlight: true),
                const SizedBox(height: 12),
                _infoRow('支持时长', args.duration, highlight: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 订单详情键值对行（key 13 #666 / value 13 semibold；预约时间值青色高亮）。
  /// iOS 参照：makeInfoRow（高 20）。
  Widget _infoRow(String key, String value, {required bool highlight}) {
    return SizedBox(
      height: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(key, style: AppTextStyles.body),
          Flexible(
            child: Text(
              value,
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w600,
                color: highlight ? AppColors.brandTeal : AppColors.textPrimary,
              ),
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// 支付方式选择卡：仅展示已接入的支付方式。
  /// 微信支付已接入（后端 wechatpay-java APIv3 + 客户端 fluwx 调起），
  /// 展示微信支付选项；selectedMethod 默认支付宝。
  Widget _paymentMethodCard() {
    final vm = _vm!;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimens.cardRadius),
      ),
      child: Column(
        children: [
          _paymentRow(
            icon: AppAssets.icPaymentAlipay,
            title: '支付宝',
            selected: vm.selectedMethod == PaymentMethod.alipay,
            onTap: () => setState(() => vm.selectMethod(PaymentMethod.alipay)),
          ),
          _paymentRow(
            icon: AppAssets.icPaymentWechat,
            title: '微信支付',
            selected: vm.selectedMethod == PaymentMethod.wechat,
            onTap: () => setState(() => vm.selectMethod(PaymentMethod.wechat)),
          ),
        ],
      ),
    );
  }

  /// 单条支付方式行（图标 24 + 名称 14 + 右侧勾选 20）。
  /// iOS 参照：makePaymentRow。
  Widget _paymentRow({
    required String icon,
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        height: 54,
        child: Row(
          children: [
            const SizedBox(width: 15),
            LoadImage(icon, width: 24, height: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            LoadImage(
              selected ? AppAssets.icPaymentCheck : AppAssets.icPaymentUncheck,
              width: 20,
              height: 20,
            ),
            const SizedBox(width: 15),
          ],
        ),
      ),
    );
  }

  /// 底部栏：实付款（¥16 bold + 数字 24 bold 红色）+ 「立即支付」
  /// 青渐变按钮（182×45，圆角 22.5，16 semibold）。
  /// iOS 参照：setupBottomArea / makeBottomPriceText。
  Widget? _buildBottomBar() {
    if (_vm == null) return null;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        boxShadow: [
          BoxShadow(
            color: AppColors.divider.withValues(alpha: 0.4),
            offset: const Offset(0, -4),
            blurRadius: 4,
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(15, 12, 15, 12 + bottomInset),
      child: Row(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '实付款',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text.rich(
                    TextSpan(children: [
                      TextSpan(
                        text: '¥',
                        style: AppTextStyles.title.copyWith(
                          color: AppColors.priceRed,
                        ),
                      ),
                      TextSpan(
                        text: _args.priceText,
                        style: AppTextStyles.price.copyWith(
                          color: AppColors.priceRed,
                        ),
                      ),
                    ]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _paying ? null : _pay,
            child: Container(
              width: 182,
              height: 45,
              decoration: BoxDecoration(
                gradient: _policyAccepted ? AppColors.brandGradient : null,
                color: _policyAccepted ? null : AppColors.innerBackground,
                borderRadius: BorderRadius.circular(22.5),
              ),
              alignment: Alignment.center,
              child: Text(
                '立即支付',
                style: AppTextStyles.title.copyWith(
                  color:
                      _policyAccepted ? Colors.white : AppColors.textTertiary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
