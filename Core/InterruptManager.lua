------------------------------------------
-- WindrunnerRotations - Interrupt Manager
-- Author: VortexQ8
-- The War Within Season 2
------------------------------------------

local addonName, WR = ...
local InterruptManager = {}
WR.InterruptManager = InterruptManager

-- Dependencies
local API = WR.API
local ConfigRegistry = WR.ConfigRegistry
local ModuleManager = WR.ModuleManager

-- Data storage
local interruptSpells = {}
local priorityInterrupts = {}
local lastInterruptTime = 0
local interruptHistory = {}
local interruptableSpells = {}
local currentCastsByUnit = {}
local interruptCooldowns = {}
local INTERRUPT_HISTORY_MAX = 50
local activeInterruptors = {}
local interruptTargets = {}
local randomDelayVariance = {}
local failedInterrupts = {}

-- Initialize the Interrupt Manager
function InterruptManager:Initialize()
    -- Register settings
    self:RegisterSettings()
    
    -- Register for events
    self:RegisterEvents()
    
    -- Initialize class-specific interrupt abilities
    self:InitializeInterruptSpells()
    
    -- Load interrupt priorities
    self:LoadInterruptPriorities()
    
    -- Initialize tracking
    self:InitializeTracking()
    
    API.PrintDebug("Interrupt Manager initialized")
    return true
end

-- Register settings for the Interrupt Manager
function InterruptManager:RegisterSettings()
    ConfigRegistry:RegisterSettings("InterruptManager", {
        generalSettings = {
            enableInterrupts = {
                displayName = "Enable Automatic Interrupts",
                description = "Automatically interrupt spellcasting when possible",
                type = "toggle",
                default = true
            },
            interruptMode = {
                displayName = "Interrupt Mode",
                description = "How to prioritize interrupt targets",
                type = "dropdown",
                options = { "all", "priority_only", "focus_target", "whitelist" },
                default = "priority_only"
            },
            interruptDelay = {
                displayName = "Interrupt Delay",
                description = "Delay interrupts by this amount (milliseconds)",
                type = "slider",
                min = 0,
                max = 1000,
                step = 50,
                default = 200
            },
            randomizeDelay = {
                displayName = "Randomize Delay",
                description = "Add random variance to interrupt timing",
                type = "toggle",
                default = true
            },
            delayVariance = {
                displayName = "Delay Variance",
                description = "Maximum random variance to add (milliseconds)",
                type = "slider",
                min = 0,
                max = 500,
                step = 50,
                default = 150
            }
        },
        targetSettings = {
            interruptFocusTarget = {
                displayName = "Always Interrupt Focus Target",
                description = "Always attempt to interrupt your focus target",
                type = "toggle",
                default = true
            },
            interruptTargetPriority = {
                displayName = "Target Interrupt Priority",
                description = "Priority for interrupting targets",
                type = "dropdown",
                options = { "healer_first", "target_first", "lowest_health", "random" },
                default = "healer_first"
            },
            interruptPriorityThreshold = {
                displayName = "Priority Threshold",
                description = "Only interrupt spells with this priority or higher",
                type = "slider",
                min = 1,
                max = 10,
                step = 1,
                default = 5
            }
        },
        partySettings = {
            enablePartyCoordination = {
                displayName = "Enable Party Coordination",
                description = "Coordinate interrupts with party members",
                type = "toggle",
                default = true
            },
            interruptRotation = {
                displayName = "Interrupt Rotation",
                description = "Take turns interrupting in a party",
                type = "toggle",
                default = true
            },
            myInterruptPriority = {
                displayName = "My Interrupt Priority",
                description = "My priority in the interrupt rotation (1 = highest)",
                type = "slider",
                min = 1,
                max = 5,
                step = 1,
                default = 1
            },
            minimumInterruptorCount = {
                displayName = "Minimum Interruptors",
                description = "Only participate in rotation with at least this many interruptors",
                type = "slider",
                min = 1,
                max = 5,
                step = 1,
                default = 2
            }
        },
        pvpSettings = {
            enableInPvP = {
                displayName = "Enable in PvP",
                description = "Enable automatic interrupts in PvP",
                type = "toggle",
                default = true
            },
            pvpInterruptDelay = {
                displayName = "PvP Interrupt Delay",
                description = "Additional delay for PvP interrupts (milliseconds)",
                type = "slider",
                min = 0,
                max = 1000,
                step = 50,
                default = 100
            },
            randomizePvPTarget = {
                displayName = "Randomize PvP Target",
                description = "Randomly choose which enemy player to interrupt",
                type = "toggle",
                default = true
            },
            focusHealerInPvP = {
                displayName = "Focus Healer in PvP",
                description = "Prioritize interrupting healers in PvP",
                type = "toggle",
                default = true
            }
        },
        debugSettings = {
            enableDebugMode = {
                displayName = "Enable Debug Mode",
                description = "Show detailed interrupt information",
                type = "toggle",
                default = false
            },
            announceInterrupts = {
                displayName = "Announce Interrupts",
                description = "Announce successful interrupts in chat",
                type = "dropdown",
                options = { "none", "self", "party", "raid" },
                default = "self"
            },
            trackInterruptStats = {
                displayName = "Track Interrupt Statistics",
                description = "Track statistics about interrupts",
                type = "toggle",
                default = true
            }
        }
    })
end

