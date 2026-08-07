import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../utils/load_image.dart';
import '../home_models.dart';

/// 首页「最近 7 天情绪」卡片：折叠态为 7 日情绪行，展开态为月历。
/// iOS 参照：XYHomeModule/Classes/View/XYHomeMoodCardView.swift。
class HomeMoodCard extends StatefulWidget {
  const HomeMoodCard({
    super.key,
    required this.moods,
    required this.monthMoodsOf,
    required this.initialYear,
    required this.initialMonth,
    required this.onRequestMonth,
    this.onRecordToday,
  });

  /// 最近 7 天情绪（本周日至周六）
  final List<MoodDay> moods;

  /// 按年月取月历情绪（由 ViewModel 提供）
  final List<MonthMood> Function(int year, int month) monthMoodsOf;

  /// 初始展示年月（服务端当前年月）
  final int initialYear;
  final int initialMonth;

  /// 请求指定年月月历数据（展开/翻页时调用，完成后重建）
  final Future<void> Function(int year, int month) onRequestMonth;

  /// 点击「今天」情绪回调
  final VoidCallback? onRecordToday;

  /// 折叠态 7 日行高度（iOS collapsedBodyHeight）
  static const double collapsedBodyHeight = 62;

  /// 月历内容区高度（iOS XYHomeMoodCalendarView.contentHeight：
  /// 24 + 14 + 16 + 8 + (6*50 + 5*2)）
  static const double calendarContentHeight =
      24 + 14 + 16 + 8 + (6 * 50 + 5 * 2);

  @override
  State<HomeMoodCard> createState() => _HomeMoodCardState();
}

class _HomeMoodCardState extends State<HomeMoodCard> {
  /// 当前是否展开月历
  bool _isExpanded = false;

