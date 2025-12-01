local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/"

local libraryLoadSuccess, libraryLoadResult = pcall(function()
    return loadstring(game:HttpGet(repo .. "Library.lua"))()
end)

if not libraryLoadSuccess or typeof(libraryLoadResult) ~= "table" then
    return
end
local Library = libraryLoadResult

local themeLoadSuccess, themeLoadResult = pcall(function()
    return loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
end)
local ThemeManager = (themeLoadSuccess and typeof(themeLoadResult) == "table") and themeLoadResult or { SetLibrary = function() end, SetFolder = function() end, ApplyToTab = function() end }

local saveLoadSuccess, saveLoadResult = pcall(function()
    return loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()
end)
local SaveManager = (saveLoadSuccess and typeof(saveLoadResult) == "table") and saveLoadResult or { SetLibrary = function() end, SetFolder = function() end, SetSubFolder = function() end, SetIgnoreIndexes = function() end, IgnoreThemeSettings = function() end, BuildConfigSection = function() end, LoadAutoloadConfig = function() end }

local Options = Library.Options
local Toggles = Library.Toggles

local mainWindow = Library:CreateWindow({
    Title = "Plow's Volleyball \nLegends Script",
    Footer = "v1.2.2",
    NotifySide = "Right",
    ShowCustomCursor = false,
})

local homeTab = mainWindow:AddTab("Home", "house")
local mainTab = mainWindow:AddTab("Main", "volleyball")
local settingsTab = mainWindow:AddTab("Settings", "settings")

local homeGroup = homeTab:AddLeftGroupbox("Information")
local hitboxGroup = mainTab:AddLeftGroupbox("Hitbox System")
local predictionGroup = mainTab:AddRightGroupbox("Ball Prediction")
local settingsGroup = settingsTab:AddLeftGroupbox("Menu Settings")

local hitboxSize = 20
local hitboxTransparency = 0.6
local hitboxEnabled = false
local hitboxUpdateLoop = nil
local ballSpawnListener = nil
local trackedBalls = {}
local predictionEnabled = false
local predictionMarker = nil
local predictionUpdateLoop = nil

local function isBallObject(name)
    local lowerName = name:lower()
    return lowerName:find("client_ball") or lowerName:find("volleyball") or lowerName == "ball"
end

local function makeBallVisible(actualBall)
    if trackedBalls[actualBall] and trackedBalls[actualBall].Parent then return end

    local visibleBall = Instance.new("Part")
    visibleBall.Name = "VisibleBall"
    visibleBall.Size = Vector3.new(2, 2, 2)
    visibleBall.Shape = Enum.PartType.Ball
    visibleBall.Color = actualBall.Color
    visibleBall.Material = Enum.Material.Plastic
    visibleBall.CanCollide = false
    visibleBall.CanTouch = false
    visibleBall.Anchored = false
    visibleBall.Massless = true
    
    if actualBall:IsA("MeshPart") then
        visibleBall.Color = actualBall.Color
    end
    
    local connector = Instance.new("WeldConstraint")
    connector.Part0 = actualBall
    connector.Part1 = visibleBall
    connector.Parent = visibleBall
    
    visibleBall.CFrame = actualBall.CFrame
    visibleBall.Parent = actualBall.Parent
    
    trackedBalls[actualBall] = visibleBall
end

local function updateBallProperties(ballPart)
    if ballPart:IsA("BasePart") then
        makeBallVisible(ballPart)
        
        if math.abs(ballPart.Size.X - hitboxSize) > 0.5 then
            ballPart.Size = Vector3.new(hitboxSize, hitboxSize, hitboxSize)
        end
        
        ballPart.Transparency = hitboxTransparency
        ballPart.Material = Enum.Material.ForceField
        ballPart.CanCollide = false
        ballPart.Massless = true
    end
end

local function checkAndModifyObject(object)
    if not object then return end
    
    if isBallObject(object.Name) then
        if object:IsA("Model") then
            for _, child in ipairs(object:GetChildren()) do
                updateBallProperties(child)
            end
            object.ChildAdded:Connect(function(newChild)
                task.wait()
                updateBallProperties(newChild)
            end)
        elseif object:IsA("BasePart") then
            updateBallProperties(object)
        end
    end
end

