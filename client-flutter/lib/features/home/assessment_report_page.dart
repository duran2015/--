import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/route_paths.dart';
import '../../core/theme/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_background.dart';
import '../../core/widgets/app_nav_bar.dart';
import '../../core/widgets/app_toast.dart';
import '../../utils/load_image.dart';
import 'home_models.dart';
import 'home_view_model.dart';

/// 测评报告页（routeTypeCode = 9004；Figma 518:2017）。
/// iOS 参照：XYHomeModule/Classes/ViewController/
/// XYHomeAssessmentReportViewController.swift +
/// View/XYHomeAssessmentReportScoreCardView.swift。
///
/// 流程：以路由参数（量表名占位）+ mock 先渲染 → 调 /app/assessment/detail
/// （assessmentId = userAssessId，契约 §3 #19）→ 用返回数据覆盖分数/等级/
/// 标签/解读/建议（detail 请求失败静默保留占位，与 iOS 一致）。
class AssessmentReportPage extends ConsumerStatefulWidget {
  const AssessmentReportPage({
    super.key,
    this.assessmentTitle,
    this.userAssessId,
    this.h5Link,
  });

  /// 测评标题（detail 字段确认前的量表名占位）
  final String? assessmentTitle;

  /// 用户测评记录 ID（作为 assessmentId 调 /app/assessment/detail）
  final int? userAssessId;

  /// 重新测答题 H5 链接（来自测评列表 h5Link，「重新测」时打开）
  final String? h5Link;

  @override
  ConsumerState<AssessmentReportPage> createState() =>
      _AssessmentReportPageState();
}

class _AssessmentReportPageState extends ConsumerState<AssessmentReportPage> {
  // iOS Style 枚举（Figma÷2 后 pt 值）
  static const double _horizontalInset = 15; // Figma 30 → 15
  static const double _sectionSpacing = 12; // Figma 24 → 12
  static const double _sectionCorner = 16; // 中间白卡片圆角
  static const double _boxCorner = 10; // 内层灰盒圆角
  static const double _badgeSize = 22; // 建议序号徽标
  static const double _retestCorner = 22.5;
  static const double _retestHeight = 46; // Figma 92 → 46
  // 出处/免责声明区（iOS setupSourceSection，Figma 1572:1793）
  static const double _sourceFontSize = 10; // Figma 20 → 10
  static const double _sourceIconSize = 10;
  static const double _sourceTopSpacing = 11; // 白卡片 → 出处栈
  static const double _sourceRowSpacing = 8;
  static const double _sourceDotSize = 3;
  static const Color _sourceDotColor = Color(0xFF8B8B8B);

