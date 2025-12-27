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
        
        if not checkcaller() then
            if (method == "GetService" or method == "getService") and self == g then
                local s = args[1]
                if s == "VirtualInputManager" or s == "HttpService" or s == "LogService" or s == "Drawing" then
                    return nil
                end
            end
            
            if method == "Kick" and self == lp then return nil end
        end
        
        return old_nc(self, ...)
    end)
    
    local old_idx
    old_idx = hookmetamethod(g, "__index", newcclosure(function(self, k)
        if not checkcaller() then
            if k == "Drawing" or k == "VirtualInputManager" then
                return nil
            end
        end
        return old_idx(self, k)
    end))

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
local lp = plrs.LocalPlayer
local cam = workspace.CurrentCamera
local mouse = lp:GetMouse()
local vim = get("VirtualInputManager")
local statsService = get("Stats")

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
local main = win:AddTab("Main", "target")
local config = win:AddTab("Settings", "settings")

local status = home:AddLeftGroupbox("Status")
local stats = home:AddRightGroupbox("FPS & Ping")
local aiming = main:AddLeftGroupbox("Aiming")
local checks = main:AddLeftGroupbox("Checks")
local visuals = main:AddRightGroupbox("Visuals")
local cfgBox = config:AddLeftGroupbox("Config")

status:AddLabel(string.format("Welcome, %s\nGame: Operation One", lp.DisplayName), true)
status:AddButton({ Text = "Unload", Func = function() lib:Unload() end })

local fpsLbl = stats:AddLabel("FPS: ...", true)
local pingLbl = stats:AddLabel("Ping: ...", true)

local triggerDelay = 0.32
local aimPart = "Head"
local tracerType = 1

local bodyParts = {
    "Random", "Closest", "Center",
    "Head", "Torso", "HumanoidRootPart",
    "UpperTorso", "LowerTorso",
    "LeftUpperArm", "RightUpperArm", "LeftLowerArm", "RightLowerArm",
    "LeftHand", "RightHand", "LeftUpperLeg", "RightUpperLeg",
    "LeftLowerLeg", "RightLowerLeg", "LeftFoot", "RightFoot"
}

aiming:AddToggle("Triggerbot", { Text = "Triggerbot", Default = false }):AddKeyPicker("TriggerbotKey", { Default = "None", Mode = "Toggle", Text = "Triggerbot" })
aiming:AddSlider("TriggerDelay", { Text = "Triggerbot Delay", Default = 0.32, Min = 0.01, Max = 1, Rounding = 2, Callback = function(v) triggerDelay = v end })
aiming:AddDivider()
aiming:AddToggle("Aimbot", { Text = "Aimbot", Default = false }):AddKeyPicker("AimbotKey", { Default = "None", Mode = "Toggle", Text = "Aimbot" })
aiming:AddDropdown("AimPart", { Values = bodyParts, Default = "Head", Text = "Aim Part", Callback = function(v) aimPart = v end })

