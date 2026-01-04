local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/"
local lib = loadstring(game:HttpGet(repo .. "Library.lua"))()
local theme = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local save = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()
local rs, plrs = game:GetService("RunService"), game:GetService("Players")
local lp = plrs.LocalPlayer
local Toggles, Options = lib.Toggles, lib.Options
local config = { Enabled = false, GuessHelper = true, TotalMines = 25, DistanceWeight = 0.1, EdgePenalty = 0.05 }
local state = { cells = { grid = {}, numbered = {}, toFlag = {}, toClear = {} }, grid = { w = 0, h = 0 }, lastPartCount = -1, bestGuessCell = nil, clicked = {} }
local elap, frames = 0, 0
local COLOR_SAFE, COLOR_MINE, COLOR_GUESS, COLOR_WRONG = Color3.fromRGB(0, 255, 0), Color3.fromRGB(255, 0, 0), Color3.fromRGB(0, 170, 255), Color3.fromRGB(255, 0, 255)
local abs, floor, huge, sqrt, max, min = math.abs, math.floor, math.huge, math.sqrt, math.max, math.min
local tsort, tinsert, tremove = table.sort, table.insert, table.remove
local function cluster(vals, d) 
    local res = {} if #vals == 0 then return res end 
    local cur, count = vals[1], 1 
    for i = 2, #vals do 
        if abs(vals[i] - cur) <= d then count = count + 1 cur = cur + (vals[i] - cur) / count 
        else tinsert(res, cur) cur, count = vals[i], 1 end 
    end 
    tinsert(res, cur) return res 
