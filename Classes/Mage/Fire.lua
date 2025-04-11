------------------------------------------
-- WindrunnerRotations - Fire Mage Module
-- Author: VortexQ8
-- The War Within Season 2
------------------------------------------

local Fire = {}
-- This will be assigned to addon.Classes.Mage.Fire when loaded

-- These will be set when the file is loaded in our test environment
local API
local ConfigRegistry
local AAC
local Mage

-- Cache frequently accessed data
local spells = {}
local talents = {}
local buffs = {}
local debuffs = {}

-- State tracking variables
local nextCastOverride = nil
local burstModeActive = false
local currentAoETargets = 0
local combustionActive = false
local combustionEndTime = 0
local hotStreakActive = false
local hotStreakEndTime = 0
local heatingUpActive = false
local heatingUpEndTime = 0
local firestarterActive = false
local scorchPhaseActive = false
local runeOfPowerActive = false
local runeOfPowerEndTime = 0
local runeOfPowerX, runeOfPowerY, runeOfPowerZ = 0, 0, 0
local runeOfPowerCharges = 0
local arcanePowerActive = false
local arcanePowerEndTime = 0
local blastWaveReady = false
local blastWaveEndTime = 0
local sunKingsActive = false
local sunKingsStacks = 0
local infernalCascadeActive = false
local infernalCascadeStacks = 0
local infernalCascadeEndTime = 0
local fireBlastCharges = 0
local fireBlastMaxCharges = 0
local phoenixFlamesCharges = 0
local phoenixFlamesMaxCharges = 0
local igniteActive = false
local totalHaste = 0
local playerHastePercent = 0
local manaGem = false
local manaGemCharges = 0
local shiftingPowerChanneling = false
local shiftingPowerEndTime = 0
local livingBombActive = false
local livingBombEndTime = 0
local meteorImpactTime = 0
local meteorPending = false
local flamePatchActive = false
local flamePatchEndTime = 0
local hyperthermiaActive = false
local hyperthermiaStacks = 0
local soulburn = false
local manaReserves = false
local meteorStrike = false
local improvedScorch = false
local searingTouch = false
local alexstraszasFury = false
local phoenixFlames = false
local masterOfElements = false
local phoenixReborn = false
local flameCannon = false
local controlledDestruction = false
local kindling = false
local flowOfTime = false
local fromTheAshes = false
local fireStarter = false
local feveredIncantation = false
local feveredIncantationStacks = 0
local feveredIncantationEndTime = 0
local pyroclasm = false
local pyroclasmsStacks = 0
local pyroclasmsEndTime = 0
local flamePatch = false
local fireAndIce = false
local flamingMind = false
local pyromaniac = false
local feelTheBurn = false
local flamingShackles = false
local currentMana = 0
local maxMana = 100
local inFireBlastRange = false
local fuelTheFire = false
local ignitionPoint = true
local temporalWarp = false

-- Constants
local FIRE_SPEC_ID = 63
local DEFAULT_AOE_THRESHOLD = 3
local COMBUSTION_DURATION = 12 -- seconds
local RUNE_OF_POWER_DURATION = 12 -- seconds
local ARCANE_POWER_DURATION = 15 -- seconds
local LIVING_BOMB_DURATION = 4 -- seconds
local FLAME_PATCH_DURATION = 8 -- seconds
local METEOR_DELAY = 3 -- seconds from cast to impact
local SHIFTING_POWER_CHANNEL_TIME = 4 -- seconds
local FIRESTARTER_THRESHOLD = 90 -- percentage
local SEARING_TOUCH_THRESHOLD = 30 -- percentage
local FIRE_BLAST_RANGE = 40 -- yards

-- Initialize the Fire module
function Fire:Initialize()
    self:RegisterSpells()
    self:RegisterVariables()
    self:RegisterSettings()
    self:RegisterEvents()
    
    API.PrintDebug("Fire Mage module initialized")
    
    return true
end

-- Register spell IDs
function Fire:RegisterSpells()
    -- Core rotational abilities
    spells.FIREBALL = 133
    spells.PYROBLAST = 11366
    spells.FIRE_BLAST = 108853
    spells.PHOENIX_FLAMES = 257541
    spells.DRAGONS_BREATH = 31661
    spells.SCORCH = 2948
    spells.LIVING_BOMB = 44457
    spells.BLAST_WAVE = 157981
    spells.FLAMESTRIKE = 2120
    spells.COMBUSTION = 190319
    spells.METEOR = 153561
    spells.RUNE_OF_POWER = 116011
    spells.SHIFTING_POWER = 382440
    
    -- Core utilities
    spells.ARCANE_INTELLECT = 1459
    spells.BLINK = 1953
    spells.SHIMMER = 212653
    spells.FROST_NOVA = 122
    spells.SLOW_FALL = 130
    spells.SPELLSTEAL = 30449
    spells.COUNTERSPELL = 2139
    spells.ICE_BLOCK = 45438
    spells.INVISIBILITY = 66
    spells.REMOVE_CURSE = 475
    spells.MIRROR_IMAGE = 55342
    spells.ARCANE_EXPLOSION = 1449
    
    -- Defensive/movement abilities
    spells.BLAZING_BARRIER = 235313
    spells.ICE_BARRIER = 11426
    spells.PRISMATIC_BARRIER = 235450
    spells.FROST_NOVA = 122
    spells.ALTER_TIME = 342245
    spells.GREATER_INVISIBILITY = 110959
    
    -- Talents and passives
    spells.HOT_STREAK = 48108
    spells.HEATING_UP = 48107
    spells.IGNITE = 12654
    spells.CRITICAL_MASS = 117216
    spells.FIRESTARTER = 205026
    spells.ENHANCED_PYROTECHNICS = 157642
    spells.KINDLING = 155148
    spells.SEARING_TOUCH = 269644
    spells.FRENETIC_SPEED = 236058
    spells.MASTER_OF_ELEMENTS = 235870
    spells.CONTROLLED_DESTRUCTION = 383669
    spells.FLAME_PATCH = 205037
    spells.FLAME_ON = 205029
    spells.ALEXSTRASZAS_FURY = 235870
    spells.FEVERED_INCANTATION = 384033
    spells.PYROCLASM = 269650
    spells.FIRE_AND_ICE = 384481
    spells.PYROMANIAC = 205020
    spells.FLAMING_MIND = 379023
    spells.FEEL_THE_BURN = 383634
    spells.FLAMING_SHACKLES = 383650
    spells.IMPROVED_FLAMESTRIKE = 398084
    spells.FLOW_OF_TIME = 385783
    spells.WILDFIRE = 383329
    spells.IMPROVED_SCORCH = 383637
    spells.PHOENIX_REBORN = 383476
    spells.ENGULFED_IN_FLAMES = 383499
    spells.INCENDIO = 398084
    spells.FLAME_CANNON = 386828
    spells.SUN_KINGS_BLESSING = 383886
    spells.TEMPERED_FLAMES = 383659
    spells.FIREFALL = 384037
    spells.FOCUS_MAGIC = 321358
    spells.FROM_THE_ASHES = 342344
    spells.FUEL_THE_FIRE = 396289
    spells.IGNITION_POINT = 386599
    spells.TEMPORAL_WARP = 386539
    
    -- War Within Season 2 specific
    spells.ARCANE_ECHO = 383980
    spells.ARCANE_TEMPEST = 383942
    spells.ARCANE_VIGILANCE = 384650
    spells.BLAZING_SOUL = 424257
    spells.DRAGONRAGE = 375087
    spells.FLAME_OF_ALACRITY = 424266
    spells.HYPERBOREAN = 383705
    spells.HYPERTHERMIA = 383214
    spells.ICE_FLOWS = 385804
    spells.INFERNAL_CASCADE = 336821
    spells.METEOR_STRIKE = 412325
    spells.MANA_RESERVES = 382849
    spells.RUNE_SURGE = 394179
    spells.SOULBURN = 384069
    
    -- Covenant abilities (for reference, converted in WoW 10.0)
    spells.MIRRORS_OF_TORMENT = 314793
    spells.DEATHBORNE = 324220
    spells.RADIANT_SPARK = 307443
    spells.SHIFTING_POWER = 382440
    
    -- Buff IDs
    spells.COMBUSTION_BUFF = 190319
    spells.HOT_STREAK_BUFF = 48108
    spells.HEATING_UP_BUFF = 48107
    spells.PYROCLASM_BUFF = 269651
    spells.RUNE_OF_POWER_BUFF = 116014
    spells.ARCANE_POWER_BUFF = 12042
    spells.SUN_KINGS_BLESSING_BUFF = 383882
    spells.INFERNAL_CASCADE_BUFF = 336832
    spells.FEVERED_INCANTATION_BUFF = 384034
    spells.BLAZING_BARRIER_BUFF = 235313
    spells.HYPERTHERMIA_BUFF = 383215
    
    -- Debuff IDs
    spells.IGNITE_DEBUFF = 12654
    spells.LIVING_BOMB_DEBUFF = 217694
    
    -- Register all spells with the API tracking system
    for spellName, spellID in pairs(spells) do
        API.RegisterSpell(spellID)
    end
    
    -- Define aura tracking
    buffs.COMBUSTION = spells.COMBUSTION_BUFF
    buffs.HOT_STREAK = spells.HOT_STREAK_BUFF
    buffs.HEATING_UP = spells.HEATING_UP_BUFF
    buffs.PYROCLASM = spells.PYROCLASM_BUFF
    buffs.RUNE_OF_POWER = spells.RUNE_OF_POWER_BUFF
    buffs.ARCANE_POWER = spells.ARCANE_POWER_BUFF
    buffs.SUN_KINGS_BLESSING = spells.SUN_KINGS_BLESSING_BUFF
    buffs.INFERNAL_CASCADE = spells.INFERNAL_CASCADE_BUFF
    buffs.FEVERED_INCANTATION = spells.FEVERED_INCANTATION_BUFF
    buffs.BLAZING_BARRIER = spells.BLAZING_BARRIER_BUFF
    buffs.HYPERTHERMIA = spells.HYPERTHERMIA_BUFF
    
    debuffs.IGNITE = spells.IGNITE_DEBUFF
    debuffs.LIVING_BOMB = spells.LIVING_BOMB_DEBUFF
    
    return true
