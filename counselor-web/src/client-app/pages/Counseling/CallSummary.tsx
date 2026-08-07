import { useState } from "react";
import { motion } from "motion/react";
import { useAppStore } from "../../store";
import {
  CheckCircle2,
  Sparkles,
  ChevronLeft,
  FileQuestion,
} from "lucide-react";
import { MissingDataPage } from "../../components/EmptyState";

export function CallSummary() {
  const { resetToView, popView, pushView, bookingOrder, selectedCounselorOrder, consultationWorkflow } = useAppStore();
  
  // 区分是咨询师端还是用户端
  const isCounselorView = !!selectedCounselorOrder;
  const order = isCounselorView ? selectedCounselorOrder : bookingOrder;
  const sharedReview = consultationWorkflow.messages.find(
    (message) => message.audience === "client" && message.orderId === order?.id,
  );
  const clientSummary = sharedReview?.clientSummary;

  // 咨询师端专属状态
  const [counselorAdvice, setCounselorAdvice] = useState("");
  const [internalNotes, setInternalNotes] = useState("");
  
  const [addedToPlan, setAddedToPlan] = useState(false);
  const evaluationTask = consultationWorkflow.tasks.find(
    (task) => task.orderId === order?.id && task.actorRole === "client" && task.taskType === "review_counselor",
  );
  const needsEvaluation = !isCounselorView && evaluationTask?.status !== "completed" && !(order as { isEvaluated?: boolean } | null)?.isEvaluated;

  // Mock Tasks generated from session
  const tasks = (clientSummary?.actionItems || [
    "睡前尝试 5 分钟的躯体扫描静观",
    "当恐慌感袭来时，进行 4-7-8 呼吸法",
  ]).map((text) => ({ text, done: false }));

  if (!isCounselorView && (!order || !sharedReview)) {
    return <MissingDataPage icon={FileQuestion} title="咨询回顾尚未送达" description="咨询师确认并提交后，你会在消息和预约详情中收到回顾入口。" onBack={popView} actionLabel="返回预约详情" />;
  }

  return (
    <motion.div
      initial={{ x: "100%" }}
      animate={{ x: 0 }}
      exit={{ x: "100%" }}
      transition={{ type: "spring", damping: 25, stiffness: 200 }}
      className="flex flex-col h-full bg-surface absolute inset-0 z-50 overflow-hidden"
    >
      <div className="pt-14 pb-4 px-4 bg-white sticky top-0 z-10 flex items-center border-b border-gray-50 shadow-sm">
        <button onClick={popView} aria-label="返回" className="grid h-10 w-10 place-items-center rounded-full text-gray-700 active:bg-gray-100"><ChevronLeft size={22} /></button>
        <h1 className="text-[17px] font-bold flex-1 text-center text-gray-900">
          本次咨询回顾
        </h1>
        <div className="h-10 w-10" />
      </div>

      <div className="flex-1 overflow-y-auto pb-32">
        <div className="p-4 space-y-4">
          
          {/* 小鹿 Generated Notes (双方可见，文案稍有不同) */}
          <div className="bg-white p-6 rounded-[2rem] shadow-sm border border-gray-100">
            <h2 className="font-bold text-[16px] text-gray-900 mb-4 flex items-center">
              <Sparkles size={20} className="mr-2 text-primary" /> 
              {isCounselorView ? "小鹿预整理咨询纪要" : "小鹿整理的咨询纪要"}
            </h2>
            <div className="space-y-4 text-[14px] text-gray-700 leading-loose tracking-wide">
              <div className="bg-primary/5 p-4 rounded-2xl">
                <span className="text-sm font-bold text-primary block mb-1">
                  本次核心探讨：
                </span>
                {clientSummary?.recap || "探讨了近期压力、情绪变化以及这些体验与日常生活之间的联系。"}
              </div>
              {!isCounselorView && (
                <div className="p-4 bg-surface rounded-2xl border border-gray-50">
                  <span className="text-sm font-bold text-gray-900 block mb-1">
                    咨询师赠言：
                  </span>
                  {clientSummary?.nextPlan || "下次会谈将继续回顾这段时间的变化，并一起调整适合你的行动节奏。"}
                </div>
              )}
            </div>
          </div>

          {/* 用户端：行动建议与计划 */}
          {!isCounselorView && (
            <div className="bg-white p-6 rounded-[2rem] shadow-sm border border-gray-100">
              <h2 className="font-bold text-[16px] text-gray-900 mb-4 flex items-center">
                <CheckCircle2 size={20} className="mr-2 text-gray-900" />{" "}
                本周课后行动建议
              </h2>
              <div className="space-y-3">
                {tasks.map((task, i) => (
                  <div
                    key={i}
                    className="flex items-start space-x-3 p-3 bg-surface rounded-xl border border-gray-100"
                  >
                    <div className="mt-0.5 w-4 h-4 rounded-full border border-primary shrink-0 bg-white"></div>
                    <span className="text-sm text-gray-700 leading-snug">
                      {task.text}
                    </span>
                  </div>
                ))}
              </div>
              <button 
                onClick={() => setAddedToPlan(true)}
                disabled={addedToPlan}
                className={`w-full mt-4 py-3 border rounded-xl text-[13px] font-medium transition-colors flex justify-center items-center ${addedToPlan ? 'bg-gray-50 border-gray-100 text-gray-400' : 'border-gray-200 bg-white text-gray-600 active:bg-gray-50'}`}
              >
                {addedToPlan ? '已加入行动计划' : '加入行动计划'}
              </button>
            </div>
          )}

          {/* 咨询师端：输入给用户的建议与定性总结 */}
          {isCounselorView && (
            <>
              <div className="bg-white p-6 rounded-[2rem] shadow-sm border border-gray-100">
                <h2 className="font-bold text-[16px] text-gray-900 mb-2">给用户的建议/行动计划</h2>
                <p className="text-[12px] text-gray-400 mb-4">这些内容将会展示在用户的咨询纪要中</p>
                <textarea
                  value={counselorAdvice}
                  onChange={(e) => setCounselorAdvice(e.target.value)}
                  placeholder="例如：建议尝试每天睡前进行 5 分钟的呼吸放松练习..."
                  className="w-full bg-surface text-sm p-4 rounded-xl resize-none outline-none focus:border-primary/50 border border-transparent transition-colors"
                  rows={4}
                />
              </div>

              <div className="bg-white p-6 rounded-[2rem] shadow-sm border border-gray-100">
                <h2 className="font-bold text-[16px] text-gray-900 mb-2">定性总结（内部记录）</h2>
                <p className="text-[12px] text-gray-400 mb-4">仅自己和督导可见，不对用户展示</p>
                <textarea
                  value={internalNotes}
                  onChange={(e) => setInternalNotes(e.target.value)}
                  placeholder="记录本次咨询的核心难点、用户表现及后续跟进方向..."
                  className="w-full bg-orange-50/50 text-sm p-4 rounded-xl resize-none outline-none focus:border-orange-200 border border-transparent transition-colors placeholder:text-orange-300"
                  rows={4}
                />
              </div>
            </>
          )}

        </div>
      </div>

      <div className="absolute bottom-0 left-0 right-0 p-5 bg-white border-t border-gray-100 shadow-[0_-10px_40px_rgba(0,0,0,0.03)] z-20">
        <button
          onClick={() => {
            if (isCounselorView) {
              resetToView("counselor-workbench");
            } else if (needsEvaluation) {
              pushView("user-evaluation" as any);
            } else {
              popView();
            }
          }}
          className="w-full bg-gray-900 text-white font-bold py-4 rounded-full active:bg-gray-800 transition-colors shadow-md shadow-gray-900/20 text-[15px]"
        >
          {isCounselorView ? "保存并结束服务" : needsEvaluation ? "评价咨询师" : "完成并关闭"}
        </button>
      </div>
    </motion.div>
  );
}
