import type { Order } from "./types";

export function hasIntakeData(order: Order): boolean {
  return Boolean(order.intakeForm || order.preQuestionnaire);
}
