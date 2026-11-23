--[[
    ╔══════════════════════════════════════════════════════════════════════╗
    ║                         DEMISE CLIENT v2.0                           ║
    ║                    Ultimate All-In-One Edition                       ║
    ╚══════════════════════════════════════════════════════════════════════╝

    Paste this entire script into your executor (Xeno, Solara, Wave, etc.)
    Press RIGHT SHIFT to toggle GUI | Press K for KillAura | Press X for Fly
]]

-- Prevent multiple instances running at once
if getgenv and getgenv().DemiseLoaded then
    if getgenv().DemiseUnload then
        pcall(getgenv().DemiseUnload)
    end
end
if getgenv then
    getgenv().DemiseLoaded = true
end

-- Core Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")
local SoundService = game:GetService("SoundService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Shared health resolver: Humanoid first, then Player props, attributes, child values.
-- Global on purpose - TargetHUD and Visuals both call it from outside Combat.
function GetHealth(player, humanoid)
    if humanoid and humanoid.Health and humanoid.MaxHealth then
        return humanoid.Health, humanoid.MaxHealth
    end
    if player then
        local success, health = pcall(function() return player.Health end)
        local success2, maxHealth = pcall(function() return player.MaxHealth end)
        if success and success2 and health and maxHealth then
            return health, maxHealth
        end
        local healthAttr = player:GetAttribute("Health")
        local maxHealthAttr = player:GetAttribute("MaxHealth")
        if healthAttr and maxHealthAttr then
            return healthAttr, maxHealthAttr
        end
        local healthValue = player:FindFirstChild("Health")
        local maxHealthValue = player:FindFirstChild("MaxHealth")
        if healthValue and maxHealthValue then
            if healthValue:IsA("NumberValue") or healthValue:IsA("IntValue") then
                return healthValue.Value, maxHealthValue.Value
            end
        end
    end
    return nil, nil
end

-- Global cleanup registry
local Cleanups = {
    Connections = {},
    Instances = {}
}

local function RegisterConnection(conn)
    table.insert(Cleanups.Connections, conn)
    return conn
end

local function RegisterInstance(inst)
    table.insert(Cleanups.Instances, inst)
    return inst
end

-- Color Palettes & Active Theme
local Themes = {
    ["Rise Green"] = Color3.fromRGB(80, 200, 120),
    ["Demise Purple"] = Color3.fromRGB(155, 89, 235),
    ["Cyber Cyan"] = Color3.fromRGB(0, 220, 255),
    ["Crimson Red"] = Color3.fromRGB(240, 60, 90)
}
local ActiveThemeName = "Demise Purple"
local AccentColor = Themes[ActiveThemeName]
echo
cat >> src/modules/unstablesmp.lua << 'LUAEOF'

-- ============================================================================
-- 1. NOTIFICATION SYSTEM
-- ============================================================================
local NotificationSystem = (function()
    local System = {}
    local ScreenGui = nil
    local Container = nil

    function System.Init()
        local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
        ScreenGui = Instance.new("ScreenGui")
        ScreenGui.Name = "DemiseNotifications"
        ScreenGui.ResetOnSpawn = false
        ScreenGui.IgnoreGuiInset = true
        ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        ScreenGui.DisplayOrder = 1000002
        ScreenGui.Parent = PlayerGui
        RegisterInstance(ScreenGui)

        Container = Instance.new("Frame")
        Container.Name = "NotificationContainer"
        Container.Size = UDim2.new(0, 260, 1, -20)
        Container.Position = UDim2.new(1, -270, 0, 10)
        Container.BackgroundTransparency = 1
        Container.Parent = ScreenGui

        local layout = Instance.new("UIListLayout")
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
        layout.Padding = UDim.new(0, 8)
        layout.Parent = Container
    end

    function System.Notify(title, text, duration, customColor)
        if not ScreenGui or not ScreenGui.Parent then
            System.Init()
        end

        duration = duration or 2.5
        local themeColor = customColor or AccentColor

        local Toast = Instance.new("Frame")
        Toast.Name = "Toast"
        Toast.Size = UDim2.new(1, 0, 0, 52)
        Toast.Position = UDim2.new(1, 50, 0, 0)
        Toast.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
        Toast.BorderSizePixel = 0
        Toast.ClipsDescendants = true
        Toast.Parent = Container

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = Toast

        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(0, 4, 1, 0)
        bar.BackgroundColor3 = themeColor
        bar.BorderSizePixel = 0
        bar.Parent = Toast

        local titleLabel = Instance.new("TextLabel")
        titleLabel.Size = UDim2.new(1, -20, 0, 18)
        titleLabel.Position = UDim2.new(0, 14, 0, 7)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Text = title
        titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        titleLabel.TextSize = 13
        titleLabel.Font = Enum.Font.GothamBold
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.Parent = Toast

        local textLabel = Instance.new("TextLabel")
        textLabel.Size = UDim2.new(1, -20, 0, 18)
        textLabel.Position = UDim2.new(0, 14, 0, 26)
        textLabel.BackgroundTransparency = 1
        textLabel.Text = text
        textLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
        textLabel.TextSize = 12
        textLabel.Font = Enum.Font.Gotham
        textLabel.TextXAlignment = Enum.TextXAlignment.Left
        textLabel.Parent = Toast

        -- Slide in
        TweenService:Create(Toast, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, 0, 0, 0)
        }):Play()

        -- Slide out & Destroy
        task.delay(duration, function()
            if Toast and Toast.Parent then
                local tween = TweenService:Create(Toast, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
                    Position = UDim2.new(1, 280, 0, 0)
                })
                tween:Play()
                tween.Completed:Connect(function()
                    Toast:Destroy()
                end)
            end
        end)
    end

    System.Init()
    return System
end)()
echo
cat >> src/modules/unstablesmp.lua << 'LUAEOF'

