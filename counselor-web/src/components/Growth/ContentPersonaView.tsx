import React, { useState } from 'react';
import { 
  ArrowLeft, Sparkles, CheckCircle2, ChevronRight, 
  UserCircle, Target, Users, Heart, Lightbulb,
  FileText, ArrowRight, Wand2
} from 'lucide-react';

interface ContentPersonaViewProps {
  onBack: () => void;
  onComplete: () => void;
}

export const ContentPersonaView: React.FC<ContentPersonaViewProps> = ({ onBack, onComplete }) => {
  const [step, setStep] = useState(0); // 0 = Intro, 1-5 = Config, 6 = Generating, 7 = Result

  // Persona State
  const [identity, setIdentity] = useState('');
  const [expertise, setExpertise] = useState<string[]>([]);
  const [targetUser, setTargetUser] = useState('');
  const [style, setStyle] = useState<string[]>([]);
  const [goal, setGoal] = useState<string[]>([]);

  const toggleSelection = (item: string, list: string[], setList: (l: string[]) => void, max?: number) => {
    if (list.includes(item)) {
      setList(list.filter(i => i !== item));
    } else {
      if (max && list.length >= max) return;
      setList([...list, item]);
    }
  };

  const nextStep = () => setStep(prev => prev + 1);
  const prevStep = () => setStep(prev => prev - 1);

  const handleGenerate = () => {
    setStep(6);
    setTimeout(() => {
      setStep(7);
    }, 2500);
  };

  // --- Views ---

  const IntroView = () => (
    <div className="flex flex-col items-center justify-center h-full py-12 animate-in fade-in duration-300">
      <div className="w-24 h-24 bg-[#EADDFF] rounded-full flex items-center justify-center mb-8">
        <Sparkles className="w-10 h-10 text-[#6750A4]" />
      </div>
      <h2 className="text-2xl font-bold text-[#1D1B16] mb-3 text-center tracking-tight">
        打造你的 AI 内容助手
      </h2>
      <p className="text-[15px] text-[#7A756C] font-medium text-center px-8 mb-12 leading-relaxed">
        完善你的专业定位，AI 会根据你的方向、人群与风格，为你生成高度个性化的专属内容。
      </p>
      <button 
        onClick={nextStep}
        className="w-[280px] py-4 bg-[#6750A4] text-white rounded-full font-bold text-[16px] hover:bg-[#594294] active:scale-95 transition shadow-sm"
      >
        开始设置
      </button>
    </div>
  );

  const Step1View = () => (
    <div className="space-y-6 animate-in slide-in-from-right-8 duration-300">
      <div>
        <div className="text-[12px] font-bold text-[#6750A4] mb-2">Step 1 / 5</div>
        <h2 className="text-xl font-bold text-[#1D1B16] mb-2 tracking-tight">你的专业身份是？</h2>
        <p className="text-[13px] text-[#7A756C] font-medium">这将决定 AI 称呼你和生成内容时的专业口吻。</p>
      </div>
      <div className="space-y-3">
        {['心理咨询师', '督导师', '情绪陪伴师', '生涯规划师', '心理科普作者'].map(item => (
          <button
            key={item}
            onClick={() => setIdentity(item)}
            className={`w-full text-left p-4 rounded-[20px] border transition flex items-center justify-between group ${
              identity === item 
                ? 'bg-[#EADDFF] border-[#D0BCFF] text-[#4F378B]' 
                : 'bg-white border-[#E6E0D6] text-[#49463D] hover:bg-[#FAF8F5]'
            }`}
          >
            <span className="font-bold text-[15px]">{item}</span>
            {identity === item && <CheckCircle2 className="w-5 h-5 text-[#6750A4]" />}
          </button>
        ))}
      </div>
      <div className="pt-4">
        <button 
          onClick={nextStep}
          disabled={!identity}
          className={`w-full py-3.5 rounded-full font-bold text-[16px] transition flex items-center justify-center gap-2 ${
            identity ? 'bg-[#6750A4] text-white shadow-sm hover:bg-[#594294]' : 'bg-[#E7E0EC] text-[#A09C94] cursor-not-allowed'
          }`}
        >
          下一步 <ArrowRight className="w-4 h-4" />
        </button>
      </div>
    </div>
  );

  const Step2View = () => (
    <div className="space-y-6 animate-in slide-in-from-right-8 duration-300">
      <div>
        <div className="text-[12px] font-bold text-[#6750A4] mb-2">Step 2 / 5</div>
        <h2 className="text-xl font-bold text-[#1D1B16] mb-2 tracking-tight">你的核心方向？</h2>
        <p className="text-[13px] text-[#7A756C] font-medium">选择你最擅长和想表达的领域 (最多3个)。</p>
      </div>
      
      <div className="space-y-5">
        <div>
          <h4 className="text-[13px] font-bold text-[#A09C94] mb-3">情绪与压力</h4>
          <div className="flex flex-wrap gap-2">
            {['焦虑', '压力管理', '情绪调节', '内耗'].map(item => (
              <button
                key={item}
                onClick={() => toggleSelection(item, expertise, setExpertise, 3)}
                className={`px-4 py-2 rounded-full border transition text-[13px] font-bold active:scale-95 ${
                  expertise.includes(item)
                    ? 'bg-[#EADDFF] border-[#D0BCFF] text-[#4F378B]'
                    : 'bg-white border-[#E6E0D6] text-[#7A756C] hover:bg-[#FAF8F5]'
                }`}
              >
                {item}
              </button>
            ))}
          </div>
        </div>
        <div>
          <h4 className="text-[13px] font-bold text-[#A09C94] mb-3">职场成长</h4>
          <div className="flex flex-wrap gap-2">
            {['职场压力', '职业发展', '管理者心理'].map(item => (
              <button
                key={item}
                onClick={() => toggleSelection(item, expertise, setExpertise, 3)}
                className={`px-4 py-2 rounded-full border transition text-[13px] font-bold active:scale-95 ${
                  expertise.includes(item)
                    ? 'bg-[#EADDFF] border-[#D0BCFF] text-[#4F378B]'
                    : 'bg-white border-[#E6E0D6] text-[#7A756C] hover:bg-[#FAF8F5]'
                }`}
              >
                {item}
              </button>
            ))}
          </div>
        </div>
        <div>
          <h4 className="text-[13px] font-bold text-[#A09C94] mb-3">关系与成长</h4>
          <div className="flex flex-wrap gap-2">
            {['亲密关系', '家庭关系', '女性成长', '自我探索'].map(item => (
              <button
                key={item}
                onClick={() => toggleSelection(item, expertise, setExpertise, 3)}
                className={`px-4 py-2 rounded-full border transition text-[13px] font-bold active:scale-95 ${
                  expertise.includes(item)
                    ? 'bg-[#EADDFF] border-[#D0BCFF] text-[#4F378B]'
                    : 'bg-white border-[#E6E0D6] text-[#7A756C] hover:bg-[#FAF8F5]'
                }`}
              >
                {item}
              </button>
            ))}
          </div>
        </div>
      </div>

      <div className="flex gap-3 pt-4">
        <button onClick={prevStep} className="w-14 h-[52px] rounded-full bg-white border border-[#E6E0D6] flex items-center justify-center text-[#49463D] hover:bg-[#FAF8F5] transition">
          <ArrowLeft className="w-5 h-5" />
        </button>
        <button 
          onClick={nextStep}
          disabled={expertise.length === 0}
          className={`flex-1 py-3.5 rounded-full font-bold text-[16px] transition flex items-center justify-center gap-2 ${
            expertise.length > 0 ? 'bg-[#6750A4] text-white shadow-sm hover:bg-[#594294]' : 'bg-[#E7E0EC] text-[#A09C94] cursor-not-allowed'
          }`}
        >
          下一步
        </button>
      </div>
    </div>
  );

  const Step3View = () => (
    <div className="space-y-6 animate-in slide-in-from-right-8 duration-300">
      <div>
        <div className="text-[12px] font-bold text-[#6750A4] mb-2">Step 3 / 5</div>
        <h2 className="text-xl font-bold text-[#1D1B16] mb-2 tracking-tight">你想写给谁看？</h2>
        <p className="text-[13px] text-[#7A756C] font-medium">精准的目标用户能让内容更有共鸣。</p>
      </div>
      <div className="space-y-3">
        {['职场新人 (20-25岁)', '城市职场女性 (25-35岁)', '高压管理者 (30-45岁)', '新手父母 (28-40岁)', '迷茫的大学生'].map(item => (
          <button
            key={item}
            onClick={() => setTargetUser(item)}
            className={`w-full text-left p-4 rounded-[20px] border transition flex items-center justify-between group ${
              targetUser === item 
                ? 'bg-[#EADDFF] border-[#D0BCFF] text-[#4F378B]' 
                : 'bg-white border-[#E6E0D6] text-[#49463D] hover:bg-[#FAF8F5]'
            }`}
          >
            <span className="font-bold text-[15px]">{item}</span>
            {targetUser === item && <CheckCircle2 className="w-5 h-5 text-[#6750A4]" />}
          </button>
        ))}
      </div>
      <div className="flex gap-3 pt-4">
        <button onClick={prevStep} className="w-14 h-[52px] rounded-full bg-white border border-[#E6E0D6] flex items-center justify-center text-[#49463D] hover:bg-[#FAF8F5] transition">
          <ArrowLeft className="w-5 h-5" />
        </button>
        <button 
          onClick={nextStep}
          disabled={!targetUser}
          className={`flex-1 py-3.5 rounded-full font-bold text-[16px] transition flex items-center justify-center gap-2 ${
            targetUser ? 'bg-[#6750A4] text-white shadow-sm hover:bg-[#594294]' : 'bg-[#E7E0EC] text-[#A09C94] cursor-not-allowed'
          }`}
        >
          下一步
        </button>
      </div>
    </div>
  );

  const Step4View = () => (
    <div className="space-y-6 animate-in slide-in-from-right-8 duration-300">
      <div>
        <div className="text-[12px] font-bold text-[#6750A4] mb-2">Step 4 / 5</div>
        <h2 className="text-xl font-bold text-[#1D1B16] mb-2 tracking-tight">你的表达风格？</h2>
        <p className="text-[13px] text-[#7A756C] font-medium">选择最符合你个人调性的风格 (可多选)。</p>
      </div>
      
      <div className="grid grid-cols-2 gap-3">
        {['专业科普型', '温暖陪伴型', '故事分享型', '成长导师型', '犀利观点型', '轻松治愈型'].map(item => (
          <button
            key={item}
            onClick={() => toggleSelection(item, style, setStyle)}
            className={`p-4 rounded-[20px] border transition text-center flex flex-col items-center justify-center gap-2 active:scale-95 ${
              style.includes(item)
                ? 'bg-[#EADDFF] border-[#D0BCFF] text-[#4F378B]'
                : 'bg-white border-[#E6E0D6] text-[#7A756C] hover:bg-[#FAF8F5]'
            }`}
          >
            <span className="font-bold text-[14px]">{item}</span>
          </button>
        ))}
      </div>

      <div className="flex gap-3 pt-4">
        <button onClick={prevStep} className="w-14 h-[52px] rounded-full bg-white border border-[#E6E0D6] flex items-center justify-center text-[#49463D] hover:bg-[#FAF8F5] transition">
          <ArrowLeft className="w-5 h-5" />
        </button>
        <button 
          onClick={nextStep}
          disabled={style.length === 0}
          className={`flex-1 py-3.5 rounded-full font-bold text-[16px] transition flex items-center justify-center gap-2 ${
            style.length > 0 ? 'bg-[#6750A4] text-white shadow-sm hover:bg-[#594294]' : 'bg-[#E7E0EC] text-[#A09C94] cursor-not-allowed'
          }`}
        >
          下一步
        </button>
      </div>
    </div>
  );

  const Step5View = () => (
    <div className="space-y-6 animate-in slide-in-from-right-8 duration-300">
      <div>
        <div className="text-[12px] font-bold text-[#6750A4] mb-2">Step 5 / 5</div>
        <h2 className="text-xl font-bold text-[#1D1B16] mb-2 tracking-tight">做内容的最终目标？</h2>
        <p className="text-[13px] text-[#7A756C] font-medium">这将决定 AI 给你推荐的选题策略 (可多选)。</p>
      </div>
      
      <div className="space-y-3">
        {['获取咨询客户', '提升专业影响力', '建立个人品牌', '扩大粉丝基数'].map(item => (
          <button
            key={item}
            onClick={() => toggleSelection(item, goal, setGoal)}
            className={`w-full text-left p-4 rounded-[20px] border transition flex items-center justify-between group ${
              goal.includes(item) 
                ? 'bg-[#EADDFF] border-[#D0BCFF] text-[#4F378B]' 
                : 'bg-white border-[#E6E0D6] text-[#49463D] hover:bg-[#FAF8F5]'
            }`}
          >
            <span className="font-bold text-[15px]">{item}</span>
            {goal.includes(item) && <CheckCircle2 className="w-5 h-5 text-[#6750A4]" />}
          </button>
        ))}
      </div>

      <div className="flex gap-3 pt-4">
        <button onClick={prevStep} className="w-14 h-[52px] rounded-full bg-white border border-[#E6E0D6] flex items-center justify-center text-[#49463D] hover:bg-[#FAF8F5] transition">
          <ArrowLeft className="w-5 h-5" />
        </button>
        <button 
          onClick={handleGenerate}
          disabled={goal.length === 0}
          className={`flex-1 py-3.5 rounded-full font-bold text-[16px] transition flex items-center justify-center gap-2 ${
            goal.length > 0 ? 'bg-[#6750A4] text-white shadow-sm hover:bg-[#594294]' : 'bg-[#E7E0EC] text-[#A09C94] cursor-not-allowed'
          }`}
        >
          <Wand2 className="w-5 h-5" /> 生成 AI 画像
        </button>
      </div>
    </div>
  );

  const GeneratingView = () => (
    <div className="flex flex-col items-center justify-center py-24 animate-in fade-in duration-300">
      <div className="w-24 h-24 bg-[#EADDFF] rounded-[32px] flex items-center justify-center mb-8 relative">
        <div className="absolute inset-0 border-4 border-[#D0BCFF] rounded-[32px] animate-ping opacity-75"></div>
        <UserCircle className="w-12 h-12 text-[#6750A4] animate-pulse" />
      </div>
      <h3 className="font-bold text-[20px] text-[#1D1B16] mb-3">正在构建 AI 内容大脑...</h3>
      <p className="text-[14px] text-[#7A756C] font-medium animate-pulse text-center px-6 leading-relaxed">
        正在将你的专业方向与目标用户匹配<br/>注入你的专属表达风格
      </p>
      
      <div className="w-64 bg-[#E7E0EC] h-2 rounded-full mt-10 overflow-hidden">
        <div className="bg-[#6750A4] h-full rounded-full w-1/2 animate-[progress_2s_ease-in-out_infinite]"></div>
      </div>
    </div>
  );

  const ResultView = () => (
    <div className="space-y-5 animate-in fade-in slide-in-from-bottom-4 duration-500 min-h-full pb-6">
      <div className="text-center mb-6">
        <div className="inline-flex items-center justify-center w-16 h-16 bg-[#EADDFF] rounded-full mb-3 shadow-sm">
          <CheckCircle2 className="w-8 h-8 text-[#6750A4]" />
        </div>
        <h2 className="text-xl font-bold text-[#1D1B16] tracking-tight">你的专属 AI 定位已生成</h2>
        <p className="text-[13px] text-[#7A756C] font-medium mt-1">后续所有 AI 工具都将基于此设定为你服务</p>
      </div>

      <div className="bg-white border border-[#E6E0D6] rounded-[28px] p-6 shadow-sm space-y-6 relative overflow-hidden">
        <div className="absolute top-0 right-0 w-32 h-32 bg-[#EADDFF]/30 rounded-full blur-3xl -mr-10 -mt-10" />
        
        {/* 身份 & 目标 */}
        <div className="flex gap-4 relative z-10">
          <div className="w-12 h-12 rounded-[16px] bg-[#FAF8F5] flex items-center justify-center text-[#49463D] shrink-0">
            <Target className="w-6 h-6" />
          </div>
          <div>
            <div className="text-[12px] font-bold text-[#A09C94] mb-1">你是一名</div>
            <div className="text-[15px] font-bold text-[#1D1B16]">{identity}</div>
          </div>
        </div>

        {/* 用户 */}
        <div className="flex gap-4 relative z-10">
          <div className="w-12 h-12 rounded-[16px] bg-[#FAF8F5] flex items-center justify-center text-[#49463D] shrink-0">
            <Users className="w-6 h-6" />
          </div>
          <div>
            <div className="text-[12px] font-bold text-[#A09C94] mb-1">主要服务</div>
            <div className="text-[15px] font-bold text-[#1D1B16]">{targetUser}</div>
          </div>
        </div>

        {/* 领域 */}
        <div className="flex gap-4 relative z-10">
          <div className="w-12 h-12 rounded-[16px] bg-[#FAF8F5] flex items-center justify-center text-[#49463D] shrink-0">
            <Lightbulb className="w-6 h-6" />
          </div>
          <div>
            <div className="text-[12px] font-bold text-[#A09C94] mb-2">核心主题</div>
            <div className="flex flex-wrap gap-2">
              {expertise.map(e => (
                <span key={e} className="text-[12px] bg-[#F5F5F5] text-[#49463D] px-2 py-1 rounded-md font-bold">{e}</span>
              ))}
            </div>
          </div>
        </div>

        {/* 风格 */}
        <div className="flex gap-4 relative z-10">
          <div className="w-12 h-12 rounded-[16px] bg-[#FAF8F5] flex items-center justify-center text-[#49463D] shrink-0">
            <Heart className="w-6 h-6" />
          </div>
          <div>
            <div className="text-[12px] font-bold text-[#A09C94] mb-2">内容风格</div>
            <div className="flex flex-wrap gap-2">
              {style.map(s => (
                <span key={s} className="text-[12px] bg-[#EADDFF] text-[#4F378B] px-2 py-1 rounded-md font-bold">{s}</span>
              ))}
            </div>
          </div>
        </div>
      </div>

      <div className="bg-[#FAF8F5] border border-[#ECE6DC] rounded-[24px] p-5">
        <h3 className="text-[13px] font-bold text-[#1D1B16] mb-3 flex items-center gap-2">
          <FileText className="w-4 h-4 text-[#6750A4]" /> AI 推荐的首批创作方向
        </h3>
        <ul className="space-y-2">
          <li className="text-[13px] text-[#49463D] font-medium bg-white p-3 rounded-[12px] border border-[#E6E0D6]">
            1. 针对 {targetUser} 的 {expertise[0] || '心理'} 解决方案
          </li>
          <li className="text-[13px] text-[#49463D] font-medium bg-white p-3 rounded-[12px] border border-[#E6E0D6]">
            2. 真实案例洞察：如何应对 {expertise[1] || '压力'}
          </li>
        </ul>
      </div>

      <div className="pt-2 flex flex-col gap-3">
        <button 
          onClick={onComplete}
          className="w-full py-4 bg-[#6750A4] text-white rounded-full font-bold text-[16px] hover:bg-[#594294] active:scale-95 transition shadow-sm flex items-center justify-center gap-2"
        >
          <Sparkles className="w-5 h-5" /> 进入 AI 选题灵感
        </button>
        <button 
          onClick={() => setStep(1)}
          className="w-full py-3 bg-transparent text-[#7A756C] font-bold text-[14px] hover:text-[#1D1B16] transition"
        >
          重新调整定位
        </button>
      </div>
    </div>
  );

  return (
    <div className="space-y-4 min-h-full pb-6">
      {/* Header (Only show on steps 1-5) */}
      {step > 0 && step < 6 && (
        <div className="flex items-center gap-3 pb-4">
          <button 
            onClick={step === 1 ? onBack : prevStep}
            className="w-10 h-10 flex items-center justify-center bg-white border border-[#E6E0D6] rounded-full text-[#49463D] hover:bg-[#FAF8F5] active:scale-95 transition shadow-sm"
          >
            <ArrowLeft className="w-5 h-5" />
          </button>
        </div>
      )}

      {step === 0 && <IntroView />}
      {step === 1 && <Step1View />}
      {step === 2 && <Step2View />}
      {step === 3 && <Step3View />}
      {step === 4 && <Step4View />}
      {step === 5 && <Step5View />}
      {step === 6 && <GeneratingView />}
      {step === 7 && <ResultView />}
    </div>
  );
};
