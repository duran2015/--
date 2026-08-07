import { useMemo, useState } from "react";
import { AnimatePresence, motion } from "motion/react";
import { ArrowRight, Check, ChevronLeft, Copy, Link2, Lock, MessageCircle, RotateCcw, Share2, Sparkles, Users, X } from "lucide-react";
import { useAppStore } from "../../store";

type Stage = "landing" | "questions" | "invite" | "waiting" | "report";

const questions = [
  ["临时收到一个新任务，你通常会？", "先做起来再调整", "先确认目标与边界", "找搭档讨论一下", "排进计划再开始"],
  ["开会出现冷场时，你更可能？", "主动抛出一个观点", "等想清楚再发言", "邀请别人先说", "会后单独补充"],
  ["搭档的方案有明显漏洞，你会？", "直接指出问题", "先肯定再提建议", "用问题引导对方发现", "先自己补好再说"],
  ["截止时间突然提前，你的第一反应？", "马上冲刺交付", "重新拆分优先级", "同步风险寻求支持", "先焦虑但仍自己扛"],
  ["工作中你最需要搭档提供什么？", "行动与推进", "清晰与确定", "理解和支持", "空间与信任"],
  ["意见不一致时，你通常？", "当场辩清楚", "用事实做判断", "先维护关系氛围", "暂时沉默再消化"],
  ["做项目时你更自然承担？", "发起和推动", "规划和把关", "协调和连接", "深度执行"],
  ["被领导否定后，你更可能？", "快速调整再尝试", "复盘哪里有问题", "找人聊聊缓冲情绪", "反复怀疑自己的能力"],
  ["理想的工作沟通频率是？", "随时同步，快速响应", "关键节点集中同步", "每天互相确认状态", "需要时再沟通"],
  ["同事状态不好时，你会？", "帮他解决具体问题", "替他理清轻重缓急", "先听他说完", "尊重空间，不过度追问"],
  ["一项工作做到什么程度可以交付？", "先完成再迭代", "达到明确标准", "相关人都认可", "自己觉得足够好"],
  ["压力最大时，你最容易？", "变得急躁强势", "过度控制细节", "照顾别人忽略自己", "躲开沟通独自消化"],
];

const roleOptions = [
  { id: "buddy", emoji: "🤝", title: "职场搭子", desc: "一起扛项目、互相接住" },
  { id: "coworker", emoji: "💻", title: "合作同事", desc: "经常协作但还不够了解" },
  { id: "partner", emoji: "🚀", title: "创业搭档", desc: "一起做决定、承担风险" },
];

