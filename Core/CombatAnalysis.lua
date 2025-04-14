------------------------------------------
-- WindrunnerRotations - Advanced Combat Analysis System
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
local PerformanceTracker = WR.PerformanceTracker
local MachineLearning = WR.MachineLearning

-- Data storage
local combatLogs = {}
local currentCombatLog = nil
local analysisReports = {}
local improvementSuggestions = {}
local realtimeMetrics = {}
local combatHistory = {}
local spellAnalysis = {}
local rotationEfficiency = {}
local resourceUsage = {}
local combatID = 0
local MAX_COMBAT_LOGS = 20
local MAX_HISTORY_ENTRIES = 50
local METRICS_UPDATE_INTERVAL = 0.5 -- seconds

-- Initialize the Combat Analysis system
function CombatAnalysis:Initialize()
    -- Register settings
    self:RegisterSettings()
    
    -- Register slash command
    SLASH_WRANALYZE1 = "/wranalyze"
    SlashCmdList["WRANALYZE"] = function(msg)
        self:HandleSlashCommand(msg)
    end
    
    -- Setup event tracking
    self:SetupEventTracking()
    
    -- Initialize report templates
    self:InitializeReportTemplates()
    
    API.PrintDebug("Combat Analysis system initialized")
    return true
end

-- Register settings for Combat Analysis
function CombatAnalysis:RegisterSettings()
    ConfigRegistry:RegisterSettings("CombatAnalysis", {
        generalSettings = {
            enableAnalysis = {
                displayName = "Enable Combat Analysis",
                description = "Enable advanced combat analysis and reporting",
                type = "toggle",
                default = true
            },
            analysisDetail = {
                displayName = "Analysis Detail Level",
                description = "Level of detail for combat analysis",
                type = "dropdown",
                options = { "basic", "standard", "comprehensive" },
                default = "standard"
            },
            automaticReporting = {
                displayName = "Automatic Reporting",
                description = "Automatically generate reports after combat",
                type = "dropdown",
                options = { "never", "major_combat", "all_combat" },
                default = "major_combat"
            },
            minCombatDuration = {
                displayName = "Minimum Combat Duration",
                description = "Minimum duration (in seconds) to analyze",
                type = "slider",
                min = 5,
                max = 60,
                step = 5,
                default = 15
            }
        },
        reportSettings = {
            includeRotationAnalysis = {
                displayName = "Rotation Analysis",
                description = "Include rotation efficiency analysis in reports",
                type = "toggle",
                default = true
            },
            includeResourceAnalysis = {
                displayName = "Resource Analysis",
                description = "Include resource usage analysis in reports",
                type = "toggle",
                default = true
            },
            includeDamageAnalysis = {
                displayName = "Damage Analysis",
                description = "Include detailed damage analysis in reports",
                type = "toggle",
                default = true
            },
            includeImprovementSuggestions = {
                displayName = "Improvement Suggestions",
                description = "Include personalized improvement suggestions",
                type = "toggle",
                default = true
            },
            reportFormat = {
                displayName = "Report Format",
                description = "Format for generated reports",
                type = "dropdown",
                options = { "text", "detailed", "visual" },
                default = "detailed"
            }
        },
        realtimeSettings = {
            enableRealtimeAnalysis = {
                displayName = "Enable Realtime Analysis",
                description = "Analyze combat in real-time",
                type = "toggle",
                default = true
            },
            realtimeMetrics = {
                displayName = "Realtime Metrics",
                description = "Select which metrics to track in real-time",
                type = "multiselect",
                options = { "dps", "resource_efficiency", "rotation_efficiency", "cooldown_usage" },
                default = { "dps", "rotation_efficiency" }
            },
            updateInterval = {
                displayName = "Update Interval",
                description = "How often to update realtime metrics (seconds)",
                type = "slider",
                min = 0.1,
                max = 2.0,
                step = 0.1,
                default = 0.5
            }
        },
        referenceData = {
            useReferenceData = {
                displayName = "Use Reference Data",
                description = "Compare performance against reference data",
                type = "toggle",
                default = true
            },
            referenceDataSource = {
                displayName = "Reference Data Source",
                description = "Source for reference data",
                type = "dropdown",
                options = { "top_players", "class_average", "personal_best" },
                default = "class_average"
            },
            updateReferenceData = {
                displayName = "Update Reference Data",
                description = "How often to update reference data",
                type = "dropdown",
                options = { "never", "weekly", "monthly" },
                default = "weekly"
            }
        },
        improvementSettings = {
            enableSuggestions = {
                displayName = "Enable Improvement Suggestions",
                description = "Generate personalized improvement suggestions",
                type = "toggle",
                default = true
            },
            suggestionDetail = {
                displayName = "Suggestion Detail Level",
                description = "Level of detail for improvement suggestions",
                type = "dropdown",
                options = { "basic", "detailed", "comprehensive" },
                default = "detailed"
            },
            focusAreas = {
                displayName = "Suggestion Focus Areas",
                description = "Areas to focus on for improvement suggestions",
                type = "multiselect",
                options = { "rotation", "cooldown_usage", "resource_management", "aoe_optimization", "survivability" },
                default = { "rotation", "cooldown_usage", "resource_management" }
            }
        },
        debugSettings = {
            enableDebugMode = {
                displayName = "Enable Debug Mode",
                description = "Enable detailed debug logging",
                type = "toggle",
                default = false
            },
            logCombatEvents = {
                displayName = "Log Combat Events",
                description = "Log detailed combat events for debugging",
                type = "toggle",
                default = false
            },
            exportAnalysisData = {
                displayName = "Export Analysis Data",
                description = "Enable exporting of analysis data",
                type = "toggle",
                default = false
            }
        }
    })
end

-- Setup event tracking
function CombatAnalysis:SetupEventTracking()
    -- Register for combat log events
    API.RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", function()
        self:ProcessCombatLogEvent(CombatLogGetCurrentEventInfo())
    end)
    
    -- Register for combat state changes
    API.RegisterEvent("PLAYER_REGEN_DISABLED", function()
        self:StartCombatTracking()
    end)
    
    API.RegisterEvent("PLAYER_REGEN_ENABLED", function()
        self:EndCombatTracking()
    end)
    
    -- Register for spec changes
    API.RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", function()
        self:ResetCurrentAnalysis()
    end)
    
    -- Register for spell cast events
    API.RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", function(unit, _, spellID)
        if unit == "player" then
            self:TrackSpellCast(spellID)
        end
    end)
    
    -- Register for resource change events
    API.RegisterEvent("UNIT_POWER_UPDATE", function(unit, powerType)
        if unit == "player" then
            self:TrackResourceChange(powerType)
        end
    end)
}

-- Initialize report templates
function CombatAnalysis:InitializeReportTemplates()
    -- These would be templates for different types of reports
    -- For implementation simplicity, we'll just use placeholders
}

-- Start combat tracking
function CombatAnalysis:StartCombatTracking()
    local settings = ConfigRegistry:GetSettings("CombatAnalysis")
    if not settings.generalSettings.enableAnalysis then
        return
    end
    
    -- Generate a new combat ID
    combatID = combatID + 1
    
    -- Initialize combat log
    currentCombatLog = {
        id = combatID,
        startTime = GetTime(),
        endTime = nil,
        events = {},
        spellCasts = {},
        damage = {
            total = 0,
            bySpell = {},
            byTarget = {}
        },
        healing = {
            total = 0,
            bySpell = {},
            byTarget = {}
        },
        resources = {
            generated = {},
            spent = {}
        },
        targets = {},
        player = {
            class = API.GetPlayerClass(),
            spec = API.GetActiveSpecID(),
            level = API.GetPlayerLevel()
        }
    }
    
    -- Initialize real-time tracking
    if settings.realtimeSettings.enableRealtimeAnalysis then
        self:StartRealtimeTracking()
    end
    
    API.PrintDebug("Combat tracking started: ID " .. combatID)
}

