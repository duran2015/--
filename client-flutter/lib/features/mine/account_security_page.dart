import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/network/api_response.dart';
import '../../core/platform/consultant_portal_launcher.dart';
import '../../core/router/route_paths.dart';
import '../../core/theme/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_background.dart';
import '../../core/widgets/app_dialog.dart';
import '../../core/widgets/app_nav_bar.dart';
import '../../core/widgets/app_toast.dart';
import '../../utils/load_image.dart';
import '../auth/auth_view_model.dart';

/// 账号与安全页（路由 /mine/security，深链 9006；用户端 / 咨询师端共用）。
/// iOS 参照：XYMineModule/.../XYAccountSecurityViewController.swift——
/// - 用户端：标题「账号与安全」，仅退出登录 / 注销账号（Figma 1205:3323）
/// - 咨询师端：标题「账号设置与反馈」，下方另增意见反馈卡片（Figma 1547:2808）
class AccountSecurityPage extends ConsumerWidget {
  const AccountSecurityPage({super.key});

  /// 行高（iOS rowHeight / feedbackRowHeight 50；历史实现 49.5，保持一致）
  static const double _rowHeight = 49.5;

  /// 行图标尺寸（iOS iconSize，Figma 40px → 20）
  static const double _iconSize = 20;

  /// 卡片距导航栏顶部（iOS cardTopInset 20）
  static const double _cardTopInset = 20;

  /// 咨询师端两卡片间距（iOS cardSpacing，Figma 20px → 10）
  static const double _cardSpacing = 10;

  /// 退出登录点击：弹确认框后执行登出。
  /// iOS 参照：logoutTapped + XYAccountSecurityViewModel.logout——
  /// 服务端登出 fire-and-forget；立即清登录态（IM 登出经
  /// AuthController.onImLogout 钩子后台执行）；路由监听登录态自动回 /login。
  Future<void> _logoutTapped(BuildContext context, WidgetRef ref) async {
    final confirmed = await AppCenterDialog.show(
      context,
      title: '提示',
      content: '确定要退出登录吗？',
      cancelText: '取消',
      confirmText: '确定',
    );
    if (confirmed != true) return;
    // 服务端登出：在清 token 前发起请求（fire-and-forget，失败不提示）
    unawaited(
      ref.read(authApiProvider).logout().catchError((_) => ''),
    );
    // 立即清登录态 → 路由 redirect 自动回 /login（不等待接口/存储）
    unawaited(ref.read(authControllerProvider.notifier).logout());
  }

  /// 注销账号点击：跳转到注销账号页面。
  /// iOS 参照：cancelAccountTapped（push XYCancelAccountViewController）。
  void _cancelAccountTapped(BuildContext context) {
    context.push(RoutePaths.mineCancelAccount);
  }

  /// 意见反馈点击：跳转与用户端相同的反馈页（route 9007）。
  /// iOS 参照：feedbackTapped。
  void _feedbackTapped(BuildContext context) {
    context.push(RoutePaths.mineFeedback);
  }

  /// Debug：黑名单管理入口。
  void _blacklistTapped(BuildContext context) {
    context.push(RoutePaths.mineBlacklist);
  }

