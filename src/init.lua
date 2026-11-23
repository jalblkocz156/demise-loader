--!strict
local VERSION = "1.0.0"
local ORG = "jalblkocz156"
local REPO = "demise-loader"

local BASE = ("https://github.com/%s/%s/releases/download/v%s/"):format(ORG, REPO, VERSION)

local function fetch(path: string): string
    local url = BASE .. path
    local ok, body = pcall(function()
        return game:HttpGetAsync(url)
    end)
    if not ok or #body < 32 then
        error(("[Demise] failed to fetch %s"):format(path), 2)
    end
    return body
end

local Loader = {}
Loader.Version = VERSION
Loader.Modules = {}

function Loader:Load(name: string)
    local chunk = fetch(name .. ".lua")
    local fn = assert(loadstring(chunk, "=demise:" .. name))
    return fn()
end

return Loader