  /// 报告数据（初值为 mock 占位，detail 返回后覆盖）
  late AssessmentReport _report =
      AssessmentReport.mock(assessmentTitle: widget.assessmentTitle);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchReportDetail());
  }

  /// 调 /app/assessment/detail 拉取报告详情，成功后用真实数据覆盖 mock 并刷新。
  /// iOS 参照：fetchReportDetail（失败仅打印，不 Toast）。
  Future<void> _fetchReportDetail() async {
    final userAssessId = widget.userAssessId;
    if (userAssessId == null) {
      if (kDebugMode) {
        debugPrint('[AssessmentReport] 跳过 detail：userAssessId 为空');
      }
      return;
    }
    try {
      final detail =
          await ref.read(homeApiProvider).fetchAssessmentDetail(userAssessId);
      if (detail != null && mounted) {
        if (kDebugMode) {
          debugPrint(
            '[AssessmentReport] detail ok：'
            'sourceUrl=${detail.sourceUrl} '
            'score=${detail.totalScore} level=${detail.level}',
          );
        }
        setState(() => _report = _report.mergedWithDetail(detail));
      }
    } catch (e, st) {
      // iOS：detail 请求失败仅打印，保留 mock 占位
      if (kDebugMode) {
        debugPrint('[AssessmentReport] detail 失败（保留占位）：$e\n$st');
      }
    }
  }

  /// 响应重新测点击：用答题 WebView 替换栈顶报告页，返回时直达列表/首页
  /// （不回到报告页）。iOS 参照：retestTapped（替换导航栈顶）。
  void _onRetestTapped() {
    final link = widget.h5Link?.trim() ?? '';
    if (link.isEmpty) {
      AppToast.show(context, '暂不支持重新测');
      return;
    }
    context.pushReplacement(
      '${RoutePaths.webview}?url=${Uri.encodeComponent(link)}'
      '&title=${Uri.encodeComponent(_report.scaleTitle)}'
      '&mode=assessment',
    );
  }

  /// 点击「内容出处」：打开 detail.sourceUrl（iOS sourceLinkTapped）。
  void _onSourceLinkTapped() {
    final raw = _report.sourceUrl?.trim() ?? '';
    if (raw.isEmpty) return;
    final uri = Uri.tryParse(raw);
    if (uri == null ||
        !(uri.isScheme('http') || uri.isScheme('https')) ||
        uri.host.isEmpty) {
      AppToast.show(context, '链接无效');
      return;
    }
    context.push(
      '${RoutePaths.webview}?url=${Uri.encodeComponent(raw)}'
      '&title=${Uri.encodeComponent('内容出处')}',
    );
  }

  /// 返回上一页。
  ///
  /// - 从「量表测试记录 / 全部测评」进入：正常 pop 回列表；
  /// - 答完问卷时 H5 openLink 把报告 push 在答题 WebView 之上：若直接
  ///   pop 会回到答题页，故连同 WebView 一起弹出；
  /// - 无法 pop 时回主壳首页。
  /// 原先一律 `go(home)` 会清掉整栈，从「我的 → 测试记录」进报告再返回
  /// 会落到主壳（仍停在我的 Tab），表现为「回到了我的」。
  void _onBack() {
    final router = GoRouter.of(context);
    if (!router.canPop()) {
      router.go(RoutePaths.home);
      return;
    }
    final matches = router.routerDelegate.currentConfiguration.matches;
    final prevIsAssessmentWebView = matches.length >= 2 &&
        matches[matches.length - 2].matchedLocation == RoutePaths.webview;
    if (prevIsAssessmentWebView) {
      router.pop();
      if (router.canPop()) router.pop();
      return;
    }
    router.pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack();
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        // iOS：XYOrderBackgroundView + 透明导航栏，标题「测评报告」
        body: AppPageBackground(
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                AppNavBar(title: '测评报告', transparent: true, onBack: _onBack),
                Expanded(
                  child: SingleChildScrollView(
                    // iOS contentInset.bottom 110 + middleCard bottom -120
                    padding: const EdgeInsets.only(bottom: 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppDimens.gap8),
                        // 量表名称 18 semibold #222
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: _horizontalInset,
                          ),
                          child: Text(
                            _report.scaleTitle,
                            style: AppTextStyles.titleLarge,
                          ),
                        ),
                        const SizedBox(height: AppDimens.gap8),
                        // 测评时间 11 #999
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: _horizontalInset,
                          ),
                          child: Text(
                            _report.testDateText,
                            style: AppTextStyles.label,
                          ),
                        ),
                        const SizedBox(height: AppDimens.gap12),
                        // 中间白色圆角内容卡片
                        // 得分卡相对白底：上/左/右 15（对齐 iOS scoreCardView inset）
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: _horizontalInset,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.cardBackground,
                              borderRadius:
                                  BorderRadius.circular(_sectionCorner),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: _horizontalInset,
                                    left: _horizontalInset,
                                    right: _horizontalInset,
                                  ),
                                  child: _ScoreCard(report: _report),
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    _horizontalInset,
                                    _sectionSpacing,
                                    _horizontalInset,
                                    _horizontalInset,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        '结果解读',
                                        style: AppTextStyles.titleSmall,
                                      ),
                                      const SizedBox(height: AppDimens.gap10),
                                      _buildBox(
                                        child: Text(
                                          _report.interpretation,
                                          style: AppTextStyles.body,
                                        ),
                                      ),
                                      const SizedBox(height: _sectionSpacing),
                                      const Text(
                                        '专业建议',
                                        style: AppTextStyles.titleSmall,
                                      ),
                                      const SizedBox(height: AppDimens.gap10),
                                      _buildBox(
                                          child: _buildSuggestionRows()),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // 白卡片下方：内容出处 + 两条免责提示
                        // （iOS setupSourceSection，Figma 1572:1793）
                        const SizedBox(height: _sourceTopSpacing),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: _horizontalInset,
                          ),
                          child: _buildSourceSection(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: _buildBottomBar(),
      ),
    );
  }

  /// 出处+免责声明竖向栈（出处行仅 sourceUrl 非空时展示；两条提示始终展示）。
  /// iOS 参照：XYHomeAssessmentReportViewController.setupSourceSection。
  Widget _buildSourceSection() {
    final sourceUrl = _report.sourceUrl?.trim() ?? '';
    final hasSource = sourceUrl.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasSource) ...[
          _buildSourceAttributionRow(),
          const SizedBox(height: _sourceRowSpacing),
        ],
        _buildTipRow('本量表结果仅供参考，不构成临床诊断'),
        const SizedBox(height: _sourceRowSpacing),
        _buildTipRow('本内容仅供参考，不可替代专业医师诊疗，如有不适请就医咨询'),
      ],
    );
  }

  /// 第一行「内容出处」链接行（图标 + 前缀 + 可点链接）。
  Widget _buildSourceAttributionRow() {
    const style = TextStyle(
      fontSize: _sourceFontSize,
      fontWeight: FontWeight.w400,
      height: 1.4,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        LoadImage(
          AppAssets.homeAssessmentSource,
          width: _sourceIconSize,
          height: _sourceIconSize,
          fit: BoxFit.contain,
          errorWidget: SizedBox(
            width: _sourceIconSize,
            height: _sourceIconSize,
            child: Icon(
              Icons.link,
              size: _sourceIconSize,
              color: AppColors.textTertiary,
            ),
          ),
        ),
        const SizedBox(width: AppDimens.gap4),
        Flexible(
          child: Text(
            '来源为权威医学/心理量表平台，点击可核验',
            style: style.copyWith(color: AppColors.textTertiary),
          ),
        ),
        GestureDetector(
          onTap: _onSourceLinkTapped,
          behavior: HitTestBehavior.opaque,
          child: Text(
            '内容出处',
            style: style.copyWith(color: AppColors.brandTeal),
          ),
        ),
      ],
    );
  }

  /// 带灰色小圆点的提示行（圆点落在与出处图标同宽的列内，文案左对齐）。
  Widget _buildTipRow(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: _sourceIconSize,
          height: _sourceIconSize + 4,
          child: Center(
            child: Container(
              width: _sourceDotSize,
              height: _sourceDotSize,
              decoration: const BoxDecoration(
                color: _sourceDotColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppDimens.gap4),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: _sourceFontSize,
              fontWeight: FontWeight.w400,
              color: AppColors.textTertiary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  /// 内层灰盒（iOS boxBackground #F7F8FC 圆角 10，内边距 12）。
  Widget _buildBox({required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.innerBackground,
        borderRadius: BorderRadius.circular(_boxCorner),
      ),
      padding: const EdgeInsets.all(AppDimens.gap12),
      child: child,
    );
  }

  /// 专业建议列表（iOS buildSuggestionRows：空数组展示占位，避免空白灰条）。
  Widget _buildSuggestionRows() {
    final suggestions = _report.suggestions;
    if (suggestions.isEmpty) {
      // 空态占位行（无序号，灰色文案）
      return Text(
        '暂无专业建议',
        style: AppTextStyles.body.copyWith(color: AppColors.textTertiary),
      );
    }
    final rows = <Widget>[];
    for (var i = 0; i < suggestions.length; i++) {
      if (i > 0) rows.add(_buildDivider());
      rows.add(_buildSuggestionRow(index: i + 1, text: suggestions[i]));
    }
    return Column(children: rows);
  }

  /// 单条专业建议行（iOS makeSuggestionRow：22 圆形序号徽标 #00A6A1 +
  /// 13 #666 文案，徽标与文案间距 10，文案 top 偏移 2）。
  Widget _buildSuggestionRow({required int index, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: _badgeSize,
          height: _badgeSize,
          decoration: const BoxDecoration(
            color: AppColors.brandTeal,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            '$index',
            style: AppTextStyles.label.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: AppDimens.gap10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(text, style: AppTextStyles.body),
          ),
        ),
      ],
    );
  }

  /// 建议项分隔线（iOS makeDivider：#EEEEEE 1px，左缩进 32，上下间距 10）。
  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.only(left: 32, top: 10, bottom: 10),
      child: Divider(height: 1, thickness: 1, color: AppColors.divider),
    );
  }

  /// 底部重新测操作栏（iOS setupBottomBar：白底 + #EAEAEA@40% 上阴影，
  /// 渐变「重新测」按钮 46 高圆角 22.5 + 11 #666 复测提示）。
  Widget _buildBottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEAEAEA).withValues(alpha: 0.4),
            offset: const Offset(0, -4),
            blurRadius: 4,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(
            top: AppDimens.gap12,
            left: _horizontalInset,
            right: _horizontalInset,
            bottom: AppDimens.gap8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _onRetestTapped,
                child: Container(
                  height: _retestHeight,
                  decoration: BoxDecoration(
                    // iOS applyBrandGradient：start 色在右
                    gradient: const LinearGradient(
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                      colors: [
                        AppColors.brandGradientStart,
                        AppColors.brandGradientEnd,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(_retestCorner),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '重新测',
                    style: AppTextStyles.title.copyWith(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: AppDimens.gap8),
              Text(
                _report.retestHint,
                style: AppTextStyles.label
                    .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 测评报告得分摘要卡（Figma 1530:1951 / 518:2081）。
///
/// 布局（逻辑 pt = Figma ÷ 2）：
/// - 左右/上下内边距 15 / 18；圆角 16；
/// - score 40 + level 18，间距 10；level → tags 间距 16；
/// - level 文案下方叠渐变色条（高 6，#C9E0EF→#DCE5FF）；
/// - 标签白底圆角 10、高 20、左右 inset 8，字 12；可换行，卡片高度随内容增高。
/// - 相对白色背景：上/左/右外边距 15（由外层 Padding 保证）。
class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.report});

  final AssessmentReport report;

  static const double _cardCorner = 16; // Figma 32 → 16
  static const double _padH = 15; // Figma 30 → 15
  static const double _padV = 18; // Figma 36 → 18
  static const double _scoreLevelGap = 10; // Figma：level 距 score 底约 10
  static const double _levelTagsGap = 16; // Figma：tags 距 level 底约 16
  static const double _gaugeWidth = 140;
  static const double _gaugeHeight = 93;
  static const double _gaugeTop = 21;
  static const double _gaugeRight = 7;
  static const double _gaugeAlpha = 0.34;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, // 拉满白底内容区，保证右外边距=左外边距 15
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_cardCorner),
        // Figma / iOS：#CED1FF → #EBF6FF
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFFCED1FF), Color(0xFFEBF6FF)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow.withValues(alpha: 0.5),
            offset: const Offset(0, 3),
            blurRadius: 6,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // 右侧仪表盘装饰（不参与高度计算）
          Positioned(
            top: _gaugeTop,
            right: _gaugeRight,
            child: Opacity(
              opacity: _gaugeAlpha,
              child: LoadImage(
                AppAssets.homeAssessmentReportGauge,
                width: _gaugeWidth,
                height: _gaugeHeight,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(_padH, _padV, _padH, _padV),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 得分 40 bold #525EE1（Figma DIN 80 / leading 80）
                Text(
                  report.scoreText,
                  style: const TextStyle(
                    fontSize: 40,
                    height: 1,
                    fontWeight: FontWeight.w700,
                    color: AppColors.indigo,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: _scoreLevelGap),
                // 结果等级 18 semibold #525EE1 + 底部渐变色条（Figma 1530:1966）
                _LevelTitle(text: report.levelTitle),
                const SizedBox(height: _levelTagsGap),
                // 无标签时仍预留一行标签高度，避免卡片被压矮
                if (report.tags.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final tag in report.tags) _Tag(text: tag),
                    ],
                  )
                else
                  const SizedBox(height: _Tag.rowHeight),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 等级文案 + 底部渐变色条（Figma 1530:1966：高 12→6，
/// `#C9E0EF` → `#DCE5FF`，叠在文字下沿并略伸出 2pt）。
class _LevelTitle extends StatelessWidget {
  const _LevelTitle({required this.text});

  final String text;

  static const double _barHeight = 6; // Figma 12 → 6
  static const double _barOverlapBelow = 2; // 色条底相对文字底伸出

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: -_barOverlapBelow,
            height: _barHeight,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xFFC9E0EF), Color(0xFFDCE5FF)],
                ),
              ),
            ),
          ),
          Text(
            text,
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.indigo,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

/// 结果标签（Figma 1530:1968：白底圆角 10，高约 20，字 12 #666，左右约 8）。
/// Wrap 子项会拿到整行 maxWidth；需按文字宽度收缩。
class _Tag extends StatelessWidget {
  const _Tag({required this.text});

  final String text;

  /// 单行标签高度（无标签时得分卡也按此预留）
  static const double rowHeight = 20; // Figma 标签区约 40 → 20
  static const double _corner = 10; // Figma 20 → 10
  static const EdgeInsets _inset =
      EdgeInsets.symmetric(horizontal: 8, vertical: 4);

  @override
  Widget build(BuildContext context) {
    return UnconstrainedBox(
      constrainedAxis: Axis.vertical,
      child: Container(
        height: rowHeight,
        padding: _inset,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(_corner),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            height: 1,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
