# Stabilize AI API and Builder Reference Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Repair the current type and DOM failures, protect the two AI endpoints, clear the dependency warning, and document how Builder should replace frontend Mock data with real tables and APIs.

**Architecture:** Keep the product as the existing React/Vite/Express application. Put validation and a deterministic in-memory fixed-window limiter in `server/aiGuard.ts`, integrate it only on `/api/ai/*`, and leave the health/static routes unchanged. The Builder document is descriptive: it maps current frontend data sources to suggested backend resources without implementing the complete backend.

**Tech Stack:** TypeScript 5.8, React 19, Vite 6, Express 4, Node built-in test runner via `tsx`, tested browser-pathname entry routing.

## Global Constraints

- Do not implement authentication, Redis, distributed rate limiting, bundle splitting, or a real database in this change.
- JSON request bodies are limited to `32kb`.
- Each source IP may make 10 AI requests in a fixed 60-second window.
- Unknown request fields remain ignored for compatibility.
- Internal exception details never appear in HTTP 500 responses.
- Preserve the current fallback AI responses when `GEMINI_API_KEY` is absent.
- The Builder reference must distinguish existing frontend behavior from recommended future backend work.

---

### Task 1: Add tested AI request guards

**Files:**
- Create: `server/aiGuard.ts`
- Create: `server/aiGuard.test.ts`
- Modify: `package.json`

**Interfaces:**
- Produces: `validateSessionSummaryBody(body: unknown): ValidationResult<SessionSummaryInput>`.
- Produces: `validateQuoteBody(body: unknown): ValidationResult<QuoteInput>`.
- Produces: `FixedWindowRateLimiter.check(key: string, now?: number): RateLimitResult`.

- [ ] **Step 1: Write failing validation and limiter tests**

```ts
import assert from "node:assert/strict";
import test from "node:test";
import {
  FixedWindowRateLimiter,
  validateQuoteBody,
  validateSessionSummaryBody,
} from "./aiGuard";

test("session summary accepts boundary values", () => {
  assert.equal(validateSessionSummaryBody({
    clientName: "a".repeat(100),
    rawNotes: "b".repeat(10_000),
    sessionTopic: "c".repeat(200),
    sessionNumber: 999,
  }).ok, true);
});

test("session summary rejects invalid known fields", () => {
  const result = validateSessionSummaryBody({ clientName: 1, rawNotes: "x".repeat(10_001), sessionNumber: 0 });
  assert.equal(result.ok, false);
  if (!result.ok) assert.equal(result.errors.length, 3);
});

test("quote rejects non-object bodies", () => {
  assert.equal(validateQuoteBody(null).ok, false);
  assert.equal(validateQuoteBody([]).ok, false);
});

test("limiter rejects request 11 and resets after 60 seconds", () => {
  const limiter = new FixedWindowRateLimiter(10, 60_000);
  for (let index = 0; index < 10; index += 1) assert.equal(limiter.check("ip", 1_000).allowed, true);
  assert.deepEqual(limiter.check("ip", 1_000), { allowed: false, retryAfterSeconds: 60 });
  assert.equal(limiter.check("ip", 61_000).allowed, true);
});
```

- [ ] **Step 2: Run the test and verify the missing module/API failure**

Run: `node --import tsx --test server/aiGuard.test.ts`

Expected: FAIL because `server/aiGuard.ts` or its exports do not exist.

- [ ] **Step 3: Implement the pure guard module**

Implement exact limits from the design using a discriminated `ValidationResult<T>`. `FixedWindowRateLimiter` stores `{ count, windowStartedAt }` per key, rejects after the tenth request, returns a ceiling-rounded retry duration, and deletes expired entries during checks.

- [ ] **Step 4: Add and run the project test script**

```json
"test": "node --import tsx --test server/*.test.ts"
```

Run: `npm test`

Expected: all guard tests pass with zero failures.

### Task 2: Integrate guards into Express

**Files:**
- Modify: `server.ts`
- Test: `server/aiGuard.test.ts`

**Interfaces:**
- Consumes: `validateSessionSummaryBody`, `validateQuoteBody`, and `FixedWindowRateLimiter` from Task 1.
- Produces: HTTP `400`, `413`, `429`, and generic `500` responses documented in the design.

- [ ] **Step 1: Record failing HTTP behavior**

Run a development server, then send an invalid body:

```bash
curl -i -H 'Content-Type: application/json' -d '{"sessionNumber":0}' http://127.0.0.1:3001/api/ai/session-summary
```

Expected before the change: HTTP 200 fallback response, proving invalid input is accepted.

- [ ] **Step 2: Add the 32 KB parser limit and AI-only limiter middleware**

Use `express.json({ limit: "32kb" })`. Apply one `FixedWindowRateLimiter(10, 60_000)` instance to `/api/ai` and set `Retry-After` when rejected.

- [ ] **Step 3: Validate each endpoint before invoking Gemini**

On validation failure return:

```ts
res.status(400).json({ error: "Invalid request", details: result.errors });
```

Use `result.value` for prompt construction so unvalidated request fields do not flow into Gemini.

- [ ] **Step 4: Add JSON parser error handling and generic 500 responses**

Return `413` for `entity.too.large`, `400` for malformed JSON, and `{ error: "Failed to generate summary" }` or `{ error: "Failed to generate quote" }` without an exception `details` field for unexpected failures.

