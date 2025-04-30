------------------------------------------
-- WindrunnerRotations - Warlock Class Module
-- Author: VortexQ8
-- The War Within Season 2
------------------------------------------

local addonName, WR = ...
local WarlockModule = {}
WR.Warlock = WarlockModule

-- Dependencies
local API = WR.API
local ConfigRegistry = WR.ConfigRegistry
local RotationManager = WR.RotationManager
local ErrorHandler = WR.ErrorHandler
local CombatAnalysis = WR.CombatAnalysis
local AntiDetectionSystem = WR.AntiDetectionSystem
local PvPManager = WR.PvPManager

-- Warlock constants
local CLASS_ID = 9 -- Warlock class ID
local SPEC_AFFLICTION = 265
local SPEC_DEMONOLOGY = 266
local SPEC_DESTRUCTION = 267

-- Current player data
local playerSpec = 0
local isEnabled = true
local inCombat = false

-- Spell IDs for Affliction Warlock (The War Within, Season 2)
local AFFLICTION_SPELLS = {
    -- Core abilities
    AGONY = 980,
    CORRUPTION = 172,
    UNSTABLE_AFFLICTION = 316099,
    MALEFIC_RAPTURE = 324536,
    DRAIN_SOUL = 198590,
    SHADOW_BOLT = 686,
    SEED_OF_CORRUPTION = 27243,
    HAUNT = 48181,
    PHANTOM_SINGULARITY = 205179,
    VILE_TAINT = 278350,
    SOUL_ROT = 325640,
    
    -- Defensive & utility
    UNENDING_RESOLVE = 104773,
    DARK_PACT = 108416,
    DEMONIC_GATEWAY = 111771,
    DEMONIC_CIRCLE = 48018,
    DEMONIC_CIRCLE_TELEPORT = 48020,
    DRAIN_LIFE = 234153,
    HEALTHSTONE = 5512,
    MORTAL_COIL = 6789,
    SHADOWFURY = 30283,
    
    -- Talents
    SUMMON_DARKGLARE = 205180,
    INEVITABLE_DEMISE = 334319,
    SIPHON_LIFE = 63106,
    SOUL_SWAP = 386951,
    GRIMOIRE_OF_SACRIFICE = 108503,
    ABSOLUTE_CORRUPTION = 196103,
    SHADOW_EMBRACE = 32388,
    
    -- Pet summons
    SUMMON_IMP = 688,
    SUMMON_VOIDWALKER = 697,
    SUMMON_FELHUNTER = 691,
    SUMMON_SUCCUBUS = 712,
    SUMMON_FELGUARD = 30146,
    
    -- Season 2 Abilities
    WICKED_BARGAIN = 423470, -- New in TWW Season 2
    DOOM_BRAND = 423471, -- New in TWW Season 2
    TORMENTED_CRESCENDO = 423463, -- New in TWW Season 2
    GRAND_WARLOCKS_DESIGN = 387084, -- New in TWW Season 2
    SOUL_STRIKE = 264057, -- Enhanced in TWW Season 2
    CREEPING_DEATH = 264000, -- Enhanced in TWW Season 2
    DREAD_TOUCH = 389775, -- New in TWW Season 2
    WRATH_OF_CONSUMPTION = 387065, -- New in TWW Season 2
    PANDEMIC_INVOCATION = 386759, -- New in TWW Season 2
    SHADOW_RIFT = 389997, -- New in TWW Season 2
    SOUL_FLAME = 199471, -- Enhanced in TWW Season 2
    DOOM_BLOSSOM = 416621, -- New in TWW Season 2
    SOUL_TAP = 387073, -- New in TWW Season 2
    SACROLASHS_DARK_STRIKE = 386986, -- New in TWW Season 2
    
    -- Misc
    CREATE_HEALTHSTONE = 6201,
    FEAR = 5782,
    BANISH = 710,
    CURSE_OF_TONGUES = 1714,
    CURSE_OF_WEAKNESS = 702,
    CURSE_OF_EXHAUSTION = 334275,
    SOULSTONE = 20707
}

-- Spell IDs for Demonology Warlock (The War Within, Season 2)
local DEMONOLOGY_SPELLS = {
    -- Core abilities
    SHADOW_BOLT = 686,
    HAND_OF_GULDAN = 105174,
    CALL_DREADSTALKERS = 104316,
    DEMONBOLT = 264178,
    IMPLOSION = 196277,
    DEMONIC_STRENGTH = 267171,
    BILESCOURGE_BOMBERS = 267211,
    POWER_SIPHON = 264130,
    SUMMON_VILEFIEND = 264119,
    GRIMOIRE_FELGUARD = 111898,
    NETHER_PORTAL = 267217,
    SUMMON_DEMONIC_TYRANT = 265187,
    
    -- Defensive & utility
    UNENDING_RESOLVE = 104773,
    DARK_PACT = 108416,
    DEMONIC_GATEWAY = 111771,
    DEMONIC_CIRCLE = 48018,
    DEMONIC_CIRCLE_TELEPORT = 48020,
    DRAIN_LIFE = 234153,
    HEALTHSTONE = 5512,
    SHADOWFURY = 30283,
    
    -- Talents
    DOOM = 603,
    SOUL_STRIKE = 264057,
    SUMMON_DEMONIC_TYRANT = 265187,
    FROM_THE_SHADOWS = 267170,
    DEMONIC_CALLING = 205145,
    DEMONIC_CORE = 264173,
    INNER_DEMONS = 267216,
    
    -- Pet summons
    SUMMON_IMP = 688,
    SUMMON_VOIDWALKER = 697,
    SUMMON_FELHUNTER = 691,
    SUMMON_SUCCUBUS = 712,
    SUMMON_FELGUARD = 30146,
    
    -- Season 2 Abilities
    THAL_KIELS_CONSUMPTION = 387391, -- New in TWW Season 2
    BLASPHEMY = 387169, -- New in TWW Season 2
    FORBIDDEN_KNOWLEDGE = 387172, -- New in TWW Season 2
    SOUL_BOND = 386333, -- New in TWW Season 2
    UMBRAL_BLAZE = 405798, -- New in TWW Season 2
    GUILLOTINE = 386833, -- New in TWW Season 2
    FEL_MIGHT = 387601, -- New in TWW Season 2
    SOULBURN_DEMONIC_CIRCLE = 386164, -- New in TWW Season 2
    THE_EXPENDABLES = 387600, -- New in TWW Season 2
    DEMONIC_PACT = 387494, -- New in TWW Season 2
    CARNIVOROUS_STALKERS = 387522, -- New in TWW Season 2
    INFERNAL_COMMAND = 387549, -- New in TWW Season 2
    GRIMOIRE_OF_SYNERGY = 171975, -- Enhanced in TWW Season 2
    DOOM_BRAND = 423471, -- New in TWW Season 2
    
    -- Misc
    CREATE_HEALTHSTONE = 6201,
    FEAR = 5782,
    BANISH = 710,
    CURSE_OF_TONGUES = 1714,
    CURSE_OF_WEAKNESS = 702,
    CURSE_OF_EXHAUSTION = 334275,
    SOULSTONE = 20707
}

