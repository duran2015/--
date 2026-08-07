import 'package:flutter/material.dart';

import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';
import 'app_nav_bar.dart';

/// 通用占位页：功能未实现页面的统一落地。
///
/// 契约来源：contracts/route_code_contract.md §0「未知 code 提示『功能开发中』」。
/// 深链路由层将未实现的功能页统一落到这里；1006 咨询室等桥接页
/// 通过 [params] 打印透传参数，便于阶段 8 联调核对。
class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({
    super.key,
    required this.title,
    this.params,
    this.showBack = true,
  });

  /// 页面标题（导航栏 + 居中展示）
  final String title;

  /// 深链透传参数（可选；非空时 debugPrint，便于桥接联调）
  final Map<String, String>? params;

  /// 是否显示返回箭头（Tab 根页面占位时传 false）
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    if (params != null && params!.isNotEmpty) {
      // 阶段 8 桥接联调用：打印透传参数（如 1006 咨询室全参数）
      debugPrint('[PlaceholderPage] $title params=$params');
    }
    return Scaffold(
      // 导航栏内嵌 body 顶部 + SafeArea（参照 06/07/10 页写法）
      body: SafeArea(
        child: Column(
          children: [
            AppNavBar(title: title, showBack: showBack),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: AppTextStyles.titleMedium),
                    const SizedBox(height: AppDimens.gap8),
                    const Text('功能开发中', style: AppTextStyles.caption),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
