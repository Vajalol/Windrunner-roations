------------------------------------------
-- WindrunnerRotations - Boss-Specific Strategies System
-- Author: VortexQ8
-- The War Within Season 2
------------------------------------------

local addonName, WR = ...
local BossStrategies = {}
WR.BossStrategies = BossStrategies

-- Dependencies
local API = WR.API
local ConfigRegistry = WR.ConfigRegistry
local ModuleManager = WR.ModuleManager
local MachineLearning = WR.MachineLearning

-- Data storage
local bossDatabase = {}
local activeBossID = nil
local currentPhase = nil
local activeEncounter = nil
local detectedMechanics = {}
local strategyOverrides = {}
local currentStrategy = nil
local phaseCallbacks = {}
local mechanicDetectors = {}
local phaseTimers = {}
local encounterHistory = {}
local activeModifiers = {}
local MAX_ENCOUNTER_HISTORY = 20

-- Constants
local MECHANIC_CHECK_INTERVAL = 0.2 -- seconds

-- Initialize the Boss Strategies system
function BossStrategies:Initialize()
    -- Register settings
    self:RegisterSettings()
    
    -- Register slash command
    SLASH_WRBOSS1 = "/wrboss"
    SlashCmdList["WRBOSS"] = function(msg)
        self:HandleSlashCommand(msg)
    end
    
    -- Load boss database
    self:LoadBossDatabase()
    
    -- Setup event tracking
    self:SetupEventTracking()
    
    -- Register mechanic detectors
    self:RegisterMechanicDetectors()
    
    API.PrintDebug("Boss Strategies system initialized")
    return true
end

-- Register settings for the Boss Strategies system
function BossStrategies:RegisterSettings()
    ConfigRegistry:RegisterSettings("BossStrategies", {
        generalSettings = {
            enableBossStrategies = {
                displayName = "Enable Boss Strategies",
                description = "Enable specialized strategies for raid and dungeon bosses",
                type = "toggle",
                default = true
            },
            bossDetection = {
                displayName = "Boss Detection",
                description = "How to detect boss encounters",
                type = "dropdown",
                options = { "automatic", "manual", "boss_only", "all_encounters" },
                default = "automatic"
            },
            notifyPhaseChanges = {
                displayName = "Notify Phase Changes",
                description = "Show notifications when boss phases change",
                type = "toggle",
                default = true
            },
            enableMechanicDetection = {
                displayName = "Enable Mechanic Detection",
                description = "Detect boss mechanics and adapt rotation accordingly",
                type = "toggle",
                default = true
            }
        },
        strategySettings = {
            prioritizeStrategies = {
                displayName = "Strategy Priority",
                description = "Which types of strategies to prioritize",
                type = "dropdown",
                options = { "balanced", "damage", "survival", "utility" },
                default = "balanced"
            },
            allowAutomaticSwitching = {
                displayName = "Automatic Strategy Switching",
                description = "Automatically switch strategies based on boss phases and mechanics",
                type = "toggle",
                default = true
            },
            defaultStrategy = {
                displayName = "Default Strategy",
                description = "Strategy to use when no specific boss strategy is available",
                type = "dropdown",
                options = { "standard", "conservative", "aggressive" },
                default = "standard"
            },
            strategyAdaptationRate = {
                displayName = "Strategy Adaptation Rate",
                description = "How quickly to adapt strategies during an encounter",
                type = "slider",
                min = 1,
                max = 10,
                step = 1,
                default = 5
            }
        },
        mechanicSettings = {
            enableMovementHandling = {
                displayName = "Enable Movement Handling",
                description = "Enable special handling for movement-heavy mechanics",
                type = "toggle",
                default = true
            },
            enableInterruptPriority = {
                displayName = "Enable Interrupt Priority",
                description = "Prioritize interrupts for critical boss abilities",
                type = "toggle",
                default = true
            },
            enableDefensiveTimings = {
                displayName = "Enable Defensive Timings",
                description = "Use defensive cooldowns at optimal times during boss fights",
                type = "toggle",
                default = true
            },
            enableCooldownOptimization = {
                displayName = "Enable Cooldown Optimization",
                description = "Optimize offensive cooldown usage for boss phases",
                type = "toggle",
                default = true
            }
        },
        displaySettings = {
            showEncounterInfo = {
                displayName = "Show Encounter Info",
                description = "Display current boss encounter information",
                type = "toggle",
                default = true
            },
            showActiveStrategy = {
                displayName = "Show Active Strategy",
                description = "Display the currently active boss strategy",
                type = "toggle",
                default = true
            },
            showMechanicWarnings = {
                displayName = "Show Mechanic Warnings",
                description = "Display warnings for upcoming boss mechanics",
                type = "toggle",
                default = true
            },
            warningStyle = {
                displayName = "Warning Style",
                description = "How to display mechanic warnings",
                type = "dropdown",
                options = { "text", "icon", "both" },
                default = "both"
            }
        },
        customizationSettings = {
            allowCustomStrategies = {
                displayName = "Allow Custom Strategies",
                description = "Enable creating and using custom boss strategies",
                type = "toggle",
                default = true
            },
            customStrategyPriority = {
                displayName = "Custom Strategy Priority",
                description = "Priority level for custom strategies vs built-in ones",
                type = "dropdown",
                options = { "low", "medium", "high", "override" },
                default = "high"
            },
            shareCustomStrategies = {
                displayName = "Share Custom Strategies",
                description = "Allow sharing custom strategies with other players",
                type = "toggle",
                default = false
            }
        },
        debugSettings = {
            enableDebugMode = {
                displayName = "Enable Debug Mode",
                description = "Enable detailed logging for boss strategies",
                type = "toggle",
                default = false
            },
            logMechanicDetection = {
                displayName = "Log Mechanic Detection",
                description = "Log detailed information about detected mechanics",
                type = "toggle",
                default = false
            },
            logStrategySelection = {
                displayName = "Log Strategy Selection",
                description = "Log detailed information about strategy selection",
                type = "toggle",
                default = false
            }
        }
    })
end

