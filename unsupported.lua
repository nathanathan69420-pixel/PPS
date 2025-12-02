local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Toggles = Library.Toggles

local Window = Library:CreateWindow({
    Title = "Plow's\nPrivate Script",
    Footer = "v1.2.2",
    ShowCustomCursor = true,
})

local VoiceTab = Window:AddTab("VoiceChat", "mic")
local SettingsTab = Window:AddTab("Settings", "settings")

local VoiceGroup = VoiceTab:AddLeftGroupbox("Voice Bypass")
local ConfigGroup = SettingsTab:AddLeftGroupbox("Configuration")

local Active = false
local Hooks = {}

local function StartBypass()
    pcall(function()
        local VS = game:GetService("VoiceService")
        local Players = game:GetService("Players")
        
        Hooks.Check = VS.IsVoiceEnabledForUserIdAsync
        VS.IsVoiceEnabledForUserIdAsync = function(_, userId)
            if userId == Players.LocalPlayer.UserId then return true end
            if Hooks.Check then return Hooks.Check(_, userId) end
            return true
        end
        
        local TS = game:GetService("TextService")
        Hooks.Filter = TS.FilterStringAsync
        TS.FilterStringAsync = function(_, text)
            return {
                GetNonChatStringForBroadcastAsync = function() return text end,
                GetChatStringForUserAsync = function() return text end
            }
        end
        
        local mt = getrawmetatable(game)
        if mt then
            Hooks.Meta = mt.__namecall
            setreadonly(mt, false)
            mt.__namecall = newcclosure(function(self, ...)
                local method = getnamecallmethod()
                local name = tostring(self)
                if name:find("Voice") and method:find("IsEnabled") then return true end
                if name:find("TextService") and method == "FilterStringAsync" then
                    local text = select(1, ...)
                    return {
                        GetNonChatStringForBroadcastAsync = function() return text end,
                        GetChatStringForUserAsync = function() return text end
                    }
                end
                return Hooks.Meta(self, ...)
            end)
            setreadonly(mt, true)
        end
        
        pcall(function()
            local store = game:GetService("DataStoreService"):GetDataStore("VoiceChatBans")
            store:RemoveAsync(tostring(Players.LocalPlayer.UserId))
        end)
        
        pcall(function()
            settings().VoiceChat.Banned = false
            settings().VoiceChat.Moderated = false
        end)
        
        while Active do
            pcall(function() game:GetService("VoiceChatService"):JoinVoice() end)
            task.wait(3)
        end
    end)
end

local function StopBypass()
    pcall(function()
        local VS = game:GetService("VoiceService")
        if Hooks.Check then VS.IsVoiceEnabledForUserIdAsync = Hooks.Check end
        
        local TS = game:GetService("TextService")
        if Hooks.Filter then TS.FilterStringAsync = Hooks.Filter end
        
        if Hooks.Meta then
            local mt = getrawmetatable(game)
            if mt then
                setreadonly(mt, false)
                mt.__namecall = Hooks.Meta
                setreadonly(mt, true)
            end
        end
        
        Hooks = {}
    end)
end

VoiceGroup:AddToggle("Bypass", {
    Text = "Voice Bypass",
    Default = false,
    Callback = function(State)
        Active = State
        if State then
            StartBypass()
        else
            StopBypass()
        end
    end
})

VoiceGroup:AddButton({
    Text = "Force Clear",
    Func = function()
        pcall(function()
            game:GetService("VoiceChatService"):LeaveVoice()
            local store = game:GetService("DataStoreService"):GetDataStore("VoiceChatBans")
            store:RemoveAsync(tostring(game.Players.LocalPlayer.UserId))
        end)
    end
})

local Player = game.Players.LocalPlayer
local Name = Player and Player.DisplayName or "Player"
local Time = os.date("%H:%M %p")
local Welcome = string.format("Welcome, %s\nTime: %s", Name, Time)

local HomeTab = Window:AddTab("Home", "house")
local HomeGroup = HomeTab:AddLeftGroupbox("Info")
HomeGroup:AddLabel(Welcome, true)

HomeGroup:AddButton({
    Text = "Unload",
    Func = function()
        if Active then StopBypass() end
        Library:Unload()
    end
})

ConfigGroup:AddToggle("ShowKeybinds", {
    Default = Library.KeybindFrame.Visible,
    Text = "Show Keybinds",
    Callback = function(State)
        Library.KeybindFrame.Visible = State
    end
})

ConfigGroup:AddLabel("Keybind"):AddKeyPicker("Keybind", { Default = "RightShift", NoUI = true })

Library.ToggleKeybind = Library.Options.Keybind

SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "Keybind" })
SaveManager:SetFolder("PlowConfig")
SaveManager:BuildConfigSection(SettingsTab)
SaveManager:LoadAutoloadConfig()

Library:OnUnload(function()
    if Active then StopBypass() end
end)
