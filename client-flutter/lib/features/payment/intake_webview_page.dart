import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/route_paths.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/webview/app_webview_page.dart';
import '../../core/widgets/app_loading_hud.dart';
import '../../core/widgets/app_nav_bar.dart';
import 'widgets/intake_h5_frame.dart';

/// 咨询前问卷（intake）H5 容器：通用 WebView + 底部固定原生
/// 「提交并进入沟通通道」按钮。
/// iOS 参照：XYCoreModule/XYCoreModule/Classes/Web/XYIntakeWebViewController.swift。
/// Android 对照：webview/IntakeFormActivity.kt。
///
/// 契约（双侧原生一致，H5 零改动）：
/// - H5 链接：`https://h5.currantmind.cn/#/intake/{orderId}`；
/// - 点提交按钮 → JS `window.XY_H5.submitIntake()`，H5 完成后回调
///   bridge action `onIntakeSubmitResult {success}`：成功 → 打开与咨询师的
///   1v1 聊天页（替换当前页，返回落在支付成功页，与 iOS 导航栈一致）；
/// - 点返回 / 系统返回 → JS `window.XY_H5.closeIntake()`（H5 存草稿），
///   回调 `onIntakeCloseResult {success}`：成功 → 返回上一页；失败则解锁重试；
/// - 提交/保存期间展示加载遮罩（iOS XYLoading.show("提交中"/"保存中")），
///   防重复触发（iOS isHandlingSubmit / isHandlingBack）。
class IntakeWebViewPage extends StatefulWidget {
  const IntakeWebViewPage({
    super.key,
    required this.orderId,
    required this.counselorIMUserID,
    required this.counselorName,
    this.counselorAvatar,
  });

  /// 订单 ID（拼接 H5 链接用；iOS 为 Int，路由统一字符串传输）
  final String orderId;

  /// 咨询师 IM 用户 ID（提交成功后跳转聊天用）
  final String counselorIMUserID;

  /// 咨询师姓名（跳转聊天页标题用）
  final String counselorName;

  /// 咨询师头像 URL（跳转聊天页头像用）
  final String? counselorAvatar;

  /// 问卷 H5 根地址（iOS questionnaireTapped：
  /// "https://h5.currantmind.cn/#/intake/\(orderId)"）。
  /// 题目定义在 H5 前端、且 H5 直连它自己的后端——本地联调时本地 token/orderId
  /// 打到测试 H5 会 401 → 「暂无问卷信息」。可用
  /// `--dart-define=INTAKE_H5_BASE=https://<本地 h5>` 指向与本机后端同源的 H5。
  static const String h5Base = String.fromEnvironment('INTAKE_H5_BASE',
      defaultValue: 'https://h5.currantmind.cn');

  static String intakeUrl(String orderId) => '$h5Base/#/intake/$orderId';

  /// 导航栏标题（iOS init title: "咨询前情况了解"）
  static const String navTitle = '咨询前情况了解';

  @override
  State<IntakeWebViewPage> createState() => _IntakeWebViewPageState();
}

class _IntakeWebViewPageState extends State<IntakeWebViewPage> {
  /// 是否已触发返回/提交（iOS isHandlingBack / isHandlingSubmit 防重复）
  bool _isHandlingBack = false;
  bool _isHandlingSubmit = false;

  /// 加载遮罩文案（null 不展示；iOS XYLoading.show("保存中"/"提交中")）
  String? _busyText;

  /// 返回拦截（iOS navigationShouldPop → closeIntakeFromApp，返回 false
  /// 阻断默认 pop，等 H5 onIntakeCloseResult 回调后再关闭）
  bool _interceptBack(AppWebViewHandle handle) {
    if (_isHandlingBack) return true;
    setState(() {
      _isHandlingBack = true;
      _busyText = '保存中';
    });
    handle.evaluateJavaScript(
      'window.XY_H5 && window.XY_H5.closeIntake()',
    );
    return true;
  }

  /// 点提交按钮（iOS submitTapped）：通知 H5 提交问卷
  void _submit(AppWebViewHandle handle) {
    if (_isHandlingSubmit) return;
    debugPrint('🌐 [Intake] submitTapped → XY_H5.submitIntake()');
    setState(() {
      _isHandlingSubmit = true;
      _busyText = '提交中';
    });
    handle.evaluateJavaScript(
      'window.XY_H5 && window.XY_H5.submitIntake()',
    );
  }

