import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';
import 'app_refresh_indicator.dart';
import 'app_states.dart';

/// 分页数据请求：pageNum 从 1 起，返回 rows 与 total。
typedef AppPagedFetcher<T> = Future<({List<T> rows, int total})> Function(
  int pageNum,
  int pageSize,
);

/// 泛型分页列表：下拉刷新 + 上拉加载更多。
/// iOS 参照：xinyuiOS MJRefresh 分页语义
/// （pageNum 从 1 起，pageSize 默认 10，按 total 判断是否还有下一页；
/// 无更多显示「没有更多了」12pt #999；空态 AppEmptyView；出错 AppErrorView 可重试）。
///
/// 外部可通过 `GlobalKey<AppPagedListViewState<T>>` 调用 [AppPagedListViewState.refresh]。
class AppPagedListView<T> extends StatefulWidget {
  const AppPagedListView({
    super.key,
    required this.fetcher,
    required this.itemBuilder,
    this.pageSize = 10,
    this.padding,
    this.separator,
    this.emptyWidget,
    this.errorMessage,
  });

  /// 分页请求
  final AppPagedFetcher<T> fetcher;

  /// 列表项构建
  final Widget Function(BuildContext context, T item, int index) itemBuilder;

  /// 每页条数，默认 10（MJRefresh 惯例）
  final int pageSize;

  /// 列表内边距
  final EdgeInsetsGeometry? padding;

  /// 列表项分隔组件，默认无分隔
  final Widget? separator;

  /// 自定义空态，默认 AppEmptyView
  final Widget? emptyWidget;

  /// 自定义错误文案，默认 AppErrorView 默认文案
  final String? errorMessage;

  @override
  State<AppPagedListView<T>> createState() => AppPagedListViewState<T>();
}

class AppPagedListViewState<T> extends State<AppPagedListView<T>> {
  final ScrollController _scrollController = ScrollController();
  final List<T> _items = [];

  int _total = 0;
  int _pageNum = 0; // 已加载到的页码
  bool _loading = true; // 仅首屏（无数据）加载中
  bool _loadingMore = false;
  Object? _error;

  /// 距底部多少像素内触发加载更多
  static const double _loadMoreTriggerExtent = 50;

  /// 底部加载指示尺寸
  static const double _footerLoaderSize = 18;

  /// 底部加载指示线宽
  static const double _footerLoaderStrokeWidth = 2;

  bool get _hasMore => _items.length < _total;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadFirstPage();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final ScrollPosition position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - _loadMoreTriggerExtent) {
      _loadMore();
    }
  }

  /// 外部主动刷新（等价于下拉刷新）
  Future<void> refresh() => _loadFirstPage();

  Future<void> _loadFirstPage() async {
    // 已有数据时保持列表 + RefreshIndicator，勿切全页 Loading（否则像没刷/闪一下）
    final keepList = _items.isNotEmpty;
    if (!keepList) {
      setState(() {
        _loading = true;
        _error = null;
      });
    } else {
      setState(() => _error = null);
    }
    try {
      final ({List<T> rows, int total}) result =
          await widget.fetcher(1, widget.pageSize);
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(result.rows);
        _total = result.total;
        _pageNum = 1;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loading || _loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final ({List<T> rows, int total}) result =
          await widget.fetcher(_pageNum + 1, widget.pageSize);
      if (!mounted) return;
      setState(() {
        _items.addAll(result.rows);
        _total = result.total;
        _pageNum += 1;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingMore = false;
        // 加载更多失败不清空已有数据，滚动到底部可再次触发重试
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 首屏加载中
    if (_loading && _items.isEmpty) {
      return const AppLoadingView();
    }
    // 首屏出错：错误文案 + 重试
    if (_error != null && _items.isEmpty) {
      return AppErrorView(
        message: widget.errorMessage ?? '加载失败，请稍后重试',
        onRetry: _loadFirstPage,
      );
    }
    // 空态
    if (_items.isEmpty) {
      return AppRefreshIndicator(
        onRefresh: _loadFirstPage,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: widget.emptyWidget ?? const AppEmptyView(),
            ),
          ],
        ),
      );
    }
    // 正常列表
    return AppRefreshIndicator(
      onRefresh: _loadFirstPage,
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: widget.padding,
        itemCount: _items.length + 1, // +1 为底部加载态
        separatorBuilder: (_, __) =>
            widget.separator ?? const SizedBox.shrink(),
        itemBuilder: (context, index) {
          if (index == _items.length) return _buildFooter();
          return widget.itemBuilder(context, _items[index], index);
        },
      ),
    );
  }

  /// 底部加载态：加载中转圈；无更多显示「没有更多了」12pt #999
  Widget _buildFooter() {
    if (_loadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppDimens.gap16),
        child: Center(
          child: SizedBox(
            width: _footerLoaderSize,
            height: _footerLoaderSize,
            child: CircularProgressIndicator(
              strokeWidth: _footerLoaderStrokeWidth,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.brandTeal),
            ),
          ),
        ),
      );
    }
    if (!_hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppDimens.gap16),
        child: Center(
          child: Text('没有更多了', style: AppTextStyles.caption),
        ),
      );
    }
    return const SizedBox(height: AppDimens.gap16);
  }
}
