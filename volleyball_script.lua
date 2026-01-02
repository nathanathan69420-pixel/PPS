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
    Title = "Axis Hub - Volleyball.lua",
    Footer = "by RwalDev & Plow | 1.7.3 | Discord: .gg/UuyxhqgEVs",
    NotifySide = "Right",
    ShowCustomCursor = true,
})

local home = win:AddTab("Home", "house")
local hitbox = win:AddTab("Hitbox", "scan")
local config = win:AddTab("Settings", "settings")

local status = home:AddLeftGroupbox("Status")
local stats = home:AddRightGroupbox("FPS & Ping")
local funcs = hitbox:AddLeftGroupbox("Functions")
local keybinds = hitbox:AddRightGroupbox("Keybinds")
local cfgBox = config:AddLeftGroupbox("Config")

status:AddLabel(string.format("Welcome, %s\nGame: Volleyball", lp.DisplayName), true)
status:AddButton({ Text = "Unload", Func = function() lib:Unload() end })

local fpsLbl = stats:AddLabel("FPS: ...", true)
local pingLbl = stats:AddLabel("Ping: ...", true)

local balls = {}
local enabled = false
local size = 10
local trans = 0.5

local function cleanup(b)
    if balls[b] then
        if balls[b].vis then balls[b].vis:Destroy() end
        if balls[b].box then balls[b].box:Destroy() end
        balls[b] = nil
    end
end

local function expand(b)
    if not b or not b:IsA("BasePart") then return end
    if not balls[b] then balls[b] = {} end
    local info = balls[b]
    if not info.box then
        local p = Instance.new("Part")
        p.Name = "ExpandedHitbox"
        p.Shape = Enum.PartType.Ball
        p.CanCollide = false
        p.Massless = true
        p.Transparency = 1
        p.Parent = b
        local w = Instance.new("WeldConstraint")
        w.Part0, w.Part1, w.Parent = b, p, p
        info.box = p
    end
    if not info.vis then
        local v = Instance.new("Part")
        v.Name = "HitboxVisual"
        v.Shape = Enum.PartType.Ball
        v.CanCollide = false
        v.Massless = true
        v.Material = Enum.Material.ForceField
        v.Color = Color3.fromRGB(100, 200, 255)
        v.Parent = b
        local w = Instance.new("WeldConstraint")
        w.Part0, w.Part1, w.Parent = b, v, v
        info.vis = v
    end
    info.box.Size = Vector3.new(size, size, size)
    info.vis.Size = Vector3.new(size, size, size)
    info.vis.Transparency = trans
end

local function scan()
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name:sub(1, 12) == "CLIENT_BALL_" then
            if enabled then expand(obj) else cleanup(obj) end
        end
    end
end

local loop, added, removing
local function start()
    scan()
    loop = rs.Heartbeat:Connect(function()
        for b, info in pairs(balls) do
            if b and b.Parent then
                info.box.Size = Vector3.new(size, size, size)
                info.vis.Size = Vector3.new(size, size, size)
                info.vis.Transparency = trans
            else
                cleanup(b)
            end
        end
    end)
    added = workspace.DescendantAdded:Connect(function(obj)
        if obj:IsA("BasePart") and obj.Name:sub(1, 12) == "CLIENT_BALL_" then
            task.wait(0.1)
            if enabled then expand(obj) end
        end
    end)
    removing = workspace.DescendantRemoving:Connect(function(obj)
        if obj:IsA("BasePart") and obj.Name:sub(1, 12) == "CLIENT_BALL_" then cleanup(obj) end
    end)
end

local function stop()
    if loop then loop:Disconnect() loop = nil end
    if added then added:Disconnect() added = nil end
    if removing then removing:Disconnect() removing = nil end
    for b, _ in pairs(balls) do cleanup(b) end
end

funcs:AddToggle("Hitbox", { Text = "Enable Hitbox Expander", Callback = function(v) 
    enabled = v 
    if v then start() else stop() end 
end })

funcs:AddSlider("Size", { Text = "Hitbox Size", Default = 10, Min = 5, Max = 20, Callback = function(v) size = v end })
funcs:AddSlider("Transparency", { Text = "Hitbox Transparency", Default = 0.5, Min = 0, Max = 1, Callback = function(v) trans = v end })

keybinds:AddLabel("Hitbox Expander"):AddKeyPicker("HitboxKey", { Default = "None", Mode = "Toggle", Text = "Toggle Hitbox", Callback = function(v) lib.Options.Hitbox:SetValue(v) end })

cfgBox:AddToggle("KeyMenu", { Default = lib.KeybindFrame.Visible, Text = "Keybind Menu", Callback = function(v) lib.KeybindFrame.Visible = v end })
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
save:SetFolder("PlowsScriptHub/Volleyball")
save:BuildConfigSection(config)
theme:ApplyToTab(config)
save:LoadAutoloadConfig()

lib:OnUnload(function()
    if conn then conn:Disconnect() end
    stop()
end)
