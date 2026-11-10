# Competition showcase

## Problem

MoonBit applications need transactional email, but application authors should not have to hand-build Resend JSON, authentication, idempotency and error handling for every project.

## Demonstrable result

`moon-resend` covers a complete transactional lifecycle: send one email, send a batch, retrieve delivery state, reschedule and cancel. The `adapter` package performs real HTTPS requests through moonfetch while the core remains deterministic and independently testable.

## 90-second demo script

1. Show `SendEmailParams::new` and the one-call `@adapter.send` API.
2. Run the test suite to demonstrate validation and response parsing.
3. Set `RESEND_API_KEY` locally and run a live example with a verified sender and recipient.
4. Show the returned email ID, then retrieve its delivery state.
5. Open the architecture diagram and explain why transport and Resend semantics are separated.

Never expose the API key in a screen recording, source file, shell history or CI log.

## Coverage matrix

| Capability | November status |
| --- | --- |
| Send email | Complete |
| Batch send, up to 100 | Complete |
| HTML/text, CC/BCC/reply-to | Complete |
| Attachments, tags and scheduling | Complete |
| Idempotency | Complete |
| Retrieve, reschedule and cancel | Complete |
| Typed API and transport errors | Complete |
| Real HTTP adapter | Complete with moonfetch |
| Webhook verification | Implemented for 0.2.0 with HMAC-SHA256 and freshness checks |
| Domains and contacts | January milestone |
| Full Resend API parity | Deliberately out of scope |

## Reproducible judging

The normal test suite does not contact Resend and requires no secret. A live email is an optional demonstration using the participant's own key and verified domain. This separates repeatable judging from external account configuration.

Live command: `moon run cmd/send-live --target native`. It reads `RESEND_API_KEY`, `RESEND_FROM`, and `RESEND_TO` exclusively from the process environment.