-- Load the boss database
function BossStrategies:LoadBossDatabase()
    -- In a real addon, this would load from a data file
    -- For our implementation, we'll build a sample database
    
    bossDatabase = {
        -- Amirdrassil, the Dream's Hope
        [2564] = { -- Gnarlroot
            name = "Gnarlroot",
            zoneID = 2549,
            encounterID = 2564,
            phases = {
                [1] = {
                    name = "Phase 1",
                    description = "Standard phase with adds",
                    mechanics = {
                        "doom_totem",
                        "withering_roots",
                        "controlled_burn"
                    },
                    strategy = {
                        priority = "adds_then_boss",
                        movement = "minimal",
                        cooldowns = "on_pull"
                    }
                },
                [2] = {
                    name = "Intermission",
                    description = "Dodge falling trees and break roots",
                    mechanics = {
                        "falling_timber",
                        "entangling_roots"
                    },
                    strategy = {
                        priority = "survivability",
                        movement = "high",
                        cooldowns = "save"
                    }
                },
                [3] = {
                    name = "Phase 2",
                    description = "Empowered abilities",
                    mechanics = {
                        "doom_totem",
                        "withering_roots",
                        "controlled_burn",
                        "blazing_pitch"
                    },
                    strategy = {
                        priority = "boss_only",
                        movement = "medium",
                        cooldowns = "during_lust"
                    }
                }
            },
            strategies = {
                default = {
                    description = "Default balanced strategy",
                    classSpecific = {}
                },
                aoe = {
                    description = "AoE focused for add phases",
                    classSpecific = {}
                },
                survival = {
                    description = "Survival focused for high damage phases",
                    classSpecific = {}
                }
            }
        },
        [2565] = { -- Igira the Cruel
            name = "Igira the Cruel",
            zoneID = 2549,
            encounterID = 2565,
            phases = {
                [1] = {
                    name = "Blistering Torment",
                    description = "Fire phase with torment mechanic",
                    mechanics = {
                        "blistering_torment",
                        "gathering_torment",
                        "smashing_viscera"
                    },
                    strategy = {
                        priority = "burst_damage",
                        movement = "medium",
                        cooldowns = "phase_start"
                    }
                },
                [2] = {
                    name = "Umbral Torment",
                    description = "Shadow phase with torment mechanic",
                    mechanics = {
                        "umbral_torment",
                        "gathering_torment",
                        "marked_for_torment"
                    },
                    strategy = {
                        priority = "sustained_damage",
                        movement = "medium",
                        cooldowns = "phase_start"
                    }
                },
                [3] = {
                    name = "Cruel Torment",
                    description = "Final phase with all mechanics",
                    mechanics = {
                        "blistering_torment",
                        "umbral_torment",
                        "gathering_torment",
                        "marked_for_torment",
                        "smashing_viscera"
                    },
                    strategy = {
                        priority = "burst_damage",
                        movement = "high",
                        cooldowns = "with_bloodlust"
                    }
                }
            },
            strategies = {
                default = {
                    description = "Default balanced strategy",
                    classSpecific = {}
                },
                mobility = {
                    description = "Mobility focused for high movement phases",
                    classSpecific = {}
                },
                burst = {
                    description = "Burst focused for phase transitions",
                    classSpecific = {}
                }
            }
        },
        [2563] = { -- Volcoross
            name = "Volcoross",
            zoneID = 2549,
            encounterID = 2563,
            phases = {
                [1] = {
                    name = "Main Phase",
                    description = "Single phase fight with increasing difficulty",
                    mechanics = {
                        "scorchtail_crash",
                        "coiling_flames",
                        "serpents_fury",
                        "flood_of_the_firelands"
                    },
                    strategy = {
                        priority = "sustained_damage",
                        movement = "high",
                        cooldowns = "on_pull_and_timed"
                    }
                }
            },
            strategies = {
                default = {
                    description = "Default balanced strategy",
                    classSpecific = {}
                },
                movement = {
                    description = "Movement focused for dodging mechanics",
                    classSpecific = {}
                },
                cooldown = {
                    description = "Optimized cooldown usage for key moments",
                    classSpecific = {}
                }
            }
        },
        
        -- Aberrus Raid from previous patch (for historical data)
        [2688] = { -- Rashok, the Elder
            name = "Rashok, the Elder",
            zoneID = 2569,
            encounterID = 2688,
            phases = {
                [1] = {
                    name = "Phase 1",
                    description = "Initial phase with rage mechanic",
                    mechanics = {
                        "living_lava",
                        "searing_chest",
                        "elder_tempest"
                    },
                    strategy = {
                        priority = "sustained_damage",
                        movement = "medium",
                        cooldowns = "on_pull"
                    }
                },
                [2] = {
                    name = "Phase 2",
                    description = "Empowered phase with increased damage",
                    mechanics = {
                        "living_lava",
                        "searing_chest",
                        "elder_tempest",
                        "charged_smash"
                    },
                    strategy = {
                        priority = "burst_damage",
                        movement = "high",
                        cooldowns = "with_bloodlust"
                    }
                }
            },
            strategies = {
                default = {
                    description = "Default balanced strategy",
                    classSpecific = {}
                }
            }
        },
        
        -- Mythic+ Dungeons
        [2499] = { -- Chrono-Lord Deios (Dawn of the Infinite)
            name = "Chrono-Lord Deios",
            zoneID = 2579,
            encounterID = 2499,
            isDungeon = true,
            phases = {
                [1] = {
                    name = "Phase 1",
                    description = "Initial phase with time mechanics",
                    mechanics = {
                        "time_sink",
                        "infinite_annihilation",
                        "temporal_breath"
                    },
                    strategy = {
                        priority = "sustained_damage",
                        movement = "medium",
                        cooldowns = "save_for_phase_2"
                    }
                },
                [2] = {
                    name = "Phase 2",
                    description = "Final phase with double bosses",
                    mechanics = {
                        "time_sink",
                        "infinite_annihilation",
                        "temporal_breath",
                        "chronomatic_anomaly"
                    },
                    strategy = {
                        priority = "burst_damage",
                        movement = "high",
                        cooldowns = "use_all"
                    }
                }
            },
            strategies = {
                default = {
                    description = "Default balanced strategy",
                    classSpecific = {}
                },
                tyrannical = {
                    description = "Strategy optimized for Tyrannical affix",
                    classSpecific = {}
                },
                fortified = {
                    description = "Strategy optimized for Fortified affix",
                    classSpecific = {}
                }
            }
        }
    }
    
    -- Add class-specific strategies for some bosses as examples
    -- Gnarlroot strategies for Mage
    bossDatabase[2564].strategies.default.classSpecific[8] = { -- Mage class ID
        [1] = { -- Arcane
            description = "Arcane Mage strategy for Gnarlroot",
            priority = "Use cooldowns during intermission transition",
            abilities = {
                ["arcane_power"] = "save_for_phase_3",
                ["touch_of_the_magi"] = "use_on_cooldown",
                ["arcane_barrage"] = "use_at_4_charges_on_adds"
            }
        },
        [2] = { -- Fire
            description = "Fire Mage strategy for Gnarlroot",
            priority = "Cleave damage during add phases",
            abilities = {
                ["combustion"] = "save_for_phase_3",
                ["flamestrike"] = "use_on_3+_adds",
                ["dragons_breath"] = "use_for_add_control"
            }
        },
        [3] = { -- Frost
            description = "Frost Mage strategy for Gnarlroot",
            priority = "Add control and sustained cleave",
            abilities = {
                ["icy_veins"] = "use_on_pull_and_phase_3",
                ["frozen_orb"] = "use_on_add_packs",
                ["blizzard"] = "maintain_for_add_control"
            }
        }
    }
    
    -- Igira strategies for Evoker
    bossDatabase[2565].strategies.default.classSpecific[13] = { -- Evoker class ID
        [1] = { -- Devastation
            description = "Devastation Evoker strategy for Igira",
            priority = "Mobile damage during high movement phases",
            abilities = {
                ["dragonrage"] = "save_for_phase_3",
                ["fire_breath"] = "use_on_cooldown",
                ["azure_strike"] = "use_during_movement"
            }
        },
        [2] = { -- Preservation
            description = "Preservation Evoker strategy for Igira",
            priority = "Burst healing during Gathering Torment",
            abilities = {
                ["emerald_communion"] = "use_before_gathering_torment",
                ["dream_breath"] = "use_for_group_healing",
                ["emerald_blossom"] = "maintain_on_tanks"
            }
        },
        [3] = { -- Augmentation
            description = "Augmentation Evoker strategy for Igira",
            priority = "Support buffs during critical phases",
            abilities = {
                ["breath_of_eons"] = "use_in_phase_3",
                ["ebon_might"] = "prioritize_on_dps",
                ["time_spiral"] = "use_after_gathering_torment"
            }
        }
    }
    
    API.PrintDebug("Boss database loaded with " .. self:CountBosses() .. " bosses")
