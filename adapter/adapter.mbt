///|
/// Execute a transport-neutral moon-resend request with moonfetch. Network,
/// TLS and timeout failures are returned as `ResendError::Transport`.
pub async fn execute(
  request : @resend.HttpRequest,
  timeout? : Int32,
) -> Result[@resend.HttpResponse, @resend.ResendError] {
  let body = match request.body() {
    Some(value) => @moonfetch.Body::Text(value)
    None => @moonfetch.Body::Empty
  }
  let received = try {
    match request.verb() {
      "GET" =>
        @moonfetch.get(
          request.url(),
          headers=request.headers(),
          timeout?,
          redirects=0,
        )
      "POST" =>
        @moonfetch.post(
          request.url(),
          body~,
          headers=request.headers(),
          timeout?,
          redirects=0,
        )
      "PATCH" =>
        @moonfetch.patch(
          request.url(),
          body~,
          headers=request.headers(),
          timeout?,
          redirects=0,
        )
      verb =>
        return Err(
          @resend.ResendError::invalid_input("unsupported HTTP method: " + verb),
        )
    }
  } catch {
    error => return Err(@resend.ResendError::transport(error.to_string()))
  }
  Ok(
    @resend.HttpResponse::new(
      received.status,
      received.text(),
      headers=received.headers,
    ),
  )
}

///|
pub async fn send(
  client : @resend.Client,
  params : @resend.SendEmailParams,
  idempotency_key? : String,
  timeout? : Int32,
) -> Result[@resend.EmailId, @resend.ResendError] {
  let request = match client.send_request(params, idempotency_key?) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  match execute(request, timeout?) {
    Ok(response) => client.parse_id_response(response)
    Err(error) => Err(error)
  }
}

///|
pub async fn send_with_retry(
  client : @resend.Client,
  params : @resend.SendEmailParams,
  idempotency_key : String,
  policy? : @resend.RetryPolicy,
  timeout? : Int32,
) -> Result[@resend.EmailId, @resend.ResendError] {
  let policy = policy.unwrap_or(@resend.RetryPolicy::new().unwrap())
  let mut attempt = 0
  let mut last : Result[@resend.EmailId, @resend.ResendError] = Err(
    @resend.ResendError::transport("retry did not execute"),
  )
  while attempt < policy.max_attempts() {
    last = send(client, params, idempotency_key~, timeout?)
    match last {
      Ok(_) => return last
      Err(error) if error.is_retryable() && attempt + 1 < policy.max_attempts() => {
        let delay = error.retry_after_ms().unwrap_or(policy.delay_ms(attempt))
        @async.sleep(delay)
        attempt += 1
      }
      Err(_) => return last
    }
  }
  last
}

///|
pub async fn send_batch(
  client : @resend.Client,
  emails : Array[@resend.SendEmailParams],
  idempotency_key? : String,
  timeout? : Int32,
) -> Result[@resend.BatchEmailIds, @resend.ResendError] {
  let request = match client.batch_send_request(emails, idempotency_key?) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  match execute(request, timeout?) {
    Ok(response) => client.parse_batch_response(response)
    Err(error) => Err(error)
  }
}

///|
pub async fn retrieve(
  client : @resend.Client,
  id : String,
  timeout? : Int32,
) -> Result[@resend.RetrievedEmail, @resend.ResendError] {
  let request = match client.retrieve_request(id) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  match execute(request, timeout?) {
    Ok(response) => client.parse_retrieve_response(response)
    Err(error) => Err(error)
  }
}

///|
pub async fn update(
  client : @resend.Client,
  id : String,
  params : @resend.UpdateEmailParams,
  timeout? : Int32,
) -> Result[@resend.EmailId, @resend.ResendError] {
  let request = match client.update_request(id, params) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  match execute(request, timeout?) {
    Ok(response) => client.parse_id_response(response)
    Err(error) => Err(error)
  }
}

///|
pub async fn cancel(
  client : @resend.Client,
  id : String,
  timeout? : Int32,
) -> Result[@resend.EmailId, @resend.ResendError] {
  let request = match client.cancel_request(id) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  match execute(request, timeout?) {
    Ok(response) => client.parse_id_response(response)
    Err(error) => Err(error)
  }
}
