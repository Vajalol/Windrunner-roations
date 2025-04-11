------------------------------------------
-- WindrunnerRotations - Assassination Rogue Module
-- Author: VortexQ8
-- The War Within Season 2
------------------------------------------

local Assassination = {}
-- This will be assigned to addon.Classes.Rogue.Assassination when loaded

-- These will be set when the file is loaded in our test environment
local API
local ConfigRegistry
local AAC
local Rogue

-- Cache frequently accessed data
local spells = {}
local talents = {}
local buffs = {}
local debuffs = {}

-- State tracking variables
local nextCastOverride = nil
local burstModeActive = false
local currentAoETargets = 0
local currentEnergy = 0
local maxEnergy = 100
local currentComboPoints = 0
local maxComboPoints = 5
local sliceAndDiceActive = false
local sliceAndDiceEndTime = 0
local shadowDanceActive = false
local shadowDanceEndTime = 0
local vanishActive = false
local vanishEndTime = 0
local subterfugeActive = false
local subterfugeEndTime = 0
local envenom = false
local envenomEndTime = 0
local blindsideActive = false
local blindsideEndTime = 0
local ruptureActive = {}
local ruptureEndTime = {}
local garroteActive = {}
local garroteEndTime = {}
local cripplingPoisonActive = {}
local cripplingPoisonEndTime = {}
local deadlyPoisonActive = {}
local deadlyPoisonEndTime = {}
local internalBleedingActive = {}
local internalBleedingEndTime = {}
local toxicBladeActive = false
local toxicBladeEndTime = 0
local deathmarkActive = false
local deathmarkEndTime = 0
local septicShockActive = {}
local septicShockEndTime = {}
local crimsonTemptestActive = {}
local crimsonTemptestEndTime = {}
local kingsbaneActive = {}
local kingsbaneEndTime = {}
local indiscriminateCarnageActive = false
local indiscriminateCarnageEndTime = 0
local stealth = false
local vendettaActive = false
local vendettaEndTime = 0
local exsanguinateActive = {}
local exsanguinateEndTime = {}
local sharpenedBladesDamage = 0
local improved = false
local numPoisons = 0
local sealFateProcs = 0
local masterAssassinStreak = 0
local lastGarrote = 0
local lastRupture = 0
local lastVendetta = 0
local lastMutilate = 0
local lastEnvenom = 0
local finisherUsed = false
local finisherBaseDamage = 0
local targetHealth = 100
local inStealth = false
local inMeleeRange = false
local ambushActive = false
local mutilate = false
local garrote = false
local rupture = false
local deadlyPoison = false
local cripplingPoison = false
local instantPoison = false
local woundPoison = false
local numbingPoison = false
local atrophicPoison = false
local crimsonTempest = false
local toxicBlade = false
local blindside = false
local masterAssassin = false
local impliedFate = false
local exsanguinate = false
local kingsbane = false
local vendetta = false
local deathmark = false
local septicShock = false
local improvedGarrote = false
local shroudedSuffocation = false
local amplifyingPoison = false
local lethalPoison = false
local nonLethalPoison = false
local indiscriminateCarnage = false
local acrobaticStrikes = false
local sealFate = false
local deeperDaggers = false
local echoingReprimand = false
local cripplingPrisonActive = false
local cripplingPrisonEndTime = 0
local indiscriminateCarnageProcs = 0
local masterPoisoner = false
local dreadblade = false
local goremaw = false
local sepsis = false

-- Constants
local ASSASSINATION_SPEC_ID = 259
local DEFAULT_AOE_THRESHOLD = 3
local SLICE_AND_DICE_DURATION = 30 -- seconds (base, can be extended)
local SHADOW_DANCE_DURATION = 8 -- seconds (base)
local VANISH_DURATION = 3 -- seconds (stealth duration)
local SUBTERFUGE_DURATION = 3 -- seconds
local ENVENOM_DURATION = 6 -- seconds (base)
local BLINDSIDE_DURATION = 10 -- seconds
local RUPTURE_DURATION = 24 -- seconds (base, with 5 combo points)
local GARROTE_DURATION = 18 -- seconds (base)
local CRIPPLING_POISON_DURATION = 12 -- seconds
local DEADLY_POISON_DURATION = 12 -- seconds (base)
local INTERNAL_BLEEDING_DURATION = 6 -- seconds
local TOXIC_BLADE_DURATION = 9 -- seconds
local DEATHMARK_DURATION = 20 -- seconds
local SEPTIC_SHOCK_DURATION = 10 -- seconds
local CRIMSON_TEMPEST_DURATION = 12 -- seconds (base)
local KINGSBANE_DURATION = 14 -- seconds
local INDISCRIMINATE_CARNAGE_DURATION = 10 -- seconds
local VENDETTA_DURATION = 20 -- seconds
local EXSANGUINATE_DURATION = 0 -- seconds, this just speeds up the bleeds
local MELEE_RANGE = 5 -- yards
local ACROBATIC_STRIKES_RANGE = 3 -- additional yards

-- Initialize the Assassination module
function Assassination:Initialize()
    self:RegisterSpells()
    self:RegisterVariables()
    self:RegisterSettings()
    self:RegisterEvents()
    
    API.PrintDebug("Assassination Rogue module initialized")
    
    return true
end

-- Register spell IDs
function Assassination:RegisterSpells()
    -- Core rotational abilities
    spells.MUTILATE = 1329
    spells.GARROTE = 703
    spells.RUPTURE = 1943
    spells.ENVENOM = 32645
    spells.SLICE_AND_DICE = 315496
    spells.TOXIC_BLADE = 245388
    spells.EXSANGUINATE = 200806
    spells.CRIMSON_TEMPEST = 121411
    spells.KINGSBANE = 385627
    spells.DEATHMARK = 360194
    spells.SEPTIC_SHOCK = 328305
    spells.AMBUSH = 8676
    spells.FAN_OF_KNIVES = 51723
    spells.SERRATED_BONE_SPIKE = 385424
    spells.SHIV = 5938
    
    -- Core utilities
    spells.VANISH = 1856
    spells.SHADOW_DANCE = 185313
    spells.VENDETTA = 79140
    spells.FEINT = 1966
    spells.EVASION = 5277
    spells.CLOAK_OF_SHADOWS = 31224
    spells.SPRINT = 2983
    spells.SHROUD_OF_CONCEALMENT = 114018
    spells.TRICKS_OF_THE_TRADE = 57934
    spells.STEALTH = 1784
    spells.BLIND = 2094
    spells.KIDNEY_SHOT = 408
    spells.DISTRACT = 1725
    spells.PICK_POCKET = 921
    spells.SAP = 6770
    spells.CHEAP_SHOT = 1833
    spells.CRIMSON_VIAL = 185311
    spells.KICK = 1766
    
    -- Poisons
    spells.DEADLY_POISON = 2823
    spells.CRIPPLING_POISON = 3408
    spells.INSTANT_POISON = 315584
    spells.WOUND_POISON = 8679
    spells.NUMBING_POISON = 5761
    spells.ATROPHIC_POISON = 381637
    spells.AMPLIFYING_POISON = 381664
    
    -- Talents and passives
    spells.SEAL_FATE = 14190
    spells.BLINDSIDE = 328085
    spells.MASTER_ASSASSIN = 255989
    spells.IMPROVED_GARROTE = 381632
    spells.SHROUDED_SUFFOCATION = 385478
    spells.AMPLIFYING_POISON = 381664
    spells.LETHAL_POISON = 396276
    spells.INDISCRIMINATE_CARNAGE = 381802
    spells.SUBTERFUGE = 108208
    spells.NIGHTSTALKER = 14062
    spells.MASTER_POISONER = 378418
    spells.DEEPENING_WOUNDS = 383405
    spells.IMPROVED_POISONS = 381623
    spells.DEEPER_DAGGERS = 382371
    spells.ALACRITY = 193539
    spells.DREADBLADES = 343160
    spells.DASHING_SCOUNDREL = 381797
    spells.GOUGE = 1776
    spells.ACROBATIC_STRIKES = 196924
    spells.CHEAT_DEATH = 31230
    spells.INTERNAL_BLEEDING = 154904
    spells.IRON_WIRE = 196861
    spells.PREY_ON_THE_WEAK = 131511
    spells.MARKING_FOR_DEATH = 137619
    spells.SHADOW_STEP = 36554
    spells.IMPROVED_KICK = 400818
    spells.THICK_AS_THIEVES = 221622
    spells.GLOOMBLADE = 200758
    spells.SEPSIS = 385408
    spells.DEEPER_STRATAGEM = 193531
    spells.ECHOING_REPRIMAND = 385616
    spells.VENOM_RUSH = 152152
    spells.ELABORATE_PLANNING = 193640
    spells.GUSHING_WOUND = 381626
    spells.DOOMBLADE = 381673
    spells.IMPROVED_AMBUSH = 381620
    spells.SOOTHING_DARKNESS = 393970
    spells.THISTLE_TEA = 381623
    spells.LIGHTWEIGHT_SHIV = 394983
    
    -- War Within Season 2 specific
    spells.POISON_BOMB = 255546
    spells.CRIPPLING_PRISON = 397050
    spells.IMPLIED_FATE = 426638
    spells.FLYING_DAGGERS = 423703
    spells.GOREMAW_THE_DEVOURER = 426564
    spells.SHARPENED_BLADES = 426573
    
    -- Covenant abilities (for reference, converted in WoW 10.0)
    spells.SEPSIS = 385408
    spells.ECHOING_REPRIMAND = 385616
    spells.FLAGELLATION = 323654
    spells.SERRATED_BONE_SPIKE = 385424
    
    -- Buff IDs
    spells.SLICE_AND_DICE_BUFF = 315496
    spells.SHADOW_DANCE_BUFF = 185422
    spells.VANISH_BUFF = 11327 -- This is the Vanished buff ID
    spells.SUBTERFUGE_BUFF = 115192
    spells.ENVENOM_BUFF = 32645
    spells.BLINDSIDE_BUFF = 121153
    spells.TOXIC_BLADE_BUFF = 245389
    spells.DEATHMARK_BUFF = 360194
    spells.STEALTH_BUFF = 1784 -- Regular stealth
    spells.INDISCRIMINATE_CARNAGE_BUFF = 385753
    spells.VENDETTA_BUFF = 79140
    spells.MASTER_ASSASSIN_BUFF = 256735
    spells.IMPROVED_GARROTE_BUFF = 392401
    spells.LETHAL_POISON_BUFF = 315584
    spells.AMPLIFYING_POISON_BUFF = 381664
    spells.CRIPPLING_PRISON_BUFF = 397051
    spells.DREADBLADES_BUFF = 343173
    spells.SEPSIS_BUFF = 347037
    spells.GOREMAW_BUFF = 426564
    
    -- Debuff IDs
    spells.RUPTURE_DEBUFF = 1943
    spells.GARROTE_DEBUFF = 703
    spells.CRIPPLING_POISON_DEBUFF = 3409
    spells.DEADLY_POISON_DEBUFF = 2818
    spells.INTERNAL_BLEEDING_DEBUFF = 154953
    spells.SEPTIC_SHOCK_DEBUFF = 328306 -- Verify if this changed
    spells.CRIMSON_TEMPEST_DEBUFF = 121411
    spells.KINGSBANE_DEBUFF = 385627
    spells.VENDETTA_DEBUFF = 79140
    spells.EXSANGUINATE_DEBUFF = 200806 -- Note: Exsanguinate doesn't have a debuff, it just speeds up bleed ticks
    spells.WOUND_POISON_DEBUFF = 8680
    spells.INSTANT_POISON_DEBUFF = 315585
    spells.POISON_BOMB_DEBUFF = 255546
    spells.NUMBING_POISON_DEBUFF = 5760
    spells.ATROPHIC_POISON_DEBUFF = 381637
    spells.SEPSIS_DEBUFF = 328305
    
    -- Register all spells with the API tracking system
    for spellName, spellID in pairs(spells) do
        API.RegisterSpell(spellID)
    end
    
    -- Define aura tracking
    buffs.SLICE_AND_DICE = spells.SLICE_AND_DICE_BUFF
    buffs.SHADOW_DANCE = spells.SHADOW_DANCE_BUFF
    buffs.VANISH = spells.VANISH_BUFF
    buffs.SUBTERFUGE = spells.SUBTERFUGE_BUFF
    buffs.ENVENOM = spells.ENVENOM_BUFF
    buffs.BLINDSIDE = spells.BLINDSIDE_BUFF
    buffs.TOXIC_BLADE = spells.TOXIC_BLADE_BUFF
    buffs.DEATHMARK = spells.DEATHMARK_BUFF
    buffs.STEALTH = spells.STEALTH_BUFF
    buffs.INDISCRIMINATE_CARNAGE = spells.INDISCRIMINATE_CARNAGE_BUFF
    buffs.VENDETTA = spells.VENDETTA_BUFF
    buffs.MASTER_ASSASSIN = spells.MASTER_ASSASSIN_BUFF
    buffs.IMPROVED_GARROTE = spells.IMPROVED_GARROTE_BUFF
    buffs.LETHAL_POISON = spells.LETHAL_POISON_BUFF
    buffs.AMPLIFYING_POISON = spells.AMPLIFYING_POISON_BUFF
    buffs.CRIPPLING_PRISON = spells.CRIPPLING_PRISON_BUFF
    buffs.DREADBLADES = spells.DREADBLADES_BUFF
    buffs.SEPSIS = spells.SEPSIS_BUFF
    buffs.GOREMAW = spells.GOREMAW_BUFF
    
    debuffs.RUPTURE = spells.RUPTURE_DEBUFF
    debuffs.GARROTE = spells.GARROTE_DEBUFF
    debuffs.CRIPPLING_POISON = spells.CRIPPLING_POISON_DEBUFF
    debuffs.DEADLY_POISON = spells.DEADLY_POISON_DEBUFF
    debuffs.INTERNAL_BLEEDING = spells.INTERNAL_BLEEDING_DEBUFF
    debuffs.SEPTIC_SHOCK = spells.SEPTIC_SHOCK_DEBUFF
    debuffs.CRIMSON_TEMPEST = spells.CRIMSON_TEMPEST_DEBUFF
    debuffs.KINGSBANE = spells.KINGSBANE_DEBUFF
    debuffs.VENDETTA = spells.VENDETTA_DEBUFF
    debuffs.WOUND_POISON = spells.WOUND_POISON_DEBUFF
    debuffs.INSTANT_POISON = spells.INSTANT_POISON_DEBUFF
    debuffs.POISON_BOMB = spells.POISON_BOMB_DEBUFF
    debuffs.NUMBING_POISON = spells.NUMBING_POISON_DEBUFF
    debuffs.ATROPHIC_POISON = spells.ATROPHIC_POISON_DEBUFF
    debuffs.SEPSIS = spells.SEPSIS_DEBUFF
    
    return true
