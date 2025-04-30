------------------------------------------
-- WindrunnerRotations - Hunter Class Module
-- Author: VortexQ8
-- The War Within Season 2
------------------------------------------

local addonName, WR = ...
local HunterModule = {}
WR.Hunter = HunterModule

-- Dependencies
local API = WR.API
local ConfigRegistry = WR.ConfigRegistry
local RotationManager = WR.RotationManager
local ErrorHandler = WR.ErrorHandler
local CombatAnalysis = WR.CombatAnalysis
local AntiDetectionSystem = WR.AntiDetectionSystem
local PvPManager = WR.PvPManager

-- Hunter constants
local CLASS_ID = 3 -- Hunter class ID
local SPEC_BEAST_MASTERY = 253
local SPEC_MARKSMANSHIP = 254
local SPEC_SURVIVAL = 255

-- Current player data
local playerSpec = 0
local isEnabled = true
local inCombat = false

-- Spell IDs for Beast Mastery Hunter (The War Within, Season 2)
local BM_SPELLS = {
    -- Core abilities
    KILL_COMMAND = 34026,
    COBRA_SHOT = 193455,
    BARBED_SHOT = 217200,
    BESTIAL_WRATH = 19574,
    ASPECT_OF_THE_WILD = 193530,
    MULTISHOT = 2643,
    KILL_SHOT = 53351,
    CONCUSSIVE_SHOT = 5116,
    INTIMIDATION = 19577,
    BEAST_CLEAVE = 115939,
    
    -- Defensive & utility
    ASPECT_OF_THE_TURTLE = 186265,
    EXHILARATION = 109304,
    FEIGN_DEATH = 5384,
    DISENGAGE = 781,
    MISDIRECTION = 34477,
    ASPECT_OF_THE_CHEETAH = 186257,
    FLARE = 1543,
    FREEZING_TRAP = 187650,
    TAR_TRAP = 187698,
    TRANQUILIZING_SHOT = 19801,
    
    -- Talents
    BLOODSHED = 321530,
    SPITTING_COBRA = 194407,
    STAMPEDE = 201430,
    CALL_OF_THE_WILD = 359844,
    DIRE_BEAST = 120679,
    BARRAGE = 120360,
    A_MURDER_OF_CROWS = 131894,
    BINDING_SHOT = 109248,
    WILD_CALL = 185789,
    
    -- Season 2 Abilities
    WAILING_ARROW = 392060, -- New in TWW Season 2
    FOCUSED_MAYHEM = 430113, -- New in TWW Season 2
    KILLER_INSTINCT = 273887, -- Enhanced in TWW Season 2
    PACK_TACTICS = 415421, -- New in TWW Season 2
    LETHAL_SHOTS = 260393, -- Enhanced in TWW Season 2
    PACK_MENTALITY = 386380, -- New in TWW Season 2
    FURY_OF_THE_FLOCK = 248443, -- New in TWW Season 2
    BLOODY_FRENZY = 431922, -- New in TWW Season 2
    VICIOUS_COMMAND = 386881, -- New in TWW Season 2
    KILL_CLEAVE = 378015, -- New in TWW Season 2
    COORDINATED_KILL = 385739, -- New in TWW Season 2
    KILLING_FRENZY = 386578, -- New in TWW Season 2
    DIRE_PACK = 378740, -- New in TWW Season 2
    THRILL_OF_THE_HUNT = 257944, -- Enhanced in TWW Season 2
    WILD_INSTINCTS = 378442, -- New in TWW Season 2
    
    -- Pet summons
    CALL_PET_1 = 883,
    CALL_PET_2 = 83242,
    CALL_PET_3 = 83243,
    CALL_PET_4 = 83244,
    CALL_PET_5 = 83245,
    DISMISS_PET = 2641,
    REVIVE_PET = 982,
    
    -- Misc
    MEND_PET = 136,
    HUNTERS_MARK = 257284,
    EAGLE_EYE = 6197,
    FEED_PET = 6991,
    TAME_BEAST = 1515
}

-- Spell IDs for Marksmanship Hunter (The War Within, Season 2)
local MM_SPELLS = {
    -- Core abilities
    AIMED_SHOT = 19434,
    ARCANE_SHOT = 185358,
    RAPID_FIRE = 257044,
    STEADY_SHOT = 56641,
    TRUESHOT = 288613,
    CHIMAERA_SHOT = 342049,
    BURSTING_SHOT = 186387,
    MULTISHOT = 257620,
    KILL_SHOT = 53351,
    VOLLEY = 260243,
    
    -- Defensive & utility
    ASPECT_OF_THE_TURTLE = 186265,
    EXHILARATION = 109304,
    FEIGN_DEATH = 5384,
    DISENGAGE = 781,
    MISDIRECTION = 34477,
    ASPECT_OF_THE_CHEETAH = 186257,
    FLARE = 1543,
    FREEZING_TRAP = 187650,
    TAR_TRAP = 187698,
    TRANQUILIZING_SHOT = 19801,
    
    -- Talents
    BARRAGE = 120360,
    A_MURDER_OF_CROWS = 131894,
    EXPLOSIVE_SHOT = 212431,
    SERPENT_STING = 271788,
    BINDING_SHOT = 109248,
    PRECISE_SHOTS = 260240,
    TRICK_SHOTS = 257621,
    SALVO = 400456,
    STEEL_TRAP = 162488,
    WAILING_ARROW = 392060,
    
    -- Season 2 Abilities
    DEATHBLOW = 378745, -- New in TWW Season 2
    RAZOR_FRAGMENTS = 384790, -- New in TWW Season 2
    EAGLETALON_TRUE = 389831, -- New in TWW Season 2
    TRICK_SHOTS_PLUS = 424567, -- New in TWW Season 2
    BULLETSTORM = 389017, -- New in TWW Season 2
    WINDRUNNERS_GUIDANCE = 378888, -- New in TWW Season 2
    DANCE_OF_DEATH = 378215, -- New in TWW Season 2
    UNERRING_VISION = 274446, -- Enhanced in TWW Season 2
    SHREWDNESS = 456826, -- New in TWW Season 2
    LEGACY_OF_THE_WINDRUNNERS = 394322, -- New in TWW Season 2
    AIMED_PRECISION = 383476, -- New in TWW Season 2
    BLAST_RADIUS = 389644, -- New in TWW Season 2
    LOCK_AND_LOAD = 194595, -- Enhanced in TWW Season 2
    OVERWATCH = 436713, -- New in TWW Season 2
    READINESS = 386719, -- New in TWW Season 2
    
    -- Pet summons
    CALL_PET_1 = 883,
    CALL_PET_2 = 83242,
    CALL_PET_3 = 83243,
    CALL_PET_4 = 83244,
    CALL_PET_5 = 83245,
    DISMISS_PET = 2641,
    REVIVE_PET = 982,
    
    -- Misc
    MEND_PET = 136,
    HUNTERS_MARK = 257284,
    EAGLE_EYE = 6197,
    FEED_PET = 6991,
    TAME_BEAST = 1515
}

