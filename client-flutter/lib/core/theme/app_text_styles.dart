import 'package:flutter/material.dart';

import 'app_colors.dart';

/// 设计 token：字号体系。
/// 来源：xinyuiOS UIFont.systemFont 使用统计（Figma÷2 后 pt 值）。
/// 字重惯例：标题/强调 semibold(w600)，正文 regular(w400)，价格 bold(w700)。
class AppTextStyles {
  AppTextStyles._();

  static const String? _fontFamily = null; // 系统字体（iOS SF Pro / Android Roboto）

  // ---------- 大字号 ----------
  /// 28 semibold：预约详情顶部时段
  static const TextStyle displayLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    fontFamily: _fontFamily,
  );

  /// 24 bold：底部价格、异常页标题
  static const TextStyle price = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    fontFamily: _fontFamily,
  );

  /// 20 semibold：区块大标题、订单时间、状态
  static const TextStyle titleXLarge = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    fontFamily: _fontFamily,
  );

  /// 18 semibold：区块标题、姓名
  static const TextStyle titleLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    fontFamily: _fontFamily,
  );

  /// 17 semibold：导航级标题、列表主标题
  static const TextStyle titleMedium = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    fontFamily: _fontFamily,
  );

  // ---------- 主力标题 ----------
  /// 16 semibold：页面/卡片标题主力字号；主按钮文字
  static const TextStyle title = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    fontFamily: _fontFamily,
  );

  /// 15 semibold：卡片标题（Figma 30→15）
  static const TextStyle titleSmall = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    fontFamily: _fontFamily,
  );

  // ---------- 正文 ----------
  /// 14 regular：正文偏强
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    fontFamily: _fontFamily,
  );

  /// 14 semibold
  static const TextStyle bodyLargeStrong = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    fontFamily: _fontFamily,
  );

  /// 13 regular：正文（Figma 26→13）
  static const TextStyle body = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    fontFamily: _fontFamily,
  );

  // ---------- 辅助 ----------
  /// 12 regular：最高频辅助文字/标签（Figma 24→12）
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textTertiary,
    fontFamily: _fontFamily,
  );

  /// 11 regular：小标签、TabBar 标题
  static const TextStyle label = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.textTertiary,
    fontFamily: _fontFamily,
  );

  /// 24 semibold：验证码数字
  /// iOS 参照：XYVerificationCodeViewController codeDigitFontSize 24 semibold
  static const TextStyle codeDigit = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    fontFamily: _fontFamily,
  );

  /// 10 regular：徽标/角标
  static const TextStyle badge = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w400,
    color: Colors.white,
    fontFamily: _fontFamily,
  );

  /// 9 semibold：极小徽标
  static const TextStyle badgeSmall = TextStyle(
    fontSize: 9,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    fontFamily: _fontFamily,
  );
}
