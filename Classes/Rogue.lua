------------------------------------------
-- WindrunnerRotations - Rogue Class Module
-- Author: VortexQ8
-- The War Within Season 2
------------------------------------------

local addonName, WR = ...
local RogueModule = {}
WR.Rogue = RogueModule

-- Dependencies
local API = WR.API
local ConfigRegistry = WR.ConfigRegistry
local RotationManager = WR.RotationManager
local ErrorHandler = WR.ErrorHandler
local CombatAnalysis = WR.CombatAnalysis
local AntiDetectionSystem = WR.AntiDetectionSystem
local PvPManager = WR.PvPManager

-- Rogue constants
local CLASS_ID = 4 -- Rogue class ID
local SPEC_ASSASSINATION = 259
local SPEC_OUTLAW = 260
local SPEC_SUBTLETY = 261

-- Current player data
local playerSpec = 0
local isEnabled = true
local inCombat = false

-- Spell IDs for Assassination Rogue (The War Within, Season 2)
local ASSASSINATION_SPELLS = {
    -- Core abilities
    MUTILATE = 1329,
    ENVENOM = 32645,
    RUPTURE = 1943,
    GARROTE = 703,
    FAN_OF_KNIVES = 51723,
    DEADLY_POISON = 2823,
    CRIMSON_TEMPEST = 121411,
    KIDNEY_SHOT = 408,
    CHEAP_SHOT = 1833,
    VENDETTA = 79140,
    KINGSBANE = 385627,
    DEATHMARK = 360194,
    SHIV = 5938,
    
    -- Defensive & utility
    CLOAK_OF_SHADOWS = 31224,
    EVASION = 5277,
    VANISH = 1856,
    FEINT = 1966,
    CRIMSON_VIAL = 185311,
    TRICKS_OF_THE_TRADE = 57934,
    BLIND = 2094,
    KICK = 1766,
    DISTRACT = 2836,
    SPRINT = 2983,
    
    -- Talents
    EXSANGUINATE = 200806,
    MASTER_ASSASSIN = 255989,
    POISON_BOMB = 255544,
    INTERNAL_BLEEDING = 154904,
    MASTER_POISONER = 196864,
    ELABORATE_PLANNING = 193640,
    INDISCRIMINATE_CARNAGE = 381802,
    SEPSIS = 385408,
    AMPLIFYING_POISON = 381664,
    
    -- Season 2 Abilities
    LETHAL_POISON = 426591, -- New in TWW Season 2
    IMPROVED_GARROTE = 426594, -- New in TWW Season 2
    IMPROVED_RUPTURE = 426595, -- New in TWW Season 2
    TINY_TOXIC_BLADE = 381623, -- New in TWW Season 2
    FATAL_MIXOLOGY = 378499, -- New in TWW Season 2
    ARTERIAL_PRECISION = 400783, -- New in TWW Season 2
    SCORPID_VENOM = 425339, -- New in TWW Season 2
    CAUSTIC_FILAMENTS = 394959, -- New in TWW Season 2
    FLYING_DAGGERS = 381631, -- Enhanced in TWW Season 2
    SERRATED_BONE_SPIKE = 385424, -- Enhanced in TWW Season 2
    DEADLY_BREW = 381637, -- New in TWW Season 2
    IMPROVED_POISONS = 381624, -- New in TWW Season 2
    VIRULENT_POISONS = 381620, -- New in TWW Season 2
    DOOMBLADE = 381673, -- New in TWW Season 2
    DEEPENING_WOUNDS = 382750, -- New in TWW Season 2
    
    -- Misc
    SHROUD_OF_CONCEALMENT = 114018,
    SHADOWSTEP = 36554,
    SLICE_AND_DICE = 315496,
    SABER_SLASH = 193315,
    STEALTH = 1784,
    WOUND_POISON = 8679,
    NUMBING_POISON = 5761
}

-- Spell IDs for Outlaw Rogue (The War Within, Season 2)
local OUTLAW_SPELLS = {
    -- Core abilities
    SINISTER_STRIKE = 193315,
    PISTOL_SHOT = 185763,
    DISPATCH = 2098,
    BETWEEN_THE_EYES = 315341,
    BLADE_FLURRY = 13877,
    SLICE_AND_DICE = 315496,
    ROLL_THE_BONES = 315508,
    KIDNEY_SHOT = 408,
    CHEAP_SHOT = 1833,
    ADRENALINE_RUSH = 13750,
    GHOSTLY_STRIKE = 196937,
    KILLING_SPREE = 51690,
    BLADE_RUSH = 271877,
    
    -- Defensive & utility
    CLOAK_OF_SHADOWS = 31224,
    EVASION = 5277,
    VANISH = 1856,
    FEINT = 1966,
    CRIMSON_VIAL = 185311,
    TRICKS_OF_THE_TRADE = 57934,
    BLIND = 2094,
    KICK = 1766,
    DISTRACT = 2836,
    SPRINT = 2983,
    GRAPPLING_HOOK = 195457,
    
    -- Talents
    ALACRITY = 193539,
    QUICK_DRAW = 196938,
    DREADBLADES = 343142,
    WEAPONMASTER = 200733,
    LOADED_DICE = 256170,
    RESTLESS_BLADES = 79096,
    DANCING_STEEL = 272026,
    SEPSIS = 385408,
    ECHOING_REPRIMAND = 385616,
    
    -- Season 2 Abilities
    THIEFS_VERSATILITY = 381619, -- New in TWW Season 2
    IMPROVED_ADRENALINE_RUSH = 381754, -- New in TWW Season 2
    FLOAT_LIKE_A_BUTTERFLY = 354897, -- New in TWW Season 2
    FLEET_FOOTED = 378813, -- New in TWW Season 2
    SUMMARILY_DISPATCHED = 381990, -- New in TWW Season 2
    IMPROVED_BETWEEN_THE_EYES = 235484, -- Enhanced in TWW Season 2
    TRIPLE_THREAT = 381894, -- New in TWW Season 2
    FAN_THE_HAMMER = 381846, -- New in TWW Season 2
    AUDACITY = 381845, -- New in TWW Season 2
    KEEP_IT_ROLLING = 381989, -- New in TWW Season 2
    PRECISE_CUTS = 381985, -- New in TWW Season 2
    HEAVY_HITTER = 381885, -- New in TWW Season 2
    STORM_CALLER = 425848, -- New in TWW Season 2
    TREASURE_HUNTER = 428539, -- New in TWW Season 2
    BOARDING_PARTY = 401987, -- New in TWW Season 2
    
    -- Misc
    SHROUD_OF_CONCEALMENT = 114018,
    STEALTH = 1784
}

-- Spell IDs for Subtlety Rogue (The War Within, Season 2)
local SUBTLETY_SPELLS = {
    -- Core abilities
    BACKSTAB = 53,
    SHADOWSTRIKE = 185438,
    EVISCERATE = 196819,
    RUPTURE = 1943,
    BLACK_POWDER = 319175,
    SHADOW_DANCE = 185313,
    SYMBOLS_OF_DEATH = 212283,
    SECRET_TECHNIQUE = 280719,
    SHURIKEN_STORM = 197835,
    SHURIKEN_TOSS = 114014,
    CHEAP_SHOT = 1833,
    KIDNEY_SHOT = 408,
    
    -- Defensive & utility
    CLOAK_OF_SHADOWS = 31224,
    EVASION = 5277,
    VANISH = 1856,
    FEINT = 1966,
    CRIMSON_VIAL = 185311,
    TRICKS_OF_THE_TRADE = 57934,
    BLIND = 2094,
    KICK = 1766,
    DISTRACT = 2836,
    SPRINT = 2983,
    
    -- Talents
    SHADOW_BLADES = 121471,
    DARK_SHADOW = 245687,
    SUBTERFUGE = 108208,
    MASTER_OF_SHADOWS = 196976,
    NIGHTSTALKER = 14062,
    ENVELOPING_SHADOWS = 238104,
    DEEPER_DAGGERS = 198703,
    SEPSIS = 385408,
    GOREMAWS_BITE = 426591,
    
    -- Season 2 Abilities
    LINGERING_SHADOW = 382745, -- New in TWW Season 2
    IMPROVED_SHADOW_DANCE = 393972, -- New in TWW Season 2
    FINALITY = 382742, -- New in TWW Season 2
    FLAGELLATION = 384631, -- New in TWW Season 2
    SILENT_STORM = 385722, -- New in TWW Season 2
    IMPROVED_SHADOW_TECHNIQUES = 394023, -- New in TWW Season 2
    PERFORATE = 427037, -- New in TWW Season 2
    INEVITABILITY = 382512, -- New in TWW Season 2
    SOOTHING_DARKNESS = 393970, -- New in TWW Season 2
    PLANNED_EXECUTION = 382508, -- New in TWW Season 2
    DEEPENING_SHADOWS = 185314, -- Enhanced in TWW Season 2
    THE_ROTTEN = 382015, -- New in TWW Season 2
    INVIGORATING_SHADOWDUST = 382523, -- New in TWW Season 2
    SHADOW_VAULT = 382528, -- New in TWW Season 2
    IMPROVED_FIND_WEAKNESS = 394320, -- New in TWW Season 2
    
    -- Misc
    SHROUD_OF_CONCEALMENT = 114018,
    SHADOWSTEP = 36554,
    SLICE_AND_DICE = 315496,
    SHADOW_TECHNIQUES = 196911,
    STEALTH = 1784,
    PREMEDITATION = 343160
}

