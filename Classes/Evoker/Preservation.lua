------------------------------------------
-- WindrunnerRotations - Preservation Evoker Module
-- Author: VortexQ8
-- The War Within Season 2
------------------------------------------

local Preservation = {}
-- This will be assigned to addon.Classes.Evoker.Preservation when loaded

-- These will be set when the file is loaded in our test environment
local API
local ConfigRegistry
local AAC
local Evoker

-- Cache frequently accessed data
local spells = {}
local talents = {}
local buffs = {}
local debuffs = {}

-- State tracking variables
local nextCastOverride = nil
local burstModeActive = false
local currentMana = 100
local currentEssence = 0
local maxEssence = 6
local livingFlame = false
local fireBreath = false
local fireBreathEmpowered = false
local fireBreathActive = false
local fireBreathEndTime = 0
local emeraldBreath = false
local emeraldBreathEmpowered = false
local emeraldBreathActive = false
local emeraldBreathEndTime = 0
local azureStrike = false
local echoingVoid = false
local echoingVoidActive = false
local echoingVoidEndTime = 0
local dreamBreath = false
local dreamBreathEmpowered = false
local dreamBreathActive = false
local dreamBreathEndTime = 0
local disintegrate = false
local disintegrateActive = false
local disintegrateEndTime = 0
local reversion = false
local reversionEmpowered = false
local reversionActive = false
local reversionEndTime = 0
local spiritbloom = false
local spiritbloomEmpowered = false
local spiritbloomActive = false
local spiritbloomEndTime = 0
local verdantEmbrace = false
local verdantEmbraceActive = false
local verdantEmbraceEndTime = 0
local timeDilation = false
local tipTheScales = false
local tipTheScalesActive = false
local tipTheScalesEndTime = 0
local rewind = false
local rewindActive = false
local rewindCooldown = 0
local rewindEndTime = 0
local essenceBurst = false
local essenceBurstActive = false
local essenceBurstStacks = 0
local essenceBurstEndTime = 0
local temporalAnomaly = false
local temporalAnomalyActive = false
local temporalAnomalyEndTime = 0
local obsidianScales = false
local obsidianScalesActive = false
local obsidianScalesEndTime = 0
local cauterizingFlame = false
local hover = false
local tailSwipe = false
local wingBuffet = false
local emeraldCommunion = false
local emeraldCommunionActive = false
local emeraldCommunionEndTime = 0
local timeSpiral = false
local timeSpiralActive = false
local timeSpiralEndTime = 0
local renewingBlaze = false
local renewingBlazeActive = false
local renewingBlazeEndTime = 0
local renew = false
local renewActive = false
local renewEndTime = 0
local lifebind = false
local lifebindActive = false
local lifebindEndTime = 0
local resonatingPuddles = false
local resonatingPuddlesActive = false
local resonatingPuddlesEndTime = 0
local breathOfEons = false
local breathOfEonsActive = false
local breathOfEonsEndTime = 0
local flightOfTheDragon = false
local flightOfTheDragonActive = false
local flightOfTheDragonEndTime = 0
local callOfYsera = false
local callOfYseraActive = false
local callOfYseraEndTime = 0
local goldenHour = false
local goldenHourActive = false
local goldenHourEndTime = 0
local dreamflight = false
local dreamflightActive = false
local dreamflightEndTime = 0
local deluge = false
local essenceAttunement = false
local essenceAttunementActive = false
local essenceAttunementStacks = 0
local essenceAttunementEndTime = 0
local bountifulBloom = false
local bountifulBloomActive = false
local bountifulBloomEndTime = 0
local timeTender = false
local timeTenderActive = false
local timeTenderEndTime = 0
local ancientFlame = false
local ancientFlameActive = false
local ancientFlameEndTime = 0
local fieldOfDreams = false
local fieldOfDreamsActive = false
local fieldOfDreamsEndTime = 0
local lastLivingFlame = 0
local lastAzureStrike = 0
local lastFireBreath = 0
local lastDisintegrate = 0
local lastReversion = 0
local lastEmeraldBreath = 0
local lastDreamBreath = 0
local lastVerdantEmbrace = 0
local lastSpiritbloom = 0
local lastTimeDilation = 0
local lastTipTheScales = 0
local lastEmeraldCommunion = 0
local lastRewind = 0
local lastObsidianScales = 0
local lastCauterizingFlame = 0
local lastHover = 0
local lastTailSwipe = 0
local lastWingBuffet = 0
local lastEchoingVoid = 0
local lastRenewingBlaze = 0
local lastTimeSpiral = 0
local lastRenew = 0
local lastLifebind = 0
local lastFirebrand = 0
local lastBreathOfEons = 0
local lastDreamflight = 0
local lastFlightOfTheDragon = 0
local lastCallOfYsera = 0
local lastQuell = 0
local lastUnravel = 0
local lastSleepWalk = 0
local lastRescue = 0
local lastExpunge = 0
local playerHealth = 100
local targetHealth = 100
local activeEnemies = 0
local isInRange = false
local castingEmpoweredSpell = false
local lowHealthAllies = 0
local criticalHealthAllies = 0
local tankHealth = 100

-- Constants
local PRESERVATION_SPEC_ID = 1468
local TIP_THE_SCALES_DURATION = 10.0 -- seconds
local ESSENCE_BURST_DURATION = 15.0 -- seconds
local TEMPORAL_ANOMALY_DURATION = 15.0 -- seconds
local OBSIDIAN_SCALES_DURATION = 8.0 -- seconds
local EMERALD_COMMUNION_DURATION = 5.0 -- seconds
local TIME_SPIRAL_DURATION = 8.0 -- seconds
local RENEWING_BLAZE_DURATION = 10.0 -- seconds
local RENEW_DURATION = 12.0 -- seconds
local LIFEBIND_DURATION = 12.0 -- seconds
local RESONATING_PUDDLES_DURATION = 20.0 -- seconds
local BREATH_OF_EONS_DURATION = 30.0 -- seconds
local FLIGHT_OF_THE_DRAGON_DURATION = 20.0 -- seconds
local CALL_OF_YSERA_DURATION = 15.0 -- seconds
local GOLDEN_HOUR_DURATION = 10.0 -- seconds
local DREAMFLIGHT_DURATION = 5.0 -- seconds
local ESSENCE_ATTUNEMENT_DURATION = 10.0 -- seconds
local BOUNTIFUL_BLOOM_DURATION = 6.0 -- seconds
local TIME_TENDER_DURATION = 15.0 -- seconds
local ANCIENT_FLAME_DURATION = 5.0 -- seconds
local FIELD_OF_DREAMS_DURATION = 15.0 -- seconds
local VERDANT_EMBRACE_DURATION = 6.0 -- seconds
local REWIND_COOLDOWN = 90.0 -- seconds

-- Initialize the Preservation module
function Preservation:Initialize()
    self:RegisterSpells()
    self:RegisterVariables()
    self:RegisterSettings()
    self:RegisterEvents()
    
    API.PrintDebug("Preservation Evoker module initialized")
    
    return true
end

-- Register spell IDs
function Preservation:RegisterSpells()
    -- Core abilities
    spells.LIVING_FLAME = 361469
    spells.FIRE_BREATH = 357208
    spells.AZURE_STRIKE = 362969
    spells.DISINTEGRATE = 356995
    spells.EMERALD_BREATH = 355913
    spells.DREAM_BREATH = 355936
    spells.REVERSION = 366155
    spells.SPIRITBLOOM = 367226
    spells.VERDANT_EMBRACE = 360995
    spells.TIME_DILATION = 357170
    spells.ECHO = 364343
    
    -- Core utility and defensive abilities
    spells.TIP_THE_SCALES = 370553
    spells.OBSIDIAN_SCALES = 363916
    spells.CAUTERIZING_FLAME = 374251
    spells.HOVER = 358267
    spells.TAIL_SWIPE = 368970
    spells.WING_BUFFET = 357214
    
    -- Preservation specific tools
    spells.EMERALD_COMMUNION = 370960
    spells.REWIND = 363534
    spells.TIME_SPIRAL = 374968
    
    -- Interrupt and CC
    spells.QUELL = 351338
    spells.SLEEP_WALK = 360806
    
    -- Utility
    spells.RESCUE = 370665
    spells.EXPUNGE = 365585
    spells.FIREBRAND = 374348
    spells.UNRAVEL = 368432
    spells.RENEWING_BLAZE = 374348
    
    -- Talents and passives
    spells.ESSENCE_BURST = 369297
    spells.TEMPORAL_ANOMALY = 373861
    spells.ECHOING_VOID = 409313
    spells.RENEW = 414969
    spells.LIFEBIND = 373270
    spells.RESONATING_PUDDLES = 409031
    spells.BREATH_OF_EONS = 403631
    spells.FLIGHT_OF_THE_DRAGON = 374968
    spells.CALL_OF_YSERA = 373835
    spells.GOLDEN_HOUR = 408083
    spells.DREAMFLIGHT = 406383
    spells.DELUGE = 409768
    spells.ESSENCE_ATTUNEMENT = 375722
    spells.BOUNTIFUL_BLOOM = 370839
    spells.TIME_TENDER = 387763
    spells.ANCIENT_FLAME = 369990
    spells.FIELD_OF_DREAMS = 370062
    
    -- War Within Season 2 specific
    spells.VERDANT_RENEWAL = 376163
    
    -- Buff IDs
    spells.TIP_THE_SCALES_BUFF = 370553
    spells.ESSENCE_BURST_BUFF = 369299
    spells.TEMPORAL_ANOMALY_BUFF = 373861
    spells.OBSIDIAN_SCALES_BUFF = 363916
    spells.EMERALD_COMMUNION_BUFF = 370960
    spells.TIME_SPIRAL_BUFF = 374968
    spells.RENEWING_BLAZE_BUFF = 374348
    spells.RENEW_BUFF = 414969
    spells.LIFEBIND_BUFF = 373270
    spells.RESONATING_PUDDLES_BUFF = 409031
    spells.BREATH_OF_EONS_BUFF = 403631
    spells.FLIGHT_OF_THE_DRAGON_BUFF = 374968
    spells.CALL_OF_YSERA_BUFF = 373835
    spells.GOLDEN_HOUR_BUFF = 408083
    spells.DREAMFLIGHT_BUFF = 406383
    spells.ESSENCE_ATTUNEMENT_BUFF = 375722
    spells.BOUNTIFUL_BLOOM_BUFF = 370839
    spells.TIME_TENDER_BUFF = 387763
    spells.ANCIENT_FLAME_BUFF = 369990
    spells.FIELD_OF_DREAMS_BUFF = 370062
    spells.VERDANT_EMBRACE_BUFF = 360995
    spells.REWIND_BUFF = 363534
    spells.ECHO_BUFF = 364343
    
    -- HoT IDs
    spells.LIVING_FLAME_HOT = 361509
    spells.EMERALD_BLOSSOM_HOT = 355941
    
    -- Debuff IDs
    spells.DISINTEGRATE_DOT = 356995
    spells.FIRE_BREATH_DOT = 357209
    spells.FIREBRAND_DEBUFF = 374349
    spells.ECHOING_VOID_DEBUFF = 409313
    
    -- Register all spells with the API tracking system
    for spellName, spellID in pairs(spells) do
        API.RegisterSpell(spellID)
    end
    
    -- Define aura tracking
    buffs.TIP_THE_SCALES = spells.TIP_THE_SCALES_BUFF
    buffs.ESSENCE_BURST = spells.ESSENCE_BURST_BUFF
    buffs.TEMPORAL_ANOMALY = spells.TEMPORAL_ANOMALY_BUFF
    buffs.OBSIDIAN_SCALES = spells.OBSIDIAN_SCALES_BUFF
    buffs.EMERALD_COMMUNION = spells.EMERALD_COMMUNION_BUFF
    buffs.TIME_SPIRAL = spells.TIME_SPIRAL_BUFF
    buffs.RENEWING_BLAZE = spells.RENEWING_BLAZE_BUFF
    buffs.RENEW = spells.RENEW_BUFF
    buffs.LIFEBIND = spells.LIFEBIND_BUFF
    buffs.RESONATING_PUDDLES = spells.RESONATING_PUDDLES_BUFF
    buffs.BREATH_OF_EONS = spells.BREATH_OF_EONS_BUFF
    buffs.FLIGHT_OF_THE_DRAGON = spells.FLIGHT_OF_THE_DRAGON_BUFF
    buffs.CALL_OF_YSERA = spells.CALL_OF_YSERA_BUFF
    buffs.GOLDEN_HOUR = spells.GOLDEN_HOUR_BUFF
    buffs.DREAMFLIGHT = spells.DREAMFLIGHT_BUFF
    buffs.ESSENCE_ATTUNEMENT = spells.ESSENCE_ATTUNEMENT_BUFF
    buffs.BOUNTIFUL_BLOOM = spells.BOUNTIFUL_BLOOM_BUFF
    buffs.TIME_TENDER = spells.TIME_TENDER_BUFF
    buffs.ANCIENT_FLAME = spells.ANCIENT_FLAME_BUFF
    buffs.FIELD_OF_DREAMS = spells.FIELD_OF_DREAMS_BUFF
    buffs.VERDANT_EMBRACE = spells.VERDANT_EMBRACE_BUFF
    buffs.REWIND = spells.REWIND_BUFF
    buffs.ECHO = spells.ECHO_BUFF
    
    buffs.LIVING_FLAME_HOT = spells.LIVING_FLAME_HOT
    buffs.EMERALD_BLOSSOM = spells.EMERALD_BLOSSOM_HOT
    
    debuffs.DISINTEGRATE = spells.DISINTEGRATE_DOT
    debuffs.FIRE_BREATH = spells.FIRE_BREATH_DOT
    debuffs.FIREBRAND = spells.FIREBRAND_DEBUFF
    debuffs.ECHOING_VOID = spells.ECHOING_VOID_DEBUFF
    
    return true
