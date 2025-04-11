------------------------------------------
-- WindrunnerRotations - Rotation Simulator
-- Author: VortexQ8
-- The War Within Season 2
------------------------------------------

local addonName, WR = ...
local RotationSimulator = {}
WR.RotationSimulator = RotationSimulator

-- Dependencies
local API = WR.API
local ConfigRegistry = WR.ConfigRegistry
local ModuleManager = WR.ModuleManager

-- Simulation variables
local simulationActive = false
local simulationTime = 0
local simulationStartTime = 0
local simulationEndTime = 0
local simulationStepSize = 0.1 -- seconds
local simulationDuration = 300 -- 5 minutes default
local simulationTimeline = {}
local simulationResults = {}

-- Simulated state variables
local simulatedPlayer = {}
local simulatedUnits = {}
local simulatedCombatLog = {}
local simulatedResources = {}
local simulatedSpellCasts = {}
local simulatedAuras = {}
local simulatedDamage = {}
local simulatedHealing = {}
local simulatedThreat = {}
local averageDPS = 0
local averageHPS = 0
local totalDamage = 0
local totalHealing = 0
local totalManaUsed = 0
local totalSpellCasts = 0
local timeSpentCasting = 0

-- Class/spec-specific variables for simulation
local simulatedClassId
local simulatedSpecId
local simulatedTalents = {}
local simulatedEquipment = {}
local simulatedStats = {}
local simulatedRotationModule

-- Spell and ability tracking
local reportedAbilities = {}
local abilityDPS = {}
local abilityCastCounts = {}
local abilityTimings = {}
local abilityUptime = {}

-- Initialize the Rotation Simulator
function RotationSimulator:Initialize()
    -- Register settings
    self:RegisterSettings()
    
    -- Set up integration with ModuleManager
    ModuleManager:RegisterCallback("OnModuleLoaded", function(moduleTable)
        -- Auto-setup simulation for the module if enabled
        if moduleTable and ConfigRegistry:GetSettings("RotationSimulator").autoSimulateModules then
            self:SetupSimulationForModule(moduleTable)
        end
    end)
    
    -- Register slash command for rotation simulation
    SLASH_WRSIM1 = "/wrsim"
    SLASH_WRSIM2 = "/wrsimu"
    SLASH_WRSIM3 = "/wrsimulate"
    SlashCmdList["WRSIM"] = function(msg)
        self:HandleSlashCommand(msg)
    end
    
    API.PrintDebug("Rotation Simulator initialized")
    return true
end

-- Register settings for the Rotation Simulator
function RotationSimulator:RegisterSettings()
    ConfigRegistry:RegisterSettings("RotationSimulator", {
        generalSettings = {
            enableSimulation = {
                displayName = "Enable Rotation Simulation",
                description = "Enable or disable rotation simulation functionality",
                type = "toggle",
                default = true
            },
            autoSimulateModules = {
                displayName = "Auto-Simulate New Modules",
                description = "Automatically simulate new modules when they are loaded",
                type = "toggle",
                default = false
            },
            defaultSimulationDuration = {
                displayName = "Default Simulation Duration",
                description = "Default duration for simulations in seconds",
                type = "slider",
                min = 30,
                max = 600,
                default = 300
            },
            simulationStepSize = {
                displayName = "Simulation Step Size",
                description = "Time step size for simulation in seconds",
                type = "slider",
                min = 0.05,
                max = 0.5,
                step = 0.05,
                default = 0.1
            },
            outputToChat = {
                displayName = "Output Results to Chat",
                description = "Output simulation results to chat window",
                type = "toggle",
                default = true
            }
        },
        simulationSettings = {
            targetLevel = {
                displayName = "Target Level",
                description = "Level of the simulated target",
                type = "slider",
                min = 60,
                max = 70,
                default = 70
            },
            targetHealth = {
                displayName = "Target Health",
                description = "Health of the simulated target (in thousands)",
                type = "slider",
                min = 100,
                max = 10000,
                step = 100,
                default = 5000
            },
            enemyCount = {
                displayName = "Enemy Count",
                description = "Number of enemies in the simulation",
                type = "slider",
                min = 1,
                max = 20,
                default = 1
            },
            movementEvents = {
                displayName = "Simulate Movement",
                description = "Simulate player movement during the rotation",
                type = "toggle",
                default = true
            },
            targetMovement = {
                displayName = "Target Movement",
                description = "Simulate target movement",
                type = "toggle",
                default = true
            },
            simulateLatency = {
                displayName = "Simulate Latency",
                description = "Add artificial latency to simulation",
                type = "toggle",
                default = true
            },
            latencyAmount = {
                displayName = "Latency (ms)",
                description = "Amount of latency to simulate in milliseconds",
                type = "slider",
                min = 0,
                max = 300,
                default = 50
            },
            bloodlust = {
                displayName = "Bloodlust/Heroism",
                description = "Simulate with Bloodlust/Heroism",
                type = "toggle",
                default = true
            },
            bloodlustTiming = {
                displayName = "Bloodlust Timing",
                description = "When to apply Bloodlust/Heroism",
                type = "dropdown",
                options = {"Start", "30 seconds", "1 minute", "2 minutes", "3 minutes", "4 minutes"},
                default = "30 seconds"
            },
            combatConsumables = {
                displayName = "Combat Consumables",
                description = "Simulate with combat consumables (potions, etc.)",
                type = "toggle",
                default = true
            },
            externalBuffs = {
                displayName = "External Buffs",
                description = "Simulate with external buffs (Power Infusion, etc.)",
                type = "toggle",
                default = true
            }
        },
        playerSettings = {
            playerLevel = {
                displayName = "Player Level",
                description = "Level of the simulated player",
                type = "slider",
                min = 60,
                max = 70,
                default = 70
            },
            primaryStat = {
                displayName = "Primary Stat Value",
                description = "Value of primary stat (Int, Str, Agi) for simulation",
                type = "slider",
                min = 100,
                max = 5000,
                step = 50,
                default = 1500
            },
            critRating = {
                displayName = "Critical Strike Rating",
                description = "Critical Strike rating for simulation",
                type = "slider",
                min = 0,
                max = 2000,
                step = 10,
                default = 500
            },
            hasteRating = {
                displayName = "Haste Rating",
                description = "Haste rating for simulation",
                type = "slider",
                min = 0,
                max = 2000,
                step = 10,
                default = 500
            },
            masteryRating = {
                displayName = "Mastery Rating",
                description = "Mastery rating for simulation",
                type = "slider",
                min = 0,
                max = 2000,
                step = 10,
                default = 500
            },
            versatilityRating = {
                displayName = "Versatility Rating",
                description = "Versatility rating for simulation",
                type = "slider",
                min = 0,
                max = 2000,
                step = 10,
                default = 500
            },
            weaponDPS = {
                displayName = "Weapon DPS",
                description = "DPS of the player's weapon(s) for simulation",
                type = "slider",
                min = 10,
                max = 1000,
                step = 10,
                default = 300
            }
        },
        outputSettings = {
            showAbilitySummary = {
                displayName = "Show Ability Summary",
                description = "Show summary of abilities used in simulation",
                type = "toggle",
                default = true
            },
            showResourceUsage = {
                displayName = "Show Resource Usage",
                description = "Show resource usage in simulation",
                type = "toggle",
                default = true
            },
            showTimeline = {
                displayName = "Show Timeline",
                description = "Show timeline of simulation events",
                type = "toggle",
                default = false
            },
            showOptimalRotation = {
                displayName = "Show Optimal Rotation",
                description = "Show recommended optimal rotation based on simulation",
                type = "toggle",
                default = true
            }
        }
    })
