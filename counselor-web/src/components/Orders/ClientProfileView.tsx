import React, { useState } from 'react';
import { 
  ArrowLeft, User, Phone, ShieldAlert, Heart, Activity, FileText, Calendar, 
  CheckCircle2, Clock, Sparkles, MessageSquare, AlertCircle, Bookmark, Video 
} from 'lucide-react';
import { ClientProfile, Order } from '../../types';

interface ClientProfileViewProps {
  client: ClientProfile;
  relatedOrder?: Order;
  onBack: () => void;
  onEnterRoom?: (order: Order) => void;
}

export const ClientProfileView: React.FC<ClientProfileViewProps> = ({
  client,
  relatedOrder,
  onBack,
  onEnterRoom,
}) => {
  const [activeSubTab, setActiveSubTab] = useState<'intake' | 'history' | 'checkins'>('intake');

  const getRiskBadge = (level: ClientProfile['riskLevel']) => {
    switch (level) {
      case 'low':
        return (
          <span className="bg-[#EADDFF] text-[#21005D] border border-[#D0BCFF] text-xs px-3 py-1 rounded-full font-semibold flex items-center gap-1">
            <CheckCircle2 className="w-3.5 h-3.5 text-[#6750A4]" />
            <span>评估：低风险</span>
          </span>
        );
      case 'attention':
        return (
          <span className="bg-amber-100 text-amber-900 border border-amber-300 text-xs px-3 py-1 rounded-full font-semibold flex items-center gap-1">
            <AlertCircle className="w-3.5 h-3.5 text-amber-700" />
            <span>评估：关注级</span>
          </span>
        );
      case 'high':
        return (
          <span className="bg-rose-100 text-rose-900 border border-rose-300 text-xs px-3 py-1 rounded-full font-semibold flex items-center gap-1">
            <ShieldAlert className="w-3.5 h-3.5 text-rose-700" />
            <span>评估：重点关注</span>
          </span>
        );
      default:
        return null;
    }
  };

  return (
    <div className="space-y-4 animate-in fade-in duration-200">
      
      {/* Top Header with Back Navigation */}
      <div className="bg-white border border-[#E6E0D6] rounded-[24px] p-4 shadow-2xs flex items-center justify-between">
        <div className="flex items-center gap-3">
          <button
            onClick={onBack}
            className="p-2 rounded-full border border-[#E6E0D6] bg-[#FAF8F5] text-[#1D1B16] hover:bg-[#E8E2D5] transition active:scale-95 flex items-center justify-center"
            title="返回"
          >
            <ArrowLeft className="w-4 h-4 text-[#6750A4]" />
          </button>
          <div className="h-4 w-[1px] bg-[#E6E0D6]" />
          <div>
            <h2 className="font-bold text-base text-[#1D1B16]">来访者档案</h2>
          </div>
        </div>
      </div>

      {/* Client Overview Banner - Material 3 Style */}
      <div className="bg-[#FAF8F5] rounded-[28px] p-5 flex flex-col gap-4 border-none shadow-none relative overflow-hidden">
        {/* Subtle decorative background for M3 feel */}
        <div className="absolute top-0 right-0 w-32 h-32 bg-[#E8E2D5]/30 rounded-full blur-2xl -translate-y-1/2 translate-x-1/4 pointer-events-none"></div>

        <div className="flex items-center gap-4 relative z-10">
          <div className="relative">
            <img
              src={client.avatar}
              alt={client.name}
              className="w-16 h-16 rounded-[20px] object-cover shrink-0"
            />
            <div className="absolute -bottom-1 -right-1 bg-[#6750A4] text-white text-[9px] font-bold px-1.5 py-0.5 rounded-md">
              M3
            </div>
          </div>
          
          <div className="flex-1 min-w-0">
            <div className="flex items-center gap-2 flex-wrap">
              <h3 className="font-bold text-xl text-[#1D1B16] tracking-tight">{client.name}</h3>
              {getRiskBadge(client.riskLevel)}
            </div>
            
            <p className="text-xs text-[#7A756C] mt-1 font-medium">
              {client.gender} · {client.age}岁 · {client.occupation}
            </p>
          </div>
        </div>

        {/* M3 Chip Group for Meta Info */}
        <div className="flex flex-wrap gap-2 relative z-10 mt-1">
          <div className="bg-white/60 backdrop-blur-sm border border-[#E6E0D6] px-3 py-1.5 rounded-xl text-xs text-[#49463D] flex items-center gap-1.5">
            <span className="w-1.5 h-1.5 rounded-full bg-[#A23F1E]"></span>
            常居 {client.city}
          </div>
          <div className="bg-white/60 backdrop-blur-sm border border-[#E6E0D6] px-3 py-1.5 rounded-xl text-xs text-[#49463D] flex items-center gap-1.5">
            <Bookmark className="w-3.5 h-3.5 text-[#6750A4]" />
            建档 {client.intakeDate}
          </div>
          <div className="bg-white/60 backdrop-blur-sm border border-[#E6E0D6] px-3 py-1.5 rounded-xl text-xs text-[#49463D] flex items-center gap-1.5">
            <CheckCircle2 className="w-3.5 h-3.5 text-[#6750A4]" />
            已咨询 {client.sessionLogs.length} 次
          </div>
        </div>
      </div>

      {/* M3 Segmented Button / Tabs */}
      <div className="bg-[#FAF8F5] rounded-[24px] p-1 flex items-center">
        <button
          onClick={() => setActiveSubTab('intake')}
          className={`flex-1 py-2.5 rounded-full text-xs font-bold transition-all duration-300 ${
            activeSubTab === 'intake'
              ? 'bg-white text-[#6750A4] shadow-[0_2px_8px_rgba(0,0,0,0.04)]'
              : 'bg-transparent text-[#7A756C] hover:bg-black/5'
          }`}
        >
          前置评估
        </button>
        <button
          onClick={() => setActiveSubTab('history')}
          className={`flex-1 py-2.5 rounded-full text-xs font-bold transition-all duration-300 ${
            activeSubTab === 'history'
              ? 'bg-white text-[#6750A4] shadow-[0_2px_8px_rgba(0,0,0,0.04)]'
              : 'bg-transparent text-[#7A756C] hover:bg-black/5'
          }`}
        >
          历次记录 {client.sessionLogs.length > 0 ? `(${client.sessionLogs.length})` : ''}
        </button>
        <button
          onClick={() => setActiveSubTab('checkins')}
          className={`flex-1 py-2.5 rounded-full text-xs font-bold transition-all duration-300 ${
            activeSubTab === 'checkins'
              ? 'bg-white text-[#6750A4] shadow-[0_2px_8px_rgba(0,0,0,0.04)]'
              : 'bg-transparent text-[#7A756C] hover:bg-black/5'
          }`}
        >
          危机干预 {client.crisisInterventions && client.crisisInterventions.length > 0 ? `(${client.crisisInterventions.length})` : ''}
        </button>
      </div>

      {/* Tab Content Areas */}
      <div className="space-y-4 text-xs">
        
        {/* Tab 1: Intake & Psychometrics */}
        {activeSubTab === 'intake' && (
          <div className="space-y-4">
            
            {/* AI Summary of Assessment (Only show if at least one assessment is filled) */}
            {(client.phq9Score || client.gad7Score || relatedOrder?.intakeForm) && (
              <div className="bg-gradient-to-br from-[#FAF8F5] to-[#F2EFE9] rounded-[24px] p-5 shadow-[0_2px_12px_-4px_rgba(0,0,0,0.05)] border border-[#E6E0D6]">
                <div className="flex items-center gap-1.5 text-[#6750A4] font-bold text-sm mb-3">
                  <Sparkles className="w-4 h-4" />
                  AI 前置评估总结
                </div>
                <p className="text-xs text-[#49463D] leading-relaxed font-medium">
                  根据来访者的前置信息，其主要面临<strong className="text-[#1D1B16]">职场压力导致的躯体化反应</strong>。
                  {client.gad7Score && <span>量表显示存在<strong className="text-amber-700"> {client.gad7Score.level} </strong>，</span>}
                  {client.phq9Score && <span>伴随<strong className="text-amber-700"> {client.phq9Score.level} </strong>。</span>}
                  建议在本次咨询中，重点关注其睡眠质量及躯体紧张感，并可以结合其过往的 CBT 经验，探讨引发焦虑的自动化思维。
                </p>
              </div>
            )}

            {/* Scale 1: PHQ-9 */}
            <div className="bg-white rounded-[24px] p-4 shadow-[0_2px_12px_-4px_rgba(0,0,0,0.05)] border border-[#F2EFE9]">
              <div className="flex items-center justify-between mb-3">
                <div className="font-bold text-sm text-[#1D1B16] flex items-center gap-2">
                  <Activity className="w-4 h-4 text-[#A23F1E]" />
                  PHQ-9 抑郁筛查
                </div>
                {client.phq9Score ? (
                  <span className="text-[10px] bg-emerald-50 text-emerald-700 px-2 py-1 rounded-md border border-emerald-200 flex items-center gap-1 font-semibold">
                    <CheckCircle2 className="w-3 h-3" /> 已填写
                  </span>
                ) : (
                  <span className="text-[10px] bg-[#FAF8F5] text-[#7A756C] px-2 py-1 rounded-md border border-[#E6E0D6]">未填写</span>
                )}
              </div>
              {client.phq9Score ? (
                <div className="bg-[#FAF8F5] rounded-[16px] p-3.5 flex justify-between items-center">
                  <div>
                    <div className="text-xs font-bold text-[#1D1B16]">测评结果: {client.phq9Score.level}</div>
                    <div className="text-[11px] text-[#7A756C] mt-1 line-clamp-1">总结: 提示存在一定抑郁情绪风险，建议关注。</div>
                  </div>
                  <div className="text-lg font-mono font-bold text-[#1D1B16] ml-3">
                    {client.phq9Score.score}<span className="text-[10px] text-[#7A756C] font-normal">/27</span>
                  </div>
                </div>
              ) : (
                <div className="flex items-center justify-between bg-[#FAF8F5] rounded-[16px] p-3">
                  <span className="text-xs text-[#7A756C]">来访者尚未完成此量表</span>
                  <button className="text-[11px] font-semibold text-[#6750A4] bg-white px-3 py-1.5 rounded-lg border border-[#E6E0D6] shadow-xs active:scale-95 transition">提醒填写</button>
                </div>
              )}
            </div>

            {/* Scale 2: GAD-7 */}
            <div className="bg-white rounded-[24px] p-4 shadow-[0_2px_12px_-4px_rgba(0,0,0,0.05)] border border-[#F2EFE9]">
              <div className="flex items-center justify-between mb-3">
                <div className="font-bold text-sm text-[#1D1B16] flex items-center gap-2">
                  <Activity className="w-4 h-4 text-[#A23F1E]" />
                  GAD-7 焦虑筛查
                </div>
                {client.gad7Score ? (
                  <span className="text-[10px] bg-emerald-50 text-emerald-700 px-2 py-1 rounded-md border border-emerald-200 flex items-center gap-1 font-semibold">
                    <CheckCircle2 className="w-3 h-3" /> 已填写
                  </span>
                ) : (
                  <span className="text-[10px] bg-[#FAF8F5] text-[#7A756C] px-2 py-1 rounded-md border border-[#E6E0D6]">未填写</span>
                )}
              </div>
              {client.gad7Score ? (
                <div className="bg-[#FAF8F5] rounded-[16px] p-3.5 flex justify-between items-center">
                  <div>
                    <div className="text-xs font-bold text-[#1D1B16]">测评结果: {client.gad7Score.level}</div>
                    <div className="text-[11px] text-[#7A756C] mt-1 line-clamp-1">总结: 提示存在焦虑症状，需探索压力源。</div>
                  </div>
                  <div className="text-lg font-mono font-bold text-[#1D1B16] ml-3">
                    {client.gad7Score.score}<span className="text-[10px] text-[#7A756C] font-normal">/21</span>
                  </div>
                </div>
              ) : (
                <div className="flex items-center justify-between bg-[#FAF8F5] rounded-[16px] p-3">
                  <span className="text-xs text-[#7A756C]">来访者尚未完成此量表</span>
                  <button className="text-[11px] font-semibold text-[#6750A4] bg-white px-3 py-1.5 rounded-lg border border-[#E6E0D6] shadow-xs active:scale-95 transition">提醒填写</button>
                </div>
              )}
            </div>

            {/* Form 3: Intake Form */}
            <div className="bg-white rounded-[24px] p-4 shadow-[0_2px_12px_-4px_rgba(0,0,0,0.05)] border border-[#F2EFE9]">
              <div className="flex items-center justify-between mb-3">
                <div className="font-bold text-sm text-[#1D1B16] flex items-center gap-2">
                  <FileText className="w-4 h-4 text-[#6750A4]" />
                  咨询前置诉求单
                </div>
                {relatedOrder?.intakeForm ? (
                  <span className="text-[10px] bg-emerald-50 text-emerald-700 px-2 py-1 rounded-md border border-emerald-200 flex items-center gap-1 font-semibold">
                    <CheckCircle2 className="w-3 h-3" /> 已填写
                  </span>
                ) : (
                  <span className="text-[10px] bg-[#FAF8F5] text-[#7A756C] px-2 py-1 rounded-md border border-[#E6E0D6]">未填写</span>
                )}
              </div>
              {relatedOrder?.intakeForm ? (
                <div className="bg-[#FAF8F5] rounded-[16px] p-3.5 space-y-3">
                  <div>
                    <div className="text-xs font-bold text-[#1D1B16] mb-1">诉求总结:</div>
                    <div className="text-xs text-[#49463D] leading-relaxed line-clamp-3">
                      {relatedOrder.intakeForm.primaryIssueDetail}
                    </div>
                  </div>
                  <div>
                    <div className="text-xs font-bold text-[#1D1B16] mb-1">咨询期望:</div>
                    <div className="text-xs text-[#49463D] leading-relaxed line-clamp-2">
                      {relatedOrder.intakeForm.expectations}
                    </div>
                  </div>
                  <div className="flex items-center gap-3 pt-2 border-t border-[#E6E0D6]">
                    <div className="text-[10px] text-[#7A756C]">过往经验: <strong className="text-[#1D1B16]">{relatedOrder.intakeForm.previousCounselingType || '无'}</strong></div>
                    <div className="text-[10px] text-[#7A756C] flex items-center gap-1">知情同意书: <CheckCircle2 className="w-3 h-3 text-emerald-600" /></div>
                  </div>
                </div>
              ) : (
                <div className="flex items-center justify-between bg-[#FAF8F5] rounded-[16px] p-3">
                  <span className="text-xs text-[#7A756C]">来访者尚未填写诉求单</span>
                  <button className="text-[11px] font-semibold text-[#6750A4] bg-white px-3 py-1.5 rounded-lg border border-[#E6E0D6] shadow-xs active:scale-95 transition">提醒填写</button>
                </div>
              )}
            </div>

          </div>
        )}

        {/* Tab 2: Counseling History & Working Notes */}
        {activeSubTab === 'history' && (
          <div className="relative max-w-full">
            {/* Vertical Timeline Line */}
            <div className="absolute left-[70px] top-[30px] bottom-0 w-[2px] bg-[#E8E2D5]"></div>
            
            <div className="space-y-6">
              {client.sessionLogs.length === 0 ? (
                <div className="bg-white p-8 rounded-[28px] shadow-[0_4px_20px_-4px_rgba(0,0,0,0.05)] border border-[#F2EFE9] text-center text-[#7A756C]">
                  <Clock className="w-8 h-8 text-[#E8E2D5] mx-auto mb-3" />
                  <span className="text-sm font-bold block text-[#1D1B16]">暂无过往咨询记录</span>
                  <span className="text-xs mt-1 block">本次预约将成为该来访者的第一条记录</span>
                </div>
              ) : (
                [...client.sessionLogs]
                  .sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime())
                  .map((log, index) => (
                  <div key={log.sessionNo} className="relative flex items-start gap-4">
                    {/* Timeline Left: Date & Year */}
                    <div className="w-[60px] text-right pt-2.5 shrink-0">
                      <div className="font-mono text-sm font-bold text-[#1D1B16]">
                        {log.date.substring(5)}
                      </div>
                      <div className="text-[10px] text-[#A09C94] font-medium mt-0.5">
                        {log.date.substring(0, 4)}
                      </div>
                    </div>
                    
                    {/* Timeline Center: Dot Indicator */}
                    <div className="relative mt-3 shrink-0 z-10 flex items-center justify-center w-[22px] h-[22px] bg-[#FAF8F5] rounded-full border-2 border-[#E8E2D5]">
                      <div className={`w-2.5 h-2.5 rounded-full ${index === 0 ? 'bg-[#6750A4]' : 'bg-[#A09C94]'}`}></div>
                    </div>
                    
                    {/* Timeline Right: Content Card */}
                    <div className="flex-1 bg-white p-5 rounded-[24px] shadow-[0_2px_12px_-4px_rgba(0,0,0,0.05)] border border-[#F2EFE9] hover:border-[#E8E2D5] transition-colors group">
                      <div className="flex items-center justify-between mb-3">
                        <span className="text-[10px] font-bold text-[#6750A4] bg-emerald-50 px-2 py-0.5 rounded border border-emerald-100">
                          第 {log.sessionNo} 次咨询
                        </span>
                        <span className="text-[10px] text-[#A09C94]">本机构咨询师</span>
                      </div>
                      
                      <div className="mb-3">
                        <div className="text-[10px] text-[#A09C94] mb-0.5">咨询主题</div>
                        <h4 className="text-sm font-bold text-[#1D1B16]">{log.topic}</h4>
                      </div>
                      
                      <div className="bg-[#FAF8F5] p-3.5 rounded-[16px] text-xs leading-relaxed group-hover:bg-[#F2EFE9] transition-colors">
                        <div className="text-[#A23F1E] font-bold mb-1.5 text-[10px] flex items-center gap-1">
                          <Sparkles className="w-3 h-3" /> 核心突破点
                        </div>
                        <div className="text-[#49463D] font-medium">
                          {log.keyBreakthrough}
                        </div>
                      </div>
                    </div>
                  </div>
                ))
              )}
            </div>
          </div>
        )}

        {/* Tab 3: Crisis Interventions */}
        {activeSubTab === 'checkins' && (
          <div className="relative max-w-full">
            {/* Vertical Timeline Line */}
            <div className="absolute left-[70px] top-[30px] bottom-0 w-[2px] bg-[#E8E2D5]"></div>
            
            <div className="space-y-6">
              {!client.crisisInterventions || client.crisisInterventions.length === 0 ? (
                <div className="bg-white p-8 rounded-[28px] shadow-[0_4px_20px_-4px_rgba(0,0,0,0.05)] border border-[#F2EFE9] text-center text-[#7A756C]">
                  <ShieldAlert className="w-8 h-8 text-[#E8E2D5] mx-auto mb-3" />
                  <span className="text-sm font-bold block text-[#1D1B16]">暂无危机干预记录</span>
                  <span className="text-xs mt-1 block">该来访者过往在平台未发生危机事件</span>
                </div>
              ) : (
                [...client.crisisInterventions]
                  .sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime())
                  .map((log, index) => (
                  <div key={log.id} className="relative flex items-start gap-4">
                    {/* Timeline Left: Date & Year */}
                    <div className="w-[60px] text-right pt-2.5 shrink-0">
                      <div className="font-mono text-sm font-bold text-[#1D1B16]">
                        {log.date.substring(5)}
                      </div>
                      <div className="text-[10px] text-[#A09C94] font-medium mt-0.5">
                        {log.date.substring(0, 4)}
                      </div>
                    </div>
                    
                    {/* Timeline Center: Dot Indicator */}
                    <div className="relative mt-3 shrink-0 z-10 flex items-center justify-center w-[22px] h-[22px] bg-[#FAF8F5] rounded-full border-2 border-[#E8E2D5]">
                      <div className={`w-2.5 h-2.5 rounded-full ${index === 0 ? 'bg-rose-600' : 'bg-[#A09C94]'}`}></div>
                    </div>
                    
                    {/* Timeline Right: Content Card */}
                    <div className="flex-1 bg-white p-5 rounded-[24px] shadow-[0_2px_12px_-4px_rgba(0,0,0,0.05)] border border-[#F2EFE9] hover:border-[#E8E2D5] transition-colors group">
                      <div className="flex items-center justify-between mb-3">
                        <span className={`text-[10px] font-bold px-2 py-0.5 rounded border ${
                          log.type === 'suicide_risk' ? 'bg-rose-50 text-rose-700 border-rose-200' :
                          log.type === 'self_harm' ? 'bg-amber-50 text-amber-700 border-amber-200' :
                          'bg-stone-50 text-stone-700 border-stone-200'
                        }`}>
                          {log.type === 'suicide_risk' ? '自杀风险' : log.type === 'self_harm' ? '自伤倾向' : '暴力/其他风险'}
                        </span>
                        <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full ${
                          log.status === 'resolved' ? 'text-emerald-700 bg-emerald-50' :
                          log.status === 'monitoring' ? 'text-amber-700 bg-amber-50' :
                          'text-blue-700 bg-blue-50'
                        }`}>
                          {log.status === 'resolved' ? '已解除' : log.status === 'monitoring' ? '监测中' : '已转介'}
                        </span>
                      </div>
                      
                      <div className="mb-3">
                        <div className="text-[10px] text-[#A09C94] mb-0.5">事件描述</div>
                        <h4 className="text-xs font-bold text-[#1D1B16] leading-relaxed">{log.description}</h4>
                      </div>
                      
                      <div className="bg-[#FAF8F5] p-3.5 rounded-[16px] text-xs leading-relaxed group-hover:bg-[#F2EFE9] transition-colors border border-[#F2EFE9]">
                        <div className="text-[#6750A4] font-bold mb-1.5 text-[10px] flex items-center gap-1">
                          <ShieldAlert className="w-3 h-3" /> 干预行动记录
                        </div>
                        <div className="text-[#49463D] font-medium">
                          {log.actionTaken}
                        </div>
                      </div>
                    </div>
                  </div>
                ))
              )}
            </div>
          </div>
        )}

      </div>

    </div>
  );
};
