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
    local old_ns = gm.__newindex
    
    setreadonly(gm, false)
    
    gm.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        if not checkcaller() then
            if method == "Kick" and self == lp then return nil end
            if method == "GetService" or method == "getService" then
                local s = args[1]
                if s == "VirtualInputManager" or s == "HttpService" or s == "TeleportService" or s == "GuiService" then
                    return Instance.new("Folder")
                end
            end
            if method == "OpenBrowserWindow" or method == "OpenVideo" then return nil end
        end
        return old_nc(self, ...)
    end)
    
    gm.__index = newcclosure(function(self, k)
        if not checkcaller() then
            if k == "Drawing" or k == "VirtualInputManager" or k == "HttpService" or k == "TeleportService" or k == "GuiService" then
                return Instance.new("Folder")
            end
        end
        return old_idx(self, k)
    end)
    
    gm.__newindex = newcclosure(function(self, k, v)
        if not checkcaller() then
            if k == "Enabled" and (self:IsA("Script") or self:IsA("LocalScript")) then
                return
            end
        end
        return old_ns(self, k, v)
    end)
    
    setreadonly(gm, true)
    
    local oldHttpGet = g.HttpGet
    g.HttpGet = function(self, url, ...)
        if not checkcaller() then return "" end
        return oldHttpGet(self, url, ...)
    end
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

local plrs = get("Players")
local rs = get("RunService")
local uis = get("UserInputService")
local stats = get("Stats")
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
    Title = "Axis Hub - Blind Shot.lua",
    Footer = "by RwalDev & Plow | 1.9.8 | Discord: .gg/UuyxhqgEVs",
    NotifySide = "Right",
    ShowCustomCursor = true,
})

local homeTab = win:AddTab("Home", "house")
local mainTab = win:AddTab("Main", "crosshair")
local miscTab = win:AddTab("Misc", "box")
local settingsTab = win:AddTab("Settings", "settings")

local status = homeTab:AddLeftGroupbox("Status")
status:AddLabel(string.format("Welcome, %s\nGame: Blind Shot", lp.DisplayName), true)
status:AddButton({ Text = "Unload Script", Func = function() lib:Unload() end })

local performance = homeTab:AddRightGroupbox("Performance")
local fpsLbl = performance:AddLabel("FPS: ...", true)
local pingLbl = performance:AddLabel("Ping: ...", true)

local elap, frames = 0, 0
local perfConn = rs.RenderStepped:Connect(function(dt)
    frames = frames + 1
    elap = elap + dt
    if elap >= 1 then
        fpsLbl:SetText("FPS: " .. math.floor(frames / elap + 0.5))
        local net = stats.Network.ServerStatsItem["Data Ping"]
        pingLbl:SetText("Ping: " .. (net and math.floor(net:GetValue()) or 0) .. " ms")
        frames, elap = 0, 0
    end
end)

local trophyBox = mainTab:AddLeftGroupbox("Auto Trophy")
trophyBox:AddToggle("TrophyTeleport", { Text = "Auto Trophy (Teleport)", Default = false }):AddKeyPicker("TrophyTeleportKey", { Default = "None", SyncToggleState = true, Mode = "Toggle", Text = "Auto Trophy" })
trophyBox:AddToggle("TrophyTouch", { Text = "Auto Trophy (Touch)", Default = false })
trophyBox:AddLabel("Recommended: Teleport method")

task.spawn(function()
    while task.wait() do
        if lib.Toggles.TrophyTeleport and lib.Toggles.TrophyTeleport.Value then
            local char = lp.Character
            local trophy = workspace:FindFirstChild("Trophy", true)
            if char and trophy and trophy:IsA("BasePart") then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.CFrame = trophy.CFrame
                end
            end
        end
        if lib.Toggles.TrophyTouch and lib.Toggles.TrophyTouch.Value then
            local char = lp.Character
            local trophy = workspace:FindFirstChild("Trophy", true)
            if char and trophy and trophy:IsA("BasePart") and firetouchinterest then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    firetouchinterest(hrp, trophy, 0)
                    task.wait()
                    firetouchinterest(hrp, trophy, 1)
                end
            end
        end
    end
end)

local aimBox = mainTab:AddRightGroupbox("Auto Aim")
aimBox:AddToggle("AutoAim", { Text = "Auto Aim", Default = false }):AddKeyPicker("AutoAimKey", { Default = "None", SyncToggleState = true, Mode = "Toggle", Text = "Auto Aim" })
aimBox:AddDropdown("AimPart", { Values = { "Head", "HumanoidRootPart" }, Default = "Head", Text = "Aim Part" })

task.spawn(function()
    while task.wait() do
        if lib.Toggles.AutoAim and lib.Toggles.AutoAim.Value then
            local char = lp.Character
            if char then
                local head = char:FindFirstChild("Head")
                if head then
                    local target = nil
                    local dist = 9999
                    for _, player in pairs(plrs:GetPlayers()) do
                        if player ~= lp and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
                            local part = player.Character:FindFirstChild(lib.Options.AimPart.Value)
                            if part then
                                local d = (head.Position - part.Position).Magnitude
                                if d < dist then
                                    dist = d
                                    target = part
                                end
                            end
                        end
                    end
                    if target then
                        cam.CFrame = CFrame.new(cam.CFrame.Position, target.Position)
                    end
                end
            end
        end
    end
end)

