local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/"
local lib = loadstring(game:HttpGet(repo .. "Library.lua"))()
local theme = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local save = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Toggles = lib.Toggles
local Options = lib.Options

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
    Title = "Axis Hub -\nViolence District.lua",
    Footer = "by RwalDev & Plow | 1.9.7 | Discord: .gg/UuyxhqgEVs",
    NotifySide = "Right",
    ShowCustomCursor = true,
})

local home = win:AddTab("Home", "house")
local main = win:AddTab("Main", "swords")
local config = win:AddTab("Settings", "settings")

local status = home:AddLeftGroupbox("Status")
local generatorsBox = main:AddLeftGroupbox("Generators")
local visualsBox = main:AddRightGroupbox("Visuals")
local cfgBox = config:AddLeftGroupbox("Config")

status:AddLabel(string.format("Welcome, %s\nGame: Violence District", lp.DisplayName), true)
status:AddButton({ Text = "Unload", Func = function() lib:Unload() end })

local generatorESPData = {}
local playerESPData = {}
local chamsData = {}

-- Helper function to clean up generator ESP data
local function cleanupGeneratorESP()
    for gen, data in pairs(generatorESPData) do
        if data.box and data.box.Remove then
            data.box:Remove()
        end
        if data.highlight and data.highlight.Destroy then
            data.highlight:Destroy()
        end
    end
    table.clear(generatorESPData)
end

-- Helper function to clean up player ESP data
local function cleanupPlayerESP()
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
end

-- Helper function to clean up chams data
local function cleanupChamsData()
    for player, highlight in pairs(chamsData) do
        if highlight and highlight.Destroy then
            highlight:Destroy()
        end
    end
    table.clear(chamsData)
end

generatorsBox:AddToggle("GeneratorESP", { Text = "Generator ESP", Default = false }):AddKeyPicker("GeneratorESPKey", { Default = "None", SyncToggleState = true, Mode = "Toggle", Text = "Generator ESP" }):AddColorPicker("GeneratorESPColor", { Default = Color3.fromRGB(255, 255, 0), Title = "Generator ESP Color" })
generatorsBox:AddDropdown("GeneratorESPType", { Values = { "Highlight", "Box" }, Default = "Highlight", Text = "ESP Type" })

visualsBox:AddToggle("Chams", { Text = "Chams", Default = false }):AddColorPicker("ChamsColor", { Default = Color3.fromRGB(255, 255, 255), Title = "Chams Color" })
visualsBox:AddToggle("Box", { Text = "Box ESP", Default = false })
visualsBox:AddDropdown("BoxType", { Values = { "2D", "3D" }, Default = "2D", Text = "Box Type" })
visualsBox:AddToggle("KillerESP", { Text = "Killer ESP", Default = false })
visualsBox:AddToggle("SurvivorESP", { Text = "Survivor ESP", Default = false })

local function updateGeneratorESP()
    local enabled = Toggles.GeneratorESP and Toggles.GeneratorESP.Value
    local color = Options.GeneratorESPColor and Options.GeneratorESPColor.Value or Color3.new(1, 1, 0)
    local type = Options.GeneratorESPType and Options.GeneratorESPType.Value or "Highlight"
    
    if enabled then
        local gens = workspace:FindFirstChild("Generators") or workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Generators")
        local list = gens and gens:GetChildren() or {}
        
        for _, player in pairs(plrs:GetPlayers()) do
            if player ~= lp and player.Character then
                for _, obj in pairs(player.Character:GetChildren()) do
                    if obj.Name == "Generator" then table.insert(list, obj) end
                end
            end
        end

        for _, gen in pairs(list) do
            if gen:IsA("Model") then
                if not generatorESPData[gen] then
                    local h = Instance.new("Highlight")
                    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    h.FillTransparency = 0.5
                    h.OutlineTransparency = 0
                    h.Parent = get("CoreGui")
                    
                    generatorESPData[gen] = {
                        box = Drawing.new("Square"),
                        highlight = h
                    }
                    generatorESPData[gen].box.Thickness = 1
                    generatorESPData[gen].box.Filled = false
                end
                
                local data = generatorESPData[gen]
                local part = gen.PrimaryPart or gen:FindFirstChildWhichIsA("BasePart")
                
                if type == "Highlight" then
                    data.box.Visible = false
                    data.highlight.FillColor = color
                    data.highlight.OutlineColor = color
                    data.highlight.Adornee = gen
                    data.highlight.Enabled = true
                elseif type == "Box" then
                    data.highlight.Enabled = false
                    if part then
                        local pos, screen = cam:WorldToViewportPoint(part.Position)
                        if screen then
                            local size = Vector2.new(50, 50)
                            data.box.Position = Vector2.new(pos.X - size.X/2, pos.Y - size.Y/2)
                            data.box.Size = size
                            data.box.Color = color
                            data.box.Visible = true
                        else
                            data.box.Visible = false
                        end
                    end
                end
            end
        end
    else
        for _, data in pairs(generatorESPData) do
            data.box.Visible = false
            if data.highlight then data.highlight.Enabled = false end
        end
    end
