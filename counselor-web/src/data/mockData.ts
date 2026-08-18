import { Order, ConsultantProfile, TimeSlot, ServiceProduct, SettlementRecord, SessionSummary, ViralVoucher, TherapyQuote, ClientProfile, BankAccount, WithdrawalRecord, BillRecord } from '../types';

export const INITIAL_CLIENT_PROFILES: Record<string, ClientProfile> = {
  'cli_107': {
    id: 'cli_107',
    name: '周明宇',
    avatar: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=150&auto=format&fit=crop&q=80',
    gender: '男',
    age: 32,
    occupation: '资深后端开发',
    city: '北京',
    phone: '135****8899',
    emergencyContact: {
      name: '王女士',
      relation: '配偶',
      phone: '139****1122'
    },
    intakeDate: '2026-05-10',
    riskLevel: 'moderate',
    tags: ['职场倦怠', '躯体化', '存在主义危机'],
    phq9Score: { score: 14, level: '中度抑郁', date: '2026-08-01' },
    gad7Score: { score: 16, level: '重度焦虑', date: '2026-08-01' },
    historySummary: {
      totalSessions: 6,
      attendanceRate: '100%',
      primaryGoals: ['缓解工作引发的严重焦虑', '探索个人生活意义', '改善睡眠与进食状态'],
      counselorWorkingNotes: '来访者属于典型的高成就动机群体，但在遭遇行业调整和连续高压后崩溃。前期咨询已建立了稳定的治疗联盟，目前重点在于帮助他脱离“工作成就=自我价值”的单一评价体系，并使用 CBT 技术干预其对工作的灾难化想象。'
    },
    sessionLogs: [
      {
        sessionNo: 6,
        date: '2026-07-28',
        topic: '面对新项目的恐惧感',
        keyBreakthrough: '识别到了在接到新需求时的自动化思维：“如果我搞砸了，我就彻底完了”。尝试引入了认知重评技术。'
      },
      {
        sessionNo: 5,
        date: '2026-07-21',
        topic: '睡眠状态的回顾与放松训练',
        keyBreakthrough: '教授了渐进式肌肉放松法。来访者反馈在使用后，入睡时间从 2 小时缩短至 40 分钟，躯体紧绷感有所下降。'
      },
      {
        sessionNo: 4,
        date: '2026-07-14',
        topic: '工作与个人边界的划定',
        keyBreakthrough: '共同制定了“下班后物理断联半小时”的实验计划。来访者首次意识到自己一直在强迫自己处于“随时待命”的状态。'
      },
      {
        sessionNo: 3,
        date: '2026-06-25',
        topic: '探索“必须完美”的内在信念',
        keyBreakthrough: '回溯了原生家庭中严苛的教养方式对其完美主义的深远影响。来访者在咨询中表现出较强的情绪释放（流泪）。'
      },
      {
        sessionNo: 2,
        date: '2026-06-11',
        topic: '职场人际冲突的复盘',
        keyBreakthrough: '探讨了近期与主管的一次冲突，发现其防御机制多为“理智化”和“抽离”。'
      },
      {
        sessionNo: 1,
        date: '2026-05-10',
        topic: '首诊：症状评估与目标建立',
        keyBreakthrough: '完成摄入性会谈。确认其躯体症状（胸闷、失眠）与工作压力高度相关，排除了双相及精神分裂风险，确立了短期缓解焦虑、长期探索价值感的咨询目标。'
      }
    ],
    preSessionCheckIns: [],
    crisisInterventions: [
      {
        id: 'ci_001',
        date: '2026-07-02',
        type: 'suicide_risk',
        description: '在平台深夜留言板表达了“如果一直这样失眠，不如彻底解脱”的消极想法。',
        actionTaken: '平台值班咨询师第一时间介入，评估自杀意念与计划。联系了其妻子（紧急联系人）确认其居家安全，并与主治医生联动。',
        status: 'resolved'
      },
      {
        id: 'ci_002',
        date: '2026-06-15',
        type: 'self_harm',
        description: '诉说在极度焦虑时有用指甲划伤手臂的冲动，虽然未实施但存在风险。',
        actionTaken: '在咨询中制定了《安全计划》，列出了替代性应对策略（如冰水洗脸、捏冰块）。',
        status: 'monitoring'
      }
    ]
  },
  'cli_101': {
    id: 'cli_101',
    name: '林海燕',
    avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80',
    gender: '女',
    age: 29,
    occupation: '高级互联网产品经理',
    city: '上海市徐汇区',
    phone: '138****9201',
    emergencyContact: {
      name: '林建国',
      relation: '父亲',
      phone: '139****1108'
    },
    intakeDate: '2026-06-10',
    riskLevel: 'low',
    tags: ['完美主义倾向', '高压职场倦怠', '睡眠障碍', '躯体化肩紧'],
    phq9Score: { score: 7, level: '轻度抑郁倾向' },
    gad7Score: { score: 12, level: '中度焦虑状态' },
    historySummary: {
      totalSessions: 4,
      attendanceRate: '100%',
      primaryGoals: ['识别自动化负面思维', '建立职场心理边界', '改善入睡困难'],
      counselorWorkingNotes: '来访者自我觉察能力较强，对自己要求极高，容易因微小疏漏产生强烈的内疚感与不安全感。对 CBT 思考表工具接受度好。'
    },
    sessionLogs: [
      {
        sessionNo: 3,
        date: '2026-07-27',
        topic: '面对晋升答辩的灾难化思维去中心化探索',
        preMoodScore: 8,
        keyBreakthrough: '意识到“答辩失败不等于个人价值全盘否定”',
        homeworkStatus: 'completed'
      },
      {
        sessionNo: 2,
        date: '2026-07-20',
        topic: '躯体化肩颈紧张与身体扫描正念练习',
        preMoodScore: 7,
        keyBreakthrough: '体验到 10 分钟身体扫描后肩部肌肉张力下降 30%',
        homeworkStatus: 'completed'
      },
      {
        sessionNo: 1,
        date: '2026-07-13',
        topic: '首诊建联与临床评估、签约目标设定',
        preMoodScore: 9,
        keyBreakthrough: '初步建立安全信任的咨询契约与沟通边界',
        homeworkStatus: 'completed'
      }
    ],
    preSessionCheckIns: [
      { date: '2026-08-02', moodScore: 7, sleepHours: 5.5, distressTrigger: '周一项目评审会议压力' },
      { date: '2026-07-26', moodScore: 8, sleepHours: 5.0, distressTrigger: 'PPT改稿至深夜1点' },
      { date: '2026-07-19', moodScore: 7, sleepHours: 6.0, distressTrigger: '领导临时增加需求' }
    ]
  },
  'cli_102': {
    id: 'cli_102',
    name: '陈子健',
    avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop&q=80',
    gender: '男',
    age: 26,
    occupation: '品牌设计主管',
    city: '北京市朝阳区',
    phone: '186****3321',
    emergencyContact: {
      name: '陈美华',
      relation: '姐姐',
      phone: '185****9988'
    },
    intakeDate: '2026-08-03',
    riskLevel: 'attention',
    tags: ['急性情绪过载', '职场冲动愤怒', '亲友转赠优惠券', '首次心理咨询'],
    phq9Score: { score: 9, level: '轻度' },
    gad7Score: { score: 14, level: '中度偏重焦虑' },
    historySummary: {
      totalSessions: 1,
      attendanceRate: '100%',
      primaryGoals: ['急性情绪宣泄与降温', '评估是否需要长期咨询'],
      counselorWorkingNotes: '通过【朋友圈暖心体验券】预约。当前处于会议后急性愤怒反应，需要提供高共情、不判定的安全倾听空间。'
    },
    sessionLogs: [],
    preSessionCheckIns: [
      { date: '2026-08-03', moodScore: 9, sleepHours: 4.5, distressTrigger: '团队会议被不公正指责' }
    ]
  },
  'cli_103': {
    id: 'cli_103',
    name: '张薇微',
    avatar: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=150&auto=format&fit=crop&q=80',
    gender: '女',
    age: 31,
    occupation: '外企 HRBP',
    city: '深圳市南山区',
    phone: '135****4432',
    emergencyContact: {
      name: '王浩',
      relation: '丈夫',
      phone: '136****1122'
    },
    intakeDate: '2026-07-20',
    riskLevel: 'low',
    tags: ['回避型依恋', '伴侣沟通障碍', '信任感确立', '情绪独立'],
    phq9Score: { score: 5, level: '正常范围' },
    gad7Score: { score: 8, level: '轻度焦虑' },
    historySummary: {
      totalSessions: 2,
      attendanceRate: '100%',
      primaryGoals: ['探索亲密关系沟通模式', '建立安全型依恋回应'],
      counselorWorkingNotes: '表达清晰，但在涉及深层脆弱情感时易使用理智化防御。已尝试引入非暴力沟通工具。'
    },
    sessionLogs: [
      {
        sessionNo: 2,
        date: '2026-08-02',
        topic: '回避型沟通背后的恐惧与非暴力沟通练习',
        preMoodScore: 5,
        keyBreakthrough: '能够在冲突发生时识别出自己的“假装冷漠”反应',
        homeworkStatus: 'completed'
      },
      {
        sessionNo: 1,
        date: '2026-07-20',
        topic: '亲密关系期待与依恋类型测评分析',
        preMoodScore: 6,
        keyBreakthrough: '接纳自己在依恋需求中的矛盾感',
        homeworkStatus: 'completed'
      }
    ],
    preSessionCheckIns: [
      { date: '2026-08-02', moodScore: 5, sleepHours: 7.0, distressTrigger: '伴侣未及时回复微信' }
    ]
  },
  'cli_104': {
    id: 'cli_104',
    name: '许默凡',
    avatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150&auto=format&fit=crop&q=80',
    gender: '男',
    age: 34,
    occupation: '大学讲师',
    city: '杭州市西湖区',
    phone: '137****5566',
    emergencyContact: {
      name: '许远大',
      relation: '父亲',
      phone: '137****0011'
    },
    intakeDate: '2026-07-28',
    riskLevel: 'low',
    tags: ['原生家庭课题', '自我价值感低', '讨好型倾向', '疗程套餐'],
    phq9Score: { score: 11, level: '中度抑郁状态' },
    gad7Score: { score: 9, level: '轻度焦虑' },
    historySummary: {
      totalSessions: 1,
      attendanceRate: '100%',
      primaryGoals: ['厘清与父母的心理分化', '建立自主决策自信'],
      counselorWorkingNotes: '购买了4次疗程包。童年期受高压服从型教养方式影响较重，讨好倾向明显。'
    },
    sessionLogs: [
      {
        sessionNo: 1,
        date: '2026-08-01',
        topic: '原生家庭图景绘制与内在小孩意象对话',
        preMoodScore: 6,
        keyBreakthrough: '首次公开表达对父母过度干预的真实愤怒',
        homeworkStatus: 'completed'
      }
    ],
    preSessionCheckIns: [
      { date: '2026-08-01', moodScore: 6, sleepHours: 6.5, distressTrigger: '父母催促回家相亲安排' }
    ]
  },
  'cli_105': {
    id: 'cli_105',
    name: '陆依柔',
    avatar: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150&auto=format&fit=crop&q=80',
    gender: '女',
    age: 27,
    occupation: '自由插画师',
    city: '成都市锦江区',
    phone: '159****8877',
    emergencyContact: {
      name: '陆伟',
      relation: '哥哥',
      phone: '159****3344'
    },
    intakeDate: '2026-08-02',
    riskLevel: 'low',
    tags: ['职业转型迷茫', '创作瓶颈焦虑', '自我效能感降低'],
    phq9Score: { score: 6, level: '轻度' },
    gad7Score: { score: 7, level: '轻度' },
    historySummary: {
      totalSessions: 1,
      attendanceRate: '100%',
      primaryGoals: ['重新定位职业创作方向', '克服冒充者综合征'],
      counselorWorkingNotes: '对艺术疗法与意象表达敏感度高。预约明日第1次标准咨询。'
    },
    sessionLogs: [],
    preSessionCheckIns: [
      { date: '2026-08-02', moodScore: 6, sleepHours: 7.5, distressTrigger: '接单客户提出多次无理改稿' }
    ]
  },
  'cli_106': {
    id: 'cli_106',
    name: '赵元浩',
    avatar: 'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=150&auto=format&fit=crop&q=80',
    gender: '男',
    age: 30,
    occupation: '金融风控经理',
    city: '广州市天河区',
    phone: '188****2211',
    emergencyContact: {
      name: '赵雪',
      relation: '妹妹',
      phone: '188****7766'
    },
    intakeDate: '2026-07-29',
    riskLevel: 'low',
    tags: ['加班冲突', '退款改期', '高节奏工作'],
    historySummary: {
      totalSessions: 0,
      attendanceRate: '0%',
      primaryGoals: ['时间管理与高压调节'],
      counselorWorkingNotes: '因临时应急加班申请退款，态度礼貌，表达日后会重新排期。'
    },
    sessionLogs: [],
    preSessionCheckIns: []
  }
};