-- Register for events
function InterruptManager:RegisterEvents()
    -- Register for spell casting events
    API.RegisterEvent("UNIT_SPELLCAST_START", function(unit)
        self:OnUnitSpellcastStart(unit)
    end)
    
    API.RegisterEvent("UNIT_SPELLCAST_STOP", function(unit)
        self:OnUnitSpellcastStop(unit)
    end)
    
    API.RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", function(unit, _, spellID)
        self:OnUnitSpellcastSucceeded(unit, spellID)
    end)
    
    API.RegisterEvent("UNIT_SPELLCAST_INTERRUPTED", function(unit, _, spellID)
        self:OnUnitSpellcastInterrupted(unit, spellID)
    end)
    
    -- Register for combat log events
    API.RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", function()
        self:ProcessCombatLogEvent(CombatLogGetCurrentEventInfo())
    end)
    
    -- Register for focus/target changes
    API.RegisterEvent("PLAYER_FOCUS_CHANGED", function()
        self:OnFocusChanged()
    end)
    
    API.RegisterEvent("PLAYER_TARGET_CHANGED", function()
        self:OnTargetChanged()
    end)
    
    -- Register for group updates
    API.RegisterEvent("GROUP_ROSTER_UPDATE", function()
        self:OnGroupUpdate()
    end)
    
    -- Register for zone changes
    API.RegisterEvent("PLAYER_ENTERING_WORLD", function()
        self:OnZoneChanged()
    end)
    
    API.RegisterEvent("ZONE_CHANGED_NEW_AREA", function()
        self:OnZoneChanged()
    end)
end

-- Initialize class-specific interrupt spells
function InterruptManager:InitializeInterruptSpells()
    -- Clear existing data
    interruptSpells = {}
    
    -- Warrior
    interruptSpells[1] = {
        [1] = {id = 6552, name = "Pummel", cooldown = 15, range = 5}, -- Arms
        [2] = {id = 6552, name = "Pummel", cooldown = 15, range = 5}, -- Fury
        [3] = {id = 6552, name = "Pummel", cooldown = 15, range = 5}  -- Protection
    }
    
    -- Paladin
    interruptSpells[2] = {
        [1] = {id = 96231, name = "Rebuke", cooldown = 15, range = 5}, -- Holy
        [2] = {id = 96231, name = "Rebuke", cooldown = 15, range = 5}, -- Protection
        [3] = {id = 96231, name = "Rebuke", cooldown = 15, range = 5}  -- Retribution
    }
    
    -- Hunter
    interruptSpells[3] = {
        [1] = {id = 147362, name = "Counter Shot", cooldown = 24, range = 40}, -- Beast Mastery
        [2] = {id = 147362, name = "Counter Shot", cooldown = 24, range = 40}, -- Marksmanship
        [3] = {id = 187707, name = "Muzzle", cooldown = 15, range = 5}         -- Survival
    }
    
    -- Rogue
    interruptSpells[4] = {
        [1] = {id = 1766, name = "Kick", cooldown = 15, range = 5}, -- Assassination
        [2] = {id = 1766, name = "Kick", cooldown = 15, range = 5}, -- Outlaw
        [3] = {id = 1766, name = "Kick", cooldown = 15, range = 5}  -- Subtlety
    }
    
    -- Priest
    interruptSpells[5] = {
        [1] = {id = 15487, name = "Silence", cooldown = 45, range = 30}, -- Discipline
        [2] = {id = 15487, name = "Silence", cooldown = 45, range = 30}, -- Holy
        [3] = {id = 15487, name = "Silence", cooldown = 45, range = 30}  -- Shadow
    }
    
    -- Death Knight
    interruptSpells[6] = {
        [1] = {id = 47528, name = "Mind Freeze", cooldown = 15, range = 15}, -- Blood
        [2] = {id = 47528, name = "Mind Freeze", cooldown = 15, range = 15}, -- Frost
        [3] = {id = 47528, name = "Mind Freeze", cooldown = 15, range = 15}  -- Unholy
    }
    
    -- Shaman
    interruptSpells[7] = {
        [1] = {id = 57994, name = "Wind Shear", cooldown = 12, range = 30}, -- Elemental
        [2] = {id = 57994, name = "Wind Shear", cooldown = 12, range = 30}, -- Enhancement
        [3] = {id = 57994, name = "Wind Shear", cooldown = 12, range = 30}  -- Restoration
    }
    
    -- Mage
    interruptSpells[8] = {
        [1] = {id = 2139, name = "Counterspell", cooldown = 24, range = 40}, -- Arcane
        [2] = {id = 2139, name = "Counterspell", cooldown = 24, range = 40}, -- Fire
        [3] = {id = 2139, name = "Counterspell", cooldown = 24, range = 40}  -- Frost
    }
    
    -- Warlock
    interruptSpells[9] = {
        -- Warlocks rely on pet interrupts or Shadowfury stun
        [1] = nil, -- Affliction
        [2] = nil, -- Demonology
        [3] = nil  -- Destruction
    }
    
    -- Monk
    interruptSpells[10] = {
        [1] = {id = 116705, name = "Spear Hand Strike", cooldown = 15, range = 5}, -- Brewmaster
        [2] = {id = 116705, name = "Spear Hand Strike", cooldown = 15, range = 5}, -- Mistweaver
        [3] = {id = 116705, name = "Spear Hand Strike", cooldown = 15, range = 5}  -- Windwalker
    }
    
    -- Druid
    interruptSpells[11] = {
        [1] = {id = 78675, name = "Solar Beam", cooldown = 60, range = 40}, -- Balance
        [2] = {id = 106839, name = "Skull Bash", cooldown = 15, range = 13}, -- Feral
        [3] = {id = 106839, name = "Skull Bash", cooldown = 15, range = 13}, -- Guardian
        [4] = nil -- Restoration
    }
    
    -- Demon Hunter
    interruptSpells[12] = {
        [1] = {id = 183752, name = "Disrupt", cooldown = 15, range = 10}, -- Havoc
        [2] = {id = 183752, name = "Disrupt", cooldown = 15, range = 10}  -- Vengeance
    }
    
    -- Evoker
    interruptSpells[13] = {
        [1] = {id = 351338, name = "Quell", cooldown = 40, range = 25}, -- Devastation
        [2] = {id = 351338, name = "Quell", cooldown = 40, range = 25}, -- Preservation
        [3] = {id = 351338, name = "Quell", cooldown = 40, range = 25}  -- Augmentation
    }
    
    -- Initialize pet interrupts
    self:InitializePetInterrupts()
    
    -- Initialize racial interrupts
    self:InitializeRacialInterrupts()
    
    -- Initialize cooldown tracking
    for classID, classTable in pairs(interruptSpells) do
        for specID, spellData in pairs(classTable) do
            if spellData then
                interruptCooldowns[spellData.id] = 0
            end
        end
    end
}

