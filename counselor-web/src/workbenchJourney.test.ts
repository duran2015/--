import assert from "node:assert/strict";
import test from "node:test";

import { buildCounselorJourneys } from "./workbenchJourney";
import type { Order, WorkflowTask, WorkflowTaskType } from "./types";

const now = "2026-08-06T10:00:00.000Z";

const makeOrder = (overrides: Partial<Order> = {}): Order => ({
  id: "order-1",
  orderNo: "KL20260806001",
  clientId: "client-1",
  clientName: "周明宇",
  clientAvatar: "avatar.png",
  serviceType: "50min_video",
  serviceTypeName: "50分钟视频咨询",
  bookingDate: "2026-08-06",
  bookingTimeSlot: "16:00 - 16:50",
  price: 500,
  status: "scheduled",
  complaintTopic: "工作压力与持续失眠",
  createdAt: now,
  ...overrides,
});

const makeCounselorTask = (
  taskType: Extract<WorkflowTaskType, "confirm_booking" | "review_intake" | "enter_session" | "complete_session_review">,
  orderId: string,
): WorkflowTask => ({
  id: `task-${taskType}-${orderId}`,
  actorRole: "counselor",
  actorId: "c1",
  taskType,
  status: "pending",
  blockingSettlement: taskType === "complete_session_review",
  orderId,
  createdAt: now,
});

test("projects the intake review before a later room task regardless of task order", () => {
  const scheduledWithIntake = makeOrder({
    intakeForm: {
      primaryIssueDetail: "近期睡眠不佳",
      expectations: "希望稳定情绪",
      riskAssessmentPassed: true,
      hasCounselingHistory: false,
    },
  });
  const scheduledTasks = [
    makeCounselorTask("enter_session", scheduledWithIntake.id),
    makeCounselorTask("review_intake", scheduledWithIntake.id),
  ];

  assert.deepEqual(
    buildCounselorJourneys([scheduledWithIntake], scheduledTasks)[0].steps.map((step) => step.status),
    ["completed", "current", "locked", "locked"],
  );
});

test("treats the submitted pre-questionnaire as intake data", () => {
  const scheduledWithQuestionnaire = makeOrder({
    preQuestionnaire: {
      mainTopic: "工作变动后持续失眠",
      duration: "1-3个月",
      event: "更换直属负责人",
      expectation: "希望恢复稳定睡眠",
      hasCounselingHistory: true,
      hasSelfHarmThoughts: false,
    },
  });
  const scheduledTasks = [
    makeCounselorTask("enter_session", scheduledWithQuestionnaire.id),
    makeCounselorTask("review_intake", scheduledWithQuestionnaire.id),
  ];

  const journey = buildCounselorJourneys([scheduledWithQuestionnaire], scheduledTasks)[0];

  assert.equal(journey.currentTask.taskType, "review_intake");
  assert.deepEqual(
    journey.steps.map((step) => step.status),
    ["completed", "current", "locked", "locked"],
  );
});

test("includes the booking date and complete time slot in the journey appointment", () => {
  const order = makeOrder();
  const journey = buildCounselorJourneys(
    [order],
    [makeCounselorTask("enter_session", order.id)],
  )[0];

  assert.equal(journey.appointmentLabel, "2026-08-06 16:00 - 16:50");
});

test("skips intake review when the client did not submit an intake form", () => {
  const scheduledWithoutIntake = makeOrder();
  const roomTask = [makeCounselorTask("enter_session", scheduledWithoutIntake.id)];

  assert.deepEqual(
    buildCounselorJourneys([scheduledWithoutIntake], roomTask)[0].steps.map((step) => step.status),
    ["completed", "skipped", "current", "locked"],
  );
});

test("keeps separate journeys for separate orders belonging to the same client", () => {
  const firstOrder = makeOrder({ id: "order-1", orderNo: "KL20260806001" });
  const secondOrder = makeOrder({ id: "order-2", orderNo: "KL20260806002" });
  const tasksForBoth = [
    makeCounselorTask("enter_session", firstOrder.id),
    makeCounselorTask("enter_session", secondOrder.id),
  ];

  assert.equal(buildCounselorJourneys([firstOrder, secondOrder], tasksForBoth).length, 2);
});

test("makes booking confirmation the current step for a pending confirmation", () => {
  const pendingConfirmation = makeOrder({ status: "pending_confirm" });
  const confirmationTask = [makeCounselorTask("confirm_booking", pendingConfirmation.id)];

  assert.deepEqual(
    buildCounselorJourneys([pendingConfirmation], confirmationTask)[0].steps.map((step) => step.status),
    ["current", "locked", "locked", "locked"],
  );
});

test("makes summary confirmation current after a completed session", () => {
  const completedSession = makeOrder({
    status: "completed",
    intakeForm: {
      primaryIssueDetail: "近期睡眠不佳",
      expectations: "希望稳定情绪",
      riskAssessmentPassed: true,
      hasCounselingHistory: false,
    },
  });
  const summaryTask = [makeCounselorTask("complete_session_review", completedSession.id)];

  assert.deepEqual(
    buildCounselorJourneys([completedSession], summaryTask)[0].steps.map((step) => step.status),
    ["completed", "completed", "completed", "current"],
  );
});
