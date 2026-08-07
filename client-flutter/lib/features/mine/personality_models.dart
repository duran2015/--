import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../consultant/consultant_models.dart';

/// 数字心理画像（/app/mine/profile 或 /consultant/home/userProfile data）。
/// iOS 参照：XYPersonality。
class PersonalityProfile {
  const PersonalityProfile({
    this.currentRisk,
    this.heartTraitScore,
    this.personalityTraits = const [],
    this.latestAssessment,
    this.latestAssessments = const [],
    this.psychologicalProfile,
    this.pastSummaries = const [],
    this.pastWarningRecords = const [],
    this.statusTrend = const [],
    this.userInfo,
  });

  final String? currentRisk;
  final int? heartTraitScore;
  final List<String> personalityTraits;
  final PersonalityAssessment? latestAssessment;
  final List<PersonalityAssessment> latestAssessments;
  final PersonalityPsychologicalProfile? psychologicalProfile;
  final List<PersonalityPastSummary> pastSummaries;
  final List<PersonalityPastWarning> pastWarningRecords;
  final List<PersonalityStatusPoint> statusTrend;
  final PersonalityUserInfo? userInfo;

  factory PersonalityProfile.fromJson(Map<String, dynamic> json) {
    return PersonalityProfile(
      currentRisk: asStringOrNull(json['currentRisk']),
      heartTraitScore: asIntOrNull(json['heartTraitScore']),
      personalityTraits: asStringList(json['personalityTraits']),
      latestAssessment: json['latestAssessment'] is Map
          ? PersonalityAssessment.fromJson(
              Map<String, dynamic>.from(json['latestAssessment'] as Map))
          : null,
      latestAssessments: [
        for (final e in (json['latestAssessments'] as List?) ?? const [])
          if (e is Map)
            PersonalityAssessment.fromJson(Map<String, dynamic>.from(e)),
      ],
      psychologicalProfile: json['psychologicalProfile'] is Map
          ? PersonalityPsychologicalProfile.fromJson(
              Map<String, dynamic>.from(json['psychologicalProfile'] as Map))
          : null,
      pastSummaries: [
        for (final e in (json['pastSummaries'] as List?) ?? const [])
          if (e is Map)
            PersonalityPastSummary.fromJson(Map<String, dynamic>.from(e)),
      ],
      pastWarningRecords: [
        for (final e in (json['pastWarningRecords'] as List?) ?? const [])
          if (e is Map)
            PersonalityPastWarning.fromJson(Map<String, dynamic>.from(e)),
      ],
      statusTrend: [
        for (final e in (json['statusTrend'] as List?) ?? const [])
          if (e is Map)
            PersonalityStatusPoint.fromJson(Map<String, dynamic>.from(e)),
      ],
      userInfo: json['userInfo'] is Map
          ? PersonalityUserInfo.fromJson(
              Map<String, dynamic>.from(json['userInfo'] as Map))
          : null,
    );
  }
}

class PersonalityAssessment {
  const PersonalityAssessment({this.date, this.score, this.type});

  final String? date;
  final int? score;
  final String? type;

  factory PersonalityAssessment.fromJson(Map<String, dynamic> json) {
    return PersonalityAssessment(
      date: asStringOrNull(json['date']),
      score: asIntOrNull(json['score']),
      type: asStringOrNull(json['type']),
    );
  }
}

class PersonalityPsychologicalProfile {
  const PersonalityPsychologicalProfile({
    this.basicProfile,
    this.scaleProfile,
    this.analysisSummary,
  });

  final String? basicProfile;
  final String? scaleProfile;
  final String? analysisSummary;

  factory PersonalityPsychologicalProfile.fromJson(Map<String, dynamic> json) {
    return PersonalityPsychologicalProfile(
      basicProfile: asStringOrNull(json['basicProfile']),
      scaleProfile: asStringOrNull(json['scaleProfile']),
      analysisSummary: asStringOrNull(json['analysisSummary']),
    );
  }
}

class PersonalityPastSummary {
  const PersonalityPastSummary({
    this.appointmentTime,
    this.createTime,
    this.content,
    this.supportModeText,
  });

  final String? appointmentTime;
  final String? createTime;
  final String? content;
  final String? supportModeText;

  factory PersonalityPastSummary.fromJson(Map<String, dynamic> json) {
    return PersonalityPastSummary(
      appointmentTime: asStringOrNull(json['appointmentTime']),
      createTime: asStringOrNull(json['createTime']),
      content: asStringOrNull(json['content']),
      supportModeText: asStringOrNull(json['supportModeText']),
    );
  }
}

class PersonalityPastWarning {
  const PersonalityPastWarning({
    this.crisisCreateTime,
    this.description,
    this.title,
  });

  final String? crisisCreateTime;
  final String? description;
  final String? title;

  factory PersonalityPastWarning.fromJson(Map<String, dynamic> json) {
    return PersonalityPastWarning(
      crisisCreateTime: asStringOrNull(json['crisisCreateTime']),
      description: asStringOrNull(json['description']),
      title: asStringOrNull(json['title']),
    );
  }
}

