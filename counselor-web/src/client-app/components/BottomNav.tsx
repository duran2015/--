import { useAppStore } from "../store";
import { Home, MessageCircle, MessageSquare, User, HeartHandshake } from "lucide-react";
import { motion } from "motion/react";
import { getClientPrimaryTabs } from "../../clientNavigation";

export function BottomNav() {
  const { currentTab, setTab, pushView } = useAppStore();

  const icons = { home: Home, ai: MessageCircle, counselors: HeartHandshake, messages: MessageSquare, profile: User };
  const userTabs = getClientPrimaryTabs().map((tab) => ({ ...tab, icon: icons[tab.id] }));

  return (
    <nav className="w-full shrink-0 h-[80px] bg-[#FAF8F5] border-t border-[#ECE6DC] flex px-1 items-center justify-around z-30 pb-safe">
      {userTabs.map((tab) => {
        const Icon = tab.icon;
        const isActive = currentTab === tab.id;
        return (
          <button
            key={tab.id}
            onClick={() => {
              if (tab.id === "ai") {
                pushView("ai-chat");
              } else {
                setTab(tab.id as any);
              }
            }}
            className="flex flex-col items-center justify-center flex-1 min-w-0 py-2 group"
          >
            <div className="relative flex items-center justify-center w-14 h-8 mb-1 transition-colors z-10">
              {isActive && (
                <motion.div
                  layoutId="client-nav-indicator"
                  className="absolute inset-0 bg-[#EADDFF] rounded-full -z-10"
                  transition={{ type: "spring", stiffness: 300, damping: 25 }}
                />
              )}
              <Icon 
                strokeWidth={isActive ? 2.5 : 2} 
                size={24} 
                className={isActive ? "text-[#21005D]" : "text-[#49463D] group-hover:text-[#1D1B16] transition-colors"} 
              />
            </div>
            <span
              className={`text-[12px] font-medium transition-colors ${
                isActive ? "text-[#1D1B16] font-bold" : "text-[#49463D]"
              }`}
            >
              {tab.label}
            </span>
          </button>
        );
      })}
    </nav>
  );
}
