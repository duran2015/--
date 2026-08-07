import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_response.dart';
import '../../core/router/route_paths.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_background.dart';
import '../../core/widgets/app_nav_bar.dart';
import '../../core/widgets/app_refresh_indicator.dart';
import '../../core/widgets/app_states.dart';
import '../../core/widgets/app_toast.dart';
import '../../utils/load_image.dart';
import 'home_models.dart';
import 'home_view_model.dart';

/// 全部测评列表状态。
/// iOS 参照：XYHomeAssessmentListViewModel（items / isFetching / isEmpty）。
class AssessmentListState {
  const AssessmentListState({
    this.items = const [],
    this.loading = false,
  });

  /// 列表数据
  final List<AssessmentListItem> items;

  /// 是否正在请求
  final bool loading;

  /// 列表是否为空
  bool get isEmpty => items.isEmpty;

  AssessmentListState copyWith({
    List<AssessmentListItem>? items,
    bool? loading,
  }) {
    return AssessmentListState(
      items: items ?? this.items,
      loading: loading ?? this.loading,
    );
  }
}

/// 全部测评列表 ViewModel。
/// iOS 参照：XYHomeAssessmentListViewModel.fetchList。
class AssessmentListViewModel extends Notifier<AssessmentListState> {
  @override
  AssessmentListState build() => const AssessmentListState();

  /// 拉取测评问卷列表（POST /app/assessment/list）。
  Future<void> fetchList({bool force = false}) async {
    if (!force && state.loading) return;
    state = state.copyWith(loading: true);
    try {
      final raw = await ref.read(homeApiProvider).fetchAssessmentList();
      final sorted = AssessmentMapper.sortedItems(raw);
      state = state.copyWith(
        items: sorted
            .map(AssessmentMapper.listItem)
            .whereType<AssessmentListItem>()
            .toList(),
        loading: false,
      );
    } catch (_) {
      state = state.copyWith(loading: false);
      rethrow;
    }
  }
}

final assessmentListViewModelProvider =
    NotifierProvider<AssessmentListViewModel, AssessmentListState>(
  AssessmentListViewModel.new,
);

/// 全部测评列表页（Figma 864:3069）。
/// iOS 参照：XYHomeAssessmentListViewController +
/// View/XYHomeAssessmentListCell.swift。
class AssessmentListPage extends ConsumerStatefulWidget {
  const AssessmentListPage({super.key});

  @override
  ConsumerState<AssessmentListPage> createState() =>
      _AssessmentListPageState();
}

