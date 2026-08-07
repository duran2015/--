/// 咨询师端工作台数据模型（契约 §6 #30-37）。
/// iOS 参照：XYCounselorModule/XYCounselorModule/Classes/ViewModel/
/// XYCounselorWorkbenchViewModel.swift（XYCounselorSupportModeStyle /
/// XYCounselorPendingOrderItem / XYCounselorCompletedOrderItem /
/// XYCounselorHomeIndexData / XYCounselorWorkbenchOrderRow /
/// XYCounselorAppointmentTimeFormatter）、
/// XYCounselorAppointmentDetailViewModel.swift（XYCounselorOrderDetail）、
/// XYCounselorConsultRecordViewModel.swift（XYCounselorSummaryDetail）。
library;

import 'package:flutter/material.dart';

import '../../core/theme/app_assets.dart';
import '../../core/theme/app_colors.dart';
// 复用用户端咨询师模型的宽松解析辅助（asIntOrNull/asDoubleOrNull/
// asStringOrNull/asStringList）。
import '../consultant/consultant_models.dart';

/// 将逗号分隔主诉字符串拆成标签列表。
/// iOS 参照：XYCounselorOrderDetail.chiefComplaintTags /
/// XYCounselorWorkbenchOrderRow.chiefComplaintTags。
List<String> splitChiefComplaintTags(String? raw) {
  if (raw == null) return const [];
  return [
    for (final part in raw.split(','))
      if (part.trim().isNotEmpty) part.trim(),
  ];
}

// ---------------- 咨询方式三色徽标样式 ----------------

/// 咨询方式徽标样式（Figma 571:5777）。
/// iOS 参照：XYCounselorSupportModeStyle。
enum CounselorSupportMode {
  voice,
  video,
  text;

  /// 徽标展示文案
  String get title => switch (this) {
        CounselorSupportMode.voice => '语音',
        CounselorSupportMode.video => '视频',
        CounselorSupportMode.text => '文字',
      };

  /// 详情页完整咨询方式文案
  String get detailTitle => switch (this) {
        CounselorSupportMode.voice => '语音咨询',
        CounselorSupportMode.video => '视频咨询',
        CounselorSupportMode.text => '文字咨询',
      };

  /// 过往记录沟通方式文案
  String get historyTitle => switch (this) {
        CounselorSupportMode.voice => '语音沟通',
        CounselorSupportMode.video => '视频沟通',
        CounselorSupportMode.text => '文字沟通',
      };

  /// 徽标文字颜色（语音 #00A6A1 / 视频 #525EE1 / 文字 #52A8E1）
  Color get textColor => switch (this) {
        CounselorSupportMode.voice => AppColors.consultVoice,
        CounselorSupportMode.video => AppColors.consultVideo,
        CounselorSupportMode.text => AppColors.consultText,
      };

  /// 徽标渐变背景（右 → 左，与 Figma gradient-to-l 一致；
  /// Flutter LinearGradient 左→右，故数组逆序存放起始/结束）
  List<Color> get gradientColors => switch (this) {
        // 语音 #E9FFF8 → #E9FAFF
        CounselorSupportMode.voice =>
          const [Color(0xFFE9FAFF), AppColors.consultVoiceBg],
        // 视频 #F9F7FE → #F1ECFF
        CounselorSupportMode.video =>
          const [Color(0xFFF1ECFF), AppColors.consultVideoBg],
        // 文字 #F4F9FF → #EAF5FF
        CounselorSupportMode.text =>
          const [Color(0xFFEAF5FF), AppColors.consultTextBg],
      };

  /// 咨询方式图标资源（ic_method_*，原色切图不着色）
  String get iconAsset => switch (this) {
        CounselorSupportMode.text => AppAssets.icMethodText,
        CounselorSupportMode.voice => AppAssets.icMethodVoice,
        CounselorSupportMode.video => AppAssets.icMethodVideo,
      };

