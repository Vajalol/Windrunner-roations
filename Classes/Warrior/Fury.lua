------------------------------------------
-- WindrunnerRotations - Fury Warrior Module
-- Author: VortexQ8
-- The War Within Season 2
------------------------------------------

local Fury = {}
-- This will be assigned to addon.Classes.Warrior.Fury when loaded

-- These will be set when the file is loaded in our test environment
local API
local ConfigRegistry
local AAC
local Warrior

-- Cache frequently accessed data
local spells = {}
local talents = {}
local buffs = {}
local debuffs = {}

-- State tracking variables
local nextCastOverride = nil
local burstModeActive = false
local currentAoETargets = 0
local currentRage = 0
local maxRage = 100
local enrageActive = false
local enrageEndTime = 0
local frenzyActive = false
local frenzyStacks = 0
local frenzyEndTime = 0
local whirlwindBuff = false 
local whirlwindBuffEndTime = 0
local recklessnessActive = false
local recklessnessEndTime = 0
local havocActive = false
local swordAndBoardProc = false
local swordAndBoardEndTime = 0
local inMeleeRange = false
local inExecutePhase = false
local suddenDeathProc = false
local inRange5 = false
local inRange8 = false
local rampageCharges = 0
local slaughterActive = false
local battlelordActive = false
local spearActive = false
local ancientAftershock = false
local hasSuperpositionResonator = false
local annihilatorActive = false
local ragetimeCooldown = 0
local executionersPrecisionStacks = 0
local meatCleaverStack = 0
local recklesAbandon = false
local overpower = false
local viciousStrikes = false
local wrathandFuryActive = false
local unhingedActive = false
local crushingForceBuff = 0

-- Constants
local FURY_SPEC_ID = 72
local DEFAULT_AOE_THRESHOLD = 3
local EXECUTE_THRESHOLD = 35  -- Updated for War Within patch
local WHIRLWIND_BUFF_DURATION = 20
local ENRAGE_DURATION = 8
local RECKLESSNESS_DURATION = 12
local RAMPAGE_COST = 80
local EXECUTE_COST = 20
local WHIRLWIND_COST = 30
local WRECKING_THROW_MIN_RANGE = 10
local RAGING_BLOW_COUNT = 2 -- Number of charges
local BLOODTHIRST_HEAL_PERCENT = 4

-- Initialize the Fury module
function Fury:Initialize()
    self:RegisterSpells()
    self:RegisterVariables()
    self:RegisterSettings()
    self:RegisterEvents()
    
    API.PrintDebug("Fury Warrior module initialized")
    
    return true
end