local visualsBox = mainTab:AddLeftGroupbox("Visuals")
visualsBox:AddToggle("EnableBox", { Text = "Box ESP", Default = false })
visualsBox:AddDropdown("BoxType", { Values = { "2D", "3D" }, Default = "2D", Text = "Box Type" })
visualsBox:AddToggle("EnableChams", { Text = "Chams", Default = false }):AddColorPicker("ChamsColor", { Default = Color3.fromRGB(255, 255, 255), Title = "Chams Color" })

local playerESPData = {}
local chamsData = {}

-- Helper function to clean up all ESP data
local function cleanupAllESP()
    for player, data in pairs(playerESPData) do
        if data.box2D and data.box2D.Remove then
            data.box2D:Remove()
        end
        if data.text and data.text.Remove then
            data.text:Remove()
        end
        if data.box3D then
            for _, line in ipairs(data.box3D) do
                if line.Remove then line:Remove() end
            end
        end
    end
    table.clear(playerESPData)
    
    for player, highlight in pairs(chamsData) do
        if highlight and highlight.Destroy then
            highlight:Destroy()
        end
    end
    table.clear(chamsData)
end

local function updatePlayerESP()
    local chams = lib.Toggles.EnableChams and lib.Toggles.EnableChams.Value
    local box = lib.Toggles.EnableBox and lib.Toggles.EnableBox.Value
    local bType = lib.Options.BoxType and lib.Options.BoxType.Value or "2D"
    local chamColor = lib.Options.ChamsColor and lib.Options.ChamsColor.Value or Color3.new(1, 1, 1)
    
    for _, player in pairs(plrs:GetPlayers()) do
        if player ~= lp then
            local char = player.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                if not playerESPData[player] then
                    playerESPData[player] = {
                        box2D = Drawing.new("Square"),
                        box3D = {},
                        text = Drawing.new("Text")
                    }
                    playerESPData[player].box2D.Thickness = 1
                    playerESPData[player].box2D.Filled = false
                    playerESPData[player].text.Size = 13
                    playerESPData[player].text.Font = 2
                    playerESPData[player].text.Outline = true
                    for i = 1, 12 do table.insert(playerESPData[player].box3D, Drawing.new("Line")) end
                end
                
                local data = playerESPData[player]
                local root = char.HumanoidRootPart
                local head = char:FindFirstChild("Head")
                local pos, screen = cam:WorldToViewportPoint(root.Position)
                
                if screen then
                    if box then
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
                        
                        data.box2D.Color = chamColor
                        for _, l in pairs(data.box3D) do l.Color = chamColor end
                        
                        if bType == "2D" then
                            local minX, minY = math.huge, math.huge
                            local maxX, maxY = -math.huge, -math.huge
                            local allOff = true
                            for _, c in pairs(corners) do
                                local p, s = cam:WorldToViewportPoint(c.Position)
                                if s then
                                    allOff = false
                                    minX = math.min(minX, p.X)
                                    minY = math.min(minY, p.Y)
                                    maxX = math.max(maxX, p.X)
                                    maxY = math.max(maxY, p.Y)
                                end
                            end
                            if not allOff then
                                data.box2D.Position = Vector2.new(minX, minY)
                                data.box2D.Size = Vector2.new(maxX - minX, maxY - minY)
                                data.box2D.Visible = true
                            else
                                data.box2D.Visible = false
                            end
                            for _, l in pairs(data.box3D) do l.Visible = false end
                        elseif bType == "3D" then
                            data.box2D.Visible = false
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
                    data.text.Visible = false
                else
                    data.box2D.Visible = false
                    data.text.Visible = false
                    for _, l in pairs(data.box3D) do l.Visible = false end
                end
                
                if chams and char then
                    if not chamsData[player] then
                        local h = Instance.new("Highlight")
                        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        h.FillTransparency = 0.5
                        h.OutlineTransparency = 0
                        local coreGui = get("CoreGui")
                        if coreGui then h.Parent = coreGui end
                        chamsData[player] = h
                    end
                    chamsData[player].Adornee = char
                    chamsData[player].FillColor = chamColor
                    chamsData[player].OutlineColor = chamColor
                    chamsData[player].Enabled = true
                elseif chamsData[player] then
                    chamsData[player].Enabled = false
                end
            else
                if playerESPData[player] then
                    playerESPData[player].box2D.Visible = false
                    playerESPData[player].text.Visible = false
                    for _, l in pairs(playerESPData[player].box3D) do l.Visible = false end
                end
                if chamsData[player] then chamsData[player].Enabled = false end
            end
        end
    end
end

rs.RenderStepped:Connect(updatePlayerESP)

