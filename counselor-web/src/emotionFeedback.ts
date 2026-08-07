import type { SessionInsight } from "./types";

export type EmotionLabel = string;
export type EmotionTrend = string;
export type EmotionSignalSource = "voice" | "facial_expression" | "body_posture";
export type EmotionStreamStatus = "collecting" | "active" | "degraded" | "unavailable";

export interface EmotionSignificantEvent {
  id: string;
  title: string;
  message: string;
  label: EmotionLabel;
  trend: EmotionTrend;
  startsAtSeconds: number;
  confidence: number;
}

export interface EmotionTimelinePoint {
  atSeconds: number;
  level: number;
  label: string;
}

export interface EmotionFeedbackPresentation {
  streamStatus: EmotionStreamStatus;
  currentLabel: EmotionLabel;
  currentTrend: EmotionTrend;
  chipLabel: string;
  detail: string;
  confidenceBand: "high" | "medium" | "insufficient";
  sources: EmotionSignalSource[];
  sustainedSeconds: number;
  timeline: EmotionTimelinePoint[];
  significantEvent?: EmotionSignificantEvent;
}

/** Normalized payload returned by the platform emotion-recognition API. */
export interface EmotionRecognitionResponse {
  streamStatus: EmotionStreamStatus;
  labelCode: string;
  labelDisplay: string;
  trendCode: string;
  trendDisplay: string;
  confidence: number;
  sustainedSeconds: number;
  sources: EmotionSignalSource[];
  timeline: EmotionTimelinePoint[];
  significantEvent?: EmotionSignificantEvent;
}

const timeline: EmotionTimelinePoint[] = [
  { atSeconds: 20, level: 28, label: "平稳" },
  { atSeconds: 80, level: 38, label: "轻微紧张" },
  { atSeconds: 120, level: 62, label: "紧张上升" },
  { atSeconds: 160, level: 78, label: "紧张持续" },
  { atSeconds: 210, level: 52, label: "逐渐放松" },
  { atSeconds: 240, level: 34, label: "趋于平稳" },
];

export function getMockEmotionFeedback(
  elapsedSeconds: number,
  mode: "voice" | "video",
  cameraAvailable: boolean,
): EmotionFeedbackPresentation {
  return adaptEmotionRecognition(getMockEmotionRecognitionResponse(elapsedSeconds, mode, cameraAvailable));
}

export function adaptEmotionRecognition(response: EmotionRecognitionResponse): EmotionFeedbackPresentation {
  const confidenceBand = response.confidence < 0.45 ? "insufficient" : response.confidence < 0.8 ? "medium" : "high";
  return {
    streamStatus: response.streamStatus,
    currentLabel: response.labelCode,
    currentTrend: response.trendCode,
    chipLabel: `情绪动态 · ${response.labelDisplay}`,
    detail: response.trendDisplay ? `${response.labelDisplay} · ${response.trendDisplay}` : response.labelDisplay,
    confidenceBand,
    sources: response.sources,
    sustainedSeconds: response.sustainedSeconds,
    timeline: response.timeline,
    significantEvent: response.significantEvent,
  };
}

/** Demo-only provider. Replace this function with the WebSocket/API response in Builder. */
export function getMockEmotionRecognitionResponse(
  elapsedSeconds: number,
  mode: "voice" | "video",
  cameraAvailable: boolean,
): EmotionRecognitionResponse {
  const sources: EmotionSignalSource[] = mode === "video" && cameraAvailable
    ? ["voice", "facial_expression", "body_posture"]
    : ["voice"];
  const degraded = mode === "video" && !cameraAvailable;
  const base = { sources, timeline, streamStatus: degraded ? "degraded" as const : "active" as const };

  if (elapsedSeconds < 20) return {
    ...base, streamStatus: "collecting", labelCode: "uncertain", labelDisplay: "分析中", trendCode: "insufficient_signal",
    trendDisplay: "正在收集有效信号", confidence: 0.2, sustainedSeconds: 0,
  };
  if (elapsedSeconds < 80) return {
    ...base, labelCode: "calm", labelDisplay: "平稳", trendCode: "stable",
    trendDisplay: "当前表达较稳定", confidence: 0.86, sustainedSeconds: elapsedSeconds - 20,
  };
  if (elapsedSeconds < 160) return {
    ...base, labelCode: "tense", labelDisplay: "紧张上升", trendCode: "rising",
    trendDisplay: "紧张迹象正在缓慢增强", confidence: 0.72, sustainedSeconds: elapsedSeconds - 80,
  };
  if (elapsedSeconds < 190) return {
    ...base, labelCode: "tense", labelDisplay: "紧张持续", trendCode: "stable",
    trendDisplay: "紧张迹象已持续约 2 分钟", confidence: 0.82, sustainedSeconds: elapsedSeconds - 80,
    significantEvent: {
      id: "mock-sustained-tension-160", title: "紧张状态持续", message: "系统观察到紧张状态已持续约 2 分钟",
      label: "tense", trend: "stable", startsAtSeconds: 160, confidence: 0.82,
    },
  };
  if (elapsedSeconds < 240) return {
    ...base, labelCode: "tense", labelDisplay: "逐渐放松", trendCode: "easing",
    trendDisplay: "紧张迹象正在逐渐缓和", confidence: 0.74, sustainedSeconds: elapsedSeconds - 190,
  };
  return {
    ...base, labelCode: "calm", labelDisplay: "趋于平稳", trendCode: "stable",
    trendDisplay: "当前表达重新趋于稳定", confidence: 0.84, sustainedSeconds: elapsedSeconds - 240,
  };
}

export function getEmotionSourceLabel(sources: EmotionSignalSource[], degraded = true): string {
  if (sources.length === 1 && sources[0] === "voice") return degraded ? "语音语调（视频信号中断）" : "语音语调";
  return sources.length > 1 ? "语音 + 表情 + 姿态" : "语音语调";
}

export function toEmotionSessionInsights(sessionId: string, events: EmotionSignificantEvent[]): SessionInsight[] {
  return events.map((event) => ({
    id: `${sessionId}-emotion-${event.id}`,
    sessionId,
    category: "emotion",
    title: event.title,
    detail: `${event.message}（${formatTimestamp(event.startsAtSeconds)}）`,
    sourceType: "emotion_event",
    sourceIds: [event.id],
    confidence: event.confidence,
  }));
}

function formatTimestamp(seconds: number): string {
  return `${String(Math.floor(seconds / 60)).padStart(2, "0")}:${String(seconds % 60).padStart(2, "0")}`;
}
