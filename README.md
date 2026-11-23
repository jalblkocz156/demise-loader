# Demise Loader

Private Roblox script loader. Versioned releases, obfuscated distribution, private source.

## Install

    loadstring(game:HttpGet("https://cdn.jsdelivr.net/gh/jalblkocz156/demise-loader@v1.0.0/dist/loader.lua"))()

## Structure

- src/ - readable Luau source (private)
- dist/ - obfuscated build, attached to releases
- docs/ - module API reference

## Releasing

1. Bump VERSION in src/init.lua
2. Update CHANGELOG.md
3. git tag v1.0.1 && git push --tags
4. CI builds, obfuscates, and publishes the release