-- Spell IDs for Destruction Warlock (The War Within, Season 2)
local DESTRUCTION_SPELLS = {
    -- Core abilities
    INCINERATE = 29722,
    CHAOS_BOLT = 116858,
    IMMOLATE = 348,
    CONFLAGRATE = 17962,
    HAVOC = 80240,
    RAIN_OF_FIRE = 5740,
    CHANNEL_DEMONFIRE = 196447,
    SUMMON_INFERNAL = 1122,
    CATACLYSM = 152108,
    SOUL_FIRE = 6353,
    
    -- Defensive & utility
    UNENDING_RESOLVE = 104773,
    DARK_PACT = 108416,
    DEMONIC_GATEWAY = 111771,
    DEMONIC_CIRCLE = 48018,
    DEMONIC_CIRCLE_TELEPORT = 48020,
    DRAIN_LIFE = 234153,
    HEALTHSTONE = 5512,
    SHADOWFURY = 30283,
    
    -- Talents
    SHADOWBURN = 17877,
    ERADICATION = 196412,
    FIRE_AND_BRIMSTONE = 196408,
    BACKDRAFT = 196406,
    INFERNO = 270545,
    GRIMOIRE_OF_SACRIFICE = 108503,
    
    -- Pet summons
    SUMMON_IMP = 688,
    SUMMON_VOIDWALKER = 697,
    SUMMON_FELHUNTER = 691,
    SUMMON_SUCCUBUS = 712,
    SUMMON_FELGUARD = 30146,
    
    -- Season 2 Abilities
    DIMENSIONAL_RIFT = 387976, -- New in TWW Season 2
    MAYHEM = 387593, -- New in TWW Season 2
    AVATAR_OF_DESTRUCTION = 387159, -- New in TWW Season 2
    BURN_TO_ASHES = 387153, -- New in TWW Season 2
    INFERNAL_COMMAND = 387549, -- New in TWW Season 2
    SOUL_FIRE_CONDUIT = 422051, -- New in TWW Season 2
    CHAOS_BOLD_FURY = 387550, -- New in TWW Season 2
    RAGING_DEMONFIRE = 387214, -- New in TWW Season 2
    PYROGENICS = 387095, -- New in TWW Season 2
    ASHEN_REMAINS = 387252, -- New in TWW Season 2
    CONFLAGRATION_OF_CHAOS = 387108, -- New in TWW Season 2
    ROARING_BLAZE = 205184, -- Enhanced in TWW Season 2
    BACKDRAFT = 196406, -- Enhanced in TWW Season 2
    CRASHING_CHAOS = 387355, -- New in TWW Season 2
    INTERNAL_COMBUSTION = 266134, -- Enhanced in TWW Season 2
    
    -- Misc
    CREATE_HEALTHSTONE = 6201,
    FEAR = 5782,
    BANISH = 710,
    CURSE_OF_TONGUES = 1714,
    CURSE_OF_WEAKNESS = 702,
    CURSE_OF_EXHAUSTION = 334275,
    SOULSTONE = 20707
}

-- Important buffs to track
local BUFFS = {
    INEVITABLE_DEMISE = 334320,
    DRAIN_SOUL = 198590,
    DEMONIC_CORE = 264173,
    NIGHTFALL = 264571,
    BACKDRAFT = 117828,
    DEVOUR_MAGIC = 19505,
    GRIMOIRE_OF_SACRIFICE = 196099,
    DARK_SOUL_MISERY = 113860,
    DARK_SOUL_INSTABILITY = 113858,
    DARK_PACT = 108416,
    UNENDING_RESOLVE = 104773,
    BURNING_RUSH = 111400,
    SOUL_LEECH = 108370,
    HEALTHSTONE_COOLDOWN = 6262,
    DEMONIC_CIRCLE = 48018
}

-- Important debuffs to track
local DEBUFFS = {
    AGONY = 980,
    CORRUPTION = 146739,
    UNSTABLE_AFFLICTION = 316099,
    PHANTOM_SINGULARITY = 205179,
    VILE_TAINT = 278350,
    HAUNT = 48181,
    SHADOW_EMBRACE = 32390,
    DOOM = 603,
    IMMOLATE = 157736,
    HAVOC = 80240,
    ERADICATION = 196414,
    CURSE_OF_WEAKNESS = 702,
    CURSE_OF_TONGUES = 1714,
    CURSE_OF_EXHAUSTION = 334275,
    FEAR = 5782,
    BANISH = 710
}

-- Initialize the Warlock module
function WarlockModule:Initialize()
    -- Register settings
    self:RegisterSettings()
    
    -- Register events
    self:RegisterEvents()
    
    -- Register rotations
    self:RegisterRotations()
    
    API.PrintDebug("Warlock module initialized")
    return true
end

