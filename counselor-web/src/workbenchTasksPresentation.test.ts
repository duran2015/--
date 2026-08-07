import assert from "node:assert/strict";
import test from "node:test";
import React from "react";
import { renderToStaticMarkup } from "react-dom/server";

import type { Order, WorkflowTask } from "./types";

const storage = new Map<string, string>();
Object.assign(globalThis, {
  localStorage: {
    getItem: (key: string) => storage.get(key) ?? null,
    setItem: (key: string, value: string) => storage.set(key, value),
    removeItem: (key: string) => storage.delete(key),
    clear: () => storage.clear(),
  },
});

const order: Order = {
  id: "order-compact",
  orderNo: "KL20260806009",
  clientId: "client-compact",
  clientName: "周明宇",
  clientAvatar: "avatar.png",
  serviceType: "50min_video",
  serviceTypeName: "50分钟视频咨询",
  bookingDate: "2026-08-06",
  bookingTimeSlot: "16:00 - 16:50",
  price: 500,
  status: "scheduled",
  complaintTopic: "工作压力与持续失眠",
  createdAt: "2026-08-06T10:00:00.000Z",
  intakeForm: {
    primaryIssueDetail: "近期睡眠不佳",
    expectations: "希望稳定情绪",
    riskAssessmentPassed: true,
    hasCounselingHistory: false,
  },
};

const reviewTask: WorkflowTask = {
  id: "task-review-compact",
  actorRole: "counselor",
  actorId: "c1",
  taskType: "review_intake",
  status: "pending",
  blockingSettlement: true,
  orderId: order.id,
  createdAt: "2026-08-06T10:00:00.000Z",
};

storage.set("kelu-consultation-workflow-v1", JSON.stringify({
  tasks: [reviewTask],
  reviewDrafts: [],
  messages: [],
}));

const { useAppStore } = await import("./client-app/store");
const { WorkbenchTasks } = await import("./components/Workbench/WorkbenchTasks");

test("workbench renders one compact current-task row without the journey timeline", () => {
  const previousWorkflow = useAppStore.getState().consultationWorkflow;
  useAppStore.setState({
    consultationWorkflow: { ...previousWorkflow, tasks: [reviewTask] },
  });

  const markup = renderToStaticMarkup(
    React.createElement(WorkbenchTasks, {
      orders: [order],
      onConfirmOrder: () => undefined,
      onEnterRoom: () => undefined,
      onWriteSummary: () => undefined,
      onSendReminder: () => undefined,
      onViewClientFile: () => undefined,
    }),
  );

  assert.match(markup, /周明宇/);
  assert.match(markup, /前序资料待查阅/);
  assert.match(markup, /用户已填写咨询前资料/);
  assert.match(markup, /aria-label="预约时间：2026-08-06 16:00 - 16:50"/);
  assert.match(markup, />查看<\/button>/);
  assert.doesNotMatch(markup, /完成后进入 T\+1 结算/);
  assert.equal(markup.match(/<article/g)?.length, 1);
  assert.equal(markup.match(/<button/g)?.length, 1);
  assert.doesNotMatch(markup, /<ol/);
  assert.doesNotMatch(markup, /的咨询流程/);
});
