# moon-resend

A small, typed, transport-neutral MoonBit SDK for the Resend Email API.

The first milestone intentionally focuses on a reliable transactional-email loop:

- build and validate send-email requests;
- HTML and text bodies, CC/BCC/reply-to, attachments, tags and scheduling;
- idempotency keys;
- retrieve, reschedule and cancel request builders;
- typed parsing of retrieved email metadata and delivery state;
- batch sending for up to 100 messages;
- typed success and API error parsing;
- no hard dependency on one HTTP runtime.

## Quick start

~~~moonbit nocheck
///|
let client = @resend.Client::new("re_xxxxxxxxx").unwrap()

///|
let email = @resend.SendEmailParams::new(
  "Acme <onboarding@example.com>",
  ["user@example.com"],
  "Welcome",
  html="<strong>It works!</strong>",
  text="It works!",
)

///|
let request = client
  .send_request(email, idempotency_key="welcome-user-42")
  .unwrap()
~~~

HttpRequest is deliberately transport-neutral. An adapter sends it with the application's chosen HTTP client and passes the result back as HttpResponse. This makes request construction and error behavior deterministic in tests. A ready-to-use async HTTP adapter is the next milestone.

## Deliberate scope

This is not advertised as a complete Resend API implementation. The November milestone prioritizes send, batch send, retrieve, reschedule, cancel, validation, errors, tests and one reproducible example. Webhook verification, domains, contacts and broadcasts remain roadmap items until the core loop is stable.

See [MILESTONES.md](MILESTONES.md) for the deliberately split delivery plan and acceptance criteria.

## Competition roadmap

- **November:** stabilize the typed request/response core and publish an auditable MVP.
- **December:** add one production HTTP adapter, integration tests against a mock server, and webhook signature verification.
- **January:** add domains/contacts APIs, examples, API reference docs and Mooncakes packaging.

The milestones are deliberately usable on their own. Later competition entries extend the SDK with new capabilities instead of submitting the same work split across repositories.

## Development

~~~sh
moon check
moon test
moon info
moon fmt
~~~

## License

Apache-2.0
