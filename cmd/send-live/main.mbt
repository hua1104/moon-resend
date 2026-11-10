///|
fn required_env(name : String) -> String {
  match @env.get_env_var(name) {
    Some(value) if !value.trim().is_empty() => value
    _ => {
      println("Missing required environment variable: " + name)
      @env.exit(2)
    }
  }
}

///|
async fn main {
  let api_key = required_env("RESEND_API_KEY")
  let sender = required_env("RESEND_FROM")
  let recipient = required_env("RESEND_TO")
  let client = @resend.Client::new(api_key).unwrap()
  let email = @resend.SendEmailParams::new(
    sender,
    [recipient],
    "moon-resend live adapter demo",
    html="<strong>moon-resend is connected.</strong>",
    text="moon-resend is connected.",
    tags=[("source", "competition-demo")],
  )
  match
    @adapter.send(
      client,
      email,
      idempotency_key="moon-resend-live-demo",
      timeout=15000,
    ) {
    Ok(sent) => println("Email accepted by Resend: " + sent.id())
    Err(InvalidInput(message)) => println("Invalid input: " + message)
    Err(Api(error)) =>
      println(
        "Resend API error " +
        error.status().to_string() +
        " (" +
        error.name() +
        "): " +
        error.message(),
      )
    Err(InvalidResponse(message)) =>
      println("Invalid Resend response: " + message)
    Err(Transport(message)) => println("Transport failure: " + message)
  }
}
