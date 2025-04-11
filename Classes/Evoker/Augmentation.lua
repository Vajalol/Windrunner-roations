------------------------------------------
-- WindrunnerRotations - Augmentation Evoker Module
-- Author: VortexQ8
-- The War Within Season 2
------------------------------------------

local Augmentation = {}
-- This will be assigned to addon.Classes.Evoker.Augmentation when loaded

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
local azureStrike = false
local disintegrate = false
local disintegrateActive = false
local disintegrateEndTime = 0
local bless = false
local blessActive = false
local blessEndTime = 0
local breath = false
local breathOfEons = false
local breathOfEonsActive = false
local breathOfEonsEndTime = 0
local ebon = false
local ebonMight = false
local ebonMightActive = false
local ebonMightEndTime = 0
local prescience = false
local prescienceActive = false
local prescienceEndTime = 0
local source = false
local sourceOfMagic = false
local sourceOfMagicActive = false
local sourceOfMagicEndTime = 0
local spiritbloom = false
local spiritbloomEmpowered = false
local spiritbloomActive = false
local spiritbloomEndTime = 0
local tipTheScales = false
local tipTheScalesActive = false
local tipTheScalesEndTime = 0
local timeSpiral = false
local timeSpiralActive = false
local timeSpiralEndTime = 0
local eruption = false
local upheavalActive = false
local upheavalEndTime = 0
local fontOfMagic = false
local fontOfMagicActive = false
local fontOfMagicEndTime = 0
local iridescenceBlue = false
local iridescenceRed = false
local iridescenceActive = false
local iridescenceEndTime = 0
local exhilarationActive = false
local exhilarationEndTime = 0
local infernalSkin = false
local infernalSkinActive = false
local infernalSkinEndTime = 0
local leapingFlames = false
local leapingFlamesActive = false
local leapingFlamesEndTime = 0
local obsidianScales = false
local obsidianScalesActive = false
local obsidianScalesEndTime = 0
local cauterizingFlame = false
local hover = false
local tailSwipe = false
local wingBuffet = false
local essenceBurst = false
local essenceBurstActive = false
local essenceBurstStacks = 0
local essenceBurstEndTime = 0
local temporal = false
local temporalCompression = false
local temporalCompressionActive = false
local temporalCompressionEndTime = 0
local timelessRenewal = false
local timelessRenewalActive = false
local timelessRenewalEndTime = 0
local powerInfusion = false
local blossoming = false
local blossomingActive = false
local blossomingEndTime = 0
local emeraldCommunion = false
local emeraldCommunionActive = false
local emeraldCommunionEndTime = 0
local bronzeFlight = false
local bronzeFlightActive = false
local bronzeFlightEndTime = 0
local renewingBlaze = false
local resonatingPuddles = false
local resonatingPuddlesActive = false
local resonatingPuddlesEndTime = 0
local evenHand = false
local evenHandActive = false
local evenHandEndTime = 0
local lastLivingFlame = 0
local lastAzureStrike = 0
local lastFireBreath = 0
local lastDisintegrate = 0
local lastBless = 0
local lastBreathOfEons = 0
local lastEbonMight = 0
local lastPrescience = 0
local lastSourceOfMagic = 0
local lastSpiritbloom = 0
local lastTipTheScales = 0
local lastTimeSpiral = 0
local lastUpheaval = 0
local lastObsidianScales = 0
local lastCauterizingFlame = 0
local lastHover = 0
local lastTailSwipe = 0
local lastWingBuffet = 0
local lastTemporalCompression = 0
local lastTimelessRenewal = 0
local lastEmeraldCommunion = 0
local lastBronzeFlight = 0
local lastFirebrand = 0
local lastQuell = 0
local lastUnravel = 0
local lastSleepWalk = 0
local lastRescue = 0
local lastExpunge = 0
local lastRenewingBlaze = 0
local playerHealth = 100
local targetHealth = 100
local activeEnemies = 0
local isInRange = false
local castingEmpoweredSpell = false
local targetInAzureStrike = false

-- Constants
local AUGMENTATION_SPEC_ID = 1473
local TIP_THE_SCALES_DURATION = 10.0 -- seconds
local ESSENCE_BURST_DURATION = 15.0 -- seconds
local FONT_OF_MAGIC_DURATION = 15.0 -- seconds
local OBSIDIAN_SCALES_DURATION = 8.0 -- seconds
local LEAPING_FLAMES_DURATION = 30.0 -- seconds
local EBON_MIGHT_DURATION = 12.0 -- seconds
local BREATH_OF_EONS_DURATION = 20.0 -- seconds
local PRESCIENCE_DURATION = 15.0 -- seconds
local SOURCE_OF_MAGIC_DURATION = 15.0 -- seconds
local TIME_SPIRAL_DURATION = 8.0 -- seconds
local UPHEAVAL_DURATION = 15.0 -- seconds
local INFERNAL_SKIN_DURATION = 15.0 -- seconds
local EXHILARATION_DURATION = 6.0 -- seconds
local BRONZE_FLIGHT_DURATION = 30.0 -- seconds
local BLOSSOMING_DURATION = 8.0 -- seconds
local EMERALD_COMMUNION_DURATION = 5.0 -- seconds
local TEMPORAL_COMPRESSION_DURATION = 30.0 -- seconds
local TIMELESS_RENEWAL_DURATION = 18.0 -- seconds
local RESONATING_PUDDLES_DURATION = 20.0 -- seconds
local EVEN_HAND_DURATION = 10.0 -- seconds

-- Initialize the Augmentation module
function Augmentation:Initialize()
    self:RegisterSpells()
    self:RegisterVariables()
    self:RegisterSettings()
    self:RegisterEvents()
    
    API.PrintDebug("Augmentation Evoker module initialized")
    
    return true
end

