import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_response.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_background.dart';
import '../../core/widgets/app_loading_hud.dart';
import '../../core/widgets/app_nav_bar.dart';
import '../../core/widgets/app_toast.dart';
import 'feedback_view_model.dart';

/// 意见反馈页（路由 /mine/feedback，深链 9007）。
/// iOS 参照：XYMineModule/.../XYFeedbackViewController.swift（Figma 1542:2206）——
/// 白卡片多行输入 + 底部固定渐变「提交」；未填写时按钮透明度 0.3。
class FeedbackPage extends ConsumerStatefulWidget {
  const FeedbackPage({super.key});

  /// 输入卡片高度（iOS cardHeight，Figma 360 → 180）
  static const double _cardHeight = 180;

  /// 卡片距导航栏（iOS cardTopInset 20）
  static const double _cardTopInset = 20;

  /// 输入区内边距（iOS textInset 15）
  static const double _textInset = 15;

  /// 提交按钮高度（iOS submitHeight 45）
  static const double _submitHeight = 45;

  /// 底部栏顶内边距（iOS bottomBarTopPadding 15）
  static const double _bottomBarTopPadding = 15;

  /// 底部栏底内边距（安全区之上，iOS bottomBarBottomPadding 10）
  static const double _bottomBarBottomPadding = 10;

  /// 未填写时提交按钮透明度（iOS submitDisabledAlpha 0.3）
  static const double _submitDisabledAlpha = 0.3;

  @override
  ConsumerState<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends ConsumerState<FeedbackPage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      ref.read(feedbackViewModelProvider).canSubmit(_controller.text);

  /// 提交：空内容 Toast；成功 Toast 后延迟 pop。
  /// iOS 参照：XYFeedbackViewController.submitButtonTapped。
  Future<void> _submitTapped() async {
    if (_submitting) return;
    final content = _controller.text.trim();
    final vm = ref.read(feedbackViewModelProvider);
    if (!vm.canSubmit(content)) {
      FocusScope.of(context).unfocus();
      AppToast.show(context, '反馈的意见不能为空');
      return;
    }

    setState(() => _submitting = true);
    FocusScope.of(context).unfocus();
    try {
      await vm.submit(content);
      if (!mounted) return;
      // 接口返回后先关 loading，再 Toast（与 iOS XYLoading.hide → XYToast 一致）
      setState(() => _submitting = false);
      AppToast.show(context, '反馈成功');
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      context.pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      AppToast.show(context, e.msg);
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      AppToast.show(context, '提交失败，请稍后重试');
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    // 键盘弹起时不再叠加安全区（与 iOS updateBottomBarLayout 一致）
    final submitBottomInset = FeedbackPage._bottomBarBottomPadding +
        (keyboardVisible ? 0.0 : safeBottom);
    final showPlaceholder = _controller.text.isEmpty;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: AppPageBackground(
        child: Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => FocusScope.of(context).unfocus(),
              child: Column(
                children: [
                  SafeArea(
                    bottom: false,
                    child: const AppNavBar(
                      title: '意见反馈',
                      transparent: true,
                      lineHidden: true,
                    ),
                  ),
                  // 白色圆角输入卡片
                  Padding(
                    padding: const EdgeInsets.only(
                      top: FeedbackPage._cardTopInset,
                      left: AppDimens.screenPadding,
                      right: AppDimens.screenPadding,
                    ),
                    child: Container(
                      height: FeedbackPage._cardHeight,
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius:
                            BorderRadius.circular(AppDimens.cardRadius),
                      ),
                      child: Stack(
                        children: [
                          TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            maxLines: null,
                            expands: true,
                            textAlignVertical: TextAlignVertical.top,
                            style: AppTextStyles.title.copyWith(
                              fontWeight: FontWeight.w400,
                              height: 24 / 16,
                            ),
                            cursorColor: AppColors.brandTeal,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isCollapsed: true,
                              contentPadding: EdgeInsets.all(
                                FeedbackPage._textInset,
                              ),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                          if (showPlaceholder)
                            const Positioned(
                              top: FeedbackPage._textInset,
                              left: FeedbackPage._textInset,
                              right: FeedbackPage._textInset,
                              child: IgnorePointer(
                                child: Text(
                                  '请具体描述您的问题',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.textTertiary,
                                    height: 24 / 16,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  // 底部固定提交栏（白底 + 顶阴影）
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEAEAEA).withValues(alpha: 0.4),
                          offset: const Offset(0, -4),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        AppDimens.screenPadding,
                        FeedbackPage._bottomBarTopPadding,
                        AppDimens.screenPadding,
                        submitBottomInset,
                      ),
                      child: _SubmitButton(
                        enabled: _canSubmit,
                        onTap: _submitTapped,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_submitting)
              const Positioned.fill(
                child: AppLoadingHud(message: '提交中'),
              ),
          ],
        ),
      ),
    );
  }
}

/// 渐变「提交」按钮（未填写透明度 0.3，始终可点以便 Toast）。
/// iOS 参照：XYFeedbackViewController.submitButton（XYGradientButton）。
class _SubmitButton extends StatelessWidget {
  const _SubmitButton({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : FeedbackPage._submitDisabledAlpha,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: FeedbackPage._submitHeight,
          decoration: BoxDecoration(
            gradient: AppColors.brandGradient,
            borderRadius:
                BorderRadius.circular(AppDimens.buttonRadiusCapsule),
          ),
          alignment: Alignment.center,
          child: Text(
            '提交',
            style: AppTextStyles.title.copyWith(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
