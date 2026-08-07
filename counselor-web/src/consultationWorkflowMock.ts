import type { Order, SessionReviewDraft, SessionSnapshot } from "./types";

export function buildMockReviewPatch(order: Order): Partial<SessionReviewDraft> {
  const topic = order.complaintTopic?.trim() || "近期压力与情绪波动";
  return {
    clinicalSummary: {
      mainConcern: `${topic}，并伴随睡眠及自我评价方面的困扰。`,
      clientState: "会谈初期紧绷、语速偏快；梳理自动化想法后情绪逐步稳定。",
      interventions: ["CBT 认知重构", "情绪命名与躯体觉察", "呼吸稳定练习"],
      observations: "来访者能够区分事实与自我判断，并形成澄清工作优先级的替代行动。",
      riskReview: "本次会谈未发现即时自伤或他伤风险，建议持续观察睡眠与压力变化。",
      nextPlan: "下次复盘睡前想法记录，继续练习工作边界表达与压力调节。",
    },
    clientSummary: {
      recap: "本次一起梳理了工作压力、睡眠和自我评价之间的联系，也找到了一种更贴近事实的看法。",
      actionItems: ["睡前记录一次自动想法", "完成四轮呼吸练习", "向负责人确认任务优先级"],
      nextPlan: "下次会谈继续回看睡眠变化，并练习更稳定地表达需求和边界。",
    },
  };
}

export function buildMockSessionSnapshot(order: Order): SessionSnapshot {
  const sessionId = `session-${order.id}`;
  const clientName = order.clientName || "来访者";
  const transcript = [
    {
      id: `${sessionId}-t1`,
      sessionId,
      speakerRole: "counselor" as const,
      speakerName: "林木青",
      text: "上次你提到工作调整后睡眠变差，这一周最明显的变化是什么？",
      startsAtSeconds: 65,
      endsAtSeconds: 73,
      confidence: 0.98,
      highlightTerms: ["睡眠"],
    },
    {
      id: `${sessionId}-t2`,
      sessionId,
      speakerRole: "client" as const,
      speakerName: clientName,
      text: "一到晚上就会反复想第二天的工作，担心自己做不好，通常两三点才睡。",
      startsAtSeconds: 75,
      endsAtSeconds: 88,
      confidence: 0.96,
      highlightTerms: ["反复想", "担心", "失眠"],
    },
    {
      id: `${sessionId}-t3`,
      sessionId,
      speakerRole: "counselor" as const,
      speakerName: "林木青",
      text: "当‘我可能做不好’出现时，你身体和情绪上会有什么反应？",
      startsAtSeconds: 126,
      endsAtSeconds: 134,
      confidence: 0.97,
      highlightTerms: ["自动想法"],
    },
    {
      id: `${sessionId}-t4`,
      sessionId,
      speakerRole: "client" as const,
      speakerName: clientName,
      text: "胸口会紧，脑子很乱。我觉得同事都比我适应得快，好像只有我不行。",
      startsAtSeconds: 136,
      endsAtSeconds: 148,
      confidence: 0.95,
      highlightTerms: ["胸口紧", "只有我不行"],
    },
    {
      id: `${sessionId}-t5`,
      sessionId,
      speakerRole: "counselor" as const,
      speakerName: "林木青",
      text: "我们先把事实和你对自己的判断分开，再看看有没有更贴近事实的解释。",
      startsAtSeconds: 905,
      endsAtSeconds: 916,
      confidence: 0.98,
      highlightTerms: ["认知重构"],
    },
    {
      id: `${sessionId}-t6`,
      sessionId,
      speakerRole: "client" as const,
      speakerName: clientName,
      text: "这样写下来以后没那么绝对了。我可以先问清楚优先级，不必全部自己扛。",
      startsAtSeconds: 1020,
      endsAtSeconds: 1032,
      confidence: 0.96,
      highlightTerms: ["优先级", "边界"],
    },
    {
      id: `${sessionId}-t7`,
      sessionId,
      speakerRole: "counselor" as const,
      speakerName: "林木青",
      text: "本周先记录一次睡前自动想法，并配合四轮呼吸练习，下次我们一起回看。",
      startsAtSeconds: 2818,
      endsAtSeconds: 2830,
      confidence: 0.98,
      highlightTerms: ["行动计划", "呼吸练习"],
    },
  ];
  const notes = [
    {
      id: `${sessionId}-n1`,
      text: "工作角色调整触发能力焦虑，伴随入睡困难与躯体紧张。",
    },
    {
      id: `${sessionId}-n2`,
      text: "认知重构后情绪强度下降，来访者能够提出澄清优先级的替代行动。",
    },
    {
      id: `${sessionId}-n3`,
      text: "未见即时自伤或他伤风险；下次继续评估睡眠与工作边界。",
    },
  ];

  return {
    durationSeconds: 50 * 60,
    transcript,
    notes,
    insights: [
      {
        id: `${sessionId}-i1`,
        sessionId,
        category: "topic",
        title: "核心议题：工作适应与自我评价",
        detail: "工作职责变化激活了‘能力不足’的自动化判断，并持续影响睡眠。",
        sourceType: "transcript",
        sourceIds: [`${sessionId}-t2`, `${sessionId}-t4`],
        confidence: 0.94,
      },
      {
        id: `${sessionId}-i2`,
        sessionId,
        category: "emotion",
        title: "焦虑伴随躯体紧张",
        detail: "来访者描述胸口紧、思绪混乱，晚间反刍明显。",
        sourceType: "transcript",
        sourceIds: [`${sessionId}-t2`, `${sessionId}-t4`],
        confidence: 0.92,
      },
      {
        id: `${sessionId}-i3`,
        sessionId,
        category: "intervention",
        title: "认知重构产生初步效果",
        detail: "区分事实与自我判断后，来访者生成了询问优先级的替代行动。",
        sourceType: "transcript",
        sourceIds: [`${sessionId}-t5`, `${sessionId}-t6`],
        confidence: 0.91,
      },
      {
        id: `${sessionId}-i4`,
        sessionId,
        category: "risk",
        title: "当前风险：低",
        detail: "会谈及咨询师记录中未发现即时自伤或他伤风险信号。",
        sourceType: "note",
        sourceIds: [`${sessionId}-n3`],
        confidence: 0.87,
      },
      {
        id: `${sessionId}-i5`,
        sessionId,
        category: "plan",
        title: "会后行动",
        detail: "记录睡前自动想法，练习呼吸，并在下次会谈复盘睡眠变化。",
        sourceType: "transcript",
        sourceIds: [`${sessionId}-t7`],
        confidence: 0.96,
      },
    ],
  };
}
