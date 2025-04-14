------------------------------------------
-- WindrunnerRotations - Player Skill System
-- Author: VortexQ8
-- The War Within Season 2
------------------------------------------

local addonName, WR = ...
local PlayerSkillSystem = {}
WR.PlayerSkillSystem = PlayerSkillSystem

-- Dependencies
local API = WR.API
local ConfigRegistry = WR.ConfigRegistry
local ModuleManager = WR.ModuleManager
local PerformanceTracker = WR.PerformanceTracker
local MachineLearning = WR.MachineLearning
local CombatAnalysis = WR.CombatAnalysis

-- Data storage
local skillProfiles = {}
local currentSkillLevel = "intermediate" -- Default to intermediate
local skillAssessment = {}
local playerMetrics = {}
local learningCurve = {}
local adaptiveSettings = {}
local skillProgression = {}
local metricWeights = {}
local tutorialSteps = {}
local activeTutorial = nil
local completedTutorials = {}
local skillHistory = {}
local manualOverrides = {}
local lastAssessmentTime = 0
local MAX_SKILL_HISTORY = 20
local ASSESSMENT_INTERVAL = 300 -- 5 minutes in seconds

-- Constants
local SKILL_LEVELS = {
    "beginner",
    "novice",
    "intermediate",
    "advanced",
    "expert"
}

-- Initialize the Player Skill System
function PlayerSkillSystem:Initialize()
    -- Register settings
    self:RegisterSettings()
    
    -- Register slash command
    SLASH_WRSKILL1 = "/wrskill"
    SlashCmdList["WRSKILL"] = function(msg)
        self:HandleSlashCommand(msg)
    end
    
    -- Setup skill profiles
    self:SetupSkillProfiles()
    
    -- Load saved settings
    self:LoadSavedSettings()
    
    -- Setup event handling
    self:SetupEventHandling()
    
    -- Initialize tutorial system
    self:InitializeTutorials()
    
    API.PrintDebug("Player Skill System initialized")
    return true
end

-- Register settings for the Player Skill System
function PlayerSkillSystem:RegisterSettings()
    ConfigRegistry:RegisterSettings("PlayerSkillSystem", {
        generalSettings = {
            enableSkillScaling = {
                displayName = "Enable Skill Scaling",
                description = "Enable the player skill scaling system",
                type = "toggle",
                default = true
            },
            initialSkillLevel = {
                displayName = "Initial Skill Level",
                description = "Starting skill level for new characters",
                type = "dropdown",
                options = SKILL_LEVELS,
                default = "intermediate"
            },
            enableAutomaticAssessment = {
                displayName = "Automatic Skill Assessment",
                description = "Automatically assess player skill during gameplay",
                type = "toggle",
                default = true
            },
            assessmentFrequency = {
                displayName = "Assessment Frequency",
                description = "How often to assess player skill (minutes)",
                type = "slider",
                min = 1,
                max = 30,
                step = 1,
                default = 5
            },
            allowSkillProgression = {
                displayName = "Allow Skill Progression",
                description = "Automatically advance skill level as you improve",
                type = "toggle",
                default = true
            }
        },
        adaptiveSettings = {
            adaptationRate = {
                displayName = "Adaptation Rate",
                description = "How quickly the system adapts to your skill level",
                type = "slider",
                min = 1,
                max = 10,
                step = 1,
                default = 5
            },
            prioritizeAccuracy = {
                displayName = "Prioritize Accuracy",
                description = "Prioritize accurate execution over maximum performance",
                type = "toggle",
                default = true
            },
            adaptCooldownUsage = {
                displayName = "Adapt Cooldown Usage",
                description = "Adapt cooldown usage based on skill level",
                type = "toggle",
                default = true
            },
            adaptResourceManagement = {
                displayName = "Adapt Resource Management",
                description = "Adapt resource management based on skill level",
                type = "toggle",
                default = true
            },
            adaptAoEHandling = {
                displayName = "Adapt AoE Handling",
                description = "Adapt AoE rotation complexity based on skill level",
                type = "toggle",
                default = true
            }
        },
        interfaceSettings = {
            showSkillLevel = {
                displayName = "Show Skill Level",
                description = "Display current skill level in the interface",
                type = "toggle",
                default = true
            },
            showSkillProgress = {
                displayName = "Show Skill Progress",
                description = "Display progress towards next skill level",
                type = "toggle",
                default = true
            },
            enableTutorials = {
                displayName = "Enable Tutorials",
                description = "Show class-specific tutorials based on skill level",
                type = "toggle",
                default = true
            },
            showAbilityHelp = {
                displayName = "Show Ability Help",
                description = "Show tooltips explaining ability usage",
                type = "toggle",
                default = true
            },
            complexityVisualization = {
                displayName = "Complexity Visualization",
                description = "How to visualize rotation complexity",
                type = "dropdown",
                options = { "text", "icons", "color_coding", "none" },
                default = "icons"
            }
        },
        manualOverrideSettings = {
            enableManualOverrides = {
                displayName = "Enable Manual Overrides",
                description = "Allow manually overriding automated system decisions",
                type = "toggle",
                default = true
            },
            defaultOverrideDuration = {
                displayName = "Default Override Duration",
                description = "Duration in minutes for temporary overrides",
                type = "slider",
                min = 1,
                max = 60,
                step = 1,
                default = 30
            },
            allowGlobalOverrides = {
                displayName = "Allow Global Overrides",
                description = "Allow overrides that apply to all characters",
                type = "toggle",
                default = false
            },
            rememberOverrides = {
                displayName = "Remember Overrides",
                description = "Remember and reapply manual overrides between sessions",
                type = "toggle",
                default = true
            }
        },
        classSpecificSettings = {
            customizeByClass = {
                displayName = "Customize By Class",
                description = "Apply class-specific skill scaling settings",
                type = "toggle",
                default = true
            },
            customizeBySpec = {
                displayName = "Customize By Specialization",
                description = "Apply spec-specific skill scaling settings",
                type = "toggle",
                default = true
            },
            enableClassTips = {
                displayName = "Enable Class Tips",
                description = "Show class-specific tip tooltips",
                type = "toggle",
                default = true
            },
            showSpecRecommendations = {
                displayName = "Show Spec Recommendations",
                description = "Show spec-specific recommendations for improvement",
                type = "toggle",
                default = true
            }
        },
        debugSettings = {
            enableDebugMode = {
                displayName = "Enable Debug Mode",
                description = "Enable detailed logging for skill system",
                type = "toggle",
                default = false
            },
            logSkillAssessments = {
                displayName = "Log Skill Assessments",
                description = "Log detailed skill assessment results",
                type = "toggle",
                default = false
            },
            showMetricValues = {
                displayName = "Show Metric Values",
                description = "Show raw metric values used for skill assessment",
                type = "toggle",
                default = false
            }
        }
    })
end