end

-- Count the number of bosses in the database
function BossStrategies:CountBosses()
    local count = 0
    for _ in pairs(bossDatabase) do
        count = count + 1
    end
    return count
end

-- Setup event tracking
function BossStrategies:SetupEventTracking()
    -- Register for encounter start event
    API.RegisterEvent("ENCOUNTER_START", function(encounterID, encounterName, difficultyID, raidSize)
        self:StartEncounter(encounterID, encounterName, difficultyID, raidSize)
    end)
    
    -- Register for encounter end event
    API.RegisterEvent("ENCOUNTER_END", function(encounterID, encounterName, difficultyID, raidSize, success)
        self:EndEncounter(encounterID, encounterName, difficultyID, raidSize, success)
    end)
    
    -- Register for boss unit detection
    API.RegisterEvent("UNIT_TARGET", function(unit)
        if unit == "player" then
            self:CheckForBossTarget()
        end
    end)
    
    -- Register for combat log events
    API.RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", function()
        self:ProcessCombatLogEvent(CombatLogGetCurrentEventInfo())
    end)
    
    -- Register for spell cast events
    API.RegisterEvent("UNIT_SPELLCAST_START", function(unit, _, spellID)
        if self:IsUnitBoss(unit) then
            self:DetectBossMechanic(unit, spellID, "start")
        end
    end)
    
    -- Register for dungeon affix changes
    API.RegisterEvent("CHALLENGE_MODE_START", function()
        self:DetectMythicPlusAffixes()
    end)
}

-- Register mechanic detectors
function BossStrategies:RegisterMechanicDetectors()
    -- Register common mechanic detection patterns
    mechanicDetectors = {
        -- Detection patterns for specific boss mechanics
        -- Each pattern is a function that checks combat log events
        
        -- Gnarlroot mechanics
        doom_totem = function(event, sourceGUID, sourceName, destGUID, spellID, spellName)
            if event == "SPELL_CAST_START" and sourceName == "Gnarlroot" and spellID == 421898 then
                return true, "Doom Totem spawning - prepare to switch targets"
            end
            return false
        end,
        
        withering_roots = function(event, sourceGUID, sourceName, destGUID, spellID, spellName)
            if event == "SPELL_AURA_APPLIED" and spellID == 422053 then
                -- Check if applied to player or important unit
                local isImportant = (destGUID == UnitGUID("player") or UnitInRaid(destGUID))
                if isImportant then
                    return true, "Withering Roots on " .. (destGUID == UnitGUID("player") and "YOU" or UnitName(destGUID))
                end
            end
            return false
        end,
        
        -- Igira mechanics
        blistering_torment = function(event, sourceGUID, sourceName, destGUID, spellID, spellName)
            if event == "SPELL_CAST_START" and sourceName == "Igira the Cruel" and spellID == 414340 then
                return true, "Blistering Torment casting - prepare to spread"
            end
            return false
        end,
        
        gathering_torment = function(event, sourceGUID, sourceName, destGUID, spellID, spellName)
            if event == "SPELL_CAST_START" and sourceName == "Igira the Cruel" and spellID == 414770 then
                return true, "Gathering Torment casting - prepare for heavy damage"
            end
            return false
        end,
        
        -- Generic mechanic detectors
        heavy_damage = function(event, sourceGUID, sourceName, destGUID, spellID, spellName)
            if event == "SPELL_DAMAGE" and destGUID == UnitGUID("player") then
                local amount = select(15, CombatLogGetCurrentEventInfo())
                local healthPercent = UnitHealth("player") / UnitHealthMax("player") * 100
                
                -- If a single hit takes more than 40% health or brings below 30%
                if (amount / UnitHealthMax("player") > 0.4) or (healthPercent < 30) then
                    return true, "Heavy damage detected - consider defensive cooldowns"
                end
            end
            return false
        end,
        
        movement_required = function(event, sourceGUID, sourceName, destGUID, spellID, spellName)
            -- This would be a sophisticated detector for movement mechanics
            -- For implementation simplicity, we'll use a placeholder
            return false
        end,
        
        interrupt_required = function(event, sourceGUID, sourceName, destGUID, spellID, spellName)
            if event == "SPELL_CAST_START" then
                -- Check if it's a boss casting an interruptible spell
                local isBoss = self:IsUnitBoss(sourceGUID)
                local isInterruptible = self:IsSpellInterruptible(spellID)
                
                if isBoss and isInterruptible then
                    return true, "Interruptible cast: " .. (spellName or "Unknown") .. " - interrupt if possible"
                end
            end
            return false
        end,
        
        phase_change = function(event, sourceGUID, sourceName, destGUID, spellID, spellName)
            if event == "SPELL_CAST_START" then
                -- Check if it's a known phase transition ability
                local phaseChange = self:IsPhaseTransition(sourceName, spellID)
                if phaseChange then
                    return true, "Phase transition detected: " .. phaseChange
                end
            end
            return false
        end
    }
    
    -- Start mechanic detection timer
    C_Timer.NewTicker(MECHANIC_CHECK_INTERVAL, function()
        self:CheckActiveMechanics()
    end)
}

