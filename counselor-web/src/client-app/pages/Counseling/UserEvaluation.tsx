import { useState } from "react";
import { motion } from "motion/react";
import { useAppStore } from "../../store";
import { ArrowLeft, Star, Heart, CheckCircle2, CalendarPlus, ActivitySquare, MessageSquareOff } from "lucide-react";
import { mockCounselors } from "../../data";
import { MissingDataPage } from "../../components/EmptyState";
import { isStructuredEvaluationComplete } from "../../../clientJourneyPresentation";

export function UserEvaluation() {
  const { popView, bookingOrder, updateOrder, pushView, selectedCounselorId, consultationWorkflow, completeWorkflowTask } = useAppStore();
  const [rating, setRating] = useState(5);
  const [tags, setTags] = useState<string[]>([]);
  const [comment, setComment] = useState("");
  
  // SOP Structured Evaluation State
  const [structuredEval, setStructuredEval] = useState({
    feltUnderstood: null as boolean | null,
    wasHelpful: null as boolean | null,
    willBookAgain: null as boolean | null
  });

  const [submitted, setSubmitted] = useState(false);

  const availableTags = ["温柔耐心", "专业见解深", "认知行为学派", "倾听者", "一针见血"];

  if (!bookingOrder) {
    return <MissingDataPage icon={MessageSquareOff} title="暂时无法评价" description="没有找到对应的已完成服务。请从预约记录中选择一笔已结束的咨询后再评价。" onBack={popView} actionLabel="返回预约记录" />;
  }

  const sharedSummary = consultationWorkflow.messages.find(
    (message) => message.orderId === bookingOrder.id && message.audience === "client" && message.status === "shared",
  );
  const recapTask = consultationWorkflow.tasks.find(
    (task) => task.orderId === bookingOrder.id && task.actorRole === "client" && task.taskType === "read_session_recap",
  );
  if (!submitted && (!sharedSummary || (recapTask && recapTask.status !== "completed"))) {
    return <MissingDataPage icon={MessageSquareOff} title="请先查看咨询回顾" description="咨询师提交回顾后，请先阅读回顾和行动建议，再完成本次服务评价。" onBack={popView} actionLabel="返回预约详情" />;
  }

  const counselor = mockCounselors.find((c) => c.id === bookingOrder.counselorId);

  if (submitted) {
    return (
      <motion.div
        initial={{ x: "100%" }}
        animate={{ x: 0 }}
        exit={{ x: "100%" }}
        transition={{ type: "spring", damping: 25, stiffness: 200 }}
        className="absolute inset-0 bg-[#f8f9fa] z-50 flex flex-col items-center justify-center p-6"
      >
        <div className="w-20 h-20 bg-green-100 rounded-full flex items-center justify-center mb-6">
          <CheckCircle2 size={40} className="text-green-500" />
        </div>
        <h2 className="text-[20px] font-bold text-gray-900 mb-2">评价提交成功</h2>
        <p className="text-[14px] text-gray-500 text-center mb-10">
          感谢你的反馈，这有助于我们提供更好的服务。
        </p>

        <div className="w-full space-y-3">
          <button 
            onClick={() => { popView(); pushView("counseling-booking"); }}
            className="w-full bg-white p-4 rounded-2xl flex items-center shadow-sm border border-gray-100 active:scale-[0.98] transition-transform"
          >
            <div className="w-12 h-12 bg-blue-50 rounded-xl flex items-center justify-center mr-4">
              <CalendarPlus size={24} className="text-blue-500" />
            </div>
            <div className="text-left flex-1">
              <div className="text-[15px] font-bold text-gray-900 mb-1">继续预约该咨询师</div>
              <div className="text-[12px] text-gray-500">保持连续的咨询节奏</div>
            </div>
            <ArrowLeft size={16} className="text-gray-400 rotate-180" />
          </button>

          <button 
            onClick={() => { popView(); pushView("ai-chat"); }}
            className="w-full bg-white p-4 rounded-2xl flex items-center shadow-sm border border-gray-100 active:scale-[0.98] transition-transform"
          >
            <div className="w-12 h-12 bg-primary/10 rounded-xl flex items-center justify-center mr-4">
              <ActivitySquare size={24} className="text-primary" />
            </div>
            <div className="text-left flex-1">
              <div className="text-[15px] font-bold text-gray-900 mb-1">使用 AI 情绪记录</div>
              <div className="text-[12px] text-gray-500">日常巩固咨询效果</div>
            </div>
            <ArrowLeft size={16} className="text-gray-400 rotate-180" />
          </button>

          <button 
            onClick={popView}
            className="w-full py-4 text-[14px] font-bold text-gray-500 active:text-gray-900"
          >
            暂不继续，返回工作台
          </button>
        </div>
      </motion.div>
    );
  }

  const toggleTag = (tag: string) => {
    setTags((prev) =>
      prev.includes(tag) ? prev.filter((t) => t !== tag) : [...prev, tag]
    );
  };

  const handleSubmit = () => {
    if (!isStructuredEvaluationComplete(structuredEval)) {
      alert("请完成核心评价选项");
      return;
    }
    updateOrder(bookingOrder.id, { isEvaluated: true });
    const evaluationTask = consultationWorkflow.tasks.find(
      (task) => task.taskType === "review_counselor" && task.orderId === bookingOrder.id && task.status !== "completed",
    );
    if (evaluationTask) completeWorkflowTask(evaluationTask.id);
    alert("评价提交成功，感谢您的反馈！");
    setSubmitted(true);
  };

  return (
    <motion.div
      initial={{ x: "100%" }}
      animate={{ x: 0 }}
      exit={{ x: "100%" }}
      transition={{ type: "spring", damping: 25, stiffness: 200 }}
      className="absolute inset-0 bg-[#f8f9fa] z-[80] flex flex-col"
    >
      <div className="flex items-center justify-between px-4 py-3 border-b border-gray-100 bg-white sticky top-0 z-10 shadow-sm">
        <button
          onClick={popView}
          className="w-8 h-8 flex items-center justify-center active:bg-gray-100 rounded-full transition-colors"
        >
          <ArrowLeft size={20} className="text-gray-900" />
        </button>
        <span className="font-bold text-gray-900 text-[16px]">评价咨询师</span>
        <div className="w-8"></div>
      </div>

      <div className="flex-1 overflow-y-auto w-full pb-32 p-4">
        <div className="bg-white p-5 rounded-2xl mb-4 shadow-sm border border-gray-100">
          <h2 className="font-bold text-[16px] text-gray-900 mb-4 text-center">本次服务反馈</h2>
          
          <div className="space-y-6">
            <div>
              <label className="block text-[14px] font-bold text-gray-900 mb-3">你是否感觉被咨询师理解了？<span className="text-red-500 ml-1">*</span></label>
              <div className="flex space-x-3">
                <button
                  onClick={() => setStructuredEval({...structuredEval, feltUnderstood: true})}
                  className={`flex-1 py-2.5 rounded-xl border text-[14px] font-medium transition-colors ${structuredEval.feltUnderstood === true ? 'bg-primary/10 border-primary text-primary' : 'bg-white border-gray-200 text-gray-600'}`}
                >
                  是
                </button>
                <button
                  onClick={() => setStructuredEval({...structuredEval, feltUnderstood: false})}
                  className={`flex-1 py-2.5 rounded-xl border text-[14px] font-medium transition-colors ${structuredEval.feltUnderstood === false ? 'bg-primary/10 border-primary text-primary' : 'bg-white border-gray-200 text-gray-600'}`}
                >
                  否
                </button>
              </div>
            </div>

            <div>
              <label className="block text-[14px] font-bold text-gray-900 mb-3">你觉得本次服务有帮助吗？<span className="text-red-500 ml-1">*</span></label>
              <div className="flex space-x-3">
                <button
                  onClick={() => setStructuredEval({...structuredEval, wasHelpful: true})}
                  className={`flex-1 py-2.5 rounded-xl border text-[14px] font-medium transition-colors ${structuredEval.wasHelpful === true ? 'bg-primary/10 border-primary text-primary' : 'bg-white border-gray-200 text-gray-600'}`}
                >
                  有帮助
                </button>
                <button
                  onClick={() => setStructuredEval({...structuredEval, wasHelpful: false})}
                  className={`flex-1 py-2.5 rounded-xl border text-[14px] font-medium transition-colors ${structuredEval.wasHelpful === false ? 'bg-primary/10 border-primary text-primary' : 'bg-white border-gray-200 text-gray-600'}`}
                >
                  没感觉
                </button>
              </div>
            </div>

            <div>
              <label className="block text-[14px] font-bold text-gray-900 mb-3">你愿意再次预约这位咨询师吗？</label>
              <div className="flex space-x-3">
                <button
                  onClick={() => setStructuredEval({...structuredEval, willBookAgain: true})}
                  className={`flex-1 py-2.5 rounded-xl border text-[14px] font-medium transition-colors ${structuredEval.willBookAgain === true ? 'bg-primary/10 border-primary text-primary' : 'bg-white border-gray-200 text-gray-600'}`}
                >
                  愿意
                </button>
                <button
                  onClick={() => setStructuredEval({...structuredEval, willBookAgain: false})}
                  className={`flex-1 py-2.5 rounded-xl border text-[14px] font-medium transition-colors ${structuredEval.willBookAgain === false ? 'bg-primary/10 border-primary text-primary' : 'bg-white border-gray-200 text-gray-600'}`}
                >
                  不愿意
                </button>
              </div>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-[1.25rem] p-6 shadow-sm border border-gray-100 mb-4 text-center">
          <img
            src={counselor?.avatar}
            alt=""
            className="w-16 h-16 rounded-full object-cover shadow-sm mx-auto mb-3"
          />
          <h3 className="font-bold text-gray-900 text-[16px] mb-1">
            {counselor?.name}
          </h3>
          <p className="text-[12px] text-gray-500 mb-6">本次咨询已结束，请为咨询师打分</p>

          <div className="flex justify-center space-x-3 mb-8">
            {[1, 2, 3, 4, 5].map((star) => (
              <button
                key={star}
                onClick={() => setRating(star)}
                className="focus:outline-none transition-transform active:scale-90"
              >
                <Star
                  size={32}
                  className={`${
                    star <= rating
                      ? "fill-yellow-400 text-yellow-400"
                      : "text-gray-200"
                  }`}
                />
              </button>
            ))}
          </div>

          <div className="text-left mb-4">
            <p className="font-bold text-[14px] text-gray-800 mb-3">
              选择符合的标签
            </p>
            <div className="flex flex-wrap gap-2">
              {availableTags.map((tag) => (
                <button
                  key={tag}
                  onClick={() => toggleTag(tag)}
                  className={`px-3 py-1.5 rounded-full text-[12px] font-medium border transition-colors ${
                    tags.includes(tag)
                      ? "bg-primary/10 border-primary/30 text-primary"
                      : "bg-gray-50 border-gray-100 text-gray-600"
                  }`}
                >
                  {tag}
                </button>
              ))}
            </div>
          </div>

          <div className="text-left">
            <p className="font-bold text-[14px] text-gray-800 mb-3">
              补充想说的话
            </p>
            <textarea
              value={comment}
              onChange={(e) => setComment(e.target.value)}
              placeholder="您的评价对我们非常重要..."
              className="w-full bg-gray-50 border border-gray-100 rounded-xl p-3 text-[14px] h-28 resize-none focus:outline-none focus:ring-1 focus:ring-primary/30"
            />
          </div>
        </div>
      </div>

      <div className="absolute bottom-0 left-0 right-0 p-5 bg-white border-t border-gray-100 shadow-[0_-10px_40px_rgba(0,0,0,0.03)] z-20">
        <button
          onClick={handleSubmit}
          className="w-full bg-gray-900 text-white font-bold py-4 rounded-full active:bg-gray-800 transition-colors shadow-md shadow-gray-900/10"
        >
          提交评价
        </button>
      </div>
    </motion.div>
  );
}
