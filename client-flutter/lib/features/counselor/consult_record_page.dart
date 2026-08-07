import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_response.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_background.dart';
import '../../core/widgets/app_loading_hud.dart';
import '../../core/widgets/app_nav_bar.dart';
import '../../core/widgets/app_toast.dart';
import 'counselor_api.dart';

/// 咨询记录与总结页（路由 /consultant/record?orderId=，深链 1010，仅咨询师）。
/// iOS 参照：XYCounselorModule/XYCounselorModule/Classes/ViewController/
/// XYCounselorConsultRecordViewController.swift（Figma 571:5306）——
/// AI 会话内容提取（主要议题/情绪状态/核心冲突）+ 咨询师小结（用户可见）+
/// 行动建议与练习（动态增删）+ 底部「发送给用户」。
///
/// ⚠ 与任务简版的出入（均以 iOS 代码为准，1:1 不改设计）：
/// - 提交按钮渐变：iOS 为品牌青绿 #00D8E0 → #00AFBE（Style.submitGradient*），
///   非靛蓝；这里按 iOS 还原；
/// - iOS 行动建议仅「新增一条」无删除入口；删除为任务要求的本端扩展
///   （每条右上角关闭图标），样式尽量贴近 iOS；
/// - iOS 未设字数上限，故本页同样不限制字数。
class ConsultRecordPage extends ConsumerStatefulWidget {
  const ConsultRecordPage({super.key, this.orderId});

  /// 订单 ID（路由 query orderId 多键兼容解析；null 表示缺失）
  final int? orderId;

  @override
  ConsumerState<ConsultRecordPage> createState() => _ConsultRecordPageState();
}

class _ConsultRecordPageState extends ConsumerState<ConsultRecordPage> {
  /// 咨询师小结输入（iOS consultantSummaryTextView）
  final TextEditingController _summaryController = TextEditingController();

  /// 行动建议输入列表（iOS actionItemTextViews 动态数组）
  final List<TextEditingController> _adviceControllers = [];

  /// AI 提取三段（/consultant/summary/detail 回填；空显示「暂无内容」）
  String? _aiMainTopic;
  String? _aiEmotionalState;
  String? _aiCoreConflict;

  /// 是否正在提交（iOS isSubmitting）
  bool _submitting = false;

  /// 多行输入框高（iOS textViewHeight 108）
  static const double _textFieldHeight = 108;

  @override
  void initState() {
    super.initState();
    // iOS buildContent：默认先有一条行动建议输入框
    _appendAdviceField();
    _fetchSummaryDetail();
  }

  @override
  void dispose() {
    _summaryController.dispose();
    for (final c in _adviceControllers) {
      c.dispose();
    }
    super.dispose();
  }

