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
        end
        return old_nc(self, ...)
    end)
    
    gm.__index = newcclosure(function(self, k)
        if not checkcaller() then
            if k == "Drawing" then return nil end
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
local lp = plrs.LocalPlayer
local cam = workspace.CurrentCamera

theme.BuiltInThemes["Default"][2] = {
    BackgroundColor = "16293a",
    MainColor = "26445f",
    AccentColor = "5983a0",
    OutlineColor = "325573",
    FontColor = "d2dae1"
}

local win = lib:CreateWindow({
    Title = "Axis Hub - Operation One.lua",
    Footer = "by RwalDev & Plow | 2.7.4 | Discord: .gg/UuyxhqgEVs",
    NotifySide = "Right",
    ShowCustomCursor = true,
})


local home = win:AddTab("Home", "house")
local main = win:AddTab("Main", "target")
local config = win:AddTab("Settings", "settings")

local status = home:AddLeftGroupbox("Status")
local visuals = main:AddLeftGroupbox("Visuals")
local cfgBox = config:AddLeftGroupbox("Config")

status:AddLabel(string.format("Welcome, %s\nGame: Operation One", lp.DisplayName), true)
status:AddButton({ Text = "Unload", Func = function() lib:Unload() end })





visuals:AddToggle("ESPEnabled", { Text = "General ESP Toggle", Default = false }):AddKeyPicker("ESPKey", { Default = "None", SyncToggleState = true, Mode = "Toggle", Text = "ESP" })
visuals:AddToggle("BoxESP", { Text = "Box", Default = true }):AddKeyPicker("BoxKey", { Default = "None", SyncToggleState = true, Mode = "Toggle", Text = "Box" })
visuals:AddToggle("BoxOutline", { Text = "Box Outline", Default = true })
visuals:AddToggle("TracerESP", { Text = "Tracer", Default = true }):AddKeyPicker("TracerKey", { Default = "None", SyncToggleState = true, Mode = "Toggle", Text = "Tracer" })
visuals:AddToggle("TracerOutline", { Text = "Tracer Outline", Default = true })
visuals:AddDropdown("TracerPos", { Values = { "Bottom", "Center", "Top" }, Default = "Bottom", Text = "Tracer Position", Callback = function(v) 
    if v == "Bottom" then tracerType = 1 elseif v == "Center" then tracerType = 2 else tracerType = 3 end
end })
visuals:AddToggle("HealthBar", { Text = "Health Bar", Default = true }):AddKeyPicker("HealthKey", { Default = "None", SyncToggleState = true, Mode = "Toggle", Text = "Health Bar" })
visuals:AddToggle("HealthOutline", { Text = "Health Bar Outline", Default = true })
visuals:AddToggle("NameESP", { Text = "Name", Default = true }):AddKeyPicker("NameKey", { Default = "None", SyncToggleState = true, Mode = "Toggle", Text = "Name" })
visuals:AddToggle("DroneESP", { Text = "Drone ESP", Default = true }):AddKeyPicker("DroneKey", { Default = "None", SyncToggleState = true, Mode = "Toggle", Text = "Drone" })
visuals:AddToggle("DroneOutline", { Text = "Drone Outline", Default = true })
visuals:AddToggle("Chams", { Text = "Chams", Default = false }):AddKeyPicker("ChamsKey", { Default = "None", SyncToggleState = true, Mode = "Toggle", Text = "Chams" }):AddColorPicker("ChamsColor", { Default = Color3.fromRGB(255, 50, 50), Title = "Chams Color" })

local tracerType = 1
local Toggles = lib.Toggles
local Options = lib.Options
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

    local espOn = Toggles.ESPEnabled and Toggles.ESPEnabled.Value
    local boxOn = Toggles.BoxESP and Toggles.BoxESP.Value
    local boxOutOn = Toggles.BoxOutline and Toggles.BoxOutline.Value
    local tracerOn = Toggles.TracerESP and Toggles.TracerESP.Value
    local tracerOutOn = Toggles.TracerOutline and Toggles.TracerOutline.Value
    local healthOn = Toggles.HealthBar and Toggles.HealthBar.Value
    local healthOutOn = Toggles.HealthOutline and Toggles.HealthOutline.Value
    local nameOn = Toggles.NameESP and Toggles.NameESP.Value

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

    local chamsOn = Toggles.Chams and Toggles.Chams.Value
    local chamsColor = Options.ChamsColor and Options.ChamsColor.Value or Color3.new(1, 0.2, 0.2)

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

    local espOn = Toggles.ESPEnabled and Toggles.ESPEnabled.Value
    local droneOn = Toggles.DroneESP and Toggles.DroneESP.Value
    local droneOutOn = Toggles.DroneOutline and Toggles.DroneOutline.Value

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

local function charhook(plr)
    local char = plr.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then hum.Died:Connect(function() removeplr(plr.Name) end) end
end

plrs.PlayerRemoving:Connect(function(plr) removeplr(plr.Name) end)
plrs.PlayerAdded:Connect(function(plr) plr.CharacterAdded:Connect(function() charhook(plr) end) end)
for _, plr in ipairs(plrs:GetPlayers()) do if plr.Character then charhook(plr) end end

local mainLoop = rs.RenderStepped:Connect(function()
    local espOn = Toggles.ESPEnabled and Toggles.ESPEnabled.Value

    local enemies, drones = getenemies()
    local alive = {}
    
    if espOn then
        for _, e in pairs(enemies) do alive[e.Name] = true mainESP(e) end
        for _, d in pairs(drones) do drone_esp(d) end
    end

    for name, _ in pairs(espboxes) do if not alive[name] then removeplr(name) end end
    for drone, _ in pairs(espdrones) do if not drone or not drone:IsDescendantOf(workspace) or not (espOn and Toggles.DroneESP.Value) then removedrone(drone) end end
end)
cfgBox:AddToggle("KeyMenu", { Default = lib.KeybindFrame.Visible, Text = "Keybind Menu", Callback = function(v) lib.KeybindFrame.Visible = v end })
cfgBox:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { Default = "RightControl", NoUI = true, Text = "Menu bind" })
lib.ToggleKeybind = lib.Options.MenuKeybind



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
    for name, _ in pairs(espboxes) do removeplr(name) end
    for drone, _ in pairs(espdrones) do removedrone(drone) end
    if Storage then Storage:Destroy() end
end)

pcall(bypass)