-- Setup skill profiles
function PlayerSkillSystem:SetupSkillProfiles()
    -- Create standard skill profiles
    skillProfiles = {
        beginner = {
            description = "New to the class or WoW in general",
            rotationComplexity = 0.2, -- 20% of full complexity
            decisionThreshold = 1.5, -- Longer time to make decisions
            resourceThreshold = 0.4, -- More conservative resource usage
            cooldownUsage = 0.3, -- Very basic cooldown usage
            movementHandling = 0.2, -- Simple movement handling
            aoeComplexity = 0.2, -- Simple AoE handling
            errorTolerance = 0.8, -- High tolerance for errors
            tutorialLevel = 1, -- Basic tutorials
            interfaceHelp = 1.0, -- Maximum interface help
            abilityCount = 4, -- Show fewer abilities
            features = {
                showBasicRotation = true,
                showOneAbilityAtATime = true,
                simplifyResourceManagement = true,
                useSingleTargetMode = true,
                highlightCoreAbilities = true,
                provideConstantFeedback = true
            }
        },
        novice = {
            description = "Basic familiarity with the class",
            rotationComplexity = 0.4,
            decisionThreshold = 1.2,
            resourceThreshold = 0.5,
            cooldownUsage = 0.5,
            movementHandling = 0.4,
            aoeComplexity = 0.4,
            errorTolerance = 0.6,
            tutorialLevel = 2,
            interfaceHelp = 0.8,
            abilityCount = 5,
            features = {
                showBasicRotation = true,
                showOneAbilityAtATime = false,
                simplifyResourceManagement = true,
                useSingleTargetMode = false,
                highlightCoreAbilities = true,
                provideConstantFeedback = true
            }
        },
        intermediate = {
            description = "Good understanding of core class mechanics",
            rotationComplexity = 0.6,
            decisionThreshold = 1.0,
            resourceThreshold = 0.6,
            cooldownUsage = 0.7,
            movementHandling = 0.6,
            aoeComplexity = 0.6,
            errorTolerance = 0.4,
            tutorialLevel = 3,
            interfaceHelp = 0.5,
            abilityCount = 6,
            features = {
                showBasicRotation = false,
                showOneAbilityAtATime = false,
                simplifyResourceManagement = false,
                useSingleTargetMode = false,
                highlightCoreAbilities = true,
                provideConstantFeedback = false
            }
        },
        advanced = {
            description = "Strong mastery of class and advanced mechanics",
            rotationComplexity = 0.8,
            decisionThreshold = 0.8,
            resourceThreshold = 0.8,
            cooldownUsage = 0.9,
            movementHandling = 0.8,
            aoeComplexity = 0.8,
            errorTolerance = 0.2,
            tutorialLevel = 4,
            interfaceHelp = 0.2,
            abilityCount = 7,
            features = {
                showBasicRotation = false,
                showOneAbilityAtATime = false,
                simplifyResourceManagement = false,
                useSingleTargetMode = false,
                highlightCoreAbilities = false,
                provideConstantFeedback = false
            }
        },
        expert = {
            description = "Complete mastery of all class systems",
            rotationComplexity = 1.0,
            decisionThreshold = 0.5,
            resourceThreshold = 1.0,
            cooldownUsage = 1.0,
            movementHandling = 1.0,
            aoeComplexity = 1.0,
            errorTolerance = 0.0,
            tutorialLevel = 5,
            interfaceHelp = 0.0,
            abilityCount = 8,
            features = {
                showBasicRotation = false,
                showOneAbilityAtATime = false,
                simplifyResourceManagement = false,
                useSingleTargetMode = false,
                highlightCoreAbilities = false,
                provideConstantFeedback = false
            }
        }
    }
    
    -- Add class-specific skill profiles
    -- Mage class-specific profiles
    skillProfiles.beginner[8] = { -- Mage class ID
        [1] = { -- Arcane
            description = "Beginner Arcane Mage",
            rotationSpecific = {
                conservePhaseOnly = true, -- Only use conserve phase rotation
                maxArcaneCharges = 3, -- Limit max Arcane Charges
                simplifiedManagement = true, -- Simplified mana management
                cooldownRestrictions = true -- Restrict cooldown usage to simple patterns
            }
        },
        [2] = { -- Fire
            description = "Beginner Fire Mage",
            rotationSpecific = {
                limitFireBlastUsage = true, -- Restrict Fire Blast usage
                simplifiedHotStreak = true, -- Simplified Hot Streak management
                predictablePattern = true -- Use a predictable, simple rotation pattern
            }
        },
        [3] = { -- Frost
            description = "Beginner Frost Mage",
            rotationSpecific = {
                skipShatterCombo = true, -- Skip complex Shatter combos
                simpleFoFUsage = true, -- Simplified Fingers of Frost usage
                noDelayedFlurry = true -- Don't delay Flurry usage for advanced techniques
            }
        }
    }
    
    -- Evoker class-specific profiles
    skillProfiles.beginner[13] = { -- Evoker class ID
        [1] = { -- Devastation
            description = "Beginner Devastation Evoker",
            rotationSpecific = {
                fixedEmpowerLevel = true, -- Use fixed empower levels
                simpleEssenceBuilding = true, -- Simple Essence building rotation
                limitedCooldownUsage = true -- Limited cooldown usage
            }
        },
        [2] = { -- Preservation
            description = "Beginner Preservation Evoker",
            rotationSpecific = {
                simpleHealingPriority = true, -- Simple healing priority
                fixedEmpowerLevel = true, -- Use fixed empower levels
                minimalDreamBreath = true -- Minimal Dream Breath usage
            }
        },
        [3] = { -- Augmentation
            description = "Beginner Augmentation Evoker",
            rotationSpecific = {
                simplifiedBuffPriority = true, -- Simple buff priority system
                limitedBronzeTimekeeper = true, -- Limited Bronze Timekeeper usage
                basicSelfBuffs = true -- Maintain basic self-buffs only
            }
        }
    }
    
    -- Setup metric weights for skill assessment
    metricWeights = {
        abilityUsageCorrectness = 0.25, -- How correctly abilities are used
        rotationPatternAdherence = 0.20, -- How closely optimal rotation is followed
        resourceManagementEfficiency = 0.15, -- How efficiently resources are managed
        cooldownOptimization = 0.15, -- How optimally cooldowns are used
        reactionTime = 0.10, -- How quickly player reacts to procs/changes
        movementEfficiency = 0.05, -- How well player handles movement
        aoeEfficiency = 0.05, -- How well player handles AoE situations
        situationalAwareness = 0.05 -- How well player responds to situation changes
    }
    
    API.PrintDebug("Skill profiles initialized")
}

-- Load saved settings
function PlayerSkillSystem:LoadSavedSettings()
    -- In a real addon, this would load from SavedVariables
    -- For our implementation, we'll use the default settings
    
    local settings = ConfigRegistry:GetSettings("PlayerSkillSystem")
    currentSkillLevel = settings.generalSettings.initialSkillLevel
    
    -- Initialize adaptive settings
    adaptiveSettings = {}
    
    -- Set up learning curve based on adaptation rate
    local adaptationRate = settings.adaptiveSettings.adaptationRate / 10 -- Convert to 0.1-1.0
    learningCurve = {
        assessmentWeight = adaptationRate, -- How much each new assessment affects skill level
        progressionThreshold = 0.75, -- Performance level needed to progress
        regressionThreshold = 0.25, -- Performance level to regress
        minimumAssessments = 3 -- Minimum assessments before level change
    }
    
    API.PrintDebug("Skill system settings loaded, current skill level: " .. currentSkillLevel)
}

