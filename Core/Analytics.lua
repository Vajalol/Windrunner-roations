local addonName, WR = ...

-- Analytics module for combat performance tracking and analysis
local Analytics = {}
WR.Analytics = Analytics

-- Maximum entries to keep in historical data
local MAX_COMBAT_LOGS = 20
local MAX_ROTATION_LOGS = 1000
local MAX_ABILITY_LOGS = 100
local MAX_TALENT_ENTRIES = 50

-- Data storage
local analyticsData = {
    combatLogs = {},               -- Combat session data
    rotationLogs = {},             -- Rotation decision data
    abilityUsage = {},             -- Ability usage statistics
    talentPerformance = {},        -- Performance by talent build
    encounterData = {},            -- Data about specific encounters
    performanceMetrics = {         -- Overall performance metrics
        dps = {},
        hps = {},
        dtps = {},
        survivalMetrics = {}
    },
    reactionMetrics = {},          -- Reaction time metrics
    environmentMetrics = {},       -- Environmental metrics (fps, latency)
    comparisonData = {},           -- Data for performance comparisons
    insights = {},                 -- Generated insights
    rotationQuality = {}           -- Rotation quality metrics
}

-- Configuration options
local config = {
    enabled = true,
    logCombat = true,              -- Log combat data
    logRotation = true,            -- Log rotation decisions
    trackPerformance = true,       -- Track performance metrics 
    logDetailLevel = 2,            -- 1-3 (low to high detail level)
    autoInsights = true,           -- Automatically generate insights
    logPrivacy = 2,                -- 1-3 (1 = most private, 3 = share all data)
    logDeletionDays = 30,          -- Number of days to keep logs
    trackTalentPerformance = true  -- Track performance by talent build
}

-- Combat logging state
local inCombat = false
local currentCombatLog = nil
local currentSessionStart = nil
local currentEncounter = nil
local combatElapsed = 0

-- Performance tracking
local damageTotal = 0
local healingTotal = 0
local damageTakenTotal = 0
local lastSpellSuccess = {}
local lastSpellQueue = {}
local spellCount = {}
local reactionTimes = {}
local combatEventCount = 0
local sessionPulses = 0
local lastCombatPulse = 0

-- Initialize the analytics module
function Analytics:Initialize()
    -- Register for events
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")  -- Enter combat
    eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")   -- Leave combat
    eventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_FAILED")
    eventFrame:RegisterEvent("ENCOUNTER_START")
    eventFrame:RegisterEvent("ENCOUNTER_END")
    eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    eventFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
    
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        if not config.enabled then return end
        
        if event == "PLAYER_REGEN_DISABLED" then
            Analytics:StartCombatTracking()
        elseif event == "PLAYER_REGEN_ENABLED" then
            Analytics:EndCombatTracking()
        elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
            local unit, _, spellID = ...
            if unit == "player" then
                Analytics:TrackSpellSuccess(spellID)
            end
        elseif event == "UNIT_SPELLCAST_FAILED" then
            local unit, _, spellID = ...
            if unit == "player" then
                Analytics:TrackSpellFailure(spellID)
            end
        elseif event == "ENCOUNTER_START" then
            local encounterID, encounterName, difficultyID, groupSize = ...
            Analytics:StartEncounterTracking(encounterID, encounterName, difficultyID, groupSize)
        elseif event == "ENCOUNTER_END" then
            local encounterID, encounterName, difficultyID, groupSize, success = ...
            Analytics:EndEncounterTracking(encounterID, encounterName, difficultyID, groupSize, success)
        elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
            if config.logCombat and config.logDetailLevel >= 2 then
                Analytics:ProcessCombatLogEvent(CombatLogGetCurrentEventInfo())
            end
        elseif event == "PLAYER_SPECIALIZATION_CHANGED" or event == "PLAYER_TALENT_UPDATE" then
            Analytics:RecordTalentConfiguration()
        end
    end)
    
    self.eventFrame = eventFrame
    
    -- Record initial talent configuration
    C_Timer.After(5, function() Analytics:RecordTalentConfiguration() end)
    
    -- Set up periodic cleanup
    C_Timer.NewTicker(86400, function() Analytics:CleanupOldData() end)  -- Daily cleanup
    
    WR:Debug("Analytics module initialized")
end

-- Start combat tracking
function Analytics:StartCombatTracking()
    if inCombat then return end
    
    inCombat = true
    currentSessionStart = GetTime()
    combatElapsed = 0
    
    -- Reset tracking variables
    damageTotal = 0
    healingTotal = 0
    damageTakenTotal = 0
    combatEventCount = 0
    sessionPulses = 0
    lastCombatPulse = GetTime()
    
    -- Create new combat log entry
    currentCombatLog = {
        sessionId = tostring(currentSessionStart),
        startTime = currentSessionStart,
        endTime = nil,
        duration = 0,
        playerInfo = self:GetPlayerInfo(),
        damage = 0,
        healing = 0,
        damageTaken = 0,
        spellCount = {},
        spellSuccess = {},
        spellFailed = {},
        environmentMetrics = {
            avgFps = 0,
            minFps = 999,
            maxFps = 0,
            avgLatency = 0,
            minLatency = 9999,
            maxLatency = 0
        },
        rotationMetrics = {
            pulseCount = 0,
            avgPulseTime = 0,
            maxPulseTime = 0,
            decisions = {}
        },
        encounter = currentEncounter,
        location = GetRealZoneText(),
        groupSize = GetNumGroupMembers(),
        isRaid = IsInRaid(),
        isDungeon = IsInInstance(),
        isLFG = IsInGroup(LE_PARTY_CATEGORY_INSTANCE),
        talentBuild = self:GetCurrentTalentBuild()
    }
    
    -- Start environment tracker
    self:StartEnvironmentTracking()
    
    WR:Debug("Combat tracking started")
end

-- End combat tracking
function Analytics:EndCombatTracking()
    if not inCombat then return end
    
    inCombat = false
    
    -- Update current combat log
    if currentCombatLog then
        currentCombatLog.endTime = GetTime()
        currentCombatLog.duration = currentCombatLog.endTime - currentCombatLog.startTime
        
        -- Add final metrics
        currentCombatLog.damage = damageTotal
        currentCombatLog.healing = healingTotal
        currentCombatLog.damageTaken = damageTakenTotal
        currentCombatLog.spellCount = CopyTable(spellCount)
        
        -- Calculate DPS/HPS/DTPS
        if currentCombatLog.duration > 0 then
            currentCombatLog.dps = damageTotal / currentCombatLog.duration
            currentCombatLog.hps = healingTotal / currentCombatLog.duration
            currentCombatLog.dtps = damageTakenTotal / currentCombatLog.duration
        else
            currentCombatLog.dps = 0
            currentCombatLog.hps = 0
            currentCombatLog.dtps = 0
        end
        
        -- Calculate rotation metrics
        if sessionPulses > 0 then
            currentCombatLog.rotationMetrics.pulseCount = sessionPulses
            currentCombatLog.rotationMetrics.avgPulseTime = combatElapsed / sessionPulses
        end
        
        -- Finalize environment metrics
        self:FinalizeEnvironmentMetrics(currentCombatLog.environmentMetrics)
        
        -- Store the combat log
        table.insert(analyticsData.combatLogs, 1, currentCombatLog)
        
        -- Trim if needed
        if #analyticsData.combatLogs > MAX_COMBAT_LOGS then
            table.remove(analyticsData.combatLogs)
        end
        
        -- Update performance metrics
        self:UpdatePerformanceMetrics()
        
        -- Generate insights
        if config.autoInsights then
            self:GenerateInsights()
        end
        
        -- Update talent performance data
        if config.trackTalentPerformance then
            self:UpdateTalentPerformance()
        end
        
        WR:Debug("Combat tracking ended, session duration:", string.format("%.2f", currentCombatLog.duration), "seconds")
        
        -- Clear current combat log
        currentCombatLog = nil
    end
end

-- Start encounter tracking
function Analytics:StartEncounterTracking(encounterID, encounterName, difficultyID, groupSize)
    currentEncounter = {
        id = encounterID,
        name = encounterName,
        difficulty = difficultyID,
        groupSize = groupSize,
        startTime = GetTime(),
        endTime = nil,
        success = nil
    }
    
    WR:Debug("Encounter tracking started:", encounterName)
    
    -- Update current combat log if we're in combat
    if inCombat and currentCombatLog then
        currentCombatLog.encounter = CopyTable(currentEncounter)
    end
end

-- End encounter tracking
function Analytics:EndEncounterTracking(encounterID, encounterName, difficultyID, groupSize, success)
    if not currentEncounter or currentEncounter.id ~= encounterID then return end
    
    currentEncounter.endTime = GetTime()
    currentEncounter.duration = currentEncounter.endTime - currentEncounter.startTime
    currentEncounter.success = success == 1
    
    -- Store encounter data
    analyticsData.encounterData[encounterID] = analyticsData.encounterData[encounterID] or {}
    table.insert(analyticsData.encounterData[encounterID], CopyTable(currentEncounter))
    
    -- Update current combat log if we're in combat
    if inCombat and currentCombatLog then
        currentCombatLog.encounter = CopyTable(currentEncounter)
    end
    
    WR:Debug("Encounter tracking ended:", encounterName, "Success:", success == 1)
    
    currentEncounter = nil
end

