------------------------------------------
-- WindrunnerRotations - Protection Warrior Module
-- Author: VortexQ8
-- The War Within Season 2
------------------------------------------

local Protection = {}
-- This will be assigned to addon.Classes.Warrior.Protection when loaded

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
local shieldBlockActive = false
local shieldBlockEndTime = 0
local lastStandActive = false
local lastStandEndTime = 0
local ignorePainActive = false
local ignorePainEndTime = 0
local ignorePainValue = 0
local ignorePainMaxValue = 0
local demoShoutActive = false
local demoShoutEndTime = 0
local avatarActive = false
local avatarEndTime = 0
local shieldWallActive = false
local shieldWallEndTime = 0
local ravagerActive = false
local ravagerEndTime = 0
local thunderClapActive = false
local thunderClapEndTime = 0
local spearOfBastionActive = false
local spearOfBastionEndTime = 0
local ancientAftershockActive = false
local ancientAftershockEndTime = 0
local dragonRoarActive = false
local dragonRoarEndTime = 0
local recklessnessActive = false
local recklessnessEndTime = 0
local enragedRegenActive = false
local enragedRegenEndTime = 0
local berserkerRageActive = false
local berserkerRageEndTime = 0
local challengingShoutActive = false
local challengingShoutEndTime = 0
local spellReflectionActive = false
local spellReflectionEndTime = 0
local intImmuneActive = false
local intImmuneEndTime = 0
local rallyingCryActive = false
local rallyingCryEndTime = 0
local victoryRushAvailable = false
local shieldBlockCharges = 0
local shieldBlockMaxCharges = 0
local thunderClapCharges = 0
local thunderClapMaxCharges = 0
local revengeProc = false
local deepWounds = false
local deepWoundsActive = {}
local deepWoundsEndTime = {}
local suddenDeathProc = false
local suddenDeathEndTime = 0
local devastatorProc = false
local shieldSlamNoCooldown = false
local revenge = false
local devastate = false
local ignoreDevastate = true
local shieldSlam = false
local impendingVictory = false
local thunderClap = false
local devastator = false
local dragonRoar = false
local ravager = false
local battleShout = false
local execute = false
local demoralizingShout = false
local shieldCharge = false
local stalwartProtector = false
local heavyRepurcussions = false
local bestServedCold = false
local bolster = false
local burningWind = false
local focusInChaos = false
local unforgivingStandard = false
local seetheActive = false
local seetheEndTime = 0
local seetheStacks = 0
local intoTheFray = false
local intoTheFrayEndTime = 0
local intoTheFrayStacks = 0
local playerHealth = 100
local inMeleeRange = false
local bloodAndThunder = false
local revengeCDStacks = 0
local thunderousRoar = false
local bloodthirst = false
local titanStrike = false
local titanicsRage = false
local rallyingCry = false
local battleRoar = false
local enrageExhaust = false
local limitlessRage = false
local executePact = false
local colossusSmash = false
local bleedStorm = false
local berserker = false

-- Constants
local PROTECTION_SPEC_ID = 73
local DEFAULT_AOE_THRESHOLD = 3
local SHIELD_BLOCK_DURATION = 6 -- seconds
local LAST_STAND_DURATION = 15 -- seconds
local IGNORE_PAIN_DURATION = 12 -- seconds
local DEMO_SHOUT_DURATION = 15 -- seconds
local AVATAR_DURATION = 20 -- seconds
local SHIELD_WALL_DURATION = 15 -- seconds
local RAVAGER_DURATION = 12 -- seconds
local THUNDER_CLAP_DURATION = 6 -- seconds
local SPEAR_OF_BASTION_DURATION = 4 -- seconds
local ANCIENT_AFTERSHOCK_DURATION = 12 -- seconds
local DRAGON_ROAR_DURATION = 6 -- seconds
local RECKLESSNESS_DURATION = 12 -- seconds
local ENRAGED_REGEN_DURATION = 8 -- seconds
local BERSERKER_RAGE_DURATION = 12 -- seconds
local CHALLENGING_SHOUT_DURATION = 6 -- seconds
local SPELL_REFLECTION_DURATION = 5 -- seconds
local DEEP_WOUNDS_DURATION = 12 -- seconds (base duration)
local MELEE_RANGE = 5 -- yards

-- Initialize the Protection module
function Protection:Initialize()
    self:RegisterSpells()
    self:RegisterVariables()
    self:RegisterSettings()
    self:RegisterEvents()
    
    API.PrintDebug("Protection Warrior module initialized")
    
    return true
end

