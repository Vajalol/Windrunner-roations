------------------------------------------
-- WindrunnerRotations - Survival Hunter Module
-- Author: VortexQ8
-- The War Within Season 2
------------------------------------------

local Survival = {}
-- This will be assigned to addon.Classes.Hunter.Survival when loaded

-- These will be set when the file is loaded in our test environment
local API
local ConfigRegistry
local AAC
local Hunter

-- Cache frequently accessed data
local spells = {}
local talents = {}
local buffs = {}
local debuffs = {}

-- State tracking variables
local nextCastOverride = nil
local burstModeActive = false
local currentAoETargets = 0
local currentFocus = 0
local maxFocus = 100
local coordinatedAssaultActive = false
local coordinatedAssaultEndTime = 0
local wildfireInfusionActive = false
local wildfireInfusionEndTime = 0
local mongooseFuryActive = false
local mongooseFuryStacks = 0
local mongooseFuryEndTime = 0
local termsOfEngagementActive = false
local termsOfEngagementEndTime = 0
local viperStingActive = false
local viperStingEndTime = 0
local serpentStingActive = {}
local serpentStingEndTime = {}
local internalBleedingActive = {}
local internalBleedingEndTime = {}
local lateralThoughtsActive = false
local lateralThoughtsStacks = 0
local lateralThoughtsEndTime = 0
local madBombardiersActive = false
local madBombardiersEndTime = 0
local naturesMendingActive = false
local naturesMendingEndTime = 0
local frenzyActive = false
local frenzyStacks = 0
local frenzyEndTime = 0
local bloodseekerActive = {}
local bloodseekerEndTime = {}
local flankingStrikeReady = false
local flankingStrikeReadyTime = 0
local wildfireBombCharges = 0
local wildfireBombMaxCharges = 0
local harpoonCharges = 0
local harpoonMaxCharges = 0
local carveCharges = 0
local carveMaxCharges = 0
local aspectOfEagleActive = false
local aspectOfEagleEndTime = 0
local petActive = false
local petFrenzyActive = false
local petFrenzyStacks = 0
local petFrenzyEndTime = 0
local petHealthPercent = 100
local shrapnelBombActive = false
local pheromoneBombActive = false
local volatileBombActive = false
local inMeleeRange = false
local killCommand = false
local rapiderFire = false
local serpentSting = false
local flankingStrike = false
local carve = false
local butchery = false
local mongoose = false
local chakrams = false
local wildfireBomb = false
local coordinatedAssault = false
local aspectOfEagle = false
local harpoon = false
local muzzle = false
local intimidation = false
local tranquilizing = false
local freezingTrap = false
local tarTrap = false
local steelTrap = false
local bindingShot = false
local disengage = false
local camouflage = false
local furyOfTheEagle = false
local sixBitePoison = false
local wildInstincts = false
local stingIntoTorpor = false
local bombardiersGuile = false
local alphaStrike = false
local spearhead = false
local enhancedWildfireOrTerms = false
local hydrasBite = false
local explosiveTrap = false
local guerrillaTactics = false
local tipOfTheSpear = false
local vipersVenom = false
local termsOfEngagement = false
local deathChakram = false
local stampede = false
local steelTrap = false
local flankingStrikeReset = false
local playerHealth = 100
local bloodseekerBleed = false
local meatHawk = false
local ruthlessMarauder = false
local deadlyDuo = false
local rangerSpear = false
local raptor = false
local bloodyFrenzy = false
local nesingwarysTrappingApparatus = false
local deadEye = false
local frenzyBand = false
local fuzzySabercat = false

-- Constants
local SURVIVAL_SPEC_ID = 255
local DEFAULT_AOE_THRESHOLD = 3
local COORDINATED_ASSAULT_DURATION = 20 -- seconds
local WILDFIRE_INFUSION_DURATION = 6 -- seconds
local MONGOOSE_FURY_DURATION = 14 -- seconds
local TERMS_OF_ENGAGEMENT_DURATION = 10 -- seconds
local VIPER_STING_DURATION = 6 -- seconds
local SERPENT_STING_DURATION = 12 -- seconds (base)
local INTERNAL_BLEEDING_DURATION = 9 -- seconds
local LATERAL_THOUGHTS_DURATION = 8 -- seconds
local MAD_BOMBARDIERS_DURATION = 8 -- seconds
local NATURES_MENDING_DURATION = 10 -- seconds
local FRENZY_DURATION = 8 -- seconds
local BLOODSEEKER_DURATION = 8 -- seconds
local FLANKING_STRIKE_READY_DURATION = 3 -- seconds
local ASPECT_OF_EAGLE_DURATION = 15 -- seconds
local MELEE_RANGE = 5 -- yards

-- Initialize the Survival module
function Survival:Initialize()
    self:RegisterSpells()
    self:RegisterVariables()
    self:RegisterSettings()
    self:RegisterEvents()
    
    API.PrintDebug("Survival Hunter module initialized")
    
    return true
end

-- Register spell IDs
function Survival:RegisterSpells()
    -- Core rotational abilities
    spells.KILL_COMMAND = 259489
    spells.RAPTOR_STRIKE = 186270
    spells.MONGOOSE_BITE = 259387
    spells.CARVE = 187708
    spells.BUTCHERY = 212436
    spells.SERPENT_STING = 259491
    spells.WILDFIRE_BOMB = 259495
    spells.CHAKRAMS = 259391
    spells.COORDINATED_ASSAULT = 266779
    spells.ASPECT_OF_THE_EAGLE = 186289
    spells.HARPOON = 190925
    spells.FLANKING_STRIKE = 269751
    spells.FURY_OF_THE_EAGLE = 203415
    
    -- Core utilities
    spells.MUZZLE = 187707
    spells.INTIMIDATION = 19577
    spells.MISDIRECTION = 34477
    spells.FEIGN_DEATH = 5384
    spells.MEND_PET = 136
    spells.REVIVE_PET = 982
    spells.CALL_PET_1 = 883
    spells.CALL_PET_2 = 83242
    spells.CALL_PET_3 = 83243
    spells.CALL_PET_4 = 83244
    spells.CALL_PET_5 = 83245
    spells.DISMISS_PET = 2641
    spells.EXHILARATION = 109304
    spells.ASPECT_OF_THE_CHEETAH = 186257
    spells.ASPECT_OF_THE_TURTLE = 186265
    spells.TRANQUILIZING_SHOT = 19801
    spells.FLARE = 1543
    spells.FREEZING_TRAP = 187650
    spells.TAR_TRAP = 187698
    spells.STEEL_TRAP = 162488
    spells.BINDING_SHOT = 109248
    spells.DISENGAGE = 781
    spells.CAMOUFLAGE = 199483
    
    -- Wildfire Infusion bombs
    spells.SHRAPNEL_BOMB = 270335
    spells.PHEROMONE_BOMB = 270323
    spells.VOLATILE_BOMB = 271045
    
    -- Talents and passives
    spells.WILDFIRE_INFUSION = 271014
    spells.VIPERS_VENOM = 268501
    spells.BIRDS_OF_PREY = 260331
    spells.ALPHA_PREDATOR = 269737
    spells.GUERRILLA_TACTICS = 264332
    spells.HYDRAS_BITE = 260241
    spells.BUTCHERY = 212436
    spells.MONGOOSE_BITE = 259387
    spells.FLANKING_STRIKE = 269751
    spells.BLOODSEEKER = 260248
    spells.WILDFIRE_BOMB = 259495
    spells.TIP_OF_THE_SPEAR = 260285
    spells.STEEL_TRAP = 162488
    spells.CHAKRAMS = 259391
    spells.TERMS_OF_ENGAGEMENT = 265895
    spells.BORN_TO_BE_WILD = 266921
    spells.POSTHASTE = 109215
    spells.TRAILBLAZER = 199921
    spells.NATURAL_MENDING = 270581
    spells.CAMOUFLAGE = 199483
    spells.ASPECT_OF_THE_EAGLE = 186289
    spells.ANIMAL_INSTINCTS = 378442
    spells.EXPLOSIVE_SHOT = 212431
    spells.STAMPEDE = 201430
    spells.SPEARHEAD = 360966
    spells.COORDINATED_KILL = 385739
    spells.RANGER = 385695
    spells.DEADLY_DUO = 378962
    spells.RANGER_SPEAR = 378215
    spells.RAPTOR_STRIKE = 186270
    spells.BLOODY_FRENZY = 385710
    spells.INTENSITY = 385700
    spells.BOMB_CHUCKER = 388644
    spells.DEATH_CHAKRAM = 375891
    spells.FURY_OF_THE_EAGLE = 203415
    spells.FLANKING_STRIKE_RESET = 263186
    spells.WILDERNESS_SURVIVAL = 385146
    spells.BOMBARDIERS_GUILE = 388857
    spells.STING_INTO_TORPOR = 388458
    spells.WILD_INSTINCTS = 378217
    spells.SIX_BITE_POISON = 388849
    spells.ALPHA_STRIKE = 269391
    spells.VENOM_COATED_BOLTS = 387845
    spells.BALANCED_CHAKRAMS = 384792
    spells.MARROW_SPIKE = 384814
    spells.GUERRILLA_WARFARE = 264339
    spells.IMPROVED_TRAPS = 343242
    spells.ENHANCED_BOLAS = 389023
    spells.ENTRAPMENT = 393950
    spells.PRECISE_CALIBRATION = 381303
    spells.BLOODY_CLEAVE = 343207
    spells.SURVIVAL_TACTICS = 388059
    spells.KINSHIP = 264263
    spells.IMPROVED_KILL_COMMAND = 343243
    spells.REJUVENATING_WIND = 385539
    
    -- War Within Season 2 specific
    spells.MEAT_HAWK = 385739
    spells.RUTHLESS_MARAUDER = 385718
    spells.DEADLY_DUO = 378962
    spells.RANGER_SPEAR = 378215
    spells.RAPTOR = 385695
    spells.BLOODY_FRENZY = 385710
    spells.NESINGWARYS_TRAPPING_APPARATUS = 336742
    spells.DEAD_EYE = 321460
    spells.FRENZY_BAND = 378748
    spells.FUZZY_SABERCAT = 378779
    
    -- Covenant abilities (for reference, converted in WoW 10.0)
    spells.RESONATING_ARROW = 308491
    spells.WILD_SPIRITS = 328231
    spells.FLAYED_SHOT = 324149
    spells.DEATH_CHAKRAM = 325028
    
    -- Buff IDs
    spells.COORDINATED_ASSAULT_BUFF = 266779
    spells.WILDFIRE_INFUSION_BUFF = 271788
    spells.MONGOOSE_FURY_BUFF = 259388
    spells.TERMS_OF_ENGAGEMENT_BUFF = 265898
    spells.VIPERS_VENOM_BUFF = 268552
    spells.LATERAL_THOUGHTS_BUFF = 385432
    spells.MAD_BOMBARDIERS_BUFF = 386875
    spells.NATURES_MENDING_BUFF = 270581
    spells.FRENZY_BUFF = 272790
    spells.SPEARHEAD_BUFF = 360966
    spells.ASPECT_OF_THE_EAGLE_BUFF = 186289
    
    -- Debuff IDs
    spells.SERPENT_STING_DEBUFF = 259491
    spells.INTERNAL_BLEEDING_DEBUFF = 270343
    spells.BLOODSEEKER_DEBUFF = 259277
    spells.STEEL_TRAP_DEBUFF = 162480
    spells.SHRAPNEL_BOMB_DEBUFF = 270339
    spells.PHEROMONE_BOMB_DEBUFF = 270332
    spells.VOLATILE_BOMB_DEBUFF = 271049
    
    -- Register all spells with the API tracking system
    for spellName, spellID in pairs(spells) do
        API.RegisterSpell(spellID)
    end
    
    -- Define aura tracking
    buffs.COORDINATED_ASSAULT = spells.COORDINATED_ASSAULT_BUFF
    buffs.WILDFIRE_INFUSION = spells.WILDFIRE_INFUSION_BUFF
    buffs.MONGOOSE_FURY = spells.MONGOOSE_FURY_BUFF
    buffs.TERMS_OF_ENGAGEMENT = spells.TERMS_OF_ENGAGEMENT_BUFF
    buffs.VIPERS_VENOM = spells.VIPERS_VENOM_BUFF
    buffs.LATERAL_THOUGHTS = spells.LATERAL_THOUGHTS_BUFF
    buffs.MAD_BOMBARDIERS = spells.MAD_BOMBARDIERS_BUFF
    buffs.NATURES_MENDING = spells.NATURES_MENDING_BUFF
    buffs.FRENZY = spells.FRENZY_BUFF
    buffs.SPEARHEAD = spells.SPEARHEAD_BUFF
    buffs.ASPECT_OF_THE_EAGLE = spells.ASPECT_OF_THE_EAGLE_BUFF
    
    debuffs.SERPENT_STING = spells.SERPENT_STING_DEBUFF
    debuffs.INTERNAL_BLEEDING = spells.INTERNAL_BLEEDING_DEBUFF
    debuffs.BLOODSEEKER = spells.BLOODSEEKER_DEBUFF
    debuffs.STEEL_TRAP = spells.STEEL_TRAP_DEBUFF
    debuffs.SHRAPNEL_BOMB = spells.SHRAPNEL_BOMB_DEBUFF
    debuffs.PHEROMONE_BOMB = spells.PHEROMONE_BOMB_DEBUFF
    debuffs.VOLATILE_BOMB = spells.VOLATILE_BOMB_DEBUFF
    
    return true
