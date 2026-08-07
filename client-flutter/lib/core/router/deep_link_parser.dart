import 'route_paths.dart';

/// 深链解析结果：内部路径 + 业务参数。
class DeepLinkTarget {
  const DeepLinkTarget({required this.path, this.params = const {}});

  /// 内部路由路径（见 [RoutePaths]）
  final String path;

  /// 透传给页面的业务参数（已按契约做多键归一）
  final Map<String, String> params;

  /// 构建 go_router location（query 参数自动编码）。
  String toLocation() {
    if (params.isEmpty) return path;
    return Uri(path: path, queryParameters: params).toString();
  }

  @override
  String toString() => 'DeepLinkTarget($toLocation)';
}

/// 深链解析器（纯 Dart，不依赖 widget，可单测）。
///
/// 契约来源：contracts/route_code_contract.md
/// - §0：scheme 兼容 currantmind / nav，解析只看 scheme + query；
///       RtId 为通用业务 ID 载体，Android 多键名兼容；
///       http(s) 链接 → 通用 WebView；未知 code 提示「功能开发中」。
/// - §1：1001-1010 双端契约码映射。
/// - §2：9000-9007 iOS 内部导航码映射。
class DeepLinkParser {
  DeepLinkParser._();

  /// 契约 §0：scheme
  static const String _scheme = 'nanjingxinyu';

  /// 订单 id 多键兼容（契约 §0：RtId → orderId → order_id → orderID → rtid）
  static const List<String> orderIdKeys = <String>[
    'RtId',
    'orderId',
    'order_id',
    'orderID',
    'rtid',
  ];

  /// 咨询师 id 多键兼容（契约 §0：RtId → counselorId → consultantId → consultant_id）
  static const List<String> consultantIdKeys = <String>[
    'RtId',
    'counselorId',
    'consultantId',
    'consultant_id',
  ];

  /// 1006 咨询室需全参数透传的字段（契约 §1，orderId 走多键兼容）
  static const List<String> _consultRoomKeys = <String>[
    'supportMode',
    'roomId',
    'roomName',
    'startTime',
    'endTime',
    'imUserId',
    'userName',
    'userAvatar',
  ];

  /// 解析入口。无法识别（非约定 scheme / 未知 code / 缺 routeTypeCode）→ null，
  /// 由上层提示「功能开发中」。
  static DeepLinkTarget? parse(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null) return null;

    // 契约 §0：http(s) 链接 → 通用 WebView
    if (uri.scheme == 'http' || uri.scheme == 'https') {
      return DeepLinkTarget(
        path: RoutePaths.webview,
        params: <String, String>{'url': url.trim()},
      );
    }