-- Initialize pet interrupts
function InterruptManager:InitializePetInterrupts()
    -- Pet interrupts
    local petInterrupts = {
        [19647] = {name = "Counterspell", cooldown = 24, pet = "Water Elemental"}, -- Mage Water Elemental
        [171138] = {name = "Shadow Lock", cooldown = 24, pet = "Warlock Pet"}, -- Warlock Doomguard
        [89766] = {name = "Axe Toss", cooldown = 30, pet = "Felguard"}, -- Warlock Felguard
        [115781] = {name = "Optical Blast", cooldown = 24, pet = "Observer"}, -- Warlock Observer
        [347008] = {name = "Spite", cooldown = 45, pet = "Venthyr Pet"} -- Hunter Venthyr Pet
    }
    
    -- Add pet interrupts to the table (we don't know the class in advance, so they're checked at runtime)
    for spellID, data in pairs(petInterrupts) do
        -- Store separately for pet interrupts
        if not interruptSpells.pets then
            interruptSpells.pets = {}
        end
        
        interruptSpells.pets[spellID] = data
        interruptCooldowns[spellID] = 0
    end
}

-- Initialize racial interrupts
function InterruptManager:InitializeRacialInterrupts()
    -- Racial interrupts
    local racialInterrupts = {
        [25046] = {name = "Arcane Torrent", cooldown = 90, race = "BloodElf"} -- Blood Elf Arcane Torrent
    }
    
    -- Add racial interrupts to the table
    for spellID, data in pairs(racialInterrupts) do
        -- Store separately for racial interrupts
        if not interruptSpells.racials then
            interruptSpells.racials = {}
        end
        
        interruptSpells.racials[spellID] = data
        interruptCooldowns[spellID] = 0
    end
}

-- Load interrupt priorities
function InterruptManager:LoadInterruptPriorities()
    -- High priority interrupts (critical spells)
    priorityInterrupts = {
        -- Healing spells (Priority 10 - Highest)
        [47788] = {name = "Guardian Spirit", priority = 10},
        [33206] = {name = "Pain Suppression", priority = 10},
        [64843] = {name = "Divine Hymn", priority = 10},
        [115310] = {name = "Revival", priority = 10},
        [1122] = {name = "Summon Infernal", priority = 10},
        [205180] = {name = "Summon Darkglare", priority = 10},
        [152173] = {name = "Serenity", priority = 10},
        [12472] = {name = "Icy Veins", priority = 10},
        [31884] = {name = "Avenging Wrath", priority = 10},
        [363534] = {name = "Rewind", priority = 10},
        [265187] = {name = "Summon Demonic Tyrant", priority = 10},
        
        -- Important damage spells (Priority 8-9)
        [203286] = {name = "Greater Pyroblast", priority = 9},
        [116858] = {name = "Chaos Bolt", priority = 9},
        [274283] = {name = "Full Moon", priority = 9},
        [274281] = {name = "New Moon", priority = 9},
        [274282] = {name = "Half Moon", priority = 9},
        [113656] = {name = "Fists of Fury", priority = 8},
        [115175] = {name = "Soothing Mist", priority = 8},
        [234153] = {name = "Drain Life", priority = 8},
        [198590] = {name = "Drain Soul", priority = 8},
        [196099] = {name = "Grimoire of Sacrifice", priority = 8},
        
        -- CC/Control spells (Priority 7)
        [20066] = {name = "Repentance", priority = 7},
        [51514] = {name = "Hex", priority = 7},
        [118] = {name = "Polymorph", priority = 7},
        [339] = {name = "Entangling Roots", priority = 7},
        [605] = {name = "Mind Control", priority = 7},
        [8122] = {name = "Psychic Scream", priority = 7},
        [64044] = {name = "Psychic Horror", priority = 7},
        [5782] = {name = "Fear", priority = 7},
        [5484] = {name = "Howl of Terror", priority = 7},
        [6358] = {name = "Seduction", priority = 7},
        
        -- Medium priority damage (Priority 5-6)
        [116011] = {name = "Rune of Power", priority = 6},
        [342938] = {name = "Unstable Affliction", priority = 6},
        [203981] = {name = "Soul Harvest", priority = 6},
        [194327] = {name = "Stormkeeper", priority = 6},
        [204883] = {name = "Circle of Healing", priority = 5},
        [33763] = {name = "Lifebloom", priority = 5},
        [116670] = {name = "Vivify", priority = 5},
        [6789] = {name = "Mortal Coil", priority = 5},
        
        -- Lower priority (Priority 3-4)
        [6358] = {name = "Seduce", priority = 4},
        [31661] = {name = "Dragon's Breath", priority = 4},
        [228260] = {name = "Void Eruption", priority = 4},
        [186723] = {name = "Penance", priority = 3},
        [8936] = {name = "Regrowth", priority = 3},
        [2061] = {name = "Flash Heal", priority = 3},
        [19750] = {name = "Flash of Light", priority = 3},
        
        -- Low priority (Priority 1-2)
        [188389] = {name = "Flame Shock", priority = 2},
        [589] = {name = "Shadow Word: Pain", priority = 2},
        [172] = {name = "Corruption", priority = 2},
        [585] = {name = "Smite", priority = 1},
        [100784] = {name = "Blackout Kick", priority = 1},
        [133] = {name = "Fireball", priority = 1}
    }
    
    -- Extended priorities from dungeon database
    local dungeonPriorities = self:LoadDungeonInterruptPriorities()
    for spellID, data in pairs(dungeonPriorities) do
        if not priorityInterrupts[spellID] then
            priorityInterrupts[spellID] = data
        end
    end
    
    -- Add custom user priorities if any
    -- This would load from SavedVariables in a real addon
}

