------------------------------------------
-- WindrunnerRotations - Combat Analysis
-- Author: VortexQ8
-- The War Within Season 2
------------------------------------------

local addonName, WR = ...
local CombatAnalysis = {}
WR.CombatAnalysis = CombatAnalysis

-- Dependencies
local API = WR.API
local ConfigRegistry = WR.ConfigRegistry
local ModuleManager = WR.ModuleManager
local PerformanceManager = WR.PerformanceManager

-- Combat data
local isEnabled = true
local combatLogFrame = nil
local playerGUID = nil
local currentTargetGUID = nil
local currentFocusGUID = nil
local inCombat = false
local combatStartTime = 0
local combatDuration = 0
local combatEvents = {}
local damageDone = {}
local damageTaken = {}
local healingDone = {}
local healingTaken = {}
local interruptsDone = {}
local interruptsMissed = {}
local spellCasts = {}
local spellHits = {}
local spellMisses = {}
local spellReflects = {}
local spellDodges = {}
local spellParries = {}
local spellImmunes = {}
local spellResists = {}
local spellEvades = {}
local resourceGain = {}
local resourceSpent = {}
local buffGains = {}
local buffFades = {}
local debuffGains = {}
local debuffFades = {}
local enemyCasts = {}
local ccEvents = {}
local deathEvents = {}
local environmentalDamage = {}
local missedInterrupts = {}
local missedCCs = {}
local MAX_EVENT_HISTORY = 1000
local combatEventTimers = {}
local patternRecognition = {}
local bossModuleEvents = {}
local bossAbilityTimers = {}
local currentBossEncounter = nil
local currentBossPhase = nil
local bossPhaseStartTimes = {}
local environmentalEffects = {}
local playerStatistics = {}
local performanceMetrics = {}
local combatLogProcessingTime = 0
local combatLogEventsProcessed = 0
local isProcessingPaused = false
local lastProcessedEventTime = 0
local MAX_PROCESS_TIME_PER_FRAME = 5 -- ms
local processingQueue = {}
local MAX_QUEUE_SIZE = 500
local eventHandlers = {}
local performanceTracking = {}
local lastPerformanceCheck = 0
local processFrequency = 0.1 -- Process combat log every 0.1 seconds
local combatLogEnabled = true
local historyLength = 30 -- 30 seconds of combat history
local tankTracking = {}
local healerTracking = {}
local recentCombatString = ""
local bossAbilityHistory = {}
local lastBossAbility = {}
local predictionConfidence = {}
local rotationEfficiency = {}
local lateInterrupts = {}
local missedDefensives = {}
local defensiveOpportunities = {}
local eventFilters = {}
local quickAccessStats = {}
local partyMemberTracking = {}
local combatDifficulty = "unknown"
local playerClass = nil
local playerSpec = nil
local playerLevel = nil
local playerRole = nil
local threatSituation = {}
local combatMetadata = {
    instanceID = nil,
    encounterID = nil,
    difficultyID = nil,
    groupSize = 0,
    success = false,
    startTime = 0,
    endTime = 0,
    wipes = 0
}

-- Combat event types
local EVENT_TYPES = {
    DAMAGE = "damage",
    HEALING = "healing",
    CAST = "cast",
    INTERRUPT = "interrupt",
    BUFF = "buff",
    DEBUFF = "debuff",
    RESOURCE = "resource",
    DEATH = "death",
    CC = "cc",
    DISPEL = "dispel",
    ENVIRONMENTAL = "environmental"
}

-- Initialize the Combat Analysis
function CombatAnalysis:Initialize()
    -- Register settings
    self:RegisterSettings()
    
    -- Create combat log frame
    self:CreateCombatLogFrame()
    
    -- Register events
    self:RegisterEvents()
    
    -- Get player information
    self:UpdatePlayerInfo()
    
    -- Initialize event handlers
    self:InitializeEventHandlers()
    
    -- Initialize pattern recognition
    self:InitializePatternRecognition()
    
    API.PrintDebug("Combat Analysis initialized")
    return true
end

-- Register settings
function CombatAnalysis:RegisterSettings()
    ConfigRegistry:RegisterSettings("CombatAnalysis", {
        generalSettings = {
            enableCombatAnalysis = {
                displayName = "Enable Combat Analysis",
                description = "Analyze combat events for better performance",
                type = "toggle",
                default = true
            },
            processingFrequency = {
                displayName = "Processing Frequency",
                description = "How often to process combat log events (seconds)",
                type = "slider",
                min = 0.05,
                max = 0.5,
                step = 0.05,
                default = 0.1
            },
            historyLength = {
                displayName = "History Length",
                description = "How many seconds of combat history to keep",
                type = "slider",
                min = 10,
                max = 60,
                step = 5,
                default = 30
            },
            enablePredictiveAnalysis = {
                displayName = "Predictive Analysis",
                description = "Predict future events based on patterns",
                type = "toggle",
                default = true
            }
        },
        eventTracking = {
            trackDamage = {
                displayName = "Track Damage",
                description = "Track damage done and taken",
                type = "toggle",
                default = true
            },
            trackHealing = {
                displayName = "Track Healing",
                description = "Track healing done and taken",
                type = "toggle",
                default = true
            },
            trackInterrupts = {
                displayName = "Track Interrupts",
                description = "Track interrupts done and missed",
                type = "toggle",
                default = true
            },
            trackBuffsDebuffs = {
                displayName = "Track Buffs/Debuffs",
                description = "Track buff and debuff gains/fades",
                type = "toggle",
                default = true
            },
            trackResources = {
                displayName = "Track Resources",
                description = "Track resource gains and expenditures",
                type = "toggle",
                default = true
            },
            trackCasts = {
                displayName = "Track Casts",
                description = "Track spell casts and outcomes",
                type = "toggle",
                default = true
            }
        },
        bossSettings = {
            enableBossModuleIntegration = {
                displayName = "Boss Module Integration",
                description = "Integrate with boss modules for ability timing",
                type = "toggle",
                default = true
            },
            trackBossAbilities = {
                displayName = "Track Boss Abilities",
                description = "Track boss ability usage and patterns",
                type = "toggle",
                default = true
            },
            enablePhaseDetection = {
                displayName = "Phase Detection",
                description = "Automatically detect boss phases",
                type = "toggle",
                default = true
            },
            predictBossAbilities = {
                displayName = "Predict Boss Abilities",
                description = "Predict when boss will use certain abilities",
                type = "toggle",
                default = true
            }
        },
        performanceSettings = {
            enablePerformanceTracking = {
                displayName = "Performance Tracking",
                description = "Track performance metrics during combat",
                type = "toggle",
                default = true
            },
            maxProcessTimePerFrame = {
                displayName = "Max Process Time",
                description = "Maximum time to spend processing combat log per frame (ms)",
                type = "slider",
                min = 1,
                max = 20,
                step = 1,
                default = 5
            },
            adaptiveProcessing = {
                displayName = "Adaptive Processing",
                description = "Dynamically adjust processing based on system load",
                type = "toggle",
                default = true
            },
            pauseInIntenseCombat = {
                displayName = "Pause in Intense Combat",
                description = "Temporarily pause processing during intense combat",
                type = "toggle",
                default = false
            }
        },
        advancedSettings = {
            enableRotationAnalysis = {
                displayName = "Rotation Analysis",
                description = "Analyze rotation efficiency based on combat log",
                type = "toggle",
                default = true
            },
            enableDefensiveTracking = {
                displayName = "Defensive Tracking",
                description = "Track defensive cooldown usage and opportunities",
                type = "toggle",
                default = true
            },
            enableThreatAnalysis = {
                displayName = "Threat Analysis",
                description = "Analyze threat situations in combat",
                type = "toggle",
                default = true
            },
            enablePartyTracking = {
                displayName = "Party Tracking",
                description = "Track party member performance",
                type = "toggle",
                default = true
            }
        }
    })
}

-- Create combat log frame
function CombatAnalysis:CreateCombatLogFrame()
    combatLogFrame = CreateFrame("Frame", "WindrunnerRotationsCombatLogFrame")
    combatLogFrame:Hide()
    
    -- Set up OnUpdate handler
    combatLogFrame:SetScript("OnUpdate", function(self, elapsed)
        CombatAnalysis:ProcessCombatLogQueue(elapsed)
    end)
}

-- Register events
function CombatAnalysis:RegisterEvents()
    -- Register for combat log events
    API.RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", function()
        self:OnCombatLogEvent(CombatLogGetCurrentEventInfo())
    end)
    
    -- Register for player target/focus changes
    API.RegisterEvent("PLAYER_TARGET_CHANGED", function()
        self:OnTargetChanged()
    end)
    
    API.RegisterEvent("PLAYER_FOCUS_CHANGED", function()
        self:OnFocusChanged()
    end)
    
    -- Register for combat state changes
    API.RegisterEvent("PLAYER_REGEN_DISABLED", function()
        self:OnEnterCombat()
    end)
    
    API.RegisterEvent("PLAYER_REGEN_ENABLED", function()
        self:OnLeaveCombat()
    end)
    
    -- Register for encounter events
    API.RegisterEvent("ENCOUNTER_START", function(encounterID, encounterName, difficultyID, groupSize)
        self:OnEncounterStart(encounterID, encounterName, difficultyID, groupSize)
    end)
    
    API.RegisterEvent("ENCOUNTER_END", function(encounterID, encounterName, difficultyID, groupSize, success)
        self:OnEncounterEnd(encounterID, encounterName, difficultyID, groupSize, success)
    end)
    
    -- Register for unit events
    API.RegisterEvent("UNIT_SPELLCAST_START", function(unit, castGUID, spellID)
        if unit == "player" then
            self:OnPlayerCastStart(unit, castGUID, spellID)
        else
            self:OnUnitCastStart(unit, castGUID, spellID)
        end
    end)
    
    API.RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", function(unit, castGUID, spellID)
        if unit == "player" then
            self:OnPlayerCastSucceeded(unit, castGUID, spellID)
        else
            self:OnUnitCastSucceeded(unit, castGUID, spellID)
        end
    end)
    
    API.RegisterEvent("UNIT_SPELLCAST_FAILED", function(unit, castGUID, spellID)
        if unit == "player" then
            self:OnPlayerCastFailed(unit, castGUID, spellID)
        end
    end)
    
    API.RegisterEvent("UNIT_HEALTH", function(unit)
        self:OnUnitHealthChanged(unit)
    end)
    
    -- Register for resource changes
    API.RegisterEvent("UNIT_POWER_UPDATE", function(unit, powerType)
        if unit == "player" then
            self:OnPlayerPowerChanged(powerType)
        end
    end)
    
    -- Register for spec changes
    API.RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", function(unit)
        if unit == "player" then
            self:OnPlayerSpecChanged()
        end
    end)
    
    -- Register for threat situation changes
    API.RegisterEvent("UNIT_THREAT_SITUATION_UPDATE", function(unit)
        self:OnThreatSituationUpdate(unit)
    end)
}

