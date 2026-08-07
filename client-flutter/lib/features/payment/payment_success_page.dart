import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_response.dart';
import '../../core/router/route_paths.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_dialog.dart';
import '../../core/widgets/app_nav_bar.dart';
import '../../core/widgets/app_toast.dart';
import '../order/order_api.dart';

/// 支付成功页（路由 /payment/success?name=&time=&orderId=）。
/// iOS 参照：XYAIModule/XYAIModule/Classes/ViewController/
/// XYPaymentSuccessViewController.swift（Figma「支付成功-0715」1173:2859）——
/// 日历勾选图标 + 「预约成功」+ 提醒文案 + 预订信息卡（倾听师/预约时间）
/// + 主按钮「填写咨询前问卷」+ 次按钮「稍后填写并返回首页」+ 退单链接。
class PaymentSuccessPage extends ConsumerWidget {
  const PaymentSuccessPage({
    super.key,
    required this.counselorName,
    required this.appointmentTime,
    required this.orderId,
    this.counselorIMUserID = '',
    this.counselorAvatar,
  });

  final String counselorName;
  final String appointmentTime;
  final String orderId;

  /// 咨询师 IM 用户 ID（咨询前问卷提交成功后跳转聊天用，
  /// iOS XYPaymentSuccessViewModel.counselorIMUserID）
  final String counselorIMUserID;

  /// 咨询师头像 URL（iOS counselorAvatar）
  final String? counselorAvatar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopScope(
      canPop: false, // iOS 参照：disableNavigationBack
      child: Scaffold(
        backgroundColor: AppColors.pageBackground,
        // 导航栏内嵌 body 顶部 + SafeArea（参照 06/07/10 页写法）
        body: SafeArea(
          child: Column(
            children: [
              const AppNavBar(
                  title: '支付成功', showBack: false, transparent: true),
              Expanded(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Column(
                    children: [
                      const SizedBox(height: 30),
                      // 日历勾选图标（iOS ic_pay_success_check 为 svg，
                      // 工程未引入 svg 渲染，用 iOS fallbackSystemName
                      // "calendar.badge.checkmark" 等价 Icons 代替，tint #00A6A1）
                      const Icon(
                        Icons.event_available_outlined,
                        size: 32,
                        color: AppColors.brandTeal,
                      ),
                      const SizedBox(height: 10),
                      Text('预约成功', style: AppTextStyles.titleXLarge),
                      const SizedBox(height: 6),
                      // iOS 参照：XYPaymentSuccessViewModel.reminderText
                      Text(
                        '请提前 5 分钟进入咨询室准备',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _orderCard(),
                      const SizedBox(height: 12),
                      _sharingNotice(context),
                      const SizedBox(height: 33),
                      // 主按钮：填写咨询前问卷（青渐变 53 高胶囊，18 semibold）
                      // iOS 参照：questionnaireTapped → XYIntakeWebViewController
                      GestureDetector(
                        key: const Key('fill_questionnaire'),
                        onTap: () => _openQuestionnaire(context),
                        child: Container(
                          height: AppDimens.confirmButtonHeight,
                          decoration: BoxDecoration(
                            gradient: AppColors.brandGradient,
                            borderRadius: BorderRadius.circular(
                              AppDimens.confirmButtonRadius,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '填写咨询前问卷',
                            style: AppTextStyles.titleLarge.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // 次按钮：稍后填写并返回首页（15 semibold #999）
                      GestureDetector(
                        onTap: () => context.go(RoutePaths.home),
                        child: Container(
                          height: 45,
                          alignment: Alignment.center,
                          child: Text(
                            '稍后填写并返回首页',
                            style: AppTextStyles.titleSmall.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // 申请退单链接（12 #00A6A1）
                      GestureDetector(
                        onTap: () => _refund(context, ref),
                        child: Container(
                          height: 30,
                          alignment: Alignment.center,
                          child: Text(
                            '申请退单并取消预约',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.brandTeal,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 预订信息卡：标题（14 semibold #666）+ 倾听师/预约时间两行键值。
  /// iOS 参照：makeOrderCard / makeInfoRow。
  Widget _orderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(15, 20, 15, 20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimens.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '预订信息',
            style: AppTextStyles.bodyLargeStrong.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 18),
          _infoRow('倾听师', counselorName),
          const SizedBox(height: 12),
          _infoRow('预约时间', appointmentTime),
        ],
      ),
    );
  }

  Widget _sharingNotice(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .secondaryContainer
            .withValues(alpha: .58),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined,
              size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              '咨询前资料为选填。提交前会展示本次分享内容，仅提供给本次咨询师。',
              style: TextStyle(fontSize: 12, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            style: AppTextStyles.bodyLargeStrong,
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// 填写咨询前问卷：打开 H5 问卷容器（iOS questionnaireTapped；
  /// orderId 缺失 → Toast「订单号缺失，请稍后重试」）
  void _openQuestionnaire(BuildContext context) {
    if (orderId.isEmpty) {
      AppToast.show(context, '订单号缺失，请稍后重试');
      return;
    }
    context.push(
      Uri(path: RoutePaths.paymentIntake, queryParameters: {
        'orderId': orderId,
        if (counselorIMUserID.isNotEmpty) 'imUserId': counselorIMUserID,
        if (counselorName.isNotEmpty) 'name': counselorName,
        if (counselorAvatar != null && counselorAvatar!.isNotEmpty)
          'avatar': counselorAvatar!,
      }).toString(),
    );
  }

  /// 申请退单：确认弹窗 → /app/consultant/order/cancel → Toast + 返回首页。
  /// iOS 参照：refundTapped（XYCenterAlertView.showConfirm confirmDestructive）。
  Future<void> _refund(BuildContext context, WidgetRef ref) async {
    final confirmed = await AppCenterDialog.show(
      context,
      title: '申请退单',
      content: '确定要申请退单并取消本次预约吗？',
      cancelText: '再想想',
      confirmText: '确定退单',
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(orderApiProvider).cancelOrder(orderId);
      if (!context.mounted) return;
      AppToast.show(context, '取消预约成功');
      context.go(RoutePaths.home);
    } on ApiException catch (e) {
      if (!context.mounted) return;
      AppToast.show(context, e.msg.isEmpty ? '取消失败' : e.msg);
    } catch (_) {
      if (!context.mounted) return;
      AppToast.show(context, '取消失败');
    }
  }
}