  /// 由接口编码或文案推导样式（"1" 文字 / "2" 语音 / "3" 视频）。
  /// iOS 参照：XYCounselorSupportModeStyle.resolve(mode:desc:)。
  static CounselorSupportMode resolve(String? mode, String? desc) {
    final combined = '${mode ?? ''} ${desc ?? ''}';
    if (combined.contains('视频') || mode == '3') {
      return CounselorSupportMode.video;
    }
    if (combined.contains('文字') || mode == '1') {
      return CounselorSupportMode.text;
    }
    return CounselorSupportMode.voice;
  }
}

// ---------------- 工作台首页（#31 /consultant/home/index） ----------------

/// 咨询师工作台首页数据。
/// iOS 参照：XYCounselorHomeIndexData（consultantInfo / tabCounts 嵌套容器
/// 多键兼容）；Android 参照：ConsultantHomeIndexData.kt。
class CounselorHomeIndex {
  const CounselorHomeIndex({
    this.avatar,
    this.name,
    this.title,
    this.satisfactionRate,
    this.satisfactionRateText,
    this.pendingCount,
    this.completedCount,
    this.unreadMessageCount,
    this.acceptanceRate,
  });

  /// 咨询师头像 URL
  final String? avatar;

  /// 咨询师姓名
  final String? name;

  /// 咨询师头衔
  final String? title;

  /// 用户满意度（数值型）
  final double? satisfactionRate;

  /// 用户满意度（字符串型，接口可能直接返回「暂无」等文案）
  final String? satisfactionRateText;

  /// 待服务数量（tabCounts.pendingCount）
  final int? pendingCount;

  /// 已咨询数量（tabCounts.completedCount）
  final int? completedCount;

  /// 未读消息数（tabCounts.unreadMessageCount，驱动消息 Tab 角标）
  final int? unreadMessageCount;

  /// 接单率（0~100，consultantInfo.acceptanceRate）
  final double? acceptanceRate;

  /// 多键取值辅助：在多个候选容器中按 key 列表取首个非 null
  static dynamic _pick(List<Map<String, dynamic>> containers, List<String> keys) {
    for (final c in containers) {
      for (final k in keys) {
        final v = c[k];
        if (v != null) return v;
      }
    }
    return null;
  }

  factory CounselorHomeIndex.fromJson(Map<String, dynamic> json) {
    // 嵌套容器（iOS：consultantInfo/consultant/consultantProfile/profile；
    // tabCounts/stats/statistics/overview 等）
    Map<String, dynamic> nested(List<String> keys) {
      for (final k in keys) {
        final v = json[k];
        if (v is Map) return Map<String, dynamic>.from(v);
      }
      return const {};
    }

    final consultant =
        nested(const ['consultantInfo', 'consultant', 'consultantProfile', 'profile']);
    final stats = nested(
        const ['tabCounts', 'tabCount', 'stats', 'statistics', 'statistic', 'overview']);
    final containers = [consultant, stats, json];

    // satisfactionRate 既可能是数值也可能是文案字符串
    final rawSatisfaction =
        _pick(containers, const ['satisfactionRate']);
    return CounselorHomeIndex(
      avatar: asStringOrNull(
          _pick(containers, const ['avatar', 'avatarUrl', 'headImg'])),
      name: asStringOrNull(_pick(
          containers, const ['name', 'consultantName', 'realName', 'nickName'])),
      title: asStringOrNull(_pick(
          containers, const ['title', 'consultantTitle', 'professionalTitle'])),
      satisfactionRate: asDoubleOrNull(rawSatisfaction),
      satisfactionRateText:
          rawSatisfaction is String ? rawSatisfaction : null,
      pendingCount: asIntOrNull(_pick([stats, json],
          const ['pendingCount', 'pendingServiceCount', 'waitServiceCount'])),
      completedCount:
          asIntOrNull(_pick([stats, json], const ['completedCount'])),
      unreadMessageCount:
          asIntOrNull(_pick([stats, json], const ['unreadMessageCount'])),
      acceptanceRate: asDoubleOrNull(_pick(containers,
          const ['acceptanceRate', 'acceptRate', 'orderAcceptRate'])),
    );
  }

