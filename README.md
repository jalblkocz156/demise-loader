# Demise Loader

Roblox script loader. Versioned releases, obfuscated distribution.

## Install

    loadstring(game:HttpGet("https://github.com/jalblkocz156/demise-loader/releases/download/v1.0.0/loader.lua"))()

## Structure

- src/ - readable Luau source
- dist/ - build output, uploaded to releases
- docs/ - module API reference

## Releasing

1. Bump VERSION in src/init.lua
2. Update CHANGELOG.md
3. git tag v1.0.1 && git push --tags
4. CI builds and publishes the release
