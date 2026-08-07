import { useState } from "react";
import { motion, AnimatePresence } from "motion/react";
import { ChevronLeft, Share2, Download, X } from "lucide-react";
import { useAppStore } from "../../store";

export function MiniAssessmentResult() {
  const { popView, pushView } = useAppStore();
  const [showShare, setShowShare] = useState(false);
  const [showAppDownload, setShowAppDownload] = useState(false);

  return (
    <motion.div
      initial={{ x: "100%" }}
      animate={{ x: 0 }}
      exit={{ x: "100%" }}
      className="flex flex-col h-full bg-[#f4f5f7] absolute inset-0 z-[120] overflow-hidden"
    >
      <div className="pt-14 pb-3 px-4 sticky top-0 flex items-center justify-between z-20">
        <button
          onClick={() => {
            popView();
            popView();
          }}
          className="w-10 h-10 -ml-2 flex items-center justify-center text-gray-900 active:bg-gray-200 bg-white/50 backdrop-blur rounded-full transition-colors"
        >
          <ChevronLeft size={24} />
        </button>
      </div>

      <div className="flex-1 overflow-y-auto px-4 pb-32 -mt-16">
        {/* Result Card Image (Simulated) */}
        <div
          id="result-card"
          className="bg-gradient-to-br from-indigo-800 to-indigo-900 rounded-[2rem] p-6 text-white shadow-xl mt-16 relative overflow-hidden"
        >
          <div className="absolute top-0 right-0 w-32 h-32 bg-white/5 rounded-bl-full pointer-events-none" />
          <h2 className="text-[12px] opacity-80 mb-2 font-medium tracking-widest uppercase">
            焦虑自评测试 - 结果
          </h2>
          <div className="flex items-end mb-6">
            <span className="text-5xl font-black mr-2">12</span>
            <span className="text-[14px] opacity-80 pb-1">分</span>
          </div>
          <h3 className="text-[20px] font-bold mb-3 text-amber-300">
            中度焦虑
          </h3>
          <p className="text-[13px] leading-relaxed opacity-90 mb-6">
            你的焦虑水平目前处于中等状态，可能有持续几天感到心烦意乱或紧张。可以尝试寻找专业的疏导或进行短时间的放松冥想。
          </p>
          <div className="absolute -bottom-4 right-4 flex items-center space-x-1.5 opacity-80 mix-blend-overlay">
            <span className="text-[10px] font-bold text-gray-400 tracking-widest">
              小鹿 生成
            </span>
            <div className="w-4 h-4 bg-gray-200 rounded-full flex items-center justify-center text-[8px]">
              🦌
            </div>
          </div>
        </div>

        {/* Actions */}
        <div className="mt-8 space-y-3">
          <button
            onClick={() => {
              popView();
            }}
            className="w-full bg-indigo-600 text-white font-bold py-4 rounded-xl flex items-center justify-center shadow-lg shadow-indigo-600/30 active:scale-95 transition-transform"
          >
            完成
          </button>
        </div>
      </div>
    </motion.div>
  );
}
