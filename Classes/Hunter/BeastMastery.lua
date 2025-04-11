------------------------------------------
-- WindrunnerRotations - Beast Mastery Hunter Module
-- Author: VortexQ8
-- The War Within Season 2
------------------------------------------

local BeastMastery = {}
-- This will be assigned to addon.Classes.Hunter.BeastMastery when loaded

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
local beastCleaveActive = false
local beastCleaveEndTime = 0
local frenzyActive = false
local frenzyStacks = 0
local frenzyEndTime = 0
local bestialWrathActive = false
local bestialWrathEndTime = 0
local aspectOfTheWildActive = false
local aspectOfTheWildEndTime = 0
local aspectOfTheEagleActive = false
local aspectOfTheEagleEndTime = 0
local coordinatedAssaultActive = false
local coordinatedAssaultEndTime = 0
local wildSpiritsActive = false
local wildSpiritsEndTime = 0
local resonatingArrowActive = false
local resonatingArrowEndTime = 0
local flayedShotActive = false
local flayerMarkStacks = 0
local barbedShotCharges = 0
local barbedShotMaxCharges = 0
local killCommandCharges = 0
local killCommandMaxCharges = 0
local killCommandCooldownRemaining = 0
local killShotAvailable = false
local petActive = false
local barbedShotRechargeTime = 0
local direBeastActive = false
local direBeastEndTime = 0
local oneWithThePackActive = false
local oneWithThePackEndTime = 0
local bloodshedActive = false
local bloodshedCooldown = 0
local callOfTheWildActive = false
local callOfTheWildEndTime = 0
local stampedeCooldown = 0
local wailingArrowCooldown = 0
local serpentStingActive = false
local serpentStingEndTime = 0
local inAspectOfTheCheetah = false
local inAspectOfTheTurtle = false
local petFrenzy = false
local petFrenzyStacks = 0
local petFrenzyEndTime = 0
local cobraShotFocusReduction = 0
local blazingConcentration = false
local blazingConcentrationStacks = 0
local packLeader = false
local packLeaderEndTime = 0
local killCleaveActive = false
local killCleaveEndTime = 0
local deadlyDuo = false
local scent4Blood = false
local savageMarauder = false
local packTactics = false
local wildInstinct = false
local rageOfTheSleeper = false
local killCommand2 = false
local empoweredRelease = false
local wildCall = false
local direBeast = false
local scentOfBlood = false
local alphaPredator = false
local inRange = false
local inMeleeRange = false
local beastCleaveReset = 0
local counterstrike = false
local counterstrikeCharges = 0
local huntersBond = false
local ichorInfusion = false
local improvedKillCommand = false
local spinningCrane = false

-- Constants
local BEAST_MASTERY_SPEC_ID = 253
local DEFAULT_AOE_THRESHOLD = 3
local BESTIAL_WRATH_DURATION = 15 -- seconds
local ASPECT_OF_THE_WILD_DURATION = 20 -- seconds
local ASPECT_OF_THE_EAGLE_DURATION = 15 -- seconds
local COORDINATED_ASSAULT_DURATION = 20 -- seconds
local WILD_SPIRITS_DURATION = 15 -- seconds
local RESONATING_ARROW_DURATION = 10 -- seconds
local FRENZY_DURATION = 8 -- seconds per stack
local BEAST_CLEAVE_DURATION = 4 -- seconds
local BARBED_SHOT_COOLDOWN = 12 -- seconds
local KILL_COMMAND_COOLDOWN = 7.5 -- seconds base cd
local DIRE_BEAST_DURATION = 8 -- seconds
local CALL_OF_THE_WILD_DURATION = 20 -- seconds
local HUNTING_RANGE = 40 -- yards
local MELEE_RANGE = 5 -- yards

-- Initialize the Beast Mastery module
function BeastMastery:Initialize()
    self:RegisterSpells()
    self:RegisterVariables()
    self:RegisterSettings()
    self:RegisterEvents()
    
    API.PrintDebug("Beast Mastery Hunter module initialized")
    
    return true
end

