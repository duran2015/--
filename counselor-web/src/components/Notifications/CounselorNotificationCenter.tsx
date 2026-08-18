import React, { useMemo, useState } from "react";
import {
  ArrowLeft,
  BellRing,
  BriefcaseBusiness,
  CalendarCheck,
  ChevronRight,
  CircleDollarSign,
  Megaphone,
  Settings,
  ShieldCheck,
  UsersRound,
} from "lucide-react";

type NotificationMessage = {
  id: string;
  title: string;
  body: string;
  time: string;
  actionLabel?: string;
  actionTarget?: string;
};

type NotificationChannel = {
  id: string;
  name: string;
  description: string;
  icon: React.ComponentType<{ size?: number; className?: string }>;
  tone: string;
  unread: number;
  messages: NotificationMessage[];
};

// Mock 推送后台配置。正式接入时整体替换为 GET /counselor/notification/channels。
const COUNSELOR_NOTIFICATION_CHANNELS: NotificationChannel[] = [
  {
    id: "workflow",
    name: "业务待办",
    description: "资料查阅、咨询与总结节点",
    icon: CalendarCheck,
    tone: "bg-emerald-100 text-emerald-700",
    unread: 2,
    messages: [
      {
        id: "wf-2",
        title: "咨询总结待确认",
        body: "与陈子健的咨询已结束，AI 草稿已生成，请确认后分享给来访者。",
        time: "今天 15:08",
        actionLabel: "确认总结",
        actionTarget: "summary:KL-000102",
      },
    ],
  },
  {
    id: "client",
    name: "来访者动态",
    description: "资料提交、评价与服务相关动态",
    icon: UsersRound,
    tone: "bg-sky-100 text-sky-700",
    unread: 1,
    messages: [
      {
        id: "cl-1",
        title: "咨询前资料已提交",
        body: "小鹿用户3821 已完成咨询前情况了解，可在订单中查看。",
        time: "今天 13:42",
        actionLabel: "查看资料",
        actionTarget: "client:3821",
      },
    ],
  },
  {
    id: "finance",
    name: "结算账户",
    description: "订单结算、退款、提现与账单变化",
    icon: CircleDollarSign,
    tone: "bg-amber-100 text-amber-700",
    unread: 1,
    messages: [
      {
        id: "fi-1",
        title: "一笔服务已完成结算",
        body: "订单 KL-000098 已结算 ¥299.00，可在收入明细中查看。",
        time: "昨天 18:30",
        actionLabel: "查看明细",
        actionTarget: "settlement:KL-000098",
      },
    ],
  },
  {
    id: "operation",
    name: "平台运营",
    description: "平台活动、课程培训与规则更新",
    icon: Megaphone,
    tone: "bg-purple-100 text-purple-700",
    unread: 0,
    messages: [
      {
        id: "op-1",
        title: "咨询师案例研讨开放报名",
        body: "本周五晚开展线上案例研讨，报名截止至明天 20:00。",
        time: "08月06日",
        actionLabel: "查看活动",
        actionTarget: "activity:case-review",
      },
    ],
  },
  {
    id: "compliance",
    name: "安全合规",
    description: "风险提示、隐私安全与平台审核",
    icon: ShieldCheck,
    tone: "bg-rose-100 text-rose-700",
    unread: 0,
    messages: [
      {
        id: "safe-1",
        title: "隐私与记录规范提醒",
        body: "请勿在个人设备中保存可识别来访者身份的咨询记录。",
        time: "08月04日",
        actionLabel: "查看规范",
        actionTarget: "policy:privacy",
      },
    ],
  },
];

const preferenceKey = (id: string) => `counselor-notification-channel-${id}`;

