------------------------------------------
-- WindrunnerRotations - Devastation Evoker Module
-- Author: VortexQ8
-- The War Within Season 2
------------------------------------------

local Devastation = {}
-- This will be assigned to addon.Classes.Evoker.Devastation when loaded

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
local deepBreath = false
local deepBreathActive = false
local deepBreathEndTime = 0
local disintegrate = false
local disintegrateActive = false
local disintegrateEndTime = 0
local eternity = false
local eternitySurge = false
local eternitySurgeEmpowered = false
local eternitySurgeActive = false
local eternitySurgeEndTime = 0
local firestorm = false
local firestormActive = false
local firestormStacks = 0
local firestormEndTime = 0
local powerSwell = false
local powerSwellActive = false
local powerSwellStacks = 0
local powerSwellEndTime = 0
local shattering = false
local shatteringStar = false
local shatteringActive = false
local shatteringStarEndTime = 0
local tipTheScales = false
local tipTheScalesActive = false
local tipTheScalesEndTime = 0
local dragonrage = false
local dragonrageActive = false
local dragonrageEndTime = 0
local essenceBurst = false
local essenceBurstActive = false
local essenceBurstStacks = 0
local essenceBurstEndTime = 0
local leapingFlames = false
local leapingFlamesActive = false
local leapingFlamesEndTime = 0
local burnout = false
local burnoutActive = false
local burnoutStacks = 0
local burnoutEndTime = 0
local fontOfMagic = false
local fontOfMagicActive = false
local fontOfMagicEndTime = 0
local ancientFlame = false
local ancientFlameActive = false
local ancientFlameStacks = 0
local ancientFlameEndTime = 0
local blastFurnace = false
local blastFurnaceActive = false
local blastFurnaceEndTime = 0
local obsidianScales = false
local obsidianScalesActive = false
local obsidianScalesEndTime = 0
local cauterizingFlame = false
local hover = false
local tailSwipe = false
local wingBuffet = false
local animosity = false
local everburningFlame = false
local scarletAdaptation = false
local scarletAdaptationActive = false 
local scarletAdaptationEndTime = 0
local feedTheFlames = false
local feedTheFlamesActive = false
local feedTheFlamesStacks = 0
local feedTheFlamesEndTime = 0
local iridescenceBlue = false
local iridescenceRed = false
local iridescenceActive = false
local iridescenceEndTime = 0
local rapture = false
local dragonflight = false
local dragonflightActive = false
local dragonflightEndTime = 0
local pyre = false
local pyreActive = false
local pyreEndTime = 0
local scintillation = false
local scintillationActive = false
local scintillationEndTime = 0
local lastLivingFlame = 0
local lastAzureStrike = 0
local lastFireBreath = 0
local lastDeepBreath = 0
local lastDisintegrate = 0
local lastEternitySurge = 0
local lastFirestorm = 0
local lastShatteringStar = 0
local lastDragonrage = 0
local lastTipTheScales = 0
local lastObsidianScales = 0
local lastCauterizingFlame = 0
local lastHover = 0
local lastTailSwipe = 0
local lastWingBuffet = 0
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
local targetInFirebreath = false
local targetInEternitySurge = false
local castingEmpoweredSpell = false

-- Constants
local DEVASTATION_SPEC_ID = 1467
local DRAGONRAGE_DURATION = 18.0 -- seconds
local FIRESTORM_DURATION = 10.0 -- seconds
local POWER_SWELL_DURATION = 15.0 -- seconds
local SHATTERING_STAR_DURATION = 6.0 -- seconds
local TIP_THE_SCALES_DURATION = 10.0 -- seconds
local ESSENCE_BURST_DURATION = 15.0 -- seconds
local LEAPING_FLAMES_DURATION = 30.0 -- seconds
local BURNOUT_DURATION = 30.0 -- seconds
local FONT_OF_MAGIC_DURATION = 15.0 -- seconds
local ANCIENT_FLAME_DURATION = 5.0 -- seconds
local BLAST_FURNACE_DURATION = 6.0 -- seconds
local OBSIDIAN_SCALES_DURATION = 8.0 -- seconds
local SCARLET_ADAPTATION_DURATION = 25.0 -- seconds
local FEED_THE_FLAMES_DURATION = 15.0 -- seconds
local IRIDESCENCE_DURATION = 20.0 -- seconds
local DRAGONFLIGHT_DURATION = 12.0 -- seconds
local PYRE_DURATION = 10.0 -- seconds
local SCINTILLATION_DURATION = 20.0 -- seconds

-- Initialize the Devastation module
function Devastation:Initialize()
    self:RegisterSpells()
    self:RegisterVariables()
    self:RegisterSettings()
    self:RegisterEvents()
    
    API.PrintDebug("Devastation Evoker module initialized")
    
    return true
end