-- Spell IDs for Survival Hunter (The War Within, Season 2)
local SV_SPELLS = {
    -- Core abilities
    RAPTOR_STRIKE = 186270,
    KILL_COMMAND = 259489,
    CARVE = 187708,
    WILDFIRE_BOMB = 259495,
    COORDINATED_ASSAULT = 266779,
    FLANKING_STRIKE = 269751,
    HARPOON = 190925,
    MONGOOSE_BITE = 259387,
    CHAKRAMS = 259391,
    BUTCHERY = 212436,
    
    -- Defensive & utility
    ASPECT_OF_THE_TURTLE = 186265,
    EXHILARATION = 109304,
    FEIGN_DEATH = 5384,
    DISENGAGE = 781,
    MISDIRECTION = 34477,
    ASPECT_OF_THE_CHEETAH = 186257,
    FLARE = 1543,
    FREEZING_TRAP = 187650,
    TAR_TRAP = 187698,
    TRANQUILIZING_SHOT = 19801,
    
    -- Talents
    STEEL_TRAP = 162488,
    A_MURDER_OF_CROWS = 131894,
    WILDFIRE_INFUSION = 271014,
    BIRDS_OF_PREY = 260331,
    BINDING_SHOT = 109248,
    BLOODSEEKER = 260248,
    GUERRILLA_TACTICS = 264332,
    SPEARHEAD = 360966,
    FURY_OF_THE_EAGLE = 203415,
    
    -- Season 2 Abilities
    LUNGE = 424270, -- New in TWW Season 2
    RANGER_AND_TRACKER = 384948, -- New in TWW Season 2
    EMPOWERED_RELEASE = 353265, -- New in TWW Season 2
    KILLING_FRENZY = 386578, -- New in TWW Season 2
    FEROCITY_OF_THE_WARSONG = 386804, -- New in TWW Season 2
    COORDINATED_ONSLAUGHT = 385739, -- New in TWW Season 2
    TERMS_OF_ENGAGEMENT = 265895, -- Enhanced in TWW Season 2
    EXPLOSIVE_TRAP = 13813, -- Enhanced in TWW Season 2
    DEATH_CHAKRAM = 375891, -- New in TWW Season 2
    SWEEPING_SPEAR = 427964, -- New in TWW Season 2
    WILD_INSTINCTS = 378442, -- New in TWW Season 2
    HUNTING_COMPANION = 384799, -- New in TWW Season 2
    BOMBARDIER = 389880, -- New in TWW Season 2
    BORN_TO_BE_WILD = 266921, -- Enhanced in TWW Season 2
    ENFEEBLING_POISON = 394961, -- New in TWW Season 2
    
    -- Pet summons
    CALL_PET_1 = 883,
    CALL_PET_2 = 83242,
    CALL_PET_3 = 83243,
    CALL_PET_4 = 83244,
    CALL_PET_5 = 83245,
    DISMISS_PET = 2641,
    REVIVE_PET = 982,
    
    -- Misc
    MEND_PET = 136,
    HUNTERS_MARK = 257284,
    EAGLE_EYE = 6197,
    FEED_PET = 6991,
    TAME_BEAST = 1515
}

-- Important buffs to track
local BUFFS = {
    BESTIAL_WRATH = 19574,
    ASPECT_OF_THE_WILD = 193530,
    BEAST_CLEAVE = 268877,
    FRENZY = 272790,
    TRUESHOT = 288613,
    PRECISE_SHOTS = 260242,
    TRICK_SHOTS = 257622,
    LOCK_AND_LOAD = 194594,
    COORDINATED_ASSAULT = 266779,
    MONGOOSE_FURY = 259388,
    TERMS_OF_ENGAGEMENT = 265898,
    ASPECT_OF_THE_TURTLE = 186265,
    ASPECT_OF_THE_CHEETAH = 186257,
    POSTHASTE = 118922,
    VIPERS_VENOM = 268552,
    TIP_OF_THE_SPEAR = 260286,
    LONE_WOLF = 155228
}

-- Important debuffs to track
local DEBUFFS = {
    HUNTERS_MARK = 257284,
    SERPENT_STING = 271788,
    CONCUSSIVE_SHOT = 5116,
    BLOODSEEKER = 259277,
    LATENT_POISON = 273286,
    PHEROMONE_BOMB = 270332,
    SHRAPNEL_BOMB = 270339,
    VOLATILE_BOMB = 271049,
    INTERNAL_BLEEDING = 270343,
    BINDING_SHOT = 117526,
    FREEZING_TRAP = 3355,
    TAR_TRAP = 135299
}

-- Initialize the Hunter module
function HunterModule:Initialize()
    -- Register settings
    self:RegisterSettings()
    
    -- Register events
    self:RegisterEvents()
    
    -- Register rotations
    self:RegisterRotations()
    
    API.PrintDebug("Hunter module initialized")
    return true
end