-- Register spell IDs
function Augmentation:RegisterSpells()
    -- Core abilities
    spells.LIVING_FLAME = 361469
    spells.FIRE_BREATH = 357208
    spells.AZURE_STRIKE = 362969
    spells.DISINTEGRATE = 356995
    spells.BLESS = 364343
    spells.BREATH_OF_EONS = 403631
    spells.EBON_MIGHT = 395152
    spells.PRESCIENCE = 409311
    spells.SOURCE_OF_MAGIC = 414339
    spells.SPIRITBLOOM = 367226
    spells.UPHEAVAL = 408092
    
    -- Core utility and defensive abilities
    spells.TIP_THE_SCALES = 370553
    spells.OBSIDIAN_SCALES = 363916
    spells.CAUTERIZING_FLAME = 374251
    spells.HOVER = 358267
    spells.TAIL_SWIPE = 368970
    spells.WING_BUFFET = 357214
    
    -- Augmentation specific tools
    spells.TIME_SPIRAL = 374968
    spells.BRONZE_FLIGHT = 414438
    spells.EMERALD_COMMUNION = 370960
    
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
    spells.ESSENCE_BURST = 392268
    spells.FONT_OF_MAGIC = 375783
    spells.INFERNAL_SKIN = 404696
    spells.LEAPING_FLAMES = 369939
    spells.EXHILARATION = 395296
    spells.TEMPORAL_COMPRESSION = 362877
    spells.TIMELESS_RENEWAL = 404977
    spells.POWER_INFUSION = 10060 -- Not native to Evoker but often used with them
    spells.BLOSSOMING = 378844
    spells.RESONATING_PUDDLES = 409031
    spells.IRIDESCENCE_BLUE = 386342
    spells.IRIDESCENCE_RED = 386344
    spells.EVEN_HAND = 404806
    
    -- War Within Season 2 specific
    spells.SPIRIT_BLOOM = 382731
    
    -- Buff IDs
    spells.TIP_THE_SCALES_BUFF = 370553
    spells.ESSENCE_BURST_BUFF = 392268
    spells.FONT_OF_MAGIC_BUFF = 375783
    spells.OBSIDIAN_SCALES_BUFF = 363916
    spells.LEAPING_FLAMES_BUFF = 369939
    spells.INFERNAL_SKIN_BUFF = 404696
    spells.EXHILARATION_BUFF = 395296
    spells.EBON_MIGHT_BUFF = 395152
    spells.BREATH_OF_EONS_BUFF = 403631
    spells.PRESCIENCE_BUFF = 409312
    spells.SOURCE_OF_MAGIC_BUFF = 414339
    spells.TIME_SPIRAL_BUFF = 374968
    spells.UPHEAVAL_BUFF = 408092
    spells.TEMPORAL_COMPRESSION_BUFF = 362877
    spells.TIMELESS_RENEWAL_BUFF = 404977
    spells.BRONZE_FLIGHT_BUFF = 414438
    spells.BLOSSOMING_BUFF = 378845
    spells.EMERALD_COMMUNION_BUFF = 370960
    spells.RESONATING_PUDDLES_BUFF = 409031
    spells.IRIDESCENCE_BLUE_BUFF = 386342
    spells.IRIDESCENCE_RED_BUFF = 386344
    spells.EVEN_HAND_BUFF = 404806
    
    -- Debuff IDs
    spells.DISINTEGRATE_DOT = 356995
    spells.FIRE_BREATH_DOT = 357209
    spells.FIREBRAND_DEBUFF = 374349
    
    -- Register all spells with the API tracking system
    for spellName, spellID in pairs(spells) do
        API.RegisterSpell(spellID)
    end
    
    -- Define aura tracking
    buffs.TIP_THE_SCALES = spells.TIP_THE_SCALES_BUFF
    buffs.ESSENCE_BURST = spells.ESSENCE_BURST_BUFF
    buffs.FONT_OF_MAGIC = spells.FONT_OF_MAGIC_BUFF
    buffs.OBSIDIAN_SCALES = spells.OBSIDIAN_SCALES_BUFF
    buffs.LEAPING_FLAMES = spells.LEAPING_FLAMES_BUFF
    buffs.INFERNAL_SKIN = spells.INFERNAL_SKIN_BUFF
    buffs.EXHILARATION = spells.EXHILARATION_BUFF
    buffs.EBON_MIGHT = spells.EBON_MIGHT_BUFF
    buffs.BREATH_OF_EONS = spells.BREATH_OF_EONS_BUFF
    buffs.PRESCIENCE = spells.PRESCIENCE_BUFF
    buffs.SOURCE_OF_MAGIC = spells.SOURCE_OF_MAGIC_BUFF
    buffs.TIME_SPIRAL = spells.TIME_SPIRAL_BUFF
    buffs.UPHEAVAL = spells.UPHEAVAL_BUFF
    buffs.TEMPORAL_COMPRESSION = spells.TEMPORAL_COMPRESSION_BUFF
    buffs.TIMELESS_RENEWAL = spells.TIMELESS_RENEWAL_BUFF
    buffs.BRONZE_FLIGHT = spells.BRONZE_FLIGHT_BUFF
    buffs.BLOSSOMING = spells.BLOSSOMING_BUFF
    buffs.EMERALD_COMMUNION = spells.EMERALD_COMMUNION_BUFF
    buffs.RESONATING_PUDDLES = spells.RESONATING_PUDDLES_BUFF
    buffs.IRIDESCENCE_BLUE = spells.IRIDESCENCE_BLUE_BUFF
    buffs.IRIDESCENCE_RED = spells.IRIDESCENCE_RED_BUFF
    buffs.EVEN_HAND = spells.EVEN_HAND_BUFF
    
    debuffs.DISINTEGRATE = spells.DISINTEGRATE_DOT
    debuffs.FIRE_BREATH = spells.FIRE_BREATH_DOT
    debuffs.FIREBRAND = spells.FIREBRAND_DEBUFF
    
    return true
end

-- Register variables to track
function Augmentation:RegisterVariables()
    -- Talent tracking
    talents.hasFontOfMagic = false
    talents.hasInfernalSkin = false
    talents.hasLeapingFlames = false
    talents.hasExhilaration = false
    talents.hasTemporalCompression = false
    talents.hasTimelessRenewal = false
    talents.hasPowerInfusion = false
    talents.hasBlossoming = false
    talents.hasResonatingPuddles = false
    talents.hasIridescence = false
    talents.hasEvenHand = false
    
    -- Initialize resources
    currentMana = API.GetPlayerManaPercentage() or 100
    currentEssence = API.GetPowerResource("essence") or 0
    maxEssence = 6 -- Default
    
    return true
end

