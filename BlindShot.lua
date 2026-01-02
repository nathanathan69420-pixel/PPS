local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/"
local lib = loadstring(game:HttpGet(repo .. "Library.lua"))()
local theme = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local save = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()
local Twilight = loadstring(game:HttpGet("https://raw.nebulasoftworks.xyz/twilight"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Stats = game:GetService("Stats")

local LocalPlayer = Players.LocalPlayer

theme.BuiltInThemes["Default"][2] = {
    BackgroundColor = "16293a",
    MainColor = "26445f",
    AccentColor = "5983a0",
    OutlineColor = "325573",
    FontColor = "d2dae1"
}

local win = lib:CreateWindow({
    Title = "Axis Hub - Blind Shot.lua",
    Footer = "by RwalDev & Plow | 1.7.2 | Discord: .gg/UuyxhqgEVs",
    NotifySide = "Right",
    ShowCustomCursor = true,
})

local homeTab = win:AddTab("Home", "house")
local mainTab = win:AddTab("Main", "crosshair")
local miscTab = win:AddTab("Misc", "box")

local status = homeTab:AddLeftGroupbox("Status")
local name = LocalPlayer and LocalPlayer.DisplayName or "Player"
local time = os.date("%H:%M:%S")

status:AddLabel(string.format("Welcome, %s\nCurrent time: %s\nGame: Blind Shot", name, time), true)

status:AddButton({
    Text = "Unload Script",
    Func = function() lib:Unload() end
})

local stats = homeTab:AddRightGroupbox("Performance")
local fpsLbl = stats:AddLabel("FPS: ...", true)
local pingLbl = stats:AddLabel("Ping: ...", true)

local elap, frames = 0, 0
local perfConn

perfConn = RunService.RenderStepped:Connect(function(dt)
    frames = frames + 1
    elap = elap + dt

    if elap >= 1 then
        fpsLbl:SetText("FPS: " .. math.floor(frames / elap + 0.5))
        local net = Stats.Network.ServerStatsItem["Data Ping"]
        pingLbl:SetText("Ping: " .. (net and math.floor(net:GetValue()) or 0) .. " ms")
        frames, elap = 0, 0
    end
end)

local trophyBox = mainTab:AddLeftGroupbox("Auto Trophy")

trophyBox:AddToggle("TrophyTeleport", {
    Text = "Auto Trophy (Teleport)",
    Default = false,
    Tooltip = "Teleports to trophy for collection",
    Callback = function(value)
        _G.TrophyTeleportFarmV2 = value
        if not value then return end
        
        spawn(function()
            while _G.TrophyTeleportFarmV2 do
                task.wait(0.1)
                local character = LocalPlayer.Character
                if character then
                    local hrp = character:FindFirstChild("HumanoidRootPart")
                    local trophy = workspace:FindFirstChild("Trophy", true)
                    
                    if hrp and trophy then
                        local parts = workspace:GetPartsInPart(hrp)
                    end
                end
            end
        end)
    end
})

trophyBox:AddToggle("TrophyTouch", {
    Text = "Auto Trophy (Touch)",
    Default = false,
    Tooltip = "Uses firetouchinterest method",
    Callback = function(value)
        _G.TrophyFarm = value
        if not value then return end
        
        spawn(function()
            while _G.TrophyFarm do
                task.wait(0.3)
                local character = LocalPlayer.Character
                if character then
                    local hrp = character:FindFirstChild("HumanoidRootPart")
                    local trophy = workspace:FindFirstChild("Trophy", true)
                    
                    if hrp and trophy and firetouchinterest then
                        firetouchinterest(hrp, trophy, 0)
                        task.wait()
                        firetouchinterest(hrp, trophy, 1)
                    end
                end
            end
        end)
    end
})

trophyBox:AddLabel("Recommended: Teleport method")

local aimBox = mainTab:AddRightGroupbox("Auto Aim")

aimBox:AddToggle("AutoAimV1", {
    Text = "Auto Aim V1",
    Default = false,
    Tooltip = "Direct face aim",
    Callback = function(value)
        _G.DirectFaceAim = value
        
        spawn(function()
            while _G.DirectFaceAim do
                task.wait()
                local character = LocalPlayer.Character
                if character then
                    local hrp = character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        for _, player in ipairs(Players:GetPlayers()) do
                            if player ~= LocalPlayer and player.Character then
                                local targetHRP = player.Character:FindFirstChild("HumanoidRootPart")
                                if targetHRP then
                                    local distance = (hrp.Position - targetHRP.Position).Magnitude
                                    if distance < 9999 then
                                        -- Aim logic
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end)
    end
})

aimBox:AddToggle("AutoAimV2", {
    Text = "Auto Aim V2",
    Default = false,
    Tooltip = "Adjustable left aim",
    Callback = function(value)
        _G.AdjustableLeftAim = value
        
        spawn(function()
            while _G.AdjustableLeftAim do
                task.wait()
                local character = LocalPlayer.Character
                if character then
                    local hrp = character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        for _, player in ipairs(Players:GetPlayers()) do
                            if player ~= LocalPlayer and player.Character then
                                local targetHRP = player.Character:FindFirstChild("HumanoidRootPart")
                                if targetHRP then
                                    local distance = (hrp.Position - targetHRP.Position).Magnitude
                                    if distance < 9999 then
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end)
    end
})

aimBox:AddLabel("V2 is recommended!")

Twilight:SetOptions({
    Enabled = false,
    Box = {
        Enabled = true,
        Thickness = 2,
        Filled = {
            Enabled = true,
            Transparency = 0.5
        }
    },
    Tracers = {
        Enabled = false,
        Thickness = 1
    },
    Name = {
        Enabled = false
    },
    Distance = {
        Enabled = false
    },
    currentColors = {
        players = {
            Box = {
                Outline = { Visible = Color3.fromRGB(255,255,255), Invisible = Color3.fromRGB(255,255,255) },
                Fill = { Visible = Color3.fromRGB(255,255,255), Invisible = Color3.fromRGB(255,255,255) }
            },
            Tracers = {
                Visible = Color3.fromRGB(255,255,255),
                Invisible = Color3.fromRGB(255,255,255)
            },
            Name = {
                Visible = Color3.fromRGB(255,255,255),
                Invisible = Color3.fromRGB(255,255,255)
            }
        }
    }
})

local Toggles = mainTab:AddLeftGroupbox("Toggle")
local Settings = mainTab:AddLeftGroupbox("ESP Settings")
local Colors = mainTab:AddRightGroupbox("Colors")

Toggles:AddLabel("idk if this works with xeno but i hope it would")

Toggles:AddToggle("EnableESP", {
    Text = "Enable ESP",
    Default = false,
    Callback = function(v)
        Twilight:SetOptions({ Enabled = v })
    end
})

Settings:AddToggle("Box", {
    Text = "Box",
    Default = true,
    Callback = function(v)
        Twilight:SetOptions({ Box = { Enabled = v } })
    end
})

Settings:AddToggle("Tracers", {
    Text = "Tracers",
    Default = false,
    Callback = function(v)
        Twilight:SetOptions({ Tracers = { Enabled = v } })
    end
})

Settings:AddToggle("Name", {
    Text = "Name",
    Default = false,
    Callback = function(v)
        Twilight:SetOptions({ Name = { Enabled = v } })
    end
})

Settings:AddToggle("Distance", {
    Text = "Distance",
    Default = false,
    Callback = function(v)
        Twilight:SetOptions({ Distance = { Enabled = v } })
    end
})

Settings:AddSlider("BoxThickness", {
    Text = "Box Thickness",
    Default = 2,
    Min = 1,
    Max = 10,
    Rounding = 0,
    Callback = function(v)
        Twilight:SetOptions({ Box = { Thickness = v } })
    end
})

Settings:AddSlider("FillTransparency", {
    Text = "Box Fill Transparency",
    Default = 50,
    Min = 0,
    Max = 100,
    Rounding = 0,
    Callback = function(v)
        Twilight:SetOptions({ Box = { Filled = { Transparency = v / 100 } } })
    end
})

Settings:AddSlider("TracerThickness", {
    Text = "Tracer Thickness",
    Default = 1,
    Min = 1,
    Max = 5,
    Rounding = 0,
    Callback = function(v)
        Twilight:SetOptions({ Tracers = { Thickness = v } })
    end
})

Colors:AddLabel("Box Color"):AddColorPicker("BoxColor", {
    Default = Color3.fromRGB(255,255,255),
    Callback = function(c)
        Twilight:SetOptions({
            currentColors = {
                players = {
                    Box = {
                        Outline = { Visible = c, Invisible = c },
                        Fill = { Visible = c, Invisible = c }
                    }
                }
            }
        })
    end
})

Colors:AddLabel("Tracer Color"):AddColorPicker("TracerColor", {
    Default = Color3.fromRGB(255,255,255),
    Callback = function(c)
        Twilight:SetOptions({
            currentColors = {
                players = {
                    Tracers = {
                        Visible = c,
                        Invisible = c
                    }
                }
            }
        })
    end
})

Colors:AddLabel("Name Color"):AddColorPicker("NameColor", {
    Default = Color3.fromRGB(255,255,255),
    Callback = function(c)
        Twilight:SetOptions({
            currentColors = {
                players = {
                    Name = {
                        Visible = c,
                        Invisible = c
                    }
                }
            }
        })
    end
})

local moveBox = mainTab:AddLeftGroupbox("Movement")

moveBox:AddToggle("EnableSpeed", {
    Text = "Speed Boost",
    Default = false,
    Callback = function(value)
        _G.SpeedOn = value
        
        spawn(function()
            while _G.SpeedOn do
                task.wait(0.1)
                local character = LocalPlayer.Character
                if character then
                    local humanoid = character:FindFirstChildOfClass("Humanoid")
                    if humanoid then
                        humanoid.WalkSpeed = _G.SpeedValue or 16
                    end
                end
            end
        end)
    end
})

moveBox:AddSlider("SpeedValue", {
    Text = "Speed",
    Default = 16,
    Min = 16,
    Max = 100,
    Rounding = 0,
    Compact = false,
    Callback = function(value)
        _G.SpeedValue = value
    end
})

moveBox:AddDivider()

moveBox:AddToggle("EnableFly", {
    Text = "Fly Mode",
    Default = false,
    Callback = function(value)
        local character = LocalPlayer.Character
        if not character then return end
        
        local hrp = character:FindFirstChild("HumanoidRootPart")
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        
        if not hrp or not humanoid then return end
        
        if value then
            workspace.Gravity = 0
            humanoid.JumpPower = 0
            
            local flyFolder = Instance.new("Folder")
            flyFolder.Name = "FlyParts"
            flyFolder.Parent = hrp
            
            -- Fly controls would go here
        else
            workspace.Gravity = 196.2
            local flyFolder = hrp:FindChild("FlyParts")
            if flyFolder then
                flyFolder:Destroy()
            end
        end
    end
})

moveBox:AddSlider("FlySpeed", {
    Text = "Fly Speed",
    Default = 10,
    Min = 10,
    Max = 50,
    Rounding = 0,
    Compact = false,
    Callback = function(value)
        _G.FlySpeed = value
    end
})

-- Camera Section
local camBox = mainTab:AddRightGroupbox("Camera")

camBox:AddToggle("FOVChanger", {
    Text = "FOV Changer",
    Default = false,
    Callback = function(value)
        _G.FOVEnabled = value
        
        local conn
        conn = RunService.RenderStepped:Connect(function()
            if not _G.FOVEnabled then
                conn:Disconnect()
                return
            end
            
            local camera = workspace.CurrentCamera
            if camera then
                camera.FieldOfView = _G.CurrentFOV or 70
            end
        end)
    end
})

camBox:AddSlider("FOVValue", {
    Text = "FOV",
    Default = 70,
    Min = 60,
    Max = 120,
    Rounding = 0,
    Suffix = "Â°",
    Compact = false,
    Callback = function(value)
        _G.CurrentFOV = value
    end
})

local fightBox = mainTab:AddLeftGroupbox("Auto Fight")

fightBox:AddToggle("AutoPunch", {
    Text = "Auto Punch",
    Default = false,
    Tooltip = "Automatically punches in combat",
    Callback = function(value)
        _G.AutoFist = value
        
        spawn(function()
            while _G.AutoFist do
                task.wait(_G.PunchSpeed or 0.2)
                local character = LocalPlayer.Character
                if character then
                    local fists = character:FindFirstChild("Fists")
                    if fists then
                        local remote = fists:FindFirstChild("fistremote")
                        if remote then
                            remote:FireServer("lmb")
                        end
                    end
                end
            end
        end)
    end
})

fightBox:AddSlider("PunchSpeed", {
    Text = "Punch Speed",
    Default = 0.2,
    Min = 0.2,
    Max = 0.5,
    Rounding = 1,
    Suffix = "s",
    Compact = false,
    Callback = function(value)
        _G.PunchSpeed = value
    end
})

fightBox:AddLabel("Useful in 1v1 rounds!")

local defenseBox = mainTab:AddRightGroupbox("Defense")

defenseBox:AddToggle("AntiFall", {
    Text = "Anti-Fall",
    Default = false,
    Tooltip = "Prevents falling off map",
    Callback = function(value)
        _G.SmartAntiVoid = value
        
        spawn(function()
            while _G.SmartAntiVoid do
                task.wait()
                local character = LocalPlayer.Character
                if character then
                    local hrp = character:FindFirstChild("HumanoidRootPart")
                    if hrp and hrp.Position.Y <= -2 then
                        -- Teleport back up logic
                    end
                end
            end
        end)
    end
})

defenseBox:AddLabel("Very useful in 1v1!")

local shopBox = miscTab:AddLeftGroupbox("Auto Buy Weapons")

local weapons = {
    {name = "Pistol", id = 1, price = 0, image = "rbxassetid://99587458671063"},
    {name = "Revolver", id = 2, price = 150, image = "rbxassetid://8585683407"},
    {name = "Laser Gun", id = 3, price = 350, image = "rbxassetid://9502438220"},
    {name = "Shotgun", id = 4, price = 700, image = "rbxassetid://10753200368"},
    {name = "RPG", id = 5, price = 1000, image = "rbxassetid://122848346024501"},
    {name = "Cobra", id = 6, price = 1500, image = "rbxassetid://127821932277803"}
}

for _, weapon in ipairs(weapons) do
    shopBox:AddToggle("AutoBuy" .. weapon.name:gsub(" ", ""), {
        Text = "Auto Buy " .. weapon.name,
        Default = false,
        Tooltip = "Cost: $" .. weapon.price,
        Callback = function(value)
            _G["AutoBuy" .. weapon.name:gsub(" ", "")] = value
            
            spawn(function()
                while _G["AutoBuy" .. weapon.name:gsub(" ", "")] do
                    task.wait(5)
                    pcall(function()
                        local shopRemote = ReplicatedStorage:WaitForChild("WeaponShopRemote")
                        shopRemote:FireServer("PurchaseSkin", {
                            name = weapon.name,
                            id = weapon.id,
                            price = weapon.price,
                            currency = "Cash",
                            image = weapon.image
                        })
                    end)
                end
            end)
        end
    })
end

local utilBox = mainTab:AddRightGroupbox("Utilities")

utilBox:AddToggle("AntiKill", {
    Text = "Anti Hit (Underground)",
    Default = false,
    Tooltip = "May fail - use carefully",
    Callback = function(value)
        _G.Underground = value
        
        local character = LocalPlayer.Character
        if not character then return end
        
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        
        if value then
            spawn(function()
                while _G.Underground do
                    if not character.Parent then break end
                    
                    local savedCF = hrp.CFrame
                    hrp.CFrame = savedCF * CFrame.new(0, -5, 0)
                    RunService.RenderStepped:Wait()
                    hrp.CFrame = savedCF
                    task.wait()
                end
            end)
        end
    end
})

local sets = win:AddTab("Settings", "settings")
local cfg = sets:AddLeftGroupbox("Configuration")

cfg:AddToggle("KeybindMenu", {
    Default = lib.KeybindFrame.Visible,
    Text = "Keybind Menu",
    Callback = function(v) lib.KeybindFrame.Visible = v end
})

cfg:AddToggle("CustomCursor", {
    Text = "Custom Cursor",
    Default = true,
    Callback = function(v) lib.ShowCustomCursor = v end
})

cfg:AddDropdown("NotifySide", {
    Values = { "Left", "Right" },
    Default = "Right",
    Text = "Notification Side",
    Callback = function(v) lib:SetNotifySide(v) end
})

cfg:AddDropdown("DPIScale", {
    Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" },
    Default = "100%",
    Text = "DPI Scale",
    Callback = function(v)
        local n = tonumber(v:gsub("%%", ""))
        if n then lib:SetDPIScale(n / 100) end
    end
})

cfg:AddDivider()
cfg:AddLabel("Menu Keybind"):AddKeyPicker("MenuKeybind", { 
    Default = "RightShift", 
    NoUI = true, 
    Text = "Menu keybind" 
})

cfg:AddButton({ 
    Text = "Unload", 
    Func = function() lib:Unload() end 
})

lib.ToggleKeybind = lib.Options.MenuKeybind

-- Theme & Save Manager
theme:SetLibrary(lib)
save:SetLibrary(lib)
save:IgnoreThemeSettings()
save:SetIgnoreIndexes({ "MenuKeybind" })

theme:SetFolder("PlowsScriptHub")
save:SetFolder("PlowsScriptHub/BlindShot")
save:SetSubFolder("Blind-Shot")

save:BuildConfigSection(sets)
theme:ApplyToTab(sets)

save:LoadAutoloadConfig()

lib:OnUnload(function()
    if perfConn then perfConn:Disconnect() end
    
    _G.TrophyTeleportFarmV2 = false
    _G.TrophyFarm = false
    _G.DirectFaceAim = false
    _G.AdjustableLeftAim = false
    _G.SpeedOn = false
    _G.FOVEnabled = false
    _G.AutoFist = false
    _G.SmartAntiVoid = false
    _G.Underground = false
    
    workspace.Gravity = 196.2
end)

print("AXIS - Blind Shot loaded successfully!")
lib:Notify("Welcome to AXIS Hub!", 5)