-- Register settings
function HunterModule:RegisterSettings()
    ConfigRegistry:RegisterSettings("Hunter", {
        generalSettings = {
            enabled = {
                displayName = "Enable Hunter Module",
                description = "Enable the Hunter module for all specs",
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
            autoCallPet = {
                displayName = "Auto Call Pet",
                description = "Automatically call your pet if missing",
                type = "toggle",
                default = true
            },
            preferredPet = {
                displayName = "Preferred Pet",
                description = "Which pet slot to call",
                type = "dropdown",
                options = {"Pet 1", "Pet 2", "Pet 3", "Pet 4", "Pet 5"},
                default = "Pet 1"
            },
            mendPetThreshold = {
                displayName = "Mend Pet Threshold",
                description = "Pet health percentage to use Mend Pet",
                type = "slider",
                min = 20,
                max = 80,
                step = 5,
                default = 50
            },
            useAspectOfTheTurtle = {
                displayName = "Use Aspect of the Turtle",
                description = "Automatically use Aspect of the Turtle at low health",
                type = "toggle",
                default = true
            },
            turtleThreshold = {
                displayName = "Turtle Health Threshold",
                description = "Health percentage to use Aspect of the Turtle",
                type = "slider",
                min = 10,
                max = 40,
                step = 5,
                default = 20
            }
        },
        beastMasterySettings = {
            -- Core settings
            useBarrage = {
                displayName = "Use Barrage",
                description = "Use Barrage for AoE",
                type = "toggle",
                default = true
            },
            barrageThreshold = {
                displayName = "Barrage Threshold",
                description = "Minimum targets to use Barrage",
                type = "slider",
                min = 2,
                max = 5,
                step = 1,
                default = 3
            },
            useBestialWrath = {
                displayName = "Use Bestial Wrath",
                description = "Use Bestial Wrath on cooldown",
                type = "toggle",
                default = true
            },
            useAspectOfTheWild = {
                displayName = "Use Aspect of the Wild",
                description = "Use Aspect of the Wild on cooldown",
                type = "toggle",
                default = true
            },
            syncBWandAotW = {
                displayName = "Sync BW and Aspect of the Wild",
                description = "Try to use Bestial Wrath and Aspect of the Wild together",
                type = "toggle",
                default = true
            },
            useDireBeast = {
                displayName = "Use Dire Beast",
                description = "Use Dire Beast on cooldown",
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
            },
            
            -- Season 2 ability settings
            useWailingArrow = {
                displayName = "Use Wailing Arrow (TWW S2)",
                description = "Use Wailing Arrow for silence and damage",
                type = "toggle",
                default = true
            },
            useFocusedMayhem = {
                displayName = "Use Focused Mayhem (TWW S2)",
                description = "Use Focused Mayhem for enhanced wild spirits",
                type = "toggle",
                default = true
            },
            useKillerInstinct = {
                displayName = "Use Killer Instinct (TWW S2)",
                description = "Use Killer Instinct for enhanced Kill Command",
                type = "toggle",
                default = true
            },
            usePackTactics = {
                displayName = "Use Pack Tactics (TWW S2)",
                description = "Use Pack Tactics for pet abilities",
                type = "toggle",
                default = true
            },
            useLethalShots = {
                displayName = "Use Lethal Shots (TWW S2)",
                description = "Use Lethal Shots for Kill Shot reset chance",
                type = "toggle",
                default = true
            },
            usePackMentality = {
                displayName = "Use Pack Mentality (TWW S2)",
                description = "Use Pack Mentality for enhanced Bestial Wrath",
                type = "toggle",
                default = true
            },
            useFuryOfTheFlock = {
                displayName = "Use Fury of the Flock (TWW S2)",
                description = "Use Fury of the Flock for AoE damage",
                type = "toggle",
                default = true
            },
            useBloodyFrenzy = {
                displayName = "Use Bloody Frenzy (TWW S2)",
                description = "Use Bloody Frenzy for enhanced Bloodshed",
                type = "toggle",
                default = true
            },
            useViciousCommand = {
                displayName = "Use Vicious Command (TWW S2)",
                description = "Use Vicious Command for enhanced Kill Command",
                type = "toggle",
                default = true
            },
            useKillCleave = {
                displayName = "Use Kill Cleave (TWW S2)",
                description = "Use Kill Cleave for cleave damage",
                type = "toggle",
                default = true
            },
            useCoordinatedKill = {
                displayName = "Use Coordinated Kill (TWW S2)",
                description = "Use Coordinated Kill for enhanced pet abilities",
                type = "toggle",
                default = true
            },
            beastialWrathMode = {
                displayName = "Bestial Wrath Usage (TWW S2)",
                description = "How to optimize Bestial Wrath",
                type = "dropdown",
                options = {
                    "With Aspect of the Wild", 
                    "On Cooldown", 
                    "With Kill Command ready", 
                    "With Barbed Shot stacks"
                },
                default = "With Aspect of the Wild"
            },
            wildInstinctsMode = {
                displayName = "Wild Instincts Usage (TWW S2)",
                description = "How to optimize Wild Instincts",
                type = "dropdown",
                options = {
                    "Always for Focus", 
                    "Only when below 50 Focus", 
                    "Only during Bestial Wrath", 
                    "Manual Only"
                },
                default = "Always for Focus"
            }
        },
        marksmanshipSettings = {
            useTrueshot = {
                displayName = "Use Trueshot",
                description = "Use Trueshot on cooldown",
                type = "toggle",
                default = true
            },
            trueshotWithAimedShot = {
                displayName = "Trueshot with Aimed Shot",
                description = "Use Trueshot after Aimed Shot for maximum effect",
                type = "toggle",
                default = true
            },
            useBarrage = {
                displayName = "Use Barrage",
                description = "Use Barrage for AoE",
                type = "toggle",
                default = true
            },
            barrageThreshold = {
                displayName = "Barrage Threshold",
                description = "Minimum targets to use Barrage",
                type = "slider",
                min = 2,
                max = 5,
                step = 1,
                default = 3
            },
            useSerpentSting = {
                displayName = "Use Serpent Sting",
                description = "Maintain Serpent Sting on targets",
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
            },
            useExplosiveShot = {
                displayName = "Use Explosive Shot",
                description = "Use Explosive Shot in AoE situations",
                type = "toggle",
                default = true
            }
        },
        survivalSettings = {
            useCoordinatedAssault = {
                displayName = "Use Coordinated Assault",
                description = "Use Coordinated Assault on cooldown",
                type = "toggle",
                default = true
            },
            useWildfireBomb = {
                displayName = "Use Wildfire Bomb",
                description = "Use Wildfire Bomb on cooldown",
                type = "toggle",
                default = true
            },
            bombPriority = {
                displayName = "Bomb Priority",
                description = "Which Wildfire Infusion bomb to prioritize",
                type = "dropdown",
                options = {"Auto", "Shrapnel", "Pheromone", "Volatile"},
                default = "Auto"
            },
            useMongooseBite = {
                displayName = "Use Mongoose Bite",
                description = "Prioritize Mongoose Bite if talented",
                type = "toggle",
                default = true
            },
            mongoosePooling = {
                displayName = "Mongoose Focus Pooling",
                description = "Pool Focus for Mongoose Bite",
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
            },
            useHarpoon = {
                displayName = "Use Harpoon",
                description = "Use Harpoon to engage enemies",
                type = "toggle",
                default = true
            }
        }
    })
    
    -- Add callback for settings changes
    ConfigRegistry:RegisterCallback("Hunter", function(settings)
        self:ApplySettings(settings)
    end)
}

-- Apply settings
function HunterModule:ApplySettings(settings)
    -- Apply general settings
    isEnabled = settings.generalSettings.enabled
}

-- Register events
function HunterModule:RegisterEvents()
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
}

