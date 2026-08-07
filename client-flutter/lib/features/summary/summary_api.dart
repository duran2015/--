import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';
import 'summary_models.dart';

final summaryApiProvider =
    Provider<SummaryApi>((ref) => SummaryApi(ref.read(apiClientProvider)));

/// 小结与建议接口封装（契约 §5 #23）。
/// iOS 参照：XYMessageModule XYSummaryAdviseViewModel.fetchDetail。
class SummaryApi {
  SummaryApi(this._client);

  final ApiClient _client;

  /// #23 小结详情
  static const detailPath = '/app/mine/summary/detail';

  /// #23 拉取小结详情（body：orderId）。
  Future<SummaryAdviseDetail> fetchDetail(int orderId) async {
    final data = await _client.postData<SummaryAdviseDetail>(
      detailPath,
      {'orderId': orderId},
      decoder: (json) =>
          SummaryAdviseDetail.fromJson(Map<String, dynamic>.from(json as Map)),
    );
    if (data == null) {
      throw const ApiException(code: -1, msg: '详情数据为空');
    }
    return data;
  }
}
