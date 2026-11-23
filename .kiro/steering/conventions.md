# demise-loader conventions

- Luau, tabs, 100 columns, double quotes. Format with StyLua on save.
- src/ is the only thing edited. dist/ is generated, never edit it, never commit it.
- Adding a game: new file in src/modules/, new PlaceId row in src/registry.lua.
- Any edit to src/init.lua requires a VERSION bump and the matching README install line.
- Never tag before `bash tools/check.sh` is clean.
- Module files must parse standalone; CI fails otherwise.
