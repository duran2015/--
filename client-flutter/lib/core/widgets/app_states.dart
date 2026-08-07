import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';

/// 空态视图：图标 + 文案，居中展示。
/// iOS 参照：xinyuiOS 列表空态占位（MJRefresh 空数据态）。
class AppEmptyView extends StatelessWidget {
  const AppEmptyView({
    super.key,
    this.icon,
    this.message = '暂无数据',
    this.iconSize = 64,
  });

  /// 自定义图标（可为 Image/Icon），默认灰色占位图标
  final Widget? icon;

  final String message;

  /// 默认图标尺寸
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon ??
              Icon(
                Icons.inbox_outlined,
                size: iconSize,
                color: AppColors.placeholder,
              ),
          const SizedBox(height: AppDimens.gap12),
          Text(
            message,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

/// 加载视图：brandTeal 转圈，居中展示。
/// iOS 参照：xinyuiOS 页面加载中态（MBProgressHUD 风格）。
class AppLoadingView extends StatelessWidget {
  const AppLoadingView({super.key, this.size = 32});

  /// 转圈尺寸
  final double size;

  /// 转圈线宽
  static const double _strokeWidth = 3;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: const CircularProgressIndicator(
          strokeWidth: _strokeWidth,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.brandTeal),
        ),
      ),
    );
  }
}

/// 错误视图：错误文案 + 50 高重试按钮胶囊。
/// iOS 参照：xinyuiOS 网络异常页（重试按钮 50 高胶囊，按钮底 textDark）。
class AppErrorView extends StatelessWidget {
  const AppErrorView({
    super.key,
    this.message = '加载失败，请稍后重试',
    this.retryText = '重新加载',
    this.onRetry,
  });

  final String message;
  final String retryText;
  final VoidCallback? onRetry;

  /// 重试按钮宽度
  static const double _retryButtonWidth = 160;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            style: AppTextStyles.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimens.gap16),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              width: _retryButtonWidth,
              height: AppDimens.retryButtonHeight,
              decoration: BoxDecoration(
                color: AppColors.textDark,
                borderRadius:
                    BorderRadius.circular(AppDimens.retryButtonHeight / 2),
              ),
              alignment: Alignment.center,
              child: Text(
                retryText,
                style: AppTextStyles.titleSmall.copyWith(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