end

-- Register variables to track
function Fire:RegisterVariables()
    -- Talent tracking
    talents.hasSoulburn = false
    talents.hasManaReserves = false
    talents.hasMeteorStrike = false
    talents.hasImprovedScorch = false
    talents.hasSearingTouch = false
    talents.hasAlexstraszasFury = false
    talents.hasPhoenixFlames = false
    talents.hasMasterOfElements = false
    talents.hasPhoenixReborn = false
    talents.hasFlameCannon = false
    talents.hasControlledDestruction = false
    talents.hasKindling = false
    talents.hasFlowOfTime = false
    talents.hasFromTheAshes = false
    talents.hasFireStarter = false
    talents.hasFeveredIncantation = false
    talents.hasPyroclasm = false
    talents.hasFlamePatch = false
    talents.hasFireAndIce = false
    talents.hasFlamingMind = false
    talents.hasPyromaniac = false
    talents.hasFeelTheBurn = false
    talents.hasFlamingShackles = false
    talents.hasFuelTheFire = false
    talents.hasIgnitionPoint = false
    talents.hasTemporalWarp = false
    
    -- War Within Season 2 talents
    talents.hasArcaneEcho = false
    talents.hasArcaneTempest = false
    talents.hasArcaneVigilance = false
    talents.hasBlazingSoul = false
    talents.hasDragonrage = false
    talents.hasFlameOfAlacrity = false
    talents.hasHyperborean = false
    talents.hasHyperthermia = false
    talents.hasIceFlows = false
    talents.hasInfernalCascade = false
    talents.hasMeteorStrike = false
    talents.hasManaReserves = false
    talents.hasRuneSurge = false
    talents.hasSoulburn = false
    
    -- Initialize resources
    currentMana = API.GetPlayerMana()
    maxMana = API.GetPlayerMaxMana()
    
    -- Initialize spell charges
    fireBlastCharges = API.GetSpellCharges(spells.FIRE_BLAST) or 0
    fireBlastMaxCharges = API.GetSpellMaxCharges(spells.FIRE_BLAST) or 2
    phoenixFlamesCharges = API.GetSpellCharges(spells.PHOENIX_FLAMES) or 0
    phoenixFlamesMaxCharges = API.GetSpellMaxCharges(spells.PHOENIX_FLAMES) or 2
    runeOfPowerCharges = API.GetSpellCharges(spells.RUNE_OF_POWER) or 0
    
    return true
end

