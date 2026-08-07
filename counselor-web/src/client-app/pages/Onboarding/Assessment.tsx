import { useState, useRef, useEffect } from "react";
import { motion, AnimatePresence } from "motion/react";
import { useAppStore } from "../../store";
import { ChevronRight, ArrowRight } from "lucide-react";

export function Assessment() {
  const { pushView, resetToView, updateUser, updateBlackboard, assessmentState, setAssessmentState, user } = useAppStore();
  const { step, answers, phq2Scores, phq2Step } = assessmentState;

  const setStep = (val: number | ((prev: number) => number)) => {
    setAssessmentState((prev: any) => ({ ...prev, step: typeof val === 'function' ? val(prev.step) : val }));
  };

  const setAnswers = (val: any) => {
    setAssessmentState((prev: any) => ({ ...prev, answers: typeof val === 'function' ? val(prev.answers) : val }));
  };

  const setPhq2Scores = (val: any) => {
    setAssessmentState((prev: any) => ({ ...prev, phq2Scores: typeof val === 'function' ? val(prev.phq2Scores) : val }));
  };

  const setPhq2Step = (val: number | ((prev: number) => number)) => {
    setAssessmentState((prev: any) => ({ ...prev, phq2Step: typeof val === 'function' ? val(prev.phq2Step) : val }));
  };

  const handleSkip = () => {
    // 如果用户跳过，依然保存当前已填写的信息并标记为新用户
    updateUser({
      isNewUser: true,
    });

    // Write what we have to blackboard
    const totalScore = phq2Scores[0] !== -1 && phq2Scores[1] !== -1 ? phq2Scores[0] + phq2Scores[1] : 0;
    
    updateBlackboard({
      clinical: phq2Scores[0] !== -1 ? {
        phq2Score: totalScore,
        severity: totalScore >= 4 ? "中度" : totalScore >= 2 ? "轻度" : "轻度", // Using MVP mapping
        crisis: phq2Scores.some(s => s === 3)
      } : null,
      domain: answers.domain ? {
        primary: answers.domain as any
      } : null,
      phase: 1,
      recommendation: {
        serviceLevel: totalScore >= 4 ? "L1" : "L1", // All default to L1 for now, will upgrade later
        firstTool: "呼吸引导",
        persona: "温暖陪伴"
      }
    });

    resetToView("main");
  };

  const handleNext = () => {
    if (step < flow.length - 1) {
      setStep(step + 1);
    } else {
      // 完成所有流程
      updateUser({
        isNewUser: false,
      });

      // Write complete data to blackboard
      const totalScore = phq2Scores[0] + phq2Scores[1];
      
      updateBlackboard({
        clinical: {
          phq2Score: totalScore,
          severity: totalScore >= 4 ? "中度" : totalScore >= 2 ? "轻度" : "轻度",
          crisis: phq2Scores.some(s => s === 3)
        },
        domain: {
          primary: (answers.domain && answers.domain !== "不想说" ? answers.domain : "未分类") as any
        },
        phase: 1,
        recommendation: {
          serviceLevel: "L1",
          firstTool: "呼吸引导",
          persona: "温暖陪伴"
        }
      });

      resetToView("main");
    }
  };

  const handleSelect = (key: keyof typeof answers, val: string) => {
    if (val === "不想说") {
      setAnswers((prev) => ({ ...prev, [key]: "" }));
    } else {
      setAnswers((prev) => ({ ...prev, [key]: val }));
    }
    setTimeout(() => {
      handleNext();
    }, 300);
  };

  const handlePhq2Select = (score: number) => {
    const newScores = [...phq2Scores];
    newScores[phq2Step] = score;
    setPhq2Scores(newScores);
    
    setTimeout(() => {
      if (phq2Step === 0) {
        setPhq2Step(1);
      } else {
        handleNext();
      }
    }, 300);
  };

  const flow = [
    {
      type: "intro",
      title: "嗨，我是小鹿。",
      desc: "用2分钟，让我认识你。",
      button: "开始",
    },
    {
      type: "phq2",
      title: "先问你两个小问题——",
      desc: "不是考试，凭感觉选就好。",
    },
    {
      type: "feedback",
      // feedback content is generated dynamically
    },
    {
      type: "select",
      key: "stage",
      title: "你现在是在...",
      desc: "",
      options: ["大学生", "研究生", "刚工作", "其他"],
    },
    {
      type: "select",
      key: "domain",
      title: "最近主要烦什么？（可选）",
      desc: "",
      options: ["学业", "工作", "感情", "人际", "说不清", "不想说"],
    },
    {
      type: "finish",
      // finish content is generated dynamically
    }
  ];

  const getFeedback = () => {
    const total = phq2Scores[0] + phq2Scores[1];
    if (total <= 1) return { text: "看起来你最近状态不错！继续保持~", mood: "微笑" };
    if (total <= 3) return { text: "最近有点辛苦吧？没关系，我陪你。", mood: "轻微担心" };
    return { text: "谢谢你愿意告诉我这些。我想帮你。", mood: "认真" };
  };

  const phq2Questions = [
    {
      q: "最近两周，有没有觉得开心不起来，\n或者心里像压了块石头？",
      options: ["没有", "偶尔", "经常", "几乎每天"]
    },
    {
      q: "有没有觉得以前喜欢的事，\n突然不想做了？",
      options: ["没有", "偶尔", "经常", "几乎每天"]
    }
  ];

  const currentStep = flow[step];

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      className="flex flex-col h-full bg-white p-6 relative overflow-hidden"
    >
      {/* 顶部进度条和跳过按钮 (Intro 阶段不显示) */}
      <div className="mt-12 mb-8 flex items-center justify-between min-h-[24px]">
        {step > 0 && (
          <>
            <div className="flex space-x-2 flex-1 mr-6">
              {flow.slice(1).map((_, i) => (
                <div
                  key={i}
                  className={`h-1.5 flex-1 rounded-full transition-colors ${
                    i <= step - 1 ? "bg-primary" : "bg-gray-100"
                  }`}
                />
              ))}
            </div>
            <button
              onClick={handleSkip}
              className="text-[13px] font-bold text-gray-400 shrink-0 hover:text-gray-600 transition-colors"
            >
              先去逛逛
            </button>
          </>
        )}
      </div>

      <AnimatePresence mode="wait">
        <motion.div
          key={step}
          initial={{ x: 30, opacity: 0 }}
          animate={{ x: 0, opacity: 1 }}
          exit={{ x: -30, opacity: 0 }}
          transition={{ duration: 0.4, ease: "easeOut" }}
          className="flex-1 flex flex-col pt-4"
        >
          {currentStep && currentStep.type === "intro" && (
            <div className="flex-1 flex flex-col items-center justify-center text-center pb-20">
              <h2 className="text-[26px] font-black text-gray-900 mb-4">
                {currentStep.title}
              </h2>
              <p className="text-[15px] text-gray-500 leading-relaxed max-w-[280px]">
                {currentStep.desc}
              </p>
              
              <div className="absolute bottom-6 right-6 w-24 h-24 flex items-center justify-center">
                <span className="text-6xl animate-bounce" style={{ animationDuration: '3s' }}>🦌</span>
              </div>

              <div className="mt-16 w-full px-6">
                <button
                  onClick={handleNext}
                  className="w-full bg-gray-900 text-white font-bold py-4 rounded-xl flex items-center justify-center space-x-2 active:scale-95 transition-transform shadow-lg"
                >
                  <span>{currentStep.button}</span>
                  <ArrowRight size={18} />
                </button>
              </div>
            </div>
          )}

          {currentStep && currentStep.type === "phq2" && (
            <div className="flex-1 flex flex-col">
              <h2 className="text-[24px] font-bold text-gray-900 mb-3 leading-tight">
                {currentStep.title}
              </h2>
              <p className="text-gray-500 text-[15px] mb-8 leading-relaxed">
                {currentStep.desc}
              </p>

              <div className="flex-1 space-y-6">
                <AnimatePresence mode="wait">
                  <motion.div
                    key={`phq2-${phq2Step}`}
                    initial={{ opacity: 0, y: 20 }}
                    animate={{ opacity: 1, y: 0 }}
                    exit={{ opacity: 0, y: -20 }}
                    className="bg-white rounded-2xl p-6 border border-gray-100 shadow-sm"
                  >
                    <p className="text-[18px] font-bold text-gray-900 mb-6 whitespace-pre-line">
                      {phq2Questions[phq2Step].q}
                    </p>
                    <div className="space-y-3">
                      {phq2Questions[phq2Step].options.map((opt, i) => (
                        <button
                          key={i}
                          onClick={() => handlePhq2Select(i)}
                          className="w-full py-4 rounded-xl border border-gray-200 bg-surface flex items-center justify-center hover:border-gray-400 active:bg-gray-50 transition-all font-medium text-gray-800"
                        >
                          {opt}
                        </button>
                      ))}
                    </div>
                  </motion.div>
                </AnimatePresence>

                <div className="flex justify-center pt-4">
                  <span className="text-4xl transition-transform duration-500" style={{ transform: phq2Step === 1 ? 'rotate(90deg)' : 'rotate(0deg)' }}>🦌</span>
                </div>
              </div>
            </div>
          )}

          {currentStep && currentStep.type === "feedback" && (
            <div className="flex-1 flex flex-col items-center justify-center text-center pb-20 px-4">
              <div className="text-7xl mb-8">🦌</div>
              <h2 className="text-[24px] font-bold text-gray-900 mb-12 leading-relaxed">
                "{getFeedback().text}"
              </h2>
              
              <div className="w-full space-y-4">
                <p className="text-gray-500 text-[15px] mb-6">
                  接下来帮我填几个基本信息，<br/>这样我能更懂你。
                </p>
                <button
                  onClick={handleNext}
                  className="w-full bg-gray-900 text-white font-bold py-4 rounded-xl flex items-center justify-center space-x-2 active:scale-95 transition-transform shadow-lg"
                >
                  <span>继续</span>
                  <ArrowRight size={18} />
                </button>
              </div>
            </div>
          )}

          {currentStep && currentStep.type === "select" && (
              <div className="flex-1 flex flex-col">
                <h2 className="text-[24px] font-bold text-gray-900 mb-3 leading-tight">
                  {currentStep.title}
                </h2>
                <p className="text-gray-500 text-[15px] mb-10 leading-relaxed">
                  {currentStep.desc}
                </p>
                <div className="space-y-4">
                  {currentStep.options?.map((opt, i) => (
                    <button
                      key={i}
                      onClick={() =>
                        handleSelect(currentStep.key as keyof typeof answers, opt)
                      }
                      className="w-full p-5 rounded-2xl border border-gray-100 bg-surface flex items-center justify-between hover:border-primary active:bg-primary-light transition-all text-left group"
                    >
                      <span className="text-gray-800 font-medium text-[16px]">
                        {opt}
                      </span>
                      <ChevronRight
                        className="text-gray-300 group-hover:text-primary transition-colors"
                        size={20}
                      />
                    </button>
                  ))}
                </div>
              </div>
            )}

            {currentStep && currentStep.type === "finish" && (
              <div className="flex-1 flex flex-col items-center justify-center text-center pb-20 px-4">
                <div className="text-7xl mb-8 animate-pulse">🦌👋</div>
                <h2 className="text-[26px] font-black text-gray-900 mb-4">
                  谢谢你，{user.name || "新朋友"}。
                </h2>
                <p className="text-[16px] text-gray-500 leading-relaxed mb-12">
                  我已经记住你啦。<br/>下次来，我会在这里等你。
                </p>
                
                <div className="w-full">
                  <button
                    onClick={handleNext}
                    className="w-full bg-gray-900 text-white font-bold py-4 rounded-xl flex items-center justify-center space-x-2 active:scale-95 transition-transform shadow-lg"
                  >
                    <span>进入首页</span>
                    <ArrowRight size={18} />
                  </button>
                </div>
              </div>
            )}
          </motion.div>
        </AnimatePresence>
    </motion.div>
  );
}