end

-- Register variables to track
function Survival:RegisterVariables()
    -- Talent tracking
    talents.hasWildfireInfusion = false
    talents.hasVipersVenom = false
    talents.hasBirdsOfPrey = false
    talents.hasAlphaPredator = false
    talents.hasGuerrillaTactics = false
    talents.hasHydrasBite = false
    talents.hasButchery = false
    talents.hasMongooseBite = false
    talents.hasFlankingStrike = false
    talents.hasBloodseeker = false
    talents.hasWildfireBomb = false
    talents.hasTipOfTheSpear = false
    talents.hasSteelTrap = false
    talents.hasChakrams = false
    talents.hasTermsOfEngagement = false
    talents.hasBornToBeWild = false
    talents.hasPosthaste = false
    talents.hasTrailblazer = false
    talents.hasNaturalMending = false
    talents.hasCamouflage = false
    talents.hasAspectOfTheEagle = false
    talents.hasAnimalInstincts = false
    talents.hasExplosiveShot = false
    talents.hasStampede = false
    talents.hasSpearhead = false
    talents.hasCoordinatedKill = false
    talents.hasRanger = false
    talents.hasDeadlyDuo = false
    talents.hasRangerSpear = false
    talents.hasRaptorStrike = false
    talents.hasBloodyFrenzy = false
    talents.hasIntensity = false
    talents.hasBombChucker = false
    talents.hasDeathChakram = false
    talents.hasFuryOfTheEagle = false
    talents.hasFlankingStrikeReset = false
    talents.hasWildernessSurvival = false
    talents.hasBombardiersGuile = false
    talents.hasStingIntoTorpor = false
    talents.hasWildInstincts = false
    talents.hasSixBitePoison = false
    talents.hasAlphaStrike = false
    talents.hasVenomCoatedBolts = false
    talents.hasBalancedChakrams = false
    talents.hasMarrowSpike = false
    talents.hasGuerrillaWarfare = false
    talents.hasImprovedTraps = false
    talents.hasEnhancedBolas = false
    talents.hasEntrapment = false
    talents.hasPreciseCalibration = false
    talents.hasBloodyLeave = false
    talents.hasSurvivalTactics = false
    talents.hasKinship = false
    talents.hasImprovedKillCommand = false
    talents.hasRejuvenatingWind = false
    
    -- War Within Season 2 talents
    talents.hasMeatHawk = false
    talents.hasRuthlessMarauder = false
    talents.hasDeadlyDuo = false
    talents.hasRangerSpear = false
    talents.hasRaptor = false
    talents.hasBloodyFrenzy = false
    talents.hasNesingwarysTrappingApparatus = false
    talents.hasDeadEye = false
    talents.hasFrenzyBand = false
    talents.hasFuzzySabercat = false
    
    -- Initialize resources
    currentFocus = API.GetPlayerPower()
    
    -- Initialize spell charges
    wildfireBombCharges = API.GetSpellCharges(spells.WILDFIRE_BOMB) or 0
    wildfireBombMaxCharges = API.GetSpellMaxCharges(spells.WILDFIRE_BOMB) or 1
    
    harpoonCharges = API.GetSpellCharges(spells.HARPOON) or 0
    harpoonMaxCharges = API.GetSpellMaxCharges(spells.HARPOON) or 1
    
    if talents.hasButchery then
        carveCharges = API.GetSpellCharges(spells.BUTCHERY) or 0
        carveMaxCharges = API.GetSpellMaxCharges(spells.BUTCHERY) or 3
    else
        carveCharges = API.GetSpellCharges(spells.CARVE) or 0
        carveMaxCharges = API.GetSpellMaxCharges(spells.CARVE) or 1
    end
    
    -- Check if pet exists
    petActive = API.HasActivePet()
    
    -- Initialize debuff tracking tables
    serpentStingActive = {}
    serpentStingEndTime = {}
    internalBleedingActive = {}
    internalBleedingEndTime = {}
    bloodseekerActive = {}
    bloodseekerEndTime = {}
    
    return true
end

