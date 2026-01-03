local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/"
local lib = loadstring(game:HttpGet(repo .. "Library.lua"))()
local theme = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local save = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local rs = game:GetService("RunService")
local plrs = game:GetService("Players")
local lp = plrs.LocalPlayer
local cam = workspace.CurrentCamera

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
    local remote = game:GetService("ReplicatedStorage"):WaitForChild("Patukka", 3)
    if remote then
        local old
        old = hookmetamethod(game, "__namecall", function(self, ...)
            local m = getnamecallmethod()
            if self == remote and (m == "InvokeServer" or m == "FireServer") and Toggles.BypassAnticheat and Toggles.BypassAnticheat.Value then
                return nil
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
    local p = folder:GetChildren()
    if #p == 0 then return end
    local xs, zs, pos = {}, {}, {}
    local sy = 0
    for _, v in ipairs(p) do
        local p3 = v.Position
        table.insert(pos, {v = v, p = p3})
        table.insert(xs, p3.X)
        table.insert(zs, p3.Z)
        sy = sy + p3.Y
    end
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
    local ay = sy / #p
    for x = 0, state.w - 1 do
        state.grid[x] = {}
        for z = 0, state.h - 1 do
            state.grid[x][z] = {
                ix = x, iz = z,
                p = Vector3.new(ux[x+1], ay, uz[z+1]),
                part = nil, state = "unknown",
                num = nil, cov = true,
                neigh = {}
            }
        end
    end
    for _, d in ipairs(pos) do
        local best, dist = nil, 1000000
        local xI = 0
        for i, val in ipairs(ux) do
            local d2 = math.abs(d.p.X - val)
            if d2 < dist then dist = d2 xI = i - 1 end
        end
        dist = 1000000
        local zI = 0
        for i, val in ipairs(uz) do
            local d2 = math.abs(d.p.Z - val)
            if d2 < dist then dist = d2 zI = i - 1 end
        end
        local c = state.grid[xI][zI]
        if not c.part or (d.p - c.p).Magnitude < (c.part.Position - c.p).Magnitude then
            c.part, c.p = d.v, d.p
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

local function updateStates(folder)
    state.numbered = {}
    if state.w == 0 then return end
    for x = 0, state.w - 1 do
        for z = 0, state.h - 1 do
            local c = state.grid[x][z]
            if c and c.part then
                c.state, c.num, c.cov = "unknown", nil, true
                local gui = c.part:FindFirstChild("NumberGui")
                if gui then
                    local lbl = gui:FindFirstChild("TextLabel")
                    if lbl and tonumber(lbl.Text) then
                        c.num = tonumber(lbl.Text)
                        c.cov = false
                        c.state = "number"
                        table.insert(state.numbered, c)
                    end
                end
                if not gui then
                    local col = c.part.Color
                    if col.R > 0.7 and col.G > 0.7 and col.B > 0.7 then c.cov = false end
                end
                for _, child in ipairs(c.part:GetChildren()) do
                    if child.Name:sub(1, 4) == "Flag" then c.state = "flagged" break end
                end
            end
        end
    end
end

local function solve()
    if state.w == 0 or #state.numbered == 0 then return end
    local f, s = {}, {}
    local changed, iter = true, 0
    while changed and iter < 64 do
        changed = false
        iter = iter + 1
        for _, c in ipairs(state.numbered) do
            local u = {}
            local fc = 0
            for _, n in ipairs(c.neigh) do
                if f[n] or n.state == "flagged" then fc = fc + 1
                elseif not s[n] and c.cov then table.insert(u, n) end
            end
            local rem = (c.num or 0) - fc
            if rem > 0 and rem == #u then
                for _, v in ipairs(u) do if not f[v] then f[v] = true changed = true end end
            elseif rem == 0 and #u > 0 then
                for _, v in ipairs(u) do if not s[v] then s[v] = true changed = true end end
            end
        end
        for _, c in ipairs(state.numbered) do
            for _, n in ipairs(c.neigh) do
                if n.state == "number" then
                    local u1, u2 = {}, {}
                    local function getU(cell)
                        local r = {}
                        for _, nb in ipairs(cell.neigh) do
                            if not f[nb] and not s[nb] and nb.state ~= "number" and nb.state ~= "flagged" then table.insert(r, nb) end
                        end
                        return r
                    end
                    u1 = getU(c) u2 = getU(n)
                    if #u1 > 0 and #u2 > 0 then
                        local i, o1, o2 = {}, {}, {}
                        local m1 = {} for _, v in ipairs(u1) do m1[v] = true end
                        for _, v in ipairs(u2) do if m1[v] then table.insert(i, v) m1[v] = nil else table.insert(o2, v) end end
                        for v in pairs(m1) do table.insert(o1, v) end
                        local r1, r2 = (c.num or 0), (n.num or 0)
                        for _, nb in ipairs(c.neigh) do if f[nb] or nb.state == "flagged" then r1 = r1 - 1 end end
                        for _, nb in ipairs(n.neigh) do if f[nb] or nb.state == "flagged" then r2 = r2 - 1 end end
                        if #o1 == 0 and #o2 > 0 then
                            local d = r2 - r1
                            if d == 0 then for _, v in ipairs(o2) do if not s[v] then s[v] = true changed = true end end
                            elseif d == #o2 then for _, v in ipairs(o2) do if not f[v] then f[v] = true changed = true end end end
                        elseif #o2 == 0 and #o1 > 0 then
                            local d = r1 - r2
                            if d == 0 then for _, v in ipairs(o1) do if not s[v] then s[v] = true changed = true end end
                            elseif d == #o1 then for _, v in ipairs(o1) do if not f[v] then f[v] = true changed = true end end end
                        end
                    end
                end
            end
        end
    end
    state.mines, state.safe = f, s
end

local function guess()
    state.guess = nil
    if state.w == 0 then return end
    local fC, uC = 0, 0
    for x = 0, state.w - 1 do
        for z = 0, state.h - 1 do
            local c = state.grid[x][z]
            if c.state == "flagged" or state.mines[c] then fC = fC + 1
            elseif not state.safe[c] and c.state == "unknown" then uC = uC + 1 end
        end
    end
    local dens = uC > 0 and ((40 - fC) / uC) or 0
    local bC, bS = nil, 2
    for x = 0, state.w - 1 do
        for z = 0, state.h - 1 do
            local c = state.grid[x][z]
            if c.part and c.state == "unknown" and not state.mines[c] and not state.safe[c] then
                local vC, pS = 0, 0
                for _, n in ipairs(c.neigh) do
                    if n.state == "number" then
                        local fl, un = 0, 0
                        for _, nn in ipairs(n.neigh) do
                            if nn.state == "flagged" or state.mines[nn] then fl = fl+1
                            elseif not state.mines[nn] and not state.safe[nn] then un = un+1 end
                        end
                        local rem = n.num - fl
                        if rem <= 0 then vC = vC + 1 elseif un > 0 then pS = pS + (rem/un) vC = vC + 1 end
                    end
                end
                local score = 0.5 * (vC > 0 and (pS/vC) or dens) + 0.5 * dens
                if x == 0 or x == state.w-1 or z == 0 or z == state.h-1 then score = score + 0.05 end
                if not bS or score < bS then bS = score bC = c end
            end
        end
    end
    state.guess = bC
end

local function highlight()
    local en = Toggles.HighlightMines and Toggles.HighlightMines.Value
    for x = 0, state.w - 1 do
        for z = 0, state.h - 1 do
            local c = state.grid[x][z]
            if not c.part then continue end
            local h = state.highlights[c]
            local isM, isS, isG = state.mines[c], state.safe[c], (state.guess == c)
            if en and (isM or isS or isG) then
                if not h then
                    h = Instance.new("Highlight")
                    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    h.FillTransparency = 0.5
                    h.OutlineTransparency = 0
                    h.Parent = get("CoreGui")
                    state.highlights[c] = h
                end
                h.Adornee = c.part
                h.FillColor = isM and Color3.new(1,0,0) or (isS and Color3.new(0,1,0) or Color3.new(0,0.7,1))
                h.OutlineColor = Color3.new(1,1,1)
                h.Enabled = true
            elseif h then
                h.Enabled = false
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
    Title = "Axis Hub - Minesweeper.lua",
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

rs.Heartbeat:Connect(function()
    local folder = workspace:FindFirstChild("Flag") and workspace.Flag:FindFirstChild("Parts")
    if not folder then return end
    local pc = #folder:GetChildren()
    if pc ~= state.parts then state.parts = pc rebuild(folder) end
    if state.w == 0 then return end
    updateStates(folder)
    solve()
    guess()
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
    for _, h in pairs(state.highlights) do h:Destroy() end
end)

pcall(bypass)
