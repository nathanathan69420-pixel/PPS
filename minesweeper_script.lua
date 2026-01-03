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

local config = {
    Enabled = false,
    GuessHelper = true,
    Debug = false,
    TotalMines = 25,
    DistanceWeight = 0.1,
    EdgePenalty = 0.05
}

local state = {
    cells = {
        grid = {},
        numbered = {},
        toFlag = {},
        toClear = {}
    },
    grid = { w = 0, h = 0 },
    lastPartCount = -1,
    lastNumberedCount = 0,
    bestGuessCell = nil,
    bestGuessScore = nil
}

local highlightFolder = workspace:FindFirstChild("MinesweeperHighlights")
if not highlightFolder then
    highlightFolder = Instance.new("Folder")
    highlightFolder.Name = "MinesweeperHighlights"
    highlightFolder.Parent = workspace
end

local COLOR_SAFE = Color3.fromRGB(0, 255, 0)
local COLOR_MINE = Color3.fromRGB(255, 0, 0)
local COLOR_GUESS = Color3.fromRGB(0, 170, 255)
local COLOR_WRONG = Color3.fromRGB(255, 0, 255)

local abs, floor, huge = math.abs, math.floor, math.huge
local tsort = table.sort

local function clusterAndAverage(values, maxDiff)
    local clusters = {}
    local n = #values
    if n == 0 then return clusters end
    local current = values[1]
    local count = 1
    for i = 2, n do
        local v = values[i]
        if abs(v - current) <= maxDiff then
            count = count + 1
            current = current + (v - current) / count
        else
            table.insert(clusters, current)
            current = v
            count = 1
        end
    end
    table.insert(clusters, current)
    return clusters
end

local function median(values)
    local n = #values
    if n == 0 then return nil end
    tsort(values)
    return values[floor((n + 1) / 2)]
end

local function estimateSpacing(coords)
    if #coords < 3 then return 4 end
    local diffs = {}
    for i = 2, #coords do diffs[#diffs + 1] = abs(coords[i] - coords[i-1]) end
    return median(diffs) or 4
end

local function findClosestIndex(target, sorted)
    local bestIdx = 1
    local bestDist = huge
    for i = 1, #sorted do
        local dist = abs(target - sorted[i])
        if dist < bestDist then
            bestDist = dist
            bestIdx = i
        end
    end
    return bestIdx - 1
end

local function hasFlagChild(parent)
    for _, child in ipairs(parent:GetChildren()) do
        if child.Name:sub(1, 4) == "Flag" then return true end
    end
    return false
end

local function isEligibleForClick(cell)
    return not (cell.state == "number") and cell.covered ~= false
end

local function scanForBoard()
    local folder = workspace:FindFirstChild("Flag") and workspace.Flag:FindFirstChild("Parts")
    if folder then return folder end
    for _, f in ipairs(workspace:GetChildren()) do
        if f:IsA("Folder") and #f:GetChildren() > 50 then
            local child = f:GetChildren()[1]
            if child:IsA("BasePart") and child.Name == "Part" then return f end
        end
    end
    return nil
end

local function clearAllCellBorders()
    if not state.cells.grid then return end
    for x = 0, state.grid.w - 1 do
        local column = state.cells.grid[x]
        if column then
            for z = 0, state.grid.h - 1 do
                local cell = column[z]
                if cell then
                    if cell.borders then
                        for _, b in pairs(cell.borders) do b:Destroy() end
                        cell.borders = nil
                    end
                    cell.isHighlightedMine = false
                    cell.isHighlightedSafe = false
                    cell.isHighlightedGuess = false
                    cell.isWrongFlag = false
                end
            end
        end
    end
end