-- Register spec-specific settings
function Survival:RegisterSettings()
    ConfigRegistry:RegisterSettings("SurvivalHunter", {
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
            focusPooling = {
                displayName = "Focus Pooling",
                description = "Pool focus for important abilities",
                type = "toggle",
                default = true
            },
            focusPoolingThreshold = {
                displayName = "Focus Pooling Threshold",
                description = "Minimum focus to maintain",
                type = "slider",
                min = 10,
                max = 70,
                default = 40
            },
            usePetActive = {
                displayName = "Use Pet",
                description = "Summon and use pet",
                type = "toggle",
                default = true
            },
            preferredPet = {
                displayName = "Preferred Pet",
                description = "Pet to summon when needed",
                type = "dropdown",
                options = {"Ferocity", "Tenacity", "Cunning"},
                default = "Ferocity"
            },
            useRaptorStrike = {
                displayName = "Use Raptor Strike",
                description = "Use Raptor Strike instead of Mongoose Bite if talented both",
                type = "toggle",
                default = false
            },
            useFlankingStrike = {
                displayName = "Use Flanking Strike",
                description = "Automatically use Flanking Strike when talented",
                type = "toggle",
                default = true
            }
        },
        
        dotSettings = {
            useSerpentSting = {
                displayName = "Use Serpent Sting",
                description = "Automatically apply and maintain Serpent Sting",
                type = "toggle",
                default = true
            },
            serpentStingTriggerLimit = {
                displayName = "Serpent Sting Target Limit",
                description = "Maximum targets to apply Serpent Sting",
                type = "slider",
                min = 1,
                max = 6,
                default = 3
            },
            serpentStingRefreshThreshold = {
                displayName = "Serpent Sting Refresh Threshold",
                description = "Seconds remaining to refresh Serpent Sting",
                type = "slider",
                min = 1,
                max = 8,
                default = 3
            },
            useInternalBleeding = {
                displayName = "Use Internal Bleeding",
                description = "Aim to apply Internal Bleeding with Shrapnel Bomb",
                type = "toggle",
                default = true
            }
        },
        
        bombSettings = {
            useWildfireBomb = {
                displayName = "Use Wildfire Bomb",
                description = "Automatically use Wildfire Bomb",
                type = "toggle",
                default = true
            },
            bombChargesReserved = {
                displayName = "Bomb Charges Reserved",
                description = "Charges to save for specific moments",
                type = "slider",
                min = 0,
                max = 2,
                default = 0
            },
            useInfusionSpecifically = {
                displayName = "Use Infusion Bombs Specifically",
                description = "Use specific bomb types in optimal situations",
                type = "toggle",
                default = true
            },
            preferredBomb = {
                displayName = "Preferred Bomb Type",
                description = "Bomb to prioritize if all are available",
                type = "dropdown",
                options = {"Shrapnel", "Pheromone", "Volatile", "Situational"},
                default = "Situational"
            }
        },
        
        cooldownSettings = {
            useCoordinatedAssault = {
                displayName = "Use Coordinated Assault",
                description = "Automatically use Coordinated Assault",
                type = "toggle",
                default = true
            },
            coordinatedAssaultMode = {
                displayName = "Coordinated Assault Usage",
                description = "When to use Coordinated Assault",
                type = "dropdown",
                options = {"On Cooldown", "With Wildfire Bomb", "Burst Only"},
                default = "On Cooldown"
            },
            useAspectOfTheEagle = {
                displayName = "Use Aspect of the Eagle",
                description = "Automatically use Aspect of the Eagle when talented",
                type = "toggle",
                default = true
            },
            eagleAspectMode = {
                displayName = "Eagle Aspect Usage",
                description = "When to use Aspect of the Eagle",
                type = "dropdown",
                options = {"On Cooldown", "With Coordinated Assault", "Burst Only"},
                default = "With Coordinated Assault"
            },
            useChakrams = {
                displayName = "Use Chakrams",
                description = "Automatically use Chakrams when talented",
                type = "toggle",
                default = true
            },
            chakramsMode = {
                displayName = "Chakrams Usage",
                description = "When to use Chakrams",
                type = "dropdown",
                options = {"On Cooldown", "AoE Only", "ST Priority"},
                default = "On Cooldown"
            },
            useStampede = {
                displayName = "Use Stampede",
                description = "Automatically use Stampede when talented",
                type = "toggle",
                default = true
            },
            useFuryOfTheEagle = {
                displayName = "Use Fury of the Eagle",
                description = "Automatically use Fury of the Eagle when talented",
                type = "toggle",
                default = true
            },
            furyOfTheEagleMode = {
                displayName = "Fury of the Eagle Usage",
                description = "When to use Fury of the Eagle",
                type = "dropdown",
                options = {"On Cooldown", "With Mongoose Fury", "AoE Only"},
                default = "With Mongoose Fury"
            }
        },
        
        defensiveSettings = {
            useExhilaration = {
                displayName = "Use Exhilaration",
                description = "Automatically use Exhilaration",
                type = "toggle",
                default = true
            },
            exhilarationThreshold = {
                displayName = "Exhilaration Health Threshold",
                description = "Health percentage to use Exhilaration",
                type = "slider",
                min = 20,
                max = 70,
                default = 40
            },
            useAspectOfTheTurtle = {
                displayName = "Use Aspect of the Turtle",
                description = "Automatically use Aspect of the Turtle",
                type = "toggle",
                default = true
            },
            aspectOfTheTurtleThreshold = {
                displayName = "Aspect of the Turtle Health Threshold",
                description = "Health percentage to use Aspect of the Turtle",
                type = "slider",
                min = 10,
                max = 40,
                default = 20
            },
            useMendPet = {
                displayName = "Use Mend Pet",
                description = "Automatically use Mend Pet",
                type = "toggle",
                default = true
            },
            mendPetThreshold = {
                displayName = "Mend Pet Health Threshold",
                description = "Pet health percentage to use Mend Pet",
                type = "slider",
                min = 20,
                max = 80,
                default = 60
            },
            useFeignDeath = {
                displayName = "Use Feign Death",
                description = "Automatically use Feign Death in emergencies",
                type = "toggle",
                default = true
            },
            feignDeathThreshold = {
                displayName = "Feign Death Health Threshold",
                description = "Health percentage to use Feign Death",
                type = "slider",
                min = 5,
                max = 30,
                default = 15
            }
        },
        
        utilitySettings = {
            useTranquilizingShot = {
                displayName = "Use Tranquilizing Shot",
                description = "Automatically use Tranquilizing Shot to remove buffs",
                type = "toggle",
                default = true
            },
            useFreezingTrap = {
                displayName = "Use Freezing Trap",
                description = "Automatically use Freezing Trap",
                type = "toggle",
                default = true
            },
            useBindingShot = {
                displayName = "Use Binding Shot",
                description = "Automatically use Binding Shot for crowd control",
                type = "toggle",
                default = true
            },
            bindingShotMinTargets = {
                displayName = "Binding Shot Min Targets",
                description = "Minimum targets to use Binding Shot",
                type = "slider",
                min = 2,
                max = 5,
                default = 3
            },
            useMisdirection = {
                displayName = "Use Misdirection",
                description = "Automatically use Misdirection",
                type = "toggle",
                default = true
            },
            misdirectionTarget = {
                displayName = "Misdirection Target",
                description = "Where to send Misdirection",
                type = "dropdown",
                options = {"Tank", "Pet", "Focus", "Manual Only"},
                default = "Tank"
            },
            useHarpoon = {
                displayName = "Use Harpoon",
                description = "Automatically use Harpoon to gap close",
                type = "toggle",
                default = true
            }
        },
        
        -- Advanced ability control settings
        abilityControls = {
            -- Coordinated Assault controls
            coordinatedAssault = AAC.RegisterAbility(spells.COORDINATED_ASSAULT, {
                enabled = true,
                useDuringBurstOnly = false,
                requireBloodseeker = false,
                minTargets = 1
            }),
            
            -- Wildfire Bomb controls
            wildfireBomb = AAC.RegisterAbility(spells.WILDFIRE_BOMB, {
                enabled = true,
                useDuringBurstOnly = false,
                preferShrampel = true,
                preferPheromone = false,
                preferVolatile = false
            }),
            
            -- Flanking Strike controls
            flankingStrike = AAC.RegisterAbility(spells.FLANKING_STRIKE, {
                enabled = true,
                useDuringBurstOnly = false,
                saveForFocus = true,
                minFocus = 25
            })
        }
    })
    
    return true
end

-- Register for events 
function Survival:RegisterEvents()
    -- Register for combat log events to track procs and buffs
    API.RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", function(...) 
        self:HandleCombatLogEvent(...) 
    end)
    
    -- Register for focus updates
    API.RegisterEvent("UNIT_POWER_FREQUENT", function(unit, powerType) 
        if unit == "player" and powerType == "FOCUS" then
            self:UpdateFocus()
        end
    end)
    
    -- Register for health updates
    API.RegisterEvent("UNIT_HEALTH", function(unit) 
        if unit == "player" then
            self:UpdateHealth()
        elseif unit == "pet" then
            self:UpdatePetHealth()
        end
    end)
    
    -- Register for target change events
    API.RegisterEvent("PLAYER_TARGET_CHANGED", function() 
        self:UpdateTargetData() 
    end)
    
    -- Register for pet events
    API.RegisterEvent("UNIT_PET", function(unit) 
        if unit == "player" then
            self:UpdatePetStatus()
        end
    end)
    
    -- Register for spell cast events
    API.RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", function(unit, _, spellID)
        if unit == "player" then
            self:HandleSpellCastSucceeded(spellID)
        end
    end)
    
    -- Register for talent update events
    API.RegisterEvent("PLAYER_TALENT_UPDATE", function() 
        self:UpdateTalentInfo() 
    end)
    
    -- Initial talent info update
    self:UpdateTalentInfo()
    
    -- Initial pet status check
    self:UpdatePetStatus()
    
    return true
end