-- Process combat log event
function Analytics:ProcessCombatLogEvent(...)
    if not inCombat or not currentCombatLog then return end
    
    local timestamp, subEvent, _, sourceGUID, sourceName, sourceFlags, sourceRaidFlags,
          destGUID, destName, destFlags, destRaidFlags, param1, param2, param3, param4, param5 = ...
    
    -- Only track events where player is source or destination
    local playerGUID = UnitGUID("player")
    local isPlayerSource = sourceGUID == playerGUID
    local isPlayerDest = destGUID == playerGUID
    
    if not isPlayerSource and not isPlayerDest then return end
    
    -- Track damage done by player
    if isPlayerSource and (subEvent == "SPELL_DAMAGE" or subEvent == "RANGE_DAMAGE" or subEvent == "SWING_DAMAGE") then
        local amount = param1
        if type(amount) == "number" then
            damageTotal = damageTotal + amount
        end
    end
    
    -- Track healing done by player
    if isPlayerSource and (subEvent == "SPELL_HEAL" or subEvent == "SPELL_PERIODIC_HEAL") then
        local amount = param1
        if type(amount) == "number" then
            healingTotal = healingTotal + amount
        end
    end
    
    -- Track damage taken by player
    if isPlayerDest and (subEvent == "SPELL_DAMAGE" or subEvent == "RANGE_DAMAGE" or 
                         subEvent == "SWING_DAMAGE" or subEvent == "ENVIRONMENTAL_DAMAGE") then
        local amount = param1
        if type(amount) == "number" then
            damageTakenTotal = damageTakenTotal + amount
        end
    end
    
    -- Count combat events
    combatEventCount = combatEventCount + 1
end

-- Track spell cast success
function Analytics:TrackSpellSuccess(spellID)
    if not spellID then return end
    
    lastSpellSuccess[spellID] = GetTime()
    
    -- Track spell count
    spellCount[spellID] = (spellCount[spellID] or 0) + 1
    
    -- Track ability usage
    if not analyticsData.abilityUsage[spellID] then
        analyticsData.abilityUsage[spellID] = {
            name = GetSpellInfo(spellID) or "Unknown Spell",
            id = spellID,
            casts = 0,
            successes = 0,
            failures = 0,
            lastCast = 0,
            totalCastTime = 0,
            inCombatCasts = 0,
            outsideCombatCasts = 0
        }
    end
    
    local ability = analyticsData.abilityUsage[spellID]
    ability.casts = ability.casts + 1
    ability.successes = ability.successes + 1
    ability.lastCast = GetTime()
    
    if inCombat then
        ability.inCombatCasts = ability.inCombatCasts + 1
    else
        ability.outsideCombatCasts = ability.outsideCombatCasts + 1
    end
    
    -- Check reaction time if this was a recommended spell
    if lastSpellQueue[spellID] then
        local reactionTime = GetTime() - lastSpellQueue[spellID]
        table.insert(reactionTimes, reactionTime)
        
        -- Only keep a reasonable number of reaction times
        if #reactionTimes > 100 then
            table.remove(reactionTimes, 1)
        end
        
        -- Track in analytics
        analyticsData.reactionMetrics[spellID] = analyticsData.reactionMetrics[spellID] or {
            name = GetSpellInfo(spellID) or "Unknown Spell",
            id = spellID,
            reactionTimes = {},
            avgReactionTime = 0,
            minReactionTime = 999,
            maxReactionTime = 0
        }
        
        local metrics = analyticsData.reactionMetrics[spellID]
        table.insert(metrics.reactionTimes, reactionTime)
        
        -- Trim if needed
        if #metrics.reactionTimes > 20 then
            table.remove(metrics.reactionTimes, 1)
        end
        
        -- Update stats
        local total = 0
        metrics.minReactionTime = 999
        metrics.maxReactionTime = 0
        
        for _, time in ipairs(metrics.reactionTimes) do
            total = total + time
            metrics.minReactionTime = math.min(metrics.minReactionTime, time)
            metrics.maxReactionTime = math.max(metrics.maxReactionTime, time)
        end
        
        metrics.avgReactionTime = total / #metrics.reactionTimes
        
        -- Clear from queue
        lastSpellQueue[spellID] = nil
    end
end

-- Track spell cast failure
function Analytics:TrackSpellFailure(spellID)
    if not spellID then return end
    
    -- Track ability usage
    if not analyticsData.abilityUsage[spellID] then
        analyticsData.abilityUsage[spellID] = {
            name = GetSpellInfo(spellID) or "Unknown Spell",
            id = spellID,
            casts = 0,
            successes = 0,
            failures = 0,
            lastCast = 0,
            totalCastTime = 0,
            inCombatCasts = 0,
            outsideCombatCasts = 0
        }
    end
    
    local ability = analyticsData.abilityUsage[spellID]
    ability.casts = ability.casts + 1
    ability.failures = ability.failures + 1
    ability.lastCast = GetTime()
    
    -- Clear from queue if it was there
    lastSpellQueue[spellID] = nil
end

-- Track a rotation decision (spell recommended)
function Analytics:TrackRotationDecision(spellID, reason)
    if not config.logRotation or not inCombat or not currentCombatLog then return end
    
    if not spellID then return end
    
    -- Record recommendation time for reaction tracking
    lastSpellQueue[spellID] = GetTime()
    
    -- Add to rotation logs if detailed logging is enabled
    if config.logDetailLevel >= 2 then
        local decision = {
            timestamp = GetTime(),
            spellID = spellID,
            spellName = GetSpellInfo(spellID) or "Unknown Spell",
            reason = reason or "No reason provided",
            combatTime = GetTime() - currentCombatLog.startTime,
            playerHealth = UnitHealth("player") / UnitHealthMax("player") * 100,
            targetHealth = UnitExists("target") and (UnitHealth("target") / UnitHealthMax("target") * 100) or 0,
            resources = self:GetPlayerResources(),
            executed = false,
            reactionTime = nil
        }
        
        -- Add to rotation metrics
        table.insert(currentCombatLog.rotationMetrics.decisions, decision)
        
        -- Add to global rotation logs
        table.insert(analyticsData.rotationLogs, decision)
        
        -- Trim if needed
        if #analyticsData.rotationLogs > MAX_ROTATION_LOGS then
            table.remove(analyticsData.rotationLogs, 1)
        end
    end
    
    -- Track rotation quality (basic)
    analyticsData.rotationQuality[spellID] = analyticsData.rotationQuality[spellID] or {
        name = GetSpellInfo(spellID) or "Unknown Spell",
        id = spellID,
        recommended = 0,
        executed = 0,
        skipped = 0,
        avgReactionTime = 0
    }
    
    analyticsData.rotationQuality[spellID].recommended = analyticsData.rotationQuality[spellID].recommended + 1
end

-- Update rotation tracking after a pulse
function Analytics:TrackRotationPulse(timeElapsed)
    if not inCombat or not currentCombatLog then return end
    
    sessionPulses = sessionPulses + 1
    combatElapsed = combatElapsed + timeElapsed
    
    if timeElapsed > (currentCombatLog.rotationMetrics.maxPulseTime or 0) then
        currentCombatLog.rotationMetrics.maxPulseTime = timeElapsed
    end
    
    -- Update execution status of rotation decisions
    if config.logDetailLevel >= 2 and #currentCombatLog.rotationMetrics.decisions > 0 then
        local lastDecision = currentCombatLog.rotationMetrics.decisions[#currentCombatLog.rotationMetrics.decisions]
        local timeSinceDecision = GetTime() - lastDecision.timestamp
        
        -- If it's a recent decision (last 2 seconds) and the spell was cast successfully, mark as executed
        if timeSinceDecision < 2 and lastSpellSuccess[lastDecision.spellID] then
            local executionTime = lastSpellSuccess[lastDecision.spellID] - lastDecision.timestamp
            if executionTime > 0 and executionTime < 2 then
                lastDecision.executed = true
                lastDecision.reactionTime = executionTime
                
                -- Update in global logs too
                for i = #analyticsData.rotationLogs, 1, -1 do
                    local decision = analyticsData.rotationLogs[i]
                    if decision.timestamp == lastDecision.timestamp and decision.spellID == lastDecision.spellID then
                        decision.executed = true
                        decision.reactionTime = executionTime
                        break
                    end
                end
                
                -- Update rotation quality
                if analyticsData.rotationQuality[lastDecision.spellID] then
                    analyticsData.rotationQuality[lastDecision.spellID].executed = 
                        analyticsData.rotationQuality[lastDecision.spellID].executed + 1
                    
                    -- Update average reaction time
                    local quality = analyticsData.rotationQuality[lastDecision.spellID]
                    quality.avgReactionTime = (quality.avgReactionTime * (quality.executed - 1) + executionTime) / quality.executed
                end
            end
        end
        
        -- If it's an older decision (over 3 seconds) and not marked executed, mark as skipped
        if timeSinceDecision > 3 and not lastDecision.executed then
            lastDecision.skipped = true
            
            -- Update in global logs too
            for i = #analyticsData.rotationLogs, 1, -1 do
                local decision = analyticsData.rotationLogs[i]
                if decision.timestamp == lastDecision.timestamp and decision.spellID == lastDecision.spellID then
                    decision.skipped = true
                    break
                end
            end
            
            -- Update rotation quality
            if analyticsData.rotationQuality[lastDecision.spellID] then
                analyticsData.rotationQuality[lastDecision.spellID].skipped = 
                    analyticsData.rotationQuality[lastDecision.spellID].skipped + 1
            end
        end
    end
    
    -- Track environment metrics
    local fps = GetFramerate()
    local _, _, latencyHome, latencyWorld = GetNetStats()
    local latency = math.max(latencyHome, latencyWorld)
    
    if currentCombatLog.environmentMetrics then
        -- Track min/max
        currentCombatLog.environmentMetrics.minFps = math.min(currentCombatLog.environmentMetrics.minFps, fps)
        currentCombatLog.environmentMetrics.maxFps = math.max(currentCombatLog.environmentMetrics.maxFps, fps)
        currentCombatLog.environmentMetrics.minLatency = math.min(currentCombatLog.environmentMetrics.minLatency, latency)
        currentCombatLog.environmentMetrics.maxLatency = math.max(currentCombatLog.environmentMetrics.maxLatency, latency)
        
        -- Track for averages
        currentCombatLog.environmentMetrics.fpsData = currentCombatLog.environmentMetrics.fpsData or {}
        currentCombatLog.environmentMetrics.latencyData = currentCombatLog.environmentMetrics.latencyData or {}
        
        table.insert(currentCombatLog.environmentMetrics.fpsData, fps)
        table.insert(currentCombatLog.environmentMetrics.latencyData, latency)
    end
    
    lastCombatPulse = GetTime()
}