-- On specialization changed
function HunterModule:OnSpecializationChanged()
    -- Get current spec ID
    playerSpec = API.GetActiveSpecID()
    
    API.PrintDebug("Hunter specialization changed: " .. playerSpec)
    
    -- Ensure correct rotation is registered
    if playerSpec == SPEC_BEAST_MASTERY then
        self:RegisterBeastMasteryRotation()
    elseif playerSpec == SPEC_MARKSMANSHIP then
        self:RegisterMarksmanshipRotation()
    elseif playerSpec == SPEC_SURVIVAL then
        self:RegisterSurvivalRotation()
    end
}

-- Register rotations
function HunterModule:RegisterRotations()
    -- Register spec-specific rotations
    self:RegisterBeastMasteryRotation()
    self:RegisterMarksmanshipRotation()
    self:RegisterSurvivalRotation()
}

-- Register Beast Mastery rotation
function HunterModule:RegisterBeastMasteryRotation()
    RotationManager:RegisterRotation("HunterBeastMastery", {
        id = "HunterBeastMastery",
        name = "Hunter - Beast Mastery",
        class = "HUNTER",
        spec = SPEC_BEAST_MASTERY,
        level = 10,
        description = "Beast Mastery Hunter rotation for The War Within Season 2",
        author = "WindrunnerRotations",
        version = "1.0.0",
        rotation = function()
            return self:BeastMasteryRotation()
        end
    })
}

-- Register Marksmanship rotation
function HunterModule:RegisterMarksmanshipRotation()
    RotationManager:RegisterRotation("HunterMarksmanship", {
        id = "HunterMarksmanship",
        name = "Hunter - Marksmanship",
        class = "HUNTER",
        spec = SPEC_MARKSMANSHIP,
        level = 10,
        description = "Marksmanship Hunter rotation for The War Within Season 2",
        author = "WindrunnerRotations",
        version = "1.0.0",
        rotation = function()
            return self:MarksmanshipRotation()
        end
    })
}

-- Register Survival rotation
function HunterModule:RegisterSurvivalRotation()
    RotationManager:RegisterRotation("HunterSurvival", {
        id = "HunterSurvival",
        name = "Hunter - Survival",
        class = "HUNTER",
        spec = SPEC_SURVIVAL,
        level = 10,
        description = "Survival Hunter rotation for The War Within Season 2",
        author = "WindrunnerRotations",
        version = "1.0.0",
        rotation = function()
            return self:SurvivalRotation()
        end
    })
}

