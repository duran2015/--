# Consultation Lifecycle and Session Review Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a frontend-only, fully demonstrable consultation lifecycle in which ending a session creates one resumable review draft, synchronized counselor tasks and IM cards, a client recap, and a summary-gated T+1 settlement state.

**Architecture:** A pure `consultationWorkflow` domain module owns every workflow transition and validation rule. Zustand stores the Mock domain state and exposes thin actions; React pages render derived selectors and never update task, message, summary, and settlement states independently. `SessionReviewWorkspace` replaces the legacy AI summary modal and is opened by meeting-end, workbench, IM, order, and settlement entry points.

**Tech Stack:** React 19, TypeScript 5.8, Zustand 5, Motion, Lucide React, Tailwind CSS 4, Node test runner, Vite.

## Global Constraints

- Implement only frontend Mock state and Builder documentation; do not connect real transcription, RTC, messaging, persistence, or settlement services.
- Use the existing warm Material 3 visual language: `#FAF8F5` surfaces, `#6750A4` primary, large rounded cards, tonal status containers, sticky top/bottom app bars.
- Internal transcript, notes, clinical summary, risk review, and counselor reflection must never appear in client-facing cards.
- Saving a draft must not complete tasks, send the client recap, or unlock settlement.
- Submitting a valid review must be idempotent and atomically complete tasks, update the counselor card, create the client card, archive the summary, and set settlement to `eligible_t1`.
- User intake and evaluation are tasks but never settlement blockers.

---

### Task 1: Consultation workflow domain and tests

**Files:**
- Create: `src/consultationWorkflow.ts`
- Create: `src/consultationWorkflow.test.ts`
- Modify: `src/types.ts`

**Interfaces:**
- Produces: `ConsultationWorkflowState`, `SessionReviewDraft`, `WorkflowTask`, `WorkflowMessage`, `seedWorkflowFromOrders`, `addBookingWorkflow`, `confirmBookingWorkflow`, `submitIntakeWorkflow`, `skipIntakeWorkflow`, `endSessionWorkflow`, `saveReviewDraft`, `submitReviewDraft`, `completeClientEvaluationWorkflow`, `validateReviewDraft`, `getReviewProgress`.
- Consumes: existing `Order` fields only; no React or Zustand dependency.

- [ ] **Step 1: Write failing transition tests**

```ts
test("ending a session creates one draft, two counselor tasks, one counselor card, and a settlement hold", () => {
  const ended = endSessionWorkflow(emptyWorkflowState(), fixtureOrder, fixtureSnapshot, "2026-08-06T10:00:00.000Z");
  assert.equal(ended.reviewDrafts.length, 1);
  assert.deepEqual(ended.tasks.map((task) => task.taskType), ["complete_session_review", "counselor_reflection"]);
  assert.equal(ended.messages[0].audience, "counselor");
  assert.equal(ended.settlements[fixtureOrder.id], "blocked_by_summary");
});

test("saving a review keeps settlement locked and does not create a client card", () => {
  const saved = saveReviewDraft(endedState, "draft-order-1", validDraftPatch);
  assert.equal(saved.reviewDrafts[0].status, "draft");
  assert.equal(saved.messages.some((message) => message.audience === "client"), false);
  assert.equal(saved.settlements[fixtureOrder.id], "blocked_by_summary");
});

test("submitting a valid review atomically updates tasks, cards, archive, and settlement", () => {
  const result = submitReviewDraft(validDraftState, "draft-order-1", "2026-08-06T10:20:00.000Z");
  assert.equal(result.ok, true);
  assert.equal(result.state.settlements[fixtureOrder.id], "eligible_t1");
  assert.equal(result.state.tasks.filter((task) => task.actorRole === "counselor").every((task) => task.status === "completed"), true);
  assert.equal(result.state.messages.filter((message) => message.audience === "client").length, 1);
  assert.equal(result.state.archivedReviews.length, 1);
});

test("submitting twice is idempotent", () => {
  const once = submitReviewDraft(validDraftState, "draft-order-1", now).state;
  const twice = submitReviewDraft(once, "draft-order-1", now).state;
  assert.equal(twice.messages.length, once.messages.length);
  assert.equal(twice.archivedReviews.length, once.archivedReviews.length);
});

test("order states seed the matching actor tasks", () => {
  const state = seedWorkflowFromOrders([pendingOrder, scheduledOrder, completedWithoutSummary]);
  assert.deepEqual(state.tasks.map((task) => task.taskType).sort(), [
    "complete_intake",
    "complete_session_review",
    "confirm_booking",
    "counselor_reflection",
    "enter_session",
  ]);
});
```

- [ ] **Step 2: Run the tests and verify RED**

Run: `node --import tsx --test src/consultationWorkflow.test.ts`