-- Load dungeon interrupt priorities
function InterruptManager:LoadDungeonInterruptPriorities()
    -- This would be a comprehensive database in a real addon
    -- For implementation simplicity, we'll include a small sample
    
    local dungeonPriorities = {
        -- Dawn of the Infinite - Chronokeeper
        [413619] = {name = "Chronoburst", priority = 9},
        [419398] = {name = "Time Beam", priority = 8},
        [413622] = {name = "Chonofade", priority = 7},
        
        -- Halls of Infusion - Primalist Shockcaster  
        [389441] = {name = "Magnetic Surge", priority = 8},
        [374074] = {name = "Seismic Slam", priority = 7},
        
        -- Neltharus - Scorchling
        [372201] = {name = "Blazing Eruption", priority = 8},
        
        -- Brackenhide Hollow - Claw Fighter
        [367522] = {name = "Hideous Cackle", priority = 8},
        [382392] = {name = "Wither Burst", priority = 9},
        
        -- Generic dungeon priorities
        [377389] = {name = "Choking Rotcloud", priority = 9}, 
        [387564] = {name = "Mystic Blast", priority = 8},
        [392451] = {name = "Flame Shock", priority = 7},
        [375602] = {name = "Raging Ember", priority = 6},
        [387564] = {name = "Overwhelming Energy", priority = 9}
    }
    
    return dungeonPriorities
end

-- Initialize tracking
function InterruptManager:InitializeTracking()
    -- Start a ticker to check for interruptible spells
    C_Timer.NewTicker(0.1, function() 
        self:CheckForInterruptibleSpells()
    end)
}

-- Process a combat log event
function InterruptManager:ProcessCombatLogEvent(...)
    local timestamp, event, _, sourceGUID, sourceName, sourceFlags, _, destGUID, destName, destFlags, _, spellID, spellName = ...
    
    -- Track cooldowns of our interrupts
    if event == "SPELL_CAST_SUCCESS" and sourceGUID == UnitGUID("player") then
        if self:IsInterruptSpell(spellID) then
            local cooldown = self:GetSpellCooldown(spellID)
            interruptCooldowns[spellID] = GetTime() + cooldown
            
            -- Log the interrupt attempt
            self:LogInterruptAttempt(destGUID, destName, spellID, spellName)
        end
    end
    
    -- Track successful interrupts
    if event == "SPELL_INTERRUPT" and sourceGUID == UnitGUID("player") then
        -- Record successful interrupt
        self:LogSuccessfulInterrupt(destGUID, destName, spellID, select(15, ...))
        
        -- Announce the interrupt if enabled
        self:AnnounceInterrupt(destName, select(15, ...))
    end
    
    -- Track spell casts from enemies that could be interrupted
    if event == "SPELL_CAST_START" then
        -- Only track enemy casts
        if bit.band(sourceFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) > 0 then
            local castingSpellID = spellID
            
            -- Store the cast
            if not currentCastsByUnit[sourceGUID] then
                currentCastsByUnit[sourceGUID] = {}
            end
            
            -- Get priority
            local priority = self:GetSpellInterruptPriority(castingSpellID, spellName)
            
            currentCastsByUnit[sourceGUID] = {
                spellID = castingSpellID,
                spellName = spellName,
                startTime = GetTime(),
                endTime = nil, -- Will be calculated based on spell cast time
                priority = priority,
                unit = self:GetUnitFromGUID(sourceGUID)
            }
            
            -- Add to interruptable spells database
            if priority > 0 then
                interruptableSpells[castingSpellID] = {
                    name = spellName,
                    priority = priority
                }
            end
        end
    end
    
    -- Track spell cast ends
    if event == "SPELL_CAST_SUCCESS" or event == "SPELL_CAST_FAILED" or event == "SPELL_CAST_STOP" or event == "SPELL_INTERRUPT" then
        if currentCastsByUnit[sourceGUID] then
            currentCastsByUnit[sourceGUID] = nil
        end
    end
    
    -- Track interrupt cooldowns from party members
    if event == "SPELL_CAST_SUCCESS" and self:IsGroupMember(sourceGUID) and self:IsInterruptSpell(spellID) then
        local cooldown = self:GetSpellCooldown(spellID)
        
        -- Track for party coordination
        if not activeInterruptors[sourceGUID] then
            activeInterruptors[sourceGUID] = {
                name = sourceName,
                lastInterrupt = GetTime(),
                nextAvailable = GetTime() + cooldown,
                spellID = spellID,
                spellName = spellName
            }
        else
            activeInterruptors[sourceGUID].lastInterrupt = GetTime()
            activeInterruptors[sourceGUID].nextAvailable = GetTime() + cooldown
            activeInterruptors[sourceGUID].spellID = spellID
            activeInterruptors[sourceGUID].spellName = spellName
        end
    end
}

-- On unit spellcast start
function InterruptManager:OnUnitSpellcastStart(unit)
    -- Only track visible units
    if not UnitIsVisible(unit) or not UnitCanAttack("player", unit) then
        return
    end
    
    -- Get spell info
    local spellName, _, _, startTime, endTime, _, _, spellID = UnitCastingInfo(unit)
    
    if not spellName or not spellID then
        return
    end
    
    local guid = UnitGUID(unit)
    
    -- Store the cast
    if not currentCastsByUnit[guid] then
        currentCastsByUnit[guid] = {}
    end
    
    -- Get priority
    local priority = self:GetSpellInterruptPriority(spellID, spellName)
    
    -- Convert start/end times from ms to seconds
    startTime = startTime / 1000
    endTime = endTime / 1000
    
    currentCastsByUnit[guid] = {
        spellID = spellID,
        spellName = spellName,
        startTime = startTime,
        endTime = endTime,
        priority = priority,
        unit = unit
    }
    
    -- Check for interrupt
    self:ConsiderInterrupt(guid, unit, spellID, spellName, priority, startTime, endTime)
}

