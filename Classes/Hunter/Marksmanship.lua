------------------------------------------
-- WindrunnerRotations - Marksmanship Hunter Module
-- Author: VortexQ8
-- The War Within Season 2
------------------------------------------

local Marksmanship = {}
-- This will be assigned to addon.Classes.Hunter.Marksmanship when loaded

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
local trueshotActive = false
local trueshotEndTime = 0
local lockAndLoadActive = false
local lockAndLoadEndTime = 0
local lockAndLoadCharges = 0
local preciseShots = false
local preciseShotsStacks = 0
local preciseShotsEndTime = 0
local trickShotsActive = false
local trickShotsEndTime = 0
local steadyFocusActive = false
local steadyFocusEndTime = 0
local volleyActive = false
local volleyEndTime = 0
local deathchakramsActive = false
local vipersVenomActive = false
local vipersVenomEndTime = 0
local razorFragments = false
local razorFragmentsStacks = 0
local razorFragmentsEndTime = 0
local salvoActive = false
local eagletalonsFire = false
local eagletalonsFireEndTime = 0
local bulletstormActive = false
local bulletstormStacks = 0
local bulletstormEndTime = 0
local serpentSting = false
local serpentStingActive = false
local serpentStingEndTime = 0
local lethalShotsActive = false
local lethalShotsStacks = 0
local lethalShotsEndTime = 0
local inTheRhythmActive = false
local inTheRhythmStacks = 0
local inTheRhythmEndTime = 0
local unerringVisionActive = false
local unerringVisionStacks = 0
local unerringVisionEndTime = 0
local petActive = false
local rapidFireActive = false
local rapidFireEndTime = 0
local rapidFireCastFinishTime = 0
local aimingShot = false
local aimingShotCastFinishTime = 0
local windrunnersFire = false
local killShot = false
local killShotAvailable = false
local multiShot = false
local arcaneShot = false
local rapidFire = false
local aimingShotCasting = false
local trueshot = false
local volley = false
local deathChakram = false
local wailingArrow = false
local salvo = false
local inRange = false
local chimaeraShotActive = false
local chimaeraShotEndTime = 0
local bombardmentActive = false
local bombardmentEndTime = 0
local latentVenom = false
local latentVenomStacks = 0
local latentVenomEndTime = 0
local deathlyPrecision = false
local deathlyPrecisionStacks = 0
local deathlyPrecisionEndTime = 0
local burningWounds = false
local burningWoundsStacks = 0
local burningWoundsEndTime = 0
local huntsmansKnowledge = false
local incomingKillingShotWindow = false
local sentryShot = false
local inTheRythm = false
local surgeOfAgility = false
local visionOfVengeance = false
local serpentstalkersTrickery = false
local chimaericFire = false

-- Constants
local MARKSMANSHIP_SPEC_ID = 254
local DEFAULT_AOE_THRESHOLD = 3
local TRUESHOT_DURATION = 15 -- seconds
local TRICK_SHOTS_DURATION = 8 -- seconds
local STEADY_FOCUS_DURATION = 15 -- seconds
local PRECISE_SHOTS_DURATION = 15 -- seconds
local VOLLEY_DURATION = 6 -- seconds
local RAPID_FIRE_CHANNEL_TIME = 2 -- seconds
local AIMED_SHOT_CAST_TIME = 2.5 -- seconds base cast time
local LOCK_AND_LOAD_DURATION = 15 -- seconds
local VIPERS_VENOM_DURATION = 8 -- seconds
local EAGLETALON_DURATION = 8 -- seconds
local BULLETSTORM_DURATION = 15 -- seconds
local SERPENT_STING_DURATION = 18 -- seconds
local LETHAL_SHOTS_DURATION = 20 -- seconds
local IN_THE_RHYTHM_DURATION = 8 -- seconds
local UNERRING_VISION_DURATION = 10 -- seconds
local CHIMAERA_SHOT_DURATION = 0.1 -- very short duration
local LATENT_VENOM_DURATION = 20 -- seconds
local DEATHLY_PRECISION_DURATION = 30 -- seconds
local BURNING_WOUNDS_DURATION = 12 -- seconds
local BOMBARDMENT_DURATION = 10 -- seconds
local HUNTING_RANGE = 40 -- yards

-- Initialize the Marksmanship module
function Marksmanship:Initialize()
    self:RegisterSpells()
    self:RegisterVariables()
    self:RegisterSettings()
    self:RegisterEvents()
    
    API.PrintDebug("Marksmanship Hunter module initialized")
    
    return true
end

