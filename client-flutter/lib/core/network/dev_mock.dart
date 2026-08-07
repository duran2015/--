import 'package:xinyu_flutter/defines/constants.dart';

import 'api_client.dart';

/// mock 微信授权 code：已绑定场景（wechatLogin 直接返回登录态）。
const String mockWechatBoundCode = 'mock_dev_code';

/// mock 微信授权 code：未绑定场景（wechatLogin 返回 needBindPhone=true +
/// preAuthToken/nickName/avatar），用于走通微信绑定手机号页。
/// 触发方式：`MockWechatAuthService.debugNextCode = mockWechatUnboundCode;`
const String mockWechatUnboundCode = 'mock_unbind';

/// mock 微信绑定临时凭证（契约 §1 #3 preAuthToken）。
const String mockWechatPreAuthToken = 'mock_pre_auth_token';

/// mock Apple identityToken：已绑定场景（appleLogin 直接返回登录态）。
const String mockAppleBoundToken = 'mock_apple_token';

/// mock Apple identityToken：未绑定场景（appleLogin 返回 needBindPhone=true）。
/// 触发方式：`MockAppleAuthService.debugNextToken = mockAppleUnboundToken;`
const String mockAppleUnboundToken = 'mock_apple_unbind';

/// mock Apple 绑定临时凭证（与微信共用 bindPhoneLogin）。
const String mockApplePreAuthToken = 'mock_apple_pre_auth_token';

/// 登录态 data 构造（契约 §1 #1 LoginData）。
/// 供 loginByPhone / wechatLogin / bindPhoneLogin 等 mock 接口与
/// splash 的 DEV_AUTO_LOGIN 调试自动登录复用。
Map<String, dynamic> devMockLoginData(String phone, {required bool dual}) => {
      'access_token': dual ? 'mock_token_dual' : 'mock_token_single',
      'imUserId': 'xy_mock_1001',
      'imUserSig': 'mock_user_sig_1001',
      'availableIdentities':
          dual ? const ['user', 'consultant'] : const ['user'],
      'currentIdentity': dual ? null : 'user',
      'consultantId': dual ? 'mock_consultant_1001' : null,
      'expires_in': 7200,
      'phone': phone,
      'nickName': 'Mock用户',
      'userId': '1001',
      'avatar': null,
    };