-- Beast Mastery rotation
function HunterModule:BeastMasteryRotation()
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
    local settings = ConfigRegistry:GetSettings("Hunter")
    
    -- Common Combat Variables
    local health, maxHealth, healthPercent = API.GetUnitHealth(player)
    local petExists = UnitExists("pet")
    local petHealth, petMaxHealth, petHealthPercent = 100, 100, 100
    if petExists then
        petHealth, petMaxHealth, petHealthPercent = API.GetUnitHealth("pet")
    end
    local targetHealth, targetMaxHealth, targetHealthPercent = API.GetUnitHealth(target)
    local focus, maxFocus, focusPercent = API.GetUnitPower(player, Enum.PowerType.Focus)
    local targetDistance = API.GetUnitDistance(target)
    local enemies = API.GetEnemyCount(8)
    local aoeEnabled = settings.beastMasterySettings.aoeThreshold <= enemies
    
    -- Check for pet
    if settings.generalSettings.autoCallPet and not petExists then
        -- Call pet based on settings
        local petSlot = settings.generalSettings.preferredPet
        local petSpellID
        
        if petSlot == "Pet 1" then
            petSpellID = BM_SPELLS.CALL_PET_1
        elseif petSlot == "Pet 2" then
            petSpellID = BM_SPELLS.CALL_PET_2
        elseif petSlot == "Pet 3" then
            petSpellID = BM_SPELLS.CALL_PET_3
        elseif petSlot == "Pet 4" then
            petSpellID = BM_SPELLS.CALL_PET_4
        elseif petSlot == "Pet 5" then
            petSpellID = BM_SPELLS.CALL_PET_5
        else
            petSpellID = BM_SPELLS.CALL_PET_1
        end
        
        if API.IsSpellKnown(petSpellID) and API.IsSpellUsable(petSpellID) then
            return {
                type = "spell",
                id = petSpellID,
                target = player
            }
        end
    end
    
    -- Revive pet if it's dead
    if petExists and petHealthPercent <= 0 and
       API.IsSpellKnown(BM_SPELLS.REVIVE_PET) and API.IsSpellUsable(BM_SPELLS.REVIVE_PET) then
        return {
            type = "spell",
            id = BM_SPELLS.REVIVE_PET,
            target = player
        }
    end
    
    -- Mend pet if needed
    if petExists and petHealthPercent < settings.generalSettings.mendPetThreshold and
       API.IsSpellKnown(BM_SPELLS.MEND_PET) and API.IsSpellUsable(BM_SPELLS.MEND_PET) then
        return {
            type = "spell",
            id = BM_SPELLS.MEND_PET,
            target = "pet"
        }
    end
    
    -- Defensive abilities
    if settings.generalSettings.useDefensives then
        -- Aspect of the Turtle at critical health
        if settings.generalSettings.useAspectOfTheTurtle and
           healthPercent <= settings.generalSettings.turtleThreshold and
           API.IsSpellKnown(BM_SPELLS.ASPECT_OF_THE_TURTLE) and 
           API.IsSpellUsable(BM_SPELLS.ASPECT_OF_THE_TURTLE) then
            return {
                type = "spell",
                id = BM_SPELLS.ASPECT_OF_THE_TURTLE,
                target = player
            }
        end
        
        -- Exhilaration at low health
        if healthPercent < 40 and 
           API.IsSpellKnown(BM_SPELLS.EXHILARATION) and 
           API.IsSpellUsable(BM_SPELLS.EXHILARATION) then
            return {
                type = "spell",
                id = BM_SPELLS.EXHILARATION,
                target = player
            }
        end
    end
    
    -- Offensive cooldowns
    if inCombat then
        -- Bestial Wrath and Aspect of the Wild synced if setting enabled
        local hasAspectOfTheWild = API.UnitHasBuff(player, BUFFS.ASPECT_OF_THE_WILD)
        local hasBestialWrath = API.UnitHasBuff(player, BUFFS.BESTIAL_WRATH)
        
        if settings.beastMasterySettings.useBestialWrath and
           API.IsSpellKnown(BM_SPELLS.BESTIAL_WRATH) and 
           API.IsSpellUsable(BM_SPELLS.BESTIAL_WRATH) then
           
            local useNow = true
            -- Check if we need to sync with AotW
            if settings.beastMasterySettings.syncBWandAotW and
               settings.beastMasterySettings.useAspectOfTheWild and
               API.IsSpellKnown(BM_SPELLS.ASPECT_OF_THE_WILD) then
                local _, aotWCD = API.GetSpellCooldown(BM_SPELLS.ASPECT_OF_THE_WILD)
                -- Only wait if AotW is coming off cooldown within 3 seconds
                if not hasAspectOfTheWild and aotWCD > 0 and aotWCD < 3 then
                    useNow = false
                end
            end
            
            if useNow then
                return {
                    type = "spell",
                    id = BM_SPELLS.BESTIAL_WRATH,
                    target = player
                }
            end
        end
        
        -- Aspect of the Wild
        if settings.beastMasterySettings.useAspectOfTheWild and
           API.IsSpellKnown(BM_SPELLS.ASPECT_OF_THE_WILD) and 
           API.IsSpellUsable(BM_SPELLS.ASPECT_OF_THE_WILD) then
            return {
                type = "spell",
                id = BM_SPELLS.ASPECT_OF_THE_WILD,
                target = player
            }
        end
        
        -- Bloodshed if talented
        if API.IsSpellKnown(BM_SPELLS.BLOODSHED) and 
           API.IsSpellUsable(BM_SPELLS.BLOODSHED) then
            return {
                type = "spell",
                id = BM_SPELLS.BLOODSHED,
                target = target
            }
        end
        
        -- Stampede if talented
        if API.IsSpellKnown(BM_SPELLS.STAMPEDE) and 
           API.IsSpellUsable(BM_SPELLS.STAMPEDE) then
            return {
                type = "spell",
                id = BM_SPELLS.STAMPEDE,
                target = target
            }
        end
        
        -- Dire Beast if talented and enabled
        if settings.beastMasterySettings.useDireBeast and
           API.IsSpellKnown(BM_SPELLS.DIRE_BEAST) and 
           API.IsSpellUsable(BM_SPELLS.DIRE_BEAST) then
            return {
                type = "spell",
                id = BM_SPELLS.DIRE_BEAST,
                target = target
            }
        end
        
        -- A Murder of Crows if talented
        if API.IsSpellKnown(BM_SPELLS.A_MURDER_OF_CROWS) and 
           API.IsSpellUsable(BM_SPELLS.A_MURDER_OF_CROWS) then
            return {
                type = "spell",
                id = BM_SPELLS.A_MURDER_OF_CROWS,
                target = target
            }
        end
    end
    
    -- AoE rotation
    if aoeEnabled and enemies >= 3 then
        -- Beast Cleave via Multishot if not active
        local hasBeastCleave, _, _, beastCleaveRemaining = API.UnitHasBuff("pet", BUFFS.BEAST_CLEAVE)
        if (not hasBeastCleave or beastCleaveRemaining < 1) and
           API.IsSpellKnown(BM_SPELLS.MULTISHOT) and 
           API.IsSpellUsable(BM_SPELLS.MULTISHOT) and
           focus >= 40 then
            return {
                type = "spell",
                id = BM_SPELLS.MULTISHOT,
                target = target
            }
        end
        
        -- Barrage for AoE if enabled
        if settings.beastMasterySettings.useBarrage and
           enemies >= settings.beastMasterySettings.barrageThreshold and
           API.IsSpellKnown(BM_SPELLS.BARRAGE) and 
           API.IsSpellUsable(BM_SPELLS.BARRAGE) then
            return {
                type = "spell",
                id = BM_SPELLS.BARRAGE,
                target = target
            }
        end
    end
    
    -- Core rotation
    -- Barbed Shot to maintain Frenzy and reset Kill Command
    local hasFrenzy, frenzyStacks, _, frenzyRemaining = API.UnitHasBuff("pet", BUFFS.FRENZY)
    if (not hasFrenzy or frenzyRemaining < 2 or frenzyStacks < 3) and
       API.IsSpellKnown(BM_SPELLS.BARBED_SHOT) and 
       API.IsSpellUsable(BM_SPELLS.BARBED_SHOT) then
        return {
            type = "spell",
            id = BM_SPELLS.BARBED_SHOT,
            target = target
        }
    end
    
    -- Kill Command on cooldown
    if API.IsSpellKnown(BM_SPELLS.KILL_COMMAND) and 
       API.IsSpellUsable(BM_SPELLS.KILL_COMMAND) and
       focus >= 30 then
        return {
            type = "spell",
            id = BM_SPELLS.KILL_COMMAND,
            target = target
        }
    end
    
    -- Barbed Shot if charges are capping
    local barbedShotCharges = API.GetSpellCharges(BM_SPELLS.BARBED_SHOT)
    if barbedShotCharges and barbedShotCharges >= 1.8 and
       API.IsSpellKnown(BM_SPELLS.BARBED_SHOT) and 
       API.IsSpellUsable(BM_SPELLS.BARBED_SHOT) then
        return {
            type = "spell",
            id = BM_SPELLS.BARBED_SHOT,
            target = target
        }
    end
    
    -- Kill Shot if target is low health
    if targetHealthPercent < 20 and
       API.IsSpellKnown(BM_SPELLS.KILL_SHOT) and 
       API.IsSpellUsable(BM_SPELLS.KILL_SHOT) then
        return {
            type = "spell",
            id = BM_SPELLS.KILL_SHOT,
            target = target
        }
    end
    
    -- Cobra Shot as focus dump
    if focus >= 50 and
       API.IsSpellKnown(BM_SPELLS.COBRA_SHOT) and 
       API.IsSpellUsable(BM_SPELLS.COBRA_SHOT) then
        return {
            type = "spell",
            id = BM_SPELLS.COBRA_SHOT,
            target = target
        }
    end
    
    return nil
}

