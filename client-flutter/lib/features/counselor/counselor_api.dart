import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';
import '../mine/personality_models.dart';
import 'counselor_models.dart';

final counselorApiProvider =
    Provider<CounselorApi>((ref) => CounselorApi(ref.read(apiClientProvider)));

/// 咨询师端工作台接口封装（契约 §6 #30-37）。
/// iOS 参照：XYCounselorModule XYCounselorWorkbenchViewModel /
/// XYCounselorAppointmentDetailViewModel / XYCounselorConsultRecordViewModel
/// 中各 postJSON/postJSONPaged 调用；
/// Android 参照：consultant/internet/ConsultantApi.kt。
class CounselorApi {
  CounselorApi(this._client);

  final ApiClient _client;

  // ---------- 路径常量（契约 §6） ----------

  /// #30 咨询师端开始咨询/进房校验
  static const orderStartPath = '/consultant/order/start';

  /// #31 工作台首页（含 unreadMessageCount）
  static const homeIndexPath = '/consultant/home/index';

  /// #32 待处理预约（分页）
  static const pendingListPath = '/consultant/home/pendingList';

  /// #33 已完成预约（分页）
  static const completedListPath = '/consultant/home/completedList';

  /// #34 预约单详情
  static const orderDetailPath = '/consultant/home/orderDetail';

  /// #35 过往接待记录（分页）
  /// ⚠ iOS API.md 未列此接口，已按 Android 契约实现，待后端确认。
  static const pastConsultationsPath = '/consultant/home/pastConsultations';

  /// #36 咨询师查看用户画像（参数 userId）。
  /// iOS 参照：XYPersonalityViewModel.fetchPersonality（userId 非空）。
  static const userProfilePath = '/consultant/home/userProfile';

  /// 用户端自身画像（userId 为空时）。
  /// iOS 参照：XYPersonalityViewModel.fetchPersonality（userId nil）。
  static const mineProfilePath = '/app/mine/profile';

  /// #37 保存小结与建议
  static const summarySavePath = '/consultant/summary/save';

  /// 小结详情（iOS API.md 列出；⚠ Android 前端未见调用，待后端确认）
  static const summaryDetailPath = '/consultant/summary/detail';

  /// 每页数量（iOS XYCounselorWorkbenchViewModel.pageSize）
  static const pageSize = 10;

  // ---------------- 工作台首页 ----------------

  /// #31 拉取工作台首页（咨询师信息 + 统计 + 未读消息数）。
  /// iOS 参照：XYCounselorWorkbenchViewModel.fetchHomeIndex。
  Future<CounselorHomeIndex> fetchHomeIndex() async {
    final data = await _client.postData<CounselorHomeIndex>(
      homeIndexPath,
      const {},
      decoder: (json) =>
          CounselorHomeIndex.fromJson(Map<String, dynamic>.from(json as Map)),
    );
    if (data == null) {
      throw const ApiException(code: -1, msg: '工作台数据为空');
    }
    return data;
  }

  // ---------------- 预约单 / 已咨询列表 ----------------

  /// #32 拉取待处理预约列表（分页，pageNum 从 1 起）。
  /// iOS 参照：XYCounselorWorkbenchViewModel.fetchPendingList。
  Future<({List<CounselorPendingOrderItem> rows, int total})> fetchPendingList({
    required int pageNum,
    int pageSize = CounselorApi.pageSize,
  }) async {
    final paged = await _client.postPaged<CounselorWorkbenchOrderRow>(
      pendingListPath,
      {'pageNum': pageNum, 'pageSize': pageSize},
      rowDecoder: (json) => CounselorWorkbenchOrderRow.fromJson(
          Map<String, dynamic>.from(json as Map)),
    );
    return (
      rows: [
        for (final row in paged.rows) CounselorPendingOrderItem.fromRow(row),
      ],
      total: paged.total,
    );
  }

  /// #33 拉取已咨询列表（分页，pageNum 从 1 起）。
  /// iOS 参照：XYCounselorWorkbenchViewModel.fetchCompletedList。
  Future<({List<CounselorCompletedOrderItem> rows, int total})>
      fetchCompletedList({
    required int pageNum,
    int pageSize = CounselorApi.pageSize,
  }) async {
    final paged = await _client.postPaged<CounselorWorkbenchOrderRow>(
      completedListPath,
      {'pageNum': pageNum, 'pageSize': pageSize},
      rowDecoder: (json) => CounselorWorkbenchOrderRow.fromJson(
          Map<String, dynamic>.from(json as Map)),
    );
    return (
      rows: [
        for (final row in paged.rows) CounselorCompletedOrderItem.fromRow(row),
      ],
      total: paged.total,
    );
  }

