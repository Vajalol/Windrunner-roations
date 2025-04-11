------------------------------------------
-- WindrunnerRotations - Feral Druid Module
-- Author: VortexQ8
-- The War Within Season 2
------------------------------------------

local Feral = {}
-- This will be assigned to addon.Classes.Druid.Feral when loaded

-- These will be set when the file is loaded in our test environment
local API
local ConfigRegistry
local AAC
local Druid

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
local ripActive = false
local ripExpiration = 0
local rakeActive = false
local rakeExpiration = 0
local thrassActive = false
local thrassExpiration = 0
local moonFireActive = false
local moonFireExpiration = 0
local prowlActive = false
local inCatForm = false
local tigersFuryActive = false
local tigersFuryExpiration = 0
local berserkActive = false
local berserkExpiration = 0
local incarnationActive = false
local incarnationExpiration = 0
local clearcastingProc = false
local clearcastingStacks = 0
local predatorySwiftnessProc = false
local bloodtalonsProc = false 
local bloodtalonsStacks = 0
local bloodtalonsExpiration = 0
local apexPredatorsCravingProc = false
local soulOfTheForestProc = false
local suddenAmbushProc = false
local savageMomentumProc = false
local convokeCooldown = 0
local adaptiveSwarmCooldown = 0
local feralFrenzyOnCooldown = false
local brutalSlashCharges = 0
local thrashDebuffCount = 0
local inMeleeRange = false
local inExecutePhase = false
local inStealth = false
local momentOfClarity = false
local sabortoothActive = false
local carnivoreVoracity = 0
local limeBite = false
local tearOpenWounds = false
local ferociousBite15 = false
local lunasticFuror = false
local rashaLobo = false
local scentOfBlood = false
local unbridledSwarm = false
local lastProwlTime = 0
local wildFleshripper = false
local ironJaws = false
local carnivorousInstinct = false
local thrashingClaws = 0
local periodicDamageMultiplier = 1.0
local savageryDebuffCount = 0

-- Constants
local FERAL_SPEC_ID = 103
local DEFAULT_AOE_THRESHOLD = 3
local RIP_DURATION = 24
local RAKE_DURATION = 15
local THRASH_DURATION = 15
local MOONFIRE_DURATION = 16
local TIGERS_FURY_DURATION = 10
local BERSERK_DURATION = 20
local INCARNATION_DURATION = 30
local BLOODTALONS_DURATION = 30
local PREDATORY_SWIFTNESS_DURATION = 15
local FEROCIOUS_BITE_EXECUTE_THRESHOLD = 25
local RAKE_RANGE = 5 -- Melee range in yards
local TIGERS_FURY_ENERGY_THRESHOLD = 50
local MIN_ENERGY_FOR_BUILDERS = 35
local FERAL_FRENZY_COST = 25
local SHRED_COST = 40
local RAKE_COST = 35
local THRASH_COST = 40
local RIP_COST = 20 -- + 5 Combo Points
local FEROCIOUS_BITE_COST = 25 -- + 5 Combo Points + up to 25 more for extra damage
local MIN_COMBO_POINTS_FOR_RIP = 5
local MIN_COMBO_POINTS_FOR_FB = 5

-- Initialize the Feral module
function Feral:Initialize()
    self:RegisterSpells()
    self:RegisterVariables()
    self:RegisterSettings()
    self:RegisterEvents()
    
    API.PrintDebug("Feral Druid module initialized")
    
    return true
end

-- Register spell IDs
function Feral:RegisterSpells()
    -- Core rotational abilities
    spells.SHRED = 5221
    spells.RAKE = 1822
    spells.RIP = 1079
    spells.FEROCIOUS_BITE = 22568
    spells.THRASH_CAT = 106830
    spells.SWIPE_CAT = 213764
    spells.TIGERS_FURY = 5217
    spells.BERSERK = 106951
    spells.INCARNATION = 102543
    spells.PRIMAL_WRATH = 285381
    spells.BRUTAL_SLASH = 202028
    spells.MAIM = 22570
    spells.FERAL_FRENZY = 274837
    spells.MOONFIRE_CAT = 155625
    spells.REGROWTH = 8936
    
    -- Forms
    spells.CAT_FORM = 768
    spells.BEAR_FORM = 5487
    spells.TRAVEL_FORM = 783
    spells.MOONKIN_FORM = 24858
    
    -- Defensive/Utility
    spells.SURVIVAL_INSTINCTS = 61336
    spells.BARKSKIN = 22812
    spells.RENEWAL = 108238
    spells.WILD_CHARGE = 102401
    spells.STAMPEDING_ROAR = 106898
    spells.DASH = 1850
    spells.REBIRTH = 20484
    spells.PROWL = 5215
    spells.ENTANGLING_ROOTS = 339
    spells.HIBERNATE = 2637
    spells.SOOTHE = 2908
    spells.SKULL_BASH = 106839
    spells.MIGHTY_BASH = 5211
    spells.INCAPACITATING_ROAR = 99
    spells.MASS_ENTANGLEMENT = 102359
    
    -- Talents and passives
    spells.SABERTOOTH = 202031
    spells.SAVAGE_ROAR = 52610
    spells.SOUL_OF_THE_FOREST = 158476
    spells.BLOODTALONS = 319439
    spells.MOMENT_OF_CLARITY = 236068
    spells.SCENT_OF_BLOOD = 285564
    spells.PREDATOR = 202021
    spells.LUNAR_INSPIRATION = 155580
    spells.WILD_CHARGE = 102401
    spells.TIGERS_FURY = 5217
    spells.SUDDEN_AMBUSH = 391974
    spells.SAVAGE_MOMENTUM = 389695
    spells.PREDATORY_SWIFTNESS = 16974
    spells.BERSERK_FRENZY = 384668
    spells.TASTE_FOR_BLOOD = 384665
    spells.TEAR_OPEN_WOUNDS = 391785
    spells.RAMPANT_FEROCITY = 391709
    spells.BERSERK_FRENZY = 384668
    spells.INCARNATION_AVATAR_OF_ASHAMANE = 102543
    spells.APEX_PREDATORS_CRAVING = 391881
    spells.TIRELESS_ENERGY = 383390
    spells.TIGERS_TENACITY = 385738
    spells.INFECTED_WOUNDS = 58180
    spells.NURTURING_INSTINCT = 33873
    spells.IMPROVED_TIGERS_FURY = 231063
    spells.SURVIVAL_OF_THE_FITTEST = 391947
    spells.HEART_OF_THE_WILD = 319454
    spells.URSINE_VIGOR = 377842
    spells.IMPROVED_BARKSKIN = 393611
    spells.PROTECTOR_OF_THE_PACK = 378986
    spells.BORN_OF_THE_WILDS = 392167
    spells.BERSERK_HEART_OF_THE_LION = 391174
    spells.CARNIVOROUS_INSTINCT = 390902
    spells.WILD_SLASHES = 390892
    spells.FRONT_CLAWS = 390841
    spells.REND_AND_TEAR = 391011
    spells.FRANTIC_MOMENTUM = 391873
    spells.ASHAMANES_GUIDANCE = 391548
    spells.DIRE_FIXATION = 417710
    spells.RELENTLESS_PREDATOR = 393771
    spells.IRON_JAWS = 231052
    spells.INFECTED_WOUNDS = 58180
    spells.WILD_FLESHRIPPER = 391882
    spells.THRASHING_CLAWS = 407283
    spells.BLOODY_HEALING = 391045
    
    -- War Within specific
    spells.FURIOUS_BITES = 422401
    spells.RAGING_FURY = 400254
    spells.RAZOR_FANGS = 413949
    spells.THICK_HIDE = 16931
    spells.INFECTED_WOUNDS = 377591
    spells.FELINE_ADEPT = 399979
    spells.SHARPENED_CLAWS = 420959
    spells.RAGING_FURY = 400254
    spells.FANGS_OF_CHAOS = 407331
    spells.BITE_THE_HAND = 400249
    spells.UNBRIDLED_SWARM = 391548
    spells.THORNS_OF_IRON = 400333
    spells.RAGE_OF_THE_SLEEPER = 200851
    spells.MANGLE = 33917
    spells.GROVE_TENDING = 383192
    spells.TIRELESS_PURSUIT = 377842
    spells.FELINE_GRACE = 125972
    spells.FELINE_ADEPT = 399979
    spells.LUNASTIC_FUROR = 424142
    spells.FRENZIED_ASSAULT = 416225
    spells.LIME_BITE = 381667
    spells.CARNIVORACIOUS = 390772
    spells.RASHA_LOBO = 393771

    -- Covenant abilities
    spells.CONVOKE_THE_SPIRITS = 323764
    spells.ADAPTIVE_SWARM = 325727
    spells.RAVENOUS_FRENZY = 323546
    spells.KINDRED_SPIRITS = 326434
    
    -- Buff IDs
    spells.PROWL_BUFF = 5215
    spells.TIGERS_FURY_BUFF = 5217
    spells.BERSERK_BUFF = 106951
    spells.INCARNATION_BUFF = 102543
    spells.CLEARCASTING_BUFF = 135700
    spells.PREDATORY_SWIFTNESS_BUFF = 69369
    spells.BLOODTALONS_BUFF = 145152
    spells.SAVAGE_ROAR_BUFF = 52610
    spells.SOUL_OF_THE_FOREST_BUFF = 158476
    spells.SUDDEN_AMBUSH_BUFF = 391988
    spells.APEX_PREDATORS_CRAVING_BUFF = 391882
    spells.HEART_OF_THE_WILD_BUFF = 108291
    spells.INCARNATION_KING_OF_THE_JUNGLE_BUFF = 102543
    spells.CAT_FORM_BUFF = 768
    spells.BEAR_FORM_BUFF = 5487
    spells.FERAL_FRENZY_BUFF = 274838
    spells.CARNIVORACIOUS_BUFF = 390773
    spells.FRENZIED_ASSAULT_BUFF = 340053
    spells.WILD_SLASHES_BUFF = 390900
    spells.LUNASTIC_FUROR_BUFF = 424143
    spells.RASHA_LOBO_BUFF = 393776
    spells.UNBRIDLED_SWARM_BUFF = 391550
    spells.THRASHING_CLAWS_BUFF = 407285
    
    -- Debuff IDs
    spells.RIP_DEBUFF = 1079
    spells.RAKE_DEBUFF = 155722
    spells.THRASH_DEBUFF = 106830
    spells.MOONFIRE_DEBUFF = 155625
    spells.INFECTED_WOUNDS_DEBUFF = 58180
    spells.ADAPTIVE_SWARM_DEBUFF = 325733
    spells.SAVAGERY_DEBUFF = 62076
    
    -- Register all spells with the API tracking system
    for spellName, spellID in pairs(spells) do
        API.RegisterSpell(spellID)
    end
    
    -- Define aura tracking
    buffs.PROWL = spells.PROWL_BUFF
    buffs.TIGERS_FURY = spells.TIGERS_FURY_BUFF
    buffs.BERSERK = spells.BERSERK_BUFF
    buffs.INCARNATION = spells.INCARNATION_BUFF
    buffs.CLEARCASTING = spells.CLEARCASTING_BUFF
    buffs.PREDATORY_SWIFTNESS = spells.PREDATORY_SWIFTNESS_BUFF
    buffs.BLOODTALONS = spells.BLOODTALONS_BUFF
    buffs.SAVAGE_ROAR = spells.SAVAGE_ROAR_BUFF
    buffs.SOUL_OF_THE_FOREST = spells.SOUL_OF_THE_FOREST_BUFF
    buffs.SUDDEN_AMBUSH = spells.SUDDEN_AMBUSH_BUFF
    buffs.APEX_PREDATORS_CRAVING = spells.APEX_PREDATORS_CRAVING_BUFF
    buffs.HEART_OF_THE_WILD = spells.HEART_OF_THE_WILD_BUFF
    buffs.CAT_FORM = spells.CAT_FORM_BUFF
    buffs.BEAR_FORM = spells.BEAR_FORM_BUFF
    buffs.FERAL_FRENZY = spells.FERAL_FRENZY_BUFF
    buffs.CARNIVORACIOUS = spells.CARNIVORACIOUS_BUFF
    buffs.FRENZIED_ASSAULT = spells.FRENZIED_ASSAULT_BUFF
    buffs.WILD_SLASHES = spells.WILD_SLASHES_BUFF
    buffs.LUNASTIC_FUROR = spells.LUNASTIC_FUROR_BUFF
    buffs.RASHA_LOBO = spells.RASHA_LOBO_BUFF
    buffs.UNBRIDLED_SWARM = spells.UNBRIDLED_SWARM_BUFF
    buffs.THRASHING_CLAWS = spells.THRASHING_CLAWS_BUFF
    
    debuffs.RIP = spells.RIP_DEBUFF
    debuffs.RAKE = spells.RAKE_DEBUFF
    debuffs.THRASH = spells.THRASH_DEBUFF
    debuffs.MOONFIRE = spells.MOONFIRE_DEBUFF
    debuffs.INFECTED_WOUNDS = spells.INFECTED_WOUNDS_DEBUFF
    debuffs.ADAPTIVE_SWARM = spells.ADAPTIVE_SWARM_DEBUFF
    debuffs.SAVAGERY = spells.SAVAGERY_DEBUFF
    
    return true
