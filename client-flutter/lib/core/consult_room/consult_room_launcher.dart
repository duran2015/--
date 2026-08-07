import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/counselor/counselor_api.dart';
import '../../features/order/order_api.dart';
import '../../features/order/order_models.dart';
import '../auth/auth_state.dart';
import '../network/api_response.dart';
import '../router/route_guards.dart';
import '../router/route_paths.dart';
import '../widgets/app_toast.dart';
import 'consult_room_service.dart';

/// 进入咨询室：时段校验 → 原生 present，不 push Flutter 可见页。
///
/// iOS 参照：XYConsultRoomService.presentConsultRoom ——
/// 进房前按角色调时段校验（用户 `/app/consultant/room/join`，
/// 咨询师 `/consultant/order/start`），通过后再拉起会议。
///
/// - 已有悬浮窗 / 进行中会话 → 直接 restore，不再重复校验；
/// - 否则先本地校验 orderId/roomId，再调接口，最后 [presentOrRestore]；
/// - 失败 → Toast；成功进房后 await 直到会议结束（调用方无需 pop）。
///
/// [params.imUserId] 透传给原生，仅用于会议内「聊天」按钮识别对端
/// （进房本身靠 roomId，与对端 id 无关；对端 id 应由调用方直接给出）。
Future<void> launchConsultRoom(
  WidgetRef ref,
  ConsultRoomParams params, {
  BuildContext? context,
}) async {
  void toast(String message) {
    final ctx = context;
    if (ctx != null && ctx.mounted) {
      AppToast.show(ctx, message);
    }
  }

  final service = ref.read(consultRoomServiceProvider);

  // 已在会议中（含悬浮窗）：恢复全屏，不重复打时段校验
  if (!service.isSessionActive) {
    final orderIdRaw = params.orderId?.trim() ?? '';
    final roomId = params.roomId?.trim() ?? '';
    final supportMode = params.supportMode?.trim().toLowerCase() ?? '';

    // 文字咨询：不进音视频会议（聊天卡 openCardLink 已拦截；此处兜底）
    if (supportMode == '1' || supportMode == 'text') {
      toast('文字咨询无需进入咨询室，可在当前页面直接进行');
      return;
    }
    if (orderIdRaw.isEmpty) {
      debugPrint(
        '🟠 [ConsultRoom] 拒绝进房：orderId 为空 '
        'params={orderId: ${params.orderId}, roomId: ${params.roomId}, '
        'supportMode: ${params.supportMode}, roomName: ${params.roomName}, '
        'imUserId: ${params.imUserId}}',
      );
      toast('订单信息缺失，无法进入咨询室');
      return;
    }
    if (roomId.isEmpty) {
      debugPrint(
        '🟠 [ConsultRoom] 拒绝进房：roomId 为空 '
        'params={orderId: ${params.orderId}, roomId: ${params.roomId}, '
        'supportMode: ${params.supportMode}, roomName: ${params.roomName}, '
        'imUserId: ${params.imUserId}}',
      );
      toast('咨询室信息缺失，无法进入');
      return;
    }
    final orderId = int.tryParse(orderIdRaw);
    if (orderId == null || orderId <= 0) {
      debugPrint(
        '🟠 [ConsultRoom] 拒绝进房：orderId 非法 "$orderIdRaw" '
        'params={orderId: ${params.orderId}, roomId: ${params.roomId}, '
        'supportMode: ${params.supportMode}, roomName: ${params.roomName}, '
        'imUserId: ${params.imUserId}}',
      );
      toast('订单信息缺失，无法进入咨询室');
      return;
    }

    try {
      final identity = ref.read(currentIdentityProvider);
      if (identity == RouteGuards.identityConsultant) {
        await ref.read(counselorApiProvider).startOrder(orderId);
      } else {
        await ref.read(orderApiProvider).joinConsultRoom(orderId);
      }
    } on ApiException catch (e) {
      toast(e.msg.isEmpty ? '不在预约时段内，暂无法进入咨询室' : e.msg);
      return;
    }
  }

  final result = await service.presentOrRestore(params);
  if (!result.ok && result.message.isNotEmpty) {
    toast(result.message);
    return;
  }
  // 用户主动结束会议后只进入“等待咨询师确认回顾”，不直接开放评价。
  // 最小化时会话仍活跃，不推进状态。
  if (!service.isSessionActive) {
    final identity = ref.read(currentIdentityProvider);
    final orderId = int.tryParse(params.orderId ?? '');
    if (identity != RouteGuards.identityConsultant && orderId != null) {
      await ref.read(orderApiProvider).completeConsultRoom(orderId);
    }
  }
}

/// 进入与订单咨询师的 1v1 聊天页（订单页「联系咨询师」入口）。
///
/// 聊天对端即订单的 [AppointmentOrderItem.counselorIMUserID]；缺失则
/// 无法确定聊天对象，Toast「订单信息无效」。
Future<void> openOrderCounselorChat(
  BuildContext context,
  AppointmentOrderItem item,
) async {
  final peerId = item.counselorIMUserID.trim();
  if (peerId.isEmpty) {
    AppToast.show(context, '订单信息无效');
    return;
  }
  await context.push(
    Uri(
      path: RoutePaths.chat,
      queryParameters: {
        'targetUserId': peerId,
        if (item.counselorName.isNotEmpty) 'userName': item.counselorName,
        if (item.counselorAvatar != null && item.counselorAvatar!.isNotEmpty)
          'avatar': item.counselorAvatar!,
      },
    ).toString(),
  );
}