-- Register spell IDs
function Protection:RegisterSpells()
    -- Core rotational abilities
    spells.SHIELD_SLAM = 23922
    spells.REVENGE = 6572
    spells.THUNDER_CLAP = 6343
    spells.DEVASTATE = 20243
    spells.EXECUTE = 163201
    spells.IMPENDING_VICTORY = 202168
    spells.VICTORY_RUSH = 34428
    spells.DRAGON_ROAR = 118000
    spells.RAVAGER = 228920
    spells.SHOCKWAVE = 46968
    spells.STORM_BOLT = 107570
    
    -- Core defensives
    spells.SHIELD_BLOCK = 2565
    spells.IGNORE_PAIN = 190456
    spells.LAST_STAND = 12975
    spells.SHIELD_WALL = 871
    spells.SPELL_REFLECTION = 23920
    spells.INTIMIDATING_SHOUT = 5246
    spells.RALLYING_CRY = 97462
    spells.DEMORALIZING_SHOUT = 1160
    
    -- Core utilities
    spells.BATTLE_SHOUT = 6673
    spells.CHALLENGING_SHOUT = 1161
    spells.HEROIC_THROW = 57755
    spells.TAUNT = 355
    spells.INTERVENE = 3411
    spells.INTERVENE_FRIENDLY = 3411
    spells.BERSERKER_RAGE = 18499
    spells.PUMMEL = 6552
    spells.CHARGE = 100
    spells.HEROIC_LEAP = 6544
    spells.AVATAR = 107574
    spells.ENRAGED_REGENERATION = 184364
    
    -- Talents and passives
    spells.DEEP_WOUNDS = 115767
    spells.DEVASTATOR = 236279
    spells.UNSTOPPABLE_FORCE = 275336
    spells.BOLSTER = 280001
    spells.BEST_SERVED_COLD = 202560
    spells.BOOMING_VOICE = 202743
    spells.HEAVY_REPERCUSSIONS = 203177
    spells.RUMBLING_EARTH = 275339
    spells.BRACE_FOR_IMPACT = 275334
    spells.SUDDEN_DEATH = 29725
    spells.SHIELD_DISCIPLINE = 197488
    spells.CRACKLING_THUNDER = 203201
    spells.INTO_THE_FRAY = 202603
    spells.MENACE = 275338
    spells.NEVER_SURRENDER = 202561
    spells.SHIELD_CHARGE = 385952
    spells.STALWART_PROTECTOR = 386285
    spells.BLOOD_AND_THUNDER = 384318
    spells.UNNERVING_FOCUS = 384042
    spells.PUNISH = 275334
    spells.BLOODTHIRST = 23881
    spells.JUGGERNAUT = 383292
    spells.BARBARIC_TRAINING = 383287
    spells.TITANS_TORMENT = 390135
    spells.CONCUSSIVE_BLOWS = 383115
    spells.BATTLE_STANCE = 386164
    spells.DEFENSIVE_STANCE = 386208
    spells.SPEAR_OF_BASTION = 376079
    spells.THUNDEROUS_ROAR = 384318
    spells.TITANIC_THROW = 384090
    spells.TITANIC_RAGE = 394329
    spells.BERSERKER_SHOUT = 384100
    spells.BLOODBORNE = 385703
    spells.BATTLE_ROAR = 403380
    spells.ENRAGE_EXHAUSTION = 383478
    spells.LIMITLESS_RAGE = 383292
    spells.EXECUTE_PACT = 385843
    spells.TITANS_STRIKE = 390301
    spells.COLOSSUS_SMASH = 167105
    spells.ENRAGED_REGENERATION = 184364
    spells.BLOODLETTING = 383154
    spells.BURNING_WOUND = 383157
    spells.FOCUS_IN_CHAOS = 383459
    spells.BLEED_STORM = 383154
    spells.UNFORGIVING_STANDARD = 390675
    
    -- War Within Season 2 specific
    spells.BERSERKER = 385391
    spells.BLOODTHIRST_BONUS = 23880
    spells.BURNING_WINDS = 384267
    spells.CONSUMING_RAGE = 383847
    spells.FRENZIED_BERSERKER = 387139
    spells.ONSLAUGHT = 315720
    spells.RAGE_OVERCAP = 385738
    spells.REINFORCED_PLATES = 392530
    spells.SEETHE = 394329
    spells.STORM_OF_STEEL = 382953
    spells.SWIFT_STRIKES = 383459
    spells.TACTICIAN = 184783
    spells.TENDERIZE = 388933
    spells.WILD_SWINGS = 390148
    
    -- Covenant abilities (for reference, converted in WoW 10.0)
    spells.ANCIENT_AFTERSHOCK = 325886
    spells.CONDEMN = 317349
    spells.CONQUERORS_BANNER = 324143
    spells.SPEAR_OF_BASTION = 376079
    
    -- Buff IDs
    spells.SHIELD_BLOCK_BUFF = 132404
    spells.IGNORE_PAIN_BUFF = 190456
    spells.LAST_STAND_BUFF = 12975
    spells.SHIELD_WALL_BUFF = 871
    spells.AVATAR_BUFF = 107574
    spells.REVENGE_BUFF = 5302
    spells.SUDDEN_DEATH_BUFF = 52437
    spells.SPELL_REFLECTION_BUFF = 23920
    spells.BATTLE_SHOUT_BUFF = 6673
    spells.RALLYING_CRY_BUFF = 97463
    spells.DEMORALIZING_SHOUT_BUFF = 1160
    spells.BERSERKER_RAGE_BUFF = 18499
    spells.ENRAGED_REGENERATION_BUFF = 184364
    spells.RAVAGER_BUFF = 228920
    spells.DRAGON_ROAR_BUFF = 118000
    spells.INTO_THE_FRAY_BUFF = 202603
    spells.SEETHE_BUFF = 394330
    
    -- Debuff IDs
    spells.DEEP_WOUNDS_DEBUFF = 115767
    spells.DEMORALIZING_SHOUT_DEBUFF = 1160
    spells.THUNDER_CLAP_DEBUFF = 6343
    spells.CONCUSSIVE_BLOWS_DEBUFF = 383116
    
    -- Register all spells with the API tracking system
    for spellName, spellID in pairs(spells) do
        API.RegisterSpell(spellID)
    end
    
    -- Define aura tracking
    buffs.SHIELD_BLOCK = spells.SHIELD_BLOCK_BUFF
    buffs.IGNORE_PAIN = spells.IGNORE_PAIN_BUFF
    buffs.LAST_STAND = spells.LAST_STAND_BUFF
    buffs.SHIELD_WALL = spells.SHIELD_WALL_BUFF
    buffs.AVATAR = spells.AVATAR_BUFF
    buffs.REVENGE = spells.REVENGE_BUFF
    buffs.SUDDEN_DEATH = spells.SUDDEN_DEATH_BUFF
    buffs.SPELL_REFLECTION = spells.SPELL_REFLECTION_BUFF
    buffs.BATTLE_SHOUT = spells.BATTLE_SHOUT_BUFF
    buffs.RALLYING_CRY = spells.RALLYING_CRY_BUFF
    buffs.DEMORALIZING_SHOUT = spells.DEMORALIZING_SHOUT_BUFF
    buffs.BERSERKER_RAGE = spells.BERSERKER_RAGE_BUFF
    buffs.ENRAGED_REGENERATION = spells.ENRAGED_REGENERATION_BUFF
    buffs.RAVAGER = spells.RAVAGER_BUFF
    buffs.DRAGON_ROAR = spells.DRAGON_ROAR_BUFF
    buffs.INTO_THE_FRAY = spells.INTO_THE_FRAY_BUFF
    buffs.SEETHE = spells.SEETHE_BUFF
    
    debuffs.DEEP_WOUNDS = spells.DEEP_WOUNDS_DEBUFF
    debuffs.DEMORALIZING_SHOUT = spells.DEMORALIZING_SHOUT_DEBUFF
    debuffs.THUNDER_CLAP = spells.THUNDER_CLAP_DEBUFF
    debuffs.CONCUSSIVE_BLOWS = spells.CONCUSSIVE_BLOWS_DEBUFF
    
    return true
end

-- Register variables to track
function Protection:RegisterVariables()
    -- Talent tracking
    talents.hasDeepWounds = false
    talents.hasDevastator = false
    talents.hasUnstoppableForce = false
    talents.hasBolster = false
    talents.hasBestServedCold = false
    talents.hasBoomingVoice = false
    talents.hasHeavyRepercussions = false
    talents.hasRumblingEarth = false
    talents.hasBraceForImpact = false
    talents.hasSuddenDeath = false
    talents.hasShieldDiscipline = false
    talents.hasCracklingThunder = false
    talents.hasIntoTheFray = false
    talents.hasMenace = false
    talents.hasNeverSurrender = false
    talents.hasShieldCharge = false
    talents.hasStalwartProtector = false
    talents.hasBloodAndThunder = false
    talents.hasUnnervingFocus = false
    talents.hasPunish = false
    talents.hasBloodthirst = false
    talents.hasJuggernaut = false
    talents.hasBarbaricTraining = false
    talents.hasTitansTorment = false
    talents.hasConcussiveBlows = false
    talents.hasBattleStance = false
    talents.hasDefensiveStance = false
    talents.hasSpearOfBastion = false
    talents.hasThunderousRoar = false
    talents.hasTitanicThrow = false
    talents.hasTitanicRage = false
    talents.hasBerserkerShout = false
    talents.hasBloodborne = false
    talents.hasBattleRoar = false
    talents.hasEnrageExhaustion = false
    talents.hasLimitlessRage = false
    talents.hasExecutePact = false
    talents.hasTitansStrike = false
    talents.hasColossusSmash = false
    talents.hasEnragedRegeneration = false
    talents.hasBloodletting = false
    talents.hasBurningWound = false
    talents.hasFocusInChaos = false
    talents.hasBleedStorm = false
    talents.hasUnforgivingStandard = false
    
    -- War Within Season 2 talents
    talents.hasBerserker = false
    talents.hasBloodthirstBonus = false
    talents.hasBurningWinds = false
    talents.hasConsumingRage = false
    talents.hasFrenziedBerserker = false
    talents.hasOnslaught = false
    talents.hasRageOvercap = false
    talents.hasReinforcedPlates = false
    talents.hasSeethe = false
    talents.hasStormOfSteel = false
    talents.hasSwiftStrikes = false
    talents.hasTactician = false
    talents.hasTenderize = false
    talents.hasWildSwings = false
    
    -- Initialize rage
    currentRage = API.GetPlayerPower()
    
    -- Initialize spell charges
    shieldBlockCharges = API.GetSpellCharges(spells.SHIELD_BLOCK) or 0
    shieldBlockMaxCharges = API.GetSpellMaxCharges(spells.SHIELD_BLOCK) or 2
    thunderClapCharges = API.GetSpellCharges(spells.THUNDER_CLAP) or 0
    thunderClapMaxCharges = API.GetSpellMaxCharges(spells.THUNDER_CLAP) or 1
    
    -- Initialize Deep Wounds tracking
    deepWoundsActive = {}
    deepWoundsEndTime = {}
    
    return true
end

