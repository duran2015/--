import type {
  ArchivedSessionReview,
  ConsultationWorkflowState,
  Order,
  SessionReviewDraft,
  SessionSnapshot,
  WorkflowMessage,
  WorkflowTask,
} from "./types";
import { hasIntakeData } from "./intakeData";

export type ReviewSubmissionResult = {
  ok: boolean;
  state: ConsultationWorkflowState;
  errors: string[];
};

const emptyClinicalSummary = (): SessionReviewDraft["clinicalSummary"] => ({
  mainConcern: "",
  clientState: "",
  interventions: [],
  observations: "",
  riskReview: "",
  nextPlan: "",
});

const emptyClientSummary = (): SessionReviewDraft["clientSummary"] => ({
  recap: "",
  actionItems: [],
  nextPlan: "",
});

export const emptyWorkflowState = (): ConsultationWorkflowState => ({
  reviewDrafts: [],
  tasks: [],
  messages: [],
  settlements: {},
  snapshots: {},
  archivedReviews: [],
});

const getSessionId = (orderId: string) => `session-${orderId}`;
const getDraftId = (orderId: string) => `draft-${orderId}`;

const actorIds = (order: Order) => ({
  clientId: order.clientId || `client-${order.id}`,
  counselorId: (order as Order & { counselorId?: string }).counselorId || "c1",
});

const buildReviewDraft = (
  order: Order,
  snapshot: SessionSnapshot,
  timestamp: string,
): SessionReviewDraft => {
  const { clientId, counselorId } = actorIds(order);
  return {
    id: getDraftId(order.id),
    sessionId: getSessionId(order.id),
    orderId: order.id,
    clientId,
    counselorId,
    status: "draft",
    version: 1,
    sourceSnapshot: {
      transcriptSegmentIds: snapshot.transcript.map((item) => item.id),
      insightIds: snapshot.insights.map((item) => item.id),
      noteIds: snapshot.notes.map((item) => item.id),
      intakeAvailable: hasIntakeData(order),
      priorRecordIds: [],
    },
    clinicalSummary: emptyClinicalSummary(),
    clientSummary: emptyClientSummary(),
    updatedAt: timestamp,
  };
};

const buildReviewTasks = (order: Order, draft: SessionReviewDraft, timestamp: string): WorkflowTask[] => [
  {
    id: `task-review-${order.id}`,
    actorRole: "counselor",
    actorId: draft.counselorId,
    taskType: "complete_session_review",
    status: "pending",
    blockingSettlement: true,
    orderId: order.id,
    sessionId: draft.sessionId,
    draftId: draft.id,
    createdAt: timestamp,
  },
];

const buildCounselorMessage = (order: Order, draft: SessionReviewDraft, timestamp: string): WorkflowMessage => ({
  id: `message-summary-${order.id}`,
  orderId: order.id,
  messageType: "summary_card",
  audience: "counselor",
  sessionId: draft.sessionId,
  draftId: draft.id,
  status: "pending_review",
  title: "本次咨询总结待确认",
  description: `${order.clientName} 的 AI 草稿已准备，请完成复核后提交。`,
  actionLabel: "确认总结",
  createdAt: timestamp,
  updatedAt: timestamp,
});

export function endSessionWorkflow(
  state: ConsultationWorkflowState,
  order: Order,
  snapshot: SessionSnapshot,
  timestamp: string,
): ConsultationWorkflowState {
  const existing = state.reviewDrafts.find((item) => item.orderId === order.id);
  if (existing) return state;

  const draft = buildReviewDraft(order, snapshot, timestamp);
  return {
    ...state,
    reviewDrafts: [...state.reviewDrafts, draft],
    tasks: [
      ...state.tasks.map((task) =>
        task.orderId === order.id && task.taskType === "enter_session"
          ? { ...task, status: "completed" as const }
          : task,
      ),
      ...buildReviewTasks(order, draft, timestamp),
    ],
    messages: [...state.messages, buildCounselorMessage(order, draft, timestamp)],
    settlements: { ...state.settlements, [order.id]: "blocked_by_summary" },
    snapshots: { ...state.snapshots, [draft.sessionId]: snapshot },
  };
}