-- ============================================================================
-- 2. LOADING SCREEN UI MODULE
-- ============================================================================
local LoaderUI = (function()
    local Module = {}

    function Module.Create()
        local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

        local ScreenGui = Instance.new("ScreenGui")
        ScreenGui.Name = "DemiseLoader"
        ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        ScreenGui.ResetOnSpawn = false
        ScreenGui.IgnoreGuiInset = true
        ScreenGui.IgnoreGuiInset = true
        ScreenGui.DisplayOrder = 999999
        RegisterInstance(ScreenGui)

        local Background = Instance.new("Frame")
        Background.Name = "Background"
        Background.Size = UDim2.new(1, 0, 1, 0)
        Background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        Background.BorderSizePixel = 0
        Background.Parent = ScreenGui

        local Title = Instance.new("TextLabel")
        Title.Name = "Title"
        Title.Size = UDim2.new(0, 400, 0, 80)
        Title.Position = UDim2.new(0.5, -200, 0.38, 0)
        Title.BackgroundTransparency = 1
        Title.Text = "demise"
        Title.TextColor3 = Color3.fromRGB(255, 255, 255)
        Title.TextSize = 72
        Title.Font = Enum.Font.GothamBold
        Title.Parent = Background

        local BarBackground = Instance.new("Frame")
        BarBackground.Name = "BarBackground"
        BarBackground.Size = UDim2.new(0, 420, 0, 4)
        BarBackground.Position = UDim2.new(0.5, -210, 0.62, 0)
        BarBackground.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
        BarBackground.BorderSizePixel = 0
        BarBackground.Parent = Background

        local BarCorner = Instance.new("UICorner")
        BarCorner.CornerRadius = UDim.new(0, 2)
        BarCorner.Parent = BarBackground

        local LoadingBar = Instance.new("Frame")
        LoadingBar.Name = "LoadingBar"
        LoadingBar.Size = UDim2.new(0, 0, 1, 0)
        LoadingBar.BackgroundColor3 = AccentColor
        LoadingBar.BorderSizePixel = 0
        LoadingBar.Parent = BarBackground

        local BarCorner2 = Instance.new("UICorner")
        BarCorner2.CornerRadius = UDim.new(0, 2)
        BarCorner2.Parent = LoadingBar

        local LoadingText = Instance.new("TextLabel")
        LoadingText.Name = "LoadingText"
        LoadingText.Size = UDim2.new(0, 420, 0, 26)
        LoadingText.Position = UDim2.new(0.5, -210, 0.65, 0)
        LoadingText.BackgroundTransparency = 1
        LoadingText.Text = "Initializing... 0%"
        LoadingText.TextColor3 = Color3.fromRGB(190, 190, 195)
        LoadingText.TextSize = 15
        LoadingText.Font = Enum.Font.Gotham
        LoadingText.Parent = Background

        local VersionText = Instance.new("TextLabel")
        VersionText.Name = "VersionText"
        VersionText.Size = UDim2.new(0, 200, 0, 20)
        VersionText.Position = UDim2.new(0.5, -100, 0.92, 0)
        VersionText.BackgroundTransparency = 1
        VersionText.Text = "v2.0.0 All-In-One"
        VersionText.TextColor3 = Color3.fromRGB(110, 110, 115)
        VersionText.TextSize = 13
        VersionText.Font = Enum.Font.Gotham
        VersionText.Parent = Background

        ScreenGui.Parent = PlayerGui

        return {
            ScreenGui = ScreenGui,
            Background = Background,
            LoadingBar = LoadingBar,
            LoadingText = LoadingText,
            Title = Title,
            VersionText = VersionText
        }
    end

    function Module.PlayCompletionSound()
        pcall(function()
            local sound = Instance.new("Sound")
            sound.SoundId = "rbxassetid://3398620867"
            sound.Volume = 0.65
            sound.PlaybackSpeed = 0.95
            sound.Parent = SoundService

            local reverb = Instance.new("ReverbSoundEffect")
            reverb.DecayTime = 2.5
            reverb.Density = 0.8
            reverb.Diffusion = 0.85
            reverb.DryLevel = -6
            reverb.WetLevel = -3
            reverb.Parent = sound

            local echo = Instance.new("EchoSoundEffect")
            echo.Delay = 0.3
            echo.DryLevel = 0
            echo.WetLevel = 0.5
            echo.Feedback = 0.4
            echo.Parent = sound

            sound:Play()
            game:GetService("Debris"):AddItem(sound, 5)
        end)
    end

    function Module.FadeOut(elements, callback)
        local tweenInfo = TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
        local fadeTween = TweenService:Create(elements.Background, tweenInfo, { BackgroundTransparency = 1 })
        local titleTween = TweenService:Create(elements.Title, tweenInfo, { TextTransparency = 1 })
        local textTween = TweenService:Create(elements.LoadingText, tweenInfo, { TextTransparency = 1 })
        local verTween = TweenService:Create(elements.VersionText, tweenInfo, { TextTransparency = 1 })

        fadeTween:Play()
        titleTween:Play()
        textTween:Play()
        verTween:Play()

        fadeTween.Completed:Connect(function()
            pcall(function() elements.ScreenGui:Destroy() end)
            if callback then callback() end
        end)
    end

    function Module.Show(duration, onComplete)
        local elements = Module.Create()
        duration = duration or 2.5
        local startTime = tick()
        local loadingMessages = {
            "Initializing environment...",
            "Compiling combat framework...",
            "Hooking movement & flight physics...",
            "Loading visuals & ESP chams...",
            "Finalizing Demise Client..."
        }

        local connection
        connection = RunService.Heartbeat:Connect(function()
            local elapsed = tick() - startTime
            local progress = math.min(elapsed / duration, 1)
            local percentage = math.floor(progress * 100)

            elements.LoadingBar.Size = UDim2.new(progress, 0, 1, 0)
            local msgIdx = math.min(math.floor(progress * #loadingMessages) + 1, #loadingMessages)
            elements.LoadingText.Text = loadingMessages[msgIdx] .. " " .. percentage .. "%"

            if progress >= 1 then
                connection:Disconnect()
                Module.PlayCompletionSound()
                task.wait(0.3)
                Module.FadeOut(elements, onComplete)
            end
        end)
    end

    return Module
end)()
echo
cat >> src/modules/unstablesmp.lua << 'LUAEOF'

-- ============================================================================
-- 3. TARGET HUD MODULE
-- ============================================================================
local TargetHUD = (function()
    local HUD = {
        Visible = false,
        ScreenGui = nil,
        Target = nil
    }

    local MainCard = nil
    local NameLabel = nil
    local HealthLabel = nil
    local DistLabel = nil
    local HealthBar = nil
    local AvatarImg = nil

    function HUD.Create()
        local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
        local ScreenGui = Instance.new("ScreenGui")
        ScreenGui.Name = "DemiseTargetHUD"
        ScreenGui.ResetOnSpawn = false
        ScreenGui.IgnoreGuiInset = true
        ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        ScreenGui.DisplayOrder = 1000001
        RegisterInstance(ScreenGui)

        MainCard = Instance.new("Frame")
        MainCard.Name = "Card"
        MainCard.Size = UDim2.new(0, 240, 0, 75)
        MainCard.Position = UDim2.new(0.5, -120, 0.72, 0)
        MainCard.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
        MainCard.BorderSizePixel = 0
        MainCard.Visible = false
        MainCard.Parent = ScreenGui

        local cardCorner = Instance.new("UICorner")
        cardCorner.CornerRadius = UDim.new(0, 8)
        cardCorner.Parent = MainCard

        local cardStroke = Instance.new("UIStroke")
        cardStroke.Color = Color3.fromRGB(45, 45, 55)
        cardStroke.Thickness = 1.2
        cardStroke.Parent = MainCard

        -- Avatar thumbnail
        AvatarImg = Instance.new("ImageLabel")
        AvatarImg.Name = "Avatar"
        AvatarImg.Size = UDim2.new(0, 50, 0, 50)
        AvatarImg.Position = UDim2.new(0, 12, 0, 12)
        AvatarImg.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
        AvatarImg.BorderSizePixel = 0
        AvatarImg.Parent = MainCard

        local avCorner = Instance.new("UICorner")
        avCorner.CornerRadius = UDim.new(0, 6)
        avCorner.Parent = AvatarImg

        NameLabel = Instance.new("TextLabel")
        NameLabel.Name = "TargetName"
        NameLabel.Size = UDim2.new(0, 160, 0, 18)
        NameLabel.Position = UDim2.new(0, 70, 0, 10)
        NameLabel.BackgroundTransparency = 1
        NameLabel.Text = "Target"
        NameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        NameLabel.TextSize = 14
        NameLabel.Font = Enum.Font.GothamBold
        NameLabel.TextXAlignment = Enum.TextXAlignment.Left
        NameLabel.TextTruncate = Enum.TextTruncate.AtEnd
        NameLabel.Parent = MainCard

        DistLabel = Instance.new("TextLabel")
        DistLabel.Name = "Dist"
        DistLabel.Size = UDim2.new(0, 160, 0, 14)
        DistLabel.Position = UDim2.new(0, 70, 0, 28)
        DistLabel.BackgroundTransparency = 1
        DistLabel.Text = "12 studs"
        DistLabel.TextColor3 = Color3.fromRGB(160, 160, 170)
        DistLabel.TextSize = 11
        DistLabel.Font = Enum.Font.Gotham
        DistLabel.TextXAlignment = Enum.TextXAlignment.Left
        DistLabel.Parent = MainCard

        local barBg = Instance.new("Frame")
        barBg.Name = "HealthBarBg"
        barBg.Size = UDim2.new(0, 155, 0, 8)
        barBg.Position = UDim2.new(0, 70, 0, 48)
        barBg.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
        barBg.BorderSizePixel = 0
        barBg.Parent = MainCard

        local bgCorner = Instance.new("UICorner")
        bgCorner.CornerRadius = UDim.new(1, 0)
        bgCorner.Parent = barBg

        HealthBar = Instance.new("Frame")
        HealthBar.Name = "Fill"
        HealthBar.Size = UDim2.new(1, 0, 1, 0)
        HealthBar.BackgroundColor3 = AccentColor
        HealthBar.BorderSizePixel = 0
        HealthBar.Parent = barBg

        local fillCorner = Instance.new("UICorner")
        fillCorner.CornerRadius = UDim.new(1, 0)
        fillCorner.Parent = HealthBar

        HealthLabel = Instance.new("TextLabel")
        HealthLabel.Name = "HPText"
        HealthLabel.Size = UDim2.new(0, 50, 0, 14)
        HealthLabel.Position = UDim2.new(1, -55, 0, 28)
        HealthLabel.BackgroundTransparency = 1
        HealthLabel.Text = "100 HP"
        HealthLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        HealthLabel.TextSize = 11
        HealthLabel.Font = Enum.Font.GothamBold
        HealthLabel.TextXAlignment = Enum.TextXAlignment.Right
        HealthLabel.Parent = MainCard

        ScreenGui.Parent = PlayerGui
        HUD.ScreenGui = ScreenGui
    end

    function HUD.Update(targetData)
        if not MainCard then return end

        if not targetData then
            if MainCard.Visible then
                MainCard.Visible = false
            end
            HUD.Target = nil
            return
        end

        local player = targetData.Player
        local humanoid = targetData.Humanoid
        local isDummy = targetData.IsDummy

        if not MainCard.Visible then
            MainCard.Visible = true
        end

        if HUD.Target ~= player then
            HUD.Target = player
            -- Add type indicator: (Player) or (Dummy)
            local typeIndicator = isDummy and " (Dummy)" or " (Player)"
            NameLabel.Text = (targetData.DisplayName or "Unknown") .. typeIndicator
            
            if player then
                pcall(function()
                    local thumb = Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size60x60)
                    AvatarImg.Image = thumb
                end)
            else
                -- For dummies without player object, use default icon
                AvatarImg.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
            end
        end

        DistLabel.Text = string.format("%.1f studs", targetData.Distance)
        
        -- Get health from either Humanoid or Player object
        local health, maxHealth = GetHealth(player, humanoid)
        
        if health and maxHealth then
            local currentHealth = math.max(0, math.floor(health))
            local currentMaxHealth = math.max(1, math.floor(maxHealth))
            local pct = math.clamp(health / maxHealth, 0, 1)

            HealthLabel.Text = string.format("%d HP", currentHealth)
            HealthBar.Size = UDim2.new(pct, 0, 1, 0)

            if pct > 0.5 then
                HealthBar.BackgroundColor3 = AccentColor
            elseif pct > 0.25 then
                HealthBar.BackgroundColor3 = Color3.fromRGB(235, 175, 45)
            else
                HealthBar.BackgroundColor3 = Color3.fromRGB(235, 55, 55)
            end
        else
            -- No health data available
            HealthLabel.Text = "No HP"
            HealthBar.Size = UDim2.new(1, 0, 1, 0)
            HealthBar.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
        end
    end

    HUD.Create()
    return HUD
end)()
echo
cat >> src/modules/unstablesmp.lua << 'LUAEOF'

-- ============================================================================
-- 4. COMBAT MODULE
-- ============================================================================
local Combat = (function()
    local Module = {
        KillAura = {
            Enabled = false,
            Settings = {
                Range = 16,
                RotationSpeed = 8,
                AttackDelay = 0.14,
                TargetMode = "Closest", -- "Closest", "Health"
                VisibleCheck = true,
                TeamCheck = true,
                SmoothLock = true,
                AutoEquip = true,
                SilentAura = false, -- No camera rotation, attacks without looking
                TargetType = "All" -- NEW: "All", "PlayersOnly", "DummiesOnly"
            }
        },
        HitboxExpander = {
            Enabled = false,
            Size = 9,
            OriginalSizes = {},
            Connection = nil
        },
        AutoClicker = {
            Enabled = false,
            CPS = 14,
            Connection = nil
        }
    }

    local CurrentTarget = nil
    local LastAttackTick = 0
    local RotationConnection = nil

    local function GetCharacter()
        return LocalPlayer.Character
    end

    local function GetRootPart()
        local char = GetCharacter()
        return char and char:FindFirstChild("HumanoidRootPart")
    end

    local function IsTeammate(player)
        if not Module.KillAura.Settings.TeamCheck then return false end
        if not LocalPlayer.Team then return false end
        return player.Team == LocalPlayer.Team
    end

    local function IsVisible(targetPart)
        if not Module.KillAura.Settings.VisibleCheck then return true end
        local root = GetRootPart()
        if not root then return false end

        local ray = Ray.new(root.Position, (targetPart.Position - root.Position).Unit * Module.KillAura.Settings.Range)
        local hit = Workspace:FindPartOnRayWithIgnoreList(ray, {GetCharacter()})
        return hit and hit:IsDescendantOf(targetPart.Parent)
    end

    local function GetTargets()
        local targets = {}
        local root = GetRootPart()
        if not root then return targets end

        -- Helper function to check if character is a dummy/bot
        local function IsDummy(character)
            -- Check if parent is Dummies folder or similar
            if character.Parent and character.Parent.Name:lower():find("dummies") then
                return true
            end
            if character.Parent and character.Parent.Name:lower():find("dummy") then
                return true
            end
            if character.Parent and character.Parent.Name:lower():find("bots") then
                return true
            end
            -- Check if character name contains "Dummy" or "Bot"
            if character.Name:lower():find("dummy") then
                return true
            end
            if character.Name:lower():find("bot") then
                return true
            end
            return false
        end

        -- Scan Players
        if Module.KillAura.Settings.TargetType == "All" or Module.KillAura.Settings.TargetType == "PlayersOnly" then
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    -- Try multiple methods to find the root part (custom models support)
                    local targetRoot = player.Character:FindFirstChild("HumanoidRootPart") 
                                    or player.Character:FindFirstChild("Torso")
                                    or player.Character:FindFirstChild("UpperTorso")
                                    or player.Character:FindFirstChild("Root")
                                    or player.Character.PrimaryPart
                    
                    -- Try to find humanoid (works with both standard and custom)
                    local targetHum = player.Character:FindFirstChildOfClass("Humanoid")
                                    or player.Character:FindFirstChild("Humanoid")
                    
                    -- Check health from either Humanoid or Player object
                    local health, maxHealth = GetHealth(player, targetHum)
                    
                    -- If no humanoid found, check if character has a primary part (custom models)
                    local isValid = false
                    if health and health > 0 then
                        isValid = true
                    elseif targetRoot then
                        -- Custom model without humanoid or health - check if it's a valid character
                        isValid = true
                    end

                    if targetRoot and isValid then
                        local distance = (root.Position - targetRoot.Position).Magnitude
                        if distance <= Module.KillAura.Settings.Range and not IsTeammate(player) then
                            if IsVisible(targetRoot) then
                                table.insert(targets, {
                                    Player = player,
                                    Character = player.Character,
                                    Root = targetRoot,
                                    Humanoid = targetHum,
                                    Distance = distance,
                                    IsCustomModel = targetHum == nil, -- Flag for custom models
                                    IsDummy = false, -- Player entity
                                    DisplayName = player.DisplayName or player.Name
                                })
                            end
                        end
                    end
                end
            end
        end

        -- Scan Dummies/Bots (from Workspace)
        if Module.KillAura.Settings.TargetType == "All" or Module.KillAura.Settings.TargetType == "DummiesOnly" then
            -- Check Workspace.Dummies folder
            local dummiesFolder = Workspace:FindFirstChild("Dummies")
            if dummiesFolder then
                for _, character in pairs(dummiesFolder:GetChildren()) do
                    if character:IsA("Model") then
                        local targetRoot = character:FindFirstChild("HumanoidRootPart")
                                        or character:FindFirstChild("Torso")
                                        or character:FindFirstChild("UpperTorso")
                                        or character:FindFirstChild("Root")
                                        or character.PrimaryPart
                        
                        local targetHum = character:FindFirstChildOfClass("Humanoid")
                                       or character:FindFirstChild("Humanoid")

                        if targetRoot then
                            local isValid = not targetHum or targetHum.Health > 0
                            if isValid then
                                local distance = (root.Position - targetRoot.Position).Magnitude
                                if distance <= Module.KillAura.Settings.Range then
                                    if IsVisible(targetRoot) then
                                        table.insert(targets, {
                                            Player = nil,
                                            Character = character,
                                            Root = targetRoot,
                                            Humanoid = targetHum,
                                            Distance = distance,
                                            IsCustomModel = targetHum == nil,
                                            IsDummy = true, -- Dummy/Bot entity
                                            DisplayName = character.Name
                                        })
                                    end
                                end
                            end
                        end
                    end
                end
            end

            -- Also check for loose dummies/bots in Workspace
            for _, character in pairs(Workspace:GetChildren()) do
                if character:IsA("Model") and IsDummy(character) then
                    local targetRoot = character:FindFirstChild("HumanoidRootPart")
                                    or character:FindFirstChild("Torso")
                                    or character:FindFirstChild("UpperTorso")
                                    or character:FindFirstChild("Root")
                                    or character.PrimaryPart
                    
                    local targetHum = character:FindFirstChildOfClass("Humanoid")
                                   or character:FindFirstChild("Humanoid")

                    if targetRoot then
                        local isValid = not targetHum or targetHum.Health > 0
                        if isValid then
                            local distance = (root.Position - targetRoot.Position).Magnitude
                            if distance <= Module.KillAura.Settings.Range then
                                if IsVisible(targetRoot) then
                                    table.insert(targets, {
                                        Player = nil,
                                        Character = character,
                                        Root = targetRoot,
                                        Humanoid = targetHum,
                                        Distance = distance,
                                        IsCustomModel = targetHum == nil,
                                        IsDummy = true,
                                        DisplayName = character.Name
                                    })
                                end
                            end
                        end
                    end
                end
            end
        end

        return targets
    end

    local function GetBestTarget()
        local targets = GetTargets()
        if #targets == 0 then return nil end

        if Module.KillAura.Settings.TargetMode == "Health" then
            table.sort(targets, function(a, b)
                return (a.Humanoid and a.Humanoid.Health or math.huge) < (b.Humanoid and b.Humanoid.Health or math.huge)
            end)
        else
            table.sort(targets, function(a, b) return a.Distance < b.Distance end)
        end
        return targets[1]
    end

    local function RotateToTarget(targetPos, delta)
        local currentCFrame = Camera.CFrame
        local targetCFrame = CFrame.new(Camera.CFrame.Position, targetPos)

        if Module.KillAura.Settings.SmoothLock then
            local speed = Module.KillAura.Settings.RotationSpeed * delta
            Camera.CFrame = currentCFrame:Lerp(targetCFrame, math.min(speed, 1))
        else
            Camera.CFrame = targetCFrame
        end
    end

    local function AutoEquipTool()
        if not Module.KillAura.Settings.AutoEquip then return end
        local char = GetCharacter()
        if not char then return end

        if not char:FindFirstChildOfClass("Tool") then
            local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
            if backpack then
                local tool = backpack:FindFirstChildOfClass("Tool")
                if tool then
                    tool.Parent = char
                end
            end
        end
    end

    local function AttackTarget()
        local currentTime = tick()
        if currentTime - LastAttackTick < Module.KillAura.Settings.AttackDelay then
            return
        end

        local char = GetCharacter()
        if not char then return end

        AutoEquipTool()

        local tool = char:FindFirstChildOfClass("Tool")
        if tool then
            tool:Activate()
            LastAttackTick = currentTime
            
            -- For custom models, also try RemoteEvent firing if tool doesn't work
            if CurrentTarget and CurrentTarget.IsCustomModel then
                -- Some custom model games use RemoteEvents for attacking
                local remotes = tool:GetDescendants()
                for _, remote in pairs(remotes) do
                    if remote:IsA("RemoteEvent") and (remote.Name:lower():find("hit") or remote.Name:lower():find("attack") or remote.Name:lower():find("damage")) then
                        pcall(function()
                            remote:FireServer(CurrentTarget.Character)
                        end)
                    end
                end
            end
        end
    end

    local function OnRenderStep(delta)
        if not Module.KillAura.Enabled then return end

        CurrentTarget = GetBestTarget()
        TargetHUD.Update(CurrentTarget)

        if CurrentTarget then
            -- Only rotate camera if Silent Aura is OFF
            if not Module.KillAura.Settings.SilentAura then
                RotateToTarget(CurrentTarget.Root.Position, delta)
            end
            AttackTarget()
        end
    end

    function Module:ToggleKillAura(state)
        if state ~= nil then
            self.KillAura.Enabled = state
        else
            self.KillAura.Enabled = not self.KillAura.Enabled
        end

        if self.KillAura.Enabled then
            RotationConnection = RunService.RenderStepped:Connect(OnRenderStep)
            RegisterConnection(RotationConnection)
            NotificationSystem.Notify("Combat", "KillAura: ENABLED", 2)
        else
            if RotationConnection then
                RotationConnection:Disconnect()
                RotationConnection = nil
            end
            CurrentTarget = nil
            TargetHUD.Update(nil)
            NotificationSystem.Notify("Combat", "KillAura: DISABLED", 2)
        end
    end

    function Module:SetSetting(setting, value)
        if self.KillAura.Settings[setting] ~= nil then
            self.KillAura.Settings[setting] = value
        end
    end

    function Module:ToggleHitboxExpander(state)
        if state ~= nil then
            self.HitboxExpander.Enabled = state
        else
            self.HitboxExpander.Enabled = not self.HitboxExpander.Enabled
        end

        if self.HitboxExpander.Enabled then
            self.HitboxExpander.Connection = RunService.Heartbeat:Connect(function()
                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer and player.Character and not IsTeammate(player) then
                        local root = player.Character:FindFirstChild("HumanoidRootPart")
                        if root then
                            if not self.HitboxExpander.OriginalSizes[root] then
                                self.HitboxExpander.OriginalSizes[root] = root.Size
                            end
                            root.Size = Vector3.new(self.HitboxExpander.Size, self.HitboxExpander.Size, self.HitboxExpander.Size)
                            root.Transparency = 0.7
                            root.CanCollide = false
                        end
                    end
                end
            end)
            RegisterConnection(self.HitboxExpander.Connection)
            NotificationSystem.Notify("Combat", "Hitbox Expander: ENABLED", 2)
        else
            if self.HitboxExpander.Connection then
                self.HitboxExpander.Connection:Disconnect()
                self.HitboxExpander.Connection = nil
            end
            for root, size in pairs(self.HitboxExpander.OriginalSizes) do
                if root and root.Parent then
                    root.Size = size
                    root.Transparency = 1
                end
            end
            self.HitboxExpander.OriginalSizes = {}
            NotificationSystem.Notify("Combat", "Hitbox Expander: DISABLED", 2)
        end
    end

    function Module:ToggleAutoClicker(state)
        if state ~= nil then
            self.AutoClicker.Enabled = state
        else
            self.AutoClicker.Enabled = not self.AutoClicker.Enabled
        end

        if self.AutoClicker.Enabled then
            self.AutoClicker.Connection = RunService.RenderStepped:Connect(function()
                local interval = 1 / self.AutoClicker.CPS
                if tick() - LastAttackTick >= interval then
                    local char = GetCharacter()
                    local tool = char and char:FindFirstChildOfClass("Tool")
                    if tool then
                        tool:Activate()
                        LastAttackTick = tick()
                    end
                end
            end)
            RegisterConnection(self.AutoClicker.Connection)
            NotificationSystem.Notify("Combat", "Auto Clicker: ENABLED", 2)
        else
            if self.AutoClicker.Connection then
                self.AutoClicker.Connection:Disconnect()
                self.AutoClicker.Connection = nil
            end
            NotificationSystem.Notify("Combat", "Auto Clicker: DISABLED", 2)
        end
    end

    return Module
end)()
echo
cat >> src/modules/unstablesmp.lua << 'LUAEOF'

-- ============================================================================
-- 5. MOVEMENT MODULE
-- ============================================================================
local Movement = (function()
    local Module = {
        Speed = {
            Enabled = false,
            Value = 32
        },
        Fly = {
            Enabled = false,
            Speed = 45,
            BodyVelocity = nil,
            BodyGyro = nil,
            Connection = nil
        },
        NoClip = {
            Enabled = false,
            Connection = nil
        },
        InfiniteJump = {
            Enabled = false,
            Connection = nil
        },
        HighJump = {
            Enabled = false,
            Power = 95
        },
        BunnyHop = {
            Enabled = false,
            Connection = nil
        }
    }

    local OriginalWalkSpeed = 16
    local OriginalJumpPower = 50

    local function GetCharacter()
        return LocalPlayer.Character
    end

    local function GetHumanoid()
        local char = GetCharacter()
        return char and char:FindFirstChildOfClass("Humanoid")
    end

    local function GetRootPart()
        local char = GetCharacter()
        return char and char:FindFirstChild("HumanoidRootPart")
    end

    function Module:ToggleSpeed(state)
        if state ~= nil then
            self.Speed.Enabled = state
        else
            self.Speed.Enabled = not self.Speed.Enabled
        end

        local hum = GetHumanoid()
        if hum then
            if self.Speed.Enabled then
                OriginalWalkSpeed = hum.WalkSpeed
                hum.WalkSpeed = self.Speed.Value
                NotificationSystem.Notify("Movement", "Speed [" .. self.Speed.Value .. "]: ON", 2)
            else
                hum.WalkSpeed = OriginalWalkSpeed > 0 and OriginalWalkSpeed or 16
                NotificationSystem.Notify("Movement", "Speed: OFF", 2)
            end
        end
    end

    function Module:SetSpeed(value)
        self.Speed.Value = value
        if self.Speed.Enabled then
            local hum = GetHumanoid()
            if hum then hum.WalkSpeed = value end
        end
    end

    function Module:ToggleFly(state)
        if state ~= nil then
            self.Fly.Enabled = state
        else
            self.Fly.Enabled = not self.Fly.Enabled
        end

        local root = GetRootPart()
        local hum = GetHumanoid()

        if not self.Fly.Enabled then
            if self.Fly.Connection then
                self.Fly.Connection:Disconnect()
                self.Fly.Connection = nil
            end
            if self.Fly.BodyVelocity then
                self.Fly.BodyVelocity:Destroy()
                self.Fly.BodyVelocity = nil
            end
            if self.Fly.BodyGyro then
                self.Fly.BodyGyro:Destroy()
                self.Fly.BodyGyro = nil
            end
            if hum then hum.PlatformStand = false end
            NotificationSystem.Notify("Movement", "Fly: DISABLED", 2)
            return
        end

        if not root or not hum then return end

        local bv = Instance.new("BodyVelocity")
        bv.Velocity = Vector3.new(0, 0, 0)
        bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        bv.Parent = root
        self.Fly.BodyVelocity = bv

        local bg = Instance.new("BodyGyro")
        bg.CFrame = root.CFrame
        bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        bg.P = 9e4
        bg.Parent = root
        self.Fly.BodyGyro = bg

        hum.PlatformStand = true

        self.Fly.Connection = RunService.RenderStepped:Connect(function()
            if not self.Fly.Enabled or not root or not root.Parent then
                self:ToggleFly(false)
                return
            end

            local cam = Workspace.CurrentCamera
            local moveDir = Vector3.zero

            if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                moveDir = moveDir + cam.CFrame.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                moveDir = moveDir - cam.CFrame.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                moveDir = moveDir - cam.CFrame.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                moveDir = moveDir + cam.CFrame.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                moveDir = moveDir + Vector3.new(0, 1, 0)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                moveDir = moveDir - Vector3.new(0, 1, 0)
            end

            if moveDir.Magnitude > 0 then
                bv.Velocity = moveDir.Unit * self.Fly.Speed
            else
                bv.Velocity = Vector3.zero
            end
            bg.CFrame = cam.CFrame
        end)
        RegisterConnection(self.Fly.Connection)
        NotificationSystem.Notify("Movement", "Fly: ENABLED (WASD + Space/Shift)", 2)
    end

    function Module:ToggleNoClip(state)
        if state ~= nil then
            self.NoClip.Enabled = state
        else
            self.NoClip.Enabled = not self.NoClip.Enabled
        end

        if self.NoClip.Enabled then
            self.NoClip.Connection = RunService.Stepped:Connect(function()
                local char = GetCharacter()
                if char then
                    for _, part in pairs(char:GetDescendants()) do
                        if part:IsA("BasePart") and part.CanCollide then
                            part.CanCollide = false
                        end
                    end
                end
            end)
            RegisterConnection(self.NoClip.Connection)
            NotificationSystem.Notify("Movement", "NoClip: ENABLED", 2)
        else
            if self.NoClip.Connection then
                self.NoClip.Connection:Disconnect()
                self.NoClip.Connection = nil
            end
            NotificationSystem.Notify("Movement", "NoClip: DISABLED", 2)
        end
    end

    function Module:ToggleInfiniteJump(state)
        if state ~= nil then
            self.InfiniteJump.Enabled = state
        else
            self.InfiniteJump.Enabled = not self.InfiniteJump.Enabled
        end

        if self.InfiniteJump.Enabled then
            self.InfiniteJump.Connection = UserInputService.JumpRequest:Connect(function()
                local hum = GetHumanoid()
                if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
            end)
            RegisterConnection(self.InfiniteJump.Connection)
            NotificationSystem.Notify("Movement", "Infinite Jump: ENABLED", 2)
        else
            if self.InfiniteJump.Connection then
                self.InfiniteJump.Connection:Disconnect()
                self.InfiniteJump.Connection = nil
            end
            NotificationSystem.Notify("Movement", "Infinite Jump: DISABLED", 2)
        end
    end

    function Module:ToggleHighJump(state)
        if state ~= nil then
            self.HighJump.Enabled = state
        else
            self.HighJump.Enabled = not self.HighJump.Enabled
        end

        local hum = GetHumanoid()
        if hum then
            if self.HighJump.Enabled then
                OriginalJumpPower = hum.JumpPower
                hum.JumpPower = self.HighJump.Power
                NotificationSystem.Notify("Movement", "High Jump: ENABLED", 2)
            else
                hum.JumpPower = OriginalJumpPower > 0 and OriginalJumpPower or 50
                NotificationSystem.Notify("Movement", "High Jump: DISABLED", 2)
            end
        end
    end

    function Module:ToggleBunnyHop(state)
        if state ~= nil then
            self.BunnyHop.Enabled = state
        else
            self.BunnyHop.Enabled = not self.BunnyHop.Enabled
        end

        if self.BunnyHop.Enabled then
            self.BunnyHop.Connection = RunService.Heartbeat:Connect(function()
                local hum = GetHumanoid()
                if hum and hum.FloorMaterial ~= Enum.Material.Air and hum.MoveDirection.Magnitude > 0 then
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end)
            RegisterConnection(self.BunnyHop.Connection)
            NotificationSystem.Notify("Movement", "BunnyHop: ENABLED", 2)
        else
            if self.BunnyHop.Connection then
                self.BunnyHop.Connection:Disconnect()
                self.BunnyHop.Connection = nil
            end
            NotificationSystem.Notify("Movement", "BunnyHop: DISABLED", 2)
        end
    end

    LocalPlayer.CharacterAdded:Connect(function(char)
        task.wait(0.5)
        local hum = char:WaitForChild("Humanoid", 5)
        if not hum then return end
        if Module.Speed.Enabled then hum.WalkSpeed = Module.Speed.Value end
        if Module.HighJump.Enabled then hum.JumpPower = Module.HighJump.Power end
        if Module.Fly.Enabled then
            Module:ToggleFly(false)
            Module:ToggleFly(true)
        end
    end)

    return Module
end)()
echo
cat >> src/modules/unstablesmp.lua << 'LUAEOF'

-- ============================================================================
-- 6. VISUALS MODULE
-- ============================================================================
local Visuals = (function()
    local Module = {
        Chams = {
            Enabled = false,
            Highlights = {}
        },
        NameESP = {
            Enabled = false,
            Billboards = {}
        },
        Fullbright = {
            Enabled = false,
            Original = {},
            Connection = nil
        },
        FOV = {
            Enabled = false,
            Value = 90,
            Original = 70
        }
    }

    local function ApplyHighlight(player)
        if player == LocalPlayer or not player.Character then return end
        if Module.Chams.Highlights[player] then
            pcall(function() Module.Chams.Highlights[player]:Destroy() end)
            Module.Chams.Highlights[player] = nil
        end

        local char = player.Character
        local hl = Instance.new("Highlight")
        hl.Name = "DemiseChams"
        hl.Adornee = char
        hl.FillColor = AccentColor
        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
        hl.FillTransparency = 0.55
        hl.OutlineTransparency = 0.1
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent = char

        Module.Chams.Highlights[player] = hl
    end

    local function ApplyBillboard(player, isDummy)
        if player == LocalPlayer or (player.Character == nil and not isDummy) then return end
        local char = player.Character or player -- For dummies, player might be the character itself
        
        -- Try to find head or root part for attachment
        local head = char:FindFirstChild("Head") 
                  or char:FindFirstChild("HumanoidRootPart")
                  or char:FindFirstChild("UpperTorso")
                  or char.PrimaryPart
        
        if not head then return end

        if Module.NameESP.Billboards[player] then
            pcall(function() Module.NameESP.Billboards[player]:Destroy() end)
            Module.NameESP.Billboards[player] = nil
        end

        local bb = Instance.new("BillboardGui")
        bb.Name = "DemiseESP"
        bb.Adornee = head
        bb.Size = UDim2.new(0, 200, 0, 60)
        bb.StudsOffset = Vector3.new(0, 3.5, 0)
        bb.AlwaysOnTop = true
        bb.MaxDistance = 500

        -- Store isDummy flag for later use
        bb:SetAttribute("IsDummy", isDummy or false)

        -- Name Label with type icon
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Name = "NameLabel"
        nameLabel.Size = UDim2.new(1, 0, 0, 18)
        nameLabel.BackgroundTransparency = 1
        local displayName = player.DisplayName or player.Name
        local typeIcon = isDummy and "🤖 " or "👤 "
        nameLabel.Text = typeIcon .. displayName
        -- Different colors: Blue for players, Orange for dummies
        nameLabel.TextColor3 = isDummy and Color3.fromRGB(255, 180, 80) or Color3.fromRGB(80, 180, 255)
        nameLabel.TextStrokeTransparency = 0
        nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        nameLabel.TextSize = 14
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.Parent = bb
        nameLabel.TextStrokeTransparency = 0
        nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        nameLabel.TextSize = 14
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.Parent = bb

        -- Health Label (shows HP numbers)
        local healthLabel = Instance.new("TextLabel")
        healthLabel.Name = "HealthLabel"
        healthLabel.Size = UDim2.new(1, 0, 0, 14)
        healthLabel.Position = UDim2.new(0, 0, 0, 18)
        healthLabel.BackgroundTransparency = 1
        healthLabel.Text = "100 HP"
        healthLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        healthLabel.TextStrokeTransparency = 0
        healthLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        healthLabel.TextSize = 12
        healthLabel.Font = Enum.Font.Gotham
        healthLabel.Parent = bb

        -- Distance Label
        local distLabel = Instance.new("TextLabel")
        distLabel.Name = "DistLabel"
        distLabel.Size = UDim2.new(1, 0, 0, 14)
        distLabel.Position = UDim2.new(0, 0, 0, 32)
        distLabel.BackgroundTransparency = 1
        distLabel.Text = "0m"
        distLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        distLabel.TextStrokeTransparency = 0
        distLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        distLabel.TextSize = 11
        distLabel.Font = Enum.Font.Gotham
        distLabel.Parent = bb

        -- Health Bar Background
        local healthBarBg = Instance.new("Frame")
        healthBarBg.Name = "HealthBg"
        healthBarBg.Size = UDim2.new(0.8, 0, 0, 4)
        healthBarBg.Position = UDim2.new(0.1, 0, 0, 48)
        healthBarBg.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
        healthBarBg.BorderSizePixel = 0
        healthBarBg.Parent = bb

        local barCorner = Instance.new("UICorner")
        barCorner.CornerRadius = UDim.new(0, 2)
        barCorner.Parent = healthBarBg

        -- Health Bar Fill
        local fill = Instance.new("Frame")
        fill.Name = "Fill"
        fill.Size = UDim2.new(1, 0, 1, 0)
        fill.BackgroundColor3 = AccentColor
        fill.BorderSizePixel = 0
        fill.Parent = healthBarBg

        local fillCorner = Instance.new("UICorner")
        fillCorner.CornerRadius = UDim.new(0, 2)
        fillCorner.Parent = fill

        bb.Parent = head
        Module.NameESP.Billboards[player] = bb
    end

    function Module:ToggleChams(state)
        if state ~= nil then
            self.Chams.Enabled = state
        else
            self.Chams.Enabled = not self.Chams.Enabled
        end

        if self.Chams.Enabled then
            for _, player in ipairs(Players:GetPlayers()) do
                ApplyHighlight(player)
            end
            NotificationSystem.Notify("Visuals", "Player Chams: ENABLED", 2)
        else
            for player, hl in pairs(self.Chams.Highlights) do
                if hl then pcall(function() hl:Destroy() end) end
            end
            self.Chams.Highlights = {}
            NotificationSystem.Notify("Visuals", "Player Chams: DISABLED", 2)
        end
    end

    function Module:ToggleNameESP(state)
        if state ~= nil then
            self.NameESP.Enabled = state
        else
            self.NameESP.Enabled = not self.NameESP.Enabled
        end

        if self.NameESP.Enabled then
            -- Apply ESP to all players
            for _, player in ipairs(Players:GetPlayers()) do
                ApplyBillboard(player, false) -- false = not a dummy
            end
            
            -- Apply ESP to all dummies in Workspace.Dummies
            local dummiesFolder = Workspace:FindFirstChild("Dummies")
            if dummiesFolder then
                for _, dummy in pairs(dummiesFolder:GetChildren()) do
                    if dummy:IsA("Model") then
                        ApplyBillboard(dummy, true) -- true = is a dummy
                    end
                end
            end
            
            NotificationSystem.Notify("Visuals", "Name & Health ESP: ENABLED", 2)
        else
            for player, bb in pairs(self.NameESP.Billboards) do
                if bb then pcall(function() bb:Destroy() end) end
            end
            self.NameESP.Billboards = {}
            NotificationSystem.Notify("Visuals", "Name & Health ESP: DISABLED", 2)
        end
    end

    RunService.RenderStepped:Connect(function()
        if not Module.NameESP.Enabled then return end
        local myChar = LocalPlayer.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")

        for entity, bb in pairs(Module.NameESP.Billboards) do
            if entity and bb and bb.Parent then
                -- For players: entity.Character, for dummies: entity itself is the character
                local char = entity.Character or entity
                
                local hum = char:FindFirstChildOfClass("Humanoid") 
                         or char:FindFirstChild("Humanoid")
                local root = char:FindFirstChild("HumanoidRootPart")
                      or char:FindFirstChild("Torso")
                      or char:FindFirstChild("UpperTorso")
                      or char.PrimaryPart

                if root and myRoot then
                    -- Update distance
                    local dist = math.floor((myRoot.Position - root.Position).Magnitude)
                    local distLabel = bb:FindFirstChild("DistLabel")
                    if distLabel then
                        distLabel.Text = string.format("%d studs", dist)
                        
                        -- Color distance based on range
                        if dist < 20 then
                            distLabel.TextColor3 = Color3.fromRGB(255, 100, 100) -- Close = red
                        elseif dist < 50 then
                            distLabel.TextColor3 = Color3.fromRGB(255, 200, 100) -- Medium = orange
                        else
                            distLabel.TextColor3 = Color3.fromRGB(200, 200, 200) -- Far = gray
                        end
                    end

                    -- Get player object if this is a player entity
                    local playerObj = nil
                    if entity.ClassName == "Player" then
                        playerObj = entity
                    end
                    
                    -- Get health from either Humanoid or Player object
                    local health, maxHealth = GetHealth(playerObj, hum)
                    
                    -- Update health display
                    if health and maxHealth and maxHealth > 0 then
                        local currentHP = math.floor(health)
                        local maxHP = math.floor(maxHealth)
                        local pct = math.clamp(health / maxHealth, 0, 1)
                        
                        -- Update health label text
                        local healthLabel = bb:FindFirstChild("HealthLabel")
                        if healthLabel then
                            healthLabel.Text = string.format("%d / %d HP", currentHP, maxHP)
                            
                            -- Color health text based on percentage
                            if pct > 0.6 then
                                healthLabel.TextColor3 = Color3.fromRGB(100, 255, 100) -- Green
                            elseif pct > 0.3 then
                                healthLabel.TextColor3 = Color3.fromRGB(255, 200, 50) -- Yellow
                            else
                                healthLabel.TextColor3 = Color3.fromRGB(255, 50, 50) -- Red
                            end
                        end
                        
                        -- Update health bar
                        local healthBg = bb:FindFirstChild("HealthBg")
                        local fill = healthBg and healthBg:FindFirstChild("Fill")
                        if fill then
                            fill.Size = UDim2.new(pct, 0, 1, 0)
                            
                            -- Color health bar
                            if pct > 0.6 then
                                fill.BackgroundColor3 = Color3.fromRGB(100, 255, 100) -- Green
                            elseif pct > 0.3 then
                                fill.BackgroundColor3 = Color3.fromRGB(255, 200, 50) -- Yellow
                            else
                                fill.BackgroundColor3 = Color3.fromRGB(255, 50, 50) -- Red
                            end
                        end
                    else
                        -- No humanoid - show as custom model
                        local healthLabel = bb:FindFirstChild("HealthLabel")
                        if healthLabel then
                            healthLabel.Text = "Custom Model"
                            healthLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
                        end
                    end
                end
            end
        end
    end)

    Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function()
            task.wait(0.5)
            if Module.Chams.Enabled then ApplyHighlight(player) end
            if Module.NameESP.Enabled then ApplyBillboard(player, false) end -- false = not dummy
        end)
    end)

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            player.CharacterAdded:Connect(function()
                task.wait(0.5)
                if Module.Chams.Enabled then ApplyHighlight(player) end
                if Module.NameESP.Enabled then ApplyBillboard(player, false) end -- false = not dummy
            end)
        end
    end

    -- Watch for new dummies being added to Workspace.Dummies
    local dummiesFolder = Workspace:FindFirstChild("Dummies")
    if dummiesFolder then
        dummiesFolder.ChildAdded:Connect(function(child)
            if child:IsA("Model") and Module.NameESP.Enabled then
                task.wait(0.3)
                ApplyBillboard(child, true) -- true = is dummy
            end
        end)
    end

    function Module:ToggleFullbright(state)
        if state ~= nil then
            self.Fullbright.Enabled = state
        else
            self.Fullbright.Enabled = not self.Fullbright.Enabled
        end

        if self.Fullbright.Enabled then
            self.Fullbright.Original.Ambient = Lighting.Ambient
            self.Fullbright.Original.OutdoorAmbient = Lighting.OutdoorAmbient
            self.Fullbright.Original.Brightness = Lighting.Brightness
            self.Fullbright.Original.ClockTime = Lighting.ClockTime
            self.Fullbright.Original.FogEnd = Lighting.FogEnd

            self.Fullbright.Connection = RunService.RenderStepped:Connect(function()
                Lighting.Ambient = Color3.fromRGB(255, 255, 255)
                Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
                Lighting.Brightness = 2
                Lighting.ClockTime = 14
                Lighting.FogEnd = 1000000
            end)
            RegisterConnection(self.Fullbright.Connection)
            NotificationSystem.Notify("Visuals", "Fullbright: ENABLED", 2)
        else
            if self.Fullbright.Connection then
                self.Fullbright.Connection:Disconnect()
                self.Fullbright.Connection = nil
            end
            if self.Fullbright.Original.Ambient then
                Lighting.Ambient = self.Fullbright.Original.Ambient
                Lighting.OutdoorAmbient = self.Fullbright.Original.OutdoorAmbient
                Lighting.Brightness = self.Fullbright.Original.Brightness
                Lighting.ClockTime = self.Fullbright.Original.ClockTime
                Lighting.FogEnd = self.Fullbright.Original.FogEnd
            end
            NotificationSystem.Notify("Visuals", "Fullbright: DISABLED", 2)
        end
    end

    function Module:ToggleFOV(state)
        if state ~= nil then
            self.FOV.Enabled = state
        else
            self.FOV.Enabled = not self.FOV.Enabled
        end

        if self.FOV.Enabled then
            Camera.FieldOfView = self.FOV.Value
            NotificationSystem.Notify("Visuals", "FOV: " .. self.FOV.Value, 2)
        else
            Camera.FieldOfView = self.FOV.Original
            NotificationSystem.Notify("Visuals", "FOV: Default", 2)
        end
    end

    function Module:SetFOV(value)
        self.FOV.Value = value
        if self.FOV.Enabled then
            Camera.FieldOfView = value
        end
    end

    return Module