-- Register spell IDs
function BeastMastery:RegisterSpells()
    -- Core rotational abilities
    spells.KILL_COMMAND = 34026
    spells.BARBED_SHOT = 217200
    spells.COBRA_SHOT = 193455
    spells.BESTIAL_WRATH = 19574
    spells.MULTISHOT = 2643
    spells.ASPECT_OF_THE_WILD = 193530
    spells.KILL_SHOT = 53351
    spells.DIRE_BEAST = 120679
    spells.WAILING_ARROW = 392060
    
    -- Core utilities
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
    spells.HUNTERS_MARK = 257284
    spells.TRANQUILIZING_SHOT = 19801
    spells.COUNTER_SHOT = 147362
    spells.CONCUSSIVE_SHOT = 5116
    spells.SCARE_BEAST = 1513
    spells.FLARE = 1543
    spells.FREEZING_TRAP = 187650
    spells.TAR_TRAP = 187698
    spells.WING_CLIP = 195645
    
    -- Talents and passives
    spells.KILLER_INSTINCT = 273887
    spells.STAMPEDE = 201430
    spells.BLOODSHED = 321530
    spells.SPITTING_COBRA = 194407
    spells.SCENT_OF_BLOOD = 193532
    spells.ALPHA_PREDATOR = 269737
    spells.STOMP = 199530
    spells.BARRAGE = 120360
    spells.A_MURDER_OF_CROWS = 131894
    spells.THRILL_OF_THE_HUNT = 257944
    spells.VENOMOUS_BITE = 257891
    spells.PACK_TACTICS = 321014
    spells.DANCE_OF_DEATH = 274443
    spells.BEAST_CLEAVE = 115939
    spells.WILD_CALL = 185789
    spells.KILLER_COBRA = 199532
    spells.ASPECT_OF_THE_BEAST = 191384
    spells.ANIMAL_COMPANION = 267116
    spells.SPIRIT_BOND = 267116
    spells.POSTHASTE = 109215
    spells.MASTER_MARKSMAN = 260309
    spells.BINDING_SHOT = 109248
    spells.BORN_TO_BE_WILD = 266921
    spells.CAMOUFLAGE = 199483
    spells.IMPROVED_KILL_COMMAND = 378440
    spells.PIERCING_FANGS = 392296
    spells.KILL_CLEAVE = 378207
    spells.WILD_INSTINCTS = 378442
    spells.WILD_KINGDOM = 378894
    spells.CALL_OF_THE_WILD = 359844
    spells.WAILING_ARROW = 392060
    spells.KILLER_COMMAND = 378888
    spells.SPEARHEAD = 360966
    spells.SERRATED_SHOTS = 378765
    spells.SAVAGE_MARAUDER = 372901
    spells.ONE_WITH_THE_PACK = 378442
    spells.JAWS_OF_THUNDER = 378220
    spells.PACK_LEADER = 378968
    spells.DEADLY_DUO = 378962
    spells.FLAMEWAKERS = 392296
    spells.SALVO = 400456
    spells.KILL_COMMAND_2 = 378753
    spells.EMPOWERED_RELEASE = 378763
    spells.RAGE_OF_THE_SLEEPER = 404368
    spells.SPINNING_CRANE = 392988
    spells.HUNTERS_BOND = 392374
    spells.ICHOR_INFUSION = 392356
    
    -- War Within Season 2 specific
    spells.BARBED_WISDOM = 378441
    spells.BESTIAL_FURY = 378210
    spells.BIRDS_OF_PREY = 378904
    spells.BLAZING_CONCENTRATION = 378737
    spells.COBRA_SENSES = 378196
    spells.COORDINATED_KILL = 378262
    spells.DARTING_HATCHLING = 378215
    spells.FAST_TRACK = 378744
    spells.KILL_COMMAND_ENHANCEMENT = 378224
    spells.DUAL_WIELD_TRAINING = 400640
    spells.SCENT_4_BLOOD = 378218
    spells.SLASH_AND_BURN = 378989
    spells.COUNTERSTRIKE = 400341
    
    -- Covenant abilities (for reference, converted in WoW 10.0)
    spells.WILD_SPIRITS = 328231
    spells.RESONATING_ARROW = 308491
    spells.FLAYED_SHOT = 324149
    
    -- Buff IDs
    spells.BEAST_CLEAVE_BUFF = 268877
    spells.BESTIAL_WRATH_BUFF = 19574
    spells.ASPECT_OF_THE_WILD_BUFF = 193530
    spells.ASPECT_OF_THE_CHEETAH_BUFF = 186257
    spells.ASPECT_OF_THE_TURTLE_BUFF = 186265
    spells.ASPECT_OF_THE_EAGLE_BUFF = 186289
    spells.COORDINATED_ASSAULT_BUFF = 360952
    spells.WILD_SPIRITS_BUFF = 328231
    spells.RESONATING_ARROW_BUFF = 308491
    spells.FLAYED_SHOT_BUFF = 324149
    spells.FRENZY_BUFF = 272790
    spells.DIRE_BEAST_BUFF = 120679
    spells.ONE_WITH_THE_PACK_BUFF = 378442
    spells.BLOODSHED_BUFF = 321530
    spells.CALL_OF_THE_WILD_BUFF = 359844
    spells.SPEARHEAD_BUFF = 360966
    spells.PIERCING_FANGS_BUFF = 378004
    spells.DEADLY_DUO_BUFF = 378961
    spells.KILL_CLEAVE_BUFF = 378207
    spells.PACK_LEADER_BUFF = 378968
    spells.BLAZING_CONCENTRATION_BUFF = 378741
    spells.COUNTERSTRIKE_BUFF = 400342
    
    -- Debuff IDs
    spells.HUNTERS_MARK_DEBUFF = 257284
    spells.SERPENT_STING_DEBUFF = 271788
    spells.FLAYER_MARK_DEBUFF = 324149
    
    -- Register all spells with the API tracking system
    for spellName, spellID in pairs(spells) do
        API.RegisterSpell(spellID)
    end
    
    -- Define aura tracking
    buffs.BEAST_CLEAVE = spells.BEAST_CLEAVE_BUFF
    buffs.BESTIAL_WRATH = spells.BESTIAL_WRATH_BUFF
    buffs.ASPECT_OF_THE_WILD = spells.ASPECT_OF_THE_WILD_BUFF
    buffs.ASPECT_OF_THE_CHEETAH = spells.ASPECT_OF_THE_CHEETAH_BUFF
    buffs.ASPECT_OF_THE_TURTLE = spells.ASPECT_OF_THE_TURTLE_BUFF
    buffs.ASPECT_OF_THE_EAGLE = spells.ASPECT_OF_THE_EAGLE_BUFF
    buffs.COORDINATED_ASSAULT = spells.COORDINATED_ASSAULT_BUFF
    buffs.WILD_SPIRITS = spells.WILD_SPIRITS_BUFF
    buffs.RESONATING_ARROW = spells.RESONATING_ARROW_BUFF
    buffs.FLAYED_SHOT = spells.FLAYED_SHOT_BUFF
    buffs.FRENZY = spells.FRENZY_BUFF
    buffs.DIRE_BEAST = spells.DIRE_BEAST_BUFF
    buffs.ONE_WITH_THE_PACK = spells.ONE_WITH_THE_PACK_BUFF
    buffs.BLOODSHED = spells.BLOODSHED_BUFF
    buffs.CALL_OF_THE_WILD = spells.CALL_OF_THE_WILD_BUFF
    buffs.SPEARHEAD = spells.SPEARHEAD_BUFF
    buffs.PIERCING_FANGS = spells.PIERCING_FANGS_BUFF
    buffs.DEADLY_DUO = spells.DEADLY_DUO_BUFF
    buffs.KILL_CLEAVE = spells.KILL_CLEAVE_BUFF
    buffs.PACK_LEADER = spells.PACK_LEADER_BUFF
    buffs.BLAZING_CONCENTRATION = spells.BLAZING_CONCENTRATION_BUFF
    buffs.COUNTERSTRIKE = spells.COUNTERSTRIKE_BUFF
    
    debuffs.HUNTERS_MARK = spells.HUNTERS_MARK_DEBUFF
    debuffs.SERPENT_STING = spells.SERPENT_STING_DEBUFF
    debuffs.FLAYER_MARK = spells.FLAYER_MARK_DEBUFF
    
    return true
end

-- Register variables to track
function BeastMastery:RegisterVariables()
    -- Talent tracking
    talents.hasKillerInstinct = false
    talents.hasStampede = false
    talents.hasBloodshed = false
    talents.hasSpittingCobra = false
    talents.hasScentOfBlood = false
    talents.hasAlphaPredator = false
    talents.hasStomp = false
    talents.hasBarrage = false
    talents.hasAMurderOfCrows = false
    talents.hasThrillOfTheHunt = false
    talents.hasVenomousBite = false
    talents.hasPackTactics = false
    talents.hasDanceOfDeath = false
    talents.hasBeastCleave = false
    talents.hasWildCall = false
    talents.hasKillerCobra = false
    talents.hasAspectOfTheBeast = false
    talents.hasAnimalCompanion = false
    talents.hasSpiritBond = false
    talents.hasPosthaste = false
    talents.hasMasterMarksman = false
    talents.hasBindingShot = false
    talents.hasBornToBeWild = false
    talents.hasCamouflage = false
    talents.hasImprovedKillCommand = false
    talents.hasPiercingFangs = false
    talents.hasKillCleave = false
    talents.hasWildInstincts = false
    talents.hasWildKingdom = false
    talents.hasCallOfTheWild = false
    talents.hasWailingArrow = false
    talents.hasKillerCommand = false
    talents.hasSpearhead = false
    talents.hasSerratedShots = false
    talents.hasSavageMarauder = false
    talents.hasOneWithThePack = false
    talents.hasJawsOfThunder = false
    talents.hasPackLeader = false
    talents.hasDeadlyDuo = false
    talents.hasFlamewakers = false
    talents.hasSalvo = false
    talents.hasKillCommand2 = false
    talents.hasEmpoweredRelease = false
    talents.hasRageOfTheSleeper = false
    talents.hasSpinningCrane = false
    talents.hasHuntersBond = false
    talents.hasIchorInfusion = false
    
    -- War Within Season 2 talents
    talents.hasBarbedWisdom = false
    talents.hasBestialFury = false
    talents.hasBirdsOfPrey = false
    talents.hasBlazingConcentration = false
    talents.hasCobraSenses = false
    talents.hasCoordinatedKill = false
    talents.hasDartingHatchling = false
    talents.hasFastTrack = false
    talents.hasKillCommandEnhancement = false
    talents.hasDualWieldTraining = false
    talents.hasScent4Blood = false
    talents.hasSlashAndBurn = false
    talents.hasCounterstrike = false
    
    -- Initialize resources
    currentFocus = API.GetPlayerPower()
    
    -- Check if pet exists
    petActive = API.HasActivePet()
    
    -- Initialize cooldown charges
    barbedShotCharges = API.GetSpellCharges(spells.BARBED_SHOT) or 0
    barbedShotMaxCharges = API.GetSpellMaxCharges(spells.BARBED_SHOT) or 2
    
    killCommandCharges = API.GetSpellCharges(spells.KILL_COMMAND) or 0
    killCommandMaxCharges = API.GetSpellMaxCharges(spells.KILL_COMMAND) or 1
    
    return true
