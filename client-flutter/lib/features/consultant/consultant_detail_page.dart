import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_response.dart';
import '../../core/theme/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_dialog.dart';
import '../../core/widgets/app_loading_hud.dart';
import '../../core/widgets/app_nav_bar.dart';
import '../../core/widgets/app_states.dart';
import '../../core/widgets/app_toast.dart';
import '../../utils/image_utils.dart';
import '../../utils/load_image.dart';
import '../report/more_action_sheet.dart';
import '../report/report_models.dart';
import '../report/report_reason_sheet.dart';
import '../report/report_service.dart';
import '../message/message_view_model.dart';
import 'booking_sheet.dart';
import 'consultant_api.dart';
import 'consultant_models.dart';
import 'review_list_page.dart';

/// 咨询师详情页（/consultant/detail?consultantId=）。
/// iOS 参照：XYAIModule/XYAIModule/Classes/ViewController/
/// XYCounselorDetailViewController.swift（区块顺序：头部→介绍→
/// 资质/擅长/风格合并卡→最近可约→评价；底部固定预约栏）。
class ConsultantDetailPage extends ConsumerStatefulWidget {
  const ConsultantDetailPage({super.key, required this.consultantId});

  final int consultantId;

  @override
  ConsumerState<ConsultantDetailPage> createState() =>
      _ConsultantDetailPageState();
}

class _ConsultantDetailPageState extends ConsumerState<ConsultantDetailPage> {
  ConsultantDetail? _detail;
  bool _loading = true;
  String? _error;

  /// 举报提交 / 拉黑中（叠 AppLoadingHud）
  bool _actionBusy = false;
  String _actionBusyMessage = '';

  /// 评价列表（详情首屏 +「更多评价」追加；iOS viewModel.reviews）
  List<ConsultantReview> _reviews = const [];

  /// 评价分页已到底（本页返回 < pageSize）
  bool _reviewsExhausted = false;

  /// 正在加载更多评价
  bool _loadingReviews = false;

  /// 评价分页大小（iOS reviewPageSize）
  static const int _reviewPageSize = 5;

