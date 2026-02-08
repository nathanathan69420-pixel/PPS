local function bypass()
    local g = game
    local lp = g:GetService("Players").LocalPlayer
    if not getrawmetatable or not setreadonly or not newcclosure or not getnamecallmethod then return end
    
    local gm = getrawmetatable(g)
    local old_nc = gm.__namecall
    local old_idx = gm.__index
    local old_ns = gm.__newindex
    
    setreadonly(gm, false)
    
    gm.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if not checkcaller() then
            if method == "Kick" and self == lp then return nil end
            if method == "GetService" or method == "getService" then
                local s = select(1, ...)
                if s == "HttpService" or s == "TeleportService" or s == "GuiService" then
                    return Instance.new("Folder")
                end
            end
        end
        return old_nc(self, ...)
    end)
    
    gm.__index = newcclosure(function(self, k)
        if not checkcaller() then
            if k == "HttpService" or k == "TeleportService" or k == "GuiService" then
                return Instance.new("Folder")
            end
        end
        return old_idx(self, k)
    end)
    
    gm.__newindex = newcclosure(function(self, k, v)
        if not checkcaller() then
            if k == "Enabled" and (self:IsA("Script") or self:IsA("LocalScript")) then
                return
            end
        end
        return old_ns(self, k, v)
    end)
    
    setreadonly(gm, true)
end

pcall(bypass)

local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/"
local lib = loadstring(game:HttpGet(repo .. "Library.lua"))()
if not lib then error("Failed to load Library.lua") end
local theme = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
if not theme then error("Failed to load ThemeManager.lua") end
local save = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()
if not save then error("Failed to load SaveManager.lua") end

local rs = game:GetService("RunService")
local plrs = game:GetService("Players")
local uis = game:GetService("UserInputService")
local lp = plrs.LocalPlayer
local cam = workspace.CurrentCamera

local ts, os = lib.Toggles, lib.Options

theme.BuiltInThemes["Default"][2] = {
    BackgroundColor = "16293a", MainColor = "26445f", AccentColor = "5983a0", OutlineColor = "325573", FontColor = "d2dae1"
}

local win = lib:CreateWindow({
    Title = "Axis Hub - Volleyball.lua", Footer = "by RwalDev & Plow | 1.9.8 | Discord: .gg/UuyxhqgEVs", NotifySide = "Right", ShowCustomCursor = true,
})

local home = win:AddTab("Home", "house")
local hitbox = win:AddTab("Hitbox", "activity")
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

local enabled = false
local size = 10
local trans = 0.5
local hitbox_circle

local function draw_circle()
    if hitbox_circle then hitbox_circle:Remove() end
    hitbox_circle = Drawing.new("Circle")
    hitbox_circle.Color = Color3.fromRGB(100, 200, 255)
    hitbox_circle.Thickness = 2
    hitbox_circle.NumSides = 32
    hitbox_circle.Filled = false
    hitbox_circle.Visible = false
end

draw_circle()

local function get_closest_ball()
    if not enabled then return end
    local mouse_pos = uis:GetMouseLocation()
    local ray_origin = cam.CFrame.Position
    local ray_direction = (cam:ScreenPointToRay(mouse_pos.X, mouse_pos.Y).Direction).Unit * 1000
    
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = {lp.Character}
    
    local result = workspace:Spherecast(ray_origin, size, ray_direction, params)
    if result and result.Instance and result.Instance.Name:sub(1, 12) == "CLIENT_BALL_" then
        return result.Instance
    end
end

local function update_visualizer()
    if not enabled or not hitbox_circle then return end
    
    local ball = get_closest_ball()
    if ball then
        local screen_pos, on_screen = cam:WorldToViewportPoint(ball.Position)
        if on_screen and screen_pos.Z > 0 then
            hitbox_circle.Position = Vector2.new(screen_pos.X, screen_pos.Y)
            
            -- Calculate accurate screen radius for hitbox
            local world_pos = ball.Position
            local dir = world_pos - cam.CFrame.Position
            local distance = dir.Magnitude
            local fov_rad = math.rad(cam.FieldOfView)
            local screen_radius = (size / distance) * (cam.ViewportSize.Y / (2 * math.tan(fov_rad / 2)))
            
            hitbox_circle.Radius = math.abs(screen_radius)
            hitbox_circle.Visible = true
        else
            hitbox_circle.Visible = false
        end
    else
        hitbox_circle.Visible = false
    end
end

funcs:AddToggle("Hitbox", { Text = "Enable Hitbox Expander", Callback = function(v) 
    enabled = v 
end })

funcs:AddSlider("Size", { Text = "Hitbox Size", Default = 10, Min = 5, Max = 20, Callback = function(v) size = v end })
funcs:AddSlider("Transparency", { Text = "Hitbox Transparency", Default = 0.5, Min = 0, Max = 1, Callback = function(v) trans = v end })

keybinds:AddLabel("Hitbox Expander"):AddKeyPicker("HitboxKey", { Default = "None", Mode = "Toggle", Text = "Toggle Hitbox", Callback = function(v) 
    if lib.Toggles.Hitbox then lib.Toggles.Hitbox:SetValue(v) end
end })

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
    update_visualizer()
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
    if hitbox_circle and hitbox_circle.Remove then hitbox_circle:Remove() end
    enabled = false
    hitbox_circle = nil
end)