export function CounselorNotificationCenter({ onClose }: { onClose: () => void }) {
  const [view, setView] = useState<"list" | "detail" | "settings">("list");
  const [selectedId, setSelectedId] = useState(COUNSELOR_NOTIFICATION_CHANNELS[0].id);
  const [enabled, setEnabled] = useState<Record<string, boolean>>(() =>
    Object.fromEntries(
      COUNSELOR_NOTIFICATION_CHANNELS.map((channel) => [
        channel.id,
        localStorage.getItem(preferenceKey(channel.id)) !== "false",
      ]),
    ),
  );

  const selected = useMemo(
    () => COUNSELOR_NOTIFICATION_CHANNELS.find((item) => item.id === selectedId)!,
    [selectedId],
  );

  const toggleChannel = (id: string, value: boolean) => {
    setEnabled((current) => ({ ...current, [id]: value }));
    localStorage.setItem(preferenceKey(id), String(value));
  };

  const openChannel = (id: string) => {
    setSelectedId(id);
    setView("detail");
  };

  return (
    <section className="absolute inset-0 z-50 flex flex-col bg-[#F8F6F2] text-[#1D1B16]">
      <header className="shrink-0 border-b border-[#ECE6DC] bg-[#FAF8F5]/95 px-3 backdrop-blur-md">
        <div className="flex h-16 items-center">
          <button
            onClick={view === "list" ? onClose : () => setView("list")}
            className="grid h-11 w-11 place-items-center rounded-full hover:bg-[#EEE9E0] active:scale-95"
            aria-label="返回"
          >
            <ArrowLeft size={22} />
          </button>
          <div className="min-w-0 flex-1 text-center">
            <h1 className="truncate text-[18px] font-bold">
              {view === "settings" ? "消息通知管理" : view === "detail" ? selected.name : "消息中心"}
            </h1>
            {view === "detail" && <p className="truncate text-[11px] text-[#7A756C]">平台官方通知</p>}
          </div>
          {view === "list" ? (
            <button
              onClick={() => setView("settings")}
              className="grid h-11 w-11 place-items-center rounded-full hover:bg-[#EEE9E0] active:scale-95"
              aria-label="通知设置"
            >
              <Settings size={21} />
            </button>
          ) : view === "detail" ? (
            <button
              onClick={() => toggleChannel(selected.id, !enabled[selected.id])}
              className="grid h-11 w-11 place-items-center rounded-full hover:bg-[#EEE9E0] active:scale-95"
              aria-label={enabled[selected.id] ? "关闭该类通知" : "开启该类通知"}
            >
              <BellRing size={21} className={enabled[selected.id] ? "text-[#6750A4]" : "text-[#938F86]"} />
            </button>
          ) : <span className="h-11 w-11" />}
        </div>
      </header>

      {view === "list" && (
        <div className="flex-1 space-y-2.5 overflow-y-auto p-4 pb-8">
          {COUNSELOR_NOTIFICATION_CHANNELS.map((channel) => {
            const Icon = channel.icon;
            const latest = channel.messages[channel.messages.length - 1];
            const active = enabled[channel.id];
            return (
              <button
                key={channel.id}
                onClick={() => openChannel(channel.id)}
                className={`flex w-full items-center gap-3 rounded-[20px] border border-[#E8E2D8] p-4 text-left shadow-[0_1px_2px_rgba(47,43,35,.04)] transition active:scale-[.99] ${active ? "bg-white" : "bg-white/60"}`}
              >
                <span className={`relative grid h-12 w-12 shrink-0 place-items-center rounded-full ${channel.tone}`}>
                  <Icon size={23} />
                  {active && channel.unread > 0 && <span className="absolute -right-1 -top-1 grid min-h-5 min-w-5 place-items-center rounded-full border-2 border-white bg-[#BA1A1A] px-1 text-[10px] font-bold text-white">{channel.unread}</span>}
                </span>
                <span className="min-w-0 flex-1">
                  <span className="mb-1 flex items-center justify-between gap-3">
                    <strong className="text-[16px]">{channel.name}</strong>
                    <span className="shrink-0 text-[11px] text-[#938F86]">{latest.time}</span>
                  </span>
                  <span className="block truncate text-[13px] text-[#7A756C]">{active ? latest.body : "该类通知已关闭"}</span>
                </span>
                <ChevronRight size={18} className="shrink-0 text-[#938F86]" />
              </button>
            );
          })}
        </div>
      )}

      {view === "detail" && (
        <div className="flex-1 overflow-y-auto px-4 py-5">
          <div className="mb-5 text-center"><span className="rounded-full bg-[#777B7A] px-3 py-1.5 text-[11px] text-white">{enabled[selected.id] ? selected.description : "该类通知已关闭"}</span></div>
          <div className="space-y-5">
            {selected.messages.map((message) => {
              const Icon = selected.icon;
              return (
                <div key={message.id}>
                  <p className="mb-2 text-center text-[11px] text-[#938F86]">{message.time}</p>
                  <div className="flex items-start gap-2">
                    <span className={`grid h-9 w-9 shrink-0 place-items-center rounded-full ${selected.tone}`}><Icon size={18} /></span>
                    <article className="max-w-[82%] rounded-bl-[18px] rounded-br-[18px] rounded-tr-[18px] border border-[#E8E2D8] bg-white p-4">
                      <h2 className="text-[16px] font-bold">{message.title}</h2>
                      <p className="mt-1.5 text-[14px] leading-6 text-[#625F58]">{message.body}</p>
                      {message.actionLabel && (
                        <div className="mt-3 flex justify-end">
                          <button onClick={() => alert(`Mock 跳转：${message.actionTarget}`)} className="rounded-full bg-[#EADDFF] px-4 py-2 text-[12px] font-bold text-[#21005D] active:scale-95">{message.actionLabel}</button>
                        </div>
                      )}
                    </article>
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      )}

      {view === "settings" && (
        <div className="flex-1 overflow-y-auto p-4">
          <p className="mb-3 px-1 text-[13px] leading-5 text-[#625F58]">关闭后不再接收该类站内推送，业务状态仍可在订单与工作台查看。</p>
          <div className="overflow-hidden rounded-[22px] border border-[#E8E2D8] bg-white">
            {COUNSELOR_NOTIFICATION_CHANNELS.map((channel, index) => {
              const Icon = channel.icon;
              return (
                <div key={channel.id} className={`flex items-center gap-3 p-4 ${index ? "border-t border-[#EEE9E0]" : ""}`}>
                  <span className={`grid h-10 w-10 shrink-0 place-items-center rounded-full ${channel.tone}`}><Icon size={20} /></span>
                  <span className="min-w-0 flex-1"><strong className="block text-[15px]">{channel.name}</strong><span className="block truncate text-[12px] text-[#7A756C]">{channel.description}</span></span>
                  <button
                    role="switch"
                    aria-checked={enabled[channel.id]}
                    onClick={() => toggleChannel(channel.id, !enabled[channel.id])}
                    className={`relative h-8 w-13 shrink-0 rounded-full transition ${enabled[channel.id] ? "bg-[#6750A4]" : "bg-[#C9C5BD]"}`}
                  >
                    <span className={`absolute top-1 h-6 w-6 rounded-full bg-white shadow transition-all ${enabled[channel.id] ? "left-6" : "left-1"}`} />
                  </button>
                </div>
              );
            })}
          </div>
        </div>
      )}
    </section>
  );
}
