import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import 'order_models.dart';

final orderApiProvider =
    Provider<OrderApi>((ref) => OrderApi(ref.read(apiClientProvider)));

/// 预约订单接口封装（契约 §2 #13-14）。
/// iOS 参照：XYMyAppointmentOrdersViewModel.fetchOrders
/// + XYAppointmentOrderActionRouter.cancelOrder。
class OrderApi {
  OrderApi(this._client);

  final ApiClient _client;

  // ---------- 路径常量 ----------
  /// #13 我的预约订单（分页）
  static const myListPath = '/app/consultant/order/my-list';

  /// #14 取消预约
  static const cancelPath = '/app/consultant/order/cancel';

  /// 用户申请改期；咨询师确认前仅创建工作流申请，不改变订单履约状态。
  static const reschedulePath = '/app/consultant/order/reschedule';
  static const rescheduleTimePath = '/app/consultant/order/reschedule-time';

  /// 用户端进咨询室时段校验（iOS XYConsultRoomService.checkRoomEnter）
  static const roomJoinPath = '/app/consultant/room/join';

  /// NERTC 安全模式进房 Token（body：orderId；返回 {token, uid, channelName, expireAt}）
  static const roomTokenPath = '/app/consultant/room/token';

  /// ASR 字幕上报（body：{orderId,channelName,uid,captions}；Java 网关转发至归档服务）
  static const roomCaptionPath = '/app/consultant/room/caption';

  /// Mock/后端会话结束投影：用户离开后进入等待咨询师确认回顾。
  static const roomCompletePath = '/app/consultant/room/complete';

  /// #13 拉取我的预约订单（pageNum 从 1 起）。
  /// iOS 参照：XYMyAppointmentOrdersViewModel.fetchOrders（pageSize 默认 10）。
  Future<({List<AppointmentOrderItem> rows, int total})> fetchMyOrders({
    required int pageNum,
    int pageSize = 10,
  }) async {
    final paged = await _client.postPaged<AppointmentOrderItem>(
      myListPath,
      {'pageNum': pageNum, 'pageSize': pageSize},
      rowDecoder: (json) =>
          AppointmentOrderItem.fromJson(Map<String, dynamic>.from(json as Map)),
    );
    return (rows: paged.rows, total: paged.total);
  }

  /// #14 取消预约。body：orderId。
  /// iOS 参照：XYAppointmentOrderActionRouter.cancelOrder。
  Future<void> cancelOrder(String orderId) async {
    await _client.postData<dynamic>(cancelPath, {'orderId': orderId});
  }

  Future<void> requestReschedule({
    required String orderId,
    required String reason,
  }) async {
    await _client.postMessage(reschedulePath, {
      'orderId': orderId,
      'reason': reason,
    });
  }

  Future<void> selectRescheduleTime({
    required String orderId,
    required String appointmentTime,
  }) async {
    await _client.postMessage(rescheduleTimePath, {
      'orderId': orderId,
      'appointmentTime': appointmentTime,
    });
  }

  /// 用户端进房时段校验（body：orderId；code==200 视为可进房）。
  /// iOS 参照：XYConsultRoomService.checkRoomEnter →
  /// POST /app/consultant/room/join。
  Future<void> joinConsultRoom(int orderId) {
    return _client.postMessage(roomJoinPath, {'orderId': orderId});
  }

  Future<void> completeConsultRoom(int orderId) {
    return _client.postMessage(roomCompletePath, {'orderId': orderId});
  }

  /// 获取咨询室 NERTC 进房 Token（安全模式）。失败抛 ApiException；data 为空返回 null。
  ///
  /// 返回服务端推导的 uid 与 token——客户端须用此 uid 调 joinChannel（不得本地另算 uid，
  /// 否则 Dart/Java hashCode 不一致会导致进房失败；服务端推导亦可防 uid 冒充）。
  Future<({String token, int uid})?> fetchConsultRoomToken(
      String orderId) async {
    final data = await _client.postData<Map<String, dynamic>>(
      roomTokenPath,
      {'orderId': orderId},
      decoder: (json) => Map<String, dynamic>.from(json as Map),
    );
    if (data == null) return null;
    final token = data['token'] as String?;
    final uid = (data['uid'] as num?)?.toInt();
    if (token == null || token.isEmpty || uid == null) return null;
    return (token: token, uid: uid);
  }

  /// 上报一批 ASR 字幕（经 Java 网关转发至归档服务，客户端免打包密钥）。
  /// best-effort：失败抛 ApiException，由引擎 _flushCaptions 捕获记日志，不影响通话。
  Future<void> uploadConsultCaptions({
    required String orderId,
    required String channelName,
    required int uid,
    required List<Map<String, dynamic>> captions,
  }) {
    return _client.postMessage(roomCaptionPath, {
      'orderId': orderId,
      'channelName': channelName,
      'uid': uid,
      'captions': captions,
    });
  }

  /// 按 orderId 在「我的预约订单」中查找订单（无独立订单详情接口，
  /// 契约 §2 仅有 my-list；供订单详情页 / 支付页按 id 回填展示数据）。
  /// 最多向前翻 [maxPages] 页，找不到返回 null。
  Future<AppointmentOrderItem?> findOrderById(
    String orderId, {
    int maxPages = 5,
    int pageSize = 10,
  }) async {
    for (var page = 1; page <= maxPages; page++) {
      final result = await fetchMyOrders(pageNum: page, pageSize: pageSize);
      for (final item in result.rows) {
        if (item.orderId == orderId) return item;
      }
      if (result.rows.length < pageSize) return null; // 已到末页
    }
    return null;
  }
}
