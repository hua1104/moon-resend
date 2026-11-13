# moon-resend

面向 Resend 邮件平台的类型化 MoonBit SDK，提供 transport-neutral 核心和基于 moonfetch 的真实 HTTPS adapter，适用于 MoonBit Web 应用、SaaS 服务、后台任务和自动化工具。

[![CI](https://github.com/hua1104/moon-resend/actions/workflows/ci.yml/badge.svg)](https://github.com/hua1104/moon-resend/actions/workflows/ci.yml)

- [项目申报书](APPLICATION.md)
- [中文比赛展示说明](docs/COMPETITION_ZH.md)
- [架构说明](docs/ARCHITECTURE.md)
- [公开 API 索引](docs/API.md)
- [阶段规划](MILESTONES.md)
- [更新记录](CHANGELOG.md)
- [安全说明](SECURITY.md)
- [贡献指南](CONTRIBUTING.md)

The first milestone intentionally focuses on a reliable transactional-email loop:

- build and validate send-email requests;
- HTML and text bodies, CC/BCC/reply-to, attachments, tags and scheduling;
- idempotency keys;
- retrieve, reschedule and cancel request builders;
- typed parsing of retrieved email metadata and delivery state;
- batch sending for up to 100 messages;
- typed success and API error parsing;
- an optional real HTTPS adapter powered by moonfetch.

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

HttpRequest is deliberately transport-neutral. This keeps request construction and error behavior deterministic while the optional adapter provides real network I/O.

## Send over HTTPS

The `hua1104/moon-resend/adapter` package provides the supported moonfetch integration:

~~~moonbit nocheck
///|
async fn send_welcome(api_key : String) -> Unit {
  let client = @resend.Client::new(api_key).unwrap()
  let email = @resend.SendEmailParams::new(
    "Acme <onboarding@example.com>",
    ["user@example.com"],
    "Welcome",
    html="<strong>It works!</strong>",
    text="It works!",
  )
  match @adapter.send(client, email, idempotency_key="welcome-user-42") {
    Ok(sent) => println("sent: " + sent.id())
    Err(_) => println("send failed")
  }
}
~~~

The adapter also exposes `send_batch`, `retrieve`, `update`, `cancel`, and low-level `execute`. It disables redirects to protect the authorization header and converts network, TLS and timeout failures to `ResendError::Transport`.

### Run the live example

Use a Resend API key, a sender on your verified domain, and a recipient you control. The values stay in environment variables and are never committed:

~~~powershell
$env:RESEND_API_KEY = "re_..."
$env:RESEND_FROM = "Demo <demo@your-verified-domain.example>"
$env:RESEND_TO = "you@example.com"
moon run cmd/send-live --target native
~~~

The regular test suite never sends an email and requires no secret.

## Deliberate scope

This is not advertised as a complete Resend API implementation. The November milestone prioritizes send, batch send, retrieve, reschedule, cancel, validation, errors, tests and one reproducible example. Domains, contacts and broadcasts remain roadmap items until the core loop is stable.

Webhook signature verification is now available as an early December capability.
It validates the raw request body, Svix headers and timestamp window. Applications
should store the returned verified event id and reject duplicates for full replay
protection; see [the API guide](docs/API.md#webhook-verification).

~~~moonbit nocheck
///|
let verifier = WebhookVerifier::new("whsec_...").unwrap()

///|
let verified = verifier
  .verify(raw_body, svix_id, svix_timestamp, svix_signature, unix_time_seconds)
  .unwrap()
// Persist verified.id() and reject it if it has already been processed.
~~~

For handlers that need structured data, verify_event authenticates the exact raw
body before parsing it. Known event kinds are typed, while future Resend event
names and resource-specific fields remain accessible without an SDK upgrade.

See [MILESTONES.md](MILESTONES.md) for the delivery plan, [architecture](docs/ARCHITECTURE.md) for the package boundary, and [competition showcase](docs/COMPETITION.md) for the coverage matrix and demo script.

## Competition roadmap

- **November:** stabilize the typed request/response core and publish an auditable MVP.
- **December:** harden the moonfetch adapter, add mock-server integration tests, and implement webhook signature verification.
- **January:** add domains/contacts APIs, examples, API reference docs and Mooncakes packaging.

The milestones are deliberately usable on their own. Later competition entries extend the SDK with new capabilities instead of submitting the same work split across repositories.

## Development

~~~sh
moon check
moon test
moon info
moon fmt
~~~

The live adapter example also compiles in CI on the native target. On Windows, native builds require MSVC Build Tools with the C++ workload and Windows SDK; the default wasm checks do not.

The adapter integration suite starts a local Resend-compatible fixture and never
contacts Resend. Run it with Python available:

~~~sh
python tests/mock_resend_server.py --port 18765
MOON_RESEND_MOCK_URL=http://127.0.0.1:18765 moon test adapter --target js
~~~

For retrying sends, use `send_with_retry` and supply a stable idempotency
key. The adapter retries transport failures, HTTP 408/429 and 5xx responses,
honors numeric `Retry-After` values, and never retries ordinary 4xx responses.

Webhook processing must follow this order: verify the signature against the raw
request body, parse the verified event, atomically record its event ID, then run
business side effects. `WebhookReplayGuard` is intentionally an in-memory,
single-process implementation; production deployments with multiple workers
must use Redis or a database to provide an atomic check-and-record operation,
unique event IDs, and a retention policy.

## License

Apache-2.0
