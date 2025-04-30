------------------------------------------
-- WindrunnerRotations - Paladin Class Module
-- Author: VortexQ8
-- The War Within Season 2
------------------------------------------

local addonName, WR = ...
local PaladinModule = {}
WR.Paladin = PaladinModule

-- Dependencies
local API = WR.API
local ConfigRegistry = WR.ConfigRegistry
local RotationManager = WR.RotationManager
local ErrorHandler = WR.ErrorHandler
local CombatAnalysis = WR.CombatAnalysis
local AntiDetectionSystem = WR.AntiDetectionSystem
local PvPManager = WR.PvPManager

-- Paladin constants
local CLASS_ID = 2 -- Paladin class ID
local SPEC_HOLY = 65
local SPEC_PROTECTION = 66
local SPEC_RETRIBUTION = 70

-- Current player data
local playerSpec = 0
local isEnabled = true
local inCombat = false

-- Spell IDs for Holy Paladin (The War Within, Season 2)
local HOLY_SPELLS = {
    -- Core abilities
    HOLY_SHOCK = 20473,
    WORD_OF_GLORY = 85673,
    LIGHT_OF_DAWN = 85222,
    HOLY_LIGHT = 82326,
    FLASH_OF_LIGHT = 19750,
    HOLY_PRISM = 114165,
    LIGHT_OF_THE_MARTYR = 183998,
    BESTOW_FAITH = 223306,
    DIVINE_TOLL = 375576, -- Added in Season 2
    BEACON_OF_LIGHT = 53563,
    BEACON_OF_FAITH = 156910,
    BEACON_OF_VIRTUE = 200025,
    HAMMER_OF_WRATH = 24275,
    BLESSING_OF_SUMMER = 388007, -- New in TWW Season 2 (part of Seasons cycle)
    BLESSING_OF_AUTUMN = 388007, -- New in TWW Season 2 (part of Seasons cycle)
    BLESSING_OF_WINTER = 388007, -- New in TWW Season 2 (part of Seasons cycle)
    BLESSING_OF_SPRING = 388007, -- New in TWW Season 2 (part of Seasons cycle)
    AFTERIMAGE = 388012, -- New in TWW Season 2
    DAYBREAK = 387986, -- New in TWW Season 2
    RESPLENDENT_LIGHT = 392903, -- New in TWW Season 2
    EMPYREAN_LEGACY = 387170, -- New in TWW Season 2
    
    -- Defensive & utility
    DIVINE_SHIELD = 642,
    BLESSING_OF_PROTECTION = 1022,
    BLESSING_OF_FREEDOM = 1044,
    BLESSING_OF_SACRIFICE = 6940,
    LAY_ON_HANDS = 633,
    DIVINE_PROTECTION = 498,
    CLEANSE = 4987,
    HAMMER_OF_JUSTICE = 853,
    REBUKE = 96231,
    AURA_MASTERY = 31821,
    
    -- Talents
    HOLY_AVENGER = 105809,
    AVENGING_WRATH = 31884,
    AVENGING_CRUSADER = 216331,
    DIVINE_FAVOR = 210294,
    RULE_OF_LAW = 214202,
    DIVINE_PURPOSE = 223817,
    LIGHTS_HAMMER = 114158, -- Important in Season 2
    JUDGMENT_OF_LIGHT = 183778, -- Important in Season 2
    GOLDEN_PATH = 377128, -- New in TWW Season 2
    RADIANT_DECREE = 387237, -- New in TWW Season 2
    
    -- Misc
    DEVOTION_AURA = 465,
    CONCENTRATION_AURA = 317920,
    CRUSADER_AURA = 32223,
    RETRIBUTION_AURA = 183435,
    CONSECRATION = 26573,
    JUDGMENT = 275773,
    CRUSADER_STRIKE = 35395
}

-- Spell IDs for Protection Paladin (The War Within, Season 2)
local PROTECTION_SPELLS = {
    -- Core abilities
    SHIELD_OF_THE_RIGHTEOUS = 53600,
    AVENGERS_SHIELD = 31935,
    JUDGMENT = 275779,
    CONSECRATION = 26573,
    HAMMER_OF_THE_RIGHTEOUS = 53595,
    BLESSED_HAMMER = 204019,
    HAMMER_OF_WRATH = 24275,
    WORD_OF_GLORY = 85673,
    ARDENT_DEFENDER = 31850,
    GUARDIAN_OF_ANCIENT_KINGS = 86659,
    DIVINE_TOLL = 375576, -- Added in Season 2
    SENTINEL = 387274, -- New in TWW Season 2
    DIVINE_ARBITER = 389102, -- New in TWW Season 2
    BULWARK_OF_RIGHTEOUS_FURY = 386652, -- New in TWW Season 2
    SANCTIFIED_GROUND = 387557, -- New in TWW Season 2
    SHIELD_OF_HOPE = 378429, -- New in TWW Season 2
    DIVINE_RESONANCE = 384027, -- New in TWW Season 2
    MOMENT_OF_GLORY = 327193, -- Important in TWW Season 2
    
    -- Defensive & utility
    DIVINE_SHIELD = 642,
    BLESSING_OF_PROTECTION = 1022,
    BLESSING_OF_FREEDOM = 1044,
    BLESSING_OF_SACRIFICE = 6940,
    LAY_ON_HANDS = 633,
    CLEANSE_TOXINS = 213644,
    HAMMER_OF_JUSTICE = 853,
    REBUKE = 96231,
    EYE_OF_TYR = 387174, -- New in TWW Season 2
    BLESSING_OF_SUMMER = 388007, -- New in TWW Season 2 (part of Seasons cycle)
    BLESSING_OF_AUTUMN = 388007, -- New in TWW Season 2 (part of Seasons cycle)
    BLESSING_OF_WINTER = 388007, -- New in TWW Season 2 (part of Seasons cycle)
    BLESSING_OF_SPRING = 388007, -- New in TWW Season 2 (part of Seasons cycle)
    
    -- Talents
    HOLY_AVENGER = 105809,
    AVENGING_WRATH = 31884,
    DIVINE_PURPOSE = 223817,
    RIGHTEOUS_PROTECTOR = 204074,
    BULWARK_OF_ORDER = 209389,
    FINAL_STAND = 204077,
    BASTION_OF_LIGHT = 204035,
    CONSECRATED_GROUND = 204054, -- Improved in TWW Season 2
    REDOUBT = 280373, -- Important in TWW Season 2
    BARRICADE_OF_FAITH = 385726, -- New in TWW Season 2
    CRUSADERS_REPRIEVE = 383314, -- New in TWW Season 2
    STRENGTH_IN_ADVERSITY = 393030, -- New in TWW Season 2
    
    -- Misc
    DEVOTION_AURA = 465,
    CONCENTRATION_AURA = 317920,
    CRUSADER_AURA = 32223,
    RETRIBUTION_AURA = 183435
}

-- Spell IDs for Retribution Paladin (The War Within, Season 2)
local RETRIBUTION_SPELLS = {
    -- Core abilities
    CRUSADER_STRIKE = 35395,
    BLADE_OF_JUSTICE = 184575,
    JUDGMENT = 20271,
    TEMPLARS_VERDICT = 85256,
    DIVINE_STORM = 53385,
    WAKE_OF_ASHES = 255937,
    EXECUTION_SENTENCE = 343527,
    FINAL_RECKONING = 343721,
    HAMMER_OF_WRATH = 24275,
    DIVINE_TOLL = 375576, -- Added in Season 2
    BLESSED_HAMMER = 204019, -- New option in TWW Season 2
    TEMPEST_OF_THE_LIGHTBRINGER = 383269, -- New in TWW Season 2
    CRUSADING_STRIKES = 383346, -- New in TWW Season 2
    DIVINE_HAMMER = 198034, -- New option in TWW Season 2
    SANCTIFY = 387591, -- New in TWW Season 2
    CRUSADER_STRIKE_RANK_2 = 389299, -- New in TWW Season 2
    
    -- Defensive & utility
    DIVINE_SHIELD = 642,
    BLESSING_OF_PROTECTION = 1022,
    BLESSING_OF_FREEDOM = 1044,
    BLESSING_OF_SACRIFICE = 6940,
    LAY_ON_HANDS = 633,
    CLEANSE_TOXINS = 213644,
    HAMMER_OF_JUSTICE = 853,
    REBUKE = 96231,
    SHIELD_OF_VENGEANCE = 184662,
    BLESSING_OF_SUMMER = 388007, -- New in TWW Season 2 (part of Seasons cycle)
    BLESSING_OF_AUTUMN = 388007, -- New in TWW Season 2 (part of Seasons cycle)
    BLESSING_OF_WINTER = 388007, -- New in TWW Season 2 (part of Seasons cycle)
    BLESSING_OF_SPRING = 388007, -- New in TWW Season 2 (part of Seasons cycle)
    DIVINE_PROTECTION = 498, -- Re-added in TWW Season 2
    GIFT_OF_THE_GOLDEN_VALKYR = 378279, -- New in TWW Season 2
    
    -- Talents
    HOLY_AVENGER = 105809,
    AVENGING_WRATH = 31884,
    CRUSADE = 231895,
    DIVINE_PURPOSE = 223817,
    SERAPHIM = 152262,
    JUSTICARS_VENGEANCE = 215661,
    EMPYREAN_POWER = 326732,
    THE_FIRES_OF_JUSTICE = 203316,
    ZEAL = 217020,
    RIGHTEOUS_VERDICT = 267610,
    VANGUARDS_MOMENTUM = 383314, -- New in TWW Season 2
    DIVINE_AUXILIARY = 386738, -- New in TWW Season 2
    DIVINE_VINDICATOR = 391174, -- New in TWW Season 2
    SEALED_VERDICT = 387640, -- New in TWW Season 2
    RADIANT_DECREE = 387237, -- New in TWW Season 2
    FORTHRIGHT_CLEANSING = 395787, -- New in TWW Season 2
    
    -- Misc
    DEVOTION_AURA = 465,
    CONCENTRATION_AURA = 317920,
    CRUSADER_AURA = 32223,
    RETRIBUTION_AURA = 183435,
    CONSECRATION = 26573,
    WORD_OF_GLORY = 85673,
    FLASH_OF_LIGHT = 19750
}

