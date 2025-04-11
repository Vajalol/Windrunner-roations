------------------------------------------
-- WindrunnerRotations - Performance Tracker
-- Author: VortexQ8
-- The War Within Season 2
------------------------------------------

local addonName, WR = ...
local PerformanceTracker = {}
WR.PerformanceTracker = PerformanceTracker

-- Dependencies
local API = WR.API
local ConfigRegistry = WR.ConfigRegistry
local ModuleManager = WR.ModuleManager

-- Performance data storage
local sessionStartTime = 0
local sessionData = {}
local combatData = {}
local currentCombatStartTime = 0
local inCombat = false
local totalDamage = 0
local totalHealing = 0
local executedAbilities = {}
local abilityTimings = {}
local pendingGCDs = {}
local rotationEfficiency = 0
local resourceUsage = {}
local resourceWaste = {}
local combatHistory = {}
local trackedPlayers = {}
local trackedEnemies = {}
local trackedAuras = {}
local reactionTimes = {}
local resourceSnapshot = {}
local lastRotationTime = 0
local rotationDurations = {}
local missedGlobalCooldowns = 0
local abilitiesPerMinute = 0
local currentAbilityCount = 0
local executionErrors = {}
local enemyTrackingEnabled = false
local playerTrackingEnabled = false
local performanceLoggingEnabled = false

-- Constants
local MAX_COMBAT_HISTORY = 20
local PERFORMANCE_LOG_INTERVAL = 5 -- seconds
local GCD_THRESHOLD = 0.1 -- threshold to detect missed GCDs (seconds)
local RESOURCE_WASTE_THRESHOLD = 0.9 -- threshold to detect resource waste (90% of max)
local RESOURCE_MONITOR_INTERVAL = 0.5 -- seconds
local MAX_EXECUTION_ERRORS = 100

-- Initialize the Performance Tracker
function PerformanceTracker:Initialize()
    -- Register settings
    self:RegisterSettings()
    
    -- Setup event handlers
    self:SetupEvents()
    
    -- Setup integration with ModuleManager
    ModuleManager:RegisterCallback("OnRotationExecuted", function(moduleTable, timeTaken, success, ability)
        self:OnRotationExecuted(moduleTable, timeTaken, success, ability)
    end)
    
    -- Create session data
    self:StartNewSession()
    
    -- Register slash command
    SLASH_WRPERF1 = "/wrperf"
    SLASH_WRPERF2 = "/wrperformance"
    SlashCmdList["WRPERF"] = function(msg)
        self:HandleSlashCommand(msg)
    end
    
    API.PrintDebug("Performance Tracker initialized")
    return true
end

-- Register settings for the Performance Tracker
function PerformanceTracker:RegisterSettings()
    ConfigRegistry:RegisterSettings("PerformanceTracker", {
        generalSettings = {
            enablePerformanceTracking = {
                displayName = "Enable Performance Tracking",
                description = "Enable or disable performance tracking functionality",
                type = "toggle",
                default = true
            },
            trackRotationEfficiency = {
                displayName = "Track Rotation Efficiency",
                description = "Track rotation efficiency metrics like GCD usage",
                type = "toggle",
                default = true
            },
            trackResourceUsage = {
                displayName = "Track Resource Usage",
                description = "Track resource (mana, energy, etc.) usage efficiency",
                type = "toggle",
                default = true
            },
            performanceLogging = {
                displayName = "Enable Performance Logging",
                description = "Enable logging of performance data for later analysis",
                type = "toggle",
                default = false
            }
        },
        combatSettings = {
            trackEnemies = {
                displayName = "Track Enemy Information",
                description = "Track target and enemy information during combat",
                type = "toggle",
                default = true
            },
            trackPlayers = {
                displayName = "Track Player Information",
                description = "Track player and group information during combat",
                type = "toggle",
                default = true
            },
            trackDamageOutput = {
                displayName = "Track Damage Output",
                description = "Track detailed damage output information",
                type = "toggle",
                default = true
            },
            trackHealingOutput = {
                displayName = "Track Healing Output",
                description = "Track detailed healing output information",
                type = "toggle",
                default = true
            },
            saveDetailedCombatLogs = {
                displayName = "Save Detailed Combat Logs",
                description = "Save detailed combat logs for later analysis",
                type = "toggle",
                default = false
            }
        },
        displaySettings = {
            showPerformanceOverlay = {
                displayName = "Show Performance Overlay",
                description = "Show performance overlay during combat",
                type = "toggle",
                default = false
            },
            overlayPosition = {
                displayName = "Overlay Position",
                description = "Position of the performance overlay",
                type = "dropdown",
                options = {"Top Left", "Top Right", "Bottom Left", "Bottom Right"},
                default = "Top Right"
            },
            overlaySize = {
                displayName = "Overlay Size",
                description = "Size of the performance overlay",
                type = "slider",
                min = 0.5,
                max = 2.0,
                step = 0.1,
                default = 1.0
            },
            showRealtimeDPS = {
                displayName = "Show Realtime DPS",
                description = "Show realtime DPS/HPS counters",
                type = "toggle",
                default = true
            },
            showRotationEfficiency = {
                displayName = "Show Rotation Efficiency",
                description = "Show rotation efficiency metrics in the overlay",
                type = "toggle",
                default = true
            },
            autoHideCombatLog = {
                displayName = "Auto-hide Detailed Combat Log",
                description = "Automatically hide detailed combat log out of combat",
                type = "toggle",
                default = true
            }
        },
        analysisSettings = {
            analyzeRotationPriorities = {
                displayName = "Analyze Rotation Priorities",
                description = "Analyze and suggest optimal rotation priorities",
                type = "toggle",
                default = true
            },
            suggestOptimizations = {
                displayName = "Suggest Optimizations",
                description = "Suggest optimizations based on performance data",
                type = "toggle",
                default = true
            },
            compareToReferences = {
                displayName = "Compare to References",
                description = "Compare performance to reference data for your class/spec",
                type = "toggle",
                default = true
            },
            detailedReports = {
                displayName = "Generate Detailed Reports",
                description = "Generate detailed post-combat analysis reports",
                type = "toggle",
                default = true
            }
        }
    })
end