-- Register settings
function WarlockModule:RegisterSettings()
    ConfigRegistry:RegisterSettings("Warlock", {
        generalSettings = {
            enabled = {
                displayName = "Enable Warlock Module",
                description = "Enable the Warlock module for all specs",
                type = "toggle",
                default = true
            },
            useDefensives = {
                displayName = "Use Defensive Abilities",
                description = "Automatically use defensive abilities when appropriate",
                type = "toggle",
                default = true
            },
            useInterrupts = {
                displayName = "Use Interrupts",
                description = "Automatically interrupt enemy casts when appropriate",
                type = "toggle",
                default = true
            },
            autoSummonPet = {
                displayName = "Auto Summon Pet",
                description = "Automatically summon your pet if missing",
                type = "toggle",
                default = true
            },
            preferredPet = {
                displayName = "Preferred Pet",
                description = "Default pet to summon",
                type = "dropdown",
                options = {"Imp", "Voidwalker", "Felhunter", "Succubus", "Felguard (Demonology only)"},
                default = "Imp"
            },
            createHealthstone = {
                displayName = "Create Healthstone",
                description = "Automatically create a Healthstone if missing",
                type = "toggle",
                default = true
            },
            useHealthstone = {
                displayName = "Use Healthstone",
                description = "Automatically use Healthstone at low health",
                type = "toggle",
                default = true
            },
            healthstoneThreshold = {
                displayName = "Healthstone Health Threshold",
                description = "Health percentage to use Healthstone",
                type = "slider",
                min = 10,
                max = 60,
                step = 5,
                default = 35
            }
        },
        afflictionSettings = {
            -- Core settings
            maintainDots = {
                displayName = "Maintain DoTs",
                description = "Automatically maintain DoTs on targets",
                type = "toggle",
                default = true
            },
            refreshDotsThreshold = {
                displayName = "Refresh DoTs Threshold",
                description = "Remaining time threshold to refresh DoTs (seconds)",
                type = "slider",
                min = 1,
                max = 5,
                step = 0.5,
                default = 3
            },
            aoeThreshold = {
                displayName = "AoE Threshold",
                description = "Number of targets to switch to AoE rotation",
                type = "slider",
                min = 2,
                max = 6,
                step = 1,
                default = 3
            },
            useSoulRot = {
                displayName = "Use Soul Rot",
                description = "Use Soul Rot in rotation (if covenant ability is available)",
                type = "toggle",
                default = true
            },
            useSeedOfCorruption = {
                displayName = "Use Seed of Corruption",
                description = "Use Seed of Corruption for AoE",
                type = "toggle",
                default = true
            },
            prioritizeAgony = {
                displayName = "Prioritize Agony",
                description = "Apply Agony before other DoTs in multi-target situations",
                type = "toggle",
                default = true
            },
            
            -- Season 2 abilities
            useWickedBargain = {
                displayName = "Use Wicked Bargain (TWW S2)",
                description = "Use Wicked Bargain for enhanced Darkglare duration",
                type = "toggle",
                default = true
            },
            useDoomBrand = {
                displayName = "Use Doom Brand (TWW S2)",
                description = "Use Doom Brand for enhanced DoT damage",
                type = "toggle",
                default = true
            },
            useTormentedCrescendo = {
                displayName = "Use Tormented Crescendo (TWW S2)",
                description = "Use Tormented Crescendo for free Malefic Raptures",
                type = "toggle",
                default = true
            },
            useGrandWarlocksDesign = {
                displayName = "Use Grand Warlock's Design (TWW S2)",
                description = "Use Grand Warlock's Design for enhanced Soul Shards generation",
                type = "toggle",
                default = true
            },
            useSoulStrike = {
                displayName = "Use Soul Strike (TWW S2)",
                description = "Use Soul Strike for enhanced burst",
                type = "toggle",
                default = true
            },
            useCreepingDeath = {
                displayName = "Use Creeping Death (TWW S2)",
                description = "Use Creeping Death for faster DoT ticking",
                type = "toggle",
                default = true
            },
            useDreadTouch = {
                displayName = "Use Dread Touch (TWW S2)",
                description = "Use Dread Touch for increased Agony damage",
                type = "toggle",
                default = true
            },
            useWrathOfConsumption = {
                displayName = "Use Wrath of Consumption (TWW S2)",
                description = "Use Wrath of Consumption for increased damage after enemy deaths",
                type = "toggle",
                default = true
            },
            usePandemicInvocation = {
                displayName = "Use Pandemic Invocation (TWW S2)",
                description = "Use Pandemic Invocation for enhanced DoT refreshing",
                type = "toggle",
                default = true
            },
            useShadowRift = {
                displayName = "Use Shadow Rift (TWW S2)",
                description = "Use Shadow Rift for additional AoE damage",
                type = "toggle",
                default = true
            },
            useSoulTap = {
                displayName = "Use Soul Tap (TWW S2)",
                description = "Use Soul Tap for additional healing during Drain Soul",
                type = "toggle",
                default = true
            },
            darkglareUsage = {
                displayName = "Darkglare Usage (TWW S2)",
                description = "How to use Summon Darkglare",
                type = "dropdown",
                options = {
                    "Maximum DoTs", 
                    "On Cooldown", 
                    "With Burst CDs", 
                    "Manual Only"
                },
                default = "Maximum DoTs"
            },
            soulSwapStrategy = {
                displayName = "Soul Swap Strategy (TWW S2)",
                description = "How to use Soul Swap for DoT applications",
                type = "dropdown",
                options = {
                    "Priority Target Only", 
                    "Spread All DoTs", 
                    "Focus Target Only", 
                    "Manual Only"
                },
                default = "Priority Target Only"
            }
        },
        demonologySettings = {
            impsBeforeImplosion = {
                displayName = "Wild Imps Before Implosion",
                description = "Minimum Wild Imps to have before using Implosion",
                type = "slider",
                min = 3,
                max = 9,
                step = 1,
                default = 6
            },
            delayTyrantBuild = {
                displayName = "Delay Tyrant Build",
                description = "Build up Demons before using Summon Demonic Tyrant",
                type = "toggle",
                default = true
            },
            prioritizeTyrantCooldowns = {
                displayName = "Prioritize Tyrant Cooldowns",
                description = "Save cooldowns for Tyrant burst window",
                type = "toggle",
                default = true
            },
            aoeThreshold = {
                displayName = "AoE Threshold",
                description = "Number of targets to switch to AoE rotation",
                type = "slider",
                min = 2,
                max = 6,
                step = 1,
                default = 3
            },
            useDoom = {
                displayName = "Use Doom",
                description = "Maintain Doom on targets",
                type = "toggle",
                default = true
            },
            useDemonicStrength = {
                displayName = "Use Demonic Strength",
                description = "Use Demonic Strength on Felguard",
                type = "toggle",
                default = true
            }
        },
        destructionSettings = {
            immolateRefreshThreshold = {
                displayName = "Immolate Refresh Threshold",
                description = "Remaining time threshold to refresh Immolate (seconds)",
                type = "slider",
                min = 1,
                max = 5,
                step = 0.5,
                default = 3
            },
            havocTarget = {
                displayName = "Havoc Target",
                description = "How to select Havoc target",
                type = "dropdown",
                options = {"Auto", "Focus", "Mouseover", "None"},
                default = "Auto"
            },
            useHavoc = {
                displayName = "Use Havoc",
                description = "Use Havoc for cleave damage",
                type = "toggle",
                default = true
            },
            poolShardsForCataclysm = {
                displayName = "Pool Shards for Cataclysm",
                description = "Pool Soul Shards for Cataclysm in AoE",
                type = "toggle",
                default = true
            },
            aoeThreshold = {
                displayName = "AoE Threshold",
                description = "Number of targets to switch to AoE rotation",
                type = "slider",
                min = 2,
                max = 6,
                step = 1,
                default = 3
            },
            useSummonInfernal = {
                displayName = "Use Summon Infernal",
                description = "Use Summon Infernal in combat",
                type = "toggle",
                default = true
            }
        }
    })
    
    -- Add callback for settings changes
    ConfigRegistry:RegisterCallback("Warlock", function(settings)
        self:ApplySettings(settings)
    end)
}

-- Apply settings
function WarlockModule:ApplySettings(settings)
    -- Apply general settings
    isEnabled = settings.generalSettings.enabled
}

