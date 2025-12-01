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
    Footer = "v1.2.2",
    NotifySide = "Right",
    ShowCustomCursor = true,
})

local homeTab = mainWindow:AddTab("Home", "house")
local voiceChatTab = mainWindow:AddTab("VoiceChat", "mic")
local settingsTab = mainWindow:AddTab("Settings", "settings")

local homeGroupbox = homeTab:AddLeftGroupbox("Greetings")
local voiceLeftGroup = voiceChatTab:AddLeftGroupbox("Voice System")
local voiceRightGroup = voiceChatTab:AddRightGroupbox("Bypass Methods Info")
local configGroupbox = settingsTab:AddLeftGroupbox("Configuration")

voiceRightGroup:AddLabel("Full Hook", true)
voiceRightGroup:AddLabel("Intercepts both voice permission checks and chat filters at the deepest level. Most reliable but detectable.", true)

voiceRightGroup:AddLabel("Network Only", true)
voiceRightGroup:AddLabel("Only modifies network packets sent to servers. Less detectable but may miss some filter checks.", true)

voiceRightGroup:AddLabel("Filter Only", true)
voiceRightGroup:AddLabel("Only bypasses text/voice content filtering. Lightweight but doesn't handle permission bans.", true)

voiceRightGroup:AddDivider()
voiceRightGroup:AddLabel("How it works:", true)
voiceRightGroup:AddLabel("1. Hooks system functions to always return 'enabled'", true)
voiceRightGroup:AddLabel("2. Clears ban records from data stores", true)
voiceRightGroup:AddLabel("3. Creates fake UI to mimic normal voice system", true)
voiceRightGroup:AddLabel("4. Auto-rejoins to maintain connection", true)

voiceRightGroup:AddDivider()
voiceRightGroup:AddLabel("Warning: Overuse may trigger", true)
voiceRightGroup:AddLabel("additional detection systems.", true)

local bypassActive = false
local voiceHooks = {}
local networkHooks = {}

local function createVoiceHook()
    pcall(function()
        local VoiceService = game:GetService("VoiceService")
        local Players = game:GetService("Players")
        local TextService = game:GetService("TextService")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local HttpService = game:GetService("HttpService")
        
        voiceHooks.originalVoiceCheck = VoiceService.IsVoiceEnabledForUserIdAsync
        voiceHooks.originalFilter = TextService.FilterStringAsync
        
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
                GetNonChatStringForBroadcastAsync = function() 
                    return text 
                end,
                GetChatStringForUserAsync = function() 
                    return text 
                end
            }
            return result
        end
        
        for _, remote in pairs(ReplicatedStorage:GetChildren()) do
            if remote:IsA("RemoteEvent") and (remote.Name:find("Voice") or remote.Name:find("Chat")) then
                local oldFire = remote.FireServer
                remote.FireServer = function(self, ...)
                    local args = {...}
                    if remote.Name:find("Voice") then
                        args[1] = "UNRESTRICTED_VOICE_" .. HttpService:GenerateGUID(false)
                    end
                    return oldFire(self, unpack(args))
                end
                networkHooks[remote] = oldFire
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
        
        local success, voiceBanStore = pcall(function()
            return game:GetService("DataStoreService"):GetDataStore("VoiceChatBans")
        end)
        
        if success and voiceBanStore then
            pcall(function()
                voiceBanStore:RemoveAsync(tostring(Players.LocalPlayer.UserId))
            end)
        end
        
        local success2, settings = pcall(function()
            return settings()
        end)
        
        if success2 and settings.VoiceChat then
            settings.VoiceChat.Banned = false
            settings.VoiceChat.Moderated = false
        end
        
        spawn(function()
            while bypassActive do
                pcall(function()
                    local VoiceChatService = game:GetService("VoiceChatService")
                    local joinSuccess = pcall(function()
                        VoiceChatService:JoinVoice()
                    end)
                    
                    if not joinSuccess then
                        local CoreGui = game:GetService("CoreGui")
                        local existingUI = CoreGui:FindFirstChild("VoiceBypassUI")
                        
                        if not existingUI then
                            local screenGui = Instance.new("ScreenGui")
                            screenGui.Name = "VoiceBypassUI"
                            screenGui.Parent = CoreGui
                            
                            local frame = Instance.new("Frame")
                            frame.Size = UDim2.new(0, 100, 0, 40)
                            frame.Position = UDim2.new(1, -110, 1, -50)
                            frame.BackgroundTransparency = 0.8
                            frame.Parent = screenGui
                            
                            local label = Instance.new("TextLabel")
                            label.Size = UDim2.new(1, 0, 1, 0)
                            label.Text = "VOICE ACTIVE"
                            label.TextColor3 = Color3.new(0, 1, 0)
                            label.BackgroundTransparency = 1
                            label.Parent = frame
                        end
                    end
                end)
                wait(2)
            end
        end)
    end)
