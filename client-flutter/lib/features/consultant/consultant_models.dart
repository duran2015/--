/// 咨询师数据模型（契约 §2 #9-14）。
/// iOS 参照：XYAIModule/XYAIModule/Classes/ViewModel/XYConsultantModel.swift
/// （XYConsultant / XYConsultantDetail / XYConsultantCapability /
/// XYConsultantReviewStats / XYConsultantCertification /
/// XYConsultantAvailability / XYConsultantReview / XYConsultOrder 逐一对齐）。
library;

// ---------------- 兼容 Int / Double / String 的宽松解析 ----------------
// iOS 参照：XYConsultant.decodeInt / decodeDouble

int? asIntOrNull(dynamic v) {
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v.trim());
  return null;
}

double? asDoubleOrNull(dynamic v) {
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is String) return double.tryParse(v.trim());
  return null;
}

String? asStringOrNull(dynamic v) => v?.toString();

List<String> asStringList(dynamic v) =>
    (v as List?)?.map((e) => e.toString()).toList() ?? const [];

Map<String, dynamic> asMap(dynamic v) =>
    Map<String, dynamic>.from(v as Map? ?? const {});

/// 价格格式化：整数不带小数点（100.0 → "100"，100.5 → "100.5"）。
/// iOS 参照：XYConsultant.formatPrice。
String formatPrice(double value) =>
    value == value.roundToDouble() ? '${value.toInt()}' : '$value';

// ---------------- 日期格式化辅助 ----------------
// iOS 参照：XYCounselorDetailViewModel.weekdayText / shortDate

String _two(int v) => v.toString().padLeft(2, '0');

/// yyyy-MM-dd → MM/dd；解析失败回退原值
String shortDate(String? dateString) {
  if (dateString == null || dateString.isEmpty) return '';
  final d = DateTime.tryParse(dateString);
  if (d == null) return dateString;
  return '${_two(d.month)}/${_two(d.day)}';
}

/// yyyy-MM-dd → 今天/明天/后天/周X；解析失败返回「可约」
/// iOS 参照：XYCounselorDetailViewModel.weekdayText
String weekdayText(String? dateString) {
  final d = dateString == null ? null : DateTime.tryParse(dateString);
  if (d == null) return '可约';
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(d.year, d.month, d.day);
  final diff = day.difference(today).inDays;
  if (diff == 0) return '今天';
  if (diff == 1) return '明天';
  if (diff == 2) return '后天';
  const names = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
  return names[d.weekday - 1];
}

/// 评价时间格式化（yyyy-MM-dd HH:mm:ss → 今天/昨天/N天前，
/// 失败兜底 yyyy-MM-dd 或原值）。
/// iOS 参照：XYCounselorDetailViewController.reviewDateText
String reviewDateText(String? createTime) {
  if (createTime == null || createTime.isEmpty) return '';
  final d = DateTime.tryParse(createTime);
  if (d == null) return createTime;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(d.year, d.month, d.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return '今天';
  if (diff == 1) return '昨天';
  if (diff > 1) return '$diff天前';
  return '${d.year}-${_two(d.month)}-${_two(d.day)}';
}

/// HH:mm:ss（或 HH:mm）→ HH:mm
/// iOS 参照：XYAppointmentTimeSheetViewModel.shortTime
String shortTime(String? time) {
  if (time == null) return '';
  return time.length >= 5 ? time.substring(0, 5) : time;
}

/// HH:mm(:ss) → 当日分钟数（解析失败返回 null）
int? minutesOfDay(String? time) {
  if (time == null || time.isEmpty) return null;
  final parts = time.split(':');
  if (parts.length < 2) return null;
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null) return null;
  return h * 60 + m;
}

/// 由起止时间算分钟差（end<=start 视为异常返回 null）
int? minutesBetween(String? start, String? end) {
  final s = minutesOfDay(start);
  final e = minutesOfDay(end);
  if (s == null || e == null) return null;
  return e > s ? e - s : null;
}

// ---------------- 咨询师列表项 ----------------

