# moon-resend delivery plan

The work is split by usable capability, not by moving one implementation into multiple repositories. Each milestone has its own acceptance criteria and leaves the package in a publishable state.

## November — transactional email core

Estimated effort: 3–5 focused development days.

- typed request construction for send, batch send, retrieve, reschedule and cancel;
- attachments, tags, scheduling and idempotency;
- typed success/error/retrieval parsing;
- input validation, deterministic tests and a runnable request-building example;
- transport-neutral design so users can choose their MoonBit HTTP runtime.
- release notes, security guidance, contribution rules and a public API index.

Acceptance: `moon check`, `moon test`, `moon info`, formatting and the offline example pass without warnings. The live example compiles and performs direct delivery only when the operator explicitly supplies Resend credentials.

## December — integration hardening and webhooks

Estimated effort: 4–6 focused development days.

- harden the moonfetch adapter delivered early in November;
- expand integration coverage with a local mock server;
- mock-server integration tests for headers, bodies, failures and timeouts;
- webhook signature verification with documented replay protection.

Acceptance: a user can send an email with an API key using the documented adapter, and CI verifies the integration without contacting Resend.

## January — ecosystem surface

Estimated effort: 5–8 focused development days, adjustable by competition schedule.

- domains and contacts APIs first; broadcasts only if time remains;
- API reference and end-to-end examples;
- Mooncakes metadata, compatibility matrix and release checklist.

Acceptance: the package is installable from Mooncakes and every advertised resource has request, response, error and example coverage.

## Deferred on purpose

Inbound email, inboxes, audiences, templates and full API parity are not part of the first three milestones. They can be added later based on real users instead of increasing the initial maintenance burden.
