///|
struct OfflineStore {
  mut calls : Int32
}

///|
impl ReplayStore for OfflineStore with fn check_and_record(self, _id, _now) {
  self.calls += 1
  Err(ReplayStoreUnavailable)
}

///|
async test "verify once authenticates before storage and rejects duplicate signed deliveries" {
  let verifier = WebhookVerifier::new("whsec_dGVzdHNlY3JldA==").unwrap()
  let store = WebhookReplayGuard::new()
  let payload = "{\"type\":\"email.delivered\",\"created_at\":\"2026-11-13T00:00:00Z\",\"data\":{\"email_id\":\"email_123\"}}"
  let tag = @hmac.mac(
    verifier.key[:],
    @utf8.encode("msg_test.1700000000." + payload)[:],
    fn() { @sha2.Hasher::new() },
  )
  let signature = "v1," + @base64.encode(tag)
  assert_true(
    verifier.verify_event_once(
      store, payload, "msg_test", "1700000000", "v1,bad", 1700000000L,
    )
    is Err(Verification(InvalidSignature)),
  )
  assert_eq(store.len(), 0)
  assert_true(
    verifier.verify_event_once(
      store, payload, "msg_test", "1700000000", signature, 1700000000L,
    )
    is Ok(_),
  )
  assert_true(
    verifier.verify_event_once(
      store, payload, "msg_test", "1700000000", signature, 1700000001L,
    )
    is Err(Replay(ReplayDetected(_))),
  )
  let offline = OfflineStore::{ calls: 0, }
  assert_true(
    verifier.verify_event_once(
      offline, payload, "msg_test", "1700000000", "v1,bad", 1700000000L,
    )
    is Err(Verification(_)),
  )
  assert_eq(offline.calls, 0)
  assert_true(
    verifier.verify_event_once(
      offline, payload, "msg_test", "1700000000", signature, 1700000000L,
    )
    is Err(Replay(ReplayStoreUnavailable)),
  )
  assert_eq(offline.calls, 1)
}