visuals:AddToggle("ESPEnabled", { Text = "General ESP Toggle", Default = false }):AddKeyPicker("ESPKey", { Default = "None", Mode = "Toggle", Text = "ESP" })
visuals:AddToggle("BoxESP", { Text = "Box", Default = true }):AddKeyPicker("BoxKey", { Default = "None", Mode = "Toggle", Text = "Box" })
visuals:AddToggle("BoxOutline", { Text = "Box Outline", Default = true })
visuals:AddToggle("TracerESP", { Text = "Tracer", Default = true }):AddKeyPicker("TracerKey", { Default = "None", Mode = "Toggle", Text = "Tracer" })
visuals:AddToggle("TracerOutline", { Text = "Tracer Outline", Default = true })
visuals:AddDropdown("TracerPos", { Values = { "Bottom", "Center", "Top" }, Default = "Bottom", Text = "Tracer Position", Callback = function(v) 
    if v == "Bottom" then tracerType = 1 elseif v == "Center" then tracerType = 2 else tracerType = 3 end
end })
visuals:AddToggle("HealthBar", { Text = "Health Bar", Default = true }):AddKeyPicker("HealthKey", { Default = "None", Mode = "Toggle", Text = "Health Bar" })
visuals:AddToggle("HealthOutline", { Text = "Health Bar Outline", Default = true })
visuals:AddToggle("NameESP", { Text = "Name", Default = true }):AddKeyPicker("NameKey", { Default = "None", Mode = "Toggle", Text = "Name" })
visuals:AddToggle("DroneESP", { Text = "Drone ESP", Default = true }):AddKeyPicker("DroneKey", { Default = "None", Mode = "Toggle", Text = "Drone" })
visuals:AddToggle("DroneOutline", { Text = "Drone Outline", Default = true })
visuals:AddToggle("Chams", { Text = "Chams", Default = false }):AddKeyPicker("ChamsKey", { Default = "None", Mode = "Toggle", Text = "Chams" }):AddColorPicker("ChamsColor", { Default = Color3.fromRGB(255, 50, 50), Title = "Chams Color" })

checks:AddToggle("WallCheck", { Text = "Wall Check", Default = true })
checks:AddToggle("TeamCheck", { Text = "Team Check", Default = true })
checks:AddToggle("ForceFieldCheck", { Text = "ForceField Check", Default = true })
checks:AddToggle("AliveCheck", { Text = "Alive Check", Default = true })

local espboxes = {}
local espboxoutlines = {}
local esptracers = {}
local esptraceroutlines = {}
local esphealthbars = {}
local esphealthbaroutlines = {}
local espnames = {}
local espdrones = {}
local espdroneoutlines = {}
local espchams = {}

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

local screensize = cam.ViewportSize
local screenpositions = {
    Vector2.new(screensize.X / 2, screensize.Y),
    Vector2.new(screensize.X / 2, screensize.Y / 2),
    Vector2.new(screensize.X / 2, 0)
}

local function removeplr(name)
    if espboxes[name] then espboxes[name]:Remove() espboxes[name] = nil end
    if espboxoutlines[name] then espboxoutlines[name]:Remove() espboxoutlines[name] = nil end
    if esptracers[name] then esptracers[name]:Remove() esptracers[name] = nil end
    if esptraceroutlines[name] then esptraceroutlines[name]:Remove() esptraceroutlines[name] = nil end
    if esphealthbars[name] then esphealthbars[name]:Remove() esphealthbars[name] = nil end
    if esphealthbaroutlines[name] then esphealthbaroutlines[name]:Remove() esphealthbaroutlines[name] = nil end
    if espnames[name] then espnames[name]:Remove() espnames[name] = nil end
    if espchams[name] then espchams[name]:Destroy() espchams[name] = nil end
end

local function removedrone(drone)
    if espdrones[drone] then espdrones[drone]:Remove() espdrones[drone] = nil end
    if espdroneoutlines[drone] then espdroneoutlines[drone]:Remove() espdroneoutlines[drone] = nil end
end

local function getenemies()
    local team = lp.Team
    local enemies = {}
    for _, plr in pairs(plrs:GetPlayers()) do
        if plr.Character and plr.Team ~= team and plr ~= lp then
            local hum = plr.Character:FindFirstChild("Humanoid")
            if hum and hum.Health > 0 then
                table.insert(enemies, plr.Character)
            end
        end
    end
    local drones = {}
    for _, v in pairs(workspace:GetChildren()) do
        if v.Name == "Drone" then
            table.insert(drones, v)
        end
    end
    return enemies, drones
end

