import { useEffect, useMemo, useRef, useState } from "react";
import { AnimatePresence, motion } from "motion/react";
import {
  BellRing,
  CalendarClock,
  CheckCircle2,
  ChevronLeft,
  Copy,
  LockKeyhole,
  MessageSquare,
  Mic,
  MicOff,
  Minimize2,
  PhoneOff,
  Send,
  ShieldCheck,
  SwitchCamera,
  Video as VideoIcon,
  VideoOff,
  Volume2,
  X,
  Sparkles,
  MoreHorizontal,
  AlertTriangle,
  FileText,
} from "lucide-react";
import { useAppStore } from "../../store";
import { mockCounselors, mockUser } from "../../data";
import {
  getVoiceCallPresentation,
  getMeetingLayerClass,
  type MeetingState,
} from "../../../voiceCallPresentation";
import { buildMockSessionSnapshot } from "../../../consultationWorkflowMock";
import { resolveMeetingClient } from "../../../meetingParticipant";
import { getMockEmotionFeedback, toEmotionSessionInsights } from "../../../emotionFeedback";
import { EmotionStatusChip } from "../../../components/ConsultationRoom/EmotionStatusChip";
import { EmotionChangeSnackbar } from "../../../components/ConsultationRoom/EmotionChangeSnackbar";
import { EmotionDynamicsCard } from "../../../components/ConsultationRoom/EmotionDynamicsCard";
import type { Order, SessionSnapshot } from "../../../types";

type MediaPermissionState = { camera: boolean; microphone: boolean };

interface VoiceCallProps {
  propOrder?: unknown;
  propMode?: "counselor" | "user";
  onClose?: () => void;
  onSessionEnded?: (order: Order, snapshot: SessionSnapshot) => void;
}

const detectClientPlatform = () => {
  if (typeof navigator === "undefined") return "当前设备";
  const ua = navigator.userAgent.toLowerCase();
  if (ua.includes("miniprogram") || ua.includes("micromessenger")) return "微信小程序";
  if (/iphone|ipad|ipod/.test(ua)) return "iOS";
  if (ua.includes("android")) return "Android";
  return "当前设备";
};