end

-- Register variables to track
function Preservation:RegisterVariables()
    -- Talent tracking
    talents.hasTemporalAnomaly = false
    talents.hasEchoingVoid = false
    talents.hasRenew = false
    talents.hasLifebind = false
    talents.hasResonatingPuddles = false
    talents.hasBreathOfEons = false
    talents.hasFlightOfTheDragon = false
    talents.hasCallOfYsera = false
    talents.hasGoldenHour = false
    talents.hasDreamflight = false
    talents.hasDeluge = false
    talents.hasEssenceAttunement = false
    talents.hasBountifulBloom = false
    talents.hasTimeTender = false
    talents.hasAncientFlame = false
    talents.hasFieldOfDreams = false
    
    -- Initialize resources
    currentMana = API.GetPlayerManaPercentage() or 100
    currentEssence = API.GetPowerResource("essence") or 0
    maxEssence = 6 -- Default
    
    return true
end

-- Register spec-specific settings
function Preservation:RegisterSettings()
    ConfigRegistry:RegisterSettings("PreservationEvoker", {
        rotationSettings = {
            burstEnabled = {
                displayName = "Enable Burst Mode",
                description = "Use cooldowns and focus on burst healing",
                type = "toggle",
                default = true
            },
            empowerPreference = {
                displayName = "Empower Preference",
                description = "How to handle empowered spells",
                type = "dropdown",
                options = {"Maximum Empower", "Fast Cast", "Situational", "Manual Control"},
                default = "Situational"
            },
            emeraldBreathLevel = {
                displayName = "Emerald Breath Empower Level",
                description = "Default empower level for Emerald Breath (0-3)",
                type = "slider",
                min = 0,
                max = 3,
                default = 1
            },
            dreamBreathLevel = {
                displayName = "Dream Breath Empower Level",
                description = "Default empower level for Dream Breath (0-3)",
                type = "slider",
                min = 0,
                max = 3,
                default = 1
            },
            reversionLevel = {
                displayName = "Reversion Empower Level",
                description = "Default empower level for Reversion (0-3)",
                type = "slider",
                min = 0,
                max = 3,
                default = 1
            },
            spiritbloomLevel = {
                displayName = "Spiritbloom Empower Level",
                description = "Default empower level for Spiritbloom (0-3)",
                type = "slider",
                min = 0,
                max = 3,
                default = 1
            },
            essenceManagement = {
                displayName = "Essence Management",
                description = "How to manage Essence resource",
                type = "dropdown",
                options = {"Aggressive", "Balanced", "Conservative"},
                default = "Balanced"
            },
            conserveEssence = {
                displayName = "Conserve Essence Percentage",
                description = "Minimum Essence to maintain",
                type = "slider",
                min = 0,
                max = 4,
                default = 1
            },
            manaManagement = {
                displayName = "Mana Management",
                description = "How to manage Mana resource",
                type = "dropdown",
                options = {"Aggressive", "Balanced", "Conservative"},
                default = "Balanced"
            },
            manaSaveThreshold = {
                displayName = "Mana Save Threshold",
                description = "Percentage of mana to begin conserving",
                type = "slider",
                min = 10,
                max = 50,
                default = 30
            },
            tipTheScalesUsage = {
                displayName = "Tip the Scales Usage",
                description = "When to use Tip the Scales",
                type = "dropdown",
                options = {"Emergency", "Emerald Breath", "Dream Breath", "Spiritbloom", "Manual Only"},
                default = "Emergency"
            },
            livingFlameUsage = {
                displayName = "Living Flame Usage",
                description = "When to use Living Flame",
                type = "dropdown",
                options = {"Essence Builder", "Damage Only", "Healing Priority", "Emergency Heal", "Never"},
                default = "Healing Priority"
            }
        },
        
        healingSettings = {
            healthThresholds = {
                displayName = "Health Thresholds",
                description = "Health percentage thresholds for different healing priorities",
                type = "group",
                settings = {
                    critical = {
                        displayName = "Critical Health",
                        description = "Health percentage considered critical",
                        type = "slider",
                        min = 1,
                        max = 40,
                        default = 30
                    },
                    low = {
                        displayName = "Low Health",
                        description = "Health percentage considered low",
                        type = "slider",
                        min = 41,
                        max = 75,
                        default = 65
                    },
                    medium = {
                        displayName = "Medium Health",
                        description = "Health percentage considered medium",
                        type = "slider",
                        min = 76,
                        max = 90,
                        default = 85
                    }
                }
            },
            verdantEmbraceUsage = {
                displayName = "Verdant Embrace Usage",
                description = "When to use Verdant Embrace",
                type = "dropdown",
                options = {"On Cooldown", "Low Health", "Critical Health Only", "Tank Priority", "Manual Only"},
                default = "Low Health"
            },
            reversionUsage = {
                displayName = "Reversion Usage",
                description = "When to use Reversion",
                type = "dropdown",
                options = {"On Cooldown", "Low Health", "Critical Health Only", "Tank Priority", "Manual Only"},
                default = "Low Health"
            },
            spiritbloomUsage = {
                displayName = "Spiritbloom Usage",
                description = "When to use Spiritbloom",
                type = "dropdown",
                options = {"On Cooldown", "Group Healing", "Emergency AoE", "Manual Only"},
                default = "Group Healing"
            },
            spiritbloomThreshold = {
                displayName = "Spiritbloom Target Count",
                description = "Minimum injured targets for Spiritbloom",
                type = "slider",
                min = 2,
                max = 6,
                default = 3
            },
            dreamBreathUsage = {
                displayName = "Dream Breath Usage",
                description = "When to use Dream Breath",
                type = "dropdown",
                options = {"On Cooldown", "Group Healing", "Emergency AoE", "Manual Only"},
                default = "Group Healing"
            },
            dreamBreathThreshold = {
                displayName = "Dream Breath Target Count",
                description = "Minimum injured targets for Dream Breath",
                type = "slider",
                min = 2,
                max = 6,
                default = 3
            },
            emeraldBreathUsage = {
                displayName = "Emerald Breath Usage",
                description = "When to use Emerald Breath",
                type = "dropdown",
                options = {"On Cooldown", "Group Healing", "Emergency AoE", "Manual Only"},
                default = "Group Healing"
            },
            emeraldBreathThreshold = {
                displayName = "Emerald Breath Target Count",
                description = "Minimum injured targets for Emerald Breath",
                type = "slider",
                min = 2,
                max = 6,
                default = 3
            }
        },
        
        cooldownSettings = {
            useRewind = {
                displayName = "Use Rewind",
                description = "Automatically use Rewind",
                type = "toggle",
                default = true
            },
            rewindMode = {
                displayName = "Rewind Usage",
                description = "When to use Rewind",
                type = "dropdown",
                options = {"Tank Only", "Any Critical", "Multiple Critical", "Manual Only"},
                default = "Any Critical"
            },
            rewindTargetCount = {
                displayName = "Rewind Critical Target Count",
                description = "Minimum critical health targets for Multiple Critical mode",
                type = "slider",
                min = 2,
                max = 5,
                default = 2
            },
            useEmeraldCommunion = {
                displayName = "Use Emerald Communion",
                description = "Automatically use Emerald Communion",
                type = "toggle",
                default = true
            },
            emeraldCommunionMode = {
                displayName = "Emerald Communion Usage",
                description = "When to use Emerald Communion",
                type = "dropdown",
                options = {"Low Mana", "Group Emergency", "With Cooldowns", "Manual Only"},
                default = "Low Mana"
            },
            emeraldCommunionManaThreshold = {
                displayName = "Emerald Communion Mana Threshold",
                description = "Mana percentage to use Emerald Communion in Low Mana mode",
                type = "slider",
                min = 5,
                max = 40,
                default = 20
            },
            useTimeDilation = {
                displayName = "Use Time Dilation",
                description = "Automatically use Time Dilation",
                type = "toggle",
                default = true
            },
            timeDilationMode = {
                displayName = "Time Dilation Usage",
                description = "When to use Time Dilation",
                type = "dropdown",
                options = {"On Cooldown", "Tank Priority", "Low Health Target", "Manual Only"},
                default = "Tank Priority"
            }
        },
        
        defensiveSettings = {
            useObsidianScales = {
                displayName = "Use Obsidian Scales",
                description = "Automatically use Obsidian Scales",
                type = "toggle",
                default = true
            },
            obsidianScalesThreshold = {
                displayName = "Obsidian Scales Threshold",
                description = "Health percentage to use Obsidian Scales",
                type = "slider",
                min = 10,
                max = 80,
                default = 50
            },
            useCauterizingFlame = {
                displayName = "Use Cauterizing Flame",
                description = "Automatically use Cauterizing Flame",
                type = "toggle",
                default = true
            },
            cauterizingFlameThreshold = {
                displayName = "Cauterizing Flame Threshold",
                description = "Health percentage to use Cauterizing Flame",
                type = "slider",
                min = 10,
                max = 80,
                default = 70
            },
            useRenewingBlaze = {
                displayName = "Use Renewing Blaze",
                description = "Automatically use Renewing Blaze",
                type = "toggle",
                default = true
            },
            renewingBlazeThreshold = {
                displayName = "Renewing Blaze Threshold", 
                description = "Health percentage to use Renewing Blaze",
                type = "slider",
                min = 10,
                max = 80,
                default = 60
            }
        },
        
        utilitySettings = {
            useHover = {
                displayName = "Use Hover",
                description = "Automatically use Hover for mobility",
                type = "toggle",
                default = true
            },
            hoverMode = {
                displayName = "Hover Usage",
                description = "When to use Hover",
                type = "dropdown",
                options = {"When Falling", "For Mobility", "Manual Only"},
                default = "When Falling"
            },
            useSleepWalk = {
                displayName = "Use Sleep Walk",
                description = "Automatically use Sleep Walk for CC",
                type = "toggle",
                default = true
            },
            useQuell = {
                displayName = "Use Quell",
                description = "Automatically use Quell to interrupt",
                type = "toggle",
                default = true
            },
            useRescue = {
                displayName = "Use Rescue",
                description = "Automatically use Rescue on allies",
                type = "toggle",
                default = true
            },
            useExpunge = {
                displayName = "Use Expunge",
                description = "Automatically use Expunge to cleanse",
                type = "toggle",
                default = true
            }
        },
        
        -- Advanced ability control settings
        abilityControls = {
            -- Emerald Breath controls
            emeraldBreath = AAC.RegisterAbility(spells.EMERALD_BREATH, {
                enabled = true,
                useDuringBurstOnly = false,
                empowerLevel = 1,
                autoEmpowerLevel = true,
                minTargets = 3
            }),
            
            -- Dream Breath controls
            dreamBreath = AAC.RegisterAbility(spells.DREAM_BREATH, {
                enabled = true,
                useDuringBurstOnly = false,
                empowerLevel = 1,
                autoEmpowerLevel = true,
                minTargets = 3
            }),
            
            -- Reversion controls
            reversion = AAC.RegisterAbility(spells.REVERSION, {
                enabled = true,
                useDuringBurstOnly = false,
                empowerLevel = 1,
                autoEmpowerLevel = true,
                tankPriority = true
            }),
            
            -- Spiritbloom controls
            spiritbloom = AAC.RegisterAbility(spells.SPIRITBLOOM, {
                enabled = true,
                useDuringBurstOnly = false,
                empowerLevel = 1,
                autoEmpowerLevel = true,
                minTargets = 3
            })
        }
    })
    
    return true
