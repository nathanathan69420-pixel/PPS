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
    
    setreadonly(gm, false)
    gm.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if not checkcaller() then
            if method == "Kick" and self == lp then return nil end
        end
        return old_nc(self, ...)
    end)
    
    gm.__index = newcclosure(function(self, k)
        if not checkcaller() then
            if k == "Drawing" then return nil end
        end
        return old_idx(self, k)
    end)
    
    setreadonly(gm, true)
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
local cam = workspace.CurrentCamera

theme.BuiltInThemes["Default"][2] = {
    BackgroundColor = "16293a",
    MainColor = "26445f",
    AccentColor = "5983a0",
    OutlineColor = "325573",
    FontColor = "d2dae1"
}

local win = lib:CreateWindow({
    Title = "AXIS HUB",
    Footer = "v1.5.2",
    NotifySide = "Right",
    ShowCustomCursor = true,
})

local home = win:AddTab("Home", "house")
local main = win:AddTab("Main", "target")
local config = win:AddTab("Settings", "settings")

local status = home:AddLeftGroupbox("Status")
local wordbox = main:AddLeftGroupbox("Word Helper")
local visuals = main:AddRightGroupbox("Visuals")
local cfgBox = config:AddLeftGroupbox("Config")

status:AddLabel(string.format("Welcome, %s\nGame: Last Letter", lp.DisplayName), true)
status:AddButton({ Text = "Unload", Func = function() lib:Unload() end })

local lastWords = {
    a = {"apple", "anchor", "abyss", "active"},
    b = {"bread", "bright", "bottle", "bubble"},
    c = {"crown", "cloud", "camera", "cactus"},
    d = {"dream", "dance", "danger", "desert"},
    e = {"earth", "eagle", "engine", "energy"},
    f = {"flame", "frost", "flower", "forest"},
    g = {"ghost", "glass", "guitar", "garden"},
    h = {"heart", "honey", "hammer", "island"},
    i = {"image", "impact", "ivory", "insect"},
    j = {"jungle", "jacket", "jumper", "junior"},
    k = {"knight", "kettle", "keyboard", "kitchen"},
    l = {"light", "lemon", "ladder", "lizard"},
    m = {"mountain", "mirror", "museum", "marine"},
    n = {"nature", "night", "number", "nebula"},
    o = {"ocean", "orange", "object", "orbit"},
    p = {"planet", "purple", "postal", "player"},
    q = {"quartz", "queen", "quiet", "quiver"},
    r = {"rocket", "river", "random", "radius"},
    s = {"shadow", "silver", "spirit", "stream"},
    t = {"target", "timber", "travel", "theory"},
    u = {"unique", "update", "urban", "useful"},
    v = {"valley", "vector", "velvet", "visual"},
    w = {"winter", "window", "wisdom", "weapon"},
    x = {"xenon", "xerox", "xylem", "xbird"},
    y = {"yellow", "yield", "young", "yonder"},
    z = {"zebra", "zenith", "zigzag", "zodiac"}
}

local wordLabel = wordbox:AddLabel("Select a letter below")
wordbox:AddInput("LetterInput", {
    Text = "Starting Letter",
    Default = "",
    Placeholder = "a-z",
    Callback = function(v)
        local l = v:sub(1,1):lower()
        if lastWords[l] then
            wordLabel:SetText("Words: " .. table.concat(lastWords[l], ", "))
        else
            wordLabel:SetText("No words found for: " .. v)
        end
    end
})

visuals:AddToggle("ESPEnabled", { Text = "General ESP Toggle", Default = false }):AddKeyPicker("ESPKey", { Default = "None", SyncToggleState = true, Mode = "Toggle", Text = "ESP" })
visuals:AddToggle("BoxESP", { Text = "Box", Default = true }):AddKeyPicker("BoxKey", { Default = "None", SyncToggleState = true, Mode = "Toggle", Text = "Box" })

local Toggles = lib.Toggles
local Options = lib.Options

local espboxes = {}
local function removeplr(name)
    if espboxes[name] then espboxes[name]:Remove() espboxes[name] = nil end
end

local function getCharMinMax(char)
    local minX, maxX = math.huge, -math.huge
    local minY, maxY = math.huge, -math.huge
    for _, part in pairs(char:GetChildren()) do
        if part:IsA("BasePart") then
            local screenPos, onScreen = cam:WorldToViewportPoint(part.Position)
            if onScreen then
                minX = math.min(minX, screenPos.X)
                maxX = math.max(maxX, screenPos.X)
                minY = math.min(minY, screenPos.Y)
                maxY = math.max(maxY, screenPos.Y)
            end
        end
    end
    return maxX, maxY, minX, minY
end

local function mainESP(target)
    if not target or not target:IsA("Model") then return end
    local name = target.Name
    local espOn = Toggles.ESPEnabled and Toggles.ESPEnabled.Value
    local boxOn = Toggles.BoxESP and Toggles.BoxESP.Value
    
    local maxX, maxY, minX, minY = getCharMinMax(target)
    if maxX == -math.huge then return end

    if not espboxes[name] then
        espboxes[name] = Drawing.new("Square")
        espboxes[name].Transparency = 0.5
        espboxes[name].Color = Color3.new(1, 1, 1)
        espboxes[name].Thickness = 1
        espboxes[name].Filled = false
    end
    espboxes[name].Size = Vector2.new(maxX - minX, maxY - minY)
    espboxes[name].Position = Vector2.new(minX, minY)
    espboxes[name].Visible = espOn and boxOn
end

local mainLoop = rs.RenderStepped:Connect(function()
    local espOn = Toggles.ESPEnabled and Toggles.ESPEnabled.Value
    local alive = {}
    for _, plr in pairs(plrs:GetPlayers()) do
        if plr ~= lp and plr.Character and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health > 0 then
            alive[plr.Name] = true
            if espOn then mainESP(plr.Character) end
        end
    end
    for name, _ in pairs(espboxes) do if not alive[name] then removeplr(name) end end
end)

cfgBox:AddToggle("KeyMenu", { Default = lib.KeybindFrame.Visible, Text = "Keybind Menu", Callback = function(v) lib.KeybindFrame.Visible = v end })
cfgBox:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { Default = "RightControl", NoUI = true, Text = "Menu bind" })
lib.ToggleKeybind = lib.Options.MenuKeybind

theme:SetLibrary(lib)
save:SetLibrary(lib)
save:IgnoreThemeSettings()
save:SetIgnoreIndexes({ "MenuKeybind" })
theme:SetFolder("PlowsScriptHub")
save:SetFolder("PlowsScriptHub/LastLetter")
save:BuildConfigSection(config)
theme:ApplyToTab(config)
save:LoadAutoloadConfig()

lib:OnUnload(function()
    if mainLoop then mainLoop:Disconnect() end
    for name, _ in pairs(espboxes) do removeplr(name) end
end)

pcall(bypass)
