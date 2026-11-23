# Demise Loader

Private Roblox script loader. Versioned releases, obfuscated distribution, private source.

## Install

```lua
loadstring(game:HttpGet("https://cdn.jsdelivr.net/gh/jalblkoc2156/demise-loader@v1.0.0/dist/loader.lua"))()

cat > README.md << 'EOF'
# Demise Loader

Private Roblox script loader. Versioned releases, obfuscated distribution, private source.

## Install

```lua
loadstring(game:HttpGet("https://cdn.jsdelivr.net/gh/jalblkoc2156/demise-loader@v1.0.0/dist/loader.lua"))()
cat > README.md << 'EOF'
# Demise Loader

Private Roblox script loader. Versioned releases, obfuscated distribution, private source.

## Install

```lua
loadstring(game:HttpGet("https://cdn.jsdelivr.net/gh/jalblkoc2156/demise-loader@v1.0.0/dist/loader.lua"))()
**16 — .github/workflows/release.yml**
```bash
cat > .github/workflows/release.yml << 'EOF'
name: release
on:
  push:
    tags: ["v*"]

jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: write
    steps:
      - uses: actions/checkout@v4
      - name: Bundle
        run: |
          mkdir -p dist
          cat src/init.lua > dist/loader.lua
          for f in src/modules/*.lua; do
            echo "-- module: $(basename "$f")" >> dist/loader.lua
            cat "$f" >> dist/loader.lua
          done
      - name: Minify
        run: |
          npx --yes luamin -f dist/loader.lua > dist/loader.min.lua
          mv dist/loader.min.lua dist/loader.lua
      - name: Publish
        uses: softprops/action-gh-release@v2
        with:
          files: dist/loader.lua
