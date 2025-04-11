------------------------------------------
-- WindrunnerRotations - Havoc Demon Hunter Module
-- Author: VortexQ8
-- The War Within Season 2
------------------------------------------

local Havoc = {}
-- This will be assigned to addon.Classes.DemonHunter.Havoc when loaded

-- These will be set when the file is loaded in our test environment
local API
local ConfigRegistry
local AAC
local DemonHunter

-- Cache frequently accessed data
local spells = {}
local talents = {}
local buffs = {}
local debuffs = {}

-- State tracking variables
local nextCastOverride = nil
local burstModeActive = false
local currentAoETargets = 0
local currentFury = 0
local maxFury = 120
local eyeBeamActive = false
local eyeBeamChannelTime = 0
local eyeBeamChannelEndTime = 0
local metamorphosisActive = false
local metamorphosisEndTime = 0
local momentumActive = false
local momentumEndTime = 0
local immolationAuraActive = false
local immolationAuraEndTime = 0
local felRushCharges = 0
local vengefulRetreatOnCooldown = false
local bladeDanceOnCooldown = false
local chaosStrikeReduced = false
local inMeleeRange = false
local nemesisActive = false
local preparedCharges = 0
local burningWoundStacks = 0
local bladeFlurryActive = false
local felBarrageCharging = false
local unrestrained = false
local unleashHellActive = false
local serratedGlaiveActive = false
local inFelRush = false
local glaiveTempestActive = false
local internalStruggleActive = false
local blindFury = false
local inferredRealityActive = false
local chaosTheoremActive = false
local havocDhDashActive = false
local demonic = false
local trailOfRuin = false
local firstBlood = false
local cycleOfHatred = false
local essenceBreakActive = false
local essenceBreakEndTime = 0
local tacticalRetreatActivated = false
local initiativeBuff = false
local initiativeBuffCount = 0
local restlessHunter = false
local shatteredRestoration = false
local soulRending = false
local chaosFragment = 0
local chaosNovaActive = false
local feltOrchidBuff = false
local feltOrchidStacks = 0

-- Constants
local HAVOC_SPEC_ID = 577
local DEFAULT_AOE_THRESHOLD = 3
local MELEE_RANGE = 5
local METAMORPHOSIS_DURATION = 24 -- in seconds (baseline with no talents)
local MOMENTUM_DURATION = 6 -- in seconds
local IMMOLATION_AURA_DURATION = 6 -- in seconds
local EYE_BEAM_CHANNEL_TIME = 2 -- in seconds (baseline without talents)
local FEL_RUSH_COOLDOWN = 10 -- in seconds (2 charges, 10 sec recharge)
local VENGEFUL_RETREAT_COOLDOWN = 25 -- in seconds
local CHAOS_NOVA_COOLDOWN = 60 -- in seconds
local BLUR_DURATION = 10 -- in seconds
local DARKNESS_DURATION = 8 -- in seconds
local ESSENCE_BREAK_DURATION = 8 -- 8 second debuff
local PREPARED_DURATION = 10 -- in seconds
local METAMORPHOSIS_COOLDOWN = 240 -- in seconds
local THROW_GLAIVE_MAX_BOUNCE = 2 -- default number of bounces

-- Initialize the Havoc module
function Havoc:Initialize()
    self:RegisterSpells()
    self:RegisterVariables()
    self:RegisterSettings()
    self:RegisterEvents()
    
    API.PrintDebug("Havoc Demon Hunter module initialized")
    
    return true
end

