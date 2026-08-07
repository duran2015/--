# Meeting Room Panel and Avatar Fix Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 让咨询师会议室 AI 助手整栏可上下滚动，并确保会议室来访者头像、姓名与当前咨询订单一致。

**Architecture:** 新建无副作用的会议参与者资料解析模块，集中兼容标准与旧版订单字段；`VoiceCall` 只消费解析结果。AI 助手抽屉保留固定页头，余下内容使用一个滚动容器，避免嵌套滚动和固定笔记区争抢高度。

**Tech Stack:** React 19、TypeScript 5.8、Tailwind CSS 4、Node test runner、应用内浏览器自动化

## Global Constraints

- 不新增依赖。
- 不改变会议状态、结束会议、复盘和结算业务流。
- 标准字段 `clientName`、`clientAvatar` 的优先级高于旧字段 `userName`、`avatar`。
- 保持现有 Material 3 视觉样式。

---

### Task 1: 统一会议来访者资料解析

**Files:**
- Create: `src/meetingParticipant.ts`
- Create: `src/meetingParticipant.test.ts`
- Modify: `src/client-app/pages/Counseling/VoiceCall.tsx:70-76`

**Interfaces:**
- Consumes: `unknown` 订单值和 `{ name: string; avatar: string }` 默认资料。
- Produces: `resolveMeetingClient(order, fallback): { name: string; avatar: string }`。

- [ ] **Step 1: Write the failing tests**

```ts
assert.deepEqual(
  resolveMeetingClient(
    { clientName: "周明宇", clientAvatar: "client.jpg", userName: "旧姓名", avatar: "legacy.jpg" },
    { name: "默认用户", avatar: "default.jpg" },
  ),
  { name: "周明宇", avatar: "client.jpg" },
);

assert.deepEqual(
  resolveMeetingClient(
    { userName: "旧版用户", avatar: "legacy.jpg" },
    { name: "默认用户", avatar: "default.jpg" },
  ),
  { name: "旧版用户", avatar: "legacy.jpg" },
);
```

- [ ] **Step 2: Run the focused test and verify RED**

Run: `node --import tsx --test src/meetingParticipant.test.ts`

Expected: FAIL because `src/meetingParticipant.ts` does not exist.

- [ ] **Step 3: Implement the minimal resolver**

```ts
export function resolveMeetingClient(order: unknown, fallback: MeetingParticipant): MeetingParticipant {
  const candidate = isRecord(order) ? order : {};
  return {
    name: readText(candidate.clientName) ?? readText(candidate.userName) ?? fallback.name,
    avatar: readText(candidate.clientAvatar) ?? readText(candidate.avatar) ?? fallback.avatar,
  };
}
```

Update `VoiceCall` so counselor mode uses this resolver for `otherName` and `otherAvatar`; user mode continues to use the counselor profile.

- [ ] **Step 4: Run the focused test and verify GREEN**

Run: `node --import tsx --test src/meetingParticipant.test.ts`

Expected: all participant resolver tests pass.

### Task 2: Convert the AI assistant body to one scroll surface

**Files:**
- Modify: `src/client-app/pages/Counseling/VoiceCall.tsx:442-504`

**Interfaces:**
- Consumes: existing `mockSnapshot`, `scratchpad`, `setScratchpad`, and `isCounselorView` state.
- Produces: one fixed-header drawer whose body contains insights, transcript, and counselor scratchpad in document order.

- [ ] **Step 1: Record the failing browser baseline**

Open a counselor video meeting, wait for the participant to join, open AI 咨询助手, and measure its body.

Expected before the fix: the content container reports `scrollHeight === clientHeight`, and setting `scrollTop` cannot move the combined panel content.

- [ ] **Step 2: Implement the single-scroll structure**

Use one body container:

```tsx
<div className="min-h-0 flex-1 overflow-y-auto overscroll-contain p-4" ref={aiScrollRef}>
  <div className="space-y-5">
    {insightCard}
    {transcriptCardWithoutNestedScroller}
    {isCounselorView && scratchpadCardWithEightRowTextarea}
  </div>
</div>
```

Remove the separate fixed scratchpad sibling and remove `overflow-y-auto flex-1` from the transcript list.

- [ ] **Step 3: Verify the browser behavior GREEN**

Repeat the exact meeting flow. Assert the body has at least 80 pixels of available scroll distance; call `scrollTo(0, 80)` and assert the resulting `scrollTop >= 80`. Assert the participant image source contains the active order's `clientAvatar` URL.

- [ ] **Step 4: Run complete verification**

Run: `npm test -- --runInBand && npm run lint && npm run build && git diff --check`

Expected: all tests pass, TypeScript exits 0, the production build exits 0, and the diff check is clean.

- [ ] **Step 5: Commit**

```bash
git add src/meetingParticipant.ts src/meetingParticipant.test.ts src/client-app/pages/Counseling/VoiceCall.tsx docs/superpowers/specs/2026-08-06-meeting-room-panel-avatar-fix-design.md docs/superpowers/plans/2026-08-06-meeting-room-panel-avatar-fix.md
git commit -m "fix: align meeting participant data and panel scrolling"
```