-- Update player info
function CombatAnalysis:UpdatePlayerInfo()
    -- Get player GUID
    playerGUID = UnitGUID("player")
    
    -- Get player class
    local _, class = UnitClass("player")
    playerClass = class
    
    -- Get player level
    playerLevel = UnitLevel("player")
    
    -- Get player spec
    playerSpec = API.GetActiveSpecID()
    
    -- Determine player role
    if WR.GroupRoleManager then
        playerRole = WR.GroupRoleManager:GetPlayerRole()
    else
        -- Fallback role detection based on spec
        if playerClass == "WARRIOR" and playerSpec == 3 or
           playerClass == "PALADIN" and playerSpec == 2 or
           playerClass == "DRUID" and playerSpec == 3 or
           playerClass == "MONK" and playerSpec == 1 or
           playerClass == "DEATHKNIGHT" and playerSpec == 1 or
           playerClass == "DEMONHUNTER" and playerSpec == 2 then
            playerRole = "TANK"
        elseif playerClass == "PRIEST" and (playerSpec == 1 or playerSpec == 2) or
               playerClass == "PALADIN" and playerSpec == 1 or
               playerClass == "DRUID" and playerSpec == 4 or
               playerClass == "MONK" and playerSpec == 2 or
               playerClass == "SHAMAN" and playerSpec == 3 or
               playerClass == "EVOKER" and playerSpec == 2 then
            playerRole = "HEALER"
        else
            playerRole = "DAMAGER"
        end
    end
    
    API.PrintDebug("Player info updated: GUID=" .. playerGUID .. ", Class=" .. playerClass .. ", Spec=" .. (playerSpec or "unknown") .. ", Role=" .. playerRole)
}

-- Initialize event handlers
function CombatAnalysis:InitializeEventHandlers()
    -- Initialize event handlers for each combat log event type
    eventHandlers = {
        -- Damage events
        ["SPELL_DAMAGE"] = function(...)
            self:ProcessDamageEvent(EVENT_TYPES.DAMAGE, ...)
        end,
        ["SPELL_PERIODIC_DAMAGE"] = function(...)
            self:ProcessDamageEvent(EVENT_TYPES.DAMAGE, ...)
        end,
        ["RANGE_DAMAGE"] = function(...)
            self:ProcessDamageEvent(EVENT_TYPES.DAMAGE, ...)
        end,
        ["SWING_DAMAGE"] = function(...)
            self:ProcessSwingDamageEvent(EVENT_TYPES.DAMAGE, ...)
        end,
        
        -- Healing events
        ["SPELL_HEAL"] = function(...)
            self:ProcessHealingEvent(EVENT_TYPES.HEALING, ...)
        end,
        ["SPELL_PERIODIC_HEAL"] = function(...)
            self:ProcessHealingEvent(EVENT_TYPES.HEALING, ...)
        end,
        
        -- Cast events
        ["SPELL_CAST_START"] = function(...)
            self:ProcessCastEvent(EVENT_TYPES.CAST, "start", ...)
        end,
        ["SPELL_CAST_SUCCESS"] = function(...)
            self:ProcessCastEvent(EVENT_TYPES.CAST, "success", ...)
        end,
        ["SPELL_CAST_FAILED"] = function(...)
            self:ProcessCastEvent(EVENT_TYPES.CAST, "failed", ...)
        end,
        
        -- Interrupt events
        ["SPELL_INTERRUPT"] = function(...)
            self:ProcessInterruptEvent(EVENT_TYPES.INTERRUPT, ...)
        end,
        
        -- Buff events
        ["SPELL_AURA_APPLIED"] = function(...)
            self:ProcessAuraEvent(EVENT_TYPES.BUFF, "applied", ...)
        end,
        ["SPELL_AURA_REMOVED"] = function(...)
            self:ProcessAuraEvent(EVENT_TYPES.BUFF, "removed", ...)
        end,
        ["SPELL_AURA_APPLIED_DOSE"] = function(...)
            self:ProcessAuraEvent(EVENT_TYPES.BUFF, "applied_dose", ...)
        end,
        ["SPELL_AURA_REMOVED_DOSE"] = function(...)
            self:ProcessAuraEvent(EVENT_TYPES.BUFF, "removed_dose", ...)
        end,
        ["SPELL_AURA_REFRESH"] = function(...)
            self:ProcessAuraEvent(EVENT_TYPES.BUFF, "refresh", ...)
        end,
        ["SPELL_AURA_BROKEN"] = function(...)
            self:ProcessAuraEvent(EVENT_TYPES.BUFF, "broken", ...)
        end,
        ["SPELL_AURA_BROKEN_SPELL"] = function(...)
            self:ProcessAuraEvent(EVENT_TYPES.BUFF, "broken_spell", ...)
        end,
        
        -- Resource events
        ["SPELL_ENERGIZE"] = function(...)
            self:ProcessResourceEvent(EVENT_TYPES.RESOURCE, "gain", ...)
        end,
        ["SPELL_PERIODIC_ENERGIZE"] = function(...)
            self:ProcessResourceEvent(EVENT_TYPES.RESOURCE, "gain", ...)
        end,
        ["SPELL_DRAIN"] = function(...)
            self:ProcessResourceEvent(EVENT_TYPES.RESOURCE, "drain", ...)
        end,
        ["SPELL_LEECH"] = function(...)
            self:ProcessResourceEvent(EVENT_TYPES.RESOURCE, "leech", ...)
        end,
        
        -- Miss events
        ["SPELL_MISSED"] = function(...)
            self:ProcessMissEvent(EVENT_TYPES.DAMAGE, ...)
        end,
        ["SPELL_PERIODIC_MISSED"] = function(...)
            self:ProcessMissEvent(EVENT_TYPES.DAMAGE, ...)
        end,
        ["RANGE_MISSED"] = function(...)
            self:ProcessMissEvent(EVENT_TYPES.DAMAGE, ...)
        end,
        ["SWING_MISSED"] = function(...)
            self:ProcessSwingMissEvent(EVENT_TYPES.DAMAGE, ...)
        end,
        
        -- Death events
        ["UNIT_DIED"] = function(...)
            self:ProcessDeathEvent(EVENT_TYPES.DEATH, ...)
        end,
        ["UNIT_DESTROYED"] = function(...)
            self:ProcessDeathEvent(EVENT_TYPES.DEATH, ...)
        end,
        
        -- Dispel events
        ["SPELL_DISPEL"] = function(...)
            self:ProcessDispelEvent(EVENT_TYPES.DISPEL, ...)
        end,
        ["SPELL_STOLEN"] = function(...)
            self:ProcessDispelEvent(EVENT_TYPES.DISPEL, ...)
        end,
        
        -- Environmental events
        ["ENVIRONMENTAL_DAMAGE"] = function(...)
            self:ProcessEnvironmentalEvent(EVENT_TYPES.ENVIRONMENTAL, ...)
        end
    }
}

-- Initialize pattern recognition
function CombatAnalysis:InitializePatternRecognition()
    -- Initialize pattern recognition for boss abilities and rotation analysis
    patternRecognition = {
        bossAbilityPatterns = {},
        playerRotationPatterns = {},
        resourceUsagePatterns = {},
        defensePatterns = {},
        interruptPatterns = {}
    }
}

-- On combat log event
function CombatAnalysis:OnCombatLogEvent(...)
    -- Skip if disabled
    if not isEnabled or not combatLogEnabled then
        return
    end
    
    -- Extract event info
    local timestamp, event, _, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, 
          destGUID, destName, destFlags, destRaidFlags, spellID, spellName, _, extraArg1 = ...
    
    -- Add to processing queue
    table.insert(processingQueue, {...})
    
    -- Trim queue if needed
    while #processingQueue > MAX_QUEUE_SIZE do
        table.remove(processingQueue, 1)
    end
    
    -- Make sure processing frame is shown
    combatLogFrame:Show()
}

-- Process combat log queue
function CombatAnalysis:ProcessCombatLogQueue(elapsed)
    -- Skip if disabled or paused
    if not isEnabled or isProcessingPaused then
        return
    end
    
    -- Check if it's time to process
    local now = GetTime()
    if now - lastProcessedEventTime < processFrequency then
        return
    end
    
    -- Update time
    lastProcessedEventTime = now
    
    -- Performance tracking
    local startTime = debugprofilestop()
    local eventsProcessed = 0
    local maxTime = MAX_PROCESS_TIME_PER_FRAME
    
    -- Process events until queue is empty or we hit time limit
    while #processingQueue > 0 and (debugprofilestop() - startTime) < maxTime do
        -- Get next event
        local eventData = table.remove(processingQueue, 1)
        
        -- Process it
        self:ProcessCombatLogEvent(unpack(eventData))
        
        -- Increment counter
        eventsProcessed = eventsProcessed + 1
    end
    
    -- Update performance metrics
    combatLogProcessingTime = debugprofilestop() - startTime
    combatLogEventsProcessed = eventsProcessed
    
    -- Debug output for performance
    if eventsProcessed > 0 and performanceTracking.enabled then
        local timePerEvent = combatLogProcessingTime / eventsProcessed
        API.PrintDebug(string.format("Processed %d combat log events in %.2f ms (%.3f ms/event)", 
                      eventsProcessed, combatLogProcessingTime, timePerEvent))
    end
    
    -- Hide frame if queue is empty
    if #processingQueue == 0 then
        combatLogFrame:Hide()
    end
}

-- Process combat log event
function CombatAnalysis:ProcessCombatLogEvent(timestamp, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, 
                                             destGUID, destName, destFlags, destRaidFlags, ...)
    -- Skip filtered events
    if eventFilters[event] then
        return
    end
    
    -- Find appropriate handler for this event
    local handler = eventHandlers[event]
    if handler then
        -- Call handler with event parameters
        handler(timestamp, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, 
                destGUID, destName, destFlags, destRaidFlags, ...)
    end
    
    -- Add to combat events history
    if inCombat then
        table.insert(combatEvents, {
            timestamp = timestamp,
            event = event,
            sourceGUID = sourceGUID,
            sourceName = sourceName,
            destGUID = destGUID,
            destName = destName,
            data = {...}
        })
        
        -- Trim if needed
        while #combatEvents > MAX_EVENT_HISTORY do
            table.remove(combatEvents, 1)
        end
    end
    
    -- Update boss ability timers and patterns for boss units
    if IsGUIDTypeNPC(sourceGUID) and self:IsBossGUID(sourceGUID) and event:match("^SPELL_") then
        self:UpdateBossAbilityPattern(sourceGUID, sourceName, ...)
    end
    
    -- Update player statistics for player actions
    if sourceGUID == playerGUID and event:match("^SPELL_") then
        self:UpdatePlayerStatistics(event, ...)
    end
    
    -- Update environment effects
    if event == "ENVIRONMENTAL_DAMAGE" and destGUID == playerGUID then
        self:UpdateEnvironmentalEffects(...)
    end
}

