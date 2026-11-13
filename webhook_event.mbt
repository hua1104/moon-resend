///|
/// Resend event names known by this SDK. Unknown names are preserved so new
/// server-side event types do not break consumers.
pub enum WebhookEventKind {
  EmailScheduled
  EmailSent
  EmailDelivered
  EmailDeliveryDelayed
  EmailComplained
  EmailBounced
  EmailOpened
  EmailClicked
  EmailFailed
  EmailSuppressed
  ContactCreated
  ContactUpdated
  ContactDeleted
  DomainCreated
  DomainUpdated
  DomainDeleted
  Other(String)
}

///|
pub fn WebhookEventKind::name(self : WebhookEventKind) -> String {
  match self {
    EmailScheduled => "email.scheduled"
    EmailSent => "email.sent"
    EmailDelivered => "email.delivered"
    EmailDeliveryDelayed => "email.delivery_delayed"
    EmailComplained => "email.complained"
    EmailBounced => "email.bounced"
    EmailOpened => "email.opened"
    EmailClicked => "email.clicked"
    EmailFailed => "email.failed"
    EmailSuppressed => "email.suppressed"
    ContactCreated => "contact.created"
    ContactUpdated => "contact.updated"
    ContactDeleted => "contact.deleted"
    DomainCreated => "domain.created"
    DomainUpdated => "domain.updated"
    DomainDeleted => "domain.deleted"
    Other(value) => value
  }
}

///|
fn webhook_kind(value : String) -> WebhookEventKind {
  match value {
    "email.scheduled" => EmailScheduled
    "email.sent" => EmailSent
    "email.delivered" => EmailDelivered
    "email.delivery_delayed" => EmailDeliveryDelayed
    "email.complained" => EmailComplained
    "email.bounced" => EmailBounced
    "email.opened" => EmailOpened
    "email.clicked" => EmailClicked
    "email.failed" => EmailFailed
    "email.suppressed" => EmailSuppressed
    "contact.created" => ContactCreated
    "contact.updated" => ContactUpdated
    "contact.deleted" => ContactDeleted
    "domain.created" => DomainCreated
    "domain.updated" => DomainUpdated
    "domain.deleted" => DomainDeleted
    value => Other(value)
  }
}

///|
/// Stable fields shared by Resend webhook resources. Resource-specific fields
/// remain available through raw_data() for forward-compatible handling.
pub struct WebhookEvent {
  kind : WebhookEventKind
  created_at : String
  resource_id : String?
  email_id : String?
  sender : String?
  recipients : Array[String]
  subject : String?
  raw_data : Json
  raw_body : String
}

///|
pub fn WebhookEvent::kind(self : WebhookEvent) -> WebhookEventKind {
  self.kind
}

///|
pub fn WebhookEvent::created_at(self : WebhookEvent) -> String {
  self.created_at
}

///|
pub fn WebhookEvent::resource_id(self : WebhookEvent) -> String? {
  self.resource_id
}

///|
pub fn WebhookEvent::email_id(self : WebhookEvent) -> String? {
  self.email_id
}

///|
pub fn WebhookEvent::sender(self : WebhookEvent) -> String? {
  self.sender
}

///|
pub fn WebhookEvent::recipients(self : WebhookEvent) -> Array[String] {
  self.recipients.copy()
}

///|
pub fn WebhookEvent::subject(self : WebhookEvent) -> String? {
  self.subject
}

///|
pub fn WebhookEvent::raw_data(self : WebhookEvent) -> Json {
  self.raw_data
}

///|
pub fn WebhookEvent::raw_body(self : WebhookEvent) -> String {
  self.raw_body
}

///|
fn webhook_string(value : Json, field : String) -> String? {
  guard value is Object(fields) else { return None }
  match fields.get(field) {
    Some(String(text)) => Some(text)
    _ => None
  }
}

///|
fn webhook_strings(value : Json, field : String) -> Array[String] {
  guard value is Object(fields) else { return [] }
  guard fields.get(field) is Some(Array(items)) else { return [] }
  let values : Array[String] = []
  for item in items {
    if item is String(text) {
      values.push(text)
    }
  }
  values
}

///|
/// Parse a webhook after signature verification. Unknown event kinds and
/// resource-specific data are retained rather than rejected.
pub fn parse_webhook_event(body : String) -> Result[WebhookEvent, WebhookError] {
  let envelope = @json.parse(body) catch {
    error => return Err(InvalidPayload("invalid JSON: " + error.to_string()))
  }
  guard envelope is Object(fields) else {
    return Err(InvalidPayload("webhook payload must be a JSON object"))
  }
  let event_name = match fields.get("type") {
    Some(String(value)) if !value.trim().is_empty() => value
    _ => return Err(InvalidPayload("payload is missing string field type"))
  }
  let created_at = match fields.get("created_at") {
    Some(String(value)) if !value.trim().is_empty() => value
    _ =>
      return Err(InvalidPayload("payload is missing string field created_at"))
  }
  let data = match fields.get("data") {
    Some(Object(_) as value) => value
    _ => return Err(InvalidPayload("payload is missing object field data"))
  }
  Ok({
    kind: webhook_kind(event_name),
    created_at,
    resource_id: webhook_string(data, "id"),
    email_id: webhook_string(data, "email_id"),
    sender: webhook_string(data, "from"),
    recipients: webhook_strings(data, "to"),
    subject: webhook_string(data, "subject"),
    raw_data: data,
    raw_body: body,
  })
}

///|
/// Result of verifying and parsing one webhook in a single operation.
pub struct VerifiedWebhookEvent {
  verification : VerifiedWebhook
  event : WebhookEvent
}

///|
pub fn VerifiedWebhookEvent::verification(
  self : VerifiedWebhookEvent,
) -> VerifiedWebhook {
  self.verification
}

///|
pub fn VerifiedWebhookEvent::event(self : VerifiedWebhookEvent) -> WebhookEvent {
  self.event
}

///|
/// Authenticate the exact raw request body, enforce freshness, then parse its
/// stable event envelope. No JSON parsing occurs before signature validation.
pub fn WebhookVerifier::verify_event(
  self : WebhookVerifier,
  payload : String,
  id : String,
  timestamp : String,
  signature : String,
  now : Int64,
  tolerance? : Int64,
) -> Result[VerifiedWebhookEvent, WebhookError] {
  let verification = match
    self.verify(payload, id, timestamp, signature, now, tolerance?) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let event = match parse_webhook_event(payload) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  Ok({ verification, event, })
}
