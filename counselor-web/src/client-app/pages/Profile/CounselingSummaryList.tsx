import { motion } from "motion/react";
import { useAppStore } from "../../store";
import { ChevronLeft, FileText, CalendarClock } from "lucide-react";
import { mockCounselors } from "../../data";
import { EmptyState } from "../../components/EmptyState";

export function CounselingSummaryList() {
  const { popView, pushView, orders } = useAppStore();

  // Filter out completed orders that have notes written
  const summaries = orders.filter(o => o.status === "completed" && o.counselorNotesWritten);

  const getCounselor = (id: string) => {
    return mockCounselors.find((c) => c.id === id) || mockCounselors[0];
  };

  return (
    <motion.div
      initial={{ x: "100%" }}
      animate={{ x: 0 }}
      exit={{ x: "100%" }}
      transition={{ type: "spring", damping: 25, stiffness: 200 }}
      className="flex flex-col h-full bg-[#f8f9fa] absolute inset-0 z-50 overflow-hidden"
    >
      <div className="pt-14 pb-4 px-4 bg-white sticky top-0 z-20 flex items-center shadow-sm">
        <button
          onClick={popView}
          className="w-10 h-10 -ml-2 flex items-center justify-center text-gray-900 border border-transparent active:bg-gray-50 rounded-full transition-colors"
        >
          <ChevronLeft size={24} />
        </button>
        <h1 className="text-[17px] font-bold text-gray-900 ml-2">
          咨询小结与建议
        </h1>
      </div>

      <div className="flex-1 overflow-y-auto p-4">
        {summaries.length === 0 ? (
          <EmptyState
            icon={FileText}
            title="暂时还没有咨询小结"
            description="咨询结束后，咨询师整理的重点回顾和建议会保存在这里。"
            actionLabel="查看预约记录"
            onAction={() => pushView("orders-list")}
          />
        ) : (
          <div className="space-y-4">
            {summaries.map((summary, ind) => {
              const counselor = getCounselor(summary.counselorId);
              return (
                <div
                  key={ind}
                  onClick={() => pushView("counseling-summary-detail")}
                  className="bg-white p-5 rounded-[1.5rem] shadow-sm border border-gray-100 cursor-pointer active:scale-[0.98] transition-transform"
                >
                  <div className="flex items-center justify-between mb-4 pb-4 border-b border-gray-50">
                    <div className="flex items-center space-x-3">
                      <img
                        src={counselor.avatar}
                        alt=""
                        className="w-10 h-10 rounded-full object-cover border border-gray-100"
                      />
                      <div>
                        <h3 className="font-bold text-gray-900 text-[15px]">
                          {counselor.name} 医生的小结
                        </h3>
                        <p className="text-[12px] text-gray-500 mt-0.5">
                          {summary.date} · {summary.time}
                        </p>
                      </div>
                    </div>
                  </div>

                  <div className="text-[13px] text-gray-600 line-clamp-2 leading-relaxed mb-4">
                    本次沟通中，我们探讨了职场人际压力与自我认同感的问题。你在会话后半段展现出了很好的觉察力...
                  </div>

                  <div className="flex items-center justify-between mt-2 pt-2">
                    <span className="text-[12px] font-medium text-green-600 bg-green-50 px-2.5 py-1 rounded-md">
                      包含 1 项建议
                    </span>
                    <span className="text-[12px] font-bold text-gray-900 flex items-center">
                      查看详情 <ChevronLeft size={14} className="rotate-180 ml-1 text-gray-400" />
                    </span>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>
    </motion.div>
  );
}