end

-- Setup simulation for a specific module
function RotationSimulator:SetupSimulationForModule(moduleTable)
    if not moduleTable or not moduleTable.specID then
        API.PrintDebug("Cannot setup simulation for invalid module")
        return false
    end
    
    simulatedClassId = moduleTable.classID
    simulatedSpecId = moduleTable.specID
    simulatedRotationModule = moduleTable
    
    -- Get default settings for the simulation
    self:ResetSimulationState()
    
    -- Set up simulated player stats based on class/spec
    self:SetupSimulatedStats(simulatedClassId, simulatedSpecId)
    
    -- Initialize simulation hooks into the module
    moduleTable.SimulateRotation = function(time, state)
        return self:MockRotation(moduleTable, time, state)
    end
    
    API.PrintDebug("Simulation setup complete for " .. (moduleTable.name or "Unknown Module"))
    return true
end

-- Reset simulation state
function RotationSimulator:ResetSimulationState()
    simulationActive = false
    simulationTime = 0
    simulationStartTime = 0
    simulationEndTime = 0
    simulationTimeline = {}
    simulationResults = {}
    
    simulatedPlayer = {
        health = 100,
        maxHealth = 100,
        position = { x = 0, y = 0, z = 0 },
        isCasting = false,
        currentCast = nil,
        castStartTime = 0,
        castEndTime = 0,
        isChanneling = false,
        currentChannel = nil,
        channelStartTime = 0,
        channelEndTime = 0,
        targetGUID = "target",
        movementSpeed = 7, -- yards per second
        isMoving = false,
        gcd = 0,
        gcdEnd = 0,
        hasteMultiplier = 1.0,
        critChance = 0.2,
        critMultiplier = 2.0,
        versatility = 0.1,
        mastery = 0.2,
        cooldowns = {},
        resources = {},
        auras = {}
    }
    
    simulatedUnits = {
        target = {
            guid = "target",
            health = 100,
            maxHealth = 100,
            position = { x = 0, y = 0, z = 30 },
            isCasting = false,
            currentCast = nil,
            castStartTime = 0,
            castEndTime = 0,
            isChanneling = false,
            currentChannel = nil,
            channelStartTime = 0,
            channelEndTime = 0,
            distance = 30,
            auras = {}
        }
    }
    
    simulatedCombatLog = {}
    simulatedResources = {}
    simulatedSpellCasts = {}
    simulatedAuras = {}
    simulatedDamage = {}
    simulatedHealing = {}
    simulatedThreat = {}
    
    averageDPS = 0
    averageHPS = 0
    totalDamage = 0
    totalHealing = 0
    totalManaUsed = 0
    totalSpellCasts = 0
    timeSpentCasting = 0
    
    reportedAbilities = {}
    abilityDPS = {}
    abilityCastCounts = {}
    abilityTimings = {}
    abilityUptime = {}
    
    -- Get values from settings
    local settings = ConfigRegistry:GetSettings("RotationSimulator")
    simulationDuration = settings.generalSettings.defaultSimulationDuration
    simulationStepSize = settings.generalSettings.simulationStepSize
    
    -- Set up simulated player resources based on class
    self:InitializeResources(simulatedClassId)
    
    return true
end

-- Initialize resources based on class
function RotationSimulator:InitializeResources(classId)
    simulatedResources = {}
    
    if not classId then
        -- Default resources
        simulatedResources.mana = {
            current = 100,
            max = 100,
            regenRate = 0.1 -- % per second
        }
        return
    end
    
    -- Class-specific resource initialization
    if classId == 1 then -- Warrior
        simulatedResources.rage = {
            current = 0,
            max = 100,
            regenRate = 0 -- Generated from combat
        }
    elseif classId == 2 then -- Paladin
        simulatedResources.mana = {
            current = 100,
            max = 100,
            regenRate = 0.1
        }
        simulatedResources.holyPower = {
            current = 0,
            max = 5,
            regenRate = 0
        }
    elseif classId == 3 then -- Hunter
        simulatedResources.focus = {
            current = 100,
            max = 100,
            regenRate = 1 -- Focus per second
        }
    elseif classId == 4 then -- Rogue
        simulatedResources.energy = {
            current = 100,
            max = 100,
            regenRate = 1
        }
        simulatedResources.comboPoints = {
            current = 0,
            max = 5,
            regenRate = 0
        }
    elseif classId == 5 then -- Priest
        simulatedResources.mana = {
            current = 100,
            max = 100,
            regenRate = 0.1
        }
        -- Shadow Priests
        if simulatedSpecId == 258 then
            simulatedResources.insanity = {
                current = 0,
                max = 100,
                regenRate = 0
            }
        end
    elseif classId == 6 then -- Death Knight
        simulatedResources.runicPower = {
            current = 0,
            max = 100,
            regenRate = 0
        }
        simulatedResources.runes = {
            current = 6,
            max = 6,
            regenRate = 0.1 -- Runes per second
        }
    elseif classId == 7 then -- Shaman
        simulatedResources.mana = {
            current = 100,
            max = 100,
            regenRate = 0.1
        }
        simulatedResources.maelstrom = {
            current = 0,
            max = 100,
            regenRate = 0
        }
    elseif classId == 8 then -- Mage
        simulatedResources.mana = {
            current = 100,
            max = 100,
            regenRate = 0.1
        }
        if simulatedSpecId == 62 then -- Arcane
            simulatedResources.arcaneCharges = {
                current = 0,
                max = 4,
                regenRate = 0
            }
        end
    elseif classId == 9 then -- Warlock
        simulatedResources.mana = {
            current = 100,
            max = 100,
            regenRate = 0.1
        }
        simulatedResources.soulShards = {
            current = 3,
            max = 5,
            regenRate = 0
        }
    elseif classId == 10 then -- Monk
        simulatedResources.energy = {
            current = 100,
            max = 100,
            regenRate = 1
        }
        simulatedResources.chi = {
            current = 0,
            max = 5,
            regenRate = 0
        }
    elseif classId == 11 then -- Druid
        simulatedResources.mana = {
            current = 100,
            max = 100,
            regenRate = 0.1
        }
        if simulatedSpecId == 103 then -- Feral
            simulatedResources.energy = {
                current = 100,
                max = 100,
                regenRate = 1
            }
            simulatedResources.comboPoints = {
                current = 0,
                max = 5,
                regenRate = 0
            }
        elseif simulatedSpecId == 104 then -- Guardian
            simulatedResources.rage = {
                current = 0,
                max = 100,
                regenRate = 0
            }
        elseif simulatedSpecId == 102 then -- Balance
            simulatedResources.astralPower = {
                current = 0,
                max = 100,
                regenRate = 0
            }
        end
    elseif classId == 12 then -- Demon Hunter
        simulatedResources.fury = {
            current = 0,
            max = 100,
            regenRate = 0.1
        }
    elseif classId == 13 then -- Evoker
        simulatedResources.mana = {
            current = 100,
            max = 100,
            regenRate = 0.1
        }
        simulatedResources.essence = {
            current = 0,
            max = 6,
            regenRate = 0.2
        }
    end
end