-- Register spell IDs
function Fury:RegisterSpells()
    -- Core rotational abilities
    spells.BLOODTHIRST = 23881
    spells.RAGING_BLOW = 85288
    spells.RAMPAGE = 184367
    spells.EXECUTE = 5308
    spells.WHIRLWIND = 190411
    spells.SLAM = 1464
    spells.CRUSHING_BLOW = 335097
    spells.ONSLAUGHT = 315720
    spells.BLOODBATH = 335096
    spells.IMPENDING_VICTORY = 202168
    
    -- Defensive abilities
    spells.ENRAGED_REGENERATION = 184364
    spells.IGNORE_PAIN = 190456
    spells.RALLYING_CRY = 97462
    spells.INTERVENE = 3411
    spells.SPELL_REFLECTION = 23920
    spells.BITTER_IMMUNITY = 383762
    spells.BERSERKER_RAGE = 18499
    
    -- Offensive cooldowns
    spells.RECKLESSNESS = 1719
    spells.AVATAR = 107574
    spells.THUNDEROUS_ROAR = 384318
    spells.RAVAGER = 228920
    spells.BLADESTORM = 46924
    
    -- Mobility/Utility
    spells.CHARGE = 100
    spells.HEROIC_LEAP = 6544
    spells.WRECKING_THROW = 384110
    spells.PUMMEL = 6552
    spells.INTIMIDATING_SHOUT = 5246
    spells.TAUNT = 355
    spells.HAMSTRING = 1715
    spells.CHALLENGING_SHOUT = 1161
    spells.PIERCING_HOWL = 12323
    spells.SHATTERING_THROW = 64382
    
    -- Talents and Passives
    spells.TITANS_TORMENT = 390135
    spells.FRENZY = 335077
    spells.SLAUGHTER = 329038
    spells.SUDDEN_DEATH = 280721
    spells.FRESH_MEAT = 215568
    spells.MEAT_CLEAVER = 280392
    spells.ANNIHILATOR = 383916
    spells.STORM_OF_STEEL = 388903
    spells.WRATH_AND_FURY = 392931
    spells.ASHEN_JUGGERNAUT = 392536
    spells.SPEAR_OF_BASTION = 376079
    spells.SIEGEBREAKER = 280772
    spells.BLOODLUST = 21562
    spells.OVERWHELMING_RAGE = 382767
    spells.FURIOUS_BLOODTHIRST = 383756
    spells.ODYN_FURY = 385059
    spells.DANCING_BLADES = 391683
    spells.SWIFTBLADE = 391677
    spells.RECKLESS_ABANDON = 396749
    spells.HACK_AND_SLASH = 383877
    spells.IMPROVED_WHIRLWIND = 12950
    spells.VICIOUS_STRIKES = 391698
    spells.COLD_STEEL_HOT_BLOOD = 383154
    spells.ACCUMULATED_RAGE = 383465
    spells.HONED_REFLEXES = 382841
    spells.ANGRY_WARRIOR = 385843
    spells.CRITICAL_THINKING = 383297
    spells.JUGGERNAUGHT = 383292
    spells.EXECUTIONERS_PRECISION = 386634
    spells.WARPAINT = 386285
    spells.FURIOUS_CHARGE = 202224
    spells.WILD_STRIKES = 382946
    spells.BATTLE_STANCE = 386164
    spells.BERSERKER_STANCE = 386196
    spells.DEFENSIVE_STANCE = 386208
    spells.CRUSHING_FORCE = 382764
    spells.RECKLESS_ABANDON = 396749
    spells.ANNIHILATOR = 383916
    spells.UNHINGED = 387139
    spells.BATTLELORD = 386630
    
    -- Covenant abilities (for reference, may not be current in War Within)
    spells.ANCIENT_AFTERSHOCK = 325886
    spells.SPEAR_OF_BASTION = 376079
    spells.CONQUERORS_BANNER = 324143
    
    -- Buff IDs
    spells.ENRAGE_BUFF = 184362
    spells.FRENZY_BUFF = 335082
    spells.WHIRLWIND_BUFF = 85739
    spells.RECKLESSNESS_BUFF = 1719
    spells.FURIOUS_CHARGE_BUFF = 202225
    spells.SUDDEN_DEATH_BUFF = 280776
    spells.VICTORIOUS_BUFF = 32216
    spells.ASHEN_JUGGERNAUT_BUFF = 392537
    spells.MEAT_CLEAVER_BUFF = 85739
    spells.EXECUTIONERS_PRECISION_BUFF = 386634
    spells.CRUSHING_FORCE_BUFF = 382764
    spells.RAGING_THIRST = 393951
    spells.JUGGERNAUT_BUFF = 383290
    spells.WRATH_AND_FURY_BUFF = 392931
    spells.DANCE_OF_DEATH = 391683
    spells.UNHINGED_BUFF = 387146
    spells.BATTLELORD_BUFF = 386631
    
    -- Register all spells with the API tracking system
    for spellName, spellID in pairs(spells) do
        API.RegisterSpell(spellID)
    end
    
    -- Define aura tracking
    buffs.ENRAGE = spells.ENRAGE_BUFF
    buffs.FRENZY = spells.FRENZY_BUFF
    buffs.WHIRLWIND = spells.WHIRLWIND_BUFF
    buffs.RECKLESSNESS = spells.RECKLESSNESS_BUFF
    buffs.FURIOUS_CHARGE = spells.FURIOUS_CHARGE_BUFF
    buffs.SUDDEN_DEATH = spells.SUDDEN_DEATH_BUFF
    buffs.VICTORIOUS = spells.VICTORIOUS_BUFF
    buffs.ASHEN_JUGGERNAUT = spells.ASHEN_JUGGERNAUT_BUFF
    buffs.MEAT_CLEAVER = spells.MEAT_CLEAVER_BUFF
    buffs.EXECUTIONERS_PRECISION = spells.EXECUTIONERS_PRECISION_BUFF
    buffs.CRUSHING_FORCE = spells.CRUSHING_FORCE_BUFF
    buffs.RAGING_THIRST = spells.RAGING_THIRST
    buffs.JUGGERNAUT = spells.JUGGERNAUT_BUFF
    buffs.WRATH_AND_FURY = spells.WRATH_AND_FURY_BUFF
    buffs.DANCE_OF_DEATH = spells.DANCE_OF_DEATH
    buffs.UNHINGED = spells.UNHINGED_BUFF
    buffs.BATTLELORD = spells.BATTLELORD_BUFF
    
    return true
end

-- Register variables to track
function Fury:RegisterVariables()
    -- Talent tracking
    talents.hasFrenzy = false
    talents.hasSlaughter = false
    talents.hasSuddenDeath = false
    talents.hasFreshMeat = false
    talents.hasMeatCleaver = false
    talents.hasTitansTorment = false
    talents.hasImprovedWhirlwind = false
    talents.hasStormOfSteel = false
    talents.hasWrathAndFury = false
    talents.hasAshenJuggernaut = false
    talents.hasSpearOfBastion = false
    talents.hasSiegebreaker = false
    talents.hasBloodlust = false
    talents.hasOverwhelmingRage = false
    talents.hasFuriousBloodthirst = false
    talents.hasOdynsFury = false
    talents.hasDancingBlades = false
    talents.hasSwiftblade = false
    talents.hasRecklessAbandon = false
    talents.hasHackAndSlash = false
    talents.hasViciousStrikes = false
    talents.hasColdSteelHotBlood = false
    talents.hasAccumulatedRage = false
    talents.hasHonedReflexes = false
    talents.hasAngryWarrior = false
    talents.hasCriticalThinking = false
    talents.hasJuggernaught = false
    talents.hasExecutionersPrecision = false
    talents.hasWarpaint = false
    talents.hasFuriousCharge = false
    talents.hasImpendingVictory = false
    talents.hasWildStrikes = false
    talents.hasBattleStance = false
    talents.hasBerserkerStance = false
    talents.hasDefensiveStance = false
    talents.hasCrushingForce = false
    talents.hasAnnihilator = false
    talents.hasUnhinged = false
    talents.hasBattlelord = false
    
    -- Initialize rage
    currentRage = API.GetPlayerPower()
    
    return true
