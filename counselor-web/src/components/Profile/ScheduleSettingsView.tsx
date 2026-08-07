import React, { useState } from 'react';
import { CalendarDays, Clock, Settings, ArrowLeft, Plus, Check, Play, Pause, Info, X, Briefcase, Video, Mic, AlertCircle } from 'lucide-react';
import { ConsultantAvailability, ConsultantService, ConsultantBookingRule, ServiceProduct } from '../../types';

interface ScheduleSettingsViewProps {
  onBack: () => void;
  rule: ConsultantBookingRule;
  onRuleChange: (newRule: ConsultantBookingRule) => void;
  products?: ServiceProduct[];
  isMockEmpty?: boolean;
  onScheduleConfigured?: () => void;
}

const MOCK_AVAILABILITIES: ConsultantAvailability[] = [
  { id: '1', weekday: 1, startTime: '09:00', endTime: '12:00', status: 'active' },
  { id: '2', weekday: 1, startTime: '14:00', endTime: '17:00', status: 'active' },
  { id: '3', weekday: 3, startTime: '19:00', endTime: '22:00', status: 'active' },
];

const MOCK_SERVICES: ConsultantService[] = [
  { id: 's1', name: '深度咨询', type: 'video', duration: 60, price: 599, description: '全面深度的心理探索与干预。', status: 'active' },
  { id: 's2', name: '情绪支持', type: 'audio', duration: 30, price: 199, description: '适合近期压力较大，希望获得情绪支持的人群。', status: 'active' },
  { id: 's3', name: '极简倾听', type: 'audio', duration: 15, price: 59, description: '碎片化时间的情绪疏导与快速倾听。', status: 'active' },
];

export const MOCK_RULE: ConsultantBookingRule = {
  minDuration: 30,
  bufferTime: 15,
  advanceTime: 2,
  cancelRule: 12,
  fragmentMode: 'standard',
};

const WEEKDAYS = ['星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'];

