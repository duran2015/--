import { useEffect, useMemo, useState } from "react";
import {
  AlertCircle,
  ArrowLeft,
  Check,
  CheckCircle2,
  ChevronRight,
  ClipboardCheck,
  FileLock2,
  LockKeyhole,
  MessageSquareText,
  Save,
  Send,
  Sparkles,
  UserRound,
  X,
  History
} from "lucide-react";

import { useAppStore } from "../../client-app/store";
import { getReviewProgress } from "../../sessionReviewPresentation";
import type { SessionReviewDraft, SessionInsight } from "../../types";

type ReviewTab = "evidence" | "clinical" | "client";

interface SessionReviewWorkspaceProps {
  draftId: string;
  onClose: () => void;
  onSubmitted?: () => void;
}

const tabItems: Array<{ id: ReviewTab; label: string; shortLabel: string }> = [
  { id: "evidence", label: "AI 证据", shortLabel: "证据" },
  { id: "clinical", label: "临床总结", shortLabel: "临床" },
  { id: "client", label: "用户回顾", shortLabel: "分享" },
];

// M3 Outlined Text Field
const Field = ({
  label,
  value,
  onChange,
  placeholder,
  rows = 3,
  disabled,
  hint,
}: {
  label: string;
  value: string;
  onChange: (value: string) => void;
  placeholder?: string;
  rows?: number;
  disabled?: boolean;
  hint?: string;
}) => (
  <div className="relative mt-4">
    <div className="relative">
      <textarea
        value={value}
        onChange={(event) => onChange(event.target.value)}
        placeholder={placeholder}
        rows={rows}
        disabled={disabled}
        className="peer w-full rounded-[16px] border border-[#79747E] bg-transparent px-4 py-4 text-[15px] leading-relaxed text-[#1D1B20] outline-none transition-all placeholder:text-transparent focus:border-2 focus:border-[#6750A4] focus:px-[15px] focus:py-[15px] disabled:border-[#1D1B20]/10 disabled:text-[#1D1B20]/38 disabled:bg-[#1D1B20]/4"
      />
      <label className={`pointer-events-none absolute left-3 top-0 -translate-y-1/2 bg-[#FFFBFE] px-1 text-[12px] transition-all peer-placeholder-shown:top-6 peer-placeholder-shown:text-[15px] peer-focus:top-0 peer-focus:text-[12px] peer-focus:font-bold peer-focus:text-[#6750A4] ${value ? 'text-[#49454F] font-bold' : 'text-[#49454F]'}`}>
        {label}
      </label>
    </div>
    {hint && <p className="mt-1 pl-4 text-[11px] text-[#49454F]">{hint}</p>}
  </div>
);

const EvidenceCard = ({
  insight,
  active,
  onClick,
}: {
  insight: SessionInsight;
  active: boolean;
  onClick: () => void;
}) => {
  const categoryLabel = {
    topic: "核心议题",
    emotion: "情绪线索",
    intervention: "干预效果",
    risk: "风险观察",
    plan: "后续计划",
  }[insight.category];
  
  return (
    <button
      type="button"
      onClick={onClick}
      className={`w-full rounded-[24px] p-4 text-left transition-all ${
        active
          ? "bg-[#EADDFF] text-[#21005D]" // Primary Container
          : "bg-[#F3EDF7] text-[#1D1B20] hover:bg-[#E8DEF8]" // Surface Container High
      }`}
    >
      <div className="flex items-start justify-between gap-3">
        <div>
          <div className={`mb-2 inline-flex rounded-full px-2.5 py-1 text-[11px] font-bold ${active ? "bg-[#21005D] text-[#EADDFF]" : "bg-[#EADDFF] text-[#21005D]"}`}>
            {categoryLabel}
          </div>
          <h3 className="text-[15px] font-bold">{insight.title}</h3>
        </div>
        <span className={`shrink-0 text-[11px] font-bold ${active ? "text-[#21005D]" : "text-[#6750A4]"}`}>
          {Math.round(insight.confidence * 100)}% 匹配
        </span>
      </div>
      <p className={`mt-2 text-[13px] leading-relaxed ${active ? "text-[#21005D]/80" : "text-[#49454F]"}`}>{insight.detail}</p>
      <div className={`mt-3 flex items-center gap-1 text-[11px] font-bold ${active ? "text-[#21005D]" : "text-[#6750A4]"}`}>
        溯源 {insight.sourceIds.length} 条原文 <ChevronRight size={14} />
      </div>
    </button>
  );
};

