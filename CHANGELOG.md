# Changelog

## 0.2.0 — Unreleased

### Added

- Resend/Svix webhook signature verification with timestamp freshness checks.
- Verified event metadata for application-level duplicate detection.
- Typed, forward-compatible webhook event parsing performed only after signature
  verification.
- Retry classification, bounded exponential backoff, response request IDs and
  an in-memory webhook replay guard.
- Local-server integration coverage for headers, JSON bodies, lifecycle calls,
  typed API errors and transport timeouts.

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