-- Setup event handlers
function PerformanceTracker:SetupEvents()
    -- Combat events
    API.RegisterEvent("PLAYER_REGEN_DISABLED", function()
        self:OnEnterCombat()
    end)
    
    API.RegisterEvent("PLAYER_REGEN_ENABLED", function()
        self:OnLeaveCombat()
    end)
    
    -- Unit events
    API.RegisterEvent("UNIT_HEALTH", function(unit)
        if self.IsTrackedUnit(unit) then
            self:UpdateUnitHealth(unit)
        end
    end)
    
    API.RegisterEvent("UNIT_POWER_FREQUENT", function(unit, powerType)
        if unit == "player" then
            self:UpdateResourceLevel(powerType)
        end
    end)
    
    -- Combat log events
    API.RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", function(...)
        self:ProcessCombatLogEvent(...)
    end)
    
    -- Cast events
    API.RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", function(unit, castGUID, spellID)
        if unit == "player" then
            self:OnSpellCastSucceeded(unit, castGUID, spellID)
        end
    end)
    
    API.RegisterEvent("UNIT_SPELLCAST_FAILED", function(unit, castGUID, spellID)
        if unit == "player" then
            self:OnSpellCastFailed(unit, castGUID, spellID)
        end
    end)
    
    API.RegisterEvent("UNIT_SPELLCAST_INTERRUPTED", function(unit, castGUID, spellID)
        if unit == "player" then
            self:OnSpellCastInterrupted(unit, castGUID, spellID)
        end
    end)
    
    -- GCD tracking
    API.RegisterEvent("SPELL_UPDATE_COOLDOWN", function()
        self:UpdateGCDStatus()
    end)
    
    -- Setup performance logging interval
    if performanceLoggingEnabled then
        C_Timer.NewTicker(PERFORMANCE_LOG_INTERVAL, function()
            self:LogPerformanceData()
        end)
    end
    
    -- Setup resource monitoring interval
    C_Timer.NewTicker(RESOURCE_MONITOR_INTERVAL, function()
        self:MonitorResourceUsage()
    end)
end

-- Start a new tracking session
function PerformanceTracker:StartNewSession()
    sessionStartTime = GetTime()
    sessionData = {
        startTime = sessionStartTime,
        endTime = nil,
        duration = 0,
        combats = 0,
        totalDamage = 0,
        totalHealing = 0,
        averageDPS = 0,
        averageHPS = 0,
        totalCombatTime = 0,
        executedAbilities = {},
        rotationEfficiency = 0,
        resourceEfficiency = {},
        reactionTimes = {},
        averageGCDUsage = 0,
        missedGCDs = 0,
        abilitiesPerMinute = 0,
        executionErrors = 0
    }
    
    combatData = {}
    combatHistory = {}
    executedAbilities = {}
    abilityTimings = {}
    resourceUsage = {}
    resourceWaste = {}
    trackedPlayers = {}
    trackedEnemies = {}
    trackedAuras = {}
    reactionTimes = {}
    rotationDurations = {}
    resourceSnapshot = {}
    executionErrors = {}
    
    -- Setup resource tracking based on player's class/spec
    self:SetupResourceTracking()
    
    API.PrintDebug("Started new performance tracking session")
end

-- Setup resource tracking based on player's class and spec
function PerformanceTracker:SetupResourceTracking()
    local classID = API.GetPlayerClassID()
    local specID = API.GetActiveSpecID()
    
    -- Clear existing data
    resourceSnapshot = {}
    resourceUsage = {}
    resourceWaste = {}
    
    -- Default tracking for all classes
    if not resourceSnapshot.mana and API.UsesMana("player") then
        resourceSnapshot.mana = {
            current = 100,
            max = 100
        }
        resourceUsage.mana = {
            generated = 0,
            spent = 0,
            wasted = 0
        }
    end
    
    -- Class-specific resource tracking
    if classID == 1 then -- Warrior
        resourceSnapshot.rage = {
            current = 0,
            max = 100
        }
        resourceUsage.rage = {
            generated = 0,
            spent = 0,
            wasted = 0
        }
    elseif classID == 2 then -- Paladin
        resourceSnapshot.holyPower = {
            current = 0,
            max = 5
        }
        resourceUsage.holyPower = {
            generated = 0,
            spent = 0,
            wasted = 0
        }
    elseif classID == 3 then -- Hunter
        resourceSnapshot.focus = {
            current = 100,
            max = 100
        }
        resourceUsage.focus = {
            generated = 0,
            spent = 0,
            wasted = 0
        }
    elseif classID == 4 then -- Rogue
        resourceSnapshot.energy = {
            current = 100,
            max = 100
        }
        resourceUsage.energy = {
            generated = 0,
            spent = 0,
            wasted = 0
        }
        resourceSnapshot.comboPoints = {
            current = 0,
            max = 5
        }
        resourceUsage.comboPoints = {
            generated = 0,
            spent = 0,
            wasted = 0
        }
    elseif classID == 5 then -- Priest
        if specID == 258 then -- Shadow
            resourceSnapshot.insanity = {
                current = 0,
                max = 100
            }
            resourceUsage.insanity = {
                generated = 0,
                spent = 0,
                wasted = 0
            }
        end
    elseif classID == 6 then -- Death Knight
        resourceSnapshot.runicPower = {
            current = 0,
            max = 100
        }
        resourceUsage.runicPower = {
            generated = 0,
            spent = 0,
            wasted = 0
        }
        resourceSnapshot.runes = {
            current = 6,
            max = 6
        }
        resourceUsage.runes = {
            generated = 0,
            spent = 0,
            wasted = 0
        }
    elseif classID == 7 then -- Shaman
        if specID == 262 or specID == 263 then -- Elemental or Enhancement
            resourceSnapshot.maelstrom = {
                current = 0,
                max = 100
            }
            resourceUsage.maelstrom = {
                generated = 0,
                spent = 0,
                wasted = 0
            }
        end
    elseif classID == 8 then -- Mage
        if specID == 62 then -- Arcane
            resourceSnapshot.arcaneCharges = {
                current = 0,
                max = 4
            }
            resourceUsage.arcaneCharges = {
                generated = 0,
                spent = 0,
                wasted = 0
            }
        end
    elseif classID == 9 then -- Warlock
        resourceSnapshot.soulShards = {
            current = 0,
            max = 5
        }
        resourceUsage.soulShards = {
            generated = 0,
            spent = 0,
            wasted = 0
        }
    elseif classID == 10 then -- Monk
        if specID == 269 or specID == 268 then -- Windwalker or Brewmaster
            resourceSnapshot.energy = {
                current = 100,
                max = 100
            }
            resourceUsage.energy = {
                generated = 0,
                spent = 0,
                wasted = 0
            }
            resourceSnapshot.chi = {
                current = 0,
                max = 5
            }
            resourceUsage.chi = {
                generated = 0,
                spent = 0,
                wasted = 0
            }
        end
    elseif classID == 11 then -- Druid
        if specID == 103 then -- Feral
            resourceSnapshot.energy = {
                current = 100,
                max = 100
            }
            resourceUsage.energy = {
                generated = 0,
                spent = 0,
                wasted = 0
            }
            resourceSnapshot.comboPoints = {
                current = 0,
                max = 5
            }
            resourceUsage.comboPoints = {
                generated = 0,
                spent = 0,
                wasted = 0
            }
        elseif specID == 104 then -- Guardian
            resourceSnapshot.rage = {
                current = 0,
                max = 100
            }
            resourceUsage.rage = {
                generated = 0,
                spent = 0,
                wasted = 0
            }
        elseif specID == 102 then -- Balance
            resourceSnapshot.astralPower = {
                current = 0,
                max = 100
            }
            resourceUsage.astralPower = {
                generated = 0,
                spent = 0,
                wasted = 0
            }
        end
    elseif classID == 12 then -- Demon Hunter
        resourceSnapshot.fury = {
            current = 0,
            max = 100
        }
        resourceUsage.fury = {
            generated = 0,
            spent = 0,
            wasted = 0
        }
    elseif classID == 13 then -- Evoker
        resourceSnapshot.essence = {
            current = 0,
            max = 6
        }
        resourceUsage.essence = {
            generated = 0,
            spent = 0,
            wasted = 0
        }
    end
    
    -- Take initial resource snapshots
    self:TakeResourceSnapshots()