  /// 用户评价文案（优先字符串，其次数值；空 → 暂无）。
  /// iOS 参照：XYCounselorWorkbenchViewModel.formatSatisfaction。
  String get satisfactionText {
    final text = satisfactionRateText?.trim();
    if (text != null && text.isNotEmpty && text.toLowerCase() != 'null') {
      return text;
    }
    final rate = satisfactionRate;
    if (rate == null) return '暂无';
    if (rate == rate.roundToDouble()) return '${rate.toInt()}';
    return rate.toStringAsFixed(1);
  }

  /// 待服务数量文案
  String get pendingText => '${pendingCount ?? 0}';

  /// 接单率文案（整数不带小数点，带 %）。
  /// iOS 参照：XYCounselorWorkbenchViewModel.formatAcceptRate。
  String get acceptRateText {
    final value = acceptanceRate;
    if (value == null) return '0%';
    if (value == value.roundToDouble()) return '${value.toInt()}%';
    return '${value.toStringAsFixed(1)}%';
  }
}

// ---------------- 工作台订单行（#32/#33 分页元素） ----------------

/// 工作台订单列表行（预约单 / 已咨询分页接口元素）。
/// iOS 参照：XYCounselorWorkbenchOrderRow（userInfo 嵌套 + 多键兼容）。
class CounselorWorkbenchOrderRow {
  const CounselorWorkbenchOrderRow({
    this.orderId,
    this.userName,
    this.userAvatar,
    this.imUserId,
    this.supportMode,
    this.supportModeDesc,
    this.roomId,
    this.roomName,
    this.appointmentStartTime,
    this.appointmentTime,
    this.appointmentEndTime,
    this.tags = const [],
    this.emotionSummary,
    this.problemSummary,
    this.hasSummary,
  });

  final int? orderId;
  final String? userName;
  final String? userAvatar;
  final String? imUserId;

  /// 服务方式编码（1 文字 / 2 语音 / 3 视频）
  final String? supportMode;

  /// 服务方式文案
  final String? supportModeDesc;

  /// 咨询室房间号（进入音视频会议用）
  final String? roomId;

  /// 咨询室名称（会议标题展示）
  final String? roomName;

  final String? appointmentStartTime;
  final String? appointmentTime;
  final String? appointmentEndTime;
  final List<String> tags;

  /// AI 情绪初判摘要（接口 preEmotionSummary）
  final String? emotionSummary;

  /// 问题摘要兜底（历史键 problemSummary 等；展示优先 emotionSummary）
  final String? problemSummary;

  /// 是否已写小结（true → 查看记录，false → 写小结与建议）
  final bool? hasSummary;

