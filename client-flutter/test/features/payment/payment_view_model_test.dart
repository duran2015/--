import 'package:flutter_test/flutter_test.dart';

import 'package:xinyu_flutter/features/payment/payment_api.dart';
import 'package:xinyu_flutter/features/payment/payment_view_model.dart';

/// 支付 ViewModel 单元测试（支付宝/微信双通道）。
///
/// 通过注入 Fake 网关与收银台唤起函数，验证 [PaymentViewModel.pay] 的
/// 通道分流、参数缺失失败关闭、唤起结果判定、confirm 验真兜底行为。
void main() {
  const outTradeNo = 'XY_TEST_001';

  /// 构造标准的微信调起参数
  WxPayParams wxParams() => const WxPayParams(
        appId: 'wx_test_appid',
        partnerId: '1900000109',
        prepayId: 'wx_prepay_001',
        packageValue: 'Sign=WXPay',
        nonceStr: 'nonce',
        timestamp: '1750000000',
        sign: 'signature',
      );

  /// 构造支付参数（默认含金额与截止时间）
  PaymentPageArgs args({String orderId = '10001'}) => PaymentPageArgs(
        orderId: orderId,
        amount: 100,
        priceText: '100',
        paymentDeadline: '2026-08-05 23:59:59',
      );

  group('支付方式切换', () {
    test('默认支付宝，切换微信后 payType 同步变化', () {
      final vm = PaymentViewModel(
        args: args(),
        gateway: _FakeGateway(orderInfo: 'alipay-order-info'),
      );
      expect(vm.selectedMethod, PaymentMethod.alipay);
      expect(vm.payType, 'alipay');
      vm.selectMethod(PaymentMethod.wechat);
      expect(vm.payType, 'wechat');
    });
  });

  group('pay 前置校验', () {
    test('订单号缺失 → 抛「订单号缺失」且不发起下单', () async {
      final gateway = _FakeGateway(orderInfo: 'alipay-order-info');
      final vm = PaymentViewModel(
        args: args(orderId: ''),
        gateway: gateway,
      );
      await expectLater(
        vm.pay(),
        throwsA(isA<PaymentFlowException>()
            .having((e) => e.message, 'message', '订单号缺失')),
      );
      expect(gateway.createCalls, 0);
    });
  });

  group('微信支付分支', () {
    test('wxPayParams 缺失（微信未配置）→ 走 mock 返回 outTradeNo，不唤起收银台', () async {
      final gateway = _FakeGateway(orderInfo: null, wxPayParams: null);
      var launched = false;
      final vm = PaymentViewModel(
        args: args(),
        gateway: gateway,
        wechatLauncher: (params) async {
          launched = true;
          return true;
        },
      );
      vm.selectMethod(PaymentMethod.wechat);
      final result = await vm.pay();
      expect(result, outTradeNo);
      expect(launched, isFalse);
      expect(gateway.mockCalls, 1);
      expect(gateway.confirmCalls, 0);
    });

    test('唤起取消/失败 → 抛「支付未完成」，不发起 confirm', () async {
      final gateway = _FakeGateway(orderInfo: null, wxPayParams: wxParams());
      WxPayParams? received;
      final vm = PaymentViewModel(
        args: args(),
        gateway: gateway,
        wechatLauncher: (params) async {
          received = params;
          return false;
        },
      );
      vm.selectMethod(PaymentMethod.wechat);
      await expectLater(
        vm.pay(),
        throwsA(isA<PaymentFlowException>()
            .having((e) => e.message, 'message', '支付未完成')),
      );
      expect(received, isNotNull);
      expect(received!.prepayId, 'wx_prepay_001');
      expect(gateway.confirmCalls, 0);
    });

    test('唤起成功且 confirm 验真通过 → 返回 outTradeNo', () async {
      final gateway = _FakeGateway(orderInfo: null, wxPayParams: wxParams());
      final vm = PaymentViewModel(
        args: args(),
        gateway: gateway,
        wechatLauncher: (params) async => true,
      );
      vm.selectMethod(PaymentMethod.wechat);
      final result = await vm.pay();
      expect(result, outTradeNo);
      expect(gateway.createdPayType, 'wechat');
      expect(gateway.confirmCalls, 1);
      expect(gateway.confirmedOutTradeNo, outTradeNo);
    });

    test('唤起成功但 confirm 验真失败 → 短时重试后仍失败，抛「支付结果确认中」', () async {
      final gateway = _FakeGateway(
        orderInfo: null,
        wxPayParams: wxParams(),
        confirmError: Exception('微信交易未成功'),
      );
      final vm = PaymentViewModel(
        args: args(),
        gateway: gateway,
        wechatLauncher: (params) async => true,
        confirmRetries: 1,
        confirmRetryDelay: Duration.zero,
      );
      vm.selectMethod(PaymentMethod.wechat);
      await expectLater(
        vm.pay(),
        throwsA(isA<PaymentFlowException>()
            .having((e) => e.message, 'message', '支付结果确认中，请稍后在订单列表查看')),
      );
      expect(gateway.confirmCalls, 1);
    });

    test('confirm 首次失败第二次成功 → 重试后返回 outTradeNo', () async {
      final gateway = _FakeGateway(
        orderInfo: null,
        wxPayParams: wxParams(),
        confirmFailures: 1,
      );
      final vm = PaymentViewModel(
        args: args(),
        gateway: gateway,
        wechatLauncher: (params) async => true,
        confirmRetries: 2,
        confirmRetryDelay: Duration.zero,
      );
      vm.selectMethod(PaymentMethod.wechat);
      final result = await vm.pay();
      expect(result, outTradeNo);
      expect(gateway.confirmCalls, 2);
    });
  });

  group('支付宝分支（回归）', () {
    test('orderInfo 缺失（支付宝未配置）→ 走 mock 返回 outTradeNo，不唤起收银台', () async {
      final gateway = _FakeGateway(orderInfo: null, wxPayParams: null);
      var launched = false;
      final vm = PaymentViewModel(
        args: args(),
        gateway: gateway,
        alipayLauncher: (orderInfo) async {
          launched = true;
          return AlipayPayResult.success;
        },
      );
      final result = await vm.pay();
      expect(result, outTradeNo);
      expect(launched, isFalse);
      expect(gateway.mockCalls, 1);
      expect(gateway.confirmCalls, 0);
    });

    test('唤起取消/失败 → 抛「支付未完成」，不发起 confirm', () async {
      final gateway = _FakeGateway(orderInfo: 'alipay-order-info');
      final vm = PaymentViewModel(
        args: args(),
        gateway: gateway,
        alipayLauncher: (orderInfo) async => AlipayPayResult.cancelled,
      );
      await expectLater(
        vm.pay(),
        throwsA(isA<PaymentFlowException>()
            .having((e) => e.message, 'message', '支付未完成')),
      );
      expect(gateway.confirmCalls, 0);
    });

    test('唤起成功且 confirm 验真通过 → 返回 outTradeNo', () async {
      final gateway = _FakeGateway(orderInfo: 'alipay-order-info');
      String? receivedOrderInfo;
      final vm = PaymentViewModel(
        args: args(),
        gateway: gateway,
        alipayLauncher: (orderInfo) async {
          receivedOrderInfo = orderInfo;
          return AlipayPayResult.success;
        },
      );
      final result = await vm.pay();
      expect(result, outTradeNo);
      expect(receivedOrderInfo, 'alipay-order-info');
      expect(gateway.createdPayType, 'alipay');
      expect(gateway.confirmCalls, 1);
    });

    test('唤起返回「结果确认中/未知」→ 走 confirm 查单验真，通过后返回 outTradeNo', () async {
      final gateway = _FakeGateway(orderInfo: 'alipay-order-info');
      final vm = PaymentViewModel(
        args: args(),
        gateway: gateway,
        alipayLauncher: (orderInfo) async => AlipayPayResult.unknown,
      );
      final result = await vm.pay();
      expect(result, outTradeNo);
      expect(gateway.confirmCalls, 1);
    });

    test('唤起返回「结果确认中/未知」且 confirm 重试仍失败 → 抛「确认中」，不判定未完成', () async {
      final gateway = _FakeGateway(
        orderInfo: 'alipay-order-info',
        confirmError: Exception('渠道暂不可用'),
      );
      final vm = PaymentViewModel(
        args: args(),
        gateway: gateway,
        alipayLauncher: (orderInfo) async => AlipayPayResult.unknown,
        confirmRetries: 2,
        confirmRetryDelay: Duration.zero,
      );
      await expectLater(
        vm.pay(),
        throwsA(isA<PaymentFlowException>().having(
          (e) => e.isConfirming,
          'isConfirming',
          isTrue,
        )),
      );
      expect(gateway.confirmCalls, 2);
    });
  });
}

