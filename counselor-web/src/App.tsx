import React, { useState } from 'react';
import { Navbar } from './components/Navbar';
import { TabNavigation, MainTabType } from './components/TabNavigation';
import { NextSessionCard } from './components/Workbench/NextSessionCard';
import { WorkbenchTasks } from './components/Workbench/WorkbenchTasks';
import { ScheduleTab } from './components/Schedule/ScheduleTab';
import { OrdersTab } from './components/Orders/OrdersTab';
import { OrderInfoModal } from './components/Orders/OrderInfoModal';
import { GrowthTab } from './components/Growth/GrowthTab';
import { ProfileTab } from './components/Profile/ProfileTab';
import { VoiceCall } from './client-app/pages/Counseling/VoiceCall';
import { SessionReviewWorkspace } from './components/SessionReview/SessionReviewWorkspace';
import { OnboardingFlow } from './components/Onboarding/OnboardingFlow';

import { ChatDrawer } from './components/IM/ChatDrawer';

import { INITIAL_CONSULTANT, INITIAL_SERVICE_PRODUCTS, INITIAL_SETTLEMENTS, INITIAL_VIRAL_VOUCHERS } from './data/mockData';
import { useAppStore } from './client-app/store';
import { Order, ServiceProduct, ViralVoucher, ConsultantProfile, SessionSnapshot } from './types';
import { IncomeView } from './components/Profile/IncomeView';
import { X, ChevronRight } from 'lucide-react';
import { CounselorNotificationCenter } from './components/Notifications/CounselorNotificationCenter';

