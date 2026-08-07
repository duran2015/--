import assert from "node:assert/strict";
import test from "node:test";

import { resolveMeetingClient } from "./meetingParticipant";

const fallback = { name: "默认用户", avatar: "default.jpg" };

test("meeting client prefers the order client profile over legacy fields", () => {
  assert.deepEqual(
    resolveMeetingClient(
      {
        clientName: "周明宇",
        clientAvatar: "client.jpg",
        userName: "旧姓名",
        avatar: "legacy.jpg",
      },
      fallback,
    ),
    { name: "周明宇", avatar: "client.jpg" },
  );
});

test("meeting client supports legacy counselor order fields", () => {
  assert.deepEqual(
    resolveMeetingClient(
      { userName: "旧版用户", avatar: "legacy.jpg" },
      fallback,
    ),
    { name: "旧版用户", avatar: "legacy.jpg" },
  );
});

test("meeting client ignores blank or malformed profile values", () => {
  assert.deepEqual(
    resolveMeetingClient(
      { clientName: "  ", clientAvatar: 42, userName: null, avatar: "" },
      fallback,
    ),
    fallback,
  );
  assert.deepEqual(resolveMeetingClient(null, fallback), fallback);
});
