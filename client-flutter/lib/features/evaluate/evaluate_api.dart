import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import 'evaluate_models.dart';

final evaluateApiProvider =
    Provider<EvaluateApi>((ref) => EvaluateApi(ref.read(apiClientProvider)));

/// 评价接口封装（契约 §2 #15-16）。
/// iOS 参照：XYMessageModule XYEvaluateViewModel.fetchReviewTags / submitReview。
class EvaluateApi {
  EvaluateApi(this._client);

  final ApiClient _client;

  /// #15 评价可选标签
  static const tagsPath = '/app/consultant/review/tags';

  /// #16 提交评价
  static const addPath = '/app/consultant/review/add';

  /// #15 拉取评价可选标签（data 为对象数组；无 id 的字符串项过滤，
  /// iOS 参照：XYConsultantReviewTagsPayload）。
  Future<List<EvaluateTagItem>> fetchReviewTags() async {
    final data = await _client.postData<List<dynamic>>(tagsPath, const {});
    if (data == null) return const [];
    return data
        .whereType<Map>()
        .map((e) => EvaluateTagItem.fromJson(Map<String, dynamic>.from(e)))
        .whereType<EvaluateTagItem>()
        .toList();
  }

  /// #16 提交评价（body 由 [EvaluateSubmission.buildBody] 组装）。
  Future<void> submitReview(Map<String, dynamic> body) async {
    await _client.postData<dynamic>(addPath, body);
  }
}