-- Process damage event
function CombatAnalysis:ProcessDamageEvent(eventType, timestamp, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, 
                                         destGUID, destName, destFlags, destRaidFlags, spellID, spellName, spellSchool, amount, overkill, 
                                         school, resisted, blocked, absorbed, critical, glancing, crushing, isOffHand)
    -- Process damage done by player
    if sourceGUID == playerGUID then
        -- Record damage done
        if not damageDone[spellID] then
            damageDone[spellID] = {
                name = spellName,
                total = 0,
                hits = 0,
                crits = 0,
                misses = 0,
                lastHit = 0,
                highestHit = 0,
                school = spellSchool
            }
        end
        
        -- Update damage stats
        damageDone[spellID].total = damageDone[spellID].total + (amount or 0)
        damageDone[spellID].hits = damageDone[spellID].hits + 1
        damageDone[spellID].lastHit = amount or 0
        
        if critical then
            damageDone[spellID].crits = damageDone[spellID].crits + 1
        end
        
        if (amount or 0) > damageDone[spellID].highestHit then
            damageDone[spellID].highestHit = amount or 0
        end
        
        -- Record spell hit
        table.insert(spellHits, {
            timestamp = timestamp,
            spellID = spellID,
            targetGUID = destGUID,
            amount = amount or 0,
            critical = critical or false
        })
        
        -- Trim if needed
        while #spellHits > MAX_EVENT_HISTORY do
            table.remove(spellHits, 1)
        end
    end
    
    -- Process damage taken by player
    if destGUID == playerGUID then
        -- Record damage taken
        if not damageTaken[spellID] then
            damageTaken[spellID] = {
                name = spellName,
                total = 0,
                hits = 0,
                crits = 0,
                lastHit = 0,
                highestHit = 0,
                school = spellSchool,
                sourceGUID = sourceGUID,
                sourceName = sourceName
            }
        end
        
        -- Update damage taken stats
        damageTaken[spellID].total = damageTaken[spellID].total + (amount or 0)
        damageTaken[spellID].hits = damageTaken[spellID].hits + 1
        damageTaken[spellID].lastHit = amount or 0
        
        if critical then
            damageTaken[spellID].crits = damageTaken[spellID].crits + 1
        end
        
        if (amount or 0) > damageTaken[spellID].highestHit then
            damageTaken[spellID].highestHit = amount or 0
        end
        
        -- Check for missed defensive opportunities
        if self:ShouldUseDefensive(amount, spellID, critical) then
            self:RecordMissedDefensive(spellID, amount, timestamp)
        end
    end
    
    -- Process boss damage
    if self:IsBossGUID(sourceGUID) then
        -- Record boss damage pattern
        self:RecordBossAbilityUse(sourceGUID, sourceName, spellID, spellName, timestamp, "damage", destGUID)
    end
}

-- Process swing damage event
function CombatAnalysis:ProcessSwingDamageEvent(eventType, timestamp, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, 
                                             destGUID, destName, destFlags, destRaidFlags, amount, overkill, school, resisted, blocked, 
                                             absorbed, critical, glancing, crushing, isOffHand)
    -- Process as a special case of damage with no spellID
    self:ProcessDamageEvent(eventType, timestamp, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, 
                           destGUID, destName, destFlags, destRaidFlags, 0, "Melee", 1, amount, overkill, 
                           school, resisted, blocked, absorbed, critical, glancing, crushing, isOffHand)
}

-- Process healing event
function CombatAnalysis:ProcessHealingEvent(eventType, timestamp, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, 
                                          destGUID, destName, destFlags, destRaidFlags, spellID, spellName, spellSchool, amount, 
                                          overhealing, absorbed, critical)
    -- Process healing done by player
    if sourceGUID == playerGUID then
        -- Record healing done
        if not healingDone[spellID] then
            healingDone[spellID] = {
                name = spellName,
                total = 0,
                effective = 0,
                overheal = 0,
                hits = 0,
                crits = 0,
                lastHit = 0,
                highestHit = 0
            }
        end
        
        -- Update healing stats
        local effectiveHealing = (amount or 0) - (overhealing or 0)
        healingDone[spellID].total = healingDone[spellID].total + (amount or 0)
        healingDone[spellID].effective = healingDone[spellID].effective + effectiveHealing
        healingDone[spellID].overheal = healingDone[spellID].overheal + (overhealing or 0)
        healingDone[spellID].hits = healingDone[spellID].hits + 1
        healingDone[spellID].lastHit = effectiveHealing
        
        if critical then
            healingDone[spellID].crits = healingDone[spellID].crits + 1
        end
        
        if effectiveHealing > healingDone[spellID].highestHit then
            healingDone[spellID].highestHit = effectiveHealing
        end
    end
    
    -- Process healing taken by player
    if destGUID == playerGUID then
        -- Record healing taken
        if not healingTaken[spellID] then
            healingTaken[spellID] = {
                name = spellName,
                total = 0,
                effective = 0,
                overheal = 0,
                hits = 0,
                crits = 0,
                lastHit = 0,
                highestHit = 0,
                sourceGUID = sourceGUID,
                sourceName = sourceName
            }
        end
        
        -- Update healing taken stats
        local effectiveHealing = (amount or 0) - (overhealing or 0)
        healingTaken[spellID].total = healingTaken[spellID].total + (amount or 0)
        healingTaken[spellID].effective = healingTaken[spellID].effective + effectiveHealing
        healingTaken[spellID].overheal = healingTaken[spellID].overheal + (overhealing or 0)
        healingTaken[spellID].hits = healingTaken[spellID].hits + 1
        healingTaken[spellID].lastHit = effectiveHealing
        
        if critical then
            healingTaken[spellID].crits = healingTaken[spellID].crits + 1
        end
        
        if effectiveHealing > healingTaken[spellID].highestHit then
            healingTaken[spellID].highestHit = effectiveHealing
        end
    end
}

-- Process cast event
function CombatAnalysis:ProcessCastEvent(eventType, castType, timestamp, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, 
                                       destGUID, destName, destFlags, destRaidFlags, spellID, spellName, spellSchool, ...)
    -- Process player casts
    if sourceGUID == playerGUID then
        -- Record cast
        table.insert(spellCasts, {
            timestamp = timestamp,
            spellID = spellID,
            name = spellName,
            targetGUID = destGUID,
            targetName = destName,
            type = castType
        })
        
        -- Trim if needed
        while #spellCasts > MAX_EVENT_HISTORY do
            table.remove(spellCasts, 1)
        end
        
        -- Update player statistics
        if castType == "success" then
            self:UpdateRotationSequence(spellID, timestamp)
        end
    end
    
    -- Process enemy casts
    if IsGUIDTypeNPC(sourceGUID) or (IsGUIDTypePlayer(sourceGUID) and not self:IsPlayerFriendly(sourceFlags)) then
        -- Record enemy cast
        table.insert(enemyCasts, {
            timestamp = timestamp,
            sourceGUID = sourceGUID,
            sourceName = sourceName,
            spellID = spellID,
            name = spellName,
            type = castType,
            targetGUID = destGUID,
            targetName = destName
        })
        
        -- Trim if needed
        while #enemyCasts > MAX_EVENT_HISTORY do
            table.remove(enemyCasts, 1)
        end
        
        -- Check for interruptible cast that we might have missed
        if castType == "start" and self:IsSpellInterruptible(spellID) then
            self:TrackPotentialInterrupt(sourceGUID, sourceName, spellID, spellName, timestamp)
        end
        
        -- If this is a boss, record ability use
        if self:IsBossGUID(sourceGUID) then
            self:RecordBossAbilityUse(sourceGUID, sourceName, spellID, spellName, timestamp, castType, destGUID)
        end
    end
}

-- Process interrupt event
function CombatAnalysis:ProcessInterruptEvent(eventType, timestamp, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, 
                                            destGUID, destName, destFlags, destRaidFlags, spellID, spellName, spellSchool, 
                                            extraSpellID, extraSpellName, extraSpellSchool)
    -- Process player interrupts
    if sourceGUID == playerGUID then
        -- Record successful interrupt
        if not interruptsDone[extraSpellID] then
            interruptsDone[extraSpellID] = {
                name = extraSpellName,
                count = 0,
                lastTime = 0,
                interruptSpellID = spellID,
                interruptSpellName = spellName
            }
        end
        
        -- Update stats
        interruptsDone[extraSpellID].count = interruptsDone[extraSpellID].count + 1
        interruptsDone[extraSpellID].lastTime = timestamp
        
        -- Remove from potential interrupts
        self:RemovePotentialInterrupt(destGUID, extraSpellID)
    end
    
    -- Process interrupts on player
    if destGUID == playerGUID then
        -- Record being interrupted
        table.insert(spellMisses, {
            timestamp = timestamp,
            spellID = extraSpellID,
            name = extraSpellName,
            missType = "interrupted",
            sourceGUID = sourceGUID,
            sourceName = sourceName,
            sourceSpellID = spellID,
            sourceSpellName = spellName
        })
        
        -- Trim if needed
        while #spellMisses > MAX_EVENT_HISTORY do
            table.remove(spellMisses, 1)
        end
    end
}

-- Process aura event
function CombatAnalysis:ProcessAuraEvent(eventType, auraType, timestamp, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, 
                                       destGUID, destName, destFlags, destRaidFlags, spellID, spellName, spellSchool, auraType2, amount)
    -- Determine if this is a buff or debuff
    local isDebuff = auraType2 == "DEBUFF"
    
    -- Process player buffs/debuffs
    if destGUID == playerGUID then
        if isDebuff then
            -- Process debuff on player
            if auraType == "applied" or auraType == "refresh" then
                -- Record debuff gain
                if not debuffGains[spellID] then
                    debuffGains[spellID] = {
                        name = spellName,
                        count = 0,
                        lastTime = 0,
                        sourceGUID = sourceGUID,
                        sourceName = sourceName
                    }
                end
                
                -- Update stats
                debuffGains[spellID].count = debuffGains[spellID].count + 1
                debuffGains[spellID].lastTime = timestamp
                
                -- Check if this is a CC that might require defensive
                if self:IsControlDebuff(spellID) then
                    self:RecordCCEvent(sourceGUID, sourceName, destGUID, destName, spellID, spellName, timestamp, "applied")
                end
            elseif auraType == "removed" then
                -- Record debuff fade
                if not debuffFades[spellID] then
                    debuffFades[spellID] = {
                        name = spellName,
                        count = 0,
                        lastTime = 0
                    }
                end
                
                -- Update stats
                debuffFades[spellID].count = debuffFades[spellID].count + 1
                debuffFades[spellID].lastTime = timestamp
                
                -- If this was a CC, record removal
                if self:IsControlDebuff(spellID) then
                    self:RecordCCEvent(sourceGUID, sourceName, destGUID, destName, spellID, spellName, timestamp, "removed")
                end
            end
        else
            -- Process buff on player
            if auraType == "applied" or auraType == "refresh" then
                -- Record buff gain
                if not buffGains[spellID] then
                    buffGains[spellID] = {
                        name = spellName,
                        count = 0,
                        lastTime = 0,
                        sourceGUID = sourceGUID,
                        sourceName = sourceName
                    }
                end
                
                -- Update stats
                buffGains[spellID].count = buffGains[spellID].count + 1
                buffGains[spellID].lastTime = timestamp
                
                -- Check if this is a defensive buff for tracking
                if self:IsDefensiveBuff(spellID) then
                    self:RecordDefensiveUse(spellID, spellName, timestamp)
                end
            elseif auraType == "removed" then
                -- Record buff fade
                if not buffFades[spellID] then
                    buffFades[spellID] = {
                        name = spellName,
                        count = 0,
                        lastTime = 0
                    }
                end
                
                -- Update stats
                buffFades[spellID].count = buffFades[spellID].count + 1
                buffFades[spellID].lastTime = timestamp
            end
        end
    else
        -- Process player's buffs/debuffs on others
        if sourceGUID == playerGUID then
            if isDebuff then
                -- Player applied debuff to target
                if auraType == "applied" or auraType == "refresh" then
                    -- Check if this is a CC
                    if self:IsControlDebuff(spellID) then
                        self:RecordCCEvent(sourceGUID, sourceName, destGUID, destName, spellID, spellName, timestamp, "applied")
                    end
                elseif auraType == "broken" or auraType == "broken_spell" then
                    -- CC was broken early
                    if self:IsControlDebuff(spellID) then
                        self:RecordCCEvent(sourceGUID, sourceName, destGUID, destName, spellID, spellName, timestamp, "broken")
                    end
                end
            end
        end
        
        -- Track boss buffs for phase detection
        if self:IsBossGUID(destGUID) and isDebuff == false and (auraType == "applied" or auraType == "removed") then
            self:CheckBossPhaseChange(destGUID, destName, spellID, spellName, auraType, timestamp)
        end
    end
}