-- Register spec-specific settings
function Augmentation:RegisterSettings()
    ConfigRegistry:RegisterSettings("AugmentationEvoker", {
        rotationSettings = {
            burstEnabled = {
                displayName = "Enable Burst Mode",
                description = "Use cooldowns and focus on burst support",
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
            empowerPreference = {
                displayName = "Empower Preference",
                description = "How to handle empowered spells",
                type = "dropdown",
                options = {"Maximum Empower", "Fast Cast", "Situational", "Manual Control"},
                default = "Situational"
            },
            fireBreathLevel = {
                displayName = "Fire Breath Empower Level",
                description = "Default empower level for Fire Breath (0-3)",
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
            ebonMightPriority = {
                displayName = "Ebon Might Priority",
                description = "Priority for Ebon Might application",
                type = "dropdown",
                options = {"On Cooldown", "Top DPS Only", "Self Only", "Manual Only"},
                default = "Top DPS Only"
            },
            presciencePriority = {
                displayName = "Prescience Priority",
                description = "Priority for Prescience application",
                type = "dropdown",
                options = {"On Cooldown", "Top DPS Only", "Self Only", "Manual Only"},
                default = "Top DPS Only"
            },
            sourceOfMagicPriority = {
                displayName = "Source of Magic Priority",
                description = "Priority for Source of Magic application",
                type = "dropdown",
                options = {"Healer Only", "Top Mana User", "Self Only", "Manual Only"},
                default = "Healer Only"
            },
            tipTheScalesUsage = {
                displayName = "Tip the Scales Usage",
                description = "When to use Tip the Scales",
                type = "dropdown",
                options = {"With Support Spells", "With Fire Breath", "With Spiritbloom", "Manual Only"},
                default = "With Support Spells"
            },
            livingFlameUsage = {
                displayName = "Living Flame Usage",
                description = "When to use Living Flame",
                type = "dropdown",
                options = {"Essence Builder", "Filler Only", "Never"},
                default = "Essence Builder"
            }
        },
        
        supportSettings = {
            ebonMightSettings = {
                displayName = "Ebon Might Settings",
                description = "Settings for Ebon Might usage",
                type = "group",
                settings = {
                    useOnMelee = {
                        displayName = "Use on Melee DPS",
                        description = "Prioritize Ebon Might on melee DPS",
                        type = "toggle",
                        default = true
                    },
                    useOnRanged = {
                        displayName = "Use on Ranged DPS",
                        description = "Prioritize Ebon Might on ranged DPS",
                        type = "toggle",
                        default = true
                    },
                    useOnTank = {
                        displayName = "Use on Tank",
                        description = "Use Ebon Might on tank when no DPS available",
                        type = "toggle",
                        default = false
                    }
                }
            },
            prescienceSettings = {
                displayName = "Prescience Settings",
                description = "Settings for Prescience usage",
                type = "group",
                settings = {
                    useOnMelee = {
                        displayName = "Use on Melee DPS",
                        description = "Prioritize Prescience on melee DPS",
                        type = "toggle",
                        default = true
                    },
                    useOnRanged = {
                        displayName = "Use on Ranged DPS",
                        description = "Prioritize Prescience on ranged DPS",
                        type = "toggle",
                        default = true
                    },
                    useOnTank = {
                        displayName = "Use on Tank",
                        description = "Use Prescience on tank when no DPS available",
                        type = "toggle",
                        default = false
                    }
                }
            },
            breathOfEonsSettings = {
                displayName = "Breath of Eons Settings",
                description = "Settings for Breath of Eons usage",
                type = "group",
                settings = {
                    useOnCooldown = {
                        displayName = "Use on Cooldown",
                        description = "Use Breath of Eons on cooldown",
                        type = "toggle",
                        default = true
                    },
                    minTargets = {
                        displayName = "Minimum Targets",
                        description = "Minimum number of targets to use Breath of Eons",
                        type = "slider",
                        min = 1,
                        max = 5,
                        default = 3
                    },
                    saveForBurst = {
                        displayName = "Save for Burst",
                        description = "Save Breath of Eons for burst phases",
                        type = "toggle",
                        default = false
                    }
                }
            },
            bronzeFlightUsage = {
                displayName = "Bronze Flight Usage",
                description = "When to use Bronze Flight",
                type = "dropdown",
                options = {"On Cooldown", "With Cooldowns", "Manual Only"},
                default = "With Cooldowns"
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
            -- Fire Breath controls
            fireBreath = AAC.RegisterAbility(spells.FIRE_BREATH, {
                enabled = true,
                useDuringBurstOnly = false,
                empowerLevel = 1,
                autoEmpowerLevel = true
            }),
            
            -- Ebon Might controls
            ebonMight = AAC.RegisterAbility(spells.EBON_MIGHT, {
                enabled = true,
                useDuringBurstOnly = false,
                targetPriority = "TopDPS",
                refreshThreshold = 3
            }),
            
            -- Prescience controls
            prescience = AAC.RegisterAbility(spells.PRESCIENCE, {
                enabled = true,
                useDuringBurstOnly = false,
                targetPriority = "TopDPS",
                refreshThreshold = 3
            })
        }
    })
    
    return true
end

-- Register for events 
function Augmentation:RegisterEvents()
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
function Augmentation:UpdateTalentInfo()
    -- Check for important talents
    talents.hasFontOfMagic = API.HasTalent(spells.FONT_OF_MAGIC)
    talents.hasInfernalSkin = API.HasTalent(spells.INFERNAL_SKIN)
    talents.hasLeapingFlames = API.HasTalent(spells.LEAPING_FLAMES)
    talents.hasExhilaration = API.HasTalent(spells.EXHILARATION)
    talents.hasTemporalCompression = API.HasTalent(spells.TEMPORAL_COMPRESSION)
    talents.hasTimelessRenewal = API.HasTalent(spells.TIMELESS_RENEWAL)
    talents.hasPowerInfusion = API.HasTalent(spells.POWER_INFUSION)
    talents.hasBlossoming = API.HasTalent(spells.BLOSSOMING)
    talents.hasResonatingPuddles = API.HasTalent(spells.RESONATING_PUDDLES)
    talents.hasIridescence = API.HasTalent(spells.IRIDESCENCE_BLUE) or API.HasTalent(spells.IRIDESCENCE_RED)
    talents.hasEvenHand = API.HasTalent(spells.EVEN_HAND)
    
    -- Set specialized variables based on talents
    if talents.hasFontOfMagic then
        fontOfMagic = true
    end
    
    if talents.hasInfernalSkin then
        infernalSkin = true
    end
    
    if talents.hasLeapingFlames then
        leapingFlames = true
    end
    
    if talents.hasExhilaration then
        exhilaration = true
    end
    
    if talents.hasTemporalCompression then
        temporal = true
        temporalCompression = true
    end
    
    if talents.hasTimelessRenewal then
        timelessRenewal = true
    end
    
    if talents.hasPowerInfusion then
        powerInfusion = true
    end
    
    if talents.hasBlossoming then
        blossoming = true
    end
    
    if talents.hasResonatingPuddles then
        resonatingPuddles = true
    end
    
    if talents.hasIridescence then
        if API.HasTalent(spells.IRIDESCENCE_BLUE) then
            iridescenceBlue = true
        end
        
        if API.HasTalent(spells.IRIDESCENCE_RED) then
            iridescenceRed = true
        end
    end
    
    if talents.hasEvenHand then
        evenHand = true
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
    
    if API.IsSpellKnown(spells.BLESS) then
        bless = true
    end
    
    if API.IsSpellKnown(spells.BREATH_OF_EONS) then
        breath = true
        breathOfEons = true
    end
    
    if API.IsSpellKnown(spells.EBON_MIGHT) then
        ebon = true
        ebonMight = true
    end
    
    if API.IsSpellKnown(spells.PRESCIENCE) then
        prescience = true
    end
    
    if API.IsSpellKnown(spells.SOURCE_OF_MAGIC) then
        source = true
        sourceOfMagic = true
    end
    
    if API.IsSpellKnown(spells.SPIRITBLOOM) then
        spiritbloom = true
        spiritbloomEmpowered = true
    end
    
    if API.IsSpellKnown(spells.UPHEAVAL) then
        eruption = true
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
    
    if API.IsSpellKnown(spells.BRONZE_FLIGHT) then
        bronzeFlight = true
    end
    
    if API.IsSpellKnown(spells.EMERALD_COMMUNION) then
        emeraldCommunion = true
    end
    
    if API.IsSpellKnown(spells.RENEWING_BLAZE) then
        renewingBlaze = true
    end
    
    API.PrintDebug("Augmentation Evoker talents updated")
    
    return true
end

-- Update mana tracking
function Augmentation:UpdateMana()
    currentMana = API.GetPlayerManaPercentage()
    return true
end

-- Update essence tracking
function Augmentation:UpdateEssence()
    currentEssence = API.GetPowerResource("essence") or 0
    return true
end

-- Update health tracking
function Augmentation:UpdateHealth()
    playerHealth = API.GetPlayerHealthPercent()
    return true
end

-- Update target health tracking
function Augmentation:UpdateTargetHealth()
    targetHealth = API.GetTargetHealthPercent()
    return true
end

-- Update active enemy counts
function Augmentation:UpdateEnemyCounts()
    activeEnemies = API.GetEnemyCount() or 0
    return true
end

-- Handle spell channel start
function Augmentation:HandleSpellChannelStart(spellID)
    if spellID == spells.DISINTEGRATE then
        disintegrateActive = true
        disintegrateEndTime = GetTime() + 3.0 -- Approximate channel duration
        API.PrintDebug("Disintegrate channel started")
    end
    
    return true
end

-- Handle empowered spell start
function Augmentation:HandleEmpowerStart(spellID)
    castingEmpoweredSpell = true
    
    if spellID == spells.FIRE_BREATH then
        fireBreathActive = true
        API.PrintDebug("Fire Breath empowering started")
    elseif spellID == spells.SPIRITBLOOM then
        spiritbloomActive = true
        API.PrintDebug("Spiritbloom empowering started")
    end
    
    return true
end

-- Handle empowered spell stop
function Augmentation:HandleEmpowerStop(spellID)
    castingEmpoweredSpell = false
    
    if spellID == spells.FIRE_BREATH then
        fireBreathActive = false
        fireBreathEndTime = GetTime() + 15.0 -- DoT duration (approximate)
        API.PrintDebug("Fire Breath cast")
    elseif spellID == spells.SPIRITBLOOM then
        spiritbloomActive = false
        spiritbloomEndTime = GetTime() + 8.0 -- Effect duration (approximate)
        API.PrintDebug("Spiritbloom cast")
    end
    
    return true
end

-- Handle combat log events
function Augmentation:HandleCombatLogEvent(...)
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
            
            -- Track Font of Magic application
            if spellID == buffs.FONT_OF_MAGIC then
                fontOfMagicActive = true
                fontOfMagicEndTime = select(6, API.GetBuffInfo("player", buffs.FONT_OF_MAGIC))
                API.PrintDebug("Font of Magic activated")
            end
            
            -- Track Obsidian Scales application
            if spellID == buffs.OBSIDIAN_SCALES then
                obsidianScalesActive = true
                obsidianScalesEndTime = select(6, API.GetBuffInfo("player", buffs.OBSIDIAN_SCALES))
                API.PrintDebug("Obsidian Scales activated")
            end
            
            -- Track Leaping Flames application
            if spellID == buffs.LEAPING_FLAMES then
                leapingFlamesActive = true
                leapingFlamesEndTime = select(6, API.GetBuffInfo("player", buffs.LEAPING_FLAMES))
                API.PrintDebug("Leaping Flames activated")
            end
            
            -- Track Infernal Skin application
            if spellID == buffs.INFERNAL_SKIN then
                infernalSkinActive = true
                infernalSkinEndTime = select(6, API.GetBuffInfo("player", buffs.INFERNAL_SKIN))
                API.PrintDebug("Infernal Skin activated")
            end
            
            -- Track Exhilaration application
            if spellID == buffs.EXHILARATION then
                exhilarationActive = true
                exhilarationEndTime = select(6, API.GetBuffInfo("player", buffs.EXHILARATION))
                API.PrintDebug("Exhilaration activated")
            end
            
            -- Track Time Spiral application
            if spellID == buffs.TIME_SPIRAL then
                timeSpiralActive = true
                timeSpiralEndTime = select(6, API.GetBuffInfo("player", buffs.TIME_SPIRAL))
                API.PrintDebug("Time Spiral activated")
            end
            
            -- Track Temporal Compression application
            if spellID == buffs.TEMPORAL_COMPRESSION then
                temporalCompressionActive = true
                temporalCompressionEndTime = select(6, API.GetBuffInfo("player", buffs.TEMPORAL_COMPRESSION))
                API.PrintDebug("Temporal Compression activated")
            end
            
            -- Track Timeless Renewal application
            if spellID == buffs.TIMELESS_RENEWAL then
                timelessRenewalActive = true
                timelessRenewalEndTime = select(6, API.GetBuffInfo("player", buffs.TIMELESS_RENEWAL))
                API.PrintDebug("Timeless Renewal activated")
            end
            
            -- Track Bronze Flight application
            if spellID == buffs.BRONZE_FLIGHT then
                bronzeFlightActive = true
                bronzeFlightEndTime = select(6, API.GetBuffInfo("player", buffs.BRONZE_FLIGHT))
                API.PrintDebug("Bronze Flight activated")
            end
            
            -- Track Blossoming application
            if spellID == buffs.BLOSSOMING then
                blossomingActive = true
                blossomingEndTime = select(6, API.GetBuffInfo("player", buffs.BLOSSOMING))
                API.PrintDebug("Blossoming activated")
            end
            
            -- Track Emerald Communion application
            if spellID == buffs.EMERALD_COMMUNION then
                emeraldCommunionActive = true
                emeraldCommunionEndTime = select(6, API.GetBuffInfo("player", buffs.EMERALD_COMMUNION))
                API.PrintDebug("Emerald Communion activated")
            end
            
            -- Track Resonating Puddles application
            if spellID == buffs.RESONATING_PUDDLES then
                resonatingPuddlesActive = true
                resonatingPuddlesEndTime = select(6, API.GetBuffInfo("player", buffs.RESONATING_PUDDLES))
                API.PrintDebug("Resonating Puddles activated")
            end
            
            -- Track Iridescence application
            if spellID == buffs.IRIDESCENCE_BLUE or spellID == buffs.IRIDESCENCE_RED then
                iridescenceActive = true
                iridescenceEndTime = select(6, API.GetBuffInfo("player", spellID))
                API.PrintDebug("Iridescence activated")
            end
            
            -- Track Even Hand application
            if spellID == buffs.EVEN_HAND then
                evenHandActive = true
                evenHandEndTime = select(6, API.GetBuffInfo("player", buffs.EVEN_HAND))
                API.PrintDebug("Even Hand activated")
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
            
            -- Track Font of Magic removal
            if spellID == buffs.FONT_OF_MAGIC then
                fontOfMagicActive = false
                API.PrintDebug("Font of Magic faded")
            end
            
            -- Track Obsidian Scales removal
            if spellID == buffs.OBSIDIAN_SCALES then
                obsidianScalesActive = false
                API.PrintDebug("Obsidian Scales faded")
            end
            
            -- Track Leaping Flames removal
            if spellID == buffs.LEAPING_FLAMES then
                leapingFlamesActive = false
                API.PrintDebug("Leaping Flames faded")
            end
            
            -- Track Infernal Skin removal
            if spellID == buffs.INFERNAL_SKIN then
                infernalSkinActive = false
                API.PrintDebug("Infernal Skin faded")
            end
            
            -- Track Exhilaration removal
            if spellID == buffs.EXHILARATION then
                exhilarationActive = false
                API.PrintDebug("Exhilaration faded")
            end
            
            -- Track Time Spiral removal
            if spellID == buffs.TIME_SPIRAL then
                timeSpiralActive = false
                API.PrintDebug("Time Spiral faded")
            end
            
            -- Track Temporal Compression removal
            if spellID == buffs.TEMPORAL_COMPRESSION then
                temporalCompressionActive = false
                API.PrintDebug("Temporal Compression faded")
            end
            
            -- Track Timeless Renewal removal
            if spellID == buffs.TIMELESS_RENEWAL then
                timelessRenewalActive = false
                API.PrintDebug("Timeless Renewal faded")
            end
            
            -- Track Bronze Flight removal
            if spellID == buffs.BRONZE_FLIGHT then
                bronzeFlightActive = false
                API.PrintDebug("Bronze Flight faded")
            end
            
            -- Track Blossoming removal
            if spellID == buffs.BLOSSOMING then
                blossomingActive = false
                API.PrintDebug("Blossoming faded")
            end
            
            -- Track Emerald Communion removal
            if spellID == buffs.EMERALD_COMMUNION then
                emeraldCommunionActive = false
                API.PrintDebug("Emerald Communion faded")
            end
            
            -- Track Resonating Puddles removal
            if spellID == buffs.RESONATING_PUDDLES then
                resonatingPuddlesActive = false
                API.PrintDebug("Resonating Puddles faded")
            end
            
            -- Track Iridescence removal
            if spellID == buffs.IRIDESCENCE_BLUE or spellID == buffs.IRIDESCENCE_RED then
                iridescenceActive = false
                API.PrintDebug("Iridescence faded")
            end
            
            -- Track Even Hand removal
            if spellID == buffs.EVEN_HAND then
                evenHandActive = false
                API.PrintDebug("Even Hand faded")
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
            elseif spellID == spells.BLESS then
                lastBless = GetTime()
                blessActive = true
                blessEndTime = GetTime() + 10.0 -- Effect duration (approximate)
                API.PrintDebug("Bless cast")
            elseif spellID == spells.BREATH_OF_EONS then
                lastBreathOfEons = GetTime()
                breathOfEonsActive = true
                breathOfEonsEndTime = GetTime() + BREATH_OF_EONS_DURATION
                API.PrintDebug("Breath of Eons cast")
            elseif spellID == spells.EBON_MIGHT then
                lastEbonMight = GetTime()
                ebonMightActive = true
                ebonMightEndTime = GetTime() + EBON_MIGHT_DURATION
                API.PrintDebug("Ebon Might cast")
            elseif spellID == spells.PRESCIENCE then
                lastPrescience = GetTime()
                prescienceActive = true
                prescienceEndTime = GetTime() + PRESCIENCE_DURATION
                API.PrintDebug("Prescience cast")
            elseif spellID == spells.SOURCE_OF_MAGIC then
                lastSourceOfMagic = GetTime()
                sourceOfMagicActive = true
                sourceOfMagicEndTime = GetTime() + SOURCE_OF_MAGIC_DURATION
                API.PrintDebug("Source of Magic cast")
            elseif spellID == spells.UPHEAVAL then
                lastUpheaval = GetTime()
                upheavalActive = true
                upheavalEndTime = GetTime() + UPHEAVAL_DURATION
                API.PrintDebug("Upheaval cast")
            elseif spellID == spells.TIP_THE_SCALES then
                lastTipTheScales = GetTime()
                tipTheScalesActive = true
                tipTheScalesEndTime = GetTime() + TIP_THE_SCALES_DURATION
                API.PrintDebug("Tip the Scales cast")
            elseif spellID == spells.TIME_SPIRAL then
                lastTimeSpiral = GetTime()
                timeSpiralActive = true
                timeSpiralEndTime = GetTime() + TIME_SPIRAL_DURATION
                API.PrintDebug("Time Spiral cast")
            elseif spellID == spells.TEMPORAL_COMPRESSION then
                lastTemporalCompression = GetTime()
                temporalCompressionActive = true
                temporalCompressionEndTime = GetTime() + TEMPORAL_COMPRESSION_DURATION
                API.PrintDebug("Temporal Compression cast")
            elseif spellID == spells.TIMELESS_RENEWAL then
                lastTimelessRenewal = GetTime()
                timelessRenewalActive = true
                timelessRenewalEndTime = GetTime() + TIMELESS_RENEWAL_DURATION
                API.PrintDebug("Timeless Renewal cast")
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
            elseif spellID == spells.EMERALD_COMMUNION then
                lastEmeraldCommunion = GetTime()
                emeraldCommunionActive = true
                emeraldCommunionEndTime = GetTime() + EMERALD_COMMUNION_DURATION
                API.PrintDebug("Emerald Communion cast")
            elseif spellID == spells.BRONZE_FLIGHT then
                lastBronzeFlight = GetTime()
                bronzeFlightActive = true
                bronzeFlightEndTime = GetTime() + BRONZE_FLIGHT_DURATION
                API.PrintDebug("Bronze Flight cast")
            elseif spellID == spells.FIREBRAND then
                lastFirebrand = GetTime()
                API.PrintDebug("Firebrand cast")
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
            elseif spellID == spells.RENEWING_BLAZE then
                lastRenewingBlaze = GetTime()
                API.PrintDebug("Renewing Blaze cast")
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
        end
    end
    
    -- Track buff applications on other players from the player
    if sourceGUID == API.GetPlayerGUID() and destGUID ~= API.GetPlayerGUID() then
        if eventType == "SPELL_AURA_APPLIED" or eventType == "SPELL_AURA_REFRESH" then
            -- Track Ebon Might application
            if spellID == buffs.EBON_MIGHT then
                API.PrintDebug("Ebon Might applied to " .. destName)
            end
            
            -- Track Prescience application
            if spellID == buffs.PRESCIENCE then
                API.PrintDebug("Prescience applied to " .. destName)
            end
            
            -- Track Source of Magic application
            if spellID == buffs.SOURCE_OF_MAGIC then
                API.PrintDebug("Source of Magic applied to " .. destName)
            end
            
            -- Track Breath of Eons application
            if spellID == buffs.BREATH_OF_EONS then
                API.PrintDebug("Breath of Eons applied to " .. destName)
            end
        end
        
        -- Track buff removals from other players
        if eventType == "SPELL_AURA_REMOVED" then
            -- Track Ebon Might removal
            if spellID == buffs.EBON_MIGHT then
                API.PrintDebug("Ebon Might faded from " .. destName)
            end
            
            -- Track Prescience removal
            if spellID == buffs.PRESCIENCE then
                API.PrintDebug("Prescience faded from " .. destName)
            end
            
            -- Track Source of Magic removal
            if spellID == buffs.SOURCE_OF_MAGIC then
                API.PrintDebug("Source of Magic faded from " .. destName)
            end
            
            -- Track Breath of Eons removal
            if spellID == buffs.BREATH_OF_EONS then
                API.PrintDebug("Breath of Eons faded from " .. destName)
            end
        end
    }
    
    return true
end

-- Main rotation function
function Augmentation:RunRotation()
    -- Check if we should be running Augmentation Evoker logic
    if API.GetActiveSpecID() ~= AUGMENTATION_SPEC_ID then
        return false
    end
    
    -- Skip rotation if player is casting or empowering
    if API.IsPlayerCasting() or castingEmpoweredSpell then
        return false
    end
    
    -- Get settings
    local settings = ConfigRegistry:GetSettings("AugmentationEvoker")
    
    -- Update variables
    self:UpdateEssence()
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
    
    -- Handle support abilities
    if self:HandleSupportAbilities(settings) then
        return true
    }
    
    -- Handle damage abilities if we have a valid target
    if API.UnitExists("target") and API.IsUnitEnemy("target") and isInRange then
        if activeEnemies >= settings.rotationSettings.aoeThreshold and settings.rotationSettings.aoeEnabled then
            return self:HandleAoE(settings)
        else
            return self:HandleSingleTarget(settings)
        end
    }
    
    return false