  /// 拉取总结详情：回填 AI 三段（小结正文与行动建议不预填，
  /// 由咨询师自行填写——iOS applySummaryDetail）。
  /// ⚠ Android 前端未见调用 /consultant/summary/detail（契约 §6），
  /// 字段以 iOS 为准，待后端确认。
  Future<void> _fetchSummaryDetail() async {
    final orderId = widget.orderId;
    if (orderId == null || orderId <= 0) return;
    try {
      final detail =
          await ref.read(counselorApiProvider).fetchSummaryDetail(orderId);
      if (!mounted || detail == null) return;
      setState(() {
        _aiMainTopic = _trimOrNull(detail.aiMainTopic);
        _aiEmotionalState = _trimOrNull(detail.aiEmotionalState);
        _aiCoreConflict = _trimOrNull(detail.aiCoreConflict);
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      AppToast.show(context, e.msg);
    }
  }

  static String? _trimOrNull(String? text) {
    final trimmed = text?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  /// 追加一条行动建议输入框（iOS appendActionItemField）
  void _appendAdviceField() {
    setState(() => _adviceControllers.add(TextEditingController()));
  }

  /// 删除一条行动建议输入框（本端扩展：iOS 无删除入口，任务要求增删）
  void _removeAdviceField(int index) {
    if (index < 0 || index >= _adviceControllers.length) return;
    setState(() {
      final controller = _adviceControllers.removeAt(index);
      controller.dispose();
    });
  }

  /// 发送给用户（iOS submitButtonTapped → ViewModel.submitRecord）：
  /// 本地校验 → #37 /consultant/summary/save → 成功 Toast「已发送」+ 返回
  /// （pop(true)，工作台据此刷新已咨询列表）。
  Future<void> _submit() async {
    if (_submitting) return;
    FocusScope.of(context).unfocus();

    final orderId = widget.orderId;
    if (orderId == null || orderId <= 0) {
      AppToast.show(context, '订单信息无效');
      return;
    }
    final content = _summaryController.text.trim();
    if (content.isEmpty) {
      AppToast.show(context, '请填写咨询师小结');
      return;
    }
    final advice = [
      for (final c in _adviceControllers)
        if (c.text.trim().isNotEmpty) c.text.trim(),
    ];
    if (advice.isEmpty) {
      AppToast.show(context, '请至少填写一条行动建议');
      return;
    }

    setState(() => _submitting = true);
    try {
      await ref.read(counselorApiProvider).saveSummary(
            orderId: orderId,
            content: content,
            advice: advice,
          );
      if (!mounted) return;
      AppToast.show(context, '已发送');
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      AppToast.show(context, e.msg);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.pageBackground,
          // 底部「发送给用户」操作栏（iOS setupBottomBar：白底 + 上投影）
          bottomNavigationBar: _RecordBottomBar(
            submitting: _submitting,
            onSubmit: _submit,
          ),
          body: AppPageBackground(
            child: SafeArea(
              child: Column(
                children: [
                  // iOS gk_navTitle = 发给用户的总结与建议
                  const AppNavBar(title: '发给用户的总结与建议', transparent: true),
                  Expanded(
                    child: GestureDetector(
                      // 点击空白收起键盘（iOS dismissTap）
                      onTap: () => FocusScope.of(context).unfocus(),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.all(AppDimens.cardPadding),
                        child: Column(
                          children: [
                            _buildAiCard(),
                            const SizedBox(height: AppDimens.gap10),
                            _buildSummaryCard(),
                            const SizedBox(height: AppDimens.gap10),
                            _buildAdviceCard(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_submitting)
          const Positioned.fill(
            child: AppLoadingHud(message: '提交中'),
          ),
      ],
    );
  }

  /// 「AI会话内容提取」卡片（iOS makeAICard）
  Widget _buildAiCard() {
    return _RecordCard(
      title: 'AI会话内容提取',
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.innerBackground,
          borderRadius: BorderRadius.circular(AppDimens.radiusInner),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AiSection(title: '主要议题：', body: _aiMainTopic),
            const SizedBox(height: AppDimens.gap12),
            _AiSection(title: '情绪状态：', body: _aiEmotionalState),
            const SizedBox(height: AppDimens.gap12),
            _AiSection(title: '核心冲突：', body: _aiCoreConflict),
          ],
        ),
      ),
    );
  }

  /// 「咨询师小结 (用户可见)」输入卡片（iOS makeConsultantSummaryCard）
  Widget _buildSummaryCard() {
    return _RecordCard(
      title: '咨询师小结 (用户可见)',
      child: _RecordTextField(
        controller: _summaryController,
        hint: '请输入本次咨询的小结，帮助用户回顾和梳理',
        height: _textFieldHeight,
      ),
    );
  }

  /// 「行动建议与练习 (用户可见)」输入卡片（iOS makeActionItemsCard）
  Widget _buildAdviceCard() {
    return _RecordCard(
      title: '行动建议与练习 (用户可见)',
      child: Column(
        children: [
          for (var i = 0; i < _adviceControllers.length; i++) ...[
            if (i > 0) const SizedBox(height: AppDimens.gap10),
            Stack(
              children: [
                _RecordTextField(
                  controller: _adviceControllers[i],
                  hint: '下一步建议、用户需要完成的作业或训练',
                  height: _textFieldHeight,
                ),
                // 删除入口（本端扩展：iOS 无删除，任务要求增删）
                if (_adviceControllers.length > 1)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _removeAdviceField(i),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.close,
                          size: 16,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: AppDimens.gap12),
          // 新增一条（iOS：#ECFBFF 底圆角 18、高 36、13 #00A6A1）
          GestureDetector(
            onTap: _appendAdviceField,
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.brandTealSelected,
                borderRadius: BorderRadius.circular(18),
              ),
              alignment: Alignment.center,
              child: Text(
                '新增一条',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.brandTeal,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 底部操作栏
// ---------------------------------------------------------------------------

/// 底部操作栏：「发送给用户」45 高圆角 22.5，品牌青绿渐变
/// （iOS Style.submitGradient #00D8E0 → #00AFBE）。
class _RecordBottomBar extends StatelessWidget {
  const _RecordBottomBar({required this.submitting, required this.onSubmit});

  final bool submitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        boxShadow: [
          BoxShadow(
            color: Color(0x66EAEAEA),
            offset: Offset(0, -4),
            blurRadius: 4,
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: AppDimens.screenPadding,
        right: AppDimens.screenPadding,
        top: AppDimens.gap15,
        bottom: AppDimens.gap10 + MediaQuery.of(context).padding.bottom,
      ),
      child: GestureDetector(
        onTap: submitting ? null : onSubmit,
        child: Container(
          height: AppDimens.buttonHeight,
          decoration: BoxDecoration(
            gradient: AppColors.brandGradient,
            borderRadius:
                BorderRadius.circular(AppDimens.buttonRadiusCapsule),
          ),
          alignment: Alignment.center,
          child: Text(
            '发送给用户',
            style: AppTextStyles.title.copyWith(color: Colors.white),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 通用部件
// ---------------------------------------------------------------------------

/// 白色圆角卡片（标题 15 w600 + 内容，间距 12）。
/// iOS 参照：makeCardView / makeEditableCard。
class _RecordCard extends StatelessWidget {
  const _RecordCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimens.cardRadius),
      ),
      padding: const EdgeInsets.all(AppDimens.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.titleSmall),
          const SizedBox(height: AppDimens.gap12),
          child,
        ],
      ),
    );
  }
}

/// 多行输入框（#F7F8FC 底圆角 10、14 #222、占位 14 #999、内边距 12）。
/// iOS 参照：configureTextView（UITextView + 占位 Label）。
class _RecordTextField extends StatelessWidget {
  const _RecordTextField({
    required this.controller,
    required this.hint,
    required this.height,
  });

  final TextEditingController controller;
  final String hint;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: TextField(
        controller: controller,
        expands: true,
        maxLines: null,
        textAlignVertical: TextAlignVertical.top,
        style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              AppTextStyles.bodyLarge.copyWith(color: AppColors.textTertiary),
          filled: true,
          fillColor: AppColors.innerBackground,
          contentPadding: const EdgeInsets.all(12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusInner),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusInner),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusInner),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

/// AI 提取字段（标签 13 w600 #00A6A1 + 正文 13；空 → 暂无内容 #999）。
/// iOS 参照：makeAISection / setAIPlaceholder。
class _AiSection extends StatelessWidget {
  const _AiSection({required this.title, required this.body});

  final String title;
  final String? body;

  @override
  Widget build(BuildContext context) {
    final hasContent = body != null && body!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.brandTeal,
          ),
        ),
        const SizedBox(height: AppDimens.gap6),
        Text(
          hasContent ? body! : '暂无内容',
          style: AppTextStyles.body.copyWith(
            color: hasContent
                ? AppColors.textPrimary
                : AppColors.textTertiary,
          ),
        ),
      ],
    );
  }
}