export function saveReviewDraft(
  state: ConsultationWorkflowState,
  draftId: string,
  patch: Partial<SessionReviewDraft>,
  timestamp: string,
): ConsultationWorkflowState {
  return {
    ...state,
    reviewDrafts: state.reviewDrafts.map((draft) => {
      if (draft.id !== draftId || draft.status === "submitted") return draft;

      const { counselorReflection: _legacyDraftReflection, ...currentMvpDraft } = draft;
      const { counselorReflection: _legacyReflection, ...currentMvpPatch } = patch;
      return {
        ...currentMvpDraft,
        ...currentMvpPatch,
        status: "draft",
        clinicalSummary: { ...draft.clinicalSummary, ...patch.clinicalSummary },
        clientSummary: { ...draft.clientSummary, ...patch.clientSummary },
        version: draft.version + 1,
        updatedAt: timestamp,
      };
    }),
  };
}

export function validateReviewDraft(draft: SessionReviewDraft): string[] {
  const errors: string[] = [];
  const clinical = draft.clinicalSummary;
  const client = draft.clientSummary;
  if (
    !clinical.mainConcern.trim() ||
    !clinical.clientState.trim() ||
    clinical.interventions.length === 0 ||
    !clinical.observations.trim() ||
    !clinical.riskReview.trim() ||
    !clinical.nextPlan.trim()
  ) {
    errors.push("请完善临床总结");
  }
  if (!client.recap.trim() || client.actionItems.length === 0 || !client.nextPlan.trim()) {
    errors.push("请完善用户可见回顾");
  }
  return errors;
}

export function normalizeConsultationWorkflow(
  state: ConsultationWorkflowState,
): ConsultationWorkflowState {
  return {
    ...state,
    tasks: state.tasks.filter((task) => (task.taskType as string) !== "counselor_reflection"),
  };
}

export function completeIntakeReviewWorkflow(
  state: ConsultationWorkflowState,
  orderId: string,
): ConsultationWorkflowState {
  return {
    ...state,
    tasks: state.tasks.map((task) =>
      task.orderId === orderId &&
      task.actorRole === "counselor" &&
      task.taskType === "review_intake" &&
      (task.status === "pending" || task.status === "in_progress")
        ? { ...task, status: "completed" as const }
        : task,
    ),
  };
}

const buildClientMessage = (draft: SessionReviewDraft, timestamp: string): WorkflowMessage => ({
  id: `message-client-summary-${draft.orderId}`,
  orderId: draft.orderId,
  messageType: "summary_card",
  audience: "client",
  sessionId: draft.sessionId,
  draftId: draft.id,
  status: "shared",
  title: "本次咨询回顾",
  description: draft.clientSummary.recap,
  actionLabel: "查看回顾并评价",
  clientSummary: draft.clientSummary,
  createdAt: timestamp,
  updatedAt: timestamp,
});

const buildArchivedReview = (
  draft: SessionReviewDraft,
  timestamp: string,
): ArchivedSessionReview => ({
  id: draft.id,
  sessionId: draft.sessionId,
  orderId: draft.orderId,
  clientId: draft.clientId,
  counselorId: draft.counselorId,
  status: "submitted",
  version: draft.version + 1,
  sourceSnapshot: draft.sourceSnapshot,
  clinicalSummary: draft.clinicalSummary,
  clientSummary: draft.clientSummary,
  updatedAt: timestamp,
  submittedAt: timestamp,
});

