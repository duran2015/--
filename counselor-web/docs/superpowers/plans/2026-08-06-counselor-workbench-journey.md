# Counselor Workbench Journey Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将咨询师工作台待办改为每笔订单独立的四步串行业务链，并移除当前 MVP 不需要的咨询师专业自评节点。

**Architecture:** `consultationWorkflow` 只生成结算所需的业务任务并规范化旧状态；新的 `workbenchJourney` 纯函数把订单和任务投影成固定四阶段旅程。`WorkbenchTasks` 渲染旅程卡，`SessionReviewWorkspace` 只保留 AI 证据、临床总结和用户回顾。

**Tech Stack:** React 19、TypeScript 5.8、Tailwind CSS 4、Zustand、Node test runner

## Global Constraints

- 每笔订单独立一条 `确认预约 → 查阅资料 → 开始咨询 → 确认总结` 流程链。
- 每条链最多只有一个当前可操作节点；后续节点锁定。
- 未填写前序资料时，“查阅资料”显示为跳过，不阻塞开始咨询。
- `counselor_reflection` 不再生成、不再校验、不再阻塞结算。
- `counselorReflection` 数据字段保留用于兼容旧草稿，但不进入当前页面和必填规则。
- 不新增依赖，保持现有 Material 3 视觉语言。

---

### Task 1: Simplify the workflow to business-required summary tasks

**Files:**
- Modify: `src/consultationWorkflow.test.ts`
- Modify: `src/consultationWorkflow.ts`
- Modify: `src/types.ts`
- Modify: `src/client-app/store.ts`

**Interfaces:**
- Produces: `normalizeConsultationWorkflow(state: ConsultationWorkflowState): ConsultationWorkflowState`。
- Produces: `endSessionWorkflow` 只创建 `complete_session_review` 咨询师任务。
- Produces: `validateReviewDraft` 只校验 `clinicalSummary` 与 `clientSummary`。

- [ ] **Step 1: Write failing workflow tests**

```ts
test("ending a session creates only the required counselor summary task", () => {
  const ended = endSessionWorkflow(emptyWorkflowState(), fixtureOrder, fixtureSnapshot, now);
  assert.deepEqual(ended.tasks.map((task) => task.taskType), ["complete_session_review"]);
});

test("professional reflection does not block summary submission", () => {
  const ended = endSessionWorkflow(emptyWorkflowState(), fixtureOrder, fixtureSnapshot, now);
  const saved = saveReviewDraft(ended, "draft-order-1", {
    ...validDraftPatch,
    counselorReflection: { allianceQuality: null, goalProgress: null, reflection: "" },
  }, now);
  assert.equal(submitReviewDraft(saved, "draft-order-1", now).ok, true);
});

test("normalizing stored workflow removes legacy counselor reflection tasks", () => {
  const state = endSessionWorkflow(emptyWorkflowState(), fixtureOrder, fixtureSnapshot, now);
  state.tasks.push({ ...state.tasks[0], id: "legacy-reflection", taskType: "counselor_reflection" as never });
  assert.equal(normalizeConsultationWorkflow(state).tasks.some((task) => task.id === "legacy-reflection"), false);
});
```

- [ ] **Step 2: Run focused tests and verify RED**

Run: `node --import tsx --test src/consultationWorkflow.test.ts`

Expected: task list contains `counselor_reflection`, empty reflection blocks submission, and normalizer is missing.

- [ ] **Step 3: Implement minimal workflow changes**

Return one task from `buildReviewTasks`, remove reflection validation, remove `counselor_reflection` from `WorkflowTaskType`, and export:

```ts
export function normalizeConsultationWorkflow(state: ConsultationWorkflowState) {
  return {
    ...state,
    tasks: state.tasks.filter((task) => (task.taskType as string) !== "counselor_reflection"),
  };
}
```

Apply the normalizer inside `loadInitialWorkflow` after structural validation.

- [ ] **Step 4: Run focused tests and verify GREEN**

Run: `node --import tsx --test src/consultationWorkflow.test.ts`

Expected: all workflow tests pass.

### Task 2: Project orders and tasks into serialized counselor journeys

**Files:**
- Create: `src/workbenchJourney.ts`
- Create: `src/workbenchJourney.test.ts`

**Interfaces:**
- Consumes: `Order[]`, `WorkflowTask[]`。
- Produces: `buildCounselorJourneys(orders, tasks): CounselorJourney[]`。
- Produces: four `CounselorJourneyStep` values with status `completed | skipped | current | locked`。

- [ ] **Step 1: Write failing journey projection tests**

Create literal fixtures proving:

```ts
assert.deepEqual(
  buildCounselorJourneys([scheduledWithIntake], scheduledTasks)[0].steps.map((step) => step.status),
  ["completed", "current", "locked", "locked"],
);

assert.deepEqual(
  buildCounselorJourneys([scheduledWithoutIntake], roomTask)[0].steps.map((step) => step.status),
  ["completed", "skipped", "current", "locked"],
);

assert.equal(
  buildCounselorJourneys([firstOrder, secondOrder], tasksForBoth).length,
  2,
);
```

