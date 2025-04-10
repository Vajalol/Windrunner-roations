local addonName, WR = ...

-- MachineLearning module for advanced rotation optimization using player data
local MachineLearning = {}
WR.MachineLearning = MachineLearning

-- Local data storage
local combatData = {
    rotationSequences = {},  -- Stored ability sequences
    outcomeMetrics = {},     -- DPS/HPS/survivability results
    contextData = {},        -- Fight conditions, group composition, etc.
    playerData = {}          -- Player-specific adaptations and patterns
}

local modelData = {
    trainedPatterns = {},    -- Learned optimal patterns
    sequenceWeights = {},    -- Effectiveness weightings
    adaptationRules = {},    -- Context-based adjustment rules
    classSpecificModels = {} -- Models for each class/spec combination
}

-- Settings with privacy controls
local settings = {
    enableDataCollection = false,
    shareAnonymousData = false,
    receiveNetworkUpdates = true,
    dataCollectionLevel = 1,  -- 1-3: Basic, Standard, Advanced
    modelUpdateFrequency = 3600, -- How often to re-analyze data (seconds)
    minimumSampleSize = 10,   -- Minimum combat samples before creating a model
    learningRate = 0.1        -- How quickly to adapt to new data (0-1)
}

-- Constants
local MAX_SEQUENCE_LENGTH = 10     -- Maximum ability sequence length to analyze
local MAX_STORED_COMBATS = 50      -- Maximum number of combat sessions to store
local MIN_COMBAT_DURATION = 30     -- Minimum duration of combat to store (seconds)
local ABILITY_CATEGORIES = {       -- Categories for ability classification
    "CORE",                        -- Core rotation abilities
    "COOLDOWN",                    -- Major cooldowns
    "DEFENSIVE",                   -- Defensive abilities
    "UTILITY",                     -- Utility abilities
    "MOVEMENT",                    -- Movement abilities
    "AOE",                         -- Area of effect abilities
    "SINGLE_TARGET",               -- Single target abilities
    "GENERATOR",                   -- Resource generators
    "SPENDER"                      -- Resource spenders
}

-- Ability pattern tracking
local currentSequence = {}
local lastAbilityTime = 0
local sequenceStartTime = 0

-- Initialize the MachineLearning module
function MachineLearning:Initialize()
    -- Get player class/spec information
    self:UpdateClassSpecInfo()
    
    -- Load saved data if available
    self:LoadSavedData()
    
    -- Register events
    self:RegisterEvents()
    
    -- Initialize UI
    self:InitializeUI()
    
    -- Start periodic model training
    C_Timer.NewTicker(settings.modelUpdateFrequency, function()
        self:TrainModels()
    end)
    
    WR:Debug("MachineLearning module initialized")
end

-- Register events for combat data collection
function MachineLearning:RegisterEvents()
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    eventFrame:RegisterEvent("ENCOUNTER_START")
    eventFrame:RegisterEvent("ENCOUNTER_END")
    eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
    eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_SPECIALIZATION_CHANGED" then
            MachineLearning:UpdateClassSpecInfo()
        elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
            if settings.enableDataCollection then
                MachineLearning:ProcessCombatLog(CombatLogGetCurrentEventInfo())
            end
        elseif event == "ENCOUNTER_START" then
            local encounterId, encounterName, difficultyId, groupSize = ...
            MachineLearning:OnEncounterStart(encounterId, encounterName, difficultyId, groupSize)
        elseif event == "ENCOUNTER_END" then
            local encounterId, encounterName, difficultyId, groupSize, success = ...
            MachineLearning:OnEncounterEnd(encounterId, encounterName, difficultyId, groupSize, success)
        elseif event == "PLAYER_REGEN_DISABLED" then
            MachineLearning:OnCombatStart()
        elseif event == "PLAYER_REGEN_ENABLED" then
            MachineLearning:OnCombatEnd()
        end
    end)
end

-- Update player class and spec information
function MachineLearning:UpdateClassSpecInfo()
    self.playerClass = select(2, UnitClass("player"))
    self.playerSpec = GetSpecialization()
    self.playerSpecID = self.playerSpec and GetSpecializationInfo(self.playerSpec) or nil
    
    -- Create class/spec-specific model container if needed
    local classSpecKey = self:GetClassSpecKey()
    if classSpecKey and not modelData.classSpecificModels[classSpecKey] then
        modelData.classSpecificModels[classSpecKey] = {
            abilityWeights = {},       -- Individual ability effectiveness
            abilitySequences = {},     -- Effective ability combinations
            situationalRules = {},     -- Context-specific adjustments
            recentPerformance = {},    -- Recent performance metrics
            modelCreationTime = nil,   -- When this model was created
            lastUpdatedTime = nil,     -- When this model was last updated
            sampleSize = 0,            -- How many combat samples used
            version = 1                -- Model version
        }
    end
end

-- Get current class/spec key
function MachineLearning:GetClassSpecKey()
    if not self.playerClass or not self.playerSpecID then
        return nil
    end
    
    return self.playerClass .. "_" .. self.playerSpecID
end

