
local Secure = {}

function Secure.Service(name)
    local s = game:GetService(name)
    if cloneref then s = cloneref(s) end
    return s
end

function Secure.Raycast(origin, dir, params)
    return workspace:Raycast(origin, dir, params)
end

function Secure.Gui(gui)
    if not gui then return end
    if gethui then
        gui.Parent = gethui()
    elseif syn and syn.protect_gui then
        syn.protect_gui(gui)
        gui.Parent = Secure.Service("CoreGui")
    end
end

local function randomString(len)
    local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local str = ""
    for i = 1, len do
        local r = math.random(1, #chars)
        str = str .. string.sub(chars, r, r)
    end
    return str
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
            
            if m == "SendMouseButtonEvent" or m == "SendKeyEvent" or m == "SendMouseWheelEvent" then
                return nil
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

pcall(bypass)

local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/"
local lib = loadstring(game:HttpGet(repo .. "Library.lua"))()
local theme = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local save = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local rs = Secure.Service("RunService")
local plrs = Secure.Service("Players")
local uis = Secure.Service("UserInputService")
local vim = Secure.Service("VirtualInputManager")
local lp = plrs.LocalPlayer
local cam = workspace.CurrentCamera

local Toggles, Options = lib.Toggles, lib.Options

theme.BuiltInThemes["Default"][2] = {
    BackgroundColor = "16293a", MainColor = "26445f", AccentColor = "5983a0", OutlineColor = "325573", FontColor = "d2dae1"
}

local win = lib:CreateWindow({
    Title = "Axis Hub - MvS Duels", Footer = "by RwalDev & Plow | 1.9.9", NotifySide = "Right", ShowCustomCursor = true,
})

if win and win.Holder and win.Holder.Parent then
    win.Holder.Parent.Name = randomString(15)
    Secure.Gui(win.Holder.Parent)
end
 
local home = win:AddTab("Home", "house")
local combat = win:AddTab("Combat", "swords")
local visuals = win:AddTab("Visuals", "eye")
local config = win:AddTab("Settings", "settings")

local status = home:AddLeftGroupbox("Status")
local hitboxes = combat:AddLeftGroupbox("Hitboxes")
local aiming = combat:AddRightGroupbox("Aiming")
local mainVisuals = visuals:AddLeftGroupbox("Main")
local boxVisuals = visuals:AddRightGroupbox("Boxes")
local cfgBox = config:AddLeftGroupbox("Config")

status:AddLabel(string.format("Welcome, %s\nGame: MvS Duels", lp.DisplayName), true)
status:AddButton({ Text = "Unload", Func = function() lib:Unload() end })

local playerESPData = {}
local chamsData = {}

local function resetHitboxForPlayer(player)
    if player.Character then
        for _, part in pairs(player.Character:GetChildren()) do
            if part:IsA("BasePart") then
                pcall(function()
                    if part.Name == "HumanoidRootPart" then
                        part.Size = Vector3.new(2, 2, 1)
                        part.Transparency = 1
                        part.CanCollide = true
                    elseif part.Name == "Head" then
                         part.Size = Vector3.new(2, 1, 1)
                         part.Transparency = 0
                         part.CanCollide = true
                    elseif string.find(part.Name, "Torso") then
                        part.Size = Vector3.new(2, 2, 1)
                        part.Transparency = 0
                        part.CanCollide = true
                    elseif string.find(part.Name, "Arm") or string.find(part.Name, "Leg") or string.find(part.Name, "Hand") or string.find(part.Name, "Foot") then
                        part.Size = Vector3.new(1, 2, 1)
                        part.Transparency = 0
                        part.CanCollide = true
                    end
                end)
            end
        end
    end
end

local function resetAllHitboxes()
    for _, player in pairs(plrs:GetPlayers()) do
        if player ~= lp then
            resetHitboxForPlayer(player)
        end
    end
end

hitboxes:AddToggle("HitboxEnabled", { Text = "Hitbox Expander", Default = false, Callback = function(v) 
    if not v then resetAllHitboxes() end 
end })
hitboxes:AddSlider("HitboxSize", { Text = "Size", Default = 2, Min = 1, Max = 10, Rounding = 1 })
hitboxes:AddSlider("HitboxTrans", { Text = "Transparency", Default = 0.5, Min = 0, Max = 1, Rounding = 1 })
hitboxes:AddDropdown("HitboxLimbs", { Values = { "Head", "Torso", "Arms", "Legs" }, Default = "Torso", Multi = true, Text = "Target Body Parts", Callback = function()
    resetAllHitboxes()
end })

aiming:AddToggle("Triggerbot", { Text = "Triggerbot", Default = false }):AddKeyPicker("TriggerbotKey", { Default = "None", Mode = "Toggle", Text = "Triggerbot" })
aiming:AddSlider("TriggerDelay", { Text = "Delay", Default = 0.1, Min = 0.01, Max = 1, Rounding = 2 })

aiming:AddDivider()

local silentAimHooked = false
local function hookSilentAim()
    if silentAimHooked then return end
    silentAimHooked = true
    
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        
        if Toggles.SilentAim and Toggles.SilentAim.Value then
            if method == "Raycast" then
                local target = getSilentTarget()
                if target then
                    args[2] = (target.Position - args[1]).Unit * 1000
                    return oldNamecall(self, unpack(args))
                end
            elseif method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRayWithWhitelist" then
                 local target = getSilentTarget()
                 if target then
                    local origin = args[1].Origin
                    local newDir = (target.Position - origin).Unit * 1000
                    args[1] = Ray.new(origin, newDir)
                    return oldNamecall(self, unpack(args))
                end
            end
        end
        
        return oldNamecall(self, ...)
    end)