class _AssessmentListPageState extends ConsumerState<AssessmentListPage> {
  @override
  void initState() {
    super.initState();
    // iOS viewWillAppear(isMovingToParent)：首次进入带 loading 拉取
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadList());
  }

  Future<void> _loadList() async {
    try {
      await ref.read(assessmentListViewModelProvider.notifier).fetchList();
    } on ApiException catch (e) {
      if (!mounted) return;
      AppToast.show(context, e.msg);
    }
  }

  /// 下拉刷新（iOS mj_header：force 拉取，失败 Toast）
  Future<void> _onRefresh() async {
    try {
      await ref
          .read(assessmentListViewModelProvider.notifier)
          .fetchList(force: true);
    } on ApiException catch (e) {
      if (!mounted) return;
      AppToast.show(context, e.msg);
    }
  }

  /// 处理测评操作：未测「去测试」开答题 H5，已测「看结果」开测评报告页。
  /// iOS 参照：XYHomeAssessmentWebOpener.open。
  /// 返回后静默刷新列表（iOS viewWillAppear 从子页返回时静默刷新）。
  Future<void> _handleAction(AssessmentListItem item) async {
    final String location;
    if (item.status == AssessmentStatus.tested) {
      location =
          '${RoutePaths.assessmentReport}?assessmentId=${item.userAssessId ?? ''}'
          '&title=${Uri.encodeComponent(item.title)}'
          '&h5Link=${Uri.encodeComponent(item.h5Link ?? '')}';
    } else {
      final link = item.h5Link?.trim() ?? '';
      if (link.isEmpty) {
        AppToast.show(context, '链接无效');
        return;
      }
      location = '${RoutePaths.webview}?url=${Uri.encodeComponent(link)}'
          '&title=${Uri.encodeComponent(item.title)}&mode=assessment';
    }
    await context.push(location);
    if (!mounted) return;
    try {
      await ref
          .read(assessmentListViewModelProvider.notifier)
          .fetchList(force: true);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assessmentListViewModelProvider);

    return Scaffold(
      // iOS：XYOrderBackgroundView + 透明导航栏，标题「全部测评」
      body: AppPageBackground(
        child: SafeArea(
          child: Column(
            children: [
              const AppNavBar(title: '全部测评', transparent: true),
              Expanded(
                child: state.loading && state.isEmpty
                    ? const AppLoadingView()
                    : (!state.loading && state.isEmpty)
                        // 空态：「暂无测评」15 #999 居中
                        ? const Center(
                            child: Text(
                              '暂无测评',
                              style: TextStyle(
                                fontSize: 15,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          )
                        : AppRefreshIndicator(
                            onRefresh: _onRefresh,
                            child: ListView.builder(
                              physics:
                                  const AlwaysScrollableScrollPhysics(),
                              // iOS contentInset：top 6 / bottom 20
                              padding: const EdgeInsets.only(
                                top: AppDimens.gap6,
                                bottom: AppDimens.gap20,
                              ),
                              itemCount: state.items.length,
                              itemBuilder: (context, index) {
                                final item = state.items[index];
                                return _AssessmentListCell(
                                  item: item,
                                  onTap: () => _handleAction(item),
                                );
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 全部测评列表卡片 Cell。
/// iOS 参照：XYHomeAssessmentListCell
/// （卡片 94 高圆角 16，图标 48，操作按钮 70×32 圆角 16：
/// 未测渐变「去测试」/ 已测浅底青字「看结果」）。
class _AssessmentListCell extends StatelessWidget {
  const _AssessmentListCell({required this.item, required this.onTap});

  final AssessmentListItem item;
  final VoidCallback onTap;

  /// 卡片高（iOS cardHeight 94）
  static const double _cardHeight = 94;

  /// 卡片间距（iOS cardGap 10）
  static const double _cardGap = 10;

  /// 图标尺寸（iOS iconSize 48）
  static const double _iconSize = 48;

  /// 操作按钮宽/高（iOS actionWidth 70 / actionHeight 32）
  static const double _actionWidth = 70;
  static const double _actionHeight = 32;

  /// 已测按钮底/字色（iOS testedBackground #E9FAFF / testedText #00A6A1）
  static const Color _testedBackground = Color(0xFFE9FAFF);
  static const Color _testedText = Color(0xFF00A6A1);

  /// 未测按钮渐变（iOS brandGradient，start 色在右）
  static const LinearGradient _actionGradient = LinearGradient(
    begin: Alignment.centerRight,
    end: Alignment.centerLeft,
    colors: [AppColors.brandGradientStart, AppColors.brandGradientEnd],
  );

  @override
  Widget build(BuildContext context) {
    final tested = item.status == AssessmentStatus.tested;
    final localIcon = assessmentLocalListIcon(item.questionnaireKey);

    return Padding(
      padding: const EdgeInsets.only(
        left: AppDimens.screenPadding,
        right: AppDimens.screenPadding,
        bottom: _cardGap,
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: _cardHeight,
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(AppDimens.cardRadiusLarge),
            // iOS：#E4E4E4 @30%，offset(0,2)，blur 10
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE4E4E4).withValues(alpha: 0.3),
                offset: const Offset(0, 2),
                blurRadius: 10,
              ),
            ],
          ),
          padding:
              const EdgeInsets.symmetric(horizontal: AppDimens.cardPadding),
          child: Row(
            children: [
              // 图标 48（接口 icon 优先，缺省本地占位图）
              _buildIcon(localIcon),
              const SizedBox(width: AppDimens.gap12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 标题 16 w600 #222（iOS top 18）
                    Text(
                      item.title,
                      style: AppTextStyles.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppDimens.gap6),
                    // 副标题 12 #999
                    Text(
                      item.subtitle,
                      style: AppTextStyles.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppDimens.gap8),
                    // 题目数 + 已测人数 12 #666（间距 12）
                    Row(
                      children: [
                        Text(
                          item.questionCountText,
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(width: AppDimens.gap12),
                        Text(
                          item.participantText,
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDimens.gap8),
              // 操作按钮 70×32 圆角 16
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onTap,
                child: Container(
                  width: _actionWidth,
                  height: _actionHeight,
                  decoration: BoxDecoration(
                    gradient: tested ? null : _actionGradient,
                    color: tested ? _testedBackground : null,
                    borderRadius:
                        BorderRadius.circular(AppDimens.cardRadiusLarge),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    item.actionTitle,
                    style: AppTextStyles.body.copyWith(
                      color: tested ? _testedText : Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(String? localIcon) {
    final iconUrl = item.iconUrl;
    if (iconUrl != null && iconUrl.isNotEmpty) {
      return LoadImage(
        iconUrl,
        width: _iconSize,
        height: _iconSize,
        fit: BoxFit.contain,
        errorWidget: _localIcon(localIcon),
      );
    }
    return _localIcon(localIcon);
  }

  Widget _localIcon(String? asset) {
    if (asset == null) {
      return const SizedBox(width: _iconSize, height: _iconSize);
    }
    return LoadImage(
      asset,
      width: _iconSize,
      height: _iconSize,
      fit: BoxFit.contain,
    );
  }
}