end

-- Register for events 
function Preservation:RegisterEvents()
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
    
    -- Register for essence updates
    API.RegisterEvent("UNIT_POWER_FREQUENT", function(unit, powerType) 
        if unit == "player" and powerType == "ESSENCE" then
            self:UpdateEssence()
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
    
    -- Register for group health updates
    API.RegisterEvent("GROUP_ROSTER_UPDATE", function()
        self:UpdateGroupHealth()
    end)
    
    -- Register for spell cast events to handle empowered spells
    API.RegisterEvent("UNIT_SPELLCAST_CHANNEL_START", function(unit, _, spellID) 
        if unit == "player" then
            self:HandleSpellChannelStart(spellID)
        end
    end)
    
    API.RegisterEvent("UNIT_SPELLCAST_EMPOWER_START", function(unit, _, spellID) 
        if unit == "player" then
            self:HandleEmpowerStart(spellID)
        end
    end)
    
    API.RegisterEvent("UNIT_SPELLCAST_EMPOWER_STOP", function(unit, _, spellID) 
        if unit == "player" then
            self:HandleEmpowerStop(spellID)
        end
    end)
    
    -- Initial talent info update
    self:UpdateTalentInfo()
    
    return true
end

-- Update talent information
function Preservation:UpdateTalentInfo()
    -- Check for important talents
    talents.hasTemporalAnomaly = API.HasTalent(spells.TEMPORAL_ANOMALY)
    talents.hasEchoingVoid = API.HasTalent(spells.ECHOING_VOID)
    talents.hasRenew = API.HasTalent(spells.RENEW)
    talents.hasLifebind = API.HasTalent(spells.LIFEBIND)
    talents.hasResonatingPuddles = API.HasTalent(spells.RESONATING_PUDDLES)
    talents.hasBreathOfEons = API.HasTalent(spells.BREATH_OF_EONS)
    talents.hasFlightOfTheDragon = API.HasTalent(spells.FLIGHT_OF_THE_DRAGON)
    talents.hasCallOfYsera = API.HasTalent(spells.CALL_OF_YSERA)
    talents.hasGoldenHour = API.HasTalent(spells.GOLDEN_HOUR)
    talents.hasDreamflight = API.HasTalent(spells.DREAMFLIGHT)
    talents.hasDeluge = API.HasTalent(spells.DELUGE)
    talents.hasEssenceAttunement = API.HasTalent(spells.ESSENCE_ATTUNEMENT)
    talents.hasBountifulBloom = API.HasTalent(spells.BOUNTIFUL_BLOOM)
    talents.hasTimeTender = API.HasTalent(spells.TIME_TENDER)
    talents.hasAncientFlame = API.HasTalent(spells.ANCIENT_FLAME)
    talents.hasFieldOfDreams = API.HasTalent(spells.FIELD_OF_DREAMS)
    
    -- Set specialized variables based on talents
    if talents.hasTemporalAnomaly then
        temporalAnomaly = true
    end
    
    if talents.hasEchoingVoid then
        echoingVoid = true
    end
    
    if talents.hasRenew then
        renew = true
    end
    
    if talents.hasLifebind then
        lifebind = true
    end
    
    if talents.hasResonatingPuddles then
        resonatingPuddles = true
    end
    
    if talents.hasBreathOfEons then
        breathOfEons = true
    end
    
    if talents.hasFlightOfTheDragon then
        flightOfTheDragon = true
    end
    
    if talents.hasCallOfYsera then
        callOfYsera = true
    end
    
    if talents.hasGoldenHour then
        goldenHour = true
    end
    
    if talents.hasDreamflight then
        dreamflight = true
    end
    
    if talents.hasDeluge then
        deluge = true
    end
    
    if talents.hasEssenceAttunement then
        essenceAttunement = true
    end
    
    if talents.hasBountifulBloom then
        bountifulBloom = true
    end
    
    if talents.hasTimeTender then
        timeTender = true
    end
    
    if talents.hasAncientFlame then
        ancientFlame = true
    end
    
    if talents.hasFieldOfDreams then
        fieldOfDreams = true
    end
    
    if API.IsSpellKnown(spells.LIVING_FLAME) then
        livingFlame = true
    end
    
    if API.IsSpellKnown(spells.FIRE_BREATH) then
        fireBreath = true
        fireBreathEmpowered = true
    end
    
    if API.IsSpellKnown(spells.AZURE_STRIKE) then
        azureStrike = true
    end
    
    if API.IsSpellKnown(spells.DISINTEGRATE) then
        disintegrate = true
    end
    
    if API.IsSpellKnown(spells.EMERALD_BREATH) then
        emeraldBreath = true
        emeraldBreathEmpowered = true
    end
    
    if API.IsSpellKnown(spells.DREAM_BREATH) then
        dreamBreath = true
        dreamBreathEmpowered = true
    end
    
    if API.IsSpellKnown(spells.REVERSION) then
        reversion = true
        reversionEmpowered = true
    end
    
    if API.IsSpellKnown(spells.SPIRITBLOOM) then
        spiritbloom = true
        spiritbloomEmpowered = true
    end
    
    if API.IsSpellKnown(spells.VERDANT_EMBRACE) then
        verdantEmbrace = true
    end
    
    if API.IsSpellKnown(spells.TIME_DILATION) then
        timeDilation = true
    end
    
    if API.IsSpellKnown(spells.EMERALD_COMMUNION) then
        emeraldCommunion = true
    end
    
    if API.IsSpellKnown(spells.REWIND) then
        rewind = true
    end
    
    if API.IsSpellKnown(spells.TIP_THE_SCALES) then
        tipTheScales = true
    end
    
    if API.IsSpellKnown(spells.OBSIDIAN_SCALES) then
        obsidianScales = true
    end
    
    if API.IsSpellKnown(spells.CAUTERIZING_FLAME) then
        cauterizingFlame = true
    end
    
    if API.IsSpellKnown(spells.HOVER) then
        hover = true
    end
    
    if API.IsSpellKnown(spells.TAIL_SWIPE) then
        tailSwipe = true
    end
    
    if API.IsSpellKnown(spells.WING_BUFFET) then
        wingBuffet = true
    end
    
    if API.IsSpellKnown(spells.ESSENCE_BURST) then
        essenceBurst = true
    end
    
    if API.IsSpellKnown(spells.TIME_SPIRAL) then
        timeSpiral = true
    end
    
    if API.IsSpellKnown(spells.RENEWING_BLAZE) then
        renewingBlaze = true
    end
    
    API.PrintDebug("Preservation Evoker talents updated")
    
    return true
end

-- Update mana tracking
function Preservation:UpdateMana()
    currentMana = API.GetPlayerManaPercentage()
    return true
end

-- Update essence tracking
function Preservation:UpdateEssence()
    currentEssence = API.GetPowerResource("essence") or 0
    return true
end

-- Update health tracking
function Preservation:UpdateHealth()
    playerHealth = API.GetPlayerHealthPercent()
    return true
end

-- Update target health tracking
function Preservation:UpdateTargetHealth()
    targetHealth = API.GetTargetHealthPercent()
    return true
end

-- Update group health status
function Preservation:UpdateGroupHealth()
    local criticalThreshold = ConfigRegistry:GetSettings("PreservationEvoker").healingSettings.healthThresholds.critical
    local lowThreshold = ConfigRegistry:GetSettings("PreservationEvoker").healingSettings.healthThresholds.low
    
    lowHealthAllies = 0
    criticalHealthAllies = 0
    tankHealth = 100
    
    -- Count group members at low/critical health
    for i = 1, API.GetGroupSize() do
        local unit
        if API.IsInRaid() then
            unit = "raid" .. i
        else
            unit = i == 1 and "player" or "party" .. (i - 1)
        end
        
        if API.UnitExists(unit) and not API.UnitIsDead(unit) then
            local health = API.GetUnitHealthPercent(unit)
            
            if health <= criticalThreshold then
                criticalHealthAllies = criticalHealthAllies + 1
            elseif health <= lowThreshold then
                lowHealthAllies = lowHealthAllies + 1
            end
            
            -- Track tank health
            if API.UnitIsTank(unit) then
                tankHealth = math.min(tankHealth, health)
            end
        end
    end
    
    return true
end

-- Update active enemy counts
function Preservation:UpdateEnemyCounts()
    activeEnemies = API.GetEnemyCount() or 0
    return true
end

-- Handle spell channel start
function Preservation:HandleSpellChannelStart(spellID)
    if spellID == spells.DISINTEGRATE then
        disintegrateActive = true
        disintegrateEndTime = GetTime() + 3.0 -- Approximate channel duration
        API.PrintDebug("Disintegrate channel started")
    elseif spellID == spells.ECHOING_VOID then
        echoingVoidActive = true
        echoingVoidEndTime = GetTime() + 3.0 -- Approximate channel duration
        API.PrintDebug("Echoing Void channel started")
    end
    
    return true
end

-- Handle empowered spell start
function Preservation:HandleEmpowerStart(spellID)
    castingEmpoweredSpell = true
    
    if spellID == spells.FIRE_BREATH then
        fireBreathActive = true
        API.PrintDebug("Fire Breath empowering started")
    elseif spellID == spells.EMERALD_BREATH then
        emeraldBreathActive = true
        API.PrintDebug("Emerald Breath empowering started")
    elseif spellID == spells.DREAM_BREATH then
        dreamBreathActive = true
        API.PrintDebug("Dream Breath empowering started")
    elseif spellID == spells.REVERSION then
        reversionActive = true
        API.PrintDebug("Reversion empowering started")
    elseif spellID == spells.SPIRITBLOOM then
        spiritbloomActive = true
        API.PrintDebug("Spiritbloom empowering started")
    end
    
    return true
end

-- Handle empowered spell stop
function Preservation:HandleEmpowerStop(spellID)
    castingEmpoweredSpell = false
    
    if spellID == spells.FIRE_BREATH then
        fireBreathActive = false
        fireBreathEndTime = GetTime() + 15.0 -- DoT duration (approximate)
        API.PrintDebug("Fire Breath cast")
    elseif spellID == spells.EMERALD_BREATH then
        emeraldBreathActive = false
        emeraldBreathEndTime = GetTime() + 30.0 -- HoT duration (approximate)
        API.PrintDebug("Emerald Breath cast")
    elseif spellID == spells.DREAM_BREATH then
        dreamBreathActive = false
        dreamBreathEndTime = GetTime() + 16.0 -- HoT duration (approximate)
        API.PrintDebug("Dream Breath cast")
    elseif spellID == spells.REVERSION then
        reversionActive = false
        reversionEndTime = GetTime() + 8.0 -- Effect duration (approximate)
        API.PrintDebug("Reversion cast")
    elseif spellID == spells.SPIRITBLOOM then
        spiritbloomActive = false
        spiritbloomEndTime = GetTime() + 8.0 -- Effect duration (approximate)
        API.PrintDebug("Spiritbloom cast")
    end
    
    return true
end

-- Handle combat log events
function Preservation:HandleCombatLogEvent(...)
    local timestamp, eventType, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, spellID, spellName = CombatLogGetCurrentEventInfo()
    
    -- Track player events (casts, buffs, etc.)
    if sourceGUID == API.GetPlayerGUID() then
        -- Track buff applications
        if eventType == "SPELL_AURA_APPLIED" or eventType == "SPELL_AURA_REFRESH" then
            -- Track Tip the Scales application
            if spellID == buffs.TIP_THE_SCALES then
                tipTheScalesActive = true
                tipTheScalesEndTime = select(6, API.GetBuffInfo("player", buffs.TIP_THE_SCALES))
                API.PrintDebug("Tip the Scales activated")
            end
            
            -- Track Essence Burst application
            if spellID == buffs.ESSENCE_BURST then
                essenceBurstActive = true
                essenceBurstEndTime = select(6, API.GetBuffInfo("player", buffs.ESSENCE_BURST))
                essenceBurstStacks = select(4, API.GetBuffInfo("player", buffs.ESSENCE_BURST)) or 1
                API.PrintDebug("Essence Burst activated: " .. tostring(essenceBurstStacks) .. " stack(s)")
            end
            
            -- Track Temporal Anomaly application
            if spellID == buffs.TEMPORAL_ANOMALY then
                temporalAnomalyActive = true
                temporalAnomalyEndTime = select(6, API.GetBuffInfo("player", buffs.TEMPORAL_ANOMALY))
                API.PrintDebug("Temporal Anomaly activated")
            end
            
            -- Track Obsidian Scales application
            if spellID == buffs.OBSIDIAN_SCALES then
                obsidianScalesActive = true
                obsidianScalesEndTime = select(6, API.GetBuffInfo("player", buffs.OBSIDIAN_SCALES))
                API.PrintDebug("Obsidian Scales activated")
            end
            
            -- Track Emerald Communion application
            if spellID == buffs.EMERALD_COMMUNION then
                emeraldCommunionActive = true
                emeraldCommunionEndTime = select(6, API.GetBuffInfo("player", buffs.EMERALD_COMMUNION))
                API.PrintDebug("Emerald Communion activated")
            end
            
            -- Track Time Spiral application
            if spellID == buffs.TIME_SPIRAL then
                timeSpiralActive = true
                timeSpiralEndTime = select(6, API.GetBuffInfo("player", buffs.TIME_SPIRAL))
                API.PrintDebug("Time Spiral activated")
            end
            
            -- Track Renewing Blaze application
            if spellID == buffs.RENEWING_BLAZE then
                renewingBlazeActive = true
                renewingBlazeEndTime = select(6, API.GetBuffInfo("player", buffs.RENEWING_BLAZE))
                API.PrintDebug("Renewing Blaze activated")
            end
            
            -- Track Essence Attunement application
            if spellID == buffs.ESSENCE_ATTUNEMENT then
                essenceAttunementActive = true
                essenceAttunementEndTime = select(6, API.GetBuffInfo("player", buffs.ESSENCE_ATTUNEMENT))
                essenceAttunementStacks = select(4, API.GetBuffInfo("player", buffs.ESSENCE_ATTUNEMENT)) or 1
                API.PrintDebug("Essence Attunement activated: " .. tostring(essenceAttunementStacks) .. " stack(s)")
            end
            
            -- Track Bountiful Bloom application
            if spellID == buffs.BOUNTIFUL_BLOOM then
                bountifulBloomActive = true
                bountifulBloomEndTime = select(6, API.GetBuffInfo("player", buffs.BOUNTIFUL_BLOOM))
                API.PrintDebug("Bountiful Bloom activated")
            end
            
            -- Track Time Tender application
            if spellID == buffs.TIME_TENDER then
                timeTenderActive = true
                timeTenderEndTime = select(6, API.GetBuffInfo("player", buffs.TIME_TENDER))
                API.PrintDebug("Time Tender activated")
            end
            
            -- Track Ancient Flame application
            if spellID == buffs.ANCIENT_FLAME then
                ancientFlameActive = true
                ancientFlameEndTime = select(6, API.GetBuffInfo("player", buffs.ANCIENT_FLAME))
                API.PrintDebug("Ancient Flame activated")
            end
            
            -- Track Field of Dreams application
            if spellID == buffs.FIELD_OF_DREAMS then
                fieldOfDreamsActive = true
                fieldOfDreamsEndTime = select(6, API.GetBuffInfo("player", buffs.FIELD_OF_DREAMS))
                API.PrintDebug("Field of Dreams activated")
            end
        end
        
        -- Track buff removals
        if eventType == "SPELL_AURA_REMOVED" then
            -- Track Tip the Scales removal
            if spellID == buffs.TIP_THE_SCALES then
                tipTheScalesActive = false
                API.PrintDebug("Tip the Scales faded")
            end
            
            -- Track Essence Burst removal
            if spellID == buffs.ESSENCE_BURST then
                essenceBurstActive = false
                essenceBurstStacks = 0
                API.PrintDebug("Essence Burst faded")
            end
            
            -- Track Temporal Anomaly removal
            if spellID == buffs.TEMPORAL_ANOMALY then
                temporalAnomalyActive = false
                API.PrintDebug("Temporal Anomaly faded")
            end
            
            -- Track Obsidian Scales removal
            if spellID == buffs.OBSIDIAN_SCALES then
                obsidianScalesActive = false
                API.PrintDebug("Obsidian Scales faded")
            end
            
            -- Track Emerald Communion removal
            if spellID == buffs.EMERALD_COMMUNION then
                emeraldCommunionActive = false
                API.PrintDebug("Emerald Communion faded")
            end
            
            -- Track Time Spiral removal
            if spellID == buffs.TIME_SPIRAL then
                timeSpiralActive = false
                API.PrintDebug("Time Spiral faded")
            end
            
            -- Track Renewing Blaze removal
            if spellID == buffs.RENEWING_BLAZE then
                renewingBlazeActive = false
                API.PrintDebug("Renewing Blaze faded")
            end
            
            -- Track Essence Attunement removal
            if spellID == buffs.ESSENCE_ATTUNEMENT then
                essenceAttunementActive = false
                essenceAttunementStacks = 0
                API.PrintDebug("Essence Attunement faded")
            end
            
            -- Track Bountiful Bloom removal
            if spellID == buffs.BOUNTIFUL_BLOOM then
                bountifulBloomActive = false
                API.PrintDebug("Bountiful Bloom faded")
            end
            
            -- Track Time Tender removal
            if spellID == buffs.TIME_TENDER then
                timeTenderActive = false
                API.PrintDebug("Time Tender faded")
            end
            
            -- Track Ancient Flame removal
            if spellID == buffs.ANCIENT_FLAME then
                ancientFlameActive = false
                API.PrintDebug("Ancient Flame faded")
            end
            
            -- Track Field of Dreams removal
            if spellID == buffs.FIELD_OF_DREAMS then
                fieldOfDreamsActive = false
                API.PrintDebug("Field of Dreams faded")
            end
        end
        
        -- Track spell casts
        if eventType == "SPELL_CAST_SUCCESS" then
            if spellID == spells.LIVING_FLAME then
                lastLivingFlame = GetTime()
                API.PrintDebug("Living Flame cast")
            elseif spellID == spells.AZURE_STRIKE then
                lastAzureStrike = GetTime()
                API.PrintDebug("Azure Strike cast")
            elseif spellID == spells.VERDANT_EMBRACE then
                lastVerdantEmbrace = GetTime()
                verdantEmbraceActive = true
                verdantEmbraceEndTime = GetTime() + VERDANT_EMBRACE_DURATION
                API.PrintDebug("Verdant Embrace cast")
            elseif spellID == spells.TIME_DILATION then
                lastTimeDilation = GetTime()
                API.PrintDebug("Time Dilation cast")
            elseif spellID == spells.TIP_THE_SCALES then
                lastTipTheScales = GetTime()
                tipTheScalesActive = true
                tipTheScalesEndTime = GetTime() + TIP_THE_SCALES_DURATION
                API.PrintDebug("Tip the Scales cast")
            elseif spellID == spells.EMERALD_COMMUNION then
                lastEmeraldCommunion = GetTime()
                emeraldCommunionActive = true
                emeraldCommunionEndTime = GetTime() + EMERALD_COMMUNION_DURATION
                API.PrintDebug("Emerald Communion cast")
            elseif spellID == spells.REWIND then
                lastRewind = GetTime()
                rewindActive = true
                rewindEndTime = GetTime() + 5.0 -- Effect duration (approximate)
                rewindCooldown = GetTime() + REWIND_COOLDOWN
                API.PrintDebug("Rewind cast")
            elseif spellID == spells.OBSIDIAN_SCALES then
                lastObsidianScales = GetTime()
                obsidianScalesActive = true
                obsidianScalesEndTime = GetTime() + OBSIDIAN_SCALES_DURATION
                API.PrintDebug("Obsidian Scales cast")
            elseif spellID == spells.CAUTERIZING_FLAME then
                lastCauterizingFlame = GetTime()
                API.PrintDebug("Cauterizing Flame cast")
            elseif spellID == spells.HOVER then
                lastHover = GetTime()
                API.PrintDebug("Hover cast")
            elseif spellID == spells.TAIL_SWIPE then
                lastTailSwipe = GetTime()
                API.PrintDebug("Tail Swipe cast")
            elseif spellID == spells.WING_BUFFET then
                lastWingBuffet = GetTime()
                API.PrintDebug("Wing Buffet cast")
            elseif spellID == spells.RENEWING_BLAZE then
                lastRenewingBlaze = GetTime()
                renewingBlazeActive = true
                renewingBlazeEndTime = GetTime() + RENEWING_BLAZE_DURATION
                API.PrintDebug("Renewing Blaze cast")
            elseif spellID == spells.TIME_SPIRAL then
                lastTimeSpiral = GetTime()
                timeSpiralActive = true
                timeSpiralEndTime = GetTime() + TIME_SPIRAL_DURATION
                API.PrintDebug("Time Spiral cast")
            elseif spellID == spells.RENEW then
                lastRenew = GetTime()
                renewActive = true
                renewEndTime = GetTime() + RENEW_DURATION
                API.PrintDebug("Renew cast")
            elseif spellID == spells.LIFEBIND then
                lastLifebind = GetTime()
                lifebindActive = true
                lifebindEndTime = GetTime() + LIFEBIND_DURATION
                API.PrintDebug("Lifebind cast")
            elseif spellID == spells.FIREBRAND then
                lastFirebrand = GetTime()
                API.PrintDebug("Firebrand cast")
            elseif spellID == spells.BREATH_OF_EONS then
                lastBreathOfEons = GetTime()
                breathOfEonsActive = true
                breathOfEonsEndTime = GetTime() + BREATH_OF_EONS_DURATION
                API.PrintDebug("Breath of Eons cast")
            elseif spellID == spells.DREAMFLIGHT then
                lastDreamflight = GetTime()
                dreamflightActive = true
                dreamflightEndTime = GetTime() + DREAMFLIGHT_DURATION
                API.PrintDebug("Dreamflight cast")
            elseif spellID == spells.FLIGHT_OF_THE_DRAGON then
                lastFlightOfTheDragon = GetTime()
                flightOfTheDragonActive = true
                flightOfTheDragonEndTime = GetTime() + FLIGHT_OF_THE_DRAGON_DURATION
                API.PrintDebug("Flight of the Dragon cast")
            elseif spellID == spells.CALL_OF_YSERA then
                lastCallOfYsera = GetTime()
                callOfYseraActive = true
                callOfYseraEndTime = GetTime() + CALL_OF_YSERA_DURATION
                API.PrintDebug("Call of Ysera cast")
            elseif spellID == spells.QUELL then
                lastQuell = GetTime()
                API.PrintDebug("Quell cast")
            elseif spellID == spells.UNRAVEL then
                lastUnravel = GetTime()
                API.PrintDebug("Unravel cast")
            elseif spellID == spells.SLEEP_WALK then
                lastSleepWalk = GetTime()
                API.PrintDebug("Sleep Walk cast")
            elseif spellID == spells.RESCUE then
                lastRescue = GetTime()
                API.PrintDebug("Rescue cast")
            elseif spellID == spells.EXPUNGE then
                lastExpunge = GetTime()
                API.PrintDebug("Expunge cast")
            elseif spellID == spells.ECHOING_VOID then
                lastEchoingVoid = GetTime()
                echoingVoidActive = true
                echoingVoidEndTime = GetTime() + 3.0 -- Channel duration
                API.PrintDebug("Echoing Void cast")
            end
        end
        
        -- Track debuff applications
        if (eventType == "SPELL_AURA_APPLIED" or eventType == "SPELL_AURA_REFRESH") and destGUID then
            -- Track Firebrand debuff
            if spellID == debuffs.FIREBRAND then
                API.PrintDebug("Firebrand debuff applied to " .. destName)
            end
            
            -- Track Fire Breath debuff
            if spellID == debuffs.FIRE_BREATH then
                API.PrintDebug("Fire Breath debuff applied to " .. destName)
            end
            
            -- Track Disintegrate debuff
            if spellID == debuffs.DISINTEGRATE then
                API.PrintDebug("Disintegrate debuff applied to " .. destName)
            end
            
            -- Track Echoing Void debuff
            if spellID == debuffs.ECHOING_VOID then
                API.PrintDebug("Echoing Void debuff applied to " .. destName)
            end
        end
    end
    
    return true
end

-- Main rotation function
function Preservation:RunRotation()
    -- Check if we should be running Preservation Evoker logic
    if API.GetActiveSpecID() ~= PRESERVATION_SPEC_ID then
        return false
    end
    
    -- Skip rotation if player is casting or empowering
    if API.IsPlayerCasting() or castingEmpoweredSpell then
        return false
    end
    
    -- Get settings
    local settings = ConfigRegistry:GetSettings("PreservationEvoker")
    
    -- Update variables
    self:UpdateEssence()
    self:UpdateGroupHealth()
    self:UpdateEnemyCounts()
    burstModeActive = settings.rotationSettings.burstEnabled and API.ShouldUseBurst()
    
    -- Check if in range
    isInRange = API.IsUnitInRange("target", 30) -- Evoker ranges vary, but 30 yards is good for most abilities
    
    -- Handle next cast override
    if nextCastOverride and API.CanCast(nextCastOverride) then
        local spell = nextCastOverride
        nextCastOverride = nil
        API.CastSpell(spell)
        return true
    end
    
    -- Handle defensive cooldowns
    if self:HandleDefensives(settings) then
        return true
    end
    
    -- Handle interrupts and utility
    if self:HandleInterrupts(settings) then
        return true
    end
    
    -- Handle major cooldowns
    if self:HandleMajorCooldowns(settings) then
        return true
    end
    
    -- Handle dispels
    if self:HandleDispels(settings) then
        return true
    end
    
    -- Handle critical healing
    if self:HandleCriticalHealing(settings) then
        return true
    end
    
    -- Handle group healing
    if lowHealthAllies >= 3 and self:HandleGroupHealing(settings) then
        return true
    end
    
    -- Handle single target healing
    if self:HandleSingleTargetHealing(settings) then
        return true
    end
    
    -- Handle DPS when healing isn't needed
    if activeEnemies > 0 and API.UnitExists("target") and API.IsUnitEnemy("target") then
        return self:HandleDamage(settings)
    end
    
    return false
end

-- Handle defensive cooldowns
function Preservation:HandleDefensives(settings)
    -- Use Obsidian Scales
    if obsidianScales and 
       settings.defensiveSettings.useObsidianScales and 
       playerHealth <= settings.defensiveSettings.obsidianScalesThreshold and 
       API.CanCast(spells.OBSIDIAN_SCALES) then
        API.CastSpell(spells.OBSIDIAN_SCALES)
        return true
    end
    
    -- Use Cauterizing Flame for healing
    if cauterizingFlame and 
       settings.defensiveSettings.useCauterizingFlame and 
       playerHealth <= settings.defensiveSettings.cauterizingFlameThreshold and 
       API.CanCast(spells.CAUTERIZING_FLAME) then
        API.CastSpell(spells.CAUTERIZING_FLAME)
        return true
    end
    
    -- Use Renewing Blaze for healing
    if renewingBlaze and 
       settings.defensiveSettings.useRenewingBlaze and 
       playerHealth <= settings.defensiveSettings.renewingBlazeThreshold and 
       API.CanCast(spells.RENEWING_BLAZE) then
        API.CastSpell(spells.RENEWING_BLAZE)
        return true
    end
    
    return false
end

-- Handle interrupts and utility
function Preservation:HandleInterrupts(settings)
    -- Use Quell to interrupt spellcasting
    if API.IsSpellKnown(spells.QUELL) and 
       settings.utilitySettings.useQuell and 
       API.CanCast(spells.QUELL) and
       API.IsUnitCasting("target") and
       API.CanBeInterrupted("target") then
        API.CastSpellOnUnit(spells.QUELL, "target")
        return true
    end
    
    -- Use Sleep Walk for CC
    if API.IsSpellKnown(spells.SLEEP_WALK) and 
       settings.utilitySettings.useSleepWalk and 
       API.CanCast(spells.SLEEP_WALK) and
       API.ShouldCrowdControl("target") then
        API.CastSpellOnUnit(spells.SLEEP_WALK, "target")
        return true
    end
    
    -- Use Hover for mobility
    if hover and 
       settings.utilitySettings.useHover and 
       settings.utilitySettings.hoverMode ~= "Manual Only" and
       API.CanCast(spells.HOVER) then
        
        if settings.utilitySettings.hoverMode == "When Falling" and API.IsFalling() then
            API.CastSpell(spells.HOVER)
            return true
        elseif settings.utilitySettings.hoverMode == "For Mobility" and API.IsPlayerMoving() then
            API.CastSpell(spells.HOVER)
            return true
        end
    end
    
    -- Use Rescue on allies in danger
    if API.IsSpellKnown(spells.RESCUE) and 
       settings.utilitySettings.useRescue and 
       API.CanCast(spells.RESCUE) then
        
        -- Find ally in danger
        for i = 1, API.GetGroupSize() do
            local unit
            if API.IsInRaid() then
                unit = "raid" .. i
            else
                unit = i == 1 and "player" or "party" .. (i - 1)
            end
            
            if API.UnitExists(unit) and not API.UnitIsDead(unit) and unit ~= "player" then
                local unitHealth = API.GetUnitHealthPercent(unit)
                if unitHealth < 30 and API.UnitIsInDanger(unit) then
                    API.CastSpellOnUnit(spells.RESCUE, unit)
                    return true
                end
            end
        end
    end
    
    return false
end

-- Handle dispels
function Preservation:HandleDispels(settings)
    -- Use Expunge to cleanse debuffs
    if API.IsSpellKnown(spells.EXPUNGE) and 
       settings.utilitySettings.useExpunge and 
       API.CanCast(spells.EXPUNGE) then
        
        -- Check for dispellable debuffs on group members
        for i = 1, API.GetGroupSize() do
            local unit
            if API.IsInRaid() then
                unit = "raid" .. i
            else
                unit = i == 1 and "player" or "party" .. (i - 1)
            end
            
            if API.UnitExists(unit) and not API.UnitIsDead(unit) then
                -- Check for dispellable debuffs
                if API.CanDispelUnit(unit, "Poison") or API.CanDispelUnit(unit, "Curse") or API.CanDispelUnit(unit, "Disease") then
                    API.CastSpellOnUnit(spells.EXPUNGE, unit)
                    return true
                end
            end
        end
    end
    
    return false
end

-- Handle major cooldowns
function Preservation:HandleMajorCooldowns(settings)
    -- Use Tip the Scales
    if tipTheScales and 
       API.CanCast(spells.TIP_THE_SCALES) and
       settings.rotationSettings.tipTheScalesUsage ~= "Manual Only" then
        
        local shouldUseTipTheScales = false
        local nextSpell = nil
        
        if settings.rotationSettings.tipTheScalesUsage == "Emergency" and criticalHealthAllies > 0 then
            shouldUseTipTheScales = true
            
            -- Queue up appropriate healing spell
            if spiritbloom and API.GetSpellCooldown(spells.SPIRITBLOOM) <= 0 and criticalHealthAllies > 1 then
                nextSpell = spells.SPIRITBLOOM
            elseif dreamBreath and API.GetSpellCooldown(spells.DREAM_BREATH) <= 0 and criticalHealthAllies > 1 then
                nextSpell = spells.DREAM_BREATH
            elseif emeraldBreath and API.GetSpellCooldown(spells.EMERALD_BREATH) <= 0 and criticalHealthAllies > 1 then
                nextSpell = spells.EMERALD_BREATH
            elseif reversion and API.GetSpellCooldown(spells.REVERSION) <= 0 then
                nextSpell = spells.REVERSION
            end
        elseif settings.rotationSettings.tipTheScalesUsage == "Emerald Breath" and
               emeraldBreath and API.GetSpellCooldown(spells.EMERALD_BREATH) <= 0 then
            shouldUseTipTheScales = true
            nextSpell = spells.EMERALD_BREATH
        elseif settings.rotationSettings.tipTheScalesUsage == "Dream Breath" and
               dreamBreath and API.GetSpellCooldown(spells.DREAM_BREATH) <= 0 then
            shouldUseTipTheScales = true
            nextSpell = spells.DREAM_BREATH
        elseif settings.rotationSettings.tipTheScalesUsage == "Spiritbloom" and
               spiritbloom and API.GetSpellCooldown(spells.SPIRITBLOOM) <= 0 then
            shouldUseTipTheScales = true
            nextSpell = spells.SPIRITBLOOM
        end
        
        if shouldUseTipTheScales then
            nextCastOverride = nextSpell
            API.CastSpell(spells.TIP_THE_SCALES)
            return true
        end
    end
    
    -- Use Emerald Communion
    if emeraldCommunion and 
       settings.cooldownSettings.useEmeraldCommunion and 
       settings.cooldownSettings.emeraldCommunionMode ~= "Manual Only" and
       API.CanCast(spells.EMERALD_COMMUNION) then
        
        local shouldUseEC = false
        
        if settings.cooldownSettings.emeraldCommunionMode == "Low Mana" then
            shouldUseEC = currentMana <= settings.cooldownSettings.emeraldCommunionManaThreshold
        elseif settings.cooldownSettings.emeraldCommunionMode == "Group Emergency" then
            shouldUseEC = criticalHealthAllies >= 3
        elseif settings.cooldownSettings.emeraldCommunionMode == "With Cooldowns" then
            shouldUseEC = burstModeActive
        end
        
        if shouldUseEC then
            API.CastSpell(spells.EMERALD_COMMUNION)
            return true
        end
    end
    
    -- Use Rewind
    if rewind and 
       settings.cooldownSettings.useRewind and 
       settings.cooldownSettings.rewindMode ~= "Manual Only" and
       API.CanCast(spells.REWIND) and
       GetTime() >= rewindCooldown then
        
        local shouldUseRewind = false
        local target = nil
        
        if settings.cooldownSettings.rewindMode == "Tank Only" then
            for i = 1, API.GetGroupSize() do
                local unit
                if API.IsInRaid() then
                    unit = "raid" .. i
                else
                    unit = i == 1 and "player" or "party" .. (i - 1)
                end
                
                if API.UnitExists(unit) and not API.UnitIsDead(unit) and API.UnitIsTank(unit) then
                    local health = API.GetUnitHealthPercent(unit)
                    if health <= settings.healingSettings.healthThresholds.critical then
                        shouldUseRewind = true
                        target = unit
                        break
                    end
                end
            end
        elseif settings.cooldownSettings.rewindMode == "Any Critical" then
            if criticalHealthAllies > 0 then
                for i = 1, API.GetGroupSize() do
                    local unit
                    if API.IsInRaid() then
                        unit = "raid" .. i
                    else
                        unit = i == 1 and "player" or "party" .. (i - 1)
                    end
                    
                    if API.UnitExists(unit) and not API.UnitIsDead(unit) then
                        local health = API.GetUnitHealthPercent(unit)
                        if health <= settings.healingSettings.healthThresholds.critical then
                            shouldUseRewind = true
                            target = unit
                            break
                        end
                    end
                end
            end
        elseif settings.cooldownSettings.rewindMode == "Multiple Critical" then
            shouldUseRewind = criticalHealthAllies >= settings.cooldownSettings.rewindTargetCount
            
            if shouldUseRewind then
                for i = 1, API.GetGroupSize() do
                    local unit
                    if API.IsInRaid() then
                        unit = "raid" .. i
                    else
                        unit = i == 1 and "player" or "party" .. (i - 1)
                    end
                    
                    if API.UnitExists(unit) and not API.UnitIsDead(unit) then
                        local health = API.GetUnitHealthPercent(unit)
                        if health <= settings.healingSettings.healthThresholds.critical then
                            target = unit
                            break
                        end
                    end
                end
            end
        end
        
        if shouldUseRewind and target then
            API.CastSpellOnUnit(spells.REWIND, target)
            return true
        end
    end
    
    -- Use Time Dilation
    if timeDilation and 
       settings.cooldownSettings.useTimeDilation and 
       settings.cooldownSettings.timeDilationMode ~= "Manual Only" and
       API.CanCast(spells.TIME_DILATION) then
        
        local shouldUseTD = false
        local target = nil
        
        if settings.cooldownSettings.timeDilationMode == "On Cooldown" then
            -- Find a target that has HoTs to extend
            for i = 1, API.GetGroupSize() do
                local unit
                if API.IsInRaid() then
                    unit = "raid" .. i
                else
                    unit = i == 1 and "player" or "party" .. (i - 1)
                end
                
                if API.UnitExists(unit) and not API.UnitIsDead(unit) and
                   (API.UnitHasBuff(unit, buffs.EMERALD_BLOSSOM) or API.UnitHasBuff(unit, buffs.LIVING_FLAME_HOT)) then
                    shouldUseTD = true
                    target = unit
                    break
                end
            end
        elseif settings.cooldownSettings.timeDilationMode == "Tank Priority" then
            for i = 1, API.GetGroupSize() do
                local unit
                if API.IsInRaid() then
                    unit = "raid" .. i
                else
                    unit = i == 1 and "player" or "party" .. (i - 1)
                end
                
                if API.UnitExists(unit) and not API.UnitIsDead(unit) and API.UnitIsTank(unit) and
                   (API.UnitHasBuff(unit, buffs.EMERALD_BLOSSOM) or API.UnitHasBuff(unit, buffs.LIVING_FLAME_HOT)) then
                    shouldUseTD = true
                    target = unit
                    break
                end
            end
        elseif settings.cooldownSettings.timeDilationMode == "Low Health Target" then
            -- Find lowest health target with HoTs
            local lowestHealth = 100
            
            for i = 1, API.GetGroupSize() do
                local unit
                if API.IsInRaid() then
                    unit = "raid" .. i
                else
                    unit = i == 1 and "player" or "party" .. (i - 1)
                end
                
                if API.UnitExists(unit) and not API.UnitIsDead(unit) and
                   (API.UnitHasBuff(unit, buffs.EMERALD_BLOSSOM) or API.UnitHasBuff(unit, buffs.LIVING_FLAME_HOT)) then
                    local health = API.GetUnitHealthPercent(unit)
                    if health < lowestHealth then
                        lowestHealth = health
                        target = unit
                        shouldUseTD = true
                    end
                end
            end
        end
        
        if shouldUseTD and target then
            API.CastSpellOnUnit(spells.TIME_DILATION, target)
            return true
        end
    end
    
    return false
end

-- Handle critical healing
function Preservation:HandleCriticalHealing(settings)
    if criticalHealthAllies <= 0 then
        return false
    end
    
    -- Find the critical health target
    local criticalTarget = nil
    local lowestHealth = 100
    
    for i = 1, API.GetGroupSize() do
        local unit
        if API.IsInRaid() then
            unit = "raid" .. i
        else
            unit = i == 1 and "player" or "party" .. (i - 1)
        end
        
        if API.UnitExists(unit) and not API.UnitIsDead(unit) then
            local health = API.GetUnitHealthPercent(unit)
            if health <= settings.healingSettings.healthThresholds.critical and health < lowestHealth then
                lowestHealth = health
                criticalTarget = unit
            end
        end
    end
    
    if not criticalTarget then
        return false
    end
    
    -- Use Verdant Embrace on critical target
    if verdantEmbrace and 
       API.CanCast(spells.VERDANT_EMBRACE) and
       (settings.healingSettings.verdantEmbraceUsage == "Critical Health Only" or settings.healingSettings.verdantEmbraceUsage == "Low Health") then
        API.CastSpellOnUnit(spells.VERDANT_EMBRACE, criticalTarget)
        return true
    end
    
    -- Use Reversion on critical target
    if reversion and 
       reversionEmpowered and 
       API.CanCast(spells.REVERSION) and
       (settings.healingSettings.reversionUsage == "Critical Health Only" or settings.healingSettings.reversionUsage == "Low Health") and
       settings.abilityControls.reversion.enabled then
        
        local empowerLevel = settings.abilityControls.reversion.empowerLevel
        
        -- Adjust empower level based on settings and circumstances
        if settings.abilityControls.reversion.autoEmpowerLevel then
            if settings.rotationSettings.empowerPreference == "Maximum Empower" then
                empowerLevel = 3
            elseif settings.rotationSettings.empowerPreference == "Fast Cast" then
                empowerLevel = 0
            elseif settings.rotationSettings.empowerPreference == "Situational" then
                -- In critical situations, use a balanced level
                empowerLevel = 1
                
                -- If we have Tip the Scales active, use max empower
                if tipTheScalesActive then
                    empowerLevel = 3
                end
            else
                empowerLevel = settings.rotationSettings.reversionLevel
            end
        end
        
        API.CastSpellOnUnitEmpowered(spells.REVERSION, criticalTarget, empowerLevel)
        return true
    end
    
    -- Use Spiritbloom if multiple critical targets
    if spiritbloom and 
       spiritbloomEmpowered and 
       API.CanCast(spells.SPIRITBLOOM) and
       criticalHealthAllies >= 2 and
       settings.healingSettings.spiritbloomUsage == "Emergency AoE" and
       settings.abilityControls.spiritbloom.enabled then
        
        local empowerLevel = settings.abilityControls.spiritbloom.empowerLevel
        
        -- Adjust empower level based on settings and circumstances
        if settings.abilityControls.spiritbloom.autoEmpowerLevel then
            if settings.rotationSettings.empowerPreference == "Maximum Empower" then
                empowerLevel = 3
            elseif settings.rotationSettings.empowerPreference == "Fast Cast" then
                empowerLevel = 0
            elseif settings.rotationSettings.empowerPreference == "Situational" then
                -- Scale with target count
                empowerLevel = math.min(criticalHealthAllies - 1, 3)
                
                -- If we have Tip the Scales active, use max empower
                if tipTheScalesActive then
                    empowerLevel = 3
                end
            else
                empowerLevel = settings.rotationSettings.spiritbloomLevel
            end
        end
        
        API.CastSpellOnUnitEmpowered(spells.SPIRITBLOOM, criticalTarget, empowerLevel)
        return true
    }
    
    -- Use Dream Breath if multiple critical targets
    if dreamBreath and 
       dreamBreathEmpowered and 
       API.CanCast(spells.DREAM_BREATH) and
       criticalHealthAllies >= 2 and
       settings.healingSettings.dreamBreathUsage == "Emergency AoE" and
       settings.abilityControls.dreamBreath.enabled then
        
        local empowerLevel = settings.abilityControls.dreamBreath.empowerLevel
        
        -- Adjust empower level based on settings and circumstances
        if settings.abilityControls.dreamBreath.autoEmpowerLevel then
            if settings.rotationSettings.empowerPreference == "Maximum Empower" then
                empowerLevel = 3
            elseif settings.rotationSettings.empowerPreference == "Fast Cast" then
                empowerLevel = 0
            elseif settings.rotationSettings.empowerPreference == "Situational" then
                -- Scale with target count
                empowerLevel = math.min(criticalHealthAllies - 1, 3)
                
                -- If we have Tip the Scales active, use max empower
                if tipTheScalesActive then
                    empowerLevel = 3
                end
            else
                empowerLevel = settings.rotationSettings.dreamBreathLevel
            end
        end
        
        API.CastSpellEmpowered(spells.DREAM_BREATH, empowerLevel)
        return true
    }
    
    -- Use Living Flame as an emergency heal
    if livingFlame and 
       API.CanCast(spells.LIVING_FLAME) and
       settings.rotationSettings.livingFlameUsage == "Emergency Heal" then
        API.CastSpellOnUnit(spells.LIVING_FLAME, criticalTarget)
        return true
    end
    
    return false
