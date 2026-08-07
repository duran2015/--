import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// 统一下拉刷新（对齐 iOS MJRefreshHeader）。
///
/// - 触发阈值 [triggerDistance] 默认 60
/// - 仅在手指拖拽中进入 armed（对齐 MJRefresh 的 `isDragging` 判断），
///   避免松手后惯性继续 overscroll 导致「拉一点点就刷新」
class AppRefreshIndicator extends StatefulWidget {
  const AppRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
    this.triggerDistance = 60,
    this.indicatorExtent = 44,
  });

  /// 刷新回调（组件内会保证最短展示时长，便于感知）
  final Future<void> Function() onRefresh;

  final Widget child;

  /// 触发刷新所需的顶部 overscroll（逻辑像素）
  final double triggerDistance;

  /// 刷新中指示器占位高度
  final double indicatorExtent;

  /// 最短转圈时长，避免接口过快时「闪一下像没刷新」
  static const Duration _minVisible = Duration(milliseconds: 600);

  @override
  State<AppRefreshIndicator> createState() => _AppRefreshIndicatorState();
}

enum _RefreshStatus { idle, drag, armed, refresh }

class _AppRefreshIndicatorState extends State<AppRefreshIndicator> {
  _RefreshStatus _status = _RefreshStatus.idle;
  double _dragOffset = 0;

  double get _progress =>
      (_dragOffset / widget.triggerDistance).clamp(0.0, 1.5);

  bool _atTop(ScrollMetrics metrics) =>
      metrics.axis == Axis.vertical && metrics.extentBefore <= 0.0;

  /// 顶部橡皮筋 / 边界外的实际下拉量（用户看得见的位移）。
  double _overscrollOf(ScrollMetrics metrics) {
    if (!_atTop(metrics)) return 0;
    // Bounce：pixels < 0；Clamping：pixels 仍为 0，靠 OverscrollNotification。
    return math.max(0.0, -metrics.pixels);
  }

  bool _shouldStart(ScrollNotification notification) {
    if (_status != _RefreshStatus.idle) return false;
    if (notification is! ScrollStartNotification &&
        notification is! ScrollUpdateNotification &&
        notification is! OverscrollNotification) {
      return false;
    }
    final dragDetails = switch (notification) {
      ScrollStartNotification(:final dragDetails) => dragDetails,
      ScrollUpdateNotification(:final dragDetails) => dragDetails,
      OverscrollNotification(:final dragDetails) => dragDetails,
      _ => null,
    };
    if (dragDetails == null) return false;
    return _atTop(notification.metrics);
  }

  void _applyPull(double pull, {required bool fingerDown}) {
    _dragOffset = pull.clamp(0.0, widget.triggerDistance * 2.5);
    // 对齐 MJRefresh：仅在 isDragging 时进入/退出 Pulling；
    // 松手后的惯性加深 overscroll 不得新武装，否则「拉一点点 + 惯性」也会刷新。
    if (!fingerDown) return;
    if (_dragOffset >= widget.triggerDistance) {
      _status = _RefreshStatus.armed;
    } else {
      _status = _RefreshStatus.drag;
    }
  }

  Future<void> _showRefresh() async {
    if (_status == _RefreshStatus.refresh) return;
    setState(() {
      _status = _RefreshStatus.refresh;
      _dragOffset = widget.indicatorExtent;
    });
    final started = DateTime.now();
    try {
      await widget.onRefresh();
    } catch (_) {}
    final elapsed = DateTime.now().difference(started);
    if (elapsed < AppRefreshIndicator._minVisible) {
      await Future<void>.delayed(AppRefreshIndicator._minVisible - elapsed);
    }
    if (!mounted) return;
    setState(() {
      _status = _RefreshStatus.idle;
      _dragOffset = 0;
    });
  }

