import { motion } from "motion/react";
import {
  Settings,
  User,
  FileText,
  ChevronRight,
  CalendarClock,
  Briefcase,
  LogOut,
} from "lucide-react";
import { useAppStore } from "../../store";

export function ProfileTab() {
  const { pushView, enterAppMode, user } = useAppStore();

  const menuGroups = [
    {
      title: "我的心灵档案",
      items: [
        { icon: User, label: "心理画像", tag: "NEW" },
        { icon: FileText, label: "量表记录" },
      ],
    },
    {
      title: "预约与服务",
      items: [
        { icon: CalendarClock, label: "预约记录" },
        { icon: FileText, label: "小结与建议" },
      ],
    }
  ];

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0 }}
      className="p-5 pb-8 overflow-y-auto h-full"
    >
      <div className="pt-12 pb-6 flex items-center justify-between">
        <div className="flex items-center space-x-4">
          <div className="relative">
            <img
              src={user.avatar}
              alt="avatar"
              className="w-20 h-20 rounded-full border-4 border-white shadow-md object-cover"
            />
          </div>
          <div>
            <h1 className="text-2xl font-bold text-gray-900 mb-1 flex items-center">
              {user.name}
            </h1>
            <p className="text-gray-500 text-sm">在这里，关注最真实的自己</p>
          </div>
        </div>
        <button 
          onClick={() => pushView("profile-edit")}
          className="w-10 h-10 bg-white rounded-full flex items-center justify-center text-gray-500 shadow-sm border border-gray-100 active:scale-95 transition-transform"
        >
          <Settings size={20} />
        </button>
      </div>



      <div className="space-y-8 mt-4">
        {user.role === "active" && (
          <button 
            onClick={() => enterAppMode("counselor")}
            className="w-full flex items-center justify-between p-4 bg-white rounded-2xl shadow-sm border border-gray-100 active:scale-[0.98] transition-transform"
          >
            <div className="flex items-center space-x-3 text-primary">
              <div className="w-8 h-8 bg-primary/10 rounded-full flex items-center justify-center">
                <Briefcase size={18} />
              </div>
              <span className="font-bold text-[15px]">切换为咨询师身份</span>
            </div>
            <ChevronRight size={20} className="text-gray-300" />
          </button>
        )}

        {menuGroups.map((group, idx) => (
          <div key={idx} className="space-y-3">
            <h3 className="text-[14px] font-bold text-gray-900 flex items-center">
              <span className="w-1 h-3.5 bg-primary rounded-full mr-2"></span>
              {group.title}
            </h3>
            <div className="bg-white rounded-[1.5rem] border border-gray-100 shadow-[0_2px_10px_rgba(0,0,0,0.02)] overflow-hidden">
              {group.items.map((item, i) => {
                const Icon = item.icon;
                return (
                  <button
                    key={i}
                    onClick={() => {
                      if (item.label === "预约记录" || item.label === "订单管理") {
                        pushView("orders-list");
                      } else if (item.label === "咨询记录") {
                        pushView("consultation-records");
                      } else if (item.label === "心理画像") {
                        pushView("profile-report");
                      } else if (item.label === "量表记录") {
                        pushView("assessment-records");
                      } else if (item.label === "小结与建议") {
                        pushView("counseling-summary-list");
                      }
                    }}
                    className="w-full px-5 py-4 flex items-center justify-between active:bg-gray-50 transition-colors border-b border-gray-50 last:border-0 group"
                  >
                    <div className="flex items-center space-x-3 text-gray-800">
                      <div className="w-8 h-8 rounded-full bg-surface group-hover:bg-primary/10 flex items-center justify-center text-gray-500 group-hover:text-primary transition-colors">
                        <Icon size={18} />
                      </div>
                      <span className="font-medium text-[15px]">
                        {item.label}
                      </span>
                    </div>
                    <div className="flex items-center space-x-2 border-none">
                      {item.tag && (
                        <span className="bg-red-50 text-red-500 text-[10px] px-2 py-0.5 rounded-full font-bold">
                          {item.tag}
                        </span>
                      )}
                      <ChevronRight
                        size={18}
                        className="text-gray-300 group-hover:text-gray-400 transition-colors"
                      />
                    </div>
                  </button>
                );
              })}
            </div>
          </div>
        ))}
      </div>

      <div className="mt-8">
        <div className="space-y-3">
          <h3 className="text-[14px] font-bold text-gray-900 flex items-center">
            <span className="w-1 h-3.5 bg-primary rounded-full mr-2"></span>
            设置与关于
          </h3>
          <div className="bg-white rounded-[1.5rem] border border-gray-100 shadow-[0_2px_10px_rgba(0,0,0,0.02)] overflow-hidden">
            <button
              onClick={() => pushView("about-us" as any)}
              className="w-full px-5 py-4 flex items-center justify-between active:bg-gray-50 transition-colors border-b border-gray-50 group"
            >
              <div className="flex items-center space-x-3 text-gray-800">
                <div className="w-8 h-8 rounded-full bg-surface group-hover:bg-primary/10 flex items-center justify-center text-gray-500 group-hover:text-primary transition-colors">
                  <FileText size={18} />
                </div>
                <div className="text-left">
                  <p className="font-medium text-[15px] text-gray-900">关于我们</p>
                </div>
              </div>
              <ChevronRight
                size={18}
                className="text-gray-300 group-hover:text-gray-400 transition-colors"
              />
            </button>
            <button
              onClick={() => pushView("legal-document" as any)}
              className="w-full px-5 py-4 flex items-center justify-between active:bg-gray-50 transition-colors border-b border-gray-50 group"
            >
              <div className="flex items-center space-x-3 text-gray-800">
                <div className="w-8 h-8 rounded-full bg-surface group-hover:bg-primary/10 flex items-center justify-center text-gray-500 group-hover:text-primary transition-colors">
                  <FileText size={18} />
                </div>
                <div className="text-left">
                  <p className="font-medium text-[15px] text-gray-900">用户协议与隐私政策</p>
                </div>
              </div>
              <ChevronRight
                size={18}
                className="text-gray-300 group-hover:text-gray-400 transition-colors"
              />
            </button>
            <button
              onClick={() => pushView("account-security" as any)}
              className="w-full px-5 py-4 flex items-center justify-between active:bg-gray-50 transition-colors group"
            >
              <div className="flex items-center space-x-3 text-gray-800">
                <div className="w-8 h-8 rounded-full bg-surface group-hover:bg-primary/10 flex items-center justify-center text-gray-500 group-hover:text-primary transition-colors">
                  <LogOut size={18} />
                </div>
                <div className="text-left">
                  <p className="font-medium text-[15px] text-gray-900">账号与安全</p>
                  <p className="text-[12px] text-gray-500">退出登录、注销账号</p>
                </div>
              </div>
              <ChevronRight
                size={18}
                className="text-gray-300 group-hover:text-gray-400 transition-colors"
              />
            </button>
          </div>
        </div>
      </div>
    </motion.div>
  );
}