end

-- Take resource snapshots of current values
function PerformanceTracker:TakeResourceSnapshots()
    for resourceName, _ in pairs(resourceSnapshot) do
        local current, max = self:GetResourceValues(resourceName)
        if current and max then
            resourceSnapshot[resourceName].current = current
            resourceSnapshot[resourceName].max = max
        end
    end
end

-- Get resource values for a specific resource
function PerformanceTracker:GetResourceValues(resourceName)
    if resourceName == "mana" then
        return API.GetPlayerManaPercentage(), 100
    elseif resourceName == "rage" then
        return API.GetPowerResource("rage") or 0, 100
    elseif resourceName == "energy" then
        return API.GetPlayerEnergy() or 0, 100
    elseif resourceName == "focus" then
        return API.GetPowerResource("focus") or 0, 100
    elseif resourceName == "runicPower" then
        return API.GetPowerResource("runicpower") or 0, 100
    elseif resourceName == "runes" then
        return API.GetRuneCount() or 0, 6
    elseif resourceName == "holyPower" then
        return API.GetPowerResource("holypower") or 0, 5
    elseif resourceName == "chi" then
        return API.GetPlayerPower() or 0, 5
    elseif resourceName == "comboPoints" then
        return API.GetComboPoints("player", "target") or 0, 5
    elseif resourceName == "arcaneCharges" then
        return API.GetArcaneCharges() or 0, 4
    elseif resourceName == "soulShards" then
        return API.GetPowerResource("soulshards") or 0, 5
    elseif resourceName == "astralPower" then
        return API.GetPowerResource("astralpower") or 0, 100
    elseif resourceName == "insanity" then
        return API.GetPowerResource("insanity") or 0, 100
    elseif resourceName == "maelstrom" then
        return API.GetPowerResource("maelstrom") or 0, 100
    elseif resourceName == "fury" then
        return API.GetPowerResource("fury") or 0, 100
    elseif resourceName == "essence" then
        return API.GetPowerResource("essence") or 0, 6
    end
    
    return 0, 100 -- Default fallback
end

-- Update resource level on power change
function PerformanceTracker:UpdateResourceLevel(powerType)
    if not inCombat then return end
    
    local resourceName = self:PowerTypeToResourceName(powerType)
    if not resourceName or not resourceSnapshot[resourceName] then return end
    
    local current, max = self:GetResourceValues(resourceName)
    if not current or not max then return end
    
    -- Track resource generation and consumption
    local previousValue = resourceSnapshot[resourceName].current
    local change = current - previousValue
    
    if change > 0 then
        -- Resource generated
        resourceUsage[resourceName].generated = resourceUsage[resourceName].generated + change
        
        -- Check for resource waste (near cap)
        if current >= max * RESOURCE_WASTE_THRESHOLD and previousValue >= max * RESOURCE_WASTE_THRESHOLD then
            local wastedAmount = math.min(change, current - (max * 0.9))
            if wastedAmount > 0 then
                resourceUsage[resourceName].wasted = resourceUsage[resourceName].wasted + wastedAmount
            end
        end
    elseif change < 0 then
        -- Resource spent
        resourceUsage[resourceName].spent = resourceUsage[resourceName].spent + math.abs(change)
    end
    
    -- Update current value
    resourceSnapshot[resourceName].current = current
    resourceSnapshot[resourceName].max = max
end

-- Convert WoW power type to resource name
function PerformanceTracker:PowerTypeToResourceName(powerType)
    local powerTypeMap = {
        ["MANA"] = "mana",
        ["RAGE"] = "rage",
        ["ENERGY"] = "energy",
        ["FOCUS"] = "focus",
        ["RUNIC_POWER"] = "runicPower",
        ["RUNES"] = "runes",
        ["HOLY_POWER"] = "holyPower",
        ["CHI"] = "chi",
        ["COMBO_POINTS"] = "comboPoints",
        ["ARCANE_CHARGES"] = "arcaneCharges",
        ["SOUL_SHARDS"] = "soulShards",
        ["ASTRAL_POWER"] = "astralPower",
        ["INSANITY"] = "insanity",
        ["MAELSTROM"] = "maelstrom",
        ["FURY"] = "fury",
        ["ESSENCE"] = "essence"
    }
    
    return powerTypeMap[powerType]
end