-- Register spell IDs
function Havoc:RegisterSpells()
    -- Core rotational abilities
    spells.DEMONS_BITE = 162243
    spells.CHAOS_STRIKE = 162794
    spells.ANNIHILATION = 201427  -- Chaos Strike during Metamorphosis
    spells.BLADE_DANCE = 188499
    spells.DEATH_SWEEP = 210152   -- Blade Dance during Metamorphosis
    spells.EYE_BEAM = 198013
    spells.FEL_RUSH = 195072
    spells.VENGEFUL_RETREAT = 198793
    spells.METAMORPHOSIS = 191427
    spells.THROW_GLAIVE = 185123
    spells.IMMOLATION_AURA = 258920
    spells.CHAOS_NOVA = 179057
    spells.FELBLADE = 232893
    
    -- Defensive and utility abilities
    spells.BLUR = 198589
    spells.DARKNESS = 196718
    spells.NETHERWALK = 196555
    spells.CONSUME_MAGIC = 278326
    spells.DISRUPT = 183752
    spells.IMPRISON = 217832
    spells.SPECTRAL_SIGHT = 188501
    spells.FEL_ERUPTION = 211881
    spells.ARCANE_TORRENT = 202719 -- Blood Elf racial
    
    -- Talents and passives
    spells.MOMENTUM = 206476
    spells.DEMON_BLADES = 203555
    spells.TRAIL_OF_RUIN = 258881
    spells.UNBOUND_CHAOS = 347461
    spells.GLAIVE_TEMPEST = 342817
    spells.ESSENCE_BREAK = 258860
    spells.CYCLE_OF_HATRED = 258887
    spells.DEMONIC = 213410
    spells.BLIND_FURY = 203550
    spells.FIRST_BLOOD = 206416
    spells.DESPERATE_INSTINCTS = 205411
    spells.NETHERWALK = 196555
    spells.BURNING_WOUND = 391189
    spells.INTERNAL_STRUGGLE = 393822
    spells.ANY_MEANS_NECESSARY = 388114
    spells.CHAOS_THEORY = 389687
    spells.INERTIA = 427640
    spells.ISOLATED_PREY = 388113
    spells.INITIATIVE = 388108
    spells.TACTICAL_RETREAT = 389688
    spells.DANCING_WITH_FATE = 389978
    spells.BOUNCING_GLAIVES = 320386
    spells.SERRATED_GLAIVE = 390154
    spells.SOULREND = 388106
    spells.RESTLESS_HUNTER = 390142
    spells.VENGEFUL_RETREAT_BUFF = 198793
    spells.SHATTERED_RESTORATION = 389824
    spells.SOUL_RENDING = 204909
    spells.CHAOS_FRAGMENTS = 320412
    spells.ERRATIC_FELHEART = 391397
    spells.FELT_ORCHID = 389847
    
    -- War Within Season 2 Additions
    spells.INNER_DEMON = 389693
    spells.FURIOUS_GAZE = 343311
    spells.VENGEFUL_BONDS = 320635
    spells.IMPROVED_DISRUPT = 320361
    spells.AURA_OF_PAIN = 207347
    spells.MASTER_OF_THE_GLAIVE = 203556
    spells.MISERY_IN_DEFEAT = 388110
    spells.DISRUPTING_FURY = 391176
    spells.ILLIDARI_KNOWLEDGE = 389696
    spells.RUSH_OF_CHAOS = 320421
    spells.UNNATURAL_MALICE = 389811
    spells.CHAOS_NOVA_EMPOWERMENT = 320413
    spells.IMPROVED_CHAOS_STRIKE = 343206
    spells.CHARRED_WARBLADES = 213010
    spells.ISOLATED_AGGRESSION = 390142
    spells.RAGEFIRE = 390158
    spells.PRECISE_VIOLENCE = 320374
    spells.FEL_BARRAGE = 258925
    
    -- Glyph/build specific
    spells.DEMON_FORM = 210607 -- Metamorphosis variant, visually different
    
    -- Covenant abilities (for reference, may not be current)
    spells.ELYSIAN_DECREE = 306830
    spells.THE_HUNT = 323639
    spells.FODDER_TO_THE_FLAME = 329554
    spells.SINFUL_BRAND = 317009
    
    -- Runeforge legendary effects
    spells.DARKGLARE_MEDALLION = 337534
    spells.ERRATIC_FEL_CORE = 337685
    spells.COLLECTIVE_ANGUISH = 337504
    spells.DARKEST_HOUR = 337539
    
    -- Buff IDs
    spells.METAMORPHOSIS_BUFF = 162264
    spells.MOMENTUM_BUFF = 208628
    spells.IMMOLATION_AURA_BUFF = 258920
    spells.PREPARED_BUFF = 203650
    spells.FURIOUS_GAZE_BUFF = 343312
    spells.CHAOS_BLADES_BUFF = 247938
    spells.NEMESIS_BUFF = 208579
    spells.BLUR_BUFF = 212800
    spells.DARKNESS_BUFF = 196718
    spells.NETHERWALK_BUFF = 196555
    spells.BURNING_WOUND_BUFF = 391191
    spells.INNER_DEMON_BUFF = 337313
    spells.UNBOUND_CHAOS_BUFF = 347462
    spells.INNER_DEMON_BUFF = 389694
    spells.TRAIL_OF_RUIN_BUFF = 258883
    spells.BLADE_FLURRY_BUFF = 391429
    spells.INITIATIVE_BUFF = 388111
    spells.CHAOS_FRAGMENTS_BUFF = 320421
    spells.FELT_ORCHID_BUFF = 389848

    -- Debuff IDs
    spells.ESSENCE_BREAK_DEBUFF = 320338
    spells.SERRATED_GLAIVE_DEBUFF = 390155
    spells.CHAOS_BRAND_DEBUFF = 1490
    
    -- Register all spells with the API tracking system
    for spellName, spellID in pairs(spells) do
        API.RegisterSpell(spellID)
    end
    
    -- Define aura tracking
    buffs.METAMORPHOSIS = spells.METAMORPHOSIS_BUFF
    buffs.MOMENTUM = spells.MOMENTUM_BUFF
    buffs.IMMOLATION_AURA = spells.IMMOLATION_AURA_BUFF
    buffs.PREPARED = spells.PREPARED_BUFF
    buffs.FURIOUS_GAZE = spells.FURIOUS_GAZE_BUFF
    buffs.CHAOS_BLADES = spells.CHAOS_BLADES_BUFF
    buffs.NEMESIS = spells.NEMESIS_BUFF
    buffs.BLUR = spells.BLUR_BUFF
    buffs.DARKNESS = spells.DARKNESS_BUFF
    buffs.NETHERWALK = spells.NETHERWALK_BUFF
    buffs.UNBOUND_CHAOS = spells.UNBOUND_CHAOS_BUFF
    buffs.INNER_DEMON = spells.INNER_DEMON_BUFF
    buffs.TRAIL_OF_RUIN = spells.TRAIL_OF_RUIN_BUFF
    buffs.BLADE_FLURRY = spells.BLADE_FLURRY_BUFF
    buffs.INITIATIVE = spells.INITIATIVE_BUFF
    buffs.CHAOS_FRAGMENTS = spells.CHAOS_FRAGMENTS_BUFF
    buffs.FELT_ORCHID = spells.FELT_ORCHID_BUFF
    
    debuffs.ESSENCE_BREAK = spells.ESSENCE_BREAK_DEBUFF
    debuffs.BURNING_WOUND = spells.BURNING_WOUND_BUFF
    debuffs.SERRATED_GLAIVE = spells.SERRATED_GLAIVE_DEBUFF
    debuffs.CHAOS_BRAND = spells.CHAOS_BRAND_DEBUFF
    
    return true
end

-- Register variables to track
function Havoc:RegisterVariables()
    -- Talent tracking
    talents.hasMomentum = false
    talents.hasDemonBlades = false
    talents.hasTrailOfRuin = false
    talents.hasUnboundChaos = false
    talents.hasGlaiveTempest = false
    talents.hasEssenceBreak = false
    talents.hasCycleOfHatred = false
    talents.hasDemonic = false
    talents.hasBlindFury = false
    talents.hasFirstBlood = false
    talents.hasDesperateInstincts = false
    talents.hasNetherwalk = false
    talents.hasBurningWound = false
    talents.hasInternalStruggle = false
    talents.hasAnyMeansNecessary = false
    talents.hasChaosTheory = false
    talents.hasInertia = false
    talents.hasIsolatedPrey = false
    talents.hasInitiative = false
    talents.hasTacticalRetreat = false
    talents.hasDancingWithFate = false
    talents.hasBouncingGlaives = false
    talents.hasSerratedGlaive = false
    talents.hasSoulrend = false
    talents.hasRestlessHunter = false
    talents.hasShatteredRestoration = false
    talents.hasSoulRending = false
    talents.hasChaosFragments = false
    talents.hasErraticFelheart = false
    talents.hasFeltOrchid = false
    talents.hasInnerDemon = false
    talents.hasFuriousGaze = false
    talents.hasVengefulBonds = false
    talents.hasImprovedDisrupt = false
    talents.hasAuraOfPain = false
    talents.hasMasterOfTheGlaive = false
    talents.hasMiseryInDefeat = false
    talents.hasDisruptingFury = false
    talents.hasIllidariKnowledge = false
    talents.hasRushOfChaos = false
    talents.hasUnnaturalMalice = false
    talents.hasChaosNovaEmpowerment = false
    talents.hasImprovedChaosStrike = false
    talents.hasCharredWarblades = false
    talents.hasIsolatedAggression = false
    talents.hasRagefire = false
    talents.hasPreciseViolence = false
    talents.hasFelBarrage = false
    
    -- Initialize fury
    currentFury = API.GetPlayerPower()
    
    return true
end

