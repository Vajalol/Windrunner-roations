------------------------------------------
-- WindrunnerRotations - Outlaw Rogue Module
-- Author: VortexQ8
-- The War Within Season 2
------------------------------------------

local Outlaw = {}
-- This will be assigned to addon.Classes.Rogue.Outlaw when loaded

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
local rolltheBonesActive = false
local rolltheBonesEndTime = 0
local adrenalineRushActive = false
local adrenalineRushEndTime = 0
local broadsidesActive = false
local broadsidesEndTime = 0
local buriedTreasureActive = false
local buriedTreasureEndTime = 0
local grandMeleeActive = false
local grandMeleeEndTime = 0
local ruthlessPrecisionActive = false
local ruthlessPrecisionEndTime = 0
local skullAndCrossbonesActive = false
local skullAndCrossbonesEndTime = 0
local trueBearingActive = false
local trueBearingEndTime = 0
local numbOfBuffs = 0
local betweenTheEyesReady = false
local opportunityActive = false
local opportunityEndTime = 0
local deadShotReady = false
local keepYourWitsActive = false
local ghostlyStrikeActive = {}
local ghostlyStrikeEndTime = {}
local echoingReprimandActive = false
local echoingReprimandEndTime = 0
local echoingReprimandPoints = 0
local bladeFlurryActive = false
local bladeFlurryEndTime = 0
local countTheOddsActive = false
local countTheOddsEndTime = 0
local killingSpreeActive = false
local killingSpreeEndTime = 0
local dreadbladeActive = false
local dreadbladeEndTime = 0
local hiddenOpportunity = false
local hiddenOpportunityProcs = 0
local lastRollTheBones = 0
local lastDispatch = 0
local lastAdrenalineRush = 0
local lastPistolShot = 0
local lastSinisterStrike = 0
local pistolShot = false
local sinisterStrike = false
local bladeFlurry = false
local betweenTheEyes = false
local rollTheBones = false
local dispatch = false
local adrenalineRush = false
local killingSpree = false
local dreadblade = false
local keepYourWits = false
local ghostlyStrike = false
local echoingReprimand = false
local subtlety = false
local ambushActive = false
local acrobaticStrikes = false
local sealFate = false
local deeperDaggers = false
local quickDraw = false
local retractable = false
local fateOfTheBold = false
local subterfugeTalent = false
local fantaSea = false
local combatPotency = false
local weaponFinesse = false
local weaponMaster = false
local findWeakness = false
local sepsis = false
local inStealth = false
local inMeleeRange = false
local targetHealth = 100
local cripplingPoison = false
local instantPoison = false
local woundPoison = false
local numbingPoison = false
local atrophicPoison = false
local lastRTBBuffs = 0
local finishingMove = false

-- Constants
local OUTLAW_SPEC_ID = 260
local DEFAULT_AOE_THRESHOLD = 3
local SLICE_AND_DICE_DURATION = 30 -- seconds (base, can be extended)
local SHADOW_DANCE_DURATION = 8 -- seconds (base)
local VANISH_DURATION = 3 -- seconds (stealth duration)
local SUBTERFUGE_DURATION = 3 -- seconds
local ROLL_THE_BONES_DURATION = 30 -- seconds (base)
local ADRENALINE_RUSH_DURATION = 20 -- seconds (base)
local BROADSIDES_DURATION = 30 -- seconds
local BURIED_TREASURE_DURATION = 30 -- seconds
local GRAND_MELEE_DURATION = 30 -- seconds
local RUTHLESS_PRECISION_DURATION = 30 -- seconds
local SKULL_AND_CROSSBONES_DURATION = 30 -- seconds
local TRUE_BEARING_DURATION = 30 -- seconds
local OPPORTUNITY_DURATION = 10 -- seconds
local GHOSTLY_STRIKE_DURATION = 10 -- seconds
local ECHOING_REPRIMAND_DURATION = 12 -- seconds
local BLADE_FLURRY_DURATION = 12 -- seconds (base)
local COUNT_THE_ODDS_DURATION = 12 -- seconds
local KILLING_SPREE_DURATION = 2 -- seconds
local DREADBLADE_DURATION = 12 -- seconds
local MELEE_RANGE = 5 -- yards
local ACROBATIC_STRIKES_RANGE = 3 -- additional yards

-- Initialize the Outlaw module
function Outlaw:Initialize()
    self:RegisterSpells()
    self:RegisterVariables()
    self:RegisterSettings()
    self:RegisterEvents()
    
    API.PrintDebug("Outlaw Rogue module initialized")
    
    return true
end

