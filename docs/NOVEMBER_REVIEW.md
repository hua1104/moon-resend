# November judging guide

## Scope and immutable snapshot

Judge the November entry from tag v0.1.0. It contains the transactional email
core, Moonfetch HTTPS adapter, offline tests, live example, API index,
architecture notes and security guidance. Webhooks and resource APIs are later
milestones.

## 90-second demonstration

1. Install hua1104/moon-resend@0.1.0 from Mooncakes.
2. Show SendEmailParams::new and @adapter.send in the README.
3. Run moon test; the suite uses no secret and sends no email.
4. Optionally run cmd/send-live with environment variables and show only the
   returned email id—never the API key.
5. Show docs/ARCHITECTURE.md and explain the SDK/transport boundary.

## Evidence checklist

- Mooncakes package page or successful moon add output.
- CI run for the submitted commit or tag.
- Offline test summary.
- Optional live-delivery output and received-email screenshot, with API keys,
  private addresses and unrelated content redacted.