export const INITIAL_CONSULTANT: ConsultantProfile = {
  id: 'c_1001',
  name: '林木青',
  avatar: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=400&auto=format&fit=crop&q=80',
  title: '注册系统心理师 / 临床心理学硕士',
  licenseNo: 'CPS-R-2018-0921',
  experienceYears: 8,
  totalHours: 1480,
  totalClients: 186,
  rating: 4.98,
  verifiedStatus: 'verified',
  isListeningActive: true,
  orientations: ['人本主义', '认知行为 (CBT)', '正念与接纳承诺 (ACT)', '心理剧与躯体觉察'],
  targetGroups: ['成人', '高压职场人', '高敏感人群', '青年学生'],
  bio: '相信每个人内心都拥有自我疗愈与生长的力量。在安全、温暖、无判定的咨询空间里，我将陪伴你一同看清情绪背后的需求，找回内心的宁静与笃定。',
  qualificationsList: [
    '中国心理学会注册心理师 (CPS-R-2018-0921)',
    '国家二级心理咨询师 (证书编号: 1603000008201201)',
    '上海市心理学会临床专业委员会会员'
  ],
  educationList: [
    '华东师范大学 临床与咨询心理学 硕士',
    '浙江大学 心理与行为科学系 学士'
  ],
  trainingExperiences: [
    '中美心理动力学连续培训项目（3年长程系统培训）',
    '认知行为疗法（CBT）临床实操与技术演练（120学时）',
    '正念减压（MBSR）与接纳承诺疗法（ACT）短程实操工作坊',
    '危机干预与心理首救专题研修'
  ],
  supervisionHours: 360,
  personalTherapyHours: 220,
  specialties: ['职场焦虑与倦怠', '亲密关系与沟通', '情绪过载与自我关怀', '高敏感人群适应', '个人成长与自我认同'],
  targetAudience: ['成人 (18-50岁)', '高压职场白领/管理者', '高敏感人群', '高校学生'],
  proficientServices: ['50分钟个体心理咨询 (视频/语音)', '15分钟极简舒压倾听'],
  workingLanguages: ['普通话 (标准)', '英语 (Fluent)', '粤语 (基础)'],
  counselingStyle: '温暖接纳、敏锐洞察、温和而坚定。注重陪伴来访者在安全氛围中自发探索，结合逻辑梳理与躯体感知。',
  earnings: {
    withdrawable: 8650.00,
    monthlySettled: 24500.00,
    totalEarned: 189200.00,
    commissionRate: 0.12, // 12% 平台服务费
  },
  referralStats: {
    totalReferrals: 42,
    convertedClients: 19,
    viralRevenue: 15800.00,
    activeVouchersCount: 3,
  }
};

