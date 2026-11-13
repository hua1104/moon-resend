# Email service example

This runnable MoonBit HTTP service connects the SDK's send, retry, verification,
replay-store and typed-event APIs. It is an integration example, not a durable
mail queue or a complete production deployment.

## Run without credentials

From the repository root, with MoonBit and Python 3.11+ on PATH:

```sh
python tests/run_service_e2e.py
```

The script builds and starts the actual Wasm service using `moonrun`, starts a
local provider fixture on an ephemeral port, and stops both when done. No request
is sent to Resend. It verifies authentication, required idempotency keys,
signature rejection without poisoning the replay cache, eight concurrent webhook
deliveries with exactly one processed result, status updates and body limits.

## Connect to Resend

PowerShell:

```powershell
$env:RESEND_API_KEY = "<your API key>"
$env:RESEND_FROM = "hello@your-verified-domain.example"
$env:RESEND_TO = "your-test-recipient@example.com"
$env:RESEND_WEBHOOK_SECRET = "<signing secret from the Resend dashboard>"
$env:DEMO_TOKEN = "<long random local access token>"
moon run cmd/email-service --target wasm
```

Use `--target native` on a host with a supported C compiler. The service binds
to `127.0.0.1:8080` by default. `DEMO_ADDR` overrides the address.
`RESEND_BASE_URL` is intended for local fixtures; leave it unset for Resend.
Real sends require a verified sender and may consume the account's quota.

```powershell
$headers = @{
  Authorization = "Bearer $env:DEMO_TOKEN"
  "Idempotency-Key" = "welcome-user-42-v1"
}
$sent = Invoke-RestMethod http://127.0.0.1:8080/send `
  -Method Post -Headers $headers -ContentType application/json `
  -Body '{"subject":"Welcome","text":"Hello from MoonBit"}'
Invoke-RestMethod "http://127.0.0.1:8080/status/$($sent.id)" -Headers $headers
```

Reuse the key only for the same logical email and identical parameters. The
recipient is configured on the server, so the sample cannot serve as an arbitrary
recipient relay. Provider errors return a generic 502 without exposing mail
content, credentials or raw error bodies.

| Route | Authentication | Behavior |
| --- | --- | --- |
| `GET /health` | None | Service availability |
| `POST /send` | Bearer token | Send configured recipient a subject/text email; Idempotency-Key required |
| `GET /status/:id` | Bearer token | Last observed event for a sent email |
| `POST /webhooks/resend` | Svix signature | Verify raw UTF-8 body, parse, claim delivery ID, update known email |

For real webhooks, expose only `/webhooks/resend` through a TLS reverse proxy or
development tunnel and register that HTTPS endpoint in Resend. Preserve the
request bytes and the `svix-id`, `svix-timestamp`, `svix-signature` headers.
Keep the token-protected routes private. Do not log bodies or secrets.

Duplicate authenticated deliveries receive HTTP 200 with `status: duplicate`,
preventing needless provider retries. Signature/payload failures return 400;
replay-store capacity or availability failures return 503 so delivery can retry.
Bodies are limited to 256 KiB while streaming with a five-second read timeout;
connections are closed after each response.

## Production boundaries

- Both the delivery claims and email projection are process-local and reset on
  restart. Use a shared durable inbox and database projection before scaling.
- The projection is the **last observed event**, not an authoritative delivery
  state machine. Out-of-order events can change it; events arriving before the
  send response has registered the email are ignored. Production needs an inbox
  that retains and reconciles such events.
- The sample limits the projection to approximately 10,000 entries (concurrent
  sends can briefly exceed this bound). Restart or replace it with durable
  storage for long-running use.
- There is no database transaction between the replay claim and state update.
  A crash between them can lose processing. See [replay storage](REPLAY_STORAGE.md)
  for the durable inbox pattern, including recoverable processing failures.
- Add TLS, authenticated users, rate limits and a job queue for public-facing
  applications. The example's fixed local bearer token is a development guard.
