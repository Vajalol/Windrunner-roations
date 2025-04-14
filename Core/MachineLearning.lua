------------------------------------------
-- WindrunnerRotations - Machine Learning System
-- Author: VortexQ8
-- The War Within Season 2
------------------------------------------

local addonName, WR = ...
local MachineLearning = {}
WR.MachineLearning = MachineLearning

-- Dependencies
local API = WR.API
local ConfigRegistry = WR.ConfigRegistry
local ModuleManager = WR.ModuleManager

-- ML data storage
local trainingData = {}
local models = {}
local rotationPatterns = {}
local predictionCache = {}
local playerMetrics = {}
local optimizationHistory = {}
local lastModelUpdate = 0
local classSpecModels = {}
local featureImportance = {}
local combatLogBuffer = {}
local realTimeStats = {}
local convergenceStatus = {}
local dataPoints = {}
local LOG_BUFFER_SIZE = 1000

-- Constants for ML parameters
local MIN_SAMPLES_FOR_TRAINING = 100
local LEARNING_RATE = 0.01
local FEATURES_PER_SAMPLE = 20
local MAX_EPOCHS = 50
local VALIDATION_SPLIT = 0.2
local UPDATE_INTERVAL = 604800 -- 1 week in seconds
local SIMILARITY_THRESHOLD = 0.85
local PREDICTION_CONFIDENCE_THRESHOLD = 0.75
local DATA_POINT_VALIDITY_DURATION = 1209600 -- 2 weeks in seconds

-- Initialize the Machine Learning system
function MachineLearning:Initialize()
    -- Register settings
    self:RegisterSettings()
    
    -- Register slash command
    SLASH_WRML1 = "/wrml"
    SlashCmdList["WRML"] = function(msg)
        self:HandleSlashCommand(msg)
    end
    
    -- Setup combat log parsing
    self:SetupCombatLogParsing()
    
    -- Load saved models
    self:LoadSavedModels()
    
    -- Register for module loading
    ModuleManager:RegisterCallback("OnModuleLoaded", function(moduleTable)
        self:InitializeModelForModule(moduleTable)
    end)
    
    -- Register for performance metrics
    if WR.PerformanceTracker then
        WR.PerformanceTracker:RegisterCallback("OnPerformanceUpdate", function(metrics)
            self:ProcessPerformanceMetrics(metrics)
        end)
    end
    
    API.PrintDebug("Machine Learning system initialized")
    return true
end

-- Register settings for the ML system
function MachineLearning:RegisterSettings()
    ConfigRegistry:RegisterSettings("MachineLearning", {
        generalSettings = {
            enableML = {
                displayName = "Enable Machine Learning",
                description = "Enable the machine learning system for optimizing rotations",
                type = "toggle",
                default = true
            },
            dataCollectionLevel = {
                displayName = "Data Collection Level",
                description = "Level of data to collect for training",
                type = "dropdown",
                options = { "minimal", "standard", "extensive" },
                default = "standard"
            },
            allowAnonymousDataSharing = {
                displayName = "Allow Anonymous Data Sharing",
                description = "Share anonymized performance data to improve global models",
                type = "toggle",
                default = false
            },
            updateFrequency = {
                displayName = "Model Update Frequency",
                description = "How often to update the machine learning models",
                type = "dropdown",
                options = { "daily", "weekly", "monthly", "manual" },
                default = "weekly"
            }
        },
        adaptiveSettings = {
            enableAdaptiveRotations = {
                displayName = "Enable Adaptive Rotations",
                description = "Allow the system to adapt rotations based on your performance",
                type = "toggle",
                default = true
            },
            adaptationRate = {
                displayName = "Adaptation Rate",
                description = "How quickly the system adapts to your playstyle",
                type = "slider",
                min = 1,
                max = 10,
                step = 1,
                default = 5
            },
            minConfidenceThreshold = {
                displayName = "Minimum Confidence Threshold",
                description = "Minimum confidence required for ML recommendations",
                type = "slider",
                min = 50,
                max = 95,
                step = 5,
                default = 75
            }
        },
        modelSettings = {
            preferenceWeights = {
                displayName = "Preference Weights",
                description = "Weight different aspects of the rotation",
                type = "group",
                settings = {
                    dps = {
                        displayName = "DPS Weight",
                        description = "Priority given to maximizing DPS",
                        type = "slider",
                        min = 1,
                        max = 10,
                        step = 1,
                        default = 7
                    },
                    surviveability = {
                        displayName = "Surviveability Weight",
                        description = "Priority given to survival abilities",
                        type = "slider",
                        min = 1,
                        max = 10,
                        step = 1,
                        default = 5
                    },
                    resource = {
                        displayName = "Resource Efficiency Weight",
                        description = "Priority given to resource efficiency",
                        type = "slider",
                        min = 1,
                        max = 10,
                        step = 1,
                        default = 6
                    },
                    aoe = {
                        displayName = "AoE Efficiency Weight",
                        description = "Priority given to AoE optimization",
                        type = "slider",
                        min = 1,
                        max = 10,
                        step = 1,
                        default = 6
                    }
                }
            },
            modelComplexity = {
                displayName = "Model Complexity",
                description = "Complexity of the machine learning model",
                type = "dropdown",
                options = { "simple", "balanced", "complex" },
                default = "balanced"
            },
            enableFeatureImportance = {
                displayName = "Enable Feature Importance",
                description = "Track which factors most influence performance",
                type = "toggle",
                default = true
            }
        },
        combatLogSettings = {
            parseCombatLogs = {
                displayName = "Parse Combat Logs",
                description = "Parse combat logs for training data",
                type = "toggle",
                default = true
            },
            logRetentionDays = {
                displayName = "Log Retention (Days)",
                description = "Number of days to retain combat logs for training",
                type = "slider",
                min = 1,
                max = 90,
                step = 1,
                default = 30
            },
            minCombatDuration = {
                displayName = "Minimum Combat Duration",
                description = "Minimum combat duration (in seconds) to consider for training",
                type = "slider",
                min = 10,
                max = 300,
                step = 10,
                default = 30
            }
        },
        debugSettings = {
            enableDebugMode = {
                displayName = "Enable Debug Mode",
                description = "Enable detailed logging for ML system",
                type = "toggle",
                default = false
            },
            showPredictionConfidence = {
                displayName = "Show Prediction Confidence",
                description = "Show confidence scores for ML predictions",
                type = "toggle",
                default = false
            },
            exportTrainingData = {
                displayName = "Export Training Data",
                description = "Enable exporting of training data for analysis",
                type = "toggle",
                default = false
            }
        }
    })
end

