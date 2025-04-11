------------------------------------------
-- WindrunnerRotations - Restoration Shaman Module
-- Author: VortexQ8
-- The War Within Season 2
------------------------------------------

local Restoration = {}
-- This will be assigned to addon.Classes.Shaman.Restoration when loaded

-- These will be set when the file is loaded in our test environment
local API
local ConfigRegistry
local AAC
local Shaman

-- Cache frequently accessed data
local spells = {}
local talents = {}
local buffs = {}
local debuffs = {}

-- State tracking variables
local nextCastOverride = nil
local burstModeActive = false
local currentAoETargets = 0
local currentMana = 100
local maxMana = 100
local waterShieldActive = false
local waterShieldEndTime = 0
local waterShieldStacks = 0
local earthShieldActive = false
local earthShieldTargetGUID = nil
local earthShieldTargetName = nil
local earthShieldStacks = 0
local healingRainActive = false
local healingRainEndTime = 0
local healingRainX, healingRainY, healingRainZ = 0, 0, 0
local riptideCharges = 0
local riptideMaxCharges = 0
local highTideActive = false
local highTideStacks = 0
local highTideEndTime = 0
local tidalWavesActive = false
local tidalWavesStacks = 0
local tidalWavesEndTime = 0
local spiritwalkersGraceActive = false
local spiritwalkersGraceEndTime = 0
local ancestralGuidanceActive = false
local ancestralGuidanceEndTime = 0
local cloudburstTotemActive = false
local cloudburstTotemEndTime = 0
local healingTideTotemActive = false
local healingTideTotemEndTime = 0
local healingStreamTotemActive = false
local healingStreamTotemEndTime = 0
local ascendanceActive = false
local ascendanceEndTime = 0
local chainHarvestActive = false
local chainHarvestEndTime = 0
local vesperTotemActive = false
local vesperTotemEndTime = 0
local primordialWaveActive = false
local primordialWaveEndTime = 0
local fadeActive = false
local fadeEndTime = 0
local wellspringCasting = false
local downpourActive = false
local downpourEndTime = 0
local waterShieldOverflowActive = false
local waterShieldOverflowStacks = 0
local waterShieldOverflowEndTime = 0
local flameShockActive = false
local flameShockEndTime = 0
local swirlingCurrentsActive = false
local swirlingCurrentsStacks = 0
local swirlingCurrentsEndTime = 0
local spiritWalkerGrace = false
local gutShot = false
local currentPlayerHealth = 100
local lowestHealthAlly = 100
local lowestHealthAllyName = nil
local tankHealth = 100
local tankName = nil
local averageGroupHealth = 100
local lowHealthAlliesCount = 0
local criticalHealthAlliesCount = 0
local mediumHealthAlliesCount = 0
local poisonTotemActive = false
local poisonTotemEndTime = 0
local spiritwalkersForge = false
local lavaSurge = false
local lavaBurst = false
local primordialWave = false
local healingWave = false
local healingSurge = false
local naturesSwiftness = false
local unleashLife = false
local anchoringTotem = false
local maelstromTotem = false
local totemicRecall = false
local refreshTotemDuration = false
local naturalOrder = false
local sinkingWater = false
local gushingDeluge = false
local naturesWisdom = false
local lashOfFlame = false
local ongoingWaves = false
local seismicShock = false
local healingStream = false
local healingBloom = false
local surgingFlood = false
local rippleInSpace = false
local vortexTotem = false

-- Constants
local RESTORATION_SPEC_ID = 264
local DEFAULT_AOE_THRESHOLD = 3
local WATER_SHIELD_DURATION = 3600 -- seconds (1 hour)
local EARTH_SHIELD_DURATION = 600 -- seconds (10 minutes, effectively permanent)
local RIPTIDE_DURATION = 18 -- seconds
local HEALING_RAIN_DURATION = 10 -- seconds
local HIGH_TIDE_DURATION = 10 -- seconds
local TIDAL_WAVES_DURATION = 15 -- seconds
local SPIRITWALKERS_GRACE_DURATION = 15 -- seconds
local ANCESTRAL_GUIDANCE_DURATION = 10 -- seconds
local CLOUDBURST_TOTEM_DURATION = 15 -- seconds
local HEALING_TIDE_TOTEM_DURATION = 10 -- seconds
local HEALING_STREAM_TOTEM_DURATION = 15 -- seconds
local ASCENDANCE_DURATION = 15 -- seconds
local CHAIN_HARVEST_DURATION = 2.5 -- seconds
local VESPER_TOTEM_DURATION = 30 -- seconds
local FLAMETONGUE_WEAPON_DURATION = 3600 -- seconds (1 hour)
local FLAME_SHOCK_DURATION = 18 -- seconds
local WATER_SHIELD_OVERFLOW_DURATION = 15 -- seconds
local HEALING_RANGE = 40 -- yards
local LOW_HEALTH_THRESHOLD = 70 -- percentage
local CRITICAL_HEALTH_THRESHOLD = 40 -- percentage
local MEDIUM_HEALTH_THRESHOLD = 85 -- percentage

-- Initialize the Restoration module
function Restoration:Initialize()
    self:RegisterSpells()
    self:RegisterVariables()
    self:RegisterSettings()
    self:RegisterEvents()
    
    API.PrintDebug("Restoration Shaman module initialized")
    
    return true
end

