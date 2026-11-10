"""Local Resend-compatible fixture used by adapter integration tests."""

from __future__ import annotations

import argparse
import json
import time
import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def log_message(self, format: str, *args: object) -> None:
        return

    def _body(self) -> bytes:
        length = int(self.headers.get("Content-Length", "0"))
        return self.rfile.read(length)

    def _json(self, status: int, payload: dict[str, object]) -> None:
        body = json.dumps(payload, separators=(",", ":")).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        try:
            self.wfile.write(body)
        except (BrokenPipeError, ConnectionAbortedError, ConnectionResetError):
            pass

    def _authorized(self) -> bool:
        return self.headers.get("Authorization") == "Bearer re_integration"

    def do_POST(self) -> None:
        if self.path == "/slow/emails":
            self._body()
            time.sleep(0.25)
            self._json(200, {"id": "email_too_late"})
            return
        if self.path == "/api-error/emails":
            self._body()
            self._json(
                422,
                {"name": "validation_error", "message": "mock recipient rejected"},
            )
            return
        if self.path == "/emails/email_mock_123/cancel":
            self._json(200, {"id": "email_mock_123"})
            return
        if self.path != "/emails":
            self._json(404, {"name": "not_found", "message": self.path})
            return
        try:
            payload = json.loads(self._body())
        except (json.JSONDecodeError, UnicodeDecodeError):
            self._json(400, {"name": "invalid_json", "message": "invalid JSON"})
            return
        valid = (
            self._authorized()
            and self.headers.get("Content-Type") == "application/json"
            and self.headers.get("Idempotency-Key") == "integration-42"
            and self.headers.get("User-Agent") == "moon-resend/0.2.0"
            and payload.get("subject") == "Integration test"
            and payload.get("to") == ["user@example.com"]
            and payload.get("html") == "<strong>Hello</strong>"
        )
        if not valid:
            self._json(400, {"name": "fixture_mismatch", "message": "request mismatch"})
            return
        self._json(200, {"id": "email_mock_123"})

    def do_GET(self) -> None:
        if self.path != "/emails/email_mock_123" or not self._authorized():
            self._json(404, {"name": "not_found", "message": self.path})
            return
        self._json(
            200,
            {
                "id": "email_mock_123",
                "from": "Moon <hello@example.com>",
                "to": ["user@example.com"],
                "subject": "Integration test",
                "created_at": "2026-11-10T08:00:00Z",
                "last_event": "delivered",
            },
        )

    def do_PATCH(self) -> None:
        if self.path != "/emails/email_mock_123" or not self._authorized():
            self._json(404, {"name": "not_found", "message": self.path})
            return
        payload = json.loads(self._body())
        if payload.get("scheduled_at") != "2026-12-01T08:00:00Z":
            self._json(400, {"name": "fixture_mismatch", "message": "bad schedule"})
            return
        self._json(200, {"id": "email_mock_123"})


class MockServer(ThreadingHTTPServer):
    daemon_threads = True

    def handle_error(self, request: object, client_address: object) -> None:
        if isinstance(sys.exception(), ConnectionError):
            return
        super().handle_error(request, client_address)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", type=int, default=18765)
    args = parser.parse_args()
    MockServer(("127.0.0.1", args.port), Handler).serve_forever()


if __name__ == "__main__":
    main()