-- Important buffs to track (The War Within, Season 2)
local BUFFS = {
    -- Holy Paladin buffs
    DIVINE_PURPOSE = 223819,
    HOLY_AVENGER = 105809,
    AVENGING_WRATH = 31884,
    AVENGING_CRUSADER = 216331,
    DIVINE_FAVOR = 210294,
    INFUSION_OF_LIGHT = 54149,
    RULE_OF_LAW = 214202,
    AURA_MASTERY = 31821,
    DIVINE_SHIELD = 642,
    BLESSING_OF_PROTECTION = 1022,
    BLESSING_OF_FREEDOM = 1044,
    BLESSING_OF_SACRIFICE = 6940,
    BLESSING_OF_SUMMER = 388010, -- Season 2
    BLESSING_OF_AUTUMN = 388011, -- Season 2
    BLESSING_OF_WINTER = 388012, -- Season 2
    BLESSING_OF_SPRING = 388013, -- Season 2
    AFTERIMAGE = 388013, -- Season 2
    DAYBREAK = 387990, -- Season 2
    GOLDEN_PATH = 377151, -- Season 2
    RESPLENDENT_LIGHT = 392907, -- Season 2 
    
    -- Protection Paladin buffs
    SHIELD_OF_THE_RIGHTEOUS = 132403,
    AVENGER_VALOR = 197561,
    CONSECRATION = 188370,
    ARDENT_DEFENDER = 31850,
    GUARDIAN_OF_ANCIENT_KINGS = 86659,
    MOMENT_OF_GLORY = 327193,
    BASTION_OF_LIGHT = 204035,
    SENTINEL = 387275, -- Season 2
    DIVINE_ARBITER = 389105, -- Season 2
    BULWARK_OF_RIGHTEOUS_FURY = 386655, -- Season 2
    SANCTIFIED_GROUND = 387558, -- Season 2
    SHIELD_OF_HOPE = 378425, -- Season 2
    DIVINE_RESONANCE = 384029, -- Season 2
    BARRICADE_OF_FAITH = 385727, -- Season 2
    DIVINE_PROTECTION_PROTECTION = 498, -- Season 2
    STRENGTH_IN_ADVERSITY = 393031, -- Season 2
    
    -- Retribution Paladin buffs
    CRUSADE = 231895,
    BLADE_OF_JUSTICE = 184575,
    SHIELD_OF_VENGEANCE = 184662,
    RIGHTEOUS_VERDICT = 267611,
    EMPYREAN_POWER = 326733,
    DIVINE_PURPOSE_RET = 223819,
    THE_FIRES_OF_JUSTICE = 209785,
    DIVINE_STORM = 53385,
    SERAPHIM = 152262,
    DIVINE_AUXILIARY = 386741, -- Season 2
    VANGUARDS_MOMENTUM = 383317, -- Season 2
    DIVINE_VINDICATOR = 391176, -- Season 2 
    SEALED_VERDICT = 387643, -- Season 2
    TEMPEST_OF_THE_LIGHTBRINGER = 383274, -- Season 2
    CRUSADING_STRIKES = 378852, -- Season 2
    GIFT_OF_THE_GOLDEN_VALKYR = 378286, -- Season 2
    DIVINE_PROTECTION_RETRIBUTION = 498 -- Season 2
}

-- Important debuffs to track (The War Within, Season 2)
local DEBUFFS = {
    -- Common debuffs
    JUDGMENT = 197277,
    FORBEARANCE = 25771,
    
    -- Holy debuffs
    GLIMMER_OF_LIGHT = 287280,
    JUDGMENT_OF_LIGHT = 196941,
    RADIANT_DECREE_DEBUFF = 387239, -- Season 2
    
    -- Protection debuffs
    BLESSED_HAMMER = 204301,
    CONSECRATION_DEBUFF = 204242,
    GUARDIAN_OF_ANCIENT_KINGS_DEBUFF = 86659,
    EYE_OF_TYR_DEBUFF = 387176, -- Season 2
    SANCTIFIED_GROUND_DEBUFF = 387559, -- Season 2
    
    -- Retribution debuffs
    EXECUTION_SENTENCE = 343527,
    FINAL_RECKONING = 343721,
    WAKE_OF_ASHES_DEBUFF = 255937,
    SANCTIFY_DEBUFF = 387599, -- Season 2
    RADIANT_DECREE_RET_DEBUFF = 387239, -- Season 2
    TEMPEST_OF_THE_LIGHTBRINGER_DEBUFF = 383276 -- Season 2
}

-- Initialize the Paladin module
function PaladinModule:Initialize()
    -- Register settings
    self:RegisterSettings()
    
    -- Register events
    self:RegisterEvents()
    
    -- Register rotations
    self:RegisterRotations()
    
    API.PrintDebug("Paladin module initialized")
    return true
end

