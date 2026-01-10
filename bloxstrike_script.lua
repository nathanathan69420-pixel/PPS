local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/"
local lib = loadstring(game:HttpGet(repo .. "Library.lua"))()
local theme = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local save = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local plrs = game:GetService("Players")
local rs = game:GetService("RunService")
local uis = game:GetService("UserInputService")
local lp = plrs.LocalPlayer
local mouse = lp:GetMouse()
local cam = workspace.CurrentCamera

local ts, os = lib.Toggles, lib.Options

local function draw(type, props)
    local obj = Drawing.new(type)
    for k, v in pairs(props) do obj[k] = v end
    return obj
end

theme.BuiltInThemes["Default"][2] = {
    BackgroundColor = "16293a", MainColor = "26445f", AccentColor = "5983a0", OutlineColor = "325573", FontColor = "d2dae1"
}

local win = lib:CreateWindow({
    Title = "Axis Hub -\nBloxstrike.lua", Footer = "by RwalDev & Plow | 1.9.5", NotifySide = "Right", ShowCustomCursor = true,
})

local hTab, mTab, sTab = win:AddTab("Home", "house"), win:AddTab("Main", "crosshair"), win:AddTab("Settings", "settings")

local status = hTab:AddLeftGroupbox("Status")
local aiming = mTab:AddLeftGroupbox("Aiming")
local visuals = mTab:AddRightGroupbox("Visuals")
local cfgBox = sTab:AddLeftGroupbox("Config")

status:AddLabel(string.format("Welcome, %s\nGame: Blox Strike", lp.DisplayName), true)
status:AddButton({ Text = "Unload", Func = function() lib:Unload() end })

aiming:AddToggle("Triggerbot", { Text = "Triggerbot", Default = false })
aiming:AddSlider("TriggerDelay", { Text = "Triggerbot Delay", Default = 0.1, Min = 0.1, Max = 1, Rounding = 1, Compact = true })
aiming:AddToggle("HitboxExpander", { Text = "Hitbox Expander", Default = false })
aiming:AddSlider("HitboxSize", { Text = "Hitbox Size", Default = 1, Min = 1, Max = 15, Rounding = 0, Compact = true })

visuals:AddToggle("Chams", { Text = "Chams", Default = false }):AddColorPicker("ChamsColor", { Default = Color3.fromRGB(0, 170, 255), Title = "Chams Color" })
visuals:AddToggle("BoxESP", { Text = "Box ESP", Default = false })
visuals:AddDropdown("BoxType", { Values = { "2D", "3D" }, Default = "2D", Text = "Box Type" })
visuals:AddToggle("SkeletonESP", { Text = "Skeleton ESP", Default = false })
visuals:AddToggle("HeadESP", { Text = "Head ESP", Default = false })

local heads, boxes, skeletons = {}, {}, {}
local hitbox_visualizer = draw("Circle", { Thickness = 1, Color = Color3.new(1,1,1), Filled = false, Visible = false, Radius = 10, NumSides = 24 })

