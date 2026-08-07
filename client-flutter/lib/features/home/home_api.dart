import '../../core/network/api_client.dart';
import 'home_models.dart';

/// 首页接口封装（契约 §5 #26-28 心情、§3 #17 测评列表）。
/// iOS 参照：XYHomeModule XYHomeViewModel / XYHomeAssessmentListViewModel
/// 中各 postJSON 调用。
class HomeApi {
  HomeApi(this._client);

  final ApiClient _client;

  // ---------- 路径常量 ----------
  /// #26 提交心情
  static const moodPath = '/app/user/mood';

  /// #27 情绪月历
  static const moodCalendarPath = '/app/user/mood/calendar';

  /// #28 情绪趋势
  static const moodTrendPath = '/app/user/mood/trend';

  /// #17 测评问卷列表
  static const assessmentListPath = '/app/assessment/list';

  /// #19 测评报告详情
  static const assessmentDetailPath = '/app/assessment/detail';

  /// #19 拉取测评报告详情（body: {"assessmentId": userAssessId}）。
  /// iOS 参照：XYHomeAssessmentReportViewController.fetchReportDetail。
  Future<AssessmentDetail?> fetchAssessmentDetail(int assessmentId) {
    return _client.postData<AssessmentDetail>(
      assessmentDetailPath,
      {'assessmentId': assessmentId},
      decoder: (json) =>
          AssessmentDetail.fromJson(Map<String, dynamic>.from(json as Map)),
    );
  }

  /// #28 拉取最近 [days] 天情绪趋势。
  /// iOS 参照：XYHomeViewModel.fetchMoodTrend（body: {"days": 7}）。
  Future<List<MoodRecordItem>> fetchMoodTrend({int days = 7}) async {
    final data = await _client.postData<List<MoodRecordItem>>(
      moodTrendPath,
      {'days': days},
      decoder: (json) => (json as List?)
              ?.map((e) =>
                  MoodRecordItem.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
    );
    return data ?? const [];
  }

  /// #27 拉取指定月份情绪月历。
  /// iOS 参照：XYHomeViewModel.fetchMoodCalendar（body: {"year","month"}）。
  Future<List<MoodRecordItem>> fetchMoodCalendar({
    required int year,
    required int month,
  }) async {
    final data = await _client.postData<List<MoodRecordItem>>(
      moodCalendarPath,
      {'year': year, 'month': month},
      decoder: (json) => (json as List?)
              ?.map((e) =>
                  MoodRecordItem.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
    );
    return data ?? const [];
  }

  /// #26 提交今天的心情（取 msg 文案）。
  /// iOS 参照：XYHomeViewModel.submitTodayMood（postJSONMessage，
  /// fallbackMessage "记录成功"）。
  Future<String> submitMood({
    required String recordDate,
    required int moodScore,
    required String note,
  }) {
    return _client.postMessage(
      moodPath,
      {'recordDate': recordDate, 'moodScore': moodScore, 'note': note},
    );
  }

  /// #17 拉取测评问卷列表。
  /// iOS 参照：XYHomeViewModel.fetchAssessmentList
  /// （body: {"category":"clinical"}，契约以代码为准）。
  Future<List<AssessmentItem>> fetchAssessmentList({
    String category = 'clinical',
  }) async {
    final data = await _client.postData<List<AssessmentItem>>(
      assessmentListPath,
      {'category': category},
      decoder: (json) => (json as List?)
              ?.map((e) =>
                  AssessmentItem.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
    );
    return data ?? const [];
  }
}