end

-- Handle group healing
function Preservation:HandleGroupHealing(settings)
    -- Use Dream Breath for group healing
    if dreamBreath and 
       dreamBreathEmpowered and 
       API.CanCast(spells.DREAM_BREATH) and
       lowHealthAllies >= settings.healingSettings.dreamBreathThreshold and
       settings.healingSettings.dreamBreathUsage ~= "Manual Only" and
       settings.abilityControls.dreamBreath.enabled then
        
        local empowerLevel = settings.abilityControls.dreamBreath.empowerLevel
        
        -- Adjust empower level based on settings and circumstances
        if settings.abilityControls.dreamBreath.autoEmpowerLevel then
            if settings.rotationSettings.empowerPreference == "Maximum Empower" then
                empowerLevel = 3
            elseif settings.rotationSettings.empowerPreference == "Fast Cast" then
                empowerLevel = 0
            elseif settings.rotationSettings.empowerPreference == "Situational" then
                -- Scale with target count
                empowerLevel = math.min(lowHealthAllies - 1, 3)
                
                -- If we have Tip the Scales active, use max empower
                if tipTheScalesActive then
                    empowerLevel = 3
                end
            else
                empowerLevel = settings.rotationSettings.dreamBreathLevel
            end
        end
        
        API.CastSpellEmpowered(spells.DREAM_BREATH, empowerLevel)
        return true
    }
    
    -- Use Emerald Breath for group healing
    if emeraldBreath and 
       emeraldBreathEmpowered and 
       API.CanCast(spells.EMERALD_BREATH) and
       lowHealthAllies >= settings.healingSettings.emeraldBreathThreshold and
       settings.healingSettings.emeraldBreathUsage ~= "Manual Only" and
       settings.abilityControls.emeraldBreath.enabled then
        
        local empowerLevel = settings.abilityControls.emeraldBreath.empowerLevel
        
        -- Adjust empower level based on settings and circumstances
        if settings.abilityControls.emeraldBreath.autoEmpowerLevel then
            if settings.rotationSettings.empowerPreference == "Maximum Empower" then
                empowerLevel = 3
            elseif settings.rotationSettings.empowerPreference == "Fast Cast" then
                empowerLevel = 0
            elseif settings.rotationSettings.empowerPreference == "Situational" then
                -- Scale with target count
                empowerLevel = math.min(lowHealthAllies - 1, 3)
                
                -- If we have Tip the Scales active, use max empower
                if tipTheScalesActive then
                    empowerLevel = 3
                end
            else
                empowerLevel = settings.rotationSettings.emeraldBreathLevel
            end
        end
        
        API.CastSpellEmpowered(spells.EMERALD_BREATH, empowerLevel)
        return true
    }
    
    -- Use Spiritbloom for group healing
    if spiritbloom and 
       spiritbloomEmpowered and 
       API.CanCast(spells.SPIRITBLOOM) and
       lowHealthAllies >= settings.healingSettings.spiritbloomThreshold and
       settings.healingSettings.spiritbloomUsage ~= "Manual Only" and
       settings.abilityControls.spiritbloom.enabled then
        
        local empowerLevel = settings.abilityControls.spiritbloom.empowerLevel
        
        -- Adjust empower level based on settings and circumstances
        if settings.abilityControls.spiritbloom.autoEmpowerLevel then
            if settings.rotationSettings.empowerPreference == "Maximum Empower" then
                empowerLevel = 3
            elseif settings.rotationSettings.empowerPreference == "Fast Cast" then
                empowerLevel = 0
            elseif settings.rotationSettings.empowerPreference == "Situational" then
                -- Scale with target count
                empowerLevel = math.min(lowHealthAllies - 1, 3)
                
                -- If we have Tip the Scales active, use max empower
                if tipTheScalesActive then
                    empowerLevel = 3
                end
            else
                empowerLevel = settings.rotationSettings.spiritbloomLevel
            end
        end
        
        -- Find a good target to center Spiritbloom on
        local target = nil
        local mostNearbyInjured = 0
        
        for i = 1, API.GetGroupSize() do
            local unit
            if API.IsInRaid() then
                unit = "raid" .. i
            else
                unit = i == 1 and "player" or "party" .. (i - 1)
            end
            
            if API.UnitExists(unit) and not API.UnitIsDead(unit) and API.GetUnitHealthPercent(unit) < 100 then
                local nearbyInjured = API.GetInjuredAlliesAroundUnit(unit, 10)
                if nearbyInjured > mostNearbyInjured then
                    mostNearbyInjured = nearbyInjured
                    target = unit
                end
            end
        end
        
        if target then
            API.CastSpellOnUnitEmpowered(spells.SPIRITBLOOM, target, empowerLevel)
            return true
        }
    }
    
    return false