  void _cancel() {
    if (_status == _RefreshStatus.refresh) return;
    setState(() {
      _status = _RefreshStatus.idle;
      _dragOffset = 0;
    });
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification.depth > 0) return false;
    if (notification.metrics.axis != Axis.vertical) return false;

    if (_shouldStart(notification)) {
      setState(() {
        _status = _RefreshStatus.drag;
        _dragOffset = _overscrollOf(notification.metrics);
      });
      return false;
    }

    if (!_atTop(notification.metrics) &&
        (_status == _RefreshStatus.drag || _status == _RefreshStatus.armed)) {
      // 已武装则本趟手势仍应刷新（避免回弹/惯性滚走取消）
      if (_status == _RefreshStatus.armed) {
        _showRefresh();
      } else {
        _cancel();
      }
      return false;
    }

    if (notification is ScrollUpdateNotification) {
      if (_status == _RefreshStatus.drag || _status == _RefreshStatus.armed) {
        final fingerDown = notification.dragDetails != null;
        final fromPixels = _overscrollOf(notification.metrics);
        if (fromPixels > 0) {
          setState(() => _applyPull(fromPixels, fingerDown: fingerDown));
        } else if (notification.scrollDelta != null && fingerDown) {
          // Android clamping：顶边 pixels 仍为 0，用 delta 累计
          setState(
            () => _applyPull(
              _dragOffset - notification.scrollDelta!,
              fingerDown: true,
            ),
          );
        }
        // 松手后首次无 dragDetails 的更新：若已武装则立刻刷新
        if (_status == _RefreshStatus.armed && !fingerDown) {
          _showRefresh();
        }
      }
    } else if (notification is OverscrollNotification) {
      if (_status == _RefreshStatus.drag || _status == _RefreshStatus.armed) {
        // Clamping 边界外增量（overscroll 为负表示顶部下拉）
        if (notification.dragDetails != null) {
          setState(
            () => _applyPull(
              _dragOffset - notification.overscroll,
              fingerDown: true,
            ),
          );
        }
      }
    } else if (notification is ScrollEndNotification) {
      switch (_status) {
        case _RefreshStatus.armed:
          _showRefresh();
        case _RefreshStatus.drag:
          _cancel();
        case _RefreshStatus.idle:
        case _RefreshStatus.refresh:
          break;
      }
    }
    return false;
  }

  bool _onIndicatorNotification(OverscrollIndicatorNotification notification) {
    if (notification.depth != 0 || !notification.leading) return false;
    if (_status == _RefreshStatus.drag || _status == _RefreshStatus.armed) {
      notification.disallowIndicator();
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final refreshing = _status == _RefreshStatus.refresh;
    final dragging =
        _status == _RefreshStatus.drag || _status == _RefreshStatus.armed;
    final showHeader = refreshing || (dragging && _dragOffset > 2);
    // 指示器始终浮层绘制，绝不给 child 加 top padding。
    // 否则松手进入 refresh 时 padding 与 iOS 橡皮筋回弹叠加，会先下沉再弹回。
    final headerHeight = refreshing
        ? widget.indicatorExtent
        : math.min(_dragOffset, widget.indicatorExtent);
    final progress = _progress.clamp(0.0, 1.0);

    return NotificationListener<OverscrollIndicatorNotification>(
      onNotification: _onIndicatorNotification,
      child: NotificationListener<ScrollNotification>(
        onNotification: _onScrollNotification,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned.fill(child: widget.child),
            if (showHeader)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: math.max(headerHeight, 28),
                child: IgnorePointer(
                  child: Center(
                    child: refreshing
                        ? const CupertinoActivityIndicator(
                            radius: 11,
                            color: AppColors.brandTeal,
                          )
                        : Opacity(
                            opacity: progress.clamp(0.25, 1.0),
                            child: CupertinoActivityIndicator.partiallyRevealed(
                              progress: progress,
                              radius: 11,
                              color: AppColors.brandTeal,
                            ),
                          ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