-- Register spec-specific settings
function Protection:RegisterSettings()
    ConfigRegistry:RegisterSettings("ProtectionWarrior", {
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
            useRevengeOnProc = {
                displayName = "Use Revenge on Proc",
                description = "Prioritize Revenge when it's free",
                type = "toggle",
                default = true
            },
            revengePrioWithRage = {
                displayName = "Revenge Priority with Rage",
                description = "When to use Revenge when it costs Rage",
                type = "dropdown",
                options = {"Never", "AoE Only", "Always"},
                default = "AoE Only"
            },
            ragePooling = {
                displayName = "Rage Pooling",
                description = "Pool rage for defensive abilities",
                type = "toggle",
                default = true
            },
            ragePoolingThreshold = {
                displayName = "Rage Pooling Threshold",
                description = "Minimum rage to maintain",
                type = "slider",
                min = 10,
                max = 70,
                default = 40
            },
            useExecute = {
                displayName = "Use Execute",
                description = "Automatically use Execute when available",
                type = "toggle",
                default = true
            },
            executeThreshold = {
                displayName = "Execute Rage Threshold",
                description = "Minimum rage to use Execute",
                type = "slider",
                min = 20,
                max = 70,
                default = 50
            }
        },
        
        defensiveSettings = {
            useShieldBlock = {
                displayName = "Use Shield Block",
                description = "Automatically use Shield Block",
                type = "toggle",
                default = true
            },
            shieldBlockChargesReserved = {
                displayName = "Shield Block Charges Reserved",
                description = "Charges to save for emergencies",
                type = "slider",
                min = 0,
                max = 2,
                default = 1
            },
            useIgnorePain = {
                displayName = "Use Ignore Pain",
                description = "Automatically use Ignore Pain",
                type = "toggle",
                default = true
            },
            ignorePainMinRage = {
                displayName = "Ignore Pain Minimum Rage",
                description = "Minimum rage to use Ignore Pain",
                type = "slider",
                min = 20,
                max = 60,
                default = 40
            },
            useLastStand = {
                displayName = "Use Last Stand",
                description = "Automatically use Last Stand",
                type = "toggle",
                default = true
            },
            lastStandThreshold = {
                displayName = "Last Stand Health Threshold",
                description = "Health percentage to use Last Stand",
                type = "slider",
                min = 10,
                max = 50,
                default = 30
            },
            useShieldWall = {
                displayName = "Use Shield Wall",
                description = "Automatically use Shield Wall",
                type = "toggle",
                default = true
            },
            shieldWallThreshold = {
                displayName = "Shield Wall Health Threshold",
                description = "Health percentage to use Shield Wall",
                type = "slider",
                min = 10,
                max = 50,
                default = 20
            },
            useSpellReflection = {
                displayName = "Use Spell Reflection",
                description = "Automatically use Spell Reflection",
                type = "toggle",
                default = true
            },
            useRallyingCry = {
                displayName = "Use Rallying Cry",
                description = "Automatically use Rallying Cry",
                type = "toggle",
                default = true
            },
            rallyingCryThreshold = {
                displayName = "Rallying Cry Health Threshold",
                description = "Health percentage to use Rallying Cry",
                type = "slider",
                min = 10,
                max = 50,
                default = 30
            }
        },
        
        utilitySettings = {
            useHeroicThrow = {
                displayName = "Use Heroic Throw",
                description = "Automatically use Heroic Throw for pulling",
                type = "toggle",
                default = true
            },
            useCharge = {
                displayName = "Use Charge",
                description = "Automatically use Charge to gap close",
                type = "toggle",
                default = true
            },
            useBattleShout = {
                displayName = "Use Battle Shout",
                description = "Automatically maintain Battle Shout",
                type = "toggle",
                default = true
            },
            useDemoralizingShout = {
                displayName = "Use Demoralizing Shout",
                description = "Automatically use Demoralizing Shout",
                type = "toggle",
                default = true
            },
            demoralizingShoutThreshold = {
                displayName = "Demoralizing Shout Target Count",
                description = "Minimum targets to use Demoralizing Shout",
                type = "slider",
                min = 1,
                max = 5,
                default = 1
            },
            useIntimidatingShout = {
                displayName = "Use Intimidating Shout",
                description = "Automatically use Intimidating Shout for AoE fear",
                type = "toggle",
                default = true
            },
            intimidatingShoutThreshold = {
                displayName = "Intimidating Shout Target Count",
                description = "Minimum targets to use Intimidating Shout",
                type = "slider",
                min = 2,
                max = 6,
                default = 3
            },
            useChallengingShout = {
                displayName = "Use Challenging Shout",
                description = "Automatically use Challenging Shout for AoE taunt",
                type = "toggle",
                default = true
            },
            challengingShoutThreshold = {
                displayName = "Challenging Shout Target Count",
                description = "Minimum targets to use Challenging Shout",
                type = "slider",
                min = 2,
                max = 6,
                default = 3
            }
        },
        
        cooldownSettings = {
            useAvatar = {
                displayName = "Use Avatar",
                description = "Automatically use Avatar",
                type = "toggle",
                default = true
            },
            avatarMode = {
                displayName = "Avatar Usage",
                description = "When to use Avatar",
                type = "dropdown",
                options = {"On Cooldown", "With Defensives", "Burst Only"},
                default = "On Cooldown"
            },
            useRavager = {
                displayName = "Use Ravager",
                description = "Automatically use Ravager when talented",
                type = "toggle",
                default = true
            },
            ravagerMode = {
                displayName = "Ravager Placement",
                description = "Where to place Ravager",
                type = "dropdown",
                options = {"At Cursor", "On Self", "On Target"},
                default = "On Target"
            },
            useSpearOfBastion = {
                displayName = "Use Spear of Bastion",
                description = "Automatically use Spear of Bastion when talented",
                type = "toggle",
                default = true
            },
            spearOfBastionMode = {
                displayName = "Spear of Bastion Placement",
                description = "Where to place Spear of Bastion",
                type = "dropdown",
                options = {"At Cursor", "On Self", "On Target"},
                default = "On Target"
            },
            useAncientAftershock = {
                displayName = "Use Ancient Aftershock",
                description = "Automatically use Ancient Aftershock when talented",
                type = "toggle",
                default = true
            },
            ancientAftershockMinTargets = {
                displayName = "Ancient Aftershock Min Targets",
                description = "Minimum targets to use Ancient Aftershock",
                type = "slider",
                min = 1,
                max = 6,
                default = 3
            }
        },
        
        ccSettings = {
            useShockwave = {
                displayName = "Use Shockwave",
                description = "Automatically use Shockwave for AoE stun",
                type = "toggle",
                default = true
            },
            shockwaveThreshold = {
                displayName = "Shockwave Target Count",
                description = "Minimum targets to use Shockwave",
                type = "slider",
                min = 2,
                max = 6,
                default = 3
            },
            useStormBolt = {
                displayName = "Use Storm Bolt",
                description = "Automatically use Storm Bolt when talented",
                type = "toggle",
                default = true
            },
            stormBoltMode = {
                displayName = "Storm Bolt Usage",
                description = "When to use Storm Bolt",
                type = "dropdown",
                options = {"On Cooldown", "Interrupt Only", "Manual Only"},
                default = "Interrupt Only"
            }
        },
        
        -- Advanced ability control settings
        abilityControls = {
            -- Shield Block controls
            shieldBlock = AAC.RegisterAbility(spells.SHIELD_BLOCK, {
                enabled = true,
                useDuringBurstOnly = false,
                minRage = 30,
                minIncomingDamage = 20
            }),
            
            -- Ignore Pain controls
            ignorePain = AAC.RegisterAbility(spells.IGNORE_PAIN, {
                enabled = true,
                useDuringBurstOnly = false,
                minRage = 40,
                minIncomingDamage = 15
            }),
            
            -- Last Stand controls
            lastStand = AAC.RegisterAbility(spells.LAST_STAND, {
                enabled = true,
                useDuringBurstOnly = false,
                minHealthPercent = 30,
                maxHealthPercent = 60
            })
        }
    })
    
    return true
end

