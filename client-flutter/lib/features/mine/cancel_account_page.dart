import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_response.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_background.dart';
import '../../core/widgets/app_dialog.dart';
import '../../core/widgets/app_loading_hud.dart';
import '../../core/widgets/app_nav_bar.dart';
import '../../core/widgets/app_toast.dart';
import 'cancel_account_view_model.dart';

/// 注销账号页（路由 /mine/cancel-account）。
/// iOS 参照：XYMineModule/XYMineModule/Classes/ViewController/
/// XYCancelAccountViewController.swift（Figma node 1205:3369）——
/// 风险提示卡（#FFF9F4 浅底 + #FF3D3D 文案）+ 手机号验证卡
/// （脱敏手机号 + 6 位验证码 + 60s 倒计时 + 渐变按钮）。
class CancelAccountPage extends ConsumerStatefulWidget {
  const CancelAccountPage({super.key});

  /// 重发倒计时秒数（iOS startCountdown 60）
  static const int countdownSeconds = 60;

  /// 验证码位数（iOS 固定 6 位）
  static const int codeLength = 6;

  /// 输入框/获取验证码按钮高度（iOS inputHeight，Figma 104 → 52）
  static const double _inputHeight = 52;

  /// 获取验证码按钮宽度（iOS 110）
  static const double _sendButtonWidth = 110;

  @override
  ConsumerState<CancelAccountPage> createState() => _CancelAccountPageState();
}

class _CancelAccountPageState extends ConsumerState<CancelAccountPage> {
  final TextEditingController _codeController = TextEditingController();

