///|
pub enum ReplayError {
  ReplayDetected(String)
  InvalidReplayId(String)
}

///|
pub fn ReplayError::message(self : ReplayError) -> String {
  match self {
    ReplayDetected(id) => "webhook event was already processed: " + id
    InvalidReplayId(message) => "invalid webhook replay id: " + message
  }
}

///|
pub struct WebhookReplayGuard {
  seen : Map[String, Int64]
}

///|
pub fn WebhookReplayGuard::new() -> WebhookReplayGuard {
  { seen: {}, }
}

///|
pub fn WebhookReplayGuard::check_and_record(
  self : WebhookReplayGuard,
  id : String,
  timestamp : Int64,
) -> Result[Unit, ReplayError] {
  if id.trim().is_empty() {
    return Err(InvalidReplayId("event id must not be empty"))
  }
  if self.seen.contains(id) {
    return Err(ReplayDetected(id))
  }
  self.seen[id] = timestamp
  Ok(())
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
