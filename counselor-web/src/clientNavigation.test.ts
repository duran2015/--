import assert from "node:assert/strict";
import test from "node:test";

import { getClientPrimaryTabs } from "./clientNavigation";

test("client bottom navigation exposes counselors as a first-class tab", () => {
  assert.deepEqual(getClientPrimaryTabs().map((tab) => tab.id), [
    "home",
    "ai",
    "counselors",
    "messages",
    "profile",
  ]);
  assert.equal(getClientPrimaryTabs().find((tab) => tab.id === "counselors")?.label, "真人咨询");
});
