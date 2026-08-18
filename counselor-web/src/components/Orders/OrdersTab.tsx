import React, { useState, useEffect } from 'react';
import { 
  Calendar, Clock, CheckCircle2, AlertCircle, 
  Video, FileText, ChevronRight, Sparkles, User,
  CreditCard, ShieldCheck, Heart, MessageSquare
} from 'lucide-react';
import { Order, OrderStatus, ClientProfile } from '../../types';
import { INITIAL_CLIENT_PROFILES } from '../../data/mockData';
import { OrderDetailView } from './OrderDetailView';
import { ClientProfileView } from './ClientProfileView';

interface OrdersTabProps {
  orders: Order[];
  onConfirmOrder: (orderId: string) => void;
  onEnterRoom: (order: Order) => void;
  onWriteSummary: (order: Order) => void;
  onSendReminder: (order: Order) => void;
  onOpenChat?: (order: Order) => void;
  onSubPageChange?: (isSubPage: boolean) => void;
  onOpenOrderInfo?: (order: Order) => void;
  initialSelectedOrder?: Order | null;
  initialViewMode?: 'order_detail' | 'client_profile';
  onClearInitialOrder?: () => void;
  onExitExternalView?: () => void;
  onNavigateToGrowth?: () => void;
}

export const OrdersTab: React.FC<OrdersTabProps> = ({
  orders,
  onConfirmOrder,
  onEnterRoom,
  onWriteSummary,
  onSendReminder,
  onOpenChat,
  onSubPageChange,
  onOpenOrderInfo,
  initialSelectedOrder,
  initialViewMode,
  onClearInitialOrder,
  onExitExternalView,
  onNavigateToGrowth,
}) => {
  const [activeStatus, setActiveStatus] = useState<string>('all');
  const [viewMode, setViewMode] = useState<'list' | 'order_detail' | 'client_profile'>('list');
  const [clientProfileSource, setClientProfileSource] = useState<'list' | 'order_detail' | 'external'>('list');
  const [orderDetailSource, setOrderDetailSource] = useState<'list' | 'external'>('list');
  const [selectedOrder, setSelectedOrder] = useState<Order | null>(null);
  const [selectedClient, setSelectedClient] = useState<{
    profile: ClientProfile;
    order?: Order;
  } | null>(null);

  useEffect(() => {
    if (initialSelectedOrder) {
      setSelectedOrder(initialSelectedOrder);
      if (initialViewMode === 'client_profile') {
        handleOpenClientProfile(initialSelectedOrder, 'external');
      } else {
        setOrderDetailSource('external');
        setViewMode('order_detail');
      }
      onClearInitialOrder?.();
    }
  }, [initialSelectedOrder, initialViewMode, onClearInitialOrder]);

  useEffect(() => {
    if (onSubPageChange) {
      onSubPageChange(viewMode !== 'list');
    }
  }, [viewMode, onSubPageChange]);

  const isPendingStatus = (status: OrderStatus) => 
    status === 'pending_reschedule_confirm' || status === 'pending_cancel_confirm';

  const statusTabs = [
    { key: 'all', label: '全部订单', count: orders.length },
    { key: 'pending', label: '待处理', count: orders.filter((o) => isPendingStatus(o.status)).length },
    { key: 'scheduled', label: '待咨询', count: orders.filter((o) => o.status === 'scheduled').length },
    { key: 'completed', label: '已完成', count: orders.filter((o) => o.status === 'completed').length },
    { key: 'refunded', label: '退款/售后', count: orders.filter((o) => o.status === 'refunded').length },
  ];

  const filteredOrders = orders.filter((order) => {
    if (activeStatus === 'all') return true;
    if (activeStatus === 'pending') return isPendingStatus(order.status);
    return order.status === activeStatus;
  });

  const getStatusBadge = (status: OrderStatus) => {
    switch (status) {
      case 'pending_confirm':
        return <span className="bg-[#EADDFF] text-[#21005D] text-[11px] px-2.5 py-0.5 rounded-full font-semibold border border-[#D0BCFF]">待咨询</span>;
      case 'pending_reschedule_confirm':
        return <span className="bg-amber-100 text-amber-900 text-[11px] px-2.5 py-0.5 rounded-full font-semibold border border-amber-300">待改期</span>;
      case 'pending_cancel_confirm':
        return <span className="bg-amber-100 text-amber-900 text-[11px] px-2.5 py-0.5 rounded-full font-semibold border border-amber-300">待取消</span>;
      case 'scheduled':
        return <span className="bg-[#EADDFF] text-[#21005D] text-[11px] px-2.5 py-0.5 rounded-full font-semibold border border-[#D0BCFF]">待咨询</span>;
      case 'in_progress':
        return <span className="bg-[#6750A4] text-white text-[11px] px-2.5 py-0.5 rounded-full font-semibold animate-pulse">服务中</span>;
      case 'completed':
        return <span className="bg-stone-100 text-[#7A756C] text-[11px] px-2.5 py-0.5 rounded-full font-semibold border border-[#ECE6DC]">已完成</span>;
      case 'refunded':
        return <span className="bg-rose-50 text-rose-700 text-[11px] px-2.5 py-0.5 rounded-full font-semibold border border-rose-200">退款/售后</span>;
      default:
        return <span className="bg-stone-100 text-stone-600 text-[11px] px-2.5 py-0.5 rounded-full">已取消</span>;
    }
  };

  const handleOpenClientProfile = (order: Order, source: 'list' | 'order_detail' | 'external' = 'list') => {
    const foundProfile = INITIAL_CLIENT_PROFILES[order.clientId] || {
      id: order.clientId || 'cli_default',
      name: order.clientName,
      avatar: order.clientAvatar,
      gender: '保密',
      age: 28,
      occupation: '来访者',
      city: '中国',
      phone: '138****0000',
      emergencyContact: { name: '紧急联系人', relation: '亲属', phone: '138****0000' },
      intakeDate: order.bookingDate,
      riskLevel: 'low',
      tags: ['心理咨询来访'],
      historySummary: {
        totalSessions: 1,
        attendanceRate: '100%',
        primaryGoals: ['情绪调节与表达'],
        counselorWorkingNotes: '初步建立安全接纳信任关系。'
      },
      sessionLogs: [],
      preSessionCheckIns: []
    };

    setSelectedClient({
      profile: foundProfile,
      order: order
    });
    setClientProfileSource(source);
    setViewMode('client_profile');
  };

  const handleOpenOrderDetail = (order: Order) => {
    setSelectedOrder(order);
    setOrderDetailSource('list');
    setViewMode('order_detail');
  };

  // Sub-view Page Render: Order Details Page
  if (viewMode === 'order_detail' && selectedOrder) {
    return (
      <OrderDetailView
        order={selectedOrder}
        onBack={() => {
          if (orderDetailSource === 'external') {
            // Restore previous tab state
            if (onExitExternalView) {
              onExitExternalView();
            } else {
              setViewMode('list');
              setSelectedOrder(null);
            }
          } else {
            setViewMode('list');
            setSelectedOrder(null);
          }
        }}
        onOpenClientProfile={(ord) => handleOpenClientProfile(ord, 'order_detail')}
        onConfirmOrder={onConfirmOrder}
        onEnterRoom={onEnterRoom}
        onWriteSummary={onWriteSummary}
            onOpenOrderInfo={(order) => onOpenOrderInfo?.(order)}
          />
    );
  }

  // Sub-view Page Render: Client Profile Page
  if (viewMode === 'client_profile' && selectedClient) {
    return (
      <ClientProfileView
        client={selectedClient.profile}
        relatedOrder={selectedClient.order}
        onBack={() => {
          if (clientProfileSource === 'order_detail' && selectedOrder) {
            setViewMode('order_detail');
          } else if (clientProfileSource === 'external') {
            setViewMode('list');
            setSelectedClient(null);
            setSelectedOrder(null);
            onExitExternalView?.();
          } else {
            setViewMode('list');
            setSelectedClient(null);
            setSelectedOrder(null);
          }
        }}
        onEnterRoom={onEnterRoom}
      />
    );
  }

  // Primary View Render: Service Thread List (Messages Style)
  return (
    <div className="space-y-3 animate-in fade-in duration-200">
      <div className="flex items-center justify-between pb-1">
        <h2 className="text-xl font-bold text-[#1D1B16]">进行中的服务流</h2>
      </div>

      {/* Filter Chips */}
      <div className="flex gap-2 overflow-x-auto pb-2 scrollbar-hide">
        {statusTabs.map((tab) => (
          <button
            key={tab.key}
            onClick={() => setActiveStatus(tab.key)}
            className={`px-4 py-1.5 rounded-full text-[13px] font-bold whitespace-nowrap transition active:scale-95 ${
              activeStatus === tab.key
                ? 'bg-[#EADDFF] text-[#21005D]'
                : 'bg-white border border-[#E6E0D6] text-[#49463D] hover:bg-[#EAE5DB]'
            }`}
          >
            {tab.label} {tab.count > 0 && <span className="opacity-80">({tab.count})</span>}
          </button>
        ))}
      </div>

      <div className="space-y-3 mt-2">
        {filteredOrders.length > 0 ? (
          filteredOrders.map((order) => (
            <div
              key={order.id}
              onClick={(e) => {
                if ((e.target as HTMLElement).closest('button')) return;
                handleOpenOrderDetail(order);
              }}
              className="bg-white rounded-[28px] p-5 shadow-sm hover:bg-[#FAF8F5] transition cursor-pointer group flex items-center gap-4 relative border border-transparent hover:border-[#E6E0D6]"
            >
              {/* Unread dot mock */}
              {(isPendingStatus(order.status) || order.status === 'scheduled') && (
                <div className="absolute top-4 left-3 w-3 h-3 bg-[#B3261E] rounded-full border-2 border-white z-10 shadow-xs" />
              )}
              
              <div className="relative shrink-0">
                <img
                  src={order.clientAvatar}
                  alt={order.clientName}
                  className="w-14 h-14 rounded-full object-cover"
                />
              </div>

              <div className="flex-1 min-w-0">
                <div className="flex justify-between items-center mb-1.5">
                  <h3 className="font-bold text-[16px] text-[#1D1B16] truncate tracking-tight">
                    {order.clientName}
                  </h3>
                  <div className="flex items-center gap-2 shrink-0">
                    {getStatusBadge(order.status)}
                    <span className="text-[11px] text-[#A09C94] font-medium">{order.bookingDate.slice(5)}</span>
                  </div>
                </div>
                
                <p className="text-[13px] text-[#7A756C] truncate pr-4 font-medium">
                  {order.status === 'pending_confirm' ? '[系统] 预约已生效，请按时提供服务' :
                   order.status === 'scheduled' ? '[系统] 咨询室即将开启，请准备入室' : 
                   order.status === 'completed' && !order.hasSummary ? '[系统] 咨询已结束，AI 结案小结待确认' :
                   order.status === 'completed' && order.hasSummary ? '好的，谢谢老师。' :
                   order.complaintTopic || '发来了一条消息...'}
                </p>
              </div>
            </div>
          ))
        ) : (
          <div className="text-center py-16 bg-white border border-[#E6E0D6] rounded-[28px] shadow-sm flex flex-col items-center">
            <div className="w-20 h-20 bg-[#F4EFF4] rounded-full flex items-center justify-center mx-auto mb-4">
              <MessageSquare className="w-8 h-8 text-[#6750A4]" />
            </div>
            <h3 className="text-[#1D1B16] text-[16px] font-bold tracking-tight mb-2">暂无服务消息</h3>
            <p className="text-[13px] text-[#7A756C] mt-1 font-medium max-w-[220px] mb-6 leading-relaxed">
              您还没有收到任何客户的消息或预约。建议将您的主页分享给更多人！
            </p>
            {activeStatus === 'all' && (
              <button 
                onClick={() => onNavigateToGrowth?.()}
                className="bg-[#6750A4] text-white px-6 py-2.5 rounded-full text-[14px] font-bold shadow-sm active:scale-95 transition hover:bg-[#594294]"
              >
                去分享主页
              </button>
            )}
          </div>
        )}
      </div>
    </div>
  );
};
