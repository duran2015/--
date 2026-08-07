import { useState, useRef, useEffect } from "react";
import { motion, AnimatePresence } from "motion/react";
import {
  ChevronRight,
  ShieldAlert,
  ChevronLeft,
  CalendarDays,
  CalendarClock,
  Lock,
  Plus,
  Bell,
  Wind,
  Headphones,
  Moon,
  Cloud,
  Book,
  Smile,
  Activity,
  HeartPulse,
  Sparkles,
  ChevronDown,
  FileText
} from "lucide-react";
import { useAppStore } from "../../store";
import { mockUser } from "../../data";
import { getClientJourneyPresentation } from "../../../clientJourneyPresentation";

// 5级 Emoji 体系
const EMOTIONS = [
  { level: 1, emoji: "😡", label: "糟了", color: "bg-[#E85D5D]", textColor: "text-[#E85D5D]" },
  { level: 2, emoji: "😞", label: "低落", color: "bg-[#F0A458]", textColor: "text-[#F0A458]" },
  { level: 3, emoji: "😐", label: "还行", color: "bg-[#F5D76E]", textColor: "text-[#F5D76E]" },
  { level: 4, emoji: "😊", label: "不错", color: "bg-[#7ECBA1]", textColor: "text-[#7ECBA1]" },
  { level: 5, emoji: "😆", label: "超棒", color: "bg-[#5BB5E0]", textColor: "text-[#5BB5E0]" },
];

// 可选场景标签
const TAGS = [
  { id: 'study', emoji: '📚', label: '学业' },
  { id: 'social', emoji: '👥', label: '社交' },
  { id: 'sports', emoji: '🏃', label: '运动' },
  { id: 'sleep', emoji: '😴', label: '睡眠' },
  { id: 'food', emoji: '🍜', label: '饮食' },
  { id: 'work', emoji: '💼', label: '实习' },
  { id: 'love', emoji: '❤️', label: '恋爱' },
  { id: 'home', emoji: '🏠', label: '家庭' },
];

