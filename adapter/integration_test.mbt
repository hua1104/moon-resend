///|
fn integration_base() -> String? {
  @env.get_env_var("MOON_RESEND_MOCK_URL")
}

///|
fn integration_email() -> @resend.SendEmailParams {
  @resend.SendEmailParams::new(
    "Moon <hello@example.com>",
    ["user@example.com"],
    "Integration test",
    html="<strong>Hello</strong>",
    text="Hello",
  )
}

///|
async test "adapter sends headers and JSON to a real HTTP server" {
  guard integration_base() is Some(base) else { return }
  let client = @resend.Client::new("re_integration", base_url=base).unwrap()
  let sent = @adapter.send(
    client,
    integration_email(),
    idempotency_key="integration-42",
    timeout=2000,
  ).unwrap()
  assert_eq(sent.id(), "email_mock_123")
}

///|
async test "adapter parses lifecycle responses over real HTTP" {
  guard integration_base() is Some(base) else { return }
  let client = @resend.Client::new("re_integration", base_url=base).unwrap()
  let retrieved = @adapter.retrieve(client, "email_mock_123", timeout=2000).unwrap()
  assert_eq(retrieved.id(), "email_mock_123")
  assert_eq(retrieved.last_event(), Some("delivered"))
  let updated = @adapter.update(
    client,
    "email_mock_123",
    @resend.UpdateEmailParams::new("2026-12-01T08:00:00Z"),
    timeout=2000,
  ).unwrap()
  assert_eq(updated.id(), "email_mock_123")
  let cancelled = @adapter.cancel(client, "email_mock_123", timeout=2000).unwrap()
  assert_eq(cancelled.id(), "email_mock_123")
}

///|
async test "adapter preserves structured API failures over real HTTP" {
  guard integration_base() is Some(base) else { return }
  let client = @resend.Client::new(
    "re_integration",
    base_url=base + "/api-error",
  ).unwrap()
  let failed = @adapter.send(client, integration_email(), timeout=2000)
  guard failed is Err(Api(error)) else { fail("expected typed API error") }
  assert_eq(error.status(), 422)
  assert_eq(error.name(), "validation_error")
  assert_eq(error.message(), "mock recipient rejected")
  assert_eq(error.request_id(), Some("req_validation_1"))
  assert_eq(error.retry_after_ms(), Some(7000))
  assert_eq(failed.unwrap_err().request_id(), Some("req_validation_1"))
  assert_eq(failed.unwrap_err().retry_after_ms(), Some(7000))
}

///|
async test "adapter retries transient failures with one stable idempotency key" {
  guard integration_base() is Some(base) else { return }
  let client = @resend.Client::new("re_integration", base_url=base + "/retry").unwrap()
  let policy = @resend.RetryPolicy::new(
    max_attempts=3,
    base_delay_ms=0,
    max_delay_ms=0,
  ).unwrap()
  let sent = @adapter.send_with_retry(
    client,
    integration_email(),
    "retry-integration-42",
    policy~,
    timeout=2000,
  ).unwrap()
  assert_eq(sent.id(), "email_retry_123")
}

///|
async test "adapter does not retry non-retryable API failures" {
  guard integration_base() is Some(base) else { return }
  let client = @resend.Client::new(
    "re_integration",
    base_url=base + "/no-retry",
  ).unwrap()
  let policy = @resend.RetryPolicy::new(
    max_attempts=3,
    base_delay_ms=0,
    max_delay_ms=0,
  ).unwrap()
  let failed = @adapter.send_with_retry(
    client,
    integration_email(),
    "no-retry-integration-42",
    policy~,
    timeout=2000,
  )
  guard failed is Err(Api(error)) else { fail("expected typed API error") }
  assert_eq(error.status(), 422)
  assert_eq(error.message(), "do not retry")
}

///|
async test "adapter maps real HTTP timeouts to transport errors" {
  guard integration_base() is Some(base) else { return }
  let client = @resend.Client::new("re_integration", base_url=base + "/slow").unwrap()
  assert_true(
    @adapter.send(client, integration_email(), timeout=50) is Err(Transport(_)),
  )
}