local moveBox = mainTab:AddRightGroupbox("Movement")
moveBox:AddToggle("EnableSpeed", { Text = "Speed Boost", Default = false }):AddKeyPicker("SpeedKey", { Default = "None", SyncToggleState = true, Mode = "Toggle", Text = "Speed Boost" })
moveBox:AddSlider("SpeedValue", { Text = "Speed", Default = 16, Min = 16, Max = 100, Rounding = 0 })
moveBox:AddDivider()
moveBox:AddToggle("EnableFly", { Text = "Fly Mode", Default = false }):AddKeyPicker("FlyKey", { Default = "None", SyncToggleState = true, Mode = "Toggle", Text = "Fly Mode" })
moveBox:AddSlider("FlySpeed", { Text = "Fly Speed", Default = 10, Min = 10, Max = 50, Rounding = 0 })

task.spawn(function()
    while task.wait() do
        local char = lp.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.WalkSpeed = (lib.Toggles.EnableSpeed and lib.Toggles.EnableSpeed.Value) and lib.Options.SpeedValue.Value or 16
            end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                if lib.Toggles.EnableFly and lib.Toggles.EnableFly.Value then
                    workspace.Gravity = 0
                    local dir = Vector3.new(0, 0, 0)
                    if uis:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
                    if uis:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
                    if uis:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
                    if uis:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
                    if uis:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
                    if uis:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0, 1, 0) end
                    if dir.Magnitude > 0 then
                        hrp.Velocity = dir.Unit * lib.Options.FlySpeed.Value * 10
                    else
                        hrp.Velocity = Vector3.new(0, 0, 0)
                    end
                else
                    workspace.Gravity = 196.2
                end
            end
        end
    end
end)

local camBox = mainTab:AddLeftGroupbox("Camera")
camBox:AddToggle("FOVChanger", { Text = "FOV Changer", Default = false })
camBox:AddSlider("FOVValue", { Text = "FOV", Default = 70, Min = 60, Max = 120, Rounding = 0 })

rs.RenderStepped:Connect(function()
    if lib.Toggles.FOVChanger and lib.Toggles.FOVChanger.Value then
        cam.FieldOfView = lib.Options.FOVValue.Value
    end
end)

local combatBox = mainTab:AddRightGroupbox("Combat")
combatBox:AddToggle("AutoPunch", { Text = "Auto Punch", Default = false }):AddKeyPicker("AutoPunchKey", { Default = "None", SyncToggleState = true, Mode = "Toggle", Text = "Auto Punch" })
combatBox:AddSlider("PunchSpeed", { Text = "Punch Speed", Default = 0.2, Min = 0.1, Max = 1, Rounding = 1 })

task.spawn(function()
    while task.wait() do
        if lib.Toggles.AutoPunch and lib.Toggles.AutoPunch.Value then
            local char = lp.Character
            if char then
                local fists = char:FindFirstChild("Fists")
                if fists and fists:IsA("Tool") and fists.Parent == char then
                    local remote = fists:FindFirstChild("fistremote")
                    if remote then remote:FireServer("lmb") end
                end
            end
            task.wait(lib.Options.PunchSpeed.Value)
        end
    end
end)

local shopBox = miscTab:AddLeftGroupbox("Auto Buy Weapons")
local weapons = {
    {name = "Pistol", id = 1, price = 0},
    {name = "Revolver", id = 2, price = 150},
    {name = "Laser Gun", id = 3, price = 350},
    {name = "Shotgun", id = 4, price = 700},
    {name = "RPG", id = 5, price = 1000},
    {name = "Cobra", id = 6, price = 1500}
}
for _, weapon in ipairs(weapons) do
    shopBox:AddToggle("AutoBuy" .. weapon.name:gsub(" ", ""), { Text = "Auto Buy " .. weapon.name, Default = false })
end

task.spawn(function()
    while task.wait(5) do
        for _, weapon in ipairs(weapons) do
            local toggle = lib.Toggles["AutoBuy" .. weapon.name:gsub(" ", "")]
            if toggle and toggle.Value then
                local remote = game:GetService("ReplicatedStorage"):FindFirstChild("WeaponShopRemote")
                if remote then
                    remote:FireServer("PurchaseSkin", {
                        name = weapon.name,
                        id = weapon.id,
                        price = weapon.price,
                        currency = "Cash"
                    })
                end
            end
        end
    end
end)

local cfgBox = settingsTab:AddLeftGroupbox("Config")
cfgBox:AddToggle("KeyMenu", { Default = lib.KeybindFrame.Visible, Text = "Keybind Menu", Callback = function(v) lib.KeybindFrame.Visible = v end })
cfgBox:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu bind" })
lib.ToggleKeybind = lib.Options.MenuKeybind

theme:SetLibrary(lib)
save:SetLibrary(lib)
save:IgnoreThemeSettings()
save:SetIgnoreIndexes({ "MenuKeybind" })
theme:SetFolder("PlowsScriptHub")
save:SetFolder("PlowsScriptHub/BlindShot")
save:BuildConfigSection(settingsTab)
theme:ApplyToTab(settingsTab)
save:LoadAutoloadConfig()

lib:OnUnload(function()
    if perfConn then perfConn:Disconnect() end
    cleanupAllESP()
    workspace.Gravity = 196.2
end)

pcall(bypass)