-- Start an encounter
function BossStrategies:StartEncounter(encounterID, encounterName, difficultyID, raidSize)
    local settings = ConfigRegistry:GetSettings("BossStrategies")
    if not settings.generalSettings.enableBossStrategies then
        return
    end
    
    -- Check if we have a strategy for this boss
    local boss = bossDatabase[encounterID]
    
    if boss then
        API.PrintDebug("Starting encounter: " .. encounterName .. " (ID: " .. encounterID .. ")")
        
        -- Set up the active encounter
        activeEncounter = {
            id = encounterID,
            name = encounterName,
            difficultyID = difficultyID,
            raidSize = raidSize,
            startTime = GetTime(),
            endTime = nil,
            currentPhase = 1,
            detectedMechanics = {},
            bossData = boss
        }
        
        -- Set the active boss ID
        activeBossID = encounterID
        
        -- Set the initial phase
        currentPhase = 1
        
        -- Clear detected mechanics
        detectedMechanics = {}
        
        -- Apply the initial strategy
        self:ApplyPhaseStrategy(1)
        
        -- Notify users
        if settings.displaySettings.showEncounterInfo then
            API.Print("Boss encounter started: " .. encounterName)
            API.Print("Active strategy: " .. self:GetActiveStrategyName())
        end
    else
        API.PrintDebug("No strategy found for encounter: " .. encounterName .. " (ID: " .. encounterID .. ")")
        
        -- Reset active encounter/boss
        activeEncounter = nil
        activeBossID = nil
        currentPhase = nil
    end
end

-- End an encounter
function BossStrategies:EndEncounter(encounterID, encounterName, difficultyID, raidSize, success)
    if not activeEncounter or activeEncounter.id ~= encounterID then
        return
    end
    
    -- Finalize the encounter data
    activeEncounter.endTime = GetTime()
    activeEncounter.duration = activeEncounter.endTime - activeEncounter.startTime
    activeEncounter.success = success == 1
    
    -- Add to encounter history
    table.insert(encounterHistory, activeEncounter)
    
    -- Trim history if needed
    if #encounterHistory > MAX_ENCOUNTER_HISTORY then
        table.remove(encounterHistory, 1)
    end
    
    -- Reset active encounter/boss
    activeBossID = nil
    currentPhase = nil
    activeEncounter = nil
    detectedMechanics = {}
    strategyOverrides = {}
    currentStrategy = nil
    
    -- Reset any phase timers
    for _, timer in pairs(phaseTimers) do
        timer:Cancel()
    end
    phaseTimers = {}
    
    -- Clear phase callbacks
    phaseCallbacks = {}
    
    -- Notify users
    local settings = ConfigRegistry:GetSettings("BossStrategies")
    if settings.displaySettings.showEncounterInfo then
        API.Print("Boss encounter ended: " .. encounterName .. " - " .. (success == 1 and "Victory!" or "Defeat"))
    end
    
    API.PrintDebug("Encounter ended: " .. encounterName .. " (Success: " .. (success == 1 and "Yes" or "No") .. ")")
}

-- Process a combat log event
function BossStrategies:ProcessCombatLogEvent(...)
    if not activeBossID then
        return
    end
    
    local settings = ConfigRegistry:GetSettings("BossStrategies")
    if not settings.generalSettings.enableBossStrategies or not settings.generalSettings.enableMechanicDetection then
        return
    end
    
    -- Extract event data
    local timestamp, event, _, sourceGUID, sourceName, sourceFlags, _, destGUID, destName, destFlags, _, spellID, spellName = ...
    
    -- Process the event for mechanic detection
    for mechanicName, detector in pairs(mechanicDetectors) do
        local detected, message = detector(event, sourceGUID, sourceName, destGUID, spellID, spellName)
        
        if detected then
            self:MechanicDetected(mechanicName, message, spellID)
        end
    end
    
    -- Check for phase changes
    self:CheckPhaseChange(event, sourceGUID, sourceName, spellID, spellName)
}

