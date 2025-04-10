local addonName, WR = ...

-- LearningSystem module for adaptive rotations and intelligent improvements
local LearningSystem = {}
WR.LearningSystem = LearningSystem

-- Constants
local MAX_SAMPLES = 1000
local MIN_SAMPLES_FOR_LEARNING = 50
local LEARNING_CYCLE_TIME = 300 -- 5 minutes between learning cycles
local MAX_ABILITY_WEIGHTS = 100
local DEFAULT_ABILITY_WEIGHT = 50
local LEARNING_RATE = 0.05

-- Data storage
local learningData = {
    combatSamples = {},
    abilityWeights = {},
    abilityPerformance = {},
    abilityUsage = {},
    resourceMetrics = {},
    sequenceEfficiency = {},
    talentPerformance = {},
    encounterSpecificData = {},
    adaptiveRules = {},
    performanceHistory = {},
    learningCycles = 0,
    lastLearnTime = 0
}

-- Configuration
local config = {
    enabled = true,
    learningRate = 5, -- 1-10, higher is more aggressive learning
    adaptRotations = true, -- Whether to adapt rotations based on learning
    personalizedWeights = true, -- Whether to use personalized ability weights
    resetOnSpecChange = true, -- Reset learning when spec changes
    resetOnMajorPatch = true, -- Reset learning on major game patches
    shareLearningData = false, -- Whether to share learning data with the community
    useCommunityData = false, -- Whether to incorporate community learning data
    preventRegression = true, -- Prevent performance regression from bad samples
    enableExperimentation = false, -- Try experimental ability sequences
    loggingLevel = 2 -- 0-3, higher is more detailed logging
}

-- Initialize the learning system
function LearningSystem:Initialize()
    -- Load saved data
    if WindrunnerRotationsDB and WindrunnerRotationsDB.LearningSystem then
        local savedData = WindrunnerRotationsDB.LearningSystem
        
        -- Load configuration
        if savedData.config then
            for k, v in pairs(savedData.config) do
                if config[k] ~= nil then
                    config[k] = v
                end
            end
        end
        
        -- Load learning data
        if savedData.data then
            -- Validate saved data structure
            if type(savedData.data) == "table" then
                -- Check for current class and spec data
                local _, class = UnitClass("player")
                local spec = GetSpecialization()
                
                if savedData.data[class] and savedData.data[class][spec] then
                    -- Copy relevant learning data for current class and spec
                    local specData = savedData.data[class][spec]
                    
                    if type(specData.abilityWeights) == "table" then
                        learningData.abilityWeights = CopyTable(specData.abilityWeights)
                    end
                    
                    if type(specData.abilityPerformance) == "table" then
                        learningData.abilityPerformance = CopyTable(specData.abilityPerformance)
                    end
                    
                    if type(specData.abilityUsage) == "table" then
                        learningData.abilityUsage = CopyTable(specData.abilityUsage)
                    end
                    
                    if type(specData.adaptiveRules) == "table" then
                        learningData.adaptiveRules = CopyTable(specData.adaptiveRules)
                    end
                    
                    learningData.learningCycles = specData.learningCycles or 0
                    learningData.lastLearnTime = specData.lastLearnTime or 0
                end
            end
        end
    end
    
    -- Set default ability weights if needed
    self:InitializeDefaultWeights()
    
    -- Register events
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("PLAYER_LOGOUT")
    eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "PLAYER_ENTERING_WORLD" then
            -- Schedule learning cycle
            C_Timer.After(30, function()
                if config.enabled then
                    LearningSystem:RunLearningCycle()
                end
            end)
            
            -- Set up periodic learning
            C_Timer.NewTicker(LEARNING_CYCLE_TIME, function() 
                if config.enabled then
                    LearningSystem:RunLearningCycle()
                end
            end)
        elseif event == "PLAYER_LOGOUT" then
            LearningSystem:SaveLearningData()
        elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
            if config.resetOnSpecChange then
                LearningSystem:ResetLearningData()
            end
            
            -- Re-initialize default weights
            LearningSystem:InitializeDefaultWeights()
        elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
            if config.enabled then
                LearningSystem:ProcessCombatEvent(CombatLogGetCurrentEventInfo())
            end
        end
    end)
    
    -- Register with rotation system
    if WR.Rotation then
        -- Register ability recommendation modifier
        WR.Rotation:RegisterModifier("learning", function(abilities)
            return LearningSystem:ModifyAbilityRecommendations(abilities)
        end, 50) -- Medium priority
    end
    
    WR:Debug("Learning system initialized")
}

-- Save learning data
function LearningSystem:SaveLearningData()
    -- Initialize storage if needed
    WindrunnerRotationsDB = WindrunnerRotationsDB or {}
    WindrunnerRotationsDB.LearningSystem = {
        config = CopyTable(config),
        data = {}
    }
    
    -- Structure data by class and spec
    local _, class = UnitClass("player")
    local spec = GetSpecialization()
    
    if not class or not spec then return end
    
    -- Initialize class and spec tables
    WindrunnerRotationsDB.LearningSystem.data[class] = WindrunnerRotationsDB.LearningSystem.data[class] or {}
    WindrunnerRotationsDB.LearningSystem.data[class][spec] = {}
    
    -- Save learning data for current class and spec
    local specData = WindrunnerRotationsDB.LearningSystem.data[class][spec]
    
    specData.abilityWeights = CopyTable(learningData.abilityWeights)
    specData.abilityPerformance = CopyTable(learningData.abilityPerformance)
    specData.abilityUsage = CopyTable(learningData.abilityUsage)
    specData.adaptiveRules = CopyTable(learningData.adaptiveRules)
    specData.learningCycles = learningData.learningCycles
    specData.lastLearnTime = learningData.lastLearnTime
    
    WR:Debug("Learning data saved")
}

-- Initialize default ability weights
function LearningSystem:InitializeDefaultWeights()
    -- Get class and spec
    local _, class = UnitClass("player")
    local spec = GetSpecialization()
    
    if not class or not spec then return end
    
    -- Get abilities for current class and spec
    local abilities = self:GetClassAbilities(class, spec)
    
    -- Set default weights for abilities that don't have weights
    for spellID, abilityInfo in pairs(abilities) do
        if not learningData.abilityWeights[spellID] then
            learningData.abilityWeights[spellID] = DEFAULT_ABILITY_WEIGHT
        end
        
        -- Initialize performance data if needed
        if not learningData.abilityPerformance[spellID] then
            learningData.abilityPerformance[spellID] = {
                successRate = 0,
                damagePerCast = 0,
                effectivenessScore = 0,
                sampleSize = 0
            }
        end
        
        -- Initialize usage data if needed
        if not learningData.abilityUsage[spellID] then
            learningData.abilityUsage[spellID] = {
                totalUses = 0,
                successfulUses = 0,
                failedUses = 0,
                averageDamage = 0,
                lastUsed = 0
            }
        end
    end
    
    WR:Debug("Default ability weights initialized")
}

-- Get abilities for a class and spec
function LearningSystem:GetClassAbilities(class, spec)
    -- This would normally get the abilities from the class modules
    -- For this demonstration, we'll return some example abilities
    
    local abilities = {}
    
    -- Get basic abilities for all classes
    abilities[5308] = {name = "Execute", type = "damage"} -- Example ability
    abilities[7384] = {name = "Overpower", type = "damage"} -- Example ability
    abilities[23881] = {name = "Bloodthirst", type = "damage"} -- Example ability
    abilities[1464] = {name = "Slam", type = "damage"} -- Example ability
    abilities[12294] = {name = "Mortal Strike", type = "damage"} -- Example ability
    
    -- In a real implementation, this would query the class modules
    -- or the game API to get the actual abilities for the class and spec
    
    return abilities
}

-- Process combat event
function LearningSystem:ProcessCombatEvent(...)
    local timestamp, subEvent, _, sourceGUID, sourceName, sourceFlags, sourceRaidFlags,
          destGUID, destName, destFlags, destRaidFlags, param1, param2, param3, param4, param5 = ...
    
    -- Only process events from the player
    if sourceGUID ~= UnitGUID("player") then return end
    
    -- Process ability usage
    if subEvent == "SPELL_CAST_SUCCESS" then
        local spellID = param1
        self:RecordAbilityUse(spellID, true)
    elseif subEvent == "SPELL_CAST_FAILED" then
        local spellID = param1
        self:RecordAbilityUse(spellID, false)
    elseif subEvent == "SPELL_DAMAGE" or subEvent == "SPELL_PERIODIC_DAMAGE" then
        local spellID = param1
        local amount = param4
        
        -- Record damage for this ability
        self:RecordAbilityDamage(spellID, amount)
    end
    
    -- Collect combat sample
    if self:ShouldCollectSample(subEvent) then
        self:CollectCombatSample(timestamp, subEvent, sourceGUID, destGUID, param1, param4)
    end
}