local function rebuildGridFromParts(folder)
    clearAllCellBorders()
    state.cells.grid = {}
    state.grid.w = 0
    state.grid.h = 0

    local parts = folder:GetChildren()
    if #parts == 0 then return end
    
    local allPositions = {}
    local sumY = 0

    for _, part in ipairs(parts) do
        if part:IsA("BasePart") then
            local pos = part.Position
            table.insert(allPositions, {part = part, pos = pos})
            sumY = sumY + pos.Y
        end
    end

    local xs, zs = {}, {}
    for _, data in ipairs(allPositions) do
        xs[#xs + 1] = data.pos.X
        zs[#zs + 1] = data.pos.Z
    end

    tsort(xs)
    tsort(zs)

    local cellWidth = estimateSpacing(xs) * 0.6
    local cellHeight = estimateSpacing(zs) * 0.6
    local uniqueX = clusterAndAverage(xs, cellWidth)
    local uniqueZ = clusterAndAverage(zs, cellHeight)

    state.grid.w = #uniqueX
    state.grid.h = #uniqueZ
    if state.grid.w == 0 or state.grid.h == 0 then return end

    local avgY = sumY / #allPositions

    for x = 0, state.grid.w - 1 do
        state.cells.grid[x] = {}
        for z = 0, state.grid.h - 1 do
            state.cells.grid[x][z] = {
                ix = x, iz = z,
                pos = Vector3.new(uniqueX[x+1], avgY, uniqueZ[z+1]),
                part = nil,
                state = "unknown",
                number = nil,
                covered = true,
                color = nil,
                neigh = {},
                borders = nil,
                isHighlightedMine = false,
                isHighlightedSafe = false,
                isHighlightedGuess = false,
                isWrongFlag = false,
                lastHighlightChange = 0
            }
        end
    end

    for _, data in ipairs(allPositions) do
        local pos = data.pos
        local part = data.part
        local xIdx = findClosestIndex(pos.X, uniqueX)
        local zIdx = findClosestIndex(pos.Z, uniqueZ)
        local cell = state.cells.grid[xIdx][zIdx]
        
        if not cell.part then
            cell.part = part
            cell.pos = pos
        else
            local currDist = (cell.part.Position - Vector3.new(uniqueX[xIdx+1], cell.part.Position.Y, uniqueZ[zIdx+1])).Magnitude
            local newDist = (pos - Vector3.new(uniqueX[xIdx+1], pos.Y, uniqueZ[zIdx+1])).Magnitude
            if newDist < currDist then
                cell.part = part
                cell.pos = pos
            end
        end
    end

    for z = 0, state.grid.h - 1 do
        for x = 0, state.grid.w - 1 do
            local cell = state.cells.grid[x][z]
            for dz = -1, 1 do
                for dx = -1, 1 do
                    if dx == 0 and dz == 0 then continue end
                    local nx, nz = x + dx, z + dz
                    if nx >= 0 and nx < state.grid.w and nz >= 0 and nz < state.grid.h then
                        table.insert(cell.neigh, state.cells.grid[nx][nz])
                    end
                end
            end
        end
    end
end

local function updateCellStates(folder)
    state.cells.numbered = {}
    if state.grid.w == 0 then return end

    local colorCounts = {}
    local distinctColors = {}
    
    -- Pass 1: Identify "Covered" color (most common color)
    for x = 0, state.grid.w - 1 do
        local column = state.cells.grid[x]
        if column then
            for z = 0, state.grid.h - 1 do
                local cell = column[z]
                if cell and cell.part then
                    local c = cell.part.Color
                    -- quantization to handle slight precision errors
                    local r, g, b = floor(c.R*20), floor(c.G*20), floor(c.B*20)
                    local key = r.."_"..g.."_"..b
                    if not colorCounts[key] then 
                        colorCounts[key] = 0 
                        distinctColors[key] = c
                    end
                    colorCounts[key] = colorCounts[key] + 1
                end
            end
        end
    end
    
    local maxCount = -1
    local coveredColor = nil
    for key, count in pairs(colorCounts) do
        if count > maxCount then
            maxCount = count
            coveredColor = distinctColors[key]
        end
    end

    -- Pass 2: Update states
    for x = 0, state.grid.w - 1 do
        local column = state.cells.grid[x]
        if column then
            for z = 0, state.grid.h - 1 do
                local cell = column[z]
                if cell and cell.part then
                    cell.state = "unknown"
                    cell.number = nil
                    cell.covered = true
                    cell.color = nil

                    local partColor = cell.part.Color
                    cell.color = {R = partColor.R, G = partColor.G, B = partColor.B}

                    local numberGui = cell.part:FindFirstChild("NumberGui")
                    if numberGui then
                        local label = numberGui:FindFirstChild("TextLabel")
                        if label and tonumber(label.Text) then
                            cell.number = tonumber(label.Text)
                            cell.covered = false
                        end
                    end

                    local isRevealed = (cell.number ~= nil)
                    
                    if not isRevealed and coveredColor then
                        local r1, g1, b1 = partColor.R, partColor.G, partColor.B
                        local r2, g2, b2 = coveredColor.R, coveredColor.G, coveredColor.B
                        local dist = abs(r1-r2) + abs(g1-g2) + abs(b1-b2)
                        if dist > 0.05 then
                             isRevealed = true
                        end
                    end

                    if isRevealed then cell.covered = false end
                    if hasFlagChild(cell.part) then cell.state = "flagged" end

                    if cell.number and not cell.covered then
                        cell.state = "number"
                        table.insert(state.cells.numbered, cell)
                    end
                end
            end
        end
    end
end

local function getUnknownNeighborsExcluding(cell, flaggedSet, safeSet)
    local result = {}
    for _, n in ipairs(cell.neigh) do
        if not flaggedSet[n] and not safeSet[n] and isEligibleForClick(n) then
            table.insert(result, n)
        end
    end
    return result
end

local function countRemainingMines(cell, flaggedSet)
    local remaining = cell.number or 0
    for _, n in ipairs(cell.neigh) do
        if flaggedSet[n] or n.state == "flagged" then
            remaining = remaining - 1
        end
    end
    return remaining
end

local function getBoundaryComponents(numbered, flaggedSet, safeSet)
    local allUnknowns = {}
    local totalFlags = 0
    if config.TotalMines and config.TotalMines > 0 then
        local count = 0
        for x = 0, state.grid.w - 1 do
            if state.cells.grid[x] then
                for z = 0, state.grid.h - 1 do
                    local cell = state.cells.grid[x][z]
                    if cell then
                        if cell.state == "flagged" or flaggedSet[cell] then
                            totalFlags = totalFlags + 1
                        elseif isEligibleForClick(cell) and not safeSet[cell] then
                            table.insert(allUnknowns, cell)
                        end
                    end
                end
            end
        end
        
        if #allUnknowns <= 26 then
            allUnknowns._isGlobal = true
            allUnknowns._remainingMines = config.TotalMines - totalFlags
            local comp = { allUnknowns }
            for _, numCell in ipairs(numbered) do
                local rem = (numCell.number or 0)
                local neighbors = {}
                for _, n in ipairs(numCell.neigh) do
                    if n.state == "flagged" then
                        table.insert(neighbors, n)
                    elseif flaggedSet[n] then
                        rem = rem - 1
                    elseif not safeSet[n] and isEligibleForClick(n) then
                        table.insert(neighbors, n)
                    end
                end
                numCell._csp_rem = rem
                numCell._csp_neigh = neighbors
            end
            return comp
        end
    end

    local boundaryCells = {}
    local cellMap = {}
    
    for _, numCell in ipairs(numbered) do
        local rem = (numCell.number or 0)
        local neighbors = {}
        for _, n in ipairs(numCell.neigh) do
            if n.state == "flagged" then
                table.insert(neighbors, n)
                if not cellMap[n] then
                    cellMap[n] = true
                    table.insert(boundaryCells, n)
                end
            elseif flaggedSet[n] then
                rem = rem - 1
            elseif not safeSet[n] and isEligibleForClick(n) then
                table.insert(neighbors, n)
                if not cellMap[n] then
                    cellMap[n] = true
                    table.insert(boundaryCells, n)
                end
            end
        end
        numCell._csp_rem = rem
        numCell._csp_neigh = neighbors
    end
    
    local adj = {}
    for _, u in ipairs(boundaryCells) do adj[u] = {} end
    
    for _, numCell in ipairs(numbered) do
        local ns = numCell._csp_neigh
        if #ns > 0 then
            for i = 1, #ns do
                for j = i+1, #ns do
                    local u, v = ns[i], ns[j]
                    adj[u][v] = true
                    adj[v][u] = true
                end
            end
        end
    end
    
    local visited = {}
    local components = {}
    
    for _, u in ipairs(boundaryCells) do
        if not visited[u] then
            local comp = {}
            local q = {u}
            visited[u] = true
            while #q > 0 do
                local curr = table.remove(q)
                table.insert(comp, curr)
                for neighbor in pairs(adj[curr] or {}) do
                    if not visited[neighbor] then
                        visited[neighbor] = true
                        table.insert(q, neighbor)
                    end
                end
            end
            table.insert(components, comp)
        end
    end
    
    return components
end

local function solveCSP(flaggedSet, safeSet)
    local numbered = state.cells.numbered
    local components = getBoundaryComponents(numbered, flaggedSet, safeSet)
    local tStart = os.clock()
    
    local compData = {}
    local totalCompVars = 0
    local allVarsSet = {}

    for _, vars in ipairs(components) do
        local degrees = {}
        for _, v in ipairs(vars) do 
            degrees[v] = 0 
            allVarsSet[v] = true
        end
        totalCompVars = totalCompVars + #vars
        for _, numCell in ipairs(numbered) do
            for _, n in ipairs(numCell._csp_neigh) do
                if degrees[n] then degrees[n] = degrees[n] + 1 end
            end
        end
        table.sort(vars, function(a, b) return degrees[a] > degrees[b] end)
        
        local nVars = #vars
        if nVars > 0 then
            local solutions = {}
            local solutionCount = 0
            local MAX_SOLUTIONS = 100000 
            local varMap = {}
            for i, v in ipairs(vars) do varMap[v] = i end
            
            local constraints = {}
            for _, numCell in ipairs(numbered) do
                local relevant = false
                for _, n in ipairs(numCell._csp_neigh) do
                    if varMap[n] then relevant = true break end
                end
                if relevant then
                    local cVars = {}
                    for _, n in ipairs(numCell._csp_neigh) do
                        if varMap[n] then table.insert(cVars, varMap[n]) end
                    end
                    table.sort(cVars) 
                    table.insert(constraints, { vars = cVars, rem = numCell._csp_rem })
                end
            end
            
            if vars._isGlobal then
                local allVars = {}
                for i = 1, nVars do table.insert(allVars, i) end
                table.insert(constraints, { vars = allVars, rem = vars._remainingMines })
            end
            
            local current = {}
            local aborted = false
            local counts = {} 
            local cellCounts = {} 
            for i=1, nVars do cellCounts[i] = {} end

            local function backtrack(idx)
                if solutionCount >= MAX_SOLUTIONS then return end
                if (solutionCount % 100 == 0) and (os.clock() - tStart > 0.1) then aborted = true return end
                
                if idx > nVars then
                    solutionCount = solutionCount + 1
                    local mines = 0
                    for i = 1, nVars do mines = mines + current[i] end
                    
                    counts[mines] = (counts[mines] or 0) + 1
                    for i = 1, nVars do
                        if current[i] == 1 then
                            cellCounts[i][mines] = (cellCounts[i][mines] or 0) + 1
                        end
                    end
                    
                    if not vars._solutions then vars._solutions = {} end
                    if #vars._solutions < 2000 then 
                        local sol = {}
                        for i = 1, nVars do sol[i] = current[i] end
                        table.insert(vars._solutions, sol)
                    end
                    return
                end
                
                for val = 0, 1 do
                    current[idx] = val
                    local consistent = true
                    for _, c in ipairs(constraints) do
                        local sum = 0
                        local unassigned = 0
                        for _, vIdx in ipairs(c.vars) do
                            if vIdx <= idx then sum = sum + current[vIdx]
                            else unassigned = unassigned + 1 end
                        end
                        if sum > c.rem then consistent = false break end
                        if (sum + unassigned) < c.rem then consistent = false break end
                    end
                    if consistent then
                        backtrack(idx + 1)
                        if aborted or solutionCount >= MAX_SOLUTIONS then return end
                    end
                end
            end
            
            backtrack(1)
            
            if not aborted and solutionCount > 0 then
                table.insert(compData, {
                    vars = vars,
                    counts = counts,
                    cellCounts = cellCounts,
                    total = solutionCount
                })
            end
        end
    end

    if #compData > 0 then
        local validCounts = {}
        for i, data in ipairs(compData) do
             validCounts[i] = {}
             for k in pairs(data.counts) do validCounts[i][k] = true end
        end

        if config.TotalMines then
            local knownFlags = 0
            local totalUnknowns = 0
            for x = 0, state.grid.w - 1 do
                if state.cells.grid[x] then
                    for z = 0, state.grid.h - 1 do
                        local cell = state.cells.grid[x][z]
                        if cell then
                            if cell.state == "flagged" or flaggedSet[cell] then knownFlags = knownFlags + 1
                            elseif isEligibleForClick(cell) and not safeSet[cell] then totalUnknowns = totalUnknowns + 1 end
                        end
                    end
                end
            end
            
            local targetMines = config.TotalMines - knownFlags
            local slack = totalUnknowns - totalCompVars
            local minSlack, maxSlack = 0, slack
            if slack < 0 then slack = 0 minSlack = 0 maxSlack = 0 end 
            
            local dp = { [0] = true } 
            
            for i, data in ipairs(compData) do
                local newDp = {}
                for currentSum, _ in pairs(dp) do
                    for k in pairs(data.counts) do
                        local nextSum = currentSum + k
                        if nextSum <= targetMines then 
                             newDp[nextSum] = true
                        end
                    end
                end
                dp = newDp
            end
            
            local finalValidSums = {}
            for s in pairs(dp) do
                if s + maxSlack >= targetMines and s + minSlack <= targetMines then
                    finalValidSums[s] = true
                end
            end
            
            local prunedCounts = {}
            for i = 1, #compData do prunedCounts[i] = {} end

            local function prune(idx, currentSum)
                if idx > #compData then return finalValidSums[currentSum] == true end
                
                local data = compData[idx]
                local isValid = false
                for k in pairs(data.counts) do
                    if prune(idx + 1, currentSum + k) then
                        prunedCounts[idx][k] = true
                        isValid = true
                    end
                end
                return isValid
            end
            
            if prune(1, 0) then
                validCounts = prunedCounts
            end
        end

        for i, data in ipairs(compData) do
            local totalValidSolutions = 0
            for k, count in pairs(data.counts) do
                if validCounts[i][k] then totalValidSolutions = totalValidSolutions + count end
            end
            
            if totalValidSolutions > 0 then
                for vIdx, v in ipairs(data.vars) do
                    local mineCount = 0
                    for k, count in pairs(data.counts) do
                        if validCounts[i][k] then
                           mineCount = mineCount + (data.cellCounts[vIdx][k] or 0)
                        end
                    end
                    
                    if mineCount == totalValidSolutions then
                        if not flaggedSet[v] then flaggedSet[v] = true end
                    elseif mineCount == 0 then
                        if not safeSet[v] then safeSet[v] = true end
                        if v.state == "flagged" then v.isWrongFlag = true end
                    end
                    v._prob = mineCount / totalValidSolutions
                end
            end
        end
    end
end

local function applySimpleDeductionRule(cellA, cellB, unknownsA, unknownsB, flaggedSet, safeSet)
    local setA = {}
    for _, u in ipairs(unknownsA) do setA[u] = true end
    local onlyA, onlyB = {}, {}
    local inter = {}
    
    for _, u in ipairs(unknownsB) do
        if setA[u] then 
            setA[u] = nil
            table.insert(inter, u)
        else 
            table.insert(onlyB, u) 
        end
    end
    for u in pairs(setA) do table.insert(onlyA, u) end

    local minesA = countRemainingMines(cellA, flaggedSet)
    local minesB = countRemainingMines(cellB, flaggedSet)

    if #onlyA == 0 and #onlyB > 0 then
        local diff = minesB - minesA
        if diff == 0 then for _, u in ipairs(onlyB) do safeSet[u] = true end
        elseif diff == #onlyB then for _, u in ipairs(onlyB) do flaggedSet[u] = true end end
    elseif #onlyB == 0 and #onlyA > 0 then
        local diff = minesA - minesB
        if diff == 0 then for _, u in ipairs(onlyA) do safeSet[u] = true end
        elseif diff == #onlyA then for _, u in ipairs(onlyA) do flaggedSet[u] = true end end
    end
    
    if minesA == 1 and minesB == 1 then
        if #onlyA == 1 and #inter == 2 and #onlyB == 0 then
            safeSet[onlyA[1]] = true
        elseif #onlyB == 1 and #inter == 2 and #onlyA == 0 then
            safeSet[onlyB[1]] = true
        end
    end
end

local function checkAdjacentNumberedCells(flaggedSet, safeSet)
    local numbered = state.cells.numbered
    local grid = state.cells.grid
    for _, cell in ipairs(numbered) do
        for dz = -1, 1 do
            for dx = -1, 1 do
                if dx == 0 and dz == 0 then continue end
                local nx, nz = cell.ix + dx, cell.iz + dz
                if nx >= 0 and nx < state.grid.w and nz >= 0 and nz < state.grid.h then
                    local adj = grid[nx][nz]
                    if adj and adj.state == "number" then
                        local unknownsThis = getUnknownNeighborsExcluding(cell, flaggedSet, safeSet)
                        local unknownsAdj = getUnknownNeighborsExcluding(adj, flaggedSet, safeSet)
                        if #unknownsThis > 0 and #unknownsAdj > 0 then
                            applySimpleDeductionRule(cell, adj, unknownsThis, unknownsAdj, flaggedSet, safeSet)
                        end
                    end
                end
            end
        end
    end
end

function getUnknownsForCell(cell, flaggedSet, safeSet) 
    return getUnknownNeighborsExcluding(cell, flaggedSet, safeSet)
end

local function updateLogic()
    if state.grid.w == 0 then
        state.cells.toFlag = {}
        state.cells.toClear = {}
        return
    end
    local numbered = state.cells.numbered
    if #numbered == 0 then return end
    
    local knownFlags = {}
    for x = 0, state.grid.w - 1 do
        local col = state.cells.grid[x]
        if col then
            for z = 0, state.grid.h - 1 do
                local cell = col[z]
                if cell and cell.state == "flagged" then knownFlags[cell] = true end
            end
        end
    end

    local changed, iterations = true, 0
    while changed and iterations < 64 do
        changed = false
        iterations = iterations + 1

        for _, cell in ipairs(numbered) do
            local unknowns = {}
            local flagCount = 0
            for _, n in ipairs(cell.neigh) do
                if knownFlags[n] or n.state == "flagged" then flagCount = flagCount + 1
                elseif not state.cells.toClear[n] and isEligibleForClick(n) then table.insert(unknowns, n) end
            end
            local remaining = (cell.number or 0) - flagCount
            if remaining > 0 and remaining == #unknowns then
                for _, u in ipairs(unknowns) do
                    if not knownFlags[u] then knownFlags[u] = true changed = true end
                end
            elseif remaining == 0 and #unknowns > 0 then
                for _, u in ipairs(unknowns) do
                    if not state.cells.toClear[u] then state.cells.toClear[u] = true changed = true end
                end
            end
        end

        local preFlags = 0
        local preClears = 0
        for _ in pairs(knownFlags) do preFlags = preFlags + 1 end
        for _ in pairs(state.cells.toClear) do preClears = preClears + 1 end

        checkAdjacentNumberedCells(knownFlags, state.cells.toClear)
        
        local postFlags = 0
        local postClears = 0
        for _ in pairs(knownFlags) do postFlags = postFlags + 1 end
        for _ in pairs(state.cells.toClear) do postClears = postClears + 1 end

        if postFlags ~= preFlags or postClears ~= preClears then
            changed = true
        end

        if not changed then
            solveCSP(knownFlags, state.cells.toClear)
            
            local newFlags = 0
            local newClears = 0
            for _ in pairs(knownFlags) do newFlags = newFlags + 1 end
            for _ in pairs(state.cells.toClear) do newClears = newClears + 1 end
            
            if newFlags ~= postFlags or newClears ~= postClears then
                changed = true
            end
        end
    end
    state.cells.toFlag = knownFlags
end

local function updateGuess()
    state.bestGuessCell = nil
    state.bestGuessScore = nil
    if not config.GuessHelper then return end
    if state.grid.w == 0 then return end

    local knownFlagsCount = 0
    local unknownCount = 0
    for x = 0, state.grid.w - 1 do
        local col = state.cells.grid[x]
        if col then
            for z = 0, state.grid.h - 1 do
                local cell = col[z]
                if cell.state == "flagged" or state.cells.toFlag[cell] then knownFlagsCount = knownFlagsCount + 1
                elseif isEligibleForClick(cell) and not state.cells.toClear[cell] then unknownCount = unknownCount + 1 end
            end
        end
    end
    
    local remainingMines = config.TotalMines - knownFlagsCount
    local globalDensity = unknownCount > 0 and (remainingMines / unknownCount) or 0.15
    local playerPos = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") and lp.Character.HumanoidRootPart.Position
    local maxDistance = playerPos and math.sqrt((state.grid.w * 5)^2 + (state.grid.h * 5)^2) or 1
    
    local bestCell, bestScore = nil, nil

    for x = 0, state.grid.w - 1 do
        local col = state.cells.grid[x]
        if col then
            for z = 0, state.grid.h - 1 do
                local cell = col[z]
                if cell and cell.part and isEligibleForClick(cell) and not hasFlagChild(cell.part) and not state.cells.toFlag[cell] and not state.cells.toClear[cell] then
                    
                    local probResult
                    if cell._prob then
                        probResult = cell._prob
                    else
                        local validCount, probSum = 0, 0
                        local hasNumberedNeighbor = false
                        
                        for _, n in ipairs(cell.neigh) do
                            if n.state == "number" and n.number and n.number > 0 then
                                hasNumberedNeighbor = true
                                local flaggedCount = 0 
                                local unknownCountLocal = 0
                                for _, nn in ipairs(n.neigh) do
                                    if (nn.part and hasFlagChild(nn.part)) or state.cells.toFlag[nn] then flaggedCount = flaggedCount + 1
                                    elseif isEligibleForClick(nn) and not state.cells.toFlag[nn] and not state.cells.toClear[nn] then unknownCountLocal = unknownCountLocal + 1 end
                                end
                                local remaining = n.number - flaggedCount
                                if remaining <= 0 then validCount = validCount + 1 
                                elseif unknownCountLocal > 0 then 
                                    probSum = probSum + (remaining / unknownCountLocal) 
                                    validCount = validCount + 1 
                                end
                            end
                        end
                         
                        if hasNumberedNeighbor and validCount > 0 then
                            probResult = probSum / validCount
                        else
                            probResult = globalDensity
                        end
                    end
                    
                    local score = probResult
                    
                    if (x == 0 or x == state.grid.w - 1 or z == 0 or z == state.grid.h - 1) then score = score + config.EdgePenalty end
                    if playerPos then score = score + ((cell.pos - playerPos).Magnitude / maxDistance) * config.DistanceWeight end
                    
                    if not bestScore or score < bestScore then 
                        bestScore = score 
                        bestCell = cell 
                    end
                end
            end
        end
    end
    state.bestGuessCell = bestCell
    state.bestGuessScore = bestScore
end

local function createBorders(cell)
    local th = 0.15
    local ins = 0.02
    local function newPart()
        local p = Instance.new("Part")
        p.Anchored = true
        p.CanCollide = false
        p.CanQuery = false
        p.CanTouch = false
        p.CastShadow = false
        p.Transparency = 1
        p.Material = Enum.Material.Neon
        p.Size = Vector3.new(1, 1, 1)
        return p
    end
    local borders = { top = newPart(), bottom = newPart(), left = newPart(), right = newPart() }
    cell.borders = borders
    cell._borderThickness = th
    cell._borderInset = ins
    
    local folder = workspace:FindFirstChild("MinesweeperHighlights")
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "MinesweeperHighlights"
        folder.Parent = workspace
    end
    for _, border in pairs(borders) do border.Parent = folder end
    return borders
end

local function updateBorderPositions(cell)
    if not cell.part or not cell.borders then return end
    local sz = cell.part.Size
    local th = cell._borderThickness or 0.15
    local ins = cell._borderInset or 0.02
    local hx, hz = sz.X / 2 - ins, sz.Z / 2 - ins
    local yoff = sz.Y / 2 + 0.01
    local t, b, l, r = cell.borders.top, cell.borders.bottom, cell.borders.left, cell.borders.right
    
    t.Size = Vector3.new(sz.X - ins*2, th, th)
    b.Size = Vector3.new(sz.X - ins*2, th, th)
    l.Size = Vector3.new(th, th, sz.Z - ins*2)
    r.Size = Vector3.new(th, th, sz.Z - ins*2)
    
    t.CFrame = cell.part.CFrame * CFrame.new(0, yoff, -hz)
    b.CFrame = cell.part.CFrame * CFrame.new(0, yoff, hz)
    l.CFrame = cell.part.CFrame * CFrame.new(-hx, yoff, 0)
    r.CFrame = cell.part.CFrame * CFrame.new(hx, yoff, 0)
    
    local folder = workspace:FindFirstChild("MinesweeperHighlights")
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "MinesweeperHighlights"
        folder.Parent = workspace
    end
    if t.Parent ~= folder then
        for _, border in pairs(cell.borders) do border.Parent = folder end
    end
end

local function removeAllHighlights(cell)
    if not cell.borders then return end
    for _, b in pairs(cell.borders) do b.Transparency = 1 end
    cell.isHighlightedMine = false
    cell.isHighlightedSafe = false
    cell.isHighlightedGuess = false
end

local function applyHighlight(cell, color)
    if not cell.borders then createBorders(cell) updateBorderPositions(cell) end
    for _, b in pairs(cell.borders) do
        b.Color = color
        b.Transparency = 0
    end
end

local function updateHighlights()
    local now = tick()
    local bestGuess = state.bestGuessCell
    local en = Toggles.HighlightMines and Toggles.HighlightMines.Value

    for x = 0, state.grid.w - 1 do
        local col = state.cells.grid[x]
        if col then
            for z = 0, state.grid.h - 1 do
                local cell = col[z]
                if cell and cell.part then
                    local isVisible = cell.covered and cell.state ~= "number"
                    if not isVisible then
                        if cell.isHighlightedMine or cell.isHighlightedSafe or cell.isHighlightedGuess or cell.isWrongFlag then
                            removeAllHighlights(cell)
                        end
                    else
                        local isMine = state.cells.toFlag[cell] ~= nil
                        local isSafe = state.cells.toClear[cell] ~= nil
                        local isGuess = bestGuess and cell == bestGuess and config.GuessHelper
                        local isWrong = cell.isWrongFlag

                        local changed = (isMine ~= cell.isHighlightedMine) or 
                                      (isSafe ~= cell.isHighlightedSafe) or 
                                      (isGuess ~= cell.isHighlightedGuess) or 
                                      (isWrong ~= cell.isWrongFlag)

                        if changed then
                            cell.lastHighlightChange = now
                            cell.isHighlightedMine = isMine
                            cell.isHighlightedSafe = isSafe
                            cell.isHighlightedGuess = isGuess
                            cell.isWrongFlag = isWrong
                        end

                        if en and (isMine or isSafe or isGuess or isWrong) then
                            local color
                            if isWrong then color = COLOR_WRONG
                            elseif isMine then color = COLOR_MINE
                            elseif isSafe then color = COLOR_SAFE
                            else color = COLOR_GUESS end
                            applyHighlight(cell, color)
                        else
                            removeAllHighlights(cell)
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
    Footer = "by RwalDev & Plow | 1.8.4 | Discord: .gg/UuyxhqgEVs",
    NotifySide = "Right",
    ShowCustomCursor = true,
})

