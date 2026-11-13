"""Run the real MoonBit service against a local provider, without real credentials."""

from __future__ import annotations

import base64
from concurrent.futures import ThreadPoolExecutor
import hashlib
import hmac
import http.client
import json
import os
from pathlib import Path
import shutil
import socket
import subprocess
import tempfile
import threading
import time

from mock_resend_server import Handler, MockServer


def main() -> None:
    root = Path(__file__).resolve().parents[1]
    moon = shutil.which("moon")
    runner = shutil.which("moonrun")
    if not moon or not runner:
        raise SystemExit("moon and moonrun must be on PATH")
    subprocess.run([moon, "build", "cmd/email-service", "--target", "wasm"], cwd=root, check=True)
    provider = MockServer(("127.0.0.1", 0), Handler)
    threading.Thread(target=provider.serve_forever, daemon=True).start()
    with socket.socket() as reserved:
        reserved.bind(("127.0.0.1", 0))
        port = reserved.getsockname()[1]
    env = dict(os.environ, RESEND_API_KEY="re_integration", RESEND_FROM="hello@example.com",
               RESEND_TO="user@example.com", RESEND_WEBHOOK_SECRET="whsec_dGVzdHNlY3JldA==",
               RESEND_BASE_URL=f"http://127.0.0.1:{provider.server_port}/service",
               DEMO_TOKEN="local-test-token", DEMO_ADDR=f"127.0.0.1:{port}")
    artifact = root / "_build/wasm/debug/build/cmd/email-service/email-service.wasm"

    def request(method: str, path: str, body: bytes = b"", headers: dict[str, str] | None = None) -> tuple[int, dict]:
        conn = http.client.HTTPConnection("127.0.0.1", port, timeout=10)
        try:
            conn.request(method, path, body, headers or {})
            response = conn.getresponse()
            return response.status, json.loads(response.read())
        finally:
            conn.close()

    with tempfile.TemporaryFile(mode="w+b") as output:
        process = subprocess.Popen([runner, str(artifact)], cwd=root, env=env, stdout=output, stderr=subprocess.STDOUT)
        try:
            deadline = time.monotonic() + 30
            while True:
                if process.poll() is not None:
                    raise RuntimeError("email service exited during startup")
                try:
                    if request("GET", "/health")[0] == 200:
                        break
                except OSError:
                    pass
                if time.monotonic() > deadline:
                    raise RuntimeError("email service did not start")
                time.sleep(.05)
            auth = {"Authorization": "Bearer local-test-token", "Content-Type": "application/json"}
            email = b'{"subject":"Welcome","text":"Hello"}'
            assert request("POST", "/send", email)[0] == 401
            assert request("POST", "/send", email, auth)[0] == 400
            assert Handler.service_attempts == 0
            send_headers = dict(auth, **{"Idempotency-Key": "service-e2e-42"})
            status, sent = request("POST", "/send", email, send_headers)
            assert status == 200 and sent["id"] == "email_service_123", (status, sent)
            assert request("GET", "/status/email_service_123", headers=auth)[1]["last_event"] == "accepted"
            body = json.dumps({"type": "email.delivered", "created_at": "2026-11-13T00:00:00Z",
                               "data": {"email_id": sent["id"]}}, separators=(",", ":")).encode()
            timestamp = str(int(time.time()))
            event_id = "msg_service_e2e"
            signature = base64.b64encode(hmac.new(b"testsecret", event_id.encode() + b"." + timestamp.encode() + b"." + body, hashlib.sha256).digest()).decode()
            signed = {"svix-id": event_id, "svix-timestamp": timestamp, "svix-signature": "v1," + signature}
            assert request("POST", "/webhooks/resend", body + b" ", signed)[0] == 400
            # The invalid signature must not reserve the delivery ID.
            with ThreadPoolExecutor(max_workers=8) as pool:
                results = list(pool.map(lambda _: request("POST", "/webhooks/resend", body, signed), range(8)))
            assert all(code == 200 for code, _ in results), results
            assert sum(item["status"] == "processed" for _, item in results) == 1, results
            assert sum(item["status"] == "duplicate" for _, item in results) == 7, results
            assert request("GET", "/status/email_service_123", headers=auth)[1]["last_event"] == "email.delivered"
            assert request("POST", "/send", b"x" * 262145, send_headers)[0] == 413
            assert Handler.service_attempts == 1
            print("Service E2E passed: authenticated send, signed webhook, concurrent deduplication, state projection and body limit.")
        except BaseException:
            output.seek(0)
            print(output.read().decode(errors="replace"))
            raise
        finally:
            process.terminate()
            try:
                process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait(timeout=5)
            provider.shutdown()
            provider.server_close()


if __name__ == "__main__":
    main()
