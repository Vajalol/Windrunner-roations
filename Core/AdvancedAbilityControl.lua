local addonName, WR = ...

-- AdvancedAbilityControl module for fine-grained control over interrupts, dispels, and CC
local AdvancedAbilityControl = {}
WR.AdvancedAbilityControl = AdvancedAbilityControl

-- Local references for performance
local GetTime = GetTime
local random = math.random
local floor = math.floor
local min = math.min
local max = math.max
local pairs = pairs
local ipairs = ipairs
local tinsert = table.insert
local tremove = table.remove
local string_match = string.match
local string_find = string.find
local string_lower = string.lower
local UnitName = UnitName
local UnitGUID = UnitGUID
local UnitIsUnit = UnitIsUnit
local UnitCreatureType = UnitCreatureType
local GetSpellInfo = GetSpellInfo
local UnitIsPlayer = UnitIsPlayer
local IsInInstance = IsInInstance
local IsInRaid = IsInRaid
local IsInGroup = IsInGroup

-- Module constants
local ABILITY_TYPES = {
    INTERRUPT = "interrupt",
    DISPEL = "dispel",
    CC = "cc",
    DEFENSIVE = "defensive",
    OFFENSIVE = "offensive",
    UTILITY = "utility"
}

local TIMING_MODES = {
    INSTANT = "instant",
    HUMAN = "human",
    RANDOM = "random",
    VARIABLE = "variable",
    PERCENTAGE = "percentage"
}

local CC_TYPES = {
    STUN = "stun",
    ROOT = "root",
    SILENCE = "silence",
    INCAPACITATE = "incapacitate",
    DISORIENT = "disorient",
    FEAR = "fear",
    SLEEP = "sleep",
    CYCLONE = "cyclone",
    BANISH = "banish",
    HORROR = "horror",
    TAUNT = "taunt"
}

local DISPEL_TYPES = {
    MAGIC = "Magic",
    CURSE = "Curse",
    DISEASE = "Disease",
    POISON = "Poison",
    ENRAGE = "Enrage"
}

local INSTANCE_TYPES = {
    WORLD = "world",
    DUNGEON = "dungeon",
    RAID = "raid",
    PVP = "pvp",
    SCENARIO = "scenario"
}

local PRIORITY_LEVELS = {
    IGNORED = 0,
    LOW = 1,
    MEDIUM = 2,
    HIGH = 3,
    CRITICAL = 4
}

local DR_CATEGORIES = {
    STUN = "stun",
    INCAPACITATE = "incapacitate",
    SILENCE = "silence",
    DISORIENT = "disorient",
    FEAR = "fear",
    HORROR = "horror",
    ROOT = "root",
    CYCLONE = "cyclone",
    MIND_CONTROL = "mind_control",
    TAUNT = "taunt"
}

-- Database of important spell IDs that should always be interrupted
local IMPORTANT_INTERRUPT_SPELLS = {
    -- Healing spells
    [2060] = true,   -- Heal
    [2061] = true,   -- Flash Heal
    [8936] = true,   -- Regrowth
    [596] = true,    -- Prayer of Healing
    [116670] = true, -- Vivify
    [227344] = true, -- Surging Mist
    
    -- CC spells
    [118] = true,    -- Polymorph
    [51514] = true,  -- Hex
    [20066] = true,  -- Repentance
    [605] = true,    -- Mind Control
    
    -- Big damage spells
    [116858] = true, -- Chaos Bolt
    [48181] = true,  -- Haunt
    [203286] = true, -- Greater Pyroblast
    
    -- Dangerous dungeon/raid spells
    -- These would be populated based on current content
}

-- Database of dangerous debuffs that should be dispelled immediately
local DANGEROUS_DISPEL_DEBUFFS = {
    -- Dungeon/Raid debuffs
    [105479] = true, -- Corrupted Blood (Example)
    [108220] = true, -- Deep Corruption (Example)
    
    -- PvP dangerous debuffs
    [33786] = true,  -- Cyclone
    [118699] = true, -- Fear
    [51514] = true,  -- Hex
    
    -- Dungeon specific
    [38064] = true,  -- Explosive Growth
    [30129] = true,  -- Charred Earth
}

-- Database of dispels that should be avoided
local DISPEL_BLACKLIST = {
    [34914] = true,  -- Vampiric Touch (spreads Shadow Word: Pain when dispelled)
    [17877] = true,  -- Unstable Affliction (deals damage when dispelled)
    [30108] = true,  -- Unstable Affliction (deals damage when dispelled)
}

-- Module state variables
local settings = {}
local abilityRegistry = {}
local exclusionLists = {}
local inclusionLists = {}
local encounterRules = {}
local playerBlacklist = {}
local pendingActions = {}
local customDelays = {}
local lastInterruptTimes = {}
local lastDispelTimes = {}
local lastCCTimes = {}
local activeInstanceType = INSTANCE_TYPES.WORLD
local activeDungeonID = nil
local activeRaidID = nil
local activeEncounterID = nil
local lastRandomSeed = 0
local debugMode = false

-- Default settings
local defaultSettings = {
    enabled = true,
    debugMode = false,
    
    -- Global settings
    global = {
        interrupts = {
            enabled = true,
            timingMode = TIMING_MODES.HUMAN,
            minDelay = 0.2,
            maxDelay = 0.8,
            targetPercentage = 70, -- Interrupt at this percentage of cast
            ignoreUnknownSpells = false,
            saveForPriority = true, -- Save interrupt for high priority spells
            rotateWithParty = true, -- Coordinate with party members
            prioritizeCasters = true, -- Focus on interrupting casters first
            prioritizeLockouts = true, -- Prioritize interrupts that lock spell schools
            allowMovingToInterrupt = true, -- Move into range to interrupt if needed
            priorityThreshold = PRIORITY_LEVELS.MEDIUM, -- Minimum priority to interrupt
        },
        
        dispels = {
            enabled = true,
            timingMode = TIMING_MODES.HUMAN,
            minDelay = 0.2,
            maxDelay = 0.6,
            priorityThreshold = PRIORITY_LEVELS.MEDIUM,
            safetyHealthThreshold = 0.4, -- Don't dispel if target below this % health
            minDebuffDuration = 2.0, -- Don't dispel if less than this duration remains
            stackThreshold = 1, -- Dispel at this many stacks or higher
            typePriorities = {
                [DISPEL_TYPES.MAGIC] = PRIORITY_LEVELS.MEDIUM,
                [DISPEL_TYPES.CURSE] = PRIORITY_LEVELS.MEDIUM,
                [DISPEL_TYPES.DISEASE] = PRIORITY_LEVELS.MEDIUM,
                [DISPEL_TYPES.POISON] = PRIORITY_LEVELS.MEDIUM,
                [DISPEL_TYPES.ENRAGE] = PRIORITY_LEVELS.LOW
            },
            allowExpensiveDispels = true, -- Use high-cost dispels (Mass Dispel, etc.)
            healerPriority = true, -- Let healers handle dispels when possible
            autoDispelOnSelf = true, -- Automatic dispel on self
        },
        
        crowdControl = {
            enabled = true,
            timingMode = TIMING_MODES.HUMAN,
            minDelay = 0.3,
            maxDelay = 0.9,
            priorityThreshold = PRIORITY_LEVELS.MEDIUM,
            avoidDiminishingReturns = true,
            enabledTypes = {
                [CC_TYPES.STUN] = true,
                [CC_TYPES.ROOT] = true,
                [CC_TYPES.SILENCE] = true,
                [CC_TYPES.INCAPACITATE] = true,
                [CC_TYPES.DISORIENT] = true,
                [CC_TYPES.FEAR] = true,
                [CC_TYPES.SLEEP] = true,
                [CC_TYPES.CYCLONE] = true,
                [CC_TYPES.BANISH] = true,
                [CC_TYPES.HORROR] = true,
                [CC_TYPES.TAUNT] = false -- Default off for tanks to control
            },
            chainCC = true, -- Try to chain CC with party members
            breakOnDamage = true, -- Break CC if target takes too much damage
            ccPriorityTargets = true, -- CC healing/dangerous targets first
        }
    },
    
    -- Class-specific overrides
    classes = {},
    
    -- Ability-specific settings
    abilities = {},
    
    -- Spell exclusion/inclusion lists
    spellLists = {
        interrupts = {
            alwaysInclude = {},
            alwaysExclude = {}
        },
        dispels = {
            alwaysInclude = {},
            alwaysExclude = {}
        },
        crowdControl = {
            alwaysInclude = {},
            alwaysExclude = {}
        }
    },
    
    -- Special encounter rules
    encounters = {},
    
    -- Logging and history
    tracking = {
        enabled = true,
        trackSuccessRate = true,
        trackTimingDistribution = true,
        maxHistoryEntries = 100,
        autoAdjustPriorities = true
    }
}

-- Initialize the module
function AdvancedAbilityControl:Initialize()
    -- Load settings
    self:LoadSettings()
    
    -- Initialize registry with player abilities
    self:ScanPlayerAbilities()
    
    -- Register events
    self:RegisterEvents()
    
    -- Register with main addon
    self:RegisterWithAddon()
    
    -- Initialize random seed
    lastRandomSeed = floor(GetTime() * 1000)
    
    -- Debug
    debugMode = settings.debugMode
    if debugMode then
        self:Debug("AdvancedAbilityControl initialized")
    end
}

-- Load settings
function AdvancedAbilityControl:LoadSettings()
    if WindrunnerRotationsDB and WindrunnerRotationsDB.AdvancedAbilityControl then
        -- Load existing settings
        settings = WindrunnerRotationsDB.AdvancedAbilityControl
        
        -- Ensure all fields exist by populating missing ones from defaults
        settings = self:EnsureDefaults(settings, defaultSettings)
    else
        -- Initialize with defaults
        settings = self:DeepCopy(defaultSettings)
    end
    
    -- Initialize exclusion and inclusion lists
    exclusionLists = {
        interrupts = {},
        dispels = {},
        crowdControl = {}
    }
    
    inclusionLists = {
        interrupts = {},
        dispels = {},
        crowdControl = {}
    }
    
    -- Populate from settings
    for spellID, _ in pairs(settings.spellLists.interrupts.alwaysExclude) do
        exclusionLists.interrupts[tonumber(spellID)] = true
    end
    
    for spellID, _ in pairs(settings.spellLists.dispels.alwaysExclude) do
        exclusionLists.dispels[tonumber(spellID)] = true
    end
    
    for spellID, _ in pairs(settings.spellLists.crowdControl.alwaysExclude) do
        exclusionLists.crowdControl[tonumber(spellID)] = true
    end
    
    for spellID, _ in pairs(settings.spellLists.interrupts.alwaysInclude) do
        inclusionLists.interrupts[tonumber(spellID)] = true
    end
    
    for spellID, _ in pairs(settings.spellLists.dispels.alwaysInclude) do
        inclusionLists.dispels[tonumber(spellID)] = true
    end
    
    for spellID, _ in pairs(settings.spellLists.crowdControl.alwaysInclude) do
        inclusionLists.crowdControl[tonumber(spellID)] = true
    end
}

-- Save settings
function AdvancedAbilityControl:SaveSettings()
    -- Ensure DB exists
    if not WindrunnerRotationsDB then
        WindrunnerRotationsDB = {}
    end
    
    -- Save settings
    WindrunnerRotationsDB.AdvancedAbilityControl = settings
    
    if debugMode then
        self:Debug("Settings saved")
    end
}

