------------------------------------------
-- WindrunnerRotations - Evoker Class Module
-- Author: VortexQ8
-- The War Within Season 2
------------------------------------------

local addonName, WR = ...
local EvokerModule = {}
WR.Evoker = EvokerModule

-- Dependencies
local API = WR.API
local ConfigRegistry = WR.ConfigRegistry
local RotationManager = WR.RotationManager
local ErrorHandler = WR.ErrorHandler
local CombatAnalysis = WR.CombatAnalysis
local AntiDetectionSystem = WR.AntiDetectionSystem
local PvPManager = WR.PvPManager

-- Evoker constants
local CLASS_ID = 13 -- Evoker class ID
local SPEC_DEVASTATION = 1467
local SPEC_PRESERVATION = 1468
local SPEC_AUGMENTATION = 1473

-- Current player data
local playerSpec = 0
local isEnabled = true
local inCombat = false

-- Spell IDs for Devastation Evoker (The War Within, Season 2)
local DEVASTATION_SPELLS = {
    -- Core abilities
    FIRE_BREATH = 357208,
    DISINTEGRATE = 356995,
    LIVING_FLAME = 361469,
    AZURE_STRIKE = 362969,
    DEEP_BREATH = 357210,
    ETERNITY_SURGE = 359073,
    PYRE = 357211,
    FIRESTORM = 368847,
    DRAGONRAGE = 375087,
    BLUE_FLAME = 388741,
    FIRE_ATTUNEMENT = 375801,
    TYRANNIZE = 361309,
    
    -- Defensive & utility
    OBSIDIAN_SCALES = 363916,
    RENEWING_BLAZE = 374348,
    VERDANT_EMBRACE = 360995,
    SOURCE_OF_MAGIC = 369459,
    EMERALD_COMMUNION = 370960,
    RESCUE = 370665,
    TIME_SPIRAL = 374968,
    
    -- Talents
    TIP_THE_SCALES = 370553,
    SHATTERING_STAR = 370452,
    HOVER = 358267,
    TAIL_SWIPE = 368970,
    BURNOUT = 375801,
    ANCIENT_FLAME = 369990,
    CATALYZE = 386283,
    
    -- Season 2 Abilities
    SCINTILLATION = 370821, -- New in TWW Season 2
    ARCANE_VIGOR = 386342, -- New in TWW Season 2
    DRACONIC_ATTUNEMENT = 381922, -- New in TWW Season 2
    ARCANE_AWAKENING = 427457, -- New in TWW Season 2
    TYRANNICAL_FLAME = 392060, -- New in TWW Season 2
    CHARGED_BLAST = 370454, -- Enhanced in TWW Season 2
    RUBY_ESSENCE = 375783, -- New in TWW Season 2
    ENGULFING_BLAZE = 370493, -- New in TWW Season 2
    LIVING_BREATH = 397056, -- New in TWW Season 2
    LEAPING_FLAMES = 369939, -- Enhanced in TWW Season 2
    VOLATILITY = 369089, -- New in TWW Season 2
    POWER_NEXUS = 369908, -- New in TWW Season 2
    FEED_THE_FLAMES = 369846, -- New in TWW Season 2
    ARCANE_INTENSITY = 375796, -- New in TWW Season 2
    FONT_OF_MAGIC = 375783, -- New in TWW Season 2
    
    -- Misc
    ESSENCE_BURST = 359618,
    AERIAL_DIVE = 370388,
    WING_BUFFET = 357214,
    SLEEP_WALK = 360806,
    QUELL = 351338
}

-- Spell IDs for Preservation Evoker (The War Within, Season 2)
local PRESERVATION_SPELLS = {
    -- Core abilities
    DREAM_BREATH = 355936,
    LIVING_FLAME = 361469,
    AZURE_STRIKE = 362969,
    EMERALD_BLOSSOM = 355913,
    ECHO = 364343,
    SPIRITBLOOM = 367226,
    VERDANT_EMBRACE = 360995,
    REVERSION = 366155,
    NATURALIZE = 360823,
    TIME_DILATION = 357170,
    RENEWING_BLAZE = 374348,
    DREAMFLIGHT = 413436,
    
    -- Defensive & utility
    OBSIDIAN_SCALES = 363916,
    RESCUE = 370665,
    TIME_SPIRAL = 374968,
    ZEPHYR = 374227,
    CAUTERIZING_FLAME = 374251,
    
    -- Talents
    TIP_THE_SCALES = 370553,
    DREAM_FLIGHT = 359816,
    STASIS = 370537,
    HOVER = 358267,
    TAIL_SWIPE = 368970,
    EMERALD_COMMUNION = 370960,
    TEMPORAL_COMPRESSIONS = 371938,
    SOURCE_OF_MAGIC = 369459,
    
    -- Season 2 Abilities
    ECHO_OF_THE_DREAM = 381922, -- New in TWW Season 2
    LIFEBIND = 373270, -- New in TWW Season 2
    EMERALD_TRANCE = 375234, -- New in TWW Season 2
    GOLDEN_HOUR = 408083, -- New in TWW Season 2
    REGENERATIVE_FUNGUS = 412785, -- New in TWW Season 2
    BLOOM = 370886, -- New in TWW Season 2
    FIELD_OF_DREAMS = 377056, -- New in TWW Season 2
    DREAM_PETALS = 427462, -- New in TWW Season 2
    PULSING_TWILIGHT = 395786, -- New in TWW Season 2
    CYCLE_OF_LIFE = 371958, -- New in TWW Season 2
    LIFEFORCE_MENDER = 385717, -- New in TWW Season 2
    REVERSION_IMPROVED = 389359, -- Enhanced in TWW Season 2
    ALLIED_PROTECTION = 409561, -- New in TWW Season 2
    TEMPORAL_ANOMALY = 373861, -- New in TWW Season 2
    TIME_LORD = 372323, -- New in TWW Season 2
    
    -- Misc
    WING_BUFFET = 357214,
    SLEEP_WALK = 360806,
    QUELL = 351338
}

-- Spell IDs for Augmentation Evoker (The War Within, Season 2)
local AUGMENTATION_SPELLS = {
    -- Core abilities
    LIVING_FLAME = 361469,
    AZURE_STRIKE = 362969,
    FIRE_BREATH = 357208,
    DISINTEGRATE = 356995,
    EYE_BEAM = 366844,
    ENGULF = 389533,
    BREATH_OF_EONS = 403631,
    ETERNITY_SURGE = 359073,
    BLISTERING_SCALES = 360827,
    EBON_MIGHT = 395152,
    ERUPTING_ESSENCE = 406732,
    
    -- Buffs
    TIME_SPIRAL = 374968,
    BLESSING_OF_BRONZE = 364342,
    POWER_INFUSION = 10060,
    PRESCIENCE = 409311,
    SPATIAL_PARADOX = 406789,
    BREATHE = 383210,
    
    -- Defensive & utility
    OBSIDIAN_SCALES = 363916,
    RENEWING_BLAZE = 374348,
    RESCUE = 370665,
    ZEPHYR = 374227,
    CAUTERIZING_FLAME = 374251,
    SOURCE_OF_MAGIC = 369459,
    
    -- Talents
    TIP_THE_SCALES = 370553,
    HOVER = 358267,
    TAIL_SWIPE = 368970,
    FLY_WITH_ME = 406732,
    TIME_STOP = 378441,
    
    -- Season 2 Abilities
    SPIRITUAL_CLARITY = 408233, -- New in TWW Season 2
    TIMELESSNESS = 376239, -- New in TWW Season 2
    CHRONOLOGY = 409667, -- New in TWW Season 2
    TEMPORAL_WOUND = 409546, -- New in TWW Season 2
    OUROBOROS = 408083, -- New in TWW Season 2
    TITANIC_WRATH = 410853, -- New in TWW Season 2
    SYMBIOTIC_BOND = 410453, -- New in TWW Season 2
    BESTOW_WRATH = 408233, -- New in TWW Season 2
    TEMPORAL_COMPRESSION = 408821, -- New in TWW Season 2
    SCINTILLATION = 370821, -- New in TWW Season 2
    BLISTERING_SCALES_IMPROVED = 410495, -- Enhanced in TWW Season 2
    CLOSE_AS_CLUTCHMATES = 409021, -- New in TWW Season 2
    ESSENCE_ATTUNEMENT = 375544, -- New in TWW Season 2
    EXPUNGE_CORRUPTION = 383870, -- New in TWW Season 2
    INFERNOS_BLESSING = 410213, -- New in TWW Season 2
    
    -- Misc
    WING_BUFFET = 357214,
    SLEEP_WALK = 360806,
    QUELL = 351338
}