-- Set up simulated stats based on class and spec
function RotationSimulator:SetupSimulatedStats(classId, specId)
    -- Default stats
    simulatedStats = {
        intellect = 1500,
        agility = 1500,
        strength = 1500,
        stamina = 2000,
        critRating = 500,
        hasteRating = 500,
        masteryRating = 500,
        versatilityRating = 500,
        weaponDPS = 300
    }
    
    -- Get player settings
    local settings = ConfigRegistry:GetSettings("RotationSimulator").playerSettings
    
    -- Apply settings to stats
    simulatedStats.critRating = settings.critRating
    simulatedStats.hasteRating = settings.hasteRating
    simulatedStats.masteryRating = settings.masteryRating
    simulatedStats.versatilityRating = settings.versatilityRating
    simulatedStats.weaponDPS = settings.weaponDPS
    
    -- Calculate stat percentages
    local critPct = self:RatingToPercent(simulatedStats.critRating, "crit")
    local hastePct = self:RatingToPercent(simulatedStats.hasteRating, "haste")
    local masteryPct = self:RatingToPercent(simulatedStats.masteryRating, "mastery")
    local versatilityPct = self:RatingToPercent(simulatedStats.versatilityRating, "versatility")
    
    -- Apply percentages to player
    simulatedPlayer.critChance = critPct
    simulatedPlayer.hasteMultiplier = 1 + hastePct
    simulatedPlayer.mastery = masteryPct
    simulatedPlayer.versatility = versatilityPct
    
    -- Class and spec-specific stat setup
    if classId == 1 or classId == 2 or classId == 6 then -- Str users (Warrior, Paladin, DK)
        simulatedPlayer.primaryStat = simulatedStats.strength = settings.primaryStat
    elseif classId == 3 or classId == 4 or classId == 10 or classId == 11 or classId == 12 then -- Agi users (Hunter, Rogue, Monk, Druid, DH)
        simulatedPlayer.primaryStat = simulatedStats.agility = settings.primaryStat
        -- Specific specs that use different primary stats
        if classId == 11 and (specId == 102 or specId == 105) then -- Balance and Resto Druid
            simulatedPlayer.primaryStat = simulatedStats.intellect = settings.primaryStat
        end
    else -- Int users (Priest, Shaman, Mage, Warlock, Evoker)
        simulatedPlayer.primaryStat = simulatedStats.intellect = settings.primaryStat
    end
    
    -- Spec-specific mastery effects
    if classId == 8 and specId == 62 then -- Arcane Mage
        simulatedPlayer.masteryEffect = 1 + (masteryPct * 2.25) -- Mastery: Savant increases arcane damage
    elseif classId == 9 and specId == 265 then -- Affliction Warlock
        simulatedPlayer.masteryEffect = 1 + (masteryPct * 2.5) -- Mastery: Potent Afflictions
    elseif classId == 13 and specId == 1467 then -- Devastation Evoker
        simulatedPlayer.masteryEffect = 1 + (masteryPct * 2.0) -- Mastery: Giantkiller
    end
    
    return true
end

-- Convert rating to percentage based on type
function RotationSimulator:RatingToPercent(rating, type)
    -- Simplified conversion - would need actual formulas for specific gear levels
    if type == "crit" then
        return rating / 35 * 0.01 -- ~35 rating = 1%
    elseif type == "haste" then
        return rating / 33 * 0.01 -- ~33 rating = 1%
    elseif type == "mastery" then
        return rating / 35 * 0.01 -- ~35 rating = 1%
    elseif type == "versatility" then
        return rating / 40 * 0.01 -- ~40 rating = 1%
    else
        return 0
    end
end

-- Start a new simulation
function RotationSimulator:StartSimulation(duration, stepSize)
    if simulationActive then
        API.Print("Simulation already in progress. Please wait or stop the current simulation.")
        return false
    end
    
    if not simulatedRotationModule then
        API.Print("No rotation module to simulate. Please load a class module first.")
        return false
    end
    
    -- Use provided parameters or defaults
    simulationDuration = duration or ConfigRegistry:GetSettings("RotationSimulator").generalSettings.defaultSimulationDuration
    simulationStepSize = stepSize or ConfigRegistry:GetSettings("RotationSimulator").generalSettings.simulationStepSize
    
    -- Reset simulation state
    self:ResetSimulationState()
    
    -- Setup simulation environment
    self:SetupSimulationEnvironment()
    
    -- Initialize simulation time
    simulationStartTime = GetTime()
    simulationEndTime = simulationStartTime + simulationDuration
    simulationTime = 0
    simulationActive = true
    
    API.Print("Starting rotation simulation for " .. (simulatedRotationModule.name or "Unknown Module") .. " for " .. simulationDuration .. " seconds.")
    
    -- Start the simulation
    self:RunSimulation()
    
    return true
end

-- Setup the simulation environment with initial buffs, etc.
function RotationSimulator:SetupSimulationEnvironment()
    local settings = ConfigRegistry:GetSettings("RotationSimulator")
    
    -- Target setup
    simulatedUnits.target.health = settings.simulationSettings.targetHealth * 1000
    simulatedUnits.target.maxHealth = settings.simulationSettings.targetHealth * 1000
    
    -- Player setup
    simulatedPlayer.cooldowns = {}
    simulatedPlayer.auras = {}
    
    -- Setup initial buffs
    if settings.simulationSettings.bloodlust and settings.simulationSettings.bloodlustTiming == "Start" then
        self:ApplyAura("player", "BLOODLUST", 40, true)
    end
    
    -- Apply class buffs
    self:ApplyClassBuffs()
    
    -- Setup enemy count
    for i = 2, settings.simulationSettings.enemyCount do
        local enemyGuid = "target" .. i
        simulatedUnits[enemyGuid] = {
            guid = enemyGuid,
            health = settings.simulationSettings.targetHealth * 1000,
            maxHealth = settings.simulationSettings.targetHealth * 1000,
            position = { 
                x = math.random(-10, 10), 
                y = math.random(-10, 10), 
                z = math.random(25, 35) 
            },
            isCasting = false,
            currentCast = nil,
            castStartTime = 0,
            castEndTime = 0,
            isChanneling = false,
            currentChannel = nil,
            channelStartTime = 0,
            channelEndTime = 0,
            distance = math.random(25, 35),
            auras = {}
        }
    end
    
    return true
end

-- Apply class-specific buffs
function RotationSimulator:ApplyClassBuffs()
    if not simulatedClassId then return end
    
    -- Add class buffs
    if simulatedClassId == 8 then -- Mage
        self:ApplyAura("player", "ARCANE_INTELLECT", 3600, true)
    elseif simulatedClassId == 5 then -- Priest
        self:ApplyAura("player", "POWER_WORD_FORTITUDE", 3600, true)
    elseif simulatedClassId == 9 then -- Warlock
        self:ApplyAura("player", "DEMON_ARMOR", 3600, true)
    end
    
    -- Add consumables if enabled
    if ConfigRegistry:GetSettings("RotationSimulator").simulationSettings.combatConsumables then
        -- Flask
        self:ApplyAura("player", "FLASK", 3600, true)
        -- Food buff
        self:ApplyAura("player", "WELL_FED", 3600, true)
    end
end

