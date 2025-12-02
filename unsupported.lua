local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

local Window = Library:CreateWindow({
    Title = "Plow's\nPrivate Script",
    Footer = "v1.2.2",
    NotifySide = "Right",
    ShowCustomCursor = true,
})

local HomeTab = Window:AddTab("Home", "house")
local HomeGroup = HomeTab:AddLeftGroupbox("Status")

local Player = game.Players.LocalPlayer
local Name = Player and Player.DisplayName or "Player"
local Time = os.date("%H:%M:%S")
local Welcome = string.format("%s | %s", Name, Time)

HomeGroup:AddLabel(Welcome, true)

HomeGroup:AddButton({
    Text = "Unload",
    Func = function()
        Library:Unload()
    end
})

local VoiceTab = Window:AddTab("VoiceChat", "mic")
local VoiceLeft = VoiceTab:AddLeftGroupbox("Voice System")
local VoiceRight = VoiceTab:AddRightGroupbox("Info")

VoiceRight:AddLabel("Advanced bypass", true)
VoiceRight:AddLabel("Updated methods", true)

local Active = false
local Hooks = {}
local VisualUI = nil
local BypassLoop = nil

local function ExecuteBypass()
    pcall(function()
        local Players = game:GetService("Players")
        local LP = Players.LocalPlayer
        
        local VS = game:GetService("VoiceService")
        Hooks.VoiceOriginal = VS.IsVoiceEnabledForUserIdAsync
        VS.IsVoiceEnabledForUserIdAsync = function(self, userId)
            if userId == LP.UserId then 
                return true 
            end
            return Hooks.VoiceOriginal and Hooks.VoiceOriginal(self, userId) or true
        end
        
        local TS = game:GetService("TextService")
        Hooks.TextOriginal = TS.FilterStringAsync
        TS.FilterStringAsync = function(self, text)
            return {
                GetNonChatStringForBroadcastAsync = function() return text end,
                GetChatStringForUserAsync = function() return text end
            }
        end
        
        local mt = getrawmetatable(game)
        if mt then
            Hooks.MetaOriginal = mt.__namecall
            setreadonly(mt, false)
            
            mt.__namecall = newcclosure(function(self, ...)
                local method = getnamecallmethod()
                local args = {...}
                
                if tostring(self):find("Voice") and method:find("IsEnabled") then
                    return true
                end
                
                if tostring(self):find("TextService") and method == "FilterStringAsync" then
                    local text = args[1]
                    return {
                        GetNonChatStringForBroadcastAsync = function() return text end,
                        GetChatStringForUserAsync = function() return text end
                    }
                end
                
                if method == "FireServer" then
                    if type(args[1]) == "string" and args[1]:lower():find("report") then
                        return nil
                    end
                end
                
                return Hooks.MetaOriginal(self, ...)
            end)
            
            setreadonly(mt, true)
        end
        
        pcall(function()
            local HttpService = game:GetService("HttpService")
            local store = game:GetService("DataStoreService"):GetDataStore("VoiceChatInternal")
            local key = "vc_bans_" .. tostring(LP.UserId)
            store:SetAsync(key, HttpService:JSONEncode({
                banned = false,
                timestamp = os.time(),
                reason = ""
            }))
        end)
        
        pcall(function()
            local s = settings()
            if s.VoiceChat then
                s.VoiceChat.Banned = false
                s.VoiceChat.Moderated = false
                s.VoiceChat.Enabled = true
            end
        end)
        
        VisualUI = Instance.new("ScreenGui")
        VisualUI.Name = "VoiceProtection"
        VisualUI.Parent = game:GetService("CoreGui")
        
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, 100, 0, 35)
        frame.Position = UDim2.new(1, -110, 0, 10)
        frame.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
        frame.BackgroundTransparency = 0.2
        frame.Parent = VisualUI
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 1, 0)
        label.Text = "ACTIVE"
        label.TextColor3 = Color3.new(1, 1, 1)
        label.BackgroundTransparency = 1
        label.Parent = frame
        
        BypassLoop = task.spawn(function()
            local RunService = game:GetService("RunService")
            while Active and RunService.Heartbeat:Wait() do
                pcall(function()
                    local success = game:GetService("VoiceChatService"):JoinVoice()
                    if not success then
                        pcall(function()
                            local VS2 = game:GetService("VoiceService")
                            local newRemote = Instance.new("RemoteFunction")
                            newRemote.Name = "VoiceJoinOverride"
                            newRemote.Parent = game:GetService("ReplicatedStorage")
                        end)
                    end
                end)
            end
        end)
    end)