-- Load saved learning data
function MachineLearning:LoadSavedData()
    if WindrunnerRotationsDB and WindrunnerRotationsDB.MachineLearning then
        -- Load settings
        if WindrunnerRotationsDB.MachineLearning.settings then
            for k, v in pairs(WindrunnerRotationsDB.MachineLearning.settings) do
                if settings[k] ~= nil then
                    settings[k] = v
                end
            end
        end
        
        -- Load model data
        if WindrunnerRotationsDB.MachineLearning.modelData then
            -- Verify data structure and version before loading
            if self:ValidateSavedModelData(WindrunnerRotationsDB.MachineLearning.modelData) then
                modelData = CopyTable(WindrunnerRotationsDB.MachineLearning.modelData)
            end
        end
        
        -- Load combat data
        if WindrunnerRotationsDB.MachineLearning.combatData then
            combatData = CopyTable(WindrunnerRotationsDB.MachineLearning.combatData)
        end
    end
    
    WR:Debug("Loaded MachineLearning saved data")
end

-- Save learning data
function MachineLearning:SaveData()
    -- Initialize storage if needed
    WindrunnerRotationsDB = WindrunnerRotationsDB or {}
    WindrunnerRotationsDB.MachineLearning = WindrunnerRotationsDB.MachineLearning or {}
    
    -- Save settings
    WindrunnerRotationsDB.MachineLearning.settings = CopyTable(settings)
    
    -- Save model data (trim to reduce file size)
    WindrunnerRotationsDB.MachineLearning.modelData = self:TrimModelDataForSaving()
    
    -- Save combat data (anonymized)
    WindrunnerRotationsDB.MachineLearning.combatData = self:AnonymizeCombatDataForSaving()
    
    WR:Debug("Saved MachineLearning data")
end

-- Process combat log entries
function MachineLearning:ProcessCombatLog(timestamp, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, 
                                         destGUID, destName, destFlags, destRaidFlags, spellID, spellName, ...)
    -- Only process player's own spellcasts
    if sourceGUID ~= UnitGUID("player") then
        return
    end
    
    -- Process based on event type
    if event == "SPELL_CAST_SUCCESS" then
        self:RecordAbilityCast(spellID, spellName, timestamp)
    elseif event == "SPELL_DAMAGE" then
        local amount, overkill = select(1, ...)
        self:RecordAbilityDamage(spellID, amount, timestamp)
    elseif event == "SPELL_HEAL" then
        local amount, overhealing = select(1, ...)
        self:RecordAbilityHealing(spellID, amount, timestamp)
    end
end

-- Record ability cast in current sequence
function MachineLearning:RecordAbilityCast(spellID, spellName, timestamp)
    -- Check if this is a tracked ability
    if not self:IsTrackedAbility(spellID) then
        return
    end
    
    -- Record time between casts for pacing analysis
    local timeSinceLast = timestamp - lastAbilityTime
    lastAbilityTime = timestamp
    
    -- Add to current sequence
    local ability = {
        id = spellID,
        name = spellName,
        timestamp = timestamp,
        timeSinceLast = timeSinceLast,
        damage = 0,
        healing = 0,
        context = self:CaptureContext()
    }
    
    table.insert(currentSequence, ability)
    
    -- Keep sequence to a reasonable size
    if #currentSequence > MAX_SEQUENCE_LENGTH then
        table.remove(currentSequence, 1)
    end
end

-- Record damage for the last cast of an ability
function MachineLearning:RecordAbilityDamage(spellID, amount, timestamp)
    -- Find the most recent cast of this ability in the sequence
    for i = #currentSequence, 1, -1 do
        if currentSequence[i].id == spellID then
            currentSequence[i].damage = currentSequence[i].damage + amount
            break
        end
    end
end

-- Record healing for the last cast of an ability
function MachineLearning:RecordAbilityHealing(spellID, amount, timestamp)
    -- Find the most recent cast of this ability in the sequence
    for i = #currentSequence, 1, -1 do
        if currentSequence[i].id == spellID then
            currentSequence[i].healing = currentSequence[i].healing + amount
            break
        end
    end
end

-- Capture current combat context
function MachineLearning:CaptureContext()
    local context = {
        targetCount = self:GetTargetCount(),
        playerHealth = UnitHealth("player") / UnitHealthMax("player"),
        targetHealth = UnitExists("target") and UnitHealth("target") / UnitHealthMax("target") or 1,
        isMoving = GetUnitSpeed("player") > 0,
        hasBloodlust = self:HasBloodlust(),
        inExecutePhase = self:IsInExecutePhase(),
        resources = self:CaptureResourceState()
    }
    
    return context
end

-- Handle combat start
function MachineLearning:OnCombatStart()
    -- Reset sequence tracking
    currentSequence = {}
    lastAbilityTime = GetTime()
    sequenceStartTime = GetTime()
    
    -- Capture initial combat state
    local combatEntry = {
        startTime = GetTime(),
        endTime = nil,
        duration = nil,
        playerLevel = UnitLevel("player"),
        playerItemLevel = self:GetPlayerItemLevel(),
        targetID = UnitExists("target") and select(6, strsplit("-", UnitGUID("target"))) or nil,
        isTrainingDummy = self:IsTargetTrainingDummy(),
        sequences = {},
        metrics = {
            totalDamage = 0,
            totalHealing = 0,
            damagePerSecond = 0,
            healingPerSecond = 0,
            survivalRating = 1.0
        }
    }
    
    -- Store combat entry
    self.currentCombat = combatEntry
}