-- Start environment tracking
function Analytics:StartEnvironmentTracking()
    -- Initialize environment metrics
    if currentCombatLog and currentCombatLog.environmentMetrics then
        currentCombatLog.environmentMetrics.fpsData = {}
        currentCombatLog.environmentMetrics.latencyData = {}
        
        -- Set initial FPS and latency
        local fps = GetFramerate()
        local _, _, latencyHome, latencyWorld = GetNetStats()
        local latency = math.max(latencyHome, latencyWorld)
        
        currentCombatLog.environmentMetrics.minFps = fps
        currentCombatLog.environmentMetrics.maxFps = fps
        currentCombatLog.environmentMetrics.minLatency = latency
        currentCombatLog.environmentMetrics.maxLatency = latency
        
        table.insert(currentCombatLog.environmentMetrics.fpsData, fps)
        table.insert(currentCombatLog.environmentMetrics.latencyData, latency)
    end
}

-- Finalize environment metrics
function Analytics:FinalizeEnvironmentMetrics(metrics)
    if not metrics or not metrics.fpsData or not metrics.latencyData then return end
    
    -- Calculate averages
    local fpsTotal = 0
    for _, fps in ipairs(metrics.fpsData) do
        fpsTotal = fpsTotal + fps
    end
    
    local latencyTotal = 0
    for _, latency in ipairs(metrics.latencyData) do
        latencyTotal = latencyTotal + latency
    end
    
    metrics.avgFps = fpsTotal / #metrics.fpsData
    metrics.avgLatency = latencyTotal / #metrics.latencyData
    
    -- Clean up raw data to save memory
    metrics.fpsData = nil
    metrics.latencyData = nil
}

-- Get player info
function Analytics:GetPlayerInfo()
    local _, class = UnitClass("player")
    local spec = GetSpecialization()
    local specID = spec and GetSpecializationInfo(spec) or 0
    local level = UnitLevel("player")
    local ilvl = C_PaperDollInfo.GetAverageItemLevel()
    
    return {
        class = class,
        spec = specID,
        level = level,
        ilvl = ilvl,
        name = UnitName("player"),
        faction = UnitFactionGroup("player"),
        realm = GetRealmName()
    }
}

-- Get player resources
function Analytics:GetPlayerResources()
    local resources = {}
    local powerType = UnitPowerType("player")
    
    resources.power = {
        current = UnitPower("player"),
        max = UnitPowerMax("player"),
        type = powerType
    }
    
    -- Get class-specific resources
    local _, class = UnitClass("player")
    
    if class == "ROGUE" or class == "DRUID" then
        resources.comboPoints = UnitPower("player", Enum.PowerType.ComboPoints)
    elseif class == "WARLOCK" then
        resources.soulShards = UnitPower("player", Enum.PowerType.SoulShards)
    elseif class == "MAGE" then
        resources.arcaneCharges = UnitPower("player", Enum.PowerType.ArcaneCharges)
    elseif class == "MONK" then
        resources.chi = UnitPower("player", Enum.PowerType.Chi)
    elseif class == "PALADIN" then
        resources.holyPower = UnitPower("player", Enum.PowerType.HolyPower)
    elseif class == "PRIEST" then
        resources.insanity = UnitPower("player", Enum.PowerType.Insanity)
    elseif class == "DEATHKNIGHT" then
        resources.runicPower = UnitPower("player", Enum.PowerType.RunicPower)
        resources.runes = 0
        for i = 1, 6 do
            local _, _, runeReady = GetRuneCooldown(i)
            if runeReady then
                resources.runes = resources.runes + 1
            end
        end
    elseif class == "EVOKER" then
        resources.essence = UnitPower("player", Enum.PowerType.Essence)
    end
    
    return resources
}

-- Update performance metrics
function Analytics:UpdatePerformanceMetrics()
    if not currentCombatLog then return end
    
    -- Only track if the session was long enough to be meaningful
    if currentCombatLog.duration < 10 then return end
    
    -- Add to DPS metrics
    table.insert(analyticsData.performanceMetrics.dps, {
        value = currentCombatLog.dps,
        sessionId = currentCombatLog.sessionId,
        timestamp = currentCombatLog.endTime,
        encounter = currentCombatLog.encounter,
        duration = currentCombatLog.duration
    })
    
    -- Add to HPS metrics
    table.insert(analyticsData.performanceMetrics.hps, {
        value = currentCombatLog.hps,
        sessionId = currentCombatLog.sessionId,
        timestamp = currentCombatLog.endTime,
        encounter = currentCombatLog.encounter,
        duration = currentCombatLog.duration
    })
    
    -- Add to DTPS metrics
    table.insert(analyticsData.performanceMetrics.dtps, {
        value = currentCombatLog.dtps,
        sessionId = currentCombatLog.sessionId,
        timestamp = currentCombatLog.endTime,
        encounter = currentCombatLog.encounter,
        duration = currentCombatLog.duration
    })
    
    -- Trim metrics if needed
    local maxMetrics = 50
    
    if #analyticsData.performanceMetrics.dps > maxMetrics then
        table.remove(analyticsData.performanceMetrics.dps, 1)
    end
    
    if #analyticsData.performanceMetrics.hps > maxMetrics then
        table.remove(analyticsData.performanceMetrics.hps, 1)
    end
    
    if #analyticsData.performanceMetrics.dtps > maxMetrics then
        table.remove(analyticsData.performanceMetrics.dtps, 1)
    end
}

-- Record current talent configuration
function Analytics:RecordTalentConfiguration()
    if not config.trackTalentPerformance then return end
    
    local talentBuild = self:GetCurrentTalentBuild()
    
    -- Store the talent build if it doesn't exist
    if not analyticsData.talentPerformance[talentBuild.hash] then
        analyticsData.talentPerformance[talentBuild.hash] = {
            hash = talentBuild.hash,
            spec = talentBuild.spec,
            specName = talentBuild.specName,
            talents = talentBuild.talents,
            combatLogs = {},
            dps = {
                total = 0,
                count = 0,
                avg = 0,
                max = 0
            },
            hps = {
                total = 0,
                count = 0,
                avg = 0,
                max = 0
            },
            dtps = {
                total = 0,
                count = 0,
                avg = 0,
                max = 0
            },
            successRate = {
                total = 0,
                success = 0,
                rate = 0
            }
        }
    end
}

-- Update talent performance statistics
function Analytics:UpdateTalentPerformance()
    if not config.trackTalentPerformance or not currentCombatLog then return end
    
    local talentBuild = currentCombatLog.talentBuild
    if not talentBuild or not talentBuild.hash then return end
    
    -- Get the talent record
    local talentRecord = analyticsData.talentPerformance[talentBuild.hash]
    if not talentRecord then return end
    
    -- Add the combat log ID to this talent build
    table.insert(talentRecord.combatLogs, currentCombatLog.sessionId)
    
    -- Update DPS stats
    talentRecord.dps.total = talentRecord.dps.total + currentCombatLog.dps
    talentRecord.dps.count = talentRecord.dps.count + 1
    talentRecord.dps.avg = talentRecord.dps.total / talentRecord.dps.count
    talentRecord.dps.max = math.max(talentRecord.dps.max, currentCombatLog.dps)
    
    -- Update HPS stats
    talentRecord.hps.total = talentRecord.hps.total + currentCombatLog.hps
    talentRecord.hps.count = talentRecord.hps.count + 1
    talentRecord.hps.avg = talentRecord.hps.total / talentRecord.hps.count
    talentRecord.hps.max = math.max(talentRecord.hps.max, currentCombatLog.hps)
    
    -- Update DTPS stats
    talentRecord.dtps.total = talentRecord.dtps.total + currentCombatLog.dtps
    talentRecord.dtps.count = talentRecord.dtps.count + 1
    talentRecord.dtps.avg = talentRecord.dtps.total / talentRecord.dtps.count
    talentRecord.dtps.max = math.max(talentRecord.dtps.max, currentCombatLog.dtps)
    
    -- Update success rate if this was an encounter
    if currentCombatLog.encounter and currentCombatLog.encounter.success ~= nil then
        talentRecord.successRate.total = talentRecord.successRate.total + 1
        
        if currentCombatLog.encounter.success then
            talentRecord.successRate.success = talentRecord.successRate.success + 1
        end
        
        talentRecord.successRate.rate = talentRecord.successRate.success / talentRecord.successRate.total
    end
    
    -- Limit the number of combat logs stored
    if #talentRecord.combatLogs > MAX_TALENT_ENTRIES then
        table.remove(talentRecord.combatLogs, 1)
    end
}