-- Process resource event
function CombatAnalysis:ProcessResourceEvent(eventType, resourceType, timestamp, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, 
                                           destGUID, destName, destFlags, destRaidFlags, spellID, spellName, spellSchool, amount, resourceType2)
    -- Process player resource gains
    if destGUID == playerGUID and resourceType == "gain" then
        -- Record resource gain
        if not resourceGain[spellID] then
            resourceGain[spellID] = {
                name = spellName,
                total = 0,
                count = 0,
                lastTime = 0,
                lastAmount = 0,
                resourceType = resourceType2
            }
        end
        
        -- Update stats
        resourceGain[spellID].total = resourceGain[spellID].total + (amount or 0)
        resourceGain[spellID].count = resourceGain[spellID].count + 1
        resourceGain[spellID].lastTime = timestamp
        resourceGain[spellID].lastAmount = amount or 0
    end
    
    -- Process player resource drains
    if sourceGUID == playerGUID and (resourceType == "drain" or resourceType == "leech") then
        -- Record resource spend (for draining abilities)
        if not resourceSpent[spellID] then
            resourceSpent[spellID] = {
                name = spellName,
                total = 0,
                count = 0,
                lastTime = 0,
                lastAmount = 0,
                resourceType = resourceType2
            }
        end
        
        -- Update stats
        resourceSpent[spellID].total = resourceSpent[spellID].total + (amount or 0)
        resourceSpent[spellID].count = resourceSpent[spellID].count + 1
        resourceSpent[spellID].lastTime = timestamp
        resourceSpent[spellID].lastAmount = amount or 0
    end
}

-- Process miss event
function CombatAnalysis:ProcessMissEvent(eventType, timestamp, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, 
                                       destGUID, destName, destFlags, destRaidFlags, spellID, spellName, spellSchool, missType, isOffHand, amountMissed)
    -- Process player misses
    if sourceGUID == playerGUID then
        -- Record miss
        table.insert(spellMisses, {
            timestamp = timestamp,
            spellID = spellID,
            name = spellName,
            missType = missType,
            targetGUID = destGUID,
            targetName = destName,
            amountMissed = amountMissed
        })
        
        -- Trim if needed
        while #spellMisses > MAX_EVENT_HISTORY do
            table.remove(spellMisses, 1)
        end
        
        -- Update overall spell stats
        if not damageDone[spellID] then
            damageDone[spellID] = {
                name = spellName,
                total = 0,
                hits = 0,
                crits = 0,
                misses = 0,
                lastHit = 0,
                highestHit = 0,
                school = spellSchool
            }
        end
        
        damageDone[spellID].misses = damageDone[spellID].misses + 1
        
        -- Track specific miss types
        if missType == "REFLECT" then
            table.insert(spellReflects, {
                timestamp = timestamp,
                spellID = spellID,
                name = spellName,
                targetGUID = destGUID,
                targetName = destName
            })
        elseif missType == "DODGE" then
            table.insert(spellDodges, {
                timestamp = timestamp,
                spellID = spellID,
                name = spellName,
                targetGUID = destGUID,
                targetName = destName
            })
        elseif missType == "PARRY" then
            table.insert(spellParries, {
                timestamp = timestamp,
                spellID = spellID,
                name = spellName,
                targetGUID = destGUID,
                targetName = destName
            })
        elseif missType == "IMMUNE" then
            table.insert(spellImmunes, {
                timestamp = timestamp,
                spellID = spellID,
                name = spellName,
                targetGUID = destGUID,
                targetName = destName
            })
        elseif missType == "RESIST" then
            table.insert(spellResists, {
                timestamp = timestamp,
                spellID = spellID,
                name = spellName,
                targetGUID = destGUID,
                targetName = destName
            })
        elseif missType == "EVADE" then
            table.insert(spellEvades, {
                timestamp = timestamp,
                spellID = spellID,
                name = spellName,
                targetGUID = destGUID,
                targetName = destName
            })
        end
    end
    
    -- Track missed interrupts
    if missType == "IMMUNE" and self:IsInterruptSpell(spellID) and sourceGUID == playerGUID then
        self:RecordMissedInterrupt(destGUID, destName, spellID, spellName, timestamp, "immune")
    end
}

-- Process swing miss event
function CombatAnalysis:ProcessSwingMissEvent(eventType, timestamp, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, 
                                           destGUID, destName, destFlags, destRaidFlags, missType, isOffHand, amountMissed)
    -- Process as a special case of miss with no spellID
    self:ProcessMissEvent(eventType, timestamp, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, 
                         destGUID, destName, destFlags, destRaidFlags, 0, "Melee", 1, missType, isOffHand, amountMissed)
}

-- Process death event
function CombatAnalysis:ProcessDeathEvent(eventType, timestamp, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, 
                                        destGUID, destName, destFlags, destRaidFlags)
    -- Record death
    table.insert(deathEvents, {
        timestamp = timestamp,
        unitGUID = destGUID,
        unitName = destName,
        isPlayer = IsGUIDTypePlayer(destGUID),
        isNPC = IsGUIDTypeNPC(destGUID),
        isBoss = self:IsBossGUID(destGUID)
    })
    
    -- Trim if needed
    while #deathEvents > MAX_EVENT_HISTORY do
        table.remove(deathEvents, 1)
    end
    
    -- If a boss died, record end of phase
    if self:IsBossGUID(destGUID) then
        self:RecordBossPhaseEnd(destGUID, destName, timestamp, "death")
    end
    
    -- If player died, record for defensive analysis
    if destGUID == playerGUID then
        self:AnalyzePlayerDeath(timestamp)
    end
}

-- Process dispel event
function CombatAnalysis:ProcessDispelEvent(eventType, timestamp, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, 
                                         destGUID, destName, destFlags, destRaidFlags, spellID, spellName, spellSchool, 
                                         extraSpellID, extraSpellName, extraSpellSchool, auraType)
    -- We don't need specific processing for dispels in this implementation
}

-- Process environmental event
function CombatAnalysis:ProcessEnvironmentalEvent(eventType, timestamp, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, 
                                               destGUID, destName, destFlags, destRaidFlags, environmentalType, amount, overkill, 
                                               school, resisted, blocked, absorbed, critical, glancing, crushing)
    -- Record environmental damage to player
    if destGUID == playerGUID then
        if not environmentalDamage[environmentalType] then
            environmentalDamage[environmentalType] = {
                total = 0,
                count = 0,
                lastTime = 0,
                lastAmount = 0,
                highestAmount = 0
            }
        end
        
        -- Update stats
        environmentalDamage[environmentalType].total = environmentalDamage[environmentalType].total + (amount or 0)
        environmentalDamage[environmentalType].count = environmentalDamage[environmentalType].count + 1
        environmentalDamage[environmentalType].lastTime = timestamp
        environmentalDamage[environmentalType].lastAmount = amount or 0
        
        if (amount or 0) > environmentalDamage[environmentalType].highestAmount then
            environmentalDamage[environmentalType].highestAmount = amount or 0
        end
        
        -- Check for missed defensive opportunities
        if self:ShouldUseDefensive(amount, 0, critical) then
            self:RecordMissedDefensive(0, amount, timestamp, environmentalType)
        end
    end
}

-- On target changed
function CombatAnalysis:OnTargetChanged()
    -- Update current target GUID
    if UnitExists("target") then
        currentTargetGUID = UnitGUID("target")
        
        -- If this is a boss unit, start tracking
        if UnitClassification("target") == "worldboss" or UnitClassification("target") == "rareelite" then
            self:StartTrackingBoss(currentTargetGUID, UnitName("target"))
        end
    else
        currentTargetGUID = nil
    end
}

-- On focus changed
function CombatAnalysis:OnFocusChanged()
    -- Update current focus GUID
    if UnitExists("focus") then
        currentFocusGUID = UnitGUID("focus")
    else
        currentFocusGUID = nil
    end
}

-- On enter combat
function CombatAnalysis:OnEnterCombat()
    -- Set combat state
    inCombat = true
    combatStartTime = GetTime()
    
    -- Reset combat data
    combatEvents = {}
    spellCasts = {}
    spellHits = {}
    spellMisses = {}
    
    -- Start performance tracking
    self:StartPerformanceTracking()
    
    API.PrintDebug("Entered combat, started analysis")
}

-- On leave combat
function CombatAnalysis:OnLeaveCombat()
    -- Set combat state
    inCombat = false
    combatDuration = GetTime() - combatStartTime
    
    -- Store recent combat summary
    self:GenerateCombatSummary()
    
    -- Stop performance tracking
    self:StopPerformanceTracking()
    
    -- Clear processing queue for efficiency
    processingQueue = {}
    
    -- Analyze recent combat for rotation efficiency
    self:AnalyzeRotationEfficiency()
    
    API.PrintDebug("Left combat, analysis completed. Combat duration: " .. string.format("%.1f", combatDuration) .. "s")
}

-- On player cast start
function CombatAnalysis:OnPlayerCastStart(unit, castGUID, spellID)
    -- We track this through combat log as well, but this provides additional timing accuracy
}

-- On unit cast start
function CombatAnalysis:OnUnitCastStart(unit, castGUID, spellID)
    -- Track enemy casts for interrupt opportunities
    if unit ~= "player" and UnitCanAttack("player", unit) then
        local spellName = select(1, UnitCastingInfo(unit))
        if spellName and self:IsSpellInterruptible(spellID) then
            self:TrackPotentialInterrupt(UnitGUID(unit), UnitName(unit), spellID, spellName, GetTime())
        end
    end
}

-- On player cast succeeded
function CombatAnalysis:OnPlayerCastSucceeded(unit, castGUID, spellID)
    -- Track resource spent on ability
    local resourceType, resourceCost = self:GetSpellResourceCost(spellID)
    
    if resourceType and resourceCost > 0 then
        -- Record resource spend
        if not resourceSpent[spellID] then
            resourceSpent[spellID] = {
                name = GetSpellInfo(spellID),
                total = 0,
                count = 0,
                lastTime = 0,
                lastAmount = 0,
                resourceType = resourceType
            }
        end
        
        -- Update stats
        resourceSpent[spellID].total = resourceSpent[spellID].total + resourceCost
        resourceSpent[spellID].count = resourceSpent[spellID].count + 1
        resourceSpent[spellID].lastTime = GetTime()
        resourceSpent[spellID].lastAmount = resourceCost
    end
}

-- On player cast failed
function CombatAnalysis:OnPlayerCastFailed(unit, castGUID, spellID)
    -- We track this through combat log as well
}