-- Setup event handling
function PlayerSkillSystem:SetupEventHandling()
    -- Register for performance updates
    if PerformanceTracker then
        PerformanceTracker:RegisterCallback("OnPerformanceUpdate", function(metrics)
            self:ProcessPerformanceMetrics(metrics)
        end)
    end
    
    -- Register for combat end events
    API.RegisterEvent("PLAYER_REGEN_ENABLED", function()
        self:ProcessCombatEnd()
    end)
    
    -- Register for spec change events
    API.RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", function(unit)
        if unit == "player" then
            self:OnSpecializationChanged()
        end
    end)
    
    -- Register for level up events
    API.RegisterEvent("PLAYER_LEVEL_UP", function(level)
        self:OnLevelUp(level)
    end)
    
    -- Set up periodic skill assessment
    C_Timer.NewTicker(ASSESSMENT_INTERVAL, function()
        self:PerformPeriodicAssessment()
    end)
}

-- Initialize tutorials
function PlayerSkillSystem:InitializeTutorials()
    -- Setup tutorial steps for each class and skill level
    tutorialSteps = {
        [8] = { -- Mage
            [1] = { -- Arcane
                beginner = {
                    {
                        id = "arcane_basics",
                        title = "Arcane Basics",
                        description = "Arcane Mage's primary resource is Mana. You build Arcane Charges with Arcane Blast and spend them with Arcane Barrage.",
                        spellHighlights = { "arcane_blast", "arcane_barrage" },
                        triggerEvent = "spec_changed"
                    },
                    {
                        id = "conserve_phase",
                        title = "Conserving Mana",
                        description = "Try to keep your mana above 50% most of the time, using Arcane Blast to build up to 3 charges, then Arcane Barrage to reset.",
                        spellHighlights = { "arcane_blast", "arcane_barrage" },
                        triggerEvent = "first_combat"
                    },
                    {
                        id = "clearcasting",
                        title = "Using Clearcasting",
                        description = "When you see the Clearcasting proc, use Arcane Missiles for free damage without spending mana.",
                        spellHighlights = { "arcane_missiles" },
                        triggerEvent = "clearcasting_proc"
                    }
                },
                novice = {
                    {
                        id = "burn_phase",
                        title = "Burn Phase Basics",
                        description = "During Arcane Power, you want to stay at 4 Arcane Charges and cast as many Arcane Blasts as possible.",
                        spellHighlights = { "arcane_power", "arcane_blast" },
                        triggerEvent = "arcane_power_cast"
                    },
                    {
                        id = "touch_of_the_magi",
                        title = "Touch of the Magi",
                        description = "Touch of the Magi stores damage and then explodes. Use it before your burst damage phase.",
                        spellHighlights = { "touch_of_the_magi" },
                        triggerEvent = "level_achievement"
                    }
                },
                intermediate = {
                    {
                        id = "advanced_burn",
                        title = "Advanced Burn Phase",
                        description = "Align Touch of the Magi with Arcane Power, then maintain 4 charges with Arcane Blast and use Arcane Barrage at the end.",
                        spellHighlights = { "touch_of_the_magi", "arcane_power", "arcane_blast", "arcane_barrage" },
                        triggerEvent = "burn_phase_started"
                    }
                }
            },
            [2] = { -- Fire
                beginner = {
                    {
                        id = "fire_basics",
                        title = "Fire Basics",
                        description = "Fire Mage revolves around creating and using Hot Streak procs for instant Pyroblasts.",
                        spellHighlights = { "fireball", "pyroblast" },
                        triggerEvent = "spec_changed"
                    }
                }
            },
            [3] = { -- Frost
                beginner = {
                    {
                        id = "frost_basics",
                        title = "Frost Basics",
                        description = "Frost Mage uses Frostbolt to generate Brain Freeze and Fingers of Frost procs.",
                        spellHighlights = { "frostbolt", "ice_lance", "flurry" },
                        triggerEvent = "spec_changed"
                    }
                }
            }
        },
        -- Add other classes here
        [13] = { -- Evoker
            [1] = { -- Devastation
                beginner = {
                    {
                        id = "devastation_basics",
                        title = "Devastation Basics",
                        description = "Devastation Evokers use Essence as their primary resource and have unique Empowered spells.",
                        spellHighlights = { "living_flame", "fire_breath" },
                        triggerEvent = "spec_changed"
                    }
                }
            }
            -- Add other Evoker specs
        }
    }
    
    API.PrintDebug("Tutorials initialized")
}

-- Process performance metrics
function PlayerSkillSystem:ProcessPerformanceMetrics(metrics)
    if not metrics then
        return
    end
    
    -- Store performance metrics
    playerMetrics = metrics
    
    -- Accumulate data for skill assessment
    if not skillAssessment.metrics then
        skillAssessment.metrics = {}
    end
    
    for metricName, value in pairs(metrics) do
        if not skillAssessment.metrics[metricName] then
            skillAssessment.metrics[metricName] = {
                sum = value,
                count = 1,
                min = value,
                max = value
            }
        else
            local data = skillAssessment.metrics[metricName]
            data.sum = data.sum + value
            data.count = data.count + 1
            data.min = math.min(data.min, value)
            data.max = math.max(data.max, value)
        end
    end
    
    -- Assess skill if we have enough data and enough time has passed
    local now = GetTime()
    if now - lastAssessmentTime >= ASSESSMENT_INTERVAL then
        self:AssessPlayerSkill()
        lastAssessmentTime = now
    end
}

-- Process combat end
function PlayerSkillSystem:ProcessCombatEnd()
    -- This would be called when combat ends
    local settings = ConfigRegistry:GetSettings("PlayerSkillSystem")
    
    -- Skip if disabled
    if not settings.generalSettings.enableSkillScaling then
        return
    end
    
    -- Check if we should trigger any tutorials
    if settings.interfaceSettings.enableTutorials then
        self:CheckTutorialTriggers("combat_end")
    end
    
    -- Check if we have combat analysis data
    if CombatAnalysis then
        local combatData = CombatAnalysis:GetLatestCombatData()
        if combatData then
            self:ProcessCombatData(combatData)
        end
    end
}

-- Process combat data
function PlayerSkillSystem:ProcessCombatData(combatData)
    -- Analyze combat data for skill assessment
    if not combatData then
        return
    end
    
    -- Extract relevant metrics
    local metrics = {
        dps = combatData.dps or 0,
        rotationEfficiency = combatData.rotationEfficiency or 0,
        resourceEfficiency = combatData.resourceEfficiency or 0,
        cooldownUsage = combatData.cooldownUsage or 0,
        movementHandling = combatData.movementHandling or 0,
        aoeEfficiency = combatData.aoeEfficiency or 0
    }
    
    -- Add to skill assessment data
    if not skillAssessment.combatData then
        skillAssessment.combatData = {}
    end
    
    table.insert(skillAssessment.combatData, {
        timestamp = GetTime(),
        metrics = metrics,
        duration = combatData.duration or 0
    })
    
    -- Trim data if needed
    if #skillAssessment.combatData > 10 then
        table.remove(skillAssessment.combatData, 1)
    end
    
    -- Log combat data
    local settings = ConfigRegistry:GetSettings("PlayerSkillSystem")
    if settings.debugSettings.logSkillAssessments then
        API.PrintDebug("Combat data processed for skill assessment")
        API.PrintDebug("DPS: " .. metrics.dps .. ", Rotation: " .. metrics.rotationEfficiency .. 
                      ", Resource: " .. metrics.resourceEfficiency)
    end
}

