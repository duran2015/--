import React, { useState, useEffect, useRef } from 'react';
import { 
  ArrowLeft, Video, User, FileText, Calendar, 
  Sparkles, CheckCircle2, MessageSquare, Send, Paperclip, Clock,
  ShieldAlert, ChevronRight
} from 'lucide-react';
import { Order, OrderStatus } from '../../types';
import { useAppStore } from '../../client-app/store';

interface OrderDetailViewProps {
  order: Order;
  onBack: () => void;
  onOpenClientProfile: (order: Order) => void;
  onConfirmOrder: (orderId: string) => void;
  onEnterRoom: (order: Order) => void;
  onWriteSummary: (order: Order) => void;
  onOpenOrderInfo: (order: Order) => void;
  onOpenChat?: (order: Order) => void;
}

  type TimelineItemType = 'system_event' | 'system_security' | 'sop_card' | 'chat_client' | 'chat_therapist' | 'interactive_card_client' | 'interactive_card_therapist';

  interface TimelineItem {
    id: string;
    type: TimelineItemType;
    sopType?: 'confirm_order' | 'intake_form' | 'enter_room' | 'write_summary';
    cardType?: 'reschedule' | 'scale_assignment' | 'new_booking' | 'cancel_request';
    cardState?: 'pending' | 'resolved' | 'rejected';
    cardData?: any;
    content?: string | React.ReactNode;
    timestamp: string;
  }

