import { motion } from "motion/react";
import { ChevronLeft, MessageSquare, Clock, ArrowRight } from "lucide-react";
import { useAppStore } from "../../store";

export function AIChatRecords() {
  const { popView } = useAppStore();

  const sessions = [
    {
      id: 1,
      date: "今天",
      time: "上午 10:30",
      title: "关于项目截止日期的焦虑",
      duration: "15 分钟",
      mood: "焦虑缓解",
      msgs: 24,
    },
    {
      id: 2,
      date: "昨天",
      time: "晚上 23:15",
      title: "难以入睡的深夜思绪",
      duration: "22 分钟",
      mood: "逐渐平静",
      msgs: 38,
    },
    {
      id: 3,
      date: "5月14日",
      time: "下午 14:00",
      title: "和同事沟通不畅的困扰",
      duration: "8 分钟",
      mood: "获得力量",
      msgs: 12,
    },
    {
      id: 4,
      date: "5月10日",
      time: "晚上 21:30",
      title: "周末的无意义感",
      duration: "35 分钟",
      mood: "深度探索",
      msgs: 56,
    },
  ];

  return (
    <motion.div
      initial={{ x: "100%" }}
      animate={{ x: 0 }}
      exit={{ x: "100%" }}
      transition={{ type: "spring", damping: 25, stiffness: 200 }}
      className="flex flex-col h-full bg-[#f8f9fa] absolute inset-0 z-50 overflow-hidden"
    >
      <div className="pt-14 pb-4 px-4 bg-white/80 backdrop-blur-md sticky top-0 z-20 flex items-center shadow-sm">
        <button
          onClick={popView}
          className="w-10 h-10 -ml-2 flex items-center justify-center text-gray-900 border border-transparent active:bg-gray-50 rounded-full transition-colors"
        >
          <ChevronLeft size={24} />
        </button>
        <h1 className="text-[17px] font-bold text-gray-900 ml-2">
          小鹿陪伴记录
        </h1>
      </div>

      <div className="flex-1 overflow-y-auto pb-32">
        <div className="p-4 space-y-3">
          <div className="flex justify-between items-center px-2 py-4 mb-2">
            <div className="flex flex-col items-center flex-1 border-r border-gray-200 last:border-0">
              <span className="text-[20px] font-black text-gray-900 leading-none mb-1">
                128
              </span>
              <span className="text-[10px] text-gray-500 font-medium tracking-wide">
                总交互/次
              </span>
            </div>
            <div className="flex flex-col items-center flex-1 border-r border-gray-200 last:border-0">
              <span className="text-[20px] font-black text-primary leading-none mb-1">
                3.5
              </span>
              <span className="text-[10px] text-gray-500 font-medium tracking-wide">
                平均时长/时
              </span>
            </div>
            <div className="flex flex-col items-center flex-1">
              <span className="text-[20px] font-black text-gray-900 leading-none mb-1">
                14
              </span>
              <span className="text-[10px] text-gray-500 font-medium tracking-wide">
                连续互动/天
              </span>
            </div>
          </div>

          <h2 className="text-[13px] font-bold text-gray-500 px-2 pt-2 mb-2">
            历史记录
          </h2>

          <div className="space-y-3">
            {sessions.map((session) => (
              <div
                key={session.id}
                className="bg-white rounded-[1.5rem] p-4 border border-gray-100 shadow-sm active:scale-[0.98] transition-transform"
              >
                <div className="flex justify-between items-start mb-3">
                  <div className="flex items-center text-[12px] text-gray-500">
                    <Clock size={12} className="mr-1.5" />
                    <span className="font-medium mr-2">{session.date}</span>
                    <span>{session.time}</span>
                  </div>
                  <div className="text-[10px] text-primary font-bold bg-primary/10 px-2 py-0.5 rounded-full">
                    {session.mood}
                  </div>
                </div>

                <h3 className="font-bold text-[15px] text-gray-900 mb-3">
                  {session.title}
                </h3>

                <div className="flex items-center justify-between mt-2 pt-3 border-t border-gray-50">
                  <div className="flex space-x-4">
                    <div className="flex items-center text-[11px] text-gray-400 font-medium">
                      <MessageSquare size={12} className="mr-1" />
                      {session.msgs} 条交互
                    </div>
                  </div>
                  <div className="flex items-center text-[11px] text-gray-400 font-medium group cursor-pointer">
                    查看详情
                    <ArrowRight size={12} className="ml-1" />
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </motion.div>
  );
}
