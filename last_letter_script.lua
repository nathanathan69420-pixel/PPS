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
    Title = "Axis Hub - Last Letter.lua",
    Footer = "by RwalDev & Plow | 1.9.4 | Discord: .gg/UuyxhqgEVs",
    NotifySide = "Right",
    ShowCustomCursor = true,
})

local home = win:AddTab("Home", "house")
local main = win:AddTab("Main", "pencil")
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
local waitingAnimation = 0
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
    local urls = {
        "https://raw.githubusercontent.com/dwyl/english-words/refs/heads/master/words_dictionary.json",
        "https://raw.githubusercontent.com/first20hours/google-10000-english/master/google-10000-english-usa-no-swears.txt"
    }
    
    for i, url in ipairs(urls) do
        local res = request({Url = url, Method = "GET"})
        if res and res.Body then
            if url:find("json") then
                writefile("words_dictionary.json", res.Body)
            else
                writefile("words_alpha.txt", res.Body)
            end
            break
        end
    end
end

local Words = {}
local WordMap = {}
local loaded = false
local commonWords = {
    ["the"] = true, ["and"] = true, ["a"] = true, ["an"] = true,
    ["is"] = true, ["it"] = true, ["to"] = true, ["of"] = true,
    ["in"] = true, ["for"] = true, ["on"] = true, ["with"] = true,
    ["as"] = true, ["at"] = true, ["by"] = true, ["or"] = true,
}

local function loadFromJSON(content)
    local success, wordsJson = pcall(function()
        return game:GetService("HttpService"):JSONDecode(content)
    end)
    
    if success then
        for word, _ in pairs(wordsJson) do
            local len = #word
            if len >= 1 and len <= 20 and not commonWords[word:lower()] then
                table.insert(Words, word:lower())
                local first = word:lower():sub(1,1)
                if not WordMap[first] then WordMap[first] = {} end
                table.insert(WordMap[first], word:lower())
            end
        end
        return true
    end
    return false
end

local function loadFromText(content)
    for word in content:gmatch("[^\r\n]+") do
        local len = #word
        if len >= 1 and len <= 20 and not commonWords[word:lower()] then
            table.insert(Words, word:lower())
            local first = word:lower():sub(1,1)
            if not WordMap[first] then WordMap[first] = {} end
            table.insert(WordMap[first], word:lower())
        end
    end
    return #Words > 0
end

local function loadWords()
    if loaded then return end
    
    if isfile("words_dictionary.json") then
        local content = readfile("words_dictionary.json")
        if loadFromJSON(content) then
            loaded = true
            return
        end
    end
    
    if isfile("words_alpha.txt") then
        local content = readfile("words_alpha.txt")
        if loadFromText(content) then
            loaded = true
        end
    end
end

pcall(downloadWords)
pcall(loadWords)

local function getSuggestions(input, count)
    input = input:lower()
    local suggestions = {}
    
    for _, w in ipairs(Words) do
        if w:sub(1, #input) == input and w ~= input then
            local len = #w
            if len >= charMin and len <= charMax then
                table.insert(suggestions, w)
            end
        end
    end
    
    table.sort(suggestions, function(a, b)
        local idealLength = 6
        local distA = math.abs(#a - idealLength)
        local distB = math.abs(#b - idealLength)
        
        if distA == distB then
            if #a == #b then
                return a < b
            end
            return #a < #b
        end
        return distA < distB
    end)
    
    local result = {}
    for i = 1, math.min(count, #suggestions) do
        table.insert(result, suggestions[i])
    end
    
    return result
end

local wordLabel = wordbox:AddLabel("Search results will appear here")

local function updateWaitingAnimation()
    waitingAnimation = (waitingAnimation + 1) % 4
    local dots = string.rep(".", waitingAnimation)
    hudLabel.Text = "Waiting" .. dots
end

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
    if lastDetected == "" then return end
    
    local allSuggestions = getSuggestions(lastDetected, 50)
    if #allSuggestions <= 3 then return end
    
    local currentWords = {}
    for word in hudLabel.Text:gmatch("(%a+)") do
        currentWords[word:lower()] = true
    end
    
    local available = {}
    for _, word in ipairs(allSuggestions) do
        if not currentWords[word:lower()] then
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
    while task.wait(0.2) do
        if not autoDetect then continue end
        
        local bestMatch = ""
        local bestScore = 0
        local foundAny = false
        
        for _, v in pairs(lp.PlayerGui:GetDescendants()) do
            if v:IsA("TextLabel") and v.Visible and #v.Text > 0 then
                local text = v.Text
                local clean = text:gsub("%s+", ""):lower()
                
                if clean:match("^[%a]+$") and #clean <= 20 then
                    foundAny = true
                    local score = 0
                    
                    if #clean >= 2 then
                        score = 50 + (#clean * 5)
                    else
                        score = 10
                    end
                    
                    local nameLower = v.Name:lower()
                    local parentName = v.Parent and v.Parent.Name:lower() or ""
                    
                    if nameLower:find("letter") or nameLower:find("word") or nameLower:find("text") or
                       nameLower:find("current") or nameLower:find("display") or
                       parentName:find("letter") or parentName:find("word") or parentName:find("text") then
                        score = score + 25
                    end
                    
                    if text:upper() == text then
                        score = score + 15
                    end
                    
                    if v.AbsoluteSize.X >= 60 and v.AbsoluteSize.Y >= 25 then
                        score = score + 10
                    end
                    
                    if v.Font.Size >= 14 then
                        score = score + 5
                    end
                    
                    if score > bestScore then
                        bestScore = score
                        bestMatch = clean
                    end
                end
            end
        end
        
        if #bestMatch > 0 then
            updateHUD(bestMatch)
        elseif not foundAny then
            updateWaitingAnimation()
        end
    end
end)

local LogService = game:GetService("LogService")

LogService.MessageOut:Connect(function(message, messageType)
    if autoDetect and message:find("Word:") then
        local letters = message:match("Word:%s*([A-Z][A-Z]?[A-Z]?[A-Z]?)")
        if letters then
            updateHUD(letters:lower())
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