-- Register for events 
function Protection:RegisterEvents()
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
    
    -- Register for health updates
    API.RegisterEvent("UNIT_HEALTH", function(unit) 
        if unit == "player" then
            self:UpdateHealth()
        end
    end)
    
    -- Register for spell cast events
    API.RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", function(unit, _, spellID)
        if unit == "player" then
            self:HandleSpellCastSucceeded(spellID)
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
function Protection:UpdateTalentInfo()
    -- Check for important talents
    talents.hasDeepWounds = API.HasTalent(spells.DEEP_WOUNDS)
    talents.hasDevastator = API.HasTalent(spells.DEVASTATOR)
    talents.hasUnstoppableForce = API.HasTalent(spells.UNSTOPPABLE_FORCE)
    talents.hasBolster = API.HasTalent(spells.BOLSTER)
    talents.hasBestServedCold = API.HasTalent(spells.BEST_SERVED_COLD)
    talents.hasBoomingVoice = API.HasTalent(spells.BOOMING_VOICE)
    talents.hasHeavyRepercussions = API.HasTalent(spells.HEAVY_REPERCUSSIONS)
    talents.hasRumblingEarth = API.HasTalent(spells.RUMBLING_EARTH)
    talents.hasBraceForImpact = API.HasTalent(spells.BRACE_FOR_IMPACT)
    talents.hasSuddenDeath = API.HasTalent(spells.SUDDEN_DEATH)
    talents.hasShieldDiscipline = API.HasTalent(spells.SHIELD_DISCIPLINE)
    talents.hasCracklingThunder = API.HasTalent(spells.CRACKLING_THUNDER)
    talents.hasIntoTheFray = API.HasTalent(spells.INTO_THE_FRAY)
    talents.hasMenace = API.HasTalent(spells.MENACE)
    talents.hasNeverSurrender = API.HasTalent(spells.NEVER_SURRENDER)
    talents.hasShieldCharge = API.HasTalent(spells.SHIELD_CHARGE)
    talents.hasStalwartProtector = API.HasTalent(spells.STALWART_PROTECTOR)
    talents.hasBloodAndThunder = API.HasTalent(spells.BLOOD_AND_THUNDER)
    talents.hasUnnervingFocus = API.HasTalent(spells.UNNERVING_FOCUS)
    talents.hasPunish = API.HasTalent(spells.PUNISH)
    talents.hasBloodthirst = API.HasTalent(spells.BLOODTHIRST)
    talents.hasJuggernaut = API.HasTalent(spells.JUGGERNAUT)
    talents.hasBarbaricTraining = API.HasTalent(spells.BARBARIC_TRAINING)
    talents.hasTitansTorment = API.HasTalent(spells.TITANS_TORMENT)
    talents.hasConcussiveBlows = API.HasTalent(spells.CONCUSSIVE_BLOWS)
    talents.hasBattleStance = API.HasTalent(spells.BATTLE_STANCE)
    talents.hasDefensiveStance = API.HasTalent(spells.DEFENSIVE_STANCE)
    talents.hasSpearOfBastion = API.HasTalent(spells.SPEAR_OF_BASTION)
    talents.hasThunderousRoar = API.HasTalent(spells.THUNDEROUS_ROAR)
    talents.hasTitanicThrow = API.HasTalent(spells.TITANIC_THROW)
    talents.hasTitanicRage = API.HasTalent(spells.TITANIC_RAGE)
    talents.hasBerserkerShout = API.HasTalent(spells.BERSERKER_SHOUT)
    talents.hasBloodborne = API.HasTalent(spells.BLOODBORNE)
    talents.hasBattleRoar = API.HasTalent(spells.BATTLE_ROAR)
    talents.hasEnrageExhaustion = API.HasTalent(spells.ENRAGE_EXHAUSTION)
    talents.hasLimitlessRage = API.HasTalent(spells.LIMITLESS_RAGE)
    talents.hasExecutePact = API.HasTalent(spells.EXECUTE_PACT)
    talents.hasTitansStrike = API.HasTalent(spells.TITANS_STRIKE)
    talents.hasColossusSmash = API.HasTalent(spells.COLOSSUS_SMASH)
    talents.hasEnragedRegeneration = API.HasTalent(spells.ENRAGED_REGENERATION)
    talents.hasBloodletting = API.HasTalent(spells.BLOODLETTING)
    talents.hasBurningWound = API.HasTalent(spells.BURNING_WOUND)
    talents.hasFocusInChaos = API.HasTalent(spells.FOCUS_IN_CHAOS)
    talents.hasBleedStorm = API.HasTalent(spells.BLEED_STORM)
    talents.hasUnforgivingStandard = API.HasTalent(spells.UNFORGIVING_STANDARD)
    
    -- War Within Season 2 talents
    talents.hasBerserker = API.HasTalent(spells.BERSERKER)
    talents.hasBloodthirstBonus = API.HasTalent(spells.BLOODTHIRST_BONUS)
    talents.hasBurningWinds = API.HasTalent(spells.BURNING_WINDS)
    talents.hasConsumingRage = API.HasTalent(spells.CONSUMING_RAGE)
    talents.hasFrenziedBerserker = API.HasTalent(spells.FRENZIED_BERSERKER)
    talents.hasOnslaught = API.HasTalent(spells.ONSLAUGHT)
    talents.hasRageOvercap = API.HasTalent(spells.RAGE_OVERCAP)
    talents.hasReinforcedPlates = API.HasTalent(spells.REINFORCED_PLATES)
    talents.hasSeethe = API.HasTalent(spells.SEETHE)
    talents.hasStormOfSteel = API.HasTalent(spells.STORM_OF_STEEL)
    talents.hasSwiftStrikes = API.HasTalent(spells.SWIFT_STRIKES)
    talents.hasTactician = API.HasTalent(spells.TACTICIAN)
    talents.hasTenderize = API.HasTalent(spells.TENDERIZE)
    talents.hasWildSwings = API.HasTalent(spells.WILD_SWINGS)
    
    -- Set specialized variables based on talents
    if talents.hasDeepWounds then
        deepWounds = true
    end
    
    if API.IsSpellKnown(spells.REVENGE) then
        revenge = true
    end
    
    if API.IsSpellKnown(spells.DEVASTATE) then
        devastate = true
    end
    
    if talents.hasDevastator then
        devastator = true
        ignoreDevastate = true
    else
        ignoreDevastate = false
    end
    
    if API.IsSpellKnown(spells.SHIELD_SLAM) then
        shieldSlam = true
    end
    
    if API.IsSpellKnown(spells.IMPENDING_VICTORY) then
        impendingVictory = true
    end
    
    if API.IsSpellKnown(spells.THUNDER_CLAP) then
        thunderClap = true
    end
    
    if API.IsSpellKnown(spells.DRAGON_ROAR) then
        dragonRoar = true
    end
    
    if API.IsSpellKnown(spells.RAVAGER) then
        ravager = true
    end
    
    if API.IsSpellKnown(spells.BATTLE_SHOUT) then
        battleShout = true
    end
    
    if API.IsSpellKnown(spells.EXECUTE) then
        execute = true
    end
    
    if API.IsSpellKnown(spells.DEMORALIZING_SHOUT) then
        demoralizingShout = true
    end
    
    if talents.hasShieldCharge then
        shieldCharge = true
    end
    
    if talents.hasStalwartProtector then
        stalwartProtector = true
    end
    
    if talents.hasHeavyRepercussions then
        heavyRepurcussions = true
    end
    
    if talents.hasBestServedCold then
        bestServedCold = true
    end
    
    if talents.hasBolster then
        bolster = true
    end
    
    if talents.hasBurningWound then
        burningWind = true
    end
    
    if talents.hasFocusInChaos then
        focusInChaos = true
    end
    
    if talents.hasUnforgivingStandard then
        unforgivingStandard = true
    end
    
    if talents.hasIntoTheFray then
        intoTheFray = true
    end
    
    if talents.hasBloodAndThunder then
        bloodAndThunder = true
    end
    
    if talents.hasThunderousRoar then
        thunderousRoar = true
    end
    
    if talents.hasBloodthirst then
        bloodthirst = true
    end
    
    if talents.hasTitansStrike then
        titanStrike = true
    end
    
    if talents.hasTitanicRage then
        titanicsRage = true
    end
    
    if API.IsSpellKnown(spells.RALLYING_CRY) then
        rallyingCry = true
    end
    
    if talents.hasBattleRoar then
        battleRoar = true
    end
    
    if talents.hasEnrageExhaustion then
        enrageExhaust = true
    end
    
    if talents.hasLimitlessRage then
        limitlessRage = true
    end
    
    if talents.hasExecutePact then
        executePact = true
    end
    
    if talents.hasColossusSmash then
        colossusSmash = true
    end
    
    if talents.hasBleedStorm then
        bleedStorm = true
    end
    
    if talents.hasBerserker then
        berserker = true
    end
    
    API.PrintDebug("Protection Warrior talents updated")
    
    return true
