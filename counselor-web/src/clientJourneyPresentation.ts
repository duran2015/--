import { hasIntakeData } from "./intakeData";
import type { ConsultationWorkflowState, Order } from "./types";

export type ClientPrimaryAction =
  | "pay"
  | "complete_intake"
  | "enter_session"
  | "wait_for_summary"
  | "read_summary"
  | "evaluate"
  | "view_summary"
  | "none";

export interface ClientJourneyPresentation {
  /** 仅表达订单交易/履约状态，禁止放入资料、回顾、评价等工作流事项。 */
  statusLabel: string;
  /** 当前工作流事项，可表达填写资料、等待回顾、评价等下一步。 */
  currentLabel: string;
  description: string;
  primaryAction: ClientPrimaryAction;
  actionLabel: string;
  canCancel: boolean;
  canContact: boolean;
  canEvaluate: boolean;
}

export function isStructuredEvaluationComplete(value: { feltUnderstood: boolean | null; wasHelpful: boolean | null }): boolean {
  return value.feltUnderstood !== null && value.wasHelpful !== null;
}

export function getClientJourneyPresentation(
  order: Order,
  workflow: ConsultationWorkflowState,
): ClientJourneyPresentation {
  const status = order.status as string;
  const orderTasks = workflow.tasks.filter((task) => task.orderId === order.id && task.actorRole === "client");
  const intakeTask = orderTasks.find((task) => task.taskType === "complete_intake");
  const recapTask = orderTasks.find((task) => task.taskType === "read_session_recap");
  const reviewTask = orderTasks.find((task) => task.taskType === "review_counselor");
  const hasSharedSummary = Boolean(order.hasSummary) || workflow.messages.some(
    (message) => message.orderId === order.id && message.audience === "client" && message.status === "shared",
  );
  const evaluated = Boolean((order as Order & { isEvaluated?: boolean }).isEvaluated) || reviewTask?.status === "completed";

  if (status === "pending" || status === "pending_confirm") {
    return {
      statusLabel: status === "pending" ? "待支付" : "待咨询师确认",
      currentLabel: status === "pending" ? "请完成支付" : "预约申请已提交",
      description: status === "pending" ? "完成支付后将为你保留预约时段。" : "咨询师确认后会通过消息通知你。",
      primaryAction: status === "pending" ? "pay" : "none",
      actionLabel: status === "pending" ? "继续支付" : "等待确认",
      canCancel: true, canContact: false, canEvaluate: false,
    };
  }

  if (["paid", "scheduled", "in_progress"].includes(status)) {
    const intakeDone = intakeTask?.status === "completed" || hasIntakeData(order);
    if (!intakeDone && status !== "in_progress") {
      return {
        statusLabel: "待咨询", currentLabel: "咨询前资料待填写",
        description: "资料为选填，但填写后能帮助咨询师提前了解你的情况。",
        primaryAction: "complete_intake", actionLabel: "填写咨询前资料",
        canCancel: true, canContact: true, canEvaluate: false,
      };
    }
    return {
      statusLabel: status === "in_progress" ? "咨询中" : "待咨询",
      currentLabel: status === "in_progress" ? "返回咨询室" : "等待开始咨询",
      description: status === "in_progress" ? "本次咨询仍在进行中。" : "咨询室将在预约开始前 10 分钟开放。",
      primaryAction: "enter_session", actionLabel: status === "in_progress" ? "返回咨询室" : "进入咨询室",
      canCancel: status !== "in_progress", canContact: true, canEvaluate: false,
    };
  }

  if (status === "completed") {
    if (!hasSharedSummary) {
      return {
        statusLabel: "已完成", currentLabel: "咨询师正在整理回顾",
        description: "咨询师确认后，回顾会通过消息发送给你。",
        primaryAction: "wait_for_summary", actionLabel: "等待咨询师确认",
        canCancel: false, canContact: true, canEvaluate: false,
      };
    }
    if (recapTask && recapTask.status !== "completed") {
      return {
        statusLabel: "已完成", currentLabel: "咨询回顾待查看",
        description: "先查看咨询师确认的回顾和行动建议，再完成评价。",
        primaryAction: "read_summary", actionLabel: "查看咨询回顾",
        canCancel: false, canContact: true, canEvaluate: false,
      };
    }
    if (!evaluated) {
      return {
        statusLabel: "已完成", currentLabel: "服务待评价",
        description: "你的反馈会帮助咨询师持续改进服务。",
        primaryAction: "evaluate", actionLabel: "评价咨询师",
        canCancel: false, canContact: true, canEvaluate: true,
      };
    }
    return {
      statusLabel: "已完成", currentLabel: "本次服务已完成",
      description: "咨询回顾和评价已归档。",
      primaryAction: "view_summary", actionLabel: "查看咨询回顾",
      canCancel: false, canContact: true, canEvaluate: false,
    };
  }

  const cancelled = status === "cancelled" || status === "refunded";
  return {
    statusLabel: cancelled ? (status === "refunded" ? "已退款" : "已取消") : "订单异常",
    currentLabel: cancelled ? "本次预约已结束" : "订单暂不可用",
    description: cancelled ? "如仍需要支持，可以重新预约咨询师。" : "请联系平台客服查看订单状态。",
    primaryAction: "none", actionLabel: "重新预约",
    canCancel: false, canContact: false, canEvaluate: false,
  };
}