-- Register spec-specific settings
function Havoc:RegisterSettings()
    ConfigRegistry:RegisterSettings("HavocDemonHunter", {
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
            holdDemonsBiteInMeta = {
                displayName = "Hold Demon's Bite in Meta",
                description = "Don't use Demon's Bite during Metamorphosis",
                type = "toggle",
                default = true
            },
            useFelRush = {
                displayName = "Use Fel Rush",
                description = "Automatically use Fel Rush for damage",
                type = "toggle",
                default = true
            },
            useVengefulRetreat = {
                displayName = "Use Vengeful Retreat",
                description = "Automatically use Vengeful Retreat for effects",
                type = "toggle",
                default = true
            },
            felRushChargesReserved = {
                displayName = "Reserved Fel Rush Charges",
                description = "Charges to save for movement",
                type = "slider",
                min = 0,
                max = 2,
                default = 1
            }
        },
        
        defensiveSettings = {
            useBlur = {
                displayName = "Use Blur",
                description = "Automatically use Blur",
                type = "toggle",
                default = true
            },
            blurThreshold = {
                displayName = "Blur Health Threshold",
                description = "Health percentage to use Blur",
                type = "slider",
                min = 20,
                max = 80,
                default = 50
            },
            useDarkness = {
                displayName = "Use Darkness",
                description = "Automatically use Darkness",
                type = "toggle",
                default = true
            },
            darknessThreshold = {
                displayName = "Darkness Health Threshold",
                description = "Health percentage to use Darkness",
                type = "slider",
                min = 10,
                max = 60,
                default = 40
            },
            useNetherwalk = {
                displayName = "Use Netherwalk",
                description = "Automatically use Netherwalk when talented",
                type = "toggle",
                default = true
            },
            netherwalkThreshold = {
                displayName = "Netherwalk Health Threshold",
                description = "Health percentage to use Netherwalk",
                type = "slider",
                min = 10,
                max = 40,
                default = 30
            }
        },
        
        offensiveSettings = {
            useMetamorphosis = {
                displayName = "Use Metamorphosis",
                description = "Automatically use Metamorphosis",
                type = "toggle",
                default = true
            },
            useEssenceBreak = {
                displayName = "Use Essence Break",
                description = "Automatically use Essence Break when talented",
                type = "toggle",
                default = true
            },
            useEyeBeam = {
                displayName = "Use Eye Beam",
                description = "Automatically use Eye Beam",
                type = "toggle",
                default = true
            },
            useChaosNova = {
                displayName = "Use Chaos Nova",
                description = "Automatically use Chaos Nova",
                type = "toggle",
                default = true
            },
            chaosNovaMinTargets = {
                displayName = "Chaos Nova Min Targets",
                description = "Minimum targets to use Chaos Nova",
                type = "slider",
                min = 1,
                max = 6,
                default = 3
            },
            useGlaiveTempest = {
                displayName = "Use Glaive Tempest",
                description = "Automatically use Glaive Tempest when talented",
                type = "toggle",
                default = true
            },
            glaiveTempestMinTargets = {
                displayName = "Glaive Tempest Min Targets",
                description = "Minimum targets to use Glaive Tempest",
                type = "slider",
                min = 1,
                max = 6,
                default = 1
            },
            useFelBarrage = {
                displayName = "Use Fel Barrage",
                description = "Automatically use Fel Barrage when talented",
                type = "toggle",
                default = true
            },
            felBarrageMinTargets = {
                displayName = "Fel Barrage Min Targets",
                description = "Minimum targets to use Fel Barrage",
                type = "slider",
                min = 1,
                max = 6,
                default = 3
            }
        },
        
        covenantSettings = {
            useElysianDecree = {
                displayName = "Use Elysian Decree",
                description = "Automatically use Elysian Decree",
                type = "toggle",
                default = true
            },
            useTheHunt = {
                displayName = "Use The Hunt",
                description = "Automatically use The Hunt",
                type = "toggle",
                default = true
            },
            useFodderToTheFlame = {
                displayName = "Use Fodder to the Flame",
                description = "Automatically use Fodder to the Flame",
                type = "toggle",
                default = true
            },
            useSinfulBrand = {
                displayName = "Use Sinful Brand",
                description = "Automatically use Sinful Brand",
                type = "toggle",
                default = true
            }
        },
        
        advancedSettings = {
            poolFury = {
                displayName = "Pool Fury",
                description = "Maintain minimum fury for important abilities",
                type = "toggle",
                default = true
            },
            minFuryPool = {
                displayName = "Minimum Fury Pool",
                description = "Minimum fury to maintain",
                type = "slider",
                min = 0,
                max = 80,
                default = 50
            },
            useEyeBeamWithMeta = {
                displayName = "Eye Beam with Meta",
                description = "Only use Eye Beam during Meta",
                type = "toggle",
                default = false
            },
            momentumManagement = {
                displayName = "Momentum Management",
                description = "How to manage Momentum procs",
                type = "dropdown",
                options = {"Maximum Uptime", "Cooldown Alignment", "Manual Only"},
                default = "Maximum Uptime"
            },
            bladeDanceStrategy = {
                displayName = "Blade Dance Strategy",
                description = "When to use Blade Dance in single target",
                type = "dropdown",
                options = {"AoE Only", "With First Blood", "On Cooldown"},
                default = "With First Blood"
            }
        },
        
        -- Advanced ability control settings
        abilityControls = {
            -- Metamorphosis controls
            metamorphosis = AAC.RegisterAbility(spells.METAMORPHOSIS, {
                enabled = true,
                useDuringBurstOnly = true,
                useWithEssenceBreak = false
            }),
            
            -- Eye Beam controls
            eyeBeam = AAC.RegisterAbility(spells.EYE_BEAM, {
                enabled = true,
                useDuringBurstOnly = false,
                minFury = 30,
                useWithMeta = false
            }),
            
            -- Essence Break controls
            essenceBreak = AAC.RegisterAbility(spells.ESSENCE_BREAK, {
                enabled = true,
                useDuringBurstOnly = false,
                furyThreshold = 80,
                useWithMeta = true
            })
        }
    })
    
    return true
end