hitboxGroup:AddToggle("EnableHitbox", {
    Text = "Enable Hitbox Expander",
    Default = false,
    Callback = function(Value)
        hitboxEnabled = Value
        
        if Value then
            for _, child in ipairs(workspace:GetChildren()) do
                checkAndModifyObject(child)
            end
            
            if ballSpawnListener then ballSpawnListener:Disconnect() end
            ballSpawnListener = workspace.ChildAdded:Connect(function(child)
                if hitboxEnabled then
                    checkAndModifyObject(child)
                end
            end)

            if hitboxUpdateLoop then task.cancel(hitboxUpdateLoop) end
            hitboxUpdateLoop = task.spawn(function()
                while hitboxEnabled and not Library.Unloaded do
                    for actualBall, visibleVersion in pairs(trackedBalls) do
                        if actualBall and actualBall.Parent then
                            if math.abs(actualBall.Size.X - hitboxSize) > 0.5 then
                                actualBall.Size = Vector3.new(hitboxSize, hitboxSize, hitboxSize)
                            end
                            
                            actualBall.Transparency = hitboxTransparency
                            actualBall.Material = Enum.Material.ForceField
                            actualBall.CanCollide = false
                            
                            if visibleVersion and visibleVersion.Parent then
                                visibleVersion.Size = Vector3.new(1.8, 1.8, 1.8)
                                visibleVersion.Transparency = 0
                                visibleVersion.Material = Enum.Material.Plastic
                                visibleVersion.Color = Color3.fromRGB(255, 255, 255)
                            end
                        else
                            if visibleVersion then visibleVersion:Destroy() end
                            trackedBalls[actualBall] = nil
                        end
                    end
                    task.wait(0.5)
                end
            end)
        else
            if ballSpawnListener then ballSpawnListener:Disconnect() end
            if hitboxUpdateLoop then task.cancel(hitboxUpdateLoop) end
            
            for actualBall, visibleVersion in pairs(trackedBalls) do
                if actualBall and actualBall.Parent then
                    actualBall.Size = Vector3.new(2.06, 2.06, 2.06)
                    actualBall.Transparency = 0
                    actualBall.Material = Enum.Material.Plastic
                    actualBall.CanCollide = true
                    actualBall.Massless = false
                end
                if visibleVersion then
                    visibleVersion:Destroy()
                end
            end
            trackedBalls = {}
        end
    end
})

hitboxGroup:AddSlider("HitboxSize", {
    Text = "Hitbox Size",
    Default = 20,
    Min = 5,
    Max = 50,
    Rounding = 0,
    Callback = function(Value)
        hitboxSize = Value
        if hitboxEnabled then
            for actualBall, _ in pairs(trackedBalls) do
                if actualBall and actualBall.Parent then
                    actualBall.Size = Vector3.new(hitboxSize, hitboxSize, hitboxSize)
                end
            end
        end
    end
})

hitboxGroup:AddSlider("HitboxTransparency", {
    Text = "Hitbox Transparency",
    Default = 0.6,
    Min = 0,
    Max = 1,
    Rounding = 1,
    Callback = function(Value)
        hitboxTransparency = Value
        if hitboxEnabled then
            for actualBall, _ in pairs(trackedBalls) do
                if actualBall and actualBall.Parent then
                    actualBall.Transparency = hitboxTransparency
                end
            end
        end
    end
})