-- Update talent information
function Survival:UpdateTalentInfo()
    -- Check for important talents
    talents.hasWildfireInfusion = API.HasTalent(spells.WILDFIRE_INFUSION)
    talents.hasVipersVenom = API.HasTalent(spells.VIPERS_VENOM)
    talents.hasBirdsOfPrey = API.HasTalent(spells.BIRDS_OF_PREY)
    talents.hasAlphaPredator = API.HasTalent(spells.ALPHA_PREDATOR)
    talents.hasGuerrillaTactics = API.HasTalent(spells.GUERRILLA_TACTICS)
    talents.hasHydrasBite = API.HasTalent(spells.HYDRAS_BITE)
    talents.hasButchery = API.HasTalent(spells.BUTCHERY)
    talents.hasMongooseBite = API.HasTalent(spells.MONGOOSE_BITE)
    talents.hasFlankingStrike = API.HasTalent(spells.FLANKING_STRIKE)
    talents.hasBloodseeker = API.HasTalent(spells.BLOODSEEKER)
    talents.hasWildfireBomb = API.IsSpellKnown(spells.WILDFIRE_BOMB)
    talents.hasTipOfTheSpear = API.HasTalent(spells.TIP_OF_THE_SPEAR)
    talents.hasSteelTrap = API.HasTalent(spells.STEEL_TRAP)
    talents.hasChakrams = API.HasTalent(spells.CHAKRAMS)
    talents.hasTermsOfEngagement = API.HasTalent(spells.TERMS_OF_ENGAGEMENT)
    talents.hasBornToBeWild = API.HasTalent(spells.BORN_TO_BE_WILD)
    talents.hasPosthaste = API.HasTalent(spells.POSTHASTE)
    talents.hasTrailblazer = API.HasTalent(spells.TRAILBLAZER)
    talents.hasNaturalMending = API.HasTalent(spells.NATURAL_MENDING)
    talents.hasCamouflage = API.HasTalent(spells.CAMOUFLAGE)
    talents.hasAspectOfTheEagle = API.HasTalent(spells.ASPECT_OF_THE_EAGLE)
    talents.hasAnimalInstincts = API.HasTalent(spells.ANIMAL_INSTINCTS)
    talents.hasExplosiveShot = API.HasTalent(spells.EXPLOSIVE_SHOT)
    talents.hasStampede = API.HasTalent(spells.STAMPEDE)
    talents.hasSpearhead = API.HasTalent(spells.SPEARHEAD)
    talents.hasCoordinatedKill = API.HasTalent(spells.COORDINATED_KILL)
    talents.hasRanger = API.HasTalent(spells.RANGER)
    talents.hasDeadlyDuo = API.HasTalent(spells.DEADLY_DUO)
    talents.hasRangerSpear = API.HasTalent(spells.RANGER_SPEAR)
    talents.hasRaptorStrike = API.IsSpellKnown(spells.RAPTOR_STRIKE)
    talents.hasBloodyFrenzy = API.HasTalent(spells.BLOODY_FRENZY)
    talents.hasIntensity = API.HasTalent(spells.INTENSITY)
    talents.hasBombChucker = API.HasTalent(spells.BOMB_CHUCKER)
    talents.hasDeathChakram = API.HasTalent(spells.DEATH_CHAKRAM)
    talents.hasFuryOfTheEagle = API.HasTalent(spells.FURY_OF_THE_EAGLE)
    talents.hasFlankingStrikeReset = API.HasTalent(spells.FLANKING_STRIKE_RESET)
    talents.hasWildernessSurvival = API.HasTalent(spells.WILDERNESS_SURVIVAL)
    talents.hasBombardiersGuile = API.HasTalent(spells.BOMBARDIERS_GUILE)
    talents.hasStingIntoTorpor = API.HasTalent(spells.STING_INTO_TORPOR)
    talents.hasWildInstincts = API.HasTalent(spells.WILD_INSTINCTS)
    talents.hasSixBitePoison = API.HasTalent(spells.SIX_BITE_POISON)
    talents.hasAlphaStrike = API.HasTalent(spells.ALPHA_STRIKE)
    talents.hasVenomCoatedBolts = API.HasTalent(spells.VENOM_COATED_BOLTS)
    talents.hasBalancedChakrams = API.HasTalent(spells.BALANCED_CHAKRAMS)
    talents.hasMarrowSpike = API.HasTalent(spells.MARROW_SPIKE)
    talents.hasGuerrillaWarfare = API.HasTalent(spells.GUERRILLA_WARFARE)
    talents.hasImprovedTraps = API.HasTalent(spells.IMPROVED_TRAPS)
    talents.hasEnhancedBolas = API.HasTalent(spells.ENHANCED_BOLAS)
    talents.hasEntrapment = API.HasTalent(spells.ENTRAPMENT)
    talents.hasPreciseCalibration = API.HasTalent(spells.PRECISE_CALIBRATION)
    talents.hasBloodyLeave = API.HasTalent(spells.BLOODY_CLEAVE)
    talents.hasSurvivalTactics = API.HasTalent(spells.SURVIVAL_TACTICS)
    talents.hasKinship = API.HasTalent(spells.KINSHIP)
    talents.hasImprovedKillCommand = API.HasTalent(spells.IMPROVED_KILL_COMMAND)
    talents.hasRejuvenatingWind = API.HasTalent(spells.REJUVENATING_WIND)
    
    -- War Within Season 2 talents
    talents.hasMeatHawk = API.HasTalent(spells.MEAT_HAWK)
    talents.hasRuthlessMarauder = API.HasTalent(spells.RUTHLESS_MARAUDER)
    talents.hasDeadlyDuo = API.HasTalent(spells.DEADLY_DUO)
    talents.hasRangerSpear = API.HasTalent(spells.RANGER_SPEAR)
    talents.hasRaptor = API.HasTalent(spells.RAPTOR)
    talents.hasBloodyFrenzy = API.HasTalent(spells.BLOODY_FRENZY)
    talents.hasNesingwarysTrappingApparatus = API.HasTalent(spells.NESINGWARYS_TRAPPING_APPARATUS)
    talents.hasDeadEye = API.HasTalent(spells.DEAD_EYE)
    talents.hasFrenzyBand = API.HasTalent(spells.FRENZY_BAND)
    talents.hasFuzzySabercat = API.HasTalent(spells.FUZZY_SABERCAT)
    
    -- Set specialized variables based on talents
    if API.IsSpellKnown(spells.KILL_COMMAND) then
        killCommand = true
    end
    
    if talents.hasRaptorStrike then
        rapiderFire = true
    end
    
    if API.IsSpellKnown(spells.SERPENT_STING) then
        serpentSting = true
    end
    
    if talents.hasFlankingStrike then
        flankingStrike = true
    end
    
    if API.IsSpellKnown(spells.CARVE) then
        carve = true
    end
    
    if talents.hasButchery then
        butchery = true
    end
    
    if talents.hasMongooseBite then
        mongoose = true
    end
    
    if talents.hasChakrams then
        chakrams = true
    end
    
    if talents.hasWildfireBomb then
        wildfireBomb = true
    end
    
    if API.IsSpellKnown(spells.COORDINATED_ASSAULT) then
        coordinatedAssault = true
    end
    
    if talents.hasAspectOfTheEagle then
        aspectOfEagle = true
    end
    
    if API.IsSpellKnown(spells.HARPOON) then
        harpoon = true
    end
    
    if API.IsSpellKnown(spells.MUZZLE) then
        muzzle = true
    end
    
    if API.IsSpellKnown(spells.INTIMIDATION) then
        intimidation = true
    end
    
    if API.IsSpellKnown(spells.TRANQUILIZING_SHOT) then
        tranquilizing = true
    end
    
    if API.IsSpellKnown(spells.FREEZING_TRAP) then
        freezingTrap = true
    end
    
    if API.IsSpellKnown(spells.TAR_TRAP) then
        tarTrap = true
    end
    
    if talents.hasSteelTrap then
        steelTrap = true
    end
    
    if API.IsSpellKnown(spells.BINDING_SHOT) then
        bindingShot = true
    end
    
    if API.IsSpellKnown(spells.DISENGAGE) then
        disengage = true
    end
    
    if talents.hasCamouflage then
        camouflage = true
    end
    
    if talents.hasFuryOfTheEagle then
        furyOfTheEagle = true
    end
    
    if talents.hasSixBitePoison then
        sixBitePoison = true
    end
    
    if talents.hasWildInstincts then
        wildInstincts = true
    end
    
    if talents.hasStingIntoTorpor then
        stingIntoTorpor = true
    end
    
    if talents.hasBombardiersGuile then
        bombardiersGuile = true
    end
    
    if talents.hasAlphaStrike then
        alphaStrike = true
    end
    
    if talents.hasSpearhead then
        spearhead = true
    end
    
    -- These are flags for enhanced behaviors rather than specific abilities
    if talents.hasWildfireInfusion or talents.hasTermsOfEngagement then
        enhancedWildfireOrTerms = true
    end
    
    if talents.hasHydrasBite then
        hydrasBite = true
    end
    
    if API.IsSpellKnown(spells.EXPLOSIVE_TRAP) then
        explosiveTrap = true
    end
    
    if talents.hasGuerrillaTactics then
        guerrillaTactics = true
    end
    
    if talents.hasTipOfTheSpear then
        tipOfTheSpear = true
    end
    
    if talents.hasVipersVenom then
        vipersVenom = true
    end
    
    if talents.hasTermsOfEngagement then
        termsOfEngagement = true
    end
    
    if talents.hasDeathChakram then
        deathChakram = true
    end
    
    if talents.hasStampede then
        stampede = true
    end
    
    if talents.hasFlankingStrikeReset then
        flankingStrikeReset = true
    end
    
    if talents.hasBloodseeker then
        bloodseekerBleed = true
    end
    
    if talents.hasMeatHawk then
        meatHawk = true
    end
    
    if talents.hasRuthlessMarauder then
        ruthlessMarauder = true
    end
    
    if talents.hasDeadlyDuo then
        deadlyDuo = true
    end
    
    if talents.hasRangerSpear then
        rangerSpear = true
    end
    
    if talents.hasRaptor then
        raptor = true
    end
    
    if talents.hasBloodyFrenzy then
        bloodyFrenzy = true
    end
    
    if talents.hasNesingwarysTrappingApparatus then
        nesingwarysTrappingApparatus = true
    end
    
    if talents.hasDeadEye then
        deadEye = true
    end
    
    if talents.hasFrenzyBand then
        frenzyBand = true
    end
    
    if talents.hasFuzzySabercat then
        fuzzySabercat = true
    end
    
    -- Initialize bomb charges after checking talents
    wildfireBombCharges = API.GetSpellCharges(spells.WILDFIRE_BOMB) or 0
    wildfireBombMaxCharges = API.GetSpellMaxCharges(spells.WILDFIRE_BOMB) or 1
    
    if guerrillaTactics then
        wildfireBombMaxCharges = 2
    end
    
    API.PrintDebug("Survival Hunter talents updated")
    
    return true
end

-- Update focus tracking
function Survival:UpdateFocus()
    currentFocus = API.GetPlayerPower()
    return true
end

-- Update health tracking
function Survival:UpdateHealth()
    playerHealth = API.GetPlayerHealthPercent()
    return true
end

-- Update pet health tracking
function Survival:UpdatePetHealth()
    if petActive then
        petHealthPercent = API.GetPetHealthPercent()
    else
        petHealthPercent = 100
    end
    return true
end

-- Update pet status
function Survival:UpdatePetStatus()
    petActive = API.HasActivePet()
    return true
end

