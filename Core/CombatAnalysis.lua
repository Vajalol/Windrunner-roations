local addonName, WR = ...

-- CombatAnalysis module - provides combat performance metrics and suggestions
local CombatAnalysis = {}
WR.CombatAnalysis = CombatAnalysis

-- Constants
local MAX_COMBAT_EVENTS = 1000 -- Maximum number of combat events to store
local MAX_COMBAT_LOGS = 10 -- Maximum number of complete combat logs to store
local DPS_UPDATE_INTERVAL = 0.5 -- Update DPS every 500ms

-- State
local state = {
    inCombat = false,
    combatStartTime = 0,
    combatEndTime = 0,
    currentCombatEvents = {},
    combatLogs = {},
    playerDamage = 0,
    playerDPS = 0,
    lastDPSUpdate = 0,
    castEvents = {},
    missedInterrupts = {},
    avoidableDamage = 0,
    downtime = 0,
    spellUsage = {}, -- Tracking spell usage frequency
    rotationEfficiency = 100, -- Percentage efficiency (0-100)
    suggestions = {}, -- List of improvement suggestions
    analysisCompleted = false,
}

-- Initialize the combat analysis module
function CombatAnalysis:Initialize()
    -- Create a frame for events
    local frame = CreateFrame("Frame")
    
    -- Register for events
    frame:RegisterEvent("PLAYER_REGEN_DISABLED") -- Enter combat
    frame:RegisterEvent("PLAYER_REGEN_ENABLED") -- Leave combat
    frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    frame:RegisterEvent("UNIT_SPELLCAST_FAILED")
    frame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
    
    frame:SetScript("OnEvent", function(self, event, ...)
        if event == "PLAYER_REGEN_DISABLED" then
            CombatAnalysis:StartCombat()
        elseif event == "PLAYER_REGEN_ENABLED" then
            CombatAnalysis:EndCombat()
        elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
            CombatAnalysis:ProcessCombatLogEvent(CombatLogGetCurrentEventInfo())
        elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
            CombatAnalysis:ProcessSpellCastSucceeded(...)
        elseif event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_INTERRUPTED" then
            CombatAnalysis:ProcessSpellCastFailed(...)
        end
    end)
    
    -- Create a frame for OnUpdate event to track DPS
    local updateFrame = CreateFrame("Frame")
    updateFrame:SetScript("OnUpdate", function(self, elapsed)
        CombatAnalysis:OnUpdate(elapsed)
    end)
    
    WR:Debug("Combat Analysis module initialized")
end

-- Start combat tracking
function CombatAnalysis:StartCombat()
    if state.inCombat then return end
    
    state.inCombat = true
    state.combatStartTime = GetTime()
    state.combatEndTime = 0
    state.playerDamage = 0
    state.playerDPS = 0
    state.lastDPSUpdate = GetTime()
    state.avoidableDamage = 0
    state.downtime = 0
    state.analysisCompleted = false
    
    -- Clear current combat events
    wipe(state.currentCombatEvents)
    wipe(state.castEvents)
    wipe(state.missedInterrupts)
    wipe(state.spellUsage)
    wipe(state.suggestions)
    
    WR:Debug("Combat tracking started")
end

-- End combat tracking
function CombatAnalysis:EndCombat()
    if not state.inCombat then return end
    
    state.inCombat = false
    state.combatEndTime = GetTime()
    
    -- Finalize combat log
    local combatDuration = self:GetCombatDuration()
    if combatDuration >= 5 then -- Only save logs for combats longer than 5 seconds
        local combatLog = {
            startTime = state.combatStartTime,
            endTime = state.combatEndTime,
            duration = combatDuration,
            events = table.copy(state.currentCombatEvents),
            damage = state.playerDamage,
            dps = state.playerDPS,
            avoidableDamage = state.avoidableDamage,
            downtime = state.downtime,
            casts = table.copy(state.castEvents),
            missedInterrupts = table.copy(state.missedInterrupts),
            spellUsage = table.copy(state.spellUsage),
        }
        
        -- Add to combat logs
        table.insert(state.combatLogs, 1, combatLog)
        
        -- Limit the number of stored logs
        while #state.combatLogs > MAX_COMBAT_LOGS do
            table.remove(state.combatLogs)
        end
        
        -- Analyze the combat
        self:AnalyzeCombat(combatLog)
    end
    
    WR:Debug("Combat tracking ended - Duration:", combatDuration, "seconds", "DPS:", state.playerDPS)