end

-- Handle single target healing
function Preservation:HandleSingleTargetHealing(settings)
    -- Find the lowest health target
    local healTarget = nil
    local lowestHealth = 100
    
    for i = 1, API.GetGroupSize() do
        local unit
        if API.IsInRaid() then
            unit = "raid" .. i
        else
            unit = i == 1 and "player" or "party" .. (i - 1)
        end
        
        if API.UnitExists(unit) and not API.UnitIsDead(unit) then
            local health = API.GetUnitHealthPercent(unit)
            
            -- Prioritize tanks if tank priority is enabled
            if API.UnitIsTank(unit) and settings.abilityControls.reversion.tankPriority then
                health = health - 15 -- Artificial priority for tanks
            end
            
            if health < lowestHealth then
                lowestHealth = health
                healTarget = unit
            end
        end
    end
    
    -- No injured targets found
    if not healTarget or lowestHealth > 95 then
        return false
    end
    
    -- Use Verdant Embrace on low health targets or tanks
    if verdantEmbrace and 
       API.CanCast(spells.VERDANT_EMBRACE) and
       ((settings.healingSettings.verdantEmbraceUsage == "Low Health" and lowestHealth <= settings.healingSettings.healthThresholds.low) or
        (settings.healingSettings.verdantEmbraceUsage == "Tank Priority" and API.UnitIsTank(healTarget) and lowestHealth <= settings.healingSettings.healthThresholds.medium) or
        (settings.healingSettings.verdantEmbraceUsage == "On Cooldown" and lowestHealth <= settings.healingSettings.healthThresholds.medium)) then
        API.CastSpellOnUnit(spells.VERDANT_EMBRACE, healTarget)
        return true
    end
    
    -- Use Reversion for single target healing
    if reversion and 
       reversionEmpowered and 
       API.CanCast(spells.REVERSION) and
       ((settings.healingSettings.reversionUsage == "Low Health" and lowestHealth <= settings.healingSettings.healthThresholds.low) or
        (settings.healingSettings.reversionUsage == "Tank Priority" and API.UnitIsTank(healTarget) and lowestHealth <= settings.healingSettings.healthThresholds.medium) or
        (settings.healingSettings.reversionUsage == "On Cooldown" and lowestHealth <= settings.healingSettings.healthThresholds.medium)) and
       settings.abilityControls.reversion.enabled then
        
        local empowerLevel = settings.abilityControls.reversion.empowerLevel
        
        -- Adjust empower level based on settings and circumstances
        if settings.abilityControls.reversion.autoEmpowerLevel then
            if settings.rotationSettings.empowerPreference == "Maximum Empower" then
                empowerLevel = 3
            elseif settings.rotationSettings.empowerPreference == "Fast Cast" then
                empowerLevel = 0
            elseif settings.rotationSettings.empowerPreference == "Situational" then
                -- Adjust empower level based on target health
                if lowestHealth < settings.healingSettings.healthThresholds.critical then
                    empowerLevel = 2
                else
                    empowerLevel = 1
                end
                
                -- If we have Tip the Scales active, use max empower
                if tipTheScalesActive then
                    empowerLevel = 3
                end
            else
                empowerLevel = settings.rotationSettings.reversionLevel
            end
        end
        
        API.CastSpellOnUnitEmpowered(spells.REVERSION, healTarget, empowerLevel)
        return true
    end
    
    -- Use Living Flame for single target healing
    if livingFlame and 
       API.CanCast(spells.LIVING_FLAME) and
       (settings.rotationSettings.livingFlameUsage == "Healing Priority" or settings.rotationSettings.livingFlameUsage == "Emergency Heal") and
       lowestHealth <= settings.healingSettings.healthThresholds.medium then
        API.CastSpellOnUnit(spells.LIVING_FLAME, healTarget)
        return true
    end
    
    return false
