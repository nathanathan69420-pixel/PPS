local FALLBACK_SCRIPT_URL = "https://raw.githubusercontent.com/nathanathan69420-pixel/PPS/main/unsupported.lua"
local BASE_SCRIPT_REPO = "https://raw.githubusercontent.com/nathanathan69420-pixel/PPS/main/"

local GAME_SCRIPTS = {
    [6229116934] = BASE_SCRIPT_REPO .. "hoopz_script.lua",       -- Corrected PlaceId for Hoopz
    [73956553001240] = BASE_SCRIPT_REPO .. "volleyball_script.lua", -- Corrected PlaceId for Volleyball Legends
}

local scriptToExecuteURL = FALLBACK_SCRIPT_URL

if GAME_SCRIPTS[game.PlaceId] then
    scriptToExecuteURL = GAME_SCRIPTS[game.PlaceId]
end

local success, result = pcall(function()
    local scriptContent = game:HttpGet(scriptToExecuteURL)
    local loadedFunction = loadstring(scriptContent)
    if loadedFunction then
        loadedFunction()
    else
        warn("Plow's Script Loader: Failed to compile script from URL: " .. scriptToExecuteURL)
    end
end)

if not success then
    warn("Plow's Script Loader: An error occurred during script execution: " .. tostring(result))
end