-- On unit spellcast stop
function InterruptManager:OnUnitSpellcastStop(unit)
    local guid = UnitGUID(unit)
    
    if currentCastsByUnit[guid] then
        currentCastsByUnit[guid] = nil
    end
}

-- On unit spellcast succeeded
function InterruptManager:OnUnitSpellcastSucceeded(unit, spellID)
    -- Track player's successful interrupt casts
    if unit == "player" and self:IsInterruptSpell(spellID) then
        local cooldown = self:GetSpellCooldown(spellID)
        interruptCooldowns[spellID] = GetTime() + cooldown
        lastInterruptTime = GetTime()
    end
}

-- On unit spellcast interrupted
function InterruptManager:OnUnitSpellcastInterrupted(unit, spellID)
    local guid = UnitGUID(unit)
    
    if currentCastsByUnit[guid] then
        currentCastsByUnit[guid] = nil
    end
}

-- On focus changed
function InterruptManager:OnFocusChanged()
    -- Update interrupts for new focus target
    if UnitExists("focus") and UnitCanAttack("player", "focus") then
        local settings = ConfigRegistry:GetSettings("InterruptManager")
        
        if settings.targetSettings.interruptFocusTarget then
            -- Check if focus is casting
            local spellName, _, _, startTime, endTime, _, _, spellID = UnitCastingInfo("focus")
            
            if spellName and spellID then
                local guid = UnitGUID("focus")
                local priority = self:GetSpellInterruptPriority(spellID, spellName)
                
                -- Convert start/end times from ms to seconds
                startTime = startTime / 1000
                endTime = endTime / 1000
                
                -- Consider interrupting
                self:ConsiderInterrupt(guid, "focus", spellID, spellName, priority, startTime, endTime)
            end
        end
    end
}

-- On target changed
function InterruptManager:OnTargetChanged()
    -- Update interrupts for new target
    if UnitExists("target") and UnitCanAttack("player", "target") then
        -- Check if target is casting
        local spellName, _, _, startTime, endTime, _, _, spellID = UnitCastingInfo("target")
        
        if spellName and spellID then
            local guid = UnitGUID("target")
            local priority = self:GetSpellInterruptPriority(spellID, spellName)
            
            -- Convert start/end times from ms to seconds
            startTime = startTime / 1000
            endTime = endTime / 1000
            
            -- Consider interrupting
            self:ConsiderInterrupt(guid, "target", spellID, spellName, priority, startTime, endTime)
        end
    end
}

-- On group update
function InterruptManager:OnGroupUpdate()
    -- Refresh active interruptors
    self:RefreshActiveInterruptors()
}

-- On zone changed
function InterruptManager:OnZoneChanged()
    -- Reset tracking when zone changes
    currentCastsByUnit = {}
    activeInterruptors = {}
    
    -- Check for PvP zone
    local inPvP = self:IsInPvPZone()
    
    -- Update settings for PvP
    if inPvP then
        -- We might adjust settings for PvP
    end
}

-- Check for interruptible spells
function InterruptManager:CheckForInterruptibleSpells()
    local settings = ConfigRegistry:GetSettings("InterruptManager")
    if not settings.generalSettings.enableInterrupts then
        return
    end
    
    -- Get current time
    local now = GetTime()
    
    -- Check all tracked casts
    for guid, castInfo in pairs(currentCastsByUnit) do
        -- Skip if already processed
        if castInfo.processed then
            goto continue
        end
        
        -- Calculate remaining cast time
        local remainingTime = castInfo.endTime - now
        
        -- Add delay based on settings
        local delay = settings.generalSettings.interruptDelay / 1000 -- Convert to seconds
        
        -- Add random variance if enabled
        if settings.generalSettings.randomizeDelay then
            if not randomDelayVariance[guid] then
                -- Generate random variance once per cast
                local maxVariance = settings.generalSettings.delayVariance / 1000 -- Convert to seconds
                randomDelayVariance[guid] = math.random() * maxVariance
            end
            
            delay = delay + randomDelayVariance[guid]
        end
        
        -- Check if we should interrupt based on priority and timing
        if remainingTime > 0 and remainingTime <= delay then
            -- Check interrupt mode
            if self:ShouldInterruptTarget(guid, castInfo.unit, castInfo.priority) then
                -- Try to interrupt
                local success = self:AttemptInterrupt(castInfo.unit, guid, castInfo.spellID, castInfo.spellName, castInfo.priority)
                
                -- Mark as processed
                castInfo.processed = true
                
                if success then
                    -- Reset random variance
                    randomDelayVariance[guid] = nil
                end
            end
        end
        
        ::continue::
    end
    
    -- Clean up expired castings
    self:CleanupExpiredCasts()
}

-- Check if we should interrupt this target
function InterruptManager:ShouldInterruptTarget(guid, unit, priority)
    local settings = ConfigRegistry:GetSettings("InterruptManager")
    
    -- Check interrupt mode
    local mode = settings.generalSettings.interruptMode
    
    -- Always interrupt based on threshold
    if priority >= settings.targetSettings.interruptPriorityThreshold then
        return true
    end
    
    -- Check mode-specific logic
    if mode == "all" then
        -- Interrupt everything
        return true
    elseif mode == "priority_only" then
        -- Only interrupt high priority spells (checked above)
        return false
    elseif mode == "focus_target" and unit == "focus" then
        -- Always interrupt focus
        return true
    elseif mode == "whitelist" then
        -- Only on whitelist (not implemented in this version)
        return false
    end
    
    -- Default
    return false
end