-- Register spell IDs
function Restoration:RegisterSpells()
    -- Core healing abilities
    spells.RIPTIDE = 61295
    spells.HEALING_WAVE = 77472
    spells.HEALING_SURGE = 8004
    spells.CHAIN_HEAL = 1064
    spells.HEALING_RAIN = 73920
    spells.WELLSPRING = 197995
    spells.DOWNPOUR = 207778
    
    -- Core utility spells
    spells.WATER_SHIELD = 52127
    spells.EARTH_SHIELD = 974
    spells.PURIFY_SPIRIT = 77130
    spells.CLEANSE_SPIRIT = 51886
    spells.HEX = 51514
    spells.WIND_SHEAR = 57994
    spells.EARTHBIND_TOTEM = 2484
    spells.CAPACITOR_TOTEM = 192058
    spells.TREMOR_TOTEM = 8143
    spells.EARTHGRAB_TOTEM = 51485
    spells.POISON_CLEANSING_TOTEM = 383017
    spells.EARTHEN_WALL_TOTEM = 198838
    spells.WIND_RUSH_TOTEM = 192077
    spells.SPIRITWALKERS_GRACE = 79206
    
    -- Offensive abilities
    spells.FLAME_SHOCK = 188389
    spells.LIGHTNING_BOLT = 188196
    spells.LAVA_BURST = 51505
    spells.CHAIN_LIGHTNING = 188443
    spells.FIRE_NOVA = 333974
    
    -- Major cooldowns
    spells.HEALING_TIDE_TOTEM = 108280
    spells.HEALING_STREAM_TOTEM = 5394
    spells.MANA_TIDE_TOTEM = 16191
    spells.CLOUDBURST_TOTEM = 157153
    spells.ASCENDANCE = 114052
    spells.ANCESTRAL_GUIDANCE = 108281
    spells.SPIRIT_LINK_TOTEM = 98008
    spells.NATURES_SWIFTNESS = 378081
    spells.UNLEASH_LIFE = 73685
    
    -- Talents and passives
    spells.HIGH_TIDE = 157154
    spells.TIDAL_WAVES = 51564
    spells.UNDULATION = 200071
    spells.TORRENT = 200072
    spells.DELUGE = 200076
    spells.SURGE_OF_EARTH = 320746
    spells.ECHO_OF_THE_ELEMENTS = 333919
    spells.FLASH_FLOOD = 280614
    spells.EARTHEN_HARMONY = 384363
    spells.GRACEFUL_SPIRIT = 192088
    spells.HEAVY_RAINFALL = 384361
    spells.IMPROVED_EARTHLIVING_WEAPON = 382021
    spells.REFRESHING_WATERS = 378211
    spells.TOTEMIC_FOCUS = 382201
    spells.ANCESTRAL_VIGOR = 207401
    spells.ANCESTRAL_REACH = 382732
    spells.TIDEBRINGER = 236501
    spells.PRIMAL_TIDE_CORE = 378270
    spells.SWIRLING_CURRENTS = 378094
    spells.WATER_TOTEM_MASTERY = 382027
    spells.EARTHLIVING_WEAPON = 382021
    spells.FLAMETONGUE_WEAPON = 318038
    spells.POISON_CLEANSING_TOTEM = 383017
    spells.STONESKIN_TOTEM = 383017
    spells.TRANQUIL_AIR_TOTEM = 383019
    spells.ANCESTRAL_PROTECTION_TOTEM = 207399
    spells.TOTEMIC_RECALL = 381933
    spells.CALL_OF_THE_ELEMENTS = 383011
    spells.SPIRITWALKERS_FORGE = 378761
    spells.GUTSHOT = 378767
    spells.PRIMORDIAL_WAVE = 375982
    spells.ANCHORING_TOTEM = 409324
    spells.MAELSTROM_TOTEM = 409306
    spells.REFRESHING_TOTEM_DURATION = 383012
    spells.NATURAL_ORDER = 378079
    spells.SINKING_WATER = 365214
    spells.GUSHING_DELUGE = 383303
    spells.NATURES_WISDOM = 378095
    spells.LASH_OF_FLAME = 376170
    spells.ONGOING_WAVES = 378092
    spells.SEISMIC_SHOCK = 379016
    spells.HEALING_BLOOM = 378092
    spells.SURGING_FLOOD = 378106
    spells.RIPPLE_IN_SPACE = 378078
    spells.VORTEX_TOTEM = 409026
    
    -- War Within Season 2 specific
    spells.EARTH_ELEMENTAL = 198103
    spells.MANA_SPRING_TOTEM = 381930
    spells.FOCUSED_DELUGE = 384359
    spells.OVERFLOWING_WATER_SHIELD = 382029
    spells.DEEPLY_ROOTED_ELEMENTS = 378270
    spells.EMPOWER_HEALING_WAVE = 409764
    spells.EMPOWER_HEALING_RAIN = 378489
    spells.EMPOWERED_NATURES_SWIFTNESS = 378297
    spells.ENHANCED_SPIRITWALKERS_GRACE = 381647
    spells.FURY_OF_THE_FATHOMS = 385132
    spells.IMPROVED_SPIRIT_LINK_TOTEM = 384357
    spells.MANA_STREAM_TOTEM = 381930
    spells.RENEWED_FERVENCY = 392929
    spells.TUMULTUOUS_WATER_TOTEM = 386443
    spells.TWISTED_ELEMENTS = 409015

    -- Covenant abilities (for reference, converted in WoW 10.0)
    spells.CHAIN_HARVEST = 375982
    spells.PRIMORDIAL_WAVE = 375982
    spells.VESPER_TOTEM = 324386
    spells.FAE_TRANSFUSION = 328923
    
    -- Buff IDs
    spells.WATER_SHIELD_BUFF = 52127
    spells.EARTH_SHIELD_BUFF = 974
    spells.SPIRITWALKERS_GRACE_BUFF = 79206
    spells.TIDAL_WAVES_BUFF = 53390
    spells.HEALING_RAIN_BUFF = 73920
    spells.HIGH_TIDE_BUFF = 288675
    spells.ASCENDANCE_BUFF = 114052
    spells.ANCESTRAL_GUIDANCE_BUFF = 108281
    spells.UNLEASH_LIFE_BUFF = 73685
    spells.FLAMETONGUE_WEAPON_BUFF = 318038
    spells.EARTHLIVING_WEAPON_BUFF = 382021
    spells.FLASH_FLOOD_BUFF = 280615
    spells.OVERFLOWING_WATER_SHIELD_BUFF = 382030
    spells.SWIRLING_CURRENTS_BUFF = 378095
    spells.DEEPLY_ROOTED_ELEMENTS_BUFF = 378271
    spells.CLOUDBURST_TOTEM_BUFF = 157504
    spells.RIPTIDE_BUFF = 61295
    
    -- Debuff IDs
    spells.FLAME_SHOCK_DEBUFF = 188389
    
    -- Register all spells with the API tracking system
    for spellName, spellID in pairs(spells) do
        API.RegisterSpell(spellID)
    end
    
    -- Define aura tracking
    buffs.WATER_SHIELD = spells.WATER_SHIELD_BUFF
    buffs.EARTH_SHIELD = spells.EARTH_SHIELD_BUFF
    buffs.SPIRITWALKERS_GRACE = spells.SPIRITWALKERS_GRACE_BUFF
    buffs.TIDAL_WAVES = spells.TIDAL_WAVES_BUFF
    buffs.HEALING_RAIN = spells.HEALING_RAIN_BUFF
    buffs.HIGH_TIDE = spells.HIGH_TIDE_BUFF
    buffs.ASCENDANCE = spells.ASCENDANCE_BUFF
    buffs.ANCESTRAL_GUIDANCE = spells.ANCESTRAL_GUIDANCE_BUFF
    buffs.UNLEASH_LIFE = spells.UNLEASH_LIFE_BUFF
    buffs.FLAMETONGUE_WEAPON = spells.FLAMETONGUE_WEAPON_BUFF
    buffs.EARTHLIVING_WEAPON = spells.EARTHLIVING_WEAPON_BUFF
    buffs.FLASH_FLOOD = spells.FLASH_FLOOD_BUFF
    buffs.OVERFLOWING_WATER_SHIELD = spells.OVERFLOWING_WATER_SHIELD_BUFF
    buffs.SWIRLING_CURRENTS = spells.SWIRLING_CURRENTS_BUFF
    buffs.DEEPLY_ROOTED_ELEMENTS = spells.DEEPLY_ROOTED_ELEMENTS_BUFF
    buffs.CLOUDBURST_TOTEM = spells.CLOUDBURST_TOTEM_BUFF
    buffs.RIPTIDE = spells.RIPTIDE_BUFF
    
    debuffs.FLAME_SHOCK = spells.FLAME_SHOCK_DEBUFF
    
    return true
end

-- Register variables to track
function Restoration:RegisterVariables()
    -- Talent tracking
    talents.hasHighTide = false
    talents.hasTidalWaves = false
    talents.hasUndulation = false
    talents.hasTorrent = false
    talents.hasDeluge = false
    talents.hasSurgeOfEarth = false
    talents.hasEchoOfTheElements = false
    talents.hasFlashFlood = false
    talents.hasEarthenHarmony = false
    talents.hasGracefulSpirit = false
    talents.hasHeavyRainfall = false
    talents.hasImprovedEarthlivingWeapon = false
    talents.hasRefreshingWaters = false
    talents.hasTotemicFocus = false
    talents.hasAncestralVigor = false
    talents.hasAncestralReach = false
    talents.hasTidebringer = false
    talents.hasPrimalTideCore = false
    talents.hasSwirlingCurrents = false
    talents.hasWaterTotemMastery = false
    talents.hasEarthlivingWeapon = false
    talents.hasFlametongueWeapon = false
    talents.hasPoisonCleansingTotem = false
    talents.hasStoneskinTotem = false
    talents.hasTranquilAirTotem = false
    talents.hasAncestralProtectionTotem = false
    talents.hasTotemicRecall = false
    talents.hasCallOfTheElements = false
    talents.hasSpiritwalkersForge = false
    talents.hasGutShot = false
    talents.hasPrimordialWave = false
    talents.hasAnchoringTotem = false
    talents.hasMaelstromTotem = false
    talents.hasRefreshingTotemDuration = false
    talents.hasNaturalOrder = false
    talents.hasSinkingWater = false
    talents.hasGushingDeluge = false
    talents.hasNaturesWisdom = false
    talents.hasLashOfFlame = false
    talents.hasOngoingWaves = false
    talents.hasSeismicShock = false
    talents.hasHealingBloom = false
    talents.hasSurgingFlood = false
    talents.hasRippleInSpace = false
    talents.hasVortexTotem = false
    
    -- War Within Season 2 talents
    talents.hasEarthElemental = false
    talents.hasManaSpringTotem = false
    talents.hasFocusedDeluge = false
    talents.hasOverflowingWaterShield = false
    talents.hasDeeplyRootedElements = false
    talents.hasEmpowerHealingWave = false
    talents.hasEmpowerHealingRain = false
    talents.hasEmpoweredNaturesSwiftness = false
    talents.hasEnhancedSpiritwalkersGrace = false
    talents.hasFuryOfTheFathoms = false
    talents.hasImprovedSpiritLinkTotem = false
    talents.hasManaStreamTotem = false
    talents.hasRenewedFervency = false
    talents.hasTumultuousWaterTotem = false
    talents.hasTwistedElements = false
    
    -- Initialize resources
    currentMana = API.GetPlayerMana()
    maxMana = API.GetPlayerMaxMana()
    
    -- Initialize spell charges
    riptideCharges = API.GetSpellCharges(spells.RIPTIDE) or 0
    riptideMaxCharges = API.GetSpellMaxCharges(spells.RIPTIDE) or 1
    
    return true
end

