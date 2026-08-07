import 'dart:convert';

import 'package:flutter/foundation.dart';

/// JS 桥 action 处理器：收 data 字典，返回回包结果（可空）。
/// iOS 参照：XYJSBridge.ActionHandler（data, reply）。
typedef XyBridgeActionHandler = Future<Object?> Function(
  Map<String, dynamic>? data,
);

/// 轻量 JS 桥：H5 ↔ 原生双向通信。
/// iOS 参照：XYCoreModule/XYCoreModule/Classes/Web/XYJSBridge.swift。
/// Android 对照：webview/WebViewBridge.kt。
///
/// 协议对齐结论（H5 零改动）：
/// - H5 侧 API 与 iOS 完全一致：`window.XYJSBridge.call(action, data)` 返回
///   Promise、`window.XYJSBridge.on(event, cb)` 监听事件；登录态经
///   `window.XY_APP` 同步读取。
/// - H5 → Native 消息体与 iOS 逐字段一致：
///   `{action, data, callbackId}`，经 `window.webkit.messageHandlers.app`
///   .postMessage 发出（iOS 原生即此通道；Android 由
///   webview_flutter JavaScriptChannel('app') 提供 `window.app.postMessage`，
///   经 [transportShimScript] 垫片适配为同名通道，helper 脚本因此可与 iOS
///   逐字节一致）。
/// - Native → H5 回包/事件与 iOS 逐字节一致：
///   `XYJSBridge.dispatchCallback('<callbackId>', {"result":...})` /
///   `XYJSBridge.dispatchEvent('<event>', {"data":...})`。
/// - 未注册 action 默认行为与 iOS 一致：有 callbackId 时回包
///   `{"error":"unregistered action: <action>"}`，避免 H5 Promise 永久挂起。
class XyJsBridge {
  XyJsBridge({required this.jsExecutor});

  /// 消息处理器名（iOS XYJSBridge.messageHandlerName = "app"；
  /// Flutter 侧对应 addJavaScriptChannel('app')）。
  static const String messageHandlerName = 'app';

  /// 在 H5 页面执行 JS（原生 → H5），由宿主 WebView 注入（runJavaScript）。
  final void Function(String javaScript) jsExecutor;

  /// 已注册的 action 处理器表（可扩展，新增 action 只需 register）。
  final Map<String, XyBridgeActionHandler> _actionHandlers = {};

  /// 注册一个 action 处理器（同名覆盖）。
  /// iOS 参照：XYJSBridge.register(_:handler:)。
  void register(String action, XyBridgeActionHandler handler) {
    _actionHandlers[action] = handler;
  }

  // MARK: - H5 → 原生

  /// H5 消息入口：JavaScriptChannel('app') 回调的 JSON 字符串。
  /// iOS 参照：XYJSBridge.userContentController(_:didReceive:)。
  Future<void> handleMessage(String message) async {
    final Map<String, dynamic> body;
    try {
      final decoded = jsonDecode(message);
      if (decoded is! Map) return;
      body = Map<String, dynamic>.from(decoded);
    } catch (_) {
      return;
    }
    final action = body['action'];
    if (action is! String) return;
    final rawData = body['data'];
    final data =
        rawData is Map ? Map<String, dynamic>.from(rawData) : null;
    final callbackId = body['callbackId'] as String?;
    debugPrint('🌐 [Bridge] recv action=$action data=$data cb=$callbackId');

    final handler = _actionHandlers[action];
    if (handler == null) {
      // 未注册的 action：若有 callbackId 回个错误，避免 H5 侧 Promise 永久挂起
      if (callbackId != null) {
        reply(callbackId, <String, String>{
          'error': 'unregistered action: $action',
        });
      }
      return;
    }
    final result = await handler(data);
    if (callbackId != null) reply(callbackId, result);
  }

  // MARK: - 原生 → H5

  /// 主动向 H5 推送事件。
  /// iOS 参照：XYJSBridge.emit(_:data:)。
  void emit(String event, [Object? data]) {
    final payload = jsonEncode(<String, Object?>{'data': data});
    jsExecutor(
      'window.XYJSBridge && window.XYJSBridge.dispatchEvent && '
      "XYJSBridge.dispatchEvent('${escapeJs(event)}', $payload);",
    );
  }

  /// 回调某次 H5 调用（按 callbackId 回包）。
  /// iOS 参照：XYJSBridge.reply(callbackId:result:)。
  void reply(String callbackId, Object? result) {
    final payload = jsonEncode(<String, Object?>{'result': result});
    jsExecutor(
      'window.XYJSBridge && window.XYJSBridge.dispatchCallback && '
      "XYJSBridge.dispatchCallback('${escapeJs(callbackId)}', $payload);",
    );
  }