end

local function updatePlayerESP()
    local chams = Toggles.Chams and Toggles.Chams.Value
    local box = Toggles.Box and Toggles.Box.Value
    local bType = Options.BoxType and Options.BoxType.Value or "2D"
    local kESP = Toggles.KillerESP and Toggles.KillerESP.Value
    local sESP = Toggles.SurvivorESP and Toggles.SurvivorESP.Value
    local chamColor = Options.ChamsColor and Options.ChamsColor.Value or Color3.new(1, 1, 1)
    
    for _, player in pairs(plrs:GetPlayers()) do
        if player ~= lp then
            local char = player.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                local isK = player.Team and player.Team.TeamColor == BrickColor.new("Crimson")
                local isS = player.Team and player.Team.TeamColor == BrickColor.new("Deep blue")
                
                local showHighlight = false
                local highlightColor = Color3.new(1, 1, 1)
                
                if kESP and isK then
                    showHighlight = true
                    highlightColor = Color3.new(1, 0, 0)
                elseif sESP and isS then
                    showHighlight = true
                    highlightColor = Color3.new(0, 0, 1)
                elseif chams then
                    showHighlight = true
                    highlightColor = chamColor
                end
                
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
                    for i = 1, 12 do
                        table.insert(playerESPData[player].box3D, Drawing.new("Line"))
                    end
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

                        data.box2D.Color = highlightColor
                        for _, l in pairs(data.box3D) do l.Color = highlightColor end

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
                
                if showHighlight and char then
                    if not chamsData[player] then
                        local h = Instance.new("Highlight")
                        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        h.FillTransparency = 0.5
                        h.OutlineTransparency = 0
                        h.Parent = get("CoreGui")
                        chamsData[player] = h
                    end
                    chamsData[player].Adornee = char
                    chamsData[player].FillColor = highlightColor
                    chamsData[player].OutlineColor = highlightColor
                    chamsData[player].Enabled = true
                elseif chamsData[player] then
                    chamsData[player].Enabled = false
                end
            end
        end
    end
end

rs.RenderStepped:Connect(function()
    updateGeneratorESP()
    updatePlayerESP()
end)

cfgBox:AddToggle("KeyMenu", { Default = lib.KeybindFrame.Visible, Text = "Keybind Menu", Callback = function(v) lib.KeybindFrame.Visible = v end })
cfgBox:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { Default = "RightControl", NoUI = true, Text = "Menu bind" })
lib.ToggleKeybind = Options.MenuKeybind

theme:SetLibrary(lib)
save:SetLibrary(lib)
save:IgnoreThemeSettings()
save:SetIgnoreIndexes({ "MenuKeybind" })
theme:SetFolder("PlowsScriptHub")
save:SetFolder("PlowsScriptHub/ViolenceDistrict")
save:BuildConfigSection(config)
theme:ApplyToTab(config)
save:LoadAutoloadConfig()

lib:OnUnload(function()
    for _, data in pairs(generatorESPData) do
        data.box:Remove()
        if data.highlight then data.highlight:Destroy() end
    end
    for _, data in pairs(playerESPData) do
        data.box2D:Remove()
        data.text:Remove()
        for _, l in pairs(data.box3D) do l:Remove() end
    end
    for _, h in pairs(chamsData) do h:Destroy() end
end)

pcall(bypass)
