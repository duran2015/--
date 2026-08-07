import { motion } from "motion/react";
import { ChevronLeft, Target, ArrowRight } from "lucide-react";
import { useAppStore } from "../../store";

export function MiniAssessmentHome() {
  const { popView, pushView } = useAppStore();

  const tests = [
    {
      id: 1,
      title: "工作压力指数核查",
      desc: "了解你当前的疲劳与压力水平",
      queries: "10题",
      users: "1.2w 人测过",
      color: "text-blue-500",
      bg: "bg-blue-50",
    },
    {
      id: 2,
      title: "焦虑自评表 (GAD-7)",
      desc: "经典的焦虑情绪自测工具",
      queries: "7题",
      users: "2.5w 人测过",
      color: "text-rose-500",
      bg: "bg-rose-50",
    },
    {
      id: 3,
      title: "情绪耗竭评估",
      desc: "你是否正在经历情绪倦怠",
      queries: "12题",
      users: "8k 人测过",
      color: "text-purple-500",
      bg: "bg-purple-50",
    },
  ];

  return (
    <motion.div
      initial={{ x: "100%" }}
      animate={{ x: 0 }}
      exit={{ x: "100%" }}
      className="flex flex-col h-full bg-[#f4f5f7] absolute inset-0 z-[100] overflow-hidden"
    >
      <div className="pt-14 pb-3 px-4 bg-white sticky top-0 z-20 flex items-center shadow-sm">
        <button
          onClick={popView}
          className="w-10 h-10 -ml-2 flex items-center justify-center text-gray-900 active:bg-gray-50 rounded-full transition-colors"
        >
          <ChevronLeft size={24} />
        </button>
        <h1 className="text-[17px] font-bold text-gray-900 ml-2">
          心理测评系统
        </h1>
      </div>

      <div className="flex-1 overflow-y-auto p-4 space-y-4">
        {/* Banner */}
        <div className="bg-gradient-to-br from-indigo-500 to-primary text-white p-5 rounded-2xl shadow-sm relative overflow-hidden">
          <div className="absolute right-0 bottom-0 w-24 h-24 bg-white/10 rounded-tl-full pointer-events-none" />
          <h2 className="text-[18px] font-bold mb-2">认识更真实的自己</h2>
          <p className="text-[13px] opacity-90 leading-relaxed mb-4">
            通过专业的心理量表，了解当前的情绪与心理压力状态。
          </p>
        </div>

        <h3 className="font-bold text-gray-900 px-1 mt-6 mb-2">精选测评</h3>

        <div className="space-y-3">
          {tests.map((test) => (
            <button
              key={test.id}
              onClick={() => pushView("mini-assessment-test")}
              className="w-full bg-white p-4 rounded-2xl border border-gray-100 shadow-[0_2px_10px_rgba(0,0,0,0.02)] active:scale-[0.98] transition-transform text-left flex items-center"
            >
              <div
                className={`w-12 h-12 rounded-xl flex items-center justify-center mr-4 ${test.bg} ${test.color}`}
              >
                <Target size={24} />
              </div>
              <div className="flex-1">
                <h4 className="font-bold text-[15px] text-gray-900 mb-0.5">
                  {test.title}
                </h4>
                <p className="text-[11px] text-gray-400 mb-2">{test.desc}</p>
                <div className="flex space-x-3 text-[10px] text-gray-500">
                  <span>{test.queries}</span>
                  <span>{test.users}</span>
                </div>
              </div>
              <ArrowRight size={16} className="text-gray-300" />
            </button>
          ))}
        </div>
      </div>
    </motion.div>
  );
}