-- End combat tracking
function CombatAnalysis:EndCombatTracking()
    if not currentCombatLog then
        return
    end
    
    -- Finalize combat log
    currentCombatLog.endTime = GetTime()
    currentCombatLog.duration = currentCombatLog.endTime - currentCombatLog.startTime
    
    -- Analyze combat if it was long enough
    local settings = ConfigRegistry:GetSettings("CombatAnalysis")
    if currentCombatLog.duration >= settings.generalSettings.minCombatDuration then
        -- Store the log
        table.insert(combatLogs, currentCombatLog)
        
        -- Trim logs if needed
        if #combatLogs > MAX_COMBAT_LOGS then
            table.remove(combatLogs, 1)
        end
        
        -- Generate report if automated
        if settings.generalSettings.automaticReporting == "all_combat" or
           (settings.generalSettings.automaticReporting == "major_combat" and 
            currentCombatLog.duration >= 30) then
            self:GenerateCombatReport(currentCombatLog.id)
        end
        
        -- Add to combat history
        local historySummary = self:GenerateHistorySummary(currentCombatLog)
        table.insert(combatHistory, historySummary)
        
        -- Trim history if needed
        if #combatHistory > MAX_HISTORY_ENTRIES then
            table.remove(combatHistory, 1)
        end
        
        API.PrintDebug("Combat analyzed: " .. string.format("%.1f", currentCombatLog.duration) .. " seconds")
    end
    
    -- Stop real-time tracking
    self:StopRealtimeTracking()
    
    -- Clear current log
    currentCombatLog = nil
}

-- Process a combat log event
function CombatAnalysis:ProcessCombatLogEvent(...)
    if not currentCombatLog then
        return
    end
    
    local settings = ConfigRegistry:GetSettings("CombatAnalysis")
    if not settings.generalSettings.enableAnalysis then
        return
    end
    
    -- Extract event data
    local timestamp, event, _, sourceGUID, sourceName, sourceFlags, _, destGUID, destName, destFlags, _, spellID, spellName, _, amount = ...
    
    -- Only process events from the player
    local playerGUID = UnitGUID("player")
    if sourceGUID ~= playerGUID then
        return
    end
    
    -- Add to combat log events if debug is enabled
    if settings.debugSettings.logCombatEvents then
        table.insert(currentCombatLog.events, {
            timestamp = timestamp,
            event = event,
            spellID = spellID,
            spellName = spellName,
            destName = destName,
            amount = amount
        })
    end
    
    -- Process specific events
    if event == "SPELL_DAMAGE" or event == "RANGE_DAMAGE" or event == "SPELL_PERIODIC_DAMAGE" then
        self:ProcessDamageEvent(timestamp, spellID, spellName, destGUID, destName, amount)
    elseif event == "SPELL_HEAL" or event == "SPELL_PERIODIC_HEAL" then
        self:ProcessHealEvent(timestamp, spellID, spellName, destGUID, destName, amount)
    elseif event == "SPELL_CAST_SUCCESS" then
        self:ProcessSpellCastEvent(timestamp, spellID, spellName)
    end
end

-- Process a damage event
function CombatAnalysis:ProcessDamageEvent(timestamp, spellID, spellName, destGUID, destName, amount)
    if not currentCombatLog or not amount or amount <= 0 then
        return
    end
    
    -- Update total damage
    currentCombatLog.damage.total = currentCombatLog.damage.total + amount
    
    -- Update damage by spell
    if not currentCombatLog.damage.bySpell[spellID] then
        currentCombatLog.damage.bySpell[spellID] = {
            name = spellName,
            total = amount,
            hits = 1,
            crits = 0,
            min = amount,
            max = amount
        }
    else
        local spellData = currentCombatLog.damage.bySpell[spellID]
        spellData.total = spellData.total + amount
        spellData.hits = spellData.hits + 1
        spellData.min = math.min(spellData.min, amount)
        spellData.max = math.max(spellData.max, amount)
    end
    
    -- Update damage by target
    if not currentCombatLog.damage.byTarget[destGUID] then
        currentCombatLog.damage.byTarget[destGUID] = {
            name = destName,
            total = amount,
            hits = 1
        }
    else
        local targetData = currentCombatLog.damage.byTarget[destGUID]
        targetData.total = targetData.total + amount
        targetData.hits = targetData.hits + 1
    end
    
    -- Update targets
    if not currentCombatLog.targets[destGUID] then
        currentCombatLog.targets[destGUID] = {
            name = destName,
            firstSeen = timestamp,
            lastSeen = timestamp,
            damageTaken = amount
        }
    else
        local target = currentCombatLog.targets[destGUID]
        target.lastSeen = timestamp
        target.damageTaken = (target.damageTaken or 0) + amount
    end
    
    -- Update spell analysis
    self:UpdateSpellAnalysis(spellID, "damage", amount)
    
    -- Update real-time metrics
    self:UpdateRealtimeMetrics("damage", amount, spellID)
}

-- Process a heal event
function CombatAnalysis:ProcessHealEvent(timestamp, spellID, spellName, destGUID, destName, amount)
    if not currentCombatLog or not amount or amount <= 0 then
        return
    end
    
    -- Update total healing
    currentCombatLog.healing.total = currentCombatLog.healing.total + amount
    
    -- Update healing by spell
    if not currentCombatLog.healing.bySpell[spellID] then
        currentCombatLog.healing.bySpell[spellID] = {
            name = spellName,
            total = amount,
            hits = 1,
            crits = 0,
            min = amount,
            max = amount
        }
    else
        local spellData = currentCombatLog.healing.bySpell[spellID]
        spellData.total = spellData.total + amount
        spellData.hits = spellData.hits + 1
        spellData.min = math.min(spellData.min, amount)
        spellData.max = math.max(spellData.max, amount)
    end
    
    -- Update healing by target
    if not currentCombatLog.healing.byTarget[destGUID] then
        currentCombatLog.healing.byTarget[destGUID] = {
            name = destName,
            total = amount,
            hits = 1
        }
    else
        local targetData = currentCombatLog.healing.byTarget[destGUID]
        targetData.total = targetData.total + amount
        targetData.hits = targetData.hits + 1
    end
    
    -- Update spell analysis
    self:UpdateSpellAnalysis(spellID, "healing", amount)
    
    -- Update real-time metrics
    self:UpdateRealtimeMetrics("healing", amount, spellID)
}

-- Process a spell cast event
function CombatAnalysis:ProcessSpellCastEvent(timestamp, spellID, spellName)
    if not currentCombatLog then
        return
    end
    
    -- Add to spell casts
    table.insert(currentCombatLog.spellCasts, {
        timestamp = timestamp,
        spellID = spellID,
        spellName = spellName
    })
    
    -- Check for rotation patterns
    self:AnalyzeRotationPattern(spellID, timestamp)
    
    -- Track resource usage
    self:TrackResourceUsageForSpell(spellID)
}

-- Track a spell cast (separate from combat log events)
function CombatAnalysis:TrackSpellCast(spellID)
    if not currentCombatLog then
        return
    end
    
    local spellName = GetSpellInfo(spellID)
    local timestamp = GetTime()
    
    -- Update real-time metrics
    self:UpdateRealtimeMetrics("cast", 1, spellID)
    
    -- Check for rotation patterns
    self:AnalyzeRotationPattern(spellID, timestamp)
}

-- Track resource changes
function CombatAnalysis:TrackResourceChange(powerType)
    if not currentCombatLog then
        return
    end
    
    -- Track changes in resources
    local resourceAmount = UnitPower("player", powerType)
    local maxResource = UnitPowerMax("player", powerType)
    
    -- Update real-time metrics
    self:UpdateRealtimeMetrics("resource", {
        type = powerType,
        current = resourceAmount,
        max = maxResource
    })
}

-- Track resource usage for a spell
function CombatAnalysis:TrackResourceUsageForSpell(spellID)
    if not currentCombatLog then
        return
    end
    
    -- This would track resource usage for specific spells
    -- For implementation simplicity, we'll use a placeholder
    
    -- Get the cost of the spell
    local resourceType, cost = self:GetSpellResourceCost(spellID)
    
    if resourceType and cost and cost > 0 then
        -- Track resource spent
        if not currentCombatLog.resources.spent[resourceType] then
            currentCombatLog.resources.spent[resourceType] = 0
        end
        
        currentCombatLog.resources.spent[resourceType] = currentCombatLog.resources.spent[resourceType] + cost
        
        -- Update resource usage metrics
        self:UpdateResourceUsage(spellID, resourceType, cost)
    end
}

