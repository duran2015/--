import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';

/// 注释：通用导航栏（全屏幕 ScreenUtil 响应式规范）
/// 时间：2026/8/4
/// 作者：郭翰林
class AppNavBar extends StatelessWidget implements PreferredSizeWidget {
  const AppNavBar({
    super.key,
    required this.title,
    this.showBack = true,
    this.onBack,
    this.actions,
    this.transparent = false,
    this.lineHidden = false,
  });

  final String title;
  final bool showBack;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final bool transparent;
  final bool lineHidden;

  static const double _navBarHeight = 44;
  static const double _dividerHeight = 0.5;

  @override
  Size get preferredSize => Size.fromHeight(_navBarHeight.h);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: transparent
          ? null
          : BoxDecoration(
              color: AppColors.cardBackground,
              border: lineHidden
                  ? null
                  : Border(
                      bottom: BorderSide(
                        color: AppColors.navDivider,
                        width: _dividerHeight.w,
                      ),
                    ),
            ),
      child: SizedBox(
        height: (_navBarHeight - _dividerHeight).h,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              left: 44.w,
              right: 44.w,
              child: Center(
                child: Text(
                  title,
                  style: AppTextStyles.titleMedium.copyWith(fontSize: 17.sp),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            Positioned(
              left: 0,
              child: showBack
                  ? GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onBack ?? () => Navigator.of(context).maybePop(),
                      child: SizedBox(
                        width: 44.w,
                        height: 44.h,
                        child: Center(
                          child: Icon(
                            Icons.arrow_back_ios_new,
                            size: 20.r,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    )
                  : SizedBox(width: 44.w),
            ),
            if (actions != null && actions!.isNotEmpty)
              Positioned(
                right: AppDimens.gap8.w,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: actions!,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