-- Get current talent build
function Analytics:GetCurrentTalentBuild()
    local spec = GetSpecialization()
    local specID = spec and GetSpecializationInfo(spec) or 0
    local specName = select(2, GetSpecializationInfo(spec)) or "Unknown"
    
    -- Basic build info
    local build = {
        spec = specID,
        specName = specName,
        talents = {},
        hash = specID .. "-"
    }
    
    -- Get talent information
    -- This is simplified - actual implementation would need to check the current talents API
    -- which can vary based on WoW version
    
    -- In a real implementation, we would iterate over the talent tree and collect active talents
    
    -- Generate a hash of the talent build
    local talentHash = tostring(specID)
    
    -- In a real implementation, we would add the talent IDs to the hash
    -- For now, just use the spec ID as the hash
    
    build.hash = talentHash
    
    return build
}

-- Generate insights from analytics data
function Analytics:GenerateInsights()
    -- Clear old insights
    analyticsData.insights = {}
    
    -- Check if we have enough data
    if #analyticsData.combatLogs < 3 then
        return
    end
    
    -- Calculate overall metrics
    local totalDps = 0
    local totalHps = 0
    local totalDtps = 0
    local count = 0
    
    for _, log in ipairs(analyticsData.combatLogs) do
        if log.duration >= 10 then  -- Only consider meaningful combat sessions
            totalDps = totalDps + log.dps
            totalHps = totalHps + log.hps
            totalDtps = totalDtps + log.dtps
            count = count + 1
        end
    end
    
    if count == 0 then return end
    
    local avgDps = totalDps / count
    local avgHps = totalHps / count
    local avgDtps = totalDtps / count
    
    -- Get most recent log for comparison
    local recentLog = analyticsData.combatLogs[1]
    
    -- DPS insights
    if recentLog.dps < avgDps * 0.8 then
        table.insert(analyticsData.insights, {
            type = "dps",
            severity = "warning",
            text = "Your DPS in the last combat session was " .. string.format("%.1f", recentLog.dps) .. 
                  ", which is " .. string.format("%.1f%%", (recentLog.dps / avgDps * 100)) .. 
                  " of your average (" .. string.format("%.1f", avgDps) .. "). This might indicate issues with your rotation."
        })
    elseif recentLog.dps > avgDps * 1.2 then
        table.insert(analyticsData.insights, {
            type = "dps",
            severity = "positive",
            text = "Your DPS in the last combat session was " .. string.format("%.1f", recentLog.dps) .. 
                  ", which is " .. string.format("%.1f%%", (recentLog.dps / avgDps * 100)) .. 
                  " of your average (" .. string.format("%.1f", avgDps) .. "). Great improvement!"
        })
    end
    
    -- Rotation quality insights
    local executedCount = 0
    local recommendedCount = 0
    
    for _, quality in pairs(analyticsData.rotationQuality) do
        executedCount = executedCount + quality.executed
        recommendedCount = recommendedCount + quality.recommended
    end
    
    if recommendedCount > 0 then
        local followRate = executedCount / recommendedCount
        
        if followRate < 0.6 then
            table.insert(analyticsData.insights, {
                type = "rotation",
                severity = "warning",
                text = "You're following only " .. string.format("%.1f%%", followRate * 100) .. 
                      " of rotation recommendations. Following the rotation more closely might improve your performance."
            })
        elseif followRate > 0.9 then
            table.insert(analyticsData.insights, {
                type = "rotation",
                severity = "positive",
                text = "You're following " .. string.format("%.1f%%", followRate * 100) .. 
                      " of rotation recommendations. Excellent rotation execution!"
            })
        end
    end
    
    -- Reaction time insights
    if #reactionTimes > 10 then
        local totalReaction = 0
        for _, time in ipairs(reactionTimes) do
            totalReaction = totalReaction + time
        end
        
        local avgReaction = totalReaction / #reactionTimes
        
        if avgReaction > 0.8 then
            table.insert(analyticsData.insights, {
                type = "reaction",
                severity = "warning",
                text = "Your average reaction time is " .. string.format("%.2f", avgReaction) .. 
                      " seconds. Working on reducing reaction time could improve your performance."
            })
        elseif avgReaction < 0.3 then
            table.insert(analyticsData.insights, {
                type = "reaction",
                severity = "positive",
                text = "Your average reaction time is " .. string.format("%.2f", avgReaction) .. 
                      " seconds. Excellent reaction speed!"
            })
        end
    end
    
    -- Ability usage insights
    for spellID, ability in pairs(analyticsData.abilityUsage) do
        if ability.casts > 10 and ability.failures / ability.casts > 0.3 then
            table.insert(analyticsData.insights, {
                type = "ability",
                severity = "warning",
                text = ability.name .. " is failing " .. string.format("%.1f%%", (ability.failures / ability.casts * 100)) .. 
                      " of the time. Check if you're trying to use it when it's not available or when targets are out of range."
            })
        end
    end
    
    -- Environment insights
    if recentLog.environmentMetrics.avgFps < 30 then
        table.insert(analyticsData.insights, {
            type = "environment",
            severity = "warning",
            text = "Your average framerate during combat is " .. string.format("%.1f", recentLog.environmentMetrics.avgFps) .. 
                  " FPS. Low framerate can impact your reaction time and overall performance."
        })
    end
    
    if recentLog.environmentMetrics.avgLatency > 200 then
        table.insert(analyticsData.insights, {
            type = "environment",
            severity = "warning",
            text = "Your average latency during combat is " .. string.format("%.1f", recentLog.environmentMetrics.avgLatency) .. 
                  " ms. High latency can impact your ability to respond to game events quickly."
        })
    end
    
    -- Talent insights
    if config.trackTalentPerformance then
        local currentBuild = self:GetCurrentTalentBuild()
        local currentPerformance = analyticsData.talentPerformance[currentBuild.hash]
        
        if currentPerformance and currentPerformance.dps.count > 3 then
            local bestDpsBuild = nil
            local bestDps = 0
            
            for hash, build in pairs(analyticsData.talentPerformance) do
                if build.spec == currentBuild.spec and build.dps.count > 3 and build.dps.avg > bestDps then
                    bestDpsBuild = build
                    bestDps = build.dps.avg
                end
            end
            
            if bestDpsBuild and bestDpsBuild.hash ~= currentBuild.hash and bestDpsBuild.dps.avg > currentPerformance.dps.avg * 1.1 then
                table.insert(analyticsData.insights, {
                    type = "talents",
                    severity = "suggestion",
                    text = "A different talent build for your spec has shown " .. 
                          string.format("%.1f%%", (bestDpsBuild.dps.avg / currentPerformance.dps.avg * 100) - 100) .. 
                          " higher average DPS. Consider trying that build."
                })
            end
        end
    end
}

-- Clean up old data
function Analytics:CleanupOldData()
    local currentTime = GetTime()
    local cutoffTime = currentTime - (config.logDeletionDays * 24 * 60 * 60)
    
    -- Clean up combat logs
    for i = #analyticsData.combatLogs, 1, -1 do
        if analyticsData.combatLogs[i].endTime < cutoffTime then
            table.remove(analyticsData.combatLogs, i)
        end
    end
    
    -- Clean up rotation logs
    for i = #analyticsData.rotationLogs, 1, -1 do
        if analyticsData.rotationLogs[i].timestamp < cutoffTime then
            table.remove(analyticsData.rotationLogs, i)
        end
    end
    
    -- Clean up ability usage
    for spellID, ability in pairs(analyticsData.abilityUsage) do
        if ability.lastCast < cutoffTime then
            analyticsData.abilityUsage[spellID] = nil
        end
    end
    
    WR:Debug("Analytics data cleanup completed")
}

-- Get analytics data
function Analytics:GetData()
    return analyticsData
}

-- Get insights
function Analytics:GetInsights()
    return analyticsData.insights
}

-- Get configuration
function Analytics:GetConfig()
    return config
end

-- Set configuration
function Analytics:SetConfig(newConfig)
    if not newConfig then return end
    
    for k, v in pairs(newConfig) do
        if config[k] ~= nil then  -- Only update existing settings
            config[k] = v
        end
    end
    
    WR:Debug("Updated analytics config")
}