-- Apply an aura to a unit
function RotationSimulator:ApplyAura(unit, auraName, duration, isBuff)
    if not simulatedUnits[unit] then
        if unit == "player" then
            simulatedPlayer.auras[auraName] = {
                name = auraName,
                duration = duration,
                expirationTime = simulationTime + duration,
                stacks = 1,
                isBuff = isBuff or false
            }
            
            -- Add to timeline
            table.insert(simulationTimeline, {
                time = simulationTime,
                event = "APPLY_AURA",
                unit = "player",
                aura = auraName,
                duration = duration
            })
            
            -- Track uptime
            if not abilityUptime[auraName] then
                abilityUptime[auraName] = {
                    totalUptime = 0,
                    lastApplied = simulationTime
                }
            else
                abilityUptime[auraName].lastApplied = simulationTime
            end
        end
    else
        simulatedUnits[unit].auras[auraName] = {
            name = auraName,
            duration = duration,
            expirationTime = simulationTime + duration,
            stacks = 1,
            isBuff = isBuff or false
        }
        
        -- Add to timeline
        table.insert(simulationTimeline, {
            time = simulationTime,
            event = "APPLY_AURA",
            unit = unit,
            aura = auraName,
            duration = duration
        })
    end
end

-- Remove an aura from a unit
function RotationSimulator:RemoveAura(unit, auraName)
    if not simulatedUnits[unit] then
        if unit == "player" and simulatedPlayer.auras[auraName] then
            -- Track uptime
            if abilityUptime[auraName] then
                abilityUptime[auraName].totalUptime = abilityUptime[auraName].totalUptime + 
                    (simulationTime - abilityUptime[auraName].lastApplied)
            end
            
            simulatedPlayer.auras[auraName] = nil
            
            -- Add to timeline
            table.insert(simulationTimeline, {
                time = simulationTime,
                event = "REMOVE_AURA",
                unit = "player",
                aura = auraName
            })
        end
    elseif simulatedUnits[unit].auras[auraName] then
        simulatedUnits[unit].auras[auraName] = nil
        
        -- Add to timeline
        table.insert(simulationTimeline, {
            time = simulationTime,
            event = "REMOVE_AURA",
            unit = unit,
            aura = auraName
        })
    end
end

-- Run the core simulation
function RotationSimulator:RunSimulation()
    if not simulationActive then
        return false
    end
    
    -- Get settings
    local settings = ConfigRegistry:GetSettings("RotationSimulator")
    
    -- Run simulation steps until duration is reached
    local simulationProgress = 0
    local nextProgressReport = 10
    local simulationIterations = math.floor(simulationDuration / simulationStepSize)
    
    for i = 1, simulationIterations do
        -- Update time
        simulationTime = i * simulationStepSize
        
        -- Calculate progress percentage
        simulationProgress = math.floor((simulationTime / simulationDuration) * 100)
        
        -- Report progress at intervals
        if simulationProgress >= nextProgressReport then
            API.PrintDebug("Simulation progress: " .. simulationProgress .. "%")
            nextProgressReport = nextProgressReport + 10
        end
        
        -- Apply Bloodlust at specified time if configured
        if settings.simulationSettings.bloodlust and not self:HasAura("player", "BLOODLUST") then
            local bloodlustTime = 0
            if settings.simulationSettings.bloodlustTiming == "30 seconds" then
                bloodlustTime = 30
            elseif settings.simulationSettings.bloodlustTiming == "1 minute" then
                bloodlustTime = 60
            elseif settings.simulationSettings.bloodlustTiming == "2 minutes" then
                bloodlustTime = 120
            elseif settings.simulationSettings.bloodlustTiming == "3 minutes" then
                bloodlustTime = 180
            elseif settings.simulationSettings.bloodlustTiming == "4 minutes" then
                bloodlustTime = 240
            end
            
            if simulationTime >= bloodlustTime and simulationTime <= bloodlustTime + 0.1 then
                self:ApplyAura("player", "BLOODLUST", 40, true)
            end
        end
        
        -- Check for movement events
        if settings.simulationSettings.movementEvents then
            self:HandleMovementEvents(simulationTime)
        end
        
        -- Update auras
        self:UpdateAuras(simulationTime)
        
        -- Update resources
        self:UpdateResources(simulationTime)
        
        -- Update cooldowns
        self:UpdateCooldowns(simulationTime)
        
        -- Update player cast/channel state
        self:UpdateCastingState(simulationTime)
        
        -- Run rotation if player is not currently casting/channeling
        if not simulatedPlayer.isCasting and not simulatedPlayer.isChanneling and
           simulationTime > (simulatedPlayer.gcdEnd or 0) then
            -- Create simulation state
            local simState = self:CreateSimulationState(simulationTime)
            
            -- Run the rotation for current time
            local success, spellId, target = pcall(function()
                return simulatedRotationModule:SimulateRotation(simulationTime, simState)
            end)
            
            if success and spellId then
                -- Cast the spell
                self:SimulateCast(spellId, target or "target", simulationTime)
            end
        end
    end
    
    -- Finalize simulation
    self:FinalizeSimulation()
    
    return true
end

-- Handle movement events during simulation
function RotationSimulator:HandleMovementEvents(currentTime)
    local settings = ConfigRegistry:GetSettings("RotationSimulator")
    
    -- Every ~20 seconds, create a movement event that lasts ~3 seconds
    if math.random(1, math.floor(20 / simulationStepSize)) == 1 and not simulatedPlayer.isMoving then
        simulatedPlayer.isMoving = true
        simulatedPlayer.movementEndTime = currentTime + 3
        
        -- Add to timeline
        table.insert(simulationTimeline, {
            time = currentTime,
            event = "MOVEMENT_START",
            unit = "player"
        })
    end
    
    -- Check if movement should end
    if simulatedPlayer.isMoving and currentTime >= simulatedPlayer.movementEndTime then
        simulatedPlayer.isMoving = false
        
        -- Add to timeline
        table.insert(simulationTimeline, {
            time = currentTime,
            event = "MOVEMENT_END",
            unit = "player"
        })
    end
    
    -- Handle target movement if enabled
    if settings.simulationSettings.targetMovement then
        for unitId, unit in pairs(simulatedUnits) do
            -- Every ~30 seconds, move the target by ~5 yards
            if math.random(1, math.floor(30 / simulationStepSize)) == 1 then
                -- Randomly move target
                local movement = math.random(-5, 5)
                unit.distance = math.max(5, math.min(40, unit.distance + movement))
                
                -- Add to timeline
                table.insert(simulationTimeline, {
                    time = currentTime,
                    event = "TARGET_MOVED",
                    unit = unitId,
                    distance = unit.distance
                })
            end
        end
    end
end

-- Update all auras
function RotationSimulator:UpdateAuras(currentTime)
    -- Update player auras
    for auraName, aura in pairs(simulatedPlayer.auras) do
        if currentTime >= aura.expirationTime then
            self:RemoveAura("player", auraName)
        end
    end
    
    -- Update target auras
    for unitId, unit in pairs(simulatedUnits) do
        for auraName, aura in pairs(unit.auras) do
            if currentTime >= aura.expirationTime then
                self:RemoveAura(unitId, auraName)
            end
        end
    end
end

-- Update resources
function RotationSimulator:UpdateResources(currentTime)
    -- Update resources based on regen rates
    for resourceName, resource in pairs(simulatedResources) do
        if resource.regenRate > 0 then
            resource.current = math.min(resource.max, resource.current + resource.regenRate * simulationStepSize)
        end
    end
    
    -- Special handling for specific resources
    -- For example, rune regeneration for Death Knights
    if simulatedClassId == 6 and simulatedResources.runes then
        -- Regenerate runes
        local runeRegen = simulatedResources.runes.regenRate * simulatedPlayer.hasteMultiplier * simulationStepSize
        simulatedResources.runes.current = math.min(simulatedResources.runes.max, simulatedResources.runes.current + runeRegen)
    end