class PersonalityStatusPoint {
  const PersonalityStatusPoint({this.date, this.score});

  final String? date;
  final int? score;

  factory PersonalityStatusPoint.fromJson(Map<String, dynamic> json) {
    return PersonalityStatusPoint(
      date: asStringOrNull(json['date']),
      score: asIntOrNull(json['score']),
    );
  }
}

class PersonalityUserInfo {
  const PersonalityUserInfo({
    this.age,
    this.avatar,
    this.nickname,
    this.occupation,
    this.userId,
  });

  final int? age;
  final String? avatar;
  final String? nickname;
  final String? occupation;
  final int? userId;

  factory PersonalityUserInfo.fromJson(Map<String, dynamic> json) {
    return PersonalityUserInfo(
      age: asIntOrNull(json['age']),
      avatar: asStringOrNull(json['avatar'] ?? json['avatarUrl']),
      nickname: asStringOrNull(json['nickname'] ?? json['userName']),
      occupation: asStringOrNull(json['occupation']),
      userId: asIntOrNull(json['userId']),
    );
  }
}

/// 画像页展示模型（iOS XYPersonalityViewModel 计算属性）。
class PersonalityDisplay {
  const PersonalityDisplay({
    required this.nickName,
    required this.subtitle,
    this.avatarUrl,
    required this.currentRisk,
    required this.latestAssessment,
    required this.resilience,
    this.profileParagraphs = const [],
    this.traitTags = const [],
    this.trendScores = const [],
    this.trendLabels = const [],
    this.pastSummaries = const [],
    this.pastWarnings = const [],
  });

  final String nickName;
  final String subtitle;
  final String? avatarUrl;
  final String currentRisk;
  final String latestAssessment;
  final String resilience;
  final List<String> profileParagraphs;
  final List<String> traitTags;
  final List<int?> trendScores;
  final List<String> trendLabels;
  final List<({String date, String channel, String content})> pastSummaries;
  final List<({String title, String description, String date})> pastWarnings;

  /// 指标色（当前风险橙 / 近期测评靛 / 心理韧性青绿）
  static const riskColor = Color(0xFFFE5509);
  static const assessmentColor = AppColors.indigo;
  static const resilienceColor = AppColors.brandTeal;

  factory PersonalityDisplay.fromProfile(PersonalityProfile p) {
    final ageText = p.userInfo?.age != null ? '${p.userInfo!.age}岁' : null;
    final occupation = p.userInfo?.occupation?.trim();
    final subtitleParts = [
      if (ageText != null) ageText,
      if (occupation != null && occupation.isNotEmpty) occupation,
    ];

    final assessment = p.latestAssessment ??
        (p.latestAssessments.isNotEmpty ? p.latestAssessments.first : null);
    final type = assessment?.type?.trim();
    final latestAssessmentText =
        (type == null || type.isEmpty) ? '—' : '$type(${assessment?.score ?? 0})';

    final profile = p.psychologicalProfile;
    final paragraphs = [
      profile?.basicProfile,
      profile?.scaleProfile,
      profile?.analysisSummary,
    ]
        .map((e) => e?.trim() ?? '')
        .where((e) => e.isNotEmpty)
        .toList();

    return PersonalityDisplay(
      nickName: p.userInfo?.nickname?.trim() ?? '',
      subtitle: subtitleParts.isEmpty ? '—' : subtitleParts.join(' · '),
      avatarUrl: p.userInfo?.avatar,
      currentRisk: (p.currentRisk?.trim().isNotEmpty ?? false)
          ? p.currentRisk!.trim()
          : '—',
      latestAssessment: latestAssessmentText,
      resilience: p.heartTraitScore == null ? '—' : '${p.heartTraitScore}/100',
      profileParagraphs: paragraphs,
      traitTags: p.personalityTraits,
      trendScores: [for (final s in p.statusTrend) s.score],
      trendLabels: [for (final s in p.statusTrend) _shortDate(s.date)],
      pastSummaries: [
        for (final s in p.pastSummaries)
          (
            date: _shortDate(s.appointmentTime ?? s.createTime),
            channel: () {
              final c = s.supportModeText?.trim() ?? '';
              return c.isEmpty ? '咨询' : c;
            }(),
            content: s.content?.trim() ?? '',
          ),
      ],
      pastWarnings: [
        for (final w in p.pastWarningRecords)
          (
            title: w.title?.trim() ?? '',
            description: w.description?.trim() ?? '',
            date: _shortDate(w.crisisCreateTime),
          ),
      ],
    );
  }

  static String _shortDate(String? raw) {
    final t = raw?.trim() ?? '';
    if (t.length < 10) return t;
    final comps = t.substring(0, 10).split('-');
    if (comps.length < 3) return t.substring(0, 10);
    return '${comps[1]}-${comps[2]}';
  }
}