-- Register spell IDs
function Devastation:RegisterSpells()
    -- Core abilities
    spells.LIVING_FLAME = 361469
    spells.FIRE_BREATH = 357208
    spells.AZURE_STRIKE = 362969
    spells.DEEP_BREATH = 357210
    spells.DISINTEGRATE = 356995
    spells.ETERNITY_SURGE = 359073
    spells.FIRESTORM = 368847
    spells.SHATTERING_STAR = 370452
    spells.DRAGONRAGE = 375087
    
    -- Core utility and defensive abilities
    spells.TIP_THE_SCALES = 370553
    spells.OBSIDIAN_SCALES = 363916
    spells.CAUTERIZING_FLAME = 374251
    spells.HOVER = 358267
    spells.TAIL_SWIPE = 368970
    spells.WING_BUFFET = 357214
    
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
    spells.ESSENCE_BURST = 359618
    spells.POWER_SWELL = 370839
    spells.LEAPING_FLAMES = 369939
    spells.BURNOUT = 375801
    spells.FONT_OF_MAGIC = 375783
    spells.ANCIENT_FLAME = 369990
    spells.BLAST_FURNACE = 375510
    spells.ANIMOSITY = 375797
    spells.EVERBURNING_FLAME = 370819
    spells.SCARLET_ADAPTATION = 372469
    spells.FEED_THE_FLAMES = 369846
    spells.IRIDESCENCE_BLUE = 386342
    spells.IRIDESCENCE_RED = 386344
    spells.RAPTURE = 372470
    spells.TYRANNY = 376888
    spells.DRAGONFLIGHT = 377509
    spells.PYRE = 357211
    scintillation = 370821
    
    -- War Within Season 2 specific
    spells.ETERNITY = 359077 -- This is an aspect of Eternity Surge
    
    -- Buff IDs
    spells.DRAGONRAGE_BUFF = 375087
    spells.FIRESTORM_BUFF = 368847
    spells.POWER_SWELL_BUFF = 370839
    spells.TIP_THE_SCALES_BUFF = 370553
    spells.ESSENCE_BURST_BUFF = 359618
    spells.LEAPING_FLAMES_BUFF = 369939
    spells.BURNOUT_BUFF = 375802
    spells.FONT_OF_MAGIC_BUFF = 375783
    spells.ANCIENT_FLAME_BUFF = 369990
    spells.BLAST_FURNACE_BUFF = 375510
    spells.OBSIDIAN_SCALES_BUFF = 363916
    spells.SCARLET_ADAPTATION_BUFF = 372470
    spells.FEED_THE_FLAMES_BUFF = 369846
    spells.IRIDESCENCE_BLUE_BUFF = 386342
    spells.IRIDESCENCE_RED_BUFF = 386344
    spells.DRAGONFLIGHT_BUFF = 377509
    spells.PYRE_BUFF = 357212
    spells.SCINTILLATION_BUFF = 370821
    
    -- Debuff IDs
    spells.DISINTEGRATE_DOT = 356995
    spells.FIRE_BREATH_DOT = 357209
    spells.FIREBRAND_DEBUFF = 374349
    spells.LIVING_FLAME_DEBUFF = 361500
    spells.SHATTERING_STAR_DEBUFF = 370452
    
    -- Register all spells with the API tracking system
    for spellName, spellID in pairs(spells) do
        API.RegisterSpell(spellID)
    end
    
    -- Define aura tracking
    buffs.DRAGONRAGE = spells.DRAGONRAGE_BUFF
    buffs.FIRESTORM = spells.FIRESTORM_BUFF
    buffs.POWER_SWELL = spells.POWER_SWELL_BUFF
    buffs.TIP_THE_SCALES = spells.TIP_THE_SCALES_BUFF
    buffs.ESSENCE_BURST = spells.ESSENCE_BURST_BUFF
    buffs.LEAPING_FLAMES = spells.LEAPING_FLAMES_BUFF
    buffs.BURNOUT = spells.BURNOUT_BUFF
    buffs.FONT_OF_MAGIC = spells.FONT_OF_MAGIC_BUFF
    buffs.ANCIENT_FLAME = spells.ANCIENT_FLAME_BUFF
    buffs.BLAST_FURNACE = spells.BLAST_FURNACE_BUFF
    buffs.OBSIDIAN_SCALES = spells.OBSIDIAN_SCALES_BUFF
    buffs.SCARLET_ADAPTATION = spells.SCARLET_ADAPTATION_BUFF
    buffs.FEED_THE_FLAMES = spells.FEED_THE_FLAMES_BUFF
    buffs.IRIDESCENCE_BLUE = spells.IRIDESCENCE_BLUE_BUFF
    buffs.IRIDESCENCE_RED = spells.IRIDESCENCE_RED_BUFF
    buffs.DRAGONFLIGHT = spells.DRAGONFLIGHT_BUFF
    buffs.PYRE = spells.PYRE_BUFF
    buffs.SCINTILLATION = spells.SCINTILLATION_BUFF
    
    debuffs.DISINTEGRATE = spells.DISINTEGRATE_DOT
    debuffs.FIRE_BREATH = spells.FIRE_BREATH_DOT
    debuffs.FIREBRAND = spells.FIREBRAND_DEBUFF
    debuffs.LIVING_FLAME = spells.LIVING_FLAME_DEBUFF
    debuffs.SHATTERING_STAR = spells.SHATTERING_STAR_DEBUFF
    
    return true
end

-- Register variables to track
function Devastation:RegisterVariables()
    -- Talent tracking
    talents.hasFirestorm = false
    talents.hasPowerSwell = false
    talents.hasLeapingFlames = false
    talents.hasBurnout = false
    talents.hasFontOfMagic = false
    talents.hasAncientFlame = false
    talents.hasBlastFurnace = false
    talents.hasAnimosity = false
    talents.hasEverburningFlame = false
    talents.hasScarletAdaptation = false
    talents.hasFeedTheFlames = false
    talents.hasIridescence = false
    talents.hasRapture = false
    talents.hasTyranny = false
    talents.hasDragonflight = false
    talents.hasPyre = false
    talents.hasScintillation = false
    
    -- Initialize resources
    currentMana = API.GetPlayerManaPercentage() or 100
    currentEssence = API.GetPowerResource("essence") or 0
    maxEssence = 6 -- Default
    
    return true
end