end

-- Update cooldowns
function RotationSimulator:UpdateCooldowns(currentTime)
    for spellId, cooldownInfo in pairs(simulatedPlayer.cooldowns) do
        if currentTime >= cooldownInfo.endTime then
            simulatedPlayer.cooldowns[spellId] = nil
            
            -- Add to timeline
            table.insert(simulationTimeline, {
                time = currentTime,
                event = "COOLDOWN_END",
                spell = spellId
            })
        end
    end
end

-- Update casting state
function RotationSimulator:UpdateCastingState(currentTime)
    -- Check if player is casting
    if simulatedPlayer.isCasting and currentTime >= simulatedPlayer.castEndTime then
        simulatedPlayer.isCasting = false
        
        -- Add to timeline
        table.insert(simulationTimeline, {
            time = currentTime,
            event = "CAST_END",
            spell = simulatedPlayer.currentCast,
            target = simulatedPlayer.castTarget
        })
        
        -- Apply cast effects
        self:ApplyCastEffects(simulatedPlayer.currentCast, simulatedPlayer.castTarget, currentTime)
        
        -- Update time spent casting
        timeSpentCasting = timeSpentCasting + (simulatedPlayer.castEndTime - simulatedPlayer.castStartTime)
        
        simulatedPlayer.currentCast = nil
        simulatedPlayer.castTarget = nil
    end
    
    -- Check if player is channeling
    if simulatedPlayer.isChanneling and currentTime >= simulatedPlayer.channelEndTime then
        simulatedPlayer.isChanneling = false
        
        -- Add to timeline
        table.insert(simulationTimeline, {
            time = currentTime,
            event = "CHANNEL_END",
            spell = simulatedPlayer.currentChannel,
            target = simulatedPlayer.channelTarget
        })
        
        -- Update time spent casting
        timeSpentCasting = timeSpentCasting + (simulatedPlayer.channelEndTime - simulatedPlayer.channelStartTime)
        
        simulatedPlayer.currentChannel = nil
        simulatedPlayer.channelTarget = nil
    end
end

-- Apply effects of a successful cast
function RotationSimulator:ApplyCastEffects(spellId, targetId, currentTime)
    if not spellId or not targetId then
        return
    end
    
    -- Get spell data from our spell database
    local spellData = API.GetSpellInfo(spellId)
    if not spellData then
        return
    end
    
    -- Deal damage for damaging spells
    if spellData.damage and spellData.damage > 0 then
        local damage = self:CalculateSpellDamage(spellId, targetId)
        self:DealDamage(targetId, damage, spellId, currentTime)
    end
    
    -- Apply healing for healing spells
    if spellData.healing and spellData.healing > 0 then
        local healing = self:CalculateSpellHealing(spellId, targetId)
        self:ApplyHealing(targetId, healing, spellId, currentTime)
    end
    
    -- Apply auras for spells that apply buffs/debuffs
    if spellData.appliesAura then
        local duration = spellData.auraDuration or 15
        local isBuff = spellData.auraType == "BUFF"
        
        -- Apply to target for debuffs or player for buffs
        local auraTarget = isBuff and "player" or targetId
        self:ApplyAura(auraTarget, spellData.auraName or spellId, duration, isBuff)
    end
    
    -- Handle resource generation or consumption
    if spellData.resourceChange then
        for resourceName, amount in pairs(spellData.resourceChange) do
            if simulatedResources[resourceName] then
                simulatedResources[resourceName].current = math.max(0, 
                    math.min(simulatedResources[resourceName].max, 
                        simulatedResources[resourceName].current + amount))
                
                -- Track resource usage
                if resourceName == "mana" and amount < 0 then
                    totalManaUsed = totalManaUsed + math.abs(amount)
                end
            end
        end
    end
    
    -- Start cooldown
    if spellData.cooldown and spellData.cooldown > 0 then
        local cooldownDuration = spellData.cooldown / simulatedPlayer.hasteMultiplier
        simulatedPlayer.cooldowns[spellId] = {
            endTime = currentTime + cooldownDuration
        }
        
        -- Add to timeline
        table.insert(simulationTimeline, {
            time = currentTime,
            event = "COOLDOWN_START",
            spell = spellId,
            duration = cooldownDuration
        })
    end
    
    -- Update GCD
    local gcdBase = 1.5
    if spellData.triggersGCD ~= false then
        -- Some abilities don't trigger GCD
        local gcd = math.max(0.75, gcdBase / simulatedPlayer.hasteMultiplier)
        simulatedPlayer.gcd = gcd
        simulatedPlayer.gcdEnd = currentTime + gcd
    end
end

-- Calculate spell damage
function RotationSimulator:CalculateSpellDamage(spellId, targetId)
    local spellData = API.GetSpellInfo(spellId)
    if not spellData or not spellData.damage then
        return 0
    end
    
    -- Base damage calculation
    local baseDamage = spellData.damage
    
    -- Apply spell power scaling if it exists
    if spellData.spellPowerCoefficient then
        baseDamage = baseDamage + (simulatedPlayer.primaryStat * spellData.spellPowerCoefficient)
    end
    
    -- Apply attack power scaling if it exists
    if spellData.attackPowerCoefficient then
        baseDamage = baseDamage + (simulatedPlayer.primaryStat * spellData.attackPowerCoefficient)
    end
    
    -- Apply weapon damage scaling if it exists
    if spellData.weaponDamageCoefficient then
        baseDamage = baseDamage + (simulatedStats.weaponDPS * spellData.weaponDamageCoefficient)
    end
    
    -- Apply mastery effect if it exists
    if simulatedPlayer.masteryEffect and spellData.affected_by_mastery then
        baseDamage = baseDamage * simulatedPlayer.masteryEffect
    end
    
    -- Apply versatility
    baseDamage = baseDamage * (1 + simulatedPlayer.versatility)
    
    -- Apply specific buffs
    if self:HasAura("player", "BLOODLUST") then
        baseDamage = baseDamage * 1.3
    end
    
    -- Apply class/spec specific buffs
    if simulatedClassId == 8 and simulatedSpecId == 62 then -- Arcane Mage
        if self:HasAura("player", "ARCANE_POWER") then
            baseDamage = baseDamage * 1.30 -- Arcane Power increases damage by 30%
        end
    elseif simulatedClassId == 9 and simulatedSpecId == 265 then -- Affliction Warlock
        if self:HasAura("player", "DARK_SOUL") then
            baseDamage = baseDamage * 1.30 -- Dark Soul increases damage
        end
    end
    
    -- Critical strike
    local isCrit = math.random() < simulatedPlayer.critChance
    if isCrit then
        baseDamage = baseDamage * simulatedPlayer.critMultiplier
    end
    
    return baseDamage
end