end

-- Register variables to track
function Feral:RegisterVariables()
    -- Talent tracking
    talents.hasSabertooth = false
    talents.hasSavageRoar = false
    talents.hasSoulOfTheForest = false
    talents.hasBloodtalons = false
    talents.hasMomentOfClarity = false
    talents.hasScentOfBlood = false
    talents.hasPredator = false
    talents.hasLunarInspiration = false
    talents.hasWildCharge = false
    talents.hasTigersFury = false
    talents.hasSuddenAmbush = false
    talents.hasSavageMomentum = false
    talents.hasPredatorySwiftness = false
    talents.hasBerserkFrenzy = false
    talents.hasTasteForBlood = false
    talents.hasTearOpenWounds = false
    talents.hasRampantFerocity = false
    talents.hasBerserkFrenzy = false
    talents.hasIncarnationAvatarOfAshamane = false
    talents.hasApexPredatorsCraving = false
    talents.hasTirelessEnergy = false
    talents.hasTigersTenacity = false
    talents.hasInfectedWounds = false
    talents.hasNurturingInstinct = false
    talents.hasImprovedTigersFury = false
    talents.hasSurvivalOfTheFittest = false
    talents.hasHeartOfTheWild = false
    talents.hasUrsineVigor = false
    talents.hasImprovedBarkskin = false
    talents.hasProtectorOfThePack = false
    talents.hasBornOfTheWilds = false
    talents.hasBerserkHeartOfTheLion = false
    talents.hasCarnivorousInstinct = false
    talents.hasWildSlashes = false
    talents.hasFrontClaws = false
    talents.hasRendAndTear = false
    talents.hasFranticMomentum = false
    talents.hasAshamanesGuidance = false
    talents.hasDireFixation = false
    talents.hasRelentlessPredator = false
    talents.hasIronJaws = false
    talents.hasInfectedWounds = false
    talents.hasWildFleshripper = false
    talents.hasThrashingClaws = false
    talents.hasBloodyHealing = false
    talents.hasPrimalWrath = false
    talents.hasBrutalSlash = false
    talents.hasFeralFrenzy = false
    talents.hasFuriousBites = false
    talents.hasRagingFury = false
    talents.hasRazorFangs = false
    talents.hasThickHide = false
    talents.hasInfectedWounds = false
    talents.hasFelineAdept = false
    talents.hasSharpenedClaws = false
    talents.hasRagingFury = false
    talents.hasFangsOfChaos = false
    talents.hasBiteTheHand = false
    talents.hasUnbridledSwarm = false
    talents.hasThornsOfIron = false
    talents.hasRageOfTheSleeper = false
    talents.hasGroveTending = false
    talents.hasTirelessPursuit = false
    talents.hasFelineGrace = false
    talents.hasFelineAdept = false
    talents.hasLunasticFuror = false
    talents.hasFrenziedAssault = false
    talents.hasLimeBite = false
    talents.hasCarnivoracious = false
    talents.hasRashaLobo = false

    -- Target state tracking
    self.targetData = {}
    
    -- Initialize energy and combo points
    currentEnergy = API.GetPlayerPower()
    currentComboPoints = API.GetPlayerComboPoints()
    
    return true
end