-- Monitor resource usage for efficiency analysis
function PerformanceTracker:MonitorResourceUsage()
    if not inCombat then return end
    
    -- Take resource snapshots and update waste tracking
    self:TakeResourceSnapshots()
    
    -- Check for resource capping
    for resourceName, data in pairs(resourceSnapshot) do
        if data.current >= data.max * RESOURCE_WASTE_THRESHOLD then
            resourceWaste[resourceName] = (resourceWaste[resourceName] or 0) + RESOURCE_MONITOR_INTERVAL
        end
    end
end

-- Update GCD status and track rotational efficiency
function PerformanceTracker:UpdateGCDStatus()
    if not inCombat then return end
    
    local settings = ConfigRegistry:GetSettings("PerformanceTracker")
    if not settings.generalSettings.trackRotationEfficiency then return end
    
    local gcdStart, gcdDuration = API.GetGCDInfo()
    if not gcdStart or not gcdDuration then return end
    
    local gcdRemaining = (gcdStart + gcdDuration) - GetTime()
    
    -- Only track if GCD was recently started to avoid duplicate tracking
    if gcdRemaining > 0 and gcdRemaining < gcdDuration - GCD_THRESHOLD then
        -- This is an active GCD
        local gcdEnd = gcdStart + gcdDuration
        
        -- Store this GCD for tracking
        pendingGCDs[gcdEnd] = {
            start = gcdStart,
            duration = gcdDuration,
            used = false
        }
    end
    
    -- Check for expired GCDs and count missed ones
    local now = GetTime()
    for gcdEnd, data in pairs(pendingGCDs) do
        if now > gcdEnd + 0.5 then -- Allow a small grace period after GCD ends
            if not data.used then
                missedGlobalCooldowns = missedGlobalCooldowns + 1
            end
            pendingGCDs[gcdEnd] = nil
        end
    end
end

-- Called when a spell cast is successful
function PerformanceTracker:OnSpellCastSucceeded(unit, castGUID, spellID)
    if not inCombat then return end
    
    local spellName = API.GetSpellInfo(spellID) and API.GetSpellInfo(spellID).name or "Unknown"
    
    -- Track the ability usage
    if not executedAbilities[spellName] then
        executedAbilities[spellName] = {
            id = spellID,
            count = 1,
            successful = 1,
            failed = 0,
            interrupted = 0,
            damage = 0,
            healing = 0,
            lastCast = GetTime()
        }
    else
        executedAbilities[spellName].count = executedAbilities[spellName].count + 1
        executedAbilities[spellName].successful = executedAbilities[spellName].successful + 1
        executedAbilities[spellName].lastCast = GetTime()
    end
    
    -- Increment ability counter for APM calculation
    currentAbilityCount = currentAbilityCount + 1
    
    -- Mark a pending GCD as used
    local now = GetTime()
    for gcdEnd, data in pairs(pendingGCDs) do
        if now >= data.start and now <= gcdEnd + 0.5 and not data.used then
            data.used = true
            break
        end
    end
    
    -- Track reaction time
    local castStart = abilityTimings[castGUID] and abilityTimings[castGUID].startTime or now
    local reactionTime = now - castStart
    if reactionTime < 3.0 then -- Only track reasonable reaction times
        table.insert(reactionTimes, reactionTime)
    end
    
    -- Clean up the timing data
    abilityTimings[castGUID] = nil
end

-- Called when a spell cast fails
function PerformanceTracker:OnSpellCastFailed(unit, castGUID, spellID)
    if not inCombat then return end
    
    local spellName = API.GetSpellInfo(spellID) and API.GetSpellInfo(spellID).name or "Unknown"
    
    -- Track the failure
    if not executedAbilities[spellName] then
        executedAbilities[spellName] = {
            id = spellID,
            count = 1,
            successful = 0,
            failed = 1,
            interrupted = 0,
            damage = 0,
            healing = 0,
            lastCast = GetTime()
        }
    else
        executedAbilities[spellName].count = executedAbilities[spellName].count + 1
        executedAbilities[spellName].failed = executedAbilities[spellName].failed + 1
        executedAbilities[spellName].lastCast = GetTime()
    end
    
    -- Record the error
    self:RecordExecutionError("FAIL", spellName, "Cast failed")
    
    -- Clean up the timing data
    abilityTimings[castGUID] = nil
end

-- Called when a spell cast is interrupted
function PerformanceTracker:OnSpellCastInterrupted(unit, castGUID, spellID)
    if not inCombat then return end
    
    local spellName = API.GetSpellInfo(spellID) and API.GetSpellInfo(spellID).name or "Unknown"
    
    -- Track the interruption
    if not executedAbilities[spellName] then
        executedAbilities[spellName] = {
            id = spellID,
            count = 1,
            successful = 0,
            failed = 0,
            interrupted = 1,
            damage = 0,
            healing = 0,
            lastCast = GetTime()
        }
    else
        executedAbilities[spellName].count = executedAbilities[spellName].count + 1
        executedAbilities[spellName].interrupted = executedAbilities[spellName].interrupted + 1
        executedAbilities[spellName].lastCast = GetTime()
    end
    
    -- Record the error
    self:RecordExecutionError("INTERRUPT", spellName, "Cast interrupted")
    
    -- Clean up the timing data
    abilityTimings[castGUID] = nil
end

-- Record a rotation execution error
function PerformanceTracker:RecordExecutionError(errorType, ability, message)
    if #executionErrors >= MAX_EXECUTION_ERRORS then
        -- Remove oldest error to make room
        table.remove(executionErrors, 1)
    end
    
    table.insert(executionErrors, {
        time = GetTime(),
        type = errorType,
        ability = ability,
        message = message
    })
end

-- Called when the rotation is executed by a module
function PerformanceTracker:OnRotationExecuted(moduleTable, timeTaken, success, ability)
    if not inCombat then return end
    
    -- Track rotation execution time
    table.insert(rotationDurations, timeTaken)
    lastRotationTime = GetTime()
    
    -- Track rotation success/failure
    if not success then
        self:RecordExecutionError("ROTATION", moduleTable.name or "Unknown", "Rotation execution failed")
    end
}