local home = win:AddTab("Home", "house")
local main = win:AddTab("Main", "target")
local cfg = win:AddTab("Settings", "settings")

local status = home:AddLeftGroupbox("Status")
status:AddLabel(string.format("Welcome, %s\nGame: Minesweeper", lp.DisplayName), true)
status:AddButton({ Text = "Unload", Func = function() lib:Unload() end })

local performance = home:AddRightGroupbox("Performance")
local fpsLbl = performance:AddLabel("FPS: ...", true)
local pingLbl = performance:AddLabel("Ping: ...", true)

local mainBox = main:AddLeftGroupbox("Main")
mainBox:AddToggle("HighlightMines", { Text = "Highlight Mines", Default = false })
mainBox:AddToggle("BypassAnticheat", { Text = "Bypass Anticheat", Default = true })

local cfgBox = cfg:AddLeftGroupbox("Config")
cfgBox:AddToggle("KeyMenu", { Default = lib.KeybindFrame.Visible, Text = "Keybind Menu", Callback = function(v) lib.KeybindFrame.Visible = v end })
cfgBox:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { Default = "RightControl", NoUI = true, Text = "Menu bind" })
lib.ToggleKeybind = lib.Options.MenuKeybind

Toggles = lib.Toggles
Options = lib.Options