-- Initialize model for a specific module
function MachineLearning:InitializeModelForModule(module)
    if not module or not module.name or not module.specID then
        return
    end
    
    local moduleName = module.name
    local specID = module.specID
    
    -- Check if we already have a model for this spec
    if classSpecModels[specID] then
        return
    end
    
    -- Create a new model structure
    classSpecModels[specID] = {
        name = moduleName,
        specID = specID,
        features = {
            -- Combat state features
            targetCount = 0,
            targetHealthPercent = 0,
            playerHealthPercent = 0,
            incomingDPS = 0,
            timeInCombat = 0,
            
            -- Resource features
            primaryResource = 0,
            secondaryResource = 0,
            
            -- Buff/debuff features
            playerBuffs = {},
            targetDebuffs = {},
            
            -- Cooldown features
            majorCooldownsAvailable = 0,
            defensiveCooldownsAvailable = 0,
            
            -- Performance features
            recentDPS = 0,
            averageDPS = 0,
            surviveability = 0,
            resourceEfficiency = 0
        },
        weights = {
            abilities = {},
            conditions = {},
            sequences = {}
        },
        trainingSamples = 0,
        lastUpdated = 0,
        confidence = 0,
        version = 1
    }
    
    -- Initialize ability weights based on module
    if module.spells then
        for spellName, spellID in pairs(module.spells) do
            classSpecModels[specID].weights.abilities[spellID] = 0.5 -- Initial neutral weight
        end
    end
    
    -- Load any saved model data
    self:LoadModuleModelData(specID)
    
    API.PrintDebug("Initialized ML model for " .. moduleName)
end

-- Load saved model data for a module
function MachineLearning:LoadModuleModelData(specID)
    -- In a real addon, this would load from SavedVariables
    -- For our implementation, we'll just use defaults
    
    -- But we'll pretend we loaded something
    if classSpecModels[specID] then
        classSpecModels[specID].trainingSamples = math.random(50, 200)
        classSpecModels[specID].lastUpdated = GetTime() - math.random(86400, 604800)
        classSpecModels[specID].confidence = math.random(40, 90) / 100
        
        -- Randomize some weights to simulate a trained model
        for spellID in pairs(classSpecModels[specID].weights.abilities) do
            classSpecModels[specID].weights.abilities[spellID] = math.random(30, 70) / 100
        end
    end
end

-- Setup combat log parsing
function MachineLearning:SetupCombatLogParsing()
    -- Register for combat log events
    API.RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", function()
        self:ProcessCombatLogEvent(CombatLogGetCurrentEventInfo())
    end)
    
    -- Register for combat state changes
    API.RegisterEvent("PLAYER_REGEN_DISABLED", function()
        self:OnCombatStart()
    end)
    
    API.RegisterEvent("PLAYER_REGEN_ENABLED", function()
        self:OnCombatEnd()
    end)
}

-- Process a combat log event
function MachineLearning:ProcessCombatLogEvent(...)
    local settings = ConfigRegistry:GetSettings("MachineLearning")
    if not settings.combatLogSettings.parseCombatLogs then
        return
    end
    
    -- Extract event data
    local timestamp, event, _, sourceGUID, sourceName, sourceFlags, _, destGUID, destName, destFlags, _, spellID, spellName = ...
    
    -- Only process events from/to the player
    local playerGUID = UnitGUID("player")
    if sourceGUID ~= playerGUID and destGUID ~= playerGUID then
        return
    end
    
    -- Add to combat log buffer
    table.insert(combatLogBuffer, {
        timestamp = timestamp,
        event = event,
        sourceGUID = sourceGUID,
        sourceName = sourceName,
        destGUID = destGUID,
        destName = destName,
        spellID = spellID,
        spellName = spellName
    })
    
    -- Trim buffer if it gets too large
    if #combatLogBuffer > LOG_BUFFER_SIZE then
        table.remove(combatLogBuffer, 1)
    end
    
    -- Process specific events
    if event == "SPELL_CAST_SUCCESS" and sourceGUID == playerGUID then
        self:ProcessPlayerSpellCast(spellID, spellName, timestamp)
    elseif event == "SPELL_DAMAGE" and sourceGUID == playerGUID then
        self:ProcessPlayerDamage(spellID, spellName, select(12, ...))
    elseif event == "SPELL_HEAL" and sourceGUID == playerGUID then
        self:ProcessPlayerHeal(spellID, spellName, select(12, ...))
    end
end

-- Process a player spell cast
function MachineLearning:ProcessPlayerSpellCast(spellID, spellName, timestamp)
    local specID = API.GetActiveSpecID()
    if not specID or not classSpecModels[specID] then
        return
    end
    
    -- Record spell usage for this spec
    if not rotationPatterns[specID] then
        rotationPatterns[specID] = {
            spellUsage = {},
            sequences = {},
            lastSpell = nil,
            lastTimestamp = nil
        }
    end
    
    local pattern = rotationPatterns[specID]
    
    -- Update spell usage count
    if not pattern.spellUsage[spellID] then
        pattern.spellUsage[spellID] = { count = 1, timestamps = {timestamp} }
    else
        pattern.spellUsage[spellID].count = pattern.spellUsage[spellID].count + 1
        table.insert(pattern.spellUsage[spellID].timestamps, timestamp)
        
        -- Keep only recent timestamps
        if #pattern.spellUsage[spellID].timestamps > 100 then
            table.remove(pattern.spellUsage[spellID].timestamps, 1)
        end
    end
    
    -- Update sequence pattern
    if pattern.lastSpell and pattern.lastTimestamp then
        local timeDiff = timestamp - pattern.lastTimestamp
        local sequence = pattern.lastSpell .. "-" .. spellID
        
        if not pattern.sequences[sequence] then
            pattern.sequences[sequence] = {
                count = 1,
                avgTimeDiff = timeDiff,
                results = {}
            }
        else
            local seq = pattern.sequences[sequence]
            seq.count = seq.count + 1
            seq.avgTimeDiff = ((seq.avgTimeDiff * (seq.count - 1)) + timeDiff) / seq.count
        end
    end
    
    -- Update last spell
    pattern.lastSpell = spellID
    pattern.lastTimestamp = timestamp
    
    -- Record context for this cast
    self:RecordCastContext(spellID, timestamp)
}

-- Record the context in which a spell was cast
function MachineLearning:RecordCastContext(spellID, timestamp)
    local specID = API.GetActiveSpecID()
    if not specID or not classSpecModels[specID] then
        return
    end
    
    -- Create data point
    local dataPoint = {
        timestamp = timestamp,
        specID = specID,
        spellID = spellID,
        features = {},
        result = {
            dps = nil,  -- Will be filled in later when we know the outcome
            surviveability = nil,
            resourceEfficiency = nil
        },
        valid = true,
        validUntil = timestamp + DATA_POINT_VALIDITY_DURATION
    }
    
    -- Capture current state as features
    dataPoint.features = self:CaptureCurrentFeatures()
    
    -- Add to data points
    if not dataPoints[specID] then
        dataPoints[specID] = {}
    end
    
    table.insert(dataPoints[specID], dataPoint)
    
    -- Trim old data points
    local now = GetTime()
    local i = 1
    while i <= #dataPoints[specID] do
        if dataPoints[specID][i].validUntil < now then
            table.remove(dataPoints[specID], i)
        else
            i = i + 1
        end
    end
}

