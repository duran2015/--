import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:xinyu_flutter/defines/constants.dart';
import 'package:xinyu_flutter/utils/ly_utils.dart';

import '../../core/router/route_paths.dart';
import '../../core/theme/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_background.dart';
import '../../core/widgets/app_nav_bar.dart';
import '../../utils/load_image.dart';

/// 注释：关于我们页面（路由 /mine/about）。
/// 时间：2026/8/4 10:50
/// 作者：郭翰林
class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  /// 版本号文字（与 pubspec.yaml version 保持一致）
  late String _versionText = '版本V1.0.0';

  /// 用户协议 URL
  static const String _userAgreementUrl = LyConfig.userAgreement;

  /// 隐私政策 URL
  static const String _privacyPolicyUrl = LyConfig.privacyPolicy;

  /// Logo 尺寸（Figma 164px → 82pt）
  static const double _logoSize = 82;

  /// Logo 距导航栏下方间距（Figma 78px → 39pt）
  static const double _logoTopSpacing = 39;

  /// App 名称距 Logo 底部间距（Figma 32px → 16pt）
  static const double _nameTopSpacing = 16;

  /// 版本号距名称底部间距（Figma 20px → 10pt）
  static const double _versionTopSpacing = 10;

  /// 协议卡片距版本号间距（Figma 72px → 36pt）
  static const double _cardTopSpacing = 36;

  /// 协议行高度（Figma 99px → 49.5pt）
  static const double _protocolRowHeight = 49.5;

  /// 右侧箭头图标尺寸（Figma 24px → 12pt）
  static const double _arrowSize = 12;

  /// 公司简介卡片距协议卡片间距（Figma 20px → 10pt）
  static const double _companyCardTopSpacing = 10;

  @override
  void initState() {
    super.initState();
    LyUtils.getAppVersion().then((e) {
      setState(() {
        _versionText = '版本V$e';
      });
    });
  }

  /// 注释：跳转用户协议
  /// 时间：2026/8/4 10:50
  /// 作者：郭翰林
  void _onUserAgreementTapped() {
    context.push(
      '${RoutePaths.webview}?url=${Uri.encodeComponent(_userAgreementUrl)}&title=${Uri.encodeComponent('用户协议')}',
    );
  }

  /// 注释：跳转隐私政策
  /// 时间：2026/8/4 10:50
  /// 作者：郭翰林
  void _onPrivacyPolicyTapped() {
    context.push(
      '${RoutePaths.webview}?url=${Uri.encodeComponent(_privacyPolicyUrl)}&title=${Uri.encodeComponent('隐私政策')}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppPageBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const AppNavBar(
                title: '关于我们',
                transparent: true,
                lineHidden: true,
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      // ─── Logo + 名称 + 版本号 ───
                      renderLogoSection(),
                      // ─── 协议卡片 ───
                      renderProtocolCard(),
                      // ─── 公司简介卡片 ───
                      renderCompanyCard(),
                      // ─── 底部版权信息 ───
                      renderCopyright(),
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

  /// 注释：绘制 Logo、名称、版本号区域
  /// 时间：2026/8/4 10:50
  /// 作者：郭翰林
  Widget renderLogoSection() {
    return Column(
      children: [
        _logoTopSpacing.verticalSpace,
        // Logo（82×82 圆形）
        ClipRRect(
          borderRadius: BorderRadius.circular(AppDimens.gap16),
          child: LoadImage(
            AppAssets.homeMascot,
            width: _logoSize,
            height: _logoSize,
            fit: BoxFit.cover,
          ),
        ),
        _nameTopSpacing.verticalSpace,
        // App 名称
        Text(
          '可鹿心理',
          style: AppTextStyles.titleXLarge,
        ),
        SizedBox(height: _versionTopSpacing),
        // 版本号
        Text(
          _versionText,
          style: AppTextStyles.body.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  /// 注释：绘制协议卡片（用户协议 + 隐私政策）
  /// 时间：2026/8/4 10:50
  /// 作者：郭翰林
  Widget renderProtocolCard() {
    return Padding(
      padding: const EdgeInsets.only(
        top: _cardTopSpacing,
        left: AppDimens.screenPadding,
        right: AppDimens.screenPadding,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimens.cardRadius),
        child: Container(
          color: AppColors.cardBackground,
          child: Column(
            children: [
              // 用户协议行
              _ProtocolRow(
                title: '用户协议',
                showSeparator: true,
                onTap: _onUserAgreementTapped,
              ),
              // 隐私政策行
              _ProtocolRow(
                title: '隐私政策',
                showSeparator: false,
                onTap: _onPrivacyPolicyTapped,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 注释：绘制公司简介卡片
  /// 时间：2026/8/4 10:50
  /// 作者：郭翰林
  Widget renderCompanyCard() {
    return Padding(
      padding: const EdgeInsets.only(
        top: _companyCardTopSpacing,
        left: AppDimens.screenPadding,
        right: AppDimens.screenPadding,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimens.cardRadius),
        child: Container(
          width: double.infinity,
          color: AppColors.cardBackground,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.screenPadding,
            vertical: 18,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 公司简介标题（Figma 30px → 15pt，#222222）
              Text(
                '公司简介',
                style: AppTextStyles.titleSmall,
              ),
              const SizedBox(height: 10),
              // 公司简介描述（Figma 28px → 14pt，#666666，行高 22pt）
              Text(
                '可鹿心理致力于为用户提供专业、温暖的泛心理支持服务。'
                '通过AI情绪陪伴与专业心理咨询师的结合，'
                '帮助每一位用户找到适合自己的心理支持路径。',
                style: AppTextStyles.body.copyWith(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.57,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 注释：绘制底部版权信息
  /// 时间：2026/8/4 10:50
  /// 作者：郭翰林
  Widget renderCopyright() {
    return Padding(
      padding: const EdgeInsets.only(
        top: 40,
        left: AppDimens.screenPadding,
        right: AppDimens.screenPadding,
        bottom: 32,
      ),
      child: SizedBox(
        width: double.infinity,
        child: Text(
          '南京心愈人工智能科技有限公司 版权所有\n'
          '备案号:苏ICP备2026043627号-2A\n'
          '客服电话:13851447607',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: AppColors.textTertiary,
            height: 1.64,
          ),
        ),
      ),
    );
  }
}

/// 注释：协议行组件（用户协议/隐私政策）
/// 时间：2026/8/4 10:50
/// 作者：郭翰林
class _ProtocolRow extends StatefulWidget {
  const _ProtocolRow({
    required this.title,
    required this.showSeparator,
    required this.onTap,
  });

  final String title;
  final bool showSeparator;
  final VoidCallback onTap;

  @override
  State<_ProtocolRow> createState() => _ProtocolRowState();
}

class _ProtocolRowState extends State<_ProtocolRow> {
  /// 按下高亮
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: Container(
        height: _AboutPageState._protocolRowHeight,
        color: _pressed ? const Color(0xFFF7F7F7) : AppColors.cardBackground,
        child: Stack(
          children: [
            Positioned.fill(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(width: AppDimens.screenPadding),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  // 右箭头
                  LoadImage(
                    AppAssets.mineArrowRight,
                    width: _AboutPageState._arrowSize,
                    height: _AboutPageState._arrowSize,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: AppDimens.gap16),
                ],
              ),
            ),
            // 底部分隔线
            if (widget.showSeparator)
              Positioned(
                left: AppDimens.screenPadding,
                right: 0,
                bottom: 0,
                child: const Divider(
                  height: 0.5,
                  thickness: 0.5,
                  color: AppColors.divider,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
