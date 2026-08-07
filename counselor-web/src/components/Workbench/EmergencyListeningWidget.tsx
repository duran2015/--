import React from 'react';
import { PhoneCall, ShieldCheck, Users, ToggleLeft, ToggleRight, Zap } from 'lucide-react';
import { ConsultantProfile } from '../../types';

interface EmergencyListeningWidgetProps {
  consultant: ConsultantProfile;
  onToggleListening: () => void;
  onStartInstantSession: () => void;
}

export const EmergencyListeningWidget: React.FC<EmergencyListeningWidgetProps> = ({
  consultant,
  onToggleListening,
  onStartInstantSession,
}) => {
  return (
    <div className="bg-white border border-[#E6E0D6] rounded-[24px] p-5 shadow-xs relative overflow-hidden transition-all">
      
      {/* M3 Card Header */}
      <div className="flex items-center justify-between mb-3">
        <div className="flex items-center gap-2">
          <div className="w-8 h-8 rounded-full bg-[#FAF2ED] text-[#A23F1E] flex items-center justify-center">
            <Zap className="w-4 h-4" />
          </div>
          <div>
            <h3 className="font-bold text-sm text-[#1D1B16]">急诊与即时倾听通道</h3>
            <p className="text-[11px] text-[#7A756C]">优先分发突发情绪求助订单</p>
          </div>
        </div>

        <button
          onClick={onToggleListening}
          className="p-1 rounded-full transition active:scale-95"
          title="开启/关闭接单"
        >
          {consultant.isListeningActive ? (
            <ToggleRight className="w-9 h-9 text-[#6750A4]" />
          ) : (
            <ToggleLeft className="w-9 h-9 text-stone-300" />
          )}
        </button>
      </div>

      {/* M3 Status Container */}
      <div className="bg-[#FAF8F5] rounded-[18px] p-3.5 border border-[#ECE6DC] flex items-center justify-between my-2">
        <div className="flex items-center gap-2.5">
          <span
            className={`w-3 h-3 rounded-full ${
              consultant.isListeningActive ? 'bg-emerald-500 animate-pulse' : 'bg-stone-300'
            }`}
          />
          <div>
            <div className="text-xs font-semibold text-[#1D1B16]">
              {consultant.isListeningActive ? '倾听通道：即时接单中 (候诊 1 人)' : '倾听通道：已休息'}
            </div>
            <div className="text-[10px] text-[#7A756C] mt-0.5">
              {consultant.isListeningActive ? '优先推送客户端首页极速连线大厅' : '点击右上角开关即可开通极速倾听'}
            </div>
          </div>
        </div>

        {consultant.isListeningActive && (
          <button
            onClick={onStartInstantSession}
            className="px-3.5 py-1.5 rounded-full bg-[#A23F1E] text-white font-semibold text-xs hover:bg-[#883216] shadow-2xs transition active:scale-95"
          >
            接入
          </button>
        )}
      </div>

      {/* M3 Card Footer */}
      <div className="flex items-center justify-between text-[11px] text-[#7A756C] pt-2 border-t border-[#ECE6DC] mt-2">
        <span className="flex items-center gap-1">
          <ShieldCheck className="w-3.5 h-3.5 text-[#6750A4]" />
          高清加密音频通道
        </span>
        <span className="flex items-center gap-1 font-medium text-[#1D1B16]">
          <Users className="w-3.5 h-3.5 text-[#A23F1E]" />
          今日已接: 3单
        </span>
      </div>

    </div>
  );
};

