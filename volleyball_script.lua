local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/"

local libSuccess, libResult = pcall(function()
    return loadstring(game:HttpGet(repo .. "Library.lua"))()
end)

if not libSuccess or typeof(libResult) ~= "table" then
    return
end
local Library = libResult

local themeSuccess, themeResult = pcall(function()
    return loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
end)
local ThemeManager = (themeSuccess and typeof(themeResult) == "table") and themeResult or { SetLibrary = function() end, SetFolder = function() end, ApplyToTab = function() end }

local saveSuccess, saveResult = pcall(function()
    return loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()
end)
local SaveManager = (saveSuccess and typeof(saveResult) == "table") and saveResult or { SetLibrary = function() end, SetFolder = function() end, SetSubFolder = function() end, SetIgnoreIndexes = function() end, IgnoreThemeSettings = function() end, BuildConfigSection = function() end, LoadAutoloadConfig = function() end }

local Options = Library.Options
local Toggles = Library.Toggles

local mainWindow = Library:CreateWindow({
    Title = "Volleyball Legends\nPrivate Script",
    Footer = "Small Update v1.0.1",
    NotifySide = "Right",
    ShowCustomCursor = true,
})

local homeTab = mainWindow:AddTab({ Name = "Home", Icon = "house", Description = "Information" })
local hitboxTab = mainWindow:AddTab({ Name = "Hitbox Expander", Icon = "expand", Description = "Modify ball hitboxes" })
local mainTab = mainWindow:AddTab({ Name = "Main", Icon = "trophy", Description = "Game Features" })
local settingsTab = mainWindow:AddTab({ Name = "Settings", Icon = "settings", Description = "UI Settings" })

local homeGroup = homeTab:AddGroupbox({ Name = "Information" })
local hitboxGroup = hitboxTab:AddGroupbox({ Name = "Configuration" })
local mainGroup = mainTab:AddGroupbox({ Name = "Gameplay" })
local settingsGroup = settingsTab:AddGroupbox({ Name = "Menu Settings" })

local HitboxSize = 20
local HitboxTransparency = 0.6
local HitboxEnabled = false
local BypassEnabled = true
local EnforceLoop = nil
local SpawnConnection = nil
local ProcessedBalls = {}

local function CheckName(name)
    local n = name:lower()
    return n:find("client_ball") or n:find("volleyball") or n == "ball"
end

local function GetOriginalBallProperties(ball)
    return {
        Size = Vector3.new(2.06, 2.06, 2.06),
        Transparency = 0,
        CanCollide = true,
        Material = Enum.Material.Plastic
    }
end

local __index
pcall(function()
    if hookmetamethod and newcclosure and checkcaller then
        __index = hookmetamethod(game, "__index", newcclosure(function(self, key)
            if BypassEnabled and not checkcaller() and self:IsA("BasePart") then
                if CheckName(self.Name) then
                    local fakeProps = GetOriginalBallProperties(self)
                    if key == "Size" then return fakeProps.Size end
                    if key == "Transparency" then return fakeProps.Transparency end
                    if key == "CanCollide" then return fakeProps.CanCollide end
                    if key == "Material" then return fakeProps.Material end
                end
            end
            return __index(self, key)
        end))
    end
end)

local function CreateVisualClone(realBall)
    if ProcessedBalls[realBall] and ProcessedBalls[realBall].Parent then return end

    local visual = Instance.new("Part")
    visual.Name = "VisualCore"
    visual.Size = Vector3.new(2, 2, 2)
    visual.Shape = Enum.PartType.Ball
    visual.Color = realBall.Color
    visual.Material = Enum.Material.Plastic
    visual.CanCollide = false
    visual.CanTouch = false
    visual.Anchored = false
    visual.Massless = true
    
    if realBall:IsA("MeshPart") then
        visual.Color = realBall.Color
    end
    
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = realBall
    weld.Part1 = visual
    weld.Parent = visual
    
    visual.CFrame = realBall.CFrame
    visual.Parent = realBall.Parent
    
    ProcessedBalls[realBall] = visual
end

local function ApplyHitboxAttributes(part)
    if part:IsA("BasePart") then
        CreateVisualClone(part)
        
        if math.abs(part.Size.X - HitboxSize) > 0.5 then
            part.Size = Vector3.new(HitboxSize, HitboxSize, HitboxSize)
        end
        
        part.Transparency = HitboxTransparency
        part.Material = Enum.Material.ForceField
        part.CanCollide = false
        part.Massless = true
    end
end