  void _toggleExpanded() {
    final willExpand = !_isExpanded;
    setState(() => _isExpanded = willExpand);
    if (willExpand) {
      // 展开时拉取当前展示月数据（iOS requestDataForDisplayedMonth）
      widget.onRequestMonth(widget.initialYear, widget.initialMonth);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          // 标题行：高 22（iOS header height 22）
          SizedBox(
            height: 22,
            child: Row(
              children: [
                // 「最近7天」#222 + 「情绪」brandTeal，16 w600
                Text.rich(
                  TextSpan(
                    text: '最近7天',
                    style: AppTextStyles.title,
                    children: const [
                      TextSpan(
                        text: '情绪',
                        style: TextStyle(color: AppColors.brandTeal),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                _ExpandButton(
                  expanded: _isExpanded,
                  onTap: _toggleExpanded,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimens.gap12),
          // 折叠/展开内容（iOS animateBodyHeight 0.25s）
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: _isExpanded
                ? MoodCalendarView(
                    key: const ValueKey('moodCalendar'),
                    initialYear: widget.initialYear,
                    initialMonth: widget.initialMonth,
                    monthMoodsOf: widget.monthMoodsOf,
                    onRequestMonth: widget.onRequestMonth,
                    onRecordToday: widget.onRecordToday,
                  )
                : SizedBox(
                    key: const ValueKey('moodWeekRow'),
                    height: HomeMoodCard.collapsedBodyHeight,
                    child: _WeekRow(
                      moods: widget.moods,
                      onRecordToday: widget.onRecordToday,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// 「展开日历 / 收起日历」按钮。
/// iOS 参照：XYHomeMoodCardView.applyExpandButtonStyle
/// （浅底 #E9FAFF 圆角 11，图标 + 11pt brandTeal 文案，间距 4，L10 R14）。
class _ExpandButton extends StatelessWidget {
  const _ExpandButton({required this.expanded, required this.onTap});

  final bool expanded;
  final VoidCallback onTap;

  /// 按钮高（iOS expandButton height 22）
  static const double _height = 22;

  /// 日历图标尺寸
  static const double _iconSize = 12;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: _height,
        padding: const EdgeInsets.only(left: 10, right: 14),
        decoration: BoxDecoration(
          color: AppColors.brandTealLight, // #E9FAFF
          borderRadius: BorderRadius.circular(_height / 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            LoadImage(
              AppAssets.homeCalendarIcon,
              width: _iconSize,
              height: _iconSize,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: AppDimens.gap4),
            Text(
              expanded ? '收起日历' : '展开日历',
              style: AppTextStyles.label.copyWith(color: AppColors.brandTeal),
            ),
          ],
        ),
      ),
    );
  }
}

/// 折叠态：7 日情绪行（fillEqually）。
/// iOS 参照：XYHomeMoodCardView.makeMoodColumn。
class _WeekRow extends StatelessWidget {
  const _WeekRow({required this.moods, this.onRecordToday});

  final List<MoodDay> moods;
  final VoidCallback? onRecordToday;

  /// 7 日情绪列表图标（iOS moodListIconSize 20）
  static const double _iconSize = 20;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final mood in moods)
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: mood.isRecordable ? onRecordToday : null,
              child: Column(
                children: [
                  // 星期 11 #999（height 1.2 对齐 iOS 单行标签行高，避免字体差异溢出）
                  Text(
                    mood.weekday,
                    style: AppTextStyles.label.copyWith(height: 1.2),
                  ),
                  const SizedBox(height: AppDimens.gap6),
                  // 情绪图标 20
                  if (mood.iconAsset != null)
                    LoadImage(
                      mood.iconAsset!,
                      width: _iconSize,
                      height: _iconSize,
                      fit: BoxFit.contain,
                      errorWidget: const SizedBox(
                        width: _iconSize,
                        height: _iconSize,
                      ),
                    )
                  else
                    const SizedBox(width: _iconSize, height: _iconSize),
                  const SizedBox(height: AppDimens.gap6),
                  // 情绪文字 12：今天「今天？」青绿；无记录「-」#999；其余 #222
                  Text(
                    mood.title ?? (mood.isToday ? '' : '-'),
                    style: AppTextStyles.caption.copyWith(
                      color: _titleColor(mood),
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Color _titleColor(MoodDay mood) {
    // iOS：isToday && title == "今天？" → brandTeal；title == "-" → #999；其他 #222
    if (mood.isToday && mood.title == '今天？') return AppColors.brandTeal;
    if (mood.title == null && !mood.isToday) return AppColors.textTertiary;
    return AppColors.textPrimary;
  }
}

/// 首页情绪卡展开后的月历视图：可查看历史月份，当前月为最后一月（不可往后翻）。
/// iOS 参照：XYHomeModule/Classes/View/XYHomeMoodCalendarView.swift。
class MoodCalendarView extends StatefulWidget {
  const MoodCalendarView({
    super.key,
    required this.initialYear,
    required this.initialMonth,
    required this.monthMoodsOf,
    required this.onRequestMonth,
    this.onRecordToday,
  });

  final int initialYear;
  final int initialMonth;

  /// 按年月取月历情绪
  final List<MonthMood> Function(int year, int month) monthMoodsOf;

  /// 请求指定年月月历数据
  final Future<void> Function(int year, int month) onRequestMonth;

  /// 点「今天」回调
  final VoidCallback? onRecordToday;

  /// 星期行标签（周日为首）
  static const List<String> weekdayLabels = ['日', '一', '二', '三', '四', '五', '六'];

  /// 单元圆圈直径（iOS circleSize）
  static const double circleSize = 32;

  /// 单元行高（iOS 6*50+5*2 → 行 50、间距 2）
  static const double rowHeight = 50;
  static const double rowSpacing = 2;

  @override
  State<MoodCalendarView> createState() => _MoodCalendarViewState();
}

class _MoodCalendarViewState extends State<MoodCalendarView> {
  late int _year = widget.initialYear;
  late int _month = widget.initialMonth;

  /// 今日（服务端时间在 ViewModel 层对齐，此处展示用本地当天即可）
  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// 是否正在查看当前月（最后一月，不可往后翻）。
  bool get _isViewingCurrentMonth =>
      _year == _today.year && _month == _today.month;

  Future<void> _prevMonth() async {
    setState(() {
      _month -= 1;
      if (_month < 1) {
        _month = 12;
        _year -= 1;
      }
    });
    await widget.onRequestMonth(_year, _month);
    if (mounted) setState(() {});
  }

  Future<void> _nextMonth() async {
    if (_isViewingCurrentMonth) return;
    setState(() {
      _month += 1;
      if (_month > 12) {
        _month = 1;
        _year += 1;
      }
      // clampToCurrentMonthIfNeeded：最多翻到当前月
      if (_year * 12 + _month > _today.year * 12 + _today.month) {
        _year = _today.year;
        _month = _today.month;
      }
    });
    await widget.onRequestMonth(_year, _month);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: HomeMoodCard.calendarContentHeight,
      child: Column(
        children: [
          // 年月头：高 24
          SizedBox(
            height: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _MonthNavButton(
                  icon: Icons.chevron_left,
                  onTap: _prevMonth,
                ),
                const SizedBox(width: AppDimens.gap16),
                Text(
                  '$_year年$_month月',
                  style: AppTextStyles.titleSmall,
                ),
                const SizedBox(width: AppDimens.gap16),
                // 当前月隐藏右侧按钮（保持占位，标题始终居中）
                Visibility(
                  visible: !_isViewingCurrentMonth,
                  maintainSize: true,
                  maintainAnimation: true,
                  maintainState: true,
                  child: _MonthNavButton(
                    icon: Icons.chevron_right,
                    onTap: _nextMonth,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimens.gap14),
          // 星期行：高 16，12 #999
          SizedBox(
            height: 16,
            child: Row(
              children: [
                for (final name in MoodCalendarView.weekdayLabels)
                  Expanded(
                    child: Center(
                      child: Text(name, style: AppTextStyles.caption),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppDimens.gap8),
          // 日期网格：6 行 × 7 列，行高 50 间距 2
          SizedBox(
            height: 6 * MoodCalendarView.rowHeight +
                5 * MoodCalendarView.rowSpacing,
            child: Column(
              children: [
                for (var row = 0; row < 6; row++) ...[
                  if (row > 0)
                    const SizedBox(height: MoodCalendarView.rowSpacing),
                  Expanded(child: _buildRow(row)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(int row) {
    final cells = _buildCells();
    return Row(
      children: [
        for (var col = 0; col < 7; col++) ...[
          if (col > 0) const SizedBox(width: MoodCalendarView.rowSpacing),
          Expanded(child: _buildDayCell(cells[row * 7 + col])),
        ],
      ],
    );
  }

  /// 计算当前年月 42 格（含上月末尾与下月开头的补位）。
  /// iOS 参照：XYHomeMoodCalendarView.buildCells。
  List<_CellData> _buildCells() {
    final moodMap = {
      for (final m in widget.monthMoodsOf(_year, _month)) m.day: m.iconAsset,
    };

    final firstOfMonth = DateTime(_year, _month, 1);
    // Dart weekday：Mon=1…Sun=7；周日为首时前置占位 = weekday % 7
    final leading = firstOfMonth.weekday % 7;
    final daysInMonth = DateTime(_year, _month + 1, 0).day;
    final daysInPrevMonth = DateTime(_year, _month, 0).day;

    final isViewingTodayMonth =
        _today.year == _year && _today.month == _month;
    final todayDay = isViewingTodayMonth ? _today.day : 1 << 31;

    final cells = <_CellData>[];
    for (var i = 0; i < leading; i++) {
      cells.add(_CellData(
        day: daysInPrevMonth - leading + 1 + i,
        isInMonth: false,
      ));
    }
    for (var day = 1; day <= daysInMonth; day++) {
      final isFuture = day > todayDay;
      final icon = isFuture ? null : moodMap[day];
      cells.add(_CellData(
        day: day,
        iconAsset: icon,
        isToday: isViewingTodayMonth && _today.day == day,
        isInMonth: true,
        hasRecord: icon != null,
      ));
    }
    var nextDay = 1;
    while (cells.length < 42) {
      cells.add(_CellData(day: nextDay, isInMonth: false));
      nextDay += 1;
    }
    return cells;
  }

  /// 构建单日格子（今天绿圈 / 已记录 3D 图标 / 未记录虚线圈 / 非本月淡显）。
  /// iOS 参照：XYHomeMoodCalendarView.makeDayCell。
  Widget _buildDayCell(_CellData cell) {
    final Widget circle = Container(
      width: MoodCalendarView.circleSize,
      height: MoodCalendarView.circleSize,
      decoration: cell.isToday
          ? BoxDecoration(
              color: AppColors.brandTealLight, // #E9FAFF
              borderRadius:
                  BorderRadius.circular(MoodCalendarView.circleSize / 2),
              border: Border.all(color: AppColors.brandTeal, width: 1.5),
            )
          : null,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 未记录（非今天）→ 虚线圈（iOS addDashedCircle）
          if (!cell.isToday && cell.isInMonth && !cell.hasRecord)
            CustomPaint(painter: DashedCirclePainter()),
          // 已记录 → 3D 图标 20（iOS moodListIconSize）
          if (cell.iconAsset != null)
            Center(
              child: LoadImage(
                cell.iconAsset!,
                width: 20,
                height: 20,
                fit: BoxFit.contain,
                errorWidget: const SizedBox(width: 20, height: 20),
              ),
            )
          else if (cell.isToday)
            // 今天未记录 → 「？」居中于绿圈。
            // 全角「？」在 CJK 回退字体里字心略偏左，Center 只能居中字宽、
            // 居中不了字形，整体右移 5px 抵消（机型/字体不同可调 Offset.x）。
            Transform.translate(
              offset: const Offset(5, 0),
              child: const Center(
                child: Text(
                  '？',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: AppColors.brandTeal),
                ),
              ),
            ),
        ],
      ),
    );

    final Widget content = Opacity(
      // 非本月淡显（iOS alpha 0.35）
      opacity: cell.isInMonth ? 1 : 0.35,
      child: Column(
        children: [
          circle,
          const SizedBox(height: 3),
          Text(
            '${cell.day}',
            style: TextStyle(
              fontSize: 10,
              height: 1.2,
              fontWeight: cell.isToday ? FontWeight.w600 : FontWeight.w400,
              color: cell.isToday
                  ? AppColors.brandTeal
                  : (cell.isInMonth
                      ? AppColors.textSecondary
                      : AppColors.textTertiary),
            ),
          ),
        ],
      ),
    );

    if (cell.isToday && !cell.hasRecord) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onRecordToday,
        child: content,
      );
    }
    return content;
  }
}

/// 翻月按钮：24×24 chevron（iOS SF Symbol 13 w600 #666）。
class _MonthNavButton extends StatelessWidget {
  const _MonthNavButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 24,
        height: 24,
        child: Icon(icon, size: 16, color: AppColors.textSecondary),
      ),
    );
  }
}

/// 单日网格数据。
class _CellData {
  const _CellData({
    required this.day,
    this.iconAsset,
    this.isToday = false,
    required this.isInMonth,
    this.hasRecord = false,
  });

  final int day;
  final String? iconAsset;
  final bool isToday;
  final bool isInMonth;
  final bool hasRecord;
}

/// 虚线圆环（未录入日期占位）。
/// iOS 参照：XYHomeMoodCalendarView.addDashedCircle
/// （stroke #999 @40%，lineWidth 1，dash [3, 3]）。
class DashedCirclePainter extends CustomPainter {
  DashedCirclePainter({
    this.color = const Color(0x66999999), // #999 @ 0.4
    this.strokeWidth = 1,
    this.dashLength = 3,
    this.gapLength = 3,
  });

  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final center = Offset(size.width / 2, size.height / 2);
    // 沿圆周按 dash/gap 弧段绘制
    final dashAngle = dashLength / radius;
    final gapAngle = gapLength / radius;
    var startAngle = 0.0;
    while (startAngle < 2 * math.pi) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        math.min(dashAngle, 2 * math.pi - startAngle),
        false,
        paint,
      );
      startAngle += dashAngle + gapAngle;
    }
  }

  @override
  bool shouldRepaint(DashedCirclePainter oldDelegate) =>
      color != oldDelegate.color ||
      strokeWidth != oldDelegate.strokeWidth ||
      dashLength != oldDelegate.dashLength ||
      gapLength != oldDelegate.gapLength;
}
