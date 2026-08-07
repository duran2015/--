import assert from "node:assert/strict";
import test from "node:test";

import { isKnownAppPath } from "./routeResolution";

test("counselor paths stay in the counselor application", () => {
  assert.equal(isKnownAppPath("/counselor"), true);
  assert.equal(isKnownAppPath("/counselor/orders"), true);
});

test("unknown paths use the counselor application fallback", () => {
  assert.equal(isKnownAppPath("/"), false);
  assert.equal(isKnownAppPath("/unknown"), false);
});

test("lookalike prefixes are not treated as application paths", () => {
  assert.equal(isKnownAppPath("/clientele"), false);
  assert.equal(isKnownAppPath("/client"), false);
  assert.equal(isKnownAppPath("/counselors"), false);
});