-- Register spell IDs
function Marksmanship:RegisterSpells()
    -- Core rotational abilities
    spells.AIMED_SHOT = 19434
    spells.ARCANE_SHOT = 185358
    spells.RAPID_FIRE = 257044
    spells.STEADY_SHOT = 56641
    spells.MULTI_SHOT = 257620
    spells.KILL_SHOT = 53351
    spells.TRUESHOT = 288613
    spells.SERPENT_STING = 271788
    spells.VOLLEY = 260243
    spells.BURSTING_SHOT = 186387
    spells.WAILING_ARROW = 392060
    spells.EXPLOSIVE_SHOT = 212431
    spells.CHIMAERA_SHOT = 342049
    spells.DEATH_CHAKRAM = 375891
    
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
    spells.FLARE = 1543
    spells.FREEZING_TRAP = 187650
    spells.TAR_TRAP = 187698
    spells.STEEL_TRAP = 162488
    spells.BINDING_SHOT = 109248
    spells.DISENGAGE = 781
    
    -- Talents and passives
    spells.LOCK_AND_LOAD = 194594
    spells.PRECISE_SHOTS = 260240
    spells.TRICK_SHOTS = 257621
    spells.BOMBARDMENT = 386875
    spells.STEADY_FOCUS = 193533
    spells.MASTER_MARKSMAN = 260309
    spells.STREAMLINE = 260367
    spells.CALLING_THE_SHOTS = 260404
    spells.CHIMAERA_SHOT = 342049
    spells.CHIMAERIC_FIRE = 404792
    spells.SALVO = 384791
    spells.SERPENTSTALKERS_TRICKERY = 378014
    spells.EAGLETALONS_TRUE_FOCUS = 336851
    spells.BULLETSTORM = 389019
    spells.RAZOR_FRAGMENTS = 388998
    spells.VIPERS_VENOM = 260241
    spells.POISON_INJECTION = 378014
    spells.LETHAL_SHOTS = 260393
    spells.WAILING_ARROW = 392060
    spells.VOLLEY = 260243
    spells.HYDRAS_BITE = 260241
    spells.EXPLOSIVE_SHOT = 212431
    spells.RANGERS_FINESSE = 248443
    spells.IN_THE_RHYTHM = 407405
    spells.UNERRING_VISION = 274447
    spells.TRAILBLAZER = 199921
    spells.POSTHASTE = 109215
    spells.BORN_TO_BE_WILD = 266921
    spells.CAMOUFLAGE = 199483
    spells.BINDING_SHACKLES = 321468
    spells.HUNTERS_AVOIDANCE = 248518
    spells.NATURAL_MENDING = 270581
    spells.LONE_WOLF = 155228
    spells.READINESS = 389017
    spells.LATENT_POISON = 378014
    spells.CAREFUL_AIM = 260228
    spells.DEATHLY_PRECISION = 389882
    spells.BURNING_WOUNDS = 389019
    spells.WINDRUNNERS_FURY = 431830
    spells.HUNTSMANS_KNOWLEDGE = 377900
    spells.INCOMING = 377887
    spells.SENTRY_SHOT = 389761
    spells.SURGE_OF_AGILITY = 389890
    spells.VISION_OF_VENGEANCE = 378210
    
    -- War Within Season 2 specific
    spells.BUNDLED_ROUNDS = 389440
    spells.BULLETSTORM = 389019
    spells.CASCADE = 384791
    spells.DEADLY_DUO = 389756
    spells.DEADEYE = 321460
    spells.LEGACYSHOT = 389720
    spells.MARKSMANS_ADVANTAGE = 409560
    spells.QUICK_DRAW = 378086
    spells.RAZOR_FRAGMENTS = 388998
    spells.SALVO = 384791
    spells.SHARPSHOOTERS_FOCUS = 389760
    spells.TIMED_KILL = 375893
    
    -- Covenant abilities (for reference, converted in WoW 10.0)
    spells.RESONATING_ARROW = 308491
    spells.WILD_SPIRITS = 328231
    spells.FLAYED_SHOT = 324149
    spells.DEATH_CHAKRAM = 375891
    
    -- Buff IDs
    spells.TRUESHOT_BUFF = 288613
    spells.LOCK_AND_LOAD_BUFF = 194594
    spells.PRECISE_SHOTS_BUFF = 260242
    spells.TRICK_SHOTS_BUFF = 257622
    spells.STEADY_FOCUS_BUFF = 193534
    spells.VOLLEY_BUFF = 260243
    spells.VIPERS_VENOM_BUFF = 260242
    spells.RAZOR_FRAGMENTS_BUFF = 388998
    spells.EAGLETALONS_TRUE_FOCUS_BUFF = 336849
    spells.BULLETSTORM_BUFF = 389020
    spells.LETHAL_SHOTS_BUFF = 260395
    spells.IN_THE_RHYTHM_BUFF = 407405
    spells.BOMBARDMENT_BUFF = 386881
    spells.UNERRING_VISION_BUFF = 274447
    spells.LATENT_POISON_BUFF = 378015
    spells.DEATHLY_PRECISION_BUFF = 389884
    spells.BURNING_WOUNDS_BUFF = 389020
    
    -- Debuff IDs
    spells.HUNTERS_MARK_DEBUFF = 257284
    spells.SERPENT_STING_DEBUFF = 271788
    
    -- Register all spells with the API tracking system
    for spellName, spellID in pairs(spells) do
        API.RegisterSpell(spellID)
    end
    
    -- Define aura tracking
    buffs.TRUESHOT = spells.TRUESHOT_BUFF
    buffs.LOCK_AND_LOAD = spells.LOCK_AND_LOAD_BUFF
    buffs.PRECISE_SHOTS = spells.PRECISE_SHOTS_BUFF
    buffs.TRICK_SHOTS = spells.TRICK_SHOTS_BUFF
    buffs.STEADY_FOCUS = spells.STEADY_FOCUS_BUFF
    buffs.VOLLEY = spells.VOLLEY_BUFF
    buffs.VIPERS_VENOM = spells.VIPERS_VENOM_BUFF
    buffs.RAZOR_FRAGMENTS = spells.RAZOR_FRAGMENTS_BUFF
    buffs.EAGLETALONS_TRUE_FOCUS = spells.EAGLETALONS_TRUE_FOCUS_BUFF
    buffs.BULLETSTORM = spells.BULLETSTORM_BUFF
    buffs.LETHAL_SHOTS = spells.LETHAL_SHOTS_BUFF
    buffs.IN_THE_RHYTHM = spells.IN_THE_RHYTHM_BUFF
    buffs.BOMBARDMENT = spells.BOMBARDMENT_BUFF
    buffs.UNERRING_VISION = spells.UNERRING_VISION_BUFF
    buffs.LATENT_POISON = spells.LATENT_POISON_BUFF
    buffs.DEATHLY_PRECISION = spells.DEATHLY_PRECISION_BUFF
    buffs.BURNING_WOUNDS = spells.BURNING_WOUNDS_BUFF
    
    debuffs.HUNTERS_MARK = spells.HUNTERS_MARK_DEBUFF
    debuffs.SERPENT_STING = spells.SERPENT_STING_DEBUFF
    
    return true
end

-- Register variables to track
function Marksmanship:RegisterVariables()
    -- Talent tracking
    talents.hasLockAndLoad = false
    talents.hasPreciseShots = false
    talents.hasTrickShots = false
    talents.hasBombardment = false
    talents.hasSteadyFocus = false
    talents.hasMasterMarksman = false
    talents.hasStreamline = false
    talents.hasCallingTheShots = false
    talents.hasChimaeraShot = false
    talents.hasChimaericFire = false
    talents.hasSalvo = false
    talents.hasSerpentstalkersTrickery = false
    talents.hasEagletalonsTrue = false
    talents.hasBulletstorm = false
    talents.hasRazorFragments = false
    talents.hasVipersVenom = false
    talents.hasPoisonInjection = false
    talents.hasLethalShots = false
    talents.hasWailingArrow = false
    talents.hasVolley = false
    talents.hasHydrasBite = false
    talents.hasExplosiveShot = false
    talents.hasRangersFinesse = false
    talents.hasInTheRhythm = false
    talents.hasUnerringVision = false
    talents.hasTrailblazer = false
    talents.hasPosthaste = false
    talents.hasBornToBeWild = false
    talents.hasCamouflage = false
    talents.hasBindingShackles = false
    talents.hasHuntersAvoidance = false
    talents.hasNaturalMending = false
    talents.hasLoneWolf = false
    talents.hasReadiness = false
    talents.hasLatentPoison = false
    talents.hasCarefulAim = false
    talents.hasDeathlyPrecision = false
    talents.hasBurningWounds = false
    talents.hasWindrunnersFury = false
    talents.hasHuntsmansKnowledge = false
    talents.hasIncoming = false
    talents.hasSentryShot = false
    talents.hasSurgeOfAgility = false
    talents.hasVisionOfVengeance = false
    
    -- War Within Season 2 talents
    talents.hasBundledRounds = false
    talents.hasBulletstorm = false
    talents.hasCascade = false
    talents.hasDeadlyDuo = false
    talents.hasDeadeye = false
    talents.hasLegacyshot = false
    talents.hasMarksmanAdvantage = false
    talents.hasQuickDraw = false
    talents.hasRazorFragments = false
    talents.hasSalvo = false
    talents.hasSharpshootersFocus = false
    talents.hasTimedKill = false
    
    -- Initialize resources
    currentFocus = API.GetPlayerPower()
    
    -- Check if pet exists
    petActive = API.HasActivePet()
    
    return true
end