-- Calculate spell healing
function RotationSimulator:CalculateSpellHealing(spellId, targetId)
    local spellData = API.GetSpellInfo(spellId)
    if not spellData or not spellData.healing then
        return 0
    end
    
    -- Base healing calculation
    local baseHealing = spellData.healing
    
    -- Apply spell power scaling if it exists
    if spellData.healingCoefficient then
        baseHealing = baseHealing + (simulatedPlayer.primaryStat * spellData.healingCoefficient)
    end
    
    -- Apply versatility
    baseHealing = baseHealing * (1 + simulatedPlayer.versatility)
    
    -- Apply specific buffs
    if self:HasAura("player", "BLOODLUST") then
        baseHealing = baseHealing * 1.3
    end
    
    -- Critical strike
    local isCrit = math.random() < simulatedPlayer.critChance
    if isCrit then
        baseHealing = baseHealing * simulatedPlayer.critMultiplier
    end
    
    return baseHealing
end

-- Deal damage to a target
function RotationSimulator:DealDamage(targetId, amount, spellId, currentTime)
    if not simulatedUnits[targetId] then
        return
    end
    
    -- Apply damage
    simulatedUnits[targetId].health = math.max(0, simulatedUnits[targetId].health - amount)
    
    -- Track damage
    totalDamage = totalDamage + amount
    
    -- Track ability damage
    local spellName = API.GetSpellInfo(spellId).name or spellId
    if not simulatedDamage[spellName] then
        simulatedDamage[spellName] = {
            totalDamage = amount,
            hits = 1,
            crits = 0,
            lastHit = currentTime
        }
    else
        simulatedDamage[spellName].totalDamage = simulatedDamage[spellName].totalDamage + amount
        simulatedDamage[spellName].hits = simulatedDamage[spellName].hits + 1
        simulatedDamage[spellName].lastHit = currentTime
    end
    
    -- Add to timeline
    table.insert(simulationTimeline, {
        time = currentTime,
        event = "DAMAGE",
        source = "player",
        target = targetId,
        spell = spellId,
        amount = amount
    })
    
    -- Check if target died
    if simulatedUnits[targetId].health <= 0 then
        -- Add to timeline
        table.insert(simulationTimeline, {
            time = currentTime,
            event = "UNIT_DIED",
            unit = targetId
        })
        
        -- Respawn target for continuing simulation
        simulatedUnits[targetId].health = simulatedUnits[targetId].maxHealth
    end
end

-- Apply healing to a target
function RotationSimulator:ApplyHealing(targetId, amount, spellId, currentTime)
    local targetUnit = targetId == "player" and simulatedPlayer or simulatedUnits[targetId]
    if not targetUnit then
        return
    end
    
    -- Apply healing
    if targetId == "player" then
        simulatedPlayer.health = math.min(simulatedPlayer.maxHealth, simulatedPlayer.health + amount)
    else
        targetUnit.health = math.min(targetUnit.maxHealth, targetUnit.health + amount)
    end
    
    -- Track healing
    totalHealing = totalHealing + amount
    
    -- Track ability healing
    local spellName = API.GetSpellInfo(spellId).name or spellId
    if not simulatedHealing[spellName] then
        simulatedHealing[spellName] = {
            totalHealing = amount,
            casts = 1,
            lastCast = currentTime
        }
    else
        simulatedHealing[spellName].totalHealing = simulatedHealing[spellName].totalHealing + amount
        simulatedHealing[spellName].casts = simulatedHealing[spellName].casts + 1
        simulatedHealing[spellName].lastCast = currentTime
    end
    
    -- Add to timeline
    table.insert(simulationTimeline, {
        time = currentTime,
        event = "HEALING",
        source = "player",
        target = targetId,
        spell = spellId,
        amount = amount
    })
end

-- Simulate casting a spell
function RotationSimulator:SimulateCast(spellId, targetId, currentTime)
    -- Get spell data from our spell database
    local spellData = API.GetSpellInfo(spellId)
    if not spellData then
        return false
    end
    
    -- Verify resources
    if spellData.resourceCost then
        for resourceName, amount in pairs(spellData.resourceCost) do
            if simulatedResources[resourceName] and simulatedResources[resourceName].current < amount then
                return false -- Not enough resources
            end
        end
    end
    
    -- Check if spell is on cooldown
    if simulatedPlayer.cooldowns[spellId] then
        return false
    end
    
    -- Verify target exists and is in range
    if targetId ~= "player" and not simulatedUnits[targetId] then
        return false
    end
    
    -- Check range
    local range = spellData.range or 40
    if targetId ~= "player" and simulatedUnits[targetId].distance > range then
        return false -- Target out of range
    end
    
    -- Consume resources
    if spellData.resourceCost then
        for resourceName, amount in pairs(spellData.resourceCost) do
            if simulatedResources[resourceName] then
                simulatedResources[resourceName].current = simulatedResources[resourceName].current - amount
                
                -- Track mana usage
                if resourceName == "mana" then
                    totalManaUsed = totalManaUsed + amount
                end
            end
        end
    end
    
    -- Track ability usage
    local spellName = spellData.name or spellId
    if not abilityCastCounts[spellName] then
        abilityCastCounts[spellName] = 1
        abilityTimings[spellName] = { firstCast = currentTime, lastCast = currentTime }
    else
        abilityCastCounts[spellName] = abilityCastCounts[spellName] + 1
        abilityTimings[spellName].lastCast = currentTime
    end
    
    -- Increment total spell casts
    totalSpellCasts = totalSpellCasts + 1
    
    -- Check if it's an instant cast
    local castTime = spellData.castTime or 0
    if castTime > 0 then
        -- Apply haste
        castTime = castTime / simulatedPlayer.hasteMultiplier
        
        -- Check if Presence of Mind is active (for Mages)
        if simulatedClassId == 8 and self:HasAura("player", "PRESENCE_OF_MIND") then
            castTime = 0
        end
        
        -- Start casting
        simulatedPlayer.isCasting = true
        simulatedPlayer.currentCast = spellId
        simulatedPlayer.castTarget = targetId
        simulatedPlayer.castStartTime = currentTime
        simulatedPlayer.castEndTime = currentTime + castTime
        
        -- Add to timeline
        table.insert(simulationTimeline, {
            time = currentTime,
            event = "CAST_START",
            spell = spellId,
            target = targetId,
            castTime = castTime
        })
    elseif spellData.channelTime and spellData.channelTime > 0 then
        -- Handle channeled spells
        local channelTime = spellData.channelTime / simulatedPlayer.hasteMultiplier
        
        -- Start channeling
        simulatedPlayer.isChanneling = true
        simulatedPlayer.currentChannel = spellId
        simulatedPlayer.channelTarget = targetId
        simulatedPlayer.channelStartTime = currentTime
        simulatedPlayer.channelEndTime = currentTime + channelTime
        
        -- Add to timeline
        table.insert(simulationTimeline, {
            time = currentTime,
            event = "CHANNEL_START",
            spell = spellId,
            target = targetId,
            channelTime = channelTime
        })
        
        -- Apply initial channel effects if specified
        if spellData.initialEffect then
            self:ApplyCastEffects(spellId, targetId, currentTime)
        end
    else
        -- Instant cast
        simulatedPlayer.isCasting = false
        
        -- Add to timeline
        table.insert(simulationTimeline, {
            time = currentTime,
            event = "CAST_SUCCESS",
            spell = spellId,
            target = targetId
        })
        
        -- Apply cast effects for instant casts
        self:ApplyCastEffects(spellId, targetId, currentTime)
    end
    
    return true
end

