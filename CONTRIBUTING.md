# Contributing

Keep the SDK small, typed and testable. Before adding a large Resend resource, describe the user scenario and intended API surface in an issue.

Run moon update, moon fmt, moon check, moon test and moon info before submitting. Generated pkg.generated.mbti files must be updated when public APIs change. Tests must not require a key or send real email.

Prefer one coherent capability per commit. Do not split one implementation into artificial repositories or commit generated dependency sources.