end)()
echo
cat >> src/modules/unstablesmp.lua << 'LUAEOF'

-- ============================================================================
-- 7. MISC MODULE
-- ============================================================================
local Misc = (function()
    local Module = {
        AntiAFK = {
            Enabled = false,
            Connection = nil
        },
        FPSBooster = {
            Enabled = false
        }
    }

    function Module:ToggleAntiAFK(state)
        if state ~= nil then
            self.AntiAFK.Enabled = state
        else
            self.AntiAFK.Enabled = not self.AntiAFK.Enabled
        end

        if self.AntiAFK.Enabled then
            self.AntiAFK.Connection = LocalPlayer.Idled:Connect(function()
                pcall(function()
                    VirtualUser:CaptureController()
                    VirtualUser:ClickButton2(Vector2.zero)
                end)
            end)
            RegisterConnection(self.AntiAFK.Connection)
            NotificationSystem.Notify("Misc", "Anti-AFK: ENABLED (No 20m Kick)", 2)
        else
            if self.AntiAFK.Connection then
                self.AntiAFK.Connection:Disconnect()
                self.AntiAFK.Connection = nil
            end
            NotificationSystem.Notify("Misc", "Anti-AFK: DISABLED", 2)
        end
    end

    function Module:ToggleFPSBooster(state)
        if state ~= nil then
            self.FPSBooster.Enabled = state
        else
            self.FPSBooster.Enabled = not self.FPSBooster.Enabled
        end

        if self.FPSBooster.Enabled then
            pcall(function()
                local terrain = workspace:FindFirstChildOfClass("Terrain")
                if terrain then
                    terrain.WaterWaveSize = 0
                    terrain.WaterWaveSpeed = 0
                    terrain.WaterReflectance = 0
                    terrain.WaterTransparency = 0
                end
                Lighting.GlobalShadows = false
                Lighting.FogEnd = 9e9

                for _, obj in ipairs(workspace:GetDescendants()) do
                    if obj:IsA("BasePart") and not obj:IsA("MeshPart") then
                        obj.Material = Enum.Material.SmoothPlastic
                        obj.Reflectance = 0
                    elseif obj:IsA("Decal") or obj:IsA("Texture") then
                        obj.Transparency = 1
                    elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") then
                        obj.Lifetime = NumberRange.new(0)
                    end
                end
            end)
            NotificationSystem.Notify("Misc", "FPS Booster: ENABLED", 2)
        end
    end

    function Module:Rejoin()
        NotificationSystem.Notify("Misc", "Rejoining Server...", 2)
        task.wait(0.5)
        pcall(function()
            if #Players:GetPlayers() <= 1 then
                TeleportService:Teleport(game.PlaceId, LocalPlayer)
            else
                TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
            end
        end)
    end

    function Module:ServerHop()
        NotificationSystem.Notify("Misc", "Finding New Server...", 2)
        task.wait(0.5)
        pcall(function()
            local placeId = game.PlaceId
            local serversUrl = string.format("https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Asc&limit=100", tostring(placeId))
            local success, result = pcall(function() return game:HttpGet(serversUrl) end)

            if success and result then
                local data = HttpService:JSONDecode(result)
                if data and data.data then
                    for _, server in ipairs(data.data) do
                        if server.playing < server.maxPlayers and server.id ~= game.JobId then
                            TeleportService:TeleportToPlaceInstance(placeId, server.id, LocalPlayer)
                            return
                        end
                    end
                end
            end
            TeleportService:Teleport(placeId, LocalPlayer)
        end)
    end

    return Module
end)()
echo
cat >> src/modules/unstablesmp.lua << 'LUAEOF'