  factory CounselorWorkbenchOrderRow.fromJson(Map<String, dynamic> json) {
    final userInfo = json['userInfo'] is Map
        ? Map<String, dynamic>.from(json['userInfo'] as Map)
        : const <String, dynamic>{};

    String? firstString(Map<String, dynamic> m, List<String> keys) {
      for (final k in keys) {
        final v = m[k];
        if (v != null && v.toString().isNotEmpty) return v.toString();
      }
      return null;
    }

    // hasSummary：Bool 直返；兼容 summarySent / summaryStatus 文案
    bool? parseHasSummary() {
      final v = json['hasSummary'] ?? json['summarySent'];
      if (v is bool) return v;
      if (v is num) return v != 0;
      final status =
          asStringOrNull(json['summaryStatus'] ?? json['recordStatus']);
      if (status != null) {
        return status == '1' ||
            status.toLowerCase() == 'sent' ||
            status.toLowerCase() == 'done';
      }
      return null;
    }

    // 主诉标签：优先 preChiefComplaint（CSV），再回退数组字段
    final chiefComplaintTags =
        splitChiefComplaintTags(asStringOrNull(json['preChiefComplaint']));
    final fallbackTags = asStringList(json['tags'] ??
        json['specialtyTags'] ??
        json['styleTags'] ??
        json['issueTags'] ??
        json['demandTags'] ??
        json['labelList'] ??
        json['userTags']);

    return CounselorWorkbenchOrderRow(
      orderId: asIntOrNull(json['orderId'] ?? json['id']),
      userName: firstString(userInfo,
              const ['nickname', 'userName', 'nickName', 'realName']) ??
          firstString(json, const [
            'userName',
            'userNickName',
            'nickName',
            'nickname',
            'visitorName',
            'customerName',
            'customerNickName',
            'clientName',
            'realName',
          ]),
      userAvatar:
          firstString(userInfo, const ['avatar', 'avatarUrl', 'headImg']) ??
              firstString(json, const [
                'userAvatar',
                'avatar',
                'visitorAvatar',
                'customerAvatar',
                'headImg',
              ]),
      imUserId: firstString(userInfo, const ['imUserId']) ??
          firstString(json, const ['imUserId']),
      supportMode: firstString(
          json, const ['supportMode', 'consultMode', 'serviceMode']),
      supportModeDesc: firstString(json, const [
        'supportModeDesc',
        // 实测（2026-07-24 live）：后端实际返回 supportModeText
        // （「语音沟通」/「视频沟通」），契约中的 supportModeDesc 未出现。
        'supportModeText',
        'capabilityName',
        'serviceType',
        'serviceDesc',
        'serviceName',
      ]),
      roomId: firstString(json, const ['roomId', 'rtId', 'RtId', 'roomNo']),
      roomName:
          firstString(json, const ['roomName', 'roomTitle', 'meetingName']),
      appointmentStartTime: firstString(json, const [
        'appointmentStartTime',
        'startTime',
        'appointmentTime',
        'serviceTime',
        'orderTime',
      ]),
      appointmentTime: firstString(json,
          const ['appointmentTime', 'serviceTime', 'startTime', 'orderTime']),
      appointmentEndTime:
          firstString(json, const ['appointmentEndTime', 'endTime']),
      tags: chiefComplaintTags.isNotEmpty ? chiefComplaintTags : fallbackTags,
      emotionSummary: firstString(json, const ['preEmotionSummary']),
      problemSummary: firstString(json, const [
        'problemSummary',
        'issueSummary',
        'mainIssue',
        'issueDesc',
        'desc',
        'remark',
        'consultIssue',
        'userIssue',
        'issueDescription',
        'consultRemark',
      ]),
      hasSummary: parseHasSummary(),
    );
  }
}

// ---------------- 列表展示模型 ----------------

/// 预约单列表项展示数据。
/// iOS 参照：XYCounselorPendingOrderItem。
class CounselorPendingOrderItem {
  const CounselorPendingOrderItem({
    this.orderId,
    required this.timeText,
    required this.dayText,
    required this.userName,
    this.userAvatar,
    this.imUserId,
    required this.supportMode,
    this.tags = const [],
    this.emotionSummary = '',
    this.roomId,
    this.roomName,
  });

  final int? orderId;
  final String timeText;
  final String dayText;
  final String userName;
  final String? userAvatar;
  final String? imUserId;
  final CounselorSupportMode supportMode;
  final List<String> tags;

  /// AI 情绪初判摘要（iOS emotionSummary；preEmotionSummary ?? problemSummary）
  final String emotionSummary;
  final String? roomId;
  final String? roomName;

  /// 订单行 → 展示模型。
  /// iOS 参照：XYCounselorWorkbenchViewModel.pendingItem(from:)。
  factory CounselorPendingOrderItem.fromRow(CounselorWorkbenchOrderRow row) {
    final (time, day) = CounselorAppointmentTimeFormatter.timeDayText(
        row.appointmentStartTime ?? row.appointmentTime ?? '');
    final emotion = (row.emotionSummary?.trim().isNotEmpty ?? false)
        ? row.emotionSummary!.trim()
        : (row.problemSummary?.trim() ?? '');
    return CounselorPendingOrderItem(
      orderId: row.orderId,
      timeText: time,
      dayText: day,
      userName: (row.userName?.trim().isNotEmpty ?? false)
          ? row.userName!
          : '匿名用户',
      userAvatar: row.userAvatar,
      imUserId: row.imUserId,
      supportMode:
          CounselorSupportMode.resolve(row.supportMode, row.supportModeDesc),
      tags: row.tags,
      emotionSummary: emotion,
      roomId: row.roomId,
      roomName: row.roomName,
    );
  }
}