export function submitReviewDraft(
  state: ConsultationWorkflowState,
  draftId: string,
  timestamp: string,
): ReviewSubmissionResult {
  const draft = state.reviewDrafts.find((item) => item.id === draftId);
  if (!draft) return { ok: false, state, errors: ["未找到咨询总结草稿"] };
  if (draft.status === "submitted") return { ok: true, state, errors: [] };

  const errors = validateReviewDraft(draft);
  if (errors.length > 0) return { ok: false, state, errors };

  const { counselorReflection: _legacyReflection, ...currentMvpDraft } = draft;
  const submittedDraft: SessionReviewDraft = {
    ...currentMvpDraft,
    status: "submitted",
    version: draft.version + 1,
    submittedAt: timestamp,
    updatedAt: timestamp,
  };
  const archivedReview = buildArchivedReview(draft, timestamp);
  const counselorMessageId = `message-summary-${draft.orderId}`;
  const clientMessageId = `message-client-summary-${draft.orderId}`;
  const nextMessages = state.messages.map((message) =>
    message.id === counselorMessageId
      ? {
          ...message,
          status: "submitted" as const,
          title: "总结已提交",
          description: "内部记录已归档，用户可见版已发送。",
          actionLabel: "查看已归档总结",
          updatedAt: timestamp,
        }
      : message,
  );
  if (!nextMessages.some((message) => message.id === clientMessageId)) {
    nextMessages.push(buildClientMessage(submittedDraft, timestamp));
  }

  const clientTasks: WorkflowTask[] = [
    {
      id: `task-recap-${draft.orderId}`,
      actorRole: "client",
      actorId: draft.clientId,
      taskType: "read_session_recap",
      status: "pending",
      blockingSettlement: false,
      orderId: draft.orderId,
      sessionId: draft.sessionId,
      draftId: draft.id,
      createdAt: timestamp,
    },
    {
      id: `task-review-counselor-${draft.orderId}`,
      actorRole: "client",
      actorId: draft.clientId,
      taskType: "review_counselor",
      status: "pending",
      blockingSettlement: false,
      orderId: draft.orderId,
      sessionId: draft.sessionId,
      draftId: draft.id,
      createdAt: timestamp,
    },
  ];

  return {
    ok: true,
    errors: [],
    state: {
      ...state,
      reviewDrafts: state.reviewDrafts.map((item) => (item.id === draft.id ? submittedDraft : item)),
      archivedReviews: state.archivedReviews.some((item) => item.id === draft.id)
        ? state.archivedReviews
        : [...state.archivedReviews, archivedReview],
      tasks: [
        ...state.tasks.map((task) =>
          task.draftId === draft.id && task.actorRole === "counselor"
            ? { ...task, status: "completed" as const }
            : task,
        ),
        ...clientTasks.filter((task) => !state.tasks.some((item) => item.id === task.id)),
      ],
      messages: nextMessages,
      settlements: { ...state.settlements, [draft.orderId]: "eligible_t1" },
    },
  };
}

const emptySnapshot: SessionSnapshot = {
  durationSeconds: 0,
  transcript: [],
  notes: [],
  insights: [],
};

const buildScheduledTasks = (order: Order, timestamp: string): WorkflowTask[] => {
  const { clientId, counselorId } = actorIds(order);
  const intakeAvailable = hasIntakeData(order);
  return [
    {
      id: `task-intake-${order.id}`,
      actorRole: "client",
      actorId: clientId,
      taskType: "complete_intake",
      status: intakeAvailable ? "completed" : "pending",
      blockingSettlement: false,
      orderId: order.id,
      createdAt: timestamp,
    },
    {
      id: `task-enter-${order.id}`,
      actorRole: "counselor",
      actorId: counselorId,
      taskType: "enter_session",
      status: "pending",
      blockingSettlement: false,
      orderId: order.id,
      sessionId: getSessionId(order.id),
      createdAt: timestamp,
    },
    ...(intakeAvailable
      ? [
          {
            id: `task-review-intake-${order.id}`,
            actorRole: "counselor" as const,
            actorId: counselorId,
            taskType: "review_intake" as const,
            status: "pending" as const,
            blockingSettlement: false,
            orderId: order.id,
            createdAt: timestamp,
          },
        ]
      : []),
  ];
};

export function confirmBookingWorkflow(
  state: ConsultationWorkflowState,
  order: Order,
  timestamp: string,
): ConsultationWorkflowState {
  const scheduledTasks = buildScheduledTasks(order, timestamp).filter(
    (task) => !state.tasks.some((existing) => existing.id === task.id),
  );
  return {
    ...state,
    tasks: [
      ...state.tasks.map((task) =>
        task.orderId === order.id && task.taskType === "confirm_booking"
          ? { ...task, status: "completed" as const }
          : task,
      ),
      ...scheduledTasks,
    ],
  };
}

export function seedWorkflowFromOrders(
  orders: Order[],
  timestamp: string,
  snapshotFactory: (order: Order) => SessionSnapshot = () => emptySnapshot,
): ConsultationWorkflowState {
  return orders.reduce((state, order) => {
    const { counselorId } = actorIds(order);
    // 模式一：支付成功即确认，不创建“咨询师接单”待办。
    // pending_confirm 仅作为旧数据兼容，按已确认预约生成后续履约任务。
    if (order.status === "scheduled" || order.status === "pending_confirm") {
      return {
        ...state,
        tasks: [...state.tasks, ...buildScheduledTasks(order, timestamp)],
      };
    }
    if (order.status === "completed" && !order.hasSummary) {
      return endSessionWorkflow(state, order, snapshotFactory(order), timestamp);
    }
    return state;
  }, emptyWorkflowState());
}