-- ============================================================================
-- 8. CLICK GUI MODULE (Rise & Vape Modes with Dynamic Theming)
-- ============================================================================
local ClickGUI = (function()
    local GUI = {
        Visible = false,
        ScreenGui = nil,
        Mode = "Rise", -- "Rise" or "Vape"
        OpenKey = Enum.KeyCode.RightControl, -- Changed to Right Ctrl
        WatermarkGui = nil
    }

    function GUI.CreateWatermark()
        if GUI.WatermarkGui then
            pcall(function() GUI.WatermarkGui:Destroy() end)
        end

        local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
        local WatermarkGui = Instance.new("ScreenGui")
        WatermarkGui.Name = "DemiseWatermark"
        WatermarkGui.ResetOnSpawn = false
        WatermarkGui.DisplayOrder = 100001
        RegisterInstance(WatermarkGui)

        local WatermarkFrame = Instance.new("Frame")
        WatermarkFrame.Size = UDim2.new(0, 240, 0, 32)
        WatermarkFrame.Position = UDim2.new(1, -250, 0, 10)
        WatermarkFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
        WatermarkFrame.BorderSizePixel = 0
        WatermarkFrame.Parent = WatermarkGui

        local Corner = Instance.new("UICorner")
        Corner.CornerRadius = UDim.new(0, 6)
        Corner.Parent = WatermarkFrame

        local Stroke = Instance.new("UIStroke")
        Stroke.Color = Color3.fromRGB(45, 45, 55)
        Stroke.Thickness = 1
        Stroke.Parent = WatermarkFrame

        local AccentBar = Instance.new("Frame")
        AccentBar.Size = UDim2.new(0, 3, 1, -12)
        AccentBar.Position = UDim2.new(0, 6, 0, 6)
        AccentBar.BackgroundColor3 = AccentColor
        AccentBar.BorderSizePixel = 0
        AccentBar.Parent = WatermarkFrame

        local BarCorner = Instance.new("UICorner")
        BarCorner.CornerRadius = UDim.new(1, 0)
        BarCorner.Parent = AccentBar

        local WatermarkText = Instance.new("TextLabel")
        WatermarkText.Size = UDim2.new(1, -25, 1, 0)
        WatermarkText.Position = UDim2.new(0, 16, 0, 0)
        WatermarkText.BackgroundTransparency = 1
        WatermarkText.Text = "demise v2.0 | 60 FPS"
        WatermarkText.TextColor3 = Color3.fromRGB(255, 255, 255)
        WatermarkText.TextSize = 13
        WatermarkText.Font = Enum.Font.GothamBold
        WatermarkText.TextXAlignment = Enum.TextXAlignment.Left
        WatermarkText.Parent = WatermarkFrame

        WatermarkGui.Parent = PlayerGui
        GUI.WatermarkGui = WatermarkGui

        task.spawn(function()
            while WatermarkGui and WatermarkGui.Parent do
                local fps = math.floor(1 / math.max(0.001, RunService.RenderStepped:Wait()))
                WatermarkText.Text = string.format("demise v2.0 | %d FPS | %s", fps, GUI.Mode)
                task.wait(0.5)
            end
        end)
    end

    function GUI.Create()
        local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
        local ScreenGui = Instance.new("ScreenGui")
        ScreenGui.Name = "DemiseClickGUI"
        ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        ScreenGui.ResetOnSpawn = false
        ScreenGui.IgnoreGuiInset = true
        ScreenGui.DisplayOrder = 100000
        RegisterInstance(ScreenGui)

        local BlurFrame = Instance.new("Frame")
        BlurFrame.Name = "Overlay"
        BlurFrame.Size = UDim2.new(1, 0, 1, 0)
        BlurFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        BlurFrame.BackgroundTransparency = 0.45
        BlurFrame.BorderSizePixel = 0
        BlurFrame.Parent = ScreenGui

        if GUI.Mode == "Rise" then
            GUI.CreateRiseMode(ScreenGui)
        else
            GUI.CreateVapeMode(ScreenGui)
        end

        ScreenGui.Parent = PlayerGui
        GUI.ScreenGui = ScreenGui
        return ScreenGui
    end

    -- ========================================================================
    -- RISE MODE (Sleek Sidebar Layout)
    -- ========================================================================
    function GUI.CreateRiseMode(ScreenGui)
        local MainFrame = Instance.new("Frame")
        MainFrame.Name = "MainFrame"
        MainFrame.Size = UDim2.new(0, 560, 0, 390)
        MainFrame.Position = UDim2.new(0.5, -280, 0.5, -195)
        MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 23)
        MainFrame.BorderSizePixel = 0
        MainFrame.Parent = ScreenGui

        local MainCorner = Instance.new("UICorner")
        MainCorner.CornerRadius = UDim.new(0, 8)
        MainCorner.Parent = MainFrame

        local MainStroke = Instance.new("UIStroke")
        MainStroke.Color = Color3.fromRGB(45, 45, 55)
        MainStroke.Thickness = 1.2
        MainStroke.Parent = MainFrame

        -- Top Bar
        local TopBar = Instance.new("Frame")
        TopBar.Name = "TopBar"
        TopBar.Size = UDim2.new(1, 0, 0, 42)
        TopBar.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
        TopBar.BorderSizePixel = 0
        TopBar.Parent = MainFrame

        local TopCorner = Instance.new("UICorner")
        TopCorner.CornerRadius = UDim.new(0, 8)
        TopCorner.Parent = TopBar

        local TopBarFix = Instance.new("Frame")
        TopBarFix.Size = UDim2.new(1, 0, 0, 12)
        TopBarFix.Position = UDim2.new(0, 0, 1, -12)
        TopBarFix.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
        TopBarFix.BorderSizePixel = 0
        TopBarFix.Parent = TopBar

        local Title = Instance.new("TextLabel")
        Title.Size = UDim2.new(0, 100, 1, 0)
        Title.Position = UDim2.new(0, 15, 0, 0)
        Title.BackgroundTransparency = 1
        Title.Text = "demise"
        Title.TextColor3 = Color3.fromRGB(255, 255, 255)
        Title.TextSize = 18
        Title.Font = Enum.Font.GothamBold
        Title.TextXAlignment = Enum.TextXAlignment.Left
        Title.Parent = TopBar

        local Version = Instance.new("TextLabel")
        Version.Size = UDim2.new(0, 60, 1, 0)
        Version.Position = UDim2.new(0, 85, 0, 0)
        Version.BackgroundTransparency = 1
        Version.Text = "v2.0"
        Version.TextColor3 = Color3.fromRGB(130, 130, 140)
        Version.TextSize = 12
        Version.Font = Enum.Font.Gotham
        Version.TextXAlignment = Enum.TextXAlignment.Left
        Version.Parent = TopBar

        local ModeBadge = Instance.new("TextLabel")
        ModeBadge.Size = UDim2.new(0, 90, 0, 20)
        ModeBadge.Position = UDim2.new(1, -135, 0.5, -10)
        ModeBadge.BackgroundColor3 = Color3.fromRGB(32, 32, 40)
        ModeBadge.Text = "Rise Mode"
        ModeBadge.TextColor3 = AccentColor
        ModeBadge.TextSize = 11
        ModeBadge.Font = Enum.Font.GothamBold
        ModeBadge.Parent = TopBar

        local BadgeCorner = Instance.new("UICorner")
        BadgeCorner.CornerRadius = UDim.new(0, 4)
        BadgeCorner.Parent = ModeBadge

        local CloseBtn = Instance.new("TextButton")
        CloseBtn.Size = UDim2.new(0, 28, 0, 28)
        CloseBtn.Position = UDim2.new(1, -35, 0.5, -14)
        CloseBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
        CloseBtn.BorderSizePixel = 0
        CloseBtn.Text = "×"
        CloseBtn.TextColor3 = Color3.fromRGB(220, 220, 225)
        CloseBtn.TextSize = 20
        CloseBtn.Font = Enum.Font.GothamBold
        CloseBtn.Parent = TopBar

        local CloseCorner = Instance.new("UICorner")
        CloseCorner.CornerRadius = UDim.new(0, 4)
        CloseCorner.Parent = CloseBtn

        CloseBtn.MouseButton1Click:Connect(function()
            GUI:Toggle()
        end)

        -- Left TabBar
        local TabBar = Instance.new("Frame")
        TabBar.Name = "TabBar"
        TabBar.Size = UDim2.new(0, 125, 1, -55)
        TabBar.Position = UDim2.new(0, 12, 0, 48)
        TabBar.BackgroundTransparency = 1
        TabBar.Parent = MainFrame

        local TabList = Instance.new("UIListLayout")
        TabList.Padding = UDim.new(0, 6)
        TabList.Parent = TabBar

        -- Right Content Area
        local ContentFrame = Instance.new("ScrollingFrame")
        ContentFrame.Name = "ContentFrame"
        ContentFrame.Size = UDim2.new(1, -155, 1, -55)
        ContentFrame.Position = UDim2.new(0, 145, 0, 48)
        ContentFrame.BackgroundTransparency = 1
        ContentFrame.BorderSizePixel = 0
        ContentFrame.ScrollBarThickness = 4
        ContentFrame.ScrollBarImageColor3 = AccentColor
        ContentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
        ContentFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
        ContentFrame.Parent = MainFrame

        local ContentLayout = Instance.new("UIListLayout")
        ContentLayout.Padding = UDim.new(0, 10)
        ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
        ContentLayout.Parent = ContentFrame

        local tabs = {
            { Name = "Combat", Icon = "⚔️" },
            { Name = "Movement", Icon = "🏃" },
            { Name = "Player", Icon = "👤" },
            { Name = "World", Icon = "🌍" },
            { Name = "Render", Icon = "👁️" },
            { Name = "Utility", Icon = "🔧" },
            { Name = "Misc", Icon = "📦" },
            { Name = "Config", Icon = "💾" },
            { Name = "Settings", Icon = "⚙️" }
        }
        local currentTab = "Combat"

        local function BuildTabs()
            for _, tabInfo in ipairs(tabs) do
                local name = tabInfo.Name
                local btn = Instance.new("TextButton")
                btn.Name = name .. "Tab"
                btn.Size = UDim2.new(1, 0, 0, 36)
                btn.BackgroundColor3 = (name == currentTab) and Color3.fromRGB(35, 35, 45) or Color3.fromRGB(24, 24, 30)
                btn.BorderSizePixel = 0
                btn.Text = "  " .. tabInfo.Icon .. " " .. name
                btn.TextColor3 = (name == currentTab) and AccentColor or Color3.fromRGB(200, 200, 205)
                btn.TextSize = 13
                btn.Font = Enum.Font.GothamBold
                btn.TextXAlignment = Enum.TextXAlignment.Left
                btn.Parent = TabBar

                local corner = Instance.new("UICorner")
                corner.CornerRadius = UDim.new(0, 5)
                corner.Parent = btn

                btn.MouseButton1Click:Connect(function()
                    currentTab = name
                    for _, child in pairs(TabBar:GetChildren()) do
                        if child:IsA("TextButton") then
                            child.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
                            child.TextColor3 = Color3.fromRGB(200, 200, 205)
                        end
                    end
                    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
                    btn.TextColor3 = AccentColor
                    GUI.PopulateTab(ContentFrame, name)
                end)
            end
        end

        BuildTabs()
        GUI.PopulateTab(ContentFrame, "Combat")

        -- Make Draggable
        local dragging, dragInput, mousePos, framePos
        TopBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                mousePos = input.Position
                framePos = MainFrame.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)
        TopBar.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                dragInput = input
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if input == dragInput and dragging then
                local delta = input.Position - mousePos
                MainFrame.Position = UDim2.new(
                    framePos.X.Scale, framePos.X.Offset + delta.X,
                    framePos.Y.Scale, framePos.Y.Offset + delta.Y
                )
            end
        end)
    end
