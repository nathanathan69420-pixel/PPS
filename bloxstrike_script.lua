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
        if not checkcaller() and method == "Kick" and self == lp then return nil end
        return old_nc(self, ...)
    end)
    setreadonly(gm, true)
end

local plrs = game:GetService("Players")
local rs = game:GetService("RunService")
local lp = plrs.LocalPlayer
local mouse = lp:GetMouse()
local cam = workspace.CurrentCamera

local ts = lib.Toggles
local os = lib.Options

theme.BuiltInThemes["Default"][2] = {
    BackgroundColor = "16293a",
    MainColor = "26445f",
    AccentColor = "5983a0",
    OutlineColor = "325573",
    FontColor = "d2dae1"
}

local win = lib:CreateWindow({
    Title = "Axis Hub -\nBloxstrike.lua",
    Footer = "by RwalDev & Plow | 1.8.4",
    NotifySide = "Right",
    ShowCustomCursor = true,
})

local hTab = win:AddTab("Home", "house")
local mTab = win:AddTab("Main", "crosshair")
local sTab = win:AddTab("Settings", "settings")

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

visuals:AddToggle("Chams", { Text = "Chams", Default = false }):AddColorPicker("ChamsColor", { Default = Color3.fromRGB(255, 0, 0), Title = "Chams Color" })
visuals:AddToggle("BoxESP", { Text = "Box ESP", Default = false })
visuals:AddDropdown("BoxType", { Values = { "2D", "3D" }, Default = "2D", Text = "Box Type" })
visuals:AddToggle("SkeletonESP", { Text = "Skeleton ESP", Default = false })
visuals:AddToggle("HeadESP", { Text = "Head ESP", Default = false })

local boxes = {}
local heads = {}
local originals = {}
local proxies = {}

local function isEnemy(plr)
    if not plr or plr == lp then return false end
    if not lp.Team or not plr.Team then return true end
    return lp.Team ~= plr.Team
end

local function cleanProxies(part)
    if proxies[part] then
        for _, v in pairs(proxies[part]) do if v then v:Destroy() end end
        proxies[part] = nil
    end
end

local function updateHitboxes()
    local expandEnabled = ts.HitboxExpander.Value
    local size = os.HitboxSize.Value
    local transparency = os.HitboxTransparency.Value
    local selected = os.Hitboxes.Value

    for _, plr in pairs(plrs:GetPlayers()) do
        if plr ~= lp and plr.Character then
            local char = plr.Character
            local enemy = isEnemy(plr)
            local hum = char:FindFirstChildOfClass("Humanoid")
            
            if hum and hum.Health > 0 then
                for _, p in pairs(char:GetChildren()) do
                    if p:IsA("BasePart") then
                        if not originals[p] then originals[p] = { size = p.Size, trans = p.Transparency } end
                        
                        local shouldExpand = expandEnabled and enemy and (selected["All"] or selected[p.Name])
                        
                        if shouldExpand then
                            p.Size = Vector3.new(size, size, size)
                            p.Transparency = 1
                            p.CanCollide = false
                            
                            if not proxies[p] then
                                local fake = Instance.new("Part")
                                fake.Name = "AxisFake"
                                fake.Size = originals[p].size
                                fake.Color = p.Color
                                fake.Material = p.Material
                                fake.CanCollide = false
                                fake.CanTouch = false
                                fake.CanQuery = false
                                fake.Transparency = originals[p].trans
                                fake.Parent = char
                                
                                local weld = Instance.new("WeldConstraint")
                                weld.Part0 = fake
                                weld.Part1 = p
                                weld.Parent = fake
                                
                                local viz = Instance.new("Part")
                                viz.Name = "AxisViz"
                                viz.Size = p.Size
                                viz.Shape = p.Shape
                                viz.Color = Color3.fromRGB(255, 255, 255)
                                viz.Material = Enum.Material.ForceField
                                viz.CanCollide = false
                                viz.CanTouch = false
                                viz.CanQuery = false
                                viz.Parent = char
                                
                                local weld2 = Instance.new("WeldConstraint")
                                weld2.Part0 = viz
                                weld2.Part1 = p
                                weld2.Parent = viz
                                
                                proxies[p] = { fake = fake, viz = viz }
                            end
                            
                            local pData = proxies[p]
                            pData.viz.Size = p.Size
                            pData.viz.Transparency = transparency
                        else
                            p.Size = originals[p].size
                            p.Transparency = originals[p].trans
                            p.CanCollide = true
                            cleanProxies(p)
                        end
                    end
                end
            end
        end
    end
