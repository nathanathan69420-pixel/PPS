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
    Title = "Axis Hub -\nBloxstrike.lua", Footer = "by RwalDev & Plow | v1.9.5", NotifySide = "Right", ShowCustomCursor = true,
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
visuals:AddToggle("HeadESP", { Text = "Head ESP", Default = false })

local heads, boxes, chams, originals = {}, {}, {}, {}

local function setupBypass()
    if not getrawmetatable or not setreadonly or not newcclosure then return end
    
    local mt = getrawmetatable(game)
    local oldNamecall = mt.__namecall
    
    setreadonly(mt, false)
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if method == "Kick" or method == "kick" then
            if self == lp then
                return wait(9e9)
            end
        end
        return oldNamecall(self, ...)
    end)
    setreadonly(mt, true)
end

local function draw(t, p)
    local o = Drawing.new(t)
    for k, v in pairs(p) do o[k] = v end
    return o
end

local lastT = 0
local loop = rs.RenderStepped:Connect(function()
    local now = tick()
    
    if ts.Triggerbot and ts.Triggerbot.Value then
        local target = mouse.Target
        if target and target.Parent then
            local model = target:FindFirstAncestorOfClass("Model")
            local p = model and plrs:GetPlayerFromCharacter(model)
            if p and p ~= lp and now - lastT >= os.TriggerDelay.Value then
                mouse1click()
                lastT = now
            end
        end
    end

    for _, plr in pairs(plrs:GetPlayers()) do
        if plr == lp then continue end
        local c = plr.Character
        if c and c:FindFirstChild("Humanoid") and c.Humanoid.Health > 0 then
            if ts.HitboxExpander and ts.HitboxExpander.Value then
                for _, name in pairs({"Head", "UpperTorso", "HumanoidRootPart"}) do
                    local part = c:FindFirstChild(name)
                    if part and part:IsA("BasePart") then
                        if not originals[part] then
                            originals[part] = part.Size
                        end
                        local s = os.HitboxSize.Value
                        part.Size = Vector3.new(s, s, s)
                        part.Transparency = 0.7
                    end
                end
            else
                for part, size in pairs(originals) do
                    if part and part.Parent then
                        part.Size = size
                        part.Transparency = 0
                    end
                end
            end
            
            if ts.Chams and ts.Chams.Value then
                if not chams[plr] then
                    local h = Instance.new("Highlight")
                    h.FillTransparency = 0.5
                    h.OutlineTransparency = 0
                    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    h.Parent = c
                    chams[plr] = h
                end
                chams[plr].FillColor = os.ChamsColor.Value
                chams[plr].OutlineColor = os.ChamsColor.Value
            else
                if chams[plr] then
                    chams[plr]:Destroy()
                    chams[plr] = nil
                end
            end

            if not heads[plr] then heads[plr] = draw("Circle", { Thickness = 2, NumSides = 20, Radius = 6, Filled = true, Visible = false, Color = Color3.new(1, 0, 0) }) end
            local head = c:FindFirstChild("Head")
            if ts.HeadESP and ts.HeadESP.Value and head then
                local pos, vis = cam:WorldToViewportPoint(head.Position)
                heads[plr].Position = Vector2.new(pos.X, pos.Y)
                heads[plr].Visible = vis
            else 
                heads[plr].Visible = false 
            end

            if not boxes[plr] then boxes[plr] = draw("Square", { Thickness = 1, Filled = false, Visible = false, Color = Color3.new(1, 1, 1) }) end
            if ts.BoxESP and ts.BoxESP.Value then
                local cf, sz = c:GetBoundingBox()
                local t, on1 = cam:WorldToViewportPoint((cf * CFrame.new(0, sz.Y/2, 0)).Position)
                local bot, on2 = cam:WorldToViewportPoint((cf * CFrame.new(0, -sz.Y/2, 0)).Position)
                if on1 and on2 then
                    local hV = math.abs(t.Y - bot.Y)
                    local wV = hV * 0.6
                    boxes[plr].Size = Vector2.new(wV, hV)
                    boxes[plr].Position = Vector2.new(t.X - wV/2, t.Y)
                    boxes[plr].Visible = true
                else 
                    boxes[plr].Visible = false 
                end
            else
                boxes[plr].Visible = false
            end
        else
            if heads[plr] then heads[plr].Visible = false end
            if boxes[plr] then boxes[plr].Visible = false end
            if chams[plr] then chams[plr]:Destroy() chams[plr] = nil end
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
    for _, h in pairs(chams) do if h then h:Destroy() end end
    for part, size in pairs(originals) do
        if part and part.Parent then
            part.Size = size
            part.Transparency = 0
        end
    end
end)

setupBypass()
