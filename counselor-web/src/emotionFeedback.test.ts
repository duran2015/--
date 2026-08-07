import assert from "node:assert/strict";
import test from "node:test";

import {
  adaptEmotionRecognition,
  getMockEmotionFeedback,
  getEmotionSourceLabel,
  toEmotionSessionInsights,
} from "./emotionFeedback";

test("emotion UI displays the recognition API result instead of classifying the user", () => {
  const result = adaptEmotionRecognition({
    streamStatus: "active",
    labelCode: "provider_custom_state",
    labelDisplay: "谨慎表达",
    trendCode: "provider_custom_trend",
    trendDisplay: "缓慢增强",
    confidence: 0.76,
    sustainedSeconds: 90,
    sources: ["voice"],
    timeline: [],
  });
  assert.equal(result.chipLabel, "情绪动态 · 谨慎表达");
  assert.equal(result.detail, "谨慎表达 · 缓慢增强");
  assert.equal(result.currentLabel, "provider_custom_state");
});

test("emotion feedback collects before publishing a conclusion", () => {
  const result = getMockEmotionFeedback(10, "voice", true);
  assert.equal(result.streamStatus, "collecting");
  assert.equal(result.chipLabel, "情绪动态 · 分析中");
  assert.equal(result.currentLabel, "uncertain");
  assert.equal(result.significantEvent, undefined);
});

test("emotion feedback only creates a reminder after tension is sustained", () => {
  assert.equal(getMockEmotionFeedback(120, "voice", true).significantEvent, undefined);
  const result = getMockEmotionFeedback(165, "voice", true);
  assert.equal(result.chipLabel, "情绪动态 · 紧张持续");
  assert.equal(result.significantEvent?.id, "mock-sustained-tension-160");
  assert.equal(result.significantEvent?.message, "系统观察到紧张状态已持续约 2 分钟");
});

test("video emotion feedback degrades to voice when camera is unavailable", () => {
  assert.deepEqual(getMockEmotionFeedback(100, "video", true).sources, [
    "voice",
    "facial_expression",
    "body_posture",
  ]);
  const degraded = getMockEmotionFeedback(100, "video", false);
  assert.deepEqual(degraded.sources, ["voice"]);
  assert.equal(degraded.streamStatus, "degraded");
  assert.equal(getEmotionSourceLabel(degraded.sources), "语音语调（视频信号中断）");
});

test("emotion feedback converts significant events into traceable review insights", () => {
  const event = getMockEmotionFeedback(165, "voice", true).significantEvent;
  assert.ok(event);
  assert.deepEqual(toEmotionSessionInsights("session-1", [event]), [
    {
      id: "session-1-emotion-mock-sustained-tension-160",
      sessionId: "session-1",
      category: "emotion",
      title: "紧张状态持续",
      detail: "系统观察到紧张状态已持续约 2 分钟（02:40）",
      sourceType: "emotion_event",
      sourceIds: ["mock-sustained-tension-160"],
      confidence: 0.82,
    },
  ]);
});
