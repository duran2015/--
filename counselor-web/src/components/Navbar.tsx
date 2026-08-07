import React from 'react';
import { Bell, PhoneCall, Video } from 'lucide-react';
import { ConsultantProfile } from '../types';

interface NavbarProps {
  consultant: ConsultantProfile;
  onToggleListening: () => void;
  onOpenLiveSession: () => void;
  onOpenNotifications: () => void;
}

export const Navbar: React.FC<NavbarProps> = ({
  consultant,
  onToggleListening,
  onOpenLiveSession,
  onOpenNotifications,
}) => {
  return (
    <header className="sticky top-0 z-30 bg-[#FAF8F5]/95 backdrop-blur-md border-b border-[#ECE6DC] px-4 py-3 transition-all">
      <div className="max-w-md mx-auto flex items-center justify-between gap-3">
        
        {/* Left: Consultant Profile Info */}
        <div className="flex items-center gap-3 min-w-0">
          <div className="relative shrink-0">
            <img
              src={consultant.avatar}
              alt={consultant.name}
              className="w-10 h-10 rounded-full object-cover ring-2 ring-[#6750A4]/20 shadow-2xs"
            />
            <span
              className={`absolute bottom-0 right-0 w-3 h-3 rounded-full border-2 border-[#FAF8F5] bg-emerald-500`}
            />
          </div>

          <div className="min-w-0">
            <div className="flex items-center gap-2">
              <h1 className="font-bold text-base text-[#1D1B16] tracking-tight truncate">
                {consultant.name}
              </h1>
              <span className="text-[10px] font-semibold bg-[#EADDFF] text-[#21005D] px-2 py-0.5 rounded-full shrink-0">
                心理咨询师
              </span>
            </div>
            <p className="text-[11px] text-[#7A756C] truncate mt-0.5">
              目前在班 · 正常预约中
            </p>
          </div>
        </div>

        {/* Right Actions */}
        <div className="flex items-center gap-2 shrink-0">
          
          {/* Quick Listening Toggle Chip */}
          <button
            onClick={onToggleListening}
            className={`flex items-center gap-1.5 px-3 h-9 rounded-full text-xs font-semibold transition active:scale-95 ${
              consultant.isListeningActive
                ? 'bg-[#6750A4] text-white shadow-2xs'
                : 'bg-[#E8E2D5] text-[#49463D] hover:bg-[#DDD7C9]'
            }`}
            title="点击切换接单状态"
          >
            <PhoneCall className="w-3.5 h-3.5" />
            <span>{consultant.isListeningActive ? '接单中' : '休息'}</span>
          </button>

          {/* Notifications */}
          <div className="relative">
            <button
              onClick={onOpenNotifications}
              className="w-9 h-9 flex items-center justify-center rounded-full text-[#49463D] hover:bg-[#E8E2D5] transition active:scale-95"
              title="消息通知"
            >
              <Bell className="w-4 h-4" />
            </button>
            <span className="absolute top-1.5 right-1.5 w-2 h-2 rounded-full bg-[#A23F1E]" />
          </div>

        </div>

      </div>
    </header>
  );
};