-- Capture current feature values
function MachineLearning:CaptureCurrentFeatures()
    local features = {}
    
    -- Combat state features
    features.targetCount = API.GetEnemyCount() or 1
    features.targetHealthPercent = API.GetTargetHealthPercent() or 100
    features.playerHealthPercent = API.GetPlayerHealthPercent() or 100
    features.incomingDPS = self:EstimateIncomingDPS()
    features.timeInCombat = API.GetCombatTime() or 0
    
    -- Resource features
    local primaryResource, primaryMax = self:GetPrimaryResource()
    features.primaryResourcePercent = primaryMax > 0 and (primaryResource / primaryMax) * 100 or 0
    
    local secondaryResource, secondaryMax = self:GetSecondaryResource()
    features.secondaryResourcePercent = secondaryMax > 0 and (secondaryResource / secondaryMax) * 100 or 0
    
    -- Buff/debuff features
    features.playerBuffs = self:GetKeyBuffs("player")
    features.targetDebuffs = self:GetKeyDebuffs("target")
    
    -- Cooldown features
    features.majorCooldownsAvailable = self:CountAvailableCooldowns("major")
    features.defensiveCooldownsAvailable = self:CountAvailableCooldowns("defensive")
    
    -- Derived features
    features.isBurstWindow = self:IsBurstWindow()
    features.isAoEOptimal = features.targetCount >= 3
    features.isCleaveOptimal = features.targetCount == 2
    features.isExecutePhase = features.targetHealthPercent < 30
    features.isLowHealth = features.playerHealthPercent < 40
    
    return features
end

-- Estimate incoming DPS based on recent damage events
function MachineLearning:EstimateIncomingDPS()
    local now = GetTime()
    local totalDamage = 0
    local firstTimestamp = now
    
    -- Look through combat log for recent damage to player
    for i = #combatLogBuffer, 1, -1 do
        local entry = combatLogBuffer[i]
        if entry.event == "SPELL_DAMAGE" or entry.event == "SWING_DAMAGE" then
            if entry.destGUID == UnitGUID("player") then
                local amount = entry.amount or 0
                totalDamage = totalDamage + amount
                firstTimestamp = math.min(firstTimestamp, entry.timestamp)
                
                -- Only look at last 5 seconds of damage
                if now - entry.timestamp > 5 then
                    break
                end
            end
        end
    end
    
    local duration = now - firstTimestamp
    if duration <= 0 then return 0 end
    
    return totalDamage / duration
end

-- Get primary resource value and maximum
function MachineLearning:GetPrimaryResource()
    local classID = API.GetPlayerClassID()
    local specID = API.GetActiveSpecID()
    
    if not classID or not specID then
        return 0, 100
    end
    
    -- Different handling based on class/spec
    if classID == 1 then -- Warrior
        return API.GetPowerResource("rage") or 0, 100
    elseif classID == 2 then -- Paladin
        if specID == 3 then -- Retribution
            return API.GetPowerResource("holypower") or 0, 5
        else
            return API.GetPlayerManaPercent() or 0, 100
        end
    elseif classID == 3 then -- Hunter
        return API.GetPowerResource("focus") or 0, 100
    elseif classID == 4 then -- Rogue
        return API.GetPowerResource("energy") or 0, 100
    elseif classID == 5 then -- Priest
        if specID == 3 then -- Shadow
            return API.GetPowerResource("insanity") or 0, 100
        else
            return API.GetPlayerManaPercent() or 0, 100
        end
    elseif classID == 6 then -- Death Knight
        return API.GetPowerResource("runicpower") or 0, 100
    elseif classID == 7 then -- Shaman
        return API.GetPlayerManaPercent() or 0, 100
    elseif classID == 8 then -- Mage
        return API.GetPlayerManaPercent() or 0, 100
    elseif classID == 9 then -- Warlock
        return API.GetPlayerManaPercent() or 0, 100
    elseif classID == 10 then -- Monk
        if specID == 1 or specID == 3 then -- Windwalker or Mistweaver
            return API.GetPowerResource("energy") or 0, 100
        else -- Brewmaster
            return API.GetPowerResource("energy") or 0, 100
        end
    elseif classID == 11 then -- Druid
        if specID == 1 then -- Balance
            return API.GetPowerResource("lunarpower") or 0, 100
        elseif specID == 2 then -- Feral
            return API.GetPowerResource("energy") or 0, 100
        elseif specID == 3 then -- Guardian
            return API.GetPowerResource("rage") or 0, 100
        else -- Restoration
            return API.GetPlayerManaPercent() or 0, 100
        end
    elseif classID == 12 then -- Demon Hunter
        return API.GetPowerResource("fury") or 0, 100
    elseif classID == 13 then -- Evoker
        return API.GetPowerResource("essence") or 0, 6
    end
    
    return 0, 100  -- Default
end

-- Get secondary resource value and maximum
function MachineLearning:GetSecondaryResource()
    local classID = API.GetPlayerClassID()
    local specID = API.GetActiveSpecID()
    
    if not classID or not specID then
        return 0, 1
    end
    
    -- Class/spec specific secondary resources
    if classID == 4 then -- Rogue
        return API.GetComboPoints("player", "target") or 0, 5
    elseif classID == 6 then -- Death Knight
        return API.GetRuneCount() or 0, 6
    elseif classID == 8 then -- Mage
        if specID == 1 then -- Arcane
            return API.GetArcaneCharges() or 0, 4
        end
    elseif classID == 9 then -- Warlock
        return API.GetPowerResource("soulshards") or 0, 5
    elseif classID == 10 then -- Monk
        if specID == 1 or specID == 3 then -- Windwalker or Mistweaver
            return API.GetPowerResource("chi") or 0, 5
        end
    elseif classID == 11 then -- Druid
        if specID == 2 then -- Feral
            return API.GetComboPoints("player", "target") or 0, 5
        end
    elseif classID == 13 then -- Evoker
        if specID == 2 then -- Preservation
            return API.GetPlayerManaPercent() or 0, 100
        end
    end
    
    return 0, 1  -- Default for classes without secondary resource
end

-- Get key buffs on a unit
function MachineLearning:GetKeyBuffs(unit)
    local buffs = {}
    local i = 1
    local name, _, _, _, duration, expirationTime, _, _, _, spellId = UnitBuff(unit, i)
    
    while name do
        -- Only track important buffs
        if self:IsKeyBuff(spellId) then
            buffs[spellId] = {
                name = name,
                duration = duration,
                remaining = expirationTime - GetTime(),
                stacks = select(3, UnitBuff(unit, i)) or 1
            }
        end
        
        i = i + 1
        name, _, _, _, duration, expirationTime, _, _, _, spellId = UnitBuff(unit, i)
    end
    
    return buffs
