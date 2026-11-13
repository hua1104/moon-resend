///|
fn required_env(name : String) -> String {
  match @env.get_env_var(name) {
    Some(value) if !value.trim().is_empty() => value
    _ => {
      println("Missing environment variable: " + name)
      @env.exit(2)
    }
  }
}

///|
async fn reply(
  conn : @http.ServerConnection,
  status : Int32,
  body : Json,
) -> Unit {
  conn.send_response(status, "Response", extra_headers={
    "Content-Type": "application/json",
  })
  conn.write(body)
  conn.end_response()
  conn.close()
}

///|
/// Enforce the limit while streaming, including chunked requests.
async fn read_body(reader : &@io.Reader) -> String? {
  let buffer = @buffer.Buffer()
  while reader.read_some(max_len=4096) is Some(chunk) {
    if buffer.length() + chunk.length() > 262144 {
      return None
    }
    buffer.write_bytes(chunk[:])
  }
  Some(@utf8.decode(buffer.to_bytes()) catch { _ => return None })
}

///|
fn string_field(body : Json, name : String) -> String? {
  guard body is Object(fields) else { return None }
  match fields.get(name) {
    Some(String(value)) => Some(value)
    _ => None
  }
}

///|
async fn main {
  let client = @resend.Client::new(
    required_env("RESEND_API_KEY"),
    base_url?=@env.get_env_var("RESEND_BASE_URL"),
  ).unwrap()
  let verifier = @resend.WebhookVerifier::new(
    required_env("RESEND_WEBHOOK_SECRET"),
  ).unwrap()
  let sender = required_env("RESEND_FROM")
  let recipient = required_env("RESEND_TO")
  let token = required_env("DEMO_TOKEN")
  let replay_store = @resend.WebhookReplayGuard::new()
  // A process-local projection for this demo, keyed by provider email ID.
  let statuses : Map[String, String] = Map([])
  let address = @env.get_env_var("DEMO_ADDR").unwrap_or("127.0.0.1:8080")
  let server = @http.Server(@socket.Addr::parse(address))
  println("Email service listening on " + address)
  server.run_forever(max_connections=32) <| ((request, body, conn) => {
    if request.meth is Get && request.path == "/health" {
      reply(conn, 200, { "status": "ok" })
      return
    }
    let webhook = request.meth is Post && request.path == "/webhooks/resend"
    if !webhook &&
      request.headers.get(@http.CaseInsensitiveString("Authorization")) !=
      Some("Bearer " + token) {
      reply(conn, 401, { "error": "unauthorized" })
      return
    }
    if request.meth is Get && request.path.has_prefix("/status/") {
      let id = request.path.strip_prefix("/status/").unwrap().to_owned()
      match statuses.get(id) {
        Some(status) => reply(conn, 200, { "id": id, "last_event": status })
        None => reply(conn, 404, { "error": "unknown email" })
      }
      return
    }
    if !webhook && !(request.meth is Post && request.path == "/send") {
      reply(conn, 404, { "error": "not found" })
      return
    }
    let raw = match @async.with_timeout_opt(5000, () => read_body(body)) {
      Some(Some(value)) => value
      _ => {
        reply(conn, 413, {
          "error": "body too large, invalid UTF-8 or timed out",
        })
        return
      }
    }
    if webhook {
      let id = request.headers
        .get(@http.CaseInsensitiveString("svix-id"))
        .unwrap_or("")
      let timestamp = request.headers
        .get(@http.CaseInsensitiveString("svix-timestamp"))
        .unwrap_or("")
      let signature = request.headers
        .get(@http.CaseInsensitiveString("svix-signature"))
        .unwrap_or("")
      let now = (@env.now() / 1000UL).reinterpret_as_int64()
      match
        verifier.verify_event_once(
          replay_store, raw, id, timestamp, signature, now,
        ) {
        Ok(verified) => {
          let event = verified.event()
          if event.email_id() is Some(email_id) && statuses.contains(email_id) {
            statuses[email_id] = event.kind().name()
          }
          reply(conn, 200, { "status": "processed" })
        }
        Err(Replay(ReplayDetected(_))) =>
          reply(conn, 200, { "status": "duplicate" })
        Err(Replay(_)) =>
          reply(conn, 503, { "error": "replay store unavailable" })
        Err(Verification(_)) => reply(conn, 400, { "error": "invalid webhook" })
      }
      return
    }
    let input = @json.parse(raw) catch {
      _ => {
        reply(conn, 400, { "error": "invalid JSON" })
        return
      }
    }
    guard string_field(input, "subject") is Some(subject) &&
      string_field(input, "text") is Some(text) else {
      reply(conn, 400, { "error": "subject and text are required" })
      return
    }
    let key = request.headers
      .get(@http.CaseInsensitiveString("Idempotency-Key"))
      .unwrap_or("")
    if statuses.length() >= 10000 {
      reply(conn, 503, { "error": "demo state capacity reached" })
      return
    }
    let params = @resend.SendEmailParams::new(
      sender,
      [recipient],
      subject,
      text~,
    )
    match @adapter.send_with_retry(client, params, key, timeout=5000) {
      Ok(email) => {
        if !statuses.contains(email.id()) {
          statuses[email.id()] = "accepted"
        }
        reply(conn, 200, { "id": email.id() })
      }
      Err(InvalidInput(_)) =>
        reply(conn, 400, { "error": "invalid email or idempotency key" })
      Err(_) => reply(conn, 502, { "error": "email provider failed" })
    }
  })
}
