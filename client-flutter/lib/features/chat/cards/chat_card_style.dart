import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/deep_link_parser.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_toast.dart';
import 'chat_card_logic.dart';

/// 聊天卡片共享样式与路由工具。
/// iOS 参照：TUIKit/TUIChat/UI_Minimalist/Cell/Custom/*.swift 各卡片 Layout 枚举。
class ChatCardStyle {
  ChatCardStyle._();

  /// 居中系统卡宽（iOS 参照：*_middle CellData resolvedCardWidth =
  /// min(345, 屏宽-48)）；方向性白卡宽 260（TUISummaryAdviseCellData.chatCardWidth）。
  static const double middleCardWidth = 248;
  static const double directionCardWidth = 260;

  /// 卡片圆角（Figma 32÷2）
  static const double cardRadius = 16;

  /// 白底卡投影：#E6EAEE @50% offset(0,3) blur6
  /// （iOS 参照：TUIRemindWindowMiddleCell cardView shadow）
  static List<BoxShadow> cardShadow({double opacity = 0.5}) => [
        BoxShadow(
          color: AppColors.cardShadow.withValues(alpha: opacity * 0.35),
          offset: const Offset(0, 1),
          blurRadius: 4,
        ),
      ];

  /// begin_chat_middle 投影：黑 6% offset(0,2) blur6
  /// （iOS 参照：TUIBeginChatMiddleCell cardView shadow）
  static const List<BoxShadow> beginChatShadow = [
    BoxShadow(color: Color(0x0A000000), offset: Offset(0, 1), blurRadius: 4),
  ];

  /// 渐变主按钮圆角（40 高胶囊）
  static const double buttonRadius = 14;

  /// 渐变主按钮（靛蓝 #4D5CFF→#A8A8FF，remind/summary 详情用）
  static const LinearGradient indigoButtonGradient = LinearGradient(
    colors: [Color(0xFF006A67), Color(0xFF006A67)],
  );

  /// 渐变主按钮（青绿 #00D8E0→#00AFBE，evaluate/summary 填写/工具卡用）
  static const LinearGradient tealButtonGradient = LinearGradient(
    colors: [Color(0xFF006A67), Color(0xFF006A67)],
  );

  /// 卡片 link 统一路由（契约 §3/§4）：
  /// - http(s) → /webview（DeepLinkParser 契约 §0）；
  /// - routeTypeCode=1006 且 supportMode=1 → 仅 Toast 提示不进咨询室
  ///   （iOS 参照：XYChatModule.observeRemindWindowAction 拦截语义；
  ///   文案与 iOS XYToast 一致「文字咨询无需进入咨询室，可在当前页面直接进行」）；
  /// - routeTypeCode=1006 且语音/视频 → push /consult-room，由
  ///   [ConsultRoomBridgePage] → [launchConsultRoom] 做时段校验后进房
  ///   （用户 /app/consultant/room/join，咨询师 /consultant/order/start）；
  /// - 其余 nanjingxinyu:// → DeepLinkParser 映射后 push；
  /// - 无法识别 → Toast「功能开发中」（契约 §0）。
  static void openCardLink(BuildContext context, String? link) {
    if (link == null || link.trim().isEmpty) return;
    final params = parseCardLinkParams(link);
    if (isTextConsultLink(params)) {
      // supportMode=1 文字咨询：不进咨询室，当前聊天页即可咨询
      AppToast.show(context, '文字咨询无需进入咨询室，可在当前页面直接进行');
      return;
    }
    final target = DeepLinkParser.parse(link);
    if (target == null) {
      AppToast.show(context, '功能开发中');
      return;
    }
    // 从聊天会话对端补齐缺失的对方资料（咨询室 / 评价页）
    final routed = _withChatPeer(context, target);
    // 1006：进房前在聊天页 context 上校验，避免桥接页 Toast 无 Overlay
    if (routed.path == RoutePaths.consultRoom) {
      final orderId = routed.params['orderId']?.trim() ?? '';
      final roomId = routed.params['roomId']?.trim() ?? '';
      if (orderId.isEmpty) {
        debugPrint(
          '🟠 [ConsultRoom] 聊天卡拒绝进房：orderId 为空 link=$link',
        );
        AppToast.show(context, '订单信息缺失，无法进入咨询室');
        return;
      }
      if (roomId.isEmpty) {
        debugPrint(
          '🟠 [ConsultRoom] 聊天卡拒绝进房：roomId 为空 '
          'orderId=$orderId link=$link',
        );
        AppToast.show(context, '咨询室信息缺失，无法进入');
        return;
      }
    }
    context.push(routed.toLocation());
  }

