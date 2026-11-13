# Replay storage contract

`WebhookVerifier::verify_event_once(store, ...)` authenticates the original UTF-8
payload and checks freshness, parses the event, and then awaits the public
`ReplayStore` trait's `check_and_record(id, now)`. The ID is the verified
**Svix delivery ID**, not `data.email_id` (one email can emit many events).
Invalid signatures or payloads never call the store.

An implementation must atomically insert an unseen ID and return:

- `Ok(())` when it successfully claims the delivery;
- `Err(ReplayDetected(id))` if an unexpired claim exists;
- `Err(ReplayStoreUnavailable)` on connectivity or other storage failures.

Storage failures must never be interpreted as a successful claim. The async
trait permits network-backed implementations without introducing Redis or SQL
dependencies into the core SDK. This release includes only the in-memory
implementation; the following Redis/PostgreSQL operations are integration
contracts for an application adapter, not shipped adapters.

## In-memory implementation

`WebhookReplayGuard::new()` retains up to 10,000 delivery IDs for 86,400 seconds.
`with_limits(ttl_seconds=..., max_entries=...)` returns a validated custom store.
Pass trusted receipt time in Unix seconds, not the provider's signed timestamp.
Expired entries are removed before each insertion; `prune(now)` also permits
explicit maintenance. An entry expires when elapsed receipt time reaches TTL.
Clock rollback does not delete existing claims early.

Full stores return `ReplayStoreFull` rather than evicting live claims. Duplicate
checks still return `ReplayDetected` at capacity. `len()` reports retained
entries; `forget(id)` explicitly releases a claim. Pruning scans the bounded
map, so this implementation is for small services and tests.

The check/insert path does not suspend, allowing duplicate exclusion within one
cooperative MoonBit event loop. It is not a cross-thread synchronization
primitive, shared process store or durable exactly-once guarantee. Restart loses
claims. Choose retention to cover the provider's complete redelivery window and
your manual replay policy; the default is not a guarantee about Resend's window.

## Redis adapter operation

Use one atomic command, with an application/environment-specific prefix:

```text
SET app:production:resend:delivery:<verified-id> 1 NX EX <retention-seconds>
```

`OK` means claimed; nil means duplicate. Connection failures, timeouts and Redis
errors map to unavailable. A timeout may have committed the claim: recover from
a durable inbox rather than assuming the side effect ran. Do not implement this
as separate GET then SET commands.

## PostgreSQL adapter operation

```sql
CREATE TABLE resend_delivery_claims (
    delivery_id text PRIMARY KEY,
    expires_at timestamptz NOT NULL
);

INSERT INTO resend_delivery_claims (delivery_id, expires_at)
VALUES ($1, CURRENT_TIMESTAMP + ($2 * INTERVAL '1 second'))
ON CONFLICT (delivery_id) DO UPDATE
SET expires_at = EXCLUDED.expires_at
WHERE resend_delivery_claims.expires_at <= CURRENT_TIMESTAMP
RETURNING delivery_id;
```

Exactly one returned row means claimed; no row means duplicate. Bind `$1` to the
verified ID and `$2` to validated positive retention seconds. Clean up expired
rows periodically. The unique key arbitrates concurrent workers; the conditional
update permits reuse after retention. Use the database clock consistently.

## Claims are not completed side effects

Recording a claim before a side effect leaves a crash window. Deleting a claim
after an ambiguous external failure can also repeat a side effect that actually
succeeded. `verify_event_once` prevents duplicate admission during retention;
it does not provide end-to-end exactly-once processing.

For business-critical processing, use `verify_event` and insert the verified ID
and event into a **durable inbox** in one database transaction. A duplicate inbox
insert is acknowledged without enqueueing another job. A worker retries pending
records and atomically marks them complete together with local database updates;
use an outbox plus downstream idempotency keys for external effects. Retain or
encrypt payloads according to your privacy policy. Never store unverified data
as trusted inbox records.