export const INITIAL_ORDERS: Order[] = [
  {
    id: 'ord_107',
    orderNo: 'ORD20260804-09',
    clientId: 'cli_107',
    clientName: '周明宇',
    clientAvatar: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=150&auto=format&fit=crop&q=80',
    serviceType: '50min_video',
    serviceTypeName: '50分钟标准视频咨询',
    status: 'scheduled',
    bookingDate: '2026-08-04',
    bookingTimeSlot: '16:00 - 16:50',
    complaintTopic: '长期加班导致的身心俱疲，对工作意义产生严重怀疑。',
    price: 600,
    hasSummary: false,
    createdAt: '2026-08-01 10:00',
    intakeForm: {
      primaryIssueDetail: '作为大厂后端开发，长期高强度加班。最近半个月出现失眠、食欲不振，一想到要去公司就感到胸闷气短，对曾经热爱的编程完全丧失兴趣。',
      expectations: '希望能缓解目前的躯体焦虑症状，重新梳理职业规划和生活重心。',
      riskAssessmentPassed: true,
      hasCounselingHistory: true,
      previousCounselingType: '本机构长程咨询'
    }
  },
  {
    id: 'ord_101',
    orderNo: 'ORD20260803-01',
    clientName: '林海燕',
    clientAvatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80',
    serviceType: '50min_video',
    serviceTypeName: '50分钟标准视频咨询',
    bookingDate: '2026-08-03',
    bookingTimeSlot: '10:30 - 11:20',
    price: 500,
    status: 'scheduled',
    preMoodScore: 7, // 焦虑指数 7/10
    complaintTopic: '职场决策陷入严重焦虑，伴随睡眠质量下降与躯体化肩紧',
    note: '第 4 次咨询。上周执行了“情绪触发事件记录”，准备在本次会谈中讨论。',
    hasSummary: false,
    createdAt: '2026-08-01 14:20',
    intakeForm: {
      primaryIssueDetail: '最近面临部门调整和晋升答辩，经常在深夜醒来，感到心慌、出汗，白天注意力难以集中，总是担心自己做不好。',
      expectations: '希望能够缓解躯体上的紧张感，并学会如何应对工作中突如其来的不确定性。',
      riskAssessmentPassed: true,
      hasCounselingHistory: true,
      previousCounselingType: 'CBT 认知行为疗法'
    }
  },
  {
    id: 'ord_102',
    orderNo: 'ORD20260803-02',
    clientName: '陈子健',
    clientAvatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop&q=80',
    serviceType: '15min_listening',
    serviceTypeName: '15分钟急诊倾听体验',
    bookingDate: '2026-08-03',
    bookingTimeSlot: '14:00 - 14:15',
    price: 39,
    status: 'scheduled',
    preMoodScore: 9,
    complaintTopic: '刚刚在团队会议后感到极度沮丧与愤怒，希望能快速情绪排毒',
    note: '新来访者，通过【朋友圈暖心体验券】完成预约。',
    hasSummary: false,
    createdAt: '2026-08-03 09:10'
  },
  {
    id: 'ord_103',
    orderNo: 'ORD20260802-05',
    clientName: '张薇微',
    clientAvatar: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=150&auto=format&fit=crop&q=80',
    serviceType: '50min_audio',
    serviceTypeName: '50分钟标准语音咨询',
    bookingDate: '2026-08-02',
    bookingTimeSlot: '16:00 - 16:50',
    price: 480,
    status: 'completed',
    preMoodScore: 5,
    complaintTopic: '', // Test empty topic,
    note: '第 2 次咨询已完成。待撰写咨询小结。',
    hasSummary: false,
    createdAt: '2026-07-30 18:00'
  },
  {
    id: 'ord_104',
    orderNo: 'ORD20260801-08',
    clientName: '许默凡',
    clientAvatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150&auto=format&fit=crop&q=80',
    serviceType: '50min_video',
    serviceTypeName: '50分钟标准视频咨询 (第1/4次)',
    bookingDate: '2026-08-01',
    bookingTimeSlot: '19:00 - 19:50',
    price: 1800,
    status: 'completed',
    preMoodScore: 6,
    complaintTopic: '原生家庭对自我价值感的影响，探索心理边界构建',
    note: '首诊评估完成，已生成阶段性契约。',
    hasSummary: true,
    createdAt: '2026-07-28 11:30'
  },
  {
    id: 'ord_105',
    orderNo: 'ORD20260804-03',
    clientName: '陆依柔',
    clientAvatar: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150&auto=format&fit=crop&q=80',
    serviceType: '50min_video',
    serviceTypeName: '50分钟标准视频咨询',
    bookingDate: '2026-08-04',
    bookingTimeSlot: '15:00 - 15:50',
    price: 500,
    status: 'scheduled',
    preMoodScore: 6,
    complaintTopic: '转行期间的职业迷茫与自我否定',
    note: '预预约明日下午，已预读其填写的心情随笔。',
    hasSummary: false,
    createdAt: '2026-08-02 20:15'
  },
  {
    id: 'ord_106',
    orderNo: 'ORD20260729-02',
    clientName: '赵元浩',
    clientAvatar: 'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=150&auto=format&fit=crop&q=80',
    serviceType: '15min_listening',
    serviceTypeName: '15分钟急诊倾听体验',
    bookingDate: '2026-07-29',
    bookingTimeSlot: '21:00 - 21:15',
    price: 39,
    status: 'refunded',
    preMoodScore: 8,
    complaintTopic: '', // test empty topic
    note: '已按平台规则友好办理改期退款，客户表示感谢。',
    hasSummary: false,
    createdAt: '2026-07-29 20:30'
  },
  {
    id: 'ord_107',
    orderNo: 'ORD20260806-01',
    clientName: '郑青',
    clientAvatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80',
    serviceType: '50min_video',
    serviceTypeName: '50分钟标准视频咨询',
    bookingDate: '2026-08-07',
    bookingTimeSlot: '10:00 - 10:50',
    price: 500,
    status: 'pending_reschedule_confirm',
    preMoodScore: 5,
    complaintTopic: '职场人际关系冲突',
    note: '用户申请改期，原定今天下午。',
    hasSummary: false,
    createdAt: '2026-08-05 10:00'
  },
  {
    id: 'ord_108',
    orderNo: 'ORD20260806-02',
    clientName: '周小杰',
    clientAvatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop&q=80',
    serviceType: '15min_listening',
    serviceTypeName: '15分钟急诊倾听体验',
    bookingDate: '2026-08-08',
    bookingTimeSlot: '20:00 - 20:15',
    price: 39,
    status: 'pending_cancel_confirm',
    preMoodScore: 7,
    complaintTopic: '情绪极度焦虑',
    note: '用户申请规则外取消。',
    hasSummary: false,
    createdAt: '2026-08-05 15:30'
  }
];

