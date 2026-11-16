# Resend compatibility statement

Baseline: Resend OpenAPI 1.5.1, inspected on 2026-11-16 from the
resend/resend-openapi repository. This document is the compatibility contract
for moon-resend. It distinguishes implemented, partial and out-of-scope surfaces
instead of describing the package as full-platform compatible.

## Transactional email API

| Official operation | MoonBit API | Status | Verification |
| --- | --- | --- | --- |
| POST /emails | adapter.send, send_with_retry | Implemented | deterministic core tests, local HTTP integration, runnable service |
| GET /emails | adapter.list_emails | Implemented | limit/after/before validation, two-page local HTTP test |
| GET /emails/{id} | adapter.retrieve | Implemented | response parsing and local HTTP integration |
| PATCH /emails/{id} | adapter.update | Implemented | request/response and local HTTP integration |
| POST /emails/{id}/cancel | adapter.cancel | Implemented | local HTTP integration |
| POST /emails/batch | adapter.send_batch | Implemented | 1..100 validation and response parsing |
| POST /emails/{id}/share | — | Not implemented | outside the declared subset |
| sent-email attachments | — | Not implemented | outside the declared subset |
| receiving email APIs | — | Not implemented | separate inbound-mail scope |
| email metrics | — | Not implemented | separate analytics scope |

Send supports HTML/text, CC, BCC, reply-to, attachments, tags, scheduling,
idempotency and typed errors. It does not yet expose every field in the latest
official SendEmailRequest: templates, custom headers and topic_id remain
unimplemented. The precise claim is transactional email lifecycle compatibility
subset, not complete Resend-platform SDK parity.

## Webhook contract

| Event | Parsing | Typed projection | Signature/freshness | Replay protection |
| --- | --- | --- | --- | --- |
| email.delivered | Implemented | delivery() | Implemented | Implemented |
| email.bounced | Implemented | bounce() with SMTP diagnostics | Implemented | Implemented |
| sent, scheduled, delayed, complained, opened, clicked, failed, suppressed | Forward-compatible | stable common fields and raw data | Implemented | Implemented |
| unknown future event | Preserved as Other(name) | raw data retained | Implemented | Implemented |

The library verifies the exact raw body before JSON parsing. The bundled memory
replay store is bounded and single-process. Production multi-instance systems
must implement the public async ReplayStore contract with Redis or a database.

## Platform resources not claimed

Domains, API keys, templates, contacts, segments, topics, broadcasts, webhooks
management, logs, automations, events, suppressions, usage and inboxes are not
implemented in version 0.3.0. Adding them requires typed models, fixture-backed
integration tests and an update to this matrix.

## Compatibility update policy

Before a release:

1. compare this matrix against the pinned official OpenAPI version;
2. run Wasm, JS and Native tests plus the local HTTP and service harness;
3. record intentionally unsupported fields and operations;
4. perform opt-in live validation without committing credentials or content;
5. update changelog, version, tag and Mooncakes package together.
