-- SpellQueue module for testing - handles spell queuing and casting with predictive capabilities
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
    -- In test environment, we don't create frames
    print("SpellQueue initialized (test environment)")
end

-- Process the spell queue
function Queue:ProcessQueue()
    if #state.queue == 0 then 
        print("Queue is empty")
        return 
    end
    
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
                -- In test environment, all conditions are met
                local conditionsMet = true
                
                -- Check if the spell is castable (always true in test)
                if conditionsMet then
                    spellToCast = spell
                    spellIndex = i
                    break
                end
            end
            
            -- Cast the spell if found
            if spellToCast then
                local success = false
                
                -- In test environment, the cast is always successful
                print("Casting spell:", GetSpellInfo(spellToCast.spellId), "with priority", spellToCast.priority)
                success = true
                
                -- If the cast was attempted, remove it from the queue and record in history
                if success then
                    -- Add to cast history before removing from queue
                    self:AddToCastHistory(spellToCast.spellId, spellToCast.target, spellToCast.priority)
                    
                    -- Remove the spell from the queue
                    table.remove(state.queue, spellIndex)
                    
                    -- Update last cast information
                    state.lastCastSpellId = spellToCast.spellId
                    state.lastCastTime = now
                    state.lastCastSuccess = true
                    
                    -- Perform prediction for next spell
                    if state.predictiveCastingEnabled then
                        self:PredictNextCast()
                    end
                end
            end
        else
            print("Can't cast yet - GCD or global lockout active")
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
    
    print("Added spell to cast history:", GetSpellInfo(spellId))
end

-- Predict the next cast based on history
function Queue:PredictNextCast()
    -- Skip prediction if disabled or insufficient history
    if not state.predictiveCastingEnabled or #state.castHistory < 5 then
        state.currentCastPrediction = nil
        return
    end
    
    -- Basic implementation for testing
    -- In a real scenario, this would analyze patterns
    if #state.castHistory > 0 then
        state.currentCastPrediction = state.castHistory[1].spellId
        print("Predicted next cast:", GetSpellInfo(state.currentCastPrediction))
    end
end

-- Queue a spell for casting with priority and conditions
function Queue:QueueSpell(spellId, target, priority, conditions)
    -- Don't queue if spell is not valid
    if not spellId or not GetSpellInfo(spellId) then
        print("Attempted to queue invalid spell:", spellId)
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
            print("Updated queued spell:", GetSpellInfo(spellId), "with priority", priority)
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
    
    print("Queued spell:", GetSpellInfo(spellId), "with priority", priority)
    
    return true
end

-- Simple version for backward compatibility
function Queue:QueueSpellSimple(spellId, target)
    return self:QueueSpell(spellId, target, 1, nil)
end

-- Clear the spell queue
function Queue:ClearQueue()
    -- Use table assignment instead of wipe for better compatibility
    state.queue = {}
    print("Spell queue cleared")
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
        print("Attempted to cast invalid spell:", spellId)
        return false
    end
    
    -- In test environment, the cast is always successful
    local spellName = GetSpellInfo(spellId)
    print("Casting spell directly:", spellName, "on", target or "no target")
    
    -- Update last cast information
    state.lastCastSpellId = spellId
    state.lastCastTime = GetTime()
    state.lastCastSuccess = true
    
    -- Add to cast history
    self:AddToCastHistory(spellId, target, 99) -- High priority for direct casts
    
    return true
end

-- Get the estimated GCD remaining
function Queue:GetGCDRemaining()
    -- Use the GCD module if available
    if WR.GCD and WR.GCD.GetGCDRemaining then
        return WR.GCD:GetGCDRemaining()
    end
    
    -- Otherwise use our internal tracking
    local now = GetTime()
    local remaining = state.gcdRemaining
    
    if remaining < 0 then remaining = 0 end
    return remaining
end

-- Get last cast information
function Queue:GetLastCast()
    return state.lastCastSpellId, state.lastCastTime, state.lastCastSuccess
end

-- Check if we're currently casting
function Queue:IsCasting()
    -- Use the GCD module if available
    if WR.GCD and WR.GCD.IsCasting then
        return WR.GCD:IsCasting()
    end
    
    return state.gcdRemaining > 0
end

-- Get the current prediction
function Queue:GetCurrentPrediction()
    return state.currentCastPrediction
end

-- Enable/disable predictive casting
function Queue:SetPredictiveCasting(enabled)
    state.predictiveCastingEnabled = enabled
    print("Predictive casting " .. (enabled and "enabled" or "disabled"))
    return true
end

-- Initialize the module
Queue:Initialize()

return Queue