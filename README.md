# Demise Loader

Roblox script loader. Versioned releases, obfuscated distribution.

## Install

    loadstring(game:HttpGet("https://github.com/jalblkocz156/demise-loader/releases/download/v1.3.1/loader.lua"))()

## Adding a game

1. Add `src/modules/<name>.lua`
2. Add the PlaceId to `src/registry.lua`
3. Bump VERSION, update the install line above, tag and push

CI fails if the registry names a module that does not exist, or if VERSION
and the pushed tag disagree.

## Structure

- src/ - readable Luau source
- src/registry.lua - PlaceId to build map
- dist/ - build output, uploaded to releases
- docs/ - module API reference

## Releasing

1. Bump VERSION in src/init.lua
2. Update the install line above
3. Update CHANGELOG.md
4. git tag v1.3.1 && git push --tags

## Build

darklua minifies every file in the Bundle step. If it fails on a file the
build logs a warning and ships that file verbatim rather than breaking the
release.