-- Handle combat end
function MachineLearning:OnCombatEnd()
    if not self.currentCombat then
        return
    end
    
    -- Finalize combat data
    self.currentCombat.endTime = GetTime()
    self.currentCombat.duration = self.currentCombat.endTime - self.currentCombat.startTime
    
    -- Only store combats that meet minimum duration
    if self.currentCombat.duration < MIN_COMBAT_DURATION then
        self.currentCombat = nil
        return
    end
    
    -- Store final sequence
    self.currentCombat.sequences = CopyTable(currentSequence)
    
    -- Calculate final metrics
    self:CalculateCombatMetrics(self.currentCombat)
    
    -- Store combat data
    table.insert(combatData.rotationSequences, self.currentCombat)
    
    -- Limit stored combats
    while #combatData.rotationSequences > MAX_STORED_COMBATS do
        table.remove(combatData.rotationSequences, 1)
    end
    
    -- Clear current combat
    self.currentCombat = nil
    
    -- Save data
    self:SaveData()
    
    -- If we have enough data, train the model
    local classSpecKey = self:GetClassSpecKey()
    if classSpecKey and #combatData.rotationSequences >= settings.minimumSampleSize and
       (not modelData.classSpecificModels[classSpecKey].lastUpdatedTime or
        GetTime() - modelData.classSpecificModels[classSpecKey].lastUpdatedTime > settings.modelUpdateFrequency) then
        self:TrainModels()
    end
}

-- Handle encounter start
function MachineLearning:OnEncounterStart(encounterId, encounterName, difficultyId, groupSize)
    -- Add encounter info to current combat if any
    if self.currentCombat then
        self.currentCombat.encounterID = encounterId
        self.currentCombat.encounterName = encounterName
        self.currentCombat.difficultyID = difficultyId
        self.currentCombat.groupSize = groupSize
        self.currentCombat.isEncounter = true
    end
}

-- Handle encounter end
function MachineLearning:OnEncounterEnd(encounterId, encounterName, difficultyId, groupSize, success)
    -- Add encounter success info to current combat if any
    if self.currentCombat and self.currentCombat.encounterID == encounterId then
        self.currentCombat.encounterSuccess = success == 1
    end
}

-- Calculate combat metrics
function MachineLearning:CalculateCombatMetrics(combat)
    if not combat or not combat.sequences then
        return
    end
    
    -- Calculate damage and healing totals
    local totalDamage = 0
    local totalHealing = 0
    
    for _, ability in ipairs(combat.sequences) do
        totalDamage = totalDamage + (ability.damage or 0)
        totalHealing = totalHealing + (ability.healing or 0)
    end
    
    -- Populate metrics
    combat.metrics.totalDamage = totalDamage
    combat.metrics.totalHealing = totalHealing
    combat.metrics.damagePerSecond = combat.duration > 0 and totalDamage / combat.duration or 0
    combat.metrics.healingPerSecond = combat.duration > 0 and totalHealing / combat.duration or 0
    
    -- Calculate survival rating (simplified for demonstration)
    combat.metrics.survivalRating = 1.0 -- Perfect survival by default
    
    -- Detailed survival metrics would use combat logs to assess damage taken,
    -- deaths, proper defensive usage, etc.
}

-- Train machine learning models
function MachineLearning:TrainModels()
    local classSpecKey = self:GetClassSpecKey()
    if not classSpecKey or #combatData.rotationSequences < settings.minimumSampleSize then
        return
    end
    
    WR:Debug("Training machine learning model for " .. classSpecKey)
    
    -- Get relevant combats for current class/spec
    local relevantCombats = self:GetRelevantCombats()
    
    -- Train ability weights
    self:TrainAbilityWeights(relevantCombats)
    
    -- Train sequence patterns
    self:TrainSequencePatterns(relevantCombats)
    
    -- Train situational rules
    self:TrainSituationalRules(relevantCombats)
    
    -- Update model metadata
    local model = modelData.classSpecificModels[classSpecKey]
    if model then
        if not model.modelCreationTime then
            model.modelCreationTime = GetTime()
        end
        
        model.lastUpdatedTime = GetTime()
        model.sampleSize = #relevantCombats
        model.version = model.version + 1
    end
    
    -- Save updated model
    self:SaveData()
    
    WR:Debug("Machine learning model training complete")
end

-- Get combats relevant to current class/spec
function MachineLearning:GetRelevantCombats()
    local classSpecKey = self:GetClassSpecKey()
    if not classSpecKey then
        return {}
    end
    
    local relevantCombats = {}
    
    for _, combat in ipairs(combatData.rotationSequences) do
        -- Skip too short combats or training dummies (optional)
        if combat.duration >= MIN_COMBAT_DURATION then
            table.insert(relevantCombats, combat)
        end
    end
    
    -- Sort by DPS/HPS (depending on role)
    local isHealer = self:IsHealerSpec()
    
    table.sort(relevantCombats, function(a, b)
        if isHealer then
            return a.metrics.healingPerSecond > b.metrics.healingPerSecond
        else
            return a.metrics.damagePerSecond > b.metrics.damagePerSecond
        end
    end)
    
    return relevantCombats
