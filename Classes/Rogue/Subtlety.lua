------------------------------------------
-- WindrunnerRotations - Subtlety Rogue Module
-- Author: VortexQ8
-- The War Within Season 2
------------------------------------------

local Subtlety = {}
-- This will be assigned to addon.Classes.Rogue.Subtlety when loaded

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
local shadowDanceCharges = 0
local shadowDanceMaxCharges = 0
local vanishActive = false
local vanishEndTime = 0
local subterfugeActive = false
local subterfugeEndTime = 0
local symbolsOfDeathActive = false
local symbolsOfDeathEndTime = 0
local shadowTechniquesActive = false
local shadowTechniquesEndTime = 0
local shadowTechniquesCount = 0
local findWeaknessActive = {}
local findWeaknessEndTime = {}
local ruptureActive = {}
local ruptureEndTime = {}
local danceOfShadowsActive = false
local danceOfShadowsEndTime = 0
local flagellationActive = false
local flagellationEndTime = 0
local flagellationCount = 0
local finality = {}
local finalityEndTime = {}
local darkShadowActive = false
local premeditation = false
local premedProcActive = false
local premedProcEndTime = 0
local shadowBlades = false
local shadowBladesActive = false
local shadowBladesEndTime = 0
local secret = false
local secretActive = false
local secretEndTime = 0
local inStealth = false
local inMeleeRange = false
local targetHealth = 100
local backstabActive = false
local shuriken = false
local symbolicPowerActive = false
local symbolicPowerEndTime = 0
local symbolicPowerStacks = 0
local perforatedVeinsActive = false
local perforatedVeinsEndTime = 0
local perforatedVeinsStacks = 0
local sepsis = false
local sepsisActive = false
local sepsisEndTime = 0
local deeperShadowsActive = false
local backstab = false
local gloomblade = false
local shurikenStorm = false
local blackPowder = false
local eviscerate = false
local rupture = false
local shadowstrike = false
local cheapShot = false
local kidney = false
local shadowstep = false
local shurikenTornado = false
local shurikenTornadoActive = false
local shurikenTornadoEndTime = 0
local darkBrew = false
local shadowcraft = false
local kyrian = false
local dagger = false
local weaponMaster = false
local acrobaticStrikes = false
local deeperStratagem = false
local vigor = false
local markedForDeath = false
local deepeningShadows = false
local shadowFocus = false
local akaaris = false
local inevitability = false
local resounds = false
local weaponDisability = false
local secretStash = false
local shadowCraft = false
local secretStratagem = false
local subterfugeTalent = false
local darkShadow = false
local coldBlood = false
local echoing = false
local sealFate = false
local prey = false
local blindside = false
local soothingDarkness = false
local nightTerrors = false
local numBlackPowderTargets = 0
local inOpener = false
local shadowStrikeOutOfStealth = false
local refreshableSliceAndDice = false
local refreshableSymbolsOfDeath = false
local refreshableRupture = false
local lastShadowDance = 0
local lastSliceAndDice = 0
local lastSymbolsOfDeath = 0
local lastEvis = 0
local lastShurikenStorm = 0
local lastShurikenTornado = 0
local gloomy = false
local flagellation = false

