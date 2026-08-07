import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/route_paths.dart';
import '../../core/network/api_response.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_assets.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_loading_hud.dart';
import '../../core/widgets/app_toast.dart';
import '../../utils/load_image.dart';
import 'consultant_api.dart';
import 'consultant_models.dart';
import '../order/appointment_policy.dart';

// =====================================================================
// 排期预约弹层 ViewModel（纯 Dart，可测）
// iOS 参照：XYAIModule/XYAIModule/Classes/ViewModel/
// XYAppointmentTimeSheetViewModel.swift
// =====================================================================

/// 单个可约时段（仅保留未被预约的时段用于展示与选择）
class BookingSlotItem {
  const BookingSlotItem({
    required this.startTimeText,
    required this.timeRange,
    required this.availabilityId,
    required this.rawStartTime,
    required this.durationMinutes,
  });

  /// 开始时间文案（HH:mm）
  final String startTimeText;

  /// 时段区间文案（HH:mm~HH:mm）
  final String timeRange;

  /// 时段 ID
  final int? availabilityId;

  /// 原始开始时间（HH:mm:ss，拼装 appointmentTime 用）
  final String rawStartTime;

  /// 时段时长（分钟，由起止时间差计算）
  final int? durationMinutes;
}

/// 单个可约日期（含当日全部可约时段）
class BookingDateItem {
  const BookingDateItem({
    required this.weekday,
    required this.date,
    required this.rawDate,
    required this.isFull,
    required this.slots,
  });

  /// 星期文案（今天/明天/后天/周X）
  final String weekday;

  /// 日期文案（MM/dd）
  final String date;

  /// 原始日期（yyyy-MM-dd，拼装 appointmentTime 用）
  final String rawDate;

  /// 当日是否已满（有时段但全部被预约）
  final bool isFull;

  /// 当日可约时段列表（已满时为空）
  final List<BookingSlotItem> slots;
}

/// 单个咨询方式（含价格/副标题）
class BookingMethodItem {
  const BookingMethodItem({
    required this.name,
    required this.subtitle,
    required this.priceText,
    required this.supportMode,
    required this.capabilityId,
  });

  /// 咨询方式名称（文字沟通/语音咨询/视频沟通）
  final String name;

  /// 副标题描述
  final String subtitle;

  /// 价格文案（¥320）
  final String priceText;

  /// 支持方式编码（1 文字 / 2 语音 / 3 视频；用于图标与下单）
  final String? supportMode;

  /// 咨询能力 ID（下单用）
  final int? capabilityId;
}

/// 排期预约弹层 ViewModel：聚合「最近可约时段」与「咨询方式」，
/// 维护日期/时段/方式选择状态，并拼装下单参数。
/// iOS 参照：XYAppointmentTimeSheetViewModel。
class BookingViewModel {
  BookingViewModel({
    required this.counselorName,
    required this.counselorTitle,
    required this.counselorImUserId,
    required this.consultantId,
    required List<ConsultantAvailability> availability,
    required List<ConsultantCapability> capabilities,
  })  : dates = _groupDates(availability),
        methods = capabilities.map(_buildMethod).toList() {
    // 默认选中首个未满日期，并预选其首个时段
    final firstOpen = dates.indexWhere((d) => !d.isFull);
    selectedDateIndex = firstOpen >= 0 ? firstOpen : 0;
    final defaultSlots =
        dates.isEmpty ? const <BookingSlotItem>[] : currentSlots;
    selectedTimeIndex = defaultSlots.isEmpty ? null : 0;
    selectedMethodIndex = methods.isEmpty ? -1 : 0;
  }

  /// 咨询师姓名
  final String counselorName;

  /// 咨询师职称
  final String counselorTitle;

  /// 咨询师 IM 用户 ID
  final String counselorImUserId;

  /// 咨询师业务 ID（下单用）
  final int consultantId;

  /// 可约日期列表（按出现顺序）
  final List<BookingDateItem> dates;

  /// 咨询方式列表
  final List<BookingMethodItem> methods;

  /// 当前选中日期索引
  late int selectedDateIndex;