/// 已咨询列表项展示数据。
/// iOS 参照：XYCounselorCompletedOrderItem。
class CounselorCompletedOrderItem {
  const CounselorCompletedOrderItem({
    this.orderId,
    required this.timeText,
    required this.dayText,
    required this.userName,
    this.userAvatar,
    this.imUserId = '',
    required this.supportMode,
    this.tags = const [],
    this.hasSummary = false,
  });

  final int? orderId;
  final String timeText;
  final String dayText;
  final String userName;
  final String? userAvatar;
  final String imUserId;
  final CounselorSupportMode supportMode;
  final List<String> tags;
  final bool hasSummary;

  /// 订单行 → 展示模型。
  /// iOS 参照：XYCounselorWorkbenchViewModel.completedItem(from:)。
  factory CounselorCompletedOrderItem.fromRow(CounselorWorkbenchOrderRow row) {
    final (time, day) = CounselorAppointmentTimeFormatter.timeDayText(
        row.appointmentStartTime ?? row.appointmentTime ?? '');
    return CounselorCompletedOrderItem(
      orderId: row.orderId,
      timeText: time,
      dayText: day,
      userName: (row.userName?.trim().isNotEmpty ?? false)
          ? row.userName!
          : '匿名用户',
      userAvatar: row.userAvatar,
      imUserId: row.imUserId ?? '',
      supportMode:
          CounselorSupportMode.resolve(row.supportMode, row.supportModeDesc),
      tags: row.tags,
      hasSummary: row.hasSummary ?? false,
    );
  }
}

// ---------------- 预约单详情（#34 /consultant/home/orderDetail） ----------------

/// 过往咨询记录单条（#35 /consultant/home/pastConsultations 行同构）。
/// iOS 参照：XYCounselorOrderDetail.PastConsultation；
/// Android 参照：AppointmentOrderDetail.PastConsultation。
class CounselorPastConsultation {
  const CounselorPastConsultation({
    this.date,
    this.summary,
    this.supportMode,
    this.supportModeText,
  });

  /// 记录日期（"yyyy-MM-dd"）
  final String? date;

  /// 记录摘要
  final String? summary;

  /// 咨询方式码（"1" 文字 / "2" 语音 / "3" 视频）
  final String? supportMode;

  /// 咨询方式文案
  final String? supportModeText;

  factory CounselorPastConsultation.fromJson(Map<String, dynamic> json) {
    return CounselorPastConsultation(
      date: asStringOrNull(json['date']),
      summary: asStringOrNull(json['summary']),
      supportMode: asStringOrNull(json['supportMode']),
      supportModeText: asStringOrNull(json['supportModeText']),
    );
  }
}

/// 过往接待记录展示项。
/// iOS 参照：XYCounselorAppointmentHistoryItem。
class CounselorHistoryItem {
  const CounselorHistoryItem({
    required this.dateText,
    required this.modeText,
    required this.summary,
  });

  final String dateText;
  final String modeText;
  final String summary;

  /// 接口记录 → 展示项。
  /// iOS 参照：XYCounselorAppointmentDetailViewModel.mapHistoryItems。
  factory CounselorHistoryItem.fromRecord(CounselorPastConsultation record) {
    return CounselorHistoryItem(
      dateText: CounselorAppointmentTimeFormatter.historyDate(record.date),
      modeText: record.supportModeText?.trim() ?? '',
      summary: record.summary?.trim() ?? '',
    );
  }
}

