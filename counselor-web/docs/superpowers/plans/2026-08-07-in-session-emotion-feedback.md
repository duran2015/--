# In-Session Emotion Feedback Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a counselor-only, Material 3 continuous emotion feedback demo for voice and video consultations, with deterministic Mock transitions and review evidence.

**Architecture:** Keep recognition and smoothing rules in a pure `emotionFeedback` module. Render a shared status chip and side-panel card from the derived snapshot, while `VoiceCall` only owns the call clock and selected event. Convert significant events into existing `SessionInsight` evidence when the session ends.

**Tech Stack:** React 19, TypeScript 5.8, Tailwind CSS 4, Motion, Lucide React, Node test runner.

## Global Constraints

- Counselor-only; client view must not receive emotion UI.
- Ordinary changes update silently; only sustained, sufficiently confident trends show a Snackbar.
- Emotion inference never opens or submits the risk workflow automatically.
- Voice uses `voice`; video uses `voice + facial_expression + body_posture`, falling back to voice when the camera is off.
- No face boxes, diagnostic labels, raw audio/video persistence, or new runtime dependency.

---

### Task 1: Pure Mock emotion timeline and presentation model

**Files:**
- Create: `src/emotionFeedback.ts`
- Test: `src/emotionFeedback.test.ts`

**Interfaces:**
- Produces: `getMockEmotionFeedback(elapsedSeconds, mode, cameraAvailable): EmotionFeedbackPresentation`
- Produces: `toEmotionSessionInsights(sessionId, events): SessionInsight[]`

- [ ] **Step 1: Write failing tests** for collecting, stable, sustained tension, easing, video source fallback, reminder cooldown identity, and insight conversion.
- [ ] **Step 2: Run `npm test -- --test-name-pattern="emotion feedback"`** and verify imports fail.
- [ ] **Step 3: Implement exact types and deterministic time ranges** from the approved design: `0–20 collecting`, `20–80 stable`, `80–160 rising`, `160–240 sustained/easing`, then stable.
- [ ] **Step 4: Run the focused tests** and verify all pass.
- [ ] **Step 5: Commit** `test/feat: add emotion feedback presentation model`.

### Task 2: Material 3 status chip and Snackbar

**Files:**
- Create: `src/components/ConsultationRoom/EmotionStatusChip.tsx`
- Create: `src/components/ConsultationRoom/EmotionChangeSnackbar.tsx`
- Modify: `src/client-app/pages/Counseling/VoiceCall.tsx`

**Interfaces:**
- Consumes: `EmotionFeedbackPresentation`
- Produces: `EmotionStatusChip({ presentation, onOpen })`
- Produces: `EmotionChangeSnackbar({ event, onOpen, onDismiss })`

- [ ] **Step 1: Add a presentation test assertion** ensuring client mode never requests emotion UI.
- [ ] **Step 2: Run the focused test** and verify it fails.
- [ ] **Step 3: Render the counselor-only chip below the meeting timer**, with `aria-live="polite"`, 48dp click target, text plus icon, and no error-red styling.
- [ ] **Step 4: Render one dismissible Snackbar for the sustained event**, auto-dismiss after six seconds and open the AI panel on action.
- [ ] **Step 5: Run `npm run lint && npm test`** and verify success.

### Task 3: Emotion detail card in the existing AI side panel

**Files:**
- Create: `src/components/ConsultationRoom/EmotionDynamicsCard.tsx`
- Modify: `src/client-app/pages/Counseling/VoiceCall.tsx`

**Interfaces:**
- Consumes: `EmotionFeedbackPresentation`, `elapsedSeconds`, and `mode`
- Produces: an accessible current-state header, 10-minute compact timeline, event list, effective-source labels, confidence band, and model disclaimer.

- [ ] **Step 1: Add pure formatter tests** for voice, multimodal, degraded, and insufficient-source labels.
- [ ] **Step 2: Run the focused tests** and verify the new formatter assertions fail.
- [ ] **Step 3: Replace the fixed “实时情绪洞察” card** with `EmotionDynamicsCard` as the first AI panel card; clicking the main chip opens and focuses this card.
- [ ] **Step 4: Ensure the panel remains scrollable** and the card does not block transcript or notes.
- [ ] **Step 5: Run `npm run lint && npm test`** and verify success.

### Task 4: Voice/video visual behavior and degradation

**Files:**
- Modify: `src/client-app/pages/Counseling/VoiceCall.tsx`
- Modify: `src/voiceCallPresentation.ts`
- Modify: `src/voiceCallPresentation.test.ts`

**Interfaces:**
- Consumes: call mode, camera state, and emotion presentation.
- Produces: `video-call` active layout and voice avatar ring styling without face overlays.

- [ ] **Step 1: Change the video layout test** to expect `video-call` after join and add camera-off degradation coverage.
- [ ] **Step 2: Run the focused test** and verify it fails.
- [ ] **Step 3: Add an active video stage** that uses the participant image as the Mock video surface and keeps emotion UI outside the face area.
- [ ] **Step 4: Add a subtle voice avatar trend ring**, disabled by reduced-motion preferences, and make camera-off change sources to voice only.
- [ ] **Step 5: Run `npm run lint && npm test`** and verify success.

### Task 5: Session-review evidence and final verification

**Files:**
- Modify: `src/client-app/pages/Counseling/VoiceCall.tsx`
- Modify: `src/components/SessionReview/SessionReviewWorkspace.tsx`
- Modify: `src/types.ts`
- Modify: `src/sessionReviewWorkflow.test.ts`

**Interfaces:**
- Consumes: `toEmotionSessionInsights()` results.
- Produces: `SessionInsight.sourceType` support for `emotion_event` and a review evidence group linked to event times.

- [ ] **Step 1: Add a failing workflow test** proving emotion events enter the session snapshot without changing settlement or review status.
- [ ] **Step 2: Run the focused test** and verify failure.
- [ ] **Step 3: Append emotion insights when finishing the room** and render them under the review AI evidence area with time/source/confidence copy.
- [ ] **Step 4: Run `npm run lint`, `npm test`, and `npm run build`**; fix every failure without weakening assertions.
- [ ] **Step 5: Manually verify counselor voice, counselor video/camera-off, client hidden state, Snackbar cooldown, side-panel scrolling, and end-to-review navigation at mobile and desktop widths.

