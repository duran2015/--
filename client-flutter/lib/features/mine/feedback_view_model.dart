import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'mine_api.dart';

/// 意见反馈页 ViewModel provider。
final feedbackViewModelProvider = Provider<FeedbackViewModel>((ref) {
  return FeedbackViewModel(submitFn: ref.read(mineApiProvider).submitFeedback);
});

/// 意见反馈页 ViewModel：校验与提交。
/// iOS 参照：XYMineModule/.../XYFeedbackViewModel.swift
/// （POST /app/mine/feedback/submit，body content）。
class FeedbackViewModel {
  FeedbackViewModel({
    required Future<void> Function({required String content}) submitFn,
  }) : _submitFn = submitFn;

  final Future<void> Function({required String content}) _submitFn;

  /// 判断反馈内容是否可提交（去空白后非空）。
  /// iOS 参照：XYFeedbackViewModel.canSubmit。
  bool canSubmit(String content) => content.trim().isNotEmpty;

  /// 提交意见反馈。
  /// iOS 参照：XYFeedbackViewModel.submit。
  Future<void> submit(String content) {
    return _submitFn(content: content.trim());
  }
}
