import { useState, useRef, useEffect } from "react";
import { motion, AnimatePresence } from "motion/react";
import {
  Activity,
  AlertTriangle,
  ArrowRight,
  ArrowUp,
  Camera,
  Check,
  ChevronLeft,
  ChevronRight,
  FileText,
  Image as ImageIcon,
  Keyboard,
  Lightbulb,
  Mic,
  Smile,
  MoreHorizontal,
  Phone,
  PlusCircle,
  ShieldAlert,
  Star,
  Wind,
  Volume2,
  VolumeX,
  ThumbsUp,
  ThumbsDown,
  Filter
} from "lucide-react";
import { useAppStore } from "../../store";
import { EmotionExercise } from "../../components/EmotionExercise";

export function AITab() {
  const { currentTab, pushView, popView, setSelectedCounselorId, user, blackboard, aiSettings, updateAISettings, counselorStatus } = useAppStore();
  const [showSortMenu, setShowSortMenu] = useState(false);
  const [sortBy, setSortBy] = useState("recommended");
  const [feedbackState, setFeedbackState] = useState<Record<number, 'up' | 'down'>>({});
  const [playingMsgIdx, setPlayingMsgIdx] = useState<number | null>(null);
  const [activeExercise, setActiveExercise] = useState<"breathing" | "rhythm" | null>(null);

  const toggleFeedback = (idx: number, type: 'up' | 'down') => {
    setFeedbackState(prev => ({
      ...prev,
      [idx]: prev[idx] === type ? undefined : type
    }));
  };

  const isDark = aiSettings.theme === 'dark';
  // Increase the distinction between font sizes to make it obvious
  const textSize = aiSettings.fontSize === 'small' ? 'text-[13px]' : aiSettings.fontSize === 'large' ? 'text-[18px]' : 'text-[15px]';
  const avatarEmoji = '🦌';
  const avatarName = '小鹿';

  // AI Chat State
  const [messages, setMessages] = useState<{
    id: string;
    role: "ai" | "user";
    type?: "text" | "referral" | "task" | "summary";
    text: string;
    time?: string;
    suggestedTopics?: string[];
    task?: {
      title: string;
      desc: string;
      actionText: string;
      duration?: string;
      actionView?: "muyu" | "breathing";
    };
    summary?: {
      problem: string;
      feeling: string;
      reason: string;
    };
    recommendations?: {
      level: string;
      title: string;
      desc: string;
      type: "ai" | "info" | "human";
    }[];
  }[]>([]);

  // Initialize messages based on blackboard
  useEffect(() => {
    if (messages.length === 0) {
      let initialGreeting = `晚上好，${user.name || "新朋友"}\n今天过得怎么样？想和我聊聊吗？`;
      let suggestedTopics = [
        "今天有件开心事",
        "感觉有点无聊",
        "其实有点焦虑"
      ];
      
      if (blackboard.clinical) {
        if (blackboard.clinical.phq2Score <= 1) {
          initialGreeting = `晚上好，${user.name || "新朋友"}\n看起来你最近状态不错！有什么开心的事想分享吗？`;
          suggestedTopics = [
            "分享开心事 🎉",
            "发现新爱好",
            "记录好心情"
          ];
        } else if (blackboard.clinical.phq2Score <= 3) {
          initialGreeting = `晚上好，${user.name || "新朋友"}\n最近有点辛苦吧？没关系，我在这里陪你。`;
          suggestedTopics = [
            "确实有点累 😮‍💨",
            "最近睡不好",
            "带我深呼吸"
          ];
        } else {
          initialGreeting = `晚上好，${user.name || "新朋友"}\n谢谢你愿意告诉我这些。你想从哪里开始聊起呢？`;
          suggestedTopics = [
            "压力好大 🥺",
            "控制不住情绪",
            "不知怎么缓解"
          ];
        }
      }

      setMessages([
        {
          id: "1",
          role: "ai",
          type: "text",
          text: initialGreeting,
          suggestedTopics,
          time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
        }
      ]);
    }
  }, [user.name, blackboard, messages.length]);

  const [input, setInput] = useState("");
  const [inputMode, setInputMode] = useState<"text" | "voice">("text");
  const [isRecording, setIsRecording] = useState(false);
  const [isTranscribing, setIsTranscribing] = useState(false);
  const [showCrisisAlert, setShowCrisisAlert] = useState(false);
  const [showPlusMenu, setShowPlusMenu] = useState(false);
  const [showEmojiMenu, setShowEmojiMenu] = useState(false);
  const [isFocused, setIsFocused] = useState(false);
  const endRef = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLTextAreaElement>(null);

  const commonEmojis = ["😀","😂","😊","😍","🥰","😘","😎","🤔","🙄","😣","😪","😫","😌","😛","😜","🤤","😓","😔","🙃","😭","😱","😡","🤯","🤡","👻","💩","👍","👎","❤️","💔","✨","🎉","🔥","🌟","💯"];

  useEffect(() => {
    endRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages]);

  const handleSend = (text?: string, source: "input" | "quick-topic" | "quick-action" = "input") => {
    const newMsg = text || input;
    if (!newMsg.trim()) return;
    setInput("");
    setShowPlusMenu(false);
    setShowEmojiMenu(false);
    
    // reset textarea height
    if (inputRef.current) inputRef.current.style.height = 'auto';
    
    const newMsgId = Date.now().toString();
    const time = new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
    
    setMessages((prev) => [
      ...prev,
      { id: newMsgId, role: "user", type: "text", text: newMsg, time },
    ]);

    console.log("[Event Analytics] AI Chat user message sent");

    // 危机词库识别 (模拟 L4 危机识别与转介 - 功能 8)
    const crisisKeywords = ["死", "不想活", "没意思", "绝望", "结束"];
    const isCrisis = crisisKeywords.some((keyword) => newMsg.includes(keyword));

    if (isCrisis) {
      console.log("[Event Analytics] L4 Crisis risk detected & intercepted");
      setTimeout(() => setShowCrisisAlert(true), 500);
      return;
    }

    // 意图识别与 Skill 调用引擎
    const intents = {
      cbt: ["失败", "没用", "糟糕", "差劲", "做不好", "肯定"],
      dbt: ["生气", "发火", "忍不住", "崩溃", "气死", "受不了"],
      mindfulness: ["想太多", "走神", "脑子乱", "发呆", "烦"],
      ba: ["不想动", "没力气", "无聊", "躺平", "没劲"],
      game: ["木鱼", "静心", "敲", "积德"],
      stress: ["焦虑", "压力", "累", "失眠", "考试", "睡", "抑郁"],
      referral: ["找人", "真人", "倾听师", "咨询", "还是很难受", "没效果"],
      summary: ["总结", "梳理", "聊得差不多", "怎么办"]
    };

    const detectIntent = (text: string) => {
      for (const [intent, keywords] of Object.entries(intents)) {
        if (keywords.some(k => text.includes(k))) return intent;
      }
      return "default";
    };

    const userIntent = detectIntent(newMsg);

    setTimeout(() => {
      const responseTime = new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
      
      let aiResponses: any[] = [];

      if (source === "quick-action") {
        if (newMsg.includes("木鱼")) {
          aiResponses = [{
            id: `${Date.now()}_muyu`,
            role: "ai",
            type: "task",
            text: "",
            time: responseTime,
            task: { title: "60 秒节奏锚定", desc: "通过规律触碰和计数，把注意力从反复思考带回当下。完成后记录情绪变化。", actionText: "开始练习", duration: "注意力锚定 · 60秒", actionView: "muyu" },
          }];
        } else if (newMsg.includes("深呼吸")) {
          aiResponses = [{
            id: `${Date.now()}_breathing`,
            role: "ai",
            type: "task",
            text: "",
            time: responseTime,
            task: { title: "三轮延长呼气", desc: "跟随节奏完成吸气 4 秒、呼气 6 秒，帮助身体从紧绷状态慢下来。", actionText: "开始练习", duration: "呼吸调节 · 约1分钟", actionView: "breathing" },
          }];
        } else {
          aiResponses = [{
            id: `${Date.now()}_vent`,
            role: "ai",
            type: "text",
            text: "当然可以，你不用急着把事情讲得很有条理。就从最想吐槽的那一件开始吧——最近是谁或什么事让你最憋屈？",
            time: responseTime,
          }];
        }
        setMessages(prev => [...prev, ...aiResponses]);
        return;
      }

      if (source === "quick-topic") {
        const quickTopicReplies: Record<string, string> = {
          "今天有件开心事": "听起来今天发生了值得开心的事呀 😊 我很想听听——是什么事情让你有了这份好心情？",
          "分享开心事 🎉": "太好啦，我也想和你一起记住这份开心 🎉 是什么事情让你觉得特别值得分享？",
          "发现新爱好": "发现新爱好是一件很有生命力的事。你最近开始喜欢上什么了？最吸引你的地方是什么？",
          "记录好心情": "好心情值得被认真收藏。此刻如果用三个词记录，你会怎么形容今天的自己？",
          "感觉有点无聊": "有点无聊的时候，时间好像会走得特别慢。你现在更想找点事情做，还是只是想有人陪你说说话？",
          "其实有点焦虑": "谢谢你愿意说出来。焦虑时脑子里常会同时挤着很多担心——此刻最让你放不下的，是一件具体的事，还是一种说不清的紧绷感？",
          "确实有点累 😮‍💨": "听起来你已经撑了一阵子了 😮‍💨 这种累更像是身体没力气，还是心里一直绷着、很难真正放松？",
          "最近睡不好": "睡不好真的会把白天也变得很辛苦。最近主要是难入睡、容易醒，还是醒得太早呢？",
          "带我深呼吸": "好，我们先不急着解决所有事情。把肩膀放松一点，慢慢吸气 4 秒，再缓缓呼气 6 秒；我会陪你做三轮。",
          "压力好大 🥺": "我听见了，你现在承受的压力已经很满了 🥺 如果只挑最压着你的那一件事，会是什么？",
          "控制不住情绪": "情绪一下子冲上来时，确实会让人很无助。刚才发生了什么？你最先注意到的是身体反应，还是脑子里的某个念头？",
          "不知怎么缓解": "不知道该怎么缓解，并不代表你做得不够好。我们可以先把难受拆小一点：现在最明显的是焦虑、委屈、愤怒，还是疲惫？",
        };
        aiResponses = [{
          id: `${Date.now()}_quick`,
          role: "ai",
          type: "text",
          text: quickTopicReplies[newMsg] || "我在听。你愿意多告诉我一点，刚才是什么让你想到这个吗？",
          time: responseTime,
        }];
        setMessages(prev => [...prev, ...aiResponses]);
        return;
      }

      switch (userIntent) {
        case "cbt":
          aiResponses = [
            {
              id: Date.now().toString() + "_cbt1",
              role: "ai",
              type: "text",
              text: "听到你这么评价自己，我有点心疼。有时候，我们的情绪会给我们戴上“有色眼镜”，让我们只看到不好的那一面。要不要和我一起，做个简单的认知重构练习，把这副眼镜摘下来看看？",
              time: responseTime,
            },
            {
              id: Date.now().toString() + "_cbt2",
              role: "ai",
              type: "task",
              text: "",
              time: responseTime,
              task: {
                title: "思维记录卡 · 认知重构",
                desc: "识别那些让你难受的“自动思维”，并尝试寻找客观的证据来反驳它。这能帮你跳出思维陷阱。",
                actionText: "开始思维记录",
                duration: "CBT 技能 · 5分钟"
              }
            }
          ];
          break;
        case "dbt":
          aiResponses = [
            {
              id: Date.now().toString() + "_dbt1",
              role: "ai",
              type: "text",
              text: "我完全能感觉到你现在情绪的强烈波动，就像是一座快要喷发的火山。在这个时候，讲道理可能没用。我们可以先试着用一种物理的方法（TIPP技巧），给身体降降温，把这股强烈的冲动扛过去。",
              time: responseTime,
            },
            {
              id: Date.now().toString() + "_dbt2",
              role: "ai",
              type: "task",
              text: "",
              time: responseTime,
              task: {
                title: "冰水驻颜术 (TIPP 技能)",
                desc: "利用温度的剧烈变化来强制启动潜水反射，迅速降低心率，平息难以忍受的极端情绪。",
                actionText: "查看具体步骤",
                duration: "DBT 技能 · 1分钟"
              }
            }
          ];
          break;
        case "ba":
          aiResponses = [
            {
              id: Date.now().toString() + "_ba1",
              role: "ai",
              type: "text",
              text: "确实，当我们情绪低落的时候，身体就像没电了一样，什么都不想做。这是很正常的保护机制。但一直躺着可能会让我们感觉更糟，要不要试试完成一个微小的、几乎不需要力气的小任务？",
              time: responseTime,
            },
            {
              id: Date.now().toString() + "_ba2",
              role: "ai",
              type: "task",
              text: "",
              time: responseTime,
              task: {
                title: "微小行为激活",
                desc: "不需要做多大的事，比如喝一杯水、走到窗边看看天，或者整理一下桌面。用小动作打破情绪的死循环。",
                actionText: "获取我的小任务",
                duration: "BA 技能 · 2分钟"
              }
            }
          ];
          break;
        case "game":
        case "mindfulness":
          aiResponses = [
            {
              id: Date.now().toString() + "_game1",
              role: "ai",
              type: "text",
              text: "感觉脑子里一团乱麻，很难静下来对吗？我为你准备了一个「电子木鱼」小练习，通过简单的动作节奏，把注意力锚定在当下，慢慢把心收回来。",
              time: responseTime,
            },
            {
              id: Date.now().toString() + "_game2",
              role: "ai",
              type: "task",
              text: "",
              time: responseTime,
              task: {
                title: "电子木鱼 · 赛博积德",
                desc: "轻触屏幕敲击，配合呼吸节奏，每次敲击都是一次压力的释放。适合焦虑、烦躁时随时使用。",
                actionText: "开始敲击",
                duration: "游戏化干预 · 随时"
              }
            }
          ];
          break;
        case "stress":
          aiResponses = [
            {
              id: Date.now().toString() + "_1",
              role: "ai",
              type: "text",
              text: "听起来压力确实让你很难受，导致状态也受到了很大影响 🥺\n\n除了跟我倾诉，我们也可以先做个简单的呼吸放松，让紧绷的神经缓一缓。",
              time: responseTime,
            },
            {
              id: Date.now().toString() + "_2",
              role: "ai",
              type: "task",
              text: "",
              time: responseTime,
              task: {
                title: "4-7-8 呼吸放松练习",
                desc: "通过控制呼吸频率来激活副交感神经，帮助身体快速进入放松状态。适合考前、睡前或感到紧绷时使用。",
                actionText: "开始练习",
                duration: "调节类工具 · 3分钟"
              }
            }
          ];
          break;
        case "referral":
          aiResponses = [
            {
              id: Date.now().toString() + "_ref1",
              role: "ai",
              type: "text",
              text: "我听到了，当前的状况确实让人感到有些无助。小鹿的陪伴有时候可能不够，如果你愿意的话，我可以帮你对接一位专业的真人倾听师。他们经验丰富，能给你更温暖、更深度的支持。",
              time: responseTime,
            },
            {
              id: Date.now().toString() + "_ref2",
              role: "ai",
              type: "referral",
              text: "",
              time: responseTime,
            }
          ];
          break;
        case "summary":
          aiResponses = [
            {
              id: Date.now().toString() + "_sum1",
              role: "ai",
              type: "text",
              text: "我陪你聊了一会儿，为了让你能看清现在的状态，我简单帮你梳理了一下刚才聊到的内容。看看我说得对不对：",
              time: responseTime,
            },
            {
              id: Date.now().toString() + "_sum2",
              role: "ai",
              type: "summary",
              text: "",
              time: responseTime,
              summary: {
                problem: "最近压力很大，经常内耗",
                feeling: "焦虑、无助、疲惫",
                reason: "职场上遇到了难以处理的人际关系"
              }
            }
          ];
          // We can also save this to blackboard or global store so next pages can use it
          useAppStore.getState().setBookingSummary({
            problem: "最近压力很大，经常内耗",
            feeling: "焦虑、无助、疲惫",
            reason: "职场上遇到了难以处理的人际关系",
            expectation: "希望能有人听我说，帮我梳理情绪",
            source: "可鹿 AI 情绪助手"
          });
          break;
        default:
          aiResponses = [
            {
              id: Date.now().toString() + "_3",
              role: "ai",
              text: "我很理解你的感受。为了更好地帮助你，根据我们目前的交流，我为你整理了分层的心理支持方案，你可以选择最舒服的方式：",
              time: responseTime,
              recommendations: [
                {
                  level: "L1",
                  title: "小鹿陪伴",
                  desc: "适合较轻的情绪压力，随时陪伴，无等待。",
                  type: "ai",
                },
                {
                  level: "L2",
                  title: "真人倾听辅导",
                  desc: "需要真实人类的情感共鸣与倾听，缓解孤独。",
                  type: "human",
                },
              ],
            },
          ];
          break;
      }

      setMessages(prev => [...prev, ...aiResponses]);
    }, 1500);
  };

  // Determine if we should show the SOS option in input based on recent crisis attempts,
  // For demo, we can just show it if messages length > 0
  const hasRiskContext = messages.some(m => m.role === 'user' && ["死", "不想活"].some(k => m.text.includes(k)));

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      className={`flex flex-col h-full relative ${isDark ? 'bg-[#121212]' : 'bg-[#f8f9fa]'}`}
    >
      <div className={`pt-12 pb-2 px-6 sticky top-0 z-20 flex flex-col shadow-[0_1px_10px_rgba(0,0,0,0.02)] relative transition-colors ${isDark ? 'bg-[#1A1A1A] border-b border-gray-800' : 'bg-white'}`}>
        <button 
          onClick={() => popView()} 
          aria-label="返回"
          className={`absolute left-4 top-11 p-2 transition-colors z-10 ${isDark ? 'text-gray-400 hover:text-white' : 'text-gray-500 hover:text-gray-900'}`}
        >
          <ChevronLeft size={24} />
        </button>
        <div className="flex justify-center space-x-8 mb-2 relative w-full px-2">
          <div className={`pb-2 text-[16px] font-bold transition-all relative ${isDark ? "text-white" : "text-gray-900"}`}>
            可鹿 AI 情绪助手
          </div>
        </div>
      </div>

      <>
        <div className={`backdrop-blur-md px-4 py-3 border-b flex items-center justify-between sticky top-[92px] z-20 transition-colors ${isDark ? 'bg-[#1A1A1A]/95 border-gray-800' : 'bg-white/95 border-gray-100'}`}>
         <div className="flex items-center space-x-3">
            <div className="relative">
              <div className={`w-10 h-10 rounded-full flex items-center justify-center text-xl border overflow-hidden ${isDark ? 'bg-orange-900/20 border-orange-900/50' : 'bg-orange-50 border-orange-100'}`}>
                {avatarEmoji}
              </div>
              <div className={`absolute bottom-0 right-0 w-3 h-3 bg-green-500 border-2 rounded-full ${isDark ? 'border-[#1A1A1A]' : 'border-white'}`}></div>
            </div>
            <div>
               <div className={`text-[15px] font-bold leading-tight ${isDark ? 'text-white' : 'text-gray-900'}`}>{avatarName}</div>
               <div className={`text-[11px] font-medium flex items-center mt-0.5 ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>
                 随时陪伴你
               </div>
            </div>
         </div>
         <div className="flex items-center space-x-2">
           <button 
             onClick={() => updateAISettings({ autoPlayVoice: !aiSettings.autoPlayVoice })}
             aria-label={aiSettings.autoPlayVoice ? "关闭自动朗读" : "开启自动朗读"}
             className={`p-2 rounded-full transition-colors flex items-center ${aiSettings.autoPlayVoice ? (isDark ? 'text-blue-400 bg-blue-900/30' : 'text-blue-500 bg-blue-50') : (isDark ? 'text-gray-400 hover:bg-gray-800' : 'text-gray-600 hover:bg-gray-50')}`}
           >
              {aiSettings.autoPlayVoice ? <Volume2 size={20} /> : <VolumeX size={20} />}
           </button>
           <button aria-label="AI 设置" onClick={() => pushView("ai-settings")} className={`p-2 rounded-full transition-colors flex items-center ${isDark ? 'text-gray-400 hover:bg-gray-800' : 'text-gray-600 hover:bg-gray-50'}`}>
              <MoreHorizontal size={20} />
           </button>
         </div>
      </div>

      {/* Active Consultation Banner Removed */}

      <div className={`flex-1 overflow-y-auto w-full relative pt-2 transition-colors ${isDark ? 'bg-[#121212]' : 'bg-gradient-to-b from-[#EBF0FA] via-[#F8F9FF] to-[#f8f9fa]'}`}>
            {/* Chat Flow */}
            <div className="px-4 pb-[140px] pt-4">
              {messages.map((msg, idx) => (
                <div
                  key={idx}
                  className={`flex ${msg.role === "user" ? "justify-end" : "justify-start"} px-1 mb-5`}
                >
                  {msg.role === "user" ? (
                      <div className="flex flex-col items-end">
                        <div className="max-w-[280px] rounded-[1.2rem] p-3 text-white rounded-tr-sm shadow-[0_2px_10px_rgba(0,0,0,0.03)] bg-blue-500 border border-blue-400">
                          <p className={`leading-relaxed whitespace-pre-wrap transition-all duration-200 ${textSize}`}>{msg.text}</p>
                        </div>
                        {msg.time && <div className="text-[11px] text-gray-400 mt-1.5 mr-1 flex items-center">{msg.time} <Check size={14} className="ml-1 text-[#C4BCE8]" /></div>}
                      </div>
                    ) : (
                      <div className="w-full">
                        {msg.type === "text" && (
                            <div className="flex items-start w-full">
                              <div className="w-2 mr-0 shrink-0"></div>
                            <div className="flex flex-col items-start w-full">
                              <div className={`${isDark ? 'bg-[#2A2A2A] border-gray-800' : 'bg-white border-gray-100'} border rounded-[1.2rem] p-3 shadow-sm inline-block max-w-[280px] ${(idx === 0 || messages[idx - 1].role === "user") ? "rounded-tl-sm" : ""}`}>
                                <p className={`leading-relaxed whitespace-pre-wrap transition-all duration-200 ${textSize} ${isDark ? 'text-gray-200' : 'text-gray-800'}`}>
                                  {msg.text}
                                </p>
                              </div>
                              
                              {/* Message Action Bar */}
                              <div className={`flex items-center space-x-3 mt-1.5 ml-2`}>
                                 <button 
                                   onClick={() => setPlayingMsgIdx(playingMsgIdx === idx ? null : idx)}
                                   className={`transition-colors active:scale-95 ${playingMsgIdx === idx ? 'text-blue-500' : (isDark ? 'text-gray-500 hover:text-gray-300' : 'text-gray-400 hover:text-gray-600')}`} 
                                   title="朗读"
                                 >
                                    <Volume2 size={15} />
                                 </button>
                                 <button 
                                   onClick={() => toggleFeedback(idx, 'up')}
                                   className={`transition-colors active:scale-95 ${feedbackState[idx] === 'up' ? 'text-green-500' : (isDark ? 'text-gray-500 hover:text-gray-300' : 'text-gray-400 hover:text-gray-600')}`} 
                                   title="有帮助"
                                 >
                                    <ThumbsUp size={15} className={feedbackState[idx] === 'up' ? "fill-current" : ""} />
                                 </button>
                                 <button 
                                   onClick={() => toggleFeedback(idx, 'down')}
                                   className={`transition-colors active:scale-95 ${feedbackState[idx] === 'down' ? 'text-red-500' : (isDark ? 'text-gray-500 hover:text-gray-300' : 'text-gray-400 hover:text-gray-600')}`} 
                                   title="无帮助"
                                 >
                                    <ThumbsDown size={15} className={feedbackState[idx] === 'down' ? "fill-current" : ""} />
                                 </button>
                              </div>
                              
                              {idx === 0 && messages.length === 1 && msg.suggestedTopics && (
                                <div className="mt-3 flex overflow-x-auto scrollbar-hide space-x-2 pb-1 -mr-4 pr-4">
                                  {msg.suggestedTopics.map((topic, tIdx) => (
                                    <button
                                      key={tIdx}
                                      onClick={() => handleSend(topic, "quick-topic")}
                                      className={`shrink-0 text-[13px] border shadow-[0_2px_8px_rgba(43,58,103,0.04)] px-3.5 py-1.5 rounded-full font-medium active:scale-95 transition-all flex items-center ${isDark ? 'bg-[#2A2A2A] border-gray-800 text-gray-300 hover:text-white' : 'bg-white border-[#EBF0FA] text-[#2B3A67] hover:border-blue-200 hover:text-blue-500'}`}
                                    >
                                      {topic}
                                    </button>
                                  ))}
                                </div>
                              )}

                              {msg.time && <div className="text-[11px] text-gray-400 mt-2 ml-1">{msg.time}</div>}
                            </div>
                          </div>
                        )}
                        
                        {msg.type === "task" && msg.task && (
                          <div className="flex items-start mt-2">
                            <div className="w-2 mr-0 shrink-0"></div>
                            <div className={`w-[280px] p-4 rounded-[1.2rem] border shadow-[0_2px_15px_rgba(0,0,0,0.03)] relative overflow-hidden ${isDark ? 'bg-[#2A2A2A] border-gray-800' : 'bg-white border-gray-100'}`}>
                               <div className={`absolute -right-6 -bottom-6 w-28 h-28 bg-gradient-to-br rounded-full pointer-events-none opacity-60 ${isDark ? 'from-blue-900/20' : 'from-blue-50'} to-transparent`}></div>
                               
                               <h4 className={`font-bold text-[16px] mb-2 flex items-center ${isDark ? 'text-white' : 'text-gray-900'}`}>
                                 {msg.task.title} <Wind className="ml-1 text-[#2CC1C1]" size={16} />
                               </h4>
                               <p className={`text-[13px] mb-4 relative z-10 leading-relaxed ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>
                                 {msg.task.desc}
                               </p>

                               <div className="flex items-end justify-between relative z-10 mt-2">
                                 <div className={`text-[11px] text-[#2CC1C1] font-bold flex items-center px-2 py-1 rounded-md ${isDark ? 'bg-[#2CC1C1]/20' : 'bg-[#2CC1C1]/10'}`}>
                                   {msg.task.duration}
                                 </div>
                                 <button onClick={() => msg.task?.actionView && setActiveExercise(msg.task.actionView === "muyu" ? "rhythm" : "breathing")} className={`px-5 py-2 font-bold rounded-xl text-[13px] transition-colors shadow-sm ${isDark ? 'bg-[#20A6A6] text-white hover:bg-[#1C8C8C]' : 'bg-primary text-white hover:bg-[#20A6A6]'}`}>
                                   {msg.task.actionText}
                                 </button>
                               </div>
                            </div>
                          </div>
                        )}

                        {msg.type === "referral" && (
                          <div className="flex items-start mt-1">
                            <div className="w-2 mr-0 shrink-0"></div>
                            <div className={`w-[280px] p-4 rounded-[1.2rem] border shadow-[0_4px_20px_-4px_rgba(44,193,193,0.15)] relative overflow-hidden ${isDark ? 'bg-[#2A2A2A] border-primary/40' : 'bg-white border-primary/20'}`}>
                              <div className="absolute top-0 right-0 w-24 h-24 bg-primary/5 rounded-bl-full pointer-events-none"></div>
                              <div className="flex items-center mb-3">
                                <Activity className="text-primary mr-2" size={18} />
                                <span className={`font-bold text-[14px] ${isDark ? 'text-white' : 'text-gray-900'}`}>真人倾听师支持</span>
                              </div>
                              <p className={`text-[12px] mb-4 leading-relaxed ${isDark ? 'text-gray-400' : 'text-gray-600'}`}>
                                为您推荐了适合缓解当前状态的资深倾听师，他们非常有经验。
                              </p>
                              <button
                                onClick={() => {
                                  pushView("ai-recommendation");
                                }}
                                className={`w-full font-bold py-2 rounded-xl text-[13px] active:scale-[0.98] transition-all flex justify-center items-center ${isDark ? 'bg-[#20A6A6] text-white hover:bg-[#1C8C8C]' : 'bg-primary text-white hover:bg-[#20A6A6]'}`}
                              >
                                查看推荐倾听师 <ArrowRight size={14} className="ml-1" />
                              </button>
                            </div>
                          </div>
                        )}

                        {msg.type === "summary" && msg.summary && (
                          <div className="flex items-start mt-2">
                            <div className="w-2 mr-0 shrink-0"></div>
                            <div className={`w-[280px] p-4 rounded-[1.2rem] border shadow-sm ${isDark ? 'bg-[#2A2A2A] border-gray-800' : 'bg-white border-gray-100'}`}>
                              <div className="flex items-center mb-4">
                                <FileText className="text-[#2CC1C1] mr-2" size={18} />
                                <span className={`font-bold text-[15px] ${isDark ? 'text-white' : 'text-gray-900'}`}>阶段性总结</span>
                              </div>
                              <div className="space-y-3 mb-5">
                                <div>
                                  <div className={`text-[11px] font-bold mb-1 ${isDark ? 'text-gray-500' : 'text-gray-400'}`}>主要困扰</div>
                                  <div className={`text-[13px] ${isDark ? 'text-gray-300' : 'text-gray-800'}`}>{msg.summary.problem}</div>
                                </div>
                                <div>
                                  <div className={`text-[11px] font-bold mb-1 ${isDark ? 'text-gray-500' : 'text-gray-400'}`}>当前感受</div>
                                  <div className={`text-[13px] ${isDark ? 'text-gray-300' : 'text-gray-800'}`}>{msg.summary.feeling}</div>
                                </div>
                                <div>
                                  <div className={`text-[11px] font-bold mb-1 ${isDark ? 'text-gray-500' : 'text-gray-400'}`}>可能有关的事件</div>
                                  <div className={`text-[13px] ${isDark ? 'text-gray-300' : 'text-gray-800'}`}>{msg.summary.reason}</div>
                                </div>
                              </div>
                              <div className="space-y-2">
                                <button
                                  onClick={() => handleSend("我想继续跟你聊聊")}
                                  className={`w-full py-2.5 rounded-xl text-[13px] font-bold transition-transform active:scale-[0.98] ${isDark ? 'bg-[#1C1C1E] text-gray-300 border border-gray-700' : 'bg-gray-100 text-gray-700 hover:bg-gray-200'}`}
                                >
                                  继续和 AI 聊
                                </button>
                                <button
                                  onClick={() => pushView("ai-recommendation")}
                                  className={`w-full py-2.5 rounded-xl text-[13px] font-bold transition-transform active:scale-[0.98] ${isDark ? 'bg-[#20A6A6] text-white hover:bg-[#1C8C8C]' : 'bg-primary text-white hover:bg-[#20A6A6] shadow-[0_2px_10px_rgba(44,193,193,0.2)]'}`}
                                >
                                  找真人咨询师
                                </button>
                              </div>
                            </div>
                          </div>
                        )}

                        {msg.recommendations && (
                          <div className="flex items-start mt-1 w-full">
                            <div className="w-2 mr-0 shrink-0"></div>
                            <div className="space-y-3 max-w-[280px]">
                              {msg.recommendations.map((rec, rIdx) => (
                                <div
                                  key={rIdx}
                                  className={`rounded-[1.2rem] p-4 shadow-[0_2px_10px_rgba(0,0,0,0.03)] border flex flex-col pt-4 relative overflow-hidden ${isDark ? 'bg-[#2A2A2A] border-gray-800' : 'bg-white border-gray-50'}`}
                                >
                                  <div
                                    className={`absolute top-0 left-0 w-full h-1 ${
                                      rec.level === "L1"
                                        ? "bg-[#2CC1C1]"
                                        : rec.level === "L2"
                                          ? "bg-blue-500"
                                          : rec.level === "L3"
                                            ? "bg-orange-500"
                                            : "bg-red-500"
                                    }`}
                                  />
                                  <div className="flex items-center space-x-2 mb-2">
                                    <span
                                      className={`text-[10px] font-black px-1.5 py-0.5 rounded ${
                                        rec.level === "L1"
                                          ? (isDark ? 'bg-[#2CC1C1]/20 text-[#2CC1C1]' : 'bg-[#2CC1C1]/10 text-[#2CC1C1]')
                                          : rec.level === "L2"
                                            ? (isDark ? 'bg-blue-900/30 text-blue-400' : 'bg-blue-50 text-blue-500')
                                            : rec.level === "L3"
                                              ? (isDark ? 'bg-orange-900/30 text-orange-400' : 'bg-orange-50 text-orange-500')
                                              : (isDark ? 'bg-red-900/30 text-red-400' : 'bg-red-50 text-red-500')
                                      }`}
                                    >
                                      {rec.level}
                                    </span>
                                    <h4 className={`text-[14px] font-bold truncate ${isDark ? 'text-white' : 'text-gray-900'}`}>
                                      {rec.title}
                                    </h4>
                                  </div>
                                  <p className={`text-[12px] mb-4 leading-relaxed ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>
                                    {rec.desc}
                                  </p>
                                  <button
                                    onClick={() => {
                                      if (rec.type === "ai")
                                        handleSend("我想继续跟你聊聊");
                                    }}
                                    className={`w-full py-2.5 rounded-xl text-[12px] font-bold transition-transform active:scale-[0.98] ${
                                      rec.level === "L1" || rec.level === "L2"
                                        ? (isDark ? 'bg-white text-gray-900' : 'bg-gray-900 text-white shadow-sm')
                                        : (isDark ? 'bg-[#1C1C1E] text-gray-400 border border-gray-700' : 'bg-surface text-gray-600 border border-gray-100')
                                    }`}
                                  >
                                    {rec.level === "L1"
                                      ? "继续跟我聊聊"
                                      : rec.level === "L2"
                                        ? "查看在线倾听师"
                                      : rec.level === "L3"
                                          ? "了解专业咨询"
                                          : "获取危机热线"}
                                  </button>
                                </div>
                              ))}
                            </div>
                          </div>
                        )}
                      </div>
                    )}
                  </div>
                ))}
                
              </div>
            <div ref={endRef} />
          </div>

        <div className={`absolute bottom-0 left-0 right-0 border-t pt-2 z-20 flex flex-col transition-colors duration-200 ${isDark ? 'bg-[#121212] border-gray-800' : 'bg-[#f8f9fa] border-gray-200/60'}`}>
          {/* Quick Replies */}
          <div className="px-3 pb-2 flex space-x-2 overflow-x-auto scrollbar-hide">
             <button onClick={() => handleSend("心里有点烦，想敲敲木鱼", "quick-action")} className={`shrink-0 border shadow-sm text-[12px] px-3 py-1.5 rounded-full font-medium flex items-center active:scale-95 transition-transform ${isDark ? 'bg-[#1C1C1E] border-gray-800 text-gray-300' : 'bg-white border-gray-100 text-gray-700'}`}>
               <Activity size={14} className="text-orange-500 mr-1.5" /> 敲木鱼静静心
             </button>
             <button onClick={() => handleSend("我觉得有点紧绷，带我做个深呼吸吧", "quick-action")} className={`shrink-0 border shadow-sm text-[12px] px-3 py-1.5 rounded-full font-medium flex items-center active:scale-95 transition-transform ${isDark ? 'bg-[#1C1C1E] border-gray-800 text-gray-300' : 'bg-white border-gray-100 text-gray-700'}`}>
               <Wind size={14} className="text-blue-500 mr-1.5" /> 带我深呼吸
             </button>
             <button onClick={() => handleSend("最近压力有点大，想找你吐吐槽", "quick-action")} className={`shrink-0 border shadow-sm text-[12px] px-3 py-1.5 rounded-full font-medium flex items-center active:scale-95 transition-transform ${isDark ? 'bg-[#1C1C1E] border-gray-800 text-gray-300' : 'bg-white border-gray-100 text-gray-700'}`}>
               <Lightbulb size={14} className="text-green-500 mr-1.5" /> 想找你吐吐槽
             </button>
          </div>

          {/* Input Row */}
          <div className={`px-3 pb-2 flex items-end space-x-2.5 relative z-10 transition-colors ${isDark ? 'bg-[#121212]' : 'bg-[#f8f9fa]'}`}>
             <div className={`flex-1 rounded-[22px] border shadow-sm flex items-end min-h-[44px] relative transition-all overflow-hidden p-1 pl-1.5 ${isFocused ? 'ring-2 ring-primary/20 border-primary/40' : ''} ${isDark ? 'bg-[#2A2A2A] border-gray-700' : 'bg-white border-gray-200'}`}>
               {/* + Menu Trigger (Inside input) */}
               <button 
                 onClick={() => setShowPlusMenu(!showPlusMenu)} 
                 aria-label={showPlusMenu ? "关闭附件菜单" : "打开附件菜单"}
                 className={`w-9 h-9 rounded-full flex items-center justify-center shrink-0 transition-colors ${showPlusMenu ? (isDark ? 'text-gray-300' : 'text-gray-800') : (isDark ? 'text-gray-500 active:text-gray-400' : 'text-gray-400 active:text-gray-600')}`}
               >
                 <PlusCircle size={24} strokeWidth={1.5} className={showPlusMenu ? 'rotate-45 transition-transform' : 'transition-transform'} />
               </button>

               {inputMode === "text" ? (
                 <>
                <textarea
                  ref={inputRef}
                  aria-label="消息内容"
                  value={input}
                  onChange={(e) => {
                    setInput(e.target.value);
                    e.target.style.height = 'auto';
                    e.target.style.height = Math.min(e.target.scrollHeight, 120) + 'px';
                    if (showPlusMenu) setShowPlusMenu(false);
                    if (showEmojiMenu) setShowEmojiMenu(false);
                  }}
                  onFocus={() => {
                    setIsFocused(true);
                    if (showPlusMenu) setShowPlusMenu(false);
                    if (showEmojiMenu) setShowEmojiMenu(false);
                  }}
                  onBlur={() => setTimeout(() => setIsFocused(false), 200)}
                  onKeyDown={(e) => { 
                    if(e.key === "Enter" && !e.shiftKey) { 
                      e.preventDefault();
                      handleSend(); 
                    } 
                  }}
                  rows={1}
                  className={`flex-1 bg-transparent border-none outline-none text-[15px] px-2 py-2 resize-none max-h-[120px] self-center leading-relaxed ${isDark ? 'text-white placeholder-gray-500' : 'text-gray-800 placeholder-gray-400'}`}
                  placeholder="发消息..."
                />
                <button 
                  onClick={() => { setShowEmojiMenu(!showEmojiMenu); setShowPlusMenu(false); }} 
                  aria-label={showEmojiMenu ? "关闭表情面板" : "打开表情面板"}
                  className={`w-9 h-9 transition-colors flex items-center justify-center shrink-0 ${isDark ? 'text-gray-500 hover:text-primary' : 'text-gray-400 active:text-primary'}`}
                >
                  <Smile size={22} strokeWidth={1.5} className={showEmojiMenu ? 'text-primary' : ''} />
                </button>
                {!input.trim() && (
                  <button aria-label="切换到语音输入" onClick={() => setInputMode("voice")} className={`w-9 h-9 transition-colors flex items-center justify-center shrink-0 ${isDark ? 'text-gray-500 hover:text-primary' : 'text-gray-400 active:text-primary'}`}>
                    <Mic size={22} strokeWidth={1.5} />
                  </button>
                )}
              </>
               ) : (
                 <div className="flex-1 flex items-center h-[36px] mt-0.5 pr-1">
                <button aria-label="切换到文字输入" onClick={() => { setInputMode("text"); setShowEmojiMenu(false); }} className={`pl-1 pr-3 transition-colors flex items-center h-full shrink-0 ${isDark ? 'text-gray-500 hover:text-primary' : 'text-gray-400 active:text-primary'}`}>
                  <Keyboard size={20} strokeWidth={1.5} />
                </button>
                   <div 
                     className={`flex-1 h-[32px] rounded-full flex items-center justify-center font-bold text-[14px] select-none transition-colors cursor-pointer ${isRecording ? "bg-primary text-white" : (isDark ? "bg-[#1C1C1E] text-gray-300" : "bg-gray-100 text-gray-700")}`}
                     onPointerDown={() => setIsRecording(true)}
                     onPointerUp={() => {
                       setIsRecording(false);
                       setIsTranscribing(true);
                       setTimeout(() => {
                         setIsTranscribing(false);
                         handleSend("我现在感觉有点焦虑，能陪我聊聊吗？");
                         setInputMode("text");
                       }, 1500);
                     }}
                     onPointerCancel={() => setIsRecording(false)}
                   >
                     {isTranscribing ? "转译中..." : isRecording ? "松开 发送" : "按住 说话"}
                   </div>
                 </div>
               )}
             </div>

             {/* Send Button outside (only when typing) */}
             <AnimatePresence>
               {input.trim() && (
                 <motion.div 
                   initial={{ scale: 0, opacity: 0 }}
                   animate={{ scale: 1, opacity: 1 }}
                   exit={{ scale: 0, opacity: 0 }}
                   className="shrink-0 mb-1"
                 >
                   <button aria-label="发送消息" onClick={() => handleSend()} className="w-[38px] h-[38px] bg-primary text-white rounded-full flex items-center justify-center shadow-md active:scale-95 transition-transform">
                     <ArrowUp size={22} strokeWidth={2.5} />
                   </button>
                 </motion.div>
               )}
             </AnimatePresence>
          </div>

          {/* Expandable Emoji Menu */}
          <AnimatePresence>
            {showEmojiMenu && (
              <motion.div
                initial={{ height: 0, opacity: 0 }}
                animate={{ height: "auto", opacity: 1 }}
                exit={{ height: 0, opacity: 0 }}
                className={`overflow-hidden z-10 relative transition-colors ${isDark ? 'bg-[#121212]' : 'bg-[#f8f9fa]'}`}
              >
                <div className={`p-4 border-t mt-3 mx-auto ${isDark ? 'border-gray-800' : 'border-gray-200/50'}`}>
                  <div className="grid grid-cols-7 gap-2">
                    {commonEmojis.map((emoji, i) => (
                      <button 
                        key={i} 
                        aria-label={`插入表情 ${emoji}`}
                        onClick={() => {
                          setInput(prev => prev + emoji);
                        }}
                        className="text-[24px] flex items-center justify-center h-10 hover:bg-gray-100 active:bg-gray-200 dark:hover:bg-gray-800 rounded-lg transition-colors"
                      >
                        {emoji}
                      </button>
                    ))}
                  </div>
                </div>
              </motion.div>
            )}
          </AnimatePresence>

          {/* Expandable Plus Menu */}
          <AnimatePresence>
            {showPlusMenu && (
              <motion.div
                initial={{ height: 0, opacity: 0 }}
                animate={{ height: "auto", opacity: 1 }}
                exit={{ height: 0, opacity: 0 }}
                className={`overflow-hidden z-10 relative transition-colors ${isDark ? 'bg-[#121212]' : 'bg-[#f8f9fa]'}`}
              >
                <div className={`pt-4 pb-6 px-8 flex justify-between border-t mt-3 max-w-[320px] mx-auto ${isDark ? 'border-gray-800' : 'border-gray-200/50'}`}>
                  {[
                    { icon: ImageIcon, label: "相册", color: "text-blue-500" },
                    { icon: Camera, label: "拍摄", color: "text-gray-400" },
                    { icon: FileText, label: "文件", color: "text-orange-500" },
                  ].map((item, i) => (
                    <button key={i} onClick={() => setShowPlusMenu(false)} className="flex flex-col items-center active:scale-95 transition-transform w-16">
                      <div className={`w-14 h-14 rounded-2xl flex items-center justify-center shadow-sm border mb-2 ${isDark ? 'bg-[#2A2A2A] border-gray-700' : 'bg-white border-gray-100'}`}>
                        <item.icon size={26} strokeWidth={1.5} className={item.color} />
                      </div>
                      <span className={`text-[11px] font-medium ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>{item.label}</span>
                    </button>
                  ))}
                </div>
              </motion.div>
            )}
          </AnimatePresence>

          {/* Mock iOS Keyboard Presentation */}
          <AnimatePresence>
            {isFocused && (
              <motion.div
                initial={{ height: 0, opacity: 0 }}
                animate={{ height: 260, opacity: 1 }}
                exit={{ height: 0, opacity: 0 }}
                transition={{ type: "spring", damping: 25, stiffness: 250 }}
                className="w-full bg-[#D1D4D9] flex flex-col justify-start px-1 pt-3 pb-8 select-none overflow-hidden"
                onMouseDown={(e) => e.preventDefault()}
              >
                <div className="flex justify-center space-x-1.5 mb-3 px-1">
                  {['Q','W','E','R','T','Y','U','I','O','P'].map(k => (
                    <div key={k} className="w-[9%] h-11 bg-white rounded-lg flex items-center justify-center text-[17px] font-medium text-gray-900 shadow-sm">{k}</div>
                  ))}
                </div>
                <div className="flex justify-center space-x-1.5 mb-3 px-5">
                  {['A','S','D','F','G','H','J','K','L'].map(k => (
                    <div key={k} className="w-[10%] h-11 bg-white rounded-lg flex items-center justify-center text-[17px] font-medium text-gray-900 shadow-sm">{k}</div>
                  ))}
                </div>
                <div className="flex justify-center space-x-1.5 mb-3 px-1">
                  <div className="w-[13%] h-11 bg-[#B3B6BE] rounded-lg flex items-center justify-center shadow-sm">
                    <ArrowUp size={18} strokeWidth={2.5} className="text-gray-900" />
                  </div>
                  {['Z','X','C','V','B','N','M'].map(k => (
                    <div key={k} className="w-[10%] h-11 bg-white rounded-lg flex items-center justify-center text-[17px] font-medium text-gray-900 shadow-sm">{k}</div>
                  ))}
                  <div className="w-[13%] h-11 bg-[#B3B6BE] rounded-lg flex items-center justify-center shadow-sm">
                    <svg width="22" height="16" viewBox="0 0 18 14" fill="none" xmlns="http://www.w3.org/2000/svg">
                      <path d="M5.5 1L1 7L5.5 13H16C16.5523 13 17 12.5523 17 12V2C17 1.44772 16.5523 1 16 1H5.5Z" stroke="#111" strokeWidth="1.5" strokeLinejoin="round"/>
                      <path d="M9 4.5L14 9.5M14 4.5L9 9.5" stroke="#111" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
                    </svg>
                  </div>
                </div>
                <div className="flex justify-center space-x-1.5 px-1">
                  <div className="w-[22%] h-11 bg-[#B3B6BE] rounded-lg flex items-center justify-center text-[15px] font-medium text-gray-900 shadow-sm">123</div>
                  <div className="w-[12%] h-11 bg-[#B3B6BE] rounded-lg flex items-center justify-center shadow-sm"><Mic size={20} className="text-gray-900"/></div>
                  <div className="w-[42%] h-11 bg-white rounded-lg flex items-center justify-center text-[15px] font-medium text-gray-900 shadow-sm">换行 (Shift+Enter)</div>
                  <div className="w-[22%] h-11 bg-blue-500 rounded-lg flex items-center justify-center text-[15px] font-bold text-white shadow-sm" onClick={() => {
                    handleSend();
                    setIsFocused(false);
                  }}>发送</div>
                </div>
              </motion.div>
            )}
          </AnimatePresence>

          {hasRiskContext && (
             <div className="flex justify-center mt-2 h-6">
               <button onClick={() => setShowCrisisAlert(true)} className="flex items-center text-[11px] bg-red-50 text-red-500 px-3 py-1 rounded-full font-bold border border-red-100 shadow-sm">
                 <AlertTriangle size={12} className="mr-1" />
                 SOS 紧急求助
               </button>
             </div>
          )}
        </div>
        </>
      
      {/* 危机预警弹窗 (L4 发现风险词拦截) */}
      <AnimatePresence>
        {activeExercise && <EmotionExercise type={activeExercise} onClose={() => setActiveExercise(null)} onComplete={(score) => {
          const exerciseName = activeExercise === "breathing" ? "呼吸练习" : "节奏锚定";
          setActiveExercise(null);
          setMessages((items) => [...items, { id: `${Date.now()}_exercise_result`, role: "ai", type: "text", text: score <= 2 ? `${exerciseName}完成了。你现在已经平静了不少，先保持这个节奏，不急着马上处理所有事情。你愿意说说刚才最明显的变化在哪里吗？` : score === 3 ? `${exerciseName}完成了。情绪有一点松动，但还在。我们可以继续聊聊：此刻最占据你注意力的念头是什么？` : `${exerciseName}完成了，但难受仍然比较强烈。练习没有立刻见效并不是你的问题。我们先不勉强放松，你愿意告诉我现在最需要的是被倾听，还是一起梳理具体困扰？`, time: new Date().toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" }) }]);
        }} />}
        {showCrisisAlert && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="absolute inset-0 bg-black/60 z-[100] flex items-center justify-center p-6 backdrop-blur-sm"
          >
            <motion.div
              initial={{ scale: 0.95, y: 20 }}
              animate={{ scale: 1, y: 0 }}
              exit={{ scale: 0.95, y: 20 }}
              className="bg-white rounded-[2rem] p-6 w-full max-w-sm shadow-2xl relative overflow-hidden"
            >
              <div className="absolute top-0 inset-x-0 h-1 bg-red-500"></div>
              <div className="w-12 h-12 bg-red-50 text-red-500 rounded-full flex items-center justify-center mb-4 border border-red-100">
                <ShieldAlert size={24} />
              </div>
              <h2 className="text-xl font-black text-gray-900 mb-2">
                生命安全预警拦截
              </h2>
              <p className="text-[14px] text-gray-600 mb-6 leading-relaxed">
                系统检测到您的情绪可能处于
                <span className="font-bold text-red-500">高危状态</span>
                。在这个艰难的时刻，请让专业的医生和公益力量帮助你，你不是一个人。
              </p>
              <div className="space-y-3">
                <a
                  href="tel:400-161-9995"
                  className="w-full bg-red-50 text-red-600 border border-red-200 font-bold py-3.5 rounded-xl flex justify-center items-center active:scale-95 transition-transform text-[15px]"
                >
                  <Phone size={18} className="mr-2" />
                  拨打 400-161-9995 热线
                </a>
                <button
                  onClick={() => setShowCrisisAlert(false)}
                  className="w-full bg-white text-gray-500 font-bold py-3 rounded-xl border border-gray-100 active:scale-95 transition-transform text-[14px]"
                >
                  我只是随口一说
                </button>
              </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </motion.div>
  );
}
