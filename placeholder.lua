-- // INIT // ------------------------------------------------------------------

local repoUrl = "https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/"
local Library = loadstring(game:HttpGet(repoUrl .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repoUrl .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repoUrl .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

local window = Library:CreateWindow({
    Title = "Plow's\nPrivate Script",
    Footer = "v1.2.2",
    NotifySide = "Right",
    ShowCustomCursor = true,
})

-- // HOME TAB // --------------------------------------------------------------

local homeTab = window:AddTab("Home", "house")
local homeStatusGroup = homeTab:AddLeftGroupbox("Status")

local localPlayer = game.Players.LocalPlayer
local displayName = localPlayer and localPlayer.DisplayName or "Player"
local currentTime = os.date("%H:%M:%S")
local welcomeText = string.format(
    "Welcome, %s\nCurrent time: %s\nYou are currently in a game that Plow's script doesn't support.",
    displayName,
    currentTime
)

homeStatusGroup:AddLabel(welcomeText, true)

homeStatusGroup:AddButton({
    Text = "Unload",
    Func = function()
        Library:Unload()
    end
})

local statsGroup = homeTab:AddRightGroupbox("FPS & Ping display")

local fpsLabel = statsGroup:AddLabel("FPS: calculating...", true)
local pingLabel = statsGroup:AddLabel("Ping: calculating...", true)

local runService = game:GetService("RunService")
local statsService = game:GetService("Stats")

local elapsedTime = 0
local frameCounter = 0
local fpsConnection

fpsConnection = runService.RenderStepped:Connect(function(deltaTime)
    frameCounter = frameCounter + 1
    elapsedTime = elapsedTime + deltaTime

    if elapsedTime >= 1 then
        local fps = math.floor(frameCounter / elapsedTime + 0.5)
        fpsLabel:SetText("FPS: " .. tostring(fps))

        local networkStats = statsService.Network.ServerStatsItem["Data Ping"]
        local ping = networkStats and math.floor(networkStats:GetValue()) or 0
        pingLabel:SetText("Ping: " .. tostring(ping) .. " ms")

        frameCounter = 0
        elapsedTime = 0
    end
end)

-- // SETTINGS TAB // ----------------------------------------------------------

local settingsTab = window:AddTab("Settings", "settings")
local configGroup = settingsTab:AddLeftGroupbox("Configuration")

configGroup:AddToggle("KeybindMenu", {
    Default = Library.KeybindFrame.Visible,
    Text = "Keybind Menu",
    Callback = function(isVisible)
        Library.KeybindFrame.Visible = isVisible
    end
})

configGroup:AddToggle("CustomCursor", {
    Text = "Custom Cursor",
    Default = true,
    Callback = function(isEnabled)
        Library.ShowCustomCursor = isEnabled
    end
})

configGroup:AddDropdown("NotifySide", {
    Values = { "Left", "Right" },
    Default = "Right",
    Text = "Notification Side",
    Callback = function(side)
        Library:SetNotifySide(side)
    end
})

configGroup:AddDropdown("DPIScale", {
    Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" },
    Default = "100%",
    Text = "DPI Scale",
    Callback = function(scaleText)
        scaleText = scaleText:gsub("%%", "")
        local scaleNumber = tonumber(scaleText)
        if scaleNumber then
            Library:SetDPIScale(scaleNumber / 100)
        end
    end
})

configGroup:AddDivider()
configGroup:AddLabel("Keybind"):AddKeyPicker("MenuKeybind", {
    Default = "RightShift",
    NoUI = true,
    Text = "Menu keybind"
})

configGroup:AddButton({
    Text = "Unload",
    Func = function()
        Library:Unload()
    end
})

Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })

ThemeManager:SetFolder("PlowsScriptHub")
SaveManager:SetFolder("PlowsScriptHub/General")
SaveManager:SetSubFolder("Universal")

SaveManager:BuildConfigSection(settingsTab)
ThemeManager:ApplyToTab(settingsTab)

SaveManager:LoadAutoloadConfig()

-- // CLEANUP // ---------------------------------------------------------------

Library:OnUnload(function()
    if fpsConnection then
        fpsConnection:Disconnect()
        fpsConnection = nil
    end
end)