  /// 当前选中时段索引（在当前日期的 slots 内；null 表示未选）
  int? selectedTimeIndex;

  /// 当前选中咨询方式索引（无咨询方式时为 -1）
  late int selectedMethodIndex;

  // ---------- 选择 ----------

  /// 选中指定日期（已满日期忽略）；切换后重置时段为当日首个
  void selectDate(int index) {
    if (index < 0 || index >= dates.length || dates[index].isFull) return;
    selectedDateIndex = index;
    selectedTimeIndex = dates[index].slots.isEmpty ? null : 0;
  }

  /// 选中指定时段（当前日期内）
  void selectTime(int index) {
    final slots = currentSlots;
    if (index < 0 || index >= slots.length) return;
    selectedTimeIndex = index;
  }

  /// 选中指定咨询方式
  void selectMethod(int index) {
    if (index < 0 || index >= methods.length) return;
    selectedMethodIndex = index;
  }

  // ---------- 当前状态 ----------

  /// 当前日期的可约时段
  List<BookingSlotItem> get currentSlots {
    if (selectedDateIndex < 0 || selectedDateIndex >= dates.length) {
      return const [];
    }
    return dates[selectedDateIndex].slots;
  }

  /// 当前选中的咨询方式
  BookingMethodItem? get currentMethod {
    if (selectedMethodIndex < 0 || selectedMethodIndex >= methods.length) {
      return null;
    }
    return methods[selectedMethodIndex];
  }

  /// 是否已满足「去支付」条件（已选时段且有咨询方式）
  bool get isReady => selectedTimeIndex != null && currentMethod != null;

  /// 合计金额数值文案（取当前咨询方式价格，不含 ¥）
  String get totalPriceText {
    final text = currentMethod?.priceText ?? '';
    return text.replaceAll('¥', '');
  }

  /// 选中时段的时长（分钟）；未选时段或解析失败时为 null
  int? get selectedSlotDuration {
    final index = selectedTimeIndex;
    final slots = currentSlots;
    if (index == null || index < 0 || index >= slots.length) return null;
    return slots[index].durationMinutes;
  }

  /// 合计金额下方描述（咨询方式 + 选中时段时长）
  /// iOS 参照：XYAppointmentTimeSheetViewModel.totalDesc
  String get totalDesc {
    final method = currentMethod;
    if (method == null) return '';
    final minutes = selectedSlotDuration;
    if (minutes != null) return '${method.name} $minutes分钟';
    return method.name;
  }

  /// 拼装 /app/consultant/book 请求体；未选全时返回 null。
  /// appointmentTime：yyyy-MM-dd HH:mm:ss（日期 + 时段开始时间）。
  /// iOS 参照：XYAppointmentTimeSheetViewModel.book 的 body 组装。
  Map<String, dynamic>? buildBookBody() {
    final method = currentMethod;
    final timeIndex = selectedTimeIndex;
    final slots = currentSlots;
    if (method == null ||
        timeIndex == null ||
        timeIndex < 0 ||
        timeIndex >= slots.length ||
        selectedDateIndex < 0 ||
        selectedDateIndex >= dates.length) {
      return null;
    }
    final slot = slots[timeIndex];
    final dateItem = dates[selectedDateIndex];
    return <String, dynamic>{
      'consultantId': consultantId,
      'capabilityId': method.capabilityId ?? 0,
      'availabilityId': slot.availabilityId ?? 0,
      'supportMode': method.supportMode ?? '',
      'appointmentTime': '${dateItem.rawDate} ${slot.rawStartTime}',
    };
  }

  // ---------- 聚合辅助（iOS 参照：groupDates / slot / buildMethods） ----------

  /// 按日期聚合可约时段：同日按时段出现顺序合并，并计算是否已满
  static List<BookingDateItem> _groupDates(
    List<ConsultantAvailability> availability,
  ) {
    final order = <String>[];
    final byDate = <String, List<ConsultantAvailability>>{};
    for (final item in availability) {
      final key = item.availableDate ?? '';
      byDate.putIfAbsent(key, () {
        order.add(key);
        return [];
      }).add(item);
    }
    return order.map((key) {
      final all = byDate[key] ?? const <ConsultantAvailability>[];
      // 仅保留未被预约的时段用于展示；全部被预约即视为「已满」
      final available = all.where((e) => (e.isBooked ?? '0') == '0').toList();
      return BookingDateItem(
        weekday: weekdayText(key),
        date: shortDate(key),
        rawDate: key,
        isFull: available.isEmpty,
        slots: available.map(_slot).toList(),
      );
    }).toList();
  }

