import React, { useState } from 'react';
import { Sparkles, X, Copy, Download, RefreshCw, QrCode, Check } from 'lucide-react';
import { ConsultantProfile, TherapyQuote } from '../types';

interface AIQuoteModalProps {
  consultant: ConsultantProfile;
  onClose: () => void;
}

export const AIQuoteModal: React.FC<AIQuoteModalProps> = ({ consultant, onClose }) => {
  const [topicInput, setTopicInput] = useState<string>('缓解职场焦虑 / 允许自己有情绪');
  const [isLoading, setIsLoading] = useState<boolean>(false);
  const [quotes, setQuotes] = useState<TherapyQuote[]>([
    {
      id: '1',
      title: '允许情绪如云飘过',
      quote: '情绪不是需要被解决的敌人，而是内心理所当然的信使。允许自己悲伤，就像允许阴雨自然落下。',
      tag: '情绪接纳',
    },
    {
      id: '2',
      title: '收回向外索求的目光',
      quote: '最深沉的关怀，往往来自你第一次对自己说：即使今天什么都没做好，我也值得被温柔对待。',
      tag: '自我关怀',
    },
    {
      id: '3',
      title: '温柔而坚定的边界',
      quote: '拒绝别人并不意味着你冷漠，而是你在为自己的心理能量筑起一座温暖的花园。',
      tag: '边界探索',
    }
  ]);

  const [selectedQuoteIndex, setSelectedQuoteIndex] = useState<number>(0);
  const [copiedIndex, setCopiedIndex] = useState<number | null>(null);

  const handleGenerate = async () => {
    setIsLoading(true);
    try {
      const res = await fetch('/api/ai/generate-quote', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ topic: topicInput, consultantName: consultant.name }),
      });
      const data = await res.json();
      if (data.success && data.data?.quotes) {
        setQuotes(data.data.quotes.map((q: any, i: number) => ({ id: `${i}`, ...q })));
        setSelectedQuoteIndex(0);
      }
    } catch (err) {
      console.error(err);
    } finally {
      setIsLoading(false);
    }
  };

  const handleCopy = (index: number, text: string) => {
    navigator.clipboard?.writeText(text);
    setCopiedIndex(index);
    setTimeout(() => setCopiedIndex(null), 2000);
  };

  const activeQuote = quotes[selectedQuoteIndex] || quotes[0];

  return (
    <div className="fixed inset-0 z-50 bg-black/40 backdrop-blur-xs flex items-end sm:items-center justify-center p-0 sm:p-4 animate-in fade-in">
      <div className="bg-[#FAF8F5] border border-[#E6E0D6] rounded-t-[28px] sm:rounded-[28px] max-w-lg w-full p-5 shadow-2xl relative max-h-[90vh] overflow-y-auto scrollbar-none">
        
        {/* M3 Drag Handle */}
        <div className="w-10 h-1 bg-[#E6E0D6] rounded-full mx-auto mb-3" />

        <button
          onClick={onClose}
          className="absolute top-4 right-4 p-2 rounded-full text-[#7A756C] hover:text-[#1D1B16] hover:bg-[#E8E2D5] transition active:scale-95"
        >
          <X className="w-5 h-5" />
        </button>

        <div className="flex items-center gap-3 mb-4">
          <div className="w-9 h-9 rounded-full bg-[#A23F1E] text-white flex items-center justify-center font-bold shadow-2xs shrink-0">
            <Sparkles className="w-4 h-4 text-amber-100" />
          </div>
          <div>
            <h3 className="font-bold text-base text-[#1D1B16]">AI 社交金句海报生成器</h3>
            <p className="text-[11px] text-[#7A756C]">生成治愈系短句，搭配数字名片导出朋友圈海报</p>
          </div>
        </div>

        {/* Input Topic */}
        <div className="flex gap-2 mb-3">
          <input
            type="text"
            value={topicInput}
            onChange={(e) => setTopicInput(e.target.value)}
            placeholder="输入主题，如：缓解职场焦虑、自我关怀..."
            className="flex-1 bg-white border border-[#E6E0D6] rounded-full px-3.5 py-1.5 text-xs text-[#1D1B16]"
          />
          <button
            onClick={handleGenerate}
            disabled={isLoading}
            className="px-4 py-1.5 rounded-full bg-[#6750A4] text-white text-xs font-semibold hover:bg-[#594294] transition shadow-2xs flex items-center gap-1 disabled:opacity-60 shrink-0 active:scale-95"
          >
            {isLoading ? <RefreshCw className="w-3.5 h-3.5 animate-spin" /> : <Sparkles className="w-3.5 h-3.5" />}
            <span>生成</span>
          </button>
        </div>

        {/* Quote Selection Pills - M3 Filter Chips */}
        <div className="flex items-center gap-1.5 overflow-x-auto pb-1 mb-3 scrollbar-none">
          {quotes.map((q, idx) => (
            <button
              key={q.id || idx}
              onClick={() => setSelectedQuoteIndex(idx)}
              className={`px-3 py-1 rounded-full text-[11px] font-semibold whitespace-nowrap transition active:scale-95 ${
                selectedQuoteIndex === idx
                  ? 'bg-[#6750A4] text-white shadow-2xs'
                  : 'bg-white border border-[#E6E0D6] text-[#49463D] hover:bg-[#E8E2D5]'
              }`}
            >
              {q.tag || `文案 ${idx + 1}`}
            </button>
          ))}
        </div>

        {/* Poster Card Live Visualizer */}
        <div className="bg-[#6750A4] rounded-[20px] p-5 text-white shadow-md space-y-3 relative overflow-hidden border border-[#386A20]/30">
          <div className="flex items-center justify-between text-[11px] text-emerald-200 font-medium">
            <span>#{activeQuote.tag || '心灵治愈'}</span>
            <span className="font-mono">心屿咨询 • 日历</span>
          </div>

          <div className="my-4 space-y-1.5">
            <h4 className="text-base font-bold text-[#FAF8F5]">“{activeQuote.title}”</h4>
            <p className="text-xs leading-relaxed text-emerald-50 italic">
              {activeQuote.quote}
            </p>
          </div>

          <div className="pt-3 border-t border-white/20 flex items-center justify-between">
            <div className="flex items-center gap-2.5">
              <img
                src={consultant.avatar}
                alt={consultant.name}
                className="w-9 h-9 rounded-full object-cover ring-2 ring-white/30"
              />
              <div>
                <div className="text-xs font-bold">{consultant.name}</div>
                <div className="text-[10px] text-emerald-200">{consultant.title}</div>
              </div>
            </div>

            <div className="bg-white/95 p-1 rounded-[10px] text-center shadow-2xs">
              <QrCode className="w-7 h-7 text-[#1D1B16]" />
              <span className="text-[7px] text-[#1D1B16] font-bold block">扫码预约</span>
            </div>
          </div>
        </div>

        {/* Actions */}
        <div className="flex items-center gap-2 mt-4">
          <button
            onClick={() => handleCopy(selectedQuoteIndex, `“${activeQuote.title}”\n${activeQuote.quote}\n—— ${consultant.name} 咨询师`)}
            className="flex-1 py-2 rounded-full border border-[#E6E0D6] bg-white text-xs font-semibold text-[#1D1B16] hover:bg-[#E8E2D5] transition flex items-center justify-center gap-1 active:scale-95"
          >
            {copiedIndex === selectedQuoteIndex ? <Check className="w-3.5 h-3.5 text-emerald-600" /> : <Copy className="w-3.5 h-3.5 text-[#6750A4]" />}
            <span>{copiedIndex === selectedQuoteIndex ? '已复制' : '复制文案'}</span>
          </button>

          <button
            onClick={() => alert('已为您导出海报图！')}
            className="flex-1 py-2 rounded-full bg-[#6750A4] text-white text-xs font-semibold hover:bg-[#594294] transition shadow-2xs flex items-center justify-center gap-1 active:scale-95"
          >
            <Download className="w-3.5 h-3.5" />
            <span>导出海报</span>
          </button>
        </div>

      </div>
    </div>
  );
};