-- Register settings
function PaladinModule:RegisterSettings()
    ConfigRegistry:RegisterSettings("Paladin", {
        generalSettings = {
            enabled = {
                displayName = "Enable Paladin Module",
                description = "Enable the Paladin module for all specs",
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
            useBlessings = {
                displayName = "Use Blessings",
                description = "Automatically use blessings on party members",
                type = "toggle",
                default = true
            },
            layOnHandsThreshold = {
                displayName = "Lay on Hands Health Threshold",
                description = "Health percentage to use Lay on Hands",
                type = "slider",
                min = 5,
                max = 30,
                step = 5,
                default = 15
            },
            selectedAura = {
                displayName = "Default Aura",
                description = "Aura to maintain while in combat",
                type = "dropdown",
                options = {"Devotion", "Concentration", "Crusader", "Retribution"},
                default = "Devotion"
            },
            useHolyPower = {
                displayName = "Holy Power Usage",
                description = "When to spend Holy Power on heals (for non-Holy specs)",
                type = "dropdown",
                options = {"Emergency Only", "When Needed", "Manual Only"},
                default = "When Needed"
            }
        },
        holySettings = {
            -- Core Healing Abilities
            useBeacon = {
                displayName = "Use Beacon",
                description = "Which Beacon talent to use",
                type = "dropdown",
                options = {"Beacon of Light", "Beacon of Faith", "Beacon of Virtue", "None"},
                default = "Beacon of Light"
            },
            beaconTarget = {
                displayName = "Beacon Target",
                description = "Who to place Beacon of Light on",
                type = "dropdown",
                options = {"Tank", "Self", "Lowest Health", "Smart"},
                default = "Tank"
            },
            useHolyShockOnCooldown = {
                displayName = "Use Holy Shock on Cooldown",
                description = "Prioritize Holy Shock whenever available",
                type = "toggle",
                default = true
            },
            
            -- Cooldowns
            useAvengingWrath = {
                displayName = "Use Avenging Wrath",
                description = "Use Avenging Wrath or Avenging Crusader on cooldown",
                type = "toggle",
                default = true
            },
            useHolyAvenger = {
                displayName = "Use Holy Avenger",
                description = "Use Holy Avenger on cooldown if talented",
                type = "toggle",
                default = true
            },
            useAuraMastery = {
                displayName = "Use Aura Mastery",
                description = "Use Aura Mastery when group damage is high",
                type = "toggle",
                default = true
            },
            aurasMasteryHealthThreshold = {
                displayName = "Aura Mastery Threshold",
                description = "Average group health percentage to use Aura Mastery",
                type = "slider",
                min = 20,
                max = 70,
                step = 5,
                default = 50
            },
            useRuleOfLaw = {
                displayName = "Use Rule of Law",
                description = "Use Rule of Law when healing distant targets",
                type = "toggle",
                default = true
            },
            healingPriority = {
                displayName = "Healing Priority",
                description = "Prioritize efficiency or throughput",
                type = "dropdown",
                options = {"Efficiency", "Throughput", "Balanced"},
                default = "Balanced"
            },
            useDivineToll = {
                displayName = "Use Divine Toll",
                description = "Use Divine Toll in combat",
                type = "toggle",
                default = true
            },
            
            -- Season 2 Abilities
            useBlessingOfSeasons = {
                displayName = "Use Blessing of Seasons (TWW S2)",
                description = "Use Blessing of Seasons cycle for party members",
                type = "toggle",
                default = true
            },
            seasonsCycleMode = {
                displayName = "Seasons Cycle Mode (TWW S2)",
                description = "How to cycle through the seasonal blessings",
                type = "dropdown",
                options = {"Auto-Optimize", "Fixed Rotation", "Situation Based"},
                default = "Auto-Optimize"
            },
            useAfterimage = {
                displayName = "Use Afterimage (TWW S2)",
                description = "Use Afterimage for additional healing",
                type = "toggle",
                default = true
            },
            useDaybreak = {
                displayName = "Use Daybreak (TWW S2)",
                description = "Use Daybreak for AoE healing boost",
                type = "toggle",
                default = true
            },
            daybreakThreshold = {
                displayName = "Daybreak Injured Count (TWW S2)",
                description = "Minimum injured allies to use Daybreak",
                type = "slider",
                min = 2,
                max = 5,
                step = 1,
                default = 3
            },
            useResplendentLight = {
                displayName = "Use Resplendent Light (TWW S2)",
                description = "Use Resplendent Light for improved healing",
                type = "toggle",
                default = true
            },
            useGoldenPath = {
                displayName = "Use Golden Path (TWW S2)",
                description = "Use Golden Path with optimal timing",
                type = "toggle",
                default = true
            },
            useRadiantDecree = {
                displayName = "Use Radiant Decree (TWW S2)",
                description = "Use Radiant Decree for additional damage and healing",
                type = "toggle",
                default = true
            },
            useEmpyreanLegacy = {
                displayName = "Use Empyrean Legacy (TWW S2)",
                description = "Optimize usage of Empyrean Legacy procs",
                type = "toggle",
                default = true
            },
            useLightsHammer = {
                displayName = "Use Light's Hammer (TWW S2)",
                description = "Use Light's Hammer for AoE healing and damage",
                type = "toggle",
                default = true
            },
            lightsHammerThreshold = {
                displayName = "Light's Hammer Injured Count (TWW S2)",
                description = "Minimum injured allies to use Light's Hammer",
                type = "slider",
                min = 2,
                max = 5,
                step = 1,
                default = 3
            }
        },
        protectionSettings = {
            -- Core Active Mitigation
            useShieldOfTheRighteous = {
                displayName = "Use Shield of the Righteous",
                description = "Automatically use Shield of the Righteous for active mitigation",
                type = "toggle",
                default = true
            },
            sotrHolyPowerThreshold = {
                displayName = "SotR Holy Power Threshold",
                description = "Minimum Holy Power to use Shield of the Righteous",
                type = "slider",
                min = 2,
                max = 5,
                step = 1,
                default = 3
            },
            
            -- Defensive Cooldowns
            useArdentDefender = {
                displayName = "Use Ardent Defender",
                description = "Use Ardent Defender at low health",
                type = "toggle",
                default = true
            },
            ardentDefenderThreshold = {
                displayName = "Ardent Defender Health Threshold",
                description = "Health percentage to use Ardent Defender",
                type = "slider",
                min = 10,
                max = 60,
                step = 5,
                default = 35
            },
            useGuardian = {
                displayName = "Use Guardian of Ancient Kings",
                description = "Use Guardian of Ancient Kings at low health",
                type = "toggle",
                default = true
            },
            guardianThreshold = {
                displayName = "Guardian Health Threshold",
                description = "Health percentage to use Guardian of Ancient Kings",
                type = "slider",
                min = 10,
                max = 40,
                step = 5,
                default = 20
            },
            
            -- Healing
            useWordOfGlory = {
                displayName = "Use Word of Glory",
                description = "Use Word of Glory for self-healing",
                type = "toggle",
                default = true
            },
            wordOfGloryThreshold = {
                displayName = "Word of Glory Health Threshold",
                description = "Health percentage to use Word of Glory",
                type = "slider",
                min = 20,
                max = 80,
                step = 5,
                default = 55
            },
            
            -- Rotational Abilities
            avengersShieldPriority = {
                displayName = "Avenger's Shield Priority",
                description = "Prioritize Avenger's Shield over other abilities",
                type = "toggle",
                default = true
            },
            consecrationUptime = {
                displayName = "Consecration Uptime",
                description = "Maintain Consecration uptime",
                type = "toggle",
                default = true
            },
            useDivineToll = {
                displayName = "Use Divine Toll",
                description = "Use Divine Toll in combat",
                type = "toggle",
                default = true
            },
            
            -- Season 2 Abilities
            useSentinel = {
                displayName = "Use Sentinel (TWW S2)",
                description = "Use Sentinel for powerful protection",
                type = "toggle",
                default = true
            },
            sentinelThreshold = {
                displayName = "Sentinel Health Threshold (TWW S2)",
                description = "Health percentage to use Sentinel",
                type = "slider",
                min = 10,
                max = 60,
                step = 5,
                default = 30
            },
            useDivineArbiter = {
                displayName = "Use Divine Arbiter (TWW S2)",
                description = "Use Divine Arbiter for enhanced SotR",
                type = "toggle",
                default = true
            },
            useBulwarkOfRighteousFury = {
                displayName = "Use Bulwark of Righteous Fury (TWW S2)",
                description = "Use Bulwark of Righteous Fury for damage reduction",
                type = "toggle",
                default = true
            },
            useSanctifiedGround = {
                displayName = "Use Sanctified Ground (TWW S2)",
                description = "Use Sanctified Ground for consecration bonuses",
                type = "toggle",
                default = true
            },
            useShieldOfHope = {
                displayName = "Use Shield of Hope (TWW S2)",
                description = "Use Shield of Hope for personal and party protection",
                type = "toggle",
                default = true
            },
            shieldOfHopeThreshold = {
                displayName = "Shield of Hope Health Threshold (TWW S2)",
                description = "Health percentage to use Shield of Hope",
                type = "slider",
                min = 10,
                max = 40,
                step = 5,
                default = 25
            },
            useDivineResonance = {
                displayName = "Use Divine Resonance (TWW S2)",
                description = "Use Divine Resonance for improved SotR",
                type = "toggle",
                default = true
            },
            useMomentOfGlory = {
                displayName = "Use Moment of Glory (TWW S2)",
                description = "Use Moment of Glory for improved avoidance",
                type = "toggle",
                default = true
            },
            useEyeOfTyr = {
                displayName = "Use Eye of Tyr (TWW S2)",
                description = "Use Eye of Tyr for damage reduction",
                type = "toggle",
                default = true
            },
            eyeOfTyrThreshold = {
                displayName = "Eye of Tyr Health Threshold (TWW S2)",
                description = "Health percentage to use Eye of Tyr",
                type = "slider",
                min = 10,
                max = 70,
                step = 5,
                default = 60
            },
            useBlessingOfSeasons = {
                displayName = "Use Blessing of Seasons (TWW S2)",
                description = "Use Blessing of Seasons for tank and party benefits",
                type = "toggle",
                default = true
            },
            seasonsCycleMode = {
                displayName = "Seasons Cycle Mode (TWW S2)",
                description = "How to cycle through the seasonal blessings",
                type = "dropdown",
                options = {"Auto-Optimize", "Fixed Rotation", "Situation Based"},
                default = "Auto-Optimize"
            },
            useDivineProtection = {
                displayName = "Use Divine Protection (TWW S2)",
                description = "Use Divine Protection for magic damage reduction",
                type = "toggle",
                default = true
            },
            divineProtectionThreshold = {
                displayName = "Divine Protection Health Threshold (TWW S2)",
                description = "Health percentage to use Divine Protection",
                type = "slider",
                min = 10,
                max = 80,
                step = 5,
                default = 70
            }
        },
        retributionSettings = {
            -- Core DPS Cooldowns
            useAvengingWrath = {
                displayName = "Use Avenging Wrath/Crusade",
                description = "Use Avenging Wrath or Crusade on cooldown",
                type = "toggle",
                default = true
            },
            useFinalReckoning = {
                displayName = "Use Final Reckoning",
                description = "Use Final Reckoning with Avenging Wrath if talented",
                type = "toggle",
                default = true
            },
            useHolyAvenger = {
                displayName = "Use Holy Avenger",
                description = "Use Holy Avenger on cooldown if talented",
                type = "toggle",
                default = true
            },
            useExecutionSentence = {
                displayName = "Use Execution Sentence",
                description = "Use Execution Sentence in combat if talented",
                type = "toggle",
                default = true
            },
            useSeraphim = {
                displayName = "Use Seraphim",
                description = "Use Seraphim in combat if talented",
                type = "toggle",
                default = true
            },
            
            -- Defensive & Utility
            useShieldOfVengeance = {
                displayName = "Use Shield of Vengeance",
                description = "Use Shield of Vengeance for damage and mitigation",
                type = "toggle",
                default = true
            },
            useWakeOfAshes = {
                displayName = "Use Wake of Ashes",
                description = "Use Wake of Ashes in combat",
                type = "toggle",
                default = true
            },
            useWordOfGlory = {
                displayName = "Use Word of Glory",
                description = "Use Word of Glory for self-healing",
                type = "toggle",
                default = true
            },
            wordOfGloryThreshold = {
                displayName = "Word of Glory Health Threshold",
                description = "Health percentage to use Word of Glory",
                type = "slider",
                min = 20,
                max = 70,
                step = 5,
                default = 40
            },
            
            -- AoE Settings
            aoeThreshold = {
                displayName = "AoE Threshold",
                description = "Number of targets to switch to AoE rotation",
                type = "slider",
                min = 2,
                max = 6,
                step = 1,
                default = 2
            },
            useDivineToll = {
                displayName = "Use Divine Toll",
                description = "Use Divine Toll in combat",
                type = "toggle",
                default = true
            },
            
            -- Season 2 Abilities
            useTempestOfTheLightbringer = {
                displayName = "Use Tempest of the Lightbringer (TWW S2)",
                description = "Use Tempest of the Lightbringer for enhanced Divine Storm",
                type = "toggle",
                default = true
            },
            useCrusadingStrikes = {
                displayName = "Use Crusading Strikes (TWW S2)",
                description = "Use Crusading Strikes for faster CS cooldown",
                type = "toggle",
                default = true
            },
            useDivineHammer = {
                displayName = "Use Divine Hammer (TWW S2)",
                description = "Use Divine Hammer instead of Blade of Justice if talented",
                type = "toggle",
                default = true
            },
            useSanctify = {
                displayName = "Use Sanctify (TWW S2)",
                description = "Use Sanctify for AoE holy damage",
                type = "toggle",
                default = true
            },
            useDivineAuxiliary = {
                displayName = "Use Divine Auxiliary (TWW S2)",
                description = "Use Divine Auxiliary for improved DPS",
                type = "toggle",
                default = true
            },
            useDivineVindicator = {
                displayName = "Use Divine Vindicator (TWW S2)",
                description = "Use Divine Vindicator to optimize Judgment usage",
                type = "toggle",
                default = true
            },
            useSealedVerdict = {
                displayName = "Use Sealed Verdict (TWW S2)",
                description = "Use Sealed Verdict for improved Templar's Verdict",
                type = "toggle",
                default = true
            },
            useRadiantDecree = {
                displayName = "Use Radiant Decree (TWW S2)",
                description = "Use Radiant Decree for damage and healing",
                type = "toggle",
                default = true
            },
            useForthrightCleansing = {
                displayName = "Use Forthright Cleansing (TWW S2)",
                description = "Use Forthright Cleansing for dispel benefits",
                type = "toggle",
                default = true
            },
            useGiftOfTheGoldenValkyr = {
                displayName = "Use Gift of the Golden Valkyr (TWW S2)",
                description = "Use Gift of the Golden Valkyr for wings extension",
                type = "toggle",
                default = true
            },
            useDivineProtection = {
                displayName = "Use Divine Protection (TWW S2)",
                description = "Use Divine Protection for magic damage reduction",
                type = "toggle",
                default = true
            },
            divineProtectionThreshold = {
                displayName = "Divine Protection Health Threshold (TWW S2)",
                description = "Health percentage to use Divine Protection",
                type = "slider",
                min = 10,
                max = 80,
                step = 5,
                default = 70
            },
            useBlessingOfSeasons = {
                displayName = "Use Blessing of Seasons (TWW S2)",
                description = "Use Blessing of Seasons for party benefits",
                type = "toggle",
                default = true
            },
            seasonsCycleMode = {
                displayName = "Seasons Cycle Mode (TWW S2)",
                description = "How to cycle through the seasonal blessings",
                type = "dropdown",
                options = {"Auto-Optimize", "Fixed Rotation", "Situation Based"},
                default = "Auto-Optimize"
            }
        }
    })
    
    -- Add callback for settings changes
    ConfigRegistry:RegisterCallback("Paladin", function(settings)
        self:ApplySettings(settings)
    end)
end

-- Apply settings
function PaladinModule:ApplySettings(settings)
    -- Apply general settings
    isEnabled = settings.generalSettings.enabled
end

-- Register events
function PaladinModule:RegisterEvents()
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
function PaladinModule:OnSpecializationChanged()
    -- Get current spec ID
    playerSpec = API.GetActiveSpecID()
    
    API.PrintDebug("Paladin specialization changed: " .. playerSpec)
    
    -- Ensure correct rotation is registered
    if playerSpec == SPEC_HOLY then
        self:RegisterHolyRotation()
    elseif playerSpec == SPEC_PROTECTION then
        self:RegisterProtectionRotation()
    elseif playerSpec == SPEC_RETRIBUTION then
        self:RegisterRetributionRotation()
    end
end

-- Register rotations
function PaladinModule:RegisterRotations()
    -- Register spec-specific rotations
    self:RegisterHolyRotation()
    self:RegisterProtectionRotation()
    self:RegisterRetributionRotation()
end

-- Register Holy rotation
function PaladinModule:RegisterHolyRotation()
    RotationManager:RegisterRotation("PaladinHoly", {
        id = "PaladinHoly",
        name = "Paladin - Holy",
        class = "PALADIN",
        spec = SPEC_HOLY,
        level = 10,
        description = "Holy Paladin rotation for The War Within Season 2",
        author = "WindrunnerRotations",
        version = "1.0.0",
        rotation = function()
            return self:HolyRotation()
        end
    })
end

-- Register Protection rotation
function PaladinModule:RegisterProtectionRotation()
    RotationManager:RegisterRotation("PaladinProtection", {
        id = "PaladinProtection",
        name = "Paladin - Protection",
        class = "PALADIN",
        spec = SPEC_PROTECTION,
        level = 10,
        description = "Protection Paladin rotation for The War Within Season 2",
        author = "WindrunnerRotations",
        version = "1.0.0",
        rotation = function()
            return self:ProtectionRotation()
        end
    })
end

-- Register Retribution rotation
function PaladinModule:RegisterRetributionRotation()
    RotationManager:RegisterRotation("PaladinRetribution", {
        id = "PaladinRetribution",
        name = "Paladin - Retribution",
        class = "PALADIN",
        spec = SPEC_RETRIBUTION,
        level = 10,
        description = "Retribution Paladin rotation for The War Within Season 2",
        author = "WindrunnerRotations",
        version = "1.0.0",
        rotation = function()
            return self:RetributionRotation()
        end
    })
end

-- Holy rotation
function PaladinModule:HolyRotation()
    -- Check if we should execute
    if not self:ShouldExecuteRotation() then
        return nil
    end
    
    -- Get player and target
    local player = "player"
    local target = "target"
    local lowestAlly = self:GetLowestHealthAlly()
    
    -- Get settings
    local settings = ConfigRegistry:GetSettings("Paladin")
    
    -- Common Combat Variables
    local health, maxHealth, healthPercent = API.GetUnitHealth(player)
    local mana, maxMana, manaPercent = API.GetUnitPower(player, Enum.PowerType.Mana)
    local holyPower = API.GetUnitPower(player, Enum.PowerType.HolyPower)
    local injuredAllies = self:GetInjuredAlliesCount(80)
    local averageGroupHealth = self:GetAverageGroupHealth()
    
    -- Target specific variables
    local lowestAllyHealth, lowestAllyMaxHealth, lowestAllyHealthPercent = 100, 100, 100
    
    if lowestAlly and UnitExists(lowestAlly) then
        lowestAllyHealth, lowestAllyMaxHealth, lowestAllyHealthPercent = API.GetUnitHealth(lowestAlly)
    end
    
    -- Buff tracking
    local hasInfusionOfLight = API.UnitHasBuff(player, BUFFS.INFUSION_OF_LIGHT)
    local hasAvengingWrath = API.UnitHasBuff(player, BUFFS.AVENGING_WRATH)
    local hasAvengingCrusader = API.UnitHasBuff(player, BUFFS.AVENGING_CRUSADER)
    local hasHolyAvenger = API.UnitHasBuff(player, BUFFS.HOLY_AVENGER)
    local hasDivinePurpose = API.UnitHasBuff(player, BUFFS.DIVINE_PURPOSE)
    local hasRuleOfLaw = API.UnitHasBuff(player, BUFFS.RULE_OF_LAW)
    local hasAuraMastery = API.UnitHasBuff(player, BUFFS.AURA_MASTERY)
    
    -- Interrupt if needed
    if settings.generalSettings.useInterrupts and
       API.IsSpellKnown(HOLY_SPELLS.REBUKE) and 
       API.IsSpellUsable(HOLY_SPELLS.REBUKE) and
       API.ShouldInterrupt(target) then
        return {
            type = "spell",
            id = HOLY_SPELLS.REBUKE,
            target = target
        }
    end
    
    -- Check for aura
    if not API.HasActiveAura() and settings.generalSettings.selectedAura ~= "None" then
        local auraSpellID
        
        if settings.generalSettings.selectedAura == "Devotion" then
            auraSpellID = HOLY_SPELLS.DEVOTION_AURA
        elseif settings.generalSettings.selectedAura == "Concentration" then
            auraSpellID = HOLY_SPELLS.CONCENTRATION_AURA
        elseif settings.generalSettings.selectedAura == "Crusader" then
            auraSpellID = HOLY_SPELLS.CRUSADER_AURA
        elseif settings.generalSettings.selectedAura == "Retribution" then
            auraSpellID = HOLY_SPELLS.RETRIBUTION_AURA
        end
        
        if auraSpellID and API.IsSpellKnown(auraSpellID) and API.IsSpellUsable(auraSpellID) then
            return {
                type = "spell",
                id = auraSpellID,
                target = player
            }
        end
    end
    
    -- Cleanse harmful magic/poison/disease effects
    if API.IsSpellKnown(HOLY_SPELLS.CLEANSE) and 
       API.IsSpellUsable(HOLY_SPELLS.CLEANSE) and
       API.HasDispellableDebuff(lowestAlly or player, "Magic", "Poison", "Disease") then
        return {
            type = "spell",
            id = HOLY_SPELLS.CLEANSE,
            target = lowestAlly or player
        }
    end
    
    -- Apply Beacon if needed
    if settings.holySettings.useBeacon ~= "None" and not self:HasActiveBeacon() then
        local beaconSpellID
        
        if settings.holySettings.useBeacon == "Beacon of Light" then
            beaconSpellID = HOLY_SPELLS.BEACON_OF_LIGHT
        elseif settings.holySettings.useBeacon == "Beacon of Faith" then
            beaconSpellID = HOLY_SPELLS.BEACON_OF_FAITH
        elseif settings.holySettings.useBeacon == "Beacon of Virtue" then
            beaconSpellID = HOLY_SPELLS.BEACON_OF_VIRTUE
        end
        
        if beaconSpellID and API.IsSpellKnown(beaconSpellID) and API.IsSpellUsable(beaconSpellID) then
            local beaconTarget = self:GetBeaconTarget(settings.holySettings.beaconTarget)
            
            if beaconTarget then
                return {
                    type = "spell",
                    id = beaconSpellID,
                    target = beaconTarget
                }
            end
        end
    end
    
    -- Emergency cooldowns
    if settings.generalSettings.useDefensives then
        -- Lay on Hands for critical health
        if lowestAllyHealthPercent <= settings.generalSettings.layOnHandsThreshold and
           not API.UnitHasDebuff(player, DEBUFFS.FORBEARANCE) and
           API.IsSpellKnown(HOLY_SPELLS.LAY_ON_HANDS) and 
           API.IsSpellUsable(HOLY_SPELLS.LAY_ON_HANDS) then
            return {
                type = "spell",
                id = HOLY_SPELLS.LAY_ON_HANDS,
                target = lowestAlly or player
            }
        end
        
        -- Divine Protection for self
        if healthPercent < 70 and
           API.IsSpellKnown(HOLY_SPELLS.DIVINE_PROTECTION) and 
           API.IsSpellUsable(HOLY_SPELLS.DIVINE_PROTECTION) then
            return {
                type = "spell",
                id = HOLY_SPELLS.DIVINE_PROTECTION,
                target = player
            }
        end
        
        -- Blessing of Protection for critical ally
        if settings.generalSettings.useBlessings and
           lowestAlly and lowestAllyHealthPercent < 20 and
           not API.UnitHasDebuff(lowestAlly, DEBUFFS.FORBEARANCE) and
           API.IsSpellKnown(HOLY_SPELLS.BLESSING_OF_PROTECTION) and 
           API.IsSpellUsable(HOLY_SPELLS.BLESSING_OF_PROTECTION) and
           not API.UnitIsTank(lowestAlly) then
            return {
                type = "spell",
                id = HOLY_SPELLS.BLESSING_OF_PROTECTION,
                target = lowestAlly
            }
        end
        
        -- Blessing of Sacrifice for critical ally
        if settings.generalSettings.useBlessings and
           lowestAlly and lowestAllyHealthPercent < 40 and healthPercent > 70 and
           API.IsSpellKnown(HOLY_SPELLS.BLESSING_OF_SACRIFICE) and 
           API.IsSpellUsable(HOLY_SPELLS.BLESSING_OF_SACRIFICE) then
            return {
                type = "spell",
                id = HOLY_SPELLS.BLESSING_OF_SACRIFICE,
                target = lowestAlly
            }
        end
        
        -- Divine Shield for self in critical situation
        if healthPercent < 15 and
           not API.UnitHasDebuff(player, DEBUFFS.FORBEARANCE) and
           API.IsSpellKnown(HOLY_SPELLS.DIVINE_SHIELD) and 
           API.IsSpellUsable(HOLY_SPELLS.DIVINE_SHIELD) then
            return {
                type = "spell",
                id = HOLY_SPELLS.DIVINE_SHIELD,
                target = player
            }
        end
    end
    
    -- Group healing cooldowns
    if inCombat then
        -- Aura Mastery for group damage
        if settings.holySettings.useAuraMastery and
           averageGroupHealth <= settings.holySettings.aurasMasteryHealthThreshold and
           API.IsSpellKnown(HOLY_SPELLS.AURA_MASTERY) and 
           API.IsSpellUsable(HOLY_SPELLS.AURA_MASTERY) then
            return {
                type = "spell",
                id = HOLY_SPELLS.AURA_MASTERY,
                target = player
            }
        end
        
        -- Divine Toll
        if settings.holySettings.useDivineToll and
           injuredAllies >= 3 and
           API.IsSpellKnown(HOLY_SPELLS.DIVINE_TOLL) and 
           API.IsSpellUsable(HOLY_SPELLS.DIVINE_TOLL) then
            return {
                type = "spell",
                id = HOLY_SPELLS.DIVINE_TOLL,
                target = lowestAlly or player
            }
        end
        
        -- Rule of Law for distant healing
        if settings.holySettings.useRuleOfLaw and
           not hasRuleOfLaw and
           API.IsSpellKnown(HOLY_SPELLS.RULE_OF_LAW) and 
           API.IsSpellUsable(HOLY_SPELLS.RULE_OF_LAW) and
           injuredAllies >= 3 then
            return {
                type = "spell",
                id = HOLY_SPELLS.RULE_OF_LAW,
                target = player
            }
        end
        
        -- Holy Avenger
        if settings.holySettings.useHolyAvenger and
           API.IsSpellKnown(HOLY_SPELLS.HOLY_AVENGER) and 
           API.IsSpellUsable(HOLY_SPELLS.HOLY_AVENGER) and
           (averageGroupHealth < 70 or injuredAllies >= 3) then
            return {
                type = "spell",
                id = HOLY_SPELLS.HOLY_AVENGER,
                target = player
            }
        end
        
        -- Avenging Wrath/Crusader
        if settings.holySettings.useAvengingWrath then
            if API.IsSpellKnown(HOLY_SPELLS.AVENGING_CRUSADER) and 
               API.IsSpellUsable(HOLY_SPELLS.AVENGING_CRUSADER) and
               injuredAllies >= 3 then
                return {
                    type = "spell",
                    id = HOLY_SPELLS.AVENGING_CRUSADER,
                    target = player
                }
            elseif API.IsSpellKnown(HOLY_SPELLS.AVENGING_WRATH) and 
                   API.IsSpellUsable(HOLY_SPELLS.AVENGING_WRATH) and
                   averageGroupHealth < 80 then
                return {
                    type = "spell",
                    id = HOLY_SPELLS.AVENGING_WRATH,
                    target = player
                }
            end
        end
    end
    
    -- Core healing rotation
    if lowestAlly then
        -- Light of Dawn if multiple injured
        if holyPower >= 3 and injuredAllies >= 2 and
           API.IsSpellKnown(HOLY_SPELLS.LIGHT_OF_DAWN) and 
           API.IsSpellUsable(HOLY_SPELLS.LIGHT_OF_DAWN) then
            return {
                type = "spell",
                id = HOLY_SPELLS.LIGHT_OF_DAWN,
                target = player
            }
        end
        
        -- Word of Glory for single target
        if (holyPower >= 3 or hasDivinePurpose) and injuredAllies < 2 and
           API.IsSpellKnown(HOLY_SPELLS.WORD_OF_GLORY) and 
           API.IsSpellUsable(HOLY_SPELLS.WORD_OF_GLORY) and
           lowestAllyHealthPercent < 70 then
            return {
                type = "spell",
                id = HOLY_SPELLS.WORD_OF_GLORY,
                target = lowestAlly
            }
        end
        
        -- Holy Shock has priority
        if settings.holySettings.useHolyShockOnCooldown and
           API.IsSpellKnown(HOLY_SPELLS.HOLY_SHOCK) and 
           API.IsSpellUsable(HOLY_SPELLS.HOLY_SHOCK) then
            return {
                type = "spell",
                id = HOLY_SPELLS.HOLY_SHOCK,
                target = lowestAlly
            }
        end
        
        -- Divine Favor for critical healing
        if lowestAllyHealthPercent < 40 and
           API.IsSpellKnown(HOLY_SPELLS.DIVINE_FAVOR) and 
           API.IsSpellUsable(HOLY_SPELLS.DIVINE_FAVOR) then
            return {
                type = "spell",
                id = HOLY_SPELLS.DIVINE_FAVOR,
                target = player
            }
        end
        
        -- Holy Prism for group healing
        if API.IsSpellKnown(HOLY_SPELLS.HOLY_PRISM) and 
           API.IsSpellUsable(HOLY_SPELLS.HOLY_PRISM) and
           injuredAllies >= 2 then
            return {
                type = "spell",
                id = HOLY_SPELLS.HOLY_PRISM,
                target = lowestAlly
            }
        end
        
        -- Bestow Faith for prediction healing
        if API.IsSpellKnown(HOLY_SPELLS.BESTOW_FAITH) and 
           API.IsSpellUsable(HOLY_SPELLS.BESTOW_FAITH) and
           lowestAllyHealthPercent < 80 then
            return {
                type = "spell",
                id = HOLY_SPELLS.BESTOW_FAITH,
                target = lowestAlly
            }
        end
        
        -- Flash of Light with Infusion proc
        if hasInfusionOfLight and
           API.IsSpellKnown(HOLY_SPELLS.FLASH_OF_LIGHT) and 
           API.IsSpellUsable(HOLY_SPELLS.FLASH_OF_LIGHT) and
           lowestAllyHealthPercent < 70 then
            return {
                type = "spell",
                id = HOLY_SPELLS.FLASH_OF_LIGHT,
                target = lowestAlly
            }
        end
        
        -- Light of the Martyr for emergency healing
        if lowestAllyHealthPercent < 30 and healthPercent > 60 and
           API.IsSpellKnown(HOLY_SPELLS.LIGHT_OF_THE_MARTYR) and 
           API.IsSpellUsable(HOLY_SPELLS.LIGHT_OF_THE_MARTYR) then
            return {
                type = "spell",
                id = HOLY_SPELLS.LIGHT_OF_THE_MARTYR,
                target = lowestAlly
            }
        end
        
        -- Flash of Light for fast healing
        if lowestAllyHealthPercent < 75 and
           API.IsSpellKnown(HOLY_SPELLS.FLASH_OF_LIGHT) and 
           API.IsSpellUsable(HOLY_SPELLS.FLASH_OF_LIGHT) and
           manaPercent > 25 then
            return {
                type = "spell",
                id = HOLY_SPELLS.FLASH_OF_LIGHT,
                target = lowestAlly
            }
        end
        
        -- Holy Light for efficient healing
        if lowestAllyHealthPercent < 90 and
           API.IsSpellKnown(HOLY_SPELLS.HOLY_LIGHT) and 
           API.IsSpellUsable(HOLY_SPELLS.HOLY_LIGHT) then
            return {
                type = "spell",
                id = HOLY_SPELLS.HOLY_LIGHT,
                target = lowestAlly
            }
        end
    end
    
    -- DPS abilities when healing is not required
    if UnitExists(target) and UnitCanAttack(player, target) and not UnitIsDead(target) and 
       (not lowestAlly or lowestAllyHealthPercent > 90) then
        
        -- Crusader Strike for Holy Power generation
        if API.IsSpellKnown(HOLY_SPELLS.CRUSADER_STRIKE) and 
           API.IsSpellUsable(HOLY_SPELLS.CRUSADER_STRIKE) and
           holyPower < 5 then
            return {
                type = "spell",
                id = HOLY_SPELLS.CRUSADER_STRIKE,
                target = target
            }
        end
        
        -- Judgment for Holy Shock cooldown reduction
        if API.IsSpellKnown(HOLY_SPELLS.JUDGMENT) and 
           API.IsSpellUsable(HOLY_SPELLS.JUDGMENT) then
            return {
                type = "spell",
                id = HOLY_SPELLS.JUDGMENT,
                target = target
            }
        end
        
        -- Holy Shock for damage and Holy Power generation
        if settings.holySettings.useHolyShockOnCooldown and
           API.IsSpellKnown(HOLY_SPELLS.HOLY_SHOCK) and 
           API.IsSpellUsable(HOLY_SPELLS.HOLY_SHOCK) then
            return {
                type = "spell",
                id = HOLY_SPELLS.HOLY_SHOCK,
                target = target
            }
        end
        
        -- Holy Prism for damage
        if API.IsSpellKnown(HOLY_SPELLS.HOLY_PRISM) and 
           API.IsSpellUsable(HOLY_SPELLS.HOLY_PRISM) then
            return {
                type = "spell",
                id = HOLY_SPELLS.HOLY_PRISM,
                target = target
            }
        end
        
        -- Consecration for AoE damage
        if API.IsSpellKnown(HOLY_SPELLS.CONSECRATION) and 
           API.IsSpellUsable(HOLY_SPELLS.CONSECRATION) and
           API.GetEnemyCount(8) >= 2 then
            return {
                type = "spell",
                id = HOLY_SPELLS.CONSECRATION,
                target = player
            }
        end
    end
    
    return nil
end

-- Protection rotation
function PaladinModule:ProtectionRotation()
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
    local settings = ConfigRegistry:GetSettings("Paladin")
    
    -- Common Combat Variables
    local health, maxHealth, healthPercent = API.GetUnitHealth(player)
    local targetHealth, targetMaxHealth, targetHealthPercent = API.GetUnitHealth(target)
    local holyPower = API.GetUnitPower(player, Enum.PowerType.HolyPower)
    local enemies = API.GetEnemyCount(8)
    local aoeEnabled = enemies >= 3
    
    -- Buff tracking
    local hasShieldOfRighteous = API.UnitHasBuff(player, BUFFS.SHIELD_OF_THE_RIGHTEOUS)
    local shieldRemainingDuration = API.GetBuffRemaining(player, BUFFS.SHIELD_OF_THE_RIGHTEOUS)
    local hasArdentDefender = API.UnitHasBuff(player, BUFFS.ARDENT_DEFENDER)
    local hasGuardian = API.UnitHasBuff(player, BUFFS.GUARDIAN_OF_ANCIENT_KINGS)
    local hasDivinePurpose = API.UnitHasBuff(player, BUFFS.DIVINE_PURPOSE)
    local hasAvengingWrath = API.UnitHasBuff(player, BUFFS.AVENGING_WRATH)
    local hasConsecration = API.UnitHasBuff(player, BUFFS.CONSECRATION)
    
    -- Interrupt if needed
    if settings.generalSettings.useInterrupts and
       API.IsSpellKnown(PROTECTION_SPELLS.REBUKE) and 
       API.IsSpellUsable(PROTECTION_SPELLS.REBUKE) and
       API.ShouldInterrupt(target) then
        return {
            type = "spell",
            id = PROTECTION_SPELLS.REBUKE,
            target = target
        }
    end
    
    -- Check for aura
    if not API.HasActiveAura() and settings.generalSettings.selectedAura ~= "None" then
        local auraSpellID
        
        if settings.generalSettings.selectedAura == "Devotion" then
            auraSpellID = PROTECTION_SPELLS.DEVOTION_AURA
        elseif settings.generalSettings.selectedAura == "Concentration" then
            auraSpellID = PROTECTION_SPELLS.CONCENTRATION_AURA
        elseif settings.generalSettings.selectedAura == "Crusader" then
            auraSpellID = PROTECTION_SPELLS.CRUSADER_AURA
        elseif settings.generalSettings.selectedAura == "Retribution" then
            auraSpellID = PROTECTION_SPELLS.RETRIBUTION_AURA
        end
        
        if auraSpellID and API.IsSpellKnown(auraSpellID) and API.IsSpellUsable(auraSpellID) then
            return {
                type = "spell",
                id = auraSpellID,
                target = player
            }
        end
    end
    
    -- Cleanse harmful poison/disease effects
    if API.IsSpellKnown(PROTECTION_SPELLS.CLEANSE_TOXINS) and 
       API.IsSpellUsable(PROTECTION_SPELLS.CLEANSE_TOXINS) and
       API.HasDispellableDebuff(player, "Poison", "Disease") then
        return {
            type = "spell",
            id = PROTECTION_SPELLS.CLEANSE_TOXINS,
            target = player
        }
    end
    
    -- Defensive abilities
    if settings.generalSettings.useDefensives then
        -- Guardian of Ancient Kings
        if settings.protectionSettings.useGuardian and
           healthPercent <= settings.protectionSettings.guardianThreshold and
           API.IsSpellKnown(PROTECTION_SPELLS.GUARDIAN_OF_ANCIENT_KINGS) and 
           API.IsSpellUsable(PROTECTION_SPELLS.GUARDIAN_OF_ANCIENT_KINGS) then
            return {
                type = "spell",
                id = PROTECTION_SPELLS.GUARDIAN_OF_ANCIENT_KINGS,
                target = player
            }
        end
        
        -- Ardent Defender
        if settings.protectionSettings.useArdentDefender and
           healthPercent <= settings.protectionSettings.ardentDefenderThreshold and
           API.IsSpellKnown(PROTECTION_SPELLS.ARDENT_DEFENDER) and 
           API.IsSpellUsable(PROTECTION_SPELLS.ARDENT_DEFENDER) then
            return {
                type = "spell",
                id = PROTECTION_SPELLS.ARDENT_DEFENDER,
                target = player
            }
        end
        
        -- Word of Glory for self-healing
        if settings.protectionSettings.useWordOfGlory and
           healthPercent <= settings.protectionSettings.wordOfGloryThreshold and
           (holyPower >= 3 or hasDivinePurpose) and
           API.IsSpellKnown(PROTECTION_SPELLS.WORD_OF_GLORY) and 
           API.IsSpellUsable(PROTECTION_SPELLS.WORD_OF_GLORY) then
            return {
                type = "spell",
                id = PROTECTION_SPELLS.WORD_OF_GLORY,
                target = player
            }
        end
        
        -- Lay on Hands for emergency
        if healthPercent <= settings.generalSettings.layOnHandsThreshold and
           not API.UnitHasDebuff(player, DEBUFFS.FORBEARANCE) and
           API.IsSpellKnown(PROTECTION_SPELLS.LAY_ON_HANDS) and 
           API.IsSpellUsable(PROTECTION_SPELLS.LAY_ON_HANDS) then
            return {
                type = "spell",
                id = PROTECTION_SPELLS.LAY_ON_HANDS,
                target = player
            }
        end
    end
    
    -- Maintain Shield of the Righteous
    if settings.protectionSettings.useShieldOfTheRighteous and
       (holyPower >= settings.protectionSettings.sotrHolyPowerThreshold or hasDivinePurpose) and
       (not hasShieldOfRighteous or shieldRemainingDuration < 3) and
       API.IsSpellKnown(PROTECTION_SPELLS.SHIELD_OF_THE_RIGHTEOUS) and 
       API.IsSpellUsable(PROTECTION_SPELLS.SHIELD_OF_THE_RIGHTEOUS) then
        return {
            type = "spell",
            id = PROTECTION_SPELLS.SHIELD_OF_THE_RIGHTEOUS,
            target = player
        }
    end
    
    -- Maintain Consecration
    if settings.protectionSettings.consecrationUptime and
       not hasConsecration and
       API.IsSpellKnown(PROTECTION_SPELLS.CONSECRATION) and 
       API.IsSpellUsable(PROTECTION_SPELLS.CONSECRATION) then
        return {
            type = "spell",
            id = PROTECTION_SPELLS.CONSECRATION,
            target = player
        }
    end
    
    -- Offensive cooldowns
    if inCombat then
        -- Avenging Wrath if talented
        if API.IsSpellKnown(PROTECTION_SPELLS.AVENGING_WRATH) and 
           API.IsSpellUsable(PROTECTION_SPELLS.AVENGING_WRATH) then
            return {
                type = "spell",
                id = PROTECTION_SPELLS.AVENGING_WRATH,
                target = player
            }
        end
        
        -- Divine Toll for Holy Power generation
        if settings.protectionSettings.useDivineToll and
           API.IsSpellKnown(PROTECTION_SPELLS.DIVINE_TOLL) and 
           API.IsSpellUsable(PROTECTION_SPELLS.DIVINE_TOLL) then
            return {
                type = "spell",
                id = PROTECTION_SPELLS.DIVINE_TOLL,
                target = target
            }
        end
        
        -- Bastion of Light for Shield of the Righteous charges
        if holyPower <= 1 and
           API.IsSpellKnown(PROTECTION_SPELLS.BASTION_OF_LIGHT) and 
           API.IsSpellUsable(PROTECTION_SPELLS.BASTION_OF_LIGHT) then
            return {
                type = "spell",
                id = PROTECTION_SPELLS.BASTION_OF_LIGHT,
                target = player
            }
        end
    end
    
    -- Core rotation
    -- Avenger's Shield (prioritized)
    if settings.protectionSettings.avengersShieldPriority and
       API.IsSpellKnown(PROTECTION_SPELLS.AVENGERS_SHIELD) and 
       API.IsSpellUsable(PROTECTION_SPELLS.AVENGERS_SHIELD) then
        return {
            type = "spell",
            id = PROTECTION_SPELLS.AVENGERS_SHIELD,
            target = target
        }
    end
    
    -- Judgment for Holy Power generation
    if API.IsSpellKnown(PROTECTION_SPELLS.JUDGMENT) and 
       API.IsSpellUsable(PROTECTION_SPELLS.JUDGMENT) then
        return {
            type = "spell",
            id = PROTECTION_SPELLS.JUDGMENT,
            target = target
        }
    end
    
    -- Hammer of Wrath if available
    if (targetHealthPercent < 20 or hasAvengingWrath) and
       API.IsSpellKnown(PROTECTION_SPELLS.HAMMER_OF_WRATH) and 
       API.IsSpellUsable(PROTECTION_SPELLS.HAMMER_OF_WRATH) then
        return {
            type = "spell",
            id = PROTECTION_SPELLS.HAMMER_OF_WRATH,
            target = target
        }
    end
    
    -- Blessed Hammer if talented
    if API.IsSpellKnown(PROTECTION_SPELLS.BLESSED_HAMMER) and 
       API.IsSpellUsable(PROTECTION_SPELLS.BLESSED_HAMMER) then
        return {
            type = "spell",
            id = PROTECTION_SPELLS.BLESSED_HAMMER,
            target = target
        }
    end
    
    -- Hammer of the Righteous if not using Blessed Hammer
    if not API.IsSpellKnown(PROTECTION_SPELLS.BLESSED_HAMMER) and
       API.IsSpellKnown(PROTECTION_SPELLS.HAMMER_OF_THE_RIGHTEOUS) and 
       API.IsSpellUsable(PROTECTION_SPELLS.HAMMER_OF_THE_RIGHTEOUS) then
        return {
            type = "spell",
            id = PROTECTION_SPELLS.HAMMER_OF_THE_RIGHTEOUS,
            target = target
        }
    end
    
    -- Avenger's Shield as filler
    if not settings.protectionSettings.avengersShieldPriority and
       API.IsSpellKnown(PROTECTION_SPELLS.AVENGERS_SHIELD) and 
       API.IsSpellUsable(PROTECTION_SPELLS.AVENGERS_SHIELD) then
        return {
            type = "spell",
            id = PROTECTION_SPELLS.AVENGERS_SHIELD,
            target = target
        }
    end
    
    -- Consecration as filler if not already active
    if API.IsSpellKnown(PROTECTION_SPELLS.CONSECRATION) and 
       API.IsSpellUsable(PROTECTION_SPELLS.CONSECRATION) then
        return {
            type = "spell",
            id = PROTECTION_SPELLS.CONSECRATION,
            target = player
        }
    end
    
    return nil
end

-- Retribution rotation
function PaladinModule:RetributionRotation()
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
    local settings = ConfigRegistry:GetSettings("Paladin")
    
    -- Common Combat Variables
    local health, maxHealth, healthPercent = API.GetUnitHealth(player)
    local targetHealth, targetMaxHealth, targetHealthPercent = API.GetUnitHealth(target)
    local holyPower = API.GetUnitPower(player, Enum.PowerType.HolyPower)
    local enemies = API.GetEnemyCount(8)
    local aoeEnabled = enemies >= settings.retributionSettings.aoeThreshold
    
    -- Buff tracking
    local hasAvengingWrath = API.UnitHasBuff(player, BUFFS.AVENGING_WRATH)
    local hasCrusade = API.UnitHasBuff(player, BUFFS.CRUSADE)
    local hasDivinePurpose = API.UnitHasBuff(player, BUFFS.DIVINE_PURPOSE_RET)
    local hasTheFiresOfJustice = API.UnitHasBuff(player, BUFFS.THE_FIRES_OF_JUSTICE)
    local hasEmpyreanPower = API.UnitHasBuff(player, BUFFS.EMPYREAN_POWER)
    local hasHolyAvenger = API.UnitHasBuff(player, BUFFS.HOLY_AVENGER)
    local hasSeraphim = API.UnitHasBuff(player, BUFFS.SERAPHIM)
    local hasShieldOfVengeance = API.UnitHasBuff(player, BUFFS.SHIELD_OF_VENGEANCE)
    local targetHasJudgment = API.UnitHasDebuff(target, DEBUFFS.JUDGMENT)
    local targetHasExecutionSentence = API.UnitHasDebuff(target, DEBUFFS.EXECUTION_SENTENCE)
    local targetHasFinalReckoning = API.UnitHasDebuff(target, DEBUFFS.FINAL_RECKONING)
    
    -- Interrupt if needed
    if settings.generalSettings.useInterrupts and
       API.IsSpellKnown(RETRIBUTION_SPELLS.REBUKE) and 
       API.IsSpellUsable(RETRIBUTION_SPELLS.REBUKE) and
       API.ShouldInterrupt(target) then
        return {
            type = "spell",
            id = RETRIBUTION_SPELLS.REBUKE,
            target = target
        }
    end
    
    -- Check for aura
    if not API.HasActiveAura() and settings.generalSettings.selectedAura ~= "None" then
        local auraSpellID
        
        if settings.generalSettings.selectedAura == "Devotion" then
            auraSpellID = RETRIBUTION_SPELLS.DEVOTION_AURA
        elseif settings.generalSettings.selectedAura == "Concentration" then
            auraSpellID = RETRIBUTION_SPELLS.CONCENTRATION_AURA
        elseif settings.generalSettings.selectedAura == "Crusader" then
            auraSpellID = RETRIBUTION_SPELLS.CRUSADER_AURA
        elseif settings.generalSettings.selectedAura == "Retribution" then
            auraSpellID = RETRIBUTION_SPELLS.RETRIBUTION_AURA
        end
        
        if auraSpellID and API.IsSpellKnown(auraSpellID) and API.IsSpellUsable(auraSpellID) then
            return {
                type = "spell",
                id = auraSpellID,
                target = player
            }
        end
    end
    
    -- Cleanse harmful poison/disease effects
    if API.IsSpellKnown(RETRIBUTION_SPELLS.CLEANSE_TOXINS) and 
       API.IsSpellUsable(RETRIBUTION_SPELLS.CLEANSE_TOXINS) and
       API.HasDispellableDebuff(player, "Poison", "Disease") then
        return {
            type = "spell",
            id = RETRIBUTION_SPELLS.CLEANSE_TOXINS,
            target = player
        }
    end
    
    -- Defensive abilities
    if settings.generalSettings.useDefensives then
        -- Shield of Vengeance
        if settings.retributionSettings.useShieldOfVengeance and
           healthPercent < 80 and
           API.IsSpellKnown(RETRIBUTION_SPELLS.SHIELD_OF_VENGEANCE) and 
           API.IsSpellUsable(RETRIBUTION_SPELLS.SHIELD_OF_VENGEANCE) then
            return {
                type = "spell",
                id = RETRIBUTION_SPELLS.SHIELD_OF_VENGEANCE,
                target = player
            }
        end
        
        -- Word of Glory for self-healing
        if settings.retributionSettings.useWordOfGlory and
           healthPercent <= settings.retributionSettings.wordOfGloryThreshold and
           (holyPower >= 3 or hasDivinePurpose) and
           API.IsSpellKnown(RETRIBUTION_SPELLS.WORD_OF_GLORY) and 
           API.IsSpellUsable(RETRIBUTION_SPELLS.WORD_OF_GLORY) then
            return {
                type = "spell",
                id = RETRIBUTION_SPELLS.WORD_OF_GLORY,
                target = player
            }
        end
        
        -- Divine Shield for emergency
        if healthPercent < 15 and
           not API.UnitHasDebuff(player, DEBUFFS.FORBEARANCE) and
           API.IsSpellKnown(RETRIBUTION_SPELLS.DIVINE_SHIELD) and 
           API.IsSpellUsable(RETRIBUTION_SPELLS.DIVINE_SHIELD) then
            return {
                type = "spell",
                id = RETRIBUTION_SPELLS.DIVINE_SHIELD,
                target = player
            }
        end
        
        -- Lay on Hands for emergency
        if healthPercent <= settings.generalSettings.layOnHandsThreshold and
           not API.UnitHasDebuff(player, DEBUFFS.FORBEARANCE) and
           API.IsSpellKnown(RETRIBUTION_SPELLS.LAY_ON_HANDS) and 
           API.IsSpellUsable(RETRIBUTION_SPELLS.LAY_ON_HANDS) then
            return {
                type = "spell",
                id = RETRIBUTION_SPELLS.LAY_ON_HANDS,
                target = player
            }
        end
    end
    
    -- Offensive cooldowns
    if inCombat then
        -- Divine Toll for Holy Power generation
        if settings.retributionSettings.useDivineToll and
           API.IsSpellKnown(RETRIBUTION_SPELLS.DIVINE_TOLL) and 
           API.IsSpellUsable(RETRIBUTION_SPELLS.DIVINE_TOLL) then
            return {
                type = "spell",
                id = RETRIBUTION_SPELLS.DIVINE_TOLL,
                target = target
            }
        end
        
        -- Final Reckoning
        if settings.retributionSettings.useFinalReckoning and
           (hasAvengingWrath or hasCrusade) and
           API.IsSpellKnown(RETRIBUTION_SPELLS.FINAL_RECKONING) and 
           API.IsSpellUsable(RETRIBUTION_SPELLS.FINAL_RECKONING) then
            return {
                type = "spell",
                id = RETRIBUTION_SPELLS.FINAL_RECKONING,
                target = target
            }
        end
        
        -- Execution Sentence
        if settings.retributionSettings.useExecutionSentence and
           API.IsSpellKnown(RETRIBUTION_SPELLS.EXECUTION_SENTENCE) and 
           API.IsSpellUsable(RETRIBUTION_SPELLS.EXECUTION_SENTENCE) and
           (hasAvengingWrath or hasCrusade or not settings.retributionSettings.useAvengingWrath) then
            return {
                type = "spell",
                id = RETRIBUTION_SPELLS.EXECUTION_SENTENCE,
                target = target
            }
        end
        
        -- Holy Avenger
        if settings.retributionSettings.useHolyAvenger and
           API.IsSpellKnown(RETRIBUTION_SPELLS.HOLY_AVENGER) and 
           API.IsSpellUsable(RETRIBUTION_SPELLS.HOLY_AVENGER) then
            return {
                type = "spell",
                id = RETRIBUTION_SPELLS.HOLY_AVENGER,
                target = player
            }
        end
        
        -- Avenging Wrath or Crusade
        if settings.retributionSettings.useAvengingWrath then
            if API.IsSpellKnown(RETRIBUTION_SPELLS.CRUSADE) and 
               API.IsSpellUsable(RETRIBUTION_SPELLS.CRUSADE) then
                return {
                    type = "spell",
                    id = RETRIBUTION_SPELLS.CRUSADE,
                    target = player
                }
            elseif API.IsSpellKnown(RETRIBUTION_SPELLS.AVENGING_WRATH) and 
                   API.IsSpellUsable(RETRIBUTION_SPELLS.AVENGING_WRATH) then
                return {
                    type = "spell",
                    id = RETRIBUTION_SPELLS.AVENGING_WRATH,
                    target = player
                }
            end
        end
        
        -- Seraphim
        if settings.retributionSettings.useSeraphim and
           holyPower >= 3 and
           API.IsSpellKnown(RETRIBUTION_SPELLS.SERAPHIM) and 
           API.IsSpellUsable(RETRIBUTION_SPELLS.SERAPHIM) then
            return {
                type = "spell",
                id = RETRIBUTION_SPELLS.SERAPHIM,
                target = player
            }
        end
    end
    
    -- Core rotation
    -- Wake of Ashes
    if settings.retributionSettings.useWakeOfAshes and
       holyPower <= 2 and
       API.IsSpellKnown(RETRIBUTION_SPELLS.WAKE_OF_ASHES) and 
       API.IsSpellUsable(RETRIBUTION_SPELLS.WAKE_OF_ASHES) then
        return {
            type = "spell",
            id = RETRIBUTION_SPELLS.WAKE_OF_ASHES,
            target = target
        }
    end
    
    -- AoE or single-target spender
    if (holyPower >= 3 or hasDivinePurpose) and targetHasJudgment then
        if aoeEnabled and enemies >= 2 and
           API.IsSpellKnown(RETRIBUTION_SPELLS.DIVINE_STORM) and 
           API.IsSpellUsable(RETRIBUTION_SPELLS.DIVINE_STORM) then
            return {
                type = "spell",
                id = RETRIBUTION_SPELLS.DIVINE_STORM,
                target = player
            }
        elseif API.IsSpellKnown(RETRIBUTION_SPELLS.TEMPLARS_VERDICT) and 
               API.IsSpellUsable(RETRIBUTION_SPELLS.TEMPLARS_VERDICT) then
            return {
                type = "spell",
                id = RETRIBUTION_SPELLS.TEMPLARS_VERDICT,
                target = target
            }
        end
    end
    
    -- Hammer of Wrath
    if (targetHealthPercent < 20 or hasAvengingWrath or hasCrusade) and
       API.IsSpellKnown(RETRIBUTION_SPELLS.HAMMER_OF_WRATH) and 
       API.IsSpellUsable(RETRIBUTION_SPELLS.HAMMER_OF_WRATH) then
        return {
            type = "spell",
            id = RETRIBUTION_SPELLS.HAMMER_OF_WRATH,
            target = target
        }
    end
    
    -- Judgment for 25% increased damage
    if API.IsSpellKnown(RETRIBUTION_SPELLS.JUDGMENT) and 
       API.IsSpellUsable(RETRIBUTION_SPELLS.JUDGMENT) then
        return {
            type = "spell",
            id = RETRIBUTION_SPELLS.JUDGMENT,
            target = target
        }
    end
    
    -- Blade of Justice for Holy Power
    if API.IsSpellKnown(RETRIBUTION_SPELLS.BLADE_OF_JUSTICE) and 
       API.IsSpellUsable(RETRIBUTION_SPELLS.BLADE_OF_JUSTICE) then
        return {
            type = "spell",
            id = RETRIBUTION_SPELLS.BLADE_OF_JUSTICE,
            target = target
        }
    end
    
    -- Crusader Strike for Holy Power
    if API.IsSpellKnown(RETRIBUTION_SPELLS.CRUSADER_STRIKE) and 
       API.IsSpellUsable(RETRIBUTION_SPELLS.CRUSADER_STRIKE) then
        return {
            type = "spell",
            id = RETRIBUTION_SPELLS.CRUSADER_STRIKE,
            target = target
        }
    end
    
    -- Consecration as filler
    if API.IsSpellKnown(RETRIBUTION_SPELLS.CONSECRATION) and 
       API.IsSpellUsable(RETRIBUTION_SPELLS.CONSECRATION) then
        return {
            type = "spell",
            id = RETRIBUTION_SPELLS.CONSECRATION,
            target = player
        }
    end
    
    return nil
end

-- Get lowest health ally
function PaladinModule:GetLowestHealthAlly()
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
function PaladinModule:GetInjuredAlliesCount(threshold)
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
function PaladinModule:GetAverageGroupHealth()
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

-- Check for active aura
function API.HasActiveAura()
    -- This would check for any active aura
    -- For our mock implementation, we'll just return false to ensure auras are applied
    return false
end

-- Get beacon target based on strategy
function PaladinModule:GetBeaconTarget(strategy)
    if strategy == "Tank" then
        -- Find a tank in the party
        for i = 1, 4 do
            local unit = "party" .. i
            if UnitExists(unit) and not UnitIsDead(unit) and API.UnitIsTank(unit) then
                return unit
            end
        end
    elseif strategy == "Self" then
        return "player"
    elseif strategy == "Lowest Health" then
        return self:GetLowestHealthAlly()
    elseif strategy == "Smart" then
        -- Try to find tank first, then fallback to lowest health
        for i = 1, 4 do
            local unit = "party" .. i
            if UnitExists(unit) and not UnitIsDead(unit) and API.UnitIsTank(unit) then
                return unit
            end
        end
        return self:GetLowestHealthAlly()
    end
    
    -- Default to player if no valid target found
    return "player"
end

-- Check if unit is a tank
function API.UnitIsTank(unit)
    if API.IsTinkrLoaded() and Tinkr.Unit then
        return Tinkr.Unit[unit]:IsActingTank()
    end
    
    -- Fallback: check role
    return UnitGroupRolesAssigned(unit) == "TANK"
end

-- Check for active beacon
function PaladinModule:HasActiveBeacon()
    -- This would check for active beacon buffs
    -- For our mock implementation, just return false to ensure beacons are applied
    return false
end

-- Should execute rotation
function PaladinModule:ShouldExecuteRotation()
    if not isEnabled then
        return false
    end
    
    -- Check if player matches class
    local playerInfo = API.GetPlayerInfo()
    if playerInfo.class ~= "PALADIN" then
        return false
    end
    
    return true
end

-- Register for export
WR.Paladin = PaladinModule

return PaladinModule