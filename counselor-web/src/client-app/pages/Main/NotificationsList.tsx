import { motion } from "motion/react";
import { useAppStore } from "../../store";
import { ChevronLeft, Bell, ChevronRight } from "lucide-react";
import { mockNotifications } from "../../data";
import { EmptyState } from "../../components/EmptyState";

export function NotificationsList() {
  const { popView, pushView, setSelectedNotificationId } = useAppStore();

  const handleSelect = (id: string) => {
    setSelectedNotificationId(id);
    pushView("notification-detail");
  };

  return (
    <motion.div
      initial={{ x: "100%" }}
      animate={{ x: 0 }}
      exit={{ x: "100%" }}
      transition={{ type: "spring", damping: 25, stiffness: 200 }}
      className="flex flex-col h-full bg-[#f4f5f7] absolute inset-0 z-50 overflow-hidden"
    >
      <div className="pt-14 pb-3 px-4 bg-white sticky top-0 z-20 flex items-center shadow-sm border-b border-gray-100">
        <button
          onClick={popView}
          className="w-10 h-10 -ml-2 flex items-center justify-center text-gray-900 border border-transparent active:bg-gray-50 rounded-full transition-colors"
        >
          <ChevronLeft size={24} />
        </button>
        <div className="ml-2 flex items-center">
          <div className="w-8 h-8 rounded-full bg-blue-500 flex items-center justify-center text-white mr-2">
            <Bell size={16} />
          </div>
          <div>
            <h1 className="text-[15px] font-bold text-gray-900 leading-tight">
              系统通知
            </h1>
            <div className="text-[10px] text-gray-500 bg-white/50 px-2 py-0.5 rounded-full inline-block backdrop-blur-sm shadow-sm border border-gray-100">
              官方服务号
            </div>
          </div>
        </div>
      </div>

      <div className="flex-1 overflow-y-auto p-4 space-y-6">
        {mockNotifications.length === 0 ? (
          <EmptyState icon={Bell} title="通知都看完啦" description="预约提醒、测评结果和服务进度会第一时间出现在这里。" />
        ) : (
          <div className="space-y-6 pb-8">
            {mockNotifications.slice().reverse().map((notif) => (
              <div key={notif.id}>
                <div className="flex justify-center mb-3">
                  <span className="text-[11px] text-gray-400 bg-gray-200/50 px-2 py-1 rounded-full">
                    {notif.date}
                  </span>
                </div>
                <div className="flex justify-start">
                  <div className="w-8 h-8 rounded-full bg-blue-500 flex items-center justify-center text-white shrink-0 mr-2 mt-1">
                    <Bell size={16} />
                  </div>
                  <div className="max-w-[78%]">
                    <div className="p-3.5 text-[14px] leading-relaxed shadow-sm rounded-2xl rounded-tl-sm bg-white border border-gray-100 text-gray-800">
                      <h4 className="font-bold mb-1.5 text-[15px]">{notif.title}</h4>
                      <p className="text-gray-500 text-[13px] mb-3">{notif.preview}</p>
                      <div 
                        className="pt-2.5 border-t border-gray-100 text-[13px] text-blue-500 flex items-center justify-between cursor-pointer active:opacity-70 transition-opacity"
                        onClick={() => handleSelect(notif.id)}
                      >
                        <span className="font-medium">查看详情</span>
                        <ChevronRight size={16} />
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
      
      {/* Bottom input area mock (disabled) */}
      <div className="bg-[#f4f5f7] border-t border-gray-200 p-3 pb-8">
        <div className="bg-white rounded-full h-10 flex items-center justify-center text-gray-400 text-[13px] border border-gray-200">
          系统通知暂不支持回复
        </div>
      </div>
    </motion.div>
  );
}
