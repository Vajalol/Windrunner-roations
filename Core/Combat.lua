local addonName, WR = ...

-- Combat module - handles combat detection and analysis
local Combat = {}
WR.Combat = Combat

-- State
local state = {
    inCombat = false,
    combatStartTime = 0,
    combatLogEvents = {},
    maxCombatLogEntries = 100,
    enemyUnits = {},
    friendlyUnits = {},
    playerEvents = {},
    damageTracker = {
        totalDamage = 0,
        totalHealing = 0,
        startTime = 0,
        spells = {},
    },
    interruptTracker = {
        successful = 0,
        missed = 0,
        lastInterrupt = 0,
        targets = {},
    },
    combatPulse = 0,
}

-- Initialize the combat module
function Combat:Initialize()
    -- Create a frame for events
    local frame = CreateFrame("Frame")
    
    -- Register for combat log events
    frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    
    frame:SetScript("OnEvent", function(self, event, ...)
        if event == "COMBAT_LOG_EVENT_UNFILTERED" then
            Combat:COMBAT_LOG_EVENT_UNFILTERED(CombatLogGetCurrentEventInfo())
        elseif event == "PLAYER_REGEN_DISABLED" then
            Combat:OnEnterCombat()
        elseif event == "PLAYER_REGEN_ENABLED" then
            Combat:OnLeaveCombat()
        end
    end)
    
    WR:Debug("Combat module initialized")
end

-- Handle entering combat
function Combat:OnEnterCombat()
    state.inCombat = true
    state.combatStartTime = GetTime()
    
    -- Reset combat stats
    self:ResetCombatStats()
    
    WR:Debug("Entered combat")
end

-- Handle leaving combat
function Combat:OnLeaveCombat()
    state.inCombat = false
    
    -- Process and store combat summary
    self:ProcessCombatSummary()
    
    WR:Debug("Left combat")
end

-- Reset combat statistics
function Combat:ResetCombatStats()
    wipe(state.combatLogEvents)
    wipe(state.enemyUnits)
    wipe(state.friendlyUnits)
    wipe(state.playerEvents)
    
    state.damageTracker = {
        totalDamage = 0,
        totalHealing = 0,
        startTime = GetTime(),
        spells = {},
    }
    
    state.interruptTracker = {
        successful = 0,
        missed = 0,
        lastInterrupt = 0,
        targets = {},
    }
    
    state.combatPulse = 0
end

-- Process combat summary when leaving combat
function Combat:ProcessCombatSummary()
    local combatTime = GetTime() - state.combatStartTime
    
    local summary = {
        duration = combatTime,
        totalDamage = state.damageTracker.totalDamage,
        totalHealing = state.damageTracker.totalHealing,
        dps = combatTime > 0 and (state.damageTracker.totalDamage / combatTime) or 0,
        hps = combatTime > 0 and (state.damageTracker.totalHealing / combatTime) or 0,
        interrupts = state.interruptTracker.successful,
        spells = {},
        enemies = {},
    }
    
    -- Top damage spells
    for spellId, data in pairs(state.damageTracker.spells) do
        if data.damage > 0 then
            table.insert(summary.spells, {
                id = spellId,
                name = data.name,
                damage = data.damage,
                casts = data.casts,
                hits = data.hits,
                crits = data.crits,
                dps = combatTime > 0 and (data.damage / combatTime) or 0
            })
        end
    end
    
    -- Sort spells by damage
    table.sort(summary.spells, function(a, b) return a.damage > b.damage end)
    
    -- Limit to top 10
    if #summary.spells > 10 then
        for i = 11, #summary.spells do
            summary.spells[i] = nil
        end
    end
    
    -- Enemy units
    for guid, data in pairs(state.enemyUnits) do
        table.insert(summary.enemies, {
            name = data.name,
            totalDamage = data.totalDamage,
            totalDamageTaken = data.totalDamageTaken,
            killingBlow = data.killingBlow
        })
    end
    
    -- Sort enemies by damage taken
    table.sort(summary.enemies, function(a, b) return a.totalDamageTaken > b.totalDamageTaken end)
    
    -- Log the summary
    WR:Debug("Combat Summary:")
    WR:Debug(" - Duration:", string.format("%.2f", combatTime), "seconds")
    WR:Debug(" - Total Damage:", string.format("%.0f", summary.totalDamage))
    WR:Debug(" - DPS:", string.format("%.2f", summary.dps))
    WR:Debug(" - Interrupts:", summary.interrupts)
    
    -- Store the summary for later use
    WR.lastCombatSummary = summary
    
    return summary
