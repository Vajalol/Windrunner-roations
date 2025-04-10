local addonName, WR = ...

-- SpellQueue module - handles spell queuing and casting with predictive capabilities
local Queue = {}
WR.Queue = Queue

-- State
local state = {
    queue = {}, -- The spell queue, entries are {spellId, target, timestamp, priority, conditions}
    processingQueue = false,
    lastProcessTime = 0,
    processInterval = 0.02, -- Process the queue every 20ms for better responsiveness
    maxQueueSize = 5, -- Maximum number of spells in the queue
    maxAge = 1.5, -- Maximum age of a queued spell in seconds
    gcdRemaining = 0, -- Estimated GCD remaining in seconds
    lastCastSpellId = nil, -- Last spell that was cast
    lastCastTime = 0, -- Time of the last cast
    lastCastSuccess = false, -- Whether the last cast was successful
    castHistory = {}, -- History of recent casts for analysis
    castHistoryMaxSize = 20, -- Maximum size of cast history
    predictiveCastingEnabled = true, -- Whether predictive casting is enabled
    currentCastPrediction = nil, -- Current spell predicted to be cast next
}

-- Initialize the spell queue
function Queue:Initialize()
    -- Create a frame for OnUpdate event
    local frame = CreateFrame("Frame")
    frame:SetScript("OnUpdate", function(self, elapsed)
        Queue:OnUpdate(elapsed)
    end)
    
    -- Register for combat log events
    frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    frame:RegisterEvent("UNIT_SPELLCAST_FAILED")
    frame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
    
    frame:SetScript("OnEvent", function(self, event, ...)
        if event == "COMBAT_LOG_EVENT_UNFILTERED" then
            Queue:COMBAT_LOG_EVENT_UNFILTERED(CombatLogGetCurrentEventInfo())
        elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
            Queue:UNIT_SPELLCAST_SUCCEEDED(...)
        elseif event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_INTERRUPTED" then
            Queue:UNIT_SPELLCAST_FAILED(...)
        end
    end)
    
    WR:Debug("Spell queue initialized")
end

-- Process the COMBAT_LOG_EVENT_UNFILTERED event
function Queue:COMBAT_LOG_EVENT_UNFILTERED(...)
    local timestamp, event, _, sourceGUID, _, _, _, destGUID, _, _, _, spellID, spellName = ...
    
    -- Only process events from the player
    if sourceGUID ~= UnitGUID("player") then return end
    
    if event == "SPELL_CAST_SUCCESS" then
        self:OnSpellCastSuccess(spellID, spellName, destGUID)
    elseif event == "SPELL_CAST_FAILED" then
        self:OnSpellCastFailed(spellID, spellName, destGUID)
    end
end

-- Process the UNIT_SPELLCAST_SUCCEEDED event
function Queue:UNIT_SPELLCAST_SUCCEEDED(unit, castGUID, spellID)
    if unit ~= "player" then return end
    
    local spellName = GetSpellInfo(spellID)
    self:OnSpellCastSuccess(spellID, spellName, nil)
end

-- Process the UNIT_SPELLCAST_FAILED event
function Queue:UNIT_SPELLCAST_FAILED(unit, castGUID, spellID)
    if unit ~= "player" then return end
    
    local spellName = GetSpellInfo(spellID)
    self:OnSpellCastFailed(spellID, spellName, nil)
end

-- Handle successful spell casts
function Queue:OnSpellCastSuccess(spellID, spellName, destGUID)
    state.lastCastSpellId = spellID
    state.lastCastTime = GetTime()
    state.lastCastSuccess = true
    
    -- Update GCD
    local gcdStart, gcdDuration = GetSpellCooldown(61304) -- GCD spell ID
    if gcdStart and gcdDuration then
        state.gcdRemaining = (gcdStart + gcdDuration) - GetTime()
        if state.gcdRemaining < 0 then state.gcdRemaining = 0 end
    end
    
    -- Remove this spell from the queue if it's there
    for i = #state.queue, 1, -1 do
        if state.queue[i].spellId == spellID then
            table.remove(state.queue, i)
            break
        end
    end
    
    WR:Debug("Successfully cast", spellName, "(", spellID, ")")
end

-- Handle failed spell casts
function Queue:OnSpellCastFailed(spellID, spellName, destGUID)
    if state.lastCastSpellId == spellID and GetTime() - state.lastCastTime < 0.5 then
        state.lastCastSuccess = false
    end
    
    WR:Debug("Failed to cast", spellName, "(", spellID, ")")
end

