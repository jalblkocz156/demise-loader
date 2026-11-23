--!nonstrict
local VERSION = "1.3.2"
local ORG = "jalblkocz156"
local REPO = "demise-loader"

local BASE = getgenv().DemiseBase or ("https://github.com/%s/%s/releases/download/v%s/"):format(ORG, REPO, VERSION)

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local loadstring = loadstring or load
assert(loadstring, "no loadstring")

local BG = Color3.fromRGB(17, 17, 21)
local SURFACE = Color3.fromRGB(27, 27, 33)
local ROW = Color3.fromRGB(33, 33, 40)
local ROW_ON = Color3.fromRGB(48, 42, 78)
local ACCENT = Color3.fromRGB(126, 96, 255)
local TEXT = Color3.fromRGB(234, 234, 240)
local MUTED = Color3.fromRGB(128, 128, 143)
local GOOD = Color3.fromRGB(96, 210, 140)
local BAD = Color3.fromRGB(230, 100, 100)

local function fetch(path: string): string
	local ok, body = pcall(function()
		return game:HttpGet(BASE .. path)
	end)
	if not ok or type(body) ~= "string" or #body < 16 then
		error(("[Demise] could not fetch %s"):format(path), 2)
	end
	return body
end

local REGISTRY_ERR = "none"
-- Registry lives in the release as registry.lua so adding a game is a data edit,
-- not a loader bump. A failure here degrades to an empty list, never a hard error.
local function loadRegistry()
	local ok, body = pcall(function()
		return game:HttpGet(BASE .. "registry.lua")
	end)
	if not ok or type(body) ~= "string" or #body < 8 then
		REGISTRY_ERR = "fetch"
		return nil
	end
	local fn, cerr = loadstring(body, "=demise:registry")
	if not fn then
		REGISTRY_ERR = tostring(cerr)
		return nil
	end
	local ran, result = pcall(fn)
	if not ran or type(result) ~= "table" then
		return nil
	end
	local clean = {}
	for id, entry in result do
		if type(id) == "number" and type(entry) == "table"
			and type(entry.name) == "string" and type(entry.module) == "string" then
			clean[id] = { name = entry.name, module = entry.module }
		end
	end
	return clean
end

local cache = {}
local running = false

local Loader = {}
Loader.Version = VERSION
Loader.Modules = {}

function Loader:Load(name: string)
	local chunk = cache[name]
	if not chunk then
		chunk = fetch(name .. ".lua")
		cache[name] = chunk
	end
	local fn, cerr = loadstring(chunk, "=demise:" .. name)
	if not fn then error(("%s failed to compile: %s"):format(name, tostring(cerr)), 2) end
	return fn()
end

local function new(class: string, props, kids)
	local inst = Instance.new(class)
	if props then
		for k, v in props do
			if k ~= "Parent" then
				inst[k] = v
			end
		end
	end
	if kids then
		for _, kid in kids do
			kid.Parent = inst
		end
	end
	if props and props.Parent then
		inst.Parent = props.Parent
	end
	return inst
end

local function corner(r: number, parent: Instance)
	return new("UICorner", { CornerRadius = UDim.new(0, r), Parent = parent })
end

local REGISTRY = loadRegistry()

local host = (function()
	local ok, hui = pcall(function()
		return gethui()
	end)
	if ok and typeof(hui) == "Instance" then
		return hui
	end
	return LocalPlayer:WaitForChild("PlayerGui")
end)()

for _, box in { host, LocalPlayer:WaitForChild("PlayerGui") } do
	local prev = box:FindFirstChild("DemiseLoaderUI")
	if prev then
		prev:Destroy()
	end
end

local gui = new("ScreenGui", {
	Parent = host,
	Name = "DemiseLoaderUI",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	DisplayOrder = 9999,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})

