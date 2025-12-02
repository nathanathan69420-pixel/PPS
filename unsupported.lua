local obsidianRepository = "https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/"

local libraryLoadSuccess, loadedLibrary = pcall(function()
    return loadstring(game:HttpGet(obsidianRepository .. "Library.lua"))()
end)

if not libraryLoadSuccess or typeof(loadedLibrary) ~= "table" then
    return
end
local UI = loadedLibrary

local themeLoadSuccess, themeSystem = pcall(function()
    return loadstring(game:HttpGet(obsidianRepository .. "addons/ThemeManager.lua"))()
end)
local ThemeCustomizer = (themeLoadSuccess and typeof(themeSystem) == "table") and themeSystem or { SetLibrary = function() end, SetFolder = function() end, ApplyToTab = function() end }

local saveLoadSuccess, saveSystem = pcall(function()
    return loadstring(game:HttpGet(obsidianRepository .. "addons/SaveManager.lua"))()
end)
local SaveHandler = (saveLoadSuccess and typeof(saveSystem) == "table") and saveSystem or { SetLibrary = function() end, SetFolder = function() end, SetSubFolder = function() end, SetIgnoreIndexes = function() end, IgnoreThemeSettings = function() end, BuildConfigSection = function() end, LoadAutoloadConfig = function() end }

local Settings = UI.Options
local Switches = UI.Toggles

local mainInterface = UI:CreateWindow({
    Title = "Universal Script Interface",
    Footer = "v1.2.2",
    NotificationPosition = "Right",
    UseCustomCursor = true,
})

local homePage = mainInterface:AddTab("Home", "house")
local featuresPage = mainInterface:AddTab("Features", "box")
local settingsPage = mainInterface:AddTab("Settings", "settings")

local infoPanel = homePage:AddLeftGroupbox("User Information")
local featuresPanel = featuresPage:AddLeftGroupbox("Available Functions")
local configurationPanel = settingsPage:AddLeftGroupbox("Interface Settings")

local currentPlayer = game.Players.LocalPlayer
local playerName = currentPlayer and currentPlayer.DisplayName or "Guest"
local currentDateTime = os.date("%A, %B %d, %Y %I:%M %p", os.time())
local welcomeMessage = string.format("Welcome back, %s\nLocal time: %s\nStatus: Ready", playerName, currentDateTime)

infoPanel:AddLabel(welcomeMessage, true)

infoPanel:AddButton({
    Text = "Close Application",
    Func = function()
        UI:Unload()
    end
})

featuresPanel:AddLabel("This game is not currently supported", true)
featuresPanel:AddLabel("Check back later for updates", true)

configurationPanel:AddToggle("ShowHotkeys", {
    Default = UI.KeybindFrame.Visible,
    Text = "Display Hotkey Menu",
    Callback = function(state)
        UI.KeybindFrame.Visible = state
    end
})

configurationPanel:AddToggle("CustomPointer", {
    Text = "Use Custom Mouse Pointer",
    Default = true,
    Callback = function(state)
        UI.UseCustomCursor = state
    end
})

configurationPanel:AddDropdown("AlertPosition", {
    Options = { "Left Side", "Right Side" },
    Default = "Right Side",
    Text = "Notification Placement",
    Callback = function(selection)
        UI:SetNotifySide(selection == "Left Side" and "Left" or "Right")
    end
})

configurationPanel:AddDropdown("InterfaceScale", {
    Options = { "Small (50%)", "Medium (75%)", "Normal (100%)", "Large (125%)", "XL (150%)", "XXL (175%)", "XXXL (200%)" },
    Default = "Normal (100%)",
    Text = "Interface Size",
    Callback = function(selection)
        local scaleText = selection:match("%d+")
        local scaleValue = tonumber(scaleText) or 100
        UI:SetDPIScale(scaleValue / 100)
    end
})

configurationPanel:AddDivider()
configurationPanel:AddLabel("Interface Shortcut"):AddKeyPicker("MenuShortcut", { Default = "RightShift", NoUI = true, Text = "Menu shortcut key" })

configurationPanel:AddButton({
    Text = "Close Interface",
    Func = function()
        UI:Unload()
    end
})

UI.ToggleKeybind = Settings.MenuShortcut

ThemeCustomizer:SetLibrary(UI)
SaveHandler:SetLibrary(UI)
SaveHandler:IgnoreThemeSettings()
SaveHandler:SetIgnoreIndexes({ "MenuShortcut" })
ThemeCustomizer:SetFolder("UserConfigurations")
SaveHandler:SetFolder("UserConfigurations/GameSettings")
SaveHandler:SetSubFolder("General")
SaveHandler:BuildConfigSection(settingsPage)
ThemeCustomizer:ApplyToTab(settingsPage)
SaveHandler:LoadAutoloadConfig()

UI:OnUnload(function()
end)
