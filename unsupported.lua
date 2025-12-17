local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/"
local lib = loadstring(game:HttpGet(repo .. "Library.lua"))()
local theme = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local save = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local win = lib:CreateWindow({
    Title = "Plow's Private Script",
    Footer = "v1.2.2",
    NotifySide = "Right",
    ShowCustomCursor = true,
})

local tab = win:AddTab("Home", "house")
local status = tab:AddLeftGroupbox("Status")

local lp = game.Players.LocalPlayer
local name = lp and lp.DisplayName or "Player"
local time = os.date("%H:%M:%S")

status:AddLabel(string.format("Welcome, %s\nCurrent time: %s\nGame not supported.", name, time), true)

status:AddButton({ Text = "Unload", Func = function() lib:Unload() end })

local stats = tab:AddRightGroupbox("FPS & Ping")
local fpsLbl = stats:AddLabel("FPS: ...", true)
local pingLbl = stats:AddLabel("Ping: ...", true)

local rs = game:GetService("RunService")
local statService = game:GetService("Stats")
local uis = game:GetService("UserInputService")
local plrs = game:GetService("Players")
local light = game:GetService("Lighting")

local elap, frames = 0, 0
local conn_fps

conn_fps = rs.RenderStepped:Connect(function(dt)
    frames = frames + 1
    elap = elap + dt
    if elap >= 1 then
        fpsLbl:SetText("FPS: " .. math.floor(frames / elap + 0.5))
        local net = statService.Network.ServerStatsItem["Data Ping"]
        pingLbl:SetText("Ping: " .. (net and math.floor(net:GetValue()) or 0) .. " ms")
        frames, elap = 0, 0
    end
end)

local lpTab = win:AddTab("Local Player", "user")
local mods = lpTab:AddLeftGroupbox("Modifiers")
local vis = lpTab:AddLeftGroupbox("Visuals")
local binds = lpTab:AddRightGroupbox("Keybinds")

local defWs, selWs = 16, 16
local defJp, selJp = 50, 50
local defFly, selFly = 50, 50

local c_ws, c_jp, c_fly, c_nc, c_esp
local origGrav = workspace.Gravity
local espItems = {}
local espCol = Color3.new(1, 1, 1)
local saveCol = {}

local origLight = {
    ClockTime = light.ClockTime,
    FogEnd = light.FogEnd,
    FogStart = light.FogStart
}

local function getChar()
    return lp.Character or lp.CharacterAdded:Wait()
end

local function getHum()
    return getChar():FindFirstChildOfClass("Humanoid")
end

local function camMove()
    local cam = workspace.CurrentCamera
    if not cam then return Vector3.zero end
    local cf = cam.CFrame
    local look = cf.LookVector
    local right = cf.RightVector
    local vec = Vector3.zero
    if uis:IsKeyDown(Enum.KeyCode.W) then vec = vec + look end
    if uis:IsKeyDown(Enum.KeyCode.S) then vec = vec - look end
    if uis:IsKeyDown(Enum.KeyCode.A) then vec = vec - right end
    if uis:IsKeyDown(Enum.KeyCode.D) then vec = vec + right end
    if uis:IsKeyDown(Enum.KeyCode.Space) then vec = vec + Vector3.new(0, 1, 0) end
    if uis:IsKeyDown(Enum.KeyCode.LeftControl) or uis:IsKeyDown(Enum.KeyCode.LeftShift) then vec = vec + Vector3.new(0, -1, 0) end
    return vec.Magnitude > 0 and vec.Unit or Vector3.zero
end

local function camYaw()
    local cam = workspace.CurrentCamera
    if not cam then return CFrame.new() end
    local _, yaw = cam.CFrame:ToOrientation()
    local root = getChar():FindFirstChild("HumanoidRootPart")
    return CFrame.new(root and root.Position or cam.CFrame.Position) * CFrame.Angles(0, yaw, 0)
end

mods:AddToggle("EnableWalkspeed", {
    Text = "Enable Walkspeed",
    Default = false,
    Callback = function(v)
        if c_ws then c_ws:Disconnect() c_ws = nil end
        if v then
            c_ws = rs.Heartbeat:Connect(function()
                local h = getHum()
                if h then h.WalkSpeed = selWs end
            end)
        else
            local h = getHum()
            if h then h.WalkSpeed = defWs end
        end
    end
})

mods:AddSlider("WalkspeedSlider", {
    Text = "Walkspeed",
    Default = defWs,
    Min = 16, Max = 100, Rounding = 0,
    Callback = function(v) selWs = v end
})

mods:AddToggle("EnableJumppower", {
    Text = "Enable Jumppower",
    Default = false,
    Callback = function(v)
        if c_jp then c_jp:Disconnect() c_jp = nil end
        if v then
            c_jp = rs.Heartbeat:Connect(function()
                local h = getHum()
                if h then h.UseJumpPower = true h.JumpPower = selJp end
            end)
        else
            local h = getHum()
            if h then h.JumpPower = defJp end
        end
    end
})