-- Record ability use
function LearningSystem:RecordAbilityUse(spellID, success)
    if not spellID then return end
    
    -- Initialize ability usage if needed
    if not learningData.abilityUsage[spellID] then
        learningData.abilityUsage[spellID] = {
            totalUses = 0,
            successfulUses = 0,
            failedUses = 0,
            averageDamage = 0,
            lastUsed = 0
        }
    end
    
    -- Update usage statistics
    local usage = learningData.abilityUsage[spellID]
    usage.totalUses = usage.totalUses + 1
    
    if success then
        usage.successfulUses = usage.successfulUses + 1
    else
        usage.failedUses = usage.failedUses + 1
    end
    
    usage.lastUsed = GetTime()
}

-- Record ability damage
function LearningSystem:RecordAbilityDamage(spellID, amount)
    if not spellID or not amount then return end
    
    -- Initialize ability usage if needed
    if not learningData.abilityUsage[spellID] then
        learningData.abilityUsage[spellID] = {
            totalUses = 0,
            successfulUses = 0,
            failedUses = 0,
            averageDamage = 0,
            lastUsed = 0
        }
    end
    
    -- Update damage statistics
    local usage = learningData.abilityUsage[spellID]
    
    if usage.successfulUses > 0 then
        -- Calculate new average damage
        local totalDamage = usage.averageDamage * (usage.successfulUses - 1)
        totalDamage = totalDamage + amount
        usage.averageDamage = totalDamage / usage.successfulUses
    else
        -- First damage recording
        usage.averageDamage = amount
    end
}

-- Check if we should collect a combat sample
function LearningSystem:ShouldCollectSample(subEvent)
    -- Only collect samples for certain events
    local relevantEvents = {
        "SPELL_DAMAGE",
        "SPELL_PERIODIC_DAMAGE",
        "SPELL_HEAL",
        "SPELL_PERIODIC_HEAL",
        "SPELL_CAST_SUCCESS",
        "SPELL_AURA_APPLIED",
        "SPELL_AURA_REFRESH",
        "SPELL_AURA_REMOVED"
    }
    
    for _, event in ipairs(relevantEvents) do
        if subEvent == event then
            return true
        end
    end
    
    return false
}

-- Collect a combat sample
function LearningSystem:CollectCombatSample(timestamp, subEvent, sourceGUID, destGUID, spellID, amount)
    -- Ensure we don't exceed the maximum sample size
    if #learningData.combatSamples >= MAX_SAMPLES then
        table.remove(learningData.combatSamples, 1)
    end
    
    -- Create a new sample
    local sample = {
        timestamp = timestamp,
        event = subEvent,
        spellID = spellID,
        amount = amount,
        playerHealth = UnitHealth("player") / UnitHealthMax("player") * 100,
        targetHealth = UnitExists("target") and (UnitHealth("target") / UnitHealthMax("target") * 100) or 0,
        inCombat = UnitAffectingCombat("player"),
        resources = self:GetCurrentResources(),
        targetCount = self:GetTargetCount(),
        sequence = self:GetRecentAbilitySequence()
    }
    
    -- Add to samples
    table.insert(learningData.combatSamples, sample)
}

-- Get current player resources
function LearningSystem:GetCurrentResources()
    local resources = {}
    local _, class = UnitClass("player")
    
    -- Get primary resource
    resources.primary = {
        type = "mana", -- Default
        current = UnitPower("player"),
        max = UnitPowerMax("player")
    }
    
    -- Add class-specific resources
    if class == "ROGUE" or class == "DRUID" then
        resources.comboPoints = UnitPower("player", Enum.PowerType.ComboPoints)
    elseif class == "WARLOCK" then
        resources.soulShards = UnitPower("player", Enum.PowerType.SoulShards)
    elseif class == "PALADIN" then
        resources.holyPower = UnitPower("player", Enum.PowerType.HolyPower)
    -- Add more class-specific resources as needed
    end
    
    return resources
}

-- Get approximate target count
function LearningSystem:GetTargetCount()
    local count = 0
    
    -- Count enemies in combat with player
    local totalUnits = 0
    for i = 1, 40 do
        local unit = "nameplate" .. i
        if UnitExists(unit) and UnitCanAttack("player", unit) and UnitAffectingCombat(unit) then
            count = count + 1
        end
        
        totalUnits = totalUnits + 1
        if totalUnits >= 40 then break end
    end
    
    -- If no enemies found via nameplates, check target and its target
    if count == 0 and UnitExists("target") and UnitCanAttack("player", "target") then
        count = 1
    end
    
    return count
}

-- Get recent ability sequence
function LearningSystem:GetRecentAbilitySequence()
    -- Reconstruct recent ability sequence from combat samples
    local sequence = {}
    local lookback = 5 -- Number of abilities to track
    
    for i = #learningData.combatSamples - lookback, #learningData.combatSamples - 1 do
        if i >= 1 then
            local sample = learningData.combatSamples[i]
            if sample.event == "SPELL_CAST_SUCCESS" then
                table.insert(sequence, sample.spellID)
            end
        end
    end
    
    return sequence
}

-- Run a learning cycle
function LearningSystem:RunLearningCycle()
    if not config.enabled then return end
    
    -- Don't run learning too frequently
    local currentTime = GetTime()
    if currentTime - learningData.lastLearnTime < LEARNING_CYCLE_TIME / 2 then
        return
    end
    
    WR:Debug("Running learning cycle")
    
    -- Ensure we have enough samples
    if #learningData.combatSamples < MIN_SAMPLES_FOR_LEARNING then
        WR:Debug("Not enough samples for learning:", #learningData.combatSamples, "/", MIN_SAMPLES_FOR_LEARNING)
        return
    end
    
    -- Analyze combat samples
    self:AnalyzeCombatSamples()
    
    -- Update ability weights
    self:UpdateAbilityWeights()
    
    -- Derive adaptive rules
    self:DeriveAdaptiveRules()
    
    -- Update learning data
    learningData.learningCycles = learningData.learningCycles + 1
    learningData.lastLearnTime = currentTime
    
    -- Clear old samples
    if #learningData.combatSamples > MAX_SAMPLES / 2 then
        for i = 1, math.floor(MAX_SAMPLES / 4) do
            table.remove(learningData.combatSamples, 1)
        end
    end
    
    WR:Debug("Learning cycle completed. Total cycles:", learningData.learningCycles)
    
    -- Save learning data
    self:SaveLearningData()
}

-- Analyze combat samples
function LearningSystem:AnalyzeCombatSamples()
    -- Reset ability performance data
    for spellID, _ in pairs(learningData.abilityWeights) do
        learningData.abilityPerformance[spellID] = learningData.abilityPerformance[spellID] or {
            successRate = 0,
            damagePerCast = 0,
            effectivenessScore = 0,
            sampleSize = 0
        }
        
        -- Keep old sample size for weighted averaging
        local oldSampleSize = learningData.abilityPerformance[spellID].sampleSize or 0
        
        -- Reset metrics for this analysis
        learningData.abilityPerformance[spellID].newSuccessCount = 0
        learningData.abilityPerformance[spellID].newCastCount = 0
        learningData.abilityPerformance[spellID].newDamageTotal = 0
        learningData.abilityPerformance[spellID].newSampleSize = 0
    end
    
    -- Process samples
    for _, sample in ipairs(learningData.combatSamples) do
        if sample.event == "SPELL_CAST_SUCCESS" then
            -- Count successful casts
            local spellID = sample.spellID
            
            if learningData.abilityPerformance[spellID] then
                learningData.abilityPerformance[spellID].newCastCount = 
                    (learningData.abilityPerformance[spellID].newCastCount or 0) + 1
                
                learningData.abilityPerformance[spellID].newSuccessCount = 
                    (learningData.abilityPerformance[spellID].newSuccessCount or 0) + 1
                
                learningData.abilityPerformance[spellID].newSampleSize = 
                    (learningData.abilityPerformance[spellID].newSampleSize or 0) + 1
            end
        elseif sample.event == "SPELL_DAMAGE" or sample.event == "SPELL_PERIODIC_DAMAGE" then
            -- Record damage
            local spellID = sample.spellID
            local amount = sample.amount or 0
            
            if learningData.abilityPerformance[spellID] then
                learningData.abilityPerformance[spellID].newDamageTotal = 
                    (learningData.abilityPerformance[spellID].newDamageTotal or 0) + amount
            end
        elseif sample.event == "SPELL_CAST_FAILED" then
            -- Count failed casts
            local spellID = sample.spellID
            
            if learningData.abilityPerformance[spellID] then
                learningData.abilityPerformance[spellID].newCastCount = 
                    (learningData.abilityPerformance[spellID].newCastCount or 0) + 1
                
                learningData.abilityPerformance[spellID].newSampleSize = 
                    (learningData.abilityPerformance[spellID].newSampleSize or 0) + 1
            end
        end
    end
    
    -- Update performance metrics
    for spellID, performance in pairs(learningData.abilityPerformance) do
        -- Calculate success rate
        if performance.newCastCount and performance.newCastCount > 0 then
            local newSuccessRate = performance.newSuccessCount / performance.newCastCount
            
            -- Blend with existing data
            if performance.sampleSize and performance.sampleSize > 0 then
                local oldWeight = performance.sampleSize / (performance.sampleSize + performance.newSampleSize)
                local newWeight = performance.newSampleSize / (performance.sampleSize + performance.newSampleSize)
                
                performance.successRate = (performance.successRate * oldWeight) + (newSuccessRate * newWeight)
            else
                performance.successRate = newSuccessRate
            end
        end
        
        -- Calculate damage per cast
        if performance.newSuccessCount and performance.newSuccessCount > 0 then
            local newDamagePerCast = performance.newDamageTotal / performance.newSuccessCount
            
            -- Blend with existing data
            if performance.sampleSize and performance.sampleSize > 0 then
                local oldWeight = performance.sampleSize / (performance.sampleSize + performance.newSampleSize)
                local newWeight = performance.newSampleSize / (performance.sampleSize + performance.newSampleSize)
                
                performance.damagePerCast = (performance.damagePerCast * oldWeight) + (newDamagePerCast * newWeight)
            else
                performance.damagePerCast = newDamagePerCast
            end
        end
        
        -- Calculate effectiveness score
        -- This is a combined metric that considers success rate and damage
        performance.effectivenessScore = performance.successRate * 
            (performance.damagePerCast / math.max(1, self:GetAverageDamagePerCast()))
        
        -- Update sample size
        performance.sampleSize = (performance.sampleSize or 0) + (performance.newSampleSize or 0)
        
        -- Clean up temporary fields
        performance.newSuccessCount = nil
        performance.newCastCount = nil
        performance.newDamageTotal = nil
        performance.newSampleSize = nil
    end
}