end

aiming:AddToggle("SilentAim", { Text = "Silent Aim", Default = false, Callback = function(v) 
    if v and not silentAimHooked then
        pcall(hookSilentAim)
    end
end }):AddKeyPicker("SilentAimKey", { Default = "None", Mode = "Toggle", Text = "Silent Aim" })
aiming:AddToggle("SilentVisible", { Text = "Visible Check", Default = true })

local r15Limbs = {
    "Head", "UpperTorso", "LowerTorso", "HumanoidRootPart",
    "LeftUpperArm", "LeftLowerArm", "LeftHand",
    "RightUpperArm", "RightLowerArm", "RightHand",
    "LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
    "RightUpperLeg", "RightLowerLeg", "RightFoot"
}
local limbOptions = {}
for _, v in ipairs(r15Limbs) do table.insert(limbOptions, v) end
table.insert(limbOptions, "Random")

aiming:AddDropdown("SilentLimbs", { Values = limbOptions, Default = "Head", Multi = true, Text = "Target Brand" })

aiming:AddToggle("FOVEnabled", { Text = "FOV Circle", Default = false }):AddColorPicker("FOVColor", { Default = Color3.fromRGB(255, 255, 255) })
aiming:AddSlider("FOVSize", { Text = "FOV Size", Default = 100, Min = 1, Max = 360, Rounding = 0 })
aiming:AddDropdown("FOVPosition", { Values = { "Center", "Follow Cursor" }, Default = "Center", Text = "FOV Position" })

mainVisuals:AddToggle("Chams", { Text = "Chams", Default = false }):AddColorPicker("ChamsColor", { Default = Color3.fromRGB(255, 255, 255) })
boxVisuals:AddToggle("BoxESP", { Text = "Box ESP", Default = false }):AddColorPicker("BoxColor", { Default = Color3.fromRGB(255, 255, 255) })
boxVisuals:AddDropdown("BoxType", { Values = { "2D", "3D" }, Default = "2D", Text = "Box Type" })

local function getTargetParts()
    local limbs = Options.HitboxLimbs.Value
    local parts = {}
    
    if limbs["Head"] then
        parts["Head"] = true
    end
    if limbs["Torso"] then
        parts["Torso"] = true
        parts["UpperTorso"] = true
        parts["LowerTorso"] = true
        parts["HumanoidRootPart"] = true
    end
    if limbs["Arms"] then
        parts["Left Arm"] = true
        parts["Right Arm"] = true
        parts["LeftUpperArm"] = true
        parts["LeftLowerArm"] = true
        parts["LeftHand"] = true
        parts["RightUpperArm"] = true
        parts["RightLowerArm"] = true
        parts["RightHand"] = true
    end
    if limbs["Legs"] then
        parts["Left Leg"] = true
        parts["Right Leg"] = true
        parts["LeftUpperLeg"] = true
        parts["LeftLowerLeg"] = true
        parts["LeftFoot"] = true
        parts["RightUpperLeg"] = true
        parts["RightLowerLeg"] = true
        parts["RightFoot"] = true
    end
    return parts
end