local function getCharMinMax(char)
    local minX, maxX = math.huge, -math.huge
    local minY, maxY = math.huge, -math.huge
    for _, part in pairs(char:GetChildren()) do
        if part:IsA("BasePart") then
            local cf = part.CFrame
            local size = part.Size / 2
            local corners = {
                Vector3.new(-size.X, -size.Y, -size.Z), Vector3.new(-size.X, -size.Y, size.Z),
                Vector3.new(-size.X, size.Y, -size.Z), Vector3.new(-size.X, size.Y, size.Z),
                Vector3.new(size.X, -size.Y, -size.Z), Vector3.new(size.X, -size.Y, size.Z),
                Vector3.new(size.X, size.Y, -size.Z), Vector3.new(size.X, size.Y, size.Z),
            }
            for _, offset in pairs(corners) do
                local worldPoint = cf:PointToWorldSpace(offset)
                local screenPos, onScreen = cam:WorldToViewportPoint(worldPoint)
                if onScreen then
                    minX = math.min(minX, screenPos.X)
                    maxX = math.max(maxX, screenPos.X)
                    minY = math.min(minY, screenPos.Y)
                    maxY = math.max(maxY, screenPos.Y)
                end
            end
        end
    end
    return maxX, maxY, minX, minY
end

local function torture(char)
    local maxX, maxY, minX, minY = getCharMinMax(char)
    local topleft = Vector2.new(minX, minY)
    local boxCFrame, boxSize = char:GetBoundingBox()
    local topCenterWorld = boxCFrame.Position + boxCFrame.UpVector * (boxSize.Y / 2)
    local camLeft = -cam.CFrame.RightVector
    local p0, on0 = cam:WorldToViewportPoint(topCenterWorld)
    local pL, onL = cam:WorldToViewportPoint(topCenterWorld + camLeft * 0.3)
    if not (on0 and onL) then return topleft, topleft end
    local LOffset = Vector2.new(pL.X - p0.X, pL.Y - p0.Y)
    return topleft, topleft + LOffset
end

