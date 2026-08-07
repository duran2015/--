// 举报 / 拉黑模型。
// iOS 参照：XYReportViewModel.ReportReason / TargetType.

import '../consultant/consultant_models.dart';

/// 举报理由（来自 POST /app/report/reasons）
class ReportReason {
  const ReportReason({required this.code, required this.label});

  /// 类型编码（提交举报时原样回传）
  final String code;

  /// 类型展示文案
  final String label;

  factory ReportReason.fromJson(Map<String, dynamic> json) {
    return ReportReason(
      code: '${json['code'] ?? ''}',
      label: '${json['label'] ?? ''}',
    );
  }
}

/// 举报对象类型（POST /app/report/submit 的 targetType）
enum ReportTargetType {
  /// 聊天（targetId = 对方 IM userID）
  chat('chat_msg'),

  /// 评价（targetId = reviewId）
  review('review'),

  /// 咨询师（targetId = 咨询师业务 ID）
  consultant('consultant'),

  /// 用户（咨询师端举报来访用户，targetId = userId）
  user('user');

  const ReportTargetType(this.rawValue);
  final String rawValue;
}

// ---------------- 黑名单列表（POST /app/block/list） ----------------

String? _firstString(Map<String, dynamic> json, List<String> keys) {
  for (final k in keys) {
    final v = json[k];
    if (v != null) return v.toString();
  }
  return null;
}

int? _firstInt(Map<String, dynamic> json, List<String> keys) {
  for (final k in keys) {
    final v = asIntOrNull(json[k]);
    if (v != null) return v;
  }
  return null;
}

/// `/app/block/list` 分页列表单行（接口原始字段，兼容多种后端命名）。
/// 对应 `/app/block/add` 写入的后端拉黑留档记录。
class BlockedUserRow {
  const BlockedUserRow({
    this.blockId,
    this.blockedUserId,
    this.nickname,
    this.avatar,
    this.userType,
    this.phonenumber,
    this.imUserId,
    this.createTime,
  });

  /// 拉黑记录 ID
  final int? blockId;

  /// 被拉黑用户业务 ID（用户端拉黑咨询师时即咨询师 id）
  final int? blockedUserId;

  /// 被拉黑用户昵称
  final String? nickname;

  /// 被拉黑用户头像 URL
  final String? avatar;

  /// 用户类型编码（见 [BlockedUserItem._userTypeLabel]）
  final String? userType;

  /// 手机号
  final String? phonenumber;

  /// 被拉黑用户 IM userID（IM 解除拉黑用；幂等）
  final String? imUserId;

  /// 拉黑时间（接口原样字符串，如 "2026-07-31 10:00:00"）
  final String? createTime;

  factory BlockedUserRow.fromJson(Map<String, dynamic> json) {
    return BlockedUserRow(
      blockId: _firstInt(json, const ['blockId', 'blockID']),
      blockedUserId: _firstInt(json, const ['blockedUserId', 'userId']),
      nickname: _firstString(json, const ['nickname', 'nickName', 'name']),
      avatar: _firstString(json, const ['avatar', 'avatarUrl', 'faceUrl']),
      userType: _firstString(json, const ['userType']),
      phonenumber: _firstString(json, const ['phonenumber', 'phone', 'mobile']),
      imUserId: _firstString(json, const ['imUserId', 'imUserID', 'userId']),
      createTime: _firstString(json, const ['createTime', 'blockTime']),
    );
  }
}

/// 黑名单列表展示模型。
class BlockedUserItem {
  const BlockedUserItem({
    required this.blockId,
    required this.blockedUserId,
    required this.displayName,
    required this.avatar,
    required this.userTypeLabel,
    required this.phonenumber,
    required this.imUserId,
    required this.createTime,
  });

  final int? blockId;
  final int? blockedUserId;
  final String displayName;
  final String? avatar;
  final String userTypeLabel;
  final String? phonenumber;

  /// 被拉黑用户 IM userID（解除拉黑时传给 IM 层）
  final String? imUserId;

  final String? createTime;

  /// userType → 身份标签。
  /// 注：按 RuoYi 惯例假设 "1"=用户、"2"=咨询师；若后端定义不同请调整此处。
  static String _userTypeLabel(String? userType) {
    switch (userType) {
      case '1':
        return '用户';
      case '2':
        return '咨询师';
      default:
        return '';
    }
  }

  factory BlockedUserItem.fromRow(BlockedUserRow row) {
    final nick = row.nickname?.trim();
    final name = (nick != null && nick.isNotEmpty)
        ? nick
        : (row.blockedUserId != null ? 'ID: ${row.blockedUserId}' : '');
    return BlockedUserItem(
      blockId: row.blockId,
      blockedUserId: row.blockedUserId,
      displayName: name,
      avatar: row.avatar,
      userTypeLabel: _userTypeLabel(row.userType),
      phonenumber: row.phonenumber,
      imUserId: row.imUserId,
      createTime: row.createTime,
    );
  }
}
