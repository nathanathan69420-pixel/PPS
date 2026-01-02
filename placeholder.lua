local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/"
local lib = loadstring(game:HttpGet(repo .. "Library.lua"))()
local theme = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local save = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

theme.BuiltInThemes["Default"][2] = {
    BackgroundColor = "16293a",
    MainColor = "26445f",
    AccentColor = "5983a0",
    OutlineColor = "325573",
    FontColor = "d2dae1"
}

local win = lib:CreateWindow({
    Title = "AXIS HUB",
    Footer = "by RwalDev & Plow | 1.7.2 | Discord: .gg/UuyxhqgEVs",
    NotifySide = "Right",
    ShowCustomCursor = true,
})

local tab = win:AddTab("Home", "house")
local status = tab:AddLeftGroupbox("Status")

local lp = game.Players.LocalPlayer
local name = lp and lp.DisplayName or "Player"
local time = os.date("%H:%M:%S")

status:AddLabel(string.format("Welcome, %s\nCurrent time: %s\nGame not supported.", name, time), true)

status:AddButton({
    Text = "Unload",
    Func = function() lib:Unload() end
})

local stats = tab:AddRightGroupbox("FPS & Ping")
local fpsLbl = stats:AddLabel("FPS: ...", true)
local pingLbl = stats:AddLabel("Ping: ...", true)

local rs = game:GetService("RunService")
local statService = game:GetService("Stats")

local elap, frames = 0, 0
local conn

conn = rs.RenderStepped:Connect(function(dt)
    frames = frames + 1
    elap = elap + dt

    if elap >= 1 then
        fpsLbl:SetText("FPS: " .. math.floor(frames / elap + 0.5))
        local net = statService.Network.ServerStatsItem["Data Ping"]
        pingLbl:SetText("Ping: " .. (net and math.floor(net:GetValue()) or 0) .. " ms")
        frames, elap = 0, 0
    end
end)

local sets = win:AddTab("Settings", "settings")
local cfg = sets:AddLeftGroupbox("Configuration")

cfg:AddToggle("KeybindMenu", {
    Default = lib.KeybindFrame.Visible,
    Text = "Keybind Menu",
    Callback = function(v) lib.KeybindFrame.Visible = v end
})

cfg:AddToggle("CustomCursor", {
    Text = "Custom Cursor",
    Default = true,
    Callback = function(v) lib.ShowCustomCursor = v end
})

cfg:AddDropdown("NotifySide", {
    Values = { "Left", "Right" },
    Default = "Right",
    Text = "Notification Side",
    Callback = function(v) lib:SetNotifySide(v) end
})

cfg:AddDropdown("DPIScale", {
    Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" },
    Default = "100%",
    Text = "DPI Scale",
    Callback = function(v)
        local n = tonumber(v:gsub("%%", ""))
        if n then lib:SetDPIScale(n / 100) end
    end
})

cfg:AddDivider()
cfg:AddLabel("Keybind"):AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })

cfg:AddButton({ Text = "Unload", Func = function() lib:Unload() end })

lib.ToggleKeybind = lib.Options.MenuKeybind

theme:SetLibrary(lib)
save:SetLibrary(lib)
save:IgnoreThemeSettings()
save:SetIgnoreIndexes({ "MenuKeybind" })

theme:SetFolder("PlowsScriptHub")
save:SetFolder("PlowsScriptHub/General")
save:SetSubFolder("Universal")

save:BuildConfigSection(sets)
theme:ApplyToTab(sets)

save:LoadAutoloadConfig()

lib:OnUnload(function()
    if conn then conn:Disconnect() end
end)