local function updateHitboxes()
    if not (Toggles.HitboxEnabled and Toggles.HitboxEnabled.Value) then return end
    
    local sizeVal = Options.HitboxSize.Value
    local transVal = Options.HitboxTrans.Value
    local targetSize = Vector3.new(sizeVal, sizeVal, sizeVal)
    local targetParts = getTargetParts()
    
    for _, player in pairs(plrs:GetPlayers()) do
        if player ~= lp and player.Character then
            for _, part in pairs(player.Character:GetChildren()) do
                if part:IsA("BasePart") and targetParts[part.Name] then
                    if part.Size ~= targetSize or part.Transparency ~= transVal then
                        pcall(function()
                            part.Size = targetSize
                            part.Transparency = transVal
                            part.CanCollide = false
                        end)
                    end
                end
            end
        end
    end
end

local lastFire = 0
local function updateTriggerbot()
    if not (Toggles.Triggerbot and Toggles.Triggerbot.Value) then return end
    
    local delay = Options.TriggerDelay.Value
    if tick() - lastFire < delay then return end
    
    local mouse = uis:GetMouseLocation()
    local ray = cam:ViewportPointToRay(mouse.X, mouse.Y)
    
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {lp.Character, cam}
    
    local result = Secure.Raycast(ray.Origin, ray.Direction * 1000, params)
    
    if result and result.Instance then
        local hit = result.Instance
        local model = hit:FindFirstAncestorOfClass("Model")
        if model then
            local player = plrs:GetPlayerFromCharacter(model)
            if player and player ~= lp then
                if player.TeamColor ~= lp.TeamColor then
                    vim:SendMouseButtonEvent(mouse.X, mouse.Y, 0, true, game, 1)
                    vim:SendMouseButtonEvent(mouse.X, mouse.Y, 0, false, game, 1)
                    lastFire = tick()
                end
            end
        end
    end
end

local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 1
fovCircle.Filled = false
fovCircle.Transparency = 1

local function updateFOV()
    if Toggles.FOVEnabled and Toggles.FOVEnabled.Value then
        fovCircle.Visible = true
        fovCircle.Radius = Options.FOVSize.Value
        fovCircle.Color = Options.FOVColor.Value
        
        if Options.FOVPosition.Value == "Follow Cursor" then
            fovCircle.Position = uis:GetMouseLocation()
        else
            fovCircle.Position = cam.ViewportSize / 2
        end
    else
        fovCircle.Visible = false
    end
end

local function isVisible(target, origin)
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    rayParams.FilterDescendantsInstances = {lp.Character, cam, target.Parent}
    
    local dir = target.Position - origin
    local result = Secure.Raycast(origin, dir, rayParams)
    
    if result then
        return false 
    end
    return true
end

