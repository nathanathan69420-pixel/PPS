local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/"
local lib = loadstring(game:HttpGet(repo .. "Library.lua"))()
local theme = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local save = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()
local rs, plrs = game:GetService("RunService"), game:GetService("Players")
local lp = plrs.LocalPlayer
local Toggles, Options = lib.Toggles, lib.Options
local config = { Enabled = false, GuessHelper = true, TotalMines = 25, DistanceWeight = 0.1, EdgePenalty = 0.05 }
local state = { cells = { grid = {}, numbered = {}, toFlag = {}, toClear = {} }, grid = { w = 0, h = 0 }, lastPartCount = -1, bestGuessCell = nil, dirtyFlag = true, lock = {} }
local COLOR_SAFE, COLOR_MINE, COLOR_GUESS, COLOR_WRONG = Color3.fromRGB(0, 255, 0), Color3.fromRGB(255, 0, 0), Color3.fromRGB(0, 170, 255), Color3.fromRGB(255, 0, 255)
local abs, floor, huge, sqrt, max, min, clock = math.abs, math.floor, math.huge, math.sqrt, math.max, math.min, os.clock
local tsort, tinsert, tremove = table.sort, table.insert, table.remove
local bit_extract = bit32.extract
local vec3, cfnew, inst = Vector3.new, CFrame.new, Instance.new
local function cluster(vals, d) 
    local res = {} if #vals == 0 then return res end 
    local cur, count = vals[1], 1 
    for i = 2, #vals do if abs(vals[i] - cur) <= d then count = count + 1 cur = cur + (vals[i] - cur) / count else tinsert(res, cur) cur, count = vals[i], 1 end end 
    tinsert(res, cur) return res 
end
local function median(vals) if #vals == 0 then return nil end tsort(vals) return vals[floor((#vals + 1) / 2)] end
local function estS(coords) if #coords < 3 then return 4 end local d = {} for i = 2, #coords do d[#d+1] = abs(coords[i] - coords[i-1]) end return median(d) or 4 end
local function findI(t, s) local bI, bD = 1, huge for i = 1, #s do local d = abs(t - s[i]) if d < bD then bD, bI = d, i end end return bI - 1 end
local function hasF(p) return p:FindFirstChild("Flag", true) ~= nil end
local cachedB = nil
local function scanB()
    if cachedB and cachedB.Parent then return cachedB end
    local f = workspace:FindFirstChild("Flag") local p = f and f:FindFirstChild("Parts") if p then cachedB = p return p end
    local ch = workspace:GetChildren() for i = 1, #ch do local v = ch[i] if v:IsA("Folder") and #v:GetChildren() > 50 then local p1 = v:GetChildren()[1] if p1 and p1:IsA("BasePart") and p1.Name == "Part" then cachedB = v return v end end end
    return nil
end
local function clearB()
    if not state.cells.grid then return end
    for x = 0, state.grid.w - 1 do local col = state.cells.grid[x] if col then for z = 0, state.grid.h - 1 do local c = col[z] if c then if c.borders then for _, b in pairs(c.borders) do b:Destroy() end c.borders = nil end c.isHighlightedMine, c.isHighlightedSafe, c.isHighlightedGuess, c.isWrongFlag = false, false, false, false end end end end
end
local function rebuildG(folder)
    clearB() state.cells.grid, state.grid.w, state.grid.h = {}, 0, 0
    local pts = folder:GetChildren() if #pts == 0 then return end
    local pD, sY = {}, 0
    for _, p in ipairs(pts) do if p:IsA("BasePart") then tinsert(pD, {p = p, pos = p.Position}) sY = sY + p.Position.Y end end
    local xs, zs = {}, {} for i = 1, #pD do xs[i], zs[i] = pD[i].pos.X, pD[i].pos.Z end
    tsort(xs) tsort(zs) local w, h = estS(xs) * 0.6, estS(zs) * 0.6
    local ux, uz = cluster(xs, w), cluster(zs, h) state.grid.w, state.grid.h = #ux, #uz
    if state.grid.w == 0 or state.grid.h == 0 then return end
    local ay = sY / #pD
    for x = 0, state.grid.w - 1 do state.cells.grid[x] = {} for z = 0, state.grid.h - 1 do state.cells.grid[x][z] = { ix = x, iz = z, pos = vec3(ux[x+1], ay, uz[z+1]), part = nil, state = "unknown", covered = true, neigh = {} } end end
    for _, d in ipairs(pD) do local xi, zi = findI(d.pos.X, ux), findI(d.pos.Z, uz) local c = state.cells.grid[xi][zi] if not c.part or (d.pos - vec3(ux[xi+1], d.pos.Y, uz[zi+1])).Magnitude < (c.part.Position - vec3(ux[xi+1], c.part.Position.Y, uz[zi+1])).Magnitude then c.part, c.pos = d.p, d.pos end end
    for z = 0, state.grid.h - 1 do for x = 0, state.grid.w - 1 do local c = state.cells.grid[x][z] for dz = -1, 1 do for dx = -1, 1 do if dx ~= 0 or dz ~= 0 then local nx, nz = x + dx, z + dz if nx >= 0 and nx < state.grid.w and nz >= 0 and nz < state.grid.h then tinsert(c.neigh, state.cells.grid[nx][nz]) end end end end end end