-- Register spec-specific settings
function Fire:RegisterSettings()
    ConfigRegistry:RegisterSettings("FireMage", {
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
            useSearingTouch = {
                displayName = "Use Searing Touch",
                description = "Switch to Scorch when targets are below health threshold",
                type = "toggle",
                default = true
            },
            useFirestarter = {
                displayName = "Use Firestarter",
                description = "Modified rotation for targets above health threshold",
                type = "toggle",
                default = true
            },
            hotStreakManagement = {
                displayName = "Hot Streak Management",
                description = "How to manage Hot Streak procs",
                type = "dropdown",
                options = {"Delay with Heating Up", "Always Instant", "Pool for Combustion"},
                default = "Delay with Heating Up"
            },
            fireBlastStrategy = {
                displayName = "Fire Blast Strategy",
                description = "How to use Fire Blast charges",
                type = "dropdown",
                options = {"On Heating Up", "On Cooldown", "Save for Combustion"},
                default = "On Heating Up"
            },
            phoenixFlamesStrategy = {
                displayName = "Phoenix Flames Strategy",
                description = "How to use Phoenix Flames charges",
                type = "dropdown",
                options = {"On Heating Up", "On Cooldown", "AoE Only", "Save for Combustion"},
                default = "On Heating Up"
            }
        },
        
        cooldownSettings = {
            useCombustion = {
                displayName = "Use Combustion",
                description = "Automatically use Combustion",
                type = "toggle",
                default = true
            },
            useRuneOfPower = {
                displayName = "Use Rune of Power",
                description = "Automatically use Rune of Power",
                type = "toggle",
                default = true
            },
            runeOfPowerWithCombustion = {
                displayName = "Rune of Power with Combustion",
                description = "Save Rune of Power for Combustion",
                type = "toggle",
                default = true
            },
            useMeteor = {
                displayName = "Use Meteor",
                description = "Automatically use Meteor when talented",
                type = "toggle",
                default = true
            },
            meteorUsage = {
                displayName = "Meteor Usage",
                description = "When to use Meteor",
                type = "dropdown",
                options = {"With Combustion", "On Cooldown", "AoE Only"},
                default = "With Combustion"
            },
            useShiftingPower = {
                displayName = "Use Shifting Power",
                description = "Automatically use Shifting Power when talented",
                type = "toggle",
                default = true
            },
            shiftingPowerUsage = {
                displayName = "Shifting Power Usage",
                description = "When to use Shifting Power",
                type = "dropdown",
                options = {"After Combustion", "On Cooldown", "Never in Combustion"},
                default = "After Combustion"
            }
        },
        
        defensiveSettings = {
            useBlazingBarrier = {
                displayName = "Use Blazing Barrier",
                description = "Automatically use Blazing Barrier",
                type = "toggle",
                default = true
            },
            blazingBarrierThreshold = {
                displayName = "Blazing Barrier Health Threshold",
                description = "Health percentage to use Blazing Barrier",
                type = "slider",
                min = 50,
                max = 100,
                default = 90
            },
            useIceBlock = {
                displayName = "Use Ice Block",
                description = "Automatically use Ice Block",
                type = "toggle",
                default = true
            },
            iceBlockThreshold = {
                displayName = "Ice Block Health Threshold",
                description = "Health percentage to use Ice Block",
                type = "slider",
                min = 10,
                max = 50,
                default = 20
            },
            useAlterTime = {
                displayName = "Use Alter Time",
                description = "Automatically use Alter Time",
                type = "toggle",
                default = true
            },
            alterTimeThreshold = {
                displayName = "Alter Time Health Threshold",
                description = "Health percentage to use Alter Time",
                type = "slider",
                min = 20,
                max = 70,
                default = 40
            },
            useGreaterInvisibility = {
                displayName = "Use Greater Invisibility",
                description = "Automatically use Greater Invisibility",
                type = "toggle",
                default = true
            },
            greaterInvisibilityThreshold = {
                displayName = "Greater Invisibility Health Threshold",
                description = "Health percentage to use Greater Invisibility",
                type = "slider",
                min = 10,
                max = 40,
                default = 25
            }
        },
        
        utilitySettings = {
            useCounterspell = {
                displayName = "Use Counterspell",
                description = "Automatically use Counterspell to interrupt",
                type = "toggle",
                default = true
            },
            useDragonsBreath = {
                displayName = "Use Dragon's Breath",
                description = "Automatically use Dragon's Breath for crowd control",
                type = "toggle",
                default = true
            },
            useFrostNova = {
                displayName = "Use Frost Nova",
                description = "Automatically use Frost Nova",
                type = "toggle",
                default = true
            },
            useBlinkDefensively = {
                displayName = "Use Blink/Shimmer Defensively",
                description = "Automatically use Blink/Shimmer to escape",
                type = "toggle",
                default = true
            },
            useArcaneIntellect = {
                displayName = "Use Arcane Intellect",
                description = "Automatically maintain Arcane Intellect",
                type = "toggle",
                default = true
            },
            useSpellsteal = {
                displayName = "Use Spellsteal",
                description = "Automatically use Spellsteal on valuable buffs",
                type = "toggle",
                default = true
            },
            useRemoveCurse = {
                displayName = "Use Remove Curse",
                description = "Automatically use Remove Curse",
                type = "toggle",
                default = true
            }
        },
        
        aoeSettings = {
            useFlamestrike = {
                displayName = "Use Flamestrike",
                description = "Use Flamestrike during AoE",
                type = "toggle",
                default = true
            },
            flamestrikeStrategy = {
                displayName = "Flamestrike Strategy",
                description = "When to use Flamestrike with Hot Streak",
                type = "dropdown",
                options = {"Always in AoE", "Only with 4+ targets", "Never"},
                default = "Always in AoE"
            },
            useLivingBomb = {
                displayName = "Use Living Bomb",
                description = "Automatically use Living Bomb when talented",
                type = "toggle",
                default = true
            },
            livingBombThreshold = {
                displayName = "Living Bomb Target Threshold",
                description = "Minimum targets to use Living Bomb",
                type = "slider",
                min = 3,
                max = 8,
                default = 4
            },
            useBlastWave = {
                displayName = "Use Blast Wave",
                description = "Automatically use Blast Wave when talented",
                type = "toggle",
                default = true
            },
            blastWaveThreshold = {
                displayName = "Blast Wave Target Threshold",
                description = "Minimum targets to use Blast Wave",
                type = "slider",
                min = 2,
                max = 6,
                default = 3
            }
        },
        
        -- Advanced ability control settings
        abilityControls = {
            -- Combustion controls
            combustion = AAC.RegisterAbility(spells.COMBUSTION, {
                enabled = true,
                useDuringBurstOnly = true,
                requireRuneOfPower = false,
                minHotStreaksInCombustion = 5
            }),
            
            -- Rune of Power controls
            runeOfPower = AAC.RegisterAbility(spells.RUNE_OF_POWER, {
                enabled = true,
                useDuringBurstOnly = false,
                saveForCombustion = true,
                minChargesHeld = 1
            }),
            
            -- Meteor controls
            meteor = AAC.RegisterAbility(spells.METEOR, {
                enabled = true,
                useDuringBurstOnly = false,
                useDuringCombustion = true,
                minTargets = 1
            })
        }
    })
    
    return true
end

