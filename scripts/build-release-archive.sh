#!/usr/bin/env bash
set -euo pipefail

usage() {
  printf 'Usage: %s <version>\n' "$(basename "$0")" >&2
}

if [[ $# -ne 1 ]]; then
  usage
  exit 64
fi

version="$1"
if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  printf 'error: version must use X.Y.Z format, got %s\n' "$version" >&2
  exit 64
fi

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

swift build \
  --configuration release \
  --product clipper \
  --arch arm64 \
  --arch x86_64

binary=".build/apple/Products/Release/clipper"
if [[ ! -x "$binary" ]]; then
  printf 'error: release binary not found at %s\n' "$binary" >&2
  exit 1
fi

expected_version="clipper ${version}"
actual_version="$("$binary" --version)"
if [[ "$actual_version" != "$expected_version" ]]; then
  printf 'error: version mismatch: expected "%s", got "%s"\n' "$expected_version" "$actual_version" >&2
  exit 1
fi

codesign --force --sign - "$binary"
codesign --verify --strict "$binary"

dist_dir="$repo_root/dist"
stage_dir="$repo_root/.build/release-artifacts/clipper-v${version}-macos-universal"
archive="$dist_dir/clipper-v${version}-macos-universal.tar.gz"
checksum="$archive.sha256"

rm -rf "$stage_dir"
mkdir -p "$stage_dir" "$dist_dir"
install -m 0755 "$binary" "$stage_dir/clipper"
install -m 0644 README.md "$stage_dir/README.md"

rm -f "$archive" "$checksum"
(
  cd "$stage_dir/.."
  COPYFILE_DISABLE=1 tar -czf "$archive" "$(basename "$stage_dir")"
)
shasum -a 256 "$archive" > "$checksum"

printf '%s\n' "$archive"
printf '%s\n' "$checksum"