  Timer? _countdownTimer;
  int _remain = 0;
  bool _sending = false;
  bool _submitting = false;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  // ---------- 倒计时（iOS startCountdown / tick / updateSendCodeButton） ----------

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() => _remain = CancelAccountPage.countdownSeconds);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _remain -= 1;
        if (_remain <= 0) {
          _remain = 0;
          timer.cancel();
        }
      });
    });
  }

  // ---------- 发送验证码（iOS sendCodeTapped） ----------

  Future<void> _sendCodeTapped() async {
    if (_remain > 0 || _sending) return;
    setState(() => _sending = true);
    try {
      await ref.read(cancelAccountViewModelProvider).sendSmsCode();
      if (!mounted) return;
      AppToast.show(context, '验证码已发送');
      _startCountdown();
    } on ApiException catch (e) {
      if (!mounted) return;
      AppToast.show(context, e.msg);
    } catch (_) {
      if (!mounted) return;
      AppToast.show(context, '发送失败，请稍后重试');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  // ---------- 验证并注销（iOS confirmTapped） ----------

  Future<void> _confirmTapped() async {
    final code = _codeController.text;
    if (code.length != CancelAccountPage.codeLength) {
      AppToast.show(context, '请输入6位验证码');
      return;
    }
    // 二次确认弹窗（iOS 无此弹窗直接注销，按 Flutter 阶段 6 任务要求补充，
    // 文案取自 iOS 风险提示正文语义）
    final confirmed = await AppCenterDialog.show(
      context,
      title: '提示',
      content: '注销后该身份的账号信息、会话记录与订单数据将被清除，且无法恢复。确定要注销吗？',
      cancelText: '取消',
      confirmText: '确定',
    );
    if (confirmed != true || !mounted) return;

    setState(() => _submitting = true);
    try {
      final vm = ref.read(cancelAccountViewModelProvider);
      await vm.deactivate(code);
      if (!mounted) return;
      AppToast.show(context, '注销成功');
      // 延迟 2s 清登录态（IM 登出经 onImLogout 钩子），路由自动回 /login
      // iOS 参照：confirmTapped 延迟避免转场吞掉「注销成功」toast
      unawaited(vm.logoutAfterSuccess());
    } on ApiException catch (e) {
      if (!mounted) return;
      AppToast.show(context, e.msg);
    } catch (_) {
      if (!mounted) return;
      AppToast.show(context, '注销失败，请稍后重试');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(cancelAccountViewModelProvider);
    final codeLength = _codeController.text.length;
    final canConfirm = codeLength == CancelAccountPage.codeLength;

    return Scaffold(
      // iOS：F1F4FB 底 + XYOrderBackgroundView + 透明导航栏（gk_navLineHidden）
      body: AppPageBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  const AppNavBar(
                    title: '注销账号',
                    transparent: true,
                    lineHidden: true,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(
                        top: 20, // iOS riskCardTopOffset
                        left: AppDimens.screenPadding,
                        right: AppDimens.screenPadding,
                        bottom: AppDimens.gap20,
                      ),
                      child: Column(
                        children: [
                          _buildRiskCard(),
                          const SizedBox(height: AppDimens.gap15),
                          _buildVerifyCard(vm, canConfirm),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              // 注销中加载遮罩（iOS XYLoading.show("注销中")）
              if (_submitting)
                const Positioned.fill(
                  child: AppLoadingHud(message: '注销中'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 风险提示卡：#FFF9F4 圆角 12，标题 16 w600 + 正文 14，均 #FF3D3D。
  /// iOS 参照：setupRiskCard。
  Widget _buildRiskCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.tipBackground,
        borderRadius: BorderRadius.circular(AppDimens.cardRadius),
      ),
      padding: const EdgeInsets.all(AppDimens.gap15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '注销账号风险确认',
            style: AppTextStyles.title.copyWith(color: AppColors.priceRed),
          ),
          const SizedBox(height: AppDimens.gap10),
          Text(
            '将注销您当前的身份（用户/咨询师），注销后该身份的账号信息、会话记录与订单数据将被清除，且无法恢复。为了您的账号安全，需验证当前绑定的手机号。',
            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.priceRed),
          ),
        ],
      ),
    );
  }

  /// 手机号验证卡：标题 18 w600 + 脱敏手机号 14 #666 + 验证码输入区 +
  /// 获取验证码（渐变 110×52 圆角 12）+ 验证并注销（渐变胶囊 52）。
  /// iOS 参照：setupVerifyCard。
  Widget _buildVerifyCard(CancelAccountViewModel vm, bool canConfirm) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimens.cardRadius),
      ),
      padding: const EdgeInsets.only(
        top: AppDimens.gap20,
        left: AppDimens.gap15,
        right: AppDimens.gap15,
        bottom: AppDimens.gap20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('验证手机号', style: AppTextStyles.titleLarge),
          const SizedBox(height: AppDimens.gap10),
          Text(
            vm.maskedPhone,
            style: AppTextStyles.bodyLarge
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppDimens.gap15),
          Row(
            children: [
              // 验证码输入区：#F7F8FC 圆角 12 高 52，输入 18 #222
              Expanded(
                child: Container(
                  height: CancelAccountPage._inputHeight,
                  decoration: BoxDecoration(
                    color: AppColors.innerBackground,
                    borderRadius: BorderRadius.circular(AppDimens.cardRadius),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.gap15,
                  ),
                  alignment: Alignment.center,
                  child: TextField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    maxLength: CancelAccountPage.codeLength,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(
                      fontSize: 18,
                      color: AppColors.textPrimary,
                    ),
                    decoration: const InputDecoration(
                      hintText: '请输入6位短信验证码',
                      hintStyle: TextStyle(
                        fontSize: 18,
                        color: AppColors.placeholder,
                      ),
                      border: InputBorder.none,
                      counterText: '',
                      isCollapsed: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ),
              const SizedBox(width: AppDimens.gap10),
              // 获取验证码按钮：渐变 110×52 圆角 12；倒计时中「Ns」透明度 0.6 禁用
              _GradientButton(
                text: _remain > 0 ? '${_remain}s' : '获取验证码',
                width: CancelAccountPage._sendButtonWidth,
                height: CancelAccountPage._inputHeight,
                radius: AppDimens.cardRadius,
                opacity: _remain > 0 ? 0.6 : 1.0,
                onTap: _remain > 0 ? null : _sendCodeTapped,
              ),
            ],
          ),
          const SizedBox(height: AppDimens.gap15),
          // 验证并注销：渐变胶囊 52（圆角 22.5），未满 6 位透明度 0.3 禁用
          _GradientButton(
            text: '验证并注销',
            height: CancelAccountPage._inputHeight,
            radius: AppDimens.buttonRadiusCapsule,
            opacity: canConfirm ? 1.0 : 0.3,
            onTap: canConfirm ? _confirmTapped : null,
          ),
        ],
      ),
    );
  }
}

/// 渐变按钮（左 #00E0C7 → 中 #00BCCE → 右 #00AFBE，白字 16 w600）。
/// iOS 参照：XYCancelAccountViewController.GradientButton
/// （colors [00AFBE, 00BCCE, 00E0C7] 右→左，等价 brandButtonGradient）。
class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.text,
    required this.height,
    required this.radius,
    required this.opacity,
    this.width,
    this.onTap,
  });

  final String text;
  final double height;
  final double radius;
  final double opacity;
  final double? width;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: width ?? double.infinity,
          height: height,
          decoration: BoxDecoration(
            gradient: AppColors.brandButtonGradient,
            borderRadius: BorderRadius.circular(radius),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: AppTextStyles.title.copyWith(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
