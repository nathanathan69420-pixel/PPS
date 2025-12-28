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
local hudCol = main:AddRightGroupbox("HUD Settings")
local cfgBox = config:AddLeftGroupbox("Config")

status:AddLabel(string.format("Welcome, %s\nGame: Last Letter", lp.DisplayName), true)
status:AddButton({ Text = "Unload", Func = function() lib:Unload() end })

local hudOn = true
local autoDetect = true
local debugMode = false
local lastDetected = ""
local currentLetter = ""
local hudGui = Instance.new("ScreenGui", get("CoreGui"))
hudGui.Name = "AXISHUD"

local hudFrame = Instance.new("Frame", hudGui)
hudFrame.Size = UDim2.new(0, 300, 0, 70)
hudFrame.Position = UDim2.new(0.5, -150, 0, 45)
hudFrame.BackgroundColor3 = Color3.fromRGB(22, 41, 58)
hudFrame.BorderSizePixel = 0
hudFrame.Active = true
hudFrame.Draggable = true
local corner = Instance.new("UICorner", hudFrame)
corner.CornerRadius = UDim.new(0, 8)
local stroke = Instance.new("UIStroke", hudFrame)
stroke.Color = Color3.fromRGB(50, 85, 115)
stroke.Thickness = 1.5

local hudLabel = Instance.new("TextLabel", hudFrame)
hudLabel.Size = UDim2.new(1, -70, 1, 0)
hudLabel.Position = UDim2.new(0, 10, 0, 0)
hudLabel.BackgroundTransparency = 1
hudLabel.TextColor3 = Color3.new(1, 1, 1)
hudLabel.Font = Enum.Font.GothamMedium
hudLabel.TextSize = 13
hudLabel.Text = "Waiting for game..."
hudLabel.TextWrapped = true

local rerollBtn = Instance.new("TextButton", hudFrame)
rerollBtn.Size = UDim2.new(0, 50, 0, 25)
rerollBtn.Position = UDim2.new(1, -60, 0, 10)
rerollBtn.BackgroundColor3 = Color3.fromRGB(89, 131, 160)
rerollBtn.BorderSizePixel = 0
rerollBtn.Font = Enum.Font.GothamMedium
rerollBtn.TextSize = 10
rerollBtn.Text = "Reroll"
rerollBtn.TextColor3 = Color3.new(1, 1, 1)
local btnCorner = Instance.new("UICorner", rerollBtn)
btnCorner.CornerRadius = UDim.new(0, 4)

rerollBtn.MouseEnter:Connect(function()
    rerollBtn.BackgroundColor3 = Color3.fromRGB(105, 150, 180)
end)

rerollBtn.MouseLeave:Connect(function()
    rerollBtn.BackgroundColor3 = Color3.fromRGB(89, 131, 160)
end)


hudCol:AddToggle("HUDVisible", { Text = "Show HUD", Default = true, Callback = function(v) hudFrame.Visible = v end })
hudCol:AddToggle("AutoDetect", { Text = "Auto Detect Letter", Default = true, Callback = function(v) autoDetect = v end })
hudCol:AddToggle("DebugMode", { Text = "Debug Mode", Default = false, Callback = function(v) debugMode = v end })
hudCol:AddButton({ Text = "Reset Detection", Func = function() lastDetected = "" hudLabel.Text = "Waiting..." end })


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