-- Register spec-specific settings
function Marksmanship:RegisterSettings()
    ConfigRegistry:RegisterSettings("MarksmanshipHunter", {
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
            steadyShotStrategy = {
                displayName = "Steady Shot Strategy",
                description = "When to use Steady Shot",
                type = "dropdown",
                options = {"Focus Emergency", "Buff Maintenance", "On Cooldown"},
                default = "Buff Maintenance"
            },
            steadyShotEmergencyThreshold = {
                displayName = "Steady Shot Emergency Threshold",
                description = "Focus level to use Steady Shot as emergency",
                type = "slider",
                min = 5,
                max = 50,
                default = 20
            },
            usePetActive = {
                displayName = "Use Pet",
                description = "Summon and use pet instead of Lone Wolf",
                type = "toggle",
                default = false
            }
        },
        
        abilitySettings = {
            useAimedShot = {
                displayName = "Use Aimed Shot",
                description = "Automatically use Aimed Shot",
                type = "toggle",
                default = true
            },
            rapidFireStrategy = {
                displayName = "Rapid Fire Strategy",
                description = "When to use Rapid Fire",
                type = "dropdown",
                options = {"On Cooldown", "With Trick Shots", "Save for Trueshot"},
                default = "On Cooldown"
            },
            usePreciseShots = {
                displayName = "Use Precise Shots Procs",
                description = "Use Arcane Shot with Precise Shots",
                type = "toggle",
                default = true
            },
            useChimaeraShot = {
                displayName = "Use Chimaera Shot",
                description = "Automatically use Chimaera Shot when talented",
                type = "toggle",
                default = true
            },
            chimaeraUsageStrategy = {
                displayName = "Chimaera Shot Usage",
                description = "When to use Chimaera Shot",
                type = "dropdown",
                options = {"On Cooldown", "For Focus Generation", "With Precise Shots"},
                default = "On Cooldown"
            },
            useSerpentSting = {
                displayName = "Use Serpent Sting",
                description = "Automatically apply and maintain Serpent Sting",
                type = "toggle",
                default = true
            },
            serpentStingRefreshThreshold = {
                displayName = "Serpent Sting Refresh Threshold",
                description = "Seconds remaining to refresh Serpent Sting",
                type = "slider",
                min = 1,
                max = 8,
                default = 3
            }
        },
        
        cooldownSettings = {
            useTrueshot = {
                displayName = "Use Trueshot",
                description = "Automatically use Trueshot",
                type = "toggle",
                default = true
            },
            useVolley = {
                displayName = "Use Volley",
                description = "Automatically use Volley when talented",
                type = "toggle",
                default = true
            },
            volleyMinTargets = {
                displayName = "Volley Minimum Targets",
                description = "Minimum targets to use Volley",
                type = "slider",
                min = 1,
                max = 5,
                default = 2
            },
            useExplosiveShot = {
                displayName = "Use Explosive Shot",
                description = "Automatically use Explosive Shot when talented",
                type = "toggle",
                default = true
            },
            explosiveShotMinTargets = {
                displayName = "Explosive Shot Minimum Targets",
                description = "Minimum targets to use Explosive Shot",
                type = "slider",
                min = 1,
                max = 5,
                default = 2
            },
            useSalvo = {
                displayName = "Use Salvo",
                description = "Automatically use Salvo when talented",
                type = "toggle",
                default = true
            },
            useWailingArrow = {
                displayName = "Use Wailing Arrow",
                description = "Automatically use Wailing Arrow when talented",
                type = "toggle",
                default = true
            },
            useDeathChakram = {
                displayName = "Use Death Chakram",
                description = "Automatically use Death Chakram when talented",
                type = "toggle",
                default = true
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
            useHuntersMark = {
                displayName = "Use Hunter's Mark",
                description = "Automatically apply Hunter's Mark",
                type = "toggle",
                default = true
            },
            useTranquilizingShot = {
                displayName = "Use Tranquilizing Shot",
                description = "Automatically use Tranquilizing Shot to remove buffs",
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
            useFreezingTrap = {
                displayName = "Use Freezing Trap",
                description = "Automatically use Freezing Trap",
                type = "toggle",
                default = true
            }
        },
        
        -- Advanced ability control settings
        abilityControls = {
            -- Trueshot controls
            trueshot = AAC.RegisterAbility(spells.TRUESHOT, {
                enabled = true,
                useDuringBurstOnly = true,
                requireLockAndLoad = false,
                requireFocusAmount = 60
            }),
            
            -- Aimed Shot controls
            aimedShot = AAC.RegisterAbility(spells.AIMED_SHOT, {
                enabled = true,
                useDuringMovement = false,
                prioritizeLockAndLoad = true,
                minFocus = 35
            }),
            
            -- Rapid Fire controls
            rapidFire = AAC.RegisterAbility(spells.RAPID_FIRE, {
                enabled = true,
                useDuringTrueshot = true,
                useDuringMovement = true
            })
        }
    })
    
    return true
end

-- Register for events 
function Marksmanship:RegisterEvents()
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
    
    -- Register for spell cast start
    API.RegisterEvent("UNIT_SPELLCAST_START", function(unit, _, spellID)
        if unit == "player" then
            if spellID == spells.AIMED_SHOT then
                aimingShotCasting = true
                aimingShotCastFinishTime = GetTime() + AIMED_SHOT_CAST_TIME / (1 + (API.GetPlayerHaste() / 100))
                API.PrintDebug("Started casting Aimed Shot")
            end
        end
    end)
    
    -- Register for spell cast stop
    API.RegisterEvent("UNIT_SPELLCAST_STOP", function(unit, _, spellID)
        if unit == "player" then
            if spellID == spells.AIMED_SHOT then
                aimingShotCasting = false
                API.PrintDebug("Stopped casting Aimed Shot")
            end
        end
    end)
    
    -- Register for rapid fire channel start
    API.RegisterEvent("UNIT_SPELLCAST_CHANNEL_START", function(unit, _, spellID)
        if unit == "player" then
            if spellID == spells.RAPID_FIRE then
                rapidFireActive = true
                rapidFireEndTime = GetTime() + RAPID_FIRE_CHANNEL_TIME
                rapidFireCastFinishTime = rapidFireEndTime
                API.PrintDebug("Started channeling Rapid Fire")
            end
        end
    end)
    
    -- Register for rapid fire channel stop
    API.RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP", function(unit, _, spellID)
        if unit == "player" then
            if spellID == spells.RAPID_FIRE then
                rapidFireActive = false
                API.PrintDebug("Stopped channeling Rapid Fire")
            end
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
function Marksmanship:UpdateTalentInfo()
    -- Check for important talents
    talents.hasLockAndLoad = API.HasTalent(spells.LOCK_AND_LOAD)
    talents.hasPreciseShots = API.HasTalent(spells.PRECISE_SHOTS)
    talents.hasTrickShots = API.HasTalent(spells.TRICK_SHOTS)
    talents.hasBombardment = API.HasTalent(spells.BOMBARDMENT)
    talents.hasSteadyFocus = API.HasTalent(spells.STEADY_FOCUS)
    talents.hasMasterMarksman = API.HasTalent(spells.MASTER_MARKSMAN)
    talents.hasStreamline = API.HasTalent(spells.STREAMLINE)
    talents.hasCallingTheShots = API.HasTalent(spells.CALLING_THE_SHOTS)
    talents.hasChimaeraShot = API.HasTalent(spells.CHIMAERA_SHOT)
    talents.hasChimaericFire = API.HasTalent(spells.CHIMAERIC_FIRE)
    talents.hasSalvo = API.HasTalent(spells.SALVO)
    talents.hasSerpentstalkersTrickery = API.HasTalent(spells.SERPENTSTALKERS_TRICKERY)
    talents.hasEagletalonsTrue = API.HasTalent(spells.EAGLETALONS_TRUE_FOCUS)
    talents.hasBulletstorm = API.HasTalent(spells.BULLETSTORM)
    talents.hasRazorFragments = API.HasTalent(spells.RAZOR_FRAGMENTS)
    talents.hasVipersVenom = API.HasTalent(spells.VIPERS_VENOM)
    talents.hasPoisonInjection = API.HasTalent(spells.POISON_INJECTION)
    talents.hasLethalShots = API.HasTalent(spells.LETHAL_SHOTS)
    talents.hasWailingArrow = API.HasTalent(spells.WAILING_ARROW)
    talents.hasVolley = API.HasTalent(spells.VOLLEY)
    talents.hasHydrasBite = API.HasTalent(spells.HYDRAS_BITE)
    talents.hasExplosiveShot = API.HasTalent(spells.EXPLOSIVE_SHOT)
    talents.hasRangersFinesse = API.HasTalent(spells.RANGERS_FINESSE)
    talents.hasInTheRhythm = API.HasTalent(spells.IN_THE_RHYTHM)
    talents.hasUnerringVision = API.HasTalent(spells.UNERRING_VISION)
    talents.hasTrailblazer = API.HasTalent(spells.TRAILBLAZER)
    talents.hasPosthaste = API.HasTalent(spells.POSTHASTE)
    talents.hasBornToBeWild = API.HasTalent(spells.BORN_TO_BE_WILD)
    talents.hasCamouflage = API.HasTalent(spells.CAMOUFLAGE)
    talents.hasBindingShackles = API.HasTalent(spells.BINDING_SHACKLES)
    talents.hasHuntersAvoidance = API.HasTalent(spells.HUNTERS_AVOIDANCE)
    talents.hasNaturalMending = API.HasTalent(spells.NATURAL_MENDING)
    talents.hasLoneWolf = API.HasTalent(spells.LONE_WOLF)
    talents.hasReadiness = API.HasTalent(spells.READINESS)
    talents.hasLatentPoison = API.HasTalent(spells.LATENT_POISON)
    talents.hasCarefulAim = API.HasTalent(spells.CAREFUL_AIM)
    talents.hasDeathlyPrecision = API.HasTalent(spells.DEATHLY_PRECISION)
    talents.hasBurningWounds = API.HasTalent(spells.BURNING_WOUNDS)
    talents.hasWindrunnersFury = API.HasTalent(spells.WINDRUNNERS_FURY)
    talents.hasHuntsmansKnowledge = API.HasTalent(spells.HUNTSMANS_KNOWLEDGE)
    talents.hasIncoming = API.HasTalent(spells.INCOMING)
    talents.hasSentryShot = API.HasTalent(spells.SENTRY_SHOT)
    talents.hasSurgeOfAgility = API.HasTalent(spells.SURGE_OF_AGILITY)
    talents.hasVisionOfVengeance = API.HasTalent(spells.VISION_OF_VENGEANCE)
    
    -- War Within Season 2 talents
    talents.hasBundledRounds = API.HasTalent(spells.BUNDLED_ROUNDS)
    talents.hasBulletstorm = API.HasTalent(spells.BULLETSTORM)
    talents.hasCascade = API.HasTalent(spells.CASCADE)
    talents.hasDeadlyDuo = API.HasTalent(spells.DEADLY_DUO)
    talents.hasDeadeye = API.HasTalent(spells.DEADEYE)
    talents.hasLegacyshot = API.HasTalent(spells.LEGACYSHOT)
    talents.hasMarksmanAdvantage = API.HasTalent(spells.MARKSMANS_ADVANTAGE)
    talents.hasQuickDraw = API.HasTalent(spells.QUICK_DRAW)
    talents.hasRazorFragments = API.HasTalent(spells.RAZOR_FRAGMENTS)
    talents.hasSalvo = API.HasTalent(spells.SALVO)
    talents.hasSharpshootersFocus = API.HasTalent(spells.SHARPSHOOTERS_FOCUS)
    talents.hasTimedKill = API.HasTalent(spells.TIMED_KILL)
    
    -- Set specialized variables based on talents
    if talents.hasPreciseShots then
        preciseShots = true
    end
    
    if talents.hasSerpentSting then
        serpentSting = true
    end
    
    if talents.hasWindrunnersFury then
        windrunnersFire = true
    end
    
    if API.IsSpellKnown(spells.KILL_SHOT) then
        killShot = true
    end
    
    if API.IsSpellKnown(spells.MULTI_SHOT) then
        multiShot = true
    end
    
    if API.IsSpellKnown(spells.ARCANE_SHOT) then
        arcaneShot = true
    end
    
    if API.IsSpellKnown(spells.RAPID_FIRE) then
        rapidFire = true
    end
    
    if API.IsSpellKnown(spells.AIMED_SHOT) then
        aimingShot = true
    end
    
    if API.IsSpellKnown(spells.TRUESHOT) then
        trueshot = true
    end
    
    if talents.hasVolley then
        volley = true
    end
    
    if talents.hasDeathChakram then
        deathChakram = true
    end
    
    if talents.hasWailingArrow then
        wailingArrow = true
    end
    
    if talents.hasSalvo then
        salvo = true
    end
    
    if talents.hasHuntsmansKnowledge then
        huntsmansKnowledge = true
    end
    
    if talents.hasSentryShot then
        sentryShot = true
    end
    
    if talents.hasInTheRhythm then
        inTheRythm = true
    end
    
    if talents.hasSurgeOfAgility then
        surgeOfAgility = true
    end
    
    if talents.hasVisionOfVengeance then
        visionOfVengeance = true
    end
    
    if talents.hasSerpentstalkersTrickery then
        serpentstalkersTrickery = true
    end
    
    if talents.hasChimaericFire then
        chimaericFire = true
    end
    
    -- Reset precise shots for safety
    preciseShotsStacks = 0
    preciseShotsEndTime = 0
    
    API.PrintDebug("Marksmanship Hunter talents updated")
    
    return true
end

-- Update focus tracking
function Marksmanship:UpdateFocus()
    currentFocus = API.GetPlayerPower()
    return true
end

-- Update pet status
function Marksmanship:UpdatePetStatus()
    petActive = API.HasActivePet()
    return true
end

-- Update target data
function Marksmanship:UpdateTargetData()
    -- Check if in range
    inRange = API.IsUnitInRange("target", HUNTING_RANGE)
    
    -- Get target GUID
    local targetGUID = API.GetTargetGUID()
    
    if targetGUID and targetGUID ~= "" then
        -- Check if target is in execute range for Kill Shot
        killShotAvailable = API.GetTargetHealthPercent() <= 20
        
        -- Check for Serpent Sting
        if serpentSting then
            local serpentStingInfo = API.GetDebuffInfo(targetGUID, debuffs.SERPENT_STING)
            if serpentStingInfo then
                serpentStingActive = true
                serpentStingEndTime = select(6, serpentStingInfo)
            else
                serpentStingActive = false
                serpentStingEndTime = 0
            end
        end
        
        -- Check for incoming kill shot (a feature of the Incoming talent that shows when targets are about to be in Kill Shot range)
        if talents.hasIncoming then
            local targetHealth = API.GetTargetHealthPercent()
            incomingKillingShotWindow = targetHealth > 20 and targetHealth <= 25
        end
    else
        killShotAvailable = false
        serpentStingActive = false
        serpentStingEndTime = 0
        incomingKillingShotWindow = false
    end
    
    -- Update AoE targets count
    currentAoETargets = API.GetNearbyEnemiesCount(8) -- Multi-Shot/Trick Shots radius
    
    return true
end

-- Handle combat log events
function Marksmanship:HandleCombatLogEvent(...)
    local timestamp, eventType, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, spellID, spellName = CombatLogGetCurrentEventInfo()
    
    -- Only process events from the player
    if sourceGUID ~= API.GetPlayerGUID() then
        return false
    end
    
    -- Track buff applications
    if eventType == "SPELL_AURA_APPLIED" or eventType == "SPELL_AURA_REFRESH" then
        -- Track player buffs
        if destGUID == API.GetPlayerGUID() then
            -- Track Trueshot
            if spellID == buffs.TRUESHOT then
                trueshotActive = true
                trueshotEndTime = GetTime() + TRUESHOT_DURATION
                API.PrintDebug("Trueshot activated")
            end
            
            -- Track Lock and Load
            if spellID == buffs.LOCK_AND_LOAD then
                lockAndLoadActive = true
                lockAndLoadCharges = select(4, API.GetBuffInfo("player", buffs.LOCK_AND_LOAD)) or 1
                lockAndLoadEndTime = select(6, API.GetBuffInfo("player", buffs.LOCK_AND_LOAD))
                API.PrintDebug("Lock and Load activated: " .. tostring(lockAndLoadCharges) .. " charges")
            end
            
            -- Track Precise Shots
            if spellID == buffs.PRECISE_SHOTS then
                preciseShots = true
                preciseShotsStacks = select(4, API.GetBuffInfo("player", buffs.PRECISE_SHOTS)) or 1
                preciseShotsEndTime = select(6, API.GetBuffInfo("player", buffs.PRECISE_SHOTS))
                API.PrintDebug("Precise Shots activated: " .. tostring(preciseShotsStacks) .. " stacks")
            end
            
            -- Track Trick Shots
            if spellID == buffs.TRICK_SHOTS then
                trickShotsActive = true
                trickShotsEndTime = GetTime() + TRICK_SHOTS_DURATION
                API.PrintDebug("Trick Shots activated")
            end
            
            -- Track Steady Focus
            if spellID == buffs.STEADY_FOCUS then
                steadyFocusActive = true
                steadyFocusEndTime = GetTime() + STEADY_FOCUS_DURATION
                API.PrintDebug("Steady Focus activated")
            end
            
            -- Track Volley
            if spellID == buffs.VOLLEY then
                volleyActive = true
                volleyEndTime = GetTime() + VOLLEY_DURATION
                API.PrintDebug("Volley activated")
            end
            
            -- Track Viper's Venom
            if spellID == buffs.VIPERS_VENOM then
                vipersVenomActive = true
                vipersVenomEndTime = GetTime() + VIPERS_VENOM_DURATION
                API.PrintDebug("Viper's Venom activated")
            end
            
            -- Track Eagletalon's True Focus
            if spellID == buffs.EAGLETALONS_TRUE_FOCUS then
                eagletalonsFire = true
                eagletalonsFireEndTime = GetTime() + EAGLETALON_DURATION
                API.PrintDebug("Eagletalon's True Focus activated")
            end
            
            -- Track Bulletstorm
            if spellID == buffs.BULLETSTORM then
                bulletstormActive = true
                bulletstormStacks = select(4, API.GetBuffInfo("player", buffs.BULLETSTORM)) or 1
                bulletstormEndTime = select(6, API.GetBuffInfo("player", buffs.BULLETSTORM))
                API.PrintDebug("Bulletstorm activated: " .. tostring(bulletstormStacks) .. " stacks")
            end
            
            -- Track Lethal Shots
            if spellID == buffs.LETHAL_SHOTS then
                lethalShotsActive = true
                lethalShotsStacks = select(4, API.GetBuffInfo("player", buffs.LETHAL_SHOTS)) or 1
                lethalShotsEndTime = select(6, API.GetBuffInfo("player", buffs.LETHAL_SHOTS))
                API.PrintDebug("Lethal Shots activated: " .. tostring(lethalShotsStacks) .. " stacks")
            end
            
            -- Track In The Rhythm
            if spellID == buffs.IN_THE_RHYTHM then
                inTheRhythmActive = true
                inTheRhythmStacks = select(4, API.GetBuffInfo("player", buffs.IN_THE_RHYTHM)) or 1
                inTheRhythmEndTime = select(6, API.GetBuffInfo("player", buffs.IN_THE_RHYTHM))
                API.PrintDebug("In The Rhythm activated: " .. tostring(inTheRhythmStacks) .. " stacks")
            end
            
            -- Track Bombardment
            if spellID == buffs.BOMBARDMENT then
                bombardmentActive = true
                bombardmentEndTime = GetTime() + BOMBARDMENT_DURATION
                API.PrintDebug("Bombardment activated")
            end
            
            -- Track Unerring Vision
            if spellID == buffs.UNERRING_VISION then
                unerringVisionActive = true
                unerringVisionStacks = select(4, API.GetBuffInfo("player", buffs.UNERRING_VISION)) or 1
                unerringVisionEndTime = select(6, API.GetBuffInfo("player", buffs.UNERRING_VISION))
                API.PrintDebug("Unerring Vision activated: " .. tostring(unerringVisionStacks) .. " stacks")
            end
            
            -- Track Razor Fragments
            if spellID == buffs.RAZOR_FRAGMENTS then
                razorFragments = true
                razorFragmentsStacks = select(4, API.GetBuffInfo("player", buffs.RAZOR_FRAGMENTS)) or 1
                razorFragmentsEndTime = select(6, API.GetBuffInfo("player", buffs.RAZOR_FRAGMENTS))
                API.PrintDebug("Razor Fragments activated: " .. tostring(razorFragmentsStacks) .. " stacks")
            end
            
            -- Track Latent Poison
            if spellID == buffs.LATENT_POISON then
                latentVenom = true
                latentVenomStacks = select(4, API.GetBuffInfo("player", buffs.LATENT_POISON)) or 1
                latentVenomEndTime = select(6, API.GetBuffInfo("player", buffs.LATENT_POISON))
                API.PrintDebug("Latent Poison activated: " .. tostring(latentVenomStacks) .. " stacks")
            end
            
            -- Track Deathly Precision
            if spellID == buffs.DEATHLY_PRECISION then
                deathlyPrecision = true
                deathlyPrecisionStacks = select(4, API.GetBuffInfo("player", buffs.DEATHLY_PRECISION)) or 1
                deathlyPrecisionEndTime = select(6, API.GetBuffInfo("player", buffs.DEATHLY_PRECISION))
                API.PrintDebug("Deathly Precision activated: " .. tostring(deathlyPrecisionStacks) .. " stacks")
            end
            
            -- Track Burning Wounds
            if spellID == buffs.BURNING_WOUNDS then
                burningWounds = true
                burningWoundsStacks = select(4, API.GetBuffInfo("player", buffs.BURNING_WOUNDS)) or 1
                burningWoundsEndTime = select(6, API.GetBuffInfo("player", buffs.BURNING_WOUNDS))
                API.PrintDebug("Burning Wounds activated: " .. tostring(burningWoundsStacks) .. " stacks")
            end
        end
        
        -- Track target specific debuffs
        if API.GetTargetGUID() == destGUID then
            -- Track Serpent Sting
            if spellID == debuffs.SERPENT_STING then
                serpentStingActive = true
                serpentStingEndTime = select(6, API.GetDebuffInfo("target", debuffs.SERPENT_STING))
                API.PrintDebug("Serpent Sting applied to target")
            end
            
            -- Track Hunter's Mark
            if spellID == debuffs.HUNTERS_MARK then
                API.PrintDebug("Hunter's Mark applied to target")
            end
        end
    end
    
    -- Track buff removals
    if eventType == "SPELL_AURA_REMOVED" then
        -- Track player buff removals
        if destGUID == API.GetPlayerGUID() then
            -- Track Trueshot
            if spellID == buffs.TRUESHOT then
                trueshotActive = false
                API.PrintDebug("Trueshot faded")
            end
            
            -- Track Lock and Load
            if spellID == buffs.LOCK_AND_LOAD then
                lockAndLoadActive = false
                lockAndLoadCharges = 0
                API.PrintDebug("Lock and Load consumed")
            end
            
            -- Track Precise Shots
            if spellID == buffs.PRECISE_SHOTS then
                preciseShots = false
                preciseShotsStacks = 0
                API.PrintDebug("Precise Shots consumed")
            end
            
            -- Track Trick Shots
            if spellID == buffs.TRICK_SHOTS then
                trickShotsActive = false
                API.PrintDebug("Trick Shots faded")
            end
            
            -- Track Steady Focus
            if spellID == buffs.STEADY_FOCUS then
                steadyFocusActive = false
                API.PrintDebug("Steady Focus faded")
            end
            
            -- Track Volley
            if spellID == buffs.VOLLEY then
                volleyActive = false
                API.PrintDebug("Volley faded")
            end
            
            -- Track Viper's Venom
            if spellID == buffs.VIPERS_VENOM then
                vipersVenomActive = false
                API.PrintDebug("Viper's Venom faded")
            end
            
            -- Track Eagletalon's True Focus
            if spellID == buffs.EAGLETALONS_TRUE_FOCUS then
                eagletalonsFire = false
                API.PrintDebug("Eagletalon's True Focus faded")
            end
            
            -- Track Bulletstorm
            if spellID == buffs.BULLETSTORM then
                bulletstormActive = false
                bulletstormStacks = 0
                API.PrintDebug("Bulletstorm faded")
            end
            
            -- Track Lethal Shots
            if spellID == buffs.LETHAL_SHOTS then
                lethalShotsActive = false
                lethalShotsStacks = 0
                API.PrintDebug("Lethal Shots faded")
            end
            
            -- Track In The Rhythm
            if spellID == buffs.IN_THE_RHYTHM then
                inTheRhythmActive = false
                inTheRhythmStacks = 0
                API.PrintDebug("In The Rhythm faded")
            end
            
            -- Track Bombardment
            if spellID == buffs.BOMBARDMENT then
                bombardmentActive = false
                API.PrintDebug("Bombardment faded")
            end
            
            -- Track Unerring Vision
            if spellID == buffs.UNERRING_VISION then
                unerringVisionActive = false
                unerringVisionStacks = 0
                API.PrintDebug("Unerring Vision faded")
            end
            
            -- Track Razor Fragments
            if spellID == buffs.RAZOR_FRAGMENTS then
                razorFragments = false
                razorFragmentsStacks = 0
                API.PrintDebug("Razor Fragments faded")
            end
            
            -- Track Latent Poison
            if spellID == buffs.LATENT_POISON then
                latentVenom = false
                latentVenomStacks = 0
                API.PrintDebug("Latent Poison faded")
            end
            
            -- Track Deathly Precision
            if spellID == buffs.DEATHLY_PRECISION then
                deathlyPrecision = false
                deathlyPrecisionStacks = 0
                API.PrintDebug("Deathly Precision faded")
            end
            
            -- Track Burning Wounds
            if spellID == buffs.BURNING_WOUNDS then
                burningWounds = false
                burningWoundsStacks = 0
                API.PrintDebug("Burning Wounds faded")
            end
        end
        
        -- Track target specific debuffs
        if API.GetTargetGUID() == destGUID then
            -- Track Serpent Sting
            if spellID == debuffs.SERPENT_STING then
                serpentStingActive = false
                API.PrintDebug("Serpent Sting faded from target")
            end
            
            -- Track Hunter's Mark
            if spellID == debuffs.HUNTERS_MARK then
                API.PrintDebug("Hunter's Mark removed from target")
            end
        end
    end
    
    -- Track buff stacks
    if eventType == "SPELL_AURA_APPLIED_DOSE" then
        if destGUID == API.GetPlayerGUID() then
            -- Track Lock and Load charges
            if spellID == buffs.LOCK_AND_LOAD then
                lockAndLoadCharges = select(4, API.GetBuffInfo("player", buffs.LOCK_AND_LOAD)) or 0
                API.PrintDebug("Lock and Load charges: " .. tostring(lockAndLoadCharges))
            end
            
            -- Track Precise Shots stacks
            if spellID == buffs.PRECISE_SHOTS then
                preciseShotsStacks = select(4, API.GetBuffInfo("player", buffs.PRECISE_SHOTS)) or 0
                API.PrintDebug("Precise Shots stacks: " .. tostring(preciseShotsStacks))
            end
            
            -- Track Bulletstorm stacks
            if spellID == buffs.BULLETSTORM then
                bulletstormStacks = select(4, API.GetBuffInfo("player", buffs.BULLETSTORM)) or 0
                API.PrintDebug("Bulletstorm stacks: " .. tostring(bulletstormStacks))
            end
            
            -- Track Lethal Shots stacks
            if spellID == buffs.LETHAL_SHOTS then
                lethalShotsStacks = select(4, API.GetBuffInfo("player", buffs.LETHAL_SHOTS)) or 0
                API.PrintDebug("Lethal Shots stacks: " .. tostring(lethalShotsStacks))
            end
            
            -- Track In The Rhythm stacks
            if spellID == buffs.IN_THE_RHYTHM then
                inTheRhythmStacks = select(4, API.GetBuffInfo("player", buffs.IN_THE_RHYTHM)) or 0
                API.PrintDebug("In The Rhythm stacks: " .. tostring(inTheRhythmStacks))
            end
            
            -- Track Unerring Vision stacks
            if spellID == buffs.UNERRING_VISION then
                unerringVisionStacks = select(4, API.GetBuffInfo("player", buffs.UNERRING_VISION)) or 0
                API.PrintDebug("Unerring Vision stacks: " .. tostring(unerringVisionStacks))
            end
            
            -- Track Razor Fragments stacks
            if spellID == buffs.RAZOR_FRAGMENTS then
                razorFragmentsStacks = select(4, API.GetBuffInfo("player", buffs.RAZOR_FRAGMENTS)) or 0
                API.PrintDebug("Razor Fragments stacks: " .. tostring(razorFragmentsStacks))
            end
            
            -- Track Latent Poison stacks
            if spellID == buffs.LATENT_POISON then
                latentVenomStacks = select(4, API.GetBuffInfo("player", buffs.LATENT_POISON)) or 0
                API.PrintDebug("Latent Poison stacks: " .. tostring(latentVenomStacks))
            end
            
            -- Track Deathly Precision stacks
            if spellID == buffs.DEATHLY_PRECISION then
                deathlyPrecisionStacks = select(4, API.GetBuffInfo("player", buffs.DEATHLY_PRECISION)) or 0
                API.PrintDebug("Deathly Precision stacks: " .. tostring(deathlyPrecisionStacks))
            end
            
            -- Track Burning Wounds stacks
            if spellID == buffs.BURNING_WOUNDS then
                burningWoundsStacks = select(4, API.GetBuffInfo("player", buffs.BURNING_WOUNDS)) or 0
                API.PrintDebug("Burning Wounds stacks: " .. tostring(burningWoundsStacks))
            end
        end
    end
    
    -- Track spell casts
    if eventType == "SPELL_CAST_SUCCESS" then
        if spellID == spells.TRUESHOT then
            trueshotActive = true
            trueshotEndTime = GetTime() + TRUESHOT_DURATION
            API.PrintDebug("Trueshot cast")
        elseif spellID == spells.RAPID_FIRE then
            API.PrintDebug("Rapid Fire cast")
        elseif spellID == spells.AIMED_SHOT then
            API.PrintDebug("Aimed Shot cast")
        elseif spellID == spells.VOLLEY then
            volleyActive = true
            volleyEndTime = GetTime() + VOLLEY_DURATION
            API.PrintDebug("Volley cast")
        elseif spellID == spells.STEADY_SHOT then
            -- Track Steady Shot for Steady Focus buff
            if talents.hasSteadyFocus then
                -- Steady Focus requires 2 Steady Shots casts
                -- This would need to track consecutive casts
                API.PrintDebug("Steady Shot cast")
            end
        elseif spellID == spells.MULTI_SHOT then
            -- Check if Multi-Shot will apply Trick Shots
            if talents.hasTrickShots and currentAoETargets >= 3 then
                trickShotsActive = true
                trickShotsEndTime = GetTime() + TRICK_SHOTS_DURATION
                API.PrintDebug("Multi-Shot cast with Trick Shots")
            else
                API.PrintDebug("Multi-Shot cast")
            end
        elseif spellID == spells.ARCANE_SHOT then
            -- Check if Arcane Shot consumed Precise Shots
            if preciseShotsStacks > 0 then
                preciseShotsStacks = preciseShotsStacks - 1
                if preciseShotsStacks <= 0 then
                    preciseShots = false
                }
                API.PrintDebug("Arcane Shot consumed Precise Shots, stacks left: " .. tostring(preciseShotsStacks))
            else
                API.PrintDebug("Arcane Shot cast")
            end
        elseif spellID == spells.CHIMAERA_SHOT then
            chimaeraShotActive = true
            chimaeraShotEndTime = GetTime() + CHIMAERA_SHOT_DURATION
            API.PrintDebug("Chimaera Shot cast")
        elseif spellID == spells.SERPENT_STING then
            serpentStingActive = true
            serpentStingEndTime = GetTime() + SERPENT_STING_DURATION
            API.PrintDebug("Serpent Sting cast")
        elseif spellID == spells.DEATH_CHAKRAM then
            deathchakramsActive = true
            API.PrintDebug("Death Chakram cast")
        elseif spellID == spells.WAILING_ARROW then
            API.PrintDebug("Wailing Arrow cast")
        elseif spellID == spells.EXPLOSIVE_SHOT then
            API.PrintDebug("Explosive Shot cast")
        elseif spellID == spells.KILL_SHOT then
            API.PrintDebug("Kill Shot cast")
        end
    end
    
    return true