end

-- Handle defensive cooldowns
function Augmentation:HandleDefensives(settings)
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
function Augmentation:HandleInterrupts(settings)
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
    
    -- Use Tip the Scales
    if tipTheScales and 
       API.CanCast(spells.TIP_THE_SCALES) and
       settings.rotationSettings.tipTheScalesUsage ~= "Manual Only" then
        
        local shouldUseTipTheScales = false
        local nextSpell = nil
        
        if settings.rotationSettings.tipTheScalesUsage == "With Support Spells" then
            if ebonMight and API.GetSpellCooldown(spells.EBON_MIGHT) <= 0 then
                shouldUseTipTheScales = true
                nextSpell = spells.EBON_MIGHT
            elseif breathOfEons and API.GetSpellCooldown(spells.BREATH_OF_EONS) <= 0 then
                shouldUseTipTheScales = true
                nextSpell = spells.BREATH_OF_EONS
            end
        elseif settings.rotationSettings.tipTheScalesUsage == "With Fire Breath" and
               fireBreath and API.GetSpellCooldown(spells.FIRE_BREATH) <= 0 then
            shouldUseTipTheScales = true
            nextSpell = spells.FIRE_BREATH
        elseif settings.rotationSettings.tipTheScalesUsage == "With Spiritbloom" and
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
    
    return false