  // ---------------- 预约单详情 ----------------

  /// #34 拉取预约订单详情（参数 orderId）。
  /// iOS 参照：XYCounselorAppointmentDetailViewModel.fetchOrderDetail。
  Future<CounselorOrderDetail> fetchOrderDetail(int orderId) async {
    final data = await _client.postData<CounselorOrderDetail>(
      orderDetailPath,
      {'orderId': orderId},
      decoder: (json) =>
          CounselorOrderDetail.fromJson(Map<String, dynamic>.from(json as Map)),
    );
    if (data == null) {
      throw const ApiException(code: -1, msg: '订单详情为空');
    }
    return data;
  }

  /// #35 拉取过往接待记录分页（参数 orderId/pageNum/pageSize）。
  /// iOS 参照：XYCounselorAppointmentDetailViewModel.fetchPastConsultations
  /// （详情页「查看全部」展开后分页拉取）。
  /// ⚠ iOS API.md 未列此接口，已按 Android 契约实现，待后端确认。
  Future<({List<CounselorHistoryItem> rows, int total})>
      fetchPastConsultations({
    required int orderId,
    required int pageNum,
    int pageSize = CounselorApi.pageSize,
  }) async {
    final paged = await _client.postPaged<CounselorPastConsultation>(
      pastConsultationsPath,
      {'orderId': orderId, 'pageNum': pageNum, 'pageSize': pageSize},
      rowDecoder: (json) => CounselorPastConsultation.fromJson(
          Map<String, dynamic>.from(json as Map)),
    );
    return (
      rows: [
        for (final row in paged.rows) CounselorHistoryItem.fromRecord(row),
      ],
      total: paged.total,
    );
  }

  // ---------------- 开始咨询 ----------------

  /// #30 开始咨询/进房校验（参数 orderId；code==200 视为校验通过）。
  /// iOS 参照：预约单 cell「进入咨询室」enterConsultRoom（iOS 直接凭 roomId
  /// 进房；Android checkRoomEnter 先调本接口校验，Flutter 取 Android 语义——
  /// 校验通过后再进咨询室占位页，待阶段 8 桥接原生音视频）。
  Future<void> startOrder(int orderId) {
    return _client.postMessage(orderStartPath, {'orderId': orderId});
  }

  // ---------------- 数字心理画像 ----------------

  /// #36 拉取数字心理画像。
  /// iOS 参照：XYPersonalityViewModel.fetchPersonality——
  /// userId 非空 → /consultant/home/userProfile；空 → /app/mine/profile。
  Future<PersonalityProfile> fetchPersonality({int? userId}) async {
    final path = userId == null ? mineProfilePath : userProfilePath;
    final body = <String, dynamic>{
      if (userId != null) 'userId': userId,
    };
    final data = await _client.postData<PersonalityProfile>(
      path,
      body,
      decoder: (json) => PersonalityProfile.fromJson(
          Map<String, dynamic>.from(json as Map)),
    );
    if (data == null) {
      throw const ApiException(code: -1, msg: '画像数据为空');
    }
    return data;
  }

  // ---------------- 小结与建议 ----------------

  /// #37 保存小结与建议（参数 orderId/content/advice[]）。
  /// iOS 参照：XYCounselorConsultRecordViewModel.submitRecord。
  Future<void> saveSummary({
    required int orderId,
    required String content,
    required List<String> advice,
  }) {
    return _client.postMessage(
      summarySavePath,
      {'orderId': orderId, 'content': content, 'advice': advice},
    );
  }

  /// 拉取小结详情（参数 orderId），回填 AI 提取三段。
  /// iOS 参照：XYCounselorConsultRecordViewModel.fetchSummaryDetail。
  /// ⚠ Android 前端未见调用该接口，字段以 iOS 为准，待后端确认；
  /// 小结正文与行动建议不回填（iOS 由咨询师自行填写）。
  Future<CounselorSummaryDetail?> fetchSummaryDetail(int orderId) {
    return _client.postData<CounselorSummaryDetail>(
      summaryDetailPath,
      {'orderId': orderId},
      decoder: (json) => CounselorSummaryDetail.fromJson(
          Map<String, dynamic>.from(json as Map)),
    );
  }
}
