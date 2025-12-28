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
local cfgBox = config:AddLeftGroupbox("Config")

status:AddLabel(string.format("Welcome, %s\nGame: Last Letter", lp.DisplayName), true)
status:AddButton({ Text = "Unload", Func = function() lib:Unload() end })

local charMin, charMax = 2, 8

local function downloadWords()
    local url = "https://raw.githubusercontent.com/dwyl/english-words/refs/heads/master/words_alpha.txt"
    if not isfile("words_alpha.txt") then
        local res = request({Url = url, Method = "GET"})
        if res and res.Body then writefile("words_alpha.txt", res.Body) end
    end
end

local Words = {}
local WordMap = {}

local function loadWords()
    if isfile("words_alpha.txt") then
        local content = readfile("words_alpha.txt")
        for w in content:gmatch("[^\r\n]+") do
            local word = w:lower()
            table.insert(Words, word)
            local first = word:sub(1,1)
            if not WordMap[first] then WordMap[first] = {} end
            table.insert(WordMap[first], word)
        end
    end
end

pcall(downloadWords)
pcall(loadWords)

local function getSuggestions(input, count)
    input = input:lower()
    local first = input:sub(1,1)
    local pool = WordMap[first] or {}
    local matches = {}

    for _, w in ipairs(pool) do
        if w:sub(1, #input) == input and #w >= charMin and #w <= charMax then
            table.insert(matches, w)
        end
    end

    table.sort(matches, function(a, b) return #a < #b end)

    local final = {}
    for i = 1, math.min(count, #matches) do
        table.insert(final, matches[i])
    end
    return final
end

local wordLabel = wordbox:AddLabel("Search results will appear here")

wordbox:AddInput("LetterInput", {
    Text = "Word Starter",
    Default = "",
    Placeholder = "type Here...",
    Callback = function(v)
        if #v == 0 then return end
        local res = getSuggestions(v, 6)
        if #res > 0 then
            wordLabel:SetText("Result: " .. table.concat(res, ", "))
        else
            wordLabel:SetText("No matches for: " .. v)
        end
    end
})

wordbox:AddSlider("MinLen", {
    Text = "Minimum Length",
    Default = 2,
    Min = 1,
    Max = 15,
    Rounding = 0,
    Callback = function(v) charMin = v end
})

wordbox:AddSlider("MaxLen", {
    Text = "Maximum Length",
    Default = 8,
    Min = 1,
    Max = 25,
    Rounding = 0,
    Callback = function(v) charMax = v end
})

local Options = lib.Options
cfgBox:AddToggle("KeyMenu", { Default = lib.KeybindFrame.Visible, Text = "Keybind Menu", Callback = function(v) lib.KeybindFrame.Visible = v end })
cfgBox:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { Default = "RightControl", NoUI = true, Text = "Menu bind" })
lib.ToggleKeybind = Options.MenuKeybind

theme:SetLibrary(lib)
save:SetLibrary(lib)
save:IgnoreThemeSettings()
save:SetIgnoreIndexes({ "MenuKeybind" })
theme:SetFolder("PlowsScriptHub")
save:SetFolder("PlowsScriptHub/LastLetter")
save:BuildConfigSection(config)
theme:ApplyToTab(config)
save:LoadAutoloadConfig()

lib:OnUnload(function() end)

pcall(bypass)