end

-- Handle support abilities
function Augmentation:HandleSupportAbilities(settings)
    -- Use Ebon Might on appropriate target
    if ebonMight and 
       API.CanCast(spells.EBON_MIGHT) and
       settings.rotationSettings.ebonMightPriority ~= "Manual Only" and
       settings.abilityControls.ebonMight.enabled then
        
        local shouldCast = false
        local target = nil
        
        if settings.rotationSettings.ebonMightPriority == "On Cooldown" then
            shouldCast = true
            
            -- Find the best target based on settings
            local bestDpsScore = 0
            
            for i = 1, API.GetGroupSize() do
                local unit
                if API.IsInRaid() then
                    unit = "raid" .. i
                else
                    unit = i == 1 and "player" or "party" .. (i - 1)
                end
                
                if API.UnitExists(unit) and not API.UnitIsDead(unit) and API.IsUnitInRange(unit, 40) then
                    local isMelee = API.UnitIsMelee(unit)
                    local isRanged = API.UnitIsRanged(unit)
                    local isTank = API.UnitIsTank(unit)
                    local isHealer = API.UnitIsHealer(unit)
                    local dpsScore = 0
                    
                    -- Score unit based on role and settings
                    if isMelee and not isHealer and settings.supportSettings.ebonMightSettings.useOnMelee then
                        dpsScore = 100
                    elseif isRanged and not isHealer and settings.supportSettings.ebonMightSettings.useOnRanged then
                        dpsScore = 90
                    elseif isTank and settings.supportSettings.ebonMightSettings.useOnTank then
                        dpsScore = 50
                    elseif unit == "player" then
                        dpsScore = 40
                    end
                    
                    -- Check if unit already has the buff
                    if API.UnitHasBuff(unit, buffs.EBON_MIGHT) then
                        local remaining = select(5, API.GetBuffInfo(unit, buffs.EBON_MIGHT))
                        if remaining and remaining > settings.abilityControls.ebonMight.refreshThreshold then
                            dpsScore = 0
                        end
                    end
                    
                    -- Update best target
                    if dpsScore > bestDpsScore then
                        bestDpsScore = dpsScore
                        target = unit
                    end
                end
            end
        elseif settings.rotationSettings.ebonMightPriority == "Top DPS Only" then
            -- Find the top DPS player
            local topDPS = API.GetTopDPSUnit()
            if topDPS and API.IsUnitInRange(topDPS, 40) then
                local remaining = 0
                if API.UnitHasBuff(topDPS, buffs.EBON_MIGHT) then
                    remaining = select(5, API.GetBuffInfo(topDPS, buffs.EBON_MIGHT)) or 0
                end
                
                if remaining <= settings.abilityControls.ebonMight.refreshThreshold then
                    shouldCast = true
                    target = topDPS
                end
            }
        elseif settings.rotationSettings.ebonMightPriority == "Self Only" then
            local remaining = 0
            if API.UnitHasBuff("player", buffs.EBON_MIGHT) then
                remaining = select(5, API.GetBuffInfo("player", buffs.EBON_MIGHT)) or 0
            end
            
            if remaining <= settings.abilityControls.ebonMight.refreshThreshold then
                shouldCast = true
                target = "player"
            end
        end
        
        if shouldCast and target then
            API.CastSpellOnUnit(spells.EBON_MIGHT, target)
            return true
        end
    end
    
    -- Use Prescience on appropriate target
    if prescience and 
       API.CanCast(spells.PRESCIENCE) and
       settings.rotationSettings.presciencePriority ~= "Manual Only" and
       settings.abilityControls.prescience.enabled then
        
        local shouldCast = false
        local target = nil
        
        if settings.rotationSettings.presciencePriority == "On Cooldown" then
            shouldCast = true
            
            -- Find the best target based on settings
            local bestDpsScore = 0
            
            for i = 1, API.GetGroupSize() do
                local unit
                if API.IsInRaid() then
                    unit = "raid" .. i
                else
                    unit = i == 1 and "player" or "party" .. (i - 1)
                end
                
                if API.UnitExists(unit) and not API.UnitIsDead(unit) and API.IsUnitInRange(unit, 40) then
                    local isMelee = API.UnitIsMelee(unit)
                    local isRanged = API.UnitIsRanged(unit)
                    local isTank = API.UnitIsTank(unit)
                    local isHealer = API.UnitIsHealer(unit)
                    local dpsScore = 0
                    
                    -- Score unit based on role and settings
                    if isMelee and not isHealer and settings.supportSettings.prescienceSettings.useOnMelee then
                        dpsScore = 100
                    elseif isRanged and not isHealer and settings.supportSettings.prescienceSettings.useOnRanged then
                        dpsScore = 90
                    elseif isTank and settings.supportSettings.prescienceSettings.useOnTank then
                        dpsScore = 50
                    elseif unit == "player" then
                        dpsScore = 40
                    end
                    
                    -- Check if unit already has the buff
                    if API.UnitHasBuff(unit, buffs.PRESCIENCE) then
                        local remaining = select(5, API.GetBuffInfo(unit, buffs.PRESCIENCE))
                        if remaining and remaining > settings.abilityControls.prescience.refreshThreshold then
                            dpsScore = 0
                        end
                    end
                    
                    -- Update best target
                    if dpsScore > bestDpsScore then
                        bestDpsScore = dpsScore
                        target = unit
                    end
                end
            end
        elseif settings.rotationSettings.presciencePriority == "Top DPS Only" then
            -- Find the top DPS player
            local topDPS = API.GetTopDPSUnit()
            if topDPS and API.IsUnitInRange(topDPS, 40) then
                local remaining = 0
                if API.UnitHasBuff(topDPS, buffs.PRESCIENCE) then
                    remaining = select(5, API.GetBuffInfo(topDPS, buffs.PRESCIENCE)) or 0
                end
                
                if remaining <= settings.abilityControls.prescience.refreshThreshold then
                    shouldCast = true
                    target = topDPS
                end
            }
        elseif settings.rotationSettings.presciencePriority == "Self Only" then
            local remaining = 0
            if API.UnitHasBuff("player", buffs.PRESCIENCE) then
                remaining = select(5, API.GetBuffInfo("player", buffs.PRESCIENCE)) or 0
            end
            
            if remaining <= settings.abilityControls.prescience.refreshThreshold then
                shouldCast = true
                target = "player"
            end
        end
        
        if shouldCast and target then
            API.CastSpellOnUnit(spells.PRESCIENCE, target)
            return true
        end
    end
    
    -- Use Source of Magic on appropriate target
    if sourceOfMagic and 
       API.CanCast(spells.SOURCE_OF_MAGIC) and
       settings.rotationSettings.sourceOfMagicPriority ~= "Manual Only" then
        
        local shouldCast = false
        local target = nil
        
        if settings.rotationSettings.sourceOfMagicPriority == "Healer Only" then
            -- Find a healer
            for i = 1, API.GetGroupSize() do
                local unit
                if API.IsInRaid() then
                    unit = "raid" .. i
                else
                    unit = i == 1 and "player" or "party" .. (i - 1)
                end
                
                if API.UnitExists(unit) and not API.UnitIsDead(unit) and API.IsUnitInRange(unit, 40) and API.UnitIsHealer(unit) then
                    local hasSourceOfMagic = API.UnitHasBuff(unit, buffs.SOURCE_OF_MAGIC)
                    if not hasSourceOfMagic then
                        shouldCast = true
                        target = unit
                        break
                    end
                end
            end
        elseif settings.rotationSettings.sourceOfMagicPriority == "Top Mana User" then
            -- Find the player with the highest mana usage
            local bestManaScore = 0
            
            for i = 1, API.GetGroupSize() do
                local unit
                if API.IsInRaid() then
                    unit = "raid" .. i
                else
                    unit = i == 1 and "player" or "party" .. (i - 1)
                end
                
                if API.UnitExists(unit) and not API.UnitIsDead(unit) and API.IsUnitInRange(unit, 40) and API.UnitUsesMana(unit) then
                    local hasSourceOfMagic = API.UnitHasBuff(unit, buffs.SOURCE_OF_MAGIC)
                    if not hasSourceOfMagic then
                        local isHealer = API.UnitIsHealer(unit)
                        local isSpellcaster = API.UnitIsSpellcaster(unit)
                        local manaScore = 0
                        
                        if isHealer then
                            manaScore = 100
                        elseif isSpellcaster then
                            manaScore = 80
                        else
                            manaScore = 10
                        end
                        
                        if manaScore > bestManaScore then
                            bestManaScore = manaScore
                            target = unit
                        end
                    end
                end
            end
            
            if target then
                shouldCast = true
            end
        elseif settings.rotationSettings.sourceOfMagicPriority == "Self Only" then
            local hasSourceOfMagic = API.UnitHasBuff("player", buffs.SOURCE_OF_MAGIC)
            if not hasSourceOfMagic then
                shouldCast = true
                target = "player"
            end
        end
        
        if shouldCast and target then
            API.CastSpellOnUnit(spells.SOURCE_OF_MAGIC, target)
            return true
        end
    end
    
    -- Use Breath of Eons when appropriate
    if breathOfEons and 
       API.CanCast(spells.BREATH_OF_EONS) then
        
        local shouldUseBreathOfEons = false
        
        if settings.supportSettings.breathOfEonsSettings.useOnCooldown then
            shouldUseBreathOfEons = true
        else
            -- Count party members in range
            local partySizeInRange = 0
            
            for i = 1, API.GetGroupSize() do
                local unit
                if API.IsInRaid() then
                    unit = "raid" .. i
                else
                    unit = i == 1 and "player" or "party" .. (i - 1)
                end
                
                if API.UnitExists(unit) and not API.UnitIsDead(unit) and API.IsUnitInRange(unit, 40) then
                    partySizeInRange = partySizeInRange + 1
                end
            end
            
            if partySizeInRange >= settings.supportSettings.breathOfEonsSettings.minTargets then
                if not settings.supportSettings.breathOfEonsSettings.saveForBurst or burstModeActive then
                    shouldUseBreathOfEons = true
                end
            end
        end
        
        if shouldUseBreathOfEons then
            API.CastSpell(spells.BREATH_OF_EONS)
            return true
        end
    end
    
    -- Use Bronze Flight when appropriate
    if bronzeFlight and 
       API.CanCast(spells.BRONZE_FLIGHT) and
       settings.supportSettings.bronzeFlightUsage ~= "Manual Only" then
        
        local shouldUseBronzeFlight = false
        
        if settings.supportSettings.bronzeFlightUsage == "On Cooldown" then
            shouldUseBronzeFlight = true
        elseif settings.supportSettings.bronzeFlightUsage == "With Cooldowns" then
            shouldUseBronzeFlight = burstModeActive
        end
        
        if shouldUseBronzeFlight then
            API.CastSpell(spells.BRONZE_FLIGHT)
            return true
        end
    end
    
    -- Use Upheaval when appropriate for group damage boost
    if eruption and 
       API.CanCast(spells.UPHEAVAL) and
       API.UnitExists("target") and
       isInRange then
        API.CastSpellOnUnit(spells.UPHEAVAL, "target")
        return true
    end
    
    -- Use Time Spiral when appropriate
    if timeSpiral and 
       API.CanCast(spells.TIME_SPIRAL) then
        API.CastSpell(spells.TIME_SPIRAL)
        return true
    end
    
    -- Use Emerald Communion when needed
    if emeraldCommunion and 
       API.CanCast(spells.EMERALD_COMMUNION) and
       currentMana < 40 then
        API.CastSpell(spells.EMERALD_COMMUNION)
        return true
    end
    
    return false
