import React, { useState, useEffect } from 'react';
import {
  Calendar as CalendarIcon, Clock, CheckCircle2, ChevronRight, Settings,
  ChevronLeft, Plus, Search, Menu, MessageSquare, AlertCircle, X,
  ChevronDown, Filter, Sparkles
} from 'lucide-react';
import { ConsultantProfile, ServiceProduct, Order } from '../../types';

interface ScheduleTabProps {
    orders?: Order[];
    consultant?: ConsultantProfile;
    products?: ServiceProduct[];
    isMockEmpty?: boolean;
    hasConfiguredSchedule?: boolean;
    onConfirmOrder?: (orderId: string) => void;
    onEnterRoom?: (order: Order) => void;
    onSubPageChange?: (isSubPage: boolean) => void;
    onOpenOrderInfo?: (order: Order) => void;
    onNavigateToProfile?: () => void;
    onNavigateToScheduleSettings?: () => void;
    onNavigateToGrowth?: () => void;
  }

type SubTab = 'calendar' | 'pending' | 'confirmed';
type BookedSubTab = 'all' | 'today' | 'future' | 'completed' | 'cancelled';

export const ScheduleTab: React.FC<ScheduleTabProps> = ({
  orders,
  consultant,
  products,
  isMockEmpty,
  hasConfiguredSchedule,
  onConfirmOrder,
  onEnterRoom,
  onSubPageChange,
  onOpenOrderInfo,
  onNavigateToProfile,
  onNavigateToScheduleSettings,
  onNavigateToGrowth
}) => {
  const [activeTab, setActiveTab] = useState<SubTab>('calendar');
  const [bookedTab, setBookedTab] = useState<BookedSubTab>('all');
  
  // Interactive States
  const [currentYear, setCurrentYear] = useState(2026);
  const [currentMonth, setCurrentMonth] = useState(8); // 1-12
  const [selectedDate, setSelectedDate] = useState(5);
  const [isMonthView, setIsMonthView] = useState(false);
  
  // Modal States
  const [showConfirmModal, setShowConfirmModal] = useState<Order | null>(null);
  const [showResourceModal, setShowResourceModal] = useState(false);
  const [showUnavailableModal, setShowUnavailableModal] = useState(false);
  const [showAddUnavailableModal, setShowAddUnavailableModal] = useState(false);

  const safeOrders = orders || [];
  const pendingOrders = safeOrders.filter(o => o.status === 'pending_confirm');
  // For MVP, just show all non-pending as booked/history based on tab
  const confirmedOrders = safeOrders.filter(o => o.status === 'scheduled');
  const completedOrders = safeOrders.filter(o => o.status === 'completed');

  useEffect(() => {
    if (onSubPageChange) {
      onSubPageChange(false); // Can adjust if settings should hide bottom nav
    }
  }, [activeTab, onSubPageChange]);

  const generateMonthDays = (year: number, month: number) => {
    const days = [];
    const firstDay = new Date(year, month - 1, 1).getDay(); // 0 (Sun) to 6 (Sat)
    const daysInMonth = new Date(year, month, 0).getDate();
    
    for (let i = 0; i < firstDay; i++) {
      days.push(null);
    }
    for (let i = 1; i <= daysInMonth; i++) {
      days.push(i);
    }
    return days;
  };

  const monthDays = generateMonthDays(currentYear, currentMonth);
  const weekDayLabels = ['日', '一', '二', '三', '四', '五', '六'];

  const handlePrevMonth = () => {
    if (currentMonth === 1) {
      setCurrentMonth(12);
      setCurrentYear(currentYear - 1);
    } else {
      setCurrentMonth(currentMonth - 1);
    }
  };

  const handleNextMonth = () => {
    if (currentMonth === 12) {
      setCurrentMonth(1);
      setCurrentYear(currentYear + 1);
    } else {
      setCurrentMonth(currentMonth + 1);
    }
  };

  const handleToday = () => {
    setCurrentYear(2026);
    setCurrentMonth(8);
    setSelectedDate(5);
    setIsMonthView(false);
  };

  const renderTopNav = () => (
    <div className="bg-[#FAF8F5] px-4 pb-3 sticky top-[76px] z-20">
      <div className="flex gap-2 overflow-x-auto scrollbar-none pb-1">
        {[
          { id: 'calendar', label: '日历' },
          { id: 'pending', label: `待确认 (${pendingOrders.length})` },
          { id: 'confirmed', label: '已预约' },
        ].map(tab => (
          <button
            key={tab.id}
            onClick={() => setActiveTab(tab.id as SubTab)}
            className={`px-5 py-2 text-[14px] font-bold rounded-full transition-colors whitespace-nowrap ${
              activeTab === tab.id
                ? 'bg-[#EADDFF] text-[#21005D]'
                : 'bg-white border border-[#E6E0D6] text-[#49463D] hover:bg-[#EAE5DB]'
            }`}
          >
            {tab.label}
          </button>
        ))}
      </div>
    </div>
  );

  const renderCalendar = () => (
    <div className="animate-in fade-in duration-200 bg-[#FAF8F5] min-h-full pb-24">
      {/* Date Selector */}
      <div className="bg-white px-4 py-4 sticky top-[125px] z-10 shadow-sm rounded-b-[28px] mx-2 border border-[#ECE6DC]">
        <div className="flex items-center justify-between mb-5">
          <div className="flex items-center gap-1">
            <button onClick={handlePrevMonth} className="p-1.5 hover:bg-[#FAF8F5] rounded-full transition active:scale-95">
              <ChevronLeft className="w-5 h-5 text-[#49463D]" />
            </button>
            <h2 className="text-[18px] font-bold text-[#1D1B16] tracking-tight w-[48px] text-center">
              {currentMonth}月
            </h2>
            <button onClick={handleNextMonth} className="p-1.5 hover:bg-[#FAF8F5] rounded-full transition active:scale-95">
              <ChevronRight className="w-5 h-5 text-[#49463D]" />
            </button>
          </div>
          
          <div className="flex items-center gap-2">
            <button 
              onClick={() => setIsMonthView(!isMonthView)}
              className={`text-[12px] font-bold px-3 py-1.5 rounded-md transition ${isMonthView ? 'bg-[#EADDFF] text-[#21005D]' : 'bg-[#FAF8F5] text-[#49463D] border border-[#ECE6DC] hover:bg-[#EAE5DB]'}`}
            >
              {isMonthView ? '收起月历' : '展开月历'}
            </button>
            <button 
              onClick={handleToday}
              className="text-[13px] text-[#21005D] font-bold bg-[#EADDFF] px-4 py-1.5 rounded-full hover:bg-[#D0BCFF] active:scale-95 transition shadow-sm"
            >
              今天
            </button>
            <button 
              onClick={() => onNavigateToScheduleSettings?.()}
              className="w-8 h-8 rounded-full bg-[#FAF8F5] flex items-center justify-center text-[#49463D] hover:bg-[#EAE5DB] transition"
            >
              <Settings className="w-4 h-4" />
            </button>
          </div>
        </div>
        
        {isMonthView ? (
          <div className="animate-in fade-in slide-in-from-top-2">
            <div className="grid grid-cols-7 gap-1 mb-2">
              {weekDayLabels.map((day, i) => (
                <div key={i} className="text-center text-[12px] font-bold text-[#7A756C]">{day}</div>
              ))}
            </div>
            <div className="grid grid-cols-7 gap-y-2 gap-x-1">
              {monthDays.map((date, i) => {
                const isSelected = date === selectedDate;
                // Mock dots
                const hasConfirmed = !isMockEmpty && (date === 5 || date === 12 || date === 18);
                const hasPending = !isMockEmpty && (date === 5 || date === 8 || date === 22);

                return (
                  <div 
                    key={i} 
                    className={`flex flex-col justify-start pt-1 pb-1 items-center cursor-pointer rounded-2xl transition-all ${
                      date ? 'hover:bg-[#FAF8F5] active:scale-95' : ''
                    }`}
                    onClick={() => { 
                      if (date) { 
                        setSelectedDate(date); 
                        setIsMonthView(false); 
                      }
                    }}
                  >
                    {date && (
                      <>
                        <div 
                          className={`w-8 h-8 rounded-full flex items-center justify-center text-[15px] font-bold transition-all ${
                            isSelected ? 'bg-[#6750A4] text-white shadow-md' : 'text-[#1D1B16]'
                          }`}
                        >
                          {date}
                        </div>
                        <div className="flex gap-1 mt-1 h-1.5">
                          {hasConfirmed && <div className="w-1.5 h-1.5 rounded-full bg-[#388E3C]"></div>}
                          {hasPending && <div className="w-1.5 h-1.5 rounded-full bg-[#F29900]"></div>}
                        </div>
                      </>
                    )}
                  </div>
                );
              })}
            </div>
          </div>
        ) : (
          <div className="flex justify-between items-center mb-1 animate-in fade-in">
            {[-3, -2, -1, 0, 1, 2, 3].map((offset, i) => {
              const displayDateObj = new Date(currentYear, currentMonth - 1, selectedDate + offset);
              const displayDate = displayDateObj.getDate();
              const weekDayIndex = displayDateObj.getDay();
              const isSelected = offset === 0;
              
              // Mock dots
              const hasConfirmed = !isMockEmpty && (displayDate === 5 || displayDate === 12 || displayDate === 18);
              const hasPending = !isMockEmpty && (displayDate === 5 || displayDate === 8 || displayDate === 22);

              return (
                <div 
                  key={i} 
                  onClick={() => {
                    setCurrentYear(displayDateObj.getFullYear());
                    setCurrentMonth(displayDateObj.getMonth() + 1);
                    setSelectedDate(displayDate);
                  }}
                  className="flex flex-col items-center gap-1.5 cursor-pointer group px-1"
                >
                  <span className={`text-[12px] font-bold ${isSelected ? 'text-[#6750A4]' : 'text-[#7A756C]'}`}>{weekDayLabels[weekDayIndex]}</span>
                  <div className={`w-10 h-10 rounded-full flex items-center justify-center text-[16px] font-bold transition-all ${
                    isSelected ? 'bg-[#6750A4] text-white shadow-md' : 'text-[#1D1B16] hover:bg-[#E7E0EC] group-active:scale-95'
                  }`}>
                    {displayDate}
                  </div>
                  <div className="flex gap-1 h-1.5">
                    {hasConfirmed && <div className="w-1.5 h-1.5 rounded-full bg-[#388E3C]"></div>}
                    {hasPending && <div className="w-1.5 h-1.5 rounded-full bg-[#F29900]"></div>}
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>

      <div className="px-4 pt-6 pb-3 flex justify-between items-end">
        <h3 className="text-[14px] font-bold text-[#49463D] tracking-tight">
          {currentMonth}月{selectedDate}日 星期{weekDayLabels[new Date(currentYear, currentMonth - 1, selectedDate).getDay()]}
        </h3>
        <span className="text-[12px] text-[#7A756C] font-medium">资源管理中心</span>
      </div>

      {/* Timeline */}
      <div className="px-4 space-y-3 relative pb-20">
        {hasConfiguredSchedule ? (
          <>
            <div className="absolute left-[38px] top-4 bottom-0 w-px bg-[#ECE6DC] z-0" />
            
            {isMockEmpty ? (
              <>
                {/* 3. 可预约 - Blue */}
                <div className="flex gap-4 relative z-10">
                  <div className="w-12 text-right text-[14px] font-bold text-[#1D1B16] pt-3 shrink-0 font-mono">09:00</div>
                  <div className="flex-1 bg-[#D3E3FD] rounded-[24px] p-4 shadow-sm border border-[#A8C7FA] border-dashed cursor-pointer hover:shadow-md active:scale-[0.98] transition-all">
                    <div className="flex justify-between items-start mb-1">
                      <span className="text-[11px] bg-[#0842A0] text-white px-2 py-0.5 rounded-md font-bold shadow-xs">可预约</span>
                      <span className="text-[12px] text-[#0842A0] font-mono font-bold">09:00-12:00</span>
                    </div>
                    <div className="font-bold text-[#001C3B] text-[15px] tracking-tight mt-2">系统生成可预约资源</div>
                    <div className="text-[12px] text-[#001C3B] mt-1 opacity-80 font-medium">支持 15/30/45/60 分钟服务</div>
                  </div>
                </div>

                {/* 4. 不可用 - Gray */}
                <div className="flex gap-4 relative z-10">
                  <div className="w-12 text-right text-[14px] font-bold text-[#A09C94] pt-3 shrink-0 font-mono">12:00</div>
                  <div className="flex-1 bg-[#F5F5F5] rounded-[24px] p-4 border border-[#ECE6DC]">
                    <div className="flex justify-between items-start mb-1">
                      <span className="text-[11px] bg-[#E6E0D6] text-[#7A756C] px-2 py-0.5 rounded-md font-bold">休息</span>
                      <span className="text-[12px] text-[#A09C94] font-mono font-bold">12:00-14:00</span>
                    </div>
                    <div className="font-bold text-[#A09C94] text-[15px] tracking-tight mt-2">不可预约</div>
                  </div>
                </div>

                <div className="text-center py-8 mt-6 bg-white rounded-[24px] border border-[#ECE6DC] shadow-sm flex flex-col items-center relative z-10">
                  <div className="w-12 h-12 bg-[#FAF8F5] rounded-full flex items-center justify-center mx-auto mb-2 border border-[#E6E0D6]">
                    <Sparkles className="w-5 h-5 text-[#6750A4]" />
                  </div>
                  <h4 className="text-[14px] font-bold text-[#1D1B16] mb-1">排班已生效</h4>
                  <p className="text-[12px] text-[#7A756C] mb-4">暂无客户预约，快去分享主页获客吧</p>
                  <button 
                    onClick={() => onNavigateToGrowth?.()} 
                    className="bg-[#6750A4] text-white px-5 py-2 rounded-full text-[13px] font-bold shadow-sm active:scale-95 transition hover:bg-[#594294]"
                  >
                    去分享主页
                  </button>
                </div>
              </>
            ) : (
              <>
                {/* 1. 已确认 - Green */}
                <div className="flex gap-4 relative z-10">
                  <div className="w-12 text-right text-[14px] font-bold text-[#1D1B16] pt-3 shrink-0 font-mono">14:00</div>
                  <div className="flex-1 bg-[#C4EED0] rounded-[24px] p-4 shadow-sm border border-[#A1DEB3] cursor-pointer hover:shadow-md active:scale-[0.98] transition-all relative overflow-hidden">
                    <div className="absolute top-0 right-0 w-16 h-16 bg-white/20 rounded-full blur-xl -mr-8 -mt-8" />
                    <div className="flex justify-between items-start mb-2 relative z-10">
                      <span className="text-[11px] bg-[#003912] text-white px-2 py-0.5 rounded-md font-bold shadow-xs flex items-center gap-1">
                        <CheckCircle2 className="w-3 h-3" /> 已确认
                      </span>
                      <span className="text-[12px] text-[#003912] font-mono font-bold">14:00-14:45</span>
                    </div>
                    <div className="font-bold text-[#001C3B] text-[16px] tracking-tight flex items-center gap-2 relative z-10">
                      <img src="https://api.dicebear.com/7.x/avataaars/svg?seed=Felix" alt="avatar" className="w-6 h-6 rounded-full bg-white/50 border border-[#003912]/20" />
                      陈先生 (45分钟)
                    </div>
                    <div className="text-[12px] text-[#003912] mt-1.5 opacity-80 font-medium relative z-10 flex items-center gap-1">
                      <div className="w-1.5 h-1.5 rounded-full bg-[#003912] animate-pulse" />
                      即将开始，可进入咨询室
                    </div>
                  </div>
                </div>

                {/* 2. 待确认 - Yellow */}
                <div className="flex gap-4 relative z-10">
                  <div className="w-12 text-right text-[14px] font-bold text-[#1D1B16] pt-3 shrink-0 font-mono">15:00</div>
                  <div className="flex-1 bg-[#FFDF99] rounded-[24px] p-4 shadow-sm border border-[#F2C97D] cursor-pointer hover:shadow-md active:scale-[0.98] transition-all">
                    <div className="flex justify-between items-start mb-2">
                      <span className="text-[11px] bg-[#7A2E0E] text-white px-2 py-0.5 rounded-md font-bold shadow-xs flex items-center gap-1">
                        <AlertCircle className="w-3 h-3" /> 待确认
                      </span>
                      <span className="text-[12px] text-[#7A2E0E] font-mono font-bold">15:00-15:30</span>
                    </div>
                    <div className="font-bold text-[#491C08] text-[16px] tracking-tight flex items-center gap-2">
                      <img src="https://api.dicebear.com/7.x/avataaars/svg?seed=Luna" alt="avatar" className="w-6 h-6 rounded-full bg-white/50 border border-[#7A2E0E]/20" />
                      李女士 (30分钟)
                    </div>
                    <div className="text-[12px] text-[#7A2E0E] mt-1.5 opacity-80 font-medium">
                      待确认接单，超时将自动取消
                    </div>
                  </div>
                </div>

                {/* 3. 可预约 - Blue */}
                <div className="flex gap-4 relative z-10">
                  <div className="w-12 text-right text-[14px] font-bold text-[#1D1B16] pt-3 shrink-0 font-mono">16:00</div>
                  <div className="flex-1 bg-[#D3E3FD] rounded-[24px] p-4 shadow-sm border border-[#A8C7FA] border-dashed cursor-pointer hover:shadow-md active:scale-[0.98] transition-all">
                    <div className="flex justify-between items-start mb-1">
                      <span className="text-[11px] bg-[#0842A0] text-white px-2 py-0.5 rounded-md font-bold shadow-xs">可预约</span>
                      <span className="text-[12px] text-[#0842A0] font-mono font-bold">16:00-18:00</span>
                    </div>
                    <div className="font-bold text-[#001C3B] text-[15px] tracking-tight mt-2">系统生成可预约资源</div>
                    <div className="text-[12px] text-[#001C3B] mt-1 opacity-80 font-medium">支持 15/30/45/60 分钟服务</div>
                  </div>
                </div>

                {/* 4. 不可用 - Gray */}
                <div className="flex gap-4 relative z-10">
                  <div className="w-12 text-right text-[14px] font-bold text-[#A09C94] pt-3 shrink-0 font-mono">18:00</div>
                  <div className="flex-1 bg-[#F5F5F5] rounded-[24px] p-4 border border-[#ECE6DC]">
                    <div className="flex justify-between items-start mb-1">
                      <span className="text-[11px] bg-[#E6E0D6] text-[#7A756C] px-2 py-0.5 rounded-md font-bold">休息</span>
                      <span className="text-[12px] text-[#A09C94] font-mono font-bold">18:00-20:00</span>
                    </div>
                    <div className="font-bold text-[#A09C94] text-[15px] tracking-tight mt-2">不可预约</div>
                  </div>
                </div>
              </>
            )}
          </>
        ) : (
          <div className="text-center py-16 bg-white border border-[#E6E0D6] rounded-[28px] shadow-sm flex flex-col items-center mt-4">
            <div className="w-16 h-16 bg-[#F4EFF4] rounded-full flex items-center justify-center mx-auto mb-4 border border-[#EADDFF]">
              <CalendarIcon className="w-8 h-8 text-[#6750A4]" />
            </div>
            <h3 className="text-[#1D1B16] text-[16px] font-bold tracking-tight mb-2">您还未配置排班</h3>
            <p className="text-[13px] text-[#7A756C] mt-1 font-medium max-w-[220px] mb-6 leading-relaxed">
              设置可服务时间后，系统将自动生成预约资源供客户选择。
            </p>
            <button 
              onClick={() => onNavigateToScheduleSettings?.()}
              className="bg-[#6750A4] text-white px-6 py-2.5 rounded-full text-[14px] font-bold shadow-sm active:scale-95 transition hover:bg-[#594294]"
            >
              去配置排班
            </button>
          </div>
        )}
      </div>
    </div>
  );

  const renderPending = () => (
    <div className="animate-in fade-in duration-200 bg-[#FAF8F5] min-h-full pb-24 p-4 space-y-4">
      <div className="bg-[#EADDFF]/40 border border-[#D0BCFF] rounded-[24px] p-4 shadow-sm">
        <h3 className="font-bold text-[14px] text-[#1D1B16] flex items-center gap-2">
          <AlertCircle className="w-4 h-4 text-[#6750A4]" /> 待处理预约申请
        </h3>
        <p className="text-[12px] text-[#49463D] mt-1">确认后将自动占用对应的时间资源，并同步至日历。</p>
      </div>

      {pendingOrders.map(order => (
        <div key={order.id} className="bg-white border border-[#ECE6DC] rounded-[28px] p-5 shadow-sm">
          <div className="flex gap-3 mb-4">
            <img src={order.clientAvatar} alt="" className="w-12 h-12 rounded-full object-cover border border-[#ECE6DC]" />
            <div className="flex-1">
              <div className="flex justify-between items-start">
                <div className="font-bold text-[16px] text-[#1D1B16]">{order.clientName}</div>
                <div className="text-[#B3261E] font-bold font-mono text-[16px]">¥{order.price}</div>
              </div>
              <div className="text-[13px] text-[#7A756C] mt-0.5 font-medium">
                {order.serviceTypeName}
              </div>
            </div>
          </div>
          
          <div className="bg-[#FAF8F5] rounded-[16px] p-3 space-y-2 mb-4 border border-[#ECE6DC]">
            <div className="flex items-center text-[13px]">
              <span className="text-[#7A756C] w-16">预约时间</span>
              <span className="font-bold text-[#21005D] bg-[#EADDFF] px-2 py-0.5 rounded-md">
                {order.bookingDate} {order.bookingTimeSlot}
              </span>
            </div>
            <div className="flex items-start text-[13px]">
              <span className="text-[#7A756C] w-16 shrink-0 mt-0.5">用户留言</span>
              <span className="text-[#49463D] font-medium leading-relaxed">
                {order.complaintTopic || '无留言'}
              </span>
            </div>
          </div>

          <div className="flex gap-3 pt-2">
            <button className="flex-1 py-3 rounded-full bg-white border border-[#E6E0D6] text-[#49463D] text-[14px] font-bold active:scale-95 transition hover:bg-[#FAF8F5]">
              拒绝
            </button>
            <button 
              onClick={() => onConfirmOrder(order.id)}
              className="flex-1 py-3 rounded-full bg-[#6750A4] text-white text-[14px] font-bold active:scale-95 transition shadow-sm hover:bg-[#594294]"
            >
              确认接单
            </button>
          </div>
        </div>
      ))}
      {pendingOrders.length === 0 && (
        <div className="text-center text-[#7A756C] py-10 text-sm font-medium">暂无待确认的预约</div>
      )}
    </div>
  );

  const renderConfirmed = () => {
    let displayList = confirmedOrders;
    if (bookedTab === 'completed') displayList = completedOrders;
    if (bookedTab === 'cancelled') displayList = [];

    return (
      <div className="animate-in fade-in duration-200 bg-[#FAF8F5] min-h-full pb-24">
        <div className="px-4 py-2 flex gap-4 overflow-x-auto scrollbar-none text-[14px] font-bold text-[#7A756C] border-b border-[#ECE6DC] bg-white sticky top-[125px] z-10">
          {[
            { id: 'all', label: '全部' },
            { id: 'today', label: '今天' },
            { id: 'future', label: '未来' },
            { id: 'completed', label: '已完成' },
            { id: 'cancelled', label: '已取消' },
          ].map(tab => (
            <button 
              key={tab.id}
              onClick={() => setBookedTab(tab.id as BookedSubTab)}
              className={`relative pb-2 whitespace-nowrap transition-colors ${bookedTab === tab.id ? 'text-[#6750A4]' : 'hover:text-[#49463D]'}`}
            >
              {tab.label}
              {bookedTab === tab.id && (
                <div className="absolute bottom-0 left-1/2 -translate-x-1/2 w-4 h-[3px] bg-[#6750A4] rounded-t-full" />
              )}
            </button>
          ))}
        </div>

        <div className="p-4 space-y-4">
          {displayList.length === 0 ? (
            <div className="text-center text-[#7A756C] py-10 text-sm font-medium">当前分类下暂无预约</div>
          ) : (
            displayList.map(order => (
              <div key={order.id} className="bg-white border border-[#ECE6DC] rounded-[24px] p-4 shadow-sm">
                <div className="flex gap-3 mb-3">
                  <img src={order.clientAvatar} alt="" className="w-10 h-10 rounded-full object-cover" />
                  <div className="flex-1">
                    <div className="flex justify-between items-start">
                      <div className="font-bold text-[15px] text-[#1D1B16]">{order.clientName}</div>
                      <div className="text-[12px] font-bold text-[#003912] bg-[#C4EED0] px-2 py-0.5 rounded-md">
                        {order.status === 'completed' ? '已完成' : '已预约'}
                      </div>
                    </div>
                    <div className="text-[13px] text-[#7A756C] mt-1 font-medium">{order.serviceTypeName}</div>
                    <div className="text-[12px] font-bold text-[#49463D] mt-2 font-mono">
                      {order.bookingDate} {order.bookingTimeSlot}
                    </div>
                  </div>
                </div>
                
                <div className="flex gap-2 mt-4 pt-3 border-t border-[#ECE6DC]">
                  <button 
                    onClick={() => onOpenOrderInfo?.(order)}
                    className="flex-1 py-2 rounded-[12px] bg-[#FAF8F5] border border-[#ECE6DC] text-[#49463D] text-[13px] font-bold active:scale-95 transition"
                  >
                    查看详情
                  </button>
                  {order.status === 'scheduled' && (
                    <>
                      <button className="flex-1 py-2 rounded-[12px] bg-[#F9DEDC] text-[#8C1D18] text-[13px] font-bold active:scale-95 transition">
                        取消预约
                      </button>
                      <button 
                        onClick={() => onEnterRoom?.(order)}
                        className="flex-1 py-2 rounded-[12px] bg-[#6750A4] text-white text-[13px] font-bold active:scale-95 transition shadow-sm"
                      >
                        进入咨询室
                      </button>
                    </>
                  )}
                </div>
              </div>
            ))
          )}
        </div>
      </div>
    );
  };


  return (
    <div className="relative min-h-full bg-[#FAF8F5]">
      {/* Global Header */}
      <div className="bg-[#FAF8F5] px-4 pt-10 pb-2 flex items-center justify-between sticky top-0 z-20">
        <h1 className="text-[28px] font-bold text-[#1D1B16]">预约</h1>
        <div className="flex items-center gap-4 text-[#1D1B16]">
          <button className="p-1"><Search className="w-6 h-6" /></button>
          <button className="p-1"><Menu className="w-6 h-6" /></button>
        </div>
      </div>

      {renderTopNav()}

      {activeTab === 'calendar' && renderCalendar()}
      {activeTab === 'pending' && renderPending()}
      {activeTab === 'confirmed' && renderConfirmed()}
      {/* Bottom FAB */}
      <button 
        onClick={() => setShowAddUnavailableModal(true)}
        className="fixed right-6 bottom-[100px] w-14 h-14 bg-[#6750A4] text-white rounded-2xl shadow-lg flex items-center justify-center hover:bg-[#594294] active:scale-95 transition z-30"
      >
        <Plus className="w-6 h-6" />
      </button>

      {/* Modals go here */}
      {showConfirmModal && (
        <div className="fixed inset-0 bg-black/40 z-50 flex items-end sm:items-center justify-center animate-in fade-in">
          <div className="bg-white w-full sm:w-[400px] rounded-t-[28px] sm:rounded-[28px] p-6 animate-in slide-in-from-bottom-10 sm:slide-in-from-bottom-0">
            <div className="flex justify-between items-center mb-6">
              <h3 className="font-bold text-[18px] text-[#1D1B16]">预约确认</h3>
              <button onClick={() => setShowConfirmModal(null)} className="p-2"><X className="w-5 h-5 text-[#49463D]"/></button>
            </div>
            <div className="flex gap-4 items-center mb-6">
              <img src={showConfirmModal.clientAvatar} alt="" className="w-14 h-14 rounded-full" />
              <div>
                <div className="font-bold text-[16px]">{showConfirmModal.clientName}</div>
                <div className="text-[13px] text-[#7A756C] mt-1">{showConfirmModal.serviceTypeName}</div>
              </div>
            </div>
            <div className="bg-[#FAF8F5] p-4 rounded-[16px] mb-6 space-y-3">
              <div className="flex justify-between text-[14px]">
                <span className="text-[#7A756C]">预约时间</span>
                <span className="font-bold text-[#21005D]">10:00-10:30</span>
              </div>
              <div className="flex justify-between text-[14px]">
                <span className="text-[#7A756C]">订单金额</span>
                <span className="font-bold text-[#B3261E]">¥{showConfirmModal.price}</span>
              </div>
              <div className="pt-2 border-t border-[#ECE6DC]">
                <span className="text-[#7A756C] text-[13px] block mb-1">用户留言</span>
                <span className="text-[#1D1B16] text-[14px] leading-relaxed">{showConfirmModal.complaintTopic || '无留言'}</span>
              </div>
            </div>
            <div className="flex gap-3">
              <button onClick={() => setShowConfirmModal(null)} className="flex-1 py-3 rounded-full bg-white border border-[#E6E0D6] text-[#49463D] text-[15px] font-bold active:scale-95 transition">
                拒绝预约
              </button>
              <button 
                onClick={() => { onConfirmOrder(showConfirmModal.id); setShowConfirmModal(null); }}
                className="flex-1 py-3 rounded-full bg-[#6750A4] text-white text-[15px] font-bold active:scale-95 transition shadow-sm"
              >
                确认预约
              </button>
            </div>
          </div>
        </div>
      )}

      {showResourceModal && (
        <div className="fixed inset-0 bg-black/40 z-50 flex items-end sm:items-center justify-center animate-in fade-in">
          <div className="bg-white w-full sm:w-[400px] rounded-t-[28px] sm:rounded-[28px] p-6 animate-in slide-in-from-bottom-10 sm:slide-in-from-bottom-0">
            <div className="flex justify-between items-center mb-6">
              <h3 className="font-bold text-[18px] text-[#1D1B16]">时间资源详情</h3>
              <button onClick={() => setShowResourceModal(false)} className="p-2"><X className="w-5 h-5 text-[#49463D]"/></button>
            </div>
            <div className="bg-[#D3E3FD] p-4 rounded-[16px] mb-6">
              <div className="text-[12px] text-[#0842A0] font-bold mb-1">当前可预约时间段</div>
              <div className="text-[20px] text-[#001C3B] font-mono font-bold">10:45 - 11:30</div>
            </div>
            <h4 className="font-bold text-[14px] text-[#1D1B16] mb-3">支持生成的服务</h4>
            <div className="space-y-2 mb-6">
              {['快速倾听 (15分钟)', '情绪支持 (30分钟)', '深度咨询 (45分钟)'].map(s => (
                <div key={s} className="bg-[#FAF8F5] p-3 rounded-xl border border-[#ECE6DC] text-[14px] text-[#49463D] font-medium flex items-center gap-3">
                  <CheckCircle2 className="w-5 h-5 text-[#003912]" /> {s}
                </div>
              ))}
            </div>
            <button onClick={() => { setShowResourceModal(false); }} className="w-full py-3 rounded-full bg-[#6750A4] text-white text-[15px] font-bold active:scale-95 transition shadow-sm">
              确定
            </button>
          </div>
        </div>
      )}

      {showUnavailableModal && (
        <div className="fixed inset-0 bg-black/40 z-50 flex items-end sm:items-center justify-center animate-in fade-in">
          <div className="bg-white w-full sm:w-[400px] rounded-t-[28px] sm:rounded-[28px] p-6 animate-in slide-in-from-bottom-10 sm:slide-in-from-bottom-0">
            <div className="flex justify-between items-center mb-6">
              <h3 className="font-bold text-[18px] text-[#1D1B16]">不可用时间编辑</h3>
              <button onClick={() => setShowUnavailableModal(false)} className="p-2"><X className="w-5 h-5 text-[#49463D]"/></button>
            </div>
            <div className="bg-[#FAF8F5] p-4 rounded-[16px] mb-6 border border-[#ECE6DC]">
              <div className="flex justify-between items-center mb-3">
                <span className="text-[14px] text-[#7A756C]">时间段</span>
                <span className="font-bold text-[#1D1B16]">12:00 - 14:00</span>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-[14px] text-[#7A756C]">原因</span>
                <span className="font-bold text-[#1D1B16]">休息 / 私人时间</span>
              </div>
            </div>
            <div className="flex gap-3">
              <button onClick={() => setShowUnavailableModal(false)} className="flex-1 py-3 rounded-full bg-[#F9DEDC] text-[#8C1D18] text-[15px] font-bold active:scale-95 transition">
                删除该时段
              </button>
              <button onClick={() => setShowUnavailableModal(false)} className="flex-1 py-3 rounded-full bg-[#6750A4] text-white text-[15px] font-bold active:scale-95 transition shadow-sm">
                保存修改
              </button>
            </div>
          </div>
        </div>
      )}

      {showAddUnavailableModal && (
        <div className="fixed inset-0 bg-black/40 z-50 flex items-end sm:items-center justify-center animate-in fade-in">
          <div className="bg-white w-full sm:w-[400px] rounded-t-[28px] sm:rounded-[28px] p-6 animate-in slide-in-from-bottom-10 sm:slide-in-from-bottom-0">
            <div className="flex justify-between items-center mb-6">
              <h3 className="font-bold text-[18px] text-[#1D1B16]">添加不可用时间</h3>
              <button onClick={() => setShowAddUnavailableModal(false)} className="p-2"><X className="w-5 h-5 text-[#49463D]"/></button>
            </div>
            <div className="space-y-4 mb-6">
              <div>
                <label className="text-[13px] text-[#7A756C] font-bold block mb-2">选择原因</label>
                <div className="flex gap-2">
                  <button className="px-4 py-2 bg-[#EADDFF] text-[#21005D] text-[13px] font-bold rounded-full border border-[#D0BCFF]">休息</button>
                  <button className="px-4 py-2 bg-white text-[#49463D] text-[13px] font-bold rounded-full border border-[#ECE6DC]">私人安排</button>
                  <button className="px-4 py-2 bg-white text-[#49463D] text-[13px] font-bold rounded-full border border-[#ECE6DC]">临时关闭</button>
                </div>
              </div>
              <div className="flex gap-4">
                <div className="flex-1">
                  <label className="text-[13px] text-[#7A756C] font-bold block mb-2">开始时间</label>
                  <div className="bg-[#FAF8F5] border border-[#ECE6DC] rounded-[12px] p-3 text-[15px] font-bold">14:00</div>
                </div>
                <div className="flex-1">
                  <label className="text-[13px] text-[#7A756C] font-bold block mb-2">结束时间</label>
                  <div className="bg-[#FAF8F5] border border-[#ECE6DC] rounded-[12px] p-3 text-[15px] font-bold">15:00</div>
                </div>
              </div>
            </div>
            <button onClick={() => setShowAddUnavailableModal(false)} className="w-full py-3 rounded-full bg-[#6750A4] text-white text-[15px] font-bold active:scale-95 transition shadow-sm">
              确认添加
            </button>
          </div>
        </div>
      )}

    </div>
  );
};