-- Constants
local SUBTLETY_SPEC_ID = 261
local DEFAULT_AOE_THRESHOLD = 3
local SLICE_AND_DICE_DURATION = 30 -- seconds (base, can be extended)
local SHADOW_DANCE_DURATION = 8 -- seconds (base)
local VANISH_DURATION = 3 -- seconds (stealth duration)
local SUBTERFUGE_DURATION = 3 -- seconds
local SYMBOLS_OF_DEATH_DURATION = 10 -- seconds
local SHADOW_TECHNIQUES_DURATION = 30 -- seconds
local FIND_WEAKNESS_DURATION = 10 -- seconds
local RUPTURE_DURATION = 24 -- seconds (base, with 5 combo points)
local DANCE_OF_SHADOWS_DURATION = 8 -- seconds
local FLAGELLATION_DURATION = 12 -- seconds
local SHADOW_BLADES_DURATION = 20 -- seconds
local SECRET_TECHNIQUE_DURATION = 10 -- seconds (this isn't a real duration, used for tracking)
local SYMBOLIC_POWER_DURATION = 10 -- seconds
local PERFORATED_VEINS_DURATION = 12 -- seconds
local SEPSIS_DURATION = 10 -- seconds
local SHURIKEN_TORNADO_DURATION = 4 -- seconds
local MELEE_RANGE = 5 -- yards
local ACROBATIC_STRIKES_RANGE = 3 -- additional yards

-- Initialize the Subtlety module
function Subtlety:Initialize()
    self:RegisterSpells()
    self:RegisterVariables()
    self:RegisterSettings()
    self:RegisterEvents()
    
    API.PrintDebug("Subtlety Rogue module initialized")
    
    return true
end

-- Register spell IDs
function Subtlety:RegisterSpells()
    -- Core rotational abilities
    spells.BACKSTAB = 53
    spells.GLOOMBLADE = 200758
    spells.SHADOWSTRIKE = 185438
    spells.SHURIKEN_STORM = 197835
    spells.SHURIKEN_TOSS = 114014
    spells.EVISCERATE = 196819
    spells.RUPTURE = 1943
    spells.BLACK_POWDER = 319175
    spells.SLICE_AND_DICE = 315496
    spells.SYMBOLS_OF_DEATH = 212283
    spells.SHADOW_DANCE = 185313
    spells.SHADOW_BLADES = 121471
    spells.SECRET_TECHNIQUE = 280719
    spells.SHURIKEN_TORNADO = 277925
    spells.SHADOW_VAULT = 354825
    
    -- Core utilities
    spells.VANISH = 1856
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
    spells.SHADOWSTEP = 36554
    
    -- Poisons
    spells.CRIPPLING_POISON = 3408
    spells.INSTANT_POISON = 315584
    spells.WOUND_POISON = 8679
    spells.NUMBING_POISON = 5761
    spells.ATROPHIC_POISON = 381637
    
    -- Talents and passives
    spells.SHADOW_TECHNIQUES = 196912
    spells.FIND_WEAKNESS = 91023
    spells.PREMEDITATION = 343160
    spells.SHADOW_FOCUS = 108209
    spells.VIGOR = 14983
    spells.ALACRITY = 193539
    spells.DEEPENING_SHADOWS = 185314
    spells.DARK_SHADOW = 245687
    spells.SECRET_STRATAGEM = 394320
    spells.SUBTERFUGE = 108208
    spells.NIGHTSTALKER = 14062
    spells.SHOT_IN_THE_DARK = 257505
    spells.IMPROVED_SHADOW_DANCE = 393970
    spells.FINALITY = 385948
    spells.WEAPONMASTER = 193537
    spells.GLOOMBLADE = 200758
    spells.WEAPONMASTER = 193537
    spells.ACROBATIC_STRIKES = 196924
    spells.DEEPER_STRATAGEM = 193531
    spells.VIGOR = 14983
    spells.MARKED_FOR_DEATH = 137619
    spells.DEEPENING_SHADOWS = 185314
    spells.SHADOW_FOCUS = 108209
    spells.AKAARIS_SOUL_FRAGMENT = 385948
    spells.INEVITABILITY = -1
    spells.RESOUNDING_CLARITY = 381622
    spells.WEAPON_DISABILITY = 324073
    spells.SECRET_STASH = 394598
    spells.SHADOW_CRAFT = -1
    spells.COLD_BLOOD = 382245
    spells.SHADOW_TECHNIQUES = 196912
    spells.IMPROVED_AMBUSH = 381620
    spells.SEAL_FATE = 14190
    spells.PREY_ON_THE_WEAK = 131511
    spells.BLINDSIDE = 328085
    spells.SOOTHING_DARKNESS = 393971
    spells.THISTLE_TEA = 381623
    spells.NIGHT_TERRORS = 277953
    spells.ECHOING_REPRIMAND = 385616
    spells.SEPSIS = 385408
    spells.DARK_BREW = 354111
    
    -- War Within Season 2 specific
    spells.PERFORATED_VEINS = 382506
    spells.DEEPER_SHADOWS = 388867
    spells.SYMBOLIC_POWER = 427025
    spells.DANSE_MACABRE = 383405
    spells.SHADOWCRAFT = 426594
    spells.SHADOWSTRIKE_OUT_OF_STEALTH = 426648
    spells.DANCE_OF_SHADOWS = 389958
    
    -- Covenant abilities (for reference, converted in WoW 10.0)
    spells.FLAGELLATION = 323654
    spells.ECHOING_REPRIMAND = 385616
    spells.SEPSIS = 385408
    spells.SERRATED_BONE_SPIKE = 385424
    
    -- Buff IDs
    spells.SLICE_AND_DICE_BUFF = 315496
    spells.SHADOW_DANCE_BUFF = 185422
    spells.VANISH_BUFF = 11327
    spells.SUBTERFUGE_BUFF = 115192
    spells.SYMBOLS_OF_DEATH_BUFF = 212283
    spells.SHADOW_TECHNIQUES_BUFF = 196912
    spells.DANCE_OF_SHADOWS_BUFF = 389958
    spells.FLAGELLATION_BUFF = 384631
    spells.SHADOW_BLADES_BUFF = 121471
    spells.SECRET_TECHNIQUE_BUFF = 257506
    spells.STEALTH_BUFF = 1784
    spells.PREMEDITATION_BUFF = 343173
    spells.SYMBOLIC_POWER_BUFF = 427025
    spells.PERFORATED_VEINS_BUFF = 382506
    spells.SEPSIS_BUFF = 347037
    spells.SHURIKEN_TORNADO_BUFF = 277925
    spells.COLD_BLOOD_BUFF = 382245
    
    -- Finality buffs (from Finality talent)
    spells.FINALITY_EVISCERATE_BUFF = 385949
    spells.FINALITY_BLACK_POWDER_BUFF = 385951
    spells.FINALITY_RUPTURE_BUFF = 385948
    
    -- Debuff IDs
    spells.FIND_WEAKNESS_DEBUFF = 316220
    spells.RUPTURE_DEBUFF = 1943
    spells.FLAGELLATION_DEBUFF = 323654
    spells.CRIPPLING_POISON_DEBUFF = 3409
    spells.WOUND_POISON_DEBUFF = 8680
    spells.NUMBING_POISON_DEBUFF = 5760
    spells.ATROPHIC_POISON_DEBUFF = 381637
    spells.INSTANT_POISON_DEBUFF = 315585
    spells.SEPSIS_DEBUFF = 328305
    
    -- Register all spells with the API tracking system
    for spellName, spellID in pairs(spells) do
        if spellID > 0 then -- Skip placeholders with -1
            API.RegisterSpell(spellID)
        end
    end
    
    -- Define aura tracking
    buffs.SLICE_AND_DICE = spells.SLICE_AND_DICE_BUFF
    buffs.SHADOW_DANCE = spells.SHADOW_DANCE_BUFF
    buffs.VANISH = spells.VANISH_BUFF
    buffs.SUBTERFUGE = spells.SUBTERFUGE_BUFF
    buffs.SYMBOLS_OF_DEATH = spells.SYMBOLS_OF_DEATH_BUFF
    buffs.SHADOW_TECHNIQUES = spells.SHADOW_TECHNIQUES_BUFF
    buffs.DANCE_OF_SHADOWS = spells.DANCE_OF_SHADOWS_BUFF
    buffs.FLAGELLATION = spells.FLAGELLATION_BUFF
    buffs.SHADOW_BLADES = spells.SHADOW_BLADES_BUFF
    buffs.SECRET_TECHNIQUE = spells.SECRET_TECHNIQUE_BUFF
    buffs.STEALTH = spells.STEALTH_BUFF
    buffs.PREMEDITATION = spells.PREMEDITATION_BUFF
    buffs.SYMBOLIC_POWER = spells.SYMBOLIC_POWER_BUFF
    buffs.PERFORATED_VEINS = spells.PERFORATED_VEINS_BUFF
    buffs.SEPSIS = spells.SEPSIS_BUFF
    buffs.SHURIKEN_TORNADO = spells.SHURIKEN_TORNADO_BUFF
    buffs.COLD_BLOOD = spells.COLD_BLOOD_BUFF
    
    -- Finality buff tracking
    buffs.FINALITY_EVISCERATE = spells.FINALITY_EVISCERATE_BUFF
    buffs.FINALITY_BLACK_POWDER = spells.FINALITY_BLACK_POWDER_BUFF
    buffs.FINALITY_RUPTURE = spells.FINALITY_RUPTURE_BUFF
    
    debuffs.FIND_WEAKNESS = spells.FIND_WEAKNESS_DEBUFF
    debuffs.RUPTURE = spells.RUPTURE_DEBUFF
    debuffs.FLAGELLATION = spells.FLAGELLATION_DEBUFF
    debuffs.CRIPPLING_POISON = spells.CRIPPLING_POISON_DEBUFF
    debuffs.WOUND_POISON = spells.WOUND_POISON_DEBUFF
    debuffs.NUMBING_POISON = spells.NUMBING_POISON_DEBUFF
    debuffs.ATROPHIC_POISON = spells.ATROPHIC_POISON_DEBUFF
    debuffs.INSTANT_POISON = spells.INSTANT_POISON_DEBUFF
    debuffs.SEPSIS = spells.SEPSIS_DEBUFF
    
    return true
end

-- Register variables to track
function Subtlety:RegisterVariables()
    -- Talent tracking
    talents.hasShadowTechniques = false
    talents.hasFindWeakness = false
    talents.hasPremeditation = false
    talents.hasShadowFocus = false
    talents.hasVigor = false
    talents.hasAlacrity = false
    talents.hasDeepeningShows = false
    talents.hasDarkShadow = false
    talents.hasSecretStratagem = false
    talents.hasSubterfuge = false
    talents.hasNightstalker = false
    talents.hasShotInTheDark = false
    talents.hasImprovedShadowDance = false
    talents.hasFinality = false
    talents.hasWeaponmaster = false
    talents.hasGloomblade = false
    talents.hasAcrobaticStrikes = false
    talents.hasDeeperStratagem = false
    talents.hasMarkedForDeath = false
    talents.hasDeepeningShows = false
    talents.hasAkaarisSoulFragment = false
    talents.hasInevitability = false
    talents.hasResoundingClarity = false
    talents.hasWeaponDisability = false
    talents.hasSecretStash = false
    talents.hasShadowCraft = false
    talents.hasColdBlood = false
    talents.hasImprovedAmbush = false
    talents.hasSealFate = false
    talents.hasPreyOnTheWeak = false
    talents.hasBlindside = false
    talents.hasSoothingDarkness = false
    talents.hasThistleTea = false
    talents.hasNightTerrors = false
    talents.hasEchoingReprimand = false
    talents.hasSepsis = false
    talents.hasDarkBrew = false
    talents.hasShadowBlades = false
    talents.hasSecretTechnique = false
    talents.hasShurikenTornado = false
    
    -- War Within Season 2 talents
    talents.hasPerforatedVeins = false
    talents.hasDeeperShadows = false
    talents.hasSymbolicPower = false
    talents.hasDanseMacabre = false
    talents.hasShadowcraft = false
    talents.hasShadowstrikeOutOfStealth = false
    talents.hasDanceOfShadows = false
    
    -- Initialize energy and combo points
    currentEnergy = API.GetPlayerPower()
    maxEnergy = API.GetPlayerMaxPower()
    currentComboPoints = API.GetPlayerComboPoints()
    maxComboPoints = 5 -- Default, could be 6 with Deeper Stratagem
    
    -- Check if in stealth
    inStealth = API.IsStealthed()
    
    -- Initialize Shadow Dance charges
    shadowDanceCharges = API.GetSpellCharges(spells.SHADOW_DANCE) or 0
    shadowDanceMaxCharges = API.GetSpellMaxCharges(spells.SHADOW_DANCE) or 2
    
    -- Initialize tracking tables
    findWeaknessActive = {}
    findWeaknessEndTime = {}
    ruptureActive = {}
    ruptureEndTime = {}
    finality = {}
    finalityEndTime = {}
    
    return true
end

-- Register spec-specific settings
function Subtlety:RegisterSettings()
    ConfigRegistry:RegisterSettings("SubtletyRogue", {
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
            prioritizeFindWeakness = {
                displayName = "Prioritize Find Weakness",
                description = "Prioritize abilities that apply Find Weakness",
                type = "toggle",
                default = true
            },
            useStealthOpener = {
                displayName = "Use Stealth Opener",
                description = "Automatically use stealth opener abilities",
                type = "toggle",
                default = true
            },
            stealthOpenerType = {
                displayName = "Stealth Opener Type",
                description = "Which stealth opener to prioritize",
                type = "dropdown",
                options = {"Shadowstrike", "Cheap Shot"},
                default = "Shadowstrike"
            }
        },
        
        finisherSettings = {
            useEviscerate = {
                displayName = "Use Eviscerate",
                description = "Automatically use Eviscerate as a finisher",
                type = "toggle",
                default = true
            },
            eviscerateCpThreshold = {
                displayName = "Eviscerate Combo Points",
                description = "Minimum combo points to use Eviscerate",
                type = "slider",
                min = 1,
                max = 6,
                default = 5
            },
            useRupture = {
                displayName = "Use Rupture",
                description = "Automatically maintain Rupture",
                type = "toggle",
                default = true
            },
            ruptureComboPoints = {
                displayName = "Rupture Combo Points",
                description = "Minimum combo points to use Rupture",
                type = "slider",
                min = 1,
                max = 6,
                default = 5
            },
            ruptureRefreshThreshold = {
                displayName = "Rupture Refresh Threshold",
                description = "Seconds remaining to refresh Rupture",
                type = "slider",
                min = 1,
                max = 10,
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
            useBlackPowder = {
                displayName = "Use Black Powder",
                description = "Automatically use Black Powder for AoE",
                type = "toggle",
                default = true
            },
            blackPowderComboPoints = {
                displayName = "Black Powder Combo Points",
                description = "Minimum combo points to use Black Powder",
                type = "slider",
                min = 1,
                max = 6,
                default = 4
            },
            blackPowderMinTargets = {
                displayName = "Black Powder Min Targets",
                description = "Minimum targets to use Black Powder",
                type = "slider",
                min = 2,
                max = 8,
                default = 3
            },
            finisherPriority = {
                displayName = "Finisher Priority",
                description = "How to prioritize finishers",
                type = "dropdown",
                options = {"Slice and Dice > Rupture > Eviscerate", "Rupture > Slice and Dice > Eviscerate", "Balanced"},
                default = "Slice and Dice > Rupture > Eviscerate"
            }
        },
        
        cooldownSettings = {
            useSymbolsOfDeath = {
                displayName = "Use Symbols of Death",
                description = "Automatically use Symbols of Death",
                type = "toggle",
                default = true
            },
            symbolsOfDeathMode = {
                displayName = "Symbols of Death Usage",
                description = "When to use Symbols of Death",
                type = "dropdown",
                options = {"On Cooldown", "With Shadow Dance", "Burst Only"},
                default = "On Cooldown"
            },
            useShadowDance = {
                displayName = "Use Shadow Dance",
                description = "Automatically use Shadow Dance",
                type = "toggle",
                default = true
            },
            shadowDanceCharges = {
                displayName = "Shadow Dance Charges to Hold",
                description = "Minimum charges to maintain",
                type = "slider",
                min = 0,
                max = 3,
                default = 1
            },
            useShadowBlades = {
                displayName = "Use Shadow Blades",
                description = "Automatically use Shadow Blades when talented",
                type = "toggle",
                default = true
            },
            shadowBladesMode = {
                displayName = "Shadow Blades Usage",
                description = "When to use Shadow Blades",
                type = "dropdown",
                options = {"On Cooldown", "With Symbols of Death", "Burst Only"},
                default = "With Symbols of Death"
            },
            useSecretTechnique = {
                displayName = "Use Secret Technique",
                description = "Automatically use Secret Technique when talented",
                type = "toggle",
                default = true
            },
            secretTechniqueMode = {
                displayName = "Secret Technique Usage",
                description = "When to use Secret Technique",
                type = "dropdown",
                options = {"On Cooldown", "With Shadow Dance", "With Symbols of Death", "Burst Only"},
                default = "With Shadow Dance"
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
                options = {"With Symbols of Death", "With Shadow Dance", "Burst Only", "Manual Only"},
                default = "With Symbols of Death"
            },
            useShurikenTornado = {
                displayName = "Use Shuriken Tornado",
                description = "Automatically use Shuriken Tornado when talented",
                type = "toggle",
                default = true
            },
            shurikenTornadoMode = {
                displayName = "Shuriken Tornado Usage",
                description = "When to use Shuriken Tornado",
                type = "dropdown",
                options = {"On Cooldown", "AoE Only", "With Shadow Dance", "Burst Only"},
                default = "AoE Only"
            },
            shurikenTornadoMinTargets = {
                displayName = "Shuriken Tornado Min Targets",
                description = "Minimum targets to use Shuriken Tornado",
                type = "slider",
                min = 2,
                max = 8,
                default = 3
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
                options = {"On Cooldown", "With Symbols of Death", "Burst Only"},
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
            useShadowstep = {
                displayName = "Use Shadowstep",
                description = "Automatically use Shadowstep",
                type = "toggle",
                default = true
            },
            shadowstepMode = {
                displayName = "Shadowstep Usage",
                description = "When to use Shadowstep",
                type = "dropdown",
                options = {"Mobility Only", "On Cooldown", "Manual Only"},
                default = "Mobility Only"
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
            autoSap = {
                displayName = "Auto Sap",
                description = "Automatically Sap enemies when in stealth",
                type = "toggle",
                default = false
            }
        },
        
        -- Advanced ability control settings
        abilityControls = {
            -- Shadow Dance controls
            shadowDance = AAC.RegisterAbility(spells.SHADOW_DANCE, {
                enabled = true,
                useDuringBurstOnly = false,
                hoardForSymbols = true,
                requireEnergy = 50
            }),
            
            -- Symbols of Death controls
            symbolsOfDeath = AAC.RegisterAbility(spells.SYMBOLS_OF_DEATH, {
                enabled = true,
                useDuringBurstOnly = false,
                waitForComboPoints = false,
                waitForEnergy = true
            }),
            
            -- Shadow Blades controls
            shadowBlades = AAC.RegisterAbility(spells.SHADOW_BLADES, {
                enabled = true,
                useDuringBurstOnly = false,
                useWithSymbols = true,
                requireFullEnergy = false
            })
        }
    })
    
    return true
end

-- Register for events 
function Subtlety:RegisterEvents()
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
    
    -- Register for spell charges update (for Shadow Dance)
    API.RegisterEvent("SPELL_UPDATE_CHARGES", function(spellID) 
        if spellID == spells.SHADOW_DANCE then
            self:UpdateShadowDanceCharges()
        end
    end)
    
    -- Initial talent info update
    self:UpdateTalentInfo()
    
    -- Initial stealth check
    self:UpdateStealthState()
    
    -- Initial Shadow Dance charges check
    self:UpdateShadowDanceCharges()
    
    return true
end

-- Update talent information
function Subtlety:UpdateTalentInfo()
    -- Check for important talents
    talents.hasShadowTechniques = API.HasTalent(spells.SHADOW_TECHNIQUES)
    talents.hasFindWeakness = API.HasTalent(spells.FIND_WEAKNESS)
    talents.hasPremeditation = API.HasTalent(spells.PREMEDITATION)
    talents.hasShadowFocus = API.HasTalent(spells.SHADOW_FOCUS)
    talents.hasVigor = API.HasTalent(spells.VIGOR)
    talents.hasAlacrity = API.HasTalent(spells.ALACRITY)
    talents.hasDeepeningShows = API.HasTalent(spells.DEEPENING_SHADOWS)
    talents.hasDarkShadow = API.HasTalent(spells.DARK_SHADOW)
    talents.hasSecretStratagem = API.HasTalent(spells.SECRET_STRATAGEM)
    talents.hasSubterfuge = API.HasTalent(spells.SUBTERFUGE)
    talents.hasNightstalker = API.HasTalent(spells.NIGHTSTALKER)
    talents.hasShotInTheDark = API.HasTalent(spells.SHOT_IN_THE_DARK)
    talents.hasImprovedShadowDance = API.HasTalent(spells.IMPROVED_SHADOW_DANCE)
    talents.hasFinality = API.HasTalent(spells.FINALITY)
    talents.hasWeaponmaster = API.HasTalent(spells.WEAPONMASTER)
    talents.hasGloomblade = API.HasTalent(spells.GLOOMBLADE)
    talents.hasAcrobaticStrikes = API.HasTalent(spells.ACROBATIC_STRIKES)
    talents.hasDeeperStratagem = API.HasTalent(spells.DEEPER_STRATAGEM)
    talents.hasVigor = API.HasTalent(spells.VIGOR)
    talents.hasMarkedForDeath = API.HasTalent(spells.MARKED_FOR_DEATH)
    talents.hasDeepeningShows = API.HasTalent(spells.DEEPENING_SHADOWS)
    talents.hasShadowFocus = API.HasTalent(spells.SHADOW_FOCUS)
    talents.hasAkaarisSoulFragment = API.HasTalent(spells.AKAARIS_SOUL_FRAGMENT)
    talents.hasResoundingClarity = API.HasTalent(spells.RESOUNDING_CLARITY)
    talents.hasWeaponDisability = API.HasTalent(spells.WEAPON_DISABILITY)
    talents.hasSecretStash = API.HasTalent(spells.SECRET_STASH)
    talents.hasColdBlood = API.HasTalent(spells.COLD_BLOOD)
    talents.hasImprovedAmbush = API.HasTalent(spells.IMPROVED_AMBUSH)
    talents.hasSealFate = API.HasTalent(spells.SEAL_FATE)
    talents.hasPreyOnTheWeak = API.HasTalent(spells.PREY_ON_THE_WEAK)
    talents.hasBlindside = API.HasTalent(spells.BLINDSIDE)
    talents.hasSoothingDarkness = API.HasTalent(spells.SOOTHING_DARKNESS)
    talents.hasThistleTea = API.HasTalent(spells.THISTLE_TEA)
    talents.hasNightTerrors = API.HasTalent(spells.NIGHT_TERRORS)
    talents.hasEchoingReprimand = API.HasTalent(spells.ECHOING_REPRIMAND)
    talents.hasSepsis = API.HasTalent(spells.SEPSIS)
    talents.hasDarkBrew = API.HasTalent(spells.DARK_BREW)
    talents.hasShadowBlades = API.HasTalent(spells.SHADOW_BLADES)
    talents.hasSecretTechnique = API.HasTalent(spells.SECRET_TECHNIQUE)
    talents.hasShurikenTornado = API.HasTalent(spells.SHURIKEN_TORNADO)
    
    -- War Within Season 2 talents
    talents.hasPerforatedVeins = API.HasTalent(spells.PERFORATED_VEINS)
    talents.hasDeeperShadows = API.HasTalent(spells.DEEPER_SHADOWS)
    talents.hasSymbolicPower = API.HasTalent(spells.SYMBOLIC_POWER)
    talents.hasDanseMacabre = API.HasTalent(spells.DANSE_MACABRE)
    talents.hasShadowcraft = API.HasTalent(spells.SHADOWCRAFT)
    talents.hasShadowstrikeOutOfStealth = API.HasTalent(spells.SHADOWSTRIKE_OUT_OF_STEALTH)
    talents.hasDanceOfShadows = API.HasTalent(spells.DANCE_OF_SHADOWS)
    
    -- Adjust max combo points based on talents
    if talents.hasDeeperStratagem then
        maxComboPoints = 6
    else
        maxComboPoints = 5
    end
    
    -- Set specialized variables based on talents
    if talents.hasShadowTechniques then
        shadowTechniquesActive = true
    end
    
    if talents.hasFindWeakness then
        findWeaknessActive = true
    end
    
    if talents.hasPremeditation then
        premeditation = true
    end
    
    if talents.hasShadowFocus then
        shadowFocus = true
    end
    
    if talents.hasVigor then
        vigor = true
    end
    
    if talents.hasMarkedForDeath then
        markedForDeath = true
    end
    
    if talents.hasDeepeningShows then
        deepeningShadows = true
    end
    
    if talents.hasAkaarisSoulFragment then
        akaaris = true
    end
    
    if talents.hasWeaponDisability then
        weaponDisability = true
    end
    
    if talents.hasSecretStash then
        secretStash = true
    end
    
    if talents.hasSecretStratagem then
        secretStratagem = true
    end
    
    if talents.hasSubterfuge then
        subterfugeTalent = true
    end
    
    if talents.hasDarkShadow then
        darkShadow = true
    end
    
    if talents.hasColdBlood then
        coldBlood = true
    end
    
    if talents.hasEchoingReprimand then
        echoing = true
    end
    
    if talents.hasSealFate then
        sealFate = true
    end
    
    if talents.hasPreyOnTheWeak then
        prey = true
    end
    
    if talents.hasBlindside then
        blindside = true
    end
    
    if talents.hasSoothingDarkness then
        soothingDarkness = true
    end
    
    if talents.hasNightTerrors then
        nightTerrors = true
    end
    
    if API.IsSpellKnown(spells.BACKSTAB) then
        backstab = true
    end
    
    if talents.hasGloomblade then
        gloomblade = true
        gloomy = true
    end
    
    if API.IsSpellKnown(spells.SHURIKEN_STORM) then
        shurikenStorm = true
    end
    
    if API.IsSpellKnown(spells.BLACK_POWDER) then
        blackPowder = true
    end
    
    if API.IsSpellKnown(spells.EVISCERATE) then
        eviscerate = true
    end
    
    if API.IsSpellKnown(spells.RUPTURE) then
        rupture = true
    end
    
    if API.IsSpellKnown(spells.SHADOWSTRIKE) then
        shadowstrike = true
    end
    
    if API.IsSpellKnown(spells.CHEAP_SHOT) then
        cheapShot = true
    end
    
    if API.IsSpellKnown(spells.KIDNEY_SHOT) then
        kidney = true
    end
    
    if API.IsSpellKnown(spells.SHADOWSTEP) then
        shadowstep = true
    end
    
    if talents.hasShurikenTornado then
        shurikenTornado = true
    end
    
    if talents.hasDarkBrew then
        darkBrew = true
    end
    
    if talents.hasShadowcraft then
        shadowCraft = true
    end
    
    if talents.hasAcrobaticStrikes then
        acrobaticStrikes = true
    end
    
    if talents.hasDeeperStratagem then
        deeperStratagem = true
    end
    
    if talents.hasDeeperShadows then
        deeperShadowsActive = true
    end
    
    if talents.hasShadowBlades then
        shadowBlades = true
    end
    
    if talents.hasSecretTechnique then
        secret = true
    end
    
    if talents.hasSepsis then
        sepsis = true
    end
    
    if API.IsPvPTalentActive(spells.FLAGELLATION) then
        flagellation = true
    end
    
    if talents.hasShadowstrikeOutOfStealth then
        shadowStrikeOutOfStealth = true
    end
    
    -- Update Shadow Dance charges
    shadowDanceCharges = API.GetSpellCharges(spells.SHADOW_DANCE) or 0
    shadowDanceMaxCharges = API.GetSpellMaxCharges(spells.SHADOW_DANCE) or 2
    
    API.PrintDebug("Subtlety Rogue talents updated")
    
    return true
end

-- Update energy tracking
function Subtlety:UpdateEnergy()
    currentEnergy = API.GetPlayerPower()
    return true
end

-- Update combo points tracking
function Subtlety:UpdateComboPoints()
    currentComboPoints = API.GetPlayerComboPoints()
    return true
end

-- Update stealth state
function Subtlety:UpdateStealthState()
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

-- Update Shadow Dance charges
function Subtlety:UpdateShadowDanceCharges()
    shadowDanceCharges, shadowDanceMaxCharges = API.GetSpellCharges(spells.SHADOW_DANCE)
    return true
end

-- Update target data
function Subtlety:UpdateTargetData()
    -- Check if in melee range
    inMeleeRange = API.IsUnitInRange("target", acrobaticStrikes and (MELEE_RANGE + ACROBATIC_STRIKES_RANGE) or MELEE_RANGE)
    
    -- Get target GUID
    local targetGUID = API.GetTargetGUID()
    
    -- Update target health
    if targetGUID and targetGUID ~= "" then
        targetHealth = API.GetTargetHealthPercent()
        
        -- Check for Find Weakness
        if talents.hasFindWeakness then
            local findWeaknessInfo = API.GetDebuffInfo(targetGUID, debuffs.FIND_WEAKNESS)
            if findWeaknessInfo then
                findWeaknessActive[targetGUID] = true
                findWeaknessEndTime[targetGUID] = select(6, findWeaknessInfo)
            else
                findWeaknessActive[targetGUID] = false
                findWeaknessEndTime[targetGUID] = 0
            end
        end
        
        -- Check for Rupture
        local ruptureInfo = API.GetDebuffInfo(targetGUID, debuffs.RUPTURE)
        if ruptureInfo then
            ruptureActive[targetGUID] = true
            ruptureEndTime[targetGUID] = select(6, ruptureInfo)
        else
            ruptureActive[targetGUID] = false
            ruptureEndTime[targetGUID] = 0
        end
    end
    
    -- Update AoE targets count
    currentAoETargets = API.GetNearbyEnemiesCount(8) -- Shuriken Storm radius
    
    -- Calculate black powder target count (within Shuriken Storm radius with Rupture)
    numBlackPowderTargets = 0
    for guid, active in pairs(ruptureActive) do
        if active and ruptureEndTime[guid] > GetTime() then
            numBlackPowderTargets = numBlackPowderTargets + 1
        end
    end
    
    return true
end

-- Handle combat log events
function Subtlety:HandleCombatLogEvent(...)
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
            
            -- Track Symbols of Death
            if spellID == buffs.SYMBOLS_OF_DEATH then
                symbolsOfDeathActive = true
                symbolsOfDeathEndTime = select(6, API.GetBuffInfo("player", buffs.SYMBOLS_OF_DEATH))
                API.PrintDebug("Symbols of Death activated")
            end
            
            -- Track Shadow Techniques
            if spellID == buffs.SHADOW_TECHNIQUES then
                shadowTechniquesActive = true
                shadowTechniquesEndTime = select(6, API.GetBuffInfo("player", buffs.SHADOW_TECHNIQUES))
                shadowTechniquesCount = select(4, API.GetBuffInfo("player", buffs.SHADOW_TECHNIQUES)) or 1
                API.PrintDebug("Shadow Techniques activated: " .. tostring(shadowTechniquesCount) .. " stacks")
            end
            
            -- Track Dance of Shadows
            if spellID == buffs.DANCE_OF_SHADOWS then
                danceOfShadowsActive = true
                danceOfShadowsEndTime = select(6, API.GetBuffInfo("player", buffs.DANCE_OF_SHADOWS))
                API.PrintDebug("Dance of Shadows activated")
            end
            
            -- Track Flagellation
            if spellID == buffs.FLAGELLATION then
                flagellationActive = true
                flagellationEndTime = select(6, API.GetBuffInfo("player", buffs.FLAGELLATION))
                flagellationCount = select(4, API.GetBuffInfo("player", buffs.FLAGELLATION)) or 1
                API.PrintDebug("Flagellation activated: " .. tostring(flagellationCount) .. " stacks")
            end
            
            -- Track Shadow Blades
            if spellID == buffs.SHADOW_BLADES then
                shadowBladesActive = true
                shadowBladesEndTime = select(6, API.GetBuffInfo("player", buffs.SHADOW_BLADES))
                API.PrintDebug("Shadow Blades activated")
            end
            
            -- Track Premeditation
            if spellID == buffs.PREMEDITATION then
                premedProcActive = true
                premedProcEndTime = select(6, API.GetBuffInfo("player", buffs.PREMEDITATION))
                API.PrintDebug("Premeditation proc activated")
            end
            
            -- Track Symbolic Power
            if spellID == buffs.SYMBOLIC_POWER then
                symbolicPowerActive = true
                symbolicPowerEndTime = select(6, API.GetBuffInfo("player", buffs.SYMBOLIC_POWER))
                symbolicPowerStacks = select(4, API.GetBuffInfo("player", buffs.SYMBOLIC_POWER)) or 1
                API.PrintDebug("Symbolic Power activated: " .. tostring(symbolicPowerStacks) .. " stacks")
            end
            
            -- Track Perforated Veins
            if spellID == buffs.PERFORATED_VEINS then
                perforatedVeinsActive = true
                perforatedVeinsEndTime = select(6, API.GetBuffInfo("player", buffs.PERFORATED_VEINS))
                perforatedVeinsStacks = select(4, API.GetBuffInfo("player", buffs.PERFORATED_VEINS)) or 1
                API.PrintDebug("Perforated Veins activated: " .. tostring(perforatedVeinsStacks) .. " stacks")
            end
            
            -- Track Sepsis
            if spellID == buffs.SEPSIS then
                sepsisActive = true
                sepsisEndTime = select(6, API.GetBuffInfo("player", buffs.SEPSIS))
                API.PrintDebug("Sepsis activated")
            end
            
            -- Track Shuriken Tornado
            if spellID == buffs.SHURIKEN_TORNADO then
                shurikenTornadoActive = true
                shurikenTornadoEndTime = select(6, API.GetBuffInfo("player", buffs.SHURIKEN_TORNADO))
                API.PrintDebug("Shuriken Tornado activated")
            end
            
            -- Track Cold Blood
            if spellID == buffs.COLD_BLOOD then
                API.PrintDebug("Cold Blood activated")
            end
            
            -- Track Stealth
            if spellID == buffs.STEALTH then
                stealth = true
                API.PrintDebug("Stealth activated")
            end
            
            -- Track Finality buffs
            if spellID == buffs.FINALITY_EVISCERATE then
                finality.eviscerate = true
                finalityEndTime.eviscerate = select(6, API.GetBuffInfo("player", buffs.FINALITY_EVISCERATE))
                API.PrintDebug("Finality: Eviscerate activated")
            elseif spellID == buffs.FINALITY_BLACK_POWDER then
                finality.blackPowder = true
                finalityEndTime.blackPowder = select(6, API.GetBuffInfo("player", buffs.FINALITY_BLACK_POWDER))
                API.PrintDebug("Finality: Black Powder activated")
            elseif spellID == buffs.FINALITY_RUPTURE then
                finality.rupture = true
                finalityEndTime.rupture = select(6, API.GetBuffInfo("player", buffs.FINALITY_RUPTURE))
                API.PrintDebug("Finality: Rupture activated")
            end
        end
        
        -- Track debuffs on any target
        if sourceGUID == API.GetPlayerGUID() then
            -- Track Find Weakness
            if spellID == debuffs.FIND_WEAKNESS then
                findWeaknessActive[destGUID] = true
                findWeaknessEndTime[destGUID] = select(6, API.GetDebuffInfo(destGUID, debuffs.FIND_WEAKNESS))
                API.PrintDebug("Find Weakness applied to " .. destName)
            end
            
            -- Track Rupture
            if spellID == debuffs.RUPTURE then
                ruptureActive[destGUID] = true
                ruptureEndTime[destGUID] = select(6, API.GetDebuffInfo(destGUID, debuffs.RUPTURE))
                API.PrintDebug("Rupture applied to " .. destName)
            end
            
            -- Track Flagellation
            if spellID == debuffs.FLAGELLATION then
                API.PrintDebug("Flagellation applied to " .. destName)
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
            
            -- Track Symbols of Death
            if spellID == buffs.SYMBOLS_OF_DEATH then
                symbolsOfDeathActive = false
                API.PrintDebug("Symbols of Death faded")
            end
            
            -- Track Shadow Techniques
            if spellID == buffs.SHADOW_TECHNIQUES then
                shadowTechniquesActive = false
                shadowTechniquesCount = 0
                API.PrintDebug("Shadow Techniques faded")
            end
            
            -- Track Dance of Shadows
            if spellID == buffs.DANCE_OF_SHADOWS then
                danceOfShadowsActive = false
                API.PrintDebug("Dance of Shadows faded")
            end
            
            -- Track Flagellation
            if spellID == buffs.FLAGELLATION then
                flagellationActive = false
                flagellationCount = 0
                API.PrintDebug("Flagellation faded")
            end
            
            -- Track Shadow Blades
            if spellID == buffs.SHADOW_BLADES then
                shadowBladesActive = false
                API.PrintDebug("Shadow Blades faded")
            end
            
            -- Track Premeditation
            if spellID == buffs.PREMEDITATION then
                premedProcActive = false
                API.PrintDebug("Premeditation proc faded")
            end
            
            -- Track Symbolic Power
            if spellID == buffs.SYMBOLIC_POWER then
                symbolicPowerActive = false
                symbolicPowerStacks = 0
                API.PrintDebug("Symbolic Power faded")
            end
            
            -- Track Perforated Veins
            if spellID == buffs.PERFORATED_VEINS then
                perforatedVeinsActive = false
                perforatedVeinsStacks = 0
                API.PrintDebug("Perforated Veins faded")
            end
            
            -- Track Sepsis
            if spellID == buffs.SEPSIS then
                sepsisActive = false
                API.PrintDebug("Sepsis faded")
            end
            
            -- Track Shuriken Tornado
            if spellID == buffs.SHURIKEN_TORNADO then
                shurikenTornadoActive = false
                API.PrintDebug("Shuriken Tornado faded")
            end
            
            -- Track Stealth
            if spellID == buffs.STEALTH then
                stealth = false
                API.PrintDebug("Stealth faded")
            end
            
            -- Track Finality buffs
            if spellID == buffs.FINALITY_EVISCERATE then
                finality.eviscerate = false
                API.PrintDebug("Finality: Eviscerate faded")
            elseif spellID == buffs.FINALITY_BLACK_POWDER then
                finality.blackPowder = false
                API.PrintDebug("Finality: Black Powder faded")
            elseif spellID == buffs.FINALITY_RUPTURE then
                finality.rupture = false
                API.PrintDebug("Finality: Rupture faded")
            end
        end
        
        -- Track debuff removals
        if sourceGUID == API.GetPlayerGUID() then
            -- Track Find Weakness
            if spellID == debuffs.FIND_WEAKNESS and findWeaknessActive[destGUID] then
                findWeaknessActive[destGUID] = false
                API.PrintDebug("Find Weakness faded from " .. destName)
            end
            
            -- Track Rupture
            if spellID == debuffs.RUPTURE and ruptureActive[destGUID] then
                ruptureActive[destGUID] = false
                API.PrintDebug("Rupture faded from " .. destName)
            end
        end
    end
    
    -- Track Shadow Techniques stacks gain
    if eventType == "SPELL_AURA_APPLIED_DOSE" and spellID == buffs.SHADOW_TECHNIQUES and destGUID == API.GetPlayerGUID() then
        shadowTechniquesCount = select(4, API.GetBuffInfo("player", buffs.SHADOW_TECHNIQUES)) or 0
        API.PrintDebug("Shadow Techniques stacks: " .. tostring(shadowTechniquesCount))
    end
    
    -- Track Symbolic Power stacks gain
    if eventType == "SPELL_AURA_APPLIED_DOSE" and spellID == buffs.SYMBOLIC_POWER and destGUID == API.GetPlayerGUID() then
        symbolicPowerStacks = select(4, API.GetBuffInfo("player", buffs.SYMBOLIC_POWER)) or 0
        API.PrintDebug("Symbolic Power stacks: " .. tostring(symbolicPowerStacks))
    end
    
    -- Track Perforated Veins stacks gain
    if eventType == "SPELL_AURA_APPLIED_DOSE" and spellID == buffs.PERFORATED_VEINS and destGUID == API.GetPlayerGUID() then
        perforatedVeinsStacks = select(4, API.GetBuffInfo("player", buffs.PERFORATED_VEINS)) or 0
        API.PrintDebug("Perforated Veins stacks: " .. tostring(perforatedVeinsStacks))
    end
    
    -- Track Flagellation stacks gain
    if eventType == "SPELL_AURA_APPLIED_DOSE" and spellID == buffs.FLAGELLATION and destGUID == API.GetPlayerGUID() then
        flagellationCount = select(4, API.GetBuffInfo("player", buffs.FLAGELLATION)) or 0
        API.PrintDebug("Flagellation stacks: " .. tostring(flagellationCount))
    end
    
    -- Track spell casts
    if eventType == "SPELL_CAST_SUCCESS" then
        if sourceGUID == API.GetPlayerGUID() then
            if spellID == spells.BACKSTAB or spellID == spells.GLOOMBLADE then
                backstabActive = true
                API.PrintDebug((spellID == spells.BACKSTAB) and "Backstab cast" or "Gloomblade cast")
            elseif spellID == spells.SHADOWSTRIKE then
                API.PrintDebug("Shadowstrike cast")
            elseif spellID == spells.SHURIKEN_STORM then
                lastShurikenStorm = GetTime()
                API.PrintDebug("Shuriken Storm cast")
            elseif spellID == spells.EVISCERATE then
                lastEvis = GetTime()
                API.PrintDebug("Eviscerate cast")
            elseif spellID == spells.RUPTURE then
                API.PrintDebug("Rupture cast")
            elseif spellID == spells.BLACK_POWDER then
                API.PrintDebug("Black Powder cast")
            elseif spellID == spells.SLICE_AND_DICE then
                lastSliceAndDice = GetTime()
                API.PrintDebug("Slice and Dice cast")
            elseif spellID == spells.SYMBOLS_OF_DEATH then
                lastSymbolsOfDeath = GetTime()
                symbolsOfDeathActive = true
                symbolsOfDeathEndTime = GetTime() + SYMBOLS_OF_DEATH_DURATION
                API.PrintDebug("Symbols of Death cast")
            elseif spellID == spells.SHADOW_DANCE then
                lastShadowDance = GetTime()
                shadowDanceActive = true
                shadowDanceEndTime = GetTime() + SHADOW_DANCE_DURATION
                shadowDanceCharges = shadowDanceCharges - 1
                API.PrintDebug("Shadow Dance cast, charges remaining: " .. tostring(shadowDanceCharges))
            elseif spellID == spells.SHADOW_BLADES then
                shadowBladesActive = true
                shadowBladesEndTime = GetTime() + SHADOW_BLADES_DURATION
                API.PrintDebug("Shadow Blades cast")
            elseif spellID == spells.SECRET_TECHNIQUE then
                secretActive = true
                secretEndTime = GetTime() + SECRET_TECHNIQUE_DURATION
                API.PrintDebug("Secret Technique cast")
            elseif spellID == spells.SHURIKEN_TORNADO then
                lastShurikenTornado = GetTime()
                shurikenTornadoActive = true
                shurikenTornadoEndTime = GetTime() + SHURIKEN_TORNADO_DURATION
                API.PrintDebug("Shuriken Tornado cast")
            elseif spellID == spells.VANISH then
                API.PrintDebug("Vanish cast")
                inStealth = true
            elseif spellID == spells.SEPSIS then
                sepsisActive = true
                sepsisEndTime = GetTime() + SEPSIS_DURATION
                API.PrintDebug("Sepsis cast")
            end
        end
    end
    
    -- Track Find Weakness application from stealth abilities
    if eventType == "SPELL_DAMAGE" and sourceGUID == API.GetPlayerGUID() then
        if (spellID == spells.SHADOWSTRIKE or 
            spellID == spells.CHEAP_SHOT or 
            (spellID == spells.BACKSTAB and inStealth) or 
            (spellID == spells.GLOOMBLADE and inStealth)) then
            
            -- Update Find Weakness for this target
            if talents.hasFindWeakness then
                findWeaknessActive[destGUID] = true
                findWeaknessEndTime[destGUID] = GetTime() + FIND_WEAKNESS_DURATION
                API.PrintDebug("Find Weakness applied to " .. destName .. " from stealth ability")
            end
        end
    end
    
    return true
end

-- Main rotation function
function Subtlety:RunRotation()
    -- Check if we should be running Subtlety Rogue logic
    if API.GetActiveSpecID() ~= SUBTLETY_SPEC_ID then
        return false
    end
    
    -- Skip rotation if player is casting
    if API.IsPlayerCasting() then
        return false
    end
    
    -- Get settings
    local settings = ConfigRegistry:GetSettings("SubtletyRogue")
    
    -- Update variables
    self:UpdateEnergy()
    self:UpdateComboPoints()
    burstModeActive = settings.rotationSettings.burstEnabled and API.ShouldUseBurst()
    self:UpdateTargetData() -- Makes sure we have current target information
    
    -- Pre-calculate if Slice and Dice, Symbols, and Rupture need refreshing
    refreshableSliceAndDice = sliceAndDiceActive and sliceAndDiceEndTime - GetTime() < settings.finisherSettings.sliceAndDiceRefreshThreshold
    refreshableSymbolsOfDeath = symbolsOfDeathActive and symbolsOfDeathEndTime - GetTime() < 3 -- 3 seconds threshold for Symbols refresh
    
    local targetGUID = API.GetTargetGUID()
    refreshableRupture = targetGUID and ruptureActive[targetGUID] and 
                         ruptureEndTime[targetGUID] - GetTime() < settings.finisherSettings.ruptureRefreshThreshold
    
    -- Check if in opener sequence
    inOpener = API.IsInCombat() and GetTime() - API.GetCombatTime() < 10 -- Consider first 10 seconds as opener
    
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
        
        if settings.rotationSettings.poisonType == "Instant Poison" then
            poisonToUse = spells.INSTANT_POISON
        elseif settings.rotationSettings.poisonType == "Wound Poison" then
            poisonToUse = spells.WOUND_POISON
        elseif settings.rotationSettings.poisonType == "Crippling Poison" then
            poisonToUse = spells.CRIPPLING_POISON
        elseif settings.rotationSettings.poisonType == "Numbing Poison" then
            poisonToUse = spells.NUMBING_POISON
        elseif settings.rotationSettings.poisonType == "Atrophic Poison" then
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
    
    -- Handle cooldowns first
    if self:HandleCooldowns(settings) then
        return true
    end
    
    -- Slice and Dice maintenance
    if settings.finisherSettings.useSliceAndDice and
       (not sliceAndDiceActive or refreshableSliceAndDice) and
       currentComboPoints >= settings.finisherSettings.sliceAndDiceComboPoints and
       API.CanCast(spells.SLICE_AND_DICE) then
        API.CastSpell(spells.SLICE_AND_DICE)
        return true
    end
    
    -- Skip if not in melee range
    if not inMeleeRange then
        return false
    end
    
    -- Check for AoE or Single Target
    if settings.rotationSettings.aoeEnabled and currentAoETargets >= settings.rotationSettings.aoeThreshold then
        return self:HandleAoERotation(settings)
    else
        return self:HandleSingleTargetRotation(settings)
    end
end

-- Handle interrupts
function Subtlety:HandleInterrupts(settings)
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
function Subtlety:HandleDefensives(settings)
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
function Subtlety:HandleCooldowns(settings)
    -- Skip if not in combat
    if not API.IsInCombat() then
        return false
    end
    
    -- Get target GUID
    local targetGUID = API.GetTargetGUID()
    
    -- Use Symbols of Death
    if settings.cooldownSettings.useSymbolsOfDeath and
       settings.abilityControls.symbolsOfDeath.enabled and
       not symbolsOfDeathActive and
       API.CanCast(spells.SYMBOLS_OF_DEATH) then
        
        -- Check if should only use during burst
        if not settings.abilityControls.symbolsOfDeath.useDuringBurstOnly or burstModeActive then
            -- Check additional requirements
            local shouldUseSymbols = false
            
            if settings.cooldownSettings.symbolsOfDeathMode == "On Cooldown" then
                shouldUseSymbols = true
            elseif settings.cooldownSettings.symbolsOfDeathMode == "With Shadow Dance" then
                shouldUseSymbols = shadowDanceActive
            elseif settings.cooldownSettings.symbolsOfDeathMode == "Burst Only" then
                shouldUseSymbols = burstModeActive
            end
            
            if settings.abilityControls.symbolsOfDeath.waitForComboPoints and currentComboPoints < 4 then
                shouldUseSymbols = false
            end
            
            if settings.abilityControls.symbolsOfDeath.waitForEnergy and currentEnergy < 40 then
                shouldUseSymbols = false
            end
            
            if shouldUseSymbols then
                API.CastSpell(spells.SYMBOLS_OF_DEATH)
                return true
            end
        end
    end
    
    -- Use Shadow Dance
    if settings.cooldownSettings.useShadowDance and
       settings.abilityControls.shadowDance.enabled and
       not shadowDanceActive and
       shadowDanceCharges > settings.cooldownSettings.shadowDanceCharges and -- Only use if we have more charges than we want to hold
       API.CanCast(spells.SHADOW_DANCE) then
        
        -- Check if should only use during burst
        if not settings.abilityControls.shadowDance.useDuringBurstOnly or burstModeActive then
            -- Check additional requirements
            if settings.abilityControls.shadowDance.hoardForSymbols and
               API.GetSpellCooldown(spells.SYMBOLS_OF_DEATH) < 3 then
                -- Save for Symbols of Death
                return false
            end
            
            if settings.abilityControls.shadowDance.requireEnergy and currentEnergy < settings.abilityControls.shadowDance.requireEnergy then
                return false
            end
            
            API.CastSpell(spells.SHADOW_DANCE)
            return true
        end
    end
    
    -- Use Shadow Blades
    if shadowBlades and
       settings.cooldownSettings.useShadowBlades and
       settings.abilityControls.shadowBlades.enabled and
       not shadowBladesActive and
       API.CanCast(spells.SHADOW_BLADES) then
        
        -- Check if should only use during burst
        if not settings.abilityControls.shadowBlades.useDuringBurstOnly or burstModeActive then
            -- Check additional requirements
            local shouldUseShadowBlades = false
            
            if settings.cooldownSettings.shadowBladesMode == "On Cooldown" then
                shouldUseShadowBlades = true
            elseif settings.cooldownSettings.shadowBladesMode == "With Symbols of Death" then
                shouldUseShadowBlades = symbolsOfDeathActive
            elseif settings.cooldownSettings.shadowBladesMode == "Burst Only" then
                shouldUseShadowBlades = burstModeActive
            end
            
            if settings.abilityControls.shadowBlades.useWithSymbols and not symbolsOfDeathActive then
                shouldUseShadowBlades = false
            end
            
            if settings.abilityControls.shadowBlades.requireFullEnergy and currentEnergy < 80 then
                shouldUseShadowBlades = false
            end
            
            if shouldUseShadowBlades then
                API.CastSpell(spells.SHADOW_BLADES)
                return true
            end
        end
    end
    
    -- Use Secret Technique
    if secret and
       settings.cooldownSettings.useSecretTechnique and
       not secretActive and
       API.CanCast(spells.SECRET_TECHNIQUE) then
        
        local shouldUseSecretTechnique = false
        
        if settings.cooldownSettings.secretTechniqueMode == "On Cooldown" then
            shouldUseSecretTechnique = true
        elseif settings.cooldownSettings.secretTechniqueMode == "With Shadow Dance" then
            shouldUseSecretTechnique = shadowDanceActive
        elseif settings.cooldownSettings.secretTechniqueMode == "With Symbols of Death" then
            shouldUseSecretTechnique = symbolsOfDeathActive
        elseif settings.cooldownSettings.secretTechniqueMode == "Burst Only" then
            shouldUseSecretTechnique = burstModeActive
        end
        
        if shouldUseSecretTechnique and currentComboPoints >= 4 then
            API.CastSpell(spells.SECRET_TECHNIQUE)
            return true
        end
    end
    
    -- Use Shuriken Tornado
    if shurikenTornado and
       settings.cooldownSettings.useShurikenTornado and
       not shurikenTornadoActive and
       API.CanCast(spells.SHURIKEN_TORNADO) then
        
        local shouldUseShurikenTornado = false
        
        if settings.cooldownSettings.shurikenTornadoMode == "On Cooldown" then
            shouldUseShurikenTornado = true
        elseif settings.cooldownSettings.shurikenTornadoMode == "AoE Only" then
            shouldUseShurikenTornado = currentAoETargets >= settings.cooldownSettings.shurikenTornadoMinTargets
        elseif settings.cooldownSettings.shurikenTornadoMode == "With Shadow Dance" then
            shouldUseShurikenTornado = shadowDanceActive
        elseif settings.cooldownSettings.shurikenTornadoMode == "Burst Only" then
            shouldUseShurikenTornado = burstModeActive
        end
        
        if shouldUseShurikenTornado then
            API.CastSpell(spells.SHURIKEN_TORNADO)
            return true
        end
    end
    
    -- Use Vanish
    if settings.cooldownSettings.useVanish and
       not inStealth and
       not shadowDanceActive and
       not subterfugeActive and
       API.CanCast(spells.VANISH) then
        
        local shouldUseVanish = false
        
        if settings.cooldownSettings.vanishMode == "With Symbols of Death" then
            shouldUseVanish = symbolsOfDeathActive
        elseif settings.cooldownSettings.vanishMode == "With Shadow Dance" then
            shouldUseVanish = shadowDanceActive
        elseif settings.cooldownSettings.vanishMode == "Burst Only" then
            shouldUseVanish = burstModeActive
        end
        
        if shouldUseVanish then
            API.CastSpell(spells.VANISH)
            return true
        end
    end
    
    -- Use Sepsis
    if sepsis and
       settings.cooldownSettings.useSepsis and
       not sepsisActive and
       API.CanCast(spells.SEPSIS) then
        
        local shouldUseSepsis = false
        
        if settings.cooldownSettings.sepsisMode == "On Cooldown" then
            shouldUseSepsis = true
        elseif settings.cooldownSettings.sepsisMode == "With Symbols of Death" then
            shouldUseSepsis = symbolsOfDeathActive
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
function Subtlety:HandleStealthRotation(settings)
    -- Get target GUID
    local targetGUID = API.GetTargetGUID()
    
    -- Skip if no target or not in melee range
    if not targetGUID or not inMeleeRange then
        return false
    end
    
    -- If using Sap is enabled and we're in pure stealth (not dance or subterfuge)
    if settings.utilitySettings.autoSap and
       stealth and
       not shadowDanceActive and
       not subterfugeActive and
       not API.UnitIsPlayer("target") and
       not API.UnitIsTapDenied("target") and
       API.CanCast(spells.SAP) then
        API.CastSpell(spells.SAP)
        return true
    end
    
    -- Check if we have Find Weakness on target already
    local needFindWeakness = settings.rotationSettings.prioritizeFindWeakness and
                            (not findWeaknessActive[targetGUID] or findWeaknessEndTime[targetGUID] - GetTime() < 3)
    
    -- Use stealth openers based on settings
    if settings.rotationSettings.useStealthOpener then
        if shadowstrike and
           (settings.rotationSettings.stealthOpenerType == "Shadowstrike" or needFindWeakness) and
           API.CanCast(spells.SHADOWSTRIKE) then
            API.CastSpell(spells.SHADOWSTRIKE)
            return true
        elseif cheapShot and
               settings.rotationSettings.stealthOpenerType == "Cheap Shot" and
               API.CanCast(spells.CHEAP_SHOT) then
            API.CastSpell(spells.CHEAP_SHOT)
            return true
        end
    end
    
    -- Default to Shadowstrike if available
    if shadowstrike and API.CanCast(spells.SHADOWSTRIKE) then
        API.CastSpell(spells.SHADOWSTRIKE)
        return true
    end
    
    return false
end

-- Handle AoE rotation
function Subtlety:HandleAoERotation(settings)
    -- Use Black Powder at high combo points if targets are bleeding from Rupture
    if settings.finisherSettings.useBlackPowder and
       blackPowder and
       numBlackPowderTargets >= settings.finisherSettings.blackPowderMinTargets and
       currentComboPoints >= settings.finisherSettings.blackPowderComboPoints and
       API.CanCast(spells.BLACK_POWDER) then
        API.CastSpell(spells.BLACK_POWDER)
        return true
    end
    
    -- Apply and maintain Rupture on multiple targets
    if settings.finisherSettings.useRupture and
       currentComboPoints >= settings.finisherSettings.ruptureComboPoints then
        
        local targetGUID = API.GetTargetGUID()
        
        if targetGUID and
           (not ruptureActive[targetGUID] || 
            (ruptureActive[targetGUID] and 
             ruptureEndTime[targetGUID] - GetTime() < settings.finisherSettings.ruptureRefreshThreshold)) and
           API.CanCast(spells.RUPTURE) then
            API.CastSpell(spells.RUPTURE)
            return true
        end
    end
    
    -- Use Shuriken Storm to generate combo points in AoE
    if shurikenStorm and API.CanCast(spells.SHURIKEN_STORM) then
        -- Check if we're pooling energy
        if not settings.rotationSettings.energyPooling or
           currentEnergy >= settings.rotationSettings.energyPoolingThreshold or
           currentComboPoints == 0 then
            API.CastSpell(spells.SHURIKEN_STORM)
            return true
        end
    end
    
    -- Use Eviscerate as a backup finisher if Black Powder can't be used
    if settings.finisherSettings.useEviscerate and
       eviscerate and
       currentComboPoints >= settings.finisherSettings.eviscerateCpThreshold and
       API.CanCast(spells.EVISCERATE) then
        API.CastSpell(spells.EVISCERATE)
        return true
    end
    
    -- Use Shadowstrike if available with Shadow Dance/Subterfuge
    if shadowstrike and 
       (shadowDanceActive or subterfugeActive) and
       API.CanCast(spells.SHADOWSTRIKE) then
        API.CastSpell(spells.SHADOWSTRIKE)
        return true
    end
    
    return false
end

-- Handle Single Target rotation
function Subtlety:HandleSingleTargetRotation(settings)
    -- Get target GUID
    local targetGUID = API.GetTargetGUID()
    
    -- Check for the Shadowstrike out of stealth window
    if shadowStrikeOutOfStealth and
       GetTime() - lastShadowDance < 10 and -- We used Shadow Dance in the last 10 seconds
       not shadowDanceActive and not subterfugeActive and not inStealth and -- We're not currently in stealth
       API.CanCast(spells.SHADOWSTRIKE) then
        API.CastSpell(spells.SHADOWSTRIKE)
        return true
    end
    
    -- Apply and maintain Rupture
    if settings.finisherSettings.useRupture and
       targetGUID and
       currentComboPoints >= settings.finisherSettings.ruptureComboPoints and
       (not ruptureActive[targetGUID] || 
        (ruptureActive[targetGUID] and 
         ruptureEndTime[targetGUID] - GetTime() < settings.finisherSettings.ruptureRefreshThreshold)) and
       API.CanCast(spells.RUPTURE) then
        API.CastSpell(spells.RUPTURE)
        return true
    end
    
    -- Use Eviscerate as a finisher
    if settings.finisherSettings.useEviscerate and
       eviscerate and
       currentComboPoints >= settings.finisherSettings.eviscerateCpThreshold and
       (targetGUID and ruptureActive[targetGUID]) and -- Make sure Rupture is active
       API.CanCast(spells.EVISCERATE) then
        API.CastSpell(spells.EVISCERATE)
        return true
    end
    
    -- Use Shadowstrike if available with Shadow Dance/Subterfuge
    if shadowstrike and 
       (shadowDanceActive or subterfugeActive) and
       API.CanCast(spells.SHADOWSTRIKE) then
        API.CastSpell(spells.SHADOWSTRIKE)
        return true
    end
    
    -- Use Backstab/Gloomblade as a builder
    if (backstab and API.CanCast(spells.BACKSTAB)) or 
       (gloomy and API.CanCast(spells.GLOOMBLADE)) then
        
        -- Pick the right spell
        local buildSpell = gloomy and spells.GLOOMBLADE or spells.BACKSTAB
        
        -- Check for energy pooling
        if not settings.rotationSettings.energyPooling or 
           currentEnergy >= settings.rotationSettings.energyPoolingThreshold or
           currentComboPoints == 0 then
            API.CastSpell(buildSpell)
            return true
        end
    end
    
    return false
end

-- Handle specialization change
function Subtlety:OnSpecializationChanged()
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
    shadowDanceCharges = 0
    shadowDanceMaxCharges = 0
    vanishActive = false
    vanishEndTime = 0
    subterfugeActive = false
    subterfugeEndTime = 0
    symbolsOfDeathActive = false
    symbolsOfDeathEndTime = 0
    shadowTechniquesActive = false
    shadowTechniquesEndTime = 0
    shadowTechniquesCount = 0
    findWeaknessActive = {}
    findWeaknessEndTime = {}
    ruptureActive = {}
    ruptureEndTime = {}
    danceOfShadowsActive = false
    danceOfShadowsEndTime = 0
    flagellationActive = false
    flagellationEndTime = 0
    flagellationCount = 0
    finality = {}
    finalityEndTime = {}
    darkShadowActive = false
    premeditation = false
    premedProcActive = false
    premedProcEndTime = 0
    shadowBlades = false
    shadowBladesActive = false
    shadowBladesEndTime = 0
    secret = false
    secretActive = false
    secretEndTime = 0
    inStealth = false
    inMeleeRange = false
    targetHealth = 100
    backstabActive = false
    shuriken = false
    symbolicPowerActive = false
    symbolicPowerEndTime = 0
    symbolicPowerStacks = 0
    perforatedVeinsActive = false
    perforatedVeinsEndTime = 0
    perforatedVeinsStacks = 0
    sepsis = false
    sepsisActive = false
    sepsisEndTime = 0
    deeperShadowsActive = false
    backstab = false
    gloomblade = false
    shurikenStorm = false
    blackPowder = false
    eviscerate = false
    rupture = false
    shadowstrike = false
    cheapShot = false
    kidney = false
    shadowstep = false
    shurikenTornado = false
    shurikenTornadoActive = false
    shurikenTornadoEndTime = 0
    darkBrew = false
    shadowcraft = false
    kyrian = false
    dagger = false
    weaponMaster = false
    acrobaticStrikes = false
    deeperStratagem = false
    vigor = false
    markedForDeath = false
    deepeningShadows = false
    shadowFocus = false
    akaaris = false
    inevitability = false
    resounds = false
    weaponDisability = false
    secretStash = false
    shadowCraft = false
    secretStratagem = false
    subterfugeTalent = false
    darkShadow = false
    coldBlood = false
    echoing = false
    sealFate = false
    prey = false
    blindside = false
    soothingDarkness = false
    nightTerrors = false
    numBlackPowderTargets = 0
    inOpener = false
    shadowStrikeOutOfStealth = false
    refreshableSliceAndDice = false
    refreshableSymbolsOfDeath = false
    refreshableRupture = false
    lastShadowDance = 0
    lastSliceAndDice = 0
    lastSymbolsOfDeath = 0
    lastEvis = 0
    lastShurikenStorm = 0
    lastShurikenTornado = 0
    gloomy = false
    flagellation = false
    
    -- Check stealth state
    self:UpdateStealthState()
    
    -- Update Shadow Dance charges
    self:UpdateShadowDanceCharges()
    
    API.PrintDebug("Subtlety Rogue state reset on spec change")
    
    return true
end

-- Return the module for loading
return Subtlety