end

-- Update rage tracking
function Protection:UpdateRage()
    currentRage = API.GetPlayerPower()
    return true
end

-- Update health tracking
function Protection:UpdateHealth()
    playerHealth = API.GetPlayerHealthPercent()
    return true
end

-- Handle spell cast events
function Protection:HandleSpellCastSucceeded(spellID)
    -- Update shield block charges
    if spellID == spells.SHIELD_BLOCK then
        shieldBlockCharges = API.GetSpellCharges(spells.SHIELD_BLOCK) or 0
        API.PrintDebug("Shield Block cast, charges remaining: " .. tostring(shieldBlockCharges))
    end
    
    -- Update thunder clap charges
    if spellID == spells.THUNDER_CLAP then
        thunderClapCharges = API.GetSpellCharges(spells.THUNDER_CLAP) or 0
        API.PrintDebug("Thunder Clap cast, charges remaining: " .. tostring(thunderClapCharges))
    end
    
    return true
end

-- Update target data
function Protection:UpdateTargetData()
    -- Check if in melee range
    inMeleeRange = API.IsUnitInRange("target", MELEE_RANGE)
    
    -- Get target GUID
    local targetGUID = API.GetTargetGUID()
    
    -- Check Victory Rush availability
    victoryRushAvailable = API.IsSpellUsable(spells.VICTORY_RUSH) or 
                          (impendingVictory and API.IsSpellUsable(spells.IMPENDING_VICTORY))
    
    if targetGUID and targetGUID ~= "" then
        -- Check for Deep Wounds
        if deepWounds then
            local deepWoundsInfo = API.GetDebuffInfo(targetGUID, debuffs.DEEP_WOUNDS)
            if deepWoundsInfo then
                deepWoundsActive[targetGUID] = true
                deepWoundsEndTime[targetGUID] = select(6, deepWoundsInfo)
            else
                deepWoundsActive[targetGUID] = false
                deepWoundsEndTime[targetGUID] = 0
            end
        end
    end
    
    -- Update AoE targets count
    currentAoETargets = API.GetNearbyEnemiesCount(8) -- Thunder Clap radius
    
    return true
end