  /// 单条可约时段 → 展示模型
  static BookingSlotItem _slot(ConsultantAvailability item) {
    final start = shortTime(item.startTime);
    final end = shortTime(item.endTime);
    return BookingSlotItem(
      startTimeText: start,
      timeRange: end.isEmpty ? start : '$start~$end',
      availabilityId: item.availabilityId,
      rawStartTime: item.startTime ?? '',
      durationMinutes: minutesBetween(item.startTime, item.endTime),
    );
  }

  /// 咨询能力 → 咨询方式展示模型
  static BookingMethodItem _buildMethod(ConsultantCapability cap) {
    return BookingMethodItem(
      name: cap.displayName,
      subtitle: _methodSubtitle(cap),
      priceText: '¥${formatPrice(cap.price ?? 0)}',
      supportMode: cap.supportMode,
      capabilityId: cap.capabilityId,
    );
  }

  /// 咨询方式副标题：优先用接口描述，否则按支持方式给默认文案
  /// iOS 参照：XYAppointmentTimeSheetViewModel.methodSubtitle
  static String _methodSubtitle(ConsultantCapability cap) {
    final desc = cap.description;
    if (desc != null && desc.isNotEmpty) return desc;
    final duration = cap.duration;
    switch (cap.supportMode) {
      case '1':
        return '异步回复，陪伴引导';
      case '2':
        return duration != null ? '注重倾听，$duration分钟' : '注重倾听';
      case '3':
        return duration != null ? '面对面深度交流，$duration分钟' : '面对面深度交流';
      default:
        return '';
    }
  }
}

// =====================================================================
// 排期预约底部弹层 UI
// iOS 参照：XYAIModule/XYAIModule/Classes/View/XYAppointmentTimeSheetView.swift
// （Figma 381:2089：半透明遮罩 + #F7F8FC 圆角弹层 + 白色内容卡）
// =====================================================================

/// 从底部弹出「选择预约时间」弹层（iOS present(in:) 语义，0.82 屏高）。
Future<void> showBookingSheet(
  BuildContext context, {
  required BookingViewModel viewModel,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BookingSheet(viewModel: viewModel),
  );
}

/// 选择预约时间底部弹层
class BookingSheet extends ConsumerStatefulWidget {
  const BookingSheet({super.key, required this.viewModel});

  final BookingViewModel viewModel;

  /// 弹层高度占屏比（iOS Style.sheetHeightRatio 0.82）
  static const double sheetHeightRatio = 0.82;

