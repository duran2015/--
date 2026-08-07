import { useState } from "react";
import { motion } from "motion/react";
import { useAppStore } from "../../store";
import { ChevronLeft } from "lucide-react";

export function PreCounselingQuestionnaire() {
  const { popView, pushView, bookingOrder, updateOrder, consultationWorkflow, completeWorkflowTask } = useAppStore();
  const [preQuestionnaire, setPreQuestionnaire] = useState({
    mainTopic: "",
    duration: "",
    event: "",
    expectation: "",
    hasCounselingHistory: null as boolean | null,
    hasSelfHarmThoughts: null as boolean | null,
  });

  const handleSubmit = () => {
    if (
      !preQuestionnaire.mainTopic ||
      preQuestionnaire.hasSelfHarmThoughts === null
    ) {
      alert("请填写主要话题并确认是否有自伤倾向");
      return;
    }

    if (bookingOrder) {
      // Update the order in the store with the questionnaire data
      updateOrder(bookingOrder.id, { preQuestionnaire });
      const intakeTask = consultationWorkflow.tasks.find(
        (task) => task.orderId === bookingOrder.id && task.actorRole === "client" && task.taskType === "complete_intake" && task.status !== "completed",
      );
      if (intakeTask) completeWorkflowTask(intakeTask.id);
    }

    // Go directly to the chat/service channel
    pushView("counseling-text-chat");
  };

  return (
    <motion.div
      initial={{ x: "100%" }}
      animate={{ x: 0 }}
      exit={{ x: "100%" }}
      transition={{ type: "spring", damping: 25, stiffness: 200 }}
      className="absolute inset-0 bg-white z-50 flex flex-col"
    >
      <div className="flex items-center justify-between px-4 py-3 border-b border-gray-100 sticky top-0 bg-white z-10 pt-14">
        <button
          onClick={popView}
          className="w-10 h-10 -ml-2 flex items-center justify-center active:bg-gray-50 rounded-full transition-colors"
        >
          <ChevronLeft size={24} className="text-gray-900" />
        </button>
        <span className="font-bold text-gray-900 text-[17px]">咨询前情况了解</span>
        <div className="w-10"></div>
      </div>

      <div className="flex-1 overflow-y-auto p-5 space-y-6 pb-32">
        <div className="bg-blue-50/50 p-4 rounded-2xl border border-blue-100/50 mb-2">
          <p className="text-blue-800 text-[13px] leading-relaxed font-medium">
            您已支付成功！为了让咨询师能更好地帮助你，请花 1
            分钟填写以下信息。这些信息将保密并仅向你的咨询师展示。
          </p>
        </div>

        <div className="space-y-6">
          <div>
            <label className="block text-[15px] font-bold text-gray-900 mb-3">
              这次主要想聊什么？<span className="text-red-500 ml-1">*</span>
            </label>
            <textarea
              value={preQuestionnaire.mainTopic}
              onChange={(e) =>
                setPreQuestionnaire({
                  ...preQuestionnaire,
                  mainTopic: e.target.value,
                })
              }
              className="w-full bg-gray-50 border border-gray-100 rounded-xl p-4 text-[14px] focus:outline-none focus:ring-2 focus:ring-primary/20 h-24 resize-none"
              placeholder="例如：最近工作压力很大，总是失眠..."
            />
          </div>

          <div>
            <label className="block text-[15px] font-bold text-gray-900 mb-3">
              这个问题持续多久了？
            </label>
            <select
              value={preQuestionnaire.duration}
              onChange={(e) =>
                setPreQuestionnaire({
                  ...preQuestionnaire,
                  duration: e.target.value,
                })
              }
              className="w-full bg-gray-50 border border-gray-100 rounded-xl p-4 text-[14px] focus:outline-none focus:ring-2 focus:ring-primary/20"
            >
              <option value="">请选择</option>
              <option value="1个月内">1个月内</option>
              <option value="1-3个月">1-3个月</option>
              <option value="3个月-半年">3个月-半年</option>
              <option value="半年以上">半年以上</option>
            </select>
          </div>

          <div>
            <label className="block text-[15px] font-bold text-gray-900 mb-3">
              最近最影响你的事件是什么？
            </label>
            <input
              type="text"
              value={preQuestionnaire.event}
              onChange={(e) =>
                setPreQuestionnaire({
                  ...preQuestionnaire,
                  event: e.target.value,
                })
              }
              className="w-full bg-gray-50 border border-gray-100 rounded-xl p-4 text-[14px] focus:outline-none focus:ring-2 focus:ring-primary/20"
              placeholder="例如：换了新领导、分手等"
            />
          </div>

          <div>
            <label className="block text-[15px] font-bold text-gray-900 mb-3">
              你希望这次服务后获得什么？
            </label>
            <input
              type="text"
              value={preQuestionnaire.expectation}
              onChange={(e) =>
                setPreQuestionnaire({
                  ...preQuestionnaire,
                  expectation: e.target.value,
                })
              }
              className="w-full bg-gray-50 border border-gray-100 rounded-xl p-4 text-[14px] focus:outline-none focus:ring-2 focus:ring-primary/20"
              placeholder="例如：倾听陪伴、具体的建议..."
            />
          </div>

          <div className="pt-2">
            <label className="block text-[15px] font-bold text-gray-900 mb-3">
              以前做过心理咨询吗？
            </label>
            <div className="flex space-x-3">
              <button
                onClick={() =>
                  setPreQuestionnaire({
                    ...preQuestionnaire,
                    hasCounselingHistory: true,
                  })
                }
                className={`flex-1 py-3 rounded-xl border text-[14px] font-bold transition-colors ${
                  preQuestionnaire.hasCounselingHistory === true
                    ? "bg-primary/10 border-primary text-primary"
                    : "bg-white border-gray-200 text-gray-600"
                }`}
              >
                做过
              </button>
              <button
                onClick={() =>
                  setPreQuestionnaire({
                    ...preQuestionnaire,
                    hasCounselingHistory: false,
                  })
                }
                className={`flex-1 py-3 rounded-xl border text-[14px] font-bold transition-colors ${
                  preQuestionnaire.hasCounselingHistory === false
                    ? "bg-primary/10 border-primary text-primary"
                    : "bg-white border-gray-200 text-gray-600"
                }`}
              >
                没做过
              </button>
            </div>
          </div>

          <div className="pt-2">
            <label className="block text-[15px] font-bold text-gray-900 mb-3">
              当前是否存在伤害自己或他人的想法？
              <span className="text-red-500 ml-1">*</span>
            </label>
            <div className="flex space-x-3">
              <button
                onClick={() =>
                  setPreQuestionnaire({
                    ...preQuestionnaire,
                    hasSelfHarmThoughts: true,
                  })
                }
                className={`flex-1 py-3 rounded-xl border text-[14px] font-bold transition-colors ${
                  preQuestionnaire.hasSelfHarmThoughts === true
                    ? "bg-red-50 border-red-500 text-red-600"
                    : "bg-white border-gray-200 text-gray-600"
                }`}
              >
                有
              </button>
              <button
                onClick={() =>
                  setPreQuestionnaire({
                    ...preQuestionnaire,
                    hasSelfHarmThoughts: false,
                  })
                }
                className={`flex-1 py-3 rounded-xl border text-[14px] font-bold transition-colors ${
                  preQuestionnaire.hasSelfHarmThoughts === false
                    ? "bg-green-50 border-green-500 text-green-600"
                    : "bg-white border-gray-200 text-gray-600"
                }`}
              >
                没有
              </button>
            </div>
            {preQuestionnaire.hasSelfHarmThoughts === true && (
              <div className="mt-3 bg-red-50 border border-red-100 rounded-xl p-3 text-[12px] text-red-700 leading-relaxed font-medium">
                平台提示：如果您现在正处于紧急危机中，请立即拨打当地报警电话（110）或急救电话（120），或联系“希望24”热线：400-161-9995。
              </div>
            )}
          </div>
        </div>
      </div>

      <div className="absolute bottom-0 left-0 right-0 p-4 pb-safe bg-white border-t border-gray-100 shadow-[0_-10px_40px_rgba(0,0,0,0.03)] z-20">
        <button
          onClick={handleSubmit}
          className="w-full py-4 rounded-full bg-gray-900 text-white font-bold text-[15px] active:scale-[0.98] transition-transform shadow-md shadow-gray-900/10"
        >
          保存资料并联系咨询师
        </button>
      </div>
    </motion.div>
  );
}
