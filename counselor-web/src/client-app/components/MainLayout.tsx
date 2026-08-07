import { ReactNode } from "react";
import { motion, AnimatePresence } from "motion/react";
import { useAppStore } from "../store";
import { BottomNav } from "./BottomNav";
import { HomeTab } from "../pages/Main/HomeTab";
import { MessagesTab } from "../pages/Main/MessagesTab";
import { AITab } from "../pages/Main/AITab";
import { ProfileTab } from "../pages/Main/ProfileTab";
import { OrdersList } from "../pages/Counseling/OrdersList";
import { CounselingEntrance } from "../pages/Counseling/CounselingEntrance";
import { Users, Wallet } from "lucide-react";

export function MainLayout() {
  const { currentTab, appMode } = useAppStore();

  return (
    <div className="flex-1 flex flex-col w-full h-full bg-[#FAF8F5]">
      <div className="flex-1 relative overflow-hidden flex flex-col isolate">
        <AnimatePresence mode="wait">
          {currentTab === "home" && <HomeTab key="home" />}
          {currentTab === "counseling" && <AITab key="counseling" />}
          {currentTab === "counselors" && <CounselingEntrance key="counselors" />}
          {currentTab === "messages" && <MessagesTab key="messages" />}
          {currentTab === "appointments" && <OrdersList key="appointments" />}
          {currentTab === "profile" && <ProfileTab key="profile" />}
        </AnimatePresence>
      </div>
      <BottomNav />
    </div>
  );
}