export const INITIAL_SERVICE_PRODUCTS: ServiceProduct[] = [
  {
    id: 'prod_1',
    name: '50分钟标准深度咨询',
    type: '50min_video',
    durationMinutes: 50,
    price: 500,
    salesCount: 312,
    isPublished: true,
    description: '高清视频/语音双选，一对一系统探索情绪与生活议题，支持评估、干预与复盘。',
  },
  {
    id: 'prod_2',
    name: '15分钟急诊倾听体验',
    type: '15min_listening',
    durationMinutes: 15,
    price: 39,
    salesCount: 184,
    isPublished: true,
    description: '适合急性情绪排毒、突发焦虑接纳，无门槛体验即时温暖陪伴。',
  }
];

export const INITIAL_SETTLEMENTS: SettlementRecord[] = [
  {
    id: 'set_202607B',
    period: '2026年07月（下半月）',
    totalAmount: 14200.00,
    platformFee: 1704.00, // 12%
    taxAmount: 426.00,
    netAmount: 12070.00,
    payoutStatus: 'paid',
    payoutDate: '2026-08-01'
  },
  {
    id: 'set_202607A',
    period: '2026年07月（上半月）',
    totalAmount: 12800.00,
    platformFee: 1536.00,
    taxAmount: 384.00,
    netAmount: 10880.00,
    payoutStatus: 'paid',
    payoutDate: '2026-07-16'
  },
  {
    id: 'set_202606B',
    period: '2026年06月（下半月）',
    totalAmount: 11500.00,
    platformFee: 1380.00,
    taxAmount: 345.00,
    netAmount: 9775.00,
    payoutStatus: 'paid',
    payoutDate: '2026-07-01'
  }
];