end

-- Train ability weights based on performance
function MachineLearning:TrainAbilityWeights(relevantCombats)
    local classSpecKey = self:GetClassSpecKey()
    if not classSpecKey then
        return
    end
    
    local model = modelData.classSpecificModels[classSpecKey]
    if not model then
        return
    end
    
    -- Initialize or reset ability weights
    local newWeights = {}
    local abilityCounts = {}
    local totalPerformance = 0
    local isHealer = self:IsHealerSpec()
    
    -- Aggregate ability data across all combats
    for _, combat in ipairs(relevantCombats) do
        -- Use appropriate performance metric
        local performance = isHealer and combat.metrics.healingPerSecond or combat.metrics.damagePerSecond
        totalPerformance = totalPerformance + performance
        
        -- Process each sequence in combat
        for _, ability in ipairs(combat.sequences) do
            local abilityID = ability.id
            
            -- Initialize ability data if needed
            if not newWeights[abilityID] then
                newWeights[abilityID] = 0
                abilityCounts[abilityID] = 0
            end
            
            -- Weight by performance (better performing combats have more influence)
            newWeights[abilityID] = newWeights[abilityID] + performance
            abilityCounts[abilityID] = abilityCounts[abilityID] + 1
        end
    end
    
    -- Normalize weights across abilities
    for abilityID, weight in pairs(newWeights) do
        if abilityCounts[abilityID] > 0 then
            -- Calculate average contribution to high-performing rotations
            local normalizedWeight = weight / (totalPerformance * abilityCounts[abilityID])
            
            -- Apply to model using learning rate
            if model.abilityWeights[abilityID] then
                -- Blend with existing weight
                model.abilityWeights[abilityID] = 
                    model.abilityWeights[abilityID] * (1 - settings.learningRate) + 
                    normalizedWeight * settings.learningRate
            else
                -- New ability
                model.abilityWeights[abilityID] = normalizedWeight
            end
        end
    end
end

-- Train sequence patterns
function MachineLearning:TrainSequencePatterns(relevantCombats)
    local classSpecKey = self:GetClassSpecKey()
    if not classSpecKey then
        return
    end
    
    local model = modelData.classSpecificModels[classSpecKey]
    if not model then
        return
    end
    
    -- Initialize model sequences if needed
    model.abilitySequences = model.abilitySequences or {}
    
    -- Find common ability patterns in high-performing combats
    local patterns = {}
    local isHealer = self:IsHealerSpec()
    
    -- We'll focus on top 25% of combats for pattern learning
    local topCombatCount = math.max(1, math.floor(#relevantCombats * 0.25))
    local topCombats = {}
    
    for i = 1, topCombatCount do
        if relevantCombats[i] then
            table.insert(topCombats, relevantCombats[i])
        end
    end
    
    -- Extract n-gram patterns from sequences (we'll look for 2-4 ability sequences)
    for patternLength = 2, 4 do
        for _, combat in ipairs(topCombats) {
            if #combat.sequences >= patternLength then
                for i = 1, #combat.sequences - patternLength + 1 do
                    -- Create a pattern key from ability IDs
                    local patternKey = ""
                    local pattern = {}
                    
                    for j = 0, patternLength - 1 do
                        local ability = combat.sequences[i + j]
                        patternKey = patternKey .. ability.id .. ":"
                        table.insert(pattern, {
                            id = ability.id,
                            name = ability.name,
                            timeSinceLast = ability.timeSinceLast
                        })
                    end
                    
                    -- Initialize pattern if needed
                    if not patterns[patternKey] then
                        patterns[patternKey] = {
                            abilities = pattern,
                            count = 0,
                            totalPerformance = 0,
                            averagePerformance = 0
                        }
                    end
                    
                    -- Update pattern statistics
                    patterns[patternKey].count = patterns[patternKey].count + 1
                    
                    -- Add combat performance to pattern
                    local performance = isHealer and combat.metrics.healingPerSecond or combat.metrics.damagePerSecond
                    patterns[patternKey].totalPerformance = patterns[patternKey].totalPerformance + performance
                }
            }
        }
    }
    
    -- Calculate average performance for each pattern
    for key, pattern in pairs(patterns) do
        if pattern.count > 0 then
            pattern.averagePerformance = pattern.totalPerformance / pattern.count
        end
    end
    
    -- Sort patterns by performance
    local sortedPatterns = {}
    for key, pattern in pairs(patterns) do
        table.insert(sortedPatterns, {key = key, pattern = pattern})
    end
    
    table.sort(sortedPatterns, function(a, b)
        return a.pattern.averagePerformance > b.pattern.averagePerformance
    end)
    
    -- Keep only top patterns to avoid overfitting
    local topPatternCount = math.min(50, #sortedPatterns)
    
    -- Update model with top patterns
    model.abilitySequences = {}
    
    for i = 1, topPatternCount do
        if sortedPatterns[i] then
            model.abilitySequences[sortedPatterns[i].key] = sortedPatterns[i].pattern
        end
    end
end

-- Train situational rules
function MachineLearning:TrainSituationalRules(relevantCombats)
    local classSpecKey = self:GetClassSpecKey()
    if not classSpecKey then
        return
    end
    
    local model = modelData.classSpecificModels[classSpecKey]
    if not model then
        return
    end
    
    -- Initialize situational rules
    model.situationalRules = {
        executePhase = {},    -- Rules for execute phase
        aoe = {},             -- Rules for AOE situations
        movement = {},        -- Rules for while moving
        cooldowns = {},       -- Rules for cooldown usage
        defensives = {}       -- Rules for defensive usage
    }
    
    -- For each situation type, find successful ability usage patterns
    
    -- Execute phase rules
    self:TrainSituationRules(model.situationalRules.executePhase, relevantCombats, 
                            function(ability) return ability.context.inExecutePhase end)
    
    -- AOE rules (3+ targets)
    self:TrainSituationRules(model.situationalRules.aoe, relevantCombats, 
                            function(ability) return ability.context.targetCount >= 3 end)
    
    -- Movement rules
    self:TrainSituationRules(model.situationalRules.movement, relevantCombats, 
                            function(ability) return ability.context.isMoving end)
    
    -- Cooldown usage rules (based on special abilities, bloodlust, etc.)
    self:TrainSituationRules(model.situationalRules.cooldowns, relevantCombats, 
                            function(ability) return ability.context.hasBloodlust or self:IsMajorCooldown(ability.id) end)
    
    -- Defensive usage rules (based on player health)
    self:TrainSituationRules(model.situationalRules.defensives, relevantCombats, 
                            function(ability) return ability.context.playerHealth < 0.6 end)
}