local win = new("Frame", {
	Parent = gui,
	Size = UDim2.fromOffset(360, 470),
	Position = UDim2.new(0.5, -180, 0.5, -235),
	BackgroundColor3 = BG,
	BorderSizePixel = 0,
})
corner(12, win)
new("UIStroke", { Parent = win, Color = Color3.fromRGB(44, 44, 54), Thickness = 1 })

local head = new("Frame", {
	Parent = win,
	Size = UDim2.new(1, 0, 0, 46),
	BackgroundColor3 = SURFACE,
	BorderSizePixel = 0,
})
corner(12, head)
new("TextLabel", {
	Parent = head,
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(16, 0),
	Size = UDim2.new(1, -60, 1, 0),
	Font = Enum.Font.GothamBold,
	Text = "DEMISE",
	TextSize = 15,
	TextColor3 = TEXT,
	TextXAlignment = Enum.TextXAlignment.Left,
})
new("TextLabel", {
	Parent = head,
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(16, 0),
	Size = UDim2.new(1, -60, 1, 0),
	Font = Enum.Font.Gotham,
	Text = "v" .. VERSION,
	TextSize = 12,
	TextColor3 = MUTED,
	TextXAlignment = Enum.TextXAlignment.Right,
})

local close = new("TextButton", {
	Parent = head,
	Position = UDim2.new(1, -38, 0, 12),
	Size = UDim2.fromOffset(26, 22),
	BackgroundColor3 = ROW,
	BorderSizePixel = 0,
	Font = Enum.Font.GothamBold,
	Text = "x",
	TextSize = 15,
	TextColor3 = MUTED,
	AutoButtonColor = false,
})
corner(6, close)
close.MouseButton1Click:Connect(function()
	gui:Destroy()
end)

local drag, dragFrom, origin
head.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		drag = true
		dragFrom = input.Position
		origin = win.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				drag = false
			end
		end)
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if drag and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local d = input.Position - dragFrom
		win.Position = UDim2.new(origin.X.Scale, origin.X.Offset + d.X, origin.Y.Scale, origin.Y.Offset + d.Y)
	end
end)

local status = new("TextLabel", {
	Parent = win,
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(16, 56),
	Size = UDim2.new(1, -32, 0, 18),
	Font = Enum.Font.Gotham,
	Text = "",
	TextSize = 12,
	TextColor3 = MUTED,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top,
})

local auto = true
local toggleRow = new("TextButton", {
	Parent = win,
	Position = UDim2.fromOffset(16, 80),
	Size = UDim2.new(1, -32, 0, 34),
	BackgroundColor3 = ROW,
	BorderSizePixel = 0,
	Text = "",
	AutoButtonColor = false,
})
corner(8, toggleRow)
new("TextLabel", {
	Parent = toggleRow,
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(10, 0),
	Size = UDim2.new(1, -60, 1, 0),
	Font = Enum.Font.GothamMedium,
	Text = "Auto-detect my game",
	TextSize = 13,
	TextColor3 = TEXT,
	TextXAlignment = Enum.TextXAlignment.Left,
})

local track = new("Frame", {
	Parent = toggleRow,
	Position = UDim2.new(1, -46, 0.5, -9),
	Size = UDim2.fromOffset(34, 18),
	BackgroundColor3 = ACCENT,
	BorderSizePixel = 0,
})
corner(9, track)
local knob = new("Frame", {
	Parent = track,
	Position = UDim2.fromOffset(16, 2),
	Size = UDim2.fromOffset(14, 14),
	BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	BorderSizePixel = 0,
})
corner(7, knob)

local function paintToggle(on: boolean)
	auto = on
	track.BackgroundColor3 = on and ACCENT or Color3.fromRGB(60, 60, 70)
	TweenService:Create(knob, TweenInfo.new(0.14), { Position = UDim2.fromOffset(on and 16 or 2, 2) }):Play()
end

new("TextLabel", {
	Parent = win,
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(16, 124),
	Size = UDim2.new(1, -32, 0, 16),
	Font = Enum.Font.GothamBold,
	Text = "BUILDS",
	TextSize = 10,
	TextColor3 = MUTED,
	TextXAlignment = Enum.TextXAlignment.Left,
})