end

-- Register variables to track
function Assassination:RegisterVariables()
    -- Talent tracking
    talents.hasSealFate = false
    talents.hasBlindside = false
    talents.hasMasterAssassin = false
    talents.hasImprovedGarrote = false
    talents.hasShroudedSuffocation = false
    talents.hasAmplifyingPoison = false
    talents.hasLethalPoison = false
    talents.hasIndiscriminateCarnage = false
    talents.hasSubterfuge = false
    talents.hasNightstalker = false
    talents.hasMasterPoisoner = false
    talents.hasDeepeningWounds = false
    talents.hasImprovedPoisons = false
    talents.hasDeeperDaggers = false
    talents.hasAlacrity = false
    talents.hasDreadblades = false
    talents.hasDashingScoundrel = false
    talents.hasGouge = false
    talents.hasAcrobaticStrikes = false
    talents.hasCheatDeath = false
    talents.hasInternalBleeding = false
    talents.hasIronWire = false
    talents.hasPreyOnTheWeak = false
    talents.hasMarkingForDeath = false
    talents.hasShadowStep = false
    talents.hasImprovedKick = false
    talents.hasThickAsThieves = false
    talents.hasGloomblade = false
    talents.hasSepsis = false
    talents.hasDeeperStratagem = false
    talents.hasEchoingReprimand = false
    talents.hasVenomRush = false
    talents.hasElaboratePlanning = false
    talents.hasGushingWound = false
    talents.hasDoomblade = false
    talents.hasImprovedAmbush = false
    talents.hasSoothingDarkness = false
    talents.hasThistleTea = false
    talents.hasLightweightShiv = false
    talents.hasToxicBlade = false
    talents.hasExsanguinate = false
    talents.hasCrimsonTempest = false
    talents.hasKingsbane = false
    talents.hasDeathmark = false
    talents.hasSepticShock = false
    
    -- War Within Season 2 talents
    talents.hasPoisonBomb = false
    talents.hasCripplingPrison = false
    talents.hasImpliedFate = false
    talents.hasFlyingDaggers = false
    talents.hasGoremawTheDevourerDebuff = false
    talents.hasSharpenedBlades = false
    
    -- Initialize energy and combo points
    currentEnergy = API.GetPlayerPower()
    maxEnergy = API.GetPlayerMaxPower()
    currentComboPoints = API.GetPlayerComboPoints()
    maxComboPoints = 5 -- Default, could be 6 with Deeper Stratagem
    
    -- Check if in stealth
    inStealth = API.IsStealthed()
    
    -- Initialize tracking tables
    ruptureActive = {}
    ruptureEndTime = {}
    garroteActive = {}
    garroteEndTime = {}
    cripplingPoisonActive = {}
    cripplingPoisonEndTime = {}
    deadlyPoisonActive = {}
    deadlyPoisonEndTime = {}
    internalBleedingActive = {}
    internalBleedingEndTime = {}
    septicShockActive = {}
    septicShockEndTime = {}
    crimsonTemptestActive = {}
    crimsonTemptestEndTime = {}
    kingsbaneActive = {}
    kingsbaneEndTime = {}
    exsanguinateActive = {}
    exsanguinateEndTime = {}
    
    return true
end

