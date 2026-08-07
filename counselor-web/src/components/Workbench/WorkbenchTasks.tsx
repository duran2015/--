import React, { useMemo, useState, useRef } from 'react';
import { LockKeyhole } from 'lucide-react';
import { useAppStore } from '../../client-app/store';
import { buildCounselorJourneys } from '../../workbenchJourney';
import type { Order, WorkflowTaskType, WorkflowTask } from '../../types';

interface WorkbenchTasksProps {
  orders: Order[];
  onConfirmOrder: (orderId: string) => void;
  onEnterRoom: (order: Order) => void;
  onWriteSummary: (order: Order) => void;
  onSendReminder: (order: Order) => void;
  onViewClientFile?: (order: Order) => void;
  onOpenChat?: (order: Order) => void;
  onProcessOrder?: (order: Order, viewMode?: 'order_detail' | 'client_profile') => void;
}

type CurrentTaskDescriptor = {
  statusText: string;
  desc: string;
  btnText: string;
};

const currentTaskDescriptors: Partial<Record<WorkflowTaskType, CurrentTaskDescriptor>> = {
  confirm_booking: {
    statusText: '预约等待确认',
    desc: '确认后创建资料收集与入室待办',
    btnText: '处理',
  },
  handle_reschedule: {
    statusText: '待确认改期',
    desc: '来访者申请修改预约时间',
    btnText: '处理',
  },
  handle_cancel_request: {
    statusText: '待确认取消',
    desc: '来访者在规则外申请取消预约',
    btnText: '处理',
  },
  review_intake: {
    statusText: '前序资料待查阅',
    desc: '用户已填写咨询前资料',
    btnText: '查看',
  },
  enter_session: {
    statusText: '即将开始咨询',
    desc: '咨询室已准备就绪',
    btnText: '进入',
  },
  complete_session_review: {
    statusText: '待确认总结',
    desc: 'AI 草稿已生成 · 提交前结算锁定',
    btnText: '确认总结',
  },
};