-- Register events
function AdvancedAbilityControl:RegisterEvents()
    -- Create event frame
    local eventFrame = CreateFrame("Frame")
    
    -- Register for events
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_START")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_STOP")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
    eventFrame:RegisterEvent("UNIT_AURA")
    eventFrame:RegisterEvent("ENCOUNTER_START")
    eventFrame:RegisterEvent("ENCOUNTER_END")
    eventFrame:RegisterEvent("CHALLENGE_MODE_START")
    eventFrame:RegisterEvent("CHALLENGE_MODE_COMPLETED")
    eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    
    -- Set up event handler
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "PLAYER_ENTERING_WORLD" then
            AdvancedAbilityControl:OnEnteringWorld()
        elseif event == "PLAYER_TALENT_UPDATE" then
            AdvancedAbilityControl:ScanPlayerAbilities()
        elseif event == "UNIT_SPELLCAST_START" then
            AdvancedAbilityControl:OnUnitSpellcastStart(...)
        elseif event == "UNIT_SPELLCAST_STOP" then
            AdvancedAbilityControl:OnUnitSpellcastStop(...)
        elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
            AdvancedAbilityControl:OnUnitSpellcastSucceeded(...)
        elseif event == "UNIT_SPELLCAST_INTERRUPTED" then
            AdvancedAbilityControl:OnUnitSpellcastInterrupted(...)
        elseif event == "UNIT_AURA" then
            AdvancedAbilityControl:OnUnitAura(...)
        elseif event == "ENCOUNTER_START" then
            AdvancedAbilityControl:OnEncounterStart(...)
        elseif event == "ENCOUNTER_END" then
            AdvancedAbilityControl:OnEncounterEnd(...)
        elseif event == "CHALLENGE_MODE_START" then
            AdvancedAbilityControl:OnMythicPlusStart(...)
        elseif event == "CHALLENGE_MODE_COMPLETED" then
            AdvancedAbilityControl:OnMythicPlusCompleted(...)
        elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
            AdvancedAbilityControl:OnCombatLogEvent(CombatLogGetCurrentEventInfo())
        end
    end)
    
    -- Set up OnUpdate for timing and processing
    eventFrame:SetScript("OnUpdate", function(self, elapsed)
        AdvancedAbilityControl:OnUpdate(elapsed)
    end)
    
    -- Store reference
    self.eventFrame = eventFrame
}

-- Register with main addon
function AdvancedAbilityControl:RegisterWithAddon()
    -- Add to UI settings panel
    if WR.UI and WR.UI.AdvancedSettingsUI then
        WR.UI.AdvancedSettingsUI:AddPanel("Ability Control", function(panel)
            self:CreateSettingsUI(panel)
        end)
    end
    
    -- Register slash command (alternative to the main slash command handler in Init.lua)
    WR.RegisterSlashCommand = WR.RegisterSlashCommand or function(command, handler)
        -- Mock implementation if the real one doesn't exist
        _G["SLASH_WINDRUNNER_" .. command:upper() .. "1"] = "/wr_" .. command
        SlashCmdList["WINDRUNNER_" .. command:upper()] = handler
    end
    
    WR.RegisterSlashCommand("abilitycontrol", function(msg)
        self:HandleSlashCommand(msg)
    end)
    
    WR.RegisterSlashCommand("ac", function(msg)
        self:HandleSlashCommand(msg)
    end)
}