-- OnUpdate handler - process the spell queue
function Queue:OnUpdate(elapsed)
    local now = GetTime()
    
    -- Don't process too frequently
    if now - state.lastProcessTime < state.processInterval then return end
    state.lastProcessTime = now
    
    -- Don't process if already processing
    if state.processingQueue then return end
    
    state.processingQueue = true
    
    -- Update GCD remaining
    local gcdStart, gcdDuration = GetSpellCooldown(61304) -- GCD spell ID
    if gcdStart and gcdDuration then
        state.gcdRemaining = (gcdStart + gcdDuration) - now
        if state.gcdRemaining < 0 then state.gcdRemaining = 0 end
    end
    
    -- Process the queue
    self:ProcessQueue()
    
    state.processingQueue = false
end

-- Process the spell queue
function Queue:ProcessQueue()
    if #state.queue == 0 then return end
    
    local now = GetTime()
    
    -- Remove expired entries
    for i = #state.queue, 1, -1 do
        if now - state.queue[i].timestamp > state.maxAge then
            table.remove(state.queue, i)
        end
    end
    
    -- Sort the queue by priority (higher priority first)
    table.sort(state.queue, function(a, b)
        return (a.priority or 0) > (b.priority or 0)
    end)
    
    -- Try to cast the next spell in the queue
    if #state.queue > 0 then
        -- Use our GCD module if available
        local canCast = state.gcdRemaining <= 0
        if WR.GCD and WR.GCD.CanQueueSpell then
            canCast = WR.GCD:CanQueueSpell()
        end
        
        if canCast then
            -- Find the highest priority spell that meets its conditions
            local spellToCast = nil
            local spellIndex = nil
            
            for i, spell in ipairs(state.queue) do
                -- Check if the spell meets its conditions
                local conditionsMet = true
                
                if spell.conditions then
                    for _, condition in ipairs(spell.conditions) do
                        if type(condition) == "function" then
                            if not condition() then
                                conditionsMet = false
                                break
                            end
                        end
                    end
                end
                
                -- Check if the spell is castable
                if conditionsMet and WR.API:IsSpellCastable(spell.spellId, spell.target) then
                    spellToCast = spell
                    spellIndex = i
                    break
                end
            end
            
            -- Cast the spell if found
            if spellToCast then
                local success = false
                
                if spellToCast.target then
                    success = WR.API:CastSpell(spellToCast.spellId, spellToCast.target)
                else
                    success = WR.API:CastSpell(spellToCast.spellId)
                end
                
                -- If the cast was attempted, remove it from the queue and record in history
                if success then
                    -- Add to cast history before removing from queue
                    self:AddToCastHistory(spellToCast.spellId, spellToCast.target, spellToCast.priority)
                    
                    -- Remove the spell from the queue
                    table.remove(state.queue, spellIndex)
                    
                    -- Perform prediction for next spell
                    if state.predictiveCastingEnabled then
                        self:PredictNextCast()
                    end
                end
            end
        end
    end
end

-- Add a spell cast to the history
function Queue:AddToCastHistory(spellId, target, priority)
    -- Don't track certain utility spells
    local ignoreSpells = {
        -- Common utility spells that don't factor into rotation predictions
        [1459] = true, -- Arcane Intellect
        [21562] = true, -- Power Word: Fortitude
        -- Add more as needed
    }
    
    if ignoreSpells[spellId] then return end
    
    -- Add to cast history
    table.insert(state.castHistory, {
        spellId = spellId,
        target = target,
        timestamp = GetTime(),
        priority = priority
    })
    
    -- Keep history at max size
    if #state.castHistory > state.castHistoryMaxSize then
        table.remove(state.castHistory, 1)
    end
end