-- Register for events 
function Havoc:RegisterEvents()
    -- Register for combat log events to track procs and buffs
    API.RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", function(...) 
        self:HandleCombatLogEvent(...) 
    end)
    
    -- Register for fury updates
    API.RegisterEvent("UNIT_POWER_FREQUENT", function(unit, powerType) 
        if unit == "player" and powerType == "FURY" then
            self:UpdateFury()
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
    
    -- Initial talent info update
    self:UpdateTalentInfo()
    
    return true
end

-- Update talent information
function Havoc:UpdateTalentInfo()
    -- Check for important talents
    talents.hasMomentum = API.HasTalent(spells.MOMENTUM)
    talents.hasDemonBlades = API.HasTalent(spells.DEMON_BLADES)
    talents.hasTrailOfRuin = API.HasTalent(spells.TRAIL_OF_RUIN)
    talents.hasUnboundChaos = API.HasTalent(spells.UNBOUND_CHAOS)
    talents.hasGlaiveTempest = API.HasTalent(spells.GLAIVE_TEMPEST)
    talents.hasEssenceBreak = API.HasTalent(spells.ESSENCE_BREAK)
    talents.hasCycleOfHatred = API.HasTalent(spells.CYCLE_OF_HATRED)
    talents.hasDemonic = API.HasTalent(spells.DEMONIC)
    talents.hasBlindFury = API.HasTalent(spells.BLIND_FURY)
    talents.hasFirstBlood = API.HasTalent(spells.FIRST_BLOOD)
    talents.hasDesperateInstincts = API.HasTalent(spells.DESPERATE_INSTINCTS)
    talents.hasNetherwalk = API.HasTalent(spells.NETHERWALK)
    talents.hasBurningWound = API.HasTalent(spells.BURNING_WOUND)
    talents.hasInternalStruggle = API.HasTalent(spells.INTERNAL_STRUGGLE)
    talents.hasAnyMeansNecessary = API.HasTalent(spells.ANY_MEANS_NECESSARY)
    talents.hasChaosTheory = API.HasTalent(spells.CHAOS_THEORY)
    talents.hasInertia = API.HasTalent(spells.INERTIA)
    talents.hasIsolatedPrey = API.HasTalent(spells.ISOLATED_PREY)
    talents.hasInitiative = API.HasTalent(spells.INITIATIVE)
    talents.hasTacticalRetreat = API.HasTalent(spells.TACTICAL_RETREAT)
    talents.hasDancingWithFate = API.HasTalent(spells.DANCING_WITH_FATE)
    talents.hasBouncingGlaives = API.HasTalent(spells.BOUNCING_GLAIVES)
    talents.hasSerratedGlaive = API.HasTalent(spells.SERRATED_GLAIVE)
    talents.hasSoulrend = API.HasTalent(spells.SOULREND)
    talents.hasRestlessHunter = API.HasTalent(spells.RESTLESS_HUNTER)
    talents.hasShatteredRestoration = API.HasTalent(spells.SHATTERED_RESTORATION)
    talents.hasSoulRending = API.HasTalent(spells.SOUL_RENDING)
    talents.hasChaosFragments = API.HasTalent(spells.CHAOS_FRAGMENTS)
    talents.hasErraticFelheart = API.HasTalent(spells.ERRATIC_FELHEART)
    talents.hasFeltOrchid = API.HasTalent(spells.FELT_ORCHID)
    
    -- War Within season 2 talents
    talents.hasInnerDemon = API.HasTalent(spells.INNER_DEMON)
    talents.hasFuriousGaze = API.HasTalent(spells.FURIOUS_GAZE)
    talents.hasVengefulBonds = API.HasTalent(spells.VENGEFUL_BONDS)
    talents.hasImprovedDisrupt = API.HasTalent(spells.IMPROVED_DISRUPT)
    talents.hasAuraOfPain = API.HasTalent(spells.AURA_OF_PAIN)
    talents.hasMasterOfTheGlaive = API.HasTalent(spells.MASTER_OF_THE_GLAIVE)
    talents.hasMiseryInDefeat = API.HasTalent(spells.MISERY_IN_DEFEAT)
    talents.hasDisruptingFury = API.HasTalent(spells.DISRUPTING_FURY)
    talents.hasIllidariKnowledge = API.HasTalent(spells.ILLIDARI_KNOWLEDGE)
    talents.hasRushOfChaos = API.HasTalent(spells.RUSH_OF_CHAOS)
    talents.hasUnnaturalMalice = API.HasTalent(spells.UNNATURAL_MALICE)
    talents.hasChaosNovaEmpowerment = API.HasTalent(spells.CHAOS_NOVA_EMPOWERMENT)
    talents.hasImprovedChaosStrike = API.HasTalent(spells.IMPROVED_CHAOS_STRIKE)
    talents.hasCharredWarblades = API.HasTalent(spells.CHARRED_WARBLADES)
    talents.hasIsolatedAggression = API.HasTalent(spells.ISOLATED_AGGRESSION)
    talents.hasRagefire = API.HasTalent(spells.RAGEFIRE)
    talents.hasPreciseViolence = API.HasTalent(spells.PRECISE_VIOLENCE)
    talents.hasFelBarrage = API.HasTalent(spells.FEL_BARRAGE)
    
    -- Set specialized variables based on talents
    if talents.hasDemonic then
        demonic = true
    end
    
    if talents.hasTrailOfRuin then
        trailOfRuin = true
    end
    
    if talents.hasFirstBlood then
        firstBlood = true
    end
    
    if talents.hasCycleOfHatred then
        cycleOfHatred = true
    end
    
    if talents.hasRestlessHunter then
        restlessHunter = true
    end
    
    if talents.hasShatteredRestoration then
        shatteredRestoration = true
    end
    
    if talents.hasSoulRending then
        soulRending = true
    }
    
    -- Get Fel Rush charges
    felRushCharges = API.GetSpellCharges(spells.FEL_RUSH) or 0
    
    API.PrintDebug("Havoc Demon Hunter talents updated")
    
    return true
end

-- Update fury tracking
function Havoc:UpdateFury()
    currentFury = API.GetPlayerPower()
    return true
end

-- Update target data
function Havoc:UpdateTargetData()
    -- Check if in melee range
    inMeleeRange = API.IsUnitInRange("target", MELEE_RANGE)
    
    -- Get target GUID
    local targetGUID = API.GetTargetGUID()
    
    if targetGUID and targetGUID ~= "" then
        -- Check for Essence Break 
        if talents.hasEssenceBreak then
            local name, _, _, _, _, expiration = API.GetDebuffInfo(targetGUID, debuffs.ESSENCE_BREAK)
            if name then
                essenceBreakActive = true
                essenceBreakEndTime = expiration
            else
                essenceBreakActive = false
                essenceBreakEndTime = 0
            end
        end
        
        -- Check for Burning Wound 
        if talents.hasBurningWound then
            burningWoundStacks = API.GetDebuffStacks(targetGUID, debuffs.BURNING_WOUND) or 0
        end
        
        -- Check for Serrated Glaive
        if talents.hasSerratedGlaive then
            local name = API.GetDebuffInfo(targetGUID, debuffs.SERRATED_GLAIVE)
            serratedGlaiveActive = name ~= nil
        end
    end
    
    -- Update AoE targets count
    currentAoETargets = API.GetNearbyEnemiesCount(8) -- AoE radius
    
    return true
end

