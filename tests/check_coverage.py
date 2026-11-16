"""Enforce the repository's minimum MoonBit coverage contract."""

from __future__ import annotations

import sys
from pathlib import Path

THRESHOLD = 60.0


def main() -> int:
    if len(sys.argv) != 2:
        raise SystemExit("usage: check_coverage.py COVERAGE_SUMMARY")
    summary = Path(sys.argv[1]).read_text(encoding="utf-8")
    total_line = next(
        (line.strip() for line in summary.splitlines() if line.startswith("Total:")),
        None,
    )
    if total_line is None:
        raise SystemExit("coverage summary did not contain a Total line")
    counts = total_line.removeprefix("Total:").strip().split("/")
    if len(counts) != 2:
        raise SystemExit("coverage Total line has an invalid format")
    covered, total = (int(value) for value in counts)
    if total == 0:
        raise SystemExit("coverage summary reported zero executable lines")
    percentage = covered * 100.0 / total
    print(f"coverage: {covered}/{total} ({percentage:.2f}%), required >= {THRESHOLD:.2f}%")
    if not percentage >= THRESHOLD:
        raise SystemExit("coverage threshold failed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