-- Register spec-specific settings
function Devastation:RegisterSettings()
    ConfigRegistry:RegisterSettings("DevastationEvoker", {
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
            eternitySurgeLevel = {
                displayName = "Eternity Surge Empower Level",
                description = "Default empower level for Eternity Surge (0-3)",
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
            tipTheScalesUsage = {
                displayName = "Tip the Scales Usage",
                description = "When to use Tip the Scales",
                type = "dropdown",
                options = {"With Dragonrage", "Fire Breath", "Eternity Surge", "Manual Only"},
                default = "With Dragonrage"
            },
            livingFlameUsage = {
                displayName = "Living Flame Usage",
                description = "When to use Living Flame",
                type = "dropdown",
                options = {"Essence Builder", "Filler Only", "With Burnout Only", "Never"},
                default = "Essence Builder"
            }
        },
        
        cooldownSettings = {
            useDragonrage = {
                displayName = "Use Dragonrage",
                description = "Automatically use Dragonrage",
                type = "toggle",
                default = true
            },
            dragonrageMode = {
                displayName = "Dragonrage Usage",
                description = "When to use Dragonrage",
                type = "dropdown",
                options = {"On Cooldown", "With Cooldowns", "Boss Only", "Manual Only"},
                default = "With Cooldowns"
            },
            useDeepBreath = {
                displayName = "Use Deep Breath",
                description = "Automatically use Deep Breath",
                type = "toggle",
                default = true
            },
            deepBreathMode = {
                displayName = "Deep Breath Usage",
                description = "When to use Deep Breath",
                type = "dropdown",
                options = {"On Cooldown", "With Cooldowns", "AoE Only", "Manual Only"},
                default = "AoE Only"
            },
            deepBreathMinTargets = {
                displayName = "Deep Breath Min Targets",
                description = "Minimum targets to use Deep Breath in AoE mode",
                type = "slider",
                min = 2,
                max = 8,
                default = 3
            },
            useFirestorm = {
                displayName = "Use Firestorm",
                description = "Automatically use Firestorm when talented",
                type = "toggle",
                default = true
            },
            firestormMode = {
                displayName = "Firestorm Usage",
                description = "When to use Firestorm",
                type = "dropdown",
                options = {"On Cooldown", "With Dragonrage", "AoE Only", "Manual Only"},
                default = "With Dragonrage"
            },
            firestormMinTargets = {
                displayName = "Firestorm Min Targets",
                description = "Minimum targets to use Firestorm in AoE mode",
                type = "slider",
                min = 2,
                max = 6,
                default = 3
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
            
            -- Eternity Surge controls
            eternitySurge = AAC.RegisterAbility(spells.ETERNITY_SURGE, {
                enabled = true,
                useDuringBurstOnly = false,
                empowerLevel = 1,
                autoEmpowerLevel = true
            }),
            
            -- Shattering Star controls
            shatteringStar = AAC.RegisterAbility(spells.SHATTERING_STAR, {
                enabled = true,
                useDuringBurstOnly = false,
                prioritizeWithDragonrage = true
            })
        }
    })
    
    return true
end

-- Register for events 
function Devastation:RegisterEvents()
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
function Devastation:UpdateTalentInfo()
    -- Check for important talents
    talents.hasFirestorm = API.HasTalent(spells.FIRESTORM)
    talents.hasPowerSwell = API.HasTalent(spells.POWER_SWELL)
    talents.hasLeapingFlames = API.HasTalent(spells.LEAPING_FLAMES)
    talents.hasBurnout = API.HasTalent(spells.BURNOUT)
    talents.hasFontOfMagic = API.HasTalent(spells.FONT_OF_MAGIC)
    talents.hasAncientFlame = API.HasTalent(spells.ANCIENT_FLAME)
    talents.hasBlastFurnace = API.HasTalent(spells.BLAST_FURNACE)
    talents.hasAnimosity = API.HasTalent(spells.ANIMOSITY)
    talents.hasEverburningFlame = API.HasTalent(spells.EVERBURNING_FLAME)
    talents.hasScarletAdaptation = API.HasTalent(spells.SCARLET_ADAPTATION)
    talents.hasFeedTheFlames = API.HasTalent(spells.FEED_THE_FLAMES)
    talents.hasIridescence = API.HasTalent(spells.IRIDESCENCE_BLUE) or API.HasTalent(spells.IRIDESCENCE_RED)
    talents.hasRapture = API.HasTalent(spells.RAPTURE)
    talents.hasTyranny = API.HasTalent(spells.TYRANNY)
    talents.hasDragonflight = API.HasTalent(spells.DRAGONFLIGHT)
    talents.hasPyre = API.HasTalent(spells.PYRE)
    talents.hasScintillation = API.HasTalent(spells.SCINTILLATION)
    
    -- Set specialized variables based on talents
    if talents.hasFirestorm then
        firestorm = true
    end
    
    if talents.hasPowerSwell then
        powerSwell = true
    end
    
    if talents.hasLeapingFlames then
        leapingFlames = true
    end
    
    if talents.hasBurnout then
        burnout = true
    end
    
    if talents.hasFontOfMagic then
        fontOfMagic = true
    end
    
    if talents.hasAncientFlame then
        ancientFlame = true
    end
    
    if talents.hasBlastFurnace then
        blastFurnace = true
    end
    
    if talents.hasAnimosity then
        animosity = true
    end
    
    if talents.hasEverburningFlame then
        everburningFlame = true
    end
    
    if talents.hasScarletAdaptation then
        scarletAdaptation = true
    end
    
    if talents.hasFeedTheFlames then
        feedTheFlames = true
    end
    
    if talents.hasIridescence then
        if API.HasTalent(spells.IRIDESCENCE_BLUE) then
            iridescenceBlue = true
        end
        
        if API.HasTalent(spells.IRIDESCENCE_RED) then
            iridescenceRed = true
        end
    end
    
    if talents.hasRapture then
        rapture = true
    end
    
    if talents.hasDragonflight then
        dragonflight = true
    end
    
    if talents.hasPyre then
        pyre = true
    end
    
    if talents.hasScintillation then
        scintillation = true
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
    
    if API.IsSpellKnown(spells.DEEP_BREATH) then
        deepBreath = true
    end
    
    if API.IsSpellKnown(spells.DISINTEGRATE) then
        disintegrate = true
    end
    
    if API.IsSpellKnown(spells.ETERNITY_SURGE) then
        eternitySurge = true
        eternitySurgeEmpowered = true
    end
    
    if API.IsSpellKnown(spells.ETERNITY) then
        eternity = true
    end
    
    if API.IsSpellKnown(spells.SHATTERING_STAR) then
        shattering = true
        shatteringStar = true
    end
    
    if API.IsSpellKnown(spells.DRAGONRAGE) then
        dragonrage = true
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
    
    API.PrintDebug("Devastation Evoker talents updated")
    
    return true
end

-- Update mana tracking
function Devastation:UpdateMana()
    currentMana = API.GetPlayerManaPercentage()
    return true
end

-- Update essence tracking
function Devastation:UpdateEssence()
    currentEssence = API.GetPowerResource("essence") or 0
    return true
end

-- Update health tracking
function Devastation:UpdateHealth()
    playerHealth = API.GetPlayerHealthPercent()
    return true
end

-- Update target health tracking
function Devastation:UpdateTargetHealth()
    targetHealth = API.GetTargetHealthPercent()
    return true
end

-- Update active enemy counts
function Devastation:UpdateEnemyCounts()
    activeEnemies = API.GetEnemyCount() or 0
    return true
end

-- Handle spell channel start
function Devastation:HandleSpellChannelStart(spellID)
    if spellID == spells.DISINTEGRATE then
        disintegrateActive = true
        disintegrateEndTime = GetTime() + 3.0 -- Approximate channel duration
        API.PrintDebug("Disintegrate channel started")
    end
    
    return true
end

-- Handle empowered spell start
function Devastation:HandleEmpowerStart(spellID)
    castingEmpoweredSpell = true
    
    if spellID == spells.FIRE_BREATH then
        fireBreathActive = true
        API.PrintDebug("Fire Breath empowering started")
    elseif spellID == spells.ETERNITY_SURGE then
        eternitySurgeActive = true
        API.PrintDebug("Eternity Surge empowering started")
    end
    
    return true
end

-- Handle empowered spell stop
function Devastation:HandleEmpowerStop(spellID)
    castingEmpoweredSpell = false
    
    if spellID == spells.FIRE_BREATH then
        fireBreathActive = false
        fireBreathEndTime = GetTime() + 15.0 -- DoT duration (approximate)
        API.PrintDebug("Fire Breath cast")
    elseif spellID == spells.ETERNITY_SURGE then
        eternitySurgeActive = false
        eternitySurgeEndTime = GetTime() + 8.0 -- Effect duration (approximate)
        API.PrintDebug("Eternity Surge cast")
    end
    
    return true
end

-- Handle combat log events
function Devastation:HandleCombatLogEvent(...)
    local timestamp, eventType, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, spellID, spellName = CombatLogGetCurrentEventInfo()
    
    -- Track player events (casts, buffs, etc.)
    if sourceGUID == API.GetPlayerGUID() then
        -- Track buff applications
        if eventType == "SPELL_AURA_APPLIED" or eventType == "SPELL_AURA_REFRESH" then
            -- Track Dragonrage application
            if spellID == buffs.DRAGONRAGE then
                dragonrageActive = true
                dragonrageEndTime = select(6, API.GetBuffInfo("player", buffs.DRAGONRAGE))
                API.PrintDebug("Dragonrage activated")
            end
            
            -- Track Firestorm application
            if spellID == buffs.FIRESTORM then
                firestormActive = true
                firestormEndTime = select(6, API.GetBuffInfo("player", buffs.FIRESTORM))
                firestormStacks = select(4, API.GetBuffInfo("player", buffs.FIRESTORM)) or 1
                API.PrintDebug("Firestorm activated: " .. tostring(firestormStacks) .. " stack(s)")
            end
            
            -- Track Power Swell application
            if spellID == buffs.POWER_SWELL then
                powerSwellActive = true
                powerSwellEndTime = select(6, API.GetBuffInfo("player", buffs.POWER_SWELL))
                powerSwellStacks = select(4, API.GetBuffInfo("player", buffs.POWER_SWELL)) or 1
                API.PrintDebug("Power Swell activated: " .. tostring(powerSwellStacks) .. " stack(s)")
            end
            
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
            
            -- Track Leaping Flames application
            if spellID == buffs.LEAPING_FLAMES then
                leapingFlamesActive = true
                leapingFlamesEndTime = select(6, API.GetBuffInfo("player", buffs.LEAPING_FLAMES))
                API.PrintDebug("Leaping Flames activated")
            end
            
            -- Track Burnout application
            if spellID == buffs.BURNOUT then
                burnoutActive = true
                burnoutEndTime = select(6, API.GetBuffInfo("player", buffs.BURNOUT))
                burnoutStacks = select(4, API.GetBuffInfo("player", buffs.BURNOUT)) or 1
                API.PrintDebug("Burnout activated: " .. tostring(burnoutStacks) .. " stack(s)")
            end
            
            -- Track Font of Magic application
            if spellID == buffs.FONT_OF_MAGIC then
                fontOfMagicActive = true
                fontOfMagicEndTime = select(6, API.GetBuffInfo("player", buffs.FONT_OF_MAGIC))
                API.PrintDebug("Font of Magic activated")
            end
            
            -- Track Ancient Flame application
            if spellID == buffs.ANCIENT_FLAME then
                ancientFlameActive = true
                ancientFlameEndTime = select(6, API.GetBuffInfo("player", buffs.ANCIENT_FLAME))
                ancientFlameStacks = select(4, API.GetBuffInfo("player", buffs.ANCIENT_FLAME)) or 1
                API.PrintDebug("Ancient Flame activated: " .. tostring(ancientFlameStacks) .. " stack(s)")
            end
            
            -- Track Blast Furnace application
            if spellID == buffs.BLAST_FURNACE then
                blastFurnaceActive = true
                blastFurnaceEndTime = select(6, API.GetBuffInfo("player", buffs.BLAST_FURNACE))
                API.PrintDebug("Blast Furnace activated")
            end
            
            -- Track Obsidian Scales application
            if spellID == buffs.OBSIDIAN_SCALES then
                obsidianScalesActive = true
                obsidianScalesEndTime = select(6, API.GetBuffInfo("player", buffs.OBSIDIAN_SCALES))
                API.PrintDebug("Obsidian Scales activated")
            end
            
            -- Track Scarlet Adaptation application
            if spellID == buffs.SCARLET_ADAPTATION then
                scarletAdaptationActive = true
                scarletAdaptationEndTime = select(6, API.GetBuffInfo("player", buffs.SCARLET_ADAPTATION))
                API.PrintDebug("Scarlet Adaptation activated")
            end
            
            -- Track Feed the Flames application
            if spellID == buffs.FEED_THE_FLAMES then
                feedTheFlamesActive = true
                feedTheFlamesEndTime = select(6, API.GetBuffInfo("player", buffs.FEED_THE_FLAMES))
                feedTheFlamesStacks = select(4, API.GetBuffInfo("player", buffs.FEED_THE_FLAMES)) or 1
                API.PrintDebug("Feed the Flames activated: " .. tostring(feedTheFlamesStacks) .. " stack(s)")
            end
            
            -- Track Iridescence application
            if spellID == buffs.IRIDESCENCE_BLUE or spellID == buffs.IRIDESCENCE_RED then
                iridescenceActive = true
                iridescenceEndTime = select(6, API.GetBuffInfo("player", spellID))
                API.PrintDebug("Iridescence activated")
            end
            
            -- Track Dragonflight application
            if spellID == buffs.DRAGONFLIGHT then
                dragonflightActive = true
                dragonflightEndTime = select(6, API.GetBuffInfo("player", buffs.DRAGONFLIGHT))
                API.PrintDebug("Dragonflight activated")
            end
            
            -- Track Pyre application
            if spellID == buffs.PYRE then
                pyreActive = true
                pyreEndTime = select(6, API.GetBuffInfo("player", buffs.PYRE))
                API.PrintDebug("Pyre activated")
            end
            
            -- Track Scintillation application
            if spellID == buffs.SCINTILLATION then
                scintillationActive = true
                scintillationEndTime = select(6, API.GetBuffInfo("player", buffs.SCINTILLATION))
                API.PrintDebug("Scintillation activated")
            end
        end
        
        -- Track buff removals
        if eventType == "SPELL_AURA_REMOVED" then
            -- Track Dragonrage removal
            if spellID == buffs.DRAGONRAGE then
                dragonrageActive = false
                API.PrintDebug("Dragonrage faded")
            end
            
            -- Track Firestorm removal
            if spellID == buffs.FIRESTORM then
                firestormActive = false
                firestormStacks = 0
                API.PrintDebug("Firestorm faded")
            end
            
            -- Track Power Swell removal
            if spellID == buffs.POWER_SWELL then
                powerSwellActive = false
                powerSwellStacks = 0
                API.PrintDebug("Power Swell faded")
            end
            
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
            
            -- Track Leaping Flames removal
            if spellID == buffs.LEAPING_FLAMES then
                leapingFlamesActive = false
                API.PrintDebug("Leaping Flames faded")
            end
            
            -- Track Burnout removal
            if spellID == buffs.BURNOUT then
                burnoutActive = false
                burnoutStacks = 0
                API.PrintDebug("Burnout faded")
            end
            
            -- Track Font of Magic removal
            if spellID == buffs.FONT_OF_MAGIC then
                fontOfMagicActive = false
                API.PrintDebug("Font of Magic faded")
            end
            
            -- Track Ancient Flame removal
            if spellID == buffs.ANCIENT_FLAME then
                ancientFlameActive = false
                ancientFlameStacks = 0
                API.PrintDebug("Ancient Flame faded")
            end
            
            -- Track Blast Furnace removal
            if spellID == buffs.BLAST_FURNACE then
                blastFurnaceActive = false
                API.PrintDebug("Blast Furnace faded")
            end
            
            -- Track Obsidian Scales removal
            if spellID == buffs.OBSIDIAN_SCALES then
                obsidianScalesActive = false
                API.PrintDebug("Obsidian Scales faded")
            end
            
            -- Track Scarlet Adaptation removal
            if spellID == buffs.SCARLET_ADAPTATION then
                scarletAdaptationActive = false
                API.PrintDebug("Scarlet Adaptation faded")
            end
            
            -- Track Feed the Flames removal
            if spellID == buffs.FEED_THE_FLAMES then
                feedTheFlamesActive = false
                feedTheFlamesStacks = 0
                API.PrintDebug("Feed the Flames faded")
            end
            
            -- Track Iridescence removal
            if spellID == buffs.IRIDESCENCE_BLUE or spellID == buffs.IRIDESCENCE_RED then
                iridescenceActive = false
                API.PrintDebug("Iridescence faded")
            end
            
            -- Track Dragonflight removal
            if spellID == buffs.DRAGONFLIGHT then
                dragonflightActive = false
                API.PrintDebug("Dragonflight faded")
            end
            
            -- Track Pyre removal
            if spellID == buffs.PYRE then
                pyreActive = false
                API.PrintDebug("Pyre faded")
            end
            
            -- Track Scintillation removal
            if spellID == buffs.SCINTILLATION then
                scintillationActive = false
                API.PrintDebug("Scintillation faded")
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
            elseif spellID == spells.DEEP_BREATH then
                lastDeepBreath = GetTime()
                deepBreathActive = true
                deepBreathEndTime = GetTime() + 3.0 -- Approximate duration
                API.PrintDebug("Deep Breath cast")
            elseif spellID == spells.SHATTERING_STAR then
                lastShatteringStar = GetTime()
                shatteringActive = true
                shatteringStarEndTime = GetTime() + SHATTERING_STAR_DURATION
                API.PrintDebug("Shattering Star cast")
            elseif spellID == spells.DRAGONRAGE then
                lastDragonrage = GetTime()
                dragonrageActive = true
                dragonrageEndTime = GetTime() + DRAGONRAGE_DURATION
                API.PrintDebug("Dragonrage cast")
            elseif spellID == spells.FIRESTORM then
                lastFirestorm = GetTime()
                firestormActive = true
                firestormEndTime = GetTime() + FIRESTORM_DURATION
                API.PrintDebug("Firestorm cast")
            elseif spellID == spells.TIP_THE_SCALES then
                lastTipTheScales = GetTime()
                tipTheScalesActive = true
                tipTheScalesEndTime = GetTime() + TIP_THE_SCALES_DURATION
                API.PrintDebug("Tip the Scales cast")
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
            -- Track Living Flame debuff
            if spellID == debuffs.LIVING_FLAME then
                API.PrintDebug("Living Flame debuff applied to " .. destName)
            end
            
            -- Track Fire Breath debuff
            if spellID == debuffs.FIRE_BREATH then
                targetInFirebreath = true
                API.PrintDebug("Fire Breath debuff applied to " .. destName)
            end
            
            -- Track Disintegrate debuff
            if spellID == debuffs.DISINTEGRATE then
                API.PrintDebug("Disintegrate debuff applied to " .. destName)
            end
            
            -- Track Shattering Star debuff
            if spellID == debuffs.SHATTERING_STAR then
                API.PrintDebug("Shattering Star debuff applied to " .. destName)
            end
            
            -- Track Firebrand debuff
            if spellID == debuffs.FIREBRAND then
                API.PrintDebug("Firebrand debuff applied to " .. destName)
            end
        end
        
        -- Track debuff removals
        if eventType == "SPELL_AURA_REMOVED" and destGUID then
            -- Track Fire Breath debuff removal
            if spellID == debuffs.FIRE_BREATH then
                if destGUID == API.UnitGUID("target") then
                    targetInFirebreath = false
                end
                API.PrintDebug("Fire Breath debuff removed from " .. destName)
            end
        end
    end
    
    return true
end

-- Main rotation function
function Devastation:RunRotation()
    -- Check if we should be running Devastation Evoker logic
    if API.GetActiveSpecID() ~= DEVASTATION_SPEC_ID then
        return false
    end
    
    -- Skip rotation if player is casting or empowering
    if API.IsPlayerCasting() or castingEmpoweredSpell then
        return false
    end
    
    -- Get settings
    local settings = ConfigRegistry:GetSettings("DevastationEvoker")
    
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
    
    -- Check for valid target in combat
    if not API.UnitExists("target") or not API.IsUnitEnemy("target") then
        return false
    end
    
    -- Handle major cooldowns (Dragonrage, etc.)
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
function Devastation:HandleDefensives(settings)
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
    if API.IsSpellKnown(spells.RENEWING_BLAZE) and 
       settings.defensiveSettings.useRenewingBlaze and 
       playerHealth <= settings.defensiveSettings.renewingBlazeThreshold and 
       API.CanCast(spells.RENEWING_BLAZE) then
        API.CastSpell(spells.RENEWING_BLAZE)
        return true
    end
    
    return false
end

-- Handle interrupts and utility
function Devastation:HandleInterrupts(settings)
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
    
    return false
end

-- Handle major cooldowns
function Devastation:HandleMajorCooldowns(settings)
    -- Use Tip the Scales
    if tipTheScales and 
       API.CanCast(spells.TIP_THE_SCALES) and
       settings.rotationSettings.tipTheScalesUsage ~= "Manual Only" then
        
        local shouldUseTipTheScales = false
        
        if settings.rotationSettings.tipTheScalesUsage == "With Dragonrage" and dragonrageActive then
            shouldUseTipTheScales = true
            -- Queue up Fire Breath or Eternity Surge after Tip the Scales
            if fireBreath and API.GetSpellCooldown(spells.FIRE_BREATH) <= 0 then
                nextCastOverride = spells.FIRE_BREATH
            elseif eternitySurge and API.GetSpellCooldown(spells.ETERNITY_SURGE) <= 0 then
                nextCastOverride = spells.ETERNITY_SURGE
            end
        elseif settings.rotationSettings.tipTheScalesUsage == "Fire Breath" and API.GetSpellCooldown(spells.FIRE_BREATH) <= 0 then
            shouldUseTipTheScales = true
            nextCastOverride = spells.FIRE_BREATH
        elseif settings.rotationSettings.tipTheScalesUsage == "Eternity Surge" and API.GetSpellCooldown(spells.ETERNITY_SURGE) <= 0 then
            shouldUseTipTheScales = true
            nextCastOverride = spells.ETERNITY_SURGE
        end
        
        if shouldUseTipTheScales then
            API.CastSpell(spells.TIP_THE_SCALES)
            return true
        end
    end
    
    -- Use Dragonrage
    if dragonrage and 
       settings.cooldownSettings.useDragonrage and 
       settings.cooldownSettings.dragonrageMode ~= "Manual Only" and
       API.CanCast(spells.DRAGONRAGE) then
        
        local shouldUseDragonrage = false
        
        if settings.cooldownSettings.dragonrageMode == "On Cooldown" then
            shouldUseDragonrage = true
        elseif settings.cooldownSettings.dragonrageMode == "With Cooldowns" then
            shouldUseDragonrage = burstModeActive
        elseif settings.cooldownSettings.dragonrageMode == "Boss Only" then
            shouldUseDragonrage = API.IsFightingBoss()
        end
        
        if shouldUseDragonrage then
            API.CastSpell(spells.DRAGONRAGE)
            return true
        end
    end
    
    -- Use Deep Breath
    if deepBreath and 
       settings.cooldownSettings.useDeepBreath and 
       settings.cooldownSettings.deepBreathMode ~= "Manual Only" and
       API.CanCast(spells.DEEP_BREATH) then
        
        local shouldUseDeepBreath = false
        
        if settings.cooldownSettings.deepBreathMode == "On Cooldown" then
            shouldUseDeepBreath = true
        elseif settings.cooldownSettings.deepBreathMode == "With Cooldowns" then
            shouldUseDeepBreath = dragonrageActive or burstModeActive
        elseif settings.cooldownSettings.deepBreathMode == "AoE Only" then
            shouldUseDeepBreath = activeEnemies >= settings.cooldownSettings.deepBreathMinTargets
        end
        
        if shouldUseDeepBreath then
            API.CastSpellAtBestLocation(spells.DEEP_BREATH)
            return true
        end
    end
    
    -- Use Firestorm
    if firestorm and 
       settings.cooldownSettings.useFirestorm and 
       settings.cooldownSettings.firestormMode ~= "Manual Only" and
       API.CanCast(spells.FIRESTORM) then
        
        local shouldUseFirestorm = false
        
        if settings.cooldownSettings.firestormMode == "On Cooldown" then
            shouldUseFirestorm = true
        elseif settings.cooldownSettings.firestormMode == "With Dragonrage" then
            shouldUseFirestorm = dragonrageActive
        elseif settings.cooldownSettings.firestormMode == "AoE Only" then
            shouldUseFirestorm = activeEnemies >= settings.cooldownSettings.firestormMinTargets
        end
        
        if shouldUseFirestorm then
            API.CastSpell(spells.FIRESTORM)
            return true
        end
    end
    
    return false
end

-- Handle AoE rotation
function Devastation:HandleAoE(settings)
    -- Use Fire Breath
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
    
    -- Use Eternity Surge in AoE
    if eternitySurge and 
       eternitySurgeEmpowered and 
       API.CanCast(spells.ETERNITY_SURGE) and
       settings.abilityControls.eternitySurge.enabled then
        
        local empowerLevel = settings.abilityControls.eternitySurge.empowerLevel
        
        -- Adjust empower level based on settings and circumstances
        if settings.abilityControls.eternitySurge.autoEmpowerLevel then
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
                empowerLevel = settings.rotationSettings.eternitySurgeLevel
            end
        end
        
        API.CastSpellEmpowered(spells.ETERNITY_SURGE, empowerLevel)
        return true
    end
    
    -- Use Azure Strike for AoE (when needed)
    if azureStrike and 
       API.CanCast(spells.AZURE_STRIKE) and
       -- Check if we need to save Essence for other spells
       (not settings.rotationSettings.essenceManagement or 
        settings.rotationSettings.essenceManagement == "Aggressive" or
        currentEssence > settings.rotationSettings.conserveEssence) then
        API.CastSpellOnUnit(spells.AZURE_STRIKE, "target")
        return true
    end
    
    -- Use Disintegrate in AoE when good to cleave
    if disintegrate and 
       API.CanCast(spells.DISINTEGRATE) and
       -- Check if we need to save Essence for other spells
       (not settings.rotationSettings.essenceManagement or 
        settings.rotationSettings.essenceManagement == "Aggressive" or
        currentEssence > settings.rotationSettings.conserveEssence + 1) then
        API.CastSpellOnUnit(spells.DISINTEGRATE, "target")
        return true
    end
    
    -- Use Shattering Star on cooldown
    if shatteringStar and 
       API.CanCast(spells.SHATTERING_STAR) and
       settings.abilityControls.shatteringStar.enabled then
        
        local shouldUseShatteringStar = true
        
        if settings.abilityControls.shatteringStar.useDuringBurstOnly and not burstModeActive then
            shouldUseShatteringStar = false
        end
        
        if settings.abilityControls.shatteringStar.prioritizeWithDragonrage and not dragonrageActive then
            shouldUseShatteringStar = false
        end
        
        if shouldUseShatteringStar then
            API.CastSpellOnUnit(spells.SHATTERING_STAR, "target")
            return true
        end
    end
    
    -- Use Living Flame as filler or essence builder
    if livingFlame and 
       API.CanCast(spells.LIVING_FLAME) and
       currentEssence < maxEssence - 1 and
       settings.rotationSettings.livingFlameUsage ~= "Never" then
        
        local shouldUseLivingFlame = false
        
        if settings.rotationSettings.livingFlameUsage == "Essence Builder" then
            shouldUseLivingFlame = true
        elseif settings.rotationSettings.livingFlameUsage == "Filler Only" then
            shouldUseLivingFlame = API.GetSpellCooldown(spells.AZURE_STRIKE) > 0
        elseif settings.rotationSettings.livingFlameUsage == "With Burnout Only" then
            shouldUseLivingFlame = burnoutActive
        end
        
        if shouldUseLivingFlame then
            API.CastSpellOnUnit(spells.LIVING_FLAME, "target")
            return true
        end
    end
    
    return false
end

-- Handle single target rotation
function Devastation:HandleSingleTarget(settings)
    -- Use Shattering Star on cooldown in single target
    if shatteringStar and 
       API.CanCast(spells.SHATTERING_STAR) and
       settings.abilityControls.shatteringStar.enabled then
        
        local shouldUseShatteringStar = true
        
        if settings.abilityControls.shatteringStar.useDuringBurstOnly and not burstModeActive then
            shouldUseShatteringStar = false
        end
        
        if settings.abilityControls.shatteringStar.prioritizeWithDragonrage and not dragonrageActive then
            shouldUseShatteringStar = false
        end
        
        if shouldUseShatteringStar then
            API.CastSpellOnUnit(spells.SHATTERING_STAR, "target")
            return true
        end
    end
    
    -- Use Fire Breath
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
                -- Single target usually best at lower empower levels for speed
                empowerLevel = dragonrageActive ? 3 : 1
                
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
    
    -- Use Eternity Surge
    if eternitySurge and 
       eternitySurgeEmpowered and 
       API.CanCast(spells.ETERNITY_SURGE) and
       settings.abilityControls.eternitySurge.enabled then
        
        local empowerLevel = settings.abilityControls.eternitySurge.empowerLevel
        
        -- Adjust empower level based on settings and circumstances
        if settings.abilityControls.eternitySurge.autoEmpowerLevel then
            if settings.rotationSettings.empowerPreference == "Maximum Empower" then
                empowerLevel = 3
            elseif settings.rotationSettings.empowerPreference == "Fast Cast" then
                empowerLevel = 0
            elseif settings.rotationSettings.empowerPreference == "Situational" then
                -- Single target usually best with higher empower in most cases
                empowerLevel = 2
                
                -- If we have Tip the Scales active, use max empower
                if tipTheScalesActive then
                    empowerLevel = 3
                end
                
                -- If we have Dragonrage active, use max empower
                if dragonrageActive then
                    empowerLevel = 3
                end
            else
                empowerLevel = settings.rotationSettings.eternitySurgeLevel
            end
        end
        
        API.CastSpellEmpowered(spells.ETERNITY_SURGE, empowerLevel)
        return true
    end
    
    -- Use Disintegrate when appropriate
    if disintegrate and 
       API.CanCast(spells.DISINTEGRATE) and
       -- Check if we need to save Essence for other spells
       (not settings.rotationSettings.essenceManagement or 
        settings.rotationSettings.essenceManagement == "Aggressive" or
        currentEssence > settings.rotationSettings.conserveEssence + 1) then
        API.CastSpellOnUnit(spells.DISINTEGRATE, "target")
        return true
    end
    
    -- Use Azure Strike as filler
    if azureStrike and 
       API.CanCast(spells.AZURE_STRIKE) and
       -- Check if we need to save Essence for other spells
       (not settings.rotationSettings.essenceManagement or 
        settings.rotationSettings.essenceManagement == "Aggressive" or
        currentEssence > settings.rotationSettings.conserveEssence) then
        API.CastSpellOnUnit(spells.AZURE_STRIKE, "target")
        return true
    end
    
    -- Use Living Flame as filler or essence builder
    if livingFlame and 
       API.CanCast(spells.LIVING_FLAME) and
       currentEssence < maxEssence - 1 and
       settings.rotationSettings.livingFlameUsage ~= "Never" then
        
        local shouldUseLivingFlame = false
        
        if settings.rotationSettings.livingFlameUsage == "Essence Builder" then
            shouldUseLivingFlame = true
        elseif settings.rotationSettings.livingFlameUsage == "Filler Only" then
            shouldUseLivingFlame = API.GetSpellCooldown(spells.AZURE_STRIKE) > 0
        elseif settings.rotationSettings.livingFlameUsage == "With Burnout Only" then
            shouldUseLivingFlame = burnoutActive
        end
        
        if shouldUseLivingFlame then
            API.CastSpellOnUnit(spells.LIVING_FLAME, "target")
            return true
        end
    end
    
    return false
end

-- Handle specialization change
function Devastation:OnSpecializationChanged()
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
    deepBreath = false
    deepBreathActive = false
    deepBreathEndTime = 0
    disintegrate = false
    disintegrateActive = false
    disintegrateEndTime = 0
    eternity = false
    eternitySurge = false
    eternitySurgeEmpowered = false
    eternitySurgeActive = false
    eternitySurgeEndTime = 0
    firestorm = false
    firestormActive = false
    firestormStacks = 0
    firestormEndTime = 0
    powerSwell = false
    powerSwellActive = false
    powerSwellStacks = 0
    powerSwellEndTime = 0
    shattering = false
    shatteringStar = false
    shatteringActive = false
    shatteringStarEndTime = 0
    tipTheScales = false
    tipTheScalesActive = false
    tipTheScalesEndTime = 0
    dragonrage = false
    dragonrageActive = false
    dragonrageEndTime = 0
    essenceBurst = false
    essenceBurstActive = false
    essenceBurstStacks = 0
    essenceBurstEndTime = 0
    leapingFlames = false
    leapingFlamesActive = false
    leapingFlamesEndTime = 0
    burnout = false
    burnoutActive = false
    burnoutStacks = 0
    burnoutEndTime = 0
    fontOfMagic = false
    fontOfMagicActive = false
    fontOfMagicEndTime = 0
    ancientFlame = false
    ancientFlameActive = false
    ancientFlameStacks = 0
    ancientFlameEndTime = 0
    blastFurnace = false
    blastFurnaceActive = false
    blastFurnaceEndTime = 0
    obsidianScales = false
    obsidianScalesActive = false
    obsidianScalesEndTime = 0
    cauterizingFlame = false
    hover = false
    tailSwipe = false
    wingBuffet = false
    animosity = false
    everburningFlame = false
    scarletAdaptation = false
    scarletAdaptationActive = false 
    scarletAdaptationEndTime = 0
    feedTheFlames = false
    feedTheFlamesActive = false
    feedTheFlamesStacks = 0
    feedTheFlamesEndTime = 0
    iridescenceBlue = false
    iridescenceRed = false
    iridescenceActive = false
    iridescenceEndTime = 0
    rapture = false
    dragonflight = false
    dragonflightActive = false
    dragonflightEndTime = 0
    pyre = false
    pyreActive = false
    pyreEndTime = 0
    scintillation = false
    scintillationActive = false
    scintillationEndTime = 0
    lastLivingFlame = 0
    lastAzureStrike = 0
    lastFireBreath = 0
    lastDeepBreath = 0
    lastDisintegrate = 0
    lastEternitySurge = 0
    lastFirestorm = 0
    lastShatteringStar = 0
    lastDragonrage = 0
    lastTipTheScales = 0
    lastObsidianScales = 0
    lastCauterizingFlame = 0
    lastHover = 0
    lastTailSwipe = 0
    lastWingBuffet = 0
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
    targetInFirebreath = false
    targetInEternitySurge = false
    castingEmpoweredSpell = false
    
    API.PrintDebug("Devastation Evoker state reset on spec change")
    
    return true
end

-- Return the module for loading
return Devastation