-- Scan player abilities
function AdvancedAbilityControl:ScanPlayerAbilities()
    -- Clear previous registry
    abilityRegistry = {
        interrupts = {},
        dispels = {},
        crowdControl = {}
    }
    
    -- Get player class and spec info
    local _, playerClass = UnitClass("player")
    local currentSpec = GetSpecialization()
    local currentSpecID = currentSpec and GetSpecializationInfo(currentSpec) or nil
    
    -- Scan abilities based on class/spec
    self:ScanInterrupts(playerClass, currentSpecID)
    self:ScanDispels(playerClass, currentSpecID)
    self:ScanCrowdControl(playerClass, currentSpecID)
    
    if debugMode then
        self:Debug("Player abilities scanned")
        self:Debug("Found " .. #abilityRegistry.interrupts .. " interrupts")
        self:Debug("Found " .. #abilityRegistry.dispels .. " dispels")
        self:Debug("Found " .. #abilityRegistry.crowdControl .. " crowd control abilities")
    end
}

-- Scan interrupt abilities
function AdvancedAbilityControl:ScanInterrupts(class, specID)
    -- Class-specific interrupts
    local interrupts = {
        -- Death Knight
        DEATHKNIGHT = {
            {spellId = 47528, name = "Mind Freeze", range = 15, cooldown = 15, castTime = 0, school = "physical"},
            {spellId = 91802, name = "Shambling Rush", range = 8, cooldown = 30, castTime = 0, school = "shadow"},
        },
        -- Demon Hunter
        DEMONHUNTER = {
            {spellId = 183752, name = "Disrupt", range = 10, cooldown = 15, castTime = 0, school = "physical"},
            {spellId = 217832, name = "Imprison", range = 20, cooldown = 45, castTime = 1.5, school = "shadow"},
        },
        -- Druid
        DRUID = {
            {spellId = 93985, name = "Skull Bash", range = 13, cooldown = 15, castTime = 0, school = "physical"},
            {spellId = 2637, name = "Hibernate", range = 30, cooldown = 0, castTime = 1.5, school = "nature"},
            {spellId = 78675, name = "Solar Beam", range = 40, cooldown = 60, castTime = 0, school = "nature"},
        },
        -- Evoker
        EVOKER = {
            {spellId = 351338, name = "Quell", range = 25, cooldown = 15, castTime = 0, school = "arcane"},
        },
        -- Hunter
        HUNTER = {
            {spellId = 147362, name = "Counter Shot", range = 40, cooldown = 24, castTime = 0, school = "physical"},
            {spellId = 187707, name = "Muzzle", range = 5, cooldown = 15, castTime = 0, school = "physical"},
        },
        -- Mage
        MAGE = {
            {spellId = 2139, name = "Counterspell", range = 40, cooldown = 24, castTime = 0, school = "arcane"},
        },
        -- Monk
        MONK = {
            {spellId = 116705, name = "Spear Hand Strike", range = 5, cooldown = 15, castTime = 0, school = "physical"},
            {spellId = 119381, name = "Leg Sweep", range = 5, cooldown = 60, castTime = 0, school = "physical"},
        },
        -- Paladin
        PALADIN = {
            {spellId = 96231, name = "Rebuke", range = 5, cooldown = 15, castTime = 0, school = "holy"},
            {spellId = 31935, name = "Avenger's Shield", range = 30, cooldown = 15, castTime = 0, school = "holy"},
        },
        -- Priest
        PRIEST = {
            {spellId = 15487, name = "Silence", range = 30, cooldown = 45, castTime = 0, school = "shadow"},
            {spellId = 64044, name = "Psychic Horror", range = 30, cooldown = 45, castTime = 0, school = "shadow"},
        },
        -- Rogue
        ROGUE = {
            {spellId = 1766, name = "Kick", range = 5, cooldown = 15, castTime = 0, school = "physical"},
            {spellId = 1833, name = "Cheap Shot", range = 5, cooldown = 0, castTime = 0, school = "physical"},
        },
        -- Shaman
        SHAMAN = {
            {spellId = 57994, name = "Wind Shear", range = 30, cooldown = 12, castTime = 0, school = "nature"},
            {spellId = 51514, name = "Hex", range = 30, cooldown = 30, castTime = 1.5, school = "nature"},
        },
        -- Warlock
        WARLOCK = {
            {spellId = 119910, name = "Spell Lock", range = 40, cooldown = 24, castTime = 0, school = "shadow"},
            {spellId = 19647, name = "Felhunter - Spell Lock", range = 40, cooldown = 24, castTime = 0, school = "shadow"},
            {spellId = 212619, name = "Call Felhunter", range = 40, cooldown = 24, castTime = 0, school = "shadow"},
            {spellId = 5484, name = "Howl of Terror", range = 10, cooldown = 40, castTime = 0, school = "shadow"},
        },
        -- Warrior
        WARRIOR = {
            {spellId = 6552, name = "Pummel", range = 5, cooldown = 15, castTime = 0, school = "physical"},
            {spellId = 5246, name = "Intimidating Shout", range = 8, cooldown = 90, castTime = 0, school = "physical"},
        },
    }
    
    -- Check if player has these spells
    if interrupts[class] then
        for _, interrupt in ipairs(interrupts[class]) do
            local name, _, icon = GetSpellInfo(interrupt.spellId)
            if name then
                -- Check if player has this spell
                if IsSpellKnown(interrupt.spellId) or IsPlayerSpell(interrupt.spellId) then
                    -- Add to registry
                    tinsert(abilityRegistry.interrupts, {
                        id = interrupt.spellId,
                        name = name,
                        icon = icon,
                        range = interrupt.range,
                        cooldown = interrupt.cooldown,
                        castTime = interrupt.castTime,
                        school = interrupt.school,
                        isMainInterrupt = (interrupt.cooldown <= 24), -- Main interrupts have shorter cooldowns
                        isPriority = false, -- Will be calculated during combat
                        lastUseTime = 0,
                        successRate = 100, -- Start with perfect success rate
                        totalUses = 0,
                        successfulUses = 0
                    })
                end
            end
        end
    end
}

-- Scan dispel abilities
function AdvancedAbilityControl:ScanDispels(class, specID)
    -- Class-specific dispels
    local dispels = {
        -- Death Knight - No normal dispels
        DEATHKNIGHT = {},
        
        -- Demon Hunter - Can dispel magic on self only (Consume Magic)
        DEMONHUNTER = {
            {spellId = 278326, name = "Consume Magic", types = {DISPEL_TYPES.MAGIC}, targetType = "self", cooldown = 10},
        },
        
        -- Druid
        DRUID = {
            {spellId = 2782, name = "Remove Corruption", types = {DISPEL_TYPES.CURSE, DISPEL_TYPES.POISON}, targetType = "friendly", cooldown = 8},
            {spellId = 88423, name = "Nature's Cure", types = {DISPEL_TYPES.CURSE, DISPEL_TYPES.POISON, DISPEL_TYPES.MAGIC}, targetType = "friendly", cooldown = 8, specID = 105}, -- Restoration
        },
        
        -- Evoker
        EVOKER = {
            {spellId = 365585, name = "Expunge", types = {DISPEL_TYPES.POISON, DISPEL_TYPES.DISEASE}, targetType = "friendly", cooldown = 8},
            {spellId = 374251, name = "Cauterizing Flame", types = {DISPEL_TYPES.CURSE, DISPEL_TYPES.DISEASE, DISPEL_TYPES.POISON}, targetType = "any", cooldown = 30},
            {spellId = 360823, name = "Naturalize", types = {DISPEL_TYPES.POISON, DISPEL_TYPES.DISEASE, DISPEL_TYPES.MAGIC}, targetType = "friendly", cooldown = 8, specID = 1468}, -- Preservation
        },
        
        -- Hunter - No normal dispels (Tranquilizing Shot for enrages)
        HUNTER = {
            {spellId = 19801, name = "Tranquilizing Shot", types = {DISPEL_TYPES.ENRAGE}, targetType = "harmful", cooldown = 10},
        },
        
        -- Mage
        MAGE = {
            {spellId = 30449, name = "Spellsteal", types = {DISPEL_TYPES.MAGIC}, targetType = "harmful", cooldown = 0},
            {spellId = 475, name = "Remove Curse", types = {DISPEL_TYPES.CURSE}, targetType = "friendly", cooldown = 8},
        },
        
        -- Monk
        MONK = {
            {spellId = 115450, name = "Detox", types = {DISPEL_TYPES.POISON, DISPEL_TYPES.DISEASE}, targetType = "friendly", cooldown = 8},
            {spellId = 115451, name = "Detox", types = {DISPEL_TYPES.POISON, DISPEL_TYPES.DISEASE, DISPEL_TYPES.MAGIC}, targetType = "friendly", cooldown = 8, specID = 270}, -- Mistweaver
        },
        
        -- Paladin
        PALADIN = {
            {spellId = 213644, name = "Cleanse Toxins", types = {DISPEL_TYPES.POISON, DISPEL_TYPES.DISEASE}, targetType = "friendly", cooldown = 8},
            {spellId = 4987, name = "Cleanse", types = {DISPEL_TYPES.POISON, DISPEL_TYPES.DISEASE, DISPEL_TYPES.MAGIC}, targetType = "friendly", cooldown = 8, specID = 65}, -- Holy
        },
        
        -- Priest
        PRIEST = {
            {spellId = 527, name = "Purify", types = {DISPEL_TYPES.DISEASE, DISPEL_TYPES.MAGIC}, targetType = "friendly", cooldown = 8, specID = 256}, -- Discipline
            {spellId = 527, name = "Purify", types = {DISPEL_TYPES.DISEASE, DISPEL_TYPES.MAGIC}, targetType = "friendly", cooldown = 8, specID = 257}, -- Holy
            {spellId = 213634, name = "Purify Disease", types = {DISPEL_TYPES.DISEASE}, targetType = "friendly", cooldown = 8},
            {spellId = 32375, name = "Mass Dispel", types = {DISPEL_TYPES.MAGIC}, targetType = "any", cooldown = 45},
            {spellId = 528, name = "Dispel Magic", types = {DISPEL_TYPES.MAGIC}, targetType = "harmful", cooldown = 0, specID = 257}, -- Holy
            {spellId = 528, name = "Dispel Magic", types = {DISPEL_TYPES.MAGIC}, targetType = "harmful", cooldown = 0, specID = 256}, -- Discipline
        },
        
        -- Rogue - No normal dispels
        ROGUE = {},
        
        -- Shaman
        SHAMAN = {
            {spellId = 51886, name = "Cleanse Spirit", types = {DISPEL_TYPES.CURSE}, targetType = "friendly", cooldown = 8},
            {spellId = 77130, name = "Purify Spirit", types = {DISPEL_TYPES.CURSE, DISPEL_TYPES.MAGIC}, targetType = "friendly", cooldown = 8, specID = 264}, -- Restoration
        },
        
        -- Warlock - No normal dispels (can remove magic with Devour Magic with Felhunter)
        WARLOCK = {
            {spellId = 19505, name = "Devour Magic", types = {DISPEL_TYPES.MAGIC}, targetType = "any", cooldown = 15, petRequired = "Felhunter"},
        },
        
        -- Warrior - No normal dispels
        WARRIOR = {},
    }
    
    -- Check if player has these spells
    if dispels[class] then
        for _, dispel in ipairs(dispels[class]) do
            -- Skip if this requires a specific spec and player isn't that spec
            if dispel.specID and dispel.specID ~= specID then
                -- Skip this dispel as it's not usable in current spec
            else
                local name, _, icon = GetSpellInfo(dispel.spellId)
                if name then
                    -- Check if player has this spell
                    if IsSpellKnown(dispel.spellId) or IsPlayerSpell(dispel.spellId) then
                        -- Add to registry
                        tinsert(abilityRegistry.dispels, {
                            id = dispel.spellId,
                            name = name,
                            icon = icon,
                            types = dispel.types,
                            targetType = dispel.targetType,
                            cooldown = dispel.cooldown,
                            petRequired = dispel.petRequired,
                            isMainDispel = (dispel.cooldown <= 8 and #dispel.types >= 2), -- Main dispels have short cooldowns
                            lastUseTime = 0,
                            successRate = 100, -- Start with perfect success rate
                            totalUses = 0,
                            successfulUses = 0
                        })
                    end
                end
            end
        end
    end
}

-- Scan crowd control abilities
function AdvancedAbilityControl:ScanCrowdControl(class, specID)
    -- Class-specific crowd control abilities
    local crowdControls = {
        -- Death Knight
        DEATHKNIGHT = {
            {spellId = 108194, name = "Asphyxiate", type = CC_TYPES.STUN, range = 20, cooldown = 45, castTime = 0, school = "shadow", drCategory = DR_CATEGORIES.STUN},
            {spellId = 207167, name = "Blinding Sleet", type = CC_TYPES.DISORIENT, range = 12, cooldown = 60, castTime = 0, school = "frost", drCategory = DR_CATEGORIES.DISORIENT},
            {spellId = 221562, name = "Asphyxiate", type = CC_TYPES.STUN, range = 20, cooldown = 45, castTime = 0, school = "shadow", drCategory = DR_CATEGORIES.STUN},
            {spellId = 56222, name = "Dark Command", type = CC_TYPES.TAUNT, range = 30, cooldown = 8, castTime = 0, school = "shadow", drCategory = DR_CATEGORIES.TAUNT},
        },
        
        -- Demon Hunter
        DEMONHUNTER = {
            {spellId = 179057, name = "Chaos Nova", type = CC_TYPES.STUN, range = 8, cooldown = 60, castTime = 0, school = "shadow", drCategory = DR_CATEGORIES.STUN},
            {spellId = 217832, name = "Imprison", type = CC_TYPES.INCAPACITATE, range = 20, cooldown = 45, castTime = 1.5, school = "shadow", drCategory = DR_CATEGORIES.INCAPACITATE},
            {spellId = 211881, name = "Fel Eruption", type = CC_TYPES.STUN, range = 30, cooldown = 30, castTime = 0, school = "shadow", drCategory = DR_CATEGORIES.STUN},
            {spellId = 185245, name = "Torment", type = CC_TYPES.TAUNT, range = 30, cooldown = 8, castTime = 0, school = "shadow", drCategory = DR_CATEGORIES.TAUNT},
        },
        
        -- Druid
        DRUID = {
            {spellId = 33786, name = "Cyclone", type = CC_TYPES.INCAPACITATE, range = 20, cooldown = 0, castTime = 1.5, school = "nature", drCategory = DR_CATEGORIES.CYCLONE},
            {spellId = 5211, name = "Mighty Bash", type = CC_TYPES.STUN, range = 5, cooldown = 50, castTime = 0, school = "physical", drCategory = DR_CATEGORIES.STUN},
            {spellId = 339, name = "Entangling Roots", type = CC_TYPES.ROOT, range = 30, cooldown = 0, castTime = 1.5, school = "nature", drCategory = DR_CATEGORIES.ROOT},
            {spellId = 2637, name = "Hibernate", type = CC_TYPES.SLEEP, range = 30, cooldown = 0, castTime = 1.5, school = "nature", drCategory = DR_CATEGORIES.SLEEP},
            {spellId = 6795, name = "Growl", type = CC_TYPES.TAUNT, range = 30, cooldown = 8, castTime = 0, school = "physical", drCategory = DR_CATEGORIES.TAUNT},
        },
        
        -- Evoker
        EVOKER = {
            {spellId = 360806, name = "Sleep Walk", type = CC_TYPES.SLEEP, range = 30, cooldown = 60, castTime = 1.5, school = "nature", drCategory = DR_CATEGORIES.SLEEP},
            {spellId = 204273, name = "Breath of Eons", type = CC_TYPES.DISORIENT, range = 15, cooldown = 120, castTime = 0, school = "nature", drCategory = DR_CATEGORIES.DISORIENT},
        },
        
        -- Hunter
        HUNTER = {
            {spellId = 3355, name = "Freezing Trap", type = CC_TYPES.INCAPACITATE, range = 40, cooldown = 30, castTime = 0, school = "frost", drCategory = DR_CATEGORIES.INCAPACITATE},
            {spellId = 24394, name = "Intimidation", type = CC_TYPES.STUN, range = 5, cooldown = 60, castTime = 0, school = "physical", drCategory = DR_CATEGORIES.STUN},
            {spellId = 187650, name = "Freezing Trap", type = CC_TYPES.INCAPACITATE, range = 40, cooldown = 30, castTime = 0, school = "frost", drCategory = DR_CATEGORIES.INCAPACITATE},
            {spellId = 2649, name = "Growl", type = CC_TYPES.TAUNT, range = 30, cooldown = 8, castTime = 0, school = "physical", drCategory = DR_CATEGORIES.TAUNT},
        },
        
        -- Mage
        MAGE = {
            {spellId = 118, name = "Polymorph", type = CC_TYPES.INCAPACITATE, range = 30, cooldown = 0, castTime = 1.5, school = "arcane", drCategory = DR_CATEGORIES.INCAPACITATE},
            {spellId = 122, name = "Frost Nova", type = CC_TYPES.ROOT, range = 12, cooldown = 30, castTime = 0, school = "frost", drCategory = DR_CATEGORIES.ROOT},
            {spellId = 31661, name = "Dragon's Breath", type = CC_TYPES.DISORIENT, range = 12, cooldown = 45, castTime = 0, school = "fire", drCategory = DR_CATEGORIES.DISORIENT},
            {spellId = 82691, name = "Ring of Frost", type = CC_TYPES.INCAPACITATE, range = 40, cooldown = 45, castTime = 2, school = "frost", drCategory = DR_CATEGORIES.INCAPACITATE},
        },
        
        -- Monk
        MONK = {
            {spellId = 115078, name = "Paralysis", type = CC_TYPES.INCAPACITATE, range = 20, cooldown = 45, castTime = 0, school = "physical", drCategory = DR_CATEGORIES.INCAPACITATE},
            {spellId = 119381, name = "Leg Sweep", type = CC_TYPES.STUN, range = 5, cooldown = 60, castTime = 0, school = "physical", drCategory = DR_CATEGORIES.STUN},
            {spellId = 116706, name = "Disable", type = CC_TYPES.ROOT, range = 5, cooldown = 0, castTime = 0, school = "physical", drCategory = DR_CATEGORIES.ROOT},
            {spellId = 116705, name = "Spear Hand Strike", type = CC_TYPES.SILENCE, range = 5, cooldown = 15, castTime = 0, school = "physical", drCategory = DR_CATEGORIES.SILENCE},
            {spellId = 115546, name = "Provoke", type = CC_TYPES.TAUNT, range = 30, cooldown = 8, castTime = 0, school = "physical", drCategory = DR_CATEGORIES.TAUNT},
        },
        
        -- Paladin
        PALADIN = {
            {spellId = 20066, name = "Repentance", type = CC_TYPES.INCAPACITATE, range = 30, cooldown = 15, castTime = 1.5, school = "holy", drCategory = DR_CATEGORIES.INCAPACITATE},
            {spellId = 853, name = "Hammer of Justice", type = CC_TYPES.STUN, range = 10, cooldown = 60, castTime = 0, school = "holy", drCategory = DR_CATEGORIES.STUN},
            {spellId = 105421, name = "Blinding Light", type = CC_TYPES.DISORIENT, range = 10, cooldown = 90, castTime = 0, school = "holy", drCategory = DR_CATEGORIES.DISORIENT},
            {spellId = 62124, name = "Hand of Reckoning", type = CC_TYPES.TAUNT, range = 30, cooldown = 8, castTime = 0, school = "holy", drCategory = DR_CATEGORIES.TAUNT},
        },
        
        -- Priest
        PRIEST = {
            {spellId = 605, name = "Mind Control", type = CC_TYPES.INCAPACITATE, range = 30, cooldown = 0, castTime = 1.5, school = "shadow", drCategory = DR_CATEGORIES.MIND_CONTROL},
            {spellId = 8122, name = "Psychic Scream", type = CC_TYPES.FEAR, range = 8, cooldown = 60, castTime = 0, school = "shadow", drCategory = DR_CATEGORIES.FEAR},
            {spellId = 15487, name = "Silence", type = CC_TYPES.SILENCE, range = 30, cooldown = 45, castTime = 0, school = "shadow", drCategory = DR_CATEGORIES.SILENCE},
            {spellId = 64044, name = "Psychic Horror", type = CC_TYPES.HORROR, range = 30, cooldown = 45, castTime = 0, school = "shadow", drCategory = DR_CATEGORIES.HORROR},
            {spellId = 9484, name = "Shackle Undead", type = CC_TYPES.INCAPACITATE, range = 30, cooldown = 0, castTime = 1.5, school = "holy", drCategory = DR_CATEGORIES.INCAPACITATE},
        },
        
        -- Rogue
        ROGUE = {
            {spellId = 2094, name = "Blind", type = CC_TYPES.INCAPACITATE, range = 15, cooldown = 120, castTime = 0, school = "physical", drCategory = DR_CATEGORIES.DISORIENT},
            {spellId = 1833, name = "Cheap Shot", type = CC_TYPES.STUN, range = 5, cooldown = 0, castTime = 0, school = "physical", drCategory = DR_CATEGORIES.STUN},
            {spellId = 408, name = "Kidney Shot", type = CC_TYPES.STUN, range = 5, cooldown = 20, castTime = 0, school = "physical", drCategory = DR_CATEGORIES.STUN},
            {spellId = 1776, name = "Gouge", type = CC_TYPES.INCAPACITATE, range = 5, cooldown = 20, castTime = 0, school = "physical", drCategory = DR_CATEGORIES.INCAPACITATE},
            {spellId = 6770, name = "Sap", type = CC_TYPES.INCAPACITATE, range = 10, cooldown = 0, castTime = 0, school = "physical", drCategory = DR_CATEGORIES.INCAPACITATE},
        },
        
        -- Shaman
        SHAMAN = {
            {spellId = 51514, name = "Hex", type = CC_TYPES.INCAPACITATE, range = 30, cooldown = 30, castTime = 1.5, school = "nature", drCategory = DR_CATEGORIES.INCAPACITATE},
            {spellId = 118905, name = "Static Charge", type = CC_TYPES.STUN, range = 0, cooldown = 30, castTime = 0, school = "nature", drCategory = DR_CATEGORIES.STUN},
            {spellId = 64695, name = "Earthgrab", type = CC_TYPES.ROOT, range = 8, cooldown = 30, castTime = 0, school = "nature", drCategory = DR_CATEGORIES.ROOT},
        },
        
        -- Warlock
        WARLOCK = {
            {spellId = 5782, name = "Fear", type = CC_TYPES.FEAR, range = 30, cooldown = 0, castTime = 1.5, school = "shadow", drCategory = DR_CATEGORIES.FEAR},
            {spellId = 710, name = "Banish", type = CC_TYPES.BANISH, range = 30, cooldown = 0, castTime = 1.5, school = "shadow", drCategory = DR_CATEGORIES.BANISH},
            {spellId = 6789, name = "Mortal Coil", type = CC_TYPES.HORROR, range = 20, cooldown = 45, castTime = 0, school = "shadow", drCategory = DR_CATEGORIES.HORROR},
            {spellId = 118699, name = "Fear", type = CC_TYPES.FEAR, range = 20, cooldown = 0, castTime = 1.5, school = "shadow", drCategory = DR_CATEGORIES.FEAR},
            {spellId = 30283, name = "Shadowfury", type = CC_TYPES.STUN, range = 30, cooldown = 60, castTime = 0, school = "shadow", drCategory = DR_CATEGORIES.STUN},
            {spellId = 89751, name = "Fel Storm", type = CC_TYPES.STUN, range = 8, cooldown = 45, castTime = 0, school = "shadow", drCategory = DR_CATEGORIES.STUN},
        },
        
        -- Warrior
        WARRIOR = {
            {spellId = 5246, name = "Intimidating Shout", type = CC_TYPES.FEAR, range = 8, cooldown = 90, castTime = 0, school = "physical", drCategory = DR_CATEGORIES.FEAR},
            {spellId = 132168, name = "Shockwave", type = CC_TYPES.STUN, range = 10, cooldown = 40, castTime = 0, school = "physical", drCategory = DR_CATEGORIES.STUN},
            {spellId = 132169, name = "Storm Bolt", type = CC_TYPES.STUN, range = 30, cooldown = 30, castTime = 0, school = "physical", drCategory = DR_CATEGORIES.STUN},
            {spellId = 107566, name = "Staggering Shout", type = CC_TYPES.ROOT, range = 30, cooldown = 40, castTime = 0, school = "physical", drCategory = DR_CATEGORIES.ROOT},
            {spellId = 355, name = "Taunt", type = CC_TYPES.TAUNT, range = 30, cooldown = 8, castTime = 0, school = "physical", drCategory = DR_CATEGORIES.TAUNT},
        },
    }
    
    -- Check if player has these spells
    if crowdControls[class] then
        for _, cc in ipairs(crowdControls[class]) do
            local name, _, icon = GetSpellInfo(cc.spellId)
            if name then
                -- Check if player has this spell
                if IsSpellKnown(cc.spellId) or IsPlayerSpell(cc.spellId) then
                    -- Add to registry
                    tinsert(abilityRegistry.crowdControl, {
                        id = cc.spellId,
                        name = name,
                        icon = icon,
                        type = cc.type,
                        range = cc.range,
                        cooldown = cc.cooldown,
                        castTime = cc.castTime,
                        school = cc.school,
                        drCategory = cc.drCategory,
                        lastUseTime = 0,
                        successRate = 100, -- Start with perfect success rate
                        totalUses = 0,
                        successfulUses = 0
                    })
                end
            end
        end
    end
}

