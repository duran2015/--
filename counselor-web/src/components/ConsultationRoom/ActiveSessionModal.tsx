import React, { useState, useEffect } from 'react';
import { 
  Video, Mic, MicOff, VideoOff, PhoneOff, MessageSquare, Sparkles, 
  Clock, Shield, Heart, FileText, Send, AlertCircle, X, ChevronRight 
} from 'lucide-react';
import { Order } from '../../types';

interface ActiveSessionModalProps {
  order: Order;
  onClose: () => void;
  onFinishSessionAndSummary: (order: Order, scratchpadNotes: string) => void;
}

interface ChatMessage {
  id: string;
  sender: 'consultant' | 'client';
  text: string;
  time: string;
}

export const ActiveSessionModal: React.FC<ActiveSessionModalProps> = ({
  order,
  onClose,
  onFinishSessionAndSummary,
}) => {
  const [secondsRemaining, setSecondsRemaining] = useState<number>(50 * 60 - 460); // ~42:20 left
  const [isMuted, setIsMuted] = useState<boolean>(false);
  const [isVideoOn, setIsVideoOn] = useState<boolean>(true);
  const [scratchpad, setScratchpad] = useState<string>(
    '来访者提到最近在做职业决策时经常出现心率加快、肩颈紧绷。上周练习腹式呼吸后，睡眠改善至5小时。'
  );
  const [moodIndex, setMoodIndex] = useState<number>(order.preMoodScore || 7);

  // Quick Chat feed
  const [messages, setMessages] = useState<ChatMessage[]>([
    { id: '1', sender: 'client', text: '林老师你好，我刚刚到了极简咨询室，声音很清晰。', time: '10:30' },
    { id: '2', sender: 'consultant', text: '你好海燕，欢迎来到我们的安全空间。今天感觉怎么样？', time: '10:30' },
    { id: '3', sender: 'client', text: '上周做完呼吸练习之后好了一点，但昨天开完组会又有点发紧...', time: '10:32' },
  ]);
  const [inputText, setInputText] = useState<string>('');

  useEffect(() => {
    const timer = setInterval(() => {
      setSecondsRemaining((prev) => (prev > 0 ? prev - 1 : 0));
    }, 1000);
    return () => clearInterval(timer);
  }, []);

  const formatTimer = (totalSec: number) => {
    const m = Math.floor(totalSec / 60);
    const s = totalSec % 60;
    return `${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
  };

  const sendQuickChip = (chipText: string) => {
    const newMsg: ChatMessage = {
      id: Date.now().toString(),
      sender: 'consultant',
      text: chipText,
      time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
    };
    setMessages((prev) => [...prev, newMsg]);
  };

  const handleSendMessage = (e: React.FormEvent) => {
    e.preventDefault();
    if (!inputText.trim()) return;
    sendQuickChip(inputText);
    setInputText('');
  };

  return (
    <div className="fixed inset-0 z-50 bg-[#1D1B16]/95 backdrop-blur-md flex flex-col p-3 sm:p-5 text-[#FAF8F5] animate-in fade-in duration-200">
      
      {/* Top Session Header - M3 Surface */}
      <div className="bg-[#2E312B] border border-[#49463D] rounded-[24px] p-3.5 flex items-center justify-between gap-3 shadow-sm shrink-0">
        <div className="flex items-center gap-3 min-w-0">
          <img
            src={order.clientAvatar}
            alt={order.clientName}
            className="w-10 h-10 rounded-full object-cover ring-2 ring-[#D0BCFF]/30 shrink-0"
          />
          <div className="min-w-0">
            <div className="flex items-center gap-2">
              <h2 className="font-bold text-sm text-white truncate">{order.clientName}</h2>
              <span className="text-[10px] bg-[#386A20] text-emerald-100 px-2 py-0.2 rounded-full font-mono shrink-0">
                {order.serviceTypeName}
              </span>
            </div>
            <p className="text-[11px] text-[#C9C6BD] truncate mt-0.5">{order.complaintTopic}</p>
          </div>
        </div>

        {/* Timer & Close */}
        <div className="flex items-center gap-2 shrink-0">
          <div className="flex items-center gap-1.5 bg-[#1B1E19] px-3 py-1 rounded-full border border-[#386A20]/40 text-xs font-mono font-bold text-emerald-200">
            <Clock className="w-3.5 h-3.5 animate-pulse text-emerald-300" />
            <span>{formatTimer(secondsRemaining)}</span>
          </div>

          <button
            onClick={onClose}
            className="p-1.5 rounded-full text-stone-300 hover:text-white hover:bg-white/10 transition active:scale-95"
            title="退出"
          >
            <X className="w-5 h-5" />
          </button>
        </div>
      </div>

      {/* Main Grid: Live Video Canvas + Instant Scratchpad & Chat */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-3 mt-3 flex-1 min-h-0">
        
        {/* Left: Video / Audio Stream View */}
        <div className="lg:col-span-7 bg-[#2E312B] border border-[#49463D] rounded-[24px] relative overflow-hidden flex flex-col p-3.5 shadow-md">
          
          {/* Main Client Video Stream Container */}
          <div className="relative w-full flex-1 min-h-[240px] rounded-[18px] overflow-hidden bg-[#1B1E19] flex items-center justify-center">
            {isVideoOn ? (
              <img
                src={order.clientAvatar}
                alt="Client Video Stream"
                className="w-full h-full object-cover filter brightness-95 contrast-105"
              />
            ) : (
              <div className="text-center p-6 space-y-2">
                <div className="w-16 h-16 rounded-full bg-[#386A20]/30 mx-auto flex items-center justify-center ring-4 ring-[#386A20]/20">
                  <Heart className="w-7 h-7 text-emerald-300 animate-pulse" />
                </div>
                <div className="text-xs font-bold text-emerald-100">高质语音倾听模式</div>
                <div className="text-[11px] text-[#C9C6BD]">24bit 高保真安全加密传输</div>
              </div>
            )}

            {/* Audio Wave Visualizer Bar */}
            <div className="absolute bottom-3 left-3 bg-black/70 backdrop-blur-md px-3 py-1 rounded-full flex items-center gap-2 text-[11px] text-emerald-200 border border-white/10">
              <span className="w-2 h-2 rounded-full bg-emerald-400 animate-ping" />
              <span>延迟 42ms</span>
            </div>

            {/* Counselor PIP Overlay */}
            <div className="absolute top-3 right-3 w-24 h-16 rounded-[14px] overflow-hidden border-2 border-white/20 bg-stone-900 shadow-md">
              <img
                src="https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=200&auto=format&fit=crop&q=80"
                alt="Consultant Self"
                className="w-full h-full object-cover"
              />
            </div>
          </div>

          {/* Media Control Bar */}
          <div className="flex items-center justify-center gap-2.5 pt-3 shrink-0">
            <button
              onClick={() => setIsMuted(!isMuted)}
              className={`p-3 rounded-full transition shadow-sm active:scale-95 ${
                isMuted ? 'bg-rose-600 text-white' : 'bg-white/10 text-white hover:bg-white/20'
              }`}
            >
              {isMuted ? <MicOff className="w-4 h-4" /> : <Mic className="w-4 h-4" />}
            </button>

            <button
              onClick={() => setIsVideoOn(!isVideoOn)}
              className={`p-3 rounded-full transition shadow-sm active:scale-95 ${
                !isVideoOn ? 'bg-amber-600 text-white' : 'bg-white/10 text-white hover:bg-white/20'
              }`}
            >
              {!isVideoOn ? <VideoOff className="w-4 h-4" /> : <Video className="w-4 h-4" />}
            </button>

            <button
              onClick={() => onFinishSessionAndSummary(order, scratchpad)}
              className="px-5 py-2.5 rounded-full bg-[#6750A4] text-white text-xs font-bold hover:bg-[#594294] transition shadow-md flex items-center gap-1.5 active:scale-95"
            >
              <Sparkles className="w-4 h-4 text-emerald-200" />
              <span>完成咨询 & AI 结案小结</span>
            </button>
          </div>

        </div>

        {/* Right: Instant Scratchpad & Empathetic Chat */}
        <div className="lg:col-span-5 flex flex-col gap-3 min-h-0">
          
          {/* Scratchpad */}
          <div className="bg-[#2E312B] border border-[#49463D] rounded-[24px] p-4 shrink-0 flex flex-col gap-2">
            <div className="flex items-center justify-between text-xs">
              <span className="font-bold text-emerald-200 flex items-center gap-1.5">
                <FileText className="w-3.5 h-3.5 text-[#A23F1E]" />
                即时随手记 (Scratchpad)
              </span>
              <div className="flex items-center gap-1.5 text-[11px]">
                <span className="text-[#C9C6BD]">焦虑值:</span>
                <select
                  value={moodIndex}
                  onChange={(e) => setMoodIndex(Number(e.target.value))}
                  className="bg-[#1B1E19] border border-[#386A20]/50 text-emerald-200 rounded-full px-2.5 py-0.5 text-[11px]"
                >
                  {[10, 9, 8, 7, 6, 5, 4, 3, 2, 1].map((val) => (
                    <option key={val} value={val}>{val}/10</option>
                  ))}
                </select>
              </div>
            </div>

            <textarea
              rows={2}
              value={scratchpad}
              onChange={(e) => setScratchpad(e.target.value)}
              placeholder="在此记录会谈随想笔记..."
              className="w-full bg-[#1B1E19] border border-[#386A20]/30 rounded-[14px] p-2.5 text-xs text-emerald-100 placeholder-stone-500 focus:outline-hidden focus:ring-1 focus:ring-[#386A20]"
            />
          </div>

          {/* Empathetic Assistant Chips & Chat Timeline */}
          <div className="bg-[#2E312B] border border-[#49463D] rounded-[24px] p-4 flex-1 flex flex-col justify-between min-h-0">
            
            {/* Quick Empathetic Response Chips */}
            <div className="space-y-1.5 mb-2 shrink-0">
              <div className="text-[10px] text-[#C9C6BD] flex items-center gap-1">
                <Sparkles className="w-3 h-3 text-amber-300" />
                <span>共情辅助话术:</span>
              </div>
              <div className="flex flex-wrap gap-1">
                <button
                  onClick={() => sendQuickChip('“听起来当时那个时刻，你感到被误解了...”')}
                  className="text-[10px] bg-[#386A20]/40 text-emerald-100 border border-[#386A20]/50 px-2.5 py-0.5 rounded-full hover:bg-[#386A20] transition active:scale-95"
                >
                  无条件共情
                </button>
                <button
                  onClick={() => sendQuickChip('“我们现在一起做 3 次 4-7-8 深呼吸...”')}
                  className="text-[10px] bg-[#386A20]/40 text-emerald-100 border border-[#386A20]/50 px-2.5 py-0.5 rounded-full hover:bg-[#386A20] transition active:scale-95"
                >
                  深呼吸引导
                </button>
                <button
                  onClick={() => sendQuickChip('“如果给这种失控感打分，现在是多少？”')}
                  className="text-[10px] bg-[#386A20]/40 text-emerald-100 border border-[#386A20]/50 px-2.5 py-0.5 rounded-full hover:bg-[#386A20] transition active:scale-95"
                >
                  情绪打分
                </button>
              </div>
            </div>

            {/* Chat Messages */}
            <div className="flex-1 overflow-y-auto space-y-2 pr-1 my-2 text-xs scrollbar-thin">
              {messages.map((m) => (
                <div
                  key={m.id}
                  className={`flex flex-col ${m.sender === 'consultant' ? 'items-end' : 'items-start'}`}
                >
                  <div
                    className={`p-2.5 rounded-[14px] max-w-[85%] leading-relaxed ${
                      m.sender === 'consultant'
                        ? 'bg-[#6750A4] text-white rounded-br-xs'
                        : 'bg-[#1B1E19] text-[#FAF8F5] border border-[#49463D] rounded-bl-xs'
                    }`}
                  >
                    {m.text}
                  </div>
                  <span className="text-[9px] text-[#C9C6BD] mt-0.5">{m.time}</span>
                </div>
              ))}
            </div>

            {/* Input Bar */}
            <form onSubmit={handleSendMessage} className="flex items-center gap-1.5 pt-2 border-t border-[#49463D] shrink-0">
              <input
                type="text"
                placeholder="发送文字疏导短句..."
                value={inputText}
                onChange={(e) => setInputText(e.target.value)}
                className="flex-1 bg-[#1B1E19] border border-[#386A20]/40 rounded-full px-3.5 py-1.5 text-xs text-white focus:outline-hidden focus:ring-1 focus:ring-[#386A20]"
              />
              <button
                type="submit"
                className="p-2 rounded-full bg-[#6750A4] text-white hover:bg-[#594294] transition active:scale-95"
              >
                <Send className="w-3.5 h-3.5" />
              </button>
            </form>

          </div>

        </div>

      </div>

    </div>
  );
};
