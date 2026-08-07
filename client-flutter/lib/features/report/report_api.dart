import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import 'report_models.dart';

final reportApiProvider = Provider<ReportApi>((ref) {
  return ReportApi(ref.read(apiClientProvider));
});

/// 举报 / 拉黑 HTTP API。
/// iOS 参照：XYReportViewModel。
class ReportApi {
  ReportApi(this._client);

  final ApiClient _client;

  /// 拉取举报理由列表（POST /app/report/reasons）
  Future<List<ReportReason>> fetchReportReasons() async {
    final data = await _client.postData<List<ReportReason>>(
      '/app/report/reasons',
      {},
      decoder: (json) {
        if (json is! List) return const [];
        return [
          for (final item in json)
            if (item is Map)
              ReportReason.fromJson(Map<String, dynamic>.from(item)),
        ];
      },
    );
    return data ?? const [];
  }

  /// 提交举报（POST /app/report/submit）
  Future<void> submitReport({
    required ReportTargetType targetType,
    required String targetId,
    required String reasonCode,
    String? reasonDetail,
  }) async {
    final body = <String, dynamic>{
      'targetType': targetType.rawValue,
      'targetId': targetId,
      'reasonCode': reasonCode,
    };
    final detail = reasonDetail?.trim();
    if (detail != null && detail.isNotEmpty) {
      body['reasonDetail'] = detail;
    }
    await _client.postMessage('/app/report/submit', body);
  }

  /// 后台上报拉黑记录（POST /app/block/add）。
  /// 静默：失败不抛，与 iOS reportBlockToBackend 一致。
  Future<void> reportBlockToBackend({
    String? consultantId,
    String? blockedUserId,
  }) async {
    final body = <String, dynamic>{};
    if (consultantId != null && consultantId.isNotEmpty) {
      body['consultantId'] = consultantId;
    } else if (blockedUserId != null && blockedUserId.isNotEmpty) {
      body['blockedUserId'] = blockedUserId;
    }
    if (body.isEmpty) return;
    try {
      await _client.postMessage('/app/block/add', body);
    } catch (_) {
      // 静默：IM 拉黑已生效，后端留档失败不打断用户
    }
  }

  /// 黑名单列表（POST /app/block/list，分页，pageNum 从 1 起）。
  static const blockListPath = '/app/block/list';

  /// 解除黑名单（POST /app/block/cancel）。
  /// body 固定 {blockedUserId}（取自 /app/block/list 返回的 blockedUserId）。
  static const blockCancelPath = '/app/block/cancel';

  /// 拉取黑名单列表（分页）。
  Future<({List<BlockedUserItem> rows, int total})> fetchBlockList({
    required int pageNum,
    required int pageSize,
  }) async {
    final paged = await _client.postPaged<BlockedUserRow>(
      blockListPath,
      {'pageNum': pageNum, 'pageSize': pageSize},
      rowDecoder: (json) =>
          BlockedUserRow.fromJson(Map<String, dynamic>.from(json as Map)),
    );
    return (
      rows: paged.rows.map(BlockedUserItem.fromRow).toList(),
      total: paged.total,
    );
  }

  /// 解除黑名单留档记录（POST /app/block/cancel）。
  /// best-effort、静默：IM 解除已生效后调用，后端记录删除失败不阻断
  /// （对称 [reportBlockToBackend]）。
  Future<void> cancelBlock({required int blockedUserId}) async {
    try {
      await _client.postMessage(blockCancelPath, {'blockedUserId': blockedUserId});
    } catch (_) {
      // 静默：IM 解除已生效，后端记录删除失败不阻断
    }
  }
}