-- Important buffs to track
local BUFFS = {
    -- Devastation
    ESSENCE_BURST = 359618,
    DRAGONRAGE = 375087,
    BURNOUT = 375802,
    TIP_THE_SCALES = 370553,
    SHATTERING_STAR = 370452,
    CATALYZE = 386353,
    FIRE_ATTUNEMENT = 375801,
    
    -- Preservation
    ECHO = 364343,
    EMERALD_BLOSSOM = 359816,
    STASIS = 370537,
    TIP_THE_SCALES = 370553,
    TEMPORAL_COMPRESSIONS = 371938,
    
    -- Augmentation
    BLESSING_OF_BRONZE = 364342,
    EBON_MIGHT = 395152,
    PRESCIENCE = 409311,
    BREATH_OF_EONS = 403631,
    SPATIAL_PARADOX = 406789,
    TIME_STOP = 378441,
    
    -- Shared
    HOVER = 358267,
    OBSIDIAN_SCALES = 363916,
    RENEWING_BLAZE = 374348
}

-- Important debuffs to track
local DEBUFFS = {
    -- Devastation
    FIRE_BREATH = 357209,
    DISINTEGRATE = 356995,
    TYRANNIZE = 368970,
    
    -- Preservation
    DREAM_BREATH = 355941,
    
    -- Augmentation
    ENGULF = 389533,
    
    -- Shared
    SLEEP_WALK = 360806
}

-- Initialize the Evoker module
function EvokerModule:Initialize()
    -- Register settings
    self:RegisterSettings()
    
    -- Register events
    self:RegisterEvents()
    
    -- Register rotations
    self:RegisterRotations()
    
    API.PrintDebug("Evoker module initialized")
    return true
end

