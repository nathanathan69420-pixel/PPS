local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/"
local lib = loadstring(game:HttpGet(repo .. "Library.lua"))()
local theme = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local save = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local function bypass()
    local g = game
    local lp = g:GetService("Players").LocalPlayer
    if not getrawmetatable or not setreadonly or not newcclosure or not getnamecallmethod then return end
    
    local gm = getrawmetatable(g)
    local old_nc = gm.__namecall
    local old_idx = gm.__index
    
    setreadonly(gm, false)
    gm.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if not checkcaller() then
            if method == "Kick" and self == lp then return nil end
            if method == "FindPartOnRayWithIgnoreList" then return nil end
        end
        return old_nc(self, ...)
    end)
    
    gm.__index = newcclosure(function(self, k)
        if not checkcaller() then
            if k == "Drawing" then return nil end
            if k == "VirtualInputManager" then return nil end
            if k == "HttpService" then return nil end
            if k == "LogService" then return nil end
        end
        return old_idx(self, k)
    end)
    
    setreadonly(gm, true)
end


local function get(name)
    local s = game:GetService(name)
    if not s then return nil end
    if cloneref then
        local success, res = pcall(cloneref, s)
        return success and res or s
    end
    return s
end

local rs = get("RunService")
local plrs = get("Players")
local uis = get("UserInputService")
local cam = workspace.CurrentCamera
local lp = plrs.LocalPlayer


theme.BuiltInThemes["Default"][2] = {
    BackgroundColor = "16293a",
    MainColor = "26445f",
    AccentColor = "5983a0",
    OutlineColor = "325573",
    FontColor = "d2dae1"
}

local win = lib:CreateWindow({
    Title = "AXIS HUB",
    Footer = "v1.6.2",
    NotifySide = "Right",
    ShowCustomCursor = true,
})

pcall(bypass)

local home = win:AddTab("Home", "house")
local main = win:AddTab("Main", "crosshair")
local config = win:AddTab("Settings", "settings")

local status = home:AddLeftGroupbox("Status")
local stats = home:AddRightGroupbox("FPS & Ping")
local aiming = main:AddLeftGroupbox("Aiming")
local checks = main:AddLeftGroupbox("Checks")
local visuals = main:AddRightGroupbox("Visuals")
local cfgBox = config:AddLeftGroupbox("Config")

status:AddLabel(string.format("Welcome, %s\nGame: Flick", lp.DisplayName), true)
status:AddButton({ Text = "Unload", Func = function() lib:Unload() end })



local triggerDelay = 0.32
local aimPart = "Head"
local boxStyle = "2D"

local bodyParts = {
    "Random", "Closest", "Head", "HumanoidRootPart", "Torso",
    "UpperTorso", "LowerTorso", "LeftArm", "RightArm",
    "LeftUpperArm", "RightUpperArm", "LeftLowerArm", "RightLowerArm",
    "LeftHand", "RightHand", "LeftLeg", "RightLeg",
    "LeftUpperLeg", "RightUpperLeg", "LeftLowerLeg", "RightLowerLeg",
    "LeftFoot", "RightFoot"
}

aiming:AddToggle("Triggerbot", { Text = "Triggerbot", Default = false }):AddKeyPicker("TriggerbotKey", { Default = "None", SyncToggleState = true, Mode = "Toggle", Text = "Triggerbot" })
aiming:AddSlider("TriggerDelay", { Text = "Triggerbot Delay", Default = 0.32, Min = 0.01, Max = 1, Rounding = 2, Callback = function(v) triggerDelay = v end })
aiming:AddDivider()
aiming:AddToggle("Aimbot", { Text = "Aimbot", Default = false }):AddKeyPicker("AimbotKey", { Default = "None", SyncToggleState = true, Mode = "Toggle", Text = "Aimbot" })
aiming:AddDropdown("AimPart", { Values = bodyParts, Default = "Head", Text = "Aim Part", Callback = function(v) aimPart = v end })

