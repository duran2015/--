import assert from "node:assert/strict";
import test from "node:test";

import { getClientReviewProjection, getReviewProgress } from "./sessionReviewPresentation";
import type { SessionReviewDraft } from "./types";

const draft: SessionReviewDraft = {
  id: "draft-1",
  sessionId: "session-1",
  orderId: "order-1",
  clientId: "client-1",
  counselorId: "counselor-1",
  status: "draft",
  version: 1,
  sourceSnapshot: {
    transcriptSegmentIds: ["t1"],
    insightIds: ["i1"],
    noteIds: ["n1"],
    intakeAvailable: true,
    priorRecordIds: [],
  },
  clinicalSummary: {
    mainConcern: "工作焦虑",
    clientState: "逐渐稳定",
    interventions: ["认知重构"],
    observations: "能够形成替代想法",
    riskReview: "当前低风险",
    nextPlan: "继续观察睡眠",
  },
  clientSummary: {
    recap: "梳理了压力与睡眠的联系",
    actionItems: ["记录想法"],
    nextPlan: "下次复盘",
  },
  counselorReflection: {
    allianceQuality: null,
    goalProgress: null,
    reflection: "",
  },
  updatedAt: "2026-08-06T10:00:00.000Z",
};

test("review progress does not require legacy counselor reflection", () => {
  assert.deepEqual(getReviewProgress(draft), {
    completed: 2,
    total: 2,
    percentage: 100,
    missingSections: [],
  });
});

test("client projection never exposes clinical notes or counselor reflection", () => {
  assert.deepEqual(getClientReviewProjection(draft), draft.clientSummary);
  assert.equal("clinicalSummary" in getClientReviewProjection(draft), false);
  assert.equal("counselorReflection" in getClientReviewProjection(draft), false);
});
