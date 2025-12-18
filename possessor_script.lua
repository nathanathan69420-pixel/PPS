local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/"
local lib = loadstring(game:HttpGet(repo .. "Library.lua"))()
local theme = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local save = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local rs = game:GetService("RunService")
local lp = game.Players.LocalPlayer

theme.BuiltInThemes["Default"][2] = {
    BackgroundColor = "16293a",
    MainColor = "26445f",
    AccentColor = "5983a0",
    OutlineColor = "325573",
    FontColor = "d2dae1"
}

local win = lib:CreateWindow({
    Title = "AXIS HUB",
    Footer = "v1.3.2",
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

vis:AddToggle("ESP", {
    Text = "Possessor ESP",
    Default = false,
    Callback = function(v) _G.esp_on = v end
}):AddColorPicker("ESPColor", {
    Default = Color3.fromRGB(175, 25, 255),
    Title = "ESP Color"
})

cfgBox:AddToggle("KeyMenu", { 
    Default = lib.KeybindFrame.Visible, 
    Text = "Keybind Menu", 
    Callback = function(v) lib.KeybindFrame.Visible = v end 
})
cfgBox:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { Default = "RightControl", NoUI = true, Text = "Menu bind" })

status:AddLabel(string.format("Welcome, %s\nGame: Possessor", lp.DisplayName), true)
status:AddButton({ Text = "Unload", Func = function() lib:Unload() end })

local fpsLbl = stats:AddLabel("FPS: ...", true)
local pingLbl = stats:AddLabel("Ping: ...", true)

task.spawn(function()
    while task.wait(0.5) do
        if not _G.esp_on then
            for _, p in pairs(game.Players:GetPlayers()) do
                if p.Character then
                    local h = p.Character:FindFirstChild("AXIS_ESP")
                    if h then h.Enabled = false end
                end
            end
            continue
        end
        for _, p in pairs(game.Players:GetPlayers()) do
            if p ~= lp and p.Character then
                local h = p.Character:FindFirstChild("AXIS_ESP") or Instance.new("Highlight", p.Character)
                h.Name = "AXIS_ESP"
                h.FillColor = lib.Options.ESPColor.Value
                h.OutlineColor = Color3.fromRGB(255, 255, 255)
                h.FillTransparency = 0.5
                h.Enabled = p:GetAttribute("IsPossessor")
            end
        end
    end
end)

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
    _G.esp_on = false
    if conn then conn:Disconnect() end
    for _, p in pairs(game.Players:GetPlayers()) do
        if p.Character then
            local h = p.Character:FindFirstChild("AXIS_ESP")
            if h then h:Destroy() end
        end
    end
end)
