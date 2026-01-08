local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/"
local lib = loadstring(game:HttpGet(repo .. "Library.lua"))()
local theme = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local save = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local function stealth()
    if not getrawmetatable or not setreadonly or not newcclosure then return end
    local g = game
    local lp = g:GetService("Players").LocalPlayer
    local gm = getrawmetatable(g)
    local old_nc = gm.__namecall
    local old_idx = gm.__index

    setreadonly(gm, false)
    gm.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if not checkcaller() and (method == "Kick" or method == "kick") and self == lp then return nil end
        return old_nc(self, ...)
    end)
    
    gm.__index = newcclosure(function(self, k)
        if not checkcaller() and self:IsA("BasePart") and self:IsDescendantOf(workspace) then
            if k == "Size" and self:FindFirstChild("AxisOriginalSize") then
                return self.AxisOriginalSize.Value
            elseif k == "Transparency" and self:FindFirstChild("AxisOriginalTrans") then
                return self.AxisOriginalTrans.Value
            end
        end
        return old_idx(self, k)
    end)
    setreadonly(gm, true)
end

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

local heads, boxes, cache = {}, {}, {}

local function isEnemy(plr)
    if not plr or plr == lp then return false end
    if not lp.Team or not plr.Team then return true end
    return lp.Team ~= plr.Team
end

local function apply(p, sz, trans)
    if not p:FindFirstChild("AxisOriginalSize") then
        local v = Instance.new("Vector3Value", p)
        v.Name = "AxisOriginalSize"
        v.Value = p.Size
    end
    if not p:FindFirstChild("AxisOriginalTrans") then
        local v = Instance.new("NumberValue", p)
        v.Name = "AxisOriginalTrans"
        v.Value = p.Transparency
    end
    p.Size, p.Transparency = sz, trans
end

local function reset(p)
    local s = p:FindFirstChild("AxisOriginalSize")
    local t = p:FindFirstChild("AxisOriginalTrans")
    if s then p.Size = s.Value s:Destroy() end
    if t then p.Transparency = t.Value t:Destroy() end
    local v = p:FindFirstChild("AxisViz")
    if v then v:Destroy() end
end

local function updateHitboxes()
    local enabled, size, trans, parts = ts.HitboxExpander.Value, os.HitboxSize.Value, os.HitboxTransparency.Value, os.Hitboxes.Value
    for _, plr in pairs(plrs:GetPlayers()) do
        local enemy = isEnemy(plr)
        local char = plr.Character
        if char and enemy then
            for _, p in pairs(char:GetChildren()) do
                if p:IsA("BasePart") and (parts["All"] or parts[p.Name]) then
                    if enabled then
                        apply(p, Vector3.new(size, size, size), 1)
                        local viz = p:FindFirstChild("AxisViz")
                        if not viz then
                            viz = Instance.new("SelectionBox")
                            viz.Name = "AxisViz"
                            viz.LineAlpha = 0
                            viz.SurfaceColor3 = Color3.new(1, 1, 1)
                            viz.Adornee = p
                            viz.Parent = p
                        end
                        viz.SurfaceAlpha = trans * 0.5
                    else
                        reset(p)
                    end
                end
            end
        elseif char then
            for _, p in pairs(char:GetChildren()) do if p:IsA("BasePart") then reset(p) end end
        end
    end
end

local lastT = 0
local loop = rs.Heartbeat:Connect(function()
    local tbOn = ts.Triggerbot.Value
    if tbOn and mouse.Target then
        local m = mouse.Target:FindFirstAncestorOfClass("Model")
        local p = m and plrs:GetPlayerFromCharacter(m)
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
            local cham = char:FindFirstChild("AxisC")
            if ts.Chams.Value then
                if not cham then
                    cham = Instance.new("Highlight", char)
                    cham.Name = "AxisC"
                    cham.OutlineTransparency = 0
                    cham.FillTransparency = 0.5
                end
                cham.FillColor = os.ChamsColor.Value
                cham.Enabled = true
            elseif cham then cham.Enabled = false end

            if not heads[plr] then
                heads[plr] = Drawing.new("Circle")
                heads[plr].Thickness, heads[plr].NumSides, heads[plr].Radius, heads[plr].Filled = 1, 12, 5, true
            end
            local h, head = heads[plr], char:FindFirstChild("Head")
            if ts.HeadESP.Value and head then
                local pos, vis = cam:WorldToViewportPoint(head.Position)
                if vis then
                    h.Position, h.Color, h.Visible = Vector2.new(pos.X, pos.Y), Color3.new(1, 0, 0), true
                else h.Visible = false end
            else h.Visible = false end

            if not boxes[plr] then
                boxes[plr] = Drawing.new("Square")
                boxes[plr].Thickness, boxes[plr].Filled = 1, false
            end
            local b = boxes[plr]
            if ts.BoxESP.Value then
                local size, pos = char:GetBoundingBox()
                local t, on1 = cam:WorldToViewportPoint((pos * CFrame.new(0, size.Y/2, 0)).Position)
                local bot, on2 = cam:WorldToViewportPoint((pos * CFrame.new(0, -size.Y/2, 0)).Position)
                if on1 and on2 then
                    local hVal = math.abs(t.Y - bot.Y)
                    local wVal = hVal * 0.6
                    b.Size, b.Position, b.Color, b.Visible = Vector2.new(wVal, hVal), Vector2.new(t.X - wVal/2, t.Y), Color3.new(1, 1, 1), true
                else b.Visible = false end
            else b.Visible = false end
        else
            if char then
                local cham = char:FindFirstChild("AxisC")
                if cham then cham.Enabled = false end
            end
            if heads[plr] then heads[plr].Visible = false end
            if boxes[plr] then boxes[plr].Visible = false end
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
    for _, h in pairs(heads) do h:Remove() end
    for _, b in pairs(boxes) do b:Remove() end
    for _, plr in pairs(plrs:GetPlayers()) do
        if plr.Character then
            local cham = plr.Character:FindFirstChild("AxisC")
            if cham then cham:Destroy() end
            for _, p in pairs(plr.Character:GetChildren()) do if p:IsA("BasePart") then reset(p) end end
        end
    end
end)

pcall(stealth)