Expected: FAIL because the domain module and types do not exist.

- [ ] **Step 3: Add exact workflow types to `src/types.ts`**

Add the status unions and interfaces from the approved design: transcript segment, insight, review draft, workflow task, summary message card, session snapshot, archived review, and `ConsultationWorkflowState`.

- [ ] **Step 4: Implement pure transitions**

Implement immutable functions with deterministic IDs (`session-${order.id}`, `draft-${order.id}`, `task-review-${order.id}`, `task-reflection-${order.id}`, `message-summary-${order.id}`), literal validation errors, client-message redaction by construction, and order-driven task seeding for booking confirmation, optional intake, intake review, session entry, review, recap reading, and evaluation.

- [ ] **Step 5: Run domain and full tests**

Run: `node --import tsx --test src/consultationWorkflow.test.ts && npm test`

Expected: all transition tests and the existing suite pass.

- [ ] **Step 6: Commit**

```bash
git add src/types.ts src/consultationWorkflow.ts src/consultationWorkflow.test.ts
git commit -m "feat: add consultation workflow state machine"
```

---

### Task 2: Mock artifacts and Zustand workflow actions

**Files:**
- Create: `src/consultationWorkflowMock.ts`
- Modify: `src/client-app/store.ts`
- Modify: `src/consultationWorkflow.test.ts`

**Interfaces:**
- Consumes: Task 1 transitions and types.
- Produces: `buildMockSessionSnapshot(order)`, store state `consultationWorkflow`, and actions `addOrderWithWorkflow`, `confirmBookingWithWorkflow`, `submitIntakeWithWorkflow`, `skipIntakeWithWorkflow`, `endConsultationSession`, `ensureSessionReview`, `saveSessionReview`, `submitSessionReview`, `completeClientEvaluation`.

- [ ] **Step 1: Add failing Mock-source tests**

```ts
test("mock session snapshot keeps every insight traceable to a real source", () => {
  const snapshot = buildMockSessionSnapshot(fixtureOrder);
  const sourceIds = new Set([
    ...snapshot.transcript.map((item) => item.id),
    ...snapshot.notes.map((item) => item.id),
  ]);
  assert.equal(snapshot.insights.every((insight) => insight.sourceIds.every((id) => sourceIds.has(id))), true);
});
```

- [ ] **Step 2: Run the test and verify RED**

Run: `node --import tsx --test src/consultationWorkflow.test.ts`

Expected: FAIL because `buildMockSessionSnapshot` does not exist.

- [ ] **Step 3: Implement traceable Mock content**

Create fixed counselor/client transcript segments with timestamps, confidence, highlights, counselor scratchpad notes, and insights whose `sourceIds` point to those items. Build the initial clinical and client-facing draft text from the order plus these sources.

- [ ] **Step 4: Add Zustand state and actions**

Initialize `consultationWorkflow` from every Mock order: pending orders create counselor confirmation tasks, scheduled orders create entry and optional intake tasks, submitted intake creates a counselor review task, and completed orders without summaries create review/reflection tasks and settlement holds. Each action must call exactly one domain transition and replace the workflow state once. `submitSessionReview` also updates the matching legacy order to `{ hasSummary: true, status: "completed" }` for existing screens.

- [ ] **Step 5: Run tests and type checking**

Run: `npm test && npm run lint`

Expected: all tests pass and TypeScript emits no errors.

- [ ] **Step 6: Commit**

```bash
git add src/consultationWorkflowMock.ts src/client-app/store.ts src/consultationWorkflow.test.ts
git commit -m "feat: store mock consultation workflow state"
```

---

### Task 3: Material 3 session review workspace

**Files:**
- Create: `src/components/SessionReview/SessionReviewWorkspace.tsx`
- Create: `src/sessionReviewPresentation.test.ts`
- Create: `src/sessionReviewPresentation.ts`

**Interfaces:**
- Consumes: `draftId`, workflow selectors/actions, order data, transcript, insights, and settlement state.
- Produces: a full-screen counselor review page with `onClose(): void` and `onSubmitted(): void` callbacks.

- [ ] **Step 1: Write failing presentation tests**

```ts
test("review progress counts the four required sections", () => {
  assert.deepEqual(getReviewProgress(emptyDraft), { completed: 0, total: 4, percent: 0 });
  assert.deepEqual(getReviewProgress(validDraft), { completed: 4, total: 4, percent: 100 });
});

test("client projection excludes internal clinical fields", () => {
  const projection = getClientReviewProjection(validDraft);
  assert.deepEqual(Object.keys(projection).sort(), ["actionItems", "nextPlan", "recap"]);
  assert.equal(JSON.stringify(projection).includes(validDraft.clinicalSummary.riskReview), false);
});
```

- [ ] **Step 2: Run the test and verify RED**

