local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/"
local lib = loadstring(game:HttpGet(repo .. "Library.lua"))()
local theme = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local save = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local plrs = game:GetService("Players")
local rs = game:GetService("RunService")
local lp = plrs.LocalPlayer
local mouse = lp:GetMouse()
local cam = workspace.CurrentCamera

local ts, os = lib.Toggles, lib.Options

theme.BuiltInThemes["Default"][2] = {
    BackgroundColor = "16293a", MainColor = "26445f", AccentColor = "5983a0", OutlineColor = "325573", FontColor = "d2dae1"
}

local win = lib:CreateWindow({
    Title = "Axis Hub -\nBloxstrike.lua", Footer = "by RwalDev & Plow | 1.8.4", NotifySide = "Right", ShowCustomCursor = true,
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
aiming:AddSlider("HitboxTransparency", { Text = "Hitbox Transparency", Default = 0.5, Min = 0.1, Max = 1, Rounding = 1, Compact = true })
aiming:AddSlider("HitboxSize", { Text = "Hitbox Size", Default = 1, Min = 1, Max = 15, Rounding = 0, Compact = true })
aiming:AddDropdown("Hitboxes", { Values = { "Head", "HumanoidRootPart", "UpperTorso", "LowerTorso", "LeftArm", "RightArm", "All" }, Default = "All", Multi = true, Text = "Hitboxes" })

visuals:AddToggle("Chams", { Text = "Chams", Default = false }):AddColorPicker("ChamsColor", { Default = Color3.fromRGB(0, 170, 255), Title = "Chams Color" })
visuals:AddToggle("BoxESP", { Text = "Box ESP", Default = false })
visuals:AddDropdown("BoxType", { Values = { "2D", "3D" }, Default = "2D", Text = "Box Type" })
visuals:AddToggle("SkeletonESP", { Text = "Skeleton ESP", Default = false })
visuals:AddToggle("HeadESP", { Text = "Head ESP", Default = false })

local heads, boxes, skeletons, pModels = {}, {}, {}, {}

local function genName()
    local s = ""
    for i = 1, 10 do s ..= string.char(math.random(97, 122)) end
    return s
end

local hbRoot = Instance.new("Folder")
hbRoot.Name = genName()
hbRoot.Parent = workspace

local function isEnemy(p)
    if not p or p == lp then return false end
    if not lp.Team or not p.Team then return true end
    return lp.Team ~= p.Team
end

local function updateHitboxes()
    local enabled, hbSize, hbTrans, selected = ts.HitboxExpander.Value, os.HitboxSize.Value, os.HitboxTransparency.Value, os.Hitboxes.Value
    
    for _, plr in pairs(plrs:GetPlayers()) do
        local enemy = isEnemy(plr)
        local char = plr.Character
        
        if char and enemy and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
            if not pModels[plr] then
                local m = Instance.new("Model")
                m.Name = genName()
                Instance.new("Humanoid", m)
                m.Parent = hbRoot
                pModels[plr] = { model = m, parts = {} }
            end
            
            local data = pModels[plr]
            for _, limbName in pairs({"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso", "LeftArm", "RightArm"}) do
                local limb = char:FindFirstChild(limbName)
                if limb and limb:IsA("BasePart") and (selected["All"] or selected[limbName]) then
                    if enabled then
                        local p = data.parts[limbName]
                        if not p then
                            p = Instance.new("Part")
                            p.Name = limbName
                            p.Transparency = 1
                            p.CanCollide = false
                            p.CanTouch = true
                            p.CanQuery = true
                            p.Parent = data.model
                            
                            local viz = Instance.new("BoxHandleAdornment")
                            viz.Name = "Viz"
                            viz.AlwaysOnTop = true
                            viz.ZIndex = 5
                            viz.Color3 = Color3.new(1, 1, 1)
                            viz.Adornee = p
                            viz.Parent = p
                            
                            data.parts[limbName] = p
                        end
                        
                        local finalSize = (limbName == "Head" and hbSize * 1.3 or hbSize)
                        p.Size = Vector3.new(finalSize, finalSize, finalSize)
                        p.CFrame = limb.CFrame
                        p:FindFirstChild("Viz").Size = p.Size
                        p:FindFirstChild("Viz").Transparency = hbTrans
                    elseif data.parts[limbName] then
                        data.parts[limbName]:Destroy()
                        data.parts[limbName] = nil
                    end
                elseif data.parts[limbName] then
                    data.parts[limbName]:Destroy()
                    data.parts[limbName] = nil
                end
            end
        elseif pModels[plr] then
            pModels[plr].model:Destroy()
            pModels[plr] = nil
        end
    end
end

local function draw(type, props)
    local obj = Drawing.new(type)
    for k, v in pairs(props) do obj[k] = v end
    return obj
end

local lastT = 0
local loop = rs.RenderStepped:Connect(function()
    if ts.Triggerbot.Value and mouse.Target then
        local target = mouse.Target
        local p = nil
        
        if target:IsDescendantOf(hbRoot) then
            for plr, data in pairs(pModels) do
                if target:IsDescendantOf(data.model) then p = plr break end
            end
        end
        
        if not p then
            local model = target:FindFirstAncestorOfClass("Model")
            p = model and plrs:GetPlayerFromCharacter(model)
        end

        if p and isEnemy(p) and (tick() - lastT >= os.TriggerDelay.Value) then
            mouse1click()
            lastT = tick()
        end
    end

    updateHitboxes()

    for _, plr in pairs(plrs:GetPlayers()) do
        local char = plr.Character
        local enemy = isEnemy(plr)
        
        if char and enemy and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
            local c = char:FindFirstChild("AxisC")
            if ts.Chams.Value then
                if not c then
                    c = Instance.new("Highlight", char)
                    c.Name = "AxisC"
                    c.OutlineTransparency = 0
                    c.FillTransparency = 0.5
                end
                c.FillColor = os.ChamsColor.Value
                c.Enabled = true
            elseif c then c.Enabled = false end

            if not heads[plr] then heads[plr] = draw("Circle", { Thickness = 1, NumSides = 12, Radius = 5, Filled = true, Visible = false }) end
            local h, head = heads[plr], char:FindFirstChild("Head")
            if ts.HeadESP.Value and head then
                local pos, vis = cam:WorldToViewportPoint(head.Position)
                h.Position, h.Color, h.Visible = Vector2.new(pos.X, pos.Y), Color3.new(1, 0, 0), vis
            else h.Visible = false end

            if not boxes[plr] then boxes[plr] = { b2d = draw("Square", { Thickness = 1, Filled = false, Visible = false }), b3d = {} } end
            local b = boxes[plr]
            if ts.BoxESP.Value then
                local cf, sz = char:GetBoundingBox()
                if os.BoxType.Value == "2D" then
                    for _, l in pairs(b.b3d) do l.Visible = false end
                    local t, on1 = cam:WorldToViewportPoint((cf * CFrame.new(0, sz.Y/2, 0)).Position)
                    local bot, on2 = cam:WorldToViewportPoint((cf * CFrame.new(0, -sz.Y/2, 0)).Position)
                    if on1 and on2 then
                        local hV = math.abs(t.Y - bot.Y)
                        local wV = hV * 0.6
                        b.b2d.Size, b.b2d.Position, b.b2d.Color, b.b2d.Visible = Vector2.new(wV, hV), Vector2.new(t.X - wV/2, t.Y), Color3.new(1, 1, 1), true
                    else b.b2d.Visible = false end
                else
                    b.b2d.Visible = false
                    local corners = {
                        cf * CFrame.new(-sz.X/2, sz.Y/2, sz.Z/2), cf * CFrame.new(sz.X/2, sz.Y/2, sz.Z/2),
                        cf * CFrame.new(-sz.X/2, -sz.Y/2, sz.Z/2), cf * CFrame.new(sz.X/2, -sz.Y/2, sz.Z/2),
                        cf * CFrame.new(-sz.X/2, sz.Y/2, -sz.Z/2), cf * CFrame.new(sz.X/2, sz.Y/2, -sz.Z/2),
                        cf * CFrame.new(-sz.X/2, -sz.Y/2, -sz.Z/2), cf * CFrame.new(sz.X/2, -sz.Y/2, -sz.Z/2)
                    }
                    local p_idx = { {1,2},{2,4},{4,3},{3,1}, {5,6},{6,8},{8,7},{7,5}, {1,5},{2,6},{3,7},{4,8} }
                    for i, p in ipairs(p_idx) do
                        if not b.b3d[i] then b.b3d[i] = draw("Line", { Thickness = 1, Color = Color3.new(1,1,1), Visible = false }) end
                        local p1, v1 = cam:WorldToViewportPoint(corners[p[1]].Position)
                        local p2, v2 = cam:WorldToViewportPoint(corners[p[2]].Position)
                        if v1 and v2 then
                            b.b3d[i].From, b.b3d[i].To, b.b3d[i].Visible = Vector2.new(p1.X, p1.Y), Vector2.new(p2.X, p2.Y), true
                        else b.b3d[i].Visible = false end
                    end
                end
            else
                b.b2d.Visible = false
                for _, l in pairs(b.b3d) do l.Visible = false end
            end

            if not skeletons[plr] then skeletons[plr] = {} end
            if ts.SkeletonESP.Value then
                local bonePairs = {
                    {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
                    {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
                    {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
                    {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
                    {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"}
                }
                for i, p in ipairs(bonePairs) do
                    if not skeletons[plr][i] then skeletons[plr][i] = draw("Line", { Thickness = 1, Color = Color3.new(1,1,1), Visible = false }) end
                    local b1, b2 = char:FindFirstChild(p[1]), char:FindFirstChild(p[2])
                    if b1 and b2 then
                        local p1, v1 = cam:WorldToViewportPoint(b1.Position)
                        local p2, v2 = cam:WorldToViewportPoint(b2.Position)
                        skeletons[plr][i].From, skeletons[plr][i].To, skeletons[plr][i].Visible = Vector2.new(p1.X, p1.Y), Vector2.new(p2.X, p2.Y), v1 and v2
                    else skeletons[plr][i].Visible = false end
                end
            else
                for _, l in pairs(skeletons[plr]) do l.Visible = false end
            end
        else
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
    hbRoot:Destroy()
    for _, h in pairs(heads) do h:Remove() end
    for _, b in pairs(boxes) do b.b2d:Remove() for _, l in pairs(b.b3d) do l:Remove() end end
    for _, s in pairs(skeletons) do for _, l in pairs(s) do l:Remove() end end
end)
