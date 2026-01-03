local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/"
local lib = loadstring(game:HttpGet(repo .. "Library.lua"))()
local theme = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local save = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local rs = game:GetService("RunService")
local plrs = game:GetService("Players")
local lp = plrs.LocalPlayer

local function get(name)
    local s = game:GetService(name)
    if not s then return nil end
    if cloneref then
        local ok, res = pcall(cloneref, s)
        return ok and res or s
    end
    return s
end

local Toggles = lib.Toggles
local Options = lib.Options

local state = {
    grid = {},
    w = 0, h = 0,
    parts = -1,
    numbered = {},
    safe = {},
    mines = {},
    guess = nil,
    highlights = {}
}

local function bypass()
    if not getrawmetatable or not hookmetamethod then return end
    local remote = game:GetService("ReplicatedStorage"):FindFirstChild("Patukka")
    if remote then
        local old
        old = hookmetamethod(game, "__namecall", function(self, ...)
            local m = getnamecallmethod()
            if self == remote and (m == "InvokeServer" or m == "FireServer") then
                if Toggles.BypassAnticheat and Toggles.BypassAnticheat.Value then
                    return nil
                end
            end
            return old(self, ...)
        end)
    end
end

local function cluster(vals, max)
    local c = {}
    if #vals == 0 then return c end
    local cur, count = vals[1], 1
    for i = 2, #vals do
        if math.abs(vals[i] - cur) <= max then
            count = count + 1
            cur = cur + (vals[i] - cur) / count
        else
            table.insert(c, cur)
            cur, count = vals[i], 1
        end
    end
    table.insert(c, cur)
    return c
end

