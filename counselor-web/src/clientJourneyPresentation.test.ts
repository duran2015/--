import assert from "node:assert/strict";
import test from "node:test";

import { getClientJourneyPresentation, isStructuredEvaluationComplete } from "./clientJourneyPresentation";
import type { ConsultationWorkflowState, Order } from "./types";

const baseOrder = {
  id: "order-client-flow",
  orderNo: "KL20260807001",
  clientId: "client-1",
  clientName: "周明宇",
  clientAvatar: "avatar.png",
  counselorId: "c1",
  serviceType: "50min_video",
  serviceTypeName: "50分钟视频咨询",
  bookingDate: "2026-08-07",
  bookingTimeSlot: "16:00 - 16:50",
  price: 500,
  status: "scheduled",
  complaintTopic: "工作压力",
  createdAt: "2026-08-07T08:00:00.000Z",
} as Order & { counselorId: string };

const workflow = (overrides: Partial<ConsultationWorkflowState> = {}): ConsultationWorkflowState => ({
  reviewDrafts: [], tasks: [], messages: [], settlements: {}, snapshots: {}, archivedReviews: [], ...overrides,
});

test("confirmed booking asks the client to complete optional intake first", () => {
  const result = getClientJourneyPresentation(baseOrder, workflow({
    tasks: [{ id: "intake", actorRole: "client", actorId: "client-1", taskType: "complete_intake", status: "pending", blockingSettlement: false, orderId: baseOrder.id, createdAt: "now" }],
  }));
  assert.equal(result.statusLabel, "待咨询");
  assert.equal(result.currentLabel, "咨询前资料待填写");
  assert.equal(result.primaryAction, "complete_intake");
});

test("completed session waits for counselor summary before evaluation", () => {
  const result = getClientJourneyPresentation({ ...baseOrder, status: "completed" }, workflow());
  assert.equal(result.statusLabel, "已完成");
  assert.equal(result.primaryAction, "wait_for_summary");
  assert.equal(result.canEvaluate, false);
});

test("shared summary becomes the next client action before evaluation", () => {
  const result = getClientJourneyPresentation({ ...baseOrder, status: "completed", hasSummary: true }, workflow({
    tasks: [
      { id: "recap", actorRole: "client", actorId: "client-1", taskType: "read_session_recap", status: "pending", blockingSettlement: false, orderId: baseOrder.id, createdAt: "now" },
      { id: "review", actorRole: "client", actorId: "client-1", taskType: "review_counselor", status: "pending", blockingSettlement: false, orderId: baseOrder.id, createdAt: "now" },
    ],
    messages: [{ id: "summary", orderId: baseOrder.id, messageType: "summary_card", audience: "client", sessionId: "session-1", draftId: "draft-1", status: "shared", title: "本次咨询回顾", description: "回顾", actionLabel: "查看回顾并评价", createdAt: "now", updatedAt: "now" }],
  }));
  assert.equal(result.currentLabel, "咨询回顾待查看");
  assert.equal(result.statusLabel, "已完成");
  assert.equal(result.primaryAction, "read_summary");
  assert.equal(result.canEvaluate, false);
});

test("evaluation opens only after recap has been read", () => {
  const result = getClientJourneyPresentation({ ...baseOrder, status: "completed", hasSummary: true }, workflow({
    tasks: [
      { id: "recap", actorRole: "client", actorId: "client-1", taskType: "read_session_recap", status: "completed", blockingSettlement: false, orderId: baseOrder.id, createdAt: "now" },
      { id: "review", actorRole: "client", actorId: "client-1", taskType: "review_counselor", status: "pending", blockingSettlement: false, orderId: baseOrder.id, createdAt: "now" },
    ],
  }));
  assert.equal(result.currentLabel, "服务待评价");
  assert.equal(result.statusLabel, "已完成");
  assert.equal(result.primaryAction, "evaluate");
  assert.equal(result.canEvaluate, true);
});

test("negative evaluation answers are valid completed answers", () => {
  assert.equal(isStructuredEvaluationComplete({ feltUnderstood: false, wasHelpful: false }), true);
  assert.equal(isStructuredEvaluationComplete({ feltUnderstood: null, wasHelpful: true }), false);
});