-- Is interrupt available
function AdvancedAbilityControl:IsInterruptAvailable(target)
    if not settings.global.interrupts.enabled then
        return false
    end
    
    -- Check for available interrupt
    for _, interrupt in ipairs(abilityRegistry.interrupts) do
        -- Check if off cooldown
        local start, duration = GetSpellCooldown(interrupt.id)
        local isOnCooldown = start > 0 and duration > 0
        
        if not isOnCooldown then
            -- Check range if target provided
            if target then
                local inRange = IsSpellInRange(interrupt.name, target)
                if inRange ~= 1 and not settings.global.interrupts.allowMovingToInterrupt then
                    -- Not in range and not allowed to move to interrupt
                    return false
                end
            end
            
            return true, interrupt
        end
    end
    
    return false
}

-- Is dispel available
function AdvancedAbilityControl:IsDispelAvailable(target, dispelType)
    if not settings.global.dispels.enabled then
        return false
    end
    
    -- Check for available dispel
    for _, dispel in ipairs(abilityRegistry.dispels) do
        -- Check if this dispel can handle the requested type
        local canDispelType = false
        if dispelType then
            for _, type in ipairs(dispel.types) do
                if type == dispelType then
                    canDispelType = true
                    break
                end
            end
            
            if not canDispelType then
                -- This dispel can't handle the requested type
                return false
            end
        end
        
        -- Check if off cooldown
        local start, duration = GetSpellCooldown(dispel.id)
        local isOnCooldown = start > 0 and duration > 0
        
        if not isOnCooldown then
            -- Check target type constraints
            if target then
                if dispel.targetType == "friendly" and not UnitIsFriend("player", target) then
                    -- Can't dispel hostile targets with friendly dispel
                    return false
                elseif dispel.targetType == "harmful" and UnitIsFriend("player", target) then
                    -- Can't dispel friendly targets with harmful dispel
                    return false
                elseif dispel.targetType == "self" and not UnitIsUnit("player", target) then
                    -- Can only dispel self
                    return false
                end
                
                -- Check range
                local inRange = IsSpellInRange(dispel.name, target)
                if inRange ~= 1 then
                    -- Not in range
                    return false
                end
            end
            
            -- Check if pet is required and available
            if dispel.petRequired then
                local hasPet = UnitExists("pet")
                if not hasPet then
                    return false
                end
                
                -- Check pet type (could be more sophisticated)
                local petName = UnitName("pet")
                if not petName or not string_find(string_lower(petName), string_lower(dispel.petRequired)) then
                    return false
                end
            end
            
            return true, dispel
        end
    end
    
    return false
}

-- Is crowd control available
function AdvancedAbilityControl:IsCCAvailable(target, ccType, drCategory)
    if not settings.global.crowdControl.enabled then
        return false
    end
    
    -- Check if this CC type is enabled
    if ccType and settings.global.crowdControl.enabledTypes[ccType] == false then
        return false
    end
    
    -- Check for available CC
    for _, cc in ipairs(abilityRegistry.crowdControl) do
        -- Check type match if requested
        if ccType and cc.type ~= ccType then
            -- Not the requested CC type
            return false
        end
        
        -- Check DR category if requested
        if drCategory and cc.drCategory ~= drCategory then
            -- Not the requested DR category
            return false
        end
        
        -- Check if off cooldown
        local start, duration = GetSpellCooldown(cc.id)
        local isOnCooldown = start > 0 and duration > 0
        
        if not isOnCooldown then
            -- Check range if target provided
            if target then
                local inRange = IsSpellInRange(cc.name, target)
                if inRange ~= 1 then
                    -- Not in range
                    return false
                end
            end
            
            return true, cc
        end
    end
    
    return false
}

-- Calculate interrupt delay
function AdvancedAbilityControl:CalculateInterruptDelay(spellId, targetId, totalCastTime)
    -- Default values
    local minDelay = settings.global.interrupts.minDelay
    local maxDelay = settings.global.interrupts.maxDelay
    local timingMode = settings.global.interrupts.timingMode
    
    -- Check for ability-specific settings
    if settings.abilities.interrupts and settings.abilities.interrupts[spellId] then
        local abilitySettings = settings.abilities.interrupts[spellId]
        if abilitySettings.useCustomTiming then
            minDelay = abilitySettings.minDelay
            maxDelay = abilitySettings.maxDelay
            timingMode = abilitySettings.timingMode
        end
    end
    
    -- Check for spell-specific settings
    if customDelays.interrupts and customDelays.interrupts[targetId] and customDelays.interrupts[targetId][spellId] then
        local spellSettings = customDelays.interrupts[targetId][spellId]
        minDelay = spellSettings.minDelay
        maxDelay = spellSettings.maxDelay
        timingMode = spellSettings.timingMode
    end
    
    -- Calculate delay based on timing mode
    if timingMode == TIMING_MODES.INSTANT then
        return 0
    elseif timingMode == TIMING_MODES.RANDOM then
        return random(math.floor(minDelay * 100), math.floor(maxDelay * 100)) / 100
    elseif timingMode == TIMING_MODES.PERCENTAGE then
        local targetPercentage = settings.global.interrupts.targetPercentage
        if settings.abilities.interrupts and settings.abilities.interrupts[spellId] and settings.abilities.interrupts[spellId].targetPercentage then
            targetPercentage = settings.abilities.interrupts[spellId].targetPercentage
        end
        
        return (targetPercentage / 100) * totalCastTime
    elseif timingMode == TIMING_MODES.VARIABLE then
        -- Variable based on spell importance
        local priority = self:GetSpellPriority(spellId, ABILITY_TYPES.INTERRUPT)
        if priority >= PRIORITY_LEVELS.HIGH then
            -- High priority = faster interrupt
            return random(math.floor(minDelay * 50), math.floor(minDelay * 150)) / 100
        elseif priority == PRIORITY_LEVELS.MEDIUM then
            -- Medium priority = normal interrupt
            return random(math.floor(minDelay * 100), math.floor(maxDelay * 100)) / 100
        else
            -- Low priority = slower interrupt
            return random(math.floor(maxDelay * 75), math.floor(maxDelay * 125)) / 100
        end
    else
        -- Human-like delay (HUMAN mode)
        -- Generate a value that tends to be in the middle of the range
        local r1 = random(math.floor(minDelay * 100), math.floor(maxDelay * 100)) / 100
        local r2 = random(math.floor(minDelay * 100), math.floor(maxDelay * 100)) / 100
        local r3 = random(math.floor(minDelay * 100), math.floor(maxDelay * 100)) / 100
        
        return (r1 + r2 + r3) / 3
    end
end