echo
cat >> src/modules/unstablesmp.lua << 'LUAEOF'

    -- ========================================================================
    -- VAPE MODE (Card Grid Layout)
    -- ========================================================================
    function GUI.CreateVapeMode(ScreenGui)
        local Container = Instance.new("Frame")
        Container.Name = "VapeContainer"
        Container.Size = UDim2.new(0, 720, 0, 420)
        Container.Position = UDim2.new(0.5, -360, 0.5, -210)
        Container.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
        Container.BorderSizePixel = 0
        Container.Parent = ScreenGui

        local Corner = Instance.new("UICorner")
        Corner.CornerRadius = UDim.new(0, 8)
        Corner.Parent = Container

        local Stroke = Instance.new("UIStroke")
        Stroke.Color = Color3.fromRGB(40, 40, 50)
        Stroke.Thickness = 1.2
        Stroke.Parent = Container

        -- Header
        local Header = Instance.new("Frame")
        Header.Size = UDim2.new(1, 0, 0, 40)
        Header.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
        Header.BorderSizePixel = 0
        Header.Parent = Container

        local HCorner = Instance.new("UICorner")
        HCorner.CornerRadius = UDim.new(0, 8)
        HCorner.Parent = Header

        local Title = Instance.new("TextLabel")
        Title.Size = UDim2.new(0, 160, 1, 0)
        Title.Position = UDim2.new(0, 15, 0, 0)
        Title.BackgroundTransparency = 1
        Title.Text = "demise v2.0 | VAPE"
        Title.TextColor3 = AccentColor
        Title.TextSize = 16
        Title.Font = Enum.Font.GothamBold
        Title.TextXAlignment = Enum.TextXAlignment.Left
        Title.Parent = Header

        local SwitchRise = Instance.new("TextButton")
        SwitchRise.Size = UDim2.new(0, 120, 0, 24)
        SwitchRise.Position = UDim2.new(1, -165, 0.5, -12)
        SwitchRise.BackgroundColor3 = Color3.fromRGB(32, 32, 40)
        SwitchRise.Text = "Switch to Rise"
        SwitchRise.TextColor3 = Color3.fromRGB(255, 255, 255)
        SwitchRise.TextSize = 11
        SwitchRise.Font = Enum.Font.Gotham
        SwitchRise.Parent = Header

        local SCorner = Instance.new("UICorner")
        SCorner.CornerRadius = UDim.new(0, 4)
        SCorner.Parent = SwitchRise

        SwitchRise.MouseButton1Click:Connect(function()
            GUI.Mode = "Rise"
            GUI:Toggle()
            GUI:Toggle()
        end)

        local CloseBtn = Instance.new("TextButton")
        CloseBtn.Size = UDim2.new(0, 28, 0, 28)
        CloseBtn.Position = UDim2.new(1, -35, 0.5, -14)
        CloseBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
        CloseBtn.BorderSizePixel = 0
        CloseBtn.Text = "×"
        CloseBtn.TextColor3 = Color3.fromRGB(220, 220, 225)
        CloseBtn.TextSize = 20
        CloseBtn.Font = Enum.Font.GothamBold
        CloseBtn.Parent = Header

        local CCorner = Instance.new("UICorner")
        CCorner.CornerRadius = UDim.new(0, 4)
        CCorner.Parent = CloseBtn

        CloseBtn.MouseButton1Click:Connect(function()
            GUI:Toggle()
        end)

        -- Columns Grid
        local ColumnsContainer = Instance.new("Frame")
        ColumnsContainer.Size = UDim2.new(1, -20, 1, -55)
        ColumnsContainer.Position = UDim2.new(0, 10, 0, 48)
        ColumnsContainer.BackgroundTransparency = 1
        ColumnsContainer.Parent = Container

        local ColLayout = Instance.new("UIGridLayout")
        ColLayout.CellSize = UDim2.new(0, 168, 1, 0)
        ColLayout.CellPadding = UDim2.new(0, 8, 0, 0)
        ColLayout.Parent = ColumnsContainer

        local categories = {"Combat", "Movement", "Visuals", "Misc"}
        for _, cat in ipairs(categories) do
            local Col = Instance.new("Frame")
            Col.Name = cat .. "Col"
            Col.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
            Col.BorderSizePixel = 0
            Col.Parent = ColumnsContainer

            local ColCorner = Instance.new("UICorner")
            ColCorner.CornerRadius = UDim.new(0, 6)
            ColCorner.Parent = Col

            local CatHeader = Instance.new("TextLabel")
            CatHeader.Size = UDim2.new(1, 0, 0, 30)
            CatHeader.BackgroundColor3 = Color3.fromRGB(26, 26, 34)
            CatHeader.Text = cat:upper()
            CatHeader.TextColor3 = AccentColor
            CatHeader.TextSize = 12
            CatHeader.Font = Enum.Font.GothamBold
            CatHeader.Parent = Col

            local CHCorner = Instance.new("UICorner")
            CHCorner.CornerRadius = UDim.new(0, 6)
            CHCorner.Parent = CatHeader

            local ColScroll = Instance.new("ScrollingFrame")
            ColScroll.Size = UDim2.new(1, -10, 1, -38)
            ColScroll.Position = UDim2.new(0, 5, 0, 34)
            ColScroll.BackgroundTransparency = 1
            ColScroll.BorderSizePixel = 0
            ColScroll.ScrollBarThickness = 2
            ColScroll.ScrollBarImageColor3 = AccentColor
            ColScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
            ColScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
            ColScroll.Parent = Col

            local SLayout = Instance.new("UIListLayout")
            SLayout.Padding = UDim.new(0, 6)
            SLayout.SortOrder = Enum.SortOrder.LayoutOrder
            SLayout.Parent = ColScroll

            GUI.PopulateTab(ColScroll, cat)
        end

        -- Dragging
        local dragging, dragInput, mousePos, framePos
        Header.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                mousePos = input.Position
                framePos = Container.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)
        Header.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                dragInput = input
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if input == dragInput and dragging then
                local delta = input.Position - mousePos
                Container.Position = UDim2.new(
                    framePos.X.Scale, framePos.X.Offset + delta.X,
                    framePos.Y.Scale, framePos.Y.Offset + delta.Y
                )
            end
        end)
    end