-- Handle combat log events
function Havoc:HandleCombatLogEvent(...)
    local timestamp, eventType, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, spellID, spellName = CombatLogGetCurrentEventInfo()
    
    -- Only process events from the player
    if sourceGUID ~= API.GetPlayerGUID() then
        return false
    end
    
    -- Track buff applications
    if eventType == "SPELL_AURA_APPLIED" or eventType == "SPELL_AURA_REFRESH" then
        -- Track player buffs
        if destGUID == API.GetPlayerGUID() then
            -- Track Metamorphosis
            if spellID == buffs.METAMORPHOSIS then
                metamorphosisActive = true
                metamorphosisEndTime = GetTime() + METAMORPHOSIS_DURATION
                API.PrintDebug("Metamorphosis activated")
            end
            
            -- Track Momentum
            if spellID == buffs.MOMENTUM then
                momentumActive = true
                momentumEndTime = GetTime() + MOMENTUM_DURATION
                API.PrintDebug("Momentum activated")
            end
            
            -- Track Immolation Aura
            if spellID == buffs.IMMOLATION_AURA then
                immolationAuraActive = true
                immolationAuraEndTime = GetTime() + IMMOLATION_AURA_DURATION
                API.PrintDebug("Immolation Aura activated")
            end
            
            -- Track Prepared buff from Vengeful Retreat
            if spellID == buffs.PREPARED then
                preparedCharges = API.GetBuffStacks(buffs.PREPARED) or 1
                API.PrintDebug("Prepared activated: " .. tostring(preparedCharges) .. " charges")
            end
            
            -- Track Blur
            if spellID == buffs.BLUR then
                API.PrintDebug("Blur activated")
            end
            
            -- Track Darkness
            if spellID == buffs.DARKNESS then
                API.PrintDebug("Darkness activated")
            end
            
            -- Track Netherwalk
            if spellID == buffs.NETHERWALK then
                API.PrintDebug("Netherwalk activated")
            end
            
            -- Track Unbound Chaos
            if spellID == buffs.UNBOUND_CHAOS then
                unrestrained = true
                API.PrintDebug("Unbound Chaos activated")
            end
            
            -- Track Inner Demon
            if spellID == buffs.INNER_DEMON then
                API.PrintDebug("Inner Demon activated")
            end
            
            -- Track Trail of Ruin
            if spellID == buffs.TRAIL_OF_RUIN then
                API.PrintDebug("Trail of Ruin activated")
            end
            
            -- Track Blade Flurry
            if spellID == buffs.BLADE_FLURRY then
                bladeFlurryActive = true
                API.PrintDebug("Blade Flurry activated")
            end
            
            -- Track Initiative
            if spellID == buffs.INITIATIVE then
                initiativeBuff = true
                initiativeBuffCount = select(4, API.GetBuffInfo("player", buffs.INITIATIVE)) or 1
                API.PrintDebug("Initiative buff activated: " .. tostring(initiativeBuffCount) .. " stacks")
            end
            
            -- Track Chaos Fragments
            if spellID == buffs.CHAOS_FRAGMENTS then
                chaosFragment = select(4, API.GetBuffInfo("player", buffs.CHAOS_FRAGMENTS)) or 1
                API.PrintDebug("Chaos Fragment stacks: " .. tostring(chaosFragment))
            end
            
            -- Track Felt Orchid
            if spellID == buffs.FELT_ORCHID then
                feltOrchidBuff = true
                feltOrchidStacks = select(4, API.GetBuffInfo("player", buffs.FELT_ORCHID)) or 1
                API.PrintDebug("Felt Orchid activated: " .. tostring(feltOrchidStacks) .. " stacks")
            end
        end
    end
    
    -- Track buff removals
    if eventType == "SPELL_AURA_REMOVED" then
        -- Track player buffs
        if destGUID == API.GetPlayerGUID() then
            -- Track Metamorphosis
            if spellID == buffs.METAMORPHOSIS then
                metamorphosisActive = false
                API.PrintDebug("Metamorphosis faded")
            end
            
            -- Track Momentum
            if spellID == buffs.MOMENTUM then
                momentumActive = false
                API.PrintDebug("Momentum faded")
            end
            
            -- Track Immolation Aura
            if spellID == buffs.IMMOLATION_AURA then
                immolationAuraActive = false
                API.PrintDebug("Immolation Aura faded")
            end
            
            -- Track Prepared buff
            if spellID == buffs.PREPARED then
                preparedCharges = 0
                API.PrintDebug("Prepared faded")
            end
            
            -- Track Unbound Chaos
            if spellID == buffs.UNBOUND_CHAOS then
                unrestrained = false
                API.PrintDebug("Unbound Chaos faded")
            end
            
            -- Track Blade Flurry
            if spellID == buffs.BLADE_FLURRY then
                bladeFlurryActive = false
                API.PrintDebug("Blade Flurry faded")
            end
            
            -- Track Initiative
            if spellID == buffs.INITIATIVE then
                initiativeBuff = false
                initiativeBuffCount = 0
                API.PrintDebug("Initiative buff faded")
            end
            
            -- Track Felt Orchid
            if spellID == buffs.FELT_ORCHID then
                feltOrchidBuff = false
                feltOrchidStacks = 0
                API.PrintDebug("Felt Orchid faded")
            end
        end
    end
    
    -- Track Chaos Fragments stacks
    if eventType == "SPELL_AURA_APPLIED_DOSE" and spellID == buffs.CHAOS_FRAGMENTS and destGUID == API.GetPlayerGUID() then
        chaosFragment = select(4, API.GetBuffInfo("player", buffs.CHAOS_FRAGMENTS)) or 0
        API.PrintDebug("Chaos Fragment stacks: " .. tostring(chaosFragment))
    end
    
    -- Track Initiative stacks
    if eventType == "SPELL_AURA_APPLIED_DOSE" and spellID == buffs.INITIATIVE and destGUID == API.GetPlayerGUID() then
        initiativeBuffCount = select(4, API.GetBuffInfo("player", buffs.INITIATIVE)) or 0
        API.PrintDebug("Initiative stacks: " .. tostring(initiativeBuffCount))
    end
    
    -- Track Felt Orchid stacks
    if eventType == "SPELL_AURA_APPLIED_DOSE" and spellID == buffs.FELT_ORCHID and destGUID == API.GetPlayerGUID() then
        feltOrchidStacks = select(4, API.GetBuffInfo("player", buffs.FELT_ORCHID)) or 0
        API.PrintDebug("Felt Orchid stacks: " .. tostring(feltOrchidStacks))
    end
    
    -- Track spell casts
    if eventType == "SPELL_CAST_SUCCESS" and sourceGUID == API.GetPlayerGUID() then
        if spellID == spells.METAMORPHOSIS then
            metamorphosisActive = true
            metamorphosisEndTime = GetTime() + METAMORPHOSIS_DURATION
            API.PrintDebug("Metamorphosis cast")
        elseif spellID == spells.IMMOLATION_AURA then
            immolationAuraActive = true
            immolationAuraEndTime = GetTime() + IMMOLATION_AURA_DURATION
            API.PrintDebug("Immolation Aura cast")
        elseif spellID == spells.FEL_RUSH then
            inFelRush = true
            havocDhDashActive = true
            
            -- Reset inFelRush after a short delay
            C_Timer.After(0.5, function()
                inFelRush = false
                havocDhDashActive = false
                API.PrintDebug("Fel Rush completed")
            end)
            
            felRushCharges = API.GetSpellCharges(spells.FEL_RUSH) or 0
            API.PrintDebug("Fel Rush cast, charges remaining: " .. tostring(felRushCharges))
        elseif spellID == spells.VENGEFUL_RETREAT then
            vengefulRetreatOnCooldown = true
            tacticalRetreatActivated = true
            
            -- Calculate cooldown (typically 25 seconds, might be reduced by talents)
            local cooldown = VENGEFUL_RETREAT_COOLDOWN
            
            -- Reset vengefulRetreatOnCooldown after cooldown
            C_Timer.After(cooldown, function()
                vengefulRetreatOnCooldown = false
                tacticalRetreatActivated = false
                API.PrintDebug("Vengeful Retreat cooldown reset")
            end)
            
            API.PrintDebug("Vengeful Retreat cast")
        elseif spellID == spells.BLADE_DANCE or spellID == spells.DEATH_SWEEP then
            bladeDanceOnCooldown = true
            
            -- Reset bladeDanceOnCooldown after a short cooldown (typically 9 seconds)
            C_Timer.After(9, function()
                bladeDanceOnCooldown = false
                API.PrintDebug("Blade Dance cooldown reset")
            end)
            
            API.PrintDebug("Blade Dance/Death Sweep cast")
        elseif spellID == spells.EYE_BEAM then
            eyeBeamActive = true
            eyeBeamChannelTime = EYE_BEAM_CHANNEL_TIME
            eyeBeamChannelEndTime = GetTime() + eyeBeamChannelTime
            
            -- Reset eyeBeamActive after channel time
            C_Timer.After(eyeBeamChannelTime, function()
                eyeBeamActive = false
                API.PrintDebug("Eye Beam channel ended")
            end)
            
            API.PrintDebug("Eye Beam cast")
        elseif spellID == spells.ESSENCE_BREAK then
            essenceBreakActive = true
            essenceBreakEndTime = GetTime() + ESSENCE_BREAK_DURATION
            API.PrintDebug("Essence Break cast")
        elseif spellID == spells.GLAIVE_TEMPEST then
            glaiveTempestActive = true
            
            -- Reset glaiveTempestActive after a short duration
            C_Timer.After(3, function() -- Approximate duration of effect
                glaiveTempestActive = false
                API.PrintDebug("Glaive Tempest effect ended")
            end)
            
            API.PrintDebug("Glaive Tempest cast")
        elseif spellID == spells.CHAOS_NOVA then
            chaosNovaActive = true
            
            -- Reset chaosNovaActive after a short delay
            C_Timer.After(0.5, function()
                chaosNovaActive = false
                API.PrintDebug("Chaos Nova effect ended")
            end)
            
            -- Track cooldown (typically 45-60 seconds)
            C_Timer.After(CHAOS_NOVA_COOLDOWN, function()
                API.PrintDebug("Chaos Nova cooldown reset")
            end)
            
            API.PrintDebug("Chaos Nova cast")
        end
    end
    
    -- Track channeling start
    if eventType == "SPELL_CHANNEL_START" and sourceGUID == API.GetPlayerGUID() then
        if spellID == spells.EYE_BEAM then
            eyeBeamActive = true
            eyeBeamChannelTime = EYE_BEAM_CHANNEL_TIME
            eyeBeamChannelEndTime = GetTime() + eyeBeamChannelTime
            API.PrintDebug("Eye Beam channel started")
        elseif spellID == spells.FEL_BARRAGE then
            felBarrageCharging = true
            API.PrintDebug("Fel Barrage channel started")
        end
    end
    
    -- Track channeling stop
    if eventType == "SPELL_CHANNEL_STOP" and sourceGUID == API.GetPlayerGUID() then
        if spellID == spells.EYE_BEAM then
            eyeBeamActive = false
            API.PrintDebug("Eye Beam channel stopped")
        elseif spellID == spells.FEL_BARRAGE then
            felBarrageCharging = false
            API.PrintDebug("Fel Barrage channel stopped")
        end
    end
    
    return true
