import 'dart:async';

import 'package:fluwx/fluwx.dart';
import 'package:tobias/tobias.dart';

import '../../core/utils/deadline_countdown.dart';
import '../consultant/consultant_models.dart';
import '../order/order_models.dart';
import 'payment_api.dart';

/// 支付方式（iOS XYPaymentViewModel.PaymentMethod；默认支付宝，与 Figma 0:979 一致）。
enum PaymentMethod { wechat, alipay }

/// 支付宝收银台返回结果分类（依据支付宝 SDK resultStatus 语义）。
enum AlipayPayResult {
  /// 支付成功（9000）：继续走服务端 confirm 验真落库
  success,

  /// 用户明确取消或系统明确失败（6001/4000/6002/5000 等）：不发起 confirm
  cancelled,

  /// 支付结果确认中/未知（8000/6004 等）：用户可能已扣款，
  /// 必须走服务端 confirm 查单验真，禁止直接判定「支付未完成」引导重复支付
  unknown,
}

/// 唤起支付宝收银台的函数签名（注入便于单测；生产默认走 tobias）。
typedef AlipayPayLauncher = Future<AlipayPayResult> Function(String orderInfo);

/// 唤起微信收银台的函数签名（注入便于单测；生产默认走 fluwx）。
/// 返回 true 表示用户已完成支付（微信侧回调成功），false 表示取消/失败/超时。
typedef WechatPayLauncher = Future<bool> Function(WxPayParams params);

/// 支付宝收银台环境开关：true=沙箱（联调用），false=正式（上线前改为 false）。
/// iOS 参照：XYPaymentConfig.alipaySandboxEnabled。
const bool alipaySandboxEnabled = false;

/// iOS 支付宝回调 Universal Link（在支付宝开放平台「App 支付」-「开发设置」中配置，
/// 需提供可访问的 apple-app-site-association，形如 https://api.currantmind.cn/）。
///
/// 当前 iOS 支付跳回**明确只使用 URL Scheme**（Info.plist 中 CFBundleURLName="alipay"、
/// scheme xinyualipay），不依赖 Universal Link，因此此处保持为空即可正常支付。
/// pubspec.yaml 中 tobias.ios.universal_link 仅为避免 tobias 写入无主机名
/// "applinks:" 的技术占位，与真实回调无关。
/// 若未来需要 App 被外部链接唤起的 Universal Link 回调，须先开通 App 关联域名并
/// 配置 AASA 文件，再在 pubspec 与支付宝开放平台替换为同一真实域名，并在此填写传参。
const String alipayUniversalLink = '';

/// 生产默认实现：tobias 唤起支付宝，resultStatus=9000 视为支付成功。
/// 不做固定短超时判定：耐心等待收银台返回（用户完成支付回到 App 后 SDK 即返回），
/// 最终支付结果以服务端支付宝交易查询验真为准（见 [PaymentViewModel.pay]）。
/// 区分「成功 / 明确取消失败 / 确认中或结果未知」三种结果：
/// 8000（结果确认中）与 6004（结果未知）用户可能已扣款，必须交由服务端 confirm 查单兜底。
Future<AlipayPayResult> alipayPayWithTobias(String orderInfo) async {
  final result = await Tobias().pay(
    orderInfo,
    evn: alipaySandboxEnabled ? AliPayEvn.sandbox : AliPayEvn.online,
    universalLink: alipayUniversalLink.isEmpty ? null : alipayUniversalLink,
  );
  final status = result['resultStatus'];
  if (status == '9000') {
    return AlipayPayResult.success;
  }
  if (status == '8000' || status == '6004') {
    // 8000=支付结果确认中（服务端异步通知可能已成功）；6004=支付结果未知（可能已扣款）
    return AlipayPayResult.unknown;
  }
  // 6001 用户取消、4000 系统异常、6002 网络连接出错、5000 重复请求等 → 明确未完成
  return AlipayPayResult.cancelled;
}

/// 微信收银台等待超时（用户长时间未返回 App，视为支付未完成）。
/// 生产最终以服务端微信查单验真为准（见 [PaymentViewModel.pay]）。
const Duration wechatPayTimeout = Duration(minutes: 2);

/// confirm 验真短时重试次数：支付渠道状态短暂未同步、网络超时或后端临时错误时，
/// 立即报「支付未完成」会误导用户重复支付；先短时重试，仍失败视为「确认中」。
const int confirmRetryCount = 3;

/// confirm 重试间隔（每次固定短间隔；3 次总耗时约 2 秒，对用户体验可接受）。
const Duration confirmRetryDelayConst = Duration(seconds: 1);