Run: `node --import tsx --test src/sessionReviewPresentation.test.ts`

Expected: FAIL because presentation selectors do not exist.

- [ ] **Step 3: Implement selectors and the workspace**

Build a sticky Material 3 top bar, settlement-lock banner, four tonal section tabs, source-quality badge, traceable transcript evidence, editable clinical fields, user-facing preview, counselor reflection controls, inline validation summary, and sticky actions `保存草稿并返回` / `正式提交总结`.

The submit confirmation dialog must explicitly show `用户可见版将发送` and `提交后进入 T+1 结算`. Submitted reviews render read-only with `总结已提交 · T+1 结算中`.

- [ ] **Step 4: Run tests and type checking**

Run: `npm test && npm run lint`

Expected: selectors and all existing tests pass; the component type-checks.

- [ ] **Step 5: Commit**

```bash
git add src/sessionReviewPresentation.ts src/sessionReviewPresentation.test.ts src/components/SessionReview/SessionReviewWorkspace.tsx
git commit -m "feat: add session review workspace"
```

---

### Task 4: Replace the meeting-end modal flow

**Files:**
- Modify: `src/client-app/pages/Counseling/VoiceCall.tsx`
- Modify: `src/App.tsx`
- Modify: `src/components/AISummaryModal.tsx` (delete only after all imports are removed)

**Interfaces:**
- Consumes: store `endConsultationSession(order, snapshot): string` returning the draft ID.
- Produces: explicit `VoiceCallProps.onSessionEnded(order, snapshot)` and App state `activeSessionReviewId`.

- [ ] **Step 1: Extend the existing end-flow regression test**

Add a domain-level test that uses `buildMockSessionSnapshot`, ends the session, and asserts the returned draft ID is the only review entry opened by the UI contract.

- [ ] **Step 2: Run the test and verify RED**

Run: `node --import tsx --test src/consultationWorkflow.test.ts`

Expected: FAIL until the end action returns the stable draft ID.

- [ ] **Step 3: Wire explicit callbacks**

Replace the `open-ai-summary` custom event and `selectedOrderForSummary` modal state. Bind the meeting scratchpad to state, build the snapshot on hang-up, invoke `onSessionEnded`, close `activeLiveOrder`, and render `SessionReviewWorkspace` as a full-screen App overlay.

The existing workbench `onWriteSummary(order)` must call `ensureSessionReview(order)` and open the same draft ID.

- [ ] **Step 4: Remove dead legacy modal wiring**

Remove the unused `AISummaryModal` import, state, handlers, rendering block, and component file only after `rg "AISummaryModal|open-ai-summary" src` returns no consumers.

- [ ] **Step 5: Run tests, type checking, and build**

Run: `npm test && npm run lint && npm run build`

Expected: all commands exit 0.

- [ ] **Step 6: Commit**

```bash
git add src/App.tsx src/client-app/pages/Counseling/VoiceCall.tsx src/components/AISummaryModal.tsx src/consultationWorkflow.test.ts
git commit -m "feat: open review workspace after consultation"
```

---

### Task 5: Synchronize workbench, counselor IM, order, and settlement entries

**Files:**
- Modify: `src/components/Workbench/WorkbenchTasks.tsx`
- Modify: `src/components/IM/ChatDrawer.tsx`
- Modify: `src/components/Orders/OrderDetailView.tsx`
- Modify: `src/components/Profile/IncomeView.tsx`
- Modify: `src/components/Profile/ProfileTab.tsx`
- Modify: `src/App.tsx`
- Modify: `src/client-app/pages/Counseling/PreCounselingQuestionnaire.tsx`

**Interfaces:**
- Consumes: workflow tasks/messages/drafts/settlements and `onOpenSessionReview(draftId)`.
- Produces: four synchronized entry points that open the same draft.

- [ ] **Step 1: Add selector assertions**

Extend the domain test to assert one pending review task and one pending counselor summary card reference the same `draftId`, and that submission updates rather than duplicates the counselor card.

- [ ] **Step 2: Run tests and verify RED for card-update behavior**

Run: `node --import tsx --test src/consultationWorkflow.test.ts`

Expected: FAIL if a duplicate counselor card is created or draft IDs differ.

- [ ] **Step 3: Render synchronized entries**

- Workbench: render counselor `confirm_booking`, `review_intake`, `enter_session`, `complete_session_review`, and `counselor_reflection` tasks; group review/reflection into one card showing completion percent and `结算锁定`.
- Counselor IM: render `summary_card` as a Material 3 system card; pending opens the workspace, submitted opens the read-only workspace.
- Order detail: map `hasSummary`/draft status to `撰写`, `继续`, or `查看已归档总结`.
- Income: show a summary-required hold and `去完成总结`; update settlement copy from “服务完成即 T+1” to “总结提交后 T+1”.
- Booking/intake: `handleConfirmOrder` completes `confirm_booking` and creates the next tasks; questionnaire submit or skip updates `complete_intake` and conditionally creates `review_intake` without blocking session entry.

