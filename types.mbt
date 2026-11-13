///|
/// A transport-neutral HTTP request. Adapters can map this value to any
/// MoonBit HTTP client without coupling the SDK core to one runtime.
pub struct HttpRequest {
  verb : String
  url : String
  headers : Array[(String, String)]
  body : String?
}

///|
pub fn HttpRequest::verb(self : HttpRequest) -> String {
  self.verb
}

///|
pub fn HttpRequest::url(self : HttpRequest) -> String {
  self.url
}

///|
pub fn HttpRequest::headers(self : HttpRequest) -> Array[(String, String)] {
  self.headers.copy()
}

///|
pub fn HttpRequest::body(self : HttpRequest) -> String? {
  self.body
}

///|
/// Construct a custom request for adapters and tests. Most applications should
/// use the request builders on `Client`.
pub fn HttpRequest::new(
  verb : String,
  url : String,
  headers? : Array[(String, String)],
  body? : String,
) -> HttpRequest {
  { verb, url, headers: headers.unwrap_or([]), body, }
}

///|
/// A transport-neutral HTTP response returned by an adapter or test fake.
pub struct HttpResponse {
  status : Int32
  headers : Array[(String, String)]
  body : String
}

///|
pub fn HttpResponse::new(
  status : Int32,
  body : String,
  headers? : Array[(String, String)],
) -> HttpResponse {
  { status, body, headers: headers.unwrap_or([]), }
}

///|
pub fn HttpResponse::status(self : HttpResponse) -> Int32 {
  self.status
}

///|
pub fn HttpResponse::body(self : HttpResponse) -> String {
  self.body
}

///|
pub fn HttpResponse::headers(self : HttpResponse) -> Array[(String, String)] {
  self.headers.copy()
}

///|
/// A file attachment. The content must be Base64 encoded as required by Resend.
pub struct Attachment {
  content : String
  filename : String
  content_type : String?
  content_id : String?
}

///|
pub fn Attachment::new(
  content : String,
  filename : String,
  content_type? : String,
  content_id? : String,
) -> Attachment {
  { content, filename, content_type, content_id, }
}

///|
/// Parameters accepted by Resend POST /emails.
pub struct SendEmailParams {
  from : String
  to : Array[String]
  subject : String
  html : String?
  text : String?
  cc : Array[String]
  bcc : Array[String]
  reply_to : Array[String]
  attachments : Array[Attachment]
  tags : Array[(String, String)]
  scheduled_at : String?
}

///|
pub fn SendEmailParams::new(
  from : String,
  to : Array[String],
  subject : String,
  html? : String,
  text? : String,
  cc? : Array[String],
  bcc? : Array[String],
  reply_to? : Array[String],
  attachments? : Array[Attachment],
  tags? : Array[(String, String)],
  scheduled_at? : String,
) -> SendEmailParams {
  {
    from,
    to,
    subject,
    html,
    text,
    cc: cc.unwrap_or([]),
    bcc: bcc.unwrap_or([]),
    reply_to: reply_to.unwrap_or([]),
    attachments: attachments.unwrap_or([]),
    tags: tags.unwrap_or([]),
    scheduled_at,
  }
}

///|
pub struct EmailId {
  id : String
}

///|
/// IDs returned by Resend POST /emails/batch.
pub struct BatchEmailIds {
  data : Array[EmailId]
}

///|
/// Parameters accepted by Resend PATCH /emails/:id.
pub struct UpdateEmailParams {
  scheduled_at : String
}

///|
pub fn UpdateEmailParams::new(scheduled_at : String) -> UpdateEmailParams {
  { scheduled_at, }
}

///|
/// The stable subset returned by Resend GET /emails/:id. Optional fields stay
/// optional because Resend omits content fields in some delivery states.
pub struct RetrievedEmail {
  id : String
  from : String
  to : Array[String]
  subject : String
  created_at : String
  html : String?
  text : String?
  cc : Array[String]
  bcc : Array[String]
  reply_to : Array[String]
  last_event : String?
  scheduled_at : String?
}

