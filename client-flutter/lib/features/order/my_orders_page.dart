import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/consult_room/consult_room_launcher.dart';
import '../../core/consult_room/consult_room_service.dart';
import '../../core/router/route_paths.dart';
import '../../core/widgets/app_nav_bar.dart';
import '../../core/widgets/app_paged_list.dart';
import '../../core/widgets/app_states.dart';
import '../../core/widgets/app_toast.dart';
import '../payment/payment_view_model.dart';
import 'order_action.dart';
import 'order_api.dart';
import 'order_models.dart';
import 'widgets/appointment_order_card.dart';

/// 我的预约订单列表页（路由 /orders，深链 9001）。
/// iOS 参照：XYAIModule/XYAIModule/Classes/ViewController/
/// XYMyAppointmentOrdersViewController.swift——
/// 下拉刷新 + 上拉分页（pageSize 10）、空态「暂无预约订单」、
/// Cell 按钮按状态机分发（XYAppointmentOrderActionRouter.handlePrimary）。
class MyOrdersPage extends ConsumerStatefulWidget {
  const MyOrdersPage({super.key});

  @override
  ConsumerState<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends ConsumerState<MyOrdersPage> {
  final _listKey = GlobalKey<AppPagedListViewState<AppointmentOrderItem>>();

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom + 16;
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const AppNavBar(title: '预约订单'),
            Expanded(
              child: AppPagedListView<AppointmentOrderItem>(
                key: _listKey,
                pageSize: 10,
                padding: EdgeInsets.only(top: 10, bottom: bottomInset),
                emptyWidget: const AppEmptyView(message: '暂无预约订单'),
                fetcher: (pageNum, pageSize) => ref
                    .read(orderApiProvider)
                    .fetchMyOrders(pageNum: pageNum, pageSize: pageSize),
                itemBuilder: (context, item, index) => AppointmentOrderCard(
                  item: item,
                  onTap: () => _openDetail(item),
                  onAction: () => _handlePrimary(item),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 点击订单行进入预约详情页；返回时若状态有变刷新列表。
  /// iOS 参照：didSelectRowAt → onOrderStatusChanged → loadOrders(isRefresh:)。
  Future<void> _openDetail(AppointmentOrderItem item) async {
    final orderId = item.orderId;
    if (orderId == null || orderId.isEmpty) return;
    final changed = await context.push<bool>(
      '${RoutePaths.orderDetail}?orderId=$orderId',
    );
    if (changed == true) _listKey.currentState?.refresh();
  }

  /// 按订单状态分发按钮动作（去支付 / 联系咨询师 / 评价咨询师）。
  /// iOS 参照：XYAppointmentOrderActionRouter.handlePrimary。
  Future<void> _handlePrimary(AppointmentOrderItem item) async {
    switch (OrderActionRouter.cellPrimaryAction(item)) {
      case OrderPrimaryAction.pay:
        await _pushPayment(item);
      case OrderPrimaryAction.fillIntake:
        await _pushIntake(item);
      case OrderPrimaryAction.enterSession:
        await _enterSession(item);
      case OrderPrimaryAction.viewRecap:
      case OrderPrimaryAction.viewArchivedRecap:
        await _pushRecap(item);
      case OrderPrimaryAction.contact:
        await openOrderCounselorChat(context, item);
      case OrderPrimaryAction.evaluate:
        await _pushEvaluate(item);
      case OrderPrimaryAction.none:
        break;
    }
  }

  Future<void> _pushIntake(AppointmentOrderItem item) async {
    final orderId = item.orderId;
    if (orderId == null) return;
    await context.push(
      Uri(path: RoutePaths.paymentIntake, queryParameters: {
        'orderId': orderId,
        'imUserId': item.counselorIMUserID,
        'name': item.counselorName,
        if (item.counselorAvatar != null) 'avatar': item.counselorAvatar!,
      }).toString(),
    );
    if (mounted) _listKey.currentState?.refresh();
  }

  Future<void> _enterSession(AppointmentOrderItem item) async {
    if (item.supportMode == '1') {
      await openOrderCounselorChat(context, item);
      return;
    }
    await launchConsultRoom(
      ref,
      ConsultRoomParams(
        orderId: item.orderId,
        supportMode: item.supportMode,
        roomId: item.roomId,
        roomName: item.roomName ?? item.supportModeText,
        imUserId: item.counselorIMUserID,
        userName: item.counselorName,
        userAvatar: item.counselorAvatar,
      ),
      context: context,
    );
    if (mounted) _listKey.currentState?.refresh();
  }

  Future<void> _pushRecap(AppointmentOrderItem item) async {
    final id = int.tryParse(item.orderId ?? '');
    if (id == null) {
      AppToast.show(context, '回顾信息暂未生成');
      return;
    }
    await context.push('${RoutePaths.summaryDetail}?orderId=$id');
    if (mounted) _listKey.currentState?.refresh();
  }

  /// 跳转支付页（携带订单号、金额、咨询师信息）；返回后刷新列表。
  /// iOS 参照：XYAppointmentOrderActionRouter.pushPayment。
  Future<void> _pushPayment(AppointmentOrderItem item) async {
    final args = PaymentPageArgs.fromOrder(item);
    if (args.orderId.isEmpty) {
      AppToast.show(context, '订单信息无效');
      return;
    }
    await context.push(
      Uri(path: RoutePaths.payment, queryParameters: args.toQuery()).toString(),
    );
    if (mounted) _listKey.currentState?.refresh();
  }

  /// 打开评价咨询师页（1008）：携带 counselorId/orderId/姓名/头像；返回后刷新。
  /// iOS 参照：XYAppointmentOrderActionRouter.openEvaluate。
  Future<void> _pushEvaluate(AppointmentOrderItem item) async {
    final orderId = item.orderId;
    final consultantId = item.consultantId;
    if (orderId == null || orderId.isEmpty || consultantId == null) {
      AppToast.show(context, '订单信息无效');
      return;
    }
    final params = <String, String>{
      'orderId': orderId,
      'counselorId': '$consultantId',
      'counselorName': item.counselorName,
      if (item.counselorAvatar != null && item.counselorAvatar!.isNotEmpty)
        'counselorAvatar': item.counselorAvatar!,
    };
    final submitted = await context.push<bool>(
      Uri(path: RoutePaths.evaluate, queryParameters: params).toString(),
    );
    if (submitted == true) _listKey.currentState?.refresh();
  }
}
