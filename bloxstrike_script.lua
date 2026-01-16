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
    Title = "Axis Hub -\nBloxstrike.lua", Footer = "by RwalDev & Plow | 1.9.7", NotifySide = "Right", ShowCustomCursor = true,
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
aiming:AddDropdown("Hitboxes", { Values = { "Head", "HumanoidRootPart", "UpperTorso", "LowerTorso", "LeftArm", "RightArm", "LeftLeg", "RightLeg", "LeftUpperArm", "RightUpperArm", "LeftLowerArm", "RightLowerArm", "LeftUpperLeg", "RightUpperLeg", "LeftLowerLeg", "RightLowerLeg", "LeftFoot", "RightFoot", "LeftHand", "RightHand", "All" }, Default = "All", Multi = true, Text = "Hitboxes" })

visuals:AddToggle("Chams", { Text = "Chams", Default = false }):AddColorPicker("ChamsColor", { Default = Color3.fromRGB(0, 170, 255), Title = "Chams Color" })
visuals:AddToggle("BoxESP", { Text = "Box ESP", Default = false })
visuals:AddDropdown("BoxType", { Values = { "2D", "3D" }, Default = "2D", Text = "Box Type" })
visuals:AddToggle("SkeletonESP", { Text = "Skeleton ESP", Default = false })
visuals:AddToggle("HeadESP", { Text = "Head ESP", Default = false })

local heads, boxes, skeletons, originals, chams = {}, {}, {}, {}, {}

local BONE_PAIRS = {
    {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"}
}

local LIMB_NAMES = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso", "LeftArm", "RightArm", "LeftLeg", "RightLeg", "LeftUpperArm", "RightUpperArm", "LeftLowerArm", "RightLowerArm", "LeftUpperLeg", "RightUpperLeg", "LeftLowerLeg", "RightLowerLeg", "LeftFoot", "RightFoot", "LeftHand", "RightHand"}

local function isEnemy(p)
    if not p or p == lp then return false end
    if not lp.Team or not p.Team then return true end
    return lp.Team ~= p.Team
end

local function apply(limb, size, trans)
    if not originals[limb] then
        originals[limb] = {size = limb.Size, trans = limb.Transparency, collide = limb.CanCollide}
    end
    limb.Size = Vector3.new(size, size, size)
    limb.Transparency = trans
    limb.CanCollide = false
    
    local viz = limb:FindFirstChild("Handle")
    if not viz then
        viz = Instance.new("SelectionBox")
        viz.Name = "Handle"
        viz.Adornee = limb
        viz.LineAlpha = 0
        viz.SurfaceColor3 = Color3.new(1, 1, 1)
        viz.SurfaceTransparency = 0.5
        viz.Parent = limb
    end
end

local function reset(limb)
    if originals[limb] then
        limb.Size = originals[limb].size
        limb.Transparency = originals[limb].trans
        limb.CanCollide = originals[limb].collide
        originals[limb] = nil
    end
    local viz = limb:FindFirstChild("Handle")
    if viz then viz:Destroy() end
end

local hitboxUpdateDelay = 0
local function updateHitboxes()
    local enabled, hbSize, hbTrans, selected = ts.HitboxExpander.Value, os.HitboxSize.Value, os.HitboxTransparency.Value, os.Hitboxes.Value
    if not enabled then
        if hitboxUpdateDelay == 0 then
            for _, plr in pairs(plrs:GetPlayers()) do
                local char = plr.Character
                if char then
                    for _, limbName in pairs(LIMB_NAMES) do
                        local limb = char:FindFirstChild(limbName)
                        if limb and limb:IsA("BasePart") then
                            reset(limb)
                        end
                    end
                end
            end
        end
        return
    end
    
    hitboxUpdateDelay = hitboxUpdateDelay + 1
    if hitboxUpdateDelay < 3 then return end
    hitboxUpdateDelay = 0
    
    for _, plr in pairs(plrs:GetPlayers()) do
        if not isEnemy(plr) then continue end
        local char = plr.Character
        if not char then continue end
        local hum = char:FindFirstChild("Humanoid")
        if not hum or hum.Health <= 0 then
            for _, limbName in pairs(LIMB_NAMES) do
                local limb = char:FindFirstChild(limbName)
                if limb and limb:IsA("BasePart") then
                    reset(limb)
                end
            end
            continue
        end
        
        for _, limbName in pairs(LIMB_NAMES) do
            local limb = char:FindFirstChild(limbName)
            if limb and limb:IsA("BasePart") then
                if selected["All"] or selected[limbName] then
                    apply(limb, hbSize, hbTrans)
                else
                    reset(limb)
                end
            end
        end
    end
end

local function bypass()
    if not getrawmetatable or not setreadonly or not newcclosure or not getnamecallmethod then return end
    
    local g = game
    local lp = g:GetService("Players").LocalPlayer
    local gm = getrawmetatable(g)
    local old_idx = gm.__index
    local old_nc = gm.__namecall
    
    setreadonly(gm, false)
    
    gm.__index = newcclosure(function(self, k)
        if not checkcaller() then
            if typeof(self) == "Instance" and self:IsA("BasePart") then
                local data = originals[self]
                if data then
                    if k == "Size" then
                        return data.size
                    elseif k == "Transparency" then
                        return data.trans
                    elseif k == "CanCollide" then
                        return data.collide
                    end
                end
            end
        end
        return old_idx(self, k)
    end)
    
    gm.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if not checkcaller() then
            if (method == "Kick" or method == "kick" or method == "kickPlayer" or method == "KickPlayer") and self == lp then
                return nil
            end
        end
        return old_nc(self, ...)
    end)
    
    setreadonly(gm, true)
