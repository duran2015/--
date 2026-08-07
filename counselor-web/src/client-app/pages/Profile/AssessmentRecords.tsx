import { motion } from "motion/react";
import {
  ChevronLeft,
  FileSpreadsheet,
  Activity,
  AlertCircle,
  ArrowRight,
} from "lucide-react";
import { useAppStore } from "../../store";
import { EmptyState } from "../../components/EmptyState";

export function AssessmentRecords() {
  const { popView, pushView, assessmentRecords } = useAppStore();

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
          量表测试记录
        </h1>
      </div>

      <div className="flex-1 overflow-y-auto pb-32">
        <div className="p-4 space-y-4">
          <div className="space-y-3 mt-2">
            {assessmentRecords.length === 0 ? (
              <EmptyState
                compact
                icon={FileSpreadsheet}
                title="还没有测评记录"
                description="完成一次专业量表，了解最近的情绪状态与变化趋势。"
                actionLabel="开始心理测评"
                onAction={() => pushView("mini-assessment-home")}
              />
            ) : (
              assessmentRecords.map((record) => (
                <button
                  key={record.id}
                  onClick={() => pushView("assessment-report-detail" as any)}
                  className="w-full bg-white rounded-[1.5rem] p-5 flex flex-col border border-gray-100 shadow-[0_2px_10px_rgba(0,0,0,0.02)] active:scale-[0.98] transition-transform text-left"
                >
                  <div className="flex justify-between items-start mb-4">
                    <div>
                      <h3 className="font-bold text-[15px] text-gray-900 mb-1">
                        {record.title}
                      </h3>
                      <p className="text-[11px] text-gray-400 font-medium">
                        {record.date}
                      </p>
                    </div>
                    <div className="flex items-center space-x-1 bg-gray-50 px-2 py-1 rounded-md">
                      <Activity size={12} className="text-primary" />
                      <span className="text-[12px] font-bold text-primary">
                        {record.score}
                      </span>
                    </div>
                  </div>

                  <div className="flex items-center justify-between w-full pt-4 border-t border-gray-50">
                    <div className="flex items-center">
                      <span
                        className={`text-[12px] font-bold px-2 py-0.5 rounded-md bg-blue-50 text-blue-600`}
                      >
                        {record.result}
                      </span>
                    </div>
                    <div className="flex items-center text-gray-400 group-hover:text-primary transition-colors">
                      <span className="text-[11px] mr-1">查看报告</span>
                      <ArrowRight size={14} />
                    </div>
                  </div>
                </button>
              ))
            )}
          </div>
        </div>
      </div>
    </motion.div>
  );
}