-- Get resource cost for a spell
function CombatAnalysis:GetSpellResourceCost(spellID)
    -- This would retrieve the resource cost of a spell
    -- In a real implementation, this would use the WoW API
    -- For simplicity, we'll use placeholders
    
    local classID = API.GetPlayerClassID()
    local specID = API.GetActiveSpecID()
    
    if not classID or not specID then
        return nil, 0
    end
    
    -- Mock resource costs based on class/spec
    if classID == 1 then -- Warrior
        return "rage", math.random(10, 30)
    elseif classID == 2 then -- Paladin
        if specID == 3 then -- Retribution
            return "holypower", math.random(1, 3)
        else
            return "mana", math.random(300, 1000)
        end
    elseif classID == 3 then -- Hunter
        return "focus", math.random(15, 50)
    elseif classID == 4 then -- Rogue
        return "energy", math.random(20, 60)
    elseif classID == 5 then -- Priest
        return "mana", math.random(400, 1200)
    elseif classID == 6 then -- Death Knight
        return "runicpower", math.random(10, 45)
    elseif classID == 7 then -- Shaman
        return "mana", math.random(300, 1100)
    elseif classID == 8 then -- Mage
        return "mana", math.random(500, 1500)
    elseif classID == 9 then -- Warlock
        return "mana", math.random(400, 1200)
    elseif classID == 10 then -- Monk
        if specID == 1 or specID == 2 then -- Windwalker or Mistweaver
            return "energy", math.random(25, 65)
        else -- Brewmaster
            return "energy", math.random(20, 50)
        end
    elseif classID == 11 then -- Druid
        if specID == 1 then -- Balance
            return "astralpower", math.random(30, 80)
        elseif specID == 2 then -- Feral
            return "energy", math.random(25, 60)
        elseif specID == 3 then -- Guardian
            return "rage", math.random(10, 40)
        else -- Restoration
            return "mana", math.random(300, 1000)
        end
    elseif classID == 12 then -- Demon Hunter
        return "fury", math.random(30, 80)
    elseif classID == 13 then -- Evoker
        return "essence", math.random(1, 3)
    end
    
    return nil, 0
}

-- Update spell analysis metrics
function CombatAnalysis:UpdateSpellAnalysis(spellID, actionType, amount)
    local timestamp = GetTime()
    
    if not spellAnalysis[spellID] then
        spellAnalysis[spellID] = {
            damage = {
                total = 0,
                hits = 0,
                min = nil,
                max = nil,
                lastHit = 0
            },
            healing = {
                total = 0,
                hits = 0,
                min = nil,
                max = nil,
                lastHit = 0
            },
            casts = 0,
            lastCast = 0,
            effectiveness = 0,
            resourceEfficiency = 0
        }
    end
    
    local analysis = spellAnalysis[spellID]
    
    if actionType == "damage" then
        analysis.damage.total = analysis.damage.total + amount
        analysis.damage.hits = analysis.damage.hits + 1
        analysis.damage.min = analysis.damage.min and math.min(analysis.damage.min, amount) or amount
        analysis.damage.max = analysis.damage.max and math.max(analysis.damage.max, amount) or amount
        analysis.damage.lastHit = timestamp
        
        -- Update effectiveness (damage per cast)
        if analysis.casts > 0 then
            analysis.effectiveness = analysis.damage.total / analysis.casts
        end
    elseif actionType == "healing" then
        analysis.healing.total = analysis.healing.total + amount
        analysis.healing.hits = analysis.healing.hits + 1
        analysis.healing.min = analysis.healing.min and math.min(analysis.healing.min, amount) or amount
        analysis.healing.max = analysis.healing.max and math.max(analysis.healing.max, amount) or amount
        analysis.healing.lastHit = timestamp
        
        -- Update effectiveness (healing per cast)
        if analysis.casts > 0 then
            analysis.effectiveness = analysis.healing.total / analysis.casts
        end
    elseif actionType == "cast" then
        analysis.casts = analysis.casts + 1
        analysis.lastCast = timestamp
    end
}

-- Update resource usage metrics
function CombatAnalysis:UpdateResourceUsage(spellID, resourceType, cost)
    if not resourceUsage[spellID] then
        resourceUsage[spellID] = {
            resourceType = resourceType,
            totalSpent = 0,
            casts = 0,
            generated = 0,
            efficiency = 0
        }
    end
    
    local usage = resourceUsage[spellID]
    
    -- Update resource spent
    usage.totalSpent = usage.totalSpent + cost
    usage.casts = usage.casts + 1
    
    -- Calculate efficiency (damage or healing per resource)
    local totalEffect = 0
    if spellAnalysis[spellID] then
        totalEffect = spellAnalysis[spellID].damage.total + spellAnalysis[spellID].healing.total
    end
    
    if usage.totalSpent > 0 then
        usage.efficiency = totalEffect / usage.totalSpent
    end
    
    -- Update spell analysis
    if spellAnalysis[spellID] then
        spellAnalysis[spellID].resourceEfficiency = usage.efficiency
    end
}

-- Analyze rotation pattern
function CombatAnalysis:AnalyzeRotationPattern(spellID, timestamp)
    if not currentCombatLog then
        return
    end
    
    -- Initialize rotation efficiency if needed
    if not rotationEfficiency.lastSpell then
        rotationEfficiency = {
            lastSpell = spellID,
            lastTimestamp = timestamp,
            sequences = {},
            optimalSequences = {},
            currentSequence = {},
            sequenceEfficiency = 0
        }
        
        table.insert(rotationEfficiency.currentSequence, spellID)
        return
    end
    
    -- Check time between casts
    local timeDiff = timestamp - rotationEfficiency.lastTimestamp
    
    -- If too much time passed, this is a new sequence
    if timeDiff > 5 then
        rotationEfficiency.currentSequence = {}
    end
    
    -- Add to current sequence
    table.insert(rotationEfficiency.currentSequence, spellID)
    
    -- Check for known sequences
    local previousSpell = rotationEfficiency.lastSpell
    local sequence = previousSpell .. "-" .. spellID
    
    if not rotationEfficiency.sequences[sequence] then
        rotationEfficiency.sequences[sequence] = {
            count = 1,
            totalDamage = 0,
            totalHealing = 0,
            avgTimeDiff = timeDiff
        }
    else
        local seq = rotationEfficiency.sequences[sequence]
        seq.count = seq.count + 1
        seq.avgTimeDiff = ((seq.avgTimeDiff * (seq.count - 1)) + timeDiff) / seq.count
    end
    
    -- Update optimal sequences from machine learning if available
    if WR.MachineLearning and WR.MachineLearning.GetOptimalSequences then
        rotationEfficiency.optimalSequences = WR.MachineLearning:GetOptimalSequences() or {}
    end
    
    -- Calculate sequence efficiency
    self:CalculateSequenceEfficiency()
    
    -- Update last spell
    rotationEfficiency.lastSpell = spellID
    rotationEfficiency.lastTimestamp = timestamp
}

-- Calculate sequence efficiency
function CombatAnalysis:CalculateSequenceEfficiency()
    if not rotationEfficiency.optimalSequences or not rotationEfficiency.sequences then
        return
    end
    
    -- Calculate how well the player's sequences match optimal ones
    local totalSequences = 0
    local matchingSequences = 0
    
    for sequence, data in pairs(rotationEfficiency.sequences) do
        totalSequences = totalSequences + data.count
        
        -- Check if this is an optimal sequence
        if rotationEfficiency.optimalSequences[sequence] then
            matchingSequences = matchingSequences + data.count
        end
    end
    
    -- Calculate efficiency percentage
    if totalSequences > 0 then
        rotationEfficiency.sequenceEfficiency = (matchingSequences / totalSequences) * 100
    else
        rotationEfficiency.sequenceEfficiency = 0
    end
}

-- Start real-time tracking
function CombatAnalysis:StartRealtimeTracking()
    -- Initialize real-time metrics
    realtimeMetrics = {
        damage = {
            total = 0,
            lastUpdate = GetTime(),
            dps = 0,
            window = {}
        },
        healing = {
            total = 0,
            lastUpdate = GetTime(),
            hps = 0,
            window = {}
        },
        resources = {
            spent = {},
            efficiency = 0
        },
        rotation = {
            efficiency = 0,
            optimalCasts = 0,
            totalCasts = 0
        },
        updateInterval = METRICS_UPDATE_INTERVAL,
        lastUpdateTime = GetTime()
    }
    
    -- Start update timer
    C_Timer.NewTicker(METRICS_UPDATE_INTERVAL, function()
        self:UpdateRealtimeMetrics("tick")
    end)
}

-- Stop real-time tracking
function CombatAnalysis:StopRealtimeTracking()
    -- This would stop any active timers
    -- In a real implementation, we'd cancel the ticker
    
    -- Clear real-time metrics
    realtimeMetrics = {}
}