end

-- Main rotation function
function Havoc:RunRotation()
    -- Check if we should be running Havoc Demon Hunter logic
    if API.GetActiveSpecID() ~= HAVOC_SPEC_ID then
        return false
    end
    
    -- Skip rotation if player is casting or channeling
    if API.IsPlayerCasting() or API.IsPlayerChanneling() or eyeBeamActive or felBarrageCharging then
        return false
    end
    
    -- Get settings
    local settings = ConfigRegistry:GetSettings("HavocDemonHunter")
    
    -- Update variables
    self:UpdateFury()
    burstModeActive = settings.rotationSettings.burstEnabled and API.ShouldUseBurst()
    self:UpdateTargetData() -- Makes sure we have current target information
    
    -- Handle next cast override
    if nextCastOverride and API.CanCast(nextCastOverride) then
        local spell = nextCastOverride
        nextCastOverride = nil
        API.CastSpell(spell)
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
    
    -- Handle cooldowns first
    if self:HandleCooldowns(settings) then
        return true
    end
    
    -- Handle charges/effects
    if self:HandleChargeMoves(settings) then
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
function Havoc:HandleInterrupts()
    -- Only attempt to interrupt if in range
    if inMeleeRange and API.CanCast(spells.DISRUPT) and API.TargetIsSpellCastable() then
        API.CastSpell(spells.DISRUPT)
        return true
    end
    
    -- Use Imprison as a backup CC if talented
    if API.IsUnitInRange("target", 20) and
       API.CanCast(spells.IMPRISON) and 
       API.TargetIsSpellCastable() then
        API.CastSpell(spells.IMPRISON)
        return true
    end
    
    return false
end

-- Handle defensive abilities
function Havoc:HandleDefensives(settings)
    local playerHealth = API.GetPlayerHealthPercent()
    
    -- Use Blur
    if settings.defensiveSettings.useBlur and
       playerHealth <= settings.defensiveSettings.blurThreshold and
       API.CanCast(spells.BLUR) then
        API.CastSpell(spells.BLUR)
        return true
    end
    
    -- Use Darkness
    if settings.defensiveSettings.useDarkness and
       playerHealth <= settings.defensiveSettings.darknessThreshold and
       API.CanCast(spells.DARKNESS) then
        API.CastSpell(spells.DARKNESS)
        return true
    end
    
    -- Use Netherwalk if talented
    if talents.hasNetherwalk and
       settings.defensiveSettings.useNetherwalk and
       playerHealth <= settings.defensiveSettings.netherwalkThreshold and
       API.CanCast(spells.NETHERWALK) then
        API.CastSpell(spells.NETHERWALK)
        return true
    end
    
    return false