end
local function updateS(folder)
    state.cells.numbered = {} local grid = state.cells.grid if state.grid.w == 0 or not grid then return end
    for x = 0, state.grid.w - 1 do local col = grid[x] if col then for z = 0, state.grid.h - 1 do
        local c = col[z] local p = c and c.part
        if p then
            c.state, c.number, c.covered = "unknown", nil, true
            local ng = c._ng or p:FindFirstChild("NumberGui")
            if ng then c._ng = ng local lbl = c._tl or ng:FindFirstChild("TextLabel") if lbl then c._tl = lbl local t = lbl.Text if t ~= "" then local n = tonumber(t) if n then c.number, c.covered, c.state = n, false, "number" tinsert(state.cells.numbered, c) end end end end
            if c.covered then local cl = p.Color local r, g, b = cl.R*255, cl.G*255, cl.B*255 if r >= 170 and g >= 170 and b >= 170 and abs(r-g) <= 60 and abs(g-b) <= 60 and abs(r-b) <= 60 then c.covered = false end end
            if c.covered and hasF(p) then c.state = "flagged" end
        end
    end end end
end
local function countR(c, fS) local r = c.number or 0 local n = c.neigh for j = 1, #n do if fS[n[j]] then r = r - 1 end end return r end
local function getC(num, fS, sS)
    local bds, map = {}, {}
    for j = 1, #num do
        local nc = num[j] local r, ns, n = nc._cr, {}, nc.neigh
        for k = 1, #n do local t = n[k] if not fS[t] and t.state ~= "number" and t.covered ~= false and not sS[t] then tinsert(ns, t) if not map[t] then map[t] = true tinsert(bds, t) end end end
        nc._cn = ns
    end
    local adj = {} for j = 1, #bds do adj[bds[j]] = {} end
    for j = 1, #num do local ns = num[j]._cn for i = 1, #ns do for k = i+1, #ns do local u, v = ns[i], ns[k] adj[u][v], adj[v][u] = true, true end end end
    local vis, comps = {}, {}
    for j = 1, #bds do
        local u = bds[j] if not vis[u] then
            local comp, q = {}, {u} vis[u] = true
            while #q > 0 do
                local cur = tremove(q) tinsert(comp, cur)
                for n in pairs(adj[cur] or {}) do if not vis[n] then vis[n] = true tinsert(q, n) end end
            end
            tinsert(comps, comp)
        end
    end
    return comps