local function ProcessObject(obj)
    if not obj then return end
    
    if CheckName(obj.Name) then
        if obj:IsA("Model") then
            for _, child in ipairs(obj:GetChildren()) do
                ApplyHitboxAttributes(child)
            end
            obj.ChildAdded:Connect(function(c)
                task.wait()
                ApplyHitboxAttributes(c)
            end)
        elseif obj:IsA("BasePart") then
            ApplyHitboxAttributes(obj)
        end
    end
end

hitboxGroup:AddToggle("EnableHitbox", {
    Text = "Enable Hitbox Expander",
    Default = false,
    Callback = function(Value)
        HitboxEnabled = Value
        
        if Value then
            for _, child in ipairs(game.Workspace:GetChildren()) do
                ProcessObject(child)
            end
            
            if SpawnConnection then SpawnConnection:Disconnect() end
            SpawnConnection = game.Workspace.ChildAdded:Connect(function(child)
                if HitboxEnabled then
                    ProcessObject(child)
                end
            end)

            if EnforceLoop then task.cancel(EnforceLoop) end
            EnforceLoop = task.spawn(function()
                while HitboxEnabled and Library.Unloaded == false do
                    for realBall, visualBall in pairs(ProcessedBalls) do
                        if realBall and realBall.Parent then
                            if math.abs(realBall.Size.X - HitboxSize) > 0.5 then
                                realBall.Size = Vector3.new(HitboxSize, HitboxSize, HitboxSize)
                            end
                            
                            realBall.Transparency = HitboxTransparency
                            realBall.Material = Enum.Material.ForceField
                            realBall.CanCollide = false
                            
                            if visualBall and visualBall.Parent then
                                visualBall.Size = Vector3.new(1.8, 1.8, 1.8)
                                visualBall.Transparency = 0
                                visualBall.Material = Enum.Material.Plastic
                                visualBall.Color = Color3.fromRGB(255, 255, 255)
                            end
                        else
                            if visualBall then visualBall:Destroy() end
                            ProcessedBalls[realBall] = nil
                        end
                    end
                    task.wait(0.5)
                end
            end)
        else
            if SpawnConnection then SpawnConnection:Disconnect() end
            if EnforceLoop then task.cancel(EnforceLoop) end
        end
    end,
})

hitboxGroup:AddToggle("EnableBypass", {
    Text = "Safe Mode (Ghost Bypass)",
    Default = true,
    Tooltip = "Spoofs Size, Transparency, and Collision to game scripts",
    Callback = function(Value)
        BypassEnabled = Value
    end,
})

hitboxGroup:AddSlider("HitboxSize", {
    Text = "Hitbox Size",
    Default = 20,
    Min = 5,
    Max = 50,
    Step = 1,
    Rounding = 0,
    Callback = function(Value)
        HitboxSize = Value
        if HitboxEnabled then
            for realBall, _ in pairs(ProcessedBalls) do
                if realBall and realBall.Parent then
                    realBall.Size = Vector3.new(HitboxSize, HitboxSize, HitboxSize)
                end
            end
        end
    end,
})

hitboxGroup:AddSlider("HitboxTransparency", {
    Text = "Hitbox Transparency",
    Default = 0.6,
    Min = 0,
    Max = 1,
    Step = 0.1,
    Rounding = 1,
    Callback = function(Value)
        HitboxTransparency = Value
        if HitboxEnabled then
            for realBall, _ in pairs(ProcessedBalls) do
                if realBall and realBall.Parent then
                    realBall.Transparency = HitboxTransparency
                end
            end
        end
    end,
})

local LocalPlayer = game.Players.LocalPlayer
local DisplayName = LocalPlayer and LocalPlayer.DisplayName or "Player"
homeGroup:AddLabel("Welcome, " .. DisplayName)
homeGroup:AddLabel("Game: Volleyball Legends")
homeGroup:AddButton({ Text = "Unload Script", Func = function() Library:Unload() end })

settingsGroup:AddToggle("KeybindMenuOpen", { Default = Library.KeybindFrame.Visible, Text = "Open Keybind Menu", Callback = function(value) Library.KeybindFrame.Visible = value end })
settingsGroup:AddToggle("ShowCustomCursor", { Text = "Custom Cursor", Default = true, Callback = function(Value) Library.ShowCustomCursor = Value end })
settingsGroup:AddDropdown("NotificationSide", { Values = { "Left", "Right" }, Default = "Right", Text = "Notification Side", Callback = function(Value) Library:SetNotifySide(Value) end })
settingsGroup:AddLabel("Menu Keybind"):AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })

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

Library:OnUnload(function()
    if SpawnConnection then SpawnConnection:Disconnect() end
    if EnforceLoop then task.cancel(EnforceLoop) end
    for _, visual in pairs(ProcessedBalls) do
        if visual then visual:Destroy() end
    end
end)

Library:Load()
