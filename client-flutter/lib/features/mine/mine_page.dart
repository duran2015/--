import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/network/api_response.dart';
import '../../core/router/route_paths.dart';
import '../../core/theme/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_background.dart';
import '../../core/widgets/app_loading_hud.dart';
import '../../core/widgets/app_toast.dart';
import '../../utils/load_image.dart';
import '../../features/auth/auth_view_model.dart';
import '../profile/support_profile_state.dart';

/// 菜单行标识（点击路由用）。
/// iOS 参照：XYMineViewModel.MenuRow。
enum _MenuRow {
  supportProfile,
  scale,
  appointment,
  summary,
  about,
  feedback,
  accountSecurity
}

/// 单行菜单展示数据。
/// iOS 参照：XYMineViewModel.MenuItem。
class _MenuItem {
  const _MenuItem({
    required this.row,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  final _MenuRow row;
  final String icon;
  final String title;
  final String? subtitle;
}

/// 一个菜单分组的展示数据。
/// iOS 参照：XYMineViewModel.MenuSection。
class _MenuSection {
  const _MenuSection({required this.title, required this.rows});

  final String title;
  final List<_MenuItem> rows;
}

/// 用户端「我的」页：共享订单背景 + 头部用户信息/身份切换 + 四个分组菜单。
/// iOS 参照：XYMineModule/Classes/ViewController/XYMineViewController.swift +
/// ViewModel/XYMineViewModel.swift。
///
/// 说明：
/// - iOS 我的页【没有】直接退出登录入口，退出登录在「账号与安全」内
///   （XYMineViewModel sections：量表记录/预约记录/小结与建议/账号与安全/意见反馈），
///   按「以 iOS 代码为准」原则本页不重复添加退出按钮；
/// - 「数字心理画像」已在原生用户端下线：页面、路由（9005）与全部入口已移除。
class MinePage extends ConsumerStatefulWidget {
  const MinePage({super.key});

  @override
  ConsumerState<MinePage> createState() => _MinePageState();
}

class _MinePageState extends ConsumerState<MinePage> {
  /// 身份切换请求中标志（防重复点击，iOS isSubmitting）
  bool _switching = false;

  /// 页面底部免责声明（Figma 1572:2224）。
  /// iOS 参照：XYMineViewController.Style.disclaimerText。
  static const String _disclaimerText = '本内容仅供参考，不可替代专业医师诊疗，如有不适请就医咨询';

  /// 末张卡片到免责声明间距（Figma 140px → 70pt）。
  static const double _disclaimerTopSpacing = 70;

  /// 四个分组的菜单数据。
  /// iOS 参照：XYMineViewModel.sections。
  static const List<_MenuSection> _sections = [
    _MenuSection(title: '我的心灵档案', rows: [
      _MenuItem(
        row: _MenuRow.supportProfile,
        icon: AppAssets.minePortrait,
        title: '我的支持档案',
        subtitle: '管理基础资料、咨询偏好与授权内容',
      ),
      _MenuItem(
        row: _MenuRow.scale,
        icon: AppAssets.mineScale,
        title: '量表记录',
      ),
    ]),
    _MenuSection(title: '预约与服务', rows: [
      _MenuItem(
        row: _MenuRow.appointment,
        icon: AppAssets.mineAppointment,
        title: '预约记录',
      ),
      _MenuItem(
        row: _MenuRow.summary,
        icon: AppAssets.mineSummary,
        title: '小结与建议',
      ),
    ]),
    _MenuSection(title: '账号与支持', rows: [
      _MenuItem(
        row: _MenuRow.about,
        icon: AppAssets.mineAbout,
        title: '关于我们',
        subtitle: '平台介绍、联系方式与版本信息',
      ),
      _MenuItem(
        row: _MenuRow.feedback,
        icon: AppAssets.mineFeedback,
        title: '意见反馈',
        subtitle: '提交使用问题或产品建议',
      ),
      _MenuItem(
        row: _MenuRow.accountSecurity,
        icon: AppAssets.mineAccSafe,
        title: '账号与安全',
        subtitle: '切换身份、退出登录与账号管理',
      ),
    ]),
  ];

  /// 菜单行点击路由。
  /// iOS 参照：XYMineViewController.handle(row:)。
  void _handleRow(_MenuRow row) {
    switch (row) {
      case _MenuRow.supportProfile:
        context.push(RoutePaths.supportProfile);
      case _MenuRow.scale:
        context.push(RoutePaths.mineAssessments);
      case _MenuRow.appointment:
        context.push(RoutePaths.orders);
      case _MenuRow.summary:
        context.push(RoutePaths.mineSummaries);
      case _MenuRow.about:
        context.push(RoutePaths.mineAbout);
      case _MenuRow.accountSecurity:
        context.push(RoutePaths.mineSecurity);
      case _MenuRow.feedback:
        context.push(RoutePaths.mineFeedback);
    }
  }

  /// 点击「切换身份」胶囊：直接选择咨询师身份并进入独立 Web 工作台。
  ///
  /// 当前产品原型由 Flutter 承载用户端、Web 承载咨询师端；不能依据 Flutter
  /// 登录响应里的 availableIdentities 把用户误导到 Flutter 入驻页。真实资质与
  /// 入驻状态由后续统一账号接口和咨询师 Web 端处理。
  void _onSwitchIdentityTapped() {
    _switchToConsultant();
  }

  /// 切换为咨询师身份。
  /// iOS 参照：XYMineViewController.switchToConsultantTapped +
  /// XYMineViewModel.switchToConsultant（selectIdentity 成功后切咨询师端主界面）。
  Future<void> _switchToConsultant() async {
    if (_switching) return;
    setState(() => _switching = true);
    try {
      final route = await ref
          .read(authViewModelProvider.notifier)
          .selectIdentity('consultant');
      if (!mounted) return;
      context.go(route);
    } on ApiException catch (e) {
      if (!mounted) return;
      AppToast.show(context, e.msg);
    } finally {
      if (mounted) setState(() => _switching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final account = ref.watch(accountProvider);
    final editableProfile = ref.watch(supportProfileProvider);
    // iOS displayName：优先 nickname，其次 phone，最后占位「未登录」
    final displayName = editableProfile.preferredName.trim().isNotEmpty
        ? editableProfile.preferredName
        : (account?.nickName ?? account?.phone ?? '未登录');
    final avatarUrl = account?.avatar;
    // 仅双身份展示「切换身份」（单身份无入口）
    const showSwitchIdentity = true;

    return Scaffold(
      // iOS：隐藏导航栏 + 共享订单背景
      body: AppPageBackground(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Stack 松约束下 ScrollView 会按内容缩高度，底部留出死区；
            // 用 minHeight 撑满可视区，滚动底边贴齐 tabbar。
            LayoutBuilder(
              builder: (context, constraints) {
                final topPadding = MediaQuery.paddingOf(context).top + 12.h;
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 头部：紧贴状态栏下方（状态栏高度 + 12.h 边距）
                        Padding(
                          padding: EdgeInsets.only(top: topPadding),
                          child: _MineHeader(
                            avatarUrl: avatarUrl,
                            avatarBytes: editableProfile.avatarBytes,
                            displayName: displayName,
                            tagline: editableProfile.personalTagline,
                            showSwitchIdentity: showSwitchIdentity,
                            onProfileTap: () =>
                                context.push(RoutePaths.userProfileEdit),
                            onSwitchTap: _onSwitchIdentityTapped,
                          ),
                        ),
                        // 分组卡片：首卡距头像底 20，卡片间 16
                        Padding(
                          padding: const EdgeInsets.only(
                            top: AppDimens.gap20,
                            left: AppDimens.screenPadding,
                            right: AppDimens.screenPadding,
                          ),
                          child: Column(
                            children: [
                              for (var i = 0; i < _sections.length; i++) ...[
                                if (i > 0)
                                  const SizedBox(height: AppDimens.gap16),
                                _MineMenuCard(
                                  section: _sections[i],
                                  onRowTap: _handleRow,
                                ),
                              ],
                            ],
                          ),
                        ),
                        // 底部免责声明（iOS：Light 10pt、#999、居中，
                        // 距末卡 70，左右 15，底 16）
                        // Column 为 start 对齐，需撑满宽度后 textAlign 才水平居中。
                        const SizedBox(
                            height: _MinePageState._disclaimerTopSpacing),
                        const Padding(
                          padding: EdgeInsets.only(
                            left: AppDimens.screenPadding,
                            right: AppDimens.screenPadding,
                            bottom: AppDimens.gap16,
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            child: Text(
                              _MinePageState._disclaimerText,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w300,
                                color: AppColors.textTertiary,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            // 切换中加载遮罩（iOS XYLoading.show("切换中")）
            if (_switching)
              const Positioned.fill(
                child: AppLoadingHud(message: '切换中'),
              ),
          ],
        ),
      ),
    );
  }
}

/// 头部：头像 + 昵称/slogan（左）+ 可选「切换身份」胶囊（右，仅双身份）。
/// iOS 参照：XYMineViewController.setupHeader。
class _MineHeader extends StatelessWidget {
  const _MineHeader({
    required this.avatarUrl,
    required this.avatarBytes,
    required this.displayName,
    required this.tagline,
    required this.showSwitchIdentity,
    required this.onSwitchTap,
    required this.onProfileTap,
  });

  final String? avatarUrl;
  final Uint8List? avatarBytes;
  final String displayName;
  final String tagline;
  final bool showSwitchIdentity;
  final VoidCallback onSwitchTap;
  final VoidCallback onProfileTap;

  /// 横向外边距（iOS horizontalInset 20）
  static const double _horizontalInset = 20;

  /// 头像直径（iOS avatarSize 58）
  static const double _avatarSize = 58;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _horizontalInset),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头像 58 圆形（占位图 AppAssets，iOS 用 SF Symbol 占位）
          GestureDetector(
            onTap: onProfileTap,
            child: ClipOval(
                child: avatarBytes != null
                    ? Image.memory(avatarBytes!,
                        width: _avatarSize,
                        height: _avatarSize,
                        fit: BoxFit.cover)
                    : avatarUrl != null && avatarUrl!.isNotEmpty
                        ? LoadImage(
                            avatarUrl!,
                            width: _avatarSize,
                            height: _avatarSize,
                            fit: BoxFit.cover,
                            errorWidget: _placeholderAvatar(),
                          )
                        : _placeholderAvatar()),
          ),
          const SizedBox(width: AppDimens.gap12),
          // 昵称 16 w600 #222 + slogan 12 #666（间距 6）
          Expanded(
            child: InkWell(
                onTap: onProfileTap,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  // 与头像垂直居中：头像 58，两行文字约 44，顶部补 (58-44)/2
                  padding: const EdgeInsets.only(top: AppDimens.gap6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: AppTextStyles.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppDimens.gap6),
                      Text(
                        tagline,
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                )),
          ),
          // 资料编辑是高频入口，显式展示，避免只靠点头像猜测。
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _EditProfilePill(onTap: onProfileTap),
              if (showSwitchIdentity) ...[
                const SizedBox(height: 6),
                _SwitchIdentityPill(onTap: onSwitchTap),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _placeholderAvatar() {
    return const LoadImage(
      AppAssets.icDefaultAvatar,
      width: _avatarSize,
      height: _avatarSize,
      fit: BoxFit.cover,
    );
  }
}

class _EditProfilePill extends StatelessWidget {
  const _EditProfilePill({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFEADDFF),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: const SizedBox(
          height: 24,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.edit_outlined, size: 13, color: Color(0xFF21005D)),
                SizedBox(width: 4),
                Text(
                  '编辑资料',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF21005D),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 「切换身份」胶囊按钮：纵向浅渐变底（#F7F8FC → #FCFCFE）+ 圆角 12。
/// iOS 参照：XYMinePillButton（图标 13 + 文字 12 w600 #222，间距 4，左右各 8）。
class _SwitchIdentityPill extends StatelessWidget {
  const _SwitchIdentityPill({required this.onTap});

  final VoidCallback onTap;

  /// 胶囊高度（iOS pillHeight 24）
  static const double _height = 24;

  /// 渐变起止色（iOS #F7F8FC → #FCFCFE，自上而下）
  static const LinearGradient _bgGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF7F8FC), Color(0xFFFCFCFE)],
  );

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: _height,
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.gap8),
        decoration: BoxDecoration(
          gradient: _bgGradient,
          borderRadius: BorderRadius.circular(AppDimens.cardRadius),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const LoadImage(
              AppAssets.mineSwitch,
              width: 13,
              height: 13,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: AppDimens.gap4),
            Text(
              '切换身份',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 「我的」页菜单分组：灰色小标题悬于白卡片上方 + 多行。
/// iOS 参照：XYMineMenuCardView。
class _MineMenuCard extends StatelessWidget {
  const _MineMenuCard({required this.section, required this.onRowTap});

  final _MenuSection section;
  final ValueChanged<_MenuRow> onRowTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 分组标题 12 #666，左偏移 4（iOS titleLabel left +4）
        Padding(
          padding: const EdgeInsets.only(left: AppDimens.gap4),
          child: Text(
            section.title,
            style:
                AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(height: AppDimens.gap8),
        // 白卡片：圆角 12（iOS masksToBounds，无投影）
        ClipRRect(
          borderRadius: BorderRadius.circular(AppDimens.cardRadius),
          child: Container(
            color: AppColors.cardBackground,
            child: Column(
              children: [
                for (var i = 0; i < section.rows.length; i++)
                  _MineMenuRowView(
                    item: section.rows[i],
                    showSeparator: i < section.rows.length - 1,
                    onTap: () => onRowTap(section.rows[i].row),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// 「我的」页菜单单行：切图图标 + 标题 + 副标题 + 右箭头（白卡片内）。
/// iOS 参照：XYMineMenuRowView
/// （无副标题行高 49.5，有副标题 70；图标 20 左 16；箭头 12 右 16；
/// 分隔线 #EEEEEE 0.5 从图标左起）。
class _MineMenuRowView extends StatefulWidget {
  const _MineMenuRowView({
    required this.item,
    required this.showSeparator,
    required this.onTap,
  });

  final _MenuItem item;
  final bool showSeparator;
  final VoidCallback onTap;

  /// 无副标题行高（iOS rowHeight 49.5）
  static const double _rowHeight = 49.5;

  /// 有副标题行高（iOS rowHeightWithSubtitle 70）
  static const double _rowHeightWithSubtitle = 70;

  @override
  State<_MineMenuRowView> createState() => _MineMenuRowViewState();
}

class _MineMenuRowViewState extends State<_MineMenuRowView> {
  /// 按下高亮（iOS rowTapped：短暂 #F7F7F7 闪白）
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final hasSubtitle =
        widget.item.subtitle != null && widget.item.subtitle!.isNotEmpty;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: Container(
        height: hasSubtitle
            ? _MineMenuRowView._rowHeightWithSubtitle
            : _MineMenuRowView._rowHeight,
        color: _pressed ? const Color(0xFFF7F7F7) : AppColors.cardBackground,
        child: Stack(
          children: [
            Row(
              children: [
                const SizedBox(width: AppDimens.gap16),
                // 图标 20
                LoadImage(
                  widget.item.icon,
                  width: 20,
                  height: 20,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: AppDimens.gap12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 标题 15 #222
                      Text(
                        widget.item.title,
                        style: AppTextStyles.titleSmall.copyWith(
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      if (hasSubtitle) ...[
                        // 副标题 13 #999，与标题间距 10
                        const SizedBox(height: AppDimens.gap10),
                        Text(
                          widget.item.subtitle!,
                          style: AppTextStyles.body
                              .copyWith(color: AppColors.textTertiary),
                        ),
                      ],
                    ],
                  ),
                ),
                // 右箭头 12（切图 #A5ABBD）
                LoadImage(
                  AppAssets.mineArrowRight,
                  width: 12,
                  height: 12,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: AppDimens.gap16),
              ],
            ),
            // 底部分隔线：从图标左（16）起到卡片右，0.5 #EEEEEE，末行隐藏
            if (widget.showSeparator)
              const Positioned(
                left: AppDimens.gap16,
                right: 0,
                bottom: 0,
                child: Divider(
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
