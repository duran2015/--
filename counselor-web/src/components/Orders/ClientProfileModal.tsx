import React, { useState } from 'react';
import { 
  X, User, Phone, ShieldAlert, Heart, Activity, FileText, Calendar, 
  CheckCircle2, Clock, Sparkles, MessageSquare, AlertCircle, Bookmark 
} from 'lucide-react';
import { ClientProfile, Order } from '../../types';

interface ClientProfileModalProps {
  client: ClientProfile;
  relatedOrder?: Order;
  onClose: () => void;
  onEnterRoom?: (order: Order) => void;
}

export const ClientProfileModal: React.FC<ClientProfileModalProps> = ({
  client,
  relatedOrder,
  onClose,
  onEnterRoom,
}) => {
  const [activeSubTab, setActiveSubTab] = useState<'intake' | 'history' | 'checkins'>('intake');

  const getRiskBadge = (level: ClientProfile['riskLevel']) => {
    switch (level) {
      case 'low':
        return (
          <span className="bg-[#EADDFF] text-[#21005D] border border-[#D0BCFF] text-[11px] px-2.5 py-0.5 rounded-full font-semibold flex items-center gap-1">
            <CheckCircle2 className="w-3 h-3 text-[#6750A4]" />
            <span>评估：低风险</span>
          </span>
        );
      case 'attention':
        return (
          <span className="bg-amber-100 text-amber-900 border border-amber-300 text-[11px] px-2.5 py-0.5 rounded-full font-semibold flex items-center gap-1">
            <AlertCircle className="w-3 h-3 text-amber-700" />
            <span>评估：关注级</span>
          </span>
        );
      case 'attention':
        return (
          <span className="bg-rose-100 text-rose-900 border border-rose-300 text-[11px] px-2.5 py-0.5 rounded-full font-semibold flex items-center gap-1">
            <ShieldAlert className="w-3 h-3 text-rose-700" />
            <span>评估：重点关注</span>
          </span>
        );
      default:
        return null;
    }
  };

  return (
    <div className="fixed inset-0 z-50 bg-black/50 backdrop-blur-xs flex items-end sm:items-center justify-center p-0 sm:p-4 animate-in fade-in">
      <div className="bg-[#FAF8F5] border border-[#E6E0D6] rounded-t-[28px] sm:rounded-[28px] max-w-xl w-full p-5 shadow-2xl relative max-h-[90vh] flex flex-col">
        
        {/* M3 Sheet Handle bar */}
        <div className="w-10 h-1 bg-[#E6E0D6] rounded-full mx-auto mb-3 shrink-0" />

        {/* Close Button */}
        <button
          onClick={onClose}
          className="absolute top-4 right-4 p-2 rounded-full text-[#7A756C] hover:text-[#1D1B16] hover:bg-[#E8E2D5] transition active:scale-95 z-10"
        >
          <X className="w-5 h-5" />
        </button>

        {/* Client Basic Card */}
        <div className="bg-white p-4 rounded-[20px] border border-[#E6E0D6] shadow-2xs mb-3 shrink-0">
          <div className="flex items-start gap-3.5">
            <img
              src={client.avatar}
              alt={client.name}
              className="w-14 h-14 rounded-full object-cover ring-2 ring-[#386A20]/20 shrink-0"
            />
            <div className="flex-1 min-w-0">
              <div className="flex items-center gap-2 flex-wrap">
                <h3 className="font-bold text-base text-[#1D1B16]">{client.name}</h3>
                <span className="text-xs text-[#7A756C] bg-[#FAF8F5] px-2 py-0.5 rounded-full border border-[#ECE6DC]">
                  {client.gender} • {client.age}岁
                </span>
                {getRiskBadge(client.riskLevel)}
              </div>

              <p className="text-xs text-[#7A756C] mt-1 truncate">
                <strong className="font-normal text-[#1D1B16]">{client.occupation}</strong> | {client.city}
              </p>

              <div className="flex items-center gap-3 text-[11px] text-[#7A756C] mt-2 pt-2 border-t border-[#ECE6DC]">
                <span className="flex items-center gap-1 font-mono">
                  <Phone className="w-3 h-3 text-[#6750A4]" />
                  {client.phone}
                </span>
                <span>建档时间：{client.intakeDate}</span>
              </div>
            </div>
          </div>

          {/* Tags */}
          <div className="flex flex-wrap gap-1.5 mt-3 pt-2.5 border-t border-[#ECE6DC]">
            {client.tags.map((tag, idx) => (
              <span
                key={idx}
                className="text-[10px] bg-[#FAF8F5] text-[#6750A4] border border-[#ECE6DC] px-2.5 py-0.5 rounded-full font-medium"
              >
                #{tag}
              </span>
            ))}
          </div>
        </div>

        {/* Sub-tab Navigation */}
        <div className="flex items-center gap-1 bg-[#E8E2D5]/50 p-1 rounded-full border border-[#ECE6DC] mb-3 shrink-0">
          <button
            onClick={() => setActiveSubTab('intake')}
            className={`flex-1 py-1.5 rounded-full text-xs font-semibold transition active:scale-95 ${
              activeSubTab === 'intake'
                ? 'bg-[#6750A4] text-white shadow-2xs'
                : 'text-[#49463D] hover:bg-[#E8E2D5]'
            }`}
          >
            知情同意与评估
          </button>
          <button
            onClick={() => setActiveSubTab('history')}
            className={`flex-1 py-1.5 rounded-full text-xs font-semibold transition active:scale-95 ${
              activeSubTab === 'history'
                ? 'bg-[#6750A4] text-white shadow-2xs'
                : 'text-[#49463D] hover:bg-[#E8E2D5]'
            }`}
          >
            咨询记录 ({client.sessionLogs.length}次)
          </button>
          <button
            onClick={() => setActiveSubTab('checkins')}
            className={`flex-1 py-1.5 rounded-full text-xs font-semibold transition active:scale-95 ${
              activeSubTab === 'checkins'
                ? 'bg-[#6750A4] text-white shadow-2xs'
                : 'text-[#49463D] hover:bg-[#E8E2D5]'
            }`}
          >
            前置情绪随手记
          </button>
        </div>

        {/* Tab Content Area (Scrollable) */}
        <div className="flex-1 overflow-y-auto space-y-3 pr-1 scrollbar-none text-xs">
          
          {/* Tab 1: Intake & Psychometrics */}
          {activeSubTab === 'intake' && (
            <div className="space-y-3">
              
              {/* Psychological Test Scores */}
              <div className="bg-white p-3.5 rounded-[18px] border border-[#E6E0D6] space-y-2">
                <div className="font-bold text-xs text-[#1D1B16] flex items-center justify-between">
                  <span className="flex items-center gap-1.5 text-[#6750A4]">
                    <Activity className="w-4 h-4 text-[#A23F1E]" />
                    临床量表自评参考
                  </span>
                  <span className="text-[10px] text-[#7A756C]">入组初始测量</span>
                </div>

                <div className="grid grid-cols-2 gap-2 pt-1">
                  {client.phq9Score && (
                    <div className="bg-[#FAF8F5] p-2.5 rounded-[12px] border border-[#ECE6DC]">
                      <div className="text-[10px] text-[#7A756C]">PHQ-9 抑郁筛查</div>
                      <div className="text-sm font-bold text-[#1D1B16] font-mono mt-0.5">
                        {client.phq9Score.score} <span className="text-[10px] font-normal text-[#6750A4]">/ 27分</span>
                      </div>
                      <div className="text-[10px] text-[#6750A4] font-medium mt-0.5">{client.phq9Score.level}</div>
                    </div>
                  )}

                  {client.gad7Score && (
                    <div className="bg-[#FAF8F5] p-2.5 rounded-[12px] border border-[#ECE6DC]">
                      <div className="text-[10px] text-[#7A756C]">GAD-7 焦虑筛查</div>
                      <div className="text-sm font-bold text-[#1D1B16] font-mono mt-0.5">
                        {client.gad7Score.score} <span className="text-[10px] font-normal text-amber-800">/ 21分</span>
                      </div>
                      <div className="text-[10px] text-amber-900 font-medium mt-0.5">{client.gad7Score.level}</div>
                    </div>
                  )}
                </div>
              </div>

              {/* Related Order Intake Form Info */}
              {relatedOrder && relatedOrder.intakeForm && (
                <div className="bg-white p-3.5 rounded-[18px] border border-[#E6E0D6] space-y-2.5">
                  <div className="font-bold text-xs text-[#1D1B16] flex items-center justify-between">
                    <span className="flex items-center gap-1.5 text-[#6750A4]">
                      <FileText className="w-4 h-4 text-[#6750A4]" />
                      本次预约知情表与主诉
                    </span>
                    <span className="text-[10px] bg-[#EADDFF] text-[#21005D] px-2 py-0.2 rounded-full font-mono">
                      {relatedOrder.orderNo}
                    </span>
                  </div>

                  <div className="space-y-2 text-[#49463D] leading-relaxed">
                    <div>
                      <span className="text-[#7A756C] block mb-0.5 font-medium text-[11px]">主诉与当前困扰：</span>
                      <p className="bg-[#FAF8F5] p-2.5 rounded-[12px] border border-[#ECE6DC] text-[#1D1B16]">
                        {relatedOrder.intakeForm.primaryIssueDetail}
                      </p>
                    </div>

                    <div>
                      <span className="text-[#7A756C] block mb-0.5 font-medium text-[11px]">本次咨询期待与目标：</span>
                      <p className="bg-[#FAF8F5] p-2.5 rounded-[12px] border border-[#ECE6DC] text-[#1D1B16]">
                        {relatedOrder.intakeForm.expectations}
                      </p>
                    </div>

                    <div className="flex items-center justify-between pt-1 text-[11px]">
                      <span className="text-[#7A756C]">既往咨询史：</span>
                      <span className="font-semibold text-[#1D1B16]">
                        {relatedOrder.intakeForm.hasCounselingHistory
                          ? relatedOrder.intakeForm.previousCounselingType || '有相关经验'
                          : '首次接受心理咨询'}
                      </span>
                    </div>

                    <div className="flex items-center justify-between text-[11px]">
                      <span className="text-[#7A756C]">知情同意书与危机免责声明：</span>
                      <span className="text-emerald-700 font-semibold flex items-center gap-1">
                        <CheckCircle2 className="w-3.5 h-3.5" /> 已在线签署
                      </span>
                    </div>
                  </div>
                </div>
              )}

              {/* Emergency Contact */}
              <div className="bg-white p-3.5 rounded-[18px] border border-[#E6E0D6] flex items-center justify-between">
                <div>
                  <div className="text-[11px] text-[#7A756C]">紧急联系人信息 (防危机伦理报备)</div>
                  <div className="font-semibold text-xs text-[#1D1B16] mt-0.5">
                    {client.emergencyContact.name} ({client.emergencyContact.relation})
                  </div>
                </div>
                <div className="text-right font-mono text-xs font-semibold text-[#6750A4]">
                  {client.emergencyContact.phone}
                </div>
              </div>

            </div>
          )}

          {/* Tab 2: Counseling History & Working Notes */}
          {activeSubTab === 'history' && (
            <div className="space-y-3">
              
              {/* Overall Progress Stats */}
              <div className="bg-white p-3.5 rounded-[18px] border border-[#E6E0D6] space-y-2">
                <div className="font-bold text-xs text-[#1D1B16] flex items-center justify-between">
                  <span>咨询师私密工作笔记</span>
                  <span className="text-[10px] text-[#7A756C]">出勤率 {client.historySummary.attendanceRate}</span>
                </div>
                <p className="bg-[#FAF8F5] p-2.5 rounded-[12px] border border-[#ECE6DC] text-[#49463D] leading-relaxed">
                  {client.historySummary.counselorWorkingNotes}
                </p>

                <div className="pt-2">
                  <span className="text-[#7A756C] block mb-1 text-[11px]">阶段性咨询目标：</span>
                  <ul className="list-disc pl-4 space-y-1 text-[#1D1B16]">
                    {client.historySummary.primaryGoals.map((g, idx) => (
                      <li key={idx}>{g}</li>
                    ))}
                  </ul>
                </div>
              </div>

              {/* Session Timeline */}
              <div className="space-y-2">
                <div className="font-bold text-xs text-[#1D1B16] px-1">历史会谈小结记录</div>
                {client.sessionLogs.length === 0 ? (
                  <div className="bg-white p-5 rounded-[18px] border border-[#E6E0D6] text-center text-[#7A756C]">
                    <Clock className="w-6 h-6 text-[#6750A4] mx-auto mb-1 opacity-50" />
                    <span>暂无过往会谈记录（首诊来访）</span>
                  </div>
                ) : (
                  client.sessionLogs.map((log) => (
                    <div
                      key={log.sessionNo}
                      className="bg-white p-3 rounded-[16px] border border-[#E6E0D6] space-y-1.5"
                    >
                      <div className="flex items-center justify-between">
                        <span className="font-bold text-xs text-[#6750A4]">
                          第 {log.sessionNo} 次会谈
                        </span>
                        <span className="font-mono text-[11px] text-[#7A756C]">{log.date}</span>
                      </div>
                      <div className="font-semibold text-[#1D1B16] text-[12px]">{log.topic}</div>
                      <div className="bg-[#FAF8F5] p-2 rounded-[10px] text-[#49463D] text-[11px]">
                        <strong className="text-[#A23F1E]">关键觉察：</strong>{log.keyBreakthrough}
                      </div>
                    </div>
                  ))
                )}
              </div>

            </div>
          )}

          {/* Tab 3: Mood Check-in Logs */}
          {activeSubTab === 'checkins' && (
            <div className="space-y-3">
              <div className="bg-white p-3.5 rounded-[18px] border border-[#E6E0D6] space-y-2">
                <div className="font-bold text-xs text-[#1D1B16] flex items-center justify-between">
                  <span>会前心情打卡与生活事件</span>
                  <span className="text-[10px] text-[#7A756C]">近3天打卡</span>
                </div>

                {client.preSessionCheckIns.length === 0 ? (
                  <div className="text-center py-4 text-[#7A756C]">未录入近期打卡</div>
                ) : (
                  <div className="space-y-2 pt-1">
                    {client.preSessionCheckIns.map((item, idx) => (
                      <div
                        key={idx}
                        className="bg-[#FAF8F5] p-2.5 rounded-[14px] border border-[#ECE6DC] flex items-center justify-between"
                      >
                        <div>
                          <div className="font-mono text-[11px] text-[#7A756C]">{item.date}</div>
                          <div className="font-medium text-[#1D1B16] text-xs mt-0.5">
                            诱发压力事由：{item.distressTrigger}
                          </div>
                        </div>
                        <div className="text-right shrink-0 ml-2">
                          <div className="text-xs font-bold text-[#A23F1E] font-mono">
                            焦虑指数 {item.moodScore}/10
                          </div>
                          <div className="text-[10px] text-[#7A756C]">睡眠: {item.sleepHours}小时</div>
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            </div>
          )}

        </div>

        {/* Modal Footer */}
        <div className="pt-3 mt-3 border-t border-[#ECE6DC] flex items-center justify-between shrink-0">
          <div className="text-[11px] text-[#7A756C]">
            档案保密级别：<span className="font-semibold text-[#1D1B16]">HIPAA 临床合规加密</span>
          </div>

          <div className="flex gap-2">
            <button
              onClick={onClose}
              className="px-4 py-2 rounded-full border border-[#E6E0D6] bg-white text-xs font-semibold text-[#49463D] hover:bg-[#E8E2D5] active:scale-95"
            >
              关闭
            </button>

            {relatedOrder && relatedOrder.status === 'scheduled' && onEnterRoom && (
              <button
                onClick={() => {
                  onClose();
                  onEnterRoom(relatedOrder);
                }}
                className="px-5 py-2 rounded-full bg-[#6750A4] text-white text-xs font-semibold hover:bg-[#594294] shadow-2xs active:scale-95"
              >
                进入咨询室
              </button>
            )}
          </div>
        </div>

      </div>
    </div>
  );
};
