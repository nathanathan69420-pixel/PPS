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
    
    setreadonly(gm, false)
    gm.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        
        if (method == "GetService" or method == "getService") and self == g then
            local s = args[1]
            if s == "VirtualInputManager" or s == "HttpService" or s == "LogService" then
                return nil
            end
        end
        
        if method == "Kick" and self == lp then
            return nil
        end
        
        return old_nc(self, ...)
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
local vim = get("VirtualInputManager")
local statsService = get("Stats")
local cam = workspace.CurrentCamera
local lp = plrs.LocalPlayer
local mouse = lp:GetMouse()

theme.BuiltInThemes["Default"][2] = {
    BackgroundColor = "16293a",
    MainColor = "26445f",
    AccentColor = "5983a0",
    OutlineColor = "325573",
    FontColor = "d2dae1"
}

local win = lib:CreateWindow({
    Title = "AXIS HUB",
    Footer = "v1.5.2",
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

local fpsLbl = stats:AddLabel("FPS: ...", true)
local pingLbl = stats:AddLabel("Ping: ...", true)

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

aiming:AddToggle("Triggerbot", { Text = "Triggerbot", Default = false }):AddKeyPicker("TriggerbotKey", { Default = "None", Mode = "Toggle", Text = "Triggerbot" })
aiming:AddSlider("TriggerDelay", { Text = "Triggerbot Delay", Default = 0.32, Min = 0.01, Max = 1, Rounding = 2, Callback = function(v) triggerDelay = v end })
aiming:AddDivider()
aiming:AddToggle("Aimbot", { Text = "Aimbot", Default = false }):AddKeyPicker("AimbotKey", { Default = "None", Mode = "Toggle", Text = "Aimbot" })
aiming:AddDropdown("AimPart", { Values = bodyParts, Default = "Head", Text = "Aim Part", Callback = function(v) aimPart = v end })

visuals:AddToggle("ESPEnabled", { Text = "General ESP Toggle", Default = false }):AddKeyPicker("ESPKey", { Default = "None", Mode = "Toggle", Text = "ESP" })
visuals:AddToggle("BoxESP", { Text = "Box", Default = false }):AddKeyPicker("BoxKey", { Default = "None", Mode = "Toggle", Text = "Box" })
visuals:AddDropdown("BoxStyle", { Values = { "2D", "3D" }, Default = "2D", Text = "Box Style", Callback = function(v) boxStyle = v end })
visuals:AddToggle("Chams", { Text = "Chams", Default = false }):AddKeyPicker("ChamsKey", { Default = "None", Mode = "Toggle", Text = "Chams" }):AddColorPicker("ChamsColor", { Default = Color3.fromRGB(255, 50, 50), Title = "Chams Color" })
visuals:AddToggle("Skeleton", { Text = "Skeleton", Default = false }):AddKeyPicker("SkeletonKey", { Default = "None", Mode = "Toggle", Text = "Skeleton" })

checks:AddToggle("WallCheck", { Text = "Wall Check", Default = true })
checks:AddToggle("TeamCheck", { Text = "Team Check", Default = true })
checks:AddToggle("ForceFieldCheck", { Text = "ForceField Check", Default = true })
checks:AddToggle("AliveCheck", { Text = "Alive Check", Default = true })

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
    -- If we hit nothing (unlikely with ray length), or hit something very close to target
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
        for _, d in pairs(espData[p]) do d:Remove() end
        espData[p] = nil
    end
    if chamsData[p] then
        chamsData[p]:Destroy()
        chamsData[p] = nil
    end
    if skeletonData[p] then
        for _, l in pairs(skeletonData[p]) do l:Remove() end
        skeletonData[p] = nil
    end
end

local lastTrigger = 0
local mainLoop = rs.RenderStepped:Connect(function()
    local espOn = lib.Toggles.ESPEnabled and lib.Toggles.ESPEnabled.Value
    local boxOn = lib.Toggles.BoxESP and lib.Toggles.BoxESP.Value
    local chamsOn = lib.Toggles.Chams and lib.Toggles.Chams.Value
    local skelOn = lib.Toggles.Skeleton and lib.Toggles.Skeleton.Value
    local triggerOn = lib.Toggles.Triggerbot and lib.Toggles.Triggerbot.Value
    local aimbotOn = lib.Toggles.Aimbot and lib.Toggles.Aimbot.Value
    local chamsColor = lib.Options.ChamsColor and lib.Options.ChamsColor.Value or Color3.new(1, 0.2, 0.2)

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
                    if vim then
                        vim:SendMouseButtonEvent(0, 0, 0, true, game, 1)
                        task.wait(0.01)
                        vim:SendMouseButtonEvent(0, 0, 0, false, game, 1)
                    else
                        -- Fallback if VIM fails
                        local tool = lp.Character and lp.Character:FindFirstChildOfClass("Tool")
                        if tool then tool:Activate() end
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
                        t = Drawing.new("Line"), b = Drawing.new("Line"),
                        l = Drawing.new("Line"), r = Drawing.new("Line"),
                        tl = Drawing.new("Line"), tr = Drawing.new("Line"),
                        bl = Drawing.new("Line"), br = Drawing.new("Line"),
                        lb = Drawing.new("Line"), rb = Drawing.new("Line"),
                        tf = Drawing.new("Line"), bf = Drawing.new("Line")
                    }
                    for _, d in pairs(espData[p]) do
                        d.Color = Color3.new(1, 1, 1)
                        d.Thickness = 1
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
                        espData[p].t.From = Vector2.new(pos.X - w / 2, pos.Y - h / 2)
                        espData[p].t.To = Vector2.new(pos.X + w / 2, pos.Y - h / 2)
                        espData[p].b.From = Vector2.new(pos.X - w / 2, pos.Y + h / 2)
                        espData[p].b.To = Vector2.new(pos.X + w / 2, pos.Y + h / 2)
                        espData[p].l.From = Vector2.new(pos.X - w / 2, pos.Y - h / 2)
                        espData[p].l.To = Vector2.new(pos.X - w / 2, pos.Y + h / 2)
                        espData[p].r.From = Vector2.new(pos.X + w / 2, pos.Y - h / 2)
                        espData[p].r.To = Vector2.new(pos.X + w / 2, pos.Y + h / 2)
                        espData[p].tl.Visible = false
                        espData[p].tr.Visible = false
                        espData[p].bl.Visible = false
                        espData[p].br.Visible = false
                        espData[p].lb.Visible = false
                        espData[p].rb.Visible = false
                        espData[p].tf.Visible = false
                        espData[p].bf.Visible = false
                    end
                else
                    local corners = {
                        cf * CFrame.new(-size.X/2, size.Y/2, -size.Z/2),
                        cf * CFrame.new(size.X/2, size.Y/2, -size.Z/2),
                        cf * CFrame.new(-size.X/2, -size.Y/2, -size.Z/2),
                        cf * CFrame.new(size.X/2, -size.Y/2, -size.Z/2),
                        cf * CFrame.new(-size.X/2, size.Y/2, size.Z/2),
                        cf * CFrame.new(size.X/2, size.Y/2, size.Z/2),
                        cf * CFrame.new(-size.X/2, -size.Y/2, size.Z/2),
                        cf * CFrame.new(size.X/2, -size.Y/2, size.Z/2)
                    }
                    local sc = {}
                    local allOn = true
                    for i, c in ipairs(corners) do
                        local v, on = worldToScreen(c.Position)
                        sc[i] = v
                        if not on then allOn = false end
                    end

                    for _, d in pairs(espData[p]) do d.Visible = allOn end

                    if allOn then
                        espData[p].t.From, espData[p].t.To = sc[1], sc[2]
                        espData[p].b.From, espData[p].b.To = sc[3], sc[4]
                        espData[p].l.From, espData[p].l.To = sc[1], sc[3]
                        espData[p].r.From, espData[p].r.To = sc[2], sc[4]
                        espData[p].tl.From, espData[p].tl.To = sc[5], sc[6]
                        espData[p].tr.From, espData[p].tr.To = sc[7], sc[8]
                        espData[p].bl.From, espData[p].bl.To = sc[5], sc[7]
                        espData[p].br.From, espData[p].br.To = sc[6], sc[8]
                        espData[p].lb.From, espData[p].lb.To = sc[1], sc[5]
                        espData[p].rb.From, espData[p].rb.To = sc[2], sc[6]
                        espData[p].tf.From, espData[p].tf.To = sc[3], sc[7]
                        espData[p].bf.From, espData[p].bf.To = sc[4], sc[8]
                        for _, d in pairs(espData[p]) do d.Visible = true end
                    end
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
                        local l = Drawing.new("Line")
                        l.Color = Color3.new(1, 1, 1)
                        l.Thickness = 1
                        skeletonData[p][i] = l
                    end
                end
                for i, pair in ipairs(bonePairs) do
                    local p0 = char:FindFirstChild(pair[1])
                    local p1 = char:FindFirstChild(pair[2])
                    if p0 and p1 then
                        local s0, on0 = worldToScreen(p0.Position)
                        local s1, on1 = worldToScreen(p1.Position)
                        skeletonData[p][i].From = s0
                        skeletonData[p][i].To = s1
                        skeletonData[p][i].Visible = on0 and on1
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

local elap, frames = 0, 0
local conn = rs.RenderStepped:Connect(function(dt)
    frames = frames + 1
    elap = elap + dt
    if elap >= 1 then
        fpsLbl:SetText("FPS: " .. math.floor(frames / elap + 0.5))
        pcall(function()
            local net = statsService and statsService.Network.ServerStatsItem["Data Ping"]
            pingLbl:SetText("Ping: " .. (net and math.floor(net:GetValue()) or 0) .. " ms")
        end)
        frames, elap = 0, 0
    end
end)

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
    if conn then conn:Disconnect() end
    for _, p in pairs(plrs:GetPlayers()) do cleanupPlayer(p) end
    if Storage then Storage:Destroy() end
end)
