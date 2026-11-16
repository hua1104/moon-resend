# Performance regression protocol

The project keeps performance measurements separate from correctness tests.
Benchmarks must use the same MoonBit toolchain and dependency lock as CI, on a
quiet machine, with at least five warm-up iterations and thirty measured
iterations.

The three required scenarios are:

1. webhook signature verification over a representative 1 KiB raw body;
2. parsing a sent-email page containing 100 records;
3. pruning a replay guard at its configured capacity.

Record the toolchain version, target, CPU model, iteration count, median and
p95 in release notes. A release must not claim a performance improvement
without a checked-in before-and-after result. CI currently runs deterministic
coverage and integration gates; benchmark numbers are intentionally not
invented until a stable benchmark harness is available on the runner.
