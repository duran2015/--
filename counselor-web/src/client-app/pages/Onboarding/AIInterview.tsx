import { useState, useEffect, useRef } from "react";
import { motion, AnimatePresence } from "motion/react";
import { useAppStore } from "../../store";
import { Send, Mic, Sparkles } from "lucide-react";

const interviewFlow = [
  "我理解了...听起来最近的压力确实给你带来了不少情绪上的波动。能具体说说，是什么事情让你特别烦心吗？",
  "这确实很不容易，面临这样的情况大部分人都会觉得有压力。在这个过程中，你觉得自己最担心发生什么？",
  "谢谢你这么坦诚地和我分享。你真的很棒，尽管觉得难受，但也一直在努力寻找开口的方式。",
  "如果可以的话，我们一起来梳理一下。我已经根据你的量表和刚才的倾诉整理了一份初步的心灵画像，准备好看看真实的自己了吗？",
];

export function AIInterview() {
  const { pushView } = useAppStore();
  const [messages, setMessages] = useState<
    { role: "ai" | "user"; text: string }[]
  >([
    {
      role: "ai",
      text: "你好，感谢你完成量表。我是小鹿。\n\n我注意到你刚才填写量表时，提到了情绪有些低落。现在的你，感觉还好吗？",
    },
  ]);
  const [input, setInput] = useState("");
  const [isTyping, setIsTyping] = useState(false);
  const [step, setStep] = useState(0);
  const endRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    endRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages, isTyping]);

  const handleSend = () => {
    if (!input.trim() || isTyping) return;

    const newMsg = input;
    setInput("");
    setMessages((prev) => [...prev, { role: "user", text: newMsg }]);
    setIsTyping(true);

    setTimeout(
      () => {
        setIsTyping(false);
        setMessages((prev) => [
          ...prev,
          { role: "ai", text: interviewFlow[step] },
        ]);

        if (step === interviewFlow.length - 1) {
          setTimeout(() => {
            pushView("generation");
          }, 2500);
        } else {
          setStep((s) => s + 1);
        }
      },
      1500 + Math.random() * 1000,
    ); // 随机由于模拟真人打字时间
  };

  return (
    <motion.div
      initial={{ y: "100%" }}
      animate={{ y: 0 }}
      exit={{ opacity: 0 }}
      transition={{ type: "spring", damping: 25, stiffness: 200 }}
      className="flex flex-col h-full bg-surface absolute inset-0 z-50"
    >
      <div className="pt-14 pb-4 px-6 bg-white/90 backdrop-blur-md sticky top-0 z-10 border-b border-gray-100 flex items-center justify-between shadow-sm">
        <div className="flex items-center space-x-3">
          <div className="w-10 h-10 bg-gradient-to-br from-primary-light to-primary/20 rounded-[1rem] flex items-center justify-center text-primary font-bold shadow-inner">
            <Sparkles size={20} className="text-primary" />
          </div>
          <div>
            <h2 className="font-semibold text-gray-900 border-none">
              小鹿
            </h2>
            <div className="flex items-center space-x-1.5 mt-0.5">
              <span className="flex h-1.5 w-1.5 rounded-full bg-green-500"></span>
              <p className="text-[11px] font-medium text-gray-500 leading-none">
                正在进行初始评估 (预计3-5分钟)
              </p>
            </div>
          </div>
        </div>
        <button
          onClick={() => pushView("generation")}
          className="text-[13px] font-medium text-gray-400 bg-gray-50 px-3 py-1.5 rounded-full active:bg-gray-100 transition-colors"
        >
          暂不倾诉
        </button>
      </div>

      <div className="flex-1 overflow-y-auto p-4 space-y-6 pb-20">
        <AnimatePresence initial={false}>
          {messages.map((msg, idx) => (
            <motion.div
              key={idx}
              initial={{ opacity: 0, y: 10, scale: 0.95 }}
              animate={{ opacity: 1, y: 0, scale: 1 }}
              transition={{ duration: 0.3 }}
              className={`flex ${msg.role === "user" ? "justify-end" : "justify-start"}`}
            >
              <div
                className={`max-w-[85%] rounded-[1.5rem] p-4 ${
                  msg.role === "user"
                    ? "bg-primary text-white rounded-tr-sm shadow-md shadow-primary/10"
                    : "bg-white border border-gray-100 text-gray-800 rounded-tl-sm shadow-sm"
                }`}
              >
                <p className="text-[15px] leading-relaxed whitespace-pre-wrap">
                  {msg.text}
                </p>
              </div>
            </motion.div>
          ))}
          {isTyping && (
            <motion.div
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.9 }}
              className="flex justify-start"
            >
              <div className="bg-white border border-gray-100 text-gray-800 rounded-[1.5rem] rounded-tl-sm p-4 shadow-sm flex items-center space-x-1.5 w-16 h-12">
                <motion.div
                  animate={{ y: [0, -5, 0] }}
                  transition={{ repeat: Infinity, duration: 0.6, delay: 0 }}
                  className="w-1.5 h-1.5 bg-gray-400 rounded-full"
                />
                <motion.div
                  animate={{ y: [0, -5, 0] }}
                  transition={{ repeat: Infinity, duration: 0.6, delay: 0.2 }}
                  className="w-1.5 h-1.5 bg-gray-400 rounded-full"
                />
                <motion.div
                  animate={{ y: [0, -5, 0] }}
                  transition={{ repeat: Infinity, duration: 0.6, delay: 0.4 }}
                  className="w-1.5 h-1.5 bg-gray-400 rounded-full"
                />
              </div>
            </motion.div>
          )}
        </AnimatePresence>
        <div ref={endRef} className="h-2" />
      </div>

      <div className="bg-white border-t border-gray-100 p-4 pb-8 shadow-[0_-10px_30px_rgba(0,0,0,0.02)]">
        <div className="flex items-end space-x-2 bg-surface p-1.5 rounded-3xl border border-gray-200 focus-within:border-primary/50 focus-within:bg-white transition-colors">
          <div className="flex-1 max-h-32 overflow-y-auto p-2 min-h-[44px]">
            <textarea
              value={input}
              onChange={(e) => setInput(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === "Enter" && !e.shiftKey) {
                  e.preventDefault();
                  handleSend();
                }
              }}
              placeholder={isTyping ? "小鹿正在回复..." : "和我聊聊..."}
              disabled={isTyping}
              className="w-full bg-transparent outline-none text-[15px] text-gray-700 resize-none placeholder-gray-400 leading-relaxed block"
              rows={
                input.split("\n").length > 1
                  ? Math.min(input.split("\n").length, 4)
                  : 1
              }
            />
          </div>
          <button className="w-10 h-10 shrink-0 rounded-full bg-gray-50 flex items-center justify-center text-gray-500 active:bg-gray-200 transition-colors mb-0.5">
            <Mic size={20} />
          </button>
          <button
            onClick={handleSend}
            disabled={!input.trim() || isTyping}
            className={`w-10 h-10 shrink-0 rounded-full flex items-center justify-center text-white transition-all shadow-sm mb-0.5 ${
              input.trim() && !isTyping
                ? "bg-primary active:scale-95"
                : "bg-gray-300"
            }`}
          >
            <Send size={18} className="translate-x-[1px] translate-y-[-1px]" />
          </button>
        </div>
      </div>
    </motion.div>
  );
}
