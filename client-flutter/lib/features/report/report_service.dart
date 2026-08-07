import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/im/im_service.dart';
import '../../core/network/api_response.dart';
import 'report_api.dart';
import 'report_models.dart';

/// 用户端拉黑咨询师成功后递增，真人倾听师列表据此刷新。
/// iOS 参照：Notification.Name.XYCounselorBlocked。
final counselorBlockedTickProvider = StateProvider<int>((ref) => 0);

/// 任意端拉黑成功后递增，驱动消息/工作台会话列表重拉。
/// （删会话后 Stream 推送可能被未监听方错过，用 tick 兜底 invalidate。）
final imPeerBlockedTickProvider = StateProvider<int>((ref) => 0);

final reportServiceProvider = Provider<ReportService>((ref) {
  return ReportService(
    api: ref.read(reportApiProvider),
    im: ref.read(imServiceProvider),
  );
});

/// 举报 / 拉黑业务编排。
/// 参照 iOS XYReportViewModel + XYBlockManager（IM 黑名单底层已由腾讯 IM 迁至网易云信）。
class ReportService {
  ReportService({required ReportApi api, required ImService im})
      : _api = api,
        _im = im;

  final ReportApi _api;
  final ImService _im;

  Future<List<ReportReason>> fetchReportReasons() => _api.fetchReportReasons();

  Future<void> submitReport({
    required ReportTargetType targetType,
    required String targetId,
    required ReportReason reason,
    String? reasonDetail,
  }) {
    return _api.submitReport(
      targetType: targetType,
      targetId: targetId,
      reasonCode: reason.code,
      reasonDetail: reasonDetail,
    );
  }

  /// 拉黑：IM 黑名单 → 静默上报后端 → 删除 C2C 会话。
  ///
  /// - 用户端拉黑咨询师：传 [consultantId]
  /// - 咨询师端拉黑用户：传 [blockedUserId]
  Future<void> blockUser({
    required String imUserId,
    String? consultantId,
    String? blockedUserId,
  }) async {
    try {
      await _im.addToBlackList(imUserId);
    } on ImException catch (e) {
      throw ApiException(code: e.code, msg: e.desc);
    }
    // 后端留档失败不阻断（苹果要求通知开发者，但 UI 已完成拉黑）
    await _api.reportBlockToBackend(
      consultantId: consultantId,
      blockedUserId: blockedUserId,
    );
    await _im.deleteC2CConversation(imUserId);
  }

  /// 解除拉黑：IM 黑名单 → 静默后端 cancel。
  /// IM 解除为主（门控）：失败抛 [ApiException] → 调用方提示且不调后端、不刷新；
  /// IM 成功后后端记录删除 best-effort（静默）。
  Future<void> unblockUser({
    required String imUserId,
    required int blockedUserId,
  }) async {
    try {
      await _im.removeFromBlackList(imUserId);
    } on ImException catch (e) {
      throw ApiException(code: e.code, msg: e.desc);
    }
    // IM 已解除，后端记录删除 best-effort（失败不阻断）
    await _api.cancelBlock(blockedUserId: blockedUserId);
  }
}
