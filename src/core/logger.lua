--!strict
local Logger = {}
local PREFIX = "[Demise]"

function Logger.info(...)
	print(PREFIX, ...)
end

function Logger.warn(...)
	warn(PREFIX, ...)
end

function Logger.error(...)
	warn(PREFIX, "ERROR:", ...)
end

return Logger