-- Register events
function WarlockModule:RegisterEvents()
    -- Register for specialization changed event
    API.RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", function(unit)
        if unit == "player" then
            self:OnSpecializationChanged()
        end
    end)
    
    -- Register for entering combat event
    API.RegisterEvent("PLAYER_REGEN_DISABLED", function()
        inCombat = true
    end)
    
    -- Register for leaving combat event
    API.RegisterEvent("PLAYER_REGEN_ENABLED", function()
        inCombat = false
    end)
    
    -- Update specialization on initialization
    self:OnSpecializationChanged()
}

-- On specialization changed
function WarlockModule:OnSpecializationChanged()
    -- Get current spec ID
    playerSpec = API.GetActiveSpecID()
    
    API.PrintDebug("Warlock specialization changed: " .. playerSpec)
    
    -- Ensure correct rotation is registered
    if playerSpec == SPEC_AFFLICTION then
        self:RegisterAfflictionRotation()
    elseif playerSpec == SPEC_DEMONOLOGY then
        self:RegisterDemonologyRotation()
    elseif playerSpec == SPEC_DESTRUCTION then
        self:RegisterDestructionRotation()
    end
}

-- Register rotations
function WarlockModule:RegisterRotations()
    -- Register spec-specific rotations
    self:RegisterAfflictionRotation()
    self:RegisterDemonologyRotation()
    self:RegisterDestructionRotation()
}

-- Register Affliction rotation
function WarlockModule:RegisterAfflictionRotation()
    RotationManager:RegisterRotation("WarlockAffliction", {
        id = "WarlockAffliction",
        name = "Warlock - Affliction",
        class = "WARLOCK",
        spec = SPEC_AFFLICTION,
        level = 10,
        description = "Affliction Warlock rotation for The War Within Season 2",
        author = "WindrunnerRotations",
        version = "1.0.0",
        rotation = function()
            return self:AfflictionRotation()
        end
    })
}

-- Register Demonology rotation
function WarlockModule:RegisterDemonologyRotation()
    RotationManager:RegisterRotation("WarlockDemonology", {
        id = "WarlockDemonology",
        name = "Warlock - Demonology",
        class = "WARLOCK",
        spec = SPEC_DEMONOLOGY,
        level = 10,
        description = "Demonology Warlock rotation for The War Within Season 2",
        author = "WindrunnerRotations",
        version = "1.0.0",
        rotation = function()
            return self:DemonologyRotation()
        end
    })
}

-- Register Destruction rotation
function WarlockModule:RegisterDestructionRotation()
    RotationManager:RegisterRotation("WarlockDestruction", {
        id = "WarlockDestruction",
        name = "Warlock - Destruction",
        class = "WARLOCK",
        spec = SPEC_DESTRUCTION,
        level = 10,
        description = "Destruction Warlock rotation for The War Within Season 2",
        author = "WindrunnerRotations",
        version = "1.0.0",
        rotation = function()
            return self:DestructionRotation()
        end
    })
}