/// 预约订单详情（/consultant/home/orderDetail 返回 data）。
/// iOS 参照：XYCounselorOrderDetail；Android 参照：AppointmentOrderDetail.kt。
class CounselorOrderDetail {
  const CounselorOrderDetail({
    this.aiEmotionSummary,
    this.appointmentTime,
    this.orderId,
    this.pastConsultationTotal,
    this.pastConsultations = const [],
    this.supportMode,
    this.supportModeText,
    this.tags = const [],
    this.userInfo,
  });

  /// AI 情绪初判摘要
  final String? aiEmotionSummary;

  /// 预约时间（"yyyy-MM-dd HH:mm:ss"）
  final String? appointmentTime;

  /// 订单 ID
  final int? orderId;

  /// 过往咨询总数
  final int? pastConsultationTotal;

  /// 过往咨询记录（预览，默认展示前 2 条）
  final List<CounselorPastConsultation> pastConsultations;

  /// 咨询方式码（"1" 文字 / "2" 语音 / "3" 视频）
  final String? supportMode;

  /// 咨询方式文案
  final String? supportModeText;

  /// 主诉标签
  final List<String> tags;

  /// 来访用户信息
  final CounselorOrderUserInfo? userInfo;

  factory CounselorOrderDetail.fromJson(Map<String, dynamic> json) {
    final chiefComplaintTags =
        splitChiefComplaintTags(asStringOrNull(json['preChiefComplaint']));
    final arrayTags = asStringList(json['tags']);
    return CounselorOrderDetail(
      // 决策（2026-07-24）：情绪摘要以 preEmotionSummary 为准；
      // aiEmotionSummary/aiSummary 作为历史键兜底兼容。
      aiEmotionSummary: asStringOrNull(json['preEmotionSummary'] ??
          json['aiEmotionSummary'] ??
          json['aiSummary']),
      appointmentTime: asStringOrNull(json['appointmentTime']),
      orderId: asIntOrNull(json['orderId']),
      pastConsultationTotal: asIntOrNull(json['pastConsultationTotal']),
      pastConsultations: [
        for (final e in (json['pastConsultations'] as List?) ?? const [])
          if (e is Map)
            CounselorPastConsultation.fromJson(Map<String, dynamic>.from(e)),
      ],
      supportMode: asStringOrNull(json['supportMode']),
      supportModeText: asStringOrNull(json['supportModeText']),
      // iOS：仅用 preChiefComplaint 拆标签；兼容历史 tags 数组
      tags: chiefComplaintTags.isNotEmpty ? chiefComplaintTags : arrayTags,
      userInfo: json['userInfo'] is Map
          ? CounselorOrderUserInfo.fromJson(
              Map<String, dynamic>.from(json['userInfo'] as Map))
          : null,
    );
  }
}

/// 来访用户信息。
/// iOS 参照：XYCounselorOrderDetail.UserInfo；
/// Android 参照：AppointmentOrderDetail.UserInfo（avatar 兼容 avatarUrl、
/// nickname 兼容 userName）。
class CounselorOrderUserInfo {
  const CounselorOrderUserInfo({
    this.age,
    this.avatar,
    this.imUserId,
    this.nickname,
    this.occupation,
    this.userId,
  });

  final int? age;
  final String? avatar;
  final String? imUserId;
  final String? nickname;
  final String? occupation;
  final int? userId;

  factory CounselorOrderUserInfo.fromJson(Map<String, dynamic> json) {
    return CounselorOrderUserInfo(
      age: asIntOrNull(json['age']),
      avatar: asStringOrNull(json['avatar'] ?? json['avatarUrl']),
      imUserId: asStringOrNull(json['imUserId']),
      nickname: asStringOrNull(json['nickname'] ?? json['userName']),
      occupation: asStringOrNull(json['occupation']),
      userId: asIntOrNull(json['userId']),
    );
  }
}

