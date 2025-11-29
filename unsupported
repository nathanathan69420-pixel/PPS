local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

if not Library then
    return
end

local mainWindow = Library:CreateWindow({
    Title = "Plow's\nPrivate Script",
    Footer = "version: 1.0",
    NotifySide = "Right",
    ShowCustomCursor = true,
})

local homeTab = mainWindow:AddTab({
    Name = "Home",
    Icon = "house",
    Description = "Greetings from plow."
})

local settingsTab = mainWindow:AddTab({
    Name = "Settings",
    Icon = "gear",
    Description = "Configure script settings."
})

local homeGroupbox = homeTab:AddGroupbox({
    Name = "Greetings"
})

local configGroupbox = settingsTab:AddGroupbox({
    Name = "Configuration"
})

local LocalPlayer = game.Players.LocalPlayer
local displayName = LocalPlayer and LocalPlayer.DisplayName or "Player"

local currentTime = os.date("%A, %B %d, %Y %H:%M:%S", os.time())

local supportedJobIds = {
}

local currentGameJobId = game.JobId
local supportMessage = ""
local isSupported = false

for _, jobId in ipairs(supportedJobIds) do
    if jobId == currentGameJobId then
        isSupported = true
        break
    end
end

if isSupported then
    supportMessage = "supports."
else
    supportMessage = "doesn't support."
end

local welcomeLabelText = string.format("Hello, %s\nToday is %s (Local Time)\nYou are currently in a game that Plow's script %s", displayName, currentTime, supportMessage)

homeGroupbox:AddLabel({
    Text = welcomeLabelText,
    DoesWrap = true,
    Size = 16,
})

homeGroupbox:AddButton({
    Text = "Unload Script",
    Func = function()
        Library:Unload()
    end,
})

-- UI Settings from example script, added to configGroupbox
configGroupbox:AddToggle("KeybindMenuOpen", {
    Default = Library.KeybindFrame.Visible,
    Text = "Open Keybind Menu",
    Callback = function(value)
        Library.KeybindFrame.Visible = value
    end,
})
configGroupbox:AddToggle("ShowCustomCursor", {
    Text = "Custom Cursor",
    Default = true,
    Callback = function(Value)
        Library.ShowCustomCursor = Value
    end,
})
configGroupbox:AddDropdown("NotificationSide", {
    Values = { "Left", "Right" },
    Default = "Right",
    Text = "Notification Side",
    Callback = function(Value)
        Library:SetNotifySide(Value)
    end,
})
configGroupbox:AddDropdown("DPIDropdown", {
    Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" },
    Default = "100%",
    Text = "DPI Scale",
    Callback = function(Value)
        Value = Value:gsub("%%", "")
        local DPI = tonumber(Value)
        Library:SetDPIScale(DPI)
    end,
})
configGroupbox:AddDivider()
configGroupbox:AddLabel("Menu bind")
    :AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })

configGroupbox:AddButton("Unload", {
    Text = "Unload UI", -- Renamed to avoid confusion with the other "Unload Script"
    Func = function()
        Library:Unload()
    end,
})

Library.ToggleKeybind = Options.MenuKeybind -- Assuming Options is correctly populated by Obsidian

-- Addons setup (ThemeManager and SaveManager)
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
ThemeManager:SetFolder("PlowsScriptHub") -- Custom folder name
SaveManager:SetFolder("PlowsScriptHub/specific-game") -- Custom folder name
SaveManager:SetSubFolder("specific-place") -- Custom folder name
SaveManager:BuildConfigSection(settingsTab) -- Build config section on settingsTab
ThemeManager:ApplyToTab(settingsTab) -- Apply theme manager to settingsTab
SaveManager:LoadAutoloadConfig()

Library:Load(function()
end)
