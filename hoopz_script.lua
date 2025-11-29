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
    Icon = "settings",
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
    game.JobId,
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

-- Function to check if the local player is holding any basketball
local function isLocalPlayerHoldingBall()
    if not LocalPlayer or not LocalPlayer.Name then return false end
    for _, child in ipairs(game.Workspace:GetChildren()) do
        if child.Name == "Basketball" and child:IsA("Folder") then
            local lastPlr = child:GetAttribute("LastPLR")
            if lastPlr == LocalPlayer.Name then
                return true
            end
            local lastPlr2 = child:GetAttribute("LastPLR2")
            if lastPlr2 == LocalPlayer.Name then
                return true
            end
        end
    end
    return false
end
-- The 'isLocalPlayerHoldingBall' function is now available for other parts of the script to call
-- when detection is needed, without automatically displaying its status in the UI.

homeGroupbox:AddButton({
    Text = "Unload Script",
    Func = function()
        Library:Unload()
    end,
})

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

configGroupbox:AddButton({
    Text = "Unload UI",
    Func = function()
        Library:Unload()
    end,
})

Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
ThemeManager:SetFolder("PlowsScriptHub")
SaveManager:SetFolder("PlowsScriptHub/Hoopz")
SaveManager:SetSubFolder("universal")
SaveManager:BuildConfigSection(settingsTab)
ThemeManager:ApplyToTab(settingsTab)
SaveManager:LoadAutoloadConfig()

Library:Load(function()
end)
