import { useState, useEffect } from "react";
import { motion } from "motion/react";
import { useAppStore } from "../../store";
import {
  ChevronLeft,
  CalendarClock,
  MessageSquare,
  Video,
  ArrowRight,
  Lock,
} from "lucide-react";
import { mockCounselors } from "../../data";
import { EmptyState } from "../../components/EmptyState";
import { getClientJourneyPresentation } from "../../../clientJourneyPresentation";

export function OrdersList() {
  const { popView, pushView, orders, setBookingOrder, setSelectedCounselorId, appMode, activeOrderTab, setSelectedCounselorOrder, consultationWorkflow, setActiveCallSession, setIsCallMinimized, completeWorkflowTask } = useAppStore();
  const [now, setNow] = useState(new Date());

  const isCounselorMode = appMode === "counselor";
  const isTab = false;

  useEffect(() => {
    const timer = setInterval(() => setNow(new Date()), 60000);
    return () => clearInterval(timer);
  }, []);

  const getCounselor = (id: string) => {
    return mockCounselors.find((c) => c.id === id) || mockCounselors[0];
  };

  const displayOrders = isCounselorMode 
    ? orders.filter(o => o.counselorId === 'c1').filter(o => {
        if (activeOrderTab === "pending") return o.status === "paid" || o.status === "pending";
        if (activeOrderTab === "completed") return o.status === "completed";
        if (activeOrderTab === "cancelled") return o.status === "cancelled" || o.status === "refunded" || o.status === "failed";
        return true;
      })
    : orders;



  return (
    <motion.div
      initial={isTab ? { opacity: 0 } : { x: "100%" }}
      animate={isTab ? { opacity: 1 } : { x: 0 }}
      exit={isTab ? { opacity: 0 } : { x: "100%" }}
      transition={isTab ? undefined : { type: "spring", damping: 25, stiffness: 200 }}
      className={`flex flex-col h-full bg-[#f8f9fa] overflow-hidden ${isTab ? 'relative w-full' : 'absolute inset-0 z-50'}`}
    >
      <div className="pt-14 pb-4 px-4 bg-white sticky top-0 z-20 flex items-center shadow-sm">
        {!isTab && (
          <button
            onClick={popView}
            className="w-10 h-10 -ml-2 flex items-center justify-center text-gray-900 border border-transparent active:bg-gray-50 rounded-full transition-colors"
          >
            <ChevronLeft size={24} />
          </button>
        )}
        <h1 className={`text-[17px] font-bold text-gray-900 ${!isTab ? 'ml-2' : ''}`}>
          {isCounselorMode ? "我的咨询" : "我的预约订单"}
        </h1>
      </div>

      <div className={`flex-1 overflow-y-auto p-4 ${isTab ? 'pb-28' : ''}`}>
        {displayOrders.length === 0 ? (
          <EmptyState
            icon={CalendarClock}
            title="还没有预约订单"
            description="找到合适的咨询师并完成预约后，服务时间和订单进度会显示在这里。"
            actionLabel="去找咨询师"
            onAction={() => pushView("counseling-entrance")}
          />
        ) : (
          <div className="space-y-4">
            {displayOrders.map((order, ind) => {
              const counselor = getCounselor(order.counselorId);
              const clientJourney = !isCounselorMode ? getClientJourneyPresentation(order, consultationWorkflow) : null;
              
              // 针对咨询师端，伪造用户的标签数据，保留原本丰富的UI样式
              const displayName = isCounselorMode ? (order.userName || "新用户") : counselor.name;
              const displayAvatar = isCounselorMode ? (order.avatar || "https://ui-avatars.com/api/?name=User&background=random") : counselor.avatar;
              const displayTags1 = isCounselorMode ? ["职场压力", "离职纠结"] : counselor.specialties?.slice(0, 1);
              const displayTags2 = isCounselorMode ? ["需关注", "抑郁倾向"] : counselor.styles?.slice(0, 1);
              const displayLabel1 = isCounselorMode ? "问题" : "擅长";
              const displayLabel2 = isCounselorMode ? "风险" : "风格";
              const displayStats = isCounselorMode ? "服务时长 50 分钟" : `累计服务 ${counselor.serviceHours || "1000+"} 小时`;
              
              return (
                <div
                  key={ind}
                  onClick={() => {
                    if (isCounselorMode) {
                      setSelectedCounselorOrder(order);
                      pushView("counseling-text-chat");
                    } else {
                      setBookingOrder(order);
                      pushView("user-order-detail");
                    }
                  }}
                  className="bg-white p-5 rounded-[1.5rem] shadow-sm border border-gray-100 cursor-pointer active:scale-[0.98] transition-transform"
                >
                  <div className="flex justify-between items-start mb-4 pb-4 border-b border-gray-50">
                    <div className="flex items-start space-x-3">
                      <img
                        src={displayAvatar}
                        alt=""
                        className="w-12 h-12 rounded-[1rem] object-cover shadow-sm bg-gray-100 shrink-0"
                      />
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center space-x-2 flex-wrap gap-y-1 mb-1">
                          <h3 className="font-bold text-gray-900 text-[15px] leading-none">
                            {displayName}
                          </h3>
                          <span className="text-[10px] bg-gray-50 text-gray-500 px-1.5 py-0.5 rounded font-medium shrink-0">
                            {displayStats}
                          </span>
                        </div>
                        <div className="flex flex-wrap gap-1.5 mt-1.5">
                          {displayTags1?.map((spec: string, i: number) => (
                            <span key={`spec-${i}`} className="text-[10px] bg-blue-50 text-blue-600 px-1.5 py-0.5 rounded font-medium">
                              {displayLabel1}: {spec}
                            </span>
                          ))}
                          {displayTags2?.map((style: string, i: number) => (
                            <span key={`style-${i}`} className={`text-[10px] px-1.5 py-0.5 rounded font-medium ${isCounselorMode && style === '高风险' ? 'bg-red-50 text-red-600' : 'bg-purple-50 text-purple-600'}`}>
                              {displayLabel2}: {style}
                            </span>
                          ))}
                        </div>
                      </div>
                    </div>
                    <span className={`px-3 py-1 rounded-full text-[11px] font-bold ${
                      order.status === 'paid' ? 'bg-primary/10 text-primary' :
                      order.status === 'pending' ? 'bg-orange-50 text-orange-500' :
                      'bg-gray-100 text-gray-500'
                    }`}>
                      {isCounselorMode 
                        ? (order.status === "paid" ? "待服务" : order.status === "pending" ? "待支付" : order.status === "completed" ? "已完成" : "已取消")
                        : clientJourney?.statusLabel
                      }
                    </span>
                  </div>

                  <div className="flex items-center justify-between">
                    <div className="space-y-2">
                      <div className="flex items-center text-gray-600 text-[13px]">
                        <CalendarClock size={16} className="mr-2 text-gray-400" />
                        <span className="font-medium">
                          {order.date} · {order.time}
                        </span>
                      </div>
                      <div className="flex items-center text-gray-600 text-[13px]">
                        {order.type === "text" ? (
                          <MessageSquare
                            size={16}
                            className="mr-2 text-gray-400"
                          />
                        ) : (
                          <Video size={16} className="mr-2 text-gray-400" />
                        )}
                        <span className="font-medium">
                          {order.type === "text" ? "全天随时可留言" : "50 分钟"}
                        </span>
                      </div>
                    </div>

                    {!isCounselorMode && clientJourney && clientJourney.primaryAction !== "none" && (
                      <button
                        onClick={(e) => {
                          e.stopPropagation();
                          setBookingOrder(order);
                          setSelectedCounselorId(order.counselorId);
                          if (clientJourney.primaryAction === "pay") return pushView("counseling-payment");
                          if (clientJourney.primaryAction === "complete_intake") return pushView("pre-questionnaire");
                          if (clientJourney.primaryAction === "enter_session") {
                            if (order.type === "text") return pushView("counseling-text-chat");
                            setIsCallMinimized(false);
                            return setActiveCallSession(order);
                          }
                          if (clientJourney.primaryAction === "read_summary" || clientJourney.primaryAction === "view_summary") {
                            const recapTask = consultationWorkflow.tasks.find((task) => task.orderId === order.id && task.taskType === "read_session_recap" && task.status !== "completed");
                            if (recapTask) completeWorkflowTask(recapTask.id);
                            return pushView("counseling-summary");
                          }
                          if (clientJourney.primaryAction === "evaluate") return pushView("user-evaluation" as any);
                          return pushView("user-order-detail");
                        }}
                        disabled={clientJourney.primaryAction === "wait_for_summary"}
                        className="px-3.5 py-1.5 rounded-full text-[12px] font-bold flex items-center justify-center transition-all bg-[#6750A4] text-white active:scale-[0.98] shrink-0 disabled:bg-[#E7E0EC] disabled:text-[#79747E]"
                      >
                        {clientJourney.actionLabel}
                      </button>
                    )}
                    {isCounselorMode && order.status === "paid" && (
                      <button onClick={(e) => { e.stopPropagation(); setSelectedCounselorOrder(order); pushView("counseling-text-chat"); }} className="px-3.5 py-1.5 rounded-lg text-[12px] font-bold bg-gray-900 text-white">联系用户</button>
                    )}
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