-- Register spell IDs
function Outlaw:RegisterSpells()
    -- Core rotational abilities
    spells.SINISTER_STRIKE = 193315
    spells.PISTOL_SHOT = 185763
    spells.DISPATCH = 2098
    spells.BETWEEN_THE_EYES = 315341
    spells.ROLL_THE_BONES = 315508
    spells.SLICE_AND_DICE = 315496
    spells.BLADE_FLURRY = 13877
    spells.ADRENALINE_RUSH = 13750
    spells.KILLING_SPREE = 51690
    spells.AMBUSH = 8676
    spells.GHOSTLY_STRIKE = 196937
    spells.DREADBLADES = 343142
    spells.GRAPPLING_HOOK = 195457
    
    -- Core utilities
    spells.VANISH = 1856
    spells.SHADOW_DANCE = 185313
    spells.DISTRACT = 1725
    spells.PICK_POCKET = 921
    spells.FEINT = 1966
    spells.EVASION = 5277
    spells.CLOAK_OF_SHADOWS = 31224
    spells.SPRINT = 2983
    spells.SHROUD_OF_CONCEALMENT = 114018
    spells.TRICKS_OF_THE_TRADE = 57934
    spells.STEALTH = 1784
    spells.BLIND = 2094
    spells.KIDNEY_SHOT = 408
    spells.SAP = 6770
    spells.CHEAP_SHOT = 1833
    spells.CRIMSON_VIAL = 185311
    spells.KICK = 1766
    spells.GOUGE = 1776
    
    -- Poisons
    spells.CRIPPLING_POISON = 3408
    spells.INSTANT_POISON = 315584
    spells.WOUND_POISON = 8679
    spells.NUMBING_POISON = 5761
    spells.ATROPHIC_POISON = 381637
    
    -- Talents and passives
    spells.RESTLESS_BLADES = 79096
    spells.COMBAT_POTENCY = 61329
    spells.OPPORTUNITY = 279876
    spells.GHOSTLY_STRIKE = 196937
    spells.BLADE_RUSH = 271877
    spells.ECHOING_REPRIMAND = 385616
    spells.ACROBATIC_STRIKES = 196924
    spells.WEAPONMASTER = 200733
    spells.BLADE_DANCER = 396734
    spells.IMPROVED_ADRENALINE_RUSH = 395422
    spells.IMPROVED_BETWEEN_THE_EYES = 235484
    spells.KEEP_IT_ROLLING = 381989
    spells.QUICK_DRAW = 196938
    spells.LOADED_DICE = 256170
    spells.SUBTERFUGE = 108208
    spells.FIND_WEAKNESS = 91023
    spells.WEAPON_FINESSE = 389819
    spells.SEAL_FATE = 14190
    spells.DEEPER_DAGGERS = 382371
    spells.RETRACTABLE_HOOK = 256188
    spells.FLEET_FOOTED = 378813
    spells.IMPROVED_AMBUSH = 381620
    spells.THISTLE_TEA = 381623
    spells.CHEAT_DEATH = 31230
    spells.LEECHING_POISON = 280716
    spells.IRON_STOMACH = 193546
    spells.NIMBLE_FINGERS = 378427
    spells.PREY_ON_THE_WEAK = 131511
    spells.SHOTGUN_COMBO = 400857
    spells.SEPSIS = 385408
    spells.SHADOW_DANCE = 185313
    spells.COLD_BLOOD = 382245
    
    -- War Within Season 2 specific
    spells.FATE_OF_THE_BOLD = 383281
    spells.TURN_THE_TABLES = 424049
    spells.BLAST_FROM_THE_PAST = 424653
    spells.HIDDEN_OPPORTUNITY = 383208
    spells.COUNT_THE_ODDS = 381982
    spells.FANTA_SEA = 381967
    
    -- Buff IDs
    spells.SLICE_AND_DICE_BUFF = 315496
    spells.SHADOW_DANCE_BUFF = 185422
    spells.VANISH_BUFF = 11327
    spells.SUBTERFUGE_BUFF = 115192
    spells.ROLL_THE_BONES_BUFF = 315508
    spells.ADRENALINE_RUSH_BUFF = 13750
    spells.BROADSIDES_BUFF = 193356
    spells.BURIED_TREASURE_BUFF = 199600
    spells.GRAND_MELEE_BUFF = 193358
    spells.RUTHLESS_PRECISION_BUFF = 193357
    spells.SKULL_AND_CROSSBONES_BUFF = 199603
    spells.TRUE_BEARING_BUFF = 193359
    spells.OPPORTUNITY_BUFF = 195627
    spells.BETWEEN_THE_EYES_BUFF = 315341
    spells.STEALTH_BUFF = 1784
    spells.BLADE_FLURRY_BUFF = 13877
    spells.COUNT_THE_ODDS_BUFF = 381982
    spells.KILLING_SPREE_BUFF = 51690
    spells.DREADBLADES_BUFF = 343142
    spells.KEEP_YOUR_WITS_BUFF = 338140
    
    -- Debuff IDs
    spells.GHOSTLY_STRIKE_DEBUFF = 196937
    spells.CRIPPLING_POISON_DEBUFF = 3409
    spells.WOUND_POISON_DEBUFF = 8680
    spells.NUMBING_POISON_DEBUFF = 5760
    spells.ATROPHIC_POISON_DEBUFF = 381637
    spells.INSTANT_POISON_DEBUFF = 315585
    spells.SEPSIS_DEBUFF = 385408
    
    -- Register all spells with the API tracking system
    for spellName, spellID in pairs(spells) do
        API.RegisterSpell(spellID)
    end
    
    -- Define aura tracking
    buffs.SLICE_AND_DICE = spells.SLICE_AND_DICE_BUFF
    buffs.SHADOW_DANCE = spells.SHADOW_DANCE_BUFF
    buffs.VANISH = spells.VANISH_BUFF
    buffs.SUBTERFUGE = spells.SUBTERFUGE_BUFF
    buffs.ROLL_THE_BONES = spells.ROLL_THE_BONES_BUFF
    buffs.ADRENALINE_RUSH = spells.ADRENALINE_RUSH_BUFF
    buffs.BROADSIDES = spells.BROADSIDES_BUFF
    buffs.BURIED_TREASURE = spells.BURIED_TREASURE_BUFF
    buffs.GRAND_MELEE = spells.GRAND_MELEE_BUFF
    buffs.RUTHLESS_PRECISION = spells.RUTHLESS_PRECISION_BUFF
    buffs.SKULL_AND_CROSSBONES = spells.SKULL_AND_CROSSBONES_BUFF
    buffs.TRUE_BEARING = spells.TRUE_BEARING_BUFF
    buffs.OPPORTUNITY = spells.OPPORTUNITY_BUFF
    buffs.BETWEEN_THE_EYES = spells.BETWEEN_THE_EYES_BUFF
    buffs.STEALTH = spells.STEALTH_BUFF
    buffs.BLADE_FLURRY = spells.BLADE_FLURRY_BUFF
    buffs.COUNT_THE_ODDS = spells.COUNT_THE_ODDS_BUFF
    buffs.KILLING_SPREE = spells.KILLING_SPREE_BUFF
    buffs.DREADBLADES = spells.DREADBLADES_BUFF
    buffs.KEEP_YOUR_WITS = spells.KEEP_YOUR_WITS_BUFF
    
    debuffs.GHOSTLY_STRIKE = spells.GHOSTLY_STRIKE_DEBUFF
    debuffs.CRIPPLING_POISON = spells.CRIPPLING_POISON_DEBUFF
    debuffs.WOUND_POISON = spells.WOUND_POISON_DEBUFF
    debuffs.NUMBING_POISON = spells.NUMBING_POISON_DEBUFF
    debuffs.ATROPHIC_POISON = spells.ATROPHIC_POISON_DEBUFF
    debuffs.INSTANT_POISON = spells.INSTANT_POISON_DEBUFF
    debuffs.SEPSIS = spells.SEPSIS_DEBUFF
    
    return true
end

-- Register variables to track
function Outlaw:RegisterVariables()
    -- Talent tracking
    talents.hasRestlessBlades = false
    talents.hasCombatPotency = false
    talents.hasOpportunity = false
    talents.hasGhostlyStrike = false
    talents.hasBladeRush = false
    talents.hasEchoingReprimand = false
    talents.hasAcrobaticStrikes = false
    talents.hasWeaponmaster = false
    talents.hasBladeDancer = false
    talents.hasImprovedAdrenalineRush = false
    talents.hasImprovedBetweenTheEyes = false
    talents.hasKeepItRolling = false
    talents.hasQuickDraw = false
    talents.hasLoadedDice = false
    talents.hasSubterfuge = false
    talents.hasFindWeakness = false
    talents.hasWeaponFinesse = false
    talents.hasSealFate = false
    talents.hasDeeperDaggers = false
    talents.hasRetractableHook = false
    talents.hasFleetFooted = false
    talents.hasImprovedAmbush = false
    talents.hasThistleTea = false
    talents.hasCheatDeath = false
    talents.hasLeechingPoison = false
    talents.hasIronStomach = false
    talents.hasNimbleFingers = false
    talents.hasPreyOnTheWeak = false
    talents.hasShotgunCombo = false
    talents.hasSepsis = false
    talents.hasShadowDance = false
    talents.hasColdBlood = false
    talents.hasDreadblades = false
    talents.hasKillingSpree = false
    
    -- War Within Season 2 talents
    talents.hasFateOfTheBold = false
    talents.hasTurnTheTables = false
    talents.hasBlastFromThePast = false
    talents.hasHiddenOpportunity = false
    talents.hasCountTheOdds = false
    talents.hasFantaSea = false
    
    -- Initialize energy and combo points
    currentEnergy = API.GetPlayerPower()
    maxEnergy = API.GetPlayerMaxPower()
    currentComboPoints = API.GetPlayerComboPoints()
    maxComboPoints = 5 -- Default, could be 6 with Deeper Stratagem
    
    -- Check if in stealth
    inStealth = API.IsStealthed()
    
    -- Initialize tracking tables
    ghostlyStrikeActive = {}
    ghostlyStrikeEndTime = {}
    
    return true
end