end
local function median(vals) if #vals == 0 then return nil end tsort(vals) return vals[floor((#vals + 1) / 2)] end
local function estS(coords) if #coords < 3 then return 4 end local d = {} for i = 2, #coords do d[#d+1] = abs(coords[i] - coords[i-1]) end return median(d) or 4 end
local function findI(t, s) local bI, bD = 1, huge for i = 1, #s do local d = abs(t - s[i]) if d < bD then bD, bI = d, i end end return bI - 1 end
local function hasF(p) for _,v in ipairs(p:GetChildren()) do local n = v.Name:lower() if n:find("flag") or n:find("mark") or v:IsA("Texture") or v:IsA("Decal") or (v:IsA("Model") and #v:GetChildren()>0) then return true end end return false end
local function isE(c) return c.state ~= "number" and c.covered ~= false end
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
    clearB() state.cells.grid, state.grid.w, state.grid.h = {}, 0, 0
    state.cells.toFlag, state.cells.toClear, state.cells.numbered = {}, {}, {}
    state.clicked = {}
    local pts = folder:GetChildren() if #pts == 0 then return end
    local pD, sY = {}, 0
    for _, p in ipairs(pts) do if p:IsA("BasePart") then tinsert(pD, {p = p, pos = p.Position}) sY = sY + p.Position.Y end end
    local xs, zs = {}, {} for i = 1, #pD do xs[i], zs[i] = pD[i].pos.X, pD[i].pos.Z end
    tsort(xs) tsort(zs) local w, h = estS(xs) * 0.6, estS(zs) * 0.6
    local ux, uz = cluster(xs, w), cluster(zs, h) state.grid.w, state.grid.h = #ux, #uz
    if state.grid.w == 0 or state.grid.h == 0 then return end
    local ay = sY / #pD
    for x = 0, state.grid.w - 1 do state.cells.grid[x] = {} for z = 0, state.grid.h - 1 do state.cells.grid[x][z] = { ix = x, iz = z, pos = Vector3.new(ux[x+1], ay, uz[z+1]), part = nil, state = "unknown", covered = true, neigh = {} } end end
    for _, d in ipairs(pD) do local xi, zi = findI(d.pos.X, ux), findI(d.pos.Z, uz) local c = state.cells.grid[xi][zi] if not c.part or (d.pos - Vector3.new(ux[xi+1], d.pos.Y, uz[zi+1])).Magnitude < (c.part.Position - Vector3.new(ux[xi+1], c.part.Position.Y, uz[zi+1])).Magnitude then c.part, c.pos = d.p, d.pos end end
    for z = 0, state.grid.h - 1 do for x = 0, state.grid.w - 1 do local c = state.cells.grid[x][z] for dz = -1, 1 do for dx = -1, 1 do if dx ~= 0 or dz ~= 0 then local nx, nz = x + dx, z + dz if nx >= 0 and nx < state.grid.w and nz >= 0 and nz < state.grid.h then tinsert(c.neigh, state.cells.grid[nx][nz]) end end end end end end
end
local function updateS(folder)
    state.cells.numbered = {} local grid = state.cells.grid if not grid or state.grid.w == 0 then return end
    for x = 0, state.grid.w - 1 do local col = grid[x] if col then for z = 0, state.grid.h - 1 do
        local c = col[z] local p = c.part if p then
            c.state, c.number, c.covered = "unknown", nil, true
            if not c._isRef then
                local ng = p:FindFirstChildWhichIsA("SurfaceGui") or p:FindFirstChildWhichIsA("BillboardGui")
                if ng then c._ng = ng c._tl = ng:FindFirstChildWhichIsA("TextLabel") end
                c._isRef = true
            end
            local lbl = c._tl
            if lbl then 
                local t = lbl.Text if t ~= "" then local n = tonumber(t)
                    if n then c.number, c.covered, c.state = n, false, "number"
                    elseif t ~= " " then c.covered, c.state, c.number = false, "empty", 0 end
                end
            end
            if c.covered then 
                local cl = p.Color local r, g, b = cl.R*255, cl.G*255, cl.B*255 
                local av = (r + g + b) / 3 if av > 165 and abs(r-av) < 20 and abs(g-av) < 20 and abs(b-av) < 20 then c.covered, c.state, c.number = false, "empty", 0 end
            end
            if hasF(p) then c.state, c.covered = "flagged", true end
            c.isWrongFlag = false
        end
        if not c.covered and (c.state == "number" or c.state == "empty") then tinsert(state.cells.numbered, c) end
    end end end
end
local function countR(c, fS) local r = c.number or 0 for _, n in ipairs(c.neigh) do if fS[n] then r = r - 1 end end return r end
local function getC(num, fS, sS)
    local bds, map = {}, {}
    for _, nc in ipairs(num) do
        local r, ns = nc.number or 0, {}
        for _, n in ipairs(nc.neigh) do if fS[n] then r = r - 1 elseif isE(n) and not sS[n] then tinsert(ns, n) if not map[n] then map[n] = true tinsert(bds, n) end end end
        nc._cr, nc._cn = r, ns
    end
    local adj = {} for _, u in ipairs(bds) do adj[u] = {} end
    for _, nc in ipairs(num) do local ns = nc._cn for i = 1, #ns do for j = i+1, #ns do local u, v = ns[i], ns[j] adj[u][v], adj[v][u] = true, true end end end
    local vis, comps = {}, {}
    for _, u in ipairs(bds) do if not vis[u] then local comp, q = {}, {u} vis[u] = true while #q > 0 do local cur = tremove(q) tinsert(comp, cur) for n in pairs(adj[cur] or {}) do if not vis[n] then vis[n] = true tinsert(q, n) end end end tinsert(comps, comp) end end
    return comps
end
local function solveCSP(fS, sS)
    local num, tS = state.cells.numbered, os.clock()
    local comps = getC(num, fS, sS) if #comps == 0 then return end
    local cD, tCV = {}, 0
    for i = 1, #comps do
        local v = comps[i] local nV = #v if nV == 0 then continue end
        local deg = {} for j = 1, nV do deg[v[j]] = 0 end tCV = tCV + nV
        for j = 1, #num do local nc = num[j] for k = 1, #nc._cn do local n = nc._cn[k] if deg[n] then deg[n] = deg[n] + 1 end end end
        tsort(v, function(a, b) return deg[a] > deg[b] end)
        if os.clock() - tS > 0.1 then break end
        local map, cts, cCts = {}, {}, {} for j = 1, nV do map[v[j]], cCts[j] = j, {} end
        local cons = {}
        for j = 1, #num do
            local nc, cv = num[j], {} for k = 1, #nc._cn do local m = map[nc._cn[k]] if m then cv[#cv+1] = m end end
            if #cv > 0 then tsort(cv) cons[#cons+1] = {v = cv, r = nc._cr, cur = 0, un = #cv} end
        end
        local vT = {} for j = 1, nV do vT[j] = {} end
        for j = 1, #cons do for _, vi in ipairs(cons[j].v) do tinsert(vT[vi], cons[j]) end end
        local cur, solC, abrt = {}, 0, false
        local function bt(idx)
            if solC >= 1000000 or abrt then return end
            if (solC % 512 == 0) and (os.clock() - tS > 0.1) then abrt = true return end
            if idx > nV then
                solC = solC + 1 local ms = 0 for j = 1, nV do ms = ms + cur[j] end
                cts[ms] = (cts[ms] or 0) + 1
                for j = 1, nV do if cur[j] == 1 then cCts[j][ms] = (cCts[j][ms] or 0) + 1 end end
                return
            end
            for val = 0, 1 do
                local ok = true
                for j = 1, #vT[idx] do
                    local c = vT[idx][j]
                    local ns = c.cur + val
                    if ns > c.r or (ns + c.un - 1) < c.r then ok = false break end
                end
                if ok then
                    cur[idx] = val
                    for j = 1, #vT[idx] do local c = vT[idx][j] c.cur, c.un = c.cur + val, c.un - 1 end
                    bt(idx + 1)
                    if abrt then return end
                    for j = 1, #vT[idx] do local c = vT[idx][j] c.cur, c.un = c.cur - val, c.un + 1 end
                end
            end
        end
        if nV <= 24 then
            for m = 0, 2^nV - 1 do
                local ok = true for j = 1, #cons do local s = 0 for _, vi in ipairs(cons[j].v) do if bit32.extract(m, vi-1) == 1 then s = s + 1 end end if s ~= cons[j].r then ok = false break end end
                if ok then solC = solC + 1 local ms = 0 for j = 1, nV do if bit32.extract(m, j-1) == 1 then ms = ms + 1 cCts[j][ms] = (cCts[j][ms] or 0) + 1 end end cts[ms] = (cts[ms] or 0) + 1 end
                if solC >= 1000000 then break end
            end
        else bt(1) end
        if not abrt and solC > 0 then tinsert(cD, {v = v, cts = cts, ccts = cCts, total = solC}) end
    end
    if #cD > 0 then
        if config.TotalMines then
            local kF, tU, grid = 0, 0, state.cells.grid
            for x = 0, state.grid.w - 1 do if grid[x] then for z = 0, state.grid.h - 1 do local c = grid[x][z] if c then if c.state == "flagged" or fS[c] then kF = kF + 1 elseif isE(c) and not sS[c] then tU = tU + 1 end end end end end
            local tM, sl = config.TotalMines - kF, max(0, tU - tCV)
            local lnF = { [0] = 0 }
            for j = 1, max(tM, sl) + 1 do lnF[j] = lnF[j-1] + math.log(j) end
            local function nCr(n, r) if r < 0 or r > n then return 0 end return math.exp(lnF[n] - lnF[r] - lnF[n-r]) end
            local dp = { [0] = 1 }
            for i = 1, #cD do
                local nD, d = {}, cD[i]
                for s, ways in pairs(dp) do
                    for k, count in pairs(d.cts) do
                        local ns = s + k
                        if ns <= tM then nD[ns] = (nD[ns] or 0) + ways * count end
                    end
                end
                dp = nD
            end
            local fW = {}
            for s, ways in pairs(dp) do
                local rem = tM - s
                if rem >= 0 and rem <= sl then fW[s] = ways * nCr(sl, rem) end
            end
            local totW = 0 for _, w in pairs(fW) do totW = totW + w end
            if totW > 1e-300 then
                local pr, sf = { [0] = { [0] = 1 } }, { [#cD + 1] = { [0] = 1 } }
                for i = 1, #cD do
                    local nD, d = {}, cD[i]
                    for s, w in pairs(pr[i-1]) do for k, c in pairs(d.cts) do local ns = s + k if ns <= tM then nD[ns] = (nD[ns] or 0) + w * c end end end
                    pr[i] = nD
                end
                for i = #cD, 1, -1 do
                    local nD, d = {}, cD[i]
                    for s, w in pairs(sf[i+1]) do for k, c in pairs(d.cts) do local ns = s + k if ns <= tM then nD[ns] = (nD[ns] or 0) + w * c end end end
                    sf[i] = nD
                end
                for i = 1, #cD do
                    local d = cD[i]
                    local p1, s1 = pr[i-1], sf[i+1]
                    local comb = {}
                    for s, w in pairs(p1) do for ks, kw in pairs(s1) do local ns = s + ks if ns <= tM then comb[ns] = (comb[ns] or 0) + w * kw end end end
                    for vi = 1, #d.v do
                        local v, mP = d.v[vi], 0
                        for k, c in pairs(d.ccts[vi]) do
                            local sK = 0
                            for cs, cw in pairs(comb) do
                                local rem = tM - (cs + k)
                                if rem >= 0 and rem <= sl then sK = sK + cw * nCr(sl, rem) end
                            end
                            mP = mP + c * sK
                        end
                        v._prob = mP / totW
                        local p = v._prob
                        v._ent = (p > 1e-6 and p < (1-1e-6)) and -(p*math.log(p) + (1-p)*math.log(1-p)) or 0
                        if not d.abrt then
                            if abs(mP - totW) < (totW * 1e-11) then fS[v] = true 
                            elseif mP < (totW * 1e-11) then sS[v] = true if v.state == "flagged" then v.isWrongFlag = true end end
                        end
                    end
                end
                local slP = 0
                for fs, fw in pairs(fW) do if tM > fs then slP = slP + fw * (tM - fs) / sl end end
                state._slProb = sl == 0 and 0 or (slP / totW)
                local sp = state._slProb
                state._slEnt = (sp > 1e-6 and sp < (1-1e-6)) and -(sp*math.log(sp) + (1-sp)*math.log(1-sp)) or 0
            end
        else
            for i = 1, #cD do
                local d = cD[i]
                for vi = 1, #d.v do
                    local v = d.v[vi]
                    local mC = 0 for k, c in pairs(d.cts) do mC = mC + (d.ccts[vi][k] or 0) end
                    v._prob = mC / d.total
                    local p = v._prob
                    v._ent = (p > 1e-6 and p < (1-1e-6)) and -(p*math.log(p) + (1-p)*math.log(1-p)) or 0
                    if not d.abrt then if abs(mC - d.total) < 1e-6 then fS[v] = true elseif mC < 1e-6 then sS[v] = true end end
                end
            end
        end
    end
end
local function applyS(cA, cB, uA, uB, fS, sS)
    local sA, sB = {}, {}
    for _, u in ipairs(uA) do sA[u] = true end
    for _, u in ipairs(uB) do if sA[u] then sA[u] = nil else sB[u] = true end end
    local oA, oB, iL = {}, {}, {}
    for _, u in ipairs(uA) do if sA[u] then tinsert(oA, u) else tinsert(iL, u) end end
    for _, u in ipairs(uB) do if sB[u] then tinsert(oB, u) end end
    if #iL == 0 then return end
    local rA, rB = countR(cA, fS), countR(cB, fS)
    local minI, maxI = max(0, rA-#oA, rB-#oB), min(rA, rB, #iL)
    if minI == maxI then
        if rA - minI == 0 then for _, u in ipairs(oA) do sS[u] = true end elseif rA - minI == #oA then for _, u in ipairs(oA) do fS[u] = true end end
        if rB - minI == 0 then for _, u in ipairs(oB) do sS[u] = true end elseif rB - minI == #oB then for _, u in ipairs(oB) do fS[u] = true end end
    end
end
local function updateL()
    if state.grid.w == 0 then state.cells.toFlag, state.cells.toClear = {}, {} return end
    local num = state.cells.numbered if #num == 0 then return end
    local fS, sS = {}, {} 
    state.cells.toFlag, state.cells.toClear = fS, sS
    local ch, it, tO = true, 0, os.clock()
    for x=0,state.grid.w-1 do local col=state.cells.grid[x] if col then for z=0,state.grid.h-1 do local c=col[z] if c then 
        c._prob = nil 
        if c.state == "flagged" then fS[c] = true end
    end end end end
    while ch and it < 64 do
        ch, it = false, it + 1
        if os.clock() - tO > 0.5 then break end
        for _, c in ipairs(num) do
            local unk, flg = {}, 0 for _, n in ipairs(c.neigh) do if fS[n] then flg = flg + 1 elseif not sS[n] and isE(n) then tinsert(unk, n) end end
            local r = (c.number or 0) - flg
            if r > 0 and r == #unk then for _, u in ipairs(unk) do if not fS[u] then fS[u] = true ch = true end end
            elseif r <= 0 and #unk > 0 then for _, u in ipairs(unk) do if not sS[u] then sS[u] = true ch = true end end end
        end
        local pF, pC = 0, 0 for _ in pairs(fS) do pF = pF + 1 end for _ in pairs(sS) do pC = pC + 1 end
        for _, c in ipairs(num) do for _, n in ipairs(c.neigh) do if n.state == "number" or n.state == "empty" then local uT, uA = {}, {} for _, nn in ipairs(c.neigh) do if not fS[nn] and not sS[nn] and isE(nn) then tinsert(uT, nn) end end for _, nn in ipairs(n.neigh) do if not fS[nn] and not sS[nn] and isE(nn) then tinsert(uA, nn) end end if #uT > 0 and #uA > 0 then applyS(c, n, uT, uA, fS, sS) end end end end
        local postF, postC = 0, 0 for _ in pairs(fS) do postF = postF + 1 end for _ in pairs(sS) do postC = postC + 1 end
        if postF ~= pF or postC ~= pC then ch = true end
        if not ch then solveCSP(fS, sS) local nF, nC = 0, 0 for _ in pairs(fS) do nF = nF + 1 end for _ in pairs(sS) do nC = nC + 1 end if nF ~= postF or nC ~= postC then ch = true end end
    end
    state.cells.toFlag, state.cells.toClear = fS, sS
    for c in pairs(sS) do if c.state == "flagged" then c.isWrongFlag = true end end
end
local function updateG()
    state.bestGuessCell = nil if not config.GuessHelper or state.grid.w == 0 then return end
    local kF, uK = 0, 0 for x=0,state.grid.w-1 do local col=state.cells.grid[x] if col then for z=0,state.grid.h-1 do local c=col[z] if c.state == "flagged" or state.cells.toFlag[c] then kF=kF+1 elseif isE(c) and not state.cells.toClear[c] then uK=uK+1 end end end end
    local gD = uK > 0 and ((config.TotalMines - kF) / uK) or 0.15
    local pP = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") and lp.Character.HumanoidRootPart.Position
    local maxD = pP and sqrt((state.grid.w*5)^2 + (state.grid.h*5)^2) or 1
    local bestC, bestS = nil, nil
    for x=0,state.grid.w-1 do local col=state.cells.grid[x] if col then for z=0,state.grid.h-1 do
        local c = col[z] if c and c.part and isE(c) and not hasF(c.part) and not state.cells.toFlag[c] and not state.cells.toClear[c] then
                local pb = c._prob or state._slProb
                local ent = c._ent or state._slEnt or 0
                if not pb then
                    local vC, pS, hasN = 0, 0, false
                    for _, n in ipairs(c.neigh) do if n.state == "number" and n.number and n.number > 0 then hasN = true local fs, lu = 0, 0 for _, nn in ipairs(n.neigh) do if (nn.part and hasF(nn.part)) or state.cells.toFlag[nn] then fs = fs + 1 elseif isE(nn) and not state.cells.toFlag[nn] and not state.cells.toClear[nn] then lu = lu + 1 end end local r = n.number - fs if r <= 0 then vC = vC + 1 elseif lu > 0 then pS = pS + (r/lu) vC = vC + 1 end end end
                    pb = (hasN and vC > 0) and (pS / vC) or gD
                end
                local s = pb - (ent * 0.05) + ((x == 0 or x == state.grid.w-1 or z == 0 or z == state.grid.h-1) and config.EdgePenalty or 0)
                local uN = 0 for _, n in ipairs(c.neigh) do if isE(n) and not state.cells.toFlag[n] and not state.cells.toClear[n] then uN = uN + 1 end end
                local nC = 0 for _, n in ipairs(c.neigh) do if n.state == "number" then nC = nC + 1 end end
                s = s - (uN * 0.01) - (nC * 0.01)
                local dx, dz = x - state.grid.w/2, z - state.grid.h/2 s = s + (sqrt(dx*dx + dz*dz) / (state.grid.w + state.grid.h)) * 0.02
                if pP then s = s + ((c.pos - pP).Magnitude / maxD) * config.DistanceWeight end
                if not bestS or s < bestS then bestS, bestC = s, c end
        end
    end end end
    state.bestGuessCell = bestC
end
local function autoFlag()
    if not (Toggles.AutoFlag and Toggles.AutoFlag.Value) then return end
    local r, d, now = Options.FlagRange.Value, Options.FlagDelay.Value, tick()
    if now - lastF < d then return end
    local h = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if not h then return end
    local targets, count = {}, 0
    for c, _ in pairs(state.cells.toFlag) do
        local p = c.part
        if p and not hasF(p) and not (state.clicked[p] and (now - state.clicked[p]) < 3) and (c.pos - h.Position).Magnitude <= r then
            count = count + 1 targets[count] = c
            if count >= 3 then break end
        end
    end
    for i = 1, count do
        local c = targets[i] local p = c.part
        local sp, on = workspace.CurrentCamera:WorldToViewportPoint(c.pos)
        if on then
            local vim = game:GetService("VirtualInputManager")
            state.clicked[p] = now
            vim:SendMouseMoveEvent(sp.X, sp.Y, game)
            vim:SendMouseButtonEvent(sp.X, sp.Y, 0, true, game, 0)
            task.wait(0.04)
            vim:SendMouseButtonEvent(sp.X, sp.Y, 0, false, game, 0)
        end
    end
    if count > 0 then lastF = now end
end
local function applyH(c, col)
    if not c.borders then
        local th, ins = 0.08, 0.05
        local function np() local p=Instance.new("Part") p.Anchored,p.CanCollide,p.CanQuery,p.CanTouch,p.CastShadow,p.Transparency,p.Material,p.Size=true,false,false,false,false,1,Enum.Material.Neon,Vector3.new(1,1,1) return p end
        c.borders = { top = np(), bottom = np(), left = np(), right = np() }
        local f = workspace:FindFirstChild("MinesweeperHighlights") or Instance.new("Folder", workspace) f.Name = "MinesweeperHighlights"
        for _, b in pairs(c.borders) do b.Parent = f end
        if c.part then
            local sz, hx, hz, yf = c.part.Size, c.part.Size.X/2 - ins, c.part.Size.Z/2 - ins, c.part.Size.Y/2 + 0.01
            local t, b, l, r = c.borders.top, c.borders.bottom, c.borders.left, c.borders.right
            t.Size, b.Size, l.Size, r.Size = Vector3.new(sz.X-ins*2, th, th), Vector3.new(sz.X-ins*2, th, th), Vector3.new(th, th, sz.Z-ins*2), Vector3.new(th, th, sz.Z-ins*2)
            t.CFrame, b.CFrame, l.CFrame, r.CFrame = c.part.CFrame*CFrame.new(0, yf, -hz), c.part.CFrame*CFrame.new(0, yf, hz), c.part.CFrame*CFrame.new(-hx, yf, 0), c.part.CFrame*CFrame.new(hx, yf, 0)
        end
    end
    for _, b in pairs(c.borders) do b.Color, b.Transparency = col, 0 end
end
local function updateH()
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
local win = lib:CreateWindow({ Title = "Axis Hub -\nMinesweeper.lua", Footer = "by RwalDev & Plow | 1.8.7", NotifySide = "Right", ShowCustomCursor = true })
local h, m, s = win:AddTab("Home", "house"), win:AddTab("Main", "target"), win:AddTab("Settings", "settings")
local status = h:AddLeftGroupbox("Status") status:AddLabel(string.format("Welcome, %s\nGame: Minesweeper", lp.DisplayName), true) status:AddButton({ Text = "Unload", Func = function() lib:Unload() end })
local perf = h:AddRightGroupbox("Performance") local fpsL, pingL = perf:AddLabel("FPS: ...", true), perf:AddLabel("Ping: ...", true)
local mainB = m:AddLeftGroupbox("Main") mainB:AddToggle("HighlightMines", { Text = "Highlight Mines", Default = false }) mainB:AddToggle("AutoFlag", { Text = "Auto Flag", Default = false }) mainB:AddSlider("FlagRange", { Text = "Auto Flag Range", Default = 16, Min = 0, Max = 16, Rounding = 0 }) mainB:AddSlider("FlagDelay", { Text = "Auto Flag Delay", Default = 0.1, Min = 0, Max = 1, Rounding = 1 }) mainB:AddToggle("BypassAnticheat", { Text = "Bypass Anticheat", Default = true })
local cfgB = s:AddLeftGroupbox("Config") cfgB:AddToggle("KeyMenu", { Default = lib.KeybindFrame.Visible, Text = "Keybind Menu", Callback = function(v) lib.KeybindFrame.Visible = v end }) cfgB:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { Default = "RightControl", NoUI = true, Text = "Menu bind" })
lib.ToggleKeybind = Options.MenuKeybind
local function bypass()
    if not getrawmetatable or not hookmetamethod then return end
    local r = game:GetService("ReplicatedStorage"):FindFirstChild("Patukka")
    if r then local old old = hookmetamethod(game, "__namecall", function(self, ...) local m = getnamecallmethod() if self == r and (m == "InvokeServer" or m == "FireServer") then if Toggles.BypassAnticheat and Toggles.BypassAnticheat.Value then return nil end end return old(self, ...) end) end
end
local lastS, solveInt = 0, 0.1
rs.Heartbeat:Connect(function()
    config.Enabled = Toggles.HighlightMines and Toggles.HighlightMines.Value
    if not config.Enabled then clearB() state.cells.toFlag, state.cells.toClear, state.lastPartCount = {}, {}, -1 return end
    local f = scanB() if not f then return end
    local pc, now = #f:GetChildren(), tick()
    local neb = pc ~= state.lastPartCount if neb then clearB() state.lastPartCount = pc rebuildG(f) end
    if state.grid.w == 0 then return end
    if neb or (now - lastS) >= solveInt then 
        lastS = now 
        updateS(f) 
        updateL() 
        updateG() 
        updateH()
    end
    autoFlag()
end)
rs.RenderStepped:Connect(function(dt)
    elap = elap + dt
    frames = frames + 1
    if elap >= 1 then 
        fpsL:SetText("FPS: " .. floor(frames/elap + 0.5)) 
        local p = floor(lp:GetNetworkPing() * 1000 + 0.5)
        pingL:SetText("Ping: " .. p .. " ms") 
        frames, elap = 0, 0 
    end
end)
theme:SetLibrary(lib) save:SetLibrary(lib) save:IgnoreThemeSettings() save:SetIgnoreIndexes({ "MenuKeybind" })
theme:SetFolder("PlowsScriptHub") save:SetFolder("PlowsScriptHub/Minesweeper")
save:BuildConfigSection(s) theme:ApplyToTab(s) save:LoadAutoloadConfig()
lib:OnUnload(function() clearB() local f = workspace:FindFirstChild("MinesweeperHighlights") if f then f:Destroy() end end)
pcall(bypass)
