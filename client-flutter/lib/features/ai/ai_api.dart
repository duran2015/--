import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/local_flags.dart';

final aiApiProvider =
    Provider<AiApi>((ref) => AiApi(ref.read(apiClientProvider)));

/// 小鹿 AI 模块接口封装（契约 §7 #38）。
class AiApi {
  AiApi(this._client);

  final ApiClient _client;

  /// #38 首次进入小鹿 AI 页调用，驱动机器人经 IM 发开场消息
  static const guidancePath = '/app/chat/guidance';

  /// 触发 AI 开场引导（code!=200 时抛 ApiException，由调用方决定是否重试）。
  Future<void> triggerGuidance() => _client.postMessage(guidancePath, const {});
}

/// 首进 guidance 触发器：每用户仅一次、接口成功（code==200）才本地标记，
/// 失败不写标记、下次进入重试。
/// iOS 参照：XYAIViewModel.triggerFirstTimeGuidance
/// （本地 key xy_ai_guidance_triggered_{userID}，Flutter 侧由
/// LocalFlags.ai_guidance_triggered_{userId} 承载）。
class AiGuidanceTrigger {
  AiGuidanceTrigger({required Future<void> Function() request, required LocalFlags flags})
      : _request = request,
        _flags = flags;

  final Future<void> Function() _request;
  final LocalFlags _flags;

  /// 按用户维度尝试触发 guidance；返回是否本次实际发起了请求并成功标记。
  /// - userId 为空 → 不触发（iOS：userID nil 直接 return）；
  /// - 已触发过 → 跳过；
  /// - 请求失败 → 不写标记，下次进入再试。
  Future<bool> triggerIfNeeded(String? userId) async {
    if (userId == null || userId.isEmpty) return false;
    if (_flags.isAiGuidanceTriggered(userId)) return false;
    try {
      await _request();
    } catch (_) {
      // 失败不写标记：下次进入再试，保证每个用户至少成功触发一次
      return false;
    }
    await _flags.markAiGuidanceTriggered(userId);
    return true;
  }
}