-- Register spec-specific settings
function Assassination:RegisterSettings()
    ConfigRegistry:RegisterSettings("AssassinationRogue", {
        rotationSettings = {
            burstEnabled = {
                displayName = "Enable Burst Mode",
                description = "Use cooldowns and focus on burst damage",
                type = "toggle",
                default = true
            },
            aoeEnabled = {
                displayName = "Enable AoE Rotation",
                description = "Use area damage abilities when multiple targets are present",
                type = "toggle",
                default = true
            },
            aoeThreshold = {
                displayName = "AoE Target Threshold",
                description = "Minimum number of targets to use AoE abilities",
                type = "slider",
                min = 2,
                max = 8,
                default = DEFAULT_AOE_THRESHOLD
            },
            energyPooling = {
                displayName = "Energy Pooling",
                description = "Pool energy for important abilities",
                type = "toggle",
                default = true
            },
            energyPoolingThreshold = {
                displayName = "Energy Pooling Threshold",
                description = "Minimum energy to maintain",
                type = "slider",
                min = 20,
                max = 90,
                default = 50
            },
            preRamp = {
                displayName = "Pre-Fight Ramp Up",
                description = "Apply bleeds from stealth before burst window",
                type = "toggle",
                default = true
            },
            autoStealth = {
                displayName = "Auto Stealth",
                description = "Automatically use Stealth when out of combat",
                type = "toggle",
                default = true
            },
            lethalPoisonType = {
                displayName = "Lethal Poison Type",
                description = "Which lethal poison to use",
                type = "dropdown",
                options = {"Deadly Poison", "Instant Poison", "Wound Poison"},
                default = "Deadly Poison"
            },
            nonLethalPoisonType = {
                displayName = "Non-Lethal Poison Type",
                description = "Which non-lethal poison to use",
                type = "dropdown",
                options = {"Crippling Poison", "Numbing Poison", "Atrophic Poison"},
                default = "Crippling Poison"
            },
            useAmplifyingPoison = {
                displayName = "Use Amplifying Poison",
                description = "Use Amplifying Poison when talented instead of non-lethal",
                type = "toggle",
                default = true
            }
        },
        
        bleedSettings = {
            useGarrote = {
                displayName = "Use Garrote",
                description = "Automatically maintain Garrote",
                type = "toggle",
                default = true
            },
            garroteRefreshThreshold = {
                displayName = "Garrote Refresh Threshold",
                description = "Seconds remaining to refresh Garrote",
                type = "slider",
                min = 1,
                max = 10,
                default = 5
            },
            useRupture = {
                displayName = "Use Rupture",
                description = "Automatically maintain Rupture",
                type = "toggle",
                default = true
            },
            ruptureRefreshThreshold = {
                displayName = "Rupture Refresh Threshold",
                description = "Seconds remaining to refresh Rupture",
                type = "slider",
                min = 1,
                max = 10,
                default = 5
            },
            ruptureComboPoints = {
                displayName = "Rupture Combo Points",
                description = "Minimum combo points to use Rupture",
                type = "slider",
                min = 1,
                max = 6,
                default = 4
            },
            useCrimsonTempest = {
                displayName = "Use Crimson Tempest",
                description = "Automatically use Crimson Tempest for AoE bleed",
                type = "toggle",
                default = true
            },
            crimsonTempestMinTargets = {
                displayName = "Crimson Tempest Min Targets",
                description = "Minimum targets to use Crimson Tempest",
                type = "slider",
                min = 2,
                max = 8,
                default = 3
            },
            crimsonTempestComboPoints = {
                displayName = "Crimson Tempest Combo Points",
                description = "Minimum combo points to use Crimson Tempest",
                type = "slider",
                min = 1,
                max = 6,
                default = 4
            },
            multiDotTargetCount = {
                displayName = "Multi-Dot Target Count",
                description = "Maximum targets to apply bleeds to",
                type = "slider",
                min = 1,
                max = 5,
                default = 3
            }
        },
        
        finisherSettings = {
            envenom = {
                displayName = "Use Envenom",
                description = "Automatically use Envenom as a finisher",
                type = "toggle",
                default = true
            },
            envenomComboPoints = {
                displayName = "Envenom Combo Points",
                description = "Minimum combo points to use Envenom",
                type = "slider",
                min = 1,
                max = 6,
                default = 4
            },
            sliceAndDice = {
                displayName = "Use Slice and Dice",
                description = "Automatically maintain Slice and Dice",
                type = "toggle",
                default = true
            },
            sliceAndDiceComboPoints = {
                displayName = "Slice and Dice Combo Points",
                description = "Minimum combo points to use Slice and Dice",
                type = "slider",
                min = 1,
                max = 6,
                default = 4
            },
            sliceAndDiceRefreshThreshold = {
                displayName = "Slice and Dice Refresh Threshold",
                description = "Seconds remaining to refresh Slice and Dice",
                type = "slider",
                min = 1,
                max = 15,
                default = 5
            },
            finisherPriority = {
                displayName = "Finisher Priority",
                description = "How to prioritize finishers",
                type = "dropdown",
                options = {"Slice and Dice > Rupture > Crimson Tempest > Envenom", "Rupture > Slice and Dice > Envenom > Crimson Tempest", "Balanced"},
                default = "Slice and Dice > Rupture > Crimson Tempest > Envenom"
            }
        },
        
        cooldownSettings = {
            useVendetta = {
                displayName = "Use Vendetta",
                description = "Automatically use Vendetta",
                type = "toggle",
                default = true
            },
            vendettaMode = {
                displayName = "Vendetta Usage",
                description = "When to use Vendetta",
                type = "dropdown",
                options = {"On Cooldown", "With Toxic Blade", "Burst Only"},
                default = "On Cooldown"
            },
            useToxicBlade = {
                displayName = "Use Toxic Blade",
                description = "Automatically use Toxic Blade when talented",
                type = "toggle",
                default = true
            },
            toxicBladeMode = {
                displayName = "Toxic Blade Usage",
                description = "When to use Toxic Blade",
                type = "dropdown",
                options = {"On Cooldown", "With Vendetta", "Burst Only"},
                default = "On Cooldown"
            },
            useDeathmark = {
                displayName = "Use Deathmark",
                description = "Automatically use Deathmark when talented",
                type = "toggle",
                default = true
            },
            deathmarkMode = {
                displayName = "Deathmark Usage",
                description = "When to use Deathmark",
                type = "dropdown",
                options = {"On Cooldown", "With Vendetta", "Burst Only"},
                default = "On Cooldown"
            },
            useKingsbane = {
                displayName = "Use Kingsbane",
                description = "Automatically use Kingsbane when talented",
                type = "toggle",
                default = true
            },
            kingsbaneMode = {
                displayName = "Kingsbane Usage",
                description = "When to use Kingsbane",
                type = "dropdown",
                options = {"On Cooldown", "With Vendetta", "Burst Only"},
                default = "On Cooldown"
            },
            useExsanguinate = {
                displayName = "Use Exsanguinate",
                description = "Automatically use Exsanguinate when talented",
                type = "toggle",
                default = true
            },
            exsanguinateMode = {
                displayName = "Exsanguinate Usage",
                description = "When to use Exsanguinate",
                type = "dropdown",
                options = {"On Cooldown", "With Vendetta", "After Bleeds Setup", "Burst Only"},
                default = "After Bleeds Setup"
            },
            useVanish = {
                displayName = "Use Vanish",
                description = "Automatically use Vanish for damage increase",
                type = "toggle",
                default = true
            },
            vanishMode = {
                displayName = "Vanish Usage",
                description = "When to use Vanish",
                type = "dropdown",
                options = {"With Vendetta", "For Garrote", "For Ambush", "Burst Only", "Manual Only"},
                default = "With Vendetta"
            },
            useShadowDance = {
                displayName = "Use Shadow Dance",
                description = "Automatically use Shadow Dance when talented",
                type = "toggle",
                default = true
            },
            shadowDanceMode = {
                displayName = "Shadow Dance Usage",
                description = "When to use Shadow Dance",
                type = "dropdown",
                options = {"On Cooldown", "For Garrote", "With Vendetta", "Burst Only"},
                default = "For Garrote"
            },
            useSepsis = {
                displayName = "Use Sepsis",
                description = "Automatically use Sepsis when talented",
                type = "toggle",
                default = true
            },
            sepsisMode = {
                displayName = "Sepsis Usage",
                description = "When to use Sepsis",
                type = "dropdown",
                options = {"On Cooldown", "With Vendetta", "Burst Only"},
                default = "On Cooldown"
            }
        },
        
        defensiveSettings = {
            useFeint = {
                displayName = "Use Feint",
                description = "Automatically use Feint",
                type = "toggle",
                default = true
            },
            feintMode = {
                displayName = "Feint Usage",
                description = "When to use Feint",
                type = "dropdown",
                options = {"Before AoE Damage", "On Cooldown", "Manual Only"},
                default = "Before AoE Damage"
            },
            useEvasion = {
                displayName = "Use Evasion",
                description = "Automatically use Evasion",
                type = "toggle",
                default = true
            },
            evasionThreshold = {
                displayName = "Evasion Health Threshold",
                description = "Health percentage to use Evasion",
                type = "slider",
                min = 10,
                max = 80,
                default = 40
            },
            useCloakOfShadows = {
                displayName = "Use Cloak of Shadows",
                description = "Automatically use Cloak of Shadows",
                type = "toggle",
                default = true
            },
            cloakMode = {
                displayName = "Cloak Usage",
                description = "When to use Cloak of Shadows",
                type = "dropdown",
                options = {"Against Magic Damage", "Against Debuffs", "Manual Only"},
                default = "Against Magic Damage"
            },
            useCrimsonVial = {
                displayName = "Use Crimson Vial",
                description = "Automatically use Crimson Vial",
                type = "toggle",
                default = true
            },
            crimsonVialThreshold = {
                displayName = "Crimson Vial Health Threshold",
                description = "Health percentage to use Crimson Vial",
                type = "slider",
                min = 10,
                max = 90,
                default = 70
            }
        },
        
        utilitySettings = {
            useKick = {
                displayName = "Use Kick",
                description = "Automatically interrupt with Kick",
                type = "toggle",
                default = true
            },
            useBlind = {
                displayName = "Use Blind",
                description = "Automatically use Blind for crowd control",
                type = "toggle",
                default = true
            },
            useKidneyShot = {
                displayName = "Use Kidney Shot",
                description = "Automatically use Kidney Shot for stun",
                type = "toggle",
                default = true
            },
            kidneyShotComboPoints = {
                displayName = "Kidney Shot Combo Points",
                description = "Minimum combo points to use Kidney Shot",
                type = "slider",
                min = 1,
                max = 6,
                default = 5
            },
            useTricksOfTheTrade = {
                displayName = "Use Tricks of the Trade",
                description = "Automatically use Tricks of the Trade",
                type = "toggle",
                default = true
            },
            tricksTarget = {
                displayName = "Tricks Target",
                description = "Who to target with Tricks of the Trade",
                type = "dropdown",
                options = {"Tank", "Focus", "Manual Only"},
                default = "Tank"
            },
            useDistract = {
                displayName = "Use Distract",
                description = "Automatically use Distract",
                type = "toggle",
                default = false
            }
        },
        
        -- Advanced ability control settings
        abilityControls = {
            -- Vendetta controls
            vendetta = AAC.RegisterAbility(spells.VENDETTA, {
                enabled = true,
                useDuringBurstOnly = false,
                requireBleeds = true,
                requireEnergy = 50
            }),
            
            -- Exsanguinate controls
            exsanguinate = AAC.RegisterAbility(spells.EXSANGUINATE, {
                enabled = true,
                useDuringBurstOnly = false,
                requireBleedsOnTarget = true,
                requireBothBleeds = true
            }),
            
            -- Vanish controls
            vanish = AAC.RegisterAbility(spells.VANISH, {
                enabled = true,
                useDuringBurstOnly = false,
                useForGarrote = true,
                useForAmbush = false
            })
        }
    })
    
    return true
end

-- Register for events 
function Assassination:RegisterEvents()
    -- Register for combat log events to track procs and buffs
    API.RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", function(...) 
        self:HandleCombatLogEvent(...) 
    end)
    
    -- Register for energy updates
    API.RegisterEvent("UNIT_POWER_FREQUENT", function(unit, powerType) 
        if unit == "player" and powerType == "ENERGY" then
            self:UpdateEnergy()
        end
    end)
    
    -- Register for combo point updates
    API.RegisterEvent("UNIT_POWER_FREQUENT", function(unit, powerType) 
        if unit == "player" and powerType == "COMBO_POINTS" then
            self:UpdateComboPoints()
        end
    end)
    
    -- Register for stealth state changes
    API.RegisterEvent("UPDATE_STEALTH", function() 
        self:UpdateStealthState() 
    end)
    
    -- Register for target change events
    API.RegisterEvent("PLAYER_TARGET_CHANGED", function() 
        self:UpdateTargetData() 
    end)
    
    -- Register for talent update events
    API.RegisterEvent("PLAYER_TALENT_UPDATE", function() 
        self:UpdateTalentInfo() 
    end)
    
    -- Initial talent info update
    self:UpdateTalentInfo()
    
    -- Initial stealth check
    self:UpdateStealthState()
    
    return true
end