predictionGroup:AddToggle("EnablePrediction", {
    Text = "Ball Trajectory Prediction",
    Default = false,
    Callback = function(Value)
        predictionEnabled = Value
        
        if Value then
            if predictionUpdateLoop then task.cancel(predictionUpdateLoop) end
            
            if not predictionMarker then
                predictionMarker = Instance.new("Part")
                predictionMarker.Name = "BallPathMarker"
                predictionMarker.Size = Vector3.new(2, 2, 2)
                predictionMarker.Shape = Enum.PartType.Ball
                predictionMarker.Color = Color3.fromRGB(255, 0, 0)
                predictionMarker.Material = Enum.Material.Neon
                predictionMarker.Transparency = 0.3
                predictionMarker.CanCollide = false
                predictionMarker.Anchored = true
                predictionMarker.Parent = workspace
            end
            
            predictionUpdateLoop = task.spawn(function()
                while predictionEnabled and not Library.Unloaded do
                    local currentBall = nil
                    
                    for _, object in ipairs(workspace:GetChildren()) do
                        if isBallObject(object.Name) then
                            if object:IsA("BasePart") then
                                currentBall = object
                                break
                            elseif object:IsA("Model") then
                                for _, child in ipairs(object:GetChildren()) do
                                    if child:IsA("BasePart") then
                                        currentBall = child
                                        break
                                    end
                                end
                            end
                        end
                        if currentBall then break end
                    end
                    
                    if currentBall and predictionMarker then
                        local ballSpeed = currentBall.AssemblyLinearVelocity
                        local ballPosition = currentBall.Position
                        
                        predictionMarker.Position = ballPosition + (ballSpeed * 0.5) + Vector3.new(0, -4.9 * 0.25, 0)
                        
                        local estimatedLanding = ballPosition + (ballSpeed * 1.0) + Vector3.new(0, -4.9 * 1.0, 0)
                        
                        local pathLine = predictionMarker:FindFirstChild("PathLine")
                        if not pathLine then
                            pathLine = Instance.new("Beam")
                            pathLine.Name = "PathLine"
                            pathLine.Color = ColorSequence.new(Color3.fromRGB(255, 0, 0))
                            pathLine.Width0 = 0.2
                            pathLine.Width1 = 0.2
                            pathLine.Attachment0 = Instance.new("Attachment")
                            pathLine.Attachment0.Parent = predictionMarker
                            pathLine.Attachment1 = Instance.new("Attachment")
                            pathLine.Attachment1.Position = estimatedLanding - ballPosition
                            pathLine.Attachment1.Parent = predictionMarker
                            pathLine.Parent = predictionMarker
                        else
                            pathLine.Attachment1.Position = estimatedLanding - ballPosition
                        end
                    end
                    
                    task.wait(0.1)
                end
                
                if predictionMarker then
                    predictionMarker:Destroy()
                    predictionMarker = nil
                end
            end)
        else
            if predictionUpdateLoop then task.cancel(predictionUpdateLoop) end
            if predictionMarker then
                predictionMarker:Destroy()
                predictionMarker = nil
            end
        end
    end
})

predictionGroup:AddLabel("Shows where the ball is headed", true)
predictionGroup:AddLabel("and where it might land", true)

local LocalPlayer = game.Players.LocalPlayer
local displayName = LocalPlayer and LocalPlayer.DisplayName or "Player"
local currentTime = os.date("%A, %B %d, %Y %I:%M %p", os.time())
local welcomeLabelText = string.format("Welcome, %s\nCurrent time: %s\nPlaying: Volleyball Legends", displayName, currentTime)

homeGroup:AddLabel(welcomeLabelText, true)

homeGroup:AddButton({
    Text = "Unload Script",
    Func = function()
        Library:Unload()
    end
})

settingsGroup:AddToggle("KeybindMenuOpen", {
    Default = Library.KeybindFrame.Visible,
    Text = "Open Keybind Menu",
    Callback = function(value)
        Library.KeybindFrame.Visible = value
    end
})

settingsGroup:AddToggle("ShowCustomCursor", {
    Text = "Custom Cursor",
    Default = false,
    Callback = function(Value)
        Library.ShowCustomCursor = Value
    end
})

settingsGroup:AddDropdown("NotificationSide", {
    Values = { "Left", "Right" },
    Default = "Right",
    Text = "Notification Side",
    Callback = function(Value)
        Library:SetNotifySide(Value)
    end
})

settingsGroup:AddLabel("Menu Keybind"):AddKeyPicker("MenuKeybind", {
    Default = "RightShift",
    NoUI = true,
    Text = "Menu keybind"
})

Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
ThemeManager:SetFolder("PlowsScriptHub")
SaveManager:SetFolder("PlowsScriptHub/VolleyballLegends")
SaveManager:SetSubFolder("universal")
SaveManager:BuildConfigSection(settingsTab)
ThemeManager:ApplyToTab(settingsTab)
SaveManager:LoadAutoloadConfig()

task.spawn(function()
    task.wait(2)
    pcall(function()
        local Players = game:GetService("Players")
        local player = Players.LocalPlayer
        if player then
            player.CameraMaxZoomDistance = 100
            player.CameraMinZoomDistance = 0.5
            player.CameraMode = Enum.CameraMode.Classic
        end
    end)
end)

Library:OnUnload(function()
    if ballSpawnListener then ballSpawnListener:Disconnect() end
    if hitboxUpdateLoop then task.cancel(hitboxUpdateLoop) end
    if predictionUpdateLoop then task.cancel(predictionUpdateLoop) end
    
    for actualBall, visibleVersion in pairs(trackedBalls) do
        if actualBall and actualBall.Parent then
            actualBall.Size = Vector3.new(2.06, 2.06, 2.06)
            actualBall.Transparency = 0
            actualBall.Material = Enum.Material.Plastic
            actualBall.CanCollide = true
            actualBall.Massless = false
        end
        if visibleVersion then
            visibleVersion:Destroy()
        end
    end
    
    if predictionMarker then
        predictionMarker:Destroy()
    end
end)