-- Register spec-specific settings
function Restoration:RegisterSettings()
    ConfigRegistry:RegisterSettings("RestorationShaman", {
        healingSettings = {
            healingStyle = {
                displayName = "Healing Style",
                description = "Overall approach to healing",
                type = "dropdown",
                options = {"Reactive", "Proactive", "Balanced", "Mana Efficient"},
                default = "Balanced"
            },
            targetSelectionMethod = {
                displayName = "Target Selection",
                description = "How to prioritize healing targets",
                type = "dropdown",
                options = {"Lowest Health", "Tank Priority", "Smart Priority", "Role Priority"},
                default = "Smart Priority"
            },
            riptideManagement = {
                displayName = "Riptide Management",
                description = "How to use Riptide charges",
                type = "dropdown",
                options = {"Spread", "Tank Focus", "Low Health Focus", "Conserve"},
                default = "Spread"
            },
            riptideThreshold = {
                displayName = "Riptide Health Threshold",
                description = "Health percentage to use Riptide",
                type = "slider",
                min = 50,
                max = 100,
                default = 90
            },
            lowHealthThreshold = {
                displayName = "Low Health Threshold",
                description = "Health percentage to consider a player as low health",
                type = "slider",
                min = 50,
                max = 90,
                default = LOW_HEALTH_THRESHOLD
            },
            criticalHealthThreshold = {
                displayName = "Critical Health Threshold",
                description = "Health percentage to consider a player as critical health",
                type = "slider",
                min = 20,
                max = 60,
                default = CRITICAL_HEALTH_THRESHOLD
            },
            useSurgeOnCritical = {
                displayName = "Use Healing Surge",
                description = "Use Healing Surge on critical health targets",
                type = "toggle",
                default = true
            }
        },
        
        aoeHealingSettings = {
            useHealingRain = {
                displayName = "Use Healing Rain",
                description = "Automatically use Healing Rain",
                type = "toggle",
                default = true
            },
            healingRainThreshold = {
                displayName = "Healing Rain Threshold",
                description = "Minimum injured allies in area to use Healing Rain",
                type = "slider",
                min = 2,
                max = 8,
                default = 3
            },
            useChainHeal = {
                displayName = "Use Chain Heal",
                description = "Automatically use Chain Heal",
                type = "toggle",
                default = true
            },
            chainHealThreshold = {
                displayName = "Chain Heal Threshold",
                description = "Minimum injured allies for Chain Heal",
                type = "slider",
                min = 2,
                max = 6,
                default = 3
            },
            chainHealHealthThreshold = {
                displayName = "Chain Heal Health Threshold",
                description = "Health percentage to use Chain Heal",
                type = "slider",
                min = 50,
                max = 90,
                default = 80
            },
            useWellspring = {
                displayName = "Use Wellspring",
                description = "Automatically use Wellspring when talented",
                type = "toggle",
                default = true
            },
            wellspringThreshold = {
                displayName = "Wellspring Threshold",
                description = "Minimum injured allies for Wellspring",
                type = "slider",
                min = 3,
                max = 10,
                default = 4
            },
            useDownpour = {
                displayName = "Use Downpour",
                description = "Automatically use Downpour when talented",
                type = "toggle",
                default = true
            },
            downpourThreshold = {
                displayName = "Downpour Threshold",
                description = "Minimum injured allies for Downpour",
                type = "slider",
                min = 2,
                max = 8,
                default = 3
            }
        },
        
        totemSettings = {
            useHealingStreamTotem = {
                displayName = "Use Healing Stream Totem",
                description = "Automatically use Healing Stream Totem",
                type = "toggle",
                default = true
            },
            useHealingTideTotem = {
                displayName = "Use Healing Tide Totem",
                description = "Automatically use Healing Tide Totem",
                type = "toggle",
                default = true
            },
            healingTideTotemThreshold = {
                displayName = "Healing Tide Totem Threshold",
                description = "Average group health to use Healing Tide Totem",
                type = "slider",
                min = 30,
                max = 80,
                default = 60
            },
            useCloudburstTotem = {
                displayName = "Use Cloudburst Totem",
                description = "Automatically use Cloudburst Totem when talented",
                type = "toggle",
                default = true
            },
            cloudburstTotemThreshold = {
                displayName = "Cloudburst Totem Threshold",
                description = "Minimum injured allies for Cloudburst Totem",
                type = "slider",
                min = 1,
                max = 6,
                default = 3
            },
            useEarthenWallTotem = {
                displayName = "Use Earthen Wall Totem",
                description = "Automatically use Earthen Wall Totem when talented",
                type = "toggle",
                default = true
            },
            earthenWallTotemThreshold = {
                displayName = "Earthen Wall Totem Threshold",
                description = "Average group health to use Earthen Wall Totem",
                type = "slider",
                min = 40,
                max = 90,
                default = 70
            },
            useSpiritLinkTotem = {
                displayName = "Use Spirit Link Totem",
                description = "Automatically use Spirit Link Totem",
                type = "toggle",
                default = true
            },
            spiritLinkTotemThreshold = {
                displayName = "Spirit Link Totem Threshold",
                description = "Average group health to use Spirit Link Totem",
                type = "slider",
                min = 30,
                max = 70,
                default = 50
            },
            useManaTideTotem = {
                displayName = "Use Mana Tide Totem",
                description = "Automatically use Mana Tide Totem",
                type = "toggle",
                default = true
            },
            manaTideTotemThreshold = {
                displayName = "Mana Tide Totem Threshold",
                description = "Mana percentage to use Mana Tide Totem",
                type = "slider",
                min = 30,
                max = 80,
                default = 60
            }
        },
        
        cooldownSettings = {
            useAscendance = {
                displayName = "Use Ascendance",
                description = "Automatically use Ascendance",
                type = "toggle",
                default = true
            },
            ascendanceThreshold = {
                displayName = "Ascendance Threshold",
                description = "Average group health to use Ascendance",
                type = "slider",
                min = 30,
                max = 70,
                default = 40
            },
            useAncestralGuidance = {
                displayName = "Use Ancestral Guidance",
                description = "Automatically use Ancestral Guidance when talented",
                type = "toggle",
                default = true
            },
            ancestralGuidanceThreshold = {
                displayName = "Ancestral Guidance Threshold",
                description = "Average group health to use Ancestral Guidance",
                type = "slider",
                min = 30,
                max = 80,
                default = 60
            },
            useNaturesSwiftness = {
                displayName = "Use Nature's Swiftness",
                description = "Automatically use Nature's Swiftness",
                type = "toggle",
                default = true
            },
            naturesSwiftnessThreshold = {
                displayName = "Nature's Swiftness Threshold",
                description = "Target health to use Nature's Swiftness",
                type = "slider",
                min = 10,
                max = 70,
                default = 40
            },
            useUnleashLife = {
                displayName = "Use Unleash Life",
                description = "Automatically use Unleash Life when talented",
                type = "toggle",
                default = true
            },
            unleashLifeThreshold = {
                displayName = "Unleash Life Threshold",
                description = "Target health to use Unleash Life",
                type = "slider",
                min = 30,
                max = 90,
                default = 70
            }
        },
        
        utilitySettings = {
            useWaterShield = {
                displayName = "Use Water Shield",
                description = "Automatically maintain Water Shield",
                type = "toggle",
                default = true
            },
            useEarthShield = {
                displayName = "Use Earth Shield",
                description = "Automatically maintain Earth Shield",
                type = "toggle",
                default = true
            },
            earthShieldTarget = {
                displayName = "Earth Shield Target",
                description = "Who to place Earth Shield on",
                type = "dropdown",
                options = {"Tank", "Lowest Health", "Self", "Manual"},
                default = "Tank"
            },
            usePurifySpirit = {
                displayName = "Use Purify Spirit",
                description = "Automatically dispel magic/curse effects",
                type = "toggle",
                default = true
            },
            useSpiritwalkers = {
                displayName = "Use Spiritwalker's Grace",
                description = "Automatically use Spiritwalker's Grace when moving",
                type = "toggle",
                default = true
            },
            useCapacitorTotem = {
                displayName = "Use Capacitor Totem",
                description = "Automatically use Capacitor Totem",
                type = "toggle",
                default = true
            },
            capacitorTotemThreshold = {
                displayName = "Capacitor Totem Min Enemies",
                description = "Minimum enemies to use Capacitor Totem",
                type = "slider",
                min = 2,
                max = 8,
                default = 3
            }
        },
        
        offensiveSettings = {
            useFlameShock = {
                displayName = "Use Flame Shock",
                description = "Automatically apply Flame Shock",
                type = "toggle",
                default = true
            },
            useLavaBurst = {
                displayName = "Use Lava Burst",
                description = "Automatically use Lava Burst",
                type = "toggle",
                default = true
            },
            useLightningBolt = {
                displayName = "Use Lightning Bolt",
                description = "Automatically use Lightning Bolt",
                type = "toggle",
                default = true
            },
            offensiveMinMana = {
                displayName = "Offensive Min Mana",
                description = "Minimum mana to use offensive abilities",
                type = "slider",
                min = 20,
                max = 80,
                default = 40
            }
        },
        
        -- Advanced ability control settings
        abilityControls = {
            -- Healing Tide Totem controls
            healingTideTotem = AAC.RegisterAbility(spells.HEALING_TIDE_TOTEM, {
                enabled = true,
                useDuringBurstOnly = false,
                minLowHealthCount = 3
            }),
            
            -- Ascendance controls
            ascendance = AAC.RegisterAbility(spells.ASCENDANCE, {
                enabled = true,
                useDuringBurstOnly = true,
                minLowHealthCount = 4
            }),
            
            -- Spirit Link Totem controls
            spiritLinkTotem = AAC.RegisterAbility(spells.SPIRIT_LINK_TOTEM, {
                enabled = true,
                useDuringBurstOnly = false,
                minLowHealthCount = 3
            })
        }
    })
    
    return true
