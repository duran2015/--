import { motion } from "motion/react";
import { useAppStore } from "../../store";
import { ArrowLeft, RefreshCw, FileText, ClipboardX } from "lucide-react";
import { MissingDataPage } from "../../components/EmptyState";

export function AssessmentReportDetail() {
  const { popView, pushView, assessmentRecords } = useAppStore();
  
  // Hardcoded to first record for demo, in real app would use selected record ID
  const record = assessmentRecords[0];

  if (!record) {
    return <MissingDataPage icon={ClipboardX} title="报告还未生成" description="完成测评后，分数解读和个性化建议会保存在这里。" onBack={popView} actionLabel="返回测评记录" />;
  }

  return (
    <motion.div
      initial={{ x: "100%" }}
      animate={{ x: 0 }}
      exit={{ x: "100%" }}
      transition={{ type: "spring", damping: 25, stiffness: 200 }}
      className="absolute inset-0 bg-[#f8f9fa] z-[70] flex flex-col"
    >
      <div className="flex items-center justify-between px-4 py-3 border-b border-gray-100 bg-white sticky top-0 z-10 shadow-sm">
        <button
          onClick={popView}
          className="w-8 h-8 flex items-center justify-center active:bg-gray-100 rounded-full transition-colors"
        >
          <ArrowLeft size={20} className="text-gray-900" />
        </button>
        <span className="font-bold text-gray-900 text-[16px]">测评报告</span>
        <div className="w-8"></div>
      </div>

      <div className="flex-1 overflow-y-auto w-full pb-32">
        <div className="bg-white p-6 mb-3 shadow-sm border-b border-gray-100">
          <div className="text-center mb-6">
            <h2 className="text-[18px] font-bold text-gray-900 mb-2">{record.title}</h2>
            <p className="text-[12px] text-gray-400">测评时间：{record.date}</p>
          </div>

          <div className="bg-surface rounded-[1.5rem] p-6 text-center mb-6">
            <div className="text-[40px] font-bold text-primary leading-none mb-2">
              {record.score}
            </div>
            <div className="text-[16px] font-bold text-gray-800 mb-3">
              {record.result}
            </div>
            <div className="flex justify-center space-x-2">
              {record.tagsGenerated?.map((tag: string, i: number) => (
                <span key={i} className="bg-white text-gray-600 px-3 py-1 rounded-full text-[12px] shadow-sm">
                  {tag}
                </span>
              ))}
            </div>
          </div>

          <div>
            <h3 className="text-[15px] font-bold text-gray-900 mb-3 flex items-center">
              <span className="w-1 h-3.5 bg-primary rounded-full mr-2"></span>
              结果解读
            </h3>
            <p className="text-[14px] text-gray-600 leading-relaxed">
              根据您的得分情况，您目前存在一定程度的{record.result.replace('倾向', '')}。这可能与近期生活压力、学业压力或人际关系变化有关。这种状态比较常见，不必过度恐慌，但建议开始关注并进行适当的自我调节。
            </p>
          </div>
        </div>

        <div className="bg-white p-6 shadow-sm border-y border-gray-100">
          <h3 className="text-[15px] font-bold text-gray-900 mb-3 flex items-center">
            <span className="w-1 h-3.5 bg-primary rounded-full mr-2"></span>
            专业建议
          </h3>
          <ul className="space-y-4">
            <li className="flex items-start">
              <div className="w-5 h-5 rounded-full bg-blue-50 text-blue-500 flex items-center justify-center text-[12px] font-bold shrink-0 mt-0.5 mr-3">1</div>
              <p className="text-[14px] text-gray-600 leading-relaxed">保持规律作息，尽量保证每天7-8小时的高质量睡眠。</p>
            </li>
            <li className="flex items-start">
              <div className="w-5 h-5 rounded-full bg-blue-50 text-blue-500 flex items-center justify-center text-[12px] font-bold shrink-0 mt-0.5 mr-3">2</div>
              <p className="text-[14px] text-gray-600 leading-relaxed">可以尝试应用内的“呼吸引导”或“正念冥想”工具来放松身心。</p>
            </li>
            <li className="flex items-start">
              <div className="w-5 h-5 rounded-full bg-blue-50 text-blue-500 flex items-center justify-center text-[12px] font-bold shrink-0 mt-0.5 mr-3">3</div>
              <p className="text-[14px] text-gray-600 leading-relaxed">若负面情绪持续超过两周且影响正常生活，建议预约专业咨询师进行沟通。</p>
            </li>
          </ul>
        </div>
      </div>

      <div className="absolute bottom-0 left-0 right-0 p-5 bg-white border-t border-gray-100 shadow-[0_-10px_40px_rgba(0,0,0,0.03)] z-20">
        <button
          onClick={() => {
            // Usually this would push to the assessment taking view with the same assessment ID
            alert("正在跳转到量表重测页面...");
            pushView("assessment");
          }}
          className="w-full bg-gray-900 text-white font-bold py-4 rounded-full flex items-center justify-center space-x-2 active:bg-gray-800 transition-colors shadow-md shadow-gray-900/10"
        >
          <RefreshCw size={18} />
          <span className="text-[15px]">重新测评</span>
        </button>
        <p className="text-center text-[11px] text-gray-400 mt-3">建议每2周-1个月复测一次，以观察状态变化</p>
      </div>
    </motion.div>
  );
}
