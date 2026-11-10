# Optional live-delivery evidence

The offline test suite is the reproducible judging path. A live Resend delivery
is optional evidence and must be produced only with credentials owned by the
participant.

## Capture procedure

1. Set RESEND_API_KEY, RESEND_FROM and RESEND_TO in the local process
   environment. Do not paste the values into source files or terminal history.
2. Run moon run cmd/send-live --target native.
3. Capture the single success line containing the returned email id.
4. Capture the received test email.
5. Redact the API key, private addresses, account identifiers and unrelated
   browser or desktop content before submission.

## Evidence record

- Date and timezone:
- Commit or tag:
- Returned email id:
- Sender domain verified: yes / no
- Recipient controlled by participant: yes / no
- Terminal screenshot:
- Received-email screenshot:

No live evidence is checked into this repository by default because it may
contain personal addresses or account metadata.
