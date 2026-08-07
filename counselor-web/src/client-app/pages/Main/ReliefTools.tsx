import React, { useEffect, useMemo, useRef, useState } from "react";
import { AnimatePresence, motion } from "motion/react";
import { Bell, Check, ChevronLeft, Cloud, Headphones, Moon, Pause, Play, RefreshCw, Smile, Volume2, VolumeX, Wind, X } from "lucide-react";
import { useAppStore } from "../../store";
import { EmotionExercise } from "../../components/EmotionExercise";

type ToolShellProps = { title: string; children: React.ReactNode };

function ToolShell({ title, children }: ToolShellProps) {
  const { popView } = useAppStore();
  return (
    <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} className="fixed inset-0 z-50 flex flex-col bg-[#F7F8F7]">
      <header className="flex h-[calc(56px+env(safe-area-inset-top))] shrink-0 items-end border-b border-black/5 bg-white px-3 pb-2">
        <button aria-label="返回" onClick={popView} className="grid h-10 w-10 place-items-center rounded-full text-gray-700 active:bg-gray-100"><ChevronLeft size={24} /></button>
        <h1 className="flex-1 pb-2 text-center text-[17px] font-bold text-gray-900">{title}</h1>
        <div className="w-10" />
      </header>
      <main className="min-h-0 flex-1 overflow-y-auto">{children}</main>
    </motion.div>
  );
}

export function BreathingTool() {
  const { popView } = useAppStore();
  return <EmotionExercise type="breathing" onClose={popView} onComplete={popView} />;
}

export function MuyuTool() {
  const { popView } = useAppStore();
  return <EmotionExercise type="rhythm" onClose={popView} onComplete={popView} />;
}

const noiseScenes = [
  { name: "细雨", icon: "🌧️", color: "from-indigo-100 to-slate-100" },
  { name: "海浪", icon: "🌊", color: "from-cyan-100 to-blue-100" },
  { name: "篝火", icon: "🔥", color: "from-orange-100 to-amber-50" },
];

export function WhiteNoiseTool() {
  const [scene, setScene] = useState(0);
  const [playing, setPlaying] = useState(false);
  const [volume, setVolume] = useState(45);
  const [seconds, setSeconds] = useState(0);
  const audioRef = useRef<{ context: AudioContext; source: AudioBufferSourceNode; gain: GainNode } | null>(null);

  useEffect(() => {
    if (!playing) return;
    const timer = window.setInterval(() => setSeconds((s) => s + 1), 1000);
    return () => window.clearInterval(timer);
  }, [playing]);

  const stop = () => {
    audioRef.current?.source.stop();
    audioRef.current?.context.close();
    audioRef.current = null;
    setPlaying(false);
  };

  const start = (sceneIndex = scene) => {
    const context = new AudioContext();
    const buffer = context.createBuffer(1, context.sampleRate * 2, context.sampleRate);
    const data = buffer.getChannelData(0);
    for (let i = 0; i < data.length; i++) data[i] = Math.random() * 2 - 1;
    const source = context.createBufferSource();
    const gain = context.createGain();
    const filter = context.createBiquadFilter();
    filter.type = sceneIndex === 2 ? "lowpass" : "bandpass";
    filter.frequency.value = sceneIndex === 0 ? 1200 : sceneIndex === 1 ? 600 : 240;
    gain.gain.value = volume / 250;
    source.buffer = buffer;
    source.loop = true;
    source.connect(filter).connect(gain).connect(context.destination);
    source.start();
    audioRef.current = { context, source, gain };
    setPlaying(true);
  };

  useEffect(() => { if (audioRef.current) audioRef.current.gain.gain.value = volume / 250; }, [volume]);
  useEffect(() => () => { audioRef.current?.source.stop(); audioRef.current?.context.close(); }, []);

  const changeScene = (index: number) => { const wasPlaying = playing; stop(); setScene(index); if (wasPlaying) window.setTimeout(() => start(index), 0); };
  return (
    <ToolShell title="白噪音">
      <div className={`flex min-h-full flex-col items-center bg-gradient-to-b ${noiseScenes[scene].color} px-6 py-10`}>
        <p className="text-[13px] font-semibold text-gray-500">专注于稳定、连续的环境声音</p>
        <motion.div animate={playing ? { scale: [1, 1.06, 1] } : {}} transition={{ repeat: Infinity, duration: 3 }} className="mt-10 grid h-48 w-48 place-items-center rounded-full bg-white/70 text-7xl shadow-[0_18px_60px_rgba(50,70,100,.12)]">{noiseScenes[scene].icon}</motion.div>
        <h2 className="mt-7 text-2xl font-black text-gray-900">{noiseScenes[scene].name}</h2>
        <p className="mt-2 tabular-nums text-sm text-gray-500">{String(Math.floor(seconds / 60)).padStart(2, "0")}:{String(seconds % 60).padStart(2, "0")}</p>
        <div className="mt-7 flex gap-3">{noiseScenes.map((item, i) => <button key={item.name} onClick={() => changeScene(i)} className={`rounded-full px-4 py-2 text-sm font-bold ${scene === i ? "bg-gray-900 text-white" : "bg-white/70 text-gray-600"}`}>{item.name}</button>)}</div>
        <div className="mt-8 flex w-full max-w-sm items-center gap-3 rounded-2xl bg-white/70 p-4"><Volume2 size={18} /><input aria-label="音量" className="w-full accent-gray-900" type="range" value={volume} onChange={(e) => setVolume(Number(e.target.value))} /></div>
        <button onClick={playing ? stop : () => start()} className="mt-7 flex h-14 w-full max-w-sm items-center justify-center gap-2 rounded-2xl bg-gray-900 font-bold text-white shadow-lg active:scale-[.98]">{playing ? <Pause size={20} /> : <Play size={20} fill="currentColor" />}{playing ? "暂停声音" : "开始播放"}</button>
      </div>
    </ToolShell>
  );
}