-- Calculate dispel delay
function AdvancedAbilityControl:CalculateDispelDelay(debuffId, targetId, debuffType)
    -- Default values
    local minDelay = settings.global.dispels.minDelay
    local maxDelay = settings.global.dispels.maxDelay
    local timingMode = settings.global.dispels.timingMode
    
    -- Check for debuff-specific settings
    if settings.abilities.dispels and settings.abilities.dispels[debuffId] then
        local abilitySettings = settings.abilities.dispels[debuffId]
        if abilitySettings.useCustomTiming then
            minDelay = abilitySettings.minDelay
            maxDelay = abilitySettings.maxDelay
            timingMode = abilitySettings.timingMode
        end
    end
    
    -- Adjust timing based on debuff type priority
    local typePriority = settings.global.dispels.typePriorities[debuffType] or PRIORITY_LEVELS.MEDIUM
    if typePriority == PRIORITY_LEVELS.HIGH or typePriority == PRIORITY_LEVELS.CRITICAL then
        -- High priority debuff types get dispelled faster
        minDelay = minDelay * 0.5
        maxDelay = maxDelay * 0.5
    elseif typePriority == PRIORITY_LEVELS.LOW then
        -- Low priority debuff types can wait longer
        minDelay = minDelay * 1.5
        maxDelay = maxDelay * 1.5
    end
    
    -- Danger check - is this an immediately dangerous debuff?
    if DANGEROUS_DISPEL_DEBUFFS[debuffId] then
        return 0 -- Instant dispel for dangerous effects
    end
    
    -- Calculate delay based on timing mode
    if timingMode == TIMING_MODES.INSTANT then
        return 0
    elseif timingMode == TIMING_MODES.RANDOM then
        return random(math.floor(minDelay * 100), math.floor(maxDelay * 100)) / 100
    elseif timingMode == TIMING_MODES.VARIABLE then
        -- Variable based on debuff priority
        local priority = self:GetSpellPriority(debuffId, ABILITY_TYPES.DISPEL)
        if priority >= PRIORITY_LEVELS.HIGH then
            -- High priority = faster dispel
            return random(math.floor(minDelay * 50), math.floor(minDelay * 150)) / 100
        elseif priority == PRIORITY_LEVELS.MEDIUM then
            -- Medium priority = normal dispel
            return random(math.floor(minDelay * 100), math.floor(maxDelay * 100)) / 100
        else
            -- Low priority = slower dispel
            return random(math.floor(maxDelay * 75), math.floor(maxDelay * 125)) / 100
        end
    else
        -- Human-like delay (HUMAN mode)
        -- Generate a value that tends to be in the middle of the range
        local r1 = random(math.floor(minDelay * 100), math.floor(maxDelay * 100)) / 100
        local r2 = random(math.floor(minDelay * 100), math.floor(maxDelay * 100)) / 100
        
        return (r1 + r2) / 2
    end
end

-- Calculate CC delay
function AdvancedAbilityControl:CalculateCCDelay(spellId, targetId, ccType)
    -- Default values
    local minDelay = settings.global.crowdControl.minDelay
    local maxDelay = settings.global.crowdControl.maxDelay
    local timingMode = settings.global.crowdControl.timingMode
    
    -- Check for ability-specific settings
    if settings.abilities.crowdControl and settings.abilities.crowdControl[spellId] then
        local abilitySettings = settings.abilities.crowdControl[spellId]
        if abilitySettings.useCustomTiming then
            minDelay = abilitySettings.minDelay
            maxDelay = abilitySettings.maxDelay
            timingMode = abilitySettings.timingMode
        end
    end
    
    -- Calculate delay based on timing mode
    if timingMode == TIMING_MODES.INSTANT then
        return 0
    elseif timingMode == TIMING_MODES.RANDOM then
        return random(math.floor(minDelay * 100), math.floor(maxDelay * 100)) / 100
    elseif timingMode == TIMING_MODES.VARIABLE then
        -- Variable based on CC type
        if ccType == CC_TYPES.STUN or ccType == CC_TYPES.SILENCE then
            -- Faster reaction for interrupting stuns/silences
            return random(math.floor(minDelay * 50), math.floor(minDelay * 150)) / 100
        elseif ccType == CC_TYPES.INCAPACITATE or ccType == CC_TYPES.FEAR then
            -- Normal timing for standard CC
            return random(math.floor(minDelay * 100), math.floor(maxDelay * 100)) / 100
        else
            -- Slower for less important CC types
            return random(math.floor(maxDelay * 75), math.floor(maxDelay * 125)) / 100
        end
    else
        -- Human-like delay (HUMAN mode)
        -- Generate a value that tends to be in the middle of the range
        local r1 = random(math.floor(minDelay * 100), math.floor(maxDelay * 100)) / 100
        local r2 = random(math.floor(minDelay * 100), math.floor(maxDelay * 100)) / 100
        local r3 = random(math.floor(minDelay * 100), math.floor(maxDelay * 100)) / 100
        
        return (r1 + r2 + r3) / 3
    end
end

-- Get spell priority (for a specific ability type)
function AdvancedAbilityControl:GetSpellPriority(spellId, abilityType)
    -- Check exclusion lists first
    if abilityType == ABILITY_TYPES.INTERRUPT and exclusionLists.interrupts[spellId] then
        return PRIORITY_LEVELS.IGNORED
    elseif abilityType == ABILITY_TYPES.DISPEL and exclusionLists.dispels[spellId] then
        return PRIORITY_LEVELS.IGNORED
    elseif abilityType == ABILITY_TYPES.CC and exclusionLists.crowdControl[spellId] then
        return PRIORITY_LEVELS.IGNORED
    end
    
    -- Check inclusion lists for high priority
    if abilityType == ABILITY_TYPES.INTERRUPT and inclusionLists.interrupts[spellId] then
        return PRIORITY_LEVELS.HIGH
    elseif abilityType == ABILITY_TYPES.DISPEL and inclusionLists.dispels[spellId] then
        return PRIORITY_LEVELS.HIGH
    elseif abilityType == ABILITY_TYPES.CC and inclusionLists.crowdControl[spellId] then
        return PRIORITY_LEVELS.HIGH
    end
    
    -- Check built-in databases
    if abilityType == ABILITY_TYPES.INTERRUPT and IMPORTANT_INTERRUPT_SPELLS[spellId] then
        return PRIORITY_LEVELS.HIGH
    elseif abilityType == ABILITY_TYPES.DISPEL and DANGEROUS_DISPEL_DEBUFFS[spellId] then
        return PRIORITY_LEVELS.CRITICAL
    elseif abilityType == ABILITY_TYPES.DISPEL and DISPEL_BLACKLIST[spellId] then
        return PRIORITY_LEVELS.IGNORED
    end
    
    -- Check encounter-specific rules
    if activeEncounterID and encounterRules[activeEncounterID] then
        local rules = encounterRules[activeEncounterID]
        
        if rules.interrupts and rules.interrupts[spellId] then
            return rules.interrupts[spellId]
        elseif rules.dispels and rules.dispels[spellId] then
            return rules.dispels[spellId]
        elseif rules.crowdControl and rules.crowdControl[spellId] then
            return rules.crowdControl[spellId]
        end
    end
    
    -- Return default medium priority
    return PRIORITY_LEVELS.MEDIUM
}

-- Should interrupt spell
function AdvancedAbilityControl:ShouldInterruptSpell(spellId, targetId, castPercentage)
    -- Check if interrupts are enabled
    if not settings.global.interrupts.enabled then
        return false
    end
    
    -- Check priority against threshold
    local priority = self:GetSpellPriority(spellId, ABILITY_TYPES.INTERRUPT)
    if priority < settings.global.interrupts.priorityThreshold then
        return false
    end
    
    -- Check cast percentage against target percentage
    if settings.global.interrupts.timingMode == TIMING_MODES.PERCENTAGE then
        local targetPercentage = settings.global.interrupts.targetPercentage
        if settings.abilities.interrupts and settings.abilities.interrupts[spellId] and settings.abilities.interrupts[spellId].targetPercentage then
            targetPercentage = settings.abilities.interrupts[spellId].targetPercentage
        end
        
        if castPercentage < targetPercentage then
            return false
        end
    end
    
    -- Check if we should save interrupt for higher priority
    if settings.global.interrupts.saveForPriority and priority < PRIORITY_LEVELS.HIGH then
        -- Check if any high priority casts are happening
        -- This would be implemented with target scanning in a real implementation
        -- Simplified for demonstration purposes
        local otherHighPriorityCastsActive = false
        
        -- Logic to check for other high priority casts
        if otherHighPriorityCastsActive then
            return false
        end
    end
    
    -- Check for party interrupt rotation if enabled
    if settings.global.interrupts.rotateWithParty and IsInGroup() then
        -- Logic to check if it's our turn to interrupt
        -- This would be implemented with party communication in a real implementation
        -- Simplified for demonstration purposes
        local isMyTurnToInterrupt = true
        
        if not isMyTurnToInterrupt then
            return false
        end
    end
    
    return true
}

-- Should dispel aura
function AdvancedAbilityControl:ShouldDispelAura(debuffId, targetId, debuffType, debuffStacks, debuffDuration)
    -- Check if dispels are enabled
    if not settings.global.dispels.enabled then
        return false
    end
    
    -- Check priority against threshold
    local priority = self:GetSpellPriority(debuffId, ABILITY_TYPES.DISPEL)
    if priority < settings.global.dispels.priorityThreshold then
        return false
    end
    
    -- Check if this is on the blacklist
    if DISPEL_BLACKLIST[debuffId] then
        return false
    end
    
    -- Check stack threshold
    if debuffStacks < settings.global.dispels.stackThreshold then
        return false
    end
    
    -- Check remaining duration
    if debuffDuration < settings.global.dispels.minDebuffDuration then
        return false
    end
    
    -- Check health safety threshold for targeted unit
    if UnitExists(targetId) then
        local healthPercent = UnitHealth(targetId) / UnitHealthMax(targetId)
        if healthPercent < settings.global.dispels.safetyHealthThreshold then
            -- Only dispel if this is a critical priority
            if priority < PRIORITY_LEVELS.CRITICAL then
                return false
            end
        end
    end
    
    -- Check if the debuff type is prioritized
    local typePriority = settings.global.dispels.typePriorities[debuffType] or PRIORITY_LEVELS.MEDIUM
    if typePriority < settings.global.dispels.priorityThreshold then
        return false
    end
    
    -- If we're not the healer and healer priority is enabled, check if a healer is available
    if settings.global.dispels.healerPriority and IsInGroup() then
        local playerRole = UnitGroupRolesAssigned("player")
        if playerRole ~= "HEALER" then
            -- Check if a healer is available with an appropriate dispel
            -- This would be implemented with party scanning in a real implementation
            -- Simplified for demonstration purposes
            local healerCanDispel = false
            
            -- Logic to check if healer can dispel
            if healerCanDispel then
                return false
            end
        end
    end
    
    return true
}

-- Should use crowd control
function AdvancedAbilityControl:ShouldUseCC(spellId, targetId, ccType)
    -- Check if CCs are enabled
    if not settings.global.crowdControl.enabled then
        return false
    end
    
    -- Check if this CC type is enabled
    if not settings.global.crowdControl.enabledTypes[ccType] then
        return false
    end
    
    -- Check priority against threshold
    local priority = self:GetSpellPriority(spellId, ABILITY_TYPES.CC)
    if priority < settings.global.crowdControl.priorityThreshold then
        return false
    end
    
    -- Check diminishing returns if enabled
    if settings.global.crowdControl.avoidDiminishingReturns then
        -- Get the DR category for this spell
        local drCategory = nil
        for _, cc in ipairs(abilityRegistry.crowdControl) do
            if cc.id == spellId then
                drCategory = cc.drCategory
                break
            end
        end
        
        if drCategory then
            -- Check if target already has DR in this category
            -- This would be implemented with DR tracking in a real implementation
            -- Simplified for demonstration purposes
            local hasDR = false
            local drLevel = 0 -- 0=None, 1=50%, 2=75%, 3=Immune
            
            -- Logic to check for DR
            if hasDR and drLevel >= 2 then
                return false
            end
        end
    end
    
    -- Check for CC chain coordination if enabled
    if settings.global.crowdControl.chainCC and IsInGroup() then
        -- Check if another CC is already active on the target
        -- This would be implemented with target scanning in a real implementation
        -- Simplified for demonstration purposes
        local targetAlreadyCCed = false
        
        -- Logic to check if target is already CC'ed
        if targetAlreadyCCed then
            return false
        end
    end
    
    return true
}

