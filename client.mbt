///|
pub struct Client {
  api_key : String
  base_url : String
}

///|
pub fn Client::new(
  api_key : String,
  base_url? : String,
) -> Result[Client, ResendError] {
  if api_key.trim().is_empty() {
    return Err(InvalidInput("API key must not be empty"))
  }
  let root = base_url.unwrap_or("https://api.resend.com")
  if root.trim().is_empty() {
    return Err(InvalidInput("base URL must not be empty"))
  }
  let normalized = match root.strip_suffix("/") {
    Some(value) => value.to_owned()
    None => root
  }
  Ok({ api_key, base_url: normalized, })
}

///|
fn Client::headers(
  self : Client,
  idempotency_key? : String,
) -> Array[(String, String)] {
  let headers = [
    ("Authorization", "Bearer " + self.api_key),
    ("Content-Type", "application/json"),
    ("User-Agent", "moon-resend/0.1.0"),
  ]
  match idempotency_key {
    Some(value) if !value.is_empty() => headers.push(("Idempotency-Key", value))
    _ => ()
  }
  headers
}

///|
pub fn Client::send_request(
  self : Client,
  params : SendEmailParams,
  idempotency_key? : String,
) -> Result[HttpRequest, ResendError] {
  match validate_email(params) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  Ok({
    verb: "POST",
    url: self.base_url + "/emails",
    headers: self.headers(idempotency_key?),
    body: Some(params.json_string()),
  })
}

///|
fn validate_email(params : SendEmailParams) -> Result[Unit, ResendError] {
  if params.from.trim().is_empty() {
    return Err(InvalidInput("sender must not be empty"))
  }
  if params.to.length() == 0 {
    return Err(InvalidInput("at least one recipient is required"))
  }
  for recipient in params.to {
    if recipient.trim().is_empty() {
      return Err(InvalidInput("recipients must not be empty"))
    }
  }
  if params.subject.trim().is_empty() {
    return Err(InvalidInput("subject must not be empty"))
  }
  if params.html is None && params.text is None {
    return Err(InvalidInput("either html or text content is required"))
  }
  for attachment in params.attachments {
    if attachment.filename.trim().is_empty() {
      return Err(InvalidInput("attachment filename must not be empty"))
    }
    if attachment.content.is_empty() {
      return Err(InvalidInput("attachment content must not be empty"))
    }
  }
  Ok(())
}

///|
/// Build a POST /emails/batch request. Resend currently accepts up to 100 items.
pub fn Client::batch_send_request(
  self : Client,
  emails : Array[SendEmailParams],
  idempotency_key? : String,
) -> Result[HttpRequest, ResendError] {
  if emails.length() == 0 {
    return Err(InvalidInput("batch must contain at least one email"))
  }
  if emails.length() > 100 {
    return Err(InvalidInput("batch must not contain more than 100 emails"))
  }
  for email in emails {
    match validate_email(email) {
      Err(error) => return Err(error)
      Ok(_) => ()
    }
  }
  let body = Json::array(emails.map(email => email.to_json())).stringify()
  Ok({
    verb: "POST",
    url: self.base_url + "/emails/batch",
    headers: self.headers(idempotency_key?),
    body: Some(body),
  })
}

///|
pub fn Client::retrieve_request(
  self : Client,
  id : String,
) -> Result[HttpRequest, ResendError] {
  if id.trim().is_empty() {
    return Err(InvalidInput("email id must not be empty"))
  }
  Ok({
    verb: "GET",
    url: self.base_url + "/emails/" + id,
    headers: self.headers(),
    body: None,
  })
}

///|
/// Reschedule an email that has not been sent yet.
pub fn Client::update_request(
  self : Client,
  id : String,
  params : UpdateEmailParams,
) -> Result[HttpRequest, ResendError] {
  if id.trim().is_empty() {
    return Err(InvalidInput("email id must not be empty"))
  }
  if params.scheduled_at.trim().is_empty() {
    return Err(InvalidInput("scheduled_at must not be empty"))
  }
  Ok({
    verb: "PATCH",
    url: self.base_url + "/emails/" + id,
    headers: self.headers(),
    body: Some(params.json_string()),
  })
}

///|
pub fn Client::cancel_request(
  self : Client,
  id : String,
) -> Result[HttpRequest, ResendError] {
  if id.trim().is_empty() {
    return Err(InvalidInput("email id must not be empty"))
  }
  Ok({
    verb: "POST",
    url: self.base_url + "/emails/" + id + "/cancel",
    headers: self.headers(),
    body: None,
  })
}

///|
/// Parse the shared response used by send and cancel.
pub fn Client::parse_id_response(
  _self : Client,
  response : HttpResponse,
) -> Result[EmailId, ResendError] {
  if response.status >= 200 && response.status < 300 {
    parse_email_id(response.body)
  } else {
    Err(Api(parse_api_error(response.status, response.body)))
  }
}

///|
pub fn Client::parse_batch_response(
  _self : Client,
  response : HttpResponse,
) -> Result[BatchEmailIds, ResendError] {
  if response.status >= 200 && response.status < 300 {
    parse_batch_email_ids(response.body)
  } else {
    Err(Api(parse_api_error(response.status, response.body)))
  }
}

///|
pub fn Client::parse_retrieve_response(
  _self : Client,
  response : HttpResponse,
) -> Result[RetrievedEmail, ResendError] {
  if response.status >= 200 && response.status < 300 {
    parse_retrieved_email(response.body)
  } else {
    Err(Api(parse_api_error(response.status, response.body)))
  }
}