-- Affliction rotation
function WarlockModule:AfflictionRotation()
    -- Check if we should execute
    if not self:ShouldExecuteRotation() then
        return nil
    end
    
    -- Get player and target
    local player = "player"
    local target = "target"
    
    -- Check if we have a target
    if not UnitExists(target) or not UnitCanAttack(player, target) or UnitIsDead(target) then
        return nil
    end
    
    -- Get settings
    local settings = ConfigRegistry:GetSettings("Warlock")
    
    -- Common Combat Variables
    local health, maxHealth, healthPercent = API.GetUnitHealth(player)
    local targetHealth, targetMaxHealth, targetHealthPercent = API.GetUnitHealth(target)
    local soulShards = API.GetUnitPower(player, Enum.PowerType.SoulShards)
    local enemies = API.GetEnemyCount(8)
    local aoeEnabled = settings.afflictionSettings.aoeThreshold <= enemies
    local hasSummonDarkglare = API.IsSpellKnown(AFFLICTION_SPELLS.SUMMON_DARKGLARE) and API.IsSpellUsable(AFFLICTION_SPELLS.SUMMON_DARKGLARE)
    
    -- Check for pet
    if settings.generalSettings.autoSummonPet and not UnitExists("pet") then
        -- Summon preferred pet based on settings
        local petType = settings.generalSettings.preferredPet
        local petSpellID
        
        if petType == "Imp" then
            petSpellID = AFFLICTION_SPELLS.SUMMON_IMP
        elseif petType == "Voidwalker" then
            petSpellID = AFFLICTION_SPELLS.SUMMON_VOIDWALKER
        elseif petType == "Felhunter" then
            petSpellID = AFFLICTION_SPELLS.SUMMON_FELHUNTER
        elseif petType == "Succubus" then
            petSpellID = AFFLICTION_SPELLS.SUMMON_SUCCUBUS
        elseif petType == "Felguard (Demonology only)" and playerSpec == SPEC_DEMONOLOGY then
            petSpellID = AFFLICTION_SPELLS.SUMMON_FELGUARD
        else
            petSpellID = AFFLICTION_SPELLS.SUMMON_IMP
        end
        
        if API.IsSpellKnown(petSpellID) and API.IsSpellUsable(petSpellID) then
            return {
                type = "spell",
                id = petSpellID,
                target = player
            }
        end
    end
    
    -- Create Healthstone if needed
    if settings.generalSettings.createHealthstone and 
       not GetItemCount(AFFLICTION_SPELLS.HEALTHSTONE, false, true) > 0 and
       API.IsSpellKnown(AFFLICTION_SPELLS.CREATE_HEALTHSTONE) and
       API.IsSpellUsable(AFFLICTION_SPELLS.CREATE_HEALTHSTONE) then
        return {
            type = "spell",
            id = AFFLICTION_SPELLS.CREATE_HEALTHSTONE,
            target = player
        }
    end
    
    -- Defensive abilities
    if settings.generalSettings.useDefensives then
        -- Use Healthstone
        if settings.generalSettings.useHealthstone and 
           healthPercent <= settings.generalSettings.healthstoneThreshold and
           GetItemCount(AFFLICTION_SPELLS.HEALTHSTONE, false, true) > 0 and
           not API.UnitHasBuff(player, BUFFS.HEALTHSTONE_COOLDOWN) then
            return {
                type = "item",
                id = AFFLICTION_SPELLS.HEALTHSTONE,
                target = player
            }
        end
        
        -- Unending Resolve at critical health
        if healthPercent < 30 and 
           API.IsSpellKnown(AFFLICTION_SPELLS.UNENDING_RESOLVE) and 
           API.IsSpellUsable(AFFLICTION_SPELLS.UNENDING_RESOLVE) then
            return {
                type = "spell",
                id = AFFLICTION_SPELLS.UNENDING_RESOLVE,
                target = player
            }
        end
        
        -- Dark Pact if available
        if healthPercent < 50 and 
           API.IsSpellKnown(AFFLICTION_SPELLS.DARK_PACT) and 
           API.IsSpellUsable(AFFLICTION_SPELLS.DARK_PACT) then
            return {
                type = "spell",
                id = AFFLICTION_SPELLS.DARK_PACT,
                target = player
            }
        end
        
        -- Drain Life at low health
        if healthPercent < 40 and 
           API.IsSpellKnown(AFFLICTION_SPELLS.DRAIN_LIFE) and 
           API.IsSpellUsable(AFFLICTION_SPELLS.DRAIN_LIFE) then
            return {
                type = "spell",
                id = AFFLICTION_SPELLS.DRAIN_LIFE,
                target = target
            }
        end
    end
    
    -- Maintain DoTs if setting enabled
    if settings.afflictionSettings.maintainDots then
        -- Agony
        if not API.UnitHasDebuff(target, DEBUFFS.AGONY) and
           API.IsSpellKnown(AFFLICTION_SPELLS.AGONY) and 
           API.IsSpellUsable(AFFLICTION_SPELLS.AGONY) then
            return {
                type = "spell",
                id = AFFLICTION_SPELLS.AGONY,
                target = target
            }
        end
        
        -- Corruption (Absolute Corruption talent might make this permanent)
        if not API.UnitHasDebuff(target, DEBUFFS.CORRUPTION) and
           API.IsSpellKnown(AFFLICTION_SPELLS.CORRUPTION) and 
           API.IsSpellUsable(AFFLICTION_SPELLS.CORRUPTION) then
            return {
                type = "spell",
                id = AFFLICTION_SPELLS.CORRUPTION,
                target = target
            }
        end
        
        -- Unstable Affliction
        if not API.UnitHasDebuff(target, DEBUFFS.UNSTABLE_AFFLICTION) and
           API.IsSpellKnown(AFFLICTION_SPELLS.UNSTABLE_AFFLICTION) and 
           API.IsSpellUsable(AFFLICTION_SPELLS.UNSTABLE_AFFLICTION) then
            return {
                type = "spell",
                id = AFFLICTION_SPELLS.UNSTABLE_AFFLICTION,
                target = target
            }
        end
        
        -- Siphon Life if talented
        if API.IsSpellKnown(AFFLICTION_SPELLS.SIPHON_LIFE) and 
           API.IsSpellUsable(AFFLICTION_SPELLS.SIPHON_LIFE) then
            return {
                type = "spell",
                id = AFFLICTION_SPELLS.SIPHON_LIFE,
                target = target
            }
        end
    end
    
    -- Offensive cooldowns
    if inCombat then
        -- Phantom Singularity
        if API.IsSpellKnown(AFFLICTION_SPELLS.PHANTOM_SINGULARITY) and 
           API.IsSpellUsable(AFFLICTION_SPELLS.PHANTOM_SINGULARITY) then
            return {
                type = "spell",
                id = AFFLICTION_SPELLS.PHANTOM_SINGULARITY,
                target = target
            }
        end
        
        -- Vile Taint / Sow the Seeds with sould shards
        if soulShards >= 1 and
           API.IsSpellKnown(AFFLICTION_SPELLS.VILE_TAINT) and 
           API.IsSpellUsable(AFFLICTION_SPELLS.VILE_TAINT) then
            return {
                type = "spell",
                id = AFFLICTION_SPELLS.VILE_TAINT,
                target = target
            }
        end
        
        -- Soul Rot if covenant ability
        if settings.afflictionSettings.useSoulRot and
           API.IsSpellKnown(AFFLICTION_SPELLS.SOUL_ROT) and 
           API.IsSpellUsable(AFFLICTION_SPELLS.SOUL_ROT) then
            return {
                type = "spell",
                id = AFFLICTION_SPELLS.SOUL_ROT,
                target = target
            }
        end
        
        -- Summon Darkglare when DoTs are applied
        if hasSummonDarkglare and
           API.UnitHasDebuff(target, DEBUFFS.AGONY) and
           API.UnitHasDebuff(target, DEBUFFS.CORRUPTION) and
           API.UnitHasDebuff(target, DEBUFFS.UNSTABLE_AFFLICTION) then
            return {
                type = "spell",
                id = AFFLICTION_SPELLS.SUMMON_DARKGLARE,
                target = player
            }
        end
    end
    
    -- AoE rotation
    if aoeEnabled and enemies >= 3 and settings.afflictionSettings.useSeedOfCorruption then
        -- Seed of Corruption for AoE
        if soulShards >= 1 and
           API.IsSpellKnown(AFFLICTION_SPELLS.SEED_OF_CORRUPTION) and 
           API.IsSpellUsable(AFFLICTION_SPELLS.SEED_OF_CORRUPTION) and
           not API.UnitHasDebuff(target, DEBUFFS.CORRUPTION) then
            return {
                type = "spell",
                id = AFFLICTION_SPELLS.SEED_OF_CORRUPTION,
                target = target
            }
        end
    end
    
    -- Core rotation
    -- Malefic Rapture when DoTs are up and we have Soul Shards
    if soulShards >= 1 and
       API.UnitHasDebuff(target, DEBUFFS.AGONY) and
       API.UnitHasDebuff(target, DEBUFFS.UNSTABLE_AFFLICTION) and
       API.IsSpellKnown(AFFLICTION_SPELLS.MALEFIC_RAPTURE) and 
       API.IsSpellUsable(AFFLICTION_SPELLS.MALEFIC_RAPTURE) then
        return {
            type = "spell",
            id = AFFLICTION_SPELLS.MALEFIC_RAPTURE,
            target = target
        }
    end
    
    -- Haunt if talented and available
    if soulShards >= 1 and
       API.IsSpellKnown(AFFLICTION_SPELLS.HAUNT) and 
       API.IsSpellUsable(AFFLICTION_SPELLS.HAUNT) and
       not API.UnitHasDebuff(target, DEBUFFS.HAUNT) then
        return {
            type = "spell",
            id = AFFLICTION_SPELLS.HAUNT,
            target = target
        }
    end
    
    -- Drain Soul as filler if talented
    if API.IsSpellKnown(AFFLICTION_SPELLS.DRAIN_SOUL) and 
       API.IsSpellUsable(AFFLICTION_SPELLS.DRAIN_SOUL) then
        return {
            type = "spell",
            id = AFFLICTION_SPELLS.DRAIN_SOUL,
            target = target
        }
    end
    
    -- Shadow Bolt as filler
    if API.IsSpellKnown(AFFLICTION_SPELLS.SHADOW_BOLT) and 
       API.IsSpellUsable(AFFLICTION_SPELLS.SHADOW_BOLT) then
        return {
            type = "spell",
            id = AFFLICTION_SPELLS.SHADOW_BOLT,
            target = target
        }
    end
    
    return nil
}

