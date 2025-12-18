local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/"
local lib = loadstring(game:HttpGet(repo .. "Library.lua"))()
local theme = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local save = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local rs = game:GetService("RunService")
local lp = game.Players.LocalPlayer

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

local folder = Instance.new("Folder", game:GetService("CoreGui"))
folder.Name = "AXIS_ESP"
local items = {}
local on = false

local function esp(p)
    if p == lp or items[p] then return end
    local h = Instance.new("Highlight", folder)
    h.Name = p.Name
    h.FillColor = lib.Options.ESPColor.Value
    h.OutlineColor = Color3.fromRGB(255, 255, 255)
    h.FillTransparency = 0.5
    h.Enabled = false
    
    local function update()
        h.Adornee = p.Character
        h.FillColor = lib.Options.ESPColor.Value
        local r = "Innocent"
        local g = p:FindFirstChild("PlayerGui")
        local m = g and g:FindFirstChild("MainUI")
        if m then
            local f = m:FindFirstChild("MainFrame")
            local rf = f and f:FindFirstChild("RoleFrame")
            local n = rf and rf:FindFirstChild("RoleName")
            if n then r = n.Text end
        end
        h.Enabled = on and r:find("Possessor")
    end

    items[p] = {h, p.CharacterAdded:Connect(update)}
    task.spawn(function()
        while items[p] do
            update()
            task.wait(1)
        end
    end)
end

vis:AddToggle("ESP", {
    Text = "Possessor ESP",
    Default = false,
    Callback = function(v)
        on = v
        if not v then
            for _, d in pairs(items) do d[1].Enabled = false end
        else
            for _, p in ipairs(game.Players:GetPlayers()) do esp(p) end
        end
    end
}):AddColorPicker("ESPColor", {
    Default = Color3.fromRGB(175, 25, 255),
    Title = "ESP Color"
})

game.Players.PlayerAdded:Connect(function(p) if on then esp(p) end end)
game.Players.PlayerRemoving:Connect(function(p)
    if items[p] then
        items[p][1]:Destroy()
        items[p][2]:Disconnect()
        items[p] = nil
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
cfgBox:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { Default = "RightControl", NoUI = true, Text = "Menu bind" })

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
    for _, d in pairs(items) do
        d[1]:Destroy()
        d[2]:Disconnect()
    end
    if folder then folder:Destroy() end
end)