-- Important buffs to track
local BUFFS = {
    -- Assassination
    MASTER_ASSASSIN = 256735,
    ELABORATE_PLANNING = 193641,
    ENVENOM = 32645,
    DEADLY_POISON = 2823,
    WOUND_POISON = 8679,
    NUMBING_POISON = 5761,
    VENDETTA = 79140,
    KINGSBANE = 385627,
    DEATHMARK = 360194,
    INDISCRIMINATE_CARNAGE = 381802,
    
    -- Outlaw
    SLICE_AND_DICE = 315496,
    ADRENALINE_RUSH = 13750,
    OPPORTUNITY = 195627,
    BLADE_FLURRY = 13877,
    DREADBLADES = 343142,
    ALACRITY = 193538,
    GHOSTLY_STRIKE = 196937,
    BURIED_TREASURE = 199600,
    GRAND_MELEE = 193358,
    SKULL_AND_CROSSBONES = 199603,
    TRUE_BEARING = 193359,
    RUTHLESS_PRECISION = 193357,
    BROADSIDE = 193356,
    KILLING_SPREE = 51690,
    BLADE_RUSH = 271877,
    
    -- Subtlety
    SHADOW_DANCE = 185422,
    SYMBOLS_OF_DEATH = 212283,
    SHADOW_BLADES = 121471,
    SUBTERFUGE = 115192,
    DARK_SHADOW = 245687,
    NIGHTSTALKER = 14062,
    MASTER_OF_SHADOWS = 196980,
    PREMEDITATION = 343173,
    SEPSIS = 385408,
    SHADOW_TECHNIQUES = 196911,
    
    -- Shared
    STEALTH = 1784,
    VANISH = 11327,
    FEINT = 1966,
    SHROUD_OF_CONCEALMENT = 114018,
    SPRINT = 2983,
    EVASION = 5277,
    CLOAK_OF_SHADOWS = 31224,
    TRICKS_OF_THE_TRADE = 57934
}

-- Important debuffs to track
local DEBUFFS = {
    -- Assassination
    RUPTURE = 1943,
    GARROTE = 703,
    CRIMSON_TEMPEST = 121411,
    INTERNAL_BLEEDING = 154953,
    VENDETTA = 79140,
    KINGSBANE = 385627,
    DEATHMARK = 360194,
    DEADLY_POISON = 2823,
    WOUND_POISON = 8679,
    NUMBING_POISON = 5761,
    SEPSIS = 385408,
    
    -- Outlaw
    BETWEEN_THE_EYES = 315341,
    GHOSTLY_STRIKE = 196937,
    SEPSIS = 385408,
    ECHOING_REPRIMAND = 385616,
    
    -- Subtlety
    RUPTURE = 1943,
    NIGHTBLADE = 195452,
    FIND_WEAKNESS = 91021,
    SHADOW_BLADES = 121471,
    CHEAP_SHOT = 1833,
    KIDNEY_SHOT = 408,
    SEPSIS = 385408,
    GOREMAWS_BITE = 426591
}

-- Initialize the Rogue module
function RogueModule:Initialize()
    -- Register settings
    self:RegisterSettings()
    
    -- Register events
    self:RegisterEvents()
    
    -- Register rotations
    self:RegisterRotations()
    
    API.PrintDebug("Rogue module initialized")
    return true
end

