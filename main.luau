local fallback = "https://raw.githubusercontent.com/nathanathan69420-pixel/PPS/main/unsupported.luau"
local base = "https://raw.githubusercontent.com/nathanathan69420-pixel/PPS/main/"

local scripts = {
    ["73956553001240"] = "volleyball_script.luau",
    ["118614517739521"] = "BlindShot.luau",
    ["74691681039273"] = "volleyball_script.luau",
    ["14841485778"] = "possessor_script.luau",
    ["136801880565837"] = "flick_script.luau",
    ["72920620366355"] = "operation_one_script.luau",
    ["129866685202296"] = "last_letter_script.luau",
    ["6298476159"] = "violence_district_script.luau",
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