-- Process combat log event
function PerformanceTracker:ProcessCombatLogEvent(...)
    if not inCombat then return end
    
    local settings = ConfigRegistry:GetSettings("PerformanceTracker")
    local timestamp, eventType, _, sourceGUID, sourceName, sourceFlags, _, destGUID, destName, destFlags, _ = CombatLogGetCurrentEventInfo()
    
    -- Only process events from the player or their pets
    if not API.IsPlayerOrPlayerPet(sourceGUID) then
        return
    end
    
    -- Track damage events
    if settings.combatSettings.trackDamageOutput and (eventType == "SPELL_DAMAGE" or eventType == "SWING_DAMAGE" or eventType == "RANGE_DAMAGE") then
        local spellID, spellName, _, amount = select(12, CombatLogGetCurrentEventInfo())
        
        -- Handle non-spell damage
        if eventType == "SWING_DAMAGE" then
            spellName = "Auto Attack"
            amount = select(15, CombatLogGetCurrentEventInfo())
        elseif eventType == "RANGE_DAMAGE" then
            amount = select(15, CombatLogGetCurrentEventInfo())
        end
        
        if amount then
            totalDamage = totalDamage + amount
            
            -- Track ability-specific damage
            if executedAbilities[spellName] then
                executedAbilities[spellName].damage = (executedAbilities[spellName].damage or 0) + amount
            elseif spellName then -- May be an ability not directly cast (e.g. a DoT)
                if not executedAbilities[spellName] then
                    executedAbilities[spellName] = {
                        id = spellID,
                        count = 0,
                        successful = 0,
                        failed = 0,
                        interrupted = 0,
                        damage = amount,
                        healing = 0,
                        lastCast = GetTime()
                    }
                else
                    executedAbilities[spellName].damage = (executedAbilities[spellName].damage or 0) + amount
                end
            end
            
            -- Update combat data
            combatData.damage = (combatData.damage or 0) + amount
        end
    end
    
    -- Track healing events
    if settings.combatSettings.trackHealingOutput and (eventType == "SPELL_HEAL" or eventType == "SPELL_PERIODIC_HEAL") then
        local spellID, spellName, _, amount, overhealing = select(12, CombatLogGetCurrentEventInfo())
        
        if amount then
            local effectiveHealing = amount - (overhealing or 0)
            totalHealing = totalHealing + effectiveHealing
            
            -- Track ability-specific healing
            if executedAbilities[spellName] then
                executedAbilities[spellName].healing = (executedAbilities[spellName].healing or 0) + effectiveHealing
            elseif spellName then -- May be an ability not directly cast (e.g. a HoT)
                if not executedAbilities[spellName] then
                    executedAbilities[spellName] = {
                        id = spellID,
                        count = 0,
                        successful = 0,
                        failed = 0,
                        interrupted = 0,
                        damage = 0,
                        healing = effectiveHealing,
                        lastCast = GetTime()
                    }
                else
                    executedAbilities[spellName].healing = (executedAbilities[spellName].healing or 0) + effectiveHealing
                end
            end
            
            -- Update combat data
            combatData.healing = (combatData.healing or 0) + effectiveHealing
        end
    end
    
    -- Track aura applications
    if eventType == "SPELL_AURA_APPLIED" or eventType == "SPELL_AURA_REFRESH" then
        local spellID, spellName, _, auraType = select(12, CombatLogGetCurrentEventInfo())
        
        -- Track aura applications
        if not trackedAuras[destGUID] then
            trackedAuras[destGUID] = {}
        end
        
        trackedAuras[destGUID][spellID] = {
            name = spellName,
            type = auraType,
            appliedAt = GetTime()
        }
    end
    
    -- Track aura removals
    if eventType == "SPELL_AURA_REMOVED" then
        local spellID = select(12, CombatLogGetCurrentEventInfo())
        
        -- Remove from tracked auras
        if trackedAuras[destGUID] and trackedAuras[destGUID][spellID] then
            local auraData = trackedAuras[destGUID][spellID]
            local duration = GetTime() - auraData.appliedAt
            
            -- Update ability uptime tracking
            if executedAbilities[auraData.name] then
                executedAbilities[auraData.name].uptime = (executedAbilities[auraData.name].uptime or 0) + duration
            end
            
            trackedAuras[destGUID][spellID] = nil
        end
    end
    
    -- If enabled, save detailed combat log
    if settings.combatSettings.saveDetailedCombatLogs then
        -- Implement detailed log saving here
    end
}

-- Called when entering combat
function PerformanceTracker:OnEnterCombat()
    local settings = ConfigRegistry:GetSettings("PerformanceTracker")
    if not settings.generalSettings.enablePerformanceTracking then
        return
    end
    
    inCombat = true
    currentCombatStartTime = GetTime()
    
    -- Reset combat-specific tracking
    combatData = {
        startTime = currentCombatStartTime,
        endTime = nil,
        duration = 0,
        damage = 0,
        healing = 0,
        dps = 0,
        hps = 0,
        abilities = {},
        resourceUsage = {},
        missedGCDs = 0,
        rotationEfficiency = 0
    }
    
    currentAbilityCount = 0
    missedGlobalCooldowns = 0
    
    enemyTrackingEnabled = settings.combatSettings.trackEnemies
    playerTrackingEnabled = settings.combatSettings.trackPlayers
    performanceLoggingEnabled = settings.generalSettings.performanceLogging
    
    -- Initialize combat tracker UI if enabled
    if settings.displaySettings.showPerformanceOverlay then
        self:InitializePerformanceUI()
    end
    
    API.PrintDebug("Performance tracking: Combat started")
}