-- On unit health changed
function CombatAnalysis:OnUnitHealthChanged(unit)
    -- Track tank health for defensive opportunities
    if unit ~= "player" and UnitGroupRolesAssigned(unit) == "TANK" then
        local healthPct = UnitHealth(unit) / UnitHealthMax(unit) * 100
        
        -- Record tank health
        tankTracking[UnitGUID(unit)] = {
            name = UnitName(unit),
            healthPct = healthPct,
            lastUpdate = GetTime()
        }
    end
    
    -- Track healer health/mana for assistance opportunities
    if unit ~= "player" and UnitGroupRolesAssigned(unit) == "HEALER" then
        local healthPct = UnitHealth(unit) / UnitHealthMax(unit) * 100
        local manaPct = UnitPower(unit, Enum.PowerType.Mana) / UnitPowerMax(unit, Enum.PowerType.Mana) * 100
        
        -- Record healer stats
        healerTracking[UnitGUID(unit)] = {
            name = UnitName(unit),
            healthPct = healthPct,
            manaPct = manaPct,
            lastUpdate = GetTime()
        }
    end
}

-- On player power changed
function CombatAnalysis:OnPlayerPowerChanged(powerType)
    -- Track player resource changes
}

-- On player spec changed
function CombatAnalysis:OnPlayerSpecChanged()
    -- Update player info
    self:UpdatePlayerInfo()
    
    -- Clear combat data as it's no longer relevant
    self:ClearCombatData()
}

-- On threat situation update
function CombatAnalysis:OnThreatSituationUpdate(unit)
    -- Track threat status for tanks
    if playerRole == "TANK" and (unit == "player" or unit == "target") then
        local status = UnitThreatSituation("player", "target")
        
        if status then
            threatSituation.status = status
            threatSituation.lastUpdate = GetTime()
        end
    end
}

-- On encounter start
function CombatAnalysis:OnEncounterStart(encounterID, encounterName, difficultyID, groupSize)
    -- Record encounter info
    currentBossEncounter = {
        id = encounterID,
        name = encounterName,
        difficulty = difficultyID,
        groupSize = groupSize,
        startTime = GetTime(),
        phases = {}
    }
    
    -- Set initial phase
    currentBossPhase = 1
    bossPhaseStartTimes[1] = GetTime()
    
    -- Record in metadata
    combatMetadata.instanceID = select(8, GetInstanceInfo())
    combatMetadata.encounterID = encounterID
    combatMetadata.difficultyID = difficultyID
    combatMetadata.groupSize = groupSize
    combatMetadata.startTime = GetTime()
    
    -- Clear previous boss ability history
    bossAbilityHistory = {}
    lastBossAbility = {}
    
    -- Determine combat difficulty
    if difficultyID == 8 then -- Mythic+ 5-man
        combatDifficulty = "mythicplus"
    elseif difficultyID == 16 then -- Mythic raid
        combatDifficulty = "mythic"
    elseif difficultyID == 15 then -- Heroic raid
        combatDifficulty = "heroic"
    elseif difficultyID == 14 then -- Normal raid
        combatDifficulty = "normal"
    elseif difficultyID == 17 then -- LFR
        combatDifficulty = "lfr"
    else
        combatDifficulty = "normal"
    end
    
    API.PrintDebug("Encounter started: " .. encounterName .. " (ID: " .. encounterID .. ", Difficulty: " .. difficultyID .. ")")
}

-- On encounter end
function CombatAnalysis:OnEncounterEnd(encounterID, encounterName, difficultyID, groupSize, success)
    -- Only process if we have a current encounter and it matches
    if currentBossEncounter and currentBossEncounter.id == encounterID then
        -- Record end time
        currentBossEncounter.endTime = GetTime()
        currentBossEncounter.duration = currentBossEncounter.endTime - currentBossEncounter.startTime
        currentBossEncounter.success = success == 1
        
        -- Record in metadata
        combatMetadata.endTime = GetTime()
        combatMetadata.success = success == 1
        
        if not success then
            combatMetadata.wipes = (combatMetadata.wipes or 0) + 1
        end
        
        -- End current phase
        self:RecordBossPhaseEnd(nil, encounterName, GetTime(), "encounter_end")
        
        -- Generate encounter summary
        self:GenerateEncounterSummary(currentBossEncounter)
        
        -- Reset current encounter
        currentBossEncounter = nil
        currentBossPhase = nil
        bossPhaseStartTimes = {}
    end
    
    API.PrintDebug("Encounter ended: " .. encounterName .. " (Success: " .. (success == 1 and "Yes" or "No") .. ")")
}

-- Track potential interrupt
function CombatAnalysis:TrackPotentialInterrupt(sourceGUID, sourceName, spellID, spellName, timestamp)
    -- Skip if interrupt tracking is disabled
    local settings = ConfigRegistry:GetSettings("CombatAnalysis")
    if not settings.eventTracking.trackInterrupts then
        return
    end
    
    -- Add to missed interrupts
    table.insert(missedInterrupts, {
        sourceGUID = sourceGUID,
        sourceName = sourceName,
        spellID = spellID,
        spellName = spellName,
        timestamp = timestamp,
        processed = false
    })
    
    -- Trim if needed
    while #missedInterrupts > MAX_EVENT_HISTORY do
        table.remove(missedInterrupts, 1)
    end
}

-- Remove potential interrupt
function CombatAnalysis:RemovePotentialInterrupt(sourceGUID, spellID)
    -- Remove this spell from the missed interrupts list
    for i, interrupt in ipairs(missedInterrupts) do
        if interrupt.sourceGUID == sourceGUID and interrupt.spellID == spellID and not interrupt.processed then
            -- Mark as processed instead of removing to keep statistics
            missedInterrupts[i].processed = true
            missedInterrupts[i].interrupted = true
            break
        end
    end
}

-- Record missed interrupt
function CombatAnalysis:RecordMissedInterrupt(targetGUID, targetName, spellID, spellName, timestamp, reason)
    -- Skip if interrupt tracking is disabled
    local settings = ConfigRegistry:GetSettings("CombatAnalysis")
    if not settings.eventTracking.trackInterrupts then
        return
    end
    
    -- Find the matching missed interrupt
    for i, interrupt in ipairs(missedInterrupts) do
        if interrupt.sourceGUID == targetGUID and not interrupt.processed then
            -- Mark as processed
            missedInterrupts[i].processed = true
            missedInterrupts[i].missed = true
            missedInterrupts[i].reason = reason
            break
        end
    end
    
    -- Record for statistics
    if not interruptsMissed[spellID] then
        interruptsMissed[spellID] = {
            name = spellName,
            count = 0,
            lastTime = 0,
            reasons = {}
        }
    end
    
    -- Update stats
    interruptsMissed[spellID].count = interruptsMissed[spellID].count + 1
    interruptsMissed[spellID].lastTime = timestamp
    
    -- Track reason
    interruptsMissed[spellID].reasons[reason] = (interruptsMissed[spellID].reasons[reason] or 0) + 1
}

-- Record CC event
function CombatAnalysis:RecordCCEvent(sourceGUID, sourceName, destGUID, destName, spellID, spellName, timestamp, ccType)
    -- Skip if buff/debuff tracking is disabled
    local settings = ConfigRegistry:GetSettings("CombatAnalysis")
    if not settings.eventTracking.trackBuffsDebuffs then
        return
    end
    
    -- Add to CC events
    table.insert(ccEvents, {
        sourceGUID = sourceGUID,
        sourceName = sourceName,
        destGUID = destGUID,
        destName = destName,
        spellID = spellID,
        spellName = spellName,
        timestamp = timestamp,
        type = ccType
    })
    
    -- Trim if needed
    while #ccEvents > MAX_EVENT_HISTORY do
        table.remove(ccEvents, 1)
    end
    
    -- If this is a player-applied CC that was broken early, record it
    if sourceGUID == playerGUID and ccType == "broken" then
        -- Record for statistics
        if not missedCCs[spellID] then
            missedCCs[spellID] = {
                name = spellName,
                count = 0,
                lastTime = 0
            }
        end
        
        -- Update stats
        missedCCs[spellID].count = missedCCs[spellID].count + 1
        missedCCs[spellID].lastTime = timestamp
    end
}

-- Record defensive use
function CombatAnalysis:RecordDefensiveUse(spellID, spellName, timestamp)
    -- Skip if buff/debuff tracking is disabled
    local settings = ConfigRegistry:GetSettings("CombatAnalysis")
    if not settings.advancedSettings.enableDefensiveTracking then
        return
    end
    
    -- Record opportunity as taken
    for i, opportunity in ipairs(defensiveOpportunities) do
        if not opportunity.taken and GetTime() - opportunity.timestamp < 2.0 then
            -- Mark as taken
            defensiveOpportunities[i].taken = true
            defensiveOpportunities[i].spellID = spellID
            defensiveOpportunities[i].spellName = spellName
            break
        end
    end
}

-- Record missed defensive
function CombatAnalysis:RecordMissedDefensive(spellID, amount, timestamp, damageType)
    -- Skip if defensive tracking is disabled
    local settings = ConfigRegistry:GetSettings("CombatAnalysis")
    if not settings.advancedSettings.enableDefensiveTracking then
        return
    end
    
    -- Record opportunity
    table.insert(defensiveOpportunities, {
        timestamp = timestamp,
        amount = amount,
        taken = false,
        damageSpellID = spellID,
        damageType = damageType,
        healthPct = UnitHealth("player") / UnitHealthMax("player") * 100
    })
    
    -- Trim if needed
    while #defensiveOpportunities > MAX_EVENT_HISTORY do
        table.remove(defensiveOpportunities, 1)
    end
    
    -- If we didn't use a defensive within 1.5 seconds, record as missed
    C_Timer.After(1.5, function()
        for i, opportunity in ipairs(defensiveOpportunities) do
            if opportunity.timestamp == timestamp and not opportunity.taken then
                -- Record as missed
                table.insert(missedDefensives, opportunity)
                
                -- Trim if needed
                while #missedDefensives > MAX_EVENT_HISTORY do
                    table.remove(missedDefensives, 1)
                end
                
                break
            end
        end
    end)
}

-- Should use defensive
function CombatAnalysis:ShouldUseDefensive(amount, spellID, critical)
    -- Only suggest using defensives if we're in combat
    if not inCombat then
        return false
    end
    
    -- Get player health percentage
    local healthPct = UnitHealth("player") / UnitHealthMax("player") * 100
    
    -- Get damage as percentage of max health
    local maxHealth = UnitHealthMax("player")
    local damagePercent = (amount / maxHealth) * 100
    
    -- If damage is over 30% of max health, suggest defensive
    if damagePercent > 30 then
        return true
    end
    
    -- If health is below 40% and damage is over 15% of max health, suggest defensive
    if healthPct < 40 and damagePercent > 15 then
        return true
    end
    
    -- If health is below 20%, suggest defensive regardless of damage
    if healthPct < 20 then
        return true
    end
    
    return false
}

-- Start tracking boss
function CombatAnalysis:StartTrackingBoss(bossGUID, bossName)
    -- Skip if boss tracking is disabled
    local settings = ConfigRegistry:GetSettings("CombatAnalysis")
    if not settings.bossSettings.trackBossAbilities then
        return
    end
    
    -- Initialize boss ability tracking
    if not bossAbilityTimers[bossGUID] then
        bossAbilityTimers[bossGUID] = {
            name = bossName,
            abilities = {},
            lastAbility = nil,
            lastAbilityTime = 0
        }
    end
}

