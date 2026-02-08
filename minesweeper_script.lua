local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/"
local lib = loadstring(game:HttpGet(repo .. "Library.lua"))()
local theme = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local save = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local rs, plrs = game:GetService("RunService"), game:GetService("Players")
local lp = plrs.LocalPlayer
local Toggles, Options = lib.Toggles, lib.Options

local abs, floor, huge, sqrt, max, min, clock = math.abs, math.floor, math.huge, math.sqrt, math.max, math.min, os.clock
local tsort, tinsert, tremove = table.sort, table.insert, table.remove
local bit_extract = bit32.extract
local vec3, cfnew, inst = Vector3.new, CFrame.new, Instance.new

local config = { Enabled = false, GuessHelper = true, DistanceWeight = 0.1, EdgePenalty = 0.05 }
local state = { 
    cells = { grid = {}, numbered = {}, toFlag = {}, toClear = {} }, 
    grid = { w = 0, h = 0 }, 
    lastPartCount = -1, 
    bestGuessCell = nil, 
    dirtyFlag = true, 
    lastF = {}, 
    lastS = {} 
}

local COLOR_SAFE = Color3.fromRGB(0, 255, 0)
local COLOR_MINE = Color3.fromRGB(255, 0, 0)
local COLOR_GUESS = Color3.fromRGB(0, 170, 255)
local COLOR_WRONG = Color3.fromRGB(255, 0, 255)

local function cluster(vals, d) 
    local res = {} 
    if #vals == 0 then return res end 
    local cur, count = vals[1], 1 
    for i = 2, #vals do 
        if abs(vals[i] - cur) <= d then 
            count = count + 1 
            cur = cur + (vals[i] - cur) / count 
        else 
            tinsert(res, cur) 
            cur, count = vals[i], 1 
        end 
    end 
    tinsert(res, cur) 
    return res 
end

