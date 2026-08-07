export interface SessionSummaryInput {
  clientName?: string;
  rawNotes?: string;
  sessionTopic?: string;
  sessionNumber?: number;
}

export interface QuoteInput {
  topic?: string;
  consultantName?: string;
}

export type ValidationResult<T> =
  | { ok: true; value: T }
  | { ok: false; errors: string[] };

export interface RateLimitResult {
  allowed: boolean;
  retryAfterSeconds: number;
}

interface RateLimitEntry {
  count: number;
  windowStartedAt: number;
}

type JsonObject = Record<string, unknown>;

function isJsonObject(value: unknown): value is JsonObject {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function isOptionalStringWithin(value: unknown, maximumLength: number): value is string | undefined {
  return value === undefined || (typeof value === "string" && Array.from(value).length <= maximumLength);
}

export function validateSessionSummaryBody(body: unknown): ValidationResult<SessionSummaryInput> {
  if (!isJsonObject(body)) {
    return { ok: false, errors: ["request body must be a JSON object"] };
  }

  const errors: string[] = [];
  if (!isOptionalStringWithin(body.clientName, 100)) {
    errors.push("clientName must be a string with at most 100 characters");
  }
  if (!isOptionalStringWithin(body.rawNotes, 10_000)) {
    errors.push("rawNotes must be a string with at most 10000 characters");
  }
  if (!isOptionalStringWithin(body.sessionTopic, 200)) {
    errors.push("sessionTopic must be a string with at most 200 characters");
  }
  if (
    body.sessionNumber !== undefined
    && (!Number.isInteger(body.sessionNumber) || Number(body.sessionNumber) < 1 || Number(body.sessionNumber) > 999)
  ) {
    errors.push("sessionNumber must be an integer from 1 through 999");
  }

  if (errors.length > 0) return { ok: false, errors };

  const value: SessionSummaryInput = {};
  if (body.clientName !== undefined) value.clientName = body.clientName as string;
  if (body.rawNotes !== undefined) value.rawNotes = body.rawNotes as string;
  if (body.sessionTopic !== undefined) value.sessionTopic = body.sessionTopic as string;
  if (body.sessionNumber !== undefined) value.sessionNumber = body.sessionNumber as number;
  return { ok: true, value };
}

export function validateQuoteBody(body: unknown): ValidationResult<QuoteInput> {
  if (!isJsonObject(body)) {
    return { ok: false, errors: ["request body must be a JSON object"] };
  }

  const errors: string[] = [];
  if (!isOptionalStringWithin(body.topic, 500)) {
    errors.push("topic must be a string with at most 500 characters");
  }
  if (!isOptionalStringWithin(body.consultantName, 100)) {
    errors.push("consultantName must be a string with at most 100 characters");
  }

  if (errors.length > 0) return { ok: false, errors };

  const value: QuoteInput = {};
  if (body.topic !== undefined) value.topic = body.topic as string;
  if (body.consultantName !== undefined) value.consultantName = body.consultantName as string;
  return { ok: true, value };
}

export class FixedWindowRateLimiter {
  private readonly entries = new Map<string, RateLimitEntry>();

  constructor(
    private readonly maximumRequests: number,
    private readonly windowMilliseconds: number,
  ) {
    if (!Number.isInteger(maximumRequests) || maximumRequests < 1) {
      throw new Error("maximumRequests must be a positive integer");
    }
    if (!Number.isFinite(windowMilliseconds) || windowMilliseconds <= 0) {
      throw new Error("windowMilliseconds must be positive");
    }
  }

  check(key: string, now = Date.now()): RateLimitResult {
    for (const [storedKey, entry] of this.entries) {
      if (now - entry.windowStartedAt >= this.windowMilliseconds) {
        this.entries.delete(storedKey);
      }
    }

    const entry = this.entries.get(key);
    if (!entry) {
      this.entries.set(key, { count: 1, windowStartedAt: now });
      return { allowed: true, retryAfterSeconds: 0 };
    }

    if (entry.count >= this.maximumRequests) {
      const remainingMilliseconds = this.windowMilliseconds - (now - entry.windowStartedAt);
      return {
        allowed: false,
        retryAfterSeconds: Math.max(1, Math.ceil(remainingMilliseconds / 1_000)),
      };
    }

    entry.count += 1;
    return { allowed: true, retryAfterSeconds: 0 };
  }
}