  // MARK: - 注入脚本

  /// 生成 `window.XY_APP` 注入脚本。
  /// iOS 参照：XYJSBridge.bootstrapScript(for:)（documentStart 注入与
  /// didFinish 补同步共用）。
  static String bootstrapScript(Map<String, dynamic> data) =>
      'window.XY_APP = ${jsonEncode(data)};';

  /// 转义 JS 字符串字面量中的危险字符（防注入）。
  /// iOS 参照：XYJSBridge.escape(_:)。
  static String escapeJs(String string) => string
      .replaceAll('\\', '\\\\')
      .replaceAll("'", "\\'")
      .replaceAll('\n', '\\n');

  /// Android 传输层垫片：把 webview_flutter JavaScriptChannel('app') 提供的
  /// `window.app.postMessage(String)` 适配为 iOS 形态的
  /// `window.webkit.messageHandlers.app.postMessage(Object)`。
  ///
  /// iOS 关键修复：webview_flutter_wkwebview 的原生通道收到**对象**时会
  /// 序列化为 NSDictionary 描述串（`{action = xxx;}`，非 JSON），Dart 侧
  /// jsonDecode 静默失败、消息全部丢失。此处包装原生 postMessage，
  /// 统一 JSON.stringify 成字符串再投递（与 Android 垫片输出对齐），
  /// 保证 helper 脚本与 iOS 原生 XYJSBridge.bridgeHelperScript 逐字节一致。
  static const String transportShimScript = '''
(function () {
  if (!window.webkit) window.webkit = {};
  if (!window.webkit.messageHandlers) window.webkit.messageHandlers = {};
  var mh = window.webkit.messageHandlers.app;
  if (!mh && window.app && window.app.postMessage) {
    // Android：适配为 iOS 形态的通道（对象 → JSON 字符串）。
    // __xyStringifyWrapped 标记必填：_injectScripts 在 onPageStarted 与
    // onPageFinished 各注入一次（window.app 先于 loadRequest 注册，故首次
    // 注入即可命中本分支）。无此标记时第二次注入会进入下方 else-if 再包一层，
    // 导致 JSON.stringify 执行两次，Dart 侧 jsonDecode 得字符串（非 Map）被
    // handleMessage 静默丢弃 —— H5→原生消息全丢（intake 提交后「提交中」不消失）。
    window.webkit.messageHandlers.app = {
      postMessage: function (msg) { window.app.postMessage(JSON.stringify(msg)); },
      __xyStringifyWrapped: true
    };
  } else if (mh && !mh.__xyStringifyWrapped) {
    // iOS：包装原生通道，对象先转 JSON 字符串再投递（幂等）
    try {
      var orig = mh.postMessage;
      mh.postMessage = function (msg) { orig.call(mh, JSON.stringify(msg)); };
      mh.__xyStringifyWrapped = true;
    } catch (e) {}
  }
})();
''';

  /// XYJSBridge helper 脚本（H5 侧 API：call / on / dispatchCallback /
  /// dispatchEvent）。与 iOS XYJSBridge.bridgeHelperScript 逐字节一致。
  static const String bridgeHelperScript = '''
(function () {
  if (window.XYJSBridge) return;
  var seq = 0, callbacks = {}, listeners = {};
  window.XYJSBridge = {
    // H5 → 原生：返回 Promise
    call: function (action, data) {
      return new Promise(function (resolve, reject) {
        var id = 'cb_' + (++seq) + '_' + Date.now();
        callbacks[id] = { resolve: resolve, reject: reject };
        try {
          window.webkit.messageHandlers.app.postMessage({ action: action, data: data || {}, callbackId: id });
        } catch (e) { delete callbacks[id]; reject(e); }
      });
    },
    // H5 监听原生事件
    on: function (event, cb) {
      (listeners[event] = listeners[event] || []).push(cb);
    },
    // 原生 → H5：回包
    dispatchCallback: function (id, payload) {
      var entry = callbacks[id];
      if (!entry) return;
      delete callbacks[id];
      entry.resolve(payload && payload.result);
    },
    // 原生 → H5：推事件
    dispatchEvent: function (event, payload) {
      var arr = listeners[event] || [];
      var data = payload && payload.data;
      for (var i = 0; i < arr.length; i++) { try { arr[i](data); } catch (e) {} }
    }
  };
})();
''';
}
