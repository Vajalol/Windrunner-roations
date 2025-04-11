------------------------------------------
-- WindrunnerRotations - Arcane Mage Module
-- Author: VortexQ8
-- The War Within Season 2
------------------------------------------

local Arcane = {}
-- This will be assigned to addon.Classes.Mage.Arcane when loaded

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
local currentMana = 100
local maxMana = 100
local arcaneMissiles = false
local arcaneMissilesActive = false
local arcaneMissilesEndTime = 0
local arcaneBarrage = false
local arcaneBlast = false
local arcaneExplosion = false
local arcaneFamiliar = false
local arcaneFamiliarActive = false
local arcaneFamiliarEndTime = 0
local arcaneIntellect = false
local arcaneIntellectActive = false
local arcaneIntellectEndTime = 0
local arcaneOrb = false
local arcaneOrbActive = false
local arcaneOrbEndTime = 0
local arcanePower = false
local arcanePowerActive = false
local arcanePowerEndTime = 0
local arcaneWard = false
local arcaneWardActive = false
local arcaneWardEndTime = 0
local clearcasting = false
local clearcastingActive = false
local clearcastingStacks = 0
local clearcastingEndTime = 0
local conjureFood = false
local conjureManaGem = false
local counterspell = false
local presenceOfMind = false
local presenceOfMindActive = false
local presenceOfMindEndTime = 0
local presenceOfMindStacks = 0
local evocation = false
local evocationActive = false
local evocationEndTime = 0
local fireBlast = false
local frostNova = false
local frostbolt = false
local greaterInvisibility = false
local greaterInvisibilityActive = false
local greaterInvisibilityEndTime = 0
local iceBlock = false
local iceBlockActive = false
local iceBlockEndTime = 0
local invisibility = false
local invisibilityActive = false
local invisibilityEndTime = 0
local mirrorImage = false
local polymorph = false
local removePolymorph = false
local shimmer = false
local slowFall = false
local spellsteal = false
local arcaneSurge = false
local arcaneSurgeActive = false
local arcaneSurgeEndTime = 0
local burstingPower = false
local burstingPowerActive = false
local burstingPowerEndTime = 0
local chargedOrbs = false
local chronoShift = false
local chronoShiftActive = false
local chronoShiftEndTime = 0
local conjureRefreshment = false
local displacement = false
local enlightened = false
local enlightenedActive = false
local enlightenedEndTime = 0
local erosion = false
local erosionActive = false
local erosionEndTime = 0
local everlastingWarmth = false
local everlastingWarmthActive = false
local everlastingWarmthEndTime = 0
local radiantSpark = false
local radiantSparkActive = false
local radiantSparkEndTime = 0
local reverberate = false
local runeOfPower = false
local runeOfPowerActive = false
local runeOfPowerEndTime = 0
local temporalWarp = false
local temporalWarpActive = false
local temporalWarpEndTime = 0
local timeAnomaly = false
local timeAnomalyActive = false
local timeAnomalyEndTime = 0
local touchOfTheMagi = false
local touchOfTheMagiActive = false
local touchOfTheMagiEndTime = 0
local shimmeringPower = false
local shimmeringPowerActive = false
local shimmeringPowerEndTime = 0
local nether = false
local netherTempest = false
local netherTempestActive = false
local netherTempestEndTime = 0
local superNova = false
local superNovaActive = false
local superNovaEndTime = 0
local bloodlust = false
local bloodlustActive = false
local bloodlustEndTime = 0
local timeWarp = false
local timeWarpActive = false
local timeWarpEndTime = 0
local prodigious = false
local prodigiousSavant = false
local prodigiousSavantActive = false
local prodigiousSavantEndTime = 0
local slipstream = false
local slipstreamActive = false
local slipstreamEndTime = 0
local lastArcaneBarrage = 0
local lastArcaneBlast = 0
local lastArcaneMissiles = 0
local lastArcaneExplosion = 0
local lastArcaneOrb = 0
local lastArcanePower = 0
local lastArcaneWard = 0
local lastCounterspell = 0
local lastPresenceOfMind = 0
local lastEvocation = 0
local lastFireBlast = 0
local lastFrostNova = 0
local lastFrostbolt = 0
local lastGreaterInvisibility = 0
local lastIceBlock = 0
local lastInvisibility = 0
local lastMirrorImage = 0
local lastPolymorph = 0
local lastShimmer = 0
local lastSlowFall = 0
local lastSpellsteal = 0
local lastArcaneFamiliar = 0
local lastArcaneIntellect = 0
local lastArcaneSurge = 0
local lastRadiantSpark = 0
local lastRuneOfPower = 0
local lastTouchOfTheMagi = 0
local lastNetherTempest = 0
local lastSuperNova = 0
local lastTimeWarp = 0
local arcaneCharges = 0
local maxArcaneCharges = 4
local playerHealth = 100
local targetHealth = 100
local activeEnemies = 0
local isInMelee = false
local inCombat = false
local hasManaGem = false
local manaGemCharges = 0

-- Constants
local ARCANE_SPEC_ID = 62
local ARCANE_POWER_DURATION = 10.0 -- seconds
local PRESENCE_OF_MIND_DURATION = 60.0 -- seconds
local ARCANE_WARD_DURATION = 60.0 -- seconds
local RUNE_OF_POWER_DURATION = 12.0 -- seconds
local TOUCH_OF_THE_MAGI_DURATION = 8.0 -- seconds
local RADIANT_SPARK_DURATION = 8.0 -- seconds (debuff duration)
local NETHER_TEMPEST_DURATION = 12.0 -- seconds
local ARCANE_FAMILIAR_DURATION = 3600.0 -- seconds (1 hour)
local ENLIGHTENED_DURATION = 8.0 -- seconds
local ARCANE_SURGE_DURATION = 10.0 -- seconds
local TIME_WARP_DURATION = 40.0 -- seconds
local SLIPSTREAM_DURATION = 8.0 -- seconds

-- Initialize the Arcane module
function Arcane:Initialize()
    self:RegisterSpells()
    self:RegisterVariables()
    self:RegisterSettings()
    self:RegisterEvents()
    
    API.PrintDebug("Arcane Mage module initialized")
    
    return true
end

-- Register spell IDs
function Arcane:RegisterSpells()
    -- Core abilities
    spells.ARCANE_BARRAGE = 44425
    spells.ARCANE_BLAST = 30451
    spells.ARCANE_MISSILES = 5143
    spells.ARCANE_EXPLOSION = 1449
    spells.ARCANE_FAMILIAR = 205022
    spells.ARCANE_INTELLECT = 1459
    spells.ARCANE_ORB = 153626
    spells.ARCANE_POWER = 12042
    spells.ARCANE_WARD = 235450
    spells.CONJURE_FOOD = 190336
    spells.CONJURE_MANA_GEM = 759
    spells.COUNTERSPELL = 2139
    spells.PRESENCE_OF_MIND = 205025
    spells.EVOCATION = 12051
    
    -- Multi-spec abilities
    spells.FIRE_BLAST = 319836
    spells.FROST_NOVA = 122
    spells.FROSTBOLT = 116
    spells.GREATER_INVISIBILITY = 110959
    spells.ICE_BLOCK = 45438
    spells.INVISIBILITY = 66
    spells.MIRROR_IMAGE = 55342
    spells.POLYMORPH = 118
    spells.REMOVE_CURSE = 475
    spells.SHIMMER = 212653
    spells.SLOW_FALL = 130
    spells.SPELLSTEAL = 30449
    
    -- Talents and passives
    spells.CLEARCASTING = 79684
    spells.ARCANE_SURGE = 365350
    spells.BURSTING_POWER = 408292
    spells.CHARGED_ORBS = 417493
    spells.CHRONO_SHIFT = 235711
    spells.CONJURE_REFRESHMENT = 116136
    spells.DISPLACEMENT = 389713
    spells.ENLIGHTENED = 321387
    spells.EROSION = 205039
    spells.EVERLASTING_WARMTH = 409036
    spells.RADIANT_SPARK = 376103
    spells.REVERBERATE = 281482
    spells.RUNE_OF_POWER = 116011
    spells.TEMPORAL_WARP = 386539
    spells.TIME_ANOMALY = 383980
    spells.TOUCH_OF_THE_MAGI = 321507
    spells.SHIMMERING_POWER = 415096
    spells.NETHER_TEMPEST = 114923
    spells.SUPERNOVA = 157980
    spells.PRODIGIOUS_SAVANT = 384287
    spells.SLIPSTREAM = 236457
    
    -- Raid cooldowns
    spells.BLOODLUST = 2825
    spells.HEROISM = 32182
    spells.TIME_WARP = 80353
    
    -- War Within Season 2 specific
    spells.ARCANE_BLAST_ARCANE_POWER = 400800 -- Evolved version
    
    -- Buff IDs
    spells.CLEARCASTING_BUFF = 263725
    spells.ARCANE_FAMILIAR_BUFF = 210126
    spells.ARCANE_INTELLECT_BUFF = 1459
    spells.ARCANE_POWER_BUFF = 12042
    spells.ARCANE_WARD_BUFF = 235450
    spells.PRESENCE_OF_MIND_BUFF = 205025
    spells.GREATER_INVISIBILITY_BUFF = 110960
    spells.ICE_BLOCK_BUFF = 45438
    spells.INVISIBILITY_BUFF = 32612
    spells.SLOW_FALL_BUFF = 130
    spells.ARCANE_SURGE_BUFF = 365350
    spells.BURSTING_POWER_BUFF = 408292
    spells.CHRONO_SHIFT_BUFF = 236298
    spells.ENLIGHTENED_BUFF = 321388
    spells.EVERLASTING_WARMTH_BUFF = 409036
    spells.RUNE_OF_POWER_BUFF = 116014
    spells.TEMPORAL_WARP_BUFF = 386540
    spells.TIME_ANOMALY_BUFF = 383980
    spells.SHIMMERING_POWER_BUFF = 415096
    spells.BLOODLUST_BUFF = 2825
    spells.HEROISM_BUFF = 32182
    spells.TIME_WARP_BUFF = 80353
    spells.PRODIGIOUS_SAVANT_BUFF = 384287
    spells.SLIPSTREAM_BUFF = 236457
    
    -- Debuff IDs
    spells.RADIANT_SPARK_DEBUFF = 376103
    spells.RADIANT_SPARK_VULNERABILITY = 307454
    spells.TOUCH_OF_THE_MAGI_DEBUFF = 210824
    spells.NETHER_TEMPEST_DEBUFF = 114923
    spells.SLOW_DEBUFF = 31589
    
    -- Register all spells with the API tracking system
    for spellName, spellID in pairs(spells) do
        API.RegisterSpell(spellID)
    end
    
    -- Define aura tracking
    buffs.CLEARCASTING = spells.CLEARCASTING_BUFF
    buffs.ARCANE_FAMILIAR = spells.ARCANE_FAMILIAR_BUFF
    buffs.ARCANE_INTELLECT = spells.ARCANE_INTELLECT_BUFF
    buffs.ARCANE_POWER = spells.ARCANE_POWER_BUFF
    buffs.ARCANE_WARD = spells.ARCANE_WARD_BUFF
    buffs.PRESENCE_OF_MIND = spells.PRESENCE_OF_MIND_BUFF
    buffs.GREATER_INVISIBILITY = spells.GREATER_INVISIBILITY_BUFF
    buffs.ICE_BLOCK = spells.ICE_BLOCK_BUFF
    buffs.INVISIBILITY = spells.INVISIBILITY_BUFF
    buffs.SLOW_FALL = spells.SLOW_FALL_BUFF
    buffs.ARCANE_SURGE = spells.ARCANE_SURGE_BUFF
    buffs.BURSTING_POWER = spells.BURSTING_POWER_BUFF
    buffs.CHRONO_SHIFT = spells.CHRONO_SHIFT_BUFF
    buffs.ENLIGHTENED = spells.ENLIGHTENED_BUFF
    buffs.EVERLASTING_WARMTH = spells.EVERLASTING_WARMTH_BUFF
    buffs.RUNE_OF_POWER = spells.RUNE_OF_POWER_BUFF
    buffs.TEMPORAL_WARP = spells.TEMPORAL_WARP_BUFF
    buffs.TIME_ANOMALY = spells.TIME_ANOMALY_BUFF
    buffs.SHIMMERING_POWER = spells.SHIMMERING_POWER_BUFF
    buffs.BLOODLUST = spells.BLOODLUST_BUFF
    buffs.HEROISM = spells.HEROISM_BUFF
    buffs.TIME_WARP = spells.TIME_WARP_BUFF
    buffs.PRODIGIOUS_SAVANT = spells.PRODIGIOUS_SAVANT_BUFF
    buffs.SLIPSTREAM = spells.SLIPSTREAM_BUFF
    
    debuffs.RADIANT_SPARK = spells.RADIANT_SPARK_DEBUFF
    debuffs.RADIANT_SPARK_VULNERABILITY = spells.RADIANT_SPARK_VULNERABILITY
    debuffs.TOUCH_OF_THE_MAGI = spells.TOUCH_OF_THE_MAGI_DEBUFF
    debuffs.NETHER_TEMPEST = spells.NETHER_TEMPEST_DEBUFF
    debuffs.SLOW = spells.SLOW_DEBUFF
    
    return true