end

-- Handle AoE rotation
function Augmentation:HandleAoE(settings)
    -- Use Fire Breath for AoE damage
    if fireBreath and 
       fireBreathEmpowered and 
       API.CanCast(spells.FIRE_BREATH) and
       settings.abilityControls.fireBreath.enabled then
        
        local empowerLevel = settings.abilityControls.fireBreath.empowerLevel
        
        -- Adjust empower level based on settings and circumstances
        if settings.abilityControls.fireBreath.autoEmpowerLevel then
            if settings.rotationSettings.empowerPreference == "Maximum Empower" then
                empowerLevel = 3
            elseif settings.rotationSettings.empowerPreference == "Fast Cast" then
                empowerLevel = 0
            elseif settings.rotationSettings.empowerPreference == "Situational" then
                -- Scale with target count
                empowerLevel = math.min(activeEnemies - 1, 3)
                
                -- If we have Tip the Scales active, use max empower
                if tipTheScalesActive then
                    empowerLevel = 3
                end
            else
                empowerLevel = settings.rotationSettings.fireBreathLevel
            end
        end
        
        API.CastSpellEmpowered(spells.FIRE_BREATH, empowerLevel)
        return true
    end
    
    -- Use Disintegrate for AoE cleave
    if disintegrate and 
       API.CanCast(spells.DISINTEGRATE) and
       not disintegrateActive then
        API.CastSpellOnUnit(spells.DISINTEGRATE, "target")
        return true
    end
    
    -- Use Azure Strike for AoE
    if azureStrike and 
       API.CanCast(spells.AZURE_STRIKE) then
        API.CastSpellOnUnit(spells.AZURE_STRIKE, "target")
        return true
    end
    
    -- Use Living Flame as an essence builder
    if livingFlame and 
       API.CanCast(spells.LIVING_FLAME) and
       currentEssence < maxEssence - 1 and
       settings.rotationSettings.livingFlameUsage == "Essence Builder" then
        API.CastSpellOnUnit(spells.LIVING_FLAME, "target")
        return true
    end
    
    return false