end

-- Process combat log events
function CombatAnalysis:ProcessCombatLogEvent(...)
    local timestamp, eventType, _, sourceGUID, sourceName, sourceFlags, _, destGUID, destName, destFlags, _, spellID, spellName, spellSchool = ...
    
    -- Only process if in combat
    if not state.inCombat then return end
    
    -- Create event record
    local event = {
        timestamp = timestamp,
        eventType = eventType,
        sourceGUID = sourceGUID,
        sourceName = sourceName,
        sourceFlags = sourceFlags,
        destGUID = destGUID,
        destName = destName,
        destFlags = destFlags,
        spellID = spellID,
        spellName = spellName,
        spellSchool = spellSchool,
    }
    
    -- Add additional parameters based on event type
    if eventType:match("_DAMAGE") then
        event.amount = select(15, ...)
        event.overkill = select(16, ...)
        event.school = select(17, ...)
        event.resisted = select(18, ...)
        event.blocked = select(19, ...)
        event.absorbed = select(20, ...)
        event.critical = select(21, ...)
        event.glancing = select(22, ...)
        event.crushing = select(23, ...)
    elseif eventType:match("_HEAL") then
        event.amount = select(15, ...)
        event.overhealing = select(16, ...)
        event.absorbed = select(17, ...)
        event.critical = select(18, ...)
    elseif eventType:match("_INTERRUPT") then
        event.extraSpellID = select(15, ...)
        event.extraSpellName = select(16, ...)
    end
    
    -- Add to current combat events
    table.insert(state.currentCombatEvents, event)
    
    -- Limit the number of stored events
    if #state.currentCombatEvents > MAX_COMBAT_EVENTS then
        table.remove(state.currentCombatEvents, 1)
    end
    
    -- Process specific events
    if eventType == "SPELL_DAMAGE" or eventType == "RANGE_DAMAGE" or eventType == "SWING_DAMAGE" then
        if sourceGUID == UnitGUID("player") then
            -- Track player damage
            local amount = event.amount or 0
            state.playerDamage = state.playerDamage + amount
            
            -- Track spell usage
            if spellID and spellID > 0 then
                state.spellUsage[spellID] = (state.spellUsage[spellID] or 0) + 1
            end
        end
    elseif eventType == "SPELL_CAST_SUCCESS" then
        if sourceGUID == UnitGUID("player") and spellID and spellID > 0 then
            -- Track player spell casts
            table.insert(state.castEvents, {
                timestamp = GetTime(),
                spellID = spellID,
                spellName = spellName,
            })
            
            -- Limit the number of stored casts
            if #state.castEvents > 100 then
                table.remove(state.castEvents, 1)
            end
        end
    elseif eventType == "SPELL_INTERRUPT" then
        if destGUID ~= UnitGUID("player") and sourceGUID ~= UnitGUID("player") then
            -- Track interrupts that could have been done by the player
            local unit = WR.API:GetUnit(destGUID)
            if unit and unit:Exists() and unit:IsEnemy() and unit:GetDistance() <= 30 then
                -- Check if we had an interrupt available
                local interruptSpellIDs = {
                    -- List of common interrupt spells by class
                    [1] = 6552, -- Pummel (Warrior)
                    [2] = 2139, -- Counterspell (Mage)
                    [3] = 19647, -- Spell Lock (Warlock)
                    [4] = 47528, -- Mind Freeze (Death Knight)
                    [5] = 96231, -- Rebuke (Paladin)
                    [6] = 116705, -- Spear Hand Strike (Monk)
                    [7] = 57994, -- Wind Shear (Shaman)
                    [8] = 147362, -- Counter Shot (Hunter)
                    [9] = 183752, -- Disrupt (Demon Hunter)
                    [10] = 351338, -- Quell (Evoker)
                }
                
                for _, interruptID in ipairs(interruptSpellIDs) do
                    if WR.API:IsSpellCastable(interruptID) then
                        table.insert(state.missedInterrupts, {
                            timestamp = GetTime(),
                            spellID = spellID,
                            spellName = spellName,
                            interruptID = interruptID,
                        })
                        break
                    end
                end
            end
        end
    elseif eventType == "SPELL_DAMAGE" and destGUID == UnitGUID("player") then
        -- Track avoidable damage taken by player
        -- This would need more logic to determine what's truly "avoidable"
        -- For demonstration, we'll track a few common avoidable mechanics
        local avoidableMechanics = {
            -- Specific dungeon mechanics that are avoidable
            -- This would be a larger database in a real implementation
            [12345] = true, -- Example spell ID
        }
        
        if avoidableMechanics[spellID] then
            local amount = event.amount or 0
            state.avoidableDamage = state.avoidableDamage + amount
        end
    end
