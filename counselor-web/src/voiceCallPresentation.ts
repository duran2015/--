export type MeetingState = "lobby" | "waiting" | "in-call" | "ended";

export type VoiceCallPresentation = {
  layout: "participant-cards" | "audio-call" | "video-call";
  otherParticipantJoined: boolean;
};

export function getVoiceCallPresentation(
  meetingState: MeetingState,
  isVideo: boolean,
): VoiceCallPresentation {
  const otherParticipantJoined = meetingState === "in-call";

  return {
    layout: otherParticipantJoined ? (isVideo ? "video-call" : "audio-call") : "participant-cards",
    otherParticipantJoined,
  };
}

export function getMeetingLayerClass(meetingState: MeetingState): string {
  return meetingState === "ended" ? "fixed inset-0" : "fixed inset-0";
}