-- Register spec-specific settings
function Feral:RegisterSettings()
    ConfigRegistry:RegisterSettings("FeralDruid", {
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
            useCatForm = {
                displayName = "Use Cat Form",
                description = "Automatically enter Cat Form",
                type = "toggle",
                default = true
            },
            stealthOpener = {
                displayName = "Stealth Opener",
                description = "Use Prowl for stealth opener when available",
                type = "toggle",
                default = true
            },
            maintainRip = {
                displayName = "Maintain Rip",
                description = "Keep Rip active on targets",
                type = "toggle",
                default = true
            },
            maintainRake = {
                displayName = "Maintain Rake",
                description = "Keep Rake active on targets",
                type = "toggle",
                default = true
            },
            maintainThrash = {
                displayName = "Maintain Thrash",
                description = "Keep Thrash active in AoE",
                type = "toggle",
                default = true
            }
        },
        
        defensiveSettings = {
            useBarkskin = {
                displayName = "Use Barkskin",
                description = "Automatically use Barkskin",
                type = "toggle",
                default = true
            },
            barkskinThreshold = {
                displayName = "Barkskin Health Threshold",
                description = "Health percentage to use Barkskin",
                type = "slider",
                min = 20,
                max = 80,
                default = 60
            },
            useSurvivalInstincts = {
                displayName = "Use Survival Instincts",
                description = "Automatically use Survival Instincts",
                type = "toggle",
                default = true
            },
            survivalInstinctsThreshold = {
                displayName = "Survival Instincts Threshold",
                description = "Health percentage to use Survival Instincts",
                type = "slider",
                min = 10,
                max = 60,
                default = 40
            },
            useRenewal = {
                displayName = "Use Renewal",
                description = "Automatically use Renewal when talented",
                type = "toggle",
                default = true
            },
            renewalThreshold = {
                displayName = "Renewal Health Threshold",
                description = "Health percentage to use Renewal",
                type = "slider",
                min = 10,
                max = 60,
                default = 35
            },
            useRegrowth = {
                displayName = "Use Regrowth",
                description = "Use Regrowth with Predatory Swiftness procs",
                type = "toggle",
                default = true
            },
            regrowthThreshold = {
                displayName = "Regrowth Health Threshold",
                description = "Health percentage to use Regrowth",
                type = "slider",
                min = 10,
                max = 70,
                default = 50
            },
            useBearForm = {
                displayName = "Use Bear Form",
                description = "Switch to Bear Form when critical",
                type = "toggle",
                default = true
            },
            bearFormThreshold = {
                displayName = "Bear Form Health Threshold",
                description = "Health percentage to switch to Bear Form",
                type = "slider",
                min = 10,
                max = 30,
                default = 20
            }
        },
        
        offensiveSettings = {
            useTigersFury = {
                displayName = "Use Tiger's Fury",
                description = "Automatically use Tiger's Fury",
                type = "toggle",
                default = true
            },
            useBerserk = {
                displayName = "Use Berserk/Incarnation",
                description = "Automatically use Berserk or Incarnation",
                type = "toggle",
                default = true
            },
            useBerserkWithTigersFury = {
                displayName = "Sync Berserk with Tiger's Fury",
                description = "Use Berserk only with Tiger's Fury",
                type = "toggle",
                default = true
            },
            useFeralFrenzy = {
                displayName = "Use Feral Frenzy",
                description = "Automatically use Feral Frenzy when talented",
                type = "toggle",
                default = true
            },
            useBrutalSlash = {
                displayName = "Use Brutal Slash",
                description = "Automatically use Brutal Slash when talented",
                type = "toggle",
                default = true
            },
            brutaSlashMinTargets = {
                displayName = "Brutal Slash Min Targets",
                description = "Minimum targets to use Brutal Slash in single target",
                type = "slider",
                min = 1,
                max = 5,
                default = 1
            },
            useSavageRoar = {
                displayName = "Use Savage Roar",
                description = "Automatically use Savage Roar when talented",
                type = "toggle",
                default = true
            },
            savageRoarRefreshPoint = {
                displayName = "Savage Roar Refresh Time",
                description = "Seconds remaining to refresh Savage Roar",
                type = "slider",
                min = 3,
                max = 12,
                default = 6
            }
        },
        
        covenantSettings = {
            useConvoke = {
                displayName = "Use Convoke the Spirits",
                description = "Automatically use Convoke the Spirits",
                type = "toggle",
                default = true
            },
            convokeMinComboPoints = {
                displayName = "Convoke Min Combo Points",
                description = "Minimum combo points needed to cast Convoke",
                type = "slider",
                min = 0,
                max = 5,
                default = 0
            },
            useAdaptiveSwarm = {
                displayName = "Use Adaptive Swarm",
                description = "Automatically use Adaptive Swarm",
                type = "toggle",
                default = true
            },
            useRavenousFrenzy = {
                displayName = "Use Ravenous Frenzy",
                description = "Automatically use Ravenous Frenzy",
                type = "toggle",
                default = true
            },
            useKindredSpirits = {
                displayName = "Use Kindred Spirits",
                description = "Automatically use Kindred Spirits",
                type = "toggle",
                default = true
            }
        },
        
        advancedSettings = {
            ripRefreshThreshold = {
                displayName = "Rip Refresh Threshold",
                description = "Seconds remaining to refresh Rip",
                type = "slider",
                min = 3,
                max = 12,
                default = 8
            },
            rakeRefreshThreshold = {
                displayName = "Rake Refresh Threshold",
                description = "Seconds remaining to refresh Rake",
                type = "slider",
                min = 3,
                max = 8,
                default = 4
            },
            thrashRefreshThreshold = {
                displayName = "Thrash Refresh Threshold",
                description = "Seconds remaining to refresh Thrash",
                type = "slider",
                min = 3,
                max = 8,
                default = 4
            },
            useBloodtalons = {
                displayName = "Use Bloodtalons",
                description = "Use special rotation to generate Bloodtalons procs",
                type = "toggle",
                default = true
            },
            poolEnergy = {
                displayName = "Pool Energy",
                description = "Pool energy for upcoming abilities",
                type = "toggle",
                default = true
            },
            minEnergyForBuilder = {
                displayName = "Min Energy for Builder",
                description = "Minimum energy to use builder abilities",
                type = "slider",
                min = 30,
                max = 60,
                default = MIN_ENERGY_FOR_BUILDERS
            },
            usePrimalWrath = {
                displayName = "Use Primal Wrath",
                description = "When to use Primal Wrath in AoE",
                type = "dropdown",
                options = {"Never", "3+ Targets", "4+ Targets", "5+ Targets"},
                default = "3+ Targets"
            },
            moonFireMode = {
                displayName = "Moonfire Mode",
                description = "When to use Moonfire in Cat Form",
                type = "dropdown",
                options = {"Always", "During Clearcasting", "Never"},
                default = "During Clearcasting"
            }
        },
        
        -- Advanced ability control settings
        abilityControls = {
            -- Berserk/Incarnation controls
            berserk = AAC.RegisterAbility(spells.BERSERK, {
                enabled = true,
                useDuringBurstOnly = true,
                useWithTigersFury = true
            }),
            
            -- Tiger's Fury controls
            tigersFury = AAC.RegisterAbility(spells.TIGERS_FURY, {
                enabled = true,
                minEnergyDelta = 50,
                snapRefreshDots = true
            }),
            
            -- Feral Frenzy controls
            feralFrenzy = AAC.RegisterAbility(spells.FERAL_FRENZY, {
                enabled = true,
                useWithTigersFury = true,
                minComboPoints = 0
            })
        }
    })
    
    return true
end

-- Register for events 
function Feral:RegisterEvents()
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
    
    -- Register for target change events
    API.RegisterEvent("PLAYER_TARGET_CHANGED", function() 
        self:UpdateTargetData() 
    end)
    
    -- Register for talent update events
    API.RegisterEvent("PLAYER_TALENT_UPDATE", function() 
        self:UpdateTalentInfo() 
    end)
    
    -- Register for form change events
    API.RegisterEvent("UPDATE_SHAPESHIFT_FORM", function() 
        self:UpdateShapeshiftForm()
    end)
    
    -- Initial talent info update
    self:UpdateTalentInfo()
    
    -- Initial shapeshift form check
    self:UpdateShapeshiftForm()
    
    return true
end

