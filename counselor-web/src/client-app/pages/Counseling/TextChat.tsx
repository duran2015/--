import { useState, useRef, useEffect } from "react";
import { motion, AnimatePresence } from "motion/react";
import { ChevronLeft, Info, HelpCircle, ArrowRight, ArrowUp, Camera, Image as ImageIcon, Keyboard, Mic, Smile, PlayCircle, Video, FileText, Plus, PlusCircle, ClipboardList, Wind, Bell, Headphones, Moon, Sparkles, CircleDashed, MoreHorizontal } from "lucide-react";
import { useAppStore } from "../../store";
import { mockCounselors, mockConsultationRecords } from "../../data";

export function TextChat() {
    const { popView, pushView, bookingOrder, selectedCounselorId, setSelectedCounselorId, selectedConsultationId, appMode, selectedCounselorOrder, setActiveCallSession, setIsSessionCounselorDetail, counselorStatus, bookingSummary, consultationWorkflow, completeWorkflowTask } =
      useAppStore();

  const isCounselorMode = appMode === "counselor";

  // Get current order context
  const order = isCounselorMode ? selectedCounselorOrder : bookingOrder;
  const isVoiceOrVideo = order?.type === "voice" || order?.type === "video";
  const clientWorkflowMessage = !isCounselorMode
    ? consultationWorkflow.messages.find((message) => message.audience === "client" && message.orderId === order?.id)
      || consultationWorkflow.messages.find((message) => message.audience === "client")
    : undefined;

  const record = mockConsultationRecords.find(r => r.id === selectedConsultationId);
  const targetCounselorId = record?.counselorId || order?.counselorId || selectedCounselorId;
  const counselor = mockCounselors.find((c) => c.id === targetCounselorId) || mockCounselors[0];
  
  // For counselor mode, the "other party" is the user
  const otherParty = isCounselorMode ? {
    name: order?.userName || "匿名用户",
    avatar: order?.avatar || "https://ui-avatars.com/api/?name=User&background=random", 
  } : {
    name: counselor.name,
    avatar: counselor.avatar,
  };

  const myParty = isCounselorMode ? {
      name: counselor.name,
      avatar: counselor.avatar,
    } : {
      name: "我",
      avatar: order?.avatar || "https://ui-avatars.com/api/?name=User&background=random",
    };

  const handleAvatarClick = () => {
    if (!isCounselorMode) {
      setSelectedCounselorId(targetCounselorId);
      // We pass a flag to indicate this detail view is opened from a session (read-only mode)
      setIsSessionCounselorDetail(true);
      pushView("counseling-detail");
    }
  };

  const baseMessages = [
    {
      id: "sys-0",
      role: "system",
      text: `交易已建立，专属沟通通道已开启。双方可在此沟通准备事项。临近咨询开始时，系统会在此通知双方。`,
      type: "system"
    },
    {
      id: "sys-1-booking",
      role: "system",
      text: `【预约成功】${order?.type === "text" ? "文字沟通" : order?.type === "voice" ? "语音咨询" : "视频咨询"}`,
      type: "booking_success"
    }
  ];

  const assistantAvatar = "https://ui-avatars.com/api/?name=Assistant&background=EBF0FA&color=2B3A67";
  const assistantName = `${counselor.name}的小助理`;

  // Provide initial mock messages for the completed order
  const [messages, setMessages] = useState<{ id: string; role: "user" | "counselor" | "system" | "assistant"; text: string; type?: "text" | "scale" | "system" | "booking_success" | "room_invite" | "counselor_notes" | "evaluation_prompt" | "tool" | "summary_sync" | "assistant_ask"; assistantData?: any }[]>(() => {
    let extraMessages: any[] = [];
    
    if (order?.status === "paid" && !isCounselorMode) {
      const { bookingSummary } = useAppStore.getState();
      if (bookingSummary && bookingSummary.authorized) {
        extraMessages.push({
          id: "sys-summary-synced",
          role: "system",
          text: `可鹿 AI 已根据你刚才的沟通整理了一份咨询前摘要，并已同步给${counselor.name}。`,
          type: "summary_sync",
          assistantData: bookingSummary
        });
      } else if (bookingSummary && !bookingSummary.authorized) {
        extraMessages.push({
          id: "ast-ask-1",
          role: "assistant",
          text: `你好，我是${counselor.name}的小助理。你暂时没有同步刚才的 AI 摘要。为了让老师更好地准备，你可以简单补充一下这次想聊的问题吗？`,
          type: "assistant_ask"
        });
      } else {
        extraMessages.push({
          id: "ast-ask-2",
          role: "assistant",
          text: `你好，我是${counselor.name}的小助理。正式咨询前，我可以先帮老师了解你的情况，让咨询开始时更高效。你可以简单说说，这次最想和老师聊什么？`,
          type: "assistant_ask"
        });
      }
    }

    const defaultMessages = [
      ...baseMessages,
      ...extraMessages,
      ...(record?.messages ? record.messages.map((m, i) => ({ id: i.toString(), role: m.role as "user" | "counselor", text: m.content, type: "text" })) : []),
      ...(order?.status === "paid" && isVoiceOrVideo ? [
        {
          id: "sys-upcoming-invite",
          role: "system",
          text: `距离您的${order?.type === 'video' ? '视频' : '语音'}咨询开始还有 5 分钟，请点击下方卡片进入咨询室。`,
          type: "system"
        },
        {
          id: "sys-room-invite",
          role: "system",
          text: "咨询室已开放",
          type: "room_invite"
        }
      ] : []),
      ...(order?.status === "completed" ? [
        {
          id: "sys-evaluation-prompt",
          role: "system",
          text: "本次咨询已结束，沟通记录已永久沉淀",
          type: "evaluation_prompt"
        }
      ] : []),
      ...(order?.status === "completed" && order?.counselorNotesWritten ? [
        {
          id: "sys-counselor-notes",
          role: "counselor",
          text: "这是一份关于您本次咨询的小结与下一步建议...",
          type: "counselor_notes"
        }
      ] : [])
    ];
    if (order?.id === "req-1" || order?.status === "completed") {
      return [
        ...defaultMessages,
        {
          id: "mock-1",
          role: "counselor",
          text: "你好，我是张医生。今天感觉怎么样？",
          type: "text"
        },
        {
          id: "mock-2",
          role: "user",
          text: "最近工作压力有点大，老是睡不好...",
          type: "text"
        }
      ] as any;
    }
    return defaultMessages as any;
  });
  const [inputValue, setInputValue] = useState("");
  const [inputMode, setInputMode] = useState<"text" | "voice">("text");
  const [isRecording, setIsRecording] = useState(false);
  const [isTranscribing, setIsTranscribing] = useState(false);
  const [showPlusMenu, setShowPlusMenu] = useState(false);
  const [showEmojiMenu, setShowEmojiMenu] = useState(false);
  const [isFocused, setIsFocused] = useState(false);
  const scrollRef = useRef<HTMLDivElement>(null);

  const commonEmojis = ["😀","😂","😊","😍","🥰","😘","😎","🤔","🙄","😣","😪","😫","😌","😛","😜","🤤","😓","😔","🙃","😭","😱","😡","🤯","🤡","👻","💩","👍","👎","❤️","💔","✨","🎉","🔥","🌟","💯"];

  useEffect(() => {
    if (scrollRef.current) {
      scrollRef.current.scrollTop = scrollRef.current.scrollHeight;
    }
  }, [messages]);

  const myRole = isCounselorMode ? "counselor" : "user";
  const otherRole = isCounselorMode ? "user" : "counselor";

  // Watch for counselor notes being written and append to chat
  useEffect(() => {
    if (order?.status === "completed" && order?.counselorNotesWritten) {
      setMessages(prev => {
        if (!prev.some(m => m.type === "counselor_notes")) {
          return [
            ...prev,
            {
              id: "sys-counselor-notes-new",
              role: "counselor",
              text: "这是一份关于您本次咨询的小结与下一步建议...",
              type: "counselor_notes"
            }
          ];
        }
        return prev;
      });
    }
  }, [order?.status, order?.counselorNotesWritten]);

  // Watch for summary authorization
  useEffect(() => {
    if (!isCounselorMode && order?.status === "paid") {
      if (bookingSummary?.authorized) {
        setMessages(prev => {
          if (!prev.some(m => m.type === "summary_sync")) {
            return [
              ...prev,
              {
                id: "sys-summary-synced-" + Date.now(),
                role: "system",
                text: `可鹿 AI 已根据你的反馈整理了一份咨询前摘要，并已同步给${counselor.name}。`,
                type: "summary_sync",
                assistantData: bookingSummary
              }
            ];
          }
          return prev;
        });
      }
    }
  }, [bookingSummary?.authorized, order?.status, isCounselorMode]);

  const handleSend = (text?: string) => {
    const userText = text || inputValue;
    if (!userText.trim()) return;

    const newMsgId = Date.now().toString();
    setMessages((prev) => [
      ...prev,
      { id: newMsgId, role: myRole, text: userText, type: "text" },
    ]);
    setInputValue("");
    setShowPlusMenu(false);
    setShowEmojiMenu(false);

    // reset textarea height
    const ta = document.querySelector('textarea');
    if (ta) ta.style.height = 'auto';

    // Simulate other party reply
    setTimeout(() => {
      const state = useAppStore.getState();
      const hasUnauthorizedSummary = state.bookingSummary && !state.bookingSummary.authorized;
      const hasNoSummary = !state.bookingSummary;

      if (!isCounselorMode && order?.status === "paid" && (hasUnauthorizedSummary || hasNoSummary)) {
        setMessages((prev) => [
          ...prev,
          {
            id: Date.now().toString() + "_ast_reply",
            role: "assistant",
            text: "谢谢你的分享。为了让咨询更高效，我帮你生成了一份咨询前摘要，请确认是否同步给老师。",
            type: "text"
          },
        ]);
        setTimeout(() => {
          state.setBookingSummary({
            problem: userText,
            feeling: "有些焦虑",
            reason: "近期发生的事件",
            expectation: "希望能获得倾听和建议",
            authorized: false
          });
          pushView("ai-summary-sync");
        }, 2000);
      } else {
        setMessages((prev) => [
          ...prev,
          {
            id: Date.now().toString() + "_2",
            role: otherRole,
            text: isCounselorMode ? "好的，我明白了。" : "收到，请问还有其他需要准备的吗？",
            type: "text"
          },
        ]);
      }
    }, 1500);
  };

  const handleSendScale = () => {
    const newMsgId = Date.now().toString();
    setMessages((prev) => [
      ...prev,
      { id: newMsgId, role: myRole, text: "【PHQ-9 抑郁症状评估】量表", type: "scale" },
    ]);
  };

  const handleSendTool = (toolName: string) => {
    const newMsgId = Date.now().toString();
    setMessages((prev) => [
      ...prev,
      { id: newMsgId, role: myRole, text: toolName, type: "tool" },
    ]);
  };

  const handleEnterRoom = () => {
    if (!order) return;
    setActiveCallSession({
      orderId: order.id,
      type: order.type === "video" ? "video" : "voice",
      startTime: Date.now(),
    });
    pushView("voice-call");
  };

  return (
    <motion.div
      initial={{ x: "100%" }}
      animate={{ x: 0 }}
      exit={{ x: "100%" }}
      className="flex flex-col h-full bg-[#FAF8F5] absolute inset-0 z-[100] overflow-hidden"
    >
      {/* Header */}
      <div className="bg-white px-4 py-3 flex items-center justify-between border-b border-[#ECE6DC] shadow-sm z-10 shrink-0 mt-safe">
          <div className="flex items-center gap-3">
            <button
              onClick={popView}
              className="w-10 h-10 -ml-2 flex items-center justify-center text-[#7A756C] hover:text-[#1D1B16] hover:bg-[#F3E3DA] active:scale-95 rounded-full transition-colors"
            >
              <ChevronLeft size={24} />
            </button>
            <div className="flex items-center gap-3">
              <button 
                onClick={handleAvatarClick}
                className={`relative rounded-full focus:outline-none transition-transform active:scale-95 ${!isCounselorMode ? 'cursor-pointer focus:ring-2 focus:ring-[#6750A4]/50' : ''}`}
                title={!isCounselorMode ? "查看咨询师详情" : ""}
              >
                <img
                  src={otherParty.avatar}
                  alt={otherParty.name}
                  className="w-10 h-10 rounded-full object-cover ring-2 ring-[#6750A4]/20"
                />
                {!isCounselorMode && (
                  <div className={`absolute bottom-0 right-0 w-2.5 h-2.5 border-2 border-white rounded-full ${(targetCounselorId === 'c1' ? counselorStatus === 'active' : counselor.status === 'online') ? 'bg-emerald-500' : 'bg-gray-400'}`}></div>
                )}
              </button>
              <div>
                <div className="font-bold text-[#1D1B16] flex items-center gap-2">
                  <span>{otherParty.name}</span>
                  <span className="text-[10px] bg-[#EADDFF] text-[#21005D] px-1.5 py-0.5 rounded-md font-medium">
                    {order?.type === "text" ? "文字咨询" : order?.type === "voice" ? "语音咨询" : "视频咨询"}
                  </span>
                </div>
                <div className="text-[11px] text-[#7A756C] flex items-center gap-1 mt-0.5">
                  {!isCounselorMode ? (
                    <>
                      <span className={`w-1.5 h-1.5 rounded-full ${(targetCounselorId === 'c1' ? counselorStatus === 'active' : counselor.status === 'online') ? 'bg-emerald-500' : 'bg-gray-400'}`}></span>
                      {(targetCounselorId === 'c1' ? counselorStatus === 'active' : counselor.status === 'online') ? '当前在线' : '离线'}
                    </>
                  ) : (
                    <>
                      <span className="w-1.5 h-1.5 rounded-full bg-emerald-500"></span>
                      当前在线
                    </>
                  )}
                </div>
              </div>
            </div>
          </div>
          {!isCounselorMode && (
            <button 
              onClick={() => pushView("user-order-detail" as any)}
              className="p-2 text-[#7A756C] hover:text-[#1D1B16] hover:bg-[#F3E3DA] active:scale-95 rounded-full transition"
              title="查看订单详情"
            >
              <FileText className="w-5 h-5" />
            </button>
          )}
        </div>

      <div className="flex-1 overflow-y-auto p-4 space-y-4 bg-[#FAF8F5]" ref={scrollRef}>
        <div className="flex justify-center mb-6">
          <div className="bg-gray-100 text-gray-500 text-[11px] px-3 py-1 rounded-full flex items-center">
            知情同意书已签署
          </div>
        </div>
        
        {messages.map((msg) => {
          if (msg.type === "room_invite") {
            return (
              <div key={msg.id} className="flex justify-center my-4">
                <div className="bg-white border border-[#ECE6DC] p-4 rounded-[16px] shadow-xs text-center w-64 max-w-[85%]">
                  <div className="flex items-center justify-center text-[#6750A4] mb-2">
                    {order?.type === "video" ? <Video size={20} className="mr-1.5" /> : <Mic size={20} className="mr-1.5" />}
                    <span className="font-bold text-[14px]">咨询室已开放</span>
                  </div>
                  <p className="text-[12px] text-[#7A756C] mb-4">请双方准时进入咨询室，开启本次履约</p>
                  <button 
                    onClick={handleEnterRoom}
                    className="w-full py-2.5 rounded-xl text-[14px] font-bold bg-[#6750A4] text-white active:bg-[#594294] transition-colors shadow-xs"
                  >
                    进入咨询室
                  </button>
                </div>
              </div>
            );
          }

          if (msg.type === "booking_success") {
            return (
              <div key={msg.id} className="flex justify-center my-4">
                <div className="bg-white border border-[#ECE6DC] p-4 rounded-[16px] shadow-xs text-center w-64 max-w-[85%]">
                  <div className="flex items-center justify-center text-[#6750A4] mb-2">
                    <PlayCircle size={18} className="mr-1.5" />
                    <span className="font-bold text-[14px]">预约订单已生成</span>
                  </div>
                  <p className="text-[13px] text-[#1D1B16] font-medium mb-1">
                    【预约成功】{order?.type === "text" ? "文字沟通" : order?.type === "voice" ? "语音咨询" : "视频咨询"}
                  </p>
                  <p className="text-[11px] text-[#7A756C]">时间: {order?.date} {order?.time}</p>
                </div>
              </div>
            );
          }

          if (msg.type === "evaluation_prompt") {
            return (
              <div key={msg.id} className="flex justify-center my-4">
                <div className="bg-white border border-[#ECE6DC] rounded-[16px] p-4 shadow-xs w-64 max-w-[85%]">
                  <div className="flex flex-col items-center text-center">
                    <div className="w-12 h-12 bg-[#FAF8F5] text-[#7A756C] rounded-full flex items-center justify-center mb-2 border border-[#ECE6DC]">
                      <FileText size={24} />
                    </div>
                    <h3 className="font-bold text-[#1D1B16] text-[15px] mb-1">本次咨询已结束</h3>
                    <p className="text-[12px] text-[#7A756C] mb-4">沟通记录已永久沉淀</p>
                    {isCounselorMode ? (
                      <button 
                        onClick={() => pushView("counselor-session-notes" as any)}
                        disabled={order?.counselorNotesWritten}
                        className={`w-full py-2.5 rounded-xl text-[14px] font-bold shadow-xs transition-all flex items-center justify-center ${order?.counselorNotesWritten ? 'bg-[#FAF8F5] text-[#A8A398] cursor-not-allowed border border-[#ECE6DC]' : 'bg-[#6750A4] text-white active:scale-95'}`}
                      >
                        {order?.counselorNotesWritten ? "已发送小结" : "写小结与建议"}
                      </button>
                    ) : (
                      <button 
                        onClick={() => pushView("user-evaluation" as any)}
                        disabled={order?.isEvaluated}
                        className={`w-full py-2.5 rounded-xl text-[14px] font-bold shadow-xs transition-all flex items-center justify-center ${order?.isEvaluated ? 'bg-[#FAF8F5] text-[#A8A398] cursor-not-allowed border border-[#ECE6DC]' : 'bg-[#6750A4] text-white active:scale-95'}`}
                      >
                        {order?.isEvaluated ? "已评价" : "去评价本次咨询"}
                      </button>
                    )}
                  </div>
                </div>
              </div>
            );
          }

          if (msg.type === "summary_sync") {
            return (
              <div key={msg.id} className="flex justify-center my-4">
                <div className="bg-[#F3E3DA] border border-[#ECE6DC] p-4 rounded-[16px] shadow-xs text-left w-64 max-w-[85%]">
                  <div className="flex items-center text-[#A23F1E] mb-2">
                    <Info size={16} className="mr-1.5 shrink-0" />
                    <span className="font-bold text-[13px] leading-snug">{msg.text}</span>
                  </div>
                  {msg.assistantData && (
                    <div className="bg-white rounded-xl p-3 border border-[#ECE6DC]">
                      <div className="text-[12px] font-bold text-[#7A756C] mb-1">主要困扰</div>
                      <div className="text-[13px] text-[#1D1B16] mb-2">{msg.assistantData.problem}</div>
                      <div className="text-[12px] font-bold text-[#7A756C] mb-1">当前情绪</div>
                      <div className="text-[13px] text-[#1D1B16]">{msg.assistantData.feeling}</div>
                    </div>
                  )}
                </div>
              </div>
            );
          }

          if (msg.type === "assistant_ask" || msg.role === "assistant") {
            return (
              <div key={msg.id} className="flex flex-col items-start">
                <div className="flex items-end gap-2 max-w-[85%]">
                  <button className="shrink-0 mb-1 rounded-full focus:outline-none transition-transform active:scale-95 cursor-default">
                    <img
                      src={assistantAvatar}
                      alt=""
                      className="w-6 h-6 rounded-full object-cover"
                    />
                  </button>
                  <div className="flex flex-col items-start">
                    <div className="text-[9px] text-[#A8A398] mb-1 px-1">{assistantName}</div>
                    <div className="px-3.5 py-2.5 rounded-[16px] text-sm leading-relaxed bg-white border border-[#ECE6DC] text-[#1D1B16] rounded-bl-sm shadow-xs">
                      {msg.text}
                    </div>
                  </div>
                </div>
              </div>
            );
          }

          if (msg.type === "scale") {
            return (
              <div
                key={msg.id}
                className={`flex flex-col ${msg.role === myRole ? "items-end" : "items-start"}`}
              >
                <div className="flex items-end gap-2 max-w-[85%]">
                  {msg.role === otherRole && (
                    <button 
                      onClick={handleAvatarClick}
                      className={`shrink-0 mb-1 rounded-full focus:outline-none transition-transform active:scale-95 ${!isCounselorMode ? 'cursor-pointer focus:ring-1 focus:ring-[#6750A4]/50' : ''}`}
                    >
                      <img
                        src={otherParty.avatar}
                        alt=""
                        className="w-6 h-6 rounded-full object-cover cursor-pointer"
                      />
                    </button>
                  )}
                  
                  <div className={`flex flex-col ${msg.role === myRole ? "items-end" : "items-start"}`}>
                    <div className={`w-64 bg-white border border-[#ECE6DC] p-3 rounded-[16px] shadow-xs ${msg.role === myRole ? "rounded-br-sm" : "rounded-bl-sm"}`}>
                      <div className="flex items-center gap-2 mb-2">
                        <div className="bg-[#FAF8F5] p-1.5 rounded-lg border border-[#ECE6DC]">
                          <FileText className="w-4 h-4 text-[#A23F1E]" />
                        </div>
                        <div className="font-bold text-xs text-[#1D1B16]">专业测评邀请</div>
                      </div>
                      <div className="text-[10px] text-[#7A756C] mb-3 line-clamp-2 leading-relaxed">
                        {msg.text}
                      </div>
                      <button 
                        onClick={() => !isCounselorMode && pushView("assessment-test" as any)}
                        className={`w-full py-1.5 bg-[#FAF8F5] border border-[#ECE6DC] text-[11px] font-bold rounded-lg transition-colors ${isCounselorMode ? 'text-[#7A756C] cursor-default' : 'text-[#6750A4] active:bg-[#F3E3DA]'}`}
                      >
                        {isCounselorMode ? "等待来访者填写..." : "点击填写"}
                      </button>
                    </div>
                  </div>
                </div>
              </div>
            );
          }

          if (msg.type === "tool") {
            return (
              <div
                key={msg.id}
                className={`flex flex-col ${msg.role === myRole ? "items-end" : "items-start"}`}
              >
                <div className="flex items-end gap-2 max-w-[85%]">
                  {msg.role === otherRole && (
                    <button 
                      onClick={handleAvatarClick}
                      className={`shrink-0 mb-1 rounded-full focus:outline-none transition-transform active:scale-95 ${!isCounselorMode ? 'cursor-pointer focus:ring-1 focus:ring-[#6750A4]/50' : ''}`}
                    >
                      <img
                        src={otherParty.avatar}
                        alt=""
                        className="w-6 h-6 rounded-full object-cover cursor-pointer"
                      />
                    </button>
                  )}
                  <div className={`flex flex-col ${msg.role === myRole ? "items-end" : "items-start"}`}>
                    <div className={`w-64 bg-white border border-[#ECE6DC] p-3 rounded-[16px] shadow-xs ${msg.role === myRole ? "rounded-br-sm" : "rounded-bl-sm"}`}>
                      <div className="flex items-center gap-2 mb-2">
                        <div className="bg-[#FAF8F5] p-1.5 rounded-lg border border-[#ECE6DC]">
                          <Sparkles className="w-4 h-4 text-[#6750A4]" />
                        </div>
                        <div className="font-bold text-xs text-[#1D1B16]">小工具推荐</div>
                      </div>
                      <div className="text-[10px] text-[#7A756C] mb-3 line-clamp-2 leading-relaxed">
                        咨询师向您推荐了【{msg.text}】小工具，帮助您平复心情。
                      </div>
                      <button 
                        className={`w-full py-1.5 bg-[#FAF8F5] border border-[#ECE6DC] text-[11px] font-bold rounded-lg transition-colors ${isCounselorMode ? 'text-[#7A756C] cursor-default' : 'text-[#6750A4] active:bg-[#F3E3DA]'}`}
                      >
                        {isCounselorMode ? "已发送" : "去体验"}
                      </button>
                    </div>
                  </div>
                </div>
              </div>
            );
          }

          if (msg.type === "counselor_notes") {
            return (
              <div
                key={msg.id}
                className={`flex flex-col ${msg.role === myRole ? "items-end" : "items-start"}`}
              >
                <div className="flex items-end gap-2 max-w-[85%]">
                  {msg.role === otherRole && (
                    <button 
                      onClick={handleAvatarClick}
                      className={`shrink-0 mb-1 rounded-full focus:outline-none transition-transform active:scale-95 ${!isCounselorMode ? 'cursor-pointer focus:ring-1 focus:ring-[#6750A4]/50' : ''}`}
                    >
                      <img
                        src={otherParty.avatar}
                        alt=""
                        className="w-6 h-6 rounded-full object-cover cursor-pointer"
                      />
                    </button>
                  )}
                  <div className={`flex flex-col ${msg.role === myRole ? "items-end" : "items-start"}`}>
                    <div className={`w-64 bg-white border border-[#ECE6DC] p-3 rounded-[16px] shadow-xs ${msg.role === myRole ? "rounded-br-sm" : "rounded-bl-sm"}`}>
                      <div className="flex items-center gap-2 mb-2">
                        <div className="bg-[#FAF8F5] p-1.5 rounded-lg border border-[#ECE6DC]">
                          <FileText className="w-4 h-4 text-[#A23F1E]" />
                        </div>
                        <div className="font-bold text-xs text-[#1D1B16]">咨询小结与建议</div>
                      </div>
                      <div className="bg-[#FAF8F5] rounded-xl p-2 mb-3 border border-[#ECE6DC]">
                        <div className="text-[10px] text-[#49463D] leading-relaxed mb-1.5"><strong className="text-[#1D1B16]">小结：</strong>本次沟通中，我们探讨了职场人际压力与自我认同感的问题。你在会话后半段展现出了很好的觉察力。</div>
                        <div className="text-[10px] text-[#49463D] leading-relaxed"><strong className="text-[#1D1B16]">建议：</strong>本周可以尝试记录一次“自动思维”，并在感到压力时使用 4-7-8 呼吸法放松。我们下次见。</div>
                      </div>
                      <button 
                        onClick={() => pushView("counseling-summary-detail")}
                        className={`w-full py-1.5 bg-[#FAF8F5] border border-[#ECE6DC] text-[11px] font-bold rounded-lg transition-colors text-[#6750A4] active:bg-[#F3E3DA]`}
                      >
                        点击查看详情
                      </button>
                    </div>
                  </div>
                </div>
              </div>
            );
          }

          if (msg.type === "system" || msg.role === "system") {
            return (
              <div key={msg.id} className="flex justify-center my-4">
                <div className="bg-[#E8E2D5] text-[#49463D] text-[10px] px-3 py-1 rounded-full my-2 max-w-[85%] text-center leading-relaxed">
                  {msg.text}
                </div>
              </div>
            );
          }

          return (
            <div
              key={msg.id}
              className={`flex flex-col ${msg.role === myRole ? "items-end" : "items-start"}`}
            >
              <div className="flex items-end gap-2 max-w-[85%]">
                {msg.role === otherRole && (
                  <button 
                    onClick={handleAvatarClick}
                    className={`shrink-0 mb-1 rounded-full focus:outline-none transition-transform active:scale-95 ${!isCounselorMode ? 'cursor-pointer focus:ring-1 focus:ring-[#6750A4]/50' : ''}`}
                  >
                    <img
                      src={otherParty.avatar}
                      alt=""
                      className="w-6 h-6 rounded-full object-cover cursor-pointer"
                    />
                  </button>
                )}
                
                <div className={`flex flex-col ${msg.role === myRole ? "items-end" : "items-start"}`}>
                  <div
                    className={`px-3.5 py-2.5 rounded-[16px] text-sm leading-relaxed ${
                      msg.role === myRole 
                        ? "bg-[#6750A4] text-white rounded-br-sm" 
                        : "bg-white border border-[#ECE6DC] text-[#1D1B16] rounded-bl-sm shadow-xs"
                    }`}
                  >
                    {msg.text}
                  </div>
                </div>
              </div>
            </div>
          );
        })}
        {clientWorkflowMessage && (
          <div className="flex flex-col items-start">
            <div className="flex max-w-[88%] items-end gap-2">
              <img src={otherParty.avatar} alt="" className="mb-1 h-6 w-6 shrink-0 rounded-full object-cover" />
              <button
                onClick={() => {
                  const task = consultationWorkflow.tasks.find(
                    (item) => item.draftId === clientWorkflowMessage.draftId && item.taskType === "read_session_recap",
                  );
                  if (task) completeWorkflowTask(task.id);
                  pushView("counseling-summary");
                }}
                className="w-64 overflow-hidden rounded-[20px] border border-[#D0BCFF] bg-white text-left shadow-sm active:scale-[0.99]"
              >
                <div className="bg-[#EADDFF] p-4 text-[#21005D]">
                  <div className="flex items-center justify-between">
                    <div className="grid h-9 w-9 place-items-center rounded-[13px] bg-white/60"><Sparkles size={18} /></div>
                    <span className="rounded-full bg-[#C4EED0] px-2 py-1 text-[9px] font-black text-[#163723]">咨询师已确认</span>
                  </div>
                  <h3 className="mt-3 text-[15px] font-black">{clientWorkflowMessage.title}</h3>
                  <p className="mt-1 line-clamp-3 text-[11px] leading-5 opacity-80">{clientWorkflowMessage.description}</p>
                </div>
                <div className="flex items-center justify-between px-4 py-3 text-[11px] font-black text-[#6750A4]">
                  {clientWorkflowMessage.actionLabel}<ArrowRight size={15} />
                </div>
              </button>
            </div>
            <div className="ml-8 mt-1 text-[9px] text-[#A8A398]">仅含用户可见回顾 · 内部记录未分享</div>
          </div>
        )}
      </div>

      {/* Input Area */}
      <div className={`absolute bottom-0 left-0 right-0 border-t pt-2 z-20 flex flex-col transition-colors duration-200 bg-[#f8f9fa] border-gray-200/60`}>
        {/* Input Row */}
        <div className={`px-3 pb-2 flex items-end space-x-2.5 relative z-10 transition-colors bg-[#FAF8F5]`}>
          <div className={`flex-1 rounded-[22px] border shadow-sm flex items-end min-h-[44px] relative transition-all overflow-hidden p-1 pl-1.5 ${isFocused ? 'ring-2 ring-[#6750A4]/20 border-[#6750A4]/40' : ''} bg-white border-[#ECE6DC]`}>
            {/* + Menu Trigger (Inside input) */}
            <button 
              onClick={() => setShowPlusMenu(!showPlusMenu)} 
              className={`w-9 h-9 rounded-full flex items-center justify-center shrink-0 transition-colors ${showPlusMenu ? 'text-[#7A756C] active:text-[#49463D]' : 'text-[#A8A398] active:text-[#7A756C]'}`}
            >
              <PlusCircle size={24} strokeWidth={1.5} className={showPlusMenu ? 'rotate-45 transition-transform' : 'transition-transform'} />
            </button>

            {inputMode === "text" ? (
              <>
                <textarea
                  value={inputValue}
                  onChange={(e) => {
                    setInputValue(e.target.value);
                    e.target.style.height = 'auto';
                    e.target.style.height = Math.min(e.target.scrollHeight, 120) + 'px';
                    if (showPlusMenu) setShowPlusMenu(false);
                    if (showEmojiMenu) setShowEmojiMenu(false);
                  }}
                  onFocus={() => {
                    setIsFocused(true);
                    if (showPlusMenu) setShowPlusMenu(false);
                    if (showEmojiMenu) setShowEmojiMenu(false);
                  }}
                  onBlur={() => setTimeout(() => setIsFocused(false), 200)}
                  onKeyDown={(e) => { 
                    if(e.key === "Enter" && !e.shiftKey) { 
                      e.preventDefault();
                      handleSend(); 
                    } 
                  }}
                  rows={1}
                  className={`flex-1 bg-transparent border-none outline-none text-[15px] px-2 py-2 resize-none max-h-[120px] self-center leading-relaxed text-[#1D1B16] placeholder-[#A8A398]`}
                  placeholder="发消息..."
                />
                <button 
                  onClick={() => { setShowEmojiMenu(!showEmojiMenu); setShowPlusMenu(false); }} 
                  className={`w-9 h-9 transition-colors flex items-center justify-center shrink-0 text-[#A8A398] active:text-[#6750A4]`}
                >
                  <Smile size={22} strokeWidth={1.5} className={showEmojiMenu ? 'text-[#6750A4]' : ''} />
                </button>
                {!inputValue.trim() && (
                  <button onClick={() => setInputMode("voice")} className={`w-9 h-9 transition-colors flex items-center justify-center shrink-0 text-[#A8A398] active:text-[#6750A4]`}>
                    <Mic size={22} strokeWidth={1.5} />
                  </button>
                )}
              </>
            ) : (
              <div className="flex-1 flex items-center h-[36px] mt-0.5 pr-1">
                <button onClick={() => { setInputMode("text"); setShowEmojiMenu(false); }} className={`pl-1 pr-3 transition-colors flex items-center h-full shrink-0 text-[#A8A398] active:text-[#6750A4]`}>
                  <Keyboard size={20} strokeWidth={1.5} />
                </button>
                <div 
                  className={`flex-1 h-[32px] rounded-full flex items-center justify-center font-bold text-[14px] select-none transition-colors cursor-pointer ${isRecording ? "bg-[#6750A4] text-white" : "bg-[#FAF8F5] text-[#7A756C]"}`}
                  onPointerDown={() => setIsRecording(true)}
                  onPointerUp={() => {
                    setIsRecording(false);
                    setIsTranscribing(true);
                    setTimeout(() => {
                      setIsTranscribing(false);
                      handleSend(isCounselorMode ? "好的，我来帮你看看。" : "我现在感觉有点焦虑，能陪我聊聊吗？");
                      setInputMode("text");
                    }, 1500);
                  }}
                  onPointerCancel={() => setIsRecording(false)}
                >
                  {isTranscribing ? "转译中..." : isRecording ? "松开 发送" : "按住 说话"}
                </div>
              </div>
            )}
          </div>

          {/* Send Button outside (only when typing) */}
          <AnimatePresence>
            {inputValue.trim() && (
              <motion.div 
                initial={{ scale: 0, opacity: 0 }}
                animate={{ scale: 1, opacity: 1 }}
                exit={{ scale: 0, opacity: 0 }}
                className="shrink-0 mb-1"
              >
                <button onClick={() => handleSend()} className="w-[38px] h-[38px] bg-[#6750A4] text-white rounded-full flex items-center justify-center shadow-xs active:scale-95 transition-transform">
                  <ArrowUp size={22} strokeWidth={2.5} />
                </button>
              </motion.div>
            )}
          </AnimatePresence>
        </div>

        {/* Expandable Emoji Menu */}
          <AnimatePresence>
            {showEmojiMenu && (
              <motion.div
                initial={{ height: 0, opacity: 0 }}
                animate={{ height: "auto", opacity: 1 }}
                exit={{ height: 0, opacity: 0 }}
                className={`overflow-hidden z-10 relative transition-colors bg-[#FAF8F5]`}
              >
                <div className={`p-4 border-t mt-3 mx-auto border-[#ECE6DC]`}>
                  <div className="grid grid-cols-7 gap-2">
                    {commonEmojis.map((emoji, i) => (
                      <button 
                        key={i} 
                        onClick={() => {
                          setInputValue(prev => prev + emoji);
                        }}
                        className="text-[24px] flex items-center justify-center h-10 hover:bg-[#F3E3DA] active:bg-[#ECE6DC] rounded-lg transition-colors"
                      >
                        {emoji}
                      </button>
                    ))}
                  </div>
                </div>
              </motion.div>
            )}
          </AnimatePresence>

          {/* Expandable Plus Menu */}
        <AnimatePresence>
          {showPlusMenu && (
            <motion.div
              initial={{ height: 0, opacity: 0 }}
              animate={{ height: "auto", opacity: 1 }}
              exit={{ height: 0, opacity: 0 }}
              className={`overflow-hidden z-10 relative transition-colors bg-[#FAF8F5]`}
            >
              <div className={`pt-5 pb-8 px-6 grid grid-rows-2 grid-flow-col gap-x-8 gap-y-5 overflow-x-auto no-scrollbar border-t mt-3 border-[#ECE6DC] auto-cols-max`} style={{ scrollbarWidth: 'none', msOverflowStyle: 'none' }}>
                <style>{`
                  .no-scrollbar::-webkit-scrollbar {
                    display: none;
                  }
                `}</style>
                {[
                  { icon: ImageIcon, label: "相册", color: "text-blue-500", onClick: () => setShowPlusMenu(false) },
                  { icon: Camera, label: "拍摄", color: "text-[#7A756C]", onClick: () => setShowPlusMenu(false) },
                  ...(isCounselorMode && order?.status === "paid" ? [
                    { icon: ClipboardList, label: "发送量表", color: "text-[#6750A4]", onClick: () => { handleSendScale(); setShowPlusMenu(false); } }
                  ] : []),
                  ...(!isCounselorMode || order?.status !== "paid" ? [
                    { icon: FileText, label: "文件", color: "text-orange-500", onClick: () => setShowPlusMenu(false) }
                  ] : []),
                  ...(isCounselorMode ? [
                    { icon: Wind, label: "深呼吸", color: "text-sky-500", onClick: () => { handleSendTool("深呼吸放松"); setShowPlusMenu(false); } },
                    { icon: Bell, label: "敲木鱼", color: "text-amber-600", onClick: () => { handleSendTool("电子木鱼"); setShowPlusMenu(false); } },
                    { icon: Headphones, label: "白噪音", color: "text-indigo-400", onClick: () => { handleSendTool("白噪音助眠"); setShowPlusMenu(false); } },
                    { icon: Moon, label: "助眠指引", color: "text-violet-500", onClick: () => { handleSendTool("助眠指引"); setShowPlusMenu(false); } },
                    { icon: Sparkles, label: "冥想", color: "text-fuchsia-500", onClick: () => { handleSendTool("正念冥想"); setShowPlusMenu(false); } },
                    { icon: CircleDashed, label: "捏泡泡", color: "text-pink-400", onClick: () => { handleSendTool("捏泡泡解压"); setShowPlusMenu(false); } }
                  ] : [])
                ].map((item, i) => (
                  <button key={i} onClick={item.onClick} className="flex flex-col items-center active:scale-95 transition-transform w-14 shrink-0">
                    <div className={`w-14 h-14 rounded-2xl flex items-center justify-center shadow-xs border mb-2 bg-white border-[#ECE6DC]`}>
                      <item.icon size={26} strokeWidth={1.5} className={item.color} />
                    </div>
                    <span className={`text-[11px] font-medium text-[#7A756C] whitespace-nowrap`}>{item.label}</span>
                  </button>
                ))}
              </div>
            </motion.div>
          )}
        </AnimatePresence>

        {/* Mock iOS Keyboard Presentation */}
        <AnimatePresence>
          {isFocused && (
            <motion.div
              initial={{ height: 0, opacity: 0 }}
              animate={{ height: 260, opacity: 1 }}
              exit={{ height: 0, opacity: 0 }}
              transition={{ type: "spring", damping: 25, stiffness: 250 }}
              className="w-full bg-[#D1D4D9] flex flex-col justify-start px-1 pt-3 pb-8 select-none overflow-hidden"
              onMouseDown={(e) => e.preventDefault()}
            >
              <div className="flex justify-center space-x-1.5 mb-3 px-1">
                {['Q','W','E','R','T','Y','U','I','O','P'].map(k => (
                  <div key={k} className="w-[9%] h-11 bg-white rounded-lg flex items-center justify-center text-[17px] font-medium text-gray-900 shadow-sm">{k}</div>
                ))}
              </div>
              <div className="flex justify-center space-x-1.5 mb-3 px-5">
                {['A','S','D','F','G','H','J','K','L'].map(k => (
                  <div key={k} className="w-[10%] h-11 bg-white rounded-lg flex items-center justify-center text-[17px] font-medium text-gray-900 shadow-sm">{k}</div>
                ))}
              </div>
              <div className="flex justify-center space-x-1.5 mb-3 px-1">
                <div className="w-[13%] h-11 bg-[#B3B6BE] rounded-lg flex items-center justify-center shadow-sm">
                  <ArrowUp size={18} strokeWidth={2.5} className="text-gray-900" />
                </div>
                {['Z','X','C','V','B','N','M'].map(k => (
                  <div key={k} className="w-[10%] h-11 bg-white rounded-lg flex items-center justify-center text-[17px] font-medium text-gray-900 shadow-sm">{k}</div>
                ))}
                <div className="w-[13%] h-11 bg-[#B3B6BE] rounded-lg flex items-center justify-center shadow-sm">
                  <svg width="22" height="16" viewBox="0 0 18 14" fill="none" xmlns="http://www.w3.org/2000/svg">
                    <path d="M5.5 1L1 7L5.5 13H16C16.5523 13 17 12.5523 17 12V2C17 1.44772 16.5523 1 16 1H5.5Z" stroke="#111" strokeWidth="1.5" strokeLinejoin="round"/>
                    <path d="M9 4.5L14 9.5M14 4.5L9 9.5" stroke="#111" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
                  </svg>
                </div>
              </div>
              <div className="flex justify-center space-x-1.5 px-1">
                <div className="w-[22%] h-11 bg-[#B3B6BE] rounded-lg flex items-center justify-center text-[15px] font-medium text-gray-900 shadow-sm">123</div>
                <div className="w-[12%] h-11 bg-[#B3B6BE] rounded-lg flex items-center justify-center shadow-sm"><Mic size={20} className="text-gray-900"/></div>
                <div className="w-[42%] h-11 bg-white rounded-lg flex items-center justify-center text-[15px] font-medium text-gray-900 shadow-sm">换行 (Shift+Enter)</div>
                <div className="w-[22%] h-11 bg-blue-500 rounded-lg flex items-center justify-center text-[15px] font-bold text-white shadow-sm" onClick={() => {
                  handleSend();
                  setIsFocused(false);
                }}>发送</div>
              </div>
            </motion.div>
          )}
        </AnimatePresence>
      </div>
    </motion.div>
  );
}
