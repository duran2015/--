import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';
import 'consultant_models.dart';

final consultantApiProvider =
    Provider<ConsultantApi>((ref) => ConsultantApi(ref.read(apiClientProvider)));

/// 咨询师接口封装（契约 §2 #9-14）。
/// iOS 参照：XYAIModule XYAIViewModel / XYCounselorDetailViewModel /
/// XYAppointmentTimeSheetViewModel 中各 postJSON 调用。
class ConsultantApi {
  ConsultantApi(this._client);

  final ApiClient _client;

  // ---------- 路径常量 ----------
  /// #9 咨询师列表（分页）
  static const listPath = '/app/consultant/list';

  /// #10 咨询师详情
  static const detailPath = '/app/consultant/detail';

  /// #11 咨询师评价列表（分页，仅 iOS；Android 详情内嵌 reviews）
  static const reviewListPath = '/app/consultant/review-list';

  /// #12 预约下单
  static const bookPath = '/app/consultant/book';

  /// #9 拉取咨询师列表（pageNum 从 1 起）。
  /// iOS 参照：XYAIViewModel.fetchCounselorList。
  Future<({List<Consultant> rows, int total})> fetchList({
    required int pageNum,
    int pageSize = 10,
  }) async {
    final paged = await _client.postPaged<Consultant>(
      listPath,
      {'pageNum': pageNum, 'pageSize': pageSize},
      rowDecoder: (json) =>
          Consultant.fromJson(Map<String, dynamic>.from(json as Map)),
    );
    return (rows: paged.rows, total: paged.total);
  }

  /// #10 拉取咨询师详情（按 imUserId 查询优先，否则按 consultantId）。
  /// iOS 参照：XYCounselorDetailViewModel.fetchDetail。
  Future<ConsultantDetail> fetchDetail({
    int? consultantId,
    String? imUserId,
  }) async {
    final body = <String, dynamic>{};
    if (imUserId != null && imUserId.isNotEmpty) {
      body['imUserId'] = imUserId;
    } else {
      body['consultantId'] = consultantId ?? 0;
    }
    final data = await _client.postData<ConsultantDetail>(
      detailPath,
      body,
      decoder: (json) =>
          ConsultantDetail.fromJson(Map<String, dynamic>.from(json as Map)),
    );
    if (data == null) throw const ApiException(code: -1, msg: '详情数据为空');
    return data;
  }

  /// #11 拉取咨询师评价列表（分页）。
  /// iOS 参照：XYCounselorDetailViewModel.fetchReviews（pageSize 5）。
  Future<({List<ConsultantReview> rows, int total})> fetchReviewList({
    required int consultantId,
    required int pageNum,
    int pageSize = 5,
  }) async {
    final paged = await _client.postPaged<ConsultantReview>(
      reviewListPath,
      {'consultantId': consultantId, 'pageNum': pageNum, 'pageSize': pageSize},
      rowDecoder: (json) =>
          ConsultantReview.fromJson(Map<String, dynamic>.from(json as Map)),
    );
    return (rows: paged.rows, total: paged.total);
  }

  /// #12 预约下单。body 由 BookingViewModel.buildBookBody() 组装：
  /// consultantId / capabilityId / availabilityId /
  /// supportMode("1/2/3" 字符串) / appointmentTime("yyyy-MM-dd HH:mm:ss")。
  /// iOS 参照：XYAppointmentTimeSheetViewModel.book（orderId 为空视为失败）。
  Future<ConsultOrder> book(Map<String, dynamic> body) async {
    final data = await _client.postData<ConsultOrder>(
      bookPath,
      body,
      decoder: (json) =>
          ConsultOrder.fromJson(Map<String, dynamic>.from(json as Map)),
    );
    if (data == null || data.orderId == null || data.orderId!.isEmpty) {
      throw const ApiException(code: -1, msg: '未获取到订单号');
    }
    return data;
  }
}