end

-- Register spec-specific settings
function BeastMastery:RegisterSettings()
    ConfigRegistry:RegisterSettings("BeastMasteryHunter", {
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
            petManagement = {
                displayName = "Pet Management",
                description = "Automatically handle pet-related abilities",
                type = "toggle",
                default = true
            },
            barbedShotStrategy = {
                displayName = "Barbed Shot Strategy",
                description = "How to prioritize Barbed Shot usage",
                type = "dropdown",
                options = {"Maintain Frenzy", "Focus Generation", "Charge Management"},
                default = "Maintain Frenzy"
            },
            killShotUsage = {
                displayName = "Kill Shot Usage",
                description = "When to use Kill Shot",
                type = "dropdown",
                options = {"On Execute", "On Cooldown", "Never"},
                default = "On Execute"
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
        
        offensiveSettings = {
            useBestialWrath = {
                displayName = "Use Bestial Wrath",
                description = "Automatically use Bestial Wrath",
                type = "toggle",
                default = true
            },
            useAspectOfTheWild = {
                displayName = "Use Aspect of the Wild",
                description = "Automatically use Aspect of the Wild",
                type = "toggle",
                default = true
            },
            syncCooldowns = {
                displayName = "Sync Cooldowns",
                description = "Synchronize Bestial Wrath and Aspect of the Wild",
                type = "toggle",
                default = true
            },
            useStampede = {
                displayName = "Use Stampede",
                description = "Automatically use Stampede when talented",
                type = "toggle",
                default = true
            },
            useBloodshed = {
                displayName = "Use Bloodshed",
                description = "Automatically use Bloodshed when talented",
                type = "toggle",
                default = true
            },
            useAMurderOfCrows = {
                displayName = "Use A Murder of Crows",
                description = "Automatically use A Murder of Crows when talented",
                type = "toggle",
                default = true
            },
            useDireBeast = {
                displayName = "Use Dire Beast",
                description = "Automatically use Dire Beast when talented",
                type = "toggle",
                default = true
            },
            useWailingArrow = {
                displayName = "Use Wailing Arrow",
                description = "Automatically use Wailing Arrow when talented",
                type = "toggle",
                default = true
            },
            useBarrage = {
                displayName = "Use Barrage",
                description = "Automatically use Barrage when talented",
                type = "toggle",
                default = true
            },
            barrageMinTargets = {
                displayName = "Barrage Min Targets",
                description = "Minimum targets to use Barrage",
                type = "slider",
                min = 1,
                max = 8,
                default = 3
            }
        },
        
        utilitySettings = {
            useHuntersMark = {
                displayName = "Use Hunter's Mark",
                description = "Automatically apply Hunter's Mark",
                type = "toggle",
                default = true
            },
            useConcussiveShot = {
                displayName = "Use Concussive Shot",
                description = "Automatically use Concussive Shot to slow targets",
                type = "toggle",
                default = true
            },
            useTranquilizingShot = {
                displayName = "Use Tranquilizing Shot",
                description = "Automatically use Tranquilizing Shot to remove buffs",
                type = "toggle",
                default = true
            },
            useFreezingTrap = {
                displayName = "Use Freezing Trap",
                description = "Automatically use Freezing Trap when in danger",
                type = "toggle",
                default = true
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
            }
        },
        
        advancedSettings = {
            focusPooling = {
                displayName = "Focus Pooling",
                description = "Pool focus for priority abilities",
                type = "toggle",
                default = true
            },
            minFocusPool = {
                displayName = "Minimum Focus Pool",
                description = "Minimum focus to maintain",
                type = "slider",
                min = 0,
                max = 80,
                default = 30
            },
            barbedShotMinFrenzyTime = {
                displayName = "Barbed Shot Min Frenzy Time",
                description = "Minimum Frenzy duration to maintain (seconds)",
                type = "slider",
                min = 1,
                max = 6,
                default = 2
            },
            maxBarbedShotCharges = {
                displayName = "Max Barbed Shot Charges",
                description = "Maximum Barbed Shot charges to hold",
                type = "slider",
                min = 0,
                max = 2,
                default = 1
            },
            maintainBeastCleave = {
                displayName = "Maintain Beast Cleave",
                description = "Always maintain Beast Cleave in AoE",
                type = "toggle",
                default = true
            }
        },
        
        -- Advanced ability control settings
        abilityControls = {
            -- Bestial Wrath controls
            bestialWrath = AAC.RegisterAbility(spells.BESTIAL_WRATH, {
                enabled = true,
                useDuringBurstOnly = false,
                minFocusToUse = 70
            }),
            
            -- Aspect of the Wild controls
            aspectOfTheWild = AAC.RegisterAbility(spells.ASPECT_OF_THE_WILD, {
                enabled = true,
                useDuringBurstOnly = true,
                syncWithBestialWrath = true
            }),
            
            -- Kill Command controls
            killCommand = AAC.RegisterAbility(spells.KILL_COMMAND, {
                enabled = true,
                alwaysMaxPriority = true,
                minFocusToKeep = 30
            })
        }
    })
    
    return true
end

-- Register for events 
function BeastMastery:RegisterEvents()
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
function BeastMastery:UpdateTalentInfo()
    -- Check for important talents
    talents.hasKillerInstinct = API.HasTalent(spells.KILLER_INSTINCT)
    talents.hasStampede = API.HasTalent(spells.STAMPEDE)
    talents.hasBloodshed = API.HasTalent(spells.BLOODSHED)
    talents.hasSpittingCobra = API.HasTalent(spells.SPITTING_COBRA)
    talents.hasScentOfBlood = API.HasTalent(spells.SCENT_OF_BLOOD)
    talents.hasAlphaPredator = API.HasTalent(spells.ALPHA_PREDATOR)
    talents.hasStomp = API.HasTalent(spells.STOMP)
    talents.hasBarrage = API.HasTalent(spells.BARRAGE)
    talents.hasAMurderOfCrows = API.HasTalent(spells.A_MURDER_OF_CROWS)
    talents.hasThrillOfTheHunt = API.HasTalent(spells.THRILL_OF_THE_HUNT)
    talents.hasVenomousBite = API.HasTalent(spells.VENOMOUS_BITE)
    talents.hasPackTactics = API.HasTalent(spells.PACK_TACTICS)
    talents.hasDanceOfDeath = API.HasTalent(spells.DANCE_OF_DEATH)
    talents.hasBeastCleave = API.HasTalent(spells.BEAST_CLEAVE)
    talents.hasWildCall = API.HasTalent(spells.WILD_CALL)
    talents.hasKillerCobra = API.HasTalent(spells.KILLER_COBRA)
    talents.hasAspectOfTheBeast = API.HasTalent(spells.ASPECT_OF_THE_BEAST)
    talents.hasAnimalCompanion = API.HasTalent(spells.ANIMAL_COMPANION)
    talents.hasSpiritBond = API.HasTalent(spells.SPIRIT_BOND)
    talents.hasPosthaste = API.HasTalent(spells.POSTHASTE)
    talents.hasMasterMarksman = API.HasTalent(spells.MASTER_MARKSMAN)
    talents.hasBindingShot = API.HasTalent(spells.BINDING_SHOT)
    talents.hasBornToBeWild = API.HasTalent(spells.BORN_TO_BE_WILD)
    talents.hasCamouflage = API.HasTalent(spells.CAMOUFLAGE)
    talents.hasImprovedKillCommand = API.HasTalent(spells.IMPROVED_KILL_COMMAND)
    talents.hasPiercingFangs = API.HasTalent(spells.PIERCING_FANGS)
    talents.hasKillCleave = API.HasTalent(spells.KILL_CLEAVE)
    talents.hasWildInstincts = API.HasTalent(spells.WILD_INSTINCTS)
    talents.hasWildKingdom = API.HasTalent(spells.WILD_KINGDOM)
    talents.hasCallOfTheWild = API.HasTalent(spells.CALL_OF_THE_WILD)
    talents.hasWailingArrow = API.HasTalent(spells.WAILING_ARROW)
    talents.hasKillerCommand = API.HasTalent(spells.KILLER_COMMAND)
    talents.hasSpearhead = API.HasTalent(spells.SPEARHEAD)
    talents.hasSerratedShots = API.HasTalent(spells.SERRATED_SHOTS)
    talents.hasSavageMarauder = API.HasTalent(spells.SAVAGE_MARAUDER)
    talents.hasOneWithThePack = API.HasTalent(spells.ONE_WITH_THE_PACK)
    talents.hasJawsOfThunder = API.HasTalent(spells.JAWS_OF_THUNDER)
    talents.hasPackLeader = API.HasTalent(spells.PACK_LEADER)
    talents.hasDeadlyDuo = API.HasTalent(spells.DEADLY_DUO)
    talents.hasFlamewakers = API.HasTalent(spells.FLAMEWAKERS)
    talents.hasSalvo = API.HasTalent(spells.SALVO)
    talents.hasKillCommand2 = API.HasTalent(spells.KILL_COMMAND_2)
    talents.hasEmpoweredRelease = API.HasTalent(spells.EMPOWERED_RELEASE)
    talents.hasRageOfTheSleeper = API.HasTalent(spells.RAGE_OF_THE_SLEEPER)
    talents.hasSpinningCrane = API.HasTalent(spells.SPINNING_CRANE)
    talents.hasHuntersBond = API.HasTalent(spells.HUNTERS_BOND)
    talents.hasIchorInfusion = API.HasTalent(spells.ICHOR_INFUSION)
    
    -- War Within Season 2 talents
    talents.hasBarbedWisdom = API.HasTalent(spells.BARBED_WISDOM)
    talents.hasBestialFury = API.HasTalent(spells.BESTIAL_FURY)
    talents.hasBirdsOfPrey = API.HasTalent(spells.BIRDS_OF_PREY)
    talents.hasBlazingConcentration = API.HasTalent(spells.BLAZING_CONCENTRATION)
    talents.hasCobraSenses = API.HasTalent(spells.COBRA_SENSES)
    talents.hasCoordinatedKill = API.HasTalent(spells.COORDINATED_KILL)
    talents.hasDartingHatchling = API.HasTalent(spells.DARTING_HATCHLING)
    talents.hasFastTrack = API.HasTalent(spells.FAST_TRACK)
    talents.hasKillCommandEnhancement = API.HasTalent(spells.KILL_COMMAND_ENHANCEMENT)
    talents.hasDualWieldTraining = API.HasTalent(spells.DUAL_WIELD_TRAINING)
    talents.hasScent4Blood = API.HasTalent(spells.SCENT_4_BLOOD)
    talents.hasSlashAndBurn = API.HasTalent(spells.SLASH_AND_BURN)
    talents.hasCounterstrike = API.HasTalent(spells.COUNTERSTRIKE)
    
    -- Set specialized variables based on talents
    if talents.hasPackTactics then
        packTactics = true
    end
    
    if talents.hasWildInstincts then
        wildInstinct = true
    end
    
    if talents.hasRageOfTheSleeper then
        rageOfTheSleeper = true
    }
    
    if talents.hasKillCommand2 then
        killCommand2 = true
    }
    
    if talents.hasEmpoweredRelease then
        empoweredRelease = true
    }
    
    if talents.hasWildCall then
        wildCall = true
    }
    
    if talents.hasDireBeast then
        direBeast = true
    }
    
    if talents.hasScentOfBlood then
        scentOfBlood = true
    }
    
    if talents.hasAlphaPredator then
        alphaPredator = true
    }
    
    if talents.hasDeadlyDuo then
        deadlyDuo = true
    }
    
    if talents.hasScent4Blood then
        scent4Blood = true
    }
    
    if talents.hasSavageMarauder then
        savageMarauder = true
    }
    
    if talents.hasImprovedKillCommand then
        improvedKillCommand = true
    }
    
    if talents.hasSpinningCrane then
        spinningCrane = true
    }
    
    if talents.hasHuntersBond then
        huntersBond = true
    }
    
    if talents.hasIchorInfusion then
        ichorInfusion = true
    }
    
    -- If Barbed Shot has two charges by default
    if talents.hasAlphaPredator then
        barbedShotMaxCharges = 2
    end
    
    -- If Kill Command has two charges
    if talents.hasKillCommand2 then
        killCommandMaxCharges = 2
    end
    
    -- Update ability charges
    barbedShotCharges = API.GetSpellCharges(spells.BARBED_SHOT) or 0
    killCommandCharges = API.GetSpellCharges(spells.KILL_COMMAND) or 0
    
    -- Reduce Cobra Shot focus cost for certain talents
    if talents.hasKillerCobra then
        cobraShotFocusReduction = 10 -- Reduced by 10 focus
    end
    
    -- Check if Counterstrike talent is active
    if talents.hasCounterstrike then
        counterstrikeCharges = API.GetBuffStacks("player", buffs.COUNTERSTRIKE) or 0
        counterstrike = counterstrikeCharges > 0
    end
    
    API.PrintDebug("Beast Mastery Hunter talents updated")
    
    return true
