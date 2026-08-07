import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/route_paths.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_nav_bar.dart';

/// 订单异常页（路由 /payment/exception；支付超时/失败进入）。
/// iOS 参照：XYAIModule/XYAIModule/Classes/ViewController/
/// XYOrderExceptionViewController.swift——
/// 双层圆形错误叉号 + 「支付异常」24 semibold #1A1A2E + 说明文案
/// + 「重新支付」#1A1A2E 50 高胶囊 + 「放弃订单并返回」。
class OrderExceptionPage extends StatelessWidget {
  const OrderExceptionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // iOS 参照：disableNavigationBack
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        // 导航栏内嵌 body 顶部 + SafeArea（参照 06/07/10 页写法）
        body: SafeArea(
          child: Column(
            children: [
              const AppNavBar(title: '订单异常', showBack: false),
              Expanded(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.16),
                      _errorIcon(),
                      const SizedBox(height: 28),
                      Text(
                        '支付异常',
                        style: AppTextStyles.price.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '订单支付未完成或已超时，请重新核对信息后再试。\n若已扣款，系统将在24小时内原路退回。',
                        style: AppTextStyles.titleSmall.copyWith(
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 48),
                      // 重新支付（#1A1A2E 底、50 高、圆角 25、17 semibold 白字）
                      GestureDetector(
                        // iOS 参照：retryPaymentTapped → 返回支付页并重置倒计时
                        onTap: () => context.pop(),
                        child: Container(
                          width: double.infinity,
                          height: AppDimens.retryButtonHeight,
                          decoration: BoxDecoration(
                            color: AppColors.textDark,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '重新支付',
                            style: AppTextStyles.titleMedium.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // 放弃订单并返回（17 medium #1A1A2E）
                      GestureDetector(
                        // iOS 参照：abandonOrderTapped → popToRootViewController
                        onTap: () => context.go(RoutePaths.home),
                        child: Container(
                          height: 44,
                          alignment: Alignment.center,
                          child: Text(
                            '放弃订单并返回',
                            style: AppTextStyles.titleMedium.copyWith(
                              fontWeight: FontWeight.w500,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
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

  /// 双层圆形错误叉号图标（外圈 120 #FDECEC / 内圈 72 白 / 红叉 #FF3B30）。
  /// iOS 参照：makeErrorIcon。
  Widget _errorIcon() {
    return Container(
      width: 120,
      height: 120,
      decoration: const BoxDecoration(
        color: AppColors.exceptionIconBg,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Container(
        width: 72,
        height: 72,
        decoration: const BoxDecoration(
          color: AppColors.cardBackground,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.close,
          size: 32,
          color: AppColors.badgeRed,
        ),
      ),
    );
  }
}
