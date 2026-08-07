import { useEffect, useState } from "react";
import { motion } from "motion/react";
import { CheckCircle2, ChevronLeft, Hand, Pause, Play, RotateCcw, Volume2, VolumeX, Wind } from "lucide-react";

type ExerciseType = "breathing" | "rhythm";
type ExerciseStage = "intro" | "running" | "paused" | "reflect";

export function EmotionExercise({ type, onClose, onComplete }: { type: ExerciseType; onClose: () => void; onComplete: (score: number) => void }) {
  const isBreathing = type === "breathing";
  const [stage, setStage] = useState<ExerciseStage>("intro");
  const [phase, setPhase] = useState<"吸气" | "呼气">("吸气");
  const [phaseLeft, setPhaseLeft] = useState(4);
  const [round, setRound] = useState(1);
  const [timeLeft, setTimeLeft] = useState(60);
  const [tapCount, setTapCount] = useState(0);
  const [voiceOn, setVoiceOn] = useState(true);

  const speak = (text: string) => {
    if (!voiceOn || !("speechSynthesis" in window)) return;
    window.speechSynthesis.cancel();
    const utterance = new SpeechSynthesisUtterance(text);
    utterance.lang = "zh-CN";
    utterance.rate = .88;
    utterance.pitch = .95;
    window.speechSynthesis.speak(utterance);
  };

  useEffect(() => () => window.speechSynthesis?.cancel(), []);

  useEffect(() => {
    if (stage !== "running") return;
    if (isBreathing) speak(phase === "吸气" ? `第${round}轮，慢慢吸气` : "现在缓缓呼气，放松肩膀");
  // Voice prompt should only run when a new breathing phase starts.
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [stage, phase, round, isBreathing]);

  useEffect(() => {
    if (stage !== "running" || isBreathing) return;
    if (timeLeft === 30) speak("已经完成一半，继续按自己的节奏轻触");
    if (timeLeft === 10) speak("还有十秒，留意手指触碰的感觉");
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [timeLeft, stage, isBreathing]);

  useEffect(() => {
    if (stage !== "running") return;
    const timer = setInterval(() => {
      if (isBreathing) {
        setPhaseLeft((value) => {
          if (value > 1) return value - 1;
          if (phase === "吸气") {
            setPhase("呼气");
            return 6;
          }
          if (round >= 3) {
            speak("三轮呼吸完成了，慢慢睁开眼睛");
            setStage("reflect");
            return 0;
          }
          setRound((value) => value + 1);
          setPhase("吸气");
          return 4;
        });
      } else {
        setTimeLeft((value) => {
          if (value <= 1) {
            speak("练习完成，请停下来感受一下现在的状态");
            setStage("reflect");
            return 0;
          }
          return value - 1;
        });
      }
    }, 1000);
    return () => clearInterval(timer);
  }, [stage, isBreathing, phase, round]);

  const reset = () => {
    window.speechSynthesis?.cancel();
    setStage("intro");
    setPhase("吸气");
    setPhaseLeft(4);
    setRound(1);
    setTimeLeft(60);
    setTapCount(0);
  };

  const tap = () => {
    if (isBreathing || stage === "paused" || stage === "reflect") return;
    if (stage === "intro") setStage("running");
    setTapCount((value) => value + 1);
    navigator.vibrate?.(12);
  };

  return (
    <div className="absolute inset-0 z-[140] flex min-h-0 flex-col overflow-hidden bg-[#f7f6f1]">
      <div className="flex shrink-0 items-center justify-between px-5 pb-4 pt-12">
        <button onClick={onClose} aria-label="关闭练习" className="flex h-10 w-10 items-center justify-center rounded-full bg-white text-gray-600 shadow-sm"><ChevronLeft size={22} /></button>
        <div className="text-center"><h1 className="text-[16px] font-black text-gray-900">{isBreathing ? "延长呼气练习" : "节奏锚定练习"}</h1><p className="mt-1 text-[10px] font-bold tracking-wider text-gray-400">{isBreathing ? "3 ROUNDS" : "60 SECONDS"}</p></div>
        <div className="flex gap-2"><button onClick={() => { setVoiceOn((v) => !v); window.speechSynthesis?.cancel(); }} aria-label={voiceOn ? "关闭语音引导" : "开启语音引导"} className="flex h-10 w-10 items-center justify-center rounded-full bg-white text-gray-500 shadow-sm">{voiceOn ? <Volume2 size={18} /> : <VolumeX size={18} />}</button><button onClick={reset} aria-label="重新开始" className="flex h-10 w-10 items-center justify-center rounded-full bg-white text-gray-500 shadow-sm"><RotateCcw size={18} /></button></div>
      </div>

      <div className="flex min-h-0 flex-1 flex-col items-center justify-center px-6 pb-6 text-center">
        {stage === "intro" && <>
          <div className="mb-7 flex h-24 w-24 items-center justify-center rounded-[30px] bg-primary-light text-primary">{isBreathing ? <Wind size={40} /> : <Hand size={40} />}</div>
          <h2 className="text-[22px] font-black text-gray-900">{isBreathing ? "先让呼吸慢下来" : "把注意力带回此刻"}</h2>
          <p className="mt-3 max-w-[280px] text-[13px] leading-6 text-gray-500">{isBreathing ? "跟随圆形完成三轮呼吸：吸气 4 秒，呼气 6 秒。感觉不适时可以随时暂停。" : "每次轻触圆形都算一次节奏。无需追求速度，走神后只需回到下一次触碰。"}</p>
          <div className="mt-5 flex items-center gap-2 rounded-full bg-white/70 px-3 py-1.5 text-[11px] font-bold text-gray-500"><Volume2 size={14} />练习中会自动语音提醒</div>
          <button onClick={() => isBreathing ? setStage("running") : tap()} className="mt-5 w-full max-w-[320px] rounded-[18px] bg-primary py-4 text-[14px] font-black text-white shadow-[0_12px_30px_rgba(50,116,92,.22)]">{isBreathing ? "开始语音引导" : "轻触开始"}</button>
        </>}

        {(stage === "running" || stage === "paused") && <>
          {isBreathing ? <>
            <div className="mb-7 text-[11px] font-bold tracking-wider text-gray-400">第 {round} / 3 轮</div>
            <motion.div animate={{ scale: phase === "吸气" ? 1.25 : .82 }} transition={{ duration: phase === "吸气" ? 4 : 6, ease: "easeInOut" }} className="flex h-48 w-48 items-center justify-center rounded-full bg-gradient-to-br from-[#d7ebe1] to-[#8fc3aa] shadow-[0_20px_60px_rgba(50,116,92,.2)]">
              <div><div className="text-[28px] font-black text-[#1f5541]">{phase}</div><div className="mt-2 text-[18px] font-bold text-[#39725c]">{phaseLeft}</div></div>
            </motion.div>
            <p className="mt-8 text-[13px] text-gray-500">{phase === "吸气" ? "自然吸气，不需要吸得很满" : "缓慢呼出，让肩膀跟着放松"}</p>
          </> : <>
            <div className="mb-5 flex items-center gap-4 text-[12px] font-bold text-gray-500"><span>{60 - timeLeft}s 已进行</span><span className="h-1 w-1 rounded-full bg-gray-300" /><span>{tapCount} 次触碰</span></div>
            <motion.button whileTap={{ scale: .9 }} onClick={tap} className="flex h-56 w-56 items-center justify-center rounded-full bg-gradient-to-br from-[#f5ddb9] to-[#c88c45] shadow-[0_24px_70px_rgba(157,96,38,.25)]">
              <div className="flex h-40 w-40 items-center justify-center rounded-full border border-white/25 bg-[#8b5d2c] text-[58px] shadow-inner">🪵</div>
            </motion.button>
            <div className="mt-7 h-1.5 w-full max-w-[280px] overflow-hidden rounded-full bg-gray-200"><div className="h-full rounded-full bg-[#b47a39] transition-all" style={{ width: `${((60 - timeLeft) / 60) * 100}%` }} /></div>
            <p className="mt-4 text-[12px] text-gray-500">还剩 {timeLeft} 秒 · 按自己的节奏轻触</p>
          </>}
          <div className="mt-9 flex gap-3">
            <button onClick={() => { const resuming = stage === "paused"; setStage(resuming ? "running" : "paused"); if (!resuming) { window.speechSynthesis?.cancel(); speak("练习已暂停"); } }} className="flex items-center rounded-[16px] bg-white px-5 py-3 text-[12px] font-bold text-gray-700 shadow-sm">{stage === "paused" ? <Play size={16} className="mr-2" /> : <Pause size={16} className="mr-2" />}{stage === "paused" ? "继续" : "暂停"}</button>
            <button onClick={() => { window.speechSynthesis?.cancel(); speak("练习已结束，请感受一下现在的状态"); setStage("reflect"); }} className="rounded-[16px] bg-gray-900 px-5 py-3 text-[12px] font-bold text-white">结束练习</button>
          </div>
        </>}

        {stage === "reflect" && <>
          <div className="mb-6 flex h-20 w-20 items-center justify-center rounded-[26px] bg-primary-light text-primary"><CheckCircle2 size={38} /></div>
          <h2 className="text-[22px] font-black text-gray-900">练习完成</h2>
          <p className="mt-3 text-[13px] leading-6 text-gray-500">现在的紧绷或烦躁程度是多少？<br />1 表示很平静，5 表示仍然很强烈。</p>
          <div className="mt-8 grid w-full max-w-[320px] grid-cols-5 gap-2">{[1,2,3,4,5].map((score) => <button key={score} onClick={() => onComplete(score)} className="aspect-square rounded-[16px] bg-white text-[16px] font-black text-primary shadow-sm active:bg-primary active:text-white">{score}</button>)}</div>
          <p className="mt-3 text-[10px] text-gray-400">选择后返回与小鹿继续聊</p>
        </>}
      </div>
    </div>
  );
}
