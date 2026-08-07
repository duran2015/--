import { useState } from "react";
import { motion } from "motion/react";
import { useAppStore } from "../../store";
import {
  ArrowLeft,
  CheckCircle2,
  Smartphone,
  ShieldCheck,
  FileText,
  ShoppingBag,
} from "lucide-react";
import { mockCounselors } from "../../data";
import { MissingDataPage } from "../../components/EmptyState";

export function Payment() {
  const {
    popView,
    pushView,
    resetToView,
    bookingOrder,
    setBookingOrder,
    addOrder,
    orders,
    updateOrder,
  } = useAppStore();
  const [status, setStatus] = useState<"checkout" | "success">("checkout");
  const [paymentMethod, setPaymentMethod] = useState<"wechat" | "alipay">(
    "wechat",
  );

  const counselor = mockCounselors.find(
    (c) => c.id === bookingOrder?.counselorId,
  );

  // Helper to format time as a 50-minute range
  const formatTimeRange = (startTime: string) => {
    if (!startTime || !startTime.includes(':')) return startTime;
    const [hourStr, minStr] = startTime.split(':');
    let hour = parseInt(hourStr, 10);
    let min = parseInt(minStr, 10);

    min += 50;
    if (min >= 60) {
      hour += 1;
      min -= 60;
    }

    const endHour = hour.toString().padStart(2, '0');
    const endMin = min.toString().padStart(2, '0');

    return `${startTime}-${endHour}:${endMin}`;
  };

  const handlePay = () => {
    // 彻底跳过 loading，直接修改状态为 success
    setStatus("success");
    if (bookingOrder) {
      const updated = { 
        ...bookingOrder, 
        status: "pending_confirm", 
        id: `ord_${Date.now()}`,
        orderNo: `ORD${Date.now()}`,
        clientName: "新用户",
        clientAvatar: "https://ui-avatars.com/api/?name=User&background=random",
        serviceTypeName: bookingOrder.type === 'video' ? '50分钟标准视频咨询' : '50分钟标准语音咨询',
        bookingDate: bookingOrder.date,
        bookingTimeSlot: formatTimeRange(bookingOrder.time),
        createdAt: new Date().toISOString()
      };
      const existingOrder = orders.find((o: any) => o.id === bookingOrder.id);
      if (!existingOrder || bookingOrder.id.startsWith("temp_")) {
        // Ensure new orders appear first
        addOrder(updated);
      } else {
        updateOrder(bookingOrder.id, updated);
      }
      setBookingOrder(updated);
    }
  };

  const handleCancelOrder = () => {
    setBookingOrder(null);
    popView();
  };

  const handleRefund = () => {
    setBookingOrder(bookingOrder ? { ...bookingOrder, status: "refunded" } : null);
    resetToView("main");
  };

  if (!bookingOrder || !counselor) {
    return <MissingDataPage icon={ShoppingBag} title="订单信息已失效" description="可能是预约尚未完成，或订单已经被取消。返回后可以重新选择咨询师和服务时间。" onBack={popView} />;
  }

  return (
    <motion.div
      initial={{ x: "100%" }}
      animate={{ x: 0 }}
      exit={{ x: "100%" }}
      transition={{ type: "spring", damping: 25, stiffness: 200 }}
      className="flex flex-col h-full bg-surface absolute inset-0 z-50 overflow-hidden"
    >
      <div className="pt-14 pb-4 px-4 bg-white sticky top-0 z-10 flex items-center shadow-sm">
        {status === "checkout" && (
          <button
            onClick={handleCancelOrder}
            className="mr-3 p-2 rounded-full active:bg-gray-100"
          >
            <ArrowLeft size={24} className="text-gray-900" />
          </button>
        )}
        <h1 className="text-[17px] font-bold flex-1 text-center pr-10 text-gray-900">
          {status === "success" ? "支付成功" : "确认订单"}
        </h1>
      </div>

      {status === "success" ? (
        <motion.div
          key="success"
          initial={{ scale: 0.98, opacity: 0 }}
          animate={{ scale: 1, opacity: 1 }}
          className="flex-1 flex flex-col items-center justify-center p-6"
        >
          <div className="w-24 h-24 bg-green-50 rounded-full flex items-center justify-center mb-6">
            <CheckCircle2 className="text-primary w-12 h-12" />
          </div>
          <h2 className="text-2xl font-bold text-gray-900 mb-3">预约成功</h2>
          <p className="text-gray-500 text-sm leading-relaxed text-center mb-6 px-4">
            您已成功预约{" "}
            <span className="font-bold text-gray-700">{counselor.name}</span>
            <br />
            时间：{bookingOrder.date} {bookingOrder.type === "text" ? bookingOrder.time : formatTimeRange(bookingOrder.time)}
            <br />
            <span className="inline-block mt-4 text-[12px] bg-yellow-50 text-yellow-600 px-3 py-1 rounded-full">
              请提前 5 分钟进入咨询室准备
            </span>
          </p>
          
          <div className="bg-blue-50/50 border border-blue-100 rounded-xl p-4 mb-8 mx-4">
            <p className="text-[13px] text-gray-600 leading-relaxed text-center">
              正式咨询前，{counselor.name}的小助理可以先帮你整理这次想聊的问题，让咨询开始时更高效。
            </p>
          </div>

          <div className="w-full max-w-xs space-y-4">
            <button
              onClick={() => {
                // Set the current order context
                useAppStore.getState().setSelectedCounselorOrder(bookingOrder);
                resetToView("main");
                pushView("counseling-text-chat");
              }}
              className="w-full bg-gray-900 text-white font-bold py-4 rounded-full active:scale-95 transition-transform flex items-center justify-center shadow-md shadow-gray-900/20"
            >
              <FileText size={18} className="mr-2" /> 开始咨询前准备
            </button>
            <button
              onClick={() => resetToView("main")}
              className="w-full bg-gray-50 text-gray-700 font-bold py-4 rounded-full active:scale-95 transition-transform"
            >
              稍后再说
            </button>
          </div>

          <button
            onClick={handleRefund}
            className="mt-8 text-xs text-gray-400 underline underline-offset-2"
          >
            申请退单并取消预约
          </button>
        </motion.div>
      ) : (
        <div className="flex-1 overflow-y-auto pb-32">
          <div className="p-5">
            <div className="bg-white p-6 rounded-[2rem] shadow-sm border border-gray-100 mb-6">
              <div className="flex items-start space-x-4 pb-6 border-b border-gray-50 mb-6">
                <img
                  src={counselor.avatar}
                  alt=""
                  className="w-14 h-14 rounded-[1.25rem] object-cover shadow-sm shrink-0"
                />
                <div className="flex-1">
                  <div className="flex items-center justify-between mb-1">
                    <p className="font-bold text-gray-900 text-[16px]">{counselor.name}</p>
                    <div className="flex items-center text-[11px] font-medium text-gray-500 bg-gray-50 px-2 py-0.5 rounded-full border border-gray-100">
                      累计服务 {counselor.serviceHours || (counselor.type === "pro" ? 5000 : 1000)}+ 小时
                    </div>
                  </div>
                  <div className="flex items-center gap-1.5 flex-wrap mt-2">
                    {counselor.specialties?.slice(0, 1).map((spec, i) => (
                      <span key={`spec-${i}`} className="text-[10px] bg-blue-50 text-blue-600 border border-blue-100/50 px-1.5 py-0.5 rounded font-medium mb-1">
                        擅长: {spec}
                      </span>
                    ))}
                    {counselor.styles?.slice(0, 1).map((style, i) => (
                      <span key={`style-${i}`} className="text-[10px] bg-purple-50 text-purple-600 border border-purple-100/50 px-1.5 py-0.5 rounded font-medium mb-1">
                        风格: {style}
                      </span>
                    ))}
                    {counselor.credentials?.slice(0, 1).map((cred, i) => (
                      <span key={`cred-${i}`} className="text-[10px] bg-amber-50 text-amber-600 border border-amber-100/50 px-1.5 py-0.5 rounded font-medium mb-1">
                        资质: {cred}
                      </span>
                    ))}
                  </div>
                </div>
              </div>

              <div className="space-y-4 text-[14px]">
                <div className="flex justify-between">
                  <span className="text-gray-500">咨询方式</span>
                  <span className="font-medium text-gray-900">
                    {bookingOrder.type === "text"
                      ? "文字沟通"
                      : bookingOrder.type === "voice"
                        ? "语音咨询"
                        : "视频咨询"}
                  </span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-500">预约时间</span>
                  <span className="font-bold text-primary">
                    {bookingOrder.date} {bookingOrder.type === "text" ? bookingOrder.time : formatTimeRange(bookingOrder.time)}
                  </span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-500">支持时长</span>
                  <span className="font-medium text-gray-900">
                    {bookingOrder.type === "text"
                      ? "单次/周期回复"
                      : "50分钟"}
                  </span>
                </div>
              </div>
            </div>

            <h3 className="text-sm font-bold text-gray-900 mb-3 px-1 ml-1">
              支付方式
            </h3>
            <div className="bg-white rounded-[2rem] border border-gray-100 p-2 shadow-sm space-y-1">
              <button
                onClick={() => setPaymentMethod("wechat")}
                className={`w-full flex items-center justify-between p-4 rounded-[1.5rem] transition-colors ${paymentMethod === "wechat" ? "bg-green-50" : "bg-transparent"}`}
              >
                <div className="flex items-center space-x-3">
                  <div className="w-8 h-8 rounded-full bg-green-500 flex items-center justify-center text-white">
                    <ShieldCheck size={18} />
                  </div>
                  <span className="font-medium text-gray-900 text-[15px]">
                    微信支付
                  </span>
                </div>
                <div
                  className={`w-5 h-5 rounded-full border-2 flex items-center justify-center ${paymentMethod === "wechat" ? "border-green-500 bg-green-500" : "border-gray-300"}`}
                >
                  {paymentMethod === "wechat" && (
                    <div className="w-2.5 h-2.5 rounded-full bg-white"></div>
                  )}
                </div>
              </button>
              <button
                onClick={() => setPaymentMethod("alipay")}
                className={`w-full flex items-center justify-between p-4 rounded-[1.5rem] transition-colors ${paymentMethod === "alipay" ? "bg-blue-50" : "bg-transparent"}`}
              >
                <div className="flex items-center space-x-3">
                  <div className="w-8 h-8 rounded-full bg-blue-500 flex items-center justify-center text-white">
                    <Smartphone size={18} />
                  </div>
                  <span className="font-medium text-gray-900 text-[15px]">
                    支付宝
                  </span>
                </div>
                <div
                  className={`w-5 h-5 rounded-full border-2 flex items-center justify-center ${paymentMethod === "alipay" ? "border-blue-500 bg-blue-500" : "border-gray-300"}`}
                >
                  {paymentMethod === "alipay" && (
                    <div className="w-2.5 h-2.5 rounded-full bg-white"></div>
                  )}
                </div>
              </button>
            </div>
          </div>

          <div className="absolute bottom-0 left-0 right-0 p-5 bg-white border-t border-gray-100 shadow-[0_-10px_40px_rgba(0,0,0,0.03)] flex justify-between items-center">
            <div className="flex flex-col ml-2">
              <span className="text-[13px] text-gray-500 mb-0.5 font-medium">
                实付款
              </span>
              <div className="flex items-end">
                <span className="text-sm font-bold text-gray-900 mr-0.5">
                  ¥
                </span>
                <span className="text-2xl font-bold text-gray-900 leading-none">
                  {bookingOrder.price}
                </span>
              </div>
            </div>
            <div className="flex flex-col items-center">
              <button
                onClick={handlePay}
                className="w-[160px] bg-gray-900 text-white font-bold py-4 rounded-full active:bg-gray-800 transition-colors shadow-md shadow-gray-900/20 text-[15px] mb-1"
              >
                立即支付
              </button>
            </div>
          </div>
        </div>
      )}
    </motion.div>
  );
}