Also cover pending confirmation and completed-session summary states.

- [ ] **Step 2: Run focused tests and verify RED**

Run: `node --import tsx --test src/workbenchJourney.test.ts`

Expected: FAIL because `workbenchJourney.ts` does not exist.

- [ ] **Step 3: Implement the fixed phase projection**

Use this phase order and labels:

```ts
const phases = [
  { taskType: "confirm_booking", label: "确认预约" },
  { taskType: "review_intake", label: "查阅资料" },
  { taskType: "enter_session", label: "开始咨询" },
  { taskType: "complete_session_review", label: "确认总结" },
] as const;
```

For each order with a pending counselor business task, select the earliest phase as `current`, mark preceding phases completed or skipped, and mark later phases locked. Preserve one journey per order even when `clientId` is shared.

- [ ] **Step 4: Run focused tests and verify GREEN**

Run: `node --import tsx --test src/workbenchJourney.test.ts`

Expected: all journey projection tests pass.

### Task 3: Render Material 3 journey cards with one active action

**Files:**
- Modify: `src/components/Workbench/WorkbenchTasks.tsx`

**Interfaces:**
- Consumes: `buildCounselorJourneys` output from Task 2 and existing action callbacks.
- Produces: one card per active order journey and one action button for `journey.currentTask`。

- [ ] **Step 1: Replace flat task mapping with journey mapping**

Use `buildCounselorJourneys(orders, workflowTasks)` inside `useMemo`. The header count is `journeys.length`.

- [ ] **Step 2: Render the four-stage track**

Render each step with a connector, `Check` for completed, a muted check/minus treatment for skipped, the numbered current node, and `LockKeyhole` for locked. Only the current descriptor renders its description and button below the track.

- [ ] **Step 3: Map only the current task to an action**

```ts
if (taskType === "confirm_booking") onConfirmOrder(order.id);
else if (taskType === "review_intake") onViewClientFile?.(order);
else if (taskType === "enter_session") onEnterRoom(order);
else if (taskType === "complete_session_review") onWriteSummary(order);
```

Use `确认总结` as the last action label. Do not render `复盘` or `专业自评`.

### Task 4: Remove professional reflection from the current summary UI

**Files:**
- Modify: `src/sessionReviewPresentation.test.ts`
- Modify: `src/sessionReviewPresentation.ts`
- Modify: `src/components/SessionReview/SessionReviewWorkspace.tsx`
- Modify: `src/consultationWorkflow.ts`

**Interfaces:**
- Produces: review progress with `total: 2` and missing sections limited to `clinical | client`。
- Produces: summary workspace tabs `evidence | clinical | client`。

- [ ] **Step 1: Write the failing progress test**

Set `draft.counselorReflection` to empty and expect:

```ts
assert.deepEqual(getReviewProgress(draft), {
  completed: 2,
  total: 2,
  percentage: 100,
  missingSections: [],
});
```

- [ ] **Step 2: Run focused tests and verify RED**

Run: `node --import tsx --test src/sessionReviewPresentation.test.ts`

Expected: current result reports `3/3` or marks reflection missing.

- [ ] **Step 3: Implement the two-section summary UI**

Remove the reflection tab, fields, update handler and submitted patch. Change visible copy from “会谈复盘” to “咨询总结”, change progress copy to `/2 已完整`, and change counselor IM action label/error copy from “复盘” to “确认总结”.

- [ ] **Step 4: Run focused tests and verify GREEN**

Run: `node --import tsx --test src/sessionReviewPresentation.test.ts src/consultationWorkflow.test.ts`

Expected: all focused tests pass.

### Task 5: Update Builder reference and verify the complete flow

**Files:**
- Modify: `docs/builder-backend-reference.md`
- Modify: `docs/superpowers/specs/2026-08-06-consultation-lifecycle-session-review-design.md`

**Interfaces:**
- Documents: ordered task projection, optional intake skip, one active node, summary-only settlement gate, and deferred professional reflection extension.

- [ ] **Step 1: Update the Builder contract**

Remove `counselor_reflection` from the MVP `task_type` list and submission transaction. Document `phase_order`, `current_task_id` or equivalent server projection so Builder returns deterministic serialized journeys. Mark professional reflection storage/API as a future supervision feature, not an MVP requirement.

- [ ] **Step 2: Build and run the real UI flow**

Run: `npm run build`, reload `/counselor`, and verify each visible client card has four ordered nodes, exactly one enabled action, later nodes locked, and no visible “复盘” or“专业自评” copy.

- [ ] **Step 3: Run full verification**

Run: `npm test -- --runInBand && npm run lint && npm run build && git diff --check`

Expected: all tests pass, TypeScript and build exit 0, and the diff check is clean.

- [ ] **Step 4: Commit**

```bash
git add src docs
git commit -m "feat: serialize counselor workbench journeys"
```