-- Update real-time metrics
function CombatAnalysis:UpdateRealtimeMetrics(metricType, value, spellID)
    if not realtimeMetrics then
        return
    end
    
    local now = GetTime()
    
    -- Update based on metric type
    if metricType == "damage" then
        -- Add to total damage
        realtimeMetrics.damage.total = realtimeMetrics.damage.total + value
        
        -- Add to damage window (last 5 seconds)
        table.insert(realtimeMetrics.damage.window, {
            timestamp = now,
            amount = value
        })
        
        -- Trim window
        self:TrimMetricWindow(realtimeMetrics.damage.window, now - 5)
    elseif metricType == "healing" then
        -- Add to total healing
        realtimeMetrics.healing.total = realtimeMetrics.healing.total + value
        
        -- Add to healing window (last 5 seconds)
        table.insert(realtimeMetrics.healing.window, {
            timestamp = now,
            amount = value
        })
        
        -- Trim window
        self:TrimMetricWindow(realtimeMetrics.healing.window, now - 5)
    elseif metricType == "resource" then
        -- Update resource tracking
        local resourceType = value.type
        local current = value.current
        local max = value.max
        
        realtimeMetrics.resources[resourceType] = {
            current = current,
            max = max,
            percent = (current / max) * 100
        }
    elseif metricType == "cast" then
        -- Update cast counts
        realtimeMetrics.rotation.totalCasts = realtimeMetrics.rotation.totalCasts + 1
        
        -- Check if this is an optimal cast based on ML recommendation
        if WR.MachineLearning and WR.MachineLearning.IsOptimalCast then
            if WR.MachineLearning:IsOptimalCast(spellID) then
                realtimeMetrics.rotation.optimalCasts = realtimeMetrics.rotation.optimalCasts + 1
            end
        end
        
        -- Update rotation efficiency
        if realtimeMetrics.rotation.totalCasts > 0 then
            realtimeMetrics.rotation.efficiency = (realtimeMetrics.rotation.optimalCasts / realtimeMetrics.rotation.totalCasts) * 100
        end
    elseif metricType == "tick" then
        -- Calculate DPS
        if #realtimeMetrics.damage.window > 0 then
            local windowDamage = 0
            local oldestTimestamp = now
            
            for _, entry in ipairs(realtimeMetrics.damage.window) do
                windowDamage = windowDamage + entry.amount
                oldestTimestamp = math.min(oldestTimestamp, entry.timestamp)
            end
            
            local windowDuration = now - oldestTimestamp
            if windowDuration > 0 then
                realtimeMetrics.damage.dps = windowDamage / windowDuration
            end
        else
            -- No recent damage, use combat duration
            local combatDuration = now - currentCombatLog.startTime
            if combatDuration > 0 then
                realtimeMetrics.damage.dps = realtimeMetrics.damage.total / combatDuration
            end
        end
        
        -- Calculate HPS
        if #realtimeMetrics.healing.window > 0 then
            local windowHealing = 0
            local oldestTimestamp = now
            
            for _, entry in ipairs(realtimeMetrics.healing.window) do
                windowHealing = windowHealing + entry.amount
                oldestTimestamp = math.min(oldestTimestamp, entry.timestamp)
            end
            
            local windowDuration = now - oldestTimestamp
            if windowDuration > 0 then
                realtimeMetrics.healing.hps = windowHealing / windowDuration
            end
        else
            -- No recent healing, use combat duration
            local combatDuration = now - currentCombatLog.startTime
            if combatDuration > 0 then
                realtimeMetrics.healing.hps = realtimeMetrics.healing.total / combatDuration
            end
        end
        
        -- Update resource efficiency
        self:CalculateResourceEfficiency()
        
        -- Update last update time
        realtimeMetrics.lastUpdateTime = now
    end
}

-- Trim metric window
function CombatAnalysis:TrimMetricWindow(window, cutoffTime)
    local i = 1
    while i <= #window do
        if window[i].timestamp < cutoffTime then
            table.remove(window, i)
        else
            i = i + 1
        end
    end
end

-- Calculate resource efficiency
function CombatAnalysis:CalculateResourceEfficiency()
    if not realtimeMetrics or not currentCombatLog then
        return
    end
    
    -- Calculate damage/healing per resource spent
    local totalEffect = realtimeMetrics.damage.total + realtimeMetrics.healing.total
    local totalResourceSpent = 0
    
    for resourceType, amount in pairs(currentCombatLog.resources.spent) do
        totalResourceSpent = totalResourceSpent + amount
    end
    
    if totalResourceSpent > 0 then
        realtimeMetrics.resources.efficiency = totalEffect / totalResourceSpent
    end
}

-- Generate a combat report
function CombatAnalysis:GenerateCombatReport(combatID)
    local log = self:GetCombatLogByID(combatID)
    if not log then
        API.Print("Combat log not found: " .. combatID)
        return
    end
    
    local settings = ConfigRegistry:GetSettings("CombatAnalysis")
    
    -- Create report structure
    local report = {
        id = "report_" .. combatID,
        timestamp = GetTime(),
        combatID = combatID,
        duration = log.duration,
        player = log.player,
        summary = {},
        details = {},
        analysis = {},
        suggestions = {}
    }
    
    -- Generate summary
    report.summary = self:GenerateReportSummary(log)
    
    -- Add detailed sections based on settings
    if settings.reportSettings.includeDamageAnalysis then
        report.details.damage = self:GenerateDamageAnalysis(log)
    end
    
    if settings.reportSettings.includeRotationAnalysis then
        report.details.rotation = self:GenerateRotationAnalysis(log)
    end
    
    if settings.reportSettings.includeResourceAnalysis then
        report.details.resources = self:GenerateResourceAnalysis(log)
    end
    
    -- Generate analysis
    report.analysis = self:GeneratePerformanceAnalysis(log)
    
    -- Generate suggestions
    if settings.reportSettings.includeImprovementSuggestions then
        report.suggestions = self:GenerateImprovementSuggestions(log, report.analysis)
    end
    
    -- Store the report
    analysisReports[report.id] = report
    
    -- Print report based on format
    self:PrintCombatReport(report, settings.reportSettings.reportFormat)
    
    return report.id
}

-- Generate report summary
function CombatAnalysis:GenerateReportSummary(log)
    if not log then
        return {}
    end
    
    -- Calculate key metrics
    local dps = log.damage.total / math.max(log.duration, 1)
    local hps = log.healing.total / math.max(log.duration, 1)
    
    -- Get target count
    local targetCount = 0
    for _ in pairs(log.targets) do
        targetCount = targetCount + 1
    end
    
    -- Calculate APM (actions per minute)
    local apm = (#log.spellCasts / log.duration) * 60
    
    -- Return summary
    return {
        dps = dps,
        hps = hps,
        targetCount = targetCount,
        damageTotal = log.damage.total,
        healingTotal = log.healing.total,
        spellCastCount = #log.spellCasts,
        apm = apm
    }
}

-- Generate damage analysis
function CombatAnalysis:GenerateDamageAnalysis(log)
    if not log then
        return {}
    end
    
    -- Sort spells by damage
    local spellList = {}
    for spellID, data in pairs(log.damage.bySpell) do
        table.insert(spellList, {
            id = spellID,
            name = data.name,
            total = data.total,
            hits = data.hits,
            min = data.min,
            max = data.max,
            avg = data.total / data.hits,
            dps = data.total / log.duration,
            percent = (data.total / log.damage.total) * 100
        })
    end
    
    -- Sort by total damage
    table.sort(spellList, function(a, b) return a.total > b.total end)
    
    -- Sort targets by damage
    local targetList = {}
    for targetGUID, data in pairs(log.damage.byTarget) do
        table.insert(targetList, {
            guid = targetGUID,
            name = data.name,
            total = data.total,
            percent = (data.total / log.damage.total) * 100
        })
    end
    
    -- Sort by total damage
    table.sort(targetList, function(a, b) return a.total > b.total end)
    
    -- Return analysis
    return {
        totalDamage = log.damage.total,
        dps = log.damage.total / log.duration,
        bySpell = spellList,
        byTarget = targetList,
        highestHit = self:FindHighestHit(log.damage.bySpell)
    }
}

