local FALLBACK_SCRIPT_URL = "https://raw.githubusercontent.com/nathanathan69420-pixel/PPS/main/unsupported.lua"
local BASE_SCRIPT_REPO = "https://raw.githubusercontent.com/nathanathan69420-pixel/PPS/main/"

local GAME_SCRIPTS = {
    [73956553001240] = BASE_SCRIPT_REPO .. "volleyball_script.lua",
}

local scriptToExecuteURL = FALLBACK_SCRIPT_URL

local function showNotification(title, message, duration)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = title,
            Text = message,
            Duration = duration or 5
        })
    end)
end

if GAME_SCRIPTS[game.PlaceId] then
    scriptToExecuteURL = GAME_SCRIPTS[game.PlaceId]
else
    showNotification("Script Loader", "Unsupported Game detected! Loading universal fallback...", 3)
end

local success, result = pcall(function()
    local scriptContent = game:HttpGet(scriptToExecuteURL)
    local loadedFunction = loadstring(scriptContent)
    if loadedFunction then
        loadedFunction()
    else
        showNotification("Script Loader", "Failed to compile script", 3)
    end
end)

if not success then
    showNotification("Script Loader", "Error during execution: " .. tostring(result), 5)
end
