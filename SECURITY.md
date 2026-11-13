# Security policy

## API key handling

- Keep Resend API keys in environment variables or a secret manager.
- Never commit keys or expose them in issues, screenshots or recordings.
- Rotate any key that may have leaked.
- The live example reads RESEND_API_KEY, RESEND_FROM and RESEND_TO from the environment.
- The official adapter disables redirects so credentials are not forwarded to another origin.

The normal test suite does not require credentials and does not contact Resend. Report vulnerabilities privately to the repository owner before sharing sensitive reproduction details.

Webhook consumers must verify the raw body before parsing and persist event IDs
to prevent duplicate delivery. The in-memory replay guard is for examples and
single-process services; distributed services need a durable atomic store.
