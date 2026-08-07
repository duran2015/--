import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import 'mine_models.dart';

final mineApiProvider =
    Provider<MineApi>((ref) => MineApi(ref.read(apiClientProvider)));

/// 我的模块接口封装（契约 §3 #18、§5 #22/#24）。
/// iOS 参照：XYMineModule 各 ViewModel 的 postJSON/postJSONPaged 调用。
class MineApi {
  MineApi(this._client);

  final ApiClient _client;

  /// #18 量表测试记录（data 为数组，非分页）
  static const assessmentRecordsPath = '/app/assessment/list-by-status';

  /// #22 小结与建议列表（分页）
  static const summariesPath = '/app/mine/summaries';

  /// #24 注销账号
  static const deactivatePath = '/app/mine/deactivate';

  /// 意见反馈提交
  static const feedbackSubmitPath = '/app/mine/feedback/submit';

  /// #18 拉取量表测试记录（status="1"，已完成；data 为数组非分页）。
  /// 名称为空的行丢弃（iOS XYMineAssessmentRecordMapper.recordItem）。
  Future<List<AssessmentRecordItem>> fetchAssessmentRecords() async {
    final rows = await _client.postData<List<AssessmentRecordRow>>(
      assessmentRecordsPath,
      const {'status': '1'},
      decoder: (json) => [
        for (final e in (json as List?) ?? const [])
          if (e is Map)
            AssessmentRecordRow.fromJson(Map<String, dynamic>.from(e)),
      ],
    );
    return [
      for (final row in rows ?? const <AssessmentRecordRow>[])
        if (AssessmentRecordItem.fromRow(row) case final item?) item,
    ];
  }

  /// #22 拉取小结与建议列表（分页，pageNum 从 1 起）。
  Future<({List<SummaryItem> rows, int total})> fetchSummaries({
    required int pageNum,
    required int pageSize,
  }) async {
    final paged = await _client.postPaged<SummaryRow>(
      summariesPath,
      {'pageNum': pageNum, 'pageSize': pageSize},
      rowDecoder: (json) =>
          SummaryRow.fromJson(Map<String, dynamic>.from(json as Map)),
    );
    return (
      rows: paged.rows.map(SummaryItem.fromRow).toList(),
      total: paged.total,
    );
  }

  /// #24 验证并注销账号（body：phone + smsCode）。
  /// iOS 参照：XYCancelAccountViewModel.cancelAccount。
  Future<void> deactivate({
    required String phone,
    required String smsCode,
  }) {
    return _client.postMessage(
      deactivatePath,
      {'phone': phone, 'smsCode': smsCode},
    );
  }

  /// 提交意见反馈（body：content）。
  /// iOS 参照：XYFeedbackViewModel.submit。
  Future<void> submitFeedback({required String content}) {
    return _client.postMessage(
      feedbackSubmitPath,
      {'content': content},
    );
  }
}
