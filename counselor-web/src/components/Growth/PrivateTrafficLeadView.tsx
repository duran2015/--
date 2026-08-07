import React, { useState } from 'react';
import { 
  ArrowLeft, Sparkles, UserCircle, Edit3, 
  CheckCircle2, Share2, FileText, Bookmark, 
  ChevronRight, Wand2, Star, ShieldCheck,
  MessageCircle
} from 'lucide-react';

interface PrivateTrafficLeadViewProps {
  onBack: () => void;
}

export const PrivateTrafficLeadView: React.FC<PrivateTrafficLeadViewProps> = ({ onBack }) => {
  const [isEditing, setIsEditing] = useState(false);
  const [isOptimizing, setIsOptimizing] = useState(false);
  
  // Profile State
  const [profile, setProfile] = useState({
    name: '林木青',
    title: '职场心理咨询师',
    oneLiner: '专注帮助职场女性缓解焦虑与内耗的心理咨询师。',
    bio: '从事心理咨询工作8年，累计咨询时长超2000小时。擅长认知行为疗法（CBT）与焦点解决短程疗法（SFBT）。我相信每个身处内耗中的人，都拥有自我治愈的力量。在我的咨询室里，你不需要假装坚强。',
    targetAudience: '25-35岁城市职场女性',
    specialties: ['职场焦虑', '情绪内耗', '职业倦怠', '完美主义'],
    serviceMethods: ['50分钟视频咨询', '15分钟语音倾听'],
    philosophy: '温和而坚定地陪伴，提供清晰可执行的行动建议。'
  });

  const handleAIOptimize = () => {
    setIsOptimizing(true);
    // Mock AI delay
    setTimeout(() => {
      setProfile(prev => ({
        ...prev,
        oneLiner: '专注破解“完美主义陷阱”，帮助高压职场女性走出焦虑内耗的资深心理咨询师。',
        bio: '拥有8年临床经验与2000+小时咨询积累。我特别理解大厂与高压行业女性面临的“既要又要”的困境。我擅长将复杂的心理学理论转化为实用的CBT认知工具，不只提供情绪价值，更提供切实可行的破局策略。',
      }));
      setIsOptimizing(false);
    }, 2000);
  };

  return (
    <div className="space-y-4 animate-in fade-in slide-in-from-right-4 duration-300 min-h-full pb-6">
      {/* Header */}
      <div className="flex items-center justify-between pb-2">
        <div className="flex items-center gap-3">
          <button 
            onClick={onBack}
            className="w-10 h-10 flex items-center justify-center bg-white border border-[#E6E0D6] rounded-full text-[#49463D] hover:bg-[#FAF8F5] active:scale-95 transition shadow-sm"
          >
            <ArrowLeft className="w-5 h-5" />
          </button>
          <div>
            <h2 className="text-xl font-bold text-[#1D1B16] flex items-center gap-2">
              我的咨询主页 <Sparkles className="w-5 h-5 text-[#6750A4]" />
            </h2>
            <p className="text-[13px] text-[#7A756C] font-medium mt-0.5">私域引流与个人品牌展示中心</p>
          </div>
        </div>
        <button className="w-10 h-10 flex items-center justify-center bg-[#EADDFF] text-[#4F378B] rounded-full hover:bg-[#D0BCFF] active:scale-95 transition">
          <Share2 className="w-5 h-5" />
        </button>
      </div>

      {/* Main Profile Card */}
      <div className="bg-white border border-[#E6E0D6] rounded-[28px] overflow-hidden shadow-sm relative">
        {/* Cover Photo / Gradient */}
        <div className="h-24 bg-gradient-to-r from-[#EADDFF] to-[#F3EDF7] relative">
          <button 
            onClick={() => setIsEditing(!isEditing)}
            className="absolute top-4 right-4 bg-white/50 backdrop-blur-md p-2 rounded-full text-[#4F378B] hover:bg-white/80 transition"
          >
            <Edit3 className="w-4 h-4" />
          </button>
        </div>
        
        <div className="px-6 pb-6 relative">
          {/* Avatar */}
          <div className="w-20 h-20 rounded-full border-4 border-white bg-[#FAF8F5] flex items-center justify-center -mt-10 mb-3 shadow-sm overflow-hidden">
            <img src="https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150&auto=format&fit=crop&q=80" alt="Avatar" className="w-full h-full object-cover" />
          </div>

          <div className="flex items-start justify-between mb-1">
            <div>
              <h3 className="text-xl font-bold text-[#1D1B16] flex items-center gap-1.5">
                {profile.name} <ShieldCheck className="w-5 h-5 text-[#2E521C]" />
              </h3>
              <div className="text-[13px] font-bold text-[#6750A4]">{profile.title}</div>
            </div>
          </div>
          
          <p className="text-[14px] text-[#49463D] font-medium mt-3 mb-4 leading-relaxed">
            {profile.oneLiner}
          </p>

          <div className="flex flex-wrap gap-2 mb-6">
            {profile.specialties.map(tag => (
              <span key={tag} className="text-[11px] font-bold px-2.5 py-1 rounded-md bg-[#F5F5F5] text-[#49463D]">
                {tag}
              </span>
            ))}
          </div>

          {/* AI Optimize Button */}
          <div className="bg-[#FAF8F5] border border-[#ECE6DC] rounded-[20px] p-4 relative overflow-hidden">
            <div className="absolute top-0 right-0 w-24 h-24 bg-[#EADDFF]/40 rounded-full blur-2xl -mr-10 -mt-10" />
            
            <div className="flex items-start justify-between mb-2 relative z-10">
              <div className="flex items-center gap-2 text-[#6750A4] font-bold text-[13px]">
                <Sparkles className="w-4 h-4" /> AI 主页优化建议
              </div>
              <button 
                onClick={handleAIOptimize}
                disabled={isOptimizing}
                className="text-[12px] bg-[#6750A4] text-white px-3 py-1.5 rounded-full font-bold hover:bg-[#594294] transition flex items-center gap-1 disabled:opacity-50"
              >
                {isOptimizing ? <span className="animate-pulse">优化中...</span> : <><Wand2 className="w-3 h-3" /> 一键升级简介</>}
              </button>
            </div>
            <p className="text-[12px] text-[#7A756C] font-medium relative z-10 leading-relaxed">
              分析发现，你的介绍偏向传统格式。建议增加“完美主义陷阱”等痛点词汇，更能击中职场女性的共鸣，提升转化率。
            </p>
          </div>
        </div>
      </div>

      {/* Detailed Info Cards */}
      <div className="grid grid-cols-1 gap-3">
        <div className="bg-white border border-[#E6E0D6] rounded-[24px] p-5 shadow-sm">
          <h4 className="font-bold text-[15px] text-[#1D1B16] mb-3 flex items-center gap-2">
            <UserCircle className="w-4 h-4 text-[#A09C94]" /> 个人简介
          </h4>
          {isEditing ? (
            <textarea 
              className="w-full bg-[#FAF8F5] border border-[#ECE6DC] rounded-[16px] p-3 text-[13px] text-[#49463D] focus:outline-none focus:border-[#D0BCFF] focus:ring-1 focus:ring-[#D0BCFF]"
              rows={4}
              value={profile.bio}
              onChange={(e) => setProfile({...profile, bio: e.target.value})}
            />
          ) : (
            <p className="text-[13px] text-[#49463D] leading-relaxed font-medium">
              {profile.bio}
            </p>
          )}
        </div>

        <div className="grid grid-cols-2 gap-3">
          <div className="bg-white border border-[#E6E0D6] rounded-[24px] p-5 shadow-sm">
            <h4 className="font-bold text-[13px] text-[#7A756C] mb-2">主要服务人群</h4>
            <div className="font-bold text-[14px] text-[#1D1B16]">{profile.targetAudience}</div>
          </div>
          <div className="bg-white border border-[#E6E0D6] rounded-[24px] p-5 shadow-sm">
            <h4 className="font-bold text-[13px] text-[#7A756C] mb-2">咨询风格理念</h4>
            <div className="font-bold text-[14px] text-[#1D1B16] leading-snug">{profile.philosophy}</div>
          </div>
        </div>
      </div>

      {/* Content Assets on Profile */}
      <div className="bg-white border border-[#E6E0D6] rounded-[28px] p-5 shadow-sm mt-4">
        <div className="flex items-center justify-between mb-4">
          <h3 className="font-bold text-[16px] text-[#1D1B16] tracking-tight">主页内容展示</h3>
          <span className="text-[12px] text-[#7A756C] font-medium">对外可见的内容资产</span>
        </div>
        
        <div className="space-y-3">
          <div className="flex gap-3 bg-[#FAF8F5] p-3 rounded-[20px] border border-[#ECE6DC]">
            <div className="w-16 h-16 rounded-[12px] bg-[#EADDFF]/30 flex items-center justify-center shrink-0">
              <FileText className="w-6 h-6 text-[#6750A4]" />
            </div>
            <div className="flex-1 min-w-0 flex flex-col justify-center">
              <h4 className="font-bold text-[14px] text-[#1D1B16] truncate mb-1">《为什么越优秀的人越容易焦虑？》</h4>
              <div className="flex items-center gap-3 text-[11px] text-[#A09C94] font-medium">
                <span className="flex items-center gap-1"><Star className="w-3 h-3" /> 128 收藏</span>
                <span className="flex items-center gap-1"><MessageCircle className="w-3 h-3" /> 45 咨询转化</span>
              </div>
            </div>
          </div>

          <div className="flex gap-3 bg-[#FAF8F5] p-3 rounded-[20px] border border-[#ECE6DC]">
            <div className="w-16 h-16 rounded-[12px] bg-[#D3E3FD]/30 flex items-center justify-center shrink-0">
              <FileText className="w-6 h-6 text-[#0842A0]" />
            </div>
            <div className="flex-1 min-w-0 flex flex-col justify-center">
              <h4 className="font-bold text-[14px] text-[#1D1B16] truncate mb-1">《自测：你是否正处于情绪耗竭状态？》</h4>
              <div className="flex items-center gap-3 text-[11px] text-[#A09C94] font-medium">
                <span className="flex items-center gap-1"><Star className="w-3 h-3" /> 89 收藏</span>
                <span className="flex items-center gap-1"><MessageCircle className="w-3 h-3" /> 12 咨询转化</span>
              </div>
            </div>
          </div>
        </div>

        <button className="w-full mt-3 py-3 border border-[#E6E0D6] text-[#49463D] font-bold text-[13px] rounded-[16px] hover:bg-[#FAF8F5] transition flex items-center justify-center gap-1">
          管理展示内容 <ChevronRight className="w-4 h-4" />
        </button>
      </div>

      <div className="pt-2">
        <button className="w-full py-4 bg-[#6750A4] text-white rounded-full font-bold text-[16px] hover:bg-[#594294] active:scale-95 transition shadow-sm flex items-center justify-center gap-2">
          预览用户视角
        </button>
      </div>
      
    </div>
  );
};
