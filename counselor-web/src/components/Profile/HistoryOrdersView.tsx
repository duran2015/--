import React, { useState } from 'react';
import { ArrowLeft, Clock, Calendar, ChevronRight } from 'lucide-react';
import { Order, OrderStatus } from '../../types';
import { useAppStore } from '../../client-app/store';

interface HistoryOrdersViewProps {
  onBack: () => void;
  onOpenOrderInfo: (order: Order) => void;
}

export const HistoryOrdersView: React.FC<HistoryOrdersViewProps> = ({
  onBack,
  onOpenOrderInfo
}) => {
  const orders = useAppStore((state) => state.orders);
  
  // Sort orders descending by bookingDate and bookingTimeSlot
  const sortedOrders = [...orders].sort((a, b) => {
    const timeStrA = a.bookingTimeSlot ? a.bookingTimeSlot.split('-')[0].trim() : '00:00';
    const timeStrB = b.bookingTimeSlot ? b.bookingTimeSlot.split('-')[0].trim() : '00:00';
    const dateA = a.bookingDate || '1970-01-01';
    const dateB = b.bookingDate || '1970-01-01';
    
    // Fallback to 0 if Date parsing fails (e.g. invalid format)
    const timeA = new Date(`${dateA}T${timeStrA}`).getTime() || 0;
    const timeB = new Date(`${dateB}T${timeStrB}`).getTime() || 0;
    return timeB - timeA;
  });

  const getStatusBadge = (status: OrderStatus) => {
    switch (status) {
      case 'pending_confirm':
        return <span className="bg-amber-100 text-amber-900 text-[11px] px-2.5 py-0.5 rounded-full font-semibold border border-amber-300 shrink-0">待确认</span>;
      case 'scheduled':
        return <span className="bg-[#EADDFF] text-[#21005D] text-[11px] px-2.5 py-0.5 rounded-full font-semibold border border-[#D0BCFF] shrink-0">待咨询</span>;
      case 'in_progress':
        return <span className="bg-[#6750A4] text-white text-[11px] px-2.5 py-0.5 rounded-full font-semibold animate-pulse shrink-0">服务中</span>;
      case 'completed':
        return <span className="bg-stone-100 text-[#7A756C] text-[11px] px-2.5 py-0.5 rounded-full font-semibold border border-[#ECE6DC] shrink-0">已完成</span>;
      case 'refunded':
        return <span className="bg-rose-50 text-rose-700 text-[11px] px-2.5 py-0.5 rounded-full font-semibold border border-rose-200 shrink-0">退款/售后</span>;
      default:
        return <span className="bg-stone-100 text-stone-600 text-[11px] px-2.5 py-0.5 rounded-full shrink-0">已取消</span>;
    }
  };

  return (
    <div className="space-y-4 animate-in fade-in duration-200">
      {/* Header */}
      <div className="flex items-center gap-2 mb-2">
        <button
          onClick={onBack}
          className="p-1.5 -ml-1.5 rounded-full text-[#6750A4] hover:bg-[#E8E2D5] transition active:scale-95 flex items-center gap-1 font-semibold text-xs"
        >
          <ArrowLeft className="w-4 h-4" />
          <span>返回</span>
        </button>
        <span className="text-[#ECE6DC]">/</span>
        <span className="text-xs font-bold text-[#1D1B16]">历史订单管理</span>
      </div>

      <div className="bg-white border border-[#E6E0D6] rounded-[28px] p-5 shadow-2xs space-y-4">
        <div className="flex items-center justify-between">
          <h3 className="font-bold text-[16px] text-[#1D1B16] tracking-tight">全部订单 ({sortedOrders.length})</h3>
        </div>

        <div className="space-y-3">
          {sortedOrders.map((order) => (
            <div
              key={order.id}
              onClick={() => onOpenOrderInfo(order)}
              className="bg-[#FAF8F5] rounded-[20px] p-4 flex flex-col gap-3 cursor-pointer hover:bg-[#E8E2D5]/50 transition border border-[#ECE6DC] group"
            >
              <div className="flex items-center justify-between border-b border-[#ECE6DC]/60 pb-3">
                <div className="flex items-center gap-2">
                  <span className="text-[12px] font-mono text-[#7A756C]">订单号: {order.orderNo}</span>
                </div>
                {getStatusBadge(order.status)}
              </div>

              <div className="flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <img
                    src={order.clientAvatar}
                    alt={order.clientName}
                    className="w-10 h-10 rounded-full object-cover border border-[#E6E0D6]"
                  />
                  <div>
                    <div className="font-bold text-[14px] text-[#1D1B16] group-hover:text-[#6750A4] transition-colors">{order.clientName}</div>
                    <div className="text-[11px] text-[#7A756C] mt-0.5">{order.serviceTypeName}</div>
                  </div>
                </div>
                <ChevronRight className="w-5 h-5 text-[#D0BCFF] group-hover:text-[#6750A4] transition-colors" />
              </div>
              
              <div className="flex items-center gap-4 pt-3 border-t border-[#ECE6DC]/60">
                <div className="flex items-center gap-1.5 text-[11px] text-[#7A756C]">
                  <Calendar className="w-3.5 h-3.5" />
                  <span>{order.bookingDate}</span>
                </div>
                <div className="flex items-center gap-1.5 text-[11px] text-[#7A756C]">
                  <Clock className="w-3.5 h-3.5" />
                  <span className="font-mono">{order.bookingTimeSlot}</span>
                </div>
                <div className="ml-auto font-mono text-[14px] font-bold text-[#1D1B16]">
                  ¥{(order.price || 0).toFixed(2)}
                </div>
              </div>
            </div>
          ))}

          {sortedOrders.length === 0 && (
            <div className="text-center py-16 flex flex-col items-center">
              <div className="w-16 h-16 bg-[#FAF8F5] rounded-full flex items-center justify-center mx-auto mb-3 border border-[#ECE6DC]">
                <Clock className="w-8 h-8 text-[#A09C94]" />
              </div>
              <p className="text-[14px] font-bold text-[#1D1B16] mb-1">暂无历史订单</p>
              <p className="text-[12px] text-[#7A756C]">您还没有任何咨询订单记录</p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};