end

-- Register spec-specific settings
function Fury:RegisterSettings()
    ConfigRegistry:RegisterSettings("FuryWarrior", {
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
            useExecute = {
                displayName = "Use Execute",
                description = "Use Execute during execute phase and with Sudden Death",
                type = "toggle",
                default = true
            },
            whirlwindStrategy = {
                displayName = "Whirlwind Strategy",
                description = "When to refresh Whirlwind buff",
                type = "dropdown",
                options = {"Maintain Always", "Only in AoE", "Refresh Early if AoE"},
                default = "Maintain Always"
            },
            useHamstring = {
                displayName = "Use Hamstring",
                description = "Automatically use Hamstring to slow enemies",
                type = "toggle",
                default = false
            }
        },
        
        defensiveSettings = {
            useEnragedRegeneration = {
                displayName = "Use Enraged Regeneration",
                description = "Automatically use Enraged Regeneration",
                type = "toggle",
                default = true
            },
            enragedRegenerationThreshold = {
                displayName = "Enraged Regeneration Threshold",
                description = "Health percentage to use Enraged Regeneration",
                type = "slider",
                min = 10,
                max = 60,
                default = 35
            },
            useIgnorePain = {
                displayName = "Use Ignore Pain",
                description = "Automatically use Ignore Pain",
                type = "toggle",
                default = true
            },
            ignorePainThreshold = {
                displayName = "Ignore Pain Threshold",
                description = "Health percentage to use Ignore Pain",
                type = "slider",
                min = 30,
                max = 80,
                default = 60
            },
            useRallyingCry = {
                displayName = "Use Rallying Cry",
                description = "Automatically use Rallying Cry",
                type = "toggle",
                default = true
            },
            rallyingCryThreshold = {
                displayName = "Rallying Cry Threshold",
                description = "Health percentage to use Rallying Cry",
                type = "slider",
                min = 10,
                max = 40,
                default = 25
            },
            useImpendingVictory = {
                displayName = "Use Impending Victory",
                description = "Automatically use Impending Victory when available",
                type = "toggle",
                default = true
            },
            impendingVictoryThreshold = {
                displayName = "Impending Victory Threshold",
                description = "Health percentage to use Impending Victory",
                type = "slider",
                min = 10,
                max = 80,
                default = 65
            },
            useBitterImmunity = {
                displayName = "Use Bitter Immunity",
                description = "Automatically use Bitter Immunity to remove effects",
                type = "toggle",
                default = true
            },
            useDefensiveStance = {
                displayName = "Use Defensive Stance",
                description = "Switch to Defensive Stance at low health",
                type = "toggle",
                default = true
            },
            defensiveStanceThreshold = {
                displayName = "Defensive Stance Threshold",
                description = "Health percentage to switch to Defensive Stance",
                type = "slider",
                min = 10,
                max = 60,
                default = 40
            }
        },
        
        offensiveSettings = {
            useRecklessness = {
                displayName = "Use Recklessness",
                description = "Automatically use Recklessness",
                type = "toggle",
                default = true
            },
            useAvatar = {
                displayName = "Use Avatar",
                description = "Automatically use Avatar",
                type = "toggle",
                default = true
            },
            useRavager = {
                displayName = "Use Ravager",
                description = "Automatically use Ravager when talented",
                type = "toggle",
                default = true
            },
            useBladestorm = {
                displayName = "Use Bladestorm",
                description = "Automatically use Bladestorm when talented",
                type = "toggle",
                default = true
            },
            bladestormTargets = {
                displayName = "Bladestorm Target Count",
                description = "Minimum targets to use Bladestorm",
                type = "slider",
                min = 1,
                max = 8,
                default = 3
            },
            useThunderousRoar = {
                displayName = "Use Thunderous Roar",
                description = "Automatically use Thunderous Roar",
                type = "toggle",
                default = true
            },
            useOnslaught = {
                displayName = "Use Onslaught",
                description = "Automatically use Onslaught when talented",
                type = "toggle",
                default = true
            }
        },
        
        covenantSettings = {
            useAncientAftershock = {
                displayName = "Use Ancient Aftershock",
                description = "Automatically use Ancient Aftershock",
                type = "toggle",
                default = true
            },
            useSpearOfBastion = {
                displayName = "Use Spear of Bastion",
                description = "Automatically use Spear of Bastion",
                type = "toggle",
                default = true
            },
            useConquerorsBanner = {
                displayName = "Use Conqueror's Banner",
                description = "Automatically use Conqueror's Banner",
                type = "toggle",
                default = true
            }
        },
        
        advancedSettings = {
            rampageRageThreshold = {
                displayName = "Rampage Rage Threshold",
                description = "Rage to trigger Rampage usage",
                type = "slider",
                min = RAMPAGE_COST,
                max = 100,
                default = RAMPAGE_COST
            },
            maintainEnrage = {
                displayName = "Maintain Enrage",
                description = "Prioritize keeping Enrage buff active",
                type = "toggle",
                default = true
            },
            poolRageForExecute = {
                displayName = "Pool Rage for Execute",
                description = "Save rage during execute phase",
                type = "toggle",
                default = true
            },
            executeRagePool = {
                displayName = "Execute Rage Pool",
                description = "Minimum rage to maintain for Execute",
                type = "slider",
                min = EXECUTE_COST,
                max = 60,
                default = 40
            },
            useRecklessnessWithEnrage = {
                displayName = "Recklessness with Enrage",
                description = "Only use Recklessness while Enraged",
                type = "toggle",
                default = false
            }
        },
        
        -- Advanced ability control settings
        abilityControls = {
            -- Recklessness controls
            recklessness = AAC.RegisterAbility(spells.RECKLESSNESS, {
                enabled = true,
                useDuringBurstOnly = true,
                useWithEnrage = false
            }),
            
            -- Bladestorm controls
            bladestorm = AAC.RegisterAbility(spells.BLADESTORM, {
                enabled = true,
                minEnemies = DEFAULT_AOE_THRESHOLD,
                useWithRecklessness = false
            }),
            
            -- Spear of Bastion controls
            spearOfBastion = AAC.RegisterAbility(spells.SPEAR_OF_BASTION, {
                enabled = true,
                useWithRecklessness = true,
                minEnemies = 1
            })
        }
    })
    
    return true