-- Update talent information
function Assassination:UpdateTalentInfo()
    -- Check for important talents
    talents.hasSealFate = API.HasTalent(spells.SEAL_FATE)
    talents.hasBlindside = API.HasTalent(spells.BLINDSIDE)
    talents.hasMasterAssassin = API.HasTalent(spells.MASTER_ASSASSIN)
    talents.hasImprovedGarrote = API.HasTalent(spells.IMPROVED_GARROTE)
    talents.hasShroudedSuffocation = API.HasTalent(spells.SHROUDED_SUFFOCATION)
    talents.hasAmplifyingPoison = API.HasTalent(spells.AMPLIFYING_POISON)
    talents.hasLethalPoison = API.HasTalent(spells.LETHAL_POISON)
    talents.hasIndiscriminateCarnage = API.HasTalent(spells.INDISCRIMINATE_CARNAGE)
    talents.hasSubterfuge = API.HasTalent(spells.SUBTERFUGE)
    talents.hasNightstalker = API.HasTalent(spells.NIGHTSTALKER)
    talents.hasMasterPoisoner = API.HasTalent(spells.MASTER_POISONER)
    talents.hasDeepeningWounds = API.HasTalent(spells.DEEPENING_WOUNDS)
    talents.hasImprovedPoisons = API.HasTalent(spells.IMPROVED_POISONS)
    talents.hasDeeperDaggers = API.HasTalent(spells.DEEPER_DAGGERS)
    talents.hasAlacrity = API.HasTalent(spells.ALACRITY)
    talents.hasDreadblades = API.HasTalent(spells.DREADBLADES)
    talents.hasDashingScoundrel = API.HasTalent(spells.DASHING_SCOUNDREL)
    talents.hasGouge = API.HasTalent(spells.GOUGE)
    talents.hasAcrobaticStrikes = API.HasTalent(spells.ACROBATIC_STRIKES)
    talents.hasCheatDeath = API.HasTalent(spells.CHEAT_DEATH)
    talents.hasInternalBleeding = API.HasTalent(spells.INTERNAL_BLEEDING)
    talents.hasIronWire = API.HasTalent(spells.IRON_WIRE)
    talents.hasPreyOnTheWeak = API.HasTalent(spells.PREY_ON_THE_WEAK)
    talents.hasMarkingForDeath = API.HasTalent(spells.MARKING_FOR_DEATH)
    talents.hasShadowStep = API.HasTalent(spells.SHADOW_STEP)
    talents.hasImprovedKick = API.HasTalent(spells.IMPROVED_KICK)
    talents.hasThickAsThieves = API.HasTalent(spells.THICK_AS_THIEVES)
    talents.hasGloomblade = API.HasTalent(spells.GLOOMBLADE)
    talents.hasSepsis = API.HasTalent(spells.SEPSIS)
    talents.hasDeeperStratagem = API.HasTalent(spells.DEEPER_STRATAGEM)
    talents.hasEchoingReprimand = API.HasTalent(spells.ECHOING_REPRIMAND)
    talents.hasVenomRush = API.HasTalent(spells.VENOM_RUSH)
    talents.hasElaboratePlanning = API.HasTalent(spells.ELABORATE_PLANNING)
    talents.hasGushingWound = API.HasTalent(spells.GUSHING_WOUND)
    talents.hasDoomblade = API.HasTalent(spells.DOOMBLADE)
    talents.hasImprovedAmbush = API.HasTalent(spells.IMPROVED_AMBUSH)
    talents.hasSoothingDarkness = API.HasTalent(spells.SOOTHING_DARKNESS)
    talents.hasThistleTea = API.HasTalent(spells.THISTLE_TEA)
    talents.hasLightweightShiv = API.HasTalent(spells.LIGHTWEIGHT_SHIV)
    talents.hasToxicBlade = API.HasTalent(spells.TOXIC_BLADE)
    talents.hasExsanguinate = API.HasTalent(spells.EXSANGUINATE)
    talents.hasCrimsonTempest = API.HasTalent(spells.CRIMSON_TEMPEST)
    talents.hasKingsbane = API.HasTalent(spells.KINGSBANE)
    talents.hasDeathmark = API.HasTalent(spells.DEATHMARK)
    talents.hasSepticShock = API.HasTalent(spells.SEPTIC_SHOCK)
    
    -- War Within Season 2 talents
    talents.hasPoisonBomb = API.HasTalent(spells.POISON_BOMB)
    talents.hasCripplingPrison = API.HasTalent(spells.CRIPPLING_PRISON)
    talents.hasImpliedFate = API.HasTalent(spells.IMPLIED_FATE)
    talents.hasFlyingDaggers = API.HasTalent(spells.FLYING_DAGGERS)
    talents.hasGoremawTheDevourerDebuff = API.HasTalent(spells.GOREMAW_THE_DEVOURER)
    talents.hasSharpenedBlades = API.HasTalent(spells.SHARPENED_BLADES)
    
    -- Adjust max combo points based on talents
    if talents.hasDeeperStratagem then
        maxComboPoints = 6
    else
        maxComboPoints = 5
    end
    
    -- Set specialized variables based on talents
    if talents.hasSealFate then
        sealFate = true
    end
    
    if talents.hasBlindside then
        blindside = true
    end
    
    if talents.hasMasterAssassin then
        masterAssassin = true
    end
    
    if talents.hasImprovedGarrote then
        improvedGarrote = true
    end
    
    if talents.hasShroudedSuffocation then
        shroudedSuffocation = true
    end
    
    if talents.hasAmplifyingPoison then
        amplifyingPoison = true
    end
    
    if talents.hasLethalPoison then
        lethalPoison = true
    end
    
    if API.IsSpellKnown(spells.DEADLY_POISON) then
        deadlyPoison = true
    end
    
    if API.IsSpellKnown(spells.CRIPPLING_POISON) then
        cripplingPoison = true
    end
    
    if API.IsSpellKnown(spells.INSTANT_POISON) then
        instantPoison = true
    end
    
    if API.IsSpellKnown(spells.WOUND_POISON) then
        woundPoison = true
    end
    
    if API.IsSpellKnown(spells.NUMBING_POISON) then
        numbingPoison = true
    end
    
    if API.IsSpellKnown(spells.ATROPHIC_POISON) then
        atrophicPoison = true
    end
    
    if talents.hasIndiscriminateCarnage then
        indiscriminateCarnage = true
    end
    
    if talents.hasAcrobaticStrikes then
        acrobaticStrikes = true
    end
    
    if talents.hasDeeperDaggers then
        deeperDaggers = true
    end
    
    if talents.hasEchoingReprimand then
        echoingReprimand = true
    end
    
    if API.IsSpellKnown(spells.MUTILATE) then
        mutilate = true
    end
    
    if API.IsSpellKnown(spells.GARROTE) then
        garrote = true
    end
    
    if API.IsSpellKnown(spells.RUPTURE) then
        rupture = true
    end
    
    if talents.hasCrimsonTempest then
        crimsonTempest = true
    end
    
    if talents.hasToxicBlade then
        toxicBlade = true
    end
    
    if talents.hasExsanguinate then
        exsanguinate = true
    end
    
    if talents.hasKingsbane then
        kingsbane = true
    end
    
    if API.IsSpellKnown(spells.VENDETTA) then
        vendetta = true
    end
    
    if talents.hasDeathmark then
        deathmark = true
    end
    
    if talents.hasSepticShock then
        septicShock = true
    end
    
    if talents.hasImpliedFate then
        impliedFate = true
    end
    
    if talents.hasMasterPoisoner then
        masterPoisoner = true
    end
    
    if talents.hasDreadblades then
        dreadblade = true
    end
    
    if talents.hasGoremawTheDevourerDebuff then
        goremaw = true
    end
    
    if talents.hasSepsis then
        sepsis = true
    end
    
    -- Check if any poisons are applied to the rogue
    if API.UnitHasBuff("player", buffs.LETHAL_POISON) or 
       (amplifyingPoison and API.UnitHasBuff("player", buffs.AMPLIFYING_POISON)) then
        -- Count poisons
        numPoisons = 0
        if API.UnitHasBuff("player", buffs.LETHAL_POISON) then
            numPoisons = numPoisons + 1
        end
        if amplifyingPoison and API.UnitHasBuff("player", buffs.AMPLIFYING_POISON) then
            numPoisons = numPoisons + 1
        end
    else
        numPoisons = 0
    end
    
    API.PrintDebug("Assassination Rogue talents updated")
    
    return true
end

-- Update energy tracking
function Assassination:UpdateEnergy()
    currentEnergy = API.GetPlayerPower()
    return true
end

-- Update combo points tracking
function Assassination:UpdateComboPoints()
    currentComboPoints = API.GetPlayerComboPoints()
    return true
end

-- Update stealth state
function Assassination:UpdateStealthState()
    inStealth = API.IsStealthed()
    
    -- Check for shadow dance and subterfuge
    shadowDanceActive = API.UnitHasBuff("player", buffs.SHADOW_DANCE)
    if shadowDanceActive then
        shadowDanceEndTime = select(6, API.GetBuffInfo("player", buffs.SHADOW_DANCE))
    end
    
    subterfugeActive = API.UnitHasBuff("player", buffs.SUBTERFUGE)
    if subterfugeActive then
        subterfugeEndTime = select(6, API.GetBuffInfo("player", buffs.SUBTERFUGE))
    end
    
    -- Check for Vanish
    vanishActive = API.UnitHasBuff("player", buffs.VANISH)
    if vanishActive then
        vanishEndTime = select(6, API.GetBuffInfo("player", buffs.VANISH))
    end
    
    return true
end