  /// 卡片 link 缺对方资料时，用当前聊天会话对端补齐。
  /// - 1006 咨询室：imUserId / userName / userAvatar（兼兼容 avatar）
  /// - 1008 评价：counselorName / counselorAvatar（iOS 由聊天窗写入 routeParams）
  static DeepLinkTarget _withChatPeer(
    BuildContext context,
    DeepLinkTarget target,
  ) {
    final peer = ChatPeerScope.of(context);
    if (peer == null) return target;
    final params = Map<String, String>.from(target.params);
    void fillIfMissing(String key, String? value) {
      if ((params[key] ?? '').isEmpty && value != null && value.isNotEmpty) {
        params[key] = value;
      }
    }

    if (target.path == RoutePaths.consultRoom) {
      fillIfMissing('imUserId', peer.peerImUserId);
      fillIfMissing('userName', peer.peerName);
      fillIfMissing('userAvatar', peer.peerAvatar);
      fillIfMissing('avatar', peer.peerAvatar);
    } else if (target.path == RoutePaths.evaluate) {
      fillIfMissing('counselorName', peer.peerName);
      fillIfMissing('name', peer.peerName);
      fillIfMissing('counselorAvatar', peer.peerAvatar);
      fillIfMissing('avatar', peer.peerAvatar);
    } else {
      return target;
    }
    return DeepLinkTarget(path: target.path, params: params);
  }

  /// 计算居中卡实际宽（屏宽 - 48 与设计宽取小，iOS 参照：resolvedCardWidth）
  static double resolvedMiddleWidth(BuildContext context) {
    final screen = MediaQuery.of(context).size.width;
    final w = screen - 96;
    return w < middleCardWidth ? w : middleCardWidth;
  }

  /// 计算方向性卡实际宽（扣除头像区，iOS 参照：
  /// TUISummaryAdviseCellData.resolvedCardWidth = min(260, 屏宽-74)）
  static double resolvedDirectionWidth(BuildContext context) {
    final screen = MediaQuery.of(context).size.width;
    final w = screen - 74;
    return w < directionCardWidth ? w : directionCardWidth;
  }
}

/// 聊天会话对端信息（挂在会话视图根部，卡片经 BuildContext 向上查找）。
/// 用途：进咨询室时若服务端 deeplink 未带对方 imUserId，用会话对端补齐，
/// 保证会议内「聊天」能 push 到对的 1v1（与咨询师端逻辑一致）。
class ChatPeerScope extends InheritedWidget {
  const ChatPeerScope({
    super.key,
    required this.peerImUserId,
    this.peerName,
    this.peerAvatar,
    required super.child,
  });

  /// 对方 IM userId
  final String? peerImUserId;

  /// 对方昵称（进咨询室透传，可缺省）
  final String? peerName;

  /// 对方头像 URL（进咨询室透传，可缺省）
  final String? peerAvatar;

  static ChatPeerScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ChatPeerScope>();

  @override
  bool updateShouldNotify(ChatPeerScope oldWidget) =>
      peerImUserId != oldWidget.peerImUserId ||
      peerName != oldWidget.peerName ||
      peerAvatar != oldWidget.peerAvatar;
}