  /// 用户端切换为咨询师端：复用登录时的身份选择接口与最近身份记录。
  Future<void> _switchIdentityTapped(
      BuildContext context, WidgetRef ref) async {
    final confirmed = await AppCenterDialog.show(
      context,
      title: '切换身份',
      content: '确认切换为咨询师端吗？',
      cancelText: '取消',
      confirmText: '切换',
    );
    if (confirmed != true || !context.mounted) return;
    try {
      final route = await ref
          .read(authViewModelProvider.notifier)
          .selectIdentity('consultant');
      if (context.mounted) navigateOrOpenPortal(context, route);
    } on ApiException catch (error) {
      if (context.mounted) AppToast.show(context, error.msg);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 咨询师端：标题与意见反馈卡片（iOS role == .counselor）
    final isCounselor =
        ref.watch(accountProvider)?.currentIdentity == 'consultant';

    return Scaffold(
      // iOS：F1F4FB 底 + XYOrderBackgroundView + 透明导航栏（gk_navLineHidden）
      body: AppPageBackground(
        child: SafeArea(
          child: Column(
            children: [
              AppNavBar(
                title: isCounselor ? '账号设置与反馈' : '账号与安全',
                transparent: true,
                lineHidden: true,
              ),
              Padding(
                padding: const EdgeInsets.only(
                  top: _cardTopInset,
                  left: AppDimens.screenPadding,
                  right: AppDimens.screenPadding,
                ),
                child: Column(
                  children: [
                    // 退出登录 / 注销账号
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppDimens.cardRadius),
                      child: Container(
                        color: AppColors.cardBackground,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!isCounselor) ...[
                              _SecurityRow(
                                iconAsset: AppAssets.mineSwitch,
                                title: '切换为咨询师端',
                                subtitle: '保留当前账号，进入咨询师工作台',
                                titleColor: AppColors.textPrimary,
                                onTap: () =>
                                    _switchIdentityTapped(context, ref),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: AppDimens.gap16,
                                ),
                                child: Divider(
                                  height: 0.5,
                                  thickness: 0.5,
                                  color: AppColors.divider,
                                ),
                              ),
                            ],
                            _SecurityRow(
                              iconAsset: AppAssets.mineLogout,
                              title: '退出登录',
                              subtitle: '退出当前账号并返回登录页',
                              titleColor: AppColors.textPrimary,
                              onTap: () => _logoutTapped(context, ref),
                            ),
                            // 分隔线 0.5 #EEEEEE 左右各 16
                            const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: AppDimens.gap16,
                              ),
                              child: Divider(
                                height: 0.5,
                                thickness: 0.5,
                                color: AppColors.divider,
                              ),
                            ),
                            _SecurityRow(
                              iconAsset: AppAssets.mineCancelAccount,
                              title: '注销账号',
                              subtitle: '提交账号注销申请',
                              titleColor: AppColors.priceRed,
                              onTap: () => _cancelAccountTapped(context),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // 咨询师端：下方意见反馈独立白卡片
                    if (isCounselor) ...[
                      const SizedBox(height: _cardSpacing),
                      ClipRRect(
                        borderRadius:
                            BorderRadius.circular(AppDimens.cardRadius),
                        child: Container(
                          color: AppColors.cardBackground,
                          child: _SecurityRow(
                            iconAsset: AppAssets.mineFeedback,
                            title: '意见反馈',
                            titleColor: AppColors.textPrimary,
                            onTap: () => _feedbackTapped(context),
                          ),
                        ),
                      ),
                    ],
                    // Debug：黑名单管理（用户端「账号与安全」/ 咨询师端「账号设置与反馈」共用）
                    if (kDebugMode) ...[
                      const SizedBox(height: _cardSpacing),
                      ClipRRect(
                        borderRadius:
                            BorderRadius.circular(AppDimens.cardRadius),
                        child: Container(
                          color: AppColors.cardBackground,
                          child: _SecurityRow(
                            leadingIcon: Icons.block_outlined,
                            title: '黑名单管理',
                            titleColor: AppColors.textPrimary,
                            onTap: () => _blacklistTapped(context),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 账号与安全操作行：图标 20 左 16 + 标题 15 + 右箭头 12 右 16。
/// iOS 参照：XYAccountSecurityViewController.makeRow。
class _SecurityRow extends StatelessWidget {
  const _SecurityRow({
    this.iconAsset,
    this.leadingIcon,
    required this.title,
    this.subtitle,
    required this.titleColor,
    required this.onTap,
  }) : assert(iconAsset != null || leadingIcon != null);

  final String? iconAsset;
  final IconData? leadingIcon;
  final String title;
  final String? subtitle;
  final Color titleColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        height: subtitle == null ? AccountSecurityPage._rowHeight : 64,
        child: Row(
          children: [
            const SizedBox(width: AppDimens.gap16),
            if (iconAsset != null)
              LoadImage(
                iconAsset!,
                width: AccountSecurityPage._iconSize,
                height: AccountSecurityPage._iconSize,
                fit: BoxFit.contain,
              )
            else
              Icon(
                leadingIcon,
                size: AccountSecurityPage._iconSize,
                color: AppColors.textPrimary,
              ),
            const SizedBox(width: AppDimens.gap12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.w500,
                      color: titleColor,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: AppDimens.gap4),
                    Text(
                      subtitle!,
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
            LoadImage(
              AppAssets.mineArrowRight,
              width: 12,
              height: 12,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: AppDimens.gap16),
          ],
        ),
      ),
    );
  }
}
