import { motion } from "motion/react";
import { useAppStore } from "../../store";
import { mockCounselors, mockConsultationRecords, mockNotifications } from "../../data";
import { Bell, ShieldAlert, Video, ArrowRight, PhoneCall, Sparkles, CheckCircle2 } from "lucide-react";
import { getClientJourneyPresentation } from "../../../clientJourneyPresentation";

export function MessagesTab() {
  const { pushView, user, setSelectedConsultationId, setActiveCallSession, setIsCallMinimized, setBookingOrder, setSelectedCounselorOrder, orders, appMode, counselorStatus, consultationWorkflow, completeWorkflowTask } = useAppStore();

  const isCounselorMode = appMode === "counselor";
  const sharedSummary = !isCounselorMode
    ? consultationWorkflow.messages.find((message) => message.audience === "client")
    : undefined;

  const startCallDemo = (type: "voice" | "video") => {
    const demoOrder = {
      id: `demo-${type}-${Date.now()}`,
      counselorId: "c1",
      userName: "小鹿用户3821",
      avatar: user.avatar,
      type,
      status: "paid",
      date: "今天",
      time: "现在",
      title: type === "voice" ? "语音咨询模拟" : "视频咨询模拟",
    };

    setIsCallMinimized(false);
    if (isCounselorMode) {
      setBookingOrder(null);
      setSelectedCounselorOrder(demoOrder);
    } else {
      setSelectedCounselorOrder(null);
      setBookingOrder(demoOrder);
    }
    setActiveCallSession(demoOrder);
  };

  // Load chat list from valid orders (paid or completed)
  const chats = orders.filter(o => o.status === "paid" || o.status === "completed").map(record => {
    const counselor = mockCounselors.find(c => c.id === record.counselorId);
    return { record, counselor };
  }).filter(item => item.counselor);

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      className="flex flex-col h-full bg-transparent"
    >
      <div className="page-header flex items-end justify-between">
        <div>
          <div className="page-kicker mb-1">{isCounselorMode ? "SERVICE INBOX" : "CONVERSATIONS"}</div>
          <h1 className="page-title">消息</h1>
        </div>
        <div className="rounded-full bg-primary-light px-3 py-1.5 text-[11px] font-bold text-primary">{isCounselorMode ? "用户沟通与通知" : "随时陪伴"}</div>
      </div>

      <div className="flex-1 overflow-y-auto px-4 pt-4 pb-24">
        {/* Group 1: AI 倾诉分组 */}
        {!isCounselorMode && <div className="mb-6">
          <h2 className="section-label mb-3 px-1">AI 倾诉</h2>
          
          <button
            onClick={() => pushView("ai-chat")}
            className="ui-card ui-row w-full p-4 flex items-center mb-3"
          >
            <div className="relative mr-4 shrink-0">
              <div className="soft-icon w-12 h-12 bg-gradient-to-br from-[#fff1dc] to-[#e8f3ed] flex items-center justify-center text-[24px]">
                🦌
              </div>
              <div className="absolute bottom-0 right-0 w-3.5 h-3.5 bg-green-500 border-2 border-white rounded-full"></div>
            </div>
            <div className="flex-1 text-left min-w-0">
              <div className="flex justify-between items-center mb-1">
                <div className="flex items-center space-x-2 truncate">
                  <h3 className="font-bold text-gray-900 text-[16px] truncate">可鹿 AI 情绪助手</h3>
                  <span className="text-[10px] bg-orange-50 text-orange-600 px-1.5 py-0.5 rounded border border-orange-100 font-medium shrink-0">
                    平台 AI
                  </span>
                </div>
              </div>
              <div className="flex items-center text-[13px] text-gray-500">
                <p className="line-clamp-1">我可以继续陪你梳理刚才的问题。</p>
              </div>
            </div>
          </button>
        </div>}

        {isCounselorMode && (
          <div className="mb-6">
            <h2 className="section-label mb-3 px-1">平台消息</h2>
            <button onClick={() => pushView("notifications-list")} className="ui-card ui-row w-full p-4 flex items-center">
              <div className="relative mr-4 shrink-0">
                <div className="soft-icon w-12 h-12 bg-[#557b91] flex items-center justify-center text-white shadow-inner"><Bell size={24} /></div>
                {mockNotifications.some(n => !n.isRead) && <div className="status-dot absolute bottom-0 right-0 w-3 h-3 bg-[#d95c5c] rounded-full" />}
              </div>
              <div className="flex-1 text-left min-w-0">
                <div className="mb-1 flex items-center justify-between"><div className="flex items-center gap-2"><h3 className="font-bold text-gray-900 text-[16px]">平台通知</h3><span className="rounded border border-blue-100 bg-blue-50 px-1.5 py-0.5 text-[10px] font-medium text-blue-600">官方</span></div><span className="text-[11px] text-gray-400">今天</span></div>
                <p className="line-clamp-1 text-[13px] text-gray-500">预约变更、审核结果、结算与风险提醒</p>
              </div>
            </button>
          </div>
        )}

        {/* Group 2: 咨询服务分组 */}
        <div>
          <h2 className="section-label mb-3 px-1">{isCounselorMode ? "用户沟通" : "咨询服务"}</h2>

          {!isCounselorMode && <div className="hero-panel mb-4 p-4">
            <div className="relative z-10 mb-3 flex items-center justify-between">
              <div>
                <div className="text-[14px] font-black text-white">通话体验室</div>
                <div className="mt-1 text-[11px] text-white/60">模拟{isCounselorMode ? "咨询师" : "用户"}端接通与通话流程</div>
              </div>
              <span className="rounded-full bg-white/10 px-2.5 py-1 text-[10px] font-bold text-white/70">DEMO</span>
            </div>
            <div className="relative z-10 grid grid-cols-2 gap-2.5">
              <button onClick={() => startCallDemo("voice")} className="flex items-center justify-center rounded-[15px] bg-white px-3 py-3 text-[12px] font-bold text-[#24483b]">
                <PhoneCall size={16} className="mr-2" />模拟语音通话
              </button>
              <button onClick={() => startCallDemo("video")} className="flex items-center justify-center rounded-[15px] bg-white/12 px-3 py-3 text-[12px] font-bold text-white ring-1 ring-white/15">
                <Video size={16} className="mr-2" />模拟视频通话
              </button>
            </div>
          </div>}

          {sharedSummary && (
            <button
              onClick={() => {
                const summaryOrder = orders.find((order) => order.id === sharedSummary.orderId);
                if (summaryOrder) setBookingOrder(summaryOrder);
                const readTask = consultationWorkflow.tasks.find(
                  (task) => task.draftId === sharedSummary.draftId && task.taskType === "read_session_recap",
                );
                if (readTask) completeWorkflowTask(readTask.id);
                pushView("counseling-summary");
              }}
              className="mb-4 w-full overflow-hidden rounded-[24px] border border-[#D0BCFF] bg-white text-left shadow-sm active:scale-[0.99]"
            >
              <div className="bg-[#EADDFF] p-4 text-[#21005D]">
                <div className="flex items-start justify-between gap-3">
                  <div className="grid h-11 w-11 place-items-center rounded-[15px] bg-white/60"><Sparkles size={21} /></div>
                  <span className="flex items-center gap-1 rounded-full bg-[#C4EED0] px-2.5 py-1 text-[9px] font-black text-[#163723]"><CheckCircle2 size={11} />咨询师已确认</span>
                </div>
                <h3 className="mt-4 text-[16px] font-black">{sharedSummary.title}</h3>
                <p className="mt-1 line-clamp-3 text-[12px] leading-5 opacity-80">{sharedSummary.description}</p>
              </div>
              <div className="flex items-center justify-between px-4 py-3 text-[12px] font-black text-[#6750A4]">
                <span>{sharedSummary.actionLabel}</span><ArrowRight size={16} />
              </div>
              <div className="border-t border-[#E7E0EC] px-4 py-2 text-[9px] text-[#79747E]">仅含用户可见回顾 · 临床记录与咨询师自评未分享</div>
            </button>
          )}

          {/* System Notifications Chat */}
          {!isCounselorMode && <button
            onClick={() => pushView("notifications-list")}
            className="ui-card ui-row w-full p-4 flex items-center mb-3"
          >
            <div className="relative mr-4 shrink-0">
              <div className="soft-icon w-12 h-12 bg-[#557b91] flex items-center justify-center text-white shadow-inner">
                <Bell size={24} />
              </div>
              {mockNotifications.some(n => !n.isRead) && (
                <div className="status-dot absolute bottom-0 right-0 w-3 h-3 bg-[#d95c5c] rounded-full" />
              )}
            </div>
            <div className="flex-1 text-left min-w-0">
              <div className="flex justify-between items-center mb-1">
                <div className="flex items-center space-x-2 truncate">
                  <h3 className="font-bold text-gray-900 text-[16px] truncate">系统通知</h3>
                  <span className="text-[10px] bg-blue-50 text-blue-600 px-1.5 py-0.5 rounded border border-blue-100 font-medium shrink-0">
                    官方
                  </span>
                </div>
                <span className="text-[11px] text-gray-400 shrink-0 ml-2">
                  {mockNotifications.length > 0 ? mockNotifications[0].date.split(" ")[0] : "今天"}
                </span>
              </div>
              <div className="flex items-center text-[13px] text-gray-500">
                <p className="line-clamp-1">
                  {mockNotifications.length > 0 ? mockNotifications[0].preview : "暂无新通知"}
                </p>
              </div>
            </div>
          </button>}

          {/* Crisis Intervention Channel (Highest Priority) */}
          {!isCounselorMode && user.hasRisk && (
            <button
              onClick={() => pushView("counseling-text-chat")}
              className="w-full bg-[#FFF0F0] p-4 rounded-2xl flex items-center shadow-sm border border-red-100 active:scale-[0.98] transition-transform mb-3 relative overflow-hidden"
            >
              <div className="absolute top-0 left-0 w-1 h-full bg-red-500"></div>
              <div className="w-12 h-12 bg-red-100 rounded-full flex items-center justify-center text-red-500 mr-4 shrink-0">
                <ShieldAlert size={24} />
              </div>
              <div className="flex-1 text-left">
                <div className="flex justify-between items-center mb-1">
                  <h3 className="font-bold text-red-600 text-[16px]">危机干预专线</h3>
                  <span className="text-[11px] text-red-400">进行中</span>
                </div>
                <p className="text-[13px] text-red-500/80 line-clamp-1 font-medium">
                  专业干预员已接入，请随时与我联系
                </p>
              </div>
            </button>
          )}

          {/* Human Counselors Chats */}
          {chats.map(({ record, counselor }) => {
            const isText = record.type === "text";
            const clientJourney = !isCounselorMode ? getClientJourneyPresentation(record, consultationWorkflow) : null;
            let lastMsg = "";
            let subStatus = "待咨询前准备";
            
            // Mock subStatus logic for demonstration
            if (!isCounselorMode && clientJourney) {
              lastMsg = clientJourney.description;
              subStatus = clientJourney.currentLabel;
            } else if (record.status === "paid") {
               if (record.type === "voice" || record.type === "video") {
                 lastMsg = record.type === "voice" ? "语音咨询待履约..." : "视频咨询待履约...";
                 subStatus = "已同步摘要";
               } else {
                 lastMsg = record.messages && record.messages.length > 0 
                  ? record.messages[record.messages.length - 1].content 
                  : `${counselor?.name}的小助理：正式咨询前，我可以先帮你整理问题。`;
               }
            } else if (record.status === "completed") {
               lastMsg = "服务已完成";
               subStatus = "服务已完成";
            }
            
            const displayAvatar = isCounselorMode ? (record.avatar || "https://ui-avatars.com/api/?name=User&background=random") : counselor?.avatar;
            const displayName = isCounselorMode ? (record.userName || "匿名用户") : `${counselor?.name} · 45分钟心理咨询`;
              
            return (
              <button
                key={record.id}
                onClick={() => {
                  if (isCounselorMode) {
                    setSelectedCounselorOrder(record);
                  } else {
                    setBookingOrder(record);
                  }
                  setSelectedConsultationId(record.id);
                  pushView("counseling-text-chat");
                }}
                className="ui-card ui-row w-full p-4 flex items-center mb-3"
              >
                <div className="relative mr-4 shrink-0">
                  <img src={displayAvatar} alt="" className="w-12 h-12 rounded-full object-cover" />
                  {!isCounselorMode && (counselor?.id === 'c1' ? counselorStatus === 'active' : counselor?.status === 'online') && (
                    <div className="absolute bottom-0 right-0 w-3.5 h-3.5 bg-green-500 border-2 border-white rounded-full"></div>
                  )}
                  {!isCounselorMode && !(counselor?.id === 'c1' ? counselorStatus === 'active' : counselor?.status === 'online') && (
                    <div className="absolute bottom-0 right-0 w-3.5 h-3.5 bg-gray-400 border-2 border-white rounded-full"></div>
                  )}
                </div>
                <div className="flex-1 text-left min-w-0">
                  <div className="flex justify-between items-center mb-1">
                    <div className="flex items-center space-x-2 truncate">
                      <h3 className="font-bold text-gray-900 text-[15px] truncate">{displayName}</h3>
                    </div>
                    <span className="text-[11px] text-gray-400 shrink-0 ml-2">
                      {isText ? "今天" : record.date}
                    </span>
                  </div>
                  <div className="flex justify-between items-center mt-1">
                    <div className="flex items-center text-[12px] text-gray-500 truncate mr-2">
                      <p className="line-clamp-1 truncate">
                        {lastMsg}
                      </p>
                    </div>
                    {!isCounselorMode && (
                      <span className="text-[10px] text-blue-500 bg-blue-50 px-1.5 py-0.5 rounded shrink-0">
                        {subStatus}
                      </span>
                    )}
                  </div>
                </div>
              </button>
            );
          })}
          
          {chats.length === 0 && !sharedSummary && (!user.hasRisk || isCounselorMode) && (
            <div className="pt-10 flex flex-col items-center justify-center text-gray-400">
              <div className="text-4xl mb-3 opacity-50">💭</div>
              <p className="text-[13px]">暂无沟通记录</p>
            </div>
          )}
        </div>
      </div>
    </motion.div>
  );
}
