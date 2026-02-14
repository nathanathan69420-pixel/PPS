local fallback = "https://raw.githubusercontent.com/nathanathan69420-pixel/PPS/main/unsupported.lua"
local base = "https://raw.githubusercontent.com/nathanathan69420-pixel/PPS/main/"

local function bypass()
    local g = game
    local lp = g:GetService("Players").LocalPlayer
    
    if not hookmetamethod or not getrawmetatable or not setreadonly then return end
    
    local blockedServices = {
        VirtualInputManager = true,
        HttpService = true,
        TeleportService = true,
        GuiService = true,
        MessageBusService = true,
        AnalyticsService = true,
        ScriptContext = true
    }
    
    local blockedIndexes = {
        Drawing = true,
        VirtualInputManager = true,
        HttpService = true,
        TeleportService = true,
        GuiService = true,
        PreloadAsync = true
    }
    
    local serviceCache = {}
    local folderCache = {}
    
    local function getFolder(name)
        if not folderCache[name] then
            local f = Instance.new("Folder")
            f.Name = name
            folderCache[name] = f
        end
        return folderCache[name]
    end
    
    local oldIndex
    oldIndex = hookmetamethod(g, "__index", function(self, key)
        if not checkcaller() then
            if blockedIndexes[key] then
                return nil
            end
            if key == "GetService" or key == "getService" then
                return function(s, n)
                    if blockedServices[n] then
                        return getFolder(n)
                    end
                    if serviceCache[n] then
                        return serviceCache[n]
                    end
                    local r = oldIndex(self, key)(s, n)
                    serviceCache[n] = r
                    return r
                end
            end
        end
        return oldIndex(self, key)
    end)
    
    local oldNamecall
    oldNamecall = hookmetamethod(g, "__namecall", function(self, ...)
        local m = getnamecallmethod()
        local a = {...}
        
        if not checkcaller() then
            if m == "Kick" and self == lp then
                return task.wait(9e9)
            end
            
            if (m == "GetService" or m == "getService") and #a > 0 then
                local s = a[1]
                if blockedServices[s] then
                    return getFolder(s)
                end
            end
            
            if m == "OpenBrowserWindow" or m == "OpenVideo" then
                return nil
            end
            
            if m == "PreloadAsync" then
                return nil
            end
            
            if m == "GetLogHistory" or m == "SaveLog" then
                return {}
            end
        end
        
        return oldNamecall(self, ...)
    end)
    
    local oldNewIndex
    oldNewIndex = hookmetamethod(g, "__newindex", function(self, key, value)
        if not checkcaller() then
            if key == "Enabled" and typeof(self) == "Instance" and (self:IsA("Script") or self:IsA("LocalScript")) then
                return
            end
        end
        return oldNewIndex(self, key, value)
    end)
    
    if hookfunction then
        local oldGetService = hookfunction(lp.GetService, function(s, n)
            if blockedServices[n] then
                return getFolder(n)
            end
            return oldGetService(s, n)
        end)
    end
    
    local mt = getrawmetatable(g)
    if mt and setreadonly then
        setreadonly(mt, true)
    end
    
    task.spawn(function()
        while task.wait(math.random(30, 60)) do
            folderCache = {}
            serviceCache = {}
        end
    end)
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
    ["12355337193"] = "mvs_duels_script.lua",
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
