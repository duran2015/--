import assert from "node:assert/strict";
import test from "node:test";

import { isKnownAppPath, resolveAppRoute } from "./routeResolution";

test("client paths resolve to the client application", () => {
  assert.equal(resolveAppRoute("/client"), "client");
  assert.equal(resolveAppRoute("/client/profile"), "client");
});

test("counselor paths resolve to the counselor application", () => {
  assert.equal(resolveAppRoute("/counselor"), "counselor");
  assert.equal(resolveAppRoute("/counselor/orders"), "counselor");
});

test("unknown paths use the counselor application fallback", () => {
  assert.equal(resolveAppRoute("/"), "counselor");
  assert.equal(resolveAppRoute("/unknown"), "counselor");
  assert.equal(isKnownAppPath("/unknown"), false);
});

test("lookalike prefixes are not treated as application paths", () => {
  assert.equal(isKnownAppPath("/clientele"), false);
  assert.equal(isKnownAppPath("/counselors"), false);
});