end

-- Process the COMBAT_LOG_EVENT_UNFILTERED event
function Combat:COMBAT_LOG_EVENT_UNFILTERED(...)
    local timestamp, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, param1, param2, param3, param4, param5 = ...
    
    -- We're primarily interested in events caused by or affecting the player
    local isPlayerSource = sourceGUID == UnitGUID("player")
    local isPlayerDest = destGUID == UnitGUID("player")
    
    -- Add to combat log with a max size
    local eventData = {
        timestamp = timestamp,
        event = event,
        sourceGUID = sourceGUID,
        sourceName = sourceName,
        destGUID = destGUID,
        destName = destName,
        param1 = param1, -- Usually spell ID or other primary parameter
        param2 = param2, -- Usually spell name or other secondary parameter
        value = param4, -- Usually damage/healing amount
        isPlayerSource = isPlayerSource,
        isPlayerDest = isPlayerDest
    }
    
    table.insert(state.combatLogEvents, 1, eventData)
    
    -- Maintain maximum number of entries
    if #state.combatLogEvents > state.maxCombatLogEntries then
        table.remove(state.combatLogEvents)
    end
    
    -- Store a separate log of just player events
    if isPlayerSource or isPlayerDest then
        table.insert(state.playerEvents, 1, eventData)
        if #state.playerEvents > state.maxCombatLogEntries then
            table.remove(state.playerEvents)
        end
    end
    
    -- Process special event types
    if isPlayerSource then
        if event == "SPELL_DAMAGE" or event == "SPELL_PERIODIC_DAMAGE" or event == "RANGE_DAMAGE" then
            self:ProcessPlayerDamage(param1, param2, destGUID, destName, param4, param5)
        elseif event == "SPELL_HEAL" or event == "SPELL_PERIODIC_HEAL" then
            self:ProcessPlayerHeal(param1, param2, destGUID, destName, param4, param5)
        elseif event == "SPELL_CAST_SUCCESS" then
            self:ProcessPlayerCast(param1, param2, destGUID, destName)
        elseif event == "SPELL_INTERRUPT" then
            self:ProcessPlayerInterrupt(param1, param2, destGUID, destName, param4, param5)
        end
    end
    
    -- Process events where player is the target
    if isPlayerDest then
        if event == "SPELL_DAMAGE" or event == "SPELL_PERIODIC_DAMAGE" or event == "RANGE_DAMAGE" or event == "SWING_DAMAGE" then
            self:ProcessPlayerDamageTaken(sourceGUID, sourceName, param1, param2, param4)
        end
    end
    
    -- Update enemy unit tracking
    if (sourceFlags and bit.band(sourceFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) ~= 0) then
        self:TrackEnemyUnit(sourceGUID, sourceName, event, destGUID, param1, param4)
    end
    
    -- Update friendly unit tracking
    if (sourceFlags and bit.band(sourceFlags, COMBATLOG_OBJECT_REACTION_FRIENDLY) ~= 0) then
        self:TrackFriendlyUnit(sourceGUID, sourceName, event, destGUID, param1, param4)
    end
    
    -- Increment combat pulse counter - used to track recent combat activity
    state.combatPulse = state.combatPulse + 1
end