/// 预约详情页展示模型。
/// iOS 参照：XYCounselorAppointmentDetailItem。
class CounselorOrderDetailItem {
  const CounselorOrderDetailItem({
    this.orderId,
    required this.timeText,
    required this.dayText,
    required this.supportMode,
    required this.userName,
    this.userAvatar,
    this.userSubtitle = '',
    this.imUserId,
    this.userId,
    this.tags = const [],
    this.emotionSummary = '',
    this.historyRecords = const [],
    this.historyTotal = 0,
  });

  final int? orderId;
  final String timeText;
  final String dayText;
  final CounselorSupportMode supportMode;
  final String userName;
  final String? userAvatar;
  final String userSubtitle;
  final String? imUserId;
  final int? userId;
  final List<String> tags;
  final String emotionSummary;
  final List<CounselorHistoryItem> historyRecords;
  final int historyTotal;

  /// 接口详情 → 展示模型。
  /// iOS 参照：XYCounselorAppointmentDetailViewModel.applyOrderDetail。
  factory CounselorOrderDetailItem.fromDetail(
    CounselorOrderDetail detail, {
    int? fallbackOrderId,
  }) {
    final (timeText, dayText) = CounselorAppointmentTimeFormatter.timeDayText(
        detail.appointmentTime ?? '');

    final nickname = detail.userInfo?.nickname?.trim();
    final userName =
        (nickname != null && nickname.isNotEmpty) ? nickname : '匿名用户';

    final subtitleParts = <String>[
      if (detail.userInfo?.age != null) '${detail.userInfo!.age}岁',
      if ((detail.userInfo?.occupation?.trim().isNotEmpty ?? false))
        detail.userInfo!.occupation!.trim(),
    ];

    final imFromApi = detail.userInfo?.imUserId?.trim();

    final historyRecords = [
      for (final r in detail.pastConsultations)
        CounselorHistoryItem.fromRecord(r),
    ];

    return CounselorOrderDetailItem(
      orderId: detail.orderId ?? fallbackOrderId,
      timeText: timeText,
      dayText: dayText,
      supportMode: CounselorSupportMode.resolve(
          detail.supportMode, detail.supportModeText),
      userName: userName,
      userAvatar: detail.userInfo?.avatar,
      userSubtitle: subtitleParts.join(' · '),
      imUserId:
          (imFromApi != null && imFromApi.isNotEmpty) ? imFromApi : null,
      userId: detail.userInfo?.userId,
      tags: detail.tags,
      emotionSummary: detail.aiEmotionSummary?.trim() ?? '',
      historyRecords: historyRecords,
      historyTotal: detail.pastConsultationTotal ?? historyRecords.length,
    );
  }

  /// Figma 571:4833 静态示例数据（详情接口拉取前临时展示）。
  /// iOS 参照：XYCounselorAppointmentDetailItem.staticSample。
  factory CounselorOrderDetailItem.staticSample({
    int? orderId,
    String? imUserId,
    int? userId,
  }) {
    return CounselorOrderDetailItem(
      orderId: orderId,
      timeText: '14:00',
      dayText: '今天',
      supportMode: CounselorSupportMode.voice,
      userName: '陈小希',
      userSubtitle: '21岁 · 大学生',
      imUserId: imUserId,
      userId: userId,
      tags: const ['高敏焦虑', '考研压力', '近期失眠', '脆弱敏感', '近期失眠'],
      emotionSummary: '职业倦怠，情绪低落，近期压力较大',
      historyRecords: const [
        CounselorHistoryItem(
          dateText: '2026年05月20日',
          modeText: '文字沟通',
          summary: '很温柔，一团乱麻的情绪被一点点理清了，感觉自己又有了面对生活的力量，布置了呼吸作业。',
        ),
        CounselorHistoryItem(
          dateText: '2026年05月20日',
          modeText: '语音沟通',
          summary: '很温柔，一团乱麻的情绪被一点点理清了，感觉自己又有了面对生活的力量，布置了呼吸作业。',
        ),
      ],
      historyTotal: 12,
    );
  }
}

// ---------------- 小结详情（/consultant/summary/detail） ----------------

