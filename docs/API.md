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

## Adapter package

The adapter package exposes send, send_batch, retrieve, update, cancel and low-level execute. All functions accept an optional timeout in milliseconds. Redirects are disabled deliberately.
