local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/"
local lib = loadstring(game:HttpGet(repo .. "Library.lua"))()
local theme = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local save = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local rs = game:GetService("RunService")
local plrs = game:GetService("Players")
local lp = plrs.LocalPlayer

theme.BuiltInThemes["Default"][2] = {
    BackgroundColor = "16293a",
    MainColor = "26445f",
    AccentColor = "5983a0",
    OutlineColor = "325573",
    FontColor = "d2dae1"
}

local win = lib:CreateWindow({
    Title = "Axis Hub - Possessor.lua",
    Footer = "by RwalDev & Plow | 1.8.4 | Discord: .gg/UuyxhqgEVs",
    NotifySide = "Right",
    ShowCustomCursor = true,
})

local home = win:AddTab("Home", "house")
local main = win:AddTab("Main", "ghost")
local config = win:AddTab("Settings", "settings")

local status = home:AddLeftGroupbox("Status")
local stats = home:AddRightGroupbox("FPS & Ping")
local vis = main:AddLeftGroupbox("Visuals", "eye")
local cfgBox = config:AddLeftGroupbox("Config")

vis:AddToggle("PossessorESP", {
    Text = "Possessor ESP",
    Default = false,
    Callback = function() end
}):AddColorPicker("ESPColor", {
    Default = Color3.fromRGB(175, 25, 255),
    Title = "ESP Color"
})

local ot = {}
vis:AddToggle("XRay", {
    Text = "X-Ray",
    Default = false,
    Callback = function(v)
        if v then
            for _, o in ipairs(workspace:GetDescendants()) do
                if o:IsA("BasePart") and o.Transparency < 0.7 and not o:IsDescendantOf(lp.Character or {}) then
                    local n = o.Name:lower()
                    if n:find("wall") or n:find("door") or n:find("floor") or n:find("ceil") or n:find("roof") or o.Size.X > 10 or o.Size.Z > 10 then
                        ot[o] = o.Transparency
                        o.Transparency = 0.7
                    end
                end
            end
        else
            for o, t in pairs(ot) do
                if o and o.Parent then o.Transparency = t end
            end
            table.clear(ot)
        end
    end
})


local Storage = Instance.new("Folder")
Storage.Name = "AXIS_Storage"
Storage.Parent = game:GetService("CoreGui")

local espLoop = rs.Heartbeat:Connect(function()
    local on = lib.Toggles.PossessorESP and lib.Toggles.PossessorESP.Value
    local color = lib.Options.ESPColor and lib.Options.ESPColor.Value or Color3.new(1, 1, 1)

    for _, p in ipairs(plrs:GetPlayers()) do
        if p ~= lp then
            local char = p.Character
            local h = Storage:FindFirstChild(p.Name)
            
            local val = p:GetAttribute("IsPossessor")
            local isP = (val == true or tostring(val):lower() == "true")
            local isA = (p:GetAttribute("Alive") == true)

            if on and isP and isA and char then
                if not h then
                    h = Instance.new("Highlight")
                    h.Name = p.Name
                    h.Parent = Storage
                    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    h.OutlineColor = Color3.new(1, 1, 1)
                    h.FillTransparency = 0.55
                    h.OutlineTransparency = 0
                end
                h.Adornee = char
                h.FillColor = color
                h.Enabled = true
            else
                if h then
                    h.Enabled = false
                end
            end
        end
    end
end)

plrs.PlayerRemoving:Connect(function(p)
    local h = Storage:FindFirstChild(p.Name)
    if h then h:Destroy() end
end)

status:AddLabel(string.format("Welcome, %s\nGame: Possessor", lp.DisplayName), true)
status:AddButton({ Text = "Unload", Func = function() lib:Unload() end })

local fpsLbl = stats:AddLabel("FPS: ...", true)
local pingLbl = stats:AddLabel("Ping: ...", true)

cfgBox:AddToggle("KeyMenu", { Default = lib.KeybindFrame.Visible, Text = "Keybind Menu", Callback = function(v) lib.KeybindFrame.Visible = v end })
cfgBox:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { Default = "RightControl", NoUI = true, Text = "Menu keybind" })
lib.ToggleKeybind = lib.Options.MenuKeybind

local elap, frames = 0, 0
local conn = rs.RenderStepped:Connect(function(dt)
    frames = frames + 1
    elap = elap + dt
    if elap >= 1 then
        fpsLbl:SetText("FPS: " .. math.floor(frames / elap + 0.5))
        local net = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]
        pingLbl:SetText("Ping: " .. (net and math.floor(net:GetValue()) or 0) .. " ms")
        frames, elap = 0, 0
    end
end)

theme:SetLibrary(lib)
save:SetLibrary(lib)
save:IgnoreThemeSettings()
save:SetIgnoreIndexes({ "MenuKeybind" })
theme:SetFolder("PlowsScriptHub")
save:SetFolder("PlowsScriptHub/Possessor")
save:BuildConfigSection(config)
theme:ApplyToTab(config)
save:LoadAutoloadConfig()

lib:OnUnload(function()
    if espLoop then espLoop:Disconnect() end
    if conn then conn:Disconnect() end
    if Storage then Storage:Destroy() end
end)
