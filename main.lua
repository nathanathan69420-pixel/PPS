local FALLBACK_SCRIPT_URL = "https://raw.githubusercontent.com/nathanathan69420-pixel/PPS/main/unsupported.lua"
local BASE_SCRIPT_REPO = "https://raw.githubusercontent.com/nathanathan69420-pixel/PPS/main/"

local GAME_SCRIPTS = {
    [2577717469] = BASE_SCRIPT_REPO .. "hoopz_script.lua",
    [9979737976] = BASE_SCRIPT_REPO .. "volleyball_script.lua",
}

local scriptToExecuteURL = FALLBACK_SCRIPT_URL

if GAME_SCRIPTS[game.PlaceId] then
    scriptToExecuteURL = GAME_SCRIPTS[game.PlaceId]
end

local success, errorMessage = pcall(function()
    local scriptContent = game:HttpGet(scriptToExecuteURL)
    local loadedFunction = loadstring(scriptContent)
    if loadedFunction then
        loadedFunction()
    end
end)