end

-- Handle cooldown abilities
function Havoc:HandleCooldowns(settings)
    -- Skip if GCD is not ready
    if not API.IsGCDReady() then
        return false
    end
    
    -- Skip offensive cooldowns if not in burst mode
    if not burstModeActive then
        -- Still allow Immolation Aura outside burst
        if not immolationAuraActive and API.CanCast(spells.IMMOLATION_AURA) then
            -- Immolation Aura rotational usage
            API.CastSpell(spells.IMMOLATION_AURA)
            return true
        end
        
        return false
    end
    
    -- Use Metamorphosis
    if settings.offensiveSettings.useMetamorphosis and
       settings.abilityControls.metamorphosis.enabled and
       not metamorphosisActive and
       API.CanCast(spells.METAMORPHOSIS) then
        
        -- Check if we want to use with Essence Break
        if not settings.abilityControls.metamorphosis.useWithEssenceBreak or 
           (essenceBreakActive or not talents.hasEssenceBreak) then
            API.CastSpell(spells.METAMORPHOSIS)
            return true
        end
    end
    
    -- Use Essence Break
    if talents.hasEssenceBreak and
       settings.offensiveSettings.useEssenceBreak and
       settings.abilityControls.essenceBreak.enabled and
       not essenceBreakActive and
       API.CanCast(spells.ESSENCE_BREAK) and
       currentFury >= settings.abilityControls.essenceBreak.furyThreshold then
        
        -- Check if we want to use with Meta
        if not settings.abilityControls.essenceBreak.useWithMeta or metamorphosisActive then
            API.CastSpell(spells.ESSENCE_BREAK)
            return true
        end
    end
    
    -- Use Eye Beam
    if settings.offensiveSettings.useEyeBeam and
       settings.abilityControls.eyeBeam.enabled and
       not eyeBeamActive and
       API.CanCast(spells.EYE_BEAM) and
       currentFury >= settings.abilityControls.eyeBeam.minFury then
        
        -- Check if we want to use with Meta
        if not settings.abilityControls.eyeBeam.useWithMeta or metamorphosisActive then
            -- Check if we should use in AoE or single target
            if settings.advancedSettings.useEyeBeamWithMeta == false or 
               metamorphosisActive or
               (demonic && currentAoETargets >= 1) then
                API.CastSpell(spells.EYE_BEAM)
                return true
            end
        end
    end
    
    -- Use Glaive Tempest
    if talents.hasGlaiveTempest and
       settings.offensiveSettings.useGlaiveTempest and
       not glaiveTempestActive and
       API.CanCast(spells.GLAIVE_TEMPEST) and
       currentAoETargets >= settings.offensiveSettings.glaiveTempestMinTargets then
        API.CastSpell(spells.GLAIVE_TEMPEST)
        return true
    end
    
    -- Use Fel Barrage
    if talents.hasFelBarrage and
       settings.offensiveSettings.useFelBarrage and
       not felBarrageCharging and
       API.CanCast(spells.FEL_BARRAGE) and
       currentAoETargets >= settings.offensiveSettings.felBarrageMinTargets then
        API.CastSpell(spells.FEL_BARRAGE)
        return true
    end
    
    -- Use Immolation Aura
    if not immolationAuraActive and API.CanCast(spells.IMMOLATION_AURA) then
        API.CastSpell(spells.IMMOLATION_AURA)
        return true
    end
    
    -- Use Chaos Nova
    if settings.offensiveSettings.useChaosNova and
       API.CanCast(spells.CHAOS_NOVA) and
       currentAoETargets >= settings.offensiveSettings.chaosNovaMinTargets then
        API.CastSpell(spells.CHAOS_NOVA)
        return true
    end
    
    -- Handle covenant abilities
    if self:HandleCovenantAbilities(settings) then
        return true
    end
    
    return false
end

-- Handle covenant abilities
function Havoc:HandleCovenantAbilities(settings)
    -- Use Elysian Decree
    if settings.covenantSettings.useElysianDecree and
       API.CanCast(spells.ELYSIAN_DECREE) then
        API.CastSpellAtCursor(spells.ELYSIAN_DECREE)
        return true
    end
    
    -- Use The Hunt
    if settings.covenantSettings.useTheHunt and
       API.CanCast(spells.THE_HUNT) then
        API.CastSpell(spells.THE_HUNT)
        return true
    end
    
    -- Use Fodder to the Flame
    if settings.covenantSettings.useFodderToTheFlame and
       API.CanCast(spells.FODDER_TO_THE_FLAME) then
        API.CastSpell(spells.FODDER_TO_THE_FLAME)
        return true
    end
    
    -- Use Sinful Brand
    if settings.covenantSettings.useSinfulBrand and
       API.CanCast(spells.SINFUL_BRAND) then
        API.CastSpell(spells.SINFUL_BRAND)
        return true
    end
    
    return false
end

-- Handle charge moves like Fel Rush and Vengeful Retreat
function Havoc:HandleChargeMoves(settings)
    -- Update available charges
    felRushCharges = API.GetSpellCharges(spells.FEL_RUSH) or 0
    
    -- Handle Fel Rush
    if settings.rotationSettings.useFelRush and
       felRushCharges > settings.rotationSettings.felRushChargesReserved and
       API.CanCast(spells.FEL_RUSH) then
        
        -- Check for momentum cooldown alignment
        if talents.hasMomentum and settings.advancedSettings.momentumManagement == "Cooldown Alignment" then
            -- Only use if we're about to use a major cooldown
            if (talents.hasEssenceBreak and API.GetSpellCooldown(spells.ESSENCE_BREAK) < 2) or
               (settings.offensiveSettings.useMetamorphosis and API.GetSpellCooldown(spells.METAMORPHOSIS) < 2) then
                API.CastSpell(spells.FEL_RUSH)
                return true
            end
        elseif talents.hasMomentum and settings.advancedSettings.momentumManagement == "Maximum Uptime" and
               (not momentumActive or momentumEndTime - GetTime() < 2) then
            -- Use to maintain momentum
            API.CastSpell(spells.FEL_RUSH)
            return true
        elseif talents.hasUnboundChaos and immolationAuraActive and not unrestrained then
            -- Use to proc Unbound Chaos
            API.CastSpell(spells.FEL_RUSH)
            return true
        end
    end
    
    -- Handle Vengeful Retreat
    if settings.rotationSettings.useVengefulRetreat and
       not vengefulRetreatOnCooldown and
       API.CanCast(spells.VENGEFUL_RETREAT) then
        
        -- Use for momentum if needed
        if talents.hasMomentum and settings.advancedSettings.momentumManagement != "Manual Only" and
           (not momentumActive or momentumEndTime - GetTime() < 1) then
            API.CastSpell(spells.VENGEFUL_RETREAT)
            return true
        end
        
        -- Use for tactical retreat benefits
        if talents.hasTacticalRetreat and currentFury < 50 then
            API.CastSpell(spells.VENGEFUL_RETREAT)
            return true
        end
        
        -- Use for initiative stacks
        if talents.hasInitiative and (not initiativeBuff or initiativeBuffCount < 5) then
            API.CastSpell(spells.VENGEFUL_RETREAT)
            return true
        end
    end
    
    return false
