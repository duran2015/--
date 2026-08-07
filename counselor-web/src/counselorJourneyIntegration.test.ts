import assert from "node:assert/strict";
import test from "node:test";

import {
  completeIntakeReviewWorkflow,
  endSessionWorkflow,
  saveReviewDraft,
  seedWorkflowFromOrders,
  submitReviewDraft,
} from "./consultationWorkflow";
import { buildCounselorJourneys } from "./workbenchJourney";
import type { Order, SessionReviewDraft, SessionSnapshot } from "./types";

const now = "2026-08-06T10:00:00.000Z";

const order = {
  id: "journey-order",
  orderNo: "KL20260806002",
  clientId: "client-2",
  clientName: "许清禾",
  clientAvatar: "avatar.png",
  serviceType: "50min_video",
  serviceTypeName: "50分钟视频咨询",
  bookingDate: "2026-08-06",
  bookingTimeSlot: "18:00 - 18:50",
  price: 500,
  status: "scheduled",
  complaintTopic: "工作变动后持续失眠",
  createdAt: now,
  preQuestionnaire: {
    mainTopic: "工作变动后持续失眠",
    duration: "1-3个月",
    event: "更换直属负责人",
    expectation: "希望恢复稳定睡眠",
    hasCounselingHistory: true,
    hasSelfHarmThoughts: false,
  },
} satisfies Order;

const snapshot: SessionSnapshot = {
  durationSeconds: 50 * 60,
  transcript: [],
  notes: [],
  insights: [],
};

const reviewPatch: Partial<SessionReviewDraft> = {
  clinicalSummary: {
    mainConcern: "工作变动引发焦虑与持续失眠。",
    clientState: "会谈后半程逐渐稳定。",
    interventions: ["CBT 认知重构"],
    observations: "能够识别自动化负面想法。",
    riskReview: "未发现即时风险。",
    nextPlan: "继续记录睡前自动想法。",
  },
  clientSummary: {
    recap: "本次梳理了压力与失眠的联系。",
    actionItems: ["记录一次自动想法"],
    nextPlan: "下次继续练习稳定表达需求。",
  },
};

test("completes one serialized counselor journey from intake review through summary", () => {
  let state = seedWorkflowFromOrders([order], now);
  assert.equal(
    buildCounselorJourneys([order], state.tasks)[0].currentTask.taskType,
    "review_intake",
  );

  state = completeIntakeReviewWorkflow(state, order.id);
  assert.equal(
    buildCounselorJourneys([order], state.tasks)[0].currentTask.taskType,
    "enter_session",
  );

  state = endSessionWorkflow(state, order, snapshot, now);
  assert.equal(
    buildCounselorJourneys([order], state.tasks)[0].currentTask.taskType,
    "complete_session_review",
  );

  state = saveReviewDraft(state, `draft-${order.id}`, reviewPatch, now);
  const submitted = submitReviewDraft(state, `draft-${order.id}`, now);

  assert.equal(submitted.ok, true);
  assert.equal(buildCounselorJourneys([order], submitted.state.tasks).length, 0);
});