-- Generate rotation analysis
function CombatAnalysis:GenerateRotationAnalysis(log)
    if not log then
        return {}
    end
    
    -- Analyze spell cast sequence
    local sequences = {}
    local lastSpell = nil
    local lastTimestamp = nil
    
    for i, cast in ipairs(log.spellCasts) do
        if lastSpell and lastTimestamp then
            local timeDiff = cast.timestamp - lastTimestamp
            local sequence = lastSpell .. "-" .. cast.spellID
            
            if not sequences[sequence] then
                sequences[sequence] = {
                    count = 1,
                    avgTimeDiff = timeDiff
                }
            else
                sequences[sequence].count = sequences[sequence].count + 1
                sequences[sequence].avgTimeDiff = ((sequences[sequence].avgTimeDiff * (sequences[sequence].count - 1)) + timeDiff) / sequences[sequence].count
            end
        end
        
        lastSpell = cast.spellID
        lastTimestamp = cast.timestamp
    end
    
    -- Sort sequences by count
    local sortedSequences = {}
    for sequence, data in pairs(sequences) do
        table.insert(sortedSequences, {
            sequence = sequence,
            count = data.count,
            avgTimeDiff = data.avgTimeDiff
        })
    end
    
    table.sort(sortedSequences, function(a, b) return a.count > b.count end)
    
    -- Calculate cooldown usage
    local cooldownUsage = self:AnalyzeCooldownUsage(log)
    
    -- Calculate rotation efficiency
    local efficiency = self:CalculateRotationEfficiency(log, sequences)
    
    -- Return analysis
    return {
        castCount = #log.spellCasts,
        apm = (#log.spellCasts / log.duration) * 60,
        commonSequences = sortedSequences,
        cooldownUsage = cooldownUsage,
        efficiency = efficiency
    }
}

-- Generate resource analysis
function CombatAnalysis:GenerateResourceAnalysis(log)
    if not log then
        return {}
    end
    
    -- Calculate resource metrics
    local resourceMetrics = {}
    
    for resourceType, amount in pairs(log.resources.spent) do
        resourceMetrics[resourceType] = {
            spent = amount,
            perSecond = amount / log.duration
        }
        
        -- Calculate efficiency (damage/healing per resource)
        if amount > 0 then
            resourceMetrics[resourceType].efficiency = (log.damage.total + log.healing.total) / amount
        else
            resourceMetrics[resourceType].efficiency = 0
        end
    end
    
    -- Analyze resource usage by spell
    local spellResourceUsage = {}
    
    for spellID, usage in pairs(resourceUsage) do
        if usage.casts > 0 then
            spellResourceUsage[spellID] = {
                resourceType = usage.resourceType,
                totalSpent = usage.totalSpent,
                perCast = usage.totalSpent / usage.casts,
                efficiency = usage.efficiency
            }
        end
    end
    
    -- Return analysis
    return {
        byResource = resourceMetrics,
        bySpell = spellResourceUsage,
        overallEfficiency = self:CalculateOverallResourceEfficiency(log)
    }
}

-- Generate performance analysis
function CombatAnalysis:GeneratePerformanceAnalysis(log)
    if not log then
        return {}
    end
    
    -- Compare with reference data if available
    local referenceData = self:GetReferenceData(log.player.class, log.player.spec)
    
    -- Calculate performance percentiles
    local dpsPercentile = self:CalculatePercentile(log.damage.total / log.duration, referenceData.dps)
    local rotationPercentile = self:CalculatePercentile(self:CalculateRotationEfficiency(log), referenceData.rotationEfficiency)
    local resourcePercentile = self:CalculatePercentile(self:CalculateOverallResourceEfficiency(log), referenceData.resourceEfficiency)
    
    -- Calculate overall performance score
    local overallScore = (dpsPercentile + rotationPercentile + resourcePercentile) / 3
    
    -- Identify strengths and weaknesses
    local strengths = {}
    local weaknesses = {}
    
    if dpsPercentile >= 75 then
        table.insert(strengths, "damage_output")
    elseif dpsPercentile <= 25 then
        table.insert(weaknesses, "damage_output")
    end
    
    if rotationPercentile >= 75 then
        table.insert(strengths, "rotation_execution")
    elseif rotationPercentile <= 25 then
        table.insert(weaknesses, "rotation_execution")
    end
    
    if resourcePercentile >= 75 then
        table.insert(strengths, "resource_management")
    elseif resourcePercentile <= 25 then
        table.insert(weaknesses, "resource_management")
    end
    
    -- Return analysis
    return {
        overallScore = overallScore,
        percentiles = {
            dps = dpsPercentile,
            rotation = rotationPercentile,
            resource = resourcePercentile
        },
        strengths = strengths,
        weaknesses = weaknesses,
        comparedTo = referenceData.source or "baseline"
    }
}

-- Generate improvement suggestions
function CombatAnalysis:GenerateImprovementSuggestions(log, analysis)
    if not log or not analysis then
        return {}
    end
    
    local suggestions = {}
    
    -- Generate suggestions based on analysis
    if analysis.weaknesses then
        for _, weakness in ipairs(analysis.weaknesses) do
            if weakness == "damage_output" then
                table.insert(suggestions, self:GenerateDamageSuggestion(log))
            elseif weakness == "rotation_execution" then
                table.insert(suggestions, self:GenerateRotationSuggestion(log))
            elseif weakness == "resource_management" then
                table.insert(suggestions, self:GenerateResourceSuggestion(log))
            end
        end
    end
    
    -- Add spell-specific suggestions
    local spellSuggestions = self:GenerateSpellSuggestions(log)
    for _, suggestion in ipairs(spellSuggestions) do
        table.insert(suggestions, suggestion)
    end
    
    -- Add cooldown suggestions
    local cooldownSuggestions = self:GenerateCooldownSuggestions(log)
    for _, suggestion in ipairs(cooldownSuggestions) do
        table.insert(suggestions, suggestion)
    end
    
    return suggestions
}

-- Generate damage improvement suggestion
function CombatAnalysis:GenerateDamageSuggestion(log)
    -- Find underperforming spells
    local underperformingSpells = {}
    local totalDamage = log.damage.total
    
    for spellID, data in pairs(log.damage.bySpell) do
        local spellPercent = (data.total / totalDamage) * 100
        
        -- Check reference data for expected contribution
        local expectedPercent = self:GetExpectedSpellContribution(spellID)
        
        if expectedPercent and spellPercent < expectedPercent * 0.7 then
            table.insert(underperformingSpells, {
                id = spellID,
                name = data.name,
                actual = spellPercent,
                expected = expectedPercent
            })
        end
    end
    
    -- Sort by biggest difference
    table.sort(underperformingSpells, function(a, b)
        return (a.expected - a.actual) > (b.expected - b.actual)
    end)
    
    -- Generate suggestion
    if #underperformingSpells > 0 then
        local spell = underperformingSpells[1]
        
        return {
            category = "damage_output",
            title = "Increase " .. spell.name .. " Usage",
            description = spell.name .. " is providing less damage than expected (" .. 
                          string.format("%.1f", spell.actual) .. "% vs expected " .. 
                          string.format("%.1f", spell.expected) .. "%). Try to prioritize this ability in your rotation.",
            priority = "high"
        }
    else
        -- Generic suggestion
        return {
            category = "damage_output",
            title = "Optimize Damage Rotation",
            description = "Your overall damage output is lower than expected. Focus on maintaining proper ability priority and ensuring you're using your highest damage abilities on cooldown.",
            priority = "medium"
        }
    end
end