-- Update target data
function Assassination:UpdateTargetData()
    -- Check if in melee range
    inMeleeRange = API.IsUnitInRange("target", acrobaticStrikes and (MELEE_RANGE + ACROBATIC_STRIKES_RANGE) or MELEE_RANGE)
    
    -- Get target GUID
    local targetGUID = API.GetTargetGUID()
    
    -- Update target health
    if targetGUID and targetGUID ~= "" then
        targetHealth = API.GetTargetHealthPercent()
        
        -- Check for Rupture
        local ruptureInfo = API.GetDebuffInfo(targetGUID, debuffs.RUPTURE)
        if ruptureInfo then
            ruptureActive[targetGUID] = true
            ruptureEndTime[targetGUID] = select(6, ruptureInfo)
        else
            ruptureActive[targetGUID] = false
            ruptureEndTime[targetGUID] = 0
        end
        
        -- Check for Garrote
        local garroteInfo = API.GetDebuffInfo(targetGUID, debuffs.GARROTE)
        if garroteInfo then
            garroteActive[targetGUID] = true
            garroteEndTime[targetGUID] = select(6, garroteInfo)
        else
            garroteActive[targetGUID] = false
            garroteEndTime[targetGUID] = 0
        end
        
        -- Check for Deadly Poison
        local deadlyPoisonInfo = API.GetDebuffInfo(targetGUID, debuffs.DEADLY_POISON)
        if deadlyPoisonInfo then
            deadlyPoisonActive[targetGUID] = true
            deadlyPoisonEndTime[targetGUID] = select(6, deadlyPoisonInfo)
        else
            deadlyPoisonActive[targetGUID] = false
            deadlyPoisonEndTime[targetGUID] = 0
        end
        
        -- Check for Crippling Poison
        local cripplingPoisonInfo = API.GetDebuffInfo(targetGUID, debuffs.CRIPPLING_POISON)
        if cripplingPoisonInfo then
            cripplingPoisonActive[targetGUID] = true
            cripplingPoisonEndTime[targetGUID] = select(6, cripplingPoisonInfo)
        else
            cripplingPoisonActive[targetGUID] = false
            cripplingPoisonEndTime[targetGUID] = 0
        end
        
        -- Check for Internal Bleeding
        if talents.hasInternalBleeding then
            local internalBleedingInfo = API.GetDebuffInfo(targetGUID, debuffs.INTERNAL_BLEEDING)
            if internalBleedingInfo then
                internalBleedingActive[targetGUID] = true
                internalBleedingEndTime[targetGUID] = select(6, internalBleedingInfo)
            else
                internalBleedingActive[targetGUID] = false
                internalBleedingEndTime[targetGUID] = 0
            end
        end
        
        -- Check for Septic Shock
        if septicShock then
            local septicShockInfo = API.GetDebuffInfo(targetGUID, debuffs.SEPTIC_SHOCK)
            if septicShockInfo then
                septicShockActive[targetGUID] = true
                septicShockEndTime[targetGUID] = select(6, septicShockInfo)
            else
                septicShockActive[targetGUID] = false
                septicShockEndTime[targetGUID] = 0
            end
        end
        
        -- Check for Crimson Tempest
        if crimsonTempest then
            local crimsonTemptestInfo = API.GetDebuffInfo(targetGUID, debuffs.CRIMSON_TEMPEST)
            if crimsonTemptestInfo then
                crimsonTemptestActive[targetGUID] = true
                crimsonTemptestEndTime[targetGUID] = select(6, crimsonTemptestInfo)
            else
                crimsonTemptestActive[targetGUID] = false
                crimsonTemptestEndTime[targetGUID] = 0
            end
        end
        
        -- Check for Kingsbane
        if kingsbane then
            local kingsbaneInfo = API.GetDebuffInfo(targetGUID, debuffs.KINGSBANE)
            if kingsbaneInfo then
                kingsbaneActive[targetGUID] = true
                kingsbaneEndTime[targetGUID] = select(6, kingsbaneInfo)
            else
                kingsbaneActive[targetGUID] = false
                kingsbaneEndTime[targetGUID] = 0
            end
        end
        
        -- Check for Vendetta
        if vendetta then
            local vendettaInfo = API.GetDebuffInfo(targetGUID, debuffs.VENDETTA)
            if vendettaInfo then
                vendettaActive = true
                vendettaEndTime = select(6, vendettaInfo)
            else
                vendettaActive = false
                vendettaEndTime = 0
            end
        end
    end
    
    -- Update AoE targets count
    currentAoETargets = API.GetNearbyEnemiesCount(8) -- Fan of Knives range
    
    return true
end

