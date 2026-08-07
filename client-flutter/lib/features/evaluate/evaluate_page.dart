import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/network/api_response.dart';
import '../../core/theme/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_background.dart';
import '../../core/widgets/app_nav_bar.dart';
import '../../core/widgets/app_loading_hud.dart';
import '../../core/widgets/app_toast.dart';
import '../../utils/load_image.dart';
import 'evaluate_api.dart';
import 'evaluate_models.dart';

/// 评价咨询师页（路由 /evaluate，深链 1008）。
/// iOS 参照：XYMessageModule/XYMessageModule/Classes/ViewController/
/// XYEvaluateViewController.swift（Figma 457:2150）——
/// 白卡（头像 58 / 姓名 / 副标题 / 5 星打分 / 标签多选 / 补充输入）
/// + 底部「提交评价」青渐变按钮（45 高）。
class EvaluatePage extends ConsumerStatefulWidget {
  const EvaluatePage({
    super.key,
    required this.orderId,
    required this.counselorId,
    required this.counselorName,
    this.counselorAvatar,
  });

  /// 订单 id（多键 orderId/order_id/orderID 已在路由层归一）
  final String orderId;

  /// 咨询师业务 id（counselorId/consultantId/userId 已在路由层归一）
  final String counselorId;

  /// 咨询师姓名 / 头像（路由参数传入，可缺省）
  final String counselorName;
  final String? counselorAvatar;

  @override
  ConsumerState<EvaluatePage> createState() => _EvaluatePageState();
}

class _EvaluatePageState extends ConsumerState<EvaluatePage> {
  /// iOS 参照：副标题提示文案 / 输入框占位文案
  static const String _subtitle = '本次咨询已结束，请为咨询师打分';
  static const String _placeholder = '您的评价对我们非常重要';

  /// 底栏顶/底内边距（iOS bottomBarTopPadding / bottomBarBottomPadding）
  static const double _bottomBarTopPadding = 15;
  static const double _bottomBarBottomPadding = 10;

  final _contentController = TextEditingController();
  final _contentFocusNode = FocusNode();
  final _scrollController = ScrollController();

  /// 当前打分（1~5），默认 5 颗满星（iOS 参照：currentRating）
  int _rating = 5;

  List<EvaluateTagItem> _tags = const [];
  final Set<int> _selectedTagIds = {};
  bool _tagsLoaded = false;
  bool _submitting = false;

  /// 上一帧键盘高度，用于弹起后把输入框滚入可视区（iOS keyboardWillChange）
  double _lastKeyboardInset = 0;

  @override
  void initState() {
    super.initState();
    _fetchTags();
    _contentFocusNode.addListener(_onContentFocusChanged);
  }

  @override
  void dispose() {
    _contentFocusNode.removeListener(_onContentFocusChanged);
    _contentFocusNode.dispose();
    _contentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onContentFocusChanged() {
    if (_contentFocusNode.hasFocus) {
      _ensureTextFieldVisible();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    // 键盘刚弹起：底栏已上移后补一次滚入（对齐 iOS keyboardWillChange completion）
    if (keyboardInset > _lastKeyboardInset + 1 && _contentFocusNode.hasFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _ensureTextFieldVisible();
      });
    }
    _lastKeyboardInset = keyboardInset;
  }