-- Update talent information
function Feral:UpdateTalentInfo()
    -- Check for important talents
    talents.hasSabertooth = API.HasTalent(spells.SABERTOOTH)
    talents.hasSavageRoar = API.HasTalent(spells.SAVAGE_ROAR)
    talents.hasSoulOfTheForest = API.HasTalent(spells.SOUL_OF_THE_FOREST)
    talents.hasBloodtalons = API.HasTalent(spells.BLOODTALONS)
    talents.hasMomentOfClarity = API.HasTalent(spells.MOMENT_OF_CLARITY)
    talents.hasScentOfBlood = API.HasTalent(spells.SCENT_OF_BLOOD)
    talents.hasPredator = API.HasTalent(spells.PREDATOR)
    talents.hasLunarInspiration = API.HasTalent(spells.LUNAR_INSPIRATION)
    talents.hasWildCharge = API.HasTalent(spells.WILD_CHARGE)
    talents.hasTigersFury = API.HasTalent(spells.TIGERS_FURY)
    talents.hasSuddenAmbush = API.HasTalent(spells.SUDDEN_AMBUSH)
    talents.hasSavageMomentum = API.HasTalent(spells.SAVAGE_MOMENTUM)
    talents.hasPredatorySwiftness = API.HasTalent(spells.PREDATORY_SWIFTNESS)
    talents.hasBerserkFrenzy = API.HasTalent(spells.BERSERK_FRENZY)
    talents.hasTasteForBlood = API.HasTalent(spells.TASTE_FOR_BLOOD)
    talents.hasTearOpenWounds = API.HasTalent(spells.TEAR_OPEN_WOUNDS)
    talents.hasRampantFerocity = API.HasTalent(spells.RAMPANT_FEROCITY)
    talents.hasBerserkFrenzy = API.HasTalent(spells.BERSERK_FRENZY)
    talents.hasIncarnationAvatarOfAshamane = API.HasTalent(spells.INCARNATION_AVATAR_OF_ASHAMANE)
    talents.hasApexPredatorsCraving = API.HasTalent(spells.APEX_PREDATORS_CRAVING)
    talents.hasTirelessEnergy = API.HasTalent(spells.TIRELESS_ENERGY)
    talents.hasTigersTenacity = API.HasTalent(spells.TIGERS_TENACITY)
    talents.hasInfectedWounds = API.HasTalent(spells.INFECTED_WOUNDS)
    talents.hasNurturingInstinct = API.HasTalent(spells.NURTURING_INSTINCT)
    talents.hasImprovedTigersFury = API.HasTalent(spells.IMPROVED_TIGERS_FURY)
    talents.hasSurvivalOfTheFittest = API.HasTalent(spells.SURVIVAL_OF_THE_FITTEST)
    talents.hasHeartOfTheWild = API.HasTalent(spells.HEART_OF_THE_WILD)
    talents.hasUrsineVigor = API.HasTalent(spells.URSINE_VIGOR)
    talents.hasImprovedBarkskin = API.HasTalent(spells.IMPROVED_BARKSKIN)
    talents.hasProtectorOfThePack = API.HasTalent(spells.PROTECTOR_OF_THE_PACK)
    talents.hasBornOfTheWilds = API.HasTalent(spells.BORN_OF_THE_WILDS)
    talents.hasBerserkHeartOfTheLion = API.HasTalent(spells.BERSERK_HEART_OF_THE_LION)
    talents.hasCarnivorousInstinct = API.HasTalent(spells.CARNIVOROUS_INSTINCT)
    talents.hasWildSlashes = API.HasTalent(spells.WILD_SLASHES)
    talents.hasFrontClaws = API.HasTalent(spells.FRONT_CLAWS)
    talents.hasRendAndTear = API.HasTalent(spells.REND_AND_TEAR)
    talents.hasFranticMomentum = API.HasTalent(spells.FRANTIC_MOMENTUM)
    talents.hasAshamanesGuidance = API.HasTalent(spells.ASHAMANES_GUIDANCE)
    talents.hasDireFixation = API.HasTalent(spells.DIRE_FIXATION)
    talents.hasRelentlessPredator = API.HasTalent(spells.RELENTLESS_PREDATOR)
    talents.hasIronJaws = API.HasTalent(spells.IRON_JAWS)
    talents.hasInfectedWounds = API.HasTalent(spells.INFECTED_WOUNDS)
    talents.hasWildFleshripper = API.HasTalent(spells.WILD_FLESHRIPPER)
    talents.hasThrashingClaws = API.HasTalent(spells.THRASHING_CLAWS)
    talents.hasBloodyHealing = API.HasTalent(spells.BLOODY_HEALING)
    talents.hasPrimalWrath = API.HasTalent(spells.PRIMAL_WRATH)
    talents.hasBrutalSlash = API.HasTalent(spells.BRUTAL_SLASH)
    talents.hasFeralFrenzy = API.HasTalent(spells.FERAL_FRENZY)
    talents.hasFuriousBites = API.HasTalent(spells.FURIOUS_BITES)
    talents.hasRagingFury = API.HasTalent(spells.RAGING_FURY)
    talents.hasRazorFangs = API.HasTalent(spells.RAZOR_FANGS)
    talents.hasThickHide = API.HasTalent(spells.THICK_HIDE)
    talents.hasInfectedWounds = API.HasTalent(spells.INFECTED_WOUNDS)
    talents.hasFelineAdept = API.HasTalent(spells.FELINE_ADEPT)
    talents.hasSharpenedClaws = API.HasTalent(spells.SHARPENED_CLAWS)
    talents.hasRagingFury = API.HasTalent(spells.RAGING_FURY)
    talents.hasFangsOfChaos = API.HasTalent(spells.FANGS_OF_CHAOS)
    talents.hasBiteTheHand = API.HasTalent(spells.BITE_THE_HAND)
    talents.hasUnbridledSwarm = API.HasTalent(spells.UNBRIDLED_SWARM)
    talents.hasThornsOfIron = API.HasTalent(spells.THORNS_OF_IRON)
    talents.hasRageOfTheSleeper = API.HasTalent(spells.RAGE_OF_THE_SLEEPER)
    talents.hasGroveTending = API.HasTalent(spells.GROVE_TENDING)
    talents.hasTirelessPursuit = API.HasTalent(spells.TIRELESS_PURSUIT)
    talents.hasFelineGrace = API.HasTalent(spells.FELINE_GRACE)
    talents.hasFelineAdept = API.HasTalent(spells.FELINE_ADEPT)
    talents.hasLunasticFuror = API.HasTalent(spells.LUNASTIC_FUROR)
    talents.hasFrenziedAssault = API.HasTalent(spells.FRENZIED_ASSAULT)
    talents.hasLimeBite = API.HasTalent(spells.LIME_BITE)
    talents.hasCarnivoracious = API.HasTalent(spells.CARNIVORACIOUS)
    talents.hasRashaLobo = API.HasTalent(spells.RASHA_LOBO)
    
    -- Set specialized variables based on talents
    if talents.hasSabertooth then
        sabortoothActive = true
    end
    
    if talents.hasMomentOfClarity then
        momentOfClarity = true
    end
    
    if talents.hasLunarInspiration then
        -- The ability to cast Moonfire in Cat Form
        -- We don't need a special variable since we check if the talent exists
    end
    
    if talents.hasIronJaws then
        ironJaws = true
    end
    
    if talents.hasCarnivorousInstinct then
        carnivorousInstinct = true
    end
    
    if talents.hasLimeBite then
        limeBite = true
    }
    
    if talents.hasTearOpenWounds then
        tearOpenWounds = true;
    }
    
    if talents.hasLunasticFuror then
        lunasticFuror = true;
    }
    
    if talents.hasRashaLobo then
        rashaLobo = true;
    }

    if talents.hasScentOfBlood then
        scentOfBlood = true;
    }
    
    if talents.hasUnbridledSwarm then
        unbridledSwarm = true;
    }
    
    if talents.hasBrutalSlash then
        brutalSlashCharges = API.GetSpellCharges(spells.BRUTAL_SLASH) or 0
    end
    
    API.PrintDebug("Feral Druid talents updated")
    
    return true
end

-- Update energy tracking
function Feral:UpdateEnergy()
    currentEnergy = API.GetPlayerPower()
    return true
end

-- Update combo points tracking
function Feral:UpdateComboPoints()
    currentComboPoints = API.GetPlayerComboPoints()
    return true
end

-- Update shapeshift form tracking
function Feral:UpdateShapeshiftForm()
    inCatForm = API.PlayerHasBuff(buffs.CAT_FORM)
    prowlActive = API.PlayerHasBuff(buffs.PROWL)
    
    -- If prowl is active, we're in stealth
    inStealth = prowlActive
    
    if prowlActive then
        lastProwlTime = GetTime()
    end
    
    return true
end