-- Update target data
function Survival:UpdateTargetData()
    -- Check if in melee range
    inMeleeRange = API.IsUnitInRange("target", MELEE_RANGE)
    
    -- Get target GUID
    local targetGUID = API.GetTargetGUID()
    
    if targetGUID and targetGUID ~= "" then
        -- Check for Serpent Sting
        if serpentSting then
            local serpentStingInfo = API.GetDebuffInfo(targetGUID, debuffs.SERPENT_STING)
            if serpentStingInfo then
                serpentStingActive[targetGUID] = true
                serpentStingEndTime[targetGUID] = select(6, serpentStingInfo)
            else
                serpentStingActive[targetGUID] = false
                serpentStingEndTime[targetGUID] = 0
            end
        end
        
        -- Check for Internal Bleeding
        local internalBleedingInfo = API.GetDebuffInfo(targetGUID, debuffs.INTERNAL_BLEEDING)
        if internalBleedingInfo then
            internalBleedingActive[targetGUID] = true
            internalBleedingEndTime[targetGUID] = select(6, internalBleedingInfo)
        else
            internalBleedingActive[targetGUID] = false
            internalBleedingEndTime[targetGUID] = 0
        end
        
        -- Check for Bloodseeker
        if bloodseekerBleed then
            local bloodseekerInfo = API.GetDebuffInfo(targetGUID, debuffs.BLOODSEEKER)
            if bloodseekerInfo then
                bloodseekerActive[targetGUID] = true
                bloodseekerEndTime[targetGUID] = select(6, bloodseekerInfo)
            else
                bloodseekerActive[targetGUID] = false
                bloodseekerEndTime[targetGUID] = 0
            end
        end
        
        -- Check for bomb debuffs
        local shrapnelBombInfo = API.GetDebuffInfo(targetGUID, debuffs.SHRAPNEL_BOMB)
        if shrapnelBombInfo then
            shrapnelBombActive = true
        else
            shrapnelBombActive = false
        end
        
        local pheromoneBombInfo = API.GetDebuffInfo(targetGUID, debuffs.PHEROMONE_BOMB)
        if pheromoneBombInfo then
            pheromoneBombActive = true
        else
            pheromoneBombActive = false
        end
        
        local volatileBombInfo = API.GetDebuffInfo(targetGUID, debuffs.VOLATILE_BOMB)
        if volatileBombInfo then
            volatileBombActive = true
        else
            volatileBombActive = false
        end
    end
    
    -- Update AoE targets count
    currentAoETargets = API.GetNearbyEnemiesCount(8) -- Carve/Butchery radius
    
    return true
end

-- Handle spell cast events
function Survival:HandleSpellCastSucceeded(spellID)
    -- Update wildfire bomb charges
    if spellID == spells.WILDFIRE_BOMB or spellID == spells.SHRAPNEL_BOMB or 
       spellID == spells.PHEROMONE_BOMB or spellID == spells.VOLATILE_BOMB then
        wildfireBombCharges = API.GetSpellCharges(spells.WILDFIRE_BOMB) or 0
        API.PrintDebug("Wildfire Bomb cast, charges remaining: " .. tostring(wildfireBombCharges))
    end
    
    -- Update carve/butchery charges
    if spellID == spells.CARVE or spellID == spells.BUTCHERY then
        if talents.hasButchery then
            carveCharges = API.GetSpellCharges(spells.BUTCHERY) or 0
            API.PrintDebug("Butchery cast, charges remaining: " .. tostring(carveCharges))
        else
            carveCharges = API.GetSpellCharges(spells.CARVE) or 0
            API.PrintDebug("Carve cast, charges remaining: " .. tostring(carveCharges))
        end
    end
    
    -- Update harpoon charges
    if spellID == spells.HARPOON then
        harpoonCharges = API.GetSpellCharges(spells.HARPOON) or 0
        API.PrintDebug("Harpoon cast, charges remaining: " .. tostring(harpoonCharges))
    end
    
    -- Track Flanking Strike readiness
    if flankingStrikeReset and (spellID == spells.KILL_COMMAND or spellID == spells.MONGOOSE_BITE or spellID == spells.RAPTOR_STRIKE) then
        -- Check if Flanking Strike is reset by Kill Command
        if flankingStrike and API.GetSpellCooldown(spells.FLANKING_STRIKE) == 0 then
            flankingStrikeReady = true
            flankingStrikeReadyTime = GetTime() + FLANKING_STRIKE_READY_DURATION
            API.PrintDebug("Flanking Strike ready from reset")
        end
    end
    
    return true
end