end

-- Process successful spell casts
function CombatAnalysis:ProcessSpellCastSucceeded(unit, castGUID, spellID)
    if unit ~= "player" or not state.inCombat then return end
    
    -- Track player spell casts
    local spellName = GetSpellInfo(spellID)
    if spellID and spellID > 0 then
        table.insert(state.castEvents, {
            timestamp = GetTime(),
            spellID = spellID,
            spellName = spellName,
        })
        
        -- Limit the number of stored casts
        if #state.castEvents > 100 then
            table.remove(state.castEvents, 1)
        end
        
        -- Track spell usage
        state.spellUsage[spellID] = (state.spellUsage[spellID] or 0) + 1
    end
end

-- Process failed spell casts
function CombatAnalysis:ProcessSpellCastFailed(unit, castGUID, spellID)
    if unit ~= "player" or not state.inCombat then return end
    
    -- Track failed casts (could be used for analysis)
end

-- OnUpdate handler
function CombatAnalysis:OnUpdate(elapsed)
    if not state.inCombat then return end
    
    local now = GetTime()
    
    -- Update DPS periodically
    if now - state.lastDPSUpdate >= DPS_UPDATE_INTERVAL then
        local combatDuration = self:GetCombatDuration()
        if combatDuration > 0 then
            state.playerDPS = state.playerDamage / combatDuration
        end
        state.lastDPSUpdate = now
        
        -- Track downtime (periods with no casting or abilities used)
        local lastCastTime = 0
        if #state.castEvents > 0 then
            lastCastTime = state.castEvents[#state.castEvents].timestamp
        end
        
        -- If it's been more than 2.5 seconds since last cast and we're not currently casting
        if now - lastCastTime > 2.5 and not UnitCastingInfo("player") and not UnitChannelInfo("player") then
            state.downtime = state.downtime + (now - lastCastTime - 2.5)
        end
    end
end

-- Get the current combat duration
function CombatAnalysis:GetCombatDuration()
    if not state.inCombat and state.combatEndTime > 0 then
        return state.combatEndTime - state.combatStartTime
    else
        return GetTime() - state.combatStartTime
    end
end

-- Analyze the combat log to provide insights and suggestions
function CombatAnalysis:AnalyzeCombat(combatLog)
    if not combatLog then return end
    
    state.analysisCompleted = false
    wipe(state.suggestions)
    
    -- Calculate basic metrics
    local duration = combatLog.duration
    local dps = combatLog.dps
    local totalDamage = combatLog.damage
    local avoidableDamage = combatLog.avoidableDamage
    local downtime = combatLog.downtime
    local downtimePercent = (downtime / duration) * 100
    
    -- Analyze spell usage
    local totalSpellCasts = 0
    local spellUsageTable = {}
    
    for spellID, count in pairs(combatLog.spellUsage) do
        totalSpellCasts = totalSpellCasts + count
        table.insert(spellUsageTable, {
            spellID = spellID,
            spellName = GetSpellInfo(spellID) or "Unknown",
            count = count
        })
    end
    
    -- Sort by usage count (descending)
    table.sort(spellUsageTable, function(a, b) return a.count > b.count end)
    
    -- Calculate rotation efficiency based on various factors
    local efficiency = 100
    
    -- Penalty for downtime
    if downtimePercent > 5 then
        efficiency = efficiency - (downtimePercent - 5)
    end
    
    -- Penalty for missed interrupts
    if #combatLog.missedInterrupts > 0 then
        efficiency = efficiency - (#combatLog.missedInterrupts * 2)
    end
    
    -- Ensure efficiency is within bounds
    if efficiency < 0 then efficiency = 0 end
    if efficiency > 100 then efficiency = 100 end
    
    state.rotationEfficiency = efficiency
    
    -- Generate suggestions
    if downtimePercent > 5 then
        table.insert(state.suggestions, {
            type = "downtime",
            text = string.format("Reduce ability downtime (%.1f%% of combat)", downtimePercent),
            severity = downtimePercent > 15 and "high" or "medium",
        })
    end
    
    if #combatLog.missedInterrupts > 0 then
        table.insert(state.suggestions, {
            type = "interrupts",
            text = string.format("Missed %d possible interrupts", #combatLog.missedInterrupts),
            severity = #combatLog.missedInterrupts > 3 and "high" or "medium",
        })
    end
    
    if avoidableDamage > 0 then
        local avoidablePercent = (avoidableDamage / UnitHealthMax("player")) * 100
        table.insert(state.suggestions, {
            type = "avoidable",
            text = string.format("Took %.1f%% of health in avoidable damage", avoidablePercent),
            severity = avoidablePercent > 25 and "high" or "medium",
        })
    end
    
    -- Class-specific suggestions would go here
    -- This would require knowledge of optimal rotations for each class/spec
    
    state.analysisCompleted = true
    
    WR:Debug("Combat analysis completed - Efficiency:", efficiency)
end

-- Get the current DPS
function CombatAnalysis:GetDPS()
    return state.playerDPS
end

-- Get the total damage done in the current/last combat
function CombatAnalysis:GetDamage()
    return state.playerDamage
end

-- Get the combat efficiency rating
function CombatAnalysis:GetEfficiency()
    return state.rotationEfficiency
end

-- Get suggestions for improvement
function CombatAnalysis:GetSuggestions()
    return state.suggestions
end

-- Get spell usage statistics
function CombatAnalysis:GetSpellUsage()
    local spellUsageTable = {}
    
    for spellID, count in pairs(state.spellUsage) do
        table.insert(spellUsageTable, {
            spellID = spellID,
            spellName = GetSpellInfo(spellID) or "Unknown",
            count = count
        })
    end
    
    -- Sort by usage count (descending)
    table.sort(spellUsageTable, function(a, b) return a.count > b.count end)
    
    return spellUsageTable
end

-- Get missed interrupt opportunities
function CombatAnalysis:GetMissedInterrupts()
    return state.missedInterrupts
end

-- Get the amount of avoidable damage taken
function CombatAnalysis:GetAvoidableDamage()
    return state.avoidableDamage
end

-- Get the amount of downtime (in seconds)
function CombatAnalysis:GetDowntime()
    return state.downtime
end

-- Get the percentage of time spent in downtime
function CombatAnalysis:GetDowntimePercent()
    local duration = self:GetCombatDuration()
    if duration > 0 then
        return (state.downtime / duration) * 100
    end
    return 0
end

-- Get all combat logs
function CombatAnalysis:GetCombatLogs()
    return state.combatLogs
end

-- Get the most recent combat log
function CombatAnalysis:GetLastCombatLog()
    if #state.combatLogs > 0 then
        return state.combatLogs[1]
    end
    return nil
end

-- Initialize the module
CombatAnalysis:Initialize()