-- Update target data
function Feral:UpdateTargetData()
    -- Check if in melee range
    inMeleeRange = API.IsUnitInRange("target", RAKE_RANGE)
    
    -- Get target GUID
    local targetGUID = API.GetTargetGUID()
    
    if targetGUID and targetGUID ~= "" then
        -- Initialize target data if needed
        if not self.targetData[targetGUID] then
            self.targetData[targetGUID] = {
                rip = false,
                ripExpiration = 0,
                rake = false,
                rakeExpiration = 0,
                thrash = false,
                thrashExpiration = 0,
                moonfire = false,
                moonfireExpiration = 0,
                adaptiveSwarm = false,
                adaptiveSwarmExpiration = 0,
                infected = false, -- Infected Wounds
                infectedExpiration = 0,
                savagery = false,
                savageryExpiration = 0
            }
        end
        
        -- Check for Rip
        local name, _, _, _, _, expiration = API.GetDebuffInfo(targetGUID, debuffs.RIP)
        if name then
            self.targetData[targetGUID].rip = true
            self.targetData[targetGUID].ripExpiration = expiration
            ripActive = true
            ripExpiration = expiration
        else
            self.targetData[targetGUID].rip = false
            self.targetData[targetGUID].ripExpiration = 0
            ripActive = false
            ripExpiration = 0
        end
        
        -- Check for Rake
        local name, _, _, _, _, expiration = API.GetDebuffInfo(targetGUID, debuffs.RAKE)
        if name then
            self.targetData[targetGUID].rake = true
            self.targetData[targetGUID].rakeExpiration = expiration
            rakeActive = true
            rakeExpiration = expiration
        else
            self.targetData[targetGUID].rake = false
            self.targetData[targetGUID].rakeExpiration = 0
            rakeActive = false
            rakeExpiration = 0
        end
        
        -- Check for Thrash
        local name, _, _, _, _, expiration = API.GetDebuffInfo(targetGUID, debuffs.THRASH)
        if name then
            self.targetData[targetGUID].thrash = true
            self.targetData[targetGUID].thrashExpiration = expiration
            thrassActive = true
            thrassExpiration = expiration
        else
            self.targetData[targetGUID].thrash = false
            self.targetData[targetGUID].thrashExpiration = 0
            thrassActive = false
            thrassExpiration = 0
        end
        
        -- Check for Moonfire
        if talents.hasLunarInspiration then
            local name, _, _, _, _, expiration = API.GetDebuffInfo(targetGUID, debuffs.MOONFIRE)
            if name then
                self.targetData[targetGUID].moonfire = true
                self.targetData[targetGUID].moonfireExpiration = expiration
                moonFireActive = true
                moonFireExpiration = expiration
            else
                self.targetData[targetGUID].moonfire = false
                self.targetData[targetGUID].moonfireExpiration = 0
                moonFireActive = false
                moonFireExpiration = 0
            end
        end
        
        -- Check for Adaptive Swarm
        local name, _, _, _, _, expiration = API.GetDebuffInfo(targetGUID, debuffs.ADAPTIVE_SWARM)
        if name then
            self.targetData[targetGUID].adaptiveSwarm = true
            self.targetData[targetGUID].adaptiveSwarmExpiration = expiration
        else
            self.targetData[targetGUID].adaptiveSwarm = false
            self.targetData[targetGUID].adaptiveSwarmExpiration = 0
        end
        
        -- Check for Infected Wounds
        if talents.hasInfectedWounds then
            local name, _, _, _, _, expiration = API.GetDebuffInfo(targetGUID, debuffs.INFECTED_WOUNDS)
            if name then
                self.targetData[targetGUID].infected = true
                self.targetData[targetGUID].infectedExpiration = expiration
            else
                self.targetData[targetGUID].infected = false
                self.targetData[targetGUID].infectedExpiration = 0
            end
        end
        
        -- Check for Savagery debuff (for War Within Season 2)
        local name, _, _, _, _, expiration = API.GetDebuffInfo(targetGUID, debuffs.SAVAGERY)
        if name then
            self.targetData[targetGUID].savagery = true
            self.targetData[targetGUID].savageryExpiration = expiration
        else
            self.targetData[targetGUID].savagery = false
            self.targetData[targetGUID].savageryExpiration = 0
        end
    end
    
    -- Check if in execute phase
    inExecutePhase = API.GetTargetHealthPercent() <= FEROCIOUS_BITE_EXECUTE_THRESHOLD
    
    -- Count thrash debuffs
    thrashDebuffCount = 0
    for _, targetData in pairs(self.targetData) do
        if targetData.thrash then
            thrashDebuffCount = thrashDebuffCount + 1
        end
    end
    
    -- Count savagery debuffs
    savageryDebuffCount = 0
    for _, targetData in pairs(self.targetData) do
        if targetData.savagery then
            savageryDebuffCount = savageryDebuffCount + 1
        end
    end
    
    -- Update AoE targets count
    currentAoETargets = API.GetNearbyEnemiesCount(8) -- Feral AoE radius
    
    return true
end

