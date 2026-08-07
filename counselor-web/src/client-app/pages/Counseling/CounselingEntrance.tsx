import { useState } from "react";
import { motion } from "motion/react";
import { ChevronLeft } from "lucide-react";
import { useAppStore } from "../../store";

export function CounselingEntrance() {
  const { popView, pushView } = useAppStore();
  const [selectedTopic, setSelectedTopic] = useState<string | null>(null);

  const topics = [
    "情绪压力",
    "亲密关系",
    "家庭关系",
    "职场心理",
    "婚恋情感",
    "睡眠困扰",
    "自我成长",
    "其他"
  ];

  return (
    <motion.div
      initial={{ x: "100%" }}
      animate={{ x: 0 }}
      exit={{ x: "100%" }}
      transition={{ type: "spring", damping: 25, stiffness: 200 }}
      className="absolute inset-0 bg-[#f8f9fa] z-50 flex flex-col"
    >
      <div className="pt-12 pb-3 px-4 bg-white sticky top-0 z-20 flex items-center shadow-sm">
        <button onClick={() => popView()} className="p-2 -ml-2 text-gray-500 hover:text-gray-900 transition-colors">
          <ChevronLeft size={24} />
        </button>
        <div className="flex-1 text-center font-bold text-[16px] text-gray-900 pr-8">
          真人咨询
        </div>
      </div>

      <div className="flex-1 overflow-y-auto px-5 pt-8 pb-32">
        <h2 className="text-[22px] font-black text-gray-900 mb-2">你这次主要想聊什么？</h2>
        <p className="text-[13px] text-gray-500 mb-8 leading-relaxed">
          选择一个最接近的方向，我们会帮你找到更合适的支持方式。
        </p>

        <div className="grid grid-cols-2 gap-3">
          {topics.map(topic => (
            <button
              key={topic}
              onClick={() => setSelectedTopic(topic)}
              className={`py-4 px-4 rounded-[1.2rem] text-left transition-all font-bold text-[15px] border-2 ${
                selectedTopic === topic 
                  ? 'bg-primary/5 border-primary text-primary shadow-[0_4px_15px_rgba(44,193,193,0.15)]' 
                  : 'bg-white border-transparent text-gray-700 shadow-sm active:scale-95'
              }`}
            >
              {topic}
            </button>
          ))}
        </div>
      </div>

      <div className="absolute bottom-0 left-0 right-0 p-5 bg-white border-t border-gray-100 shadow-[0_-10px_40px_rgba(0,0,0,0.03)] z-30 pb-safe">
        <button
          disabled={!selectedTopic}
          onClick={() => pushView("counselor-list")}
          className={`w-full py-3.5 rounded-2xl font-bold text-[15px] transition-all ${
            selectedTopic 
              ? 'bg-gray-900 text-white active:scale-[0.98] shadow-md shadow-gray-900/20' 
              : 'bg-gray-100 text-gray-400 cursor-not-allowed'
          }`}
        >
          下一步，查看咨询师
        </button>
      </div>
    </motion.div>
  );
}
