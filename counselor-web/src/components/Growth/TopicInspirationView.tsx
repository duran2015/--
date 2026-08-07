import React, { useState } from 'react';
import { 
  ArrowLeft, Sparkles, Settings, Bookmark, 
  ChevronRight, BookmarkCheck, FileText, 
  Video, Image as ImageIcon, CheckCircle2,
  TrendingUp, Users, BookOpen, UserCircle,
  X, PenTool
} from 'lucide-react';
import { ContentPersonaView } from './ContentPersonaView';

interface Topic {
  id: string;
  category: 'pain_point' | 'knowledge' | 'case' | 'brand';
  title: string;
  targetUser: string;
  reason: string;
  formats: string[];
  tags: string[];
}

interface TopicInspirationViewProps {
  onBack: () => void;
  onGoToContentGenerator: (topic?: string) => void;
}

export const TopicInspirationView: React.FC<TopicInspirationViewProps> = ({ onBack, onGoToContentGenerator }) => {
  const [showPersonaConfig, setShowPersonaConfig] = useState(false);
  const [savedTopics, setSavedTopics] = useState<string[]>([]);
  const [activeCategory, setActiveCategory] = useState<string | null>(null);
  const [selectedTopic, setSelectedTopic] = useState<Topic | null>(null);

  // Mock Topics Database
  const mockTopics: Topic[] = [
    {
      id: 't1',
      category: 'pain_point',
      title: '为什么越努力的人越容易陷入内耗？',
      targetUser: '25-35岁职场女性',
      reason: '近期大量用户搜索“工作压力”、“自我否定”，与你的专业方向高度匹配。',
      formats: ['小红书笔记', '短视频'],
      tags: ['职场压力', '内耗']
    },
    {
      id: 't2',
      category: 'pain_point',
      title: '总是害怕让别人失望，该如何拒绝？',
      targetUser: '讨好型人格倾向人群',
      reason: '该痛点在你的历史咨询中出现频率高达 40%。',
      formats: ['小红书笔记', '朋友圈'],
      tags: ['讨好型人格', '边界感']
    },
    {
      id: 't3',
      category: 'knowledge',
      title: '什么是情绪耗竭？3个信号帮你自测',
      targetUser: '高压白领人群',
      reason: '将专业术语转化为大众易懂的自测工具，互动率和收藏率通常较高。',
      formats: ['小红书笔记', '公众号文章'],
      tags: ['情绪管理', '科普']
    },
    {
      id: 't4',
      category: 'case',
      title: '一个总说“没事”的人，可能经历了什么？',
      targetUser: '寻求共鸣的潜在来访者',
      reason: '通过匿名案例展现你的同理心和专业分析能力，是建立信任的最佳方式。',
      formats: ['公众号文章', '短视频'],
      tags: ['案例洞察', '深度分析']
    },
    {
      id: 't5',
      category: 'brand',
      title: '咨询8年，我看到最多的情绪问题是什么？',
      targetUser: '关注心理学的泛人群',
      reason: '通过回顾职业生涯建立权威背书，适合作为置顶的个人介绍内容。',
      formats: ['小红书笔记', '朋友圈'],
      tags: ['个人品牌', '经验分享']
    }
  ];

  if (showPersonaConfig) {
    return (
      <ContentPersonaView 
        onBack={() => setShowPersonaConfig(false)} 
        onComplete={() => setShowPersonaConfig(false)} 
      />
    );
  }

  const toggleSave = (id: string, e?: React.MouseEvent) => {
    if (e) e.stopPropagation();
    setSavedTopics(prev => 
      prev.includes(id) ? prev.filter(tId => tId !== id) : [...prev, id]
    );
  };

  const renderTopicList = (category: string) => {
    const filteredTopics = mockTopics.filter(t => t.category === category);
    const categoryNames: Record<string, string> = {
      pain_point: '用户痛点',
      knowledge: '专业科普',
      case: '案例洞察',
      brand: '个人品牌'
    };
    
    return (
      <div className="space-y-4 animate-in fade-in slide-in-from-right-4 duration-300 min-h-full pb-6">
        <div className="flex items-center gap-3 pb-2">
          <button 
            onClick={() => setActiveCategory(null)}
            className="w-10 h-10 flex items-center justify-center bg-white border border-[#E6E0D6] rounded-full text-[#49463D] hover:bg-[#FAF8F5] active:scale-95 transition shadow-sm"
          >
            <ArrowLeft className="w-5 h-5" />
          </button>
          <div>
            <h2 className="text-xl font-bold text-[#1D1B16] flex items-center gap-2">
              {categoryNames[category]} <Sparkles className="w-5 h-5 text-[#6750A4]" />
            </h2>
            <p className="text-[13px] text-[#7A756C] font-medium mt-0.5">AI 根据你的定位生成的专属选题库</p>
          </div>
        </div>

        <div className="space-y-3">
          {filteredTopics.map((topic) => (
            <div 
              key={topic.id} 
              onClick={() => setSelectedTopic(topic)}
              className="bg-white border border-[#E6E0D6] rounded-[24px] p-5 shadow-sm hover:border-[#D0BCFF] cursor-pointer transition"
            >
              <div className="flex justify-between items-start mb-3">
                <div className="flex gap-2">
                  {topic.tags.map(tag => (
                    <span key={tag} className="text-[11px] font-bold px-2 py-0.5 rounded-md bg-[#F5F5F5] text-[#49463D]">
                      {tag}
                    </span>
                  ))}
                </div>
                <button 
                  onClick={(e) => toggleSave(topic.id, e)}
                  className={`text-[#A09C94] hover:text-[#6750A4] transition ${savedTopics.includes(topic.id) ? 'text-[#6750A4]' : ''}`}
                >
                  {savedTopics.includes(topic.id) ? <BookmarkCheck className="w-5 h-5" /> : <Bookmark className="w-5 h-5" />}
                </button>
              </div>
              
              <h4 className="font-bold text-[16px] text-[#1D1B16] mb-2 leading-snug">
                {topic.title}
              </h4>
              <p className="text-[13px] text-[#7A756C] font-medium line-clamp-1">
                目标场景：{topic.targetUser}
              </p>
            </div>
          ))}
        </div>
      </div>
    );
  };

  if (activeCategory) {
    return (
      <>
        {renderTopicList(activeCategory)}
        
        {/* Topic Detail Modal */}
        {selectedTopic && (
          <div className="fixed inset-0 bg-black/40 z-50 flex flex-col justify-end animate-in fade-in duration-200">
            <div className="bg-white rounded-t-[32px] p-6 pb-10 animate-in slide-in-from-bottom-full duration-300">
              <div className="flex justify-between items-start mb-4">
                <div className="flex gap-2">
                  <span className="text-[11px] bg-[#EADDFF] text-[#4F378B] px-2 py-1 rounded-md font-bold">AI 推荐匹配度 98%</span>
                </div>
                <button onClick={() => setSelectedTopic(null)} className="p-2 bg-[#F5F5F5] rounded-full text-[#7A756C]">
                  <X className="w-5 h-5" />
                </button>
              </div>
              
              <h3 className="text-xl font-bold text-[#1D1B16] mb-5 leading-snug">{selectedTopic.title}</h3>
              
              <div className="space-y-4 mb-6">
                <div className="bg-[#FAF8F5] rounded-[20px] p-4 border border-[#ECE6DC]">
                  <div className="text-[12px] font-bold text-[#6750A4] mb-1 flex items-center gap-1">
                    <Sparkles className="w-3.5 h-3.5" /> 为什么推荐？
                  </div>
                  <div className="text-[13px] text-[#49463D] leading-relaxed font-medium">
                    {selectedTopic.reason}
                  </div>
                </div>
                
                <div className="flex gap-4">
                  <div className="flex-1 bg-[#FAF8F5] rounded-[20px] p-4 border border-[#ECE6DC]">
                    <div className="text-[12px] font-bold text-[#A09C94] mb-1">目标用户</div>
                    <div className="text-[13px] font-bold text-[#1D1B16]">{selectedTopic.targetUser}</div>
                  </div>
                  <div className="flex-1 bg-[#FAF8F5] rounded-[20px] p-4 border border-[#ECE6DC]">
                    <div className="text-[12px] font-bold text-[#A09C94] mb-1">适合平台</div>
                    <div className="text-[13px] font-bold text-[#1D1B16]">{selectedTopic.formats.join(' / ')}</div>
                  </div>
                </div>
              </div>
              
              <div className="flex gap-3">
                <button 
                  onClick={() => toggleSave(selectedTopic.id)}
                  className={`w-14 h-14 flex items-center justify-center rounded-[20px] border transition active:scale-95 ${
                    savedTopics.includes(selectedTopic.id) 
                      ? 'bg-[#EADDFF] border-[#D0BCFF] text-[#4F378B]' 
                      : 'bg-white border-[#E6E0D6] text-[#7A756C] hover:bg-[#FAF8F5]'
                  }`}
                >
                  {savedTopics.includes(selectedTopic.id) ? <BookmarkCheck className="w-6 h-6" /> : <Bookmark className="w-6 h-6" />}
                </button>
                <button 
                  onClick={() => onGoToContentGenerator(selectedTopic.title)}
                  className="flex-1 bg-[#6750A4] text-white font-bold text-[16px] rounded-[20px] hover:bg-[#594294] active:scale-95 transition shadow-sm flex items-center justify-center gap-2"
                >
                  <PenTool className="w-5 h-5" /> 立即生成内容
                </button>
              </div>
            </div>
          </div>
        )}
      </>
    );
  }

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
              选题灵感 <Sparkles className="w-5 h-5 text-[#6750A4]" />
            </h2>
            <p className="text-[13px] text-[#7A756C] font-medium mt-0.5">你的个人内容增长 Agent</p>
          </div>
        </div>
        <button 
          onClick={() => setShowPersonaConfig(true)}
          className="text-[12px] text-[#4F378B] font-bold flex items-center gap-1 bg-[#EADDFF] px-3 py-1.5 rounded-full hover:bg-[#D0BCFF] transition"
        >
          <Settings className="w-3.5 h-3.5" /> 内容定位
        </button>
      </div>

      {/* 第一层：AI今日推荐 */}
      <div className="bg-gradient-to-br from-[#EADDFF]/40 to-white border border-[#D0BCFF] rounded-[28px] p-5 shadow-sm relative overflow-hidden">
        <div className="absolute top-0 right-0 w-32 h-32 bg-white/40 rounded-full blur-2xl -mr-10 -mt-10" />
        <div className="relative z-10">
          <div className="flex items-center gap-2 mb-4">
            <Sparkles className="w-5 h-5 text-[#6750A4]" />
            <h3 className="font-bold text-[16px] text-[#1D1B16] tracking-tight">AI 猜你今天适合创作</h3>
          </div>
          
          <div className="bg-white rounded-[20px] p-4 border border-[#ECE6DC] shadow-sm mb-4">
            <div className="flex gap-2 mb-2">
              <span className="text-[11px] bg-[#F5F5F5] text-[#49463D] px-2 py-0.5 rounded-md font-bold">职场心理</span>
              <span className="text-[11px] bg-[#F5F5F5] text-[#49463D] px-2 py-0.5 rounded-md font-bold">情绪管理</span>
            </div>
            <h4 className="font-bold text-[16px] text-[#1D1B16] mb-3 leading-snug">
              为什么越优秀的人越容易陷入焦虑？
            </h4>
            <div className="bg-[#FAF8F5] rounded-[12px] p-3 mb-3">
              <div className="text-[12px] font-bold text-[#6750A4] mb-1">推荐原因</div>
              <ul className="text-[12px] text-[#7A756C] font-medium space-y-1">
                <li>• 符合你的专业方向 (职场心理)</li>
                <li>• 你的目标用户 (25-35岁职场女性) 高度关注</li>
                <li>• 近期类似话题互动率上升 45%</li>
              </ul>
            </div>
            <div className="flex items-center gap-2 mb-4">
              <span className="text-[11px] text-[#A09C94] font-bold">适合形式:</span>
              <span className="text-[11px] font-medium text-[#49463D] flex items-center gap-1"><ImageIcon className="w-3 h-3" /> 小红书笔记</span>
              <span className="text-[11px] font-medium text-[#49463D] flex items-center gap-1"><Video className="w-3 h-3" /> 短视频</span>
            </div>
            <div className="flex gap-3">
              <button 
                onClick={() => onGoToContentGenerator('为什么越优秀的人越容易陷入焦虑？')}
                className="flex-1 bg-[#6750A4] text-white font-bold text-[14px] py-2.5 rounded-xl hover:bg-[#594294] active:scale-95 transition shadow-sm flex items-center justify-center gap-2"
              >
                <PenTool className="w-4 h-4" /> 立即生成内容
              </button>
              <button 
                onClick={() => toggleSave('t_today')}
                className={`w-11 h-11 flex items-center justify-center rounded-xl border transition active:scale-95 ${
                  savedTopics.includes('t_today') 
                    ? 'bg-[#EADDFF] border-[#D0BCFF] text-[#4F378B]' 
                    : 'bg-white border-[#E6E0D6] text-[#7A756C] hover:bg-[#FAF8F5]'
                }`}
              >
                {savedTopics.includes('t_today') ? <BookmarkCheck className="w-5 h-5" /> : <Bookmark className="w-5 h-5" />}
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* 第二层：探索更多选题方向 */}
      <div>
        <h3 className="font-bold text-[16px] text-[#1D1B16] tracking-tight mb-3 ml-1">探索更多方向</h3>
        <div className="grid grid-cols-2 gap-3">
        {/* 入口1：用户痛点 */}
        <button 
          onClick={() => setActiveCategory('pain_point')}
          className="bg-white border border-[#E6E0D6] rounded-[24px] p-5 shadow-sm hover:border-[#D0BCFF] transition text-left group flex flex-col h-full active:scale-95"
        >
          <div className="w-12 h-12 rounded-[16px] bg-[#FFDF99]/30 text-[#7A2E0E] flex items-center justify-center mb-3 group-hover:scale-110 transition">
            <TrendingUp className="w-6 h-6" />
          </div>
          <div className="font-bold text-[16px] text-[#1D1B16] mb-1">用户痛点</div>
          <div className="text-[12px] text-[#7A756C] font-medium leading-snug mt-auto">发现用户正在焦虑和搜索的真实问题</div>
        </button>
        
        {/* 入口2：专业科普 */}
        <button 
          onClick={() => setActiveCategory('knowledge')}
          className="bg-white border border-[#E6E0D6] rounded-[24px] p-5 shadow-sm hover:border-[#D0BCFF] transition text-left group flex flex-col h-full active:scale-95"
        >
          <div className="w-12 h-12 rounded-[16px] bg-[#D3E3FD]/50 text-[#0842A0] flex items-center justify-center mb-3 group-hover:scale-110 transition">
            <BookOpen className="w-6 h-6" />
          </div>
          <div className="font-bold text-[16px] text-[#1D1B16] mb-1">专业科普</div>
          <div className="text-[12px] text-[#7A756C] font-medium leading-snug mt-auto">将心理学知识转化为大众易懂的内容</div>
        </button>
        
        {/* 入口3：案例洞察 */}
        <button 
          onClick={() => setActiveCategory('case')}
          className="bg-white border border-[#E6E0D6] rounded-[24px] p-5 shadow-sm hover:border-[#D0BCFF] transition text-left group flex flex-col h-full active:scale-95"
        >
          <div className="w-12 h-12 rounded-[16px] bg-[#C4EED0]/50 text-[#003912] flex items-center justify-center mb-3 group-hover:scale-110 transition">
            <Users className="w-6 h-6" />
          </div>
          <div className="font-bold text-[16px] text-[#1D1B16] mb-1">案例洞察</div>
          <div className="text-[12px] text-[#7A756C] font-medium leading-snug mt-auto">通过匿名脱敏案例展现专业分析能力</div>
        </button>
        
        {/* 入口4：个人品牌 */}
        <button 
          onClick={() => setActiveCategory('brand')}
          className="bg-white border border-[#E6E0D6] rounded-[24px] p-5 shadow-sm hover:border-[#D0BCFF] transition text-left group flex flex-col h-full active:scale-95"
        >
          <div className="w-12 h-12 rounded-[16px] bg-[#EADDFF]/50 text-[#4F378B] flex items-center justify-center mb-3 group-hover:scale-110 transition">
            <UserCircle className="w-6 h-6" />
          </div>
          <div className="font-bold text-[16px] text-[#1D1B16] mb-1">个人品牌</div>
          <div className="text-[12px] text-[#7A756C] font-medium leading-snug mt-auto">分享成长经历与理念，建立执业信任</div>
        </button>
      </div>
      </div>

      {/* 第三层：我的内容资产 */}
      <div className="bg-white border border-[#E6E0D6] rounded-[28px] p-5 shadow-sm mt-4">
        <h3 className="font-bold text-[16px] text-[#1D1B16] mb-4 tracking-tight">我的内容资产</h3>
        
        <div className="space-y-1">
          {/* 已收藏灵感 */}
          <button className="w-full flex items-center justify-between p-3 hover:bg-[#FAF8F5] rounded-2xl transition group">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-[14px] bg-[#FAF8F5] flex items-center justify-center text-[#49463D]">
                <Bookmark className="w-5 h-5" />
              </div>
              <div className="text-left">
                <div className="font-bold text-[14px] text-[#1D1B16]">已收藏灵感</div>
                <div className="text-[11px] text-[#7A756C] mt-0.5">待创作的选题</div>
              </div>
            </div>
            <div className="flex items-center gap-2">
              <span className="text-[13px] font-bold text-[#6750A4]">{savedTopics.length}</span>
              <ChevronRight className="w-4 h-4 text-[#A09C94] group-hover:text-[#1D1B16] transition" />
            </div>
          </button>
          
          {/* 创作中 (草稿箱) */}
          <button className="w-full flex items-center justify-between p-3 hover:bg-[#FAF8F5] rounded-2xl transition group">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-[14px] bg-[#FAF8F5] flex items-center justify-center text-[#49463D]">
                <FileText className="w-5 h-5" />
              </div>
              <div className="text-left">
                <div className="font-bold text-[14px] text-[#1D1B16]">创作中</div>
                <div className="text-[11px] text-[#7A756C] mt-0.5">未完成的草稿</div>
              </div>
            </div>
            <div className="flex items-center gap-2">
              <span className="text-[13px] font-bold text-[#6750A4]">3</span>
              <ChevronRight className="w-4 h-4 text-[#A09C94] group-hover:text-[#1D1B16] transition" />
            </div>
          </button>
          
          {/* 已生成内容 */}
          <button className="w-full flex items-center justify-between p-3 hover:bg-[#FAF8F5] rounded-2xl transition group">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-[14px] bg-[#FAF8F5] flex items-center justify-center text-[#49463D]">
                <CheckCircle2 className="w-5 h-5" />
              </div>
              <div className="text-left">
                <div className="font-bold text-[14px] text-[#1D1B16]">已生成内容</div>
                <div className="text-[11px] text-[#7A756C] mt-0.5">待发布或已发布</div>
              </div>
            </div>
            <div className="flex items-center gap-2">
              <span className="text-[13px] font-bold text-[#6750A4]">12</span>
              <ChevronRight className="w-4 h-4 text-[#A09C94] group-hover:text-[#1D1B16] transition" />
            </div>
          </button>
        </div>
      </div>
    </div>
  );
};