  /// 键盘弹起后把「补充想说的话」滚入可视区（iOS scrollRectToVisible）。
  void _ensureTextFieldVisible() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // 等 Scaffold 按 viewInsets 完成收缩后再滚
      await Future<void>.delayed(const Duration(milliseconds: 280));
      if (!mounted || !_contentFocusNode.hasFocus) return;
      if (!_scrollController.hasClients) return;
      await _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  /// 拉取评价可选标签（无数据或失败时收起标签区，iOS 参照：setTagSectionHidden）。
  Future<void> _fetchTags() async {
    try {
      final tags = await ref.read(evaluateApiProvider).fetchReviewTags();
      if (!mounted) return;
      setState(() {
        _tags = tags;
        _tagsLoaded = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _tagsLoaded = true); // 失败收起标签区
    }
  }

  /// 已选标签 id 列表（按接口返回顺序，iOS 参照：selectedTagIdsList）。
  List<int> get _selectedTagIdsList => [
        for (final tag in _tags)
          if (_selectedTagIds.contains(tag.tagId)) tag.tagId,
      ];

  @override
  Widget build(BuildContext context) {
    final showTagSection = _tagsLoaded && _tags.isNotEmpty;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final keyboardVisible = keyboardInset > 0;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    // 键盘弹起时不再叠加 Home Indicator（iOS updateBottomBarLayout）
    final submitBottomInset =
        _bottomBarBottomPadding + (keyboardVisible ? 0.0 : safeBottom);

    return Scaffold(
      // false：背景铺满全屏；底栏用 viewInsets 上移（对齐 iOS，避免键盘区露黑底）
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.pageBackground,
      body: AppPageBackground(
        // 整页内容上移 keyboardInset，渐变仍铺满（iOS bottomBar offset = -keyboardHeight）
        child: Padding(
          padding: EdgeInsets.only(bottom: keyboardInset),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Column(
                children: [
                  const SafeArea(
                    bottom: false,
                    child: AppNavBar(title: '评价咨询师', transparent: true),
                  ),
                  // 滚动区底边贴底栏顶（iOS scrollView.bottom = bottomBar.top）
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () => FocusScope.of(context).unfocus(),
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.all(15),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: AppColors.cardBackground,
                            borderRadius:
                                BorderRadius.circular(AppDimens.cardRadius),
                          ),
                          child: Column(
                            children: [
                              _header(),
                              const SizedBox(height: 25),
                              _starSection(),
                              const SizedBox(height: 25),
                              if (showTagSection) ...[
                                _sectionTitle('选择符合的标签'),
                                const SizedBox(height: 15),
                                _tagFlow(),
                                const SizedBox(height: 25),
                              ],
                              _sectionTitle('补充想说的话'),
                              const SizedBox(height: 15),
                              _textInput(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  _buildBottomBar(submitBottomInset),
                ],
              ),
              if (_submitting)
                const Positioned.fill(
                  child: AppLoadingHud(message: '提交中'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 头部：头像 58 + 姓名 16 semibold + 副标题 12 #666（居中）
  Widget _header() {
    return Column(
      children: [
        _CounselorAvatar(url: widget.counselorAvatar, size: 58),
        const SizedBox(height: 15),
        Text(widget.counselorName, style: AppTextStyles.title),
        const SizedBox(height: 6),
        Text(_subtitle, style: AppTextStyles.caption),
      ],
    );
  }

  /// 5 颗星打分（24 图标 / 36 热区 / 间距 12，默认满星）
  /// iOS 参照：setupStarSection / refreshStars。
  Widget _starSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < 5; i++) ...[
          GestureDetector(
            onTap: () => setState(() => _rating = i + 1),
            child: SizedBox(
              width: 36,
              height: 36,
              child: Center(
                child: LoadImage(
                  i < _rating
                      ? AppAssets.icEvaluateStarFilled
                      : AppAssets.icEvaluateStarEmpty,
                  width: 24,
                  height: 24,
                ),
              ),
            ),
          ),
          if (i < 4) const SizedBox(width: 12),
        ],
      ],
    );
  }

  Widget _sectionTitle(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(text, style: AppTextStyles.titleSmall),
    );
  }

  /// 标签多选流（32 高、圆角 6、间距 10；选中 #EBFBFF 底 #00A6A1 字 semibold，
  /// 未选 #F7F8FC 底 #222 字）。iOS 参照：XYEvaluateTagFlow.refreshStyles。
  Widget _tagFlow() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final tag in _tags)
            GestureDetector(
              onTap: () => setState(() {
                if (_selectedTagIds.contains(tag.tagId)) {
                  _selectedTagIds.remove(tag.tagId);
                } else {
                  _selectedTagIds.add(tag.tagId);
                }
              }),
              child: _tagChip(tag),
            ),
        ],
      ),
    );
  }

  Widget _tagChip(EvaluateTagItem tag) {
    final selected = _selectedTagIds.contains(tag.tagId);
    // 勿设 alignment：在 Wrap 中会把约束撑满整行；靠 padding + 文字固有宽度即可。
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color:
            selected ? AppColors.brandTealSelected : AppColors.innerBackground,
        borderRadius: BorderRadius.circular(AppDimens.radiusTag),
      ),
      child: Center(
        widthFactor: 1,
        child: Text(
          tag.tagName,
          style: AppTextStyles.body.copyWith(
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? AppColors.brandTeal : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  /// 多行评价输入框（107 高、#F7F8FC 底、圆角 6、13 号）
  /// iOS 参照：setupTextSection。
  Widget _textInput() {
    return Container(
      height: 107,
      decoration: BoxDecoration(
        color: AppColors.innerBackground,
        borderRadius: BorderRadius.circular(AppDimens.radiusTag),
      ),
      child: TextField(
        controller: _contentController,
        focusNode: _contentFocusNode,
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
        decoration: const InputDecoration(
          hintText: _placeholder,
          hintStyle: TextStyle(fontSize: 13, color: AppColors.textTertiary),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 15),
        ),
      ),
    );
  }

  /// 底部「提交评价」操作栏（白底 + 上投影；青渐变 45 高按钮 16 semibold）。
  /// iOS 参照：setupBottomBar / updateBottomBarLayout。
  Widget _buildBottomBar(double submitBottomInset) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        boxShadow: [
          BoxShadow(
            color: AppColors.divider.withValues(alpha: 0.4),
            offset: const Offset(0, -4),
            blurRadius: 4,
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        15,
        _bottomBarTopPadding,
        15,
        submitBottomInset,
      ),
      child: GestureDetector(
        onTap: _submitting ? null : _submit,
        child: Container(
          height: 45,
          decoration: BoxDecoration(
            gradient: AppColors.brandGradient,
            borderRadius: BorderRadius.circular(22.5),
          ),
          alignment: Alignment.center,
          child: Text(
            '提交评价',
            style: AppTextStyles.title.copyWith(color: Colors.white),
          ),
        ),
      ),
    );
  }

  /// 提交评价：校验 → /app/consultant/review/add → Toast + 0.5s 后返回。
  /// iOS 参照：submitButtonTapped。
  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (_submitting) return;

    final Map<String, dynamic> body;
    try {
      body = EvaluateSubmission.buildBody(
        orderId: widget.orderId,
        consultantId: widget.counselorId,
        rating: _rating,
        content: _contentController.text,
        tagIds: _selectedTagIdsList,
        currentUserId: ref.read(authControllerProvider)?.userId,
      );
    } on EvaluateSubmitException catch (e) {
      AppToast.show(context, e.message);
      return;
    }

    setState(() => _submitting = true);
    try {
      await ref.read(evaluateApiProvider).submitReview(body);
      if (!mounted) return;
      AppToast.show(context, '评价已提交');
      // iOS 参照：成功后 0.5s pop
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) context.pop(true);
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      AppToast.show(context, e.msg.isEmpty ? '提交失败' : e.msg);
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      AppToast.show(context, '提交失败');
    }
  }
}

/// 咨询师头像（58 圆；网络图失败/无 URL 时默认头像）。
/// iOS 参照：XYEvaluateViewController avatarImageView + message_avatar_chen 占位。
class _CounselorAvatar extends StatelessWidget {
  const _CounselorAvatar({this.url, required this.size});

  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final trimmed = url?.trim();
    final hasUrl = trimmed != null && trimmed.isNotEmpty;
    return ClipOval(
      child: Container(
        width: size,
        height: size,
        color: AppColors.dividerDark,
        child: hasUrl
            ? LoadImage(
                trimmed,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorWidget: _placeholder(),
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return LoadImage(
      AppAssets.icDefaultAvatar,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorWidget: Icon(
        Icons.person,
        size: size * 0.7,
        color: AppColors.avatarTintTeal,
      ),
    );
  }
}