local function updateHUD(text, forceReroll)
    local cleanText = text:gsub("%s+", ""):lower()
    if #cleanText == 0 then return end
    
    local letter = cleanText:sub(-1)
    local prefix = cleanText:sub(1, #cleanText - 1)
    
    if not forceReroll and cleanText == lastDetected then return end
    lastDetected = cleanText
    currentLetter = letter
    
    local suggests = getSuggestions(prefix .. letter, 3)
    if #suggests > 0 then
        local displayText = ""
        if #prefix > 0 then
            displayText = string.format("%s+%s: %s", prefix:upper(), letter:upper(), table.concat(suggests, ", "))
        else
            displayText = string.format("Letter: %s | Words: %s", letter:upper(), table.concat(suggests, ", "))
        end
        hudLabel.Text = displayText
    else
        if #prefix > 0 then
            hudLabel.Text = string.format("%s+%s: No words found", prefix:upper(), letter:upper())
        else
            hudLabel.Text = string.format("Letter: %s | No words found", letter:upper())
        end
    end
end

local function rerollWords()
    if currentLetter == "" then return end
    
    local allSuggestions = getSuggestions(currentLetter, 20)
    if #allSuggestions <= 3 then return end
    
    local used = {}
    for word in hudLabel.Text:gmatch("(%a+)") do
        used[word:lower()] = true
    end
    
    local available = {}
    for _, word in ipairs(allSuggestions) do
        if not used[word:lower()] then
            table.insert(available, word)
        end
    end
    
    if #available > 0 then
        local newSuggestions = {}
        for i = 1, math.min(3, #available) do
            local idx = math.random(1, #available)
            table.insert(newSuggestions, available[idx])
            table.remove(available, idx)
        end
        
        local prefix = lastDetected:sub(1, #lastDetected - 1)
        if #prefix > 0 then
            hudLabel.Text = string.format("%s+%s: %s", prefix:upper(), currentLetter:upper(), table.concat(newSuggestions, ", "))
        else
            hudLabel.Text = string.format("Letter: %s | Words: %s", currentLetter:upper(), table.concat(newSuggestions, ", "))
        end
    end
end

rerollBtn.MouseButton1Click:Connect(rerollWords)

wordbox:AddInput("LetterInput", {
    Text = "Manual Letter/Word",
    Default = "",
    Placeholder = "Type letter or word...",
    Callback = function(v)
        if #v == 0 then return end
        local clean = v:gsub("%s+", ""):lower()
        local res = getSuggestions(clean, 6)
        if #res > 0 then
            wordLabel:SetText("Result: " .. table.concat(res, ", "))
            updateHUD(clean)
        else
            wordLabel:SetText("No matches for: " .. clean)
        end
    end
})

task.spawn(function()
    while task.wait(0.25) do
        if not autoDetect then continue end
        
        local candidates = {}
        local gameLabels = {}
        local priorityLabels = {}
        local debugInfo = {}
        
        for _, v in pairs(lp.PlayerGui:GetDescendants()) do
            if v:IsA("TextLabel") and v.Visible and #v.Text > 0 then
                local clean = v.Text:gsub("%s+", ""):lower()
                if string.match(clean, "^[%a]+$") then
                    local nameLower = v.Name:lower()
                    local parentLower = v.Parent and v.Parent.Name:lower() or ""
                    
                    if #clean == 1 then
                        local priority = 10
                        if nameLower:find("letter") or nameLower:find("current") or parentLower:find("letter") then
                            priority = 20
                            table.insert(priorityLabels, {text = clean, label = v, priority = priority})
                            if debugMode then table.insert(debugInfo, string.format("HIGH: '%s' (%s)", clean, v.Name)) end
                        else
                            table.insert(candidates, {text = clean, label = v, priority = priority})
                            if debugMode then table.insert(debugInfo, string.format("CAND: '%s' (%s)", clean, v.Name)) end
                        end
                    elseif #clean >= 2 and #clean <= 15 then
                        local priority = 5
                        if nameLower:find("word") or nameLower:find("current") or parentLower:find("word") then
                            priority = 15
                            table.insert(gameLabels, {text = clean, label = v, priority = priority})
                            if debugMode then table.insert(debugInfo, string.format("WORD: '%s' (%s)", clean, v.Name)) end
                        else
                            table.insert(candidates, {text = clean, label = v, priority = priority})
                            if debugMode and #debugInfo < 5 then table.insert(debugInfo, string.format("CAND: '%s' (%s)", clean, v.Name)) end
                        end
                    end
                end
            end
        end
        
        local bestMatch = nil
        local highestPriority = 0
        
        for _, candidate in ipairs(priorityLabels) do
            if candidate.priority > highestPriority then
                highestPriority = candidate.priority
                bestMatch = candidate
            end
        end
        
        if not bestMatch then
            for _, candidate in ipairs(gameLabels) do
                if candidate.priority > highestPriority then
                    highestPriority = candidate.priority
                    bestMatch = candidate
                end
            end
        end
        
        if not bestMatch then
            for _, candidate in ipairs(candidates) do
                if candidate.priority > highestPriority then
                    highestPriority = candidate.priority
                    bestMatch = candidate
                end
            end
        end
        
        if debugMode and #debugInfo > 0 then
            local debugText = "DEBUG: " .. table.concat(debugInfo, " | ")
            if bestMatch then
                debugText = debugText .. " -> SELECTED: '" .. bestMatch.text .. "'"
            end
            hudLabel.Text = debugText
        elseif bestMatch then
            local text = bestMatch.text
            updateHUD(text)
        end
    end
end)


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

lib:OnUnload(function()
    if hudGui then hudGui:Destroy() end
end)

pcall(bypass)
