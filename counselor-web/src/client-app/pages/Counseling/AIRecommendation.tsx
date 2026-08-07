import { motion } from "motion/react";
import { ChevronLeft, CheckCircle2, ChevronRight, Clock, Star } from "lucide-react";
import { useAppStore } from "../../store";
import { mockCounselors } from "../../data";

export function AIRecommendation() {
  const { popView, pushView, setSelectedCounselorId } = useAppStore();

  const services = [
    {
      id: "s1",
      name: "20分钟倾诉体验",
      desc: "适合：你现在需要先被接住、被听见",
      price: 39,
    },
    {
      id: "s2",
      name: "30分钟问题初筛",
      desc: "适合：你还不确定自己需要哪类支持",
      price: 79,
    },
    {
      id: "s3",
      name: "45分钟心理咨询",
      desc: "适合：这个困扰持续出现，想深入聊一次",
      price: 199,
      recommended: true
    },
    {
      id: "s4",
      name: "3次支持包",
      desc: "适合：你希望连续跟进一段时间",
      price: 499,
    }
  ];

  // Pick some counselors from mockCounselors for recommendation
  const recommendedCounselors = mockCounselors.slice(0, 2);

  return (
    <motion.div
      initial={{ opacity: 0, x: 20 }}
      animate={{ opacity: 1, x: 0 }}
      exit={{ opacity: 0, x: 20 }}
      className="absolute inset-0 bg-[#f8f9fa] z-50 flex flex-col"
    >
      <div className="pt-12 pb-3 px-4 bg-white sticky top-0 z-20 flex items-center shadow-sm">
        <button onClick={() => popView()} className="p-2 -ml-2 text-gray-500 hover:text-gray-900 transition-colors">
          <ChevronLeft size={24} />
        </button>
        <div className="flex-1 text-center font-bold text-[16px] text-gray-900 pr-8">
          专属推荐方案
        </div>
      </div>

      <div className="flex-1 overflow-y-auto px-4 pt-4 pb-24">
        <p className="text-[13px] text-gray-500 mb-6 px-1">
          以下推荐仅基于你刚才的表达，用于帮助你选择更合适的支持方式，不作为医学诊断。
        </p>

        <h3 className="font-bold text-[16px] text-gray-900 mb-4 px-1">推荐支持方式</h3>
        <div className="space-y-3 mb-8">
          {services.map(s => (
            <div key={s.id} className={`bg-white rounded-2xl p-4 border transition-all cursor-pointer active:scale-[0.98] ${s.recommended ? 'border-[#2CC1C1] shadow-[0_4px_15px_rgba(44,193,193,0.1)]' : 'border-gray-100 shadow-sm'}`}>
              {s.recommended && (
                <div className="absolute top-0 right-0 bg-[#2CC1C1] text-white text-[10px] font-bold px-2 py-1 rounded-bl-lg rounded-tr-xl">
                  AI 强推
                </div>
              )}
              <div className="flex justify-between items-center mb-1">
                <div className="font-bold text-[15px] text-gray-900">{s.name}</div>
                <div className="font-black text-[16px] text-[#2CC1C1]">¥{s.price}</div>
              </div>
              <div className="text-[12px] text-gray-500">{s.desc}</div>
            </div>
          ))}
        </div>

        <h3 className="font-bold text-[16px] text-gray-900 mb-4 px-1">推荐咨询师</h3>
        <div className="space-y-4">
          {recommendedCounselors.map(c => (
            <div key={c.id} className="bg-white rounded-2xl p-4 border border-gray-100 shadow-sm">
              <div className="flex items-start mb-3">
                <img src={c.avatar} alt={c.name} className="w-12 h-12 rounded-full object-cover mr-3 bg-gray-100" />
                <div className="flex-1">
                  <div className="flex items-center justify-between">
                    <h4 className="font-bold text-[16px] text-gray-900">{c.name}</h4>
                    <div className="text-[13px] font-bold text-orange-500 flex items-center">
                      <Star size={14} className="fill-current mr-0.5" /> {c.rating}
                    </div>
                  </div>
                  <div className="text-[12px] text-gray-500 mt-0.5 line-clamp-1">
                    擅长：{c.specialties.join("、")}
                  </div>
                </div>
              </div>

              <div className="bg-blue-50/50 rounded-xl p-3 mb-4 border border-blue-100/50">
                <div className="text-[11px] font-bold text-blue-600 mb-1 flex items-center">
                  <CheckCircle2 size={12} className="mr-1" /> 匹配理由
                </div>
                <div className="text-[12px] text-gray-600 leading-relaxed">
                  你刚才提到最近主要是职场压力和长期内耗，{c.name}老师擅长情绪压力和职场心理支持，能很好地帮助你。
                </div>
              </div>

              <div className="flex space-x-3">
                <button 
                  onClick={() => {
                    setSelectedCounselorId(c.id);
                    pushView("counseling-detail");
                  }}
                  className="flex-1 py-2.5 rounded-xl border border-gray-200 text-gray-700 font-bold text-[13px] active:bg-gray-50 transition-colors"
                >
                  查看主页
                </button>
                <button 
                  onClick={() => {
                    setSelectedCounselorId(c.id);
                    // 场景B：直接进入摘要同步确认页
                    pushView("ai-summary-sync");
                  }}
                  className="flex-1 py-2.5 rounded-xl bg-primary text-white font-bold text-[13px] active:scale-95 transition-transform"
                >
                  预约
                </button>
              </div>
            </div>
          ))}
        </div>
      </div>
    </motion.div>
  );
}