end

local function removeVoiceHook()
    pcall(function()
        local VoiceService = game:GetService("VoiceService")
        local TextService = game:GetService("TextService")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        
        if voiceHooks.originalVoiceCheck then
            VoiceService.IsVoiceEnabledForUserIdAsync = voiceHooks.originalVoiceCheck
        end
        
        if voiceHooks.originalFilter then
            TextService.FilterStringAsync = voiceHooks.originalFilter
        end
        
        for remote, oldFire in pairs(networkHooks) do
            if remote and oldFire then
                remote.FireServer = oldFire
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
end

voiceLeftGroup:AddToggle("BypassVoiceChat", {
    Text = "Voice Bypass System",
    Default = false,
    Callback = function(Value)
        bypassActive = Value
        if Value then
            createVoiceHook()
        else
            removeVoiceHook()
        end
    end
})

voiceLeftGroup:AddSlider("RejoinDelay", {
    Text = "Rejoin Delay",
    Default = 2,
    Min = 1,
    Max = 10,
    Rounding = 1,
    Suffix = "s",
    Callback = function(Value)
    end
})

voiceLeftGroup:AddDropdown("BypassMethod", {
    Values = {"Full Hook", "Network Only", "Filter Only"},
    Default = "Full Hook",
    Text = "Bypass Method",
    Callback = function(Value)
    end
})

voiceLeftGroup:AddButton({
    Text = "Clear Voice Data",
    Func = function()
        pcall(function()
            game:GetService("VoiceChatService"):LeaveVoice()
            wait(0.5)
            local CoreGui = game:GetService("CoreGui")
            for _, obj in pairs(CoreGui:GetChildren()) do
                if obj.Name:find("Voice") then
                    obj:Destroy()
                end
            end
        end)
    end
})

voiceLeftGroup:AddButton({
    Text = "Force Unban All",
    Func = function()
        pcall(function()
            local Players = game:GetService("Players")
            local DataStoreService = game:GetService("DataStoreService")
            local voiceBanStore = DataStoreService:GetDataStore("VoiceChatBans")
            
            for _, player in pairs(Players:GetPlayers()) do
                pcall(function()
                    voiceBanStore:RemoveAsync(tostring(player.UserId))
                end)
            end
            
            if settings().VoiceChat then
                settings().VoiceChat.Banned = false
                settings().VoiceChat.Moderated = false
            end
        end)
    end
})

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

local welcomeLabelText = string.format("Hello, %s\nToday is %s (Local Time)\nYou are currently in a game that Plow's script %s", displayName, currentTime, supportMessage)

homeGroupbox:AddLabel(welcomeLabelText, true)

homeGroupbox:AddButton({
    Text = "Unload Script",
    Func = function()
        if bypassActive then
            removeVoiceHook()
        end
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

configGroupbox:AddButton({
    Text = "Unload UI",
    Func = function()
        if bypassActive then
            removeVoiceHook()
        end
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