export function HomeTab() {
  const { user, pushView, setTab, assessmentRecords, orders, consultationWorkflow, setBookingOrder } = useAppStore();

  const isNewUser = user.isNewUser || false;
  const hasRisk = user.hasRisk || false;

  // Streak State
  const [streakDays, setStreakDays] = useState(12);
  const [graceDays, setGraceDays] = useState(2);
  
  // Calendar State (Mock data for MVP)
  const [hasRecordedToday, setHasRecordedToday] = useState(false);
  const [showInputSheet, setShowInputSheet] = useState(false);
  const [selectedEmoji, setSelectedEmoji] = useState<number | null>(null);
  const [selectedTags, setSelectedTags] = useState<string[]>([]);
  const [showCalendarDetail, setShowCalendarDetail] = useState<{date: number | string, emoji: string, tags: string[], color: string} | null>(null);
  
  // IP Status (小鹿状态)
  const getIpStatus = () => {
    if (!hasRecordedToday) return { status: 'curious', text: '今天感觉怎么样？' };
    if (selectedEmoji && selectedEmoji >= 4) return { status: 'happy', text: '太棒啦～' };
    if (selectedEmoji === 3) return { status: 'calm', text: '嗯，慢慢来～' };
    if (selectedEmoji && selectedEmoji <= 2) return { status: 'hug', text: '没关系，我在呢' };
    return { status: 'curious', text: '今天感觉怎么样？' };
  };

  const ipStatus = getIpStatus();
  const activeConsultationOrder = orders.find((order) => !["cancelled", "refunded"].includes(order.status as string));
  const activeConsultation = activeConsultationOrder
    ? getClientJourneyPresentation(activeConsultationOrder, consultationWorkflow)
    : null;

  const [isCalendarExpanded, setIsCalendarExpanded] = useState(false);
  const scrollRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (scrollRef.current && !isCalendarExpanded) {
      // Auto scroll to the rightmost (today)
      scrollRef.current.scrollLeft = scrollRef.current.scrollWidth;
    }
  }, [isCalendarExpanded]);

  // Generate 14-day row (scrollable)
  const renderSevenDaysRow = () => {
    const mockData = [
      { dayIndex: 0, level: 3, emoji: "😐", label: "还行", tags: [] },
      { dayIndex: 1, level: 4, emoji: "😊", label: "不错", tags: ['学业'] },
      { dayIndex: 2, level: 5, emoji: "😆", label: "超棒", tags: ['运动'] },
      { dayIndex: 3, level: 2, emoji: "😞", label: "低落", tags: ['睡眠'] },
      { dayIndex: 4, level: 4, emoji: "😊", label: "不错", tags: [] },
      { dayIndex: 5, level: null, emoji: null, label: null, tags: [] },
      { dayIndex: 6, level: 3, emoji: "😐", label: "还行", tags: ['社交'] },
      { dayIndex: 7, level: 4, emoji: "😊", label: "不错", tags: ['学业'] },
      { dayIndex: 8, level: 3, emoji: "😐", label: "还行", tags: [] },
      { dayIndex: 9, level: 4, emoji: "😊", label: "不错", tags: ['社交'] },
      { dayIndex: 10, level: 2, emoji: "😞", label: "低落", tags: ['睡眠'] },
      { dayIndex: 11, level: null, emoji: null, label: null, tags: [] }, // Empty/missed day
      { dayIndex: 12, level: 4, emoji: "😊", label: "不错", tags: ['运动'] },
      // Index 13 is "Today"
    ];

    const dayNames = ['日', '一', '二', '三', '四', '五', '六'];
    const todayDate = new Date();

    return Array.from({length: 14}).map((_, index) => {
      const isToday = index === 13;
      const d = new Date();
      d.setDate(todayDate.getDate() - (13 - index));
      const dayName = dayNames[d.getDay()];
      
      let content = null;
      if (isToday) {
        if (hasRecordedToday && selectedEmoji) {
          const emotionObj = EMOTIONS.find(e => e.level === selectedEmoji);
          const displayTags = selectedTags.map(tagId => TAGS.find(t => t.id === tagId)?.label).filter(Boolean) as string[];
          content = (
            <div className="flex flex-col items-center justify-center cursor-pointer group" onClick={() => setShowCalendarDetail({ date: d.getDate(), emoji: emotionObj?.emoji || "😐", tags: displayTags, color: emotionObj?.color || "bg-gray-200" })}>
              <div className="text-[22px] mb-1 group-active:scale-90 transition-transform">{emotionObj?.emoji}</div>
              <span className="text-[11px] font-bold text-gray-800">{emotionObj?.label}</span>
            </div>
          );
        } else {
          content = (
            <div className="flex flex-col items-center justify-center cursor-pointer" onClick={() => setShowInputSheet(true)}>
              <div className="w-[22px] h-[22px] rounded-full border-2 border-primary mb-1 animate-pulse bg-primary/10 flex items-center justify-center">
                <div className="w-1.5 h-1.5 rounded-full bg-primary" />
              </div>
              <span className="text-[11px] font-bold text-primary">今天?</span>
            </div>
          );
        }
      } else {
        const data = mockData.find(m => m.dayIndex === index);
        if (data && data.level) {
          const colorClass = EMOTIONS.find(e => e.level === data.level)?.color || "bg-gray-200";
          content = (
            <div className="flex flex-col items-center justify-center cursor-pointer group" onClick={() => setShowCalendarDetail({ date: d.getDate(), emoji: data.emoji || "😐", tags: data.tags, color: colorClass })}>
              <div className="text-[22px] mb-1 group-active:scale-90 transition-transform">{data.emoji}</div>
              <span className="text-[11px] font-medium text-gray-600">{data.label}</span>
            </div>
          );
        } else {
          content = (
            <div className="flex flex-col items-center justify-center">
              <div className="w-[22px] h-[22px] flex items-center justify-center mb-1">
                <div className="w-2 h-2 rounded-full bg-gray-200" />
              </div>
              <span className="text-[11px] font-medium text-gray-400">—</span>
            </div>
          );
        }
      }

      return (
        <div key={index} className="flex flex-col items-center flex-shrink-0 min-w-[42px] snap-end">
          <div className="text-center text-[11px] text-gray-400 font-medium mb-3">{dayName}</div>
          {content}
        </div>
      );
    });
  };

  const handleEmojiSelect = (level: number) => {
      setSelectedEmoji(level);
      setTimeout(() => {
        setHasRecordedToday(true);
        setShowInputSheet(false);
        setStreakDays(prev => prev + 1);
      }, 500);
    };

  const toggleTag = (id: string) => {
    setSelectedTags(prev => 
      prev.includes(id) ? prev.filter(t => t !== id) : [...prev, id]
    );
  };

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      className="flex flex-col h-full bg-transparent relative pb-24 overflow-y-auto w-full"
    >
      {/* 顶部栏 & 小鹿状态区 (IP Status) */}
      <div className="px-5 pt-10 pb-4 flex items-center justify-between sticky top-0 bg-[#fbfaf6]/88 backdrop-blur-xl z-10 border-b border-white/30">
        <div className="flex items-center">
          <div className="relative mr-3">
            <div className="w-11 h-11 bg-gradient-to-br from-[#fff4df] to-[#e9f3ed] rounded-[16px] flex items-center justify-center text-xl shadow-[0_8px_22px_rgba(50,116,92,0.12)] border border-white z-10 relative">
              🦌
            </div>
          </div>
          <div>
            <h1 className="text-[17px] font-black text-gray-900 tracking-tight leading-tight">可鹿 <span className="text-[10px] font-semibold text-primary bg-primary/8 rounded-full px-2 py-0.5 ml-1">陪伴中</span></h1>
            <p className="text-[11px] font-medium text-gray-500 mt-1">{ipStatus.text}</p>
          </div>
        </div>
        
        <div className="flex space-x-3">
          {!hasRecordedToday && (
            <button 
              onClick={() => setShowInputSheet(true)}
              className="bg-primary text-white text-[13px] font-bold px-4 py-2 rounded-[14px] shadow-[0_8px_20px_rgba(50,116,92,0.2)] flex items-center active:scale-95 transition-transform"
            >
              <Plus size={14} className="mr-1" strokeWidth={3} />
              记录
            </button>
          )}
        </div>
      </div>

      {activeConsultationOrder && activeConsultation && (
        <div className="px-5 mb-6">
          <button
            onClick={() => { setBookingOrder(activeConsultationOrder); pushView("user-order-detail"); }}
            className="w-full rounded-[24px] border border-[#D0BCFF] bg-[#F6EDFF] p-4 text-left text-[#21005D] shadow-sm active:scale-[0.99] transition-transform"
          >
            <div className="flex items-start gap-3">
              <div className="grid h-11 w-11 shrink-0 place-items-center rounded-[15px] bg-[#EADDFF] text-[#6750A4]"><CalendarClock size={21} /></div>
              <div className="min-w-0 flex-1">
                <div className="flex items-center justify-between gap-3"><span className="text-[10px] font-black text-[#6750A4]">我的咨询 · {activeConsultation.statusLabel}</span><ChevronRight size={17} /></div>
                <h2 className="mt-1 text-[15px] font-black">{activeConsultation.currentLabel}</h2>
                <p className="mt-1 line-clamp-2 text-[11px] leading-5 text-[#49454F]">{activeConsultation.description}</p>
              </div>
            </div>
          </button>
        </div>
      )}

      {/* 双人职场关系测试：社交获客入口 */}
      <div className="px-5 mb-6 mt-3">
        <button onClick={() => pushView('work-buddy-test')} className="relative w-full overflow-hidden rounded-[1.75rem] bg-[#292b4d] p-5 text-left text-white shadow-[0_16px_38px_rgba(41,43,77,.2)] active:scale-[.98] transition-transform"><div className="absolute -right-8 -top-10 h-36 w-36 rounded-full bg-[#ffca75]/20" /><div className="relative flex items-center"><div className="flex-1"><span className="rounded-full bg-white/10 px-2.5 py-1 text-[10px] font-bold text-[#ffdc9c]">双人完成 · 职场关系测试</span><h2 className="mt-4 text-[20px] font-black leading-7">你和 TA 是哪种<br />职场搭子？</h2><p className="mt-2 text-[11px] text-white/55">12 道工作情境题，解锁双人默契报告</p></div><div className="ml-3 text-[52px]">🤝</div></div><div className="relative mt-4 flex items-center text-[11px] font-bold text-white">先完成我的部分 <ChevronRight size={14} className="ml-1" /></div></button>
      </div>

      {/* 情绪追踪综合模块 */}
      <div className="px-5 mb-8 mt-2">
          <div className="bg-white/92 rounded-[1.75rem] p-5 shadow-[0_14px_38px_rgba(33,53,46,0.07)] border border-white">
          <div className="flex items-center justify-between mb-6">
            <h2 className="text-[15px] font-bold text-gray-800 flex items-center">
              最近7天情绪
            </h2>
            <button 
              onClick={() => setIsCalendarExpanded(!isCalendarExpanded)}
              className="text-primary bg-primary/5 px-3 py-1.5 rounded-full text-[12px] font-bold flex items-center hover:bg-primary/10 transition-colors"
            >
              <CalendarDays size={14} className="mr-1" />
              {isCalendarExpanded ? '收起' : '展开月历'}
            </button>
          </div>

          <AnimatePresence mode="wait" initial={false}>
            {!isCalendarExpanded ? (
              <motion.div 
                key="week"
                initial={{ opacity: 0, height: 0 }}
                animate={{ opacity: 1, height: 'auto' }}
                exit={{ opacity: 0, height: 0 }}
                className="flex overflow-x-auto gap-x-3 mb-5 pb-2 snap-x hide-scrollbar -mx-2 px-2"
                ref={scrollRef}
              >
                {renderSevenDaysRow()}
              </motion.div>
            ) : (
              <motion.div 
                key="month"
                initial={{ opacity: 0, height: 0 }}
                animate={{ opacity: 1, height: 'auto' }}
                exit={{ opacity: 0, height: 0 }}
                className="mb-5 overflow-hidden"
              >
                <div className="flex justify-between items-center mb-4 px-2">
                  <span className="text-[13px] font-bold text-gray-700">2026年6月</span>
                  <div className="flex space-x-3">
                    <ChevronLeft size={16} className="text-gray-400 cursor-pointer hover:text-gray-600" />
                    <ChevronRight size={16} className="text-gray-400 cursor-pointer hover:text-gray-600" />
                  </div>
                </div>
                <div className="grid grid-cols-7 gap-y-4 gap-x-2">
                  {Array.from({ length: 30 }, (_, i) => i + 1).map(day => {
                    let clickHandler = undefined;
                    let content = <div className="w-3.5 h-3.5 rounded-full border border-dashed border-gray-300"></div>;
                    
                    if ([2, 5, 8, 12, 16].includes(day)) {
                       content = <span className="text-[18px]">😊</span>;
                       clickHandler = () => setShowCalendarDetail({ date: day, emoji: '😊', tags: ['学业', '运动'], color: 'bg-teal-100 text-teal-600' });
                    } else if ([3, 6, 14].includes(day)) {
                       content = <span className="text-[18px]">😞</span>;
                       clickHandler = () => setShowCalendarDetail({ date: day, emoji: '😞', tags: ['社交'], color: 'bg-orange-100 text-orange-600' });
                    } else if ([1, 10, 15].includes(day)) {
                       content = <span className="text-[18px]">😐</span>;
                       clickHandler = () => setShowCalendarDetail({ date: day, emoji: '😐', tags: ['睡眠'], color: 'bg-yellow-100 text-yellow-600' });
                    } else if (day === 17) {
                       content = <div className="w-3.5 h-3.5 rounded-full border border-blue-400 animate-pulse bg-blue-100"></div>;
                    }

                    return (
                      <div key={day} className="flex flex-col items-center justify-center cursor-pointer active:scale-90 transition-transform h-10" onClick={clickHandler}>
                        {content}
                        <span className="text-[10px] text-gray-400 mt-1 font-medium">{day}</span>
                      </div>
                    )
                  })}
                </div>
              </motion.div>
            )}
          </AnimatePresence>


        </div>
      </div>

      {/* 专业测评横排 */}
      <div className="px-5 mb-8">
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-[16px] font-bold text-gray-800">专业测评</h2>
          <span 
            className="text-[12px] text-gray-400 font-medium flex items-center cursor-pointer"
            onClick={() => pushView('mini-assessment-home')}
          >
            全部 <ChevronRight size={14} />
          </span>
        </div>
        <div className="flex space-x-3 overflow-x-auto pb-2 -mx-5 px-5 [&::-webkit-scrollbar]:hidden [-ms-overflow-style:none] [scrollbar-width:none]">
          {[
            { id: 'PHQ-9', title: '抑郁自评量表', desc: '了解近期情绪状态', icon: <HeartPulse size={16} />, color: 'bg-orange-100 text-orange-500', wrapper: 'bg-orange-50 border-orange-100/50' },
            { id: 'GAD-7', title: 'GAD-7焦虑测评', desc: '国际通用量表', icon: <Activity size={16} />, color: 'bg-blue-100 text-blue-500', wrapper: 'bg-blue-50 border-blue-100/50' },
            { id: 'MBTI', title: 'MBTI人格测评', desc: '发现真实的自己', icon: <Sparkles size={16} />, color: 'bg-teal-100 text-teal-500', wrapper: 'bg-teal-50 border-teal-100/50' }
          ].map((scale) => {
            const record = assessmentRecords?.find((r: any) => r.assessmentId === scale.id);
            
            return (
              <div 
                key={scale.id}
                className={`min-w-[140px] relative ${scale.wrapper} rounded-[1.25rem] p-4 border flex-shrink-0 cursor-pointer active:scale-95 transition-transform`}
                onClick={() => record ? pushView('assessment-report-detail') : pushView('mini-assessment-test')}
              >
                {record && (
                  <div className="absolute top-0 right-0 bg-primary/10 text-primary text-[10px] font-bold px-2 py-0.5 rounded-bl-lg rounded-tr-[1.25rem]">
                    已测
                  </div>
                )}
                <div className={`w-8 h-8 ${scale.color} rounded-full flex items-center justify-center mb-3`}>
                  {scale.icon}
                </div>
                <div className="text-[14px] font-bold text-gray-800 mb-1">{scale.title}</div>
                <div className="text-[11px] text-gray-500">{scale.desc}</div>
              </div>
            );
          })}
        </div>
      </div>

      {/* 缓解小工具网格 */}
      <div className="px-5 mb-10">
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-[16px] font-bold text-gray-800">缓解小工具</h2>
        </div>
        <div className="grid grid-cols-4 gap-y-6 gap-x-2">
          {[
            { name: '呼吸训练', icon: <Wind size={20} />, color: 'bg-teal-50 text-teal-600', action: () => pushView('breathing') },
            { name: '白噪音', icon: <Headphones size={20} />, color: 'bg-indigo-50 text-indigo-600', action: () => pushView('white-noise') },
            { name: '敲木鱼', icon: <Bell size={20} />, color: 'bg-amber-50 text-amber-600', action: () => pushView('muyu') },
            { name: '冥想放松', icon: <Cloud size={20} />, color: 'bg-sky-50 text-sky-600', action: () => pushView('meditation') },
            { name: '睡眠引导', icon: <Moon size={20} />, color: 'bg-blue-50 text-blue-600', action: () => pushView('sleep-guide') },
            { name: '情绪日记', icon: <Book size={20} />, color: 'bg-rose-50 text-rose-600', action: () => pushView('ai-chat') },
            { name: '捏泡泡', icon: <Smile size={20} />, color: 'bg-fuchsia-50 text-fuchsia-600', action: () => pushView('bubble-wrap') },
          ].map((tool, idx) => (
            <div 
              key={idx} 
              className="flex flex-col items-center cursor-pointer group active:scale-95 transition-transform"
              onClick={tool.action}
            >
              <div className={`w-[3.25rem] h-[3.25rem] rounded-[1.25rem] flex items-center justify-center mb-2 ${tool.color} group-hover:shadow-sm transition-all`}>
                {tool.icon}
              </div>
              <span className="text-[11px] font-medium text-gray-600">{tool.name}</span>
            </div>
          ))}
        </div>
      </div>

      {/* Calendar Detail Popover */}
      <AnimatePresence>
        {showCalendarDetail && (
          <div className="fixed inset-0 z-40 flex justify-center">
            <motion.div 
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              className="absolute inset-0 bg-transparent"
              onClick={() => setShowCalendarDetail(null)}
            />
            <motion.div
              initial={{ opacity: 0, scale: 0.9, y: 10 }}
              animate={{ opacity: 1, scale: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.9, y: 10 }}
              className="absolute top-1/2 -translate-y-1/2 bg-white rounded-[2rem] p-6 shadow-[0_10px_40px_rgba(0,0,0,0.12)] border border-gray-100 z-50 w-[280px] flex flex-col items-center"
            >
              <div className="text-gray-400 font-medium text-[13px] mb-4">6月{showCalendarDetail.date}日</div>
              <div className={`w-20 h-20 rounded-full ${showCalendarDetail.color} flex items-center justify-center text-[40px] mb-5 shadow-inner`}>
                {showCalendarDetail.emoji}
              </div>
              
              {showCalendarDetail.tags.length > 0 ? (
                <div className="flex flex-wrap justify-center gap-2 mb-2">
                  {showCalendarDetail.tags.map((tag, idx) => (
                    <span key={idx} className="bg-gray-50 text-gray-600 px-3 py-1.5 rounded-full text-[13px] font-medium border border-gray-100">
                      {tag}
                    </span>
                  ))}
                </div>
              ) : (
                <div className="text-[13px] text-gray-400 mb-2">这一天没有记录具体事情哦</div>
              )}
              
              <button 
                onClick={() => setShowCalendarDetail(null)}
                className="mt-6 bg-gray-50 text-gray-600 font-bold py-2.5 px-8 rounded-full active:scale-95 transition-transform w-full"
              >
                关闭
              </button>
            </motion.div>
          </div>
        )}
      </AnimatePresence>

      {/* 主 CTA 悬浮按钮 - 已移除，入口移至顶部栏 */}

      {/* Bottom Sheet 输入面板 (Mock) */}
      <AnimatePresence>
        {showInputSheet && (
          <div className="fixed inset-0 z-40 flex justify-center">
            <motion.div 
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              className="absolute inset-0 bg-black/40"
              onClick={() => setShowInputSheet(false)}
            />
            <motion.div
              initial={{ y: "100%" }}
              animate={{ y: 0 }}
              exit={{ y: "100%" }}
              transition={{ type: "spring", damping: 25, stiffness: 200 }}
              className="absolute bottom-0 w-full max-w-md bg-white rounded-t-[2rem] p-6 pb-12 shadow-[0_-10px_40px_rgba(0,0,0,0.1)]"
            >
              <div className="w-12 h-1.5 bg-gray-200 rounded-full mx-auto mb-6" />
              
              <h2 className="text-center text-[20px] font-black text-gray-900 mb-8">今天感觉怎么样？</h2>
              
              {/* Emoji 5级选择 */}
              <div className="flex justify-between items-center mb-10 px-2">
                {EMOTIONS.map((emo) => (
                  <button 
                    key={emo.level}
                    onClick={() => handleEmojiSelect(emo.level)}
                    className={`flex flex-col items-center transition-all ${selectedEmoji === emo.level ? 'scale-125' : (selectedEmoji ? 'opacity-40 scale-90' : 'hover:scale-110')}`}
                  >
                    <div className="text-[36px] mb-2 drop-shadow-sm">{emo.emoji}</div>
                    <span className={`text-[12px] font-bold ${selectedEmoji === emo.level ? emo.textColor : 'text-gray-400'}`}>
                      {emo.label}
                    </span>
                  </button>
                ))}
              </div>

            </motion.div>
          </div>
        )}
      </AnimatePresence>

    </motion.div>
  );
}