-- Clean up expired casts
function InterruptManager:CleanupExpiredCasts()
    local now = GetTime()
    local toRemove = {}
    
    for guid, castInfo in pairs(currentCastsByUnit) do
        if castInfo.endTime < now then
            table.insert(toRemove, guid)
        end
    end
    
    for _, guid in ipairs(toRemove) do
        currentCastsByUnit[guid] = nil
        randomDelayVariance[guid] = nil
    end
}

-- Attempt to interrupt a spell
function InterruptManager:AttemptInterrupt(unit, guid, spellID, spellName, priority)
    local settings = ConfigRegistry:GetSettings("InterruptManager")
    
    -- Skip if interrupts are disabled
    if not settings.generalSettings.enableInterrupts then
        return false
    end
    
    -- Check PvP settings
    local isPvP = self:IsPlayerUnit(guid)
    if isPvP and not settings.pvpSettings.enableInPvP then
        return false
    end
    
    -- Check rotation in party
    if settings.partySettings.enablePartyCoordination and IsInGroup() then
        if settings.partySettings.interruptRotation then
            if not self:IsMyTurnToInterrupt() then
                -- Skip if it's not our turn
                return false
            end
        end
    end
    
    -- Find available interrupt spell
    local interruptSpell = self:GetAvailableInterruptSpell(unit)
    if not interruptSpell then
        return false
    end
    
    -- Log the attempt
    API.PrintDebug("Attempting to interrupt " .. (spellName or "Unknown") .. " with " .. interruptSpell.name)
    
    -- Cast the interrupt
    if interruptSpell.pet then
        -- This would handle pet interrupts
        -- For implementation simplicity, we'll just simulate it
        API.PrintDebug("Commanding pet to interrupt with " .. interruptSpell.name)
    else
        -- Cast the spell
        API.CastSpellByID(interruptSpell.id, unit)
    end
    
    -- Track cooldown
    interruptCooldowns[interruptSpell.id] = GetTime() + interruptSpell.cooldown
    lastInterruptTime = GetTime()
    
    return true
end

-- Get available interrupt spell
function InterruptManager:GetAvailableInterruptSpell(unit)
    -- Get player class and spec
    local classID = API.GetPlayerClassID()
    local specID = API.GetActiveSpecID()
    
    if not classID or not specID then
        return nil
    end
    
    -- Check if we have a class interrupt
    local interruptSpell = nil
    
    if interruptSpells[classID] and interruptSpells[classID][specID] then
        interruptSpell = interruptSpells[classID][specID]
    end
    
    -- Check if it's on cooldown
    if interruptSpell and interruptCooldowns[interruptSpell.id] > GetTime() then
        interruptSpell = nil
    end
    
    -- Check if it's in range
    if interruptSpell and unit and not API.IsSpellInRange(interruptSpell.id, unit) then
        interruptSpell = nil
    end
    
    -- If no class interrupt available, check pet interrupts
    if not interruptSpell and interruptSpells.pets then
        for spellID, data in pairs(interruptSpells.pets) do
            -- Check if we have this pet active
            local hasPet = self:HasActivePet(data.pet)
            
            -- Check if the spell is available
            if hasPet and API.IsSpellKnown(spellID) and interruptCooldowns[spellID] <= GetTime() then
                -- Check range if unit is provided
                if not unit or API.IsSpellInRange(spellID, unit) then
                    interruptSpell = {id = spellID, name = data.name, cooldown = data.cooldown, pet = data.pet}
                    break
                end
            end
        end
    end
    
    -- If still no interrupt, check racial abilities
    if not interruptSpell and interruptSpells.racials then
        local playerRace = select(2, UnitRace("player"))
        
        for spellID, data in pairs(interruptSpells.racials) do
            -- Check if we have this racial
            if data.race == playerRace and API.IsSpellKnown(spellID) and interruptCooldowns[spellID] <= GetTime() then
                -- Check range if unit is provided
                if not unit or API.IsSpellInRange(spellID, unit) then
                    interruptSpell = {id = spellID, name = data.name, cooldown = data.cooldown}
                    break
                end
            end
        end
    end
    
    return interruptSpell
end

-- Refresh active interruptors
function InterruptManager:RefreshActiveInterruptors()
    -- Clear old data
    activeInterruptors = {}
    
    -- Skip if not in group
    if not IsInGroup() then
        return
    end
    
    -- Add ourselves
    local playerGUID = UnitGUID("player")
    local interruptSpell = self:GetAvailableInterruptSpell()
    
    if interruptSpell then
        activeInterruptors[playerGUID] = {
            name = UnitName("player"),
            lastInterrupt = 0,
            nextAvailable = interruptCooldowns[interruptSpell.id] or 0,
            spellID = interruptSpell.id,
            spellName = interruptSpell.name
        }
    end
    
    -- This would scan group members for interrupts
    -- For implementation simplicity, we'll simulate some group members
    local groupSize = GetNumGroupMembers()
    
    if groupSize > 1 then
        -- Simulate other group members with interrupts
        for i = 1, math.min(4, groupSize - 1) do
            local mockGUID = "Player-" .. i
            local mockName = "GroupMember" .. i
            local mockSpellID = 6552 -- Pummel
            local mockSpellName = "Pummel"
            
            activeInterruptors[mockGUID] = {
                name = mockName,
                lastInterrupt = GetTime() - math.random(5, 30),
                nextAvailable = GetTime() + math.random(-5, 15),
                spellID = mockSpellID,
                spellName = mockSpellName
            }
        end
    end
}

