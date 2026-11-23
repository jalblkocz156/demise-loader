#!/usr/bin/env bash
set -e
mkdir -p dist
/tmp/darklua process src/init.lua dist/loader.lua --config .darklua.json
/tmp/darklua process src/registry.lua dist/registry.lua --config .darklua.json
for f in src/modules/*.lua; do
  /tmp/darklua process "$f" "dist/$(basename "$f")" --config .darklua.json
done
echo "built $(ls dist | wc -l) files"