end

-- Main rotation function
function Marksmanship:RunRotation()
    -- Check if we should be running Marksmanship Hunter logic
    if API.GetActiveSpecID() ~= MARKSMANSHIP_SPEC_ID then
        return false
    end
    
    -- Skip rotation if player is casting or channeling
    if aimingShotCasting or rapidFireActive then
        return false
    end
    
    -- Get settings
    local settings = ConfigRegistry:GetSettings("MarksmanshipHunter")
    
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
    if settings.rotationSettings.usePetActive and not petActive and not talents.hasLoneWolf then
        if API.CanCast(spells.CALL_PET_1) then
            API.CastSpell(spells.CALL_PET_1)
            return true
        end
    end
    
    -- Heal pet if needed
    if petActive and settings.defensiveSettings.useMendPet and API.GetPetHealthPercent() <= settings.defensiveSettings.mendPetThreshold and 
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
function Marksmanship:HandleInterrupts()
    -- Only attempt to interrupt if in range
    if inRange and API.CanCast(spells.COUNTER_SHOT) and API.TargetIsSpellCastable() then
        API.CastSpell(spells.COUNTER_SHOT)
        return true
    end
    
    return false
end

-- Handle defensive abilities
function Marksmanship:HandleDefensives(settings)
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
function Marksmanship:HandleCooldowns(settings)
    -- Skip if not in combat
    if not API.IsInCombat() then
        return false
    end
    
    -- Use Trueshot
    if trueshot and
       settings.cooldownSettings.useTrueshot and
       settings.abilityControls.trueshot.enabled and
       not trueshotActive and
       API.CanCast(spells.TRUESHOT) then
        
        -- Check if we should only use during burst
        if not settings.abilityControls.trueshot.useDuringBurstOnly or burstModeActive then
            -- Check additional requirements like Lock and Load or Focus amount
            local canUseTrueshot = true
            
            if settings.abilityControls.trueshot.requireLockAndLoad and not lockAndLoadActive then
                canUseTrueshot = false
            end
            
            if settings.abilityControls.trueshot.requireFocusAmount > currentFocus then
                canUseTrueshot = false
            end
            
            if canUseTrueshot then
                API.CastSpell(spells.TRUESHOT)
                return true
            end
        end
    end
    
    -- Use Volley
    if volley and
       settings.cooldownSettings.useVolley and
       not volleyActive and
       currentAoETargets >= settings.cooldownSettings.volleyMinTargets and
       API.CanCast(spells.VOLLEY) then
        API.CastSpellAtCursor(spells.VOLLEY)
        return true
    end
    
    -- Use Explosive Shot
    if talents.hasExplosiveShot and
       settings.cooldownSettings.useExplosiveShot and
       currentAoETargets >= settings.cooldownSettings.explosiveShotMinTargets and
       API.CanCast(spells.EXPLOSIVE_SHOT) then
        API.CastSpellAtCursor(spells.EXPLOSIVE_SHOT)
        return true
    end
    
    -- Use Wailing Arrow
    if wailingArrow and
       settings.cooldownSettings.useWailingArrow and
       API.CanCast(spells.WAILING_ARROW) then
        API.CastSpell(spells.WAILING_ARROW)
        return true
    end
    
    -- Use Death Chakram
    if deathChakram and
       settings.cooldownSettings.useDeathChakram and
       API.CanCast(spells.DEATH_CHAKRAM) then
        API.CastSpell(spells.DEATH_CHAKRAM)
        return true
    end
    
    return false