-- Record boss ability use
function CombatAnalysis:RecordBossAbilityUse(bossGUID, bossName, spellID, spellName, timestamp, abilityType, targetGUID)
    -- Skip if boss tracking is disabled
    local settings = ConfigRegistry:GetSettings("CombatAnalysis")
    if not settings.bossSettings.trackBossAbilities then
        return
    end
    
    -- Start tracking this boss if needed
    self:StartTrackingBoss(bossGUID, bossName)
    
    -- Get boss data
    local bossData = bossAbilityTimers[bossGUID]
    
    -- Initialize ability data if needed
    if not bossData.abilities[spellID] then
        bossData.abilities[spellID] = {
            name = spellName,
            usages = {},
            intervals = {},
            targets = {},
            nextPredicted = 0,
            minInterval = 0,
            maxInterval = 0,
            avgInterval = 0,
            occurrences = 0
        }
    end
    
    -- Get ability data
    local abilityData = bossData.abilities[spellID]
    
    -- Record usage
    table.insert(abilityData.usages, {
        timestamp = timestamp,
        targetGUID = targetGUID,
        type = abilityType
    })
    
    -- Update ability pattern recognition
    self:UpdateBossAbilityPattern(bossGUID, bossName, spellID, spellName, timestamp, abilityType, targetGUID)
    
    -- Record in global boss ability history
    table.insert(bossAbilityHistory, {
        bossGUID = bossGUID,
        bossName = bossName,
        spellID = spellID,
        spellName = spellName,
        timestamp = timestamp,
        type = abilityType,
        targetGUID = targetGUID,
        phase = currentBossPhase
    })
    
    -- Trim if needed
    while #bossAbilityHistory > MAX_EVENT_HISTORY do
        table.remove(bossAbilityHistory, 1)
    end
    
    -- Update last ability
    bossData.lastAbility = spellID
    bossData.lastAbilityTime = timestamp
    
    -- Update last boss ability
    lastBossAbility[bossGUID] = {
        spellID = spellID,
        spellName = spellName,
        timestamp = timestamp
    }
}

-- Update boss ability pattern
function CombatAnalysis:UpdateBossAbilityPattern(bossGUID, bossName, spellID, spellName, timestamp, abilityType, targetGUID)
    -- Skip if predictive analysis is disabled
    local settings = ConfigRegistry:GetSettings("CombatAnalysis")
    if not settings.generalSettings.enablePredictiveAnalysis then
        return
    end
    
    -- Get boss data
    local bossData = bossAbilityTimers[bossGUID]
    if not bossData then
        return
    end
    
    -- Get ability data
    local abilityData = bossData.abilities[spellID]
    if not abilityData then
        return
    end
    
    -- Calculate interval from last usage
    if #abilityData.usages > 1 then
        local previousUsage = abilityData.usages[#abilityData.usages - 1]
        local interval = timestamp - previousUsage.timestamp
        
        -- Add to intervals
        table.insert(abilityData.intervals, interval)
        
        -- Update statistics
        abilityData.occurrences = abilityData.occurrences + 1
        
        -- Calculate min/max intervals
        if abilityData.minInterval == 0 or interval < abilityData.minInterval then
            abilityData.minInterval = interval
        end
        
        if interval > abilityData.maxInterval then
            abilityData.maxInterval = interval
        end
        
        -- Calculate average interval
        local sum = 0
        for _, int in ipairs(abilityData.intervals) do
            sum = sum + int
        end
        abilityData.avgInterval = sum / #abilityData.intervals
        
        -- Predict next usage
        if #abilityData.intervals >= 2 then
            -- Simple prediction based on average
            abilityData.nextPredicted = timestamp + abilityData.avgInterval
            
            -- Calculate prediction confidence
            local confidence = self:CalculatePredictionConfidence(abilityData.intervals)
            predictionConfidence[spellID] = confidence
            
            -- Debug output for high-confidence predictions
            if confidence > 0.7 then
                local timeUntilNext = abilityData.nextPredicted - GetTime()
                if timeUntilNext > 0 then
                    API.PrintDebug(string.format("%s will cast %s again in %.1f seconds (%.0f%% confidence)", 
                                  bossName, spellName, timeUntilNext, confidence * 100))
                end
            end
        end
    end
    
    -- Track target patterns
    if targetGUID then
        -- Record target
        abilityData.targets[targetGUID] = (abilityData.targets[targetGUID] or 0) + 1
    end
    
    -- Check for ability sequences
    if bossData.lastAbility and bossData.lastAbility ~= spellID then
        -- Initialize pattern recognition if needed
        if not patternRecognition.bossAbilityPatterns[bossGUID] then
            patternRecognition.bossAbilityPatterns[bossGUID] = {
                sequences = {},
                lastThree = {},
                nextPredicted = {}
            }
        end
        
        -- Get pattern data
        local patternData = patternRecognition.bossAbilityPatterns[bossGUID]
        
        -- Update last three abilities
        table.insert(patternData.lastThree, bossData.lastAbility)
        if #patternData.lastThree > 3 then
            table.remove(patternData.lastThree, 1)
        end
        
        -- Check for sequences
        if #patternData.lastThree >= 2 then
            -- Build sequence string
            local sequenceKey = table.concat(patternData.lastThree, "-")
            
            -- Record sequence
            if not patternData.sequences[sequenceKey] then
                patternData.sequences[sequenceKey] = {
                    count = 0,
                    nextSpells = {}
                }
            end
            
            -- Update sequence stats
            patternData.sequences[sequenceKey].count = patternData.sequences[sequenceKey].count + 1
            
            -- Record next spell in sequence
            patternData.sequences[sequenceKey].nextSpells[spellID] = (patternData.sequences[sequenceKey].nextSpells[spellID] or 0) + 1
            
            -- Predict next spell after current one
            if patternData.sequences[sequenceKey].count >= 2 then
                -- Find most likely next spell
                local mostLikelyNext = nil
                local highestCount = 0
                
                for nextSpellID, count in pairs(patternData.sequences[sequenceKey].nextSpells) do
                    if count > highestCount then
                        highestCount = count
                        mostLikelyNext = nextSpellID
                    end
                end
                
                -- Record prediction
                if mostLikelyNext then
                    patternData.nextPredicted[spellID] = mostLikelyNext
                end
            end
        end
    end
}

-- Calculate prediction confidence
function CombatAnalysis:CalculatePredictionConfidence(intervals)
    -- Need at least 2 intervals for prediction
    if #intervals < 2 then
        return 0
    end
    
    -- Calculate mean and standard deviation
    local sum = 0
    for _, interval in ipairs(intervals) do
        sum = sum + interval
    end
    local mean = sum / #intervals
    
    local sumSquaredDiff = 0
    for _, interval in ipairs(intervals) do
        sumSquaredDiff = sumSquaredDiff + (interval - mean)^2
    end
    local stdDev = math.sqrt(sumSquaredDiff / #intervals)
    
    -- Calculate coefficient of variation (lower is better)
    local cv = stdDev / mean
    
    -- Convert to confidence (0-1)
    local confidence = 1 - math.min(cv, 1)
    
    -- Adjust based on sample size
    local sampleSizeAdjustment = math.min(1, #intervals / 5)
    
    return confidence * sampleSizeAdjustment
}

-- Check boss phase change
function CombatAnalysis:CheckBossPhaseChange(bossGUID, bossName, spellID, spellName, auraType, timestamp)
    -- Skip if phase detection is disabled
    local settings = ConfigRegistry:GetSettings("CombatAnalysis")
    if not settings.bossSettings.enablePhaseDetection then
        return
    end
    
    -- Only process if we have a current boss encounter
    if not currentBossEncounter then
        return
    end
    
    -- Check for phase transition auras
    if self:IsPhaseTransitionAura(spellID) then
        if auraType == "applied" then
            -- End current phase
            self:RecordBossPhaseEnd(bossGUID, bossName, timestamp, "phase_aura")
            
            -- Start new phase
            currentBossPhase = (currentBossPhase or 0) + 1
            bossPhaseStartTimes[currentBossPhase] = timestamp
            
            -- Add phase to encounter
            if currentBossEncounter then
                currentBossEncounter.phases[currentBossPhase] = {
                    number = currentBossPhase,
                    startTime = timestamp,
                    abilities = {}
                }
            end
            
            API.PrintDebug("Boss " .. bossName .. " entered phase " .. currentBossPhase)
        end
    end
}

-- Record boss phase end
function CombatAnalysis:RecordBossPhaseEnd(bossGUID, bossName, timestamp, reason)
    -- Skip if no current phase
    if not currentBossPhase then
        return
    end
    
    -- Add end time to current phase
    if currentBossEncounter and currentBossEncounter.phases[currentBossPhase] then
        currentBossEncounter.phases[currentBossPhase].endTime = timestamp
        currentBossEncounter.phases[currentBossPhase].duration = timestamp - currentBossEncounter.phases[currentBossPhase].startTime
        currentBossEncounter.phases[currentBossPhase].endReason = reason
    end
    
    API.PrintDebug("Boss phase " .. currentBossPhase .. " ended (" .. reason .. ")")
}

-- Is phase transition aura
function CombatAnalysis:IsPhaseTransitionAura(spellID)
    -- These would be specific to each boss encounter
    -- This is a simplified implementation
    local phaseAuras = {
        164406, -- Warlock Green Fire: Phase 2
        164407, -- Warlock Green Fire: Phase 3
        155222, -- Mana Shield (Phase 2 transition)
        155265, -- Blazing Shield (Phase 3 transition)
        219347, -- Soul Infused (Phase 2)
        219482  -- Soul Infused (Phase 3)
    }
    
    return tContains(phaseAuras, spellID)
}

-- Is spell interruptible
function CombatAnalysis:IsSpellInterruptible(spellID)
    -- In a real implementation, this would check a comprehensive database
    -- For simplicity, we'll assume most spells are interruptible
    return true
end

-- Is interrupt spell
function CombatAnalysis:IsInterruptSpell(spellID)
    -- Common interrupt abilities
    local interruptSpells = {
        2139,   -- Counterspell (Mage)
        1766,   -- Kick (Rogue)
        6552,   -- Pummel (Warrior)
        47528,  -- Mind Freeze (Death Knight)
        96231,  -- Rebuke (Paladin)
        57994,  -- Wind Shear (Shaman)
        183752, -- Disrupt (Demon Hunter)
        19647,  -- Spell Lock (Warlock)
        147362, -- Counter Shot (Hunter)
        116705, -- Spear Hand Strike (Monk)
        78675,  -- Solar Beam (Druid)
        15487   -- Silence (Priest)
    }
    
    return tContains(interruptSpells, spellID)
}

-- Is control debuff
function CombatAnalysis:IsControlDebuff(spellID)
    -- In a real implementation, this would check a comprehensive database
    -- This is a simplified version
    local controlDebuffs = {
        -- Common CC spells
        118,    -- Polymorph
        853,    -- Hammer of Justice
        605,    -- Mind Control
        2094,   -- Blind
        5782,   -- Fear
        6770,   -- Sap
        3355,   -- Freezing Trap
        51514,  -- Hex
        5211,   -- Mighty Bash
        339,    -- Entangling Roots
        2637,   -- Hibernate
        20066,  -- Repentance
        82691,  -- Ring of Frost
        115078, -- Paralysis
        8122,   -- Psychic Scream
        5246,   -- Intimidating Shout
        5484,   -- Howl of Terror
        19386,  -- Wyvern Sting
        113724, -- Ring of Peace
        31661,  -- Dragon's Breath
        33786,  -- Cyclone
        119381, -- Leg Sweep
        179057, -- Chaos Nova
        221562, -- Asphyxiate
        6789,   -- Mortal Coil
        317009, -- Sinful Brand
        255941, -- Wake of Ashes
        202137, -- Sigil of Silence
        226943  -- Mind Bomb
    }
    
    return tContains(controlDebuffs, spellID)
}

