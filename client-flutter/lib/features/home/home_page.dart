import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_response.dart';
import '../../core/router/route_paths.dart';
import '../../core/theme/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_background.dart';
import '../../core/widgets/app_loading_hud.dart';
import '../../core/widgets/app_refresh_indicator.dart';
import '../../core/widgets/app_toast.dart';
import '../../utils/image_utils.dart';
import '../../utils/load_image.dart';
import 'home_models.dart';
import 'home_view_model.dart';
import 'widgets/mood_card.dart';
import 'widgets/mood_record_sheet.dart';
import '../profile/support_profile_prompt.dart';

/// 首页（Tab 根页面）：情绪打卡、专业测评、缓解小工具。
/// iOS 参照：XYHomeModule/Classes/ViewController/XYHomeViewController.swift。
///
/// 与 iOS 的一致点：
/// - 隐藏导航栏（gk_navigationBar.isHidden = true）+ 共享渐变背景；
/// - 顶部小鹿吉祥物 + 问候文案 + 「记录」按钮（今天已记录时隐藏）；
/// - 「最近7天情绪」卡（折叠 7 日行 / 展开月历）；
/// - 「专业测评」横向 150×150 卡片 + 「全部」入口；
/// - 「缓解小工具」4 列网格（H5 链接与 iOS 逐项一致）。
///
/// 说明：任务书提到的「7 天折线 TrendLineView」与「咨询师横幅」在当前
/// iOS 首页代码中均不存在（XYHomeViewController 无此组件），按
/// 「双端不一致以 iOS 为准」原则不实现。
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  /// 是否正在提交今日情绪（防重复点击，iOS isSubmittingMood）
  bool _submittingMood = false;

  @override
  void initState() {
    super.initState();
    // iOS viewWillAppear：拉取情绪趋势与测评列表
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitial());
  }

  Future<void> _loadInitial() async {
    final vm = ref.read(homeViewModelProvider.notifier);
    // 首屏失败静默（iOS showFailureToast: false 仅 DEBUG 打印）
    try {
      await vm.fetchMoodTrend();
    } catch (_) {}
    try {
      await vm.fetchAssessmentList();
    } catch (_) {}
  }

  /// 下拉刷新：并行请求情绪趋势与测评列表（iOS refreshHomeContent）。
  Future<void> _onRefresh() async {
    final (moodError, assessmentError) =
        await ref.read(homeViewModelProvider.notifier).refreshHomeContent();
    if (!mounted) return;
    // iOS：两路错误合并 Toast
    if (moodError != null && assessmentError != null) {
      AppToast.show(context, '$moodError；$assessmentError');
    } else if (moodError != null) {
      AppToast.show(context, moodError);
    } else if (assessmentError != null) {
      AppToast.show(context, assessmentError);
    }
  }

  /// 点击「记录」/「今天？」弹出情绪选择弹窗（iOS recordTapped）。
  Future<void> _onRecordTapped() async {
    final vm = ref.read(homeViewModelProvider.notifier);
    if (!vm.todayIsRecordable) {
      AppToast.show(context, '今天已记录，暂不可修改');
      return;
    }
    final option = await MoodRecordSheet.show(context);
    if (option == null || !mounted || _submittingMood) return;
    setState(() => _submittingMood = true);
    try {
      final message = await vm.submitTodayMood(note: option.title);
      if (!mounted) return;
      AppToast.show(context, message.isEmpty ? '记录成功' : message);
      // 记录心情成功后刷新最近 7 天情绪（iOS refreshMoodTrendAfterRecord）
      try {
        await vm.fetchMoodTrend(force: true);
      } catch (e) {
        if (!mounted) return;
        AppToast.show(context, e is ApiException ? e.msg : '网络异常，请稍后重试');
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      AppToast.show(context, e.msg);
    } finally {
      if (mounted) setState(() => _submittingMood = false);
    }
  }

  /// 打开测评：未测开答题 H5（iOS XYAssessmentWebViewController），
  /// 已测开测评报告页（iOS XYHomeAssessmentReportViewController）。
  /// iOS 参照：XYHomeAssessmentWebOpener.open。
  /// 返回后静默刷新测评列表（iOS viewWillAppear loadAssessmentList）。
  Future<void> _openAssessment({
    required AssessmentStatus status,
    required String title,
    String? h5Link,
    int? userAssessId,
  }) async {
    final String location;
    if (status == AssessmentStatus.tested) {
      location =
          '${RoutePaths.assessmentReport}?assessmentId=${userAssessId ?? ''}'
          '&title=${Uri.encodeComponent(title)}'
          '&h5Link=${Uri.encodeComponent(h5Link ?? '')}';
    } else {
      final link = h5Link?.trim() ?? '';
      if (link.isEmpty) {
        AppToast.show(context, '链接无效');
        return;
      }
      location = '${RoutePaths.webview}?url=${Uri.encodeComponent(link)}'
          '&title=${Uri.encodeComponent(title)}&mode=assessment';
    }
    await context.push(location);
    if (!mounted) return;
    // 从测评页返回：静默刷新测评状态（失败静默，同 iOS 首屏策略）
    try {
      await ref
          .read(homeViewModelProvider.notifier)
          .fetchAssessmentList(force: true);
    } catch (_) {}
  }

  /// 打开缓解小工具 H5 页（iOS openTool → XYURLRouter open webTitle）。
  void _openTool(HomeToolItem tool) {
    context.push(
      '${RoutePaths.webview}?url=${Uri.encodeComponent(tool.linkUrl)}'
      '&title=${Uri.encodeComponent(tool.title)}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeViewModelProvider);
    final vm = ref.watch(homeViewModelProvider.notifier);

    return Scaffold(
      body: AppPageBackground(
        child: Stack(
          fit: StackFit.expand,
          children: [
            SafeArea(
              bottom: false,
              child: AppRefreshIndicator(
                onRefresh: _onRefresh,
                // RefreshIndicator 内部 Stack 给子组件的是松约束；
                // SingleChildScrollView 会按内容缩高度，内容不够高时底部会空出
                // 一块滚不到的区域（视觉上像没到 tabbar 就被挡住）。
                // 用 LayoutBuilder + minHeight 把滚动视口撑满可用高度。
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _GreetingHeader(
                              showRecordButton: vm.todayIsRecordable,
                              onRecordTapped: _onRecordTapped,
                            ),
                            const Padding(
                              padding: EdgeInsets.fromLTRB(
                                AppDimens.screenPadding,
                                AppDimens.gap10,
                                AppDimens.screenPadding,
                                0,
                              ),
                              child: SupportProfilePrompt(
                                allowDismiss: true,
                              ),
                            ),
                            // 情绪卡：距小鹿底 10，左右 15
                            Padding(
                              padding: const EdgeInsets.only(
                                top: AppDimens.gap10,
                                left: AppDimens.screenPadding,
                                right: AppDimens.screenPadding,
                              ),
                              child: HomeMoodCard(
                                moods: vm.moods,
                                monthMoodsOf: vm.monthMoods,
                                initialYear: vm.calendarYear,
                                initialMonth: vm.calendarMonth,
                                onRequestMonth: (year, month) =>
                                    vm.fetchMoodCalendar(
                                        year: year, month: month),
                                onRecordToday: _onRecordTapped,
                              ),
                            ),
                            // 专业测评区块（iOS setupAssessmentSection）
                            Padding(
                              padding: const EdgeInsets.only(
                                top: AppDimens.sectionGap,
                                left: AppDimens.screenPadding,
                                right: AppDimens.screenPadding,
                              ),
                              child: HomeSectionHeader(
                                prefix: '专业',
                                highlight: '测评',
                                showsAll: true,
                                onAllTapped: () =>
                                    context.push(RoutePaths.assessmentList),
                              ),
                            ),
                            const SizedBox(height: AppDimens.gap12),
                            _AssessmentStrip(
                              assessments: state.assessments,
                              onTap: (a) => _openAssessment(
                                status: a.status,
                                title: a.title,
                                h5Link: a.h5Link,
                                userAssessId: a.userAssessId,
                              ),
                            ),
                            // 缓解小工具区块（iOS setupToolSection）
                            const Padding(
                              padding: EdgeInsets.only(
                                top: AppDimens.sectionGap,
                                left: AppDimens.screenPadding,
                                right: AppDimens.screenPadding,
                              ),
                              child: HomeSectionHeader(
                                prefix: '缓解',
                                highlight: '小工具',
                                showsAll: false,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                top: AppDimens.gap12,
                                bottom: AppDimens.gap20,
                                left: AppDimens.screenPadding,
                                right: AppDimens.screenPadding,
                              ),
                              child: _ToolGrid(onTap: _openTool),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            if (_submittingMood)
              const Positioned.fill(
                child: AppLoadingHud(message: '提交中'),
              ),
          ],
        ),
      ),
    );
  }
}

/// 顶部问候区：小鹿吉祥物 + 问候文案 + 「记录」按钮。
/// iOS 参照：XYHomeViewController.setupHeader。
class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader({
    required this.showRecordButton,
    required this.onRecordTapped,
  });

  final bool showRecordButton;
  final VoidCallback onRecordTapped;

  /// 小鹿吉祥物宽/高（iOS mascotWidth 65 / mascotHeight 68）
  static const double _mascotWidth = 65;
  static const double _mascotHeight = 68;

  /// 「记录」按钮渐变（iOS applyBrandGradient：start 色在右）
  static const LinearGradient _brandGradient = LinearGradient(
    begin: Alignment.centerRight,
    end: Alignment.centerLeft,
    colors: [AppColors.brandGradientStart, AppColors.brandGradientEnd],
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppDimens.gap8,
        left: AppDimens.screenPadding,
        right: AppDimens.screenPadding,
      ),
      child: Row(
        children: [
          LoadImage(
            AppAssets.homeMascot,
            width: _mascotWidth,
            height: _mascotHeight,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: AppDimens.gap8),
          // 问候文案（iOS centerY = mascot + 4，这里顶部对齐 mascot 中线下移 4）
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: AppDimens.gap4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    HomeViewModel.greetingTitle,
                    style: AppTextStyles.title,
                  ),
                  const SizedBox(height: AppDimens.gap4),
                  Text(
                    HomeViewModel.greetingSubtitle,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
          // 「记录」按钮：高 30 圆角 15，渐变底，图标 + 13 w600 白字
          if (showRecordButton)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onRecordTapped,
              child: Container(
                height: 30,
                padding: const EdgeInsets.only(left: 14, right: 18),
                decoration: BoxDecoration(
                  gradient: _brandGradient,
                  borderRadius: BorderRadius.circular(AppDimens.gap15),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LoadImage(
                      AppAssets.homeRecordPlus,
                      width: AppDimens.gap16,
                      height: AppDimens.gap16,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: AppDimens.gap4),
                    Text(
                      '记录',
                      style: AppTextStyles.body.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 首页区块标题头（左标题含高亮词 + 装饰图标 + 可选「全部」）。
/// iOS 参照：XYHomeModule/Classes/View/XYHomeSectionHeaderView.swift。
class HomeSectionHeader extends StatelessWidget {
  const HomeSectionHeader({
    super.key,
    required this.prefix,
    required this.highlight,
    this.showsAll = true,
    this.onAllTapped,
  });

  /// 标题前缀（#222）
  final String prefix;

  /// 标题高亮后缀（brandTeal）
  final String highlight;

  /// 是否显示右侧「全部 >」
  final bool showsAll;

  /// 「全部」点击回调
  final VoidCallback? onAllTapped;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: Row(
        children: [
          Text.rich(
            TextSpan(
              text: prefix,
              style: AppTextStyles.title,
              children: [
                TextSpan(
                  text: highlight,
                  style: const TextStyle(color: AppColors.brandTeal),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimens.gap4),
          LoadImage(
            AppAssets.homeSectionSparkle,
            width: AppDimens.gap16,
            height: AppDimens.gap16,
            fit: BoxFit.contain,
          ),
          const Spacer(),
          if (showsAll)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onAllTapped,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '全部',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: AppDimens.gap4),
                  LoadImage(
                    AppAssets.homeSectionArrow,
                    width: AppDimens.gap12,
                    height: AppDimens.gap12,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// 测评横向滚动卡片条（iOS assessmentScrollView：高 150，卡片 150×150，
/// 首张左 15、间距 10、末张右 15）。
class _AssessmentStrip extends StatelessWidget {
  const _AssessmentStrip({required this.assessments, required this.onTap});

  final List<HomeAssessment> assessments;
  final ValueChanged<HomeAssessment> onTap;

  @override
  Widget build(BuildContext context) {
    if (assessments.isEmpty) {
      // iOS 接口未返回时横向区为空占位（保持区块节奏）
      return const SizedBox(height: 150);
    }
    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.screenPadding,
        ),
        itemCount: assessments.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppDimens.gap10),
        itemBuilder: (context, index) => HomeAssessmentCard(
          assessment: assessments[index],
          onTap: () => onTap(assessments[index]),
        ),
      ),
    );
  }
}

/// 首页「专业测评」横向卡片（150×150，圆角 16）。
/// iOS 参照：XYHomeModule/Classes/View/XYHomeAssessmentCardView.swift
/// （顶部 / 图标-标题 / 底部三段留白等高）。
///
/// 图标形态对齐 iOS（ios/01_home.png）：小图标置于**白色圆形底托**内，
/// 位于卡片左上角；标题/副标题固定字号单行显示，过长省略，保证各卡
/// 字号与文字位置一致。
class HomeAssessmentCard extends StatelessWidget {
  const HomeAssessmentCard({
    super.key,
    required this.assessment,
    this.onTap,
  });

  final HomeAssessment assessment;
  final VoidCallback? onTap;

  /// 卡片尺寸（iOS width/height 150）
  static const double cardSize = 150;

  /// 左上角白色圆形底托直径（iOS iconBadge 48）
  static const double iconBadgeSize = 48;

  /// 底托内图标尺寸（iOS 底托内缩约 10）
  static const double iconSize = 28;

  /// 标题行高（15pt × 1.2），固定槽位避免各卡垂直位置漂移
  static const double _titleSlotHeight = 18;

  /// 副标题行高（12pt × 1.2）
  static const double _subtitleSlotHeight = 15;

  @override
  Widget build(BuildContext context) {
    final localBg = assessmentLocalCardImage(assessment.questionnaireKey);
    final localIcon = assessmentLocalListIcon(assessment.questionnaireKey);

    Widget icon;
    final iconUrl = assessment.iconUrl;
    if (iconUrl != null && iconUrl.isNotEmpty) {
      icon = LoadImage(
        iconUrl,
        width: iconSize,
        height: iconSize,
        fit: BoxFit.contain,
        errorWidget: _localIcon(localIcon),
      );
    } else {
      icon = _localIcon(localIcon);
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: cardSize,
        height: cardSize,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppDimens.cardRadiusLarge),
          // 背景图：接口 backgroundImage 优先，缺省走本地占位图，均无则白底
          image: assessment.backgroundImageUrl != null &&
                  assessment.backgroundImageUrl!.isNotEmpty
              ? DecorationImage(
                  image: ImageUtils.getImageProvider(
                      assessment.backgroundImageUrl!),
                  fit: BoxFit.cover,
                  onError: (_, __) {},
                )
              : (localBg != null
                  ? DecorationImage(
                      image: ImageUtils.getImageProvider(localBg),
                      fit: BoxFit.cover,
                    )
                  : null),
        ),
        child: Stack(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppDimens.cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 三段留白等高（iOS topGuide = iconTitleGuide = bottomGuide）
                  const Spacer(),
                  // 白色圆形底托 + 小图标（iOS：白圆 48，图标 28 居中）
                  Container(
                    width: iconBadgeSize,
                    height: iconBadgeSize,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: icon,
                  ),
                  const Spacer(),
                  // 标题/副标题：固定字号 + 固定行槽，过长省略（各卡对齐）
                  SizedBox(
                    height: _titleSlotHeight,
                    width: double.infinity,
                    child: Text(
                      assessment.title,
                      style: AppTextStyles.titleSmall.copyWith(height: 1.2),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: AppDimens.gap8),
                  SizedBox(
                    height: _subtitleSlotHeight,
                    width: double.infinity,
                    child: Text(
                      assessment.subtitle,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
            // 状态标签：top/right 15，11 w600（未测青绿 / 已测 #999）
            Positioned(
              top: AppDimens.cardPadding,
              right: AppDimens.cardPadding,
              child: Text(
                assessment.status == AssessmentStatus.tested ? '已测' : '未测',
                style: AppTextStyles.label.copyWith(
                  color: assessment.status == AssessmentStatus.tested
                      ? AppColors.textTertiary
                      : AppColors.brandTeal,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _localIcon(String? asset) {
    if (asset == null) {
      return const SizedBox(width: iconSize, height: iconSize);
    }
    return LoadImage(
      asset,
      width: iconSize,
      height: iconSize,
      fit: BoxFit.contain,
    );
  }
}

/// 缓解小工具 4 列网格（iOS buildToolGrid：列间距 8、行间距 12、项高 82）。
class _ToolGrid extends StatelessWidget {
  const _ToolGrid({required this.onTap});

  final ValueChanged<HomeToolItem> onTap;

  /// 每行列数（iOS columnCount 4）
  static const int _columnCount = 4;

  /// 行间距（iOS verticalSpacing 12）
  static const double _rowSpacing = 12;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var start = 0; start < kHomeTools.length; start += _columnCount) {
      final rowTools = kHomeTools.sublist(
        start,
        (start + _columnCount).clamp(0, kHomeTools.length),
      );
      if (start > 0) rows.add(const SizedBox(height: _rowSpacing));
      rows.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final tool in rowTools)
            Expanded(
              child: HomeToolItemView(
                tool: tool,
                onTap: () => onTap(tool),
              ),
            ),
          // 不足 4 列补空（iOS spacer）
          for (var i = rowTools.length; i < _columnCount; i++)
            const Expanded(child: SizedBox()),
        ],
      ));
    }
    return Column(children: rows);
  }
}

/// 首页「缓解小工具」网格单项。
/// iOS 参照：XYHomeModule/Classes/View/XYHomeToolItemView.swift
/// （白底容器 58 圆角 16，图标 44 居中，标题 12 #222，总高 82）。
class HomeToolItemView extends StatelessWidget {
  const HomeToolItemView({super.key, required this.tool, this.onTap});

  final HomeToolItem tool;
  final VoidCallback? onTap;

  /// 白底容器尺寸（iOS 58）
  static const double _containerSize = 58;

  /// 图标尺寸（iOS 44）
  static const double _iconSize = 44;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        height: 82,
        child: Column(
          children: [
            Container(
              width: _containerSize,
              height: _containerSize,
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(AppDimens.cardRadiusLarge),
              ),
              alignment: Alignment.center,
              child: LoadImage(
                tool.iconAsset,
                width: _iconSize,
                height: _iconSize,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: AppDimens.gap8),
            Text(
              tool.title,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textPrimary,
                height: 1.2, // 固定行高，保证 58+8+14.4=80.4 ≤ 82（iOS 项高）
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
