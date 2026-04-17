#!/usr/bin/env bash

set -euo pipefail

swift test -c release
ASTROCORE_ENABLE_SWISS_VERIFICATION=1 swift test -c release --filter SwissHouseVerificationTests

if command -v swiftformat >/dev/null 2>&1; then
  swiftformat . --config .swiftformat --lint
else
  echo "swiftformat not found; skipping format lint" >&2
fi

if command -v swiftlint >/dev/null 2>&1; then
  swiftlint lint . --config .swiftlint.yml --strict --force-exclude
else
  echo "swiftlint not found; skipping SwiftLint" >&2
fi