-- Is defensive buff
function CombatAnalysis:IsDefensiveBuff(spellID)
    -- Common defensive cooldowns
    local defensiveBuffs = {
        45438,  -- Ice Block (Mage)
        642,    -- Divine Shield (Paladin)
        871,    -- Shield Wall (Warrior)
        48792,  -- Icebound Fortitude (Death Knight)
        33206,  -- Pain Suppression (Priest)
        22812,  -- Barkskin (Druid)
        61336,  -- Survival Instincts (Druid)
        31224,  -- Cloak of Shadows (Rogue)
        186265, -- Aspect of the Turtle (Hunter)
        198589, -- Blur (Demon Hunter)
        104773, -- Unending Resolve (Warlock)
        118038, -- Die by the Sword (Warrior)
        184364, -- Enraged Regeneration (Warrior)
        115203, -- Fortifying Brew (Monk)
        116849, -- Life Cocoon (Monk)
        108271, -- Astral Shift (Shaman)
        55233,  -- Vampiric Blood (Death Knight)
        1022,   -- Blessing of Protection (Paladin)
        6940,   -- Blessing of Sacrifice (Paladin)
        102342, -- Ironbark (Druid)
        47788,  -- Guardian Spirit (Priest)
        243435, -- Fortifying Brew (Monk tank)
        198760, -- Intercept (Warrior)
        122278, -- Dampen Harm (Monk)
        122783, -- Diffuse Magic (Monk)
        213610, -- Holy Ward (Priest)
        235313, -- Blazing Barrier (Mage)
        48707,  -- Anti-Magic Shell (Death Knight)
        196555, -- Netherwalk (Demon Hunter)
        104773, -- Unending Resolve (Warlock)
        205604  -- Reverse Magic (Demon Hunter)
    }
    
    return tContains(defensiveBuffs, spellID)
}

-- Get spell resource cost
function CombatAnalysis:GetSpellResourceCost(spellID)
    -- In a real implementation, this would use the WoW API to get actual cost
    -- This is a simplified version
    
    -- Try to determine resource type based on class/spec
    local resourceType = nil
    
    if playerClass == "WARRIOR" then
        resourceType = Enum.PowerType.Rage
    elseif playerClass == "PALADIN" then
        resourceType = Enum.PowerType.Mana
    elseif playerClass == "HUNTER" then
        resourceType = Enum.PowerType.Focus
    elseif playerClass == "ROGUE" then
        resourceType = Enum.PowerType.Energy
    elseif playerClass == "PRIEST" then
        resourceType = Enum.PowerType.Mana
    elseif playerClass == "SHAMAN" then
        resourceType = Enum.PowerType.Mana
    elseif playerClass == "MAGE" then
        resourceType = Enum.PowerType.Mana
    elseif playerClass == "WARLOCK" then
        resourceType = Enum.PowerType.Mana
    elseif playerClass == "MONK" then
        resourceType = Enum.PowerType.Energy
    elseif playerClass == "DRUID" then
        if playerSpec == 2 then -- Feral
            resourceType = Enum.PowerType.Energy
        elseif playerSpec == 1 then -- Balance
            resourceType = Enum.PowerType.Mana
        else
            resourceType = Enum.PowerType.Mana
        end
    elseif playerClass == "DEMONHUNTER" then
        resourceType = Enum.PowerType.Fury
    elseif playerClass == "DEATHKNIGHT" then
        resourceType = Enum.PowerType.RunicPower
    elseif playerClass == "EVOKER" then
        resourceType = Enum.PowerType.Mana
    end
    
    -- Estimate cost (in a real addon, this would be more accurate)
    local cost = 0
    
    if resourceType == Enum.PowerType.Mana then
        cost = 500 + math.random(0, 1000) -- Random mana cost
    elseif resourceType == Enum.PowerType.Energy or resourceType == Enum.PowerType.Focus then
        cost = 20 + math.random(0, 30) -- Random energy/focus cost
    elseif resourceType == Enum.PowerType.Rage or resourceType == Enum.PowerType.RunicPower then
        cost = 10 + math.random(0, 30) -- Random rage/runic power cost
    elseif resourceType == Enum.PowerType.Fury then
        cost = 30 + math.random(0, 40) -- Random fury cost
    end
    
    return resourceType, cost
}

-- Update rotation sequence
function CombatAnalysis:UpdateRotationSequence(spellID, timestamp)
    -- Skip if rotation analysis is disabled
    local settings = ConfigRegistry:GetSettings("CombatAnalysis")
    if not settings.advancedSettings.enableRotationAnalysis then
        return
    end
    
    -- Initialize pattern recognition if needed
    if not patternRecognition.playerRotationPatterns then
        patternRecognition.playerRotationPatterns = {
            sequences = {},
            lastThree = {},
            spellFrequency = {}
        }
    end
    
    -- Get pattern data
    local patternData = patternRecognition.playerRotationPatterns
    
    -- Update spell frequency
    patternData.spellFrequency[spellID] = (patternData.spellFrequency[spellID] or 0) + 1
    
    -- Update last three abilities
    table.insert(patternData.lastThree, spellID)
    if #patternData.lastThree > 3 then
        table.remove(patternData.lastThree, 1)
    end
    
    -- Check for sequences
    if #patternData.lastThree >= 2 then
        -- Build sequence string
        local sequenceKey = table.concat(patternData.lastThree, "-")
        
        -- Record sequence
        if not patternData.sequences[sequenceKey] then
            patternData.sequences[sequenceKey] = {
                count = 0,
                timestamps = {}
            }
        end
        
        -- Update sequence stats
        patternData.sequences[sequenceKey].count = patternData.sequences[sequenceKey].count + 1
        
        -- Record timestamp
        table.insert(patternData.sequences[sequenceKey].timestamps, timestamp)
        
        -- Trim timestamps if needed
        while #patternData.sequences[sequenceKey].timestamps > 10 do
            table.remove(patternData.sequences[sequenceKey].timestamps, 1)
        end
    end
}

-- Analyze rotation efficiency
function CombatAnalysis:AnalyzeRotationEfficiency()
    -- Skip if rotation analysis is disabled
    local settings = ConfigRegistry:GetSettings("CombatAnalysis")
    if not settings.advancedSettings.enableRotationAnalysis then
        return
    end
    
    -- Skip if combat was too short
    if combatDuration < 10 then
        return
    end
    
    -- Initialize rotation efficiency
    rotationEfficiency = {
        overall = 0,
        resourceEfficiency = 0,
        damageEfficiency = 0,
        sequenceOptimality = 0,
        gapAnalysis = 0,
        cooldownUsage = 0
    }
    
    -- Calculate resource efficiency
    local totalResourceSpent = 0
    local totalDamageDone = 0
    
    for spellID, data in pairs(resourceSpent) do
        totalResourceSpent = totalResourceSpent + data.total
        
        -- Match with damage done
        if damageDone[spellID] then
            totalDamageDone = totalDamageDone + damageDone[spellID].total
        end
    end
    
    -- Calculate damage per resource
    if totalResourceSpent > 0 then
        rotationEfficiency.resourceEfficiency = totalDamageDone / totalResourceSpent
    end
    
    -- Calculate sequence optimality
    if patternRecognition.playerRotationPatterns and patternRecognition.playerRotationPatterns.sequences then
        local optimalSequences = 0
        local totalSequences = 0
        
        for sequenceKey, data in pairs(patternRecognition.playerRotationPatterns.sequences) do
            totalSequences = totalSequences + data.count
            
            -- Check if this is an optimal sequence
            if self:IsOptimalSequence(sequenceKey) then
                optimalSequences = optimalSequences + data.count
            end
        end
        
        -- Calculate percentage of optimal sequences
        if totalSequences > 0 then
            rotationEfficiency.sequenceOptimality = optimalSequences / totalSequences
        end
    end
    
    -- Calculate gap analysis
    if #spellCasts > 2 then
        local totalGaps = 0
        local lastCastTime = spellCasts[1].timestamp
        
        for i = 2, #spellCasts do
            local gap = spellCasts[i].timestamp - lastCastTime
            totalGaps = totalGaps + gap
            lastCastTime = spellCasts[i].timestamp
        end
        
        -- Calculate average gap
        local avgGap = totalGaps / (#spellCasts - 1)
        
        -- Evaluate gap score (lower gaps = better)
        rotationEfficiency.gapAnalysis = math.max(0, 1 - (avgGap / 2.5))
    end
    
    -- Calculate cooldown usage
    -- This would be specific to the class/spec
    -- For simplicity, we'll use a placeholder score
    rotationEfficiency.cooldownUsage = 0.7
    
    -- Calculate overall efficiency (weighted average)
    rotationEfficiency.overall = (
        rotationEfficiency.resourceEfficiency * 0.3 +
        rotationEfficiency.sequenceOptimality * 0.3 +
        rotationEfficiency.gapAnalysis * 0.2 +
        rotationEfficiency.cooldownUsage * 0.2
    )
    
    -- Debug output
    API.PrintDebug(string.format("Rotation efficiency: %.2f (Resource: %.2f, Sequence: %.2f, Gaps: %.2f, CDs: %.2f)",
                  rotationEfficiency.overall,
                  rotationEfficiency.resourceEfficiency,
                  rotationEfficiency.sequenceOptimality,
                  rotationEfficiency.gapAnalysis,
                  rotationEfficiency.cooldownUsage))
}

-- Is optimal sequence
function CombatAnalysis:IsOptimalSequence(sequenceKey)
    -- This would check class-specific optimal sequences
    -- For simplicity, we'll just return true for some example sequences
    
    -- Split sequence key
    local sequence = {}
    for spellID in sequenceKey:gmatch("([^-]+)") do
        table.insert(sequence, tonumber(spellID))
    end
    
    -- Check for class-specific optimal sequences
    if playerClass == "MAGE" then
        -- Example: Arcane Mage sequences
        if sequence[1] == 30451 and sequence[2] == 30451 and sequence[3] == 44425 then
            return true -- Arcane Blast > Arcane Blast > Arcane Barrage
        end
    elseif playerClass == "WARRIOR" then
        -- Example: Arms Warrior sequences
        if sequence[1] == 12294 and sequence[2] == 1464 then
            return true -- Mortal Strike > Slam
        end
    end
    
    return false
}