local list = new("ScrollingFrame", {
	Parent = win,
	Position = UDim2.fromOffset(12, 144),
	Size = UDim2.new(1, -24, 1, -206),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 3,
	ScrollBarImageColor3 = Color3.fromRGB(70, 70, 84),
	CanvasSize = UDim2.new(),
})
local layout = new("UIListLayout", {
	Parent = list,
	Padding = UDim.new(0, 6),
	SortOrder = Enum.SortOrder.LayoutOrder,
})
layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	list.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y + 8)
end)

local exec = new("TextButton", {
	Parent = win,
	Position = UDim2.new(0, 16, 1, -52),
	Size = UDim2.new(1, -32, 0, 36),
	BackgroundColor3 = Color3.fromRGB(50, 50, 62),
	BorderSizePixel = 0,
	Font = Enum.Font.GothamBold,
	Text = "Execute",
	TextSize = 13,
	TextColor3 = Color3.fromRGB(255, 255, 255),
	AutoButtonColor = false,
})
corner(8, exec)

local here = REGISTRY and (REGISTRY[game.PlaceId] or REGISTRY[game.GameId])
local selected
local rows = {}

local function select(mod: string?)
	selected = mod
	for m, row in rows do
		row.BackgroundColor3 = (m == mod) and ROW_ON or ROW
	end
	exec.BackgroundColor3 = mod and ACCENT or Color3.fromRGB(50, 50, 62)
end

local function run(mod: string?)
	if not mod or running then
		return
	end
	running = true
	exec.Text = "Running..."
	task.spawn(function()
		local ok, err = pcall(Loader.Load, Loader, mod)
		running = false
		exec.Text = "Execute"
		if ok then
			status.Text = ("%s loaded"):format(mod)
			status.TextColor3 = GOOD
		else
			status.Text = tostring(err)
			warn(err)
			warn(err)
			status.TextColor3 = BAD
		end
	end)
end

local sorted = {}
for _, entry in REGISTRY or {} do
	sorted[#sorted + 1] = entry
end
table.sort(sorted, function(a, b)
	return a.name < b.name
end)

for i, entry in sorted do
	local isHere = here and entry.module == here.module
	local row = new("TextButton", {
		Parent = list,
		LayoutOrder = i,
		Size = UDim2.new(1, -8, 0, 40),
		BackgroundColor3 = ROW,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
	})
	corner(8, row)
	new("TextLabel", {
		Parent = row,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(1, -70, 1, 0),
		Font = Enum.Font.GothamMedium,
		Text = entry.name,
		TextSize = 13,
		TextColor3 = TEXT,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	new("TextLabel", {
		Parent = row,
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -62, 0, 0),
		Size = UDim2.fromOffset(50, 40),
		Font = Enum.Font.Gotham,
		Text = isHere and "here" or entry.module,
		TextSize = 11,
		TextColor3 = isHere and GOOD or MUTED,
		TextXAlignment = Enum.TextXAlignment.Right,
	})
	row.MouseButton1Click:Connect(function()
		select(entry.module)
	end)
	rows[entry.module] = row
end

exec.MouseButton1Click:Connect(function()
	run(selected)
end)

if not REGISTRY then
	status.Text = "Registry unavailable: " .. REGISTRY_ERR
	status.TextColor3 = BAD
elseif here then
	status.Text = ("Detected %s"):format(here.name)
	status.TextColor3 = GOOD
	select(here.module)
else
	status.Text = ("No build for place %d"):format(game.PlaceId)
	status.TextColor3 = MUTED
end

toggleRow.MouseButton1Click:Connect(function()
	paintToggle(not auto)
	if auto and here then
		select(here.module)
		run(here.module)
	end
end)

if here then
	task.delay(0.4, function()
		if auto and selected == here.module then
			run(here.module)
		end
	end)
end

return Loader