end

-- Handle AoE rotation
function Marksmanship:HandleAoERotation(settings)
    -- Apply Serpent Sting if we have Hydra's Bite or with Viper's Venom proc
    if serpentSting and 
       settings.abilitySettings.useSerpentSting and
       (vipersVenomActive or talents.hasHydrasBite) and
       API.CanCast(spells.SERPENT_STING) then
        API.CastSpell(spells.SERPENT_STING)
        return true
    end
    
    -- Apply Trick Shots with Multi-Shot
    if multiShot and
       not trickShotsActive and
       currentAoETargets >= 3 and
       API.CanCast(spells.MULTI_SHOT) then
        API.CastSpell(spells.MULTI_SHOT)
        return true
    end
    
    -- Use Aimed Shot with Lock and Load during AoE
    if aimingShot and
       settings.abilitySettings.useAimedShot and
       settings.abilityControls.aimedShot.enabled and
       lockAndLoadActive and
       API.CanCast(spells.AIMED_SHOT) then
        API.CastSpell(spells.AIMED_SHOT)
        return true
    end
    
    -- Use Rapid Fire during AoE with Trick Shots
    if rapidFire and
       trickShotsActive and
       settings.abilityControls.rapidFire.enabled and
       (settings.rotationSettings.rapidFireStrategy == "On Cooldown" ||
        settings.rotationSettings.rapidFireStrategy == "With Trick Shots") and
       API.CanCast(spells.RAPID_FIRE) then
        API.CastSpell(spells.RAPID_FIRE)
        return true
    end
    
    -- Use Arcane Shot with Precise Shots proc
    if arcaneShot and
       settings.abilitySettings.usePreciseShots and
       preciseShots and
       API.CanCast(spells.ARCANE_SHOT) then
        API.CastSpell(spells.ARCANE_SHOT)
        return true
    end
    
    -- Use Multi-Shot to spend focus and maintain Trick Shots
    if multiShot and
       currentFocus >= 40 and
       API.CanCast(spells.MULTI_SHOT) then
        API.CastSpell(spells.MULTI_SHOT)
        return true
    end
    
    -- Use Chimaera Shot in AoE for focus and cleave
    if talents.hasChimaeraShot and
       settings.abilitySettings.useChimaeraShot and
       API.CanCast(spells.CHIMAERA_SHOT) then
       
        local shouldUse = false
        
        if settings.abilitySettings.chimaeraUsageStrategy == "On Cooldown" then
            shouldUse = true
        elseif settings.abilitySettings.chimaeraUsageStrategy == "For Focus Generation" and currentFocus < 50 then
            shouldUse = true
        elseif settings.abilitySettings.chimaeraUsageStrategy == "With Precise Shots" and preciseShots then
            shouldUse = true
        end
        
        if shouldUse then
            API.CastSpell(spells.CHIMAERA_SHOT)
            return true
        end
    end
    
    -- Use Steady Shot if we're very low on Focus
    if settings.rotationSettings.steadyShotStrategy == "Focus Emergency" and
       currentFocus <= settings.rotationSettings.steadyShotEmergencyThreshold and
       API.CanCast(spells.STEADY_SHOT) then
        API.CastSpell(spells.STEADY_SHOT)
        return true
    end
    
    -- Maintain Steady Focus if talented
    if talents.hasSteadyFocus and
       settings.rotationSettings.steadyShotStrategy == "Buff Maintenance" and
       not steadyFocusActive and
       API.CanCast(spells.STEADY_SHOT) then
        API.CastSpell(spells.STEADY_SHOT)
        return true
    end
    
    return false