-- Train rules for a specific situation
function MachineLearning:TrainSituationRules(rulesTable, combats, situationCheckFunc)
    -- Track ability effectiveness in this situation
    local abilityStats = {}
    local totalSituationDamage = 0
    local totalSituationHealing = 0
    local abilityUseCount = {}
    local isHealer = self:IsHealerSpec()
    
    -- Extract ability usage in the target situation
    for _, combat in ipairs(combats) do
        for _, ability in ipairs(combat.sequences) do
            -- Check if this ability was used in the target situation
            if situationCheckFunc(ability) then
                if not abilityStats[ability.id] then
                    abilityStats[ability.id] = {
                        damage = 0,
                        healing = 0,
                        count = 0
                    }
                end
                
                -- Add stats
                abilityStats[ability.id].damage = abilityStats[ability.id].damage + (ability.damage or 0)
                abilityStats[ability.id].healing = abilityStats[ability.id].healing + (ability.healing or 0)
                abilityStats[ability.id].count = abilityStats[ability.id].count + 1
                
                -- Track totals
                totalSituationDamage = totalSituationDamage + (ability.damage or 0)
                totalSituationHealing = totalSituationHealing + (ability.healing or 0)
            end
        end
    end
    
    -- Calculate average effectiveness
    for abilityId, stats in pairs(abilityStats) do
        if stats.count > 0 then
            -- Calculate average damage/healing per use
            stats.avgDamage = stats.damage / stats.count
            stats.avgHealing = stats.healing / stats.count
            
            -- Calculate relative effectiveness
            local totalPerformance = isHealer and totalSituationHealing or totalSituationDamage
            local abilityPerformance = isHealer and stats.healing or stats.damage
            
            if totalPerformance > 0 then
                stats.relativeEffectiveness = abilityPerformance / totalPerformance
            else
                stats.relativeEffectiveness = 0
            end
        end
    end
    
    -- Store in rules table
    for abilityId, stats in pairs(abilityStats) do
        rulesTable[abilityId] = stats.relativeEffectiveness
    end
end

-- Apply learned patterns to improve ability scoring
function MachineLearning:ApplyLearnedPatterns(abilities)
    local classSpecKey = self:GetClassSpecKey()
    if not classSpecKey then
        return abilities
    end
    
    local model = modelData.classSpecificModels[classSpecKey]
    if not model or not model.abilityWeights then
        return abilities
    end
    
    -- Apply ability weights from model
    for i, ability in ipairs(abilities) do
        local modelWeight = model.abilityWeights[ability.id]
        if modelWeight then
            ability.score = ability.score * modelWeight
            ability.mlAdjusted = true
        end
    end
    
    -- Apply sequence pattern bonuses
    self:ApplySequencePatterns(abilities, model)
    
    -- Apply situational rules
    self:ApplySituationalRules(abilities, model)
    
    return abilities
end

