import React, { useState } from 'react';
import { 
  ArrowLeft, Sparkles, Calendar as CalendarIcon, 
  Target, Globe, Clock, CheckCircle2, 
  ChevronRight, Lightbulb, Plus, PlayCircle,
  FileText, PenTool, LayoutTemplate
} from 'lucide-react';

interface PublishPlanViewProps {
  onBack: () => void;
  onGoToContentGenerator: () => void;
}

export const PublishPlanView: React.FC<PublishPlanViewProps> = ({ onBack, onGoToContentGenerator }) => {
  const [step, setStep] = useState<'create' | 'generating' | 'calendar'>('create');

  // Form State
  const [direction, setDirection] = useState('职场心理');
  const [goal, setGoal] = useState('获得咨询客户');
  const [platforms, setPlatforms] = useState<string[]>(['小红书']);
  const [frequency, setFrequency] = useState('每周3次');

  const togglePlatform = (p: string) => {
    setPlatforms(prev => 
      prev.includes(p) ? prev.filter(item => item !== p) : [...prev, p]
    );
  };

  const handleGenerate = () => {
    setStep('generating');
    setTimeout(() => {
      setStep('calendar');
    }, 2000);
  };

  const CreatePlanView = () => (
    <div className="space-y-6 animate-in fade-in duration-300">
      <div className="bg-white border border-[#E6E0D6] rounded-[28px] p-5 shadow-sm space-y-6">
        {/* 方向 */}
        <div>
          <h3 className="font-bold text-[15px] text-[#1D1B16] mb-3 tracking-tight flex items-center gap-2">
            <Target className="w-4 h-4 text-[#6750A4]" /> 我的方向
          </h3>
          <div className="flex flex-wrap gap-2">
            {['职场心理', '亲密关系', '个人成长', '情绪管理'].map(d => (
              <button
                key={d}
                onClick={() => setDirection(d)}
                className={`px-4 py-2 rounded-full border transition text-[13px] active:scale-95 ${
                  direction === d
                    ? 'bg-[#EADDFF] border-[#D0BCFF] text-[#4F378B] font-bold'
                    : 'bg-[#FAF8F5] border-[#ECE6DC] text-[#7A756C] hover:bg-[#EAE5DB] font-medium'
                }`}
              >
                {d}
              </button>
            ))}
          </div>
        </div>

        {/* 目标 */}
        <div>
          <h3 className="font-bold text-[15px] text-[#1D1B16] mb-3 tracking-tight flex items-center gap-2">
            <Sparkles className="w-4 h-4 text-[#6750A4]" /> 内容目标
          </h3>
          <div className="flex flex-wrap gap-2">
            {['提升曝光', '获得咨询客户', '建立专业背书', '社群活跃'].map(g => (
              <button
                key={g}
                onClick={() => setGoal(g)}
                className={`px-4 py-2 rounded-full border transition text-[13px] active:scale-95 ${
                  goal === g
                    ? 'bg-[#EADDFF] border-[#D0BCFF] text-[#4F378B] font-bold'
                    : 'bg-[#FAF8F5] border-[#ECE6DC] text-[#7A756C] hover:bg-[#EAE5DB] font-medium'
                }`}
              >
                {g}
              </button>
            ))}
          </div>
        </div>

        {/* 平台 */}
        <div>
          <h3 className="font-bold text-[15px] text-[#1D1B16] mb-3 tracking-tight flex items-center gap-2">
            <Globe className="w-4 h-4 text-[#6750A4]" /> 分发平台 (多选)
          </h3>
          <div className="flex flex-wrap gap-2">
            {['小红书', '朋友圈', '公众号', '视频号'].map(p => (
              <button
                key={p}
                onClick={() => togglePlatform(p)}
                className={`px-4 py-2 rounded-full border transition text-[13px] active:scale-95 ${
                  platforms.includes(p)
                    ? 'bg-[#EADDFF] border-[#D0BCFF] text-[#4F378B] font-bold'
                    : 'bg-[#FAF8F5] border-[#ECE6DC] text-[#7A756C] hover:bg-[#EAE5DB] font-medium'
                }`}
              >
                {p}
              </button>
            ))}
          </div>
        </div>

        {/* 频率 */}
        <div>
          <h3 className="font-bold text-[15px] text-[#1D1B16] mb-3 tracking-tight flex items-center gap-2">
            <Clock className="w-4 h-4 text-[#6750A4]" /> 更新频率
          </h3>
          <div className="flex flex-wrap gap-2">
            {['每周1次', '每周3次', '工作日日更', '每日更新'].map(f => (
              <button
                key={f}
                onClick={() => setFrequency(f)}
                className={`px-4 py-2 rounded-full border transition text-[13px] active:scale-95 ${
                  frequency === f
                    ? 'bg-[#EADDFF] border-[#D0BCFF] text-[#4F378B] font-bold'
                    : 'bg-[#FAF8F5] border-[#ECE6DC] text-[#7A756C] hover:bg-[#EAE5DB] font-medium'
                }`}
              >
                {f}
              </button>
            ))}
          </div>
        </div>
      </div>

      <button 
        onClick={handleGenerate}
        className="w-full py-3.5 bg-[#6750A4] text-white rounded-full font-bold text-[16px] hover:bg-[#594294] active:scale-95 transition shadow-sm flex items-center justify-center gap-2"
      >
        <LayoutTemplate className="w-5 h-5" /> 生成专属内容日历
      </button>
    </div>
  );

  const GeneratingView = () => (
    <div className="flex flex-col items-center justify-center py-20 animate-in fade-in duration-300">
      <div className="w-20 h-20 bg-[#EADDFF] rounded-full flex items-center justify-center mb-6 relative">
        <div className="absolute inset-0 border-4 border-[#D0BCFF] rounded-full animate-ping opacity-75"></div>
        <CalendarIcon className="w-8 h-8 text-[#6750A4] animate-pulse" />
      </div>
      <h3 className="font-bold text-[18px] text-[#1D1B16] mb-2">正在排布内容节奏...</h3>
      <p className="text-[14px] text-[#7A756C] font-medium animate-pulse">结合「{goal}」目标智能规划选题</p>
      
      <div className="w-64 bg-[#E7E0EC] h-2 rounded-full mt-8 overflow-hidden">
        <div className="bg-[#6750A4] h-full rounded-full w-1/2 animate-[progress_2s_ease-in-out_infinite]"></div>
      </div>
    </div>
  );

  const CalendarView = () => (
    <div className="space-y-4 animate-in fade-in slide-in-from-bottom-4 duration-300">
      
      {/* AI 运营建议 */}
      <div className="bg-[#FAF8F5] border border-[#ECE6DC] rounded-[28px] p-5 shadow-sm">
        <div className="flex items-start gap-3">
          <div className="mt-0.5">
            <Lightbulb className="w-5 h-5 text-[#B3261E]" />
          </div>
          <div>
            <h3 className="font-bold text-[15px] text-[#1D1B16] mb-1">AI 运营洞察</h3>
            <p className="text-[13px] text-[#7A756C] font-medium leading-relaxed mb-2">
              分析发现你近期的规划 80% 集中在理论科普。为了达成「获得咨询客户」的目标，建议增加个人故事类内容以建立情感链接。
            </p>
            <div className="bg-white rounded-xl p-3 border border-[#E6E0D6] flex items-center justify-between">
              <div className="flex items-center gap-2">
                <span className="text-[12px] bg-[#FFDF99] text-[#7A2E0E] px-2 py-0.5 rounded-md font-bold">本周推荐</span>
                <span className="text-[13px] font-bold text-[#1D1B16]">咨询案例匿名复盘</span>
              </div>
              <button 
                onClick={onGoToContentGenerator}
                className="text-[12px] text-[#6750A4] font-bold hover:underline"
              >
                立即创作
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* 日历头部 */}
      <div className="flex items-center justify-between px-1">
        <h3 className="font-bold text-[16px] text-[#1D1B16] tracking-tight">8月第一周计划</h3>
        <div className="flex gap-2">
          <button className="text-[12px] text-[#49463D] font-bold bg-white border border-[#E6E0D6] px-3 py-1.5 rounded-full hover:bg-[#FAF8F5]">
            导出为日历
          </button>
        </div>
      </div>

      {/* 任务列表 */}
      <div className="space-y-3">
        {/* Task 1: 待创作 */}
        <div className="bg-white border border-[#E6E0D6] rounded-[24px] p-5 shadow-sm relative overflow-hidden group">
          <div className="absolute left-0 top-0 bottom-0 w-1.5 bg-[#6750A4]"></div>
          <div className="flex justify-between items-start mb-3">
            <div className="flex items-center gap-2">
              <span className="font-bold text-[16px] text-[#1D1B16]">周一</span>
              <span className="text-[12px] text-[#7A756C] font-medium">8月5日</span>
            </div>
            <span className="text-[11px] bg-[#EADDFF] text-[#4F378B] px-2 py-0.5 rounded-md font-bold border border-[#D0BCFF]">待创作</span>
          </div>
          
          <h4 className="font-bold text-[15px] text-[#1D1B16] mb-2 leading-snug">
            为什么成年人容易精神内耗？
          </h4>
          
          <div className="flex items-center gap-2 mb-4">
            <span className="text-[11px] font-medium text-[#49463D] bg-[#F5F5F5] px-2 py-1 rounded flex items-center gap-1">
              <PenTool className="w-3 h-3" /> 小红书笔记
            </span>
            <span className="text-[11px] font-medium text-[#49463D] bg-[#F5F5F5] px-2 py-1 rounded flex items-center gap-1">
              <Target className="w-3 h-3" /> 痛点共鸣
            </span>
          </div>
          
          <button 
            onClick={onGoToContentGenerator}
            className="w-full bg-[#FAF8F5] border border-[#ECE6DC] text-[#49463D] font-bold text-[13px] py-2.5 rounded-xl hover:bg-[#EAE5DB] hover:text-[#1D1B16] transition flex items-center justify-center gap-1"
          >
            <Sparkles className="w-4 h-4 text-[#6750A4]" /> 让 AI 帮我写
          </button>
        </div>

        {/* Task 2: 已完成 */}
        <div className="bg-white border border-[#E6E0D6] rounded-[24px] p-5 shadow-sm relative overflow-hidden opacity-75">
          <div className="absolute left-0 top-0 bottom-0 w-1.5 bg-[#C4EED0]"></div>
          <div className="flex justify-between items-start mb-3">
            <div className="flex items-center gap-2">
              <span className="font-bold text-[16px] text-[#1D1B16]">周三</span>
              <span className="text-[12px] text-[#7A756C] font-medium">8月7日</span>
            </div>
            <span className="text-[11px] bg-[#F4F8F4] text-[#132C0B] px-2 py-0.5 rounded-md font-bold border border-[#C4EED0]">已发布</span>
          </div>
          
          <h4 className="font-bold text-[15px] text-[#1D1B16] mb-2 leading-snug line-through text-[#7A756C]">
            3个方法，建立你的情绪缓冲带
          </h4>
          
          <div className="flex items-center gap-2">
            <span className="text-[11px] font-medium text-[#7A756C] bg-[#F5F5F5] px-2 py-1 rounded flex items-center gap-1">
              <PlayCircle className="w-3 h-3" /> 短视频
            </span>
          </div>
        </div>

        {/* Task 3: 创作中 */}
        <div className="bg-white border border-[#E6E0D6] rounded-[24px] p-5 shadow-sm relative overflow-hidden">
          <div className="absolute left-0 top-0 bottom-0 w-1.5 bg-[#FFDF99]"></div>
          <div className="flex justify-between items-start mb-3">
            <div className="flex items-center gap-2">
              <span className="font-bold text-[16px] text-[#1D1B16]">周五</span>
              <span className="text-[12px] text-[#7A756C] font-medium">8月9日</span>
            </div>
            <span className="text-[11px] bg-[#FFF8E6] text-[#7A2E0E] px-2 py-0.5 rounded-md font-bold border border-[#FFDF99]">草稿箱</span>
          </div>
          
          <h4 className="font-bold text-[15px] text-[#1D1B16] mb-2 leading-snug">
            来访者故事：那个总觉得配不上赞美的女孩
          </h4>
          
          <div className="flex items-center gap-2 mb-4">
            <span className="text-[11px] font-medium text-[#49463D] bg-[#F5F5F5] px-2 py-1 rounded flex items-center gap-1">
              <FileText className="w-3 h-3" /> 公众号文章
            </span>
          </div>
          
          <button 
            onClick={onGoToContentGenerator}
            className="w-full bg-[#FAF8F5] border border-[#ECE6DC] text-[#49463D] font-bold text-[13px] py-2.5 rounded-xl hover:bg-[#EAE5DB] hover:text-[#1D1B16] transition"
          >
            继续编辑
          </button>
        </div>
      </div>
      
      <button className="w-full py-4 border-2 border-dashed border-[#ECE6DC] text-[#7A756C] rounded-[24px] font-bold text-[14px] hover:bg-[#FAF8F5] transition flex items-center justify-center gap-1">
        <Plus className="w-4 h-4" /> 手动添加任务
      </button>

    </div>
  );

  return (
    <div className="space-y-4 animate-in fade-in slide-in-from-right-4 duration-300 min-h-full pb-6">
      {/* Header */}
      <div className="flex items-center gap-3 pb-2">
        <button 
          onClick={onBack}
          className="w-10 h-10 flex items-center justify-center bg-white border border-[#E6E0D6] rounded-full text-[#49463D] hover:bg-[#FAF8F5] active:scale-95 transition shadow-sm"
        >
          <ArrowLeft className="w-5 h-5" />
        </button>
        <div>
          <h2 className="text-xl font-bold text-[#1D1B16] flex items-center gap-2">
            发布计划 <CalendarIcon className="w-5 h-5 text-[#6750A4]" />
          </h2>
          <p className="text-[13px] text-[#7A756C] font-medium mt-0.5">你的智能内容运营日历</p>
        </div>
      </div>

      {step === 'create' && <CreatePlanView />}
      {step === 'generating' && <GeneratingView />}
      {step === 'calendar' && <CalendarView />}
      
    </div>
  );
};
