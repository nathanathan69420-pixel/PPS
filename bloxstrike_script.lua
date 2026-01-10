local lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/Library.lua"))()
local thm = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/addons/ThemeManager.lua"))()
local sav = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/addons/SaveManager.lua"))()

local plrs, rs, lp = game:GetService("Players"), game:GetService("RunService"), game:GetService("Players").LocalPlayer
local m, cam = lp:GetMouse(), workspace.CurrentCamera
local t, o = lib.Toggles, lib.Options

thm.BuiltInThemes["Default"][2] = {BackgroundColor="16293a",MainColor="26445f",AccentColor="5983a0",OutlineColor="325573",FontColor="d2dae1"}

local w = lib:CreateWindow({Title="Axis Hub -\nBloxstrike.lua",Footer="by RwalDev & Plow | v1.9.5",NotifySide="Right",ShowCustomCursor=true})
local ht, mt, st = w:AddTab("Home","house"), w:AddTab("Main","crosshair"), w:AddTab("Settings","settings")

ht:AddLeftGroupbox("Status"):AddLabel(string.format("Welcome, %s\nGame: Blox Strike", lp.DisplayName), true)
local aim = mt:AddLeftGroupbox("Aiming")
local vis = mt:AddRightGroupbox("Visuals")

aim:AddToggle("tb", {Text="Triggerbot",Default=false})
aim:AddSlider("td", {Text="Delay",Default=0.1,Min=0.1,Max=1,Rounding=1,Compact=true})
aim:AddToggle("hb", {Text="Hitbox Expander",Default=false})
aim:AddSlider("hs", {Text="Size",Default=5,Min=1,Max=15,Rounding=0,Compact=true})
aim:AddSlider("ht", {Text="Transparency",Default=0.7,Min=0,Max=1,Rounding=1,Compact=true})
aim:AddDropdown("hp", {Values={"Head","HumanoidRootPart","UpperTorso","LowerTorso","LeftUpperArm","RightUpperArm","All"},Default="All",Multi=true,Text="Parts"})

vis:AddToggle("ch", {Text="Chams",Default=false}):AddColorPicker("cc", {Default=Color3.fromRGB(0,170,255),Title="Color"})
vis:AddToggle("bx", {Text="Box ESP",Default=false})
vis:AddToggle("he", {Text="Head ESP",Default=false})

local hd, bx, ch, og = {}, {}, {}, {}

if getrawmetatable and setreadonly and newcclosure then
    local mt = getrawmetatable(game)
    local nc = mt.__namecall
    setreadonly(mt, false)
    mt.__namecall = newcclosure(function(s, ...)
        local nm = getnamecallmethod()
        if (nm == "Kick" or nm == "kick") and s == lp then return wait(9e9) end
        return nc(s, ...)
    end)
    setreadonly(mt, true)
end

local function dr(ty, pr)
    local obj = Drawing.new(ty)
    for k,v in pairs(pr) do obj[k] = v end
    return obj
end

local lt = 0
rs.RenderStepped:Connect(function()
    local n = tick()
    
    if t.tb and t.tb.Value and m.Target then
        local md = m.Target:FindFirstAncestorOfClass("Model")
        local p = md and plrs:GetPlayerFromCharacter(md)
        if p and p ~= lp and n - lt >= o.td.Value then mouse1click() lt = n end
    end

    for _, p in pairs(plrs:GetPlayers()) do
        if p == lp then continue end
        local c = p.Character
        if not c or not c:FindFirstChild("Humanoid") or c.Humanoid.Health <= 0 then
            if hd[p] then hd[p].Visible = false end
            if bx[p] then bx[p].Visible = false end
            if ch[p] then ch[p]:Destroy() ch[p] = nil end
            continue
        end

        local sel = o.hp.Value
        if t.hb and t.hb.Value then
            for _, nm in pairs({"Head","HumanoidRootPart","UpperTorso","LowerTorso","LeftUpperArm","RightUpperArm"}) do
                local pt = c:FindFirstChild(nm)
                if pt and pt:IsA("BasePart") and (sel["All"] or sel[nm]) then
                    if not og[pt] then og[pt] = {s=pt.Size, t=pt.Transparency} end
                    pt.Size = Vector3.new(o.hs.Value, o.hs.Value, o.hs.Value)
                    pt.Transparency = o.ht.Value
                end
            end
        else
            for pt, d in pairs(og) do
                if pt and pt.Parent then pt.Size = d.s pt.Transparency = d.t end
            end
        end
        
        if t.ch and t.ch.Value then
            if not ch[p] then
                local h = Instance.new("Highlight", c)
                h.FillTransparency = 0.5
                h.OutlineTransparency = 0
                h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                ch[p] = h
            end
            ch[p].FillColor = o.cc.Value
            ch[p].OutlineColor = o.cc.Value
        elseif ch[p] then ch[p]:Destroy() ch[p] = nil end

        if not hd[p] then hd[p] = dr("Circle", {Thickness=2,NumSides=20,Radius=6,Filled=true,Visible=false,Color=Color3.new(1,0,0)}) end
        local hp = c:FindFirstChild("Head")
        if t.he and t.he.Value and hp then
            local ps, vs = cam:WorldToViewportPoint(hp.Position)
            hd[p].Position = Vector2.new(ps.X, ps.Y)
            hd[p].Visible = vs
        else hd[p].Visible = false end

        if not bx[p] then bx[p] = dr("Square", {Thickness=1,Filled=false,Visible=false,Color=Color3.new(1,1,1)}) end
        if t.bx and t.bx.Value then
            local cf, sz = c:GetBoundingBox()
            local tp, o1 = cam:WorldToViewportPoint((cf * CFrame.new(0, sz.Y/2, 0)).Position)
            local bt, o2 = cam:WorldToViewportPoint((cf * CFrame.new(0, -sz.Y/2, 0)).Position)
            if o1 and o2 then
                local hv = math.abs(tp.Y - bt.Y)
                bx[p].Size = Vector2.new(hv * 0.6, hv)
                bx[p].Position = Vector2.new(tp.X - (hv * 0.6)/2, tp.Y)
                bx[p].Visible = true
            else bx[p].Visible = false end
        else bx[p].Visible = false end
    end
end)

local cfg = st:AddLeftGroupbox("Config")
cfg:AddToggle("km", {Default=lib.KeybindFrame.Visible,Text="Keybind Menu",Callback=function(v) lib.KeybindFrame.Visible = v end})
cfg:AddLabel("Menu bind"):AddKeyPicker("mk", {Default="RightControl",NoUI=true,Text="Menu bind"})
lib.ToggleKeybind = o.mk

thm:SetLibrary(lib) sav:SetLibrary(lib)
sav:IgnoreThemeSettings()
thm:SetFolder("PlowsScriptHub")
sav:SetFolder("PlowsScriptHub/BloxStrike")
sav:BuildConfigSection(st)
thm:ApplyToTab(st)
sav:LoadAutoloadConfig()

lib:OnUnload(function()
    for _, v in pairs(hd) do v:Remove() end
    for _, v in pairs(bx) do v:Remove() end
    for _, v in pairs(ch) do if v then v:Destroy() end end
    for pt, d in pairs(og) do if pt and pt.Parent then pt.Size = d.s pt.Transparency = d.t end end
end)