end

-- Handle Single Target rotation
function Marksmanship:HandleSingleTargetRotation(settings)
    -- Use Kill Shot if available
    if killShot and
       killShotAvailable and
       API.CanCast(spells.KILL_SHOT) then
        API.CastSpell(spells.KILL_SHOT)
        return true
    end
    
    -- Maintain Serpent Sting if needed
    if serpentSting and
       settings.abilitySettings.useSerpentSting and
       (not serpentStingActive or
        serpentStingEndTime - GetTime() < settings.abilitySettings.serpentStingRefreshThreshold) and
       API.CanCast(spells.SERPENT_STING) then
        API.CastSpell(spells.SERPENT_STING)
        return true
    end
    
    -- Use Aimed Shot with Lock and Load or enough focus
    if aimingShot and
       settings.abilitySettings.useAimedShot and
       settings.abilityControls.aimedShot.enabled and
       (lockAndLoadActive || currentFocus >= settings.abilityControls.aimedShot.minFocus) and
       API.CanCast(spells.AIMED_SHOT) then
        API.CastSpell(spells.AIMED_SHOT)
        return true
    end
    
    -- Use Arcane Shot with Precise Shots proc
    if arcaneShot and
       settings.abilitySettings.usePreciseShots and
       preciseShots and
       API.CanCast(spells.ARCANE_SHOT) then
        API.CastSpell(spells.ARCANE_SHOT)
        return true
    end
    
    -- Use Rapid Fire on cooldown or with Trueshot
    if rapidFire and
       settings.abilityControls.rapidFire.enabled and
       (settings.rotationSettings.rapidFireStrategy == "On Cooldown" ||
        (settings.rotationSettings.rapidFireStrategy == "Save for Trueshot" && trueshotActive)) and
       API.CanCast(spells.RAPID_FIRE) then
        API.CastSpell(spells.RAPID_FIRE)
        return true
    end
    
    -- Use Chimaera Shot
    if talents.hasChimaeraShot and
       settings.abilitySettings.useChimaeraShot and
       API.CanCast(spells.CHIMAERA_SHOT) then
       
        local shouldUse = false
        
        if settings.abilitySettings.chimaeraUsageStrategy == "On Cooldown" then
            shouldUse = true
        elseif settings.abilitySettings.chimaeraUsageStrategy == "For Focus Generation" and currentFocus < 50 then
            shouldUse = true
        elseif settings.abilitySettings.chimaeraUsageStrategy == "With Precise Shots" and preciseShots then
            shouldUse = true
        end
        
        if shouldUse then
            API.CastSpell(spells.CHIMAERA_SHOT)
            return true
        end
    end
    
    -- Use Arcane Shot to dump focus
    if arcaneShot and
       currentFocus >= 50 and
       (not settings.rotationSettings.focusPooling ||
        currentFocus > settings.rotationSettings.focusPoolingThreshold) and
       API.CanCast(spells.ARCANE_SHOT) then
        API.CastSpell(spells.ARCANE_SHOT)
        return true
    end
    
    -- Use Steady Shot if we're low on Focus
    if settings.rotationSettings.steadyShotStrategy == "Focus Emergency" and
       currentFocus <= settings.rotationSettings.steadyShotEmergencyThreshold and
       API.CanCast(spells.STEADY_SHOT) then
        API.CastSpell(spells.STEADY_SHOT)
        return true
    end
    
    -- Maintain Steady Focus if talented
    if talents.hasSteadyFocus and
       settings.rotationSettings.steadyShotStrategy == "Buff Maintenance" and
       not steadyFocusActive and
       API.CanCast(spells.STEADY_SHOT) then
        API.CastSpell(spells.STEADY_SHOT)
        return true
    end
    
    -- Use Steady Shot as filler
    if settings.rotationSettings.steadyShotStrategy == "On Cooldown" and
       API.CanCast(spells.STEADY_SHOT) then
        API.CastSpell(spells.STEADY_SHOT)
        return true
    end
    
    return false
