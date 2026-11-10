///|
/// Errors returned while validating a Resend/Svix webhook.
pub enum WebhookError {
  InvalidSecret(String)
  InvalidHeader(String)
  InvalidTimestamp(String)
  TimestampOutsideTolerance
  InvalidSignature
}

///|
pub fn WebhookError::message(self : WebhookError) -> String {
  match self {
    InvalidSecret(message) => "invalid webhook secret: " + message
    InvalidHeader(message) => "invalid webhook header: " + message
    InvalidTimestamp(message) => "invalid webhook timestamp: " + message
    TimestampOutsideTolerance =>
      "webhook timestamp is outside the allowed tolerance"
    InvalidSignature => "webhook signature does not match"
  }
}

///|
/// Metadata returned only after the payload, message id and timestamp have
/// passed signature and freshness validation.
pub struct VerifiedWebhook {
  id : String
  timestamp : Int64
}

///|
pub fn VerifiedWebhook::id(self : VerifiedWebhook) -> String {
  self.id
}

///|
pub fn VerifiedWebhook::timestamp(self : VerifiedWebhook) -> Int64 {
  self.timestamp
}

///|
/// Verifies the Svix-compatible signatures used by Resend webhooks. Construct
/// this once from the signing secret shown in the Resend dashboard.
pub struct WebhookVerifier {
  key : Bytes
}

///|
pub fn WebhookVerifier::new(
  secret : String,
) -> Result[WebhookVerifier, WebhookError] {
  let encoded = match secret.strip_prefix("whsec_") {
    Some(value) => value
    None => return Err(InvalidSecret("expected whsec_ prefix"))
  }
  if encoded.is_empty() {
    return Err(InvalidSecret("secret body must not be empty"))
  }
  let key = @base64.decode(encoded) catch {
    _ => return Err(InvalidSecret("secret body must be valid Base64"))
  }
  if key.length() == 0 {
    return Err(InvalidSecret("decoded secret must not be empty"))
  }
  Ok({ key, })
}

///|
fn parse_webhook_timestamp(value : String) -> Result[Int64, WebhookError] {
  if value.is_empty() {
    return Err(InvalidTimestamp("value must not be empty"))
  }
  let mut parsed = 0L
  for i in 0..<value.length() {
    let digit = value.unsafe_get(i).to_int() - 48
    if digit < 0 || digit > 9 {
      return Err(InvalidTimestamp("value must contain decimal digits only"))
    }
    if parsed > (9223372036854775807L - digit.to_int64()) / 10L {
      return Err(InvalidTimestamp("value is too large"))
    }
    parsed = parsed * 10L + digit.to_int64()
  }
  Ok(parsed)
}

///|
fn signature_matches(header : String, expected : Bytes) -> Bool {
  for item in header.split(" ") {
    match item.to_owned().split_once(",") {
      Some((version, encoded)) if version == "v1" => {
        let supplied = @base64.decode(encoded) catch { _ => continue }
        if @spec.eq(supplied[:], expected[:]) {
          return true
        }
      }
      _ => ()
    }
  }
  false
}

///|
/// Verify a raw request body and the svix-id, svix-timestamp and
/// svix-signature header values. now is Unix time in seconds. The default
/// five-minute tolerance rejects old or far-future payloads; applications must
/// additionally remember VerifiedWebhook::id() to reject duplicate delivery.
pub fn WebhookVerifier::verify(
  self : WebhookVerifier,
  payload : String,
  id : String,
  timestamp : String,
  signature : String,
  now : Int64,
  tolerance? : Int64,
) -> Result[VerifiedWebhook, WebhookError] {
  if id.trim().is_empty() {
    return Err(InvalidHeader("svix-id must not be empty"))
  }
  if signature.trim().is_empty() {
    return Err(InvalidHeader("svix-signature must not be empty"))
  }
  let seconds = match parse_webhook_timestamp(timestamp) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let window = tolerance.unwrap_or(300L)
  if window < 0L {
    return Err(InvalidTimestamp("tolerance must not be negative"))
  }
  let distance = if now >= seconds { now - seconds } else { seconds - now }
  if distance > window {
    return Err(TimestampOutsideTolerance)
  }
  let signed = id + "." + timestamp + "." + payload
  let tag = @hmac.mac(self.key[:], @utf8.encode(signed)[:], fn() {
    @sha2.Hasher::new()
  })
  if !signature_matches(signature, tag) {
    return Err(InvalidSignature)
  }
  Ok({ id, timestamp: seconds, })
}