-- Handle combat log events
function Protection:HandleCombatLogEvent(...)
    local timestamp, eventType, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, spellID, spellName = CombatLogGetCurrentEventInfo()
    
    -- Track buff applications
    if eventType == "SPELL_AURA_APPLIED" or eventType == "SPELL_AURA_REFRESH" then
        -- Track player buffs
        if destGUID == API.GetPlayerGUID() then
            -- Track Shield Block
            if spellID == buffs.SHIELD_BLOCK then
                shieldBlockActive = true
                shieldBlockEndTime = GetTime() + SHIELD_BLOCK_DURATION
                API.PrintDebug("Shield Block activated")
            end
            
            -- Track Last Stand
            if spellID == buffs.LAST_STAND then
                lastStandActive = true
                lastStandEndTime = GetTime() + LAST_STAND_DURATION
                API.PrintDebug("Last Stand activated")
            end
            
            -- Track Ignore Pain
            if spellID == buffs.IGNORE_PAIN then
                ignorePainActive = true
                ignorePainEndTime = GetTime() + IGNORE_PAIN_DURATION
                ignorePainValue = API.GetIgnorePainValue() or 0
                ignorePainMaxValue = API.GetIgnorePainMaxValue() or 0
                API.PrintDebug("Ignore Pain activated: " .. tostring(ignorePainValue) .. " / " .. tostring(ignorePainMaxValue))
            end
            
            -- Track Demo Shout
            if spellID == buffs.DEMORALIZING_SHOUT then
                demoShoutActive = true
                demoShoutEndTime = GetTime() + DEMO_SHOUT_DURATION
                API.PrintDebug("Demoralizing Shout activated")
            end
            
            -- Track Avatar
            if spellID == buffs.AVATAR then
                avatarActive = true
                avatarEndTime = GetTime() + AVATAR_DURATION
                API.PrintDebug("Avatar activated")
            end
            
            -- Track Shield Wall
            if spellID == buffs.SHIELD_WALL then
                shieldWallActive = true
                shieldWallEndTime = GetTime() + SHIELD_WALL_DURATION
                API.PrintDebug("Shield Wall activated")
            end
            
            -- Track Revenge proc
            if spellID == buffs.REVENGE then
                revengeProc = true
                API.PrintDebug("Revenge proc activated")
            end
            
            -- Track Sudden Death proc
            if spellID == buffs.SUDDEN_DEATH then
                suddenDeathProc = true
                suddenDeathEndTime = select(6, API.GetBuffInfo("player", buffs.SUDDEN_DEATH))
                API.PrintDebug("Sudden Death proc activated")
            end
            
            -- Track Battle Shout
            if spellID == buffs.BATTLE_SHOUT then
                API.PrintDebug("Battle Shout activated")
            end
            
            -- Track Spell Reflection
            if spellID == buffs.SPELL_REFLECTION then
                spellReflectionActive = true
                spellReflectionEndTime = GetTime() + SPELL_REFLECTION_DURATION
                API.PrintDebug("Spell Reflection activated")
            end
            
            -- Track Ravager
            if spellID == buffs.RAVAGER then
                ravagerActive = true
                ravagerEndTime = GetTime() + RAVAGER_DURATION
                API.PrintDebug("Ravager activated")
            end
            
            -- Track Dragon Roar
            if spellID == buffs.DRAGON_ROAR then
                dragonRoarActive = true
                dragonRoarEndTime = GetTime() + DRAGON_ROAR_DURATION
                API.PrintDebug("Dragon Roar activated")
            end
            
            -- Track Into the Fray
            if spellID == buffs.INTO_THE_FRAY then
                intoTheFrayStacks = select(4, API.GetBuffInfo("player", buffs.INTO_THE_FRAY)) or 1
                intoTheFrayEndTime = select(6, API.GetBuffInfo("player", buffs.INTO_THE_FRAY))
                API.PrintDebug("Into the Fray activated: " .. tostring(intoTheFrayStacks) .. " stacks")
            end
            
            -- Track Seethe
            if spellID == buffs.SEETHE then
                seetheActive = true
                seetheStacks = select(4, API.GetBuffInfo("player", buffs.SEETHE)) or 1
                seetheEndTime = select(6, API.GetBuffInfo("player", buffs.SEETHE))
                API.PrintDebug("Seethe activated: " .. tostring(seetheStacks) .. " stacks")
            end
        end
        
        -- Track Deep Wounds application to target
        if spellID == debuffs.DEEP_WOUNDS and sourceGUID == API.GetPlayerGUID() then
            deepWoundsActive[destGUID] = true
            deepWoundsEndTime[destGUID] = GetTime() + DEEP_WOUNDS_DURATION
            API.PrintDebug("Deep Wounds applied to " .. destName)
        end
        
        -- Track Thunder Clap debuff application
        if spellID == debuffs.THUNDER_CLAP and sourceGUID == API.GetPlayerGUID() then
            thunderClapActive = true
            thunderClapEndTime = GetTime() + THUNDER_CLAP_DURATION
            API.PrintDebug("Thunder Clap debuff applied to " .. destName)
        end
    end
    
    -- Track buff removals
    if eventType == "SPELL_AURA_REMOVED" then
        -- Track player buff removals
        if destGUID == API.GetPlayerGUID() then
            -- Track Shield Block
            if spellID == buffs.SHIELD_BLOCK then
                shieldBlockActive = false
                API.PrintDebug("Shield Block faded")
            end
            
            -- Track Last Stand
            if spellID == buffs.LAST_STAND then
                lastStandActive = false
                API.PrintDebug("Last Stand faded")
            end
            
            -- Track Ignore Pain
            if spellID == buffs.IGNORE_PAIN then
                ignorePainActive = false
                ignorePainValue = 0
                API.PrintDebug("Ignore Pain faded")
            end
            
            -- Track Demo Shout
            if spellID == buffs.DEMORALIZING_SHOUT then
                demoShoutActive = false
                API.PrintDebug("Demoralizing Shout faded")
            end
            
            -- Track Avatar
            if spellID == buffs.AVATAR then
                avatarActive = false
                API.PrintDebug("Avatar faded")
            end
            
            -- Track Shield Wall
            if spellID == buffs.SHIELD_WALL then
                shieldWallActive = false
                API.PrintDebug("Shield Wall faded")
            end
            
            -- Track Revenge proc
            if spellID == buffs.REVENGE then
                revengeProc = false
                API.PrintDebug("Revenge proc consumed")
            end
            
            -- Track Sudden Death proc
            if spellID == buffs.SUDDEN_DEATH then
                suddenDeathProc = false
                API.PrintDebug("Sudden Death proc consumed")
            end
            
            -- Track Spell Reflection
            if spellID == buffs.SPELL_REFLECTION then
                spellReflectionActive = false
                API.PrintDebug("Spell Reflection faded")
            end
            
            -- Track Ravager
            if spellID == buffs.RAVAGER then
                ravagerActive = false
                API.PrintDebug("Ravager faded")
            end
            
            -- Track Dragon Roar
            if spellID == buffs.DRAGON_ROAR then
                dragonRoarActive = false
                API.PrintDebug("Dragon Roar faded")
            end
            
            -- Track Seethe
            if spellID == buffs.SEETHE then
                seetheActive = false
                seetheStacks = 0
                API.PrintDebug("Seethe faded")
            end
        end
        
        -- Track Deep Wounds removal
        if spellID == debuffs.DEEP_WOUNDS and deepWoundsActive[destGUID] then
            deepWoundsActive[destGUID] = false
            deepWoundsEndTime[destGUID] = 0
            API.PrintDebug("Deep Wounds faded from " .. destName)
        end
    end
    
    -- Track Into the Fray stacks
    if eventType == "SPELL_AURA_APPLIED_DOSE" and spellID == buffs.INTO_THE_FRAY and destGUID == API.GetPlayerGUID() then
        intoTheFrayStacks = select(4, API.GetBuffInfo("player", buffs.INTO_THE_FRAY)) or 0
        API.PrintDebug("Into the Fray stacks: " .. tostring(intoTheFrayStacks))
    end
    
    -- Track Seethe stacks
    if eventType == "SPELL_AURA_APPLIED_DOSE" and spellID == buffs.SEETHE and destGUID == API.GetPlayerGUID() then
        seetheStacks = select(4, API.GetBuffInfo("player", buffs.SEETHE)) or 0
        API.PrintDebug("Seethe stacks: " .. tostring(seetheStacks))
    end
    
    -- Track Devastator procs
    if eventType == "SPELL_DAMAGE" and sourceGUID == API.GetPlayerGUID() and devastator then
        if spellID == spells.DEVASTATOR then
            devastatorProc = true
            
            -- Reset devastator proc after a short delay
            C_Timer.After(1.0, function()
                devastatorProc = false
            end)
            
            API.PrintDebug("Devastator proc")
        end
    end
    
    -- Track Shield Slam cooldown resets from Shield Discipline
    if eventType == "SPELL_ENERGIZE" and sourceGUID == API.GetPlayerGUID() and
       talents.hasShieldDiscipline and spellID == spells.SHIELD_DISCIPLINE then
        shieldSlamNoCooldown = true
        
        -- Reset after a short delay
        C_Timer.After(1.0, function()
            shieldSlamNoCooldown = false
        end)
        
        API.PrintDebug("Shield Slam cooldown reset")
    end
    
    -- Track spell casts
    if eventType == "SPELL_CAST_SUCCESS" then
        if sourceGUID == API.GetPlayerGUID() then
            if spellID == spells.SHIELD_BLOCK then
                shieldBlockActive = true
                shieldBlockEndTime = GetTime() + SHIELD_BLOCK_DURATION
                shieldBlockCharges = API.GetSpellCharges(spells.SHIELD_BLOCK) or 0
                API.PrintDebug("Shield Block cast, charges remaining: " .. tostring(shieldBlockCharges))
            elseif spellID == spells.IGNORE_PAIN then
                ignorePainActive = true
                ignorePainEndTime = GetTime() + IGNORE_PAIN_DURATION
                ignorePainValue = API.GetIgnorePainValue() or 0
                ignorePainMaxValue = API.GetIgnorePainMaxValue() or 0
                API.PrintDebug("Ignore Pain cast: " .. tostring(ignorePainValue) .. " / " .. tostring(ignorePainMaxValue))
            elseif spellID == spells.LAST_STAND then
                lastStandActive = true
                lastStandEndTime = GetTime() + LAST_STAND_DURATION
                API.PrintDebug("Last Stand cast")
            elseif spellID == spells.DEMORALIZING_SHOUT then
                demoShoutActive = true
                demoShoutEndTime = GetTime() + DEMO_SHOUT_DURATION
                API.PrintDebug("Demoralizing Shout cast")
            elseif spellID == spells.AVATAR then
                avatarActive = true
                avatarEndTime = GetTime() + AVATAR_DURATION
                API.PrintDebug("Avatar cast")
            elseif spellID == spells.SHIELD_WALL then
                shieldWallActive = true
                shieldWallEndTime = GetTime() + SHIELD_WALL_DURATION
                API.PrintDebug("Shield Wall cast")
            elseif spellID == spells.REVENGE then
                revengeCDStacks = select(4, API.GetBuffInfo("player", spells.REVENGE)) or 0
                API.PrintDebug("Revenge cast")
                if revengeProc then
                    revengeProc = false
                    API.PrintDebug("Revenge proc consumed")
                end
            elseif spellID == spells.SHIELD_SLAM then
                -- Apply Deep Wounds via Punish
                if talents.hasPunish and deepWounds then
                    local targetGUID = API.GetTargetGUID()
                    if targetGUID then
                        deepWoundsActive[targetGUID] = true
                        deepWoundsEndTime[targetGUID] = GetTime() + DEEP_WOUNDS_DURATION
                        API.PrintDebug("Deep Wounds applied via Punish")
                    end
                end
                
                API.PrintDebug("Shield Slam cast")
            elseif spellID == spells.THUNDER_CLAP then
                thunderClapActive = true
                thunderClapEndTime = GetTime() + THUNDER_CLAP_DURATION
                thunderClapCharges = API.GetSpellCharges(spells.THUNDER_CLAP) or 0
                API.PrintDebug("Thunder Clap cast, charges remaining: " .. tostring(thunderClapCharges))
            elseif spellID == spells.RAVAGER then
                ravagerActive = true
                ravagerEndTime = GetTime() + RAVAGER_DURATION
                API.PrintDebug("Ravager cast")
            elseif spellID == spells.DRAGON_ROAR then
                dragonRoarActive = true
                dragonRoarEndTime = GetTime() + DRAGON_ROAR_DURATION
                API.PrintDebug("Dragon Roar cast")
            elseif spellID == spells.SPEAR_OF_BASTION then
                spearOfBastionActive = true
                spearOfBastionEndTime = GetTime() + SPEAR_OF_BASTION_DURATION
                API.PrintDebug("Spear of Bastion cast")
            end
        end
    end
    
    return true
end