-- Check for phase changes
function BossStrategies:CheckPhaseChange(event, sourceGUID, sourceName, spellID, spellName)
    if not activeBossID or not activeEncounter then
        return
    end
    
    local boss = bossDatabase[activeBossID]
    if not boss or not boss.phases then
        return
    end
    
    -- This would include boss-specific phase detection logic
    -- For implementation simplicity, we'll use a placeholder
    
    -- Check if this spell is a known phase transition
    if event == "SPELL_CAST_START" or event == "SPELL_CAST_SUCCESS" then
        local newPhase = self:GetPhaseFromSpell(activeBossID, sourceName, spellID)
        
        if newPhase and newPhase ~= currentPhase then
            self:ChangePhase(newPhase)
        end
    end
    
    -- Check health-based phase transitions
    if event == "SPELL_DAMAGE" and sourceGUID == UnitGUID("player") then
        local targetGUID = destGUID
        local isTarget = self:IsUnitBoss(targetGUID)
        
        if isTarget then
            local healthPercent = self:GetUnitHealthPercent(targetGUID)
            local newPhase = self:GetPhaseFromHealth(activeBossID, healthPercent)
            
            if newPhase and newPhase ~= currentPhase then
                self:ChangePhase(newPhase)
            end
        end
    end
}

-- Change to a new phase
function BossStrategies:ChangePhase(newPhase)
    if not activeBossID or not activeEncounter then
        return
    end
    
    local boss = bossDatabase[activeBossID]
    if not boss or not boss.phases or not boss.phases[newPhase] then
        return
    end
    
    local oldPhase = currentPhase
    currentPhase = newPhase
    activeEncounter.currentPhase = newPhase
    
    -- Apply the new phase strategy
    self:ApplyPhaseStrategy(newPhase)
    
    -- Notify users
    local settings = ConfigRegistry:GetSettings("BossStrategies")
    if settings.generalSettings.notifyPhaseChanges then
        API.Print("Boss phase changed: " .. boss.phases[newPhase].name)
        API.Print("Active strategy updated: " .. self:GetActiveStrategyName())
    end
    
    -- Fire phase callbacks
    self:FirePhaseCallbacks(oldPhase, newPhase)
    
    API.PrintDebug("Phase changed to: " .. newPhase .. " (" .. boss.phases[newPhase].name .. ")")
}

-- Apply a phase-specific strategy
function BossStrategies:ApplyPhaseStrategy(phase)
    if not activeBossID or not activeEncounter then
        return
    end
    
    local boss = bossDatabase[activeBossID]
    if not boss or not boss.phases or not boss.phases[phase] then
        return
    end
    
    local phaseData = boss.phases[phase]
    local settings = ConfigRegistry:GetSettings("BossStrategies")
    
    -- Determine which strategy to use
    local strategyName = "default"
    
    -- Check for strategy overrides
    if strategyOverrides[activeBossID] then
        strategyName = strategyOverrides[activeBossID]
    else
        -- Select strategy based on settings and encounter
        strategyName = self:SelectBestStrategy(activeBossID, phase)
    end
    
    -- Get the strategy
    local strategy = boss.strategies[strategyName]
    if not strategy then
        -- Fall back to default if selected strategy doesn't exist
        strategy = boss.strategies.default
        strategyName = "default"
    end
    
    -- Get class-specific strategy if available
    local classID = API.GetPlayerClassID()
    local specID = API.GetActiveSpecID()
    
    local classStrategy = nil
    if strategy.classSpecific[classID] and strategy.classSpecific[classID][specID] then
        classStrategy = strategy.classSpecific[classID][specID]
    end
    
    -- Apply the strategy
    currentStrategy = {
        name = strategyName,
        bossID = activeBossID,
        phase = phase,
        phaseName = phaseData.name,
        phaseDescription = phaseData.description,
        baseStrategy = strategy,
        classStrategy = classStrategy,
        phasePriority = phaseData.strategy.priority,
        phaseMovement = phaseData.strategy.movement,
        phaseCooldowns = phaseData.strategy.cooldowns,
        mechanics = phaseData.mechanics
    }
    
    -- Log strategy selection
    if settings.debugSettings.logStrategySelection then
        API.PrintDebug("Strategy applied: " .. strategyName .. " for phase " .. phase)
        if classStrategy then
            API.PrintDebug("Class-specific strategy: " .. classStrategy.description)
        end
    end
}

-- Select the best strategy for a given boss and phase
function BossStrategies:SelectBestStrategy(bossID, phase)
    local boss = bossDatabase[bossID]
    if not boss then
        return "default"
    end
    
    local settings = ConfigRegistry:GetSettings("BossStrategies")
    local strategyPriority = settings.strategySettings.prioritizeStrategies
    
    -- Start with default
    local bestStrategy = "default"
    
    -- Check for dungeon affixes
    if boss.isDungeon then
        -- Check for Tyrannical or Fortified strategies
        if self:IsTyrannicalActive() and boss.strategies.tyrannical then
            bestStrategy = "tyrannical"
        elseif self:IsFortifiedActive() and boss.strategies.fortified then
            bestStrategy = "fortified"
        end
    end
    
    -- Check for strategy based on user priority
    if strategyPriority == "damage" and boss.strategies.aoe then
        bestStrategy = "aoe" -- Prioritize damage
    elseif strategyPriority == "survival" and boss.strategies.survival then
        bestStrategy = "survival" -- Prioritize survival
    elseif strategyPriority == "utility" and boss.strategies.utility then
        bestStrategy = "utility" -- Prioritize utility
    elseif strategyPriority == "balanced" then
        -- Already using default/balanced or affix-specific
    end
    
    -- If ML system is available, use it to refine strategy
    if MachineLearning and MachineLearning.SuggestBossStrategy then
        local mlStrategy = MachineLearning:SuggestBossStrategy(bossID, phase)
        if mlStrategy and boss.strategies[mlStrategy] then
            bestStrategy = mlStrategy
        end
    end
    
    return bestStrategy
end

-- Get the name of the active strategy
function BossStrategies:GetActiveStrategyName()
    if not currentStrategy then
        return "None"
    end
    
    local strategyDesc = currentStrategy.name
    
    if currentStrategy.classStrategy then
        strategyDesc = strategyDesc .. " (" .. currentStrategy.classStrategy.description .. ")"
    end
    
    return strategyDesc
}

