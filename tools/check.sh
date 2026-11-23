#!/usr/bin/env bash
set -e
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
for f in src/init.lua src/registry.lua src/modules/*.lua; do
  darklua process "$f" "$tmp" --config .darklua-parse.json >/dev/null \
    || { echo "FAIL parse: $f"; exit 1; }
done
stylua --check src >/dev/null || { echo "FAIL format: run stylua src"; exit 1; }
selene src || { echo "FAIL lint"; exit 1; }
grep -q "/v$(sed -n 's/^local VERSION = "\(.*\)"$/\1/p' src/init.lua)/" README.md || { echo "FAIL version/README"; exit 1; }
for m in $(sed -n 's/.*module = "\([A-Za-z0-9_]*\)".*/\1/p' src/registry.lua); do
  [ -f "src/modules/$m.lua" ] || { echo "FAIL missing module $m"; exit 1; }
done
echo OK