/// 咨询师（对应后端 /app/consultant/list 行元素）。
/// iOS 参照：XYConsultant。
class Consultant {
  const Consultant({
    this.consultantId,
    this.realName,
    this.title,
    this.styleTags = const [],
    this.avatar,
    this.minPrice,
    this.ratingScore,
    this.serviceCount,
    this.totalServiceHours,
    this.specialtyTags = const [],
    this.evalTags = const [],
    this.experienceYears,
    this.status,
    this.nextAvailableTime,
    this.supportModes = const [],
    this.reviewCount,
    this.isVerified = false,
  });

  /// 咨询师业务 ID
  final int? consultantId;

  /// 真实姓名（列表展示名）
  final String? realName;

  /// 职称/头衔
  final String? title;

  /// 个人风格标签（标签行紫色底标签）
  final List<String> styleTags;

  /// 头像 URL（可能为空）
  final String? avatar;

  /// 起步价（元，如 100.0）
  final double? minPrice;

  /// 评分（如 5.0）
  final double? ratingScore;

  /// 服务计数（列表接口字段 serviceCount）
  final int? serviceCount;

  /// 服务总时长（小时；列表 cell「累计服务时长」取此字段。
  /// 兼容 totalServiceHours / serviceHours / totalHours 三个字段名）
  final int? totalServiceHours;

  /// 擅长标签
  final List<String> specialtyTags;

  /// 姓名旁评价标签（evalTags，如「专业咨询」）
  final List<String> evalTags;

  /// 从业年限
  final int? experienceYears;

  /// 状态（"1" 正常/在线）
  final String? status;

  /// 列表首屏决策字段：由列表接口直接返回，避免逐条请求详情。
  final String? nextAvailableTime;
  final List<String> supportModes;
  final int? reviewCount;
  final bool isVerified;

  factory Consultant.fromJson(Map<String, dynamic> json) {
    // iOS 参照：XYConsultant.init(from:) totalServiceHours 多字段名兼容
    final hours = asIntOrNull(json['totalServiceHours']) ??
        asIntOrNull(json['serviceHours']) ??
        asIntOrNull(json['totalHours']);
    return Consultant(
      consultantId: asIntOrNull(json['consultantId']),
      realName: asStringOrNull(json['realName']),
      title: asStringOrNull(json['title']),
      styleTags: asStringList(json['styleTags']),
      avatar: asStringOrNull(json['avatar']),
      minPrice: asDoubleOrNull(json['minPrice']),
      ratingScore: asDoubleOrNull(json['ratingScore']),
      serviceCount: asIntOrNull(json['serviceCount']),
      totalServiceHours: hours,
      specialtyTags: asStringList(json['specialtyTags']),
      evalTags: asStringList(json['evalTags']),
      experienceYears: asIntOrNull(json['experienceYears']),
      status: asStringOrNull(json['status']),
      nextAvailableTime: asStringOrNull(json['nextAvailableTime']),
      supportModes: asStringList(json['supportModes']),
      reviewCount: asIntOrNull(json['reviewCount']),
      isVerified: json['isVerified'] == true,
    );
  }

  // ---------- Cell 展示派生（iOS 参照：XYConsultant.cellDisplayData） ----------

  /// 展示名
  String get displayName => realName ?? '';

  /// 累计服务时长文案数值（>0 时为 "5200+"，否则 null 不展示）
  String? get serviceHoursText {
    final hours = totalServiceHours;
    if (hours == null || hours <= 0) return null;
    return '$hours+';
  }

  /// 起步价数值文案（formatPrice；null 不展示）
  String? get priceText => minPrice == null ? null : formatPrice(minPrice!);
}

// ---------------- 咨询能力 / 咨询方式 ----------------

/// 咨询师咨询能力/咨询方式（对应 data.capabilities[] 元素）。
/// iOS 参照：XYConsultantCapability。
class ConsultantCapability {
  const ConsultantCapability({
    this.capabilityId,
    this.capabilityName,
    this.description,
    this.duration,
    this.price,
    this.supportMode,
  });

  /// 能力 ID
  final int? capabilityId;

