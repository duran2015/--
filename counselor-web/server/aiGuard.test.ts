import assert from "node:assert/strict";
import test from "node:test";

import {
  FixedWindowRateLimiter,
  validateQuoteBody,
  validateSessionSummaryBody,
} from "./aiGuard";

test("session summary accepts boundary values and ignores unknown fields", () => {
  const body = {
    clientName: "a".repeat(100),
    rawNotes: "b".repeat(10_000),
    sessionTopic: "c".repeat(200),
    sessionNumber: 999,
    ignored: "value",
  };

  assert.deepEqual(validateSessionSummaryBody(body), {
    ok: true,
    value: {
      clientName: body.clientName,
      rawNotes: body.rawNotes,
      sessionTopic: body.sessionTopic,
      sessionNumber: body.sessionNumber,
    },
  });
});

test("session summary rejects invalid known fields", () => {
  const result = validateSessionSummaryBody({
    clientName: 1,
    rawNotes: "x".repeat(10_001),
    sessionTopic: false,
    sessionNumber: 0,
  });

  assert.equal(result.ok, false);
  if (!result.ok) {
    assert.deepEqual(result.errors, [
      "clientName must be a string with at most 100 characters",
      "rawNotes must be a string with at most 10000 characters",
      "sessionTopic must be a string with at most 200 characters",
      "sessionNumber must be an integer from 1 through 999",
    ]);
  }
});

test("session summary rejects non-object bodies", () => {
  for (const body of [null, [], "text", 1]) {
    assert.deepEqual(validateSessionSummaryBody(body), {
      ok: false,
      errors: ["request body must be a JSON object"],
    });
  }
});

test("quote accepts omitted fields and maximum lengths", () => {
  assert.deepEqual(validateQuoteBody({}), { ok: true, value: {} });
  assert.equal(
    validateQuoteBody({ topic: "a".repeat(500), consultantName: "b".repeat(100) }).ok,
    true,
  );
});

test("quote rejects invalid fields", () => {
  const result = validateQuoteBody({ topic: "a".repeat(501), consultantName: 1 });

  assert.equal(result.ok, false);
  if (!result.ok) {
    assert.deepEqual(result.errors, [
      "topic must be a string with at most 500 characters",
      "consultantName must be a string with at most 100 characters",
    ]);
  }
});

test("fixed-window limiter permits ten requests and rejects request eleven", () => {
  const limiter = new FixedWindowRateLimiter(10, 60_000);

  for (let index = 0; index < 10; index += 1) {
    assert.deepEqual(limiter.check("127.0.0.1", 1_000), {
      allowed: true,
      retryAfterSeconds: 0,
    });
  }

  assert.deepEqual(limiter.check("127.0.0.1", 1_000), {
    allowed: false,
    retryAfterSeconds: 60,
  });
});

test("fixed-window limiter isolates keys and resets expired windows", () => {
  const limiter = new FixedWindowRateLimiter(1, 60_000);

  assert.equal(limiter.check("first", 1_000).allowed, true);
  assert.equal(limiter.check("first", 60_999).allowed, false);
  assert.equal(limiter.check("second", 60_999).allowed, true);
  assert.equal(limiter.check("first", 61_000).allowed, true);
});

test("fixed-window limiter rounds retry seconds up", () => {
  const limiter = new FixedWindowRateLimiter(1, 60_000);

  limiter.check("ip", 1_000);
  assert.deepEqual(limiter.check("ip", 1_001), {
    allowed: false,
    retryAfterSeconds: 60,
  });
  assert.deepEqual(limiter.check("ip", 60_001), {
    allowed: false,
    retryAfterSeconds: 1,
  });
});
