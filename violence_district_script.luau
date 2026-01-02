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
        if not checkcaller() then
            if method == "Kick" and self == lp then return nil end
            if method == "GetService" then
                local service = select(1, ...)
                if service == "VirtualInputManager" or service == "HttpService" or service == "TeleportService" then
                    return Instance.new("Folder")
                end
            end
        end
        return old_nc(self, ...)
    end)
    
    gm.__index = newcclosure(function(self, k)
        if not checkcaller() then
            if k == "Drawing" or k == "VirtualInputManager" or k == "HttpService" or k == "TeleportService" then
                return Instance.new("Folder")
            end
        end
        return old_idx(self, k)
    end)
    
    gm.__newindex = newcclosure(function(self, k, v)
        if not checkcaller() then
            if k == "Enabled" and self:IsA("Script") then
                return
            end
        end
        return old_ns(self, k, v)
    end)
    
    setreadonly(gm, true)
    
    local oldHttpGet = game.HttpGet
    game.HttpGet = function(...)
        if not checkcaller() then return "" end
        return oldHttpGet(...)
    end
    
    local oldHttpGetAsync = game.HttpGetAsync
    game.HttpGetAsync = function(...)
        if not checkcaller() then return "" end
        return oldHttpGetAsync(...)
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
    Title = "AXIS HUB",
    Footer = "v1.6.2",
    NotifySide = "Right",
    ShowCustomCursor = true,
})

local home = win:AddTab("Home", "house")
local main = win:AddTab("Main", "target")
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

generatorsBox:AddToggle("GeneratorESP", { Text = "Generator ESP", Default = false }):AddKeyPicker("GeneratorESPKey", { Default = "None", SyncToggleState = true, Mode = "Toggle", Text = "Generator ESP" }):AddColorPicker("GeneratorESPColor", { Default = Color3.fromRGB(255, 255, 0), Title = "Generator ESP Color" })

visualsBox:AddToggle("Chams", { Text = "Chams", Default = false })
visualsBox:AddToggle("Box", { Text = "Box ESP", Default = false })
visualsBox:AddDropdown("BoxType", { Values = { "2D", "3D" }, Default = "2D", Text = "Box Type" })
visualsBox:AddToggle("KillerESP", { Text = "Killer ESP", Default = false })
visualsBox:AddToggle("SurvivorESP", { Text = "Survivor ESP", Default = false })

local function updateGeneratorESP()
    local enabled = Toggles.GeneratorESP and Toggles.GeneratorESP.Value
    local color = Options.GeneratorESPColor and Options.GeneratorESPColor.Value or Color3.new(1, 1, 0)
    
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
                    generatorESPData[gen] = {
                        box = Drawing.new("Square"),
                        text = Drawing.new("Text")
                    }
                    generatorESPData[gen].box.Thickness = 1
                    generatorESPData[gen].box.Filled = false
                    generatorESPData[gen].text.Size = 13
                    generatorESPData[gen].text.Font = 2
                    generatorESPData[gen].text.Outline = true
                    generatorESPData[gen].text.Text = "Generator"
                end
                
                local data = generatorESPData[gen]
                data.box.Color = color
                data.text.Color = color
                
                local part = gen.PrimaryPart or gen:FindFirstChildWhichIsA("BasePart")
                if part then
                    local pos, screen = cam:WorldToViewportPoint(part.Position)
                    if screen then
                        local size = Vector2.new(50, 50)
                        data.box.Position = Vector2.new(pos.X - size.X/2, pos.Y - size.Y/2)
                        data.box.Size = size
                        data.box.Visible = true
                        data.text.Position = Vector2.new(pos.X, pos.Y - 35)
                        data.text.Visible = true
                    else
                        data.box.Visible = false
                        data.text.Visible = false
                    end
                end
            end
        end
    else
        for _, data in pairs(generatorESPData) do
            data.box.Visible = false
            data.text.Visible = false
        end
    end
end

local function updatePlayerESP()
    local chams = Toggles.Chams and Toggles.Chams.Value
    local box = Toggles.Box and Toggles.Box.Value
    local bType = Options.BoxType and Options.BoxType.Value or "2D"
    local kESP = Toggles.KillerESP and Toggles.KillerESP.Value
    local sESP = Toggles.SurvivorESP and Toggles.SurvivorESP.Value
    
    for _, player in pairs(plrs:GetPlayers()) do
        if player ~= lp then
            local char = player.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                local isK = player.Team and player.Team.TeamColor == BrickColor.new("Crimson")
                local isS = player.Team and player.Team.TeamColor == BrickColor.new("Deep blue")
                
                local show = false
                local color = Color3.new(1, 1, 1)
                
                if kESP and isK then
                    show = true
                    color = Color3.new(1, 0, 0)
                elseif sESP and isS then
                    show = true
                    color = Color3.new(0, 0, 1)
                elseif chams then
                    show = true
                    color = Color3.new(1, 1, 1)
                end
                
                if show then
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
                    data.box2D.Color = color
                    data.text.Color = color
                    for _, l in pairs(data.box3D) do l.Color = color end
                    
                    local root = char.HumanoidRootPart
                    local head = char:FindFirstChild("Head")
                    local pos, screen = cam:WorldToViewportPoint(root.Position)
                    
                    if screen then
                        if box then
                            if bType == "2D" and head then
                                local hPos = cam:WorldToViewportPoint(head.Position)
                                local h = math.abs(hPos.Y - pos.Y) * 1.2
                                local w = h * 0.6
                                data.box2D.Position = Vector2.new(pos.X - w/2, hPos.Y - (h*0.1))
                                data.box2D.Size = Vector2.new(w, h)
                                data.box2D.Visible = true
                                for _, l in pairs(data.box3D) do l.Visible = false end
                            elseif bType == "3D" then
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
                            else
                                data.box2D.Visible = false
                                for _, l in pairs(data.box3D) do l.Visible = false end
                            end
                        else
                            data.box2D.Visible = false
                            for _, l in pairs(data.box3D) do l.Visible = false end
                        end
                        
                        data.text.Position = Vector2.new(pos.X, (head and cam:WorldToViewportPoint(head.Position).Y or pos.Y) - 25)
                        data.text.Text = player.Name .. " [" .. (isK and "Killer" or isS and "Survivor" or "Player") .. "]"
                        data.text.Visible = true
                    else
                        data.box2D.Visible = false
                        data.text.Visible = false
                        for _, l in pairs(data.box3D) do l.Visible = false end
                    end
                elseif playerESPData[player] then
                    playerESPData[player].box2D.Visible = false
                    playerESPData[player].text.Visible = false
                    for _, l in pairs(playerESPData[player].box3D) do l.Visible = false end
                end
                
                if chams and char then
                    if not chamsData[player] then
                        local h = Instance.new("Highlight")
                        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        h.FillTransparency = 0.5
                        h.OutlineTransparency = 0
                        h.Parent = get("CoreGui")
                        chamsData[player] = h
                    end
                    chamsData[player].Adornee = char
                    chamsData[player].FillColor = color
                    chamsData[player].OutlineColor = color
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
        data.text:Remove()
    end
    for _, data in pairs(playerESPData) do
        data.box2D:Remove()
        data.text:Remove()
        for _, l in pairs(data.box3D) do l:Remove() end
    end
    for _, h in pairs(chamsData) do h:Destroy() end
end)

pcall(bypass)
