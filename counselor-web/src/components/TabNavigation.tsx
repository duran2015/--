import React from 'react';
import { LayoutDashboard, Calendar, MessageCircle, TrendingUp, UserCheck } from 'lucide-react';

export type MainTabType = 'workbench' | 'schedule' | 'messages' | 'growth' | 'profile';

interface TabNavigationProps {
  activeTab: MainTabType;
  onChangeTab: (tab: MainTabType) => void;
  pendingSummaryCount: number;
  pendingOrderCount: number;
}

export const TabNavigation: React.FC<TabNavigationProps> = ({
  activeTab,
  onChangeTab,
  pendingSummaryCount,
  pendingOrderCount,
}) => {
  const tabs = [
    {
      id: 'workbench' as MainTabType,
      label: '工作台',
      icon: LayoutDashboard,
      badge: pendingSummaryCount > 0 ? pendingSummaryCount : undefined,
    },
    {
      id: 'schedule' as MainTabType,
      label: '预约',
      icon: Calendar,
      badge: pendingOrderCount > 0 ? pendingOrderCount : undefined,
    },
    {
      id: 'messages' as MainTabType,
      label: '消息',
      icon: MessageCircle,
      badge: undefined,
    },
    {
      id: 'growth' as MainTabType,
      label: '增长',
      icon: TrendingUp,
      badge: undefined,
    },
    {
      id: 'profile' as MainTabType,
      label: '我的',
      icon: UserCheck,
      badge: undefined,
    },
  ];

  return (
    <nav className="fixed bottom-0 left-0 right-0 z-40 bg-[#FAF8F5] border-t border-[#E6E0D6] px-2 py-2 flex items-center justify-around shadow-sm pb-safe">
      <div className="max-w-md w-full mx-auto flex items-center justify-around">
        {tabs.map((tab) => {
          const Icon = tab.icon;
          const isActive = activeTab === tab.id;
          return (
            <button
              key={tab.id}
              onClick={() => onChangeTab(tab.id)}
              className="flex flex-col items-center justify-center py-1 px-3 min-w-[68px] relative group focus:outline-hidden"
            >
              {/* M3 Active Indicator Pill */}
              <div
                className={`w-14 h-8 rounded-full flex items-center justify-center transition-all duration-200 ${
                  isActive
                    ? 'bg-[#EADDFF] text-[#21005D]'
                    : 'text-[#49463D] hover:bg-[#EAE5DB]'
                }`}
              >
                <Icon className={`w-5 h-5 ${isActive ? 'stroke-[2.5px]' : 'stroke-2'}`} />

                {/* M3 Badge */}
                {tab.badge !== undefined && (
                  <span className="absolute -top-0.5 right-3 min-w-[18px] h-4 px-1 rounded-full bg-[#B3261E] text-white text-[10px] font-bold font-mono flex items-center justify-center shadow-xs">
                    {tab.badge}
                  </span>
                )}
              </div>

              {/* M3 Label */}
              <span
                className={`text-[11px] font-sans mt-1 tracking-tight transition-colors ${
                  isActive ? 'text-[#21005D] font-bold' : 'text-[#7A756C] font-medium'
                }`}
              >
                {tab.label}
              </span>
            </button>
          );
        })}
      </div>
    </nav>
  );
};