-- Main rotation function
function Protection:RunRotation()
    -- Check if we should be running Protection Warrior logic
    if API.GetActiveSpecID() ~= PROTECTION_SPEC_ID then
        return false
    end
    
    -- Skip rotation if player is casting
    if API.IsPlayerCasting() then
        return false
    end
    
    -- Get settings
    local settings = ConfigRegistry:GetSettings("ProtectionWarrior")
    
    -- Update variables
    self:UpdateRage()
    burstModeActive = settings.rotationSettings.burstEnabled and API.ShouldUseBurst()
    self:UpdateTargetData() -- Makes sure we have current target information
    
    -- Handle next cast override
    if nextCastOverride and API.CanCast(nextCastOverride) then
        local spell = nextCastOverride
        nextCastOverride = nil
        API.CastSpell(spell)
        return true
    end
    
    -- Maintain Battle Shout
    if battleShout and
       settings.utilitySettings.useBattleShout and
       not API.GroupHasBuff(buffs.BATTLE_SHOUT) and
       API.CanCast(spells.BATTLE_SHOUT) then
        API.CastSpell(spells.BATTLE_SHOUT)
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
    
    -- Skip if not in melee range
    if not inMeleeRange then
        -- Handle ranged abilities if not in melee range
        return self:HandleRangedAbilities(settings)
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
function Protection:HandleInterrupts()
    -- Only attempt to interrupt if in range
    if inMeleeRange and API.CanCast(spells.PUMMEL) and API.TargetIsSpellCastable() then
        API.CastSpell(spells.PUMMEL)
        return true
    end
    
    return false
end

-- Handle defensive abilities
function Protection:HandleDefensives(settings)
    -- Use Shield Block
    if settings.defensiveSettings.useShieldBlock and
       settings.abilityControls.shieldBlock.enabled and
       not shieldBlockActive and
       shieldBlockCharges > settings.defensiveSettings.shieldBlockChargesReserved and
       currentRage >= settings.abilityControls.shieldBlock.minRage and
       API.CanCast(spells.SHIELD_BLOCK) then
        
        local incomingDamage = API.GetIncomingDamage(5) -- Check damage in the next 5 seconds
        
        if incomingDamage >= settings.abilityControls.shieldBlock.minIncomingDamage or
           (not settings.abilityControls.shieldBlock.useDuringBurstOnly or burstModeActive) then
            API.CastSpell(spells.SHIELD_BLOCK)
            return true
        end
    end
    
    -- Use Ignore Pain
    if settings.defensiveSettings.useIgnorePain and
       settings.abilityControls.ignorePain.enabled and
       currentRage >= settings.defensiveSettings.ignorePainMinRage and
       API.CanCast(spells.IGNORE_PAIN) then
        
        local incomingDamage = API.GetIncomingDamage(5) -- Check damage in the next 5 seconds
        
        if incomingDamage >= settings.abilityControls.ignorePain.minIncomingDamage or
           (not settings.abilityControls.ignorePain.useDuringBurstOnly or burstModeActive) then
            API.CastSpell(spells.IGNORE_PAIN)
            return true
        end
    end
    
    -- Use Last Stand
    if settings.defensiveSettings.useLastStand and
       settings.abilityControls.lastStand.enabled and
       not lastStandActive and
       playerHealth <= settings.defensiveSettings.lastStandThreshold and
       API.CanCast(spells.LAST_STAND) and
       playerHealth <= settings.abilityControls.lastStand.maxHealthPercent and
       playerHealth >= settings.abilityControls.lastStand.minHealthPercent then
        API.CastSpell(spells.LAST_STAND)
        return true
    end
    
    -- Use Shield Wall
    if settings.defensiveSettings.useShieldWall and
       not shieldWallActive and
       playerHealth <= settings.defensiveSettings.shieldWallThreshold and
       API.CanCast(spells.SHIELD_WALL) then
        API.CastSpell(spells.SHIELD_WALL)
        return true
    end
    
    -- Use Spell Reflection
    if settings.defensiveSettings.useSpellReflection and
       not spellReflectionActive and
       API.IsFacingMagicDamage() and
       API.CanCast(spells.SPELL_REFLECTION) then
        API.CastSpell(spells.SPELL_REFLECTION)
        return true
    end
    
    -- Use Rallying Cry
    if rallyingCry and
       settings.defensiveSettings.useRallyingCry and
       playerHealth <= settings.defensiveSettings.rallyingCryThreshold and
       API.CanCast(spells.RALLYING_CRY) then
        API.CastSpell(spells.RALLYING_CRY)
        return true
    end
    
    return false
end

-- Handle ranged abilities when not in melee range
function Protection:HandleRangedAbilities(settings)
    -- Use Heroic Throw for pulling
    if settings.utilitySettings.useHeroicThrow and
       API.CanCast(spells.HEROIC_THROW) then
        API.CastSpell(spells.HEROIC_THROW)
        return true
    end
    
    -- Use Charge to gap close
    if settings.utilitySettings.useCharge and
       API.CanCast(spells.CHARGE) then
        API.CastSpell(spells.CHARGE)
        return true
    end
    
    return false
end

-- Handle cooldown abilities
function Protection:HandleCooldowns(settings)
    -- Skip offensive cooldowns if not in burst mode or not in combat
    if not API.IsInCombat() then
        return false
    end
    
    -- Use Avatar
    if settings.cooldownSettings.useAvatar and
       not avatarActive and
       API.CanCast(spells.AVATAR) then
        
        local shouldUseAvatar = false
        
        if settings.cooldownSettings.avatarMode == "On Cooldown" then
            shouldUseAvatar = true
        elseif settings.cooldownSettings.avatarMode == "With Defensives" then
            shouldUseAvatar = shieldBlockActive or lastStandActive or ignorePainActive
        elseif settings.cooldownSettings.avatarMode == "Burst Only" then
            shouldUseAvatar = burstModeActive
        end
        
        if shouldUseAvatar then
            API.CastSpell(spells.AVATAR)
            return true
        end
    end
    
    -- Use Ravager
    if ravager and
       settings.cooldownSettings.useRavager and
       not ravagerActive and
       API.CanCast(spells.RAVAGER) then
        
        local placement = "target"
        
        if settings.cooldownSettings.ravagerMode == "At Cursor" then
            placement = "cursor"
        elseif settings.cooldownSettings.ravagerMode == "On Self" then
            placement = "player"
        end
        
        API.CastSpellAt(spells.RAVAGER, placement)
        return true
    end
    
    -- Use Spear of Bastion
    if talents.hasSpearOfBastion and
       settings.cooldownSettings.useSpearOfBastion and
       not spearOfBastionActive and
       API.CanCast(spells.SPEAR_OF_BASTION) then
        
        local placement = "target"
        
        if settings.cooldownSettings.spearOfBastionMode == "At Cursor" then
            placement = "cursor"
        elseif settings.cooldownSettings.spearOfBastionMode == "On Self" then
            placement = "player"
        end
        
        API.CastSpellAt(spells.SPEAR_OF_BASTION, placement)
        return true
    end
    
    -- Use Demoralizing Shout
    if demoralizingShout and
       settings.utilitySettings.useDemoralizingShout and
       not demoShoutActive and
       currentAoETargets >= settings.utilitySettings.demoralizingShoutThreshold and
       API.CanCast(spells.DEMORALIZING_SHOUT) then
        API.CastSpell(spells.DEMORALIZING_SHOUT)
        return true
    end
    
    -- Use Challenging Shout
    if settings.utilitySettings.useChallengingShout and
       not challengingShoutActive and
       currentAoETargets >= settings.utilitySettings.challengingShoutThreshold and
       API.CanCast(spells.CHALLENGING_SHOUT) then
        API.CastSpell(spells.CHALLENGING_SHOUT)
        return true
    end
    
    return false
end

