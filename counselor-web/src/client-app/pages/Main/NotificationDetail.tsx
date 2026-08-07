import { motion } from "motion/react";
import { useAppStore } from "../../store";
import { ChevronLeft } from "lucide-react";
import { mockNotifications } from "../../data";

export function NotificationDetail() {
  const { popView, selectedNotificationId } = useAppStore();

  const notification = mockNotifications.find(n => n.id === selectedNotificationId) || mockNotifications[0];

  return (
    <motion.div
      initial={{ x: "100%" }}
      animate={{ x: 0 }}
      exit={{ x: "100%" }}
      transition={{ type: "spring", damping: 25, stiffness: 200 }}
      className="flex flex-col h-full bg-white absolute inset-0 z-50 overflow-hidden"
    >
      <div className="pt-14 pb-4 px-4 bg-white sticky top-0 z-20 flex items-center shadow-sm">
        <button
          onClick={popView}
          className="w-10 h-10 -ml-2 flex items-center justify-center text-gray-900 border border-transparent active:bg-gray-50 rounded-full transition-colors"
        >
          <ChevronLeft size={24} />
        </button>
        <h1 className="text-[17px] font-bold text-gray-900 ml-2">
          通知详情
        </h1>
      </div>

      <div className="flex-1 overflow-y-auto p-6">
        <h2 className="text-[20px] font-bold text-gray-900 mb-2 leading-snug">
          {notification.title}
        </h2>
        <div className="text-[12px] text-gray-400 mb-6 pb-4 border-b border-gray-100">
          {notification.date}
        </div>
        
        <div className="text-[15px] text-gray-700 leading-relaxed whitespace-pre-wrap">
          {notification.content}
        </div>
      </div>
    </motion.div>
  );
}