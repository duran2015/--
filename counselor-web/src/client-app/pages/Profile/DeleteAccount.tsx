import { useState, useEffect } from "react";
import { motion } from "motion/react";
import { ChevronLeft, AlertCircle, Loader2 } from "lucide-react";
import { useAppStore } from "../../store";

export function DeleteAccount() {
  const { popView, deleteAccount } = useAppStore();
  const [code, setCode] = useState("");
  const [countdown, setCountdown] = useState(0);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (countdown > 0) {
      const timer = window.setTimeout(() => setCountdown(countdown - 1), 1000);
      return () => window.clearTimeout(timer);
    }
  }, [countdown]);

  const handleSendCode = () => {
    if (countdown > 0) return;
    setCountdown(60);
  };

  const handleDelete = () => {
    if (code.length !== 6) return;
    setLoading(true);
    setTimeout(() => {
      setLoading(false);
      deleteAccount();
    }, 1000);
  };

  return (
    <motion.div
      initial={{ x: "100%" }}
      animate={{ x: 0 }}
      exit={{ x: "100%" }}
      transition={{ type: "spring", damping: 25, stiffness: 200 }}
      className="absolute inset-0 z-50 flex h-full flex-col overflow-hidden bg-[#f8f9fa]"
    >
      <div className="sticky top-0 z-20 flex items-center justify-center bg-white px-4 pb-4 pt-14 shadow-sm">
        <button
          onClick={popView}
          className="absolute left-4 flex h-10 w-10 items-center justify-center rounded-full text-gray-900 transition-colors active:bg-gray-50"
        >
          <ChevronLeft size={24} />
        </button>
        <h1 className="text-[17px] font-bold text-gray-900">注销账号</h1>
      </div>

      <div className="flex-1 overflow-y-auto p-5">
        <div className="mb-6 rounded-2xl bg-red-50 p-4 text-left">
          <div className="mb-2 flex items-center text-red-500">
            <AlertCircle size={18} className="mr-2" />
            <h3 className="text-[15px] font-bold">注销账号风险确认</h3>
          </div>
          <p className="text-[13px] leading-relaxed text-red-500/80">
            注销后将清空您的所有本地账号信息、会话记录与订单数据，且无法恢复。为了您的账号安全，需验证当前绑定的手机号。
          </p>
        </div>

        <div className="rounded-[1.5rem] border border-gray-100 bg-white p-5 shadow-sm">
          <h3 className="mb-1 text-[15px] font-bold text-gray-900">验证手机号</h3>
          <p className="mb-5 text-[12px] text-gray-500">
            已绑定手机号：188****8888
          </p>

          <div className="mb-6 flex items-center space-x-3">
            <input
              type="text"
              maxLength={6}
              value={code}
              onChange={(e) => setCode(e.target.value.replace(/\D/g, ""))}
              placeholder="请输入 6 位短信验证码"
              className="flex-1 rounded-xl bg-gray-50 p-3.5 text-[15px] font-medium text-gray-900 placeholder-gray-400 outline-none transition-all focus:bg-primary/5 focus:ring-1 focus:ring-primary/30"
            />
            <button
              onClick={handleSendCode}
              disabled={countdown > 0}
              className="whitespace-nowrap rounded-xl bg-gray-900 px-4 py-3.5 text-[13px] font-bold text-white transition-colors active:bg-gray-800 disabled:bg-gray-100 disabled:text-gray-400"
            >
              {countdown > 0 ? `${countdown}s 后重新获取` : "获取验证码"}
            </button>
          </div>

          <button
            onClick={handleDelete}
            disabled={code.length !== 6 || loading}
            className="flex w-full items-center justify-center rounded-full bg-red-500 py-4 text-[15px] font-bold text-white transition-colors active:bg-red-600 disabled:bg-gray-200 disabled:text-gray-400"
          >
            {loading && <Loader2 size={18} className="mr-2 animate-spin" />}
            验证并注销
          </button>
        </div>
      </div>
    </motion.div>
  );
}