export const WorkbenchTasks: React.FC<WorkbenchTasksProps> = ({
  orders,
  onConfirmOrder,
  onEnterRoom,
  onWriteSummary,
  onSendReminder,
  onViewClientFile,
  onOpenChat,
  onProcessOrder,
}) => {
  const workflowTasks = useAppStore((state) => state.consultationWorkflow.tasks);
  
  // Mix normal workflow journeys with virtual exceptional journeys (reschedule/cancel)
  const journeys = useMemo(() => {
    const normalJourneys = buildCounselorJourneys(orders, workflowTasks);
    
    const exceptionJourneys = orders
      .filter(o => o.status === 'pending_reschedule_confirm' || o.status === 'pending_cancel_confirm')
      .map(order => {
        const isReschedule = order.status === 'pending_reschedule_confirm';
        return {
          order,
          appointmentLabel: `${order.bookingDate} ${order.bookingTimeSlot}`,
          steps: [],
          currentTask: {
            id: `virtual-${order.id}`,
            orderId: order.id,
            taskType: isReschedule ? 'handle_reschedule' : 'handle_cancel_request',
            status: 'pending',
            actorRole: 'counselor',
            priority: 'high',
            createdAt: order.createdAt
          } as unknown as WorkflowTask
        };
      });

    return [...exceptionJourneys, ...normalJourneys];
  }, [orders, workflowTasks]);

  const ITEMS_PER_PAGE = 4;
  const chunks = useMemo(() => {
    const result = [];
    for (let i = 0; i < journeys.length; i += ITEMS_PER_PAGE) {
      result.push(journeys.slice(i, i + ITEMS_PER_PAGE));
    }
    return result;
  }, [journeys]);

  const [currentPage, setCurrentPage] = useState(0);
  const scrollContainerRef = useRef<HTMLDivElement>(null);

  const handleScroll = () => {
    if (!scrollContainerRef.current) return;
    const scrollLeft = scrollContainerRef.current.scrollLeft;
    const width = scrollContainerRef.current.clientWidth;
    const newPage = Math.round(scrollLeft / width);
    if (newPage !== currentPage) {
      setCurrentPage(newPage);
    }
  };

  return (
    <div className="space-y-4 rounded-[28px] border border-[#E6E0D6] bg-white p-6 shadow-sm">
      <div className="flex items-center justify-between border-b border-[#FAF8F5] pb-3">
        <div>
          <h3 className="text-[16px] font-bold tracking-tight text-[#1D1B16]">业务待办</h3>
          <p className="mt-0.5 text-[10px] text-[#7A756C]">预约、资料、会谈、总结与结算联动</p>
        </div>
        <div className="flex items-center gap-1 text-[13px] font-bold text-[#7A756C]">
          <span>{journeys.length}</span>
        </div>
      </div>

      <div className="relative w-full">
        {journeys.length > 0 ? (
          <>
            <div 
              ref={scrollContainerRef}
              onScroll={handleScroll}
              className="flex w-full overflow-x-auto snap-x snap-mandatory scrollbar-none"
            >
              {chunks.map((chunk, chunkIndex) => (
                <div key={chunkIndex} className="w-full shrink-0 snap-center">
                  <div className="divide-y divide-[#F0ECE6]">
                    {chunk.map((journey) => {
                      const descriptor = currentTaskDescriptors[journey.currentTask.taskType];
                      const { order, currentTask } = journey;
                      const buttonClassForCurrentTask = currentTask.taskType === 'enter_session'
                        ? 'rounded-full bg-[#6750A4] px-4 py-2 text-[13px] font-bold text-white shadow-xs transition hover:bg-[#594294] focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#6750A4] active:scale-95'
                        : currentTask.taskType === 'complete_session_review'
                          ? 'rounded-full bg-[#EADDFF] px-4 py-2 text-[13px] font-bold text-[#4F378B] transition hover:bg-[#D8BFFF] focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#6750A4] active:scale-95'
                          : 'rounded-full bg-[#F4EFF4] px-4 py-2 text-[13px] font-bold text-[#49454F] transition hover:bg-[#E7E0EC] focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#6750A4] active:scale-95';
                      const handleCurrentTask = () => {
                        if (currentTask.taskType === 'review_intake') {
                          onProcessOrder?.(order, 'client_profile');
                        } else if (currentTask.taskType === 'enter_session') {
                          onEnterRoom(order);
                        } else if (currentTask.taskType === 'complete_session_review') {
                          onWriteSummary(order);
                        } else {
                          onProcessOrder?.(order, 'order_detail');
                        }
                      };

                      if (!descriptor) return null;

                      return (
                        <article key={order.id} className="flex w-full items-center justify-between gap-3 py-3 first:pt-0 last:pb-0 pr-1">
                          <div className="flex min-w-0 items-center gap-3">
                            <img
                              src={order.clientAvatar}
                              alt=""
                              className="h-12 w-12 shrink-0 rounded-full border border-[#ECE6DC] bg-[#FAF8F5] object-cover"
                            />
                            <div className="min-w-0 pr-1">
                              <div className="flex min-w-0 items-center gap-2">
                                <span className="truncate text-[15px] font-bold text-[#1D1B16]">{order.clientName}</span>
                                <span className="shrink-0 text-[12px] font-medium text-[#7A756C]">{descriptor.statusText}</span>
                              </div>
                              <div className="mt-0.5 truncate text-[12px] text-[#7A756C]">{descriptor.desc}</div>
                              {currentTask.taskType === 'complete_session_review' && currentTask.blockingSettlement && (
                                <div className="mt-1 flex items-center gap-1 text-[10px] font-bold text-[#8A5100]">
                                  <LockKeyhole size={11} />完成后进入 T+1 结算
                                </div>
                              )}
                            </div>
                          </div>
                          <div className="ml-auto flex shrink-0 items-center gap-2">
                            <time
                              aria-label={`预约时间：${journey.appointmentLabel}`}
                              title={journey.appointmentLabel}
                              className="w-[46px] truncate text-right font-mono text-[10px] font-medium text-[#7A756C]"
                            >
                              {order.bookingTimeSlot.split(' ')[0]}
                            </time>
                            <button type="button" onClick={handleCurrentTask} className={buttonClassForCurrentTask}>
                              {descriptor.btnText}
                            </button>
                          </div>
                        </article>
                      );
                    })}
                  </div>
                </div>
              ))}
            </div>
            {chunks.length > 1 && (
              <div className="flex justify-center items-center gap-1.5 pt-4">
                {chunks.map((_, i) => (
                  <div 
                    key={i} 
                    className={`h-1.5 rounded-full transition-all duration-300 ${currentPage === i ? 'w-4 bg-[#6750A4]' : 'w-1.5 bg-[#EADDFF]'}`} 
                  />
                ))}
              </div>
            )}
          </>
        ) : (
          <div className="py-8 flex flex-col items-center justify-center text-center">
            <div className="w-16 h-16 bg-[#F4EFF4] rounded-full flex items-center justify-center mb-3">
              <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="#6750A4" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M12 22c5.523 0 10-4.477 10-10S17.523 2 12 2 2 6.477 2 12s4.477 10 10 10z"></path><path d="m9 12 2 2 4-4"></path></svg>
            </div>
            <h4 className="text-[15px] font-bold text-[#1D1B16] mb-1">暂无业务待办</h4>
            <p className="text-[12px] text-[#7A756C] max-w-[200px] mb-4">
              您的工作台目前很清闲。建议先去完善个人资料或配置排班。
            </p>
          </div>
        )}
      </div>
    </div>
  );
};