export const ScheduleSettingsView: React.FC<ScheduleSettingsViewProps> = ({ onBack, rule, onRuleChange, isMockEmpty, onScheduleConfigured }) => {
  const [activeTab, setActiveTab] = useState<'availability' | 'rules'>('availability');
  
  // States
  const [availabilities, setAvailabilities] = useState(isMockEmpty ? [] : MOCK_AVAILABILITIES);
  
  // Add Time Modal State
  const [showAddModal, setShowAddModal] = useState(false);
  const [newWeekday, setNewWeekday] = useState(1);
  const [newStartTime, setNewStartTime] = useState('09:00');
  const [newEndTime, setNewEndTime] = useState('12:00');
  
  // Single Adjustment State
  const [todayClosed, setTodayClosed] = useState(false);

  const deleteAvailability = (id: string) => {
    setAvailabilities(availabilities.filter(a => a.id !== id));
  };

  const handleAddTime = () => {
    const newAvail: ConsultantAvailability = {
      id: `avail_${Date.now()}`,
      weekday: newWeekday,
      startTime: newStartTime,
      endTime: newEndTime,
      status: 'active'
    };
    // 排序逻辑：按星期、然后按开始时间排序
    const updated = [...availabilities, newAvail].sort((a, b) => {
      if (a.weekday !== b.weekday) return a.weekday - b.weekday;
      return a.startTime.localeCompare(b.startTime);
    });
    setAvailabilities(updated);
    setShowAddModal(false);
    onScheduleConfigured?.();
  };

  return (
    <div className="space-y-4 animate-in fade-in duration-200 pb-10">
      <div className="flex items-center gap-2">
        <button
          onClick={onBack}
          className="p-1.5 -ml-1.5 rounded-full text-[#6750A4] hover:bg-[#E8E2D5] transition active:scale-95 flex items-center gap-1 font-semibold text-xs"
        >
          <ArrowLeft className="w-4 h-4" />
          <span>返回</span>
        </button>
        <span className="text-[#ECE6DC]">/</span>
        <span className="text-xs font-bold text-[#1D1B16]">排班设置</span>
      </div>

      <div className="bg-white border border-[#E6E0D6] rounded-[24px] shadow-2xs overflow-hidden flex flex-col h-[calc(100vh-140px)]">
        
        {/* Header Tabs */}
        <div className="flex items-center border-b border-[#ECE6DC] bg-[#FAF8F5]">
          <button 
            onClick={() => setActiveTab('availability')}
            className={`flex-1 py-3.5 text-[13px] font-bold transition flex items-center justify-center gap-1.5 ${activeTab === 'availability' ? 'text-[#6750A4] border-b-2 border-[#6750A4] bg-white' : 'text-[#7A756C] hover:text-[#1D1B16]'}`}
          >
            <Clock className="w-4 h-4" /> 可服务时间
          </button>
          <button 
            onClick={() => setActiveTab('rules')}
            className={`flex-1 py-3.5 text-[13px] font-bold transition flex items-center justify-center gap-1.5 ${activeTab === 'rules' ? 'text-[#6750A4] border-b-2 border-[#6750A4] bg-white' : 'text-[#7A756C] hover:text-[#1D1B16]'}`}
          >
            <Settings className="w-4 h-4" /> 预约规则
          </button>
        </div>

        <div className="flex-1 overflow-y-auto p-4 sm:p-5">
          {/* TAB 1: 可服务时间 */}
          {activeTab === 'availability' && (
            <div className="space-y-5 animate-in fade-in">
              <div className="bg-[#FAF8F5] p-3.5 rounded-[16px] border border-[#ECE6DC] flex items-start gap-2.5">
                <Info className="w-4 h-4 text-[#6750A4] shrink-0 mt-0.5" />
                <div className="text-xs text-[#49463D] leading-relaxed">
                  <span className="font-bold text-[#1D1B16]">设置你的工作时间窗口</span><br/>
                  系统会根据你提供的服务时长自动生成用户可预约时间，禁止使用传统固定号源模式。
                </div>
              </div>

              <div className="space-y-4">
                <div className="flex items-center justify-between">
                  <h3 className="font-bold text-[#1D1B16] text-sm">周循环模板</h3>
                  <button onClick={() => setShowAddModal(true)} className="flex items-center gap-1 text-[#6750A4] text-xs font-bold bg-[#6750A4]/10 px-2.5 py-1 rounded-full active:scale-95">
                    <Plus className="w-3.5 h-3.5" /> 添加时间
                  </button>
                </div>

                <div className="space-y-2.5">
                  {availabilities.length === 0 && (
                    <div className="text-center py-10 bg-[#FAF8F5] border border-[#ECE6DC] rounded-[24px]">
                      <p className="text-[14px] text-[#1D1B16] font-bold mb-1">您还没有配置可服务时间</p>
                      <p className="text-[12px] text-[#7A756C]">点击右上角 "+" 号添加您的工作时间段</p>
                    </div>
                  )}
                  {WEEKDAYS.map((day, idx) => {
                    const dayNum = idx + 1;
                    const daySlots = availabilities.filter(a => a.weekday === dayNum);
                    
                    return (
                      <div key={dayNum} className="border border-[#ECE6DC] rounded-[16px] p-3 flex flex-col sm:flex-row sm:items-start gap-3 bg-white">
                        <div className="font-bold text-xs text-[#1D1B16] w-14 shrink-0 mt-1">{day}</div>
                        <div className="flex-1 space-y-1.5">
                          {daySlots.length > 0 ? (
                            daySlots.map(slot => (
                              <div key={slot.id} className="flex items-center justify-between bg-[#FAF8F5] px-3 py-1.5 rounded-full border border-[#ECE6DC] text-xs">
                                <span className="font-mono font-medium text-[#49463D]">{slot.startTime} - {slot.endTime}</span>
                                <button onClick={() => deleteAvailability(slot.id)} className="text-[#7A756C] hover:text-[#A23F1E]">
                                  <X className="w-3.5 h-3.5" />
                                </button>
                              </div>
                            ))
                          ) : (
                            <div className="text-xs text-[#A23F1E] font-medium bg-[#A23F1E]/5 px-3 py-1.5 rounded-full inline-block border border-[#A23F1E]/10">休息</div>
                          )}
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>

              <div className="h-px bg-[#ECE6DC]" />

              <div className="space-y-3">
                <h3 className="font-bold text-[#1D1B16] text-sm">单次/临时调整</h3>
                <div className="border border-[#ECE6DC] rounded-[16px] p-3.5 bg-white space-y-2">
                  <div className="flex items-center justify-between">
                    <div className="font-bold text-xs text-[#1D1B16]">关闭今天预约</div>
                    <button 
                      onClick={() => {
                        if (!todayClosed) {
                          const confirmClose = window.confirm("关闭后今天将不再接收新预约。\n若该时间段已有预约，系统将保持原有订单，请在日历中妥善处理。\n\n确定要关闭今天的预约吗？");
                          if (confirmClose) setTodayClosed(true);
                        } else {
                          setTodayClosed(false);
                        }
                      }}
                      className={`w-11 h-6 rounded-full relative transition ${todayClosed ? 'bg-[#A23F1E]' : 'bg-[#E6E0D6]'}`}
                    >
                      <div className={`w-5 h-5 bg-white rounded-full absolute top-0.5 transition-transform ${todayClosed ? 'translate-x-[22px]' : 'translate-x-0.5'}`} />
                    </button>
                  </div>
                  <p className="text-[11px] text-[#7A756C]">如有已有预约，调整时将提示“该时间已有预约，无法关闭”，需优先妥善处理。</p>
                </div>
              </div>
            </div>
          )}

          {/* TAB 3: 预约规则 */}
          {activeTab === 'rules' && (
            <div className="space-y-5 animate-in fade-in">
              <div className="space-y-4">
                <div className="bg-white border border-[#ECE6DC] rounded-[20px] p-4 space-y-4">
                  
                  {/* Rule 1 */}
                  <div>
                    <label className="flex items-center justify-between text-xs font-bold text-[#1D1B16] mb-2">
                      <span>最小预约时长</span>
                      <span className="text-[#6750A4]">{rule.minDuration} 分钟起</span>
                    </label>
                    <div className="flex gap-2">
                      {[15, 30, 45, 60].map(val => (
                        <button key={val} onClick={() => onRuleChange({...rule, minDuration: val as any})} className={`flex-1 py-1.5 rounded-full border text-xs font-medium transition ${rule.minDuration === val ? 'bg-[#6750A4] text-white border-[#6750A4]' : 'bg-[#FAF8F5] text-[#49463D] border-[#ECE6DC]'}`}>
                          {val}m
                        </button>
                      ))}
                    </div>
                  </div>

                  <div className="h-px bg-[#ECE6DC]" />

                  {/* Rule 2 */}
                  <div>
                    <label className="flex items-center justify-between text-xs font-bold text-[#1D1B16] mb-2">
                      <span>咨询间隔时间 (自动预留休息)</span>
                      <span className="text-[#6750A4]">{rule.bufferTime} 分钟</span>
                    </label>
                    <div className="flex gap-2">
                      {[0, 10, 15, 30].map(val => (
                        <button key={val} onClick={() => onRuleChange({...rule, bufferTime: val})} className={`flex-1 py-1.5 rounded-full border text-xs font-medium transition ${rule.bufferTime === val ? 'bg-[#6750A4] text-white border-[#6750A4]' : 'bg-[#FAF8F5] text-[#49463D] border-[#ECE6DC]'}`}>
                          {val}m
                        </button>
                      ))}
                    </div>
                  </div>

                  <div className="h-px bg-[#ECE6DC]" />

                  {/* Rule 3 & 4 */}
                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <label className="block text-xs font-bold text-[#1D1B16] mb-1.5">提前预约时间</label>
                      <select value={rule.advanceTime} onChange={(e) => onRuleChange({...rule, advanceTime: Number(e.target.value)})} className="w-full bg-[#FAF8F5] border border-[#ECE6DC] rounded-[12px] px-3 py-2 text-xs text-[#1D1B16] outline-none">
                        <option value={1}>至少提前 1 小时</option>
                        <option value={2}>至少提前 2 小时</option>
                        <option value={12}>至少提前 12 小时</option>
                        <option value={24}>至少提前 24 小时</option>
                      </select>
                    </div>
                    <div>
                      <label className="block text-xs font-bold text-[#1D1B16] mb-1.5">无责取消规则</label>
                      <select value={rule.cancelRule} onChange={(e) => onRuleChange({...rule, cancelRule: Number(e.target.value)})} className="w-full bg-[#FAF8F5] border border-[#ECE6DC] rounded-[12px] px-3 py-2 text-xs text-[#1D1B16] outline-none">
                        <option value={12}>开诊前 12 小时</option>
                        <option value={24}>开诊前 24 小时</option>
                        <option value={48}>开诊前 48 小时</option>
                      </select>
                    </div>
                  </div>
                </div>

                {/* Fragmentation Strategy */}
                <div className="bg-white border border-[#ECE6DC] rounded-[20px] p-4 space-y-3">
                  <div className="flex items-center gap-1.5 mb-1">
                    <AlertCircle className="w-4 h-4 text-[#A23F1E]" />
                    <h3 className="font-bold text-[#1D1B16] text-sm">碎片时间策略</h3>
                  </div>
                  <p className="text-[11px] text-[#7A756C] leading-relaxed">系统如何处理被小订单切割的时间碎片，控制服务节奏。</p>
                  
                  <div className="space-y-2">
                    <button onClick={() => onRuleChange({...rule, fragmentMode: 'flexible'})} className={`w-full text-left p-3 rounded-[16px] border transition ${rule.fragmentMode === 'flexible' ? 'bg-[#6750A4]/5 border-[#6750A4] ring-1 ring-[#6750A4]' : 'bg-[#FAF8F5] border-[#ECE6DC]'}`}>
                      <div className="font-bold text-xs text-[#1D1B16] mb-0.5 flex items-center justify-between">
                        <span>灵活接单模式</span>
                        {rule.fragmentMode === 'flexible' && <Check className="w-3.5 h-3.5 text-[#6750A4]" />}
                      </div>
                      <div className="text-[10px] text-[#7A756C]">允许 15 分钟连续短订单，适合新人或倾听服务。</div>
                    </button>

                    <button onClick={() => onRuleChange({...rule, fragmentMode: 'standard'})} className={`w-full text-left p-3 rounded-[16px] border transition ${rule.fragmentMode === 'standard' ? 'bg-[#6750A4]/5 border-[#6750A4] ring-1 ring-[#6750A4]' : 'bg-[#FAF8F5] border-[#ECE6DC]'}`}>
                      <div className="font-bold text-xs text-[#1D1B16] mb-0.5 flex items-center justify-between">
                        <span>标准咨询模式 (推荐)</span>
                        {rule.fragmentMode === 'standard' && <Check className="w-3.5 h-3.5 text-[#6750A4]" />}
                      </div>
                      <div className="text-[10px] text-[#7A756C]">推荐生成 30 分钟以上的连贯服务块。</div>
                    </button>

                    <button onClick={() => onRuleChange({...rule, fragmentMode: 'deep'})} className={`w-full text-left p-3 rounded-[16px] border transition ${rule.fragmentMode === 'deep' ? 'bg-[#6750A4]/5 border-[#6750A4] ring-1 ring-[#6750A4]' : 'bg-[#FAF8F5] border-[#ECE6DC]'}`}>
                      <div className="font-bold text-xs text-[#1D1B16] mb-0.5 flex items-center justify-between">
                        <span>深度咨询模式</span>
                        {rule.fragmentMode === 'deep' && <Check className="w-3.5 h-3.5 text-[#6750A4]" />}
                      </div>
                      <div className="text-[10px] text-[#7A756C]">优先保障 45/60 分钟完整时间，抑制碎片化短单。</div>
                    </button>
                  </div>
                </div>
              </div>
            </div>
          )}
        </div>
      </div>

      {/* Add Time Modal */}
      {showAddModal && (
        <div className="absolute inset-0 z-[80] bg-black/40 flex items-end sm:items-center justify-center animate-in fade-in duration-200">
          <div className="bg-white w-full sm:w-[360px] sm:rounded-[24px] rounded-t-[24px] p-5 animate-in slide-in-from-bottom-full sm:slide-in-from-bottom-0">
            <div className="flex justify-between items-center mb-5">
              <h3 className="font-bold text-[#1D1B16]">添加可服务时间</h3>
              <button onClick={() => setShowAddModal(false)} className="p-1 rounded-full hover:bg-[#FAF8F5] transition">
                <X className="w-5 h-5 text-[#7A756C]"/>
              </button>
            </div>
            
            <div className="space-y-4 text-sm">
              <div>
                <label className="block font-bold text-[#1D1B16] mb-1.5">选择星期</label>
                <select 
                  value={newWeekday} 
                  onChange={e => setNewWeekday(Number(e.target.value))}
                  className="w-full bg-[#FAF8F5] border border-[#ECE6DC] rounded-[16px] px-3.5 py-3 outline-none"
                >
                  {WEEKDAYS.map((d, i) => (
                    <option key={i+1} value={i+1}>{d}</option>
                  ))}
                </select>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block font-bold text-[#1D1B16] mb-1.5">开始时间</label>
                  <input 
                    type="time" 
                    value={newStartTime}
                    onChange={e => setNewStartTime(e.target.value)}
                    className="w-full bg-[#FAF8F5] border border-[#ECE6DC] rounded-[16px] px-3.5 py-3 outline-none font-mono"
                  />
                </div>
                <div>
                  <label className="block font-bold text-[#1D1B16] mb-1.5">结束时间</label>
                  <input 
                    type="time" 
                    value={newEndTime}
                    onChange={e => setNewEndTime(e.target.value)}
                    className="w-full bg-[#FAF8F5] border border-[#ECE6DC] rounded-[16px] px-3.5 py-3 outline-none font-mono"
                  />
                </div>
              </div>

              <button 
                onClick={handleAddTime}
                className="w-full mt-2 py-3.5 rounded-full bg-[#6750A4] text-white font-bold shadow-xs active:scale-95 transition"
              >
                确认添加
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