-- Called when leaving combat
function PerformanceTracker:OnLeaveCombat()
    if not inCombat then return end
    
    local combatEndTime = GetTime()
    local combatDuration = combatEndTime - currentCombatStartTime
    
    -- Skip very short combats
    if combatDuration < 5 then
        inCombat = false
        return
    end
    
    -- Update combat data
    combatData.endTime = combatEndTime
    combatData.duration = combatDuration
    
    -- Calculate DPS and HPS
    combatData.dps = combatData.damage / combatDuration
    combatData.hps = combatData.healing / combatDuration
    
    -- Calculate rotation efficiency
    local totalPossibleGCDs = math.floor(combatDuration / 1.5) -- Approximate, based on 1.5s GCD
    if totalPossibleGCDs > 0 then
        local usedGCDs = totalPossibleGCDs - missedGlobalCooldowns
        rotationEfficiency = (usedGCDs / totalPossibleGCDs) * 100
        combatData.rotationEfficiency = rotationEfficiency
    end
    
    -- Calculate APM
    abilitiesPerMinute = (currentAbilityCount / combatDuration) * 60
    combatData.abilitiesPerMinute = abilitiesPerMinute
    
    -- Snapshot resource usage
    combatData.resourceUsage = {}
    for resourceName, data in pairs(resourceUsage) do
        combatData.resourceUsage[resourceName] = {
            generated = data.generated,
            spent = data.spent,
            wasted = data.wasted
        }
    }
    
    -- Snapshot ability usage
    combatData.abilities = {}
    for abilityName, data in pairs(executedAbilities) do
        combatData.abilities[abilityName] = {
            count = data.count,
            successful = data.successful,
            failed = data.failed,
            interrupted = data.interrupted,
            damage = data.damage or 0,
            healing = data.healing or 0
        }
    }
    
    -- Add to combat history
    if #combatHistory >= MAX_COMBAT_HISTORY then
        table.remove(combatHistory, 1) -- Remove oldest entry
    end
    table.insert(combatHistory, combatData)
    
    -- Update session data
    sessionData.combats = sessionData.combats + 1
    sessionData.totalCombatTime = sessionData.totalCombatTime + combatDuration
    sessionData.totalDamage = sessionData.totalDamage + (combatData.damage or 0)
    sessionData.totalHealing = sessionData.totalHealing + (combatData.healing or 0)
    
    if sessionData.totalCombatTime > 0 then
        sessionData.averageDPS = sessionData.totalDamage / sessionData.totalCombatTime
        sessionData.averageHPS = sessionData.totalHealing / sessionData.totalCombatTime
    end
    
    -- Analyze performance and make suggestions if enabled
    local settings = ConfigRegistry:GetSettings("PerformanceTracker")
    if settings.analysisSettings.analyzeRotationPriorities then
        self:AnalyzeRotationPerformance()
    end
    
    -- Generate detailed report if enabled
    if settings.analysisSettings.detailedReports then
        self:GenerateDetailedReport()
    }
    
    -- Reset tracking for next combat
    inCombat = false
    
    -- Hide performance UI if auto-hide is enabled
    if settings.displaySettings.autoHideCombatLog then
        self:HidePerformanceUI()
    end
    
    API.PrintDebug("Performance tracking: Combat ended")
}

-- Initialize the performance UI overlay
function PerformanceTracker:InitializePerformanceUI()
    -- Check if we already have a UI frame
    if self.performanceFrame then
        self.performanceFrame:Show()
        return
    end
    
    -- Create main frame
    local frame = CreateFrame("Frame", "WindrunnerPerformanceFrame", UIParent)
    frame:SetSize(200, 150)
    
    -- Position based on settings
    local settings = ConfigRegistry:GetSettings("PerformanceTracker").displaySettings
    local position = settings.overlayPosition
    
    if position == "Top Left" then
        frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 10, -10)
    elseif position == "Top Right" then
        frame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -10, -10)
    elseif position == "Bottom Left" then
        frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 10, 10)
    else -- Bottom Right
        frame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -10, 10)
    end
    
    -- Apply scaling
    frame:SetScale(settings.overlaySize)
    
    -- Create background
    frame.bg = frame:CreateTexture(nil, "BACKGROUND")
    frame.bg:SetAllPoints(frame)
    frame.bg:SetColorTexture(0, 0, 0, 0.7)
    
    -- Create border
    frame.border = CreateFrame("Frame", nil, frame)
    frame.border:SetPoint("TOPLEFT", frame, "TOPLEFT", -1, 1)
    frame.border:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 1, -1)
    frame.border:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    frame.border:SetBackdropBorderColor(0.6, 0.6, 0.6, 0.8)
    
    -- Title text
    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.title:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -8)
    frame.title:SetText("WindrunnerRotations Performance")
    
    -- DPS/HPS text
    frame.dpsText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.dpsText:SetPoint("TOPLEFT", frame.title, "BOTTOMLEFT", 0, -5)
    frame.dpsText:SetText("DPS: 0")
    
    frame.hpsText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.hpsText:SetPoint("TOPLEFT", frame.dpsText, "BOTTOMLEFT", 0, -3)
    frame.hpsText:SetText("HPS: 0")
    
    -- Rotation efficiency
    if settings.showRotationEfficiency then
        frame.efficiencyText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        frame.efficiencyText:SetPoint("TOPLEFT", frame.hpsText, "BOTTOMLEFT", 0, -3)
        frame.efficiencyText:SetText("Rotation: 100%")
        
        frame.apmText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        frame.apmText:SetPoint("TOPLEFT", frame.efficiencyText, "BOTTOMLEFT", 0, -3)
        frame.apmText:SetText("APM: 0")
    end
    
    -- Make frame movable
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    
    -- Setup update
    frame:SetScript("OnUpdate", function(self, elapsed)
        self.updateTimer = (self.updateTimer or 0) + elapsed
        if self.updateTimer >= 0.5 then
            self.updateTimer = 0
            PerformanceTracker:UpdatePerformanceUI()
        end
    end)
    
    self.performanceFrame = frame
    frame:Show()
}

-- Update the performance UI
function PerformanceTracker:UpdatePerformanceUI()
    local frame = self.performanceFrame
    if not frame or not inCombat then return end
    
    local combatDuration = GetTime() - currentCombatStartTime
    if combatDuration <= 0 then return end
    
    local settings = ConfigRegistry:GetSettings("PerformanceTracker").displaySettings
    
    -- Update DPS/HPS
    if settings.showRealtimeDPS then
        local currentDPS = combatData.damage / combatDuration
        local currentHPS = combatData.healing / combatDuration
        
        frame.dpsText:SetText(string.format("DPS: %.0f", currentDPS))
        frame.hpsText:SetText(string.format("HPS: %.0f", currentHPS))
    end
    
    -- Update efficiency metrics
    if settings.showRotationEfficiency then
        local totalPossibleGCDs = math.floor(combatDuration / 1.5)
        local efficiency = 100
        
        if totalPossibleGCDs > 0 then
            local usedGCDs = totalPossibleGCDs - missedGlobalCooldowns
            efficiency = (usedGCDs / totalPossibleGCDs) * 100
        end
        
        frame.efficiencyText:SetText(string.format("Rotation: %.0f%%", efficiency))
        
        -- Calculate APM
        local apm = (currentAbilityCount / combatDuration) * 60
        frame.apmText:SetText(string.format("APM: %.0f", apm))
    end
}

-- Hide the performance UI
function PerformanceTracker:HidePerformanceUI()
    if self.performanceFrame then
        self.performanceFrame:Hide()
    end
}