local function rebuild(folder)
    state.grid = {}
    state.w, state.h = 0, 0
    state.safe = {}
    state.mines = {}
    state.guess = nil
    local p = folder:GetChildren()
    if #p == 0 then return end
    local xs, zs, pos = {}, {}, {}
    local sy = 0
    for _, v in ipairs(p) do
        if v:IsA("BasePart") then
            local p3 = v.Position
            table.insert(pos, {v = v, p = p3})
            table.insert(xs, p3.X)
            table.insert(zs, p3.Z)
            sy = sy + p3.Y
        end
    end
    if #pos == 0 then return end
    table.sort(xs)
    table.sort(zs)
    local function getSpc(t)
        if #t < 3 then return 4 end
        local d = {}
        for i = 2, #t do table.insert(d, math.abs(t[i]-t[i-1])) end
        table.sort(d)
        return d[math.floor((#d+1)/2)]
    end
    local wx, wz = getSpc(xs) * 0.6, getSpc(zs) * 0.6
    local ux = cluster(xs, wx)
    local uz = cluster(zs, wz)
    state.w, state.h = #ux, #uz
    if state.w == 0 or state.h == 0 then return end
    local ay = sy / #pos
    for x = 0, state.w - 1 do
        state.grid[x] = {}
        for z = 0, state.h - 1 do
            state.grid[x][z] = {
                ix = x, iz = z,
                p = Vector3.new(ux[x+1], ay, uz[z+1]),
                part = nil, st = "unknown",
                num = nil, cov = true,
                neigh = {}
            }
        end
    end
    for _, d in ipairs(pos) do
        local xI, zI = 0, 0
        local dist = 1000000
        for i, val in ipairs(ux) do
            local d2 = math.abs(d.p.X - val)
            if d2 < dist then dist = d2 xI = i - 1 end
        end
        dist = 1000000
        for i, val in ipairs(uz) do
            local d2 = math.abs(d.p.Z - val)
            if d2 < dist then dist = d2 zI = i - 1 end
        end
        local c = state.grid[xI] and state.grid[xI][zI]
        if c then
            if not c.part or (d.p - c.p).Magnitude < (c.part.Position - c.p).Magnitude then
                c.part, c.p = d.v, d.p
            end
        end
    end
    for x = 0, state.w - 1 do
        for z = 0, state.h - 1 do
            local c = state.grid[x][z]
            for dx = -1, 1 do
                for dz = -1, 1 do
                    if dx == 0 and dz == 0 then continue end
                    local nx, nz = x + dx, z + dz
                    if nx >= 0 and nx < state.w and nz >= 0 and nz < state.h then
                        table.insert(c.neigh, state.grid[nx][nz])
                    end
                end
            end
        end
    end
end

local function updateStates()
    state.numbered = {}
    if state.w == 0 then return end
    for x = 0, state.w - 1 do
        for z = 0, state.h - 1 do
            local c = state.grid[x][z]
            if c and c.part then
                c.st, c.num, c.cov = "unknown", nil, true
                local gui = c.part:FindFirstChild("NumberGui")
                if gui then
                    local lbl = gui:FindFirstChild("TextLabel")
                    if lbl and tonumber(lbl.Text) then
                        c.num = tonumber(lbl.Text)
                        c.cov = false
                        c.st = "number"
                        table.insert(state.numbered, c)
                    end
                end
                if not gui then
                    local col = c.part.Color
                    if col.R > 0.7 and col.G > 0.7 and col.B > 0.7 then
                        c.cov = false
                        c.st = "empty"
                    end
                end
                for _, child in ipairs(c.part:GetChildren()) do
                    if child.Name:sub(1, 4) == "Flag" then c.st = "flagged" break end
                end
            end
        end
    end
end

local function isUnknown(c)
    return c.cov and c.st ~= "flagged" and c.st ~= "number"
end

local function solve()
    state.mines = {}
    state.safe = {}
    if state.w == 0 or #state.numbered == 0 then return end
    local f, s = {}, {}
    
    local function getUnknowns(cell)
        local r = {}
        for _, nb in ipairs(cell.neigh) do
            if not f[nb] and not s[nb] and isUnknown(nb) then
                table.insert(r, nb)
            end
        end
        return r
    end
    
    local function getRemaining(cell)
        local rem = cell.num or 0
        for _, nb in ipairs(cell.neigh) do
            if f[nb] or nb.st == "flagged" then rem = rem - 1 end
        end
        return rem
    end
    
    local function setIntersection(a, b)
        local setA = {}
        for _, v in ipairs(a) do setA[v] = true end
        local inter, onlyA, onlyB = {}, {}, {}
        for _, v in ipairs(b) do
            if setA[v] then table.insert(inter, v) setA[v] = nil
            else table.insert(onlyB, v) end
        end
        for v in pairs(setA) do table.insert(onlyA, v) end
        return inter, onlyA, onlyB
    end
    
    local changed, iter = true, 0
    while changed and iter < 64 do
        changed = false
        iter = iter + 1
        
        for _, c in ipairs(state.numbered) do
            local u = getUnknowns(c)
            local rem = getRemaining(c)
            if rem > 0 and rem == #u then
                for _, v in ipairs(u) do if not f[v] then f[v] = true changed = true end end
            elseif rem == 0 and #u > 0 then
                for _, v in ipairs(u) do if not s[v] then s[v] = true changed = true end end
            end
        end
        
        for _, c in ipairs(state.numbered) do
            for _, n in ipairs(c.neigh) do
                if n.st == "number" then
                    local u1 = getUnknowns(c)
                    local u2 = getUnknowns(n)
                    if #u1 > 0 and #u2 > 0 then
                        local _, o1, o2 = setIntersection(u1, u2)
                        local r1 = getRemaining(c)
                        local r2 = getRemaining(n)
                        if #o1 == 0 and #o2 > 0 then
                            local d = r2 - r1
                            if d == 0 then
                                for _, v in ipairs(o2) do if not s[v] then s[v] = true changed = true end end
                            elseif d == #o2 then
                                for _, v in ipairs(o2) do if not f[v] then f[v] = true changed = true end end
                            end
                        elseif #o2 == 0 and #o1 > 0 then
                            local d = r1 - r2
                            if d == 0 then
                                for _, v in ipairs(o1) do if not s[v] then s[v] = true changed = true end end
                            elseif d == #o1 then
                                for _, v in ipairs(o1) do if not f[v] then f[v] = true changed = true end end
                            end
                        end
                    end
                end
            end
        end
        
        for _, c in ipairs(state.numbered) do
            if (c.num or 0) == 1 then
                for _, n in ipairs(c.neigh) do
                    if n.st == "number" and (n.num or 0) == 1 then
                        local u1 = getUnknowns(c)
                        local u2 = getUnknowns(n)
                        local inter, o1, o2 = setIntersection(u1, u2)
                        if #inter == 1 and #o1 == 1 and #o2 == 1 then
                            if not s[inter[1]] then s[inter[1]] = true changed = true end
                        end
                    end
                end
            end
        end
        
        for _, c in ipairs(state.numbered) do
            if (c.num or 0) == 1 then
                for _, n in ipairs(c.neigh) do
                    if n.st == "number" and (n.num or 0) == 2 then
                        local u1 = getUnknowns(c)
                        local u2 = getUnknowns(n)
                        local inter, o1, o2 = setIntersection(u1, u2)
                        if #inter >= 1 and #o1 == 0 and #o2 == 1 then
                            if not f[o2[1]] then f[o2[1]] = true changed = true end
                        end
                    end
                end
            end
        end
        
        for _, c in ipairs(state.numbered) do
            local isEdge = c.ix == 0 or c.ix == state.w - 1 or c.iz == 0 or c.iz == state.h - 1
            if isEdge then
                local u = getUnknowns(c)
                local rem = getRemaining(c)
                local edgeU = {}
                for _, v in ipairs(u) do
                    if v.ix == 0 or v.ix == state.w - 1 or v.iz == 0 or v.iz == state.h - 1 then
                        table.insert(edgeU, v)
                    end
                end
                if rem == #edgeU and #edgeU > 0 then
                    for _, v in ipairs(edgeU) do if not f[v] then f[v] = true changed = true end end
                    for _, v in ipairs(u) do
                        local found = false
                        for _, ev in ipairs(edgeU) do if v == ev then found = true break end end
                        if not found and not s[v] then s[v] = true changed = true end
                    end
                end
            end
        end
        
        for _, c in ipairs(state.numbered) do
            local isCorner = (c.ix == 0 or c.ix == state.w - 1) and (c.iz == 0 or c.iz == state.h - 1)
            if isCorner then
                local u = getUnknowns(c)
                local rem = getRemaining(c)
                if rem == #u and #u > 0 then
                    for _, v in ipairs(u) do if not f[v] then f[v] = true changed = true end end
                end
            end
        end
    end
    state.mines, state.safe = f, s
end

local function calcGuess()
    state.guess = nil
    if state.w == 0 then return end
    local fC, uC = 0, 0
    local allUnknown = {}
    for x = 0, state.w - 1 do
        for z = 0, state.h - 1 do
            local c = state.grid[x][z]
            if c.st == "flagged" or state.mines[c] then
                fC = fC + 1
            elseif not state.safe[c] and isUnknown(c) then
                uC = uC + 1
                table.insert(allUnknown, c)
            end
        end
    end
    if uC == 0 then return end
    local dens = uC > 0 and ((40 - fC) / uC) or 0
    local bC, bS = nil, 2
    for _, c in ipairs(allUnknown) do
        if c.part and not state.mines[c] and not state.safe[c] then
            local vC, pS = 0, 0
            for _, n in ipairs(c.neigh) do
                if n.st == "number" then
                    local fl, un = 0, 0
                    for _, nn in ipairs(n.neigh) do
                        if nn.st == "flagged" or state.mines[nn] then fl = fl+1
                        elseif isUnknown(nn) and not state.mines[nn] and not state.safe[nn] then un = un+1 end
                    end
                    local rem = (n.num or 0) - fl
                    if rem <= 0 then vC = vC + 1 elseif un > 0 then pS = pS + (rem/un) vC = vC + 1 end
                end
            end
            local score = 0.5 * (vC > 0 and (pS/vC) or dens) + 0.5 * dens
            if c.ix == 0 or c.ix == state.w-1 or c.iz == 0 or c.iz == state.h-1 then score = score + 0.05 end
            if not bS or score < bS then bS = score bC = c end
        end
    end
    if not bC and #allUnknown > 0 then
        bC = allUnknown[math.random(1, #allUnknown)]
    end
    state.guess = bC
end

local function createBorders(c)
    local th = 0.08
    local ins = 0.05
    local folder = workspace:FindFirstChild("MinesweeperHighlights")
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "MinesweeperHighlights"
        folder.Parent = workspace
    end

    local function newPart()
        local p = Instance.new("Part")
        p.Anchored = true
        p.CanCollide = false
        p.CanQuery = false
        p.CanTouch = false
        p.CastShadow = false
        p.Material = Enum.Material.Neon
        p.Size = Vector3.new(1, 1, 1)
        p.Parent = folder
        return p
    end
    c.borders = {
        top = newPart(),
        bottom = newPart(),
        left = newPart(),
        right = newPart()
    }
    c.borderTh = th
    c.borderIns = ins
end

local function updateBorders(c, color, visible)
    if not c.part then return end
    if not c.borders then createBorders(c) end
    
    -- Ensure parent exists
    if c.borders.top.Parent == nil then
        local folder = workspace:FindFirstChild("MinesweeperHighlights")
        if not folder then
            folder = Instance.new("Folder")
            folder.Name = "MinesweeperHighlights"
            folder.Parent = workspace
        end
        for _, b in pairs(c.borders) do b.Parent = folder end
    end

    local sz = c.part.Size
    local th = c.borderTh or 0.08
    local ins = c.borderIns or 0.05
    local hx = sz.X / 2 - ins
    local hz = sz.Z / 2 - ins
    local yoff = sz.Y / 2 + 0.01
    
    local t, b, l, r = c.borders.top, c.borders.bottom, c.borders.left, c.borders.right
    t.Size = Vector3.new(sz.X - ins * 2, th, th)
    b.Size = Vector3.new(sz.X - ins * 2, th, th)
    l.Size = Vector3.new(th, th, sz.Z - ins * 2)
    r.Size = Vector3.new(th, th, sz.Z - ins * 2)
    
    t.CFrame = c.part.CFrame * CFrame.new(0, yoff, -hz)
    b.CFrame = c.part.CFrame * CFrame.new(0, yoff, hz)
    l.CFrame = c.part.CFrame * CFrame.new(-hx, yoff, 0)
    r.CFrame = c.part.CFrame * CFrame.new(hx, yoff, 0)
    
    for _, border in pairs(c.borders) do
        border.Color = color
        border.Transparency = visible and 0 or 1
    end
end

local function highlight()
    local en = Toggles.HighlightMines and Toggles.HighlightMines.Value
    for x = 0, state.w - 1 do
        for z = 0, state.h - 1 do
            local c = state.grid[x][z]
            if not c or not c.part then continue end
            local isM = state.mines[c]
            local isS = state.safe[c]
            local isG = (state.guess == c)
            if en and (isM or isS or isG) then
                local color
                if isM then
                    color = Color3.new(1, 0, 0)
                elseif isS then
                    color = Color3.new(0, 1, 0)
                else
                    color = Color3.new(0, 0.7, 1)
                end
                updateBorders(c, color, true)
            elseif c.borders then
                updateBorders(c, Color3.new(1, 1, 1), false)
            end
        end
    end
end

theme.BuiltInThemes["Default"][2] = {
    BackgroundColor = "16293a",
    MainColor = "26445f",
    AccentColor = "5983a0",
    OutlineColor = "325573",
    FontColor = "d2dae1"
}

local win = lib:CreateWindow({
    Title = "Axis Hub -\nMinesweeper.lua",
    Footer = "by RwalDev & Plow | 1.8.4 | Discord: .gg/UuyxhqgEVs",
    NotifySide = "Right",
    ShowCustomCursor = true,
})

local home = win:AddTab("Home", "house")
local main = win:AddTab("Main", "target")
local config = win:AddTab("Settings", "settings")

local status = home:AddLeftGroupbox("Status")
status:AddLabel(string.format("Welcome, %s\nGame: Minesweeper", lp.DisplayName), true)
status:AddButton({ Text = "Unload", Func = function() lib:Unload() end })

local performance = home:AddRightGroupbox("Performance")
local fpsLbl = performance:AddLabel("FPS: ...", true)
local pingLbl = performance:AddLabel("Ping: ...", true)

local mainBox = main:AddLeftGroupbox("Main")
mainBox:AddToggle("HighlightMines", { Text = "Highlight Mines", Default = false })
mainBox:AddToggle("BypassAnticheat", { Text = "Bypass Anticheat", Default = true })

Toggles = lib.Toggles
Options = lib.Options

local lastSolve = 0
local solveInterval = 0.15

rs.Heartbeat:Connect(function()
    if not Toggles.HighlightMines or not Toggles.HighlightMines.Value then
        for x = 0, state.w - 1 do
            for z = 0, state.h - 1 do
                local c = state.grid[x] and state.grid[x][z]
                if c and c.borders then
                    for _, b in pairs(c.borders) do b.Transparency = 1 end
                end
            end
        end
        return
    end
    
    local folder = workspace:FindFirstChild("Flag") and workspace.Flag:FindFirstChild("Parts")
    if not folder then return end
    
    local pc = #folder:GetChildren()
    local now = tick()
    local needsRebuild = pc ~= state.parts
    
    if needsRebuild then
        state.parts = pc
        rebuild(folder)
    end
    
    if state.w == 0 then return end
    
    if needsRebuild or (now - lastSolve) >= solveInterval then
        lastSolve = now
        updateStates()
        solve()
        calcGuess()
    end
    
    highlight()
end)

local elap, frames = 0, 0
local perfConn = rs.RenderStepped:Connect(function(dt)
    frames = frames + 1
    elap = elap + dt
    if elap >= 1 then
        fpsLbl:SetText("FPS: " .. math.floor(frames / elap + 0.5))
        local net = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]
        pingLbl:SetText("Ping: " .. (net and math.floor(net:GetValue()) or 0) .. " ms")
        frames, elap = 0, 0
    end
end)

local cfgBox = config:AddLeftGroupbox("Config")
cfgBox:AddToggle("KeyMenu", { Default = lib.KeybindFrame.Visible, Text = "Keybind Menu", Callback = function(v) lib.KeybindFrame.Visible = v end })
cfgBox:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { Default = "RightControl", NoUI = true, Text = "Menu bind" })
lib.ToggleKeybind = lib.Options.MenuKeybind

theme:SetLibrary(lib)
save:SetLibrary(lib)
save:IgnoreThemeSettings()
save:SetIgnoreIndexes({ "MenuKeybind" })
theme:SetFolder("PlowsScriptHub")
save:SetFolder("PlowsScriptHub/Minesweeper")
save:BuildConfigSection(config)
theme:ApplyToTab(config)
save:LoadAutoloadConfig()

lib:OnUnload(function()
    if perfConn then perfConn:Disconnect() end
    for x = 0, state.w - 1 do
        for z = 0, state.h - 1 do
            local c = state.grid[x] and state.grid[x][z]
            if c and c.borders then
                for _, b in pairs(c.borders) do b:Destroy() end
            end
        end
    end
end)

pcall(bypass)
