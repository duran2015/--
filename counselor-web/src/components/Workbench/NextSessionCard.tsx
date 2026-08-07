import React, { useState, useEffect } from 'react';
import { Video, Clock, FileText, AlertCircle, Sparkles, MessageCircle, ArrowRight } from 'lucide-react';
import { Order } from '../../types';

interface NextSessionCardProps {
  nextOrder: Order | undefined;
  onEnterRoom: (order: Order) => void;
  onViewClientFile: (order: Order) => void;
  onOpenChat?: (order: Order) => void;
}

export const NextSessionCard: React.FC<NextSessionCardProps> = ({
  nextOrder,
  onEnterRoom,
  onViewClientFile,
  onOpenChat,
}) => {
  // Mock live countdown in seconds (e.g. 18 minutes 42 seconds)
  const [timeLeft, setTimeLeft] = useState<number>(1122);

  useEffect(() => {
    const timer = setInterval(() => {
      setTimeLeft((prev) => (prev > 0 ? prev - 1 : 0));
    }, 1000);
    return () => clearInterval(timer);
  }, []);

  const formatCountdown = (totalSeconds: number) => {
    const minutes = Math.floor(totalSeconds / 60);
    const seconds = totalSeconds % 60;
    return `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
  };

  if (!nextOrder) {
    return (
      <div className="bg-white border border-[#E5E0D5] rounded-[32px] p-8 text-center text-[#8C877E]">
        <Clock className="w-8 h-8 text-[#5A6A50] mx-auto mb-2 opacity-60" />
        <h3 className="font-serif font-medium text-base text-[#4A5344]">今日暂无即将开始的预约</h3>
        <p className="text-xs text-[#8C877E] mt-1">排班表正常开放中，您可以提前编写历史小结或在个人中心调整预约时段。</p>
      </div>
    );
  }

  return (
    <div className="bg-white border border-[#E6E0D6] rounded-[24px] p-5 shadow-xs relative overflow-hidden transition-all">
      
      {/* Header: M3 Badge and Countdown Assist Chip */}
      <div className="flex items-center justify-between gap-2 mb-4">
        <div className="flex items-center gap-2">
          <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-semibold bg-[#6750A4] text-white shadow-2xs">
            <span className="w-2 h-2 rounded-full bg-emerald-300 animate-pulse" />
            下一个预约
          </span>
          <span className="text-xs text-[#49463D] bg-[#F5F2EC] px-2.5 py-1 rounded-md font-mono font-medium border border-[#E6E0D6]">
            {nextOrder.bookingTimeSlot}
          </span>
        </div>

        <div className="flex items-center gap-1.5 text-xs font-semibold text-[#A23F1E] bg-[#FAF2ED] px-3 py-1 rounded-full border border-[#F3E3DA]">
          <Clock className="w-3.5 h-3.5" />
          <span>倒计时: <strong className="font-mono text-sm">{formatCountdown(timeLeft)}</strong></span>
        </div>
      </div>

      {/* Main Content Area */}
      <div className="space-y-4">
        
        {/* Client Brief */}
        <div className="flex items-start justify-between gap-3 bg-[#FAF8F5] p-3.5 rounded-[18px] border border-[#ECE6DC]">
          <div className="flex items-center gap-3">
            <div className="relative">
              <img
                src={nextOrder.clientAvatar}
                alt={nextOrder.clientName}
                className="w-12 h-12 rounded-full object-cover ring-1 ring-[#386A20]/20"
              />
              <span className="absolute -bottom-1 -right-1 bg-[#6750A4] text-white text-[9px] font-bold px-1 py-0.2 rounded-md">
                第4次
              </span>
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h2 className="text-sm font-bold text-[#1D1B16]">{nextOrder.clientName}</h2>
                <span className="text-[10px] bg-[#EADDFF] text-[#21005D] px-1.5 py-0.2 rounded-md font-medium">
                  {nextOrder.serviceTypeName}
                </span>
              </div>
              <p className="text-[11px] text-[#49463D] mt-1 line-clamp-1">
                {nextOrder.complaintTopic}
              </p>
            </div>
          </div>
          
          <button
            onClick={() => onViewClientFile(nextOrder)}
            className="shrink-0 text-[#6750A4] text-[10px] font-bold bg-[#E8E2D5] hover:bg-[#D5CEBC] px-2 py-1 rounded-full transition"
          >
            查阅档案
          </button>
        </div>

        {/* Action Buttons */}
        <div className="flex gap-2">
          <button
            onClick={() => onEnterRoom(nextOrder)}
            className="flex-1 flex items-center justify-center gap-2 bg-[#6750A4] text-white py-3 px-4 rounded-[16px] font-bold text-xs hover:bg-[#594294] shadow-xs active:scale-[0.98] transition"
          >
            <Video className="w-4 h-4 text-emerald-200" />
            <span>进入咨询室</span>
          </button>

          <button
            onClick={() => onOpenChat && onOpenChat(nextOrder)}
            className="w-12 flex items-center justify-center bg-[#FAF8F5] text-[#1D1B16] border border-[#E6E0D6] rounded-[16px] hover:bg-[#E8E2D5] active:scale-[0.98] transition"
            title="私信沟通"
          >
            <MessageCircle className="w-5 h-5 text-[#6750A4]" />
          </button>
        </div>
      </div>
    </div>
  );
};