end

local function RemoveBypass()
    pcall(function()
        local VS = game:GetService("VoiceService")
        if Hooks.VoiceOriginal then
            VS.IsVoiceEnabledForUserIdAsync = Hooks.VoiceOriginal
        end
        
        local TS = game:GetService("TextService")
        if Hooks.TextOriginal then
            TS.FilterStringAsync = Hooks.TextOriginal
        end
        
        if Hooks.MetaOriginal then
            local mt = getrawmetatable(game)
            if mt then
                setreadonly(mt, false)
                mt.__namecall = Hooks.MetaOriginal
                setreadonly(mt, true)
            end
        end
        
        if VisualUI then
            VisualUI:Destroy()
        end
        
        if BypassLoop then
            task.cancel(BypassLoop)
        end
        
        Hooks = {}
    end)
end

local function ClearAllBans()
    pcall(function()
        local Players = game:GetService("Players")
        local LP = Players.LocalPlayer
        
        game:GetService("VoiceChatService"):LeaveVoice()
        
        local DataStoreService = game:GetService("DataStoreService")
        
        local stores = {
            "VoiceChatBans",
            "VoiceChatRestrictions",
            "VoiceChatInternal",
            "VCRestrictions",
            "VCBans"
        }
        
        for _, storeName in pairs(stores) do
            pcall(function()
                local store = DataStoreService:GetDataStore(storeName)
                store:RemoveAsync(tostring(LP.UserId))
                
                local key2 = "vc_" .. tostring(LP.UserId)
                store:RemoveAsync(key2)
                
                local key3 = "banned_" .. tostring(LP.UserId)
                store:RemoveAsync(key3)
            end)
        end
        
        local s = settings()
        if s.VoiceChat then
            s.VoiceChat.Banned = false
            s.VoiceChat.Moderated = false
            s.VoiceChat.Enabled = true
        end
        
        Library:Notify("All bans cleared", 3)
    end)
end

VoiceLeft:AddToggle("VoiceBypass", {
    Text = "Voice Protection",
    Default = false,
    Callback = function(Value)
        Active = Value
        if Value then
            ExecuteBypass()
        else
            RemoveBypass()
        end
    end
})

VoiceLeft:AddButton({
    Text = "Clear All Bans",
    Func = ClearAllBans
})

VoiceLeft:AddButton({
    Text = "Force Voice Join",
    Func = function()
        pcall(function()
            game:GetService("VoiceChatService"):JoinVoice()
        end)
    end
})

local SettingsTab = Window:AddTab("Settings", "settings")
local ConfigGroup = SettingsTab:AddLeftGroupbox("Configuration")

ConfigGroup:AddToggle("KeybindMenu", {
    Default = Library.KeybindFrame.Visible,
    Text = "Keybind Menu",
    Callback = function(Value)
        Library.KeybindFrame.Visible = Value
    end
})

ConfigGroup:AddToggle("CustomCursor", {
    Text = "Custom Cursor",
    Default = true,
    Callback = function(Value)
        Library.ShowCustomCursor = Value
    end
})

ConfigGroup:AddDropdown("NotifySide", {
    Values = { "Left", "Right" },
    Default = "Right",
    Text = "Notification Side",
    Callback = function(Value)
        Library:SetNotifySide(Value)
    end
})

ConfigGroup:AddDropdown("DPIScale", {
    Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" },
    Default = "100%",
    Text = "DPI Scale",
    Callback = function(Value)
        Value = Value:gsub("%%", "")
        local Scale = tonumber(Value)
        Library:SetDPIScale(Scale / 100)
    end
})

ConfigGroup:AddDivider()
ConfigGroup:AddLabel("Keybind"):AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })

ConfigGroup:AddButton({
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
SaveManager:BuildConfigSection(SettingsTab)
ThemeManager:ApplyToTab(SettingsTab)
SaveManager:LoadAutoloadConfig()

Library:OnUnload(function()
    if Active then RemoveBypass() end
end)
