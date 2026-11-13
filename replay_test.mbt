///|
test "replay retention expires at the boundary without evicting live IDs" {
  let store = @moon-resend.WebhookReplayGuard::with_limits(
    ttl_seconds=10L,
    max_entries=1,
  ).unwrap()
  assert_true(store.check_and_record("a", 100L) is Ok(_))
  assert_true(store.check_and_record("b", 109L) is Err(ReplayStoreFull))
  assert_true(store.check_and_record("a", 109L) is Err(ReplayDetected(_)))
  assert_eq(store.len(), 1)
  assert_true(store.check_and_record("b", 110L) is Ok(_))
  assert_eq(store.len(), 1)
  assert_eq(store.prune(119L), 0)
  assert_eq(store.prune(120L), 1)
  assert_false(store.forget("b"))
}

///|
test "replay limits reject invalid configuration and tolerate clock rollback" {
  assert_true(
    @moon-resend.WebhookReplayGuard::with_limits(ttl_seconds=0L, max_entries=1)
    is Err(InvalidReplayConfig(_)),
  )
  assert_true(
    @moon-resend.WebhookReplayGuard::with_limits(ttl_seconds=1L, max_entries=0)
    is Err(InvalidReplayConfig(_)),
  )
  let store = @moon-resend.WebhookReplayGuard::new()
  assert_true(store.check_and_record("a", -1L) is Err(InvalidReplayConfig(_)))
  assert_true(store.check_and_record("a", 100L) is Ok(_))
  assert_true(store.check_and_record("a", 99L) is Err(ReplayDetected(_)))
  assert_eq(store.prune(99L), 0)
}