-- Generate rotation improvement suggestion
function CombatAnalysis:GenerateRotationSuggestion(log)
    -- Analyze actual vs optimal rotation
    local optimalSequences = WR.MachineLearning and WR.MachineLearning.GetOptimalSequences and WR.MachineLearning:GetOptimalSequences() or {}
    
    -- Find missing optimal sequences
    local missingSequences = {}
    
    for sequence, weight in pairs(optimalSequences) do
        local found = false
        
        for i = 1, #log.spellCasts - 1 do
            local testSequence = log.spellCasts[i].spellID .. "-" .. log.spellCasts[i+1].spellID
            if testSequence == sequence then
                found = true
                break
            end
        end
        
        if not found and weight > 0.7 then -- Only suggest high-weight sequences
            table.insert(missingSequences, {
                sequence = sequence,
                weight = weight
            })
        end
    end
    
    -- Sort by weight
    table.sort(missingSequences, function(a, b) return a.weight > b.weight end)
    
    -- Generate suggestion
    if #missingSequences > 0 then
        local sequence = missingSequences[1]
        local spellIDs = {}
        for id in string.gmatch(sequence.sequence, "(%d+)") do
            table.insert(spellIDs, tonumber(id))
        end
        
        local spell1Name = GetSpellInfo(spellIDs[1]) or "Ability 1"
        local spell2Name = GetSpellInfo(spellIDs[2]) or "Ability 2"
        
        return {
            category = "rotation_execution",
            title = "Optimize Ability Sequence",
            description = "Try using " .. spell1Name .. " followed by " .. spell2Name .. " more frequently. This sequence is highly effective but was missing from your rotation.",
            priority = "high"
        }
    else
        -- Check for APM issues
        local apm = (#log.spellCasts / log.duration) * 60
        local expectedAPM = self:GetExpectedAPM()
        
        if apm < expectedAPM * 0.8 then
            return {
                category = "rotation_execution",
                title = "Increase Action Speed",
                description = "Your actions per minute (" .. string.format("%.1f", apm) .. ") are lower than expected (" .. string.format("%.1f", expectedAPM) .. "). Try to reduce downtime between ability casts.",
                priority = "medium"
            }
        else
            -- Generic suggestion
            return {
                category = "rotation_execution",
                title = "Refine Rotation Execution",
                description = "Your rotation could be optimized. Focus on maintaining the proper priority of abilities and minimizing gaps between casts.",
                priority = "medium"
            }
        end
    end
end

-- Generate resource improvement suggestion
function CombatAnalysis:GenerateResourceSuggestion(log)
    -- Check for resource capping
    local resourceCapping = self:DetectResourceCapping(log)
    
    if resourceCapping.detected then
        return {
            category = "resource_management",
            title = "Avoid " .. resourceCapping.resourceName .. " Capping",
            description = "You're frequently reaching maximum " .. resourceCapping.resourceName .. ". Try to use more " .. resourceCapping.resourceName .. " spenders when approaching the cap to avoid wasting resources.",
            priority = "high"
        }
    end
    
    -- Check for inefficient resource usage
    local inefficientSpells = self:FindIneffientResourceSpells(log)
    
    if #inefficientSpells > 0 then
        local spell = inefficientSpells[1]
        
        return {
            category = "resource_management",
            title = "Optimize " .. spell.name .. " Usage",
            description = spell.name .. " is using a high amount of " .. spell.resourceType .. " for its effect. Consider using it more strategically or prioritizing more efficient abilities.",
            priority = "medium"
        }
    else
        -- Generic suggestion
        return {
            category = "resource_management",
            title = "Improve Resource Management",
            description = "Your resource usage could be more efficient. Focus on using resource generators effectively and avoid wasting resources.",
            priority = "medium"
        }
    end
end

-- Generate spell-specific suggestions
function CombatAnalysis:GenerateSpellSuggestions(log)
    local suggestions = {}
    
    -- Analyze spell usage patterns
    for spellID, data in pairs(spellAnalysis) do
        -- Skip if no meaningful data
        if data.casts == 0 then
            goto continue
        end
        
        local spellName = GetSpellInfo(spellID) or "Unknown Spell"
        
        -- Check for missed targets with AoE spells
        if self:IsAoESpell(spellID) and log.targets and #log.targets > 1 then
            local avgTargetsHit = data.damage.hits / data.casts
            
            if avgTargetsHit < 1.5 then
                table.insert(suggestions, {
                    category = "spell_usage",
                    title = "Optimize " .. spellName .. " AoE",
                    description = "You're averaging only " .. string.format("%.1f", avgTargetsHit) .. " targets with " .. spellName .. ". Try to position better to hit multiple targets with this AoE ability.",
                    priority = "medium"
                })
            end
        end
        
        -- Check for ineffective DoT uptime
        if self:IsDoTSpell(spellID) then
            -- This would calculate DoT uptime
            -- For implementation simplicity, we'll use a placeholder
            local dotUptime = math.random(40, 95) -- Placeholder
            
            if dotUptime < 70 then
                table.insert(suggestions, {
                    category = "spell_usage",
                    title = "Improve " .. spellName .. " Uptime",
                    description = spellName .. " uptime is only " .. dotUptime .. "%. Try to maintain this DoT effect more consistently for better damage.",
                    priority = "high"
                })
            end
        end
        
        ::continue::
    end
    
    return suggestions
end

-- Generate cooldown usage suggestions
function CombatAnalysis:GenerateCooldownSuggestions(log)
    local suggestions = {}
    
    -- Check cooldown usage
    local cooldownUsage = self:AnalyzeCooldownUsage(log)
    
    for spellID, usageData in pairs(cooldownUsage) do
        if usageData.efficiency < 0.7 then
            local spellName = GetSpellInfo(spellID) or "Unknown Cooldown"
            
            table.insert(suggestions, {
                category = "cooldown_usage",
                title = "Optimize " .. spellName .. " Usage",
                description = "You're not using " .. spellName .. " optimally. It was available for " .. 
                              string.format("%.0f", usageData.availablePercent) .. "% of the fight but only used " .. 
                              usageData.usedCount .. " times. Try to use this cooldown more frequently.",
                priority = "high"
            })
        end
    end
    
    return suggestions
}

-- Print combat report
function CombatAnalysis:PrintCombatReport(report, format)
    if not report then
        return
    end
    
    -- Build report based on format
    if format == "text" then
        API.Print("=== Combat Report ===")
        API.Print("Duration: " .. string.format("%.1f", report.duration) .. "s")
        API.Print("DPS: " .. string.format("%.1f", report.summary.dps))
        API.Print("Damage: " .. report.summary.damageTotal)
        
        if report.summary.healingTotal > 0 then
            API.Print("HPS: " .. string.format("%.1f", report.summary.hps))
            API.Print("Healing: " .. report.summary.healingTotal)
        end
        
        API.Print("Performance: " .. string.format("%.1f", report.analysis.overallScore) .. "%")
        
        if #report.suggestions > 0 then
            API.Print("Top Suggestion: " .. report.suggestions[1].title)
        end
    elseif format == "detailed" then
        API.Print("=== Detailed Combat Report ===")
        API.Print("Duration: " .. string.format("%.1f", report.duration) .. "s")
        API.Print("DPS: " .. string.format("%.1f", report.summary.dps) .. 
                  " (" .. string.format("%.0f", report.analysis.percentiles.dps) .. "th percentile)")
        
        -- Print top spells
        if report.details.damage and report.details.damage.bySpell then
            API.Print("Top Spells:")
            for i = 1, math.min(3, #report.details.damage.bySpell) do
                local spell = report.details.damage.bySpell[i]
                API.Print("  " .. i .. ". " .. spell.name .. ": " .. 
                          string.format("%.1f", spell.percent) .. "% (" .. 
                          string.format("%.1f", spell.dps) .. " DPS)")
            end
        end
        
        -- Print overall analysis
        API.Print("Performance:")
        API.Print("  Overall: " .. string.format("%.1f", report.analysis.overallScore) .. "%")
        API.Print("  Rotation: " .. string.format("%.1f", report.analysis.percentiles.rotation) .. "%")
        API.Print("  Resource: " .. string.format("%.1f", report.analysis.percentiles.resource) .. "%")
        
        -- Print suggestions
        if #report.suggestions > 0 then
            API.Print("Suggestions:")
            for i = 1, math.min(3, #report.suggestions) do
                API.Print("  " .. i .. ". " .. report.suggestions[i].title)
            end
        end
    elseif format == "visual" then
        -- This would use a visual UI to display the report
        -- For simplicity, we'll just print a message
        API.Print("Combat report generated. Type '/wranalyze report " .. report.id .. "' to view.")
    end
}

-- Find highest hit in damage data
function CombatAnalysis:FindHighestHit(damageBySpell)
    local highestHit = {
        amount = 0,
        spellID = nil,
        spellName = nil
    }
    
    for spellID, data in pairs(damageBySpell) do
        if data.max > highestHit.amount then
            highestHit.amount = data.max
            highestHit.spellID = spellID
            highestHit.spellName = data.name
        end
    end
    
    return highestHit
}

-- Analyze cooldown usage
function CombatAnalysis:AnalyzeCooldownUsage(log)
    local cooldownUsage = {}
    
    -- This would analyze cooldown usage based on spell cast history
    -- For implementation simplicity, we'll use placeholders
    
    local classID = log.player.class
    local specID = log.player.spec
    
    -- Get cooldowns for this spec
    local cooldowns = self:GetSpecCooldowns(classID, specID)
    
    for _, cooldownData in ipairs(cooldowns) do
        -- Count cooldown usage
        local usedCount = 0
        
        for _, cast in ipairs(log.spellCasts) do
            if cast.spellID == cooldownData.spellID then
                usedCount = usedCount + 1
            end
        end
        
        -- Calculate potential usage
        local cooldownDuration = cooldownData.cooldown
        local potentialUses = math.floor(log.duration / cooldownDuration)
        
        -- Calculate efficiency
        local efficiency = potentialUses > 0 and (usedCount / potentialUses) or 0
        local availableTime = math.min(log.duration, potentialUses * cooldownDuration)
        local availablePercent = (availableTime / log.duration) * 100
        
        cooldownUsage[cooldownData.spellID] = {
            name = cooldownData.name,
            usedCount = usedCount,
            potentialUses = potentialUses,
            efficiency = efficiency,
            availablePercent = availablePercent
        }
    end
    
    return cooldownUsage