-- Get average damage per cast
function LearningSystem:GetAverageDamagePerCast()
    local totalDamage = 0
    local count = 0
    
    for _, performance in pairs(learningData.abilityPerformance) do
        if performance.damagePerCast and performance.damagePerCast > 0 then
            totalDamage = totalDamage + performance.damagePerCast
            count = count + 1
        end
    end
    
    if count > 0 then
        return totalDamage / count
    else
        return 1 -- Default to avoid division by zero
    end
}

-- Update ability weights
function LearningSystem:UpdateAbilityWeights()
    -- Get learning rate from config
    local learningRate = config.learningRate * LEARNING_RATE
    
    -- Update weights based on performance
    for spellID, performance in pairs(learningData.abilityPerformance) do
        if performance.sampleSize and performance.sampleSize > 0 then
            -- Get current weight
            local currentWeight = learningData.abilityWeights[spellID] or DEFAULT_ABILITY_WEIGHT
            
            -- Adjust weight based on effectiveness
            local targetWeight = DEFAULT_ABILITY_WEIGHT
            
            if performance.effectivenessScore > 1.0 then
                -- Above average effectiveness, increase weight up to 100
                targetWeight = DEFAULT_ABILITY_WEIGHT + 
                    (MAX_ABILITY_WEIGHTS - DEFAULT_ABILITY_WEIGHT) * 
                    math.min(1.0, performance.effectivenessScore - 1.0)
            elseif performance.effectivenessScore < 1.0 then
                -- Below average effectiveness, decrease weight down to 0
                targetWeight = DEFAULT_ABILITY_WEIGHT * performance.effectivenessScore
            end
            
            -- Apply learning rate
            local newWeight = currentWeight + (targetWeight - currentWeight) * learningRate
            
            -- Ensure weight is within bounds
            newWeight = math.max(0, math.min(MAX_ABILITY_WEIGHTS, newWeight))
            
            -- Update weight
            learningData.abilityWeights[spellID] = newWeight
            
            if config.loggingLevel >= 3 then
                WR:Debug("Updated weight for", GetSpellInfo(spellID) or spellID, 
                        "from", string.format("%.1f", currentWeight), 
                        "to", string.format("%.1f", newWeight), 
                        "(effectiveness:", string.format("%.2f", performance.effectivenessScore), ")")
            end
        end
    end
}

-- Derive adaptive rules
function LearningSystem:DeriveAdaptiveRules()
    -- Reset adaptive rules
    learningData.adaptiveRules = {}
    
    -- Derive rules for different scenarios
    
    -- Target count rules
    self:DeriveTargetCountRules()
    
    -- Resource threshold rules
    self:DeriveResourceRules()
    
    -- Health threshold rules
    self:DeriveHealthRules()
    
    -- Sequence optimization rules
    self:DeriveSequenceRules()
}

-- Derive rules based on target count
function LearningSystem:DeriveTargetCountRules()
    -- Analyze samples by target count
    local targetCountData = {}
    
    for _, sample in ipairs(learningData.combatSamples) do
        if sample.event == "SPELL_DAMAGE" or sample.event == "SPELL_PERIODIC_DAMAGE" then
            local targetCount = sample.targetCount or 1
            local spellID = sample.spellID
            local amount = sample.amount or 0
            
            -- Initialize data for this target count
            targetCountData[targetCount] = targetCountData[targetCount] or {}
            targetCountData[targetCount][spellID] = targetCountData[targetCount][spellID] or {
                totalDamage = 0,
                casts = 0,
                damagePerCast = 0
            }
            
            -- Update data
            targetCountData[targetCount][spellID].totalDamage = 
                targetCountData[targetCount][spellID].totalDamage + amount
            
            targetCountData[targetCount][spellID].casts = 
                targetCountData[targetCount][spellID].casts + 1
        end
    end
    
    -- Calculate damage per cast for each target count
    for targetCount, spells in pairs(targetCountData) do
        for spellID, data in pairs(spells) do
            if data.casts > 0 then
                data.damagePerCast = data.totalDamage / data.casts
            end
        end
    end
    
    -- Derive rules for each target count
    for targetCount, spells in pairs(targetCountData) do
        -- Get top performing spells for this target count
        local sortedSpells = {}
        for spellID, data in pairs(spells) do
            table.insert(sortedSpells, {
                spellID = spellID,
                damagePerCast = data.damagePerCast
            })
        end
        
        table.sort(sortedSpells, function(a, b)
            return a.damagePerCast > b.damagePerCast
        end)
        
        -- Create rules for the top spells
        for i = 1, math.min(3, #sortedSpells) do
            local spellData = sortedSpells[i]
            
            -- Add a rule for this spell at this target count
            local rule = {
                type = "targetCount",
                condition = {
                    targetCount = targetCount
                },
                action = {
                    spellID = spellData.spellID,
                    weightModifier = 20 * (3 - i + 1) -- Higher bonus for higher damage
                }
            }
            
            table.insert(learningData.adaptiveRules, rule)
        end
    end
}

-- Derive rules based on resource levels
function LearningSystem:DeriveResourceRules()
    -- Analyze samples by resource levels
    local resourceData = {}
    
    for _, sample in ipairs(learningData.combatSamples) do
        if sample.event == "SPELL_DAMAGE" or sample.event == "SPELL_PERIODIC_DAMAGE" then
            local resources = sample.resources or {}
            local primaryPct = resources.primary and 
                              (resources.primary.current / resources.primary.max * 100) or 50
            local spellID = sample.spellID
            local amount = sample.amount or 0
            
            -- Categorize into resource buckets (0-25%, 25-50%, 50-75%, 75-100%)
            local resourceBucket = math.floor(primaryPct / 25) + 1
            
            -- Initialize data for this resource bucket
            resourceData[resourceBucket] = resourceData[resourceBucket] or {}
            resourceData[resourceBucket][spellID] = resourceData[resourceBucket][spellID] or {
                totalDamage = 0,
                casts = 0,
                damagePerCast = 0
            }
            
            -- Update data
            resourceData[resourceBucket][spellID].totalDamage = 
                resourceData[resourceBucket][spellID].totalDamage + amount
            
            resourceData[resourceBucket][spellID].casts = 
                resourceData[resourceBucket][spellID].casts + 1
        end
    end
    
    -- Calculate damage per cast for each resource bucket
    for bucket, spells in pairs(resourceData) do
        for spellID, data in pairs(spells) do
            if data.casts > 0 then
                data.damagePerCast = data.totalDamage / data.casts
            end
        end
    end
    
    -- Derive rules for each resource bucket
    for bucket, spells in pairs(resourceData) do
        -- Convert bucket to resource range
        local minResource = (bucket - 1) * 25
        local maxResource = bucket * 25
        
        -- Get top performing spells for this resource range
        local sortedSpells = {}
        for spellID, data in pairs(spells) do
            table.insert(sortedSpells, {
                spellID = spellID,
                damagePerCast = data.damagePerCast
            })
        end
        
        table.sort(sortedSpells, function(a, b)
            return a.damagePerCast > b.damagePerCast
        end)
        
        -- Create rules for the top spells
        for i = 1, math.min(2, #sortedSpells) do
            local spellData = sortedSpells[i]
            
            -- Add a rule for this spell at this resource range
            local rule = {
                type = "resource",
                condition = {
                    resourceType = "primary",
                    minValue = minResource,
                    maxValue = maxResource
                },
                action = {
                    spellID = spellData.spellID,
                    weightModifier = 15 * (2 - i + 1) -- Higher bonus for higher damage
                }
            }
            
            table.insert(learningData.adaptiveRules, rule)
        end
    end
}

