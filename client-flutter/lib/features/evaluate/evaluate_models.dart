/// 评价页数据模型与提交参数组装。
/// iOS 参照：XYMessageModule/XYMessageModule/Classes/ViewModel/
/// XYEvaluateViewModel.swift（XYConsultantReviewTag / XYEvaluateTagItem /
/// submitReview body）。
library;

/// 评价页标签展示项（含提交所需的 tagId）。
/// iOS 参照：XYEvaluateTagItem。
class EvaluateTagItem {
  const EvaluateTagItem({required this.tagId, required this.tagName});

  /// 标签 ID
  final int tagId;

  /// 标签展示文案
  final String tagName;

  /// /app/consultant/review/tags 的 data[] 元素 → 展示项
  /// （tagId/id 与 tagName/name/tag 多键兼容；无 id 或空名的过滤掉，
  /// iOS 参照：XYConsultantReviewTagsPayload）。
  static EvaluateTagItem? fromJson(Map<String, dynamic> json) {
    final id = _intOf(json['tagId']) ?? _intOf(json['id']);
    final name = (json['tagName'] ?? json['name'] ?? json['tag'])?.toString();
    if (id == null || name == null || name.isEmpty) return null;
    return EvaluateTagItem(tagId: id, tagName: name);
  }

  static int? _intOf(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v.trim());
    return null;
  }
}

/// 评价提交参数校验 + body 组装（契约 §2 #16）。
/// iOS 参照：XYEvaluateViewModel.submitReview
/// （content trim 后长度须 > 5；body 含 currentUserId）。
class EvaluateSubmission {
  EvaluateSubmission._();

  /// 评价内容最少字数（trim 后须大于 5）
  static const int minContentLength = 5;

  /// 校验并组装提交 body；校验失败抛 [EvaluateSubmitException]（msg 供 Toast）。
  static Map<String, dynamic> buildBody({
    required String orderId,
    required String consultantId,
    required int rating,
    required String content,
    required List<int> tagIds,
    required String? currentUserId,
  }) {
    final orderIdInt = int.tryParse(orderId.trim());
    if (orderIdInt == null || orderIdInt <= 0) {
      throw const EvaluateSubmitException('订单信息无效');
    }
    final consultantIdInt = int.tryParse(consultantId.trim());
    if (consultantIdInt == null || consultantIdInt <= 0) {
      throw const EvaluateSubmitException('咨询师信息无效');
    }
    if (currentUserId == null || currentUserId.isEmpty) {
      throw const EvaluateSubmitException('请先登录');
    }
    final trimmed = content.trim();
    if (trimmed.length <= minContentLength) {
      throw const EvaluateSubmitException('补充评价内容需超过5个字');
    }
    if (tagIds.isEmpty) {
      throw const EvaluateSubmitException('请至少选择一个标签');
    }
    return {
      'orderId': orderIdInt,
      'consultantId': consultantIdInt,
      'rating': rating,
      'content': trimmed,
      'tagIds': tagIds,
      'currentUserId': currentUserId,
    };
  }
}

/// 评价提交校验异常（msg 供 Toast）。
class EvaluateSubmitException implements Exception {
  const EvaluateSubmitException(this.message);

  final String message;

  @override
  String toString() => message;
}
