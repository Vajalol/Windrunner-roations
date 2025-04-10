local addonName, WR = ...

-- SpellQueue module - handles spell queuing and casting
local Queue = {}
WR.Queue = Queue

-- State
local state = {
    queue = {}, -- The spell queue, entries are {spellId, target, timestamp}
    processingQueue = false,
    lastProcessTime = 0,
    processInterval = 0.05, -- Process the queue every 50ms
    maxQueueSize = 3, -- Maximum number of spells in the queue
    maxAge = 1.0, -- Maximum age of a queued spell in seconds
    gcdRemaining = 0, -- Estimated GCD remaining in seconds
    lastCastSpellId = nil, -- Last spell that was cast
    lastCastTime = 0, -- Time of the last cast
    lastCastSuccess = false, -- Whether the last cast was successful
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
    
    -- Try to cast the next spell in the queue
    if #state.queue > 0 and state.gcdRemaining <= 0 then
        local nextSpell = state.queue[1]
        
        -- Try to cast the spell
        local success = false
        
        if nextSpell.target then
            success = WR.API:CastSpell(nextSpell.spellId, nextSpell.target)
        else
            success = WR.API:CastSpell(nextSpell.spellId)
        end
        
        -- If the cast was attempted (success or fail), remove it from the queue
        if success then
            table.remove(state.queue, 1)
        end
    end
end

-- Queue a spell for casting
function Queue:QueueSpell(spellId, target)
    -- Don't queue if spell is not valid
    if not spellId or not GetSpellInfo(spellId) then
        WR:Debug("Attempted to queue invalid spell:", spellId)
        return false
    end
    
    -- Check if spell is already in the queue
    for i, spellData in ipairs(state.queue) do
        if spellData.spellId == spellId then
            -- Update the timestamp and target for existing entry
            spellData.timestamp = GetTime()
            spellData.target = target
            return true
        end
    end
    
    -- Check if queue is full
    if #state.queue >= state.maxQueueSize then
        -- Remove the oldest entry
        table.remove(state.queue, 1)
    end
    
    -- Add the spell to the queue
    table.insert(state.queue, {
        spellId = spellId,
        target = target,
        timestamp = GetTime()
    })
    
    WR:Debug("Queued spell:", GetSpellInfo(spellId), "(", spellId, ")", target or "no target")
    
    return true
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