-- Handle AoE rotation
function Protection:HandleAoERotation(settings)
    -- Use Shockwave for AoE stun
    if settings.ccSettings.useShockwave and
       currentAoETargets >= settings.ccSettings.shockwaveThreshold and
       API.CanCast(spells.SHOCKWAVE) then
        API.CastSpell(spells.SHOCKWAVE)
        return true
    end
    
    -- Victory Rush or Impending Victory if available
    if victoryRushAvailable then
        if impendingVictory and API.CanCast(spells.IMPENDING_VICTORY) then
            API.CastSpell(spells.IMPENDING_VICTORY)
            return true
        elseif API.CanCast(spells.VICTORY_RUSH) then
            API.CastSpell(spells.VICTORY_RUSH)
            return true
        end
    end
    
    -- Thunder Clap for AoE threat and damage
    if thunderClap and
       API.CanCast(spells.THUNDER_CLAP) then
        API.CastSpell(spells.THUNDER_CLAP)
        return true
    end
    
    -- Use Dragon Roar for AoE damage
    if dragonRoar and
       not dragonRoarActive and
       API.CanCast(spells.DRAGON_ROAR) then
        API.CastSpell(spells.DRAGON_ROAR)
        return true
    end
    
    -- Use Revenge with proc for free AoE damage
    if revenge and
       settings.rotationSettings.useRevengeOnProc and
       revengeProc and
       API.CanCast(spells.REVENGE) then
        API.CastSpell(spells.REVENGE)
        return true
    end
    
    -- Shield Slam for rage generation and threat
    if shieldSlam and
       API.CanCast(spells.SHIELD_SLAM) then
        API.CastSpell(spells.SHIELD_SLAM)
        return true
    end
    
    -- Use Revenge when in AoE mode if we have enough rage
    if revenge and
       settings.rotationSettings.revengePrioWithRage == "AoE Only" and
       currentRage >= 30 and 
       (not settings.rotationSettings.ragePooling || 
        currentRage > settings.rotationSettings.ragePoolingThreshold) and
       API.CanCast(spells.REVENGE) then
        API.CastSpell(spells.REVENGE)
        return true
    end
    
    -- Execute with Sudden Death proc or if target is in execute range
    if execute and
       settings.rotationSettings.useExecute and
       (suddenDeathProc || API.GetTargetHealthPercent() <= 20) and
       currentRage >= settings.rotationSettings.executeThreshold and
       API.CanCast(spells.EXECUTE) then
        API.CastSpell(spells.EXECUTE)
        return true
    end
    
    -- Devastate as filler if not using Devastator talent
    if devastate and not ignoreDevastate and API.CanCast(spells.DEVASTATE) then
        API.CastSpell(spells.DEVASTATE)
        return true
    end
    
    return false
end

-- Handle Single Target rotation
function Protection:HandleSingleTargetRotation(settings)
    -- Victory Rush or Impending Victory if available
    if victoryRushAvailable then
        if impendingVictory and API.CanCast(spells.IMPENDING_VICTORY) then
            API.CastSpell(spells.IMPENDING_VICTORY)
            return true
        elseif API.CanCast(spells.VICTORY_RUSH) then
            API.CastSpell(spells.VICTORY_RUSH)
            return true
        end
    end
    
    -- Shield Slam for rage generation and threat
    if shieldSlam and
       API.CanCast(spells.SHIELD_SLAM) then
        API.CastSpell(spells.SHIELD_SLAM)
        return true
    end
    
    -- Thunder Clap for applying debuff
    if thunderClap and
       API.CanCast(spells.THUNDER_CLAP) then
        API.CastSpell(spells.THUNDER_CLAP)
        return true
    end
    
    -- Use Revenge with proc for free damage
    if revenge and
       settings.rotationSettings.useRevengeOnProc and
       revengeProc and
       API.CanCast(spells.REVENGE) then
        API.CastSpell(spells.REVENGE)
        return true
    end
    
    -- Execute with Sudden Death proc or if target is in execute range
    if execute and
       settings.rotationSettings.useExecute and
       (suddenDeathProc || API.GetTargetHealthPercent() <= 20) and
       currentRage >= settings.rotationSettings.executeThreshold and
       API.CanCast(spells.EXECUTE) then
        API.CastSpell(spells.EXECUTE)
        return true
    end
    
    -- Use Dragon Roar for additional damage
    if dragonRoar and
       not dragonRoarActive and
       API.CanCast(spells.DRAGON_ROAR) then
        API.CastSpell(spells.DRAGON_ROAR)
        return true
    end
    
    -- Use Revenge if "Always" selected and we have enough rage
    if revenge and
       settings.rotationSettings.revengePrioWithRage == "Always" and
       currentRage >= 30 and 
       (not settings.rotationSettings.ragePooling || 
        currentRage > settings.rotationSettings.ragePoolingThreshold) and
       API.CanCast(spells.REVENGE) then
        API.CastSpell(spells.REVENGE)
        return true
    end
    
    -- Devastate as filler if not using Devastator talent
    if devastate and not ignoreDevastate and API.CanCast(spells.DEVASTATE) then
        API.CastSpell(spells.DEVASTATE)
        return true
    end
    
    return false
end

-- Handle specialization change
function Protection:OnSpecializationChanged()
    -- Update talent information
    self:UpdateTalentInfo()
    
    -- Reset state variables
    nextCastOverride = nil
    burstModeActive = false
    currentAoETargets = 0
    currentRage = 0
    maxRage = 100
    shieldBlockActive = false
    shieldBlockEndTime = 0
    lastStandActive = false
    lastStandEndTime = 0
    ignorePainActive = false
    ignorePainEndTime = 0
    ignorePainValue = 0
    ignorePainMaxValue = 0
    demoShoutActive = false
    demoShoutEndTime = 0
    avatarActive = false
    avatarEndTime = 0
    shieldWallActive = false
    shieldWallEndTime = 0
    ravagerActive = false
    ravagerEndTime = 0
    thunderClapActive = false
    thunderClapEndTime = 0
    spearOfBastionActive = false
    spearOfBastionEndTime = 0
    ancientAftershockActive = false
    ancientAftershockEndTime = 0
    dragonRoarActive = false
    dragonRoarEndTime = 0
    recklessnessActive = false
    recklessnessEndTime = 0
    enragedRegenActive = false
    enragedRegenEndTime = 0
    berserkerRageActive = false
    berserkerRageEndTime = 0
    challengingShoutActive = false
    challengingShoutEndTime = 0
    spellReflectionActive = false
    spellReflectionEndTime = 0
    intImmuneActive = false
    intImmuneEndTime = 0
    rallyingCryActive = false
    rallyingCryEndTime = 0
    victoryRushAvailable = false
    shieldBlockCharges = 0
    shieldBlockMaxCharges = 0
    thunderClapCharges = 0
    thunderClapMaxCharges = 0
    revengeProc = false
    deepWounds = false
    deepWoundsActive = {}
    deepWoundsEndTime = {}
    suddenDeathProc = false
    suddenDeathEndTime = 0
    devastatorProc = false
    shieldSlamNoCooldown = false
    revenge = false
    devastate = false
    ignoreDevastate = true
    shieldSlam = false
    impendingVictory = false
    thunderClap = false
    devastator = false
    dragonRoar = false
    ravager = false
    battleShout = false
    execute = false
    demoralizingShout = false
    shieldCharge = false
    stalwartProtector = false
    heavyRepurcussions = false
    bestServedCold = false
    bolster = false
    burningWind = false
    focusInChaos = false
    unforgivingStandard = false
    seetheActive = false
    seetheEndTime = 0
    seetheStacks = 0
    intoTheFray = false
    intoTheFrayEndTime = 0
    intoTheFrayStacks = 0
    playerHealth = 100
    inMeleeRange = false
    bloodAndThunder = false
    revengeCDStacks = 0
    thunderousRoar = false
    bloodthirst = false
    titanStrike = false
    titanicsRage = false
    rallyingCry = false
    battleRoar = false
    enrageExhaust = false
    limitlessRage = false
    executePact = false
    colossusSmash = false
    bleedStorm = false
    berserker = false
    
    API.PrintDebug("Protection Warrior state reset on spec change")
    
    return true
end

-- Return the module for loading
return Protection