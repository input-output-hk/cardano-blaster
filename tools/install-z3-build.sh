#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
platform="$(uname -s)-$(uname -m)"
read -r url sha256 < <(python3 - "$platform" <<'PYTHON'
import json
import sys

with open("runtime-lock.json", encoding="utf-8") as lock:
    assets = json.load(lock)["z3"]["assets"]
asset = assets.get(sys.argv[1])
if asset is None:
    sys.exit(f"No locked Z3 build for {sys.argv[1]}")
print(asset["url"], asset["sha256"])
PYTHON
)

staging="$(mktemp -d)"
trap 'rm -rf -- "$staging"' EXIT
archive="$staging/z3.zip"
curl -fLsS --connect-timeout 15 --max-time 120 -o "$archive" "$url"
printf '%s  %s\n' "$sha256" "$archive" | shasum -a 256 -c -
unzip -q "$archive" '*/include/*' '*/bin/libz3.a' '*/bin/z3' -d "$staging"

release="$staging/$(basename "$url" .zip)"
z3_root="$PWD/.lake/z3"
mkdir -p "$z3_root/include" "$z3_root/bin"
cp -R "$release/include/." "$z3_root/include/"
install -m 644 "$release/bin/libz3.a" "$z3_root/bin/libz3.a"
install -m 755 "$release/bin/z3" "$z3_root/bin/z3"