-- Register for events 
function Fire:RegisterEvents()
    -- Register for combat log events to track procs and buffs
    API.RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", function(...) 
        self:HandleCombatLogEvent(...) 
    end)
    
    -- Register for mana updates
    API.RegisterEvent("UNIT_POWER_FREQUENT", function(unit, powerType) 
        if unit == "player" and powerType == "MANA" then
            self:UpdateMana()
        end
    end)
    
    -- Register for haste updates
    API.RegisterEvent("UNIT_STATS", function(unit) 
        if unit == "player" then
            self:UpdateHaste()
        end
    end)
    
    -- Register for target change events
    API.RegisterEvent("PLAYER_TARGET_CHANGED", function() 
        self:UpdateTargetData() 
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
    
    return true
end

-- Update talent information
function Fire:UpdateTalentInfo()
    -- Check for important talents
    talents.hasSoulburn = API.HasTalent(spells.SOULBURN)
    talents.hasManaReserves = API.HasTalent(spells.MANA_RESERVES)
    talents.hasMeteorStrike = API.HasTalent(spells.METEOR_STRIKE)
    talents.hasImprovedScorch = API.HasTalent(spells.IMPROVED_SCORCH)
    talents.hasSearingTouch = API.HasTalent(spells.SEARING_TOUCH)
    talents.hasAlexstraszasFury = API.HasTalent(spells.ALEXSTRASZAS_FURY)
    talents.hasPhoenixFlames = API.HasTalent(spells.PHOENIX_FLAMES)
    talents.hasMasterOfElements = API.HasTalent(spells.MASTER_OF_ELEMENTS)
    talents.hasPhoenixReborn = API.HasTalent(spells.PHOENIX_REBORN)
    talents.hasFlameCannon = API.HasTalent(spells.FLAME_CANNON)
    talents.hasControlledDestruction = API.HasTalent(spells.CONTROLLED_DESTRUCTION)
    talents.hasKindling = API.HasTalent(spells.KINDLING)
    talents.hasFlowOfTime = API.HasTalent(spells.FLOW_OF_TIME)
    talents.hasFromTheAshes = API.HasTalent(spells.FROM_THE_ASHES)
    talents.hasFireStarter = API.HasTalent(spells.FIRESTARTER)
    talents.hasFeveredIncantation = API.HasTalent(spells.FEVERED_INCANTATION)
    talents.hasPyroclasm = API.HasTalent(spells.PYROCLASM)
    talents.hasFlamePatch = API.HasTalent(spells.FLAME_PATCH)
    talents.hasFireAndIce = API.HasTalent(spells.FIRE_AND_ICE)
    talents.hasFlamingMind = API.HasTalent(spells.FLAMING_MIND)
    talents.hasPyromaniac = API.HasTalent(spells.PYROMANIAC)
    talents.hasFeelTheBurn = API.HasTalent(spells.FEEL_THE_BURN)
    talents.hasFlamingShackles = API.HasTalent(spells.FLAMING_SHACKLES)
    talents.hasFuelTheFire = API.HasTalent(spells.FUEL_THE_FIRE)
    talents.hasIgnitionPoint = API.HasTalent(spells.IGNITION_POINT)
    talents.hasTemporalWarp = API.HasTalent(spells.TEMPORAL_WARP)
    
    -- War Within Season 2 talents
    talents.hasArcaneEcho = API.HasTalent(spells.ARCANE_ECHO)
    talents.hasArcaneTempest = API.HasTalent(spells.ARCANE_TEMPEST)
    talents.hasArcaneVigilance = API.HasTalent(spells.ARCANE_VIGILANCE)
    talents.hasBlazingSoul = API.HasTalent(spells.BLAZING_SOUL)
    talents.hasDragonrage = API.HasTalent(spells.DRAGONRAGE)
    talents.hasFlameOfAlacrity = API.HasTalent(spells.FLAME_OF_ALACRITY)
    talents.hasHyperborean = API.HasTalent(spells.HYPERBOREAN)
    talents.hasHyperthermia = API.HasTalent(spells.HYPERTHERMIA)
    talents.hasIceFlows = API.HasTalent(spells.ICE_FLOWS)
    talents.hasInfernalCascade = API.HasTalent(spells.INFERNAL_CASCADE)
    talents.hasMeteorStrike = API.HasTalent(spells.METEOR_STRIKE)
    talents.hasManaReserves = API.HasTalent(spells.MANA_RESERVES)
    talents.hasRuneSurge = API.HasTalent(spells.RUNE_SURGE)
    talents.hasSoulburn = API.HasTalent(spells.SOULBURN)
    
    -- Set specialized variables based on talents
    if talents.hasSoulburn then
        soulburn = true
    end
    
    if talents.hasManaReserves then
        manaReserves = true
    end
    
    if talents.hasMeteorStrike then
        meteorStrike = true
    end
    
    if talents.hasImprovedScorch then
        improvedScorch = true
    end
    
    if talents.hasSearingTouch then
        searingTouch = true
    end
    
    if talents.hasAlexstraszasFury then
        alexstraszasFury = true
    end
    
    if talents.hasPhoenixFlames then
        phoenixFlames = true
    end
    
    if talents.hasMasterOfElements then
        masterOfElements = true
    end
    
    if talents.hasPhoenixReborn then
        phoenixReborn = true
    end
    
    if talents.hasFlameCannon then
        flameCannon = true
    end
    
    if talents.hasControlledDestruction then
        controlledDestruction = true
    end
    
    if talents.hasKindling then
        kindling = true
    end
    
    if talents.hasFlowOfTime then
        flowOfTime = true
    end
    
    if talents.hasFromTheAshes then
        fromTheAshes = true
    end
    
    if talents.hasFireStarter then
        fireStarter = true
    end
    
    if talents.hasFlamePatch then
        flamePatch = true
    end
    
    if talents.hasFireAndIce then
        fireAndIce = true
    end
    
    if talents.hasFlamingMind then
        flamingMind = true
    end
    
    if talents.hasPyromaniac then
        pyromaniac = true
    end
    
    if talents.hasFeelTheBurn then
        feelTheBurn = true
    end
    
    if talents.hasFlamingShackles then
        flamingShackles = true
    end
    
    if talents.hasFuelTheFire then
        fuelTheFire = true
    end
    
    if talents.hasIgnitionPoint then
        ignitionPoint = true
    end
    
    if talents.hasTemporalWarp then
        temporalWarp = true
    end
    
    -- Initialize ability charges
    fireBlastCharges = API.GetSpellCharges(spells.FIRE_BLAST) or 0
    fireBlastMaxCharges = API.GetSpellMaxCharges(spells.FIRE_BLAST) or 2
    
    if phoenixFlames then
        phoenixFlamesCharges = API.GetSpellCharges(spells.PHOENIX_FLAMES) or 0
        phoenixFlamesMaxCharges = API.GetSpellMaxCharges(spells.PHOENIX_FLAMES) or 2
    end
    
    runeOfPowerCharges = API.GetSpellCharges(spells.RUNE_OF_POWER) or 0
    
    -- Update haste %
    self:UpdateHaste()
    
    API.PrintDebug("Fire Mage talents updated")
    
    return true
end

-- Update mana tracking
function Fire:UpdateMana()
    currentMana = API.GetPlayerMana()
    maxMana = API.GetPlayerMaxMana()
    return true
end

-- Update haste tracking
function Fire:UpdateHaste()
    playerHastePercent = API.GetPlayerHaste()
    totalHaste = playerHastePercent
    return true
end

-- Update target data
function Fire:UpdateTargetData()
    -- Check if in range for Fire Blast (most important ability to check range for)
    inFireBlastRange = API.IsSpellInRange(spells.FIRE_BLAST, "target")
    
    -- Get target health to determine if we should use Searing Touch or Firestarter
    local targetHealth = API.GetTargetHealthPercent() or 100
    
    -- Check for Firestarter phase (if talented)
    if fireStarter and targetHealth >= FIRESTARTER_THRESHOLD then
        firestarterActive = true
    else
        firestarterActive = false
    end
    
    -- Check for Scorch phase (if talented with Searing Touch)
    if searingTouch and targetHealth <= SEARING_TOUCH_THRESHOLD then
        scorchPhaseActive = true
    else
        scorchPhaseActive = false
    end
    
    -- Update AoE targets count
    currentAoETargets = API.GetNearbyEnemiesCount(12) -- Flamestrike radius
    
    -- Check for ignite on target
    if API.UnitExists("target") then
        local igniteDebuff = API.GetDebuffInfo("target", debuffs.IGNITE)
        igniteActive = igniteDebuff ~= nil
    else
        igniteActive = false
    end
    
    -- Check for Living Bomb on target
    if API.UnitExists("target") then
        local livingBombDebuff = API.GetDebuffInfo("target", debuffs.LIVING_BOMB)
        if livingBombDebuff then
            livingBombActive = true
            livingBombEndTime = select(6, livingBombDebuff)
        else
            livingBombActive = false
            livingBombEndTime = 0
        end
    else
        livingBombActive = false
        livingBombEndTime = 0
    end
    
    -- Check for Flame Patch on target
    if flamePatch and API.UnitExists("target") then
        local flamePatchDistance = API.GetDistanceToUnit("target")
        flamePatchActive = flamePatchDistance and flamePatchDistance < 8 -- Within Flamestrike radius
    else
        flamePatchActive = false
    end
    
    return true
end

-- Handle combat log events
function Fire:HandleCombatLogEvent(...)
    local timestamp, eventType, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, spellID, spellName = CombatLogGetCurrentEventInfo()
    
    -- Track buff applications
    if eventType == "SPELL_AURA_APPLIED" or eventType == "SPELL_AURA_REFRESH" then
        -- Track player buffs
        if destGUID == API.GetPlayerGUID() then
            -- Track Combustion
            if spellID == buffs.COMBUSTION then
                combustionActive = true
                combustionEndTime = GetTime() + COMBUSTION_DURATION
                API.PrintDebug("Combustion activated")
            end
            
            -- Track Hot Streak
            if spellID == buffs.HOT_STREAK then
                hotStreakActive = true
                hotStreakEndTime = GetTime() + 15 -- Typically doesn't have a duration but keeping for consistency
                API.PrintDebug("Hot Streak activated")
            end
            
            -- Track Heating Up
            if spellID == buffs.HEATING_UP then
                heatingUpActive = true
                heatingUpEndTime = GetTime() + 10 -- Typically lasts 10 seconds
                API.PrintDebug("Heating Up activated")
            end
            
            -- Track Pyroclasm
            if spellID == buffs.PYROCLASM then
                pyroclasm = true
                pyroclasmsStacks = select(4, API.GetBuffInfo("player", buffs.PYROCLASM)) or 1
                pyroclasmsEndTime = select(6, API.GetBuffInfo("player", buffs.PYROCLASM))
                API.PrintDebug("Pyroclasm activated: " .. tostring(pyroclasmsStacks) .. " stacks")
            end
            
            -- Track Rune of Power
            if spellID == buffs.RUNE_OF_POWER then
                runeOfPowerActive = true
                runeOfPowerEndTime = GetTime() + RUNE_OF_POWER_DURATION
                API.PrintDebug("Rune of Power activated")
            end
            
            -- Track Arcane Power (can be gained from certain procs in some talents)
            if spellID == buffs.ARCANE_POWER then
                arcanePowerActive = true
                arcanePowerEndTime = GetTime() + ARCANE_POWER_DURATION
                API.PrintDebug("Arcane Power activated")
            end
            
            -- Track Sun King's Blessing
            if spellID == buffs.SUN_KINGS_BLESSING then
                sunKingsActive = true
                sunKingsStacks = select(4, API.GetBuffInfo("player", buffs.SUN_KINGS_BLESSING)) or 1
                API.PrintDebug("Sun King's Blessing activated: " .. tostring(sunKingsStacks) .. " stacks")
            end
            
            -- Track Infernal Cascade
            if spellID == buffs.INFERNAL_CASCADE then
                infernalCascadeActive = true
                infernalCascadeStacks = select(4, API.GetBuffInfo("player", buffs.INFERNAL_CASCADE)) or 1
                infernalCascadeEndTime = select(6, API.GetBuffInfo("player", buffs.INFERNAL_CASCADE))
                API.PrintDebug("Infernal Cascade activated: " .. tostring(infernalCascadeStacks) .. " stacks")
            end
            
            -- Track Fevered Incantation
            if spellID == buffs.FEVERED_INCANTATION then
                feveredIncantation = true
                feveredIncantationStacks = select(4, API.GetBuffInfo("player", buffs.FEVERED_INCANTATION)) or 1
                feveredIncantationEndTime = select(6, API.GetBuffInfo("player", buffs.FEVERED_INCANTATION))
                API.PrintDebug("Fevered Incantation activated: " .. tostring(feveredIncantationStacks) .. " stacks")
            end
            
            -- Track Blazing Barrier
            if spellID == buffs.BLAZING_BARRIER then
                API.PrintDebug("Blazing Barrier activated")
            end
            
            -- Track Hyperthermia
            if spellID == buffs.HYPERTHERMIA then
                hyperthermiaActive = true
                hyperthermiaStacks = select(4, API.GetBuffInfo("player", buffs.HYPERTHERMIA)) or 1
                API.PrintDebug("Hyperthermia activated: " .. tostring(hyperthermiaStacks) .. " stacks")
            end
        end
        
        -- Track Ignite application on any target
        if spellID == debuffs.IGNITE and sourceGUID == API.GetPlayerGUID() then
            if destGUID == API.GetTargetGUID() then
                igniteActive = true
            end
            API.PrintDebug("Ignite applied to " .. destName)
        end
        
        -- Track Living Bomb application
        if spellID == debuffs.LIVING_BOMB and sourceGUID == API.GetPlayerGUID() then
            if destGUID == API.GetTargetGUID() then
                livingBombActive = true
                livingBombEndTime = GetTime() + LIVING_BOMB_DURATION
            end
            API.PrintDebug("Living Bomb applied to " .. destName)
        end
    end
    
    -- Track buff removals
    if eventType == "SPELL_AURA_REMOVED" then
        -- Track player buff removals
        if destGUID == API.GetPlayerGUID() then
            -- Track Combustion
            if spellID == buffs.COMBUSTION then
                combustionActive = false
                API.PrintDebug("Combustion faded")
            end
            
            -- Track Hot Streak
            if spellID == buffs.HOT_STREAK then
                hotStreakActive = false
                API.PrintDebug("Hot Streak consumed")
            end
            
            -- Track Heating Up
            if spellID == buffs.HEATING_UP then
                heatingUpActive = false
                API.PrintDebug("Heating Up faded")
            end
            
            -- Track Pyroclasm
            if spellID == buffs.PYROCLASM then
                pyroclasm = false
                pyroclasmsStacks = 0
                API.PrintDebug("Pyroclasm faded")
            end
            
            -- Track Rune of Power
            if spellID == buffs.RUNE_OF_POWER then
                runeOfPowerActive = false
                API.PrintDebug("Rune of Power faded")
            end
            
            -- Track Arcane Power
            if spellID == buffs.ARCANE_POWER then
                arcanePowerActive = false
                API.PrintDebug("Arcane Power faded")
            end
            
            -- Track Sun King's Blessing
            if spellID == buffs.SUN_KINGS_BLESSING then
                sunKingsActive = false
                sunKingsStacks = 0
                API.PrintDebug("Sun King's Blessing faded")
            end
            
            -- Track Infernal Cascade
            if spellID == buffs.INFERNAL_CASCADE then
                infernalCascadeActive = false
                infernalCascadeStacks = 0
                API.PrintDebug("Infernal Cascade faded")
            end
            
            -- Track Fevered Incantation
            if spellID == buffs.FEVERED_INCANTATION then
                feveredIncantation = false
                feveredIncantationStacks = 0
                API.PrintDebug("Fevered Incantation faded")
            end
            
            -- Track Hyperthermia
            if spellID == buffs.HYPERTHERMIA then
                hyperthermiaActive = false
                hyperthermiaStacks = 0
                API.PrintDebug("Hyperthermia faded")
            end
        end
        
        -- Track Ignite removal
        if spellID == debuffs.IGNITE and destGUID == API.GetTargetGUID() then
            igniteActive = false
            API.PrintDebug("Ignite faded from " .. destName)
        end
        
        -- Track Living Bomb removal
        if spellID == debuffs.LIVING_BOMB and destGUID == API.GetTargetGUID() then
            livingBombActive = false
            API.PrintDebug("Living Bomb detonated on " .. destName)
        end
    end
    
    -- Track buff stack changes
    if eventType == "SPELL_AURA_APPLIED_DOSE" then
        if destGUID == API.GetPlayerGUID() then
            -- Track Sun King's Blessing stacks
            if spellID == buffs.SUN_KINGS_BLESSING then
                sunKingsStacks = select(4, API.GetBuffInfo("player", buffs.SUN_KINGS_BLESSING)) or 0
                API.PrintDebug("Sun King's Blessing stacks: " .. tostring(sunKingsStacks))
            end
            
            -- Track Infernal Cascade stacks
            if spellID == buffs.INFERNAL_CASCADE then
                infernalCascadeStacks = select(4, API.GetBuffInfo("player", buffs.INFERNAL_CASCADE)) or 0
                API.PrintDebug("Infernal Cascade stacks: " .. tostring(infernalCascadeStacks))
            end
            
            -- Track Fevered Incantation stacks
            if spellID == buffs.FEVERED_INCANTATION then
                feveredIncantationStacks = select(4, API.GetBuffInfo("player", buffs.FEVERED_INCANTATION)) or 0
                API.PrintDebug("Fevered Incantation stacks: " .. tostring(feveredIncantationStacks))
            end
            
            -- Track Pyroclasm stacks
            if spellID == buffs.PYROCLASM then
                pyroclasmsStacks = select(4, API.GetBuffInfo("player", buffs.PYROCLASM)) or 0
                API.PrintDebug("Pyroclasm stacks: " .. tostring(pyroclasmsStacks))
            end
            
            -- Track Hyperthermia stacks
            if spellID == buffs.HYPERTHERMIA then
                hyperthermiaStacks = select(4, API.GetBuffInfo("player", buffs.HYPERTHERMIA)) or 0
                API.PrintDebug("Hyperthermia stacks: " .. tostring(hyperthermiaStacks))
            end
        end
    end
    
    -- Track spell casts
    if eventType == "SPELL_CAST_SUCCESS" then
        if sourceGUID == API.GetPlayerGUID() then
            -- Track Fire Blast usage
            if spellID == spells.FIRE_BLAST then
                fireBlastCharges = API.GetSpellCharges(spells.FIRE_BLAST) or 0
                API.PrintDebug("Fire Blast cast, charges remaining: " .. tostring(fireBlastCharges))
            end
            
            -- Track Phoenix Flames usage
            if spellID == spells.PHOENIX_FLAMES then
                phoenixFlamesCharges = API.GetSpellCharges(spells.PHOENIX_FLAMES) or 0
                API.PrintDebug("Phoenix Flames cast, charges remaining: " .. tostring(phoenixFlamesCharges))
            end
            
            -- Track Combustion
            if spellID == spells.COMBUSTION then
                combustionActive = true
                combustionEndTime = GetTime() + COMBUSTION_DURATION
                API.PrintDebug("Combustion cast")
            end
            
            -- Track Rune of Power
            if spellID == spells.RUNE_OF_POWER then
                runeOfPowerCharges = API.GetSpellCharges(spells.RUNE_OF_POWER) or 0
                runeOfPowerActive = true
                runeOfPowerEndTime = GetTime() + RUNE_OF_POWER_DURATION
                runeOfPowerX, runeOfPowerY, runeOfPowerZ = API.GetPlayerPosition()
                API.PrintDebug("Rune of Power cast, charges remaining: " .. tostring(runeOfPowerCharges))
            end
            
            -- Track Meteor
            if spellID == spells.METEOR then
                meteorPending = true
                meteorImpactTime = GetTime() + METEOR_DELAY
                
                -- Reset after impact delay
                C_Timer.After(METEOR_DELAY, function()
                    meteorPending = false
                    API.PrintDebug("Meteor has impacted")
                end)
                
                API.PrintDebug("Meteor cast, impact in " .. tostring(METEOR_DELAY) .. " seconds")
            end
            
            -- Track Shifting Power
            if spellID == spells.SHIFTING_POWER then
                shiftingPowerChanneling = true
                shiftingPowerEndTime = GetTime() + SHIFTING_POWER_CHANNEL_TIME
                
                -- Reset after channel finishes
                C_Timer.After(SHIFTING_POWER_CHANNEL_TIME, function()
                    shiftingPowerChanneling = false
                    API.PrintDebug("Shifting Power channel complete")
                end)
                
                API.PrintDebug("Shifting Power channel started")
            end
            
            -- Track Living Bomb
            if spellID == spells.LIVING_BOMB then
                livingBombActive = true
                livingBombEndTime = GetTime() + LIVING_BOMB_DURATION
                API.PrintDebug("Living Bomb cast")
            end
            
            -- Track Blast Wave
            if spellID == spells.BLAST_WAVE then
                blastWaveReady = false
                blastWaveEndTime = GetTime() + API.GetSpellCooldown(spells.BLAST_WAVE)
                API.PrintDebug("Blast Wave cast")
            end
            
            -- Track Flamestrike for potential Flame Patch tracking
            if spellID == spells.FLAMESTRIKE and flamePatch then
                flamePatchActive = true
                flamePatchEndTime = GetTime() + FLAME_PATCH_DURATION
                API.PrintDebug("Flamestrike cast with Flame Patch")
            end
        end
    end
    
    -- Track critical hits for Heating Up and Hot Streak
    if (eventType == "SPELL_DAMAGE" or eventType == "SPELL_PERIODIC_DAMAGE") and sourceGUID == API.GetPlayerGUID() then
        local critical = select(21, ...)
        if critical then
            -- This counts for Kindling (Combustion CD reduction)
            if kindling and (spellID == spells.FIREBALL or 
                           spellID == spells.PYROBLAST or 
                           spellID == spells.FIRE_BLAST or 
                           spellID == spells.SCORCH or 
                           spellID == spells.PHOENIX_FLAMES) then
                API.PrintDebug("Critical hit with " .. spellName .. " (Kindling proc)")
            end
        end
    end
    
    return true
end

-- Handle spell cast succeeded (different from SPELL_CAST_SUCCESS combat log event)
function Fire:HandleSpellCastSucceeded(spellID)
    -- Update charge tracking for important abilities
    if spellID == spells.FIRE_BLAST then
        fireBlastCharges = API.GetSpellCharges(spells.FIRE_BLAST) or 0
    elseif spellID == spells.PHOENIX_FLAMES then
        phoenixFlamesCharges = API.GetSpellCharges(spells.PHOENIX_FLAMES) or 0
    elseif spellID == spells.RUNE_OF_POWER then
        runeOfPowerCharges = API.GetSpellCharges(spells.RUNE_OF_POWER) or 0
    end
    
    return true
end

-- Main rotation function
function Fire:RunRotation()
    -- Check if we should be running Fire Mage logic
    if API.GetActiveSpecID() ~= FIRE_SPEC_ID then
        return false
    end
    
    -- Skip rotation if player is casting or channeling
    if API.IsPlayerCasting() or shiftingPowerChanneling then
        return false
    end
    
    -- Get settings
    local settings = ConfigRegistry:GetSettings("FireMage")
    
    -- Update variables
    self:UpdateMana()
    burstModeActive = settings.rotationSettings.burstEnabled and API.ShouldUseBurst()
    self:UpdateTargetData() -- Makes sure we have current target information
    
    -- Handle next cast override
    if nextCastOverride and API.CanCast(nextCastOverride) then
        local spell = nextCastOverride
        nextCastOverride = nil
        API.CastSpell(spell)
        return true
    end
    
    -- Maintain Arcane Intellect
    if settings.utilitySettings.useArcaneIntellect and
       not API.PlayerHasBuff(spells.ARCANE_INTELLECT) and
       API.CanCast(spells.ARCANE_INTELLECT) then
        API.CastSpell(spells.ARCANE_INTELLECT)
        return true
    end
    
    -- Handle interrupts
    if self:HandleInterrupts(settings) then
        return true
    end
    
    -- Handle defensive abilities
    if self:HandleDefensives(settings) then
        return true
    end
    
    -- Skip if not in range
    if not inFireBlastRange then
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
function Fire:HandleInterrupts(settings)
    -- Only attempt to interrupt if enabled and in range
    if settings.utilitySettings.useCounterspell and API.CanCast(spells.COUNTERSPELL) and API.TargetIsSpellCastable() then
        API.CastSpell(spells.COUNTERSPELL)
        return true
    end
    
    return false
end

-- Handle defensive abilities
function Fire:HandleDefensives(settings)
    local playerHealth = API.GetPlayerHealthPercent()
    
    -- Use Blazing Barrier
    if settings.defensiveSettings.useBlazingBarrier and
       playerHealth <= settings.defensiveSettings.blazingBarrierThreshold and
       not API.PlayerHasBuff(buffs.BLAZING_BARRIER) and
       API.CanCast(spells.BLAZING_BARRIER) then
        API.CastSpell(spells.BLAZING_BARRIER)
        return true
    end
    
    -- Use Ice Block
    if settings.defensiveSettings.useIceBlock and
       playerHealth <= settings.defensiveSettings.iceBlockThreshold and
       API.CanCast(spells.ICE_BLOCK) then
        API.CastSpell(spells.ICE_BLOCK)
        return true
    end
    
    -- Use Alter Time
    if settings.defensiveSettings.useAlterTime and
       playerHealth <= settings.defensiveSettings.alterTimeThreshold and
       API.CanCast(spells.ALTER_TIME) then
        API.CastSpell(spells.ALTER_TIME)
        return true
    end
    
    -- Use Greater Invisibility
    if settings.defensiveSettings.useGreaterInvisibility and
       playerHealth <= settings.defensiveSettings.greaterInvisibilityThreshold and
       API.CanCast(spells.GREATER_INVISIBILITY) then
        API.CastSpell(spells.GREATER_INVISIBILITY)
        return true
    end
    
    return false
end

-- Handle cooldown abilities
function Fire:HandleCooldowns(settings)
    -- Skip cooldowns if not in burst mode or not in combat
    if not API.IsInCombat() then
        return false
    }
    
    -- Use Rune of Power
    if settings.cooldownSettings.useRuneOfPower and
       settings.abilityControls.runeOfPower.enabled and
       not runeOfPowerActive and
       runeOfPowerCharges > settings.abilityControls.runeOfPower.minChargesHeld and
       API.CanCast(spells.RUNE_OF_POWER) and
       (not settings.abilityControls.runeOfPower.useDuringBurstOnly or burstModeActive) then
        
        -- Check if we should save for Combustion
        if settings.cooldownSettings.runeOfPowerWithCombustion and 
           settings.abilityControls.runeOfPower.saveForCombustion and 
           API.GetSpellCooldown(spells.COMBUSTION) < 10 and 
           not combustionActive then
            -- Save for Combustion
        else
            API.CastSpellAtFeet(spells.RUNE_OF_POWER)
            return true
        end
    end
    
    -- Use Combustion if appropriate conditions are met
    if settings.cooldownSettings.useCombustion and
       settings.abilityControls.combustion.enabled and
       not combustionActive and
       API.CanCast(spells.COMBUSTION) and
       (not settings.abilityControls.combustion.useDuringBurstOnly or burstModeActive) then
        
        -- Check if we should require Rune of Power
        if settings.abilityControls.combustion.requireRuneOfPower and not runeOfPowerActive then
            -- Wait for Rune of Power
        else
            API.CastSpell(spells.COMBUSTION)
            return true
        end
    end
    
    -- Use Meteor
    if settings.cooldownSettings.useMeteor and
       settings.abilityControls.meteor.enabled and
       API.CanCast(spells.METEOR) and
       (not settings.abilityControls.meteor.useDuringBurstOnly or burstModeActive) then
        
        -- Check meteor usage strategy
        local shouldUseMeteor = false
        
        if settings.cooldownSettings.meteorUsage == "With Combustion" then
            shouldUseMeteor = combustionActive
        elseif settings.cooldownSettings.meteorUsage == "On Cooldown" then
            shouldUseMeteor = true
        elseif settings.cooldownSettings.meteorUsage == "AoE Only" then
            shouldUseMeteor = currentAoETargets >= settings.abilityControls.meteor.minTargets
        end
        
        if shouldUseMeteor then
            API.CastSpellAtCursor(spells.METEOR)
            return true
        end
    end
    
    -- Use Shifting Power 
    if settings.cooldownSettings.useShiftingPower and 
       API.CanCast(spells.SHIFTING_POWER) then
        
        -- Check shifting power usage strategy
        local shouldUseShiftingPower = false
        
        if settings.cooldownSettings.shiftingPowerUsage == "After Combustion" then
            shouldUseShiftingPower = not combustionActive and API.GetSpellCooldown(spells.COMBUSTION) > 20
        elseif settings.cooldownSettings.shiftingPowerUsage == "On Cooldown" then
            shouldUseShiftingPower = true
        elseif settings.cooldownSettings.shiftingPowerUsage == "Never in Combustion" then
            shouldUseShiftingPower = not combustionActive
        end
        
        if shouldUseShiftingPower then
            API.CastSpell(spells.SHIFTING_POWER)
            return true
        end
    end
    
    return false