-- Process player damage event
function Combat:ProcessPlayerDamage(spellId, spellName, destGUID, destName, amount, overkill)
    if not spellId or not amount then return end
    
    -- Add to total damage
    state.damageTracker.totalDamage = state.damageTracker.totalDamage + amount
    
    -- Add to spell tracking
    if not state.damageTracker.spells[spellId] then
        state.damageTracker.spells[spellId] = {
            name = spellName,
            damage = 0,
            casts = 0,
            hits = 0,
            crits = 0
        }
    end
    
    state.damageTracker.spells[spellId].damage = state.damageTracker.spells[spellId].damage + amount
    state.damageTracker.spells[spellId].hits = state.damageTracker.spells[spellId].hits + 1
    
    -- TODO: Detect crits
    
    -- Track damage to enemy
    if destGUID and destName then
        if not state.enemyUnits[destGUID] then
            state.enemyUnits[destGUID] = {
                name = destName,
                totalDamage = 0,
                totalDamageTaken = 0,
                killingBlow = false
            }
        end
        
        state.enemyUnits[destGUID].totalDamageTaken = state.enemyUnits[destGUID].totalDamageTaken + amount
        
        -- Check for killing blow
        if overkill and overkill > 0 then
            state.enemyUnits[destGUID].killingBlow = true
        end
    end
end

-- Process player healing event
function Combat:ProcessPlayerHeal(spellId, spellName, destGUID, destName, amount, overhealing)
    if not spellId or not amount then return end
    
    -- Subtract overhealing
    local effectiveHealing = amount - (overhealing or 0)
    if effectiveHealing < 0 then effectiveHealing = 0 end
    
    -- Add to total healing
    state.damageTracker.totalHealing = state.damageTracker.totalHealing + effectiveHealing
    
    -- Add to spell tracking (we'll reuse the damage tracker)
    if not state.damageTracker.spells[spellId] then
        state.damageTracker.spells[spellId] = {
            name = spellName,
            damage = 0,
            healing = 0,
            casts = 0,
            hits = 0,
            crits = 0
        }
    end
    
    -- Add healing field if it doesn't exist
    if not state.damageTracker.spells[spellId].healing then
        state.damageTracker.spells[spellId].healing = 0
    end
    
    state.damageTracker.spells[spellId].healing = state.damageTracker.spells[spellId].healing + effectiveHealing
    state.damageTracker.spells[spellId].hits = state.damageTracker.spells[spellId].hits + 1
    
    -- TODO: Track healing by target
end

-- Process player spell cast event
function Combat:ProcessPlayerCast(spellId, spellName, destGUID, destName)
    if not spellId then return end
    
    -- Track spell casts
    if not state.damageTracker.spells[spellId] then
        state.damageTracker.spells[spellId] = {
            name = spellName,
            damage = 0,
            casts = 0,
            hits = 0,
            crits = 0
        }
    end
    
    state.damageTracker.spells[spellId].casts = state.damageTracker.spells[spellId].casts + 1
end

-- Process player interrupt event
function Combat:ProcessPlayerInterrupt(spellId, spellName, destGUID, destName, extraSpellId, extraSpellName)
    if not spellId then return end
    
    -- Update interrupt tracker
    state.interruptTracker.successful = state.interruptTracker.successful + 1
    state.interruptTracker.lastInterrupt = GetTime()
    
    -- Track by target
    if destGUID and destName then
        if not state.interruptTracker.targets[destGUID] then
            state.interruptTracker.targets[destGUID] = {
                name = destName,
                interrupts = 0,
                spells = {}
            }
        end
        
        state.interruptTracker.targets[destGUID].interrupts = state.interruptTracker.targets[destGUID].interrupts + 1
        
        -- Track interrupted spells
        if extraSpellId and extraSpellName then
            if not state.interruptTracker.targets[destGUID].spells[extraSpellId] then
                state.interruptTracker.targets[destGUID].spells[extraSpellId] = {
                    name = extraSpellName,
                    count = 0
                }
            end
            
            state.interruptTracker.targets[destGUID].spells[extraSpellId].count = state.interruptTracker.targets[destGUID].spells[extraSpellId].count + 1
        end
    end
    
    WR:Debug("Interrupted", destName, "casting", extraSpellName)
end

-- Process damage taken by player
function Combat:ProcessPlayerDamageTaken(sourceGUID, sourceName, spellId, spellName, amount)
    if not sourceGUID or not amount then return end
    
    -- Track damage from enemy
    if not state.enemyUnits[sourceGUID] then
        state.enemyUnits[sourceGUID] = {
            name = sourceName,
            totalDamage = 0,
            totalDamageTaken = 0,
            killingBlow = false
        }
    end
    
    state.enemyUnits[sourceGUID].totalDamage = state.enemyUnits[sourceGUID].totalDamage + amount
end

-- Track enemy units
function Combat:TrackEnemyUnit(guid, name, event, targetGUID, spellId, value)
    if not guid or not name then return end
    
    -- Initialize tracking for this enemy if not exists
    if not state.enemyUnits[guid] then
        state.enemyUnits[guid] = {
            name = name,
            totalDamage = 0,
            totalDamageTaken = 0,
            killingBlow = false,
            lastSeen = GetTime(),
            casts = {}
        }
    end
    
    -- Update last seen time
    state.enemyUnits[guid].lastSeen = GetTime()
    
    -- Track spell casts by this enemy
    if event == "SPELL_CAST_START" and spellId then
        if not state.enemyUnits[guid].casts[spellId] then
            state.enemyUnits[guid].casts[spellId] = {
                name = GetSpellInfo(spellId) or "Unknown",
                count = 0,
                lastCast = 0
            }
        end
        
        state.enemyUnits[guid].casts[spellId].count = state.enemyUnits[guid].casts[spellId].count + 1
        state.enemyUnits[guid].casts[spellId].lastCast = GetTime()
    end
end

-- Track friendly units
function Combat:TrackFriendlyUnit(guid, name, event, targetGUID, spellId, value)
    if not guid or not name then return end
    
    -- Initialize tracking for this friendly if not exists
    if not state.friendlyUnits[guid] then
        state.friendlyUnits[guid] = {
            name = name,
            lastSeen = GetTime()
        }
    end
    
    -- Update last seen time
    state.friendlyUnits[guid].lastSeen = GetTime()
}