-- Check if it's my turn to interrupt
function InterruptManager:IsMyTurnToInterrupt()
    local settings = ConfigRegistry:GetSettings("InterruptManager")
    
    -- Skip rotation if not enough interruptors
    local interruptorCount = 0
    for _ in pairs(activeInterruptors) do
        interruptorCount = interruptorCount + 1
    end
    
    if interruptorCount < settings.partySettings.minimumInterruptorCount then
        return true
    end
    
    -- Sort interruptors by last interrupt time
    local sortedInterruptors = {}
    for guid, data in pairs(activeInterruptors) do
        table.insert(sortedInterruptors, {guid = guid, data = data})
    end
    
    table.sort(sortedInterruptors, function(a, b)
        return a.data.lastInterrupt < b.data.lastInterrupt
    end)
    
    -- Find our position in rotation
    local playerGUID = UnitGUID("player")
    local myPosition = nil
    
    for i, interruptor in ipairs(sortedInterruptors) do
        if interruptor.guid == playerGUID then
            myPosition = i
            break
        end
    end
    
    -- Check if it's our turn
    local myPriority = settings.partySettings.myInterruptPriority
    
    if myPosition and myPosition <= myPriority then
        -- We're one of the preferred interruptors
        return true
    elseif not myPosition then
        -- We're not in the list, take default action
        return true
    else
        -- Check if higher priority interruptors are available
        local higherPriorityAvailable = false
        
        for i = 1, math.min(myPriority, #sortedInterruptors) do
            if i ~= myPosition then
                local interruptor = sortedInterruptors[i]
                if interruptor.data.nextAvailable <= GetTime() then
                    higherPriorityAvailable = true
                    break
                end
            end
        end
        
        -- If no higher priority interruptors are available, it's our turn
        return not higherPriorityAvailable
    end
end

-- Get spell interrupt priority
function InterruptManager:GetSpellInterruptPriority(spellID, spellName)
    -- Check if we know this spell's priority
    if priorityInterrupts[spellID] then
        return priorityInterrupts[spellID].priority
    end
    
    -- Check if we can find it by name (for unknown spellIDs)
    for id, data in pairs(priorityInterrupts) do
        if data.name == spellName then
            -- Add to our database for future reference
            priorityInterrupts[spellID] = {name = spellName, priority = data.priority}
            return data.priority
        end
    end
    
    -- Default priority
    return 1
end

-- Log interrupt attempt
function InterruptManager:LogInterruptAttempt(destGUID, destName, spellID, spellName)
    -- Log the interrupt attempt
    table.insert(interruptHistory, {
        type = "attempt",
        targetGUID = destGUID,
        targetName = destName,
        spellID = spellID,
        spellName = spellName,
        time = GetTime(),
        success = nil -- Will be updated if successful
    })
    
    -- Trim history if needed
    if #interruptHistory > INTERRUPT_HISTORY_MAX then
        table.remove(interruptHistory, 1)
    end
}

-- Log successful interrupt
function InterruptManager:LogSuccessfulInterrupt(destGUID, destName, spellID, interruptedSpell)
    -- Update the most recent attempt to mark as successful
    for i = #interruptHistory, 1, -1 do
        local entry = interruptHistory[i]
        if entry.type == "attempt" and entry.targetGUID == destGUID and entry.success == nil then
            entry.success = true
            entry.interruptedSpell = interruptedSpell
            break
        end
    end
    
    -- Also log as a separate successful event
    table.insert(interruptHistory, {
        type = "success",
        targetGUID = destGUID,
        targetName = destName,
        spellID = spellID,
        interruptedSpell = interruptedSpell,
        time = GetTime()
    })
    
    -- Trim history if needed
    if #interruptHistory > INTERRUPT_HISTORY_MAX then
        table.remove(interruptHistory, 1)
    end
}

-- Announce successful interrupt
function InterruptManager:AnnounceInterrupt(targetName, interruptedSpell)
    local settings = ConfigRegistry:GetSettings("InterruptManager")
    local announceTarget = settings.debugSettings.announceInterrupts
    
    if announceTarget == "none" then
        return
    end
    
    local message = "Interrupted " .. targetName .. "'s " .. interruptedSpell .. "!"
    
    if announceTarget == "self" then
        API.Print(message)
    elseif announceTarget == "party" and IsInGroup() and not IsInRaid() then
        SendChatMessage(message, "PARTY")
    elseif announceTarget == "raid" and IsInRaid() then
        SendChatMessage(message, "RAID")
    end
}

-- Check if a spell is an interrupt spell
function InterruptManager:IsInterruptSpell(spellID)
    -- Check class interrupts
    for classID, classTable in pairs(interruptSpells) do
        for specID, spellData in pairs(classTable) do
            if spellData and spellData.id == spellID then
                return true
            end
        end
    end
    
    -- Check pet interrupts
    if interruptSpells.pets then
        for id, _ in pairs(interruptSpells.pets) do
            if id == spellID then
                return true
            end
        end
    end
    
    -- Check racial interrupts
    if interruptSpells.racials then
        for id, _ in pairs(interruptSpells.racials) do
            if id == spellID then
                return true
            end
        end
    end
    
    return false
end

-- Get spell cooldown
function InterruptManager:GetSpellCooldown(spellID)
    -- Check class interrupts
    for classID, classTable in pairs(interruptSpells) do
        for specID, spellData in pairs(classTable) do
            if spellData and spellData.id == spellID then
                return spellData.cooldown
            end
        end
    end
    
    -- Check pet interrupts
    if interruptSpells.pets and interruptSpells.pets[spellID] then
        return interruptSpells.pets[spellID].cooldown
    end
    
    -- Check racial interrupts
    if interruptSpells.racials and interruptSpells.racials[spellID] then
        return interruptSpells.racials[spellID].cooldown
    end
    
    -- Default fallback
    return 15
end