echo
cat >> src/modules/unstablesmp.lua << 'LUAEOF'

    -- ========================================================================
    -- TAB CONTENT POPULATOR
    -- ========================================================================
    function GUI.PopulateTab(contentFrame, tabName)
        for _, child in pairs(contentFrame:GetChildren()) do
            if not child:IsA("UIListLayout") then
                child:Destroy()
            end
        end

        if tabName == "Combat" then
            local auraToggle = GUI.CreateToggle("KillAura", Combat.KillAura.Enabled, function(s)
                Combat:ToggleKillAura(s)
            end)
            auraToggle.LayoutOrder = 1
            auraToggle.Parent = contentFrame

            local rangeSlider = GUI.CreateSlider("Range (Studs)", Combat.KillAura.Settings.Range, 5, 35, function(v)
                Combat:SetSetting("Range", v)
            end)
            rangeSlider.LayoutOrder = 2
            rangeSlider.Parent = contentFrame

            local delaySlider = GUI.CreateSlider("Attack Delay (ms)", Combat.KillAura.Settings.AttackDelay * 1000, 50, 400, function(v)
                Combat:SetSetting("AttackDelay", v / 1000)
            end)
            delaySlider.LayoutOrder = 3
            delaySlider.Parent = contentFrame

            local rotSpeedSlider = GUI.CreateSlider("Rotation Speed", Combat.KillAura.Settings.RotationSpeed, 1, 20, function(v)
                Combat:SetSetting("RotationSpeed", v)
            end)
            rotSpeedSlider.LayoutOrder = 4
            rotSpeedSlider.Parent = contentFrame

            local modeBtn = GUI.CreateButton("Target Mode: " .. Combat.KillAura.Settings.TargetMode, function(btn)
                if Combat.KillAura.Settings.TargetMode == "Closest" then
                    Combat.KillAura.Settings.TargetMode = "Health"
                else
                    Combat.KillAura.Settings.TargetMode = "Closest"
                end
                btn.Text = "Target Mode: " .. Combat.KillAura.Settings.TargetMode
                NotificationSystem.Notify("Combat", "Mode: " .. Combat.KillAura.Settings.TargetMode, 1.5)
            end)
            modeBtn.LayoutOrder = 5
            modeBtn.Parent = contentFrame

            local hitboxToggle = GUI.CreateToggle("Hitbox Expander", Combat.HitboxExpander.Enabled, function(s)
                Combat:ToggleHitboxExpander(s)
            end)
            hitboxToggle.LayoutOrder = 6
            hitboxToggle.Parent = contentFrame

            local hitboxSlider = GUI.CreateSlider("Hitbox Size", Combat.HitboxExpander.Size, 4, 25, function(v)
                Combat.HitboxExpander.Size = v
            end)
            hitboxSlider.LayoutOrder = 7
            hitboxSlider.Parent = contentFrame

            local clickerToggle = GUI.CreateToggle("Auto Clicker", Combat.AutoClicker.Enabled, function(s)
                Combat:ToggleAutoClicker(s)
            end)
            clickerToggle.LayoutOrder = 8
            clickerToggle.Parent = contentFrame

            local silentToggle = GUI.CreateToggle("Silent Aura (No Camera Rotation)", Combat.KillAura.Settings.SilentAura, function(s)
                Combat:SetSetting("SilentAura", s)
                NotificationSystem.Notify("Combat", "Silent Aura: " .. (s and "ON" or "OFF"), 1.5)
            end)
            silentToggle.LayoutOrder = 9
            silentToggle.Parent = contentFrame

            local targetTypeBtn = GUI.CreateButton("Target Type: " .. Combat.KillAura.Settings.TargetType, function(btn)
                local types = {"All", "PlayersOnly", "DummiesOnly"}
                local currentIdx = 1
                for i, t in ipairs(types) do
                    if t == Combat.KillAura.Settings.TargetType then
                        currentIdx = i
                        break
                    end
                end
                local nextIdx = (currentIdx % #types) + 1
                Combat.KillAura.Settings.TargetType = types[nextIdx]
                btn.Text = "Target Type: " .. types[nextIdx]
                NotificationSystem.Notify("Combat", "Targeting: " .. types[nextIdx], 1.5)
            end)
            targetTypeBtn.LayoutOrder = 10
            targetTypeBtn.Parent = contentFrame

        elseif tabName == "Movement" then
            local speedToggle = GUI.CreateToggle("Speed", Movement.Speed.Enabled, function(s)
                Movement:ToggleSpeed(s)
            end)
            speedToggle.LayoutOrder = 1
            speedToggle.Parent = contentFrame

            local speedSlider = GUI.CreateSlider("Speed Factor", Movement.Speed.Value, 16, 120, function(v)
                Movement:SetSpeed(v)
            end)
            speedSlider.LayoutOrder = 2
            speedSlider.Parent = contentFrame

            local flyToggle = GUI.CreateToggle("Fly (WASD + Space/Shift)", Movement.Fly.Enabled, function(s)
                Movement:ToggleFly(s)
            end)
            flyToggle.LayoutOrder = 3
            flyToggle.Parent = contentFrame

            local flySlider = GUI.CreateSlider("Fly Speed", Movement.Fly.Speed, 15, 120, function(v)
                Movement.Fly.Speed = v
            end)
            flySlider.LayoutOrder = 4
            flySlider.Parent = contentFrame

            local noclipToggle = GUI.CreateToggle("NoClip", Movement.NoClip.Enabled, function(s)
                Movement:ToggleNoClip(s)
            end)
            noclipToggle.LayoutOrder = 5
            noclipToggle.Parent = contentFrame

            local infJumpToggle = GUI.CreateToggle("Infinite Jump", Movement.InfiniteJump.Enabled, function(s)
                Movement:ToggleInfiniteJump(s)
            end)
            infJumpToggle.LayoutOrder = 6
            infJumpToggle.Parent = contentFrame

            local highJumpToggle = GUI.CreateToggle("High Jump", Movement.HighJump.Enabled, function(s)
                Movement:ToggleHighJump(s)
            end)
            highJumpToggle.LayoutOrder = 7
            highJumpToggle.Parent = contentFrame

            local bhopToggle = GUI.CreateToggle("BunnyHop (Auto Jump)", Movement.BunnyHop.Enabled, function(s)
                Movement:ToggleBunnyHop(s)
            end)
            bhopToggle.LayoutOrder = 8
            bhopToggle.Parent = contentFrame

        elseif tabName == "Visuals" then
            local chamsToggle = GUI.CreateToggle("Player Chams (Highlight)", Visuals.Chams.Enabled, function(s)
                Visuals:ToggleChams(s)
            end)
            chamsToggle.LayoutOrder = 1
            chamsToggle.Parent = contentFrame

            local espToggle = GUI.CreateToggle("Name & Distance ESP", Visuals.NameESP.Enabled, function(s)
                Visuals:ToggleNameESP(s)
            end)
            espToggle.LayoutOrder = 2
            espToggle.Parent = contentFrame

            local fullbrightToggle = GUI.CreateToggle("Fullbright", Visuals.Fullbright.Enabled, function(s)
                Visuals:ToggleFullbright(s)
            end)
            fullbrightToggle.LayoutOrder = 3
            fullbrightToggle.Parent = contentFrame

            local fovToggle = GUI.CreateToggle("Custom FOV", Visuals.FOV.Enabled, function(s)
                Visuals:ToggleFOV(s)
            end)
            fovToggle.LayoutOrder = 4
            fovToggle.Parent = contentFrame

            local fovSlider = GUI.CreateSlider("Camera FOV", Visuals.FOV.Value, 70, 120, function(v)
                Visuals:SetFOV(v)
            end)
            fovSlider.LayoutOrder = 5
            fovSlider.Parent = contentFrame

        elseif tabName == "Misc" then
            local teamToggle = GUI.CreateToggle("Team Check", Combat.KillAura.Settings.TeamCheck, function(s)
                Combat:SetSetting("TeamCheck", s)
                NotificationSystem.Notify("Misc", "Team Check: " .. (s and "ON" or "OFF"), 1.5)
            end)
            teamToggle.LayoutOrder = 1
            teamToggle.Parent = contentFrame

            local visToggle = GUI.CreateToggle("Visibility Check", Combat.KillAura.Settings.VisibleCheck, function(s)
                Combat:SetSetting("VisibleCheck", s)
                NotificationSystem.Notify("Misc", "Visibility Check: " .. (s and "ON" or "OFF"), 1.5)
            end)
            visToggle.LayoutOrder = 2
            visToggle.Parent = contentFrame

            local smoothToggle = GUI.CreateToggle("Smooth Camera Lock", Combat.KillAura.Settings.SmoothLock, function(s)
                Combat:SetSetting("SmoothLock", s)
            end)
            smoothToggle.LayoutOrder = 3
            smoothToggle.Parent = contentFrame

            local antiAFKToggle = GUI.CreateToggle("Anti-AFK (No Disconnect)", Misc.AntiAFK.Enabled, function(s)
                Misc:ToggleAntiAFK(s)
            end)
            antiAFKToggle.LayoutOrder = 4
            antiAFKToggle.Parent = contentFrame

            local fpsToggle = GUI.CreateToggle("FPS Booster / Low Quality", Misc.FPSBooster.Enabled, function(s)
                Misc:ToggleFPSBooster(s)
            end)
            fpsToggle.LayoutOrder = 5
            fpsToggle.Parent = contentFrame

            local rejoinBtn = GUI.CreateButton("Rejoin Server", function()
                Misc:Rejoin()
            end)
            rejoinBtn.LayoutOrder = 6
            rejoinBtn.Parent = contentFrame

            local hopBtn = GUI.CreateButton("Server Hop", function()
                Misc:ServerHop()
            end)
            hopBtn.LayoutOrder = 7
            hopBtn.Parent = contentFrame

            local unloadBtn = GUI.CreateButton("⚠️ Self Destruct / Clean Unload", function()
                getgenv().DemiseUnload()
            end)
            unloadBtn.BackgroundColor3 = Color3.fromRGB(60, 25, 30)
            unloadBtn.LayoutOrder = 8
            unloadBtn.Parent = contentFrame

        elseif tabName == "Player" then
            local header1 = Instance.new("TextLabel")
            header1.Size = UDim2.new(1, 0, 0, 24)
            header1.BackgroundTransparency = 1
            header1.Text = "Player Modifications"
            header1.TextColor3 = AccentColor
            header1.TextSize = 14
            header1.Font = Enum.Font.GothamBold
            header1.TextXAlignment = Enum.TextXAlignment.Left
            header1.LayoutOrder = 1
            header1.Parent = contentFrame

            local comingSoonLabel1 = Instance.new("TextLabel")
            comingSoonLabel1.Size = UDim2.new(1, 0, 0, 100)
            comingSoonLabel1.BackgroundTransparency = 1
            comingSoonLabel1.Text = "Coming Soon:\n• No Fall Damage\n• Auto Jump\n• Anti Knockback\n• Fast Interact"
            comingSoonLabel1.TextColor3 = Color3.fromRGB(150, 150, 150)
            comingSoonLabel1.TextSize = 13
            comingSoonLabel1.Font = Enum.Font.Gotham
            comingSoonLabel1.TextXAlignment = Enum.TextXAlignment.Left
            comingSoonLabel1.TextYAlignment = Enum.TextYAlignment.Top
            comingSoonLabel1.LayoutOrder = 2
            comingSoonLabel1.Parent = contentFrame

        elseif tabName == "World" then
            local header1 = Instance.new("TextLabel")
            header1.Size = UDim2.new(1, 0, 0, 24)
            header1.BackgroundTransparency = 1
            header1.Text = "World Interactions"
            header1.TextColor3 = AccentColor
            header1.TextSize = 14
            header1.Font = Enum.Font.GothamBold
            header1.TextXAlignment = Enum.TextXAlignment.Left
            header1.LayoutOrder = 1
            header1.Parent = contentFrame

            local comingSoonLabel1 = Instance.new("TextLabel")
            comingSoonLabel1.Size = UDim2.new(1, 0, 0, 120)
            comingSoonLabel1.BackgroundTransparency = 1
            comingSoonLabel1.Text = "Coming Soon:\n• Scaffold\n• Auto Mine\n• Nuker\n• Time Changer\n• Weather Control"
            comingSoonLabel1.TextColor3 = Color3.fromRGB(150, 150, 150)
            comingSoonLabel1.TextSize = 13
            comingSoonLabel1.Font = Enum.Font.Gotham
            comingSoonLabel1.TextXAlignment = Enum.TextXAlignment.Left
            comingSoonLabel1.TextYAlignment = Enum.TextYAlignment.Top
            comingSoonLabel1.LayoutOrder = 2
            comingSoonLabel1.Parent = contentFrame

        elseif tabName == "Render" then
            local header1 = Instance.new("TextLabel")
            header1.Size = UDim2.new(1, 0, 0, 24)
            header1.BackgroundTransparency = 1
            header1.Text = "Render & Visuals"
            header1.TextColor3 = AccentColor
            header1.TextSize = 14
            header1.Font = Enum.Font.GothamBold
            header1.TextXAlignment = Enum.TextXAlignment.Left
            header1.LayoutOrder = 1
            header1.Parent = contentFrame

            -- Re-use Visuals content
            local chamsToggle = GUI.CreateToggle("Player Chams (Highlight)", Visuals.Chams.Enabled, function(s)
                Visuals:ToggleChams(s)
            end)
            chamsToggle.LayoutOrder = 2
            chamsToggle.Parent = contentFrame

            local espToggle = GUI.CreateToggle("Name & Distance ESP", Visuals.NameESP.Enabled, function(s)
                Visuals:ToggleNameESP(s)
            end)
            espToggle.LayoutOrder = 3
            espToggle.Parent = contentFrame

            local fullbrightToggle = GUI.CreateToggle("Fullbright", Visuals.Fullbright.Enabled, function(s)
                Visuals:ToggleFullbright(s)
            end)
            fullbrightToggle.LayoutOrder = 4
            fullbrightToggle.Parent = contentFrame

            local fovToggle = GUI.CreateToggle("Custom FOV", Visuals.FOV.Enabled, function(s)
                Visuals:ToggleFOV(s)
            end)
            fovToggle.LayoutOrder = 5
            fovToggle.Parent = contentFrame

            local fovSlider = GUI.CreateSlider("Camera FOV", Visuals.FOV.Value, 70, 120, function(v)
                Visuals:SetFOV(v)
            end)
            fovSlider.LayoutOrder = 6
            fovSlider.Parent = contentFrame

        elseif tabName == "Utility" then
            local header1 = Instance.new("TextLabel")
            header1.Size = UDim2.new(1, 0, 0, 24)
            header1.BackgroundTransparency = 1
            header1.Text = "Automation & Helpers"
            header1.TextColor3 = AccentColor
            header1.TextSize = 14
            header1.Font = Enum.Font.GothamBold
            header1.TextXAlignment = Enum.TextXAlignment.Left
            header1.LayoutOrder = 1
            header1.Parent = contentFrame

            local comingSoonLabel1 = Instance.new("TextLabel")
            comingSoonLabel1.Size = UDim2.new(1, 0, 0, 120)
            comingSoonLabel1.BackgroundTransparency = 1
            comingSoonLabel1.Text = "Coming Soon:\n• Auto Farm\n• Auto Collect\n• Auto Respawn\n• Inventory Manager\n• Chat Commands"
            comingSoonLabel1.TextColor3 = Color3.fromRGB(150, 150, 150)
            comingSoonLabel1.TextSize = 13
            comingSoonLabel1.Font = Enum.Font.Gotham
            comingSoonLabel1.TextXAlignment = Enum.TextXAlignment.Left
            comingSoonLabel1.TextYAlignment = Enum.TextYAlignment.Top
            comingSoonLabel1.LayoutOrder = 2
            comingSoonLabel1.Parent = contentFrame

        elseif tabName == "Config" then
            local header1 = Instance.new("TextLabel")
            header1.Size = UDim2.new(1, 0, 0, 24)
            header1.BackgroundTransparency = 1
            header1.Text = "Configuration Management"
            header1.TextColor3 = AccentColor
            header1.TextSize = 14
            header1.Font = Enum.Font.GothamBold
            header1.TextXAlignment = Enum.TextXAlignment.Left
            header1.LayoutOrder = 1
            header1.Parent = contentFrame

            local saveBtn = GUI.CreateButton("💾 Save Current Config", function()
                NotificationSystem.Notify("Config", "Saved current settings!", 2)
            end)
            saveBtn.LayoutOrder = 2
            saveBtn.Parent = contentFrame

            local loadBtn = GUI.CreateButton("📂 Load Saved Config", function()
                NotificationSystem.Notify("Config", "Loaded config!", 2)
            end)
            loadBtn.LayoutOrder = 3
            loadBtn.Parent = contentFrame

            local resetBtn = GUI.CreateButton("🔄 Reset to Defaults", function()
                NotificationSystem.Notify("Config", "Reset to defaults!", 2)
            end)
            resetBtn.LayoutOrder = 4
            resetBtn.Parent = contentFrame

            local header2 = Instance.new("TextLabel")
            header2.Size = UDim2.new(1, 0, 0, 24)
            header2.BackgroundTransparency = 1
            header2.Text = "Presets"
            header2.TextColor3 = AccentColor
            header2.TextSize = 14
            header2.Font = Enum.Font.GothamBold
            header2.TextXAlignment = Enum.TextXAlignment.Left
            header2.LayoutOrder = 5
            header2.Parent = contentFrame

            local legitBtn = GUI.CreateButton("🎯 Legit Mode (Recommended)", function()
                NotificationSystem.Notify("Config", "Loaded Legit preset!", 2)
            end)
            legitBtn.LayoutOrder = 6
            legitBtn.Parent = contentFrame

            local rageBtn = GUI.CreateButton("⚡ Rage Mode (Obvious)", function()
                NotificationSystem.Notify("Config", "Loaded Rage preset!", 2)
            end)
            rageBtn.LayoutOrder = 7
            rageBtn.Parent = contentFrame

            local hvhBtn = GUI.CreateButton("👑 HvH Mode (PvP)", function()
                NotificationSystem.Notify("Config", "Loaded HvH preset!", 2)
            end)
            hvhBtn.LayoutOrder = 8
            hvhBtn.Parent = contentFrame

            local infoLabel = Instance.new("TextLabel")
            infoLabel.Size = UDim2.new(1, 0, 0, 60)
            infoLabel.BackgroundTransparency = 1
            infoLabel.Text = "Note: Config save/load coming soon!\nPresets will adjust settings automatically."
            infoLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
            infoLabel.TextSize = 11
            infoLabel.Font = Enum.Font.Gotham
            infoLabel.TextXAlignment = Enum.TextXAlignment.Left
            infoLabel.TextWrapped = true
            infoLabel.LayoutOrder = 9
            infoLabel.Parent = contentFrame

        elseif tabName == "Settings" then
            local header = Instance.new("TextLabel")
            header.Size = UDim2.new(1, 0, 0, 24)
            header.BackgroundTransparency = 1
            header.Text = "Accent Color & Theming"
            header.TextColor3 = AccentColor
            header.TextSize = 14
            header.Font = Enum.Font.GothamBold
            header.TextXAlignment = Enum.TextXAlignment.Left
            header.LayoutOrder = 1
            header.Parent = contentFrame

            local themeBtn = GUI.CreateButton("Current Theme: " .. ActiveThemeName, function(btn)
                local themeKeys = {"Rise Green", "Demise Purple", "Cyber Cyan", "Crimson Red"}
                local nextIdx = 1
                for i, k in ipairs(themeKeys) do
                    if k == ActiveThemeName then
                        nextIdx = (i % #themeKeys) + 1
                        break
                    end
                end
                ActiveThemeName = themeKeys[nextIdx]
                AccentColor = Themes[ActiveThemeName]
                btn.Text = "Current Theme: " .. ActiveThemeName
                NotificationSystem.Notify("Theme Changed", ActiveThemeName, 2, AccentColor)
                GUI:Toggle()
                GUI:Toggle()
                GUI.CreateWatermark()
            end)
            themeBtn.LayoutOrder = 2
            themeBtn.Parent = contentFrame

            local bindHeader = Instance.new("TextLabel")
            bindHeader.Size = UDim2.new(1, 0, 0, 24)
            bindHeader.BackgroundTransparency = 1
            bindHeader.Text = "Keybinds"
            bindHeader.TextColor3 = AccentColor
            bindHeader.TextSize = 14
            bindHeader.Font = Enum.Font.GothamBold
            bindHeader.TextXAlignment = Enum.TextXAlignment.Left
            bindHeader.LayoutOrder = 3
            bindHeader.Parent = contentFrame

            local guiKeybind = GUI.CreateKeybind("Open/Close GUI Key", GUI.OpenKey, function(k)
                GUI.OpenKey = k
                NotificationSystem.Notify("Keybind", "GUI Key: " .. k.Name, 2)
            end)
            guiKeybind.LayoutOrder = 4
            guiKeybind.Parent = contentFrame

            local modeHeader = Instance.new("TextLabel")
            modeHeader.Size = UDim2.new(1, 0, 0, 24)
            modeHeader.BackgroundTransparency = 1
            modeHeader.Text = "Interface Layout"
            modeHeader.TextColor3 = AccentColor
            modeHeader.TextSize = 14
            modeHeader.Font = Enum.Font.GothamBold
            modeHeader.TextXAlignment = Enum.TextXAlignment.Left
            modeHeader.LayoutOrder = 5
            modeHeader.Parent = contentFrame

            local modeSwitchBtn = GUI.CreateButton("Switch to " .. (GUI.Mode == "Rise" and "Vape" or "Rise") .. " Mode", function()
                GUI.Mode = (GUI.Mode == "Rise") and "Vape" or "Rise"
                GUI:Toggle()
                GUI:Toggle()
            end)
            modeSwitchBtn.LayoutOrder = 6
            modeSwitchBtn.Parent = contentFrame
        end
    end
echo
cat >> src/modules/unstablesmp.lua << 'LUAEOF'

    -- ========================================================================
    -- UI ELEMENT BUILDERS (Toggle, Slider, Keybind, Button)
    -- ========================================================================
    function GUI.CreateToggle(name, initialState, callback)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 0, 36)
        frame.BackgroundColor3 = Color3.fromRGB(26, 26, 33)
        frame.BorderSizePixel = 0

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 5)
        corner.Parent = frame

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -60, 1, 0)
        label.Position = UDim2.new(0, 12, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = name
        label.TextColor3 = Color3.fromRGB(235, 235, 240)
        label.TextSize = 13
        label.Font = Enum.Font.Gotham
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = frame

        local toggleBtn = Instance.new("TextButton")
        toggleBtn.Size = UDim2.new(0, 42, 0, 22)
        toggleBtn.Position = UDim2.new(1, -50, 0.5, -11)
        toggleBtn.BackgroundColor3 = initialState and AccentColor or Color3.fromRGB(50, 50, 60)
        toggleBtn.BorderSizePixel = 0
        toggleBtn.Text = ""
        toggleBtn.Parent = frame

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(1, 0)
        btnCorner.Parent = toggleBtn

        local pill = Instance.new("Frame")
        pill.Size = UDim2.new(0, 16, 0, 16)
        pill.Position = initialState and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
        pill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        pill.BorderSizePixel = 0
        pill.Parent = toggleBtn

        local pillCorner = Instance.new("UICorner")
        pillCorner.CornerRadius = UDim.new(1, 0)
        pillCorner.Parent = pill

        local enabled = initialState
        toggleBtn.MouseButton1Click:Connect(function()
            enabled = not enabled
            local tInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad)
            TweenService:Create(toggleBtn, tInfo, {
                BackgroundColor3 = enabled and AccentColor or Color3.fromRGB(50, 50, 60)
            }):Play()
            TweenService:Create(pill, tInfo, {
                Position = enabled and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
            }):Play()

            if callback then callback(enabled) end
        end)

        return frame
    end

    function GUI.CreateSlider(name, initialValue, min, max, callback)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 0, 48)
        frame.BackgroundColor3 = Color3.fromRGB(26, 26, 33)
        frame.BorderSizePixel = 0

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 5)
        corner.Parent = frame

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0.65, 0, 0, 22)
        label.Position = UDim2.new(0, 12, 0, 5)
        label.BackgroundTransparency = 1
        label.Text = name
        label.TextColor3 = Color3.fromRGB(235, 235, 240)
        label.TextSize = 13
        label.Font = Enum.Font.Gotham
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = frame

        local valLabel = Instance.new("TextLabel")
        valLabel.Size = UDim2.new(0.3, 0, 0, 22)
        valLabel.Position = UDim2.new(0.7, -12, 0, 5)
        valLabel.BackgroundTransparency = 1
        valLabel.Text = tostring(math.floor(initialValue))
        valLabel.TextColor3 = AccentColor
        valLabel.TextSize = 12
        valLabel.Font = Enum.Font.GothamBold
        valLabel.TextXAlignment = Enum.TextXAlignment.Right
        valLabel.Parent = frame

        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(1, -24, 0, 5)
        bar.Position = UDim2.new(0, 12, 1, -14)
        bar.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
        bar.BorderSizePixel = 0
        bar.Parent = frame

        local barCorner = Instance.new("UICorner")
        barCorner.CornerRadius = UDim.new(1, 0)
        barCorner.Parent = bar

        local fill = Instance.new("Frame")
        local startRatio = math.clamp((initialValue - min) / (max - min), 0, 1)
        fill.Size = UDim2.new(startRatio, 0, 1, 0)
        fill.BackgroundColor3 = AccentColor
        fill.BorderSizePixel = 0
        fill.Parent = bar

        local fillCorner = Instance.new("UICorner")
        fillCorner.CornerRadius = UDim.new(1, 0)
        fillCorner.Parent = fill

        local dragging = false
        bar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                local mouseX = input.Position.X
                local barX = bar.AbsolutePosition.X
                local barW = bar.AbsoluteSize.X
                local rel = math.clamp((mouseX - barX) / barW, 0, 1)
                local val = math.floor(min + (max - min) * rel)
                fill.Size = UDim2.new(rel, 0, 1, 0)
                valLabel.Text = tostring(val)
                if callback then callback(val) end
            end
        end)

        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local mouseX = input.Position.X
                local barX = bar.AbsolutePosition.X
                local barW = bar.AbsoluteSize.X
                local rel = math.clamp((mouseX - barX) / barW, 0, 1)
                local val = math.floor(min + (max - min) * rel)
                fill.Size = UDim2.new(rel, 0, 1, 0)
                valLabel.Text = tostring(val)
                if callback then callback(val) end
            end
        end)

        return frame
    end

    function GUI.CreateButton(text, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 34)
        btn.BackgroundColor3 = Color3.fromRGB(32, 32, 40)
        btn.BorderSizePixel = 0
        btn.Text = text
        btn.TextColor3 = Color3.fromRGB(240, 240, 245)
        btn.TextSize = 13
        btn.Font = Enum.Font.Gotham
        btn.AutoButtonColor = false

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 5)
        corner.Parent = btn

        btn.MouseButton1Click:Connect(function()
            if callback then callback(btn) end
        end)

        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.2), { BackgroundColor3 = Color3.fromRGB(44, 44, 55) }):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.2), { BackgroundColor3 = Color3.fromRGB(32, 32, 40) }):Play()
        end)

        return btn
    end

    function GUI.CreateKeybind(name, currentKey, callback)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 0, 36)
        frame.BackgroundColor3 = Color3.fromRGB(26, 26, 33)
        frame.BorderSizePixel = 0

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 5)
        corner.Parent = frame

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0.6, 0, 1, 0)
        label.Position = UDim2.new(0, 12, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = name
        label.TextColor3 = Color3.fromRGB(235, 235, 240)
        label.TextSize = 13
        label.Font = Enum.Font.Gotham
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = frame

        local keyBtn = Instance.new("TextButton")
        keyBtn.Size = UDim2.new(0, 100, 0, 24)
        keyBtn.Position = UDim2.new(1, -110, 0.5, -12)
        keyBtn.BackgroundColor3 = Color3.fromRGB(38, 38, 48)
        keyBtn.BorderSizePixel = 0
        keyBtn.Text = currentKey.Name
        keyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        keyBtn.TextSize = 12
        keyBtn.Font = Enum.Font.GothamBold
        keyBtn.Parent = frame

        local keyCorner = Instance.new("UICorner")
        keyCorner.CornerRadius = UDim.new(0, 4)
        keyCorner.Parent = keyBtn

        local listening = false
        keyBtn.MouseButton1Click:Connect(function()
            if listening then return end
            listening = true
            keyBtn.Text = "..."
            keyBtn.BackgroundColor3 = AccentColor

            local conn
            conn = UserInputService.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Keyboard then
                    conn:Disconnect()
                    listening = false
                    keyBtn.Text = input.KeyCode.Name
                    keyBtn.BackgroundColor3 = Color3.fromRGB(38, 38, 48)
                    if callback then callback(input.KeyCode) end
                end
            end)
        end)

        return frame
    end

    function GUI:Toggle()
        self.Visible = not self.Visible
        if self.ScreenGui then
            self.ScreenGui:Destroy()
            self.ScreenGui = nil
        end
        if self.Visible then
            self.ScreenGui = self.Create()
        end
    end

    return GUI