-- Demonology rotation
function WarlockModule:DemonologyRotation()
    -- Check if we should execute
    if not self:ShouldExecuteRotation() then
        return nil
    end
    
    -- Get player and target
    local player = "player"
    local target = "target"
    
    -- Check if we have a target
    if not UnitExists(target) or not UnitCanAttack(player, target) or UnitIsDead(target) then
        return nil
    end
    
    -- Get settings
    local settings = ConfigRegistry:GetSettings("Warlock")
    
    -- Common Combat Variables
    local health, maxHealth, healthPercent = API.GetUnitHealth(player)
    local targetHealth, targetMaxHealth, targetHealthPercent = API.GetUnitHealth(target)
    local soulShards = API.GetUnitPower(player, Enum.PowerType.SoulShards)
    local enemies = API.GetEnemyCount(8)
    local aoeEnabled = settings.demonologySettings.aoeThreshold <= enemies
    local demoCoreCharges = 0
    local hasDemonicCoreAura, demonicCoreStacks = API.UnitHasBuff(player, BUFFS.DEMONIC_CORE)
    if hasDemonicCoreAura then
        demoCoreCharges = demonicCoreStacks
    end
    
    -- Check for pet (Felguard for Demonology)
    if settings.generalSettings.autoSummonPet and not UnitExists("pet") then
        -- Try Felguard first
        if API.IsSpellKnown(DEMONOLOGY_SPELLS.SUMMON_FELGUARD) and API.IsSpellUsable(DEMONOLOGY_SPELLS.SUMMON_FELGUARD) then
            return {
                type = "spell",
                id = DEMONOLOGY_SPELLS.SUMMON_FELGUARD,
                target = player
            }
        -- Fallback to Imp
        elseif API.IsSpellKnown(DEMONOLOGY_SPELLS.SUMMON_IMP) and API.IsSpellUsable(DEMONOLOGY_SPELLS.SUMMON_IMP) then
            return {
                type = "spell",
                id = DEMONOLOGY_SPELLS.SUMMON_IMP,
                target = player
            }
        end
    end
    
    -- Create Healthstone if needed
    if settings.generalSettings.createHealthstone and 
       not GetItemCount(DEMONOLOGY_SPELLS.HEALTHSTONE, false, true) > 0 and
       API.IsSpellKnown(DEMONOLOGY_SPELLS.CREATE_HEALTHSTONE) and
       API.IsSpellUsable(DEMONOLOGY_SPELLS.CREATE_HEALTHSTONE) then
        return {
            type = "spell",
            id = DEMONOLOGY_SPELLS.CREATE_HEALTHSTONE,
            target = player
        }
    end
    
    -- Defensive abilities
    if settings.generalSettings.useDefensives then
        -- Use Healthstone
        if settings.generalSettings.useHealthstone and 
           healthPercent <= settings.generalSettings.healthstoneThreshold and
           GetItemCount(DEMONOLOGY_SPELLS.HEALTHSTONE, false, true) > 0 and
           not API.UnitHasBuff(player, BUFFS.HEALTHSTONE_COOLDOWN) then
            return {
                type = "item",
                id = DEMONOLOGY_SPELLS.HEALTHSTONE,
                target = player
            }
        end
        
        -- Unending Resolve at critical health
        if healthPercent < 30 and 
           API.IsSpellKnown(DEMONOLOGY_SPELLS.UNENDING_RESOLVE) and 
           API.IsSpellUsable(DEMONOLOGY_SPELLS.UNENDING_RESOLVE) then
            return {
                type = "spell",
                id = DEMONOLOGY_SPELLS.UNENDING_RESOLVE,
                target = player
            }
        end
        
        -- Dark Pact if available
        if healthPercent < 50 and 
           API.IsSpellKnown(DEMONOLOGY_SPELLS.DARK_PACT) and 
           API.IsSpellUsable(DEMONOLOGY_SPELLS.DARK_PACT) then
            return {
                type = "spell",
                id = DEMONOLOGY_SPELLS.DARK_PACT,
                target = player
            }
        end
        
        -- Drain Life at low health
        if healthPercent < 40 and 
           API.IsSpellKnown(DEMONOLOGY_SPELLS.DRAIN_LIFE) and 
           API.IsSpellUsable(DEMONOLOGY_SPELLS.DRAIN_LIFE) then
            return {
                type = "spell",
                id = DEMONOLOGY_SPELLS.DRAIN_LIFE,
                target = target
            }
        end
    end
    
    -- Maintain Doom if talented and enabled
    if settings.demonologySettings.useDoom and
       API.IsSpellKnown(DEMONOLOGY_SPELLS.DOOM) and 
       API.IsSpellUsable(DEMONOLOGY_SPELLS.DOOM) and
       not API.UnitHasDebuff(target, DEBUFFS.DOOM) then
        return {
            type = "spell",
            id = DEMONOLOGY_SPELLS.DOOM,
            target = target
        }
    end
    
    -- Demonic Strength on Felguard
    if settings.demonologySettings.useDemonicStrength and
       UnitExists("pet") and
       API.IsSpellKnown(DEMONOLOGY_SPELLS.DEMONIC_STRENGTH) and 
       API.IsSpellUsable(DEMONOLOGY_SPELLS.DEMONIC_STRENGTH) then
        return {
            type = "spell",
            id = DEMONOLOGY_SPELLS.DEMONIC_STRENGTH,
            target = "pet"
        }
    end
    
    -- Core rotation for building up demons before Tyrant
    if inCombat and API.IsSpellKnown(DEMONOLOGY_SPELLS.SUMMON_DEMONIC_TYRANT) then
        -- Summon Vilefiend if talented
        if soulShards >= 1 and
           API.IsSpellKnown(DEMONOLOGY_SPELLS.SUMMON_VILEFIEND) and 
           API.IsSpellUsable(DEMONOLOGY_SPELLS.SUMMON_VILEFIEND) then
            return {
                type = "spell",
                id = DEMONOLOGY_SPELLS.SUMMON_VILEFIEND,
                target = player
            }
        end
        
        -- Call Dreadstalkers
        if soulShards >= 2 and
           API.IsSpellKnown(DEMONOLOGY_SPELLS.CALL_DREADSTALKERS) and 
           API.IsSpellUsable(DEMONOLOGY_SPELLS.CALL_DREADSTALKERS) then
            return {
                type = "spell",
                id = DEMONOLOGY_SPELLS.CALL_DREADSTALKERS,
                target = target
            }
        end
        
        -- Grimoire: Felguard if talented
        if soulShards >= 1 and
           API.IsSpellKnown(DEMONOLOGY_SPELLS.GRIMOIRE_FELGUARD) and 
           API.IsSpellUsable(DEMONOLOGY_SPELLS.GRIMOIRE_FELGUARD) then
            return {
                type = "spell",
                id = DEMONOLOGY_SPELLS.GRIMOIRE_FELGUARD,
                target = player
            }
        end
        
        -- Summon Demonic Tyrant to extend demons
        if API.IsSpellUsable(DEMONOLOGY_SPELLS.SUMMON_DEMONIC_TYRANT) then
            return {
                type = "spell",
                id = DEMONOLOGY_SPELLS.SUMMON_DEMONIC_TYRANT,
                target = player
            }
        end
    end
    
    -- AoE rotation
    if aoeEnabled and enemies >= 3 then
        -- Bilescourge Bombers if talented
        if API.IsSpellKnown(DEMONOLOGY_SPELLS.BILESCOURGE_BOMBERS) and 
           API.IsSpellUsable(DEMONOLOGY_SPELLS.BILESCOURGE_BOMBERS) then
            return {
                type = "spell",
                id = DEMONOLOGY_SPELLS.BILESCOURGE_BOMBERS,
                target = target
            }
        end
        
        -- Hand of Gul'dan for AoE
        if soulShards >= 3 and
           API.IsSpellKnown(DEMONOLOGY_SPELLS.HAND_OF_GULDAN) and 
           API.IsSpellUsable(DEMONOLOGY_SPELLS.HAND_OF_GULDAN) then
            return {
                type = "spell",
                id = DEMONOLOGY_SPELLS.HAND_OF_GULDAN,
                target = target
            }
        end
        
        -- Implosion when we have enough imps
        if API.IsSpellKnown(DEMONOLOGY_SPELLS.IMPLOSION) and 
           API.IsSpellUsable(DEMONOLOGY_SPELLS.IMPLOSION) then
            return {
                type = "spell",
                id = DEMONOLOGY_SPELLS.IMPLOSION,
                target = target
            }
        end
    end
    
    -- Core rotation
    -- Hand of Gul'dan with 3+ Soul Shards
    if soulShards >= 3 and
       API.IsSpellKnown(DEMONOLOGY_SPELLS.HAND_OF_GULDAN) and 
       API.IsSpellUsable(DEMONOLOGY_SPELLS.HAND_OF_GULDAN) then
        return {
            type = "spell",
            id = DEMONOLOGY_SPELLS.HAND_OF_GULDAN,
            target = target
        }
    end
    
    -- Power Siphon to get Demonic Core stacks
    if API.IsSpellKnown(DEMONOLOGY_SPELLS.POWER_SIPHON) and 
       API.IsSpellUsable(DEMONOLOGY_SPELLS.POWER_SIPHON) and
       demoCoreCharges < 2 then
        return {
            type = "spell",
            id = DEMONOLOGY_SPELLS.POWER_SIPHON,
            target = player
        }
    end
    
    -- Demonbolt with Demonic Core procs
    if demoCoreCharges > 0 and
       API.IsSpellKnown(DEMONOLOGY_SPELLS.DEMONBOLT) and 
       API.IsSpellUsable(DEMONOLOGY_SPELLS.DEMONBOLT) then
        return {
            type = "spell",
            id = DEMONOLOGY_SPELLS.DEMONBOLT,
            target = target
        }
    end
    
    -- Soul Strike if talented for soul shards
    if API.IsSpellKnown(DEMONOLOGY_SPELLS.SOUL_STRIKE) and 
       API.IsSpellUsable(DEMONOLOGY_SPELLS.SOUL_STRIKE) then
        return {
            type = "spell",
            id = DEMONOLOGY_SPELLS.SOUL_STRIKE,
            target = target
        }
    end
    
    -- Shadow Bolt as filler
    if API.IsSpellKnown(DEMONOLOGY_SPELLS.SHADOW_BOLT) and 
       API.IsSpellUsable(DEMONOLOGY_SPELLS.SHADOW_BOLT) then
        return {
            type = "spell",
            id = DEMONOLOGY_SPELLS.SHADOW_BOLT,
            target = target
        }
    end
    
    return nil
}

