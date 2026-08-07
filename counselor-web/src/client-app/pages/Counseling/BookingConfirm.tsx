import { useState } from "react";
import { motion } from "motion/react";
import { useAppStore } from "../../store";
import { ChevronLeft, FileText } from "lucide-react";
import { mockCounselors } from "../../data";

export function BookingConfirm() {
  const { popView, pushView, bookingOrder, setBookingOrder, bookingSummary } = useAppStore();
  const counselor =
    mockCounselors.find((c) => c.id === bookingOrder?.counselorId) ||
    mockCounselors[0];

  const [agreed, setAgreed] = useState(false);
  const [preQuestionnaire, setPreQuestionnaire] = useState({
    mainTopic: "",
    duration: "",
    event: "",
    expectation: "",
    hasCounselingHistory: null as boolean | null,
    hasSelfHarmThoughts: null as boolean | null,
  });

  const handlePayment = () => {
    if (!agreed) {
      alert("请先阅读并同意服务边界与风险确认");
      return;
    }

    setBookingOrder({
      ...bookingOrder,
      status: "pending",
    });
    pushView("counseling-payment");
  };

  return (
    <motion.div
      initial={{ x: "100%" }}
      animate={{ x: 0 }}
      exit={{ x: "100%" }}
      transition={{ type: "spring", damping: 25, stiffness: 200 }}
      className="absolute inset-0 bg-[#f8f9fa] z-50 flex flex-col"
    >
      <div className="flex items-center justify-between px-4 py-3 border-b border-gray-100 bg-white sticky top-0 z-20 shadow-sm pt-14">
        <button
          onClick={popView}
          className="w-10 h-10 -ml-2 flex items-center justify-center active:bg-gray-50 rounded-full transition-colors"
        >
          <ChevronLeft size={24} className="text-gray-900" />
        </button>
        <span className="font-bold text-gray-900 text-[17px]">确认预约</span>
        <div className="w-10"></div>
      </div>

      <div className="flex-1 overflow-y-auto pb-32">
        {/* Order Summary */}
        <div className="bg-white p-5 mb-3 shadow-sm">
          <h3 className="text-[15px] font-bold text-gray-900 mb-4 flex items-center">
            <span className="w-1 h-3.5 bg-primary rounded-full mr-2"></span>
            预约信息
          </h3>
          <div className="bg-gray-50 rounded-2xl p-4">
            <div className="flex justify-between items-center mb-3">
              <span className="text-gray-500 text-[13px]">咨询师</span>
              <span className="font-bold text-gray-900 text-[14px]">
                {counselor?.name}
              </span>
            </div>
            <div className="flex justify-between items-center mb-3">
              <span className="text-gray-500 text-[13px]">服务时间</span>
              <span className="font-bold text-gray-900 text-[14px]">
                {bookingOrder?.date} {bookingOrder?.time}
              </span>
            </div>
            <div className="flex justify-between items-center mb-3">
              <span className="text-gray-500 text-[13px]">服务方式</span>
              <span className="font-bold text-gray-900 text-[14px]">
                {bookingOrder?.type === "voice"
                  ? "语音通话"
                  : bookingOrder?.type === "video"
                    ? "视频通话"
                    : "文字咨询"}
              </span>
            </div>
            {bookingSummary && (
              <div className="flex justify-between items-center pt-3 border-t border-gray-200/50 mt-1">
                <span className="text-gray-500 text-[13px] flex items-center">
                  <FileText size={14} className="mr-1" />
                  咨询前摘要
                </span>
                <span className={`font-bold text-[13px] ${bookingSummary.authorized ? 'text-[#2CC1C1]' : 'text-gray-400'}`}>
                  {bookingSummary.authorized ? "已授权同步" : "未同步"}
                </span>
              </div>
            )}
          </div>
        </div>

        {/* Boundary SOP */}
        <div className="bg-white p-5 mb-3 shadow-sm">
          <h3 className="text-[15px] font-bold text-gray-900 mb-4 flex items-center">
            <span className="w-1 h-3.5 bg-primary rounded-full mr-2"></span>
            服务边界与风险确认
          </h3>
          <div className="space-y-3 mb-5">
            <div className="flex items-start">
              <div className="w-1.5 h-1.5 bg-blue-500 rounded-full mt-2 mr-2 shrink-0"></div>
              <p className="text-gray-700 text-[13px] leading-relaxed">
                本服务提供心理支持和心理咨询预约，
                <span className="font-bold text-gray-900">不提供医学诊断</span>。
              </p>
            </div>
            <div className="flex items-start">
              <div className="w-1.5 h-1.5 bg-blue-500 rounded-full mt-2 mr-2 shrink-0"></div>
              <p className="text-gray-700 text-[13px] leading-relaxed">
                不替代精神科诊疗、心理治疗或紧急危机干预。
              </p>
            </div>
            <div className="flex items-start bg-red-50 p-3 rounded-xl border border-red-100 mt-2">
              <div className="w-1.5 h-1.5 bg-red-500 rounded-full mt-1.5 mr-2 shrink-0"></div>
              <p className="text-red-700 text-[12px] leading-relaxed font-medium">
                若存在自伤、自杀、伤害他人等紧急风险，请立即联系当地紧急救助或专业机构。
              </p>
            </div>
          </div>

          <label className="flex items-center cursor-pointer mt-4">
            <input
              type="checkbox"
              checked={agreed}
              onChange={(e) => setAgreed(e.target.checked)}
              className="w-5 h-5 text-primary rounded border-gray-300 focus:ring-primary mr-3"
            />
            <span className="text-[14px] font-bold text-gray-900">
              我已阅读并同意以上内容
            </span>
          </label>
        </div>
      </div>

      {/* Bottom Action Bar */}
      <div className="absolute bottom-0 left-0 right-0 p-4 pb-safe bg-white border-t border-gray-100 shadow-[0_-10px_40px_rgba(0,0,0,0.03)] z-20 flex items-center justify-between">
        <div className="flex items-end ml-2">
          <span className="text-sm font-bold text-primary mr-0.5 mb-0.5">
            ¥
          </span>
          <span className="text-[24px] font-bold text-primary leading-none">
            {bookingOrder?.price || counselor.price}
          </span>
        </div>
        <button
          onClick={handlePayment}
          className="w-2/3 py-3.5 rounded-full bg-gray-900 text-white font-bold text-[15px] active:scale-[0.98] transition-transform shadow-md shadow-gray-900/10"
        >
          提交并去支付
        </button>
      </div>
    </motion.div>
  );
}