-- Process a spellcast for possible interruption
function AdvancedAbilityControl:ProcessSpellCastForInterrupt(unit, spellId, target, castGUID)
    -- Skip if not enabled
    if not settings.global.interrupts.enabled then
        return
    end
    
    -- Skip if we don't care about this unit (only interrupt enemies)
    if UnitIsFriend("player", unit) then
        return
    end
    
    -- Check for unknown spells if set to ignore them
    local spellName = GetSpellInfo(spellId)
    if not spellName and settings.global.interrupts.ignoreUnknownSpells then
        return
    end
    
    -- Get cast information
    local castName, castText, castIcon, castStartTime, castEndTime, _, castId = UnitCastingInfo(unit)
    if not castName then
        -- Not casting
        return
    end
    
    -- Calculate cast percentage and total cast time
    local currentTime = GetTime()
    local totalCastTime = (castEndTime - castStartTime) / 1000
    local elapsedTime = (currentTime * 1000 - castStartTime) / 1000
    local remainingTime = totalCastTime - elapsedTime
    local castPercentage = (elapsedTime / totalCastTime) * 100
    
    -- Check if we should interrupt this spell
    if self:ShouldInterruptSpell(spellId, UnitGUID(unit), castPercentage) then
        -- Calculate delay
        local delay = self:CalculateInterruptDelay(spellId, UnitGUID(unit), totalCastTime)
        
        -- Ensure delay doesn't exceed remaining cast time
        delay = min(delay, remainingTime - 0.1)
        
        -- Schedule the interrupt
        self:ScheduleInterrupt(unit, delay, spellId, castGUID)
    end
}

-- Schedule an interrupt
function AdvancedAbilityControl:ScheduleInterrupt(unit, delay, spellId, castGUID)
    -- Check if interrupt is available
    local interruptAvailable, interruptAbility = self:IsInterruptAvailable(unit)
    if not interruptAvailable then
        if debugMode then
            self:Debug("Cannot schedule interrupt: No interrupt available")
        end
        return
    end
    
    -- Create interrupt action
    local action = {
        type = ABILITY_TYPES.INTERRUPT,
        unit = unit,
        spellId = spellId,
        castGUID = castGUID,
        abilityId = interruptAbility.id,
        abilityName = interruptAbility.name,
        executeTime = GetTime() + delay
    }
    
    -- Add to pending actions
    tinsert(pendingActions, action)
    
    if debugMode then
        self:Debug("Scheduled interrupt of " .. GetSpellInfo(spellId) .. " on " .. UnitName(unit) .. " in " .. delay .. "s")
    end
}

-- Process an aura for possible dispelling
function AdvancedAbilityControl:ProcessAuraForDispel(unit, auraId, dispelType, stackCount, duration)
    -- Skip if not enabled
    if not settings.global.dispels.enabled then
        return
    end
    
    -- Skip if our class can't dispel this type
    local canDispelType = false
    for _, dispel in ipairs(abilityRegistry.dispels) do
        for _, type in ipairs(dispel.types) do
            if type == dispelType then
                canDispelType = true
                break
            end
        end
        if canDispelType then break end
    end
    
    if not canDispelType then
        return
    end
    
    -- Check if we should dispel this aura
    if self:ShouldDispelAura(auraId, unit, dispelType, stackCount, duration) then
        -- Calculate delay
        local delay = self:CalculateDispelDelay(auraId, UnitGUID(unit), dispelType)
        
        -- Ensure delay doesn't exceed duration
        delay = min(delay, duration - 0.1)
        
        -- Schedule the dispel
        self:ScheduleDispel(unit, delay, auraId, dispelType)
    end
}

-- Schedule a dispel
function AdvancedAbilityControl:ScheduleDispel(unit, delay, auraId, dispelType)
    -- Check if dispel is available
    local dispelAvailable, dispelAbility = self:IsDispelAvailable(unit, dispelType)
    if not dispelAvailable then
        if debugMode then
            self:Debug("Cannot schedule dispel: No dispel available")
        end
        return
    end
    
    -- Create dispel action
    local action = {
        type = ABILITY_TYPES.DISPEL,
        unit = unit,
        auraId = auraId,
        dispelType = dispelType,
        abilityId = dispelAbility.id,
        abilityName = dispelAbility.name,
        executeTime = GetTime() + delay
    }
    
    -- Add to pending actions
    tinsert(pendingActions, action)
    
    if debugMode then
        self:Debug("Scheduled dispel of " .. GetSpellInfo(auraId) .. " (" .. dispelType .. ") on " .. UnitName(unit) .. " in " .. delay .. "s")
    end
}

-- Process a target for possible crowd control
function AdvancedAbilityControl:ProcessTargetForCC(unit, ccType)
    -- Skip if not enabled
    if not settings.global.crowdControl.enabled then
        return
    end
    
    -- Skip if this CC type is not enabled
    if ccType and not settings.global.crowdControl.enabledTypes[ccType] then
        return
    end
    
    -- Check if this target should be CC'ed
    -- In a real implementation, this would include threat analysis, role detection, etc.
    -- Simplified for demonstration purposes
    local shouldCC = true
    
    -- Check if we have an appropriate CC ability
    local ccAvailable, ccAbility = self:IsCCAvailable(unit, ccType)
    if not ccAvailable then
        if debugMode then
            self:Debug("Cannot schedule CC: No CC available for type " .. (ccType or "any"))
        end
        return
    end
    
    -- Calculate delay
    local delay = self:CalculateCCDelay(ccAbility.id, UnitGUID(unit), ccAbility.type)
    
    -- Schedule the crowd control
    self:ScheduleCC(unit, delay, ccAbility)
}

-- Schedule crowd control
function AdvancedAbilityControl:ScheduleCC(unit, delay, ccAbility)
    -- Create CC action
    local action = {
        type = ABILITY_TYPES.CC,
        unit = unit,
        abilityId = ccAbility.id,
        abilityName = ccAbility.name,
        ccType = ccAbility.type,
        executeTime = GetTime() + delay
    }
    
    -- Add to pending actions
    tinsert(pendingActions, action)
    
    if debugMode then
        self:Debug("Scheduled " .. ccAbility.name .. " on " .. UnitName(unit) .. " in " .. delay .. "s")
    end
}

-- Execute pending actions
function AdvancedAbilityControl:ExecutePendingActions()
    local currentTime = GetTime()
    
    -- Check each pending action
    for i = #pendingActions, 1, -1 do
        local action = pendingActions[i]
        
        -- Check if it's time to execute
        if action.executeTime <= currentTime then
            -- Execute based on action type
            if action.type == ABILITY_TYPES.INTERRUPT then
                self:ExecuteInterrupt(action)
            elseif action.type == ABILITY_TYPES.DISPEL then
                self:ExecuteDispel(action)
            elseif action.type == ABILITY_TYPES.CC then
                self:ExecuteCC(action)
            end
            
            -- Remove from pending actions
            tremove(pendingActions, i)
        end
    end
}

-- Execute an interrupt
function AdvancedAbilityControl:ExecuteInterrupt(action)
    -- Check if unit still exists and is still casting
    if not UnitExists(action.unit) then
        if debugMode then
            self:Debug("Interrupt failed: Unit no longer exists")
        end
        return
    end
    
    -- Check if unit is still casting the same spell
    local castName, castText, castIcon, castStartTime, castEndTime, _, castId = UnitCastingInfo(action.unit)
    if not castName then
        if debugMode then
            self:Debug("Interrupt failed: Unit no longer casting")
        end
        return
    end
    
    -- Check if it's the same cast (using cast GUID)
    if action.castGUID and castId ~= action.castGUID then
        if debugMode then
            self:Debug("Interrupt failed: Different cast in progress")
        end
        return
    end
    
    -- Cast the interrupt
    if debugMode then
        self:Debug("Executing interrupt: " .. action.abilityName .. " on " .. UnitName(action.unit))
    end
    
    -- Update last use time for tracking
    for i, interrupt in ipairs(abilityRegistry.interrupts) do
        if interrupt.id == action.abilityId then
            interrupt.lastUseTime = GetTime()
            interrupt.totalUses = interrupt.totalUses + 1
            -- Success tracking would be updated in SPELL_INTERRUPT event
            break
        end
    end
    
    -- Store last interrupt time for this target
    lastInterruptTimes[UnitGUID(action.unit)] = GetTime()
    
    -- Cast the spell
    -- In a real implementation, this would use a secure spell casting function
    -- For demonstration, we'll log the action
    self:Debug("WOULD CAST INTERRUPT: " .. action.abilityName .. " on " .. UnitName(action.unit))
}

-- Execute a dispel
function AdvancedAbilityControl:ExecuteDispel(action)
    -- Check if unit still exists
    if not UnitExists(action.unit) then
        if debugMode then
            self:Debug("Dispel failed: Unit no longer exists")
        end
        return
    end
    
    -- Check if the aura is still present
    local found = false
    local isFriend = UnitIsFriend("player", action.unit)
    
    -- For friendly units, check for debuffs
    if isFriend then
        for i = 1, 40 do
            local _, _, _, _, _, _, _, _, _, id = UnitDebuff(action.unit, i)
            if id and id == action.auraId then
                found = true
                break
            end
        end
    else
        -- For hostile units, check for buffs
        for i = 1, 40 do
            local _, _, _, _, _, _, _, _, _, id = UnitBuff(action.unit, i)
            if id and id == action.auraId then
                found = true
                break
            end
        end
    end
    
    if not found then
        if debugMode then
            self:Debug("Dispel failed: Aura no longer present")
        end
        return
    end
    
    -- Cast the dispel
    if debugMode then
        self:Debug("Executing dispel: " .. action.abilityName .. " on " .. UnitName(action.unit))
    end
    
    -- Update last use time for tracking
    for i, dispel in ipairs(abilityRegistry.dispels) do
        if dispel.id == action.abilityId then
            dispel.lastUseTime = GetTime()
            dispel.totalUses = dispel.totalUses + 1
            -- Success tracking would be updated in SPELL_DISPEL event
            break
        end
    end
    
    -- Store last dispel time for this target
    lastDispelTimes[UnitGUID(action.unit)] = GetTime()
    
    -- Cast the spell
    -- In a real implementation, this would use a secure spell casting function
    -- For demonstration, we'll log the action
    self:Debug("WOULD CAST DISPEL: " .. action.abilityName .. " on " .. UnitName(action.unit))
}

-- Execute crowd control
function AdvancedAbilityControl:ExecuteCC(action)
    -- Check if unit still exists
    if not UnitExists(action.unit) then
        if debugMode then
            self:Debug("CC failed: Unit no longer exists")
        end
        return
    end
    
    -- Check if unit is already under control
    local controlled = false
    for i = 1, 40 do
        local _, _, _, _, debuffType, _, _, _, _, id = UnitDebuff(action.unit, i)
        if debuffType == "Magic" or debuffType == "Curse" or debuffType == "Poison" then
            -- Possible CC, check more specifically
            -- In a real implementation, this would check for specific CC types
            controlled = true
            break
        end
    end
    
    if controlled and settings.global.crowdControl.chainCC then
        if debugMode then
            self:Debug("CC skipped: Unit already controlled and chain CC not enabled")
        end
        return
    end
    
    -- Cast the crowd control
    if debugMode then
        self:Debug("Executing CC: " .. action.abilityName .. " on " .. UnitName(action.unit))
    end
    
    -- Update last use time for tracking
    for i, cc in ipairs(abilityRegistry.crowdControl) do
        if cc.id == action.abilityId then
            cc.lastUseTime = GetTime()
            cc.totalUses = cc.totalUses + 1
            -- Success tracking would be updated in appropriate combat log event
            break
        end
    end
    
    -- Store last CC time for this target
    lastCCTimes[UnitGUID(action.unit)] = GetTime()
    
    -- Cast the spell
    -- In a real implementation, this would use a secure spell casting function
    -- For demonstration, we'll log the action
    self:Debug("WOULD CAST CC: " .. action.abilityName .. " on " .. UnitName(action.unit))
}

