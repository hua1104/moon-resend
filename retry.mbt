///|
pub struct RetryPolicy {
  max_attempts : Int32
  base_delay_ms : Int32
  max_delay_ms : Int32
}

///|
pub fn RetryPolicy::new(
  max_attempts? : Int32,
  base_delay_ms? : Int32,
  max_delay_ms? : Int32,
) -> Result[RetryPolicy, ResendError] {
  let attempts = max_attempts.unwrap_or(3)
  let base = base_delay_ms.unwrap_or(100)
  let maximum = max_delay_ms.unwrap_or(2000)
  if attempts < 1 || base < 0 || maximum < base {
    return Err(InvalidInput("invalid retry policy bounds"))
  }
  Ok({ max_attempts: attempts, base_delay_ms: base, max_delay_ms: maximum, })
}

///|
pub fn RetryPolicy::max_attempts(self : RetryPolicy) -> Int32 {
  self.max_attempts
}

///|
pub fn RetryPolicy::delay_ms(self : RetryPolicy, attempt : Int32) -> Int32 {
  let mut delay = self.base_delay_ms
  for _ in 0..<attempt {
    if delay >= self.max_delay_ms || delay > self.max_delay_ms / 2 {
      return self.max_delay_ms
    }
    delay = delay * 2
  }
  if delay > self.max_delay_ms {
    self.max_delay_ms
  } else {
    delay
  }
}
