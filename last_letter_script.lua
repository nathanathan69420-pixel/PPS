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

local function downloadWords()
    local url = "https://raw.githubusercontent.com/dwyl/english-words/refs/heads/master/words_alpha.txt"
    if not isfile("words_alpha.txt") then
        local res = request({Url = url, Method = "GET"})
        if res and res.Body then
            writefile("words_alpha.txt", res.Body)
        end
    end
end

local Words = {}
local function loadWords()
    if isfile("words_alpha.txt") then
        local content = readfile("words_alpha.txt")
        for w in content:gmatch("[^\r\n]+") do
            table.insert(Words, w)
        end
    end
end

local success = pcall(downloadWords)
if success then pcall(loadWords) end

local function SuggestWords(letter, count)
    letter = letter:lower()
    local possible = {}
    for _, w in ipairs(Words) do
        if w:sub(1,1):lower() == letter then
            table.insert(possible, w)
        end
    end
    local results = {}
    local used = {}
    local found = 0
    while found < count and found < #possible do
        local r = math.random(1, #possible)
        if not used[r] then
            table.insert(results, possible[r])
            used[r] = true
            found = found + 1
        end
    end
    return results
end

local wordLabel = wordbox:AddLabel("Select a letter below")
wordbox:AddInput("LetterInput", {
    Text = "Starting Letter",
    Default = "",
    Placeholder = "a-z",
    Callback = function(v)
        local l = v:sub(1,1):lower()
        if #l == 0 then return end
        local suggests = SuggestWords(l, 5)
        if #suggests > 0 then
            wordLabel:SetText("Words: " .. table.concat(suggests, ", "))
        else
            wordLabel:SetText("No words found for: " .. l)
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