/// 生产默认实现：fluwx 唤起微信收银台。
/// fluwx 的 pay() 只代表"已成功调起微信"，支付完成/取消通过
/// [WeChatPaymentResponse] 订阅回调（errCode=0 成功 / -2 用户取消）：
/// 因此先订阅响应再发起支付，收到回调即判定结果；超时兜底返回 false。
Future<bool> wechatPayWithFluwx(WxPayParams params) async {
  final timestamp = int.tryParse(params.timestamp);
  if (timestamp == null) return false;
  // 支付为一次性操作，用局部 Fluwx 实例订阅本次响应，结束即取消
  final fluwxInstance = Fluwx();
  // 冷启动后必须重新注册微信 SDK（fluwx registerApi 幂等），
  // 否则 fluwx 未持有有效的 WXApi 实例，pay() 会唤起失败/收不到回调
  try {
    await fluwxInstance.registerApi(
      appId: params.appId,
      universalLink: 'https://api.currantmind.cn/',
    );
  } catch (_) {
    // 注册异常不阻塞：若 registerApi 失败，下方 pay() 会返回失败并走异常分支
  }
  final completer = Completer<bool>();
  final subscription = fluwxInstance.addSubscriber((response) {
    if (response is! WeChatPaymentResponse) return;
    if (response.errCode == 0) {
      completer.complete(true);
    } else {
      completer.complete(false);
    }
  });
  bool sent;
  try {
    sent = await fluwxInstance.pay(
      which: Payment(
        appId: params.appId,
        partnerId: params.partnerId,
        prepayId: params.prepayId,
        packageValue: params.packageValue,
        nonceStr: params.nonceStr,
        timestamp: timestamp,
        sign: params.sign,
      ),
    );
  } catch (_) {
    sent = false;
  }
  if (!sent) {
    subscription.cancel();
    return false;
  }
  try {
    return await completer.future.timeout(
      wechatPayTimeout,
      onTimeout: () => false,
    );
  } finally {
    subscription.cancel();
  }
}

/// 支付页展示/支付参数（对应 iOS XYPaymentViewModel 的展示字段）。
///
/// 两个入口：
/// - [PaymentPageArgs.fromOrder]：订单列表/详情页「去支付」，字段齐全；
/// - [PaymentPageArgs.fromQuery]：/payment 路由 query（预约下单后仅有 orderId 时，
///   页面会回查 my-list 补齐，见 PaymentPage）。
class PaymentPageArgs {
  const PaymentPageArgs({
    required this.orderId,
    this.amount,
    this.priceText = '',
    this.counselorName = '',
    this.counselorTitle = '',
    this.counselorAvatar,
    this.counselorIMUserID = '',
    this.method = '',
    this.time = '',
    this.duration = '',
    this.serviceHoursText = '',
    this.specialtyTags = const [],
    this.styleTags = const [],
    this.paymentDeadline,
  });

  /// 订单 ID（创建支付用）
  final String orderId;

  /// 支付金额数值（元，创建支付用）
  final double? amount;

  /// 支付金额展示文案（不含 ¥ 前缀，如 "299"）
  final String priceText;

  /// 咨询师姓名 / 职称 / 头像 / IM 用户 ID
  final String counselorName;
  final String counselorTitle;
  final String? counselorAvatar;
  final String counselorIMUserID;

  /// 咨询方式文案
  final String method;

  /// 预约时间展示文案
  final String time;

  /// 咨询时长展示文案
  final String duration;

  /// 累计服务时长文案（空则隐藏胶囊）
  final String serviceHoursText;

  /// 擅长领域 / 咨询风格标签
  final List<String> specialtyTags;
  final List<String> styleTags;

  /// 支付截止时间（yyyy-MM-dd HH:mm:ss；倒计时权威来源）
  final String? paymentDeadline;

  /// 订单展示模型 → 支付参数。
  /// iOS 参照：XYAppointmentOrderActionRouter.pushPayment。
  factory PaymentPageArgs.fromOrder(AppointmentOrderItem item) {
    return PaymentPageArgs(
      orderId: item.orderId ?? '',
      amount: item.price,
      priceText: formatPrice(item.price ?? 0),
      counselorName: item.counselorName,
      counselorTitle: item.counselorTitle ?? '',
      counselorAvatar: item.counselorAvatar,
      counselorIMUserID: item.counselorIMUserID,
      method: item.supportModeText,
      time: item.appointmentTimeRangeDisplay.isNotEmpty
          ? item.appointmentTimeRangeDisplay
          : item.appointmentTimeDisplay,
      duration: item.durationDisplay,
      serviceHoursText: item.serviceHoursText,
      specialtyTags: item.specialtyTags,
      styleTags: item.styleTags,
      paymentDeadline: item.paymentDeadline,
    );
  }