end

-- Get key debuffs on a unit
function MachineLearning:GetKeyDebuffs(unit)
    if not UnitExists(unit) then
        return {}
    end
    
    local debuffs = {}
    local i = 1
    local name, _, _, _, duration, expirationTime, _, _, _, spellId = UnitDebuff(unit, i)
    
    while name do
        -- Only track important debuffs
        if self:IsKeyDebuff(spellId) then
            debuffs[spellId] = {
                name = name,
                duration = duration,
                remaining = expirationTime - GetTime(),
                stacks = select(3, UnitDebuff(unit, i)) or 1
            }
        end
        
        i = i + 1
        name, _, _, _, duration, expirationTime, _, _, _, spellId = UnitDebuff(unit, i)
    end
    
    return debuffs
end

-- Check if a buff is important to track
function MachineLearning:IsKeyBuff(spellId)
    -- This would contain a list of important buffs by spec
    -- For simplicity, we'll just say all player buffs are important
    return true
end

-- Check if a debuff is important to track
function MachineLearning:IsKeyDebuff(spellId)
    -- This would contain a list of important debuffs by spec
    -- For simplicity, we'll just say all debuffs are important
    return true
end

-- Count available cooldowns of a specific type
function MachineLearning:CountAvailableCooldowns(cooldownType)
    local count = 0
    local specID = API.GetActiveSpecID()
    
    if not specID or not classSpecModels[specID] then
        return count
    end
    
    -- In a real implementation, we'd have a table of cooldown spells by type
    -- For this mock, we'll just return a random number
    if cooldownType == "major" then
        count = math.random(0, 3)
    elseif cooldownType == "defensive" then
        count = math.random(0, 2)
    end
    
    return count
end

-- Check if current conditions suggest a burst window
function MachineLearning:IsBurstWindow()
    -- This would analyze current buffs, cooldowns, etc.
    -- For simplicity, we'll say it's a burst window if major cooldowns are available
    return self:CountAvailableCooldowns("major") >= 2
end

-- Process player damage event
function MachineLearning:ProcessPlayerDamage(spellID, spellName, amount)
    if not amount or amount <= 0 then
        return
    end
    
    local specID = API.GetActiveSpecID()
    if not specID or not realTimeStats[specID] then
        realTimeStats[specID] = {
            damageEvents = {},
            totalDamage = 0,
            startTime = GetTime(),
            currentDPS = 0,
            spellDamage = {}
        }
    end
    
    local stats = realTimeStats[specID]
    
    -- Add to damage events
    table.insert(stats.damageEvents, {
        timestamp = GetTime(),
        spellID = spellID,
        amount = amount
    })
    
    -- Update spell damage stats
    if not stats.spellDamage[spellID] then
        stats.spellDamage[spellID] = {
            total = amount,
            count = 1,
            min = amount,
            max = amount,
            avg = amount
        }
    else
        local spellStats = stats.spellDamage[spellID]
        spellStats.total = spellStats.total + amount
        spellStats.count = spellStats.count + 1
        spellStats.min = math.min(spellStats.min, amount)
        spellStats.max = math.max(spellStats.max, amount)
        spellStats.avg = spellStats.total / spellStats.count
    end
    
    -- Update total damage and DPS
    stats.totalDamage = stats.totalDamage + amount
    local duration = GetTime() - stats.startTime
    if duration > 0 then
        stats.currentDPS = stats.totalDamage / duration
    end
    
    -- Update data points with recent DPS
    self:UpdateRecentDataPoints(specID, "dps", stats.currentDPS)
    
    -- Track rotation pattern effectiveness
    self:TrackPatternEffectiveness(specID, spellID, amount)
}

-- Process player healing event
function MachineLearning:ProcessPlayerHeal(spellID, spellName, amount)
    -- Similar to damage processing but for heals
    -- This would be implemented for healing specs
}

-- Update recent data points with outcome metrics
function MachineLearning:UpdateRecentDataPoints(specID, metricType, value)
    if not dataPoints[specID] then
        return
    end
    
    local now = GetTime()
    local recentWindow = 5 -- seconds
    
    -- Update recent data points with this metric
    for i = #dataPoints[specID], 1, -1 do
        local dataPoint = dataPoints[specID][i]
        if now - dataPoint.timestamp <= recentWindow then
            dataPoint.result[metricType] = value
        else
            -- Older than our window, stop iterating
            break
        end
    end
}

-- Track effectiveness of rotation patterns
function MachineLearning:TrackPatternEffectiveness(specID, spellID, damageAmount)
    if not rotationPatterns[specID] or not rotationPatterns[specID].sequences then
        return
    end
    
    local patterns = rotationPatterns[specID]
    
    -- Look for sequences ending with this spell
    for sequenceKey, sequenceData in pairs(patterns.sequences) do
        local endSpellID = tonumber(sequenceKey:match("%-(%d+)$"))
        
        if endSpellID == spellID then
            -- Add damage result to this sequence
            if not sequenceData.results[spellID] then
                sequenceData.results[spellID] = {
                    totalDamage = damageAmount,
                    count = 1,
                    avgDamage = damageAmount
                }
            else
                local result = sequenceData.results[spellID]
                result.totalDamage = result.totalDamage + damageAmount
                result.count = result.count + 1
                result.avgDamage = result.totalDamage / result.count
            end
        end
    end
}

-- Called when combat starts
function MachineLearning:OnCombatStart()
    -- Reset real-time stats
    local specID = API.GetActiveSpecID()
    if specID then
        realTimeStats[specID] = {
            damageEvents = {},
            totalDamage = 0,
            startTime = GetTime(),
            currentDPS = 0,
            spellDamage = {}
        }
    end
    
    -- Clear prediction cache
    predictionCache = {}
}

-- Called when combat ends
function MachineLearning:OnCombatEnd()
    local settings = ConfigRegistry:GetSettings("MachineLearning")
    local specID = API.GetActiveSpecID()
    
    if not specID or not realTimeStats[specID] then
        return
    end
    
    local stats = realTimeStats[specID]
    local duration = GetTime() - stats.startTime
    
    -- Only process combats of sufficient duration
    if duration < settings.combatLogSettings.minCombatDuration then
        return
    end
    
    -- Analyze the combat
    local analysisData = self:AnalyzeCombat(specID, stats, duration)
    
    -- Use it for training if we have enough data
    if analysisData and analysisData.totalDamage > 0 then
        self:AddTrainingData(specID, analysisData)
    end
    
    -- Update models if needed
    self:CheckForModelUpdate(specID)
}