end

-- Register variables to track
function Arcane:RegisterVariables()
    -- Talent tracking
    talents.hasArcaneFamiliar = false
    talents.hasArcaneOrb = false
    talents.hasPresenceOfMind = false
    talents.hasArcaneSurge = false
    talents.hasBurstingPower = false
    talents.hasChargedOrbs = false
    talents.hasChronoShift = false
    talents.hasConjureRefreshment = false
    talents.hasDisplacement = false
    talents.hasEnlightened = false
    talents.hasErosion = false
    talents.hasEverlastingWarmth = false
    talents.hasRadiantSpark = false
    talents.hasReverberate = false
    talents.hasRuneOfPower = false
    talents.hasTemporalWarp = false
    talents.hasTimeAnomaly = false
    talents.hasTouchOfTheMagi = false
    talents.hasShimmeringPower = false
    talents.hasNetherTempest = false
    talents.hasSuperNova = false
    talents.hasProdigiousSavant = false
    talents.hasSlipstream = false
    
    -- Initialize resources
    currentMana = API.GetPlayerManaPercentage() or 100
    maxMana = 100
    arcaneCharges = API.GetArcaneCharges() or 0
    maxArcaneCharges = 4
    
    -- Initialize other state
    hasManaGem = API.HasManaGem() or false
    manaGemCharges = API.GetManaGemCharges() or 0
    
    return true
end

-- Register spec-specific settings
function Arcane:RegisterSettings()
    ConfigRegistry:RegisterSettings("ArcaneMage", {
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
                default = 3
            },
            conservePhaseThreshold = {
                displayName = "Conserve Phase Mana Threshold",
                description = "Mana percentage to enter conserve phase",
                type = "slider",
                min = 10,
                max = 60,
                default = 40
            },
            burnPhaseThreshold = {
                displayName = "Burn Phase Mana Threshold",
                description = "Mana percentage to enter burn phase",
                type = "slider",
                min = 70,
                max = 100,
                default = 85
            },
            useManaGem = {
                displayName = "Use Mana Gem",
                description = "Automatically use Mana Gem when available",
                type = "toggle",
                default = true
            },
            manaGemThreshold = {
                displayName = "Mana Gem Threshold",
                description = "Mana percentage to use Mana Gem",
                type = "slider",
                min = 10,
                max = 50,
                default = 30
            },
            clearcastingUsage = {
                displayName = "Clearcasting Usage",
                description = "How to use Clearcasting procs",
                type = "dropdown",
                options = {"Always Arcane Missiles", "AoE: Explosion, ST: Missiles", "Save for Burn Phase", "Manual Only"},
                default = "Always Arcane Missiles"
            }
        },
        
        cooldownSettings = {
            useArcanePower = {
                displayName = "Use Arcane Power",
                description = "Automatically use Arcane Power",
                type = "toggle",
                default = true
            },
            arcanePowerMode = {
                displayName = "Arcane Power Usage",
                description = "When to use Arcane Power",
                type = "dropdown",
                options = {"On Cooldown", "With Touch of the Magi", "Boss Only", "Manual Only"},
                default = "With Touch of the Magi"
            },
            useTouchOfTheMagi = {
                displayName = "Use Touch of the Magi",
                description = "Automatically use Touch of the Magi",
                type = "toggle",
                default = true
            },
            touchOfTheMagiMode = {
                displayName = "Touch of the Magi Usage",
                description = "When to use Touch of the Magi",
                type = "dropdown",
                options = {"On Cooldown", "With Arcane Power", "Boss Only", "Manual Only"},
                default = "With Arcane Power"
            },
            useRadiantSpark = {
                displayName = "Use Radiant Spark",
                description = "Automatically use Radiant Spark",
                type = "toggle",
                default = true
            },
            radiantSparkMode = {
                displayName = "Radiant Spark Usage",
                description = "When to use Radiant Spark",
                type = "dropdown",
                options = {"On Cooldown", "With Cooldowns", "Boss Only", "Manual Only"},
                default = "With Cooldowns"
            },
            useRuneOfPower = {
                displayName = "Use Rune of Power",
                description = "Automatically use Rune of Power",
                type = "toggle",
                default = true
            },
            runeOfPowerMode = {
                displayName = "Rune of Power Usage",
                description = "When to use Rune of Power",
                type = "dropdown",
                options = {"On Cooldown", "With Cooldowns", "Boss Only", "Manual Only"},
                default = "With Cooldowns"
            },
            useTimeWarp = {
                displayName = "Use Time Warp",
                description = "Automatically use Time Warp",
                type = "toggle",
                default = true
            },
            timeWarpMode = {
                displayName = "Time Warp Usage",
                description = "When to use Time Warp",
                type = "dropdown",
                options = {"On Pull", "With Cooldowns", "Boss Only", "Manual Only"},
                default = "Boss Only"
            },
            useMirrorImage = {
                displayName = "Use Mirror Image",
                description = "Automatically use Mirror Image",
                type = "toggle",
                default = true
            },
            mirrorImageMode = {
                displayName = "Mirror Image Usage",
                description = "When to use Mirror Image",
                type = "dropdown",
                options = {"On Cooldown", "With Cooldowns", "Threat/Defensive", "Manual Only"},
                default = "With Cooldowns"
            }
        },
        
        defensiveSettings = {
            useArcaneWard = {
                displayName = "Use Arcane Ward",
                description = "Automatically use Arcane Ward",
                type = "toggle",
                default = true
            },
            arcaneWardMode = {
                displayName = "Arcane Ward Usage",
                description = "When to use Arcane Ward",
                type = "dropdown",
                options = {"On Cooldown", "When Taking Damage", "Manual Only"},
                default = "On Cooldown"
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
                min = 0,
                max = 40,
                default = 15
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
                min = 0,
                max = 50,
                default = 20
            }
        },
        
        utilitySettings = {
            useSlowFall = {
                displayName = "Use Slow Fall",
                description = "Automatically use Slow Fall when falling",
                type = "toggle",
                default = true
            },
            useFrostNova = {
                displayName = "Use Frost Nova",
                description = "Automatically use Frost Nova when enemies are in melee range",
                type = "toggle",
                default = true
            },
            usePolymorph = {
                displayName = "Use Polymorph",
                description = "Automatically use Polymorph for crowd control",
                type = "toggle",
                default = true
            },
            useSpellsteal = {
                displayName = "Use Spellsteal",
                description = "Automatically use Spellsteal on enemies with stealable buffs",
                type = "toggle",
                default = true
            },
            useFireBlast = {
                displayName = "Use Fire Blast",
                description = "Use Fire Blast as an instant cast damage option",
                type = "toggle",
                default = true
            },
            conjureFoodMode = {
                displayName = "Auto-Conjure Food",
                description = "Automatically conjure food when out of combat",
                type = "dropdown",
                options = {"Always", "When Low", "Manual Only"},
                default = "When Low"
            },
            conjureManaGemMode = {
                displayName = "Auto-Conjure Mana Gem",
                description = "Automatically conjure mana gem when out of combat",
                type = "dropdown",
                options = {"Always", "When Missing", "Manual Only"},
                default = "When Missing"
            }
        },
        
        -- Advanced ability control settings
        abilityControls = {
            -- Arcane Missiles controls
            arcaneMissiles = AAC.RegisterAbility(spells.ARCANE_MISSILES, {
                enabled = true,
                useDuringBurstOnly = false,
                onlyWithClearcasting = true,
                minArcaneCharges = 0
            }),
            
            -- Arcane Barrage controls
            arcaneBarrage = AAC.RegisterAbility(spells.ARCANE_BARRAGE, {
                enabled = true,
                useDuringBurstOnly = false,
                minArcaneCharges = 3,
                refreshNetherTempestThreshold = 3.0
            }),
            
            -- Arcane Blast controls
            arcaneBlast = AAC.RegisterAbility(spells.ARCANE_BLAST, {
                enabled = true,
                useDuringBurstOnly = false,
                maxArcaneCharges = 4,
                manaConserveThreshold = 30
            })
        }
    })
    
    return true
