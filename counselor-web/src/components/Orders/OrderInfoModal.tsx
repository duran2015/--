import React from 'react';
import { Calendar, ArrowLeft } from 'lucide-react';
import { Order, OrderStatus } from '../../types';

interface OrderInfoModalProps {
  order: Order;
  onClose: () => void;
  onConfirmOrder?: (orderId: string) => void;
}

const getStatusBadge = (status: OrderStatus) => {
  switch (status) {
    case 'pending_confirm':
      return <span className="bg-amber-100 text-amber-900 text-xs px-2.5 py-1 rounded-full font-semibold border border-amber-300">待接单</span>;
    case 'pending_reschedule_confirm':
      return <span className="bg-amber-100 text-amber-900 text-xs px-2.5 py-1 rounded-full font-semibold border border-amber-300">待改期</span>;
    case 'pending_cancel_confirm':
      return <span className="bg-amber-100 text-amber-900 text-xs px-2.5 py-1 rounded-full font-semibold border border-amber-300">待取消</span>;
    case 'scheduled':
      return <span className="bg-[#EADDFF] text-[#21005D] text-xs px-2.5 py-1 rounded-full font-semibold border border-[#D0BCFF]">待咨询</span>;
    case 'completed':
      return <span className="bg-stone-100 text-[#7A756C] text-xs px-2.5 py-1 rounded-full font-semibold border border-[#ECE6DC]">已完成</span>;
    default:
      return null;
  }
};

export const OrderInfoModal: React.FC<OrderInfoModalProps> = ({ order, onClose, onConfirmOrder }) => {
  return (
    <div className="fixed inset-0 z-50 bg-[#FAF8F5] overflow-y-auto animate-in fade-in duration-200">
      {/* Top Navigation */}
      <div className="bg-white px-4 py-3 flex items-center justify-between border-b border-[#ECE6DC] sticky top-0 z-10">
        <div className="flex items-center gap-1">
          <button 
            onClick={onClose}
            className="p-2 -ml-2 rounded-full hover:bg-stone-100 transition active:scale-95 flex items-center gap-1 text-[#49463D]"
          >
            <ArrowLeft className="w-5 h-5" />
            <span className="text-sm font-semibold">返回</span>
          </button>
        </div>
        <div className="absolute left-1/2 -translate-x-1/2">
          <h1 className="text-base font-bold text-[#1D1B16]">订单详情</h1>
        </div>
      </div>

      <div className="p-4 max-w-lg mx-auto space-y-4 pb-28">
        {/* Status Card */}
        <div className="bg-white rounded-[20px] p-5 shadow-sm border border-[#ECE6DC]">
          <div className="flex justify-between items-center mb-4">
            <span className="text-sm font-medium text-[#7A756C]">订单状态</span>
            {getStatusBadge(order.status)}
          </div>
          <div className="flex justify-between items-center pt-4 border-t border-[#FAF8F5]">
            <span className="text-sm font-medium text-[#7A756C]">订单编号</span>
            <span className="text-sm font-mono text-[#1D1B16]">{order.orderNo}</span>
          </div>
        </div>

        {/* Client & Booking Info */}
        <div className="bg-white rounded-[20px] overflow-hidden shadow-sm border border-[#ECE6DC]">
          <div className="p-4 border-b border-[#FAF8F5] bg-stone-50/50">
            <h4 className="font-bold text-[#1D1B16] flex items-center gap-2">
              <Calendar className="w-4 h-4 text-[#6750A4]" />
              预约明细
            </h4>
          </div>
          <div className="p-4 space-y-4">
            <div className="flex justify-between items-center">
              <span className="text-sm text-[#7A756C]">来访者</span>
              <div className="flex items-center gap-2">
                <img src={order.clientAvatar} alt="avatar" className="w-6 h-6 rounded-full border border-[#ECE6DC]" />
                <span className="text-sm font-medium text-[#1D1B16]">{order.clientName}</span>
              </div>
            </div>
            <div className="flex justify-between items-center">
              <span className="text-sm text-[#7A756C]">服务项目</span>
              <span className="text-sm font-medium text-[#1D1B16]">{order.serviceTypeName}</span>
            </div>
            <div className="flex justify-between items-center">
              <span className="text-sm text-[#7A756C]">预约时间</span>
              <span className="text-sm font-medium text-[#1D1B16]">{order.bookingDate} {order.bookingTimeSlot}</span>
            </div>
            <div className="flex justify-between items-center">
              <span className="text-sm text-[#7A756C]">咨询形式</span>
              <span className="text-sm font-medium text-[#1D1B16]">线上视频咨询</span>
            </div>
          </div>
        </div>

        {/* Complaint Topic (If exists) */}
        {order.complaintTopic && (
          <div className="bg-white rounded-[20px] p-5 shadow-sm border border-[#ECE6DC]">
            <h4 className="font-bold text-sm text-[#1D1B16] mb-3">咨询议题摘要</h4>
            <div className="bg-[#FAF8F5] p-3 rounded-[12px] text-sm text-[#49463D] leading-relaxed">
              {order.complaintTopic}
            </div>
          </div>
        )}

        {/* Financial Info */}
        <div className="bg-white rounded-[20px] overflow-hidden shadow-sm border border-[#ECE6DC]">
          <div className="p-4 border-b border-[#FAF8F5] bg-stone-50/50">
            <h4 className="font-bold text-[#1D1B16]">财务结算</h4>
          </div>
          <div className="p-4 space-y-4">
            <div className="flex justify-between items-center">
              <span className="text-sm text-[#7A756C]">服务原价</span>
              <span className="text-sm text-[#1D1B16]">¥{(order.price || 0).toFixed(2)}</span>
            </div>
            <div className="flex justify-between items-center">
              <span className="text-sm text-[#7A756C]">优惠抵扣</span>
              <span className="text-sm text-[#6750A4]">- ¥0.00</span>
            </div>
            <div className="pt-4 mt-2 border-t border-[#ECE6DC] flex justify-between items-center">
              <span className="font-bold text-[#1D1B16]">实付金额</span>
              <span className="text-xl font-bold text-[#A23F1E]">¥{(order.price || 0).toFixed(2)}</span>
            </div>
          </div>
        </div>
      </div>

      {/* Fixed Bottom Action Bar */}
      {(order.status === 'pending_confirm' || order.status === 'pending_reschedule_confirm' || order.status === 'pending_cancel_confirm') && (
        <div className="fixed bottom-0 left-0 right-0 bg-white border-t border-[#ECE6DC] p-4 pb-safe z-20 shadow-[0_-4px_20px_rgba(0,0,0,0.05)]">
          <div className="max-w-lg mx-auto flex gap-3">
            <button 
              onClick={() => alert('已拒绝')}
              className="flex-1 py-3.5 rounded-full bg-[#FAF8F5] border border-[#ECE6DC] text-[#49463D] text-[15px] font-bold hover:bg-[#E8E2D5] transition active:scale-95"
            >
              拒绝
            </button>
            <button 
              onClick={() => {
                if (order.status === 'pending_confirm' && onConfirmOrder) {
                  onConfirmOrder(order.id);
                  onClose();
                } else {
                  alert('已接受');
                  onClose();
                }
              }}
              className="flex-1 py-3.5 rounded-full bg-[#6750A4] text-white text-[15px] font-bold hover:bg-[#594294] transition shadow-md active:scale-95"
            >
              {order.status === 'pending_confirm' ? '确认接单' : 
               order.status === 'pending_cancel_confirm' ? '同意取消' : '同意修改'}
            </button>
          </div>
        </div>
      )}
    </div>
  );
};