-- Analyze rotation performance and generate suggestions
function PerformanceTracker:AnalyzeRotationPerformance()
    local analysis = {
        rotationEfficiency = rotationEfficiency,
        topAbilities = {},
        resourceEfficiency = {},
        suggestions = {}
    }
    
    -- Analyze top damage/healing abilities
    local sortedAbilities = {}
    for abilityName, data in pairs(executedAbilities) do
        table.insert(sortedAbilities, {
            name = abilityName,
            damage = data.damage or 0,
            healing = data.healing or 0,
            count = data.count,
            successful = data.successful,
            failed = data.failed,
            interrupted = data.interrupted
        })
    end
    
    -- Sort by damage+healing contribution
    table.sort(sortedAbilities, function(a, b)
        return (a.damage + a.healing) > (b.damage + b.healing)
    end)
    
    -- Take top 5 abilities
    for i = 1, math.min(5, #sortedAbilities) do
        table.insert(analysis.topAbilities, sortedAbilities[i])
    end
    
    -- Analyze resource efficiency
    for resourceName, data in pairs(resourceUsage) do
        local efficiency = 0
        if data.generated > 0 then
            efficiency = ((data.generated - data.wasted) / data.generated) * 100
        end
        
        analysis.resourceEfficiency[resourceName] = {
            generated = data.generated,
            spent = data.spent,
            wasted = data.wasted,
            efficiency = efficiency
        }
        
        -- Add suggestions for resource usage
        if efficiency < 85 then
            table.insert(analysis.suggestions, {
                type = "RESOURCE",
                resource = resourceName,
                message = string.format("Consider optimizing %s usage. Current efficiency: %.0f%%", 
                    resourceName, efficiency)
            })
        end
    end
    
    -- Generate rotation suggestions
    if rotationEfficiency < 85 then
        table.insert(analysis.suggestions, {
            type = "ROTATION",
            message = string.format("Rotation efficiency is low (%.0f%%). Try to use abilities more consistently on GCD.", 
                rotationEfficiency)
        })
    end
    
    -- Check for ability usage issues
    for _, ability in ipairs(sortedAbilities) do
        if ability.failed / math.max(1, ability.count) > 0.2 then
            table.insert(analysis.suggestions, {
                type = "ABILITY",
                ability = ability.name,
                message = string.format("%s is failing frequently (%.0f%% of attempts). Check usage conditions.", 
                    ability.name, (ability.failed / ability.count) * 100)
            })
        end
        
        if ability.interrupted / math.max(1, ability.count) > 0.2 then
            table.insert(analysis.suggestions, {
                type = "ABILITY",
                ability = ability.name,
                message = string.format("%s is being interrupted frequently. Consider improving positioning or timing.", 
                    ability.name)
            })
        end
    end
    
    -- Store the analysis in combat data
    combatData.analysis = analysis
    
    -- If there are suggestions, output them
    local settings = ConfigRegistry:GetSettings("PerformanceTracker")
    if settings.analysisSettings.suggestOptimizations and #analysis.suggestions > 0 then
        API.Print("--- WindrunnerRotations Performance Suggestions ---")
        for i, suggestion in ipairs(analysis.suggestions) do
            API.Print(suggestion.message)
        end
    end
    
    return analysis
}

-- Generate a detailed performance report
function PerformanceTracker:GenerateDetailedReport()
    local report = {
        title = "WindrunnerRotations Performance Report",
        combat = {
            duration = combatData.duration,
            dps = combatData.dps,
            hps = combatData.hps,
            damageTotal = combatData.damage,
            healingTotal = combatData.healing,
            rotationEfficiency = combatData.rotationEfficiency,
            apm = combatData.abilitiesPerMinute
        },
        abilities = {},
        resources = {},
        suggestions = combatData.analysis and combatData.analysis.suggestions or {}
    }
    
    -- Add ability details
    for abilityName, data in pairs(combatData.abilities) do
        table.insert(report.abilities, {
            name = abilityName,
            count = data.count,
            successful = data.successful,
            failed = data.failed,
            interrupted = data.interrupted,
            damage = data.damage,
            healing = data.healing,
            dps = data.damage / combatData.duration,
            hps = data.healing / combatData.duration
        })
    end
    
    -- Sort abilities by damage+healing contribution
    table.sort(report.abilities, function(a, b)
        return (a.damage + a.healing) > (b.damage + b.healing)
    end)
    
    -- Add resource details
    for resourceName, data in pairs(combatData.resourceUsage) do
        local efficiency = 0
        if data.generated > 0 then
            efficiency = ((data.generated - data.wasted) / data.generated) * 100
        end
        
        report.resources[resourceName] = {
            generated = data.generated,
            spent = data.spent,
            wasted = data.wasted,
            efficiency = efficiency
        }
    end
    
    -- If there are execution errors, include a summary
    if #executionErrors > 0 then
        report.errors = {}
        
        -- Group errors by type and ability
        local errorSummary = {}
        for _, error in ipairs(executionErrors) do
            local key = error.type .. "_" .. error.ability
            errorSummary[key] = (errorSummary[key] or 0) + 1
        end
        
        -- Add to report
        for key, count in pairs(errorSummary) do
            local errorType, ability = string.match(key, "(.+)_(.+)")
            table.insert(report.errors, {
                type = errorType,
                ability = ability,
                count = count
            })
        end
        
        -- Sort by count
        table.sort(report.errors, function(a, b)
            return a.count > b.count
        end)
    end
    
    -- Save the report to combatData
    combatData.detailedReport = report
    
    -- Output report summary to chat
    API.Print("--- WindrunnerRotations Performance Report ---")
    API.Print(string.format("Combat Duration: %.1f seconds", report.combat.duration))
    API.Print(string.format("DPS: %.0f, HPS: %.0f", report.combat.dps, report.combat.hps))
    API.Print(string.format("Rotation Efficiency: %.0f%%, APM: %.0f", report.combat.rotationEfficiency, report.combat.apm))
    API.Print("Top 3 abilities:")
    
    for i = 1, math.min(3, #report.abilities) do
        local ability = report.abilities[i]
        if ability.damage > 0 then
            API.Print(string.format("%d. %s: %.0f damage (%.0f DPS, %.0f%%)", 
                i, ability.name, ability.damage, ability.dps, (ability.damage / math.max(1, report.combat.damageTotal)) * 100))
        elseif ability.healing > 0 then
            API.Print(string.format("%d. %s: %.0f healing (%.0f HPS, %.0f%%)", 
                i, ability.name, ability.healing, ability.hps, (ability.healing / math.max(1, report.combat.healingTotal)) * 100))
        end
    end
    
    return report
}

