--!strict
local Http = {}

function Http.Get(url: string, retries: number?): string
	local attempts = retries or 3
	for i = 1, attempts do
		local ok, res = pcall(function()
			return game:HttpGetAsync(url)
		end)
		if ok and res and #res > 0 then
			return res
		end
		task.wait(i * 0.5)
	end
	error(("[Demise] GET failed: %s"):format(url), 2)
end

return Http