end

-- Calculate rotation efficiency
function CombatAnalysis:CalculateRotationEfficiency(log, sequences)
    -- This would calculate rotation efficiency based on optimal sequences
    -- For implementation simplicity, we'll use a placeholder
    
    -- Try to use the real rotation efficiency if available
    if rotationEfficiency and rotationEfficiency.sequenceEfficiency then
        return rotationEfficiency.sequenceEfficiency
    end
    
    -- Placeholder
    return math.random(30, 95)
}

-- Calculate overall resource efficiency
function CombatAnalysis:CalculateOverallResourceEfficiency(log)
    if not log then
        return 0
    end
    
    -- Calculate total resources spent
    local totalSpent = 0
    for _, amount in pairs(log.resources.spent) do
        totalSpent = totalSpent + amount
    end
    
    -- Calculate total effect (damage + healing)
    local totalEffect = log.damage.total + log.healing.total
    
    -- Calculate efficiency
    if totalSpent > 0 then
        return totalEffect / totalSpent
    else
        return 0
    end
}

-- Get reference data for comparison
function CombatAnalysis:GetReferenceData(classID, specID)
    -- This would retrieve reference data from a database
    -- For implementation simplicity, we'll use placeholders
    
    local settings = ConfigRegistry:GetSettings("CombatAnalysis")
    local source = settings.referenceData.referenceDataSource
    
    -- Create placeholder reference data
    local referenceData = {
        dps = {
            low = 10000,
            average = 30000,
            high = 50000,
            percentiles = {
                [25] = 15000,
                [50] = 30000,
                [75] = 45000,
                [90] = 55000,
                [99] = 70000
            }
        },
        rotationEfficiency = {
            low = 40,
            average = 70,
            high = 90,
            percentiles = {
                [25] = 50,
                [50] = 70,
                [75] = 85,
                [90] = 92,
                [99] = 98
            }
        },
        resourceEfficiency = {
            low = 50,
            average = 100,
            high = 150,
            percentiles = {
                [25] = 60,
                [50] = 100,
                [75] = 140,
                [90] = 180,
                [99] = 220
            }
        },
        source = source
    }
    
    return referenceData
end

-- Calculate percentile against reference data
function CombatAnalysis:CalculatePercentile(value, referenceData)
    if not referenceData or not referenceData.percentiles then
        return 50 -- Default to middle
    end
    
    -- Find which percentile this value falls into
    if value <= referenceData.percentiles[25] then
        return math.max(1, (value / referenceData.percentiles[25]) * 25)
    elseif value <= referenceData.percentiles[50] then
        return 25 + ((value - referenceData.percentiles[25]) / (referenceData.percentiles[50] - referenceData.percentiles[25])) * 25
    elseif value <= referenceData.percentiles[75] then
        return 50 + ((value - referenceData.percentiles[50]) / (referenceData.percentiles[75] - referenceData.percentiles[50])) * 25
    elseif value <= referenceData.percentiles[90] then
        return 75 + ((value - referenceData.percentiles[75]) / (referenceData.percentiles[90] - referenceData.percentiles[75])) * 15
    elseif value <= referenceData.percentiles[99] then
        return 90 + ((value - referenceData.percentiles[90]) / (referenceData.percentiles[99] - referenceData.percentiles[90])) * 9
    else
        return 99 -- Above 99th percentile
    end
end

-- Get combat log by ID
function CombatAnalysis:GetCombatLogByID(id)
    for _, log in ipairs(combatLogs) do
        if log.id == id then
            return log
        end
    end
    
    return nil
end

-- Get expected spell contribution
function CombatAnalysis:GetExpectedSpellContribution(spellID)
    -- This would retrieve expected contributions from reference data
    -- For implementation simplicity, we'll use a placeholder
    
    return math.random(5, 25)
end

-- Get expected APM (actions per minute)
function CombatAnalysis:GetExpectedAPM()
    -- This would retrieve expected APM from reference data
    -- For implementation simplicity, we'll use a placeholder
    
    local classID = API.GetPlayerClassID()
    
    -- Different classes have different expected APMs
    local baseAPM = 30
    
    if classID == 4 or classID == 10 then -- Rogue or Monk
        baseAPM = 45 -- Energy-based classes have higher APM
    elseif classID == 8 then -- Mage
        baseAPM = 35 -- Caster with some instant casts
    elseif classID == 2 or classID == 9 then -- Paladin or Warlock
        baseAPM = 25 -- Slower paced casters/hybrids
    end
    
    return baseAPM
end

-- Get cooldowns for a spec
function CombatAnalysis:GetSpecCooldowns(classID, specID)
    -- This would retrieve cooldowns from a database
    -- For implementation simplicity, we'll use placeholders
    
    -- Return some placeholder cooldowns
    return {
        { spellID = 12345, name = "Major Cooldown 1", cooldown = 120 },
        { spellID = 23456, name = "Major Cooldown 2", cooldown = 180 },
        { spellID = 34567, name = "Major Cooldown 3", cooldown = 90 }
    }
end

-- Check if a spell is an AoE spell
function CombatAnalysis:IsAoESpell(spellID)
    -- This would check if a spell is AoE
    -- For implementation simplicity, we'll use a placeholder
    
    -- Randomize for simulation
    return math.random(1, 3) == 1
end

-- Check if a spell is a DoT spell
function CombatAnalysis:IsDoTSpell(spellID)
    -- This would check if a spell is a DoT
    -- For implementation simplicity, we'll use a placeholder
    
    -- Randomize for simulation
    return math.random(1, 5) == 1
end

-- Detect resource capping
function CombatAnalysis:DetectResourceCapping(log)
    -- This would analyze resource usage to detect capping
    -- For implementation simplicity, we'll use a placeholder
    
    local result = {
        detected = false,
        resourceName = "",
        frequency = 0
    }
    
    -- Mock detection
    local resourceTypes = { "Energy", "Rage", "Mana", "Focus", "Runic Power", "Astral Power", "Fury" }
    local detectChance = math.random(1, 3)
    
    if detectChance == 1 then
        result.detected = true
        result.resourceName = resourceTypes[math.random(1, #resourceTypes)]
        result.frequency = math.random(20, 70)
    end
    
    return result
end

-- Find inefficient resource spells
function CombatAnalysis:FindIneffientResourceSpells(log)
    local inefficientSpells = {}
    
    -- This would find spells with low effect-to-resource ratio
    -- For implementation simplicity, we'll use placeholders
    
    -- Generate some random inefficient spells
    local spellCount = math.random(0, 2)
    
    for i = 1, spellCount do
        -- Placeholder spell data
        table.insert(inefficientSpells, {
            id = 10000 + i,
            name = "Inefficient Spell " .. i,
            resourceType = "Energy", -- Placeholder
            efficiency = math.random(20, 50) / 100
        })
    end
    
    return inefficientSpells
end

-- Generate history summary from combat log
function CombatAnalysis:GenerateHistorySummary(log)
    if not log then
        return {}
    end
    
    return {
        id = log.id,
        timestamp = log.startTime,
        duration = log.duration,
        dps = log.damage.total / log.duration,
        damage = log.damage.total,
        healing = log.healing.total,
        targetCount = self:CountTargets(log),
        score = self:CalculateOverallPerformanceScore(log)
    }
}

-- Count targets in a log
function CombatAnalysis:CountTargets(log)
    if not log or not log.targets then
        return 0
    end
    
    local count = 0
    for _ in pairs(log.targets) do
        count = count + 1
    end
    
    return count
end

-- Calculate overall performance score
function CombatAnalysis:CalculateOverallPerformanceScore(log)
    if not log then
        return 0
    end
    
    -- This would calculate an overall score based on multiple metrics
    -- For implementation simplicity, we'll use a placeholder
    
    return math.random(40, 95)
end

-- Reset current analysis
function CombatAnalysis:ResetCurrentAnalysis()
    currentCombatLog = nil
    rotationEfficiency = {}
    realtimeMetrics = {}
}