///|
pub fn RetrievedEmail::id(self : RetrievedEmail) -> String {
  self.id
}

///|
pub fn RetrievedEmail::sender(self : RetrievedEmail) -> String {
  self.from
}

///|
pub fn RetrievedEmail::recipients(self : RetrievedEmail) -> Array[String] {
  self.to.copy()
}

///|
pub fn RetrievedEmail::subject(self : RetrievedEmail) -> String {
  self.subject
}

///|
pub fn RetrievedEmail::created_at(self : RetrievedEmail) -> String {
  self.created_at
}

///|
pub fn RetrievedEmail::last_event(self : RetrievedEmail) -> String? {
  self.last_event
}

///|
pub fn RetrievedEmail::scheduled_at(self : RetrievedEmail) -> String? {
  self.scheduled_at
}

///|
pub fn RetrievedEmail::html(self : RetrievedEmail) -> String? {
  self.html
}

///|
pub fn RetrievedEmail::text(self : RetrievedEmail) -> String? {
  self.text
}

///|
pub fn RetrievedEmail::cc(self : RetrievedEmail) -> Array[String] {
  self.cc.copy()
}

///|
pub fn RetrievedEmail::bcc(self : RetrievedEmail) -> Array[String] {
  self.bcc.copy()
}

///|
pub fn RetrievedEmail::reply_to(self : RetrievedEmail) -> Array[String] {
  self.reply_to.copy()
}

///|
pub fn BatchEmailIds::data(self : BatchEmailIds) -> Array[EmailId] {
  self.data.copy()
}

///|
pub fn EmailId::id(self : EmailId) -> String {
  self.id
}

///|
pub struct ApiError {
  status : Int32
  name : String
  message : String
  raw_body : String
  request_id : String?
  retry_after_ms : Int32?
}

///|
pub fn ApiError::status(self : ApiError) -> Int32 {
  self.status
}

///|
pub fn ApiError::name(self : ApiError) -> String {
  self.name
}

///|
pub fn ApiError::message(self : ApiError) -> String {
  self.message
}

///|
pub fn ApiError::raw_body(self : ApiError) -> String {
  self.raw_body
}

///|
pub fn ApiError::request_id(self : ApiError) -> String? {
  self.request_id
}

///|
pub fn ApiError::retry_after_ms(self : ApiError) -> Int32? {
  self.retry_after_ms
}

///|
pub enum ResendError {
  InvalidInput(String)
  Api(ApiError)
  InvalidResponse(String)
  Transport(String)
}

///|
pub fn ResendError::is_retryable(self : ResendError) -> Bool {
  match self {
    Api(error) =>
      error.status() == 408 ||
      error.status() == 429 ||
      (error.status() >= 500 && error.status() <= 599)
    Transport(_) => true
    _ => false
  }
}

///|
/// Return the provider request identifier when the error came from the API.
pub fn ResendError::request_id(self : ResendError) -> String? {
  match self {
    Api(error) => error.request_id()
    _ => None
  }
}

///|
/// Return the provider retry hint in milliseconds, when present.
pub fn ResendError::retry_after_ms(self : ResendError) -> Int32? {
  match self {
    Api(error) => error.retry_after_ms()
    _ => None
  }
}

///|
/// Create an input error from an adapter or extension package.
pub fn ResendError::invalid_input(message : String) -> ResendError {
  InvalidInput(message)
}

///|
/// Create a network, TLS or timeout error from a transport adapter.
pub fn ResendError::transport(message : String) -> ResendError {
  Transport(message)
}

///|
/// A concise description suitable for application logs.
pub fn ResendError::message(self : ResendError) -> String {
  match self {
    InvalidInput(message) => "invalid input: " + message
    Api(error) =>
      "Resend API error " +
      error.status().to_string() +
      " (" +
      error.name() +
      "): " +
      error.message()
    InvalidResponse(message) => "invalid Resend response: " + message
    Transport(message) => "transport failure: " + message
  }
}
