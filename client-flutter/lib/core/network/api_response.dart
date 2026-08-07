// RuoYi 响应壳解析（契约见 contracts/api_contract.md §0）。
// 参照 iOS XYNetworkManager 对 code/msg/data 与 code/msg/total/rows 的处理。

/// 业务异常：code + msg。
class ApiException implements Exception {
  const ApiException({required this.code, required this.msg});

  final int code;
  final String msg;

  /// 会话过期：HTTP 401 或业务 code==401（契约 §0，统一登出回登录页）。
  bool get isSessionExpired => code == 401;

  @override
  String toString() => 'ApiException(code: $code, msg: $msg)';
}

/// 普通响应壳：code / msg / data。
class ApiResponse<T> {
  const ApiResponse({required this.code, this.msg, this.data});

  final int code;
  final String? msg;
  final T? data;

  /// 成功判定：code == 200（契约 §0）。
  bool get isSuccess => code == 200;

  /// 会话过期：业务 code==401（契约 §0）。
  bool get isSessionExpired => code == 401;

  /// [decoder] 将原始 data JSON 转为 T；不传时按 T 直接强转。
  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json)? decoder,
  ) {
    final rawData = json['data'];
    return ApiResponse<T>(
      code: (json['code'] as num?)?.toInt() ?? -1,
      msg: json['msg'] as String?,
      data:
          decoder != null && rawData != null ? decoder(rawData) : rawData as T?,
    );
  }
}

/// 分页响应壳：code / msg / total / rows。
/// 注意：顶层无 data 包装，结构与 [ApiResponse] 不同（契约 §0）。
class PagedResponse<T> {
  const PagedResponse({
    required this.code,
    this.msg,
    required this.total,
    required this.rows,
  });

  final int code;
  final String? msg;
  final int total;
  final List<T> rows;

  bool get isSuccess => code == 200;

  /// [rowDecoder] 解析 rows 中的单个元素。
  factory PagedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json) rowDecoder,
  ) {
    final rawRows = (json['rows'] as List?) ?? const [];
    return PagedResponse<T>(
      code: (json['code'] as num?)?.toInt() ?? -1,
      msg: json['msg'] as String?,
      total: (json['total'] as num?)?.toInt() ?? rawRows.length,
      rows: rawRows.map(rowDecoder).toList(),
    );
  }
}