end

-- Update focus tracking
function BeastMastery:UpdateFocus()
    currentFocus = API.GetPlayerPower()
    return true
end

-- Update pet status
function BeastMastery:UpdatePetStatus()
    petActive = API.HasActivePet()
    
    if petActive then
        -- Check for pet Frenzy buff
        local frenzyInfo = API.GetBuffInfo("pet", buffs.FRENZY)
        if frenzyInfo then
            frenzyActive = true
            frenzyStacks = select(4, frenzyInfo) or 0
            frenzyEndTime = select(6, frenzyInfo)
            petFrenzy = true
            petFrenzyStacks = frenzyStacks
            petFrenzyEndTime = frenzyEndTime
        else
            frenzyActive = false
            frenzyStacks = 0
            frenzyEndTime = 0
            petFrenzy = false
            petFrenzyStacks = 0
            petFrenzyEndTime = 0
        end
    end
    
    return true
end

-- Update target data
function BeastMastery:UpdateTargetData()
    -- Check if in range
    inRange = API.IsUnitInRange("target", HUNTING_RANGE)
    inMeleeRange = API.IsUnitInRange("target", MELEE_RANGE)
    
    -- Get target GUID
    local targetGUID = API.GetTargetGUID()
    
    if targetGUID and targetGUID ~= "" then
        -- Check if target is in execute range for Kill Shot
        killShotAvailable = API.GetTargetHealthPercent() <= 20
    else
        killShotAvailable = false
    end
    
    -- Update AoE targets count
    currentAoETargets = API.GetNearbyEnemiesCount(8) -- AoE radius
    
    return true
