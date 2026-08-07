# Compact Counselor Workbench Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restore the counselor workbench to one compact current-task row per case while preserving the complete serialized workflow in the data layer.

**Architecture:** Keep `buildCounselorJourneys(orders, tasks)` as the sole selector of one current task per order. Change only the `WorkbenchTasks` presentation from a four-step timeline card to the former compact row structure, with one status label and one action.

**Tech Stack:** React 19, TypeScript, Zustand, Tailwind CSS, Node test runner, React server rendering

## Global Constraints

- Each order renders at most one row and one action button.
- Row information is limited to avatar, client name, current-node status, one-line description, appointment time, and the current action.
- Do not render the four-step timeline, completed checks, skipped nodes, or future locks on the homepage.
- Preserve the underlying `确认预约 → 查阅资料 → 开始咨询 → 确认总结` workflow and `buildCounselorJourneys` projection.
- Current-node labels are `预约等待确认`, `前序资料待查阅`, `即将开始咨询`, and `待确认总结`.
- Action labels are `确认`, `查看`, `进入`, and `确认总结`; never render `复盘`.
- Only a blocking summary task may render `完成后进入 T+1 结算`.
- Preserve existing actions, including completing intake review in the client-file drawer.

---

### Task 1: Render one compact current-task row per case

**Files:**
- Create: `src/workbenchTasksPresentation.test.ts`
- Modify: `src/components/Workbench/WorkbenchTasks.tsx`

**Interfaces:**
- Consumes: `buildCounselorJourneys(orders: Order[], tasks: WorkflowTask[]): CounselorJourney[]`
- Preserves: `WorkbenchTasksProps` and all existing callbacks
- Produces: one compact `<article>` per `CounselorJourney`, with exactly one current-task button

- [ ] **Step 1: Write the failing presentation test**

Create `src/workbenchTasksPresentation.test.ts` with a real server render of the component:

```tsx
import assert from "node:assert/strict";
import test from "node:test";
import React from "react";
import { renderToStaticMarkup } from "react-dom/server";

import { useAppStore } from "./client-app/store";
import { WorkbenchTasks } from "./components/Workbench/WorkbenchTasks";
import type { Order, WorkflowTask } from "./types";

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
  blockingSettlement: false,
  orderId: order.id,
  createdAt: "2026-08-06T10:00:00.000Z",
};

test("workbench renders one compact current-task row without the journey timeline", (t) => {
  const previousWorkflow = useAppStore.getState().consultationWorkflow;
  useAppStore.setState({
    consultationWorkflow: { ...previousWorkflow, tasks: [reviewTask] },
  });
  t.after(() => useAppStore.setState({ consultationWorkflow: previousWorkflow }));

  const markup = renderToStaticMarkup(
    <WorkbenchTasks
      orders={[order]}
      onConfirmOrder={() => undefined}
      onEnterRoom={() => undefined}
      onWriteSummary={() => undefined}
      onSendReminder={() => undefined}
      onViewClientFile={() => undefined}
    />,
  );

  assert.match(markup, /周明宇/);
  assert.match(markup, /前序资料待查阅/);
  assert.match(markup, /用户已填写咨询前资料/);
  assert.match(markup, /aria-label="预约时间：2026-08-06 16:00 - 16:50"/);
  assert.match(markup, />查看<\/button>/);
  assert.equal(markup.match(/<article/g)?.length, 1);
  assert.equal(markup.match(/<button/g)?.length, 1);
  assert.doesNotMatch(markup, /<ol/);
  assert.doesNotMatch(markup, /的咨询流程/);
});
```

- [ ] **Step 2: Run the test and verify RED**

Run:

```bash
node --import tsx --test src/workbenchTasksPresentation.test.ts
```

Expected: FAIL because the current component lacks `前序资料待查阅` and still renders the `<ol>` timeline.

- [ ] **Step 3: Replace the timeline presentation with compact rows**

In `src/components/Workbench/WorkbenchTasks.tsx`:

1. Remove `Check`, `Minus`, `CounselorJourneyStep`, `StepNode`, `stepNodeClasses`, and `connectorClasses`.
2. Extend each current-task descriptor with `statusText`:

```tsx
type CurrentTaskDescriptor = {
  statusText: string;
  desc: string;
  btnText: string;
};

const currentTaskDescriptors: Partial<Record<WorkflowTaskType, CurrentTaskDescriptor>> = {
  confirm_booking: {
    statusText: "预约等待确认",
    desc: "确认后创建资料收集与入室待办",
    btnText: "确认",
  },
  review_intake: {
    statusText: "前序资料待查阅",
    desc: "用户已填写咨询前资料",
    btnText: "查看",
  },
  enter_session: {
    statusText: "即将开始咨询",
    desc: "咨询室已准备就绪",
    btnText: "进入",
  },
  complete_session_review: {
    statusText: "待确认总结",
    desc: "AI 草稿已生成 · 提交前结算锁定",
    btnText: "确认总结",
  },
};
```

3. Keep the existing `journeys` memo and action routing. Replace each timeline card with this compact structure:

```tsx
<article key={order.id} className="flex w-full items-center justify-between gap-3 py-3 first:pt-0 last:pb-0">
  <div className="flex min-w-0 items-center gap-3">
    <img
      src={order.clientAvatar}
      alt=""
      className="h-12 w-12 shrink-0 rounded-full border border-[#ECE6DC] bg-[#FAF8F5] object-cover"
    />
    <div className="min-w-0 pr-1">
      <div className="flex min-w-0 items-center gap-2">
        <span className="truncate text-[15px] font-bold text-[#1D1B16]">{order.clientName}</span>
        <span className="shrink-0 text-[12px] font-medium text-[#7A756C]">{descriptor.statusText}</span>
      </div>
      <div className="mt-0.5 truncate text-[12px] text-[#7A756C]">{descriptor.desc}</div>
      {currentTask.blockingSettlement && (
        <div className="mt-1 flex items-center gap-1 text-[10px] font-bold text-[#8A5100]">
          <LockKeyhole size={11} />完成后进入 T+1 结算
        </div>
      )}
    </div>
  </div>
  <div className="ml-auto flex shrink-0 items-center gap-2">
    <time
      aria-label={`预约时间：${journey.appointmentLabel}`}
      title={journey.appointmentLabel}
      className="w-[46px] truncate text-right font-mono text-[10px] font-medium text-[#7A756C]"
    >
      {order.bookingTimeSlot.split(" ")[0]}
    </time>
    <button type="button" onClick={handleCurrentTask} className={buttonClassForCurrentTask}>
      {descriptor.btnText}
    </button>
  </div>
</article>
```

Use the former task-specific Material 3 button emphasis: purple filled for `enter_session`, light purple for `complete_session_review`, and neutral tonal for confirmation/review. Keep a visible `focus-visible` outline for every button.

Render the rows inside a divider list rather than adding per-row bordered cards:

```tsx
<div className="divide-y divide-[#F0ECE6]">
  {/* compact rows */}
</div>
```

- [ ] **Step 4: Run focused and full verification**

Run:

```bash
node --import tsx --test src/workbenchTasksPresentation.test.ts src/workbenchJourney.test.ts
npm test
npm run lint
npm run build
git diff --check
```

Expected: focused and full tests pass, TypeScript exits 0, production build exits 0, and diff check has no output. The existing Vite chunk-size warning may remain.

- [ ] **Step 5: Browser acceptance**

At `/counselor`, verify:

- each case appears once as a compact row;
- there is no four-step timeline;
- each row has exactly one current action;
- `查看` still opens the client file and `完成查阅，继续下一步` advances the row to `进入`;
- no browser console errors are emitted.

- [ ] **Step 6: Commit**

```bash
git add src/components/Workbench/WorkbenchTasks.tsx src/workbenchTasksPresentation.test.ts
git commit -m "fix: compact counselor workbench tasks"
```