visuals:AddToggle("ESPEnabled", { Text = "General ESP Toggle", Default = false }):AddKeyPicker("ESPKey", { Default = "None", SyncToggleState = true, Mode = "Toggle", Text = "ESP" })
visuals:AddToggle("BoxESP", { Text = "Box", Default = false }):AddKeyPicker("BoxKey", { Default = "None", SyncToggleState = true, Mode = "Toggle", Text = "Box" })
visuals:AddDropdown("BoxStyle", { Values = { "2D", "3D" }, Default = "2D", Text = "Box Style", Callback = function(v) boxStyle = v end })
visuals:AddToggle("Chams", { Text = "Chams", Default = false }):AddKeyPicker("ChamsKey", { Default = "None", SyncToggleState = true, Mode = "Toggle", Text = "Chams" }):AddColorPicker("ChamsColor", { Default = Color3.fromRGB(255, 50, 50), Title = "Chams Color" })
visuals:AddToggle("Skeleton", { Text = "Skeleton", Default = false }):AddKeyPicker("SkeletonKey", { Default = "None", SyncToggleState = true, Mode = "Toggle", Text = "Skeleton" })

checks:AddToggle("WallCheck", { Text = "Wall Check", Default = true })
checks:AddToggle("TeamCheck", { Text = "Team Check", Default = true })
checks:AddToggle("ForceFieldCheck", { Text = "ForceField Check", Default = true })
checks:AddToggle("AliveCheck", { Text = "Alive Check", Default = true })

local Toggles = lib.Toggles
local Options = lib.Options

local function genName()
    local s = ""
    for i = 1, math.random(8, 12) do
        s ..= string.char(math.random(97, 122))
    end
    return s
end

local Storage = Instance.new("Folder")
Storage.Name = genName()
Storage.Parent = get("CoreGui")

local espData = {}
local chamsData = {}
local skeletonData = {}

local function createLine()
    local line = Instance.new("Frame")
    line.BorderSizePixel = 0
    line.BackgroundColor3 = Color3.new(1, 1, 1)
    line.Parent = Storage
    return line
end