-- Handle specialization change
function PlayerSkillSystem:OnSpecializationChanged()
    -- Reset skill assessment for the new spec
    skillAssessment = {}
    
    -- Trigger tutorials for new spec
    self:CheckTutorialTriggers("spec_changed")
    
    -- Apply skill level settings for the new spec
    self:ApplySkillLevelSettings()
    
    API.PrintDebug("Specialization changed, skill assessment reset")
}

-- Handle level up
function PlayerSkillSystem:OnLevelUp(level)
    -- This would handle level-up events
    self:CheckTutorialTriggers("level_up", level)
    
    -- Check if we should adjust skill level based on player level
    -- Higher level players might start at higher skill levels
    if level >= 60 and currentSkillLevel == "beginner" then
        -- Consider advancing skill level for higher level players
        self:ConsiderSkillAdvancement(0.5) -- 50% chance to advance
    end
}

-- Perform periodic skill assessment
function PlayerSkillSystem:PerformPeriodicAssessment()
    local settings = ConfigRegistry:GetSettings("PlayerSkillSystem")
    
    -- Skip if disabled
    if not settings.generalSettings.enableSkillScaling or not settings.generalSettings.enableAutomaticAssessment then
        return
    end
    
    -- Assess player skill
    self:AssessPlayerSkill()
}

-- Assess player skill
function PlayerSkillSystem:AssessPlayerSkill()
    -- Skip if not enough data
    if not skillAssessment.metrics or not next(skillAssessment.metrics) then
        return
    end
    
    local settings = ConfigRegistry:GetSettings("PlayerSkillSystem")
    
    -- Calculate assessment scores
    local scores = self:CalculateSkillScores()
    
    -- Calculate overall score
    local overallScore = 0
    local totalWeight = 0
    
    for metricName, weight in pairs(metricWeights) do
        if scores[metricName] then
            overallScore = overallScore + (scores[metricName] * weight)
            totalWeight = totalWeight + weight
        end
    end
    
    -- Normalize overall score
    if totalWeight > 0 then
        overallScore = overallScore / totalWeight
    end
    
    -- Add to skill history
    table.insert(skillHistory, {
        timestamp = GetTime(),
        score = overallScore,
        scores = scores,
        skillLevel = currentSkillLevel
    })
    
    -- Trim history if needed
    if #skillHistory > MAX_SKILL_HISTORY then
        table.remove(skillHistory, 1)
    end
    
    -- Log assessment
    if settings.debugSettings.logSkillAssessments then
        API.PrintDebug("Skill assessment completed: " .. string.format("%.2f", overallScore * 100) .. "% overall")
        
        for metricName, score in pairs(scores) do
            API.PrintDebug("  " .. metricName .. ": " .. string.format("%.2f", score * 100) .. "%")
        end
    end
    
    -- Consider skill level progression
    if settings.generalSettings.allowSkillProgression then
        self:ConsiderSkillProgression(overallScore)
    end
    
    -- Update adaptive settings
    self:UpdateAdaptiveSettings(scores)
    
    -- Return assessment results
    return {
        overallScore = overallScore,
        scores = scores,
        skillLevel = currentSkillLevel
    }
}

-- Calculate skill scores from metrics
function PlayerSkillSystem:CalculateSkillScores()
    local scores = {}
    
    -- Skill components to evaluate
    scores.abilityUsageCorrectness = self:EvaluateAbilityUsageCorrectness()
    scores.rotationPatternAdherence = self:EvaluateRotationPatternAdherence()
    scores.resourceManagementEfficiency = self:EvaluateResourceManagement()
    scores.cooldownOptimization = self:EvaluateCooldownOptimization()
    scores.reactionTime = self:EvaluateReactionTime()
    scores.movementEfficiency = self:EvaluateMovementEfficiency()
    scores.aoeEfficiency = self:EvaluateAoEEfficiency()
    scores.situationalAwareness = self:EvaluateSituationalAwareness()
    
    return scores
end

-- Evaluate ability usage correctness
function PlayerSkillSystem:EvaluateAbilityUsageCorrectness()
    -- This would compare ability usage to optimal patterns
    -- For implementation simplicity, we'll use a placeholder
    
    -- In a real implementation, this would analyze combat logs
    -- and compare to ideal rotation patterns
    
    -- Get data from ML system if available
    if MachineLearning and MachineLearning.GetAbilityUsageCorrectness then
        local score = MachineLearning:GetAbilityUsageCorrectness()
        if score then
            return score
        end
    end
    
    -- Placeholder implementation with random variation
    local baseScore = 0.5 -- Default middle score
    local skillLevelAdjustment = 0
    
    -- Adjust based on current skill level
    if currentSkillLevel == "beginner" then
        skillLevelAdjustment = -0.1
    elseif currentSkillLevel == "novice" then
        skillLevelAdjustment = -0.05
    elseif currentSkillLevel == "advanced" then
        skillLevelAdjustment = 0.1
    elseif currentSkillLevel == "expert" then
        skillLevelAdjustment = 0.2
    end
    
    -- Add some randomness (±15%)
    local randomVariation = (math.random() * 0.3) - 0.15
    
    -- Calculate final score (clamped to 0-1)
    local score = math.max(0, math.min(1, baseScore + skillLevelAdjustment + randomVariation))
    return score
end

-- Evaluate rotation pattern adherence
function PlayerSkillSystem:EvaluateRotationPatternAdherence()
    -- This would evaluate how well the player follows optimal rotation patterns
    
    -- Get data from combat analysis if available
    if CombatAnalysis and skillAssessment.combatData then
        local rotationScores = {}
        
        for _, data in ipairs(skillAssessment.combatData) do
            if data.metrics and data.metrics.rotationEfficiency then
                table.insert(rotationScores, data.metrics.rotationEfficiency)
            end
        end
        
        if #rotationScores > 0 then
            -- Calculate average rotation efficiency
            local total = 0
            for _, score in ipairs(rotationScores) do
                total = total + score
            end
            
            return total / #rotationScores
        end
    end
    
    -- Placeholder implementation with random variation
    local baseScore = 0.5 -- Default middle score
    local skillLevelAdjustment = 0
    
    -- Adjust based on current skill level
    if currentSkillLevel == "beginner" then
        skillLevelAdjustment = -0.15
    elseif currentSkillLevel == "novice" then
        skillLevelAdjustment = -0.05
    elseif currentSkillLevel == "advanced" then
        skillLevelAdjustment = 0.1
    elseif currentSkillLevel == "expert" then
        skillLevelAdjustment = 0.25
    end
    
    -- Add some randomness (±10%)
    local randomVariation = (math.random() * 0.2) - 0.1
    
    -- Calculate final score (clamped to 0-1)
    local score = math.max(0, math.min(1, baseScore + skillLevelAdjustment + randomVariation))
    return score
end

