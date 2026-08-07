import { Activity } from "lucide-react";
import { motion } from "motion/react";

import type { EmotionFeedbackPresentation } from "../../emotionFeedback";

export function EmotionStatusChip({ presentation, onOpen }: { presentation: EmotionFeedbackPresentation; onOpen: () => void }) {
  return (
    <motion.button
      layout
      type="button"
      onClick={onOpen}
      aria-label={`${presentation.chipLabel}，查看情绪动态`}
      className="mt-2 inline-flex min-h-12 items-center gap-2 rounded-full border border-white/15 bg-[#EADDFF]/90 px-3.5 py-2 text-[12px] font-bold text-[#21005D] shadow-md backdrop-blur-md pointer-events-auto active:scale-95"
    >
      <Activity size={15} aria-hidden="true" />
      <span aria-live="polite">{presentation.chipLabel}</span>
    </motion.button>
  );
}