end

-- Handle combat log events
function BeastMastery:HandleCombatLogEvent(...)
    local timestamp, eventType, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, spellID, spellName = CombatLogGetCurrentEventInfo()
    
    -- Only process events relevant to the player or their pet
    if sourceGUID ~= API.GetPlayerGUID() and sourceGUID ~= API.GetPetGUID() then
        return false
    end
    
    -- Track buff applications
    if eventType == "SPELL_AURA_APPLIED" or eventType == "SPELL_AURA_REFRESH" then
        -- Player buffs
        if destGUID == API.GetPlayerGUID() then
            -- Track Beast Cleave
            if spellID == buffs.BEAST_CLEAVE then
                beastCleaveActive = true
                beastCleaveEndTime = GetTime() + BEAST_CLEAVE_DURATION
                beastCleaveReset = GetTime()
                API.PrintDebug("Beast Cleave activated")
            end
            
            -- Track Bestial Wrath
            if spellID == buffs.BESTIAL_WRATH then
                bestialWrathActive = true
                bestialWrathEndTime = GetTime() + BESTIAL_WRATH_DURATION
                API.PrintDebug("Bestial Wrath activated")
            end
            
            -- Track Aspect of the Wild
            if spellID == buffs.ASPECT_OF_THE_WILD then
                aspectOfTheWildActive = true
                aspectOfTheWildEndTime = GetTime() + ASPECT_OF_THE_WILD_DURATION
                API.PrintDebug("Aspect of the Wild activated")
            end
            
            -- Track Aspect of the Eagle
            if spellID == buffs.ASPECT_OF_THE_EAGLE then
                aspectOfTheEagleActive = true
                aspectOfTheEagleEndTime = GetTime() + ASPECT_OF_THE_EAGLE_DURATION
                API.PrintDebug("Aspect of the Eagle activated")
            end
            
            -- Track Coordinated Assault
            if spellID == buffs.COORDINATED_ASSAULT then
                coordinatedAssaultActive = true
                coordinatedAssaultEndTime = GetTime() + COORDINATED_ASSAULT_DURATION
                API.PrintDebug("Coordinated Assault activated")
            end
            
            -- Track Wild Spirits
            if spellID == buffs.WILD_SPIRITS then
                wildSpiritsActive = true
                wildSpiritsEndTime = GetTime() + WILD_SPIRITS_DURATION
                API.PrintDebug("Wild Spirits activated")
            end
            
            -- Track Resonating Arrow
            if spellID == buffs.RESONATING_ARROW then
                resonatingArrowActive = true
                resonatingArrowEndTime = GetTime() + RESONATING_ARROW_DURATION
                API.PrintDebug("Resonating Arrow activated")
            end
            
            -- Track aspects (defensive/utility)
            if spellID == buffs.ASPECT_OF_THE_CHEETAH then
                inAspectOfTheCheetah = true
                API.PrintDebug("Aspect of the Cheetah activated")
            elseif spellID == buffs.ASPECT_OF_THE_TURTLE then
                inAspectOfTheTurtle = true
                API.PrintDebug("Aspect of the Turtle activated")
            end
            
            -- Track Dire Beast
            if spellID == buffs.DIRE_BEAST then
                direBeastActive = true
                direBeastEndTime = GetTime() + DIRE_BEAST_DURATION
                API.PrintDebug("Dire Beast activated")
            end
            
            -- Track One with the Pack
            if spellID == buffs.ONE_WITH_THE_PACK then
                oneWithThePackActive = true
                oneWithThePackEndTime = GetTime() + 10 -- approximate duration
                API.PrintDebug("One with the Pack activated")
            end
            
            -- Track Call of the Wild
            if spellID == buffs.CALL_OF_THE_WILD then
                callOfTheWildActive = true
                callOfTheWildEndTime = GetTime() + CALL_OF_THE_WILD_DURATION
                API.PrintDebug("Call of the Wild activated")
            end
            
            -- Track Deadly Duo
            if spellID == buffs.DEADLY_DUO then
                deadlyDuo = true
                API.PrintDebug("Deadly Duo activated")
            end
            
            -- Track Kill Cleave
            if spellID == buffs.KILL_CLEAVE then
                killCleaveActive = true
                killCleaveEndTime = GetTime() + 8 -- approximate duration
                API.PrintDebug("Kill Cleave activated")
            end
            
            -- Track Pack Leader
            if spellID == buffs.PACK_LEADER then
                packLeader = true
                packLeaderEndTime = GetTime() + 8 -- approximate duration
                API.PrintDebug("Pack Leader activated")
            end
            
            -- Track Blazing Concentration
            if spellID == buffs.BLAZING_CONCENTRATION then
                blazingConcentration = true
                blazingConcentrationStacks = select(4, API.GetBuffInfo("player", buffs.BLAZING_CONCENTRATION)) or 1
                API.PrintDebug("Blazing Concentration activated: " .. tostring(blazingConcentrationStacks) .. " stacks")
            end
            
            -- Track Counterstrike
            if spellID == buffs.COUNTERSTRIKE then
                counterstrike = true
                counterstrikeCharges = select(4, API.GetBuffInfo("player", buffs.COUNTERSTRIKE)) or 1
                API.PrintDebug("Counterstrike activated: " .. tostring(counterstrikeCharges) .. " charges")
            end
        end
        
        -- Pet buffs
        if destGUID == API.GetPetGUID() then
            -- Track pet Frenzy
            if spellID == buffs.FRENZY then
                frenzyActive = true
                frenzyStacks = select(4, API.GetBuffInfo("pet", buffs.FRENZY)) or 1
                frenzyEndTime = select(6, API.GetBuffInfo("pet", buffs.FRENZY))
                petFrenzy = true
                petFrenzyStacks = frenzyStacks
                petFrenzyEndTime = frenzyEndTime
                API.PrintDebug("Pet Frenzy stacks: " .. tostring(frenzyStacks))
            end
        end
        
        -- Target debuffs
        if API.GetTargetGUID() == destGUID then
            if spellID == debuffs.HUNTERS_MARK then
                API.PrintDebug("Hunter's Mark applied to target")
            elseif spellID == debuffs.SERPENT_STING then
                serpentStingActive = true
                serpentStingEndTime = select(6, API.GetDebuffInfo("target", debuffs.SERPENT_STING))
                API.PrintDebug("Serpent Sting applied to target")
            elseif spellID == debuffs.FLAYER_MARK then
                flayedShotActive = true
                flayerMarkStacks = select(4, API.GetDebuffInfo("target", debuffs.FLAYER_MARK)) or 1
                API.PrintDebug("Flayer Mark applied to target: " .. tostring(flayerMarkStacks) .. " stacks")
            elseif spellID == buffs.BLOODSHED then
                bloodshedActive = true
                API.PrintDebug("Bloodshed applied to target")
            end
        end
    end
    
    -- Track buff removals
    if eventType == "SPELL_AURA_REMOVED" then
        -- Player buff removals
        if destGUID == API.GetPlayerGUID() then
            -- Track Beast Cleave
            if spellID == buffs.BEAST_CLEAVE then
                beastCleaveActive = false
                API.PrintDebug("Beast Cleave faded")
            end
            
            -- Track Bestial Wrath
            if spellID == buffs.BESTIAL_WRATH then
                bestialWrathActive = false
                API.PrintDebug("Bestial Wrath faded")
            end
            
            -- Track Aspect of the Wild
            if spellID == buffs.ASPECT_OF_THE_WILD then
                aspectOfTheWildActive = false
                API.PrintDebug("Aspect of the Wild faded")
            end
            
            -- Track Aspect of the Eagle
            if spellID == buffs.ASPECT_OF_THE_EAGLE then
                aspectOfTheEagleActive = false
                API.PrintDebug("Aspect of the Eagle faded")
            end
            
            -- Track Coordinated Assault
            if spellID == buffs.COORDINATED_ASSAULT then
                coordinatedAssaultActive = false
                API.PrintDebug("Coordinated Assault faded")
            end
            
            -- Track Wild Spirits
            if spellID == buffs.WILD_SPIRITS then
                wildSpiritsActive = false
                API.PrintDebug("Wild Spirits faded")
            end
            
            -- Track Resonating Arrow
            if spellID == buffs.RESONATING_ARROW then
                resonatingArrowActive = false
                API.PrintDebug("Resonating Arrow faded")
            end
            
            -- Track aspects (defensive/utility)
            if spellID == buffs.ASPECT_OF_THE_CHEETAH then
                inAspectOfTheCheetah = false
                API.PrintDebug("Aspect of the Cheetah faded")
            elseif spellID == buffs.ASPECT_OF_THE_TURTLE then
                inAspectOfTheTurtle = false
                API.PrintDebug("Aspect of the Turtle faded")
            end
            
            -- Track Dire Beast
            if spellID == buffs.DIRE_BEAST then
                direBeastActive = false
                API.PrintDebug("Dire Beast faded")
            end
            
            -- Track One with the Pack
            if spellID == buffs.ONE_WITH_THE_PACK then
                oneWithThePackActive = false
                API.PrintDebug("One with the Pack faded")
            end
            
            -- Track Call of the Wild
            if spellID == buffs.CALL_OF_THE_WILD then
                callOfTheWildActive = false
                API.PrintDebug("Call of the Wild faded")
            end
            
            -- Track Deadly Duo
            if spellID == buffs.DEADLY_DUO then
                deadlyDuo = false
                API.PrintDebug("Deadly Duo faded")
            end
            
            -- Track Kill Cleave
            if spellID == buffs.KILL_CLEAVE then
                killCleaveActive = false
                API.PrintDebug("Kill Cleave faded")
            end
            
            -- Track Pack Leader
            if spellID == buffs.PACK_LEADER then
                packLeader = false
                API.PrintDebug("Pack Leader faded")
            end
            
            -- Track Blazing Concentration
            if spellID == buffs.BLAZING_CONCENTRATION then
                blazingConcentration = false
                blazingConcentrationStacks = 0
                API.PrintDebug("Blazing Concentration faded")
            end
            
            -- Track Counterstrike
            if spellID == buffs.COUNTERSTRIKE then
                counterstrike = false
                counterstrikeCharges = 0
                API.PrintDebug("Counterstrike faded")
            end
        end
        
        -- Pet buff removals
        if destGUID == API.GetPetGUID() then
            -- Track pet Frenzy
            if spellID == buffs.FRENZY then
                frenzyActive = false
                frenzyStacks = 0
                petFrenzy = false
                petFrenzyStacks = 0
                API.PrintDebug("Pet Frenzy faded")
            end
        end
        
        -- Target debuff removals
        if API.GetTargetGUID() == destGUID then
            if spellID == debuffs.HUNTERS_MARK then
                API.PrintDebug("Hunter's Mark removed from target")
            elseif spellID == debuffs.SERPENT_STING then
                serpentStingActive = false
                API.PrintDebug("Serpent Sting removed from target")
            elseif spellID == debuffs.FLAYER_MARK then
                flayedShotActive = false
                flayerMarkStacks = 0
                API.PrintDebug("Flayer Mark removed from target")
            elseif spellID == buffs.BLOODSHED then
                bloodshedActive = false
                API.PrintDebug("Bloodshed removed from target")
            end
        end
    end
    
    -- Track Frenzy stacks
    if eventType == "SPELL_AURA_APPLIED_DOSE" and spellID == buffs.FRENZY and destGUID == API.GetPetGUID() then
        frenzyStacks = select(4, API.GetBuffInfo("pet", buffs.FRENZY)) or 0
        petFrenzyStacks = frenzyStacks
        API.PrintDebug("Pet Frenzy stacks: " .. tostring(frenzyStacks))
    end
    
    -- Track Blazing Concentration stacks
    if eventType == "SPELL_AURA_APPLIED_DOSE" and spellID == buffs.BLAZING_CONCENTRATION and destGUID == API.GetPlayerGUID() then
        blazingConcentrationStacks = select(4, API.GetBuffInfo("player", buffs.BLAZING_CONCENTRATION)) or 0
        API.PrintDebug("Blazing Concentration stacks: " .. tostring(blazingConcentrationStacks))
    end
    
    -- Track Counterstrike charges
    if eventType == "SPELL_AURA_APPLIED_DOSE" and spellID == buffs.COUNTERSTRIKE and destGUID == API.GetPlayerGUID() then
        counterstrikeCharges = select(4, API.GetBuffInfo("player", buffs.COUNTERSTRIKE)) or 0
        API.PrintDebug("Counterstrike charges: " .. tostring(counterstrikeCharges))
    end
    
    -- Track spell casts
    if eventType == "SPELL_CAST_SUCCESS" and sourceGUID == API.GetPlayerGUID() then
        if spellID == spells.BARBED_SHOT then
            barbedShotCharges = API.GetSpellCharges(spells.BARBED_SHOT) or 0
            barbedShotRechargeTime = select(2, API.GetSpellChargeInfo(spells.BARBED_SHOT)) or 0
            API.PrintDebug("Barbed Shot cast, " .. tostring(barbedShotCharges) .. " charges remaining")
        elseif spellID == spells.KILL_COMMAND then
            killCommandCharges = API.GetSpellCharges(spells.KILL_COMMAND) or 0
            killCommandCooldownRemaining = select(2, API.GetSpellCooldownInfo(spells.KILL_COMMAND)) or 0
            API.PrintDebug("Kill Command cast, " .. tostring(killCommandCharges) .. " charges remaining")
        elseif spellID == spells.BESTIAL_WRATH then
            bestialWrathActive = true
            bestialWrathEndTime = GetTime() + BESTIAL_WRATH_DURATION
            API.PrintDebug("Bestial Wrath cast")
        elseif spellID == spells.ASPECT_OF_THE_WILD then
            aspectOfTheWildActive = true
            aspectOfTheWildEndTime = GetTime() + ASPECT_OF_THE_WILD_DURATION
            API.PrintDebug("Aspect of the Wild cast")
        elseif spellID == spells.MULTISHOT then
            -- Beast Cleave is triggered by Multishot
            beastCleaveActive = true
            beastCleaveEndTime = GetTime() + BEAST_CLEAVE_DURATION
            beastCleaveReset = GetTime()
            API.PrintDebug("Multishot cast, Beast Cleave activated")
        elseif spellID == spells.COBRA_SHOT then
            API.PrintDebug("Cobra Shot cast")
        elseif spellID == spells.BLOODSHED then
            bloodshedActive = true
            bloodshedCooldown = API.GetSpellCooldown(spells.BLOODSHED) or 0
            API.PrintDebug("Bloodshed cast")
        elseif spellID == spells.STAMPEDE then
            stampedeCooldown = API.GetSpellCooldown(spells.STAMPEDE) or 0
            API.PrintDebug("Stampede cast")
        elseif spellID == spells.DIRE_BEAST then
            direBeastActive = true
            direBeastEndTime = GetTime() + DIRE_BEAST_DURATION
            API.PrintDebug("Dire Beast cast")
        elseif spellID == spells.WAILING_ARROW then
            wailingArrowCooldown = API.GetSpellCooldown(spells.WAILING_ARROW) or 0
            API.PrintDebug("Wailing Arrow cast")
        elseif spellID == spells.CALL_OF_THE_WILD then
            callOfTheWildActive = true
            callOfTheWildEndTime = GetTime() + CALL_OF_THE_WILD_DURATION
            API.PrintDebug("Call of the Wild cast")
        elseif spellID == spells.KILL_SHOT then
            API.PrintDebug("Kill Shot cast")
        end
    end
    
    return true
