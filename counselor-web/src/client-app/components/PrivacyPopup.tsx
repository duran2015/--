import { useState } from "react";
import { motion, AnimatePresence } from "motion/react";
import { Shield, CheckCircle2, Circle, ChevronLeft } from "lucide-react";
import { useAppStore } from "../store";

export function PrivacyPopup() {
  const { hasAgreedPrivacy, agreePrivacy } = useAppStore();
  const [checked, setChecked] = useState(false);
  const [showDocument, setShowDocument] = useState<null | "user" | "privacy">(null);
  const documentTitle = showDocument === "user"
    ? "用户协议"
    : showDocument === "privacy"
      ? "隐私政策"
      : "";

  if (hasAgreedPrivacy) return null;

  return (
    <AnimatePresence>
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        exit={{ opacity: 0 }}
        className="fixed inset-0 z-[100] bg-black/60 flex items-center justify-center p-6"
      >
        <motion.div
          initial={{ scale: 0.95, opacity: 0 }}
          animate={{ scale: 1, opacity: 1 }}
          exit={{ scale: 0.95, opacity: 0 }}
          className="bg-white rounded-[1.5rem] p-6 w-full max-w-sm shadow-2xl relative overflow-hidden"
        >
          <div className="flex justify-center mb-4">
            <div className="w-12 h-12 bg-primary/10 rounded-full flex items-center justify-center text-primary">
              <Shield size={24} />
            </div>
          </div>
          
          <h2 className="text-[18px] font-bold text-center text-gray-900 mb-4">
            服务协议与隐私政策
          </h2>
          
          <div className="text-[13px] text-gray-600 leading-relaxed space-y-3 mb-5 max-h-[34vh] overflow-y-auto pr-2">
            <p>
              欢迎使用「可鹿心理」。为了保障你的个人信息与使用权益，请在继续前阅读并理解《用户协议》和《隐私政策》。
            </p>
            <p>
              在你使用 AI 倾诉、心理测评、情绪记录和咨询预约等服务时，我们会收集必要的设备信息、网络信息，以及你主动提供的情绪和服务资料，并按照相关法律法规进行保护。
            </p>
            <p>
              未经你的明确同意，我们不会将 AI 沟通内容直接展示给咨询师；仅在你授权时同步结构化摘要用于咨询前准备。
            </p>
          </div>

          <div className="rounded-2xl bg-gray-50 px-4 py-3 mb-5">
            <div className="flex items-start gap-2">
              <button
                onClick={() => setChecked((value: boolean) => !value)}
                className="mt-0.5 shrink-0"
              >
                {checked ? (
                  <CheckCircle2 size={18} className="text-primary" />
                ) : (
                  <Circle size={18} className="text-gray-300" />
                )}
              </button>
              <div className="text-[12px] leading-5 text-gray-600">
                我已阅读并同意
                <button
                  onClick={() => setShowDocument("user")}
                  className="px-0.5 font-semibold text-primary"
                >
                  《用户协议》
                </button>
                和
                <button
                  onClick={() => setShowDocument("privacy")}
                  className="px-0.5 font-semibold text-primary"
                >
                  《隐私政策》
                </button>
              </div>
            </div>
          </div>

          <div className="flex flex-col space-y-3">
            <button
              onClick={() => {
                if (!checked) return;
                agreePrivacy();
              }}
              className={`w-full py-3.5 rounded-full font-bold text-[15px] transition-transform ${
                checked
                  ? "bg-primary text-white shadow-[0_4px_15px_rgba(92,110,153,0.2)] active:scale-[0.98]"
                  : "bg-gray-100 text-gray-400"
              }`}
            >
              同意并继续
            </button>
            <button
              onClick={() => {
                alert("你可以先阅读协议内容；如暂不同意，将无法继续使用当前服务。");
              }}
              className="w-full py-3.5 bg-gray-50 text-gray-500 rounded-full font-medium text-[15px] active:scale-[0.98] transition-transform"
            >
              暂不同意
            </button>
          </div>

          <AnimatePresence>
            {showDocument && (
              <motion.div
                initial={{ opacity: 0, x: 16 }}
                animate={{ opacity: 1, x: 0 }}
                exit={{ opacity: 0, x: 16 }}
                className="absolute inset-0 bg-white z-10 flex flex-col"
              >
                <div className="flex items-center px-4 pt-5 pb-4 border-b border-gray-100">
                  <button
                    onClick={() => setShowDocument(null)}
                    className="p-1 -ml-1 text-gray-700"
                  >
                    <ChevronLeft size={20} />
                  </button>
                  <h3 className="ml-2 text-[16px] font-bold text-gray-900">
                    {documentTitle}
                  </h3>
                </div>
                <div className="flex-1 overflow-y-auto px-4 py-4 text-[13px] leading-6 text-gray-600">
                  {showDocument === "user" ? (
                    <>
                      <p className="font-semibold text-gray-900 mb-3">用户协议摘要</p>
                      <p className="mb-3">欢迎使用可鹿心理。你在注册、登录和使用服务前，应充分阅读并理解平台的服务边界、账号规则、内容规范及风险提示。</p>
                      <p className="mb-3">平台提供 AI 倾诉、情绪记录、心理测评和咨询预约等服务，不提供医学诊断，也不替代精神科诊疗、心理治疗或紧急危机干预。</p>
                      <p>当你继续使用服务时，表示你同意遵守平台规则，并理解相关服务边界与风险提示。</p>
                    </>
                  ) : (
                    <>
                      <p className="font-semibold text-gray-900 mb-3">隐私政策摘要</p>
                      <p className="mb-3">为了向你提供基础登录、内容记录、咨询预约与服务衔接功能，我们会收集必要的设备信息、网络信息，以及你主动填写或输入的服务资料。</p>
                      <p className="mb-3">你的 AI 沟通内容不会未经授权直接提供给咨询师；只有在你主动确认后，平台才会同步结构化摘要，用于本次咨询准备。</p>
                      <p>你可以在设置页查看完整政策入口，也可以通过账号与安全管理个人资料与账号状态。</p>
                    </>
                  )}
                </div>
              </motion.div>
            )}
          </AnimatePresence>
        </motion.div>
      </motion.div>
    </AnimatePresence>
  );
}