-- Handle combat log events
function Assassination:HandleCombatLogEvent(...)
    local timestamp, eventType, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, spellID, spellName = CombatLogGetCurrentEventInfo()
    
    -- Track buff applications
    if eventType == "SPELL_AURA_APPLIED" or eventType == "SPELL_AURA_REFRESH" then
        -- Track player buffs
        if destGUID == API.GetPlayerGUID() then
            -- Track Slice and Dice
            if spellID == buffs.SLICE_AND_DICE then
                sliceAndDiceActive = true
                sliceAndDiceEndTime = select(6, API.GetBuffInfo("player", buffs.SLICE_AND_DICE))
                API.PrintDebug("Slice and Dice activated")
            end
            
            -- Track Shadow Dance
            if spellID == buffs.SHADOW_DANCE then
                shadowDanceActive = true
                shadowDanceEndTime = select(6, API.GetBuffInfo("player", buffs.SHADOW_DANCE))
                API.PrintDebug("Shadow Dance activated")
            end
            
            -- Track Vanish
            if spellID == buffs.VANISH then
                vanishActive = true
                vanishEndTime = select(6, API.GetBuffInfo("player", buffs.VANISH))
                API.PrintDebug("Vanish activated")
            end
            
            -- Track Subterfuge
            if spellID == buffs.SUBTERFUGE then
                subterfugeActive = true
                subterfugeEndTime = select(6, API.GetBuffInfo("player", buffs.SUBTERFUGE))
                API.PrintDebug("Subterfuge activated")
            end
            
            -- Track Envenom
            if spellID == buffs.ENVENOM then
                envenom = true
                envenomEndTime = select(6, API.GetBuffInfo("player", buffs.ENVENOM))
                API.PrintDebug("Envenom activated")
            end
            
            -- Track Blindside
            if spellID == buffs.BLINDSIDE then
                blindsideActive = true
                blindsideEndTime = select(6, API.GetBuffInfo("player", buffs.BLINDSIDE))
                API.PrintDebug("Blindside proc activated")
            end
            
            -- Track Toxic Blade
            if spellID == buffs.TOXIC_BLADE then
                toxicBladeActive = true
                toxicBladeEndTime = select(6, API.GetBuffInfo("player", buffs.TOXIC_BLADE))
                API.PrintDebug("Toxic Blade activated")
            end
            
            -- Track Deathmark
            if spellID == buffs.DEATHMARK then
                deathmarkActive = true
                deathmarkEndTime = select(6, API.GetBuffInfo("player", buffs.DEATHMARK))
                API.PrintDebug("Deathmark activated")
            end
            
            -- Track Stealth
            if spellID == buffs.STEALTH then
                stealth = true
                API.PrintDebug("Stealth activated")
            end
            
            -- Track Indiscriminate Carnage
            if spellID == buffs.INDISCRIMINATE_CARNAGE then
                indiscriminateCarnageActive = true
                indiscriminateCarnageEndTime = select(6, API.GetBuffInfo("player", buffs.INDISCRIMINATE_CARNAGE))
                API.PrintDebug("Indiscriminate Carnage activated")
            end
            
            -- Track Master Assassin
            if spellID == buffs.MASTER_ASSASSIN then
                masterAssassinStreak = select(4, API.GetBuffInfo("player", buffs.MASTER_ASSASSIN)) or 1
                API.PrintDebug("Master Assassin stacks: " .. tostring(masterAssassinStreak))
            end
            
            -- Track Improved Garrote
            if spellID == buffs.IMPROVED_GARROTE then
                API.PrintDebug("Improved Garrote activated")
            end
            
            -- Track Lethal and Amplifying Poison applications on self (when applied to weapons)
            if spellID == buffs.LETHAL_POISON or spellID == buffs.AMPLIFYING_POISON then
                -- Count poisons
                numPoisons = 0
                if API.UnitHasBuff("player", buffs.LETHAL_POISON) then
                    numPoisons = numPoisons + 1
                end
                if amplifyingPoison and API.UnitHasBuff("player", buffs.AMPLIFYING_POISON) then
                    numPoisons = numPoisons + 1
                end
            end
            
            -- Track Crippling Prison
            if spellID == buffs.CRIPPLING_PRISON then
                cripplingPrisonActive = true
                cripplingPrisonEndTime = select(6, API.GetBuffInfo("player", buffs.CRIPPLING_PRISON))
                API.PrintDebug("Crippling Prison activated")
            end
            
            -- Track Dreadblades
            if spellID == buffs.DREADBLADES then
                API.PrintDebug("Dreadblades activated")
            end
            
            -- Track Sepsis
            if spellID == buffs.SEPSIS then
                API.PrintDebug("Sepsis activated")
            end
            
            -- Track Goremaw
            if spellID == buffs.GOREMAW then
                API.PrintDebug("Goremaw the Devourer activated")
            end
        end
        
        -- Track debuffs on any target
        if sourceGUID == API.GetPlayerGUID() then
            -- Track Rupture
            if spellID == debuffs.RUPTURE then
                ruptureActive[destGUID] = true
                ruptureEndTime[destGUID] = select(6, API.GetDebuffInfo(destGUID, debuffs.RUPTURE))
                API.PrintDebug("Rupture applied to " .. destName)
            end
            
            -- Track Garrote
            if spellID == debuffs.GARROTE then
                garroteActive[destGUID] = true
                garroteEndTime[destGUID] = select(6, API.GetDebuffInfo(destGUID, debuffs.GARROTE))
                API.PrintDebug("Garrote applied to " .. destName)
            end
            
            -- Track Deadly Poison
            if spellID == debuffs.DEADLY_POISON then
                deadlyPoisonActive[destGUID] = true
                deadlyPoisonEndTime[destGUID] = select(6, API.GetDebuffInfo(destGUID, debuffs.DEADLY_POISON))
                API.PrintDebug("Deadly Poison applied to " .. destName)
            end
            
            -- Track Crippling Poison
            if spellID == debuffs.CRIPPLING_POISON then
                cripplingPoisonActive[destGUID] = true
                cripplingPoisonEndTime[destGUID] = select(6, API.GetDebuffInfo(destGUID, debuffs.CRIPPLING_POISON))
                API.PrintDebug("Crippling Poison applied to " .. destName)
            end
            
            -- Track Internal Bleeding
            if spellID == debuffs.INTERNAL_BLEEDING then
                internalBleedingActive[destGUID] = true
                internalBleedingEndTime[destGUID] = select(6, API.GetDebuffInfo(destGUID, debuffs.INTERNAL_BLEEDING))
                API.PrintDebug("Internal Bleeding applied to " .. destName)
            end
            
            -- Track Septic Shock
            if spellID == debuffs.SEPTIC_SHOCK then
                septicShockActive[destGUID] = true
                septicShockEndTime[destGUID] = select(6, API.GetDebuffInfo(destGUID, debuffs.SEPTIC_SHOCK))
                API.PrintDebug("Septic Shock applied to " .. destName)
            end
            
            -- Track Crimson Tempest
            if spellID == debuffs.CRIMSON_TEMPEST then
                crimsonTemptestActive[destGUID] = true
                crimsonTemptestEndTime[destGUID] = select(6, API.GetDebuffInfo(destGUID, debuffs.CRIMSON_TEMPEST))
                API.PrintDebug("Crimson Tempest applied to " .. destName)
            end
            
            -- Track Kingsbane
            if spellID == debuffs.KINGSBANE then
                kingsbaneActive[destGUID] = true
                kingsbaneEndTime[destGUID] = select(6, API.GetDebuffInfo(destGUID, debuffs.KINGSBANE))
                API.PrintDebug("Kingsbane applied to " .. destName)
            end
            
            -- Track Vendetta
            if spellID == debuffs.VENDETTA then
                vendettaActive = true
                vendettaEndTime = select(6, API.GetDebuffInfo(destGUID, debuffs.VENDETTA))
                API.PrintDebug("Vendetta applied to " .. destName)
            end
            
            -- Track Sepsis
            if spellID == debuffs.SEPSIS then
                API.PrintDebug("Sepsis applied to " .. destName)
            end
        end
    end
    
    -- Track buff removals
    if eventType == "SPELL_AURA_REMOVED" then
        -- Track player buff removals
        if destGUID == API.GetPlayerGUID() then
            -- Track Slice and Dice
            if spellID == buffs.SLICE_AND_DICE then
                sliceAndDiceActive = false
                API.PrintDebug("Slice and Dice faded")
            end
            
            -- Track Shadow Dance
            if spellID == buffs.SHADOW_DANCE then
                shadowDanceActive = false
                API.PrintDebug("Shadow Dance faded")
            end
            
            -- Track Vanish
            if spellID == buffs.VANISH then
                vanishActive = false
                API.PrintDebug("Vanish faded")
            end
            
            -- Track Subterfuge
            if spellID == buffs.SUBTERFUGE then
                subterfugeActive = false
                API.PrintDebug("Subterfuge faded")
            end
            
            -- Track Envenom
            if spellID == buffs.ENVENOM then
                envenom = false
                API.PrintDebug("Envenom faded")
            end
            
            -- Track Blindside
            if spellID == buffs.BLINDSIDE then
                blindsideActive = false
                API.PrintDebug("Blindside proc faded")
            end
            
            -- Track Toxic Blade
            if spellID == buffs.TOXIC_BLADE then
                toxicBladeActive = false
                API.PrintDebug("Toxic Blade faded")
            end
            
            -- Track Deathmark
            if spellID == buffs.DEATHMARK then
                deathmarkActive = false
                API.PrintDebug("Deathmark faded")
            end
            
            -- Track Stealth
            if spellID == buffs.STEALTH then
                stealth = false
                API.PrintDebug("Stealth faded")
            end
            
            -- Track Indiscriminate Carnage
            if spellID == buffs.INDISCRIMINATE_CARNAGE then
                indiscriminateCarnageActive = false
                API.PrintDebug("Indiscriminate Carnage faded")
            end
            
            -- Track Crippling Prison
            if spellID == buffs.CRIPPLING_PRISON then
                cripplingPrisonActive = false
                API.PrintDebug("Crippling Prison faded")
            end
        end
        
        -- Track debuff removals
        if sourceGUID == API.GetPlayerGUID() then
            -- Track Rupture
            if spellID == debuffs.RUPTURE and ruptureActive[destGUID] then
                ruptureActive[destGUID] = false
                API.PrintDebug("Rupture faded from " .. destName)
            end
            
            -- Track Garrote
            if spellID == debuffs.GARROTE and garroteActive[destGUID] then
                garroteActive[destGUID] = false
                API.PrintDebug("Garrote faded from " .. destName)
            end
            
            -- Track Deadly Poison
            if spellID == debuffs.DEADLY_POISON and deadlyPoisonActive[destGUID] then
                deadlyPoisonActive[destGUID] = false
                API.PrintDebug("Deadly Poison faded from " .. destName)
            end
            
            -- Track Crippling Poison
            if spellID == debuffs.CRIPPLING_POISON and cripplingPoisonActive[destGUID] then
                cripplingPoisonActive[destGUID] = false
                API.PrintDebug("Crippling Poison faded from " .. destName)
            end
            
            -- Track Internal Bleeding
            if spellID == debuffs.INTERNAL_BLEEDING and internalBleedingActive[destGUID] then
                internalBleedingActive[destGUID] = false
                API.PrintDebug("Internal Bleeding faded from " .. destName)
            end
            
            -- Track Septic Shock
            if spellID == debuffs.SEPTIC_SHOCK and septicShockActive[destGUID] then
                septicShockActive[destGUID] = false
                API.PrintDebug("Septic Shock faded from " .. destName)
            end
            
            -- Track Crimson Tempest
            if spellID == debuffs.CRIMSON_TEMPEST and crimsonTemptestActive[destGUID] then
                crimsonTemptestActive[destGUID] = false
                API.PrintDebug("Crimson Tempest faded from " .. destName)
            end
            
            -- Track Kingsbane
            if spellID == debuffs.KINGSBANE and kingsbaneActive[destGUID] then
                kingsbaneActive[destGUID] = false
                API.PrintDebug("Kingsbane faded from " .. destName)
            end
            
            -- Track Vendetta
            if spellID == debuffs.VENDETTA then
                vendettaActive = false
                API.PrintDebug("Vendetta faded from " .. destName)
            end
        end
    end
    
    -- Track finisher usage for Seal Fate procs
    if eventType == "SPELL_CAST_SUCCESS" then
        if sourceGUID == API.GetPlayerGUID() then
            if spellID == spells.GARROTE then
                lastGarrote = GetTime()
                API.PrintDebug("Garrote cast")
                ambushActive = false -- Since we used garrote from stealth instead of ambush
            elseif spellID == spells.AMBUSH then
                ambushActive = true
                API.PrintDebug("Ambush cast")
            elseif spellID == spells.RUPTURE then
                lastRupture = GetTime()
                API.PrintDebug("Rupture cast")
                finisherUsed = true
                
                -- Track for Implied Fate
                if impliedFate then
                    local comboPointsUsed = currentComboPoints
                    API.PrintDebug("Rupture used with " .. tostring(comboPointsUsed) .. " combo points")
                end
            elseif spellID == spells.VENDETTA then
                lastVendetta = GetTime()
                API.PrintDebug("Vendetta cast")
            elseif spellID == spells.MUTILATE then
                lastMutilate = GetTime()
                API.PrintDebug("Mutilate cast")
                
                -- Track Seal Fate procs
                if sealFate then
                    local sealFateChance = 50 -- 50% chance baseline to get an extra combo point
                    local roll = math.random(100)
                    if roll <= sealFateChance then
                        sealFateProcs = sealFateProcs + 1
                        API.PrintDebug("Seal Fate proc")
                    end
                end
            elseif spellID == spells.ENVENOM then
                lastEnvenom = GetTime()
                API.PrintDebug("Envenom cast")
                finisherUsed = true
                
                -- Track for Implied Fate
                if impliedFate then
                    local comboPointsUsed = currentComboPoints
                    API.PrintDebug("Envenom used with " .. tostring(comboPointsUsed) .. " combo points")
                end
            elseif spellID == spells.TOXIC_BLADE then
                API.PrintDebug("Toxic Blade cast")
            elseif spellID == spells.EXSANGUINATE then
                API.PrintDebug("Exsanguinate cast")
                
                -- Track Exsanguinate on target, it speeds up all bleeds
                local targetGUID = API.GetTargetGUID()
                if targetGUID then
                    exsanguinateActive[targetGUID] = true
                    exsanguinateEndTime[targetGUID] = GetTime() + EXSANGUINATE_DURATION -- This is a placeholder, as it doesn't have a duration
                end
            elseif spellID == spells.CRIMSON_TEMPEST then
                API.PrintDebug("Crimson Tempest cast")
                finisherUsed = true
            elseif spellID == spells.KINGSBANE then
                API.PrintDebug("Kingsbane cast")
            elseif spellID == spells.DEATHMARK then
                API.PrintDebug("Deathmark cast")
            elseif spellID == spells.FAN_OF_KNIVES then
                API.PrintDebug("Fan of Knives cast")
                
                -- Track for Indiscriminate Carnage procs
                if indiscriminateCarnage and indiscriminateCarnageActive then
                    indiscriminateCarnageProcs = indiscriminateCarnageProcs + 1
                    API.PrintDebug("Indiscriminate Carnage proc #" .. tostring(indiscriminateCarnageProcs))
                end
            elseif spellID == spells.SEPTIC_SHOCK then
                API.PrintDebug("Septic Shock cast")
            elseif spellID == spells.VANISH then
                API.PrintDebug("Vanish cast")
                inStealth = true
            elseif spellID == spells.SHADOW_DANCE then
                API.PrintDebug("Shadow Dance cast")
            elseif spellID == spells.SEPSIS then
                API.PrintDebug("Sepsis cast")
            end
        end
    end
    
    -- Track Sharpened Blades effects on Garrote and Rupture damage
    if eventType == "SPELL_PERIODIC_DAMAGE" and sourceGUID == API.GetPlayerGUID() then
        if spellID == debuffs.RUPTURE or spellID == debuffs.GARROTE then
            if talents.hasSharpenedBlades then
                -- Increment damage tracker for Sharpened Blades
                sharpenedBladesDamage = sharpenedBladesDamage + 1
                
                if sharpenedBladesDamage % 10 == 0 then
                    API.PrintDebug("Sharpened Blades triggered bonus damage")
                end
            end
        end
    end
    
    return true
end