end

-- Main rotation function
function BeastMastery:RunRotation()
    -- Check if we should be running Beast Mastery Hunter logic
    if API.GetActiveSpecID() ~= BEAST_MASTERY_SPEC_ID then
        return false
    end
    
    -- Skip rotation if player is casting or channeling
    if API.IsPlayerCasting() or API.IsPlayerChanneling() then
        return false
    end
    
    -- Get settings
    local settings = ConfigRegistry:GetSettings("BeastMasteryHunter")
    
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
    if settings.rotationSettings.petManagement and not petActive then
        if API.CanCast(spells.CALL_PET_1) then
            API.CastSpell(spells.CALL_PET_1)
            return true
        end
    end
    
    -- Heal pet if needed
    if petActive and settings.rotationSettings.petManagement and API.GetPetHealthPercent() <= settings.defensiveSettings.mendPetThreshold and 
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
    
    -- Check if in range for regular abilities
    if not inRange then
        return false
    end
    
    -- Apply Hunter's Mark if enabled
    if settings.utilitySettings.useHuntersMark and 
       not API.TargetHasDebuff(debuffs.HUNTERS_MARK) and
       API.CanCast(spells.HUNTERS_MARK) then
        API.CastSpell(spells.HUNTERS_MARK)
        return true
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
function BeastMastery:HandleInterrupts()
    -- Only attempt to interrupt if in range
    if inRange and API.CanCast(spells.COUNTER_SHOT) and API.TargetIsSpellCastable() then
        API.CastSpell(spells.COUNTER_SHOT)
        return true
    end
    
    return false