-- Evaluate resource management
function PlayerSkillSystem:EvaluateResourceManagement()
    -- This would evaluate resource usage efficiency
    
    -- Get data from combat analysis if available
    if CombatAnalysis and skillAssessment.combatData then
        local resourceScores = {}
        
        for _, data in ipairs(skillAssessment.combatData) do
            if data.metrics and data.metrics.resourceEfficiency then
                table.insert(resourceScores, data.metrics.resourceEfficiency)
            end
        end
        
        if #resourceScores > 0 then
            -- Calculate average resource efficiency
            local total = 0
            for _, score in ipairs(resourceScores) do
                total = total + score
            end
            
            return total / #resourceScores
        end
    end
    
    -- Placeholder implementation with random variation
    local baseScore = 0.5 -- Default middle score
    local skillLevelAdjustment = 0
    
    -- Adjust based on current skill level
    if currentSkillLevel == "beginner" then
        skillLevelAdjustment = -0.2
    elseif currentSkillLevel == "novice" then
        skillLevelAdjustment = -0.1
    elseif currentSkillLevel == "advanced" then
        skillLevelAdjustment = 0.15
    elseif currentSkillLevel == "expert" then
        skillLevelAdjustment = 0.3
    end
    
    -- Add some randomness (±15%)
    local randomVariation = (math.random() * 0.3) - 0.15
    
    -- Calculate final score (clamped to 0-1)
    local score = math.max(0, math.min(1, baseScore + skillLevelAdjustment + randomVariation))
    return score
end

-- Evaluate cooldown optimization
function PlayerSkillSystem:EvaluateCooldownOptimization()
    -- This would evaluate how effectively cooldowns are used
    
    -- Get data from combat analysis if available
    if CombatAnalysis and skillAssessment.combatData then
        local cooldownScores = {}
        
        for _, data in ipairs(skillAssessment.combatData) do
            if data.metrics and data.metrics.cooldownUsage then
                table.insert(cooldownScores, data.metrics.cooldownUsage)
            end
        end
        
        if #cooldownScores > 0 then
            -- Calculate average cooldown usage
            local total = 0
            for _, score in ipairs(cooldownScores) do
                total = total + score
            end
            
            return total / #cooldownScores
        end
    end
    
    -- Placeholder implementation with random variation
    local baseScore = 0.5 -- Default middle score
    local skillLevelAdjustment = 0
    
    -- Adjust based on current skill level
    if currentSkillLevel == "beginner" then
        skillLevelAdjustment = -0.25
    elseif currentSkillLevel == "novice" then
        skillLevelAdjustment = -0.15
    elseif currentSkillLevel == "advanced" then
        skillLevelAdjustment = 0.15
    elseif currentSkillLevel == "expert" then
        skillLevelAdjustment = 0.3
    end
    
    -- Add some randomness (±10%)
    local randomVariation = (math.random() * 0.2) - 0.1
    
    -- Calculate final score (clamped to 0-1)
    local score = math.max(0, math.min(1, baseScore + skillLevelAdjustment + randomVariation))
    return score
end

-- Evaluate reaction time
function PlayerSkillSystem:EvaluateReactionTime()
    -- This would evaluate how quickly the player reacts to procs and mechanics
    
    -- Placeholder implementation with random variation
    local baseScore = 0.5 -- Default middle score
    local skillLevelAdjustment = 0
    
    -- Adjust based on current skill level
    if currentSkillLevel == "beginner" then
        skillLevelAdjustment = -0.2
    elseif currentSkillLevel == "novice" then
        skillLevelAdjustment = -0.1
    elseif currentSkillLevel == "advanced" then
        skillLevelAdjustment = 0.1
    elseif currentSkillLevel == "expert" then
        skillLevelAdjustment = 0.2
    end
    
    -- Add some randomness (±20%)
    local randomVariation = (math.random() * 0.4) - 0.2
    
    -- Calculate final score (clamped to 0-1)
    local score = math.max(0, math.min(1, baseScore + skillLevelAdjustment + randomVariation))
    return score
end

-- Evaluate movement efficiency
function PlayerSkillSystem:EvaluateMovementEfficiency()
    -- This would evaluate how well the player maintains DPS while moving
    
    -- Get data from combat analysis if available
    if CombatAnalysis and skillAssessment.combatData then
        local movementScores = {}
        
        for _, data in ipairs(skillAssessment.combatData) do
            if data.metrics and data.metrics.movementHandling then
                table.insert(movementScores, data.metrics.movementHandling)
            end
        end
        
        if #movementScores > 0 then
            -- Calculate average movement handling
            local total = 0
            for _, score in ipairs(movementScores) do
                total = total + score
            end
            
            return total / #movementScores
        end
    end
    
    -- Placeholder implementation with random variation
    local baseScore = 0.5 -- Default middle score
    local skillLevelAdjustment = 0
    
    -- Adjust based on current skill level
    if currentSkillLevel == "beginner" then
        skillLevelAdjustment = -0.3
    elseif currentSkillLevel == "novice" then
        skillLevelAdjustment = -0.15
    elseif currentSkillLevel == "advanced" then
        skillLevelAdjustment = 0.15
    elseif currentSkillLevel == "expert" then
        skillLevelAdjustment = 0.25
    end
    
    -- Add some randomness (±15%)
    local randomVariation = (math.random() * 0.3) - 0.15
    
    -- Calculate final score (clamped to 0-1)
    local score = math.max(0, math.min(1, baseScore + skillLevelAdjustment + randomVariation))
    return score
end

-- Evaluate AoE efficiency
function PlayerSkillSystem:EvaluateAoEEfficiency()
    -- This would evaluate how effectively AoE rotations are executed
    
    -- Get data from combat analysis if available
    if CombatAnalysis and skillAssessment.combatData then
        local aoeScores = {}
        
        for _, data in ipairs(skillAssessment.combatData) do
            if data.metrics and data.metrics.aoeEfficiency then
                table.insert(aoeScores, data.metrics.aoeEfficiency)
            end
        end
        
        if #aoeScores > 0 then
            -- Calculate average AoE efficiency
            local total = 0
            for _, score in ipairs(aoeScores) do
                total = total + score
            end
            
            return total / #aoeScores
        end
    end
    
    -- Placeholder implementation with random variation
    local baseScore = 0.5 -- Default middle score
    local skillLevelAdjustment = 0
    
    -- Adjust based on current skill level
    if currentSkillLevel == "beginner" then
        skillLevelAdjustment = -0.3
    elseif currentSkillLevel == "novice" then
        skillLevelAdjustment = -0.2
    elseif currentSkillLevel == "advanced" then
        skillLevelAdjustment = 0.1
    elseif currentSkillLevel == "expert" then
        skillLevelAdjustment = 0.2
    end
    
    -- Add some randomness (±15%)
    local randomVariation = (math.random() * 0.3) - 0.15
    
    -- Calculate final score (clamped to 0-1)
    local score = math.max(0, math.min(1, baseScore + skillLevelAdjustment + randomVariation))
    return score
end