export const INITIAL_VIRAL_VOUCHERS: ViralVoucher[] = [
  {
    id: 'vouch_1',
    title: '【新手疏导】15分钟倾听体验券',
    code: 'HEAR2026',
    discountType: 'amount_off',
    discountValue: 20,
    originalPrice: 39,
    voucherPrice: 19,
    claimedCount: 88,
    conversionCount: 34,
    isEnabled: true
  },
  {
    id: 'vouch_2',
    title: '【友邻分享】首诊50元抵扣券',
    code: 'WARM50',
    discountType: 'amount_off',
    discountValue: 50,
    originalPrice: 500,
    voucherPrice: 450,
    claimedCount: 45,
    conversionCount: 18,
    isEnabled: true
  },
  {
    id: 'vouch_3',
    title: '【复购关怀】4次疗程专属¥150现金券',
    code: 'RENEW150',
    discountType: 'amount_off',
    discountValue: 150,
    originalPrice: 1800,
    voucherPrice: 1650,
    claimedCount: 22,
    conversionCount: 15,
    isEnabled: true
  }
];

export const PRESET_THEME_QUOTES: TherapyQuote[] = [
  {
    id: 'q_1',
    title: '接纳与停顿',
    quote: '情绪就像天气，阴晴雨雪都是自然。你不需要每天都充满阳光，允许自己有阴天，也是一种勇敢。',
    tag: '情绪接纳',
    authorNote: '适合在周一早晨或压力期分享给职场朋友'
  },
  {
    id: 'q_2',
    title: '自我关怀',
    quote: '当我们学会不再苛责自己时，内心的声音才会变得温柔。最深沉的治愈，始于第一次对自己说“没关系的”。',
    tag: '自我慈悲',
    authorNote: '表达无条件积极关注'
  },
  {
    id: 'q_3',
    title: '心理边界',
    quote: '拒绝不是冷漠，而是为你心灵的房间留出通风的窗户。清清晰晰的边界，是对自己和他人最大的尊重。',
    tag: '边界力量',
    authorNote: '帮助建立健康的人际交往'
  }
];

