# Public API overview

## Core package

| API | Purpose |
| --- | --- |
| Client::new | Configure API key and optional base URL |
| SendEmailParams::new | Define a transactional email |
| Attachment::new | Add Base64-encoded attachment content |
| Client::send_request | Build POST /emails |
| Client::batch_send_request | Build POST /emails/batch |
| Client::retrieve_request | Build GET /emails/:id |
| Client::update_request | Build PATCH /emails/:id |
| Client::cancel_request | Build POST /emails/:id/cancel |
| Client response parsers | Convert HTTP responses to typed results |

ResendError distinguishes invalid input, API errors, malformed success responses and transport failures. Its message method provides a concise application-facing description.

## Webhook verification

- WebhookVerifier::new(secret) decodes the Resend whsec_ signing secret.
- WebhookVerifier::verify(...) validates the raw body with HMAC-SHA256,
  accepts rotated v1 signatures, and enforces a five-minute timestamp window.
- Successful verification returns VerifiedWebhook. Persist its id() in
  application storage and reject duplicates to complete replay protection.
- Always pass the request body exactly as received; parsing and re-serializing JSON
  before verification changes the signed bytes.
- WebhookVerifier::verify_event(...) verifies before parsing and returns a
  VerifiedWebhookEvent containing signature metadata plus a typed WebhookEvent.
- WebhookEvent exposes stable envelope and email fields. Unknown event names and
  resource-specific data are retained through Other(name) and raw_data().

## Adapter package

The adapter package exposes send, send_batch, retrieve, update, cancel and low-level execute. All functions accept an optional timeout in milliseconds. Redirects are disabled deliberately. send_with_retry performs bounded exponential backoff only for retryable failures and requires an idempotency key.

ApiError request IDs, retry delays and ResendError retry classification let applications make an explicit retry and logging decision.

## Replay protection

WebhookReplayGuard is a small in-memory reference implementation. Call its
check-and-record operation before business effects; distributed services should
implement the same atomic operation in durable storage.

The public async `ReplayStore` trait supports custom shared storage.
`WebhookVerifier::verify_event_once` verifies, parses, then claims the verified
delivery ID. It returns `WebhookProcessingError::Verification` or `Replay` on
failure. The default memory store retains 10,000 IDs for one day; `with_limits`
configures positive TTL/capacity. `len`, `prune` and `forget` support maintenance.
It fails closed at capacity and does not evict live claims.
See [storage contracts and failure semantics](REPLAY_STORAGE.md) and the
[complete HTTP service](EMAIL_SERVICE.md).