export function SessionReviewWorkspace({ draftId, onClose, onSubmitted }: SessionReviewWorkspaceProps) {
  const {
    consultationWorkflow,
    orders,
    saveSessionReview,
    submitSessionReview,
  } = useAppStore();
  
  const storedDraft = consultationWorkflow.reviewDrafts.find((item) => item.id === draftId);
  const [draft, setDraft] = useState<SessionReviewDraft | null>(storedDraft || null);
  const [activeTab, setActiveTab] = useState<ReviewTab>("clinical");
  const [selectedInsightId, setSelectedInsightId] = useState<string | null>(null);
  const [showSubmitDialog, setShowSubmitDialog] = useState(false);
  const [feedback, setFeedback] = useState("");

  useEffect(() => {
    if (storedDraft) setDraft(storedDraft);
  }, [storedDraft?.version, storedDraft?.status]);

  const snapshot = storedDraft
    ? consultationWorkflow.snapshots[storedDraft.sessionId]
    : undefined;
  const order = storedDraft
    ? orders.find((item) => item.id === storedDraft.orderId)
    : undefined;
    
  const isSubmitted = draft?.status === "submitted";
  const progress = draft ? getReviewProgress(draft) : null;
  const selectedInsight = snapshot?.insights.find((item) => item.id === selectedInsightId);
  const selectedSourceIds = useMemo(
    () => new Set(selectedInsight?.sourceIds || []),
    [selectedInsight],
  );

  if (!draft || !storedDraft) {
    return (
      <div className="fixed inset-0 z-[300] grid place-items-center bg-[#F3EDF7] p-6">
        <div className="rounded-[28px] bg-[#FFFBFE] p-8 text-center shadow-lg">
          <AlertCircle className="mx-auto text-[#BA1A1A]" size={32} />
          <p className="mt-4 text-[16px] font-bold text-[#1D1B20]">未找到本次咨询总结</p>
          <button onClick={onClose} className="mt-6 rounded-full bg-[#6750A4] px-6 py-2.5 text-[14px] font-bold text-white shadow-md active:scale-95 transition-transform">
            返回工作台
          </button>
        </div>
      </div>
    );
  }

  const updateClinical = (patch: Partial<SessionReviewDraft["clinicalSummary"]>) =>
    setDraft((current) =>
      current
        ? { ...current, clinicalSummary: { ...current.clinicalSummary, ...patch } }
        : current,
    );
  const updateClient = (patch: Partial<SessionReviewDraft["clientSummary"]>) =>
    setDraft((current) =>
      current ? { ...current, clientSummary: { ...current.clientSummary, ...patch } } : current,
    );
    
  const handleSave = () => {
    saveSessionReview(draft.id, {
      clinicalSummary: draft.clinicalSummary,
      clientSummary: draft.clientSummary,
    });
    setFeedback("草稿已保存，随时可继续编辑");
    window.setTimeout(() => setFeedback(""), 2200);
  };

  const handleSubmit = () => {
    const result = submitSessionReview(draft.id, {
      clinicalSummary: draft.clinicalSummary,
      clientSummary: draft.clientSummary,
    });
    if (!result.ok) {
      setFeedback(result.errors.join("；"));
      setShowSubmitDialog(false);
      return;
    }
    setShowSubmitDialog(false);
    setFeedback("总结已归档，用户回顾已发送，T+1 结算已解锁");
    onSubmitted?.();
  };

  return (
    <div className="fixed inset-0 z-[300] flex justify-center bg-[#1D1B20]/40 sm:p-4 backdrop-blur-sm transition-all">
      <div className="relative flex h-full w-full max-w-2xl flex-col overflow-hidden bg-[#F3EDF7] sm:rounded-[32px] sm:shadow-2xl">
        
        {/* M3 Top App Bar (Center Aligned) */}
        <header className="shrink-0 bg-[#F3EDF7] px-4 pb-4 pt-[max(16px,env(safe-area-inset-top))]">
          <div className="relative flex items-center justify-center">
            <button onClick={onClose} aria-label="返回" className="absolute left-0 grid h-12 w-12 place-items-center rounded-full text-[#1D1B20] hover:bg-[#E8DEF8] active:bg-[#E8DEF8] transition-colors">
              <ArrowLeft size={24} />
            </button>
            <h1 className="text-[20px] font-bold text-[#1D1B20]">咨询总结与回顾</h1>
            <div className="absolute right-0">
              <span className={`rounded-full px-3 py-1 text-[12px] font-bold ${isSubmitted ? "bg-[#163723]/10 text-[#163723]" : "bg-[#EADDFF] text-[#21005D]"}`}>
                {isSubmitted ? "已归档" : "撰写中"}
              </span>
            </div>
          </div>
          
          <div className="mt-6 flex flex-col items-center justify-center gap-1">
            <div className="text-[13px] text-[#49454F] font-medium">
              {order?.clientName} · {order?.bookingDate}
            </div>
            <div className="flex items-center gap-2 w-full max-w-[200px] mt-2">
              <div className="flex-1 h-1.5 overflow-hidden rounded-full bg-[#E8DEF8]">
                <div className="h-full rounded-full bg-[#6750A4] transition-all" style={{ width: `${progress?.percentage || 0}%` }} />
              </div>
              <span className="text-[12px] font-bold text-[#6750A4]">{progress?.percentage}%</span>
            </div>
          </div>
        </header>

        {/* M3 Segmented Button / Tabs */}
        <div className="px-4 pb-2">
          <div className="flex w-full rounded-full border border-[#79747E] overflow-hidden bg-transparent h-10">
            {tabItems.map((tab, idx) => (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id)}
                className={`flex-1 flex items-center justify-center text-[13px] font-bold transition-colors ${
                  activeTab === tab.id 
                    ? "bg-[#E8DEF8] text-[#1D1B20]" 
                    : "text-[#49454F] hover:bg-[#1D1B20]/5"
                } ${idx !== tabItems.length - 1 ? "border-r border-[#79747E]" : ""}`}
              >
                {activeTab === tab.id && <Check size={16} className="mr-1.5" />}
                {tab.label}
              </button>
            ))}
          </div>
        </div>

        {/* Status Banner */}
        <div className="px-4 pb-2">
          <div className={`flex items-start gap-3 rounded-[24px] p-4 ${isSubmitted ? "bg-[#C4EED0] text-[#163723]" : "bg-[#EADDFF] text-[#21005D]"}`}>
            {isSubmitted ? <CheckCircle2 className="shrink-0 mt-0.5" size={20} /> : <LockKeyhole className="shrink-0 mt-0.5" size={20} />}
            <div>
              <p className="text-[14px] font-bold">
                {isSubmitted ? "总结已归档 · T+1 结算已解锁" : "待完成总结 · 本单结算暂锁定"}
              </p>
              <p className="mt-1 text-[12px] opacity-80 leading-relaxed">
                {isSubmitted ? "用户仅收到“用户回顾”内容，内部临床记录不会对外展示。" : "保存草稿不会发送给用户；正式提交后将同步 IM 卡片并进入结算。"}
              </p>
            </div>
          </div>
        </div>

        {/* Main Content Area */}
        <main className="flex-1 overflow-y-auto px-4 pb-32">
          {/* TAB 1: 临床总结 */}
          {activeTab === "clinical" && (
            <div className="space-y-4 pt-2">
              <div className="rounded-[28px] bg-[#FFFBFE] p-5 shadow-sm">
                <div className="flex items-center gap-2 text-[#6750A4] mb-4">
                  <FileLock2 size={20} />
                  <h2 className="text-[16px] font-bold text-[#1D1B20]">内部临床记录</h2>
                </div>
                <p className="text-[13px] text-[#49454F] mb-6">仅咨询师及获授权的专业支持角色可见，绝不会通过用户 IM 分享，请放心客观记录。</p>
                
                <div className="space-y-5">
                  <Field label="主诉与核心议题" value={draft.clinicalSummary.mainConcern} onChange={(value) => updateClinical({ mainConcern: value })} disabled={isSubmitted} />
                  <Field label="来访者精神与情绪状态" value={draft.clinicalSummary.clientState} onChange={(value) => updateClinical({ clientState: value })} disabled={isSubmitted} />
                  <Field label="本次采用的干预方式" hint="每行一项，支持多项" value={draft.clinicalSummary.interventions.join("\n")} onChange={(value) => updateClinical({ interventions: value.split("\n").map((item) => item.trim()).filter(Boolean) })} disabled={isSubmitted} />
                  <Field label="咨询师专业观察" value={draft.clinicalSummary.observations} onChange={(value) => updateClinical({ observations: value })} disabled={isSubmitted} />
                  <Field label="风险排查复核" hint="如有自伤/他伤等风险，请详述" value={draft.clinicalSummary.riskReview} onChange={(value) => updateClinical({ riskReview: value })} disabled={isSubmitted} />
                  <Field label="后续咨询计划" value={draft.clinicalSummary.nextPlan} onChange={(value) => updateClinical({ nextPlan: value })} disabled={isSubmitted} />
                </div>
              </div>
            </div>
          )}

          {/* TAB 2: 用户回顾 */}
          {activeTab === "client" && (
            <div className="space-y-4 pt-2">
              <div className="rounded-[28px] bg-[#FFFBFE] p-5 shadow-sm">
                <div className="flex items-center gap-2 text-[#25683B] mb-4">
                  <UserRound size={20} />
                  <h2 className="text-[16px] font-bold text-[#1D1B20]">对外分享回顾</h2>
                </div>
                <p className="text-[13px] text-[#49454F] mb-6">正式提交后将作为消息卡片发送给用户。请使用温暖、支持性且避免病理化标签的表达。</p>
                
                <div className="space-y-5">
                  <Field label="写给用户的寄语/回顾" value={draft.clientSummary.recap} onChange={(value) => updateClient({ recap: value })} disabled={isSubmitted} rows={4} />
                  <Field label="推荐会后行动" hint="每行一项，可作为作业" value={draft.clientSummary.actionItems.join("\n")} onChange={(value) => updateClient({ actionItems: value.split("\n").map((item) => item.trim()).filter(Boolean) })} disabled={isSubmitted} />
                  <Field label="下次探讨方向" value={draft.clientSummary.nextPlan} onChange={(value) => updateClient({ nextPlan: value })} disabled={isSubmitted} />
                </div>
              </div>

              {/* IM 卡片预览 - M3 Card */}
              <div className="rounded-[28px] border border-[#CAC4D0] bg-[#FFFBFE] p-5">
                <h3 className="mb-4 flex items-center gap-2 text-[14px] font-bold text-[#49454F]">
                  <MessageSquareText size={18} /> IM 卡片预览效果
                </h3>
                <div className="rounded-[24px] bg-[#F3EDF7] p-5">
                  <div className="text-[12px] font-bold text-[#6750A4]">来自林木青咨询师</div>
                  <div className="mt-1 text-[16px] font-bold text-[#1D1B20]">本次咨询回顾</div>
                  <p className="mt-3 line-clamp-3 text-[13px] leading-relaxed text-[#49454F] italic">
                    “{draft.clientSummary.recap || "暂无寄语..."}”
                  </p>
                  <div className="mt-4 flex items-center justify-between border-t border-[#CAC4D0] pt-4 text-[13px] font-bold text-[#6750A4]">
                    <span>查看完整回顾与作业</span>
                    <ChevronRight size={16} />
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* TAB 3: AI 证据 */}
          {activeTab === "evidence" && (
            <div className="space-y-4 pt-2">
              <div className="rounded-[28px] bg-[#FFFBFE] p-5 shadow-sm">
                <div className="flex items-center gap-2 text-[#6750A4] mb-4">
                  <Sparkles size={20} />
                  <h2 className="text-[16px] font-bold text-[#1D1B20]">AI 智能洞察与溯源</h2>
                </div>
                <p className="text-[13px] text-[#49454F] mb-6">AI 基于全程语音转录生成的辅助线索。点击卡片可查看原文来源。</p>
                
                <div className="space-y-3">
                  {snapshot?.insights.map((insight) => (
                    <EvidenceCard key={insight.id} insight={insight} active={selectedInsightId === insight.id} onClick={() => setSelectedInsightId(selectedInsightId === insight.id ? null : insight.id)} />
                  ))}
                </div>
              </div>

              {/* 实时转录与笔记区域 */}
              <div className="rounded-[28px] bg-[#FFFBFE] p-5 shadow-sm space-y-6">
                <div>
                  <h3 className="mb-4 flex items-center justify-between text-[15px] font-bold text-[#1D1B20]">
                    <span className="flex items-center gap-2"><History size={18} className="text-[#6750A4]" />语音转录记录</span>
                    <span className="text-[12px] font-medium text-[#79747E] bg-[#F3EDF7] px-2 py-0.5 rounded-full">{snapshot?.transcript.length || 0} 条</span>
                  </h3>
                  <div className="space-y-3">
                    {snapshot?.transcript.map((segment) => (
                      <div key={segment.id} className={`rounded-[16px] p-4 transition-all ${selectedSourceIds.has(segment.id) ? "bg-[#EADDFF] border border-[#6750A4]" : "bg-[#F3EDF7] border border-transparent"}`}>
                        <div className="flex items-center justify-between text-[11px] mb-2">
                          <span className={`font-bold ${selectedSourceIds.has(segment.id) ? "text-[#21005D]" : "text-[#49454F]"}`}>{segment.speakerName}</span>
                          <span className={selectedSourceIds.has(segment.id) ? "text-[#21005D]/70" : "text-[#79747E]"}>{Math.floor(segment.startsAtSeconds / 60).toString().padStart(2, "0")}:{(segment.startsAtSeconds % 60).toString().padStart(2, "0")}</span>
                        </div>
                        <p className={`text-[13px] leading-relaxed ${selectedSourceIds.has(segment.id) ? "text-[#21005D]" : "text-[#1D1B20]"}`}>{segment.text}</p>
                      </div>
                    ))}
                  </div>
                </div>

                <div className="border-t border-[#CAC4D0] pt-6">
                  <h3 className="mb-4 flex items-center gap-2 text-[15px] font-bold text-[#1D1B20]">
                    <ClipboardCheck size={18} className="text-[#6750A4]" />咨询师随手记
                  </h3>
                  <div className="space-y-3">
                    {snapshot?.notes.map((note) => (
                      <div key={note.id} className={`rounded-[16px] p-4 text-[13px] leading-relaxed ${selectedSourceIds.has(note.id) ? "bg-[#EADDFF] border border-[#6750A4] text-[#21005D]" : "bg-[#FFF8E7] border border-[#FFDDB3] text-[#5D3A00]"}`}>
                        {note.text}
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            </div>
          )}
        </main>

        {/* M3 Bottom App Bar / Floating Actions */}
        <footer className="absolute inset-x-0 bottom-0 bg-[#F3EDF7] px-4 pb-[max(16px,env(safe-area-inset-bottom))] pt-3 shadow-[0_-4px_20px_rgba(0,0,0,0.05)]">
          {feedback && (
            <div className="absolute bottom-full left-4 right-4 mb-4 flex justify-center pointer-events-none">
              <div className="bg-[#313033] text-[#F4EFF4] px-4 py-3 rounded-[8px] text-[14px] shadow-lg max-w-sm w-full text-center">
                {feedback}
              </div>
            </div>
          )}
          
          {isSubmitted ? (
            <button onClick={onClose} className="w-full h-14 rounded-full bg-[#6750A4] text-[15px] font-bold text-white shadow-md active:scale-95 transition-transform flex items-center justify-center gap-2">
              <Check size={20} /> 完成查阅并返回
            </button>
          ) : (
            <div className="flex gap-3">
              <button onClick={handleSave} className="flex-1 h-14 rounded-full border border-[#79747E] text-[14px] font-bold text-[#6750A4] active:bg-[#E8DEF8] transition-colors flex items-center justify-center gap-2">
                <Save size={18} /> 保存草稿
              </button>
              <button onClick={() => setShowSubmitDialog(true)} className="flex-[1.5] h-14 rounded-full bg-[#6750A4] text-[14px] font-bold text-white shadow-md active:scale-95 transition-transform flex items-center justify-center gap-2">
                <Send size={18} /> 提交总结与反馈
              </button>
            </div>
          )}
        </footer>

        {/* M3 Standard Basic Dialog */}
        {showSubmitDialog && (
          <div className="absolute inset-0 z-[400] flex items-center justify-center bg-[#1D1B20]/40 p-4 backdrop-blur-sm">
            <div className="w-full max-w-[320px] rounded-[28px] bg-[#FFFBFE] p-6 shadow-2xl animate-in zoom-in-95 duration-200">
              <div className="mx-auto mb-4 grid h-12 w-12 place-items-center rounded-full bg-[#EADDFF] text-[#6750A4]">
                <Send size={24} />
              </div>
              <h2 className="text-center text-[24px] font-normal text-[#1D1B20] mb-4">确认提交总结？</h2>
              <p className="text-[14px] leading-relaxed text-[#49454F] mb-6">
                提交后内部临床记录将永久归档，用户回顾卡片将立即通过 IM 推送。本单也将进入 T+1 财务可结算状态。
              </p>
              
              <div className="flex flex-col gap-2">
                <button onClick={handleSubmit} className="w-full h-10 rounded-full bg-[#6750A4] text-[14px] font-bold text-white transition-colors">
                  确认提交
                </button>
                <button onClick={() => setShowSubmitDialog(false)} className="w-full h-10 rounded-full text-[14px] font-bold text-[#6750A4] hover:bg-[#1D1B20]/5 transition-colors">
                  继续检查草稿
                </button>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}