///|
/// Entry point for the CLI or runnable program in this template.
/// Keep main focused; move logic into the library package.
/// Run with `moon run cmd/main` from the project root.
fn main {
  let client = @resend.Client::new("re_example").unwrap()
  let email = @resend.SendEmailParams::new(
    "MoonSaaS <hello@example.com>",
    ["user@example.com"],
    "Welcome to MoonBit",
    html="<strong>Your MoonBit email integration is ready.</strong>",
    text="Your MoonBit email integration is ready.",
  )
  let request = client
    .send_request(email, idempotency_key="welcome-demo")
    .unwrap()
  println(request.verb() + " " + request.url())
  println(request.body().unwrap())
}