-- Log performance data at intervals
function PerformanceTracker:LogPerformanceData()
    if not inCombat or not performanceLoggingEnabled then return end
    
    local logEntry = {
        time = GetTime(),
        relativeTime = GetTime() - currentCombatStartTime,
        damage = combatData.damage or 0,
        healing = combatData.healing or 0,
        dps = 0,
        hps = 0,
        resources = {},
        missedGCDs = missedGlobalCooldowns,
        abilityCount = currentAbilityCount
    }
    
    -- Calculate current DPS/HPS
    local combatDuration = GetTime() - currentCombatStartTime
    if combatDuration > 0 then
        logEntry.dps = logEntry.damage / combatDuration
        logEntry.hps = logEntry.healing / combatDuration
    end
    
    -- Snapshot resources
    for resourceName, data in pairs(resourceSnapshot) do
        logEntry.resources[resourceName] = {
            current = data.current,
            max = data.max,
            percent = (data.current / math.max(1, data.max)) * 100
        }
    end
    
    -- Store the log entry
    if not combatData.performanceLogs then
        combatData.performanceLogs = {}
    end
    
    table.insert(combatData.performanceLogs, logEntry)
}

-- Handle slash command
function PerformanceTracker:HandleSlashCommand(msg)
    if not msg or msg == "" then
        -- Display help
        API.Print("WindrunnerRotations Performance Tracker Commands:")
        API.Print("/wrperf report - Show last combat report")
        API.Print("/wrperf show - Show performance overlay")
        API.Print("/wrperf hide - Hide performance overlay")
        API.Print("/wrperf reset - Reset all performance data")
        API.Print("/wrperf config - Open settings")
        return
    end
    
    local args = {}
    for arg in string.gmatch(msg, "%S+") do
        table.insert(args, arg)
    end
    
    local command = args[1]
    
    if command == "report" then
        if combatData.detailedReport then
            -- Output the last detailed report
            API.Print("--- WindrunnerRotations Latest Performance Report ---")
            local report = combatData.detailedReport
            API.Print(string.format("Combat Duration: %.1f seconds", report.combat.duration))
            API.Print(string.format("DPS: %.0f, HPS: %.0f", report.combat.dps, report.combat.hps))
            API.Print(string.format("Rotation Efficiency: %.0f%%, APM: %.0f", report.combat.rotationEfficiency, report.combat.apm))
            
            -- Top abilities by damage/healing
            API.Print("Top abilities:")
            for i = 1, math.min(5, #report.abilities) do
                local ability = report.abilities[i]
                if ability.damage > 0 then
                    API.Print(string.format("%d. %s: %.0f damage (%.0f DPS, %.0f%%)", 
                        i, ability.name, ability.damage, ability.dps, (ability.damage / math.max(1, report.combat.damageTotal)) * 100))
                elseif ability.healing > 0 then
                    API.Print(string.format("%d. %s: %.0f healing (%.0f HPS, %.0f%%)", 
                        i, ability.name, ability.healing, ability.hps, (ability.healing / math.max(1, report.combat.healingTotal)) * 100))
                end
            end
            
            -- Resource efficiency
            API.Print("Resource efficiency:")
            for resourceName, data in pairs(report.resources) do
                API.Print(string.format("%s: %.0f%% efficient (%.0f generated, %.0f wasted)", 
                    resourceName, data.efficiency, data.generated, data.wasted))
            end
            
            -- Suggestions
            if #report.suggestions > 0 then
                API.Print("Suggestions:")
                for i, suggestion in ipairs(report.suggestions) do
                    API.Print(string.format("%d. %s", i, suggestion.message))
                end
            end
        else
            API.Print("No combat report available. Complete a combat encounter first.")
        end
    elseif command == "show" then
        -- Show the performance overlay
        self:InitializePerformanceUI()
    elseif command == "hide" then
        -- Hide the performance overlay
        self:HidePerformanceUI()
    elseif command == "reset" then
        -- Reset all data
        self:StartNewSession()
        API.Print("WindrunnerRotations Performance data has been reset.")
    elseif command == "config" then
        -- Open settings
        if ConfigRegistry.OpenSettings then
            ConfigRegistry:OpenSettings("PerformanceTracker")
        else
            API.Print("Configuration interface not available.")
        end
    else
        API.Print("Unknown command. Type /wrperf for help.")
    end
end

-- Check if a unit should be tracked
function PerformanceTracker.IsTrackedUnit(unit)
    if not unit then return false end
    
    if playerTrackingEnabled and (unit == "player" or unit:match("^party%d$") or unit:match("^raid%d+$")) then
        return true
    end
    
    if enemyTrackingEnabled and (unit == "target" or unit:match("^boss%d$") or unit:match("^nameplate%d+$")) then
        return true
    end
    
    return false
end

-- Update tracked unit health
function PerformanceTracker:UpdateUnitHealth(unit)
    if not inCombat then return end
    
    local isPlayer = unit == "player" or unit:match("^party%d$") or unit:match("^raid%d+$")
    local isEnemy = unit == "target" or unit:match("^boss%d$") or unit:match("^nameplate%d+$")
    
    if isPlayer and playerTrackingEnabled then
        -- Track player health if not already tracking
        if not trackedPlayers[unit] then
            trackedPlayers[unit] = {
                guid = API.UnitGUID(unit),
                health = API.GetUnitHealthPercent(unit),
                class = API.UnitClass(unit),
                role = API.GetUnitRole(unit),
                auras = {}
            }
        else
            trackedPlayers[unit].health = API.GetUnitHealthPercent(unit)
        end
    elseif isEnemy and enemyTrackingEnabled then
        -- Track enemy health if not already tracking
        if not trackedEnemies[unit] then
            trackedEnemies[unit] = {
                guid = API.UnitGUID(unit),
                health = API.GetUnitHealthPercent(unit),
                auras = {}
            }
        else
            trackedEnemies[unit].health = API.GetUnitHealthPercent(unit)
        end
    end
}

return PerformanceTracker