-- Evaluate situational awareness
function PlayerSkillSystem:EvaluateSituationalAwareness()
    -- This would evaluate how well the player adapts to different situations
    
    -- Placeholder implementation with random variation
    local baseScore = 0.5 -- Default middle score
    local skillLevelAdjustment = 0
    
    -- Adjust based on current skill level
    if currentSkillLevel == "beginner" then
        skillLevelAdjustment = -0.25
    elseif currentSkillLevel == "novice" then
        skillLevelAdjustment = -0.15
    elseif currentSkillLevel == "advanced" then
        skillLevelAdjustment = 0.15
    elseif currentSkillLevel == "expert" then
        skillLevelAdjustment = 0.3
    end
    
    -- Add some randomness (±15%)
    local randomVariation = (math.random() * 0.3) - 0.15
    
    -- Calculate final score (clamped to 0-1)
    local score = math.max(0, math.min(1, baseScore + skillLevelAdjustment + randomVariation))
    return score
end

-- Consider skill progression
function PlayerSkillSystem:ConsiderSkillProgression(overallScore)
    -- Check if we should advance or regress skill level
    
    -- Find the index of current skill level
    local currentIndex = 1
    for i, level in ipairs(SKILL_LEVELS) do
        if level == currentSkillLevel then
            currentIndex = i
            break
        end
    end
    
    -- Check if we should progress
    local progressThreshold = learningCurve.progressionThreshold
    local regressThreshold = learningCurve.regressionThreshold
    
    -- Look at recent skill history
    local recentAssessments = 0
    local scoreSum = 0
    
    for i = #skillHistory, math.max(1, #skillHistory - 10), -1 do
        if skillHistory[i].skillLevel == currentSkillLevel then
            recentAssessments = recentAssessments + 1
            scoreSum = scoreSum + skillHistory[i].score
        end
    end
    
    -- Calculate average score
    local averageScore = 0
    if recentAssessments > 0 then
        averageScore = scoreSum / recentAssessments
    else
        averageScore = overallScore
    end
    
    -- Check if we have enough assessments
    if recentAssessments >= learningCurve.minimumAssessments then
        -- Check for progression
        if averageScore >= progressThreshold and currentIndex < #SKILL_LEVELS then
            self:AdvanceSkillLevel()
        -- Check for regression
        elseif averageScore <= regressThreshold and currentIndex > 1 then
            self:RegressSkillLevel()
        end
    end
}

-- Advance skill level
function PlayerSkillSystem:AdvanceSkillLevel()
    -- Find current index
    local currentIndex = 1
    for i, level in ipairs(SKILL_LEVELS) do
        if level == currentSkillLevel then
            currentIndex = i
            break
        end
    end
    
    -- Advance if possible
    if currentIndex < #SKILL_LEVELS then
        local oldLevel = currentSkillLevel
        currentSkillLevel = SKILL_LEVELS[currentIndex + 1]
        
        -- Apply new settings
        self:ApplySkillLevelSettings()
        
        -- Notify user
        API.Print("Your skill level has advanced to " .. currentSkillLevel .. "!")
        
        -- Log progression
        API.PrintDebug("Skill level advanced from " .. oldLevel .. " to " .. currentSkillLevel)
        
        -- Add progression event to history
        table.insert(skillProgression, {
            timestamp = GetTime(),
            from = oldLevel,
            to = currentSkillLevel,
            reason = "automatic_progression"
        })
        
        -- Trigger appropriate tutorials
        self:CheckTutorialTriggers("skill_advanced", currentSkillLevel)
        
        return true
    end
    
    return false
end

-- Regress skill level
function PlayerSkillSystem:RegressSkillLevel()
    -- Find current index
    local currentIndex = 1
    for i, level in ipairs(SKILL_LEVELS) do
        if level == currentSkillLevel then
            currentIndex = i
            break
        end
    end
    
    -- Regress if possible
    if currentIndex > 1 then
        local oldLevel = currentSkillLevel
        currentSkillLevel = SKILL_LEVELS[currentIndex - 1]
        
        -- Apply new settings
        self:ApplySkillLevelSettings()
        
        -- Notify user
        API.Print("Your skill level has adjusted to " .. currentSkillLevel .. " for better learning.")
        
        -- Log regression
        API.PrintDebug("Skill level regressed from " .. oldLevel .. " to " .. currentSkillLevel)
        
        -- Add regression event to history
        table.insert(skillProgression, {
            timestamp = GetTime(),
            from = oldLevel,
            to = currentSkillLevel,
            reason = "automatic_regression"
        })
        
        -- Trigger appropriate tutorials
        self:CheckTutorialTriggers("skill_regressed", currentSkillLevel)
        
        return true
    end
    
    return false
end

-- Consider skill advancement (manual or triggered)
function PlayerSkillSystem:ConsiderSkillAdvancement(chance)
    chance = chance or 1.0
    
    -- Only advance if random check passes
    if math.random() > chance then
        return false
    end
    
    return self:AdvanceSkillLevel()
end

-- Apply skill level settings
function PlayerSkillSystem:ApplySkillLevelSettings()
    -- Get profile for current skill level
    local profile = skillProfiles[currentSkillLevel]
    if not profile then
        return
    end
    
    -- Apply general settings from profile
    self:ApplyGeneralSkillSettings(profile)
    
    -- Apply class/spec specific settings if available
    local classID = API.GetPlayerClassID()
    local specID = API.GetActiveSpecID()
    
    if profile[classID] and profile[classID][specID] then
        self:ApplyClassSpecificSettings(profile[classID][specID])
    end
    
    -- Apply any manual overrides
    self:ApplyManualOverrides()
    
    -- Apply adaptive settings
    self:ApplyAdaptiveSettings()
    
    API.PrintDebug("Applied skill level settings for " .. currentSkillLevel)
}

-- Apply general skill settings
function PlayerSkillSystem:ApplyGeneralSkillSettings(profile)
    -- This would apply general settings from the skill profile
    
    -- Update rotation complexity
    if WR.RotationComplexity then
        WR.RotationComplexity:SetComplexityLevel(profile.rotationComplexity)
    end
    
    -- Update UI help level
    if WR.ConfigurationUI then
        WR.ConfigurationUI:SetHelpLevel(profile.interfaceHelp)
    end
    
    -- Update ability display count
    if WR.VisualOverlay then
        WR.VisualOverlay:SetAbilityCount(profile.abilityCount)
    end
    
    -- Apply feature flags
    for feature, enabled in pairs(profile.features) do
        if WR.FeatureFlags then
            WR.FeatureFlags:SetFeatureEnabled(feature, enabled)
        end
    end
}

-- Apply class/spec specific settings
function PlayerSkillSystem:ApplyClassSpecificSettings(specProfile)
    -- This would apply class/spec specific settings
    
    if not specProfile or not specProfile.rotationSpecific then
        return
    end
    
    -- Apply rotation-specific settings
    for setting, value in pairs(specProfile.rotationSpecific) do
        if WR.RotationSettings then
            WR.RotationSettings:SetValue(setting, value)
        end
    end
}