-- Get unit from GUID
function InterruptManager:GetUnitFromGUID(guid)
    -- Check common units
    if UnitGUID("target") == guid then
        return "target"
    elseif UnitGUID("focus") == guid then
        return "focus"
    elseif UnitGUID("mouseover") == guid then
        return "mouseover"
    end
    
    -- Check party/raid members
    local prefix = IsInRaid() and "raid" or "party"
    local count = IsInRaid() and GetNumGroupMembers() or GetNumGroupMembers() - 1
    
    for i = 1, count do
        if UnitGUID(prefix..i) == guid then
            return prefix..i
        elseif UnitGUID(prefix..i.."target") == guid then
            return prefix..i.."target"
        end
    end
    
    -- Check nameplates
    for i = 1, 40 do
        local unitID = "nameplate"..i
        if UnitExists(unitID) and UnitGUID(unitID) == guid then
            return unitID
        end
    end
    
    return nil
end

-- Check if unit is a group member
function InterruptManager:IsGroupMember(guid)
    -- Check if guid is player
    if UnitGUID("player") == guid then
        return true
    end
    
    -- Check party/raid members
    local prefix = IsInRaid() and "raid" or "party"
    local count = IsInRaid() and GetNumGroupMembers() or GetNumGroupMembers() - 1
    
    for i = 1, count do
        if UnitGUID(prefix..i) == guid then
            return true
        end
    end
    
    return false
end

-- Check if active pet matches
function InterruptManager:HasActivePet(petType)
    -- This would check if the player has an active pet of the specified type
    -- For implementation simplicity, we'll just return true
    return true
end

-- Check if unit is a player
function InterruptManager:IsPlayerUnit(guid)
    -- This would check if the guid belongs to a player
    -- For implementation simplicity, we'll use a basic check
    return guid and guid:find("Player")
end

-- Check if in PvP zone
function InterruptManager:IsInPvPZone()
    -- Check for arena, battleground, or war mode
    local inArena = IsActiveBattlefieldArena()
    local inBattleground = UnitInBattleground("player")
    local warModeEnabled = C_PvP.IsWarModeDesired()
    
    return inArena or inBattleground or warModeEnabled
end

-- Consider interrupting a spell
function InterruptManager:ConsiderInterrupt(guid, unit, spellID, spellName, priority, startTime, endTime)
    local settings = ConfigRegistry:GetSettings("InterruptManager")
    
    -- Skip if interrupts are disabled
    if not settings.generalSettings.enableInterrupts then
        return
    end
    
    -- Check if priority is high enough
    if priority < settings.targetSettings.interruptPriorityThreshold then
        -- If it's a focus target with that option enabled, ignore threshold
        if not (unit == "focus" and settings.targetSettings.interruptFocusTarget) then
            return
        end
    end
    
    -- Check if we should handle this interrupt
    if not self:ShouldInterruptTarget(guid, unit, priority) then
        return
    end
    
    -- Calculate when to interrupt
    local now = GetTime()
    local castRemaining = endTime - now
    
    -- Add delay based on settings
    local delay = settings.generalSettings.interruptDelay / 1000 -- Convert to seconds
    
    -- Add random variance if enabled
    if settings.generalSettings.randomizeDelay then
        if not randomDelayVariance[guid] then
            -- Generate random variance once per cast
            local maxVariance = settings.generalSettings.delayVariance / 1000 -- Convert to seconds
            randomDelayVariance[guid] = math.random() * maxVariance
        end
        
        delay = delay + randomDelayVariance[guid]
    end
    
    -- Add PvP delay if needed
    local isPvP = self:IsPlayerUnit(guid)
    if isPvP and settings.pvpSettings.enableInPvP then
        delay = delay + (settings.pvpSettings.pvpInterruptDelay / 1000)
    end
    
    -- Schedule interrupt
    if castRemaining > delay then
        local interruptTime = endTime - delay
        
        -- Schedule interrupt
        C_Timer.After(interruptTime - now, function()
            -- Check if the unit is still casting the same spell
            if currentCastsByUnit[guid] and currentCastsByUnit[guid].spellID == spellID then
                -- Try to interrupt
                self:AttemptInterrupt(unit, guid, spellID, spellName, priority)
            end
        end)
    else
        -- Try to interrupt immediately
        self:AttemptInterrupt(unit, guid, spellID, spellName, priority)
    end
end

-- Get interrupt stats
function InterruptManager:GetInterruptStats()
    local stats = {
        total = 0,
        successful = 0,
        failed = 0,
        bySpell = {},
        byTarget = {},
        successRate = 0
    }
    
    -- Process history
    for _, entry in ipairs(interruptHistory) do
        if entry.type == "attempt" then
            stats.total = stats.total + 1
            
            if entry.success then
                stats.successful = stats.successful + 1
            elseif entry.success == false then
                stats.failed = stats.failed + 1
            end
            
            -- Count by spell
            if not stats.bySpell[entry.spellID] then
                stats.bySpell[entry.spellID] = {
                    total = 0,
                    successful = 0,
                    failed = 0,
                    name = entry.spellName
                }
            end
            
            stats.bySpell[entry.spellID].total = stats.bySpell[entry.spellID].total + 1
            
            if entry.success then
                stats.bySpell[entry.spellID].successful = stats.bySpell[entry.spellID].successful + 1
            elseif entry.success == false then
                stats.bySpell[entry.spellID].failed = stats.bySpell[entry.spellID].failed + 1
            end
            
            -- Count by target
            if not stats.byTarget[entry.targetGUID] then
                stats.byTarget[entry.targetGUID] = {
                    total = 0,
                    successful = 0,
                    failed = 0,
                    name = entry.targetName
                }
            end
            
            stats.byTarget[entry.targetGUID].total = stats.byTarget[entry.targetGUID].total + 1
            
            if entry.success then
                stats.byTarget[entry.targetGUID].successful = stats.byTarget[entry.targetGUID].successful + 1
            elseif entry.success == false then
                stats.byTarget[entry.targetGUID].failed = stats.byTarget[entry.targetGUID].failed + 1
            end
        end
    end
    
    -- Calculate success rate
    if stats.total > 0 then
        stats.successRate = (stats.successful / stats.total) * 100
    end
    
    return stats
end

-- Return the module for loading
return InterruptManager