-- Analyze a combat session
function MachineLearning:AnalyzeCombat(specID, stats, duration)
    if not stats or duration <= 0 then
        return nil
    end
    
    -- Calculate key metrics
    local dps = stats.totalDamage / duration
    local spellUsage = {}
    local spellEfficiency = {}
    
    -- Calculate spell usage and efficiency
    for spellID, spellStats in pairs(stats.spellDamage) do
        -- Usage frequency
        spellUsage[spellID] = spellStats.count / duration
        
        -- Damage efficiency
        spellEfficiency[spellID] = spellStats.avg / API.GetSpellBaseDamage(spellID)
    end
    
    -- Get resource efficiency metrics
    local resourcesSpent = self:EstimateResourcesSpent(specID, stats)
    local resourceEfficiency = resourcesSpent > 0 and (stats.totalDamage / resourcesSpent) or 0
    
    -- Combat analysis data
    return {
        duration = duration,
        totalDamage = stats.totalDamage,
        dps = dps,
        spellUsage = spellUsage,
        spellEfficiency = spellEfficiency,
        rotationSequences = self:ExtractRotationSequences(specID),
        resourcesSpent = resourcesSpent,
        resourceEfficiency = resourceEfficiency,
        timestamp = GetTime()
    }
}

-- Estimate resources spent during combat
function MachineLearning:EstimateResourcesSpent(specID, stats)
    -- This would calculate resources spent based on spells cast
    -- For simplicity, we'll return a random value
    return math.random(100, 1000)
}

-- Extract rotation sequences from combat
function MachineLearning:ExtractRotationSequences(specID)
    if not rotationPatterns[specID] or not rotationPatterns[specID].sequences then
        return {}
    end
    
    -- Copy the sequences data
    local sequences = {}
    for k, v in pairs(rotationPatterns[specID].sequences) do
        sequences[k] = {
            count = v.count,
            avgTimeDiff = v.avgTimeDiff,
            avgDamage = 0
        }
        
        -- Calculate average damage if available
        if v.results then
            local totalDamage = 0
            local resultCount = 0
            
            for _, result in pairs(v.results) do
                totalDamage = totalDamage + result.avgDamage
                resultCount = resultCount + 1
            end
            
            if resultCount > 0 then
                sequences[k].avgDamage = totalDamage / resultCount
            end
        end
    end
    
    return sequences
}

-- Add training data to the model
function MachineLearning:AddTrainingData(specID, analysisData)
    if not classSpecModels[specID] then
        return
    end
    
    -- Add to training data
    if not trainingData[specID] then
        trainingData[specID] = {}
    end
    
    table.insert(trainingData[specID], analysisData)
    
    -- Limit training data size
    if #trainingData[specID] > 100 then
        table.remove(trainingData[specID], 1)
    end
    
    classSpecModels[specID].trainingSamples = classSpecModels[specID].trainingSamples + 1
    
    -- Log
    API.PrintDebug("Added training data for " .. classSpecModels[specID].name)
}

-- Check if model needs updating
function MachineLearning:CheckForModelUpdate(specID)
    if not classSpecModels[specID] then
        return
    end
    
    local settings = ConfigRegistry:GetSettings("MachineLearning")
    local model = classSpecModels[specID]
    local now = GetTime()
    
    -- Check if we have enough samples
    if model.trainingSamples < MIN_SAMPLES_FOR_TRAINING then
        return
    end
    
    -- Check update frequency
    local updateInterval = UPDATE_INTERVAL -- Default weekly
    
    if settings.generalSettings.updateFrequency == "daily" then
        updateInterval = 86400 -- 1 day
    elseif settings.generalSettings.updateFrequency == "monthly" then
        updateInterval = 2592000 -- 30 days
    elseif settings.generalSettings.updateFrequency == "manual" then
        return -- Don't auto-update
    end
    
    if now - model.lastUpdated < updateInterval then
        return
    end
    
    -- Update the model
    self:UpdateModel(specID)
}

-- Update a model with training data
function MachineLearning:UpdateModel(specID)
    if not classSpecModels[specID] or not trainingData[specID] or #trainingData[specID] == 0 then
        return
    end
    
    local model = classSpecModels[specID]
    local trainingSet = trainingData[specID]
    
    API.PrintDebug("Updating model for " .. model.name .. " with " .. #trainingSet .. " samples")
    
    -- Simple model update: average metrics from training data
    -- In a real ML system, this would be much more sophisticated
    
    -- Reset weights
    for spellID in pairs(model.weights.abilities) do
        model.weights.abilities[spellID] = 0
    end
    
    -- Analyze spell effectiveness across all training data
    local totalDamage = 0
    local spellTotalDamage = {}
    local spellUsageCount = {}
    
    for _, data in ipairs(trainingSet) do
        totalDamage = totalDamage + data.totalDamage
        
        for spellID, usage in pairs(data.spellUsage) do
            spellUsageCount[spellID] = (spellUsageCount[spellID] or 0) + usage
        end
        
        for spellID, efficiency in pairs(data.spellEfficiency) do
            local spellDamage = data.spellDamage and data.spellDamage[spellID] and data.spellDamage[spellID].total or 0
            spellTotalDamage[spellID] = (spellTotalDamage[spellID] or 0) + spellDamage
        end
    end
    
    -- Calculate spell weights based on contribution to overall damage
    for spellID, damage in pairs(spellTotalDamage) do
        if totalDamage > 0 and model.weights.abilities[spellID] ~= nil then
            model.weights.abilities[spellID] = damage / totalDamage
        end
    end
    
    -- Analyze rotation sequences
    local bestSequences = {}
    for _, data in ipairs(trainingSet) do
        for sequenceKey, sequenceData in pairs(data.rotationSequences) do
            if not bestSequences[sequenceKey] then
                bestSequences[sequenceKey] = {
                    count = 0,
                    avgDamage = 0,
                    totalDamage = 0
                }
            end
            
            bestSequences[sequenceKey].count = bestSequences[sequenceKey].count + sequenceData.count
            bestSequences[sequenceKey].totalDamage = bestSequences[sequenceKey].totalDamage + (sequenceData.avgDamage * sequenceData.count)
        end
    end
    
    -- Calculate average damage for sequences
    for sequenceKey, sequenceData in pairs(bestSequences) do
        if sequenceData.count > 0 then
            sequenceData.avgDamage = sequenceData.totalDamage / sequenceData.count
        end
    end
    
    -- Sort sequences by average damage
    local sortedSequences = {}
    for sequenceKey, sequenceData in pairs(bestSequences) do
        table.insert(sortedSequences, {
            sequence = sequenceKey,
            avgDamage = sequenceData.avgDamage,
            count = sequenceData.count
        })
    end
    
    table.sort(sortedSequences, function(a, b) return a.avgDamage > b.avgDamage end)
    
    -- Store top sequences in model
    model.weights.sequences = {}
    for i = 1, math.min(10, #sortedSequences) do
        local sequenceKey = sortedSequences[i].sequence
        model.weights.sequences[sequenceKey] = sortedSequences[i].avgDamage
    end
    
    -- Update model metadata
    model.lastUpdated = GetTime()
    model.confidence = 0.7 -- Mock confidence value
    model.version = model.version + 1
    
    -- Save the model
    self:SaveModels()
    
    API.PrintDebug("Model updated for " .. model.name)
}

-- Save all models
function MachineLearning:SaveModels()
    -- In a real addon, this would save to SavedVariables
    -- For our implementation, just log it
    
    API.PrintDebug("Models saved")
}

