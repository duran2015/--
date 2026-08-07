import assert from "node:assert/strict";
import test from "node:test";

import { getMeetingLayerClass, getVoiceCallPresentation } from "./voiceCallPresentation";

test("video consultation switches to the active video layout after the other participant joins", () => {
  assert.deepEqual(getVoiceCallPresentation("waiting", true), {
    layout: "participant-cards",
    otherParticipantJoined: false,
  });
  assert.deepEqual(getVoiceCallPresentation("in-call", true), {
    layout: "video-call",
    otherParticipantJoined: true,
  });
});

test("audio consultation still uses its active-call visualization after joining", () => {
  assert.deepEqual(getVoiceCallPresentation("in-call", false), {
    layout: "audio-call",
    otherParticipantJoined: true,
  });
});

test("ended meeting remains fixed to the viewport like the active room", () => {
  assert.match(getMeetingLayerClass("ended"), /fixed/);
  assert.doesNotMatch(getMeetingLayerClass("ended"), /absolute/);
});
