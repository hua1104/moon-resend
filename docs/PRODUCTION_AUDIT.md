# Production and competition audit

Audit date: 2026-11-16.

The official MoonBit quarterly rubric scores four dimensions at 25 points each.
Its excellent tier requires complete core outcomes and verified key scenarios,
substantive technical difficulty with clear constraints and trade-offs,
externally demonstrated ecosystem value, and a repeatable validation loop using
harnesses, regression tests, benchmarks and automation.

## Current evidence

### Engineering depth

- transport-neutral request/response core plus moonfetch adapter;
- send, batch, paginated history, retrieve, reschedule and cancel lifecycle;
- idempotent bounded retries with Retry-After;
- raw-body webhook verification, typed events and bounded replay;
- runnable MoonBit HTTP service exercising send-to-callback flow.

Assessment: strong good tier. Excellent additionally requires real delivered and
bounced callback evidence plus an executable durable-store example.

### Technical contribution

- MoonBit-native separation of deterministic API semantics and transport;
- typed layered errors with request IDs and retry hints;
- fail-closed replay capacity and an async custom storage trait;
- forward-compatible events with typed delivery and bounce projections.

Assessment: upper good tier. The project now has an OpenAPI coverage statement;
remaining design evidence should explain crash windows and exactly-once limits.

### Ecosystem increment

- published Mooncakes package filling a missing Resend integration;
- normal tests require no real credentials;
- executable integration service and framework-neutral core.

Assessment: good tier but weak external proof. Excellent requires an independent
consumer or framework example and feedback from another developer.

### Development and validation

- Wasm, JS and Native CI, formatting and generated-interface checks;
- local real-HTTP fixture, retry harness and complete-service E2E;
- regression tests for malformed responses, pagination, retries and replay.

Assessment: good tier. Missing for excellent: coverage threshold, benchmark
regression, official-schema drift check, fault injection and live smoke report.

## Priority gates

### P0 release correctness

- [x] version 0.2.0 published;
- [ ] create and push v0.2.0 tag at the exact published commit;
- [x] move new work to 0.3.0;
- [ ] keep changelog, package version and tag atomic for each release.

### P0 acceptance evidence

- [ ] live send using a verified domain;
- [ ] live GET /emails response with a cursor transition when data permits;
- [ ] authentic email.delivered callback verification;
- [ ] authentic email.bounced callback verification;
- [ ] redacted report with timestamps, status, request IDs and truncated IDs,
  never secrets or message content.

### P1 automated quality gates

- [ ] enforce a core coverage threshold and retain the report as CI artifact;
- [ ] benchmark signature verification, list parsing and replay pruning;
- [ ] pin an OpenAPI baseline and fail CI when covered schemas drift;
- [ ] add property or fuzz cases for cursors, JSON and webhook headers;
- [ ] test disconnects, chunked-body failures, 429 bursts and store outages.

### P1 ecosystem proof

- [ ] add one MoonBack or equivalent framework example;
- [ ] create an independent sample consuming the published package;
- [ ] obtain one external-user validation and record actionable feedback;
- [ ] publish migration and compatibility policy.

## Release decision

Version 0.2.0 is a usable transactional-email SDK milestone. It is not yet a
production-complete or full Resend-platform SDK. The next competition-quality
release should not be submitted as excellent-tier evidence until the P0 live
evidence and release-tag gates are complete.