end

local lastTrigger = 0
rs.Heartbeat:Connect(function()
    if ts.Triggerbot.Value and mouse.Target then
        local target = mouse.Target
        local model = target:FindFirstAncestorOfClass("Model")
        local plr = model and plrs:GetPlayerFromCharacter(model)
        
        if plr and isEnemy(plr) then
            local now = tick()
            if now - lastTrigger >= os.TriggerDelay.Value then
                mouse1click()
                lastTrigger = now
            end
        end
    end
    
    updateHitboxes()
    
    for _, plr in pairs(plrs:GetPlayers()) do
        if plr ~= lp and plr.Character then
            local char = plr.Character
            local hum = char:FindFirstChildOfClass("Humanoid")
            local head = char:FindFirstChild("Head")
            local enemy = isEnemy(plr)
            
            local cham = char:FindFirstChild("AxisCham")
            if ts.Chams.Value and enemy and hum and hum.Health > 0 then
                if not cham then
                    cham = Instance.new("Highlight")
                    cham.Name = "AxisCham"
                    cham.Parent = char
                end
                cham.FillColor = os.ChamsColor.Value
                cham.FillTransparency = 0.5
                cham.OutlineColor = Color3.new(1, 1, 1)
                cham.Enabled = true
            elseif cham then
                cham.Enabled = false
            end

            if not heads[plr] then
                local h = Drawing.new("Circle")
                h.Thickness = 1
                h.NumSides = 12
                h.Radius = 5
                h.Filled = true
                heads[plr] = h
            end
            
            local hESP = heads[plr]
            if ts.HeadESP.Value and enemy and head and hum and hum.Health > 0 then
                local pos, vis = cam:WorldToViewportPoint(head.Position)
                if vis then
                    hESP.Position = Vector2.new(pos.X, pos.Y)
                    hESP.Color = Color3.new(1, 0, 0)
                    hESP.Visible = true
                else
                    hESP.Visible = false
                end
            else
                hESP.Visible = false
            end

            if not boxes[plr] then
                local b = Drawing.new("Square")
                b.Thickness = 1
                b.Filled = false
                boxes[plr] = b
            end
            
            local bESP = boxes[plr]
            if ts.BoxESP.Value and enemy and hum and hum.Health > 0 then
                local _, vis = cam:WorldToViewportPoint(char:GetPivot().Position)
                if vis then
                    local size, pos = char:GetBoundingBox()
                    local top, on1 = cam:WorldToViewportPoint((pos * CFrame.new(0, size.Y/2, 0)).Position)
                    local bottom, on2 = cam:WorldToViewportPoint((pos * CFrame.new(0, -size.Y/2, 0)).Position)
                    
                    if on1 and on2 then
                        local h = math.abs(top.Y - bottom.Y)
                        local w = h * 0.6
                        bESP.Size = Vector2.new(w, h)
                        bESP.Position = Vector2.new(top.X - w/2, top.Y)
                        bESP.Color = Color3.new(1, 1, 1)
                        bESP.Visible = true
                    else
                        bESP.Visible = false
                    end
                else
                    bESP.Visible = false
                end
            else
                bESP.Visible = false
            end
        else
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
save:SetIgnoreIndexes({ "MenuKeybind" })
theme:SetFolder("PlowsScriptHub")
save:SetFolder("PlowsScriptHub/BloxStrike")
save:BuildConfigSection(sTab)
theme:ApplyToTab(sTab)
save:LoadAutoloadConfig()

lib:OnUnload(function()
    for _, h in pairs(heads) do h:Remove() end
    for _, b in pairs(boxes) do b:Remove() end
    for p, d in pairs(originals) do if p and p.Parent then p.Size = d.size p.Transparency = d.trans p.CanCollide = true end end
    for _, pTable in pairs(proxies) do for _, v in pairs(pTable) do if v then v:Destroy() end end end
end)

pcall(bypass)