-- Update adaptive settings
function PlayerSkillSystem:UpdateAdaptiveSettings(scores)
    -- This would update adaptive settings based on assessment
    local settings = ConfigRegistry:GetSettings("PlayerSkillSystem")
    
    -- Skip if adaptive settings not enabled
    if not settings.adaptiveSettings.adaptCooldownUsage and
       not settings.adaptiveSettings.adaptResourceManagement and
       not settings.adaptiveSettings.adaptAoEHandling then
        return
    end
    
    -- Update cooldown usage adaptation
    if settings.adaptiveSettings.adaptCooldownUsage and scores.cooldownOptimization then
        adaptiveSettings.cooldownUsageLevel = scores.cooldownOptimization
    end
    
    -- Update resource management adaptation
    if settings.adaptiveSettings.adaptResourceManagement and scores.resourceManagementEfficiency then
        adaptiveSettings.resourceManagementLevel = scores.resourceManagementEfficiency
    end
    
    -- Update AoE handling adaptation
    if settings.adaptiveSettings.adaptAoEHandling and scores.aoeEfficiency then
        adaptiveSettings.aoeHandlingLevel = scores.aoeEfficiency
    end
    
    -- Apply the updated adaptive settings
    self:ApplyAdaptiveSettings()
}

-- Apply adaptive settings
function PlayerSkillSystem:ApplyAdaptiveSettings()
    -- This would apply current adaptive settings
    local settings = ConfigRegistry:GetSettings("PlayerSkillSystem")
    
    -- Skip if not enabled
    if not settings.generalSettings.enableSkillScaling then
        return
    end
    
    -- Apply cooldown usage adaptation
    if settings.adaptiveSettings.adaptCooldownUsage and adaptiveSettings.cooldownUsageLevel then
        -- This would adjust how cooldowns are used based on player skill
        -- For implementation simplicity, we'll use a placeholder
        API.PrintDebug("Applied adaptive cooldown usage: " .. 
                       string.format("%.2f", adaptiveSettings.cooldownUsageLevel))
    end
    
    -- Apply resource management adaptation
    if settings.adaptiveSettings.adaptResourceManagement and adaptiveSettings.resourceManagementLevel then
        -- This would adjust resource thresholds based on player skill
        -- For implementation simplicity, we'll use a placeholder
        API.PrintDebug("Applied adaptive resource management: " .. 
                       string.format("%.2f", adaptiveSettings.resourceManagementLevel))
    end
    
    -- Apply AoE handling adaptation
    if settings.adaptiveSettings.adaptAoEHandling and adaptiveSettings.aoeHandlingLevel then
        -- This would adjust AoE rotation complexity based on player skill
        -- For implementation simplicity, we'll use a placeholder
        API.PrintDebug("Applied adaptive AoE handling: " .. 
                       string.format("%.2f", adaptiveSettings.aoeHandlingLevel))
    end
}

-- Apply manual overrides
function PlayerSkillSystem:ApplyManualOverrides()
    -- This would apply any manual overrides set by the user
    local settings = ConfigRegistry:GetSettings("PlayerSkillSystem")
    
    -- Skip if manual overrides not enabled
    if not settings.manualOverrideSettings.enableManualOverrides then
        return
    end
    
    -- Check each override
    local now = GetTime()
    local overridesToRemove = {}
    
    for setting, override in pairs(manualOverrides) do
        -- Check if override has expired
        if override.expiration and now > override.expiration then
            table.insert(overridesToRemove, setting)
        else
            -- Apply the override
            if WR.RotationSettings and override.value ~= nil then
                WR.RotationSettings:SetValue(setting, override.value)
                API.PrintDebug("Applied manual override for " .. setting)
            end
        end
    end
    
    -- Remove expired overrides
    for _, setting in ipairs(overridesToRemove) do
        manualOverrides[setting] = nil
        API.PrintDebug("Removed expired override for " .. setting)
    end
}

-- Check tutorial triggers
function PlayerSkillSystem:CheckTutorialTriggers(triggerEvent, data)
    local settings = ConfigRegistry:GetSettings("PlayerSkillSystem")
    
    -- Skip if tutorials disabled
    if not settings.interfaceSettings.enableTutorials then
        return
    end
    
    -- Get class and spec
    local classID = API.GetPlayerClassID()
    local specID = API.GetActiveSpecID()
    
    -- Check if we have tutorials for this class/spec
    if not tutorialSteps[classID] or not tutorialSteps[classID][specID] then
        return
    end
    
    -- Check if we have tutorials for current skill level
    local levelTutorials = tutorialSteps[classID][specID][currentSkillLevel]
    if not levelTutorials then
        return
    end
    
    -- Check each tutorial for this level
    for _, tutorial in ipairs(levelTutorials) do
        -- Skip if already completed
        if completedTutorials[tutorial.id] then
            goto continue
        end
        
        -- Check if trigger matches
        if tutorial.triggerEvent == triggerEvent then
            -- Show the tutorial
            self:ShowTutorial(tutorial)
            break
        end
        
        ::continue::
    end
end

-- Show a tutorial
function PlayerSkillSystem:ShowTutorial(tutorial)
    -- This would display a tutorial to the user
    -- For implementation simplicity, we'll just print it
    
    API.Print("|cFF00CCFF" .. tutorial.title .. "|r")
    API.Print(tutorial.description)
    
    -- Mark as completed
    completedTutorials[tutorial.id] = GetTime()
    
    -- Set as active tutorial
    activeTutorial = tutorial
    
    -- Highlight spells if needed
    if tutorial.spellHighlights and WR.VisualOverlay then
        for _, spellName in ipairs(tutorial.spellHighlights) do
            WR.VisualOverlay:HighlightAbility(spellName, 5) -- Highlight for 5 seconds
        end
    end
    
    API.PrintDebug("Showed tutorial: " .. tutorial.id)
}

-- Get the current skill level
function PlayerSkillSystem:GetCurrentSkillLevel()
    return currentSkillLevel
end

-- Get skill profile
function PlayerSkillSystem:GetSkillProfile(level)
    level = level or currentSkillLevel
    return skillProfiles[level]
end

-- Get class specific profile
function PlayerSkillSystem:GetClassSpecificProfile(level)
    level = level or currentSkillLevel
    
    local classID = API.GetPlayerClassID()
    local specID = API.GetActiveSpecID()
    
    if not skillProfiles[level] or not skillProfiles[level][classID] then
        return nil
    end
    
    return skillProfiles[level][classID][specID]
end

-- Set a manual override
function PlayerSkillSystem:SetManualOverride(setting, value, duration)
    local settings = ConfigRegistry:GetSettings("PlayerSkillSystem")
    
    -- Skip if manual overrides not enabled
    if not settings.manualOverrideSettings.enableManualOverrides then
        return false
    end
    
    -- Set the override
    local expiration = nil
    if duration then
        expiration = GetTime() + (duration * 60) -- Convert minutes to seconds
    end
    
    manualOverrides[setting] = {
        value = value,
        expiration = expiration,
        timestamp = GetTime()
    }
    
    -- Apply immediately
    if WR.RotationSettings then
        WR.RotationSettings:SetValue(setting, value)
    end
    
    API.PrintDebug("Set manual override for " .. setting .. " to " .. tostring(value) .. 
                   (expiration and " (expires in " .. duration .. " minutes)" or " (permanent)"))
    
    return true
end

-- Clear a manual override
function PlayerSkillSystem:ClearManualOverride(setting)
    if manualOverrides[setting] then
        manualOverrides[setting] = nil
        
        API.PrintDebug("Cleared manual override for " .. setting)
        
        -- Re-apply skill settings to restore default
        self:ApplySkillLevelSettings()
        
        return true
    end
    
    return false
end

-- Get active overrides
function PlayerSkillSystem:GetActiveOverrides()
    return manualOverrides