export function WorkBuddyTest() {
  const { popView, pushView } = useAppStore();
  const [stage, setStage] = useState<Stage>("landing");
  const [role, setRole] = useState("buddy");
  const [question, setQuestion] = useState(0);
  const [answers, setAnswers] = useState<number[]>([]);
  const [shared, setShared] = useState(false);
  const [showShare, setShowShare] = useState(false);
  const [copied, setCopied] = useState(false);

  const relation = useMemo(() => {
    const decisive = answers.filter((v) => v < 2).length;
    return decisive >= 7
      ? { title: "双引擎推进组", emoji: "⚡", sub: "一个敢开路，一个会把路铺稳", score: 91 }
      : { title: "灵感与稳定器", emoji: "🪁", sub: "你负责看见可能，TA负责让它发生", score: 86 };
  }, [answers]);

  const answer = (index: number) => {
    const next = [...answers]; next[question] = index; setAnswers(next);
    window.setTimeout(() => question < questions.length - 1 ? setQuestion((q) => q + 1) : setStage("invite"), 180);
  };

  const copyInvite = async () => {
    await navigator.clipboard?.writeText("我测了一半，剩下需要你来完成：看看我们是哪种职场搭子 → https://kelo.example/buddy/KL2607");
    setCopied(true); setShared(true); window.setTimeout(() => setCopied(false), 1600);
  };

  const restart = () => { setStage("landing"); setQuestion(0); setAnswers([]); setShared(false); };

  return (
    <motion.div initial={{ opacity: 0, x: 20 }} animate={{ opacity: 1, x: 0 }} exit={{ opacity: 0, x: 20 }} className="fixed inset-0 z-50 flex flex-col overflow-hidden bg-[#f7f7f3]">
      <header className="flex h-[calc(56px+env(safe-area-inset-top))] shrink-0 items-end px-4 pb-2">
        <button onClick={popView} aria-label="返回" className="grid h-10 w-10 place-items-center rounded-full bg-white shadow-sm"><ChevronLeft size={22} /></button>
        <div className="flex-1 pb-2 text-center text-[15px] font-black text-gray-900">职场关系实验室</div>
        <button onClick={restart} aria-label="重新测试" className="grid h-10 w-10 place-items-center rounded-full bg-white text-gray-500 shadow-sm"><RotateCcw size={17} /></button>
      </header>

      <main className="min-h-0 flex-1 overflow-y-auto">
        <AnimatePresence mode="wait">
          {stage === "landing" && <motion.section key="landing" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} className="px-5 pb-8 pt-4">
            <div className="relative overflow-hidden rounded-[32px] bg-[#242641] px-6 pb-7 pt-8 text-white shadow-[0_24px_70px_rgba(35,37,65,.25)]">
              <div className="absolute -right-8 -top-10 h-40 w-40 rounded-full bg-[#ffca75]/20" /><div className="absolute -bottom-14 -left-8 h-44 w-44 rounded-full bg-[#8de0c0]/15" />
              <div className="relative"><span className="rounded-full bg-white/10 px-3 py-1.5 text-[11px] font-bold">双人完成 · 约 3 分钟</span><div className="mt-9 flex gap-2 text-5xl"><span>🧑🏻‍💻</span><span className="mt-4">🤝</span><span>👩🏻‍💻</span></div><h1 className="mt-6 text-[30px] font-black leading-[1.25]">你和 TA 是哪种<br />职场搭子？</h1><p className="mt-4 max-w-[290px] text-[14px] leading-6 text-white/65">不是判断谁更优秀，而是看见你们如何沟通、推进，以及压力来时怎样互相影响。</p></div>
            </div>
            <div className="mt-7"><h2 className="text-[15px] font-black text-gray-900">先选择你们的关系</h2><div className="mt-3 space-y-3">{roleOptions.map((item) => <button key={item.id} onClick={() => setRole(item.id)} className={`flex w-full items-center rounded-[20px] border p-4 text-left ${role === item.id ? "border-[#4b4f82] bg-[#f0f0fa]" : "border-gray-100 bg-white"}`}><span className="mr-3 text-2xl">{item.emoji}</span><span className="flex-1"><b className="block text-[14px] text-gray-900">{item.title}</b><small className="mt-1 block text-[11px] text-gray-500">{item.desc}</small></span>{role === item.id && <Check size={18} className="text-[#4b4f82]" />}</button>)}</div></div>
            <button onClick={() => setStage("questions")} className="mt-7 flex h-14 w-full items-center justify-center gap-2 rounded-[18px] bg-[#4b4f82] text-[14px] font-black text-white shadow-lg">先完成我的部分 <ArrowRight size={18} /></button>
            <p className="mt-3 text-center text-[10px] text-gray-400"><Lock size={11} className="mr-1 inline" />答案不会直接展示给对方</p>
          </motion.section>}

          {stage === "questions" && <motion.section key="questions" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} className="flex min-h-full flex-col px-5 pb-8 pt-3">
            <div className="flex items-center justify-between text-[11px] font-bold text-gray-400"><span>我的工作习惯</span><span>{question + 1} / {questions.length}</span></div>
            <div className="mt-3 h-1.5 overflow-hidden rounded-full bg-gray-200"><motion.div animate={{ width: `${((question + 1) / questions.length) * 100}%` }} className="h-full rounded-full bg-[#65699b]" /></div>
            <motion.div key={question} initial={{ opacity: 0, x: 18 }} animate={{ opacity: 1, x: 0 }} className="mt-12"><span className="text-4xl">{["🗂️","🗣️","🔍","⏰"][question % 4]}</span><h2 className="mt-6 text-[23px] font-black leading-9 text-gray-900">{questions[question][0]}</h2><p className="mt-2 text-xs text-gray-400">选择更接近真实反应的一项</p><div className="mt-8 space-y-3">{questions[question].slice(1).map((option, index) => <button key={option} onClick={() => answer(index)} className={`flex min-h-14 w-full items-center rounded-[18px] border bg-white px-4 text-left text-[14px] font-bold transition ${answers[question] === index ? "border-[#65699b] bg-[#f0f0fa] text-[#4b4f82]" : "border-gray-100 text-gray-700 active:border-[#a9acd0]"}`}><span className="mr-3 text-[11px] text-gray-300">{String.fromCharCode(65 + index)}</span>{option}</button>)}</div></motion.div>
            {question > 0 && <button onClick={() => setQuestion((q) => q - 1)} className="mt-auto pt-8 text-xs font-bold text-gray-400">返回上一题</button>}
          </motion.section>}

          {stage === "invite" && <motion.section key="invite" initial={{ opacity: 0, y: 16 }} animate={{ opacity: 1, y: 0 }} className="px-5 pb-8 pt-7 text-center">
            <div className="mx-auto grid h-20 w-20 place-items-center rounded-[26px] bg-[#e9f7f1] text-[#32745c]"><Check size={36} /></div><h2 className="mt-6 text-2xl font-black text-gray-900">你的部分完成了</h2><p className="mx-auto mt-3 max-w-[280px] text-[13px] leading-6 text-gray-500">完整结果需要 TA 回答同一组情境题。双方答案保持私密，只展示你们的关系模式。</p>
            <div className="mt-8 rounded-[26px] bg-[#242641] p-5 text-left text-white"><div className="flex items-center gap-3"><div className="grid h-12 w-12 place-items-center rounded-2xl bg-white/10 text-2xl">🤝</div><div><b className="text-[15px]">职场搭子邀请</b><p className="mt-1 text-[11px] text-white/55">可鹿 · 双人关系测试</p></div></div><p className="mt-5 text-[14px] font-bold leading-6">“我测了一半，剩下需要你来完成。看看我们是哪种职场搭子？”</p><div className="mt-4 rounded-xl bg-white/8 px-3 py-2 text-[10px] text-white/50">邀请码 · KL2607</div></div>
            <button onClick={copyInvite} className="mt-6 flex h-14 w-full items-center justify-center gap-2 rounded-[18px] bg-[#4b4f82] font-black text-white">{copied ? <Check size={19} /> : <Share2 size={19} />}{copied ? "邀请文案已复制" : "发送给职场搭子"}</button>
            <button onClick={() => setStage(shared ? "waiting" : "waiting")} className="mt-3 h-12 w-full rounded-[16px] bg-white text-[13px] font-bold text-gray-600 shadow-sm">预览 TA 收到后的流程</button>
          </motion.section>}

          {stage === "waiting" && <motion.section key="waiting" initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="flex min-h-full flex-col items-center px-5 pb-8 pt-10 text-center">
            <div className="relative"><div className="grid h-28 w-28 place-items-center rounded-full bg-[#ececf6] text-5xl">👩🏻‍💻</div><motion.div animate={{ scale: [1, 1.15, 1] }} transition={{ repeat: Infinity, duration: 1.8 }} className="absolute -bottom-1 -right-1 grid h-10 w-10 place-items-center rounded-full border-4 border-[#f7f7f3] bg-[#ffca75] text-lg">✍️</motion.div></div><h2 className="mt-8 text-2xl font-black text-gray-900">等待 TA 完成</h2><p className="mt-3 text-[13px] leading-6 text-gray-500">好友打开邀请后，会先看到你的称呼和测试说明，再独立完成 12 道题。</p>
            <div className="mt-8 w-full rounded-[22px] bg-white p-4 text-left shadow-sm"><div className="flex items-center justify-between"><span className="text-[13px] font-bold text-gray-800">好友端完成进度</span><span className="text-[11px] font-bold text-[#4b4f82]">模拟中</span></div><div className="mt-3 h-2 overflow-hidden rounded-full bg-gray-100"><motion.div initial={{ width: 0 }} animate={{ width: "100%" }} transition={{ duration: 2.2 }} onAnimationComplete={() => setShared(true)} className="h-full bg-[#7f83b4]" /></div></div>
            <button disabled={!shared} onClick={() => setStage("report")} className="mt-auto h-14 w-full rounded-[18px] bg-[#4b4f82] font-black text-white disabled:opacity-35">{shared ? "查看双人关系报告" : "TA 正在完成测试…"}</button>
          </motion.section>}

          {stage === "report" && <motion.section key="report" initial={{ opacity: 0, y: 18 }} animate={{ opacity: 1, y: 0 }} className="pb-10">
            <div className="mx-5 rounded-[32px] bg-gradient-to-br from-[#292b4d] to-[#4f527e] p-6 text-white shadow-xl"><div className="flex items-center justify-between text-[10px] font-bold tracking-wider text-white/50"><span>你 × 职场搭子</span><span>关系编号 08</span></div><div className="mt-8 text-6xl">{relation.emoji}</div><p className="mt-6 text-[11px] font-bold text-[#ffda96]">你们是</p><h1 className="mt-2 text-[30px] font-black">{relation.title}</h1><p className="mt-3 text-[14px] text-white/65">{relation.sub}</p><div className="mt-7 flex items-end gap-2"><b className="text-5xl font-black">{relation.score}</b><span className="pb-1 text-xs text-white/50">默契指数</span></div></div>
            <div className="px-5"><h2 className="mt-8 text-[16px] font-black text-gray-900">你们如何一起工作</h2><div className="mt-4 grid grid-cols-2 gap-3">{[["沟通默契",88],["决策互补",93],["执行配合",90],["压力兼容",72]].map(([label, value]) => <div key={String(label)} className="rounded-[20px] bg-white p-4 shadow-sm"><div className="flex justify-between text-[11px]"><b>{label}</b><span className="text-[#65699b]">{value}</span></div><div className="mt-3 h-1.5 rounded-full bg-gray-100"><div className="h-full rounded-full bg-[#7f83b4]" style={{ width: `${value}%` }} /></div></div>)}</div>
              <div className="mt-6 rounded-[24px] bg-white p-5 shadow-sm"><span className="text-[11px] font-bold text-[#a36d22]">最值得注意的差异</span><h3 className="mt-3 text-[16px] font-black leading-6">你想快速解决问题，TA 更需要先确认彼此理解一致</h3><p className="mt-3 text-[12px] leading-6 text-gray-500">这不是效率差异，而是安全感来源不同。重要任务开始前，多用一句“我们理解的是同一件事吗？”</p></div>
              <div className="mt-4 rounded-[24px] bg-[#eaf6f1] p-5"><h3 className="text-[14px] font-black text-[#245b46]">你们的协作约定</h3>{["需求变化时先同步优先级", "沉默不默认代表同意", "冲突时先讨论目标，再讨论做法"].map((text) => <div key={text} className="mt-3 flex items-center text-[12px] font-bold text-[#356b56]"><Check size={15} className="mr-2" />{text}</div>)}</div>
              <button onClick={() => setShowShare(true)} className="mt-6 flex h-14 w-full items-center justify-center gap-2 rounded-[18px] bg-[#4b4f82] font-black text-white"><Share2 size={18} />分享我们的关系卡</button>
              <button onClick={() => pushView("ai-chat")} className="mt-3 flex h-14 w-full items-center justify-center gap-2 rounded-[18px] border border-gray-200 bg-white font-black text-gray-700"><Lock size={16} />查看只对我可见的职场模式</button>
            </div>
          </motion.section>}
        </AnimatePresence>
      </main>

      <AnimatePresence>{showShare && <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="absolute inset-0 z-20 flex items-end bg-black/35" onClick={() => setShowShare(false)}><motion.div initial={{ y: "100%" }} animate={{ y: 0 }} exit={{ y: "100%" }} onClick={(e) => e.stopPropagation()} className="w-full rounded-t-[30px] bg-white p-5 pb-[calc(20px+env(safe-area-inset-bottom))]"><div className="flex items-center justify-between"><h3 className="text-[17px] font-black">分享关系卡</h3><button onClick={() => setShowShare(false)} className="grid h-9 w-9 place-items-center rounded-full bg-gray-100"><X size={18} /></button></div><div className="mt-5 rounded-[24px] bg-[#292b4d] p-5 text-white"><div className="text-4xl">{relation.emoji}</div><div className="mt-4 text-[11px] text-white/50">我和我的职场搭子是</div><div className="mt-1 text-2xl font-black">{relation.title}</div><div className="mt-3 text-xs text-white/60">默契指数 {relation.score} · 一个敢开路，一个把路铺稳</div></div><p className="mt-4 text-center text-[11px] text-gray-400">分享卡只展示关系结果，不展示任何个人答案</p><div className="mt-5 grid grid-cols-3 gap-3">{[[MessageCircle,"发给好友"],[Copy,"复制链接"],[Link2,"更多"]].map(([Icon, label]) => { const I = Icon as typeof MessageCircle; return <button key={String(label)} onClick={copyInvite} className="flex flex-col items-center rounded-2xl bg-gray-50 py-4 text-[11px] font-bold text-gray-600"><span className="mb-2 grid h-10 w-10 place-items-center rounded-full bg-white text-[#4b4f82] shadow-sm"><I size={18} /></span>{label as string}</button>; })}</div></motion.div></motion.div>}</AnimatePresence>
    </motion.div>
  );
}