end
local function solveCSP(fS, sS)
    local num, tS = state.cells.numbered, clock()
    for j = 1, #num do local nc = num[j] local r, n = nc.number or 0, nc.neigh for k = 1, #n do if fS[n[k]] then r = r - 1 end end nc._cr = r end
    local comps = getC(num, fS, sS) if #comps == 0 then return end
    local cD, tCV = {}, 0
    for i = 1, #comps do
        local v = comps[i] local nV = #v if nV == 0 then continue end
        local deg = {} for j = 1, nV do deg[v[j]] = 0 end tCV = tCV + nV
        for j = 1, #num do local n = num[j]._cn for k = 1, #n do if deg[n[k]] then deg[n[k]] = deg[n[k]] + 1 end end end
        tsort(v, function(a, b) return deg[a] > deg[b] end)
        if clock() - tS > 0.08 then break end
        local map, cts, cCts = {}, {}, {} for j = 1, nV do map[v[j]], cCts[j] = j, {} end
        local cons = {}
        for j = 1, #num do local nc, cv = num[j], {} for k = 1, #nc._cn do local m = map[nc._cn[k]] if m then cv[#cv+1] = m end end if #cv > 0 then tsort(cv) cons[#cons+1] = {v = cv, r = nc._cr, cur = 0, un = #cv} end end
        if v._isGlobal then local gv = {} for j = 1, nV do gv[j] = j end cons[#cons+1] = {v = gv, r = v._rem, cur = 0, un = nV} end
        local vT = {} for j = 1, nV do vT[j] = {} end
        for j = 1, #cons do for _, vi in ipairs(cons[j].v) do tinsert(vT[vi], cons[j]) end end
        local cur, solC, abrt = {}, 0, false
        local function bt(idx)
            if solC >= 50000 or abrt then return end
            if (solC % 512 == 0) and (clock() - tS > 0.08) then abrt = true return end
            if idx > nV then
                solC = solC + 1 local ms = 0 for j = 1, nV do if cur[j] == 1 then ms = ms + 1 end end
                cts[ms] = (cts[ms] or 0) + 1
                for j = 1, nV do if cur[j] == 1 then cCts[j][ms] = (cCts[j][ms] or 0) + 1 end end
                return
            end
            local t = vT[idx]
            for val = 0, 1 do
                local ok = true
                for j = 1, #t do local c = t[j] local ns = c.cur + val if ns > c.r or (ns + c.un - 1) < c.r then ok = false break end end
                if ok then
                    cur[idx] = val for j = 1, #t do local c = t[j] c.cur, c.un = c.cur + val, c.un - 1 end
                    bt(idx + 1) if abrt then return end
                    for j = 1, #t do local c = t[j] c.cur, c.un = c.cur - val, c.un + 1 end
                end
            end
        end
        if nV <= 16 then
            for m = 0, 2^nV - 1 do
                local ok = true for j = 1, #cons do local s = 0 local cV = cons[j].v for k = 1, #cV do if bit_extract(m, cV[k]-1) == 1 then s = s + 1 end end if s ~= cons[j].r then ok = false break end end
                if ok then solC = solC + 1 local ms = 0 for j = 1, nV do if bit_extract(m, j-1) == 1 then ms = ms + 1 local mS = cCts[j] mS[ms] = (mS[ms] or 0) + 1 end end cts[ms] = (cts[ms] or 0) + 1 end
            end
        else bt(1) end
        if not abrt and solC > 0 then tinsert(cD, {v = v, cts = cts, ccts = cCts, total = solC}) end
    end
    if #cD > 0 then
        local valC = {} for i = 1, #cD do local vc = {} for k in pairs(cD[i].cts) do vc[k] = true end valC[i] = vc end
        if config.TotalMines then
            local kF, tU, grid = 0, 0, state.cells.grid
            for x = 0, state.grid.w - 1 do if grid[x] then for z = 0, state.grid.h - 1 do local c = grid[x][z] if c then if fS[c] then kF = kF + 1 elseif c.state ~= "number" and c.covered ~= false and not sS[c] then tU = tU + 1 end end end end end
            local tM, sl, dp = config.TotalMines - kF, max(0, tU - tCV), { [0] = true }
            for i = 1, #cD do local nD, d = {}, cD[i] for s in pairs(dp) do for k in pairs(d.cts) do local ns = s + k if ns <= tM then nD[ns] = true end end end dp = nD end
            local fVS = {} for s in pairs(dp) do if s + sl >= tM and s <= tM then fVS[s] = true end end
            local pC = {} for i = 1, #cD do pC[i] = {} end
            local function pr(idx, s)
                if idx > #cD then return fVS[s] == true end
                local d, ok = cD[idx], false for k in pairs(d.cts) do if pr(idx + 1, s + k) then pC[idx][k], ok = true, true end end return ok
            end
            if pr(1, 0) then valC = pC end
        end
        for i = 1, #cD do
            local d, tVS, vc = cD[i], 0, valC[i] for k, c in pairs(d.cts) do if vc[k] then tVS = tVS + c end end
            if tVS > 0 then
                for vi = 1, #d.v do
                    local v, mC = d.v[vi], 0 for k in pairs(vc) do mC = mC + (d.ccts[vi][k] or 0) end
                    if mC == tVS then fS[v] = true elseif mC == 0 then sS[v] = true if v.state == "flagged" then v.isWrongFlag = true end end
                    v._prob = mC / tVS
                end
            end
        end
    end
end
local function applyS(cA, cB, uA, uB, fS, sS)
    local sA, sB, iS = {}, {}, 0 for _, u in ipairs(uA) do sA[u] = true end
    for _, u in ipairs(uB) do if sA[u] then iS = iS + 1 sA[u] = false sB[u] = false else sB[u] = true end end
    local oA, oB, iL = {}, {}, {} for _, u in ipairs(uA) do if sA[u] ~= false then oA[#oA+1] = u else iL[#iL+1] = u end end
    for _, u in ipairs(uB) do if sB[u] then oB[#oB+1] = u end end
    if #iL == 0 then return end local rA, rB = countR(cA, fS), countR(cB, fS) local minI, maxI = max(0, rA - #oA, rB - #oB), min(rA, rB, #iL)
    if minI == maxI then
        if rA - minI == 0 then for _, u in ipairs(oA) do sS[u] = true end elseif rA - minI == #oA then for _, u in ipairs(oA) do fS[u] = true end end
        if rB - minI == 0 then for _, u in ipairs(oB) do sS[u] = true end elseif rB - minI == #oB then for _, u in ipairs(oB) do fS[u] = true end end
    end
end
local function updateL()
    if state.grid.w == 0 then state.cells.toFlag, state.cells.toClear = {}, {} return end
    local num = state.cells.numbered if #num == 0 then return end
    local fS, sS, ch, it = {}, {}, true, 0
    for x=0,state.grid.w-1 do local col=state.cells.grid[x] if col then for z=0,state.grid.h-1 do local c=col[z] if c then c._prob=nil end end end end
    while ch and it < 64 do
        ch, it = false, it + 1
        for j = 1, #num do
            local c = num[j] local unk, flg, n = {}, 0, c.neigh
            for k = 1, #n do local t = n[k] if fS[t] then flg = flg + 1 elseif not sS[t] and t.state ~= "number" and t.covered ~= false then tinsert(unk, t) end end
            local r = (c.number or 0) - flg
            if r > 0 and r == #unk then for k = 1, #unk do local u = unk[k] if not fS[u] then fS[u] = true ch = true end end
            elseif r == 0 and #unk > 0 then for k = 1, #unk do local u = unk[k] if not sS[u] then sS[u] = true ch = true end end end
        end
        local pF, pC = 0, 0 for _ in pairs(fS) do pF = pF + 1 end for _ in pairs(sS) do pC = pC + 1 end
        for j = 1, #num do
            local c = num[j] local n = c.neigh
            for k = 1, #n do
                local a = n[k] if a.state == "number" then
                    local uT, uA, n1, n2 = {}, {}, c.neigh, a.neigh
                    for m = 1, #n1 do local t = n1[m] if not fS[t] and not sS[t] and t.state ~= "number" and t.covered ~= false then tinsert(uT, t) end end
                    for m = 1, #n2 do local t = n2[m] if not fS[t] and not sS[t] and t.state ~= "number" and t.covered ~= false then tinsert(uA, t) end end
                    if #uT > 0 and #uA > 0 then applyS(c, a, uT, uA, fS, sS) end
                end
            end
        end
        local postF, postC = 0, 0 for _ in pairs(fS) do postF = postF + 1 end for _ in pairs(sS) do postC = postC + 1 end
        if postF ~= pF or postC ~= pC then ch = true end
        if not ch then solveCSP(fS, sS) local nF, nC = 0, 0 for _ in pairs(fS) do nF = nF + 1 end for _ in pairs(sS) do nC = nC + 1 end if nF ~= postF or nC ~= postC then ch = true end end
    end
    local stableF, stableS = {}, {}
    for c in pairs(fS) do stableF[c] = true end
    for c in pairs(sS) do stableS[c] = true end
    if state.cells.toFlag ~= stableF or state.cells.toClear ~= stableS then state.dirtyFlag = true end
    state.cells.toFlag, state.cells.toClear = stableF, stableS
end
local function updateG()
    state.bestGuessCell = nil if not config.GuessHelper or state.grid.w == 0 then return end
    local kF, uK = 0, 0 for x=0,state.grid.w-1 do local col=state.cells.grid[x] if col then for z=0,state.grid.h-1 do local c=col[z] if c.state == "flagged" or state.cells.toFlag[c] then kF=kF+1 elseif c.state ~= "number" and c.covered ~= false and not state.cells.toClear[c] then uK=uK+1 end end end end
    local gD = uK > 0 and ((config.TotalMines - kF) / uK) or 0.15
    local pP = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") and lp.Character.HumanoidRootPart.Position
    local maxD = pP and sqrt((state.grid.w*5)^2 + (state.grid.h*5)^2) or 1
    local bestC, bestS = nil, nil
    for x=0,state.grid.w-1 do local col=state.cells.grid[x] if col then for z=0,state.grid.h-1 do
        local c = col[z] if c and c.part and c.state ~= "number" and c.covered ~= false and not hasF(c.part) and not state.cells.toFlag[c] and not state.cells.toClear[c] then
            local pb = c._prob
            if not pb then
                local vC, pS, hasNIdx, n = 0, 0, false, c.neigh
                for k = 1, #n do
                    local t = n[k] if t.state == "number" and t.number and t.number > 0 then
                        hasNIdx = true local fs, lu, n3 = 0, 0, t.neigh
                        for m = 1, #n3 do local nn = n3[m] if (nn.part and hasF(nn.part)) or state.cells.toFlag[nn] then fs = fs + 1 elseif nn.state ~= "number" and nn.covered ~= false and not state.cells.toFlag[nn] and not state.cells.toClear[nn] then lu = lu + 1 end end
                        local r = t.number - fs if r <= 0 then vC = vC + 1 elseif lu > 0 then pS = pS + (r/lu) vC = vC + 1 end
                    end
                end
                pb = (hasNIdx and vC > 0) and (pS / vC) or gD
            end
            local s = pb + ((x == 0 or x == state.grid.w-1 or z == 0 or z == state.grid.h-1) and config.EdgePenalty or 0)
            local uN = 0 local n4 = c.neigh for k = 1, #n4 do local t = n4[k] if t.state ~= "number" and t.covered ~= false and not state.cells.toFlag[t] and not state.cells.toClear[t] then uN = uN + 1 end end
            local cN = 0 for k = 1, #n4 do if n4[k].state == "number" then cN = cN + 1 end end
            s = s - (uN * 0.01) - (cN * 0.05) + (sqrt((x-state.grid.w/2)^2 + (z-state.grid.h/2)^2) / (state.grid.w + state.grid.h)) * 0.05
            if pP then s = s + ((c.pos - pP).Magnitude / maxD) * config.DistanceWeight end
            if not bestS or s < bestS then bestS, bestC = s, c end
        end
    end end end
    if state.bestGuessCell ~= bestC then state.dirtyFlag = true end
    state.bestGuessCell = bestC
end
local function applyH(c, col)
    if not c.borders then
        local th, ins = 0.15, 0.02
        local function np() local p=inst("Part") p.Anchored,p.CanCollide,p.CanQuery,p.CanTouch,p.CastShadow,p.Transparency,p.Material,p.Size=true,false,false,false,false,1,Enum.Material.Neon,vec3(1,1,1) return p end
        c.borders = { top = np(), bottom = np(), left = np(), right = np() }
        local f = workspace:FindFirstChild("MinesweeperHighlights") or inst("Folder", workspace) f.Name = "MinesweeperHighlights"
        for _, b in pairs(c.borders) do b.Parent = f end
        if c.part then
            local sz, hx, hz, yf = c.part.Size, c.part.Size.X/2 - ins, c.part.Size.Z/2 - ins, c.part.Size.Y/2 + 0.01
            local t, b, l, r = c.borders.top, c.borders.bottom, c.borders.left, c.borders.right
            t.Size, b.Size, l.Size, r.Size = vec3(sz.X-ins*2, th, th), vec3(sz.X-ins*2, th, th), vec3(th, th, sz.Z-ins*2), vec3(th, th, sz.Z-ins*2)
            t.CFrame, b.CFrame, l.CFrame, r.CFrame = c.part.CFrame*cfnew(0, yf, -hz), c.part.CFrame*cfnew(0, yf, hz), c.part.CFrame*cfnew(-hx, yf, 0), c.part.CFrame*cfnew(hx, yf, 0)
        end
    end
    for _, b in pairs(c.borders) do b.Color, b.Transparency = col, 0 end
end
local function updateH()
    if not state.dirtyFlag then return end
    state.dirtyFlag = false
    local bG, en = state.bestGuessCell, Toggles.HighlightMines and Toggles.HighlightMines.Value
    local grid = state.cells.grid if not grid then return end
    for x = 0, state.grid.w - 1 do local col = grid[x] if col then for z = 0, state.grid.h - 1 do
        local c = col[z] if c and c.part then
            local vis = c.covered and c.state ~= "number"
            if not vis then if c.isHighlightedMine or c.isHighlightedSafe or c.isHighlightedGuess or c.isWrongFlag then if c.borders then for _, b in pairs(c.borders) do b.Transparency = 1 end end c.isHighlightedMine, c.isHighlightedSafe, c.isHighlightedGuess, c.isWrongFlag = false, false, false, false end
            else
                local iM, iS, iG, iW = state.cells.toFlag[c] ~= nil, state.cells.toClear[c] ~= nil, c == bG and config.GuessHelper, c.isWrongFlag
                if iM ~= c.isHighlightedMine or iS ~= c.isHighlightedSafe or iG ~= c.isHighlightedGuess or iW ~= c.isWrongFlag then
                    c.isHighlightedMine, c.isHighlightedSafe, c.isHighlightedGuess, c.isWrongFlag = iM, iS, iG, iW
                    if en and (iM or iS or iG or iW) then applyH(c, iW and COLOR_WRONG or (iM and COLOR_MINE) or (iS and COLOR_SAFE) or COLOR_GUESS)
                    elseif c.borders then for _, b in pairs(c.borders) do b.Transparency = 1 end end
                end
            end
        end
    end end end
end
theme.BuiltInThemes["Default"][2] = { BackgroundColor = "16293a", MainColor = "26445f", AccentColor = "5983a0", OutlineColor = "325573", FontColor = "d2dae1" }
local win = lib:CreateWindow({ Title = "Axis Hub -\nMinesweeper.lua", Footer = "by RwalDev & Plow | 1.9.0", NotifySide = "Right", ShowCustomCursor = true })
local h, m, s = win:AddTab("Home", "house"), win:AddTab("Main", "target"), win:AddTab("Settings", "settings")
local status = h:AddLeftGroupbox("Status") status:AddLabel(string.format("Welcome, %s\nGame: Minesweeper", lp.DisplayName), true) status:AddButton({ Text = "Unload", Func = function() lib:Unload() end })
local perf = h:AddRightGroupbox("Performance") local fpsL, pingL = perf:AddLabel("FPS: ...", true), perf:AddLabel("Ping: ...", true)
local mainB = m:AddLeftGroupbox("Main") mainB:AddToggle("HighlightMines", { Text = "Highlight Mines", Default = false }) mainB:AddToggle("BypassAnticheat", { Text = "Bypass Anticheat", Default = true })
local cfgB = s:AddLeftGroupbox("Config") cfgB:AddToggle("KeyMenu", { Default = lib.KeybindFrame.Visible, Text = "Keybind Menu", Callback = function(v) lib.KeybindFrame.Visible = v end }) cfgB:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { Default = "RightControl", NoUI = true, Text = "Menu bind" })
lib.ToggleKeybind = Options.MenuKeybind
local function bypass()
    if not getrawmetatable or not hookmetamethod then return end
    local r = game:GetService("ReplicatedStorage"):FindFirstChild("Patukka")
    if r then local old old = hookmetamethod(game, "__namecall", function(self, ...) local m = getnamecallmethod() if self == r and (m == "InvokeServer" or m == "FireServer") then if Toggles.BypassAnticheat and Toggles.BypassAnticheat.Value then return nil end end return old(self, ...) end) end
end
local lastS, solveInt = 0, 0.05
rs.Heartbeat:Connect(function()
    config.Enabled = Toggles.HighlightMines and Toggles.HighlightMines.Value
    if not config.Enabled then clearB() state.cells.toFlag, state.cells.toClear, state.lastPartCount = {}, {}, -1 return end
    local f = scanB() if not f then return end
    local pc, now = #f:GetChildren(), tick()
    local neb = pc ~= state.lastPartCount if neb then clearB() state.lastPartCount = pc rebuildG(f) end
    if state.grid.w == 0 then return end
    if neb or (now - lastS) >= solveInt then lastS = now updateS(f) updateL() updateG() end
    updateH()
end)
rs.RenderStepped:Connect(function(dt)
    elap, frames = elap + dt, frames + 1
    if elap >= 1 then fpsL:SetText("FPS: " .. floor(frames/elap+0.5)) local net = game:GetService("Stats").Network.ServerStatsItem["Data Ping"] pingL:SetText("Ping: " .. (net and floor(net:GetValue()) or 0) .. " ms") frames, elap = 0, 0 end
end)
theme:SetLibrary(lib) save:SetLibrary(lib) save:IgnoreThemeSettings() save:SetIgnoreIndexes({ "MenuKeybind" })
theme:SetFolder("PlowsScriptHub") save:SetFolder("PlowsScriptHub/Minesweeper")
save:BuildConfigSection(s) theme:ApplyToTab(s) save:LoadAutoloadConfig()
lib:OnUnload(function() clearB() local f = workspace:FindFirstChild("MinesweeperHighlights") if f then f:Destroy() end end)
pcall(bypass)