end

-- Register for events 
function Arcane:RegisterEvents()
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
    
    -- Register for arcane charges updates
    API.RegisterEvent("UNIT_POWER_FREQUENT", function(unit, powerType) 
        if unit == "player" and powerType == "ARCANE_CHARGES" then
            self:UpdateArcaneCharges()
        end
    end)
    
    -- Register for health updates
    API.RegisterEvent("UNIT_HEALTH", function(unit) 
        if unit == "player" then
            self:UpdateHealth()
        elseif unit == "target" then
            self:UpdateTargetHealth()
        end
    end)
    
    -- Register for talent update events
    API.RegisterEvent("PLAYER_TALENT_UPDATE", function() 
        self:UpdateTalentInfo() 
    end)
    
    -- Register for spell cast events
    API.RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", function(unit, _, spellID) 
        if unit == "player" then
            self:HandleSpellCastSuccess(spellID)
        end
    end)
    
    -- Register for channel start/stop
    API.RegisterEvent("UNIT_SPELLCAST_CHANNEL_START", function(unit, _, spellID) 
        if unit == "player" then
            self:HandleChannelStart(spellID)
        end
    end)
    
    API.RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP", function(unit, _, spellID) 
        if unit == "player" then
            self:HandleChannelStop(spellID)
        end
    end)
    
    -- Register for combat state changes
    API.RegisterEvent("PLAYER_REGEN_DISABLED", function() 
        inCombat = true
    end)
    
    API.RegisterEvent("PLAYER_REGEN_ENABLED", function() 
        inCombat = false
        self:HandleOutOfCombat()
    end)
    
    -- Initial talent info update
    self:UpdateTalentInfo()
    
    -- Initial mana gem update
    self:UpdateManaGemState()
    
    return true
end

-- Update talent information
function Arcane:UpdateTalentInfo()
    -- Check for important talents
    talents.hasArcaneFamiliar = API.HasTalent(spells.ARCANE_FAMILIAR)
    talents.hasArcaneOrb = API.HasTalent(spells.ARCANE_ORB)
    talents.hasPresenceOfMind = API.HasTalent(spells.PRESENCE_OF_MIND)
    talents.hasArcaneSurge = API.HasTalent(spells.ARCANE_SURGE)
    talents.hasBurstingPower = API.HasTalent(spells.BURSTING_POWER)
    talents.hasChargedOrbs = API.HasTalent(spells.CHARGED_ORBS)
    talents.hasChronoShift = API.HasTalent(spells.CHRONO_SHIFT)
    talents.hasConjureRefreshment = API.HasTalent(spells.CONJURE_REFRESHMENT)
    talents.hasDisplacement = API.HasTalent(spells.DISPLACEMENT)
    talents.hasEnlightened = API.HasTalent(spells.ENLIGHTENED)
    talents.hasErosion = API.HasTalent(spells.EROSION)
    talents.hasEverlastingWarmth = API.HasTalent(spells.EVERLASTING_WARMTH)
    talents.hasRadiantSpark = API.HasTalent(spells.RADIANT_SPARK)
    talents.hasReverberate = API.HasTalent(spells.REVERBERATE)
    talents.hasRuneOfPower = API.HasTalent(spells.RUNE_OF_POWER)
    talents.hasTemporalWarp = API.HasTalent(spells.TEMPORAL_WARP)
    talents.hasTimeAnomaly = API.HasTalent(spells.TIME_ANOMALY)
    talents.hasTouchOfTheMagi = API.HasTalent(spells.TOUCH_OF_THE_MAGI)
    talents.hasShimmeringPower = API.HasTalent(spells.SHIMMERING_POWER)
    talents.hasNetherTempest = API.HasTalent(spells.NETHER_TEMPEST)
    talents.hasSuperNova = API.HasTalent(spells.SUPERNOVA)
    talents.hasProdigiousSavant = API.HasTalent(spells.PRODIGIOUS_SAVANT)
    talents.hasSlipstream = API.HasTalent(spells.SLIPSTREAM)
    
    -- Set specialized variables based on talents
    if talents.hasArcaneFamiliar then
        arcaneFamiliar = true
    end
    
    if talents.hasArcaneOrb then
        arcaneOrb = true
    end
    
    if talents.hasPresenceOfMind then
        presenceOfMind = true
    end
    
    if talents.hasArcaneSurge then
        arcaneSurge = true
    end
    
    if talents.hasBurstingPower then
        burstingPower = true
    end
    
    if talents.hasChargedOrbs then
        chargedOrbs = true
    end
    
    if talents.hasChronoShift then
        chronoShift = true
    end
    
    if talents.hasConjureRefreshment then
        conjureRefreshment = true
    else
        conjureFood = true
    end
    
    if talents.hasDisplacement then
        displacement = true
    end
    
    if talents.hasEnlightened then
        enlightened = true
    end
    
    if talents.hasErosion then
        erosion = true
    end
    
    if talents.hasEverlastingWarmth then
        everlastingWarmth = true
    end
    
    if talents.hasRadiantSpark then
        radiantSpark = true
    end
    
    if talents.hasReverberate then
        reverberate = true
    end
    
    if talents.hasRuneOfPower then
        runeOfPower = true
    end
    
    if talents.hasTemporalWarp then
        temporalWarp = true
    end
    
    if talents.hasTimeAnomaly then
        timeAnomaly = true
    end
    
    if talents.hasTouchOfTheMagi then
        touchOfTheMagi = true
    end
    
    if talents.hasShimmeringPower then
        shimmeringPower = true
    end
    
    if talents.hasNetherTempest then
        nether = true
        netherTempest = true
    end
    
    if talents.hasSuperNova then
        superNova = true
    end
    
    if talents.hasProdigiousSavant then
        prodigious = true
        prodigiousSavant = true
    end
    
    if talents.hasSlipstream then
        slipstream = true
    end
    
    if API.IsSpellKnown(spells.ARCANE_BARRAGE) then
        arcaneBarrage = true
    end
    
    if API.IsSpellKnown(spells.ARCANE_BLAST) then
        arcaneBlast = true
    end
    
    if API.IsSpellKnown(spells.ARCANE_MISSILES) then
        arcaneMissiles = true
    end
    
    if API.IsSpellKnown(spells.ARCANE_EXPLOSION) then
        arcaneExplosion = true
    end
    
    if API.IsSpellKnown(spells.ARCANE_POWER) then
        arcanePower = true
    end
    
    if API.IsSpellKnown(spells.ARCANE_WARD) then
        arcaneWard = true
    end
    
    if API.IsSpellKnown(spells.CLEARCASTING) then
        clearcasting = true
    end
    
    if API.IsSpellKnown(spells.CONJURE_MANA_GEM) then
        conjureManaGem = true
    end
    
    if API.IsSpellKnown(spells.COUNTERSPELL) then
        counterspell = true
    end
    
    if API.IsSpellKnown(spells.EVOCATION) then
        evocation = true
    end
    
    if API.IsSpellKnown(spells.FIRE_BLAST) then
        fireBlast = true
    end
    
    if API.IsSpellKnown(spells.FROST_NOVA) then
        frostNova = true
    end
    
    if API.IsSpellKnown(spells.FROSTBOLT) then
        frostbolt = true
    end
    
    if API.IsSpellKnown(spells.GREATER_INVISIBILITY) then
        greaterInvisibility = true
    else
        invisibility = true
    end
    
    if API.IsSpellKnown(spells.ICE_BLOCK) then
        iceBlock = true
    end
    
    if API.IsSpellKnown(spells.MIRROR_IMAGE) then
        mirrorImage = true
    end
    
    if API.IsSpellKnown(spells.POLYMORPH) then
        polymorph = true
    end
    
    if API.IsSpellKnown(spells.REMOVE_CURSE) then
        removePolymorph = true
    end
    
    if API.IsSpellKnown(spells.SHIMMER) then
        shimmer = true
    end
    
    if API.IsSpellKnown(spells.SLOW_FALL) then
        slowFall = true
    end
    
    if API.IsSpellKnown(spells.SPELLSTEAL) then
        spellsteal = true
    end
    
    if API.IsSpellKnown(spells.TIME_WARP) then
        timeWarp = true
    end
    
    API.PrintDebug("Arcane Mage talents updated")
    
    return true
end

-- Update mana tracking
function Arcane:UpdateMana()
    currentMana = API.GetPlayerManaPercentage()
    return true
end

-- Update arcane charges tracking
function Arcane:UpdateArcaneCharges()
    arcaneCharges = API.GetArcaneCharges()
    return true
end

-- Update health tracking
function Arcane:UpdateHealth()
    playerHealth = API.GetPlayerHealthPercent()
    return true
end

-- Update target health tracking
function Arcane:UpdateTargetHealth()
    targetHealth = API.GetTargetHealthPercent()
    return true
