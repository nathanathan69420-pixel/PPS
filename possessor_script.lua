local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/"
local lib = loadstring(game:HttpGet(repo .. "Library.lua"))()
local theme = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local save = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local rs = game:GetService("RunService")
local lp = game.Players.LocalPlayer

lib.Scheme.BackgroundColor = Color3.fromRGB(22, 41, 58)
lib.Scheme.MainColor = Color3.fromRGB(38, 68, 95)
lib.Scheme.AccentColor = Color3.fromRGB(89, 131, 160)
lib.Scheme.OutlineColor = Color3.fromRGB(50, 85, 115)
lib.Scheme.FontColor = Color3.fromRGB(210, 218, 225)

local win = lib:CreateWindow({
    Title = "AXIS HUB",
    Footer = "v1.3.2",
    NotifySide = "Right",
    ShowCustomCursor = true,
    ToggleKeybind = Enum.KeyCode.RightControl
})

local home = win:AddTab("Home", "house")
local main = win:AddTab("Main", "ghost")
local config = win:AddTab("Settings", "settings")

local status = home:AddLeftGroupbox("Status")
local stats = home:AddRightGroupbox("FPS & Ping")
local vis = main:AddLeftGroupbox("Visuals", "eye")
local cfgBox = config:AddLeftGroupbox("Config")

local espFolder = Instance.new("Folder", game:GetService("CoreGui"))
espFolder.Name = "AXIS_ESP"
local items = {}
local on = false

local function highlight(p)
    if p == lp or items[p] then return end
    
    local h = Instance.new("Highlight")
    h.Name = p.Name
    h.FillColor = lib.Options.ESPColor.Value
    h.OutlineColor = Color3.fromRGB(255, 255, 255)
    h.FillTransparency = 0.5
    h.OutlineTransparency = 0
    h.Parent = espFolder
    h.Enabled = false
    
    local function update()
        local c = p.Character
        h.Adornee = c
        h.FillColor = lib.Options.ESPColor.Value
        
        local role = "Innocent"
        local gui = p:FindFirstChild("PlayerGui")
        local m = gui and gui:FindFirstChild("MainUI")
        if m then
            local f = m:FindFirstChild("MainFrame")
            local r = f and f:FindFirstChild("RoleFrame")
            local n = r and r:FindFirstChild("RoleName")
            if n then role = n.Text end
        end
        
        h.Enabled = on and role:find("Possessor")
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
            for _, data in pairs(items) do
                data[1].Enabled = false
            end
        else
            for _, p in ipairs(game.Players:GetPlayers()) do highlight(p) end
        end
    end
}):AddColorPicker("ESPColor", {
    Default = Color3.fromRGB(175, 25, 255),
    Title = "ESP Color",
    Callback = function() end
})

game.Players.PlayerAdded:Connect(function(p)
    if on then highlight(p) end
end)

game.Players.PlayerRemoving:Connect(function(p)
    if items[p] then
        items[p][1]:Destroy()
        items[p][2]:Disconnect()
        items[p] = nil
    end
end)

local name = lp and lp.DisplayName or "Player"
local time = os.date("%H:%M:%S")

status:AddLabel(string.format("Welcome, %s\nCurrent time: %s\nGame: Possessor", name, time), true)
status:AddButton({ Text = "Unload", Func = function() lib:Unload() end })

local fpsLbl = stats:AddLabel("FPS: ...", true)
local pingLbl = stats:AddLabel("Ping: ...", true)

cfgBox:AddToggle("KeyMenu", { 
    Default = lib.KeybindFrame.Visible, 
    Text = "Keybind Menu", 
    Callback = function(v) lib.KeybindFrame.Visible = v end 
})
cfgBox:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { 
    Default = "RightControl", 
    NoUI = true, 
    Text = "Menu bind",
    Callback = function(key) lib.ToggleKeybind = key end
})

cfgBox:AddButton({ Text = "Unload", Func = function() lib:Unload() end })

local elap, frames = 0, 0
local conn_fps = rs.RenderStepped:Connect(function(dt)
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
theme:SetFolder("PlowsScriptHub")
save:SetFolder("PlowsScriptHub/Possessor")
save:BuildConfigSection(config)
theme:ApplyToTab(config)
save:LoadAutoloadConfig()

lib:OnUnload(function()
    if conn_fps then conn_fps:Disconnect() end
    for _, data in pairs(items) do
        data[1]:Destroy()
        data[2]:Disconnect()
    end
    if espFolder then espFolder:Destroy() end
end)