local function mainESP(target)
    if not target or not target:IsA("Model") then return end

    local espOn = lib.Toggles.ESPEnabled and lib.Toggles.ESPEnabled.Value
    local boxOn = lib.Toggles.BoxESP and lib.Toggles.BoxESP.Value
    local boxOutOn = lib.Toggles.BoxOutline and lib.Toggles.BoxOutline.Value
    local tracerOn = lib.Toggles.TracerESP and lib.Toggles.TracerESP.Value
    local tracerOutOn = lib.Toggles.TracerOutline and lib.Toggles.TracerOutline.Value
    local healthOn = lib.Toggles.HealthBar and lib.Toggles.HealthBar.Value
    local healthOutOn = lib.Toggles.HealthOutline and lib.Toggles.HealthOutline.Value
    local nameOn = lib.Toggles.NameESP and lib.Toggles.NameESP.Value

    local maxX, maxY, minX, minY = getCharMinMax(target)
    local name = target.Name

    if not espboxoutlines[name] then
        espboxoutlines[name] = Drawing.new("Square")
        espboxoutlines[name].Transparency = 0.5
        espboxoutlines[name].Color = Color3.new(0, 0, 0)
        espboxoutlines[name].Thickness = 2
        espboxoutlines[name].Filled = false
    end
    if not espboxes[name] then
        espboxes[name] = Drawing.new("Square")
        espboxes[name].Transparency = 0.5
        espboxes[name].Color = Color3.new(1, 1, 1)
        espboxes[name].Thickness = 1
        espboxes[name].Filled = false
    end

    espboxes[name].Size = Vector2.new(maxX - minX, maxY - minY)
    espboxes[name].Position = Vector2.new(minX, minY)
    espboxes[name].Visible = espOn and boxOn
    espboxoutlines[name].Size = Vector2.new(maxX - minX, maxY - minY)
    espboxoutlines[name].Position = Vector2.new(minX, minY)
    espboxoutlines[name].Visible = espOn and boxOn and boxOutOn

    if not esptraceroutlines[name] then
        esptraceroutlines[name] = Drawing.new("Line")
        esptraceroutlines[name].Color = Color3.new(0, 0, 0)
        esptraceroutlines[name].Thickness = 2
    end
    if not esptracers[name] then
        esptracers[name] = Drawing.new("Line")
        esptracers[name].Color = Color3.new(1, 1, 1)
        esptracers[name].Thickness = 1
    end

    esptraceroutlines[name].From = screenpositions[tracerType]
    esptracers[name].From = screenpositions[tracerType]
    esptraceroutlines[name].To = Vector2.new(minX + (maxX - minX) / 2, minY)
    esptracers[name].To = Vector2.new(minX + (maxX - minX) / 2, minY)
    esptracers[name].Visible = espOn and tracerOn
    esptraceroutlines[name].Visible = espOn and tracerOn and tracerOutOn

    if not esphealthbaroutlines[name] then
        esphealthbaroutlines[name] = Drawing.new("Square")
        esphealthbaroutlines[name].Color = Color3.new(0, 0, 0)
        esphealthbaroutlines[name].Thickness = 2
        esphealthbaroutlines[name].Filled = false
    end
    if not esphealthbars[name] then
        esphealthbars[name] = Drawing.new("Square")
        esphealthbars[name].Color = Color3.new(0, 1, 0)
        esphealthbars[name].Thickness = 1
        esphealthbars[name].Filled = true
    end

    local topleft, width = torture(target)
    local hWidth = (topleft - width).Magnitude
    local hum = target:FindFirstChild("Humanoid")
    local healthPct = hum and (hum.Health / hum.MaxHealth) or 1
    local targethealthloss = Vector2.new(0, (maxY - minY) * (1 - healthPct))

    esphealthbars[name].Size = Vector2.new(hWidth, (maxY - minY)) - targethealthloss
    esphealthbars[name].Position = Vector2.new(topleft.X - hWidth, minY) + targethealthloss
    esphealthbars[name].Visible = espOn and healthOn
    esphealthbaroutlines[name].Size = Vector2.new(hWidth, (maxY - minY)) - targethealthloss
    esphealthbaroutlines[name].Position = Vector2.new(topleft.X - hWidth, minY) + targethealthloss
    esphealthbaroutlines[name].Visible = espOn and healthOn and healthOutOn

    if not espnames[name] then
        espnames[name] = Drawing.new("Text")
        espnames[name].Color = Color3.new(1, 1, 1)
        espnames[name].Text = name
        espnames[name].Size = 12
        espnames[name].Center = true
        espnames[name].Outline = true
        espnames[name].OutlineColor = Color3.new(0, 0, 0)
    end

    espnames[name].Position = Vector2.new(minX + (maxX - minX) / 2, minY - espnames[name].TextBounds.Y - 3)
    espnames[name].Visible = espOn and nameOn

    local chamsOn = lib.Toggles.Chams and lib.Toggles.Chams.Value
    local chamsColor = lib.Options.ChamsColor and lib.Options.ChamsColor.Value or Color3.new(1, 0.2, 0.2)

    if not espchams[name] then
        local h = Instance.new("Highlight")
        h.Name = name
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        h.FillTransparency = 0.55
        h.OutlineTransparency = 0
        h.OutlineColor = Color3.new(1, 1, 1)
        h.Parent = Storage
        espchams[name] = h
    end
    espchams[name].Adornee = target
    espchams[name].FillColor = chamsColor
    espchams[name].Enabled = espOn and chamsOn
end

local function drone_esp(target)
    if not target or not target:IsA("Model") or not target:IsDescendantOf(workspace) then
        removedrone(target)
        return
    end

    local espOn = lib.Toggles.ESPEnabled and lib.Toggles.ESPEnabled.Value
    local droneOn = lib.Toggles.DroneESP and lib.Toggles.DroneESP.Value
    local droneOutOn = lib.Toggles.DroneOutline and lib.Toggles.DroneOutline.Value

    local maxX, maxY, minX, minY = getCharMinMax(target)

    if not espdroneoutlines[target] then
        espdroneoutlines[target] = Drawing.new("Square")
        espdroneoutlines[target].Transparency = 0.5
        espdroneoutlines[target].Color = Color3.new(0, 0, 0)
        espdroneoutlines[target].Thickness = 2
        espdroneoutlines[target].Filled = false
    end
    if not espdrones[target] then
        espdrones[target] = Drawing.new("Square")
        espdrones[target].Transparency = 0.5
        espdrones[target].Color = Color3.new(1, 0, 0)
        espdrones[target].Thickness = 1
        espdrones[target].Filled = false
    end

    espdrones[target].Size = Vector2.new(maxX - minX, maxY - minY)
    espdrones[target].Position = Vector2.new(minX, minY)
    espdrones[target].Visible = espOn and droneOn
    espdroneoutlines[target].Size = Vector2.new(maxX - minX, maxY - minY)
    espdroneoutlines[target].Position = Vector2.new(minX, minY)
    espdroneoutlines[target].Visible = espOn and droneOn and droneOutOn