  /// 路由 query → 支付参数（tags 以逗号分隔传输）。
  factory PaymentPageArgs.fromQuery(Map<String, String> q) {
    List<String> splitTags(String? raw) {
      if (raw == null || raw.isEmpty) return const [];
      return raw.split(',').where((e) => e.isNotEmpty).toList();
    }

    return PaymentPageArgs(
      orderId: q['orderId'] ?? '',
      amount: double.tryParse(q['amount'] ?? ''),
      priceText: q['price'] ?? '',
      counselorName: q['name'] ?? '',
      counselorTitle: q['title'] ?? '',
      counselorAvatar: q['avatar'],
      counselorIMUserID: q['imUserId'] ?? '',
      method: q['method'] ?? '',
      time: q['time'] ?? '',
      duration: q['duration'] ?? '',
      serviceHoursText: q['serviceHours'] ?? '',
      specialtyTags: splitTags(q['specialty']),
      styleTags: splitTags(q['style']),
      paymentDeadline: q['deadline'],
    );
  }

  /// 序列化为路由 query（订单列表/详情「去支付」用）。
  Map<String, String> toQuery() {
    return {
      'orderId': orderId,
      if (amount != null) 'amount': '$amount',
      if (priceText.isNotEmpty) 'price': priceText,
      if (counselorName.isNotEmpty) 'name': counselorName,
      if (counselorTitle.isNotEmpty) 'title': counselorTitle,
      if (counselorAvatar != null && counselorAvatar!.isNotEmpty)
        'avatar': counselorAvatar!,
      if (counselorIMUserID.isNotEmpty) 'imUserId': counselorIMUserID,
      if (method.isNotEmpty) 'method': method,
      if (time.isNotEmpty) 'time': time,
      if (duration.isNotEmpty) 'duration': duration,
      if (serviceHoursText.isNotEmpty) 'serviceHours': serviceHoursText,
      if (specialtyTags.isNotEmpty) 'specialty': specialtyTags.join(','),
      if (styleTags.isNotEmpty) 'style': styleTags.join(','),
      if (paymentDeadline != null && paymentDeadline!.isNotEmpty)
        'deadline': paymentDeadline!,
    };
  }

  /// 是否需要回查订单补齐展示字段（预约下单入口仅有 orderId 的场景）。
  bool get needsOrderLookup => counselorName.isEmpty;
}

/// 支付页 ViewModel。
/// iOS 参照：XYAIModule/XYAIModule/Classes/ViewModel/XYPaymentViewModel.swift。
///
/// 倒计时基于注入时钟（页面层传 `apiClient.serverNow`，对应 iOS XYServerTime）；
/// 测试注入固定时钟。
class PaymentViewModel {
  PaymentViewModel({
    required this.args,
    required PaymentGateway gateway,
    DateTime Function()? clock,
    AlipayPayLauncher? alipayLauncher,
    WechatPayLauncher? wechatLauncher,
    this.confirmRetries = confirmRetryCount,
    this.confirmRetryDelay = confirmRetryDelayConst,
  })  : _gateway = gateway,
        _alipayLauncher = alipayLauncher ?? alipayPayWithTobias,
        _wechatLauncher = wechatLauncher ?? wechatPayWithFluwx,
        countdown = DeadlineCountdown(args.paymentDeadline, clock: clock);

  /// 展示/支付参数
  final PaymentPageArgs args;

  final PaymentGateway _gateway;

  /// 唤起支付宝收银台实现（默认 tobias；测试注入 fake）
  final AlipayPayLauncher _alipayLauncher;

  /// 唤起微信收银台实现（默认 fluwx；测试注入 fake）
  final WechatPayLauncher _wechatLauncher;

  /// confirm 验真重试次数（默认 3；测试注入 1 缩短时长）
  final int confirmRetries;

  /// confirm 重试间隔（默认 1s；测试注入 [Duration.zero]）
  final Duration confirmRetryDelay;

  /// 倒计时助手（支付页与结果判定共用）
  final DeadlineCountdown countdown;

  /// 当前选中的支付方式（默认支付宝）
  PaymentMethod selectedMethod = PaymentMethod.alipay;

  /// 切换支付方式
  void selectMethod(PaymentMethod method) {
    selectedMethod = method;
  }

  /// 是否配置了支付截止时间（决定倒计时横幅是否展示）
  bool get hasPaymentDeadline => countdown.hasDeadline;

