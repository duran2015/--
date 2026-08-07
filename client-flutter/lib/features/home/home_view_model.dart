import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';
import '../../core/theme/app_assets.dart';
import 'home_api.dart';
import 'home_models.dart';

final homeApiProvider =
    Provider<HomeApi>((ref) => HomeApi(ref.read(apiClientProvider)));

/// 首页状态：情绪记录缓存 + 测评列表。
/// iOS 参照：XYHomeViewModel 的 moodRecordMap / assessments。
class HomeState {
  const HomeState({
    this.moodRecords = const {},
    this.assessments = const [],
  });

  /// 日期 yyyy-MM-dd → 情绪记录
  final Map<String, MoodRecordItem> moodRecords;

  /// 专业测评列表（进入首页后由接口填充）
  final List<HomeAssessment> assessments;

  HomeState copyWith({
    Map<String, MoodRecordItem>? moodRecords,
    List<HomeAssessment>? assessments,
  }) {
    return HomeState(
      moodRecords: moodRecords ?? this.moodRecords,
      assessments: assessments ?? this.assessments,
    );
  }
}

/// 首页 ViewModel：提供顶部问候、情绪、测评、小工具等展示数据。
/// iOS 参照：XYHomeModule/Classes/ViewModel/XYHomeViewModel.swift。
class HomeViewModel extends Notifier<HomeState> {
  @override
  HomeState build() => const HomeState();

  HomeApi get _api => ref.read(homeApiProvider);

  /// 服务端对齐的当前时间（iOS XYServerTime.now）。
  DateTime get _now => ref.read(apiClientProvider).serverNow();

  /// 是否正在拉取情绪趋势 / 提交今日情绪 / 拉取月历 / 拉取测评（防重入）。
  bool _isFetchingMoodTrend = false;
  bool _isSubmittingMood = false;
  bool _isFetchingMoodCalendar = false;
  bool _isFetchingAssessmentList = false;

  // ---------- 顶部问候（iOS userInfo 固定文案） ----------

  /// 问候主标题
  static const String greetingTitle = 'Hi～';

  /// 问候副标题
  static const String greetingSubtitle = '今天感觉怎么样？';

  // ---------- 情绪趋势 / 月历 ----------

  /// 月历当前展示年（服务端时间）。
  int get calendarYear => _now.year;

  /// 月历当前展示月（服务端时间）。
  int get calendarMonth => _now.month;

  /// 今天是否可录入。
  /// iOS 参照：todayIsRecordable（今天无记录时可录入）。
  bool get todayIsRecordable => state.moodRecords[formatDateKey(_now)] == null;

  /// 最近 7 天情绪（本周日至周六）。
  /// iOS 参照：weekMoods()。
  List<MoodDay> get moods {
    const weekdayLabels = ['日', '一', '二', '三', '四', '五', '六'];
    final today = DateTime(_now.year, _now.month, _now.day);
    // Dart weekday：Mon=1…Sun=7；周日偏移 = weekday % 7
    final sunday = today.subtract(Duration(days: today.weekday % 7));

    final week = <MoodDay>[];
    for (var offset = 0; offset < 7; offset++) {
      final date = sunday.add(Duration(days: offset));
      final isToday = date == today;
      final record = state.moodRecords[formatDateKey(date)];
      final hasRecord = record != null;

      String? displayTitle;
      if (hasRecord) {
        displayTitle = _displayText(record) ??
            moodOptionForScore(record.moodScore ?? -1)?.title;
      } else if (isToday) {
        displayTitle = '今天？';
      }

      week.add(MoodDay(
        weekday: weekdayLabels[date.weekday % 7],
        iconAsset: _iconAsset(
          score: record?.moodScore,
          isToday: isToday,
          hasRecord: hasRecord,
        ),
        title: displayTitle,
        isToday: isToday,
        isRecordable: isToday && !hasRecord,
      ));
    }
    return week;
  }

  /// 获取指定年月的月历情绪（day 升序）。
  /// iOS 参照：monthMoods(year:month:)。
  List<MonthMood> monthMoods(int year, int month) {
    final result = <MonthMood>[];
    state.moodRecords.forEach((key, record) {
      final date = DateTime.tryParse(key);
      if (date == null || date.year != year || date.month != month) return;
      final option = moodOptionForScore(record.moodScore ?? -1);
      if (option == null) return;
      result.add(MonthMood(day: date.day, iconAsset: option.iconAsset));
    });
    result.sort((a, b) => a.day.compareTo(b.day));
    return result;
  }

  /// 列表展示文案（优先 moodTags，其次 note）。
  /// iOS 参照：MoodRecord.displayText。
  String? _displayText(MoodRecordItem record) {
    final tags = record.moodTags?.trim();
    if (tags != null && tags.isNotEmpty) return tags;
    final note = record.note?.trim();
    if (note != null && note.isNotEmpty) return note;
    return null;
  }

