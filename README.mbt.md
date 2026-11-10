# moon-resend

面向 Resend 邮件平台的类型化 MoonBit SDK，提供 transport-neutral 核心和基于 moonfetch 的真实 HTTPS adapter，适用于 MoonBit Web 应用、SaaS 服务、后台任务和自动化工具。

[![CI](https://github.com/hua1104/moon-resend/actions/workflows/ci.yml/badge.svg)](https://github.com/hua1104/moon-resend/actions/workflows/ci.yml)

## 3-minute review path

Install the published November release with moon add hua1104/moon-resend@0.1.0.
The immutable judging snapshot is v0.1.0; later main-branch commits belong to
later milestones and are not required to evaluate the November submission.

Reproduce the release without a Resend key:

~~~sh
moon update
moon check
moon test
moon build cmd/send-live --target native
~~~

The request builder performs no network access. The supported adapter below
returns an EmailId, and the live example prints sent: followed by that id.

- [项目申报书](APPLICATION.md)
- [中文比赛展示说明](docs/COMPETITION_ZH.md)
- [11 月评审清单](docs/NOVEMBER_REVIEW.md)
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

This is not advertised as a complete Resend API implementation. The November milestone prioritizes send, batch send, retrieve, reschedule, cancel, validation, errors, tests and one reproducible example. Webhook verification, domains, contacts and broadcasts remain roadmap items until the core loop is stable.

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

### Compatibility matrix

| Surface | Wasm | JavaScript | Native |
| --- | --- | --- | --- |
| Typed core and offline tests | Supported | Supported | Supported |
| moonfetch adapter | Supported | Supported | Supported |
| Live CLI example | — | — | Supported |

The November release was checked with MoonBit toolchains dated 2026-10-29 and
2026-11-04. Normal tests use no API key and make no Resend request. Only the
live command requires RESEND_API_KEY, RESEND_FROM, and RESEND_TO.

## License

Apache-2.0