  /// 咨询方式名称（如「语音沟通」）
  final String? capabilityName;

  /// 咨询方式描述（可能为 null）
  final String? description;

  /// 单次时长（分钟）
  final int? duration;

  /// 单次价格（元）
  final double? price;

  /// 支持方式编码（约定：1 文字 / 2 语音 / 3 视频）
  final String? supportMode;

  factory ConsultantCapability.fromJson(Map<String, dynamic> json) {
    return ConsultantCapability(
      capabilityId: asIntOrNull(json['capabilityId']),
      capabilityName: asStringOrNull(json['capabilityName']),
      description: asStringOrNull(json['description']),
      duration: asIntOrNull(json['duration']),
      price: asDoubleOrNull(json['price']),
      supportMode: asStringOrNull(json['supportMode']),
    );
  }

  /// 展示名：优先 capabilityName，否则按 supportMode 映射，兜底「在线咨询」
  /// iOS 参照：XYConsultantCapability.displayName
  String get displayName {
    final name = capabilityName;
    if (name != null && name.isNotEmpty) return name;
    switch (supportMode) {
      case '1':
        return '文字咨询';
      case '2':
        return '语音咨询';
      case '3':
        return '视频咨询';
      default:
        return '在线咨询';
    }
  }
}

// ---------------- 评价统计 / 资质 / 可约时段 / 评价 ----------------

/// 咨询师评价统计（对应 data.reviewStats）。
/// iOS 参照：XYConsultantReviewStats。
class ConsultantReviewStats {
  const ConsultantReviewStats({this.avgStar, this.goodRate, this.totalCount});

  /// 平均星级
  final double? avgStar;

  /// 好评率（如 100.0）
  final double? goodRate;

  /// 评价总数
  final int? totalCount;

  factory ConsultantReviewStats.fromJson(Map<String, dynamic> json) {
    return ConsultantReviewStats(
      avgStar: asDoubleOrNull(json['avgStar']),
      goodRate: asDoubleOrNull(json['goodRate']),
      totalCount: asIntOrNull(json['totalCount']),
    );
  }
}

/// 咨询师认证资质（对应 data.certifications[] 元素）。
/// iOS 参照：XYConsultantCertification。
class ConsultantCertification {
  const ConsultantCertification({this.certName, this.issuingAuthority});

  /// 证书名称
  final String? certName;

  /// 发证机构
  final String? issuingAuthority;

  factory ConsultantCertification.fromJson(Map<String, dynamic> json) {
    return ConsultantCertification(
      certName: asStringOrNull(json['certName']),
      issuingAuthority: asStringOrNull(json['issuingAuthority']),
    );
  }
}

/// 咨询师可约时段（对应 data.recentAvailability[] 元素）。
/// iOS 参照：XYConsultantAvailability。
class ConsultantAvailability {
  const ConsultantAvailability({
    this.availabilityId,
    this.availableDate,
    this.startTime,
    this.endTime,
    this.isBooked,
  });

  /// 时段 ID
  final int? availabilityId;

  /// 可约日期（yyyy-MM-dd）
  final String? availableDate;

  /// 开始时间（HH:mm:ss）
  final String? startTime;

  /// 结束时间（HH:mm:ss）
  final String? endTime;

  /// 是否已被预约（"0" 未约）
  final String? isBooked;

  factory ConsultantAvailability.fromJson(Map<String, dynamic> json) {
    return ConsultantAvailability(
      availabilityId: asIntOrNull(json['availabilityId']),
      availableDate: asStringOrNull(json['availableDate']),
      startTime: asStringOrNull(json['startTime']),
      endTime: asStringOrNull(json['endTime']),
      isBooked: asStringOrNull(json['isBooked']),
    );
  }
}

/// 咨询师评价明细（对应 data.reviews[] / 评价列表 rows[] 元素）。
/// iOS 参照：XYConsultantReview。
class ConsultantReview {
  const ConsultantReview({
    this.reviewId,
    this.userNickName,
    this.userAvatar,
    this.content,
    this.rating,
    this.createTime,
    this.isAnonymous,
    this.tagNames = const [],
  });

