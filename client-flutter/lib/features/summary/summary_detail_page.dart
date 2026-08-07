import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_background.dart';
import '../../core/widgets/app_nav_bar.dart';
import '../../core/widgets/app_states.dart';
import '../../core/widgets/app_toast.dart';
import '../../utils/image_utils.dart';
import '../../utils/load_image.dart';
import '../order/order_models.dart';
import 'summary_api.dart';
import 'summary_models.dart';

/// 小结与建议详情页（路由 /summary/detail，深链 1007，参数 orderId）。
/// iOS 参照：XYMessageModule/XYMessageModule/Classes/ViewController/
/// XYSummaryAdviseViewController.swift（Figma 457:2642）——
/// 本次咨询回顾（标题+时间）→ 咨询师半透明面板（叠于小结卡之上）
/// → 咨询师小结（白卡 + #F7F8FC 内文框）→ 行动建议与练习（白卡 + 序号徽标条目）。
class SummaryDetailPage extends ConsumerStatefulWidget {
  const SummaryDetailPage({super.key, required this.orderId});

  final int? orderId;

  @override
  ConsumerState<SummaryDetailPage> createState() => _SummaryDetailPageState();
}

class _SummaryDetailPageState extends ConsumerState<SummaryDetailPage> {
  SummaryAdviseDetail? _detail;
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// 拉取小结详情（iOS 参照：loadDetail）。
  Future<void> _load() async {
    final orderId = widget.orderId;
    if (orderId == null || orderId <= 0) {
      setState(() {
        _loading = false;
        _error = '订单信息无效';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final detail = await ref.read(summaryApiProvider).fetchDetail(orderId);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
      AppToast.show(context, '加载失败，请稍后重试');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      // XYOrderBackgroundView + 透明导航栏；滚动区贴屏幕底
      body: AppPageBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const AppNavBar(title: '小结与建议详情', transparent: true),
              Expanded(child: _buildBody(bottomInset)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody([double bottomInset = 0]) {
    if (_loading) return const AppLoadingView();
    if (_error != null || _detail == null) {
      return AppErrorView(onRetry: _load);
    }
    final detail = _detail!;
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(15, 15, 15, 15 + bottomInset),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _headerSection(detail),
          const SizedBox(height: 15),
          _consultantSummaryUnit(detail),
          if (detail.validAdvice.isNotEmpty) ...[
            const SizedBox(height: 10),
            _adviceCard(detail),
          ],
          if ((detail.nextDirection ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            _nextDirectionCard(detail.nextDirection!.trim()),
          ],
        ],
      ),
    );
  }

  /// 「本次咨询回顾」标题 + 咨询时间 + 方式/时长（直接铺背景，无卡片）。
  /// iOS 参照：buildHeaderSection（标题 20 semibold，日期/方式 12 #666）。
  Widget _headerSection(SummaryAdviseDetail detail) {
    final dateText = detail.dateText;
    final modeText = detail.supportModeText?.trim() ?? '';
    final duration = detail.duration ?? 0;
    final parts = <String>[
      if (modeText.isNotEmpty) modeText,
      if (duration > 0) '$duration分钟',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('本次咨询回顾', style: AppTextStyles.titleXLarge),
        if (dateText.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                dateText,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              if (parts.isNotEmpty) ...[
                const SizedBox(width: 12),
                LoadImage(
                  methodIconAsset(detail.supportMode),
                  width: 12,
                  height: 12,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  parts.join(' '),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  /// 叠层单元：咨询师半透明面板浮于白色小结卡顶部（面板高 77，压小结卡 8）。
  /// iOS 参照：buildConsultantSummaryUnit。
  Widget _consultantSummaryUnit(SummaryAdviseDetail detail) {
    const panelHeight = 77.0;
    const panelOverlap = 8.0;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 小结卡（底层，顶部让出面板高度 - 重叠量）
        Padding(
          padding: const EdgeInsets.only(top: panelHeight - panelOverlap),
          child: _summaryCard(detail),
        ),
        // 咨询师半透明面板（顶层）
        _consultantPanel(detail, panelHeight),
      ],
    );
  }

  /// 咨询师半透明面板：白渐变（顶 0.6 → 底 0.2）+ 顶部圆角 16 + 白边，
  /// 内容：头像 40 + 「咨询师：姓名」15 semibold + 职称 11 #999。
  /// iOS 参照：ConsultantPanel + makeConsultantPanel。
  Widget _consultantPanel(SummaryAdviseDetail detail, double height) {
    final name = detail.consultantName?.trim() ?? '';
    final title = detail.consultantTitle?.trim() ?? '';
    final avatarUrl = detail.consultantAvatar;
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.6),
            Colors.white.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: Row(
        children: [
          const SizedBox(width: 15),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(20),
              image: hasAvatar
                  ? DecorationImage(
                      image: ImageUtils.getImageProvider(avatarUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: hasAvatar
                ? null
                : const Icon(Icons.person,
                    size: 24, color: AppColors.placeholder),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name.isEmpty ? '咨询师' : '咨询师：$name',
                style: AppTextStyles.titleSmall,
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: AppTextStyles.label.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 「咨询师小结」白卡：标题 15 semibold + #F7F8FC 内文框（13 #222，行距 7）。
  /// iOS 参照：makeSummaryCard。
  Widget _summaryCard(SummaryAdviseDetail detail) {
    final content = detail.content?.trim() ?? '';
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimens.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 15),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 15),
            child: Text('写给你的寄语与回顾', style: AppTextStyles.titleSmall),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(15, 0, 15, 15),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.innerBackground,
              borderRadius: BorderRadius.circular(AppDimens.radiusInner),
            ),
            child: content.isEmpty
                ? Text(
                    '暂无小结内容',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  )
                : Text(
                    content,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textPrimary,
                      height: 1.5, // 行间距约 7（13 号 × 1.5 ≈ 19.5）
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// 「行动建议与练习」白卡：标题 + 各建议条目（#F7F8FC 内框 + 青色序号徽标）。
  /// iOS 参照：buildAdviceCard / makeAdviceItem。
  Widget _adviceCard(SummaryAdviseDetail detail) {
    final advice = detail.validAdvice;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimens.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('推荐会后行动', style: AppTextStyles.titleSmall),
          const SizedBox(height: 10),
          for (var i = 0; i < advice.length; i++) ...[
            _adviceItem(i, advice[i]),
            if (i < advice.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Widget _nextDirectionCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimens.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('下次探讨方向', style: AppTextStyles.titleSmall),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.innerBackground,
              borderRadius: BorderRadius.circular(AppDimens.radiusInner),
            ),
            child: Text(
              text,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 单条建议内框：青色圆形序号徽标 22（11 semibold 白字）+ 正文 14 #333。
  Widget _adviceItem(int index, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.innerBackground,
        borderRadius: BorderRadius.circular(AppDimens.radiusInner),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: AppColors.brandTeal,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '${index + 1}',
              style: AppTextStyles.label.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodyLarge.copyWith(
                color: const Color(0xFF333333),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
