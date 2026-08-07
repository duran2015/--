import React, { useState } from 'react';
import { 
  ArrowLeft, Sparkles, FileText, 
  MessageSquare, Video, PenTool,
  CheckCircle2, AlertTriangle, 
  RefreshCw, Copy, Save, ChevronDown,
  Wand2, Zap, Heart, Hash
} from 'lucide-react';

interface ContentGeneratorViewProps {
  onBack: () => void;
  initialTopic?: string;
}

export const ContentGeneratorView: React.FC<ContentGeneratorViewProps> = ({ onBack, initialTopic }) => {
  const [step, setStep] = useState<'input' | 'generating' | 'result'>('input');
  
  // Form State
  const [topic, setTopic] = useState(initialTopic || '');
  const [contentType, setContentType] = useState('小红书笔记');
  const [style, setStyle] = useState('专业科普');
  
  const contentTypes = [
    { id: '小红书笔记', icon: <PenTool className="w-4 h-4" /> },
    { id: '朋友圈', icon: <MessageSquare className="w-4 h-4" /> },
    { id: '视频脚本', icon: <Video className="w-4 h-4" /> },
    { id: '公众号文章', icon: <FileText className="w-4 h-4" /> },
  ];

  const styles = ['专业科普', '温暖陪伴', '案例故事', '个人观点'];

  const handleGenerate = () => {
    if (!topic.trim()) return;
    setStep('generating');
    setTimeout(() => {
      setStep('result');
    }, 2000);
  };

  const InputView = () => (
    <div className="space-y-6 animate-in fade-in duration-300">
      {/* 核心输入区 */}
      <div className="bg-white border border-[#E6E0D6] rounded-[28px] p-5 shadow-sm">
        <h3 className="font-bold text-[16px] text-[#1D1B16] mb-4 tracking-tight">你想写什么？</h3>
        <textarea 
          value={topic}
          onChange={(e) => setTopic(e.target.value)}
          placeholder="例如：最近遇到很多职场新人，总是因为领导的一句话内耗一整天..."
          className="w-full bg-[#FAF8F5] border border-[#ECE6DC] rounded-[20px] p-4 text-[14px] text-[#1D1B16] placeholder-[#A09C94] focus:outline-none focus:border-[#D0BCFF] focus:ring-1 focus:ring-[#D0BCFF] transition resize-none h-32"
        />
        <div className="flex items-center justify-between mt-3">
          <div className="flex gap-2">
            <button 
              onClick={() => setTopic('职场焦虑')}
              className="text-[12px] bg-[#F5F5F5] text-[#7A756C] px-3 py-1.5 rounded-full hover:bg-[#EAE5DB] transition font-medium"
            >
              # 职场焦虑
            </button>
            <button 
              onClick={() => setTopic('讨好型人格')}
              className="text-[12px] bg-[#F5F5F5] text-[#7A756C] px-3 py-1.5 rounded-full hover:bg-[#EAE5DB] transition font-medium"
            >
              # 讨好型人格
            </button>
          </div>
          <span className="text-[12px] text-[#A09C94]">{topic.length}/200</span>
        </div>
      </div>

      {/* 选项区 */}
      <div className="bg-white border border-[#E6E0D6] rounded-[28px] p-5 shadow-sm space-y-6">
        
        <div>
          <h3 className="font-bold text-[15px] text-[#1D1B16] mb-3 tracking-tight">内容类型</h3>
          <div className="grid grid-cols-2 gap-3">
            {contentTypes.map((type) => (
              <button
                key={type.id}
                onClick={() => setContentType(type.id)}
                className={`flex items-center gap-2 p-3 rounded-[16px] border transition active:scale-95 ${
                  contentType === type.id
                    ? 'bg-[#EADDFF] border-[#D0BCFF] text-[#4F378B] font-bold'
                    : 'bg-[#FAF8F5] border-[#ECE6DC] text-[#7A756C] hover:bg-[#EAE5DB] font-medium'
                }`}
              >
                {type.icon}
                <span className="text-[13px]">{type.id}</span>
              </button>
            ))}
          </div>
        </div>

        <div>
          <h3 className="font-bold text-[15px] text-[#1D1B16] mb-3 tracking-tight">内容风格</h3>
          <div className="flex flex-wrap gap-2">
            {styles.map((s) => (
              <button
                key={s}
                onClick={() => setStyle(s)}
                className={`px-4 py-2 rounded-full border transition text-[13px] active:scale-95 ${
                  style === s
                    ? 'bg-[#EADDFF] border-[#D0BCFF] text-[#4F378B] font-bold'
                    : 'bg-[#FAF8F5] border-[#ECE6DC] text-[#7A756C] hover:bg-[#EAE5DB] font-medium'
                }`}
              >
                {s}
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* Action */}
      <button 
        onClick={handleGenerate}
        disabled={!topic.trim()}
        className={`w-full py-3.5 rounded-full font-bold text-[16px] flex items-center justify-center gap-2 transition ${
          topic.trim() 
            ? 'bg-[#6750A4] text-white hover:bg-[#594294] active:scale-95 shadow-sm' 
            : 'bg-[#E7E0EC] text-[#A09C94] cursor-not-allowed'
        }`}
      >
        <Sparkles className="w-5 h-5" /> 开始生成
      </button>
    </div>
  );

  const GeneratingView = () => (
    <div className="flex flex-col items-center justify-center py-20 animate-in fade-in duration-300">
      <div className="w-20 h-20 bg-[#EADDFF] rounded-full flex items-center justify-center mb-6 relative">
        <div className="absolute inset-0 border-4 border-[#D0BCFF] rounded-full animate-ping opacity-75"></div>
        <Sparkles className="w-8 h-8 text-[#6750A4] animate-pulse" />
      </div>
      <h3 className="font-bold text-[18px] text-[#1D1B16] mb-2">AI 正在创作中...</h3>
      <p className="text-[14px] text-[#7A756C] font-medium animate-pulse">正在结合「{style}」风格与您的专业定位</p>
      
      <div className="w-64 bg-[#E7E0EC] h-2 rounded-full mt-8 overflow-hidden">
        <div className="bg-[#6750A4] h-full rounded-full w-1/2 animate-[progress_2s_ease-in-out_infinite]"></div>
      </div>
    </div>
  );

  const ResultView = () => (
    <div className="space-y-4 animate-in fade-in slide-in-from-bottom-4 duration-300">
      
      {/* 标题候选 */}
      <div className="bg-white border border-[#E6E0D6] rounded-[28px] p-5 shadow-sm">
        <div className="flex items-center gap-2 mb-4">
          <Hash className="w-5 h-5 text-[#6750A4]" />
          <h3 className="font-bold text-[16px] text-[#1D1B16] tracking-tight">候选标题 (点击使用)</h3>
        </div>
        <div className="space-y-2">
          {['别让领导的一句话，毁了你一整天的心情', '职场高敏感：如何建立情绪防火墙？', '致职场新人：你的价值不由别人的评价决定'].map((title, i) => (
            <button key={i} className="w-full text-left p-3 bg-[#FAF8F5] border border-[#ECE6DC] rounded-xl text-[14px] text-[#1D1B16] font-bold hover:bg-[#EADDFF] hover:border-[#D0BCFF] hover:text-[#4F378B] transition">
              {title}
            </button>
          ))}
        </div>
      </div>

      {/* 正文内容 */}
      <div className="bg-white border border-[#E6E0D6] rounded-[28px] p-5 shadow-sm relative overflow-hidden">
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center gap-2">
            <FileText className="w-5 h-5 text-[#6750A4]" />
            <h3 className="font-bold text-[16px] text-[#1D1B16] tracking-tight">正文内容</h3>
          </div>
          <button className="text-[12px] text-[#6750A4] font-bold flex items-center gap-1 bg-[#EADDFF] px-3 py-1.5 rounded-full hover:bg-[#D0BCFF] transition">
            <Copy className="w-3.5 h-3.5" /> 复制全文
          </button>
        </div>
        
        <div className="text-[14px] text-[#49463D] leading-relaxed space-y-4 font-medium">
          <p><span className="font-bold text-[#6750A4]">【痛点引入】</span><br/>最近在咨询室里，我遇到好几位职场新人。他们都有一个共同的困扰：“今天领导叹了口气，我是不是做错了什么？”、“开会时老板没看我，是不是对我有意见？”</p>
          <p><span className="font-bold text-[#6750A4]">【心理解释】</span><br/>在心理学中，我们把这种现象称为「自动化负面思维」结合「过度理智化」。高敏感人群往往拥有极强的雷达，能捕捉到空气中一丝一毫的微表情。但问题在于，我们常常把别人的情绪，错误地归因于自己。</p>
          <p><span className="font-bold text-[#6750A4]">【行动建议】</span><br/>下次当你再次陷入这种内耗时，试试这 3 个心理急救法：<br/>1. 课题分离：他的情绪是他的课题，你的工作是你的课题。<br/>2. 寻找反证：除了“他对我不满”，还有其他可能吗？也许他只是太累了。<br/>3. 物理抽离：去接杯水，让紧绷的神经休息 3 分钟。</p>
          <p>你的专业价值，永远不需要通过讨好所有人来证明。💡</p>
        </div>
        
        <div className="flex gap-2 mt-5 pt-4 border-t border-[#F5F5F5]">
          <span className="text-[12px] text-[#4F378B] bg-[#EADDFF] px-2 py-1 rounded-md font-bold">#职场心理学</span>
          <span className="text-[12px] text-[#4F378B] bg-[#EADDFF] px-2 py-1 rounded-md font-bold">#拒绝内耗</span>
          <span className="text-[12px] text-[#4F378B] bg-[#EADDFF] px-2 py-1 rounded-md font-bold">#情绪管理</span>
        </div>
      </div>

      {/* AI 微调优化 */}
      <div className="bg-white border border-[#E6E0D6] rounded-[28px] p-5 shadow-sm">
        <h3 className="font-bold text-[15px] text-[#1D1B16] mb-3 tracking-tight">AI 一键优化</h3>
        <div className="grid grid-cols-4 gap-2 mb-3">
          <button className="flex flex-col items-center justify-center p-3 bg-[#FAF8F5] border border-[#ECE6DC] rounded-[16px] hover:bg-[#EAE5DB] transition active:scale-95 text-[#49463D]">
            <Wand2 className="w-5 h-5 mb-1 text-[#6750A4]" />
            <span className="text-[12px] font-bold">更专业</span>
          </button>
          <button className="flex flex-col items-center justify-center p-3 bg-[#FAF8F5] border border-[#ECE6DC] rounded-[16px] hover:bg-[#EAE5DB] transition active:scale-95 text-[#49463D]">
            <Heart className="w-5 h-5 mb-1 text-[#B3261E]" />
            <span className="text-[12px] font-bold">更温暖</span>
          </button>
          <button className="flex flex-col items-center justify-center p-3 bg-[#FAF8F5] border border-[#ECE6DC] rounded-[16px] hover:bg-[#EAE5DB] transition active:scale-95 text-[#49463D]">
            <MessageSquare className="w-5 h-5 mb-1 text-[#0842A0]" />
            <span className="text-[12px] font-bold">更口语</span>
          </button>
          <button className="flex flex-col items-center justify-center p-3 bg-[#FAF8F5] border border-[#ECE6DC] rounded-[16px] hover:bg-[#EAE5DB] transition active:scale-95 text-[#49463D]">
            <Zap className="w-5 h-5 mb-1 text-[#7A2E0E]" />
            <span className="text-[12px] font-bold">更营销</span>
          </button>
        </div>
        <div className="flex gap-2">
          <button className="flex-1 py-2 bg-[#F5F5F5] text-[#49463D] rounded-full text-[13px] font-bold hover:bg-[#EAE5DB] transition">缩短篇幅</button>
          <button className="flex-1 py-2 bg-[#F5F5F5] text-[#49463D] rounded-full text-[13px] font-bold hover:bg-[#EAE5DB] transition">扩写细节</button>
          <button className="flex-1 py-2 bg-[#F5F5F5] text-[#49463D] rounded-full text-[13px] font-bold hover:bg-[#EAE5DB] transition flex items-center justify-center gap-1">
            <RefreshCw className="w-3.5 h-3.5" /> 重写
          </button>
        </div>
      </div>

      {/* 发布前检查 */}
      <div className="bg-[#F4F8F4] border border-[#C4EED0] rounded-[28px] p-5 shadow-sm">
        <div className="flex items-start gap-3">
          <div className="mt-0.5">
            <CheckCircle2 className="w-5 h-5 text-[#132C0B]" />
          </div>
          <div>
            <h3 className="font-bold text-[15px] text-[#132C0B] mb-1">发布前安全检查通过</h3>
            <p className="text-[12px] text-[#003912] font-medium leading-relaxed">
              未发现过度承诺、医疗风险及违规敏感词。该内容符合《心理咨询师职业伦理规范》及小红书平台规范。
            </p>
          </div>
        </div>
      </div>

      {/* 底部操作 */}
      <div className="flex gap-3 pt-2">
        <button 
          onClick={() => setStep('input')}
          className="w-1/3 py-3.5 rounded-full font-bold text-[15px] bg-white border border-[#E6E0D6] text-[#49463D] hover:bg-[#FAF8F5] active:scale-95 transition shadow-sm"
        >
          返回修改
        </button>
        <button className="flex-1 py-3.5 rounded-full font-bold text-[15px] bg-[#6750A4] text-white hover:bg-[#594294] active:scale-95 transition shadow-sm flex items-center justify-center gap-2">
          <Save className="w-4 h-4" /> 保存草稿
        </button>
      </div>

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
            AI 内容生成 <Sparkles className="w-5 h-5 text-[#6750A4]" />
          </h2>
          <p className="text-[13px] text-[#7A756C] font-medium mt-0.5">你的专属 AI 写作助手</p>
        </div>
      </div>

      {step === 'input' && <InputView />}
      {step === 'generating' && <GeneratingView />}
      {step === 'result' && <ResultView />}
      
    </div>
  );
};