export function VoiceCall({ propOrder, propMode, onClose, onSessionEnded }: VoiceCallProps) {
  const {
    popView,
    pushView,
    bookingOrder,
    selectedCounselorOrder,
    selectedCounselorId,
    isCallMinimized,
    setIsCallMinimized,
    setActiveCallSession,
    updateOrder,
  } = useAppStore();

  const isCounselorView = propMode === "counselor" || Boolean(selectedCounselorOrder);
  const order = propOrder || (isCounselorView ? selectedCounselorOrder : bookingOrder);
  const isVideo = order?.serviceTypeName?.includes("视频") || order?.type?.includes("video") || order?.type === "video";
  const counselor = mockCounselors.find((item) => item.id === (order?.counselorId || selectedCounselorId)) || mockCounselors[0];
  const user = mockUser;
  const meetingClient = resolveMeetingClient(order, {
    name: user.name || "小鹿用户3821",
    avatar: user.avatar,
  });

  const otherName = isCounselorView ? meetingClient.name : counselor.name;
  const otherAvatar = isCounselorView ? meetingClient.avatar : counselor.avatar;
  const selfAvatar = isCounselorView ? counselor.avatar : user.avatar;
  const selfName = isCounselorView ? counselor.name : user.name || "我";
  const selfRole = isCounselorView ? "咨询师" : "用户";
  const otherRole = isCounselorView ? "用户" : "咨询师";
  const roomNumber = `KL-${String(order?.id || "849201").replace(/\D/g, "").slice(-6).padStart(6, "0")}`;
  const mockSnapshot = useMemo(
    () => buildMockSessionSnapshot((order || { id: "demo", clientName: "来访者" }) as Order),
    [order?.id],
  );

  const [meetingState, setMeetingState] = useState<MeetingState>("waiting");
  const roomPresentation = getVoiceCallPresentation(meetingState, isVideo);
  const [muted, setMuted] = useState(false);
  const [cameraOff, setCameraOff] = useState(!isVideo);
  const [speaker, setSpeaker] = useState(true);
  const [duration, setDuration] = useState(0);
  const emotionPresentation = useMemo(
    () => getMockEmotionFeedback(duration, isVideo ? "video" : "voice", !cameraOff),
    [duration, isVideo, cameraOff],
  );
  const [scratchpad, setScratchpad] = useState(mockSnapshot.notes.map((note) => note.text).join("\n"));
  
  // AI Panel & More Menus
  const [aiPanelOpen, setAiPanelOpen] = useState(false);
  const [showChat, setShowChat] = useState(false);
  const [showRiskReport, setShowRiskReport] = useState(false);
  const [dismissedEmotionEventId, setDismissedEmotionEventId] = useState<string | null>(null);

  const [showPermissionPrompt, setShowPermissionPrompt] = useState(false);
  const platform = detectClientPlatform();
  const permissionStorageKey = `kelu-media-permissions:${platform}`;
  const [mediaPermissions, setMediaPermissions] = useState<MediaPermissionState>(() => {
    if (typeof window === "undefined") return { camera: false, microphone: false };
    try {
      return JSON.parse(window.localStorage.getItem(permissionStorageKey) || "null") || { camera: false, microphone: false };
    } catch {
      return { camera: false, microphone: false };
    }
  });
  
  const needsCameraPermission = isVideo && !mediaPermissions.camera;
  const needsMicrophonePermission = !mediaPermissions.microphone;
  const requestedPermissionLabel = needsCameraPermission && needsMicrophonePermission ? "相机和麦克风" : needsCameraPermission ? "相机" : "麦克风";
  
  const [notice, setNotice] = useState("");
  const [messages, setMessages] = useState<{ id: string; sender: "me" | "other"; text: string; time: string }[]>([]);
  const [inputValue, setInputValue] = useState("");
  const scrollRef = useRef<HTMLDivElement>(null);
  const aiScrollRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (meetingState !== "waiting") return;
    const joinTimer = setTimeout(() => setMeetingState("in-call"), 4000);
    return () => clearTimeout(joinTimer);
  }, [meetingState]);

  useEffect(() => {
    if (meetingState !== "in-call") return;
    const timer = setInterval(() => setDuration((value) => value + 1), 1000);
    return () => clearInterval(timer);
  }, [meetingState]);

  useEffect(() => {
    if (!notice) return;
    const timer = setTimeout(() => setNotice(""), 1600);
    return () => clearTimeout(timer);
  }, [notice]);

  useEffect(() => {
    if (scrollRef.current) scrollRef.current.scrollTop = scrollRef.current.scrollHeight;
  }, [messages, showChat]);

  useEffect(() => {
    if (aiPanelOpen && aiScrollRef.current) aiScrollRef.current.scrollTop = 0;
  }, [aiPanelOpen]);

  useEffect(() => {
    const event = emotionPresentation.significantEvent;
    if (!event || dismissedEmotionEventId === event.id) return;
    const timer = setTimeout(() => setDismissedEmotionEventId(event.id), 6000);
    return () => clearTimeout(timer);
  }, [emotionPresentation.significantEvent?.id, dismissedEmotionEventId]);

  const formatTime = (seconds: number) => `${Math.floor(seconds / 60).toString().padStart(2, "0")}:${(seconds % 60).toString().padStart(2, "0")}`;

  const openEmotionDynamics = () => {
    setAiPanelOpen(true);
    requestAnimationFrame(() => document.getElementById("emotion-dynamics")?.focus());
  };

  const leaveMeeting = () => {
    setActiveCallSession(null);
    setIsCallMinimized(false);
    if (onClose) onClose(); else popView();
  };

  const endMeeting = () => {
    if (order?.id) updateOrder(order.id, { status: "completed", callDuration: duration });
    setMeetingState("ended");
    setShowChat(false);
    setAiPanelOpen(false);
    setIsCallMinimized(false);
  };

  const finishAndGoToSummary = () => {
    if (isCounselorView) {
      const sessionOrder = order as Order;
      const snapshot: SessionSnapshot = {
        ...mockSnapshot,
        durationSeconds: duration || mockSnapshot.durationSeconds,
        insights: [
          ...mockSnapshot.insights,
          ...toEmotionSessionInsights(
            mockSnapshot.transcript[0]?.sessionId || `session-${sessionOrder.id}`,
            emotionPresentation.significantEvent ? [emotionPresentation.significantEvent] : [],
          ),
        ],
        notes: scratchpad.trim()
          ? [
              { id: `${mockSnapshot.transcript[0]?.sessionId || `session-${sessionOrder.id}`}-n-live`, text: scratchpad.trim() },
              ...mockSnapshot.notes,
            ]
          : mockSnapshot.notes,
      };
      setActiveCallSession(null);
      setIsCallMinimized(false);
      if (onSessionEnded) {
        onSessionEnded(sessionOrder, snapshot);
      } else {
        useAppStore.getState().endConsultationSession(sessionOrder, snapshot);
        pushView("counselor-session-notes" as any);
      }
    } else {
      const sessionOrder = order as Order;
      useAppStore.getState().endConsultationSession(sessionOrder, {
        ...mockSnapshot,
        durationSeconds: duration || mockSnapshot.durationSeconds,
      });
      setActiveCallSession(null);
      setIsCallMinimized(false);
      pushView("user-order-detail" as any);
    }
  };

  const sendMessage = () => {
    const value = inputValue.trim();
    if (!value) return;
    const time = new Date().toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" });
    setMessages((items) => [...items, { id: `${Date.now()}-me`, sender: "me", text: value, time }]);
    setInputValue("");
    setTimeout(() => {
      setMessages((items) => [...items, { id: `${Date.now()}-other`, sender: "other", text: isCounselorView ? "收到，我们继续。" : "我看到了，我们慢慢聊。", time }]);
    }, 900);
  };

  const enterMeeting = () => {
    if (needsCameraPermission || needsMicrophonePermission) {
      setShowPermissionPrompt(true);
      return;
    }
    setMeetingState("waiting");
  };

  const grantRequestedPermissions = () => {
    const nextPermissions = {
      camera: mediaPermissions.camera || needsCameraPermission,
      microphone: mediaPermissions.microphone || needsMicrophonePermission,
    };
    setMediaPermissions(nextPermissions);
    if (typeof window !== "undefined") window.localStorage.setItem(permissionStorageKey, JSON.stringify(nextPermissions));
    setShowPermissionPrompt(false);
    setMeetingState("waiting");
  };

  useEffect(() => {
    document.body.style.overflow = "hidden";
    return () => {
      document.body.style.overflow = "";
    };
  }, []);

  if (isCallMinimized && meetingState !== "lobby" && meetingState !== "ended") {
    return (
      <motion.button
        drag
        dragConstraints={{ left: 10, right: 300, top: 50, bottom: 700 }}
        onClick={() => setIsCallMinimized(false)}
        aria-label="返回预约会议室"
        className="absolute right-4 top-20 z-[200] h-32 w-24 overflow-hidden rounded-2xl border-2 border-white/20 bg-[#17382d] shadow-2xl"
      >
        <img src={otherAvatar} alt={otherName} className="h-full w-full object-cover opacity-55" />
        <div className="absolute inset-0 flex flex-col items-center justify-end bg-gradient-to-t from-black/80 to-transparent p-2 text-white">
          <span className="text-[10px] font-bold">{meetingState === "waiting" ? "等待加入" : formatTime(duration)}</span>
        </div>
      </motion.button>
    );
  }

  if (meetingState === "lobby") {
    return (
      <div className="absolute inset-0 z-[100] flex flex-col overflow-hidden bg-[#FAF8F5]">
        <div className="flex items-center justify-between px-5 pb-4 pt-12 mt-safe">
          <button onClick={leaveMeeting} aria-label="退出会议室" className="flex h-10 w-10 items-center justify-center rounded-full bg-white text-[#49463D] shadow-sm active:scale-95 transition-transform"><ChevronLeft size={22} /></button>
          <div className="text-center">
            <div className="text-[15px] font-black text-[#1D1B16]">预约咨询会议室</div>
            <div className="mt-0.5 text-[10px] font-bold tracking-wider text-[#7A756C]">{roomNumber}</div>
          </div>
          <div className="flex h-10 w-10 items-center justify-center rounded-full bg-[#EADDFF] text-[#21005D]"><LockKeyhole size={18} /></div>
        </div>

        <div className="flex-1 overflow-y-auto px-5 pb-6">
          <div className="hero-panel mb-4 p-5 rounded-[24px] bg-[#6750A4] shadow-lg relative overflow-hidden">
            <div className="absolute top-0 right-0 w-32 h-32 bg-white/10 rounded-full blur-2xl -mr-10 -mt-10 pointer-events-none"></div>
            <div className="relative z-10 mb-4 flex items-center justify-between">
              <div>
                <div className="text-[11px] font-bold text-white/70">{order?.date || "今天"} · {order?.time || "预约时间"}</div>
                <h1 className="mt-1 text-[22px] font-black text-white">{isVideo ? "视频咨询" : "语音咨询"}</h1>
              </div>
              <CalendarClock size={32} className="text-white/80" />
            </div>
            <div className="relative z-10 flex items-center rounded-[18px] bg-black/20 p-3 backdrop-blur-sm border border-white/10">
              <img src={otherAvatar} alt={otherName} className="mr-3 h-12 w-12 rounded-[14px] border border-white/20 object-cover" />
              <div>
                <div className="text-[14px] font-bold text-white">与 {otherName} 会面</div>
                <div className="mt-0.5 text-[10px] text-white/70">双方进入后才开始计算咨询时长</div>
              </div>
            </div>
          </div>

          <div className="mb-5 flex items-start rounded-[20px] border border-[#EADDFF] bg-[#F6EDFF] p-4">
            <ShieldCheck size={20} className="mr-3 mt-0.5 shrink-0 text-[#6750A4]" />
            <p className="text-[12px] leading-relaxed text-[#21005D] font-medium">会议室仅限本次预约双方进入，通话内容默认不录音、不录像。请确认当前环境安静且私密。</p>
          </div>
          <button onClick={enterMeeting} className="w-full rounded-full bg-[#6750A4] py-4 text-[15px] font-black text-white shadow-lg shadow-[#6750A4]/30 active:scale-95 transition-transform">
            进入预约会议室
          </button>
        </div>

        {/* Permission Prompt Modal */}
        <AnimatePresence>
          {showPermissionPrompt && (
            <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} className="absolute inset-0 z-[200] flex items-end bg-black/40 backdrop-blur-sm" onClick={() => setShowPermissionPrompt(false)}>
              <motion.div initial={{ y: "100%" }} animate={{ y: 0 }} exit={{ y: "100%" }} onClick={(event) => event.stopPropagation()} className="w-full rounded-t-[28px] bg-white p-6 pb-[calc(24px+env(safe-area-inset-bottom))] shadow-2xl relative">
                <button onClick={() => setShowPermissionPrompt(false)} aria-label="关闭" className="absolute right-5 top-5 grid h-9 w-9 place-items-center rounded-full bg-[#FAF8F5] text-[#7A756C] active:bg-[#ECE6DC] transition-colors"><X size={18} /></button>
                <div className="flex gap-3">
                  {needsCameraPermission && <div className="grid h-12 w-12 place-items-center rounded-[16px] bg-[#EADDFF] text-[#21005D]"><VideoIcon size={22} /></div>}
                  {needsMicrophonePermission && <div className="grid h-12 w-12 place-items-center rounded-[16px] bg-[#F3E3DA] text-[#A23F1E]"><Mic size={22} /></div>}
                </div>
                <h2 className="mt-5 text-[20px] font-black text-[#1D1B16]">开启{requestedPermissionLabel}</h2>
                <p className="mt-3 text-[13px] leading-relaxed text-[#7A756C]">用于本次{isVideo ? "视频" : "语音"}咨询，仅在会议中使用，结束后立即停止。拒绝后仍可使用会议内文字聊天。</p>
                <p className="mt-4 rounded-[16px] bg-[#FAF8F5] p-3.5 text-[11px] leading-relaxed text-[#7A756C] border border-[#ECE6DC]">已识别为 {platform}。授权成功后会记住当前状态，下次不再重复提醒；未授权时，下次使用仍会提示。</p>
                <button onClick={grantRequestedPermissions} className="mt-6 h-[52px] w-full rounded-full bg-[#6750A4] text-[15px] font-black text-white shadow-lg shadow-[#6750A4]/30 active:scale-95 transition-transform">继续并授权</button>
                <button onClick={() => setShowPermissionPrompt(false)} className="mt-3 h-12 w-full text-[14px] font-bold text-[#7A756C] active:text-[#1D1B16] transition-colors">暂不开启</button>
              </motion.div>
            </motion.div>
          )}
        </AnimatePresence>
      </div>
    );
  }

  if (meetingState === "ended") {
    return (
      <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className={`${getMeetingLayerClass("ended")} z-[99999] flex h-[100dvh] w-screen flex-col items-center justify-center overflow-y-auto bg-[#FAF8F5] p-7 text-center`}>
        <div className="mb-5 flex h-[88px] w-[88px] items-center justify-center rounded-[28px] bg-[#EADDFF] text-[#21005D] shadow-lg shadow-[#EADDFF]/50"><CheckCircle2 size={44} strokeWidth={2.5} /></div>
        <h1 className="text-[24px] font-black text-[#1D1B16]">本次会议已结束</h1>
        <p className="mt-2 text-[14px] leading-relaxed text-[#7A756C]">双方已离开预约会议室，通话时长 {formatTime(duration)}</p>
        <div className="bg-white border border-[#ECE6DC] rounded-[24px] shadow-sm mt-8 w-full p-5 text-left">
          <div className="flex justify-between border-b border-[#ECE6DC] pb-4 text-[13px]">
            <span className="text-[#7A756C]">会议号</span>
            <span className="font-bold text-[#1D1B16]">{roomNumber}</span>
          </div>
          <div className="flex justify-between pt-4 text-[13px]">
            <span className="text-[#7A756C]">服务状态</span>
            <span className="font-bold text-[#6750A4]">已完成</span>
          </div>
        </div>
        <button 
          onClick={finishAndGoToSummary} 
          className="mt-8 w-full rounded-full bg-[#6750A4] py-4 text-[15px] font-black text-white shadow-lg shadow-[#6750A4]/30 active:scale-95 transition-transform"
        >
          {isCounselorView ? "查看 AI 咨询总结" : "返回预约详情"}
        </button>
      </motion.div>
    );
  }

  // Sub-components for In-Call
  const AudioConsultationView = () => (
    <div className="flex h-full w-full flex-col items-center justify-center bg-[#1D1B16] overflow-hidden relative">
      <div className="absolute top-0 left-0 w-full h-1/2 bg-gradient-to-b from-[#6750A4]/10 to-transparent pointer-events-none"></div>
      <div className="relative flex items-center justify-center mb-12">
        {/* Animated rings for audio visualizer */}
        {[0, 1, 2].map((i) => (
          <motion.div
            key={i}
            animate={{ scale: [1, 1.4, 1], opacity: [0.3, 0, 0.3] }}
            transition={{ duration: 3, repeat: Infinity, delay: i * 1 }}
            className="absolute inset-0 rounded-full border-2 border-[#EADDFF]/20 bg-[#EADDFF]/5"
          />
        ))}
        <img src={otherAvatar} alt={otherName} className="relative z-10 h-36 w-36 rounded-full border-[6px] border-[#1D1B16] object-cover shadow-[0_0_40px_rgba(103,80,164,0.3)]" />
      </div>
      <h2 className="text-[22px] font-black text-white mb-2">{otherName}</h2>
      <p className="text-[14px] text-[#EADDFF] font-medium tracking-widest opacity-80">正在语音咨询中</p>
      <div className="mt-6 flex items-center gap-2 rounded-full bg-white/10 px-3.5 py-1.5 text-[11px] text-white/70 backdrop-blur-md border border-white/10">
        <span className="h-2 w-2 rounded-full bg-emerald-400"></span> 网络质量良好
      </div>
    </div>
  );

  const VideoConsultationView = () => (
    <div className="relative h-full w-full overflow-hidden bg-[#1D1B16]">
      {cameraOff ? (
        <div className="flex h-full flex-col items-center justify-center">
          <img src={otherAvatar} alt={otherName} className="h-36 w-36 rounded-full border-4 border-white/15 object-cover shadow-2xl" />
          <p className="mt-5 text-[14px] font-bold text-white/75">对方视频已关闭 · 当前使用语音分析</p>
        </div>
      ) : (
        <>
          <img src={otherAvatar} alt={`${otherName}的视频画面`} className="h-full w-full scale-110 object-cover blur-[1px]" />
          <div className="absolute inset-0 bg-gradient-to-b from-black/30 via-transparent to-black/50" />
          <div className="absolute bottom-28 left-5 rounded-full bg-black/45 px-4 py-2 text-[13px] font-bold backdrop-blur-md"><span className="mr-2 inline-block h-2 w-2 rounded-full bg-emerald-400" />{otherName}</div>
        </>
      )}
      <div className="absolute right-5 top-36 h-32 w-24 overflow-hidden rounded-[22px] border-2 border-white/15 bg-[#322F35] shadow-xl">
        <img src={selfAvatar} alt="我的画面" className="h-full w-full object-cover" />
      </div>
    </div>
  );

  return (
    <motion.div data-meeting-room initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="fixed inset-0 z-[99999] flex h-[100dvh] flex-col overflow-hidden bg-[#1D1B16] text-white" style={{ position: "fixed", top: 0, left: 0, right: 0, bottom: 0, width: '100vw', height: '100dvh' }}>
      {/* Top Floating Header */}
      <div className="absolute top-0 left-0 right-0 z-20 flex items-center justify-between px-4 pb-4 pt-12 mt-safe bg-gradient-to-b from-black/60 to-transparent pointer-events-none">
        <button onClick={() => setIsCallMinimized(true)} aria-label="最小化会议" className="flex h-10 w-10 items-center justify-center rounded-full bg-white/15 backdrop-blur-md pointer-events-auto active:scale-95 transition-transform"><Minimize2 size={20} /></button>
        <div className="text-center pointer-events-auto">
          <div className="flex items-center rounded-full bg-white/15 backdrop-blur-md px-3 py-1.5 text-[11px] font-bold border border-white/10 shadow-sm">
            <LockKeyhole size={12} className="mr-1.5 text-emerald-400" />预约会议 · {roomNumber}
          </div>
          <div className="mt-2 text-[13px] font-mono text-white/80 drop-shadow-md font-bold tracking-widest">{meetingState === "waiting" ? "1/2 人已入会" : formatTime(duration)}</div>
          {meetingState === "in-call" && isCounselorView && <EmotionStatusChip presentation={emotionPresentation} onOpen={openEmotionDynamics} />}
        </div>
        <button onClick={() => { setNotice("已切换摄像头"); }} aria-label="切换摄像头" className={`flex h-10 w-10 items-center justify-center rounded-full bg-white/15 backdrop-blur-md pointer-events-auto active:scale-95 transition-transform ${isVideo ? "" : "invisible"}`}><SwitchCamera size={20} /></button>
      </div>

      <AnimatePresence>
        {notice && <motion.div initial={{ opacity: 0, y: -10 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0 }} className="absolute left-1/2 top-32 z-50 -translate-x-1/2 rounded-full bg-white/90 px-4 py-2 text-[12px] font-bold text-[#1D1B16] shadow-lg backdrop-blur-md">{notice}</motion.div>}
      </AnimatePresence>

      {/* Main Flex Layout */}
      <div className="relative z-10 flex min-h-0 flex-1 overflow-hidden">
        
        {/* AV View Area */}
        <div className="flex-1 relative flex flex-col transition-all duration-300">
          {roomPresentation.layout === "participant-cards" ? (
            <div className="flex h-full w-full flex-col items-center justify-center px-6">
               <div className="w-full max-w-sm grid grid-rows-2 gap-4 h-[60%]">
                 <div className="relative flex flex-col items-center justify-center overflow-hidden rounded-[32px] border border-[#EADDFF]/20 bg-[#6750A4]/20 backdrop-blur-md shadow-2xl">
                   <img src={selfAvatar} alt={selfName} className="mb-4 h-24 w-24 rounded-[28px] object-cover shadow-lg" />
                   <div className="text-[16px] font-black">{selfName}</div>
                   <div className="mt-1.5 flex items-center text-[12px] font-bold text-[#EADDFF]"><span className="mr-2 h-2 w-2 rounded-full bg-emerald-400 shadow-[0_0_5px_#34d399]" />{selfRole} · 已进入</div>
                 </div>
                 <div className={`relative flex flex-col items-center justify-center overflow-hidden rounded-[32px] border backdrop-blur-md transition-colors ${roomPresentation.otherParticipantJoined ? "border-[#EADDFF]/20 bg-[#6750A4]/20 shadow-2xl" : "border-dashed border-white/20 bg-white/5"}`}>
                   <img src={otherAvatar} alt={otherName} className={`mb-4 h-24 w-24 rounded-[28px] object-cover transition-all ${roomPresentation.otherParticipantJoined ? "shadow-lg" : "opacity-40 grayscale"}`} />
                   <div className={`text-[16px] font-black ${roomPresentation.otherParticipantJoined ? "text-white" : "text-white/60"}`}>{otherName}</div>
                   <div className={`mt-1.5 flex items-center text-[12px] font-bold ${roomPresentation.otherParticipantJoined ? "text-[#EADDFF]" : "text-white/40"}`}>
                     {roomPresentation.otherParticipantJoined && <span className="mr-2 h-2 w-2 rounded-full bg-emerald-400 shadow-[0_0_5px_#34d399]" />}
                     {otherRole} · {roomPresentation.otherParticipantJoined ? "已加入" : "待加入"}
                   </div>
                   {!roomPresentation.otherParticipantJoined && <button onClick={() => setNotice(`已提醒${otherName}加入会议`)} className="mt-5 flex items-center rounded-full bg-white/10 px-5 py-2.5 text-[12px] font-bold text-white/80 active:scale-95 transition-transform"><BellRing size={16} className="mr-2" />提醒对方</button>}
                 </div>
               </div>
            </div>
          ) : roomPresentation.layout === "audio-call" ? (
            <AudioConsultationView />
          ) : (
            <VideoConsultationView />
          )}

          {/* Bottom Control Bar */}
          <div className="absolute bottom-8 left-1/2 flex w-max max-w-[95vw] -translate-x-1/2 items-center justify-center gap-1.5 sm:gap-3 rounded-[28px] bg-black/40 px-3 sm:px-5 py-2.5 sm:py-3 backdrop-blur-2xl border border-white/10 shadow-2xl z-30">
            <button onClick={() => setMuted(!muted)} className={`flex h-[42px] w-[42px] sm:h-[52px] sm:w-[52px] shrink-0 flex-col items-center justify-center rounded-[18px] sm:rounded-[20px] transition-all active:scale-95 ${muted ? "bg-white text-[#1D1B16]" : "bg-white/10 text-white hover:bg-white/20"}`}>
              {muted ? <MicOff size={22} /> : <Mic size={22} />}
            </button>
            {isVideo ? (
              <button onClick={() => setCameraOff(!cameraOff)} className={`flex h-[42px] w-[42px] sm:h-[52px] sm:w-[52px] shrink-0 flex-col items-center justify-center rounded-[18px] sm:rounded-[20px] transition-all active:scale-95 ${cameraOff ? "bg-white text-[#1D1B16]" : "bg-white/10 text-white hover:bg-white/20"}`}>
                {cameraOff ? <VideoOff size={22} /> : <VideoIcon size={22} />}
              </button>
            ) : (
              <button onClick={() => setSpeaker(!speaker)} className={`flex h-[42px] w-[42px] sm:h-[52px] sm:w-[52px] shrink-0 flex-col items-center justify-center rounded-[18px] sm:rounded-[20px] transition-all active:scale-95 ${speaker ? "bg-white text-[#1D1B16]" : "bg-white/10 text-white hover:bg-white/20"}`}>
                <Volume2 size={22} />
              </button>
            )}
            
            {/* Chat Button (First Level) */}
            <button onClick={() => setShowChat(!showChat)} className={`relative flex h-[42px] w-[42px] sm:h-[52px] sm:w-[52px] shrink-0 items-center justify-center rounded-[18px] sm:rounded-[20px] transition-all active:scale-95 ${showChat ? "bg-[#EADDFF] text-[#21005D]" : "bg-white/10 text-white hover:bg-white/20"} shadow-sm`}>
              <MessageSquare size={22} />
              {!showChat && messages.length > 0 && <span className="absolute top-0 right-0 flex h-3 w-3 rounded-full bg-[#D92D20] border-2 border-[#2C2A25]"></span>}
            </button>

            {/* AI Panel Toggle (Highlight) */}
            {meetingState === "in-call" && isCounselorView && (
              <button onClick={() => setAiPanelOpen(!aiPanelOpen)} className={`flex h-[42px] w-[42px] shrink-0 sm:h-[56px] sm:w-[56px] shrink-0 flex-col items-center justify-center rounded-[20px] sm:rounded-[22px] transition-all active:scale-95 ${aiPanelOpen ? "bg-[#EADDFF] text-[#21005D]" : "bg-[#6750A4] text-white shadow-[0_0_20px_rgba(103,80,164,0.6)]"}`}>
                <Sparkles size={22} strokeWidth={2.5} />
              </button>
            )}

            
            {isCounselorView && (
              <button onClick={() => setShowRiskReport(true)} className="flex h-[42px] w-[42px] sm:h-[52px] sm:w-[52px] shrink-0 flex-col items-center justify-center rounded-[18px] sm:rounded-[20px] bg-[#D92D20]/20 text-[#D92D20] border border-[#D92D20]/30 transition-all hover:bg-[#D92D20]/30 active:scale-95 shadow-sm">
                <AlertTriangle size={22} />
              </button>
            )}
<button onClick={meetingState === "waiting" ? leaveMeeting : endMeeting} className="flex h-[42px] w-[42px] sm:h-[52px] sm:w-[52px] shrink-0 flex-col items-center justify-center rounded-[18px] sm:rounded-[20px] bg-red-500 text-white shadow-lg shadow-red-500/30 transition-all hover:bg-red-600 active:scale-95">
              <PhoneOff size={22} />
            </button>
          </div>
        </div>

        {/* AIAssistantPanel Drawer */}
        <AnimatePresence>
          {aiPanelOpen && (
            <>
              {/* Overlay for mobile to dismiss panel */}
              <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} className="absolute inset-0 bg-black/20 z-30 md:hidden" onClick={() => setAiPanelOpen(false)} />
              
              <motion.div initial={{ x: "100%" }} animate={{ x: 0 }} exit={{ x: "100%" }} transition={{ type: "spring", stiffness: 300, damping: 30 }} className="absolute right-0 top-0 bottom-0 z-40 flex w-[85%] max-w-[360px] flex-col overflow-hidden rounded-l-[32px] bg-[#FAF8F5] shadow-[-10px_0_40px_rgba(0,0,0,0.3)]">
                
                {/* Panel Header */}
                <div className="flex items-center justify-between border-b border-[#ECE6DC] bg-white px-5 py-4 pt-12 mt-safe">
                   <div className="flex items-center gap-2 text-[#21005D]">
                     <div className="w-8 h-8 rounded-full bg-[#EADDFF] flex items-center justify-center">
                       <Sparkles size={16} />
                     </div>
                     <span className="font-black text-[16px]">AI 咨询助手</span>
                   </div>
                   <button onClick={() => setAiPanelOpen(false)} className="rounded-full p-2 text-[#7A756C] hover:bg-[#F3E3DA] active:scale-95 transition-colors"><X size={20} /></button>
                </div>
                
                <div className="min-h-0 flex-1 overflow-y-auto overscroll-contain p-4 pb-[calc(16px+env(safe-area-inset-bottom))]" ref={aiScrollRef}>
                  <div className="space-y-5">
                    {isCounselorView && <EmotionDynamicsCard presentation={emotionPresentation} />}

                    {/* Live Transcription */}
                    <div className="rounded-[20px] bg-white border border-[#ECE6DC] p-4 shadow-sm">
                      <div className="mb-3 text-[12px] font-black text-[#7A756C] flex justify-between items-center">
                        <span>实时转录流</span>
                        <div className="flex items-center gap-1"><span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse"></span><span className="text-[10px] font-normal">Recording</span></div>
                      </div>
                      <div className="space-y-4 pr-1">
                        {mockSnapshot.transcript.slice(0, 4).map((segment) => (
                          <div key={segment.id} className="text-[13px] leading-relaxed">
                            <span className={`font-black mr-2 ${segment.speakerRole === "client" ? "text-[#6750A4]" : "text-[#7A756C]"}`}>{segment.speakerRole === "counselor" ? "我" : segment.speakerName}:</span>
                            <span className="text-[#1D1B16]">{segment.text}</span>
                          </div>
                        ))}
                      </div>
                    </div>

                    {/* Scratchpad (Counselor Only) */}
                    {isCounselorView && (
                      <div className="rounded-[20px] border border-[#ECE6DC] bg-white p-4 shadow-sm">
                        <div className="mb-3 flex items-center justify-between text-[12px] font-black text-[#7A756C]">
                          <div className="flex items-center gap-1.5"><FileText size={14} /><span>咨询笔记 (仅自己可见)</span></div>
                          <button className="text-[#6750A4] font-bold text-[11px] bg-[#EADDFF] px-2 py-1 rounded-md flex items-center gap-1"><Sparkles size={10} />AI提取重点</button>
                        </div>
                        <textarea
                          className="w-full resize-none rounded-[16px] bg-[#FAF8F5] border border-[#ECE6DC] p-3 text-[13px] leading-relaxed text-[#1D1B16] outline-none focus:ring-2 focus:ring-[#6750A4]/20 focus:border-[#6750A4] transition-all"
                          rows={8}
                          placeholder="在这里记录临床观察或灵感，支持快捷键..."
                          value={scratchpad}
                          onChange={(event) => setScratchpad(event.target.value)}
                        />
                      </div>
                    )}
                  </div>
                </div>
              </motion.div>
            </>
          )}
        </AnimatePresence>
      </div>

      <AnimatePresence>
        {isCounselorView && emotionPresentation.significantEvent && dismissedEmotionEventId !== emotionPresentation.significantEvent.id && (
          <motion.div initial={{ opacity: 0, y: 12 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: 12 }}>
            <EmotionChangeSnackbar
              event={emotionPresentation.significantEvent}
              onOpen={() => { setDismissedEmotionEventId(emotionPresentation.significantEvent!.id); openEmotionDynamics(); }}
              onDismiss={() => setDismissedEmotionEventId(emotionPresentation.significantEvent!.id)}
            />
          </motion.div>
        )}
      </AnimatePresence>

      

      {/* Risk Report Modal */}
      <AnimatePresence>
        {showRiskReport && (
          <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} className="absolute inset-0 z-[200] bg-black/60 flex items-center justify-center px-5 backdrop-blur-md" onClick={() => setShowRiskReport(false)}>
            <motion.div initial={{ scale: 0.95, opacity: 0 }} animate={{ scale: 1, opacity: 1 }} exit={{ scale: 0.95, opacity: 0 }} className="bg-white rounded-[32px] w-full max-w-sm p-7 shadow-2xl" onClick={e => e.stopPropagation()}>
              <div className="flex items-center gap-2 text-[#D92D20] mb-3">
                <AlertTriangle size={28} strokeWidth={2.5} />
                <h2 className="text-[22px] font-black">危机风险上报</h2>
              </div>
              <p className="text-[13px] text-[#7A756C] mb-6 leading-relaxed">此操作不中断当前通话。上报后将触发平台最高级别的安全干预流程，请如实填写。</p>
              
              <div className="space-y-5">
                 <div>
                   <label className="text-[13px] font-black text-[#1D1B16] block mb-2">判定风险类型</label>
                   <div className="grid grid-cols-2 gap-2">
                     {['自伤风险', '他伤风险', '严重情绪危机', '其他异常'].map(t => (
                       <button key={t} className="bg-[#FAF8F5] border border-[#ECE6DC] py-2.5 rounded-xl text-[13px] font-bold text-[#49463D] active:bg-[#F3E3DA] transition-colors">{t}</button>
                     ))}
                   </div>
                 </div>
                 <div>
                   <label className="text-[13px] font-black text-[#1D1B16] block mb-2">风险事件描述</label>
                   <div className="relative">
                     <textarea className="w-full bg-[#FAF8F5] border border-[#ECE6DC] rounded-xl p-3.5 text-[13px] h-24 outline-none focus:ring-2 focus:ring-[#D92D20]/20 focus:border-[#D92D20] transition-all resize-none" placeholder="描述具体情况..."></textarea>
                     <button className="absolute bottom-2 right-2 bg-white border border-[#ECE6DC] px-2 py-1 rounded-md text-[10px] font-bold text-[#6750A4] shadow-sm flex items-center gap-1"><Sparkles size={10} />导入最近对话</button>
                   </div>
                 </div>
              </div>
              
              <div className="flex gap-3 mt-8">
                <button onClick={() => setShowRiskReport(false)} className="flex-1 py-3.5 bg-[#FAF8F5] text-[#49463D] rounded-full text-[15px] font-black active:scale-95 transition-transform">取消</button>
                <button onClick={() => { setShowRiskReport(false); setNotice("危机风险已上报至平台干预中心"); }} className="flex-1 py-3.5 bg-[#D92D20] text-white rounded-full text-[15px] font-black shadow-lg shadow-[#D92D20]/30 active:scale-95 transition-transform">确认提交上报</button>
              </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Overlay Chat directly on screen */}
      <AnimatePresence>
        {showChat && (
          <motion.div 
            initial={{ opacity: 0, y: 20 }} 
            animate={{ opacity: 1, y: 0 }} 
            exit={{ opacity: 0, y: 20 }} 
            className="absolute bottom-28 left-4 z-[90] flex flex-col justify-end pointer-events-none w-[75%]"
            style={{ maxHeight: '40vh' }}
          >
            <div className="overflow-y-auto space-y-3 pb-2 pointer-events-auto pr-2" style={{ WebkitMaskImage: 'linear-gradient(to bottom, transparent, black 15%)' }}>
              {messages.length === 0 && <div className="text-white/40 text-[12px] font-medium py-2">暂无聊天消息...</div>}
              {messages.map((msg) => (
                <div key={msg.id} className="flex flex-col items-start">
                  <div className="bg-black/40 backdrop-blur-md rounded-2xl rounded-bl-sm px-3.5 py-2 text-[13px] leading-relaxed text-white/90 border border-white/10 shadow-sm inline-block">
                    <span className="font-bold text-[#EADDFF] mr-2">{msg.sender === "me" ? "我" : otherName}:</span>
                    {msg.text}
                  </div>
                </div>
              ))}
            </div>
            <div className="mt-2 pointer-events-auto flex items-center bg-black/50 backdrop-blur-xl rounded-full p-1.5 border border-white/10 shadow-lg">
              <input 
                aria-label="会议消息" 
                value={inputValue} 
                onChange={(e) => setInputValue(e.target.value)} 
                onKeyDown={(e) => e.key === "Enter" && sendMessage()} 
                placeholder="发送消息..." 
                className="flex-1 bg-transparent px-3 text-[13px] text-white outline-none placeholder:text-white/50 font-medium" 
              />
              <button 
                onClick={sendMessage} 
                disabled={!inputValue.trim()} 
                className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-[#6750A4] disabled:opacity-50 transition-opacity"
              >
                <Send size={14} className="ml-0.5" />
              </button>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </motion.div>
  );
}