end

-- Handle defensive abilities
function BeastMastery:HandleDefensives(settings)
    local playerHealth = API.GetPlayerHealthPercent()
    
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

-- Handle cooldown abilities
function BeastMastery:HandleCooldowns(settings)
    -- Skip if GCD is not ready
    if not API.IsGCDReady() then
        return false
    }
    
    -- Skip offensive cooldowns if not in burst mode or no target
    if not burstModeActive and not API.IsInCombat() then
        return false
    }
    
    -- Use Bestial Wrath
    if settings.offensiveSettings.useBestialWrath and
       settings.abilityControls.bestialWrath.enabled and
       not bestialWrathActive and
       API.CanCast(spells.BESTIAL_WRATH) then
        
        -- Check for focus requirements
        if currentFocus >= settings.abilityControls.bestialWrath.minFocusToUse or 
           (settings.abilityControls.bestialWrath.useDuringBurstOnly and burstModeActive) then
            
            -- Check if we should sync with Aspect of the Wild
            if not settings.offensiveSettings.syncCooldowns or 
               not settings.offensiveSettings.useAspectOfTheWild or 
               aspectOfTheWildActive or 
               not API.IsSpellKnown(spells.ASPECT_OF_THE_WILD) then
                API.CastSpell(spells.BESTIAL_WRATH)
                return true
            end
        end
    end
    
    -- Use Aspect of the Wild
    if settings.offensiveSettings.useAspectOfTheWild and
       settings.abilityControls.aspectOfTheWild.enabled and
       not aspectOfTheWildActive and
       API.CanCast(spells.ASPECT_OF_THE_WILD) then
        
        -- Check if we should sync with Bestial Wrath
        if (not settings.abilityControls.aspectOfTheWild.syncWithBestialWrath or 
            bestialWrathActive or 
            not API.IsSpellKnown(spells.BESTIAL_WRATH)) and
           (not settings.abilityControls.aspectOfTheWild.useDuringBurstOnly or burstModeActive) then
            API.CastSpell(spells.ASPECT_OF_THE_WILD)
            return true
        end
    end
    
    -- Use Bloodshed
    if talents.hasBloodshed and
       settings.offensiveSettings.useBloodshed and
       not bloodshedActive and
       API.CanCast(spells.BLOODSHED) then
        API.CastSpell(spells.BLOODSHED)
        return true
    end
    
    -- Use A Murder of Crows
    if talents.hasAMurderOfCrows and
       settings.offensiveSettings.useAMurderOfCrows and
       API.CanCast(spells.A_MURDER_OF_CROWS) then
        API.CastSpell(spells.A_MURDER_OF_CROWS)
        return true
    end
    
    -- Use Stampede
    if talents.hasStampede and
       settings.offensiveSettings.useStampede and
       API.CanCast(spells.STAMPEDE) then
        API.CastSpellAtCursor(spells.STAMPEDE)
        return true
    end
    
    -- Use Dire Beast
    if talents.hasDireBeast and
       settings.offensiveSettings.useDireBeast and
       not direBeastActive and
       API.CanCast(spells.DIRE_BEAST) then
        API.CastSpell(spells.DIRE_BEAST)
        return true
    end
    
    -- Use Wailing Arrow
    if talents.hasWailingArrow and
       settings.offensiveSettings.useWailingArrow and
       API.CanCast(spells.WAILING_ARROW) then
        API.CastSpell(spells.WAILING_ARROW)
        return true
    end
    
    -- Use Barrage
    if talents.hasBarrage and
       settings.offensiveSettings.useBarrage and
       currentAoETargets >= settings.offensiveSettings.barrageMinTargets and
       API.CanCast(spells.BARRAGE) then
        API.CastSpell(spells.BARRAGE)
        return true
    end
    
    return false
end

