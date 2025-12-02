local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

local mainWindow = Library:CreateWindow({
    Title = "Plow's\nPrivate Script",
    Footer = "v1.2.2",
    NotifySide = "Right",
    ShowCustomCursor = true,
})

local homeTab = mainWindow:AddTab("Home", "house")
local voiceChatTab = mainWindow:AddTab("VoiceChat", "mic")
local settingsTab = mainWindow:AddTab("Settings", "settings")

local homeGroupbox = homeTab:AddLeftGroupbox("Greetings")
local voiceGroup = voiceChatTab:AddLeftGroupbox("Voice System")
local configGroupbox = settingsTab:AddLeftGroupbox("Configuration")

local bypassActive = false
local voiceHooks = {}
local networkHooks = {}
local bypassLoop = nil

local function activateFullBypass()
    pcall(function()
        local VoiceService = game:GetService("VoiceService")
        local Players = game:GetService("Players")
        local TextService = game:GetService("TextService")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        
        voiceHooks.originalVoiceCheck = VoiceService.IsVoiceEnabledForUserIdAsync
        
        VoiceService.IsVoiceEnabledForUserIdAsync = function(self, userId)
            if userId == Players.LocalPlayer.UserId then
                return true
            end
            if voiceHooks.originalVoiceCheck then
                return voiceHooks.originalVoiceCheck(self, userId)
            end
            return true
        end
        
        TextService.FilterStringAsync = function(self, text, userId, context)
            local result = {
                GetNonChatStringForBroadcastAsync = function() return text end,
                GetChatStringForUserAsync = function() return text end
            }
            return result
        end
        
        for _, remote in pairs(ReplicatedStorage:GetChildren()) do
            if remote:IsA("RemoteEvent") and remote.Name:find("Voice") then
                local originalFire = remote.FireServer
                remote.FireServer = function(self, ...)
                    local args = {...}
                    if remote.Name:find("Voice") then
                        args[1] = "BYPASS_" .. tostring(math.random(10000, 99999))
                    end
                    return originalFire(self, unpack(args))
                end
                networkHooks[remote] = originalFire
            end
        end
        
        local mt = getrawmetatable(game)
        if mt then
            voiceHooks.originalMeta = mt.__namecall
            setreadonly(mt, false)
            
            mt.__namecall = newcclosure(function(self, ...)
                local method = getnamecallmethod()
                local selfName = tostring(self)
                
                if selfName:find("Voice") and method:find("IsEnabled") then
                    return true
                end
                
                if selfName:find("TextService") and method == "FilterStringAsync" then
                    local text = select(1, ...)
                    local result = {
                        GetNonChatStringForBroadcastAsync = function() return text end,
                        GetChatStringForUserAsync = function() return text end
                    }
                    return result
                end
                
                if voiceHooks.originalMeta then
                    return voiceHooks.originalMeta(self, ...)
                end
            end)
            
            setreadonly(mt, true)
        end
        
        local success, settings = pcall(function()
            return settings()
        end)
        
        if success and settings.VoiceChat then
            settings.VoiceChat.Banned = false
            settings.VoiceChat.Moderated = false
            settings.VoiceChat.Enabled = true
        end
        
        local DataStoreService = game:GetService("DataStoreService")
        pcall(function()
            local banStore = DataStoreService:GetDataStore("VoiceChatBans")
            banStore:RemoveAsync(tostring(Players.LocalPlayer.UserId))
        end)
        
        bypassLoop = task.spawn(function()
            while bypassActive do
                pcall(function()
                    local CoreGui = game:GetService("CoreGui")
                    local existingUI = CoreGui:FindFirstChild("VoiceBypassUI")
                    
                    if not existingUI then
                        local screenUI = Instance.new("ScreenGui")
                        screenUI.Name = "VoiceBypassUI"
                        screenUI.Parent = CoreGui
                        
                        local statusFrame = Instance.new("Frame")
                        statusFrame.Size = UDim2.new(0, 120, 0, 40)
                        statusFrame.Position = UDim2.new(1, -130, 1, -50)
                        statusFrame.BackgroundTransparency = 0.7
                        statusFrame.Parent = screenUI
                        
                        local statusText = Instance.new("TextLabel")
                        statusText.Size = UDim2.new(1, 0, 1, 0)
                        statusText.Text = "VOICE ACTIVE"
                        statusText.TextColor3 = Color3.new(0, 1, 0)
                        statusText.BackgroundTransparency = 1
                        statusText.Parent = statusFrame
                    end
                end)
                task.wait(5)
            end
        end)
    end)
end

local function deactivateBypass()
    pcall(function()
        local VoiceService = game:GetService("VoiceService")
        local TextService = game:GetService("TextService")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        
        if voiceHooks.originalVoiceCheck then
            VoiceService.IsVoiceEnabledForUserIdAsync = voiceHooks.originalVoiceCheck
        end
        
        for remote, originalFire in pairs(networkHooks) do
            if remote and originalFire then
                remote.FireServer = originalFire
            end
        end
        
        local mt = getrawmetatable(game)
        if mt and voiceHooks.originalMeta then
            setreadonly(mt, false)
            mt.__namecall = voiceHooks.originalMeta
            setreadonly(mt, true)
        end
        
        local CoreGui = game:GetService("CoreGui")
        local bypassUI = CoreGui:FindFirstChild("VoiceBypassUI")
        if bypassUI then
            bypassUI:Destroy()
        end
        
        voiceHooks = {}
        networkHooks = {}
    end)
    
    if bypassLoop then
        task.cancel(bypassLoop)
    end
end

voiceGroup:AddToggle("VoiceBypass", {
    Text = "Voice Chat Bypass",
    Default = false,
    Callback = function(Value)
        bypassActive = Value
        if Value then
            activateFullBypass()
        else
            deactivateBypass()
        end
    end
})

voiceGroup:AddLabel("Advanced bypass system", true)
voiceGroup:AddLabel("Multiple method integration", true)

local LocalPlayer = game.Players.LocalPlayer
local displayName = LocalPlayer and LocalPlayer.DisplayName or "Player"
local currentTime = os.date("%A, %B %d, %Y %H:%M:%S", os.time())
local supportedJobIds = {}
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

local welcomeLabelText = string.format("Hello, %s\nToday is %s (Local Time)\nYou are currently in a game that this script %s", displayName, currentTime, supportMessage)

homeGroupbox:AddLabel(welcomeLabelText, true)

homeGroupbox:AddButton({
    Text = "Unload Script",
    Func = function()
        deactivateBypass()
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
configGroupbox:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })

configGroupbox:AddButton("Unload", {
    Text = "Unload UI",
    Func = function()
        deactivateBypass()
        Library:Unload()
    end,
})

Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
ThemeManager:SetFolder("PlowsScriptHub")
SaveManager:SetFolder("PlowsScriptHub/specific-game")
SaveManager:SetSubFolder("specific-place")
SaveManager:BuildConfigSection(settingsTab)
ThemeManager:ApplyToTab(settingsTab)
SaveManager:LoadAutoloadConfig()