local function getSilentTarget()
    if not (Toggles.SilentAim and Toggles.SilentAim.Value) then return nil end

    local r = Options.FOVSize.Value
    local origin = (Options.FOVPosition.Value == "Follow Cursor") and uis:GetMouseLocation() or (cam.ViewportSize / 2)
    local visibleCheck = Toggles.SilentVisible and Toggles.SilentVisible.Value
    local closest, minDist = nil, r

    for _, player in pairs(plrs:GetPlayers()) do
        if player ~= lp and player.Character and player.TeamColor ~= lp.TeamColor then
            local root = player.Character:FindFirstChild("HumanoidRootPart")
            if root then
                local pos, onScreen = cam:WorldToViewportPoint(root.Position)
                if onScreen then
                    local dist = (Vector2.new(pos.X, pos.Y) - origin).Magnitude
                    if dist < minDist then
                        if visibleCheck then
                            if isVisible(root, cam.CFrame.Position) then
                                closest = player
                                minDist = dist
                            end
                        else
                            closest = player
                            minDist = dist
                        end
                    end
                end
            end
        end
    end
    
    if closest and closest.Character then
        local validLimbs = {}
        local selected = Options.SilentLimbs.Value
        
        if selected["Random"] then
            local limb = closest.Character:FindFirstChild(r15Limbs[math.random(1, #r15Limbs)])
            if limb then return limb end
        else
            for name, _ in pairs(selected) do
                local limb = closest.Character:FindFirstChild(name)
                if limb then table.insert(validLimbs, limb) end
            end
        end
        
        if #validLimbs > 0 then
            if visibleCheck then
                for _, limb in ipairs(validLimbs) do
                    if isVisible(limb, cam.CFrame.Position) then
                        return limb
                    end
                end
            end
            return validLimbs[math.random(1, #validLimbs)]
        end
        return closest.Character:FindFirstChild("Head") 
    end
    return nil
end

local function updateESP()
    local doChams = Toggles.Chams and Toggles.Chams.Value
    local doBox = Toggles.BoxESP and Toggles.BoxESP.Value
    local bType = Options.BoxType and Options.BoxType.Value or "2D"
    local chamColor = Options.ChamsColor and Options.ChamsColor.Value or Color3.new(1, 1, 1)
    local boxColor = Options.BoxColor and Options.BoxColor.Value or Color3.new(1, 1, 1)
    
    for _, player in pairs(plrs:GetPlayers()) do
        if player ~= lp then
            local char = player.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                if not playerESPData[player] then
                    playerESPData[player] = {
                        box2D = Drawing.new("Square"),
                        box3D = {},
                    }
                    playerESPData[player].box2D.Thickness = 1
                    playerESPData[player].box2D.Filled = false
                    for i = 1, 12 do
                        table.insert(playerESPData[player].box3D, Drawing.new("Line"))
                    end
                end
                
                local data = playerESPData[player]
                local root = char.HumanoidRootPart
                local pos, screen = cam:WorldToViewportPoint(root.Position)
                
                if screen and doBox then
                    data.box2D.Color = boxColor
                    for _, l in pairs(data.box3D) do l.Color = boxColor end
                    
                    if bType == "2D" then
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
                        
                        local minX, minY = math.huge, math.huge
                        local maxX, maxY = -math.huge, -math.huge
                        for _, c in pairs(corners) do
                            local p, s = cam:WorldToViewportPoint(c.Position)
                            if s then
                                minX = math.min(minX, p.X)
                                minY = math.min(minY, p.Y)
                                maxX = math.max(maxX, p.X)
                                maxY = math.max(maxY, p.Y)
                            end
                        end
                        
                        data.box2D.Position = Vector2.new(minX, minY)
                        data.box2D.Size = Vector2.new(maxX - minX, maxY - minY)
                        data.box2D.Visible = true
                        for _, l in pairs(data.box3D) do l.Visible = false end
                    else
                        data.box2D.Visible = false
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
                        local sCorners = {}
                        for _, c in pairs(corners) do
                            local p = cam:WorldToViewportPoint(c.Position)
                            table.insert(sCorners, Vector2.new(p.X, p.Y))
                        end
                        local conns = {{1,2},{2,4},{4,3},{3,1},{5,6},{6,8},{8,7},{7,5},{1,5},{2,6},{3,7},{4,8}}
                        for i, c in pairs(conns) do
                            local l = data.box3D[i]
                            l.From = sCorners[c[1]]
                            l.To = sCorners[c[2]]
                            l.Visible = true
                        end
                    end
                else
                    data.box2D.Visible = false
                    for _, l in pairs(data.box3D) do l.Visible = false end
                end
                
                if doChams then
                    if not chamsData[player] then
                        local h = Instance.new("Highlight")
                        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        h.FillTransparency = 0.5
                        h.OutlineTransparency = 0
                        local cg = Secure.Service("CoreGui") or Secure.Service("Players").LocalPlayer:FindFirstChild("PlayerGui")
                        h.Parent = cg
                        chamsData[player] = h
                    end
                    chamsData[player].Adornee = char
                    chamsData[player].FillColor = chamColor
                    chamsData[player].OutlineColor = chamColor
                    chamsData[player].Enabled = true
                elseif chamsData[player] then
                    chamsData[player].Enabled = false
                end
            end
        end
    end
end

local conn = rs.RenderStepped:Connect(function()
    updateHitboxes()
    updateESP()
    updateTriggerbot()
    updateFOV()
end)

cfgBox:AddToggle("KeyMenu", { Default = lib.KeybindFrame.Visible, Text = "Keybind Menu", Callback = function(v) lib.KeybindFrame.Visible = v end })
cfgBox:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { Default = "RightControl", NoUI = true, Text = "Menu bind" })
lib.ToggleKeybind = Options.MenuKeybind

theme:SetLibrary(lib)
save:SetLibrary(lib)
save:IgnoreThemeSettings()
save:SetIgnoreIndexes({ "MenuKeybind" })
theme:SetFolder("PlowsScriptHub")
save:SetFolder("PlowsScriptHub/MvSDuels")
save:BuildConfigSection(config)
theme:ApplyToTab(config)
save:LoadAutoloadConfig()

lib:OnUnload(function()
    if conn then conn:Disconnect() end
    for _, data in pairs(playerESPData) do
        data.box2D:Remove()
        for _, l in pairs(data.box3D) do l:Remove() end
    end
    if fovCircle then fovCircle:Remove() end
    for _, h in pairs(chamsData) do h:Destroy() end
    for _, player in pairs(plrs:GetPlayers()) do
        resetHitboxForPlayer(player)
    end
end)
