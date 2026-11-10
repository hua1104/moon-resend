///|
fn object() -> Map[String, Json] {
  {}
}

///|
fn put_string(target : Map[String, Json], key : String, value : String) -> Unit {
  target[key] = Json::string(value)
}

///|
fn put_optional_string(
  target : Map[String, Json],
  key : String,
  value : String?,
) -> Unit {
  match value {
    Some(text) => target[key] = Json::string(text)
    None => ()
  }
}

///|
fn put_strings(
  target : Map[String, Json],
  key : String,
  values : Array[String],
) -> Unit {
  if values.length() > 0 {
    target[key] = Json::array(values.map(value => Json::string(value)))
  }
}

///|
fn attachment_json(value : Attachment) -> Json {
  let out = object()
  put_string(out, "content", value.content)
  put_string(out, "filename", value.filename)
  put_optional_string(out, "content_type", value.content_type)
  put_optional_string(out, "content_id", value.content_id)
  Json::object(out)
}

///|
fn tag_json(value : (String, String)) -> Json {
  let out = object()
  put_string(out, "name", value.0)
  put_string(out, "value", value.1)
  Json::object(out)
}

///|
pub fn SendEmailParams::to_json(self : SendEmailParams) -> Json {
  let out = object()
  put_string(out, "from", self.from)
  put_strings(out, "to", self.to)
  put_string(out, "subject", self.subject)
  put_optional_string(out, "html", self.html)
  put_optional_string(out, "text", self.text)
  put_strings(out, "cc", self.cc)
  put_strings(out, "bcc", self.bcc)
  put_strings(out, "reply_to", self.reply_to)
  if self.attachments.length() > 0 {
    out["attachments"] = Json::array(self.attachments.map(attachment_json))
  }
  if self.tags.length() > 0 {
    out["tags"] = Json::array(self.tags.map(tag_json))
  }
  put_optional_string(out, "scheduled_at", self.scheduled_at)
  Json::object(out)
}

///|
pub fn SendEmailParams::json_string(self : SendEmailParams) -> String {
  self.to_json().stringify()
}

///|
fn UpdateEmailParams::json_string(self : UpdateEmailParams) -> String {
  let out = object()
  put_string(out, "scheduled_at", self.scheduled_at)
  Json::object(out).stringify()
}

///|
fn field_string(value : Json, field : String) -> String? {
  match value {
    Object(fields) =>
      match fields.get(field) {
        Some(String(text)) => Some(text)
        _ => None
      }
    _ => None
  }
}

///|
fn field_strings(value : Json, field : String) -> Array[String]? {
  guard value is Object(fields) else { return None }
  guard fields.get(field) is Some(Array(items)) else { return None }
  let result : Array[String] = []
  for item in items {
    match item {
      String(text) => result.push(text)
      _ => return None
    }
  }
  Some(result)
}

///|
fn parse_email_id(body : String) -> Result[EmailId, ResendError] {
  let json = @json.parse(body) catch {
    error => return Err(InvalidResponse("invalid JSON: " + error.to_string()))
  }
  match field_string(json, "id") {
    Some(id) => Ok({ id, })
    None => Err(InvalidResponse("response is missing string field id"))
  }
}

///|
fn parse_batch_email_ids(body : String) -> Result[BatchEmailIds, ResendError] {
  let json = @json.parse(body) catch {
    error => return Err(InvalidResponse("invalid JSON: " + error.to_string()))
  }
  guard json is Object(fields) else {
    return Err(InvalidResponse("response must be a JSON object"))
  }
  guard fields.get("data") is Some(Array(items)) else {
    return Err(InvalidResponse("response is missing array field data"))
  }
  let result : Array[EmailId] = []
  for item in items {
    match field_string(item, "id") {
      Some(id) => result.push({ id, })
      None =>
        return Err(InvalidResponse("batch item is missing string field id"))
    }
  }
  Ok({ data: result, })
}

///|
fn parse_retrieved_email(body : String) -> Result[RetrievedEmail, ResendError] {
  let json = @json.parse(body) catch {
    error => return Err(InvalidResponse("invalid JSON: " + error.to_string()))
  }
  let id = match field_string(json, "id") {
    Some(value) => value
    None => return Err(InvalidResponse("response is missing string field id"))
  }
  let sender = match field_string(json, "from") {
    Some(value) => value
    None => return Err(InvalidResponse("response is missing string field from"))
  }
  let recipients = match field_strings(json, "to") {
    Some(value) => value
    None =>
      return Err(InvalidResponse("response is missing string array field to"))
  }
  let subject = match field_string(json, "subject") {
    Some(value) => value
    None =>
      return Err(InvalidResponse("response is missing string field subject"))
  }
  let created_at = match field_string(json, "created_at") {
    Some(value) => value
    None =>
      return Err(InvalidResponse("response is missing string field created_at"))
  }
  Ok({
    id,
    from: sender,
    to: recipients,
    subject,
    created_at,
    html: field_string(json, "html"),
    text: field_string(json, "text"),
    cc: field_strings(json, "cc").unwrap_or([]),
    bcc: field_strings(json, "bcc").unwrap_or([]),
    reply_to: field_strings(json, "reply_to").unwrap_or([]),
    last_event: field_string(json, "last_event"),
    scheduled_at: field_string(json, "scheduled_at"),
  })
}

///|
fn parse_api_error(status : Int32, body : String) -> ApiError {
  let json = @json.parse(body) catch { _ => Json::null() }
  let name = field_string(json, "name").unwrap_or("api_error")
  let message = field_string(json, "message").unwrap_or(body)
  { status, name, message, raw_body: body, }
}
