import { motion } from "motion/react";
import {
  ChevronLeft,
  Radar,
  Search,
  Target,
  Brain,
  ArrowUpRight,
  Flame,
} from "lucide-react";
import { useAppStore } from "../../store";

export function ProfileReport() {
  const { popView } = useAppStore();

  return (
    <motion.div
      initial={{ x: "100%" }}
      animate={{ x: 0 }}
      exit={{ x: "100%" }}
      transition={{ type: "spring", damping: 25, stiffness: 200 }}
      className="flex flex-col h-full bg-[#f8f9fa] absolute inset-0 z-50 overflow-hidden"
    >
      <div className="pt-14 pb-4 px-4 bg-white/80 backdrop-blur-md sticky top-0 z-20 flex items-center border-b border-gray-100">
        <button
          onClick={popView}
          className="w-10 h-10 -ml-2 flex items-center justify-center text-gray-900 border border-transparent active:bg-gray-50 rounded-full transition-colors"
        >
          <ChevronLeft size={24} />
        </button>
        <h1 className="text-[17px] font-bold text-gray-900 ml-2">
          动态心理画像
        </h1>
      </div>

      <div className="flex-1 overflow-y-auto pb-32">
        <div className="p-5 space-y-6">
          {/* Header */}
          <div className="bg-gradient-to-br from-indigo-500 to-primary text-white rounded-[2rem] p-6 shadow-md relative overflow-hidden">
            <div className="absolute top-0 right-0 w-32 h-32 bg-white/10 rounded-bl-full pointer-events-none" />
            <div className="absolute bottom-0 left-0 w-24 h-24 bg-black/10 rounded-tr-full pointer-events-none" />
            <div className="relative z-10">
              <div className="flex items-center text-indigo-100 text-xs mb-3">
                <Brain size={16} className="mr-2" />
                画像中枢 Agent 更新于 2小时前
              </div>
              <h2 className="text-2xl font-black mb-1">
                "高敏捷 / 内向探索者"
              </h2>
              <p className="text-sm text-indigo-50 leading-relaxed mb-4 opacity-90">
                你具有极强的自我反思能力，能够敏锐捕捉细微情绪，但近期应对外界变化时能量消耗较快。
              </p>
              <div className="flex space-x-2">
                <span className="bg-white/20 backdrop-blur-md px-3 py-1 rounded-full text-xs font-bold border border-white/20">
                  感知力 92
                </span>
                <span className="bg-white/20 backdrop-blur-md px-3 py-1 rounded-full text-xs font-bold border border-white/20">
                  适应力 68
                </span>
              </div>
            </div>
          </div>

          {/* Traits */}
          <div>
            <h3 className="text-[15px] font-bold mb-4 flex items-center text-gray-900">
              <span className="w-1 h-3.5 bg-primary rounded-full mr-2"></span>
              核心特质演变
            </h3>
            <div className="grid grid-cols-2 gap-3">
              {[
                {
                  title: "独立思考",
                  desc: "不轻易盲从",
                  trend: "up",
                  color: "text-blue-500",
                  bg: "bg-blue-50",
                  icon: Target,
                },
                {
                  title: "情绪颗粒度",
                  desc: "感受层次丰富",
                  trend: "up",
                  color: "text-purple-500",
                  bg: "bg-purple-50",
                  icon: Search,
                },
                {
                  title: "完美主义",
                  desc: "容易导致内耗",
                  trend: "steady",
                  color: "text-orange-500",
                  bg: "bg-orange-50",
                  icon: Flame,
                },
                {
                  title: "人际边界",
                  desc: "目前偏向收缩",
                  trend: "down",
                  color: "text-indigo-500",
                  bg: "bg-indigo-50",
                  icon: Radar,
                },
              ].map((item, i) => (
                <div
                  key={i}
                  className="bg-white p-4 rounded-2xl border border-gray-100 shadow-sm flex flex-col items-start relative overflow-hidden"
                >
                  <div
                    className={`w-8 h-8 rounded-full ${item.bg} ${item.color} flex items-center justify-center mb-3`}
                  >
                    <item.icon size={16} />
                  </div>
                  <h4 className="font-bold text-[14px] text-gray-900 mb-0.5">
                    {item.title}
                  </h4>
                  <p className="text-[11px] text-gray-500">{item.desc}</p>
                  {item.trend === "up" && (
                    <ArrowUpRight
                      size={16}
                      className="absolute top-4 right-4 text-green-500"
                    />
                  )}
                </div>
              ))}
            </div>
          </div>

          {/* Activity Insights */}
          <div>
            <h3 className="text-[15px] font-bold mb-4 flex items-center text-gray-900">
              <span className="w-1 h-3.5 bg-primary rounded-full mr-2"></span>
              近期触发节点
            </h3>
            <div className="bg-white rounded-2xl border border-gray-100 p-5 shadow-sm space-y-4">
              <div className="border-l-2 border-primary/30 pl-4 py-1 relative">
                <div className="absolute w-2 h-2 rounded-full bg-primary -left-[5px] top-2" />
                <span className="text-[10px] text-gray-400 font-bold mb-1 block">
                  本周二 晚上
                </span>
                <p className="text-[13px] text-gray-800 leading-relaxed font-medium">
                  连续工作后完成情况低于预期，引发了自我批评（完美主义触发）。
                </p>
              </div>
              <div className="border-l-2 border-green-500/30 pl-4 py-1 relative">
                <div className="absolute w-2 h-2 rounded-full bg-green-500 -left-[5px] top-2" />
                <span className="text-[10px] text-gray-400 font-bold mb-1 block">
                  上周日 下午
                </span>
                <p className="text-[13px] text-gray-800 leading-relaxed font-medium">
                  参加了社交活动，初始紧张但后半段逐渐放松（适应力缓慢回升）。
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </motion.div>
  );
}