end

-- Update mana gem state
function Arcane:UpdateManaGemState()
    hasManaGem = API.HasManaGem()
    if hasManaGem then
        manaGemCharges = API.GetManaGemCharges()
    else
        manaGemCharges = 0
    end
    return true
end

-- Update active enemy counts
function Arcane:UpdateEnemyCounts()
    activeEnemies = API.GetEnemyCount() or 0
    return true
end

-- Handle out of combat actions
function Arcane:HandleOutOfCombat()
    local settings = ConfigRegistry:GetSettings("ArcaneMage")
    
    -- Cast Arcane Intellect if needed
    if arcaneIntellect and not API.UnitHasBuff("player", buffs.ARCANE_INTELLECT) and API.CanCast(spells.ARCANE_INTELLECT) then
        API.CastSpell(spells.ARCANE_INTELLECT)
        return true
    end
    
    -- Cast Arcane Familiar if needed
    if arcaneFamiliar and not API.UnitHasBuff("player", buffs.ARCANE_FAMILIAR) and API.CanCast(spells.ARCANE_FAMILIAR) then
        API.CastSpell(spells.ARCANE_FAMILIAR)
        return true
    end
    
    -- Conjure Food if needed
    if conjureFood and API.CanCast(spells.CONJURE_FOOD) and settings.utilitySettings.conjureFoodMode ~= "Manual Only" then
        local shouldConjure = false
        
        if settings.utilitySettings.conjureFoodMode == "Always" then
            shouldConjure = true
        elseif settings.utilitySettings.conjureFoodMode == "When Low" then
            local foodCount = API.GetItemCount("Conjured Food")
            shouldConjure = foodCount < 10
        end
        
        if shouldConjure then
            API.CastSpell(spells.CONJURE_FOOD)
            return true
        end
    end
    
    -- Conjure Refreshment if needed
    if conjureRefreshment and API.CanCast(spells.CONJURE_REFRESHMENT) and settings.utilitySettings.conjureFoodMode ~= "Manual Only" then
        local shouldConjure = false
        
        if settings.utilitySettings.conjureFoodMode == "Always" then
            shouldConjure = true
        elseif settings.utilitySettings.conjureFoodMode == "When Low" then
            local foodCount = API.GetItemCount("Conjured Refreshment")
            shouldConjure = foodCount < 10
        end
        
        if shouldConjure then
            API.CastSpell(spells.CONJURE_REFRESHMENT)
            return true
        end
    end
    
    -- Conjure Mana Gem if needed
    if conjureManaGem and API.CanCast(spells.CONJURE_MANA_GEM) and settings.utilitySettings.conjureManaGemMode ~= "Manual Only" then
        self:UpdateManaGemState()
        
        local shouldConjure = false
        
        if settings.utilitySettings.conjureManaGemMode == "Always" then
            shouldConjure = not hasManaGem or manaGemCharges < 3
        elseif settings.utilitySettings.conjureManaGemMode == "When Missing" then
            shouldConjure = not hasManaGem
        end
        
        if shouldConjure then
            API.CastSpell(spells.CONJURE_MANA_GEM)
            return true
        end
    end
    
    return false
end

-- Handle spell cast success
function Arcane:HandleSpellCastSuccess(spellID)
    if spellID == spells.ARCANE_BARRAGE then
        lastArcaneBarrage = GetTime()
        arcaneCharges = 0 -- Arcane Barrage consumes all charges
        API.PrintDebug("Arcane Barrage cast")
    elseif spellID == spells.ARCANE_BLAST then
        lastArcaneBlast = GetTime()
        -- Arcane Blast increases Arcane Charges, handled by UpdateArcaneCharges
        API.PrintDebug("Arcane Blast cast")
    elseif spellID == spells.ARCANE_EXPLOSION then
        lastArcaneExplosion = GetTime()
        -- Arcane Explosion increases Arcane Charges, handled by UpdateArcaneCharges
        API.PrintDebug("Arcane Explosion cast")
    elseif spellID == spells.ARCANE_ORB then
        lastArcaneOrb = GetTime()
        arcaneOrbActive = true
        arcaneOrbEndTime = GetTime() + 15.0 -- Approximate duration
        API.PrintDebug("Arcane Orb cast")
    elseif spellID == spells.ARCANE_POWER then
        lastArcanePower = GetTime()
        arcanePowerActive = true
        arcanePowerEndTime = GetTime() + ARCANE_POWER_DURATION
        API.PrintDebug("Arcane Power cast")
    elseif spellID == spells.ARCANE_WARD then
        lastArcaneWard = GetTime()
        arcaneWardActive = true
        arcaneWardEndTime = GetTime() + ARCANE_WARD_DURATION
        API.PrintDebug("Arcane Ward cast")
    elseif spellID == spells.COUNTERSPELL then
        lastCounterspell = GetTime()
        API.PrintDebug("Counterspell cast")
    elseif spellID == spells.PRESENCE_OF_MIND then
        lastPresenceOfMind = GetTime()
        presenceOfMindActive = true
        presenceOfMindEndTime = GetTime() + PRESENCE_OF_MIND_DURATION
        presenceOfMindStacks = 2 -- Initial stacks
        API.PrintDebug("Presence of Mind cast")
    elseif spellID == spells.EVOCATION then
        lastEvocation = GetTime()
        evocationActive = true
        evocationEndTime = GetTime() + 6.0 -- Channel duration
        API.PrintDebug("Evocation cast")
    elseif spellID == spells.FIRE_BLAST then
        lastFireBlast = GetTime()
        API.PrintDebug("Fire Blast cast")
    elseif spellID == spells.FROST_NOVA then
        lastFrostNova = GetTime()
        API.PrintDebug("Frost Nova cast")
    elseif spellID == spells.FROSTBOLT then
        lastFrostbolt = GetTime()
        API.PrintDebug("Frostbolt cast")
    elseif spellID == spells.GREATER_INVISIBILITY then
        lastGreaterInvisibility = GetTime()
        greaterInvisibilityActive = true
        greaterInvisibilityEndTime = GetTime() + 3.0 -- Buff duration
        API.PrintDebug("Greater Invisibility cast")
    elseif spellID == spells.ICE_BLOCK then
        lastIceBlock = GetTime()
        iceBlockActive = true
        iceBlockEndTime = GetTime() + 10.0 -- Buff duration
        API.PrintDebug("Ice Block cast")
    elseif spellID == spells.INVISIBILITY then
        lastInvisibility = GetTime()
        invisibilityActive = true
        invisibilityEndTime = GetTime() + 20.0 -- Fade duration + invisibility duration
        API.PrintDebug("Invisibility cast")
    elseif spellID == spells.MIRROR_IMAGE then
        lastMirrorImage = GetTime()
        API.PrintDebug("Mirror Image cast")
    elseif spellID == spells.POLYMORPH then
        lastPolymorph = GetTime()
        API.PrintDebug("Polymorph cast")
    elseif spellID == spells.SHIMMER then
        lastShimmer = GetTime()
        API.PrintDebug("Shimmer cast")
    elseif spellID == spells.SLOW_FALL then
        lastSlowFall = GetTime()
        API.PrintDebug("Slow Fall cast")
    elseif spellID == spells.SPELLSTEAL then
        lastSpellsteal = GetTime()
        API.PrintDebug("Spellsteal cast")
    elseif spellID == spells.ARCANE_FAMILIAR then
        lastArcaneFamiliar = GetTime()
        arcaneFamiliarActive = true
        arcaneFamiliarEndTime = GetTime() + ARCANE_FAMILIAR_DURATION
        API.PrintDebug("Arcane Familiar cast")
    elseif spellID == spells.ARCANE_INTELLECT then
        lastArcaneIntellect = GetTime()
        arcaneIntellectActive = true
        arcaneIntellectEndTime = GetTime() + 3600.0 -- 1 hour buff
        API.PrintDebug("Arcane Intellect cast")
    elseif spellID == spells.ARCANE_SURGE then
        lastArcaneSurge = GetTime()
        arcaneSurgeActive = true
        arcaneSurgeEndTime = GetTime() + ARCANE_SURGE_DURATION
        API.PrintDebug("Arcane Surge cast")
    elseif spellID == spells.RADIANT_SPARK then
        lastRadiantSpark = GetTime()
        radiantSparkActive = true
        radiantSparkEndTime = GetTime() + RADIANT_SPARK_DURATION
        API.PrintDebug("Radiant Spark cast")
    elseif spellID == spells.RUNE_OF_POWER then
        lastRuneOfPower = GetTime()
        runeOfPowerActive = true
        runeOfPowerEndTime = GetTime() + RUNE_OF_POWER_DURATION
        API.PrintDebug("Rune of Power cast")
    elseif spellID == spells.TOUCH_OF_THE_MAGI then
        lastTouchOfTheMagi = GetTime()
        touchOfTheMagiActive = true
        touchOfTheMagiEndTime = GetTime() + TOUCH_OF_THE_MAGI_DURATION
        API.PrintDebug("Touch of the Magi cast")
    elseif spellID == spells.NETHER_TEMPEST then
        lastNetherTempest = GetTime()
        netherTempestActive = true
        netherTempestEndTime = GetTime() + NETHER_TEMPEST_DURATION
        API.PrintDebug("Nether Tempest cast")
    elseif spellID == spells.SUPERNOVA then
        lastSuperNova = GetTime()
        superNovaActive = true
        superNovaEndTime = GetTime() + 1.0 -- Effect duration is very short
        API.PrintDebug("Supernova cast")
    elseif spellID == spells.TIME_WARP then
        lastTimeWarp = GetTime()
        timeWarpActive = true
        timeWarpEndTime = GetTime() + TIME_WARP_DURATION
        API.PrintDebug("Time Warp cast")
    end
    
    return true
end

-- Handle channel start
function Arcane:HandleChannelStart(spellID)
    if spellID == spells.ARCANE_MISSILES then
        arcaneMissilesActive = true
        lastArcaneMissiles = GetTime()
        API.PrintDebug("Arcane Missiles channel started")
    elseif spellID == spells.EVOCATION then
        evocationActive = true
        lastEvocation = GetTime()
        API.PrintDebug("Evocation channel started")
    end
    
    return true