export const REVENUE_MONTHLY_DATA = [
  { month: '3月', 收入: 16800, 咨询时长: 110, 裂变转化: 12 },
  { month: '4月', 收入: 19200, 咨询时长: 125, 裂变转化: 15 },
  { month: '5月', 收入: 21500, 咨询时长: 140, 裂变转化: 18 },
  { month: '6月', 收入: 23000, 咨询时长: 152, 裂变转化: 22 },
  { month: '7月', 收入: 27000, 咨询时长: 178, 裂变转化: 28 },
  { month: '8月(预估)', 收入: 31000, 咨询时长: 195, 裂变转化: 35 },
];

export const INITIAL_BANK_ACCOUNTS: BankAccount[] = [
  {
    id: 'bank_1',
    accountType: 'bank_card',
    bankName: '招商银行 (上海静安支行)',
    cardNumber: '6222 0210 **** 8821',
    accountHolder: '林木青',
    phone: '138****9201',
    isDefault: true
  },
  {
    id: 'bank_2',
    accountType: 'wechat',
    bankName: '微信支付绑定零钱',
    cardNumber: 'wx_linmuqing_psy',
    accountHolder: '林木青',
    phone: '138****9201',
    isDefault: false
  }
];

export const INITIAL_WITHDRAWAL_RECORDS: WithdrawalRecord[] = [
  {
    id: 'wd_101',
    withdrawNo: 'WD20260802001',
    amount: 5000.00,
    bankAccount: {
      bankName: '招商银行 (上海静安支行)',
      cardNumber: '6222 0210 **** 8821',
      accountHolder: '林木青'
    },
    status: 'success',
    applyTime: '2026-08-02 10:15',
    completedTime: '2026-08-02 16:30',
    financeNote: '已通过网银打款成功 (凭证号: PAY202608029912)'
  },
  {
    id: 'wd_102',
    withdrawNo: 'WD20260801002',
    amount: 3200.00,
    bankAccount: {
      bankName: '微信支付绑定零钱',
      cardNumber: 'wx_linmuqing_psy',
      accountHolder: '林木青'
    },
    status: 'success',
    applyTime: '2026-08-01 14:20',
    completedTime: '2026-08-01 17:00',
    financeNote: '微信商户后台代付完成'
  },
  {
    id: 'wd_103',
    withdrawNo: 'WD20260728003',
    amount: 2000.00,
    bankAccount: {
      bankName: '招商银行 (上海静安支行)',
      cardNumber: '6222 0210 **** 8821',
      accountHolder: '林木青'
    },
    status: 'failed',
    applyTime: '2026-07-28 09:10',
    completedTime: '2026-07-28 11:00',
    rejectReason: '提交卡号与银行预留姓名校验不一致，已解冻退回余额，请更新银行卡后再试'
  }
];

