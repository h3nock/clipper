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

if "$clipper" window --source nope 2>/dev/null; then
  echo "unsupported window source should fail" >&2
  exit 1
fi

"$root/libexec/clipper-system-windows" | jq -e 'type == "array"' >/dev/null

if command -v yabai >/dev/null 2>&1 && command -v jq >/dev/null 2>&1 && command -v fzf >/dev/null 2>&1; then
  if yabai -m query --windows 2>/dev/null | jq -e 'length > 0' >/dev/null; then
    if "$clipper" window --source yabai --json >/tmp/clipper-smoke-window.json 2>/dev/null; then
      echo "non-interactive window picker should fail" >&2
      rm -f /tmp/clipper-smoke-window.json
      exit 1
    fi
    grep -q 'Window picker requires an interactive terminal' /tmp/clipper-smoke-window.json
    rm -f /tmp/clipper-smoke-window.json
  fi
fi

if "$clipper" window --source system --json >/tmp/clipper-smoke-system-window.json 2>/dev/null; then
  echo "non-interactive system window picker should fail" >&2
  rm -f /tmp/clipper-smoke-system-window.json
  exit 1
fi
grep -q 'Window picker requires an interactive terminal' /tmp/clipper-smoke-system-window.json
rm -f /tmp/clipper-smoke-system-window.json

echo "smoke tests passed"