-- Handle combat log events
function Survival:HandleCombatLogEvent(...)
    local timestamp, eventType, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, spellID, spellName = CombatLogGetCurrentEventInfo()
    
    -- Track buff applications
    if eventType == "SPELL_AURA_APPLIED" or eventType == "SPELL_AURA_REFRESH" then
        -- Track player buffs
        if destGUID == API.GetPlayerGUID() then
            -- Track Coordinated Assault
            if spellID == buffs.COORDINATED_ASSAULT then
                coordinatedAssaultActive = true
                coordinatedAssaultEndTime = GetTime() + COORDINATED_ASSAULT_DURATION
                API.PrintDebug("Coordinated Assault activated")
            end
            
            -- Track Wildfire Infusion
            if spellID == buffs.WILDFIRE_INFUSION then
                wildfireInfusionActive = true
                wildfireInfusionEndTime = GetTime() + WILDFIRE_INFUSION_DURATION
                API.PrintDebug("Wildfire Infusion activated")
            end
            
            -- Track Mongoose Fury
            if spellID == buffs.MONGOOSE_FURY then
                mongooseFuryActive = true
                mongooseFuryStacks = select(4, API.GetBuffInfo("player", buffs.MONGOOSE_FURY)) or 1
                mongooseFuryEndTime = select(6, API.GetBuffInfo("player", buffs.MONGOOSE_FURY))
                API.PrintDebug("Mongoose Fury activated: " .. tostring(mongooseFuryStacks) .. " stacks")
            end
            
            -- Track Terms of Engagement
            if spellID == buffs.TERMS_OF_ENGAGEMENT then
                termsOfEngagementActive = true
                termsOfEngagementEndTime = GetTime() + TERMS_OF_ENGAGEMENT_DURATION
                API.PrintDebug("Terms of Engagement activated")
            end
            
            -- Track Viper's Venom
            if spellID == buffs.VIPERS_VENOM then
                viperStingActive = true
                viperStingEndTime = GetTime() + VIPER_STING_DURATION
                API.PrintDebug("Viper's Venom activated")
            end
            
            -- Track Lateral Thoughts
            if spellID == buffs.LATERAL_THOUGHTS then
                lateralThoughtsActive = true
                lateralThoughtsStacks = select(4, API.GetBuffInfo("player", buffs.LATERAL_THOUGHTS)) or 1
                lateralThoughtsEndTime = select(6, API.GetBuffInfo("player", buffs.LATERAL_THOUGHTS))
                API.PrintDebug("Lateral Thoughts activated: " .. tostring(lateralThoughtsStacks) .. " stacks")
            end
            
            -- Track Mad Bombardiers
            if spellID == buffs.MAD_BOMBARDIERS then
                madBombardiersActive = true
                madBombardiersEndTime = GetTime() + MAD_BOMBARDIERS_DURATION
                API.PrintDebug("Mad Bombardiers activated")
            end
            
            -- Track Nature's Mending
            if spellID == buffs.NATURES_MENDING then
                naturesMendingActive = true
                naturesMendingEndTime = GetTime() + NATURES_MENDING_DURATION
                API.PrintDebug("Nature's Mending activated")
            end
            
            -- Track Spearhead
            if spellID == buffs.SPEARHEAD then
                API.PrintDebug("Spearhead activated")
            end
            
            -- Track Aspect of the Eagle
            if spellID == buffs.ASPECT_OF_THE_EAGLE then
                aspectOfEagleActive = true
                aspectOfEagleEndTime = GetTime() + ASPECT_OF_EAGLE_DURATION
                API.PrintDebug("Aspect of the Eagle activated")
            end
        end
        
        -- Track pet buffs
        if API.GetPetGUID() == destGUID then
            -- Track Frenzy
            if spellID == buffs.FRENZY then
                petFrenzyActive = true
                petFrenzyStacks = select(4, API.GetBuffInfo("pet", buffs.FRENZY)) or 1
                petFrenzyEndTime = select(6, API.GetBuffInfo("pet", buffs.FRENZY))
                API.PrintDebug("Pet Frenzy activated: " .. tostring(petFrenzyStacks) .. " stacks")
            end
        end
        
        -- Track target debuffs
        if destGUID and destGUID ~= "" then
            -- Track Serpent Sting
            if spellID == debuffs.SERPENT_STING and sourceGUID == API.GetPlayerGUID() then
                serpentStingActive[destGUID] = true
                serpentStingEndTime[destGUID] = GetTime() + SERPENT_STING_DURATION
                API.PrintDebug("Serpent Sting applied to " .. destName)
            end
            
            -- Track Internal Bleeding
            if spellID == debuffs.INTERNAL_BLEEDING and sourceGUID == API.GetPlayerGUID() then
                internalBleedingActive[destGUID] = true
                internalBleedingEndTime[destGUID] = GetTime() + INTERNAL_BLEEDING_DURATION
                API.PrintDebug("Internal Bleeding applied to " .. destName)
            end
            
            -- Track Bloodseeker
            if spellID == debuffs.BLOODSEEKER and sourceGUID == API.GetPlayerGUID() then
                bloodseekerActive[destGUID] = true
                bloodseekerEndTime[destGUID] = GetTime() + BLOODSEEKER_DURATION
                API.PrintDebug("Bloodseeker applied to " .. destName)
            end
            
            -- Track bomb debuffs
            if spellID == debuffs.SHRAPNEL_BOMB and sourceGUID == API.GetPlayerGUID() then
                shrapnelBombActive = true
                API.PrintDebug("Shrapnel Bomb applied to " .. destName)
            elseif spellID == debuffs.PHEROMONE_BOMB and sourceGUID == API.GetPlayerGUID() then
                pheromoneBombActive = true
                API.PrintDebug("Pheromone Bomb applied to " .. destName)
            elseif spellID == debuffs.VOLATILE_BOMB and sourceGUID == API.GetPlayerGUID() then
                volatileBombActive = true
                API.PrintDebug("Volatile Bomb applied to " .. destName)
            end
        end
    end
    
    -- Track buff removals
    if eventType == "SPELL_AURA_REMOVED" then
        -- Track player buff removals
        if destGUID == API.GetPlayerGUID() then
            -- Track Coordinated Assault
            if spellID == buffs.COORDINATED_ASSAULT then
                coordinatedAssaultActive = false
                API.PrintDebug("Coordinated Assault faded")
            end
            
            -- Track Wildfire Infusion
            if spellID == buffs.WILDFIRE_INFUSION then
                wildfireInfusionActive = false
                API.PrintDebug("Wildfire Infusion faded")
            end
            
            -- Track Mongoose Fury
            if spellID == buffs.MONGOOSE_FURY then
                mongooseFuryActive = false
                mongooseFuryStacks = 0
                API.PrintDebug("Mongoose Fury faded")
            end
            
            -- Track Terms of Engagement
            if spellID == buffs.TERMS_OF_ENGAGEMENT then
                termsOfEngagementActive = false
                API.PrintDebug("Terms of Engagement faded")
            end
            
            -- Track Viper's Venom
            if spellID == buffs.VIPERS_VENOM then
                viperStingActive = false
                API.PrintDebug("Viper's Venom faded")
            end
            
            -- Track Lateral Thoughts
            if spellID == buffs.LATERAL_THOUGHTS then
                lateralThoughtsActive = false
                lateralThoughtsStacks = 0
                API.PrintDebug("Lateral Thoughts faded")
            end
            
            -- Track Mad Bombardiers
            if spellID == buffs.MAD_BOMBARDIERS then
                madBombardiersActive = false
                API.PrintDebug("Mad Bombardiers faded")
            end
            
            -- Track Nature's Mending
            if spellID == buffs.NATURES_MENDING then
                naturesMendingActive = false
                API.PrintDebug("Nature's Mending faded")
            end
            
            -- Track Aspect of the Eagle
            if spellID == buffs.ASPECT_OF_THE_EAGLE then
                aspectOfEagleActive = false
                API.PrintDebug("Aspect of the Eagle faded")
            end
        end
        
        -- Track pet buff removals
        if API.GetPetGUID() == destGUID then
            -- Track Frenzy
            if spellID == buffs.FRENZY then
                petFrenzyActive = false
                petFrenzyStacks = 0
                API.PrintDebug("Pet Frenzy faded")
            end
        end
        
        -- Track debuff removals
        if destGUID and destGUID ~= "" then
            -- Track Serpent Sting
            if spellID == debuffs.SERPENT_STING and serpentStingActive[destGUID] then
                serpentStingActive[destGUID] = false
                serpentStingEndTime[destGUID] = 0
                API.PrintDebug("Serpent Sting faded from " .. destName)
            end
            
            -- Track Internal Bleeding
            if spellID == debuffs.INTERNAL_BLEEDING and internalBleedingActive[destGUID] then
                internalBleedingActive[destGUID] = false
                internalBleedingEndTime[destGUID] = 0
                API.PrintDebug("Internal Bleeding faded from " .. destName)
            end
            
            -- Track Bloodseeker
            if spellID == debuffs.BLOODSEEKER and bloodseekerActive[destGUID] then
                bloodseekerActive[destGUID] = false
                bloodseekerEndTime[destGUID] = 0
                API.PrintDebug("Bloodseeker faded from " .. destName)
            end
            
            -- Track bomb debuffs
            if spellID == debuffs.SHRAPNEL_BOMB then
                shrapnelBombActive = false
                API.PrintDebug("Shrapnel Bomb faded from " .. destName)
            elseif spellID == debuffs.PHEROMONE_BOMB then
                pheromoneBombActive = false
                API.PrintDebug("Pheromone Bomb faded from " .. destName)
            elseif spellID == debuffs.VOLATILE_BOMB then
                volatileBombActive = false
                API.PrintDebug("Volatile Bomb faded from " .. destName)
            end
        end
    end
    
    -- Track Mongoose Fury stacks
    if eventType == "SPELL_AURA_APPLIED_DOSE" and spellID == buffs.MONGOOSE_FURY and destGUID == API.GetPlayerGUID() then
        mongooseFuryStacks = select(4, API.GetBuffInfo("player", buffs.MONGOOSE_FURY)) or 0
        API.PrintDebug("Mongoose Fury stacks: " .. tostring(mongooseFuryStacks))
    end
    
    -- Track Lateral Thoughts stacks
    if eventType == "SPELL_AURA_APPLIED_DOSE" and spellID == buffs.LATERAL_THOUGHTS and destGUID == API.GetPlayerGUID() then
        lateralThoughtsStacks = select(4, API.GetBuffInfo("player", buffs.LATERAL_THOUGHTS)) or 0
        API.PrintDebug("Lateral Thoughts stacks: " .. tostring(lateralThoughtsStacks))
    end
    
    -- Track Pet Frenzy stacks
    if eventType == "SPELL_AURA_APPLIED_DOSE" and spellID == buffs.FRENZY and destGUID == API.GetPetGUID() then
        petFrenzyStacks = select(4, API.GetBuffInfo("pet", buffs.FRENZY)) or 0
        API.PrintDebug("Pet Frenzy stacks: " .. tostring(petFrenzyStacks))
    end
    
    -- Track spell casts
    if eventType == "SPELL_CAST_SUCCESS" then
        if sourceGUID == API.GetPlayerGUID() then
            if spellID == spells.HARPOON then
                -- Track Terms of Engagement
                if talents.hasTermsOfEngagement then
                    termsOfEngagementActive = true
                    termsOfEngagementEndTime = GetTime() + TERMS_OF_ENGAGEMENT_DURATION
                    API.PrintDebug("Terms of Engagement activated from Harpoon")
                end
                
                API.PrintDebug("Harpoon cast")
            elseif spellID == spells.WILDFIRE_BOMB or spellID == spells.SHRAPNEL_BOMB or 
                   spellID == spells.PHEROMONE_BOMB or spellID == spells.VOLATILE_BOMB then
                API.PrintDebug("Wildfire Bomb cast")
            elseif spellID == spells.COORDINATED_ASSAULT then
                coordinatedAssaultActive = true
                coordinatedAssaultEndTime = GetTime() + COORDINATED_ASSAULT_DURATION
                API.PrintDebug("Coordinated Assault cast")
            elseif spellID == spells.ASPECT_OF_THE_EAGLE then
                aspectOfEagleActive = true
                aspectOfEagleEndTime = GetTime() + ASPECT_OF_EAGLE_DURATION
                API.PrintDebug("Aspect of the Eagle cast")
            elseif spellID == spells.MONGOOSE_BITE then
                -- Check Mongoose Fury activation
                if not mongooseFuryActive then
                    mongooseFuryActive = true
                    mongooseFuryStacks = 1
                    mongooseFuryEndTime = GetTime() + MONGOOSE_FURY_DURATION
                    API.PrintDebug("Mongoose Fury activated from Mongoose Bite")
                end
                
                API.PrintDebug("Mongoose Bite cast")
            elseif spellID == spells.FLANKING_STRIKE then
                -- Reset tracking for Flanking Strike ready
                flankingStrikeReady = false
                API.PrintDebug("Flanking Strike cast")
            elseif spellID == spells.KILL_COMMAND then
                -- Track Bloodseeker application (if talented)
                if bloodseekerBleed then
                    local targetGUID = API.GetTargetGUID()
                    if targetGUID then
                        bloodseekerActive[targetGUID] = true
                        bloodseekerEndTime[targetGUID] = GetTime() + BLOODSEEKER_DURATION
                        API.PrintDebug("Bloodseeker applied from Kill Command")
                    end
                end
                
                API.PrintDebug("Kill Command cast")
            elseif spellID == spells.CHAKRAMS then
                API.PrintDebug("Chakrams cast")
            elseif spellID == spells.FURY_OF_THE_EAGLE then
                API.PrintDebug("Fury of the Eagle cast")
            elseif spellID == spells.STAMPEDE then
                API.PrintDebug("Stampede cast")
            elseif spellID == spells.DEATH_CHAKRAM then
                API.PrintDebug("Death Chakram cast")
            end
        end
    end
    
    return true
end

-- Main rotation function
function Survival:RunRotation()
    -- Check if we should be running Survival Hunter logic
    if API.GetActiveSpecID() ~= SURVIVAL_SPEC_ID then
        return false
    end
    
    -- Skip rotation if player is casting
    if API.IsPlayerCasting() then
        return false
    end
    
    -- Get settings
    local settings = ConfigRegistry:GetSettings("SurvivalHunter")
    
    -- Update variables
    self:UpdateFocus()
    burstModeActive = settings.rotationSettings.burstEnabled and API.ShouldUseBurst()
    self:UpdateTargetData() -- Makes sure we have current target information
    
    -- Handle next cast override
    if nextCastOverride and API.CanCast(nextCastOverride) then
        local spell = nextCastOverride
        nextCastOverride = nil
        API.CastSpell(spell)
        return true
    end
    
    -- Check if we need to summon a pet
    if settings.rotationSettings.usePetActive and not petActive then
        if API.CanCast(spells.CALL_PET_1) then
            API.CastSpell(spells.CALL_PET_1)
            return true
        end
    end
    
    -- Heal pet if needed
    if petActive and settings.defensiveSettings.useMendPet and 
       petHealthPercent <= settings.defensiveSettings.mendPetThreshold and
       API.CanCast(spells.MEND_PET) then
        API.CastSpell(spells.MEND_PET)
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
    
    -- Handle crowd control and utility
    if self:HandleUtilities(settings) then
        return true
    end
    
    -- Skip if not in melee range
    if not inMeleeRange then
        -- Handle ranged abilities if not in melee range
        return self:HandleRangedAbilities(settings)
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
function Survival:HandleInterrupts()
    -- Only attempt to interrupt if in range
    if inMeleeRange and API.CanCast(spells.MUZZLE) and API.TargetIsSpellCastable() then
        API.CastSpell(spells.MUZZLE)
        return true
    end
    
    return false
