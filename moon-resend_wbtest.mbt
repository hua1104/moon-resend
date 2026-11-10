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
