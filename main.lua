local fallback = "https://raw.githubusercontent.com/nathanathan69420-pixel/PPS/main/unsupported.lua"
local base = "https://raw.githubusercontent.com/nathanathan69420-pixel/PPS/main/"

local scripts = {
    ["73956553001240"] = "volleyball_script.lua",
    ["74691681039273"] = "volleyball_script.lua",
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

local success, res = pcall(function()
    loadstring(game:HttpGet(url, true))()
end)

if not success then
    notify("Error", res, 5)
end
