local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/"
local lib = loadstring(game:HttpGet(repo .. "Library.lua"))()
local theme = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local save = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local win = lib:CreateWindow({
    Title = "Plow's Private Script",
    Footer = "v1.2.2",
    NotifySide = "Right",
    ShowCustomCursor = true,
})

local tab = win:AddTab("Home", "house")
local status = tab:AddLeftGroupbox("Status")

local lp = game.Players.LocalPlayer
local name = lp and lp.DisplayName or "Player"
local time = os.date("%H:%M:%S")

status:AddLabel(string.format("Welcome, %s\nCurrent time: %s\nGame not supported.", name, time), true)

status:AddButton({ Text = "Unload", Func = function() lib:Unload() end })

local stats = tab:AddRightGroupbox("FPS & Ping")
local fpsLbl = stats:AddLabel("FPS: ...", true)
local pingLbl = stats:AddLabel("Ping: ...", true)

local rs = game:GetService("RunService")
local statService = game:GetService("Stats")
local uis = game:GetService("UserInputService")
local plrs = game:GetService("Players")
local light = game:GetService("Lighting")

local elap, frames = 0, 0
local conn_fps

conn_fps = rs.RenderStepped:Connect(function(dt)
    frames = frames + 1
    elap = elap + dt
    if elap >= 1 then
        fpsLbl:SetText("FPS: " .. math.floor(frames / elap + 0.5))
        local net = statService.Network.ServerStatsItem["Data Ping"]
        pingLbl:SetText("Ping: " .. (net and math.floor(net:GetValue()) or 0) .. " ms")
        frames, elap = 0, 0
    end
end)

local hitbox = win:AddTab("Hitbox Expander", "scan")
local funcs = hitbox:AddLeftGroupbox("Functions")
local keybinds = hitbox:AddRightGroupbox("Keybinds")

local balls = {}
local enabled = false
local size = 10
local trans = 0.5

local function cleanup(b)
    if balls[b] then
        if balls[b].vis then
            balls[b].vis:Destroy()
        end
        if balls[b].box then
            balls[b].box:Destroy()
        end
        balls[b] = nil
    end
end

local function expand(b)
    if not b or not b:IsA("BasePart") then return end
    
    if not balls[b] then
        balls[b] = {}
    end
    
    local info = balls[b]
    
    if not info.box then
        local p = Instance.new("Part")
        p.Name = "ExpandedHitbox"
        p.Shape = Enum.PartType.Ball
        p.CanCollide = false
        p.Massless = true
        p.Transparency = 1
        p.Anchored = false
        p.Parent = b
        
        local w = Instance.new("WeldConstraint")
        w.Part0 = b
        w.Part1 = p
        w.Parent = p
        
        info.box = p
    end
    
    if not info.vis then
        local v = Instance.new("Part")
        v.Name = "HitboxVisual"
        v.Shape = Enum.PartType.Ball
        v.CanCollide = false
        v.Massless = true
        v.Anchored = false
        v.Material = Enum.Material.ForceField
        v.Color = Color3.fromRGB(100, 200, 255)
        v.Parent = b
        
        local w = Instance.new("WeldConstraint")
        w.Part0 = b
        w.Part1 = v
        w.Parent = v
        
        info.vis = v
    end
    
    info.box.Size = Vector3.new(size, size, size)
    info.box.CFrame = b.CFrame
    
    info.vis.Size = Vector3.new(size, size, size)
    info.vis.CFrame = b.CFrame
    info.vis.Transparency = trans
end

local function scan()
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name:sub(1, 12) == "CLIENT_BALL_" then
            if enabled then
                expand(obj)
            else
                cleanup(obj)
            end
        end
    end
end

local loop
local added
local removing

local function start()
    scan()
    
    loop = rs.Heartbeat:Connect(function()
        for b, info in pairs(balls) do
            if b and b.Parent then
                if info.box then
                    info.box.Size = Vector3.new(size, size, size)
                    info.box.CFrame = b.CFrame
                end
                if info.vis then
                    info.vis.Size = Vector3.new(size, size, size)
                    info.vis.CFrame = b.CFrame
                    info.vis.Transparency = trans
                end
            else
                cleanup(b)
            end
        end
    end)
    
    added = workspace.DescendantAdded:Connect(function(obj)
        if obj:IsA("BasePart") and obj.Name:sub(1, 12) == "CLIENT_BALL_" then
            task.wait(0.1)
            if enabled then
                expand(obj)
            end
        end
    end)
    
    removing = workspace.DescendantRemoving:Connect(function(obj)
        if obj:IsA("BasePart") and obj.Name:sub(1, 12) == "CLIENT_BALL_" then
            cleanup(obj)
        end
    end)
end

local function stop()
    if loop then loop:Disconnect() loop = nil end
    if added then added:Disconnect() added = nil end
    if removing then removing:Disconnect() removing = nil end
    
    for b, _ in pairs(balls) do
        cleanup(b)
    end
end

funcs:AddToggle("HitboxToggle", {
    Text = "Enable Hitbox Expander",
    Default = false,
    Callback = function(v)
        enabled = v
        if v then
            start()
        else
            stop()
        end
    end
})

funcs:AddSlider("HitboxSize", {
    Text = "Hitbox Size",
    Default = 10,
    Min = 5,
    Max = 20,
    Rounding = 1,
    Callback = function(v)
        size = v
    end
})

funcs:AddSlider("HitboxTransparency", {
    Text = "Hitbox Transparency",
    Default = 0.5,
    Min = 0,
    Max = 1,
    Rounding = 2,
    Callback = function(v)
        trans = v
    end
})

keybinds:AddLabel("Hitbox Expander"):AddKeyPicker("HitboxKeybind", {
    Default = "None",
    Mode = "Toggle",
    Text = "Toggle Hitbox",
    Callback = function(v)
        lib.Options.HitboxToggle:SetValue(v)
    end
})

local sets = win:AddTab("Settings", "settings")
local cfg = sets:AddLeftGroupbox("Configuration")

cfg:AddToggle("KeybindMenu", { Default = lib.KeybindFrame.Visible, Text = "Keybind Menu", Callback = function(v) lib.KeybindFrame.Visible = v end })
cfg:AddToggle("CustomCursor", { Text = "Custom Cursor", Default = true, Callback = function(v) lib.ShowCustomCursor = v end })
cfg:AddDropdown("NotifySide", { Values = { "Left", "Right" }, Default = "Right", Text = "Notification Side", Callback = function(v) lib:SetNotifySide(v) end })
cfg:AddDropdown("DPIScale", { Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" }, Default = "100%", Text = "DPI Scale", Callback = function(v) local n = tonumber(v:gsub("%%", "")) if n then lib:SetDPIScale(n / 100) end end })

cfg:AddDivider()
cfg:AddLabel("Keybind"):AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })
cfg:AddButton({ Text = "Unload", Func = function() lib:Unload() end })

lib.ToggleKeybind = lib.Options.MenuKeybind
theme:SetLibrary(lib)
save:SetLibrary(lib)
save:IgnoreThemeSettings()
save:SetIgnoreIndexes({ "MenuKeybind" })
theme:SetFolder("PlowsScriptHub")
save:SetFolder("PlowsScriptHub/General")
save:SetSubFolder("Universal")
save:BuildConfigSection(sets)
theme:ApplyToTab(sets)
save:LoadAutoloadConfig()

lib:OnUnload(function()
    if conn_fps then conn_fps:Disconnect() end
    stop()
end)
