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
}

///|
async test "adapter maps real HTTP timeouts to transport errors" {
  guard integration_base() is Some(base) else { return }
  let client = @resend.Client::new("re_integration", base_url=base + "/slow").unwrap()
  assert_true(
    @adapter.send(client, integration_email(), timeout=50) is Err(Transport(_)),
  )
}