  /// 倒计时 mm:ss 展示文案
  String get countdownText => countdown.countdownText;

  /// 支付是否已超时（无截止时间视为未超时）
  bool get isExpired => countdown.isExpired;

  /// 当前 payType（"wechat" / "alipay"）
  String get payType =>
      selectedMethod == PaymentMethod.wechat ? 'wechat' : 'alipay';

  /// 发起支付：
  /// 1. /app/pay/create 统一下单（金额以服务端订单价格为准），拿 outTradeNo + 对应通道参数；
  /// 2. 按支付方式唤起收银台：
  ///    - 支付宝：orderInfo 非空 → 唤起收银台；为空（服务端 dev/test 且通道未配置，
  ///      生产通道未配置时 create 已拒绝下单）→ 走 /mock-success 模拟支付成功联调；
  ///    - 微信：wxPayParams 非空 → 唤起收银台；为空 → 同上走 mock 兜底；
  /// 3. 真实唤起成功后调用 /app/pay/confirm 由服务端调对应通道交易查询接口验真：
  ///    交易真实成功且金额一致才落库联动；confirm 短暂失败（渠道状态未同步/网络/后端
  ///    临时错误）先短时重试，重试仍失败视为「确认中」而非「支付未完成」，避免
  ///    用户已扣款却被引导重复支付。
  /// 成功返回 outTradeNo；失败抛 PaymentFlowException。
  Future<String> pay() async {
    if (args.orderId.isEmpty) {
      throw const PaymentFlowException('订单号缺失');
    }
    final result = await _gateway.createPayment(
      orderId: args.orderId,
      payType: payType,
    );
    if (payType == 'alipay') {
      final orderInfo = result.orderInfo;
      if (orderInfo == null || orderInfo.isEmpty) {
        // 支付宝未配置（仅 dev/test 可能，生产 create 已拒绝下单）：
        // 走 mock 模拟支付成功联调，落库并联动订单后即视为支付成功，不再 confirm
        // （通道未配置时 confirm 验真必然失败）
        await _gateway.mockPaymentSuccess(result.outTradeNo);
        return result.outTradeNo;
      }
      // 唤起支付宝收银台：cancelled（用户取消/系统明确失败）→ 未完成流程；
      // success 与 unknown（8000 确认中/6004 结果未知，用户可能已扣款）→ 均继续走
      // 服务端 confirm 查单验真，避免已扣款却被误判「支付未完成」引导重复支付
      final outcome = await _alipayLauncher(orderInfo);
      if (outcome == AlipayPayResult.cancelled) {
        throw const PaymentFlowException('支付未完成');
      }
    } else {
      final params = result.wxPayParams;
      if (params == null) {
        // 微信未配置（仅 dev/test 可能，生产 create 已拒绝下单）：走 mock 兜底联调
        await _gateway.mockPaymentSuccess(result.outTradeNo);
        return result.outTradeNo;
      }
      // 唤起微信收银台；返回 false 表示用户取消/支付失败/超时，进入未完成流程
      final launched = await _wechatLauncher(params);
      if (!launched) {
        throw const PaymentFlowException('支付未完成');
      }
    }
    await _confirmWithRetry(result.outTradeNo);
    return result.outTradeNo;
  }

  /// confirm 验真 + 短时重试：
  /// 支付渠道状态短暂未同步、网络超时或后端临时错误时立即失败会误导用户重复支付，
  /// 先按 [confirmRetries] 次短时重试；仍失败视为「确认中」——
  /// 用户已扣款的场景由订单列表的最终状态兜底，不再强制走重新支付。
  Future<void> _confirmWithRetry(String outTradeNo) async {
    for (var i = 0; i < confirmRetries; i++) {
      try {
        await _gateway.confirmPayment(outTradeNo: outTradeNo);
        return;
      } catch (_) {
        if (i < confirmRetries - 1) {
          await Future<void>.delayed(confirmRetryDelay);
        }
      }
    }
    // 重试仍失败：不判定「支付未完成」，提示结果确认中，由订单状态兜底
    throw const PaymentFlowException(
      '支付结果确认中，请稍后在订单列表查看',
      isConfirming: true,
    );
  }
}

/// 支付流程本地校验异常（对应 iOS failure("订单号缺失")）。
class PaymentFlowException implements Exception {
  const PaymentFlowException(this.message, {this.isConfirming = false});

  final String message;

  /// 是否为「支付结果确认中」：用户已扣款但本地 confirm 重试仍失败。
  /// 页面应引导去订单列表查询最终状态，禁止进入「重新支付」流程。
  final bool isConfirming;

  @override
  String toString() => message;
}