end

-- Register for events 
function Fury:RegisterEvents()
    -- Register for combat log events to track procs and buffs
    API.RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", function(...) 
        self:HandleCombatLogEvent(...) 
    end)
    
    -- Register for rage updates
    API.RegisterEvent("UNIT_POWER_FREQUENT", function(unit, powerType) 
        if unit == "player" and powerType == "RAGE" then
            self:UpdateRage()
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
function Fury:UpdateTalentInfo()
    -- Check for important talents
    talents.hasFrenzy = API.HasTalent(spells.FRENZY)
    talents.hasSlaughter = API.HasTalent(spells.SLAUGHTER)
    talents.hasSuddenDeath = API.HasTalent(spells.SUDDEN_DEATH)
    talents.hasFreshMeat = API.HasTalent(spells.FRESH_MEAT)
    talents.hasMeatCleaver = API.HasTalent(spells.MEAT_CLEAVER)
    talents.hasTitansTorment = API.HasTalent(spells.TITANS_TORMENT)
    talents.hasImprovedWhirlwind = API.HasTalent(spells.IMPROVED_WHIRLWIND)
    talents.hasStormOfSteel = API.HasTalent(spells.STORM_OF_STEEL)
    talents.hasWrathAndFury = API.HasTalent(spells.WRATH_AND_FURY)
    talents.hasAshenJuggernaut = API.HasTalent(spells.ASHEN_JUGGERNAUT)
    talents.hasSpearOfBastion = API.HasTalent(spells.SPEAR_OF_BASTION)
    talents.hasSiegebreaker = API.HasTalent(spells.SIEGEBREAKER)
    talents.hasBloodlust = API.HasTalent(spells.BLOODLUST)
    talents.hasOverwhelmingRage = API.HasTalent(spells.OVERWHELMING_RAGE)
    talents.hasFuriousBloodthirst = API.HasTalent(spells.FURIOUS_BLOODTHIRST)
    talents.hasOdynsFury = API.HasTalent(spells.ODYN_FURY)
    talents.hasDancingBlades = API.HasTalent(spells.DANCING_BLADES)
    talents.hasSwiftblade = API.HasTalent(spells.SWIFTBLADE)
    talents.hasRecklessAbandon = API.HasTalent(spells.RECKLESS_ABANDON)
    talents.hasHackAndSlash = API.HasTalent(spells.HACK_AND_SLASH)
    talents.hasViciousStrikes = API.HasTalent(spells.VICIOUS_STRIKES)
    talents.hasColdSteelHotBlood = API.HasTalent(spells.COLD_STEEL_HOT_BLOOD)
    talents.hasAccumulatedRage = API.HasTalent(spells.ACCUMULATED_RAGE)
    talents.hasHonedReflexes = API.HasTalent(spells.HONED_REFLEXES)
    talents.hasAngryWarrior = API.HasTalent(spells.ANGRY_WARRIOR)
    talents.hasCriticalThinking = API.HasTalent(spells.CRITICAL_THINKING)
    talents.hasJuggernaught = API.HasTalent(spells.JUGGERNAUGHT)
    talents.hasExecutionersPrecision = API.HasTalent(spells.EXECUTIONERS_PRECISION)
    talents.hasWarpaint = API.HasTalent(spells.WARPAINT)
    talents.hasFuriousCharge = API.HasTalent(spells.FURIOUS_CHARGE)
    talents.hasImpendingVictory = API.HasTalent(spells.IMPENDING_VICTORY)
    talents.hasWildStrikes = API.HasTalent(spells.WILD_STRIKES)
    talents.hasBattleStance = API.HasTalent(spells.BATTLE_STANCE)
    talents.hasBerserkerStance = API.HasTalent(spells.BERSERKER_STANCE)
    talents.hasDefensiveStance = API.HasTalent(spells.DEFENSIVE_STANCE)
    talents.hasCrushingForce = API.HasTalent(spells.CRUSHING_FORCE)
    talents.hasAnnihilator = API.HasTalent(spells.ANNIHILATOR)
    talents.hasUnhinged = API.HasTalent(spells.UNHINGED)
    talents.hasBattlelord = API.HasTalent(spells.BATTLELORD)
    
    API.PrintDebug("Fury Warrior talents updated")
    
    return true
end

-- Update rage tracking
function Fury:UpdateRage()
    currentRage = API.GetPlayerPower()
    return true
end

-- Update target data
function Fury:UpdateTargetData()
    -- Check if in melee range
    inMeleeRange = API.IsUnitInRange("target", 5) -- Check for melee range (5 yards)
    inRange5 = API.IsUnitInRange("target", 5)     -- 5-yard range check
    inRange8 = API.IsUnitInRange("target", 8)     -- 8-yard range check
    
    -- Update execute phase status
    if API.GetTargetHealthPercent() <= EXECUTE_THRESHOLD then
        inExecutePhase = true
    else
        inExecutePhase = false
    end
    
    -- Update AoE targets count
    currentAoETargets = API.GetNearbyEnemiesCount(8) -- Fury Warrior AoE radius
    
    return true
end

-- Handle combat log events
function Fury:HandleCombatLogEvent(...)
    local timestamp, eventType, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, spellID, spellName = CombatLogGetCurrentEventInfo()
    
    -- Only process events from the player
    if sourceGUID ~= API.GetPlayerGUID() then
        return false
    end
    
    -- Track buff applications
    if eventType == "SPELL_AURA_APPLIED" or eventType == "SPELL_AURA_REFRESH" then
        -- Track player buffs
        if destGUID == API.GetPlayerGUID() then
            -- Track Enrage
            if spellID == buffs.ENRAGE then
                enrageActive = true
                enrageEndTime = GetTime() + ENRAGE_DURATION
                API.PrintDebug("Enrage activated")
            end
            
            -- Track Frenzy
            if spellID == buffs.FRENZY then
                frenzyActive = true
                frenzyStacks = 1
                frenzyEndTime = GetTime() + 10 -- Frenzy lasts 10 seconds
                API.PrintDebug("Frenzy activated")
            end
            
            -- Track Whirlwind buff
            if spellID == buffs.WHIRLWIND then
                whirlwindBuff = true
                whirlwindBuffEndTime = GetTime() + WHIRLWIND_BUFF_DURATION
                API.PrintDebug("Whirlwind buff activated")
            end
            
            -- Track Recklessness
            if spellID == buffs.RECKLESSNESS then
                recklessnessActive = true
                recklessnessEndTime = GetTime() + RECKLESSNESS_DURATION
                API.PrintDebug("Recklessness activated")
            end
            
            -- Track Sudden Death
            if spellID == buffs.SUDDEN_DEATH then
                suddenDeathProc = true
                API.PrintDebug("Sudden Death proc activated")
            end
            
            -- Track Victorious
            if spellID == buffs.VICTORIOUS then
                API.PrintDebug("Victorious proc activated")
            end
            
            -- Track Ashen Juggernaut
            if spellID == buffs.ASHEN_JUGGERNAUT then
                API.PrintDebug("Ashen Juggernaut activated")
            end
            
            -- Track Meat Cleaver
            if spellID == buffs.MEAT_CLEAVER then
                meatCleaverStack = select(4, API.GetBuffInfo("player", buffs.MEAT_CLEAVER)) or 1
                API.PrintDebug("Meat Cleaver stacks: " .. tostring(meatCleaverStack))
            end
            
            -- Track Executioner's Precision
            if spellID == buffs.EXECUTIONERS_PRECISION then
                executionersPrecisionStacks = select(4, API.GetBuffInfo("player", buffs.EXECUTIONERS_PRECISION)) or 0
                API.PrintDebug("Executioner's Precision stacks: " .. tostring(executionersPrecisionStacks))
            end
            
            -- Track Crushing Force
            if spellID == buffs.CRUSHING_FORCE then
                crushingForceBuff = select(4, API.GetBuffInfo("player", buffs.CRUSHING_FORCE)) or 0
                API.PrintDebug("Crushing Force active: " .. tostring(crushingForceBuff))
            end
            
            -- Track Juggernaut
            if spellID == buffs.JUGGERNAUT then
                API.PrintDebug("Juggernaut stacks: " .. tostring(select(4, API.GetBuffInfo("player", buffs.JUGGERNAUT)) or 0))
            end
            
            -- Track Wrath and Fury
            if spellID == buffs.WRATH_AND_FURY then
                wrathandFuryActive = true
                API.PrintDebug("Wrath and Fury activated")
            end
            
            -- Track Unhinged
            if spellID == buffs.UNHINGED then
                unhingedActive = true
                API.PrintDebug("Unhinged activated")
            end
            
            -- Track Battlelord
            if spellID == buffs.BATTLELORD then
                battlelordActive = true
                API.PrintDebug("Battlelord activated")
            end
        end
    end
    
    -- Track buff removals
    if eventType == "SPELL_AURA_REMOVED" then
        -- Track player buffs
        if destGUID == API.GetPlayerGUID() then
            -- Track Enrage
            if spellID == buffs.ENRAGE then
                enrageActive = false
                API.PrintDebug("Enrage faded")
            end
            
            -- Track Frenzy
            if spellID == buffs.FRENZY then
                frenzyActive = false
                frenzyStacks = 0
                API.PrintDebug("Frenzy faded")
            end
            
            -- Track Whirlwind buff
            if spellID == buffs.WHIRLWIND then
                whirlwindBuff = false
                API.PrintDebug("Whirlwind buff faded")
            end
            
            -- Track Recklessness
            if spellID == buffs.RECKLESSNESS then
                recklessnessActive = false
                API.PrintDebug("Recklessness faded")
            end
            
            -- Track Sudden Death
            if spellID == buffs.SUDDEN_DEATH then
                suddenDeathProc = false
                API.PrintDebug("Sudden Death proc consumed")
            end
            
            -- Track Meat Cleaver
            if spellID == buffs.MEAT_CLEAVER then
                meatCleaverStack = 0
                API.PrintDebug("Meat Cleaver faded")
            end
            
            -- Track Executioner's Precision
            if spellID == buffs.EXECUTIONERS_PRECISION then
                executionersPrecisionStacks = 0
                API.PrintDebug("Executioner's Precision faded")
            end
            
            -- Track Crushing Force
            if spellID == buffs.CRUSHING_FORCE then
                crushingForceBuff = 0
                API.PrintDebug("Crushing Force faded")
            end
            
            -- Track Wrath and Fury
            if spellID == buffs.WRATH_AND_FURY then
                wrathandFuryActive = false
                API.PrintDebug("Wrath and Fury faded")
            end
            
            -- Track Unhinged
            if spellID == buffs.UNHINGED then
                unhingedActive = false
                API.PrintDebug("Unhinged faded")
            end
            
            -- Track Battlelord
            if spellID == buffs.BATTLELORD then
                battlelordActive = false
                API.PrintDebug("Battlelord faded")
            end
        end
    end
    
    -- Track Frenzy stacks
    if eventType == "SPELL_AURA_APPLIED_DOSE" and spellID == buffs.FRENZY and destGUID == API.GetPlayerGUID() then
        frenzyStacks = select(4, API.GetBuffInfo("player", buffs.FRENZY)) or 0
        API.PrintDebug("Frenzy stacks: " .. tostring(frenzyStacks))
    end
    
    -- Track spell casts
    if eventType == "SPELL_CAST_SUCCESS" and sourceGUID == API.GetPlayerGUID() then
        if spellID == spells.RAMPAGE then
            API.PrintDebug("Rampage cast")
        elseif spellID == spells.EXECUTE then
            API.PrintDebug("Execute cast")
        elseif spellID == spells.BLOODTHIRST then
            API.PrintDebug("Bloodthirst cast")
        elseif spellID == spells.RAGING_BLOW then
            API.PrintDebug("Raging Blow cast")
        elseif spellID == spells.SPEAR_OF_BASTION then
            spearActive = true
            -- Set a timer to track Spear duration
            C_Timer.After(4, function() -- Spear effect lasts ~4 seconds
                spearActive = false
                API.PrintDebug("Spear of Bastion effect ended")
            end)
            API.PrintDebug("Spear of Bastion cast")
        elseif spellID == spells.ANCIENT_AFTERSHOCK then
            ancientAftershock = true
            -- Set a timer to track Ancient Aftershock duration
            C_Timer.After(10, function() -- Ancient Aftershock lasts 10 seconds
                ancientAftershock = false
                API.PrintDebug("Ancient Aftershock ended")
            end)
            API.PrintDebug("Ancient Aftershock cast")
        elseif spellID == spells.ANNIHILATOR then
            annihilatorActive = true
            -- Set a timer to track Annihilator duration
            C_Timer.After(8, function() -- Approximate duration
                annihilatorActive = false
                API.PrintDebug("Annihilator effect ended")
            end)
            API.PrintDebug("Annihilator cast")
        end
    end
    
    return true
end

-- Main rotation function
function Fury:RunRotation()
    -- Check if we should be running Fury Warrior logic
    if API.GetActiveSpecID() ~= FURY_SPEC_ID then
        return false
    end
    
    -- Skip rotation if player is casting or channeling
    if API.IsPlayerCasting() or API.IsPlayerChanneling() then
        return false
    end
    
    -- Get settings
    local settings = ConfigRegistry:GetSettings("FuryWarrior")
    
    -- Update variables
    self:UpdateRage()
    burstModeActive = settings.rotationSettings.burstEnabled and API.ShouldUseBurst()
    self:UpdateTargetData() -- Update range and target data
    
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
    
    -- Check if we're in melee range
    if not inMeleeRange then
        -- Handle out of range abilities
        if self:HandleRangeGap() then
            return true
        end
        
        -- Skip rest of rotation if not in range and no gap closers available
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
function Fury:HandleInterrupts()
    -- Only attempt to interrupt if in range
    if inRange5 and API.CanCast(spells.PUMMEL) and API.TargetIsSpellCastable() then
        API.CastSpell(spells.PUMMEL)
        return true
    end
    
    return false
end

-- Handle defensive abilities
function Fury:HandleDefensives(settings)
    local playerHealth = API.GetPlayerHealthPercent()
    
    -- Use Enraged Regeneration when low on health
    if settings.defensiveSettings.useEnragedRegeneration and
       playerHealth <= settings.defensiveSettings.enragedRegenerationThreshold and
       API.CanCast(spells.ENRAGED_REGENERATION) then
        API.CastSpell(spells.ENRAGED_REGENERATION)
        return true
    end
    
    -- Use Ignore Pain for damage mitigation
    if settings.defensiveSettings.useIgnorePain and
       playerHealth <= settings.defensiveSettings.ignorePainThreshold and
       currentRage >= 40 and
       API.CanCast(spells.IGNORE_PAIN) then
        API.CastSpell(spells.IGNORE_PAIN)
        return true
    end
    
    -- Use Rallying Cry for group-wide defense
    if settings.defensiveSettings.useRallyingCry and
       playerHealth <= settings.defensiveSettings.rallyingCryThreshold and
       API.CanCast(spells.RALLYING_CRY) then
        API.CastSpell(spells.RALLYING_CRY)
        return true
    end
    
    -- Use Impending Victory for healing
    if talents.hasImpendingVictory and
       settings.defensiveSettings.useImpendingVictory and
       playerHealth <= settings.defensiveSettings.impendingVictoryThreshold and
       API.CanCast(spells.IMPENDING_VICTORY) and
       inMeleeRange then
        API.CastSpell(spells.IMPENDING_VICTORY)
        return true
    end
    
    -- Use Bitter Immunity to remove effects
    if settings.defensiveSettings.useBitterImmunity and
       API.CanCast(spells.BITTER_IMMUNITY) and
       API.PlayerHasDebuffType("Poison", "Disease", "Curse") then
        API.CastSpell(spells.BITTER_IMMUNITY)
        return true
    end
    
    -- Use Defensive Stance if health is low
    if talents.hasDefensiveStance and
       settings.defensiveSettings.useDefensiveStance and
       playerHealth <= settings.defensiveSettings.defensiveStanceThreshold and
       not API.PlayerHasBuff(spells.DEFENSIVE_STANCE) and
       API.CanCast(spells.DEFENSIVE_STANCE) then
        API.CastSpell(spells.DEFENSIVE_STANCE)
        return true
    end
    
    return false
end

-- Handle abilities to close range gap
function Fury:HandleRangeGap()
    -- Check for Charge
    if API.IsUnitInRange("target", 25) and API.CanCast(spells.CHARGE) then
        API.CastSpell(spells.CHARGE)
        return true
    end
    
    -- Check for Heroic Leap
    if API.CanCast(spells.HEROIC_LEAP) then
        API.CastSpellAtCursor(spells.HEROIC_LEAP)
        return true
    end
    
    -- Check for Wrecking Throw (ranged ability)
    if API.IsUnitInRange("target", 30) and 
       API.GetUnitDistance("target") >= WRECKING_THROW_MIN_RANGE and
       API.CanCast(spells.WRECKING_THROW) then
        API.CastSpell(spells.WRECKING_THROW)
        return true
    end
    
    return false
end

-- Handle cooldown abilities
function Fury:HandleCooldowns(settings)
    -- Skip if GCD is not ready
    if not API.IsGCDReady() then
        return false
    end
    
    -- Skip offensive cooldowns if not in burst mode
    if not burstModeActive then
        return false
    end
    
    -- Use Recklessness
    if settings.offensiveSettings.useRecklessness and
       settings.abilityControls.recklessness.enabled and
       API.CanCast(spells.RECKLESSNESS) then
        
        -- Check if we want to use with Enrage
        if not settings.advancedSettings.useRecklessnessWithEnrage or enrageActive then
            API.CastSpell(spells.RECKLESSNESS)
            return true
        end
    end
    
    -- Use Avatar
    if settings.offensiveSettings.useAvatar and
       API.CanCast(spells.AVATAR) then
        API.CastSpell(spells.AVATAR)
        return true
    end
    
    -- Use Bladestorm for AoE
    if settings.offensiveSettings.useBladestorm and
       settings.abilityControls.bladestorm.enabled and
       currentAoETargets >= settings.offensiveSettings.bladestormTargets and
       API.CanCast(spells.BLADESTORM) then
        
        -- Check if we want to use with Recklessness
        if not settings.abilityControls.bladestorm.useWithRecklessness or recklessnessActive then
            API.CastSpell(spells.BLADESTORM)
            return true
        end
    end
    
    -- Use Ravager
    if settings.offensiveSettings.useRavager and
       API.CanCast(spells.RAVAGER) then
        API.CastSpellAtCursor(spells.RAVAGER)
        return true
    end
    
    -- Use Thunderous Roar
    if settings.offensiveSettings.useThunderousRoar and
       API.CanCast(spells.THUNDEROUS_ROAR) then
        API.CastSpell(spells.THUNDEROUS_ROAR)
        return true
    end
    
    -- Use Onslaught
    if settings.offensiveSettings.useOnslaught and
       API.CanCast(spells.ONSLAUGHT) then
        API.CastSpell(spells.ONSLAUGHT)
        return true
    end
    
    -- Use covenant abilities
    if self:HandleCovenantAbilities(settings) then
        return true
    end
    
    return false
end

-- Handle covenant abilities
function Fury:HandleCovenantAbilities(settings)
    -- Use Spear of Bastion
    if talents.hasSpearOfBastion and
       settings.covenantSettings.useSpearOfBastion and
       settings.abilityControls.spearOfBastion.enabled and
       API.CanCast(spells.SPEAR_OF_BASTION) then
        
        -- Check if we want to use with Recklessness
        if not settings.abilityControls.spearOfBastion.useWithRecklessness or recklessnessActive then
            API.CastSpellAtCursor(spells.SPEAR_OF_BASTION)
            return true
        end
    end
    
    -- Use Ancient Aftershock
    if settings.covenantSettings.useAncientAftershock and
       API.CanCast(spells.ANCIENT_AFTERSHOCK) then
        API.CastSpell(spells.ANCIENT_AFTERSHOCK)
        return true
    end
    
    -- Use Conqueror's Banner
    if settings.covenantSettings.useConquerorsBanner and
       API.CanCast(spells.CONQUERORS_BANNER) then
        API.CastSpell(spells.CONQUERORS_BANNER)
        return true
    end
    
    return false
end

-- Handle AoE rotation
function Fury:HandleAoERotation(settings)
    -- Maintain Whirlwind buff for cleave
    if not whirlwindBuff and API.CanCast(spells.WHIRLWIND) then
        API.CastSpell(spells.WHIRLWIND)
        return true
    end
    
    -- Execute during execute phase or with Sudden Death proc
    if settings.rotationSettings.useExecute and API.CanCast(spells.EXECUTE) and
       ((inExecutePhase and currentRage >= EXECUTE_COST) or suddenDeathProc) then
        API.CastSpell(spells.EXECUTE)
        return true
    end
    
    -- Use Rampage to trigger Enrage if needed and we have enough rage
    if settings.advancedSettings.maintainEnrage and
       not enrageActive and
       currentRage >= settings.advancedSettings.rampageRageThreshold and
       API.CanCast(spells.RAMPAGE) then
        API.CastSpell(spells.RAMPAGE)
        return true
    end
    
    -- Use Bloodthirst to try and trigger Enrage
    if not enrageActive and API.CanCast(spells.BLOODTHIRST) then
        API.CastSpell(spells.BLOODTHIRST)
        return true
    end
    
    -- Use Raging Blow to generate rage 
    if API.CanCast(spells.RAGING_BLOW) then
        API.CastSpell(spells.RAGING_BLOW)
        return true
    end
    
    -- Use Bloodthirst for rage generation
    if API.CanCast(spells.BLOODTHIRST) then
        API.CastSpell(spells.BLOODTHIRST)
        return true
    end
    
    -- Use Whirlwind as filler
    if API.CanCast(spells.WHIRLWIND) then
        API.CastSpell(spells.WHIRLWIND)
        return true
    end
    
    -- Rampage to spend rage
    if currentRage >= settings.advancedSettings.rampageRageThreshold and API.CanCast(spells.RAMPAGE) then
        API.CastSpell(spells.RAMPAGE)
        return true
    end
    
    return false
end

-- Handle Single Target rotation
function Fury:HandleSingleTargetRotation(settings)
    -- Execute during execute phase or with Sudden Death proc
    if settings.rotationSettings.useExecute and API.CanCast(spells.EXECUTE) and
       ((inExecutePhase and currentRage >= EXECUTE_COST) or suddenDeathProc) then
        API.CastSpell(spells.EXECUTE)
        return true
    end
    
    -- Use Rampage to trigger Enrage if needed and we have enough rage
    if settings.advancedSettings.maintainEnrage and
       not enrageActive and
       currentRage >= settings.advancedSettings.rampageRageThreshold and
       API.CanCast(spells.RAMPAGE) then
        API.CastSpell(spells.RAMPAGE)
        return true
    end
    
    -- Use Rampage to spend rage once we reach threshold
    if currentRage >= settings.advancedSettings.rampageRageThreshold and API.CanCast(spells.RAMPAGE) then
        -- Skip if we're in execute phase and want to pool
        if not (inExecutePhase and settings.advancedSettings.poolRageForExecute and 
                currentRage < settings.advancedSettings.executeRagePool + RAMPAGE_COST) then
            API.CastSpell(spells.RAMPAGE)
            return true
        end
    end
    
    -- Use Bloodthirst to try and trigger Enrage
    if API.CanCast(spells.BLOODTHIRST) then
        API.CastSpell(spells.BLOODTHIRST)
        return true
    end
    
    -- Use Raging Blow to generate rage 
    if API.CanCast(spells.RAGING_BLOW) then
        API.CastSpell(spells.RAGING_BLOW)
        return true
    end
    
    -- Refresh Whirlwind buff if it's about to fade and we might AoE soon
    if settings.rotationSettings.whirlwindStrategy ~= "Only in AoE" and
       (not whirlwindBuff || (whirlwindBuffEndTime - GetTime() < 3)) and
       API.CanCast(spells.WHIRLWIND) then
        API.CastSpell(spells.WHIRLWIND)
        return true
    end
    
    -- Slam as filler
    if API.CanCast(spells.SLAM) then
        API.CastSpell(spells.SLAM)
        return true
    end
    
    return false
end

-- Handle specialization change
function Fury:OnSpecializationChanged()
    -- Update talent information
    self:UpdateTalentInfo()
    
    -- Reset state variables
    nextCastOverride = nil
    burstModeActive = false
    currentRage = API.GetPlayerPower()
    maxRage = 100
    enrageActive = false
    enrageEndTime = 0
    frenzyActive = false
    frenzyStacks = 0
    frenzyEndTime = 0
    whirlwindBuff = false 
    whirlwindBuffEndTime = 0
    recklessnessActive = false
    recklessnessEndTime = 0
    havocActive = false
    swordAndBoardProc = false
    swordAndBoardEndTime = 0
    inMeleeRange = false
    inExecutePhase = false
    suddenDeathProc = false
    inRange5 = false
    inRange8 = false
    rampageCharges = 0
    slaughterActive = false
    battlelordActive = false
    spearActive = false
    ancientAftershock = false
    annihilatorActive = false
    ragetimeCooldown = 0
    executionersPrecisionStacks = 0
    meatCleaverStack = 0
    recklesAbandon = false
    overpower = false
    viciousStrikes = false
    wrathandFuryActive = false
    unhingedActive = false
    crushingForceBuff = 0
    
    API.PrintDebug("Fury Warrior state reset on spec change")
    
    return true
end

-- Return the module for loading
return Fury