-- Derive rules based on health thresholds
function LearningSystem:DeriveHealthRules()
    -- Analyze samples by health levels
    local healthData = {}
    
    for _, sample in ipairs(learningData.combatSamples) do
        if sample.event == "SPELL_DAMAGE" or sample.event == "SPELL_PERIODIC_DAMAGE" then
            local playerHealth = sample.playerHealth or 100
            local targetHealth = sample.targetHealth or 100
            local spellID = sample.spellID
            local amount = sample.amount or 0
            
            -- Categorize into target health buckets (0-20%, 20-35%, 35-100%)
            local healthBucket
            if targetHealth <= 20 then
                healthBucket = "execute" -- Execute range
            elseif targetHealth <= 35 then
                healthBucket = "low" -- Low health
            else
                healthBucket = "normal" -- Normal health
            end
            
            -- Initialize data for this health bucket
            healthData[healthBucket] = healthData[healthBucket] or {}
            healthData[healthBucket][spellID] = healthData[healthBucket][spellID] or {
                totalDamage = 0,
                casts = 0,
                damagePerCast = 0
            }
            
            -- Update data
            healthData[healthBucket][spellID].totalDamage = 
                healthData[healthBucket][spellID].totalDamage + amount
            
            healthData[healthBucket][spellID].casts = 
                healthData[healthBucket][spellID].casts + 1
        end
    end
    
    -- Calculate damage per cast for each health bucket
    for bucket, spells in pairs(healthData) do
        for spellID, data in pairs(spells) do
            if data.casts > 0 then
                data.damagePerCast = data.totalDamage / data.casts
            end
        end
    end
    
    -- Derive rules for each health bucket
    for bucket, spells in pairs(healthData) do
        -- Get top performing spells for this health range
        local sortedSpells = {}
        for spellID, data in pairs(spells) do
            table.insert(sortedSpells, {
                spellID = spellID,
                damagePerCast = data.damagePerCast
            })
        end
        
        table.sort(sortedSpells, function(a, b)
            return a.damagePerCast > b.damagePerCast
        end)
        
        -- Create rules for the top spells
        for i = 1, math.min(2, #sortedSpells) do
            local spellData = sortedSpells[i]
            
            -- Create health condition based on bucket
            local condition = {
                targetHealth = {}
            }
            
            if bucket == "execute" then
                condition.targetHealth = {
                    min = 0,
                    max = 20
                }
            elseif bucket == "low" then
                condition.targetHealth = {
                    min = 20,
                    max = 35
                }
            else
                condition.targetHealth = {
                    min = 35,
                    max = 100
                }
            end
            
            -- Add a rule for this spell at this health range
            local rule = {
                type = "health",
                condition = condition,
                action = {
                    spellID = spellData.spellID,
                    weightModifier = 25 * (2 - i + 1) -- Higher bonus for execute range
                }
            }
            
            table.insert(learningData.adaptiveRules, rule)
        end
    end
}

-- Derive rules based on ability sequences
function LearningSystem:DeriveSequenceRules()
    -- This is a more complex analysis that would look for optimal ability sequences
    -- For this demonstration, we'll implement a simplified version
    
    -- Analyze spell sequences and their effectiveness
    local sequenceData = {}
    
    -- Process samples to find sequences
    for i = 3, #learningData.combatSamples do
        if learningData.combatSamples[i].event == "SPELL_DAMAGE" or 
           learningData.combatSamples[i].event == "SPELL_PERIODIC_DAMAGE" then
            
            -- Look for a 2-spell sequence that preceded this damage
            if learningData.combatSamples[i-1].event == "SPELL_CAST_SUCCESS" and
               learningData.combatSamples[i-2].event == "SPELL_CAST_SUCCESS" then
                
                local spell1 = learningData.combatSamples[i-2].spellID
                local spell2 = learningData.combatSamples[i-1].spellID
                local damageSpell = learningData.combatSamples[i].spellID
                local amount = learningData.combatSamples[i].amount or 0
                
                -- Skip if damage isn't from the second spell
                if spell2 ~= damageSpell then
                    goto continue
                end
                
                -- Create sequence key
                local sequenceKey = spell1 .. ":" .. spell2
                
                -- Initialize data for this sequence
                sequenceData[sequenceKey] = sequenceData[sequenceKey] or {
                    spell1 = spell1,
                    spell2 = spell2,
                    totalDamage = 0,
                    count = 0,
                    damagePerSequence = 0
                }
                
                -- Update data
                sequenceData[sequenceKey].totalDamage = 
                    sequenceData[sequenceKey].totalDamage + amount
                
                sequenceData[sequenceKey].count = 
                    sequenceData[sequenceKey].count + 1
            end
            
            ::continue::
        end
    end
    
    -- Calculate damage per sequence
    for key, data in pairs(sequenceData) do
        if data.count > 0 then
            data.damagePerSequence = data.totalDamage / data.count
        end
    end
    
    -- Get top performing sequences
    local sortedSequences = {}
    for key, data in pairs(sequenceData) do
        table.insert(sortedSequences, {
            key = key,
            data = data
        })
    end
    
    table.sort(sortedSequences, function(a, b)
        return a.data.damagePerSequence > b.data.damagePerSequence
    end)
    
    -- Create rules for the top sequences
    for i = 1, math.min(3, #sortedSequences) do
        local sequence = sortedSequences[i].data
        
        -- Add a rule for this sequence
        local rule = {
            type = "sequence",
            condition = {
                previousSpell = sequence.spell1
            },
            action = {
                spellID = sequence.spell2,
                weightModifier = 30 * (3 - i + 1) -- Higher bonus for better sequences
            }
        }
        
        table.insert(learningData.adaptiveRules, rule)
    end
}

-- Modify ability recommendations based on learning
function LearningSystem:ModifyAbilityRecommendations(abilities)
    if not config.enabled or not config.adaptRotations then
        return abilities
    end
    
    -- Apply ability weights
    for i, ability in ipairs(abilities) do
        local spellID = ability.spellId
        
        if learningData.abilityWeights[spellID] then
            local weight = learningData.abilityWeights[spellID]
            
            -- Convert weight to a score multiplier (0.5 to 1.5)
            local multiplier = 0.5 + (weight / MAX_ABILITY_WEIGHTS)
            
            -- Apply multiplier to ability score
            ability.score = ability.score * multiplier
            
            if config.loggingLevel >= 3 then
                WR:Debug("Applied weight", string.format("%.2f", weight), 
                        "to", GetSpellInfo(spellID) or spellID, 
                        "(multiplier:", string.format("%.2f", multiplier), ")")
            end
        end
    end
    
    -- Apply adaptive rules
    for _, rule in ipairs(learningData.adaptiveRules) do
        if self:RuleMatchesCurrentState(rule) then
            -- Find the ability this rule applies to
            for i, ability in ipairs(abilities) do
                if ability.spellId == rule.action.spellID then
                    -- Apply weight modifier
                    local modifier = rule.action.weightModifier / 100 -- Convert to multiplier
                    ability.score = ability.score * (1 + modifier)
                    
                    if config.loggingLevel >= 3 then
                        WR:Debug("Applied rule", rule.type, 
                                "to", GetSpellInfo(ability.spellId) or ability.spellId, 
                                "(modifier: +", string.format("%.0f", rule.action.weightModifier), "%)")
                    end
                    
                    break
                end
            end
        end
    end
    
    -- Re-sort abilities by score
    table.sort(abilities, function(a, b)
        return a.score > b.score
    end)
    
    return abilities
}

-- Check if a rule matches the current state
function LearningSystem:RuleMatchesCurrentState(rule)
    if rule.type == "targetCount" then
        local currentTargetCount = self:GetTargetCount()
        
        return currentTargetCount == rule.condition.targetCount
    elseif rule.type == "resource" then
        local resources = self:GetCurrentResources()
        
        if rule.condition.resourceType == "primary" and resources.primary then
            local currentPct = resources.primary.current / resources.primary.max * 100
            
            return currentPct >= rule.condition.minValue and currentPct <= rule.condition.maxValue
        end
    elseif rule.type == "health" then
        local targetHealth = UnitExists("target") and (UnitHealth("target") / UnitHealthMax("target") * 100) or 100
        
        return targetHealth >= rule.condition.targetHealth.min and 
               targetHealth <= rule.condition.targetHealth.max
    elseif rule.type == "sequence" then
        -- Check if previous spell cast matches the condition
        local previousSpell = nil
        
        -- Look through recent combat log for the previous spell cast
        for i = #learningData.combatSamples, 1, -1 do
            local sample = learningData.combatSamples[i]
            
            if sample.event == "SPELL_CAST_SUCCESS" then
                previousSpell = sample.spellID
                break
            end
        end
        
        return previousSpell == rule.condition.previousSpell
    end
    
    return false
}

-- Reset learning data
function LearningSystem:ResetLearningData()
    WR:Debug("Resetting learning data")
    
    -- Reset data structures
    learningData.combatSamples = {}
    learningData.abilityWeights = {}
    learningData.abilityPerformance = {}
    learningData.abilityUsage = {}
    learningData.resourceMetrics = {}
    learningData.sequenceEfficiency = {}
    learningData.talentPerformance = {}
    learningData.encounterSpecificData = {}
    learningData.adaptiveRules = {}
    learningData.performanceHistory = {}
    learningData.learningCycles = 0
    learningData.lastLearnTime = 0
    
    -- Re-initialize default weights
    self:InitializeDefaultWeights()
}