    if (uri.scheme != _scheme) return null;
    return _parseScheme(uri);
  }

  /// 契约 §0：host 兼容 currantmind / nav，只看 query 中的 routeTypeCode。
  static DeepLinkTarget? _parseScheme(Uri uri) {
    final q = uri.queryParameters;
    final code = q['routeTypeCode'];
    if (code == null || code.isEmpty) return null;

    switch (code) {
      // ---------- 契约 §1：1001-1003 量表占位 → 映射测评列表 ----------
      case '1001':
      case '1002':
      case '1003':
        return const DeepLinkTarget(path: RoutePaths.mineAssessments);

      // 1004：咨询师主页，RtId=咨询师业务 id（多键兼容）
      case '1004':
        final id = _firstNonEmpty(q, consultantIdKeys);
        return DeepLinkTarget(
          path: RoutePaths.consultantDetail,
          params: <String, String>{if (id != null) 'consultantId': id},
        );

      // 1005：IM 聊天，RtId=对方 IM userId（空 → 机器人），userName/avatar 可缺省
      case '1005':
        final imUserId = _firstNonEmpty(q, const <String>['RtId', 'imUserId']);
        return DeepLinkTarget(
          path: RoutePaths.chat,
          params: <String, String>{
            if (imUserId != null) 'imUserId': imUserId,
            if (_nonEmpty(q['userName']) != null) 'userName': q['userName']!,
            if (_nonEmpty(q['avatar']) != null) 'avatar': q['avatar']!,
          },
        );

      // 1006：咨询室，全参数透传（契约 §1；初期桥接原生咨询室）
      case '1006':
        final orderId = _firstNonEmpty(q, orderIdKeys);
        return DeepLinkTarget(
          path: RoutePaths.consultRoom,
          params: <String, String>{
            if (orderId != null) 'orderId': orderId,
            for (final k in _consultRoomKeys)
              if (_nonEmpty(q[k]) != null) k: q[k]!,
          },
        );

      // 1007：咨询小结与建议，RtId=orderId
      case '1007':
        final orderId = _firstNonEmpty(q, orderIdKeys);
        return DeepLinkTarget(
          path: RoutePaths.summaryDetail,
          params: <String, String>{if (orderId != null) 'orderId': orderId},
        );

      // 1008：去评价，orderId + counselorId/consultantId（契约 §1）
      // 姓名/头像多键透传（iOS resolvedCounselor* 契约；路由层归一，
      // 姓名缺省回退「咨询师」），否则 IM 评价卡片进入的评价页无头像。
      case '1008':
        final orderId = _firstNonEmpty(q, orderIdKeys);
        final counselorId = _firstNonEmpty(q, consultantIdKeys);
        final counselorName = _firstNonEmpty(
          q,
          const <String>['counselorName', 'name', 'consultantName'],
        );
        final counselorAvatar = _firstNonEmpty(
          q,
          const <String>['counselorAvatar', 'avatar', 'consultantAvatar'],
        );
        return DeepLinkTarget(
          path: RoutePaths.evaluate,
          params: <String, String>{
            if (orderId != null) 'orderId': orderId,
            if (counselorId != null) 'counselorId': counselorId,
            if (counselorName != null) 'counselorName': counselorName,
            if (counselorAvatar != null) 'counselorAvatar': counselorAvatar,
          },
        );

      // 1010：写咨询小结（咨询师端），RtId=orderId
      case '1010':
        final orderId = _firstNonEmpty(q, orderIdKeys);
        return DeepLinkTarget(
          path: RoutePaths.consultRecord,
          params: <String, String>{if (orderId != null) 'orderId': orderId},
        );

      // ---------- 契约 §2：9000 段 iOS 内部导航码 ----------
      case '9000':
        return const DeepLinkTarget(path: RoutePaths.ai);
      case '9001':
        return const DeepLinkTarget(path: RoutePaths.orders);
      case '9002':
        return const DeepLinkTarget(path: RoutePaths.mineSummaries);
      case '9003':
        return const DeepLinkTarget(path: RoutePaths.mineAssessments);

      // 9004：测评报告页，参数 assessmentId（=userAssessId）
      case '9004':
        final id = _firstNonEmpty(
          q,
          const <String>['assessmentId', 'userAssessId', 'id'],
        );
        return DeepLinkTarget(
          path: RoutePaths.assessmentReport,
          params: <String, String>{if (id != null) 'assessmentId': id},
        );

      // 9005：数字心理画像，参数 userId（咨询师端查看指定用户）
      case '9005':
        final userId = _firstNonEmpty(
          q,
          const <String>['userId', 'RtId', 'id'],
        );
        return DeepLinkTarget(
          path: RoutePaths.personality,
          params: <String, String>{if (userId != null) 'userId': userId},
        );

      case '9006':
        return const DeepLinkTarget(path: RoutePaths.mineSecurity);

      case '9007':
        return const DeepLinkTarget(path: RoutePaths.mineFeedback);

      // 未知 code → null（契约 §0：提示「功能开发中」）
      default:
        return null;
    }
  }

  /// 按优先级取首个非空值（契约 §0 多键兼容策略）。
  static String? _firstNonEmpty(Map<String, String> q, List<String> keys) {
    for (final k in keys) {
      final v = _nonEmpty(q[k]);
      if (v != null) return v;
    }
    return null;
  }

  static String? _nonEmpty(String? v) => (v == null || v.isEmpty) ? null : v;
}