local bonePairs = {
    {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"}
}

local function getChar(p)
    return p and p.Character
end

local function isAlive(char)
    local h = char and char:FindFirstChild("Humanoid")
    return h and h.Health > 0
end

local function worldToScreen(pos)
    local vec, onScreen = cam:WorldToViewportPoint(pos)
    return Vector2.new(vec.X, vec.Y), onScreen, vec.Z
end

local function getClosestPart(char)
    local closest, dist = nil, math.huge
    for _, p in pairs(char:GetChildren()) do
        if p:IsA("BasePart") then
            local screenPos, onScreen = worldToScreen(p.Position)
            if onScreen then
                local center = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
                local d = (screenPos - center).Magnitude
                if d < dist then
                    dist = d
                    closest = p
                end
            end
        end
    end
    return closest
end

local function getRandomPart(char)
    local parts = {}
    for _, p in pairs(char:GetChildren()) do
        if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
            table.insert(parts, p)
        end
    end
    return #parts > 0 and parts[math.random(1, #parts)] or nil
end

local function isVisible(part, char)
    if not part then return false end
    local origin = cam.CFrame.Position
    local direction = part.Position - origin
    local ray = Ray.new(origin, direction)
    local hit, pos = workspace:FindPartOnRayWithIgnoreList(ray, {lp.Character})
    
    if hit and hit:IsDescendantOf(char) then
        return true
    end
    
    if not hit then return true end
    return (pos - part.Position).Magnitude < 1
end

local function hasForceField(char)
    return char:FindFirstChildOfClass("ForceField") ~= nil
end

local function passesChecks(player, char)
    local wallCheck = lib.Toggles.WallCheck and lib.Toggles.WallCheck.Value
    local teamCheck = lib.Toggles.TeamCheck and lib.Toggles.TeamCheck.Value
    local ffCheck = lib.Toggles.ForceFieldCheck and lib.Toggles.ForceFieldCheck.Value
    local aliveCheck = lib.Toggles.AliveCheck and lib.Toggles.AliveCheck.Value
    
    if aliveCheck and not isAlive(char) then return false end
    if teamCheck and player.Team == lp.Team then return false end
    if ffCheck and hasForceField(char) then return false end
    if wallCheck then
        local head = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
        if head and not isVisible(head, char) then return false end
    end
    return true
end

local function getAimTarget()
    local closest, dist = nil, math.huge
    for _, p in pairs(plrs:GetPlayers()) do
        if p ~= lp then
            local char = getChar(p)
            if char and passesChecks(p, char) then
                local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")
                if root then
                    local screenPos, onScreen = worldToScreen(root.Position)
                    if onScreen then
                        local center = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
                        local d = (screenPos - center).Magnitude
                        if d < dist then
                            dist = d
                            closest = char
                        end
                    end
                end
            end
        end
    end
    return closest
end

local function getTargetPart(char)
    if aimPart == "Random" then
        return getRandomPart(char)
    elseif aimPart == "Closest" then
        return getClosestPart(char)
    else
        return char:FindFirstChild(aimPart) or char:FindFirstChild("Head")
    end
end

local function cleanupPlayer(p)
    if espData[p] then
        for _, d in pairs(espData[p]) do d:Destroy() end
        espData[p] = nil
    end
    if chamsData[p] then
        chamsData[p]:Destroy()
        chamsData[p] = nil
    end
    if skeletonData[p] then
        for _, l in pairs(skeletonData[p]) do l:Destroy() end
        skeletonData[p] = nil
    end
end

local lastTrigger = 0
local mainLoop = rs.RenderStepped:Connect(function()
    local espOn = Toggles.ESPEnabled and Toggles.ESPEnabled.Value
    local boxOn = Toggles.BoxESP and Toggles.BoxESP.Value
    local chamsOn = Toggles.Chams and Toggles.Chams.Value
    local skelOn = Toggles.Skeleton and Toggles.Skeleton.Value
    local triggerOn = Toggles.Triggerbot and Toggles.Triggerbot.Value
    local aimbotOn = Toggles.Aimbot and Toggles.Aimbot.Value
    local chamsColor = Options.ChamsColor and Options.ChamsColor.Value or Color3.new(1, 1, 1)

    if aimbotOn then
        local target = getAimTarget()
        if target then
            local part = getTargetPart(target)
            if part then
                local targetPos = part.Position
                local camPos = cam.CFrame.Position
                local direction = (targetPos - camPos).Unit
                local targetCFrame = CFrame.lookAt(camPos, camPos + direction)
                cam.CFrame = cam.CFrame:Lerp(targetCFrame, 0.5)
            end
        end
    end

    if triggerOn then
        local now = tick()
        if now - lastTrigger >= triggerDelay then
            local ray = Ray.new(cam.CFrame.Position, cam.CFrame.LookVector * 1000)
            local hit = workspace:FindPartOnRayWithIgnoreList(ray, {lp.Character})
            if hit then
                local model = hit:FindFirstAncestorOfClass("Model")
                if model and plrs:GetPlayerFromCharacter(model) and plrs:GetPlayerFromCharacter(model) ~= lp then
                    local tool = lp.Character and lp.Character:FindFirstChildOfClass("Tool")
                    if tool then 
                        tool:Activate() 
                    end
                    lastTrigger = now
                end
            end
        end
    end

    for _, p in pairs(plrs:GetPlayers()) do
        if p ~= lp then
            local char = getChar(p)
            local alive = char and isAlive(char)
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local head = char and char:FindFirstChild("Head")

            if espOn and boxOn and alive and root then
                if not espData[p] then
                    espData[p] = {
                        t = createLine(), b = createLine(),
                        l = createLine(), r = createLine(),
                        tl = createLine(), tr = createLine(),
                        bl = createLine(), br = createLine(),
                        lb = createLine(), rb = createLine(),
                        tf = createLine(), bf = createLine()
                    }
                    for _, d in pairs(espData[p]) do
                        d.BorderSizePixel = 0
                        d.BackgroundColor3 = Color3.new(1, 1, 1)
                    end
                end

                local cf = root.CFrame
                local size = Vector3.new(4, 5, 2)

                if boxStyle == "2D" then
                    local pos, onScreen = worldToScreen(root.Position)
                    local dist = (cam.CFrame.Position - root.Position).Magnitude
                    local factor = 1 / (dist * math.tan(math.rad(cam.FieldOfView / 2)) * 2 / cam.ViewportSize.Y)
                    local w, h = size.X * factor, size.Y * factor

                    for _, d in pairs(espData[p]) do d.Visible = onScreen end

                    if onScreen then
                        espData[p].t.Position = UDim2.new(0, pos.X - w / 2, 0, pos.Y - h / 2)
                        espData[p].t.Size = UDim2.new(0, w, 0, 1)
                        espData[p].b.Position = UDim2.new(0, pos.X - w / 2, 0, pos.Y + h / 2)
                        espData[p].b.Size = UDim2.new(0, w, 0, 1)
                        espData[p].l.Position = UDim2.new(0, pos.X - w / 2, 0, pos.Y - h / 2)
                        espData[p].l.Size = UDim2.new(0, 1, 0, h)
                        espData[p].r.Position = UDim2.new(0, pos.X + w / 2, 0, pos.Y - h / 2)
                        espData[p].r.Size = UDim2.new(0, 1, 0, h)
                        for _, d in pairs({espData[p].tl, espData[p].tr, espData[p].bl, espData[p].br, espData[p].lb, espData[p].rb, espData[p].tf, espData[p].bf}) do
                            d.Visible = false
                        end
                    end
                else
                    for _, d in pairs(espData[p]) do d.Visible = false end
                end
            else
                if espData[p] then
                    for _, d in pairs(espData[p]) do d.Visible = false end
                end
            end

            if espOn and chamsOn and alive and char then
                if not chamsData[p] then
                    local h = Instance.new("Highlight")
                    h.Name = p.Name
                    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    h.FillTransparency = 0.55
                    h.OutlineTransparency = 0
                    h.OutlineColor = Color3.new(1, 1, 1)
                    h.Parent = Storage
                    chamsData[p] = h
                end
                chamsData[p].Adornee = char
                chamsData[p].FillColor = chamsColor
                chamsData[p].Enabled = true
            else
                if chamsData[p] then chamsData[p].Enabled = false end
            end

            if espOn and skelOn and alive and char then
                if not skeletonData[p] then
                    skeletonData[p] = {}
                    for i = 1, #bonePairs do
                        local l = createLine()
                        skeletonData[p][i] = l
                    end
                end
                for i, pair in ipairs(bonePairs) do
                    local p0 = char:FindFirstChild(pair[1])
                    local p1 = char:FindFirstChild(pair[2])
                    if p0 and p1 then
                        local s0, on0 = worldToScreen(p0.Position)
                        local s1, on1 = worldToScreen(p1.Position)
                        if on0 and on1 then
                            local line = skeletonData[p][i]
                            local dist = (s0 - s1).Magnitude
                            local angle = math.atan2(s1.Y - s0.Y, s1.X - s0.X)
                            line.Position = UDim2.new(0, s0.X, 0, s0.Y)
                            line.Size = UDim2.new(0, dist, 0, 1)
                            line.Rotation = math.deg(angle)
                            line.Visible = true
                        else
                            skeletonData[p][i].Visible = false
                        end
                    else
                        skeletonData[p][i].Visible = false
                    end
                end
            else
                if skeletonData[p] then
                    for _, l in pairs(skeletonData[p]) do l.Visible = false end
                end
            end
        end
    end
end)

plrs.PlayerRemoving:Connect(cleanupPlayer)

cfgBox:AddToggle("KeyMenu", { Default = lib.KeybindFrame.Visible, Text = "Keybind Menu", Callback = function(v) lib.KeybindFrame.Visible = v end })
cfgBox:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { Default = "RightControl", NoUI = true, Text = "Menu bind" })
lib.ToggleKeybind = lib.Options.MenuKeybind



theme:SetLibrary(lib)
save:SetLibrary(lib)
save:IgnoreThemeSettings()
save:SetIgnoreIndexes({ "MenuKeybind" })
theme:SetFolder("PlowsScriptHub")
save:SetFolder("PlowsScriptHub/Flick")
save:BuildConfigSection(config)
theme:ApplyToTab(config)
save:LoadAutoloadConfig()

lib:OnUnload(function()
    if mainLoop then mainLoop:Disconnect() end
    for _, p in pairs(plrs:GetPlayers()) do cleanupPlayer(p) end
    if Storage then Storage:Destroy() end
end)
