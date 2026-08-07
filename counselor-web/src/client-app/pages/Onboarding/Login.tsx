import { useState, useRef, useEffect, type ClipboardEvent, type KeyboardEvent } from "react";
import { motion, AnimatePresence } from "motion/react";
import { useAppStore } from "../../store";
import { Loader2, CheckCircle2, Circle, ArrowLeft, Apple, AlertCircle, Briefcase, User } from "lucide-react";

export function Login() {
  const { pushView, updateUser, enterAppMode, hasAgreedPrivacy } = useAppStore();
  const [step, setStep] = useState<"phone" | "code" | "bind-phone" | "role-select">("phone");
  const [phone, setPhone] = useState("");
  const [code, setCode] = useState(["", "", "", ""]);
  const [loading, setLoading] = useState(false);
  const [agreed, setAgreed] = useState(hasAgreedPrivacy);
  const [error, setError] = useState(false);
  const [codeError, setCodeError] = useState(false);
  
  // Track if this is a third-party login flow
  const [thirdPartyProvider, setThirdPartyProvider] = useState<false | "wechat" | "apple">(false);

  const inputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    if (step === "phone" || step === "bind-phone") {
      inputRef.current?.focus();
    } else if (step === "code") {
      document.getElementById("code-0")?.focus();
    }
  }, [step]);

  useEffect(() => {
    if (hasAgreedPrivacy) {
      setAgreed(true);
    }
  }, [hasAgreedPrivacy]);

  const handleNext = () => {
    if (!agreed) {
      setError(true);
      setTimeout(() => setError(false), 2000);
      return;
    }
    if (phone.length !== 11) return;

    setLoading(true);
    setTimeout(() => {
      setLoading(false);
      setStep("code");
    }, 800);
  };

  const handleKeyDown = (idx: number, e: KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'Backspace' && !code[idx] && idx > 0) {
      const prevInput = document.getElementById(`code-${idx - 1}`);
      prevInput?.focus();
    }
  };

  const handlePaste = (e: ClipboardEvent<HTMLInputElement>) => {
    e.preventDefault();
    const pastedData = e.clipboardData.getData('text').replace(/\D/g, '').slice(0, 4);
    if (!pastedData) return;

    const newCode = [...code];
    for (let i = 0; i < pastedData.length; i++) {
       newCode[i] = pastedData[i];
    }
    setCode(newCode);
    setCodeError(false);

    if (pastedData.length < 4) {
       document.getElementById(`code-${pastedData.length}`)?.focus();
    } else {
       document.getElementById(`code-3`)?.focus();
       verifyCode(newCode.join(""));
    }
  };

  const handleCodeChange = (idx: number, val: string) => {
    if (!/^\d*$/.test(val)) return;
    setCodeError(false);

    const newCode = [...code];
    newCode[idx] = val;
    setCode(newCode);

    if (val && idx < 3) {
      const nextInput = document.getElementById(`code-${idx + 1}`);
      nextInput?.focus();
    } 
    
    if (newCode.every((c) => c !== "")) {
      verifyCode(newCode.join(""));
    }
  };

  const verifyCode = (fullCode: string) => {
    setLoading(true);
    setTimeout(() => {
      setLoading(false);
      
      // Simulate error code logic (e.g., 0000 means error)
      if (fullCode === "0000") {
        setCodeError(true);
        setCode(["", "", "", ""]);
        document.getElementById(`code-0`)?.focus();
        return;
      }

      // 模拟后端逻辑：识别特定手机号为已开通的咨询师账号
      if (phone === "18888888888") {
        console.log("[Event Analytics] Dual-role user authenticated via Phone & OTP");
        updateUser({ role: "active", name: "双重身份测试账号", isNewUser: false });
        setStep("role-select");
        return;
      }

      updateUser({ role: "registered", isNewUser: true });
      
      if (thirdPartyProvider) {
        console.log("[Event Analytics] User authenticated via Third Party + Phone Binding");
        updateUser({ name: thirdPartyProvider === "wechat" ? "微信用户" : "Apple 授权用户", avatar: "https://ui-avatars.com/api/?name=User&background=random" });
        pushView("assessment");
      } else {
        console.log("[Event Analytics] User authenticated via Phone & OTP");
        pushView("assessment");
      }
    }, 1000);
  };

  const handleThirdParty = (provider: "wechat" | "apple") => {
    if (!agreed) {
      setError(true);
      setTimeout(() => setError(false), 2000);
      return;
    }
    setLoading(true);
    setTimeout(() => {
      setLoading(false);
      setThirdPartyProvider(provider);
      setStep("bind-phone");
    }, 800);
  };

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      className="flex flex-col h-full bg-transparent absolute inset-0 z-50 px-7 pb-7 overflow-hidden before:absolute before:w-64 before:h-64 before:rounded-full before:bg-primary/8 before:-top-32 before:-right-28 before:blur-2xl before:pointer-events-none"
    >
      <div className="pt-10 mb-8 min-h-[40px] relative z-10">
        {(step === "code" || step === "bind-phone" || step === "role-select") && (
          <button
            onClick={() => {
              if (step === "code") {
                setStep(thirdPartyProvider ? "bind-phone" : "phone");
              } else if (step === "bind-phone") {
                setThirdPartyProvider(false);
                setStep("phone");
              } else if (step === "role-select") {
                // 退出登录，回到输入手机号
                setStep("phone");
                setPhone("");
                setCode(["", "", "", ""]);
              }
            }}
            className="p-2 -ml-2 rounded-full active:bg-gray-100 transition-colors"
          >
            <ArrowLeft size={24} className="text-gray-900" />
          </button>
        )}
      </div>

      <div className="flex-1 flex flex-col">
        <AnimatePresence mode="wait">
          {step === "role-select" ? (
            <motion.div
              key="role-select"
              initial={{ opacity: 0, x: 20 }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: -20 }}
              className="flex-1 flex flex-col pt-10"
            >
              <div className="mb-10 text-center">
                <h2 className="text-2xl font-bold text-gray-900">请选择您的身份</h2>
                <p className="text-gray-500 mt-2">您拥有双重身份，请选择本次需要使用的身份</p>
              </div>
              <div className="space-y-4">
                <button
                  onClick={() => enterAppMode("counselor")}
                  className="w-full p-6 border-2 border-primary/20 rounded-2xl flex items-center space-x-4 hover:border-primary hover:bg-primary/5 transition-all text-left"
                >
                  <div className="w-12 h-12 bg-primary/10 rounded-full flex items-center justify-center text-primary">
                    <Briefcase size={24} />
                  </div>
                  <div>
                    <h3 className="font-bold text-gray-900 text-lg">我是咨询师</h3>
                    <p className="text-gray-500 text-sm">处理订单、管理日程与服务</p>
                  </div>
                </button>
                <button
                  onClick={() => enterAppMode("user")}
                  className="w-full p-6 border-2 border-gray-100 rounded-2xl flex items-center space-x-4 hover:border-primary/50 hover:bg-gray-50 transition-all text-left"
                >
                  <div className="w-12 h-12 bg-gray-100 rounded-full flex items-center justify-center text-gray-600">
                    <User size={24} />
                  </div>
                  <div>
                    <h3 className="font-bold text-gray-900 text-lg">我是用户</h3>
                    <p className="text-gray-500 text-sm">寻找咨询师、体验小鹿陪伴</p>
                  </div>
                </button>
              </div>
            </motion.div>
          ) : step === "phone" ? (
            <motion.div
              key="phone"
              initial={{ opacity: 0, x: -20 }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: -20 }}
              className="flex-1 flex flex-col relative z-10"
            >
              <div className="mb-10 text-center">
                <div className="w-[72px] h-[72px] bg-gradient-to-br from-primary-light to-[#fff1dc] rounded-[24px] flex items-center justify-center text-primary mx-auto mb-5 shadow-[0_16px_36px_rgba(50,116,92,0.13)] border border-white">
                  <svg
                    width="32"
                    height="32"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    strokeWidth="2"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                  >
                    <path d="M20.42 4.58a5.4 5.4 0 0 0-7.65 0l-.77.78-.77-.78a5.4 5.4 0 0 0-7.65 0C1.46 6.7 1.33 10.28 4 13l8 8 8-8c2.67-2.72 2.54-6.3.42-8.42z"></path>
                  </svg>
                </div>
                <h1 className="text-[28px] font-black text-gray-900 tracking-tight">
                  欢迎来到可鹿
                </h1>
                <p className="text-gray-500 text-sm mt-2.5 tracking-wide">
                  在这里，听见自己的声音
                </p>
              </div>

              <div className="flex items-center bg-white/80 border border-white shadow-[0_10px_30px_rgba(33,53,46,0.06)] rounded-[18px] px-4 py-4 mb-5">
                <span className="text-gray-900 font-medium mr-4 border-r pr-4">
                  +86
                </span>
                <input
                  ref={inputRef}
                  type="tel"
                  maxLength={11}
                  value={phone}
                  onChange={(e) => setPhone(e.target.value.replace(/\D/g, ""))}
                  placeholder="请输入手机号"
                  className="flex-1 bg-transparent outline-none text-lg font-semibold text-gray-900 placeholder-gray-300 w-full"
                />
              </div>

              <button
                onClick={handleNext}
                className={`w-full py-4 rounded-[18px] font-bold flex justify-center items-center space-x-2 transition-all ${phone.length === 11 ? "bg-primary text-white shadow-[0_12px_28px_rgba(50,116,92,0.22)] hover:bg-primary/90" : "bg-gray-100 text-gray-400"}`}
              >
                {loading && !thirdPartyProvider && <Loader2 size={18} className="animate-spin" />}
                <span>获取验证码</span>
              </button>
              
              <div className="mt-auto mb-6 flex flex-col items-center">
                <div className="flex items-center space-x-10 text-gray-500 mb-8">
                  <button
                    onClick={() => handleThirdParty("wechat")}
                    className="flex flex-col items-center space-y-2 active:scale-95 transition-transform"
                  >
                    <div className="w-12 h-12 bg-[#07C160]/10 rounded-full flex items-center justify-center text-[#07C160]">
                      <svg
                        width="24"
                        height="24"
                        viewBox="0 0 24 24"
                        fill="currentColor"
                      >
                        <path d="M8.28,14.65c-2.3,0-4.17-1.87-4.17-4.17s1.87-4.17,4.17-4.17c1.1,0,2.1.43,2.83,1.13l1.8-1.8c-1.2-1.14-2.84-1.84-4.63-1.84C3.71,3.8,0,7.51,0,12.08s3.71,8.28,8.28,8.28c1.37,0,2.66-.33,3.8-.91l-1.55-2.27C9.77,14.47,9.05,14.65,8.28,14.65Zm7.8-8.12V3.79H14.16v2.74H11.41v1.92h2.75V11.2h1.92V8.45h2.75V6.53Z" />
                      </svg>
                    </div>
                    <span className="text-xs">微信登录</span>
                  </button>
                  <button
                    onClick={() => handleThirdParty("apple")}
                    className="flex flex-col items-center space-y-2 active:scale-95 transition-transform"
                  >
                    <div className="w-12 h-12 bg-black rounded-full flex items-center justify-center text-white">
                      <Apple size={22} className="fill-current" />
                    </div>
                    <span className="text-xs">Apple 登录</span>
                  </button>
                </div>

                <div
                  className={`flex items-start space-x-2 text-xs transition-colors w-full ${error ? "animate-pulse" : ""}`}
                >
                  <button
                    type="button"
                    aria-label="同意服务协议与隐私政策"
                    aria-pressed={agreed}
                    onClick={() => setAgreed(!agreed)}
                    className="mt-0.5 shrink-0"
                  >
                    {agreed ? (
                      <CheckCircle2 size={16} className="text-primary" />
                    ) : (
                      <Circle
                        size={16}
                        className={error ? "text-red-500" : "text-gray-300"}
                      />
                    )}
                  </button>
                  <span
                    className={`text-left leading-relaxed ${error ? "text-red-500 font-medium" : "text-gray-500"}`}
                  >
                    我已阅读并同意
                    <button
                      type="button"
                      onClick={() => pushView("legal-document")}
                      className="text-primary px-0.5"
                    >
                      《可鹿用户服务协议》
                    </button>
                    与
                    <button
                      type="button"
                      onClick={() => pushView("legal-document")}
                      className="text-primary px-0.5"
                    >
                      《隐私政策》
                    </button>
                    ， 未注册手机号通过验证后将自动注册
                  </span>
                </div>
              </div>
            </motion.div>
          ) : step === "bind-phone" ? (
            <motion.div
              key="bind-phone"
              initial={{ opacity: 0, x: 20 }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: -20 }}
              className="flex-1 flex flex-col"
            >
              <div className="mb-10">
                <h1 className="text-2xl font-bold text-gray-900 mb-2">
                  绑定手机号
                </h1>
                <p className="text-gray-500 text-sm">
                  应国家网络安全相关法律法规要求，继续使用需绑定您的真实手机号。
                </p>
              </div>
              
              <div className="flex items-center space-x-3 mb-8 p-3 bg-gray-50 rounded-2xl border border-gray-100">
                 <img src="https://api.dicebear.com/7.x/avataaars/svg?seed=Felix" alt="wechat avatar" className="w-10 h-10 rounded-full" />
                 <div>
                    <div className="text-sm font-bold text-gray-900">微信用户</div>
                    <div className="text-[10px] text-gray-500">已授权获取基础信息</div>
                 </div>
              </div>

              <div className="flex items-center border-b border-gray-200 py-3 mb-8">
                <span className="text-gray-900 font-medium mr-4 border-r pr-4">
                  +86
                </span>
                <input
                  ref={inputRef}
                  type="tel"
                  maxLength={11}
                  value={phone}
                  onChange={(e) => setPhone(e.target.value.replace(/\D/g, ""))}
                  placeholder="请输入手机号"
                  className="flex-1 bg-transparent outline-none text-xl font-medium text-gray-900 placeholder-gray-300 w-full"
                />
              </div>

              <button
                onClick={handleNext}
                className={`w-full py-4 rounded-full font-medium flex justify-center items-center space-x-2 transition-all ${phone.length === 11 ? "bg-primary text-white shadow-md shadow-primary/20 hover:bg-primary/90" : "bg-gray-100 text-gray-400"}`}
              >
                {loading && <Loader2 size={18} className="animate-spin" />}
                <span>获取验证码</span>
              </button>
            </motion.div>
          ) : (
            <motion.div
              key="code"
              initial={{ opacity: 0, x: 20 }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: 20 }}
              className="flex-1"
            >
              <h1 className="text-2xl font-bold text-gray-900 mb-2">
                输入验证码
              </h1>
              <p className="text-gray-500 text-sm mb-10">
                验证码已发送至 +86 {phone.substring(0, 3)}****
                {phone.substring(7)}
                {thirdPartyProvider && "，验证后即完成绑定"}
              </p>

              <div className="flex justify-between space-x-2 mb-6">
                {code.map((digit, idx) => (
                  <input
                    key={idx}
                    id={`code-${idx}`}
                    type="tel"
                    maxLength={1}
                    value={digit}
                    onChange={(e) => handleCodeChange(idx, e.target.value)}
                    onKeyDown={(e) => handleKeyDown(idx, e)}
                    onPaste={handlePaste}
                    className={`w-[20%] aspect-square bg-surface border rounded-2xl text-center text-3xl font-bold outline-none transition-colors ${codeError ? "border-red-500 bg-red-50 text-red-500" : "border-gray-200 focus:border-primary focus:bg-primary-light/10"}`}
                  />
                ))}
              </div>
              
              {codeError && (
                 <motion.div 
                   initial={{ opacity: 0, y: -10 }}
                   animate={{ opacity: 1, y: 0 }}
                   className="flex items-center justify-center text-red-500 text-sm font-medium mb-6"
                 >
                   <AlertCircle size={16} className="mr-1.5" /> 验证码错误，请重新输入（输入0000会报错）
                 </motion.div>
              )}

              <div className="text-center">
                {loading ? (
                  <span className="flex items-center justify-center space-x-2 text-primary font-medium text-sm">
                    <Loader2 size={16} className="animate-spin" />
                    <span>验证中...</span>
                  </span>
                ) : (
                  <button 
                    onClick={() => {
                        setPhone("");
                        setCode(["", "", "", ""]);
                        setCodeError(false);
                        setStep(thirdPartyProvider ? "bind-phone" : "phone");
                    }}
                    className="text-sm text-gray-400 active:text-gray-600 transition-colors mt-4"
                  >
                    接收不到验证码？<span className="text-primary ml-1">重新获取</span>
                  </button>
                )}
              </div>
            </motion.div>
          )}
        </AnimatePresence>
      </div>
    </motion.div>
  );
}