-- Analyze player death
function CombatAnalysis:AnalyzePlayerDeath(timestamp)
    -- Skip if defensive tracking is disabled
    local settings = ConfigRegistry:GetSettings("CombatAnalysis")
    if not settings.advancedSettings.enableDefensiveTracking then
        return
    end
    
    -- Look at damage taken in the last 5 seconds
    local deathWindow = 5.0
    local deathDamage = {}
    local totalDamage = 0
    
    -- Calculate total damage taken
    for _, event in ipairs(combatEvents) do
        if event.destGUID == playerGUID and timestamp - event.timestamp <= deathWindow and
           (event.event == "SPELL_DAMAGE" or event.event == "SPELL_PERIODIC_DAMAGE" or
            event.event == "RANGE_DAMAGE" or event.event == "SWING_DAMAGE") then
            
            local spellID = event.data[1] or 0
            local amount = event.data[4] or 0
            
            -- Add to death damage
            if not deathDamage[spellID] then
                deathDamage[spellID] = {
                    name = event.data[2] or "Unknown",
                    total = 0,
                    hits = 0
                }
            end
            
            deathDamage[spellID].total = deathDamage[spellID].total + amount
            deathDamage[spellID].hits = deathDamage[spellID].hits + 1
            totalDamage = totalDamage + amount
        end
    end
    
    -- Check for missed defensives
    local hadDefensive = false
    
    for spellID, data in pairs(buffGains) do
        if self:IsDefensiveBuff(spellID) and timestamp - data.lastTime <= deathWindow then
            hadDefensive = true
            break
        end
    end
    
    -- Record missed defensive if we didn't use one
    if not hadDefensive and totalDamage > 0 then
        table.insert(missedDefensives, {
            timestamp = timestamp,
            amount = totalDamage,
            damage = deathDamage,
            type = "death",
            healthPct = 0
        })
        
        -- Trim if needed
        while #missedDefensives > MAX_EVENT_HISTORY do
            table.remove(missedDefensives, 1)
        end
    end
}

-- Start performance tracking
function CombatAnalysis:StartPerformanceTracking()
    -- Skip if performance tracking is disabled
    local settings = ConfigRegistry:GetSettings("CombatAnalysis")
    if not settings.performanceSettings.enablePerformanceTracking then
        return
    end
    
    -- Initialize performance tracking
    performanceTracking = {
        enabled = true,
        startTime = GetTime(),
        lastCheckTime = GetTime(),
        samples = {},
        avgProcessTime = 0,
        maxProcessTime = 0,
        totalEventsProcessed = 0
    }
}

-- Stop performance tracking
function CombatAnalysis:StopPerformanceTracking()
    -- Skip if not tracking
    if not performanceTracking.enabled then
        return
    end
    
    -- Finalize performance metrics
    performanceMetrics = {
        totalTime = GetTime() - performanceTracking.startTime,
        avgProcessTime = performanceTracking.avgProcessTime,
        maxProcessTime = performanceTracking.maxProcessTime,
        totalEventsProcessed = performanceTracking.totalEventsProcessed,
        eventsPerSecond = performanceTracking.totalEventsProcessed / (GetTime() - performanceTracking.startTime)
    }
    
    -- Disable tracking
    performanceTracking.enabled = false
    
    -- Debug output
    API.PrintDebug(string.format("Combat analysis performance: %.2f events/sec, %.3f ms avg, %.3f ms max",
                  performanceMetrics.eventsPerSecond,
                  performanceMetrics.avgProcessTime,
                  performanceMetrics.maxProcessTime))
}

-- Generate combat summary
function CombatAnalysis:GenerateCombatSummary()
    -- Generate a summary string of the recent combat
    local summary = string.format("Combat summary (%.1f seconds):", combatDuration)
    
    -- Add damage done
    local totalDamage = 0
    for _, data in pairs(damageDone) do
        totalDamage = totalDamage + data.total
    end
    
    summary = summary .. string.format("\nDamage done: %.1fk (%.1f DPS)", 
              totalDamage / 1000, totalDamage / combatDuration)
    
    -- Add healing done
    local totalHealing = 0
    local totalEffectiveHealing = 0
    
    for _, data in pairs(healingDone) do
        totalHealing = totalHealing + data.total
        totalEffectiveHealing = totalEffectiveHealing + data.effective
    end
    
    if totalHealing > 0 then
        summary = summary .. string.format("\nHealing done: %.1fk (%.1f HPS, %.1f%% effective)", 
                  totalEffectiveHealing / 1000, totalEffectiveHealing / combatDuration,
                  (totalEffectiveHealing / totalHealing) * 100)
    end
    
    -- Add damage taken
    local totalTaken = 0
    for _, data in pairs(damageTaken) do
        totalTaken = totalTaken + data.total
    end
    
    summary = summary .. string.format("\nDamage taken: %.1fk (%.1f DTPS)", 
              totalTaken / 1000, totalTaken / combatDuration)
    
    -- Add interrupts
    local totalInterrupts = 0
    for _, data in pairs(interruptsDone) do
        totalInterrupts = totalInterrupts + data.count
    end
    
    summary = summary .. string.format("\nInterrupts: %d", totalInterrupts)
    
    -- Store summary
    recentCombatString = summary
    
    API.PrintDebug(summary)
}

-- Generate encounter summary
function CombatAnalysis:GenerateEncounterSummary(encounter)
    -- Generate a summary string of the encounter
    local summary = string.format("Encounter summary: %s (%.1f seconds, %s)", 
              encounter.name, encounter.duration, encounter.success and "Success" or "Failed")
    
    -- Add phase information
    summary = summary .. string.format("\nPhases: %d", #encounter.phases)
    
    for phaseNum, phase in pairs(encounter.phases) do
        if phase.duration then
            summary = summary .. string.format("\n  Phase %d: %.1f seconds", 
                      phaseNum, phase.duration)
        end
    end
    
    -- Add damage done
    local totalDamage = 0
    for _, data in pairs(damageDone) do
        totalDamage = totalDamage + data.total
    end
    
    summary = summary .. string.format("\nDamage done: %.1fk (%.1f DPS)", 
              totalDamage / 1000, totalDamage / encounter.duration)
    
    -- Add healing done
    local totalEffectiveHealing = 0
    for _, data in pairs(healingDone) do
        totalEffectiveHealing = totalEffectiveHealing + data.effective
    end
    
    if totalEffectiveHealing > 0 then
        summary = summary .. string.format("\nHealing done: %.1fk (%.1f HPS)", 
                  totalEffectiveHealing / 1000, totalEffectiveHealing / encounter.duration)
    end
    
    -- Store summary
    recentCombatString = summary
    
    API.PrintDebug(summary)
}

-- Is GUID type player
function IsGUIDTypePlayer(guid)
    if not guid then return false end
    return guid:match("^Player-")
end

-- Is GUID type NPC
function IsGUIDTypeNPC(guid)
    if not guid then return false end
    return guid:match("^Creature-") or guid:match("^Vehicle-")
end

-- Is boss GUID
function CombatAnalysis:IsBossGUID(guid)
    if not guid then return false end
    
    -- Check if this is a known boss
    -- In a real implementation, this would check boss unit IDs
    -- For simplicity, we'll just check if we're tracking it
    return bossAbilityTimers[guid] ~= nil
}

-- Is player friendly
function CombatAnalysis:IsPlayerFriendly(flags)
    -- Check unit flags for friendly bit
    return bit.band(flags, COMBATLOG_OBJECT_REACTION_FRIENDLY) > 0
}

-- Update player statistics
function CombatAnalysis:UpdatePlayerStatistics(event, ...)
    -- Initialize if needed
    if not playerStatistics.events then
        playerStatistics = {
            events = {},
            totalDamage = 0,
            totalHealing = 0,
            totalInterrupts = 0,
            abilities = {}
        }
    end
    
    -- Track event
    playerStatistics.events[event] = (playerStatistics.events[event] or 0) + 1
    
    -- Extract ability info
    local spellID, spellName = ...
    
    -- Track ability usage
    if spellID and spellID > 0 then
        if not playerStatistics.abilities[spellID] then
            playerStatistics.abilities[spellID] = {
                name = spellName,
                uses = 0,
                hits = 0,
                crits = 0,
                damage = 0,
                healing = 0
            }
        end
        
        playerStatistics.abilities[spellID].uses = playerStatistics.abilities[spellID].uses + 1
    end
}

-- Update environmental effects
function CombatAnalysis:UpdateEnvironmentalEffects(...)
    -- Track environmental effects that affect the player
    local environmentalType = ...
    
    -- Initialize if needed
    if not environmentalEffects[environmentalType] then
        environmentalEffects[environmentalType] = {
            count = 0,
            lastTime = 0
        }
    end
    
    -- Update stats
    environmentalEffects[environmentalType].count = environmentalEffects[environmentalType].count + 1
    environmentalEffects[environmentalType].lastTime = GetTime()
}

-- Clear combat data
function CombatAnalysis:ClearCombatData()
    -- Reset all combat tracking data
    damageDone = {}
    damageTaken = {}
    healingDone = {}
    healingTaken = {}
    interruptsDone = {}
    interruptsMissed = {}
    spellCasts = {}
    spellHits = {}
    spellMisses = {}
    spellReflects = {}
    spellDodges = {}
    spellParries = {}
    spellImmunes = {}
    spellResists = {}
    spellEvades = {}
    resourceGain = {}
    resourceSpent = {}
    buffGains = {}
    buffFades = {}
    debuffGains = {}
    debuffFades = {}
    enemyCasts = {}
    ccEvents = {}
    deathEvents = {}
    environmentalDamage = {}
    missedInterrupts = {}
    missedCCs = {}
    
    -- Clear processing queue
    processingQueue = {}
    
    -- Reset ongoing tracking
    bossAbilityTimers = {}
    patternRecognition = {}
    currentBossEncounter = nil
    currentBossPhase = nil
    bossPhaseStartTimes = {}
    
    API.PrintDebug("Combat data cleared")
}

-- Clear cache
function CombatAnalysis:ClearCache()
    -- Clear cached data that can be regenerated
    processingQueue = {}
    combatEvents = {}
    quickAccessStats = {}
    
    API.PrintDebug("Combat analysis cache cleared")
}

-- Toggle enabled state
function CombatAnalysis:Toggle()
    isEnabled = not isEnabled
    
    if isEnabled then
        combatLogFrame:Show()
    else
        combatLogFrame:Hide()
        
        -- Clear processing queue
        processingQueue = {}
    end
    
    return isEnabled
}

-- Is enabled
function CombatAnalysis:IsEnabled()
    return isEnabled
}

-- Get damage done
function CombatAnalysis:GetDamageDone()
    return damageDone
}

-- Get damage taken
function CombatAnalysis:GetDamageTaken()
    return damageTaken
}

-- Get healing done
function CombatAnalysis:GetHealingDone()
    return healingDone
}

-- Get healing taken
function CombatAnalysis:GetHealingTaken()
    return healingTaken
}

-- Get interrupts done
function CombatAnalysis:GetInterruptsDone()
    return interruptsDone
}

-- Get interrupts missed
function CombatAnalysis:GetInterruptsMissed()
    return interruptsMissed
}

-- Get spell casts
function CombatAnalysis:GetSpellCasts()
    return spellCasts
}

-- Get resource gain
function CombatAnalysis:GetResourceGain()
    return resourceGain
}

-- Get resource spent
function CombatAnalysis:GetResourceSpent()
    return resourceSpent
}

-- Get rotation efficiency
function CombatAnalysis:GetRotationEfficiency()
    return rotationEfficiency
}

-- Get missed defensives
function CombatAnalysis:GetMissedDefensives()
    return missedDefensives
}

-- Get recent combat string
function CombatAnalysis:GetRecentCombatString()
    return recentCombatString
}

-- Get performance metrics
function CombatAnalysis:GetPerformanceMetrics()
    return performanceMetrics
}

-- Get boss ability timers
function CombatAnalysis:GetBossAbilityTimers()
    return bossAbilityTimers
}

-- Get boss ability history
function CombatAnalysis:GetBossAbilityHistory()
    return bossAbilityHistory
}

-- Return the module
return CombatAnalysis