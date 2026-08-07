import { motion } from "motion/react";
import { useAppStore } from "../../store";
import { ChevronLeft, FileText, CheckCircle2, Sparkles, User, UserCircle } from "lucide-react";
import { mockCounselors } from "../../data";

export function CounselingSummaryDetail() {
  const { popView } = useAppStore();

  return (
    <motion.div
      initial={{ x: "100%" }}
      animate={{ x: 0 }}
      exit={{ x: "100%" }}
      transition={{ type: "spring", damping: 25, stiffness: 200 }}
      className="flex flex-col h-full bg-[#f8f9fa] absolute inset-0 z-50 overflow-hidden"
    >
      <div className="pt-14 pb-4 px-4 bg-white sticky top-0 z-20 flex items-center shadow-sm">
        <button
          onClick={popView}
          className="w-10 h-10 -ml-2 flex items-center justify-center text-gray-900 border border-transparent active:bg-gray-50 rounded-full transition-colors"
        >
          <ChevronLeft size={24} />
        </button>
        <h1 className="text-[17px] font-bold text-gray-900 ml-2">
          小结与建议详情
        </h1>
      </div>

      <div className="flex-1 overflow-y-auto p-4 pb-12">
        {/* Header Info */}
        <div className="bg-white p-5 rounded-[1.5rem] shadow-sm border border-gray-100 mb-4">
          <div className="flex justify-between items-center mb-4">
            <h2 className="font-black text-gray-900 text-lg">本次咨询回顾</h2>
            <span className="text-[12px] text-gray-500 font-medium">06.20 · 14:00</span>
          </div>
          <div className="flex items-center space-x-3 bg-gray-50 p-3 rounded-xl border border-gray-100">
            <img 
              src={mockCounselors[0].avatar} 
              alt="avatar" 
              className="w-10 h-10 rounded-full object-cover shadow-sm"
            />
            <div>
              <p className="text-[14px] font-bold text-gray-900">咨询师：{mockCounselors[0].name}</p>
              <p className="text-[11px] text-gray-500 mt-0.5">专业心理咨询师</p>
            </div>
          </div>
        </div>

        {/* Notes Content */}
        <div className="bg-white rounded-[1.5rem] p-6 shadow-sm border border-gray-100 mb-4">
          <h3 className="font-bold text-gray-900 text-[16px] mb-4 flex items-center border-b border-gray-50 pb-3">
            <UserCircle size={20} className="text-blue-500 mr-2" />
            咨询师小结
          </h3>
          <p className="text-[14px] text-gray-700 leading-loose tracking-wide">
            本次沟通中，我们深入探讨了职场人际关系带给你的压力，以及背后潜藏的自我认同感问题。
            <br/><br/>
            你在会话后半段展现出了很好的觉察力，能够清晰地描述出“害怕犯错导致回避行为”的心理机制。这是一个非常好的开始，看见即是疗愈的一半。
          </p>
        </div>

        {/* Suggestions Content */}
        <div className="bg-white rounded-[1.5rem] p-6 shadow-sm border border-gray-100">
          <h3 className="font-bold text-gray-900 text-[16px] mb-4 flex items-center border-b border-gray-50 pb-3">
            <CheckCircle2 size={20} className="text-green-500 mr-2" />
            行动建议与练习
          </h3>
          <div className="space-y-4">
            <div className="bg-green-50/50 p-4 rounded-xl border border-green-100/50">
              <h4 className="font-bold text-green-800 text-[14px] mb-2 flex items-center">
                <span className="w-5 h-5 rounded-full bg-green-200 text-green-700 flex items-center justify-center text-[12px] mr-2">1</span>
                记录自动思维
              </h4>
              <p className="text-[13px] text-gray-600 leading-relaxed pl-7">
                本周在感到焦虑或害怕犯错时，尝试拿出纸笔，或者在备忘录里写下那一刻脑海中冒出的第一个想法。
              </p>
            </div>
            <div className="bg-green-50/50 p-4 rounded-xl border border-green-100/50">
              <h4 className="font-bold text-green-800 text-[14px] mb-2 flex items-center">
                <span className="w-5 h-5 rounded-full bg-green-200 text-green-700 flex items-center justify-center text-[12px] mr-2">2</span>
                4-7-8 呼吸放松法
              </h4>
              <p className="text-[13px] text-gray-600 leading-relaxed pl-7">
                如果在会议前或汇报时感到胸闷、心跳加快，请尝试做 3-5 轮 4-7-8 呼吸放松法，让身体先平静下来。
              </p>
            </div>
          </div>
        </div>
      </div>
    </motion.div>
  );
}