-- Marksmanship rotation
function HunterModule:MarksmanshipRotation()
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
    local settings = ConfigRegistry:GetSettings("Hunter")
    
    -- Common Combat Variables
    local health, maxHealth, healthPercent = API.GetUnitHealth(player)
    local petExists = UnitExists("pet")
    local petHealth, petMaxHealth, petHealthPercent = 100, 100, 100
    if petExists then
        petHealth, petMaxHealth, petHealthPercent = API.GetUnitHealth("pet")
    end
    local targetHealth, targetMaxHealth, targetHealthPercent = API.GetUnitHealth(target)
    local focus, maxFocus, focusPercent = API.GetUnitPower(player, Enum.PowerType.Focus)
    local targetDistance = API.GetUnitDistance(target)
    local enemies = API.GetEnemyCount(8)
    local aoeEnabled = settings.marksmanshipSettings.aoeThreshold <= enemies
    local hasTrueshot = API.UnitHasBuff(player, BUFFS.TRUESHOT)
    local hasPreciseShots = API.UnitHasBuff(player, BUFFS.PRECISE_SHOTS)
    local hasTrickShots = API.UnitHasBuff(player, BUFFS.TRICK_SHOTS)
    
    -- Check for pet if not using Lone Wolf
    local hasLoneWolf = API.UnitHasBuff(player, BUFFS.LONE_WOLF)
    if settings.generalSettings.autoCallPet and not petExists and not hasLoneWolf then
        -- Call pet based on settings
        local petSlot = settings.generalSettings.preferredPet
        local petSpellID
        
        if petSlot == "Pet 1" then
            petSpellID = MM_SPELLS.CALL_PET_1
        elseif petSlot == "Pet 2" then
            petSpellID = MM_SPELLS.CALL_PET_2
        elseif petSlot == "Pet 3" then
            petSpellID = MM_SPELLS.CALL_PET_3
        elseif petSlot == "Pet 4" then
            petSpellID = MM_SPELLS.CALL_PET_4
        elseif petSlot == "Pet 5" then
            petSpellID = MM_SPELLS.CALL_PET_5
        else
            petSpellID = MM_SPELLS.CALL_PET_1
        end
        
        if API.IsSpellKnown(petSpellID) and API.IsSpellUsable(petSpellID) then
            return {
                type = "spell",
                id = petSpellID,
                target = player
            }
        end
    end
    
    -- Revive pet if it's dead
    if petExists and petHealthPercent <= 0 and
       API.IsSpellKnown(MM_SPELLS.REVIVE_PET) and API.IsSpellUsable(MM_SPELLS.REVIVE_PET) then
        return {
            type = "spell",
            id = MM_SPELLS.REVIVE_PET,
            target = player
        }
    end
    
    -- Mend pet if needed
    if petExists and petHealthPercent < settings.generalSettings.mendPetThreshold and
       API.IsSpellKnown(MM_SPELLS.MEND_PET) and API.IsSpellUsable(MM_SPELLS.MEND_PET) then
        return {
            type = "spell",
            id = MM_SPELLS.MEND_PET,
            target = "pet"
        }
    end
    
    -- Defensive abilities
    if settings.generalSettings.useDefensives then
        -- Aspect of the Turtle at critical health
        if settings.generalSettings.useAspectOfTheTurtle and
           healthPercent <= settings.generalSettings.turtleThreshold and
           API.IsSpellKnown(MM_SPELLS.ASPECT_OF_THE_TURTLE) and 
           API.IsSpellUsable(MM_SPELLS.ASPECT_OF_THE_TURTLE) then
            return {
                type = "spell",
                id = MM_SPELLS.ASPECT_OF_THE_TURTLE,
                target = player
            }
        end
        
        -- Exhilaration at low health
        if healthPercent < 40 and 
           API.IsSpellKnown(MM_SPELLS.EXHILARATION) and 
           API.IsSpellUsable(MM_SPELLS.EXHILARATION) then
            return {
                type = "spell",
                id = MM_SPELLS.EXHILARATION,
                target = player
            }
        end
    end
    
    -- Offensive cooldowns
    if inCombat then
        -- Trueshot
        if settings.marksmanshipSettings.useTrueshot and
           API.IsSpellKnown(MM_SPELLS.TRUESHOT) and 
           API.IsSpellUsable(MM_SPELLS.TRUESHOT) then
           
            local useNow = true
            -- Check if we need a special condition
            if settings.marksmanshipSettings.trueshotWithAimedShot then
                -- Only use Trueshot when Aimed Shot is ready
                local _, aimedShotCD = API.GetSpellCooldown(MM_SPELLS.AIMED_SHOT)
                if aimedShotCD > 0.5 then -- Give a small buffer
                    useNow = false
                end
            end
            
            if useNow then
                return {
                    type = "spell",
                    id = MM_SPELLS.TRUESHOT,
                    target = player
                }
            end
        end
        
        -- Volley if talented
        if aoeEnabled and
           API.IsSpellKnown(MM_SPELLS.VOLLEY) and 
           API.IsSpellUsable(MM_SPELLS.VOLLEY) then
            return {
                type = "spell",
                id = MM_SPELLS.VOLLEY,
                target = target
            }
        end
        
        -- A Murder of Crows if talented
        if API.IsSpellKnown(MM_SPELLS.A_MURDER_OF_CROWS) and 
           API.IsSpellUsable(MM_SPELLS.A_MURDER_OF_CROWS) then
            return {
                type = "spell",
                id = MM_SPELLS.A_MURDER_OF_CROWS,
                target = target
            }
        end
    end
    
    -- Apply or refresh Serpent Sting if setting enabled
    if settings.marksmanshipSettings.useSerpentSting and
       API.IsSpellKnown(MM_SPELLS.SERPENT_STING) and 
       API.IsSpellUsable(MM_SPELLS.SERPENT_STING) and
       not API.UnitHasDebuff(target, DEBUFFS.SERPENT_STING) and
       focus >= 20 then
        return {
            type = "spell",
            id = MM_SPELLS.SERPENT_STING,
            target = target
        }
    end
    
    -- AoE rotation
    if aoeEnabled and enemies >= 3 then
        -- Apply Trick Shots buff with Multi-Shot first
        if not hasTrickShots and
           API.IsSpellKnown(MM_SPELLS.MULTISHOT) and 
           API.IsSpellUsable(MM_SPELLS.MULTISHOT) and
           focus >= 40 then
            return {
                type = "spell",
                id = MM_SPELLS.MULTISHOT,
                target = target
            }
        end
        
        -- Explosive Shot for AoE if enabled
        if settings.marksmanshipSettings.useExplosiveShot and
           API.IsSpellKnown(MM_SPELLS.EXPLOSIVE_SHOT) and 
           API.IsSpellUsable(MM_SPELLS.EXPLOSIVE_SHOT) and
           focus >= 20 then
            return {
                type = "spell",
                id = MM_SPELLS.EXPLOSIVE_SHOT,
                target = target
            }
        end
        
        -- Barrage for AoE if enabled
        if settings.marksmanshipSettings.useBarrage and
           enemies >= settings.marksmanshipSettings.barrageThreshold and
           API.IsSpellKnown(MM_SPELLS.BARRAGE) and 
           API.IsSpellUsable(MM_SPELLS.BARRAGE) and
           focus >= 30 then
            return {
                type = "spell",
                id = MM_SPELLS.BARRAGE,
                target = target
            }
        end
        
        -- With Trick Shots, Aimed Shot cleaves
        if hasTrickShots and focus >= 35 and
           API.IsSpellKnown(MM_SPELLS.AIMED_SHOT) and 
           API.IsSpellUsable(MM_SPELLS.AIMED_SHOT) then
            return {
                type = "spell",
                id = MM_SPELLS.AIMED_SHOT,
                target = target
            }
        end
    end
    
    -- Core rotation
    -- Kill Shot if target is low health
    if targetHealthPercent < 20 and
       API.IsSpellKnown(MM_SPELLS.KILL_SHOT) and 
       API.IsSpellUsable(MM_SPELLS.KILL_SHOT) then
        return {
            type = "spell",
            id = MM_SPELLS.KILL_SHOT,
            target = target
        }
    end
    
    -- Rapid Fire on cooldown
    if API.IsSpellKnown(MM_SPELLS.RAPID_FIRE) and 
       API.IsSpellUsable(MM_SPELLS.RAPID_FIRE) then
        return {
            type = "spell",
            id = MM_SPELLS.RAPID_FIRE,
            target = target
        }
    end
    
    -- Aimed Shot if not moving
    if not IsPlayerMoving() and focus >= 35 and
       API.IsSpellKnown(MM_SPELLS.AIMED_SHOT) and 
       API.IsSpellUsable(MM_SPELLS.AIMED_SHOT) then
        return {
            type = "spell",
            id = MM_SPELLS.AIMED_SHOT,
            target = target
        }
    end
    
    -- Arcane Shot with Precise Shots proc
    if hasPreciseShots and
       API.IsSpellKnown(MM_SPELLS.ARCANE_SHOT) and 
       API.IsSpellUsable(MM_SPELLS.ARCANE_SHOT) and
       focus >= 20 then
        return {
            type = "spell",
            id = MM_SPELLS.ARCANE_SHOT,
            target = target
        }
    end
    
    -- Chimaera Shot if talented
    if API.IsSpellKnown(MM_SPELLS.CHIMAERA_SHOT) and 
       API.IsSpellUsable(MM_SPELLS.CHIMAERA_SHOT) and
       focus >= 20 then
        return {
            type = "spell",
            id = MM_SPELLS.CHIMAERA_SHOT,
            target = target
        }
    end
    
    -- Arcane Shot as focus dump
    if focus >= 50 and
       API.IsSpellKnown(MM_SPELLS.ARCANE_SHOT) and 
       API.IsSpellUsable(MM_SPELLS.ARCANE_SHOT) then
        return {
            type = "spell",
            id = MM_SPELLS.ARCANE_SHOT,
            target = target
        }
    end
    
    -- Steady Shot to build focus
    if focus < 70 and
       API.IsSpellKnown(MM_SPELLS.STEADY_SHOT) and 
       API.IsSpellUsable(MM_SPELLS.STEADY_SHOT) then
        return {
            type = "spell",
            id = MM_SPELLS.STEADY_SHOT,
            target = target
        }
    end
    
    return nil
}