end

-- Handle single target rotation
function Augmentation:HandleSingleTarget(settings)
    -- Use Azure Strike as a priority
    if azureStrike and 
       API.CanCast(spells.AZURE_STRIKE) then
        API.CastSpellOnUnit(spells.AZURE_STRIKE, "target")
        return true
    end
    
    -- Use Disintegrate if available
    if disintegrate and 
       API.CanCast(spells.DISINTEGRATE) and
       not disintegrateActive then
        API.CastSpellOnUnit(spells.DISINTEGRATE, "target")
        return true
    end
    
    -- Use Fire Breath for sustained damage
    if fireBreath and 
       fireBreathEmpowered and 
       API.CanCast(spells.FIRE_BREATH) and
       settings.abilityControls.fireBreath.enabled then
        
        local empowerLevel = settings.abilityControls.fireBreath.empowerLevel
        
        -- Adjust empower level based on settings and circumstances
        if settings.abilityControls.fireBreath.autoEmpowerLevel then
            if settings.rotationSettings.empowerPreference == "Maximum Empower" then
                empowerLevel = 3
            elseif settings.rotationSettings.empowerPreference == "Fast Cast" then
                empowerLevel = 0
            elseif settings.rotationSettings.empowerPreference == "Situational" then
                -- Single target usually best with lower empower for quick casts
                empowerLevel = 1
                
                -- If we have Tip the Scales active, use max empower
                if tipTheScalesActive then
                    empowerLevel = 3
                end
            else
                empowerLevel = settings.rotationSettings.fireBreathLevel
            end
        end
        
        API.CastSpellEmpowered(spells.FIRE_BREATH, empowerLevel)
        return true
    end
    
    -- Use Living Flame as an essence builder or filler
    if livingFlame and 
       API.CanCast(spells.LIVING_FLAME) and
       (settings.rotationSettings.livingFlameUsage == "Essence Builder" or 
        (settings.rotationSettings.livingFlameUsage == "Filler Only" and API.GetSpellCooldown(spells.AZURE_STRIKE) > 0)) then
        API.CastSpellOnUnit(spells.LIVING_FLAME, "target")
        return true
    end
    
    return false