-- Handle combat log events
function Feral:HandleCombatLogEvent(...)
    local timestamp, eventType, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, spellID, spellName = CombatLogGetCurrentEventInfo()
    
    -- Track buff applications
    if eventType == "SPELL_AURA_APPLIED" or eventType == "SPELL_AURA_REFRESH" then
        -- Track player buffs
        if destGUID == API.GetPlayerGUID() then
            -- Track Tiger's Fury
            if spellID == buffs.TIGERS_FURY then
                tigersFuryActive = true
                tigersFuryExpiration = GetTime() + TIGERS_FURY_DURATION
                API.PrintDebug("Tiger's Fury activated")
            end
            
            -- Track Berserk
            if spellID == buffs.BERSERK then
                berserkActive = true
                berserkExpiration = GetTime() + BERSERK_DURATION
                API.PrintDebug("Berserk activated")
            end
            
            -- Track Incarnation
            if spellID == buffs.INCARNATION then
                incarnationActive = true
                incarnationExpiration = GetTime() + INCARNATION_DURATION
                API.PrintDebug("Incarnation activated")
            end
            
            -- Track Clearcasting
            if spellID == buffs.CLEARCASTING then
                clearcastingProc = true
                clearcastingStacks = select(4, API.GetBuffInfo("player", buffs.CLEARCASTING)) or 1
                API.PrintDebug("Clearcasting proc: " .. tostring(clearcastingStacks) .. " stacks")
            end
            
            -- Track Predatory Swiftness
            if spellID == buffs.PREDATORY_SWIFTNESS then
                predatorySwiftnessProc = true
                API.PrintDebug("Predatory Swiftness proc activated")
            end
            
            -- Track Bloodtalons
            if spellID == buffs.BLOODTALONS then
                bloodtalonsProc = true
                bloodtalonsStacks = select(4, API.GetBuffInfo("player", buffs.BLOODTALONS)) or 1
                bloodtalonsExpiration = GetTime() + BLOODTALONS_DURATION
                API.PrintDebug("Bloodtalons proc: " .. tostring(bloodtalonsStacks) .. " stacks")
            end
            
            -- Track Apex Predator's Craving
            if spellID == buffs.APEX_PREDATORS_CRAVING then
                apexPredatorsCravingProc = true
                API.PrintDebug("Apex Predator's Craving proc activated")
            end
            
            -- Track Soul of the Forest
            if spellID == buffs.SOUL_OF_THE_FOREST then
                soulOfTheForestProc = true
                API.PrintDebug("Soul of the Forest proc activated")
            end
            
            -- Track Sudden Ambush
            if spellID == buffs.SUDDEN_AMBUSH then
                suddenAmbushProc = true
                API.PrintDebug("Sudden Ambush proc activated")
            end
            
            -- Track Cat Form
            if spellID == buffs.CAT_FORM then
                inCatForm = true
                API.PrintDebug("Cat Form activated")
            end
            
            -- Track Prowl
            if spellID == buffs.PROWL then
                prowlActive = true
                inStealth = true
                lastProwlTime = GetTime()
                API.PrintDebug("Prowl activated")
            end
            
            -- Track Feral Frenzy
            if spellID == buffs.FERAL_FRENZY then
                API.PrintDebug("Feral Frenzy activated")
            end
            
            -- Track Carnivoracious
            if spellID == buffs.CARNIVORACIOUS then
                carnivoreVoracity = select(4, API.GetBuffInfo("player", buffs.CARNIVORACIOUS)) or 0
                API.PrintDebug("Carnivoracious stacks: " .. tostring(carnivoreVoracity))
            end
            
            -- Track Frenzied Assault
            if spellID == buffs.FRENZIED_ASSAULT then
                API.PrintDebug("Frenzied Assault activated")
            end
            
            -- Track Wild Slashes
            if spellID == buffs.WILD_SLASHES then
                wildFleshripper = true
                API.PrintDebug("Wild Slashes activated")
            end
            
            -- Track Lunastic Furor
            if spellID == buffs.LUNASTIC_FUROR then
                lunasticFuror = true
                API.PrintDebug("Lunastic Furor activated")
            end
            
            -- Track Rasha Lobo
            if spellID == buffs.RASHA_LOBO then
                rashaLobo = true
                API.PrintDebug("Rasha Lobo activated")
            end
            
            -- Track Unbridled Swarm
            if spellID == buffs.UNBRIDLED_SWARM then
                unbridledSwarm = true
                API.PrintDebug("Unbridled Swarm activated")
            end
            
            -- Track Thrashing Claws
            if spellID == buffs.THRASHING_CLAWS then
                thrashingClaws = select(4, API.GetBuffInfo("player", buffs.THRASHING_CLAWS)) or 0
                API.PrintDebug("Thrashing Claws stacks: " .. tostring(thrashingClaws))
                
                -- Each stack increases periodic damage
                periodicDamageMultiplier = 1.0 + (thrashingClaws * 0.03) -- 3% per stack
            end
        end
        
        -- Track target debuffs
        -- Update target data when debuffs change
        self:UpdateTargetData()
    end
    
    -- Track buff removals
    if eventType == "SPELL_AURA_REMOVED" then
        -- Track player buffs
        if destGUID == API.GetPlayerGUID() then
            -- Track Tiger's Fury
            if spellID == buffs.TIGERS_FURY then
                tigersFuryActive = false
                API.PrintDebug("Tiger's Fury faded")
            end
            
            -- Track Berserk
            if spellID == buffs.BERSERK then
                berserkActive = false
                API.PrintDebug("Berserk faded")
            end
            
            -- Track Incarnation
            if spellID == buffs.INCARNATION then
                incarnationActive = false
                API.PrintDebug("Incarnation faded")
            end
            
            -- Track Clearcasting
            if spellID == buffs.CLEARCASTING then
                clearcastingProc = false
                clearcastingStacks = 0
                API.PrintDebug("Clearcasting consumed")
            end
            
            -- Track Predatory Swiftness
            if spellID == buffs.PREDATORY_SWIFTNESS then
                predatorySwiftnessProc = false
                API.PrintDebug("Predatory Swiftness consumed")
            end
            
            -- Track Bloodtalons
            if spellID == buffs.BLOODTALONS then
                bloodtalonsProc = false
                bloodtalonsStacks = 0
                API.PrintDebug("Bloodtalons consumed")
            end
            
            -- Track Apex Predator's Craving
            if spellID == buffs.APEX_PREDATORS_CRAVING then
                apexPredatorsCravingProc = false
                API.PrintDebug("Apex Predator's Craving consumed")
            end
            
            -- Track Soul of the Forest
            if spellID == buffs.SOUL_OF_THE_FOREST then
                soulOfTheForestProc = false
                API.PrintDebug("Soul of the Forest consumed")
            end
            
            -- Track Sudden Ambush
            if spellID == buffs.SUDDEN_AMBUSH then
                suddenAmbushProc = false
                API.PrintDebug("Sudden Ambush consumed")
            end
            
            -- Track Cat Form
            if spellID == buffs.CAT_FORM then
                inCatForm = false
                API.PrintDebug("Cat Form deactivated")
            end
            
            -- Track Prowl
            if spellID == buffs.PROWL then
                prowlActive = false
                inStealth = false
                API.PrintDebug("Prowl deactivated")
            end
            
            -- Track Wild Slashes
            if spellID == buffs.WILD_SLASHES then
                wildFleshripper = false
                API.PrintDebug("Wild Slashes faded")
            end
            
            -- Track Lunastic Furor
            if spellID == buffs.LUNASTIC_FUROR then
                lunasticFuror = false
                API.PrintDebug("Lunastic Furor faded")
            end
            
            -- Track Rasha Lobo
            if spellID == buffs.RASHA_LOBO then
                rashaLobo = false
                API.PrintDebug("Rasha Lobo faded")
            end
            
            -- Track Unbridled Swarm
            if spellID == buffs.UNBRIDLED_SWARM then
                unbridledSwarm = false
                API.PrintDebug("Unbridled Swarm faded")
            end
            
            -- Track Thrashing Claws
            if spellID == buffs.THRASHING_CLAWS then
                thrashingClaws = 0
                periodicDamageMultiplier = 1.0
                API.PrintDebug("Thrashing Claws faded")
            end
        end
        
        -- Track target debuffs
        -- Update target data when debuffs change
        self:UpdateTargetData()
    end
    
    -- Track Bloodtalons stacks
    if eventType == "SPELL_AURA_APPLIED_DOSE" and spellID == buffs.BLOODTALONS and destGUID == API.GetPlayerGUID() then
        bloodtalonsStacks = select(4, API.GetBuffInfo("player", buffs.BLOODTALONS)) or 0
        API.PrintDebug("Bloodtalons stacks: " .. tostring(bloodtalonsStacks))
    end
    
    -- Track Clearcasting stacks
    if eventType == "SPELL_AURA_APPLIED_DOSE" and spellID == buffs.CLEARCASTING and destGUID == API.GetPlayerGUID() then
        clearcastingStacks = select(4, API.GetBuffInfo("player", buffs.CLEARCASTING)) or 0
        API.PrintDebug("Clearcasting stacks: " .. tostring(clearcastingStacks))
    end
    
    -- Track Carnivoracious stacks
    if eventType == "SPELL_AURA_APPLIED_DOSE" and spellID == buffs.CARNIVORACIOUS and destGUID == API.GetPlayerGUID() then
        carnivoreVoracity = select(4, API.GetBuffInfo("player", buffs.CARNIVORACIOUS)) or 0
        API.PrintDebug("Carnivoracious stacks: " .. tostring(carnivoreVoracity))
    end
    
    -- Track Thrashing Claws stacks
    if eventType == "SPELL_AURA_APPLIED_DOSE" and spellID == buffs.THRASHING_CLAWS and destGUID == API.GetPlayerGUID() then
        thrashingClaws = select(4, API.GetBuffInfo("player", buffs.THRASHING_CLAWS)) or 0
        API.PrintDebug("Thrashing Claws stacks: " .. tostring(thrashingClaws))
        
        -- Each stack increases periodic damage
        periodicDamageMultiplier = 1.0 + (thrashingClaws * 0.03) -- 3% per stack
    end
    
    -- Track spell casts
    if eventType == "SPELL_CAST_SUCCESS" and sourceGUID == API.GetPlayerGUID() then
        if spellID == spells.TIGERS_FURY then
            tigersFuryActive = true
            tigersFuryExpiration = GetTime() + TIGERS_FURY_DURATION
            API.PrintDebug("Tiger's Fury cast")
        elseif spellID == spells.BERSERK then
            berserkActive = true
            berserkExpiration = GetTime() + BERSERK_DURATION
            API.PrintDebug("Berserk cast")
        elseif spellID == spells.INCARNATION then
            incarnationActive = true
            incarnationExpiration = GetTime() + INCARNATION_DURATION
            API.PrintDebug("Incarnation cast")
        elseif spellID == spells.FERAL_FRENZY then
            feralFrenzyOnCooldown = true
            -- Set a timer to track cooldown (20-30 seconds typically)
            C_Timer.After(20, function()
                feralFrenzyOnCooldown = false
                API.PrintDebug("Feral Frenzy cooldown reset")
            end)
            API.PrintDebug("Feral Frenzy cast")
        elseif spellID == spells.BRUTAL_SLASH then
            brutalSlashCharges = API.GetSpellCharges(spells.BRUTAL_SLASH) or 0
            API.PrintDebug("Brutal Slash cast, " .. tostring(brutalSlashCharges) .. " charges remaining")
        elseif spellID == spells.CONVOKE_THE_SPIRITS then
            convokeCooldown = 120 -- 2 minute cooldown
            API.PrintDebug("Convoke the Spirits cast")
        elseif spellID == spells.ADAPTIVE_SWARM then
            adaptiveSwarmCooldown = 25 -- 25 second cooldown
            API.PrintDebug("Adaptive Swarm cast")
        elseif spellID == spells.CAT_FORM then
            inCatForm = true
            API.PrintDebug("Cat Form cast")
        elseif spellID == spells.PROWL then
            prowlActive = true
            inStealth = true
            lastProwlTime = GetTime()
            API.PrintDebug("Prowl cast")
        elseif spellID == spells.FEROCIOUS_BITE then
            -- Check if it was an execute FB
            if inExecutePhase then
                ferociousBite15 = true
                API.PrintDebug("Ferocious Bite used in execute range")
            end
            
            API.PrintDebug("Ferocious Bite cast")
        end
    end
    
    return true