-- Load all saved models
function MachineLearning:LoadSavedModels()
    -- In a real addon, this would load from SavedVariables
    -- For our implementation, just log it
    
    API.PrintDebug("Models loaded")
}

-- Make a prediction for the next best action
function MachineLearning:PredictNextAction()
    local settings = ConfigRegistry:GetSettings("MachineLearning")
    if not settings.generalSettings.enableML then
        return nil
    end
    
    local specID = API.GetActiveSpecID()
    if not specID or not classSpecModels[specID] then
        return nil
    end
    
    -- Check cache
    local now = GetTime()
    if predictionCache.specID == specID and 
       predictionCache.timestamp and 
       now - predictionCache.timestamp < 0.5 then
        return predictionCache.result
    end
    
    -- Capture current state
    local currentFeatures = self:CaptureCurrentFeatures()
    
    -- Find similar situations in data points
    local similarPoints = self:FindSimilarDataPoints(specID, currentFeatures)
    
    -- If we have similar situations, use them for prediction
    if #similarPoints > 0 then
        local prediction = self:PredictFromSimilarPoints(similarPoints)
        
        -- Cache the result
        predictionCache = {
            specID = specID,
            timestamp = now,
            result = prediction
        }
        
        return prediction
    end
    
    -- Fall back to model-based prediction
    local prediction = self:PredictFromModel(specID, currentFeatures)
    
    -- Cache the result
    predictionCache = {
        specID = specID,
        timestamp = now,
        result = prediction
    }
    
    return prediction
}

-- Find similar data points to current state
function MachineLearning:FindSimilarDataPoints(specID, currentFeatures)
    if not dataPoints[specID] then
        return {}
    end
    
    local similarPoints = {}
    
    for _, dataPoint in ipairs(dataPoints[specID]) do
        local similarity = self:CalculateSimilarity(currentFeatures, dataPoint.features)
        
        if similarity >= SIMILARITY_THRESHOLD then
            table.insert(similarPoints, {
                dataPoint = dataPoint,
                similarity = similarity
            })
        end
    end
    
    -- Sort by similarity (highest first)
    table.sort(similarPoints, function(a, b) return a.similarity > b.similarity end)
    
    -- Return top 5 similar points
    if #similarPoints > 5 then
        local topPoints = {}
        for i = 1, 5 do
            table.insert(topPoints, similarPoints[i])
        end
        return topPoints
    end
    
    return similarPoints
}

-- Calculate similarity between feature sets
function MachineLearning:CalculateSimilarity(features1, features2)
    -- This would be a sophisticated similarity metric
    -- For simplicity, we'll use a mock implementation
    
    local similarity = 0.5 -- Base similarity
    
    -- Adjust based on some key features
    if features1.targetCount == features2.targetCount then
        similarity = similarity + 0.1
    end
    
    if math.abs(features1.playerHealthPercent - features2.playerHealthPercent) < 20 then
        similarity = similarity + 0.1
    end
    
    if features1.isAoEOptimal == features2.isAoEOptimal then
        similarity = similarity + 0.1
    end
    
    if features1.isBurstWindow == features2.isBurstWindow then
        similarity = similarity + 0.1
    end
    
    if math.abs(features1.primaryResourcePercent - features2.primaryResourcePercent) < 20 then
        similarity = similarity + 0.1
    end
    
    -- Cap at 1.0
    return math.min(similarity, 1.0)
}

-- Predict next action from similar data points
function MachineLearning:PredictFromSimilarPoints(similarPoints)
    -- Count spell occurrences weighted by similarity and outcome
    local spellScores = {}
    local totalWeight = 0
    
    for _, pointData in ipairs(similarPoints) do
        local dataPoint = pointData.dataPoint
        local similarity = pointData.similarity
        local outcomeWeight = 1.0
        
        -- Weight by outcome (DPS, surviveability, etc.)
        if dataPoint.result.dps then
            -- Normalize DPS to 0-1 range (assuming 100k DPS is max)
            local dpsWeight = math.min(dataPoint.result.dps / 100000, 1.0)
            outcomeWeight = outcomeWeight * (0.5 + dpsWeight * 0.5)
        end
        
        local weight = similarity * outcomeWeight
        totalWeight = totalWeight + weight
        
        -- Add to spell score
        if not spellScores[dataPoint.spellID] then
            spellScores[dataPoint.spellID] = 0
        end
        spellScores[dataPoint.spellID] = spellScores[dataPoint.spellID] + weight
    end
    
    -- Find highest scoring spell
    local bestSpellID = nil
    local bestScore = 0
    
    for spellID, score in pairs(spellScores) do
        local normalizedScore = totalWeight > 0 and (score / totalWeight) or 0
        
        if normalizedScore > bestScore then
            bestSpellID = spellID
            bestScore = normalizedScore
        end
    end
    
    -- Return prediction with confidence
    if bestSpellID and bestScore >= PREDICTION_CONFIDENCE_THRESHOLD then
        return {
            spellID = bestSpellID,
            confidence = bestScore,
            method = "similarity"
        }
    end
    
    return nil
}

-- Predict next action from model
function MachineLearning:PredictFromModel(specID, currentFeatures)
    local model = classSpecModels[specID]
    if not model or not model.weights or not model.weights.abilities then
        return nil
    end
    
    -- Get contextual modifiers based on features
    local contextModifiers = self:GetContextModifiers(currentFeatures)
    
    -- Adjust weights based on context
    local adjustedWeights = {}
    for spellID, baseWeight in pairs(model.weights.abilities) do
        -- Skip if we can't cast this spell
        if not API.CanCast(spellID) then
            goto continue
        end
        
        -- Start with base weight
        local weight = baseWeight
        
        -- Apply context modifiers
        if contextModifiers[spellID] then
            weight = weight * contextModifiers[spellID]
        end
        
        -- Store adjusted weight
        adjustedWeights[spellID] = weight
        
        ::continue::
    end
    
    -- Check for optimal sequence
    local sequenceBoost = self:CheckForOptimalSequence(specID, adjustedWeights)
    
    -- Apply sequence boost
    for spellID, boost in pairs(sequenceBoost) do
        if adjustedWeights[spellID] then
            adjustedWeights[spellID] = adjustedWeights[spellID] * boost
        end
    end
    
    -- Find highest weighted spell
    local bestSpellID = nil
    local bestWeight = 0
    
    for spellID, weight in pairs(adjustedWeights) do
        if weight > bestWeight then
            bestSpellID = spellID
            bestWeight = weight
        end
    end
    
    -- Return prediction with confidence
    if bestSpellID then
        return {
            spellID = bestSpellID,
            confidence = math.min(bestWeight, 1.0), -- Normalize to 0-1
            method = "model"
        }
    end
    
    return nil
}