-- Register settings
function RogueModule:RegisterSettings()
    ConfigRegistry:RegisterSettings("Rogue", {
        generalSettings = {
            enabled = {
                displayName = "Enable Rogue Module",
                description = "Enable the Rogue module for all specs",
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
            useTricksOfTheTrade = {
                displayName = "Use Tricks of the Trade",
                description = "Automatically use Tricks of the Trade on tank",
                type = "toggle",
                default = true
            },
            tricksTarget = {
                displayName = "Tricks of the Trade Target",
                description = "Who to use Tricks of the Trade on",
                type = "dropdown",
                options = {"Tank", "Focus", "None"},
                default = "Tank"
            },
            useKidneyShot = {
                displayName = "Use Kidney Shot",
                description = "Automatically use Kidney Shot to stun enemies",
                type = "toggle",
                default = true
            },
            feintThreshold = {
                displayName = "Feint Health Threshold",
                description = "Health percentage to use Feint",
                type = "slider",
                min = 10,
                max = 80,
                step = 5,
                default = 60
            },
            crimsonVialThreshold = {
                displayName = "Crimson Vial Health Threshold",
                description = "Health percentage to use Crimson Vial",
                type = "slider",
                min = 10,
                max = 80,
                step = 5,
                default = 65
            },
            evasionThreshold = {
                displayName = "Evasion Health Threshold",
                description = "Health percentage to use Evasion",
                type = "slider",
                min = 5,
                max = 60,
                step = 5,
                default = 35
            },
            cloakThreshold = {
                displayName = "Cloak of Shadows Health Threshold",
                description = "Health percentage to use Cloak of Shadows if magic damage is present",
                type = "slider",
                min = 5,
                max = 60,
                step = 5,
                default = 30
            },
            vanishMode = {
                displayName = "Vanish Usage",
                description = "How to use Vanish in combat",
                type = "dropdown",
                options = {"Offensive Only", "Defensive Only", "Both", "Manual Only"},
                default = "Both"
            }
        },
        assassinationSettings = {
            -- Core settings
            useVendetta = {
                displayName = "Use Vendetta",
                description = "Use Vendetta on cooldown",
                type = "toggle",
                default = true
            },
            useKingsbane = {
                displayName = "Use Kingsbane",
                description = "Use Kingsbane on cooldown if talented",
                type = "toggle",
                default = true
            },
            useDeathmark = {
                displayName = "Use Deathmark",
                description = "Use Deathmark on cooldown if talented",
                type = "toggle",
                default = true
            },
            useExsanguinate = {
                displayName = "Use Exsanguinate",
                description = "Use Exsanguinate when DoTs are up if talented",
                type = "toggle",
                default = true
            },
            ruptureUptime = {
                displayName = "Rupture Uptime",
                description = "Maintain Rupture on targets",
                type = "toggle",
                default = true
            },
            garroteUptime = {
                displayName = "Garrote Uptime",
                description = "Maintain Garrote on targets",
                type = "toggle",
                default = true
            },
            useCrimsonTempest = {
                displayName = "Use Crimson Tempest",
                description = "Use Crimson Tempest for AoE bleeds if talented",
                type = "toggle",
                default = true
            },
            poolEnergyThreshold = {
                displayName = "Energy Pooling Threshold",
                description = "Energy to pool before using finishers",
                type = "slider",
                min = 0,
                max = 50,
                step = 5,
                default = 25
            },
            envenomComboPoints = {
                displayName = "Envenom Combo Points",
                description = "Minimum combo points to use Envenom",
                type = "slider",
                min = 4,
                max = 8,
                step = 1,
                default = 4
            },
            ruptureComboPoints = {
                displayName = "Rupture Combo Points",
                description = "Minimum combo points to use Rupture",
                type = "slider",
                min = 4,
                max = 8,
                step = 1,
                default = 5
            },
            crimsonTempestComboPoints = {
                displayName = "Crimson Tempest Combo Points",
                description = "Minimum combo points to use Crimson Tempest",
                type = "slider",
                min = 4,
                max = 8,
                step = 1,
                default = 5
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
            useSepsis = {
                displayName = "Use Sepsis",
                description = "Use Sepsis on cooldown if talented",
                type = "toggle",
                default = true
            },
            poisonType = {
                displayName = "Poison Selection",
                description = "Which poison to apply to weapons",
                type = "dropdown",
                options = {"Deadly + Wound", "Deadly + Numbing", "Amplifying + Wound"},
                default = "Deadly + Wound"
            },
            
            -- Season 2 ability settings
            useLethalPoison = {
                displayName = "Use Lethal Poison (TWW S2)",
                description = "Use Lethal Poison for increased poison damage",
                type = "toggle",
                default = true
            },
            useImprovedGarrote = {
                displayName = "Use Improved Garrote (TWW S2)",
                description = "Use Improved Garrote for increased Garrote damage",
                type = "toggle",
                default = true
            },
            useImprovedRupture = {
                displayName = "Use Improved Rupture (TWW S2)",
                description = "Use Improved Rupture for increased Rupture damage",
                type = "toggle",
                default = true
            },
            useTinyToxicBlade = {
                displayName = "Use Tiny Toxic Blade (TWW S2)",
                description = "Use Tiny Toxic Blade for enhanced poison application",
                type = "toggle",
                default = true
            },
            useFatalMixology = {
                displayName = "Use Fatal Mixology (TWW S2)",
                description = "Use Fatal Mixology for poison burst damage",
                type = "toggle",
                default = true
            },
            useArterialPrecision = {
                displayName = "Use Arterial Precision (TWW S2)",
                description = "Use Arterial Precision for increased bleed damage",
                type = "toggle",
                default = true
            },
            useScorpidVenom = {
                displayName = "Use Scorpid Venom (TWW S2)",
                description = "Use Scorpid Venom poison",
                type = "toggle",
                default = true
            },
            useCausticFilaments = {
                displayName = "Use Caustic Filaments (TWW S2)",
                description = "Use Caustic Filaments for DoT spreading",
                type = "toggle",
                default = true
            },
            useFlyingDaggers = {
                displayName = "Use Flying Daggers (TWW S2)",
                description = "Use Flying Daggers for enhanced Fan of Knives",
                type = "toggle",
                default = true
            },
            useSerratedBoneSpike = {
                displayName = "Use Serrated Bone Spike (TWW S2)",
                description = "Use Serrated Bone Spike for combo point generation",
                type = "toggle",
                default = true
            },
            useDeadlyBrew = {
                displayName = "Use Deadly Brew (TWW S2)",
                description = "Use Deadly Brew for additional poison application",
                type = "toggle",
                default = true
            },
            venomRushMode = {
                displayName = "Venom Rush Mode (TWW S2)",
                description = "How to optimize Venom Rush talent",
                type = "dropdown",
                options = {
                    "Maximize Envenom", 
                    "Balance DoTs and Envenom", 
                    "Envenom at 4+ CP Only", 
                    "Manual Only"
                },
                default = "Balance DoTs and Envenom"
            },
            doombladeStrategy = {
                displayName = "Doomblade Usage (TWW S2)",
                description = "When to use Doomblade for maximum effect",
                type = "dropdown",
                options = {
                    "With Vendetta", 
                    "With Full DoTs", 
                    "On Cooldown", 
                    "Manual Only"
                },
                default = "With Full DoTs"
            }
        },
        outlawSettings = {
            useAdrenalineRush = {
                displayName = "Use Adrenaline Rush",
                description = "Use Adrenaline Rush on cooldown",
                type = "toggle",
                default = true
            },
            rollTheBonesBuffCount = {
                displayName = "Roll the Bones Buff Count",
                description = "Minimum number of RtB buffs before rerolling",
                type = "slider",
                min = 1,
                max = 6,
                step = 1,
                default = 2
            },
            rollTheBonesRerollList = {
                displayName = "Roll the Bones Reroll List",
                description = "RtB buffs to keep and not reroll",
                type = "dropdown",
                options = {"Any 2+", "True Bearing", "Buried Treasure + Any", "Ruthless + Grand Melee"},
                default = "Any 2+"
            },
            useKillingSpree = {
                displayName = "Use Killing Spree",
                description = "Use Killing Spree on cooldown if talented",
                type = "toggle",
                default = true
            },
            useBladeRush = {
                displayName = "Use Blade Rush",
                description = "Use Blade Rush on cooldown if talented",
                type = "toggle",
                default = true
            },
            useGhostlyStrike = {
                displayName = "Use Ghostly Strike",
                description = "Use Ghostly Strike on cooldown if talented",
                type = "toggle",
                default = true
            },
            useBetweenTheEyes = {
                displayName = "Use Between the Eyes",
                description = "Use Between the Eyes as finisher",
                type = "toggle",
                default = true
            },
            usePistolShot = {
                displayName = "Use Pistol Shot",
                description = "Use Pistol Shot with Opportunity procs",
                type = "toggle",
                default = true
            },
            sliceAndDiceUptime = {
                displayName = "Slice and Dice Uptime",
                description = "Maintain Slice and Dice uptime",
                type = "toggle",
                default = true
            },
            bladeFlurryUsage = {
                displayName = "Blade Flurry Usage",
                description = "When to use Blade Flurry",
                type = "dropdown",
                options = {"Always in AoE", "With Cooldowns", "Manual Only"},
                default = "Always in AoE"
            },
            finisherComboPoints = {
                displayName = "Finisher Combo Points",
                description = "Minimum combo points to use finishers",
                type = "slider",
                min = 4,
                max = 8,
                step = 1,
                default = 5
            },
            aoeThreshold = {
                displayName = "AoE Threshold",
                description = "Number of targets to switch to AoE rotation",
                type = "slider",
                min = 2,
                max = 6,
                step = 1,
                default = 2
            },
            useSepsis = {
                displayName = "Use Sepsis",
                description = "Use Sepsis on cooldown if talented",
                type = "toggle",
                default = true
            },
            useEchoingReprimand = {
                displayName = "Use Echoing Reprimand",
                description = "Use Echoing Reprimand on cooldown if talented",
                type = "toggle",
                default = true
            }
        },
        subtletySettings = {
            useShadowDance = {
                displayName = "Use Shadow Dance",
                description = "Use Shadow Dance on cooldown",
                type = "toggle",
                default = true
            },
            useSymbolsOfDeath = {
                displayName = "Use Symbols of Death",
                description = "Use Symbols of Death on cooldown",
                type = "toggle",
                default = true
            },
            useShadowBlades = {
                displayName = "Use Shadow Blades",
                description = "Use Shadow Blades on cooldown if talented",
                type = "toggle",
                default = true
            },
            useSecretTechnique = {
                displayName = "Use Secret Technique",
                description = "Use Secret Technique on cooldown if talented",
                type = "toggle",
                default = true
            },
            ruptureUptime = {
                displayName = "Rupture Uptime",
                description = "Maintain Rupture on targets",
                type = "toggle",
                default = true
            },
            useBlackPowder = {
                displayName = "Use Black Powder",
                description = "Use Black Powder for AoE",
                type = "toggle",
                default = true
            },
            sliceAndDiceUptime = {
                displayName = "Slice and Dice Uptime",
                description = "Maintain Slice and Dice uptime",
                type = "toggle",
                default = true
            },
            finisherComboPoints = {
                displayName = "Finisher Combo Points",
                description = "Minimum combo points to use finishers",
                type = "slider",
                min = 4,
                max = 8,
                step = 1,
                default = 5
            },
            ruptureComboPoints = {
                displayName = "Rupture Combo Points",
                description = "Minimum combo points to use Rupture",
                type = "slider",
                min = 4,
                max = 8,
                step = 1,
                default = 5
            },
            aoeThreshold = {
                displayName = "AoE Threshold",
                description = "Number of targets to switch to AoE rotation",
                type = "slider",
                min = 2,
                max = 6,
                step = 1,
                default = 2
            },
            useSepsis = {
                displayName = "Use Sepsis",
                description = "Use Sepsis on cooldown if talented",
                type = "toggle",
                default = true
            },
            shadowDancePooling = {
                displayName = "Shadow Dance Energy Pooling",
                description = "Energy to pool before using Shadow Dance",
                type = "slider",
                min = 0,
                max = 80,
                step = 5,
                default = 50
            },
            goremawsBite = {
                displayName = "Use Goremaw's Bite",
                description = "Use Goremaw's Bite on cooldown if talented",
                type = "toggle",
                default = true
            }
        }
    })
    
    -- Add callback for settings changes
    ConfigRegistry:RegisterCallback("Rogue", function(settings)
        self:ApplySettings(settings)
    end)
end

-- Apply settings
function RogueModule:ApplySettings(settings)
    -- Apply general settings
    isEnabled = settings.generalSettings.enabled
end

-- Register events
function RogueModule:RegisterEvents()
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
function RogueModule:OnSpecializationChanged()
    -- Get current spec ID
    playerSpec = API.GetActiveSpecID()
    
    API.PrintDebug("Rogue specialization changed: " .. playerSpec)
    
    -- Ensure correct rotation is registered
    if playerSpec == SPEC_ASSASSINATION then
        self:RegisterAssassinationRotation()
    elseif playerSpec == SPEC_OUTLAW then
        self:RegisterOutlawRotation()
    elseif playerSpec == SPEC_SUBTLETY then
        self:RegisterSubtletyRotation()
    end
end

-- Register rotations
function RogueModule:RegisterRotations()
    -- Register spec-specific rotations
    self:RegisterAssassinationRotation()
    self:RegisterOutlawRotation()
    self:RegisterSubtletyRotation()
end

-- Register Assassination rotation
function RogueModule:RegisterAssassinationRotation()
    RotationManager:RegisterRotation("RogueAssassination", {
        id = "RogueAssassination",
        name = "Rogue - Assassination",
        class = "ROGUE",
        spec = SPEC_ASSASSINATION,
        level = 10,
        description = "Assassination Rogue rotation for The War Within Season 2",
        author = "WindrunnerRotations",
        version = "1.0.0",
        rotation = function()
            return self:AssassinationRotation()
        end
    })
end

-- Register Outlaw rotation
function RogueModule:RegisterOutlawRotation()
    RotationManager:RegisterRotation("RogueOutlaw", {
        id = "RogueOutlaw",
        name = "Rogue - Outlaw",
        class = "ROGUE",
        spec = SPEC_OUTLAW,
        level = 10,
        description = "Outlaw Rogue rotation for The War Within Season 2",
        author = "WindrunnerRotations",
        version = "1.0.0",
        rotation = function()
            return self:OutlawRotation()
        end
    })
end

-- Register Subtlety rotation
function RogueModule:RegisterSubtletyRotation()
    RotationManager:RegisterRotation("RogueSubtlety", {
        id = "RogueSubtlety",
        name = "Rogue - Subtlety",
        class = "ROGUE",
        spec = SPEC_SUBTLETY,
        level = 10,
        description = "Subtlety Rogue rotation for The War Within Season 2",
        author = "WindrunnerRotations",
        version = "1.0.0",
        rotation = function()
            return self:SubtletyRotation()
        end
    })
end

-- Assassination rotation
function RogueModule:AssassinationRotation()
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
    local settings = ConfigRegistry:GetSettings("Rogue")
    
    -- Common Combat Variables
    local health, maxHealth, healthPercent = API.GetUnitHealth(player)
    local targetHealth, targetMaxHealth, targetHealthPercent = API.GetUnitHealth(target)
    local energy = API.GetUnitPower(player, Enum.PowerType.Energy)
    local comboPoints = API.GetUnitPower(player, Enum.PowerType.ComboPoints)
    local enemies = API.GetEnemyCount(10)
    local aoeEnabled = settings.assassinationSettings.aoeThreshold <= enemies
    
    -- Check if we're stealthed
    local stealthed = API.UnitHasBuff(player, BUFFS.STEALTH) or 
                       API.UnitHasBuff(player, BUFFS.VANISH) or 
                       API.UnitHasBuff(player, BUFFS.SUBTERFUGE)
    
    -- Buff tracking
    local hasElaboratePlanning = API.UnitHasBuff(player, BUFFS.ELABORATE_PLANNING)
    local hasVendetta = API.UnitHasBuff(player, BUFFS.VENDETTA)
    local hasKingsbane = API.UnitHasBuff(player, BUFFS.KINGSBANE)
    local hasDeathmark = API.UnitHasBuff(player, BUFFS.DEATHMARK)
    local hasMasterAssassin = API.UnitHasBuff(player, BUFFS.MASTER_ASSASSIN)
    
    -- Debuff tracking on target
    local ruptureRemaining = API.GetDebuffRemaining(target, DEBUFFS.RUPTURE)
    local garroteRemaining = API.GetDebuffRemaining(target, DEBUFFS.GARROTE)
    local crimsonTempestRemaining = API.GetDebuffRemaining(target, DEBUFFS.CRIMSON_TEMPEST)
    local hasDeadlyPoison = API.UnitHasDebuff(target, DEBUFFS.DEADLY_POISON)
    local hasWoundPoison = API.UnitHasDebuff(target, DEBUFFS.WOUND_POISON)
    local hasNumbingPoison = API.UnitHasDebuff(target, DEBUFFS.NUMBING_POISON)
    local vendettaRemaining = API.GetDebuffRemaining(target, DEBUFFS.VENDETTA)
    local kingsbaneRemaining = API.GetDebuffRemaining(target, DEBUFFS.KINGSBANE)
    local deathmarkRemaining = API.GetDebuffRemaining(target, DEBUFFS.DEATHMARK)
    
    -- Interrupt if needed
    if settings.generalSettings.useInterrupts and
       API.IsSpellKnown(ASSASSINATION_SPELLS.KICK) and 
       API.IsSpellUsable(ASSASSINATION_SPELLS.KICK) and
       API.ShouldInterrupt(target) then
        return {
            type = "spell",
            id = ASSASSINATION_SPELLS.KICK,
            target = target
        }
    end
    
    -- Defensive abilities
    if settings.generalSettings.useDefensives then
        -- Use Feint
        if healthPercent < settings.generalSettings.feintThreshold and
           API.IsSpellKnown(ASSASSINATION_SPELLS.FEINT) and 
           API.IsSpellUsable(ASSASSINATION_SPELLS.FEINT) then
            return {
                type = "spell",
                id = ASSASSINATION_SPELLS.FEINT,
                target = player
            }
        end
        
        -- Use Crimson Vial
        if healthPercent < settings.generalSettings.crimsonVialThreshold and
           API.IsSpellKnown(ASSASSINATION_SPELLS.CRIMSON_VIAL) and 
           API.IsSpellUsable(ASSASSINATION_SPELLS.CRIMSON_VIAL) then
            return {
                type = "spell",
                id = ASSASSINATION_SPELLS.CRIMSON_VIAL,
                target = player
            }
        end
        
        -- Use Evasion
        if healthPercent < settings.generalSettings.evasionThreshold and
           API.IsSpellKnown(ASSASSINATION_SPELLS.EVASION) and 
           API.IsSpellUsable(ASSASSINATION_SPELLS.EVASION) then
            return {
                type = "spell",
                id = ASSASSINATION_SPELLS.EVASION,
                target = player
            }
        end
        
        -- Use Cloak of Shadows
        if healthPercent < settings.generalSettings.cloakThreshold and
           API.IsTakingMagicDamage(player) and
           API.IsSpellKnown(ASSASSINATION_SPELLS.CLOAK_OF_SHADOWS) and 
           API.IsSpellUsable(ASSASSINATION_SPELLS.CLOAK_OF_SHADOWS) then
            return {
                type = "spell",
                id = ASSASSINATION_SPELLS.CLOAK_OF_SHADOWS,
                target = player
            }
        end
        
        -- Use Vanish defensively
        if healthPercent < 20 and
           (settings.generalSettings.vanishMode == "Defensive Only" or settings.generalSettings.vanishMode == "Both") and
           API.IsSpellKnown(ASSASSINATION_SPELLS.VANISH) and 
           API.IsSpellUsable(ASSASSINATION_SPELLS.VANISH) then
            return {
                type = "spell",
                id = ASSASSINATION_SPELLS.VANISH,
                target = player
            }
        end
    end
    
    -- CC / Stun if needed
    if settings.generalSettings.useKidneyShot and
       comboPoints >= 5 and
       API.ShouldStun(target) and
       API.IsSpellKnown(ASSASSINATION_SPELLS.KIDNEY_SHOT) and 
       API.IsSpellUsable(ASSASSINATION_SPELLS.KIDNEY_SHOT) then
        return {
            type = "spell",
            id = ASSASSINATION_SPELLS.KIDNEY_SHOT,
            target = target
        }
    end
    
    -- Use Tricks of the Trade on tank
    if settings.generalSettings.useTricksOfTheTrade and
       not API.UnitHasBuff(player, BUFFS.TRICKS_OF_THE_TRADE) and
       API.IsSpellKnown(ASSASSINATION_SPELLS.TRICKS_OF_THE_TRADE) and 
       API.IsSpellUsable(ASSASSINATION_SPELLS.TRICKS_OF_THE_TRADE) then
        local tricksTarget = self:GetTricksTarget(settings.generalSettings.tricksTarget)
        if tricksTarget then
            return {
                type = "spell",
                id = ASSASSINATION_SPELLS.TRICKS_OF_THE_TRADE,
                target = tricksTarget
            }
        end
    end
    
    -- Stealth specific abilities
    if stealthed then
        if API.IsSpellKnown(ASSASSINATION_SPELLS.GARROTE) and 
           API.IsSpellUsable(ASSASSINATION_SPELLS.GARROTE) and
           (garroteRemaining < 4 or not settings.assassinationSettings.garroteUptime) then
            return {
                type = "spell",
                id = ASSASSINATION_SPELLS.GARROTE,
                target = target
            }
        end
        
        if API.IsSpellKnown(ASSASSINATION_SPELLS.CHEAP_SHOT) and 
           API.IsSpellUsable(ASSASSINATION_SPELLS.CHEAP_SHOT) then
            return {
                type = "spell",
                id = ASSASSINATION_SPELLS.CHEAP_SHOT,
                target = target
            }
        end
    end
    
    -- Offensive cooldowns
    if inCombat and targetHealth > 0 then
        -- Use Vendetta
        if settings.assassinationSettings.useVendetta and
           API.IsSpellKnown(ASSASSINATION_SPELLS.VENDETTA) and 
           API.IsSpellUsable(ASSASSINATION_SPELLS.VENDETTA) then
            return {
                type = "spell",
                id = ASSASSINATION_SPELLS.VENDETTA,
                target = target
            }
        end
        
        -- Use Kingsbane
        if settings.assassinationSettings.useKingsbane and
           API.IsSpellKnown(ASSASSINATION_SPELLS.KINGSBANE) and 
           API.IsSpellUsable(ASSASSINATION_SPELLS.KINGSBANE) and
           (hasVendetta or not settings.assassinationSettings.useVendetta) then
            return {
                type = "spell",
                id = ASSASSINATION_SPELLS.KINGSBANE,
                target = target
            }
        end
        
        -- Use Deathmark
        if settings.assassinationSettings.useDeathmark and
           API.IsSpellKnown(ASSASSINATION_SPELLS.DEATHMARK) and 
           API.IsSpellUsable(ASSASSINATION_SPELLS.DEATHMARK) and
           (hasVendetta or not settings.assassinationSettings.useVendetta) then
            return {
                type = "spell",
                id = ASSASSINATION_SPELLS.DEATHMARK,
                target = target
            }
        end
        
        -- Use Exsanguinate (with DoTs)
        if settings.assassinationSettings.useExsanguinate and
           API.IsSpellKnown(ASSASSINATION_SPELLS.EXSANGUINATE) and 
           API.IsSpellUsable(ASSASSINATION_SPELLS.EXSANGUINATE) and
           ruptureRemaining > 12 and garroteRemaining > 8 then
            return {
                type = "spell",
                id = ASSASSINATION_SPELLS.EXSANGUINATE,
                target = target
            }
        end
        
        -- Use Sepsis
        if settings.assassinationSettings.useSepsis and
           API.IsSpellKnown(ASSASSINATION_SPELLS.SEPSIS) and 
           API.IsSpellUsable(ASSASSINATION_SPELLS.SEPSIS) and
           (hasVendetta or not settings.assassinationSettings.useVendetta) then
            return {
                type = "spell",
                id = ASSASSINATION_SPELLS.SEPSIS,
                target = target
            }
        end
        
        -- Use Vanish offensively
        if (settings.generalSettings.vanishMode == "Offensive Only" or settings.generalSettings.vanishMode == "Both") and
           API.IsSpellKnown(ASSASSINATION_SPELLS.VANISH) and 
           API.IsSpellUsable(ASSASSINATION_SPELLS.VANISH) and
           energy > 60 and
           (hasVendetta or hasDeathmark or hasKingsbane) then
            return {
                type = "spell",
                id = ASSASSINATION_SPELLS.VANISH,
                target = player
            }
        end
        
        -- Use Shiv
        if API.IsSpellKnown(ASSASSINATION_SPELLS.SHIV) and 
           API.IsSpellUsable(ASSASSINATION_SPELLS.SHIV) and
           hasDeadlyPoison and
           (hasVendetta or hasDeathmark or hasKingsbane) then
            return {
                type = "spell",
                id = ASSASSINATION_SPELLS.SHIV,
                target = target
            }
        end
    end
    
    -- Maintain DoTs
    -- Rupture (priority)
    if settings.assassinationSettings.ruptureUptime and
       comboPoints >= settings.assassinationSettings.ruptureComboPoints and
       ruptureRemaining < 4 and
       API.IsSpellKnown(ASSASSINATION_SPELLS.RUPTURE) and 
       API.IsSpellUsable(ASSASSINATION_SPELLS.RUPTURE) then
        return {
            type = "spell",
            id = ASSASSINATION_SPELLS.RUPTURE,
            target = target
        }
    end
    
    -- Garrote (if not stealthed)
    if settings.assassinationSettings.garroteUptime and
       not stealthed and
       garroteRemaining < 2 and
       API.IsSpellKnown(ASSASSINATION_SPELLS.GARROTE) and 
       API.IsSpellUsable(ASSASSINATION_SPELLS.GARROTE) then
        return {
            type = "spell",
            id = ASSASSINATION_SPELLS.GARROTE,
            target = target
        }
    end
    
    -- Crimson Tempest for AoE
    if settings.assassinationSettings.useCrimsonTempest and
       aoeEnabled and
       comboPoints >= settings.assassinationSettings.crimsonTempestComboPoints and
       crimsonTempestRemaining < 2 and
       API.IsSpellKnown(ASSASSINATION_SPELLS.CRIMSON_TEMPEST) and 
       API.IsSpellUsable(ASSASSINATION_SPELLS.CRIMSON_TEMPEST) then
        return {
            type = "spell",
            id = ASSASSINATION_SPELLS.CRIMSON_TEMPEST,
            target = player
        }
    end
    
    -- Envenom (with sufficient combo points)
    if comboPoints >= settings.assassinationSettings.envenomComboPoints and
       energy >= settings.assassinationSettings.poolEnergyThreshold and
       API.IsSpellKnown(ASSASSINATION_SPELLS.ENVENOM) and 
       API.IsSpellUsable(ASSASSINATION_SPELLS.ENVENOM) then
        return {
            type = "spell",
            id = ASSASSINATION_SPELLS.ENVENOM,
            target = target
        }
    end
    
    -- AoE attack
    if aoeEnabled and
       API.IsSpellKnown(ASSASSINATION_SPELLS.FAN_OF_KNIVES) and 
       API.IsSpellUsable(ASSASSINATION_SPELLS.FAN_OF_KNIVES) then
        return {
            type = "spell",
            id = ASSASSINATION_SPELLS.FAN_OF_KNIVES,
            target = player
        }
    end
    
    -- Single target attack
    if not aoeEnabled and
       API.IsSpellKnown(ASSASSINATION_SPELLS.MUTILATE) and 
       API.IsSpellUsable(ASSASSINATION_SPELLS.MUTILATE) then
        return {
            type = "spell",
            id = ASSASSINATION_SPELLS.MUTILATE,
            target = target
        }
    end
    
    return nil
end

-- Outlaw rotation
function RogueModule:OutlawRotation()
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
    local settings = ConfigRegistry:GetSettings("Rogue")
    
    -- Common Combat Variables
    local health, maxHealth, healthPercent = API.GetUnitHealth(player)
    local targetHealth, targetMaxHealth, targetHealthPercent = API.GetUnitHealth(target)
    local energy = API.GetUnitPower(player, Enum.PowerType.Energy)
    local comboPoints = API.GetUnitPower(player, Enum.PowerType.ComboPoints)
    local enemies = API.GetEnemyCount(10)
    local aoeEnabled = settings.outlawSettings.aoeThreshold <= enemies
    
    -- Check if we're stealthed
    local stealthed = API.UnitHasBuff(player, BUFFS.STEALTH) or 
                       API.UnitHasBuff(player, BUFFS.VANISH) or 
                       API.UnitHasBuff(player, BUFFS.SUBTERFUGE)
    
    -- Buff tracking
    local hasAdrenalineRush = API.UnitHasBuff(player, BUFFS.ADRENALINE_RUSH)
    local hasOpportunity = API.UnitHasBuff(player, BUFFS.OPPORTUNITY)
    local hasBladeFlurry = API.UnitHasBuff(player, BUFFS.BLADE_FLURRY)
    local hasDreadblades = API.UnitHasBuff(player, BUFFS.DREADBLADES)
    local hasAlacrity = API.UnitHasBuff(player, BUFFS.ALACRITY)
    local alacStacks = API.GetBuffStacks(player, BUFFS.ALACRITY)
    
    -- Roll the Bones buffs
    local rtbBuffCount = self:GetRollTheBonesBuffCount(player)
    local sliceAndDiceRemaining = API.GetBuffRemaining(player, BUFFS.SLICE_AND_DICE)
    local hasTrueBearing = API.UnitHasBuff(player, BUFFS.TRUE_BEARING)
    local hasBuriedTreasure = API.UnitHasBuff(player, BUFFS.BURIED_TREASURE)
    local hasRuthlessPrecision = API.UnitHasBuff(player, BUFFS.RUTHLESS_PRECISION)
    local hasGrandMelee = API.UnitHasBuff(player, BUFFS.GRAND_MELEE)
    local hasSkullAndCrossbones = API.UnitHasBuff(player, BUFFS.SKULL_AND_CROSSBONES)
    local hasBroadside = API.UnitHasBuff(player, BUFFS.BROADSIDE)
    
    -- Debuff tracking
    local betweenTheEyesRemaining = API.GetDebuffRemaining(target, DEBUFFS.BETWEEN_THE_EYES)
    local ghostlyStrikeRemaining = API.GetDebuffRemaining(target, DEBUFFS.GHOSTLY_STRIKE)
    
    -- Interrupt if needed
    if settings.generalSettings.useInterrupts and
       API.IsSpellKnown(OUTLAW_SPELLS.KICK) and 
       API.IsSpellUsable(OUTLAW_SPELLS.KICK) and
       API.ShouldInterrupt(target) then
        return {
            type = "spell",
            id = OUTLAW_SPELLS.KICK,
            target = target
        }
    end
    
    -- Defensive abilities
    if settings.generalSettings.useDefensives then
        -- Use Feint
        if healthPercent < settings.generalSettings.feintThreshold and
           API.IsSpellKnown(OUTLAW_SPELLS.FEINT) and 
           API.IsSpellUsable(OUTLAW_SPELLS.FEINT) then
            return {
                type = "spell",
                id = OUTLAW_SPELLS.FEINT,
                target = player
            }
        end
        
        -- Use Crimson Vial
        if healthPercent < settings.generalSettings.crimsonVialThreshold and
           API.IsSpellKnown(OUTLAW_SPELLS.CRIMSON_VIAL) and 
           API.IsSpellUsable(OUTLAW_SPELLS.CRIMSON_VIAL) then
            return {
                type = "spell",
                id = OUTLAW_SPELLS.CRIMSON_VIAL,
                target = player
            }
        end
        
        -- Use Evasion
        if healthPercent < settings.generalSettings.evasionThreshold and
           API.IsSpellKnown(OUTLAW_SPELLS.EVASION) and 
           API.IsSpellUsable(OUTLAW_SPELLS.EVASION) then
            return {
                type = "spell",
                id = OUTLAW_SPELLS.EVASION,
                target = player
            }
        end
        
        -- Use Cloak of Shadows
        if healthPercent < settings.generalSettings.cloakThreshold and
           API.IsTakingMagicDamage(player) and
           API.IsSpellKnown(OUTLAW_SPELLS.CLOAK_OF_SHADOWS) and 
           API.IsSpellUsable(OUTLAW_SPELLS.CLOAK_OF_SHADOWS) then
            return {
                type = "spell",
                id = OUTLAW_SPELLS.CLOAK_OF_SHADOWS,
                target = player
            }
        end
        
        -- Use Vanish defensively
        if healthPercent < 20 and
           (settings.generalSettings.vanishMode == "Defensive Only" or settings.generalSettings.vanishMode == "Both") and
           API.IsSpellKnown(OUTLAW_SPELLS.VANISH) and 
           API.IsSpellUsable(OUTLAW_SPELLS.VANISH) then
            return {
                type = "spell",
                id = OUTLAW_SPELLS.VANISH,
                target = player
            }
        end
    end
    
    -- CC / Stun if needed
    if settings.generalSettings.useKidneyShot and
       comboPoints >= 5 and
       API.ShouldStun(target) and
       API.IsSpellKnown(OUTLAW_SPELLS.KIDNEY_SHOT) and 
       API.IsSpellUsable(OUTLAW_SPELLS.KIDNEY_SHOT) then
        return {
            type = "spell",
            id = OUTLAW_SPELLS.KIDNEY_SHOT,
            target = target
        }
    end
    
    -- Use Tricks of the Trade on tank
    if settings.generalSettings.useTricksOfTheTrade and
       not API.UnitHasBuff(player, BUFFS.TRICKS_OF_THE_TRADE) and
       API.IsSpellKnown(OUTLAW_SPELLS.TRICKS_OF_THE_TRADE) and 
       API.IsSpellUsable(OUTLAW_SPELLS.TRICKS_OF_THE_TRADE) then
        local tricksTarget = self:GetTricksTarget(settings.generalSettings.tricksTarget)
        if tricksTarget then
            return {
                type = "spell",
                id = OUTLAW_SPELLS.TRICKS_OF_THE_TRADE,
                target = tricksTarget
            }
        end
    end
    
    -- Stealth specific abilities
    if stealthed then
        if API.IsSpellKnown(OUTLAW_SPELLS.CHEAP_SHOT) and 
           API.IsSpellUsable(OUTLAW_SPELLS.CHEAP_SHOT) then
            return {
                type = "spell",
                id = OUTLAW_SPELLS.CHEAP_SHOT,
                target = target
            }
        end
    end
    
    -- Maintain Blade Flurry for AoE
    if aoeEnabled and 
       (settings.outlawSettings.bladeFlurryUsage == "Always in AoE" or 
        (settings.outlawSettings.bladeFlurryUsage == "With Cooldowns" and hasAdrenalineRush)) and
       not hasBladeFlurry and
       API.IsSpellKnown(OUTLAW_SPELLS.BLADE_FLURRY) and 
       API.IsSpellUsable(OUTLAW_SPELLS.BLADE_FLURRY) then
        return {
            type = "spell",
            id = OUTLAW_SPELLS.BLADE_FLURRY,
            target = player
        }
    end
    
    -- Maintain Slice and Dice
    if settings.outlawSettings.sliceAndDiceUptime and
       sliceAndDiceRemaining < 5 and
       comboPoints >= 1 and
       API.IsSpellKnown(OUTLAW_SPELLS.SLICE_AND_DICE) and 
       API.IsSpellUsable(OUTLAW_SPELLS.SLICE_AND_DICE) then
        return {
            type = "spell",
            id = OUTLAW_SPELLS.SLICE_AND_DICE,
            target = player
        }
    end
    
    -- Roll the Bones management
    local shouldReroll = self:ShouldRerollRollTheBones(rtbBuffCount, hasBuriedTreasure, hasTrueBearing, hasRuthlessPrecision, hasGrandMelee, settings.outlawSettings.rollTheBonesBuffCount, settings.outlawSettings.rollTheBonesRerollList)
    
    if sliceAndDiceRemaining > 5 and
       shouldReroll and
       comboPoints >= 1 and
       API.IsSpellKnown(OUTLAW_SPELLS.ROLL_THE_BONES) and 
       API.IsSpellUsable(OUTLAW_SPELLS.ROLL_THE_BONES) then
        return {
            type = "spell",
            id = OUTLAW_SPELLS.ROLL_THE_BONES,
            target = player
        }
    end
    
    -- Offensive cooldowns
    if inCombat and targetHealth > 0 then
        -- Use Adrenaline Rush
        if settings.outlawSettings.useAdrenalineRush and
           API.IsSpellKnown(OUTLAW_SPELLS.ADRENALINE_RUSH) and 
           API.IsSpellUsable(OUTLAW_SPELLS.ADRENALINE_RUSH) then
            return {
                type = "spell",
                id = OUTLAW_SPELLS.ADRENALINE_RUSH,
                target = player
            }
        end
        
        -- Use Killing Spree
        if settings.outlawSettings.useKillingSpree and
           energy < 30 and
           API.IsSpellKnown(OUTLAW_SPELLS.KILLING_SPREE) and 
           API.IsSpellUsable(OUTLAW_SPELLS.KILLING_SPREE) then
            return {
                type = "spell",
                id = OUTLAW_SPELLS.KILLING_SPREE,
                target = target
            }
        end
        
        -- Use Blade Rush
        if settings.outlawSettings.useBladeRush and
           API.IsSpellKnown(OUTLAW_SPELLS.BLADE_RUSH) and 
           API.IsSpellUsable(OUTLAW_SPELLS.BLADE_RUSH) then
            return {
                type = "spell",
                id = OUTLAW_SPELLS.BLADE_RUSH,
                target = target
            }
        end
        
        -- Use Ghostly Strike
        if settings.outlawSettings.useGhostlyStrike and
           ghostlyStrikeRemaining < 1 and
           API.IsSpellKnown(OUTLAW_SPELLS.GHOSTLY_STRIKE) and 
           API.IsSpellUsable(OUTLAW_SPELLS.GHOSTLY_STRIKE) then
            return {
                type = "spell",
                id = OUTLAW_SPELLS.GHOSTLY_STRIKE,
                target = target
            }
        end
        
        -- Use Sepsis
        if settings.outlawSettings.useSepsis and
           API.IsSpellKnown(OUTLAW_SPELLS.SEPSIS) and 
           API.IsSpellUsable(OUTLAW_SPELLS.SEPSIS) then
            return {
                type = "spell",
                id = OUTLAW_SPELLS.SEPSIS,
                target = target
            }
        end
        
        -- Use Echoing Reprimand
        if settings.outlawSettings.useEchoingReprimand and
           API.IsSpellKnown(OUTLAW_SPELLS.ECHOING_REPRIMAND) and 
           API.IsSpellUsable(OUTLAW_SPELLS.ECHOING_REPRIMAND) then
            return {
                type = "spell",
                id = OUTLAW_SPELLS.ECHOING_REPRIMAND,
                target = target
            }
        end
        
        -- Use Vanish offensively
        if (settings.generalSettings.vanishMode == "Offensive Only" or settings.generalSettings.vanishMode == "Both") and
           API.IsSpellKnown(OUTLAW_SPELLS.VANISH) and 
           API.IsSpellUsable(OUTLAW_SPELLS.VANISH) and
           energy > 60 and
           hasAdrenalineRush then
            return {
                type = "spell",
                id = OUTLAW_SPELLS.VANISH,
                target = player
            }
        end
    end
    
    -- Finishers (with sufficient combo points)
    if comboPoints >= settings.outlawSettings.finisherComboPoints then
        -- Between the Eyes
        if settings.outlawSettings.useBetweenTheEyes and
           betweenTheEyesRemaining < 2 and
           (hasRuthlessPrecision or rtbBuffCount < 2) and
           API.IsSpellKnown(OUTLAW_SPELLS.BETWEEN_THE_EYES) and 
           API.IsSpellUsable(OUTLAW_SPELLS.BETWEEN_THE_EYES) then
            return {
                type = "spell",
                id = OUTLAW_SPELLS.BETWEEN_THE_EYES,
                target = target
            }
        end
        
        -- Dispatch (if BtE is on cooldown or not using it)
        if API.IsSpellKnown(OUTLAW_SPELLS.DISPATCH) and 
           API.IsSpellUsable(OUTLAW_SPELLS.DISPATCH) then
            return {
                type = "spell",
                id = OUTLAW_SPELLS.DISPATCH,
                target = target
            }
        end
    end
    
    -- Pistol Shot with Opportunity proc
    if settings.outlawSettings.usePistolShot and
       hasOpportunity and
       API.IsSpellKnown(OUTLAW_SPELLS.PISTOL_SHOT) and 
       API.IsSpellUsable(OUTLAW_SPELLS.PISTOL_SHOT) then
        return {
            type = "spell",
            id = OUTLAW_SPELLS.PISTOL_SHOT,
            target = target
        }
    end
    
    -- Sinister Strike (main builder)
    if API.IsSpellKnown(OUTLAW_SPELLS.SINISTER_STRIKE) and 
       API.IsSpellUsable(OUTLAW_SPELLS.SINISTER_STRIKE) then
        return {
            type = "spell",
            id = OUTLAW_SPELLS.SINISTER_STRIKE,
            target = target
        }
    end
    
    return nil
end

-- Subtlety rotation
function RogueModule:SubtletyRotation()
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
    local settings = ConfigRegistry:GetSettings("Rogue")
    
    -- Common Combat Variables
    local health, maxHealth, healthPercent = API.GetUnitHealth(player)
    local targetHealth, targetMaxHealth, targetHealthPercent = API.GetUnitHealth(target)
    local energy = API.GetUnitPower(player, Enum.PowerType.Energy)
    local comboPoints = API.GetUnitPower(player, Enum.PowerType.ComboPoints)
    local enemies = API.GetEnemyCount(10)
    local aoeEnabled = settings.subtletySettings.aoeThreshold <= enemies
    
    -- Check if we're stealthed
    local stealthed = API.UnitHasBuff(player, BUFFS.STEALTH) or 
                       API.UnitHasBuff(player, BUFFS.VANISH) or 
                       API.UnitHasBuff(player, BUFFS.SUBTERFUGE) or
                       API.UnitHasBuff(player, BUFFS.SHADOW_DANCE)
    
    -- Buff tracking
    local hasShadowDance = API.UnitHasBuff(player, BUFFS.SHADOW_DANCE)
    local hasSymbolsOfDeath = API.UnitHasBuff(player, BUFFS.SYMBOLS_OF_DEATH)
    local hasShadowBlades = API.UnitHasBuff(player, BUFFS.SHADOW_BLADES)
    local hasSubterfuge = API.UnitHasBuff(player, BUFFS.SUBTERFUGE)
    local hasDarkShadow = API.UnitHasBuff(player, BUFFS.DARK_SHADOW)
    local hasNightstalker = API.UnitHasBuff(player, BUFFS.NIGHTSTALKER)
    local hasMasterOfShadows = API.UnitHasBuff(player, BUFFS.MASTER_OF_SHADOWS)
    local hasPremeditation = API.UnitHasBuff(player, BUFFS.PREMEDITATION)
    
    -- Debuff tracking
    local ruptureRemaining = API.GetDebuffRemaining(target, DEBUFFS.RUPTURE)
    local hasFindWeakness = API.UnitHasDebuff(target, DEBUFFS.FIND_WEAKNESS)
    
    -- Slice and Dice tracking
    local sliceAndDiceRemaining = API.GetBuffRemaining(player, BUFFS.SLICE_AND_DICE)
    
    -- Shadowdance charges
    local shadowDanceCharges, shadowDanceMaxCharges, shadowDanceCooldown = API.GetSpellCharges(SUBTLETY_SPELLS.SHADOW_DANCE)
    
    -- Interrupt if needed
    if settings.generalSettings.useInterrupts and
       API.IsSpellKnown(SUBTLETY_SPELLS.KICK) and 
       API.IsSpellUsable(SUBTLETY_SPELLS.KICK) and
       API.ShouldInterrupt(target) then
        return {
            type = "spell",
            id = SUBTLETY_SPELLS.KICK,
            target = target
        }
    end
    
    -- Defensive abilities
    if settings.generalSettings.useDefensives then
        -- Use Feint
        if healthPercent < settings.generalSettings.feintThreshold and
           API.IsSpellKnown(SUBTLETY_SPELLS.FEINT) and 
           API.IsSpellUsable(SUBTLETY_SPELLS.FEINT) then
            return {
                type = "spell",
                id = SUBTLETY_SPELLS.FEINT,
                target = player
            }
        end
        
        -- Use Crimson Vial
        if healthPercent < settings.generalSettings.crimsonVialThreshold and
           API.IsSpellKnown(SUBTLETY_SPELLS.CRIMSON_VIAL) and 
           API.IsSpellUsable(SUBTLETY_SPELLS.CRIMSON_VIAL) then
            return {
                type = "spell",
                id = SUBTLETY_SPELLS.CRIMSON_VIAL,
                target = player
            }
        end
        
        -- Use Evasion
        if healthPercent < settings.generalSettings.evasionThreshold and
           API.IsSpellKnown(SUBTLETY_SPELLS.EVASION) and 
           API.IsSpellUsable(SUBTLETY_SPELLS.EVASION) then
            return {
                type = "spell",
                id = SUBTLETY_SPELLS.EVASION,
                target = player
            }
        end
        
        -- Use Cloak of Shadows
        if healthPercent < settings.generalSettings.cloakThreshold and
           API.IsTakingMagicDamage(player) and
           API.IsSpellKnown(SUBTLETY_SPELLS.CLOAK_OF_SHADOWS) and 
           API.IsSpellUsable(SUBTLETY_SPELLS.CLOAK_OF_SHADOWS) then
            return {
                type = "spell",
                id = SUBTLETY_SPELLS.CLOAK_OF_SHADOWS,
                target = player
            }
        end
        
        -- Use Vanish defensively
        if healthPercent < 20 and
           (settings.generalSettings.vanishMode == "Defensive Only" or settings.generalSettings.vanishMode == "Both") and
           API.IsSpellKnown(SUBTLETY_SPELLS.VANISH) and 
           API.IsSpellUsable(SUBTLETY_SPELLS.VANISH) then
            return {
                type = "spell",
                id = SUBTLETY_SPELLS.VANISH,
                target = player
            }
        end
    end
    
    -- CC / Stun if needed
    if settings.generalSettings.useKidneyShot and
       comboPoints >= 5 and
       API.ShouldStun(target) and
       API.IsSpellKnown(SUBTLETY_SPELLS.KIDNEY_SHOT) and 
       API.IsSpellUsable(SUBTLETY_SPELLS.KIDNEY_SHOT) then
        return {
            type = "spell",
            id = SUBTLETY_SPELLS.KIDNEY_SHOT,
            target = target
        }
    end
    
    -- Use Tricks of the Trade on tank
    if settings.generalSettings.useTricksOfTheTrade and
       not API.UnitHasBuff(player, BUFFS.TRICKS_OF_THE_TRADE) and
       API.IsSpellKnown(SUBTLETY_SPELLS.TRICKS_OF_THE_TRADE) and 
       API.IsSpellUsable(SUBTLETY_SPELLS.TRICKS_OF_THE_TRADE) then
        local tricksTarget = self:GetTricksTarget(settings.generalSettings.tricksTarget)
        if tricksTarget then
            return {
                type = "spell",
                id = SUBTLETY_SPELLS.TRICKS_OF_THE_TRADE,
                target = tricksTarget
            }
        end
    end
    
    -- Maintain Slice and Dice
    if settings.subtletySettings.sliceAndDiceUptime and
       sliceAndDiceRemaining < 5 and
       comboPoints >= 1 and
       API.IsSpellKnown(SUBTLETY_SPELLS.SLICE_AND_DICE) and 
       API.IsSpellUsable(SUBTLETY_SPELLS.SLICE_AND_DICE) then
        return {
            type = "spell",
            id = SUBTLETY_SPELLS.SLICE_AND_DICE,
            target = player
        }
    end
    
    -- Offensive cooldowns
    if inCombat and targetHealth > 0 then
        -- Use Shadow Blades
        if settings.subtletySettings.useShadowBlades and
           API.IsSpellKnown(SUBTLETY_SPELLS.SHADOW_BLADES) and 
           API.IsSpellUsable(SUBTLETY_SPELLS.SHADOW_BLADES) then
            return {
                type = "spell",
                id = SUBTLETY_SPELLS.SHADOW_BLADES,
                target = player
            }
        end
        
        -- Use Symbols of Death
        if settings.subtletySettings.useSymbolsOfDeath and
           API.IsSpellKnown(SUBTLETY_SPELLS.SYMBOLS_OF_DEATH) and 
           API.IsSpellUsable(SUBTLETY_SPELLS.SYMBOLS_OF_DEATH) then
            return {
                type = "spell",
                id = SUBTLETY_SPELLS.SYMBOLS_OF_DEATH,
                target = player
            }
        end
        
        -- Use Shadow Dance
        if settings.subtletySettings.useShadowDance and
           not stealthed and
           energy >= settings.subtletySettings.shadowDancePooling and
           shadowDanceCharges > 0 and
           API.IsSpellKnown(SUBTLETY_SPELLS.SHADOW_DANCE) and 
           API.IsSpellUsable(SUBTLETY_SPELLS.SHADOW_DANCE) then
            return {
                type = "spell",
                id = SUBTLETY_SPELLS.SHADOW_DANCE,
                target = player
            }
        end
        
        -- Use Sepsis
        if settings.subtletySettings.useSepsis and
           API.IsSpellKnown(SUBTLETY_SPELLS.SEPSIS) and 
           API.IsSpellUsable(SUBTLETY_SPELLS.SEPSIS) then
            return {
                type = "spell",
                id = SUBTLETY_SPELLS.SEPSIS,
                target = target
            }
        end
        
        -- Use Goremaw's Bite
        if settings.subtletySettings.goremawsBite and
           API.IsSpellKnown(SUBTLETY_SPELLS.GOREMAWS_BITE) and 
           API.IsSpellUsable(SUBTLETY_SPELLS.GOREMAWS_BITE) then
            return {
                type = "spell",
                id = SUBTLETY_SPELLS.GOREMAWS_BITE,
                target = target
            }
        end
        
        -- Use Secret Technique
        if settings.subtletySettings.useSecretTechnique and
           comboPoints >= 4 and
           API.IsSpellKnown(SUBTLETY_SPELLS.SECRET_TECHNIQUE) and 
           API.IsSpellUsable(SUBTLETY_SPELLS.SECRET_TECHNIQUE) then
            return {
                type = "spell",
                id = SUBTLETY_SPELLS.SECRET_TECHNIQUE,
                target = target
            }
        end
        
        -- Use Vanish offensively
        if (settings.generalSettings.vanishMode == "Offensive Only" or settings.generalSettings.vanishMode == "Both") and
           API.IsSpellKnown(SUBTLETY_SPELLS.VANISH) and 
           API.IsSpellUsable(SUBTLETY_SPELLS.VANISH) and
           energy > 60 and
           hasSymbolsOfDeath then
            return {
                type = "spell",
                id = SUBTLETY_SPELLS.VANISH,
                target = player
            }
        end
    end
    
    -- Maintain Rupture
    if settings.subtletySettings.ruptureUptime and
       comboPoints >= settings.subtletySettings.ruptureComboPoints and
       ruptureRemaining < 4 and
       API.IsSpellKnown(SUBTLETY_SPELLS.RUPTURE) and 
       API.IsSpellUsable(SUBTLETY_SPELLS.RUPTURE) then
        return {
            type = "spell",
            id = SUBTLETY_SPELLS.RUPTURE,
            target = target
        }
    end
    
    -- Stealth specific abilities
    if stealthed then
        -- Cheap Shot (if needed)
        if not hasFindWeakness and
           API.IsSpellKnown(SUBTLETY_SPELLS.CHEAP_SHOT) and 
           API.IsSpellUsable(SUBTLETY_SPELLS.CHEAP_SHOT) then
            return {
                type = "spell",
                id = SUBTLETY_SPELLS.CHEAP_SHOT,
                target = target
            }
        end
        
        -- Shadowstrike
        if API.IsSpellKnown(SUBTLETY_SPELLS.SHADOWSTRIKE) and 
           API.IsSpellUsable(SUBTLETY_SPELLS.SHADOWSTRIKE) then
            return {
                type = "spell",
                id = SUBTLETY_SPELLS.SHADOWSTRIKE,
                target = target
            }
        end
    end
    
    -- Finishers (with sufficient combo points)
    if comboPoints >= settings.subtletySettings.finisherComboPoints then
        -- Black Powder for AoE
        if settings.subtletySettings.useBlackPowder and
           aoeEnabled and
           API.IsSpellKnown(SUBTLETY_SPELLS.BLACK_POWDER) and 
           API.IsSpellUsable(SUBTLETY_SPELLS.BLACK_POWDER) then
            return {
                type = "spell",
                id = SUBTLETY_SPELLS.BLACK_POWDER,
                target = player
            }
        end
        
        -- Eviscerate (single target)
        if API.IsSpellKnown(SUBTLETY_SPELLS.EVISCERATE) and 
           API.IsSpellUsable(SUBTLETY_SPELLS.EVISCERATE) then
            return {
                type = "spell",
                id = SUBTLETY_SPELLS.EVISCERATE,
                target = target
            }
        end
    end
    
    -- Shuriken Storm for AoE
    if aoeEnabled and
       API.IsSpellKnown(SUBTLETY_SPELLS.SHURIKEN_STORM) and 
       API.IsSpellUsable(SUBTLETY_SPELLS.SHURIKEN_STORM) then
        return {
            type = "spell",
            id = SUBTLETY_SPELLS.SHURIKEN_STORM,
            target = player
        }
    end
    
    -- Backstab (main builder)
    if not aoeEnabled and
       API.IsSpellKnown(SUBTLETY_SPELLS.BACKSTAB) and 
       API.IsSpellUsable(SUBTLETY_SPELLS.BACKSTAB) then
        return {
            type = "spell",
            id = SUBTLETY_SPELLS.BACKSTAB,
            target = target
        }
    end
    
    -- Shuriken Toss if out of melee range
    if not API.IsInMeleeRange(target) and
       API.IsSpellKnown(SUBTLETY_SPELLS.SHURIKEN_TOSS) and 
       API.IsSpellUsable(SUBTLETY_SPELLS.SHURIKEN_TOSS) then
        return {
            type = "spell",
            id = SUBTLETY_SPELLS.SHURIKEN_TOSS,
            target = target
        }
    end
    
    return nil
end

-- Get Tricks of the Trade target
function RogueModule:GetTricksTarget(targetType)
    if targetType == "Tank" then
        -- Try to find a tank in the party
        for i = 1, 4 do
            local unit = "party" .. i
            if UnitExists(unit) and not UnitIsDead(unit) and UnitGroupRolesAssigned(unit) == "TANK" then
                return unit
            end
        end
        -- No tank found, return nil
        return nil
    elseif targetType == "Focus" then
        -- Use focus target if it exists and is friendly
        if UnitExists("focus") and not UnitIsDead("focus") and UnitIsFriend("player", "focus") then
            return "focus"
        end
        return nil
    else
        -- None option
        return nil
    end
end

-- Get Roll the Bones buff count
function RogueModule:GetRollTheBonesBuffCount(unit)
    local count = 0
    
    if API.UnitHasBuff(unit, BUFFS.BROADSIDE) then count = count + 1 end
    if API.UnitHasBuff(unit, BUFFS.BURIED_TREASURE) then count = count + 1 end
    if API.UnitHasBuff(unit, BUFFS.GRAND_MELEE) then count = count + 1 end
    if API.UnitHasBuff(unit, BUFFS.SKULL_AND_CROSSBONES) then count = count + 1 end
    if API.UnitHasBuff(unit, BUFFS.RUTHLESS_PRECISION) then count = count + 1 end
    if API.UnitHasBuff(unit, BUFFS.TRUE_BEARING) then count = count + 1 end
    
    return count
end

-- Decide if we should reroll Roll the Bones
function RogueModule:ShouldRerollRollTheBones(buffCount, hasBuriedTreasure, hasTrueBearing, hasRuthlessPrecision, hasGrandMelee, minBuffs, strategy)
    -- Don't reroll if we have enough buffs
    if buffCount >= minBuffs then
        return false
    end
    
    -- Specific strategies
    if strategy == "True Bearing" and hasTrueBearing then
        return false
    elseif strategy == "Buried Treasure + Any" and hasBuriedTreasure and buffCount >= 1 then
        return false
    elseif strategy == "Ruthless + Grand Melee" and hasRuthlessPrecision and hasGrandMelee then
        return false
    end
    
    -- Default to reroll
    return true
end

-- Check if taking magic damage
function API.IsTakingMagicDamage(unit)
    -- In a real implementation, this would track actual magic damage intake
    -- For our mock implementation, we'll just return false
    return false
end

-- Check if we should stun the target
function API.ShouldStun(unit)
    -- In a real implementation, this would check if the target is casting something important
    -- For our mock implementation, we'll just return false
    return false
end

-- Check if in melee range
function API.IsInMeleeRange(unit)
    -- In a real implementation, this would check actual range
    -- For our mock implementation, we'll return true
    return true
end

-- Should execute rotation
function RogueModule:ShouldExecuteRotation()
    if not isEnabled then
        return false
    end
    
    -- Check if player matches class
    local playerInfo = API.GetPlayerInfo()
    if playerInfo.class ~= "ROGUE" then
        return false
    end
    
    return true
end

-- Register for export
WR.Rogue = RogueModule

return RogueModule