end

-- Handle specialization change
function Augmentation:OnSpecializationChanged()
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
    azureStrike = false
    disintegrate = false
    disintegrateActive = false
    disintegrateEndTime = 0
    bless = false
    blessActive = false
    blessEndTime = 0
    breath = false
    breathOfEons = false
    breathOfEonsActive = false
    breathOfEonsEndTime = 0
    ebon = false
    ebonMight = false
    ebonMightActive = false
    ebonMightEndTime = 0
    prescience = false
    prescienceActive = false
    prescienceEndTime = 0
    source = false
    sourceOfMagic = false
    sourceOfMagicActive = false
    sourceOfMagicEndTime = 0
    spiritbloom = false
    spiritbloomEmpowered = false
    spiritbloomActive = false
    spiritbloomEndTime = 0
    tipTheScales = false
    tipTheScalesActive = false
    tipTheScalesEndTime = 0
    timeSpiral = false
    timeSpiralActive = false
    timeSpiralEndTime = 0
    eruption = false
    upheavalActive = false
    upheavalEndTime = 0
    fontOfMagic = false
    fontOfMagicActive = false
    fontOfMagicEndTime = 0
    iridescenceBlue = false
    iridescenceRed = false
    iridescenceActive = false
    iridescenceEndTime = 0
    exhilarationActive = false
    exhilarationEndTime = 0
    infernalSkin = false
    infernalSkinActive = false
    infernalSkinEndTime = 0
    leapingFlames = false
    leapingFlamesActive = false
    leapingFlamesEndTime = 0
    obsidianScales = false
    obsidianScalesActive = false
    obsidianScalesEndTime = 0
    cauterizingFlame = false
    hover = false
    tailSwipe = false
    wingBuffet = false
    essenceBurst = false
    essenceBurstActive = false
    essenceBurstStacks = 0
    essenceBurstEndTime = 0
    temporal = false
    temporalCompression = false
    temporalCompressionActive = false
    temporalCompressionEndTime = 0
    timelessRenewal = false
    timelessRenewalActive = false
    timelessRenewalEndTime = 0
    powerInfusion = false
    blossoming = false
    blossomingActive = false
    blossomingEndTime = 0
    emeraldCommunion = false
    emeraldCommunionActive = false
    emeraldCommunionEndTime = 0
    bronzeFlight = false
    bronzeFlightActive = false
    bronzeFlightEndTime = 0
    renewingBlaze = false
    resonatingPuddles = false
    resonatingPuddlesActive = false
    resonatingPuddlesEndTime = 0
    evenHand = false
    evenHandActive = false
    evenHandEndTime = 0
    lastLivingFlame = 0
    lastAzureStrike = 0
    lastFireBreath = 0
    lastDisintegrate = 0
    lastBless = 0
    lastBreathOfEons = 0
    lastEbonMight = 0
    lastPrescience = 0
    lastSourceOfMagic = 0
    lastSpiritbloom = 0
    lastTipTheScales = 0
    lastTimeSpiral = 0
    lastUpheaval = 0
    lastObsidianScales = 0
    lastCauterizingFlame = 0
    lastHover = 0
    lastTailSwipe = 0
    lastWingBuffet = 0
    lastTemporalCompression = 0
    lastTimelessRenewal = 0
    lastEmeraldCommunion = 0
    lastBronzeFlight = 0
    lastFirebrand = 0
    lastQuell = 0
    lastUnravel = 0
    lastSleepWalk = 0
    lastRescue = 0
    lastExpunge = 0
    lastRenewingBlaze = 0
    playerHealth = 100
    targetHealth = 100
    activeEnemies = 0
    isInRange = false
    castingEmpoweredSpell = false
    targetInAzureStrike = false
    
    API.PrintDebug("Augmentation Evoker state reset on spec change")
    
    return true
end

-- Return the module for loading
return Augmentation