end

-- Handle channel stop
function Arcane:HandleChannelStop(spellID)
    if spellID == spells.ARCANE_MISSILES then
        arcaneMissilesActive = false
        API.PrintDebug("Arcane Missiles channel stopped")
    elseif spellID == spells.EVOCATION then
        evocationActive = false
        API.PrintDebug("Evocation channel stopped")
    end
    
    return true
end

-- Handle combat log events
function Arcane:HandleCombatLogEvent(...)
    local timestamp, eventType, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, spellID, spellName = CombatLogGetCurrentEventInfo()
    
    -- Track player events (casts, buffs, etc.)
    if sourceGUID == API.GetPlayerGUID() then
        -- Track buff applications
        if eventType == "SPELL_AURA_APPLIED" or eventType == "SPELL_AURA_REFRESH" then
            -- Track Clearcasting application
            if spellID == buffs.CLEARCASTING then
                clearcastingActive = true
                clearcastingEndTime = select(6, API.GetBuffInfo("player", buffs.CLEARCASTING))
                clearcastingStacks = select(4, API.GetBuffInfo("player", buffs.CLEARCASTING)) or 1
                API.PrintDebug("Clearcasting activated: " .. tostring(clearcastingStacks) .. " stack(s)")
            end
            
            -- Track Arcane Power application
            if spellID == buffs.ARCANE_POWER then
                arcanePowerActive = true
                arcanePowerEndTime = select(6, API.GetBuffInfo("player", buffs.ARCANE_POWER))
                API.PrintDebug("Arcane Power activated")
            end
            
            -- Track Presence of Mind application
            if spellID == buffs.PRESENCE_OF_MIND then
                presenceOfMindActive = true
                presenceOfMindEndTime = select(6, API.GetBuffInfo("player", buffs.PRESENCE_OF_MIND))
                presenceOfMindStacks = select(4, API.GetBuffInfo("player", buffs.PRESENCE_OF_MIND)) or 2
                API.PrintDebug("Presence of Mind activated: " .. tostring(presenceOfMindStacks) .. " stack(s)")
            end
            
            -- Track Arcane Familiar application
            if spellID == buffs.ARCANE_FAMILIAR then
                arcaneFamiliarActive = true
                arcaneFamiliarEndTime = select(6, API.GetBuffInfo("player", buffs.ARCANE_FAMILIAR))
                API.PrintDebug("Arcane Familiar activated")
            end
            
            -- Track Arcane Intellect application
            if spellID == buffs.ARCANE_INTELLECT then
                arcaneIntellectActive = true
                arcaneIntellectEndTime = select(6, API.GetBuffInfo("player", buffs.ARCANE_INTELLECT))
                API.PrintDebug("Arcane Intellect activated")
            end
            
            -- Track Arcane Ward application
            if spellID == buffs.ARCANE_WARD then
                arcaneWardActive = true
                arcaneWardEndTime = select(6, API.GetBuffInfo("player", buffs.ARCANE_WARD))
                API.PrintDebug("Arcane Ward activated")
            end
            
            -- Track Arcane Surge application
            if spellID == buffs.ARCANE_SURGE then
                arcaneSurgeActive = true
                arcaneSurgeEndTime = select(6, API.GetBuffInfo("player", buffs.ARCANE_SURGE))
                API.PrintDebug("Arcane Surge activated")
            end
            
            -- Track Bursting Power application
            if spellID == buffs.BURSTING_POWER then
                burstingPowerActive = true
                burstingPowerEndTime = select(6, API.GetBuffInfo("player", buffs.BURSTING_POWER))
                API.PrintDebug("Bursting Power activated")
            end
            
            -- Track Chrono Shift application
            if spellID == buffs.CHRONO_SHIFT then
                chronoShiftActive = true
                chronoShiftEndTime = select(6, API.GetBuffInfo("player", buffs.CHRONO_SHIFT))
                API.PrintDebug("Chrono Shift activated")
            end
            
            -- Track Enlightened application
            if spellID == buffs.ENLIGHTENED then
                enlightenedActive = true
                enlightenedEndTime = select(6, API.GetBuffInfo("player", buffs.ENLIGHTENED))
                API.PrintDebug("Enlightened activated")
            end
            
            -- Track Everlasting Warmth application
            if spellID == buffs.EVERLASTING_WARMTH then
                everlastingWarmthActive = true
                everlastingWarmthEndTime = select(6, API.GetBuffInfo("player", buffs.EVERLASTING_WARMTH))
                API.PrintDebug("Everlasting Warmth activated")
            end
            
            -- Track Rune of Power application
            if spellID == buffs.RUNE_OF_POWER then
                runeOfPowerActive = true
                runeOfPowerEndTime = select(6, API.GetBuffInfo("player", buffs.RUNE_OF_POWER))
                API.PrintDebug("Rune of Power activated")
            end
            
            -- Track Temporal Warp application
            if spellID == buffs.TEMPORAL_WARP then
                temporalWarpActive = true
                temporalWarpEndTime = select(6, API.GetBuffInfo("player", buffs.TEMPORAL_WARP))
                API.PrintDebug("Temporal Warp activated")
            end
            
            -- Track Time Anomaly application
            if spellID == buffs.TIME_ANOMALY then
                timeAnomalyActive = true
                timeAnomalyEndTime = select(6, API.GetBuffInfo("player", buffs.TIME_ANOMALY))
                API.PrintDebug("Time Anomaly activated")
            end
            
            -- Track Shimmering Power application
            if spellID == buffs.SHIMMERING_POWER then
                shimmeringPowerActive = true
                shimmeringPowerEndTime = select(6, API.GetBuffInfo("player", buffs.SHIMMERING_POWER))
                API.PrintDebug("Shimmering Power activated")
            end
            
            -- Track Time Warp/Bloodlust/Heroism application
            if spellID == buffs.TIME_WARP or spellID == buffs.BLOODLUST or spellID == buffs.HEROISM then
                timeWarpActive = true
                bloodlustActive = true
                timeWarpEndTime = select(6, API.GetBuffInfo("player", spellID))
                bloodlustEndTime = timeWarpEndTime
                API.PrintDebug("Time Warp/Bloodlust activated")
            end
            
            -- Track Prodigious Savant application
            if spellID == buffs.PRODIGIOUS_SAVANT then
                prodigiousSavantActive = true
                prodigiousSavantEndTime = select(6, API.GetBuffInfo("player", buffs.PRODIGIOUS_SAVANT))
                API.PrintDebug("Prodigious Savant activated")
            end
            
            -- Track Slipstream application
            if spellID == buffs.SLIPSTREAM then
                slipstreamActive = true
                slipstreamEndTime = select(6, API.GetBuffInfo("player", buffs.SLIPSTREAM))
                API.PrintDebug("Slipstream activated")
            end
            
            -- Track Greater Invisibility application
            if spellID == buffs.GREATER_INVISIBILITY then
                greaterInvisibilityActive = true
                greaterInvisibilityEndTime = select(6, API.GetBuffInfo("player", buffs.GREATER_INVISIBILITY))
                API.PrintDebug("Greater Invisibility activated")
            end
            
            -- Track Ice Block application
            if spellID == buffs.ICE_BLOCK then
                iceBlockActive = true
                iceBlockEndTime = select(6, API.GetBuffInfo("player", buffs.ICE_BLOCK))
                API.PrintDebug("Ice Block activated")
            end
            
            -- Track Invisibility application
            if spellID == buffs.INVISIBILITY then
                invisibilityActive = true
                invisibilityEndTime = select(6, API.GetBuffInfo("player", buffs.INVISIBILITY))
                API.PrintDebug("Invisibility activated")
            end
            
            -- Track Slow Fall application
            if spellID == buffs.SLOW_FALL then
                slowFallActive = true
                slowFallEndTime = select(6, API.GetBuffInfo("player", buffs.SLOW_FALL))
                API.PrintDebug("Slow Fall activated")
            end
        end
        
        -- Track buff removals
        if eventType == "SPELL_AURA_REMOVED" then
            -- Track Clearcasting removal
            if spellID == buffs.CLEARCASTING then
                clearcastingActive = false
                clearcastingStacks = 0
                API.PrintDebug("Clearcasting faded")
            end
            
            -- Track Arcane Power removal
            if spellID == buffs.ARCANE_POWER then
                arcanePowerActive = false
                API.PrintDebug("Arcane Power faded")
            end
            
            -- Track Presence of Mind removal
            if spellID == buffs.PRESENCE_OF_MIND then
                presenceOfMindActive = false
                presenceOfMindStacks = 0
                API.PrintDebug("Presence of Mind faded")
            end
            
            -- Track Arcane Familiar removal
            if spellID == buffs.ARCANE_FAMILIAR then
                arcaneFamiliarActive = false
                API.PrintDebug("Arcane Familiar faded")
            end
            
            -- Track Arcane Intellect removal
            if spellID == buffs.ARCANE_INTELLECT then
                arcaneIntellectActive = false
                API.PrintDebug("Arcane Intellect faded")
            end
            
            -- Track Arcane Ward removal
            if spellID == buffs.ARCANE_WARD then
                arcaneWardActive = false
                API.PrintDebug("Arcane Ward faded")
            end
            
            -- Track Arcane Surge removal
            if spellID == buffs.ARCANE_SURGE then
                arcaneSurgeActive = false
                API.PrintDebug("Arcane Surge faded")
            end
            
            -- Track Bursting Power removal
            if spellID == buffs.BURSTING_POWER then
                burstingPowerActive = false
                API.PrintDebug("Bursting Power faded")
            end
            
            -- Track Chrono Shift removal
            if spellID == buffs.CHRONO_SHIFT then
                chronoShiftActive = false
                API.PrintDebug("Chrono Shift faded")
            end
            
            -- Track Enlightened removal
            if spellID == buffs.ENLIGHTENED then
                enlightenedActive = false
                API.PrintDebug("Enlightened faded")
            end
            
            -- Track Everlasting Warmth removal
            if spellID == buffs.EVERLASTING_WARMTH then
                everlastingWarmthActive = false
                API.PrintDebug("Everlasting Warmth faded")
            end
            
            -- Track Rune of Power removal
            if spellID == buffs.RUNE_OF_POWER then
                runeOfPowerActive = false
                API.PrintDebug("Rune of Power faded")
            end
            
            -- Track Temporal Warp removal
            if spellID == buffs.TEMPORAL_WARP then
                temporalWarpActive = false
                API.PrintDebug("Temporal Warp faded")
            end
            
            -- Track Time Anomaly removal
            if spellID == buffs.TIME_ANOMALY then
                timeAnomalyActive = false
                API.PrintDebug("Time Anomaly faded")
            end
            
            -- Track Shimmering Power removal
            if spellID == buffs.SHIMMERING_POWER then
                shimmeringPowerActive = false
                API.PrintDebug("Shimmering Power faded")
            end
            
            -- Track Time Warp/Bloodlust/Heroism removal
            if spellID == buffs.TIME_WARP or spellID == buffs.BLOODLUST or spellID == buffs.HEROISM then
                timeWarpActive = false
                bloodlustActive = false
                API.PrintDebug("Time Warp/Bloodlust faded")
            end
            
            -- Track Prodigious Savant removal
            if spellID == buffs.PRODIGIOUS_SAVANT then
                prodigiousSavantActive = false
                API.PrintDebug("Prodigious Savant faded")
            end
            
            -- Track Slipstream removal
            if spellID == buffs.SLIPSTREAM then
                slipstreamActive = false
                API.PrintDebug("Slipstream faded")
            end
            
            -- Track Greater Invisibility removal
            if spellID == buffs.GREATER_INVISIBILITY then
                greaterInvisibilityActive = false
                API.PrintDebug("Greater Invisibility faded")
            end
            
            -- Track Ice Block removal
            if spellID == buffs.ICE_BLOCK then
                iceBlockActive = false
                API.PrintDebug("Ice Block faded")
            end
            
            -- Track Invisibility removal
            if spellID == buffs.INVISIBILITY then
                invisibilityActive = false
                API.PrintDebug("Invisibility faded")
            end
            
            -- Track Slow Fall removal
            if spellID == buffs.SLOW_FALL then
                slowFallActive = false
                API.PrintDebug("Slow Fall faded")
            end
        end
        
        -- Track debuff applications on target
        if (eventType == "SPELL_AURA_APPLIED" or eventType == "SPELL_AURA_REFRESH") and destGUID then
            -- Track Radiant Spark application
            if spellID == debuffs.RADIANT_SPARK then
                radiantSparkActive = true
                radiantSparkEndTime = select(6, API.GetDebuffInfo(destGUID, debuffs.RADIANT_SPARK))
                API.PrintDebug("Radiant Spark applied to " .. destName)
            end
            
            -- Track Radiant Spark Vulnerability application
            if spellID == debuffs.RADIANT_SPARK_VULNERABILITY then
                API.PrintDebug("Radiant Spark Vulnerability applied to " .. destName)
            end
            
            -- Track Touch of the Magi application
            if spellID == debuffs.TOUCH_OF_THE_MAGI then
                touchOfTheMagiActive = true
                touchOfTheMagiEndTime = select(6, API.GetDebuffInfo(destGUID, debuffs.TOUCH_OF_THE_MAGI))
                API.PrintDebug("Touch of the Magi applied to " .. destName)
            end
            
            -- Track Nether Tempest application
            if spellID == debuffs.NETHER_TEMPEST then
                netherTempestActive = true
                netherTempestEndTime = select(6, API.GetDebuffInfo(destGUID, debuffs.NETHER_TEMPEST))
                API.PrintDebug("Nether Tempest applied to " .. destName)
            end
        end
        
        -- Track debuff removals from target
        if eventType == "SPELL_AURA_REMOVED" and destGUID then
            -- Track Radiant Spark removal
            if spellID == debuffs.RADIANT_SPARK then
                if destGUID == API.UnitGUID("target") then
                    radiantSparkActive = false
                end
                API.PrintDebug("Radiant Spark removed from " .. destName)
            end
            
            -- Track Touch of the Magi removal
            if spellID == debuffs.TOUCH_OF_THE_MAGI then
                if destGUID == API.UnitGUID("target") then
                    touchOfTheMagiActive = false
                end
                API.PrintDebug("Touch of the Magi removed from " .. destName)
            end
            
            -- Track Nether Tempest removal
            if spellID == debuffs.NETHER_TEMPEST then
                if destGUID == API.UnitGUID("target") then
                    netherTempestActive = false
                end
                API.PrintDebug("Nether Tempest removed from " .. destName)
            end
        end
    end
    
    return true