  /// H5 保存草稿结果（iOS onIntakeCloseResult）：成功 → 返回上一页
  void _onCloseResult(AppWebViewHandle handle, Map<String, dynamic>? data) {
    final success = data?['success'] == true;
    setState(() => _busyText = null);
    if (success) {
      handle.close();
    } else {
      _isHandlingBack = false;
    }
  }

  /// H5 提交问卷结果（iOS onIntakeSubmitResult）：
  /// 成功 → 打开与咨询师的聊天页（替换当前页，iOS openCounselorChat
  /// 先从导航栈移除本页再 openChat，栈形一致）
  void _onSubmitResult(Map<String, dynamic>? data) {
    final success = data?['success'] == true;
    debugPrint('🌐 [Intake] onIntakeSubmitResult success=$success data=$data');
    setState(() => _busyText = null);
    if (success) {
      context.pushReplacement(
        Uri(path: RoutePaths.chat, queryParameters: {
          'targetUserId': widget.counselorIMUserID,
          'userName': widget.counselorName,
          if (widget.counselorAvatar != null &&
              widget.counselorAvatar!.isNotEmpty)
            'avatar': widget.counselorAvatar!,
        }).toString(),
      );
    } else {
      _isHandlingSubmit = false;
    }
  }

  /// 底部白色按钮面板（iOS setupBottomBar：白底 + 顶部投影
  /// #EAEAEA 40% offset(0,-4) blur 4；
  /// 按钮左/右 15、上 15、下 10+安全区（设计稿常见 10+34）、高 45、圆角 22.5、
  /// 渐变 00AFBE→00D8E0、16 semibold 白字「提交并进入沟通通道」）
  Widget _buildBottomBar(AppWebViewHandle handle) {
    // 用 viewPadding：SafeArea/键盘不会吞掉 Home Indicator 高度
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEAEAEA).withValues(alpha: 0.4),
            offset: const Offset(0, -4),
            blurRadius: 4,
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(15, 15, 15, 10 + bottomInset),
      child: GestureDetector(
        key: const Key('intake_submit'),
        behavior: HitTestBehavior.opaque,
        onTap: () => _submit(handle),
        child: Container(
          width: double.infinity,
          height: 45,
          decoration: BoxDecoration(
            // iOS submitButton.colors = (00AFBE, 00D8E0)（与品牌渐变反向）
            gradient: const LinearGradient(
              colors: [
                AppColors.brandGradientEnd,
                AppColors.brandGradientStart,
              ],
            ),
            borderRadius: BorderRadius.circular(22.5),
          ),
          alignment: Alignment.center,
          child: Text(
            '提交并进入沟通通道',
            style: AppTextStyles.titleLarge.copyWith(
              fontSize: 16,
              height: 1,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return _buildWebH5Page();
    return Stack(
      children: [
        AppWebViewPage(
          url: IntakeWebViewPage.intakeUrl(widget.orderId),
          title: IntakeWebViewPage.navTitle,
          // iOS XYIntakeWebViewController init：useSharedBackground = true
          useSharedBackground: true,
          extraActions: {
            // iOS registerActions(in:)：H5 提交/保存后通知原生处理结果
            'onIntakeCloseResult': (handle, data) async {
              _onCloseResult(handle, data);
              return null;
            },
            'onIntakeSubmitResult': (handle, data) async {
              _onSubmitResult(data);
              return null;
            },
          },
          backInterceptor: _interceptBack,
          bottomBarBuilder: _buildBottomBar,
        ),
        if (_busyText != null)
          Positioned.fill(
            child: AppLoadingHud(message: _busyText!),
          ),
      ],
    );
  }

  /// Web 端用 iframe 加载与移动端相同的原始 H5，避免 webview_flutter
  /// 在浏览器平台没有实现而报错，也不再维护本地仿制表单。
  Widget _buildWebH5Page() {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const AppNavBar(title: IntakeWebViewPage.navTitle),
            Expanded(
              child: IntakeH5Frame(
                url: IntakeWebViewPage.intakeUrl(widget.orderId),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