- [ ] **Step 5: Verify HTTP behavior**

Run valid fallback requests plus invalid, oversized, and 11-request rate-limit cases. Expect success for valid requests and exact `400`, `413`, and `429` status codes for rejected requests.

### Task 3: Repair type checking and invalid login DOM

**Files:**
- Modify: `src/client-app/pages/Counseling/VoiceCall.tsx`
- Modify: `src/client-app/pages/Onboarding/Login.tsx`
- Modify: `tsconfig.json`

**Interfaces:**
- Produces: a normal `VoiceCallProps` component contract.
- Produces: separate agreement toggle and legal-document buttons with no nested interactive element.

- [ ] **Step 1: Reproduce both failures**

Run: `npx tsc --noEmit --allowJs false`

Expected: FAIL at `ClientApp.tsx` where `<VoiceCall key="vcall" />` is rejected.

Open `/client` with Playwright and inspect the console.

Expected: React reports that `<button>` cannot contain a nested `<button>`.

- [ ] **Step 2: Correct the VoiceCall props signature**

Define `VoiceCallProps` with optional `propOrder`, `propMode`, and `onClose`, then destructure the parameter without a default object. `<VoiceCall />` remains valid because React always supplies the props object.

- [ ] **Step 3: Replace the agreement wrapper with valid accessible markup**

Use a non-interactive flex container, a dedicated `type="button"` toggle with `aria-label="同意服务协议与隐私政策"` and `aria-pressed={agreed}`, followed by text containing the two existing legal-document buttons.

- [ ] **Step 4: Limit TypeScript to maintained source files**

Add `include` entries for `src/**/*.ts`, `src/**/*.tsx`, `server/**/*.ts`, `server.ts`, and `vite.config.ts`; set `allowJs` to `false`.

- [ ] **Step 5: Verify type and DOM behavior**

Run `npm run lint`, then revisit `/client` with Playwright. Expect TypeScript exit 0 and no nested-button console error.

### Task 4: Remove patch artifacts and clear dependency audit

**Files:**
- Delete: `fix-client-app.cjs`
- Delete: `patch5.cjs`, `patch6.cjs`, `patch7.cjs`, `patch9.cjs`, `patch11.cjs`, `patch13.cjs`, `patch21.cjs`
- Modify: `package.json`
- Modify: `package-lock.json`
- Modify: `README.md`

- [ ] **Step 1: Delete all one-time patch scripts**

Confirm no package script references them, then remove the eight committed artifacts.

- [ ] **Step 2: Remove the vulnerable router dependency**

Replace the three-route React Router wrapper with the tested `resolveAppRoute` pathname resolver, then run `npm uninstall react-router-dom`.

Expected: `/client` and `/counselor` select their existing applications, unknown paths become `/counselor`, and no React Router packages remain.

- [ ] **Step 3: Correct README stack versions**

Change React 18 to React 19 and describe the pathname entry routing.

- [ ] **Step 4: Verify dependency state**

Run: `npm audit`

Expected: zero known vulnerabilities.

### Task 5: Create the Builder backend reference

**Files:**
- Create: `docs/builder-backend-reference.md`

**Interfaces:**
- Consumes: `src/types.ts`, `src/client-app/store.ts`, `src/client-app/data.ts`, `src/data/mockData.ts`, and component-local Mock arrays.
- Produces: a non-binding implementation reference for Builder.

- [ ] **Step 1: Inventory frontend Mock sources**

Document global store state, exported Mock datasets, and component-local data for users, counselors, assessments, availability, orders/payments, sessions/messages, summaries, notifications, growth content, vouchers, settlements, withdrawals, risk data, and AI settings.

- [ ] **Step 2: Map resources to suggested tables**

For each domain, list primary keys, ownership/foreign-key relationships, sensitive fields, and source frontend types. Include at least users/roles, counselor profiles/credentials/services, availability slots, orders/payments/refunds, sessions/messages/transcripts/notes/summaries, assessments/risk events, notifications, vouchers/referrals/content, ledgers/settlements/payout accounts/withdrawals, and audit/consent records.

- [ ] **Step 3: Map frontend actions to suggested APIs**

List REST endpoints, request/response responsibilities, authorization owner, pagination/idempotency needs, and realtime channels. Mark the two existing AI routes as implemented and all others as Builder work.

- [ ] **Step 4: Provide migration order and completion checklist**

Describe staged replacement of Mock data: identity and profiles, catalog/availability, booking/payment, consultation/messaging, clinical records/risk, notifications/growth, and finance. Include a checklist that removes each Mock import only after its API is connected.

### Task 6: Full verification and local deployment

**Files:**
- Review all changed files.

- [ ] **Step 1: Run the full verification suite**

```bash
npm test
npm run lint
npm audit
npm run build
```

Expected: every command exits 0; build may retain the existing non-blocking large-chunk warning.

- [ ] **Step 2: Start the production server locally**

Run: `PORT=4311 npm start`

Expected: health endpoint returns HTTP 200 and both `/client` and `/counselor` render.

- [ ] **Step 3: Run API and browser smoke checks**

Verify valid fallback responses, `400` invalid input, `413` oversized body, `429` rate limit, and no React DOM nesting error in either application route.

- [ ] **Step 4: Review repository scope**

Run `git diff --check`, `git status --short`, and inspect the complete diff. Confirm only the planned code, dependency, README, Builder reference, spec, and plan files changed.