-- Get the current combat state
function Combat:IsInCombat()
    return state.inCombat
end

-- Get time spent in current combat
function Combat:GetCombatTime()
    if not state.inCombat then return 0 end
    return GetTime() - state.combatStartTime
end

-- Get the recent combat log events
function Combat:GetCombatLog(count)
    count = count or state.maxCombatLogEntries
    local result = {}
    
    for i = 1, math.min(count, #state.combatLogEvents) do
        table.insert(result, state.combatLogEvents[i])
    end
    
    return result
end

-- Get only the player's combat log events
function Combat:GetPlayerCombatLog(count)
    count = count or state.maxCombatLogEntries
    local result = {}
    
    for i = 1, math.min(count, #state.playerEvents) do
        table.insert(result, state.playerEvents[i])
    end
    
    return result
end

-- Get current DPS
function Combat:GetDPS()
    local combatTime = self:GetCombatTime()
    if combatTime <= 0 then return 0 end
    
    return state.damageTracker.totalDamage / combatTime
end

-- Get current HPS
function Combat:GetHPS()
    local combatTime = self:GetCombatTime()
    if combatTime <= 0 then return 0 end
    
    return state.damageTracker.totalHealing / combatTime
end

-- Get interrupt statistics
function Combat:GetInterruptStats()
    return {
        successful = state.interruptTracker.successful,
        timeSinceLast = GetTime() - state.interruptTracker.lastInterrupt
    }
end

-- Get tracked enemy units
function Combat:GetEnemyUnits()
    return state.enemyUnits
end

-- Get tracked friendly units
function Combat:GetFriendlyUnits()
    return state.friendlyUnits
end

-- Get combat pulse (activity indicator)
function Combat:GetCombatPulse()
    local pulse = state.combatPulse
    state.combatPulse = 0
    return pulse
end

-- Check if there was recent damage activity
function Combat:HasRecentDamageActivity(timeThreshold)
    timeThreshold = timeThreshold or 3.0 -- Default 3 seconds
    
    for i = 1, math.min(10, #state.combatLogEvents) do
        local event = state.combatLogEvents[i]
        if event and event.event and (
           event.event == "SPELL_DAMAGE" or 
           event.event == "SPELL_PERIODIC_DAMAGE" or 
           event.event == "RANGE_DAMAGE" or 
           event.event == "SWING_DAMAGE") then
            
            local eventTime = event.timestamp
            if GetTime() - eventTime <= timeThreshold then
                return true
            end
        end
    end
    
    return false
end