  /// 评价 ID
  final int? reviewId;

  /// 用户昵称（空时页面显示「匿名用户」）
  final String? userNickName;

  /// 用户头像 URL（空时页面显示匿名头像）
  final String? userAvatar;

  /// 评价正文
  final String? content;

  /// 评分（1~5）
  final int? rating;

  /// 评价时间（yyyy-MM-dd HH:mm:ss）
  final String? createTime;

  /// 是否匿名（"1" 匿名）
  final String? isAnonymous;

  /// 来访者给咨询师打的标签（用于「Ta认为咨询师」chip）
  final List<String> tagNames;

  factory ConsultantReview.fromJson(Map<String, dynamic> json) {
    return ConsultantReview(
      reviewId: asIntOrNull(json['reviewId']),
      userNickName: asStringOrNull(json['userNickName']),
      userAvatar: asStringOrNull(json['userAvatar']),
      content: asStringOrNull(json['content']),
      rating: asIntOrNull(json['rating']),
      createTime: asStringOrNull(json['createTime']),
      isAnonymous: asStringOrNull(json['isAnonymous']),
      tagNames: asStringList(json['tagNames']),
    );
  }

  /// 展示昵称：有昵称用昵称，否则「匿名用户」
  String get displayNickName {
    final name = userNickName;
    if (name != null && name.isNotEmpty) return name;
    return '匿名用户';
  }

  /// 是否有头像 URL
  bool get hasAvatar => userAvatar != null && userAvatar!.isNotEmpty;
}

// ---------------- 咨询师详情 ----------------

/// 咨询师详情数据模型（对应后端 /app/consultant/detail 返回字段）。
/// iOS 参照：XYConsultantDetail。
class ConsultantDetail {
  const ConsultantDetail({
    this.consultantId,
    this.realName,
    this.title,
    this.avatar,
    this.introduction,
    this.ratingScore,
    this.serviceCount,
    this.totalServiceHours,
    this.experienceYears,
    this.status,
    this.capabilities = const [],
    this.reviewStats,
    this.certifications = const [],
    this.isVerified,
    this.recentAvailability = const [],
    this.reviews = const [],
    this.imUserId,
    this.specialtyTags = const [],
    this.styleTags = const [],
  });

  /// 咨询师业务 ID
  final int? consultantId;

  /// 真实姓名
  final String? realName;

  /// 职称/头衔
  final String? title;

  /// 头像 URL（远程）
  final String? avatar;

  /// 个人简介（可能为空串）
  final String? introduction;

  /// 评分
  final double? ratingScore;

  /// 服务次数
  final int? serviceCount;

  /// 服务总时长（小时）
  final int? totalServiceHours;

  /// 从业年限
  final int? experienceYears;

  /// 状态（"1" 正常/在线）
  final String? status;

  /// 咨询方式列表（价格/时长/方式均从此取）
  final List<ConsultantCapability> capabilities;

  /// 评价统计
  final ConsultantReviewStats? reviewStats;

  /// 认证资质列表
  final List<ConsultantCertification> certifications;

  /// 是否官方认证
  final bool? isVerified;

  /// 最近可约时段列表
  final List<ConsultantAvailability> recentAvailability;

  /// 评价明细列表（可能为空）
  final List<ConsultantReview> reviews;

  /// 咨询师 IM 用户 ID（预约/聊天使用）
  final String? imUserId;

  /// 擅长标签
  final List<String> specialtyTags;

  /// 风格标签
  final List<String> styleTags;

