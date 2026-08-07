import { Activity, Info, Mic2, Video } from "lucide-react";

import { getEmotionSourceLabel, type EmotionFeedbackPresentation } from "../../emotionFeedback";

const confidenceLabel = { high: "较高", medium: "中等", insufficient: "信号不足" } as const;

export function EmotionDynamicsCard({ presentation }: { presentation: EmotionFeedbackPresentation }) {
  const sourceLabel = getEmotionSourceLabel(presentation.sources, presentation.streamStatus === "degraded");
  return (
    <section id="emotion-dynamics" tabIndex={-1} className="rounded-[24px] border border-[#EADDFF] bg-[#F6EDFF] p-4 text-[#21005D] shadow-sm outline-none focus:ring-2 focus:ring-[#6750A4]">
      <div className="flex items-start justify-between gap-3">
        <div>
          <div className="flex items-center gap-1.5 text-[12px] font-black text-[#6750A4]"><Activity size={15} />情绪动态</div>
          <p className="mt-2 text-[16px] font-black">{presentation.chipLabel.replace("情绪动态 · ", "")}</p>
          <p className="mt-1 text-[12px] leading-relaxed text-[#49454F]">{presentation.detail}</p>
        </div>
        <span className="shrink-0 rounded-full bg-white/70 px-2.5 py-1 text-[10px] font-bold text-[#6750A4]">可信度 {confidenceLabel[presentation.confidenceBand]}</span>
      </div>

      <div className="mt-4 flex h-16 items-end gap-1 rounded-[16px] bg-white/55 px-3 pb-2 pt-3" aria-label="最近十分钟情绪趋势">
        {presentation.timeline.map((point) => (
          <div key={point.atSeconds} title={`${point.label} · ${Math.floor(point.atSeconds / 60)}:${String(point.atSeconds % 60).padStart(2, "0")}`} className="flex flex-1 items-end">
            <div className="w-full rounded-full bg-[#6750A4]/55" style={{ height: `${Math.max(12, point.level * 0.48)}px` }} />
          </div>
        ))}
      </div>

      <div className="mt-3 flex items-center justify-between gap-3 rounded-[14px] bg-white/55 px-3 py-2 text-[11px] font-bold text-[#49454F]">
        <span className="flex items-center gap-1.5">{presentation.sources.length > 1 ? <Video size={14} /> : <Mic2 size={14} />}{sourceLabel}</span>
        <span>{presentation.streamStatus === "degraded" ? "已自动降级" : presentation.streamStatus === "collecting" ? "收集中" : "持续分析"}</span>
      </div>

      {presentation.significantEvent && (
        <div className="mt-3 rounded-[14px] border border-[#CAC4D0] bg-white/70 px-3 py-2.5">
          <p className="text-[11px] font-black">关键节点 · 02:40</p>
          <p className="mt-1 text-[11px] leading-relaxed text-[#49454F]">{presentation.significantEvent.message}</p>
        </div>
      )}

      <p className="mt-3 flex gap-1.5 text-[10px] leading-relaxed text-[#625B71]"><Info size={13} className="mt-0.5 shrink-0" />AI 结果仅用于辅助观察，请结合对话内容和专业判断。</p>
    </section>
  );
}
