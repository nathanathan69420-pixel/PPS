local fallback = "https://raw.githubusercontent.com/nathanathan69420-pixel/PPS/main/unsupported.lua"
local base = "https://raw.githubusercontent.com/nathanathan69420-pixel/PPS/main/"

local function bypass()
    if not getrawmetatable or not setreadonly or not newcclosure or not getnamecallmethod then return end
    
    local g = game
    local lp = g:GetService("Players").LocalPlayer
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
        if not checkcaller() then 
            local success, result = pcall(oldHttpGet, self, url, ...)
            return success and result or ""
        end
        return oldHttpGet(self, url, ...)
    end
end

pcall(bypass)

local scripts = {
    ["73956553001240"] = "volleyball_script.lua",
    ["118614517739521"] = "BlindShot.lua",
    ["74691681039273"] = "volleyball_script.lua",
    ["14841485778"] = "possessor_script.lua",
    ["136801880565837"] = "flick_script.lua",
    ["72920620366355"] = "operation_one_script.lua",
    ["129866685202296"] = "last_letter_script.lua",
    ["6298476159"] = "violence_district_script.lua",
    ["7871169780"] = "minesweeper_script.lua",
    ["114234929420007"] = "bloxstrike_script.lua",
}

local function notify(title, msg, dur)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = title,
            Text = msg,
            Duration = dur or 5
        })
    end)
end

local id = tostring(game.PlaceId)
local url

if scripts[id] then
    url = base .. scripts[id]
    notify("Loader", "Loading...", 2)
else
    url = fallback
    notify("Loader", "Unsupported Game", 3)
end

local function safeLoad()
    local httpSuccess, scriptContent = pcall(function()
        return game:HttpGet(url, true)
    end)
    
    if not httpSuccess or not scriptContent then
        return false, "Failed to fetch script"
    end
    
    local loadSuccess, result = pcall(function()
        local func = loadstring(scriptContent)
        if func then
            func()
            return true
        end
        return false, "Failed to compile script"
    end)
    
    return loadSuccess, result
end

local success, res = safeLoad()

if not success then
    notify("Error", res, 5)
end
