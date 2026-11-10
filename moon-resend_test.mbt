///|
fn sample_email() -> @moon-resend.SendEmailParams {
  @moon-resend.SendEmailParams::new(
    "MoonSaaS <hello@example.com>",
    ["jin@example.com"],
    "Welcome",
    html="<strong>Hello</strong>",
    text="Hello",
    reply_to=["support@example.com"],
    tags=[("kind", "welcome")],
  )
}

///|
test "build send request with auth, idempotency and JSON body" {
  let client = @moon-resend.Client::new(
    "re_test",
    base_url="https://example.test/v1",
  ).unwrap()
  let request = client
    .send_request(sample_email(), idempotency_key="signup-42")
    .unwrap()
  assert_eq(request.verb(), "POST")
  assert_eq(request.url(), "https://example.test/v1/emails")
  assert_true(request.headers().contains(("Authorization", "Bearer re_test")))
  assert_true(request.headers().contains(("Idempotency-Key", "signup-42")))
  let body = request.body().unwrap()
  assert_true(body.contains("\"subject\":\"Welcome\""))
  assert_true(body.contains("\"name\":\"kind\""))
}

///|
test "reject missing recipients and content before transport" {
  let client = @moon-resend.Client::new("re_test").unwrap()
  let empty = @moon-resend.SendEmailParams::new(
    "from@example.com",
    [],
    "subject",
  )
  assert_true(client.send_request(empty) is Err(InvalidInput(_)))
  let no_content = @moon-resend.SendEmailParams::new(
    "from@example.com",
    ["to@example.com"],
    "subject",
  )
  assert_true(client.send_request(no_content) is Err(InvalidInput(_)))
}

///|
test "parse success and structured API error" {
  let client = @moon-resend.Client::new("re_test").unwrap()
  let sent = client.parse_id_response(
    @moon-resend.HttpResponse::new(200, "{\"id\":\"email_123\"}"),
  )
  assert_eq(sent.unwrap().id(), "email_123")
  let failed = client.parse_id_response(
    @moon-resend.HttpResponse::new(
      422, "{\"name\":\"validation_error\",\"message\":\"invalid recipient\"}",
    ),
  )
  guard failed is Err(Api(error)) else { fail("expected API error") }
  assert_eq(error.status(), 422)
  assert_eq(error.name(), "validation_error")
  assert_eq(error.message(), "invalid recipient")
}

///|
test "build retrieve and cancel requests" {
  let client = @moon-resend.Client::new("re_test").unwrap()
  assert_eq(
    client.retrieve_request("email_1").unwrap().url(),
    "https://api.resend.com/emails/email_1",
  )
  let cancel = client.cancel_request("email_1").unwrap()
  assert_eq(cancel.verb(), "POST")
  assert_eq(cancel.url(), "https://api.resend.com/emails/email_1/cancel")
}

///|
test "normalize base URL and parse malformed responses safely" {
  let client = @moon-resend.Client::new(
    "re_test",
    base_url="https://example.test/",
  ).unwrap()
  assert_eq(
    client.retrieve_request("email_1").unwrap().url(),
    "https://example.test/emails/email_1",
  )
  assert_true(
    client.parse_id_response(@moon-resend.HttpResponse::new(200, "not-json"))
    is Err(InvalidResponse(_)),
  )
  let failed = client.parse_id_response(
    @moon-resend.HttpResponse::new(500, "upstream unavailable"),
  )
  guard failed is Err(Api(error)) else { fail("expected API error") }
  assert_eq(error.message(), "upstream unavailable")
}

///|
test "build and parse a batch request" {
  let client = @moon-resend.Client::new("re_test").unwrap()
  let request = client
    .batch_send_request(
      [sample_email(), sample_email()],
      idempotency_key="batch-1",
    )
    .unwrap()
  assert_eq(request.verb(), "POST")
  assert_eq(request.url(), "https://api.resend.com/emails/batch")
  assert_true(request.body().unwrap().has_prefix("[{"))
  let result = client
    .parse_batch_response(
      @moon-resend.HttpResponse::new(
        200, "{\"data\":[{\"id\":\"email_1\"},{\"id\":\"email_2\"}]}",
      ),
    )
    .unwrap()
  assert_eq(result.data().length(), 2)
  assert_eq(result.data()[1].id(), "email_2")
}

///|
test "reject incomplete emails and invalid batches" {
  let client = @moon-resend.Client::new("re_test").unwrap()
  let blank_subject = @moon-resend.SendEmailParams::new(
    "from@example.com",
    ["to@example.com"],
    "  ",
    text="hello",
  )
  assert_true(client.send_request(blank_subject) is Err(InvalidInput(_)))
  assert_true(client.batch_send_request([]) is Err(InvalidInput(_)))
}

///|
test "build update request and parse a retrieved email" {
  let client = @moon-resend.Client::new("re_test").unwrap()
  let update = client
    .update_request(
      "email_1",
      @moon-resend.UpdateEmailParams::new("2026-11-20T08:00:00Z"),
    )
    .unwrap()
  assert_eq(update.verb(), "PATCH")
  assert_eq(update.url(), "https://api.resend.com/emails/email_1")
  assert_true(
    update.body().unwrap().contains("\"scheduled_at\":\"2026-11-20T08:00:00Z\""),
  )
  let retrieved = client
    .parse_retrieve_response(
      @moon-resend.HttpResponse::new(
        200, "{\"id\":\"email_1\",\"from\":\"Moon <hello@example.com>\",\"to\":[\"user@example.com\"],\"subject\":\"Hello\",\"created_at\":\"2026-11-10T08:00:00Z\",\"last_event\":\"delivered\"}",
      ),
    )
    .unwrap()
  assert_eq(retrieved.id(), "email_1")
  assert_eq(retrieved.sender(), "Moon <hello@example.com>")
  assert_eq(retrieved.recipients(), ["user@example.com"])
  assert_eq(retrieved.last_event(), Some("delivered"))
}

///|
test "reject blank lifecycle parameters and malformed retrieve payloads" {
  let client = @moon-resend.Client::new("re_test").unwrap()
  assert_true(client.retrieve_request("  ") is Err(InvalidInput(_)))
  assert_true(client.cancel_request("  ") is Err(InvalidInput(_)))
  assert_true(
    client.update_request("email_1", @moon-resend.UpdateEmailParams::new("  "))
    is Err(InvalidInput(_)),
  )
  assert_true(
    client.parse_retrieve_response(
      @moon-resend.HttpResponse::new(200, "{\"id\":\"email_1\"}"),
    )
    is Err(InvalidResponse(_)),
  )
}