end

-- Main rotation function
function Feral:RunRotation()
    -- Check if we should be running Feral Druid logic
    if API.GetActiveSpecID() ~= FERAL_SPEC_ID then
        return false
    end
    
    -- Skip rotation if player is casting
    if API.IsPlayerCasting() then
        return false
    end
    
    -- Get settings
    local settings = ConfigRegistry:GetSettings("FeralDruid")
    
    -- Update variables
    self:UpdateEnergy()
    self:UpdateComboPoints()
    self:UpdateShapeshiftForm()
    burstModeActive = settings.rotationSettings.burstEnabled and API.ShouldUseBurst()
    self:UpdateTargetData() -- Makes sure we have current target information
    
    -- Handle next cast override
    if nextCastOverride and API.CanCast(nextCastOverride) then
        local spell = nextCastOverride
        nextCastOverride = nil
        API.CastSpell(spell)
        return true
    end
    
    -- Enter Cat Form if not in it and it's enabled
    if not inCatForm and 
       settings.rotationSettings.useCatForm and 
       API.CanCast(spells.CAT_FORM) then
        API.CastSpell(spells.CAT_FORM)
        return true
    end
    
    -- Use Prowl if enabled and not in combat
    if not prowlActive and
       not API.IsInCombat() and
       inCatForm and
       settings.rotationSettings.stealthOpener and
       API.CanCast(spells.PROWL) then
        API.CastSpell(spells.PROWL)
        return true
    end
    
    -- Handle interrupts
    if self:HandleInterrupts() then
        return true
    end
    
    -- Handle defensive abilities
    if self:HandleDefensives(settings) then
        return true
    end
    
    -- Check if we're in cat form
    if not inCatForm then
        -- Skip rest of rotation if not in cat form
        return false
    end
    
    -- Handle cooldowns first
    if self:HandleCooldowns(settings) then
        return true
    end
    
    -- Check if we're in melee range
    if not inMeleeRange then
        -- Skip rest of rotation if not in range
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
function Feral:HandleInterrupts()
    -- Only attempt to interrupt if in melee range and in cat form
    if inMeleeRange and inCatForm and API.CanCast(spells.SKULL_BASH) and API.TargetIsSpellCastable() then
        API.CastSpell(spells.SKULL_BASH)
        return true
    end
    
    -- Use Mighty Bash as backup interrupt if talented
    if inMeleeRange and
       API.CanCast(spells.MIGHTY_BASH) and 
       API.TargetIsSpellCastable() then
        API.CastSpell(spells.MIGHTY_BASH)
        return true
    end
    
    return false
end

-- Handle defensive abilities
function Feral:HandleDefensives(settings)
    local playerHealth = API.GetPlayerHealthPercent()
    
    -- Use Barkskin
    if settings.defensiveSettings.useBarkskin and
       playerHealth <= settings.defensiveSettings.barkskinThreshold and
       API.CanCast(spells.BARKSKIN) then
        API.CastSpell(spells.BARKSKIN)
        return true
    end
    
    -- Use Survival Instincts
    if settings.defensiveSettings.useSurvivalInstincts and
       playerHealth <= settings.defensiveSettings.survivalInstinctsThreshold and
       API.CanCast(spells.SURVIVAL_INSTINCTS) then
        API.CastSpell(spells.SURVIVAL_INSTINCTS)
        return true
    end
    
    -- Use Renewal if talented
    if talents.hasRenewal and
       settings.defensiveSettings.useRenewal and
       playerHealth <= settings.defensiveSettings.renewalThreshold and
       API.CanCast(spells.RENEWAL) then
        API.CastSpell(spells.RENEWAL)
        return true
    end
    
    -- Use Regrowth with Predatory Swiftness
    if settings.defensiveSettings.useRegrowth and
       playerHealth <= settings.defensiveSettings.regrowthThreshold and
       predatorySwiftnessProc and
       API.CanCast(spells.REGROWTH) then
        API.CastSpellOnSelf(spells.REGROWTH)
        return true
    end
    
    -- Switch to Bear Form if health is critically low
    if settings.defensiveSettings.useBearForm and
       playerHealth <= settings.defensiveSettings.bearFormThreshold and
       not API.PlayerHasBuff(buffs.BEAR_FORM) and
       API.CanCast(spells.BEAR_FORM) then
        API.CastSpell(spells.BEAR_FORM)
        return true
    end
    
    return false
end

-- Handle cooldown abilities
function Feral:HandleCooldowns(settings)
    -- Skip if GCD is not ready
    if not API.IsGCDReady() then
        return false
    end
    
    -- Use Tiger's Fury if energy is low or we need the damage buff
    if settings.offensiveSettings.useTigersFury and
       settings.abilityControls.tigersFury.enabled and
       API.CanCast(spells.TIGERS_FURY) and
       not tigersFuryActive then
        
        -- Check if we're low on energy
        if currentEnergy <= TIGERS_FURY_ENERGY_THRESHOLD then
            API.CastSpell(spells.TIGERS_FURY)
            return true
        end
        
        -- Check if we should use for DoT snapshot
        if settings.abilityControls.tigersFury.snapRefreshDots and
           (ripActive and ripExpiration - GetTime() < 6 or
            rakeActive and rakeExpiration - GetTime() < 4) then
            API.CastSpell(spells.TIGERS_FURY)
            return true
        end
    end
    
    -- Skip offensive cooldowns if not in burst mode
    if not burstModeActive then
        return false
    end
    
    -- Use Berserk or Incarnation
    if settings.offensiveSettings.useBerserk and
       settings.abilityControls.berserk.enabled and
       not berserkActive and not incarnationActive then
        
        -- Check if we want to use with Tiger's Fury
        if not settings.offensiveSettings.useBerserkWithTigersFury or tigersFuryActive then
            if talents.hasIncarnationAvatarOfAshamane and API.CanCast(spells.INCARNATION) then
                API.CastSpell(spells.INCARNATION)
                return true
            elseif API.CanCast(spells.BERSERK) then
                API.CastSpell(spells.BERSERK)
                return true
            end
        end
    end
    
    -- Use Feral Frenzy
    if talents.hasFeralFrenzy and
       settings.offensiveSettings.useFeralFrenzy and
       settings.abilityControls.feralFrenzy.enabled and
       not feralFrenzyOnCooldown and
       API.CanCast(spells.FERAL_FRENZY) and
       currentEnergy >= FERAL_FRENZY_COST and
       currentComboPoints >= settings.abilityControls.feralFrenzy.minComboPoints then
        
        -- Check if we want to use with Tiger's Fury
        if not settings.abilityControls.feralFrenzy.useWithTigersFury or tigersFuryActive then
            API.CastSpell(spells.FERAL_FRENZY)
            return true
        end
    end
    
    -- Handle covenant abilities
    if self:HandleCovenantAbilities(settings) then
        return true
    end
    
    return false
end

-- Handle covenant abilities
function Feral:HandleCovenantAbilities(settings)
    -- Convoke the Spirits
    if settings.covenantSettings.useConvoke and
       API.CanCast(spells.CONVOKE_THE_SPIRITS) and
       currentComboPoints >= settings.covenantSettings.convokeMinComboPoints then
        API.CastSpell(spells.CONVOKE_THE_SPIRITS)
        return true
    end
    
    -- Adaptive Swarm
    if settings.covenantSettings.useAdaptiveSwarm and
       API.CanCast(spells.ADAPTIVE_SWARM) then
        API.CastSpell(spells.ADAPTIVE_SWARM)
        return true
    end
    
    -- Ravenous Frenzy
    if settings.covenantSettings.useRavenousFrenzy and
       API.CanCast(spells.RAVENOUS_FRENZY) then
        API.CastSpell(spells.RAVENOUS_FRENZY)
        return true
    end
    
    -- Kindred Spirits
    if settings.covenantSettings.useKindredSpirits and
       API.CanCast(spells.KINDRED_SPIRITS) then
        API.CastSpell(spells.KINDRED_SPIRITS)
        return true
    end
    
    return false
