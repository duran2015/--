import React, { useState, useEffect, useRef } from 'react';
import { X, Send, Image as ImageIcon, Smile, FileText, CheckCircle2, Sparkles, ChevronRight, LockKeyhole } from 'lucide-react';
import { Order } from '../../types';
import { useAppStore } from '../../client-app/store';

interface Message {
  id: string;
  sender: 'consultant' | 'client' | 'system';
  type: 'text' | 'image' | 'questionnaire' | 'system_alert';
  content: string;
  timestamp: string;
  metadata?: any;
}

interface ChatDrawerProps {
  order: Order;
  isOpen: boolean;
  onClose: () => void;
  onViewClientProfile?: (order: Order) => void;
  onOpenOrderInfo?: (order: Order) => void;
  onOpenSessionReview?: (draftId: string) => void;
}

export const ChatDrawer: React.FC<ChatDrawerProps> = ({ order, isOpen, onClose, onViewClientProfile, onOpenOrderInfo, onOpenSessionReview }) => {
  const [messages, setMessages] = useState<Message[]>([]);
  const [inputValue, setInputValue] = useState('');
  const [showQuestionnaireMenu, setShowQuestionnaireMenu] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const workflowMessage = useAppStore((state) =>
    state.consultationWorkflow.messages.find(
      (message) => message.orderId === order.id && message.audience === 'counselor',
    ),
  );

  useEffect(() => {
    if (isOpen) {
      // Mock initial messages
      setMessages([
        {
          id: '1',
          sender: 'system',
          type: 'system_alert',
          content: '来访者已预约成功。为了更好地了解来访者情况，您可以在这里发送预检量表或进行基础交流。',
          timestamp: new Date(Date.now() - 3600000).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
        },
        {
          id: '2',
          sender: 'client',
          type: 'text',
          content: '咨询师您好，我有些紧张，第一次做心理咨询。',
          timestamp: new Date(Date.now() - 300000).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
        }
      ]);
    }
  }, [isOpen, order]);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  if (!isOpen) return null;

  const handleSend = () => {
    if (!inputValue.trim()) return;
    const newMessage: Message = {
      id: Date.now().toString(),
      sender: 'consultant',
      type: 'text',
      content: inputValue,
      timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
    };
    setMessages(prev => [...prev, newMessage]);
    setInputValue('');
  };

  const handleSendQuestionnaire = (title: string, desc: string) => {
    const newMessage: Message = {
      id: Date.now().toString(),
      sender: 'consultant',
      type: 'questionnaire',
      content: '发送了测评问卷',
      metadata: { title, desc },
      timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
    };
    setMessages(prev => [...prev, newMessage]);
    setShowQuestionnaireMenu(false);
  };

  return (
    <>
      <div 
        className="fixed inset-0 bg-black/40 backdrop-blur-sm z-40 transition-opacity"
        onClick={onClose}
      />
      
      <div className="fixed right-0 top-0 bottom-0 w-full md:w-[400px] bg-[#FAF8F5] z-50 flex flex-col shadow-2xl animate-in slide-in-from-right duration-300">
        {/* Header */}
        <div className="bg-white px-4 py-3 flex items-center justify-between border-b border-[#ECE6DC] shadow-sm z-10 shrink-0">
          <div className="flex items-center gap-3">
            <button 
              onClick={() => onViewClientProfile?.(order)}
              className="relative rounded-full focus:outline-none focus:ring-2 focus:ring-[#6750A4]/50 transition-transform active:scale-95"
              title="查看档案"
            >
              <img src={order.clientAvatar} alt={order.clientName} className="w-10 h-10 rounded-full object-cover ring-2 ring-[#6750A4]/20 cursor-pointer" />
            </button>
            <div>
              <div className="font-bold text-[#1D1B16] flex items-center gap-2">
                <span>{order.clientName}</span>
                <span className="text-[10px] bg-[#EADDFF] text-[#21005D] px-1.5 py-0.2 rounded-md font-medium">{order.serviceTypeName}</span>
              </div>
              <div className="text-[11px] text-[#7A756C] flex items-center gap-1 mt-0.5">
                <span className="w-1.5 h-1.5 rounded-full bg-emerald-500"></span>
                当前在线
              </div>
            </div>
          </div>
          <div className="flex items-center gap-1">
            {onOpenOrderInfo && (
              <button 
                onClick={() => onOpenOrderInfo(order)}
                className="p-2 text-[#7A756C] hover:text-[#1D1B16] hover:bg-[#F3E3DA] rounded-full transition"
                title="查看订单详情"
              >
                <FileText className="w-5 h-5" />
              </button>
            )}
            <button 
              onClick={onClose}
              className="p-2 text-[#7A756C] hover:text-[#1D1B16] hover:bg-[#F3E3DA] rounded-full transition"
            >
              <X className="w-5 h-5" />
            </button>
          </div>
        </div>

        {/* Messages Area */}
        <div className="flex-1 overflow-y-auto p-4 space-y-4">
          {messages.map(msg => (
            <div key={msg.id} className={`flex flex-col ${msg.sender === 'system' ? 'items-center' : msg.sender === 'consultant' ? 'items-end' : 'items-start'}`}>
              
              {msg.sender === 'system' && (
                <div className="bg-[#E8E2D5] text-[#49463D] text-[10px] px-3 py-1 rounded-full my-2 max-w-[85%] text-center">
                  {msg.content}
                </div>
              )}

              {msg.sender !== 'system' && (
                <div className="flex items-end gap-2 max-w-[85%]">
                  {msg.sender === 'client' && (
                    <button 
                      onClick={() => onViewClientProfile?.(order)}
                      className="shrink-0 mb-1 rounded-full focus:outline-none focus:ring-1 focus:ring-[#6750A4]/50 transition-transform active:scale-95"
                    >
                      <img src={order.clientAvatar} alt="" className="w-6 h-6 rounded-full object-cover cursor-pointer" />
                    </button>
                  )}
                  
                  <div className={`flex flex-col ${msg.sender === 'consultant' ? 'items-end' : 'items-start'}`}>
                    {msg.type === 'text' && (
                      <div className={`px-3.5 py-2.5 rounded-[16px] text-sm leading-relaxed ${
                        msg.sender === 'consultant' 
                          ? 'bg-[#6750A4] text-white rounded-br-sm' 
                          : 'bg-white border border-[#ECE6DC] text-[#1D1B16] rounded-bl-sm shadow-xs'
                      }`}>
                        {msg.content}
                      </div>
                    )}

                    {msg.type === 'questionnaire' && (
                      <div className={`w-64 bg-white border border-[#ECE6DC] p-3 rounded-[16px] shadow-xs ${msg.sender === 'consultant' ? 'rounded-br-sm' : 'rounded-bl-sm'}`}>
                        <div className="flex items-center gap-2 mb-2">
                          <div className="bg-[#FAF8F5] p-1.5 rounded-lg border border-[#ECE6DC]">
                            <FileText className="w-4 h-4 text-[#A23F1E]" />
                          </div>
                          <div className="font-bold text-xs text-[#1D1B16]">{msg.metadata?.title}</div>
                        </div>
                        <div className="text-[10px] text-[#7A756C] mb-3 line-clamp-2 leading-relaxed">
                          {msg.metadata?.desc}
                        </div>
                        <button className="w-full py-1.5 bg-[#FAF8F5] border border-[#ECE6DC] text-[#6750A4] text-[11px] font-bold rounded-lg cursor-default">
                          等待来访者填写...
                        </button>
                      </div>
                    )}

                    <div className="text-[9px] text-[#A8A398] mt-1 px-1">
                      {msg.timestamp}
                    </div>
                  </div>
                </div>
              )}
            </div>
          ))}
          {workflowMessage && (
            <div className="flex flex-col items-end">
              <button
                onClick={() => onOpenSessionReview?.(workflowMessage.draftId)}
                className="w-[86%] overflow-hidden rounded-[22px] border border-[#D0BCFF] bg-white text-left shadow-sm active:scale-[0.99] transition"
              >
                <div className="bg-[#EADDFF] p-4 text-[#21005D]">
                  <div className="flex items-start justify-between gap-3">
                    <div className="grid h-10 w-10 place-items-center rounded-[14px] bg-white/60"><Sparkles size={19} /></div>
                    <span className={`rounded-full px-2 py-1 text-[9px] font-black ${workflowMessage.status === 'pending_review' ? 'bg-[#FFF4E4] text-[#8A5100]' : 'bg-[#C4EED0] text-[#163723]'}`}>
                      {workflowMessage.status === 'pending_review' ? '待确认' : '已归档'}
                    </span>
                  </div>
                  <h3 className="mt-4 text-[15px] font-black">{workflowMessage.title}</h3>
                  <p className="mt-1 text-[11px] leading-5 opacity-80">{workflowMessage.description}</p>
                </div>
                <div className="flex items-center justify-between px-4 py-3 text-[11px] font-black text-[#6750A4]">
                  <span className="flex items-center gap-1.5">{workflowMessage.status === 'pending_review' && <LockKeyhole size={13} />}{workflowMessage.actionLabel}</span>
                  <ChevronRight size={16} />
                </div>
              </button>
              <div className="mt-1 px-1 text-[9px] text-[#A8A398]">系统业务卡片 · 与待办、结算同步</div>
            </div>
          )}
          <div ref={messagesEndRef} />
        </div>

        {/* Input Area */}
        <div className="bg-white border-t border-[#ECE6DC] p-3 shrink-0 relative">
          
          {/* Questionnaire Menu */}
          {showQuestionnaireMenu && (
            <div className="absolute bottom-[100%] left-4 mb-2 w-64 bg-white border border-[#ECE6DC] rounded-[16px] shadow-lg p-2 animate-in slide-in-from-bottom-2 fade-in duration-200">
              <div className="text-[10px] font-bold text-[#7A756C] px-2 py-1 mb-1">发送专业测试题</div>
              <button 
                onClick={() => handleSendQuestionnaire('PHQ-9 抑郁症筛查量表', '用于评估近两周内的抑郁症状严重程度，共9题。')}
                className="w-full text-left px-3 py-2 hover:bg-[#FAF8F5] rounded-xl transition flex items-start gap-2"
              >
                <CheckCircle2 className="w-4 h-4 text-[#6750A4] mt-0.5 shrink-0" />
                <div>
                  <div className="text-xs font-bold text-[#1D1B16]">PHQ-9 抑郁症筛查量表</div>
                  <div className="text-[10px] text-[#7A756C] mt-0.5">评估近期情绪低落情况</div>
                </div>
              </button>
              <button 
                onClick={() => handleSendQuestionnaire('GAD-7 焦虑症筛查量表', '用于评估近两周内的广泛性焦虑症状，共7题。')}
                className="w-full text-left px-3 py-2 hover:bg-[#FAF8F5] rounded-xl transition flex items-start gap-2 mt-1"
              >
                <CheckCircle2 className="w-4 h-4 text-[#6750A4] mt-0.5 shrink-0" />
                <div>
                  <div className="text-xs font-bold text-[#1D1B16]">GAD-7 焦虑症筛查量表</div>
                  <div className="text-[10px] text-[#7A756C] mt-0.5">评估近期焦虑紧张程度</div>
                </div>
              </button>
              <button 
                onClick={() => handleSendQuestionnaire('咨询前评估登记表', '用于初诊前的基本信息及核心诉求收集。')}
                className="w-full text-left px-3 py-2 hover:bg-[#FAF8F5] rounded-xl transition flex items-start gap-2 mt-1"
              >
                <FileText className="w-4 h-4 text-[#6750A4] mt-0.5 shrink-0" />
                <div>
                  <div className="text-xs font-bold text-[#1D1B16]">咨询前初始评估表</div>
                  <div className="text-[10px] text-[#7A756C] mt-0.5">初次预约补充信息</div>
                </div>
              </button>
            </div>
          )}

          <div className="flex items-center gap-2 mb-2">
            <button 
              onClick={() => setShowQuestionnaireMenu(!showQuestionnaireMenu)}
              className={`p-1.5 rounded-lg transition ${showQuestionnaireMenu ? 'bg-[#F3E3DA] text-[#A23F1E]' : 'text-[#7A756C] hover:bg-[#FAF8F5] hover:text-[#1D1B16]'}`}
              title="发送专业量表"
            >
              <FileText className="w-4.5 h-4.5" />
            </button>
            <button className="p-1.5 text-[#7A756C] hover:bg-[#FAF8F5] hover:text-[#1D1B16] rounded-lg transition">
              <ImageIcon className="w-4.5 h-4.5" />
            </button>
            <button className="p-1.5 text-[#7A756C] hover:bg-[#FAF8F5] hover:text-[#1D1B16] rounded-lg transition">
              <Smile className="w-4.5 h-4.5" />
            </button>
          </div>
          <div className="flex items-end gap-2">
            <textarea 
              value={inputValue}
              onChange={(e) => setInputValue(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === 'Enter' && !e.shiftKey) {
                  e.preventDefault();
                  handleSend();
                }
              }}
              placeholder="发送消息..."
              className="flex-1 bg-[#FAF8F5] border border-[#ECE6DC] rounded-[16px] px-3.5 py-2.5 text-sm outline-none focus:ring-1 focus:ring-[#6750A4] min-h-[44px] max-h-[120px] resize-none"
              rows={1}
            />
            <button 
              onClick={handleSend}
              disabled={!inputValue.trim()}
              className="w-11 h-11 shrink-0 bg-[#6750A4] text-white rounded-full flex items-center justify-center disabled:opacity-50 disabled:bg-[#A8A398] hover:bg-[#594294] shadow-xs transition active:scale-95"
            >
              <Send className="w-4.5 h-4.5 ml-0.5" />
            </button>
          </div>
        </div>
      </div>
    </>
  );
};