/// 测试用支付网关：可配置 orderInfo / wxPayParams / confirm 异常，
/// 记录调用次数与传参。
class _FakeGateway implements PaymentGateway {
  _FakeGateway({
    this.orderInfo,
    this.wxPayParams,
    this.confirmError,
    this.confirmFailures = 0,
  });

  /// 支付宝 orderInfo（null 模拟支付宝未配置）
  final String? orderInfo;

  /// 微信调起参数（null 模拟微信未配置）
  final WxPayParams? wxPayParams;

  /// confirm 阶段注入的异常（null 表示验真通过）
  final Object? confirmError;

  /// confirm 前 N 次失败（之后成功），模拟渠道状态短暂未同步后恢复
  final int confirmFailures;

  /// createPayment 被调用次数
  int createCalls = 0;

  /// 最近一次 createPayment 的 payType
  String? createdPayType;

  /// confirmPayment 被调用次数
  int confirmCalls = 0;

  /// 最近一次 confirmPayment 的 outTradeNo
  String? confirmedOutTradeNo;

  /// mockPaymentSuccess 被调用次数
  int mockCalls = 0;

  @override
  Future<PayCreateResult> createPayment({
    required String orderId,
    required String payType,
  }) async {
    createCalls++;
    createdPayType = payType;
    return PayCreateResult(
      outTradeNo: 'XY_TEST_001',
      orderInfo: orderInfo,
      wxPayParams: wxPayParams,
    );
  }

  @override
  Future<void> mockPaymentSuccess(String outTradeNo) async {
    mockCalls++;
  }

  @override
  Future<void> confirmPayment({
    required String outTradeNo,
    String? transactionId,
  }) async {
    confirmCalls++;
    confirmedOutTradeNo = outTradeNo;
    if (confirmError != null) {
      throw confirmError!;
    }
    if (confirmCalls <= confirmFailures) {
      throw Exception('验真未通过');
    }
  }
}