/// 咨询小结详情（/consultant/summary/detail 返回 data）。
/// iOS 参照：XYCounselorSummaryDetail（仅 AI 提取三段；
/// 小结正文与行动建议由咨询师自行填写，不预填）。
/// ⚠ Android 前端未见调用该接口（契约 §6），字段以 iOS 为准，待后端确认。
class CounselorSummaryDetail {
  const CounselorSummaryDetail({
    this.aiMainTopic,
    this.aiEmotionalState,
    this.aiCoreConflict,
  });

  /// 主要议题（AI 生成）
  final String? aiMainTopic;

  /// 情绪状态（AI 生成）
  final String? aiEmotionalState;

  /// 核心冲突（AI 生成）
  final String? aiCoreConflict;

  factory CounselorSummaryDetail.fromJson(Map<String, dynamic> json) {
    return CounselorSummaryDetail(
      aiMainTopic: asStringOrNull(json['aiMainTopic']),
      aiEmotionalState: asStringOrNull(json['aiEmotionalState']),
      aiCoreConflict: asStringOrNull(json['aiCoreConflict']),
    );
  }
}

// ---------------- 预约时间格式化 ----------------

/// 咨询师模块预约时间格式化工具（详情页与列表共用）。
/// iOS 参照：XYCounselorAppointmentTimeFormatter。
class CounselorAppointmentTimeFormatter {
  CounselorAppointmentTimeFormatter._();

  static String _two(int v) => v.toString().padLeft(2, '0');

  /// 解析后端预约时间字符串为时段 + 日期文案。
  /// 支持 ISO8601、`yyyy-MM-dd HH:mm:ss`、已含「今天/昨天/明天」等；
  /// 返回（时段 如 21:00，日期文案 如 今天 / 07-14）。
  static (String, String) timeDayText(String raw, {DateTime? now}) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return ('', '');
    if (trimmed.contains('今天') ||
        trimmed.contains('明天') ||
        trimmed.contains('昨天')) {
      return _splitEmbeddedDay(trimmed);
    }
    final date = parseDate(trimmed);
    if (date == null) return (trimmed, '');
    final current = now ?? DateTime.now();
    final timeText = '${_two(date.hour)}:${_two(date.minute)}';
    final today = DateTime(current.year, current.month, current.day);
    final day = DateTime(date.year, date.month, date.day);
    final String dayText;
    if (day == today) {
      dayText = '今天';
    } else if (day == today.subtract(const Duration(days: 1))) {
      dayText = '昨天';
    } else if (day == today.add(const Duration(days: 1))) {
      dayText = '明天';
    } else {
      dayText = '${_two(date.month)}-${_two(date.day)}';
    }
    return (timeText, dayText);
  }

  /// 历史记录日期文案（`yyyy-MM-dd` → `yyyy年MM月dd日`，解析失败返回原值）。
  /// iOS 参照：XYCounselorAppointmentTimeFormatter.historyDate。
  static String historyDate(String? raw) {
    final trimmed = raw?.trim() ?? '';
    if (trimmed.isEmpty) return '';
    final date = DateTime.tryParse(trimmed);
    if (date == null) return trimmed;
    return '${date.year}年${_two(date.month)}月${_two(date.day)}日';
  }

  /// 解析常见后端时间格式（含 ISO8601 与常见分隔符）。
  static DateTime? parseDate(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    // DateTime.tryParse 覆盖 ISO8601 与 "yyyy-MM-dd HH:mm(:ss)"
    final parsed = DateTime.tryParse(trimmed);
    if (parsed != null) return parsed;
    // 兼容 yyyy/MM/dd HH:mm(:ss)
    final normalized = trimmed.replaceAll('/', '-');
    return DateTime.tryParse(normalized);
  }

  /// 拆分已含「今天/昨天/明天」的预约文案
  static (String, String) _splitEmbeddedDay(String raw) {
    for (final day in const ['今天', '昨天', '明天']) {
      if (raw.contains(day)) {
        final timePart = raw.replaceAll(day, '').trim();
        return (timePart, day);
      }
    }
    return (raw, '');
  }
}