local function median(vals) 
    if #vals == 0 then return nil end 
    tsort(vals) 
    return vals[floor((#vals + 1) / 2)] 
end

local function estS(coords) 
    if #coords < 3 then return 4 end 
    local d = {} 
    for i = 2, #coords do 
        d[#d+1] = abs(coords[i] - coords[i-1]) 
    end 
    return median(d) or 4 
end

local function findI(t, s) 
    local bI, bD = 1, huge 
    for i = 1, #s do 
        local d = abs(t - s[i]) 
        if d < bD then 
            bD, bI = d, i 
        end 
    end 
    return bI - 1 
end

local function hasF(p) 
    return p:FindFirstChild("Flag", true) ~= nil 
end

local cachedB = nil
local function scanB()
    if cachedB and cachedB.Parent then return cachedB end
    local f = workspace:FindFirstChild("Flag") 
    local p = f and f:FindFirstChild("Parts") 
    if p then 
        cachedB = p 
        return p 
    end
    local ch = workspace:GetChildren() 
    for i = 1, #ch do 
        local v = ch[i] 
        if v:IsA("Folder") and #v:GetChildren() > 50 then 
            local p1 = v:GetChildren()[1] 
            if p1 and p1:IsA("BasePart") and p1.Name == "Part" then 
                cachedB = v 
                return v 
            end 
        end 
    end
    return nil
end

local function clearB()
    if not state.cells.grid then return end
    for x = 0, (state.grid.w or 0) - 1 do 
        local col = state.cells.grid[x] 
        if col then 
            for z = 0, (state.grid.h or 0) - 1 do 
                local c = col[z] 
                if c then 
                    if c.borders then 
                        for _, b in pairs(c.borders) do b:Destroy() end 
                        c.borders = nil 
                    end 
                    c.isHighlightedMine, c.isHighlightedSafe, c.isHighlightedGuess, c.isWrongFlag = false, false, false, false 
                end 
            end 
        end 
    end
    state.cells.toFlag, state.cells.toClear, state.lastF, state.lastS = {}, {}, {}, {}
end

local function rebuildG(folder)
    clearB() 
    state.cells.grid, state.grid.w, state.grid.h = {}, 0, 0
    local pts = folder:GetChildren() 
    if #pts == 0 then return end
    
    local pD, sY = {}, 0
    for _, p in ipairs(pts) do 
        if p:IsA("BasePart") then 
            tinsert(pD, {p = p, pos = p.Position}) 
            sY = sY + p.Position.Y 
        end 
    end
    
    local xs, zs = {}, {} 
    for i = 1, #pD do xs[i], zs[i] = pD[i].pos.X, pD[i].pos.Z end
    tsort(xs) 
    tsort(zs) 
    
    local w, h = estS(xs) * 0.6, estS(zs) * 0.6
    local ux, uz = cluster(xs, w), cluster(zs, h) 
    state.grid.w, state.grid.h = #ux, #uz
    
    if state.grid.w == 0 or state.grid.h == 0 then return end
    
    local ay = sY / #pD
    for x = 0, state.grid.w - 1 do 
        state.cells.grid[x] = {} 
        for z = 0, state.grid.h - 1 do 
            state.cells.grid[x][z] = { 
                ix = x, iz = z, 
                pos = vec3(ux[x+1], ay, uz[z+1]), 
                part = nil, state = "unknown", 
                covered = true, neigh = {} 
            } 
        end 
    end
    
    for _, d in ipairs(pD) do 
        local xi, zi = findI(d.pos.X, ux), findI(d.pos.Z, uz) 
        local c = state.cells.grid[xi][zi] 
        if not c.part or (d.pos - vec3(ux[xi+1], d.pos.Y, uz[zi+1])).Magnitude < (c.part.Position - vec3(ux[xi+1], c.part.Position.Y, uz[zi+1])).Magnitude then 
            c.part, c.pos = d.p, d.pos 
        end 
    end
    
    for z = 0, state.grid.h - 1 do 
        for x = 0, state.grid.w - 1 do 
            local c = state.cells.grid[x][z] 
            for dz = -1, 1 do 
                for dx = -1, 1 do 
                    if dx ~= 0 or dz ~= 0 then 
                        local nx, nz = x + dx, z + dz 
                        if nx >= 0 and nx < state.grid.w and nz >= 0 and nz < state.grid.h then 
                            tinsert(c.neigh, state.cells.grid[nx][nz]) 
                        end 
                    end 
                end 
            end 
        end 
    end
end

local function updateS()
    state.cells.numbered = {} 
    local grid = state.cells.grid 
    if state.grid.w == 0 or not grid then return end
    
    for x = 0, state.grid.w - 1 do 
        local col = grid[x] 
        if col then 
            for z = 0, state.grid.h - 1 do
                local c = col[z] 
                if c.part then
                    if c.state == "number" then 
                        tinsert(state.cells.numbered, c)
                    else
                        c.state, c.number, c.covered = "unknown", nil, true
                        local ng = c._ng or c.part:FindFirstChild("NumberGui")
                        if ng then 
                            c._ng = ng 
                            local lbl = c._tl or ng:FindFirstChild("TextLabel") 
                            if lbl then 
                                c._tl = lbl 
                                local t = lbl.Text 
                                if t ~= "" then 
                                    local n = tonumber(t) 
                                    if n then 
                                        c.number, c.covered, c.state = n, false, "number" 
                                        tinsert(state.cells.numbered, c) 
                                    end 
                                end 
                            end 
                        end
                        if c.state ~= "number" then
                            if c.covered then 
                                local cl = c.part.Color 
                                local r, g, b = cl.R*255, cl.G*255, cl.B*255 
                                if r >= 170 and g >= 170 and b >= 170 and abs(r-g) <= 60 and abs(g-b) <= 60 and abs(r-b) <= 60 then 
                                    c.covered = false 
                                end 
                            end
                            if c.covered and hasF(c.part) then 
                                c.state = "flagged" 
                            end
                        end
                    end
                end
            end 
        end 
    end
end

local function countR(c, fS) 
    local r = c.number or 0 
    local n = c.neigh 
    for j = 1, #n do 
        if fS[n[j]] then r = r - 1 end 
    end 
    return r 
end

local function getC(num, fS, sS)
    local bds, map = {}, {}
    for j = 1, #num do
        local ncValue = num[j] 
        local r, ns, n = ncValue._cr, {}, ncValue.neigh
        for k = 1, #n do 
            local t = n[k] 
            if not fS[t] and t.state ~= "number" and t.covered ~= false and not sS[t] then 
                tinsert(ns, t) 
                if not map[t] then 
                    map[t] = true 
                    tinsert(bds, t) 
                end 
            end 
        end
        ncValue._cn = ns
    end
    
    local adj, vis, comps = {}, {}, {} 
    for j = 1, #bds do adj[bds[j]] = {} end
    
    for j = 1, #num do 
        local ns = num[j]._cn 
        for i = 1, #ns do 
            for k = i+1, #ns do 
                local u, v = ns[i], ns[k] 
                adj[u][v], adj[v][u] = true, true 
            end 
        end 
    end
    
    for j = 1, #bds do
        local u = bds[j] 
        if not vis[u] then
            local comp, q = {}, {u} 
            vis[u] = true
            while #q > 0 do 
                local cur = tremove(q) 
                tinsert(comp, cur) 
                for n in pairs(adj[cur] or {}) do 
                    if not vis[n] then 
                        vis[n] = true 
                        tinsert(q, n) 
                    end 
                end 
            end
            tinsert(comps, comp)
        end
    end
    return comps
end

local function solveCSP(fS, sS)
    local num, tS = state.cells.numbered, clock()
    for j = 1, #num do 
        local ncValue = num[j] 
        local r, n = ncValue.number or 0, ncValue.neigh 
        for k = 1, #n do 
            if fS[n[k]] then r = r - 1 end 
        end 
        ncValue._cr = r 
    end
    
    local comps = getC(num, fS, sS) 
    if #comps == 0 then return end
    
    local bgt = 0.04
    for i = 1, #comps do
        if clock() - tS > bgt then break end
        
        local v = comps[i] 
        local nV = #v 
        if nV == 0 then continue end
        
        local deg = {} 
        for j = 1, nV do deg[v[j]] = 0 end
        for j = 1, #num do 
            local n = num[j]._cn 
            for k = 1, #n do 
                if deg[n[k]] then deg[n[k]] = deg[n[k]] + 1 end 
            end 
        end
        tsort(v, function(a, b) return deg[a] > deg[b] end)
        
        local map, cts, cCts = {}, {}, {} 
        for j = 1, nV do map[v[j]], cCts[j] = j, {} end
        
        local cons = {}
        for j = 1, #num do 
            local ncValue, cv = num[j], {} 
            for k = 1, #ncValue._cn do 
                local m = map[ncValue._cn[k]] 
                if m then cv[#cv+1] = m end 
            end 
            if #cv > 0 then 
                tsort(cv) 
                cons[#cons+1] = {v = cv, r = ncValue._cr, cur = 0, un = #cv} 
            end 
        end
        
        local vT = {} 
        for j = 1, nV do vT[j] = {} end
        for j = 1, #cons do 
            for _, vi in ipairs(cons[j].v) do tinsert(vT[vi], cons[j]) end 
        end
        
        local cur, solC, abrt = {}, 0, false
        local function bt(idx)
            if solC >= 50000 or abrt then return end
            if (solC % 512 == 0) and (clock() - tS > bgt) then abrt = true return end
            if idx > nV then 
                solC = solC + 1 
                for j = 1, nV do 
                    if cur[j] == 1 then cCts[j][1] = (cCts[j][1] or 0) + 1 end 
                end 
                return 
            end
            
            local t = vT[idx]
            for val = 0, 1 do
                local ok = true
                for j = 1, #t do 
                    local c = t[j] 
                    local nsValue = c.cur + val 
                    if nsValue > c.r or (nsValue + c.un - 1) < c.r then ok = false break end 
                end
                
                if ok then 
                    cur[idx] = val 
                    for j = 1, #t do 
                        local c = t[j] 
                        c.cur, c.un = c.cur + val, c.un - 1 
                    end 
                    bt(idx + 1) 
                    if abrt then return end 
                    for j = 1, #t do 
                        local c = t[j] 
                        c.cur, c.un = c.cur - val, c.un + 1 
                    end 
                end
            end
        end
        
        if nV <= 14 then
            for m = 0, 2^nV - 1 do
                local ok = true 
                for j = 1, #cons do 
                    local sVal = 0 
                    local cV = cons[j].v 
                    for k = 1, #cV do 
                        if bit_extract(m, cV[k]-1) == 1 then sVal = sVal + 1 end 
                    end 
                    if sVal ~= cons[j].r then ok = false break end 
                end
                if ok then 
                    solC = solC + 1 
                    for j = 1, nV do 
                        if bit_extract(m, j-1) == 1 then cCts[j][1] = (cCts[j][1] or 0) + 1 end 
                    end 
                end
            end
        else 
            bt(1) 
        end
        
        if solC > 0 then 
            for vi = 1, #v do 
                local mCValue = cCts[vi][1] or 0 
                if mCValue == solC then 
                    fS[v[vi]] = true 
                elseif mCValue == 0 then 
                    sS[v[vi]] = true 
                end 
                v[vi]._prob = mCValue / solC 
            end 
        end
    end
end

local function applyS(cA, cB, uA, uB, fS, sS)
    local sA, sB, iS = {}, {}, 0 
    for _, u in ipairs(uA) do sA[u] = true end
    for _, u in ipairs(uB) do 
        if sA[u] then 
            iS = iS + 1 
            sA[u] = false 
            sB[u] = false 
        else 
            sB[u] = true 
        end 
    end
    
    local oA, oB, iL = {}, {}, {} 
    for _, u in ipairs(uA) do 
        if sA[u] ~= false then oA[#oA+1] = u else iL[#iL+1] = u end 
    end
    for _, u in ipairs(uB) do 
        if sB[u] then oB[#oB+1] = u end 
    end
    
    if #iL == 0 then return end 
    local rA, rB = countR(cA, fS), countR(cB, fS) 
    local minI, maxI = max(0, rA - #oA, rB - #oB), min(rA, rB, #iL)
    
    if minI == maxI then
        if rA - minI == 0 then 
            for _, u in ipairs(oA) do sS[u] = true end 
        elseif rA - minI == #oA then 
            for _, u in ipairs(oA) do fS[u] = true end 
        end
        if rB - minI == 0 then 
            for _, u in ipairs(oB) do sS[u] = true end 
        elseif rB - minI == #oB then 
            for _, u in ipairs(oB) do fS[u] = true end 
        end
        return true
    end 
    return false
end

local function updateL()
    if state.grid.w == 0 then state.cells.toFlag, state.cells.toClear = {}, {} return end
    local num = state.cells.numbered 
    if #num == 0 then return end
    
    local fS, sS, ch, it, tS = {}, {}, true, 0, clock()
    for x=0,state.grid.w-1 do 
        local col=state.cells.grid[x] 
        if col then 
            for z=0,state.grid.h-1 do 
                local c=col[z] 
                if c then c._prob=nil end 
            end 
        end 
    end
    
    while ch and it < 32 and (clock() - tS < 0.05) do
        ch, it = false, it + 1
        for j = 1, #num do
            local c = num[j] 
            local unk, flg, n = {}, 0, c.neigh
            for k = 1, #n do 
                local tValue = n[k] 
                if fS[tValue] then 
                    flg = flg + 1 
                elseif not sS[tValue] and tValue.state ~= "number" and tValue.covered ~= false then 
                    tinsert(unk, tValue) 
                end 
            end
            local r = (c.number or 0) - flg
            if r > 0 and r == #unk then 
                for k = 1, #unk do 
                    local uValue = unk[k] 
                    if not fS[uValue] then fS[uValue], ch = true, true end 
                end
            elseif r == 0 and #unk > 0 then 
                for k = 1, #unk do 
                    local uValue = unk[k] 
                    if not sS[uValue] then sS[uValue], ch = true, true end 
                end 
            end
        end
        
        if it % 2 == 0 then
            for i = 1, #num do 
                local a = num[i] 
                local uA, n1 = {}, a.neigh 
                for k = 1, #n1 do 
                    local tValue = n1[k] 
                    if not fS[tValue] and not sS[tValue] and tValue.state ~= "number" and tValue.covered ~= false then 
                        uA[#uA+1] = tValue 
                    end 
                end
                if #uA > 0 then
                    local checked = {} 
                    for k = 1, #n1 do 
                        local nValue = n1[k] 
                        if nValue.state == "number" and nValue ~= a and not checked[nValue] then
                            checked[nValue] = true 
                            local uB, n2 = {}, nValue.neigh 
                            for m = 1, #n2 do 
                                local tValue = n2[m] 
                                if not fS[tValue] and not sS[tValue] and tValue.state ~= "number" and tValue.covered ~= false then 
                                    uB[#uB+1] = tValue 
                                end 
                            end
                            if #uB > 0 and applyS(a, nValue, uA, uB, fS, sS) then ch = true end
                        end 
                    end
                end
            end
        end
        
        if not ch then 
            local oldF, oldS = 0, 0 
            for _ in pairs(fS) do oldF = oldF + 1 end 
            for _ in pairs(sS) do oldS = oldS + 1 end 
            solveCSP(fS, sS) 
            local newF, newS = 0, 0 
            for _ in pairs(fS) do newF = newF + 1 end 
            for _ in pairs(sS) do newS = newS + 1 end 
            if newF ~= oldF or newS ~= oldS then ch = true end 
        end
    end
    
    local changed = false
    for c in pairs(fS) do if not state.lastF[c] then changed = true break end end
    if not changed then for c in pairs(state.lastF) do if not fS[c] then changed = true break end end end
    if not changed then for c in pairs(sS) do if not state.lastS[c] then changed = true break end end end
    if not changed then for c in pairs(state.lastS) do if not sS[c] then changed = true break end end end
    
    if changed then 
        state.cells.toFlag, state.cells.toClear, state.lastF, state.lastS, state.dirtyFlag = fS, sS, fS, sS, true 
    end
end

local function updateG()
    state.bestGuessCell = nil 
    if not config.GuessHelper or state.grid.w == 0 then return end
    
    local kF, uK = 0, 0 
    for x=0,state.grid.w-1 do 
        local col=state.cells.grid[x] 
        if col then 
            for z=0,state.grid.h-1 do 
                local c=col[z] 
                if c.state == "flagged" or state.cells.toFlag[c] then 
                    kF=kF+1 
                elseif c.state ~= "number" and c.covered ~= false and not state.cells.toClear[c] then 
                    uK=uK+1 
                end 
            end 
        end 
    end
    
    local gDValue = uK > 0 and (max(0, 40-kF)/uK) or 0.15
    local pPValue = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") and lp.Character.HumanoidRootPart.Position
    local maxDValue, bestCValue, bestSValue = pPValue and sqrt((state.grid.w*5)^2 + (state.grid.h*5)^2) or 1, nil, nil
    
    for x=0,state.grid.w-1 do 
        local col=state.cells.grid[x] 
        if col then 
            for z=0,state.grid.h-1 do
                local c = col[z] 
                if c and c.part and c.state ~= "number" and c.covered ~= false and not hasF(c.part) and not state.cells.toFlag[c] and not state.cells.toClear[c] then
                    local pbValue = c._prob
                    if not pbValue then
                        local vCValue, pSValue, hasNIdxValue, nValue = 0, 0, false, c.neigh
                        for k = 1, #nValue do
                            local tValue = nValue[k] 
                            if tValue.state == "number" and tValue.number and tValue.number > 0 then
                                hasNIdxValue = true 
                                local fsValue, luValue, n3Value = 0, 0, tValue.neigh
                                for m = 1, #n3Value do 
                                    local nnValue = n3Value[m] 
                                    if (nnValue.part and hasF(nnValue.part)) or state.cells.toFlag[nnValue] then 
                                        fsValue = fsValue + 1 
                                    elseif nnValue.state ~= "number" and nnValue.covered ~= false and not state.cells.toFlag[nnValue] and not state.cells.toClear[nnValue] then 
                                        luValue = luValue + 1 
                                    end 
                                end
                                local rValue = tValue.number - fsValue 
                                if rValue <= 0 then 
                                    vCValue = vCValue + 1 
                                elseif luValue > 0 then 
                                    pSValue = pSValue + (rValue/luValue)
                                    vCValue = vCValue + 1 
                                end
                            end
                        end
                        pbValue = (hasNIdxValue and vCValue > 0) and (pSValue / vCValue) or gDValue
                    end
                    local sValue = pbValue + ((x == 0 or x == state.grid.w-1 or z == 0 or z == state.grid.h-1) and config.EdgePenalty or 0)
                    local uNValue, cNValue, n4Value = 0, 0, c.neigh 
                    for k = 1, #n4Value do 
                        local tValue = n4Value[k] 
                        if tValue.state ~= "number" and tValue.covered ~= false and not state.cells.toFlag[tValue] and not state.cells.toClear[tValue] then 
                            uNValue = uNValue + 1 
                        end 
                        if tValue.state == "number" then 
                            cNValue = cNValue + 1 
                        end 
                    end
                    sValue = sValue - (uNValue * 0.01) - (cNValue * 0.05) + (sqrt((x-state.grid.w/2)^2 + (z-state.grid.h/2)^2) / (state.grid.w + state.grid.h)) * 0.05
                    if pPValue then sValue = sValue + ((c.pos - pPValue).Magnitude / maxDValue) * config.DistanceWeight end
                    if not bestSValue or sValue < bestSValue then bestSValue, bestCValue = sValue, c end
                end
            end 
        end 
    end
    if state.bestGuessCell ~= bestCValue then state.bestGuessCell, state.dirtyFlag = bestCValue, true end
end

local function applyH(c, colValue)
    if not c.borders then
        local thValue, insValue = 0.15, 0.02
        local function np() 
            local pValue=inst("Part") 
            pValue.Anchored,pValue.CanCollide,pValue.CanQuery,pValue.CanTouch,pValue.CastShadow,pValue.Transparency,pValue.Material,pValue.Size=true,false,false,false,false,1,Enum.Material.Neon,vec3(1,1,1) return pValue 
        end
        c.borders = { top = np(), bottom = np(), left = np(), right = np() }
        local fValue = workspace:FindFirstChild("MinesweeperHighlights") or inst("Folder", workspace) 
        fValue.Name = "MinesweeperHighlights"
        for _, bValue in pairs(c.borders) do bValue.Parent = fValue end
        if c.part then
            local szValue, hxValue, hzValue, yfValue = c.part.Size, c.part.Size.X/2 - insValue, c.part.Size.Z/2 - insValue, c.part.Size.Y/2 + 0.01
            local tValue, bValue, lValue, rValue = c.borders.top, c.borders.bottom, c.borders.left, c.borders.right
            tValue.Size, bValue.Size, lValue.Size, rValue.Size = vec3(szValue.X-insValue*2, thValue, thValue), vec3(szValue.X-insValue*2, thValue, thValue), vec3(thValue, thValue, szValue.Z-insValue*2), vec3(thValue, thValue, szValue.Z-insValue*2)
            tValue.CFrame, bValue.CFrame, lValue.CFrame, rValue.CFrame = c.part.CFrame*cfnew(0, yfValue, -hzValue), c.part.CFrame*cfnew(0, yfValue, hzValue), c.part.CFrame*cfnew(-hxValue, yfValue, 0), c.part.CFrame*cfnew(hxValue, yfValue, 0)
        end
    end
    for _, bValue in pairs(c.borders) do bValue.Color, bValue.Transparency = colValue, 0 end
end

local function updateH()
    if not state.dirtyFlag then return end
    state.dirtyFlag = false
    local bGValue, enValue = state.bestGuessCell, Toggles.HighlightMines and Toggles.HighlightMines.Value
    local gridValue = state.cells.grid 
    if not gridValue then return end
    
    for x = 0, state.grid.w - 1 do 
        local colValue = gridValue[x] 
        if colValue then 
            for z = 0, state.grid.h - 1 do
                local cValue = colValue[z] 
                if cValue and cValue.part then
                    local visValue = cValue.covered and cValue.state ~= "number"
                    if not visValue then 
                        if cValue.isHighlightedMine or cValue.isHighlightedSafe or cValue.isHighlightedGuess or cValue.isWrongFlag then 
                            if cValue.borders then 
                                for _, bValue in pairs(cValue.borders) do bValue.Transparency = 1 end 
                            end 
                            cValue.isHighlightedMine, cValue.isHighlightedSafe, cValue.isHighlightedGuess, cValue.isWrongFlag = false, false, false, false 
                        end
                    else
                        local iMValue, iSValue, iGValue, iWValue = state.cells.toFlag[cValue] ~= nil, state.cells.toClear[cValue] ~= nil, cValue == bGValue and config.GuessHelper, cValue.isWrongFlag
                        if iMValue ~= cValue.isHighlightedMine or iSValue ~= cValue.isHighlightedSafe or iGValue ~= cValue.isHighlightedGuess or iWValue ~= cValue.isWrongFlag then
                            cValue.isHighlightedMine, cValue.isHighlightedSafe, cValue.isHighlightedGuess, cValue.isWrongFlag = iMValue, iSValue, iGValue, iWValue
                            if enValue and (iMValue or iSValue or iGValue or iWValue) then 
                                applyH(cValue, iWValue and COLOR_WRONG or (iMValue and COLOR_MINE) or (iSValue and COLOR_SAFE) or COLOR_GUESS)
                            elseif cValue.borders then 
                                for _, bValue in pairs(cValue.borders) do bValue.Transparency = 1 end 
                            end
                        end
                    end
                end
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
    Footer = "by RwalDev & Plow | 1.9.8", 	 
    NotifySide = "Right", 
    ShowCustomCursor = true 
})

local hTab, mTab, sTab = win:AddTab("Home", "house"), win:AddTab("Main", "bomb"), win:AddTab("Settings", "settings")

local statusGrp = hTab:AddLeftGroupbox("Status") 
statusGrp:AddLabel(string.format("Welcome, %s\nGame: bLockerman's minesweeper", lp.DisplayName), true) 
statusGrp:AddButton({ Text = "Unload", Func = function() lib:Unload() end })

local perfGrp = hTab:AddRightGroupbox("Performance") 
local fpsL, pingL = perfGrp:AddLabel("FPS: ...", true), perfGrp:AddLabel("Ping: ...", true)

local mainGrp = mTab:AddLeftGroupbox("Main") 
mainGrp:AddToggle("HighlightMines", { Text = "Highlight Mines", Default = false }) 
mainGrp:AddToggle("BypassAnticheat", { Text = "Bypass Anticheat", Default = true })

local cfgGrp = sTab:AddLeftGroupbox("Config") 
cfgGrp:AddToggle("KeyMenu", { Default = lib.KeybindFrame.Visible, Text = "Keybind Menu", Callback = function(v) lib.KeybindFrame.Visible = v end }) 
cfgGrp:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { Default = "RightControl", NoUI = true, Text = "Menu bind" })

lib.ToggleKeybind = Options.MenuKeybind

local lastSVal, solveIntVal, elVal, frVal = 0, 0.1, 0, 0

rs.Heartbeat:Connect(function()
    config.Enabled = Toggles.HighlightMines and Toggles.HighlightMines.Value
    if not config.Enabled then 
        clearB() 
        state.cells.toFlag, state.cells.toClear, state.lastPartCount = {}, {}, -1 
        return 
    end
    
    local folderValue = scanB() 
    if not folderValue then return end
    
    local pcValue, nowValue = #folderValue:GetChildren(), tick()
    local nebValue = pcValue ~= state.lastPartCount 
    if nebValue then 
        clearB() 
        state.lastPartCount = pcValue 
        rebuildG(folderValue) 
    end
    
    if state.grid.w == 0 then return end
    if nebValue or (nowValue - lastSVal) >= solveIntVal then 
        lastSVal = nowValue 
        updateS() 
        updateL() 
        updateG() 
    end
    updateH()
end)

rs.RenderStepped:Connect(function(dt)
    elVal, frVal = elVal + dt, frVal + 1
    if elVal >= 0.5 then 
        fpsL:SetText("FPS: " .. floor(frVal / elVal + 0.5))
        local netValue = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]
        local pngValue = 0 
        pcall(function() pngValue = netValue:GetValue() end)
        pingL:SetText("Ping: " .. floor(pngValue) .. " ms")
        elVal, frVal = 0, 0 
    end
end)

theme:SetLibrary(lib) 
save:SetLibrary(lib) 
save:IgnoreThemeSettings() 
save:SetIgnoreIndexes({ "MenuKeybind" })
theme:SetFolder("PlowsScriptHub") 
save:SetFolder("PlowsScriptHub/Minesweeper")
save:BuildConfigSection(sTab) 
theme:ApplyToTab(sTab) 
save:LoadAutoloadConfig()

lib:OnUnload(function() 
    clearB() 
    local fValue = workspace:FindFirstChild("MinesweeperHighlights") 
    if fValue then fValue:Destroy() end 
end)

pcall(function() 
    if not getrawmetatable or not hookmetamethod then return end 
    local rValue = game:GetService("ReplicatedStorage"):FindFirstChild("Patukka") 
    if rValue then 
        local oldNamecall 
        oldNamecall = hookmetamethod(game, "__namecall", function(self, ...) 
            local methodValue = getnamecallmethod() 
            if self == rValue and (methodValue == "InvokeServer" or methodValue == "FireServer") then 
                local bypassToggle = Toggles.BypassAnticheat
                if bypassToggle and bypassToggle.Value then return nil end 
            end 
            return oldNamecall(self, ...) 
        end) 
    end 
end)