-- Handle a detected mechanic
function BossStrategies:MechanicDetected(mechanicName, message, spellID)
    if not activeBossID or not activeEncounter then
        return
    end
    
    local settings = ConfigRegistry:GetSettings("BossStrategies")
    
    -- Add to detected mechanics list
    if not detectedMechanics[mechanicName] then
        detectedMechanics[mechanicName] = {
            count = 1,
            lastDetected = GetTime(),
            spellID = spellID
        }
    else
        detectedMechanics[mechanicName].count = detectedMechanics[mechanicName].count + 1
        detectedMechanics[mechanicName].lastDetected = GetTime()
    end
    
    -- Add to encounter mechanics
    if not activeEncounter.detectedMechanics[mechanicName] then
        activeEncounter.detectedMechanics[mechanicName] = {
            count = 1,
            firstDetected = GetTime()
        }
    else
        activeEncounter.detectedMechanics[mechanicName].count = activeEncounter.detectedMechanics[mechanicName].count + 1
    end
    
    -- Log mechanic detection
    if settings.debugSettings.logMechanicDetection then
        API.PrintDebug("Mechanic detected: " .. mechanicName .. " (" .. (message or "") .. ")")
    end
    
    -- Check if this mechanic should trigger a strategy change
    self:CheckMechanicStrategies(mechanicName)
    
    -- Show warning to user if enabled
    if settings.displaySettings.showMechanicWarnings then
        -- This would use a UI element to show the warning
        -- For implementation simplicity, we'll just print it
        API.Print("|cFFFF4500Boss Mechanic:|r " .. (message or mechanicName))
    end
}

-- Check if a mechanic should trigger a strategy change
function BossStrategies:CheckMechanicStrategies(mechanicName)
    if not activeBossID or not currentStrategy then
        return
    end
    
    local settings = ConfigRegistry:GetSettings("BossStrategies")
    if not settings.strategySettings.allowAutomaticSwitching then
        return
    end
    
    -- This would include mechanic-specific strategy adjustments
    -- For implementation simplicity, we'll use a placeholder
    
    -- Examples of automatic adjustments:
    if mechanicName == "heavy_damage" then
        -- Temporarily prioritize defensive abilities
        self:TemporaryStrategyAdjustment("defensive", 5)
    elseif mechanicName == "movement_required" then
        -- Temporarily prioritize movement abilities
        self:TemporaryStrategyAdjustment("movement", 3)
    elseif mechanicName == "interrupt_required" then
        -- Temporarily prioritize interrupts
        self:TemporaryStrategyAdjustment("interrupt", 2)
    end
}

-- Apply a temporary strategy adjustment
function BossStrategies:TemporaryStrategyAdjustment(adjustmentType, duration)
    -- This would temporarily adjust the current strategy
    -- For implementation simplicity, we'll just log it
    
    API.PrintDebug("Temporary strategy adjustment: " .. adjustmentType .. " for " .. duration .. " seconds")
    
    -- In a real implementation, this would modify the active strategy
    -- or add modifiers to the rotation system
    activeModifiers[adjustmentType] = {
        endTime = GetTime() + duration
    }
    
    -- Create a timer to remove this adjustment
    C_Timer.After(duration, function()
        activeModifiers[adjustmentType] = nil
        API.PrintDebug("Strategy adjustment ended: " .. adjustmentType)
    end)
}

-- Check active mechanics for ongoing effects
function BossStrategies:CheckActiveMechanics()
    if not activeBossID or not currentStrategy then
        return
    end
    
    local settings = ConfigRegistry:GetSettings("BossStrategies")
    if not settings.generalSettings.enableBossStrategies or not settings.generalSettings.enableMechanicDetection then
        return
    end
    
    local now = GetTime()
    local mechanicsToRemove = {}
    
    -- Check each active mechanic
    for mechanicName, data in pairs(detectedMechanics) do
        -- Check if mechanic has expired (e.g., after 10 seconds)
        if now - data.lastDetected > 10 then
            table.insert(mechanicsToRemove, mechanicName)
        end
    end
    
    -- Remove expired mechanics
    for _, mechanicName in ipairs(mechanicsToRemove) do
        detectedMechanics[mechanicName] = nil
        
        -- Log mechanic expiration
        if settings.debugSettings.logMechanicDetection then
            API.PrintDebug("Mechanic expired: " .. mechanicName)
        end
    end
}

-- Check for boss target
function BossStrategies:CheckForBossTarget()
    local settings = ConfigRegistry:GetSettings("BossStrategies")
    if not settings.generalSettings.enableBossStrategies then
        return
    end
    
    -- Skip if already in an encounter
    if activeBossID then
        return
    end
    
    -- Check if detection type allows for target-based detection
    local detectionType = settings.generalSettings.bossDetection
    if detectionType ~= "automatic" and detectionType ~= "boss_only" and detectionType ~= "all_encounters" then
        return
    end
    
    -- Check if target is a boss
    local targetGUID = UnitGUID("target")
    if not targetGUID then
        return
    end
    
    local isBoss = self:IsUnitBoss(targetGUID)
    if not isBoss then
        return
    end
    
    -- Get boss information
    local bossID = self:GetBossIDFromGUID(targetGUID)
    if not bossID then
        return
    end
    
    local boss = bossDatabase[bossID]
    if not boss then
        return
    end
    
    -- Start encounter manually
    self:StartEncounter(bossID, boss.name, 0, 0)
}

-- Check if a unit is a boss
function BossStrategies:IsUnitBoss(unitGUIDOrID)
    if not unitGUIDOrID then
        return false
    end
    
    local unit
    if type(unitGUIDOrID) == "string" and unitGUIDOrID:find("Unit") then
        unit = unitGUIDOrID
    else
        -- Try to find the unit ID from GUID
        if UnitGUID("boss1") == unitGUIDOrID then
            unit = "boss1"
        elseif UnitGUID("boss2") == unitGUIDOrID then
            unit = "boss2"
        elseif UnitGUID("boss3") == unitGUIDOrID then
            unit = "boss3"
        elseif UnitGUID("boss4") == unitGUIDOrID then
            unit = "boss4"
        elseif UnitGUID("boss5") == unitGUIDOrID then
            unit = "boss5"
        end
    end
    
    if not unit then
        -- Check if it's the target and is a boss
        if UnitGUID("target") == unitGUIDOrID then
            unit = "target"
        end
    end
    
    if not unit then
        return false
    end
    
    -- Check classification
    local classification = UnitClassification(unit)
    return classification == "worldboss" or classification == "rareelite" or classification == "elite"
}