end)()
echo
cat >> src/modules/unstablesmp.lua << 'LUAEOF'

-- ============================================================================
-- 9. HOTKEYS & GLOBAL CONTROLS
-- ============================================================================
local InputConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == ClickGUI.OpenKey then
        ClickGUI:Toggle()
    elseif input.KeyCode == Enum.KeyCode.K then
        Combat:ToggleKillAura()
    elseif input.KeyCode == Enum.KeyCode.X then
        Movement:ToggleFly()
    end
end)
RegisterConnection(InputConn)

-- ============================================================================
-- 10. UNLOAD / SELF DESTRUCT
-- ============================================================================
getgenv().DemiseUnload = function()
    print("[Demise] Cleaning up client...")

    -- Disconnect all recorded connections
    for _, conn in ipairs(Cleanups.Connections) do
        if conn and typeof(conn) == "RBXScriptConnection" then
            pcall(function() conn:Disconnect() end)
        end
    end

    -- Destroy all registered UI instances
    for _, inst in ipairs(Cleanups.Instances) do
        if inst and typeof(inst) == "Instance" then
            pcall(function() inst:Destroy() end)
        end
    end

    -- Restore states
    Movement:ToggleFly(false)
    Movement:ToggleSpeed(false)
    Movement:ToggleHighJump(false)
    Movement:ToggleNoClip(false)
    Movement:ToggleInfiniteJump(false)
    Movement:ToggleBunnyHop(false)
    Visuals:ToggleChams(false)
    Visuals:ToggleNameESP(false)
    Visuals:ToggleFullbright(false)
    Visuals:ToggleFOV(false)
    Combat:ToggleKillAura(false)
    Combat:ToggleHitboxExpander(false)
    Combat:ToggleAutoClicker(false)

    if getgenv then
        getgenv().DemiseLoaded = false
        getgenv().DemiseUnload = nil
    end

    print("[Demise] Client completely unloaded.")
end

-- ============================================================================
-- 11. STARTUP SEQUENCE
-- ============================================================================
LoaderUI.Show(2.5, function()
    ClickGUI.CreateWatermark()
    NotificationSystem.Notify("Demise Client v2.0", "Press RIGHT SHIFT to open GUI", 3.5)
    print([[
╔══════════════════════════════════════════════════════════════════════╗
║                    DEMISE CLIENT v2.0 LOADED ✓                       ║
╚══════════════════════════════════════════════════════════════════════╝
    [RIGHT CTRL]    Open / Close GUI
    [K]             Quick Toggle KillAura
    [X]             Quick Toggle Fly
    
    NEW FEATURES:
    ✅ Silent Aura - Attack without camera rotation
    ✅ Improved ESP - Shows HP numbers, distance, health bars
    ✅ Custom Model Support - Works with any character rig
]])
end)