-- Handle slash command
function CombatAnalysis:HandleSlashCommand(msg)
    if not msg or msg == "" then
        -- Show help
        API.Print("WindrunnerRotations Combat Analysis Commands:")
        API.Print("/wranalyze status - Show analysis status")
        API.Print("/wranalyze report [id] - Show a specific report")
        API.Print("/wranalyze list - List recent combat logs")
        API.Print("/wranalyze compare - Compare logs")
        API.Print("/wranalyze reset - Reset analysis data")
        API.Print("/wranalyze suggest - Get improvement suggestions")
        return
    end
    
    local args = {}
    for arg in string.gmatch(msg, "%S+") do
        table.insert(args, arg)
    end
    
    local command = args[1]
    
    if command == "status" then
        -- Show analysis status
        local settings = ConfigRegistry:GetSettings("CombatAnalysis")
        
        API.Print("Combat Analysis Status:")
        API.Print("Enabled: " .. (settings.generalSettings.enableAnalysis and "Yes" or "No"))
        API.Print("Detail Level: " .. settings.generalSettings.analysisDetail)
        
        if currentCombatLog then
            local duration = GetTime() - currentCombatLog.startTime
            local dps = currentCombatLog.damage.total / math.max(duration, 1)
            
            API.Print("In Combat: Yes")
            API.Print("Duration: " .. string.format("%.1f", duration) .. "s")
            API.Print("Current DPS: " .. string.format("%.1f", dps))
        else
            API.Print("In Combat: No")
        end
        
        API.Print("Combat Logs: " .. #combatLogs)
        API.Print("Reports: " .. self:CountReports())
    elseif command == "report" then
        -- Show a specific report
        local reportID = args[2]
        
        if not reportID then
            -- Show most recent report
            local latestReport = self:GetLatestReport()
            
            if latestReport then
                self:PrintCombatReport(latestReport, "detailed")
            else
                API.Print("No reports available")
            end
        else
            -- Show specific report
            local report = analysisReports[reportID]
            
            if report then
                self:PrintCombatReport(report, "detailed")
            else
                API.Print("Report not found: " .. reportID)
            end
        end
    elseif command == "list" then
        -- List recent combat logs
        if #combatLogs == 0 then
            API.Print("No combat logs available")
            return
        end
        
        API.Print("Recent Combat Logs:")
        
        for i = #combatLogs, math.max(1, #combatLogs - 5), -1 do
            local log = combatLogs[i]
            local timestamp = date("%H:%M:%S", log.startTime)
            local dps = log.damage.total / log.duration
            
            API.Print(i .. ". " .. timestamp .. " - " .. 
                     string.format("%.1f", log.duration) .. "s, " .. 
                     string.format("%.1f", dps) .. " DPS" .. 
                     " (ID: " .. log.id .. ")")
        end
    elseif command == "compare" then
        -- Compare logs
        if #combatLogs < 2 then
            API.Print("Need at least 2 combat logs to compare")
            return
        end
        
        -- Default to comparing the two most recent logs
        local log1 = combatLogs[#combatLogs]
        local log2 = combatLogs[#combatLogs - 1]
        
        if args[2] and args[3] then
            -- Use specified logs
            log1 = self:GetCombatLogByID(tonumber(args[2]))
            log2 = self:GetCombatLogByID(tonumber(args[3]))
            
            if not log1 or not log2 then
                API.Print("One or both combat logs not found")
                return
            end
        end
        
        -- Compare the logs
        self:CompareCombatLogs(log1, log2)
    elseif command == "reset" then
        -- Reset analysis data
        combatLogs = {}
        analysisReports = {}
        improvementSuggestions = {}
        realtimeMetrics = {}
        combatHistory = {}
        spellAnalysis = {}
        rotationEfficiency = {}
        resourceUsage = {}
        currentCombatLog = nil
        
        API.Print("Combat analysis data reset")
    elseif command == "suggest" then
        -- Get improvement suggestions
        if #combatLogs == 0 then
            API.Print("No combat logs available for suggestions")
            return
        end
        
        local latestLog = combatLogs[#combatLogs]
        local analysis = self:GeneratePerformanceAnalysis(latestLog)
        local suggestions = self:GenerateImprovementSuggestions(latestLog, analysis)
        
        if #suggestions == 0 then
            API.Print("No suggestions available")
            return
        end
        
        API.Print("Improvement Suggestions:")
        
        for i, suggestion in ipairs(suggestions) do
            API.Print(i .. ". " .. suggestion.title)
            API.Print("   " .. suggestion.description)
            
            if i >= 3 then
                API.Print("..." .. (#suggestions - 3) .. " more suggestions")
                break
            end
        end
    else
        API.Print("Unknown command. Type /wranalyze for help.")
    end
end

-- Get the latest report
function CombatAnalysis:GetLatestReport()
    local latestTime = 0
    local latestReport = nil
    
    for id, report in pairs(analysisReports) do
        if report.timestamp > latestTime then
            latestTime = report.timestamp
            latestReport = report
        end
    end
    
    return latestReport
end

-- Count reports
function CombatAnalysis:CountReports()
    local count = 0
    for _ in pairs(analysisReports) do
        count = count + 1
    end
    
    return count
end

-- Compare two combat logs
function CombatAnalysis:CompareCombatLogs(log1, log2)
    if not log1 or not log2 then
        return
    end
    
    -- Calculate key metrics
    local dps1 = log1.damage.total / log1.duration
    local dps2 = log2.damage.total / log2.duration
    local dpsDiff = dps1 - dps2
    local dpsPercent = dps2 > 0 and ((dpsDiff / dps2) * 100) or 0
    
    local efficiency1 = self:CalculateOverallResourceEfficiency(log1)
    local efficiency2 = self:CalculateOverallResourceEfficiency(log2)
    local efficiencyDiff = efficiency1 - efficiency2
    local efficiencyPercent = efficiency2 > 0 and ((efficiencyDiff / efficiency2) * 100) or 0
    
    -- Print comparison
    API.Print("=== Combat Log Comparison ===")
    API.Print("Log 1: " .. string.format("%.1f", log1.duration) .. "s, " .. string.format("%.1f", dps1) .. " DPS")
    API.Print("Log 2: " .. string.format("%.1f", log2.duration) .. "s, " .. string.format("%.1f", dps2) .. " DPS")
    
    -- Overall comparison
    API.Print("DPS Difference: " .. string.format("%.1f", dpsDiff) .. " (" .. string.format("%+.1f", dpsPercent) .. "%)")
    API.Print("Resource Efficiency Difference: " .. string.format("%.1f", efficiencyDiff) .. " (" .. string.format("%+.1f", efficiencyPercent) .. "%)")
    
    -- Compare spell usage
    API.Print("Spell Usage Differences:")
    
    -- Create combined spell list
    local allSpells = {}
    
    for spellID in pairs(log1.damage.bySpell) do
        allSpells[spellID] = true
    end
    
    for spellID in pairs(log2.damage.bySpell) do
        allSpells[spellID] = true
    end
    
    -- Compare damage for each spell
    local spellDiffs = {}
    
    for spellID in pairs(allSpells) do
        local spell1 = log1.damage.bySpell[spellID]
        local spell2 = log2.damage.bySpell[spellID]
        
        local name = "Unknown"
        local damage1 = 0
        local damage2 = 0
        
        if spell1 then
            name = spell1.name
            damage1 = spell1.total / log1.duration -- Normalize for duration
        end
        
        if spell2 then
            name = spell2.name
            damage2 = spell2.total / log2.duration -- Normalize for duration
        end
        
        local diff = damage1 - damage2
        local percent = damage2 > 0 and ((diff / damage2) * 100) or 0
        
        table.insert(spellDiffs, {
            id = spellID,
            name = name,
            diff = diff,
            percent = percent
        })
    end
    
    -- Sort by largest absolute difference
    table.sort(spellDiffs, function(a, b) return math.abs(a.diff) > math.abs(b.diff) end)
    
    -- Print top differences
    for i = 1, math.min(5, #spellDiffs) do
        local diff = spellDiffs[i]
        local sign = diff.diff >= 0 and "+" or ""
        
        API.Print("  " .. diff.name .. ": " .. sign .. string.format("%.1f", diff.diff) .. " DPS (" .. 
                 sign .. string.format("%.1f", diff.percent) .. "%)")
    end
    
    -- Conclusion
    if dpsPercent > 5 then
        API.Print("Conclusion: Log 1 shows a significant DPS improvement.")
    elseif dpsPercent < -5 then
        API.Print("Conclusion: Log 1 shows a significant DPS decrease.")
    else
        API.Print("Conclusion: DPS difference is minor.")
    end
}

-- Return the module for loading
return CombatAnalysis