-- Get boss ID from unit GUID
function BossStrategies:GetBossIDFromGUID(guid)
    -- This would extract the boss ID from GUID
    -- For implementation simplicity, we'll use a placeholder
    
    -- In a real addon, this would parse the GUID or look up NPC ID
    local possibleBosses = {2564, 2565, 2563, 2688, 2499}
    return possibleBosses[math.random(#possibleBosses)]
}

-- Get unit health percent
function BossStrategies:GetUnitHealthPercent(unitGUIDOrID)
    if not unitGUIDOrID then
        return 100
    end
    
    local unit
    if type(unitGUIDOrID) == "string" and unitGUIDOrID:find("Unit") then
        unit = unitGUIDOrID
    else
        -- Try to find the unit from GUID
        for i = 1, 5 do
            if UnitGUID("boss" .. i) == unitGUIDOrID then
                unit = "boss" .. i
                break
            end
        end
        
        if not unit and UnitGUID("target") == unitGUIDOrID then
            unit = "target"
        end
    end
    
    if not unit then
        return 100
    end
    
    local health = UnitHealth(unit)
    local maxHealth = UnitHealthMax(unit)
    
    if maxHealth <= 0 then
        return 100
    end
    
    return (health / maxHealth) * 100
}

-- Get phase based on spell
function BossStrategies:GetPhaseFromSpell(bossID, sourceName, spellID)
    -- This would identify phase changes based on specific spells
    -- For implementation simplicity, we'll use a placeholder
    
    -- For Gnarlroot
    if bossID == 2564 then
        if spellID == 421898 and currentPhase == 1 then  -- Mock Doom Totem as phase transition
            return 2
        elseif spellID == 422053 and currentPhase == 2 then  -- Mock Withering Roots as phase transition
            return 3
        end
    end
    
    -- For Igira
    if bossID == 2565 then
        if spellID == 414340 and currentPhase ~= 1 then  -- Blistering Torment
            return 1
        elseif spellID == 414770 and currentPhase ~= 3 then  -- Gathering Torment as final phase
            return 3
        end
    end
    
    return nil
}

-- Get phase based on boss health
function BossStrategies:GetPhaseFromHealth(bossID, healthPercent)
    -- This would identify phase changes based on boss health percentage
    -- For implementation simplicity, we'll use a placeholder
    
    -- For Gnarlroot
    if bossID == 2564 then
        if healthPercent <= 60 and currentPhase == 1 then
            return 2
        elseif healthPercent <= 30 and currentPhase == 2 then
            return 3
        end
    end
    
    -- For Igira
    if bossID == 2565 then
        if healthPercent <= 66 and currentPhase == 1 then
            return 2
        elseif healthPercent <= 33 and currentPhase == 2 then
            return 3
        end
    end
    
    -- For Volcoross - single phase
    
    -- For Chrono-Lord Deios
    if bossID == 2499 then
        if healthPercent <= 40 and currentPhase == 1 then
            return 2
        end
    end
    
    return nil
}

-- Check if a spell is a known phase transition
function BossStrategies:IsPhaseTransition(sourceName, spellID)
    -- This would look up if a spell is known to indicate a phase change
    -- For implementation simplicity, we'll use a placeholder
    
    local phaseTransitions = {
        -- Gnarlroot
        [421898] = "Gnarlroot - Intermission",  -- Doom Totem
        [422053] = "Gnarlroot - Phase 2",       -- Withering Roots
        
        -- Igira
        [414340] = "Igira - Blistering Torment Phase",
        [414770] = "Igira - Final Phase"
    }
    
    return phaseTransitions[spellID]
}

-- Detect boss mechanic from spell cast
function BossStrategies:DetectBossMechanic(unit, spellID, castType)
    if not activeBossID or not activeEncounter then
        return
    end
    
    local settings = ConfigRegistry:GetSettings("BossStrategies")
    if not settings.generalSettings.enableBossStrategies or not settings.generalSettings.enableMechanicDetection then
        return
    end
    
    -- Get spell name
    local spellName = GetSpellInfo(spellID)
    
    -- Check if this spell is a known mechanic
    local mechanicName, message = self:GetMechanicFromSpell(spellID, spellName, unit)
    
    if mechanicName then
        self:MechanicDetected(mechanicName, message, spellID)
    end
}

-- Get mechanic from spell
function BossStrategies:GetMechanicFromSpell(spellID, spellName, unit)
    -- This would identify mechanics based on spells
    -- For implementation simplicity, we'll use a placeholder
    
    local mechanicMap = {
        -- Gnarlroot
        [421898] = {"doom_totem", "Doom Totem spawning - prepare to switch targets"},
        [422053] = {"withering_roots", "Withering Roots - break free or dispel"},
        
        -- Igira
        [414340] = {"blistering_torment", "Blistering Torment - spread out"},
        [414770] = {"gathering_torment", "Gathering Torment - use defensive cooldowns"}
    }
    
    if mechanicMap[spellID] then
        return mechanicMap[spellID][1], mechanicMap[spellID][2]
    end
    
    -- Check if it's an interruptible cast
    if self:IsSpellInterruptible(spellID) then
        return "interrupt_required", spellName .. " - interrupt if possible"
    end
    
    return nil
}

-- Check if a spell is interruptible
function BossStrategies:IsSpellInterruptible(spellID)
    -- This would check if a spell is interruptible
    -- For implementation simplicity, we'll use a placeholder
    
    -- In a real addon, this would check the spell flags or use a database
    -- Let's assume 20% of spells are interruptible for simulation
    return math.random(1, 5) == 1
}