/// DEV 接口 mock（契约 §1 #1-#8，登录/协议链路）。
///
/// 生效条件：显式 `--dart-define=API_ENV=mock`
///（默认 live，见 api_env.dart），由 main.dart 自动调用本方法；
/// Debug 与 Release 演示包使用相同的 Mock 数据
///（内部置 `ApiClient.useMock=true`）。单测可直接调用本方法。
///
/// 特殊手机号：
/// - `13800000002` → loginByPhone 返回双身份（availableIdentities 两个，
///   currentIdentity 为空），登录后进入身份选择页；
/// - 其他任意合法手机号 → 单身份 user，直接进 /home。
///
/// 特殊微信 code（MockWechatAuthService 返回，见 wechat_auth_service.dart）：
/// - [mockWechatBoundCode] → 已绑定，直接登录进主端；
/// - [mockWechatUnboundCode] → 未绑定，跳绑定手机号页（preAuthToken 见
///   [mockWechatPreAuthToken]）。
///
/// 特殊 Apple identityToken（MockAppleAuthService 返回，见 apple_auth_service.dart）：
/// - [mockAppleBoundToken] → 已绑定，直接登录进主端；
/// - [mockAppleUnboundToken] → 未绑定，跳绑定手机号页。
void registerDevMocks() {
  ApiClient.useMock = true;

  Map<String, dynamic> ok({Map<String, dynamic>? data, String msg = '操作成功'}) =>
      {'code': 200, 'msg': msg, if (data != null) 'data': data};

  // #2 发送验证码（登录场景免鉴权；注销场景 scene != null）
  ApiClient.registerMock('/app/auth/sendSmsCode', (body) {
    return ok(msg: '验证码已发送');
  });

  // #1 手机号验证码登录
  ApiClient.registerMock('/app/auth/loginByPhone', (body) {
    final phone = body['phone']?.toString() ?? '';
    final code = body['smsCode']?.toString() ?? '';
    if (code.length != 6) {
      return {'code': 500, 'msg': '验证码错误'};
    }
    return ok(data: devMockLoginData(phone, dual: phone == '13800000002'));
  });

  // #3 微信登录：mock_unbind → 未绑定（走绑定页）；其他 code → 已绑定直接登录
  ApiClient.registerMock('/app/auth/wechatLogin', (body) {
    final code = body['code']?.toString() ?? '';
    if (code == mockWechatUnboundCode) {
      return ok(data: {
        'needBindPhone': true,
        'preAuthToken': mockWechatPreAuthToken,
        'nickName': '微信Mock用户',
        'avatar': null,
      });
    }
    return ok(data: {
      'needBindPhone': false,
      ...devMockLoginData('13800000000', dual: false),
    });
  });

  // Apple 登录（对齐 iOS /app/auth/appleLogin；响应形态同微信）
  ApiClient.registerMock('/app/auth/appleLogin', (body) {
    final token = body['identityToken']?.toString() ?? '';
    if (token == mockAppleUnboundToken) {
      return ok(data: {
        'needBindPhone': true,
        'preAuthToken': mockApplePreAuthToken,
        'nickName': body['nickName']?.toString() ?? 'AppleMock用户',
        'avatar': null,
      });
    }
    return ok(data: {
      'needBindPhone': false,
      ...devMockLoginData('13800000000', dual: false),
    });
  });

  // #4 微信/Apple 绑定手机号（契约：preAuthToken + phone + smsCode → LoginData）
  ApiClient.registerMock('/app/auth/bindPhoneLogin', (body) {
    final phone = body['phone']?.toString() ?? '';
    final code = body['smsCode']?.toString() ?? '';
    final preAuthToken = body['preAuthToken']?.toString() ?? '';
    if (preAuthToken.isEmpty) {
      return {'code': 500, 'msg': '绑定凭证已失效，请重新登录'};
    }
    if (code.length != 6) {
      return {'code': 500, 'msg': '验证码错误'};
    }
    return ok(data: devMockLoginData(phone, dual: false));
  });

  // #5 选择身份：返回新 currentIdentity / availableIdentities /
  // consultantId / imUserId / imUserSig（契约 §1 #5 全量刷新）
  ApiClient.registerMock('/app/auth/selectIdentity', (body) {
    final identity = body['identity']?.toString() ?? 'user';
    return ok(data: {
      'currentIdentity': identity,
      'availableIdentities': const ['user', 'consultant'],
      'consultantId': 'mock_consultant_1001',
      'imUserId': 'xy_mock_1001',
      'imUserSig': 'mock_user_sig_1001_switched',
    });
  });

  // #6 登出
  ApiClient.registerMock('/app/auth/logout', (body) => ok(msg: '登出成功'));

  // #7 最新协议链接与版本
  ApiClient.registerMock('/app/agreement/latest', (body) {
    return ok(data: {
      'user': {
        'url': LyConfig.userAgreement,
        'version': '1.0.0',
      },
      'privacy': {
        'url': LyConfig.privacyPolicy,
        'version': '1.0.0',
      },
    });
  });

  // #8 协议同意上报
  ApiClient.registerMock('/app/agreement/consent', (body) => ok());

  // ----------------------------------------------------------------------
  // 阶段 2：首页心情（契约 §5 #26-28）+ 测评列表（契约 §3 #17）
  // ----------------------------------------------------------------------

  String two(int v) => v.toString().padLeft(2, '0');
  String dateKeyOf(DateTime d) => '${d.year}-${two(d.month)}-${two(d.day)}';

  /// 本阶段提交的心情记录（内存态，驱动 trend/calendar 演示闭环）
  final moodStore = <String, Map<String, dynamic>>{};

  Map<String, dynamic> moodItem(
    String dateKey,
    int score, {
    String? note,
    String? tags,
  }) =>
      {
        'trendId': dateKey.hashCode.abs() % 100000,
        'userId': 1001,
        'recordDate': '$dateKey 10:00:00',
        'moodScore': score,
        'moodTags': tags,
        'moodIcon': null,
        'note': note,
        'createTime': '$dateKey 10:00:00',
      };

  // #26 提交心情：写入内存态，返回成功 msg（iOS 取 msg 文案 Toast）
  ApiClient.registerMock('/app/user/mood', (body) {
    final recordDate = body['recordDate']?.toString() ?? '';
    final key = recordDate.length >= 10 ? recordDate.substring(0, 10) : '';
    if (key.isNotEmpty) {
      moodStore[key] = moodItem(
        key,
        (body['moodScore'] as num?)?.toInt() ?? 3,
        note: body['note']?.toString(),
      );
    }
    return ok(msg: '记录成功');
  });

  // #28 情绪趋势：近 7 天内固定 2 条历史记录（不含今天，保证「记录」入口可演示）
  // + 本阶段提交的记录
  ApiClient.registerMock('/app/user/mood/trend', (body) {
    final now = DateTime.now();
    final data = <Map<String, dynamic>>[
      moodItem(dateKeyOf(now.subtract(const Duration(days: 3))), 5, note: '超棒'),
      moodItem(dateKeyOf(now.subtract(const Duration(days: 1))), 4, note: '还行'),
    ];
    moodStore.forEach((key, value) {
      final date = DateTime.tryParse(key);
      if (date == null) return;
      final diff = DateTime(now.year, now.month, now.day)
          .difference(DateTime(date.year, date.month, date.day))
          .inDays;
      if (diff >= 0 && diff < 7) data.add(value);
    });
    return {'code': 200, 'msg': '操作成功', 'data': data};
  });

  // #27 情绪月历：任意请求月份返回 3 条确定性记录（3 号还行 / 8 号超棒 /
  // 13 号不爽，28 天及以上的月份均合法）+ 本阶段提交的当月记录
  ApiClient.registerMock('/app/user/mood/calendar', (body) {
    final year = (body['year'] as num?)?.toInt() ?? DateTime.now().year;
    final month = (body['month'] as num?)?.toInt() ?? DateTime.now().month;
    String key(int day) => '$year-${two(month)}-${two(day)}';
    final data = <Map<String, dynamic>>[
      moodItem(key(3), 4),
      moodItem(key(8), 5),
      moodItem(key(13), 2),
    ];
    moodStore.forEach((k, value) {
      final date = DateTime.tryParse(k);
      if (date != null && date.year == year && date.month == month) {
        data.add(value);
      }
    });
    return {'code': 200, 'msg': '操作成功', 'data': data};
  });

  // #19 测评报告详情（assessmentId = userAssessId）：完整报告假数据，
  // 字段对齐 XYHomeAssessmentDetail（assessDate/totalScore/level/
  // interpretation/symptomTags/suggestions/sourceUrl）
  ApiClient.registerMock('/app/assessment/detail', (body) {
    return ok(data: {
      'assessDate': dateKeyOf(DateTime.now()),
      'totalScore': 8,
      'level': '轻度抑郁倾向',
      'interpretation':
          '根据您的得分情况，您目前存在一定程度的轻度抑郁。这可能与近期生活压力、学业压力或人际关系变化有关。这种状态比较常见，不必过度恐慌，但建议开始关注并进行适当的自我调节。',
      'symptomTags': ['轻度情绪失落', '睡眠困扰'],
      'suggestions': [
        '保持规律作息，尽量保证每天7-8小时的高质量睡眠。',
        '可以尝试应用内的“呼吸引导”或“正念冥想”工具来放松身心。',
        '若负面情绪持续超过两周且影响正常生活，建议预约专业咨询师进行沟通。',
      ],
      'sourceUrl': 'https://www.cxmed.cn/ms/preview_297.html',
    });
  });

  // #17 测评问卷列表（category=clinical）：4 项，backgroundImage/icon 为空
  // → 页面走 AppAssets 本地占位图（sds/sas/mbti/gad7）
  ApiClient.registerMock('/app/assessment/list', (body) {
    return {
      'code': 200,
      'msg': '操作成功',
      'data': [
        {
          'questionnaireId': 1,
          'questionnaireKey': 'sds',
          'name': '抑郁自评量表(SDS)',
          'description': '评估近一周抑郁情绪状态',
          'questionCount': 20,
          'testedCount': 12345,
          'sortOrder': 1,
          'category': 'clinical',
          'h5Link': 'https://admin.currantmind.cn/assessment/sds.html',
          'backgroundImage': null,
          'icon': null,
          'userAssessStatus': '1',
          'userAssessId': 101,
        },
        {
          'questionnaireId': 2,
          'questionnaireKey': 'sas',
          'name': '焦虑自评量表(SAS)',
          'description': '评估近一周焦虑情绪状态',
          'questionCount': 20,
          'testedCount': 9860,
          'sortOrder': 2,
          'category': 'clinical',
          'h5Link': 'https://admin.currantmind.cn/assessment/sas.html',
          'backgroundImage': null,
          'icon': null,
          'userAssessStatus': '0',
          'userAssessId': null,
        },
        {
          'questionnaireId': 3,
          'questionnaireKey': 'mbti',
          'name': 'MBTI性格测试',
          'description': '了解你的性格类型与特质',
          'questionCount': 93,
          'testedCount': 234567,
          'sortOrder': 3,
          'category': 'clinical',
          'h5Link': 'https://admin.currantmind.cn/assessment/mbti.html',
          'backgroundImage': null,
          'icon': null,
          'userAssessStatus': '0',
          'userAssessId': null,
        },
        {
          'questionnaireId': 4,
          'questionnaireKey': 'gad7',
          'name': '广泛性焦虑量表(GAD-7)',
          'description': '快速筛查广泛性焦虑',
          'questionCount': 7,
          'testedCount': 321,
          'sortOrder': 4,
          'category': 'clinical',
          'h5Link': 'https://admin.currantmind.cn/assessment/gad7.html',
          'backgroundImage': null,
          'icon': null,
          'userAssessStatus': '0',
          'userAssessId': null,
        },
      ],
    };
  });

  // ----------------------------------------------------------------------
  // 阶段 4 上半：咨询师列表/详情/评价/预约下单（契约 §2 #9-12）+ AI 引导（§7 #38）
  // ----------------------------------------------------------------------

  /// mock 咨询师种子数据（12 条，列表分页演示加载更多：首页 10 + 第 2 页 2）。
  /// 字段对齐 iOS XYConsultant（XYConsultantModel.swift）。
  Map<String, dynamic> consultantRow(
    int id,
    String name,
    String title,
    double minPrice,
    double rating,
    int serviceCount,
    int hours,
    int expYears,
    List<String> specialty,
    List<String> style,
  ) =>
      {
        'consultantId': id,
        'realName': name,
        'title': title,
        'styleTags': style,
        'avatar': null,
        'minPrice': minPrice,
        'ratingScore': rating,
        'serviceCount': serviceCount,
        'totalServiceHours': hours,
        'specialtyTags': specialty,
        'evalTags': const ['专业咨询'],
        'experienceYears': expYears,
        'status': '1',
        'nextAvailableTime': switch (id % 4) {
          0 => '今天 19:00',
          1 => '明天 10:00',
          2 => '明天 14:00',
          _ => '后天 09:00',
        },
        'supportModes': id.isEven ? const ['语音', '视频'] : const ['文字', '语音'],
        'reviewCount': (serviceCount / 3).round(),
        'isVerified': true,
      };

  final consultantSeed = <Map<String, dynamic>>[
    consultantRow(101, '林小满', '国家二级心理咨询师 · 注册心理师', 199, 4.9, 1280, 3200, 8,
        const ['焦虑情绪', '亲密关系', '职场压力'], const ['温和倾听', '专业理性']),
    consultantRow(102, '陈安之', '婚姻家庭咨询师（中级）', 299, 5.0, 860, 2100, 6,
        const ['婚姻家庭', '亲子教育'], const ['共情陪伴', '目标导向']),
    consultantRow(103, '苏晚晴', '国家三级心理咨询师', 159, 4.8, 640, 1500, 5,
        const ['情绪管理', '自我成长'], const ['温暖接纳', '循循善诱']),
    consultantRow(104, '周牧野', '认知行为治疗（CBT）取向咨询师', 399, 4.9, 1500, 4600, 10,
        const ['抑郁情绪', '强迫困扰', '睡眠问题'], const ['结构化', '专业理性']),
    consultantRow(105, '顾一帆', '青少年心理发展咨询师', 259, 4.7, 520, 1300, 4,
        const ['学业压力', '青春期困惑'], const ['耐心细致', '亲和力强']),
    consultantRow(106, '沈知遥', '人本主义取向心理咨询师', 329, 4.9, 980, 2800, 7,
        const ['自我价值', '人际关系'], const ['温和倾听', '深度陪伴']),
    consultantRow(107, '韩青梧', '精神动力学取向咨询师', 459, 5.0, 2100, 6800, 12,
        const ['原生家庭', '创伤修复'], const ['稳定抱持', '洞察深入']),
    consultantRow(108, '唐雨桐', '国家二级心理咨询师', 189, 4.6, 430, 980, 3,
        const ['焦虑情绪', '职场压力'], const ['轻松幽默', '共情陪伴']),
    consultantRow(109, '白鹭洲', '正念减压（MBSR）引导师', 229, 4.8, 760, 1900, 6,
        const ['正念减压', '睡眠问题'], const ['平静专注', '循循善诱']),
    consultantRow(110, '祁连山', '危机干预与哀伤辅导咨询师', 499, 5.0, 1800, 5400, 11,
        const ['哀伤辅导', '危机干预'], const ['稳定抱持', '专业理性']),
    consultantRow(111, '叶知秋', '伴侣与性心理咨询师', 359, 4.7, 690, 1700, 5,
        const ['亲密关系', '婚姻家庭'], const ['开放包容', '目标导向']),
    consultantRow(112, '方既明', '积极心理学取向咨询师', 269, 4.8, 840, 2200, 7,
        const ['自我成长', '情绪管理'], const ['温暖接纳', '结构化']),
  ];

  // #9 咨询师列表（分页：total 12 > pageSize 10，演示上拉加载更多）
  ApiClient.registerMock('/app/consultant/list', (body) {
    final pageNum = (body['pageNum'] as num?)?.toInt() ?? 1;
    final pageSize = (body['pageSize'] as num?)?.toInt() ?? 10;
    final start = (pageNum - 1) * pageSize;
    final rows = start >= consultantSeed.length
        ? <Map<String, dynamic>>[]
        : consultantSeed.sublist(
            start,
            (start + pageSize) > consultantSeed.length
                ? consultantSeed.length
                : start + pageSize,
          );
    return {
      'code': 200,
      'msg': '操作成功',
      'total': consultantSeed.length,
      'rows': rows,
    };
  });

  /// mock 最近可约时段：未来 7 天，每天若干 50 分钟时段；
  /// 第 3 天全部已约（演示「已满」），其余天每第 2 个时段已约。
  List<Map<String, dynamic>> buildMockAvailability() {
    const slotPairs = [
      ('09:00:00', '09:50:00'),
      ('10:00:00', '10:50:00'),
      ('14:00:00', '14:50:00'),
      ('15:00:00', '15:50:00'),
      ('19:00:00', '19:50:00'),
    ];
    final now = DateTime.now();
    final list = <Map<String, dynamic>>[];
    var id = 1000;
    for (var d = 0; d < 7; d++) {
      final date = dateKeyOf(now.add(Duration(days: d)));
      for (var i = 0; i < slotPairs.length; i++) {
        final booked = d == 2 || i == 1;
        list.add({
          'availabilityId': id++,
          'availableDate': date,
          'startTime': slotPairs[i].$1,
          'endTime': slotPairs[i].$2,
          'isBooked': booked ? '1' : '0',
        });
      }
    }
    return list;
  }

  // #10 咨询师详情（全字段：capabilities/reviewStats/certifications/
  // recentAvailability 未来 7 天/reviews 2 条；字段对齐 iOS XYConsultantDetail）
  ApiClient.registerMock('/app/consultant/detail', (body) {
    final id = (body['consultantId'] as num?)?.toInt() ?? 101;
    final seed = consultantSeed.firstWhere(
      (e) => e['consultantId'] == id,
      orElse: () => consultantSeed.first,
    );
    return ok(data: {
      'consultantId': seed['consultantId'],
      'realName': seed['realName'],
      'title': seed['title'],
      'avatar': null,
      'introduction':
          '你好，我是${seed['realName']}。在多年的咨询工作中，我陪伴过许多正在经历情绪困扰、关系难题与人生转折的来访者。'
              '我相信每个人都拥有自我成长的力量，咨询是一段共同探索的旅程——在安全、接纳的空间里，'
              '我们会一起梳理你的感受与需要，找到属于你的方向与答案。',
      'ratingScore': seed['ratingScore'],
      'serviceCount': seed['serviceCount'],
      'totalServiceHours': seed['totalServiceHours'],
      'experienceYears': seed['experienceYears'],
      'status': '1',
      'capabilities': const [
        {
          'capabilityId': 11,
          'capabilityName': null,
          'description': null,
          'duration': 50,
          'price': 199.0,
          'supportMode': '1',
        },
        {
          'capabilityId': 12,
          'capabilityName': '语音沟通',
          'description': null,
          'duration': 50,
          'price': 299.0,
          'supportMode': '2',
        },
        {
          'capabilityId': 13,
          'capabilityName': '视频沟通',
          'description': '面对面视频交流，50分钟',
          'duration': 50,
          'price': 399.0,
          'supportMode': '3',
        },
      ],
      'reviewStats': const {'avgStar': 4.9, 'goodRate': 98.0, 'totalCount': 12},
      'certifications': const [
        {
          'certName': '国家二级心理咨询师（证书编号：1901000000123456）',
          'issuingAuthority': '人力资源和社会保障部'
        },
        {'certName': '中国心理学会临床心理学注册工作委员会注册心理师', 'issuingAuthority': '中国心理学会'},
        {'certName': '认知行为治疗（CBT）系统培训结业', 'issuingAuthority': '中科院心理研究所'},
      ],
      'isVerified': true,
      'recentAvailability': buildMockAvailability(),
      'reviews': [
        {
          'reviewId': 1,
          'userNickName': '一只小柚子',
          'userAvatar': null,
          'content': '老师特别有耐心，会认真听我把话说完，再一点点帮我梳理情绪背后的原因。聊完感觉心里轻松了很多。',
          'rating': 5,
          'createTime':
              '${dateKeyOf(DateTime.now().subtract(const Duration(days: 1)))} 21:30:00',
          'isAnonymous': '0',
          'tagNames': const ['专业负责', '很有帮助'],
        },
        {
          'reviewId': 2,
          'userNickName': null,
          'userAvatar': null,
          'content': '第一次做心理咨询，本来很紧张，老师的声音很温柔，慢慢就放松下来了。已经约了下一次。',
          'rating': 5,
          'createTime':
              '${dateKeyOf(DateTime.now().subtract(const Duration(days: 4)))} 15:02:00',
          'isAnonymous': '1',
          'tagNames': const ['温暖治愈'],
        },
      ],
      'imUserId': 'xy_mock_counselor_1001',
      'specialtyTags': seed['specialtyTags'],
      'styleTags': seed['styleTags'],
    });
  });

  /// mock 评价种子（12 条，对应 reviewStats.totalCount；reviewId 3~14，
  /// 与详情首屏 2 条不重复，演示分页加载）
  Map<String, dynamic> reviewRow(int id, String? nick, String content,
          int daysAgo, List<String> tags) =>
      {
        'reviewId': id,
        'userNickName': nick,
        'userAvatar': null,
        'content': content,
        'rating': 5,
        'createTime':
            '${dateKeyOf(DateTime.now().subtract(Duration(days: daysAgo)))} 10:00:00',
        'isAnonymous': nick == null ? '1' : '0',
        'tagNames': tags,
      };

  final reviewSeed = <Map<String, dynamic>>[
    reviewRow(3, '晚风有信', '每次咨询都有新的收获，老师给的方法很实用，已经在生活中用起来了。', 5, const ['专业负责']),
    reviewRow(
        4, null, '咨询节奏很好，不会让我觉得有压力，适合我这种慢热的人。', 7, const ['温暖治愈', '很有帮助']),
    reviewRow(5, '山茶花开', '帮孩子约的咨询，老师很懂青少年心理，孩子愿意继续聊下去。', 9, const ['耐心细致']),
    reviewRow(6, '一颗柠檬树', '把积压很久的情绪说出来了，哭完之后轻松多了，谢谢老师。', 12, const ['共情陪伴']),
    reviewRow(7, null, '视频咨询体验很好，画面清晰，老师观察很细致。', 15, const ['专业负责']),
    reviewRow(8, '橘子汽水', '第二次咨询了，睡眠真的改善了，会继续坚持。', 18, const ['很有帮助']),
    reviewRow(9, '南风知意', '老师很会提问，几个问题就点醒了我一直以来的误区。', 22, const ['洞察深入']),
    reviewRow(10, null, '语音咨询很方便，通勤路上就能聊，回复也很及时。', 26, const ['耐心细致']),
    reviewRow(
        11, '北巷听风', '很专业的一次咨询体验，结构清晰，目标明确，推荐。', 30, const ['专业负责', '目标导向']),
    reviewRow(12, '雾都夜话', '原生家庭的话题聊起来很沉重，但老师一直稳稳地接住我。', 35, const ['稳定抱持']),
    reviewRow(13, null, '聊完之后对自己的认识清晰了很多，知道自己接下来该做什么。', 40, const ['很有帮助']),
    reviewRow(14, '林间小鹿', '平台体验很好，咨询师质量很高，已经推荐给朋友了。', 45, const ['温暖治愈']),
  ];

  // #11 咨询师评价列表（分页，pageSize 5：第 1 页 5 条、第 2 页 5 条、第 3 页 2 条）
  ApiClient.registerMock('/app/consultant/review-list', (body) {
    final pageNum = (body['pageNum'] as num?)?.toInt() ?? 1;
    final pageSize = (body['pageSize'] as num?)?.toInt() ?? 5;
    final start = (pageNum - 1) * pageSize;
    final rows = start >= reviewSeed.length
        ? <Map<String, dynamic>>[]
        : reviewSeed.sublist(
            start,
            (start + pageSize) > reviewSeed.length
                ? reviewSeed.length
                : start + pageSize,
          );
    return {
      'code': 200,
      'msg': '操作成功',
      'total': reviewSeed.length,
      'rows': rows,
    };
  });

  // #12 预约下单：返回订单（orderId "mock_order_1001"）
  ApiClient.registerMock('/app/consultant/book', (body) {
    return ok(data: {
      'orderId': 'mock_order_1001',
      'orderNo': 'MOCK2024001001',
      'payStatus': '0',
      'paymentDeadline': DateTime.now()
          .add(const Duration(minutes: 15))
          .toString()
          .substring(0, 19),
      'price': 299.0,
      'duration': 50,
      'appointmentStartTime': body['appointmentTime'],
      'consultantId': body['consultantId'],
      'supportMode': body['supportMode'],
      'status': '0',
      'statusDesc': '待支付',
      'createTime': DateTime.now().toString().substring(0, 19),
    });
  });

  // #38 AI 开场引导：code 200（前端不解析返回，开场消息由后端经 IM 下发）
  ApiClient.registerMock('/app/chat/guidance', (body) => ok());

  // ----------------------------------------------------------------------
  // 阶段 4 下半：我的预约订单 / 取消 / 支付 / 评价 / 小结
  // （契约 §2 #13-16、§4 #20-21、§5 #23）
  // ----------------------------------------------------------------------

  String timeText(DateTime d) => d.toString().substring(0, 19);

  /// 已取消订单 id 内存态（cancel 后 my-list 状态同步为已取消，演示闭环）
  final cancelledOrderIds = <String>{};
  final paidOrderIds = <String>{};
  final reviewedOrderIds = <String>{};
  final recapReadOrderIds = <String>{};
  final completedSessionOrderIds = <String>{};
  final rescheduleApplicationOrderIds = <String>{};
  final rescheduleRequests = <String, String>{};
  final paymentOrders = <String, String>{};

  /// mock 预约订单行（字段对齐 iOS XYConsultOrder / my-list 行元素）。
  Map<String, dynamic> orderRow({
    required Object orderId,
    required int consultantId,
    required String name,
    required String title,
    required String supportMode,
    required String supportModeDesc,
    required String appointmentTime,
    required int duration,
    required double price,
    required String displayStatus,
    required String displayStatusDesc,
    required List<String> specialty,
    required List<String> style,
    required double serviceHours,
    String? paymentDeadline,
    bool hasReview = true,
    String confirmationStatus = 'confirmed',
    String intakeStatus = 'submitted',
    String sessionStatus = 'ready',
    String summaryStatus = 'none',
    bool recapRead = false,
    String? rescheduleStatus,
    String? requestedAppointmentTime,
  }) =>
      {
        'orderId': orderId,
        'orderNo': 'MOCK202400$orderId'.replaceAll('mock_order_', '1'),
        'payStatus': displayStatus == 'unpaid' ? '0' : '1',
        'paymentDeadline': paymentDeadline,
        'price': price,
        'duration': duration,
        'appointmentTime': appointmentTime,
        'consultantId': consultantId,
        'consultantName': name,
        'consultantTitle': title,
        // 演示用占位头像（评价页 / 订单卡可展示）
        'consultantAvatar':
            'https://i.pravatar.cc/150?u=consultant_$consultantId',
        'consultantImUserId': 'xy_mock_counselor_$consultantId',
        'supportMode': supportMode,
        'supportModeDesc': supportModeDesc,
        'capabilityName': supportModeDesc,
        'displayStatus': displayStatus,
        'displayStatusDesc': displayStatusDesc,
        'status': displayStatus,
        'statusDesc': displayStatusDesc,
        'specialtyTags': specialty,
        'styleTags': style,
        'totalServiceHours': serviceHours,
        'hasReview': hasReview,
        'confirmationStatus': confirmationStatus,
        'intakeStatus': intakeStatus,
        'sessionStatus': sessionStatus,
        'summaryStatus': summaryStatus,
        'recapRead': recapRead,
        if (rescheduleStatus != null) 'rescheduleStatus': rescheduleStatus,
        if (requestedAppointmentTime != null)
          'requestedAppointmentTime': requestedAppointmentTime,
        'sessionId': 'session-$orderId',
        'draftId': 'draft-$orderId',
        'roomId': 'room-$orderId',
        'roomName': supportModeDesc,
        'createTime':
            timeText(DateTime.now().subtract(const Duration(days: 2))),
      };

  final now = DateTime.now();
  final orderSeed = <Map<String, dynamic>>[
    // 待支付 2 条（首条为预约下单 mock 返回的 mock_order_1001，支付链路可闭环）
    orderRow(
      orderId: 'mock_order_1001',
      consultantId: 101,
      name: '林小满',
      title: '国家二级心理咨询师 · 注册心理师',
      supportMode: '2',
      supportModeDesc: '语音咨询',
      appointmentTime: timeText(now.add(const Duration(days: 1, hours: 2))),
      duration: 50,
      price: 299,
      displayStatus: 'unpaid',
      displayStatusDesc: '待支付',
      specialty: const ['焦虑情绪', '亲密关系', '职场压力'],
      style: const ['温和倾听', '专业理性'],
      serviceHours: 3200,
      paymentDeadline: timeText(now.add(const Duration(minutes: 15))),
      confirmationStatus: 'not_requested',
      intakeStatus: 'locked',
      sessionStatus: 'locked',
    ),
    orderRow(
      orderId: 2002,
      consultantId: 104,
      name: '周牧野',
      title: '认知行为治疗（CBT）取向咨询师',
      supportMode: '3',
      supportModeDesc: '视频咨询',
      appointmentTime: timeText(now.add(const Duration(days: 2, hours: 5))),
      duration: 50,
      price: 399,
      displayStatus: 'unpaid',
      displayStatusDesc: '待支付',
      specialty: const ['抑郁情绪', '睡眠问题'],
      style: const ['结构化'],
      serviceHours: 4600,
      paymentDeadline: timeText(now.add(const Duration(minutes: 14))),
      confirmationStatus: 'not_requested',
      intakeStatus: 'locked',
      sessionStatus: 'locked',
    ),
    // 待咨询 3 条
    orderRow(
      orderId: 2003,
      consultantId: 102,
      name: '陈安之',
      title: '婚姻家庭咨询师（中级）',
      supportMode: '2',
      supportModeDesc: '语音咨询',
      appointmentTime: timeText(now.add(const Duration(days: 3))),
      duration: 50,
      price: 299,
      displayStatus: 'not_consulted',
      displayStatusDesc: '待咨询',
      specialty: const ['婚姻家庭', '亲子教育'],
      style: const ['共情陪伴'],
      serviceHours: 2100,
      confirmationStatus: 'pending',
      intakeStatus: 'locked',
      sessionStatus: 'locked',
    ),
    orderRow(
      orderId: 2004,
      consultantId: 103,
      name: '苏晚晴',
      title: '国家三级心理咨询师',
      supportMode: '1',
      supportModeDesc: '文字咨询',
      appointmentTime: timeText(now.add(const Duration(days: 4))),
      duration: 50,
      price: 159,
      displayStatus: 'not_consulted',
      displayStatusDesc: '待咨询',
      specialty: const ['情绪管理', '自我成长'],
      style: const ['温暖接纳'],
      serviceHours: 1500,
      intakeStatus: 'pending',
    ),
    orderRow(
      orderId: 2005,
      consultantId: 106,
      name: '沈知遥',
      title: '人本主义取向心理咨询师',
      supportMode: '3',
      supportModeDesc: '视频咨询',
      appointmentTime: timeText(now.add(const Duration(days: 5))),
      duration: 50,
      price: 329,
      displayStatus: 'not_consulted',
      displayStatusDesc: '待咨询',
      specialty: const ['自我价值', '人际关系'],
      style: const ['深度陪伴'],
      serviceHours: 2800,
      intakeStatus: 'skipped',
      rescheduleStatus: 'approved',
    ),
    // 改期申请待确认：订单状态仍为“待咨询”，只增加工作流申请。
    orderRow(
      orderId: 2013,
      consultantId: 113,
      name: '程听澜',
      title: '国家二级心理咨询师 · 叙事取向',
      supportMode: '3',
      supportModeDesc: '视频咨询',
      appointmentTime: timeText(now.add(const Duration(days: 6, hours: 2))),
      duration: 50,
      price: 369,
      displayStatus: 'not_consulted',
      displayStatusDesc: '待咨询',
      specialty: const ['情绪调节', '自我成长'],
      style: const ['温和启发'],
      serviceHours: 2600,
      confirmationStatus: 'confirmed',
      intakeStatus: 'submitted',
      sessionStatus: 'ready',
      rescheduleStatus: 'pending',
    ),
    // 可发起改期申请：底部与“取消预约”并列展示。
    orderRow(
      orderId: 2014,
      consultantId: 114,
      name: '陆时安',
      title: '注册心理师 · 人本取向',
      supportMode: '2',
      supportModeDesc: '语音咨询',
      appointmentTime: timeText(now.add(const Duration(days: 8))),
      duration: 50,
      price: 329,
      displayStatus: 'not_consulted',
      displayStatusDesc: '待咨询',
      specialty: const ['职场压力', '人际关系'],
      style: const ['温暖倾听'],
      serviceHours: 3100,
      confirmationStatus: 'confirmed',
      intakeStatus: 'submitted',
      sessionStatus: 'ready',
    ),
    // 咨询中 1 条
    orderRow(
      orderId: 2006,
      consultantId: 107,
      name: '韩青梧',
      title: '精神动力学取向咨询师',
      supportMode: '2',
      supportModeDesc: '语音咨询',
      appointmentTime: timeText(now.subtract(const Duration(minutes: 10))),
      duration: 50,
      price: 459,
      displayStatus: 'consulting',
      displayStatusDesc: '咨询中',
      specialty: const ['原生家庭', '创伤修复'],
      style: const ['稳定抱持'],
      serviceHours: 6800,
      sessionStatus: 'in_progress',
    ),
    // 视频会议室演示：用于验证双端身份差异与多模态情绪识别 UI。
    orderRow(
      orderId: 2011,
      consultantId: 108,
      name: '陈子健',
      title: '临床与咨询心理学硕士',
      supportMode: '3',
      supportModeDesc: '视频咨询',
      appointmentTime: timeText(now.subtract(const Duration(minutes: 8))),
      duration: 50,
      price: 399,
      displayStatus: 'consulting',
      displayStatusDesc: '咨询中',
      specialty: const ['情绪调节', '压力管理'],
      style: const ['温和聚焦'],
      serviceHours: 3600,
      sessionStatus: 'in_progress',
    ),
    // 已完成 4 条（2 条未评价 → 评价咨询师；2 条已评价）
    orderRow(
      orderId: 2007,
      consultantId: 106,
      name: '沈知遥',
      title: '人本主义取向心理咨询师',
      supportMode: '2',
      supportModeDesc: '语音咨询',
      appointmentTime: timeText(now.subtract(const Duration(days: 1))),
      duration: 50,
      price: 299,
      displayStatus: 'consulted',
      displayStatusDesc: '已完成',
      specialty: const ['自我价值', '人际关系'],
      style: const ['深度陪伴'],
      serviceHours: 2800,
      hasReview: false,
      sessionStatus: 'completed',
      summaryStatus: 'pending',
    ),
    orderRow(
      orderId: 2008,
      consultantId: 105,
      name: '顾一帆',
      title: '青少年心理发展咨询师',
      supportMode: '3',
      supportModeDesc: '视频咨询',
      appointmentTime: timeText(now.subtract(const Duration(days: 3))),
      duration: 50,
      price: 259,
      displayStatus: 'consulted',
      displayStatusDesc: '已完成',
      specialty: const ['学业压力', '青春期困惑'],
      style: const ['耐心细致'],
      serviceHours: 1300,
      hasReview: false,
      sessionStatus: 'completed',
      summaryStatus: 'shared',
      recapRead: false,
    ),
    orderRow(
      orderId: 2009,
      consultantId: 109,
      name: '白鹭洲',
      title: '正念减压（MBSR）引导师',
      supportMode: '2',
      supportModeDesc: '语音咨询',
      appointmentTime: timeText(now.subtract(const Duration(days: 6))),
      duration: 50,
      price: 229,
      displayStatus: 'consulted',
      displayStatusDesc: '已完成',
      specialty: const ['正念减压', '睡眠问题'],
      style: const ['平静专注'],
      serviceHours: 1900,
      hasReview: false,
      sessionStatus: 'completed',
      summaryStatus: 'shared',
      recapRead: true,
    ),
    orderRow(
      orderId: 2010,
      consultantId: 110,
      name: '祁连山',
      title: '危机干预与哀伤辅导咨询师',
      supportMode: '2',
      supportModeDesc: '语音咨询',
      appointmentTime: timeText(now.subtract(const Duration(days: 9))),
      duration: 50,
      price: 499,
      displayStatus: 'consulted',
      displayStatusDesc: '已完成',
      specialty: const ['哀伤辅导', '危机干预'],
      style: const ['稳定抱持'],
      serviceHours: 5400,
      sessionStatus: 'completed',
      summaryStatus: 'shared',
      recapRead: true,
    ),
    // 已取消 2 条
    orderRow(
      orderId: 2011,
      consultantId: 108,
      name: '唐雨桐',
      title: '国家二级心理咨询师',
      supportMode: '1',
      supportModeDesc: '文字咨询',
      appointmentTime: timeText(now.subtract(const Duration(days: 4))),
      duration: 50,
      price: 189,
      displayStatus: 'cancelled',
      displayStatusDesc: '已取消',
      specialty: const ['焦虑情绪', '职场压力'],
      style: const ['轻松幽默'],
      serviceHours: 980,
    ),
    orderRow(
      orderId: 2012,
      consultantId: 112,
      name: '方既明',
      title: '积极心理学取向咨询师',
      supportMode: '2',
      supportModeDesc: '语音咨询',
      appointmentTime: timeText(now.subtract(const Duration(days: 7))),
      duration: 50,
      price: 269,
      displayStatus: 'cancelled',
      displayStatusDesc: '已取消',
      specialty: const ['自我成长', '情绪管理'],
      style: const ['温暖接纳'],
      serviceHours: 2200,
    ),
  ];

  // #13 我的预约订单：首屏同时展示生命周期与改期工作流样本。
  ApiClient.registerMock('/app/consultant/order/my-list', (body) {
    final pageNum = (body['pageNum'] as num?)?.toInt() ?? 1;
    final pageSize = (body['pageSize'] as num?)?.toInt() ?? 10;
    const lifecycleShowcaseOrderIds = {
      'mock_order_1001', // 待支付
      '2003', // 待咨询师确认
      '2004', // 订单待咨询；当前工作流为前序资料
      '2005', // 已确认且未开始；详情页可发起改期
      '2013', // 改期申请已提交，待咨询师确认
      '2014', // 可从详情底部发起改期申请
      '2006', // 咨询室
      '2007', // 订单已完成；当前工作流为等待回顾
      '2008', // 订单已完成；当前工作流为查看回顾
      '2009', // 订单已完成；当前工作流为待评价
    };
    final all = orderSeed
        .where((row) =>
            lifecycleShowcaseOrderIds.contains(row['orderId'].toString()))
        .map((row) {
      final id = row['orderId'].toString();
      final requestedTime = rescheduleRequests[id];
      if (cancelledOrderIds.contains(id)) {
        return {
          ...row,
          'payStatus': '0',
          'paymentDeadline': null,
          'displayStatus': 'cancelled',
          'displayStatusDesc': '已取消',
          'status': 'cancelled',
          'statusDesc': '已取消',
        };
      }
      if (paidOrderIds.contains(id)) {
        return {
          ...row,
          'payStatus': '1',
          'paymentDeadline': null,
          'displayStatus': 'not_consulted',
          'displayStatusDesc': '待咨询师确认',
          'confirmationStatus': 'pending',
          'intakeStatus': 'locked',
          'sessionStatus': 'locked',
        };
      }
      if (completedSessionOrderIds.contains(id)) {
        return {
          ...row,
          'displayStatus': 'consulted',
          'displayStatusDesc': '已完成',
          'sessionStatus': 'completed',
          'summaryStatus': 'pending',
          'recapRead': false,
          'hasReview': false,
        };
      }
      return {
        ...row,
        if (rescheduleApplicationOrderIds.contains(id))
          'rescheduleStatus': 'pending',
        if (requestedTime != null) ...{
          'rescheduleStatus': 'completed',
          'requestedAppointmentTime': requestedTime,
          'appointmentTime': requestedTime,
        },
        if (reviewedOrderIds.contains(id)) 'hasReview': true,
        if (recapReadOrderIds.contains(id)) 'recapRead': true,
      };
    }).toList();
    final start = (pageNum - 1) * pageSize;
    final rows = start >= all.length
        ? <Map<String, dynamic>>[]
        : all.sublist(
            start,
            (start + pageSize) > all.length ? all.length : start + pageSize,
          );
    return {
      'code': 200,
      'msg': '操作成功',
      'total': all.length,
      'rows': rows,
    };
  });

  // #14 取消预约：写入内存态，my-list 状态同步
  ApiClient.registerMock('/app/consultant/order/cancel', (body) {
    final id = body['orderId']?.toString() ?? '';
    if (id.isEmpty) return {'code': 500, 'msg': '订单信息无效'};
    cancelledOrderIds.add(id);
    return ok(msg: '取消成功');
  });

  ApiClient.registerMock('/app/consultant/order/reschedule', (body) {
    final id = body['orderId']?.toString() ?? '';
    final reason = body['reason']?.toString() ?? '';
    if (id.isEmpty || reason.isEmpty) {
      return {'code': 500, 'msg': '改期信息不完整'};
    }
    rescheduleApplicationOrderIds.add(id);
    return ok(msg: '改期申请已提交，等待咨询师确认');
  });

  ApiClient.registerMock('/app/consultant/order/reschedule-time', (body) {
    final id = body['orderId']?.toString() ?? '';
    final appointmentTime = body['appointmentTime']?.toString() ?? '';
    if (id.isEmpty || appointmentTime.isEmpty) {
      return {'code': 500, 'msg': '新预约时间不完整'};
    }
    rescheduleRequests[id] = appointmentTime;
    return ok(msg: '预约时间已更新');
  });

  ApiClient.registerMock('/app/consultant/room/complete', (body) {
    final id = body['orderId']?.toString() ?? '';
    if (id.isEmpty) return {'code': 500, 'msg': '订单信息无效'};
    completedSessionOrderIds.add(id);
    return ok(msg: '咨询已结束，等待咨询师确认回顾');
  });

  // #20 创建支付：返回商户订单号 outTradeNo
  ApiClient.registerMock('/app/pay/create', (body) {
    final orderId = body['orderId']?.toString() ?? '';
    if (orderId.isEmpty) return {'code': 500, 'msg': '订单号缺失'};
    final payType = body['payType']?.toString() ?? 'alipay';
    final tradeNo =
        'MOCK_${payType.toUpperCase()}_${DateTime.now().millisecondsSinceEpoch}';
    paymentOrders[tradeNo] = orderId;
    return ok(data: {'outTradeNo': tradeNo});
  });

  // #21 模拟支付成功回调（阶段 9 换真实支付）
  ApiClient.registerMock('/app/pay/mock-success', (body) {
    final tradeNo = body['outTradeNo']?.toString() ?? '';
    if (tradeNo.isEmpty) return {'code': 500, 'msg': '支付订单号缺失'};
    final orderId = paymentOrders[tradeNo];
    if (orderId != null) paidOrderIds.add(orderId);
    return ok(msg: '支付成功');
  });

  // #15 评价可选标签（8 个，对象数组带 tagId）
  ApiClient.registerMock('/app/consultant/review/tags', (body) {
    return {
      'code': 200,
      'msg': '操作成功',
      'data': const [
        {'tagId': 1, 'tagName': '专业负责'},
        {'tagId': 2, 'tagName': '很有帮助'},
        {'tagId': 3, 'tagName': '温暖治愈'},
        {'tagId': 4, 'tagName': '耐心细致'},
        {'tagId': 5, 'tagName': '共情陪伴'},
        {'tagId': 6, 'tagName': '洞察深入'},
        {'tagId': 7, 'tagName': '稳定抱持'},
        {'tagId': 8, 'tagName': '目标导向'},
      ],
    };
  });

  // #16 提交评价：校验基本字段后成功
  ApiClient.registerMock('/app/consultant/review/add', (body) {
    final rating = (body['rating'] as num?)?.toInt() ?? 0;
    final content = body['content']?.toString() ?? '';
    if (rating < 1 || rating > 5) return {'code': 500, 'msg': '评分无效'};
    if (content.trim().isEmpty) return {'code': 500, 'msg': '评价内容不能为空'};
    final orderId = body['orderId']?.toString();
    if (orderId != null && orderId.isNotEmpty) reviewedOrderIds.add(orderId);
    return ok(msg: '评价已提交');
  });

  // IM 行动卡状态与订单投影共用同一份 Mock 数据。
  ApiClient.registerMock('/app/mine/order/consult-status', (body) {
    final id = body['orderId']?.toString() ?? '';
    final row = orderSeed.cast<Map<String, dynamic>?>().firstWhere(
          (item) => item?['orderId'].toString() == id,
          orElse: () => null,
        );
    return ok(data: {
      'reviewDone': reviewedOrderIds.contains(id) || row?['hasReview'] == true,
      'summaryDone': row?['summaryStatus'] == 'shared',
    });
  });

  // #23 小结与建议详情（完整小结 + 建议数组；
  // 字段对齐 iOS XYSummaryAdviseDetail）
  ApiClient.registerMock('/app/mine/summary/detail', (body) {
    final orderId = body['orderId']?.toString();
    if (orderId != null && orderId.isNotEmpty) recapReadOrderIds.add(orderId);
    return ok(data: {
      'content': '本次咨询中，我们一起梳理了你最近在工作中遇到的焦虑情绪。你提到任务截止压力让你在夜间反复回想白天的失误，'
          '我们一起区分了「事实」与「灾难化想象」，并练习了情绪命名与 grounding 技巧。'
          '整体而言，你对自己的情绪模式有了更清晰的觉察，这是一个很好的开始。',
      'advice': const [
        '睡前记录一次自动想法',
        '完成四轮呼吸练习',
        '向负责人确认任务优先级',
      ],
      'nextDirection': '下次会谈继续回看睡眠变化，并练习更稳定地表达需求和边界。',
      'consultantName': '林小满',
      'consultantTitle': '国家二级心理咨询师 · 注册心理师',
      'consultantAvatar': null,
      'appointmentTime': timeText(now.subtract(const Duration(days: 1))),
      'duration': 50,
      'supportModeText': '语音咨询',
      'supportMode': '2',
    });
  });

  // ----------------------------------------------------------------------
  // 阶段 6：量表测试记录 / 小结列表 / 注销账号
  // （契约 §3 #18、§5 #22/#24；#25 数字心理画像已随原生用户端下线移除）
  // ----------------------------------------------------------------------

  // #18 量表测试记录（status="1"；data 为数组非分页）：
  // 4 条记录均带 userAssessId，点「查看详情」可跳测评报告（9004）
  ApiClient.registerMock('/app/assessment/list-by-status', (body) {
    return {
      'code': 200,
      'msg': '操作成功',
      'data': [
        {
          'h5Link': 'https://admin.currantmind.cn/assessment/sds.html',
          'name': '抑郁自评量表(SDS)',
          'questionnaireId': 1,
          'updateTime': timeText(now.subtract(const Duration(days: 1))),
          'userAssessId': 101,
          'userAssessStatus': '1',
          'userScore': 58,
          'userLevel': '轻度抑郁倾向',
        },
        {
          'h5Link': 'https://admin.currantmind.cn/assessment/sas.html',
          'name': '焦虑自评量表(SAS)',
          'questionnaireId': 2,
          'updateTime': timeText(now.subtract(const Duration(days: 6))),
          'userAssessId': 102,
          'userAssessStatus': '1',
          'userScore': 46,
          'userLevel': '正常范围',
        },
        {
          'h5Link': 'https://admin.currantmind.cn/assessment/gad7.html',
          'name': '广泛性焦虑量表(GAD-7)',
          'questionnaireId': 4,
          'updateTime': timeText(now.subtract(const Duration(days: 13))),
          'userAssessId': 103,
          'userAssessStatus': '1',
          'userScore': 9,
          'userLevel': '轻度焦虑',
        },
        {
          'h5Link': 'https://admin.currantmind.cn/assessment/mbti.html',
          'name': 'MBTI性格测试',
          'questionnaireId': 3,
          'updateTime': timeText(now.subtract(const Duration(days: 20))),
          'userAssessId': 104,
          'userAssessStatus': '1',
          'userScore': null,
          'userLevel': null,
        },
      ],
    };
  });

  /// mock 小结种子（12 条，分页演示加载更多：首页 10 + 第 2 页 2）。
  /// 字段对齐 iOS XYMineSummaryRow（orderId/consultant 系列/
  /// appointmentStartTime/EndTime/content/advice 数组）。
  Map<String, dynamic> summarySeedRow(
    int orderId,
    int consultantId,
    String name,
    String title,
    int daysAgo,
    String content,
    List<String> advice,
  ) =>
      {
        'orderId': orderId,
        'consultantId': consultantId,
        'consultantName': name,
        'consultantTitle': title,
        'consultantAvatar': null,
        'appointmentStartTime': timeText(now.subtract(Duration(days: daysAgo))),
        'appointmentEndTime': timeText(now
            .subtract(Duration(days: daysAgo))
            .add(const Duration(minutes: 50))),
        'content': content,
        'advice': advice,
      };

  final summarySeed = <Map<String, dynamic>>[
    summarySeedRow(
        2007,
        101,
        '林小满',
        '医生',
        1,
        '本次咨询中，我们一起梳理了你最近在工作中遇到的焦虑情绪，区分了「事实」与「灾难化想象」，并练习了情绪命名与 grounding 技巧。',
        const [
          '每天睡前花 5 分钟做「情绪命名」练习',
          '焦虑出现时尝试 5-4-3-2-1 grounding 技巧',
          '把大任务拆成 3 个小步骤',
          '一周后复诊回顾练习效果'
        ]),
    summarySeedRow(
        2008,
        105,
        '顾一帆',
        '心理咨询师',
        3,
        '围绕学业压力与青春期困惑展开，孩子逐渐打开心扉，愿意表达真实想法，后续可继续巩固信任关系。',
        const ['每天记录一件让自己有成就感的小事', '与家人约定每周一次固定交流时间']),
    summarySeedRow(
        2009,
        109,
        '白鹭洲',
        '引导师',
        6,
        '本次以正念呼吸练习为主，帮助你在睡前建立放松仪式，睡眠困扰已有初步改善。',
        const ['睡前 10 分钟正念呼吸', '固定就寝时间，减少睡前屏幕使用']),
    summarySeedRow(2010, 110, '祁连山', '医生', 9, '哀伤辅导初见成效，你能更平静地谈论失去，情绪稳定性逐步提升。',
        const ['允许自己悲伤，不必强迫自己「快点好起来」', '保持基本作息与饮食规律']),
    summarySeedRow(
        2101,
        102,
        '陈安之',
        '咨询师',
        12,
        '婚姻家庭议题中梳理了沟通模式，识别出「指责-防御」循环，练习了非暴力沟通表达。',
        const ['用「我感到…」代替「你总是…」', '每周安排一次无干扰的伴侣对话']),
    summarySeedRow(
        2102,
        103,
        '苏晚晴',
        '心理咨询师',
        15,
        '情绪管理训练进行中，你对情绪的觉察速度明显加快，能在升级前按下暂停键。',
        const ['情绪升级前先做 3 次深呼吸', '建立自己的情绪触发清单']),
    summarySeedRow(
        2103,
        104,
        '周牧野',
        '医生',
        18,
        'CBT 框架下识别了核心不合理信念，完成了第一次认知重构练习。',
        const ['记录自动化思维并标注认知歪曲类型', '每天完成一张思维记录表']),
    summarySeedRow(
        2104,
        106,
        '沈知遥',
        '咨询师',
        22,
        '围绕自我价值展开探索，你开始区分「他人的期待」与「自己的需要」。',
        const ['每天写下一件「为自己而做」的事', '练习对不合理请求说「不」']),
    summarySeedRow(
        2105,
        107,
        '韩青梧',
        '医生',
        26,
        '原生家庭议题深入探讨，对早年依恋模式有了更清晰的看见，哀悼过程正在发生。',
        const ['给童年的自己写一封信', '观察自己在亲密关系中的投射']),
    summarySeedRow(
        2106,
        108,
        '唐雨桐',
        '咨询师',
        30,
        '职场压力议题中明确了边界感的重要性，制定了可执行的边界守护计划。',
        const ['明确工作时间边界，下班后不处理工作消息', '每天留出 30 分钟完全属于自己的时间']),
    summarySeedRow(
        2107,
        111,
        '叶知秋',
        '咨询师',
        34,
        '亲密关系中的沟通模式逐步改善，你能更坦诚地表达需求而非试探。',
        const ['直接表达需求，代替暗示与试探', '复盘一次成功沟通的经验']),
    summarySeedRow(
        2108,
        112,
        '方既明',
        '咨询师',
        38,
        '积极心理学取向干预，优势清单与感恩练习双管齐下，主观幸福感有所提升。',
        const ['每天睡前记录 3 件值得感恩的事', '发挥一项个人优势完成一件小事']),
  ];

  // #22 小结与建议列表（分页：total 12 > pageSize 10，演示上拉加载更多）
  ApiClient.registerMock('/app/mine/summaries', (body) {
    final pageNum = (body['pageNum'] as num?)?.toInt() ?? 1;
    final pageSize = (body['pageSize'] as num?)?.toInt() ?? 10;
    final start = (pageNum - 1) * pageSize;
    final rows = start >= summarySeed.length
        ? <Map<String, dynamic>>[]
        : summarySeed.sublist(
            start,
            (start + pageSize) > summarySeed.length
                ? summarySeed.length
                : start + pageSize,
          );
    return {
      'code': 200,
      'msg': '操作成功',
      'total': summarySeed.length,
      'rows': rows,
    };
  });

  // #25 数字心理画像 mock 已移除（原生用户端已下线该功能，
  // 页面/路由/入口同步删除）。

  // #24 注销账号：校验验证码 6 位成功（成功后页面清登录态回登录页）
  ApiClient.registerMock('/app/mine/deactivate', (body) {
    final code = body['smsCode']?.toString() ?? '';
    if (code.length != 6) {
      return {'code': 500, 'msg': '验证码错误'};
    }
    return ok(msg: '注销成功');
  });

  // 意见反馈提交（iOS XYFeedbackViewModel → POST /app/mine/feedback/submit）
  ApiClient.registerMock('/app/mine/feedback/submit', (body) {
    final content = (body['content']?.toString() ?? '').trim();
    if (content.isEmpty) {
      return {'code': 500, 'msg': '反馈的意见不能为空'};
    }
    return ok(msg: '反馈成功');
  });

  // 举报理由列表（iOS XYReportViewModel → POST /app/report/reasons）
  // data 为数组，不能走 ok(data: Map)
  ApiClient.registerMock('/app/report/reasons', (body) {
    return {
      'code': 200,
      'msg': '操作成功',
      'data': [
        {'code': 'porn', 'label': '色情低俗'},
        {'code': 'illegal', 'label': '违法违规'},
        {'code': 'fraud', 'label': '诈骗骚扰'},
        {'code': 'abuse', 'label': '人身攻击'},
        {'code': 'fake', 'label': '虚假信息'},
        {'code': 'other', 'label': '其他'},
      ],
    };
  });

  // 提交举报（POST /app/report/submit）
  ApiClient.registerMock('/app/report/submit', (body) {
    final targetId = (body['targetId']?.toString() ?? '').trim();
    final reasonCode = (body['reasonCode']?.toString() ?? '').trim();
    if (targetId.isEmpty || reasonCode.isEmpty) {
      return {'code': 500, 'msg': '参数缺失'};
    }
    return ok(msg: '举报成功');
  });

  // 拉黑上报（POST /app/block/add；静默成功）
  ApiClient.registerMock('/app/block/add', (body) => ok());

  // 黑名单列表（POST /app/block/list，分页；total 3，演示身份标签 + 分页分支）
  final blockListSeed = <Map<String, dynamic>>[
    {
      'blockId': 12,
      'blockedUserId': 88,
      'nickname': '张老师',
      'avatar': null,
      'userType': '2',
      'phonenumber': '13800000088',
      'imUserId': 'cst_88',
      'createTime': '2026-07-31 10:00:00',
    },
    {
      'blockId': 13,
      'blockedUserId': 201,
      'nickname': '小明',
      'avatar': null,
      'userType': '1',
      'phonenumber': '13900000201',
      'imUserId': 'user_201',
      'createTime': '2026-07-30 15:32:10',
    },
    {
      'blockId': 14,
      'blockedUserId': 305,
      'nickname': '王医生',
      'avatar': null,
      'userType': '2',
      'phonenumber': '13700000305',
      'imUserId': 'cst_305',
      'createTime': '2026-07-28 09:05:00',
    },
  ];
  ApiClient.registerMock('/app/block/list', (body) {
    final pageNum = (body['pageNum'] as num?)?.toInt() ?? 1;
    final pageSize = (body['pageSize'] as num?)?.toInt() ?? 10;
    final start = (pageNum - 1) * pageSize;
    final rows = start >= blockListSeed.length
        ? <Map<String, dynamic>>[]
        : blockListSeed.sublist(
            start,
            (start + pageSize) > blockListSeed.length
                ? blockListSeed.length
                : start + pageSize,
          );
    return {
      'code': 200,
      'msg': '查询成功',
      'total': blockListSeed.length,
      'rows': rows,
    };
  });

  // 解除黑名单（POST /app/block/cancel；按 consultantId/blockedUserId 从 seed 移除）
  ApiClient.registerMock('/app/block/cancel', (body) {
    final id = (body['consultantId'] ?? body['blockedUserId']);
    final idInt = (id as num?)?.toInt();
    blockListSeed.removeWhere((e) => e['blockedUserId'] == idInt);
    return ok(msg: '操作成功');
  });

  // ----------------------------------------------------------------------
  // 阶段 7：咨询师端工作台 / 预约单详情 / 咨询记录（契约 §6 #30-37）
  // iOS 参照：XYCounselorModule 各 ViewModel；Android 参照：ConsultantApi.kt
  // ----------------------------------------------------------------------

  /// 已写小结的订单 id 内存态（summary/save 后 completedList 的
  /// hasSummary 同步为 true，演示闭环）
  final counselorSavedSummaryOrderIds = <int>{};

  /// 工作台订单行构造（字段对齐 iOS XYCounselorWorkbenchOrderRow）
  Map<String, dynamic> counselorOrderRow({
    required int orderId,
    required String userName,
    required String imUserId,
    required String supportMode,
    required String supportModeDesc,
    required String appointmentTime,
    required List<String> tags,
    String? problemSummary,
    String? roomId,
    String? roomName,
    bool hasSummary = false,
  }) =>
      {
        'orderId': orderId,
        'userInfo': {
          'nickname': userName,
          'avatar': null,
          'imUserId': imUserId,
        },
        'supportMode': supportMode,
        'supportModeDesc': supportModeDesc,
        'roomId': roomId,
        'roomName': roomName,
        'appointmentStartTime': appointmentTime,
        'appointmentTime': appointmentTime,
        // 对齐线上：主诉 CSV + AI 摘要字段
        'preChiefComplaint': tags.join(','),
        'preEmotionSummary': problemSummary,
        'tags': tags,
        'problemSummary': problemSummary,
        'hasSummary': hasSummary,
      };

  // #31 工作台首页（consultantInfo + tabCounts 嵌套结构，
  // 含 unreadMessageCount=3；Android 参照：ConsultantHomeIndexData.kt）
  ApiClient.registerMock('/consultant/home/index', (body) {
    return ok(data: {
      'consultantInfo': {
        'avatar': null,
        'name': '林小满',
        'title': '国家二级心理咨询师 · 注册心理师',
        'satisfactionRate': 4.9,
        'acceptanceRate': 96,
      },
      'tabCounts': {
        'pendingCount': 3,
        'completedCount': 12,
        'unreadMessageCount': 3,
      },
    });
  });

  // #32 待处理预约列表（3 条不同方式/时间，total 3 不分页演示）：
  // 语音 今天 14:00（含 roomId）、视频 明天 10:00（含 roomId）、
  // 文字 今天 19:00（无 roomId，「进入咨询室」直达聊天页）
  ApiClient.registerMock('/consultant/home/pendingList', (body) {
    final rows = [
      counselorOrderRow(
        orderId: 3001,
        userName: '陈小希',
        imUserId: 'xy_mock_user_2001',
        supportMode: '2',
        supportModeDesc: '语音咨询',
        appointmentTime:
            timeText(DateTime(now.year, now.month, now.day, 14, 0)),
        tags: const ['高敏焦虑', '考研压力', '近期失眠'],
        problemSummary: '职业倦怠，情绪低落，近期压力较大',
        roomId: 'mock_room_3001',
        roomName: '语音咨询室',
      ),
      counselorOrderRow(
        orderId: 3002,
        userName: '一只小柚子',
        imUserId: 'xy_mock_user_2002',
        supportMode: '3',
        supportModeDesc: '视频咨询',
        appointmentTime:
            timeText(DateTime(now.year, now.month, now.day + 1, 10, 0)),
        tags: const ['亲密关系', '沟通困扰'],
        problemSummary: '与伴侣频繁争吵，希望改善沟通模式',
        roomId: 'mock_room_3002',
        roomName: '视频咨询室',
      ),
      counselorOrderRow(
        orderId: 3003,
        userName: '晚风有信',
        imUserId: 'xy_mock_user_2003',
        supportMode: '1',
        supportModeDesc: '文字咨询',
        appointmentTime:
            timeText(DateTime(now.year, now.month, now.day, 19, 0)),
        tags: const ['职场压力', '自我成长'],
        problemSummary: '换工作后适应困难，自我怀疑增多',
      ),
    ];
    return {
      'code': 200,
      'msg': '操作成功',
      'total': rows.length,
      'rows': rows,
    };
  });

  /// 已咨询订单种子（12 条，分页 10 + 2 演示加载更多）
  final counselorCompletedSeed = <Map<String, dynamic>>[
    counselorOrderRow(
      orderId: 3101,
      userName: '陈小希',
      imUserId: 'xy_mock_user_2001',
      supportMode: '2',
      supportModeDesc: '语音咨询',
      appointmentTime: timeText(now.subtract(const Duration(days: 1))),
      tags: const ['高敏焦虑', '考研压力'],
    ),
    counselorOrderRow(
      orderId: 3102,
      userName: '一只小柚子',
      imUserId: 'xy_mock_user_2002',
      supportMode: '3',
      supportModeDesc: '视频咨询',
      appointmentTime: timeText(now.subtract(const Duration(days: 2))),
      tags: const ['亲密关系'],
    ),
    counselorOrderRow(
      orderId: 3103,
      userName: '晚风有信',
      imUserId: 'xy_mock_user_2003',
      supportMode: '1',
      supportModeDesc: '文字咨询',
      appointmentTime: timeText(now.subtract(const Duration(days: 3))),
      tags: const ['职场压力'],
    ),
    counselorOrderRow(
      orderId: 3104,
      userName: '山茶花开',
      imUserId: 'xy_mock_user_2004',
      supportMode: '2',
      supportModeDesc: '语音咨询',
      appointmentTime: timeText(now.subtract(const Duration(days: 4))),
      tags: const ['亲子教育'],
    ),
    counselorOrderRow(
      orderId: 3105,
      userName: '一颗柠檬树',
      imUserId: 'xy_mock_user_2005',
      supportMode: '3',
      supportModeDesc: '视频咨询',
      appointmentTime: timeText(now.subtract(const Duration(days: 5))),
      tags: const ['情绪管理'],
    ),
    counselorOrderRow(
      orderId: 3106,
      userName: '橘子汽水',
      imUserId: 'xy_mock_user_2006',
      supportMode: '2',
      supportModeDesc: '语音咨询',
      appointmentTime: timeText(now.subtract(const Duration(days: 6))),
      tags: const ['睡眠问题'],
    ),
    counselorOrderRow(
      orderId: 3107,
      userName: '南风知意',
      imUserId: 'xy_mock_user_2007',
      supportMode: '1',
      supportModeDesc: '文字咨询',
      appointmentTime: timeText(now.subtract(const Duration(days: 7))),
      tags: const ['自我价值'],
    ),
    counselorOrderRow(
      orderId: 3108,
      userName: '北巷听风',
      imUserId: 'xy_mock_user_2008',
      supportMode: '2',
      supportModeDesc: '语音咨询',
      appointmentTime: timeText(now.subtract(const Duration(days: 8))),
      tags: const ['目标导向'],
    ),
    counselorOrderRow(
      orderId: 3109,
      userName: '雾都夜话',
      imUserId: 'xy_mock_user_2009',
      supportMode: '3',
      supportModeDesc: '视频咨询',
      appointmentTime: timeText(now.subtract(const Duration(days: 9))),
      tags: const ['原生家庭'],
    ),
    counselorOrderRow(
      orderId: 3110,
      userName: '林间小鹿',
      imUserId: 'xy_mock_user_2010',
      supportMode: '2',
      supportModeDesc: '语音咨询',
      appointmentTime: timeText(now.subtract(const Duration(days: 10))),
      tags: const ['温暖治愈'],
    ),
    counselorOrderRow(
      orderId: 3111,
      userName: '星野',
      imUserId: 'xy_mock_user_2011',
      supportMode: '1',
      supportModeDesc: '文字咨询',
      appointmentTime: timeText(now.subtract(const Duration(days: 11))),
      tags: const ['学业压力'],
    ),
    counselorOrderRow(
      orderId: 3112,
      userName: '青柠',
      imUserId: 'xy_mock_user_2012',
      supportMode: '2',
      supportModeDesc: '语音咨询',
      appointmentTime: timeText(now.subtract(const Duration(days: 12))),
      tags: const ['正念减压'],
    ),
  ];

  // #33 已咨询列表（分页：total 12 > pageSize 10；
  // summary/save 过的订单 hasSummary 同步为 true）
  ApiClient.registerMock('/consultant/home/completedList', (body) {
    final pageNum = (body['pageNum'] as num?)?.toInt() ?? 1;
    final pageSize = (body['pageSize'] as num?)?.toInt() ?? 10;
    final all = [
      for (final row in counselorCompletedSeed)
        counselorSavedSummaryOrderIds.contains(row['orderId'])
            ? {...row, 'hasSummary': true}
            : row,
    ];
    final start = (pageNum - 1) * pageSize;
    final rows = start >= all.length
        ? <Map<String, dynamic>>[]
        : all.sublist(
            start,
            (start + pageSize) > all.length ? all.length : start + pageSize,
          );
    return {
      'code': 200,
      'msg': '操作成功',
      'total': all.length,
      'rows': rows,
    };
  });

  /// 过往接待记录种子（2 条；#34 详情内嵌预览 + #35 分页共用）
  List<Map<String, dynamic>> counselorPastConsultations() => [
        {
          'date': dateKeyOf(now.subtract(const Duration(days: 7))),
          'summary': '很温柔，一团乱麻的情绪被一点点理清了，感觉自己又有了面对生活的力量，布置了呼吸作业。',
          'supportMode': '1',
          'supportModeText': '文字沟通',
        },
        {
          'date': dateKeyOf(now.subtract(const Duration(days: 21))),
          'summary': '首次咨询建立了良好的信任关系，来访者表达了主要的压力来源，后续将从认知角度切入。',
          'supportMode': '2',
          'supportModeText': '语音沟通',
        },
      ];

  // #34 预约单详情（来访者信息 + 主诉标签 + AI 情绪摘要 + 过往记录预览）
  ApiClient.registerMock('/consultant/home/orderDetail', (body) {
    final orderId = (body['orderId'] as num?)?.toInt() ?? 0;
    if (orderId <= 0) return {'code': 500, 'msg': '订单信息无效'};
    return ok(data: {
      'orderId': orderId,
      'appointmentTime':
          timeText(DateTime(now.year, now.month, now.day, 14, 0)),
      'supportMode': '2',
      'supportModeText': '语音咨询',
      'preEmotionSummary': '职业倦怠，情绪低落，近期压力较大',
      'preChiefComplaint': '高敏焦虑,考研压力,近期失眠,脆弱敏感',
      'pastConsultationTotal': 2,
      'pastConsultations': counselorPastConsultations(),
      'userInfo': {
        'age': 21,
        'avatar': null,
        'imUserId': 'xy_mock_user_2001',
        'nickname': '陈小希',
        'occupation': '大学生',
        'userId': 1001,
      },
    });
  });

  // #35 过往接待记录（分页）
  // ⚠ iOS API.md 未列此接口，已按 Android 契约实现，待后端确认。
  ApiClient.registerMock('/consultant/home/pastConsultations', (body) {
    final all = counselorPastConsultations();
    final pageNum = (body['pageNum'] as num?)?.toInt() ?? 1;
    final pageSize = (body['pageSize'] as num?)?.toInt() ?? 10;
    final start = (pageNum - 1) * pageSize;
    final rows = start >= all.length
        ? <Map<String, dynamic>>[]
        : all.sublist(
            start,
            (start + pageSize) > all.length ? all.length : start + pageSize,
          );
    return {
      'code': 200,
      'msg': '操作成功',
      'total': all.length,
      'rows': rows,
    };
  });

  // #36 咨询师查看用户画像
  ApiClient.registerMock('/consultant/home/userProfile', (body) {
    final userId = (body['userId'] as num?)?.toInt();
    if (userId == null) return {'code': 500, 'msg': '用户信息缺失'};
    return ok(data: {
      'currentRisk': '低',
      'heartTraitScore': 72,
      'personalityTraits': const ['高敏感', '内省型', '求稳'],
      'latestAssessment': {
        'date': timeText(now.subtract(const Duration(days: 5))),
        'score': 12,
        'type': 'sas',
      },
      'psychologicalProfile': {
        'basicProfile': '来访者近期学业压力明显，情绪波动偏大，需关注睡眠与支持系统。',
        'scaleProfile': 'SAS 得分提示轻度焦虑，建议持续观察并配合放松练习。',
        'analysisSummary': '整体风险可控，适合以支持性咨询为主，逐步建立可执行的日常节奏。',
      },
      'statusTrend': [
        for (var i = 6; i >= 0; i--)
          {
            'date': timeText(now.subtract(Duration(days: i))),
            'score': 60 + (i % 3) * 5,
          },
      ],
      'pastSummaries': [
        {
          'appointmentTime': timeText(now.subtract(const Duration(days: 14))),
          'createTime': timeText(now.subtract(const Duration(days: 14))),
          'content': '梳理了考研焦虑来源，布置呼吸练习作业。',
          'supportModeText': '语音沟通',
        },
      ],
      'pastWarningRecords': const [],
      'userInfo': {
        'age': 21,
        'avatar': null,
        'nickname': '陈小希',
        'occupation': '大学生',
        'userId': userId,
      },
    });
  });

  // #30 开始咨询/进房校验（校验 orderId 后成功）
  ApiClient.registerMock('/consultant/order/start', (body) {
    final orderId = (body['orderId'] as num?)?.toInt() ?? 0;
    if (orderId <= 0) return {'code': 500, 'msg': '订单信息无效'};
    return ok(msg: '校验通过');
  });

  // 用户端进房时段校验（iOS XYConsultRoomService.checkRoomEnter）
  ApiClient.registerMock('/app/consultant/room/join', (body) {
    final orderId = (body['orderId'] as num?)?.toInt() ?? 0;
    if (orderId <= 0) return {'code': 500, 'msg': '订单信息无效'};
    return ok(msg: '校验通过');
  });

  // #37 保存小结与建议（校验 content/advice 后写入内存态，
  // completedList 的 hasSummary 同步为 true 演示闭环）
  ApiClient.registerMock('/consultant/summary/save', (body) {
    final orderId = (body['orderId'] as num?)?.toInt() ?? 0;
    final content = body['content']?.toString().trim() ?? '';
    final advice = (body['advice'] as List?) ?? const [];
    if (orderId <= 0) return {'code': 500, 'msg': '订单信息无效'};
    if (content.isEmpty) return {'code': 500, 'msg': '请填写咨询师小结'};
    if (advice.isEmpty) return {'code': 500, 'msg': '请至少填写一条行动建议'};
    counselorSavedSummaryOrderIds.add(orderId);
    return ok(msg: '已发送');
  });

  // /consultant/summary/detail（iOS API.md 列出；⚠ Android 前端未见调用，
  // 待后端确认）：回填 AI 会话内容提取三段
  ApiClient.registerMock('/consultant/summary/detail', (body) {
    return ok(data: {
      'aiMainTopic': '考研压力引发的焦虑情绪与睡眠困扰',
      'aiEmotionalState': '情绪低落、紧张，存在明显的灾难化思维',
      'aiCoreConflict': '对自我价值的怀疑与外在期待之间的冲突',
    });
  });
}