-- Register spec-specific settings
function Outlaw:RegisterSettings()
    ConfigRegistry:RegisterSettings("OutlawRogue", {
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
            autoStealth = {
                displayName = "Auto Stealth",
                description = "Automatically use Stealth when out of combat",
                type = "toggle",
                default = true
            },
            poisonType = {
                displayName = "Poison Type",
                description = "Which poison to use",
                type = "dropdown",
                options = {"Instant Poison", "Wound Poison", "Crippling Poison", "Numbing Poison", "Atrophic Poison"},
                default = "Instant Poison"
            },
            rollTheBonesStrategy = {
                displayName = "Roll the Bones Strategy",
                description = "How to handle Roll the Bones buffs",
                type = "dropdown",
                options = {"2+ Buffs", "True Bearing", "Any 2 Buffs", "Specific Buffs", "1+ Buffs"},
                default = "2+ Buffs"
            },
            specificBuffs = {
                displayName = "Specific RtB Buffs",
                description = "Which specific Roll the Bones buffs to look for",
                type = "multiselect",
                options = {"Broadside", "Buried Treasure", "Grand Melee", "Ruthless Precision", "Skull & Crossbones", "True Bearing"},
                default = {"Broadside", "Buried Treasure", "True Bearing"}
            }
        },
        
        finisherSettings = {
            useDispatch = {
                displayName = "Use Dispatch",
                description = "Automatically use Dispatch as a finisher",
                type = "toggle",
                default = true
            },
            dispatchComboPoints = {
                displayName = "Dispatch Combo Points",
                description = "Minimum combo points to use Dispatch",
                type = "slider",
                min = 1,
                max = 6,
                default = 5
            },
            useBetweenTheEyes = {
                displayName = "Use Between the Eyes",
                description = "Automatically use Between the Eyes",
                type = "toggle",
                default = true
            },
            betweenTheEyesComboPoints = {
                displayName = "Between the Eyes Combo Points",
                description = "Minimum combo points to use Between the Eyes",
                type = "slider",
                min = 1,
                max = 6,
                default = 5
            },
            useSliceAndDice = {
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
                default = 5
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
                options = {"Slice and Dice > Between the Eyes > Dispatch", "Between the Eyes > Slice and Dice > Dispatch", "Balanced"},
                default = "Slice and Dice > Between the Eyes > Dispatch"
            }
        },
        
        cooldownSettings = {
            useAdrenalineRush = {
                displayName = "Use Adrenaline Rush",
                description = "Automatically use Adrenaline Rush",
                type = "toggle",
                default = true
            },
            adrenalineRushMode = {
                displayName = "Adrenaline Rush Usage",
                description = "When to use Adrenaline Rush",
                type = "dropdown",
                options = {"On Cooldown", "With Roll the Bones", "Burst Only"},
                default = "On Cooldown"
            },
            useBladeFlurry = {
                displayName = "Use Blade Flurry",
                description = "Automatically use Blade Flurry for AoE",
                type = "toggle",
                default = true
            },
            bladeFlurryTargets = {
                displayName = "Blade Flurry Targets",
                description = "Minimum targets to use Blade Flurry",
                type = "slider",
                min = 2,
                max = 8,
                default = 2
            },
            useDreadblades = {
                displayName = "Use Dreadblades",
                description = "Automatically use Dreadblades when talented",
                type = "toggle",
                default = true
            },
            dreadbladesMode = {
                displayName = "Dreadblades Usage",
                description = "When to use Dreadblades",
                type = "dropdown",
                options = {"On Cooldown", "With Adrenaline Rush", "Burst Only"},
                default = "With Adrenaline Rush"
            },
            useKillingSpree = {
                displayName = "Use Killing Spree",
                description = "Automatically use Killing Spree when talented",
                type = "toggle",
                default = true
            },
            killingSpreeMode = {
                displayName = "Killing Spree Usage",
                description = "When to use Killing Spree",
                type = "dropdown",
                options = {"On Cooldown", "With Adrenaline Rush", "Low Energy Only", "Burst Only"},
                default = "On Cooldown"
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
                options = {"With Adrenaline Rush", "For Ambush", "Burst Only", "Manual Only"},
                default = "With Adrenaline Rush"
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
                options = {"On Cooldown", "For Ambush", "With Adrenaline Rush", "Burst Only"},
                default = "For Ambush"
            },
            useKeepItRolling = {
                displayName = "Use Keep It Rolling",
                description = "Automatically use Keep It Rolling when talented",
                type = "toggle",
                default = true
            },
            useGhostlyStrike = {
                displayName = "Use Ghostly Strike",
                description = "Automatically use Ghostly Strike when talented",
                type = "toggle",
                default = true
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
                options = {"On Cooldown", "With Adrenaline Rush", "Burst Only"},
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
            useGouge = {
                displayName = "Use Gouge",
                description = "Automatically use Gouge for crowd control",
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
            useGrapplingHook = {
                displayName = "Use Grappling Hook",
                description = "Automatically use Grappling Hook",
                type = "toggle",
                default = false
            }
        },
        
        -- Advanced ability control settings
        abilityControls = {
            -- Adrenaline Rush controls
            adrenalineRush = AAC.RegisterAbility(spells.ADRENALINE_RUSH, {
                enabled = true,
                useDuringBurstOnly = false,
                requireEnergy = 50,
                requireGoodRtBBuffs = false
            }),
            
            -- Roll the Bones controls
            rollTheBones = AAC.RegisterAbility(spells.ROLL_THE_BONES, {
                enabled = true,
                useDuringBurstOnly = false,
                alwaysRollWithLoadedDice = true,
                minimumBuffCount = 2
            }),
            
            -- Blade Flurry controls
            bladeFlurry = AAC.RegisterAbility(spells.BLADE_FLURRY, {
                enabled = true,
                useDuringBurstOnly = false,
                reserveWithAdrenalineRush = true,
                minimumTargets = 2
            })
        }
    })
    
    return true
end

-- Register for events 
function Outlaw:RegisterEvents()
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
    
    -- Register for aura updates to track Roll the Bones buffs
    API.RegisterEvent("UNIT_AURA", function(unit)
        if unit == "player" then
            self:UpdateRollTheBones()
        end
    end)
    
    -- Initial talent info update
    self:UpdateTalentInfo()
    
    -- Initial stealth check
    self:UpdateStealthState()
    
    -- Initial Roll the Bones check
    self:UpdateRollTheBones()
    
    return true
end

-- Update talent information
function Outlaw:UpdateTalentInfo()
    -- Check for important talents
    talents.hasRestlessBlades = API.HasTalent(spells.RESTLESS_BLADES)
    talents.hasCombatPotency = API.HasTalent(spells.COMBAT_POTENCY)
    talents.hasOpportunity = API.HasTalent(spells.OPPORTUNITY)
    talents.hasGhostlyStrike = API.HasTalent(spells.GHOSTLY_STRIKE)
    talents.hasBladeRush = API.HasTalent(spells.BLADE_RUSH)
    talents.hasEchoingReprimand = API.HasTalent(spells.ECHOING_REPRIMAND)
    talents.hasAcrobaticStrikes = API.HasTalent(spells.ACROBATIC_STRIKES)
    talents.hasWeaponmaster = API.HasTalent(spells.WEAPONMASTER)
    talents.hasBladeDancer = API.HasTalent(spells.BLADE_DANCER)
    talents.hasImprovedAdrenalineRush = API.HasTalent(spells.IMPROVED_ADRENALINE_RUSH)
    talents.hasImprovedBetweenTheEyes = API.HasTalent(spells.IMPROVED_BETWEEN_THE_EYES)
    talents.hasKeepItRolling = API.HasTalent(spells.KEEP_IT_ROLLING)
    talents.hasQuickDraw = API.HasTalent(spells.QUICK_DRAW)
    talents.hasLoadedDice = API.HasTalent(spells.LOADED_DICE)
    talents.hasSubterfuge = API.HasTalent(spells.SUBTERFUGE)
    talents.hasFindWeakness = API.HasTalent(spells.FIND_WEAKNESS)
    talents.hasWeaponFinesse = API.HasTalent(spells.WEAPON_FINESSE)
    talents.hasSealFate = API.HasTalent(spells.SEAL_FATE)
    talents.hasDeeperDaggers = API.HasTalent(spells.DEEPER_DAGGERS)
    talents.hasRetractableHook = API.HasTalent(spells.RETRACTABLE_HOOK)
    talents.hasFleetFooted = API.HasTalent(spells.FLEET_FOOTED)
    talents.hasImprovedAmbush = API.HasTalent(spells.IMPROVED_AMBUSH)
    talents.hasThistleTea = API.HasTalent(spells.THISTLE_TEA)
    talents.hasCheatDeath = API.HasTalent(spells.CHEAT_DEATH)
    talents.hasLeechingPoison = API.HasTalent(spells.LEECHING_POISON)
    talents.hasIronStomach = API.HasTalent(spells.IRON_STOMACH)
    talents.hasNimbleFingers = API.HasTalent(spells.NIMBLE_FINGERS)
    talents.hasPreyOnTheWeak = API.HasTalent(spells.PREY_ON_THE_WEAK)
    talents.hasShotgunCombo = API.HasTalent(spells.SHOTGUN_COMBO)
    talents.hasSepsis = API.HasTalent(spells.SEPSIS)
    talents.hasShadowDance = API.HasTalent(spells.SHADOW_DANCE)
    talents.hasColdBlood = API.HasTalent(spells.COLD_BLOOD)
    talents.hasDreadblades = API.HasTalent(spells.DREADBLADES)
    talents.hasKillingSpree = API.HasTalent(spells.KILLING_SPREE)
    
    -- War Within Season 2 talents
    talents.hasFateOfTheBold = API.HasTalent(spells.FATE_OF_THE_BOLD)
    talents.hasTurnTheTables = API.HasTalent(spells.TURN_THE_TABLES)
    talents.hasBlastFromThePast = API.HasTalent(spells.BLAST_FROM_THE_PAST)
    talents.hasHiddenOpportunity = API.HasTalent(spells.HIDDEN_OPPORTUNITY)
    talents.hasCountTheOdds = API.HasTalent(spells.COUNT_THE_ODDS)
    talents.hasFantaSea = API.HasTalent(spells.FANTA_SEA)
    
    -- Adjust max combo points based on talents
    if talents.hasDeeperDaggers then
        maxComboPoints = 6
    else
        maxComboPoints = 5
    end
    
    -- Set specialized variables based on talents
    if API.IsSpellKnown(spells.PISTOL_SHOT) then
        pistolShot = true
    end
    
    if API.IsSpellKnown(spells.SINISTER_STRIKE) then
        sinisterStrike = true
    end
    
    if API.IsSpellKnown(spells.BLADE_FLURRY) then
        bladeFlurry = true
    end
    
    if API.IsSpellKnown(spells.BETWEEN_THE_EYES) then
        betweenTheEyes = true
    end
    
    if API.IsSpellKnown(spells.ROLL_THE_BONES) then
        rollTheBones = true
    end
    
    if API.IsSpellKnown(spells.DISPATCH) then
        dispatch = true
    end
    
    if API.IsSpellKnown(spells.ADRENALINE_RUSH) then
        adrenalineRush = true
    end
    
    if talents.hasKillingSpree then
        killingSpree = true
    end
    
    if talents.hasDreadblades then
        dreadblade = true
    end
    
    if talents.hasKeepItRolling then
        keepYourWits = true
    end
    
    if talents.hasGhostlyStrike then
        ghostlyStrike = true
    end
    
    if talents.hasEchoingReprimand then
        echoingReprimand = true
    end
    
    if talents.hasSubterfuge then
        subterfugeTalent = true
    end
    
    if talents.hasAcrobaticStrikes then
        acrobaticStrikes = true
    end
    
    if talents.hasSealFate then
        sealFate = true
    end
    
    if talents.hasDeeperDaggers then
        deeperDaggers = true
    end
    
    if talents.hasQuickDraw then
        quickDraw = true
    end
    
    if talents.hasRetractableHook then
        retractable = true
    end
    
    if talents.hasFateOfTheBold then
        fateOfTheBold = true
    end
    
    if talents.hasFantaSea then
        fantaSea = true
    end
    
    if talents.hasCombatPotency then
        combatPotency = true
    end
    
    if talents.hasWeaponFinesse then
        weaponFinesse = true
    end
    
    if talents.hasWeaponmaster then
        weaponMaster = true
    end
    
    if talents.hasFindWeakness then
        findWeakness = true
    end
    
    if talents.hasSepsis then
        sepsis = true
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
    
    if talents.hasHiddenOpportunity then
        hiddenOpportunity = true
    end
    
    API.PrintDebug("Outlaw Rogue talents updated")
    
    return true
end

-- Update energy tracking
function Outlaw:UpdateEnergy()
    currentEnergy = API.GetPlayerPower()
    return true
end

-- Update combo points tracking
function Outlaw:UpdateComboPoints()
    currentComboPoints = API.GetPlayerComboPoints()
    return true
end

-- Update stealth state
function Outlaw:UpdateStealthState()
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
function Outlaw:UpdateTargetData()
    -- Check if in melee range
    inMeleeRange = API.IsUnitInRange("target", acrobaticStrikes and (MELEE_RANGE + ACROBATIC_STRIKES_RANGE) or MELEE_RANGE)
    
    -- Get target GUID
    local targetGUID = API.GetTargetGUID()
    
    -- Update target health
    if targetGUID and targetGUID ~= "" then
        targetHealth = API.GetTargetHealthPercent()
        
        -- Check for Ghostly Strike
        if ghostlyStrike then
            local ghostlyStrikeInfo = API.GetDebuffInfo(targetGUID, debuffs.GHOSTLY_STRIKE)
            if ghostlyStrikeInfo then
                ghostlyStrikeActive[targetGUID] = true
                ghostlyStrikeEndTime[targetGUID] = select(6, ghostlyStrikeInfo)
            else
                ghostlyStrikeActive[targetGUID] = false
                ghostlyStrikeEndTime[targetGUID] = 0
            end
        end
    end
    
    -- Update AoE targets count
    currentAoETargets = API.GetNearbyEnemiesCount(8) -- Blade Flurry radius
    
    return true
end

-- Update Roll the Bones buffs
function Outlaw:UpdateRollTheBones()
    -- Count active Roll the Bones buffs
    numbOfBuffs = 0
    
    -- Reset buff states
    broadsidesActive = API.UnitHasBuff("player", buffs.BROADSIDES)
    if broadsidesActive then
        broadsidesEndTime = select(6, API.GetBuffInfo("player", buffs.BROADSIDES))
        numbOfBuffs = numbOfBuffs + 1
    end
    
    buriedTreasureActive = API.UnitHasBuff("player", buffs.BURIED_TREASURE)
    if buriedTreasureActive then
        buriedTreasureEndTime = select(6, API.GetBuffInfo("player", buffs.BURIED_TREASURE))
        numbOfBuffs = numbOfBuffs + 1
    end
    
    grandMeleeActive = API.UnitHasBuff("player", buffs.GRAND_MELEE)
    if grandMeleeActive then
        grandMeleeEndTime = select(6, API.GetBuffInfo("player", buffs.GRAND_MELEE))
        numbOfBuffs = numbOfBuffs + 1
    end
    
    ruthlessPrecisionActive = API.UnitHasBuff("player", buffs.RUTHLESS_PRECISION)
    if ruthlessPrecisionActive then
        ruthlessPrecisionEndTime = select(6, API.GetBuffInfo("player", buffs.RUTHLESS_PRECISION))
        numbOfBuffs = numbOfBuffs + 1
        
        -- Set Between the Eyes as ready if we have Ruthless Precision
        betweenTheEyesReady = true
    else
        betweenTheEyesReady = false
    end
    
    skullAndCrossbonesActive = API.UnitHasBuff("player", buffs.SKULL_AND_CROSSBONES)
    if skullAndCrossbonesActive then
        skullAndCrossbonesEndTime = select(6, API.GetBuffInfo("player", buffs.SKULL_AND_CROSSBONES))
        numbOfBuffs = numbOfBuffs + 1
    end
    
    trueBearingActive = API.UnitHasBuff("player", buffs.TRUE_BEARING)
    if trueBearingActive then
        trueBearingEndTime = select(6, API.GetBuffInfo("player", buffs.TRUE_BEARING))
        numbOfBuffs = numbOfBuffs + 1
    end
    
    -- Track if Roll the Bones is active at all
    rolltheBonesActive = numbOfBuffs > 0
    if rolltheBonesActive then
        -- Use the earliest end time as the Roll the Bones end time
        -- This is a simplification, but works for our purposes
        local earliestEndTime = math.huge
        if broadsidesActive and broadsidesEndTime < earliestEndTime then
            earliestEndTime = broadsidesEndTime
        end
        if buriedTreasureActive and buriedTreasureEndTime < earliestEndTime then
            earliestEndTime = buriedTreasureEndTime
        end
        if grandMeleeActive and grandMeleeEndTime < earliestEndTime then
            earliestEndTime = grandMeleeEndTime
        end
        if ruthlessPrecisionActive and ruthlessPrecisionEndTime < earliestEndTime then
            earliestEndTime = ruthlessPrecisionEndTime
        end
        if skullAndCrossbonesActive and skullAndCrossbonesEndTime < earliestEndTime then
            earliestEndTime = skullAndCrossbonesEndTime
        end
        if trueBearingActive and trueBearingEndTime < earliestEndTime then
            earliestEndTime = trueBearingEndTime
        end
        
        rolltheBonesEndTime = earliestEndTime
    else
        rolltheBonesEndTime = 0
    end
    
    -- Track Count the Odds
    countTheOddsActive = API.UnitHasBuff("player", buffs.COUNT_THE_ODDS)
    if countTheOddsActive then
        countTheOddsEndTime = select(6, API.GetBuffInfo("player", buffs.COUNT_THE_ODDS))
    end
    
    -- Track Keep Your Wits
    keepYourWitsActive = API.UnitHasBuff("player", buffs.KEEP_YOUR_WITS)
    
    return true
end

-- Handle combat log events
function Outlaw:HandleCombatLogEvent(...)
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
            
            -- Track Opportunity
            if spellID == buffs.OPPORTUNITY then
                opportunityActive = true
                opportunityEndTime = select(6, API.GetBuffInfo("player", buffs.OPPORTUNITY))
                API.PrintDebug("Opportunity proc activated")
            end
            
            -- Track Adrenaline Rush
            if spellID == buffs.ADRENALINE_RUSH then
                adrenalineRushActive = true
                adrenalineRushEndTime = select(6, API.GetBuffInfo("player", buffs.ADRENALINE_RUSH))
                API.PrintDebug("Adrenaline Rush activated")
            end
            
            -- Track Roll the Bones buffs (specifically handle when they first appear)
            if spellID == buffs.BROADSIDES or
               spellID == buffs.BURIED_TREASURE or
               spellID == buffs.GRAND_MELEE or
               spellID == buffs.RUTHLESS_PRECISION or
               spellID == buffs.SKULL_AND_CROSSBONES or
               spellID == buffs.TRUE_BEARING then
                -- Update Roll the Bones tracking
                self:UpdateRollTheBones()
                API.PrintDebug("Roll the Bones buff applied: " .. spellName)
                
                if lastRTBBuffs ~= numbOfBuffs then
                    API.PrintDebug("Roll the Bones buffs changed from " .. tostring(lastRTBBuffs) .. " to " .. tostring(numbOfBuffs))
                    lastRTBBuffs = numbOfBuffs
                end
            end
            
            -- Track Count the Odds
            if spellID == buffs.COUNT_THE_ODDS then
                countTheOddsActive = true
                countTheOddsEndTime = select(6, API.GetBuffInfo("player", buffs.COUNT_THE_ODDS))
                API.PrintDebug("Count the Odds activated")
            end
            
            -- Track Blade Flurry
            if spellID == buffs.BLADE_FLURRY then
                bladeFlurryActive = true
                bladeFlurryEndTime = select(6, API.GetBuffInfo("player", buffs.BLADE_FLURRY))
                API.PrintDebug("Blade Flurry activated")
            end
            
            -- Track Killing Spree
            if spellID == buffs.KILLING_SPREE then
                killingSpreeActive = true
                killingSpreeEndTime = select(6, API.GetBuffInfo("player", buffs.KILLING_SPREE))
                API.PrintDebug("Killing Spree activated")
            end
            
            -- Track Dreadblades
            if spellID == buffs.DREADBLADES then
                dreadbladeActive = true
                dreadbladeEndTime = select(6, API.GetBuffInfo("player", buffs.DREADBLADES))
                API.PrintDebug("Dreadblades activated")
            end
            
            -- Track Keep Your Wits
            if spellID == buffs.KEEP_YOUR_WITS then
                keepYourWitsActive = true
                API.PrintDebug("Keep Your Wits activated")
            end
            
            -- Track Stealth
            if spellID == buffs.STEALTH then
                stealth = true
                API.PrintDebug("Stealth activated")
            end
        end
        
        -- Track debuffs on any target
        if sourceGUID == API.GetPlayerGUID() then
            -- Track Ghostly Strike
            if spellID == debuffs.GHOSTLY_STRIKE then
                ghostlyStrikeActive[destGUID] = true
                ghostlyStrikeEndTime[destGUID] = select(6, API.GetDebuffInfo(destGUID, debuffs.GHOSTLY_STRIKE))
                API.PrintDebug("Ghostly Strike applied to " .. destName)
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
            
            -- Track Opportunity
            if spellID == buffs.OPPORTUNITY then
                opportunityActive = false
                API.PrintDebug("Opportunity proc faded")
            end
            
            -- Track Adrenaline Rush
            if spellID == buffs.ADRENALINE_RUSH then
                adrenalineRushActive = false
                API.PrintDebug("Adrenaline Rush faded")
            end
            
            -- Track Roll the Bones buffs
            if spellID == buffs.BROADSIDES or
               spellID == buffs.BURIED_TREASURE or
               spellID == buffs.GRAND_MELEE or
               spellID == buffs.RUTHLESS_PRECISION or
               spellID == buffs.SKULL_AND_CROSSBONES or
               spellID == buffs.TRUE_BEARING then
                -- Update Roll the Bones tracking
                self:UpdateRollTheBones()
                API.PrintDebug("Roll the Bones buff faded: " .. spellName)
                
                if lastRTBBuffs ~= numbOfBuffs then
                    API.PrintDebug("Roll the Bones buffs changed from " .. tostring(lastRTBBuffs) .. " to " .. tostring(numbOfBuffs))
                    lastRTBBuffs = numbOfBuffs
                end
            end
            
            -- Track Count the Odds
            if spellID == buffs.COUNT_THE_ODDS then
                countTheOddsActive = false
                API.PrintDebug("Count the Odds faded")
            end
            
            -- Track Blade Flurry
            if spellID == buffs.BLADE_FLURRY then
                bladeFlurryActive = false
                API.PrintDebug("Blade Flurry faded")
            end
            
            -- Track Killing Spree
            if spellID == buffs.KILLING_SPREE then
                killingSpreeActive = false
                API.PrintDebug("Killing Spree faded")
            end
            
            -- Track Dreadblades
            if spellID == buffs.DREADBLADES then
                dreadbladeActive = false
                API.PrintDebug("Dreadblades faded")
            end
            
            -- Track Keep Your Wits
            if spellID == buffs.KEEP_YOUR_WITS then
                keepYourWitsActive = false
                API.PrintDebug("Keep Your Wits faded")
            end
            
            -- Track Stealth
            if spellID == buffs.STEALTH then
                stealth = false
                API.PrintDebug("Stealth faded")
            end
        end
        
        -- Track debuff removals
        if sourceGUID == API.GetPlayerGUID() then
            -- Track Ghostly Strike
            if spellID == debuffs.GHOSTLY_STRIKE and ghostlyStrikeActive[destGUID] then
                ghostlyStrikeActive[destGUID] = false
                API.PrintDebug("Ghostly Strike faded from " .. destName)
            end
        end
    end
    
    -- Track spell casts
    if eventType == "SPELL_CAST_SUCCESS" then
        if sourceGUID == API.GetPlayerGUID() then
            if spellID == spells.AMBUSH then
                ambushActive = true
                API.PrintDebug("Ambush cast")
            elseif spellID == spells.SINISTER_STRIKE then
                lastSinisterStrike = GetTime()
                API.PrintDebug("Sinister Strike cast")
                
                -- If Hidden Opportunity is talented
                if hiddenOpportunity then
                    local hiddenOppChance = 30 -- 30% chance baseline
                    local roll = math.random(100)
                    if roll <= hiddenOppChance then
                        hiddenOpportunityProcs = hiddenOpportunityProcs + 1
                        API.PrintDebug("Hidden Opportunity proc")
                    end
                end
            elseif spellID == spells.PISTOL_SHOT then
                lastPistolShot = GetTime()
                API.PrintDebug("Pistol Shot cast")
            elseif spellID == spells.DISPATCH then
                lastDispatch = GetTime()
                API.PrintDebug("Dispatch cast")
                finishingMove = true
            elseif spellID == spells.BETWEEN_THE_EYES then
                API.PrintDebug("Between the Eyes cast")
                finishingMove = true
            elseif spellID == spells.ROLL_THE_BONES then
                lastRollTheBones = GetTime()
                API.PrintDebug("Roll the Bones cast")
                finishingMove = true
            elseif spellID == spells.SLICE_AND_DICE then
                API.PrintDebug("Slice and Dice cast")
                finishingMove = true
            elseif spellID == spells.BLADE_FLURRY then
                bladeFlurryActive = true
                bladeFlurryEndTime = GetTime() + BLADE_FLURRY_DURATION
                API.PrintDebug("Blade Flurry cast")
            elseif spellID == spells.ADRENALINE_RUSH then
                lastAdrenalineRush = GetTime()
                adrenalineRushActive = true
                adrenalineRushEndTime = GetTime() + ADRENALINE_RUSH_DURATION
                API.PrintDebug("Adrenaline Rush cast")
            elseif spellID == spells.KILLING_SPREE then
                killingSpreeActive = true
                killingSpreeEndTime = GetTime() + KILLING_SPREE_DURATION
                API.PrintDebug("Killing Spree cast")
            elseif spellID == spells.GHOSTLY_STRIKE then
                API.PrintDebug("Ghostly Strike cast")
            elseif spellID == spells.DREADBLADES then
                dreadbladeActive = true
                dreadbladeEndTime = GetTime() + DREADBLADE_DURATION
                API.PrintDebug("Dreadblades cast")
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
    
    return true
end

-- Main rotation function
function Outlaw:RunRotation()
    -- Check if we should be running Outlaw Rogue logic
    if API.GetActiveSpecID() ~= OUTLAW_SPEC_ID then
        return false
    end
    
    -- Skip rotation if player is casting
    if API.IsPlayerCasting() then
        return false
    end
    
    -- Get settings
    local settings = ConfigRegistry:GetSettings("OutlawRogue")
    
    -- Update variables
    self:UpdateEnergy()
    self:UpdateComboPoints()
    burstModeActive = settings.rotationSettings.burstEnabled and API.ShouldUseBurst()
    self:UpdateTargetData() -- Makes sure we have current target information
    self:UpdateRollTheBones() -- Makes sure we have current Roll the Bones status
    
    -- Handle next cast override
    if nextCastOverride and API.CanCast(nextCastOverride) then
        local spell = nextCastOverride
        nextCastOverride = nil
        API.CastSpell(spell)
        return true
    end
    
    -- Check for poisons that need to be applied
    if not API.UnitHasBuff("player", buffs.INSTANT_POISON) and
       not API.UnitHasBuff("player", buffs.WOUND_POISON) and
       not API.UnitHasBuff("player", buffs.CRIPPLING_POISON) and
       not API.UnitHasBuff("player", buffs.NUMBING_POISON) and
       not API.UnitHasBuff("player", buffs.ATROPHIC_POISON) and
       not API.IsInCombat() then
        
        local poisonToUse
        
        if settings.rotationSettings.poisonType == "Instant Poison" and instantPoison then
            poisonToUse = spells.INSTANT_POISON
        elseif settings.rotationSettings.poisonType == "Wound Poison" and woundPoison then
            poisonToUse = spells.WOUND_POISON
        elseif settings.rotationSettings.poisonType == "Crippling Poison" and cripplingPoison then
            poisonToUse = spells.CRIPPLING_POISON
        elseif settings.rotationSettings.poisonType == "Numbing Poison" and numbingPoison then
            poisonToUse = spells.NUMBING_POISON
        elseif settings.rotationSettings.poisonType == "Atrophic Poison" and atrophicPoison then
            poisonToUse = spells.ATROPHIC_POISON
        end
        
        if poisonToUse and API.CanCast(poisonToUse) then
            API.CastSpell(poisonToUse)
            return true
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
    
    -- Skip if not in melee range
    if not inMeleeRange then
        return false
    end
    
    -- Handle cooldowns first
    if self:HandleCooldowns(settings) then
        return true
    end
    
    -- Slice and Dice maintenance
    if settings.finisherSettings.useSliceAndDice and
       (not sliceAndDiceActive or (sliceAndDiceEndTime - GetTime() < settings.finisherSettings.sliceAndDiceRefreshThreshold)) and
       currentComboPoints >= settings.finisherSettings.sliceAndDiceComboPoints and
       API.CanCast(spells.SLICE_AND_DICE) then
        API.CastSpell(spells.SLICE_AND_DICE)
        return true
    end
    
    -- Roll the Bones logic
    if rollTheBones and 
       settings.abilityControls.rollTheBones.enabled and
       currentComboPoints >= 5 and
       API.CanCast(spells.ROLL_THE_BONES) then
        
        local shouldRoll = false
        local strategy = settings.rotationSettings.rollTheBonesStrategy
        
        -- Roll if we have no buffs
        if not rolltheBonesActive then
            shouldRoll = true
        else
            -- Check based on strategy
            if strategy == "2+ Buffs" and numbOfBuffs < 2 then
                shouldRoll = true
            elseif strategy == "True Bearing" and not trueBearingActive then
                shouldRoll = true
            elseif strategy == "Any 2 Buffs" and numbOfBuffs < 2 then
                shouldRoll = true
            elseif strategy == "1+ Buffs" and numbOfBuffs < 1 then
                shouldRoll = true
            elseif strategy == "Specific Buffs" then
                -- Check if we're missing any of the specific buffs we want
                local missingDesiredBuff = false
                
                for _, buffName in ipairs(settings.rotationSettings.specificBuffs) do
                    if (buffName == "Broadside" and not broadsidesActive) or
                       (buffName == "Buried Treasure" and not buriedTreasureActive) or
                       (buffName == "Grand Melee" and not grandMeleeActive) or
                       (buffName == "Ruthless Precision" and not ruthlessPrecisionActive) or
                       (buffName == "Skull & Crossbones" and not skullAndCrossbonesActive) or
                       (buffName == "True Bearing" and not trueBearingActive) then
                        missingDesiredBuff = true
                        break
                    end
                end
                
                shouldRoll = missingDesiredBuff
            end
        end
        
        -- Always roll with Loaded Dice if the talent is active
        if talents.hasLoadedDice and settings.abilityControls.rollTheBones.alwaysRollWithLoadedDice and adrenalineRushActive then
            shouldRoll = true
        end
        
        -- Check minimum buff count requirement
        if rolltheBonesActive and numbOfBuffs >= settings.abilityControls.rollTheBones.minimumBuffCount then
            shouldRoll = false
        end
        
        -- Roll if Count the Odds is active (guaranteed to get at least one specific buff)
        if countTheOddsActive then
            shouldRoll = true
        end
        
        if shouldRoll then
            API.CastSpell(spells.ROLL_THE_BONES)
            return true
        end
    end
    
    -- Check for AoE or Single Target
    if settings.rotationSettings.aoeEnabled and 
       currentAoETargets >= settings.rotationSettings.aoeThreshold and 
       not bladeFlurryActive and
       settings.abilityControls.bladeFlurry.enabled and
       currentAoETargets >= settings.abilityControls.bladeFlurry.minimumTargets and
       API.CanCast(spells.BLADE_FLURRY) then
        
        -- Check if we should reserve it with Adrenaline Rush
        if settings.abilityControls.bladeFlurry.reserveWithAdrenalineRush and
           not adrenalineRushActive and
           API.GetSpellCooldown(spells.ADRENALINE_RUSH) < 10 then
            -- Save Blade Flurry for Adrenaline Rush
        else
            API.CastSpell(spells.BLADE_FLURRY)
            return true
        end
    end
    
    -- Use Ghostly Strike if talented and not active on target
    if ghostlyStrike and
       settings.cooldownSettings.useGhostlyStrike then
        
        local targetGUID = API.GetTargetGUID()
        
        if targetGUID and 
           (not ghostlyStrikeActive[targetGUID] or 
            (ghostlyStrikeActive[targetGUID] and 
             ghostlyStrikeEndTime[targetGUID] - GetTime() < 3)) and -- Refresh with 3 seconds remaining
           API.CanCast(spells.GHOSTLY_STRIKE) then
            API.CastSpell(spells.GHOSTLY_STRIKE)
            return true
        end
    end
    
    -- Handle AoE or Single Target rotations
    if settings.rotationSettings.aoeEnabled and currentAoETargets >= settings.rotationSettings.aoeThreshold then
        return self:HandleAoERotation(settings)
    else
        return self:HandleSingleTargetRotation(settings)
    end
end

-- Handle interrupts
function Outlaw:HandleInterrupts(settings)
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
function Outlaw:HandleDefensives(settings)
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
function Outlaw:HandleCooldowns(settings)
    -- Skip if not in combat
    if not API.IsInCombat() then
        return false
    end
    
    -- Use Adrenaline Rush
    if adrenalineRush and
       settings.cooldownSettings.useAdrenalineRush and
       settings.abilityControls.adrenalineRush.enabled and
       not adrenalineRushActive and
       API.CanCast(spells.ADRENALINE_RUSH) then
        
        -- Check if should only use during burst
        if not settings.abilityControls.adrenalineRush.useDuringBurstOnly or burstModeActive then
            -- Check additional requirements
            local shouldUseAdrenalineRush = false
            
            if settings.cooldownSettings.adrenalineRushMode == "On Cooldown" then
                shouldUseAdrenalineRush = true
            elseif settings.cooldownSettings.adrenalineRushMode == "With Roll the Bones" then
                shouldUseAdrenalineRush = (numbOfBuffs >= 2 or trueBearingActive)
            elseif settings.cooldownSettings.adrenalineRushMode == "Burst Only" then
                shouldUseAdrenalineRush = burstModeActive
            end
            
            if settings.abilityControls.adrenalineRush.requireEnergy and currentEnergy < settings.abilityControls.adrenalineRush.requireEnergy then
                shouldUseAdrenalineRush = false
            end
            
            if settings.abilityControls.adrenalineRush.requireGoodRtBBuffs and numbOfBuffs < 2 and not trueBearingActive then
                shouldUseAdrenalineRush = false
            end
            
            if shouldUseAdrenalineRush then
                API.CastSpell(spells.ADRENALINE_RUSH)
                return true
            end
        end
    end
    
    -- Use Keep It Rolling
    if keepYourWits and
       settings.cooldownSettings.useKeepItRolling and
       rolltheBonesActive and
       numbOfBuffs >= 2 and
       API.CanCast(spells.KEEP_IT_ROLLING) then
        API.CastSpell(spells.KEEP_IT_ROLLING)
        return true
    end
    
    -- Use Dreadblades
    if dreadblade and 
       settings.cooldownSettings.useDreadblades and
       not dreadbladeActive and
       API.CanCast(spells.DREADBLADES) then
        
        local shouldUseDreadblades = false
        
        if settings.cooldownSettings.dreadbladesMode == "On Cooldown" then
            shouldUseDreadblades = true
        elseif settings.cooldownSettings.dreadbladesMode == "With Adrenaline Rush" then
            shouldUseDreadblades = adrenalineRushActive
        elseif settings.cooldownSettings.dreadbladesMode == "Burst Only" then
            shouldUseDreadblades = burstModeActive
        end
        
        if shouldUseDreadblades then
            API.CastSpell(spells.DREADBLADES)
            return true
        end
    end
    
    -- Use Killing Spree
    if killingSpree and
       settings.cooldownSettings.useKillingSpree and
       not killingSpreeActive and
       API.CanCast(spells.KILLING_SPREE) then
        
        local shouldUseKillingSpree = false
        
        if settings.cooldownSettings.killingSpreeMode == "On Cooldown" then
            shouldUseKillingSpree = true
        elseif settings.cooldownSettings.killingSpreeMode == "With Adrenaline Rush" then
            shouldUseKillingSpree = adrenalineRushActive
        elseif settings.cooldownSettings.killingSpreeMode == "Low Energy Only" then
            shouldUseKillingSpree = currentEnergy < 30
        elseif settings.cooldownSettings.killingSpreeMode == "Burst Only" then
            shouldUseKillingSpree = burstModeActive
        end
        
        if shouldUseKillingSpree then
            if API.UnitExists("target") then
                API.CastSpell(spells.KILLING_SPREE)
                return true
            end
        end
    end
    
    -- Use Vanish
    if settings.cooldownSettings.useVanish and
       not inStealth and
       not subterfugeActive and
       not shadowDanceActive and
       API.CanCast(spells.VANISH) then
        
        local shouldUseVanish = false
        
        if settings.cooldownSettings.vanishMode == "With Adrenaline Rush" then
            shouldUseVanish = adrenalineRushActive
        elseif settings.cooldownSettings.vanishMode == "For Ambush" then
            shouldUseVanish = true -- We'll use Ambush in the stealth rotation
        elseif settings.cooldownSettings.vanishMode == "Burst Only" then
            shouldUseVanish = burstModeActive
        end
        
        if shouldUseVanish then
            API.CastSpell(spells.VANISH)
            return true
        end
    end
    
    -- Use Shadow Dance
    if talents.hasShadowDance and
       settings.cooldownSettings.useShadowDance and
       not inStealth and
       not shadowDanceActive and
       not subterfugeActive and
       API.CanCast(spells.SHADOW_DANCE) then
        
        local shouldUseShadowDance = false
        
        if settings.cooldownSettings.shadowDanceMode == "On Cooldown" then
            shouldUseShadowDance = true
        elseif settings.cooldownSettings.shadowDanceMode == "For Ambush" then
            shouldUseShadowDance = true -- We'll use Ambush in the stealth rotation
        elseif settings.cooldownSettings.shadowDanceMode == "With Adrenaline Rush" then
            shouldUseShadowDance = adrenalineRushActive
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
        elseif settings.cooldownSettings.sepsisMode == "With Adrenaline Rush" then
            shouldUseSepsis = adrenalineRushActive
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
function Outlaw:HandleStealthRotation(settings)
    -- Use Ambush from stealth
    if API.CanCast(spells.AMBUSH) then
        API.CastSpell(spells.AMBUSH)
        return true
    end
    
    return false
end

-- Handle AoE rotation
function Outlaw:HandleAoERotation(settings)
    -- Check if we have Blade Flurry active
    if not bladeFlurryActive and 
       settings.cooldownSettings.useBladeFlurry and
       currentAoETargets >= settings.cooldownSettings.bladeFlurryTargets and
       API.CanCast(spells.BLADE_FLURRY) then
        API.CastSpell(spells.BLADE_FLURRY)
        return true
    end
    
    -- Use finishers at high combo points
    if currentComboPoints >= 5 then
        -- Use Between the Eyes if we have Ruthless Precision or it's a priority
        if betweenTheEyes and
           settings.finisherSettings.useBetweenTheEyes and
           (betweenTheEyesReady or (settings.finisherSettings.finisherPriority == "Between the Eyes > Slice and Dice > Dispatch")) and
           currentComboPoints >= settings.finisherSettings.betweenTheEyesComboPoints and
           API.CanCast(spells.BETWEEN_THE_EYES) then
            API.CastSpell(spells.BETWEEN_THE_EYES)
            return true
        end
        
        -- Use Dispatch as a finisher
        if dispatch and
           settings.finisherSettings.useDispatch and
           currentComboPoints >= settings.finisherSettings.dispatchComboPoints and
           sliceAndDiceActive and -- Make sure Slice and Dice is up
           API.CanCast(spells.DISPATCH) then
            API.CastSpell(spells.DISPATCH)
            return true
        end
    end
    
    -- Use Opportunity-boosted Pistol Shot
    if pistolShot and opportunityActive and API.CanCast(spells.PISTOL_SHOT) then
        API.CastSpell(spells.PISTOL_SHOT)
        return true
    end
    
    -- Build with Sinister Strike
    if sinisterStrike and API.CanCast(spells.SINISTER_STRIKE) then
        -- Check for energy pooling
        if not settings.rotationSettings.energyPooling or 
           currentEnergy >= settings.rotationSettings.energyPoolingThreshold or
           currentComboPoints == 0 then
            API.CastSpell(spells.SINISTER_STRIKE)
            return true
        end
    end
    
    return false
end

-- Handle Single Target rotation
function Outlaw:HandleSingleTargetRotation(settings)
    -- Use finishers at high combo points
    if currentComboPoints >= 5 then
        -- Use Between the Eyes if we have Ruthless Precision or it's a priority
        if betweenTheEyes and
           settings.finisherSettings.useBetweenTheEyes and
           (betweenTheEyesReady or (settings.finisherSettings.finisherPriority == "Between the Eyes > Slice and Dice > Dispatch")) and
           currentComboPoints >= settings.finisherSettings.betweenTheEyesComboPoints and
           API.CanCast(spells.BETWEEN_THE_EYES) then
            API.CastSpell(spells.BETWEEN_THE_EYES)
            return true
        end
        
        -- Use Dispatch as a finisher
        if dispatch and
           settings.finisherSettings.useDispatch and
           currentComboPoints >= settings.finisherSettings.dispatchComboPoints and
           sliceAndDiceActive and -- Make sure Slice and Dice is up
           API.CanCast(spells.DISPATCH) then
            API.CastSpell(spells.DISPATCH)
            return true
        end
    end
    
    -- Use Opportunity-boosted Pistol Shot
    if pistolShot and opportunityActive and API.CanCast(spells.PISTOL_SHOT) then
        API.CastSpell(spells.PISTOL_SHOT)
        return true
    end
    
    -- Build with Sinister Strike
    if sinisterStrike and API.CanCast(spells.SINISTER_STRIKE) then
        -- Check for energy pooling
        if not settings.rotationSettings.energyPooling or 
           currentEnergy >= settings.rotationSettings.energyPoolingThreshold or
           currentComboPoints == 0 then
            API.CastSpell(spells.SINISTER_STRIKE)
            return true
        end
    end
    
    return false
end

-- Handle specialization change
function Outlaw:OnSpecializationChanged()
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
    rolltheBonesActive = false
    rolltheBonesEndTime = 0
    adrenalineRushActive = false
    adrenalineRushEndTime = 0
    broadsidesActive = false
    broadsidesEndTime = 0
    buriedTreasureActive = false
    buriedTreasureEndTime = 0
    grandMeleeActive = false
    grandMeleeEndTime = 0
    ruthlessPrecisionActive = false
    ruthlessPrecisionEndTime = 0
    skullAndCrossbonesActive = false
    skullAndCrossbonesEndTime = 0
    trueBearingActive = false
    trueBearingEndTime = 0
    numbOfBuffs = 0
    betweenTheEyesReady = false
    opportunityActive = false
    opportunityEndTime = 0
    deadShotReady = false
    keepYourWitsActive = false
    ghostlyStrikeActive = {}
    ghostlyStrikeEndTime = {}
    echoingReprimandActive = false
    echoingReprimandEndTime = 0
    echoingReprimandPoints = 0
    bladeFlurryActive = false
    bladeFlurryEndTime = 0
    countTheOddsActive = false
    countTheOddsEndTime = 0
    killingSpreeActive = false
    killingSpreeEndTime = 0
    dreadbladeActive = false
    dreadbladeEndTime = 0
    hiddenOpportunity = false
    hiddenOpportunityProcs = 0
    lastRollTheBones = 0
    lastDispatch = 0
    lastAdrenalineRush = 0
    lastPistolShot = 0
    lastSinisterStrike = 0
    pistolShot = false
    sinisterStrike = false
    bladeFlurry = false
    betweenTheEyes = false
    rollTheBones = false
    dispatch = false
    adrenalineRush = false
    killingSpree = false
    dreadblade = false
    keepYourWits = false
    ghostlyStrike = false
    echoingReprimand = false
    subtlety = false
    ambushActive = false
    acrobaticStrikes = false
    sealFate = false
    deeperDaggers = false
    quickDraw = false
    retractable = false
    fateOfTheBold = false
    subterfugeTalent = false
    fantaSea = false
    combatPotency = false
    weaponFinesse = false
    weaponMaster = false
    findWeakness = false
    sepsis = false
    inStealth = false
    inMeleeRange = false
    targetHealth = 100
    cripplingPoison = false
    instantPoison = false
    woundPoison = false
    numbingPoison = false
    atrophicPoison = false
    lastRTBBuffs = 0
    finishingMove = false
    
    -- Check stealth state
    self:UpdateStealthState()
    
    -- Update Roll the Bones
    self:UpdateRollTheBones()
    
    API.PrintDebug("Outlaw Rogue state reset on spec change")
    
    return true
end

-- Return the module for loading
return Outlaw