-- Detect Mythic+ affixes
function BossStrategies:DetectMythicPlusAffixes()
    -- This would detect current Mythic+ affixes
    -- For implementation simplicity, we'll use a placeholder
    
    -- Check if Tyrannical or Fortified is active
    local isTyrannical = self:IsTyrannicalActive()
    local isFortified = self:IsFortifiedActive()
    
    API.PrintDebug("Mythic+ affixes detected: " .. 
                   (isTyrannical and "Tyrannical" or "") .. 
                   (isFortified and "Fortified" or ""))
    
    -- Update strategies based on affixes
    if isTyrannical then
        -- Prioritize boss-focused strategies
        API.PrintDebug("Using Tyrannical-optimized strategies")
    elseif isFortified then
        -- Prioritize trash-focused strategies
        API.PrintDebug("Using Fortified-optimized strategies")
    end
}

-- Check if Tyrannical affix is active
function BossStrategies:IsTyrannicalActive()
    -- This would check if Tyrannical affix is active
    -- For implementation simplicity, we'll use a placeholder
    
    -- Let's randomly select one for simulation
    return math.random(1, 2) == 1
end

-- Check if Fortified affix is active
function BossStrategies:IsFortifiedActive()
    -- This would check if Fortified affix is active
    -- For implementation simplicity, we'll use a placeholder
    
    -- Opposite of Tyrannical
    return not self:IsTyrannicalActive()
end

-- Register a callback for phase changes
function BossStrategies:RegisterPhaseCallback(callback)
    table.insert(phaseCallbacks, callback)
    return #phaseCallbacks
end

-- Unregister a phase callback
function BossStrategies:UnregisterPhaseCallback(callbackID)
    phaseCallbacks[callbackID] = nil
end

-- Fire phase callbacks
function BossStrategies:FirePhaseCallbacks(oldPhase, newPhase)
    for _, callback in pairs(phaseCallbacks) do
        if type(callback) == "function" then
            callback(oldPhase, newPhase)
        end
    end
end

-- Get the current boss strategy
function BossStrategies:GetCurrentStrategy()
    return currentStrategy
end

-- Get strategy for an ability
function BossStrategies:GetAbilityStrategy(abilityName)
    if not currentStrategy or not currentStrategy.classStrategy then
        return nil
    end
    
    -- Check if this ability has a specific strategy
    local abilities = currentStrategy.classStrategy.abilities
    if not abilities or not abilities[abilityName] then
        return nil
    end
    
    return abilities[abilityName]
}

-- Check if a mechanic is active
function BossStrategies:IsMechanicActive(mechanicName)
    return detectedMechanics[mechanicName] ~= nil
end

-- Get active mechanics
function BossStrategies:GetActiveMechanics()
    return detectedMechanics
end

-- Set a strategy override
function BossStrategies:SetStrategyOverride(bossID, strategyName)
    strategyOverrides[bossID] = strategyName
    
    -- Apply immediately if this is the active boss
    if activeBossID == bossID then
        self:ApplyPhaseStrategy(currentPhase or 1)
    end
}

-- Clear a strategy override
function BossStrategies:ClearStrategyOverride(bossID)
    strategyOverrides[bossID] = nil
    
    -- Apply default strategy if this is the active boss
    if activeBossID == bossID then
        self:ApplyPhaseStrategy(currentPhase or 1)
    end
end

-- Handle slash command
function BossStrategies:HandleSlashCommand(msg)
    if not msg or msg == "" then
        -- Show help
        API.Print("WindrunnerRotations Boss Strategies Commands:")
        API.Print("/wrboss status - Show current boss status")
        API.Print("/wrboss list - List known bosses")
        API.Print("/wrboss strategy [name] - Set strategy override")
        API.Print("/wrboss clear - Clear strategy override")
        API.Print("/wrboss debug - Toggle debug mode")
        return
    end
    
    local args = {}
    for arg in string.gmatch(msg, "%S+") do
        table.insert(args, arg)
    end
    
    local command = args[1]
    
    if command == "status" then
        -- Show boss status
        if activeBossID and activeEncounter then
            API.Print("Current Boss: " .. activeEncounter.name)
            API.Print("Current Phase: " .. currentPhase .. " (" .. activeEncounter.bossData.phases[currentPhase].name .. ")")
            API.Print("Active Strategy: " .. self:GetActiveStrategyName())
            
            API.Print("Active Mechanics:")
            for mechanicName, data in pairs(detectedMechanics) do
                API.Print("  - " .. mechanicName .. " (detected " .. data.count .. " times)")
            end
        else
            API.Print("No active boss encounter")
        end
    elseif command == "list" then
        -- List known bosses
        API.Print("Known Bosses:")
        
        local count = 0
        for id, boss in pairs(bossDatabase) do
            count = count + 1
            API.Print(count .. ". " .. boss.name .. " (ID: " .. id .. ")")
            
            if count >= 5 then
                API.Print("... and " .. (self:CountBosses() - 5) .. " more")
                break
            end
        end
    elseif command == "strategy" then
        -- Set strategy override
        local strategyName = args[2]
        
        if not strategyName then
            API.Print("Please specify a strategy name")
            return
        end
        
        if not activeBossID then
            API.Print("No active boss encounter")
            return
        end
        
        local boss = bossDatabase[activeBossID]
        if not boss or not boss.strategies[strategyName] then
            API.Print("Strategy not found: " .. strategyName)
            return
        end
        
        self:SetStrategyOverride(activeBossID, strategyName)
        API.Print("Strategy override set: " .. strategyName)
    elseif command == "clear" then
        -- Clear strategy override
        if not activeBossID then
            API.Print("No active boss encounter")
            return
        end
        
        self:ClearStrategyOverride(activeBossID)
        API.Print("Strategy override cleared, using default strategy")
    elseif command == "debug" then
        -- Toggle debug mode
        local settings = ConfigRegistry:GetSettings("BossStrategies")
        local newValue = not settings.debugSettings.enableDebugMode
        
        ConfigRegistry:SetSettingValue("BossStrategies", "debugSettings.enableDebugMode", newValue)
        ConfigRegistry:SetSettingValue("BossStrategies", "debugSettings.logMechanicDetection", newValue)
        ConfigRegistry:SetSettingValue("BossStrategies", "debugSettings.logStrategySelection", newValue)
        
        API.Print("Boss strategies debug mode " .. (newValue and "enabled" or "disabled"))
    else
        API.Print("Unknown command. Type /wrboss for help.")
    end
end

-- Return the module for loading
return BossStrategies