-- On PLAYER_ENTERING_WORLD event
function AdvancedAbilityControl:OnEnteringWorld()
    -- Detect current instance type
    local inInstance, instanceType = IsInInstance()
    if inInstance then
        if instanceType == "pvp" then
            activeInstanceType = INSTANCE_TYPES.PVP
        elseif instanceType == "arena" then
            activeInstanceType = INSTANCE_TYPES.PVP
        elseif instanceType == "party" then
            activeInstanceType = INSTANCE_TYPES.DUNGEON
        elseif instanceType == "raid" then
            activeInstanceType = INSTANCE_TYPES.RAID
        elseif instanceType == "scenario" then
            activeInstanceType = INSTANCE_TYPES.SCENARIO
        else
            activeInstanceType = INSTANCE_TYPES.WORLD
        end
    else
        activeInstanceType = INSTANCE_TYPES.WORLD
    end
    
    -- Reset active encounter ID
    activeEncounterID = nil
    
    -- Get dungeon or raid ID
    -- This would be implemented in a real addon
    activeDungeonID = nil
    activeRaidID = nil
    
    -- Re-scan player abilities (in case of spec change)
    self:ScanPlayerAbilities()
}

-- On UNIT_SPELLCAST_START event
function AdvancedAbilityControl:OnUnitSpellcastStart(unit, castGUID, spellId)
    -- Skip non-enemy units for interrupts
    if UnitIsFriend("player", unit) then
        return
    end
    
    -- Process for interruption
    self:ProcessSpellCastForInterrupt(unit, spellId, nil, castGUID)
}

-- On UNIT_SPELLCAST_STOP event
function AdvancedAbilityControl:OnUnitSpellcastStop(unit, castGUID, spellId)
    -- Remove any pending interrupts for this cast
    for i = #pendingActions, 1, -1 do
        local action = pendingActions[i]
        if action.type == ABILITY_TYPES.INTERRUPT and action.unit == unit and action.castGUID == castGUID then
            tremove(pendingActions, i)
            
            if debugMode then
                self:Debug("Removed pending interrupt for stopped cast")
            end
        end
    end
}

-- On UNIT_SPELLCAST_SUCCEEDED event
function AdvancedAbilityControl:OnUnitSpellcastSucceeded(unit, castGUID, spellId)
    -- Track successful casts by the player
    if unit ~= "player" then
        return
    end
    
    -- Check if this was one of our tracked abilities
    for _, interrupt in ipairs(abilityRegistry.interrupts) do
        if interrupt.id == spellId then
            -- Track success (will be confirmed in combat log)
            if debugMode then
                self:Debug("Successfully used interrupt: " .. interrupt.name)
            end
            return
        end
    end
    
    for _, dispel in ipairs(abilityRegistry.dispels) do
        if dispel.id == spellId then
            -- Track success (will be confirmed in combat log)
            if debugMode then
                self:Debug("Successfully used dispel: " .. dispel.name)
            end
            return
        end
    end
    
    for _, cc in ipairs(abilityRegistry.crowdControl) do
        if cc.id == spellId then
            -- Track success (will be confirmed in combat log)
            if debugMode then
                self:Debug("Successfully used CC: " .. cc.name)
            end
            return
        end
    end
}

-- On UNIT_SPELLCAST_INTERRUPTED event
function AdvancedAbilityControl:OnUnitSpellcastInterrupted(unit, castGUID, spellId)
    -- This could be used to track when player's own casts are interrupted
}

-- On UNIT_AURA event
function AdvancedAbilityControl:OnUnitAura(unit)
    -- Skip non-friendly units for dispels
    local isFriend = UnitIsFriend("player", unit)
    
    -- For friendly units, check for debuffs to dispel
    if isFriend and settings.global.dispels.enabled then
        for i = 1, 40 do
            local name, icon, count, debuffType, duration, expirationTime, source, isStealable, 
                  nameplateShowPersonal, spellId, canApplyAura, isBossDebuff, castByPlayer = UnitDebuff(unit, i)
                  
            if spellId and debuffType then
                local remainingTime = expirationTime - GetTime()
                self:ProcessAuraForDispel(unit, spellId, debuffType, count or 1, remainingTime)
            end
        end
    end
    
    -- For enemy units, check for buffs to steal/dispel
    if not isFriend and settings.global.dispels.enabled then
        for i = 1, 40 do
            local name, icon, count, buffType, duration, expirationTime, source, isStealable,
                  nameplateShowPersonal, spellId, canApplyAura, isBossDebuff, castByPlayer = UnitBuff(unit, i)
                  
            if spellId and (isStealable or buffType == DISPEL_TYPES.MAGIC or buffType == DISPEL_TYPES.ENRAGE) then
                local remainingTime = expirationTime - GetTime()
                self:ProcessAuraForDispel(unit, spellId, buffType or DISPEL_TYPES.MAGIC, count or 1, remainingTime)
            end
        end
    end
}

-- On ENCOUNTER_START event
function AdvancedAbilityControl:OnEncounterStart(encounterID, encounterName, difficultyID, groupSize)
    activeEncounterID = encounterID
    
    if debugMode then
        self:Debug("Encounter started: " .. encounterName .. " (ID: " .. encounterID .. ")")
    end
}

-- On ENCOUNTER_END event
function AdvancedAbilityControl:OnEncounterEnd(encounterID, encounterName, difficultyID, groupSize, success)
    activeEncounterID = nil
    
    if debugMode then
        self:Debug("Encounter ended: " .. encounterName .. " (ID: " .. encounterID .. ")")
    end
}

-- On CHALLENGE_MODE_START event (Mythic+)
function AdvancedAbilityControl:OnMythicPlusStart()
    -- Set instance type to dungeon for M+
    activeInstanceType = INSTANCE_TYPES.DUNGEON
    
    if debugMode then
        self:Debug("Mythic+ started")
    end
}

-- On CHALLENGE_MODE_COMPLETED event (Mythic+)
function AdvancedAbilityControl:OnMythicPlusCompleted()
    if debugMode then
        self:Debug("Mythic+ completed")
    end
}

-- On COMBAT_LOG_EVENT_UNFILTERED event
function AdvancedAbilityControl:OnCombatLogEvent(timestamp, eventType, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellId, spellName, spellSchool, ...)
    -- Skip if not enabled
    if not settings.enabled then
        return
    end
    
    -- Track successful interrupts
    if eventType == "SPELL_INTERRUPT" and sourceGUID == UnitGUID("player") then
        local interruptedSpellId, interruptedSpellName, interruptedSpellSchool = ...
        
        for _, interrupt in ipairs(abilityRegistry.interrupts) do
            if interrupt.id == spellId then
                interrupt.successfulUses = interrupt.successfulUses + 1
                interrupt.successRate = (interrupt.successfulUses / interrupt.totalUses) * 100
                
                if debugMode then
                    self:Debug("Tracked successful interrupt: " .. spellName .. " on " .. destName .. "'s " .. interruptedSpellName)
                end
                break
            end
        end
    end
    
    -- Track successful dispels
    if eventType == "SPELL_DISPEL" and sourceGUID == UnitGUID("player") then
        local dispelledSpellId, dispelledSpellName, dispelledSpellSchool, extraSpellId, extraSpellName, extraSchool = ...
        
        for _, dispel in ipairs(abilityRegistry.dispels) do
            if dispel.id == spellId then
                dispel.successfulUses = dispel.successfulUses + 1
                dispel.successRate = (dispel.successfulUses / dispel.totalUses) * 100
                
                if debugMode then
                    self:Debug("Tracked successful dispel: " .. spellName .. " on " .. destName .. "'s " .. dispelledSpellName)
                end
                break
            end
        end
    end
    
    -- Track successful crowd control
    if (eventType == "SPELL_AURA_APPLIED" and sourceGUID == UnitGUID("player")) then
        for _, cc in ipairs(abilityRegistry.crowdControl) do
            if cc.id == spellId then
                cc.successfulUses = cc.successfulUses + 1
                cc.successRate = (cc.successfulUses / cc.totalUses) * 100
                
                if debugMode then
                    self:Debug("Tracked successful CC: " .. spellName .. " on " .. destName)
                end
                break
            end
        end
    end
}

-- On UPDATE handler
function AdvancedAbilityControl:OnUpdate(elapsed)
    -- Execute pending actions
    self:ExecutePendingActions()
}