-- Get learning statistics
function LearningSystem:GetStatistics()
    return {
        sampleCount = #learningData.combatSamples,
        learningCycles = learningData.learningCycles,
        lastLearnTime = learningData.lastLearnTime,
        abilitiesTracked = self:GetTableSize(learningData.abilityWeights),
        rulesGenerated = #learningData.adaptiveRules,
        configSettings = config
    }
}

-- Get ability performance data
function LearningSystem:GetAbilityPerformance()
    -- Format ability performance data for display
    local result = {}
    
    for spellID, performance in pairs(learningData.abilityPerformance) do
        local weight = learningData.abilityWeights[spellID] or DEFAULT_ABILITY_WEIGHT
        
        table.insert(result, {
            spellID = spellID,
            name = GetSpellInfo(spellID) or "Unknown",
            successRate = string.format("%.1f%%", performance.successRate * 100),
            damagePerCast = math.floor(performance.damagePerCast),
            effectivenessScore = string.format("%.2f", performance.effectivenessScore),
            sampleSize = performance.sampleSize,
            weight = string.format("%.1f", weight)
        })
    end
    
    -- Sort by weight
    table.sort(result, function(a, b)
        return a.weight > b.weight
    end)
    
    return result
}

-- Get configuration
function LearningSystem:GetConfig()
    return config
}

-- Set configuration
function LearningSystem:SetConfig(newConfig)
    if not newConfig then return end
    
    for k, v in pairs(newConfig) do
        if config[k] ~= nil then  -- Only update existing settings
            config[k] = v
        end
    end
    
    -- Save configuration
    self:SaveLearningData()
    
    -- Reset learning if requested
    if newConfig.resetOnChange then
        self:ResetLearningData()
    end
    
    WR:Debug("Updated learning system configuration")
}

-- Handle learning system commands
function LearningSystem:HandleCommand(args)
    if not args or args == "" then
        -- Show statistics
        self:ShowStatistics()
        return
    end
    
    local command, parameter = args:match("^(%S+)%s*(.*)$")
    command = command and command:lower() or args:lower()
    
    if command == "stats" or command == "statistics" then
        -- Show detailed statistics
        self:ShowStatistics(true)
    elseif command == "weights" then
        -- Show ability weights
        self:ShowAbilityWeights()
    elseif command == "rules" then
        -- Show adaptive rules
        self:ShowAdaptiveRules()
    elseif command == "reset" then
        -- Reset learning data
        self:ResetLearningData()
        WR:Print("Learning data has been reset")
    elseif command == "enable" then
        -- Enable learning system
        config.enabled = true
        self:SaveLearningData()
        WR:Print("Learning system enabled")
    elseif command == "disable" then
        -- Disable learning system
        config.enabled = false
        self:SaveLearningData()
        WR:Print("Learning system disabled")
    elseif command == "learn" then
        -- Force a learning cycle
        WR:Print("Running learning cycle...")
        self:RunLearningCycle()
        WR:Print("Learning cycle completed")
    elseif command == "config" then
        -- Show/set configuration
        if parameter == "" then
            -- Show configuration
            self:ShowConfig()
        else
            -- Parse configuration setting
            local setting, value = parameter:match("^(%S+)%s+(.+)$")
            
            if setting and value and config[setting] ~= nil then
                -- Convert value based on setting type
                if type(config[setting]) == "boolean" then
                    value = value:lower()
                    config[setting] = (value == "true" or value == "yes" or value == "1" or value == "on")
                elseif type(config[setting]) == "number" then
                    config[setting] = tonumber(value) or config[setting]
                else
                    config[setting] = value
                end
                
                -- Save configuration
                self:SaveLearningData()
                
                WR:Print("Set", setting, "to", tostring(config[setting]))
            else
                WR:Print("Unknown setting:", setting)
                WR:Print("Available settings:")
                
                for k, v in pairs(config) do
                    WR:Print("  -", k, "=", tostring(v), "(", type(v), ")")
                end
            end
        end
    else
        -- Unknown command
        WR:Print("Unknown learning command:", command)
        WR:Print("Available commands: stats, weights, rules, reset, enable, disable, learn, config")
    end
}

-- Show statistics
function LearningSystem:ShowStatistics(detailed)
    local stats = self:GetStatistics()
    
    WR:Print("Learning System Statistics:")
    WR:Print("Status:", config.enabled and "Enabled" or "Disabled")
    WR:Print("Sample Count:", stats.sampleCount)
    WR:Print("Learning Cycles:", stats.learningCycles)
    
    if stats.lastLearnTime > 0 then
        local timeAgo = GetTime() - stats.lastLearnTime
        local timeString = ""
        
        if timeAgo < 60 then
            timeString = string.format("%.0f seconds ago", timeAgo)
        elseif timeAgo < 3600 then
            timeString = string.format("%.0f minutes ago", timeAgo / 60)
        else
            timeString = string.format("%.1f hours ago", timeAgo / 3600)
        end
        
        WR:Print("Last Learning Cycle:", timeString)
    else
        WR:Print("Last Learning Cycle: Never")
    end
    
    WR:Print("Abilities Tracked:", stats.abilitiesTracked)
    WR:Print("Adaptive Rules:", stats.rulesGenerated)
    
    if detailed then
        -- Show more detailed statistics
        WR:Print("")
        WR:Print("Top Ability Weights:")
        
        local abilityPerformance = self:GetAbilityPerformance()
        
        for i = 1, math.min(5, #abilityPerformance) do
            local ability = abilityPerformance[i]
            
            WR:Print(i .. ".", ability.name, "- Weight:", ability.weight, 
                    "- Effectiveness:", ability.effectivenessScore,
                    "- Damage:", ability.damagePerCast)
        end
    end
}

-- Show ability weights
function LearningSystem:ShowAbilityWeights()
    local abilityPerformance = self:GetAbilityPerformance()
    
    WR:Print("Ability Weights:")
    
    for i, ability in ipairs(abilityPerformance) do
        WR:Print(i .. ".", ability.name, "- Weight:", ability.weight, 
                "- Success Rate:", ability.successRate,
                "- Samples:", ability.sampleSize)
    end
}

-- Show adaptive rules
function LearningSystem:ShowAdaptiveRules()
    if #learningData.adaptiveRules == 0 then
        WR:Print("No adaptive rules have been generated yet")
        return
    end
    
    WR:Print("Adaptive Rules:")
    
    local ruleTypes = {}
    
    for _, rule in ipairs(learningData.adaptiveRules) do
        ruleTypes[rule.type] = (ruleTypes[rule.type] or 0) + 1
    end
    
    for ruleType, count in pairs(ruleTypes) do
        WR:Print(ruleType:gsub("^%l", string.upper), "Rules:", count)
    end
    
    WR:Print("")
    WR:Print("Top Rules:")
    
    -- Sort rules by weight modifier
    local sortedRules = {}
    for _, rule in ipairs(learningData.adaptiveRules) do
        table.insert(sortedRules, rule)
    end
    
    table.sort(sortedRules, function(a, b)
        return a.action.weightModifier > b.action.weightModifier
    end)
    
    for i = 1, math.min(5, #sortedRules) do
        local rule = sortedRules[i]
        local spellName = GetSpellInfo(rule.action.spellID) or "Unknown"
        
        local description = "Rule Type: " .. rule.type .. " - "
        
        if rule.type == "targetCount" then
            description = description .. "Target Count: " .. rule.condition.targetCount
        elseif rule.type == "resource" then
            description = description .. "Resource: " .. rule.condition.minValue .. "-" .. rule.condition.maxValue .. "%"
        elseif rule.type == "health" then
            description = description .. "Target Health: " .. rule.condition.targetHealth.min .. "-" .. rule.condition.targetHealth.max .. "%"
        elseif rule.type == "sequence" then
            local prevSpellName = GetSpellInfo(rule.condition.previousSpell) or "Unknown"
            description = description .. "After: " .. prevSpellName
        end
        
        WR:Print(i .. ".", spellName, "-", description)
        WR:Print("   Bonus:", "+" .. rule.action.weightModifier .. "%")
    end
}

-- Show configuration
function LearningSystem:ShowConfig()
    WR:Print("Learning System Configuration:")
    
    for k, v in pairs(config) do
        WR:Print(k .. ":", tostring(v))
    end
    
    WR:Print("")
    WR:Print("To change a setting, use: /wr learning config setting value")
    WR:Print("Example: /wr learning config learningRate 7")
}

-- Get table size
function LearningSystem:GetTableSize(tbl)
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
}