end

-- Handle AoE rotation
function Fire:HandleAoERotation(settings)
    -- Use Flamestrike with Hot Streak
    if hotStreakActive and settings.aoeSettings.useFlamestrike and API.CanCast(spells.FLAMESTRIKE) then
        local useFlamestrikeHS = false
        
        if settings.aoeSettings.flamestrikeStrategy == "Always in AoE" then
            useFlamestrikeHS = true
        elseif settings.aoeSettings.flamestrikeStrategy == "Only with 4+ targets" and currentAoETargets >= 4 then
            useFlamestrikeHS = true
        end
        
        if useFlamestrikeHS then
            API.CastSpellAtCursor(spells.FLAMESTRIKE)
            return true
        end
    end
    
    -- Use Living Bomb
    if settings.aoeSettings.useLivingBomb and
       not livingBombActive and
       currentAoETargets >= settings.aoeSettings.livingBombThreshold and
       API.CanCast(spells.LIVING_BOMB) then
        API.CastSpell(spells.LIVING_BOMB)
        return true
    end
    
    -- Use Blast Wave
    if settings.aoeSettings.useBlastWave and 
       currentAoETargets >= settings.aoeSettings.blastWaveThreshold and
       API.CanCast(spells.BLAST_WAVE) then
        API.CastSpell(spells.BLAST_WAVE)
        return true
    end
    
    -- Use Dragon's Breath
    if settings.utilitySettings.useDragonsBreath and 
       API.CanCast(spells.DRAGONS_BREATH) then
        API.CastSpell(spells.DRAGONS_BREATH)
        return true
    end
    
    -- Use Fire Blast to convert Heating Up to Hot Streak
    if heatingUpActive and
       fireBlastCharges > 0 and
       API.CanCast(spells.FIRE_BLAST) and
       settings.rotationSettings.fireBlastStrategy == "On Heating Up" then
        API.CastSpell(spells.FIRE_BLAST)
        return true
    end
    
    -- Use Phoenix Flames to generate Hot Streak or for AoE damage
    if phoenixFlames and
       phoenixFlamesCharges > 0 and
       API.CanCast(spells.PHOENIX_FLAMES) and
       (heatingUpActive || settings.rotationSettings.phoenixFlamesStrategy == "AoE Only") then
        API.CastSpell(spells.PHOENIX_FLAMES)
        return true
    end
    
    -- Hard cast Flamestrike in heavy AoE situations
    if currentAoETargets >= 4 and API.CanCast(spells.FLAMESTRIKE) then
        API.CastSpellAtCursor(spells.FLAMESTRIKE)
        return true
    end
    
    -- Fall back to single target rotation if no AoE-specific abilities are available
    if hotStreakActive and API.CanCast(spells.PYROBLAST) then
        API.CastSpell(spells.PYROBLAST)
        return true
    end
    
    -- Use Scorch if in execute range with Searing Touch
    if scorchPhaseActive and API.CanCast(spells.SCORCH) then
        API.CastSpell(spells.SCORCH)
        return true
    end
    
    -- Default to Fireball
    if API.CanCast(spells.FIREBALL) then
        API.CastSpell(spells.FIREBALL)
        return true
    end
    
    return false
