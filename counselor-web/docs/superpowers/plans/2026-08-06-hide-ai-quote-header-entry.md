# Hide AI Quote Header Entry Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove the AI quote poster entry from the counselor home-page header without removing the reusable quote feature used elsewhere.

**Architecture:** `Navbar` will no longer import or render the Sparkles action and will no longer expose an `onOpenAiQuoteModal` callback. `App` will remove the now-unreachable modal state and rendering connection, while the standalone `AIQuoteModal` component and API remain available for future reuse.

**Tech Stack:** React 19, TypeScript 5.8, Node test runner, React DOM server rendering, Vite.

## Global Constraints

- Do not delete `AIQuoteModal`, the AI quote API, or related data types.
- Do not change neighboring header actions or home-page styling.
- Do not add a replacement action or placeholder in the Growth tab.

---

### Task 1: Remove the home header entry

**Files:**
- Create: `src/navbar.test.ts`
- Modify: `src/components/Navbar.tsx`
- Modify: `src/App.tsx`
- Modify: `src/components/Growth/GrowthTab.tsx`

**Interfaces:**
- Consumes: `NavbarProps` and `INITIAL_CONSULTANT`.
- Produces: `NavbarProps` without `onOpenAiQuoteModal`; rendered header without the AI quote action; no unreachable modal state in `App`.

- [x] **Step 1: Write the failing rendering test**

```ts
import assert from "node:assert/strict";
import test from "node:test";
import React, { type ComponentProps } from "react";
import { renderToStaticMarkup } from "react-dom/server";

import { Navbar } from "./components/Navbar";
import { INITIAL_CONSULTANT } from "./data/mockData";

test("home header omits the AI quote action and keeps neighboring actions", () => {
  const legacyCompatibleProps = {
    consultant: INITIAL_CONSULTANT,
    onToggleListening: () => undefined,
    onOpenLiveSession: () => undefined,
    onOpenAiQuoteModal: () => undefined,
  } as ComponentProps<typeof Navbar>;

  const markup = renderToStaticMarkup(
    React.createElement(Navbar, legacyCompatibleProps),
  );

  assert.doesNotMatch(markup, /生成 AI 金句海报/);
  assert.match(markup, /接单中/);
  assert.match(markup, /消息通知/);
});
```

- [x] **Step 2: Run the test and verify the current button makes it fail**

Run: `node --import tsx --test src/navbar.test.ts`

Expected: FAIL because the rendered markup contains `生成 AI 金句海报`.

- [x] **Step 3: Remove the button and its unreachable callback wiring**

In `src/components/Navbar.tsx`, remove the `Sparkles` import, `onOpenAiQuoteModal` prop, destructured callback, and the quick-poster `<button>`.

In `src/App.tsx`, remove the `Navbar` prop:

```tsx
onOpenAiQuoteModal={() => setIsQuoteModalOpen(true)}
```

Also remove the `AIQuoteModal` import, `isQuoteModalOpen` state, modal rendering block, and the unused `GrowthTab` callback prop. Keep the standalone `src/components/AIQuoteModal.tsx` file and server API.

- [x] **Step 4: Run automated verification**

Run: `npm test && npm run lint && npm run build`

Expected: all tests pass, TypeScript emits no errors, and the production build exits with code 0.

- [x] **Step 5: Verify the production page**

Restart the production server on port 4311, open `http://localhost:4311/counselor`, and confirm the AI quote button is absent while `接单中` and `消息通知` remain visible. Confirm the browser console has no errors.

- [x] **Step 6: Commit the implementation**

```bash
git add src/navbar.test.ts src/components/Navbar.tsx src/components/Growth/GrowthTab.tsx src/App.tsx docs/superpowers/plans/2026-08-06-hide-ai-quote-header-entry.md
git commit -m "fix: hide AI quote action from home header"
```