- [ ] **Step 4: Run tests, type checking, and build**

Run: `npm test && npm run lint && npm run build`

Expected: all commands exit 0.

- [ ] **Step 5: Commit**

```bash
git add src/components/Workbench/WorkbenchTasks.tsx src/components/IM/ChatDrawer.tsx src/components/Orders/OrderDetailView.tsx src/components/Profile/IncomeView.tsx src/components/Profile/ProfileTab.tsx src/client-app/pages/Counseling/PreCounselingQuestionnaire.tsx src/App.tsx src/consultationWorkflow.test.ts
git commit -m "feat: link review tasks messages and settlement"
```

---

### Task 6: Client recap, evaluation task, and Builder reference

**Files:**
- Modify: `src/client-app/pages/Counseling/TextChat.tsx`
- Modify: `src/client-app/pages/Counseling/UserEvaluation.tsx`
- Modify: `src/client-app/pages/Counseling/CallSummary.tsx`
- Modify: `docs/builder-backend-reference.md`

**Interfaces:**
- Consumes: audience-filtered client `summary_card` projection and workflow evaluation task.
- Produces: client-only recap card with `查看完整回顾` / `评价咨询师`, plus documented backend transaction and schema.

- [ ] **Step 1: Add privacy and evaluation-task tests**

```ts
test("submitted review creates a non-blocking client review task", () => {
  const submitted = submitReviewDraft(validDraftState, draftId, now).state;
  const task = submitted.tasks.find((item) => item.taskType === "review_counselor");
  assert.equal(task?.actorRole, "client");
  assert.equal(task?.blockingSettlement, false);
});
```

- [ ] **Step 2: Run test and verify RED if task/card contract is incomplete**

Run: `node --import tsx --test src/consultationWorkflow.test.ts`

Expected: FAIL until both the user card and evaluation task are created by submission.

- [ ] **Step 3: Render the client recap and evaluation entry**

In `TextChat`, render the client-audience summary card using only `clientSummary`; route evaluation to the existing `UserEvaluation`. Update `CallSummary` to read the archived client projection rather than fixed prose. Mark the evaluation task complete when the Mock evaluation is submitted without changing settlement.

- [ ] **Step 4: Expand Builder documentation**

Document `workflow_tasks`, `session_review_drafts`, `session_summary_versions`, `settlement_holds`, `summary_card` metadata, the review-draft APIs, submit transaction, idempotency key, optimistic version, role visibility matrix, and T+1 release rule.

- [ ] **Step 5: Run the full automated suite**

Run: `npm test && npm run lint && npm run build && npm audit --omit=dev`

Expected: all tests/type checks/builds pass and production dependency audit reports 0 vulnerabilities.

- [ ] **Step 6: Commit**

```bash
git add src/client-app/pages/Counseling/TextChat.tsx src/client-app/pages/Counseling/UserEvaluation.tsx src/client-app/pages/Counseling/CallSummary.tsx docs/builder-backend-reference.md src/consultationWorkflow.test.ts
git commit -m "feat: share client recap and document review backend"
```

---

### Task 7: End-to-end browser verification and deployment

**Files:**
- Modify only files required by defects found during verification.

**Interfaces:**
- Consumes: the complete frontend flow.
- Produces: a production build served on `http://localhost:4311/counselor`.

- [ ] **Step 1: Restart the production server**

Run: `npm run build`, stop the existing 4311 process, then run `PORT=4311 npm start`.

- [ ] **Step 2: Verify counselor draft recovery**

In a real browser: enter a scheduled consultation, wait for join, hang up, verify the full-screen review page, edit each section, save draft, reopen from workbench, reopen from IM, and confirm identical values/progress.

- [ ] **Step 3: Verify submission and settlement**

Submit the review, confirm the task is completed, counselor IM card changes to submitted, archived review is readable, and income status is `T+1 结算中`.

- [ ] **Step 4: Verify client privacy and evaluation**

Switch to the client flow, open the recap card, confirm internal clinical/risk/note text is absent, submit the user evaluation, and confirm settlement status does not change.

- [ ] **Step 5: Verify responsiveness and console**

Check 390×844 and 878×1514 viewports. Confirm no horizontal overflow, clipped sticky actions, React/DOM errors, console warnings, or duplicate cards.

- [ ] **Step 6: Final verification and commit**

Run: `npm test && npm run lint && npm run build && npm audit --omit=dev && git diff --check`

Expected: every command exits 0; build may retain the known chunk-size warning only.

```bash
git add -A
git commit -m "fix: polish consultation review workflow"
```
