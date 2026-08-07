import React, { useState } from 'react';
import { 
  Sparkles, CheckCircle2, ChevronRight, 
  Lightbulb, FileText, Calendar, 
  Users, MessageSquare, Globe, Heart, Share2,
  X, Link as LinkIcon, Image as ImageIcon, Download
} from 'lucide-react';
import { ConsultantProfile, ViralVoucher } from '../../types';
import { TopicInspirationView } from './TopicInspirationView';
import { ContentGeneratorView } from './ContentGeneratorView';
import { PublishPlanView } from './PublishPlanView';
import { PrivateTrafficLeadView } from './PrivateTrafficLeadView';
import { ConsultingEntryView } from './ConsultingEntryView';

interface GrowthTabProps {
  consultant: ConsultantProfile;
  vouchers: ViralVoucher[];
  onAddVoucher: (voucher: ViralVoucher) => void;
  onSubPageChange?: (isSubPage: boolean) => void;
  onNavigateToProfile?: () => void;
}

export const GrowthTab: React.FC<GrowthTabProps> = ({
  consultant,
  vouchers,
  onAddVoucher,
  onSubPageChange,
  onNavigateToProfile
}) => {
  const [viewMode, setViewMode] = useState<'main' | 'topic_inspiration' | 'content_generator' | 'publish_plan' | 'private_traffic' | 'consulting_entry'>('main');
  const [passedTopic, setPassedTopic] = useState<string | undefined>();
  const [showShareModal, setShowShareModal] = useState(false);
  const [showPosterModal, setShowPosterModal] = useState(false);
  const [completionRate, setCompletionRate] = useState((consultant as any).completionRate || 80);

  React.useEffect(() => {
    setCompletionRate((consultant as any).completionRate || 80);
  }, [(consultant as any).completionRate]);

  React.useEffect(() => {
    if (onSubPageChange) {
      onSubPageChange(viewMode !== 'main');
    }
  }, [viewMode, onSubPageChange]);

  if (viewMode === 'consulting_entry') {
    return <ConsultingEntryView onBack={() => setViewMode('main')} />;
  }

  if (viewMode === 'private_traffic') {
    return <PrivateTrafficLeadView onBack={() => setViewMode('main')} />;
  }

  if (viewMode === 'topic_inspiration') {
    return (
      <TopicInspirationView 
        onBack={() => setViewMode('main')} 
        onGoToContentGenerator={(topic) => {
          setPassedTopic(topic);
          setViewMode('content_generator');
        }}
      />
    );
  }
  
  if (viewMode === 'content_generator') {
    return (
      <ContentGeneratorView 
        onBack={() => {
          setViewMode('main');
          setPassedTopic(undefined);
        }} 
        initialTopic={passedTopic}
      />
    );
  }

  if (viewMode === 'publish_plan') {
    return (
      <PublishPlanView 
        onBack={() => setViewMode('main')} 
        onGoToContentGenerator={() => setViewMode('content_generator')} 
      />
    );
  }

  return (
    <div className="space-y-4 animate-in fade-in duration-200 min-h-full pb-4">
      {/* 顶部: 完成度卡片 */}
      {completionRate < 100 && (
        <div className="bg-white border border-[#E6E0D6] rounded-[28px] p-6 shadow-sm flex items-center justify-between">
          <div>
            <h2 className="font-bold text-[16px] text-[#1D1B16] mb-1 tracking-tight">完善个人主页，提升被发现几率</h2>
            <div className="flex items-center gap-2">
              <span className="text-[13px] text-[#7A756C] font-medium">完成度 {completionRate}%</span>
              <button 
                onClick={() => {
                  setCompletionRate(100);
                  if (onNavigateToProfile) onNavigateToProfile();
                }}
                className="text-[13px] font-bold text-[#6750A4] hover:underline"
              >
                去完善 {'>'}
              </button>
            </div>
          </div>
          <div className="relative w-14 h-14 shrink-0">
            <svg className="w-full h-full transform -rotate-90" viewBox="0 0 36 36">
              <circle cx="18" cy="18" r="16" fill="none" className="stroke-[#EADDFF]" strokeWidth="4" />
              <circle 
                cx="18" cy="18" r="16" fill="none" 
                className="stroke-[#6750A4]" strokeWidth="4" 
                strokeDasharray="100" strokeDashoffset={100 - completionRate} strokeLinecap="round" 
              />
            </svg>
            <div className="absolute inset-0 flex items-center justify-center font-bold text-[12px] text-[#6750A4]">
              {completionRate}%
            </div>
          </div>
        </div>
      )}

      {/* Section 1: 我的主页 */}
      <div className="bg-white border border-[#E6E0D6] rounded-[28px] p-6 shadow-sm">
        <div className="flex items-center justify-between mb-5">
          <h3 className="font-bold text-[16px] text-[#1D1B16] tracking-tight">我的主页</h3>
          <div className="flex items-center gap-2">
            <button 
              onClick={() => setShowShareModal(true)}
              className="text-[13px] text-[#49463D] font-medium flex items-center gap-1 bg-[#F5F5F5] px-3 py-1.5 rounded-full hover:bg-[#EAE5DB] transition"
            >
              <Share2 className="w-3.5 h-3.5" /> 分享
            </button>
            <button className="text-[13px] text-[#49463D] font-medium flex items-center gap-0.5 bg-[#F5F5F5] px-3 py-1.5 rounded-full hover:bg-[#EAE5DB] transition">
              预览主页 <ChevronRight className="w-3.5 h-3.5" />
            </button>
          </div>
        </div>
        
        <div className="grid grid-cols-4 gap-2">
          <div className="flex flex-col items-center justify-center">
            <div className="w-12 h-12 rounded-[16px] bg-[#FAF8F5] flex items-center justify-center text-[#49463D] mb-2 hover:bg-[#EAE5DB] transition cursor-pointer">
              <Users className="w-5 h-5" />
            </div>
            <span className="text-[11px] text-[#7A756C] mb-1 font-medium">访客数</span>
            <span className="text-[11px] text-[#132C0B] bg-[#D0BCFF] px-2 py-0.5 rounded-md font-bold">{(consultant as any).totalClients === 0 ? '暂无数据' : '本周 +28%'}</span>
          </div>
          
          <div className="flex flex-col items-center justify-center">
            <div className="w-12 h-12 rounded-[16px] bg-[#FAF8F5] flex items-center justify-center text-[#49463D] mb-2 hover:bg-[#EAE5DB] transition cursor-pointer">
              <Heart className="w-5 h-5" />
            </div>
            <span className="text-[11px] text-[#7A756C] mb-1 font-medium">收藏数</span>
            <span className="text-[11px] text-[#132C0B] bg-[#D0BCFF] px-2 py-0.5 rounded-md font-bold">{(consultant as any).totalClients === 0 ? '暂无数据' : '本周 +12%'}</span>
          </div>
          
          <div className="flex flex-col items-center justify-center">
            <div className="w-12 h-12 rounded-[16px] bg-[#FAF8F5] flex items-center justify-center text-[#49463D] mb-2 hover:bg-[#EAE5DB] transition cursor-pointer">
              <Globe className="w-5 h-5" />
            </div>
            <span className="text-[11px] text-[#7A756C] mb-1 font-medium">被分享</span>
            <span className="text-[11px] text-[#132C0B] bg-[#D0BCFF] px-2 py-0.5 rounded-md font-bold">{(consultant as any).totalClients === 0 ? '暂无数据' : '本周 +12%'}</span>
          </div>
          
          <div className="flex flex-col items-center justify-center">
            <div className="w-12 h-12 rounded-[16px] bg-[#FAF8F5] flex items-center justify-center text-[#49463D] mb-2 hover:bg-[#EAE5DB] transition cursor-pointer">
              <CheckCircle2 className="w-5 h-5" />
            </div>
            <span className="text-[11px] text-[#7A756C] mb-1 font-medium">咨询转化</span>
            <span className="text-[11px] text-[#132C0B] bg-[#D0BCFF] px-2 py-0.5 rounded-md font-bold">{(consultant as any).totalClients === 0 ? '暂无数据' : '本周 +18%'}</span>
          </div>
        </div>
      </div>

      {/* Section 2: AI内容助手 */}
      <div className="bg-white border border-[#E6E0D6] rounded-[28px] p-6 shadow-sm">
        <div className="flex items-center justify-between mb-5">
          <div className="flex items-center gap-2">
            <h3 className="font-bold text-[16px] text-[#1D1B16] tracking-tight">AI内容助手</h3>
            <Sparkles className="w-4 h-4 text-[#6750A4]" />
          </div>
        </div>
        
        <div className="space-y-3">
          <button 
            onClick={() => setViewMode('topic_inspiration')}
            className="w-full flex items-center gap-4 p-4 bg-[#FAF8F5] rounded-[20px] border border-[#ECE6DC] hover:bg-[#EAE5DB] transition text-left group"
          >
            <div className="w-12 h-12 rounded-[16px] bg-[#FFDF99] text-[#7A2E0E] flex items-center justify-center shrink-0 group-active:scale-95 transition">
              <Lightbulb className="w-6 h-6" />
            </div>
            <div className="flex-1">
              <div className="font-bold text-[15px] text-[#1D1B16]">选题灵感</div>
              <div className="text-[12px] text-[#7A756C] mt-0.5 font-medium">挖掘你的擅长生成热门选题</div>
            </div>
            <ChevronRight className="w-5 h-5 text-[#A09C94] group-hover:text-[#1D1B16] transition" />
          </button>
          
          <button 
            onClick={() => setViewMode('content_generator')}
            className="w-full flex items-center gap-4 p-4 bg-[#FAF8F5] rounded-[20px] border border-[#ECE6DC] hover:bg-[#EAE5DB] transition text-left group"
          >
            <div className="w-12 h-12 rounded-[16px] bg-[#D3E3FD] text-[#0842A0] flex items-center justify-center shrink-0 group-active:scale-95 transition">
              <FileText className="w-6 h-6" />
            </div>
            <div className="flex-1">
              <div className="font-bold text-[15px] text-[#1D1B16]">内容生成</div>
              <div className="text-[12px] text-[#7A756C] mt-0.5 font-medium">小红书/公众号/视频脚本</div>
            </div>
            <ChevronRight className="w-5 h-5 text-[#A09C94] group-hover:text-[#1D1B16] transition" />
          </button>
          
          <button 
            onClick={() => setViewMode('publish_plan')}
            className="w-full flex items-center gap-4 p-4 bg-[#FAF8F5] rounded-[20px] border border-[#ECE6DC] hover:bg-[#EAE5DB] transition text-left group"
          >
            <div className="w-12 h-12 rounded-[16px] bg-[#C4EED0] text-[#003912] flex items-center justify-center shrink-0 group-active:scale-95 transition">
              <Calendar className="w-6 h-6" />
            </div>
            <div className="flex-1">
              <div className="font-bold text-[15px] text-[#1D1B16]">发布计划</div>
              <div className="text-[12px] text-[#7A756C] mt-0.5 font-medium">本周待发布 3 篇内容</div>
            </div>
            <ChevronRight className="w-5 h-5 text-[#A09C94] group-hover:text-[#1D1B16] transition" />
          </button>
        </div>
      </div>

      {/* Section 3: 获客助手 */}
      <div className="bg-white border border-[#E6E0D6] rounded-[28px] p-6 shadow-sm">
        <div className="flex items-center justify-between mb-5">
          <h3 className="font-bold text-[16px] text-[#1D1B16] tracking-tight">获客助手</h3>
        </div>
        
        <div className="grid grid-cols-2 gap-3">
          <button 
            onClick={() => setViewMode('private_traffic')}
            className="flex flex-col items-center justify-center text-center p-4 bg-[#FAF8F5] rounded-[20px] border border-[#ECE6DC] hover:bg-[#EAE5DB] transition group"
          >
            <div className="w-12 h-12 rounded-[16px] bg-[#EADDFF] text-[#4F378B] flex items-center justify-center mb-3 group-active:scale-95 transition">
              <Users className="w-6 h-6" />
            </div>
            <span className="text-[13px] font-bold text-[#1D1B16]">私域引流</span>
          </button>
          
          <button 
            onClick={() => setViewMode('consulting_entry')}
            className="flex flex-col items-center justify-center text-center p-4 bg-[#FAF8F5] rounded-[20px] border border-[#ECE6DC] hover:bg-[#EAE5DB] transition group"
          >
            <div className="w-12 h-12 rounded-[16px] bg-[#D3E3FD] text-[#0842A0] flex items-center justify-center mb-3 group-active:scale-95 transition">
              <Heart className="w-6 h-6" />
            </div>
            <span className="text-[13px] font-bold text-[#1D1B16]">咨询入口</span>
          </button>
        </div>
      </div>
      
      {/* Share Bottom Sheet */}
      {showShareModal && (
        <div className="fixed inset-0 z-[80] bg-black/40 flex items-end justify-center animate-in fade-in duration-200">
          <div className="bg-[#FAF8F5] w-full max-w-md rounded-t-[24px] pb-8 animate-in slide-in-from-bottom-full duration-300">
            <div className="flex justify-between items-center p-4 border-b border-[#ECE6DC]">
              <div className="w-5" /> {/* placeholder for centering */}
              <h3 className="font-bold text-[16px] text-[#1D1B16]">分享至</h3>
              <button onClick={() => setShowShareModal(false)} className="p-1 rounded-full hover:bg-[#E8E2D5] transition">
                <X className="w-5 h-5 text-[#7A756C]"/>
              </button>
            </div>
            
            <div className="p-6">
              <div className="flex justify-between items-center px-4">
                <button className="flex flex-col items-center gap-2 group" onClick={() => alert('微信小程序分享卡片已发送')}>
                  <div className="w-14 h-14 rounded-full bg-[#07C160] text-white flex items-center justify-center group-active:scale-95 transition shadow-sm">
                    <MessageSquare className="w-7 h-7" />
                  </div>
                  <span className="text-[12px] text-[#49463D] font-medium">微信好友</span>
                </button>
                <button className="flex flex-col items-center gap-2 group" onClick={() => alert('朋友圈分享卡片已发送')}>
                  <div className="w-14 h-14 rounded-full bg-[#07C160] text-white flex items-center justify-center group-active:scale-95 transition shadow-sm">
                    <Globe className="w-7 h-7" />
                  </div>
                  <span className="text-[12px] text-[#49463D] font-medium">朋友圈</span>
                </button>
                <button 
                  onClick={() => {
                    alert('主页链接已复制到剪贴板');
                    setShowShareModal(false);
                  }}
                  className="flex flex-col items-center gap-2 group"
                >
                  <div className="w-14 h-14 rounded-[16px] bg-white border border-[#ECE6DC] text-[#1D1B16] flex items-center justify-center group-active:scale-95 transition shadow-sm">
                    <LinkIcon className="w-6 h-6" />
                  </div>
                  <span className="text-[12px] text-[#49463D] font-medium">复制链接</span>
                </button>
                <button 
                  onClick={() => {
                    setShowShareModal(false);
                    setShowPosterModal(true);
                  }}
                  className="flex flex-col items-center gap-2 group"
                >
                  <div className="w-14 h-14 rounded-[16px] bg-white border border-[#ECE6DC] text-[#1D1B16] flex items-center justify-center group-active:scale-95 transition shadow-sm">
                    <ImageIcon className="w-6 h-6" />
                  </div>
                  <span className="text-[12px] text-[#49463D] font-medium">生成分享图</span>
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Poster Modal */}
      {showPosterModal && (
        <div className="fixed inset-0 z-[90] bg-black/80 flex flex-col items-center justify-center p-6 animate-in fade-in duration-200">
          <div className="w-full max-w-sm bg-white rounded-[24px] overflow-hidden shadow-2xl animate-in zoom-in-95 duration-300">
            {/* Poster Content */}
            <div className="p-6 bg-gradient-to-b from-[#EADDFF]/30 to-white">
              <div className="flex items-center gap-4 mb-6">
                <img src={consultant.avatar} alt="avatar" className="w-16 h-16 rounded-full border-2 border-white shadow-sm object-cover" />
                <div>
                  <h2 className="text-xl font-bold text-[#1D1B16]">{consultant.name}</h2>
                  <p className="text-sm text-[#49463D] mt-1">{consultant.title}</p>
                </div>
              </div>
              <div className="space-y-3 mb-8">
                <div className="bg-[#FAF8F5] p-3 rounded-[12px] text-sm text-[#49463D] leading-relaxed">
                  "温暖接纳、敏锐洞察、温和而坚定。注重陪伴来访者在安全氛围中自发探索..."
                </div>
                <div className="flex flex-wrap gap-2">
                  <span className="bg-[#EADDFF]/50 text-[#4F378B] px-2 py-1 rounded-md text-[11px] font-bold border border-[#D0BCFF]/50">职场焦虑与倦怠</span>
                  <span className="bg-[#EADDFF]/50 text-[#4F378B] px-2 py-1 rounded-md text-[11px] font-bold border border-[#D0BCFF]/50">亲密关系与沟通</span>
                </div>
              </div>
              <div className="flex items-center justify-between pt-6 border-t border-[#ECE6DC]">
                <div className="text-xs text-[#7A756C]">
                  <p className="font-bold text-[#1D1B16] mb-1">长按识别小程序码</p>
                  <p>进入我的咨询主页</p>
                </div>
                <div className="w-16 h-16 bg-[#FAF8F5] border border-[#ECE6DC] rounded-lg flex items-center justify-center shrink-0">
                  {/* Mock QR Code */}
                  <div className="w-12 h-12 bg-[#1D1B16] [mask-image:url('data:image/svg+xml;utf8,<svg viewBox=\'0 0 24 24\' xmlns=\'http://www.w3.org/2000/svg\'><path d=\'M3 3h6v6H3V3zm2 2v2h2V5H5zm8-2h6v6h-6V3zm2 2v2h2V5h-2zM3 13h6v6H3v-6zm2 2v2h2v-2H5zm13-2h-3v2h3v-2zm-3 4h3v2h-3v-2zm-2-4h2v6h-2v-6z\'/></svg>')] [mask-size:cover]" />
                </div>
              </div>
            </div>
          </div>
          
          <div className="mt-8 flex gap-4">
            <button 
              onClick={() => setShowPosterModal(false)}
              className="w-12 h-12 rounded-full bg-white/20 text-white flex items-center justify-center hover:bg-white/30 transition"
            >
              <X className="w-6 h-6" />
            </button>
            <button 
              onClick={() => {
                alert('咨询师主页海报已保存到手机相册');
                setShowPosterModal(false);
              }}
              className="flex items-center gap-2 px-6 h-12 rounded-full bg-[#6750A4] text-white font-bold hover:bg-[#594294] transition shadow-lg"
            >
              <Download className="w-5 h-5" /> 保存到相册
            </button>
          </div>
        </div>
      )}

    </div>
  );
};
