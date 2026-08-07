import { Counselor, TodayTask, UserProfile, AssessmentRecord } from "./types";

export const mockUser: UserProfile = {
  id: "u1",
  name: "新用户",
  avatar: "https://ui-avatars.com/api/?name=User&background=random",
  statusScore: 72,
  statusTrend: 8,
  statusSummary: "最近压力有所下降，睡眠质量有待提高。",
  isNewUser: false,
  hasRisk: false,
  role: "active",
  usedTrialCount: 0,
};

export const mockAssessmentRecords: AssessmentRecord[] = [
  {
    id: "rec_1",
    assessmentId: "PHQ-9",
    title: "抑郁症筛查量表 (PHQ-9)",
    date: new Date(Date.now() - 86400000 * 3).toISOString().split('T')[0], // 3 days ago
    score: 8,
    result: "轻度抑郁倾向",
    tagsGenerated: ["轻度情绪低落", "睡眠困扰"]
  },
  {
    id: "rec_2",
    assessmentId: "GAD-7",
    title: "广泛性焦虑障碍量表 (GAD-7)",
    date: new Date(Date.now() - 86400000 * 15).toISOString().split('T')[0], // 15 days ago
    score: 12,
    result: "中度焦虑",
    tagsGenerated: ["过度担忧", "容易疲劳"]
  }
];

export const mockOrders: any[] = [
  {
    id: "ord_1001",
    counselorId: "c1",
    date: "11-20",
    time: "14:00-14:50",
    type: "voice",
    price: 300,
    status: "paid",
    createdAt: new Date(Date.now() - 3600000).toISOString(),
  },
  {
    id: "ord_1002",
    counselorId: "c2",
    date: "11-21",
    time: "10:00-10:50",
    type: "video",
    price: 450,
    status: "pending",
    createdAt: new Date().toISOString(),
  },
  {
    id: "ord_1003",
    counselorId: "c1",
    date: "11-18",
    time: "15:30-16:20",
    type: "text",
    price: 300,
    status: "completed",
    createdAt: new Date(Date.now() - 86400000 * 2).toISOString(),
    counselorNotesWritten: true,
    isEvaluated: false,
  },
  {
    id: "ord_1004",
    counselorId: "c2",
    date: "11-15",
    time: "09:00-09:50",
    type: "voice",
    price: 450,
    status: "cancelled",
    createdAt: new Date(Date.now() - 86400000 * 5).toISOString(),
  },
  {
    id: "ord_1005",
    counselorId: "c1",
    date: "11-10",
    time: "14:00-14:50",
    type: "video",
    price: 300,
    status: "refunded",
    createdAt: new Date(Date.now() - 86400000 * 10).toISOString(),
  },
  {
    id: "ord_1006",
    counselorId: "c2",
    date: "11-09",
    time: "10:00-10:50",
    type: "text",
    price: 450,
    status: "failed",
    createdAt: new Date(Date.now() - 86400000 * 11).toISOString(),
  },
  {
    id: "ord_1007",
    counselorId: "c1",
    date: "今天",
    time: "15:00-15:50",
    type: "text",
    price: 300,
    status: "completed",
    createdAt: new Date(Date.now() - 3600000).toISOString(),
    counselorNotesWritten: false,
    isEvaluated: false,
  }
];

export const mockCounselors: Counselor[] = [
  {
    id: "c1",
    name: "林静",
    avatar: "https://ui-avatars.com/api/?name=Lin&background=random",
    title: "国家二级心理咨询师",
    tags: ["情绪管理", "学业焦虑", "人际关系"],
    price: 300,
    rating: 4.9,
    reviewsCount: 128,
    consultationCount: 2340,
    serviceHours: 5200,
    about:
      "从业8年，擅长使用认知行为疗法（CBT）和正念疗法，帮助大学生群体缓解考试焦虑、就业迷茫和人际关系冲突，陪伴你走过人生的低谷。",
    specialties: [
      "情绪压力",
      "职场心理",
      "个人成长",
      "睡眠困扰",
    ],
    styles: ["温柔耐心", "专业见解深", "认知行为学派"],
    credentials: [
      "国家注册系统心理咨询师",
      "CBT 认知行为学派认证",
      "8年+ 临床咨询经验",
      "心理学硕士",
    ],
    type: "pro",
    status: "online",
    schedules: [
      {
        date: "11-20",
        label: "今天",
        isFull: false,
        times: ["14:00", "15:30", "19:00"],
      },
      {
        date: "11-21",
        label: "明天",
        isFull: false,
        times: ["09:00", "10:30", "14:00", "16:00"],
      },
      { date: "11-22", label: "周五", isFull: true, times: [] },
      { date: "11-23", label: "周六", isFull: false, times: ["10:00"] },
    ],
  },
  {
    id: "c2",
    name: "张宇",
    avatar: "https://ui-avatars.com/api/?name=Zhang&background=random",
    title: "临床心理学硕士",
    tags: ["失眠困扰", "抑郁情绪", "原生家庭"],
    price: 450,
    rating: 4.8,
    reviewsCount: 86,
    consultationCount: 1520,
    serviceHours: 1200,
    about:
      "致力于解决由于原生家庭带来的心理创伤，以及长期高压导致的睡眠障碍。通过精神分析与人本主义结合的方式，带你重新认识自己。",
    specialties: ["家庭关系", "睡眠困扰", "个人成长"],
    styles: ["一针见血", "精神分析", "人本主义"],
    credentials: [
      "临床心理学硕士",
      "精神分析动力学认证",
      "5年+ 临床咨询经验",
    ],
    type: "listener",
    status: "busy",
    schedules: [
      { date: "11-20", label: "今天", isFull: true, times: [] },
      {
        date: "11-21",
        label: "明天",
        isFull: false,
        times: ["10:00", "14:00"],
      },
      {
        date: "11-23",
        label: "周六",
        isFull: false,
        times: ["09:00", "11:00", "15:00"],
      },
    ],
  },
];