end

local function worldToScreen(pos)
    local vec, onScreen = cam:WorldToViewportPoint(pos)
    return Vector2.new(vec.X, vec.Y), onScreen, vec.Z
end

local function getClosestPart(char)
    local closest, dist = nil, math.huge
    for _, p in pairs(char:GetDescendants()) do
        if p:IsA("BasePart") then
            local screenPos, onScreen = worldToScreen(p.Position)
            if onScreen then
                local center = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
                local d = (screenPos - center).Magnitude
                if d < dist then dist = d closest = p end
            end
        end
    end
    return closest
end

local function getRandomPart(char)
    local parts = {}
    for _, p in pairs(char:GetDescendants()) do
        if p:IsA("BasePart") then table.insert(parts, p) end
    end
    return #parts > 0 and parts[math.random(1, #parts)] or nil
end

local function getCenterPart(char)
    local cf, size = char:GetBoundingBox()
    local closest, dist = nil, math.huge
    for _, p in pairs(char:GetDescendants()) do
        if p:IsA("BasePart") then
            local d = (p.Position - cf.Position).Magnitude
            if d < dist then dist = d closest = p end
        end
    end
    return closest
end

local function findPartInModel(char, name)
    local part = char:FindFirstChild(name, true)
    if part and part:IsA("BasePart") then return part end
    for _, p in pairs(char:GetDescendants()) do
        if p:IsA("BasePart") and p.Name:lower():find(name:lower()) then return p end
    end
    return nil
end

local function isVisible(part, char)
    if not part then return false end
    local origin = cam.CFrame.Position
    local direction = part.Position - origin
    
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {lp.Character}
    params.FilterType = Enum.RaycastFilterType.Blacklist
    
    local result = workspace:Raycast(origin, direction, params)
    
    if result then
        local hit = result.Instance
        if hit and (hit:IsDescendantOf(char) or hit == part) then return true end
        return false
    end
    return true
end

local function hasForceField(char)
    return char:FindFirstChildOfClass("ForceField") ~= nil
end

local function passesChecks(player, char)
    local wallCheck = lib.Toggles.WallCheck and lib.Toggles.WallCheck.Value
    local teamCheck = lib.Toggles.TeamCheck and lib.Toggles.TeamCheck.Value
    local ffCheck = lib.Toggles.ForceFieldCheck and lib.Toggles.ForceFieldCheck.Value
    local aliveCheck = lib.Toggles.AliveCheck and lib.Toggles.AliveCheck.Value
    
    if aliveCheck then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health <= 0 then return false end
    end
    if teamCheck and player.Team == lp.Team then return false end
    if ffCheck and hasForceField(char) then return false end
    if wallCheck then
        local cf, size = char:GetBoundingBox()
        local testPart = {Position = cf.Position}
        if not isVisible(testPart, char) then return false end
    end
    return true
end

local function getAimTarget()
    local closest, dist = nil, math.huge
    for _, p in pairs(plrs:GetPlayers()) do
        if p ~= lp then
            local char = p.Character
            if char and passesChecks(p, char) then
                local cf, size = char:GetBoundingBox()
                local screenPos, onScreen = worldToScreen(cf.Position)
                if onScreen then
                    local center = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
                    local d = (screenPos - center).Magnitude
                    if d < dist then dist = d closest = char end
                end
            end
        end
    end
    return closest
