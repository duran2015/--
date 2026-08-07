import { ChevronLeft } from "lucide-react";
import { useAppStore } from "../../store";

export function LegalDocument() {
  const { popView } = useAppStore();

  return (
    <div className="flex flex-col h-full bg-white absolute inset-0 z-[100]">
      <div className="px-5 pt-12 pb-4 flex items-center bg-white sticky top-0 z-10 border-b border-gray-100 shadow-sm">
        <button onClick={popView} className="p-2 -ml-2 active:scale-95 transition-transform">
          <ChevronLeft size={24} className="text-gray-800" />
        </button>
        <h1 className="text-[17px] font-bold text-gray-900 ml-2">协议与政策</h1>
      </div>

      <div className="flex-1 overflow-y-auto px-5 py-6">
        <div className="prose prose-sm prose-gray max-w-none text-[13px] leading-relaxed text-gray-600">
          <h2 className="text-[18px] font-bold text-gray-900 mb-4 text-center">可鹿心理用户协议与隐私政策</h2>
          
          <p className="font-bold text-gray-800 mb-2">最近更新日期：2026年07月16日</p>
          
          <p className="mb-4">
            欢迎您使用「可鹿心理」！本应用由可鹿心理科技有限公司（以下简称“我们”）开发并运营。我们深知个人信息对您的重要性，并庄重承诺保护您的隐私安全。
          </p>

          <h3 className="text-[15px] font-bold text-gray-800 mt-6 mb-2">一、我们如何收集和使用您的信息</h3>
          <p className="mb-2">
            1. <strong>基本信息</strong>：当您注册账号时，我们需要收集您的手机号码或第三方平台授权信息。
          </p>
          <p className="mb-2">
            2. <strong>服务信息</strong>：在您使用 AI 倾诉、心理测评、情绪记录或真人咨询时，我们会收集您主动提供的文字、语音及选择的标签，以便为您提供连贯的支持服务。
          </p>
          <p className="mb-2">
            3. <strong>摘要授权</strong>：仅在您明确授权的情况下，AI 聊天记录的结构化摘要才会同步给您预约的真人咨询师。
          </p>

          <h3 className="text-[15px] font-bold text-gray-800 mt-6 mb-2">二、服务边界声明</h3>
          <p className="mb-4">
            「可鹿心理」提供的服务属于泛心理支持范畴。<strong>我们不提供任何形式的医学诊断，亦不能替代精神科诊疗或危机干预。</strong> 如果您正处于严重的心理危机或有伤害自己/他人的倾向，请立即拨打紧急救助电话（如 110、120）或前往专业医疗机构就诊。
          </p>

          <h3 className="text-[15px] font-bold text-gray-800 mt-6 mb-2">三、信息的存储与安全</h3>
          <p className="mb-4">
            您的数据将被加密存储于国内安全服务器中。除非获得您的明确同意或法律法规要求，我们不会向任何第三方分享您的敏感个人信息。
          </p>

          <h3 className="text-[15px] font-bold text-gray-800 mt-6 mb-2">四、您的权利</h3>
          <p className="mb-4">
            您可以在“账号与安全”中随时查看、修改或删除您的个人信息，也可以申请注销账号。注销账号后，我们将停止为您提供服务，并删除或匿名化您的所有数据。
          </p>

          <div className="mt-8 pt-6 border-t border-gray-100 text-center text-gray-400">
            <p>可鹿心理科技有限公司</p>
            <p className="mt-1">客服联系：support@kelu.example.com</p>
          </div>
        </div>
      </div>
    </div>
  );
}