end

-- Handle damage abilities
function Preservation:HandleDamage(settings)
    -- Check if we have enough mana and essence to DPS
    local canSpendMana = currentMana > settings.rotationSettings.manaSaveThreshold or 
                          settings.rotationSettings.manaManagement == "Aggressive"
    
    local canSpendEssence = currentEssence > settings.rotationSettings.conserveEssence or
                             settings.rotationSettings.essenceManagement == "Aggressive"
    
    -- Use Azure Strike
    if azureStrike and 
       API.CanCast(spells.AZURE_STRIKE) and 
       canSpendEssence then
        API.CastSpellOnUnit(spells.AZURE_STRIKE, "target")
        return true
    end
    
    -- Use Fire Breath in DPS downtime
    if fireBreath and 
       fireBreathEmpowered and 
       API.CanCast(spells.FIRE_BREATH) and 
       canSpendMana and
       canSpendEssence and
       activeEnemies >= 2 then
        API.CastSpellEmpowered(spells.FIRE_BREATH, 0) -- Use minimal empower for DPS
        return true
    end
    
    -- Use Disintegrate if talented
    if disintegrate and 
       API.CanCast(spells.DISINTEGRATE) and 
       canSpendMana and
       canSpendEssence then
        API.CastSpellOnUnit(spells.DISINTEGRATE, "target")
        return true
    end
    
    -- Use Living Flame for damage if appropriate
    if livingFlame and 
       API.CanCast(spells.LIVING_FLAME) and
       (settings.rotationSettings.livingFlameUsage == "Damage Only" or settings.rotationSettings.livingFlameUsage == "Essence Builder") and
       canSpendMana then
        API.CastSpellOnUnit(spells.LIVING_FLAME, "target")
        return true
    end
    
    return false
