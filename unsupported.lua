local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/"
local lib = loadstring(game:HttpGet(repo .. "Library.lua"))()
local theme = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local save = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local rs = game:GetService("RunService")
local lp = game.Players.LocalPlayer

lib.Scheme.BackgroundColor = Color3.fromRGB(22, 41, 58)
lib.Scheme.MainColor = Color3.fromRGB(38, 68, 95)
lib.Scheme.AccentColor = Color3.fromRGB(89, 131, 160)
lib.Scheme.OutlineColor = Color3.fromRGB(50, 85, 115)
lib.Scheme.FontColor = Color3.fromRGB(210, 218, 225)

local win = lib:CreateWindow({
    Title = "AXIS HUB",
    Footer = "v1.3.2",
    NotifySide = "Right",
    ShowCustomCursor = true,
})

local home = win:AddTab("Home", "house")
local config = win:AddTab("Settings", "settings")

local status = home:AddLeftGroupbox("Status")
local stats = home:AddRightGroupbox("FPS & Ping")
local cfgBox = config:AddLeftGroupbox("Config")

local name = lp and lp.DisplayName or "Player"
local time = os.date("%H:%M:%S")

status:AddLabel(string.format("Welcome, %s\nCurrent time: %s\nGame not supported.", name, time), true)
status:AddButton({ Text = "Unload", Func = function() lib:Unload() end })

local fpsLbl = stats:AddLabel("FPS: ...", true)
local pingLbl = stats:AddLabel("Ping: ...", true)

cfgBox:AddToggle("KeyMenu", { Default = lib.KeybindFrame.Visible, Text = "Keybind Menu", Callback = function(v) lib.KeybindFrame.Visible = v end })
cfgBox:AddButton({ Text = "Unload", Func = function() lib:Unload() end })

local elap, frames = 0, 0
local conn_fps = rs.RenderStepped:Connect(function(dt)
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
theme:SetFolder("PlowsScriptHub")
save:SetFolder("PlowsScriptHub/General")
save:SetSubFolder("Universal")
save:BuildConfigSection(config)
theme:ApplyToTab(config)
save:LoadAutoloadConfig()

lib:OnUnload(function()
    if conn_fps then conn_fps:Disconnect() end
end)
