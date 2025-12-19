local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/"
local lib = loadstring(game:HttpGet(repo .. "Library.lua"))()
local theme = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local save = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local rs = game:GetService("RunService")
local plrs = game:GetService("Players")
local lp = plrs.LocalPlayer

theme.BuiltInThemes["Default"][2] = {
    BackgroundColor = "16293a",
    MainColor = "26445f",
    AccentColor = "5983a0",
    OutlineColor = "325573",
    FontColor = "d2dae1"
}

local win = lib:CreateWindow({
    Title = "AXIS HUB",
    Footer = "v1.3.2",
    NotifySide = "Right",
    ShowCustomCursor = true,
})

local home = win:AddTab("Home", "house")
local main = win:AddTab("Main", "ghost")
local config = win:AddTab("Settings", "settings")

local status = home:AddLeftGroupbox("Status")
local stats = home:AddRightGroupbox("FPS & Ping")
local vis = main:AddLeftGroupbox("Visuals", "eye")
local cfgBox = config:AddLeftGroupbox("Config")

vis:AddToggle("PossessorESP", {
    Text = "Possessor ESP",
    Default = false,
    Callback = function() end
}):AddColorPicker("ESPColor", {
    Default = Color3.fromRGB(175, 25, 255),
    Title = "ESP Color"
})

local Storage = Instance.new("Folder")
Storage.Name = "AXIS_Storage"
Storage.Parent = game:GetService("CoreGui")

local conns = {}

local function Highlight(p)
    if p == lp then return end
    
    local h = Instance.new("Highlight")
    h.Name = p.Name
    h.FillColor = lib.Options.ESPColor.Value
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    h.FillTransparency = 0.55
    h.OutlineColor = Color3.fromRGB(255, 255, 255)
    h.OutlineTransparency = 0
    h.Parent = Storage
    
    local function update()
        local char = p.Character
        local val = p:GetAttribute("IsPossessor")
        local isAlive = p:GetAttribute("Alive") == true
        local on = lib.Toggles.PossessorESP and lib.Toggles.PossessorESP.Value
        
        local isPoss = true
        if val == false or tostring(val):lower() == "false" then
            isPoss = false
        end
        
        if char then
            h.Adornee = char
        end
        
        h.FillColor = lib.Options.ESPColor.Value
        h.Enabled = on and isPoss and isAlive
    end

    conns[p] = {
        p.CharacterAdded:Connect(function(char)
            h.Adornee = char
            update()
        end),
        p:GetAttributeChangedSignal("IsPossessor"):Connect(update),
        p:GetAttributeChangedSignal("Alive"):Connect(update)
    }

    task.spawn(function()
        while conns[p] do
            update()
            task.wait(0.5)
        end
    end)
end

plrs.PlayerAdded:Connect(Highlight)
for _, v in ipairs(plrs:GetPlayers()) do
    Highlight(v)
end

plrs.PlayerRemoving:Connect(function(p)
    if Storage:FindFirstChild(p.Name) then
        Storage[p.Name]:Destroy()
    end
    if conns[p] then
        for _, c in ipairs(conns[p]) do c:Disconnect() end
        conns[p] = nil
    end
end)

status:AddLabel(string.format("Welcome, %s\nGame: Possessor", lp.DisplayName), true)
status:AddButton({ Text = "Unload", Func = function() lib:Unload() end })

local fpsLbl = stats:AddLabel("FPS: ...", true)
local pingLbl = stats:AddLabel("Ping: ...", true)

cfgBox:AddToggle("KeyMenu", { 
    Default = lib.KeybindFrame.Visible, 
    Text = "Keybind Menu", 
    Callback = function(v) lib.KeybindFrame.Visible = v end 
})
cfgBox:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { Default = "RightControl", NoUI = true, Text = "Menu keybind" })

lib.ToggleKeybind = lib.Options.MenuKeybind

local elap, frames = 0, 0
local conn = rs.RenderStepped:Connect(function(dt)
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
save:SetIgnoreIndexes({ "MenuKeybind" })
theme:SetFolder("PlowsScriptHub")
save:SetFolder("PlowsScriptHub/Possessor")
save:BuildConfigSection(config)
theme:ApplyToTab(config)
save:LoadAutoloadConfig()

lib:OnUnload(function()
    if conn then conn:Disconnect() end
    for p, c_list in pairs(conns) do
        for _, c in ipairs(c_list) do c:Disconnect() end
    end
    if Storage then Storage:Destroy() end
end)