end

-- Handle defensive abilities
function Survival:HandleDefensives(settings)
    -- Use Exhilaration
    if settings.defensiveSettings.useExhilaration and
       playerHealth <= settings.defensiveSettings.exhilarationThreshold and
       API.CanCast(spells.EXHILARATION) then
        API.CastSpell(spells.EXHILARATION)
        return true
    end
    
    -- Use Aspect of the Turtle
    if settings.defensiveSettings.useAspectOfTheTurtle and
       playerHealth <= settings.defensiveSettings.aspectOfTheTurtleThreshold and
       API.CanCast(spells.ASPECT_OF_THE_TURTLE) then
        API.CastSpell(spells.ASPECT_OF_THE_TURTLE)
        return true
    end
    
    -- Use Feign Death
    if settings.defensiveSettings.useFeignDeath and
       playerHealth <= settings.defensiveSettings.feignDeathThreshold and
       API.CanCast(spells.FEIGN_DEATH) then
        API.CastSpell(spells.FEIGN_DEATH)
        return true
    end
    
    return false
end

-- Handle crowd control and utility
function Survival:HandleUtilities(settings)
    -- Use Tranquilizing Shot
    if settings.utilitySettings.useTranquilizingShot and
       API.TargetHasDispellableBuff() and
       API.CanCast(spells.TRANQUILIZING_SHOT) then
        API.CastSpell(spells.TRANQUILIZING_SHOT)
        return true
    end
    
    -- Use Freezing Trap
    if settings.utilitySettings.useFreezingTrap and
       API.TargetNeedsCrowdControl() and
       API.CanCast(spells.FREEZING_TRAP) then
        API.CastSpellAtTarget(spells.FREEZING_TRAP)
        return true
    end
    
    -- Use Binding Shot
    if settings.utilitySettings.useBindingShot and
       currentAoETargets >= settings.utilitySettings.bindingShotMinTargets and
       API.CanCast(spells.BINDING_SHOT) then
        API.CastSpellAtTarget(spells.BINDING_SHOT)
        return true
    end
    
    -- Use Misdirection
    if settings.utilitySettings.useMisdirection and
       API.IsInGroup() and
       API.CanCast(spells.MISDIRECTION) then
        
        local mdTarget = "pet"
        
        if settings.utilitySettings.misdirectionTarget == "Tank" then
            if API.GetTank() then
                mdTarget = API.GetTank()
            end
        elseif settings.utilitySettings.misdirectionTarget == "Focus" then
            if API.UnitExists("focus") then
                mdTarget = "focus"
            end
        elseif settings.utilitySettings.misdirectionTarget == "Manual Only" then
            return false
        end
        
        API.CastSpellOnUnit(spells.MISDIRECTION, mdTarget)
        return true
    end
    
    return false
end

-- Handle ranged abilities when not in melee range
function Survival:HandleRangedAbilities(settings)
    -- Use Harpoon to gap close
    if settings.utilitySettings.useHarpoon and
       API.CanCast(spells.HARPOON) then
        API.CastSpell(spells.HARPOON)
        return true
    end
    
    -- Use Wildfire Bomb at range
    if settings.bombSettings.useWildfireBomb and
       wildfireBombCharges > settings.bombSettings.bombChargesReserved and
       API.CanCast(spells.WILDFIRE_BOMB) then
        API.CastSpellAtTarget(spells.WILDFIRE_BOMB)
        return true
    end
    
    -- Use Serpent Sting at range to apply DoT
    if serpentSting and
       settings.dotSettings.useSerpentSting and
       API.CanCast(spells.SERPENT_STING) then
        
        local targetGUID = API.GetTargetGUID()
        
        if targetGUID and (not serpentStingActive[targetGUID] or 
                          (serpentStingActive[targetGUID] and 
                           serpentStingEndTime[targetGUID] - GetTime() < settings.dotSettings.serpentStingRefreshThreshold)) then
            API.CastSpell(spells.SERPENT_STING)
            return true
        end
    end
    
    return false
end

-- Handle cooldown abilities
function Survival:HandleCooldowns(settings)
    -- Skip offensive cooldowns if not in burst mode or not in combat
    if not API.IsInCombat() then
        return false
    end
    
    -- Use Coordinated Assault
    if coordinatedAssault and
       settings.cooldownSettings.useCoordinatedAssault and
       settings.abilityControls.coordinatedAssault.enabled and
       not coordinatedAssaultActive and
       API.CanCast(spells.COORDINATED_ASSAULT) then
        
        -- Check if should only use during burst
        if not settings.abilityControls.coordinatedAssault.useDuringBurstOnly or burstModeActive then
            -- Check additional requirements
            local shouldUseCoordinated = false
            
            if settings.cooldownSettings.coordinatedAssaultMode == "On Cooldown" then
                shouldUseCoordinated = true
            elseif settings.cooldownSettings.coordinatedAssaultMode == "With Wildfire Bomb" then
                shouldUseCoordinated = wildfireBombCharges > 0
            elseif settings.cooldownSettings.coordinatedAssaultMode == "Burst Only" then
                shouldUseCoordinated = burstModeActive
            end
            
            if settings.abilityControls.coordinatedAssault.requireBloodseeker then
                local targetGUID = API.GetTargetGUID()
                if not targetGUID or not bloodseekerActive[targetGUID] then
                    shouldUseCoordinated = false
                end
            end
            
            if currentAoETargets < settings.abilityControls.coordinatedAssault.minTargets then
                shouldUseCoordinated = false
            end
            
            if shouldUseCoordinated then
                API.CastSpell(spells.COORDINATED_ASSAULT)
                return true
            end
        end
    end
    
    -- Use Aspect of the Eagle
    if aspectOfEagle and
       settings.cooldownSettings.useAspectOfTheEagle and
       not aspectOfEagleActive and
       API.CanCast(spells.ASPECT_OF_THE_EAGLE) then
        
        local shouldUseEagle = false
        
        if settings.cooldownSettings.eagleAspectMode == "On Cooldown" then
            shouldUseEagle = true
        elseif settings.cooldownSettings.eagleAspectMode == "With Coordinated Assault" then
            shouldUseEagle = coordinatedAssaultActive
        elseif settings.cooldownSettings.eagleAspectMode == "Burst Only" then
            shouldUseEagle = burstModeActive
        end
        
        if shouldUseEagle then
            API.CastSpell(spells.ASPECT_OF_THE_EAGLE)
            return true
        end
    end
    
    -- Use Chakrams
    if chakrams and
       settings.cooldownSettings.useChakrams and
       API.CanCast(spells.CHAKRAMS) then
        
        local shouldUseChakrams = false
        
        if settings.cooldownSettings.chakramsMode == "On Cooldown" then
            shouldUseChakrams = true
        elseif settings.cooldownSettings.chakramsMode == "AoE Only" then
            shouldUseChakrams = currentAoETargets >= settings.rotationSettings.aoeThreshold
        elseif settings.cooldownSettings.chakramsMode == "ST Priority" then
            shouldUseChakrams = currentAoETargets < settings.rotationSettings.aoeThreshold
        end
        
        if shouldUseChakrams then
            API.CastSpellAtTarget(spells.CHAKRAMS)
            return true
        end
    end
    
    -- Use Stampede
    if stampede and
       settings.cooldownSettings.useStampede and
       API.CanCast(spells.STAMPEDE) then
        API.CastSpellAtTarget(spells.STAMPEDE)
        return true
    end
    
    -- Use Fury of the Eagle
    if furyOfTheEagle and
       settings.cooldownSettings.useFuryOfTheEagle and
       API.CanCast(spells.FURY_OF_THE_EAGLE) then
        
        local shouldUseFury = false
        
        if settings.cooldownSettings.furyOfTheEagleMode == "On Cooldown" then
            shouldUseFury = true
        elseif settings.cooldownSettings.furyOfTheEagleMode == "With Mongoose Fury" then
            shouldUseFury = mongooseFuryActive and mongooseFuryStacks >= 5
        elseif settings.cooldownSettings.furyOfTheEagleMode == "AoE Only" then
            shouldUseFury = currentAoETargets >= settings.rotationSettings.aoeThreshold
        end
        
        if shouldUseFury then
            API.CastSpellAtTarget(spells.FURY_OF_THE_EAGLE)
            return true
        end
    end
    
    return false
end