end

-- Handle specialization change
function Preservation:OnSpecializationChanged()
    -- Update talent information
    self:UpdateTalentInfo()
    
    -- Reset state variables
    nextCastOverride = nil
    burstModeActive = false
    currentMana = 100
    currentEssence = 0
    maxEssence = 6
    livingFlame = false
    fireBreath = false
    fireBreathEmpowered = false
    fireBreathActive = false
    fireBreathEndTime = 0
    emeraldBreath = false
    emeraldBreathEmpowered = false
    emeraldBreathActive = false
    emeraldBreathEndTime = 0
    azureStrike = false
    echoingVoid = false
    echoingVoidActive = false
    echoingVoidEndTime = 0
    dreamBreath = false
    dreamBreathEmpowered = false
    dreamBreathActive = false
    dreamBreathEndTime = 0
    disintegrate = false
    disintegrateActive = false
    disintegrateEndTime = 0
    reversion = false
    reversionEmpowered = false
    reversionActive = false
    reversionEndTime = 0
    spiritbloom = false
    spiritbloomEmpowered = false
    spiritbloomActive = false
    spiritbloomEndTime = 0
    verdantEmbrace = false
    verdantEmbraceActive = false
    verdantEmbraceEndTime = 0
    timeDilation = false
    tipTheScales = false
    tipTheScalesActive = false
    tipTheScalesEndTime = 0
    rewind = false
    rewindActive = false
    rewindCooldown = 0
    rewindEndTime = 0
    essenceBurst = false
    essenceBurstActive = false
    essenceBurstStacks = 0
    essenceBurstEndTime = 0
    temporalAnomaly = false
    temporalAnomalyActive = false
    temporalAnomalyEndTime = 0
    obsidianScales = false
    obsidianScalesActive = false
    obsidianScalesEndTime = 0
    cauterizingFlame = false
    hover = false
    tailSwipe = false
    wingBuffet = false
    emeraldCommunion = false
    emeraldCommunionActive = false
    emeraldCommunionEndTime = 0
    timeSpiral = false
    timeSpiralActive = false
    timeSpiralEndTime = 0
    renewingBlaze = false
    renewingBlazeActive = false
    renewingBlazeEndTime = 0
    renew = false
    renewActive = false
    renewEndTime = 0
    lifebind = false
    lifebindActive = false
    lifebindEndTime = 0
    resonatingPuddles = false
    resonatingPuddlesActive = false
    resonatingPuddlesEndTime = 0
    breathOfEons = false
    breathOfEonsActive = false
    breathOfEonsEndTime = 0
    flightOfTheDragon = false
    flightOfTheDragonActive = false
    flightOfTheDragonEndTime = 0
    callOfYsera = false
    callOfYseraActive = false
    callOfYseraEndTime = 0
    goldenHour = false
    goldenHourActive = false
    goldenHourEndTime = 0
    dreamflight = false
    dreamflightActive = false
    dreamflightEndTime = 0
    deluge = false
    essenceAttunement = false
    essenceAttunementActive = false
    essenceAttunementStacks = 0
    essenceAttunementEndTime = 0
    bountifulBloom = false
    bountifulBloomActive = false
    bountifulBloomEndTime = 0
    timeTender = false
    timeTenderActive = false
    timeTenderEndTime = 0
    ancientFlame = false
    ancientFlameActive = false
    ancientFlameEndTime = 0
    fieldOfDreams = false
    fieldOfDreamsActive = false
    fieldOfDreamsEndTime = 0
    lastLivingFlame = 0
    lastAzureStrike = 0
    lastFireBreath = 0
    lastDisintegrate = 0
    lastReversion = 0
    lastEmeraldBreath = 0
    lastDreamBreath = 0
    lastVerdantEmbrace = 0
    lastSpiritbloom = 0
    lastTimeDilation = 0
    lastTipTheScales = 0
    lastEmeraldCommunion = 0
    lastRewind = 0
    lastObsidianScales = 0
    lastCauterizingFlame = 0
    lastHover = 0
    lastTailSwipe = 0
    lastWingBuffet = 0
    lastEchoingVoid = 0
    lastRenewingBlaze = 0
    lastTimeSpiral = 0
    lastRenew = 0
    lastLifebind = 0
    lastFirebrand = 0
    lastBreathOfEons = 0
    lastDreamflight = 0
    lastFlightOfTheDragon = 0
    lastCallOfYsera = 0
    lastQuell = 0
    lastUnravel = 0
    lastSleepWalk = 0
    lastRescue = 0
    lastExpunge = 0
    playerHealth = 100
    targetHealth = 100
    activeEnemies = 0
    isInRange = false
    castingEmpoweredSpell = false
    lowHealthAllies = 0
    criticalHealthAllies = 0
    tankHealth = 100
    
    API.PrintDebug("Preservation Evoker state reset on spec change")
    
    return true
end

-- Return the module for loading
return Preservation