-- Apply sequence pattern matching
function MachineLearning:ApplySequencePatterns(abilities, model)
    if not model.abilitySequences or #currentSequence == 0 then
        return
    end
    
    -- Build recent ability sequence key (last 3 abilities)
    local recentSequence = {}
    for i = math.max(1, #currentSequence - 2), #currentSequence do
        table.insert(recentSequence, currentSequence[i].id)
    end
    
    -- Check all abilities for potential sequence matches
    for i, ability in ipairs(abilities) do
        -- Create potential next sequence
        local potentialSequence = CopyTable(recentSequence)
        table.insert(potentialSequence, ability.id)
        
        -- Check if this creates a known high-performing pattern
        while #potentialSequence > 1 do
            local patternKey = ""
            for _, id in ipairs(potentialSequence) do
                patternKey = patternKey .. id .. ":"
            end
            
            -- Check if this sequence exists in our model
            local pattern = model.abilitySequences[patternKey]
            if pattern then
                -- Boost score based on pattern performance
                local boost = 1 + (pattern.count / 10) -- Modest boost that scales with pattern frequency
                ability.score = ability.score * boost
                ability.patternBoost = boost
                break -- Found a match, no need to check shorter sequences
            end
            
            -- Try shorter sequence
            table.remove(potentialSequence, 1)
        end
    end
end

-- Apply situational rules
function MachineLearning:ApplySituationalRules(abilities, model)
    if not model.situationalRules then
        return
    end
    
    -- Determine current situation
    local isExecutePhase = self:IsInExecutePhase()
    local targetCount = self:GetTargetCount() 
    local isMoving = GetUnitSpeed("player") > 0
    local hasBloodlust = self:HasBloodlust()
    local playerHealthPct = UnitHealth("player") / UnitHealthMax("player")
    
    -- Apply appropriate situational rules
    for i, ability in ipairs(abilities) do
        -- Execute phase adjustments
        if isExecutePhase and model.situationalRules.executePhase[ability.id] then
            local factor = model.situationalRules.executePhase[ability.id]
            ability.score = ability.score * (1 + factor)
            ability.situationalAdjusted = true
        end
        
        -- AOE adjustments
        if targetCount >= 3 and model.situationalRules.aoe[ability.id] then
            local factor = model.situationalRules.aoe[ability.id]
            ability.score = ability.score * (1 + factor)
            ability.situationalAdjusted = true
        end
        
        -- Movement adjustments
        if isMoving and model.situationalRules.movement[ability.id] then
            local factor = model.situationalRules.movement[ability.id]
            ability.score = ability.score * (1 + factor)
            ability.situationalAdjusted = true
        end
        
        -- Cooldown usage adjustments
        if (hasBloodlust or self:IsBurstPhase()) and model.situationalRules.cooldowns[ability.id] then
            local factor = model.situationalRules.cooldowns[ability.id]
            ability.score = ability.score * (1 + factor)
            ability.situationalAdjusted = true
        end
        
        -- Defensive usage adjustments
        if playerHealthPct < 0.6 and model.situationalRules.defensives[ability.id] then
            local factor = model.situationalRules.defensives[ability.id]
            ability.score = ability.score * (1 + factor)
            ability.situationalAdjusted = true
        end
    end
end

-- Check if ability is tracked for learning
function MachineLearning:IsTrackedAbility(spellID)
    -- In a real implementation, this would check against a list of class abilities
    -- For demonstration, we'll use a simplified approach
    
    -- Ignore certain types of abilities (e.g., autoattacks)
    local ignoredSpellIDs = {
        75, -- Auto Shot
        6603, -- Auto Attack
        -- Add more as needed
    }
    
    for _, id in ipairs(ignoredSpellIDs) do
        if spellID == id then
            return false
        end
    end
    
    -- Validate that this is a proper spell
    local name = GetSpellInfo(spellID)
    return name ~= nil
end

-- Check if we're in execute phase (target below 20% health)
function MachineLearning:IsInExecutePhase()
    if not UnitExists("target") then
        return false
    end
    
    local healthPct = UnitHealth("target") / UnitHealthMax("target")
    return healthPct <= 0.2
end

-- Check if player has bloodlust/heroism buff
function MachineLearning:HasBloodlust()
    local bloodlustIDs = {
        2825,  -- Bloodlust
        32182, -- Heroism
        80353, -- Time Warp
        90355, -- Ancient Hysteria
        160452 -- Netherwinds
    }
    
    for _, id in ipairs(bloodlustIDs) do
        local name = GetSpellInfo(id)
        if name and AuraUtil.FindAuraByName(name, "player") then
            return true
        end
    end
    
    return false
end

-- Check if current spec is a healer spec
function MachineLearning:IsHealerSpec()
    local _, _, _, _, role = GetSpecializationInfo(self.playerSpec or 0)
    return role == "HEALER"
end

-- Check if a spell is a major cooldown
function MachineLearning:IsMajorCooldown(spellID)
    -- In a real implementation, this would check against a class-specific cooldown list
    -- For demonstration, we'll use a simplified approach based on cooldown time
    
    local _, duration = GetSpellCooldown(spellID)
    return duration >= 60 -- Cooldowns of 1 minute or longer
end

-- Check if we're in a burst phase
function MachineLearning:IsBurstPhase()
    -- This would be more sophisticated in a real implementation
    -- For demonstration, we'll use some simple heuristics
    
    -- Check for personal damage increasers
    local damageIncreasers = {
        "Avenging Wrath", -- Paladin
        "Icy Veins",      -- Mage
        "Arcane Power",   -- Mage
        "Combustion",     -- Mage
        "Avatar",         -- Warrior
        "Recklessness",   -- Warrior
        -- Add more class-specific buffs
    }
    
    for _, buffName in ipairs(damageIncreasers) do
        if AuraUtil.FindAuraByName(buffName, "player") then
            return true
        end
    end
    
    -- Check for bloodlust
    if self:HasBloodlust() then
        return true
    end
    
    return false
end

-- Get number of nearby enemies
function MachineLearning:GetTargetCount()
    -- In a real implementation, this would use nameplates or combat log
    -- For demonstration, we'll use a simple approach
    
    local count = 0
    if UnitExists("target") and UnitCanAttack("player", "target") then
        count = count + 1
    end
    
    -- Check nameplate units if available
    for i = 1, 40 do
        local unitID = "nameplate" .. i
        if UnitExists(unitID) and UnitCanAttack("player", unitID) and UnitAffectingCombat(unitID) then
            count = count + 1
        end
    end
    
    return count
end

-- Capture current resource state
function MachineLearning:CaptureResourceState()
    local resources = {}
    
    -- Primary power
    local powerType = UnitPowerType("player")
    resources.primaryType = powerType
    resources.primaryCurrent = UnitPower("player", powerType)
    resources.primaryMax = UnitPowerMax("player", powerType)
    
    -- Secondary power (combo points, chi, etc.)
    local classSecondary = {
        ROGUE = Enum.PowerType.ComboPoints,
        DRUID = Enum.PowerType.ComboPoints,
        MONK = Enum.PowerType.Chi,
        PALADIN = Enum.PowerType.HolyPower,
        WARLOCK = Enum.PowerType.SoulShards,
        MAGE = nil, -- No secondary resource
        WARRIOR = nil,
        HUNTER = nil,
        PRIEST = nil,
        DEATHKNIGHT = Enum.PowerType.Runes,
        DEMONHUNTER = nil,
        SHAMAN = nil,
        EVOKER = nil
    }
    
    local secondaryType = classSecondary[self.playerClass]
    if secondaryType then
        resources.secondaryType = secondaryType
        resources.secondaryCurrent = UnitPower("player", secondaryType)
        resources.secondaryMax = UnitPowerMax("player", secondaryType)
    end
    
    return resources
end

-- Initialize UI components
function MachineLearning:InitializeUI()
    -- This would create UI elements for settings and statistics
    -- Simplified for demonstration
end

-- Get player's average item level
function MachineLearning:GetPlayerItemLevel()
    local _, itemLevel = GetAverageItemLevel()
    return itemLevel
end

-- Check if target is a training dummy
function MachineLearning:IsTargetTrainingDummy()
    if not UnitExists("target") then
        return false
    end
    
    local targetName = UnitName("target"):lower()
    return targetName:find("dummy") or targetName:find("target") or targetName:find("training")
end

-- Validate saved model data
function MachineLearning:ValidateSavedModelData(data)
    -- Simple validation for demonstration
    if not data or type(data) ~= "table" then
        return false
    end
    
    if not data.classSpecificModels or type(data.classSpecificModels) ~= "table" then
        return false
    end
    
    return true
end

-- Trim model data for saving
function MachineLearning:TrimModelDataForSaving()
    -- Create a copy of modelData
    local trimmedData = CopyTable(modelData)
    
    -- If there are too many class/spec models, keep only the current and most recent ones
    if trimmedData.classSpecificModels then
        local currentKey = self:GetClassSpecKey()
        local models = {}
        
        -- Always keep current class/spec
        if currentKey and trimmedData.classSpecificModels[currentKey] then
            models[currentKey] = trimmedData.classSpecificModels[currentKey]
        end
        
        -- Sort other models by last updated time
        local sortedKeys = {}
        for key, model in pairs(trimmedData.classSpecificModels) do
            if key ~= currentKey then
                table.insert(sortedKeys, {key = key, time = model.lastUpdatedTime or 0})
            end
        end
        
        table.sort(sortedKeys, function(a, b) return a.time > b.time end)
        
        -- Keep only the 5 most recent models
        for i = 1, math.min(5, #sortedKeys) do
            models[sortedKeys[i].key] = trimmedData.classSpecificModels[sortedKeys[i].key]
        end
        
        -- Replace with trimmed version
        trimmedData.classSpecificModels = models
    end
    
    return trimmedData
end

-- Anonymize combat data for saving
function MachineLearning:AnonymizeCombatDataForSaving()
    -- Create a copy of combatData
    local anonymizedData = CopyTable(combatData)
    
    -- Remove any sensitive data
    for i, combat in ipairs(anonymizedData.rotationSequences) do
        -- Remove player identifiers
        combat.playerGUID = nil
        combat.playerName = nil
        
        -- Remove specific timestamps (keep only relative times)
        local startTime = combat.startTime
        combat.startTime = 0
        combat.endTime = combat.duration
        
        -- Adjust sequence timestamps
        for j, ability in ipairs(combat.sequences) do
            ability.timestamp = ability.timestamp - startTime
        end
    end
    
    return anonymizedData
end

-- Get model status for UI
function MachineLearning:GetModelStatus()
    local classSpecKey = self:GetClassSpecKey()
    if not classSpecKey then
        return {
            available = false,
            message = "No class/spec detected"
        }
    end
    
    local model = modelData.classSpecificModels[classSpecKey]
    if not model or not model.lastUpdatedTime then
        return {
            available = false,
            message = "No model available for current class/spec"
        }
    end
    
    local timeSinceUpdate = GetTime() - model.lastUpdatedTime
    local daysAgo = math.floor(timeSinceUpdate / (24 * 60 * 60))
    local hoursAgo = math.floor((timeSinceUpdate % (24 * 60 * 60)) / (60 * 60))
    
    local timeString = ""
    if daysAgo > 0 then
        timeString = daysAgo .. " days, " .. hoursAgo .. " hours ago"
    else
        timeString = hoursAgo .. " hours ago"
    end
    
    return {
        available = true,
        sampleSize = model.sampleSize,
        lastUpdated = timeString,
        version = model.version,
        abilityCount = self:TableSize(model.abilityWeights)
    }
end

-- Table size helper
function MachineLearning:TableSize(tbl)
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
end

-- Get settings
function MachineLearning:GetSettings()
    return settings
end

-- Update settings
function MachineLearning:UpdateSettings(newSettings)
    if not newSettings then return end
    
    for k, v in pairs(newSettings) do
        if settings[k] ~= nil then
            settings[k] = v
        end
    end
    
    self:SaveData()
end

-- Handle command line
function MachineLearning:HandleCommand(cmd)
    if not cmd or cmd == "" then
        -- Show status
        self:ShowStatus()
        return
    end
    
    local command, param = cmd:match("^(%S+)%s*(.*)$")
    command = command:lower()
    
    if command == "enable" then
        settings.enableDataCollection = true
        self:SaveData()
        WR:Print("Machine Learning data collection enabled")
    elseif command == "disable" then
        settings.enableDataCollection = false
        self:SaveData()
        WR:Print("Machine Learning data collection disabled")
    elseif command == "train" then
        self:TrainModels()
        WR:Print("Initiated manual model training")
    elseif command == "status" then
        self:ShowStatus()
    elseif command == "reset" then
        self:ResetData()
        WR:Print("Reset machine learning data")
    elseif command == "settings" then
        if param == "" then
            self:ShowSettings()
        else
            local setting, value = param:match("(%S+)%s+(.+)")
            if setting and value and settings[setting] ~= nil then
                -- Convert value based on setting type
                if type(settings[setting]) == "boolean" then
                    value = value:lower()
                    settings[setting] = (value == "true" or value == "yes" or value == "1" or value == "on")
                elseif type(settings[setting]) == "number" then
                    settings[setting] = tonumber(value) or settings[setting]
                else
                    settings[setting] = value
                end
                
                self:SaveData()
                WR:Print("Updated setting: " .. setting .. " = " .. tostring(settings[setting]))
            else
                WR:Print("Unknown setting: " .. (setting or ""))
            end
        end
    else
        WR:Print("Unknown ML command: " .. command)
        WR:Print("Available commands: enable, disable, train, status, reset, settings")
    end
end

-- Show current status
function MachineLearning:ShowStatus()
    WR:Print("Machine Learning Status:")
    WR:Print("Data Collection: " .. (settings.enableDataCollection and "Enabled" or "Disabled"))
    
    local modelStatus = self:GetModelStatus()
    if modelStatus.available then
        WR:Print("Model Available: Yes")
        WR:Print("Sample Size: " .. modelStatus.sampleSize)
        WR:Print("Model Version: " .. modelStatus.version)
        WR:Print("Last Updated: " .. modelStatus.lastUpdated)
        WR:Print("Ability Count: " .. modelStatus.abilityCount)
    else
        WR:Print("Model Available: No (" .. modelStatus.message .. ")")
    end
    
    WR:Print("Combat Samples: " .. #combatData.rotationSequences)
end

-- Show current settings
function MachineLearning:ShowSettings()
    WR:Print("Machine Learning Settings:")
    
    for k, v in pairs(settings) do
        WR:Print("  " .. k .. ": " .. tostring(v))
    end
    
    WR:Print("Use '/wr ml settings <name> <value>' to change")
end

-- Reset data
function MachineLearning:ResetData()
    -- Reset data structures
    combatData = {
        rotationSequences = {},
        outcomeMetrics = {},
        contextData = {},
        playerData = {}
    }
    
    modelData = {
        trainedPatterns = {},
        sequenceWeights = {},
        adaptationRules = {},
        classSpecificModels = {}
    }
    
    -- Re-initialize for current class/spec
    self:UpdateClassSpecInfo()
    
    -- Save empty data
    self:SaveData()
end

-- Register with RotationEnhancer
function MachineLearning:RegisterWithRotationEnhancer()
    if WR.RotationEnhancer then
        WR.RotationEnhancer:RegisterModifyAbilities(function(abilities)
            return self:ApplyLearnedPatterns(abilities)
        end)
    end
end

-- Initialize the module
MachineLearning:Initialize()

return MachineLearning