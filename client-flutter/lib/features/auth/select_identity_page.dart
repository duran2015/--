import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_response.dart';
import '../../core/router/route_guards.dart';
import '../../core/theme/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_background.dart';
import '../../core/widgets/app_loading_hud.dart';
import '../../core/widgets/app_nav_bar.dart';
import '../../core/widgets/app_toast.dart';
import '../../utils/load_image.dart';
import 'auth_view_model.dart';

/// 注释：登录身份选择页（全屏幕 ScreenUtil 响应式规范）
/// 时间：2026/8/4
/// 作者：郭翰林
class SelectIdentityPage extends ConsumerStatefulWidget {
  const SelectIdentityPage({super.key});

  @override
  ConsumerState<SelectIdentityPage> createState() => _SelectIdentityPageState();
}

class _SelectIdentityPageState extends ConsumerState<SelectIdentityPage> {
  bool _submitting = false;

  Future<void> _onRoleTapped(String identity) async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      final route = await ref
          .read(authViewModelProvider.notifier)
          .selectIdentity(identity);
      if (!mounted) return;
      context.go(route);
    } on ApiException catch (e) {
      if (!mounted) return;
      AppToast.show(context, e.msg);
    } catch (_) {
      if (!mounted) return;
      AppToast.show(context, '网络异常，请稍后重试');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppPageBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppNavBar(title: '', transparent: true),
                  Padding(
                    padding: EdgeInsets.only(
                      top: AppDimens.gap16.h,
                      left: AppDimens.loginPadding.w,
                      right: AppDimens.loginPadding.w,
                    ),
                    child: Text(
                      '请选择您的身份',
                      style: AppTextStyles.titleXLarge.copyWith(fontSize: 20.sp),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                      top: AppDimens.gap8.h,
                      left: AppDimens.loginPadding.w,
                      right: AppDimens.loginPadding.w,
                    ),
                    child: Text(
                      '您拥有双重身份，请选择本次需要使用的身份',
                      style: AppTextStyles.body.copyWith(fontSize: 13.sp),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                      top: AppDimens.loginPadding.h,
                      left: AppDimens.loginPadding.w,
                      right: AppDimens.loginPadding.w,
                    ),
                    child: Column(
                      children: [
                        _RoleCard(
                          icon: AppAssets.loginRoleCounselor,
                          title: '我是咨询师',
                          desc: '处理订单、管理日程与服务',
                          onTap: () =>
                              _onRoleTapped(RouteGuards.identityConsultant),
                        ),
                        AppDimens.gap15.verticalSpace,
                        _RoleCard(
                          icon: AppAssets.loginRoleUser,
                          title: '我是用户',
                          desc: '寻找咨询师、体验AI服务',
                          onTap: () => _onRoleTapped(RouteGuards.identityUser),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_submitting)
                const Positioned.fill(
                  child: AppLoadingHud(message: '切换中'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatefulWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.desc,
    required this.onTap,
  });

  final String icon;
  final String title;
  final String desc;
  final VoidCallback onTap;

  static const double _pressedOpacity = 0.85;

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> {
  double _opacity = 1;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _opacity = _RoleCard._pressedOpacity),
      onTapUp: (_) => setState(() => _opacity = 1),
      onTapCancel: () => setState(() => _opacity = 1),
      child: AnimatedOpacity(
        opacity: _opacity,
        duration: const Duration(milliseconds: 150),
        child: Container(
          height: AppDimens.roleCardHeight.h,
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(AppDimens.cardRadius.r),
            border: Border.all(
              color: AppColors.navDivider,
              width: AppDimens.roleCardBorderWidth.w,
            ),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: AppDimens.cardPadding.w,
          ),
          child: Row(
            children: [
              LoadImage(
                widget.icon,
                width: AppDimens.roleIconSize.w,
                height: AppDimens.roleIconSize.w,
                fit: BoxFit.contain,
              ),
              AppDimens.gap8.horizontalSpace,
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: AppTextStyles.titleSmall.copyWith(fontSize: 15.sp),
                    ),
                    AppDimens.roleCardTextGap.verticalSpace,
                    Text(
                      widget.desc,
                      style: AppTextStyles.caption.copyWith(fontSize: 12.sp),
                    ),
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
