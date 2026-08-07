import { useState, useEffect } from "react";
import { motion } from "motion/react";
import { useAppStore } from "../../store";
import { ArrowLeft, MessageSquare, Video, Clock, ShieldAlert, CalendarX, Sparkles, ClipboardList } from "lucide-react";
import { mockCounselors } from "../../data";
import { MissingDataPage } from "../../components/EmptyState";
import { getClientJourneyPresentation } from "../../../clientJourneyPresentation";

export function UserOrderDetail() {
  const { popView, pushView, bookingOrder, updateOrder, setActiveCallSession, setIsCallMinimized, consultationWorkflow, completeWorkflowTask } = useAppStore();
  const [now, setNow] = useState(new Date());

  useEffect(() => {
    const timer = setInterval(() => setNow(new Date()), 1000);
    return () => clearInterval(timer);
  }, []);

  let paymentTimeLeft = 0;
  if (bookingOrder?.status === "pending" && bookingOrder.createdAt) {
    const createdTime = new Date(bookingOrder.createdAt).getTime();
    const expiryTime = createdTime + 30 * 60000;
    paymentTimeLeft = Math.max(0, Math.floor((expiryTime - now.getTime()) / 1000));
  }

  useEffect(() => {
    if (bookingOrder?.status === "pending" && paymentTimeLeft === 0 && bookingOrder.createdAt) {
      updateOrder(bookingOrder.id, { status: "cancelled" });
    }
  }, [paymentTimeLeft, bookingOrder?.status, bookingOrder?.id, bookingOrder?.createdAt, updateOrder]);

  if (!bookingOrder) {
    return <MissingDataPage icon={CalendarX} title="找不到这笔预约" description="订单可能已被清理或链接已经失效，可以返回预约列表重新查看。" onBack={popView} actionLabel="返回预约列表" />;
  }

  const formatPaymentTime = (seconds: number) => {
    const m = Math.floor(seconds / 60).toString().padStart(2, "0");
    const s = (seconds % 60).toString().padStart(2, "0");
    return `${m}:${s}`;
  };

  const counselor = mockCounselors.find((c) => c.id === bookingOrder.counselorId) || mockCounselors[0];
  const journey = getClientJourneyPresentation(bookingOrder, consultationWorkflow);

  const getLockStatus = () => {
    if (bookingOrder.type === "text") return { isLocked: false, lockMessage: "" };
    
    let scheduledTime = new Date();
    const timeStr = bookingOrder.time;
    const dateStr = bookingOrder.date;

    if (timeStr && timeStr.includes(":")) {
      const [hourStr, minStr] = timeStr.split("-")[0].split(":");
      scheduledTime.setHours(parseInt(hourStr), parseInt(minStr), 0, 0);
    }
    
    if (dateStr && dateStr.includes("-")) {
      const [month, day] = dateStr.split("-");
      scheduledTime.setMonth(parseInt(month) - 1);
      scheduledTime.setDate(parseInt(day));
    } else if (dateStr === "明天") {
      scheduledTime.setDate(scheduledTime.getDate() + 1);
    }

    const diffMinutes = (scheduledTime.getTime() - now.getTime()) / 60000;
    if (diffMinutes > 10) {
      const openTime = new Date(scheduledTime.getTime() - 10 * 60000);
      const openDateStr = `${openTime.getMonth() + 1}月${openTime.getDate()}日`;
      const openTimeStr = `${openTime.getHours().toString().padStart(2, '0')}:${openTime.getMinutes().toString().padStart(2, '0')}`;
      return { isLocked: true, lockMessage: `预计 ${openDateStr} ${openTimeStr} 开放` };
    }
    return { isLocked: false, lockMessage: "" };
  };

  const handleEnterConsultation = () => {
    const { isLocked, lockMessage } = getLockStatus();
    if (isLocked) {
      alert(`咨询室将在开始前10分钟开放，请稍后再试\n（${lockMessage}）`);
      return;
    }
    if (bookingOrder.type === "text") {
      pushView("counseling-text-chat");
    } else {
      setActiveCallSession(bookingOrder);
      setIsCallMinimized(false);
    }
  };

  const handleCancelOrder = () => {
    const isConfirm = window.confirm("确定要取消该预约吗？");
    if (isConfirm) {
      const newStatus = bookingOrder.status === "paid" ? "refunded" : "cancelled";
      updateOrder(bookingOrder.id, { status: newStatus });
      popView();
    }
  };

  const handlePrimaryAction = () => {
    if (journey.primaryAction === "pay") return pushView("counseling-payment");
    if (journey.primaryAction === "complete_intake") return pushView("pre-questionnaire");
    if (journey.primaryAction === "enter_session") return handleEnterConsultation();
    if (journey.primaryAction === "read_summary" || journey.primaryAction === "view_summary") {
      const recapTask = consultationWorkflow.tasks.find(
        (task) => task.orderId === bookingOrder.id && task.actorRole === "client" && task.taskType === "read_session_recap" && task.status !== "completed",
      );
      if (recapTask) completeWorkflowTask(recapTask.id);
      return pushView("counseling-summary");
    }
    if (journey.primaryAction === "evaluate") return pushView("user-evaluation" as any);
  };

  const { isLocked, lockMessage } = getLockStatus();

  return (
    <motion.div
      initial={{ x: "100%" }}
      animate={{ x: 0 }}
      exit={{ x: "100%" }}
      transition={{ type: "spring", damping: 25, stiffness: 200 }}
      className="absolute inset-0 bg-[#f8f9fa] z-[60] flex flex-col"
    >
      <div className="flex items-center justify-between px-4 py-3 border-b border-gray-100 bg-white sticky top-0 z-10 shadow-sm">
        <button
          onClick={popView}
          className="w-8 h-8 flex items-center justify-center active:bg-gray-100 rounded-full transition-colors"
        >
          <ArrowLeft size={20} className="text-gray-900" />
        </button>
        <span className="font-bold text-gray-900 text-[16px]">预约详情</span>
        <div className="w-8"></div>
      </div>

      <div className="flex-1 overflow-y-auto w-full pb-32 px-4 pt-4">
        <div className="bg-white rounded-[1.25rem] p-5 shadow-sm border border-gray-100 mb-4">
          <div className="flex items-center justify-between mb-4 pb-4 border-b border-gray-50">
            <span className="text-gray-500 text-[14px]">订单状态</span>
            <span className="flex items-center text-[15px] font-bold text-primary">
              {journey.statusLabel}
              {bookingOrder.status === "pending" && <span className="ml-2 flex items-center rounded-full bg-orange-100 px-2 py-0.5 text-[11px] text-orange-600"><Clock size={10} className="mr-1"/> {formatPaymentTime(paymentTimeLeft)}</span>}
            </span>
          </div>

          <div className="flex items-start space-x-4 mb-6">
            <img
              src={counselor.avatar}
              alt=""
              className="w-14 h-14 rounded-[1.25rem] object-cover shadow-sm shrink-0"
            />
            <div className="flex-1">
              <div className="flex items-center justify-between mb-1">
                <p className="font-bold text-gray-900 text-[16px]">{counselor.name}</p>
                <div className="flex items-center text-[11px] font-medium text-gray-500 bg-gray-50 px-2 py-0.5 rounded-full border border-gray-100">
                  累计服务 {counselor.serviceHours || (counselor.type === "pro" ? 5000 : 1000)}+ 小时
                </div>
              </div>
              <div className="flex items-center gap-1.5 flex-wrap mt-2">
                {counselor.specialties?.slice(0, 1).map((spec, i) => (
                  <span key={`spec-${i}`} className="text-[10px] bg-blue-50 text-blue-600 border border-blue-100/50 px-1.5 py-0.5 rounded font-medium mb-1">
                    擅长: {spec}
                  </span>
                ))}
                {counselor.styles?.slice(0, 1).map((style, i) => (
                  <span key={`style-${i}`} className="text-[10px] bg-purple-50 text-purple-600 border border-purple-100/50 px-1.5 py-0.5 rounded font-medium mb-1">
                    风格: {style}
                  </span>
                ))}
                {counselor.credentials?.slice(0, 1).map((cred, i) => (
                  <span key={`cred-${i}`} className="text-[10px] bg-amber-50 text-amber-600 border border-amber-100/50 px-1.5 py-0.5 rounded font-medium mb-1">
                    资质: {cred}
                  </span>
                ))}
              </div>
            </div>
          </div>

          <div className="space-y-4 text-[14px]">
            <div className="flex justify-between items-center">
              <span className="text-gray-500">咨询方式</span>
              <span className="font-medium text-gray-900 flex items-center">
                {bookingOrder.type === "text" ? (
                  <><MessageSquare size={14} className="mr-1 text-blue-500"/> 文字沟通</>
                ) : bookingOrder.type === "voice" ? (
                  <><Video size={14} className="mr-1 text-indigo-500"/> 语音咨询</>
                ) : (
                  <><Video size={14} className="mr-1 text-green-500"/> 视频咨询</>
                )}
              </span>
            </div>
            <div className="flex justify-between items-center">
              <span className="text-gray-500">预约时间</span>
              <span className="font-bold text-gray-900">
                {bookingOrder.date} {bookingOrder.time}
              </span>
            </div>
            <div className="flex justify-between items-center">
              <span className="text-gray-500">咨询时长</span>
              <span className="font-medium text-gray-900">
                {bookingOrder.type === "text" ? "全天随时可留言" : "50 分钟"}
              </span>
            </div>
            <div className="flex justify-between items-center">
              <span className="text-gray-500">实付款</span>
              <span className="font-bold text-gray-900">
                ¥{bookingOrder.price}
              </span>
            </div>
            <div className="flex justify-between items-center">
              <span className="text-gray-500">订单编号</span>
              <span className="font-medium text-gray-400 text-[13px]">
                {bookingOrder.id}
              </span>
            </div>
          </div>
        </div>

        <div className="mb-4 rounded-[24px] border border-[#D0BCFF] bg-[#F6EDFF] p-5 text-[#21005D] shadow-sm">
          <div className="flex items-start gap-3">
            <div className="grid h-11 w-11 shrink-0 place-items-center rounded-[15px] bg-[#EADDFF] text-[#6750A4]">
              {journey.primaryAction === "read_summary" || journey.primaryAction === "view_summary" ? <Sparkles size={21} /> : <ClipboardList size={21} />}
            </div>
            <div className="min-w-0 flex-1">
              <p className="text-[11px] font-black text-[#6750A4]">当前事项</p>
              <h3 className="mt-1 text-[16px] font-black">{journey.currentLabel}</h3>
              <p className="mt-1 text-[12px] leading-5 text-[#49454F]">{journey.description}</p>
            </div>
          </div>
        </div>

        {bookingOrder.status === "completed" && bookingOrder.counselorAdvice && (
          <div className="bg-white rounded-[1.25rem] p-5 shadow-sm border border-gray-100 mb-4">
            <h3 className="text-[15px] font-bold text-gray-900 flex items-center mb-3">
              <MessageSquare size={16} className="text-primary mr-1.5" />
              本次服务总结与建议
            </h3>
            <div className="bg-primary/5 rounded-xl p-4 border border-primary/10">
              <p className="text-[13px] text-gray-700 leading-relaxed font-medium">
                {bookingOrder.counselorAdvice}
              </p>
            </div>
          </div>
        )}
        
        {journey.canCancel && (
          <div className="bg-orange-50 rounded-[1rem] p-4 flex items-start space-x-2">
            <ShieldAlert size={16} className="text-orange-500 mt-0.5 shrink-0" />
            <p className="text-[12px] text-orange-700 leading-relaxed">
              支持在预约开始前 24 小时免费取消；距预约开始不足 24 小时取消，将收取 50% 违约金；开始后取消不予退款。
            </p>
          </div>
        )}
      </div>

      <div className="absolute bottom-0 left-0 right-0 p-4 bg-white border-t border-gray-100 shadow-[0_-10px_40px_rgba(0,0,0,0.03)] z-20">
        <div className="flex space-x-3">
          {journey.canCancel && (
            <button
              onClick={handleCancelOrder}
              className="flex-1 py-3.5 rounded-full font-bold bg-gray-50 text-gray-600 active:bg-gray-100 transition-colors border border-gray-200"
            >
              取消预约
            </button>
          )}

          {journey.primaryAction !== "none" && journey.primaryAction !== "wait_for_summary" && (
            <button onClick={handlePrimaryAction} className="flex-[1.4] rounded-full bg-[#6750A4] py-3.5 font-bold text-white shadow-lg shadow-[#6750A4]/20 active:scale-[0.98] transition-transform">
              {journey.actionLabel}
            </button>
          )}
          {journey.primaryAction === "wait_for_summary" && (
            <button onClick={() => pushView("counseling-text-chat")} className="flex-1 rounded-full bg-[#EADDFF] py-3.5 font-bold text-[#21005D] active:scale-[0.98]">联系咨询师</button>
          )}
        </div>
      </div>
    </motion.div>
  );
}
