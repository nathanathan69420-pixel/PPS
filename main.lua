local fallback = "https://raw.githubusercontent.com/nathanathan69420-pixel/PPS/main/unsupported.lua"
local base = "https://raw.githubusercontent.com/nathanathan69420-pixel/PPS/main/"

local scripts = {
    ["73956553001240"] = "volleyball_script.lua",
    ["118614517739521"] = "BlindShot.lua",
    ["74691681039273"] = "volleyball_script.lua",
    ["14841485778"] = "possessor_script.lua",
    ["136801880565837"] = "flick_script.lua",
    ["72920620366355"] = "operation_one_script.lua",
    ["129866685202296"] = "last_letter_script.lua",
    ["6298476159"] = "violence_district_script.lua",
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