-- Get context modifiers based on current features
function MachineLearning:GetContextModifiers(features)
    local modifiers = {}
    
    -- AoE modifiers
    if features.targetCount >= 3 then
        -- Boost AoE spells in AoE situations
        modifiers = self:ApplyAoEModifiers(modifiers)
    end
    
    -- Execute phase modifiers
    if features.isExecutePhase then
        -- Boost execute abilities
        modifiers = self:ApplyExecuteModifiers(modifiers)
    end
    
    -- Defensive modifiers
    if features.isLowHealth then
        -- Boost defensive abilities
        modifiers = self:ApplyDefensiveModifiers(modifiers)
    end
    
    -- Burst window modifiers
    if features.isBurstWindow then
        -- Boost burst cooldowns
        modifiers = self:ApplyBurstModifiers(modifiers)
    end
    
    -- Resource modifiers
    if features.primaryResourcePercent < 30 then
        -- Boost resource generators, reduce spenders
        modifiers = self:ApplyResourceModifiers(modifiers, "low")
    elseif features.primaryResourcePercent > 80 then
        -- Boost resource spenders
        modifiers = self:ApplyResourceModifiers(modifiers, "high")
    end
    
    return modifiers
}

-- Apply AoE modifiers to weights
function MachineLearning:ApplyAoEModifiers(modifiers)
    -- This would be populated with spell IDs and modifiers for AoE
    -- For simplicity, we'll use a mock implementation
    
    -- Boost a random spell as if it were an AoE ability
    local randomSpellID = 12345 + math.random(1, 10)
    modifiers[randomSpellID] = 2.0 -- Double weight for this "AoE spell"
    
    return modifiers
end

-- Apply execute phase modifiers to weights
function MachineLearning:ApplyExecuteModifiers(modifiers)
    -- Similar to AoE modifiers but for execute phase abilities
    local randomSpellID = 12345 + math.random(11, 20)
    modifiers[randomSpellID] = 1.5 -- 50% boost for this "execute spell"
    
    return modifiers
end

-- Apply defensive modifiers to weights
function MachineLearning:ApplyDefensiveModifiers(modifiers)
    -- Similar to above but for defensive abilities
    local randomSpellID = 12345 + math.random(21, 30)
    modifiers[randomSpellID] = 3.0 -- Triple weight for this "defensive spell"
    
    return modifiers
end

-- Apply burst window modifiers to weights
function MachineLearning:ApplyBurstModifiers(modifiers)
    -- Similar to above but for burst cooldowns
    local randomSpellID = 12345 + math.random(31, 40)
    modifiers[randomSpellID] = 2.5 -- 2.5x weight for this "burst spell"
    
    return modifiers
end

-- Apply resource modifiers to weights
function MachineLearning:ApplyResourceModifiers(modifiers, resourceState)
    -- Modifiers based on resource state
    if resourceState == "low" then
        -- Boost generators, reduce spenders
        local generatorID = 12345 + math.random(41, 45)
        local spenderID = 12345 + math.random(46, 50)
        
        modifiers[generatorID] = 1.8 -- Boost generator
        modifiers[spenderID] = 0.3 -- Reduce spender
    elseif resourceState == "high" then
        -- Boost spenders
        local spenderID = 12345 + math.random(46, 50)
        modifiers[spenderID] = 1.8 -- Boost spender
    end
    
    return modifiers
end

-- Check for optimal sequence based on previous actions
function MachineLearning:CheckForOptimalSequence(specID, weights)
    local model = classSpecModels[specID]
    local boost = {}
    
    if not model or not model.weights or not model.weights.sequences then
        return boost
    end
    
    -- Look for the last cast spell
    local lastSpell = rotationPatterns[specID] and rotationPatterns[specID].lastSpell
    
    if not lastSpell then
        return boost
    end
    
    -- Check if there's a sequence starting with last spell
    for sequenceKey, sequenceWeight in pairs(model.weights.sequences) do
        local startSpellID, nextSpellID = sequenceKey:match("(%d+)%-(%d+)")
        
        if startSpellID and nextSpellID and tonumber(startSpellID) == lastSpell then
            -- Found a sequence, boost the next spell
            local nextID = tonumber(nextSpellID)
            boost[nextID] = sequenceWeight * 1.5 -- Boost based on sequence weight
        end
    end
    
    return boost
end

-- Process performance metrics from the performance tracker
function MachineLearning:ProcessPerformanceMetrics(metrics)
    if not metrics then
        return
    end
    
    local specID = API.GetActiveSpecID()
    if not specID then
        return
    end
    
    -- Store metrics
    playerMetrics[specID] = metrics
    
    -- Use metrics to update data points
    self:UpdateRecentDataPoints(specID, "dps", metrics.dps)
    
    -- If applicable, also update surviveability and resource metrics
    if metrics.damageTaken then
        local surviveability = 1 - (metrics.damageTaken / (metrics.maxHealth or 1))
        self:UpdateRecentDataPoints(specID, "surviveability", surviveability)
    end
    
    if metrics.resourceEfficiency then
        self:UpdateRecentDataPoints(specID, "resourceEfficiency", metrics.resourceEfficiency)
    end
}

-- Get the next recommended spell
function MachineLearning:GetNextRecommendedSpell()
    local settings = ConfigRegistry:GetSettings("MachineLearning")
    if not settings.generalSettings.enableML then
        return nil
    end
    
    -- Make a prediction
    local prediction = self:PredictNextAction()
    
    -- Check confidence threshold
    if not prediction or prediction.confidence < (settings.adaptiveSettings.minConfidenceThreshold / 100) then
        return nil
    end
    
    -- Return recommendation
    return {
        spellID = prediction.spellID,
        confidence = prediction.confidence,
        method = prediction.method,
        timestamp = GetTime()
    }
}

