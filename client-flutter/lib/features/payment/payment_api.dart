import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';

final paymentApiProvider =
    Provider<PaymentGateway>((ref) => PaymentApi(ref.read(apiClientProvider)));

/// 支付接口封装（契约 §4 #20-21）。
/// iOS 参照：XYPaymentViewModel.pay / mockSuccess。
///
/// 抽象为 [PaymentGateway] 便于测试注入假实现。
abstract class PaymentGateway {
  /// #20 创建支付：orderId / payType("wechat"/"alipay")。
  /// 金额由服务端按订单价格为准（不信任客户端金额），返回商户订单号 + 支付宝 orderInfo。
  Future<PayCreateResult> createPayment({
    required String orderId,
    required String payType,
  });

  /// #21 模拟支付成功回调（兜底：支付宝未配置/非支付宝方式时保持原生 mock 行为）。
  Future<void> mockPaymentSuccess(String outTradeNo);

  /// #22 同步确认支付成功（本地联调：支付宝客户端 resultStatus=9000 后调用，
  /// 弥补异步通知内网不可达；生产环境仍以支付宝异步通知为准）。
  Future<void> confirmPayment({
    required String outTradeNo,
    String? transactionId,
  });
}

/// 统一下单结果（对应后端 PayCreateVO：outTradeNo + orderInfo + wxPayParams）。
class PayCreateResult {
  const PayCreateResult({
    required this.outTradeNo,
    this.orderInfo,
    this.wxPayParams,
  });

  /// 商户订单号
  final String outTradeNo;

  /// 支付宝 orderInfo（已签名支付参数串；支付宝未配置时为 null）
  final String? orderInfo;

  /// 微信 App 支付调起参数（已签名；微信未配置时为 null）
  final WxPayParams? wxPayParams;
}

/// 微信 App 支付调起参数（对应后端 WxPayParamsVO，package 序列化为 "package"）。
/// 字段含义与微信官方「APP 调起支付」参数一一对应，客户端直接用于唤起微信收银台。
class WxPayParams {
  const WxPayParams({
    required this.appId,
    required this.partnerId,
    required this.prepayId,
    required this.packageValue,
    required this.nonceStr,
    required this.timestamp,
    required this.sign,
  });

  /// 应用 ID（openapi 下的 appid）
  final String appId;

  /// 商户号
  final String partnerId;

  /// 预支付交易会话标识
  final String prepayId;

  /// 扩展字段（固定值 Sign=WXPay）
  final String packageValue;

  /// 随机字符串
  final String nonceStr;

  /// 时间戳（秒）
  final String timestamp;

  /// 签名
  final String sign;
}

/// 真实网络实现。
class PaymentApi implements PaymentGateway {
  PaymentApi(this._client);

  final ApiClient _client;

  /// #20 创建支付
  static const createPath = '/app/pay/create';

  /// #21 模拟支付成功
  static const mockSuccessPath = '/app/pay/mock-success';

  /// #22 同步确认支付成功（服务端调用支付宝交易查询接口验真后落库）
  static const confirmPath = '/app/pay/confirm';

  @override
  Future<PayCreateResult> createPayment({
    required String orderId,
    required String payType,
  }) async {
    // iOS 参照：XYPaymentViewModel.pay createBody（orderId 为 Int；
    // 兼容 mock 字符串 id，可转 Int 时按数字上传）
    final data = await _client.postData<Map<String, dynamic>>(
      createPath,
      {
        'orderId': int.tryParse(orderId) ?? orderId,
        'payType': payType,
      },
      decoder: (json) => Map<String, dynamic>.from(json as Map),
    );
    final tradeNo = data?['outTradeNo']?.toString() ?? '';
    if (tradeNo.isEmpty) {
      throw const ApiException(code: -1, msg: '未获取到支付订单号');
    }
    return PayCreateResult(
      outTradeNo: tradeNo,
      orderInfo: data?['orderInfo']?.toString(),
      wxPayParams: _parseWxPayParams(data?['wxPayParams']),
    );
  }

  /// 解析后端 wxPayParams（JSON 对象 → 强类型；缺失/非法返回 null）。
  WxPayParams? _parseWxPayParams(Object? raw) {
    if (raw is! Map) return null;
    final appId = raw['appId']?.toString();
    final partnerId = raw['partnerId']?.toString();
    final prepayId = raw['prepayId']?.toString();
    final packageValue = raw['package']?.toString();
    final nonceStr = raw['nonceStr']?.toString();
    final timestamp = raw['timestamp']?.toString();
    final sign = raw['sign']?.toString();
    if (appId == null ||
        partnerId == null ||
        prepayId == null ||
        packageValue == null ||
        nonceStr == null ||
        timestamp == null ||
        sign == null) {
      return null;
    }
    return WxPayParams(
      appId: appId,
      partnerId: partnerId,
      prepayId: prepayId,
      packageValue: packageValue,
      nonceStr: nonceStr,
      timestamp: timestamp,
      sign: sign,
    );
  }

  @override
  Future<void> mockPaymentSuccess(String outTradeNo) async {
    await _client
        .postData<dynamic>(mockSuccessPath, {'outTradeNo': outTradeNo});
  }

  @override
  Future<void> confirmPayment({
    required String outTradeNo,
    String? transactionId,
  }) async {
    await _client.postData<dynamic>(
      confirmPath,
      {'outTradeNo': outTradeNo, 'transactionId': transactionId},
    );
  }
}