mods:AddSlider("JumppowerSlider", {
    Text = "Jumppower",
    Default = defJp,
    Min = 50, Max = 500, Rounding = 0,
    Callback = function(v) selJp = v end
})

mods:AddToggle("Fly", {
    Text = "Fly",
    Default = false,
    Callback = function(v)
        local char = getChar()
        local root = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        
        if c_fly then c_fly:Disconnect() c_fly = nil end
        
        if v then
            workspace.Gravity = 0
            if hum then hum.PlatformStand = true end
            c_fly = rs.Heartbeat:Connect(function()
                if not char.Parent then return end
                root = char:FindFirstChild("HumanoidRootPart")
                hum = char:FindFirstChildOfClass("Humanoid")
                if hum and root then
                    root.CFrame = camYaw()
                    local dir = camMove()
                    root.Velocity = dir.Magnitude > 0 and dir * selFly or Vector3.new(0,0,0)
                end
            end)
        else
            workspace.Gravity = origGrav
            if hum then hum.PlatformStand = false end
            if root then root.Velocity = Vector3.new(0,0,0) end
        end
    end
})

mods:AddSlider("FlySpeedSlider", {
    Text = "Fly Speed",
    Default = defFly,
    Min = 16, Max = 100, Rounding = 0,
    Callback = function(v) selFly = v end
})

mods:AddToggle("Noclip", {
    Text = "Noclip",
    Default = false,
    Callback = function(v)
        if c_nc then c_nc:Disconnect() c_nc = nil end
        saveCol = {}
        if v then
            local c = lp.Character
            if c then
                for _, p in ipairs(c:GetDescendants()) do
                    if p:IsA("BasePart") then
                        saveCol[p] = p.CanCollide
                        p.CanCollide = false
                    end
                end
            end
            c_nc = rs.Heartbeat:Connect(function()
                local char = lp.Character
                if not char then return end
                for p, s in pairs(saveCol) do
                    if p and p.Parent == char and p:IsA("BasePart") then p.CanCollide = false end
                end
            end)
        else
            local char = lp.Character
            if char then
                for p, s in pairs(saveCol) do
                    if p and p.Parent == char and p:IsA("BasePart") then p.CanCollide = s end
                end
            end
            saveCol = {}
        end
    end
})

local function clearESP()
    for _, h in pairs(espItems) do h:Destroy() end
    espItems = {}
end

local function newESP(p)
    if p == lp then return end
    local c = p.Character
    if not c then return end
    local h = Instance.new("Highlight")
    h.Adornee = c
    h.FillTransparency = 0.55
    h.OutlineTransparency = 0
    h.FillColor = espCol
    h.OutlineColor = espCol
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    h.Parent = game:GetService("CoreGui")
    espItems[p] = h
end

vis:AddToggle("ESP", {
    Text = "ESP",
    Default = false,
    Callback = function(v)
        if c_esp then c_esp:Disconnect() c_esp = nil end
        if v then
            clearESP()
            for _, p in ipairs(plrs:GetPlayers()) do
                if p ~= lp then newESP(p) end
            end
            c_esp = plrs.PlayerAdded:Connect(function(p)
                if lib.Toggles.ESP.Value then newESP(p) end
            end)
            plrs.PlayerRemoving:Connect(function(p)
                if espItems[p] then espItems[p]:Destroy() espItems[p] = nil end
            end)
        else
            clearESP()
        end
    end
}):AddColorPicker("ESPColor", {
    Default = Color3.new(1, 1, 1),
    Title = "Color",
    Callback = function(v)
        espCol = v
        for _, h in pairs(espItems) do
            h.FillColor = v
            h.OutlineColor = v
        end
    end
})

vis:AddToggle("Fullbright", {
    Text = "Fullbright",
    Default = false,
    Callback = function(v)
        if v then
            origLight.ClockTime = light.ClockTime
            origLight.FogEnd = light.FogEnd
            origLight.FogStart = light.FogStart
            light.ClockTime = 14
            light.FogEnd = 100000
            light.FogStart = 0
        else
            light.ClockTime = origLight.ClockTime
            light.FogEnd = origLight.FogEnd
            light.FogStart = origLight.FogStart
        end
    end
})

binds:AddLabel("Walkspeed Toggle Keybind"):AddKeyPicker("WalkspeedKeybind", { Default = nil, Text = "Toggle Walkspeed", Callback = function()
    if lib.Toggles.EnableWalkspeed then lib.Toggles.EnableWalkspeed:SetValue(not lib.Toggles.EnableWalkspeed.Value) end
end })

