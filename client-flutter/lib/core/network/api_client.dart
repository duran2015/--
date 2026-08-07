import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_state.dart';
import 'api_env.dart';
import 'api_response.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref);
});

/// mock 处理器：path → RuoYi 外壳 JSON。
typedef ApiMockHandler = Map<String, dynamic> Function(
  Map<String, dynamic> body,
);

/// 统一网络层（契约 contracts/api_contract.md §0）。
/// 参照 iOS XYNetworkManager / XYServerTimeMonitor：
/// - 全部 POST + JSON body；
/// - 鉴权头由拦截器统一注入；
/// - HTTP 401 / 业务 code==401 → 全局 onSessionExpired（由 auth 模块注册）；
/// - 响应头 Date 校准服务器时间（支付倒计时用）。
class ApiClient {
  ApiClient(this._ref) {
    _dio.interceptors.addAll([
      _authInterceptor(),
      _serverTimeInterceptor(),
      if (kDebugMode) _logInterceptor(), // release 关闭日志
    ]);
  }

  final Ref _ref;

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiEnv.baseUrl,
      // 契约 §0：connect 10s / receive 20s
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      contentType: 'application/json',
    ),
  );

  /// 暴露 dio 仅供测试注入 HttpClientAdapter。
  @visibleForTesting
  Dio get dio => _dio;

  /// 会话过期回调钩子：HTTP 401 / 业务 code==401 时触发，
  /// 由 auth 模块（AuthController）注册执行统一登出（契约 §0，按 iOS 语义）。
  static void Function()? onSessionExpired;

  // ---------------- mock 开关 ----------------

  /// mock 总开关：后端不可达时页面可开发；默认 false。
  /// 由 [registerDevMocks] 置 true（显式 API_ENV=mock 且 debug，或单测
  /// setUp 手动注册）；默认 live / release 下恒为 false。
  static bool useMock = false;

  static final Map<String, ApiMockHandler> _mockHandlers = {};

  /// 注册某个 path 的 mock 响应（useMock=true 时生效）。
  static void registerMock(String path, ApiMockHandler handler) {
    _mockHandlers[path] = handler;
  }

  static void clearMocks() => _mockHandlers.clear();

  // ---------------- 服务器时间校准 ----------------

  /// 服务器时间与本地时间的偏移（serverTime - localTime）。
  /// 参照 iOS XYServerTimeMonitor，支付倒计时等场景用 [serverNow]。
  Duration _serverTimeOffset = Duration.zero;

  Duration get serverTimeOffset => _serverTimeOffset;

  /// 校准后的服务器当前时间。
  DateTime serverNow() => DateTime.now().add(_serverTimeOffset);

  // ---------------- 鉴权白名单 ----------------

  /// 免鉴权白名单（契约 §1）：这些路径永不附带 Authorization。
  /// 注意：/app/auth/sendSmsCode 不在白名单内——登录场景免鉴权、
  /// 注销场景 requireAuth: true（契约 §1 #2），由调用方按场景传参。
  static const _authFreePaths = <String>{
    '/app/auth/loginByPhone',
    '/app/auth/wechatLogin',
    '/app/auth/appleLogin',
    '/app/auth/bindPhoneLogin',
    '/app/agreement/latest',
  };

  bool _isAuthFree(String path) => _authFreePaths.contains(path);

  // ---------------- 公开请求方法 ----------------

  /// 统一 POST JSON，返回完整响应壳。
  /// 业务 code==401 时触发 onSessionExpired 并抛 [ApiException]；
  /// 其余非 200 不抛，由调用方判定（或改用 [postData]）。
  Future<ApiResponse<T>> post<T>(
    String path,
    Map<String, dynamic> body, {
    bool requireAuth = true,
    T Function(dynamic json)? decoder,
  }) async {
    final json = await _requestJson(path, body, requireAuth: requireAuth);
    final res = ApiResponse<T>.fromJson(json, decoder);
    if (res.isSessionExpired) {
      _notifySessionExpired();
      throw ApiException(code: res.code, msg: res.msg ?? '登录已过期，请重新登录');
    }
    return res;
  }

  /// 直接取 data；code!=200 时抛 [ApiException]（msg 供 toast）。
  Future<T?> postData<T>(
    String path,
    Map<String, dynamic> body, {
    bool requireAuth = true,
    T Function(dynamic json)? decoder,
  }) async {
    final res = await post<T>(
      path,
      body,
      requireAuth: requireAuth,
      decoder: decoder,
    );
    if (!res.isSuccess) {
      throw ApiException(code: res.code, msg: res.msg ?? '请求失败');
    }
    return res.data;
  }

  /// 分页请求，返回 [PagedResponse]（rows 元素由 [rowDecoder] 解析）。
  /// code!=200 时抛 [ApiException]。
  Future<PagedResponse<T>> postPaged<T>(
    String path,
    Map<String, dynamic> body, {
    bool requireAuth = true,
    required T Function(dynamic json) rowDecoder,
  }) async {
    final json = await _requestJson(path, body, requireAuth: requireAuth);
    final paged = PagedResponse<T>.fromJson(json, rowDecoder);
    if (paged.code == 401) {
      _notifySessionExpired();
      throw ApiException(code: paged.code, msg: paged.msg ?? '登录已过期，请重新登录');
    }
    if (!paged.isSuccess) {
      throw ApiException(code: paged.code, msg: paged.msg ?? '请求失败');
    }
    return paged;
  }

  /// 只取 msg 文案（对应 iOS postJSONMessage，如 sendSmsCode、mood 上报）。
  Future<String> postMessage(
    String path,
    Map<String, dynamic> body, {
    bool requireAuth = true,
  }) async {
    final res = await post<dynamic>(path, body, requireAuth: requireAuth);
    if (!res.isSuccess) {
      throw ApiException(code: res.code, msg: res.msg ?? '请求失败');
    }
    return res.msg ?? '';
  }

  // ---------------- 内部实现 ----------------

  Future<Map<String, dynamic>> _requestJson(
    String path,
    Map<String, dynamic> body, {
    required bool requireAuth,
  }) async {
    // mock 拦截：后端不可达时页面可开发
    if (useMock) {
      final mock = _mockHandlers[path];
      if (mock != null) {
        if (kDebugMode) {
          _logMockRequest(path, body, requireAuth: requireAuth);
        }
        final result = mock(body);
        if (kDebugMode) {
          debugPrint(
            '\n✅ [请求成功][mock] POST ${ApiEnv.baseUrl}$path\n'
            'HTTP状态码: 200\n原始JSON: ${_prettyJson(result)}',
          );
        }
        return result;
      }
    }
    try {
      final response = await _dio.post<dynamic>(
        path,
        data: body,
        options: Options(extra: {'requireAuth': requireAuth}),
      );
      final data = response.data;
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
      throw const ApiException(code: -1, msg: '响应格式异常');
    } on ApiException {
      rethrow;
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  /// mock 请求日志：与真实请求一致，先打 URL / 参数 / 头。
  void _logMockRequest(
    String path,
    Map<String, dynamic> body, {
    required bool requireAuth,
  }) {
    final headers = <String, dynamic>{
      'content-type': 'application/json',
    };
    final token = _ref.read(authTokenProvider);
    if (requireAuth &&
        token != null &&
        token.isNotEmpty &&
        !_isAuthFree(path)) {
      headers['Authorization'] = 'Bearer $token';
    }
    debugPrint(
      '\n🌐 [网络请求][mock] POST ${ApiEnv.baseUrl}$path\n'
      '请求头: ${_prettyJson(headers)}\n'
      '请求参数: ${_prettyJson(body)}',
    );
  }

  /// JSON 美化（两空格缩进）；不可序列化时回退 toString。
  static String _prettyJson(Object? data) {
    try {
      return const JsonEncoder.withIndent('  ').convert(data);
    } catch (_) {
      return data.toString();
    }
  }

  /// DioException → ApiException：优先取响应体内的业务 code/msg。
  ApiException _mapDioError(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      final code =
          (data['code'] as num?)?.toInt() ?? e.response!.statusCode ?? -1;
      final msg = data['msg'] as String? ?? '请求失败';
      return ApiException(code: code, msg: msg);
    }
    final status = e.response?.statusCode;
    return ApiException(
      code: status ?? -1,
      msg: status == 401 ? '登录已过期，请重新登录' : '网络异常，请稍后重试',
    );
  }

  void _notifySessionExpired() {
    onSessionExpired?.call();
  }

  /// 鉴权拦截器：requireAuth=true 时从 authTokenProvider 读 token 注入
  /// `Authorization: Bearer`；白名单路径跳过。
  Interceptor _authInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        final requireAuth = options.extra['requireAuth'] != false;
        final token = _ref.read(authTokenProvider);
        if (requireAuth &&
            token != null &&
            token.isNotEmpty &&
            !_isAuthFree(options.path)) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    );
  }

  /// 服务器时间校准 + HTTP 401 处理。
  Interceptor _serverTimeInterceptor() {
    return InterceptorsWrapper(
      onResponse: (response, handler) {
        _updateServerTime(response.headers);
        handler.next(response);
      },
      onError: (error, handler) {
        final response = error.response;
        if (response != null) {
          _updateServerTime(response.headers);
          // HTTP 401 → 统一登出（契约 §0）
          if (response.statusCode == 401) _notifySessionExpired();
        }
        handler.next(error);
      },
    );
  }

  /// 解析响应头 Date，维护 serverTimeOffset（参照 iOS XYServerTimeMonitor）。
  void _updateServerTime(Headers headers) {
    final date = headers.value('date');
    if (date == null || date.isEmpty) return;
    try {
      final serverTime = HttpDate.parse(date);
      _serverTimeOffset = serverTime.difference(DateTime.now());
    } catch (_) {
      // 非法 Date 头忽略，保持上次校准值
    }
  }

  /// DEBUG 日志：对齐 iOS XYNetworkEventMonitor——
  /// 请求发出时先打 URL / 请求头 / 参数，响应后再打状态码与原始 JSON；
  /// release 不注册。
  Interceptor _logInterceptor() {
    int? costOf(RequestOptions options) {
      final start = options.extra['_reqStartMs'] as int?;
      if (start == null) return null;
      return DateTime.now().millisecondsSinceEpoch - start;
    }

    return InterceptorsWrapper(
      onRequest: (options, handler) {
        options.extra['_reqStartMs'] = DateTime.now().millisecondsSinceEpoch;
        // 鉴权拦截器在本拦截器之前，此处 headers 已含 Authorization（若有）
        debugPrint(
          '\n🌐 [网络请求] ${options.method} ${options.uri}\n'
          '请求头: ${_prettyJson(Map<String, dynamic>.from(options.headers))}\n'
          '请求参数: ${_prettyJson(options.data)}',
        );
        handler.next(options);
      },
      onResponse: (response, handler) {
        final req = response.requestOptions;
        final cost = costOf(req);
        debugPrint(
          '\n✅ [请求成功] ${req.method} ${req.uri}\n'
          'HTTP状态码: ${response.statusCode}\n'
          '耗时: ${cost ?? -1}ms\n'
          '原始JSON: ${_prettyJson(response.data)}',
        );
        handler.next(response);
      },
      onError: (error, handler) {
        final req = error.requestOptions;
        final cost = costOf(req);
        final status = error.response?.statusCode;
        final body = error.response?.data;
        debugPrint(
          '\n❌ [请求失败] ${req.method} ${req.uri}\n'
          'HTTP状态码: ${status ?? '无响应'}\n'
          '耗时: ${cost ?? -1}ms\n'
          '失败原因: ${error.message}\n'
          '原始数据: ${body == null ? '' : _prettyJson(body)}',
        );
        handler.next(error);
      },
    );
  }
}