local BONE_PAIRS = {
    {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"}
}

local function isTarget(p)
    return p and p ~= lp
end

local function getEnemyChars()
    local t = {}
    for _, v in pairs(plrs:GetPlayers()) do
        if isTarget(v) and v.Character then
            table.insert(t, v.Character)
        end
    end
    return t
end

-- Raycast Redirection Hook (Hitbox Expansion through code)
if hookmetamethod then
    local old_rc
    old_rc = hookmetamethod(workspace, "__namecall", newcclosure(function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        
        if not checkcaller() and method == "Raycast" and ts.HitboxExpander.Value then
            local origin, direction = args[1], args[2]
            local params = args[3]
            
            local radius = os.HitboxSize.Value
            local cast = workspace:Spherecast(origin, radius, direction, params)
            
            if cast and cast.Instance then
                return cast
            end
        end
        return old_rc(self, unpack(args))
    end))
end

local function updateBoxESP(b, char, boxType)
    local cf, sz = char:GetBoundingBox()
    if boxType == "2D" then
        for _, l in pairs(b.b3d) do l.Visible = false end
        local t, on1 = cam:WorldToViewportPoint((cf * CFrame.new(0, sz.Y/2, 0)).Position)
        local bot, on2 = cam:WorldToViewportPoint((cf * CFrame.new(0, -sz.Y/2, 0)).Position)
        if on1 and on2 then
            local hV = math.abs(t.Y - bot.Y)
            local wV = hV * 0.6
            b.b2d.Size = Vector2.new(wV, hV)
            b.b2d.Position = Vector2.new(t.X - wV/2, t.Y)
            b.b2d.Color = Color3.new(1, 1, 1)
            b.b2d.Visible = true
        else
            b.b2d.Visible = false
        end
    else
        b.b2d.Visible = false
        local corners = {
            cf * CFrame.new(-sz.X/2, sz.Y/2, sz.Z/2), cf * CFrame.new(sz.X/2, sz.Y/2, sz.Z/2),
            cf * CFrame.new(-sz.X/2, -sz.Y/2, sz.Z/2), cf * CFrame.new(sz.X/2, -sz.Y/2, sz.Z/2),
            cf * CFrame.new(-sz.X/2, sz.Y/2, -sz.Z/2), cf * CFrame.new(sz.X/2, sz.Y/2, -sz.Z/2),
            cf * CFrame.new(-sz.X/2, -sz.Y/2, -sz.Z/2), cf * CFrame.new(sz.X/2, -sz.Y/2, -sz.Z/2)
        }
        local BOX_CONNECTIONS = {{1,2},{2,4},{4,3},{3,1}, {5,6},{6,8},{8,7},{7,5}, {1,5},{2,6},{3,7},{4,8}}
        for i, conn in ipairs(BOX_CONNECTIONS) do
            if not b.b3d[i] then
                b.b3d[i] = draw("Line", { Thickness = 1, Color = Color3.new(1,1,1), Visible = false })
            end
            local p1, v1 = cam:WorldToViewportPoint(corners[conn[1]].Position)
            local p2, v2 = cam:WorldToViewportPoint(corners[conn[2]].Position)
            if v1 and v2 then
                b.b3d[i].From = Vector2.new(p1.X, p1.Y)
                b.b3d[i].To = Vector2.new(p2.X, p2.Y)
                b.b3d[i].Visible = true
            else
                b.b3d[i].Visible = false
            end
        end
    end
end

local function updateSkeletonESP(skelData, char)
    for i, pair in ipairs(BONE_PAIRS) do
        if not skelData[i] then
            skelData[i] = draw("Line", { Thickness = 1, Color = Color3.new(1,1,1), Visible = false })
        end
        local b1, b2 = char:FindFirstChild(pair[1]), char:FindFirstChild(pair[2])
        if b1 and b2 then
            local p1, v1 = cam:WorldToViewportPoint(b1.Position)
            local p2, v2 = cam:WorldToViewportPoint(b2.Position)
            skelData[i].From = Vector2.new(p1.X, p1.Y)
            skelData[i].To = Vector2.new(p2.X, p2.Y)
            skelData[i].Visible = v1 and v2
        else
            skelData[i].Visible = false
        end
    end
end

local lastT = 0
local loop = rs.RenderStepped:Connect(function()
    if ts.Triggerbot.Value and (tick() - lastT >= os.TriggerDelay.Value) then
        local mousePos = uis:GetMouseLocation()
        local ray = cam:ViewportPointToRay(mousePos.X, mousePos.Y)
        local params = RaycastParams.new()
        params.FilterDescendantsInstances = getEnemyChars()
        params.FilterType = Enum.RaycastFilterType.Include

        local radius = ts.HitboxExpander.Value and os.HitboxSize.Value or 1
        local cast = workspace:Spherecast(ray.Origin, radius, ray.Direction * 1000, params)

        if cast and cast.Instance then
            if mouse1click then
                mouse1click()
                lastT = tick()
            end
        end
    end

    if ts.HitboxExpander.Value then
        hitbox_visualizer.Visible = true
        hitbox_visualizer.Radius = os.HitboxSize.Value * 5
        hitbox_visualizer.Position = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
    else
        hitbox_visualizer.Visible = false
    end

    for _, plr in pairs(plrs:GetPlayers()) do
        local char = plr.Character
        if not isTarget(plr) or not char or not char:FindFirstChild("Humanoid") or char.Humanoid.Health <= 0 then
            if heads[plr] then heads[plr].Visible = false end
            if boxes[plr] then
                boxes[plr].b2d.Visible = false
                for _, l in pairs(boxes[plr].b3d) do l.Visible = false end
            end
            if skeletons[plr] then
                for _, l in pairs(skeletons[plr]) do l.Visible = false end
            end
            if char then
                local c = char:FindFirstChild("AxisC")
                if c then c.Enabled = false end
            end
            continue
        end
        
        local highlight = char:FindFirstChild("AxisC")
        if ts.Chams.Value then
            if not highlight then
                highlight = Instance.new("Highlight")
                highlight.Name = "AxisC"
                highlight.OutlineTransparency = 0
                highlight.FillTransparency = 0.5
                highlight.Parent = char
            end
            highlight.FillColor = os.ChamsColor.Value
            highlight.Enabled = true
        elseif highlight then
            highlight.Enabled = false
        end

        if ts.HeadESP.Value then
            if not heads[plr] then
                heads[plr] = draw("Circle", { Thickness = 1, NumSides = 12, Radius = 5, Filled = true, Visible = false })
            end
            local head = char:FindFirstChild("Head")
            if head then
                local pos, vis = cam:WorldToViewportPoint(head.Position)
                heads[plr].Position = Vector2.new(pos.X, pos.Y)
                heads[plr].Color = Color3.new(1, 0, 0)
                heads[plr].Visible = vis
            else
                heads[plr].Visible = false
            end
        elseif heads[plr] then
            heads[plr].Visible = false
        end

        if ts.BoxESP.Value then
            if not boxes[plr] then
                boxes[plr] = { b2d = draw("Square", { Thickness = 1, Filled = false, Visible = false }), b3d = {} }
            end
            updateBoxESP(boxes[plr], char, os.BoxType.Value)
        elseif boxes[plr] then
            boxes[plr].b2d.Visible = false
            for _, l in pairs(boxes[plr].b3d) do l.Visible = false end
        end

        if ts.SkeletonESP.Value then
            if not skeletons[plr] then skeletons[plr] = {} end
            updateSkeletonESP(skeletons[plr], char)
        elseif skeletons[plr] then
            for _, l in pairs(skeletons[plr]) do l.Visible = false end
        end
    end
end)

cfgBox:AddToggle("KeyMenu", { Default = lib.KeybindFrame.Visible, Text = "Keybind Menu", Callback = function(v) lib.KeybindFrame.Visible = v end })
cfgBox:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { Default = "RightControl", NoUI = true, Text = "Menu bind" })
lib.ToggleKeybind = os.MenuKeybind
theme:SetLibrary(lib)
save:SetLibrary(lib)
save:IgnoreThemeSettings()
theme:SetFolder("PlowsScriptHub")
save:SetFolder("PlowsScriptHub/BloxStrike")
save:BuildConfigSection(sTab)
theme:ApplyToTab(sTab)
save:LoadAutoloadConfig()

lib:OnUnload(function()
    loop:Disconnect()
    hitbox_visualizer:Remove()
    for _, h in pairs(heads) do h:Remove() end
    for _, b in pairs(boxes) do b.b2d:Remove() for _, l in pairs(b.b3d) do l:Remove() end end
    for _, s in pairs(skeletons) do for _, l in pairs(s) do l:Remove() end end
end)