binds:AddLabel("Jumppower Toggle Keybind"):AddKeyPicker("JumppowerKeybind", { Default = nil, Text = "Toggle Jumppower", Callback = function()
    if lib.Toggles.EnableJumppower then lib.Toggles.EnableJumppower:SetValue(not lib.Toggles.EnableJumppower.Value) end
end })

binds:AddLabel("Fly Toggle Keybind"):AddKeyPicker("FlyKeybind", { Default = nil, Text = "Toggle Fly", Callback = function()
    if lib.Toggles.Fly then lib.Toggles.Fly:SetValue(not lib.Toggles.Fly.Value) end
end })

binds:AddLabel("Noclip Toggle Keybind"):AddKeyPicker("NoclipKeybind", { Default = nil, Text = "Toggle Noclip", Callback = function()
    if lib.Toggles.Noclip then lib.Toggles.Noclip:SetValue(not lib.Toggles.Noclip.Value) end
end })

binds:AddLabel("ESP Toggle Keybind"):AddKeyPicker("ESPKeybind", { Default = nil, Text = "Toggle ESP", Callback = function()
    if lib.Toggles.ESP then lib.Toggles.ESP:SetValue(not lib.Toggles.ESP.Value) end
end })

binds:AddLabel("Fullbright Toggle Keybind"):AddKeyPicker("FullbrightKeybind", { Default = nil, Text = "Toggle Fullbright", Callback = function()
    if lib.Toggles.Fullbright then lib.Toggles.Fullbright:SetValue(not lib.Toggles.Fullbright.Value) end
end })

local sets = win:AddTab("Settings", "settings")
local cfg = sets:AddLeftGroupbox("Configuration")

cfg:AddToggle("KeybindMenu", { Default = lib.KeybindFrame.Visible, Text = "Keybind Menu", Callback = function(v) lib.KeybindFrame.Visible = v end })
cfg:AddToggle("CustomCursor", { Text = "Custom Cursor", Default = true, Callback = function(v) lib.ShowCustomCursor = v end })
cfg:AddDropdown("NotifySide", { Values = { "Left", "Right" }, Default = "Right", Text = "Notification Side", Callback = function(v) lib:SetNotifySide(v) end })
cfg:AddDropdown("DPIScale", { Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" }, Default = "100%", Text = "DPI Scale", Callback = function(v) local n = tonumber(v:gsub("%%", "")) if n then lib:SetDPIScale(n / 100) end end })

cfg:AddDivider()
cfg:AddLabel("Keybind"):AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })
cfg:AddButton({ Text = "Unload", Func = function() lib:Unload() end })

lib.ToggleKeybind = lib.Options.MenuKeybind
theme:SetLibrary(lib)
save:SetLibrary(lib)
save:IgnoreThemeSettings()
save:SetIgnoreIndexes({ "MenuKeybind" })
theme:SetFolder("PlowsScriptHub")
save:SetFolder("PlowsScriptHub/General")
save:SetSubFolder("Universal")
save:BuildConfigSection(sets)
theme:ApplyToTab(sets)
save:LoadAutoloadConfig()

lib:OnUnload(function()
    if lib.Toggles.EnableWalkspeed and lib.Toggles.EnableWalkspeed.Value then lib.Toggles.EnableWalkspeed:SetValue(false) end
    if lib.Toggles.EnableJumppower and lib.Toggles.EnableJumppower.Value then lib.Toggles.EnableJumppower:SetValue(false) end
    if lib.Toggles.Fly and lib.Toggles.Fly.Value then lib.Toggles.Fly:SetValue(false) end
    if lib.Toggles.Noclip and lib.Toggles.Noclip.Value then lib.Toggles.Noclip:SetValue(false) end
    if lib.Toggles.ESP and lib.Toggles.ESP.Value then lib.Toggles.ESP:SetValue(false) end
    if lib.Toggles.Fullbright and lib.Toggles.Fullbright.Value then lib.Toggles.Fullbright:SetValue(false) end

    if conn_fps then conn_fps:Disconnect() end
    if c_ws then c_ws:Disconnect() end
    if c_jp then c_jp:Disconnect() end
    if c_fly then c_fly:Disconnect() end
    if c_nc then c_nc:Disconnect() end
    if c_esp then c_esp:Disconnect() end

    workspace.Gravity = origGrav
    light.ClockTime = origLight.ClockTime
    light.FogEnd = origLight.FogEnd
    light.FogStart = origLight.FogStart

    local hum = getHum()
    local root = getChar():FindFirstChild("HumanoidRootPart")
    if hum then hum.WalkSpeed = defWs hum.JumpPower = defJp hum.PlatformStand = false end
    if root then root.Velocity = Vector3.new(0,0,0) end
    if lp.Character then
        for p, s in pairs(saveCol) do
            if p and p.Parent == lp.Character and p:IsA("BasePart") then p.CanCollide = s end
        end
    end
    clearESP()
end)
