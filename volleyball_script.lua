local repoUrl = "https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/"
local Library = loadstring(game:HttpGet(repoUrl .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repoUrl .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repoUrl .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

local window = Library:CreateWindow({
    Title = "Plow's\nPrivate Script",
    Footer = "v1.2.2",
    NotifySide = "Right",
    ShowCustomCursor = true,
})

local homeTab = window:AddTab("Home", "house")
local homeStatusGroup = homeTab:AddLeftGroupbox("Status")

local localPlayer = game.Players.LocalPlayer
local displayName = localPlayer and localPlayer.DisplayName or "Player"
local currentTime = os.date("%H:%M:%S")
local welcomeText = string.format(
    "Welcome, %s\nCurrent time: %s\nYou are currently in a game that Plow's script doesn't support.",
    displayName,
    currentTime
)

homeStatusGroup:AddLabel(welcomeText, true)

homeStatusGroup:AddButton({
    Text = "Unload",
    Func = function()
        Library:Unload()
    end
})

local statsGroup = homeTab:AddRightGroupbox("FPS & Ping display")

local fpsLabel = statsGroup:AddLabel("FPS: calculating...", true)
local pingLabel = statsGroup:AddLabel("Ping: calculating...", true)

local runService = game:GetService("RunService")
local statsService = game:GetService("Stats")
local userInputService = game:GetService("UserInputService")
local playersService = game:GetService("Players")
local lightingService = game:GetService("Lighting")

local elapsedTime = 0
local frameCounter = 0
local fpsConnection

fpsConnection = runService.RenderStepped:Connect(function(deltaTime)
    frameCounter = frameCounter + 1
    elapsedTime = elapsedTime + deltaTime

    if elapsedTime >= 1 then
        local fps = math.floor(frameCounter / elapsedTime + 0.5)
        fpsLabel:SetText("FPS: " .. tostring(fps))

        local networkStats = statsService.Network.ServerStatsItem["Data Ping"]
        local ping = networkStats and math.floor(networkStats:GetValue()) or 0
        pingLabel:SetText("Ping: " .. tostring(ping) .. " ms")

        frameCounter = 0
        elapsedTime = 0
    end
end)

local localPlayerTab = window:AddTab("Local Player", "user")

local modifiersGroup = localPlayerTab:AddLeftGroupbox("Modifiers")
local visualsGroup = localPlayerTab:AddLeftGroupbox("Visuals")
local keybindsGroup = localPlayerTab:AddRightGroupbox("Keybinds")

local defaultWalkspeed = 16
local selectedWalkspeed = defaultWalkspeed
local defaultJumppower = 50
local selectedJumppower = defaultJumppower

local defaultFlySpeed = 50
local selectedFlySpeed = defaultFlySpeed

local walkspeedConnection
local jumppowerConnection
local flyConnection
local noclipConnection
local espConnection
local originalGravity = workspace.Gravity

local espHighlights = {}
local espColor = Color3.new(1, 1, 1)

local savedCollisionStates = {}

local originalLighting = {
    ClockTime = lightingService.ClockTime,
    FogEnd = lightingService.FogEnd,
    FogStart = lightingService.FogStart
}

local function getLocalCharacter()
    local character = localPlayer.Character
    if not character then
        character = localPlayer.CharacterAdded:Wait()
    end
    return character
end

local function getLocalHumanoid()
    local character = getLocalCharacter()
    return character:FindFirstChildOfClass("Humanoid")
end

local function getCameraRelativeMoveDirection()
    local camera = workspace.CurrentCamera
    if not camera then
        return Vector3.zero
    end

    local camCF = camera.CFrame
    local look = camCF.LookVector
    local right = camCF.RightVector

    local moveVector = Vector3.zero

    if userInputService:IsKeyDown(Enum.KeyCode.W) then
        moveVector = moveVector + look
    end
    if userInputService:IsKeyDown(Enum.KeyCode.S) then
        moveVector = moveVector - look
    end
    if userInputService:IsKeyDown(Enum.KeyCode.A) then
        moveVector = moveVector - right
    end
    if userInputService:IsKeyDown(Enum.KeyCode.D) then
        moveVector = moveVector + right
    end

    if userInputService:IsKeyDown(Enum.KeyCode.Space) then
        moveVector = moveVector + Vector3.new(0, 1, 0)
    end
    if userInputService:IsKeyDown(Enum.KeyCode.LeftControl) or userInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
        moveVector = moveVector + Vector3.new(0, -1, 0)
    end

    if moveVector.Magnitude > 0 then
        return moveVector.Unit
    else
        return Vector3.zero
    end
end

local function getCameraYawCFrame()
    local camera = workspace.CurrentCamera
    if not camera then
        return CFrame.new()
    end

    local camCF = camera.CFrame
    local _, yaw, _ = camCF:ToOrientation()

    local character = getLocalCharacter()
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    local rootPos = rootPart and rootPart.Position or camCF.Position

    return CFrame.new(rootPos) * CFrame.Angles(0, yaw, 0)
end

modifiersGroup:AddToggle("EnableWalkspeed", {
    Text = "Enable Walkspeed",
    Default = false,
    Callback = function(isEnabled)
        if isEnabled then
            if walkspeedConnection then
                walkspeedConnection:Disconnect()
                walkspeedConnection = nil
            end
            walkspeedConnection = runService.Heartbeat:Connect(function()
                local humanoid = getLocalHumanoid()
                if humanoid then
                    humanoid.WalkSpeed = selectedWalkspeed
                end
            end)
        else
            if walkspeedConnection then
                walkspeedConnection:Disconnect()
                walkspeedConnection = nil
            end
            local humanoid = getLocalHumanoid()
            if humanoid then
                humanoid.WalkSpeed = defaultWalkspeed
            end
        end
    end
})

modifiersGroup:AddSlider("WalkspeedSlider", {
    Text = "Walkspeed",
    Default = defaultWalkspeed,
    Min = 16,
    Max = 100,
    Rounding = 0,
    Compact = false,
    Callback = function(value)
        selectedWalkspeed = value
    end
})

modifiersGroup:AddToggle("EnableJumppower", {
    Text = "Enable Jumppower",
    Default = false,
    Callback = function(isEnabled)
        if isEnabled then
            if jumppowerConnection then
                jumppowerConnection:Disconnect()
                jumppowerConnection = nil
            end
            jumppowerConnection = runService.Heartbeat:Connect(function()
                local humanoid = getLocalHumanoid()
                if humanoid then
                    humanoid.UseJumpPower = true
                    humanoid.JumpPower = selectedJumppower
                end
            end)
        else
            if jumppowerConnection then
                jumppowerConnection:Disconnect()
                jumppowerConnection = nil
            end
            local humanoid = getLocalHumanoid()
            if humanoid then
                humanoid.JumpPower = defaultJumppower
            end
        end
    end
})

modifiersGroup:AddSlider("JumppowerSlider", {
    Text = "Jumppower",
    Default = defaultJumppower,
    Min = 50,
    Max = 500,
    Rounding = 0,
    Compact = false,
    Callback = function(value)
        selectedJumppower = value
    end
})

modifiersGroup:AddToggle("Fly", {
    Text = "Fly",
    Default = false,
    Callback = function(isEnabled)
        local character = getLocalCharacter()
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        local humanoid = character:FindFirstChildOfClass("Humanoid")

        if isEnabled then
            if flyConnection then
                flyConnection:Disconnect()
                flyConnection = nil
            end

            workspace.Gravity = 0

            if humanoid then
                humanoid.PlatformStand = true
            end

            flyConnection = runService.Heartbeat:Connect(function()
                if not character.Parent then
                    return
                end

                humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
                humanoid = character:FindFirstChildOfClass("Humanoid")

                if humanoid and humanoidRootPart then
                    humanoidRootPart.CFrame = getCameraYawCFrame()

                    local moveDir = getCameraRelativeMoveDirection()
                    if moveDir.Magnitude > 0 then
                        humanoidRootPart.Velocity = moveDir * selectedFlySpeed
                    else
                        humanoidRootPart.Velocity = Vector3.new(0, 0, 0)
                    end
                end
            end)
        else
            if flyConnection then
                flyConnection:Disconnect()
                flyConnection = nil
            end

            workspace.Gravity = originalGravity

            if humanoid then
                humanoid.PlatformStand = false
            end
            if humanoidRootPart then
                humanoidRootPart.Velocity = Vector3.new(0, 0, 0)
            end
        end
    end
})

modifiersGroup:AddSlider("FlySpeedSlider", {
    Text = "Fly Speed",
    Default = defaultFlySpeed,
    Min = 16,
    Max = 100,
    Rounding = 0,
    Compact = false,
    Callback = function(value)
        selectedFlySpeed = value
    end
})

modifiersGroup:AddToggle("Noclip", {
    Text = "Noclip",
    Default = false,
    Callback = function(isEnabled)
        if isEnabled then
            if noclipConnection then
                noclipConnection:Disconnect()
                noclipConnection = nil
            end

            savedCollisionStates = {}

            local character = localPlayer.Character
            if character then
                for _, part in ipairs(character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        savedCollisionStates[part] = part.CanCollide
                        part.CanCollide = false
                    end
                end
            end

            noclipConnection = runService.Heartbeat:Connect(function()
                local char = localPlayer.Character
                if not char then
                    return
                end
                for part, state in pairs(savedCollisionStates) do
                    if part and part.Parent == char and part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end)
        else
            if noclipConnection then
                noclipConnection:Disconnect()
                noclipConnection = nil
            end
            local character = localPlayer.Character
            if character then
                for part, state in pairs(savedCollisionStates) do
                    if part and part.Parent == character and part:IsA("BasePart") then
                        part.CanCollide = state
                    end
                end
            end
            savedCollisionStates = {}
        end
    end
})

local function clearESP()
    for _, hl in pairs(espHighlights) do
        if hl and hl.Destroy then
            hl:Destroy()
        end
    end
    espHighlights = {}
end

local function createHighlightForPlayer(player)
    if player == localPlayer then
        return
    end

    local character = player.Character
    if not character then
        return
    end

    local highlight = Instance.new("Highlight")
    highlight.Adornee = character
    highlight.FillTransparency = 0.55
    highlight.OutlineTransparency = 0
    highlight.FillColor = espColor
    highlight.OutlineColor = espColor
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = game:GetService("CoreGui")

    espHighlights[player] = highlight
end

local function updateESPColor(newColor)
    espColor = newColor
    for _, hl in pairs(espHighlights) do
        if hl then
            hl.FillColor = espColor
            hl.OutlineColor = espColor
        end
    end
end

local function setupPlayerESP(player)
    createHighlightForPlayer(player)
end

local function startESP()
    clearESP()

    for _, player in ipairs(playersService:GetPlayers()) do
        if player ~= localPlayer then
            setupPlayerESP(player)
        end
    end

    if espConnection then
        espConnection:Disconnect()
        espConnection = nil
    end

    espConnection = playersService.PlayerAdded:Connect(function(player)
        if Toggles.ESP and Toggles.ESP.Value then
            setupPlayerESP(player)
        end
    end)

    playersService.PlayerRemoving:Connect(function(player)
        local hl = espHighlights[player]
        if hl and hl.Destroy then
            hl:Destroy()
        end
        espHighlights[player] = nil
    end)
end

local espToggle = visualsGroup:AddToggle("ESP", {
    Text = "ESP",
    Default = false,
    Callback = function(isEnabled)
        if isEnabled then
            startESP()
        else
            if espConnection then
                espConnection:Disconnect()
                espConnection = nil
            end
            clearESP()
        end
    end
})

espToggle:AddColorPicker("ESPColor", {
    Default = Color3.new(1, 1, 1),
    Title = "ESP Color",
    Callback = function(color)
        updateESPColor(color)
    end
})

visualsGroup:AddToggle("Fullbright", {
    Text = "Fullbright",
    Default = false,
    Callback = function(isEnabled)
        if isEnabled then
            originalLighting.ClockTime = lightingService.ClockTime
            originalLighting.FogEnd = lightingService.FogEnd
            originalLighting.FogStart = lightingService.FogStart

            lightingService.ClockTime = 14
            lightingService.FogEnd = 100000
            lightingService.FogStart = 0
        else
            lightingService.ClockTime = originalLighting.ClockTime
            lightingService.FogEnd = originalLighting.FogEnd
            lightingService.FogStart = originalLighting.FogStart
        end
    end
})

keybindsGroup:AddLabel("Walkspeed Toggle Keybind")
    :AddKeyPicker("WalkspeedKeybind", {
        Default = nil,
        NoUI = false,
        Text = "Toggle Walkspeed",
        Callback = function()
            if Toggles.EnableWalkspeed then
                Toggles.EnableWalkspeed:SetValue(not Toggles.EnableWalkspeed.Value)
            end
        end
    })

keybindsGroup:AddLabel("Jumppower Toggle Keybind")
    :AddKeyPicker("JumppowerKeybind", {
        Default = nil,
        NoUI = false,
        Text = "Toggle Jumppower",
        Callback = function()
            if Toggles.EnableJumppower then
                Toggles.EnableJumppower:SetValue(not Toggles.EnableJumppower.Value)
            end
        end
    })

keybindsGroup:AddLabel("Fly Toggle Keybind")
    :AddKeyPicker("FlyKeybind", {
        Default = nil,
        NoUI = false,
        Text = "Toggle Fly",
        Callback = function()
            if Toggles.Fly then
                Toggles.Fly:SetValue(not Toggles.Fly.Value)
            end
        end
    })

keybindsGroup:AddLabel("Noclip Toggle Keybind")
    :AddKeyPicker("NoclipKeybind", {
        Default = nil,
        NoUI = false,
        Text = "Toggle Noclip",
        Callback = function()
            if Toggles.Noclip then
                Toggles.Noclip:SetValue(not Toggles.Noclip.Value)
            end
        end
    })

keybindsGroup:AddLabel("ESP Toggle Keybind")
    :AddKeyPicker("ESPKeybind", {
        Default = nil,
        NoUI = false,
        Text = "Toggle ESP",
        Callback = function()
            if Toggles.ESP then
                Toggles.ESP:SetValue(not Toggles.ESP.Value)
            end
        end
    })

keybindsGroup:AddLabel("Fullbright Toggle Keybind")
    :AddKeyPicker("FullbrightKeybind", {
        Default = nil,
        NoUI = false,
        Text = "Toggle Fullbright",
        Callback = function()
            if Toggles.Fullbright then
                Toggles.Fullbright:SetValue(not Toggles.Fullbright.Value)
            end
        end
    })

local settingsTab = window:AddTab("Settings", "settings")
local configGroup = settingsTab:AddLeftGroupbox("Configuration")

configGroup:AddToggle("KeybindMenu", {
    Default = Library.KeybindFrame.Visible,
    Text = "Keybind Menu",
    Callback = function(isVisible)
        Library.KeybindFrame.Visible = isVisible
    end
})

configGroup:AddToggle("CustomCursor", {
    Text = "Custom Cursor",
    Default = true,
    Callback = function(isEnabled)
        Library.ShowCustomCursor = isEnabled
    end
})

configGroup:AddDropdown("NotifySide", {
    Values = { "Left", "Right" },
    Default = "Right",
    Text = "Notification Side",
    Callback = function(side)
        Library:SetNotifySide(side)
    end
})

configGroup:AddDropdown("DPIScale", {
    Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" },
    Default = "100%",
    Text = "DPI Scale",
    Callback = function(scaleText)
        scaleText = scaleText:gsub("%%", "")
        local scaleNumber = tonumber(scaleText)
        if scaleNumber then
            Library:SetDPIScale(scaleNumber / 100)
        end
    end
})

configGroup:AddDivider()
configGroup:AddLabel("Keybind"):AddKeyPicker("MenuKeybind", {
    Default = "RightShift",
    NoUI = true,
    Text = "Menu keybind"
})

configGroup:AddButton({
    Text = "Unload",
    Func = function()
        Library:Unload()
    end
})

Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })

ThemeManager:SetFolder("PlowsScriptHub")
SaveManager:SetFolder("PlowsScriptHub/General")
SaveManager:SetSubFolder("Universal")

SaveManager:BuildConfigSection(settingsTab)
ThemeManager:ApplyToTab(settingsTab)

SaveManager:LoadAutoloadConfig()

Library:OnUnload(function()
    if Toggles.EnableWalkspeed and Toggles.EnableWalkspeed.Value then
        Toggles.EnableWalkspeed:SetValue(false)
    end
    if Toggles.EnableJumppower and Toggles.EnableJumppower.Value then
        Toggles.EnableJumppower:SetValue(false)
    end
    if Toggles.Fly and Toggles.Fly.Value then
        Toggles.Fly:SetValue(false)
    end
    if Toggles.Noclip and Toggles.Noclip.Value then
        Toggles.Noclip:SetValue(false)
    end
    if Toggles.ESP and Toggles.ESP.Value then
        Toggles.ESP:SetValue(false)
    end
    if Toggles.Fullbright and Toggles.Fullbright.Value then
        Toggles.Fullbright:SetValue(false)
    end

    if fpsConnection then
        fpsConnection:Disconnect()
        fpsConnection = nil
    end
    if walkspeedConnection then
        walkspeedConnection:Disconnect()
        walkspeedConnection = nil
    end
    if jumppowerConnection then
        jumppowerConnection:Disconnect()
        jumppowerConnection = nil
    end
    if flyConnection then
        flyConnection:Disconnect()
        flyConnection = nil
    end
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end
    if espConnection then
        espConnection:Disconnect()
        espConnection = nil
    end

    workspace.Gravity = originalGravity

    lightingService.ClockTime = originalLighting.ClockTime
    lightingService.FogEnd = originalLighting.FogEnd
    lightingService.FogStart = originalLighting.FogStart

    local character = localPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")

    if humanoid then
        humanoid.WalkSpeed = defaultWalkspeed
        humanoid.JumpPower = defaultJumppower
        humanoid.PlatformStand = false
    end

    if rootPart then
        rootPart.Velocity = Vector3.new(0, 0, 0)
    end

    if character then
        for part, state in pairs(savedCollisionStates) do
            if part and part.Parent == character and part:IsA("BasePart") then
                part.CanCollide = state
            end
        end
    end

    clearESP()
end)