end

-- Handle Single Target rotation
function Fire:HandleSingleTargetRotation(settings)
    -- Use Pyroblast with Hot Streak
    if hotStreakActive and API.CanCast(spells.PYROBLAST) then
        -- Check if we should delay usage based on settings
        local useHotStreak = true
        
        if settings.rotationSettings.hotStreakManagement == "Delay with Heating Up" and 
           heatingUpActive and 
           not combustionActive then
            useHotStreak = false
        elseif settings.rotationSettings.hotStreakManagement == "Pool for Combustion" and
               not combustionActive and 
               API.GetSpellCooldown(spells.COMBUSTION) < 5 then
            useHotStreak = false
        end
        
        if useHotStreak then
            API.CastSpell(spells.PYROBLAST)
            return true
        end
    end
    
    -- Use Pyroblast with Pyroclasm (if talented)
    if pyroclasm and pyroclasmsStacks > 0 and API.CanCast(spells.PYROBLAST) then
        API.CastSpell(spells.PYROBLAST)
        return true
    end
    
    -- Use Fire Blast to convert Heating Up to Hot Streak
    if heatingUpActive and
       fireBlastCharges > 0 and
       API.CanCast(spells.FIRE_BLAST) and
       settings.rotationSettings.fireBlastStrategy == "On Heating Up" then
        API.CastSpell(spells.FIRE_BLAST)
        return true
    end
    
    -- Use Phoenix Flames to generate Hot Streak
    if phoenixFlames and
       phoenixFlamesCharges > 0 and
       heatingUpActive and
       API.CanCast(spells.PHOENIX_FLAMES) and
       settings.rotationSettings.phoenixFlamesStrategy == "On Heating Up" then
        API.CastSpell(spells.PHOENIX_FLAMES)
        return true
    end
    
    -- Use Fire Blast during Combustion or on cooldown
    if fireBlastCharges > 0 and API.CanCast(spells.FIRE_BLAST) then
        if (combustionActive || settings.rotationSettings.fireBlastStrategy == "On Cooldown") then
            API.CastSpell(spells.FIRE_BLAST)
            return true
        end
    end
    
    -- Use Phoenix Flames during Combustion or on cooldown
    if phoenixFlames and
       phoenixFlamesCharges > 0 and
       API.CanCast(spells.PHOENIX_FLAMES) then
        if (combustionActive || settings.rotationSettings.phoenixFlamesStrategy == "On Cooldown") then
            API.CastSpell(spells.PHOENIX_FLAMES)
            return true
        end
    end
    
    -- Use Scorch if in execute range with Searing Touch
    if scorchPhaseActive and API.CanCast(spells.SCORCH) then
        API.CastSpell(spells.SCORCH)
        return true
    end
    
    -- Use Firestarter optimized rotation
    if firestarterActive and settings.rotationSettings.useFirestarter then
        -- During Firestarter phase, use the same priority but with appropriate adjustments
        return self:HandleFirestarterRotation()
    end
    
    -- Default to Fireball
    if API.CanCast(spells.FIREBALL) then
        API.CastSpell(spells.FIREBALL)
        return true
    end
    
    return false
