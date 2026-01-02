local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/"
local lib = loadstring(game:HttpGet(repo .. "Library.lua"))()

local function get(name)
    local s = game:GetService(name)
    if not s then return nil end
    if cloneref then
        local success, res = pcall(cloneref, s)
        return success and res or s
    end
    return s
end

local plrs = get("Players")
local lp = plrs.LocalPlayer

local win = lib:CreateWindow({
    Title = "UI Debugger",
    NotifySide = "Right",
})

local main = win:AddTab("Debug", "search")
local output = main:AddLeftGroupbox("UI Scanner Results")

local scanBtn = main:AddButton({ Text = "Scan PlayerGui", Func = function() 
    local results = {}
    for _, v in pairs(lp.PlayerGui:GetDescendants()) do
        if v:IsA("TextLabel") and v.Visible and #v.Text > 0 then
            local clean = v.Text:gsub("%s+", "")
            if #clean > 0 then
                table.insert(results, {
                    Name = v.Name,
                    Text = v.Text,
                    Parent = v.Parent and v.Parent.Name or "Unknown",
                    Visible = v.Visible,
                    CleanText = clean,
                    Length = #clean
                })
            end
        end
    end
    
    local outputText = "Found " .. #results .. " TextLabels:\n\n"
    for i, r in ipairs(results) do
        if i <= 10 then
            outputText = outputText .. string.format("%d. %s\n   Text: '%s'\n   Parent: %s\n   Clean: '%s' (%d)\n\n", 
                i, r.Name, r.Text, r.Parent, r.CleanText, r.Length)
        end
    end
    
    if #results > 10 then
        outputText = outputText .. "... and " .. (#results - 10) .. " more"
    end
    
    output:AddLabel(outputText)
end })

local watchBtn = main:AddButton({ Text = "Start Live Watch", Func = function()
    local lastTexts = {}
    local running = true
    
    task.spawn(function()
        while running and task.wait(0.3) do
            local currentTexts = {}
            local changes = {}
            
            for _, v in pairs(lp.PlayerGui:GetDescendants()) do
                if v:IsA("TextLabel") and v.Visible and #v.Text > 0 then
                    local clean = v.Text:gsub("%s+", "")
                    if #clean > 0 then
                        currentTexts[v:GetFullName()] = clean
                        
                        if lastTexts[v:GetFullName()] ~= clean then
                            table.insert(changes, {
                                Name = v.Name,
                                Path = v:GetFullName(),
                                Old = lastTexts[v:GetFullName()] or "NEW",
                                New = clean
                            })
                        end
                    end
                end
            end
            
            if #changes > 0 then
                local changeText = "Changes detected:\n\n"
                for i, c in ipairs(changes) do
                    if i <= 5 then
                        changeText = changeText .. string.format("%s\n'%s' -> '%s'\n\n", 
                            c.Name, c.Old, c.New)
                    end
                end
                
                output:AddLabel(changeText)
            end
            
            lastTexts = currentTexts
        end
    end)
    
    task.delay(10, function() running = false end)
end })

output:AddLabel("Click 'Scan PlayerGui' to see all TextLabels\nor 'Start Live Watch' to monitor changes")
