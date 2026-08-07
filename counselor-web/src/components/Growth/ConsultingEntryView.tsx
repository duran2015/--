import React, { useState } from 'react';
import { 
  ArrowLeft, Sparkles, Activity, FileText, 
  ChevronRight, Brain, Heart, Clock, Users,
  CheckCircle2, ArrowRight, Share2, Plus,
  MessageSquare, Calendar, Wand2, Copy,
  QrCode, Image as ImageIcon, Settings
} from 'lucide-react';

interface ConsultingEntryViewProps {
  onBack: () => void;
}

export const ConsultingEntryView: React.FC<ConsultingEntryViewProps> = ({ onBack }) => {
  const [viewMode, setViewMode] = useState<'list' | 'create_step1' | 'create_step2' | 'generating' | 'share'>('list');
  const [entryType, setEntryType] = useState<'assessment' | 'chat' | 'booking'>('assessment');
  
  const [formState, setFormState] = useState({
    title: '职场压力指数测试',
    targetUser: '25-35岁职场人',
    questions: 15,
  });

  const mockEntries = [
    {
      id: 'e_1',
      title: '职场压力水平测试',
      type: '心理测评',
      participants: 128,
      leads: 12,
      status: 'active',
      icon: <Activity className="w-5 h-5 text-[#0842A0]" />,
      bg: 'bg-[#D3E3FD]/50'
    },
    {
      id: 'e_2',
      title: '情绪状态 AI 树洞',
      type: 'AI 对话入口',
      participants: 56,
      leads: 8,
      status: 'active',
      icon: <MessageSquare className="w-5 h-5 text-[#6750A4]" />,
      bg: 'bg-[#EADDFF]/50'
    }
  ];

  const handleGenerate = () => {
    setViewMode('generating');
    setTimeout(() => {
      setViewMode('share');
    }, 2500);
  };

  if (viewMode === 'share') {
    return (
      <div className="space-y-4 animate-in fade-in slide-in-from-bottom-4 duration-500 min-h-full pb-6">
        <div className="flex items-center gap-3 pb-2">
          <button 
            onClick={() => setViewMode('list')}
            className="w-10 h-10 flex items-center justify-center bg-white border border-[#E6E0D6] rounded-full text-[#49463D] hover:bg-[#FAF8F5] active:scale-95 transition shadow-sm"
          >
            <ArrowLeft className="w-5 h-5" />
          </button>
          <div>
            <h2 className="text-xl font-bold text-[#1D1B16] flex items-center gap-2">
              获客入口已生成 <CheckCircle2 className="w-5 h-5 text-[#2E521C]" />
            </h2>
          </div>
        </div>

        <div className="bg-white border border-[#E6E0D6] rounded-[28px] p-6 shadow-sm relative overflow-hidden">
          <div className="absolute top-0 right-0 w-32 h-32 bg-[#EADDFF]/30 rounded-full blur-3xl -mr-10 -mt-10" />
          
          <div className="text-center mb-6 relative z-10">
            <div className="w-16 h-16 bg-[#F5F5F5] rounded-[20px] mx-auto flex items-center justify-center mb-3">
              <QrCode className="w-8 h-8 text-[#49463D]" />
            </div>
            <h3 className="font-bold text-[18px] text-[#1D1B16] mb-1">{formState.title}</h3>
            <p className="text-[13px] text-[#7A756C] font-medium">专属获客链接与海报已准备就绪</p>
          </div>

          <div className="space-y-3 relative z-10 mb-6">
            <button className="w-full bg-[#FAF8F5] border border-[#ECE6DC] rounded-[20px] p-4 flex items-center justify-between group hover:border-[#D0BCFF] transition">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-full bg-white flex items-center justify-center shadow-sm text-[#49463D]">
                  <Copy className="w-4 h-4" />
                </div>
                <div className="text-left">
                  <div className="font-bold text-[14px] text-[#1D1B16]">复制分享链接</div>
                  <div className="text-[11px] text-[#7A756C] mt-0.5">用于公众号、微信群等文本场景</div>
                </div>
              </div>
              <ChevronRight className="w-5 h-5 text-[#A09C94] group-hover:text-[#6750A4] transition" />
            </button>

            <button className="w-full bg-[#FAF8F5] border border-[#ECE6DC] rounded-[20px] p-4 flex items-center justify-between group hover:border-[#D0BCFF] transition">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-full bg-white flex items-center justify-center shadow-sm text-[#49463D]">
                  <ImageIcon className="w-4 h-4" />
                </div>
                <div className="text-left">
                  <div className="font-bold text-[14px] text-[#1D1B16]">保存朋友圈海报</div>
                  <div className="text-[11px] text-[#7A756C] mt-0.5">带专属二维码的高转化海报</div>
                </div>
              </div>
              <ChevronRight className="w-5 h-5 text-[#A09C94] group-hover:text-[#6750A4] transition" />
            </button>
          </div>

          <div className="bg-[#EADDFF]/20 rounded-[20px] p-4 border border-[#D0BCFF]/50 relative z-10">
            <div className="text-[12px] font-bold text-[#4F378B] mb-2 flex items-center gap-1.5">
              <Sparkles className="w-3.5 h-3.5" /> AI 生成的分享文案
            </div>
            <p className="text-[13px] text-[#49463D] font-medium leading-relaxed mb-3">
              “最近总是感觉很累？明明没干什么体力活，却总是觉得力不从心？花 3 分钟测一测你的职场压力指数，AI 会给你一份专属的情绪处方哦~”
            </p>
            <button className="text-[12px] font-bold text-[#6750A4] bg-white px-3 py-1.5 rounded-full shadow-sm hover:bg-[#FAF8F5] transition">
              一键复制文案
            </button>
          </div>
        </div>

        <button 
          onClick={() => setViewMode('list')}
          className="w-full py-4 bg-[#6750A4] text-white rounded-full font-bold text-[16px] hover:bg-[#594294] active:scale-95 transition shadow-sm"
        >
          完成并返回
        </button>
      </div>
    );
  }

  if (viewMode === 'generating') {
    return (
      <div className="flex flex-col items-center justify-center py-32 animate-in fade-in duration-300 min-h-full">
        <div className="w-24 h-24 bg-[#EADDFF] rounded-[32px] flex items-center justify-center mb-8 relative">
          <div className="absolute inset-0 border-4 border-[#D0BCFF] rounded-[32px] animate-ping opacity-75"></div>
          <Sparkles className="w-12 h-12 text-[#6750A4] animate-pulse" />
        </div>
        <h3 className="font-bold text-[20px] text-[#1D1B16] mb-3">AI 正在生成获客入口...</h3>
        <p className="text-[14px] text-[#7A756C] font-medium animate-pulse text-center px-6 leading-relaxed">
          正在为你生成专业的测评题目<br/>并配置自动分析模型与转化引导话术
        </p>
        <div className="w-64 bg-[#E7E0EC] h-2 rounded-full mt-10 overflow-hidden">
          <div className="bg-[#6750A4] h-full rounded-full w-1/2 animate-[progress_2s_ease-in-out_infinite]"></div>
        </div>
      </div>
    );
  }

  if (viewMode === 'create_step2') {
    return (
      <div className="space-y-4 animate-in fade-in slide-in-from-right-4 duration-300 min-h-full pb-6">
        <div className="flex items-center gap-3 pb-2">
          <button 
            onClick={() => setViewMode('create_step1')}
            className="w-10 h-10 flex items-center justify-center bg-white border border-[#E6E0D6] rounded-full text-[#49463D] hover:bg-[#FAF8F5] active:scale-95 transition shadow-sm"
          >
            <ArrowLeft className="w-5 h-5" />
          </button>
          <div>
            <h2 className="text-xl font-bold text-[#1D1B16] flex items-center gap-2">
              设置入口内容
            </h2>
          </div>
        </div>

        <div className="bg-white border border-[#E6E0D6] rounded-[28px] p-6 shadow-sm space-y-5">
          <div>
            <label className="block text-[13px] font-bold text-[#49463D] mb-2">获客工具标题</label>
            <input 
              type="text" 
              value={formState.title}
              onChange={e => setFormState({...formState, title: e.target.value})}
              className="w-full bg-[#FAF8F5] border border-[#ECE6DC] rounded-[16px] px-4 py-3 text-[14px] text-[#1D1B16] font-bold focus:outline-none focus:border-[#D0BCFF] focus:ring-1 focus:ring-[#D0BCFF]"
              placeholder="例如：职场压力指数测试"
            />
          </div>

          <div>
            <label className="block text-[13px] font-bold text-[#49463D] mb-2">适用目标人群</label>
            <input 
              type="text" 
              value={formState.targetUser}
              onChange={e => setFormState({...formState, targetUser: e.target.value})}
              className="w-full bg-[#FAF8F5] border border-[#ECE6DC] rounded-[16px] px-4 py-3 text-[14px] text-[#1D1B16] font-bold focus:outline-none focus:border-[#D0BCFF] focus:ring-1 focus:ring-[#D0BCFF]"
              placeholder="例如：25-35岁职场人"
            />
          </div>

          <div>
            <label className="block text-[13px] font-bold text-[#49463D] mb-2">测评问题数量 (AI生成)</label>
            <div className="flex gap-2">
              {[5, 10, 15, 20].map(num => (
                <button
                  key={num}
                  onClick={() => setFormState({...formState, questions: num})}
                  className={`flex-1 py-2 rounded-[12px] font-bold text-[13px] transition ${
                    formState.questions === num
                      ? 'bg-[#EADDFF] text-[#4F378B] border border-[#D0BCFF]'
                      : 'bg-white border border-[#E6E0D6] text-[#7A756C] hover:bg-[#FAF8F5]'
                  }`}
                >
                  {num} 题
                </button>
              ))}
            </div>
            <p className="text-[11px] text-[#A09C94] font-medium mt-2">建议 10-15 题，体验最佳，放弃率最低。</p>
          </div>

          <div className="bg-[#FAF8F5] p-4 rounded-[20px] border border-[#ECE6DC] mt-4">
            <div className="text-[12px] font-bold text-[#1D1B16] mb-2 flex items-center gap-1.5">
              <Settings className="w-4 h-4 text-[#A09C94]" /> 自动转化设置
            </div>
            <div className="flex items-center justify-between">
              <span className="text-[13px] text-[#49463D] font-medium">要求用户留下联系方式查看结果</span>
              <div className="w-10 h-6 bg-[#6750A4] rounded-full relative cursor-pointer">
                <div className="w-5 h-5 bg-white rounded-full absolute top-0.5 right-0.5 shadow-sm"></div>
              </div>
            </div>
          </div>
        </div>

        <button 
          onClick={handleGenerate}
          className="w-full py-4 bg-[#6750A4] text-white rounded-full font-bold text-[16px] hover:bg-[#594294] active:scale-95 transition shadow-sm flex items-center justify-center gap-2"
        >
          <Wand2 className="w-5 h-5" /> AI 生成完整工具
        </button>
      </div>
    );
  }

  if (viewMode === 'create_step1') {
    return (
      <div className="space-y-4 animate-in fade-in slide-in-from-right-4 duration-300 min-h-full pb-6">
        <div className="flex items-center gap-3 pb-2">
          <button 
            onClick={() => setViewMode('list')}
            className="w-10 h-10 flex items-center justify-center bg-white border border-[#E6E0D6] rounded-full text-[#49463D] hover:bg-[#FAF8F5] active:scale-95 transition shadow-sm"
          >
            <ArrowLeft className="w-5 h-5" />
          </button>
          <div>
            <h2 className="text-xl font-bold text-[#1D1B16] flex items-center gap-2">
              选择获客入口类型
            </h2>
          </div>
        </div>

        <div className="space-y-3">
          {/* 心理测评 */}
          <button 
            onClick={() => { setEntryType('assessment'); setViewMode('create_step2'); }}
            className="w-full bg-white border border-[#E6E0D6] rounded-[24px] p-5 shadow-sm hover:border-[#D0BCFF] transition text-left group flex items-start gap-4 active:scale-95"
          >
            <div className="w-14 h-14 rounded-[16px] bg-[#D3E3FD]/50 flex items-center justify-center shrink-0 group-hover:scale-110 transition">
              <Activity className="w-6 h-6 text-[#0842A0]" />
            </div>
            <div className="flex-1 min-w-0">
              <h4 className="font-bold text-[16px] text-[#1D1B16] mb-1">心理测评</h4>
              <p className="text-[12px] text-[#7A756C] font-medium leading-relaxed">
                如压力测试、焦虑测试。转化率最高，门槛最低的获客方式。
              </p>
            </div>
            <ChevronRight className="w-5 h-5 text-[#A09C94] group-hover:text-[#6750A4] transition shrink-0 mt-4" />
          </button>

          {/* AI 对话 */}
          <button 
            onClick={() => { setEntryType('chat'); setViewMode('create_step2'); }}
            className="w-full bg-white border border-[#E6E0D6] rounded-[24px] p-5 shadow-sm hover:border-[#D0BCFF] transition text-left group flex items-start gap-4 active:scale-95"
          >
            <div className="w-14 h-14 rounded-[16px] bg-[#EADDFF]/50 flex items-center justify-center shrink-0 group-hover:scale-110 transition">
              <MessageSquare className="w-6 h-6 text-[#6750A4]" />
            </div>
            <div className="flex-1 min-w-0">
              <h4 className="font-bold text-[16px] text-[#1D1B16] mb-1">AI 倾诉入口</h4>
              <p className="text-[12px] text-[#7A756C] font-medium leading-relaxed">
                如“聊聊你的最近状态”。通过 AI 引导用户表达情绪并收集线索。
              </p>
            </div>
            <ChevronRight className="w-5 h-5 text-[#A09C94] group-hover:text-[#6750A4] transition shrink-0 mt-4" />
          </button>

          {/* 咨询预约 */}
          <button 
            onClick={() => { setEntryType('booking'); setViewMode('create_step2'); }}
            className="w-full bg-white border border-[#E6E0D6] rounded-[24px] p-5 shadow-sm hover:border-[#D0BCFF] transition text-left group flex items-start gap-4 active:scale-95"
          >
            <div className="w-14 h-14 rounded-[16px] bg-[#C4EED0]/50 flex items-center justify-center shrink-0 group-hover:scale-110 transition">
              <Calendar className="w-6 h-6 text-[#003912]" />
            </div>
            <div className="flex-1 min-w-0">
              <h4 className="font-bold text-[16px] text-[#1D1B16] mb-1">直接咨询预约</h4>
              <p className="text-[12px] text-[#7A756C] font-medium leading-relaxed">
                如“首次咨询申请表”。适合放在个人主页或文章底部的强意向转化。
              </p>
            </div>
            <ChevronRight className="w-5 h-5 text-[#A09C94] group-hover:text-[#6750A4] transition shrink-0 mt-4" />
          </button>
        </div>
      </div>
    );
  }

  // viewMode === 'list'
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
            我的获客入口 <Sparkles className="w-5 h-5 text-[#6750A4]" />
          </h2>
          <p className="text-[13px] text-[#7A756C] font-medium mt-0.5">创建低门槛工具，高效收集咨询线索</p>
        </div>
      </div>

      <div className="bg-[#EADDFF]/40 border border-[#D0BCFF] rounded-[24px] p-5 shadow-sm">
        <div className="flex items-center justify-between mb-2">
          <h3 className="font-bold text-[15px] text-[#1D1B16]">累计获客数据</h3>
          <span className="text-[12px] bg-white px-2 py-1 rounded-md font-bold text-[#6750A4] shadow-sm">近 30 天</span>
        </div>
        <div className="grid grid-cols-2 gap-4 mt-4">
          <div>
            <div className="text-[12px] text-[#49463D] font-medium mb-1">总参与人数</div>
            <div className="text-2xl font-bold text-[#21005D] font-mono">184</div>
          </div>
          <div>
            <div className="text-[12px] text-[#49463D] font-medium mb-1">收集意向线索</div>
            <div className="text-2xl font-bold text-[#21005D] font-mono">20</div>
          </div>
        </div>
      </div>

      <div>
        <div className="flex items-center justify-between mb-3 ml-1 mt-2">
          <h3 className="font-bold text-[16px] text-[#1D1B16] tracking-tight">已有的获客入口</h3>
        </div>
        <div className="space-y-3">
          {mockEntries.map((entry) => (
            <div 
              key={entry.id}
              className="bg-white border border-[#E6E0D6] rounded-[24px] p-4 shadow-sm hover:border-[#D0BCFF] transition flex items-center gap-4"
            >
              <div className={`w-12 h-12 rounded-[14px] ${entry.bg} flex items-center justify-center shrink-0`}>
                {entry.icon}
              </div>
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-2 mb-1">
                  <h4 className="font-bold text-[15px] text-[#1D1B16] truncate">{entry.title}</h4>
                  <span className="text-[10px] bg-[#F5F5F5] text-[#7A756C] px-1.5 py-0.5 rounded-sm font-bold shrink-0">{entry.type}</span>
                </div>
                <div className="flex items-center gap-3 text-[11px] text-[#A09C94] font-bold mt-1.5">
                  <span className="flex items-center gap-1"><Users className="w-3 h-3" /> {entry.participants} 人参与</span>
                  <span className="flex items-center gap-1 text-[#6750A4]"><Activity className="w-3 h-3" /> {entry.leads} 条线索</span>
                </div>
              </div>
              <button className="w-8 h-8 rounded-full bg-[#FAF8F5] flex items-center justify-center text-[#49463D] hover:bg-[#EAE5DB] transition shrink-0">
                <Share2 className="w-4 h-4" />
              </button>
            </div>
          ))}
        </div>
      </div>

      <div className="pt-2">
        <button 
          onClick={() => setViewMode('create_step1')}
          className="w-full py-4 bg-[#6750A4] text-white rounded-full font-bold text-[16px] hover:bg-[#594294] active:scale-95 transition shadow-sm flex items-center justify-center gap-2"
        >
          <Plus className="w-5 h-5" /> 创建新入口
        </button>
      </div>
      
    </div>
  );
};