end

-- Special handling for Firestarter phase
function Fire:HandleFirestarterRotation()
    -- Firestarter gives guaranteed crits, so we can focus more on direct damage
    
    -- Still use Pyroblast with Hot Streak
    if hotStreakActive and API.CanCast(spells.PYROBLAST) then
        API.CastSpell(spells.PYROBLAST)
        return true
    end
    
    -- With Firestarter, using Fireball directly is often better 
    -- as it will crit and build Hot Streak
    if API.CanCast(spells.FIREBALL) then
        API.CastSpell(spells.FIREBALL)
        return true
    end
    
    return false
end

-- Handle specialization change
function Fire:OnSpecializationChanged()
    -- Update talent information
    self:UpdateTalentInfo()
    
    -- Reset state variables
    nextCastOverride = nil
    burstModeActive = false
    currentAoETargets = 0
    combustionActive = false
    combustionEndTime = 0
    hotStreakActive = false
    hotStreakEndTime = 0
    heatingUpActive = false
    heatingUpEndTime = 0
    firestarterActive = false
    scorchPhaseActive = false
    runeOfPowerActive = false
    runeOfPowerEndTime = 0
    runeOfPowerX, runeOfPowerY, runeOfPowerZ = 0, 0, 0
    runeOfPowerCharges = 0
    arcanePowerActive = false
    arcanePowerEndTime = 0
    blastWaveReady = false
    blastWaveEndTime = 0
    sunKingsActive = false
    sunKingsStacks = 0
    infernalCascadeActive = false
    infernalCascadeStacks = 0
    infernalCascadeEndTime = 0
    fireBlastCharges = 0
    fireBlastMaxCharges = 0
    phoenixFlamesCharges = 0
    phoenixFlamesMaxCharges = 0
    igniteActive = false
    totalHaste = 0
    playerHastePercent = 0
    manaGem = false
    manaGemCharges = 0
    shiftingPowerChanneling = false
    shiftingPowerEndTime = 0
    livingBombActive = false
    livingBombEndTime = 0
    meteorImpactTime = 0
    meteorPending = false
    flamePatchActive = false
    flamePatchEndTime = 0
    hyperthermiaActive = false
    hyperthermiaStacks = 0
    soulburn = false
    manaReserves = false
    meteorStrike = false
    improvedScorch = false
    searingTouch = false
    alexstraszasFury = false
    phoenixFlames = false
    masterOfElements = false
    phoenixReborn = false
    flameCannon = false
    controlledDestruction = false
    kindling = false
    flowOfTime = false
    fromTheAshes = false
    fireStarter = false
    feveredIncantation = false
    feveredIncantationStacks = 0
    feveredIncantationEndTime = 0
    pyroclasm = false
    pyroclasmsStacks = 0
    pyroclasmsEndTime = 0
    flamePatch = false
    fireAndIce = false
    flamingMind = false
    pyromaniac = false
    feelTheBurn = false
    flamingShackles = false
    currentMana = 0
    maxMana = 100
    inFireBlastRange = false
    fuelTheFire = false
    ignitionPoint = true
    temporalWarp = false
    
    API.PrintDebug("Fire Mage state reset on spec change")
    
    return true
end

-- Return the module for loading
return Fire