end

local function getTargetPart(char)
    if aimPart == "Random" then return getRandomPart(char)
    elseif aimPart == "Closest" then return getClosestPart(char)
    elseif aimPart == "Center" then return getCenterPart(char)
    else
        local part = findPartInModel(char, aimPart)
        if part then return part end
        return getCenterPart(char)
    end
end

local function charhook(plr)
    local char = plr.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then hum.Died:Connect(function() removeplr(plr.Name) end) end
end

plrs.PlayerRemoving:Connect(function(plr) removeplr(plr.Name) end)
plrs.PlayerAdded:Connect(function(plr) plr.CharacterAdded:Connect(function() charhook(plr) end) end)
for _, plr in ipairs(plrs:GetPlayers()) do if plr.Character then charhook(plr) end end

local lastTrigger = 0
local mainLoop = rs.RenderStepped:Connect(function()
    local aimbotOn = lib.Toggles.Aimbot and lib.Toggles.Aimbot.Value
    local triggerOn = lib.Toggles.Triggerbot and lib.Toggles.Triggerbot.Value

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
            local origin = cam.CFrame.Position
            local direction = cam.CFrame.LookVector * 1000
            
            local params = RaycastParams.new()
            params.FilterDescendantsInstances = {lp.Character}
            params.FilterType = Enum.RaycastFilterType.Blacklist
            
            local result = workspace:Raycast(origin, direction, params)
            
            if result then
                local hit = result.Instance
                local model = hit:FindFirstAncestorOfClass("Model")
                local isEnemy = model and plrs:GetPlayerFromCharacter(model)
                if not isEnemy and model then
                    local parent = model.Parent
                    if parent and parent:IsA("Model") then
                        isEnemy = plrs:GetPlayerFromCharacter(parent)
                    end
                end
                if isEnemy and isEnemy ~= lp then
                    if vim then
                        vim:SendMouseButtonEvent(0, 0, 0, true, game, 1)
                        task.wait(0.01)
                        vim:SendMouseButtonEvent(0, 0, 0, false, game, 1)
                    else
                        local tool = lp.Character and lp.Character:FindFirstChildOfClass("Tool")
                        if tool then tool:Activate() end
                    end
                    lastTrigger = now
                end
            end
        end
    end

    local enemies, drones = getenemies()
    local alive = {}
    for _, e in pairs(enemies) do alive[e.Name] = true mainESP(e) end
    for _, d in pairs(drones) do drone_esp(d) end

    for name, _ in pairs(espboxes) do if not alive[name] then removeplr(name) end end
    for name, _ in pairs(espboxoutlines) do if not alive[name] then removeplr(name) end end
    for name, _ in pairs(esptracers) do if not alive[name] then removeplr(name) end end
    for name, _ in pairs(esptraceroutlines) do if not alive[name] then removeplr(name) end end
    for name, _ in pairs(esphealthbars) do if not alive[name] then removeplr(name) end end
    for name, _ in pairs(esphealthbaroutlines) do if not alive[name] then removeplr(name) end end
    for name, _ in pairs(espnames) do if not alive[name] then removeplr(name) end end

    for drone, _ in pairs(espdrones) do if not drone or not drone:IsDescendantOf(workspace) then removedrone(drone) end end
    for drone, _ in pairs(espdroneoutlines) do if not drone or not drone:IsDescendantOf(workspace) then removedrone(drone) end end
end)

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
save:SetFolder("PlowsScriptHub/OperationOne")
save:BuildConfigSection(config)
theme:ApplyToTab(config)
save:LoadAutoloadConfig()

lib:OnUnload(function()
    if mainLoop then mainLoop:Disconnect() end
    if conn then conn:Disconnect() end
    for name, _ in pairs(espboxes) do removeplr(name) end
    for drone, _ in pairs(espdrones) do removedrone(drone) end
    if Storage then Storage:Destroy() end
end)
