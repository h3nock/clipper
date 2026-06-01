#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
clipper="$root/bin/clipper"

"$clipper" --help >/dev/null
"$clipper" --version | grep -q '^clipper '

if "$clipper" nope 2>/dev/null; then
  echo "unknown command should fail" >&2
  exit 1
fi

if "$clipper" front --output 2>/dev/null; then
  echo "missing --output value should fail" >&2
  exit 1
fi

echo "smoke tests passed"
