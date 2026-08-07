import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';

/// 咨询完成状态（评价是否已提交 + 小结是否已发布）。
/// 用于卡片「已完成」态按 app 自有数据渲染（ADR-0005），不再依赖 IM 消息原地编辑。
class ConsultStatus {
  const ConsultStatus({this.reviewDone = false, this.summaryDone = false});

  /// 当前用户是否已对该订单提交评价。
  final bool reviewDone;

  /// 该订单是否已有已发布的咨询小结。
  final bool summaryDone;
}

final consultStatusApiProvider = Provider<ConsultStatusApi>(
  (ref) => ConsultStatusApi(ref.read(apiClientProvider)),
);

/// 咨询完成状态接口（POST /app/mine/order/consult-status）。
class ConsultStatusApi {
  ConsultStatusApi(this._client);

  final ApiClient _client;

  static const path = '/app/mine/order/consult-status';

  /// 按订单拉取完成状态；失败返回未完成（卡片回退 IM 消息 type，不阻断渲染）。
  Future<ConsultStatus> fetchByOrder(int orderId) async {
    try {
      final data = await _client.postData<Map<String, dynamic>>(
        path,
        {'orderId': orderId},
        decoder: (json) => Map<String, dynamic>.from(json as Map),
      );
      if (data == null) return const ConsultStatus();
      return ConsultStatus(
        reviewDone: data['reviewDone'] == true,
        summaryDone: data['summaryDone'] == true,
      );
    } catch (_) {
      return const ConsultStatus();
    }
  }
}
