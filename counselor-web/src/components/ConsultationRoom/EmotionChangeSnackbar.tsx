import { Activity, X } from "lucide-react";

import type { EmotionSignificantEvent } from "../../emotionFeedback";

export function EmotionChangeSnackbar({ event, onOpen, onDismiss }: { event: EmotionSignificantEvent; onOpen: () => void; onDismiss: () => void }) {
  return (
    <div role="status" className="absolute bottom-28 left-1/2 z-[80] flex w-[calc(100%-32px)] max-w-md -translate-x-1/2 items-center gap-3 rounded-[18px] bg-[#322F35] p-3 pl-4 text-white shadow-2xl">
      <Activity className="shrink-0 text-[#D0BCFF]" size={20} />
      <p className="min-w-0 flex-1 text-[12px] font-medium leading-relaxed">{event.message}</p>
      <button type="button" onClick={onOpen} className="min-h-10 shrink-0 rounded-full px-2 text-[12px] font-black text-[#D0BCFF]">查看动态</button>
      <button type="button" onClick={onDismiss} aria-label="关闭提示" className="grid h-10 w-10 shrink-0 place-items-center rounded-full hover:bg-white/10"><X size={18} /></button>
    </div>
  );
}
