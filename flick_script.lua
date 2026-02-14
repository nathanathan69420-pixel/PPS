local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/"
local lib = loadstring(game:HttpGet(repo .. "Library.lua"))()
local theme = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local save = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local function get(name)
    local s = game:GetService(name)
    if not s then return nil end
    if cloneref then
        local success, res = pcall(cloneref, s)
        return success and res or s
    end
    return s
end

local cam = workspace.CurrentCamera

local function safeClick()
    local vim = game:GetService("VirtualInputManager")
    if vim and cam then
        vim:SendMouseButtonEvent(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2, 0, true, game, 0)
        task.wait(0.01)
        vim:SendMouseButtonEvent(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2, 0, false, game, 0)
    end
end

local function bypass()
    local g = game
    local lp = g:GetService("Players").LocalPlayer
    
    if not hookmetamethod or not getrawmetatable or not setreadonly then return end
    
    local blockedServices = {
        VirtualInputManager = true,
        HttpService = true,
        TeleportService = true,
        GuiService = true,
        MessageBusService = true,
        AnalyticsService = true,
        ScriptContext = true
    }
    
    local blockedIndexes = {
        Drawing = true,
        VirtualInputManager = true,
        HttpService = true,
        TeleportService = true,
        GuiService = true,
        PreloadAsync = true
    }
    
    local serviceCache = {}
    local folderCache = {}
    
    local function getFolder(name)
        if not folderCache[name] then
            local f = Instance.new("Folder")
            f.Name = name
            folderCache[name] = f
        end
        return folderCache[name]
    end
    
    local oldIndex
    oldIndex = hookmetamethod(g, "__index", function(self, key)
        if not checkcaller() then
            if blockedIndexes[key] then
                return nil
            end
            if key == "GetService" or key == "getService" then
                return function(s, n)
                    if blockedServices[n] then
                        return getFolder(n)
                    end
                    if serviceCache[n] then
                        return serviceCache[n]
                    end
                    local r = oldIndex(self, key)(s, n)
                    serviceCache[n] = r
                    return r
                end
            end
        end
        return oldIndex(self, key)
    end)
    
    local oldNamecall
    oldNamecall = hookmetamethod(g, "__namecall", function(self, ...)
        local m = getnamecallmethod()
        local a = {...}
        
        if not checkcaller() then
            if m == "Kick" and self == lp then
                return task.wait(9e9)
            end
            
            if (m == "GetService" or m == "getService") and #a > 0 then
                local s = a[1]
                if blockedServices[s] then
                    return getFolder(s)
                end
            end
            
            if m == "OpenBrowserWindow" or m == "OpenVideo" then
                return nil
            end
            
            if m == "PreloadAsync" then
                return nil
            end
            
            if m == "GetLogHistory" or m == "SaveLog" then
                return {}
            end
        end
        
        return oldNamecall(self, ...)
    end)
    
    local oldNewIndex
    oldNewIndex = hookmetamethod(g, "__newindex", function(self, key, value)
        if not checkcaller() then
            if key == "Enabled" and typeof(self) == "Instance" and (self:IsA("Script") or self:IsA("LocalScript")) then
                return
            end
        end
        return oldNewIndex(self, key, value)
    end)
    
    if hookfunction then
        local oldGetService = hookfunction(lp.GetService, function(s, n)
            if blockedServices[n] then
                return getFolder(n)
            end
            return oldGetService(s, n)
        end)
    end
    
    local mt = getrawmetatable(g)
    if mt and setreadonly then
        setreadonly(mt, true)
    end
    
    task.spawn(function()
        while task.wait(math.random(30, 60)) do
            folderCache = {}
            serviceCache = {}
        end
    end)
end

local rs = get("RunService")
local plrs = get("Players")
local uis = get("UserInputService")
local lp = plrs.LocalPlayer

theme.BuiltInThemes["Default"][2] = {
    BackgroundColor = "16293a",
    MainColor = "26445f",
    AccentColor = "5983a0",
    OutlineColor = "325573",
    FontColor = "d2dae1"
}