end

-- Main rotation function
function Arcane:RunRotation()
    -- Check if we should be running Arcane Mage logic
    if API.GetActiveSpecID() ~= ARCANE_SPEC_ID then
        return false
    end
    
    -- Skip rotation if player is casting or channeling
    if API.IsPlayerCasting() or arcaneMissilesActive or evocationActive then
        return false
    end
    
    -- Skip if player is in Ice Block
    if iceBlockActive then
        return false
    }
    
    -- Get settings
    local settings = ConfigRegistry:GetSettings("ArcaneMage")
    
    -- Update variables
    self:UpdateArcaneCharges()
    self:UpdateEnemyCounts()
    self:UpdateManaGemState()
    burstModeActive = settings.rotationSettings.burstEnabled and API.ShouldUseBurst()
    isInMelee = API.IsUnitInMeleeRange("player")
    
    -- Handle next cast override
    if nextCastOverride and API.CanCast(nextCastOverride) then
        local spell = nextCastOverride
        nextCastOverride = nil
        API.CastSpell(spell)
        return true
    end
    
    -- Handle out of combat tasks
    if not inCombat then
        if self:HandleOutOfCombat() then
            return true
        end
    end
    
    -- Handle defensive cooldowns
    if self:HandleDefensives(settings) then
        return true
    end
    
    -- Handle interrupts and utility
    if self:HandleInterrupts(settings) then
        return true
    end
    
    -- Handle mana management
    if self:HandleManaManagement(settings) then
        return true
    }
    
    -- Check for valid target in combat
    if not API.UnitExists("target") or not API.IsUnitEnemy("target") then
        return false
    end
    
    -- Handle major cooldowns
    if self:HandleMajorCooldowns(settings) then
        return true
    end
    
    -- Handle core rotation
    if activeEnemies >= settings.rotationSettings.aoeThreshold and settings.rotationSettings.aoeEnabled then
        return self:HandleAoE(settings)
    else
        return self:HandleSingleTarget(settings)
    end
end

-- Handle defensive cooldowns
function Arcane:HandleDefensives(settings)
    -- Use Ice Block as emergency defensive
    if iceBlock and 
       settings.defensiveSettings.useIceBlock and 
       playerHealth <= settings.defensiveSettings.iceBlockThreshold and 
       API.CanCast(spells.ICE_BLOCK) then
        API.CastSpell(spells.ICE_BLOCK)
        return true
    end
    
    -- Use Greater Invisibility as defensive
    if greaterInvisibility and 
       settings.defensiveSettings.useGreaterInvisibility and 
       playerHealth <= settings.defensiveSettings.greaterInvisibilityThreshold and 
       API.CanCast(spells.GREATER_INVISIBILITY) then
        API.CastSpell(spells.GREATER_INVISIBILITY)
        return true
    end
    
    -- Use Invisibility as defensive if Greater Invisibility not available
    if not greaterInvisibility and invisibility and 
       settings.defensiveSettings.useGreaterInvisibility and 
       playerHealth <= settings.defensiveSettings.greaterInvisibilityThreshold and 
       API.CanCast(spells.INVISIBILITY) then
        API.CastSpell(spells.INVISIBILITY)
        return true
    end
    
    -- Use Arcane Ward
    if arcaneWard and 
       settings.defensiveSettings.useArcaneWard and 
       settings.defensiveSettings.arcaneWardMode ~= "Manual Only" and
       not arcaneWardActive and
       API.CanCast(spells.ARCANE_WARD) then
        
        local shouldUseWard = false
        
        if settings.defensiveSettings.arcaneWardMode == "On Cooldown" then
            shouldUseWard = true
        elseif settings.defensiveSettings.arcaneWardMode == "When Taking Damage" then
            shouldUseWard = playerHealth < 95 or API.IsPlayerBeingAttacked()
        end
        
        if shouldUseWard then
            API.CastSpell(spells.ARCANE_WARD)
            return true
        end
    end
    
    -- Use Slow Fall when falling
    if slowFall and 
       settings.utilitySettings.useSlowFall and 
       API.IsFalling() and 
       not API.UnitHasBuff("player", buffs.SLOW_FALL) and
       API.CanCast(spells.SLOW_FALL) then
        API.CastSpell(spells.SLOW_FALL)
        return true
    end
    
    return false
end

-- Handle interrupts and utility
function Arcane:HandleInterrupts(settings)
    -- Use Counterspell to interrupt spellcasting
    if counterspell and 
       API.CanCast(spells.COUNTERSPELL) and
       API.IsUnitCasting("target") and
       API.CanBeInterrupted("target") then
        API.CastSpellOnUnit(spells.COUNTERSPELL, "target")
        return true
    end
    
    -- Use Frost Nova for mobs in melee range
    if frostNova and 
       settings.utilitySettings.useFrostNova and 
       isInMelee and
       API.CanCast(spells.FROST_NOVA) then
        API.CastSpell(spells.FROST_NOVA)
        return true
    end
    
    -- Use Polymorph for crowd control
    if polymorph and 
       settings.utilitySettings.usePolymorph and 
       API.CanCast(spells.POLYMORPH) and
       API.ShouldCrowdControl("target") then
        API.CastSpellOnUnit(spells.POLYMORPH, "target")
        return true
    end
    
    -- Use Spellsteal on enemies with stealable buffs
    if spellsteal and 
       settings.utilitySettings.useSpellsteal and 
       API.CanCast(spells.SPELLSTEAL) and
       API.HasStealableBuff("target") then
        API.CastSpellOnUnit(spells.SPELLSTEAL, "target")
        return true
    end
    
    return false
