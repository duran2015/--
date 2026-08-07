# Stabilize and Secure Local Deployment Design

## Goal

Make the existing Kelu application type-safe, free of known React DOM errors and one-time patch artifacts, clear the current dependency audit warning, and protect the two AI endpoints with basic single-process request controls without unrelated product changes.

## Scope

The implementation will:

- delete the committed one-time scripts `fix-client-app.cjs` and `patch*.cjs`;
- make `npm run lint` type-check the maintained TypeScript source successfully;
- fix the nested interactive controls on the client login agreement row while preserving agreement toggling and legal-document navigation;
- remove `react-router-dom` after current audit data showed no clean v6/v7 release, replacing its three-route usage with a tested pathname resolver;
- add in-process rate limiting and structured input validation to `/api/ai/session-summary` and `/api/ai/generate-quote`;
- stop exposing internal exception messages in API responses; and
- update README dependency versions when they differ from `package.json`.

The implementation will not add authentication, Redis, distributed rate limiting, bundle splitting, UI redesign, or unrelated refactoring.

## Architecture

Request-control logic will live in a small server-side module separate from `server.ts`. It will expose pure validation functions and a fixed-window rate-limiter class so the behavior can be tested without starting the whole application. Express middleware in `server.ts` will translate those results into HTTP responses.

The health endpoint remains unrestricted. Only `/api/ai/*` requests count toward the rate limit.

## Request Limits

- JSON body limit: `32kb`.
- AI rate limit: 10 requests per source IP in a fixed 60-second window that begins with that IP's first request.
- A rejected 11th request returns HTTP `429` and a `Retry-After` header.
- Rate-limit state is in memory and resets when the process restarts.
- Expired IP entries are removed during subsequent checks so the map does not grow without bound.

The application will use Express's resolved `req.ip` without enabling `trust proxy`. This is correct for the requested local, single-process deployment. A future reverse-proxy or multi-instance deployment must replace or reconfigure this mechanism.

## Input Validation

Both endpoint bodies must be JSON objects. Supplied fields must have the following types and limits:

### `/api/ai/session-summary`

- `clientName`: optional string, maximum 100 characters.
- `rawNotes`: optional string, maximum 10,000 characters.
- `sessionTopic`: optional string, maximum 200 characters.
- `sessionNumber`: optional integer from 1 through 999.

### `/api/ai/generate-quote`

- `topic`: optional string, maximum 500 characters.
- `consultantName`: optional string, maximum 100 characters.

Unknown fields are ignored to preserve current client compatibility. An invalid known field returns HTTP `400` with a stable `{ "error": "Invalid request", "details": [...] }` structure that contains validation messages but no stack traces or internal exceptions. Existing fallback content remains available when `GEMINI_API_KEY` is not configured.

Malformed JSON returns HTTP `400`; a body larger than `32kb` returns HTTP `413`. Unexpected server or Gemini failures return HTTP `500` with a generic error message and are logged on the server.

## Frontend Corrections

The login agreement row will use a non-interactive layout container, a dedicated accessible agreement toggle button, and separate legal-document buttons. This removes the invalid `button > button` structure while keeping all current actions reachable by keyboard.

The `VoiceCall` component's props signature will be corrected so `<VoiceCall key="vcall" />` type-checks normally without suppressing errors. TypeScript configuration will cover maintained TypeScript sources and no longer need to compile deleted JavaScript patch artifacts.

## Dependency Handling

The app only distinguishes `/client`, `/counselor`, and a counselor fallback, so a small tested pathname resolver will replace `react-router-dom`. The lockfile will be regenerated with npm. The dependency decision is accepted only if `npm audit` reports zero known vulnerabilities and the existing routes still render.

## Testing

Node's built-in test runner, loaded through `tsx`, will cover:

- valid and invalid request shapes;
- each field boundary;
- rejection of non-object bodies;
- rate-limit allowance through request 10;
- request 11 rejection and retry timing; and
- expiry/reset behavior.

Regression verification will also run:

- `npm test`;
- `npm run lint`;
- `npm audit`;
- `npm run build`;
- production server health and AI endpoint requests, including `400`, `413`, and `429` cases;
- real-browser checks of `/client` and `/counselor`, with no React DOM nesting errors; and
- `git status`/`git diff` review to confirm only scoped files changed.

## Acceptance Criteria

The repair is complete when all automated commands exit successfully, the production build starts locally, both application routes render, valid AI requests retain their current response behavior, invalid or excessive requests receive the documented status codes, no one-time patch scripts remain, and the browser console no longer reports the nested-button React error.