-- Destruction rotation
function WarlockModule:DestructionRotation()
    -- Check if we should execute
    if not self:ShouldExecuteRotation() then
        return nil
    end
    
    -- Get player and target
    local player = "player"
    local target = "target"
    
    -- Check if we have a target
    if not UnitExists(target) or not UnitCanAttack(player, target) or UnitIsDead(target) then
        return nil
    end
    
    -- Get settings
    local settings = ConfigRegistry:GetSettings("Warlock")
    
    -- Common Combat Variables
    local health, maxHealth, healthPercent = API.GetUnitHealth(player)
    local targetHealth, targetMaxHealth, targetHealthPercent = API.GetUnitHealth(target)
    local soulShards = API.GetUnitPower(player, Enum.PowerType.SoulShards)
    local enemies = API.GetEnemyCount(8)
    local aoeEnabled = settings.destructionSettings.aoeThreshold <= enemies
    local hasInfernal = API.IsSpellKnown(DESTRUCTION_SPELLS.SUMMON_INFERNAL) and API.IsSpellUsable(DESTRUCTION_SPELLS.SUMMON_INFERNAL)
    local hasBackdraft, backdraftStacks = API.UnitHasBuff(player, BUFFS.BACKDRAFT)
    local hasImmolate = API.UnitHasDebuff(target, DEBUFFS.IMMOLATE)
    
    -- Check for pet
    if settings.generalSettings.autoSummonPet and not UnitExists("pet") then
        -- Summon preferred pet based on settings
        local petType = settings.generalSettings.preferredPet
        local petSpellID
        
        if petType == "Imp" then
            petSpellID = DESTRUCTION_SPELLS.SUMMON_IMP
        elseif petType == "Voidwalker" then
            petSpellID = DESTRUCTION_SPELLS.SUMMON_VOIDWALKER
        elseif petType == "Felhunter" then
            petSpellID = DESTRUCTION_SPELLS.SUMMON_FELHUNTER
        elseif petType == "Succubus" then
            petSpellID = DESTRUCTION_SPELLS.SUMMON_SUCCUBUS
        else
            petSpellID = DESTRUCTION_SPELLS.SUMMON_IMP
        end
        
        if API.IsSpellKnown(petSpellID) and API.IsSpellUsable(petSpellID) then
            return {
                type = "spell",
                id = petSpellID,
                target = player
            }
        end
    end
    
    -- Create Healthstone if needed
    if settings.generalSettings.createHealthstone and 
       not GetItemCount(DESTRUCTION_SPELLS.HEALTHSTONE, false, true) > 0 and
       API.IsSpellKnown(DESTRUCTION_SPELLS.CREATE_HEALTHSTONE) and
       API.IsSpellUsable(DESTRUCTION_SPELLS.CREATE_HEALTHSTONE) then
        return {
            type = "spell",
            id = DESTRUCTION_SPELLS.CREATE_HEALTHSTONE,
            target = player
        }
    end
    
    -- Defensive abilities
    if settings.generalSettings.useDefensives then
        -- Use Healthstone
        if settings.generalSettings.useHealthstone and 
           healthPercent <= settings.generalSettings.healthstoneThreshold and
           GetItemCount(DESTRUCTION_SPELLS.HEALTHSTONE, false, true) > 0 and
           not API.UnitHasBuff(player, BUFFS.HEALTHSTONE_COOLDOWN) then
            return {
                type = "item",
                id = DESTRUCTION_SPELLS.HEALTHSTONE,
                target = player
            }
        end
        
        -- Unending Resolve at critical health
        if healthPercent < 30 and 
           API.IsSpellKnown(DESTRUCTION_SPELLS.UNENDING_RESOLVE) and 
           API.IsSpellUsable(DESTRUCTION_SPELLS.UNENDING_RESOLVE) then
            return {
                type = "spell",
                id = DESTRUCTION_SPELLS.UNENDING_RESOLVE,
                target = player
            }
        end
        
        -- Dark Pact if available
        if healthPercent < 50 and 
           API.IsSpellKnown(DESTRUCTION_SPELLS.DARK_PACT) and 
           API.IsSpellUsable(DESTRUCTION_SPELLS.DARK_PACT) then
            return {
                type = "spell",
                id = DESTRUCTION_SPELLS.DARK_PACT,
                target = player
            }
        end
        
        -- Drain Life at low health
        if healthPercent < 40 and 
           API.IsSpellKnown(DESTRUCTION_SPELLS.DRAIN_LIFE) and 
           API.IsSpellUsable(DESTRUCTION_SPELLS.DRAIN_LIFE) then
            return {
                type = "spell",
                id = DESTRUCTION_SPELLS.DRAIN_LIFE,
                target = target
            }
        end
    end
    
    -- Maintain Immolate
    if not hasImmolate and
       API.IsSpellKnown(DESTRUCTION_SPELLS.IMMOLATE) and 
       API.IsSpellUsable(DESTRUCTION_SPELLS.IMMOLATE) then
        return {
            type = "spell",
            id = DESTRUCTION_SPELLS.IMMOLATE,
            target = target
        }
    end
    
    -- Havoc for cleave when enabled
    if settings.destructionSettings.useHavoc and enemies > 1 and
       API.IsSpellKnown(DESTRUCTION_SPELLS.HAVOC) and 
       API.IsSpellUsable(DESTRUCTION_SPELLS.HAVOC) then
        -- Different targets based on settings
        local havocTarget = target
        if settings.destructionSettings.havocTarget == "Focus" and UnitExists("focus") then
            havocTarget = "focus"
        elseif settings.destructionSettings.havocTarget == "Mouseover" and UnitExists("mouseover") then
            havocTarget = "mouseover"
        end
        
        if havocTarget ~= target then
            return {
                type = "spell",
                id = DESTRUCTION_SPELLS.HAVOC,
                target = havocTarget
            }
        end
    end
    
    -- Offensive cooldowns
    if inCombat then
        -- Summon Infernal
        if settings.destructionSettings.useSummonInfernal and hasInfernal then
            return {
                type = "spell",
                id = DESTRUCTION_SPELLS.SUMMON_INFERNAL,
                target = target
            }
        end
        
        -- Channel Demonfire if talented and Immolate is applied
        if hasImmolate and
           API.IsSpellKnown(DESTRUCTION_SPELLS.CHANNEL_DEMONFIRE) and 
           API.IsSpellUsable(DESTRUCTION_SPELLS.CHANNEL_DEMONFIRE) then
            return {
                type = "spell",
                id = DESTRUCTION_SPELLS.CHANNEL_DEMONFIRE,
                target = target
            }
        end
        
        -- Cataclysm for AoE if talented
        if aoeEnabled and
           API.IsSpellKnown(DESTRUCTION_SPELLS.CATACLYSM) and 
           API.IsSpellUsable(DESTRUCTION_SPELLS.CATACLYSM) then
            return {
                type = "spell",
                id = DESTRUCTION_SPELLS.CATACLYSM,
                target = target
            }
        end
    end
    
    -- AoE rotation
    if aoeEnabled and enemies >= 3 then
        -- Rain of Fire for AoE
        if soulShards >= 3 and
           API.IsSpellKnown(DESTRUCTION_SPELLS.RAIN_OF_FIRE) and 
           API.IsSpellUsable(DESTRUCTION_SPELLS.RAIN_OF_FIRE) then
            return {
                type = "spell",
                id = DESTRUCTION_SPELLS.RAIN_OF_FIRE,
                target = target
            }
        end
    end
    
    -- Core rotation
    -- Chaos Bolt with 4+ Soul Shards or Infernal is active
    if soulShards >= 4 and
       API.IsSpellKnown(DESTRUCTION_SPELLS.CHAOS_BOLT) and 
       API.IsSpellUsable(DESTRUCTION_SPELLS.CHAOS_BOLT) then
        return {
            type = "spell",
            id = DESTRUCTION_SPELLS.CHAOS_BOLT,
            target = target
        }
    end
    
    -- Conflagrate to generate Soul Shards and Backdraft
    if API.IsSpellKnown(DESTRUCTION_SPELLS.CONFLAGRATE) and 
       API.IsSpellUsable(DESTRUCTION_SPELLS.CONFLAGRATE) and
       (hasBackdraft == false or backdraftStacks < 2) then
        return {
            type = "spell",
            id = DESTRUCTION_SPELLS.CONFLAGRATE,
            target = target
        }
    end
    
    -- Soul Fire if talented
    if API.IsSpellKnown(DESTRUCTION_SPELLS.SOUL_FIRE) and 
       API.IsSpellUsable(DESTRUCTION_SPELLS.SOUL_FIRE) then
        return {
            type = "spell",
            id = DESTRUCTION_SPELLS.SOUL_FIRE,
            target = target
        }
    end
    
    -- Shadowburn if talented and target is low health
    if targetHealthPercent < 20 and
       API.IsSpellKnown(DESTRUCTION_SPELLS.SHADOWBURN) and 
       API.IsSpellUsable(DESTRUCTION_SPELLS.SHADOWBURN) then
        return {
            type = "spell",
            id = DESTRUCTION_SPELLS.SHADOWBURN,
            target = target
        }
    end
    
    -- Incinerate as filler
    if API.IsSpellKnown(DESTRUCTION_SPELLS.INCINERATE) and 
       API.IsSpellUsable(DESTRUCTION_SPELLS.INCINERATE) then
        return {
            type = "spell",
            id = DESTRUCTION_SPELLS.INCINERATE,
            target = target
        }
    end
    
    return nil
}

-- Should execute rotation
function WarlockModule:ShouldExecuteRotation()
    if not isEnabled then
        return false
    end
    
    -- Check if player matches class
    local playerInfo = API.GetPlayerInfo()
    if playerInfo.class ~= "WARLOCK" then
        return false
    end
    
    return true
}

-- Register for export
WR.Warlock = WarlockModule

return WarlockModule