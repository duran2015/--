import { useState } from "react";
import { motion } from "motion/react";
import { ChevronLeft, ArrowRight } from "lucide-react";
import { useAppStore } from "../../store";

export function MiniAssessmentTest() {
  const { popView, pushView } = useAppStore();
  const [currentQ, setCurrentQ] = useState(0);

  const questions = [
    {
      title: "在过去的两周里，你多久感到有些事情让你心烦意乱？",
      options: ["几乎没有", "有几天", "在一半以上的时间里", "几乎每天"],
    },
    {
      title: "你是否发现自己很难停下来或者控制自己的担忧？",
      options: ["几乎没有", "有几天", "在一半以上的时间里", "几乎每天"],
    },
    {
      title: "你觉得自己有多久处于一种无法放松的状态？",
      options: ["几乎没有", "有几天", "在一半以上的时间里", "几乎每天"],
    },
  ];

  const handleSelect = () => {
    if (currentQ < questions.length - 1) {
      setCurrentQ((prev) => prev + 1);
    } else {
      pushView("mini-assessment-result");
    }
  };

  return (
    <motion.div
      initial={{ x: "100%" }}
      animate={{ x: 0 }}
      exit={{ x: "100%" }}
      className="flex flex-col h-full bg-white absolute inset-0 z-[110]"
    >
      <div className="pt-14 pb-3 px-4 sticky top-0 bg-white z-20 flex items-center justify-between">
        <button
          onClick={popView}
          className="w-10 h-10 -ml-2 flex items-center justify-center text-gray-900 active:bg-gray-50 rounded-full transition-colors"
        >
          <ChevronLeft size={24} />
        </button>
        <span className="text-[14px] font-bold text-gray-500">
          {currentQ + 1} / {questions.length}
        </span>
      </div>

      {/* Progress */}
      <div className="h-1 bg-gray-100 w-full mb-8">
        <motion.div
          initial={false}
          animate={{ width: `${((currentQ + 1) / questions.length) * 100}%` }}
          className="h-full bg-primary"
        />
      </div>

      <div className="flex-1 px-6">
        <h2 className="text-[20px] font-bold text-gray-900 mb-8 leading-snug">
          {questions[currentQ].title}
        </h2>

        <div className="space-y-4">
          {questions[currentQ].options.map((opt, i) => (
            <button
              key={i}
              onClick={handleSelect}
              className="w-full text-left p-4 rounded-xl border border-gray-200 font-medium text-[15px] hover:border-primary hover:bg-primary/5 active:scale-[0.98] transition-all"
            >
              {opt}
            </button>
          ))}
        </div>
      </div>
    </motion.div>
  );
}