-- Create simulation state for the rotation module
function RotationSimulator:CreateSimulationState(currentTime)
    local state = {
        time = currentTime,
        player = {
            health = simulatedPlayer.health,
            maxHealth = simulatedPlayer.maxHealth,
            position = simulatedPlayer.position,
            isMoving = simulatedPlayer.isMoving,
            isCasting = simulatedPlayer.isCasting,
            isChanneling = simulatedPlayer.isChanneling,
            hasteMultiplier = simulatedPlayer.hasteMultiplier,
            critChance = simulatedPlayer.critChance,
            mastery = simulatedPlayer.mastery,
            versatility = simulatedPlayer.versatility,
            inCombat = true,
            auras = {}
        },
        targets = {},
        resources = {},
        cooldowns = {}
    }
    
    -- Copy player auras
    for auraName, aura in pairs(simulatedPlayer.auras) do
        state.player.auras[auraName] = {
            name = aura.name,
            duration = aura.duration,
            expirationTime = aura.expirationTime,
            stacks = aura.stacks,
            isBuff = aura.isBuff
        }
    end
    
    -- Copy targets
    for unitId, unit in pairs(simulatedUnits) do
        state.targets[unitId] = {
            guid = unit.guid,
            health = unit.health,
            maxHealth = unit.maxHealth,
            healthPercent = (unit.health / unit.maxHealth) * 100,
            position = unit.position,
            distance = unit.distance,
            isCasting = unit.isCasting,
            isChanneling = unit.isChanneling,
            auras = {}
        }
        
        -- Copy target auras
        for auraName, aura in pairs(unit.auras) do
            state.targets[unitId].auras[auraName] = {
                name = aura.name,
                duration = aura.duration,
                expirationTime = aura.expirationTime,
                stacks = aura.stacks,
                isBuff = aura.isBuff
            }
        end
    end
    
    -- Copy resources
    for resourceName, resource in pairs(simulatedResources) do
        state.resources[resourceName] = {
            current = resource.current,
            max = resource.max,
            percent = (resource.current / resource.max) * 100
        }
    end
    
    -- Copy cooldowns
    for spellId, cooldownInfo in pairs(simulatedPlayer.cooldowns) do
        state.cooldowns[spellId] = {
            endTime = cooldownInfo.endTime,
            remainingTime = cooldownInfo.endTime - currentTime
        }
    end
    
    -- Add GCD status
    state.gcdRemaining = simulatedPlayer.gcdEnd > currentTime and (simulatedPlayer.gcdEnd - currentTime) or 0
    
    return state
end

-- Check if a unit has an aura
function RotationSimulator:HasAura(unit, auraName)
    if unit == "player" then
        return simulatedPlayer.auras[auraName] ~= nil
    elseif simulatedUnits[unit] then
        return simulatedUnits[unit].auras[auraName] ~= nil
    end
    return false
end

-- Get aura information for a unit
function RotationSimulator:GetAuraInfo(unit, auraName)
    if unit == "player" and simulatedPlayer.auras[auraName] then
        return simulatedPlayer.auras[auraName]
    elseif simulatedUnits[unit] and simulatedUnits[unit].auras[auraName] then
        return simulatedUnits[unit].auras[auraName]
    end
    return nil
end

