export type MeetingParticipant = {
  name: string;
  avatar: string;
};

const isRecord = (value: unknown): value is Record<string, unknown> =>
  typeof value === "object" && value !== null;

const readText = (value: unknown) => {
  if (typeof value !== "string") return undefined;
  const normalized = value.trim();
  return normalized || undefined;
};

export function resolveMeetingClient(
  order: unknown,
  fallback: MeetingParticipant,
): MeetingParticipant {
  const candidate = isRecord(order) ? order : {};

  return {
    name:
      readText(candidate.clientName) ??
      readText(candidate.userName) ??
      fallback.name,
    avatar:
      readText(candidate.clientAvatar) ??
      readText(candidate.avatar) ??
      fallback.avatar,
  };
}