-- Main rotation function
function Assassination:RunRotation()
    -- Check if we should be running Assassination Rogue logic
    if API.GetActiveSpecID() ~= ASSASSINATION_SPEC_ID then
        return false
    end
    
    -- Skip rotation if player is casting
    if API.IsPlayerCasting() then
        return false
    end
    
    -- Get settings
    local settings = ConfigRegistry:GetSettings("AssassinationRogue")
    
    -- Update variables
    self:UpdateEnergy()
    self:UpdateComboPoints()
    burstModeActive = settings.rotationSettings.burstEnabled and API.ShouldUseBurst()
    self:UpdateTargetData() -- Makes sure we have current target information
    
    -- Handle next cast override
    if nextCastOverride and API.CanCast(nextCastOverride) then
        local spell = nextCastOverride
        nextCastOverride = nil
        API.CastSpell(spell)
        return true
    end
    
    -- Check for poisons that need to be applied
    if numPoisons < 2 and not API.IsInCombat() then
        -- Apply lethal poison
        if not API.UnitHasBuff("player", buffs.LETHAL_POISON) then
            local lethalPoisonToUse
            
            if settings.rotationSettings.lethalPoisonType == "Deadly Poison" and deadlyPoison then
                lethalPoisonToUse = spells.DEADLY_POISON
            elseif settings.rotationSettings.lethalPoisonType == "Instant Poison" and instantPoison then
                lethalPoisonToUse = spells.INSTANT_POISON
            elseif settings.rotationSettings.lethalPoisonType == "Wound Poison" and woundPoison then
                lethalPoisonToUse = spells.WOUND_POISON
            end
            
            if lethalPoisonToUse and API.CanCast(lethalPoisonToUse) then
                API.CastSpell(lethalPoisonToUse)
                return true
            end
        end
        
        -- Apply non-lethal or amplifying poison
        if (amplifyingPoison and settings.rotationSettings.useAmplifyingPoison and 
            not API.UnitHasBuff("player", buffs.AMPLIFYING_POISON) and 
            API.CanCast(spells.AMPLIFYING_POISON)) then
            API.CastSpell(spells.AMPLIFYING_POISON)
            return true
        elseif not API.UnitHasBuff("player", buffs.AMPLIFYING_POISON) then
            local nonLethalPoisonToUse
            
            if settings.rotationSettings.nonLethalPoisonType == "Crippling Poison" and cripplingPoison then
                nonLethalPoisonToUse = spells.CRIPPLING_POISON
            elseif settings.rotationSettings.nonLethalPoisonType == "Numbing Poison" and numbingPoison then
                nonLethalPoisonToUse = spells.NUMBING_POISON
            elseif settings.rotationSettings.nonLethalPoisonType == "Atrophic Poison" and atrophicPoison then
                nonLethalPoisonToUse = spells.ATROPHIC_POISON
            end
            
            if nonLethalPoisonToUse and API.CanCast(nonLethalPoisonToUse) then
                API.CastSpell(nonLethalPoisonToUse)
                return true
            end
        end
    end
    
    -- Handle auto stealth when out of combat
    if settings.rotationSettings.autoStealth and 
       not API.IsInCombat() and 
       not inStealth and 
       API.CanCast(spells.STEALTH) then
        API.CastSpell(spells.STEALTH)
        return true
    end
    
    -- Skip if no valid target or not in range
    if not API.UnitExists("target") then
        return false
    end
    
    -- Handle interrupts
    if self:HandleInterrupts(settings) then
        return true
    end
    
    -- Handle defensive abilities
    if self:HandleDefensives(settings) then
        return true
    end
    
    -- Special Stealth Opener logic
    if inStealth or shadowDanceActive or subterfugeActive then
        return self:HandleStealthRotation(settings)
    end
    
    -- Get target GUID
    local targetGUID = API.GetTargetGUID()
    
    -- Slice and Dice maintenance
    if targetGUID and settings.finisherSettings.sliceAndDice and currentComboPoints >= settings.finisherSettings.sliceAndDiceComboPoints and 
       (not sliceAndDiceActive or (sliceAndDiceEndTime - GetTime() < settings.finisherSettings.sliceAndDiceRefreshThreshold)) and
       API.CanCast(spells.SLICE_AND_DICE) then
        API.CastSpell(spells.SLICE_AND_DICE)
        return true
    end
    
    -- Skip if not in melee range
    if not inMeleeRange then
        return false
    end
    
    -- Handle cooldowns first
    if self:HandleCooldowns(settings) then
        return true
    end
    
    -- Check for AoE or Single Target
    if settings.rotationSettings.aoeEnabled and currentAoETargets >= settings.rotationSettings.aoeThreshold then
        return self:HandleAoERotation(settings)
    else
        return self:HandleSingleTargetRotation(settings)
    end
end

-- Handle interrupts
function Assassination:HandleInterrupts(settings)
    -- Only interrupt if in range and setting is enabled
    if settings.utilitySettings.useKick and
       inMeleeRange and 
       API.CanCast(spells.KICK) and 
       API.TargetIsSpellCastable() then
        API.CastSpell(spells.KICK)
        return true
    end
    
    return false
end

-- Handle defensive abilities
function Assassination:HandleDefensives(settings)
    -- Use Cloak of Shadows against magic damage or debuffs
    if settings.defensiveSettings.useCloakOfShadows and
       API.CanCast(spells.CLOAK_OF_SHADOWS) then
        
        local shouldUseCloak = false
        
        if settings.defensiveSettings.cloakMode == "Against Magic Damage" and API.IsFacingMagicDamage() then
            shouldUseCloak = true
        elseif settings.defensiveSettings.cloakMode == "Against Debuffs" and API.HasDangerousDebuff() then
            shouldUseCloak = true
        end
        
        if shouldUseCloak then
            API.CastSpell(spells.CLOAK_OF_SHADOWS)
            return true
        end
    end
    
    -- Use Evasion against physical damage
    if settings.defensiveSettings.useEvasion and
       API.GetPlayerHealthPercent() <= settings.defensiveSettings.evasionThreshold and
       API.IsFacingPhysicalDamage() and
       API.CanCast(spells.EVASION) then
        API.CastSpell(spells.EVASION)
        return true
    end
    
    -- Use Feint to reduce AoE damage
    if settings.defensiveSettings.useFeint and
       API.CanCast(spells.FEINT) then
        
        local shouldUseFeint = false
        
        if settings.defensiveSettings.feintMode == "Before AoE Damage" and API.IsFacingAoEDamage() then
            shouldUseFeint = true
        elseif settings.defensiveSettings.feintMode == "On Cooldown" then
            shouldUseFeint = true
        end
        
        if shouldUseFeint then
            API.CastSpell(spells.FEINT)
            return true
        end
    end
    
    -- Use Crimson Vial for self-healing
    if settings.defensiveSettings.useCrimsonVial and
       API.GetPlayerHealthPercent() <= settings.defensiveSettings.crimsonVialThreshold and
       API.CanCast(spells.CRIMSON_VIAL) then
        API.CastSpell(spells.CRIMSON_VIAL)
        return true
    end
    
    return false
end

-- Handle cooldown abilities
function Assassination:HandleCooldowns(settings)
    -- Skip if not in combat
    if not API.IsInCombat() then
        return false
    end
    
    -- Get target GUID
    local targetGUID = API.GetTargetGUID()
    
    -- Use Vendetta
    if vendetta and
       settings.cooldownSettings.useVendetta and
       not vendettaActive and
       settings.abilityControls.vendetta.enabled and
       API.CanCast(spells.VENDETTA) then
        
        -- Check if should only use during burst
        if not settings.abilityControls.vendetta.useDuringBurstOnly or burstModeActive then
            -- Check additional requirements
            local shouldUseVendetta = false
            
            if settings.cooldownSettings.vendettaMode == "On Cooldown" then
                shouldUseVendetta = true
            elseif settings.cooldownSettings.vendettaMode == "With Toxic Blade" then
                shouldUseVendetta = toxicBladeActive
            elseif settings.cooldownSettings.vendettaMode == "Burst Only" then
                shouldUseVendetta = burstModeActive
            end
            
            if settings.abilityControls.vendetta.requireBleeds then
                shouldUseVendetta = shouldUseVendetta and 
                                   targetGUID and 
                                   ruptureActive[targetGUID] and 
                                   garroteActive[targetGUID]
            end
            
            if settings.abilityControls.vendetta.requireEnergy and currentEnergy < settings.abilityControls.vendetta.requireEnergy then
                shouldUseVendetta = false
            end
            
            if shouldUseVendetta then
                API.CastSpell(spells.VENDETTA)
                return true
            end
        end
    end
    
    -- Use Toxic Blade
    if toxicBlade and
       settings.cooldownSettings.useToxicBlade and
       API.CanCast(spells.TOXIC_BLADE) then
        
        local shouldUseToxicBlade = false
        
        if settings.cooldownSettings.toxicBladeMode == "On Cooldown" then
            shouldUseToxicBlade = true
        elseif settings.cooldownSettings.toxicBladeMode == "With Vendetta" then
            shouldUseToxicBlade = vendettaActive
        elseif settings.cooldownSettings.toxicBladeMode == "Burst Only" then
            shouldUseToxicBlade = burstModeActive
        end
        
        if shouldUseToxicBlade then
            API.CastSpell(spells.TOXIC_BLADE)
            return true
        end
    end
    
    -- Use Deathmark
    if deathmark and
       settings.cooldownSettings.useDeathmark and
       API.CanCast(spells.DEATHMARK) then
        
        local shouldUseDeathmark = false
        
        if settings.cooldownSettings.deathmarkMode == "On Cooldown" then
            shouldUseDeathmark = true
        elseif settings.cooldownSettings.deathmarkMode == "With Vendetta" then
            shouldUseDeathmark = vendettaActive
        elseif settings.cooldownSettings.deathmarkMode == "Burst Only" then
            shouldUseDeathmark = burstModeActive
        end
        
        if shouldUseDeathmark then
            API.CastSpell(spells.DEATHMARK)
            return true
        end
    end
    
    -- Use Kingsbane
    if kingsbane and
       settings.cooldownSettings.useKingsbane and
       API.CanCast(spells.KINGSBANE) then
        
        local shouldUseKingsbane = false
        
        if settings.cooldownSettings.kingsbaneMode == "On Cooldown" then
            shouldUseKingsbane = true
        elseif settings.cooldownSettings.kingsbaneMode == "With Vendetta" then
            shouldUseKingsbane = vendettaActive
        elseif settings.cooldownSettings.kingsbaneMode == "Burst Only" then
            shouldUseKingsbane = burstModeActive
        end
        
        if shouldUseKingsbane then
            API.CastSpell(spells.KINGSBANE)
            return true
        end
    end
    
    -- Use Exsanguinate
    if exsanguinate and
       settings.cooldownSettings.useExsanguinate and
       settings.abilityControls.exsanguinate.enabled and
       API.CanCast(spells.EXSANGUINATE) then
        
        -- Check additional requirements
        local shouldUseExsanguinate = false
        local targetGUID = API.GetTargetGUID()
        
        if settings.cooldownSettings.exsanguinateMode == "On Cooldown" then
            shouldUseExsanguinate = true
        elseif settings.cooldownSettings.exsanguinateMode == "With Vendetta" then
            shouldUseExsanguinate = vendettaActive
        elseif settings.cooldownSettings.exsanguinateMode == "After Bleeds Setup" then
            shouldUseExsanguinate = targetGUID and ruptureActive[targetGUID] and garroteActive[targetGUID]
        elseif settings.cooldownSettings.exsanguinateMode == "Burst Only" then
            shouldUseExsanguinate = burstModeActive
        end
        
        if settings.abilityControls.exsanguinate.requireBleedsOnTarget then
            shouldUseExsanguinate = shouldUseExsanguinate and
                                   targetGUID and
                                   ruptureActive[targetGUID]
                                   
            if settings.abilityControls.exsanguinate.requireBothBleeds then
                shouldUseExsanguinate = shouldUseExsanguinate and
                                       targetGUID and
                                       garroteActive[targetGUID]
            end
        end
        
        if shouldUseExsanguinate then
            API.CastSpell(spells.EXSANGUINATE)
            return true
        end
    end
    
    -- Use Vanish
    if settings.cooldownSettings.useVanish and
       settings.abilityControls.vanish.enabled and
       API.CanCast(spells.VANISH) then
        
        local shouldUseVanish = false
        
        if settings.cooldownSettings.vanishMode == "With Vendetta" then
            shouldUseVanish = vendettaActive
        elseif settings.cooldownSettings.vanishMode == "For Garrote" then
            shouldUseVanish = settings.abilityControls.vanish.useForGarrote
        elseif settings.cooldownSettings.vanishMode == "For Ambush" then
            shouldUseVanish = settings.abilityControls.vanish.useForAmbush
        elseif settings.cooldownSettings.vanishMode == "Burst Only" then
            shouldUseVanish = burstModeActive
        end
        
        if shouldUseVanish then
            API.CastSpell(spells.VANISH)
            return true
        end
    end
    
    -- Use Shadow Dance
    if settings.cooldownSettings.useShadowDance and
       API.CanCast(spells.SHADOW_DANCE) then
        
        local shouldUseShadowDance = false
        
        if settings.cooldownSettings.shadowDanceMode == "On Cooldown" then
            shouldUseShadowDance = true
        elseif settings.cooldownSettings.shadowDanceMode == "For Garrote" then
            shouldUseShadowDance = true -- We'll use it for garrote in the stealth rotation
        elseif settings.cooldownSettings.shadowDanceMode == "With Vendetta" then
            shouldUseShadowDance = vendettaActive
        elseif settings.cooldownSettings.shadowDanceMode == "Burst Only" then
            shouldUseShadowDance = burstModeActive
        end
        
        if shouldUseShadowDance then
            API.CastSpell(spells.SHADOW_DANCE)
            return true
        end
    end
    
    -- Use Sepsis
    if sepsis and
       settings.cooldownSettings.useSepsis and
       API.CanCast(spells.SEPSIS) then
        
        local shouldUseSepsis = false
        
        if settings.cooldownSettings.sepsisMode == "On Cooldown" then
            shouldUseSepsis = true
        elseif settings.cooldownSettings.sepsisMode == "With Vendetta" then
            shouldUseSepsis = vendettaActive
        elseif settings.cooldownSettings.sepsisMode == "Burst Only" then
            shouldUseSepsis = burstModeActive
        end
        
        if shouldUseSepsis then
            API.CastSpell(spells.SEPSIS)
            return true
        end
    end
    
    return false