end

-- Handle AoE rotation
function Havoc:HandleAoERotation(settings)
    -- Blade Dance (Death Sweep during Meta)
    if not bladeDanceOnCooldown and API.CanCast(metamorphosisActive and spells.DEATH_SWEEP or spells.BLADE_DANCE) then
        API.CastSpell(metamorphosisActive and spells.DEATH_SWEEP or spells.BLADE_DANCE)
        return true
    end
    
    -- Throw Glaive for AoE damage
    if API.CanCast(spells.THROW_GLAIVE) then
        API.CastSpell(spells.THROW_GLAIVE)
        return true
    end
    
    -- Chaos Strike / Annihilation when we have plenty of fury
    if API.CanCast(metamorphosisActive and spells.ANNIHILATION or spells.CHAOS_STRIKE) and
       currentFury >= 40 and
       (not settings.advancedSettings.poolFury or currentFury >= settings.advancedSettings.minFuryPool) then
        API.CastSpell(metamorphosisActive and spells.ANNIHILATION or spells.CHAOS_STRIKE)
        return true
    end
    
    -- Demon's Bite to generate fury when needed
    if not talents.hasDemonBlades and
       (not metamorphosisActive or not settings.rotationSettings.holdDemonsBiteInMeta) and
       API.CanCast(spells.DEMONS_BITE) then
        API.CastSpell(spells.DEMONS_BITE)
        return true
    end
    
    -- Use Felblade to generate fury if low
    if currentFury < 40 and API.CanCast(spells.FELBLADE) then
        API.CastSpell(spells.FELBLADE)
        return true
    end
    
    return false
end

-- Handle Single Target rotation
function Havoc:HandleSingleTargetRotation(settings)
    -- Chaos Strike / Annihilation when we have plenty of fury
    if API.CanCast(metamorphosisActive and spells.ANNIHILATION or spells.CHAOS_STRIKE) and
       currentFury >= 40 and
       (not settings.advancedSettings.poolFury or currentFury >= settings.advancedSettings.minFuryPool) then
        API.CastSpell(metamorphosisActive and spells.ANNIHILATION or spells.CHAOS_STRIKE)
        return true
    end
    
    -- Blade Dance / Death Sweep based on settings
    if not bladeDanceOnCooldown and 
       API.CanCast(metamorphosisActive and spells.DEATH_SWEEP or spells.BLADE_DANCE) then
        
        -- Check strategy for Blade Dance usage
        if settings.advancedSettings.bladeDanceStrategy == "On Cooldown" or
           (settings.advancedSettings.bladeDanceStrategy == "With First Blood" and firstBlood) or
           (settings.advancedSettings.bladeDanceStrategy == "AoE Only" and currentAoETargets >= DEFAULT_AOE_THRESHOLD) then
            API.CastSpell(metamorphosisActive and spells.DEATH_SWEEP or spells.BLADE_DANCE)
            return true
        end
    end
    
    -- Use Throw Glaive to maintain Serrated Glaive if talented
    if talents.hasSerratedGlaive and not serratedGlaiveActive and API.CanCast(spells.THROW_GLAIVE) then
        API.CastSpell(spells.THROW_GLAIVE)
        return true
    end
    
    -- Throw Glaive if nothing else to cast
    if (!talents.hasSerratedGlaive || serratedGlaiveActive) and API.CanCast(spells.THROW_GLAIVE) then
        API.CastSpell(spells.THROW_GLAIVE)
        return true
    end
    
    -- Demon's Bite to generate fury when needed
    if not talents.hasDemonBlades and
       (not metamorphosisActive or not settings.rotationSettings.holdDemonsBiteInMeta) and
       API.CanCast(spells.DEMONS_BITE) then
        API.CastSpell(spells.DEMONS_BITE)
        return true
    end
    
    -- Use Felblade to generate fury if low
    if currentFury < 40 and API.CanCast(spells.FELBLADE) then
        API.CastSpell(spells.FELBLADE)
        return true
    }
    
    return false
end

-- Handle specialization change
function Havoc:OnSpecializationChanged()
    -- Update talent information
    self:UpdateTalentInfo()
    
    -- Reset state variables
    nextCastOverride = nil
    burstModeActive = false
    currentFury = API.GetPlayerPower()
    maxFury = 120
    eyeBeamActive = false
    eyeBeamChannelTime = 0
    eyeBeamChannelEndTime = 0
    metamorphosisActive = false
    metamorphosisEndTime = 0
    momentumActive = false
    momentumEndTime = 0
    immolationAuraActive = false
    immolationAuraEndTime = 0
    felRushCharges = API.GetSpellCharges(spells.FEL_RUSH) or 0
    vengefulRetreatOnCooldown = false
    bladeDanceOnCooldown = false
    chaosStrikeReduced = false
    inMeleeRange = false
    nemesisActive = false
    preparedCharges = 0
    burningWoundStacks = 0
    bladeFlurryActive = false
    felBarrageCharging = false
    unrestrained = false
    unleashHellActive = false
    serratedGlaiveActive = false
    inFelRush = false
    glaiveTempestActive = false
    internalStruggleActive = false
    blindFury = false
    inferredRealityActive = false
    chaosTheoremActive = false
    havocDhDashActive = false
    demonic = false
    trailOfRuin = false
    firstBlood = false
    cycleOfHatred = false
    essenceBreakActive = false
    essenceBreakEndTime = 0
    tacticalRetreatActivated = false
    initiativeBuff = false
    initiativeBuffCount = 0
    restlessHunter = false
    shatteredRestoration = false
    soulRending = false
    chaosFragment = 0
    chaosNovaActive = false
    feltOrchidBuff = false
    feltOrchidStacks = 0
    
    API.PrintDebug("Havoc Demon Hunter state reset on spec change")
    
    return true
end

-- Return the module for loading
return Havoc