local function bypass()
    if not getrawmetatable or not hookmetamethod then return end
    local remote = game:GetService("ReplicatedStorage"):FindFirstChild("Patukka")
    if remote then
        local old
        old = hookmetamethod(game, "__namecall", function(self, ...)
            local m = getnamecallmethod()
            if self == remote and (m == "InvokeServer" or m == "FireServer") then
                if Toggles.BypassAnticheat and Toggles.BypassAnticheat.Value then return nil end
            end
            return old(self, ...)
        end)
    end
end

local lastSolve = 0
local solveInterval = 0.15

rs.Heartbeat:Connect(function()
    config.Enabled = Toggles.HighlightMines and Toggles.HighlightMines.Value
    
    if not config.Enabled then
        clearAllCellBorders()
        state.cells.toFlag = {}
        state.cells.toClear = {}
        state.parts = -1
        return
    end

    local folder = scanForBoard()
    if not folder then return end

    local pc = #folder:GetChildren()
    local now = tick()
    local needsRebuild = pc ~= state.parts

    if needsRebuild then
        clearAllCellBorders()
        state.parts = pc
        rebuildGridFromParts(folder)
    end

    if state.grid.w == 0 then return end
    
    if needsRebuild or (now - lastSolve) >= solveInterval then
        lastSolve = now
        updateCellStates(folder)
        updateLogic()
        updateGuess()
    end
    updateHighlights()
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


theme:SetLibrary(lib)
save:SetLibrary(lib)
save:IgnoreThemeSettings()
save:SetIgnoreIndexes({ "MenuKeybind" })
theme:SetFolder("PlowsScriptHub")
save:SetFolder("PlowsScriptHub/Minesweeper")
save:BuildConfigSection(cfg)
theme:ApplyToTab(cfg)
save:LoadAutoloadConfig()

lib:OnUnload(function()
    if perfConn then perfConn:Disconnect() end
    clearAllCellBorders()
    local f = workspace:FindFirstChild("MinesweeperHighlights")
    if f then f:Destroy() end
end)

pcall(bypass)
