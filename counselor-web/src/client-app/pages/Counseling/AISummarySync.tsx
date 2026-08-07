import { motion } from "motion/react";
import { ChevronLeft, Info, Lock } from "lucide-react";
import { useAppStore } from "../../store";
import { useState } from "react";

export function AISummarySync() {
  const { popView, pushView, bookingSummary, setBookingSummary, bookingOrder } = useAppStore();
  const [isEditing, setIsEditing] = useState(false);
  const [editableSummary, setEditableSummary] = useState(bookingSummary || {
    problem: "最近压力很大，经常内耗",
    feeling: "焦虑、无助、疲惫",
    reason: "职场上遇到了难以处理的人际关系",
    expectation: "希望能有人听我说，帮我梳理情绪"
  });

  const handleSync = () => {
    setBookingSummary({ ...editableSummary, authorized: true });
    if (bookingOrder?.status === "paid") {
      popView(); // 返回到聊天界面
    } else {
      pushView("counseling-booking-confirm"); // 场景 B：进入预约确认
    }
  };

  const handleSkip = () => {
    setBookingSummary({ ...editableSummary, authorized: false });
    if (bookingOrder?.status === "paid") {
      popView(); // 返回到聊天界面
    } else {
      pushView("counseling-booking-confirm"); // 场景 B：进入预约确认
    }
  };

  return (
    <motion.div
      initial={{ opacity: 0, x: 20 }}
      animate={{ opacity: 1, x: 0 }}
      exit={{ opacity: 0, x: 20 }}
      className="absolute inset-0 bg-[#f8f9fa] z-50 flex flex-col"
    >
      <div className="pt-12 pb-3 px-4 bg-white sticky top-0 z-20 flex items-center shadow-sm">
        <button onClick={() => popView()} className="p-2 -ml-2 text-gray-500 hover:text-gray-900 transition-colors">
          <ChevronLeft size={24} />
        </button>
        <div className="flex-1 text-center font-bold text-[16px] text-gray-900 pr-8">
          是否将摘要同步给咨询师？
        </div>
      </div>

      <div className="flex-1 overflow-y-auto px-4 pt-6 pb-24">
        <div className="bg-blue-50/50 border border-blue-100 rounded-xl p-4 mb-6 flex items-start">
          <Info className="text-blue-500 shrink-0 mr-3 mt-0.5" size={18} />
          <div className="text-[13px] text-gray-600 leading-relaxed">
            为了让咨询师更好地理解你的情况，我们可以把 AI 帮你整理的摘要同步给你预约的咨询师。你可以先查看和编辑，确认后再同步。
          </div>
        </div>

        <div className="bg-white rounded-2xl p-5 border border-gray-100 shadow-sm mb-6">
          <div className="flex justify-between items-center mb-4">
            <h3 className="font-bold text-[15px] text-gray-900">咨询前摘要</h3>
            <button 
              onClick={() => setIsEditing(!isEditing)}
              className="text-[13px] font-bold text-[#2CC1C1]"
            >
              {isEditing ? "完成编辑" : "编辑"}
            </button>
          </div>

          <div className="space-y-4">
            <div>
              <div className="text-[12px] font-bold text-gray-500 mb-1.5">主要困扰</div>
              {isEditing ? (
                <input 
                  value={editableSummary.problem}
                  onChange={(e) => setEditableSummary({...editableSummary, problem: e.target.value})}
                  className="w-full bg-gray-50 border border-gray-200 rounded-lg px-3 py-2 text-[14px] text-gray-800 focus:outline-none focus:border-[#2CC1C1]"
                />
              ) : (
                <div className="text-[14px] text-gray-800">{editableSummary.problem}</div>
              )}
            </div>
            
            <div>
              <div className="text-[12px] font-bold text-gray-500 mb-1.5">当前情绪</div>
              {isEditing ? (
                <input 
                  value={editableSummary.feeling}
                  onChange={(e) => setEditableSummary({...editableSummary, feeling: e.target.value})}
                  className="w-full bg-gray-50 border border-gray-200 rounded-lg px-3 py-2 text-[14px] text-gray-800 focus:outline-none focus:border-[#2CC1C1]"
                />
              ) : (
                <div className="text-[14px] text-gray-800">{editableSummary.feeling}</div>
              )}
            </div>

            <div>
              <div className="text-[12px] font-bold text-gray-500 mb-1.5">可能有关的事件</div>
              {isEditing ? (
                <textarea 
                  value={editableSummary.reason}
                  onChange={(e) => setEditableSummary({...editableSummary, reason: e.target.value})}
                  className="w-full bg-gray-50 border border-gray-200 rounded-lg px-3 py-2 text-[14px] text-gray-800 focus:outline-none focus:border-[#2CC1C1] resize-none h-20"
                />
              ) : (
                <div className="text-[14px] text-gray-800">{editableSummary.reason}</div>
              )}
            </div>

            <div>
              <div className="text-[12px] font-bold text-gray-500 mb-1.5">你希望获得的帮助</div>
              {isEditing ? (
                <input 
                  value={editableSummary.expectation}
                  onChange={(e) => setEditableSummary({...editableSummary, expectation: e.target.value})}
                  className="w-full bg-gray-50 border border-gray-200 rounded-lg px-3 py-2 text-[14px] text-gray-800 focus:outline-none focus:border-[#2CC1C1]"
                />
              ) : (
                <div className="text-[14px] text-gray-800">{editableSummary.expectation}</div>
              )}
            </div>
          </div>
        </div>

        <div className="flex items-start justify-center text-gray-400 text-[11px] mt-8 px-4">
          <Lock size={12} className="mr-1.5 shrink-0 mt-0.5" />
          <span className="leading-relaxed">
            我们会保护你的隐私。未经你确认，AI 聊天内容不会直接展示给咨询师。
          </span>
        </div>
      </div>

      <div className="fixed bottom-0 left-0 right-0 p-4 bg-white border-t border-gray-100 z-30 pb-safe">
        <button
          onClick={handleSync}
          className="w-full bg-primary text-white font-bold text-[15px] py-3.5 rounded-2xl active:scale-[0.98] transition-transform mb-3 shadow-[0_4px_15px_rgba(92,110,153,0.2)]"
        >
          {isEditing ? "保存并同步" : "确认同步"}
        </button>
        <button
          onClick={handleSkip}
          className="w-full bg-white text-gray-500 font-bold text-[15px] py-3 rounded-2xl active:bg-gray-50 transition-colors border border-gray-200"
        >
          暂不同步
        </button>
      </div>
    </motion.div>
  );
}