export const INITIAL_BILL_RECORDS: BillRecord[] = [
  {
    id: 'bill_101',
    billNo: 'BILL20260803-01',
    orderId: 'ord_101',
    orderNo: 'ORD20260803-01',
    clientName: '林海燕',
    clientAvatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80',
    serviceTypeName: '50分钟标准视频咨询',
    bookingDate: '2026-08-03',
    bookingTimeSlot: '10:30 - 11:20',
    grossAmount: 500.00,
    platformFee: 60.00,
    netAmount: 440.00,
    status: 'pending_settlement',
    createdAt: '2026-08-01 14:20'
  },
  {
    id: 'bill_102',
    billNo: 'BILL20260803-02',
    orderId: 'ord_102',
    orderNo: 'ORD20260803-02',
    clientName: '陈子健',
    clientAvatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop&q=80',
    serviceTypeName: '15分钟急诊倾听体验',
    bookingDate: '2026-08-03',
    bookingTimeSlot: '14:00 - 14:15',
    grossAmount: 39.00,
    platformFee: 4.68,
    netAmount: 34.32,
    status: 'pending_settlement',
    createdAt: '2026-08-03 09:10'
  },
  {
    id: 'bill_103',
    billNo: 'BILL20260802-05',
    orderId: 'ord_103',
    orderNo: 'ORD20260802-05',
    clientName: '张薇微',
    clientAvatar: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=150&auto=format&fit=crop&q=80',
    serviceTypeName: '50分钟标准语音咨询',
    bookingDate: '2026-08-02',
    bookingTimeSlot: '16:00 - 16:50',
    grossAmount: 480.00,
    platformFee: 57.60,
    netAmount: 422.40,
    status: 'settled',
    createdAt: '2026-07-30 18:00',
    settledAt: '2026-08-02 17:00'
  },
  {
    id: 'bill_104',
    billNo: 'BILL20260801-08',
    orderId: 'ord_104',
    orderNo: 'ORD20260801-08',
    clientName: '许默凡',
    clientAvatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150&auto=format&fit=crop&q=80',
    serviceTypeName: '4次深度探索疗程包 (第1/4次)',
    bookingDate: '2026-08-01',
    bookingTimeSlot: '19:00 - 19:50',
    grossAmount: 1800.00,
    platformFee: 216.00,
    netAmount: 1584.00,
    status: 'settled',
    createdAt: '2026-07-28 11:30',
    settledAt: '2026-08-01 20:00'
  },
  {
    id: 'bill_105',
    billNo: 'BILL20260729-02',
    orderId: 'ord_106',
    orderNo: 'ORD20260729-02',
    clientName: '赵元浩',
    clientAvatar: 'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=150&auto=format&fit=crop&q=80',
    serviceTypeName: '15分钟急诊倾听体验',
    bookingDate: '2026-07-29',
    bookingTimeSlot: '21:00 - 21:15',
    grossAmount: 39.00,
    platformFee: 0.00,
    netAmount: 0.00,
    status: 'refunded',
    createdAt: '2026-07-29 20:30'
  },
  {
    id: 'bill_106',
    billNo: 'BILL20260725-01',
    clientName: '林海燕',
    clientAvatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80',
    serviceTypeName: '50分钟标准视频咨询',
    bookingDate: '2026-07-25',
    bookingTimeSlot: '10:30 - 11:20',
    grossAmount: 500.00,
    platformFee: 60.00,
    netAmount: 440.00,
    status: 'settled',
    createdAt: '2026-07-23 09:00',
    settledAt: '2026-07-25 12:00'
  }
];