-- Survival rotation
function HunterModule:SurvivalRotation()
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
    local settings = ConfigRegistry:GetSettings("Hunter")
    
    -- Common Combat Variables
    local health, maxHealth, healthPercent = API.GetUnitHealth(player)
    local petExists = UnitExists("pet")
    local petHealth, petMaxHealth, petHealthPercent = 100, 100, 100
    if petExists then
        petHealth, petMaxHealth, petHealthPercent = API.GetUnitHealth("pet")
    end
    local targetHealth, targetMaxHealth, targetHealthPercent = API.GetUnitHealth(target)
    local focus, maxFocus, focusPercent = API.GetUnitPower(player, Enum.PowerType.Focus)
    local targetDistance = API.GetUnitDistance(target)
    local enemies = API.GetEnemyCount(8)
    local aoeEnabled = settings.survivalSettings.aoeThreshold <= enemies
    local hasCoodinatedAssault = API.UnitHasBuff(player, BUFFS.COORDINATED_ASSAULT)
    local hasMongooseFury, mongooseFuryStacks, _, mongooseFuryRemaining = API.UnitHasBuff(player, BUFFS.MONGOOSE_FURY)
    
    -- Check for pet
    if settings.generalSettings.autoCallPet and not petExists then
        -- Call pet based on settings
        local petSlot = settings.generalSettings.preferredPet
        local petSpellID
        
        if petSlot == "Pet 1" then
            petSpellID = SV_SPELLS.CALL_PET_1
        elseif petSlot == "Pet 2" then
            petSpellID = SV_SPELLS.CALL_PET_2
        elseif petSlot == "Pet 3" then
            petSpellID = SV_SPELLS.CALL_PET_3
        elseif petSlot == "Pet 4" then
            petSpellID = SV_SPELLS.CALL_PET_4
        elseif petSlot == "Pet 5" then
            petSpellID = SV_SPELLS.CALL_PET_5
        else
            petSpellID = SV_SPELLS.CALL_PET_1
        end
        
        if API.IsSpellKnown(petSpellID) and API.IsSpellUsable(petSpellID) then
            return {
                type = "spell",
                id = petSpellID,
                target = player
            }
        end
    end
    
    -- Revive pet if it's dead
    if petExists and petHealthPercent <= 0 and
       API.IsSpellKnown(SV_SPELLS.REVIVE_PET) and API.IsSpellUsable(SV_SPELLS.REVIVE_PET) then
        return {
            type = "spell",
            id = SV_SPELLS.REVIVE_PET,
            target = player
        }
    end
    
    -- Mend pet if needed
    if petExists and petHealthPercent < settings.generalSettings.mendPetThreshold and
       API.IsSpellKnown(SV_SPELLS.MEND_PET) and API.IsSpellUsable(SV_SPELLS.MEND_PET) then
        return {
            type = "spell",
            id = SV_SPELLS.MEND_PET,
            target = "pet"
        }
    end
    
    -- Defensive abilities
    if settings.generalSettings.useDefensives then
        -- Aspect of the Turtle at critical health
        if settings.generalSettings.useAspectOfTheTurtle and
           healthPercent <= settings.generalSettings.turtleThreshold and
           API.IsSpellKnown(SV_SPELLS.ASPECT_OF_THE_TURTLE) and 
           API.IsSpellUsable(SV_SPELLS.ASPECT_OF_THE_TURTLE) then
            return {
                type = "spell",
                id = SV_SPELLS.ASPECT_OF_THE_TURTLE,
                target = player
            }
        end
        
        -- Exhilaration at low health
        if healthPercent < 40 and 
           API.IsSpellKnown(SV_SPELLS.EXHILARATION) and 
           API.IsSpellUsable(SV_SPELLS.EXHILARATION) then
            return {
                type = "spell",
                id = SV_SPELLS.EXHILARATION,
                target = player
            }
        end
    end
    
    -- Harpoon for gap closing
    if settings.survivalSettings.useHarpoon and
       targetDistance > 8 and targetDistance < 30 and
       API.IsSpellKnown(SV_SPELLS.HARPOON) and 
       API.IsSpellUsable(SV_SPELLS.HARPOON) then
        return {
            type = "spell",
            id = SV_SPELLS.HARPOON,
            target = target
        }
    end
    
    -- Offensive cooldowns
    if inCombat then
        -- Coordinated Assault
        if settings.survivalSettings.useCoordinatedAssault and
           API.IsSpellKnown(SV_SPELLS.COORDINATED_ASSAULT) and 
           API.IsSpellUsable(SV_SPELLS.COORDINATED_ASSAULT) then
            return {
                type = "spell",
                id = SV_SPELLS.COORDINATED_ASSAULT,
                target = player
            }
        end
        
        -- Spearhead if talented
        if API.IsSpellKnown(SV_SPELLS.SPEARHEAD) and 
           API.IsSpellUsable(SV_SPELLS.SPEARHEAD) then
            return {
                type = "spell",
                id = SV_SPELLS.SPEARHEAD,
                target = target
            }
        end
        
        -- A Murder of Crows if talented
        if API.IsSpellKnown(SV_SPELLS.A_MURDER_OF_CROWS) and 
           API.IsSpellUsable(SV_SPELLS.A_MURDER_OF_CROWS) then
            return {
                type = "spell",
                id = SV_SPELLS.A_MURDER_OF_CROWS,
                target = target
            }
        end
        
        -- Chakrams if talented
        if aoeEnabled and
           API.IsSpellKnown(SV_SPELLS.CHAKRAMS) and 
           API.IsSpellUsable(SV_SPELLS.CHAKRAMS) then
            return {
                type = "spell",
                id = SV_SPELLS.CHAKRAMS,
                target = target
            }
        end
    end
    
    -- Wildfire Bomb
    if settings.survivalSettings.useWildfireBomb and
       API.IsSpellKnown(SV_SPELLS.WILDFIRE_BOMB) and 
       API.IsSpellUsable(SV_SPELLS.WILDFIRE_BOMB) then
        return {
            type = "spell",
            id = SV_SPELLS.WILDFIRE_BOMB,
            target = target
        }
    end
    
    -- AoE rotation
    if aoeEnabled and enemies >= 3 then
        -- Butchery if talented
        if API.IsSpellKnown(SV_SPELLS.BUTCHERY) and 
           API.IsSpellUsable(SV_SPELLS.BUTCHERY) and
           focus >= 30 then
            return {
                type = "spell",
                id = SV_SPELLS.BUTCHERY,
                target = target
            }
        end
        
        -- Carve if not using Butchery
        if not API.IsSpellKnown(SV_SPELLS.BUTCHERY) and
           API.IsSpellKnown(SV_SPELLS.CARVE) and 
           API.IsSpellUsable(SV_SPELLS.CARVE) and
           focus >= 30 then
            return {
                type = "spell",
                id = SV_SPELLS.CARVE,
                target = target
            }
        end
    end
    
    -- Core rotation
    -- Kill Command on cooldown
    if API.IsSpellKnown(SV_SPELLS.KILL_COMMAND) and 
       API.IsSpellUsable(SV_SPELLS.KILL_COMMAND) and
       focus >= 30 then
        return {
            type = "spell",
            id = SV_SPELLS.KILL_COMMAND,
            target = target
        }
    end
    
    -- Flanking Strike if talented
    if API.IsSpellKnown(SV_SPELLS.FLANKING_STRIKE) and 
       API.IsSpellUsable(SV_SPELLS.FLANKING_STRIKE) and
       focus >= 30 then
        return {
            type = "spell",
            id = SV_SPELLS.FLANKING_STRIKE,
            target = target
        }
    end
    
    -- Mongoose Bite if talented and enabled
    if settings.survivalSettings.useMongooseBite and
       API.IsSpellKnown(SV_SPELLS.MONGOOSE_BITE) and 
       API.IsSpellUsable(SV_SPELLS.MONGOOSE_BITE) and
       focus >= 30 and (not settings.survivalSettings.mongoosePooling or focus >= 70 or hasMongooseFury) then
        return {
            type = "spell",
            id = SV_SPELLS.MONGOOSE_BITE,
            target = target
        }
    end
    
    -- Raptor Strike if not using Mongoose Bite
    if (not API.IsSpellKnown(SV_SPELLS.MONGOOSE_BITE) or not settings.survivalSettings.useMongooseBite) and
       API.IsSpellKnown(SV_SPELLS.RAPTOR_STRIKE) and 
       API.IsSpellUsable(SV_SPELLS.RAPTOR_STRIKE) and
       focus >= 30 then
        return {
            type = "spell",
            id = SV_SPELLS.RAPTOR_STRIKE,
            target = target
        }
    end
    
    return nil
}

-- Should execute rotation
function HunterModule:ShouldExecuteRotation()
    if not isEnabled then
        return false
    end
    
    -- Check if player matches class
    local playerInfo = API.GetPlayerInfo()
    if playerInfo.class ~= "HUNTER" then
        return false
    end
    
    return true
}

-- Get spell charges
function API.GetSpellCharges(spellID)
    if not API.IsSpellKnown(spellID) then
        return 0
    end
    
    -- Try to use Tinkr's API if available
    if API.IsTinkrLoaded() and Tinkr.Spell and Tinkr.Spell[spellID] then
        return Tinkr.Spell[spellID]:GetCharges() or 0
    end
    
    -- Fallback to WoW API
    local charges, maxCharges, cdStart, cdDuration = GetSpellCharges(spellID)
    if charges then
        -- If on cooldown, calculate partial charges
        if cdStart and cdDuration and cdDuration > 0 then
            local timeSinceStart = GetTime() - cdStart
            local partialCharge = timeSinceStart / cdDuration
            return charges + partialCharge
        end
        return charges
    end
    
    return 0
end

-- Register for export
WR.Hunter = HunterModule

return HunterModule