# Changelog

## 0.3.0 — 2026-11-16

### Added

- Typed email.delivered projection through WebhookEvent::delivery.
- Typed email.bounced details through WebhookEvent::bounce, including bounce
  type, subtype, message and SMTP diagnostic codes.
- Repository coverage threshold and CI coverage artifact.
- Production release checklist, benchmark protocol and OpenAPI baseline.

## 0.2.0 — 2026-11-16

### Added

- Resend/Svix webhook signature verification with timestamp freshness checks.
- Verified event metadata for application-level duplicate detection.
- Typed, forward-compatible webhook event parsing performed only after signature
  verification.
- Retry classification, bounded exponential backoff, response request IDs and
  an in-memory webhook replay guard.
- Bounded replay retention with configurable TTL/capacity, an async ReplayStore
  extension contract and verify-parse-claim integration.
- Runnable MoonBit email service and credential-free end-to-end tests for
  sends, signed callbacks, concurrent duplicates and last-observed email state.
- Local-server integration coverage for headers, JSON bodies, lifecycle calls,
  typed API errors and transport timeouts.
- Paginated sent-email history with validated limit, after and before cursors
  and typed page metadata.

## 0.1.0 — 2026-11-10

### Added

- Typed request builders for send, batch send, retrieve, reschedule and cancel.
- HTML/text bodies, address fields, attachments, tags and scheduled delivery.
- Idempotency keys with validation.
- Typed API, invalid-response and transport errors.
- A real HTTPS adapter powered by moonfetch.
- Offline tests and opt-in live delivery example.

### Security

- Redirects are disabled by the adapter to protect authorization credentials.
- Live credentials are read from environment variables and are not required by tests.