function GuidedTool({ type }: { type: "meditation" | "sleep" }) {
  const sleep = type === "sleep";
  const steps = sleep
    ? ["放松额头与眼周", "松开下颌和肩膀", "感受背部被床面托住", "放松双腿直到脚趾", "让呼吸自然流动"]
    : ["找到舒适坐姿，轻轻闭眼", "留意鼻尖呼吸的触感", "从头顶缓慢扫描到肩膀", "允许念头经过，不必追随", "把注意力带回身体此刻"];
  const [running, setRunning] = useState(false);
  const [step, setStep] = useState(0);
  const [remaining, setRemaining] = useState(30);
  const [done, setDone] = useState(false);
  const [voiceOn, setVoiceOn] = useState(true);
  const speak = (text: string) => {
    if (!voiceOn || !("speechSynthesis" in window)) return;
    window.speechSynthesis.cancel();
    const utterance = new SpeechSynthesisUtterance(text);
    utterance.lang = "zh-CN"; utterance.rate = sleep ? .78 : .86; utterance.pitch = .92;
    window.speechSynthesis.speak(utterance);
  };
  useEffect(() => () => window.speechSynthesis?.cancel(), []);
  useEffect(() => {
    if (!running || done) return;
    speak(steps[step]);
  // Announce only when a new guided segment starts or resumes.
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [step, running, done]);
  useEffect(() => {
    if (!running || done) return;
    const timer = window.setInterval(() => setRemaining((r) => {
      if (r > 1) return r - 1;
      if (step === steps.length - 1) { speak(sleep ? "引导结束了，不需要睁眼，让呼吸自然流动，慢慢进入睡眠" : "练习完成，准备好以后，再慢慢睁开眼睛"); setRunning(false); setDone(true); return 0; }
      setStep((s) => s + 1); return 30;
    }), 1000);
    return () => window.clearInterval(timer);
  }, [running, done, step, steps.length]);
  const reset = () => { window.speechSynthesis?.cancel(); setRunning(false); setStep(0); setRemaining(30); setDone(false); };
  return (
    <ToolShell title={sleep ? "睡眠引导" : "冥想放松"}>
      <div className={`flex min-h-full flex-col px-6 py-8 ${sleep ? "bg-gradient-to-b from-[#17233f] to-[#0c1326] text-white" : "bg-gradient-to-b from-sky-50 to-white text-gray-900"}`}>
        <div className="text-center"><button onClick={() => { setVoiceOn((v) => !v); window.speechSynthesis?.cancel(); }} className={`absolute right-5 top-[calc(76px+env(safe-area-inset-top))] grid h-10 w-10 place-items-center rounded-full ${sleep ? "bg-white/10 text-white" : "bg-white text-gray-600 shadow-sm"}`} aria-label={voiceOn ? "关闭语音引导" : "开启语音引导"}>{voiceOn ? <Volume2 size={18} /> : <VolumeX size={18} />}</button><div className={`mx-auto grid h-20 w-20 place-items-center rounded-3xl ${sleep ? "bg-white/10" : "bg-sky-100 text-sky-600"}`}>{sleep ? <Moon size={38} /> : <Cloud size={38} />}</div><p className={`mt-5 text-sm ${sleep ? "text-blue-200" : "text-gray-500"}`}>{done ? "练习完成" : `第 ${step + 1} / ${steps.length} 段`}</p><h2 className="mx-auto mt-3 max-w-xs text-2xl font-black leading-9">{done ? (sleep ? "现在，让自己慢慢入睡" : "带着这份平静回到当下") : steps[step]}</h2>{!running && !done && !step && <p className={`mt-3 text-xs ${sleep ? "text-blue-200/70" : "text-gray-400"}`}><Volume2 className="mr-1 inline" size={14} />开始后可闭眼，阶段切换会自动播报</p>}</div>
        <div className="mt-10 flex gap-2">{steps.map((_, i) => <div key={i} className={`h-1.5 flex-1 rounded-full ${i < step || done ? (sleep ? "bg-blue-300" : "bg-sky-500") : i === step ? (sleep ? "bg-white" : "bg-gray-900") : (sleep ? "bg-white/15" : "bg-gray-200")}`} />)}</div>
        {!done && <motion.div animate={running ? { scale: [0.86, 1.1, 0.86], opacity: [.55, 1, .55] } : {}} transition={{ repeat: Infinity, duration: 8 }} className={`mx-auto mt-14 grid h-36 w-36 place-items-center rounded-full border ${sleep ? "border-blue-300/30 bg-blue-300/10" : "border-sky-200 bg-sky-100/60"}`}><span className="text-3xl font-light tabular-nums">{remaining}</span></motion.div>}
        <div className="mt-auto pt-10"><button onClick={done ? reset : () => { if (running) { window.speechSynthesis?.cancel(); speak("引导已暂停"); } setRunning((v) => !v); }} className={`flex h-14 w-full items-center justify-center gap-2 rounded-2xl font-bold ${sleep ? "bg-white text-[#17233f]" : "bg-gray-900 text-white"}`}>{done ? <RefreshCw size={19} /> : running ? <Pause size={19} /> : <Play size={19} fill="currentColor" />}{done ? "再做一次" : running ? "暂停引导" : step ? "继续语音引导" : "开始语音引导"}</button></div>
      </div>
    </ToolShell>
  );
}

export function MeditationTool() { return <GuidedTool type="meditation" />; }
export function SleepGuideTool() { return <GuidedTool type="sleep" />; }

export function BubbleWrapTool() {
  const initial = useMemo(() => Array.from({ length: 30 }, (_, i) => i), []);
  const [popped, setPopped] = useState<Set<number>>(new Set());
  const [celebrate, setCelebrate] = useState(false);
  const pop = (id: number) => {
    if (popped.has(id)) return;
    navigator.vibrate?.(10);
    const next = new Set(popped).add(id); setPopped(next);
    if (next.size === initial.length) setCelebrate(true);
  };
  const reset = () => { setPopped(new Set()); setCelebrate(false); };
  return (
    <ToolShell title="捏泡泡">
      <div className="flex min-h-full flex-col bg-gradient-to-b from-fuchsia-50 to-white px-5 py-7">
        <div className="flex items-end justify-between"><div><h2 className="text-2xl font-black text-gray-900">把压力一个个捏掉</h2><p className="mt-2 text-sm text-gray-500">不追求速度，跟着每一次触感回到当下</p></div><span className="rounded-full bg-white px-3 py-1.5 text-xs font-bold text-fuchsia-600 shadow-sm">{popped.size}/{initial.length}</span></div>
        <div className="mt-7 grid grid-cols-5 gap-3 rounded-[28px] bg-white/80 p-4 shadow-sm">{initial.map((id) => { const isPopped = popped.has(id); return <motion.button aria-label={`泡泡 ${id + 1}${isPopped ? " 已捏破" : ""}`} whileTap={{ scale: .75 }} key={id} onClick={() => pop(id)} className={`aspect-square rounded-full border transition-all ${isPopped ? "border-fuchsia-100 bg-fuchsia-50 shadow-inner" : "border-white bg-gradient-to-br from-fuchsia-200 to-pink-300 shadow-[inset_4px_4px_7px_rgba(255,255,255,.75),0_4px_8px_rgba(180,80,160,.18)]"}`}>{isPopped && <Check className="mx-auto text-fuchsia-300" size={18} />}</motion.button>; })}</div>
        <button onClick={reset} className="mt-6 flex h-12 items-center justify-center gap-2 rounded-2xl border border-fuchsia-100 bg-white font-bold text-fuchsia-700"><RefreshCw size={17} />重新铺满</button>
      </div>
      <AnimatePresence>{celebrate && <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="absolute inset-0 z-10 grid place-items-center bg-black/25 p-6"><motion.div initial={{ scale: .85, y: 20 }} animate={{ scale: 1, y: 0 }} className="w-full max-w-sm rounded-[28px] bg-white p-7 text-center shadow-xl"><div className="mx-auto grid h-16 w-16 place-items-center rounded-full bg-fuchsia-100 text-fuchsia-600"><Smile size={30} /></div><h3 className="mt-5 text-xl font-black">这一轮完成了</h3><p className="mt-2 text-sm leading-6 text-gray-500">停一下，感受手指和呼吸。哪怕只松了一点，也值得被注意。</p><button onClick={reset} className="mt-6 h-12 w-full rounded-2xl bg-gray-900 font-bold text-white">再捏一轮</button><button aria-label="关闭完成提示" onClick={() => setCelebrate(false)} className="absolute right-8 top-8 hidden"><X /></button></motion.div></motion.div>}</AnimatePresence>
    </ToolShell>
  );
}