-- Get performance summary
function Analytics:GetPerformanceSummary()
    local summary = {
        dps = {
            avg = 0,
            max = 0,
            min = 999999999,
            recent = 0
        },
        hps = {
            avg = 0,
            max = 0,
            min = 999999999,
            recent = 0
        },
        dtps = {
            avg = 0,
            max = 0,
            min = 999999999,
            recent = 0
        },
        rotationQuality = 0,
        reactionTime = 0,
        environmentQuality = 0
    }
    
    -- Calculate DPS/HPS/DTPS metrics
    local totalDps = 0
    local totalHps = 0
    local totalDtps = 0
    local count = 0
    
    for _, log in ipairs(analyticsData.combatLogs) do
        if log.duration >= 10 then  -- Only consider meaningful combat sessions
            totalDps = totalDps + log.dps
            totalHps = totalHps + log.hps
            totalDtps = totalDtps + log.dtps
            count = count + 1
            
            summary.dps.max = math.max(summary.dps.max, log.dps)
            summary.dps.min = math.min(summary.dps.min, log.dps)
            summary.hps.max = math.max(summary.hps.max, log.hps)
            summary.hps.min = math.min(summary.hps.min, log.hps)
            summary.dtps.max = math.max(summary.dtps.max, log.dtps)
            summary.dtps.min = math.min(summary.dtps.min, log.dtps)
        end
    end
    
    if count > 0 then
        summary.dps.avg = totalDps / count
        summary.hps.avg = totalHps / count
        summary.dtps.avg = totalDtps / count
        
        if #analyticsData.combatLogs > 0 then
            summary.dps.recent = analyticsData.combatLogs[1].dps
            summary.hps.recent = analyticsData.combatLogs[1].hps
            summary.dtps.recent = analyticsData.combatLogs[1].dtps
        end
    end
    
    -- Calculate rotation quality
    local executedCount = 0
    local recommendedCount = 0
    
    for _, quality in pairs(analyticsData.rotationQuality) do
        executedCount = executedCount + quality.executed
        recommendedCount = recommendedCount + quality.recommended
    end
    
    if recommendedCount > 0 then
        summary.rotationQuality = executedCount / recommendedCount
    end
    
    -- Calculate average reaction time
    if #reactionTimes > 0 then
        local total = 0
        for _, time in ipairs(reactionTimes) do
            total = total + time
        end
        summary.reactionTime = total / #reactionTimes
    end
    
    -- Calculate environment quality (simplified)
    local envCount = 0
    local fpsTotal = 0
    local latencyTotal = 0
    
    for _, log in ipairs(analyticsData.combatLogs) do
        if log.environmentMetrics and log.environmentMetrics.avgFps then
            fpsTotal = fpsTotal + log.environmentMetrics.avgFps
            latencyTotal = latencyTotal + log.environmentMetrics.avgLatency
            envCount = envCount + 1
        end
    end
    
    if envCount > 0 then
        local avgFps = fpsTotal / envCount
        local avgLatency = latencyTotal / envCount
        
        -- Convert to a 0-1 quality score
        local fpsScore = math.min(1, avgFps / 60)
        local latencyScore = math.max(0, 1 - (avgLatency / 300))
        
        summary.environmentQuality = (fpsScore + latencyScore) / 2
    end
    
    return summary
}