  // iOS Style 实值（XYCounselorDetailViewController.Style）
  static const double _headerBackgroundHeight = 217;
  static const double _headerAvatarSize = 92;
  static const double _profileCardRadius = 12;
  static const double _profileCardInnerPadding = 10;
  static const double _statsInnerInset = 12;
  static const double _headerStatsHeight = 74;
  static const double _horizontalInset = 15;
  static const double _sectionSpacing = 10;
  static const double _timeCardFixedWidth = 110;
  static const double _timeCardHeight = 84;
  static const double _methodCardRadius = 10;
  static const double _bottomContentHeight = 70;
  static const double _bookButtonWidth = 182;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  /// 请求咨询师详情（iOS 参照：fetchDetail）
  Future<void> _fetchDetail() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final detail = await ref
          .read(consultantApiProvider)
          .fetchDetail(consultantId: widget.consultantId);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _reviews = List<ConsultantReview>.from(detail.reviews);
        _reviewsExhausted = false;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.msg;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = '加载失败，请稍后重试';
        _loading = false;
      });
    }
  }

  // ---------- 派生展示字段（iOS 参照：XYCounselorDetailViewModel） ----------

  String get _name => _detail?.realName ?? '';
  String get _title => _detail?.title ?? '';
  String get _avatar => _detail?.avatar ?? '';
  bool get _isVerified => _detail?.isVerified ?? false;
  List<String> get _expertises => _detail?.specialtyTags ?? const [];
  List<String> get _styleTags => _detail?.styleTags ?? const [];
  List<ConsultantCapability> get _capabilities =>
      _detail?.capabilities ?? const [];

  /// 点击导航「更多」：举报 / 拉黑。
  /// iOS 参照：moreTapped → XYCounselorMoreSheetViewController。
  Future<void> _moreTapped() async {
    final action = await MoreActionSheet.show(context);
    if (!mounted || action == null) return;
    switch (action) {
      case MoreSheetAction.report:
        await _openReportReasonSheet();
      case MoreSheetAction.block:
        await _confirmBlockCounselor();
    }
  }

  /// 弹出举报理由并提交（咨询师 / 默认）。
  Future<void> _openReportReasonSheet() async {
    final reason = await ReportReasonSheet.show(context);
    if (!mounted || reason == null) return;
    await _submitReport(
      reason: reason,
      targetType: ReportTargetType.consultant,
      targetId: '${_detail?.consultantId ?? widget.consultantId}',
    );
  }

  /// 评价「举报」：理由弹层 → targetType=review。
  /// iOS 参照：reviewReportTapped。
  Future<void> _reportReview(int reviewId) async {
    final reason = await ReportReasonSheet.show(context);
    if (!mounted || reason == null) return;
    await _submitReport(
      reason: reason,
      targetType: ReportTargetType.review,
      targetId: '$reviewId',
    );
  }

  /// 提交举报。iOS 参照：submitReport。
  Future<void> _submitReport({
    required ReportReason reason,
    required ReportTargetType targetType,
    required String targetId,
  }) async {
    if (targetId.isEmpty || targetId == '0') {
      AppToast.show(context, '举报失败：缺少对象信息');
      return;
    }
    setState(() {
      _actionBusy = true;
      _actionBusyMessage = '提交中';
    });
    try {
      await ref.read(reportServiceProvider).submitReport(
            targetType: targetType,
            targetId: targetId,
            reason: reason,
          );
      if (!mounted) return;
      setState(() => _actionBusy = false);
      AppToast.show(context, '举报已收到，我们将在 24 小时内处理');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _actionBusy = false);
      AppToast.show(context, e.msg.isEmpty ? '举报失败' : e.msg);
    } catch (_) {
      if (!mounted) return;
      setState(() => _actionBusy = false);
      AppToast.show(context, '举报失败');
    }
  }

  /// 拉黑前二次确认。iOS 参照：confirmBlockCounselor。
  Future<void> _confirmBlockCounselor() async {
    final confirmed = await AppCenterDialog.show(
      context,
      title: '拉黑 ${_name.isEmpty ? '该咨询师' : _name}',
      content: '拉黑后将不再接收对方消息，且会通知平台核查。确定拉黑吗？',
      cancelText: '取消',
      confirmText: '拉黑',
      confirmColor: AppColors.priceRed,
    );
    if (confirmed != true || !mounted) return;
    await _blockCounselor();
  }

  /// 执行拉黑。iOS 参照：blockCounselor。
  Future<void> _blockCounselor() async {
    final imUserId = _detail?.imUserId?.trim() ?? '';
    if (imUserId.isEmpty) {
      AppToast.show(context, '拉黑失败：缺少咨询师信息');
      return;
    }
    final consultantId = '${_detail?.consultantId ?? widget.consultantId}';
    setState(() {
      _actionBusy = true;
      _actionBusyMessage = '拉黑中';
    });
    try {
      await ref.read(reportServiceProvider).blockUser(
            imUserId: imUserId,
            consultantId: consultantId,
          );
      if (!mounted) return;
      setState(() => _actionBusy = false);
      AppToast.show(context, '已拉黑');
      ref.read(counselorBlockedTickProvider.notifier).state++;
      ref.invalidate(conversationListProvider);
      ref.read(imPeerBlockedTickProvider.notifier).state++;
      Navigator.of(context).maybePop();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _actionBusy = false);
      AppToast.show(context, e.msg.isEmpty ? '拉黑失败' : e.msg);
    } catch (_) {
      if (!mounted) return;
      setState(() => _actionBusy = false);
      AppToast.show(context, '拉黑失败');
    }
  }

  /// 服务总时长（totalServiceHours，展示为「5200+」）
  String get _serviceHours {
    final hours = _detail?.totalServiceHours;
    return hours == null ? '0+' : '$hours+';
  }

  /// 服务人次（serviceCount）
  String get _serviceCount => '${_detail?.serviceCount ?? 0}';

  /// 从业年限（experienceYears，单位「年」）
  String get _experienceYears => '${_detail?.experienceYears ?? 0}年';

  /// 底部咨询方式摘要（按 supportMode 映射为「文字/语音/视频」去重拼接 + 「支持」）
  /// iOS 参照：XYCounselorDetailViewModel.methods
  String get _methods {
    final seen = <String>{};
    final names = <String>[];
    for (final cap in _capabilities) {
      final name = switch (cap.supportMode) {
        '1' => '文字',
        '2' => '语音',
        '3' => '视频',
        _ => null,
      };
      if (name != null && seen.add(name)) names.add(name);
    }
    if (names.isEmpty) return '';
    return '${names.join('/')}支持';
  }

  /// 起步价文案数值（取所有咨询能力最低价，不含 ¥；无能力则空）
  /// iOS 参照：XYCounselorDetailViewModel.price
  String get _priceValue {
    final prices = _capabilities.map((c) => c.price).whereType<double>();
    if (prices.isEmpty) return '';
    return formatPrice(prices.reduce((a, b) => a < b ? a : b));
  }

  /// 认证资质列表（取 certifications 的证书名称）
  List<String> get _certifications => (_detail?.certifications ?? const [])
      .map((c) => c.certName)
      .whereType<String>()
      .where((s) => s.isNotEmpty)
      .toList();

  /// 评价总数（reviewStats.totalCount）
  int get _reviewCount => _detail?.reviewStats?.totalCount ?? 0;

  /// 仍有更多可加载：总数大于已加载且未到底。
  /// iOS 参照：hasMoreReviews / reviewsExhausted。
  bool get _hasMoreReviews =>
      !_reviewsExhausted && _reviewCount > _reviews.length;

  /// 点击「更多评价」拉取下一页。
  /// iOS 参照：loadMoreReviewsTapped + XYCounselorDetailViewModel.fetchReviews。
  Future<void> _loadMoreReviews() async {
    if (_reviewsExhausted || _loadingReviews) return;
    final consultantId = _detail?.consultantId ?? widget.consultantId;
    if (consultantId <= 0) return;
    setState(() => _loadingReviews = true);
    try {
      final page = (_reviews.length ~/ _reviewPageSize) + 1;
      final result = await ref.read(consultantApiProvider).fetchReviewList(
            consultantId: consultantId,
            pageNum: page,
            pageSize: _reviewPageSize,
          );
      if (!mounted) return;
      final existing = _reviews.map((r) => r.reviewId).whereType<int>().toSet();
      final newRows = result.rows.where((r) {
        final id = r.reviewId;
        return id == null || !existing.contains(id);
      }).toList();
      setState(() {
        _reviews = [..._reviews, ...newRows];
        if (result.rows.length < _reviewPageSize) {
          _reviewsExhausted = true;
        }
        _loadingReviews = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loadingReviews = false);
      AppToast.show(context, e.msg.isEmpty ? '加载失败' : e.msg);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingReviews = false);
      AppToast.show(context, '加载失败');
    }
  }

  /// 最近可约日期概览（按天聚合 recentAvailability → 星期/MM/dd/N个时段）
  /// iOS 参照：XYCounselorDetailViewModel.availableDateCards
  List<(String, String, String)> get _availableDateCards {
    final items = _detail?.recentAvailability ?? const [];
    final order = <String>[];
    final counts = <String, int>{};
    for (final item in items) {
      final key = item.availableDate ?? '';
      if (!counts.containsKey(key)) order.add(key);
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return order
        .map((key) => (
              weekdayText(key),
              shortDate(key),
              '${counts[key] ?? 0}个时段',
            ))
        .toList();
  }

  // ---------------- 页面骨架 ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      // iOS：gk_navBackgroundColor clear + gk_navLineHidden + 黑返回键；
      // 透明导航内嵌 body 顶部 + SafeArea（参照 06/07/10 页写法）
      body: Stack(
        children: [
          // 顶部渐变波浪背景（iOS setupTopBackground，bg_header_gradient）
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: _headerBackgroundHeight,
            child: LoadImage(
              AppAssets.bgHeaderGradient,
              fit: BoxFit.cover,
              errorWidget: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.pageGradient,
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                AppNavBar(
                  title: '咨询师主页',
                  transparent: true,
                  actions: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _moreTapped,
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: Center(
                          child: LoadImage(
                            AppAssets.navBarMore,
                            width: 24,
                            height: 24,
                            errorWidget: const Icon(
                              Icons.more_horiz,
                              size: 24,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Expanded(child: _buildBody()),
                _buildBottomBar(),
              ],
            ),
          ),
          if (_actionBusy)
            Positioned.fill(
              child: AppLoadingHud(message: _actionBusyMessage),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const AppLoadingView();
    if (_error != null) {
      return AppErrorView(message: _error!, onRetry: _fetchDetail);
    }
    return ListView(
      padding: const EdgeInsets.only(top: 6, bottom: 16),
      children: [
        _buildHeaderSection(),
        const SizedBox(height: _sectionSpacing),
        _buildIntroductionSection(),
        const SizedBox(height: _sectionSpacing),
        _buildQualificationsSection(),
        const SizedBox(height: _sectionSpacing),
        _buildAvailableTimeSection(),
        const SizedBox(height: _sectionSpacing),
        _buildReviewsSection(),
      ],
    );
  }

  /// 白色圆角卡片区块容器（iOS makeCardSection：左右 15）
  Widget _cardSection({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: _horizontalInset),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimens.cardRadius),
      ),
      child: child,
    );
  }

  // ---------------- 头部（iOS setupHeaderSection） ----------------

  Widget _buildHeaderSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _horizontalInset),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 咨询师资料白色卡片（投影 黑6% offset(0,4) blur 12）
          Container(
            margin: const EdgeInsets.only(top: 16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(_profileCardRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  offset: const Offset(0, 4),
                  blurRadius: 12,
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(
              _statsInnerInset,
              12,
              _statsInnerInset,
              _statsInnerInset,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 头像右侧：姓名行 + 标签流 + 职称（左缩进 = 头像左 10 + 头像宽 92
                // + 间距 12 - 卡片内边距 12，与 iOS nameRow.left = avatar.right + 12 对齐）
                Padding(
                  padding: const EdgeInsets.only(
                    left: _profileCardInnerPadding +
                        _headerAvatarSize +
                        12 -
                        _statsInnerInset,
                  ),
                  child: ConstrainedBox(
                    // 保证右栏内容至少覆盖头像探出卡片的区域
                    constraints: const BoxConstraints(minHeight: 80),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _nameRow(),
                        const SizedBox(height: 6),
                        _headerTagFlow(),
                        const SizedBox(height: 6),
                        Text(
                          _title,
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 17),
                _statsBox(),
              ],
            ),
          ),
          // 头像（92，白边 2.5，探出卡片顶 16）
          Positioned(
            top: 0,
            left: _profileCardInnerPadding,
            child: _headerAvatar(),
          ),
        ],
      ),
    );
  }

  /// 姓名 + 官方认证徽章（iOS nameRow：18 semibold + 16 徽章，间距 4）
  Widget _nameRow() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            _name,
            style: AppTextStyles.titleLarge,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (_isVerified) ...[
          const SizedBox(width: 4),
          LoadImage(
            AppAssets.icVerifiedBadge,
            width: 16,
            height: 16,
            errorWidget: const Icon(
              Icons.verified,
              size: 16,
              color: AppColors.funcPurple,
            ),
          ),
        ],
      ],
    );
  }

  /// 头部擅长（青）+ 风格（紫）混排标签流
  /// iOS 参照：headerTags（XYOrderTagFlowView：字号 11、内边距 6/3、圆角 3、间距 6）
  Widget _headerTagFlow() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final tag in _expertises)
          _smallTagChip(tag, AppColors.brandTeal, AppColors.brandTealLight),
        for (final tag in _styleTags)
          _smallTagChip(tag, AppColors.indigo, AppColors.purpleTagBg),
      ],
    );
  }

  Widget _smallTagChip(String text, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        text,
        style: AppTextStyles.label.copyWith(color: textColor),
      ),
    );
  }

  /// 头部头像（远程 URL 或占位图；iOS avatarIV：白边 2.5、#E8E8E8 底）
  Widget _headerAvatar() {
    return Container(
      width: _headerAvatarSize,
      height: _headerAvatarSize,
      decoration: BoxDecoration(
        color: AppColors.dividerDark,
        borderRadius: BorderRadius.circular(_headerAvatarSize / 2),
        border: Border.all(color: Colors.white, width: 2.5),
        image: _avatar.isNotEmpty
            ? DecorationImage(image: ImageUtils.getImageProvider(_avatar), fit: BoxFit.cover)
            : null,
      ),
      child: _avatar.isEmpty
          ? const Icon(
              Icons.person,
              size: 56,
              color: AppColors.avatarTintTeal,
            )
          : null,
    );
  }

  /// 统计数据渐变内框（#F9F7FE→#FDFDFE，圆角 12，高 74；iOS layoutStats）
  Widget _statsBox() {
    final stats = <(String, String)>[
      (_serviceHours, '服务时长(小时)'),
      (_serviceCount, '累计服务人次'),
      (_experienceYears, '从业经验'),
    ];
    return Container(
      height: _headerStatsHeight,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.statsGradientTop, AppColors.statsGradientBottom],
        ),
        borderRadius: BorderRadius.circular(AppDimens.cardRadius),
      ),
      child: Row(
        children: [
          for (var i = 0; i < stats.length; i++) ...[
            if (i > 0)
              Container(
                width: 1,
                // 列间竖线不撑满整栏（上下各 14，iOS statsSeparatorVerticalInset）
                margin: const EdgeInsets.symmetric(vertical: 14),
                color: AppColors.lightPurpleDivider,
              ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _statValue(stats[i].$1, stats[i].$2),
                  const SizedBox(height: 10),
                  Text(
                    stats[i].$2,
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 统计数值：从业经验为「数字(20 bold) + 年+(14 semibold)」；其余 20 bold
  /// iOS 参照：statValueAttributed（DIN 缺字体回退系统粗体）
  Widget _statValue(String value, String title) {
    if (title == '从业经验') {
      final years = value.replaceAll('年', '');
      return Text.rich(
        TextSpan(children: [
          TextSpan(
            text: years,
            style: AppTextStyles.titleXLarge.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          TextSpan(
            text: '年+',
            style: AppTextStyles.bodyLargeStrong.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ]),
      );
    }
    return Text(
      value,
      style: AppTextStyles.titleXLarge.copyWith(fontWeight: FontWeight.w700),
    );
  }

  // ---------------- 咨询师介绍（iOS setupIntroductionSection） ----------------

  Widget _buildIntroductionSection() {
    return _cardSection(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('咨询师介绍', style: AppTextStyles.title),
            const SizedBox(height: 12),
            Text(
              _detail?.introduction ?? '',
              style: AppTextStyles.body.copyWith(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- 认证资质 + 擅长领域 + 咨询风格 合并卡 ----------------
  // iOS 参照：setupQualificationsSection（同一张白卡，0.5pt #F0F0F0 分隔线分区）

  Widget _buildQualificationsSection() {
    return _cardSection(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('认证资质', style: AppTextStyles.title),
            const SizedBox(height: 12),
            for (final cert in _certifications) ...[
              _certItem(cert),
              if (cert != _certifications.last) const SizedBox(height: 12),
            ],
            const SizedBox(height: 16),
            _hairline(),
            const SizedBox(height: 16),
            const Text('擅长领域', style: AppTextStyles.title),
            const SizedBox(height: 12),
            _flowTags(
              _expertises,
              AppColors.brandTeal,
              AppColors.brandTealLight,
            ),
            const SizedBox(height: 16),
            _hairline(),
            const SizedBox(height: 16),
            const Text('咨询风格', style: AppTextStyles.title),
            const SizedBox(height: 12),
            _flowTags(
              _styleTags,
              AppColors.indigo,
              AppColors.purpleTagBg,
            ),
          ],
        ),
      ),
    );
  }

  /// 区块间分隔线（0.5pt #F0F0F0；iOS makeHairline）
  Widget _hairline() => Container(height: 0.5, color: AppColors.hairline);

  /// 单条认证资质（青色圆点 8 + 文案 12 #222，最多 2 行；iOS makeCertItem）
  Widget _certItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(top: 4),
          decoration: const BoxDecoration(
            color: AppColors.accentTeal,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// 彩色换行标签（字号 12、内边距 10/5、圆角 6、间距 8；iOS makeFlowTagView）
  Widget _flowTags(List<String> tags, Color textColor, Color bgColor) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final tag in tags)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              tag,
              style: AppTextStyles.caption.copyWith(color: textColor),
            ),
          ),
      ],
    );
  }

  // ---------------- 最近可约时间（iOS setupAvailableTimeSection） ----------------

  Widget _buildAvailableTimeSection() {
    final cards = _availableDateCards;
    return _cardSection(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: _horizontalInset,
              ),
              child: Row(
                children: [
                  const Text('最近可约时间', style: AppTextStyles.title),
                  const Spacer(),
                  _tealLinkButton(
                    title: '查看全部',
                    showChevron: true,
                    onTap: _presentAppointmentSheet,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: _timeCardHeight,
              child: cards.isEmpty
                  ? const Center(
                      child: Text('暂无可约时间', style: AppTextStyles.body),
                    )
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: _horizontalInset,
                      ),
                      itemCount: cards.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: AppDimens.gap10),
                      itemBuilder: (context, index) => _timeCard(cards[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// 单个可约时间卡片（星期/日期/时段数，110 宽，#F7F8FC 底圆角 10）
  /// iOS 参照：makeTimeCard
  Widget _timeCard((String, String, String) card) {
    return Container(
      width: _timeCardFixedWidth,
      decoration: BoxDecoration(
        color: AppColors.innerBackground,
        borderRadius: BorderRadius.circular(_methodCardRadius),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            card.$1,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(card.$2, style: AppTextStyles.titleSmall),
          const SizedBox(height: 6),
          Text(
            card.$3,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.accentTeal,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- 来访者评价（iOS setupReviewsSection） ----------------

  Widget _buildReviewsSection() {
    return _cardSection(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: _horizontalInset,
              ),
              child: Row(
                children: [
                  const Text('来访者评价', style: AppTextStyles.title),
                  const Spacer(),
                  Text(
                    '共 $_reviewCount 条评价',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: _horizontalInset,
              ),
              child: _reviews.isEmpty
                  ? const Center(
                      child: Text('暂无评价', style: AppTextStyles.body),
                    )
                  : Column(
                      children: [
                        for (var i = 0; i < _reviews.length; i++) ...[
                          if (i > 0) ...[
                            const SizedBox(height: 16),
                            _hairline(),
                            const SizedBox(height: 16),
                          ],
                          ReviewItemTile(
                            review: _reviews[i],
                            onReport: _reviews[i].reviewId == null
                                ? null
                                : () => _reportReview(_reviews[i].reviewId!),
                          ),
                        ],
                        const SizedBox(height: 16),
                        _reviewsFooter(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// 评价列表末尾：仍有更多 →「更多评价」内嵌分页；否则「暂无更多评价」。
  /// iOS 参照：populateReviewList / makeReviewFooter。
  Widget _reviewsFooter() {
    if (_hasMoreReviews) {
      return Center(
        child: _tealLinkButton(
          title: '更多评价',
          showChevron: true,
          onTap: _loadingReviews ? null : _loadMoreReviews,
        ),
      );
    }
    return Center(
      child: _tealLinkButton(
        title: '暂无更多评价',
        showChevron: false,
      ),
    );
  }

  /// 青色文字链接按钮（可选右箭头；iOS makeTealLinkButton：13pt #00BBC8）
  Widget _tealLinkButton({
    required String title,
    required bool showChevron,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: AppTextStyles.body.copyWith(color: AppColors.accentTeal),
          ),
          if (showChevron) ...[
            const SizedBox(width: 2),
            const Icon(
              Icons.chevron_right,
              size: 14,
              color: AppColors.accentTeal,
            ),
          ],
        ],
      ),
    );
  }

  // ---------------- 底部固定栏（iOS setupBottomBar） ----------------

  Widget _buildBottomBar() {
    final price = _priceValue;
    // iOS：bottomBar 贴屏幕底，top = safeArea.bottom - 70；
    // bottomContentView 高 70，安全区由底栏白底填满
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: const Border(
          top: BorderSide(color: AppColors.hairline, width: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEAEAEA).withValues(alpha: 0.4),
            offset: const Offset(0, -4),
            blurRadius: 4,
          ),
        ],
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SizedBox(
        height: _bottomContentHeight,
        child: Row(
          children: [
            const SizedBox(width: _horizontalInset),
            // 左侧：咨询方式摘要 + 起步价
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _methods,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text.rich(
                    TextSpan(children: [
                      TextSpan(text: '起步价 ', style: AppTextStyles.label),
                      TextSpan(
                        text: '¥',
                        style: AppTextStyles.title.copyWith(
                          color: AppColors.priceRed,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(
                        text: price,
                        style: AppTextStyles.titleXLarge.copyWith(
                          color: AppColors.priceRed,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ]),
                  ),
                ],
              ),
            ),
            // 查看排期并预约按钮（182×45 品牌渐变胶囊；iOS XYCounselorDetailViewController:1095）
            GestureDetector(
              onTap: _presentAppointmentSheet,
              child: Container(
                width: _bookButtonWidth,
                height: AppDimens.buttonHeight,
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius:
                      BorderRadius.circular(AppDimens.buttonRadiusCapsule),
                ),
                alignment: Alignment.center,
                child: Text(
                  '查看排期并预约',
                  style: AppTextStyles.title.copyWith(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: _horizontalInset),
          ],
        ),
      ),
    );
  }

  /// 「查看全部」与底部「查看排期并预约」共用：弹出排期预约弹层。
  /// iOS 参照：presentAppointmentSheet（无可约时间 → Toast「暂无可约时间」）。
  void _presentAppointmentSheet() {
    final detail = _detail;
    if (detail == null) return;
    if (detail.recentAvailability.isEmpty) {
      AppToast.show(context, '暂无可约时间');
      return;
    }
    showBookingSheet(
      context,
      viewModel: BookingViewModel(
        counselorName: _name,
        counselorTitle: _title,
        counselorImUserId: detail.imUserId ?? '',
        consultantId: detail.consultantId ?? widget.consultantId,
        availability: detail.recentAvailability,
        capabilities: detail.capabilities,
      ),
    );
  }
}
