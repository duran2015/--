import type { Order, WorkflowTask } from "./types";
import { hasIntakeData } from "./intakeData";

const phases = [
  { taskType: "confirm_booking", label: "确认预约" },
  { taskType: "review_intake", label: "查阅资料" },
  { taskType: "enter_session", label: "开始咨询" },
  { taskType: "complete_session_review", label: "确认总结" },
] as const;

type CounselorJourneyTaskType = (typeof phases)[number]["taskType"];

export type CounselorJourneyStepStatus = "completed" | "skipped" | "current" | "locked";

export type CounselorJourneyStep = {
  taskType: CounselorJourneyTaskType;
  label: string;
  status: CounselorJourneyStepStatus;
};

export type CounselorJourney = {
  order: Order;
  appointmentLabel: string;
  steps: CounselorJourneyStep[];
  currentTask: WorkflowTask;
};

const isPendingCounselorTask = (task: WorkflowTask) =>
  task.actorRole === "counselor" && (task.status === "pending" || task.status === "in_progress");

const shouldSkipIntakeReview = (order: Order, taskType: CounselorJourneyTaskType) =>
  taskType === "review_intake" && !hasIntakeData(order);

export function buildCounselorJourneys(
  orders: Order[],
  tasks: WorkflowTask[],
): CounselorJourney[] {
  return orders.flatMap((order) => {
    const orderTasks = tasks.filter(
      (task) => task.orderId === order.id && isPendingCounselorTask(task),
    );
    const currentPhaseIndex = phases.findIndex(
      (phase) =>
        !shouldSkipIntakeReview(order, phase.taskType) &&
        orderTasks.some((task) => task.taskType === phase.taskType),
    );

    if (currentPhaseIndex === -1) return [];

    const currentPhase = phases[currentPhaseIndex];
    const currentTask = orderTasks.find((task) => task.taskType === currentPhase.taskType);
    if (!currentTask) return [];

    return [{
      order,
      appointmentLabel: `${order.bookingDate} ${order.bookingTimeSlot}`,
      currentTask,
      steps: phases.map((phase, index) => ({
        ...phase,
        status:
          index === currentPhaseIndex
            ? "current"
            : index > currentPhaseIndex
              ? "locked"
              : shouldSkipIntakeReview(order, phase.taskType)
                ? "skipped"
                : "completed",
      })),
    }];
  });
}