-- Create learning UI
function LearningSystem:CreateLearningUI(parent)
    if not parent then return end
    
    -- Create the frame
    local frame = CreateFrame("Frame", "WindrunnerRotationsLearningUI", parent, "BackdropTemplate")
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
    title:SetText("Windrunner Rotations Learning System")
    
    -- Create close button
    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    
    -- Create tab buttons
    local tabWidth = 120
    local tabHeight = 24
    local tabs = {}
    local tabContents = {}
    
    local tabNames = {"Overview", "Abilities", "Rules", "Settings"}
    
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
        
        -- Create selected texture
        local selectedTexture = tab:CreateTexture(nil, "BACKGROUND")
        selectedTexture:SetAllPoints()
        selectedTexture:SetColorTexture(0.2, 0.4, 0.8, 0.2)
        selectedTexture:Hide()
        tab.selectedTexture = selectedTexture
        
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
                tabButton.selectedTexture:Hide()
            end
            
            tab.selectedTexture:Show()
        end)
        
        tabs[i] = tab
        tabContents[i] = content
    end
    
    -- Populate Overview tab
    local overviewContent = tabContents[1]
    
    -- Status section
    local statusFrame = CreateFrame("Frame", nil, overviewContent, "BackdropTemplate")
    statusFrame:SetSize(overviewContent:GetWidth(), 100)
    statusFrame:SetPoint("TOP", overviewContent, "TOP", 0, 0)
    statusFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    statusFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
    
    local statusTitle = statusFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    statusTitle:SetPoint("TOPLEFT", statusFrame, "TOPLEFT", 15, -15)
    statusTitle:SetText("Learning System Status")
    
    local enabledText = statusFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    enabledText:SetPoint("TOPLEFT", statusTitle, "BOTTOMLEFT", 10, -5)
    enabledText:SetText("Enabled: " .. (config.enabled and "Yes" or "No"))
    
    local adaptText = statusFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    adaptText:SetPoint("TOPLEFT", enabledText, "BOTTOMLEFT", 0, -5)
    adaptText:SetText("Adapting Rotations: " .. (config.adaptRotations and "Yes" or "No"))
    
    local rateText = statusFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    rateText:SetPoint("TOPLEFT", adaptText, "BOTTOMLEFT", 0, -5)
    rateText:SetText("Learning Rate: " .. config.learningRate .. "/10")
    
    local statsTitle = statusFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    statsTitle:SetPoint("LEFT", statusTitle, "LEFT", 300, 0)
    statsTitle:SetText("Learning Statistics")
    
    local stats = self:GetStatistics()
    
    local cyclesText = statusFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    cyclesText:SetPoint("TOPLEFT", statsTitle, "BOTTOMLEFT", 10, -5)
    cyclesText:SetText("Learning Cycles: " .. stats.learningCycles)
    
    local samplesText = statusFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    samplesText:SetPoint("TOPLEFT", cyclesText, "BOTTOMLEFT", 0, -5)
    samplesText:SetText("Samples Collected: " .. stats.sampleCount)
    
    local abilitiesText = statusFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    abilitiesText:SetPoint("TOPLEFT", samplesText, "BOTTOMLEFT", 0, -5)
    abilitiesText:SetText("Abilities Tracked: " .. stats.abilitiesTracked)
    
    -- Performance graph (placeholder)
    local graphFrame = CreateFrame("Frame", nil, overviewContent, "BackdropTemplate")
    graphFrame:SetSize(overviewContent:GetWidth(), 150)
    graphFrame:SetPoint("TOP", statusFrame, "BOTTOM", 0, -10)
    graphFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    graphFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
    
    local graphTitle = graphFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    graphTitle:SetPoint("TOPLEFT", graphFrame, "TOPLEFT", 15, -15)
    graphTitle:SetText("Performance Over Time")
    
    local graphPlaceholder = graphFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    graphPlaceholder:SetPoint("CENTER", graphFrame, "CENTER", 0, 0)
    graphPlaceholder:SetText("Graph would be displayed here in the full implementation")
    
    -- Control buttons
    local resetButton = CreateFrame("Button", nil, overviewContent, "UIPanelButtonTemplate")
    resetButton:SetSize(100, 30)
    resetButton:SetPoint("TOPLEFT", graphFrame, "BOTTOMLEFT", 10, -10)
    resetButton:SetText("Reset Data")
    resetButton:SetScript("OnClick", function()
        -- Confirmation dialog
        StaticPopupDialogs["WR_LEARNING_RESET_CONFIRM"] = {
            text = "Are you sure you want to reset all learning data? This cannot be undone.",
            button1 = "Yes",
            button2 = "No",
            OnAccept = function()
                LearningSystem:ResetLearningData()
                WR:Print("Learning data has been reset")
                
                -- Update statistics
                local newStats = LearningSystem:GetStatistics()
                cyclesText:SetText("Learning Cycles: " .. newStats.learningCycles)
                samplesText:SetText("Samples Collected: " .. newStats.sampleCount)
                abilitiesText:SetText("Abilities Tracked: " .. newStats.abilitiesTracked)
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3
        }
        
        StaticPopup_Show("WR_LEARNING_RESET_CONFIRM")
    end)
    
    local learnButton = CreateFrame("Button", nil, overviewContent, "UIPanelButtonTemplate")
    learnButton:SetSize(100, 30)
    learnButton:SetPoint("LEFT", resetButton, "RIGHT", 10, 0)
    learnButton:SetText("Learn Now")
    learnButton:SetScript("OnClick", function()
        WR:Print("Running learning cycle...")
        LearningSystem:RunLearningCycle()
        WR:Print("Learning cycle completed")
        
        -- Update statistics
        local newStats = LearningSystem:GetStatistics()
        cyclesText:SetText("Learning Cycles: " .. newStats.learningCycles)
        samplesText:SetText("Samples Collected: " .. newStats.sampleCount)
        abilitiesText:SetText("Abilities Tracked: " .. newStats.abilitiesTracked)
    end)
    
    local toggleButton = CreateFrame("Button", nil, overviewContent, "UIPanelButtonTemplate")
    toggleButton:SetSize(100, 30)
    toggleButton:SetPoint("LEFT", learnButton, "RIGHT", 10, 0)
    toggleButton:SetText(config.enabled and "Disable" or "Enable")
    toggleButton:SetScript("OnClick", function()
        config.enabled = not config.enabled
        LearningSystem:SaveLearningData()
        
        toggleButton:SetText(config.enabled and "Disable" or "Enable")
        enabledText:SetText("Enabled: " .. (config.enabled and "Yes" or "No"))
        
        WR:Print("Learning system " .. (config.enabled and "enabled" or "disabled"))
    end)
    
    -- Populate Abilities tab
    local abilitiesContent = tabContents[2]
    
    -- Abilities header
    local abilitiesHeaderFrame = CreateFrame("Frame", nil, abilitiesContent, "BackdropTemplate")
    abilitiesHeaderFrame:SetSize(abilitiesContent:GetWidth(), 50)
    abilitiesHeaderFrame:SetPoint("TOP", abilitiesContent, "TOP", 0, 0)
    abilitiesHeaderFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    abilitiesHeaderFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
    
    local abilitiesTitle = abilitiesHeaderFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    abilitiesTitle:SetPoint("TOPLEFT", abilitiesHeaderFrame, "TOPLEFT", 15, -15)
    abilitiesTitle:SetText("Ability Weights and Performance")
    
    local sortLabel = abilitiesHeaderFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    sortLabel:SetPoint("LEFT", abilitiesTitle, "RIGHT", 20, 0)
    sortLabel:SetText("Sort by:")
    
    -- Create dropdown for sorting
    local sortDropdown = CreateFrame("Frame", "WindrunnerLearningSortDropdown", abilitiesHeaderFrame, "UIDropDownMenuTemplate")
    sortDropdown:SetPoint("LEFT", sortLabel, "RIGHT", 5, 0)
    
    local selectedSort = "Weight"
    
    UIDropDownMenu_SetWidth(sortDropdown, 100)
    UIDropDownMenu_SetText(sortDropdown, selectedSort)
    
    UIDropDownMenu_Initialize(sortDropdown, function(self, level, menuList)
        local sortOptions = {"Weight", "Effectiveness", "Damage", "Success Rate", "Name"}
        
        local info = UIDropDownMenu_CreateInfo()
        for _, option in ipairs(sortOptions) do
            info.text = option
            info.value = option
            info.checked = (selectedSort == option)
            info.func = function(self)
                selectedSort = self.value
                UIDropDownMenu_SetText(sortDropdown, selectedSort)
                CloseDropDownMenus()
                
                -- Resort and refresh ability list
                LearningSystem:UpdateAbilitiesTab(selectedSort)
            end
            UIDropDownMenu_AddButton(info)
        end
    end)
    
    -- Abilities list
    local abilitiesScrollFrame = CreateFrame("ScrollFrame", nil, abilitiesContent, "UIPanelScrollFrameTemplate")
    abilitiesScrollFrame:SetSize(abilitiesContent:GetWidth() - 30, abilitiesContent:GetHeight() - 60)
    abilitiesScrollFrame:SetPoint("TOP", abilitiesHeaderFrame, "BOTTOM", 0, -5)
    
    local abilitiesScrollChild = CreateFrame("Frame", nil, abilitiesScrollFrame)
    abilitiesScrollChild:SetSize(abilitiesScrollFrame:GetWidth(), 1) -- Height will be set dynamically
    abilitiesScrollFrame:SetScrollChild(abilitiesScrollChild)
    
    -- Store for updates
    frame.abilitiesScrollChild = abilitiesScrollChild
    
    -- Function to update abilities tab
    function LearningSystem:UpdateAbilitiesTab(sortBy)
        -- Clear existing entries
        for i = abilitiesScrollChild:GetNumChildren(), 1, -1 do
            local child = select(i, abilitiesScrollChild:GetChildren())
            child:Hide()
            child:SetParent(nil)
        end
        
        -- Get ability performance data
        local abilityPerformance = self:GetAbilityPerformance()
        
        -- Sort by selected method
        if sortBy == "Weight" then
            table.sort(abilityPerformance, function(a, b)
                return tonumber(a.weight) > tonumber(b.weight)
            end)
        elseif sortBy == "Effectiveness" then
            table.sort(abilityPerformance, function(a, b)
                return tonumber(a.effectivenessScore) > tonumber(b.effectivenessScore)
            end)
        elseif sortBy == "Damage" then
            table.sort(abilityPerformance, function(a, b)
                return tonumber(a.damagePerCast) > tonumber(b.damagePerCast)
            end)
        elseif sortBy == "Success Rate" then
            table.sort(abilityPerformance, function(a, b)
                -- Strip the % sign and convert to number
                return tonumber(a.successRate:match("(%d+%.%d+)")) > tonumber(b.successRate:match("(%d+%.%d+)"))
            end)
        elseif sortBy == "Name" then
            table.sort(abilityPerformance, function(a, b)
                return a.name < b.name
            end)
        end
        
        -- Create ability list entries
        local entryHeight = 50
        local totalHeight = 10
        
        for i, ability in ipairs(abilityPerformance) do
            local entryFrame = CreateFrame("Frame", nil, abilitiesScrollChild, "BackdropTemplate")
            entryFrame:SetSize(abilitiesScrollChild:GetWidth() - 20, entryHeight)
            entryFrame:SetPoint("TOPLEFT", abilitiesScrollChild, "TOPLEFT", 10, -totalHeight)
            entryFrame:SetBackdrop({
                bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile = true,
                tileSize = 16,
                edgeSize = 16,
                insets = { left = 4, right = 4, top = 4, bottom = 4 }
            })
            entryFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
            
            -- Icon (if available)
            local icon = entryFrame:CreateTexture(nil, "ARTWORK")
            icon:SetSize(32, 32)
            icon:SetPoint("TOPLEFT", entryFrame, "TOPLEFT", 10, -10)
            
            local iconTexture = select(3, GetSpellInfo(ability.spellID)) or "Interface\\Icons\\INV_Misc_QuestionMark"
            icon:SetTexture(iconTexture)
            
            -- Name
            local nameText = entryFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            nameText:SetPoint("TOPLEFT", icon, "TOPRIGHT", 10, 0)
            nameText:SetText(ability.name)
            
            -- Weight
            local weightLabel = entryFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            weightLabel:SetPoint("TOPLEFT", nameText, "BOTTOMLEFT", 0, -5)
            weightLabel:SetText("Weight: " .. ability.weight)
            
            -- Effectiveness
            local effectivenessLabel = entryFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            effectivenessLabel:SetPoint("LEFT", weightLabel, "RIGHT", 20, 0)
            effectivenessLabel:SetText("Effectiveness: " .. ability.effectivenessScore)
            
            -- Sample Size
            local sampleSizeLabel = entryFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            sampleSizeLabel:SetPoint("LEFT", effectivenessLabel, "RIGHT", 20, 0)
            sampleSizeLabel:SetText("Samples: " .. ability.sampleSize)
            
            -- Success Rate
            local successRateLabel = entryFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            successRateLabel:SetPoint("TOPRIGHT", entryFrame, "TOPRIGHT", -15, -10)
            successRateLabel:SetText("Success: " .. ability.successRate)
            
            -- Damage
            local damageLabel = entryFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            damageLabel:SetPoint("TOPRIGHT", successRateLabel, "BOTTOMRIGHT", 0, -5)
            damageLabel:SetText("Damage: " .. ability.damagePerCast)
            
            totalHeight = totalHeight + entryHeight + 5
        end
        
        abilitiesScrollChild:SetHeight(math.max(totalHeight, abilitiesScrollFrame:GetHeight()))
    end
    
    -- Populate Rules tab
    local rulesContent = tabContents[3]
    
    -- Rules header
    local rulesHeaderFrame = CreateFrame("Frame", nil, rulesContent, "BackdropTemplate")
    rulesHeaderFrame:SetSize(rulesContent:GetWidth(), 50)
    rulesHeaderFrame:SetPoint("TOP", rulesContent, "TOP", 0, 0)
    rulesHeaderFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    rulesHeaderFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
    
    local rulesTitle = rulesHeaderFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    rulesTitle:SetPoint("TOPLEFT", rulesHeaderFrame, "TOPLEFT", 15, -15)
    rulesTitle:SetText("Adaptive Rules")
    
    local rulesCountText = rulesHeaderFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    rulesCountText:SetPoint("LEFT", rulesTitle, "RIGHT", 20, 0)
    rulesCountText:SetText("Rules: " .. #learningData.adaptiveRules)
    
    local filterLabel = rulesHeaderFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    filterLabel:SetPoint("RIGHT", rulesHeaderFrame, "RIGHT", -150, 0)
    filterLabel:SetText("Filter:")
    
    -- Create dropdown for filtering
    local filterDropdown = CreateFrame("Frame", "WindrunnerLearningFilterDropdown", rulesHeaderFrame, "UIDropDownMenuTemplate")
    filterDropdown:SetPoint("LEFT", filterLabel, "RIGHT", 5, 0)
    
    local selectedFilter = "All"
    
    UIDropDownMenu_SetWidth(filterDropdown, 100)
    UIDropDownMenu_SetText(filterDropdown, selectedFilter)
    
    UIDropDownMenu_Initialize(filterDropdown, function(self, level, menuList)
        local filterOptions = {"All", "Target Count", "Resource", "Health", "Sequence"}
        
        local info = UIDropDownMenu_CreateInfo()
        for _, option in ipairs(filterOptions) do
            info.text = option
            info.value = option
            info.checked = (selectedFilter == option)
            info.func = function(self)
                selectedFilter = self.value
                UIDropDownMenu_SetText(filterDropdown, selectedFilter)
                CloseDropDownMenus()
                
                -- Apply filter and refresh rules list
                LearningSystem:UpdateRulesTab(selectedFilter)
            end
            UIDropDownMenu_AddButton(info)
        end
    end)
    
    -- Rules list
    local rulesScrollFrame = CreateFrame("ScrollFrame", nil, rulesContent, "UIPanelScrollFrameTemplate")
    rulesScrollFrame:SetSize(rulesContent:GetWidth() - 30, rulesContent:GetHeight() - 60)
    rulesScrollFrame:SetPoint("TOP", rulesHeaderFrame, "BOTTOM", 0, -5)
    
    local rulesScrollChild = CreateFrame("Frame", nil, rulesScrollFrame)
    rulesScrollChild:SetSize(rulesScrollFrame:GetWidth(), 1) -- Height will be set dynamically
    rulesScrollFrame:SetScrollChild(rulesScrollChild)
    
    -- Store for updates
    frame.rulesScrollChild = rulesScrollChild
    
    -- Function to update rules tab
    function LearningSystem:UpdateRulesTab(filter)
        -- Clear existing entries
        for i = rulesScrollChild:GetNumChildren(), 1, -1 do
            local child = select(i, rulesScrollChild:GetChildren())
            child:Hide()
            child:SetParent(nil)
        end
        
        -- Filter and sort rules
        local rules = {}
        for _, rule in ipairs(learningData.adaptiveRules) do
            if filter == "All" or rule.type:gsub("^%l", string.upper) == filter or 
               rule.type:gsub("_", " "):gsub("^%l", string.upper) == filter then
                table.insert(rules, rule)
            end
        end
        
        -- Sort by weight modifier
        table.sort(rules, function(a, b)
            return a.action.weightModifier > b.action.weightModifier
        end)
        
        -- Update count display
        rulesCountText:SetText("Rules: " .. #rules .. " of " .. #learningData.adaptiveRules)
        
        -- Create rule entries
        local entryHeight = 70
        local totalHeight = 10
        
        for i, rule in ipairs(rules) do
            local entryFrame = CreateFrame("Frame", nil, rulesScrollChild, "BackdropTemplate")
            entryFrame:SetSize(rulesScrollChild:GetWidth() - 20, entryHeight)
            entryFrame:SetPoint("TOPLEFT", rulesScrollChild, "TOPLEFT", 10, -totalHeight)
            entryFrame:SetBackdrop({
                bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile = true,
                tileSize = 16,
                edgeSize = 16,
                insets = { left = 4, right = 4, top = 4, bottom = 4 }
            })
            entryFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
            
            -- Rule type
            local typeText = entryFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            typeText:SetPoint("TOPLEFT", entryFrame, "TOPLEFT", 15, -10)
            typeText:SetText(rule.type:gsub("^%l", string.upper):gsub("_", " ") .. " Rule:")
            
            -- Condition
            local conditionText = entryFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            conditionText:SetPoint("TOPLEFT", typeText, "BOTTOMLEFT", 5, -5)
            
            local conditionDesc = ""
            if rule.type == "targetCount" then
                conditionDesc = "Target Count: " .. rule.condition.targetCount
            elseif rule.type == "resource" then
                conditionDesc = "Resource: " .. rule.condition.minValue .. "-" .. rule.condition.maxValue .. "%"
            elseif rule.type == "health" then
                conditionDesc = "Target Health: " .. rule.condition.targetHealth.min .. "-" .. rule.condition.targetHealth.max .. "%"
            elseif rule.type == "sequence" then
                local prevSpellName = GetSpellInfo(rule.condition.previousSpell) or "Unknown"
                conditionDesc = "After Casting: " .. prevSpellName
            end
            
            conditionText:SetText("When " .. conditionDesc)
            
            -- Action
            local actionText = entryFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            actionText:SetPoint("TOPLEFT", conditionText, "BOTTOMLEFT", 0, -5)
            
            local spellName = GetSpellInfo(rule.action.spellID) or "Unknown Spell"
            actionText:SetText("Boost: " .. spellName .. " by +" .. rule.action.weightModifier .. "%")
            
            -- Spellicon
            local icon = entryFrame:CreateTexture(nil, "ARTWORK")
            icon:SetSize(32, 32)
            icon:SetPoint("TOPRIGHT", entryFrame, "TOPRIGHT", -15, -10)
            
            local iconTexture = select(3, GetSpellInfo(rule.action.spellID)) or "Interface\\Icons\\INV_Misc_QuestionMark"
            icon:SetTexture(iconTexture)
            
            -- Adjust frame height if needed based on text content
            local textHeight = typeText:GetStringHeight() + conditionText:GetStringHeight() + actionText:GetStringHeight() + 25
            if textHeight > entryHeight then
                entryFrame:SetHeight(textHeight)
                entryHeight = textHeight
            end
            
            totalHeight = totalHeight + entryFrame:GetHeight() + 5
        end
        
        rulesScrollChild:SetHeight(math.max(totalHeight, rulesScrollFrame:GetHeight()))
    end
    
    -- Populate Settings tab
    local settingsContent = tabContents[4]
    
    -- Settings frame
    local settingsFrame = CreateFrame("Frame", nil, settingsContent, "BackdropTemplate")
    settingsFrame:SetSize(settingsContent:GetWidth(), settingsContent:GetHeight() - 50)
    settingsFrame:SetPoint("TOP", settingsContent, "TOP", 0, 0)
    settingsFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    settingsFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
    
    local settingsTitle = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    settingsTitle:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 15, -15)
    settingsTitle:SetText("Learning System Settings")
    
    -- Create checkboxes for various settings
    local checkboxes = {}
    local checkY = -50
    local checkboxLabels = {
        enabledCheckbox = "Enable learning system",
        adaptRotationsCheckbox = "Adapt rotations based on learning",
        personalizedWeightsCheckbox = "Use personalized ability weights",
        resetOnSpecChangeCheckbox = "Reset learning when spec changes",
        resetOnMajorPatchCheckbox = "Reset learning on major game patches",
        preventRegressionCheckbox = "Prevent performance regression",
        enableExperimentationCheckbox = "Try experimental ability sequences"
    }
    
    local i = 0
    for name, label in pairs(checkboxLabels) do
        local checkbox = CreateFrame("CheckButton", nil, settingsFrame, "UICheckButtonTemplate")
        checkbox:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 30, checkY - (i * 30))
        
        local text = checkbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
        text:SetText(label)
        
        checkboxes[name] = checkbox
        i = i + 1
    end
    
    -- Set initial values
    checkboxes.enabledCheckbox:SetChecked(config.enabled)
    checkboxes.adaptRotationsCheckbox:SetChecked(config.adaptRotations)
    checkboxes.personalizedWeightsCheckbox:SetChecked(config.personalizedWeights)
    checkboxes.resetOnSpecChangeCheckbox:SetChecked(config.resetOnSpecChange)
    checkboxes.resetOnMajorPatchCheckbox:SetChecked(config.resetOnMajorPatch)
    checkboxes.preventRegressionCheckbox:SetChecked(config.preventRegression)
    checkboxes.enableExperimentationCheckbox:SetChecked(config.enableExperimentation)
    
    -- Learning rate slider
    local rateLabel = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    rateLabel:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 30, checkY - (i * 30) - 20)
    rateLabel:SetText("Learning Rate:")
    
    local rateSlider = CreateFrame("Slider", nil, settingsFrame, "OptionsSliderTemplate")
    rateSlider:SetPoint("TOPLEFT", rateLabel, "BOTTOMLEFT", 20, -10)
    rateSlider:SetWidth(200)
    rateSlider:SetHeight(16)
    rateSlider:SetMinMaxValues(1, 10)
    rateSlider:SetValue(config.learningRate)
    rateSlider:SetValueStep(1)
    rateSlider:SetObeyStepOnDrag(true)
    
    -- Set labels
    _G[rateSlider:GetName() .. "Low"]:SetText("Slow")
    _G[rateSlider:GetName() .. "High"]:SetText("Fast")
    _G[rateSlider:GetName() .. "Text"]:SetText(config.learningRate)
    
    -- Logging level slider
    local loggingLabel = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    loggingLabel:SetPoint("TOPLEFT", rateSlider, "BOTTOMLEFT", -20, -20)
    loggingLabel:SetText("Logging Detail Level:")
    
    local loggingSlider = CreateFrame("Slider", nil, settingsFrame, "OptionsSliderTemplate")
    loggingSlider:SetPoint("TOPLEFT", loggingLabel, "BOTTOMLEFT", 20, -10)
    loggingSlider:SetWidth(200)
    loggingSlider:SetHeight(16)
    loggingSlider:SetMinMaxValues(0, 3)
    loggingSlider:SetValue(config.loggingLevel)
    loggingSlider:SetValueStep(1)
    loggingSlider:SetObeyStepOnDrag(true)
    
    -- Set labels
    _G[loggingSlider:GetName() .. "Low"]:SetText("None")
    _G[loggingSlider:GetName() .. "High"]:SetText("Debug")
    _G[loggingSlider:GetName() .. "Text"]:SetText(config.loggingLevel)
    
    -- Set up slider behavior
    rateSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value)
        _G[self:GetName() .. "Text"]:SetText(value)
    end)
    
    loggingSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value)
        _G[self:GetName() .. "Text"]:SetText(value)
    end)
    
    -- Create save and reset buttons
    local saveButton = CreateFrame("Button", nil, settingsContent, "UIPanelButtonTemplate")
    saveButton:SetSize(100, 30)
    saveButton:SetPoint("BOTTOMRIGHT", settingsContent, "BOTTOMRIGHT", -10, 10)
    saveButton:SetText("Save")
    saveButton:SetScript("OnClick", function()
        -- Update config
        config.enabled = checkboxes.enabledCheckbox:GetChecked()
        config.adaptRotations = checkboxes.adaptRotationsCheckbox:GetChecked()
        config.personalizedWeights = checkboxes.personalizedWeightsCheckbox:GetChecked()
        config.resetOnSpecChange = checkboxes.resetOnSpecChangeCheckbox:GetChecked()
        config.resetOnMajorPatch = checkboxes.resetOnMajorPatchCheckbox:GetChecked()
        config.preventRegression = checkboxes.preventRegressionCheckbox:GetChecked()
        config.enableExperimentation = checkboxes.enableExperimentationCheckbox:GetChecked()
        
        config.learningRate = rateSlider:GetValue()
        config.loggingLevel = loggingSlider:GetValue()
        
        -- Save configuration
        LearningSystem:SaveLearningData()
        
        -- Update status displays in Overview tab
        enabledText:SetText("Enabled: " .. (config.enabled and "Yes" or "No"))
        adaptText:SetText("Adapting Rotations: " .. (config.adaptRotations and "Yes" or "No"))
        rateText:SetText("Learning Rate: " .. config.learningRate .. "/10")
        
        -- Update toggle button text
        toggleButton:SetText(config.enabled and "Disable" or "Enable")
        
        WR:Print("Learning system settings saved")
    end)
    
    local resetButton = CreateFrame("Button", nil, settingsContent, "UIPanelButtonTemplate")
    resetButton:SetSize(100, 30)
    resetButton:SetPoint("RIGHT", saveButton, "LEFT", -10, 0)
    resetButton:SetText("Reset")
    resetButton:SetScript("OnClick", function()
        -- Reset checkboxes to default values
        checkboxes.enabledCheckbox:SetChecked(true)
        checkboxes.adaptRotationsCheckbox:SetChecked(true)
        checkboxes.personalizedWeightsCheckbox:SetChecked(true)
        checkboxes.resetOnSpecChangeCheckbox:SetChecked(true)
        checkboxes.resetOnMajorPatchCheckbox:SetChecked(true)
        checkboxes.preventRegressionCheckbox:SetChecked(true)
        checkboxes.enableExperimentationCheckbox:SetChecked(false)
        
        -- Reset sliders
        rateSlider:SetValue(5)
        loggingSlider:SetValue(2)
    end)
    
    -- Initialize tabs
    LearningSystem:UpdateAbilitiesTab("Weight")
    LearningSystem:UpdateRulesTab("All")
    
    -- Select first tab by default
    tabs[1].selectedTexture:Show()
    tabContents[1]:Show()
    
    -- Hide by default
    frame:Hide()
    
    return frame
}

-- Initialize the module
LearningSystem:Initialize()

return LearningSystem