export const mockTodayTask: TodayTask = {
  id: "t1",
  title: "4-7-8 呼吸放松",
  duration: "5 分钟",
  reason:
    "你最近反映睡前容易焦虑，这个练习可以帮助你快速平静下来，为入睡做准备。",
  type: "breathing",
};

export const mockConsultationRecords: any[] = [
  {
    id: "req-1",
    counselorId: "c1",
    date: "今天",
    type: "voice",
    status: "paid",
    messages: [
      { role: "user", content: "医生你好，我今天下午2点准时上线。" },
      { role: "counselor", content: "好的，我已经收到你的预约，请提前准备好安静的环境。如果遇到网络问题可以随时在这里留言。" },
      { role: "user", content: "收到，麻烦您了。" }
    ]
  },
  {
    id: "ord_1001",
    counselorId: "c1",
    date: "今天",
    type: "voice",
    status: "paid",
    messages: [
      { role: "user", content: "林老师你好，我今天下午2点准时上线。" },
      { role: "counselor", content: "好的，我已经收到你的预约，请提前准备好安静的环境。如果遇到网络问题可以随时在这里留言。" },
      { role: "user", content: "收到，麻烦您了。" }
    ]
  },
  {
    id: "r1",
    counselorId: "c1",
    date: "今天",
    type: "text",
    messages: [
      { role: "user", content: "林老师，我最近压力很大，总觉得什么都做不好。" },
      { role: "counselor", content: "我听到了。可以具体说说是什么事情让你有这种感觉吗？慢慢来，我在这里听你讲。" },
    ]
  },
  {
    id: "r3",
    counselorId: "c2",
    date: "今天",
    type: "voice",
    status: "active",
    messages: []
  },
  {
    id: "r2",
    counselorId: "c2",
    date: "11-18",
    type: "voice",
    duration: 50,
    summary: "用户探讨了与父母沟通时经常产生的窒息感。我们在通话中梳理了引发情绪的具体场景，并练习了如何温和但坚定地表达自己的边界。",
    counselorNotes: "建议下次尝试在非冲突情境下，先用写信的方式和父母进行一次简短的情感表达。注意保持日常的深呼吸放松练习。",
    messages: [
      { role: "user", content: "张老师，我刚刚麦克风好像有点问题，你能听到吗？", timestamp: "14:02" },
      { role: "counselor", content: "现在听到了，没关系，我们慢慢来。", timestamp: "14:03" },
      { role: "user", content: "我刚刚说到我爸妈总是干涉我的选择，这让我觉得快窒息了。", timestamp: "14:15" },
      { role: "counselor", content: "嗯，这种感觉一定很沉重。你在那一刻身体有什么反应吗？", timestamp: "14:16" }
    ]
  }
];
export const mockNotifications: any[] = [
  {
    id: "n1",
    title: "预约成功提醒",
    type: "booking",
    date: "今天 10:30",
    preview: "您已成功预约倾听师 林静 的服务。时间：11-20 14:00。",
    content: "您好，\n\n您已成功预约倾听师 林静 的服务。\n\n预约时间：11-20 14:00\n咨询方式：文字咨询\n\n请在约定的时间提前 5 分钟进入 APP 准备。如果您需要取消或更改时间，请提前至少 24 小时进行操作。\n\n祝您有一个愉快的咨询体验！",
    isRead: false,
  },
  {
    id: "n2",
    title: "量表报告已生成",
    type: "report",
    date: "昨天 15:20",
    preview: "您的最新心理状态评估报告已经生成，点击查看详细分析。",
    content: "您好，\n\n您的最新心理状态评估报告已经生成。\n\n根据您的评估结果，您的状态处于良好水平。请点击下方链接查看详细分析报告。\n\n祝您生活愉快！",
    isRead: true,
  },
  {
    id: "n3",
    title: "系统维护通知",
    type: "system",
    date: "11-18 09:00",
    preview: "系统将于本周日凌晨 2:00-4:00 进行停机维护，期间服务将暂停。",
    content: "尊敬的用户：\n\n为了给您提供更好的服务体验，系统将于本周日（11月24日）凌晨 2:00-4:00 进行停机维护。\n\n维护期间，APP内的所有服务将暂停使用，请您提前做好安排。\n\n给您带来的不便，敬请谅解！",
    isRead: true,
  }
];