-- Mock the rotation function for a module
function RotationSimulator:MockRotation(moduleTable, time, state)
    -- Default implementation - should be overridden by module
    if not moduleTable.RunRotation then
        -- Return a default mock behavior if module doesn't have a rotation
        local castableSpells = { "ATTACK" }
        local randomSpell = castableSpells[math.random(1, #castableSpells)]
        return randomSpell, "target"
    end
    
    -- Use module's rotation
    local spellToCast = moduleTable:RunRotation()
    if spellToCast then
        return spellToCast, "target"
    end
    
    return nil
end

-- Finalize the simulation and calculate results
function RotationSimulator:FinalizeSimulation()
    -- Calculate DPS and HPS
    averageDPS = totalDamage / simulationDuration
    averageHPS = totalHealing / simulationDuration
    
    -- Calculate spell DPS contributions
    for spellName, data in pairs(simulatedDamage) do
        abilityDPS[spellName] = data.totalDamage / simulationDuration
    end
    
    -- Calculate ability uptimes
    for auraName, data in pairs(abilityUptime) do
        -- Ensure uptime is calculated properly if aura is still active at end
        if simulatedPlayer.auras[auraName] then
            data.totalUptime = data.totalUptime + (simulationDuration - data.lastApplied)
        end
        
        -- Calculate percentage uptime
        data.percentUptime = (data.totalUptime / simulationDuration) * 100
    end
    
    -- Sort ability DPS contributions
    local sortedAbilityDPS = {}
    for spellName, dps in pairs(abilityDPS) do
        table.insert(sortedAbilityDPS, {name = spellName, dps = dps})
    end
    table.sort(sortedAbilityDPS, function(a, b) return a.dps > b.dps end)
    
    -- Prepare results table
    simulationResults = {
        duration = simulationDuration,
        totalDamage = totalDamage,
        totalHealing = totalHealing,
        totalManaUsed = totalManaUsed,
        totalSpellCasts = totalSpellCasts,
        timeSpentCasting = timeSpentCasting,
        averageDPS = averageDPS,
        averageHPS = averageHPS,
        abilityCastCounts = abilityCastCounts,
        abilityDPS = sortedAbilityDPS,
        abilityUptime = abilityUptime
    }
    
    -- Generate report
    self:GenerateSimulationReport()
    
    -- End simulation
    simulationActive = false
    API.PrintDebug("Simulation complete.")
    
    return true
end

-- Generate a report from simulation results
function RotationSimulator:GenerateSimulationReport()
    if not simulationResults then
        return
    end
    
    local settings = ConfigRegistry:GetSettings("RotationSimulator")
    
    -- Create header
    local report = {
        "===== WindrunnerRotations Simulation Report =====",
        string.format("Class: %s, Spec: %s, Duration: %.1f seconds", 
            self:GetClassNameFromID(simulatedClassId), 
            self:GetSpecNameFromID(simulatedSpecId), 
            simulationResults.duration),
        string.format("Total Damage: %.0f, DPS: %.1f", 
            simulationResults.totalDamage, 
            simulationResults.averageDPS),
        ""
    }
    
    -- Add ability summary
    if settings.outputSettings.showAbilitySummary then
        table.insert(report, "--- Ability Summary ---")
        
        -- Top damaging abilities
        table.insert(report, "Top Damage Sources:")
        for i, ability in ipairs(simulationResults.abilityDPS) do
            if i <= 10 then -- Show top 10
                table.insert(report, string.format("%d. %s: %.1f DPS (%.1f%% of total)", 
                    i, ability.name, ability.dps, (ability.dps / simulationResults.averageDPS) * 100))
            end
        end
        table.insert(report, "")
        
        -- Ability cast counts
        table.insert(report, "Ability Usage:")
        local sortedCasts = {}
        for name, count in pairs(simulationResults.abilityCastCounts) do
            table.insert(sortedCasts, {name = name, count = count})
        end
        table.sort(sortedCasts, function(a, b) return a.count > b.count end)
        
        for i, ability in ipairs(sortedCasts) do
            table.insert(report, string.format("%s: %d casts", ability.name, ability.count))
        end
        table.insert(report, "")
        
        -- Aura uptimes
        local sortedUptime = {}
        for name, data in pairs(simulationResults.abilityUptime) do
            table.insert(sortedUptime, {name = name, uptime = data.percentUptime})
        end
        table.sort(sortedUptime, function(a, b) return a.uptime > b.uptime end)
        
        if #sortedUptime > 0 then
            table.insert(report, "Buff/Debuff Uptimes:")
            for i, ability in ipairs(sortedUptime) do
                table.insert(report, string.format("%s: %.1f%% uptime", ability.name, ability.uptime))
            end
            table.insert(report, "")
        end
    end
    
    -- Add resource usage
    if settings.outputSettings.showResourceUsage then
        table.insert(report, "--- Resource Usage ---")
        if simulatedResources.mana then
            table.insert(report, string.format("Mana Used: %.1f%%", 
                (simulationResults.totalManaUsed / 100) * 100))
        end
        -- Add other resources as needed
        table.insert(report, "")
    end
    
    -- Add timeline info
    if settings.outputSettings.showTimeline then
        table.insert(report, "--- Timeline Highlights ---")
        -- Show up to 10 important events from the timeline
        local importantEvents = {}
        for i, event in ipairs(simulationTimeline) do
            if event.event == "DAMAGE" and event.amount > (simulationResults.averageDPS * 3) then
                -- Highlight big damage spikes
                table.insert(importantEvents, {
                    time = event.time,
                    description = string.format("%.1fs: %s hit for %.0f damage", 
                        event.time, API.GetSpellInfo(event.spell).name or "Unknown", event.amount)
                })
            elseif event.event == "APPLY_AURA" and event.aura == "BLOODLUST" then
                -- Highlight Bloodlust
                table.insert(importantEvents, {
                    time = event.time,
                    description = string.format("%.1fs: Bloodlust activated", event.time)
                })
            end
        end
        
        table.sort(importantEvents, function(a, b) return a.time < b.time end)
        
        for i, event in ipairs(importantEvents) do
            if i <= 10 then
                table.insert(report, event.description)
            end
        end
        table.insert(report, "")
    end
    
    -- Add optimal rotation advice
    if settings.outputSettings.showOptimalRotation then
        table.insert(report, "--- Optimal Rotation Advice ---")
        -- Use ability DPS and cast counts to suggest optimal rotation
        table.insert(report, "Priority order based on simulation:")
        
        -- Core rotation abilities (most frequently used high-damage abilities)
        local coreAbilities = {}
        for i, ability in ipairs(simulationResults.abilityDPS) do
            if simulationResults.abilityCastCounts[ability.name] > 3 then
                table.insert(coreAbilities, ability)
            end
        end
        
        for i, ability in ipairs(coreAbilities) do
            if i <= 5 then
                table.insert(report, string.format("%d. %s", i, ability.name))
            end
        end
        
        -- Cooldowns (high damage, low cast count)
        local cooldowns = {}
        for i, ability in ipairs(simulationResults.abilityDPS) do
            if simulationResults.abilityCastCounts[ability.name] <= 3 and
               ability.dps > (simulationResults.averageDPS * 0.05) then
                table.insert(cooldowns, ability)
            end
        end
        
        if #cooldowns > 0 then
            table.insert(report, "")
            table.insert(report, "Important cooldowns:")
            for i, ability in ipairs(cooldowns) do
                table.insert(report, string.format("- %s", ability.name))
            end
        end
    end
    
    -- Output report to chat if enabled
    if settings.generalSettings.outputToChat then
        for _, line in ipairs(report) do
            API.Print(line)
        end
    end
    
    -- Save report
    simulationResults.report = report
    
    return report
end

-- Get class name from ID
function RotationSimulator:GetClassNameFromID(classId)
    local classNames = {
        [1] = "Warrior",
        [2] = "Paladin",
        [3] = "Hunter",
        [4] = "Rogue",
        [5] = "Priest",
        [6] = "Death Knight",
        [7] = "Shaman",
        [8] = "Mage",
        [9] = "Warlock",
        [10] = "Monk",
        [11] = "Druid",
        [12] = "Demon Hunter",
        [13] = "Evoker"
    }
    
    return classNames[classId] or "Unknown"
end

-- Get spec name from ID
function RotationSimulator:GetSpecNameFromID(specId)
    local specNames = {
        -- Warrior
        [71] = "Arms",
        [72] = "Fury",
        [73] = "Protection",
        
        -- Paladin
        [65] = "Holy",
        [66] = "Protection",
        [70] = "Retribution",
        
        -- Hunter
        [253] = "Beast Mastery",
        [254] = "Marksmanship",
        [255] = "Survival",
        
        -- Rogue
        [259] = "Assassination",
        [260] = "Outlaw",
        [261] = "Subtlety",
        
        -- Priest
        [256] = "Discipline",
        [257] = "Holy",
        [258] = "Shadow",
        
        -- Death Knight
        [250] = "Blood",
        [251] = "Frost",
        [252] = "Unholy",
        
        -- Shaman
        [262] = "Elemental",
        [263] = "Enhancement",
        [264] = "Restoration",
        
        -- Mage
        [62] = "Arcane",
        [63] = "Fire",
        [64] = "Frost",
        
        -- Warlock
        [265] = "Affliction",
        [266] = "Demonology",
        [267] = "Destruction",
        
        -- Monk
        [268] = "Brewmaster",
        [269] = "Windwalker",
        [270] = "Mistweaver",
        
        -- Druid
        [102] = "Balance",
        [103] = "Feral",
        [104] = "Guardian",
        [105] = "Restoration",
        
        -- Demon Hunter
        [577] = "Havoc",
        [581] = "Vengeance",
        
        -- Evoker
        [1467] = "Devastation",
        [1468] = "Preservation",
        [1473] = "Augmentation"
    }
    
    return specNames[specId] or "Unknown"
end

-- Handle slash command input
function RotationSimulator:HandleSlashCommand(msg)
    if not msg or msg == "" then
        -- Display help
        API.Print("WindrunnerRotations Simulator Commands:")
        API.Print("/wrsim start - Start simulation with current settings")
        API.Print("/wrsim stop - Stop current simulation")
        API.Print("/wrsim report - Show last simulation report")
        API.Print("/wrsim config - Show simulation settings")
        return
    end
    
    local args = {}
    for arg in string.gmatch(msg, "%S+") do
        table.insert(args, arg)
    end
    
    local command = args[1]
    
    if command == "start" then
        -- Get duration if provided
        local duration = tonumber(args[2])
        self:StartSimulation(duration)
    elseif command == "stop" then
        if simulationActive then
            simulationActive = false
            API.Print("Simulation stopped.")
        else
            API.Print("No simulation is currently running.")
        end
    elseif command == "report" then
        if simulationResults and simulationResults.report then
            for _, line in ipairs(simulationResults.report) do
                API.Print(line)
            end
        else
            API.Print("No simulation report available. Run a simulation first.")
        end
    elseif command == "config" then
        -- Display current settings
        local settings = ConfigRegistry:GetSettings("RotationSimulator")
        API.Print("WindrunnerRotations Simulator Settings:")
        API.Print("Duration: " .. settings.generalSettings.defaultSimulationDuration .. " seconds")
        API.Print("Step Size: " .. settings.generalSettings.simulationStepSize .. " seconds")
        API.Print("Target Health: " .. settings.simulationSettings.targetHealth .. "K")
        API.Print("Enemy Count: " .. settings.simulationSettings.enemyCount)
    else
        API.Print("Unknown command. Type /wrsim for help.")
    end
end

return RotationSimulator