///|
test "attachment and scheduling JSON use Resend field names" {
  let email = SendEmailParams::new(
    "from@example.com",
    ["to@example.com"],
    "Report",
    text="Attached",
    scheduled_at="2026-11-12T08:00:00Z",
    attachments=[
      Attachment::new("SGVsbG8=", "hello.txt", content_type="text/plain"),
    ],
  )
  let body = email.json_string()
  assert_true(body.contains("\"content_type\":\"text/plain\""))
  assert_true(body.contains("\"scheduled_at\":\"2026-11-12T08:00:00Z\""))
}

///|
test "retry metadata handles invalid hints and large delays without overflow" {
  for hint in ["-1", "2147484", "99999999999999999", "tomorrow"] {
    let error = parse_api_error(429, "{}", [("Retry-After", hint)])
    assert_eq(error.retry_after_ms(), None)
  }
  assert_eq(parse_retry_after(Some(" 2 ")), Some(2000))
  assert_eq(parse_retry_after(Some("0")), Some(0))
  assert_eq(parse_retry_after(None), None)
  let huge = RetryPolicy::new(base_delay_ms=1500000000, max_delay_ms=2147483647).unwrap()
  assert_eq(huge.delay_ms(1), 2147483647)
  for status in [408, 429, 500, 503, 599] {
    assert_true(
      ResendError::Api(parse_api_error(status, "{}", [])).is_retryable(),
    )
  }
  for status in [400, 401, 403, 422, 600] {
    assert_false(
      ResendError::Api(parse_api_error(status, "{}", [])).is_retryable(),
    )
  }
}