end

-- Handle AoE rotation
function Feral:HandleAoERotation(settings)
    -- Use Primal Wrath if enabled and we have enough combo points and targets
    local primalWrathThreshold = 3 -- Default threshold
    
    if settings.advancedSettings.usePrimalWrath == "4+ Targets" then
        primalWrathThreshold = 4
    elseif settings.advancedSettings.usePrimalWrath == "5+ Targets" then
        primalWrathThreshold = 5
    elseif settings.advancedSettings.usePrimalWrath == "Never" then
        primalWrathThreshold = 999 -- Effectively disable
    end
    
    if talents.hasPrimalWrath and
       currentAoETargets >= primalWrathThreshold and
       currentComboPoints >= 5 and
       API.CanCast(spells.PRIMAL_WRATH) then
        API.CastSpell(spells.PRIMAL_WRATH)
        return true
    end
    
    -- Use Brutal Slash if available and talented
    if talents.hasBrutalSlash and
       settings.offensiveSettings.useBrutalSlash and
       brutalSlashCharges > 0 and
       API.CanCast(spells.BRUTAL_SLASH) then
        API.CastSpell(spells.BRUTAL_SLASH)
        return true
    end
    
    -- Maintain Rake on primary target if needed
    if settings.rotationSettings.maintainRake and
       API.CanCast(spells.RAKE) and
       currentEnergy >= RAKE_COST and
       (not rakeActive or (rakeExpiration - GetTime() < settings.advancedSettings.rakeRefreshThreshold)) then
        API.CastSpell(spells.RAKE)
        return true
    end
    
    -- Maintain Thrash if needed
    if settings.rotationSettings.maintainThrash and
       API.CanCast(spells.THRASH_CAT) and
       currentEnergy >= THRASH_COST and
       (not thrassActive || (thrassExpiration - GetTime() < settings.advancedSettings.thrashRefreshThreshold)) then
        API.CastSpell(spells.THRASH_CAT)
        return true
    end
    
    -- Maintain Moonfire if talented
    if talents.hasLunarInspiration and
       settings.advancedSettings.moonFireMode != "Never" and
       API.CanCast(spells.MOONFIRE_CAT) and
       (settings.advancedSettings.moonFireMode == "Always" || 
        (settings.advancedSettings.moonFireMode == "During Clearcasting" && clearcastingProc)) then
        
        if not moonFireActive || (moonFireExpiration - GetTime() < 4) then
            API.CastSpell(spells.MOONFIRE_CAT)
            return true
        end
    end
    
    -- Use Swipe for AoE damage
    if API.CanCast(spells.SWIPE_CAT) and
       currentEnergy >= 40 and
       (settings.advancedSettings.poolEnergy == false || currentEnergy > settings.advancedSettings.minEnergyForBuilder) then
        API.CastSpell(spells.SWIPE_CAT)
        return true
    }
    
    return false
end

-- Handle Single Target rotation
function Feral:HandleSingleTargetRotation(settings)
    -- Use Tiger's Fury (check if needed in this case)
    if settings.offensiveSettings.useTigersFury and
       currentEnergy < 30 and
       not tigersFuryActive and
       API.CanCast(spells.TIGERS_FURY) then
        API.CastSpell(spells.TIGERS_FURY)
        return true
    end
    
    -- Use Savage Roar if talented and enabled
    if talents.hasSavageRoar and
       settings.offensiveSettings.useSavageRoar and
       currentComboPoints >= 5 and
       not API.PlayerHasBuff(buffs.SAVAGE_ROAR) and
       API.CanCast(spells.SAVAGE_ROAR) then
        API.CastSpell(spells.SAVAGE_ROAR)
        return true
    end
    
    -- Use Ferocious Bite in execute phase if applicable
    if inExecutePhase and
       currentComboPoints >= MIN_COMBO_POINTS_FOR_FB and
       API.CanCast(spells.FEROCIOUS_BITE) and
       currentEnergy >= FEROCIOUS_BITE_COST then
        API.CastSpell(spells.FEROCIOUS_BITE)
        return true
    end
    
    -- Maintain Rip if needed
    if settings.rotationSettings.maintainRip and
       currentComboPoints >= MIN_COMBO_POINTS_FOR_RIP and
       API.CanCast(spells.RIP) and
       currentEnergy >= RIP_COST and
       (not ripActive || (ripExpiration - GetTime() < settings.advancedSettings.ripRefreshThreshold)) then
        API.CastSpell(spells.RIP)
        return true
    end
    
    -- Maintain Rake if needed
    if settings.rotationSettings.maintainRake and
       API.CanCast(spells.RAKE) and
       currentEnergy >= RAKE_COST and
       (not rakeActive || (rakeExpiration - GetTime() < settings.advancedSettings.rakeRefreshThreshold)) then
        API.CastSpell(spells.RAKE)
        return true
    end
    
    -- Maintain Thrash if needed (depending on settings)
    if talents.hasThrashingClaws || talents.hasWildSlashes then
        if settings.rotationSettings.maintainThrash and
           API.CanCast(spells.THRASH_CAT) and
           currentEnergy >= THRASH_COST and
           (not thrassActive || (thrassExpiration - GetTime() < settings.advancedSettings.thrashRefreshThreshold)) then
            API.CastSpell(spells.THRASH_CAT)
            return true
        end
    end
    
    -- Use Ferocious Bite if we have 5 combo points and Rip is active
    if currentComboPoints >= MIN_COMBO_POINTS_FOR_FB and
       API.CanCast(spells.FEROCIOUS_BITE) and
       currentEnergy >= FEROCIOUS_BITE_COST and
       ripActive then
        API.CastSpell(spells.FEROCIOUS_BITE)
        return true
    end
    
    -- Use Shred as main combo point builder
    if API.CanCast(spells.SHRED) and
       currentEnergy >= SHRED_COST and
       (settings.advancedSettings.poolEnergy == false || currentEnergy > settings.advancedSettings.minEnergyForBuilder) then
        API.CastSpell(spells.SHRED)
        return true
    }
    
    return false
end

-- Handle specialization change
function Feral:OnSpecializationChanged()
    -- Update talent information
    self:UpdateTalentInfo()
    
    -- Reset state variables
    nextCastOverride = nil
    burstModeActive = false
    currentEnergy = API.GetPlayerPower()
    maxEnergy = 100
    currentComboPoints = API.GetPlayerComboPoints()
    maxComboPoints = 5
    ripActive = false
    ripExpiration = 0
    rakeActive = false
    rakeExpiration = 0
    thrassActive = false
    thrassExpiration = 0
    moonFireActive = false
    moonFireExpiration = 0
    prowlActive = false
    inCatForm = API.PlayerHasBuff(buffs.CAT_FORM)
    tigersFuryActive = false
    tigersFuryExpiration = 0
    berserkActive = false
    berserkExpiration = 0
    incarnationActive = false
    incarnationExpiration = 0
    clearcastingProc = false
    clearcastingStacks = 0
    predatorySwiftnessProc = false
    bloodtalonsProc = false 
    bloodtalonsStacks = 0
    bloodtalonsExpiration = 0
    apexPredatorsCravingProc = false
    soulOfTheForestProc = false
    suddenAmbushProc = false
    savageMomentumProc = false
    convokeCooldown = 0
    adaptiveSwarmCooldown = 0
    feralFrenzyOnCooldown = false
    brutalSlashCharges = API.GetSpellCharges(spells.BRUTAL_SLASH) or 0
    thrashDebuffCount = 0
    inMeleeRange = false
    inExecutePhase = false
    inStealth = prowlActive
    momentOfClarity = false
    sabortoothActive = false
    carnivoreVoracity = 0
    limeBite = false
    tearOpenWounds = false
    ferociousBite15 = false
    lunasticFuror = false
    rashaLobo = false
    scentOfBlood = false
    unbridledSwarm = false
    lastProwlTime = 0
    wildFleshripper = false
    ironJaws = false
    carnivorousInstinct = false
    thrashingClaws = 0
    periodicDamageMultiplier = 1.0
    savageryDebuffCount = 0
    
    -- Clear target data
    self.targetData = {}
    
    API.PrintDebug("Feral Druid state reset on spec change")
    
    return true
end

-- Return the module for loading
return Feral