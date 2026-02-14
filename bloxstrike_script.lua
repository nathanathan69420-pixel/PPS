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
    Title = "Axis Hub -\nBloxstrike.lua", Footer = "by RwalDev & Plow | 1.9.9", NotifySide = "Right", ShowCustomCursor = true,
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
aiming:AddSlider("HitboxSize", { Text = "Hitbox Size", Default = 5, Min = 1, Max = 15, Rounding = 0, Compact = true })

visuals:AddToggle("Chams", { Text = "Chams", Default = false }):AddColorPicker("ChamsColor", { Default = Color3.fromRGB(0, 170, 255), Title = "Chams Color" })
visuals:AddToggle("BoxESP", { Text = "Box ESP", Default = false })
visuals:AddDropdown("BoxType", { Values = { "2D", "3D" }, Default = "2D", Text = "Box Type" })
visuals:AddToggle("SkeletonESP", { Text = "Skeleton ESP", Default = false })
visuals:AddToggle("HeadESP", { Text = "Head ESP", Default = false })

local heads, boxes, skeletons, chams, proxies = {}, {}, {}, {}, {}

local BONE_PAIRS = {
    {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"}
}

local BOX_CONNECTIONS = {{1,2},{2,4},{4,3},{3,1}, {5,6},{6,8},{8,7},{7,5}, {1,5},{2,6},{3,7},{4,8}}

local proxyFolder = Instance.new("Folder")
proxyFolder.Name = "AxisProxy"
proxyFolder.Parent = workspace

local function isEnemy(p)
    if not p or p == lp then return false end
    if not lp.Team or not p.Team then return true end
    return lp.Team ~= p.Team
end

local function setupBypass()
    if not getrawmetatable or not setreadonly or not newcclosure or not checkcaller then return end
    local gm = getrawmetatable(game)
    local old_nc = gm.__namecall
    setreadonly(gm, false)
    gm.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if not checkcaller() and self == lp and (method == "Kick" or method == "kick") then
            return wait(9e9)
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

local function createProxy(plr, char)
    if proxies[plr] then return proxies[plr] end
    
    local proxyModel = Instance.new("Model")
    proxyModel.Name = plr.Name
    proxyModel.Parent = proxyFolder
    
    local head = char:FindFirstChild("Head")
    if head then
        local p = Instance.new("Part")
        p.Name = "Head"
        p.Size = Vector3.new(5, 5, 5)
        p.Transparency = 1
        p.CanCollide = false
        p.CanQuery = true
        p.CanTouch = false
        p.Anchored = true
        p.Parent = proxyModel
    end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then
        local p = Instance.new("Part")
        p.Name = "HumanoidRootPart"
        p.Size = Vector3.new(5, 5, 5)
        p.Transparency = 1
        p.CanCollide = false
        p.CanQuery = true
        p.CanTouch = false
        p.Anchored = true
        p.Parent = proxyModel
    end
    
    local hum = Instance.new("Humanoid")
    hum.Parent = proxyModel
    
    proxies[plr] = proxyModel
    return proxyModel
end

local function updateProxy(plr, char, size)
    local proxy = proxies[plr]
    if not proxy or not proxy.Parent then
        proxy = createProxy(plr, char)
    end
    
    local head = char:FindFirstChild("Head")
    local proxyHead = proxy:FindFirstChild("Head")
    if head and proxyHead then
        proxyHead.Size = Vector3.new(size, size, size)
        proxyHead.CFrame = head.CFrame
    end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local proxyHrp = proxy:FindFirstChild("HumanoidRootPart")
    if hrp and proxyHrp then
        proxyHrp.Size = Vector3.new(size, size, size)
        proxyHrp.CFrame = hrp.CFrame
    end
end

local function removeProxy(plr)
    if proxies[plr] then
        proxies[plr]:Destroy()
        proxies[plr] = nil
    end
end

local function safeClick()
    local vim = game:GetService("VirtualInputManager")
    if vim then
        vim:SendMouseButtonEvent(mouse.X, mouse.Y, 0, true, game, 0)
        task.wait(0.01)
        vim:SendMouseButtonEvent(mouse.X, mouse.Y, 0, false, game, 0)
    end
end

local lastT, lastHb = 0, 0
local loop = rs.RenderStepped:Connect(function()
    local now = tick()
    
    local hbEnabled = ts.HitboxExpander and ts.HitboxExpander.Value
    local hbSize = os.HitboxSize and os.HitboxSize.Value or 5
    
    if now - lastHb >= 0.05 then
        lastHb = now
        for _, plr in pairs(plrs:GetPlayers()) do
            if plr == lp then continue end
            local char = plr.Character
            local hum = char and char:FindFirstChild("Humanoid")
            
            if hbEnabled and char and hum and hum.Health > 0 and isEnemy(plr) then
                updateProxy(plr, char, hbSize)
            else
                removeProxy(plr)
            end
        end
    end
    
    if ts.Triggerbot and ts.Triggerbot.Value and mouse.Target then
        local target = mouse.Target
        local model = target:FindFirstAncestorOfClass("Model")
        local p = model and plrs:GetPlayerFromCharacter(model)
        
        if not p and model and model.Parent == proxyFolder then
            p = plrs:FindFirstChild(model.Name)
        end
        
        if p and isEnemy(p) and (now - lastT >= os.TriggerDelay.Value) then
            safeClick()
            lastT = now
        end
    end

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
            if chams[plr] then chams[plr].Enabled = false end
            continue
        end
        
        local char = plr.Character
        if not char then continue end
        local hum = char:FindFirstChild("Humanoid")
        if not hum or hum.Health <= 0 then
            if chams[plr] then chams[plr].Enabled = false end
            if heads[plr] then heads[plr].Visible = false end
            if boxes[plr] then
                boxes[plr].b2d.Visible = false
                for _, l in pairs(boxes[plr].b3d) do l.Visible = false end
            end
            if skeletons[plr] then
                for _, l in pairs(skeletons[plr]) do l.Visible = false end
            end
            continue
        end
        
        if ts.Chams and ts.Chams.Value then
            if not chams[plr] then
                chams[plr] = Instance.new("Highlight")
                chams[plr].OutlineTransparency = 0
                chams[plr].FillTransparency = 0.5
                chams[plr].Parent = char
            end
            if chams[plr].Parent ~= char then chams[plr].Parent = char end
            chams[plr].FillColor = os.ChamsColor.Value
            chams[plr].Enabled = true
        elseif chams[plr] then
            chams[plr].Enabled = false
        end

        if ts.HeadESP and ts.HeadESP.Value then
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

        if ts.BoxESP and ts.BoxESP.Value then
            if not boxes[plr] then
                boxes[plr] = { b2d = draw("Square", { Thickness = 1, Filled = false, Visible = false }), b3d = {} }
            end
            local cf, sz = char:GetBoundingBox()
            if os.BoxType.Value == "2D" then
                for _, l in pairs(boxes[plr].b3d) do l.Visible = false end
                local t, on1 = cam:WorldToViewportPoint((cf * CFrame.new(0, sz.Y/2, 0)).Position)
                local bot, on2 = cam:WorldToViewportPoint((cf * CFrame.new(0, -sz.Y/2, 0)).Position)
                if on1 and on2 then
                    local hV = math.abs(t.Y - bot.Y)
                    local wV = hV * 0.6
                    boxes[plr].b2d.Size = Vector2.new(wV, hV)
                    boxes[plr].b2d.Position = Vector2.new(t.X - wV/2, t.Y)
                    boxes[plr].b2d.Color = Color3.new(1, 1, 1)
                    boxes[plr].b2d.Visible = true
                else
                    boxes[plr].b2d.Visible = false
                end
            else
                boxes[plr].b2d.Visible = false
                local corners = {
                    cf * CFrame.new(-sz.X/2, sz.Y/2, sz.Z/2), cf * CFrame.new(sz.X/2, sz.Y/2, sz.Z/2),
                    cf * CFrame.new(-sz.X/2, -sz.Y/2, sz.Z/2), cf * CFrame.new(sz.X/2, -sz.Y/2, sz.Z/2),
                    cf * CFrame.new(-sz.X/2, sz.Y/2, -sz.Z/2), cf * CFrame.new(sz.X/2, sz.Y/2, -sz.Z/2),
                    cf * CFrame.new(-sz.X/2, -sz.Y/2, -sz.Z/2), cf * CFrame.new(sz.X/2, -sz.Y/2, -sz.Z/2)
                }
                for i, conn in ipairs(BOX_CONNECTIONS) do
                    if not boxes[plr].b3d[i] then
                        boxes[plr].b3d[i] = draw("Line", { Thickness = 1, Color = Color3.new(1,1,1), Visible = false })
                    end
                    local p1, v1 = cam:WorldToViewportPoint(corners[conn[1]].Position)
                    local p2, v2 = cam:WorldToViewportPoint(corners[conn[2]].Position)
                    if v1 and v2 then
                        boxes[plr].b3d[i].From = Vector2.new(p1.X, p1.Y)
                        boxes[plr].b3d[i].To = Vector2.new(p2.X, p2.Y)
                        boxes[plr].b3d[i].Visible = true
                    else
                        boxes[plr].b3d[i].Visible = false
                    end
                end
            end
        elseif boxes[plr] then
            boxes[plr].b2d.Visible = false
            for _, l in pairs(boxes[plr].b3d) do l.Visible = false end
        end

        if ts.SkeletonESP and ts.SkeletonESP.Value then
            if not skeletons[plr] then skeletons[plr] = {} end
            for i, pair in ipairs(BONE_PAIRS) do
                if not skeletons[plr][i] then
                    skeletons[plr][i] = draw("Line", { Thickness = 1, Color = Color3.new(1,1,1), Visible = false })
                end
                local b1, b2 = char:FindFirstChild(pair[1]), char:FindFirstChild(pair[2])
                if b1 and b2 then
                    local p1, v1 = cam:WorldToViewportPoint(b1.Position)
                    local p2, v2 = cam:WorldToViewportPoint(b2.Position)
                    skeletons[plr][i].From = Vector2.new(p1.X, p1.Y)
                    skeletons[plr][i].To = Vector2.new(p2.X, p2.Y)
                    skeletons[plr][i].Visible = v1 and v2
                else
                    skeletons[plr][i].Visible = false
                end
            end
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
    proxyFolder:Destroy()
    for _, h in pairs(heads) do h:Remove() end
    for _, b in pairs(boxes) do b.b2d:Remove() for _, l in pairs(b.b3d) do l:Remove() end end
    for _, s in pairs(skeletons) do for _, l in pairs(s) do l:Remove() end end
    for _, c in pairs(chams) do if c then c:Destroy() end end
end)

setupBypass()
