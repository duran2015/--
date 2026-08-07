import { motion } from "motion/react";
import { useAppStore } from "../../store";
import { ChevronLeft, MessageSquare, Mic, CalendarClock, ChevronRight, History } from "lucide-react";
import { mockConsultationRecords, mockCounselors } from "../../data";
import { EmptyState } from "../../components/EmptyState";

export function ConsultationRecords() {
  const { popView, pushView, setSelectedConsultationId } = useAppStore();

  const handleSelect = (id: string) => {
    setSelectedConsultationId(id);
    pushView("consultation-detail");
  };

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
          消息沟通记录
        </h1>
      </div>

      <div className="flex-1 overflow-y-auto p-4">
        {mockConsultationRecords.length === 0 ? (
          <EmptyState
            icon={History}
            title="还没有沟通记录"
            description="与咨询师完成文字或语音沟通后，可在这里回顾时间和服务信息。"
            actionLabel="预约真人咨询"
            onAction={() => pushView("counseling-entrance")}
          />
        ) : (
          <div className="space-y-4">
            {mockConsultationRecords.map((record) => {
              const counselor = getCounselor(record.counselorId);
              const isPro = counselor.type === "pro";
              
              return (
                <button
                  key={record.id}
                  onClick={() => handleSelect(record.id)}
                  className="w-full bg-white p-5 rounded-[1.5rem] shadow-sm border border-gray-100 flex flex-col active:scale-[0.98] transition-transform text-left"
                >
                  <div className="flex justify-between items-start mb-3 w-full">
                    <div className="flex items-center space-x-3 flex-1 min-w-0 mr-3">
                      <img
                        src={counselor.avatar}
                        alt=""
                        className="w-12 h-12 rounded-full object-cover shadow-sm bg-gray-100 shrink-0"
                      />
                      <div className="min-w-0 flex-1">
                        <div className="flex items-center space-x-2">
                          <h3 className="font-bold text-gray-900 text-[16px] truncate">
                            {counselor.name}
                          </h3>
                        </div>
                        <p className="text-[12px] text-gray-500 flex items-center mt-1 truncate">
                          <CalendarClock size={12} className="mr-1 shrink-0" />
                          {record.date} · {record.time}
                        </p>
                      </div>
                    </div>
                    <div className="flex items-center justify-center w-8 h-8 bg-gray-50 rounded-full text-gray-400 shrink-0">
                      {record.type === "text" ? <MessageSquare size={16} /> : <Mic size={16} />}
                    </div>
                  </div>

                  <div className="bg-gray-50 p-3.5 rounded-xl w-full mb-3">
                    <p className="text-[13px] text-gray-600 line-clamp-2 leading-relaxed">
                      <span className="font-bold text-gray-700 mr-1.5">咨询摘要：</span>
                      {record.summary}
                    </p>
                  </div>
                  
                  <div className="flex items-center justify-between w-full mt-2">
                    <span className="text-[12px] text-gray-400">
                      {record.type === "text" ? "查看聊天记录与总结" : "查看语音纪要与总结"}
                    </span>
                    <ChevronRight size={16} className="text-gray-300" />
                  </div>
                </button>
              );
            })}
          </div>
        )}
      </div>
    </motion.div>
  );
}