end

-- Handle specialization change
function Marksmanship:OnSpecializationChanged()
    -- Update talent information
    self:UpdateTalentInfo()
    
    -- Reset state variables
    nextCastOverride = nil
    burstModeActive = false
    currentAoETargets = 0
    currentFocus = 0
    maxFocus = 100
    trueshotActive = false
    trueshotEndTime = 0
    lockAndLoadActive = false
    lockAndLoadEndTime = 0
    lockAndLoadCharges = 0
    preciseShots = false
    preciseShotsStacks = 0
    preciseShotsEndTime = 0
    trickShotsActive = false
    trickShotsEndTime = 0
    steadyFocusActive = false
    steadyFocusEndTime = 0
    volleyActive = false
    volleyEndTime = 0
    deathchakramsActive = false
    vipersVenomActive = false
    vipersVenomEndTime = 0
    razorFragments = false
    razorFragmentsStacks = 0
    razorFragmentsEndTime = 0
    salvoActive = false
    eagletalonsFire = false
    eagletalonsFireEndTime = 0
    bulletstormActive = false
    bulletstormStacks = 0
    bulletstormEndTime = 0
    serpentSting = false
    serpentStingActive = false
    serpentStingEndTime = 0
    lethalShotsActive = false
    lethalShotsStacks = 0
    lethalShotsEndTime = 0
    inTheRhythmActive = false
    inTheRhythmStacks = 0
    inTheRhythmEndTime = 0
    unerringVisionActive = false
    unerringVisionStacks = 0
    unerringVisionEndTime = 0
    petActive = false
    rapidFireActive = false
    rapidFireEndTime = 0
    rapidFireCastFinishTime = 0
    aimingShot = false
    aimingShotCastFinishTime = 0
    windrunnersFire = false
    killShot = false
    killShotAvailable = false
    multiShot = false
    arcaneShot = false
    rapidFire = false
    aimingShotCasting = false
    trueshot = false
    volley = false
    deathChakram = false
    wailingArrow = false
    salvo = false
    inRange = false
    chimaeraShotActive = false
    chimaeraShotEndTime = 0
    bombardmentActive = false
    bombardmentEndTime = 0
    latentVenom = false
    latentVenomStacks = 0
    latentVenomEndTime = 0
    deathlyPrecision = false
    deathlyPrecisionStacks = 0
    deathlyPrecisionEndTime = 0
    burningWounds = false
    burningWoundsStacks = 0
    burningWoundsEndTime = 0
    huntsmansKnowledge = false
    incomingKillingShotWindow = false
    sentryShot = false
    inTheRythm = false
    surgeOfAgility = false
    visionOfVengeance = false
    serpentstalkersTrickery = false
    chimaericFire = false
    
    petActive = API.HasActivePet()
    
    API.PrintDebug("Marksmanship Hunter state reset on spec change")
    
    return true
end

-- Return the module for loading
return Marksmanship