local win = lib:CreateWindow({
    Title = "Axis Hub - Flick.lua",
    Footer = "by RwalDev & Plow | 1.9.9 | Discord: .gg/UuyxhqgEVs",
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
local visuals = main:AddRightGroupbox("Visuals")
local cfgBox = config:AddLeftGroupbox("Config")

status:AddLabel(string.format("Welcome, %s\nGame: Flick", lp.DisplayName), true)
status:AddButton({ Text = "Unload", Func = function() lib:Unload() end })

local triggerDelay = 0.32
local aimPart = "Head"
local boxStyle = "2D"
local aimSmooth = 0.5

aiming:AddToggle("Triggerbot", { Text = "Triggerbot", Default = false }):AddKeyPicker("TriggerbotKey", { Default = "None", SyncToggleState = true, Mode = "Toggle", Text = "Triggerbot" })
aiming:AddSlider("TriggerDelay", { Text = "Triggerbot Delay", Default = 0.32, Min = 0.01, Max = 1, Rounding = 2, Callback = function(v) triggerDelay = v end })
aiming:AddDivider()
aiming:AddToggle("Aimbot", { Text = "Aimbot", Default = false }):AddKeyPicker("AimbotKey", { Default = "None", SyncToggleState = true, Mode = "Toggle", Text = "Aimbot" })
aiming:AddSlider("AimSmooth", { Text = "Aim Smooth", Default = 0.5, Min = 0.1, Max = 1, Rounding = 2, Callback = function(v) aimSmooth = v end })

visuals:AddToggle("ESPEnabled", { Text = "General ESP Toggle", Default = false }):AddKeyPicker("ESPKey", { Default = "None", SyncToggleState = true, Mode = "Toggle", Text = "ESP" })
visuals:AddToggle("BoxESP", { Text = "Box", Default = false }):AddKeyPicker("BoxKey", { Default = "None", SyncToggleState = true, Mode = "Toggle", Text = "Box" })
visuals:AddDropdown("BoxStyle", { Values = { "2D", "3D" }, Default = "2D", Text = "Box Style", Callback = function(v) boxStyle = v end })
visuals:AddToggle("Chams", { Text = "Chams", Default = false }):AddKeyPicker("ChamsKey", { Default = "None", SyncToggleState = true, Mode = "Toggle", Text = "Chams" }):AddColorPicker("ChamsColor", { Default = Color3.fromRGB(255, 50, 50), Title = "Chams Color" })
visuals:AddToggle("Skeleton", { Text = "Skeleton", Default = false }):AddKeyPicker("SkeletonKey", { Default = "None", SyncToggleState = true, Mode = "Toggle", Text = "Skeleton" })

local Toggles = lib.Toggles
local Options = lib.Options

local function genName()
    local s = ""
    for i = 1, math.random(8, 12) do
        s = s .. string.char(math.random(97, 122))
    end
    return s
end

local Storage = Instance.new("Folder")
Storage.Name = genName()
local coreGui = get("CoreGui")
Storage.Parent = coreGui or game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

local espData = {}
local chamsData = {}
local skeletonData = {}

local BONE_PAIRS = {
    {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"}
}

local BOX_CONNECTIONS = {{1,2},{2,4},{4,3},{3,1},{5,6},{6,8},{8,7},{7,5},{1,5},{2,6},{3,7},{4,8}}

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

local function isVisible(part, char)
    if not part then return false end
    local origin = cam.CFrame.Position
    local direction = part.Position - origin
    local ray = Ray.new(origin, direction)
    local hit, pos = workspace:FindPartOnRayWithIgnoreList(ray, {lp.Character})
    if hit and hit:IsDescendantOf(char) then return true end
    if not hit then return true end
    return (pos - part.Position).Magnitude < 1
end

local function passesChecks(player, char)
    if not isAlive(char) then return false end
    if player.Team == lp.Team then return false end
    local head = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
    if head and not isVisible(head, char) then return false end
    return true
end

local function getTarget()
    local best, dist = nil, math.huge
    local center = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y/2)
    for _, p in pairs(plrs:GetPlayers()) do
        if p ~= lp and p.Character and p.Character:FindFirstChild("Head")
        and p.Character:FindFirstChild("Humanoid")
        and p.Character.Humanoid.Health > 0
        and passesChecks(p, p.Character) then
            local pos, vis = cam:WorldToViewportPoint(p.Character.Head.Position)
            if vis then
                local mag = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                if mag < dist then
                    dist = mag
                    best = p.Character.Head
                end
            end
        end
    end
    return best
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

local function updateBoxESP(data, char, style)
    local cf, size = char:GetBoundingBox()
    local corners = {
        cf * CFrame.new(size.X/2, size.Y/2, size.Z/2),
        cf * CFrame.new(-size.X/2, size.Y/2, size.Z/2),
        cf * CFrame.new(size.X/2, -size.Y/2, size.Z/2),
        cf * CFrame.new(-size.X/2, -size.Y/2, size.Z/2),
        cf * CFrame.new(size.X/2, size.Y/2, -size.Z/2),
        cf * CFrame.new(-size.X/2, size.Y/2, -size.Z/2),
        cf * CFrame.new(size.X/2, -size.Y/2, -size.Z/2),
        cf * CFrame.new(-size.X/2, -size.Y/2, -size.Z/2)
    }

    if style == "2D" then
        for _, l in pairs(data.box3D) do l.Visible = false end
        local minX, minY = math.huge, math.huge
        local maxX, maxY = -math.huge, -math.huge
        local allOff = true
        for _, c in pairs(corners) do
            local pos, on = cam:WorldToViewportPoint(c.Position)
            if on then
                allOff = false
                minX = math.min(minX, pos.X)
                minY = math.min(minY, pos.Y)
                maxX = math.max(maxX, pos.X)
                maxY = math.max(maxY, pos.Y)
            end
        end
        if not allOff then
            data.box2D.Position = Vector2.new(minX, minY)
            data.box2D.Size = Vector2.new(maxX - minX, maxY - minY)
            data.box2D.Visible = true
        else
            data.box2D.Visible = false
        end
    else
        data.box2D.Visible = false
        local sc = {}
        for _, c in pairs(corners) do
            local pos = cam:WorldToViewportPoint(c.Position)
            table.insert(sc, Vector2.new(pos.X, pos.Y))
        end
        for i, conn in ipairs(BOX_CONNECTIONS) do
            local l = data.box3D[i]
            l.From = sc[conn[1]]
            l.To = sc[conn[2]]
            l.Visible = true
        end
    end
end

local lastTrigger = 0
local mainLoop = rs.RenderStepped:Connect(function()
    local espOn = Toggles.ESPEnabled and Toggles.ESPEnabled.Value
    if not espOn then
        for _, data in pairs(espData) do
            data.box2D.Visible = false
            for _, l in pairs(data.box3D) do l.Visible = false end
        end
        for _, h in pairs(chamsData) do h.Enabled = false end
        for _, skel in pairs(skeletonData) do
            for _, l in pairs(skel) do l.Visible = false end
        end
    end

    local boxOn = espOn and Toggles.BoxESP and Toggles.BoxESP.Value
    local chamsOn = espOn and Toggles.Chams and Toggles.Chams.Value
    local skelOn = espOn and Toggles.Skeleton and Toggles.Skeleton.Value
    local triggerOn = Toggles.Triggerbot and Toggles.Triggerbot.Value
    local aimbotOn = Toggles.Aimbot and Toggles.Aimbot.Value
    local chamsColor = Options.ChamsColor and Options.ChamsColor.Value or Color3.new(1, 1, 1)

    if aimbotOn then
        local target = getTarget()
        if target and target.Parent and target:IsA("BasePart") then
            local targetPos = target.Position
            local camPos = cam.CFrame.Position
            local direction = (targetPos - camPos).Unit
            cam.CFrame = cam.CFrame:Lerp(CFrame.lookAt(camPos, camPos + direction), aimSmooth)
        end
    end

    if triggerOn then
        local now = tick()
        if now - lastTrigger >= triggerDelay then
            local target = getTarget()
            if target then
                safeClick()
                lastTrigger = now
            end
        end
    end

    for _, p in pairs(plrs:GetPlayers()) do
        if p == lp then continue end
        
        local char = getChar(p)
        if not char then
            if espData[p] then
                espData[p].box2D.Visible = false
                for _, l in pairs(espData[p].box3D) do l.Visible = false end
            end
            if chamsData[p] then chamsData[p].Enabled = false end
            if skeletonData[p] then
                for _, l in pairs(skeletonData[p]) do l.Visible = false end
            end
            continue
        end

        local alive = isAlive(char)
        if not alive then
            if espData[p] then
                espData[p].box2D.Visible = false
                for _, l in pairs(espData[p].box3D) do l.Visible = false end
            end
            if chamsData[p] then chamsData[p].Enabled = false end
            if skeletonData[p] then
                for _, l in pairs(skeletonData[p]) do l.Visible = false end
            end
            continue
        end

        if boxOn then
            if not espData[p] then
                espData[p] = {
                    box2D = Drawing.new("Square"),
                    box3D = {}
                }
                espData[p].box2D.Color = Color3.new(1, 1, 1)
                espData[p].box2D.Thickness = 1
                for i = 1, 12 do
                    local l = Drawing.new("Line")
                    l.Color = Color3.new(1, 1, 1)
                    l.Thickness = 1
                    espData[p].box3D[i] = l
                end
            end
            updateBoxESP(espData[p], char, boxStyle)
        elseif espData[p] then
            espData[p].box2D.Visible = false
            for _, l in pairs(espData[p].box3D) do l.Visible = false end
        end

        if chamsOn then
            if not chamsData[p] then
                local h = Instance.new("Highlight")
                h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                h.FillTransparency = 0.55
                h.OutlineTransparency = 0
                h.Parent = Storage
                chamsData[p] = h
            end
            chamsData[p].Adornee = char
            chamsData[p].FillColor = chamsColor
            chamsData[p].Enabled = true
        elseif chamsData[p] then
            chamsData[p].Enabled = false
        end

        if skelOn then
            if not skeletonData[p] then
                skeletonData[p] = {}
                for i = 1, #BONE_PAIRS do
                    local l = Drawing.new("Line")
                    l.Color = Color3.new(1, 1, 1)
                    l.Thickness = 1
                    skeletonData[p][i] = l
                end
            end
            for i, pair in ipairs(BONE_PAIRS) do
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
        elseif skeletonData[p] then
            for _, l in pairs(skeletonData[p]) do l.Visible = false end
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