-- Handle AoE rotation
function BeastMastery:HandleAoERotation(settings)
    -- Maintain Beast Cleave if enabled
    if talents.hasBeastCleave and
       settings.advancedSettings.maintainBeastCleave and
       (not beastCleaveActive || GetTime() - beastCleaveReset > 2.5) and
       API.CanCast(spells.MULTISHOT) then
        API.CastSpell(spells.MULTISHOT)
        return true
    end
    
    -- Use Kill Command - highest priority
    if settings.abilityControls.killCommand.alwaysMaxPriority and
       killCommandCharges > 0 and
       API.CanCast(spells.KILL_COMMAND) then
        API.CastSpell(spells.KILL_COMMAND)
        return true
    end
    
    -- Use Barbed Shot based on strategy
    if API.CanCast(spells.BARBED_SHOT) and barbedShotCharges > settings.advancedSettings.maxBarbedShotCharges then
        -- If we have more charges than the maximum we want to hold
        API.CastSpell(spells.BARBED_SHOT)
        return true
    elseif API.CanCast(spells.BARBED_SHOT) and settings.rotationSettings.barbedShotStrategy == "Maintain Frenzy" and
           (not frenzyActive or frenzyEndTime - GetTime() < settings.advancedSettings.barbedShotMinFrenzyTime) then
        -- Prioritize maintaining Frenzy
        API.CastSpell(spells.BARBED_SHOT)
        return true
    end
    
    -- Use Kill Shot if available and enabled
    if killShotAvailable and 
       settings.rotationSettings.killShotUsage != "Never" and
       API.CanCast(spells.KILL_SHOT) then
        API.CastSpell(spells.KILL_SHOT)
        return true
    end
    
    -- Multi-Shot to maintain Beast Cleave
    if talents.hasBeastCleave and
       not beastCleaveActive and
       API.CanCast(spells.MULTISHOT) then
        API.CastSpell(spells.MULTISHOT)
        return true
    end
    
    -- Use Barbed Shot with remaining charges
    if API.CanCast(spells.BARBED_SHOT) and barbedShotCharges > 0 and
       settings.rotationSettings.barbedShotStrategy == "Focus Generation" then
        API.CastSpell(spells.BARBED_SHOT)
        return true
    end
    
    -- Use Kill Command if available
    if killCommandCharges > 0 and API.CanCast(spells.KILL_COMMAND) then
        API.CastSpell(spells.KILL_COMMAND)
        return true
    end
    
    -- Use Cobra Shot as filler
    if API.CanCast(spells.COBRA_SHOT) and
       (settings.advancedSettings.focusPooling == false or 
        currentFocus > settings.advancedSettings.minFocusPool) then
        API.CastSpell(spells.COBRA_SHOT)
        return true
    end
    
    return false
end

-- Handle Single Target rotation
function BeastMastery:HandleSingleTargetRotation(settings)
    -- Use Kill Command - highest priority
    if settings.abilityControls.killCommand.alwaysMaxPriority and
       killCommandCharges > 0 and
       API.CanCast(spells.KILL_COMMAND) then
        API.CastSpell(spells.KILL_COMMAND)
        return true
    end
    
    -- Use Barbed Shot based on strategy
    if API.CanCast(spells.BARBED_SHOT) and barbedShotCharges > settings.advancedSettings.maxBarbedShotCharges then
        -- If we have more charges than the maximum we want to hold
        API.CastSpell(spells.BARBED_SHOT)
        return true
    elseif API.CanCast(spells.BARBED_SHOT) and settings.rotationSettings.barbedShotStrategy == "Maintain Frenzy" and
           (not frenzyActive or frenzyEndTime - GetTime() < settings.advancedSettings.barbedShotMinFrenzyTime) then
        -- Prioritize maintaining Frenzy
        API.CastSpell(spells.BARBED_SHOT)
        return true
    end
    
    -- Use Kill Shot if available and enabled
    if killShotAvailable and 
       settings.rotationSettings.killShotUsage != "Never" and
       API.CanCast(spells.KILL_SHOT) then
        API.CastSpell(spells.KILL_SHOT)
        return true
    end
    
    -- Use Kill Command if available
    if killCommandCharges > 0 and API.CanCast(spells.KILL_COMMAND) then
        API.CastSpell(spells.KILL_COMMAND)
        return true
    end
    
    -- Use Barbed Shot with remaining charges if we're using Focus Generation strategy
    if API.CanCast(spells.BARBED_SHOT) and barbedShotCharges > 0 and
       settings.rotationSettings.barbedShotStrategy == "Focus Generation" then
        API.CastSpell(spells.BARBED_SHOT)
        return true
    end
    
    -- Use Cobra Shot as filler
    if API.CanCast(spells.COBRA_SHOT) and
       (settings.advancedSettings.focusPooling == false or 
        currentFocus > settings.advancedSettings.minFocusPool) then
        API.CastSpell(spells.COBRA_SHOT)
        return true
    end
    
    return false
end

-- Handle specialization change
function BeastMastery:OnSpecializationChanged()
    -- Update talent information
    self:UpdateTalentInfo()
    
    -- Reset state variables
    nextCastOverride = nil
    burstModeActive = false
    currentAoETargets = 0
    currentFocus = API.GetPlayerPower()
    maxFocus = 100
    beastCleaveActive = false
    beastCleaveEndTime = 0
    frenzyActive = false
    frenzyStacks = 0
    frenzyEndTime = 0
    bestialWrathActive = false
    bestialWrathEndTime = 0
    aspectOfTheWildActive = false
    aspectOfTheWildEndTime = 0
    aspectOfTheEagleActive = false
    aspectOfTheEagleEndTime = 0
    coordinatedAssaultActive = false
    coordinatedAssaultEndTime = 0
    wildSpiritsActive = false
    wildSpiritsEndTime = 0
    resonatingArrowActive = false
    resonatingArrowEndTime = 0
    flayedShotActive = false
    flayerMarkStacks = 0
    barbedShotCharges = API.GetSpellCharges(spells.BARBED_SHOT) or 0
    barbedShotMaxCharges = API.GetSpellMaxCharges(spells.BARBED_SHOT) or 2
    killCommandCharges = API.GetSpellCharges(spells.KILL_COMMAND) or 0
    killCommandMaxCharges = API.GetSpellMaxCharges(spells.KILL_COMMAND) or 1
    killCommandCooldownRemaining = 0
    killShotAvailable = false
    petActive = API.HasActivePet()
    barbedShotRechargeTime = 0
    direBeastActive = false
    direBeastEndTime = 0
    oneWithThePackActive = false
    oneWithThePackEndTime = 0
    bloodshedActive = false
    bloodshedCooldown = 0
    callOfTheWildActive = false
    callOfTheWildEndTime = 0
    stampedeCooldown = 0
    wailingArrowCooldown = 0
    serpentStingActive = false
    serpentStingEndTime = 0
    inAspectOfTheCheetah = false
    inAspectOfTheTurtle = false
    petFrenzy = false
    petFrenzyStacks = 0
    petFrenzyEndTime = 0
    cobraShotFocusReduction = 0
    blazingConcentration = false
    blazingConcentrationStacks = 0
    packLeader = false
    packLeaderEndTime = 0
    killCleaveActive = false
    killCleaveEndTime = 0
    deadlyDuo = false
    scent4Blood = false
    savageMarauder = false
    packTactics = false
    wildInstinct = false
    rageOfTheSleeper = false
    killCommand2 = false
    empoweredRelease = false
    wildCall = false
    direBeast = false
    scentOfBlood = false
    alphaPredator = false
    inRange = false
    inMeleeRange = false
    beastCleaveReset = 0
    counterstrike = false
    counterstrikeCharges = 0
    huntersBond = false
    ichorInfusion = false
    improvedKillCommand = false
    spinningCrane = false
    
    API.PrintDebug("Beast Mastery Hunter state reset on spec change")
    
    return true
end

-- Return the module for loading
return BeastMastery