export default function App() {
  const {
    orders,
    consultationWorkflow,
    ensureSessionReview,
    endConsultationSession,
    completeIntakeReview,
    confirmConsultationBooking,
  } = useAppStore();
  const setOrders = (updater: any) => {
    // Adapter for legacy setOrders
    if (typeof updater === 'function') {
      const nextOrders = updater(orders);
      useAppStore.getState().setOrders(nextOrders);
    } else {
      useAppStore.getState().setOrders(updater);
    }
  };

  const [consultant, setConsultant] = useState(INITIAL_CONSULTANT);
  const [products, setProducts] = useState<ServiceProduct[]>(INITIAL_SERVICE_PRODUCTS);
  const [settlements] = useState(INITIAL_SETTLEMENTS);
  const [vouchers, setVouchers] = useState<ViralVoucher[]>(INITIAL_VIRAL_VOUCHERS);

  const [activeTab, setActiveTab] = useState<MainTabType>('workbench');
  const [isSubPage, setIsSubPage] = useState<boolean>(false);
  const [mockState, setMockState] = useState<'demo' | 'empty' | 'unonboarded'>('demo');

  const isOnboarded = mockState !== 'unonboarded';
  const isMockEmpty = mockState === 'empty';

  const [hasConfiguredSchedule, setHasConfiguredSchedule] = useState(false);
  const [initialProfileSection, setInitialProfileSection] = useState<'menu' | 'schedule_settings'>('menu');

  React.useEffect(() => {
    if (mockState === 'empty') setHasConfiguredSchedule(false);
    else if (mockState === 'demo') setHasConfiguredSchedule(true);
  }, [mockState]);

  // Reset isSubPage when tab changes
  React.useEffect(() => {
    setIsSubPage(false);
    if (activeTab !== 'profile') {
      setInitialProfileSection('menu');
    }
  }, [activeTab]);

  // Modals & Drawers
  const [activeLiveOrder, setActiveLiveOrder] = useState<Order | null>(null);
  const [activeSessionReviewId, setActiveSessionReviewId] = useState<string | null>(null);
  const [showOrderInfo, setShowOrderInfo] = useState<Order | null>(null);
  const [activeChatOrder, setActiveChatOrder] = useState<Order | null>(null);
  const [activeOrderDetail, setActiveOrderDetail] = useState<Order | null>(null);
  const [activeOrderViewMode, setActiveOrderViewMode] = useState<'order_detail' | 'client_profile'>('order_detail');
  const [activeOrderReturnTab, setActiveOrderReturnTab] = useState<MainTabType | null>(null);
  const [showIncomeView, setShowIncomeView] = useState(false);
  const [showNotifications, setShowNotifications] = useState(false);

  const displayedOrders = isMockEmpty ? [] : orders;
  const displayedProducts = isMockEmpty ? [] : products;
  const displayedConsultant = isMockEmpty ? {
    ...consultant,
    income: 0,
    walletBalance: 0,
    completionRate: 40,
    servicesCount: 0,
    totalHours: 0,
    totalClients: 0,
    rating: 5.0,
    earnings: {
      withdrawable: 0,
      monthlySettled: 0,
      totalEarned: 0,
      commissionRate: 12
    }
  } : consultant;

  // Helper counts
  const pendingSummaryCount = displayedOrders.filter((o) => o.status === 'completed' && !o.hasSummary).length;
  const pendingOrderCount = displayedOrders.filter((o) => o.status === 'pending_confirm' || o.status === 'pending_reschedule_confirm' || o.status === 'pending_cancel_confirm').length;

  // Next upcoming session
  const nextScheduledOrder = displayedOrders.find((o) => o.status === 'scheduled');

  // Action Handlers
  const handleToggleListening = () => {
    setConsultant((prev) => ({ ...prev, isListeningActive: !prev.isListeningActive }));
  };

  const getUserAppUrl = (hash: 'home' | 'login') => {
    const host = window.location.hostname || 'localhost';
    if (host === 'localhost' || host === '127.0.0.1') {
      return `${window.location.protocol}//${host}:4312/#/${hash}`;
    }
    return `${window.location.protocol}//${host}/client/#/${hash}`;
  };

  const handleSwitchToUser = () => {
    window.location.assign(getUserAppUrl('home'));
  };

  const handleCounselorLogout = () => {
    window.localStorage.removeItem('isLoggedIn');
    window.localStorage.removeItem('appMode');
    window.location.assign(getUserAppUrl('login'));
  };

  const handleConfirmOrder = (orderId: string) => {
    confirmConsultationBooking(orderId);
    alert('已成功确认接单，已为您安排入班提醒！');
  };

  const handleWriteSummary = (order: Order) => {
    setActiveSessionReviewId(ensureSessionReview(order));
  };

  const handleSendReminder = (order: Order) => {
    alert(`已为【${order.clientName}】发送微信及短信【极简咨询室入室提醒】！`);
  };

  const handleSessionEnded = (order: Order, snapshot: SessionSnapshot) => {
    const draftId = endConsultationSession(order, snapshot);
    setActiveLiveOrder(null);
    setActiveSessionReviewId(draftId);
  };

  const handleUpdateConsultant = (updated: ConsultantProfile) => {
    setConsultant(updated);
  };

  const handleToggleProductPublish = (productId: string) => {
    setProducts((prev) =>
      prev.map((p) => (p.id === productId ? { ...p, isPublished: !p.isPublished } : p))
    );
  };

  const handleAddVoucher = (voucher: ViralVoucher) => {
    setVouchers((prev) => [voucher, ...prev]);
  };

  const handleProcessOrder = (order: Order, viewMode: 'order_detail' | 'client_profile' = 'order_detail') => {
    setActiveOrderReturnTab(activeTab);
    setActiveOrderDetail(order);
    setActiveOrderViewMode(viewMode);
    setActiveTab('messages'); // Forces OrdersTab to mount and process the activeOrderDetail
  };

  const handleExitExternalView = () => {
    if (activeOrderReturnTab) {
      setActiveTab(activeOrderReturnTab);
    } else {
      setActiveTab('workbench');
    }
    setActiveOrderDetail(null);
    setActiveOrderReturnTab(null);
  };

  if (!isOnboarded) {
    return (
      <div className="relative mx-auto h-[100dvh] w-full max-w-md overflow-hidden bg-[#FAF8F5]">
        <OnboardingFlow onComplete={() => setMockState('empty')} />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-[#EAE5DB] text-[#1D1B16] font-sans flex flex-col items-center justify-start p-0 sm:p-2 md:p-4">
      
      {/* Dev Toggle for State */}
      <div className="fixed top-4 right-4 z-[100] flex gap-1">
        <button 
          onClick={() => setMockState(mockState === 'demo' ? 'empty' : 'demo')} 
          className="bg-black/50 hover:bg-black/70 text-white text-[10px] px-2 py-1 rounded shadow-md transition"
        >
          Dev: {mockState === 'demo' ? '切换为新用户' : '切换为老用户(Demo)'}
        </button>
        <button 
          onClick={() => setMockState('unonboarded')} 
          className="bg-black/50 hover:bg-black/70 text-white text-[10px] px-2 py-1 rounded shadow-md transition"
        >
          重置入驻
        </button>
      </div>

      {/* Main Container Wrapper */}
      <div className="w-full max-w-md bg-[#FAF8F5] min-h-screen sm:min-h-[840px] sm:rounded-[28px] sm:border sm:border-[#ECE6DC] shadow-xl overflow-hidden flex flex-col relative">
        
        {/* Top App Navbar - Only shown on Workbench (首页) tab per user design */}
        {activeTab === 'workbench' && (
          <Navbar
            consultant={displayedConsultant}
            onToggleListening={handleToggleListening}
            onOpenLiveSession={() => {
              const target = nextScheduledOrder || displayedOrders[0];
              if (target) setActiveLiveOrder(target);
            }}
            onOpenNotifications={() => setShowNotifications(true)}
          />
        )}

        {/* Main View Area */}
        <main className="flex-1 px-4 py-3 pb-24 overflow-y-auto space-y-4 scrollbar-none">
          
          {/* TAB 1: WORKBENCH (工作台) */}
          {activeTab === 'workbench' && (
            <div className="space-y-4">
              
              {/* Overview Hero Card - M3 Style */}
              <div className="bg-[#EADDFF] rounded-[28px] p-6 text-[#21005D] shadow-sm relative overflow-hidden">
                <div className="absolute top-0 right-0 w-32 h-32 bg-white/20 rounded-full blur-2xl -mr-10 -mt-10" />
                <div className="flex justify-between items-center mb-6 relative z-10">
                  <h2 className="font-bold text-[16px] tracking-tight">今日概况</h2>
                  <div className="w-6 h-6 flex items-center justify-center bg-[#D0BCFF] text-[#21005D] rounded-full">
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><path d="M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.39a2 2 0 0 0-.73-2.73l-.15-.08a2 2 0 0 1-1-1.74v-.5a2 2 0 0 1 1-1.74l.15-.09a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2z"></path><circle cx="12" cy="12" r="3"></circle></svg>
                  </div>
                </div>
                <div className="flex justify-between items-end relative z-10">
                  <div className="flex gap-8">
                    <div>
                      <div className="text-[12px] opacity-80 mb-1 font-medium">今日预约</div>
                      <div className="flex items-baseline gap-1">
                        <span className="text-3xl font-bold font-mono tracking-tight">{isMockEmpty ? '0' : '3'}</span>
                        <span className="text-[13px] font-medium">人</span>
                      </div>
                      <div className="text-[11px] bg-[#D0BCFF] px-2 py-0.5 rounded-md mt-1 inline-block font-medium">{isMockEmpty ? '暂无' : '待确认'}</div>
                    </div>
                    <div>
                      <div className="text-[12px] opacity-80 mb-1 font-medium">今晨无</div>
                      <div className="flex items-baseline gap-1">
                        <span className="text-3xl font-bold font-mono tracking-tight">{isMockEmpty ? '0' : '1'}</span>
                        <span className="text-[13px] font-medium">个</span>
                      </div>
                      <div className="text-[11px] opacity-80 mt-1.5 font-medium">{isMockEmpty ? '-' : '已结束'}</div>
                    </div>
                  </div>
                  <div className="text-right">
                    <div className="text-[12px] opacity-80 mb-1 font-medium">今日收入 (元)</div>
                    <div className="flex items-baseline justify-end gap-1">
                      <span className="text-3xl font-bold font-mono tracking-tight">{isMockEmpty ? '¥0' : '¥600'}</span>
                    </div>
                    <div className="text-[11px] font-bold text-[#6750A4] mt-1.5 flex items-center justify-end gap-1">
                      <span className="bg-[#FEF7FF] px-2 py-0.5 rounded-md flex items-center gap-1">
                        {isMockEmpty ? '无昨日数据' : '较昨日 +12.5%'}
                        {!isMockEmpty && <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><polyline points="23 6 13.5 15.5 8.5 10.5 1 18"></polyline><polyline points="17 6 23 6 23 12"></polyline></svg>}
                      </span>
                    </div>
                  </div>
                </div>
              </div>

              {/* Actionable Workbench Tasks */}
              <WorkbenchTasks
                orders={displayedOrders}
                onConfirmOrder={handleConfirmOrder}
                onEnterRoom={(order) => setActiveLiveOrder(order)}
                onWriteSummary={handleWriteSummary}
                onSendReminder={handleSendReminder}
                onOpenChat={(order) => setActiveChatOrder(order)}
                onProcessOrder={handleProcessOrder}
              />

              {/* Quick Actions */}
              <div className="bg-white border border-[#E6E0D6] rounded-[28px] p-6 shadow-sm">
                <div className="flex items-center justify-between mb-5">
                  <h3 className="font-bold text-[16px] text-[#1D1B16] tracking-tight">快捷入口</h3>
                  <div className="w-8 h-8 rounded-full bg-[#FAF8F5] flex items-center justify-center hover:bg-[#EAE5DB] transition cursor-pointer">
                    <ChevronRight className="w-4 h-4 text-[#7A756C]" />
                  </div>
                </div>
                <div className="grid grid-cols-4 gap-2 text-center">
                  <button className="flex flex-col items-center gap-2 group">
                    <div className="w-14 h-14 rounded-[20px] bg-[#EADDFF] flex items-center justify-center text-[#4F378B] group-active:scale-95 transition">
                      <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path><polyline points="22 4 12 14.01 9 11.01"></polyline></svg>
                    </div>
                    <span className="text-[12px] text-[#49463D] font-bold">开始咨询</span>
                  </button>
                  <button onClick={() => setActiveTab('schedule')} className="flex flex-col items-center gap-2 group">
                    <div className="w-14 h-14 rounded-[20px] bg-[#D3E3FD] flex items-center justify-center text-[#0842A0] group-active:scale-95 transition">
                      <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect><line x1="16" y1="2" x2="16" y2="6"></line><line x1="8" y1="2" x2="8" y2="6"></line><line x1="3" y1="10" x2="21" y2="10"></line></svg>
                    </div>
                    <span className="text-[12px] text-[#49463D] font-bold">管理预约</span>
                  </button>
                  <button onClick={() => setActiveTab('growth')} className="flex flex-col items-center gap-2 group">
                    <div className="w-14 h-14 rounded-[20px] bg-[#FFDF99] flex items-center justify-center text-[#7A2E0E] group-active:scale-95 transition">
                      <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path><polyline points="14 2 14 8 20 8"></polyline><line x1="16" y1="13" x2="8" y2="13"></line><line x1="16" y1="17" x2="8" y2="17"></line><polyline points="10 9 9 9 8 9"></polyline></svg>
                    </div>
                    <span className="text-[12px] text-[#49463D] font-bold">发布内容</span>
                  </button>
                  <button className="flex flex-col items-center gap-2 group">
                    <div className="w-14 h-14 rounded-[20px] bg-[#D0BCFF] flex items-center justify-center text-[#132C0B] group-active:scale-95 transition">
                      <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"><path d="M16 21v-2a4 4 0 0 0-4-4H5.5"></path><circle cx="8.5" cy="7" r="4"></circle><line x1="20" y1="8" x2="20" y2="14"></line><line x1="23" y1="11" x2="17" y2="11"></line></svg>
                    </div>
                    <span className="text-[12px] text-[#49463D] font-bold">邀请客户</span>
                  </button>
                </div>
              </div>

            </div>
          )}

          {/* TAB 2: SCHEDULE (排班) */}
          {activeTab === 'schedule' && (
            <ScheduleTab
              consultant={displayedConsultant}
              products={displayedProducts}
              isMockEmpty={isMockEmpty}
              hasConfiguredSchedule={hasConfiguredSchedule}
              onSubPageChange={setIsSubPage}
              onNavigateToProfile={() => setActiveTab('profile')}
              onNavigateToScheduleSettings={() => {
                setInitialProfileSection('schedule_settings');
                setActiveTab('profile');
              }}
              onNavigateToGrowth={() => setActiveTab('growth')}
            />
          )}

          {/* TAB 3: MESSAGES (消息流) */}
          {activeTab === 'messages' && (
            <OrdersTab
              orders={displayedOrders}
              onConfirmOrder={handleConfirmOrder}
              onEnterRoom={(order) => setActiveLiveOrder(order)}
              onWriteSummary={handleWriteSummary}
              onSendReminder={handleSendReminder}
              onOpenChat={(order) => setActiveChatOrder(order)}
              onSubPageChange={setIsSubPage}
              onOpenOrderInfo={(order) => setShowOrderInfo(order)}
              initialSelectedOrder={activeOrderDetail}
              initialViewMode={activeOrderViewMode}
              onClearInitialOrder={() => setActiveOrderDetail(null)}
              onExitExternalView={handleExitExternalView}
              onNavigateToGrowth={() => setActiveTab('growth')}
            />
          )}

          {/* TAB 4: GROWTH (增长) */}
          {activeTab === 'growth' && (
            <GrowthTab
              consultant={displayedConsultant}
              vouchers={vouchers}
              onAddVoucher={handleAddVoucher}
              onSubPageChange={setIsSubPage}
              onNavigateToProfile={() => setActiveTab('profile')}
            />
          )}

          {/* TAB 5: PROFILE (我的) */}
          {activeTab === 'profile' && (
            <ProfileTab
              consultant={displayedConsultant}
              products={displayedProducts}
              settlements={settlements}
              initialSection={initialProfileSection}
              onToggleProductPublish={handleToggleProductPublish}
              onUpdateConsultant={handleUpdateConsultant}
              onSubPageChange={setIsSubPage}
              onProcessOrder={handleProcessOrder}
              onOpenOrderInfo={(order) => setShowOrderInfo(order)}
              onOpenIncomeView={() => setShowIncomeView(true)}
              onScheduleConfigured={() => setHasConfiguredSchedule(true)}
              onSwitchToUser={handleSwitchToUser}
              onLogout={handleCounselorLogout}
            />
          )}

        </main>

        {/* Mobile Bottom Navigation */}
        {!isSubPage && !showIncomeView && (
          <TabNavigation
            activeTab={activeTab}
            onChangeTab={setActiveTab}
            pendingSummaryCount={pendingSummaryCount}
            pendingOrderCount={pendingOrderCount}
          />
        )}

        {showIncomeView && (
          <IncomeView
            consultant={displayedConsultant}
            isMockEmpty={isMockEmpty}
            onClose={() => setShowIncomeView(false)}
            onOpenSessionReview={(draftId) => {
              setShowIncomeView(false);
              setActiveSessionReviewId(draftId);
            }}
            onOpenOrderInfo={(order) => setShowOrderInfo(order)}
          />
        )}

        {showNotifications && (
          <CounselorNotificationCenter
            onClose={() => setShowNotifications(false)}
          />
        )}

      </div>

      {/* MODAL 1: Minimalist Active Consultation Room */}
      {activeLiveOrder && (
        <VoiceCall 
          propOrder={activeLiveOrder} 
          propMode="counselor" 
          onClose={() => setActiveLiveOrder(null)}
          onSessionEnded={handleSessionEnded}
        />
      )}

      {/* MODAL 2: Session review workspace */}
      {activeSessionReviewId && (
        <SessionReviewWorkspace
          draftId={activeSessionReviewId}
          onClose={() => setActiveSessionReviewId(null)}
        />
      )}

      {/* MODAL 5: IM Chat Drawer */}
      {activeChatOrder && (
        <ChatDrawer 
          order={activeChatOrder}
          isOpen={!!activeChatOrder}
          onClose={() => setActiveChatOrder(null)}
          onViewClientProfile={(order) => handleProcessOrder(order, 'client_profile')}
          onOpenOrderInfo={(order) => setShowOrderInfo(order)}
          onOpenSessionReview={(draftId) => {
            setActiveChatOrder(null);
            setActiveSessionReviewId(draftId);
          }}
        />
      )}

      {showOrderInfo && (
        <OrderInfoModal 
          order={showOrderInfo} 
          onClose={() => setShowOrderInfo(null)}
          onConfirmOrder={handleConfirmOrder}
        />
      )}

    </div>
  );
}