end

local function draw(type, props)
    local obj = Drawing.new(type)
    for k, v in pairs(props) do obj[k] = v end
    return obj
end

local BOX_CONNECTIONS = {{1,2},{2,4},{4,3},{3,1}, {5,6},{6,8},{8,7},{7,5}, {1,5},{2,6},{3,7},{4,8}}

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
    if ts.Triggerbot.Value and mouse.Target then
        local model = mouse.Target:FindFirstAncestorOfClass("Model")
        local p = model and plrs:GetPlayerFromCharacter(model)
        if p and isEnemy(p) and (tick() - lastT >= os.TriggerDelay.Value) then
            mouse1click()
            lastT = tick()
        end
    end

    updateHitboxes()

    for _, plr in pairs(plrs:GetPlayers()) do
        if not isEnemy(plr) then
            if heads[plr] then heads[plr].Visible = false end
            if boxes[plr] then
                boxes[plr].b2d.Visible = false
                for _, l in pairs(boxes[plr].b3d) do l.Visible = false end
            end
            if skeletons[plr] then
                for _, l in pairs(skeletons[plr]) do l.Visible = false end
            end
            if chams[plr] then
                chams[plr].Enabled = false
            end
            continue
        end
        
        local char = plr.Character
        if not char then
            if chams[plr] then
                chams[plr].Enabled = false
            end
            continue
        end
        
        local hum = char:FindFirstChild("Humanoid")
        if not hum or hum.Health <= 0 then
            if chams[plr] then
                chams[plr].Enabled = false
            end
            continue
        end
        
        if ts.Chams.Value then
            if not chams[plr] then
                chams[plr] = Instance.new("Highlight")
                chams[plr].Name = "AxisC"
                chams[plr].OutlineTransparency = 0
                chams[plr].FillTransparency = 0.5
                chams[plr].Parent = char
            end
            if chams[plr].Parent ~= char then
                chams[plr].Parent = char
            end
            chams[plr].FillColor = os.ChamsColor.Value
            chams[plr].Enabled = true
        elseif chams[plr] then
            chams[plr].Enabled = false
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

plrs.PlayerRemoving:Connect(function(plr)
    if chams[plr] then
        chams[plr]:Destroy()
        chams[plr] = nil
    end
end)

for _, plr in pairs(plrs:GetPlayers()) do
    if plr.Character then
        plr.CharacterRemoving:Connect(function()
            if chams[plr] then
                chams[plr]:Destroy()
                chams[plr] = nil
            end
        end)
    end
    plr.CharacterAdded:Connect(function()
        if chams[plr] then
            chams[plr]:Destroy()
            chams[plr] = nil
        end
    end)
end

lib:OnUnload(function()
    loop:Disconnect()
    for _, h in pairs(heads) do h:Remove() end
    for _, b in pairs(boxes) do b.b2d:Remove() for _, l in pairs(b.b3d) do l:Remove() end end
    for _, s in pairs(skeletons) do for _, l in pairs(s) do l:Remove() end end
    for _, c in pairs(chams) do
        if c then c:Destroy() end
    end
    for limb, data in pairs(originals) do
        if limb and limb.Parent then
            limb.Size = data.size
            limb.Transparency = data.trans
            limb.CanCollide = data.collide
        end
    end
end)

pcall(bypass)