-- Predict the next cast based on history
function Queue:PredictNextCast()
    -- Skip prediction if disabled or insufficient history
    if not state.predictiveCastingEnabled or #state.castHistory < 5 then
        state.currentCastPrediction = nil
        return
    end
    
    -- Simple prediction based on common spell sequences
    local sequences = {}
    
    -- Check for common 2-spell sequences
    for i = 1, #state.castHistory - 1 do
        local spell1 = state.castHistory[i].spellId
        local spell2 = state.castHistory[i+1].spellId
        
        local key = tostring(spell1) .. "-" .. tostring(spell2)
        sequences[key] = (sequences[key] or 0) + 1
    end
    
    -- Check for common 3-spell sequences for better accuracy
    for i = 1, #state.castHistory - 2 do
        local spell1 = state.castHistory[i].spellId
        local spell2 = state.castHistory[i+1].spellId
        local spell3 = state.castHistory[i+2].spellId
        
        local key = tostring(spell1) .. "-" .. tostring(spell2) .. "-" .. tostring(spell3)
        sequences[key] = (sequences[key] or 0) + 2  -- Weight 3-spell sequences higher
    end
    
    -- Identify most common sequences
    local bestSequence = nil
    local bestCount = 0
    
    for sequence, count in pairs(sequences) do
        if count > bestCount then
            bestSequence = sequence
            bestCount = count
        end
    end
    
    -- Extract prediction from best sequence
    if bestSequence and bestCount >= 2 then
        local parts = {}
        for part in bestSequence:gmatch("[^-]+") do
            table.insert(parts, part)
        end
        
        local lastCastId = state.lastCastSpellId
        
        -- For 2-spell sequences
        if #parts == 2 and tonumber(parts[1]) == lastCastId then
            state.currentCastPrediction = tonumber(parts[2])
            return
        end
        
        -- For 3-spell sequences
        if #parts == 3 then
            local secondLast = nil
            if #state.castHistory >= 2 then
                secondLast = state.castHistory[#state.castHistory-1].spellId
            end
            
            if secondLast and tonumber(parts[1]) == secondLast and tonumber(parts[2]) == lastCastId then
                state.currentCastPrediction = tonumber(parts[3])
                return
            end
        end
    end
    
    state.currentCastPrediction = nil
end

-- Queue a spell for casting with priority and conditions
function Queue:QueueSpell(spellId, target, priority, conditions)
    -- Don't queue if spell is not valid
    if not spellId or not GetSpellInfo(spellId) then
        WR:Debug("Attempted to queue invalid spell:", spellId)
        return false
    end
    
    -- Default priority
    priority = priority or 1
    
    -- Check if spell is already in the queue
    for i, spellData in ipairs(state.queue) do
        if spellData.spellId == spellId then
            -- Update the entry with new info
            spellData.timestamp = GetTime()
            spellData.target = target
            spellData.priority = priority
            spellData.conditions = conditions
            return true
        end
    end
    
    -- Check if queue is full
    if #state.queue >= state.maxQueueSize then
        -- Instead of removing oldest, remove lowest priority
        table.sort(state.queue, function(a, b)
            return (a.priority or 0) < (b.priority or 0)
        end)
        
        table.remove(state.queue, 1)
    end
    
    -- Add the spell to the queue
    table.insert(state.queue, {
        spellId = spellId,
        target = target,
        timestamp = GetTime(),
        priority = priority,
        conditions = conditions
    })
    
    WR:Debug("Queued spell:", GetSpellInfo(spellId), "(", spellId, ") Priority:", priority, target or "no target")
    
    return true
end

-- Simple version for backward compatibility
function Queue:QueueSpellSimple(spellId, target)
    return self:QueueSpell(spellId, target, 1, nil)
end

-- Clear the spell queue
function Queue:ClearQueue()
    wipe(state.queue)
    WR:Debug("Spell queue cleared")
    return true
end

-- Get the current queue size
function Queue:GetQueueSize()
    return #state.queue
end

-- Get the current spell queue
function Queue:GetQueue()
    return state.queue
end

-- Check if a spell is in the queue
function Queue:IsSpellQueued(spellId)
    for i, spellData in ipairs(state.queue) do
        if spellData.spellId == spellId then
            return true
        end
    end
    return false
end

-- Cast a spell immediately, bypassing the queue
function Queue:CastSpell(spellId, target)
    -- Don't cast if spell is not valid
    if not spellId or not GetSpellInfo(spellId) then
        WR:Debug("Attempted to cast invalid spell:", spellId)
        return false
    end
    
    -- Try to cast the spell
    local success = false
    
    if target then
        success = WR.API:CastSpell(spellId, target)
    else
        success = WR.API:CastSpell(spellId)
    end
    
    if success then
        WR:Debug("Casting spell:", GetSpellInfo(spellId), "(", spellId, ")", target or "no target")
    end
    
    return success
end

-- Get the estimated GCD remaining
function Queue:GetGCDRemaining()
    local now = GetTime()
    local gcdStart, gcdDuration = GetSpellCooldown(61304) -- GCD spell ID
    
    if gcdStart and gcdDuration then
        local remaining = (gcdStart + gcdDuration) - now
        if remaining < 0 then remaining = 0 end
        return remaining
    end
    
    return 0
end

-- Get last cast information
function Queue:GetLastCast()
    return state.lastCastSpellId, state.lastCastTime, state.lastCastSuccess
end

-- Check if we're currently casting
function Queue:IsCasting()
    return state.gcdRemaining > 0 or UnitCastingInfo("player") ~= nil
end