  @override
  ConsumerState<BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends ConsumerState<BookingSheet> {
  bool _submitting = false;

  BookingViewModel get vm => widget.viewModel;

  // iOS Style：区块标题图标/圆角/间距实值
  static const double _sheetRadius = 20; // 弹层顶部圆角
  static const double _cardRadius = 12; // 白色内容卡圆角
  static const double _chipRadius = 10; // 可选项圆角
  static const double _horizontalInset = 15;
  static const double _cardPadding = 15;
  static const double _sectionIconSize = 12;
  static const double _dateCardWidth = 72;
  static const double _dateCardHeight = 63;
  static const double _timeSlotHeight = 40;
  static const double _gridSpacing = 10;
  static const double _methodIconSize = 15;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Container(
      height: screenHeight * BookingSheet.sheetHeightRatio,
      decoration: const BoxDecoration(
        color: AppColors.innerBackground, // #F7F8FC 弹层底
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(_sheetRadius),
        ),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    _horizontalInset,
                    16,
                    _horizontalInset,
                    20,
                  ),
                  child: Column(
                    children: [
                      _buildDateSection(),
                      const SizedBox(height: AppDimens.gap10),
                      _buildTimeSection(),
                      const SizedBox(height: AppDimens.gap10),
                      _buildMethodSection(),
                      const SizedBox(height: AppDimens.gap10),
                      _buildPolicySection(),
                    ],
                  ),
                ),
              ),
              _buildBottomBar(),
            ],
          ),
          if (_submitting)
            const Positioned.fill(
              child: AppLoadingHud(message: '提交中'),
            ),
        ],
      ),
    );
  }

  Widget _buildPolicySection() {
    const policy = AppointmentPolicy.current;
    return _sectionCard(
      title: '预约与取消规则',
      iconAsset: AppAssets.icBookingCalendar,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF2D38A)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final line in policy.userFacingLines) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child:
                        Icon(Icons.circle, size: 5, color: Color(0xFF8A6116)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      line,
                      style: AppTextStyles.label.copyWith(
                        color: const Color(0xFF6B531C),
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
              if (line != policy.userFacingLines.last)
                const SizedBox(height: 6),
            ],
          ],
        ),
      ),
    );
  }

  /// 头部：居中标题 + 右上关闭（iOS setupHeader）
  Widget _buildHeader() {
    return SizedBox(
      height: 18 + 22 + 8, // top 18 + 标题行 + 余量
      child: Stack(
        children: [
          const Positioned(
            left: 0,
            right: 0,
            top: 18,
            child: Center(
              child: Text('选择预约时间', style: AppTextStyles.title),
            ),
          ),
          Positioned(
            right: _horizontalInset,
            top: 16,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).pop(),
              child: const SizedBox(
                width: 24,
                height: 24,
                child:
                    Icon(Icons.close, size: 18, color: AppColors.textTertiary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 白色内容卡 + 「图标 + 区块标题」标题行（iOS makeSectionCard）
  Widget _sectionCard({
    required String title,
    required String iconAsset,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(_cardPadding),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(_cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              LoadImage(
                iconAsset,
                width: _sectionIconSize,
                height: _sectionIconSize,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: AppTextStyles.titleSmall.copyWith(fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.gap12),
          child,
        ],
      ),
    );
  }

  /// 选择日期区块：横向日期卡（72×63，可滑动；iOS makeDateSection）
  Widget _buildDateSection() {
    return _sectionCard(
      title: '选择日期',
      iconAsset: AppAssets.icBookingCalendar,
      child: SizedBox(
        height: _dateCardHeight,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: vm.dates.length,
          separatorBuilder: (_, __) => const SizedBox(width: _gridSpacing),
          itemBuilder: (context, index) {
            final item = vm.dates[index];
            final selected = index == vm.selectedDateIndex;
            return GestureDetector(
              onTap: item.isFull
                  ? null
                  : () => setState(() => vm.selectDate(index)),
              child: _dateCard(item, selected),
            );
          },
        ),
      ),
    );
  }

  /// 单个日期卡片（星期/日期；已满时日期删除线 + 「已满」；iOS makeDateCard）
  Widget _dateCard(BookingDateItem item, bool selected) {
    final Color textColor;
    if (selected) {
      textColor = AppColors.brandTeal;
    } else if (item.isFull) {
      textColor = AppColors.textTertiary;
    } else {
      textColor = AppColors.textSecondary;
    }
    return Container(
      width: _dateCardWidth,
      height: _dateCardHeight,
      decoration: BoxDecoration(
        color:
            selected ? AppColors.brandTealSelected : AppColors.innerBackground,
        borderRadius: BorderRadius.circular(_chipRadius),
        boxShadow: selected ? _selectedShadow : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            item.weekday,
            style: AppTextStyles.caption.copyWith(color: textColor),
          ),
          const SizedBox(height: 2),
          Text(
            item.date,
            style: AppTextStyles.titleSmall.copyWith(
              color: textColor,
              decoration:
                  item.isFull && !selected ? TextDecoration.lineThrough : null,
            ),
          ),
          if (item.isFull) ...[
            const SizedBox(height: 2),
            Text('已满', style: AppTextStyles.label),
          ],
        ],
      ),
    );
  }

  /// 选择时段区块：2 列网格（iOS makeTimeSection / rebuildTimeButtons）
  Widget _buildTimeSection() {
    final slots = vm.currentSlots;
    return _sectionCard(
      title: '选择时段',
      iconAsset: AppAssets.icBookingClock,
      child: slots.isEmpty
          ? const SizedBox(
              height: _timeSlotHeight,
              child: Center(
                child: Text('该日暂无可约时段', style: AppTextStyles.body),
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final slotWidth = (constraints.maxWidth - _gridSpacing) / 2;
                return Wrap(
                  spacing: _gridSpacing,
                  runSpacing: _gridSpacing,
                  children: [
                    for (var i = 0; i < slots.length; i++)
                      GestureDetector(
                        onTap: () => setState(() => vm.selectTime(i)),
                        child: _timeSlotChip(
                          slots[i],
                          i == vm.selectedTimeIndex,
                          slotWidth,
                        ),
                      ),
                  ],
                );
              },
            ),
    );
  }

  /// 单个时段格（选中态 brandTealSelected 底 + brandTeal 文字 + 淡青投影；
  /// iOS applyTimeStyle 实值，无描边）
  Widget _timeSlotChip(BookingSlotItem slot, bool selected, double width) {
    return Container(
      width: width,
      height: _timeSlotHeight,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color:
            selected ? AppColors.brandTealSelected : AppColors.innerBackground,
        borderRadius: BorderRadius.circular(_chipRadius),
        boxShadow: selected ? _selectedShadow : null,
      ),
      child: Text(
        slot.timeRange,
        style: TextStyle(
          fontSize: 15,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          color: selected ? AppColors.brandTeal : AppColors.textSecondary,
        ),
      ),
    );
  }

  /// 选择咨询方式区块：纵向方式卡片（iOS makeMethodSection）
  Widget _buildMethodSection() {
    return _sectionCard(
      title: '选择咨询方式',
      iconAsset: AppAssets.icBookingConsult,
      child: Column(
        children: [
          for (var i = 0; i < vm.methods.length; i++) ...[
            if (i > 0) const SizedBox(height: _gridSpacing),
            GestureDetector(
              onTap: () => setState(() => vm.selectMethod(i)),
              child: _methodCard(vm.methods[i], i == vm.selectedMethodIndex),
            ),
          ],
        ],
      ),
    );
  }

  /// 单个咨询方式卡片（图标 / 名称+价格同行 / 副标题；iOS makeMethodCard）
  Widget _methodCard(BookingMethodItem method, bool selected) {
    final nameColor = selected ? AppColors.brandTeal : AppColors.textPrimary;
    final subColor = selected ? AppColors.brandTeal : AppColors.textSecondary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(15, 14, 15, 14),
      decoration: BoxDecoration(
        color:
            selected ? AppColors.brandTealSelected : AppColors.innerBackground,
        borderRadius: BorderRadius.circular(_chipRadius),
        boxShadow: selected ? _selectedShadow : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              LoadImage(
                _methodIcon(method),
                width: _methodIconSize,
                height: _methodIconSize,
                color: selected ? AppColors.brandTeal : AppColors.textSecondary,
              ),
              const SizedBox(width: AppDimens.gap8),
              Expanded(
                child: Text(
                  method.name,
                  style: AppTextStyles.titleSmall.copyWith(color: nameColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // 价格（¥14 + 数字 18，红色粗体；iOS priceAttributed）
              Text.rich(
                TextSpan(children: [
                  TextSpan(
                    text: '¥',
                    style: AppTextStyles.bodyLargeStrong.copyWith(
                      color: AppColors.priceRed,
                    ),
                  ),
                  TextSpan(
                    text: method.priceText.replaceAll('¥', ''),
                    style: AppTextStyles.titleLarge.copyWith(
                      color: AppColors.priceRed,
                    ),
                  ),
                ]),
              ),
            ],
          ),
          if (method.subtitle.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              method.subtitle,
              style: AppTextStyles.caption.copyWith(color: subColor),
            ),
          ],
        ],
      ),
    );
  }

  /// 按 supportMode / 名称取咨询方式图标（iOS methodNameIcon）
  String _methodIcon(BookingMethodItem method) {
    switch (method.supportMode) {
      case '1':
        return AppAssets.icMethodText;
      case '2':
        return AppAssets.icMethodVoice;
      case '3':
        return AppAssets.icMethodVideo;
      default:
        if (method.name.contains('文')) return AppAssets.icMethodText;
        if (method.name.contains('语')) return AppAssets.icMethodVoice;
        if (method.name.contains('视')) return AppAssets.icMethodVideo;
        return AppAssets.icMethodText;
    }
  }

  /// 底部固定区：合计金额 + 确认按钮（iOS setupBottomBar）
  Widget _buildBottomBar() {
    final ready = vm.isReady;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        boxShadow: [
          // Figma 0,-8,8 rgba(234,234,234,0.4)
          BoxShadow(
            color: const Color(0xFFEAEAEA).withValues(alpha: 0.4),
            offset: const Offset(0, -4),
            blurRadius: 4,
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        _horizontalInset,
        14,
        _horizontalInset,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '合计金额',
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(vm.totalDesc, style: AppTextStyles.label),
                  ],
                ),
              ),
              // 合计价格（¥16 + 数字 24 红色粗体）
              Text.rich(
                TextSpan(children: [
                  TextSpan(
                    text: '¥',
                    style: AppTextStyles.title.copyWith(
                      color: AppColors.priceRed,
                    ),
                  ),
                  TextSpan(
                    text: vm.totalPriceText,
                    style: AppTextStyles.price.copyWith(
                      color: AppColors.priceRed,
                    ),
                  ),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ready ? _confirmButton() : _disabledButton(),
        ],
      ),
    );
  }

  /// 确认预约渐变按钮（#00D8E0→#00AFBE，45 高胶囊；iOS confirmButton）
  Widget _confirmButton() {
    return GestureDetector(
      onTap: _submitting ? null : _confirm,
      child: Container(
        height: AppDimens.buttonHeight,
        decoration: BoxDecoration(
          gradient: AppColors.brandGradient,
          borderRadius: BorderRadius.circular(AppDimens.buttonRadiusCapsule),
        ),
        alignment: Alignment.center,
        child: Text(
          '确认预约，去支付',
          style: AppTextStyles.title.copyWith(color: Colors.white),
        ),
      ),
    );
  }

  /// 未选时段时的禁用按钮（iOS disabledButton）
  Widget _disabledButton() {
    return Container(
      height: AppDimens.buttonHeight,
      decoration: BoxDecoration(
        color: AppColors.innerBackground,
        borderRadius: BorderRadius.circular(AppDimens.buttonRadiusCapsule),
      ),
      alignment: Alignment.center,
      child: Text(
        '请先选择时间',
        style: AppTextStyles.title.copyWith(color: AppColors.textTertiary),
      ),
    );
  }

  /// 选中态淡青投影（iOS applySelectedShadow：offset(0,2) blur 3 rgba(180,204,204,0.22)）
  static const List<BoxShadow> _selectedShadow = [
    BoxShadow(
      color: AppColors.selectedChipShadow,
      offset: Offset(0, 2),
      blurRadius: 3,
    ),
  ];

  /// 确认预约：调 /app/consultant/book 拿订单 → 关弹层 → push 支付页（占位）。
  /// iOS 参照：XYCounselorDetailViewController.presentAppointmentSheet 的 onConfirm。
  Future<void> _confirm() async {
    final body = vm.buildBookBody();
    if (body == null) {
      AppToast.show(context, '请先选择预约时段与咨询方式');
      return;
    }
    setState(() => _submitting = true);
    try {
      final order = await ref.read(consultantApiProvider).book(body);
      if (!mounted) return;
      Navigator.of(context).pop(); // 收起弹层（iOS dismissAnimated）
      // 支付页属阶段 4 下半，当前为占位页
      context.push('${RoutePaths.payment}?orderId=${order.orderId}');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      AppToast.show(context, e.msg.isEmpty ? '创建订单失败' : e.msg);
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      AppToast.show(context, '创建订单失败');
    }
  }
}
