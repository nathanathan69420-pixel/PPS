local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/"
local lib = loadstring(game:HttpGet(repo .. "Library.lua"))()
local theme = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local save = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

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
        local args = {...}
        if not checkcaller() then
            if method == "Kick" and self == lp then return nil end
            if method == "GetService" or method == "getService" then
                local s = args[1]
                if s == "VirtualInputManager" or s == "HttpService" or s == "TeleportService" or s == "GuiService" then
                    return Instance.new("Folder")
                end
            end
            if method == "OpenBrowserWindow" or method == "OpenVideo" then return nil end
        end
        return old_nc(self, ...)
    end)
    
    gm.__index = newcclosure(function(self, k)
        if not checkcaller() then
            if k == "Drawing" or k == "VirtualInputManager" or k == "HttpService" or k == "TeleportService" or k == "GuiService" then
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
    
    local oldHttpGet = g.HttpGet
    g.HttpGet = function(self, url, ...)
        if not checkcaller() then return "" end
        return oldHttpGet(self, url, ...)
    end
end

local function get(name)
    local s = game:GetService(name)
    if not s then return nil end
    if cloneref then
        local success, res = pcall(cloneref, s)
        return success and res or s
    end
    return s
end

local rs = get("RunService")
local plrs = get("Players")
local lp = plrs.LocalPlayer

theme.BuiltInThemes["Default"][2] = {
    BackgroundColor = "16293a",
    MainColor = "26445f",
    AccentColor = "5983a0",
    OutlineColor = "325573",
    FontColor = "d2dae1"
}

local win = lib:CreateWindow({
    Title = "Axis Hub - Minesweeper.lua",
    Footer = "by RwalDev & Plow | 1.8.4 | Discord: .gg/UuyxhqgEVs",
    NotifySide = "Right",
    ShowCustomCursor = true,
})

local home = win:AddTab("Home", "house")
local main = win:AddTab("Main", "target")
local config = win:AddTab("Settings", "settings")

local status = home:AddLeftGroupbox("Status")
status:AddLabel(string.format("Welcome, %s\nGame: Minesweeper", lp.DisplayName), true)
status:AddButton({ Text = "Unload", Func = function() lib:Unload() end })

local mainBox = main:AddLeftGroupbox("Main")
mainBox:AddToggle("HighlightMines", { Text = "Highlight Mines", Default = false })

local mineHighlights = {}

local function updateMines()
    local enabled = lib.Toggles.HighlightMines and lib.Toggles.HighlightMines.Value
    if enabled then
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and obj.Name == "Mine" then
                if not mineHighlights[obj] then
                    local h = Instance.new("Highlight")
                    h.FillColor = Color3.fromRGB(255, 0, 0)
                    h.OutlineColor = Color3.fromRGB(255, 255, 255)
                    h.FillTransparency = 0.5
                    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    h.Adornee = obj
                    h.Parent = get("CoreGui")
                    mineHighlights[obj] = h
                end
            end
        end
    else
        for obj, h in pairs(mineHighlights) do
            h:Destroy()
            mineHighlights[obj] = nil
        end
    end
end

rs.RenderStepped:Connect(updateMines)

local cfgBox = config:AddLeftGroupbox("Config")
cfgBox:AddToggle("KeyMenu", { Default = lib.KeybindFrame.Visible, Text = "Keybind Menu", Callback = function(v) lib.KeybindFrame.Visible = v end })
cfgBox:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { Default = "RightControl", NoUI = true, Text = "Menu bind" })
lib.ToggleKeybind = lib.Options.MenuKeybind

theme:SetLibrary(lib)
save:SetLibrary(lib)
save:IgnoreThemeSettings()
save:SetIgnoreIndexes({ "MenuKeybind" })
theme:SetFolder("PlowsScriptHub")
save:SetFolder("PlowsScriptHub/Minesweeper")
save:BuildConfigSection(config)
theme:ApplyToTab(config)
save:LoadAutoloadConfig()

lib:OnUnload(function()
    for _, h in pairs(mineHighlights) do h:Destroy() end
end)

pcall(bypass)