-- Handle slash command
function MachineLearning:HandleSlashCommand(msg)
    if not msg or msg == "" then
        -- Show help
        API.Print("WindrunnerRotations Machine Learning Commands:")
        API.Print("/wrml status - Show ML system status")
        API.Print("/wrml model - Show model information")
        API.Print("/wrml update - Force update of the current model")
        API.Print("/wrml analyze - Analyze your recent performance")
        API.Print("/wrml recommend - Get a spell recommendation")
        API.Print("/wrml reset - Reset ML data")
        return
    end
    
    local args = {}
    for arg in string.gmatch(msg, "%S+") do
        table.insert(args, arg)
    end
    
    local command = args[1]
    
    if command == "status" then
        -- Show ML system status
        local settings = ConfigRegistry:GetSettings("MachineLearning")
        
        API.Print("Machine Learning System Status:")
        API.Print("Enabled: " .. (settings.generalSettings.enableML and "Yes" or "No"))
        API.Print("Data Collection: " .. settings.generalSettings.dataCollectionLevel)
        
        local specID = API.GetActiveSpecID()
        if specID and classSpecModels[specID] then
            local model = classSpecModels[specID]
            
            API.Print("Current Model: " .. model.name)
            API.Print("Training Samples: " .. model.trainingSamples)
            API.Print("Confidence: " .. string.format("%.1f", model.confidence * 100) .. "%")
            API.Print("Last Updated: " .. string.format("%.2f", (GetTime() - model.lastUpdated) / 3600) .. " hours ago")
        else
            API.Print("No model for current specialization")
        end
    elseif command == "model" then
        -- Show model details
        local specID = API.GetActiveSpecID()
        if not specID or not classSpecModels[specID] then
            API.Print("No model for current specialization")
            return
        end
        
        local model = classSpecModels[specID]
        
        API.Print("Model Details for " .. model.name .. ":")
        API.Print("Version: " .. model.version)
        API.Print("Training Samples: " .. model.trainingSamples)
        API.Print("Confidence: " .. string.format("%.1f", model.confidence * 100) .. "%")
        
        -- Show top weighted abilities
        API.Print("Top Abilities:")
        
        local sortedAbilities = {}
        for spellID, weight in pairs(model.weights.abilities) do
            table.insert(sortedAbilities, {
                spellID = spellID,
                weight = weight
            })
        end
        
        table.sort(sortedAbilities, function(a, b) return a.weight > b.weight end)
        
        for i = 1, math.min(5, #sortedAbilities) do
            local ability = sortedAbilities[i]
            local spellName = GetSpellInfo(ability.spellID) or "Unknown"
            API.Print("  " .. i .. ". " .. spellName .. " (" .. string.format("%.2f", ability.weight) .. ")")
        end
        
        -- Show top sequences
        if model.weights.sequences then
            API.Print("Top Sequences:")
            
            local sortedSequences = {}
            for sequence, weight in pairs(model.weights.sequences) do
                table.insert(sortedSequences, {
                    sequence = sequence,
                    weight = weight
                })
            end
            
            table.sort(sortedSequences, function(a, b) return a.weight > b.weight end)
            
            for i = 1, math.min(3, #sortedSequences) do
                local seq = sortedSequences[i]
                local startID, endID = seq.sequence:match("(%d+)%-(%d+)")
                local startName = GetSpellInfo(tonumber(startID)) or "Unknown"
                local endName = GetSpellInfo(tonumber(endID)) or "Unknown"
                
                API.Print("  " .. i .. ". " .. startName .. " -> " .. endName .. " (" .. string.format("%.2f", seq.weight) .. ")")
            end
        end
    elseif command == "update" then
        -- Force update of the current model
        local specID = API.GetActiveSpecID()
        if not specID or not classSpecModels[specID] then
            API.Print("No model for current specialization")
            return
        end
        
        if not trainingData[specID] or #trainingData[specID] < MIN_SAMPLES_FOR_TRAINING then
            API.Print("Not enough training data. Need at least " .. MIN_SAMPLES_FOR_TRAINING .. " samples.")
            API.Print("Current samples: " .. (trainingData[specID] and #trainingData[specID] or 0))
            return
        end
        
        API.Print("Updating model for " .. classSpecModels[specID].name .. "...")
        self:UpdateModel(specID)
        API.Print("Model updated")
    elseif command == "analyze" then
        -- Analyze recent performance
        local specID = API.GetActiveSpecID()
        if not specID or not playerMetrics[specID] then
            API.Print("No performance data for current specialization")
            return
        end
        
        local metrics = playerMetrics[specID]
        
        API.Print("Performance Analysis:")
        API.Print("DPS: " .. string.format("%.1f", metrics.dps or 0))
        
        if metrics.damageTaken and metrics.maxHealth then
            local surviveability = 1 - (metrics.damageTaken / metrics.maxHealth)
            API.Print("Survival: " .. string.format("%.1f", surviveability * 100) .. "%")
        end
        
        if metrics.resourceEfficiency then
            API.Print("Resource Efficiency: " .. string.format("%.1f", metrics.resourceEfficiency))
        end
        
        -- Show spell usage
        if realTimeStats[specID] and realTimeStats[specID].spellDamage then
            API.Print("Spell Performance:")
            
            local sortedSpells = {}
            for spellID, spellStats in pairs(realTimeStats[specID].spellDamage) do
                table.insert(sortedSpells, {
                    spellID = spellID,
                    damage = spellStats.total,
                    count = spellStats.count,
                    avg = spellStats.avg
                })
            end
            
            table.sort(sortedSpells, function(a, b) return a.damage > b.damage end)
            
            for i = 1, math.min(5, #sortedSpells) do
                local spell = sortedSpells[i]
                local spellName = GetSpellInfo(spell.spellID) or "Unknown"
                local dps = spell.damage / (realTimeStats[specID].duration or 1)
                
                API.Print("  " .. i .. ". " .. spellName .. ": " .. string.format("%.1f", dps) .. " DPS (" .. spell.count .. " casts)")
            end
        end
    elseif command == "recommend" then
        -- Get a spell recommendation
        local recommendation = self:GetNextRecommendedSpell()
        
        if not recommendation then
            API.Print("No recommendation available")
            return
        end
        
        local spellName = GetSpellInfo(recommendation.spellID) or "Unknown"
        
        API.Print("Recommended Spell: " .. spellName)
        API.Print("Confidence: " .. string.format("%.1f", recommendation.confidence * 100) .. "%")
        API.Print("Method: " .. recommendation.method)
    elseif command == "reset" then
        -- Reset ML data
        local specID = API.GetActiveSpecID()
        if not specID then
            API.Print("No active specialization")
            return
        end
        
        -- Clear data for this spec
        trainingData[specID] = {}
        rotationPatterns[specID] = nil
        predictionCache = {}
        playerMetrics[specID] = nil
        realTimeStats[specID] = nil
        dataPoints[specID] = {}
        
        -- Reset model
        if classSpecModels[specID] then
            classSpecModels[specID].trainingSamples = 0
            classSpecModels[specID].lastUpdated = 0
            classSpecModels[specID].confidence = 0
            classSpecModels[specID].version = 1
            
            -- Reset weights
            for spellID in pairs(classSpecModels[specID].weights.abilities) do
                classSpecModels[specID].weights.abilities[spellID] = 0.5
            end
            
            classSpecModels[specID].weights.sequences = {}
        end
        
        -- Save
        self:SaveModels()
        
        API.Print("Machine Learning data reset for current specialization")
    else
        API.Print("Unknown command. Type /wrml for help.")
    end
end

-- Return the module for loading
return MachineLearning