-- Handle AoE rotation
function Survival:HandleAoERotation(settings)
    -- Get target GUID
    local targetGUID = API.GetTargetGUID()
    
    -- Apply and maintain Serpent Sting
    if serpentSting and
       settings.dotSettings.useSerpentSting and
       targetGUID and
       (not serpentStingActive[targetGUID] || 
        (serpentStingActive[targetGUID] and 
         serpentStingEndTime[targetGUID] - GetTime() < settings.dotSettings.serpentStingRefreshThreshold)) and
       API.CanCast(spells.SERPENT_STING) then
        API.CastSpell(spells.SERPENT_STING)
        return true
    end
    
    -- Use Wildfire Bomb for AoE
    if settings.bombSettings.useWildfireBomb and
       wildfireBombCharges > settings.bombSettings.bombChargesReserved and
       API.CanCast(spells.WILDFIRE_BOMB) then
        
        -- Handle different bomb types if Wildfire Infusion is talented
        if talents.hasWildfireInfusion and settings.bombSettings.useInfusionSpecifically then
            -- Choose optimal bomb type based on situation and preferences
            local preferredBomb = settings.bombSettings.preferredBomb
            
            if preferredBomb == "Shrapnel" or 
               (preferredBomb == "Situational" and settings.dotSettings.useInternalBleeding and currentAoETargets >= 3) then
                if API.CanCast(spells.SHRAPNEL_BOMB) then
                    API.CastSpellAtTarget(spells.SHRAPNEL_BOMB)
                    return true
                end
            elseif preferredBomb == "Pheromone" or 
                   (preferredBomb == "Situational" and currentFocus < 50) then
                if API.CanCast(spells.PHEROMONE_BOMB) then
                    API.CastSpellAtTarget(spells.PHEROMONE_BOMB)
                    return true
                end
            elseif preferredBomb == "Volatile" or 
                   (preferredBomb == "Situational" and currentAoETargets >= 5) then
                if API.CanCast(spells.VOLATILE_BOMB) then
                    API.CastSpellAtTarget(spells.VOLATILE_BOMB)
                    return true
                end
            end
        end
        
        -- Default to regular Wildfire Bomb
        API.CastSpellAtTarget(spells.WILDFIRE_BOMB)
        return true
    end
    
    -- Use Carve or Butchery for AoE
    if butchery and carveCharges > 0 and API.CanCast(spells.BUTCHERY) then
        API.CastSpell(spells.BUTCHERY)
        return true
    elseif carve and API.CanCast(spells.CARVE) then
        API.CastSpell(spells.CARVE)
        return true
    end
    
    -- Use Kill Command
    if killCommand and API.CanCast(spells.KILL_COMMAND) then
        API.CastSpell(spells.KILL_COMMAND)
        return true
    end
    
    -- Use Flanking Strike if talented and appropriate
    if flankingStrike and 
       settings.rotationSettings.useFlankingStrike and
       API.CanCast(spells.FLANKING_STRIKE) then
        API.CastSpell(spells.FLANKING_STRIKE)
        return true
    end
    
    -- Choose between Mongoose Bite and Raptor Strike
    if mongoose and 
       (settings.rotationSettings.useRaptorStrike == false or not talents.hasRaptorStrike) and
       API.CanCast(spells.MONGOOSE_BITE) then
        API.CastSpell(spells.MONGOOSE_BITE)
        return true
    elseif rapiderFire and API.CanCast(spells.RAPTOR_STRIKE) then
        API.CastSpell(spells.RAPTOR_STRIKE)
        return true
    end
    
    return false
end

-- Handle Single Target rotation
function Survival:HandleSingleTargetRotation(settings)
    -- Get target GUID
    local targetGUID = API.GetTargetGUID()
    
    -- Apply and maintain Serpent Sting
    if serpentSting and
       settings.dotSettings.useSerpentSting and
       targetGUID and
       (not serpentStingActive[targetGUID] || 
        (serpentStingActive[targetGUID] and 
         serpentStingEndTime[targetGUID] - GetTime() < settings.dotSettings.serpentStingRefreshThreshold)) and
       API.CanCast(spells.SERPENT_STING) then
        
        -- Use free Serpent Sting from Viper's Venom proc if available
        if vipersVenom then
            if viperStingActive then
                API.CastSpell(spells.SERPENT_STING)
                return true
            end
        else
            API.CastSpell(spells.SERPENT_STING)
            return true
        end
    end
    
    -- Use Wildfire Bomb if available
    if settings.bombSettings.useWildfireBomb and
       wildfireBombCharges > settings.bombSettings.bombChargesReserved and
       API.CanCast(spells.WILDFIRE_BOMB) then
        
        -- Handle different bomb types if Wildfire Infusion is talented
        if talents.hasWildfireInfusion and settings.bombSettings.useInfusionSpecifically then
            -- Choose optimal bomb type based on situation and preferences
            local preferredBomb = settings.bombSettings.preferredBomb
            
            if preferredBomb == "Shrapnel" or 
               (preferredBomb == "Situational" and settings.dotSettings.useInternalBleeding) then
                if API.CanCast(spells.SHRAPNEL_BOMB) then
                    API.CastSpellAtTarget(spells.SHRAPNEL_BOMB)
                    return true
                end
            elseif preferredBomb == "Pheromone" or 
                   (preferredBomb == "Situational" and currentFocus < 50) then
                if API.CanCast(spells.PHEROMONE_BOMB) then
                    API.CastSpellAtTarget(spells.PHEROMONE_BOMB)
                    return true
                end
            elseif preferredBomb == "Volatile" then
                if API.CanCast(spells.VOLATILE_BOMB) then
                    API.CastSpellAtTarget(spells.VOLATILE_BOMB)
                    return true
                end
            end
        end
        
        -- Default to regular Wildfire Bomb
        API.CastSpellAtTarget(spells.WILDFIRE_BOMB)
        return true
    end
    
    -- Use Kill Command for focus generation and damage
    if killCommand and API.CanCast(spells.KILL_COMMAND) then
        API.CastSpell(spells.KILL_COMMAND)
        return true
    end
    
    -- Use Flanking Strike if talented and ready
    if flankingStrike and 
       settings.rotationSettings.useFlankingStrike and
       API.CanCast(spells.FLANKING_STRIKE) then
        
        -- Check if we want to save it for emergencies
        if settings.abilityControls.flankingStrike.saveForFocus and 
           currentFocus < settings.abilityControls.flankingStrike.minFocus then
            -- Focus is too low, use it now
            API.CastSpell(spells.FLANKING_STRIKE)
            return true
        elseif not settings.abilityControls.flankingStrike.saveForFocus or flankingStrikeReady then
            -- Use it normally
            API.CastSpell(spells.FLANKING_STRIKE)
            return true
        end
    end
    
    -- Choose between Mongoose Bite and Raptor Strike
    if mongoose and 
       (settings.rotationSettings.useRaptorStrike == false or not talents.hasRaptorStrike) and
       API.CanCast(spells.MONGOOSE_BITE) then
        
        -- Prioritize Mongoose Bite
        API.CastSpell(spells.MONGOOSE_BITE)
        return true
    elseif rapiderFire and API.CanCast(spells.RAPTOR_STRIKE) then
        -- Use Raptor Strike
        API.CastSpell(spells.RAPTOR_STRIKE)
        return true
    end
    
    return false
end

-- Handle specialization change
function Survival:OnSpecializationChanged()
    -- Update talent information
    self:UpdateTalentInfo()
    
    -- Reset state variables
    nextCastOverride = nil
    burstModeActive = false
    currentAoETargets = 0
    currentFocus = 0
    maxFocus = 100
    coordinatedAssaultActive = false
    coordinatedAssaultEndTime = 0
    wildfireInfusionActive = false
    wildfireInfusionEndTime = 0
    mongooseFuryActive = false
    mongooseFuryStacks = 0
    mongooseFuryEndTime = 0
    termsOfEngagementActive = false
    termsOfEngagementEndTime = 0
    viperStingActive = false
    viperStingEndTime = 0
    serpentStingActive = {}
    serpentStingEndTime = {}
    internalBleedingActive = {}
    internalBleedingEndTime = {}
    lateralThoughtsActive = false
    lateralThoughtsStacks = 0
    lateralThoughtsEndTime = 0
    madBombardiersActive = false
    madBombardiersEndTime = 0
    naturesMendingActive = false
    naturesMendingEndTime = 0
    frenzyActive = false
    frenzyStacks = 0
    frenzyEndTime = 0
    bloodseekerActive = {}
    bloodseekerEndTime = {}
    flankingStrikeReady = false
    flankingStrikeReadyTime = 0
    wildfireBombCharges = 0
    wildfireBombMaxCharges = 0
    harpoonCharges = 0
    harpoonMaxCharges = 0
    carveCharges = 0
    carveMaxCharges = 0
    aspectOfEagleActive = false
    aspectOfEagleEndTime = 0
    petActive = false
    petFrenzyActive = false
    petFrenzyStacks = 0
    petFrenzyEndTime = 0
    petHealthPercent = 100
    shrapnelBombActive = false
    pheromoneBombActive = false
    volatileBombActive = false
    inMeleeRange = false
    killCommand = false
    rapiderFire = false
    serpentSting = false
    flankingStrike = false
    carve = false
    butchery = false
    mongoose = false
    chakrams = false
    wildfireBomb = false
    coordinatedAssault = false
    aspectOfEagle = false
    harpoon = false
    muzzle = false
    intimidation = false
    tranquilizing = false
    freezingTrap = false
    tarTrap = false
    steelTrap = false
    bindingShot = false
    disengage = false
    camouflage = false
    furyOfTheEagle = false
    sixBitePoison = false
    wildInstincts = false
    stingIntoTorpor = false
    bombardiersGuile = false
    alphaStrike = false
    spearhead = false
    enhancedWildfireOrTerms = false
    hydrasBite = false
    explosiveTrap = false
    guerrillaTactics = false
    tipOfTheSpear = false
    vipersVenom = false
    termsOfEngagement = false
    deathChakram = false
    stampede = false
    steelTrap = false
    flankingStrikeReset = false
    playerHealth = 100
    bloodseekerBleed = false
    meatHawk = false
    ruthlessMarauder = false
    deadlyDuo = false
    rangerSpear = false
    raptor = false
    bloodyFrenzy = false
    nesingwarysTrappingApparatus = false
    deadEye = false
    frenzyBand = false
    fuzzySabercat = false
    
    API.PrintDebug("Survival Hunter state reset on spec change")
    
    return true
end

-- Return the module for loading
return Survival