  factory ConsultantDetail.fromJson(Map<String, dynamic> json) {
    List<T> parseList<T>(String key, T Function(Map<String, dynamic>) decode) {
      return (json[key] as List?)?.map((e) => decode(asMap(e))).toList() ??
          const [];
    }

    return ConsultantDetail(
      consultantId: asIntOrNull(json['consultantId']),
      realName: asStringOrNull(json['realName']),
      title: asStringOrNull(json['title']),
      avatar: asStringOrNull(json['avatar']),
      introduction: asStringOrNull(json['introduction']),
      ratingScore: asDoubleOrNull(json['ratingScore']),
      serviceCount: asIntOrNull(json['serviceCount']),
      totalServiceHours: asIntOrNull(json['totalServiceHours']) ??
          asIntOrNull(json['serviceHours']) ??
          asIntOrNull(json['totalHours']),
      experienceYears: asIntOrNull(json['experienceYears']),
      status: asStringOrNull(json['status']),
      capabilities: parseList('capabilities', ConsultantCapability.fromJson),
      reviewStats: json['reviewStats'] == null
          ? null
          : ConsultantReviewStats.fromJson(asMap(json['reviewStats'])),
      certifications:
          parseList('certifications', ConsultantCertification.fromJson),
      isVerified: json['isVerified'] as bool?,
      recentAvailability:
          parseList('recentAvailability', ConsultantAvailability.fromJson),
      reviews: parseList('reviews', ConsultantReview.fromJson),
      imUserId: asStringOrNull(json['imUserId']),
      specialtyTags: asStringList(json['specialtyTags']),
      styleTags: asStringList(json['styleTags']),
    );
  }
}

// ---------------- 咨询订单 ----------------

/// 咨询订单（/app/consultant/book 返回；字段对齐 iOS XYConsultOrder，
/// 本阶段仅使用 orderId / price / paymentDeadline 等少数字段）。
class ConsultOrder {
  const ConsultOrder({
    this.orderId,
    this.orderNo,
    this.payStatus,
    this.paymentDeadline,
    this.price,
    this.duration,
    this.appointmentStartTime,
    this.appointmentEndTime,
    this.consultantId,
    this.consultantName,
    this.consultantTitle,
    this.consultantAvatar,
    this.capabilityName,
    this.supportMode,
    this.status,
    this.statusDesc,
    this.createTime,
  });

  /// 订单 ID（mock 阶段为字符串 "mock_order_1001"，统一按字符串解析）
  final String? orderId;

  /// 订单号
  final String? orderNo;

  /// 支付状态（0 未支付）
  final String? payStatus;

  /// 支付截止时间
  final String? paymentDeadline;

  /// 支付金额（元）
  final double? price;

  /// 咨询时长（分钟）
  final int? duration;

  /// 预约开始时间
  final String? appointmentStartTime;

  /// 预约结束时间
  final String? appointmentEndTime;

  /// 咨询师业务 ID
  final int? consultantId;

  /// 咨询师姓名
  final String? consultantName;

  /// 咨询师职称
  final String? consultantTitle;

  /// 咨询师头像 URL
  final String? consultantAvatar;

  /// 咨询方式名称
  final String? capabilityName;

  /// 支持方式编码（1 文字 / 2 语音 / 3 视频）
  final String? supportMode;

  /// 订单状态
  final String? status;

  /// 订单状态文案（待接单 等）
  final String? statusDesc;

  /// 创建时间
  final String? createTime;

  factory ConsultOrder.fromJson(Map<String, dynamic> json) {
    return ConsultOrder(
      orderId: asStringOrNull(json['orderId']),
      orderNo: asStringOrNull(json['orderNo']),
      payStatus: asStringOrNull(json['payStatus']),
      paymentDeadline: asStringOrNull(json['paymentDeadline']),
      price: asDoubleOrNull(json['price']),
      duration: asIntOrNull(json['duration']),
      appointmentStartTime: asStringOrNull(json['appointmentStartTime']),
      appointmentEndTime: asStringOrNull(json['appointmentEndTime']),
      consultantId: asIntOrNull(json['consultantId']),
      consultantName: asStringOrNull(json['consultantName']),
      consultantTitle: asStringOrNull(json['consultantTitle']),
      consultantAvatar: asStringOrNull(json['consultantAvatar']),
      capabilityName: asStringOrNull(json['capabilityName']),
      supportMode: asStringOrNull(json['supportMode']),
      status: asStringOrNull(json['status']),
      statusDesc: asStringOrNull(json['statusDesc']),
      createTime: asStringOrNull(json['createTime']),
    );
  }
}
