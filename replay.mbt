///|
pub enum ReplayError {
  ReplayDetected(String)
  InvalidReplayId(String)
  InvalidReplayConfig(String)
  ReplayStoreFull
  ReplayStoreUnavailable
}

///|
pub fn ReplayError::message(self : ReplayError) -> String {
  match self {
    ReplayDetected(id) => "webhook event was already processed: " + id
    InvalidReplayId(message) => "invalid webhook replay id: " + message
    InvalidReplayConfig(message) =>
      "invalid replay store configuration: " + message
    ReplayStoreFull => "webhook replay store is full"
    ReplayStoreUnavailable => "webhook replay store is unavailable"
  }
}

///|
pub struct WebhookReplayGuard {
  seen : Map[String, Int64]
  ttl_seconds : Int64
  max_entries : Int32
}

///|
pub fn WebhookReplayGuard::new() -> WebhookReplayGuard {
  { seen: {}, ttl_seconds: 86400L, max_entries: 10000, }
}

///|
/// Retention uses the trusted receipt clock, never the signed event timestamp.
pub fn WebhookReplayGuard::with_limits(
  ttl_seconds~ : Int64,
  max_entries~ : Int32,
) -> Result[WebhookReplayGuard, ReplayError] {
  if ttl_seconds <= 0L || max_entries <= 0 {
    return Err(InvalidReplayConfig("TTL and capacity must be positive"))
  }
  Ok({ seen: {}, ttl_seconds, max_entries, })
}

///|
pub fn WebhookReplayGuard::len(self : WebhookReplayGuard) -> Int32 {
  self.seen.length()
}

///|
pub fn WebhookReplayGuard::prune(
  self : WebhookReplayGuard,
  now : Int64,
) -> Int32 {
  let expired : Array[String] = []
  for id, recorded_at in self.seen {
    if now >= recorded_at && now - recorded_at >= self.ttl_seconds {
      expired.push(id)
    }
  }
  for id in expired {
    self.seen.remove(id)
  }
  expired.length()
}

///|
pub fn WebhookReplayGuard::check_and_record(
  self : WebhookReplayGuard,
  id : String,
  now : Int64,
) -> Result[Unit, ReplayError] {
  if id.trim().is_empty() {
    return Err(InvalidReplayId("event id must not be empty"))
  }
  if now < 0L {
    return Err(InvalidReplayConfig("receipt clock must be nonnegative"))
  }
  self.prune(now) |> ignore
  if self.seen.contains(id) {
    return Err(ReplayDetected(id))
  }
  if self.seen.length() >= self.max_entries {
    return Err(ReplayStoreFull)
  }
  self.seen[id] = now
  Ok(())
}

///|
/// An implementation must atomically insert if absent and fail closed on
/// storage errors. Use receipt time for retention. Redis/database implementations
/// may suspend; the in-memory implementation never suspends during insertion.
pub(open) trait ReplayStore {
  async fn check_and_record(Self, String, Int64) -> Result[Unit, ReplayError]
}

///|
pub impl ReplayStore for WebhookReplayGuard with fn check_and_record(
  self,
  id,
  now,
) {
  self.check_and_record(id, now)
}

///|
pub enum WebhookProcessingError {
  Verification(WebhookError)
  Replay(ReplayError)
}

///|
/// Verify raw bytes represented as UTF-8, parse, then claim the delivery ID.
/// No store call occurs for unauthenticated or malformed events.
pub async fn[S : ReplayStore] WebhookVerifier::verify_event_once(
  self : WebhookVerifier,
  store : S,
  payload : String,
  id : String,
  timestamp : String,
  signature : String,
  now : Int64,
  tolerance? : Int64,
) -> Result[VerifiedWebhookEvent, WebhookProcessingError] {
  let verified = match
    self.verify_event(payload, id, timestamp, signature, now, tolerance?) {
    Ok(event) => event
    Err(error) => return Err(Verification(error))
  }
  match store.check_and_record(verified.verification().id(), now) {
    Ok(_) => Ok(verified)
    Err(error) => Err(Replay(error))
  }
}

///|
pub fn WebhookReplayGuard::forget(
  self : WebhookReplayGuard,
  id : String,
) -> Bool {
  if self.seen.contains(id) {
    self.seen.remove(id)
    true
  } else {
    false
  }
}
