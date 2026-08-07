import { motion } from "motion/react";
import { ChevronLeft, ChevronRight, LogOut, UserX } from "lucide-react";
import { useAppStore } from "../store";

interface AccountSecurityPageProps {
  onBack: () => void;
}

export function AccountSecurityPage({ onBack }: AccountSecurityPageProps) {
  const { logout, pushView } = useAppStore();

  const handleLogout = () => {
    if (window.confirm("确认要退出登录吗？")) {
      logout();
    }
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
          onClick={onBack}
          className="absolute left-4 flex h-10 w-10 items-center justify-center rounded-full text-gray-900 transition-colors active:bg-gray-50"
        >
          <ChevronLeft size={24} />
        </button>
        <h1 className="text-[17px] font-bold text-gray-900">账号与安全</h1>
      </div>

      <div className="flex-1 overflow-y-auto p-5">
        <div className="rounded-[1.5rem] border border-gray-100 bg-white p-2 shadow-sm">
          <button
            onClick={handleLogout}
            className="flex w-full items-center justify-between border-b border-gray-50 px-4 py-4 text-left transition-colors active:bg-gray-50"
          >
            <div className="flex items-center">
              <div className="mr-3 flex h-9 w-9 items-center justify-center rounded-full bg-gray-50 text-gray-600">
                <LogOut size={18} />
              </div>
              <span className="text-[15px] font-bold text-gray-900">退出登录</span>
            </div>
            <ChevronRight size={18} className="text-gray-300" />
          </button>
          
          <button
            onClick={() => pushView("delete-account")}
            className="flex w-full items-center justify-between px-4 py-4 text-left transition-colors active:bg-gray-50"
          >
            <div className="flex items-center">
              <div className="mr-3 flex h-9 w-9 items-center justify-center rounded-full bg-red-50 text-red-500">
                <UserX size={18} />
              </div>
              <span className="text-[15px] font-bold text-red-500">注销账号</span>
            </div>
            <ChevronRight size={18} className="text-gray-300" />
          </button>
        </div>
      </div>
    </motion.div>
  );
}