end

-- Register for events 
function Restoration:RegisterEvents()
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
    
    -- Register for player movement
    API.RegisterEvent("PLAYER_STARTED_MOVING", function() 
        self:HandleMovementStart()
    end)
    
    API.RegisterEvent("PLAYER_STOPPED_MOVING", function() 
        self:HandleMovementStop()
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
function Restoration:UpdateTalentInfo()
    -- Check for important talents
    talents.hasHighTide = API.HasTalent(spells.HIGH_TIDE)
    talents.hasTidalWaves = API.HasTalent(spells.TIDAL_WAVES)
    talents.hasUndulation = API.HasTalent(spells.UNDULATION)
    talents.hasTorrent = API.HasTalent(spells.TORRENT)
    talents.hasDeluge = API.HasTalent(spells.DELUGE)
    talents.hasSurgeOfEarth = API.HasTalent(spells.SURGE_OF_EARTH)
    talents.hasEchoOfTheElements = API.HasTalent(spells.ECHO_OF_THE_ELEMENTS)
    talents.hasFlashFlood = API.HasTalent(spells.FLASH_FLOOD)
    talents.hasEarthenHarmony = API.HasTalent(spells.EARTHEN_HARMONY)
    talents.hasGracefulSpirit = API.HasTalent(spells.GRACEFUL_SPIRIT)
    talents.hasHeavyRainfall = API.HasTalent(spells.HEAVY_RAINFALL)
    talents.hasImprovedEarthlivingWeapon = API.HasTalent(spells.IMPROVED_EARTHLIVING_WEAPON)
    talents.hasRefreshingWaters = API.HasTalent(spells.REFRESHING_WATERS)
    talents.hasTotemicFocus = API.HasTalent(spells.TOTEMIC_FOCUS)
    talents.hasAncestralVigor = API.HasTalent(spells.ANCESTRAL_VIGOR)
    talents.hasAncestralReach = API.HasTalent(spells.ANCESTRAL_REACH)
    talents.hasTidebringer = API.HasTalent(spells.TIDEBRINGER)
    talents.hasPrimalTideCore = API.HasTalent(spells.PRIMAL_TIDE_CORE)
    talents.hasSwirlingCurrents = API.HasTalent(spells.SWIRLING_CURRENTS)
    talents.hasWaterTotemMastery = API.HasTalent(spells.WATER_TOTEM_MASTERY)
    talents.hasEarthlivingWeapon = API.HasTalent(spells.EARTHLIVING_WEAPON)
    talents.hasFlametongueWeapon = API.HasTalent(spells.FLAMETONGUE_WEAPON)
    talents.hasPoisonCleansingTotem = API.HasTalent(spells.POISON_CLEANSING_TOTEM)
    talents.hasStoneskinTotem = API.HasTalent(spells.STONESKIN_TOTEM)
    talents.hasTranquilAirTotem = API.HasTalent(spells.TRANQUIL_AIR_TOTEM)
    talents.hasAncestralProtectionTotem = API.HasTalent(spells.ANCESTRAL_PROTECTION_TOTEM)
    talents.hasTotemicRecall = API.HasTalent(spells.TOTEMIC_RECALL)
    talents.hasCallOfTheElements = API.HasTalent(spells.CALL_OF_THE_ELEMENTS)
    talents.hasSpiritwalkersForge = API.HasTalent(spells.SPIRITWALKERS_FORGE)
    talents.hasGutShot = API.HasTalent(spells.GUTSHOT)
    talents.hasPrimordialWave = API.HasTalent(spells.PRIMORDIAL_WAVE)
    talents.hasAnchoringTotem = API.HasTalent(spells.ANCHORING_TOTEM)
    talents.hasMaelstromTotem = API.HasTalent(spells.MAELSTROM_TOTEM)
    talents.hasRefreshingTotemDuration = API.HasTalent(spells.REFRESHING_TOTEM_DURATION)
    talents.hasNaturalOrder = API.HasTalent(spells.NATURAL_ORDER)
    talents.hasSinkingWater = API.HasTalent(spells.SINKING_WATER)
    talents.hasGushingDeluge = API.HasTalent(spells.GUSHING_DELUGE)
    talents.hasNaturesWisdom = API.HasTalent(spells.NATURES_WISDOM)
    talents.hasLashOfFlame = API.HasTalent(spells.LASH_OF_FLAME)
    talents.hasOngoingWaves = API.HasTalent(spells.ONGOING_WAVES)
    talents.hasSeismicShock = API.HasTalent(spells.SEISMIC_SHOCK)
    talents.hasHealingBloom = API.HasTalent(spells.HEALING_BLOOM)
    talents.hasSurgingFlood = API.HasTalent(spells.SURGING_FLOOD)
    talents.hasRippleInSpace = API.HasTalent(spells.RIPPLE_IN_SPACE)
    talents.hasVortexTotem = API.HasTalent(spells.VORTEX_TOTEM)
    
    -- War Within Season 2 talents
    talents.hasEarthElemental = API.HasTalent(spells.EARTH_ELEMENTAL)
    talents.hasManaSpringTotem = API.HasTalent(spells.MANA_SPRING_TOTEM)
    talents.hasFocusedDeluge = API.HasTalent(spells.FOCUSED_DELUGE)
    talents.hasOverflowingWaterShield = API.HasTalent(spells.OVERFLOWING_WATER_SHIELD)
    talents.hasDeeplyRootedElements = API.HasTalent(spells.DEEPLY_ROOTED_ELEMENTS)
    talents.hasEmpowerHealingWave = API.HasTalent(spells.EMPOWER_HEALING_WAVE)
    talents.hasEmpowerHealingRain = API.HasTalent(spells.EMPOWER_HEALING_RAIN)
    talents.hasEmpoweredNaturesSwiftness = API.HasTalent(spells.EMPOWERED_NATURES_SWIFTNESS)
    talents.hasEnhancedSpiritwalkersGrace = API.HasTalent(spells.ENHANCED_SPIRITWALKERS_GRACE)
    talents.hasFuryOfTheFathoms = API.HasTalent(spells.FURY_OF_THE_FATHOMS)
    talents.hasImprovedSpiritLinkTotem = API.HasTalent(spells.IMPROVED_SPIRIT_LINK_TOTEM)
    talents.hasManaStreamTotem = API.HasTalent(spells.MANA_STREAM_TOTEM)
    talents.hasRenewedFervency = API.HasTalent(spells.RENEWED_FERVENCY)
    talents.hasTumultuousWaterTotem = API.HasTalent(spells.TUMULTUOUS_WATER_TOTEM)
    talents.hasTwistedElements = API.HasTalent(spells.TWISTED_ELEMENTS)
    
    -- Set specialized variables based on talents
    if talents.hasSpiritwalkersForge then
        spiritwalkersForge = true
    end
    
    if talents.hasGutShot then
        gutShot = true
    end
    
    if talents.hasPrimordialWave then
        primordialWave = true
    end
    
    if API.IsSpellKnown(spells.HEALING_WAVE) then
        healingWave = true
    end
    
    if API.IsSpellKnown(spells.HEALING_SURGE) then
        healingSurge = true
    end
    
    if API.IsSpellKnown(spells.NATURES_SWIFTNESS) then
        naturesSwiftness = true
    end
    
    if API.IsSpellKnown(spells.UNLEASH_LIFE) then
        unleashLife = true
    end
    
    if talents.hasAnchoringTotem then
        anchoringTotem = true
    end
    
    if talents.hasMaelstromTotem then
        maelstromTotem = true
    end
    
    if talents.hasTotemicRecall then
        totemicRecall = true
    end
    
    if talents.hasRefreshingTotemDuration then
        refreshTotemDuration = true
    end
    
    if talents.hasNaturalOrder then
        naturalOrder = true
    end
    
    if talents.hasSinkingWater then
        sinkingWater = true
    end
    
    if talents.hasGushingDeluge then
        gushingDeluge = true
    end
    
    if talents.hasNaturesWisdom then
        naturesWisdom = true
    end
    
    if talents.hasLashOfFlame then
        lashOfFlame = true
    end
    
    if talents.hasOngoingWaves then
        ongoingWaves = true
    end
    
    if talents.hasSeismicShock then
        seismicShock = true
    end
    
    if API.IsSpellKnown(spells.HEALING_STREAM_TOTEM) then
        healingStream = true
    end
    
    if talents.hasHealingBloom then
        healingBloom = true
    end
    
    if talents.hasSurgingFlood then
        surgingFlood = true
    end
    
    if talents.hasRippleInSpace then
        rippleInSpace = true
    end
    
    if talents.hasVortexTotem then
        vortexTotem = true
    end
    
    if talents.hasLavaBurst then
        lavaBurst = true
    end
    
    -- Initialize ability charges
    if talents.hasEchoOfTheElements then
        riptideMaxCharges = 2
    end
    
    riptideCharges = API.GetSpellCharges(spells.RIPTIDE) or 0
    
    API.PrintDebug("Restoration Shaman talents updated")
    
    return true
end

-- Update mana tracking
function Restoration:UpdateMana()
    currentMana = API.GetPlayerMana()
    maxMana = API.GetPlayerMaxMana()
    return true
end

-- Handle movement start
function Restoration:HandleMovementStart()
    -- Check if we should use Spiritwalker's Grace
    local settings = ConfigRegistry:GetSettings("RestorationShaman")
    
    if settings.utilitySettings.useSpiritwalkers and not spiritwalkersGraceActive and API.CanCast(spells.SPIRITWALKERS_GRACE) then
        API.CastSpell(spells.SPIRITWALKERS_GRACE)
    end
    
    return true
end

-- Handle movement stop
function Restoration:HandleMovementStop()
    return true
end

-- Update healing targets
function Restoration:UpdateHealingTargets()
    -- Initialize variables
    currentPlayerHealth = API.GetPlayerHealthPercent()
    lowestHealthAlly = 100
    lowestHealthAllyName = nil
    tankHealth = 100
    tankName = nil
    averageGroupHealth = 0
    lowHealthAlliesCount = 0
    criticalHealthAlliesCount = 0
    mediumHealthAlliesCount = 0
    
    -- Get settings
    local settings = ConfigRegistry:GetSettings("RestorationShaman")
    local lowHealthThreshold = settings.healingSettings.lowHealthThreshold
    local criticalHealthThreshold = settings.healingSettings.criticalHealthThreshold
    local mediumHealthThreshold = MEDIUM_HEALTH_THRESHOLD
    
    -- Track total health
    local totalHealthPercent = 0
    local numGroupMembers = 0
    
    -- Get party/raid information
    local inRaid = API.IsInRaid()
    local unitPrefix = inRaid and "raid" or "party"
    local groupSize = inRaid and API.GetRaidSize() or API.GetPartySize()
    
    -- Include player in checks
    totalHealthPercent = totalHealthPercent + currentPlayerHealth
    numGroupMembers = numGroupMembers + 1
    
    -- Check if player is lowest health
    if currentPlayerHealth < lowestHealthAlly then
        lowestHealthAlly = currentPlayerHealth
        lowestHealthAllyName = "player"
    end
    
    -- Check if player needs healing
    if currentPlayerHealth <= lowHealthThreshold then
        lowHealthAlliesCount = lowHealthAlliesCount + 1
    end
    
    if currentPlayerHealth <= criticalHealthThreshold then
        criticalHealthAlliesCount = criticalHealthAlliesCount + 1
    end
    
    if currentPlayerHealth <= mediumHealthThreshold then
        mediumHealthAlliesCount = mediumHealthAlliesCount + 1
    end
    
    -- Check group members
    for i = 1, groupSize do
        local unit = unitPrefix .. i
        if API.UnitExists(unit) and not API.UnitIsDeadOrGhost(unit) and API.UnitIsVisible(unit) then
            local healthPercent = API.GetUnitHealthPercent(unit)
            local unitName = API.UnitName(unit)
            
            -- Add to total health
            totalHealthPercent = totalHealthPercent + healthPercent
            numGroupMembers = numGroupMembers + 1
            
            -- Check if this unit is lowest health
            if healthPercent < lowestHealthAlly then
                lowestHealthAlly = healthPercent
                lowestHealthAllyName = unit
            end
            
            -- Check if unit is a tank
            if API.UnitIsTank(unit) then
                tankHealth = healthPercent
                tankName = unit
            end
            
            -- Check if unit needs healing
            if healthPercent <= lowHealthThreshold then
                lowHealthAlliesCount = lowHealthAlliesCount + 1
            end
            
            if healthPercent <= criticalHealthThreshold then
                criticalHealthAlliesCount = criticalHealthAlliesCount + 1
            end
            
            if healthPercent <= mediumHealthThreshold then
                mediumHealthAlliesCount = mediumHealthAlliesCount + 1
            end
        end
    end
    
    -- Calculate average health
    if numGroupMembers > 0 then
        averageGroupHealth = totalHealthPercent / numGroupMembers
    end
    
    return true
end

-- Handle combat log events
function Restoration:HandleCombatLogEvent(...)
    local timestamp, eventType, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, spellID, spellName = CombatLogGetCurrentEventInfo()
    
    -- Track buff applications
    if eventType == "SPELL_AURA_APPLIED" or eventType == "SPELL_AURA_REFRESH" then
        -- Track player buffs
        if destGUID == API.GetPlayerGUID() then
            -- Track Water Shield
            if spellID == buffs.WATER_SHIELD then
                waterShieldActive = true
                waterShieldStacks = select(4, API.GetBuffInfo("player", buffs.WATER_SHIELD)) or 1
                waterShieldEndTime = GetTime() + WATER_SHIELD_DURATION
                API.PrintDebug("Water Shield activated: " .. tostring(waterShieldStacks) .. " stacks")
            end
            
            -- Track Spiritwalker's Grace
            if spellID == buffs.SPIRITWALKERS_GRACE then
                spiritwalkersGraceActive = true
                spiritwalkersGraceEndTime = GetTime() + SPIRITWALKERS_GRACE_DURATION
                API.PrintDebug("Spiritwalker's Grace activated")
            end
            
            -- Track Tidal Waves
            if spellID == buffs.TIDAL_WAVES then
                tidalWavesActive = true
                tidalWavesStacks = select(4, API.GetBuffInfo("player", buffs.TIDAL_WAVES)) or 1
                tidalWavesEndTime = GetTime() + TIDAL_WAVES_DURATION
                API.PrintDebug("Tidal Waves activated: " .. tostring(tidalWavesStacks) .. " stacks")
            end
            
            -- Track High Tide
            if spellID == buffs.HIGH_TIDE then
                highTideActive = true
                highTideStacks = select(4, API.GetBuffInfo("player", buffs.HIGH_TIDE)) or 1
                highTideEndTime = GetTime() + HIGH_TIDE_DURATION
                API.PrintDebug("High Tide activated: " .. tostring(highTideStacks) .. " stacks")
            end
            
            -- Track Ascendance
            if spellID == buffs.ASCENDANCE then
                ascendanceActive = true
                ascendanceEndTime = GetTime() + ASCENDANCE_DURATION
                API.PrintDebug("Ascendance activated")
            end
            
            -- Track Ancestral Guidance
            if spellID == buffs.ANCESTRAL_GUIDANCE then
                ancestralGuidanceActive = true
                ancestralGuidanceEndTime = GetTime() + ANCESTRAL_GUIDANCE_DURATION
                API.PrintDebug("Ancestral Guidance activated")
            end
            
            -- Track Unleash Life
            if spellID == buffs.UNLEASH_LIFE then
                API.PrintDebug("Unleash Life activated")
            end
            
            -- Track Flametongue Weapon
            if spellID == buffs.FLAMETONGUE_WEAPON then
                API.PrintDebug("Flametongue Weapon activated")
            end
            
            -- Track Earthliving Weapon
            if spellID == buffs.EARTHLIVING_WEAPON then
                API.PrintDebug("Earthliving Weapon activated")
            end
            
            -- Track Flash Flood
            if spellID == buffs.FLASH_FLOOD then
                API.PrintDebug("Flash Flood activated")
            end
            
            -- Track Overflowing Water Shield
            if spellID == buffs.OVERFLOWING_WATER_SHIELD then
                waterShieldOverflowActive = true
                waterShieldOverflowStacks = select(4, API.GetBuffInfo("player", buffs.OVERFLOWING_WATER_SHIELD)) or 1
                waterShieldOverflowEndTime = GetTime() + WATER_SHIELD_OVERFLOW_DURATION
                API.PrintDebug("Overflowing Water Shield activated: " .. tostring(waterShieldOverflowStacks) .. " stacks")
            end
            
            -- Track Swirling Currents
            if spellID == buffs.SWIRLING_CURRENTS then
                swirlingCurrentsActive = true
                swirlingCurrentsStacks = select(4, API.GetBuffInfo("player", buffs.SWIRLING_CURRENTS)) or 1
                swirlingCurrentsEndTime = select(6, API.GetBuffInfo("player", buffs.SWIRLING_CURRENTS))
                API.PrintDebug("Swirling Currents activated: " .. tostring(swirlingCurrentsStacks) .. " stacks")
            end
            
            -- Track Deeply Rooted Elements
            if spellID == buffs.DEEPLY_ROOTED_ELEMENTS then
                API.PrintDebug("Deeply Rooted Elements activated")
            end
        end
        
        -- Track Earth Shield on any unit
        if spellID == buffs.EARTH_SHIELD then
            if destGUID == earthShieldTargetGUID then
                earthShieldActive = true
                earthShieldStacks = select(4, API.GetBuffInfo(destName, buffs.EARTH_SHIELD)) or 1
                API.PrintDebug("Earth Shield refreshed on " .. destName .. ": " .. tostring(earthShieldStacks) .. " stacks")
            else
                earthShieldActive = true
                earthShieldTargetGUID = destGUID
                earthShieldTargetName = destName
                earthShieldStacks = select(4, API.GetBuffInfo(destName, buffs.EARTH_SHIELD)) or 1
                API.PrintDebug("Earth Shield applied to " .. destName .. ": " .. tostring(earthShieldStacks) .. " stacks")
            end
        end
        
        -- Track Riptide buff on any unit
        if spellID == buffs.RIPTIDE then
            API.PrintDebug("Riptide applied to " .. destName)
        end
        
        -- Track Flame Shock debuff application
        if spellID == debuffs.FLAME_SHOCK and destGUID == API.GetTargetGUID() then
            flameShockActive = true
            flameShockEndTime = select(6, API.GetDebuffInfo("target", debuffs.FLAME_SHOCK))
            API.PrintDebug("Flame Shock applied to target")
        end
    end
    
    -- Track buff removals
    if eventType == "SPELL_AURA_REMOVED" then
        -- Track player buff removals
        if destGUID == API.GetPlayerGUID() then
            -- Track Water Shield
            if spellID == buffs.WATER_SHIELD then
                waterShieldActive = false
                waterShieldStacks = 0
                API.PrintDebug("Water Shield faded")
            end
            
            -- Track Spiritwalker's Grace
            if spellID == buffs.SPIRITWALKERS_GRACE then
                spiritwalkersGraceActive = false
                API.PrintDebug("Spiritwalker's Grace faded")
            end
            
            -- Track Tidal Waves
            if spellID == buffs.TIDAL_WAVES then
                tidalWavesActive = false
                tidalWavesStacks = 0
                API.PrintDebug("Tidal Waves faded")
            end
            
            -- Track High Tide
            if spellID == buffs.HIGH_TIDE then
                highTideActive = false
                highTideStacks = 0
                API.PrintDebug("High Tide faded")
            end
            
            -- Track Ascendance
            if spellID == buffs.ASCENDANCE then
                ascendanceActive = false
                API.PrintDebug("Ascendance faded")
            end
            
            -- Track Ancestral Guidance
            if spellID == buffs.ANCESTRAL_GUIDANCE then
                ancestralGuidanceActive = false
                API.PrintDebug("Ancestral Guidance faded")
            end
            
            -- Track Overflowing Water Shield
            if spellID == buffs.OVERFLOWING_WATER_SHIELD then
                waterShieldOverflowActive = false
                waterShieldOverflowStacks = 0
                API.PrintDebug("Overflowing Water Shield faded")
            end
            
            -- Track Swirling Currents
            if spellID == buffs.SWIRLING_CURRENTS then
                swirlingCurrentsActive = false
                swirlingCurrentsStacks = 0
                API.PrintDebug("Swirling Currents faded")
            end
        end
        
        -- Track Earth Shield removal
        if spellID == buffs.EARTH_SHIELD and destGUID == earthShieldTargetGUID then
            earthShieldActive = false
            earthShieldTargetGUID = nil
            earthShieldTargetName = nil
            earthShieldStacks = 0
            API.PrintDebug("Earth Shield faded from " .. destName)
        end
        
        -- Track Flame Shock debuff removal
        if spellID == debuffs.FLAME_SHOCK and destGUID == API.GetTargetGUID() then
            flameShockActive = false
            API.PrintDebug("Flame Shock faded from target")
        end
    end
    
    -- Track Water Shield stack changes
    if eventType == "SPELL_AURA_APPLIED_DOSE" and spellID == buffs.WATER_SHIELD and destGUID == API.GetPlayerGUID() then
        waterShieldStacks = select(4, API.GetBuffInfo("player", buffs.WATER_SHIELD)) or 0
        API.PrintDebug("Water Shield stacks: " .. tostring(waterShieldStacks))
    end
    
    -- Track Overflowing Water Shield stack changes
    if eventType == "SPELL_AURA_APPLIED_DOSE" and spellID == buffs.OVERFLOWING_WATER_SHIELD and destGUID == API.GetPlayerGUID() then
        waterShieldOverflowStacks = select(4, API.GetBuffInfo("player", buffs.OVERFLOWING_WATER_SHIELD)) or 0
        API.PrintDebug("Overflowing Water Shield stacks: " .. tostring(waterShieldOverflowStacks))
    end
    
    -- Track Earth Shield stack changes
    if eventType == "SPELL_AURA_APPLIED_DOSE" and spellID == buffs.EARTH_SHIELD then
        if destGUID == earthShieldTargetGUID then
            earthShieldStacks = select(4, API.GetBuffInfo(destName, buffs.EARTH_SHIELD)) or 0
            API.PrintDebug("Earth Shield stacks on " .. destName .. ": " .. tostring(earthShieldStacks))
        end
    end
    
    -- Track Tidal Waves stack changes
    if eventType == "SPELL_AURA_APPLIED_DOSE" and spellID == buffs.TIDAL_WAVES and destGUID == API.GetPlayerGUID() then
        tidalWavesStacks = select(4, API.GetBuffInfo("player", buffs.TIDAL_WAVES)) or 0
        API.PrintDebug("Tidal Waves stacks: " .. tostring(tidalWavesStacks))
    end
    
    -- Track Swirling Currents stack changes
    if eventType == "SPELL_AURA_APPLIED_DOSE" and spellID == buffs.SWIRLING_CURRENTS and destGUID == API.GetPlayerGUID() then
        swirlingCurrentsStacks = select(4, API.GetBuffInfo("player", buffs.SWIRLING_CURRENTS)) or 0
        API.PrintDebug("Swirling Currents stacks: " .. tostring(swirlingCurrentsStacks))
    end
    
    -- Track High Tide stack changes
    if eventType == "SPELL_AURA_APPLIED_DOSE" and spellID == buffs.HIGH_TIDE and destGUID == API.GetPlayerGUID() then
        highTideStacks = select(4, API.GetBuffInfo("player", buffs.HIGH_TIDE)) or 0
        API.PrintDebug("High Tide stacks: " .. tostring(highTideStacks))
    end
    
    -- Track spell casts
    if eventType == "SPELL_CAST_SUCCESS" then
        if sourceGUID == API.GetPlayerGUID() then
            -- Track Riptide cast
            if spellID == spells.RIPTIDE then
                riptideCharges = API.GetSpellCharges(spells.RIPTIDE) or 0
                API.PrintDebug("Riptide cast, charges remaining: " .. tostring(riptideCharges))
            elseif spellID == spells.HEALING_RAIN then
                healingRainActive = true
                healingRainEndTime = GetTime() + HEALING_RAIN_DURATION
                healingRainX, healingRainY, healingRainZ = API.GetCursorPosition()
                API.PrintDebug("Healing Rain cast")
            elseif spellID == spells.HEALING_STREAM_TOTEM then
                healingStreamTotemActive = true
                healingStreamTotemEndTime = GetTime() + HEALING_STREAM_TOTEM_DURATION
                API.PrintDebug("Healing Stream Totem cast")
            elseif spellID == spells.HEALING_TIDE_TOTEM then
                healingTideTotemActive = true
                healingTideTotemEndTime = GetTime() + HEALING_TIDE_TOTEM_DURATION
                API.PrintDebug("Healing Tide Totem cast")
            elseif spellID == spells.CLOUDBURST_TOTEM then
                cloudburstTotemActive = true
                cloudburstTotemEndTime = GetTime() + CLOUDBURST_TOTEM_DURATION
                API.PrintDebug("Cloudburst Totem cast")
            elseif spellID == spells.ASCENDANCE then
                ascendanceActive = true
                ascendanceEndTime = GetTime() + ASCENDANCE_DURATION
                API.PrintDebug("Ascendance cast")
            elseif spellID == spells.ANCESTRAL_GUIDANCE then
                ancestralGuidanceActive = true
                ancestralGuidanceEndTime = GetTime() + ANCESTRAL_GUIDANCE_DURATION
                API.PrintDebug("Ancestral Guidance cast")
            elseif spellID == spells.WELLSPRING then
                wellspringCasting = true
                
                -- Reset wellspringCasting after a short delay
                C_Timer.After(2.0, function()
                    wellspringCasting = false
                    API.PrintDebug("Wellspring finished")
                end)
                
                API.PrintDebug("Wellspring cast")
            elseif spellID == spells.DOWNPOUR then
                downpourActive = true
                downpourEndTime = GetTime() + 2.0 -- Approximate duration
                API.PrintDebug("Downpour cast")
            elseif spellID == spells.WATER_SHIELD then
                waterShieldActive = true
                waterShieldStacks = 3 -- Initial stacks
                waterShieldEndTime = GetTime() + WATER_SHIELD_DURATION
                API.PrintDebug("Water Shield cast")
            elseif spellID == spells.EARTH_SHIELD then
                earthShieldActive = true
                earthShieldTargetGUID = destGUID
                earthShieldTargetName = destName
                earthShieldStacks = 3 -- Initial stacks
                API.PrintDebug("Earth Shield cast on " .. destName)
            elseif spellID == spells.FLAME_SHOCK then
                flameShockActive = true
                flameShockEndTime = GetTime() + FLAME_SHOCK_DURATION
                API.PrintDebug("Flame Shock cast")
            elseif spellID == spells.SPIRITWALKERS_GRACE then
                spiritwalkersGraceActive = true
                spiritwalkersGraceEndTime = GetTime() + SPIRITWALKERS_GRACE_DURATION
                API.PrintDebug("Spiritwalker's Grace cast")
            elseif spellID == spells.POISON_CLEANSING_TOTEM then
                poisonTotemActive = true
                poisonTotemEndTime = GetTime() + 120 -- 2 minutes duration
                API.PrintDebug("Poison Cleansing Totem cast")
            end
        end
    end
    
    return true
end

-- Main rotation function
function Restoration:RunRotation()
    -- Check if we should be running Restoration Shaman logic
    if API.GetActiveSpecID() ~= RESTORATION_SPEC_ID then
        return false
    end
    
    -- Skip rotation if player is casting
    if API.IsPlayerCasting() then
        return false
    end
    
    -- Get settings
    local settings = ConfigRegistry:GetSettings("RestorationShaman")
    
    -- Update variables
    self:UpdateMana()
    self:UpdateHealingTargets()
    burstModeActive = settings.healingSettings.healingStyle == "Aggressive" or API.ShouldUseBurst()
    
    -- Handle next cast override
    if nextCastOverride and API.CanCast(nextCastOverride) then
        local spell = nextCastOverride
        nextCastOverride = nil
        API.CastSpell(spell)
        return true
    end
    
    -- Maintain buffs
    if self:HandleBuffs(settings) then
        return true
    end
    
    -- Handle dispels
    if self:HandleDispel(settings) then
        return true
    end
    
    -- Handle emergency healing
    if self:HandleEmergencyHealing(settings) then
        return true
    end
    
    -- Use healing cooldowns
    if self:HandleHealingCooldowns(settings) then
        return true
    end
    
    -- Handle AoE healing
    if self:HandleAoEHealing(settings) then
        return true
    end
    
    -- Handle single target healing
    if self:HandleSingleTargetHealing(settings) then
        return true
    end
    
    -- Handle DPS if healing not needed
    if lowHealthAlliesCount == 0 and criticalHealthAlliesCount == 0 and self:HandleDPS(settings) then
        return true
    end
    
    return false
end

-- Handle maintaining buffs
function Restoration:HandleBuffs(settings)
    -- Maintain Water Shield
    if settings.utilitySettings.useWaterShield and
       not waterShieldActive and
       API.CanCast(spells.WATER_SHIELD) then
        API.CastSpell(spells.WATER_SHIELD)
        return true
    end
    
    -- Maintain Earth Shield
    if settings.utilitySettings.useEarthShield and
       not earthShieldActive and
       API.CanCast(spells.EARTH_SHIELD) then
        
        local target = nil
        if settings.utilitySettings.earthShieldTarget == "Tank" and tankName then
            target = tankName
        elseif settings.utilitySettings.earthShieldTarget == "Lowest Health" and lowestHealthAllyName then
            target = lowestHealthAllyName
        elseif settings.utilitySettings.earthShieldTarget == "Self" then
            target = "player"
        else
            target = "player" -- Default to self if no target
        end
        
        if target then
            API.CastSpellOnUnit(spells.EARTH_SHIELD, target)
            return true
        end
    end
    
    return false
end

-- Handle dispel
function Restoration:HandleDispel(settings)
    if settings.utilitySettings.usePurifySpirit and API.CanCast(spells.PURIFY_SPIRIT) then
        local dispelTarget = API.FindDispellableTarget({"Magic", "Curse"})
        if dispelTarget then
            API.CastSpellOnUnit(spells.PURIFY_SPIRIT, dispelTarget)
            return true
        end
    end
    
    return false
end

-- Handle emergency healing
function Restoration:HandleEmergencyHealing(settings)
    -- Use Nature's Swiftness + Healing Surge for critical healing
    if naturesSwiftness and
       settings.cooldownSettings.useNaturesSwiftness and
       criticalHealthAlliesCount > 0 and
       lowestHealthAlly <= settings.cooldownSettings.naturesSwiftnessThreshold and
       API.CanCast(spells.NATURES_SWIFTNESS) then
        
        API.CastSpell(spells.NATURES_SWIFTNESS)
        
        -- Queue Healing Surge
        if API.CanCast(spells.HEALING_SURGE) then
            nextCastOverride = spells.HEALING_SURGE
        end
        
        return true
    end
    
    -- Use Healing Surge for critical healing
    if healingSurge and
       settings.healingSettings.useSurgeOnCritical and
       criticalHealthAlliesCount > 0 and
       API.CanCast(spells.HEALING_SURGE) then
        
        API.CastSpellOnUnit(spells.HEALING_SURGE, lowestHealthAllyName)
        return true
    end
    
    return false
end

-- Handle healing cooldowns
function Restoration:HandleHealingCooldowns(settings)
    -- Use Healing Tide Totem
    if settings.totemSettings.useHealingTideTotem and
       settings.abilityControls.healingTideTotem.enabled and
       averageGroupHealth <= settings.totemSettings.healingTideTotemThreshold and
       lowHealthAlliesCount >= settings.abilityControls.healingTideTotem.minLowHealthCount and
       API.CanCast(spells.HEALING_TIDE_TOTEM) and
       (not settings.abilityControls.healingTideTotem.useDuringBurstOnly or burstModeActive) then
        
        API.CastSpell(spells.HEALING_TIDE_TOTEM)
        return true
    end
    
    -- Use Spirit Link Totem
    if settings.totemSettings.useSpiritLinkTotem and
       settings.abilityControls.spiritLinkTotem.enabled and
       averageGroupHealth <= settings.totemSettings.spiritLinkTotemThreshold and
       lowHealthAlliesCount >= settings.abilityControls.spiritLinkTotem.minLowHealthCount and
       API.CanCast(spells.SPIRIT_LINK_TOTEM) and
       (not settings.abilityControls.spiritLinkTotem.useDuringBurstOnly or burstModeActive) then
        
        API.CastSpellAtBestLocation(spells.SPIRIT_LINK_TOTEM, 10) -- 10 yard radius
        return true
    end
    
    -- Use Ascendance
    if settings.cooldownSettings.useAscendance and
       settings.abilityControls.ascendance.enabled and
       averageGroupHealth <= settings.cooldownSettings.ascendanceThreshold and
       lowHealthAlliesCount >= settings.abilityControls.ascendance.minLowHealthCount and
       API.CanCast(spells.ASCENDANCE) and
       (not settings.abilityControls.ascendance.useDuringBurstOnly or burstModeActive) then
        
        API.CastSpell(spells.ASCENDANCE)
        return true
    end
    
    -- Use Ancestral Guidance
    if settings.cooldownSettings.useAncestralGuidance and
       averageGroupHealth <= settings.cooldownSettings.ancestralGuidanceThreshold and
       API.CanCast(spells.ANCESTRAL_GUIDANCE) then
        
        API.CastSpell(spells.ANCESTRAL_GUIDANCE)
        return true
    end
    
    -- Use Mana Tide Totem
    if settings.totemSettings.useManaTideTotem and
       currentMana / maxMana * 100 <= settings.totemSettings.manaTideTotemThreshold and
       API.CanCast(spells.MANA_TIDE_TOTEM) then
        
        API.CastSpell(spells.MANA_TIDE_TOTEM)
        return true
    end
    
    -- Use Cloudburst Totem
    if talents.hasCloudburstTotem and
       settings.totemSettings.useCloudburstTotem and
       lowHealthAlliesCount >= settings.totemSettings.cloudburstTotemThreshold and
       API.CanCast(spells.CLOUDBURST_TOTEM) then
        
        API.CastSpell(spells.CLOUDBURST_TOTEM)
        return true
    end
    
    -- Use Earthen Wall Totem
    if talents.hasEarthenWallTotem and
       settings.totemSettings.useEarthenWallTotem and
       averageGroupHealth <= settings.totemSettings.earthenWallTotemThreshold and
       API.CanCast(spells.EARTHEN_WALL_TOTEM) then
        
        API.CastSpellAtBestLocation(spells.EARTHEN_WALL_TOTEM, 10) -- 10 yard radius
        return true
    end
    
    -- Use Unleash Life to buff next heal
    if unleashLife and
       settings.cooldownSettings.useUnleashLife and
       lowestHealthAlly <= settings.cooldownSettings.unleashLifeThreshold and
       API.CanCast(spells.UNLEASH_LIFE) then
        
        API.CastSpellOnUnit(spells.UNLEASH_LIFE, lowestHealthAllyName)
        return true
    end
    
    return false
end

-- Handle AoE healing
function Restoration:HandleAoEHealing(settings)
    -- Use Healing Rain
    if settings.aoeHealingSettings.useHealingRain and
       lowHealthAlliesCount >= settings.aoeHealingSettings.healingRainThreshold and
       API.CanCast(spells.HEALING_RAIN) then
        
        API.CastSpellAtBestLocation(spells.HEALING_RAIN, 10) -- 10 yard radius
        return true
    end
    
    -- Use Wellspring
    if talents.hasWellspring and
       settings.aoeHealingSettings.useWellspring and
       lowHealthAlliesCount >= settings.aoeHealingSettings.wellspringThreshold and
       API.CanCast(spells.WELLSPRING) then
        
        API.CastSpell(spells.WELLSPRING)
        return true
    end
    
    -- Use Downpour
    if talents.hasDownpour and
       settings.aoeHealingSettings.useDownpour and
       lowHealthAlliesCount >= settings.aoeHealingSettings.downpourThreshold and
       API.CanCast(spells.DOWNPOUR) then
        
        API.CastSpellAtBestLocation(spells.DOWNPOUR, 10) -- 10 yard radius
        return true
    end
    
    -- Use Chain Heal
    if settings.aoeHealingSettings.useChainHeal and
       lowHealthAlliesCount >= settings.aoeHealingSettings.chainHealThreshold and
       lowestHealthAlly <= settings.aoeHealingSettings.chainHealHealthThreshold and
       API.CanCast(spells.CHAIN_HEAL) then
        
        API.CastSpellOnUnit(spells.CHAIN_HEAL, lowestHealthAllyName)
        return true
    end
    
    -- Use Primordial Wave
    if primordialWave and
       lowestHealthAlly <= 85 and
       lowHealthAlliesCount >= 3 and
       API.CanCast(spells.PRIMORDIAL_WAVE) then
        
        API.CastSpellOnUnit(spells.PRIMORDIAL_WAVE, lowestHealthAllyName)
        return true
    end
    
    -- Use Healing Stream Totem
    if healingStream and
       settings.totemSettings.useHealingStreamTotem and
       API.CanCast(spells.HEALING_STREAM_TOTEM) then
        
        API.CastSpell(spells.HEALING_STREAM_TOTEM)
        return true
    end
    
    return false
end

-- Handle single target healing
function Restoration:HandleSingleTargetHealing(settings)
    -- Use Riptide to apply HoT and enable Tidal Waves
    if API.CanCast(spells.RIPTIDE) and riptideCharges > 0 then
        -- Determine target based on settings
        local target = nil
        
        if settings.healingSettings.riptideManagement == "Spread" then
            -- Find a target without Riptide below threshold
            target = API.FindUnitWithoutBuff(buffs.RIPTIDE, settings.healingSettings.riptideThreshold)
        elseif settings.healingSettings.riptideManagement == "Tank Focus" and tankName then
            -- Prioritize tank if their health is below threshold
            if tankHealth <= settings.healingSettings.riptideThreshold then
                target = tankName
            else
                target = API.FindUnitWithoutBuff(buffs.RIPTIDE, settings.healingSettings.riptideThreshold)
            end
        elseif settings.healingSettings.riptideManagement == "Low Health Focus" then
            -- Prioritize lowest health target
            if lowestHealthAlly <= settings.healingSettings.riptideThreshold then
                target = lowestHealthAllyName
            end
        elseif settings.healingSettings.riptideManagement == "Conserve" then
            -- Only use if someone is below threshold and we have max charges
            if lowestHealthAlly <= settings.healingSettings.riptideThreshold and riptideCharges >= riptideMaxCharges then
                target = lowestHealthAllyName
            end
        end
        
        if target then
            API.CastSpellOnUnit(spells.RIPTIDE, target)
            return true
        end
    end
    
    -- Use Healing Wave with Tidal Waves
    if healingWave and
       tidalWavesActive and
       lowestHealthAlly <= 80 and
       API.CanCast(spells.HEALING_WAVE) then
        
        API.CastSpellOnUnit(spells.HEALING_WAVE, lowestHealthAllyName)
        return true
    end
    
    -- Use Healing Surge for more urgent healing
    if healingSurge and
       lowestHealthAlly <= 60 and
       API.CanCast(spells.HEALING_SURGE) then
        
        API.CastSpellOnUnit(spells.HEALING_SURGE, lowestHealthAllyName)
        return true
    end
    
    -- Use Healing Wave as filler
    if healingWave and
       lowestHealthAlly <= 90 and
       API.CanCast(spells.HEALING_WAVE) then
        
        API.CastSpellOnUnit(spells.HEALING_WAVE, lowestHealthAllyName)
        return true
    end
    
    return false
end

-- Handle DPS rotation when healing not needed
function Restoration:HandleDPS(settings)
    -- Skip DPS if mana is too low
    if currentMana / maxMana * 100 < settings.offensiveSettings.offensiveMinMana then
        return false
    end
    
    -- Apply Flame Shock
    if settings.offensiveSettings.useFlameShock and
       not flameShockActive and
       API.CanCast(spells.FLAME_SHOCK) then
        API.CastSpell(spells.FLAME_SHOCK)
        return true
    end
    
    -- Use Lava Burst with Flame Shock up
    if lavaBurst and
       settings.offensiveSettings.useLavaBurst and
       flameShockActive and
       API.CanCast(spells.LAVA_BURST) then
        API.CastSpell(spells.LAVA_BURST)
        return true
    end
    
    -- Use Lightning Bolt as filler
    if settings.offensiveSettings.useLightningBolt and
       API.CanCast(spells.LIGHTNING_BOLT) then
        API.CastSpell(spells.LIGHTNING_BOLT)
        return true
    end
    
    return false
end

-- Handle specialization change
function Restoration:OnSpecializationChanged()
    -- Update talent information
    self:UpdateTalentInfo()
    
    -- Reset state variables
    nextCastOverride = nil
    burstModeActive = false
    currentAoETargets = 0
    currentMana = API.GetPlayerMana()
    maxMana = API.GetPlayerMaxMana()
    waterShieldActive = false
    waterShieldEndTime = 0
    waterShieldStacks = 0
    earthShieldActive = false
    earthShieldTargetGUID = nil
    earthShieldTargetName = nil
    earthShieldStacks = 0
    healingRainActive = false
    healingRainEndTime = 0
    healingRainX, healingRainY, healingRainZ = 0, 0, 0
    riptideCharges = API.GetSpellCharges(spells.RIPTIDE) or 0
    riptideMaxCharges = API.GetSpellMaxCharges(spells.RIPTIDE) or 1
    highTideActive = false
    highTideStacks = 0
    highTideEndTime = 0
    tidalWavesActive = false
    tidalWavesStacks = 0
    tidalWavesEndTime = 0
    spiritwalkersGraceActive = false
    spiritwalkersGraceEndTime = 0
    ancestralGuidanceActive = false
    ancestralGuidanceEndTime = 0
    cloudburstTotemActive = false
    cloudburstTotemEndTime = 0
    healingTideTotemActive = false
    healingTideTotemEndTime = 0
    healingStreamTotemActive = false
    healingStreamTotemEndTime = 0
    ascendanceActive = false
    ascendanceEndTime = 0
    chainHarvestActive = false
    chainHarvestEndTime = 0
    vesperTotemActive = false
    vesperTotemEndTime = 0
    primordialWaveActive = false
    primordialWaveEndTime = 0
    fadeActive = false
    fadeEndTime = 0
    wellspringCasting = false
    downpourActive = false
    downpourEndTime = 0
    waterShieldOverflowActive = false
    waterShieldOverflowStacks = 0
    waterShieldOverflowEndTime = 0
    flameShockActive = false
    flameShockEndTime = 0
    swirlingCurrentsActive = false
    swirlingCurrentsStacks = 0
    swirlingCurrentsEndTime = 0
    spiritWalkerGrace = false
    gutShot = false
    currentPlayerHealth = 100
    lowestHealthAlly = 100
    lowestHealthAllyName = nil
    tankHealth = 100
    tankName = nil
    averageGroupHealth = 100
    lowHealthAlliesCount = 0
    criticalHealthAlliesCount = 0
    mediumHealthAlliesCount = 0
    poisonTotemActive = false
    poisonTotemEndTime = 0
    spiritwalkersForge = false
    lavaSurge = false
    lavaBurst = false
    primordialWave = false
    healingWave = false
    healingSurge = false
    naturesSwiftness = false
    unleashLife = false
    anchoringTotem = false
    maelstromTotem = false
    totemicRecall = false
    refreshTotemDuration = false
    naturalOrder = false
    sinkingWater = false
    gushingDeluge = false
    naturesWisdom = false
    lashOfFlame = false
    ongoingWaves = false
    seismicShock = false
    healingStream = false
    healingBloom = false
    surgingFlood = false
    rippleInSpace = false
    vortexTotem = false
    
    API.PrintDebug("Restoration Shaman state reset on spec change")
    
    return true
end

-- Return the module for loading
return Restoration