end

-- Handle mana management
function Arcane:HandleManaManagement(settings)
    -- Use Evocation to restore mana
    if evocation and 
       API.CanCast(spells.EVOCATION) and
       currentMana < 20 and
       not API.IsPlayerMoving() then
        API.CastSpell(spells.EVOCATION)
        return true
    end
    
    -- Use Mana Gem if available
    if hasManaGem and manaGemCharges > 0 and
       settings.rotationSettings.useManaGem and
       currentMana <= settings.rotationSettings.manaGemThreshold then
        API.UseManaGem()
        return true
    end
    
    return false
end

-- Handle major cooldowns
function Arcane:HandleMajorCooldowns(settings)
    -- Use Time Warp
    if timeWarp and 
       settings.cooldownSettings.useTimeWarp and 
       settings.cooldownSettings.timeWarpMode ~= "Manual Only" and
       API.CanCast(spells.TIME_WARP) and
       not API.HasBloodlustDebuff() then
        
        local shouldUseTimeWarp = false
        
        if settings.cooldownSettings.timeWarpMode == "On Pull" and not API.PlayerInCombatForSeconds(5) then
            shouldUseTimeWarp = true
        elseif settings.cooldownSettings.timeWarpMode == "With Cooldowns" and burstModeActive then
            shouldUseTimeWarp = true
        elseif settings.cooldownSettings.timeWarpMode == "Boss Only" and API.IsFightingBoss() then
            shouldUseTimeWarp = true
        end
        
        if shouldUseTimeWarp then
            API.CastSpell(spells.TIME_WARP)
            return true
        end
    end
    
    -- Use Touch of the Magi
    if touchOfTheMagi and 
       settings.cooldownSettings.useTouchOfTheMagi and 
       settings.cooldownSettings.touchOfTheMagiMode ~= "Manual Only" and
       API.CanCast(spells.TOUCH_OF_THE_MAGI) then
        
        local shouldUseTouchOfTheMagi = false
        
        if settings.cooldownSettings.touchOfTheMagiMode == "On Cooldown" then
            shouldUseTouchOfTheMagi = true
        elseif settings.cooldownSettings.touchOfTheMagiMode == "With Arcane Power" then
            shouldUseTouchOfTheMagi = arcanePowerActive or API.GetSpellCooldown(spells.ARCANE_POWER) == 0
        elseif settings.cooldownSettings.touchOfTheMagiMode == "Boss Only" then
            shouldUseTouchOfTheMagi = API.IsFightingBoss()
        end
        
        if shouldUseTouchOfTheMagi then
            API.CastSpellOnUnit(spells.TOUCH_OF_THE_MAGI, "target")
            return true
        end
    end
    
    -- Use Arcane Power
    if arcanePower and 
       settings.cooldownSettings.useArcanePower and 
       settings.cooldownSettings.arcanePowerMode ~= "Manual Only" and
       API.CanCast(spells.ARCANE_POWER) then
        
        local shouldUseArcanePower = false
        
        if settings.cooldownSettings.arcanePowerMode == "On Cooldown" then
            shouldUseArcanePower = true
        elseif settings.cooldownSettings.arcanePowerMode == "With Touch of the Magi" then
            shouldUseArcanePower = touchOfTheMagiActive or (API.GetSpellCooldown(spells.TOUCH_OF_THE_MAGI) < 2 and API.GetSpellCooldown(spells.TOUCH_OF_THE_MAGI) > 0)
        elseif settings.cooldownSettings.arcanePowerMode == "Boss Only" then
            shouldUseArcanePower = API.IsFightingBoss()
        end
        
        if shouldUseArcanePower then
            API.CastSpell(spells.ARCANE_POWER)
            return true
        end
    end
    
    -- Use Rune of Power
    if runeOfPower and 
       settings.cooldownSettings.useRuneOfPower and 
       settings.cooldownSettings.runeOfPowerMode ~= "Manual Only" and
       API.CanCast(spells.RUNE_OF_POWER) and
       not API.IsPlayerMoving() then
        
        local shouldUseRuneOfPower = false
        
        if settings.cooldownSettings.runeOfPowerMode == "On Cooldown" then
            shouldUseRuneOfPower = true
        elseif settings.cooldownSettings.runeOfPowerMode == "With Cooldowns" then
            shouldUseRuneOfPower = arcanePowerActive or touchOfTheMagiActive or burstModeActive
        elseif settings.cooldownSettings.runeOfPowerMode == "Boss Only" then
            shouldUseRuneOfPower = API.IsFightingBoss()
        end
        
        if shouldUseRuneOfPower then
            API.CastSpell(spells.RUNE_OF_POWER)
            return true
        end
    end
    
    -- Use Radiant Spark
    if radiantSpark and 
       settings.cooldownSettings.useRadiantSpark and 
       settings.cooldownSettings.radiantSparkMode ~= "Manual Only" and
       API.CanCast(spells.RADIANT_SPARK) then
        
        local shouldUseRadiantSpark = false
        
        if settings.cooldownSettings.radiantSparkMode == "On Cooldown" then
            shouldUseRadiantSpark = true
        elseif settings.cooldownSettings.radiantSparkMode == "With Cooldowns" then
            shouldUseRadiantSpark = arcanePowerActive or touchOfTheMagiActive or burstModeActive
        elseif settings.cooldownSettings.radiantSparkMode == "Boss Only" then
            shouldUseRadiantSpark = API.IsFightingBoss()
        end
        
        if shouldUseRadiantSpark then
            API.CastSpellOnUnit(spells.RADIANT_SPARK, "target")
            return true
        end
    end
    
    -- Use Mirror Image
    if mirrorImage and 
       settings.cooldownSettings.useMirrorImage and 
       settings.cooldownSettings.mirrorImageMode ~= "Manual Only" and
       API.CanCast(spells.MIRROR_IMAGE) then
        
        local shouldUseMirrorImage = false
        
        if settings.cooldownSettings.mirrorImageMode == "On Cooldown" then
            shouldUseMirrorImage = true
        elseif settings.cooldownSettings.mirrorImageMode == "With Cooldowns" then
            shouldUseMirrorImage = arcanePowerActive or touchOfTheMagiActive or burstModeActive
        elseif settings.cooldownSettings.mirrorImageMode == "Threat/Defensive" then
            shouldUseMirrorImage = API.GetThreatLevel("player") >= 2 or playerHealth < 50
        end
        
        if shouldUseMirrorImage then
            API.CastSpell(spells.MIRROR_IMAGE)
            return true
        end
    end
    
    -- Use Presence of Mind
    if presenceOfMind and 
       API.CanCast(spells.PRESENCE_OF_MIND) and
       arcaneCharges < maxArcaneCharges then
        API.CastSpell(spells.PRESENCE_OF_MIND)
        return true
    end
    
    return false
end

-- Handle AoE rotation
function Arcane:HandleAoE(settings)
    -- Apply Nether Tempest if talented and not active
    if netherTempest and 
       API.CanCast(spells.NETHER_TEMPEST) and
       arcaneCharges >= 3 and
       (not netherTempestActive or 
        (netherTempestEndTime - GetTime() < settings.abilityControls.arcaneBarrage.refreshNetherTempestThreshold)) then
        API.CastSpellOnUnit(spells.NETHER_TEMPEST, "target")
        return true
    end
    
    -- Use Supernova if talented
    if superNova and 
       API.CanCast(spells.SUPERNOVA) and
       activeEnemies >= 3 then
        API.CastSpell(spells.SUPERNOVA)
        return true
    end
    
    -- Use Arcane Orb if talented
    if arcaneOrb and 
       API.CanCast(spells.ARCANE_ORB) and
       activeEnemies >= 3 then
        API.CastSpell(spells.ARCANE_ORB)
        return true
    end
    
    -- Use Arcane Explosion with Clearcasting or when enough targets
    if arcaneExplosion and 
       API.CanCast(spells.ARCANE_EXPLOSION) then
        
        local shouldUseArcaneExplosion = activeEnemies >= 4
        
        -- Use with Clearcasting if configured
        if clearcastingActive and settings.rotationSettings.clearcastingUsage == "AoE: Explosion, ST: Missiles" then
            shouldUseArcaneExplosion = true
        end
        
        if shouldUseArcaneExplosion then
            API.CastSpell(spells.ARCANE_EXPLOSION)
            return true
        end
    end
    
    -- Use Arcane Barrage at max charges
    if arcaneBarrage and 
       API.CanCast(spells.ARCANE_BARRAGE) and
       arcaneCharges >= settings.abilityControls.arcaneBarrage.minArcaneCharges and
       settings.abilityControls.arcaneBarrage.enabled then
        API.CastSpellOnUnit(spells.ARCANE_BARRAGE, "target")
        return true
    end
    
    -- Use Arcane Missiles with Clearcasting
    if arcaneMissiles and 
       API.CanCast(spells.ARCANE_MISSILES) and
       clearcastingActive and
       settings.rotationSettings.clearcastingUsage == "Always Arcane Missiles" and
       settings.abilityControls.arcaneMissiles.enabled then
        API.CastSpellOnUnit(spells.ARCANE_MISSILES, "target")
        return true
    end
    
    -- Use Arcane Explosion for AoE damage
    if arcaneExplosion and 
       API.CanCast(spells.ARCANE_EXPLOSION) then
        API.CastSpell(spells.ARCANE_EXPLOSION)
        return true
    end
    
    -- Use Fire Blast as filler
    if fireBlast and 
       settings.utilitySettings.useFireBlast and 
       API.CanCast(spells.FIRE_BLAST) then
        API.CastSpellOnUnit(spells.FIRE_BLAST, "target")
        return true
    end
    
    return false
end

