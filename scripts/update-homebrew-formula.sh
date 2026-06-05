#!/usr/bin/env bash
set -euo pipefail

usage() {
  printf 'Usage: %s <version> <sha256> <tap-root>\n' "$(basename "$0")" >&2
}

if [[ $# -ne 3 ]]; then
  usage
  exit 64
fi

version="$1"
sha256="$2"
tap_root="$3"

if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  printf 'error: version must use X.Y.Z format, got %s\n' "$version" >&2
  exit 64
fi

if [[ ! "$sha256" =~ ^[0-9a-f]{64}$ ]]; then
  printf 'error: sha256 must be 64 lowercase hex characters\n' >&2
  exit 64
fi

if [[ ! -d "$tap_root" ]]; then
  printf 'error: tap root does not exist: %s\n' "$tap_root" >&2
  exit 1
fi

formula_dir="$tap_root/Formula"
if [[ ! -d "$formula_dir" ]]; then
  printf 'error: tap Formula directory does not exist: %s\n' "$formula_dir" >&2
  exit 1
fi

tarball_url="${CLIPPER_TARBALL_URL:-https://github.com/h3nock/clipper/releases/download/v${version}/clipper-v${version}-macos-universal.tar.gz}"
formula="$formula_dir/clipper.rb"

cat > "$formula" <<RUBY
class Clipper < Formula
  desc "Keyboard-first macOS screenshots for developer workflows"
  homepage "https://github.com/h3nock/clipper"
  url "${tarball_url}"
  sha256 "${sha256}"

  depends_on "fzf"
  depends_on macos: :sonoma

  def install
    bin.install "clipper"
  end

  test do
    assert_match "clipper #{version}", shell_output("#{bin}/clipper --version")
  end
end
RUBY

ruby -c "$formula" >/dev/null

readme="$tap_root/README.md"
if [[ -f "$readme" ]]; then
  if grep -q '^- `clipper`:' "$readme"; then
    perl -0pi -e 's/^- `clipper`:.*$/- `clipper`: Keyboard-first macOS screenshots for developer workflows./m' "$readme"
  else
    perl -0pi -e 's/(## Formulae\n\n)/$1- `clipper`: Keyboard-first macOS screenshots for developer workflows.\n/' "$readme"
  fi
fi

printf '%s\n' "$formula"