end

-- Get skill history
function PlayerSkillSystem:GetSkillHistory()
    return skillHistory
end

-- Get skill progression history
function PlayerSkillSystem:GetSkillProgression()
    return skillProgression
end

-- Manually set skill level
function PlayerSkillSystem:SetSkillLevel(level, reason)
    -- Validate level
    local valid = false
    for _, skillLevel in ipairs(SKILL_LEVELS) do
        if skillLevel == level then
            valid = true
            break
        end
    end
    
    if not valid then
        return false
    end
    
    -- Set the level
    local oldLevel = currentSkillLevel
    currentSkillLevel = level
    
    -- Apply new settings
    self:ApplySkillLevelSettings()
    
    -- Add to progression history
    table.insert(skillProgression, {
        timestamp = GetTime(),
        from = oldLevel,
        to = level,
        reason = reason or "manual_change"
    })
    
    -- Notify user
    API.Print("Skill level set to " .. level)
    
    -- Trigger appropriate tutorials
    self:CheckTutorialTriggers("skill_changed", level)
    
    -- Log change
    API.PrintDebug("Skill level manually changed from " .. oldLevel .. " to " .. level)
    
    return true
end

-- Handle slash command
function PlayerSkillSystem:HandleSlashCommand(msg)
    if not msg or msg == "" then
        -- Show help
        API.Print("WindrunnerRotations Skill System Commands:")
        API.Print("/wrskill status - Show current skill status")
        API.Print("/wrskill set [level] - Set skill level (beginner, novice, intermediate, advanced, expert)")
        API.Print("/wrskill override [setting] [value] [duration] - Set a manual override")
        API.Print("/wrskill clear [setting] - Clear a manual override")
        API.Print("/wrskill tutorial [id] - Show a specific tutorial")
        API.Print("/wrskill assess - Perform a skill assessment")
        API.Print("/wrskill adaptations - Show active adaptations")
        return
    end
    
    local args = {}
    for arg in string.gmatch(msg, "%S+") do
        table.insert(args, arg)
    end
    
    local command = args[1]
    
    if command == "status" then
        -- Show skill status
        API.Print("Current Skill Level: " .. currentSkillLevel)
        
        local profile = self:GetSkillProfile()
        if profile then
            API.Print("Description: " .. profile.description)
        end
        
        -- Show class-specific settings
        local classProfile = self:GetClassSpecificProfile()
        if classProfile then
            API.Print("Class Profile: " .. classProfile.description)
        end
        
        -- Show recent assessments
        if #skillHistory > 0 then
            API.Print("Recent Skill Assessment: " .. 
                     string.format("%.1f", skillHistory[#skillHistory].score * 100) .. "%")
        end
        
        -- Show active overrides
        local overrideCount = 0
        for _ in pairs(manualOverrides) do
            overrideCount = overrideCount + 1
        end
        
        if overrideCount > 0 then
            API.Print("Active Overrides: " .. overrideCount)
        end
    elseif command == "set" then
        -- Set skill level
        local level = args[2]
        
        if not level then
            API.Print("Please specify a skill level: beginner, novice, intermediate, advanced, expert")
            return
        end
        
        if self:SetSkillLevel(level, "manual_command") then
            API.Print("Skill level set to " .. level)
        else
            API.Print("Invalid skill level: " .. level)
            API.Print("Valid levels: beginner, novice, intermediate, advanced, expert")
        end
    elseif command == "override" then
        -- Set an override
        local setting = args[2]
        local value = args[3]
        local duration = tonumber(args[4])
        
        if not setting or not value then
            API.Print("Please specify a setting and value")
            return
        end
        
        -- Parse value
        local parsedValue
        if value == "true" then
            parsedValue = true
        elseif value == "false" then
            parsedValue = false
        elseif tonumber(value) then
            parsedValue = tonumber(value)
        else
            parsedValue = value
        end
        
        if self:SetManualOverride(setting, parsedValue, duration) then
            API.Print("Override set for " .. setting .. ": " .. tostring(parsedValue) .. 
                      (duration and " (expires in " .. duration .. " minutes)" or ""))
        else
            API.Print("Failed to set override. Manual overrides might be disabled.")
        end
    elseif command == "clear" then
        -- Clear an override
        local setting = args[2]
        
        if not setting then
            API.Print("Please specify a setting to clear")
            return
        end
        
        if self:ClearManualOverride(setting) then
            API.Print("Override cleared for " .. setting)
        else
            API.Print("No override found for " .. setting)
        end
    elseif command == "tutorial" then
        -- Show a tutorial
        local tutorialID = args[2]
        
        if not tutorialID then
            API.Print("Please specify a tutorial ID")
            return
        end
        
        -- Find the tutorial
        local classID = API.GetPlayerClassID()
        local specID = API.GetActiveSpecID()
        
        if not tutorialSteps[classID] or not tutorialSteps[classID][specID] then
            API.Print("No tutorials available for your class/spec")
            return
        end
        
        local foundTutorial = nil
        
        for _, levelTutorials in pairs(tutorialSteps[classID][specID]) do
            for _, tutorial in ipairs(levelTutorials) do
                if tutorial.id == tutorialID then
                    foundTutorial = tutorial
                    break
                end
            end
            
            if foundTutorial then
                break
            end
        end
        
        if foundTutorial then
            self:ShowTutorial(foundTutorial)
        else
            API.Print("Tutorial not found: " .. tutorialID)
        end
    elseif command == "assess" then
        -- Perform a skill assessment
        local assessment = self:AssessPlayerSkill()
        
        if assessment then
            API.Print("Skill Assessment: " .. string.format("%.1f", assessment.overallScore * 100) .. "%")
            API.Print("Skill Level: " .. assessment.skillLevel)
            
            -- Show detailed scores if debug enabled
            local settings = ConfigRegistry:GetSettings("PlayerSkillSystem")
            if settings.debugSettings.showMetricValues then
                API.Print("Detailed Scores:")
                
                for metricName, score in pairs(assessment.scores) do
                    API.Print("  " .. metricName .. ": " .. string.format("%.1f", score * 100) .. "%")
                end
            end
        else
            API.Print("Not enough data for skill assessment")
        end
    elseif command == "adaptations" then
        -- Show active adaptations
        API.Print("Active Skill Adaptations:")
        
        if adaptiveSettings.cooldownUsageLevel then
            API.Print("  Cooldown Usage: " .. string.format("%.1f", adaptiveSettings.cooldownUsageLevel * 100) .. "%")
        end
        
        if adaptiveSettings.resourceManagementLevel then
            API.Print("  Resource Management: " .. string.format("%.1f", adaptiveSettings.resourceManagementLevel * 100) .. "%")
        end
        
        if adaptiveSettings.aoeHandlingLevel then
            API.Print("  AoE Handling: " .. string.format("%.1f", adaptiveSettings.aoeHandlingLevel * 100) .. "%")
        end
        
        if not adaptiveSettings.cooldownUsageLevel and
           not adaptiveSettings.resourceManagementLevel and
           not adaptiveSettings.aoeHandlingLevel then
            API.Print("  No active adaptations")
        end
    else
        API.Print("Unknown command. Type /wrskill for help.")
    end
end

-- Return the module for loading
return PlayerSkillSystem