-- Handle burn phase
function Arcane:HandleBurnPhase(settings)
    -- Apply Nether Tempest if talented and not active
    if netherTempest and 
       API.CanCast(spells.NETHER_TEMPEST) and
       arcaneCharges >= 3 and
       (not netherTempestActive or 
        (netherTempestEndTime - GetTime() < settings.abilityControls.arcaneBarrage.refreshNetherTempestThreshold)) then
        API.CastSpellOnUnit(spells.NETHER_TEMPEST, "target")
        return true
    end
    
    -- Use Arcane Orb if talented
    if arcaneOrb and 
       API.CanCast(spells.ARCANE_ORB) then
        API.CastSpell(spells.ARCANE_ORB)
        return true
    end
    
    -- Use Arcane Missiles with Clearcasting
    if arcaneMissiles and 
       API.CanCast(spells.ARCANE_MISSILES) and
       clearcastingActive and
       (settings.rotationSettings.clearcastingUsage == "Always Arcane Missiles" or 
        settings.rotationSettings.clearcastingUsage == "AoE: Explosion, ST: Missiles") and
       settings.abilityControls.arcaneMissiles.enabled then
        API.CastSpellOnUnit(spells.ARCANE_MISSILES, "target")
        return true
    end
    
    -- Use Arcane Blast
    if arcaneBlast and 
       API.CanCast(spells.ARCANE_BLAST) and
       (arcaneCharges < settings.abilityControls.arcaneBlast.maxArcaneCharges or
        arcanePowerActive or touchOfTheMagiActive or radiantSparkActive) and
       settings.abilityControls.arcaneBlast.enabled then
        API.CastSpellOnUnit(spells.ARCANE_BLAST, "target")
        return true
    end
    
    -- Use Arcane Barrage to dump charges and restore mana
    if arcaneBarrage and 
       API.CanCast(spells.ARCANE_BARRAGE) and
       arcaneCharges >= settings.abilityControls.arcaneBarrage.minArcaneCharges and
       (currentMana < 20 or not arcanePowerActive) and
       settings.abilityControls.arcaneBarrage.enabled then
        API.CastSpellOnUnit(spells.ARCANE_BARRAGE, "target")
        return true
    end
    
    return false
end

-- Handle conserve phase
function Arcane:HandleConservePhase(settings)
    -- Apply Nether Tempest if talented and not active
    if netherTempest and 
       API.CanCast(spells.NETHER_TEMPEST) and
       arcaneCharges >= 3 and
       (not netherTempestActive or 
        (netherTempestEndTime - GetTime() < settings.abilityControls.arcaneBarrage.refreshNetherTempestThreshold)) then
        API.CastSpellOnUnit(spells.NETHER_TEMPEST, "target")
        return true
    end
    
    -- Use Arcane Missiles with Clearcasting
    if arcaneMissiles and 
       API.CanCast(spells.ARCANE_MISSILES) and
       clearcastingActive and
       (settings.rotationSettings.clearcastingUsage == "Always Arcane Missiles" or 
        settings.rotationSettings.clearcastingUsage == "AoE: Explosion, ST: Missiles") and
       settings.abilityControls.arcaneMissiles.enabled then
        API.CastSpellOnUnit(spells.ARCANE_MISSILES, "target")
        return true
    end
    
    -- Use Arcane Blast until 3-4 charges, then barrage
    if arcaneBlast and 
       API.CanCast(spells.ARCANE_BLAST) and
       arcaneCharges < 3 and
       currentMana > settings.abilityControls.arcaneBlast.manaConserveThreshold and
       settings.abilityControls.arcaneBlast.enabled then
        API.CastSpellOnUnit(spells.ARCANE_BLAST, "target")
        return true
    end
    
    -- Use Arcane Barrage to dump charges and restore mana
    if arcaneBarrage and 
       API.CanCast(spells.ARCANE_BARRAGE) and
       arcaneCharges >= 3 and
       settings.abilityControls.arcaneBarrage.enabled then
        API.CastSpellOnUnit(spells.ARCANE_BARRAGE, "target")
        return true
    end
    
    -- Use Frostbolt as a mana-neutral filler
    if frostbolt and 
       API.CanCast(spells.FROSTBOLT) and
       currentMana < settings.abilityControls.arcaneBlast.manaConserveThreshold then
        API.CastSpellOnUnit(spells.FROSTBOLT, "target")
        return true
    end
    
    -- Use Fire Blast as filler
    if fireBlast and 
       settings.utilitySettings.useFireBlast and 
       API.CanCast(spells.FIRE_BLAST) then
        API.CastSpellOnUnit(spells.FIRE_BLAST, "target")
        return true
    end
    
    return false
end

-- Handle single target rotation
function Arcane:HandleSingleTarget(settings)
    local inBurnPhase = currentMana >= settings.rotationSettings.burnPhaseThreshold || arcanePowerActive || touchOfTheMagiActive || radiantSparkActive
    local inConservePhase = currentMana <= settings.rotationSettings.conservePhaseThreshold && !arcanePowerActive && !touchOfTheMagiActive
    
    if inBurnPhase then
        return self:HandleBurnPhase(settings)
    elseif inConservePhase then
        return self:HandleConservePhase(settings)
    else
        -- In in-between state, use more conservative approach
        return self:HandleConservePhase(settings)
    end
}

-- Handle specialization change
function Arcane:OnSpecializationChanged()
    -- Update talent information
    self:UpdateTalentInfo()
    
    -- Reset state variables
    nextCastOverride = nil
    burstModeActive = false
    currentMana = 100
    maxMana = 100
    arcaneMissiles = false
    arcaneMissilesActive = false
    arcaneMissilesEndTime = 0
    arcaneBarrage = false
    arcaneBlast = false
    arcaneExplosion = false
    arcaneFamiliar = false
    arcaneFamiliarActive = false
    arcaneFamiliarEndTime = 0
    arcaneIntellect = false
    arcaneIntellectActive = false
    arcaneIntellectEndTime = 0
    arcaneOrb = false
    arcaneOrbActive = false
    arcaneOrbEndTime = 0
    arcanePower = false
    arcanePowerActive = false
    arcanePowerEndTime = 0
    arcaneWard = false
    arcaneWardActive = false
    arcaneWardEndTime = 0
    clearcasting = false
    clearcastingActive = false
    clearcastingStacks = 0
    clearcastingEndTime = 0
    conjureFood = false
    conjureManaGem = false
    counterspell = false
    presenceOfMind = false
    presenceOfMindActive = false
    presenceOfMindEndTime = 0
    presenceOfMindStacks = 0
    evocation = false
    evocationActive = false
    evocationEndTime = 0
    fireBlast = false
    frostNova = false
    frostbolt = false
    greaterInvisibility = false
    greaterInvisibilityActive = false
    greaterInvisibilityEndTime = 0
    iceBlock = false
    iceBlockActive = false
    iceBlockEndTime = 0
    invisibility = false
    invisibilityActive = false
    invisibilityEndTime = 0
    mirrorImage = false
    polymorph = false
    removePolymorph = false
    shimmer = false
    slowFall = false
    spellsteal = false
    arcaneSurge = false
    arcaneSurgeActive = false
    arcaneSurgeEndTime = 0
    burstingPower = false
    burstingPowerActive = false
    burstingPowerEndTime = 0
    chargedOrbs = false
    chronoShift = false
    chronoShiftActive = false
    chronoShiftEndTime = 0
    conjureRefreshment = false
    displacement = false
    enlightened = false
    enlightenedActive = false
    enlightenedEndTime = 0
    erosion = false
    erosionActive = false
    erosionEndTime = 0
    everlastingWarmth = false
    everlastingWarmthActive = false
    everlastingWarmthEndTime = 0
    radiantSpark = false
    radiantSparkActive = false
    radiantSparkEndTime = 0
    reverberate = false
    runeOfPower = false
    runeOfPowerActive = false
    runeOfPowerEndTime = 0
    temporalWarp = false
    temporalWarpActive = false
    temporalWarpEndTime = 0
    timeAnomaly = false
    timeAnomalyActive = false
    timeAnomalyEndTime = 0
    touchOfTheMagi = false
    touchOfTheMagiActive = false
    touchOfTheMagiEndTime = 0
    shimmeringPower = false
    shimmeringPowerActive = false
    shimmeringPowerEndTime = 0
    nether = false
    netherTempest = false
    netherTempestActive = false
    netherTempestEndTime = 0
    superNova = false
    superNovaActive = false
    superNovaEndTime = 0
    bloodlust = false
    bloodlustActive = false
    bloodlustEndTime = 0
    timeWarp = false
    timeWarpActive = false
    timeWarpEndTime = 0
    prodigious = false
    prodigiousSavant = false
    prodigiousSavantActive = false
    prodigiousSavantEndTime = 0
    slipstream = false
    slipstreamActive = false
    slipstreamEndTime = 0
    lastArcaneBarrage = 0
    lastArcaneBlast = 0
    lastArcaneMissiles = 0
    lastArcaneExplosion = 0
    lastArcaneOrb = 0
    lastArcanePower = 0
    lastArcaneWard = 0
    lastCounterspell = 0
    lastPresenceOfMind = 0
    lastEvocation = 0
    lastFireBlast = 0
    lastFrostNova = 0
    lastFrostbolt = 0
    lastGreaterInvisibility = 0
    lastIceBlock = 0
    lastInvisibility = 0
    lastMirrorImage = 0
    lastPolymorph = 0
    lastShimmer = 0
    lastSlowFall = 0
    lastSpellsteal = 0
    lastArcaneFamiliar = 0
    lastArcaneIntellect = 0
    lastArcaneSurge = 0
    lastRadiantSpark = 0
    lastRuneOfPower = 0
    lastTouchOfTheMagi = 0
    lastNetherTempest = 0
    lastSuperNova = 0
    lastTimeWarp = 0
    arcaneCharges = 0
    maxArcaneCharges = 4
    playerHealth = 100
    targetHealth = 100
    activeEnemies = 0
    isInMelee = false
    inCombat = false
    hasManaGem = false
    manaGemCharges = 0
    
    API.PrintDebug("Arcane Mage state reset on spec change")
    
    return true
end

-- Return the module for loading
return Arcane