-- Create analytics UI
function Analytics:CreateAnalyticsUI(parent)
    if not parent then return end
    
    -- Create the analytics frame
    local frame = CreateFrame("Frame", "WindrunnerRotationsAnalyticsFrame", parent, "BackdropTemplate")
    frame:SetSize(700, 500)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    frame:SetBackdropColor(0.1, 0.1, 0.1, 1)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    
    -- Create title
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", frame, "TOP", 0, -15)
    title:SetText("WindrunnerRotations Analytics")
    
    -- Create close button
    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    
    -- Create tab buttons
    local tabWidth = 100
    local tabHeight = 24
    local tabs = {}
    local tabContents = {}
    
    local tabNames = {"Performance", "Rotation", "Insights", "Abilities", "Environment"}
    
    for i, tabName in ipairs(tabNames) do
        -- Create tab button
        local tab = CreateFrame("Button", nil, frame)
        tab:SetSize(tabWidth, tabHeight)
        tab:SetPoint("TOPLEFT", frame, "TOPLEFT", 20 + (i-1) * (tabWidth + 5), -40)
        
        local tabText = tab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        tabText:SetPoint("CENTER", tab, "CENTER", 0, 0)
        tabText:SetText(tabName)
        
        -- Create highlight texture
        local highlightTexture = tab:CreateTexture(nil, "HIGHLIGHT")
        highlightTexture:SetAllPoints()
        highlightTexture:SetColorTexture(1, 1, 1, 0.2)
        
        -- Create tab content frame
        local content = CreateFrame("Frame", nil, frame)
        content:SetSize(frame:GetWidth() - 40, frame:GetHeight() - 80)
        content:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -70)
        content:Hide()
        
        -- Set up tab behavior
        tab:SetScript("OnClick", function()
            -- Hide all contents
            for _, contentFrame in ipairs(tabContents) do
                contentFrame:Hide()
            end
            
            -- Show this content
            content:Show()
            
            -- Update tab appearance
            for _, tabButton in ipairs(tabs) do
                tabButton:SetButtonState("NORMAL")
            end
            
            tab:SetButtonState("PUSHED", true)
        end)
        
        -- Store references
        tabs[i] = tab
        tabContents[i] = content
    end
    
    -- Populate Performance tab
    local performanceContent = tabContents[1]
    
    -- DPS/HPS/DTPS display
    local dpsTitle = performanceContent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    dpsTitle:SetPoint("TOPLEFT", performanceContent, "TOPLEFT", 0, -10)
    dpsTitle:SetText("Damage Per Second")
    
    local hpsTitle = performanceContent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    hpsTitle:SetPoint("TOPLEFT", performanceContent, "TOPLEFT", 0, -100)
    hpsTitle:SetText("Healing Per Second")
    
    local dtpsTitle = performanceContent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    dtpsTitle:SetPoint("TOPLEFT", performanceContent, "TOPLEFT", 0, -190)
    dtpsTitle:SetText("Damage Taken Per Second")
    
    -- Create performance summary
    local function CreatePerformanceDisplay(header, yOffset, metric)
        local statsFrame = CreateFrame("Frame", nil, performanceContent, "BackdropTemplate")
        statsFrame:SetSize(600, 60)
        statsFrame:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -10)
        statsFrame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        statsFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
        
        -- Create metrics
        local avgLabel = statsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        avgLabel:SetPoint("TOPLEFT", statsFrame, "TOPLEFT", 15, -15)
        avgLabel:SetText("Average:")
        
        local avgValue = statsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        avgValue:SetPoint("TOPLEFT", avgLabel, "TOPRIGHT", 5, 0)
        avgValue:SetText("0")
        
        local maxLabel = statsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        maxLabel:SetPoint("TOPLEFT", statsFrame, "TOPLEFT", 150, -15)
        maxLabel:SetText("Maximum:")
        
        local maxValue = statsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        maxValue:SetPoint("TOPLEFT", maxLabel, "TOPRIGHT", 5, 0)
        maxValue:SetText("0")
        
        local minLabel = statsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        minLabel:SetPoint("TOPLEFT", statsFrame, "TOPLEFT", 300, -15)
        minLabel:SetText("Minimum:")
        
        local minValue = statsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        minValue:SetPoint("TOPLEFT", minLabel, "TOPRIGHT", 5, 0)
        minValue:SetText("0")
        
        local recentLabel = statsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        recentLabel:SetPoint("TOPLEFT", avgLabel, "BOTTOMLEFT", 0, -10)
        recentLabel:SetText("Recent:")
        
        local recentValue = statsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        recentValue:SetPoint("TOPLEFT", recentLabel, "TOPRIGHT", 5, 0)
        recentValue:SetText("0")
        
        local sessionLabel = statsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        sessionLabel:SetPoint("TOPLEFT", maxLabel, "BOTTOMLEFT", 0, -10)
        sessionLabel:SetText("Sessions:")
        
        local sessionValue = statsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        sessionValue:SetPoint("TOPLEFT", sessionLabel, "TOPRIGHT", 5, 0)
        sessionValue:SetText("0")
        
        return {
            frame = statsFrame,
            avgValue = avgValue,
            maxValue = maxValue,
            minValue = minValue,
            recentValue = recentValue,
            sessionValue = sessionValue,
            metric = metric
        }
    end
    
    local dpsDisplay = CreatePerformanceDisplay(dpsTitle, -40, "dps")
    local hpsDisplay = CreatePerformanceDisplay(hpsTitle, -130, "hps")
    local dtpsDisplay = CreatePerformanceDisplay(dtpsTitle, -220, "dtps")
    
    -- Populate Rotation tab
    local rotationContent = tabContents[2]
    
    local rotationTitle = rotationContent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    rotationTitle:SetPoint("TOP", rotationContent, "TOP", 0, -10)
    rotationTitle:SetText("Rotation Analysis")
    
    -- Create rotation quality display
    local qualityFrame = CreateFrame("Frame", nil, rotationContent, "BackdropTemplate")
    qualityFrame:SetSize(600, 100)
    qualityFrame:SetPoint("TOP", rotationTitle, "BOTTOM", 0, -20)
    qualityFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    qualityFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
    
    local followRateLabel = qualityFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    followRateLabel:SetPoint("TOPLEFT", qualityFrame, "TOPLEFT", 15, -15)
    followRateLabel:SetText("Rotation Follow Rate:")
    
    local followRateValue = qualityFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    followRateValue:SetPoint("TOPLEFT", followRateLabel, "TOPRIGHT", 5, 0)
    followRateValue:SetText("0%")
    
    local reactionTimeLabel = qualityFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    reactionTimeLabel:SetPoint("TOPLEFT", followRateLabel, "BOTTOMLEFT", 0, -10)
    reactionTimeLabel:SetText("Average Reaction Time:")
    
    local reactionTimeValue = qualityFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    reactionTimeValue:SetPoint("TOPLEFT", reactionTimeLabel, "TOPRIGHT", 5, 0)
    reactionTimeValue:SetText("0.00 seconds")
    
    local recommendedLabel = qualityFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    recommendedLabel:SetPoint("TOPLEFT", reactionTimeLabel, "BOTTOMLEFT", 0, -10)
    recommendedLabel:SetText("Recommended Abilities:")
    
    local recommendedValue = qualityFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    recommendedValue:SetPoint("TOPLEFT", recommendedLabel, "TOPRIGHT", 5, 0)
    recommendedValue:SetText("0")
    
    local executedLabel = qualityFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    executedLabel:SetPoint("TOPLEFT", qualityFrame, "TOPLEFT", 300, -15)
    executedLabel:SetText("Executed Abilities:")
    
    local executedValue = qualityFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    executedValue:SetPoint("TOPLEFT", executedLabel, "TOPRIGHT", 5, 0)
    executedValue:SetText("0")
    
    local skippedLabel = qualityFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    skippedLabel:SetPoint("TOPLEFT", executedLabel, "BOTTOMLEFT", 0, -10)
    skippedLabel:SetText("Skipped Abilities:")
    
    local skippedValue = qualityFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    skippedValue:SetPoint("TOPLEFT", skippedLabel, "TOPRIGHT", 5, 0)
    skippedValue:SetText("0")
    
    -- Create rotation history display
    local historyTitle = rotationContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    historyTitle:SetPoint("TOPLEFT", qualityFrame, "BOTTOMLEFT", 0, -15)
    historyTitle:SetText("Recent Rotation Decisions:")
    
    local historyFrame = CreateFrame("ScrollFrame", nil, rotationContent, "UIPanelScrollFrameTemplate")
    historyFrame:SetSize(600, 250)
    historyFrame:SetPoint("TOPLEFT", historyTitle, "BOTTOMLEFT", 0, -5)
    
    local historyContent = CreateFrame("Frame", nil, historyFrame)
    historyContent:SetSize(historyFrame:GetWidth() - 30, 1)  -- Height will be set dynamically
    historyFrame:SetScrollChild(historyContent)
    
    -- Populate Insights tab
    local insightsContent = tabContents[3]
    
    local insightsTitle = insightsContent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    insightsTitle:SetPoint("TOP", insightsContent, "TOP", 0, -10)
    insightsTitle:SetText("Performance Insights")
    
    local insightsScroll = CreateFrame("ScrollFrame", nil, insightsContent, "UIPanelScrollFrameTemplate")
    insightsScroll:SetSize(insightsContent:GetWidth() - 30, insightsContent:GetHeight() - 40)
    insightsScroll:SetPoint("TOP", insightsTitle, "BOTTOM", 0, -10)
    
    local insightsScrollChild = CreateFrame("Frame", nil, insightsScroll)
    insightsScrollChild:SetSize(insightsScroll:GetWidth(), 1)  -- Height will be set dynamically
    insightsScroll:SetScrollChild(insightsScrollChild)
    
    -- Populate Abilities tab
    local abilitiesContent = tabContents[4]
    
    local abilitiesTitle = abilitiesContent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    abilitiesTitle:SetPoint("TOP", abilitiesContent, "TOP", 0, -10)
    abilitiesTitle:SetText("Ability Usage Statistics")
    
    local abilitiesScroll = CreateFrame("ScrollFrame", nil, abilitiesContent, "UIPanelScrollFrameTemplate")
    abilitiesScroll:SetSize(abilitiesContent:GetWidth() - 30, abilitiesContent:GetHeight() - 40)
    abilitiesScroll:SetPoint("TOP", abilitiesTitle, "BOTTOM", 0, -10)
    
    local abilitiesScrollChild = CreateFrame("Frame", nil, abilitiesScroll)
    abilitiesScrollChild:SetSize(abilitiesScroll:GetWidth(), 1)  -- Height will be set dynamically
    abilitiesScroll:SetScrollChild(abilitiesScrollChild)
    
    -- Populate Environment tab
    local environmentContent = tabContents[5]
    
    local environmentTitle = environmentContent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    environmentTitle:SetPoint("TOP", environmentContent, "TOP", 0, -10)
    environmentTitle:SetText("Environment Statistics")
    
    -- Create FPS display
    local fpsFrame = CreateFrame("Frame", nil, environmentContent, "BackdropTemplate")
    fpsFrame:SetSize(600, 80)
    fpsFrame:SetPoint("TOP", environmentTitle, "BOTTOM", 0, -20)
    fpsFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    fpsFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
    
    local fpsTitle = fpsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fpsTitle:SetPoint("TOP", fpsFrame, "TOP", 0, -10)
    fpsTitle:SetText("Framerate (FPS)")
    
    local fpsAvgLabel = fpsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fpsAvgLabel:SetPoint("TOPLEFT", fpsFrame, "TOPLEFT", 15, -30)
    fpsAvgLabel:SetText("Average FPS:")
    
    local fpsAvgValue = fpsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    fpsAvgValue:SetPoint("TOPLEFT", fpsAvgLabel, "TOPRIGHT", 5, 0)
    fpsAvgValue:SetText("0")
    
    local fpsMinLabel = fpsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fpsMinLabel:SetPoint("TOPLEFT", fpsFrame, "TOPLEFT", 200, -30)
    fpsMinLabel:SetText("Minimum FPS:")
    
    local fpsMinValue = fpsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    fpsMinValue:SetPoint("TOPLEFT", fpsMinLabel, "TOPRIGHT", 5, 0)
    fpsMinValue:SetText("0")
    
    local fpsMaxLabel = fpsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fpsMaxLabel:SetPoint("TOPLEFT", fpsFrame, "TOPLEFT", 400, -30)
    fpsMaxLabel:SetText("Maximum FPS:")
    
    local fpsMaxValue = fpsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    fpsMaxValue:SetPoint("TOPLEFT", fpsMaxLabel, "TOPRIGHT", 5, 0)
    fpsMaxValue:SetText("0")
    
    local fpsCurrentLabel = fpsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fpsCurrentLabel:SetPoint("TOPLEFT", fpsAvgLabel, "BOTTOMLEFT", 0, -10)
    fpsCurrentLabel:SetText("Current FPS:")
    
    local fpsCurrentValue = fpsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    fpsCurrentValue:SetPoint("TOPLEFT", fpsCurrentLabel, "TOPRIGHT", 5, 0)
    fpsCurrentValue:SetText("0")
    
    -- Create Latency display
    local latencyFrame = CreateFrame("Frame", nil, environmentContent, "BackdropTemplate")
    latencyFrame:SetSize(600, 80)
    latencyFrame:SetPoint("TOP", fpsFrame, "BOTTOM", 0, -20)
    latencyFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    latencyFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
    
    local latencyTitle = latencyFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    latencyTitle:SetPoint("TOP", latencyFrame, "TOP", 0, -10)
    latencyTitle:SetText("Network Latency (ms)")
    
    local latencyAvgLabel = latencyFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    latencyAvgLabel:SetPoint("TOPLEFT", latencyFrame, "TOPLEFT", 15, -30)
    latencyAvgLabel:SetText("Average Latency:")
    
    local latencyAvgValue = latencyFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    latencyAvgValue:SetPoint("TOPLEFT", latencyAvgLabel, "TOPRIGHT", 5, 0)
    latencyAvgValue:SetText("0 ms")
    
    local latencyMinLabel = latencyFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    latencyMinLabel:SetPoint("TOPLEFT", latencyFrame, "TOPLEFT", 200, -30)
    latencyMinLabel:SetText("Minimum Latency:")
    
    local latencyMinValue = latencyFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    latencyMinValue:SetPoint("TOPLEFT", latencyMinLabel, "TOPRIGHT", 5, 0)
    latencyMinValue:SetText("0 ms")
    
    local latencyMaxLabel = latencyFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    latencyMaxLabel:SetPoint("TOPLEFT", latencyFrame, "TOPLEFT", 400, -30)
    latencyMaxLabel:SetText("Maximum Latency:")
    
    local latencyMaxValue = latencyFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    latencyMaxValue:SetPoint("TOPLEFT", latencyMaxLabel, "TOPRIGHT", 5, 0)
    latencyMaxValue:SetText("0 ms")
    
    local latencyCurrentLabel = latencyFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    latencyCurrentLabel:SetPoint("TOPLEFT", latencyAvgLabel, "BOTTOMLEFT", 0, -10)
    latencyCurrentLabel:SetText("Current Latency:")
    
    local latencyCurrentValue = latencyFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    latencyCurrentValue:SetPoint("TOPLEFT", latencyCurrentLabel, "TOPRIGHT", 5, 0)
    latencyCurrentValue:SetText("0 ms")
    
    -- Session information
    local sessionFrame = CreateFrame("Frame", nil, environmentContent, "BackdropTemplate")
    sessionFrame:SetSize(600, 100)
    sessionFrame:SetPoint("TOP", latencyFrame, "BOTTOM", 0, -20)
    sessionFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    sessionFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
    
    local sessionTitle = sessionFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    sessionTitle:SetPoint("TOP", sessionFrame, "TOP", 0, -10)
    sessionTitle:SetText("Session Information")
    
    local sessionCountLabel = sessionFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    sessionCountLabel:SetPoint("TOPLEFT", sessionFrame, "TOPLEFT", 15, -30)
    sessionCountLabel:SetText("Combat Sessions:")
    
    local sessionCountValue = sessionFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    sessionCountValue:SetPoint("TOPLEFT", sessionCountLabel, "TOPRIGHT", 5, 0)
    sessionCountValue:SetText("0")
    
    local encounterCountLabel = sessionFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    encounterCountLabel:SetPoint("TOPLEFT", sessionFrame, "TOPLEFT", 200, -30)
    encounterCountLabel:SetText("Encounters:")
    
    local encounterCountValue = sessionFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    encounterCountValue:SetPoint("TOPLEFT", encounterCountLabel, "TOPRIGHT", 5, 0)
    encounterCountValue:SetText("0")
    
    local totalTimeLabel = sessionFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    totalTimeLabel:SetPoint("TOPLEFT", sessionFrame, "TOPLEFT", 400, -30)
    totalTimeLabel:SetText("Total Combat Time:")
    
    local totalTimeValue = sessionFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    totalTimeValue:SetPoint("TOPLEFT", totalTimeLabel, "TOPRIGHT", 5, 0)
    totalTimeValue:SetText("0:00")
    
    local avgSessionLabel = sessionFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    avgSessionLabel:SetPoint("TOPLEFT", sessionCountLabel, "BOTTOMLEFT", 0, -10)
    avgSessionLabel:SetText("Avg Session Length:")
    
    local avgSessionValue = sessionFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    avgSessionValue:SetPoint("TOPLEFT", avgSessionLabel, "TOPRIGHT", 5, 0)
    avgSessionValue:SetText("0:00")
    
    local successRateLabel = sessionFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    successRateLabel:SetPoint("TOPLEFT", encounterCountLabel, "BOTTOMLEFT", 0, -10)
    successRateLabel:SetText("Encounter Success Rate:")
    
    local successRateValue = sessionFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    successRateValue:SetPoint("TOPLEFT", successRateLabel, "TOPRIGHT", 5, 0)
    successRateValue:SetText("0%")
    
    -- Functions to update UI
    
    -- Update performance tab
    local function UpdatePerformanceTab()
        local summary = Analytics:GetPerformanceSummary()
        
        -- Update DPS display
        dpsDisplay.avgValue:SetText(string.format("%.1f", summary.dps.avg))
        dpsDisplay.maxValue:SetText(string.format("%.1f", summary.dps.max))
        dpsDisplay.minValue:SetText(summary.dps.min < 999999999 and string.format("%.1f", summary.dps.min) or "0")
        dpsDisplay.recentValue:SetText(string.format("%.1f", summary.dps.recent))
        dpsDisplay.sessionValue:SetText(tostring(#analyticsData.combatLogs))
        
        -- Update HPS display
        hpsDisplay.avgValue:SetText(string.format("%.1f", summary.hps.avg))
        hpsDisplay.maxValue:SetText(string.format("%.1f", summary.hps.max))
        hpsDisplay.minValue:SetText(summary.hps.min < 999999999 and string.format("%.1f", summary.hps.min) or "0")
        hpsDisplay.recentValue:SetText(string.format("%.1f", summary.hps.recent))
        hpsDisplay.sessionValue:SetText(tostring(#analyticsData.combatLogs))
        
        -- Update DTPS display
        dtpsDisplay.avgValue:SetText(string.format("%.1f", summary.dtps.avg))
        dtpsDisplay.maxValue:SetText(string.format("%.1f", summary.dtps.max))
        dtpsDisplay.minValue:SetText(summary.dtps.min < 999999999 and string.format("%.1f", summary.dtps.min) or "0")
        dtpsDisplay.recentValue:SetText(string.format("%.1f", summary.dtps.recent))
        dtpsDisplay.sessionValue:SetText(tostring(#analyticsData.combatLogs))
    end
    
    -- Update rotation tab
    local function UpdateRotationTab()
        -- Calculate rotation quality metrics
        local executedCount = 0
        local recommendedCount = 0
        local skippedCount = 0
        
        for _, quality in pairs(analyticsData.rotationQuality) do
            executedCount = executedCount + quality.executed
            recommendedCount = recommendedCount + quality.recommended
            skippedCount = skippedCount + quality.skipped
        end
        
        -- Update rotation quality display
        local followRate = recommendedCount > 0 and (executedCount / recommendedCount) or 0
        followRateValue:SetText(string.format("%.1f%%", followRate * 100))
        
        -- Calculate average reaction time
        local avgReactionTime = 0
        if #reactionTimes > 0 then
            local total = 0
            for _, time in ipairs(reactionTimes) do
                total = total + time
            end
            avgReactionTime = total / #reactionTimes
        end
        
        reactionTimeValue:SetText(string.format("%.2f seconds", avgReactionTime))
        
        -- Update counts
        recommendedValue:SetText(tostring(recommendedCount))
        executedValue:SetText(tostring(executedCount))
        skippedValue:SetText(tostring(skippedCount))
        
        -- Update rotation history
        -- Clear existing entries
        for i = historyContent:GetNumChildren(), 1, -1 do
            local child = select(i, historyContent:GetChildren())
            child:Hide()
            child:SetParent(nil)
        end
        
        -- Add recent rotation decisions
        local decisions = {}
        local maxToShow = 10
        
        -- Get most recent decisions
        for i = #analyticsData.rotationLogs, math.max(1, #analyticsData.rotationLogs - maxToShow), -1 do
            table.insert(decisions, analyticsData.rotationLogs[i])
        end
        
        -- Display decisions
        local entryHeight = 40
        local totalHeight = 10
        
        for i, decision in ipairs(decisions) do
            local entryFrame = CreateFrame("Frame", nil, historyContent, "BackdropTemplate")
            entryFrame:SetSize(historyContent:GetWidth() - 20, entryHeight)
            entryFrame:SetPoint("TOPLEFT", historyContent, "TOPLEFT", 10, -totalHeight)
            entryFrame:SetBackdrop({
                bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
                edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
                tile = true,
                tileSize = 16,
                edgeSize = 16,
                insets = { left = 4, right = 4, top = 4, bottom = 4 }
            })
            entryFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
            
            -- Create spell icon
            local icon = entryFrame:CreateTexture(nil, "ARTWORK")
            icon:SetSize(32, 32)
            icon:SetPoint("LEFT", entryFrame, "LEFT", 8, 0)
            
            local iconTexture = select(3, GetSpellInfo(decision.spellID)) or "Interface\\Icons\\INV_Misc_QuestionMark"
            icon:SetTexture(iconTexture)
            
            -- Create spell name
            local name = entryFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            name:SetPoint("LEFT", icon, "RIGHT", 8, 5)
            name:SetText(decision.spellName)
            
            -- Create timestamp
            local timeText = entryFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            timeText:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -2)
            
            local timeAgo = GetTime() - decision.timestamp
            local timeString = ""
            
            if timeAgo < 60 then
                timeString = string.format("%.0f seconds ago", timeAgo)
            elseif timeAgo < 3600 then
                timeString = string.format("%.0f minutes ago", timeAgo / 60)
            else
                timeString = string.format("%.1f hours ago", timeAgo / 3600)
            end
            
            timeText:SetText(timeString)
            
            -- Create status indicator
            local status = entryFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            status:SetPoint("RIGHT", entryFrame, "RIGHT", -8, 0)
            
            if decision.executed then
                status:SetText("Executed")
                status:SetTextColor(0, 1, 0)
            elseif decision.skipped then
                status:SetText("Skipped")
                status:SetTextColor(1, 0, 0)
            else
                status:SetText("Pending")
                status:SetTextColor(1, 1, 0)
            end
            
            totalHeight = totalHeight + entryHeight + 5
        end
        
        historyContent:SetHeight(math.max(totalHeight, historyFrame:GetHeight()))
    end
    
    -- Update insights tab
    local function UpdateInsightsTab()
        -- Clear existing entries
        for i = insightsScrollChild:GetNumChildren(), 1, -1 do
            local child = select(i, insightsScrollChild:GetChildren())
            child:Hide()
            child:SetParent(nil)
        end
        
        -- Get insights
        local insights = Analytics:GetInsights()
        
        -- Display insights
        local entryHeight = 60
        local totalHeight = 10
        
        if #insights == 0 then
            local noInsightsText = insightsScrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            noInsightsText:SetPoint("CENTER", insightsScrollChild, "CENTER", 0, 0)
            noInsightsText:SetText("No insights available yet. Complete more combat sessions to generate insights.")
            totalHeight = insightsScrollChild:GetHeight()
        else
            for i, insight in ipairs(insights) do
                local entryFrame = CreateFrame("Frame", nil, insightsScrollChild, "BackdropTemplate")
                entryFrame:SetSize(insightsScrollChild:GetWidth() - 20, entryHeight)
                entryFrame:SetPoint("TOPLEFT", insightsScrollChild, "TOPLEFT", 10, -totalHeight)
                entryFrame:SetBackdrop({
                    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
                    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
                    tile = true,
                    tileSize = 16,
                    edgeSize = 16,
                    insets = { left = 4, right = 4, top = 4, bottom = 4 }
                })
                entryFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
                
                -- Create insight type label
                local typeLabel = entryFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                typeLabel:SetPoint("TOPLEFT", entryFrame, "TOPLEFT", 10, -10)
                typeLabel:SetText(insight.type:gsub("^%l", string.upper) .. ":")
                
                -- Set color based on severity
                if insight.severity == "warning" then
                    typeLabel:SetTextColor(1, 0.7, 0)
                elseif insight.severity == "positive" then
                    typeLabel:SetTextColor(0, 1, 0)
                elseif insight.severity == "suggestion" then
                    typeLabel:SetTextColor(0, 0.7, 1)
                end
                
                -- Create insight text
                local insightText = entryFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                insightText:SetPoint("TOPLEFT", typeLabel, "BOTTOMLEFT", 5, -2)
                insightText:SetPoint("RIGHT", entryFrame, "RIGHT", -10, 0)
                insightText:SetJustifyH("LEFT")
                insightText:SetJustifyV("TOP")
                insightText:SetText(insight.text)
                
                -- Adjust height based on text
                insightText:SetWidth(entryFrame:GetWidth() - 20)
                local textHeight = insightText:GetStringHeight() + 30
                if textHeight > entryHeight then
                    entryFrame:SetHeight(textHeight)
                    entryHeight = textHeight
                end
                
                totalHeight = totalHeight + entryFrame:GetHeight() + 5
            end
        end
        
        insightsScrollChild:SetHeight(math.max(totalHeight, insightsScroll:GetHeight()))
    end
    
    -- Update abilities tab
    local function UpdateAbilitiesTab()
        -- Clear existing entries
        for i = abilitiesScrollChild:GetNumChildren(), 1, -1 do
            local child = select(i, abilitiesScrollChild:GetChildren())
            child:Hide()
            child:SetParent(nil)
        end
        
        -- Get abilities data
        local abilities = {}
        
        for spellID, ability in pairs(analyticsData.abilityUsage) do
            if ability.casts > 0 then
                table.insert(abilities, ability)
            end
        end
        
        -- Sort abilities by cast count
        table.sort(abilities, function(a, b) return a.casts > b.casts end)
        
        -- Display abilities
        local entryHeight = 90
        local totalHeight = 10
        
        if #abilities == 0 then
            local noAbilitiesText = abilitiesScrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            noAbilitiesText:SetPoint("CENTER", abilitiesScrollChild, "CENTER", 0, 0)
            noAbilitiesText:SetText("No ability usage data available yet.")
            totalHeight = abilitiesScrollChild:GetHeight()
        else
            for i, ability in ipairs(abilities) do
                local entryFrame = CreateFrame("Frame", nil, abilitiesScrollChild, "BackdropTemplate")
                entryFrame:SetSize(abilitiesScrollChild:GetWidth() - 20, entryHeight)
                entryFrame:SetPoint("TOPLEFT", abilitiesScrollChild, "TOPLEFT", 10, -totalHeight)
                entryFrame:SetBackdrop({
                    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
                    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
                    tile = true,
                    tileSize = 16,
                    edgeSize = 16,
                    insets = { left = 4, right = 4, top = 4, bottom = 4 }
                })
                entryFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
                
                -- Create spell icon
                local icon = entryFrame:CreateTexture(nil, "ARTWORK")
                icon:SetSize(48, 48)
                icon:SetPoint("TOPLEFT", entryFrame, "TOPLEFT", 10, -10)
                
                local iconTexture = select(3, GetSpellInfo(ability.id)) or "Interface\\Icons\\INV_Misc_QuestionMark"
                icon:SetTexture(iconTexture)
                
                -- Create spell name
                local name = entryFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
                name:SetPoint("TOPLEFT", icon, "TOPRIGHT", 10, -5)
                name:SetText(ability.name)
                
                -- Create cast count
                local castsLabel = entryFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                castsLabel:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -5)
                castsLabel:SetText("Total Casts:")
                
                local castsValue = entryFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                castsValue:SetPoint("TOPLEFT", castsLabel, "TOPRIGHT", 5, 0)
                castsValue:SetText(tostring(ability.casts))
                
                -- Create success rate
                local successLabel = entryFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                successLabel:SetPoint("TOPLEFT", castsLabel, "BOTTOMLEFT", 0, -5)
                successLabel:SetText("Success Rate:")
                
                local successRate = ability.casts > 0 and (ability.successes / ability.casts * 100) or 0
                
                local successValue = entryFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                successValue:SetPoint("TOPLEFT", successLabel, "TOPRIGHT", 5, 0)
                successValue:SetText(string.format("%.1f%%", successRate))
                
                -- Create in-combat percentage
                local combatLabel = entryFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                combatLabel:SetPoint("LEFT", castsLabel, "LEFT", 200, 0)
                combatLabel:SetText("In Combat:")
                
                local combatPercentage = ability.casts > 0 and (ability.inCombatCasts / ability.casts * 100) or 0
                
                local combatValue = entryFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                combatValue:SetPoint("TOPLEFT", combatLabel, "TOPRIGHT", 5, 0)
                combatValue:SetText(string.format("%.1f%%", combatPercentage))
                
                -- Create reaction time (if available)
                local reactionMetrics = analyticsData.reactionMetrics[ability.id]
                
                if reactionMetrics and reactionMetrics.avgReactionTime > 0 then
                    local reactionLabel = entryFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                    reactionLabel:SetPoint("LEFT", successLabel, "LEFT", 200, 0)
                    reactionLabel:SetText("Avg Reaction:")
                    
                    local reactionValue = entryFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                    reactionValue:SetPoint("TOPLEFT", reactionLabel, "TOPRIGHT", 5, 0)
                    reactionValue:SetText(string.format("%.2f sec", reactionMetrics.avgReactionTime))
                end
                
                totalHeight = totalHeight + entryHeight + 5
            end
        end
        
        abilitiesScrollChild:SetHeight(math.max(totalHeight, abilitiesScroll:GetHeight()))
    end
    
    -- Update environment tab
    local function UpdateEnvironmentTab()
        -- Update FPS display
        local currentFps = GetFramerate()
        fpsCurrentValue:SetText(string.format("%.1f", currentFps))
        
        -- Update latency display
        local _, _, latencyHome, latencyWorld = GetNetStats()
        local currentLatency = math.max(latencyHome, latencyWorld)
        latencyCurrentValue:SetText(string.format("%d ms", currentLatency))
        
        -- Calculate averages from combat logs
        local fpsTotal = 0
        local latencyTotal = 0
        local fpsMin = 999
        local fpsMax = 0
        local latencyMin = 9999
        local latencyMax = 0
        local logCount = 0
        
        for _, log in ipairs(analyticsData.combatLogs) do
            if log.environmentMetrics and log.environmentMetrics.avgFps then
                fpsTotal = fpsTotal + log.environmentMetrics.avgFps
                fpsMin = math.min(fpsMin, log.environmentMetrics.minFps)
                fpsMax = math.max(fpsMax, log.environmentMetrics.maxFps)
                
                latencyTotal = latencyTotal + log.environmentMetrics.avgLatency
                latencyMin = math.min(latencyMin, log.environmentMetrics.minLatency)
                latencyMax = math.max(latencyMax, log.environmentMetrics.maxLatency)
                
                logCount = logCount + 1
            end
        end
        
        if logCount > 0 then
            fpsAvgValue:SetText(string.format("%.1f", fpsTotal / logCount))
            fpsMinValue:SetText(string.format("%.1f", fpsMin))
            fpsMaxValue:SetText(string.format("%.1f", fpsMax))
            
            latencyAvgValue:SetText(string.format("%d ms", latencyTotal / logCount))
            latencyMinValue:SetText(string.format("%d ms", latencyMin))
            latencyMaxValue:SetText(string.format("%d ms", latencyMax))
        end
        
        -- Update session info
        sessionCountValue:SetText(tostring(#analyticsData.combatLogs))
        
        -- Count encounters
        local encounterCount = 0
        for _, encounters in pairs(analyticsData.encounterData) do
            encounterCount = encounterCount + #encounters
        end
        
        encounterCountValue:SetText(tostring(encounterCount))
        
        -- Calculate total combat time
        local totalTime = 0
        local successCount = 0
        local totalEncounters = 0
        
        for _, log in ipairs(analyticsData.combatLogs) do
            if log.duration then
                totalTime = totalTime + log.duration
            end
            
            if log.encounter and log.encounter.success ~= nil then
                totalEncounters = totalEncounters + 1
                if log.encounter.success then
                    successCount = successCount + 1
                end
            end
        end
        
        -- Format as MM:SS
        local minutes = math.floor(totalTime / 60)
        local seconds = math.floor(totalTime % 60)
        totalTimeValue:SetText(string.format("%d:%02d", minutes, seconds))
        
        -- Calculate average session length
        local avgTime = #analyticsData.combatLogs > 0 and (totalTime / #analyticsData.combatLogs) or 0
        local avgMinutes = math.floor(avgTime / 60)
        local avgSeconds = math.floor(avgTime % 60)
        avgSessionValue:SetText(string.format("%d:%02d", avgMinutes, avgSeconds))
        
        -- Calculate success rate
        local successRate = totalEncounters > 0 and (successCount / totalEncounters * 100) or 0
        successRateValue:SetText(string.format("%.1f%%", successRate))
    end
    
    -- Set up refresh timer
    frame:SetScript("OnUpdate", function(self, elapsed)
        self.updateTimer = (self.updateTimer or 0) + elapsed
        
        if self.updateTimer >= 1 then
            self.updateTimer = 0
            
            if frame:IsShown() then
                -- Update the active tab
                for i, content in ipairs(tabContents) do
                    if content:IsShown() then
                        if i == 1 then -- Performance tab
                            UpdatePerformanceTab()
                        elseif i == 2 then -- Rotation tab
                            UpdateRotationTab()
                        elseif i == 3 then -- Insights tab
                            UpdateInsightsTab()
                        elseif i == 4 then -- Abilities tab
                            UpdateAbilitiesTab()
                        elseif i == 5 then -- Environment tab
                            UpdateEnvironmentTab()
                        end
                        break
                    end
                end
            end
        end
    end)
    
    -- Set up tab switching behavior
    tabs[1]:Click()
    
    -- Hide by default
    frame:Hide()
    
    return frame
end

-- Initialize the module
Analytics:Initialize()

return Analytics