-- Handle slash command
function AdvancedAbilityControl:HandleSlashCommand(msg)
    if not msg or msg == "" then
        -- Show settings panel
        if WR.UI and WR.UI.AdvancedSettingsUI then
            WR.UI.AdvancedSettingsUI:SelectPanel("Ability Control")
        else
            print("Advanced Settings UI not available. Use command parameters to configure the ability control system.")
        end
        return
    end
    
    local command, param = msg:match("^(%S+)%s*(.*)$")
    if not command then
        return
    end
    
    command = command:lower()
    
    if command == "toggle" or command == "enable" or command == "disable" then
        if command == "toggle" then
            settings.enabled = not settings.enabled
        elseif command == "enable" then
            settings.enabled = true
        elseif command == "disable" then
            settings.enabled = false
        end
        
        self:SaveSettings()
        print(string.format("|cFF00FFFF[Advanced Ability Control]|r Module %s", settings.enabled and "enabled" or "disabled"))
    elseif command == "interrupt" or command == "interrupts" then
        if param == "toggle" or param == "enable" or param == "disable" then
            if param == "toggle" then
                settings.global.interrupts.enabled = not settings.global.interrupts.enabled
            elseif param == "enable" then
                settings.global.interrupts.enabled = true
            elseif param == "disable" then
                settings.global.interrupts.enabled = false
            end
            
            self:SaveSettings()
            print(string.format("|cFF00FFFF[Advanced Ability Control]|r Interrupts %s", settings.global.interrupts.enabled and "enabled" or "disabled"))
        elseif param:match("^delay%s+(.+)$") then
            local delayParams = param:match("^delay%s+(.+)$")
            local min, max = delayParams:match("(%S+)%s+(%S+)")
            
            if min and max then
                min = tonumber(min)
                max = tonumber(max)
                
                if min and max and min >= 0 and max >= min then
                    settings.global.interrupts.minDelay = min
                    settings.global.interrupts.maxDelay = max
                    self:SaveSettings()
                    print(string.format("|cFF00FFFF[Advanced Ability Control]|r Interrupt delay set to %.2f-%.2f seconds", min, max))
                else
                    print("|cFFFF0000[Advanced Ability Control]|r Invalid delay values. Use format: interrupt delay <min> <max>")
                end
            else
                print("|cFFFF0000[Advanced Ability Control]|r Invalid delay format. Use format: interrupt delay <min> <max>")
            end
        elseif param:match("^mode%s+(.+)$") then
            local mode = param:match("^mode%s+(.+)$")
            
            if mode == "instant" or mode == "human" or mode == "random" or mode == "variable" or mode == "percentage" then
                settings.global.interrupts.timingMode = mode:upper()
                self:SaveSettings()
                print(string.format("|cFF00FFFF[Advanced Ability Control]|r Interrupt mode set to %s", mode))
            else
                print("|cFFFF0000[Advanced Ability Control]|r Invalid mode. Valid modes: instant, human, random, variable, percentage")
            end
        else
            print("|cFF00FFFF[Advanced Ability Control]|r Interrupt commands:")
            print("  /abilitycontrol interrupt toggle/enable/disable")
            print("  /abilitycontrol interrupt delay <min> <max>")
            print("  /abilitycontrol interrupt mode <instant|human|random|variable|percentage>")
        end
    elseif command == "dispel" or command == "dispels" then
        if param == "toggle" or param == "enable" or param == "disable" then
            if param == "toggle" then
                settings.global.dispels.enabled = not settings.global.dispels.enabled
            elseif param == "enable" then
                settings.global.dispels.enabled = true
            elseif param == "disable" then
                settings.global.dispels.enabled = false
            end
            
            self:SaveSettings()
            print(string.format("|cFF00FFFF[Advanced Ability Control]|r Dispels %s", settings.global.dispels.enabled and "enabled" or "disabled"))
        elseif param:match("^delay%s+(.+)$") then
            local delayParams = param:match("^delay%s+(.+)$")
            local min, max = delayParams:match("(%S+)%s+(%S+)")
            
            if min and max then
                min = tonumber(min)
                max = tonumber(max)
                
                if min and max and min >= 0 and max >= min then
                    settings.global.dispels.minDelay = min
                    settings.global.dispels.maxDelay = max
                    self:SaveSettings()
                    print(string.format("|cFF00FFFF[Advanced Ability Control]|r Dispel delay set to %.2f-%.2f seconds", min, max))
                else
                    print("|cFFFF0000[Advanced Ability Control]|r Invalid delay values. Use format: dispel delay <min> <max>")
                end
            else
                print("|cFFFF0000[Advanced Ability Control]|r Invalid delay format. Use format: dispel delay <min> <max>")
            end
        else
            print("|cFF00FFFF[Advanced Ability Control]|r Dispel commands:")
            print("  /abilitycontrol dispel toggle/enable/disable")
            print("  /abilitycontrol dispel delay <min> <max>")
        end
    elseif command == "cc" then
        if param == "toggle" or param == "enable" or param == "disable" then
            if param == "toggle" then
                settings.global.crowdControl.enabled = not settings.global.crowdControl.enabled
            elseif param == "enable" then
                settings.global.crowdControl.enabled = true
            elseif param == "disable" then
                settings.global.crowdControl.enabled = false
            end
            
            self:SaveSettings()
            print(string.format("|cFF00FFFF[Advanced Ability Control]|r Crowd Control %s", settings.global.crowdControl.enabled and "enabled" or "disabled"))
        elseif param:match("^delay%s+(.+)$") then
            local delayParams = param:match("^delay%s+(.+)$")
            local min, max = delayParams:match("(%S+)%s+(%S+)")
            
            if min and max then
                min = tonumber(min)
                max = tonumber(max)
                
                if min and max and min >= 0 and max >= min then
                    settings.global.crowdControl.minDelay = min
                    settings.global.crowdControl.maxDelay = max
                    self:SaveSettings()
                    print(string.format("|cFF00FFFF[Advanced Ability Control]|r CC delay set to %.2f-%.2f seconds", min, max))
                else
                    print("|cFFFF0000[Advanced Ability Control]|r Invalid delay values. Use format: cc delay <min> <max>")
                end
            else
                print("|cFFFF0000[Advanced Ability Control]|r Invalid delay format. Use format: cc delay <min> <max>")
            end
        elseif param:match("^type%s+(%S+)%s+(%S+)$") then
            local ccType, state = param:match("^type%s+(%S+)%s+(%S+)$")
            
            -- Check if the CC type exists
            if settings.global.crowdControl.enabledTypes[string.upper(ccType)] ~= nil then
                local enabled = (state == "enable" or state == "on" or state == "true")
                settings.global.crowdControl.enabledTypes[string.upper(ccType)] = enabled
                self:SaveSettings()
                print(string.format("|cFF00FFFF[Advanced Ability Control]|r CC type %s %s", ccType, enabled and "enabled" or "disabled"))
            else
                print("|cFFFF0000[Advanced Ability Control]|r Invalid CC type. Valid types: stun, root, silence, incapacitate, disorient, fear, sleep, cyclone, banish, horror, taunt")
            end
        else
            print("|cFF00FFFF[Advanced Ability Control]|r CC commands:")
            print("  /abilitycontrol cc toggle/enable/disable")
            print("  /abilitycontrol cc delay <min> <max>")
            print("  /abilitycontrol cc type <type> <enable|disable>")
        end
    elseif command == "exclude" or command == "blacklist" then
        if not param or param == "" then
            print("|cFF00FFFF[Advanced Ability Control]|r Exclude commands:")
            print("  /abilitycontrol exclude interrupt <spellId>")
            print("  /abilitycontrol exclude dispel <spellId>")
            print("  /abilitycontrol exclude cc <spellId>")
            return
        end
        
        local category, spellId = param:match("(%S+)%s+(%d+)")
        if not category or not spellId then
            print("|cFFFF0000[Advanced Ability Control]|r Invalid exclude format. Use format: exclude <category> <spellId>")
            return
        end
        
        spellId = tonumber(spellId)
        if not spellId then
            print("|cFFFF0000[Advanced Ability Control]|r Invalid spell ID")
            return
        end
        
        if category == "interrupt" or category == "interrupts" then
            exclusionLists.interrupts[spellId] = true
            settings.spellLists.interrupts.alwaysExclude[tostring(spellId)] = true
            print(string.format("|cFF00FFFF[Advanced Ability Control]|r Added spell %d (%s) to interrupt exclusion list", spellId, GetSpellInfo(spellId) or "Unknown"))
        elseif category == "dispel" or category == "dispels" then
            exclusionLists.dispels[spellId] = true
            settings.spellLists.dispels.alwaysExclude[tostring(spellId)] = true
            print(string.format("|cFF00FFFF[Advanced Ability Control]|r Added spell %d (%s) to dispel exclusion list", spellId, GetSpellInfo(spellId) or "Unknown"))
        elseif category == "cc" then
            exclusionLists.crowdControl[spellId] = true
            settings.spellLists.crowdControl.alwaysExclude[tostring(spellId)] = true
            print(string.format("|cFF00FFFF[Advanced Ability Control]|r Added spell %d (%s) to CC exclusion list", spellId, GetSpellInfo(spellId) or "Unknown"))
        else
            print("|cFFFF0000[Advanced Ability Control]|r Invalid category. Valid categories: interrupt, dispel, cc")
            return
        end
        
        self:SaveSettings()
    elseif command == "include" or command == "whitelist" then
        if not param or param == "" then
            print("|cFF00FFFF[Advanced Ability Control]|r Include commands:")
            print("  /abilitycontrol include interrupt <spellId>")
            print("  /abilitycontrol include dispel <spellId>")
            print("  /abilitycontrol include cc <spellId>")
            return
        end
        
        local category, spellId = param:match("(%S+)%s+(%d+)")
        if not category or not spellId then
            print("|cFFFF0000[Advanced Ability Control]|r Invalid include format. Use format: include <category> <spellId>")
            return
        end
        
        spellId = tonumber(spellId)
        if not spellId then
            print("|cFFFF0000[Advanced Ability Control]|r Invalid spell ID")
            return
        end
        
        if category == "interrupt" or category == "interrupts" then
            inclusionLists.interrupts[spellId] = true
            settings.spellLists.interrupts.alwaysInclude[tostring(spellId)] = true
            print(string.format("|cFF00FFFF[Advanced Ability Control]|r Added spell %d (%s) to interrupt inclusion list", spellId, GetSpellInfo(spellId) or "Unknown"))
        elseif category == "dispel" or category == "dispels" then
            inclusionLists.dispels[spellId] = true
            settings.spellLists.dispels.alwaysInclude[tostring(spellId)] = true
            print(string.format("|cFF00FFFF[Advanced Ability Control]|r Added spell %d (%s) to dispel inclusion list", spellId, GetSpellInfo(spellId) or "Unknown"))
        elseif category == "cc" then
            inclusionLists.crowdControl[spellId] = true
            settings.spellLists.crowdControl.alwaysInclude[tostring(spellId)] = true
            print(string.format("|cFF00FFFF[Advanced Ability Control]|r Added spell %d (%s) to CC inclusion list", spellId, GetSpellInfo(spellId) or "Unknown"))
        else
            print("|cFFFF0000[Advanced Ability Control]|r Invalid category. Valid categories: interrupt, dispel, cc")
            return
        end
        
        self:SaveSettings()
    elseif command == "debug" then
        debugMode = not debugMode
        settings.debugMode = debugMode
        self:SaveSettings()
        print(string.format("|cFF00FFFF[Advanced Ability Control]|r Debug mode %s", debugMode and "enabled" or "disabled"))
    elseif command == "scan" then
        self:ScanPlayerAbilities()
        print("|cFF00FFFF[Advanced Ability Control]|r Rescanned player abilities")
        print("Found " .. #abilityRegistry.interrupts .. " interrupts")
        print("Found " .. #abilityRegistry.dispels .. " dispels")
        print("Found " .. #abilityRegistry.crowdControl .. " crowd control abilities")
    elseif command == "status" or command == "info" then
        self:PrintStatus()
    else
        print("|cFF00FFFF[Advanced Ability Control]|r Commands:")
        print("  /abilitycontrol - Open settings panel")
        print("  /abilitycontrol toggle/enable/disable - Toggle the module")
        print("  /abilitycontrol interrupt ... - Interrupt commands")
        print("  /abilitycontrol dispel ... - Dispel commands")
        print("  /abilitycontrol cc ... - Crowd control commands")
        print("  /abilitycontrol exclude ... - Add spell to exclusion list")
        print("  /abilitycontrol include ... - Add spell to inclusion list")
        print("  /abilitycontrol debug - Toggle debug mode")
        print("  /abilitycontrol scan - Rescan player abilities")
        print("  /abilitycontrol status - Show current status")
    end
}

-- Print status information
function AdvancedAbilityControl:PrintStatus()
    print("|cFF00FFFF[Advanced Ability Control]|r Status:")
    print("Module enabled: " .. (settings.enabled and "|cFF00FF00Yes|r" or "|cFFFF0000No|r"))
    print("Debug mode: " .. (debugMode and "|cFF00FF00Yes|r" or "|cFFFF0000No|r"))
    print("")
    
    print("Interrupts: " .. (settings.global.interrupts.enabled and "|cFF00FF00Enabled|r" or "|cFFFF0000Disabled|r"))
    print("  Timing mode: " .. settings.global.interrupts.timingMode)
    print("  Delay: " .. settings.global.interrupts.minDelay .. " - " .. settings.global.interrupts.maxDelay .. " seconds")
    print("  Available abilities: " .. #abilityRegistry.interrupts)
    print("")
    
    print("Dispels: " .. (settings.global.dispels.enabled and "|cFF00FF00Enabled|r" or "|cFFFF0000Disabled|r"))
    print("  Timing mode: " .. settings.global.dispels.timingMode)
    print("  Delay: " .. settings.global.dispels.minDelay .. " - " .. settings.global.dispels.maxDelay .. " seconds")
    print("  Available abilities: " .. #abilityRegistry.dispels)
    print("")
    
    print("Crowd Control: " .. (settings.global.crowdControl.enabled and "|cFF00FF00Enabled|r" or "|cFFFF0000Disabled|r"))
    print("  Timing mode: " .. settings.global.crowdControl.timingMode)
    print("  Delay: " .. settings.global.crowdControl.minDelay .. " - " .. settings.global.crowdControl.maxDelay .. " seconds")
    print("  Available abilities: " .. #abilityRegistry.crowdControl)
    print("")
    
    print("Current Instance Type: " .. activeInstanceType)
    print("Active Encounter: " .. (activeEncounterID and tostring(activeEncounterID) or "None"))
    print("Pending Actions: " .. #pendingActions)
}

-- Create settings UI panel
function AdvancedAbilityControl:CreateSettingsUI(panel)
    -- This function would create a comprehensive settings UI
    -- Since it would be quite large, we'll stub it out for now
    -- In a real implementation, this would create all the UI widgets for the settings panel
    
    -- Example structure:
    -- - Tab for Global Settings
    -- - Tab for Interrupts
    -- - Tab for Dispels
    -- - Tab for Crowd Control
    -- - Tab for Spell Lists
    -- - Tab for Encounter Rules
}

-- Helper function: Ensure all defaults exist
function AdvancedAbilityControl:EnsureDefaults(target, source)
    if type(target) ~= "table" or type(source) ~= "table" then
        return source
    end
    
    for k, v in pairs(source) do
        if target[k] == nil then
            target[k] = self:DeepCopy(v)
        elseif type(v) == "table" then
            target[k] = self:EnsureDefaults(target[k], v)
        end
    end
    
    return target
}

-- Helper function: Deep copy a table
function AdvancedAbilityControl:DeepCopy(src)
    if type(src) ~= "table" then return src end
    
    local copy = {}
    for k, v in pairs(src) do
        if type(v) == "table" then
            copy[k] = self:DeepCopy(v)
        else
            copy[k] = v
        end
    end
    
    return copy
}

-- Debug print
function AdvancedAbilityControl:Debug(...)
    if debugMode then
        print("|cFF00FFFF[WR-AC Debug]|r", ...)
    end
}

-- Initialize the module
AdvancedAbilityControl:Initialize()

return AdvancedAbilityControl