  /// 根据 moodScore 映射 3D 图标资源。
  /// iOS 参照：iconAsset(forScore:isToday:hasRecord:)。
  String? _iconAsset({
    required int? score,
    required bool isToday,
    required bool hasRecord,
  }) {
    if (hasRecord && score != null) {
      final option = moodOptionForScore(score);
      if (option != null) return option.iconAsset;
    }
    if (isToday) return AppAssets.homeMoodToday;
    return AppAssets.homeMoodUnrecorded;
  }

  // ---------- 接口 ----------

  /// 拉取最近 7 天情绪趋势（POST /app/user/mood/trend）。
  /// iOS 参照：fetchMoodTrend（成功后覆盖近 7 天记录缓存）。
  Future<void> fetchMoodTrend({bool force = false}) async {
    if (!force && _isFetchingMoodTrend) return;
    _isFetchingMoodTrend = true;
    try {
      final items = await _api.fetchMoodTrend(days: 7);
      // applyMoodTrend：整体覆盖
      final map = <String, MoodRecordItem>{};
      for (final item in items) {
        final key = item.normalizedDateKey;
        if (key == null || item.moodScore == null) continue;
        map[key] = item;
      }
      state = state.copyWith(moodRecords: map);
    } finally {
      _isFetchingMoodTrend = false;
    }
  }

  /// 拉取指定月份情绪月历（POST /app/user/mood/calendar）。
  /// iOS 参照：fetchMoodCalendar（覆盖指定月份，其他月份保留）。
  Future<void> fetchMoodCalendar({
    required int year,
    required int month,
  }) async {
    if (_isFetchingMoodCalendar) return;
    _isFetchingMoodCalendar = true;
    try {
      final items = await _api.fetchMoodCalendar(year: year, month: month);
      final map = Map<String, MoodRecordItem>.of(state.moodRecords);
      map.removeWhere((key, _) {
        final date = DateTime.tryParse(key);
        if (date == null) return false;
        return date.year == year && date.month == month;
      });
      for (final item in items) {
        final key = item.normalizedDateKey;
        if (key == null || item.moodScore == null) continue;
        map[key] = item;
      }
      state = state.copyWith(moodRecords: map);
    } finally {
      _isFetchingMoodCalendar = false;
    }
  }

  /// 提交今天的心情（POST /app/user/mood），返回接口 msg 文案。
  /// iOS 参照：submitTodayMood（今天已记录 / 文案不匹配 → 失败）。
  Future<String> submitTodayMood({required String note}) async {
    if (_isSubmittingMood) {
      throw const ApiException(code: -1, msg: '提交中，请稍候');
    }
    if (!todayIsRecordable) {
      throw const ApiException(code: -1, msg: '今天已记录，暂不可修改');
    }
    MoodOption? option;
    for (final e in kMoodOptions) {
      if (e.title == note) {
        option = e;
        break;
      }
    }
    if (option == null) {
      throw const ApiException(code: -1, msg: '今天已记录，暂不可修改');
    }
    _isSubmittingMood = true;
    try {
      return await _api.submitMood(
        recordDate: formatRecordDateTime(_now),
        moodScore: option.moodScore,
        note: note,
      );
    } finally {
      _isSubmittingMood = false;
    }
  }

  /// 拉取测评问卷列表（POST /app/assessment/list）。
  /// iOS 参照：fetchAssessmentList（sortedItems → homeAssessment 映射）。
  Future<void> fetchAssessmentList({bool force = false}) async {
    if (!force && _isFetchingAssessmentList) return;
    _isFetchingAssessmentList = true;
    try {
      final items = await _api.fetchAssessmentList();
      final sorted = AssessmentMapper.sortedItems(items);
      final assessments = sorted
          .map(AssessmentMapper.homeAssessment)
          .whereType<HomeAssessment>()
          .toList();
      state = state.copyWith(assessments: assessments);
    } finally {
      _isFetchingAssessmentList = false;
    }
  }

  /// 下拉刷新：并行拉取情绪趋势与测评列表。
  /// iOS 参照：refreshHomeContent（返回两路错误文案，页面合并 Toast）。
  Future<(String? moodError, String? assessmentError)>
      refreshHomeContent() async {
    String? moodError;
    String? assessmentError;
    await Future.wait([
      fetchMoodTrend(force: true)
          .catchError((Object e) => moodError = _errorMessage(e)),
      fetchAssessmentList(force: true)
          .catchError((Object e) => assessmentError = _errorMessage(e)),
    ]);
    return (moodError, assessmentError);
  }

  /// 提取错误文案（ApiException 取 msg，其他给通用文案）。
  static String _errorMessage(Object error) {
    if (error is ApiException) return error.msg;
    return '网络异常，请稍后重试';
  }
}

final homeViewModelProvider =
    NotifierProvider<HomeViewModel, HomeState>(HomeViewModel.new);
