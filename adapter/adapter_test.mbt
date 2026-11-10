///|
async test "execute rejects unsupported methods without network access" {
  let request = @resend.HttpRequest::new(
    "DELETE", "https://example.test/emails/1",
  )
  assert_true(@adapter.execute(request) is Err(InvalidInput(_)))
}

///|
async test "execute maps transport failures without contacting Resend" {
  let request = @resend.HttpRequest::new("GET", "not-a-valid-url")
  assert_true(@adapter.execute(request) is Err(Transport(_)))
}