export const OrderDetailView: React.FC<OrderDetailViewProps> = ({
  order,
  onBack,
  onOpenClientProfile,
  onConfirmOrder,
  onEnterRoom,
  onWriteSummary,
  onOpenOrderInfo,
}) => {
  const summaryMessage = useAppStore((state) =>
    state.consultationWorkflow.messages.find(
      (message) => message.orderId === order.id && message.audience === 'counselor',
    ),
  );
  const [items, setItems] = useState<TimelineItem[]>([]);
  const [inputValue, setInputValue] = useState('');
  const endRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const buildTimeline = () => {
      const newItems: TimelineItem[] = [];
      let timeOffset = 0;
      
      const addTime = (mins: number) => {
        timeOffset += mins;
        return new Date(Date.now() - (10000 * 60 - timeOffset * 60000)).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
      };

      // 0. Security Notice (Always at the top)
      newItems.push({
        id: 'sec_1',
        type: 'system_security',
        content: '安全提醒：平台不会以任何理由要求您私下转账。请注意保护来访者隐私，遵守咨询伦理。',
        timestamp: addTime(0)
      });

      // 1. Order Created (Interactive Card replacing system event)
      newItems.push({
        id: 'evt_1',
        type: 'interactive_card_client',
        cardType: 'new_booking',
        cardState: 'resolved',
        cardData: { 
          serviceType: order.serviceTypeName,
          bookingTime: `${order.bookingDate} ${order.bookingTimeSlot}`,
          price: `¥${(order.price || 0).toFixed(2)}`
        },
        timestamp: order.createdAt
      });

      // 2. 支付成功即确认，不再插入接单卡片或确认通知。
      newItems.push({
        id: 'evt_2',
        type: 'system_event',
        content: '预约已生效，咨询前资料已向来访者开放',
        timestamp: addTime(5)
      });

      // 4. Intake Form (if exists or mock received)
      newItems.push({
        id: 'sop_2',
        type: 'sop_card',
        sopType: 'intake_form',
        timestamp: addTime(30)
      });

      // Mock Chat messages
      newItems.push({
        id: 'chat_1',
        type: 'chat_client',
        content: '咨询师您好，我已经填完表了。第一次做心理咨询，稍微有点紧张。',
        timestamp: addTime(35)
      });
      newItems.push({
        id: 'chat_2',
        type: 'chat_therapist',
        content: '没关系的，深呼吸，我们的环境非常安全保密。到时间我们准时上线。',
        timestamp: addTime(40)
      });

      if (order.status === 'pending_reschedule_confirm' || order.status === 'pending_cancel_confirm' || order.status === 'scheduled') {
        // Therapist sends a scale (Resolved)
        newItems.push({
          id: 'card_1',
          type: 'interactive_card_therapist',
          cardType: 'scale_assignment',
          cardState: 'resolved',
          cardData: { scaleName: 'PHQ-9 抑郁症筛查量表' },
          timestamp: addTime(50)
        });

        if (order.status === 'pending_reschedule_confirm') {
          newItems.push({
            id: 'card_2',
            type: 'interactive_card_client',
            cardType: 'reschedule',
            cardState: 'pending',
            cardData: { newTime: '明天下午 14:00 - 14:50', reason: '临时有个紧急会议，实在抱歉老师。' },
            timestamp: addTime(80)
          });
          return newItems;
        }

        if (order.status === 'pending_cancel_confirm') {
          newItems.push({
            id: 'card_3',
            type: 'interactive_card_client',
            cardType: 'cancel_request',
            cardState: 'pending',
            cardData: { reason: '在约定规则范围外申请取消，暂时不涉及退款操作。' },
            timestamp: addTime(80)
          });
          return newItems;
        }

        newItems.push({
          id: 'evt_3',
          type: 'system_event',
          content: '距离咨询开始还有 10 分钟，请准备入室',
          timestamp: addTime(120)
        });
        newItems.push({
          id: 'sop_3',
          type: 'sop_card',
          sopType: 'enter_room',
          timestamp: addTime(121)
        });
        return newItems;
      }

      // 5. Completed State
      if (order.status === 'completed') {
        newItems.push({
          id: 'evt_4',
          type: 'system_event',
          content: '本次咨询已结束',
          timestamp: addTime(180)
        });
        newItems.push({
          id: 'sop_4',
          type: 'sop_card',
          sopType: 'write_summary',
          timestamp: addTime(181)
        });
      }

      return newItems;
    };

    setItems(buildTimeline());
  }, [order]);

  useEffect(() => {
    endRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [items]);

  const handleSend = () => {
    if (!inputValue.trim()) return;
    const newItem: TimelineItem = {
      id: Date.now().toString(),
      type: 'chat_therapist',
      content: inputValue,
      timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
    };
    setItems(prev => [...prev, newItem]);
    setInputValue('');
  };

  const getStatusBadge = (status: OrderStatus) => {
    switch (status) {
      case 'pending_confirm':
        return <span className="bg-[#EADDFF] text-[#21005D] text-[10px] px-2 py-0.5 rounded-full font-semibold border border-[#D0BCFF]">待咨询</span>;
      case 'scheduled':
        return <span className="bg-[#EADDFF] text-[#21005D] text-[10px] px-2 py-0.5 rounded-full font-semibold border border-[#D0BCFF]">待咨询</span>;
      case 'completed':
        return <span className="bg-stone-100 text-[#7A756C] text-[10px] px-2 py-0.5 rounded-full font-semibold border border-[#ECE6DC]">已完成</span>;
      default:
        return null;
    }
  };

  const renderSOPCard = (item: TimelineItem) => {
    switch (item.sopType) {
      case 'confirm_order':
        return (
          <div className="bg-white border border-[#ECE6DC] rounded-[24px] p-4 shadow-sm w-full max-w-[85%] mx-auto">
            <h4 className="font-bold text-sm text-[#1D1B16] flex items-center gap-2 mb-3 pb-3 border-b border-[#FAF8F5]">
              <div className="w-6 h-6 rounded-full bg-amber-100 flex items-center justify-center shrink-0">
                <CheckCircle2 className="w-3.5 h-3.5 text-amber-600" />
              </div>
              预约已确认
            </h4>
            <div className="text-xs text-[#49463D] mb-4 space-y-1.5 mt-3">
              <p>来访者：<span className="font-medium text-[#1D1B16]">{order.clientName}</span></p>
              <p>预约时间：<span className="font-medium text-[#1D1B16]">{order.bookingDate} {order.bookingTimeSlot}</span></p>
            </div>
            <p className="text-xs text-[#7A756C]">支付成功后已自动生效，无需接单。</p>
          </div>
        );
      case 'intake_form':
        return (
          <div className="bg-white border border-[#ECE6DC] rounded-[24px] p-4 shadow-sm w-full max-w-[85%] mx-auto">
            <h4 className="font-bold text-sm text-[#1D1B16] flex items-center justify-between mb-3 pb-3 border-b border-[#FAF8F5]">
              <div className="flex items-center gap-2">
                <div className="w-6 h-6 rounded-full bg-[#E8E2D5] flex items-center justify-center shrink-0">
                  <FileText className="w-3.5 h-3.5 text-[#6750A4]" />
                </div>
                来访者前置评估
              </div>
              <span className="text-[10px] bg-emerald-50 text-emerald-700 px-2 py-0.5 rounded-full font-semibold border border-emerald-100">已提交</span>
            </h4>
            <div className="bg-[#FAF8F5] p-3 rounded-[12px] text-xs text-[#49463D] mb-4 leading-relaxed">
              <span className="font-bold text-[#1D1B16]">核心诉求：</span>
              {order.complaintTopic || '无'}
              {order.intakeForm && (
                <div className="mt-2 pt-2 border-t border-[#ECE6DC]">
                  <span className="font-bold text-[#1D1B16] block mb-1">AI 风险评估提示：</span>
                  <span className="text-rose-600 font-medium">已签署安全告知。量表提示存在轻度焦虑风险，建议在本次咨询中关注其躯体化症状。</span>
                </div>
              )}
            </div>
            <button
              onClick={() => onOpenClientProfile(order)}
              className="w-full py-2 rounded-[12px] bg-white border border-[#E6E0D6] text-[#49463D] text-xs font-bold hover:bg-[#FAF8F5] transition active:scale-[0.98]"
            >
              查看完整档案详情
            </button>
          </div>
        );
      case 'enter_room':
        return (
          <div className="bg-white border border-[#ECE6DC] rounded-[24px] p-4 shadow-sm w-full max-w-[85%] mx-auto">
            <h4 className="font-bold text-sm text-[#1D1B16] flex items-center gap-2 mb-3 pb-3 border-b border-[#FAF8F5]">
              <div className="w-6 h-6 rounded-full bg-[#6750A4]/10 flex items-center justify-center shrink-0">
                <Video className="w-3.5 h-3.5 text-[#6750A4]" />
              </div>
              准备开始咨询
            </h4>
            <div className="flex items-center justify-center gap-2 text-xs text-[#6750A4] font-medium mb-4 bg-[#E8E2D5]/50 p-2.5 rounded-[10px] mt-3">
              <Clock className="w-3.5 h-3.5" />
              <span className="font-mono">{order.bookingDate} {order.bookingTimeSlot}</span>
            </div>
            <button
              onClick={() => onEnterRoom(order)}
              className="w-full py-2.5 rounded-[12px] bg-[#6750A4] text-white text-xs font-bold hover:bg-[#594294] shadow-xs transition active:scale-[0.98] flex items-center justify-center gap-2"
            >
              <Video className="w-4 h-4 text-emerald-200" />
              进入极简咨询室
            </button>
          </div>
        );
      case 'write_summary':
        const summarySubmitted = summaryMessage?.status === 'submitted' || order.hasSummary;
        return (
          <div className="bg-white border border-[#ECE6DC] rounded-[24px] p-4 shadow-sm w-full max-w-[85%] mx-auto">
            <h4 className="font-bold text-sm text-[#1D1B16] flex items-center justify-between mb-3 pb-3 border-b border-[#FAF8F5]">
              <div className="flex items-center gap-2">
                <div className="w-6 h-6 rounded-full bg-amber-50 flex items-center justify-center shrink-0">
                  <Sparkles className="w-3.5 h-3.5 text-amber-600" />
                </div>
                业务流：结案小结
              </div>
              {summarySubmitted ? (
                <span className="text-[10px] bg-emerald-50 text-emerald-700 px-2 py-0.5 rounded-full font-semibold border border-emerald-100">已完成</span>
              ) : (
                <span className="text-[10px] bg-rose-50 text-rose-600 px-2 py-0.5 rounded-full font-semibold border border-rose-100">待处理</span>
              )}
            </h4>
            <p className="text-xs text-[#7A756C] mb-4">
              {summaryMessage?.description || '本次咨询已结束。AI 已为您生成了本次对话的初步结构化小结，请您审查并补充临床意见。'}
            </p>
            <button
              onClick={() => onWriteSummary(order)}
              className={`w-full py-2.5 rounded-[12px] text-xs font-bold shadow-xs transition active:scale-[0.98] flex items-center justify-center gap-2 ${
                summarySubmitted
                  ? 'bg-[#FAF8F5] text-[#49463D] border border-[#E6E0D6] hover:bg-[#E8E2D5]'
                  : 'bg-[#A23F1E] text-white hover:bg-[#883216]'
              }`}
            >
              <Sparkles className={`w-4 h-4 ${summarySubmitted ? 'text-[#7A756C]' : 'text-amber-200'}`} />
              {summaryMessage?.actionLabel || (summarySubmitted ? '查看已归档咨询小结' : '打开待确认总结')}
            </button>
          </div>
        );
      default:
        return null;
    }
  };

  return (
    <div className="absolute inset-0 flex flex-col bg-[#FAF8F5] animate-in fade-in duration-200 z-20">
      
      {/* Top Header */}
      <div className="bg-white px-4 py-3 flex items-center justify-between border-b border-[#ECE6DC] shadow-sm z-10 shrink-0 sticky top-0">
        <div className="flex items-center gap-3 w-full">
          <button 
            onClick={onBack}
            className="p-2 -ml-2 rounded-full hover:bg-stone-100 transition active:scale-95 shrink-0"
          >
            <ArrowLeft className="w-5 h-5 text-[#1D1B16]" />
          </button>
          
          {/* Avatar (Click to Profile) */}
          <button 
            onClick={() => onOpenClientProfile(order)}
            className="w-10 h-10 rounded-full overflow-hidden ring-2 ring-[#386A20]/10 hover:ring-[#386A20]/30 transition shrink-0 active:scale-95"
            title="查看来访者档案"
          >
            <img 
              src={order.clientAvatar} 
              alt={order.clientName} 
              className="w-full h-full object-cover" 
            />
          </button>

          {/* Center Info (Click to Order Details) */}
          <div 
            className="flex-1 flex flex-col cursor-pointer group min-w-0 px-2"
            onClick={() => onOpenOrderInfo && onOpenOrderInfo(order)}
            title="查看订单详情"
          >
            <div className="flex items-center gap-2">
              <h2 className="font-bold text-base text-[#1D1B16] group-hover:text-[#6750A4] transition shrink-0">
                {order.clientName}
              </h2>
              <span className="text-xs font-semibold text-[#1D1B16] group-hover:text-[#6750A4] transition shrink-0">
                {order.bookingDate.slice(5)} {order.bookingTimeSlot}
              </span>
              <ChevronRight className="w-4 h-4 text-[#A09C94] group-hover:text-[#6750A4] transition -ml-1 shrink-0" />
            </div>
            <div className="text-[11px] text-[#7A756C] flex items-center gap-1 mt-0.5">
              <span className="truncate">{order.complaintTopic || '常规心理咨询'}</span>
            </div>
          </div>

          {/* Right Status Badge */}
          <div className="shrink-0 flex items-center">
            {getStatusBadge(order.status)}
          </div>
        </div>
      </div>

      {/* Timeline & Chat Area */}
      <div className="flex-1 overflow-y-auto p-4 space-y-6">
        <div className="text-center">
          <span className="bg-[#E8E2D5] text-[#7A756C] text-[10px] px-3 py-1 rounded-full">
            订单编号：{order.orderNo}
          </span>
        </div>

        {items.map((item) => (
          <div key={item.id} className="flex flex-col">
            {/* Timestamp for messages */}
            {item.type !== 'system_event' && item.type !== 'system_security' && (
              <span className="text-[10px] text-[#A09C94] text-center mb-3 mt-1">{item.timestamp}</span>
            )}

            {/* System Security Notice */}
            {item.type === 'system_security' && (
              <div className="flex justify-center my-3">
                <div className="bg-[#FAF8F5] border border-[#E6E0D6] text-[#7A756C] text-[11px] px-3 py-2 rounded-[12px] text-center max-w-[90%] flex items-start gap-1.5 shadow-2xs">
                  <ShieldAlert className="w-3.5 h-3.5 text-amber-500 shrink-0 mt-0.5" />
                  <span className="leading-relaxed text-left">{item.content}</span>
                </div>
              </div>
            )}

            {/* System Event Notice */}
            {item.type === 'system_event' && (
              <div className="flex justify-center my-3">
                <span className="bg-black/5 text-[#7A756C] text-[11px] px-3 py-1 rounded-full text-center max-w-[80%]">
                  {item.timestamp} - {item.content}
                </span>
              </div>
            )}

            {/* SOP Card (Centered, rich UI) */}
            {item.type === 'sop_card' && (
              <div className="flex justify-center mb-4 mt-2">
                {renderSOPCard(item)}
              </div>
            )}

            {/* Client Chat */}
            {item.type === 'chat_client' && (
              <div className="flex justify-start mb-4">
                <div className="flex gap-2 max-w-[75%]">
                  <img src={order.clientAvatar} alt="client" className="w-8 h-8 rounded-full shrink-0 object-cover mt-1" />
                  <div className="bg-white border border-[#ECE6DC] rounded-[24px] rounded-tl-sm px-4 py-2.5 shadow-sm text-[13px] text-[#1D1B16] leading-relaxed break-words">
                    {item.content}
                  </div>
                </div>
              </div>
            )}

            {/* Therapist Chat */}
            {item.type === 'chat_therapist' && (
              <div className="flex justify-end mb-4">
                <div className="bg-[#6750A4] text-white rounded-[24px] rounded-tr-sm px-4 py-2.5 shadow-sm text-[13px] leading-relaxed max-w-[75%] break-words">
                  {item.content}
                </div>
              </div>
            )}

            {/* Interactive Card: Client to Therapist (e.g. Reschedule Request, New Booking) */}
            {item.type === 'interactive_card_client' && (
              <div className="flex justify-start mb-4">
                <div className="flex gap-2 w-full max-w-[85%]">
                  <img src={order.clientAvatar} alt="client" className="w-8 h-8 rounded-full shrink-0 object-cover mt-1" />
                  <div className="bg-white border border-[#ECE6DC] rounded-[24px] rounded-tl-sm p-4 shadow-sm w-full">
                    <h4 className="font-bold text-sm text-[#1D1B16] flex items-center gap-2 mb-3 pb-2 border-b border-[#FAF8F5]">
                      <div className="w-6 h-6 rounded-full bg-amber-50 flex items-center justify-center shrink-0">
                        {item.cardType === 'new_booking' ? (
                          <CheckCircle2 className="w-3.5 h-3.5 text-amber-600" />
                        ) : item.cardType === 'cancel_request' ? (
                          <ShieldAlert className="w-3.5 h-3.5 text-amber-600" />
                        ) : (
                          <Calendar className="w-3.5 h-3.5 text-amber-600" />
                        )}
                      </div>
                      {item.cardType === 'reschedule' ? '申请修改预约时间' : 
                       item.cardType === 'new_booking' ? '发起了一条服务预约' :
                       item.cardType === 'cancel_request' ? '申请取消预约' : '发来一条互动请求'}
                    </h4>
                    
                    {item.cardData && item.cardType === 'reschedule' && (
                      <div className="bg-[#FAF8F5] p-3 rounded-[12px] text-xs text-[#49463D] mb-4 space-y-1.5 border border-[#ECE6DC]/50">
                        <p><span className="font-medium text-[#7A756C]">期望时间：</span>{item.cardData.newTime}</p>
                        <p><span className="font-medium text-[#7A756C]">修改原因：</span>{item.cardData.reason}</p>
                      </div>
                    )}

                    {item.cardData && item.cardType === 'cancel_request' && (
                      <div className="bg-[#FAF8F5] p-3 rounded-[12px] text-xs text-[#49463D] mb-4 space-y-1.5 border border-[#ECE6DC]/50">
                        <p><span className="font-medium text-[#7A756C]">取消原因：</span>{item.cardData.reason}</p>
                      </div>
                    )}

                    {item.cardData && item.cardType === 'new_booking' && (
                      <div className="bg-[#FAF8F5] p-3 rounded-[12px] text-xs text-[#49463D] mb-4 space-y-1.5 border border-[#ECE6DC]/50">
                        <p><span className="font-medium text-[#7A756C]">预约服务：</span>{item.cardData.serviceType}</p>
                        <p><span className="font-medium text-[#7A756C]">预约时间：</span>{item.cardData.bookingTime}</p>
                      </div>
                    )}

                    {item.cardState === 'pending' ? (
                      <div className="flex gap-2">
                        <button 
                          onClick={() => alert('已拒绝该请求')}
                          className="flex-1 py-2 rounded-[12px] bg-[#FAF8F5] border border-[#ECE6DC] text-[#49463D] text-xs font-bold hover:bg-[#E8E2D5] transition active:scale-95"
                        >
                          拒绝
                        </button>
                        <button 
                          onClick={() => {
                            if (item.cardType === 'new_booking') {
                              onConfirmOrder(order.id);
                            } else {
                              alert('已接受请求');
                            }
                          }}
                          className="flex-1 py-2 rounded-[12px] bg-[#6750A4] text-white text-xs font-bold hover:bg-[#594294] transition shadow-xs active:scale-95"
                        >
                          {item.cardType === 'new_booking' ? '接单' : 
                           item.cardType === 'cancel_request' ? '接受' : '接受'}
                        </button>
                      </div>
                    ) : item.cardState === 'resolved' ? (
                      <div className="text-center py-2 bg-emerald-50 rounded-[12px] text-emerald-700 text-xs font-bold flex items-center justify-center gap-1.5 border border-emerald-100">
                        <CheckCircle2 className="w-4 h-4" />
                        {item.cardType === 'new_booking' ? '已接单' : 
                         item.cardType === 'cancel_request' ? '已接受取消' : '已接受修改'}
                      </div>
                    ) : (
                      <div className="text-center py-2 bg-stone-100 rounded-[12px] text-stone-500 text-xs font-bold">
                        已拒绝
                      </div>
                    )}
                  </div>
                </div>
              </div>
            )}

            {/* Interactive Card: Therapist to Client (e.g. Scale Assignment) */}
            {item.type === 'interactive_card_therapist' && (
              <div className="flex justify-end mb-4">
                <div className="bg-[#6750A4]/5 border border-[#6750A4]/10 rounded-[24px] rounded-tr-sm p-4 shadow-sm w-full max-w-[85%]">
                  <h4 className="font-bold text-sm text-[#1D1B16] flex items-center gap-2 mb-3 pb-3 border-b border-[#6750A4]/10">
                    <div className="w-6 h-6 rounded-full bg-white flex items-center justify-center shrink-0 shadow-sm border border-[#ECE6DC]">
                      <FileText className="w-3.5 h-3.5 text-[#6750A4]" />
                    </div>
                    {item.cardType === 'scale_assignment' ? '发送了评估量表' : '发送了一条互动请求'}
                  </h4>
                  
                  {item.cardData && (
                    <div className="bg-white p-3 rounded-[12px] text-xs font-medium text-[#6750A4] mb-4 border border-[#ECE6DC] shadow-2xs">
                      {item.cardData.scaleName}
                    </div>
                  )}

                  {item.cardState === 'pending' ? (
                    <div className="text-center py-2 bg-white/50 rounded-[12px] text-[#7A756C] text-xs font-bold flex items-center justify-center gap-1.5 border border-[#ECE6DC] border-dashed">
                      <Clock className="w-3.5 h-3.5" />
                      等待来访者填写
                    </div>
                  ) : item.cardState === 'resolved' ? (
                    <button className="w-full py-2 rounded-[12px] bg-white text-[#6750A4] text-xs font-bold flex items-center justify-center gap-1.5 border border-[#6750A4]/20 shadow-xs hover:bg-[#FAF8F5] transition active:scale-95">
                      <CheckCircle2 className="w-4 h-4" />
                      来访者已完成，查看结果
                    </button>
                  ) : null}
                </div>
              </div>
            )}
          </div>
        ))}
        <div ref={endRef} />
      </div>

      {/* Chat Input Area */}
      <div className="bg-white border-t border-[#ECE6DC] p-3 pb-safe shrink-0">
        <div className="flex items-end gap-2 max-w-4xl mx-auto">
          <button className="p-2.5 text-[#7A756C] hover:bg-[#FAF8F5] rounded-full transition shrink-0">
            <Paperclip className="w-5 h-5" />
          </button>
          
          <div className="flex-1 bg-[#FAF8F5] border border-[#ECE6DC] rounded-[24px] flex items-end p-1 shadow-inner-sm">
            <textarea
              value={inputValue}
              onChange={(e) => setInputValue(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === 'Enter' && !e.shiftKey) {
                  e.preventDefault();
                  handleSend();
                }
              }}
              placeholder="发送消息或指令..."
              className="flex-1 bg-transparent border-none focus:ring-0 resize-none max-h-32 min-h-[40px] py-2 px-3 text-sm text-[#1D1B16] placeholder:text-[#A09C94]"
              rows={1}
            />
            <button 
              onClick={handleSend}
              disabled={!inputValue.trim()}
              className={`p-2.5 m-1 rounded-full transition shrink-0 ${
                inputValue.trim() 
                  ? 'bg-[#6750A4] text-white shadow-md active:scale-95' 
                  : 'bg-[#E8E2D5] text-[#A09C94] cursor-not-allowed'
              }`}
            >
              <Send className="w-4 h-4 ml-0.5" />
            </button>
          </div>
        </div>
      </div>

    </div>
  );
};
