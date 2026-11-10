# November coverage audit

Audit date: 2026-11-10. Branch: november-polish.

## Results

- Core package: 307 / 313 executable lines covered (98.1%).
- Whole module: 321 / 417 executable lines covered (77.0%).
- Tests: 22 / 22 passing on the default Wasm target and 22 / 22 on JavaScript.

The whole-module figure includes the two executable examples and live network
paths in the Moonfetch adapter. Those paths are intentionally not exercised by
the November offline suite because it must not contact Resend or require a
secret. Request construction, validation, JSON serialization, response parsing
and error behavior live in the core package and are covered independently.

## Reproduce

~~~sh
moon coverage clean
moon coverage analyze
moon coverage report -f summary -p hua1104/moon-resend
moon coverage report -f summary
~~~

The CI workflow runs the coverage audit and fails if instrumentation or tests
cannot complete. Coverage is reported as evidence, not used as an arbitrary
100% gate.