-- Register settings
function EvokerModule:RegisterSettings()
    ConfigRegistry:RegisterSettings("Evoker", {
        generalSettings = {
            enabled = {
                displayName = "Enable Evoker Module",
                description = "Enable the Evoker module for all specs",
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
            useRescue = {
                displayName = "Use Rescue",
                description = "Use Rescue to save allies in danger",
                type = "toggle",
                default = false
            },
            useSleepWalk = {
                displayName = "Use Sleep Walk",
                description = "Use Sleep Walk for crowd control",
                type = "toggle",
                default = true
            },
            useCauterizingFlame = {
                displayName = "Use Cauterizing Flame",
                description = "Use Cauterizing Flame to dispel harmful effects",
                type = "toggle",
                default = true
            },
            useZephyr = {
                displayName = "Use Zephyr",
                description = "Use Zephyr to prevent damage",
                type = "toggle",
                default = true
            },
            obsidianScalesThreshold = {
                displayName = "Obsidian Scales Health Threshold",
                description = "Health percentage to use Obsidian Scales",
                type = "slider",
                min = 10,
                max = 60,
                step = 5,
                default = 40
            },
            renewingBlazeThreshold = {
                displayName = "Renewing Blaze Health Threshold",
                description = "Health percentage to use Renewing Blaze",
                type = "slider",
                min = 10,
                max = 80,
                step = 5,
                default = 60
            },
            useTipTheScales = {
                displayName = "Use Tip the Scales",
                description = "Use Tip the Scales with breath abilities",
                type = "toggle",
                default = true
            },
            empowermentLevel = {
                displayName = "Default Empowerment Level",
                description = "Level of empowerment to use for abilities",
                type = "dropdown",
                options = {"Max Level", "Level 1", "Level 2", "Level 3"},
                default = "Max Level"
            }
        },
        devastationSettings = {
            -- Core settings
            useDragonrage = {
                displayName = "Use Dragonrage",
                description = "Use Dragonrage on cooldown",
                type = "toggle",
                default = true
            },
            useFireBreath = {
                displayName = "Use Fire Breath",
                description = "Use Fire Breath in rotation",
                type = "toggle",
                default = true
            },
            useEternitySurge = {
                displayName = "Use Eternity Surge",
                description = "Use Eternity Surge in rotation",
                type = "toggle",
                default = true
            },
            useDeepBreath = {
                displayName = "Use Deep Breath",
                description = "Use Deep Breath for AoE",
                type = "toggle",
                default = true
            },
            useFirestorm = {
                displayName = "Use Firestorm",
                description = "Use Firestorm on cooldown if talented",
                type = "toggle",
                default = true
            },
            usePyre = {
                displayName = "Use Pyre",
                description = "Use Pyre with Essence Burst procs",
                type = "toggle",
                default = true
            },
            useAncientFlame = {
                displayName = "Use Ancient Flame",
                description = "Use Ancient Flame in rotation if talented",
                type = "toggle",
                default = true
            },
            useCatalyze = {
                displayName = "Use Catalyze",
                description = "Use Catalyze in rotation if talented",
                type = "toggle",
                default = true
            },
            
            -- Season 2 ability settings
            useScintillation = {
                displayName = "Use Scintillation (TWW S2)",
                description = "Use Scintillation for enhanced Essence Burst",
                type = "toggle",
                default = true
            },
            useArcaneVigor = {
                displayName = "Use Arcane Vigor (TWW S2)",
                description = "Use Arcane Vigor for enhanced Essence generation",
                type = "toggle",
                default = true
            },
            useDraconicAttunement = {
                displayName = "Use Draconic Attunement (TWW S2)",
                description = "Use Draconic Attunement in rotation",
                type = "toggle",
                default = true
            },
            useArcaneAwakening = {
                displayName = "Use Arcane Awakening (TWW S2)",
                description = "Use Arcane Awakening for enhanced Arcane spells",
                type = "toggle",
                default = true
            },
            useTyrannicalFlame = {
                displayName = "Use Tyrannical Flame (TWW S2)",
                description = "Use Tyrannical Flame to enhance Fire Breath",
                type = "toggle",
                default = true
            },
            useChargedBlast = {
                displayName = "Use Charged Blast (TWW S2)",
                description = "Use Charged Blast to enhance Azure Strike",
                type = "toggle",
                default = true
            },
            useRubyEssence = {
                displayName = "Use Ruby Essence (TWW S2)",
                description = "Use Ruby Essence for enhanced Fire damage",
                type = "toggle",
                default = true
            },
            useEngulfingBlaze = {
                displayName = "Use Engulfing Blaze (TWW S2)",
                description = "Use Engulfing Blaze in rotation",
                type = "toggle",
                default = true
            },
            useLivingBreath = {
                displayName = "Use Living Breath (TWW S2)",
                description = "Use Living Breath to enhance Living Flame",
                type = "toggle",
                default = true
            },
            useLeapingFlames = {
                displayName = "Use Leaping Flames (TWW S2)",
                description = "Use Leaping Flames for fire damage jumps",
                type = "toggle",
                default = true
            },
            useVolatility = {
                displayName = "Use Volatility (TWW S2)",
                description = "Use Volatility for enhanced Essence Burst procs",
                type = "toggle",
                default = true
            },
            
            -- Advanced settings
            aoeThreshold = {
                displayName = "AoE Threshold",
                description = "Number of targets to switch to AoE rotation",
                type = "slider",
                min = 2,
                max = 6,
                step = 1,
                default = 3
            },
            dragonrageMode = {
                displayName = "Dragonrage Usage (TWW S2)",
                description = "How to optimize Dragonrage cooldown",
                type = "dropdown",
                options = {"On Cooldown", "With Bloodlust/Heroism", "Save for Burst Windows", "Manual Only"},
                default = "On Cooldown"
            },
            empowermentStrategy = {
                displayName = "Empowerment Strategy (TWW S2)",
                description = "How to handle empowered spell casts",
                type = "dropdown",
                options = {"Always Max Level", "Situational", "Speed Prioritized", "Damage Prioritized"},
                default = "Situational"
            }
        },
        preservationSettings = {
            useDreamBreath = {
                displayName = "Use Dream Breath",
                description = "Use Dream Breath for group healing",
                type = "toggle",
                default = true
            },
            useSpiritbloom = {
                displayName = "Use Spiritbloom",
                description = "Use Spiritbloom for burst healing",
                type = "toggle",
                default = true
            },
            useEmeraldCommunion = {
                displayName = "Use Emerald Communion",
                description = "Use Emerald Communion for emergency mana",
                type = "toggle",
                default = true
            },
            useTimeDilation = {
                displayName = "Use Time Dilation",
                description = "Use Time Dilation on HoT effects",
                type = "toggle",
                default = true
            },
            useReversion = {
                displayName = "Use Reversion",
                description = "Use Reversion for emergency healing",
                type = "toggle",
                default = true
            },
            useEchoEfficiently = {
                displayName = "Use Echo Efficiently",
                description = "Use Echo buff to cast free heals",
                type = "toggle",
                default = true
            },
            dreamBreathSetting = {
                displayName = "Dream Breath Usage",
                description = "When to use Dream Breath",
                type = "dropdown",
                options = {"Group Healing", "Single Target", "Both"},
                default = "Both"
            },
            emeraldBlossomThreshold = {
                displayName = "Emerald Blossom Group Threshold",
                description = "Number of injured allies for Emerald Blossom",
                type = "slider",
                min = 2,
                max = 5,
                step = 1,
                default = 3
            },
            sourceOfMagicTarget = {
                displayName = "Source of Magic Target",
                description = "Who to cast Source of Magic on",
                type = "dropdown",
                options = {"Healer", "DPS Caster", "Self", "None"},
                default = "DPS Caster"
            },
            useDreamFlight = {
                displayName = "Use Dreamflight",
                description = "Use Dreamflight for group healing",
                type = "toggle",
                default = true
            },
            dreamFlightThreshold = {
                displayName = "Dreamflight Health Threshold",
                description = "Average group health to use Dreamflight",
                type = "slider",
                min = 10,
                max = 70,
                step = 5,
                default = 45
            }
        },
        augmentationSettings = {
            useEbonMight = {
                displayName = "Use Ebon Might",
                description = "Use Ebon Might on cooldown",
                type = "toggle",
                default = true
            },
            useBlessingOfBronze = {
                displayName = "Use Blessing of Bronze",
                description = "Use Blessing of Bronze on cooldown",
                type = "toggle",
                default = true
            },
            usePrescience = {
                displayName = "Use Prescience",
                description = "Use Prescience on cooldown",
                type = "toggle",
                default = true
            },
            useBreathOfEons = {
                displayName = "Use Breath of Eons",
                description = "Use Breath of Eons on cooldown",
                type = "toggle",
                default = true
            },
            useSpatialParadox = {
                displayName = "Use Spatial Paradox",
                description = "Use Spatial Paradox in rotation",
                type = "toggle",
                default = true
            },
            useTimeStop = {
                displayName = "Use Time Stop",
                description = "Use Time Stop for emergency group effects",
                type = "toggle",
                default = true
            },
            useBlistering = {
                displayName = "Use Blistering Scales",
                description = "Use Blistering Scales on allies",
                type = "toggle",
                default = true
            },
            blisteringScalesTarget = {
                displayName = "Blistering Scales Target",
                description = "Who to cast Blistering Scales on",
                type = "dropdown",
                options = {"Tank", "Melee DPS", "Self", "Smart"},
                default = "Melee DPS"
            },
            ebonMightSpreadTargets = {
                displayName = "Ebon Might Spread Count",
                description = "Number of allies to spread Ebon Might to",
                type = "slider",
                min = 2,
                max = 5,
                step = 1,
                default = 4
            },
            useBreathe = {
                displayName = "Use Breathe",
                description = "Use Breathe in rotation",
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
            }
        }
    })
    
    -- Add callback for settings changes
    ConfigRegistry:RegisterCallback("Evoker", function(settings)
        self:ApplySettings(settings)
    end)
end

-- Apply settings
function EvokerModule:ApplySettings(settings)
    -- Apply general settings
    isEnabled = settings.generalSettings.enabled
end

-- Register events
function EvokerModule:RegisterEvents()
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
end

-- On specialization changed
function EvokerModule:OnSpecializationChanged()
    -- Get current spec ID
    playerSpec = API.GetActiveSpecID()
    
    API.PrintDebug("Evoker specialization changed: " .. playerSpec)
    
    -- Ensure correct rotation is registered
    if playerSpec == SPEC_DEVASTATION then
        self:RegisterDevastationRotation()
    elseif playerSpec == SPEC_PRESERVATION then
        self:RegisterPreservationRotation()
    elseif playerSpec == SPEC_AUGMENTATION then
        self:RegisterAugmentationRotation()
    end
end

-- Register rotations
function EvokerModule:RegisterRotations()
    -- Register spec-specific rotations
    self:RegisterDevastationRotation()
    self:RegisterPreservationRotation()
    self:RegisterAugmentationRotation()
end

-- Register Devastation rotation
function EvokerModule:RegisterDevastationRotation()
    RotationManager:RegisterRotation("EvokerDevastation", {
        id = "EvokerDevastation",
        name = "Evoker - Devastation",
        class = "EVOKER",
        spec = SPEC_DEVASTATION,
        level = 10,
        description = "Devastation Evoker rotation for The War Within Season 2",
        author = "WindrunnerRotations",
        version = "1.0.0",
        rotation = function()
            return self:DevastationRotation()
        end
    })
end

-- Register Preservation rotation
function EvokerModule:RegisterPreservationRotation()
    RotationManager:RegisterRotation("EvokerPreservation", {
        id = "EvokerPreservation",
        name = "Evoker - Preservation",
        class = "EVOKER",
        spec = SPEC_PRESERVATION,
        level = 10,
        description = "Preservation Evoker rotation for The War Within Season 2",
        author = "WindrunnerRotations",
        version = "1.0.0",
        rotation = function()
            return self:PreservationRotation()
        end
    })
end

-- Register Augmentation rotation
function EvokerModule:RegisterAugmentationRotation()
    RotationManager:RegisterRotation("EvokerAugmentation", {
        id = "EvokerAugmentation",
        name = "Evoker - Augmentation",
        class = "EVOKER",
        spec = SPEC_AUGMENTATION,
        level = 10,
        description = "Augmentation Evoker rotation for The War Within Season 2",
        author = "WindrunnerRotations",
        version = "1.0.0",
        rotation = function()
            return self:AugmentationRotation()
        end
    })
end

-- Devastation rotation
function EvokerModule:DevastationRotation()
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
    local settings = ConfigRegistry:GetSettings("Evoker")
    
    -- Common Combat Variables
    local health, maxHealth, healthPercent = API.GetUnitHealth(player)
    local targetHealth, targetMaxHealth, targetHealthPercent = API.GetUnitHealth(target)
    local mana = API.GetUnitPower(player, Enum.PowerType.Mana)
    local maxMana = API.GetUnitPowerMax(player, Enum.PowerType.Mana)
    local enemies = API.GetEnemyCount(10)
    local aoeEnabled = settings.devastationSettings.aoeThreshold <= enemies
    
    -- Buff tracking
    local hasEssenceBurst = API.UnitHasBuff(player, BUFFS.ESSENCE_BURST)
    local essenceBurstStacks = API.GetBuffStacks(player, BUFFS.ESSENCE_BURST)
    local hasDragonrage = API.UnitHasBuff(player, BUFFS.DRAGONRAGE)
    local hasBurnout = API.UnitHasBuff(player, BUFFS.BURNOUT)
    local hasTipTheScales = API.UnitHasBuff(player, BUFFS.TIP_THE_SCALES)
    local hasShatteringStar = API.UnitHasBuff(player, BUFFS.SHATTERING_STAR)
    local hasCatalyze = API.UnitHasBuff(player, BUFFS.CATALYZE)
    local hasFireAttunement = API.UnitHasBuff(player, BUFFS.FIRE_ATTUNEMENT)
    
    -- Debuff tracking
    local fireBreathRemaining = API.GetDebuffRemaining(target, DEBUFFS.FIRE_BREATH)
    
    -- CDs
    local dragonrageCD = API.GetSpellCooldown(DEVASTATION_SPELLS.DRAGONRAGE)
    local fireBreathCD = API.GetSpellCooldown(DEVASTATION_SPELLS.FIRE_BREATH)
    local eternitySurgeCD = API.GetSpellCooldown(DEVASTATION_SPELLS.ETERNITY_SURGE)
    local deepBreathCD = API.GetSpellCooldown(DEVASTATION_SPELLS.DEEP_BREATH)
    local firestormCD = API.GetSpellCooldown(DEVASTATION_SPELLS.FIRESTORM)
    local tipTheScalesCD = API.GetSpellCooldown(DEVASTATION_SPELLS.TIP_THE_SCALES)
    
    -- Interrupt if needed
    if settings.generalSettings.useInterrupts and
       API.IsSpellKnown(DEVASTATION_SPELLS.QUELL) and 
       API.IsSpellUsable(DEVASTATION_SPELLS.QUELL) and
       API.ShouldInterrupt(target) then
        return {
            type = "spell",
            id = DEVASTATION_SPELLS.QUELL,
            target = target
        }
    end
    
    -- Defensive abilities
    if settings.generalSettings.useDefensives then
        -- Use Obsidian Scales
        if healthPercent < settings.generalSettings.obsidianScalesThreshold and
           API.IsSpellKnown(DEVASTATION_SPELLS.OBSIDIAN_SCALES) and 
           API.IsSpellUsable(DEVASTATION_SPELLS.OBSIDIAN_SCALES) then
            return {
                type = "spell",
                id = DEVASTATION_SPELLS.OBSIDIAN_SCALES,
                target = player
            }
        end
        
        -- Use Renewing Blaze
        if healthPercent < settings.generalSettings.renewingBlazeThreshold and
           API.IsSpellKnown(DEVASTATION_SPELLS.RENEWING_BLAZE) and 
           API.IsSpellUsable(DEVASTATION_SPELLS.RENEWING_BLAZE) then
            return {
                type = "spell",
                id = DEVASTATION_SPELLS.RENEWING_BLAZE,
                target = player
            }
        end
        
        -- Use Verdant Embrace for healing
        if healthPercent < 70 and
           API.IsSpellKnown(DEVASTATION_SPELLS.VERDANT_EMBRACE) and 
           API.IsSpellUsable(DEVASTATION_SPELLS.VERDANT_EMBRACE) then
            return {
                type = "spell",
                id = DEVASTATION_SPELLS.VERDANT_EMBRACE,
                target = player
            }
        end
    end
    
    -- Use Emerald Communion for mana
    if API.IsSpellKnown(DEVASTATION_SPELLS.EMERALD_COMMUNION) and 
       API.IsSpellUsable(DEVASTATION_SPELLS.EMERALD_COMMUNION) and
       mana < (maxMana * 0.4) then
        return {
            type = "spell",
            id = DEVASTATION_SPELLS.EMERALD_COMMUNION,
            target = player
        }
    end
    
    -- Offensive cooldowns
    if inCombat then
        -- Use Dragonrage
        if settings.devastationSettings.useDragonrage and
           not hasDragonrage and
           API.IsSpellKnown(DEVASTATION_SPELLS.DRAGONRAGE) and 
           API.IsSpellUsable(DEVASTATION_SPELLS.DRAGONRAGE) then
            return {
                type = "spell",
                id = DEVASTATION_SPELLS.DRAGONRAGE,
                target = player
            }
        end
        
        -- Use Tip the Scales for empower abilities
        if settings.generalSettings.useTipTheScales and
           not hasTipTheScales and
           (fireBreathCD == 0 or eternitySurgeCD == 0) and
           API.IsSpellKnown(DEVASTATION_SPELLS.TIP_THE_SCALES) and 
           API.IsSpellUsable(DEVASTATION_SPELLS.TIP_THE_SCALES) then
            return {
                type = "spell",
                id = DEVASTATION_SPELLS.TIP_THE_SCALES,
                target = player
            }
        end
        
        -- Use Firestorm for AoE
        if settings.devastationSettings.useFirestorm and
           aoeEnabled and
           API.IsSpellKnown(DEVASTATION_SPELLS.FIRESTORM) and 
           API.IsSpellUsable(DEVASTATION_SPELLS.FIRESTORM) then
            return {
                type = "spell",
                id = DEVASTATION_SPELLS.FIRESTORM,
                target = target
            }
        end
        
        -- Use Deep Breath for AoE
        if settings.devastationSettings.useDeepBreath and
           aoeEnabled and
           enemies >= 3 and
           API.IsSpellKnown(DEVASTATION_SPELLS.DEEP_BREATH) and 
           API.IsSpellUsable(DEVASTATION_SPELLS.DEEP_BREATH) then
            local empowerLevel = self:GetEmpowermentLevel(settings.generalSettings.empowermentLevel)
            return {
                type = "empowered_spell",
                id = DEVASTATION_SPELLS.DEEP_BREATH,
                target = player,
                empowerLevel = empowerLevel
            }
        end
    end
    
    -- Core rotation
    
    -- Use Fire Breath with or without Tip the Scales
    if settings.devastationSettings.useFireBreath and
       fireBreathRemaining < 2 and
       API.IsSpellKnown(DEVASTATION_SPELLS.FIRE_BREATH) and 
       API.IsSpellUsable(DEVASTATION_SPELLS.FIRE_BREATH) then
        local empowerLevel = hasTipTheScales and 3 or self:GetEmpowermentLevel(settings.generalSettings.empowermentLevel)
        return {
            type = "empowered_spell",
            id = DEVASTATION_SPELLS.FIRE_BREATH,
            target = target,
            empowerLevel = empowerLevel
        }
    end
    
    -- Use Eternity Surge with or without Tip the Scales
    if settings.devastationSettings.useEternitySurge and
       API.IsSpellKnown(DEVASTATION_SPELLS.ETERNITY_SURGE) and 
       API.IsSpellUsable(DEVASTATION_SPELLS.ETERNITY_SURGE) then
        local empowerLevel = hasTipTheScales and 3 or self:GetEmpowermentLevel(settings.generalSettings.empowermentLevel)
        return {
            type = "empowered_spell",
            id = DEVASTATION_SPELLS.ETERNITY_SURGE,
            target = target,
            empowerLevel = empowerLevel
        }
    end
    
    -- Use Shattering Star (if talented)
    if hasShatteringStar and
       API.IsSpellKnown(DEVASTATION_SPELLS.SHATTERING_STAR) and 
       API.IsSpellUsable(DEVASTATION_SPELLS.SHATTERING_STAR) then
        return {
            type = "spell",
            id = DEVASTATION_SPELLS.SHATTERING_STAR,
            target = target
        }
    end
    
    -- Use Pyre with Essence Burst
    if settings.devastationSettings.usePyre and
       hasEssenceBurst and
       API.IsSpellKnown(DEVASTATION_SPELLS.PYRE) and 
       API.IsSpellUsable(DEVASTATION_SPELLS.PYRE) then
        return {
            type = "spell",
            id = DEVASTATION_SPELLS.PYRE,
            target = target
        }
    end
    
    -- Use Catalyze if talented
    if settings.devastationSettings.useCatalyze and
       hasCatalyze and
       API.IsSpellKnown(DEVASTATION_SPELLS.CATALYZE) and 
       API.IsSpellUsable(DEVASTATION_SPELLS.CATALYZE) then
        return {
            type = "spell",
            id = DEVASTATION_SPELLS.CATALYZE,
            target = target
        }
    end
    
    -- AoE: Disintegrate for multiple targets
    if aoeEnabled and
       API.IsSpellKnown(DEVASTATION_SPELLS.DISINTEGRATE) and 
       API.IsSpellUsable(DEVASTATION_SPELLS.DISINTEGRATE) then
        return {
            type = "spell",
            id = DEVASTATION_SPELLS.DISINTEGRATE,
            target = target
        }
    end
    
    -- AoE: Azure Strike for AoE
    if aoeEnabled and
       API.IsSpellKnown(DEVASTATION_SPELLS.AZURE_STRIKE) and 
       API.IsSpellUsable(DEVASTATION_SPELLS.AZURE_STRIKE) then
        return {
            type = "spell",
            id = DEVASTATION_SPELLS.AZURE_STRIKE,
            target = target
        }
    end
    
    -- Use Ancient Flame if talented
    if settings.devastationSettings.useAncientFlame and
       hasFireAttunement and
       API.IsSpellKnown(DEVASTATION_SPELLS.ANCIENT_FLAME) and 
       API.IsSpellUsable(DEVASTATION_SPELLS.ANCIENT_FLAME) then
        return {
            type = "spell",
            id = DEVASTATION_SPELLS.ANCIENT_FLAME,
            target = target
        }
    end
    
    -- Single target: Living Flame as filler
    if not aoeEnabled and
       API.IsSpellKnown(DEVASTATION_SPELLS.LIVING_FLAME) and 
       API.IsSpellUsable(DEVASTATION_SPELLS.LIVING_FLAME) then
        return {
            type = "spell",
            id = DEVASTATION_SPELLS.LIVING_FLAME,
            target = target
        }
    end
    
    -- Azure Strike as a fallback
    if API.IsSpellKnown(DEVASTATION_SPELLS.AZURE_STRIKE) and 
       API.IsSpellUsable(DEVASTATION_SPELLS.AZURE_STRIKE) then
        return {
            type = "spell",
            id = DEVASTATION_SPELLS.AZURE_STRIKE,
            target = target
        }
    end
    
    return nil
end

-- Preservation rotation
function EvokerModule:PreservationRotation()
    -- Check if we should execute
    if not self:ShouldExecuteRotation() then
        return nil
    end
    
    -- Get player and target
    local player = "player"
    local target = nil
    local lowestAlly = self:GetLowestHealthAlly()
    
    -- Get settings
    local settings = ConfigRegistry:GetSettings("Evoker")
    
    -- Common Combat Variables
    local health, maxHealth, healthPercent = API.GetUnitHealth(player)
    local mana, maxMana, manaPercent = API.GetUnitPower(player, Enum.PowerType.Mana)
    local injuredAllies = self:GetInjuredAlliesCount(80)
    local averageGroupHealth = self:GetAverageGroupHealth()
    
    -- Target specific variables
    local lowestAllyHealth, lowestAllyMaxHealth, lowestAllyHealthPercent = 100, 100, 100
    
    if lowestAlly and UnitExists(lowestAlly) then
        lowestAllyHealth, lowestAllyMaxHealth, lowestAllyHealthPercent = API.GetUnitHealth(lowestAlly)
    end
    
    -- Buff tracking
    local hasEcho = API.UnitHasBuff(player, BUFFS.ECHO)
    local hasTipTheScales = API.UnitHasBuff(player, BUFFS.TIP_THE_SCALES)
    
    -- Debuff tracking on targets with Dream Breath
    local targetsWithDreamBreath = self:GetTargetsWithDebuff(DEBUFFS.DREAM_BREATH)
    
    -- CD tracking
    local dreamBreathCD = API.GetSpellCooldown(PRESERVATION_SPELLS.DREAM_BREATH)
    local spiritbloomCD = API.GetSpellCooldown(PRESERVATION_SPELLS.SPIRITBLOOM)
    local reversionCD = API.GetSpellCooldown(PRESERVATION_SPELLS.REVERSION)
    local timeDilationCD = API.GetSpellCooldown(PRESERVATION_SPELLS.TIME_DILATION)
    local tipTheScalesCD = API.GetSpellCooldown(PRESERVATION_SPELLS.TIP_THE_SCALES)
    local dreamFlightCD = API.GetSpellCooldown(PRESERVATION_SPELLS.DREAMFLIGHT)
    
    -- Check if we have a harmful target for interrupts
    local harmfulTarget = UnitExists("target") and UnitCanAttack(player, "target") and not UnitIsDead("target") and "target" or nil
    
    -- Interrupt if needed
    if harmfulTarget and settings.generalSettings.useInterrupts and
       API.IsSpellKnown(PRESERVATION_SPELLS.QUELL) and 
       API.IsSpellUsable(PRESERVATION_SPELLS.QUELL) and
       API.ShouldInterrupt(harmfulTarget) then
        return {
            type = "spell",
            id = PRESERVATION_SPELLS.QUELL,
            target = harmfulTarget
        }
    end
    
    -- Dispel harmful effects
    if settings.generalSettings.useCauterizingFlame and
       lowestAlly and API.HasDispellableDebuff(lowestAlly, "Disease", "Poison", "Curse", "Bleed") and
       API.IsSpellKnown(PRESERVATION_SPELLS.CAUTERIZING_FLAME) and 
       API.IsSpellUsable(PRESERVATION_SPELLS.CAUTERIZING_FLAME) then
        return {
            type = "spell",
            id = PRESERVATION_SPELLS.CAUTERIZING_FLAME,
            target = lowestAlly
        }
    end
    
    -- Defensive abilities
    if settings.generalSettings.useDefensives then
        -- Use Obsidian Scales
        if healthPercent < settings.generalSettings.obsidianScalesThreshold and
           API.IsSpellKnown(PRESERVATION_SPELLS.OBSIDIAN_SCALES) and 
           API.IsSpellUsable(PRESERVATION_SPELLS.OBSIDIAN_SCALES) then
            return {
                type = "spell",
                id = PRESERVATION_SPELLS.OBSIDIAN_SCALES,
                target = player
            }
        end
        
        -- Use Renewing Blaze
        if healthPercent < settings.generalSettings.renewingBlazeThreshold and
           API.IsSpellKnown(PRESERVATION_SPELLS.RENEWING_BLAZE) and 
           API.IsSpellUsable(PRESERVATION_SPELLS.RENEWING_BLAZE) then
            return {
                type = "spell",
                id = PRESERVATION_SPELLS.RENEWING_BLAZE,
                target = player
            }
        end
        
        -- Use Zephyr for group damage prevention
        if settings.generalSettings.useZephyr and
           averageGroupHealth < 60 and
           API.IsSpellKnown(PRESERVATION_SPELLS.ZEPHYR) and 
           API.IsSpellUsable(PRESERVATION_SPELLS.ZEPHYR) then
            return {
                type = "spell",
                id = PRESERVATION_SPELLS.ZEPHYR,
                target = player
            }
        end
    end
    
    -- Use Emerald Communion for mana
    if settings.preservationSettings.useEmeraldCommunion and
       API.IsSpellKnown(PRESERVATION_SPELLS.EMERALD_COMMUNION) and 
       API.IsSpellUsable(PRESERVATION_SPELLS.EMERALD_COMMUNION) and
       mana < (maxMana * 0.4) then
        return {
            type = "spell",
            id = PRESERVATION_SPELLS.EMERALD_COMMUNION,
            target = player
        }
    end
    
    -- Apply Source of Magic to appropriate target
    if API.IsSpellKnown(PRESERVATION_SPELLS.SOURCE_OF_MAGIC) and 
       API.IsSpellUsable(PRESERVATION_SPELLS.SOURCE_OF_MAGIC) and
       settings.preservationSettings.sourceOfMagicTarget ~= "None" then
        local sourceTarget = self:GetSourceOfMagicTarget(settings.preservationSettings.sourceOfMagicTarget)
        if sourceTarget then
            return {
                type = "spell",
                id = PRESERVATION_SPELLS.SOURCE_OF_MAGIC,
                target = sourceTarget
            }
        end
    end
    
    -- Use Dream Flight for emergency group healing
    if settings.preservationSettings.useDreamFlight and
       averageGroupHealth <= settings.preservationSettings.dreamFlightThreshold and
       API.IsSpellKnown(PRESERVATION_SPELLS.DREAMFLIGHT) and 
       API.IsSpellUsable(PRESERVATION_SPELLS.DREAMFLIGHT) then
        return {
            type = "spell",
            id = PRESERVATION_SPELLS.DREAMFLIGHT,
            target = player
        }
    end
    
    -- Core rotation
    
    -- Use Tip the Scales for empower abilities
    if settings.generalSettings.useTipTheScales and
       not hasTipTheScales and
       (dreamBreathCD == 0 or spiritbloomCD == 0) and
       API.IsSpellKnown(PRESERVATION_SPELLS.TIP_THE_SCALES) and 
       API.IsSpellUsable(PRESERVATION_SPELLS.TIP_THE_SCALES) then
        return {
            type = "spell",
            id = PRESERVATION_SPELLS.TIP_THE_SCALES,
            target = player
        }
    end
    
    -- Use Dream Breath for group healing
    if settings.preservationSettings.useDreamBreath and
       (settings.preservationSettings.dreamBreathSetting == "Group Healing" or 
        settings.preservationSettings.dreamBreathSetting == "Both") and
       injuredAllies >= 3 and
       API.IsSpellKnown(PRESERVATION_SPELLS.DREAM_BREATH) and 
       API.IsSpellUsable(PRESERVATION_SPELLS.DREAM_BREATH) then
        local empowerLevel = hasTipTheScales and 3 or self:GetEmpowermentLevel(settings.generalSettings.empowermentLevel)
        return {
            type = "empowered_spell",
            id = PRESERVATION_SPELLS.DREAM_BREATH,
            target = lowestAlly or player,
            empowerLevel = empowerLevel
        }
    end
    
    -- Use Time Dilation on targets with Dream Breath
    if settings.preservationSettings.useTimeDilation and
       #targetsWithDreamBreath > 0 and
       API.IsSpellKnown(PRESERVATION_SPELLS.TIME_DILATION) and 
       API.IsSpellUsable(PRESERVATION_SPELLS.TIME_DILATION) then
        return {
            type = "spell",
            id = PRESERVATION_SPELLS.TIME_DILATION,
            target = targetsWithDreamBreath[1]
        }
    end
    
    -- Use Spiritbloom for burst healing
    if settings.preservationSettings.useSpiritbloom and
       lowestAlly and lowestAllyHealthPercent < 70 and
       API.IsSpellKnown(PRESERVATION_SPELLS.SPIRITBLOOM) and 
       API.IsSpellUsable(PRESERVATION_SPELLS.SPIRITBLOOM) then
        local empowerLevel = hasTipTheScales and 3 or self:GetEmpowermentLevel(settings.generalSettings.empowermentLevel)
        return {
            type = "empowered_spell",
            id = PRESERVATION_SPELLS.SPIRITBLOOM,
            target = lowestAlly,
            empowerLevel = empowerLevel
        }
    end
    
    -- Emergency: Reversion for single target healing
    if settings.preservationSettings.useReversion and
       lowestAlly and lowestAllyHealthPercent < 40 and
       API.IsSpellKnown(PRESERVATION_SPELLS.REVERSION) and 
       API.IsSpellUsable(PRESERVATION_SPELLS.REVERSION) then
        return {
            type = "spell",
            id = PRESERVATION_SPELLS.REVERSION,
            target = lowestAlly
        }
    end
    
    -- Use Dream Breath for single target if needed
    if settings.preservationSettings.useDreamBreath and
       (settings.preservationSettings.dreamBreathSetting == "Single Target" or 
        settings.preservationSettings.dreamBreathSetting == "Both") and
       lowestAlly and lowestAllyHealthPercent < 75 and
       API.IsSpellKnown(PRESERVATION_SPELLS.DREAM_BREATH) and 
       API.IsSpellUsable(PRESERVATION_SPELLS.DREAM_BREATH) then
        local empowerLevel = hasTipTheScales and 3 or self:GetEmpowermentLevel(settings.generalSettings.empowermentLevel)
        return {
            type = "empowered_spell",
            id = PRESERVATION_SPELLS.DREAM_BREATH,
            target = lowestAlly,
            empowerLevel = empowerLevel
        }
    end
    
    -- Use Echo efficiently
    if settings.preservationSettings.useEchoEfficiently and
       hasEcho and
       lowestAlly and lowestAllyHealthPercent < 85 and
       API.IsSpellKnown(PRESERVATION_SPELLS.LIVING_FLAME) and 
       API.IsSpellUsable(PRESERVATION_SPELLS.LIVING_FLAME) then
        return {
            type = "spell",
            id = PRESERVATION_SPELLS.LIVING_FLAME,
            target = lowestAlly
        }
    end
    
    -- Use Emerald Blossom for group healing
    if injuredAllies >= settings.preservationSettings.emeraldBlossomThreshold and
       API.IsSpellKnown(PRESERVATION_SPELLS.EMERALD_BLOSSOM) and 
       API.IsSpellUsable(PRESERVATION_SPELLS.EMERALD_BLOSSOM) then
        return {
            type = "spell",
            id = PRESERVATION_SPELLS.EMERALD_BLOSSOM,
            target = player
        }
    end
    
    -- Verdant Embrace for HoT
    if lowestAlly and lowestAllyHealthPercent < 80 and
       API.IsSpellKnown(PRESERVATION_SPELLS.VERDANT_EMBRACE) and 
       API.IsSpellUsable(PRESERVATION_SPELLS.VERDANT_EMBRACE) then
        return {
            type = "spell",
            id = PRESERVATION_SPELLS.VERDANT_EMBRACE,
            target = lowestAlly
        }
    end
    
    -- Living Flame for efficient healing
    if lowestAlly and lowestAllyHealthPercent < 90 and
       API.IsSpellKnown(PRESERVATION_SPELLS.LIVING_FLAME) and 
       API.IsSpellUsable(PRESERVATION_SPELLS.LIVING_FLAME) then
        return {
            type = "spell",
            id = PRESERVATION_SPELLS.LIVING_FLAME,
            target = lowestAlly
        }
    end
    
    -- DPS if healing isn't needed
    if harmfulTarget and (lowestAllyHealthPercent >= 90 or not lowestAlly) then
        -- Fire Breath for DPS
        if API.IsSpellKnown(DEVASTATING_SPELLS.FIRE_BREATH) and 
           API.IsSpellUsable(DEVASTATING_SPELLS.FIRE_BREATH) then
            return {
                type = "empowered_spell",
                id = DEVASTATING_SPELLS.FIRE_BREATH,
                target = harmfulTarget,
                empowerLevel = 1
            }
        end
        
        -- Azure Strike for DPS
        if API.IsSpellKnown(PRESERVATION_SPELLS.AZURE_STRIKE) and 
           API.IsSpellUsable(PRESERVATION_SPELLS.AZURE_STRIKE) then
            return {
                type = "spell",
                id = PRESERVATION_SPELLS.AZURE_STRIKE,
                target = harmfulTarget
            }
        end
    end
    
    return nil
end

-- Augmentation rotation
function EvokerModule:AugmentationRotation()
    -- Check if we should execute
    if not self:ShouldExecuteRotation() then
        return nil
    end
    
    -- Get player and target
    local player = "player"
    local target = nil
    local partyMembers = self:GetPartyMembers()
    
    -- Check if we have a harmful target
    if UnitExists("target") and UnitCanAttack(player, "target") and not UnitIsDead("target") then
        target = "target"
    end
    
    -- Get settings
    local settings = ConfigRegistry:GetSettings("Evoker")
    
    -- Common Combat Variables
    local health, maxHealth, healthPercent = API.GetUnitHealth(player)
    local mana = API.GetUnitPower(player, Enum.PowerType.Mana)
    local maxMana = API.GetUnitPowerMax(player, Enum.PowerType.Mana)
    local enemies = API.GetEnemyCount(10)
    local aoeEnabled = settings.augmentationSettings.aoeThreshold <= enemies
    
    -- Buff tracking
    local hasTipTheScales = API.UnitHasBuff(player, BUFFS.TIP_THE_SCALES)
    local hasEbonMight = API.UnitHasBuff(player, BUFFS.EBON_MIGHT)
    local hasBreathOfEons = API.UnitHasBuff(player, BUFFS.BREATH_OF_EONS)
    local hasSpatialParadox = API.UnitHasBuff(player, BUFFS.SPATIAL_PARADOX)
    
    -- Allies with buffs
    local alliesWithEbonMight = self:GetAlliesWithBuff(BUFFS.EBON_MIGHT)
    local alliesWithPrescience = self:GetAlliesWithBuff(BUFFS.PRESCIENCE)
    local alliesWithBlessing = self:GetAlliesWithBuff(BUFFS.BLESSING_OF_BRONZE)
    local alliesWithBlisteringScales = self:GetAlliesWithBuff(target, AUGMENTATION_SPELLS.BLISTERING_SCALES)
    
    -- CD tracking
    local fireBreathCD = API.GetSpellCooldown(AUGMENTATION_SPELLS.FIRE_BREATH)
    local eternitySurgeCD = API.GetSpellCooldown(AUGMENTATION_SPELLS.ETERNITY_SURGE)
    local ebonMightCD = API.GetSpellCooldown(AUGMENTATION_SPELLS.EBON_MIGHT)
    local breathOfEonsCD = API.GetSpellCooldown(AUGMENTATION_SPELLS.BREATH_OF_EONS)
    local blisteringScalesCD = API.GetSpellCooldown(AUGMENTATION_SPELLS.BLISTERING_SCALES)
    local prescienceCD = API.GetSpellCooldown(AUGMENTATION_SPELLS.PRESCIENCE)
    local blessingOfBronzeCD = API.GetSpellCooldown(AUGMENTATION_SPELLS.BLESSING_OF_BRONZE)
    local tipTheScalesCD = API.GetSpellCooldown(AUGMENTATION_SPELLS.TIP_THE_SCALES)
    
    -- Interrupt if needed
    if target and settings.generalSettings.useInterrupts and
       API.IsSpellKnown(AUGMENTATION_SPELLS.QUELL) and 
       API.IsSpellUsable(AUGMENTATION_SPELLS.QUELL) and
       API.ShouldInterrupt(target) then
        return {
            type = "spell",
            id = AUGMENTATION_SPELLS.QUELL,
            target = target
        }
    end
    
    -- Dispel harmful effects
    if settings.generalSettings.useCauterizingFlame and
       self:HasGroupMemberWithDispellableDebuff("Disease", "Poison", "Curse", "Bleed") and
       API.IsSpellKnown(AUGMENTATION_SPELLS.CAUTERIZING_FLAME) and 
       API.IsSpellUsable(AUGMENTATION_SPELLS.CAUTERIZING_FLAME) then
        local dispelTarget = self:GetGroupMemberWithDispellableDebuff("Disease", "Poison", "Curse", "Bleed")
        if dispelTarget then
            return {
                type = "spell",
                id = AUGMENTATION_SPELLS.CAUTERIZING_FLAME,
                target = dispelTarget
            }
        end
    end
    
    -- Defensive abilities
    if settings.generalSettings.useDefensives then
        -- Use Obsidian Scales
        if healthPercent < settings.generalSettings.obsidianScalesThreshold and
           API.IsSpellKnown(AUGMENTATION_SPELLS.OBSIDIAN_SCALES) and 
           API.IsSpellUsable(AUGMENTATION_SPELLS.OBSIDIAN_SCALES) then
            return {
                type = "spell",
                id = AUGMENTATION_SPELLS.OBSIDIAN_SCALES,
                target = player
            }
        end
        
        -- Use Renewing Blaze
        if healthPercent < settings.generalSettings.renewingBlazeThreshold and
           API.IsSpellKnown(AUGMENTATION_SPELLS.RENEWING_BLAZE) and 
           API.IsSpellUsable(AUGMENTATION_SPELLS.RENEWING_BLAZE) then
            return {
                type = "spell",
                id = AUGMENTATION_SPELLS.RENEWING_BLAZE,
                target = player
            }
        end
        
        -- Use Zephyr for group damage prevention
        if settings.generalSettings.useZephyr and
           inCombat and self:IsGroupInDanger() and
           API.IsSpellKnown(AUGMENTATION_SPELLS.ZEPHYR) and 
           API.IsSpellUsable(AUGMENTATION_SPELLS.ZEPHYR) then
            return {
                type = "spell",
                id = AUGMENTATION_SPELLS.ZEPHYR,
                target = player
            }
        end
        
        -- Use Time Stop for emergency
        if settings.augmentationSettings.useTimeStop and
           inCombat and self:IsGroupInDanger() and
           API.IsSpellKnown(AUGMENTATION_SPELLS.TIME_STOP) and 
           API.IsSpellUsable(AUGMENTATION_SPELLS.TIME_STOP) then
            return {
                type = "spell",
                id = AUGMENTATION_SPELLS.TIME_STOP,
                target = player
            }
        end
    end
    
    -- Core rotation for buffs and utility
    
    -- Use Ebon Might
    if settings.augmentationSettings.useEbonMight and
       inCombat and
       #alliesWithEbonMight < settings.augmentationSettings.ebonMightSpreadTargets and
       API.IsSpellKnown(AUGMENTATION_SPELLS.EBON_MIGHT) and 
       API.IsSpellUsable(AUGMENTATION_SPELLS.EBON_MIGHT) then
        return {
            type = "spell",
            id = AUGMENTATION_SPELLS.EBON_MIGHT,
            target = player
        }
    end
    
    -- Use Breath of Eons
    if settings.augmentationSettings.useBreathOfEons and
       inCombat and
       not hasBreathOfEons and
       API.IsSpellKnown(AUGMENTATION_SPELLS.BREATH_OF_EONS) and 
       API.IsSpellUsable(AUGMENTATION_SPELLS.BREATH_OF_EONS) then
        return {
            type = "spell",
            id = AUGMENTATION_SPELLS.BREATH_OF_EONS,
            target = player
        }
    end
    
    -- Use Prescience 
    if settings.augmentationSettings.usePrescience and
       #alliesWithPrescience < 2 and
       API.IsSpellKnown(AUGMENTATION_SPELLS.PRESCIENCE) and 
       API.IsSpellUsable(AUGMENTATION_SPELLS.PRESCIENCE) then
        local prescienceTarget = self:GetBestDpsTarget()
        if prescienceTarget then
            return {
                type = "spell",
                id = AUGMENTATION_SPELLS.PRESCIENCE,
                target = prescienceTarget
            }
        end
    end
    
    -- Use Blessing of Bronze
    if settings.augmentationSettings.useBlessingOfBronze and
       #alliesWithBlessing < 2 and
       API.IsSpellKnown(AUGMENTATION_SPELLS.BLESSING_OF_BRONZE) and 
       API.IsSpellUsable(AUGMENTATION_SPELLS.BLESSING_OF_BRONZE) then
        return {
            type = "spell",
            id = AUGMENTATION_SPELLS.BLESSING_OF_BRONZE,
            target = player
        }
    end
    
    -- Use Blistering Scales on appropriate target
    if settings.augmentationSettings.useBlistering and
       #alliesWithBlisteringScales < 2 and
       API.IsSpellKnown(AUGMENTATION_SPELLS.BLISTERING_SCALES) and 
       API.IsSpellUsable(AUGMENTATION_SPELLS.BLISTERING_SCALES) then
        local blisteringTarget = self:GetBlisteringScalesTarget(settings.augmentationSettings.blisteringScalesTarget)
        if blisteringTarget then
            return {
                type = "spell",
                id = AUGMENTATION_SPELLS.BLISTERING_SCALES,
                target = blisteringTarget
            }
        end
    end
    
    -- Use Tip the Scales for empower abilities
    if settings.generalSettings.useTipTheScales and
       not hasTipTheScales and target and
       (fireBreathCD == 0 or eternitySurgeCD == 0) and
       API.IsSpellKnown(AUGMENTATION_SPELLS.TIP_THE_SCALES) and 
       API.IsSpellUsable(AUGMENTATION_SPELLS.TIP_THE_SCALES) then
        return {
            type = "spell",
            id = AUGMENTATION_SPELLS.TIP_THE_SCALES,
            target = player
        }
    end
    
    -- Combat abilities when having a target
    if target then
        -- Use Fire Breath with or without Tip the Scales
        if API.IsSpellKnown(AUGMENTATION_SPELLS.FIRE_BREATH) and 
           API.IsSpellUsable(AUGMENTATION_SPELLS.FIRE_BREATH) then
            local empowerLevel = hasTipTheScales and 3 or self:GetEmpowermentLevel(settings.generalSettings.empowermentLevel)
            return {
                type = "empowered_spell",
                id = AUGMENTATION_SPELLS.FIRE_BREATH,
                target = target,
                empowerLevel = empowerLevel
            }
        end
        
        -- Use Eternity Surge with or without Tip the Scales
        if API.IsSpellKnown(AUGMENTATION_SPELLS.ETERNITY_SURGE) and 
           API.IsSpellUsable(AUGMENTATION_SPELLS.ETERNITY_SURGE) then
            local empowerLevel = hasTipTheScales and 3 or self:GetEmpowermentLevel(settings.generalSettings.empowermentLevel)
            return {
                type = "empowered_spell",
                id = AUGMENTATION_SPELLS.ETERNITY_SURGE,
                target = target,
                empowerLevel = empowerLevel
            }
        end
        
        -- Use Breathe in rotation
        if settings.augmentationSettings.useBreathe and
           API.IsSpellKnown(AUGMENTATION_SPELLS.BREATHE) and 
           API.IsSpellUsable(AUGMENTATION_SPELLS.BREATHE) then
            return {
                type = "spell",
                id = AUGMENTATION_SPELLS.BREATHE,
                target = player  -- Breathe affects the Evoker first
            }
        end
        
        -- Use Spatial Paradox
        if settings.augmentationSettings.useSpatialParadox and
           not hasSpatialParadox and
           API.IsSpellKnown(AUGMENTATION_SPELLS.SPATIAL_PARADOX) and 
           API.IsSpellUsable(AUGMENTATION_SPELLS.SPATIAL_PARADOX) then
            return {
                type = "spell",
                id = AUGMENTATION_SPELLS.SPATIAL_PARADOX,
                target = player
            }
        end
        
        -- Use Engulf on cooldown
        if API.IsSpellKnown(AUGMENTATION_SPELLS.ENGULF) and 
           API.IsSpellUsable(AUGMENTATION_SPELLS.ENGULF) then
            return {
                type = "spell",
                id = AUGMENTATION_SPELLS.ENGULF,
                target = target
            }
        end
        
        -- Eye Beam for AoE
        if aoeEnabled and
           API.IsSpellKnown(AUGMENTATION_SPELLS.EYE_BEAM) and 
           API.IsSpellUsable(AUGMENTATION_SPELLS.EYE_BEAM) then
            return {
                type = "spell",
                id = AUGMENTATION_SPELLS.EYE_BEAM,
                target = target
            }
        end
        
        -- Use Disintegrate
        if API.IsSpellKnown(AUGMENTATION_SPELLS.DISINTEGRATE) and 
           API.IsSpellUsable(AUGMENTATION_SPELLS.DISINTEGRATE) then
            return {
                type = "spell",
                id = AUGMENTATION_SPELLS.DISINTEGRATE,
                target = target
            }
        end
        
        -- AoE: Azure Strike for AoE
        if aoeEnabled and
           API.IsSpellKnown(AUGMENTATION_SPELLS.AZURE_STRIKE) and 
           API.IsSpellUsable(AUGMENTATION_SPELLS.AZURE_STRIKE) then
            return {
                type = "spell",
                id = AUGMENTATION_SPELLS.AZURE_STRIKE,
                target = target
            }
        end
        
        -- Single target: Living Flame as filler
        if not aoeEnabled and
           API.IsSpellKnown(AUGMENTATION_SPELLS.LIVING_FLAME) and 
           API.IsSpellUsable(AUGMENTATION_SPELLS.LIVING_FLAME) then
            return {
                type = "spell",
                id = AUGMENTATION_SPELLS.LIVING_FLAME,
                target = target
            }
        end
        
        -- Azure Strike as a fallback
        if API.IsSpellKnown(AUGMENTATION_SPELLS.AZURE_STRIKE) and 
           API.IsSpellUsable(AUGMENTATION_SPELLS.AZURE_STRIKE) then
            return {
                type = "spell",
                id = AUGMENTATION_SPELLS.AZURE_STRIKE,
                target = target
            }
        end
    end
    
    return nil
end

-- Get lowest health ally
function EvokerModule:GetLowestHealthAlly()
    local lowestUnit = nil
    local lowestHealth = 100
    
    -- Check party members
    for i = 1, 4 do
        local unit = "party" .. i
        if UnitExists(unit) and not UnitIsDead(unit) then
            local health, maxHealth, healthPercent = API.GetUnitHealth(unit)
            if healthPercent < lowestHealth then
                lowestHealth = healthPercent
                lowestUnit = unit
            end
        end
    end
    
    -- Check player
    local playerHealth, playerMaxHealth, playerHealthPercent = API.GetUnitHealth("player")
    if playerHealthPercent < lowestHealth then
        lowestHealth = playerHealthPercent
        lowestUnit = "player"
    end
    
    return lowestUnit
end

-- Get injured allies count
function EvokerModule:GetInjuredAlliesCount(threshold)
    local count = 0
    
    for i = 1, 4 do
        local unit = "party" .. i
        if UnitExists(unit) and not UnitIsDead(unit) then
            local health, maxHealth, healthPercent = API.GetUnitHealth(unit)
            if healthPercent < threshold then
                count = count + 1
            end
        end
    end
    
    -- Include player
    local playerHealth, playerMaxHealth, playerHealthPercent = API.GetUnitHealth("player")
    if playerHealthPercent < threshold then
        count = count + 1
    end
    
    return count
end

-- Get average group health
function EvokerModule:GetAverageGroupHealth()
    local totalHealth = 0
    local count = 0
    
    for i = 1, 4 do
        local unit = "party" .. i
        if UnitExists(unit) and not UnitIsDead(unit) then
            local health, maxHealth, healthPercent = API.GetUnitHealth(unit)
            totalHealth = totalHealth + healthPercent
            count = count + 1
        end
    end
    
    -- Include player
    local playerHealth, playerMaxHealth, playerHealthPercent = API.GetUnitHealth("player")
    totalHealth = totalHealth + playerHealthPercent
    count = count + 1
    
    return count > 0 and (totalHealth / count) or 100
end

-- Get Source of Magic target
function EvokerModule:GetSourceOfMagicTarget(type)
    if type == "Healer" then
        for i = 1, 4 do
            local unit = "party" .. i
            if UnitExists(unit) and not UnitIsDead(unit) and UnitGroupRolesAssigned(unit) == "HEALER" then
                return unit
            end
        end
    elseif type == "DPS Caster" then
        for i = 1, 4 do
            local unit = "party" .. i
            if UnitExists(unit) and not UnitIsDead(unit) and
               UnitGroupRolesAssigned(unit) == "DAMAGER" and
               self:IsCaster(unit) then
                return unit
            end
        end
    elseif type == "Self" then
        return "player"
    end
    
    -- Default to first caster DPS or self
    for i = 1, 4 do
        local unit = "party" .. i
        if UnitExists(unit) and not UnitIsDead(unit) and self:IsCaster(unit) then
            return unit
        end
    end
    
    return "player"
end

-- Get Blistering Scales target
function EvokerModule:GetBlisteringScalesTarget(type)
    if type == "Tank" then
        for i = 1, 4 do
            local unit = "party" .. i
            if UnitExists(unit) and not UnitIsDead(unit) and UnitGroupRolesAssigned(unit) == "TANK" then
                return unit
            end
        end
    elseif type == "Melee DPS" then
        for i = 1, 4 do
            local unit = "party" .. i
            if UnitExists(unit) and not UnitIsDead(unit) and
               UnitGroupRolesAssigned(unit) == "DAMAGER" and
               not self:IsCaster(unit) then
                return unit
            end
        end
    elseif type == "Self" then
        return "player"
    elseif type == "Smart" then
        -- First try tank
        for i = 1, 4 do
            local unit = "party" .. i
            if UnitExists(unit) and not UnitIsDead(unit) and UnitGroupRolesAssigned(unit) == "TANK" then
                return unit
            end
        end
        
        -- Then try melee DPS
        for i = 1, 4 do
            local unit = "party" .. i
            if UnitExists(unit) and not UnitIsDead(unit) and
               UnitGroupRolesAssigned(unit) == "DAMAGER" and
               not self:IsCaster(unit) then
                return unit
            end
        end
    end
    
    -- Default to self if no valid target
    return "player"
end

-- Get targets with specified debuff
function EvokerModule:GetTargetsWithDebuff(debuffID)
    local units = {}
    
    -- Check party members
    for i = 1, 4 do
        local unit = "party" .. i
        if UnitExists(unit) and not UnitIsDead(unit) and API.UnitHasDebuff(unit, debuffID) then
            table.insert(units, unit)
        end
    end
    
    -- Check player
    if API.UnitHasDebuff("player", debuffID) then
        table.insert(units, "player")
    end
    
    return units
end

-- Get allies with a specific buff
function EvokerModule:GetAlliesWithBuff(buffID)
    local units = {}
    
    -- Check party members
    for i = 1, 4 do
        local unit = "party" .. i
        if UnitExists(unit) and not UnitIsDead(unit) and API.UnitHasBuff(unit, buffID) then
            table.insert(units, unit)
        end
    end
    
    -- Check player
    if API.UnitHasBuff("player", buffID) then
        table.insert(units, "player")
    end
    
    return units
end

-- Get party members
function EvokerModule:GetPartyMembers()
    local units = {}
    
    -- Check party members
    for i = 1, 4 do
        local unit = "party" .. i
        if UnitExists(unit) and not UnitIsDead(unit) then
            table.insert(units, unit)
        end
    end
    
    -- Include player
    table.insert(units, "player")
    
    return units
end

-- Get empowerment level based on settings
function EvokerModule:GetEmpowermentLevel(setting)
    if setting == "Max Level" then
        return 3
    elseif setting == "Level 3" then
        return 3
    elseif setting == "Level 2" then
        return 2
    elseif setting == "Level 1" then
        return 1
    end
    
    -- Default to max level
    return 3
end

-- Check if a unit is likely a caster
function EvokerModule:IsCaster(unit)
    local class = select(2, UnitClass(unit))
    return class == "MAGE" or class == "WARLOCK" or class == "PRIEST" or
           (class == "DRUID" and GetSpecialization(unit) == 1) or  -- Balance
           (class == "SHAMAN" and GetSpecialization(unit) == 1) or -- Elemental
           class == "EVOKER"
end

-- Check if group is in danger
function EvokerModule:IsGroupInDanger()
    local averageHealth = self:GetAverageGroupHealth()
    local injuredCount = self:GetInjuredAlliesCount(60)
    
    return averageHealth < 50 or injuredCount >= 3
end

-- Check if any group member has a dispellable debuff of the specified types
function EvokerModule:HasGroupMemberWithDispellableDebuff(...)
    local debuffTypes = {...}
    
    for i = 1, 4 do
        local unit = "party" .. i
        if UnitExists(unit) and not UnitIsDead(unit) and
           API.HasDispellableDebuff(unit, unpack(debuffTypes)) then
            return true
        end
    end
    
    if API.HasDispellableDebuff("player", unpack(debuffTypes)) then
        return true
    end
    
    return false
end

-- Get a group member with a dispellable debuff of the specified types
function EvokerModule:GetGroupMemberWithDispellableDebuff(...)
    local debuffTypes = {...}
    
    for i = 1, 4 do
        local unit = "party" .. i
        if UnitExists(unit) and not UnitIsDead(unit) and
           API.HasDispellableDebuff(unit, unpack(debuffTypes)) then
            return unit
        end
    end
    
    if API.HasDispellableDebuff("player", unpack(debuffTypes)) then
        return "player"
    end
    
    return nil
end

-- Get best DPS target for buffs
function EvokerModule:GetBestDpsTarget()
    -- Try to find a DPS first
    for i = 1, 4 do
        local unit = "party" .. i
        if UnitExists(unit) and not UnitIsDead(unit) and
           UnitGroupRolesAssigned(unit) == "DAMAGER" then
            return unit
        end
    end
    
    -- Then try tank
    for i = 1, 4 do
        local unit = "party" .. i
        if UnitExists(unit) and not UnitIsDead(unit) and
           UnitGroupRolesAssigned(unit) == "TANK" then
            return unit
        end
    end
    
    -- Default to player if no DPS or tank
    return "player"
end

-- Helper functions
-- Check if a unit has dispellable debuffs
function API.HasDispellableDebuff(unit, ...)
    local debuffTypes = {...}
    
    -- Basic implementation - this would be expanded in a real addon
    for i = 1, 40 do
        local name, _, _, debuffType, _, _, _, _, _, spellId = UnitDebuff(unit, i)
        if name and debuffType then
            for _, type in ipairs(debuffTypes) do
                if type == debuffType or (type == "Bleed" and self:IsBleedEffect(spellId)) then
                    return true
                end
            end
        end
    end
    
    return false
end

-- Check if a debuff is a bleed effect
function API.IsBleedEffect(spellId)
    -- In a real implementation, this would check if the debuff is a bleed
    -- For our mock implementation, we'll return false
    return false
end

-- Should execute rotation
function EvokerModule:ShouldExecuteRotation()
    if not isEnabled then
        return false
    end
    
    -- Check if player matches class
    local playerInfo = API.GetPlayerInfo()
    if playerInfo.class ~= "EVOKER" then
        return false
    end
    
    return true
end

-- Register for export
WR.Evoker = EvokerModule

return EvokerModule