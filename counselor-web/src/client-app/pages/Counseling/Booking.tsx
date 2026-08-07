import { useState, useEffect } from "react";
import { motion } from "motion/react";
import { useAppStore } from "../../store";
import { ChevronLeft, CheckCircle2, X } from "lucide-react";
import { mockCounselors } from "../../data";
import { BookingOrder } from "../../types";

interface BookingProps {
  onClose?: () => void;
  key?: string;
}

export function Booking({ onClose }: BookingProps) {
  const { popView, pushView, selectedCounselorId, setBookingOrder } =
    useAppStore();
  const counselor =
    mockCounselors.find((c) => c.id === selectedCounselorId) ||
    mockCounselors[0];

  const initialDate =
    counselor.schedules.find((s) => !s.isFull)?.date ||
    counselor.schedules[0].date;
  const [selectedDate, setSelectedDate] = useState(initialDate);
  const [selectedMethod, setSelectedMethod] = useState<"text" | "voice" | "video">(
    "voice",
  );
  const [selectedTime, setSelectedTime] = useState("");

  const currentSchedule = counselor.schedules.find(
    (s) => s.date === selectedDate,
  );

  // Helper to format time as a 50-minute range
  const formatTimeRange = (startTime: string) => {
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

  // Reset time when date changes
  useEffect(() => {
    setSelectedTime("");
  }, [selectedDate]);

  const handleConfirm = () => {
    if (!selectedTime) return;

    // Set draft booking order to store so BookingConfirm page can use it
    const draftOrder = {
      id: `temp_${Date.now()}`,
      counselorId: counselor.id,
      date: selectedDate,
      time: selectedTime,
      type: selectedMethod,
      price: selectedMethod === "text" ? 199 : 500,
      status: "draft",
    };
    
    setBookingOrder(draftOrder);
    
    if (onClose) onClose();
    pushView("booking-confirm");
  };

  return (
    <>
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        exit={{ opacity: 0 }}
        onClick={() => (onClose ? onClose() : popView())}
        className="absolute inset-0 bg-black/50 z-40"
      />
      <motion.div
        initial={{ y: "100%" }}
        animate={{ y: 0 }}
        exit={{ y: "100%" }}
        transition={{ type: "spring", damping: 25, stiffness: 200 }}
        className="flex flex-col bg-white absolute bottom-0 left-0 right-0 z-50 rounded-t-[1.5rem] overflow-hidden"
        style={{ height: '85vh' }}
      >
        <div className="pt-4 pb-4 px-4 bg-white sticky top-0 z-10 flex items-center border-b border-gray-50">
          <h1 className="text-[17px] font-bold flex-1 text-center pl-10 text-gray-900">
            选择预约时间
          </h1>
          <button
            onClick={() => (onClose ? onClose() : popView())}
            className="ml-3 p-2 rounded-full active:bg-gray-100"
          >
            <X size={24} className="text-gray-900" />
          </button>
        </div>

      <div className="flex-1 overflow-y-auto pb-32">
        <div className="p-5">
          <h2 className="text-[15px] font-bold mb-4 flex items-center text-gray-900">
            <span className="w-1 h-3.5 bg-primary rounded-full mr-2"></span>
            选择日期
          </h2>

          {/* Scrollable Date Strip */}
          <div className="flex space-x-3 overflow-x-auto pb-2 mb-6 scrollbar-hide -mx-5 px-5">
            {counselor.schedules.map((schedule) => (
              <button
                key={schedule.date}
                onClick={() =>
                  !schedule.isFull && setSelectedDate(schedule.date)
                }
                disabled={schedule.isFull}
                className={`flex-shrink-0 w-[4.5rem] py-3 rounded-2xl border-2 transition-colors flex flex-col items-center justify-center ${
                  selectedDate === schedule.date
                    ? "border-gray-900 bg-gray-900 text-white shadow-md"
                    : schedule.isFull
                      ? "border-transparent bg-gray-50 text-gray-400 opacity-60 cursor-not-allowed"
                      : "border-gray-100 bg-white text-gray-600 hover:border-gray-200"
                }`}
              >
                <span
                  className={`text-[11px] mb-1 font-medium ${selectedDate === schedule.date ? "text-gray-300" : "text-gray-400"}`}
                >
                  {schedule.label}
                </span>
                <span
                  className={`text-[15px] font-bold tracking-tighter ${schedule.isFull ? "line-through" : ""}`}
                >
                  {schedule.date}
                </span>
                {schedule.isFull && (
                  <span className="text-[9px] mt-1 text-gray-400 font-bold">
                    已满
                  </span>
                )}
              </button>
            ))}
          </div>

          <h2 className="text-[15px] font-bold mb-4 flex items-center text-gray-900">
            <span className="w-1 h-3.5 bg-primary rounded-full mr-2"></span>
            选择时段
          </h2>

          <div className="grid grid-cols-2 gap-3 mb-8">
            {currentSchedule?.times.map((time) => {
              const timeRange = formatTimeRange(time);
              return (
                <button
                  key={time}
                  onClick={() => setSelectedTime(time)}
                  className={`py-4 px-3 rounded-[1.5rem] border-2 transition-transform active:scale-[0.98] flex items-center justify-center space-x-2 relative ${
                    selectedTime === time
                      ? "border-primary bg-primary-light/50 text-primary font-bold shadow-sm"
                      : "border-gray-100 text-gray-700 bg-white hover:border-gray-200 font-medium"
                  }`}
                >
                  <span className="text-[15px] tracking-tight whitespace-nowrap">{timeRange}</span>
                  {selectedTime === time && (
                    <CheckCircle2 size={18} className="text-primary fall-in absolute right-3" />
                  )}
                </button>
              );
            })}
            {currentSchedule?.times.length === 0 && (
              <div className="col-span-2 py-8 text-center text-gray-400 text-sm bg-gray-50 rounded-3xl border border-dashed border-gray-200">
                该日期暂无可约时间
              </div>
            )}
          </div>

          <h2 className="text-[15px] font-bold mb-4 flex items-center text-gray-900">
            <span className="w-1 h-3.5 bg-primary rounded-full mr-2"></span>
            选择咨询方式
          </h2>
          <div className="flex flex-col space-y-3">
            <button
              onClick={() => setSelectedMethod("text")}
              className={`p-4 rounded-2xl border-2 transition-all flex items-center justify-between ${
                selectedMethod === "text"
                  ? "border-primary bg-primary-light/30 shadow-sm"
                  : "border-gray-100 bg-white hover:border-gray-200"
              }`}
            >
              <div className="flex flex-col items-start">
                <span
                  className={`font-bold text-[14px] mb-1 flex items-center ${selectedMethod === "text" ? "text-primary" : "text-gray-900"}`}
                >
                  <span className="mr-1.5">💬</span> 文字沟通
                </span>
                <span className="text-[11px] text-gray-500">
                  随时留言，陪伴引导
                </span>
              </div>
              <span className={`font-bold ${selectedMethod === "text" ? "text-primary" : "text-gray-900"}`}>
                ¥{counselor.price}
              </span>
            </button>
            <button
              onClick={() => setSelectedMethod("voice")}
              className={`p-4 rounded-2xl border-2 transition-all flex items-center justify-between ${
                selectedMethod === "voice"
                  ? "border-primary bg-primary-light/30 shadow-sm"
                  : "border-gray-100 bg-white hover:border-gray-200"
              }`}
            >
              <div className="flex flex-col items-start">
                <span
                  className={`font-bold text-[14px] mb-1 flex items-center ${selectedMethod === "voice" ? "text-primary" : "text-gray-900"}`}
                >
                  <span className="mr-1.5">🎙️</span> 语音咨询
                </span>
                <span className="text-[11px] text-gray-500">
                  注重倾听，50分钟
                </span>
              </div>
              <span className={`font-bold ${selectedMethod === "voice" ? "text-primary" : "text-gray-900"}`}>
                ¥{counselor.price}
              </span>
            </button>
            <button
              onClick={() => setSelectedMethod("video")}
              className={`p-4 rounded-2xl border-2 transition-all flex items-center justify-between ${
                selectedMethod === "video"
                  ? "border-primary bg-primary-light/30 shadow-sm"
                  : "border-gray-100 bg-white hover:border-gray-200"
              }`}
            >
              <div className="flex flex-col items-start">
                <span
                  className={`font-bold text-[14px] mb-1 flex items-center ${selectedMethod === "video" ? "text-primary" : "text-gray-900"}`}
                >
                  <span className="mr-1.5">📹</span> 视频咨询
                </span>
                <span className="text-[11px] text-gray-500">
                  面对面深度交流，50分钟
                </span>
              </div>
              <span className={`font-bold ${selectedMethod === "video" ? "text-primary" : "text-gray-900"}`}>
                ¥{counselor.price}
              </span>
            </button>
          </div>
        </div>
      </div>

      <div className="absolute bottom-0 left-0 right-0 p-5 bg-white border-t border-gray-100 shadow-[0_-10px_40px_rgba(0,0,0,0.03)]">
        <div className="flex justify-between items-end mb-4 px-1">
          <div>
            <span className="text-[13px] text-gray-500 font-medium">
              合计金额
            </span>
            <div className="text-gray-400 text-[11px] mt-0.5">
              {selectedMethod === "video"
                ? "视频咨询 50分钟"
                : selectedMethod === "voice"
                  ? "语音咨询 50分钟"
                  : "文字沟通 (按次/周期)"}
            </div>
          </div>
          <div className="flex items-end">
              <span className="text-sm font-bold text-gray-900 mr-0.5">¥</span>
              <span className="text-[26px] font-bold text-gray-900 leading-none">
                {counselor.price}
              </span>
            </div>
        </div>
        <button
          onClick={handleConfirm}
          disabled={!selectedTime}
          className={`w-full font-bold py-4 rounded-full transition-all flex justify-center items-center shadow-md ${
            selectedTime
              ? "bg-gray-900 text-white active:bg-gray-800 shadow-gray-900/20"
              : "bg-gray-100 text-gray-400 shadow-none"
          }`}
        >
          {selectedTime ? "确认预约，去支付" : "请先选择时间"}
        </button>
      </div>
    </motion.div>
    </>
  );
}
