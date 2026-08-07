import { ChevronLeft, Info, FileText, Shield } from "lucide-react";
import { useAppStore } from "../../store";

export function AboutUs() {
  const { popView, pushView } = useAppStore();

  return (
    <div className="flex flex-col h-full bg-[#f8f9fa] absolute inset-0 z-50">
      <div className="px-5 pt-12 pb-4 flex items-center bg-white sticky top-0 z-10 border-b border-gray-100">
        <button onClick={popView} className="p-2 -ml-2 active:scale-95 transition-transform">
          <ChevronLeft size={24} className="text-gray-800" />
        </button>
        <h1 className="text-[17px] font-bold text-gray-900 ml-2">关于我们</h1>
      </div>

      <div className="flex-1 overflow-y-auto pb-8">
        <div className="flex flex-col items-center pt-12 pb-8">
          <div className="w-20 h-20 bg-gradient-to-br from-orange-50 to-orange-100 rounded-[1.5rem] flex items-center justify-center text-4xl shadow-[0_4px_20px_rgba(0,0,0,0.05)] border-2 border-white mb-4">
            🦌
          </div>
          <h2 className="text-[22px] font-black text-gray-900 tracking-tight">可鹿心理</h2>
          <p className="text-[13px] text-gray-500 mt-1 font-medium">版本 v1.0.0</p>
        </div>

        <div className="px-5 mt-2">
          <div className="bg-white rounded-[1.25rem] overflow-hidden shadow-[0_2px_10px_rgba(0,0,0,0.02)] border border-gray-50">
            <div 
              onClick={() => pushView("legal-document")}
              className="flex items-center justify-between p-4 border-b border-gray-50 active:bg-gray-50 cursor-pointer transition-colors"
            >
              <div className="flex items-center text-gray-700">
                <FileText size={18} className="mr-3 text-primary" />
                <span className="text-[15px] font-medium">用户协议</span>
              </div>
              <ChevronLeft size={18} className="text-gray-300 rotate-180" />
            </div>
            <div 
              onClick={() => pushView("legal-document")}
              className="flex items-center justify-between p-4 active:bg-gray-50 cursor-pointer transition-colors"
            >
              <div className="flex items-center text-gray-700">
                <Shield size={18} className="mr-3 text-primary" />
                <span className="text-[15px] font-medium">隐私政策</span>
              </div>
              <ChevronLeft size={18} className="text-gray-300 rotate-180" />
            </div>
          </div>
        </div>

        <div className="px-5 mt-6">
          <div className="bg-white rounded-[1.25rem] p-5 shadow-[0_2px_10px_rgba(0,0,0,0.02)] border border-gray-50">
            <h3 className="text-[14px] font-bold text-gray-900 mb-2">公司简介</h3>
            <p className="text-[13px] text-gray-600 leading-relaxed">
              可鹿心理致力于为用户提供专业、温暖的泛心理支持服务。通过 AI 情绪陪伴与专业心理咨询师的结合，帮助每一位用户找到适合自己的心理支持路径。
            </p>
          </div>
        </div>

        <div className="mt-12 flex flex-col items-center justify-center space-y-1">
          <p className="text-[11px] text-gray-400 font-medium">可鹿心理科技有限公司 版权所有</p>
          <p className="text-[11px] text-gray-400 font-medium">备案号：沪ICP备2026123456号-1</p>
          <p className="text-[11px] text-gray-400 font-medium">客服电话：400-123-4567</p>
        </div>
      </div>
    </div>
  );
}
