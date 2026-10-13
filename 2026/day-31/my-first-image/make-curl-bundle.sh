#!/bin/bash
# Copy the host's curl + every shared library it needs into ./curl-bundle (same paths),
# so a Dockerfile can "install curl" with a single COPY when apt is unreachable.
set -euo pipefail
cd "$(dirname "$0")"
OUT=curl-bundle
rm -rf "$OUT" && mkdir -p "$OUT/bin"
src=$(type -P curl)
cp -L "$src" "$OUT/bin/curl"
for lib in $(ldd "$src" | grep -oE '/[^ ]+'); do
  mkdir -p "$OUT$(dirname "$lib")"
  cp -Ln "$lib" "$OUT$lib" 2>/dev/null || true
done
du -sh "$OUT"