end

-- Handle actions while in stealth
function Assassination:HandleStealthRotation(settings)
    -- Get target GUID
    local targetGUID = API.GetTargetGUID()
    
    -- Skip if no target or not in melee range
    if not targetGUID or not inMeleeRange then
        return false
    end
    
    -- Use Garrote from stealth (this is high priority in stealth since it deals extra damage and lasts longer)
    if garrote and
       settings.bleedSettings.useGarrote and
       (not garroteActive[targetGUID] or 
        (garroteActive[targetGUID] and 
         garroteEndTime[targetGUID] - GetTime() < settings.bleedSettings.garroteRefreshThreshold)) and
       API.CanCast(spells.GARROTE) then
        API.CastSpell(spells.GARROTE)
        return true
    end
    
    -- Use Rupture from stealth if needed and Garrote is already active
    if rupture and
       settings.bleedSettings.useRupture and
       garroteActive[targetGUID] and
       currentComboPoints >= settings.bleedSettings.ruptureComboPoints and
       (not ruptureActive[targetGUID] || 
        (ruptureActive[targetGUID] and 
         ruptureEndTime[targetGUID] - GetTime() < settings.bleedSettings.ruptureRefreshThreshold)) and
       API.CanCast(spells.RUPTURE) then
        API.CastSpell(spells.RUPTURE)
        return true
    end
    
    -- Use Ambush from stealth if not using Garrote or Rupture
    if API.CanCast(spells.AMBUSH) then
        API.CastSpell(spells.AMBUSH)
        return true
    end
    
    return false
end

-- Handle AoE rotation
function Assassination:HandleAoERotation(settings)
    -- Get target GUID
    local targetGUID = API.GetTargetGUID()
    
    -- Use Fan of Knives to generate combo points in AoE
    if currentComboPoints < maxComboPoints and
       API.CanCast(spells.FAN_OF_KNIVES) then
        API.CastSpell(spells.FAN_OF_KNIVES)
        return true
    end
    
    -- Apply and maintain Rupture on primary target
    if rupture and
       settings.bleedSettings.useRupture and
       targetGUID and
       currentComboPoints >= settings.bleedSettings.ruptureComboPoints and
       (not ruptureActive[targetGUID] || 
        (ruptureActive[targetGUID] and 
         ruptureEndTime[targetGUID] - GetTime() < settings.bleedSettings.ruptureRefreshThreshold)) and
       API.CanCast(spells.RUPTURE) then
        API.CastSpell(spells.RUPTURE)
        return true
    end
    
    -- Use Crimson Tempest as AoE finisher
    if crimsonTempest and
       settings.bleedSettings.useCrimsonTempest and
       currentAoETargets >= settings.bleedSettings.crimsonTempestMinTargets and
       currentComboPoints >= settings.bleedSettings.crimsonTempestComboPoints and
       API.CanCast(spells.CRIMSON_TEMPEST) then
        API.CastSpell(spells.CRIMSON_TEMPEST)
        return true
    end
    
    -- Use Envenom as a finisher
    if settings.finisherSettings.envenom and
       currentComboPoints >= settings.finisherSettings.envenomComboPoints and
       API.CanCast(spells.ENVENOM) then
        API.CastSpell(spells.ENVENOM)
        return true
    end
    
    -- Use Fan of Knives again as a filler
    if API.CanCast(spells.FAN_OF_KNIVES) then
        API.CastSpell(spells.FAN_OF_KNIVES)
        return true
    end
    
    return false
end

-- Handle Single Target rotation
function Assassination:HandleSingleTargetRotation(settings)
    -- Get target GUID
    local targetGUID = API.GetTargetGUID()
    
    -- Apply and maintain Garrote
    if garrote and
       settings.bleedSettings.useGarrote and
       (not garroteActive[targetGUID] || 
        (garroteActive[targetGUID] and 
         garroteEndTime[targetGUID] - GetTime() < settings.bleedSettings.garroteRefreshThreshold)) and
       API.CanCast(spells.GARROTE) then
        API.CastSpell(spells.GARROTE)
        return true
    end
    
    -- Apply and maintain Rupture
    if rupture and
       settings.bleedSettings.useRupture and
       currentComboPoints >= settings.bleedSettings.ruptureComboPoints and
       (not ruptureActive[targetGUID] || 
        (ruptureActive[targetGUID] and 
         ruptureEndTime[targetGUID] - GetTime() < settings.bleedSettings.ruptureRefreshThreshold)) and
       API.CanCast(spells.RUPTURE) then
        API.CastSpell(spells.RUPTURE)
        return true
    end
    
    -- Use Blindside procs
    if blindside and
       blindsideActive and
       API.CanCast(spells.AMBUSH) then
        API.CastSpell(spells.AMBUSH)
        return true
    end
    
    -- Use Envenom as a finisher
    if settings.finisherSettings.envenom and
       currentComboPoints >= settings.finisherSettings.envenomComboPoints and
       ruptureActive[targetGUID] and -- Make sure Rupture is active before spending combo points on Envenom
       API.CanCast(spells.ENVENOM) then
        API.CastSpell(spells.ENVENOM)
        return true
    end
    
    -- Use Mutilate as a builder
    if mutilate and
       currentComboPoints < maxComboPoints and
       API.CanCast(spells.MUTILATE) then
        
        -- Check for energy pooling
        if not settings.rotationSettings.energyPooling or 
           currentEnergy >= settings.rotationSettings.energyPoolingThreshold or
           currentComboPoints == 0 then
            API.CastSpell(spells.MUTILATE)
            return true
        end
    end
    
    return false
end

-- Handle specialization change
function Assassination:OnSpecializationChanged()
    -- Update talent information
    self:UpdateTalentInfo()
    
    -- Reset state variables
    nextCastOverride = nil
    burstModeActive = false
    currentAoETargets = 0
    currentEnergy = 0
    maxEnergy = 100
    currentComboPoints = 0
    maxComboPoints = 5
    sliceAndDiceActive = false
    sliceAndDiceEndTime = 0
    shadowDanceActive = false
    shadowDanceEndTime = 0
    vanishActive = false
    vanishEndTime = 0
    subterfugeActive = false
    subterfugeEndTime = 0
    envenom = false
    envenomEndTime = 0
    blindsideActive = false
    blindsideEndTime = 0
    ruptureActive = {}
    ruptureEndTime = {}
    garroteActive = {}
    garroteEndTime = {}
    cripplingPoisonActive = {}
    cripplingPoisonEndTime = {}
    deadlyPoisonActive = {}
    deadlyPoisonEndTime = {}
    internalBleedingActive = {}
    internalBleedingEndTime = {}
    toxicBladeActive = false
    toxicBladeEndTime = 0
    deathmarkActive = false
    deathmarkEndTime = 0
    septicShockActive = {}
    septicShockEndTime = {}
    crimsonTemptestActive = {}
    crimsonTemptestEndTime = {}
    kingsbaneActive = {}
    kingsbaneEndTime = {}
    indiscriminateCarnageActive = false
    indiscriminateCarnageEndTime = 0
    stealth = false
    vendettaActive = false
    vendettaEndTime = 0
    exsanguinateActive = {}
    exsanguinateEndTime = {}
    sharpenedBladesDamage = 0
    improved = false
    numPoisons = 0
    sealFateProcs = 0
    masterAssassinStreak = 0
    lastGarrote = 0
    lastRupture = 0
    lastVendetta = 0
    lastMutilate = 0
    lastEnvenom = 0
    finisherUsed = false
    finisherBaseDamage = 0
    targetHealth = 100
    inStealth = false
    inMeleeRange = false
    ambushActive = false
    mutilate = false
    garrote = false
    rupture = false
    deadlyPoison = false
    cripplingPoison = false
    instantPoison = false
    woundPoison = false
    numbingPoison = false
    atrophicPoison = false
    crimsonTempest = false
    toxicBlade = false
    blindside = false
    masterAssassin = false
    impliedFate = false
    exsanguinate = false
    kingsbane = false
    vendetta = false
    deathmark = false
    septicShock = false
    improvedGarrote = false
    shroudedSuffocation = false
    amplifyingPoison = false
    lethalPoison = false
    nonLethalPoison = false
    indiscriminateCarnage = false
    acrobaticStrikes = false
    sealFate = false
    deeperDaggers = false
    echoingReprimand = false
    cripplingPrisonActive = false
    cripplingPrisonEndTime = 0
    indiscriminateCarnageProcs = 0
    masterPoisoner = false
    dreadblade = false
    goremaw = false
    sepsis = false
    
    -- Check stealth state
    self:UpdateStealthState()
    
    API.PrintDebug("Assassination Rogue state reset on spec change")
    
    return true
end

-- Return the module for loading
return Assassination