------------------------------------------
-- WindrunnerRotations - Arms Warrior Module
-- Author: VortexQ8
------------------------------------------

local Arms = {}
-- This will be assigned to addon.Classes.Warrior.Arms when loaded

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
local rendActive = false
local rendExpiration = 0
local deepWoundsActive = false
local deepWoundsExpiration = 0
local executionPhase = false
local sweepingStrikesActive = false
local colossusSmashActive = false
local colossusSmashExpiration = 0
local suddenDeathProc = false
local deadlyCalm = false
local deadlyCalmExpiration = 0
local bladestormChanneling = false
local inForTheKill = false
local ravagerActive = false
local ravagerExpiration = 0
local spearOfBastionActive = false
local conquerersBanner = false
local conqueringDraught = 0 -- Stacks from banner
local testOfMight = false
local skullsplitter = false
local fervorOfBattle = false
local strengthOfArms = false
local cleaveActive = false
local tidyProcActive = false -- Exploiter
local warbreaker = false
local shatteredDefenses = false
local battlelord = false -- Extra Overpower proc chance
local defensiveStance = false
local dieByTheSword = false
local overlordsProcActive = false

-- Constants
local ARMS_SPEC_ID = 71
local DEFAULT_AOE_THRESHOLD = 3
local EXECUTION_THRESHOLD = 20 -- Health percent to enable Execute phase
local REND_REFRESH_THRESHOLD = 5.4 -- Seconds remaining to refresh Rend
local SWEEPING_STRIKES_DURATION = 15
local COLOSSUS_SMASH_DURATION = 10
local DEEP_WOUNDS_DURATION = 12
local DEADLY_CALM_DURATION = 6
local REND_DURATION = 15
local AVATAR_DURATION = 20
local BLADESTORM_DURATION = 6
local WARBREAKER_COOLDOWN = 45

-- Initialize the Arms module
function Arms:Initialize()
    self:RegisterSpells()
    self:RegisterVariables()
    self:RegisterSettings()
    self:RegisterEvents()
    
    API.PrintDebug("Arms Warrior module initialized")
    
    return true
end

-- Register spell IDs
function Arms:RegisterSpells()
    -- Main rotational abilities
    spells.MORTAL_STRIKE = 12294
    spells.EXECUTE = 163201
    spells.SLAM = 1464
    spells.OVERPOWER = 7384
    spells.WHIRLWIND = 1680
    spells.REND = 772
    spells.CLEAVE = 845
    spells.BLADESTORM = 227847
    spells.COLOSSUS_SMASH = 167105
    spells.WARBREAKER = 262161
    
    -- Defensive and utility
    spells.VICTORY_RUSH = 34428
    spells.DEFENSIVE_STANCE = 386208
    spells.DIE_BY_THE_SWORD = 118038
    spells.RALLYING_CRY = 97462
    spells.IGNORE_PAIN = 190456
    spells.INTERVENE = 3411
    spells.SPELL_REFLECTION = 23920
    spells.CHARGE = 100
    spells.HEROIC_LEAP = 6544
    spells.PUMMEL = 6552
    spells.INTIMIDATING_SHOUT = 5246
    spells.HAMSTRING = 1715
    
    -- Talents/Procs
    spells.SWEEPING_STRIKES = 260708
    spells.SUDDEN_DEATH = 29725
    spells.DEADLY_CALM = 262228
    spells.IN_FOR_THE_KILL = 248621
    spells.MASSACRE = 281001
    spells.DREADNAUGHT = 262150
    spells.AVATAR = 107574
    spells.COLLATERAL_DAMAGE = 334779
    spells.FERVOR_OF_BATTLE = 202316
    spells.SKULLSPLITTER = 260643
    spells.TEST_OF_MIGHT = 385008
    spells.REND_TALENT = 772
    spells.STORM_OF_DESTRUCTION = 385512
    spells.TACTICIAN = 184783
    spells.BATTLELORD = 386630
    spells.TIDE_OF_BLOOD = 386357
    spells.EXECUTIONERS_PRECISION = 386634
    spells.EXPLOITER = 383115
    spells.SHARPENED_BLADES = 385512
    spells.BLOODLETTING = 383154
    spells.BLADEMASTERS_TORMENT = 390138
    
    -- Covenant abilities
    spells.CONDEMN = 317349 -- Replaces Execute for Venthyr
    spells.SPEAR_OF_BASTION = 307865
    spells.ANCIENT_AFTERSHOCK = 325886
    spells.CONQUERORS_BANNER = 324143
    
    -- Legendary effects
    spells.ENDURING_BLOW = 344140 -- Signet of Tormented Kings legendary
    spells.EXPLOITER = 383115 -- Increases CS damage
    spells.STRENGTH_OF_ARMS = 329333 -- Battlelord legendary effect
    spells.WILL_OF_THE_BERSERKER = 335597 -- Sinful Surge legendary effect
    
    -- Buff and debuff IDs
    spells.DEEP_WOUNDS = 262115
    spells.SUDDEN_DEATH_BUFF = 52437
    spells.DEADLY_CALM_BUFF = 262228
    spells.SWEEPING_STRIKES_BUFF = 260708
    spells.AVATAR_BUFF = 107574
    spells.OVERPOWER_BUFF = 7384
    spells.REND_DEBUFF = 772
    spells.COLOSSUS_SMASH_DEBUFF = 208086
    spells.TEST_OF_MIGHT_BUFF = 385013
    spells.CLEAVE_BUFF = 845
    spells.SPEAR_OF_BASTION_DEBUFF = 307871
    spells.CONQUERORS_BANNER_BUFF = 324143
    spells.CONQUERORS_DRAUGHT = 325862
    spells.TACTICIAN_BUFF = 184783
    spells.DEFENSIVESTANCE_BUFF = 386208
    spells.DIE_BY_THE_SWORD_BUFF = 118038
    spells.BATTLELORD_BUFF = 346369
    spells.SHATTERED_DEFENSES = 248625
    spells.EXPLOITER_BUFF = 383117
    spells.OVERLORDS_CRITICAL = 426537
    
    -- Register all spells with the API tracking system
    for spellName, spellID in pairs(spells) do
        API.RegisterSpell(spellID)
    end
    
    -- Define aura tracking
    buffs.SUDDEN_DEATH = spells.SUDDEN_DEATH_BUFF
    buffs.DEADLY_CALM = spells.DEADLY_CALM_BUFF
    buffs.SWEEPING_STRIKES = spells.SWEEPING_STRIKES_BUFF
    buffs.AVATAR = spells.AVATAR_BUFF
    buffs.OVERPOWER = spells.OVERPOWER_BUFF
    buffs.TEST_OF_MIGHT = spells.TEST_OF_MIGHT_BUFF
    buffs.CLEAVE = spells.CLEAVE_BUFF
    buffs.CONQUERORS_BANNER = spells.CONQUERORS_BANNER_BUFF
    buffs.CONQUERORS_DRAUGHT = spells.CONQUERORS_DRAUGHT
    buffs.TACTICIAN = spells.TACTICIAN_BUFF
    buffs.DEFENSIVE_STANCE = spells.DEFENSIVESTANCE_BUFF
    buffs.DIE_BY_THE_SWORD = spells.DIE_BY_THE_SWORD_BUFF
    buffs.BATTLELORD = spells.BATTLELORD_BUFF
    buffs.SHATTERED_DEFENSES = spells.SHATTERED_DEFENSES
    buffs.EXPLOITER = spells.EXPLOITER_BUFF
    buffs.OVERLORDS_CRITICAL = spells.OVERLORDS_CRITICAL
    
    debuffs.REND = spells.REND_DEBUFF
    debuffs.DEEP_WOUNDS = spells.DEEP_WOUNDS
    debuffs.COLOSSUS_SMASH = spells.COLOSSUS_SMASH_DEBUFF
    debuffs.SPEAR_OF_BASTION = spells.SPEAR_OF_BASTION_DEBUFF
    
    return true
end

-- Register variables to track
function Arms:RegisterVariables()
    -- Talent tracking
    talents.hasRend = false
    talents.hasSweepingStrikes = false
    talents.hasSuddenDeath = false
    talents.hasDeadlyCalm = false
    talents.hasInForTheKill = false
    talents.hasMassacre = false
    talents.hasDreadnaught = false
    talents.hasAvatar = false
    talents.hasCollateralDamage = false
    talents.hasFervorOfBattle = false
    talents.hasSkullsplitter = false
    talents.hasTestOfMight = false
    talents.hasStormOfDestruction = false
    talents.hasTactician = false
    talents.hasBattlelord = false
    talents.hasTideOfBlood = false
    talents.hasExecutionersPrecision = false
    talents.hasExploiter = false
    talents.hasSharpenedBlades = false
    talents.hasBloodletting = false
    talents.hasBlademastersTorment = false
    talents.hasWarbreaker = false
    talents.hasRavager = false
    talents.hasCleave = false
    
    -- Target state tracking
    self.targetData = {}
    
    return true
end

-- Register spec-specific settings
function Arms:RegisterSettings()
    ConfigRegistry:RegisterSettings("ArmsWarrior", {
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
            useRend = {
                displayName = "Use Rend",
                description = "Maintain Rend on targets",
                type = "toggle",
                default = true
            },
            useExecute = {
                displayName = "Use Execute",
                description = "Use Execute during execute phase and with Sudden Death",
                type = "toggle",
                default = true
            },
            slamPriority = {
                displayName = "Slam Priority",
                description = "When to use Slam in rotation",
                type = "dropdown",
                options = {"High Priority", "Low Priority", "Rage Dump Only"},
                default = "Low Priority"
            },
            mortalStrikeMinRage = {
                displayName = "Mortal Strike Min Rage",
                description = "Minimum rage to use Mortal Strike (30 is default cost)",
                type = "slider",
                min = 30,
                max = 60,
                default = 30
            }
        },
        
        defensiveSettings = {
            useDefensiveStance = {
                displayName = "Use Defensive Stance",
                description = "Automatically switch to Defensive Stance at low health",
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
            },
            useDieByTheSword = {
                displayName = "Use Die By The Sword",
                description = "Automatically use Die By The Sword",
                type = "toggle",
                default = true
            },
            dieByTheSwordThreshold = {
                displayName = "Die By The Sword Threshold",
                description = "Health percentage to use Die By The Sword",
                type = "slider",
                min = 10,
                max = 50,
                default = 30
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
            }
        },
        
        offensiveSettings = {
            useAvatar = {
                displayName = "Use Avatar",
                description = "Automatically use Avatar",
                type = "toggle",
                default = true
            },
            useColossusSmash = {
                displayName = "Use Colossus Smash",
                description = "Automatically use Colossus Smash or Warbreaker",
                type = "toggle",
                default = true
            },
            useDeadlyCalm = {
                displayName = "Use Deadly Calm",
                description = "Automatically use Deadly Calm",
                type = "toggle",
                default = true
            },
            useBladestorm = {
                displayName = "Use Bladestorm",
                description = "Automatically use Bladestorm",
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
            useSkullsplitter = {
                displayName = "Use Skullsplitter",
                description = "Automatically use Skullsplitter",
                type = "toggle",
                default = true
            },
            skullsplitterRageThreshold = {
                displayName = "Skullsplitter Rage Threshold",
                description = "Maximum rage to use Skullsplitter",
                type = "slider",
                min = 30,
                max = 80,
                default = 60
            }
        },
        
        covenantSettings = {
            useCondemn = {
                displayName = "Use Condemn",
                description = "Automatically use Condemn (Venthyr)",
                type = "toggle",
                default = true
            },
            useSpearOfBastion = {
                displayName = "Use Spear of Bastion",
                description = "Automatically use Spear of Bastion (Kyrian)",
                type = "toggle",
                default = true
            },
            useAncientAftershock = {
                displayName = "Use Ancient Aftershock",
                description = "Automatically use Ancient Aftershock (Night Fae)",
                type = "toggle",
                default = true
            },
            useConquerorsBanner = {
                displayName = "Use Conqueror's Banner",
                description = "Automatically use Conqueror's Banner (Necrolord)",
                type = "toggle",
                default = true
            }
        },
        
        advancedSettings = {
            rendRefreshThreshold = {
                displayName = "Rend Refresh Threshold",
                description = "Seconds remaining to refresh Rend",
                type = "slider",
                min = 3,
                max = 8,
                default = 5
            },
            maxRagePool = {
                displayName = "Maximum Rage to Pool",
                description = "Maximum rage to save for Execute phase",
                type = "slider",
                min = 50,
                max = 100,
                default = 70
            },
            minRageSpend = {
                displayName = "Minimum Rage to Spend",
                description = "Minimum rage before using rage-consuming abilities",
                type = "slider",
                min = 20,
                max = 60,
                default = 40
            },
            poolForColossusSmash = {
                displayName = "Pool for Colossus Smash",
                description = "Pool rage when Colossus Smash is about to come off cooldown",
                type = "toggle",
                default = true
            },
            useCleave = {
                displayName = "Use Cleave",
                description = "When to use Cleave in AoE situations",
                type = "dropdown",
                options = {"Never", "Before Whirlwind", "After Whirlwind", "On Cooldown"},
                default = "Before Whirlwind"
            },
            prioritizeOverpower = {
                displayName = "Prioritize Overpower",
                description = "Always use Overpower when available",
                type = "toggle",
                default = true
            }
        },
        
        -- Advanced ability control settings
        abilityControls = {
            -- Colossus Smash / Warbreaker controls
            colossusSmash = AAC.RegisterAbility(spells.COLOSSUS_SMASH, {
                enabled = true,
                useDuringBurstOnly = false,
                useWithAvatar = true
            }),
            
            -- Avatar controls
            avatar = AAC.RegisterAbility(spells.AVATAR, {
                enabled = true,
                useDuringBurstOnly = true,
                useWithColossusSmash = true
            }),
            
            -- Sweeping Strikes controls
            sweepingStrikes = AAC.RegisterAbility(spells.SWEEPING_STRIKES, {
                enabled = true,
                minEnemies = 2,
                useWithBladestorm = true
            })
        }
    })
    
    return true
end

-- Register for events 
function Arms:RegisterEvents()
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
function Arms:UpdateTalentInfo()
    -- Check for important talents
    talents.hasRend = API.HasTalent(spells.REND)
    talents.hasSweepingStrikes = API.HasTalent(spells.SWEEPING_STRIKES)
    talents.hasSuddenDeath = API.HasTalent(spells.SUDDEN_DEATH)
    talents.hasDeadlyCalm = API.HasTalent(spells.DEADLY_CALM)
    talents.hasInForTheKill = API.HasTalent(spells.IN_FOR_THE_KILL)
    talents.hasMassacre = API.HasTalent(spells.MASSACRE)
    talents.hasDreadnaught = API.HasTalent(spells.DREADNAUGHT)
    talents.hasAvatar = API.HasTalent(spells.AVATAR)
    talents.hasCollateralDamage = API.HasTalent(spells.COLLATERAL_DAMAGE)
    talents.hasFervorOfBattle = API.HasTalent(spells.FERVOR_OF_BATTLE)
    talents.hasSkullsplitter = API.HasTalent(spells.SKULLSPLITTER)
    talents.hasTestOfMight = API.HasTalent(spells.TEST_OF_MIGHT)
    talents.hasStormOfDestruction = API.HasTalent(spells.STORM_OF_DESTRUCTION)
    talents.hasTactician = API.HasTalent(spells.TACTICIAN)
    talents.hasBattlelord = API.HasTalent(spells.BATTLELORD)
    talents.hasTideOfBlood = API.HasTalent(spells.TIDE_OF_BLOOD)
    talents.hasExecutionersPrecision = API.HasTalent(spells.EXECUTIONERS_PRECISION)
    talents.hasExploiter = API.HasTalent(spells.EXPLOITER)
    talents.hasSharpenedBlades = API.HasTalent(spells.SHARPENED_BLADES)
    talents.hasBloodletting = API.HasTalent(spells.BLOODLETTING)
    talents.hasBlademastersTorment = API.HasTalent(spells.BLADEMASTERS_TORMENT)
    talents.hasWarbreaker = API.HasTalent(spells.WARBREAKER)
    talents.hasCleave = API.HasTalent(spells.CLEAVE)
    
    API.PrintDebug("Arms Warrior talents updated")
    
    return true
end

-- Update rage tracking
function Arms:UpdateRage()
    currentRage = API.GetPlayerPower()
    return true
end

-- Update target data
function Arms:UpdateTargetData()
    -- Get target GUID
    local targetGUID = API.GetTargetGUID()
    
    if targetGUID and targetGUID ~= "" then
        -- Initialize target data if needed
        if not self.targetData[targetGUID] then
            self.targetData[targetGUID] = {
                rend = false,
                rendExpiration = 0,
                deepWounds = false,
                deepWoundsExpiration = 0,
                colossusSmash = false,
                colossusSmashExpiration = 0,
                spearOfBastion = false,
                spearOfBastionExpiration = 0
            }
        end
        
        -- Check for Rend
        local name, _, _, _, _, expiration = API.GetDebuffInfo(targetGUID, spells.REND_DEBUFF)
        if name then
            self.targetData[targetGUID].rend = true
            self.targetData[targetGUID].rendExpiration = expiration
            rendActive = true
            rendExpiration = expiration
        else
            self.targetData[targetGUID].rend = false
            self.targetData[targetGUID].rendExpiration = 0
            rendActive = false
            rendExpiration = 0
        end
        
        -- Check for Deep Wounds
        local name, _, _, _, _, expiration = API.GetDebuffInfo(targetGUID, spells.DEEP_WOUNDS)
        if name then
            self.targetData[targetGUID].deepWounds = true
            self.targetData[targetGUID].deepWoundsExpiration = expiration
            deepWoundsActive = true
            deepWoundsExpiration = expiration
        else
            self.targetData[targetGUID].deepWounds = false
            self.targetData[targetGUID].deepWoundsExpiration = 0
            deepWoundsActive = false
            deepWoundsExpiration = 0
        end
        
        -- Check for Colossus Smash
        local name, _, _, _, _, expiration = API.GetDebuffInfo(targetGUID, spells.COLOSSUS_SMASH_DEBUFF)
        if name then
            self.targetData[targetGUID].colossusSmash = true
            self.targetData[targetGUID].colossusSmashExpiration = expiration
            colossusSmashActive = true
            colossusSmashExpiration = expiration
        else
            self.targetData[targetGUID].colossusSmash = false
            self.targetData[targetGUID].colossusSmashExpiration = 0
            colossusSmashActive = false
            colossusSmashExpiration = 0
        end
        
        -- Check for Spear of Bastion
        local name, _, _, _, _, expiration = API.GetDebuffInfo(targetGUID, spells.SPEAR_OF_BASTION_DEBUFF)
        if name then
            self.targetData[targetGUID].spearOfBastion = true
            self.targetData[targetGUID].spearOfBastionExpiration = expiration
            spearOfBastionActive = true
        else
            self.targetData[targetGUID].spearOfBastion = false
            self.targetData[targetGUID].spearOfBastionExpiration = 0
            spearOfBastionActive = false
        end
    end
    
    -- Check if in execute phase
    executionPhase = API.GetTargetHealthPercent() <= (talents.hasMassacre and 35 or EXECUTION_THRESHOLD)
    
    -- Update AoE targets count
    currentAoETargets = API.GetNearbyEnemiesCount(8) -- Arms Warrior AoE radius
    
    return true
end

-- Handle combat log events
function Arms:HandleCombatLogEvent(...)
    local timestamp, eventType, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, spellID, spellName = CombatLogGetCurrentEventInfo()
    
    -- Only process events from the player
    if sourceGUID ~= API.GetPlayerGUID() then
        return false
    end
    
    -- Track buff applications
    if eventType == "SPELL_AURA_APPLIED" or eventType == "SPELL_AURA_REFRESH" then
        -- Track player buffs
        if destGUID == API.GetPlayerGUID() then
            -- Track Sudden Death
            if spellID == buffs.SUDDEN_DEATH then
                suddenDeathProc = true
                API.PrintDebug("Sudden Death proc activated")
            end
            
            -- Track Deadly Calm
            if spellID == buffs.DEADLY_CALM then
                deadlyCalm = true
                deadlyCalmExpiration = GetTime() + DEADLY_CALM_DURATION
                API.PrintDebug("Deadly Calm activated")
            end
            
            -- Track Sweeping Strikes
            if spellID == buffs.SWEEPING_STRIKES then
                sweepingStrikesActive = true
                API.PrintDebug("Sweeping Strikes activated")
            end
            
            -- Track Overpower buff
            if spellID == buffs.OVERPOWER then
                API.PrintDebug("Overpower buff applied")
            end
            
            -- Track Test of Might
            if spellID == buffs.TEST_OF_MIGHT then
                testOfMight = true
                API.PrintDebug("Test of Might activated")
            end
            
            -- Track Cleave
            if spellID == buffs.CLEAVE then
                cleaveActive = true
                API.PrintDebug("Cleave buff applied")
            end
            
            -- Track Conqueror's Banner
            if spellID == buffs.CONQUERORS_BANNER then
                conquerersBanner = true
                API.PrintDebug("Conqueror's Banner activated")
            end
            
            -- Track Conqueror's Draught stacks
            if spellID == buffs.CONQUERORS_DRAUGHT then
                conqueringDraught = select(4, API.GetBuffInfo("player", buffs.CONQUERORS_DRAUGHT)) or 0
                API.PrintDebug("Conqueror's Draught stacks: " .. tostring(conqueringDraught))
            end
            
            -- Track Defensive Stance
            if spellID == buffs.DEFENSIVE_STANCE then
                defensiveStance = true
                API.PrintDebug("Defensive Stance activated")
            end
            
            -- Track Die By The Sword
            if spellID == buffs.DIE_BY_THE_SWORD then
                dieByTheSword = true
                API.PrintDebug("Die By The Sword activated")
            end
            
            -- Track Tactician proc
            if spellID == buffs.TACTICIAN then
                API.PrintDebug("Tactician procced - Colossus Smash cooldown reset")
            end
            
            -- Track Battlelord proc
            if spellID == buffs.BATTLELORD then
                battlelord = true
                API.PrintDebug("Battlelord proc activated")
            end
            
            -- Track Shattered Defenses (CS effect)
            if spellID == buffs.SHATTERED_DEFENSES then
                shatteredDefenses = true
                API.PrintDebug("Shattered Defenses activated")
            end
            
            -- Track Exploiter proc
            if spellID == buffs.EXPLOITER then
                tidyProcActive = true
                API.PrintDebug("Exploiter proc activated")
            end
            
            -- Track Overlord's Critical (proc from Condemn/Execute)
            if spellID == buffs.OVERLORDS_CRITICAL then
                overlordsProcActive = true
                API.PrintDebug("Overlord's Critical proc activated")
            end
        end
        
        -- Track target debuffs
        local targetGUID = API.GetTargetGUID()
        if destGUID == targetGUID then
            -- Update target data for debuffs
            self:UpdateTargetData()
        end
    end
    
    -- Track buff removals
    if eventType == "SPELL_AURA_REMOVED" then
        -- Track player buffs
        if destGUID == API.GetPlayerGUID() then
            -- Track Sudden Death
            if spellID == buffs.SUDDEN_DEATH then
                suddenDeathProc = false
                API.PrintDebug("Sudden Death consumed")
            end
            
            -- Track Deadly Calm
            if spellID == buffs.DEADLY_CALM then
                deadlyCalm = false
                API.PrintDebug("Deadly Calm faded")
            end
            
            -- Track Sweeping Strikes
            if spellID == buffs.SWEEPING_STRIKES then
                sweepingStrikesActive = false
                API.PrintDebug("Sweeping Strikes faded")
            end
            
            -- Track Test of Might
            if spellID == buffs.TEST_OF_MIGHT then
                testOfMight = false
                API.PrintDebug("Test of Might faded")
            end
            
            -- Track Cleave
            if spellID == buffs.CLEAVE then
                cleaveActive = false
                API.PrintDebug("Cleave buff faded")
            end
            
            -- Track Conqueror's Banner
            if spellID == buffs.CONQUERORS_BANNER then
                conquerersBanner = false
                API.PrintDebug("Conqueror's Banner faded")
            end
            
            -- Track Defensive Stance
            if spellID == buffs.DEFENSIVE_STANCE then
                defensiveStance = false
                API.PrintDebug("Defensive Stance deactivated")
            end
            
            -- Track Die By The Sword
            if spellID == buffs.DIE_BY_THE_SWORD then
                dieByTheSword = false
                API.PrintDebug("Die By The Sword faded")
            end
            
            -- Track Battlelord proc
            if spellID == buffs.BATTLELORD then
                battlelord = false
                API.PrintDebug("Battlelord proc faded")
            end
            
            -- Track Shattered Defenses
            if spellID == buffs.SHATTERED_DEFENSES then
                shatteredDefenses = false
                API.PrintDebug("Shattered Defenses consumed")
            end
            
            -- Track Exploiter proc
            if spellID == buffs.EXPLOITER then
                tidyProcActive = false
                API.PrintDebug("Exploiter proc consumed")
            end
            
            -- Track Overlord's Critical
            if spellID == buffs.OVERLORDS_CRITICAL then
                overlordsProcActive = false
                API.PrintDebug("Overlord's Critical proc faded")
            end
        end
        
        -- Track target debuffs
        local targetGUID = API.GetTargetGUID()
        if destGUID == targetGUID then
            -- Update target data for debuffs
            self:UpdateTargetData()
        end
    end
    
    -- Track channeling
    if eventType == "SPELL_CHANNEL_START" and sourceGUID == API.GetPlayerGUID() then
        if spellID == spells.BLADESTORM then
            bladestormChanneling = true
            
            -- Start timer to track when channel ends
            C_Timer.After(BLADESTORM_DURATION, function()
                bladestormChanneling = false
                API.PrintDebug("Bladestorm channel ended")
            end)
            
            API.PrintDebug("Bladestorm channel started")
        end
    end
    
    -- Track channel end
    if eventType == "SPELL_CHANNEL_STOP" and sourceGUID == API.GetPlayerGUID() then
        if spellID == spells.BLADESTORM then
            bladestormChanneling = false
            API.PrintDebug("Bladestorm channel ended early")
        end
    end
    
    -- Track spell casts for cooldowns
    if eventType == "SPELL_CAST_SUCCESS" and sourceGUID == API.GetPlayerGUID() then
        if spellID == spells.COLOSSUS_SMASH or spellID == spells.WARBREAKER then
            colossusSmashActive = true
            colossusSmashExpiration = GetTime() + COLOSSUS_SMASH_DURATION
            
            -- Set Warbreaker cooldown tracking
            if spellID == spells.WARBREAKER then
                warbreaker = true
                
                -- Set a timer to track cooldown
                C_Timer.After(WARBREAKER_COOLDOWN, function()
                    warbreaker = false
                    API.PrintDebug("Warbreaker off cooldown")
                end)
            end
            
            API.PrintDebug("Colossus Smash/Warbreaker applied")
        elseif spellID == spells.AVATAR then
            -- Set a timer to track avatar duration
            C_Timer.After(AVATAR_DURATION, function()
                API.PrintDebug("Avatar faded")
            end)
            
            API.PrintDebug("Avatar activated")
        elseif spellID == spells.SWEEPING_STRIKES then
            sweepingStrikesActive = true
            
            -- Set a timer to track duration
            C_Timer.After(SWEEPING_STRIKES_DURATION, function()
                sweepingStrikesActive = false
                API.PrintDebug("Sweeping Strikes faded")
            end)
            
            API.PrintDebug("Sweeping Strikes activated")
        elseif spellID == spells.RAVAGER then
            ravagerActive = true
            
            -- Set a timer to track duration (typically 12 seconds)
            C_Timer.After(12, function()
                ravagerActive = false
                API.PrintDebug("Ravager faded")
            end)
            
            API.PrintDebug("Ravager placed")
        elseif spellID == spells.SPEAR_OF_BASTION then
            spearOfBastionActive = true
            
            -- Set a timer to track duration (typically 4 seconds)
            C_Timer.After(4, function()
                spearOfBastionActive = false
                API.PrintDebug("Spear of Bastion effect ended")
            end)
            
            API.PrintDebug("Spear of Bastion placed")
        elseif spellID == spells.CONQUERORS_BANNER then
            conquerersBanner = true
            
            -- Set a timer to track duration
            C_Timer.After(15, function()
                conquerersBanner = false
                API.PrintDebug("Conqueror's Banner faded")
            end)
            
            API.PrintDebug("Conqueror's Banner planted")
        elseif spellID == spells.EXECUTE or spellID == spells.CONDEMN then
            API.PrintDebug("Execute/Condemn used")
        elseif spellID == spells.WHIRLWIND then
            API.PrintDebug("Whirlwind used")
        elseif spellID == spells.MORTAL_STRIKE then
            API.PrintDebug("Mortal Strike used")
        elseif spellID == spells.CLEAVE then
            cleaveActive = true
            
            -- Set a timer to track duration
            C_Timer.After(6, function() -- Approximate duration
                cleaveActive = false
                API.PrintDebug("Cleave buff faded")
            end)
            
            API.PrintDebug("Cleave used")
        elseif spellID == spells.OVERPOWER then
            API.PrintDebug("Overpower used")
        elseif spellID == spells.REND then
            rendActive = true
            rendExpiration = GetTime() + REND_DURATION
            API.PrintDebug("Rend applied")
        elseif spellID == spells.DEADLY_CALM then
            deadlyCalm = true
            deadlyCalmExpiration = GetTime() + DEADLY_CALM_DURATION
            API.PrintDebug("Deadly Calm activated")
        elseif spellID == spells.SKULLSPLITTER then
            skullsplitter = true
            -- Skullsplitter is instant
            
            API.PrintDebug("Skullsplitter used")
        end
    end
    
    return true
end

-- Main rotation function
function Arms:RunRotation()
    -- Check if we should be running Arms Warrior logic
    if API.GetActiveSpecID() ~= ARMS_SPEC_ID then
        return false
    end
    
    -- Skip rotation if player is casting or channeling (like Bladestorm)
    if API.IsPlayerCasting() or API.IsPlayerChanneling() or bladestormChanneling then
        return false
    end
    
    -- Get settings
    local settings = ConfigRegistry:GetSettings("ArmsWarrior")
    
    -- Update variables
    self:UpdateRage()
    burstModeActive = settings.rotationSettings.burstEnabled and API.ShouldUseBurst()
    
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
    
    -- Check for AoE or Single Target
    if settings.rotationSettings.aoeEnabled and currentAoETargets >= settings.rotationSettings.aoeThreshold then
        return self:HandleAoERotation(settings)
    else
        return self:HandleSingleTargetRotation(settings)
    end
end

-- Handle interrupts
function Arms:HandleInterrupts()
    -- Use Pummel for interrupt
    if API.CanCast(spells.PUMMEL) and API.TargetIsSpellCastable() then
        API.CastSpell(spells.PUMMEL)
        return true
    end
    
    return false
end

-- Handle defensive abilities
function Arms:HandleDefensives(settings)
    local playerHealth = API.GetPlayerHealthPercent()
    
    -- Automatically switch to Defensive Stance at low health
    if settings.defensiveSettings.useDefensiveStance and
       playerHealth <= settings.defensiveSettings.defensiveStanceThreshold and
       not defensiveStance and
       API.CanCast(spells.DEFENSIVE_STANCE) then
        API.CastSpell(spells.DEFENSIVE_STANCE)
        return true
    end
    
    -- Use Die By The Sword for critical situations
    if settings.defensiveSettings.useDieByTheSword and
       playerHealth <= settings.defensiveSettings.dieByTheSwordThreshold and
       not dieByTheSword and
       API.CanCast(spells.DIE_BY_THE_SWORD) then
        API.CastSpell(spells.DIE_BY_THE_SWORD)
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
    
    -- Use Rallying Cry for emergency situations
    if settings.defensiveSettings.useRallyingCry and
       playerHealth <= settings.defensiveSettings.rallyingCryThreshold and
       API.CanCast(spells.RALLYING_CRY) then
        API.CastSpell(spells.RALLYING_CRY)
        return true
    end
    
    -- Use Victory Rush for healing if available
    if playerHealth < 80 and API.CanCast(spells.VICTORY_RUSH) then
        API.CastSpell(spells.VICTORY_RUSH)
        return true
    end
    
    return false
end

-- Handle cooldown abilities
function Arms:HandleCooldowns(settings)
    -- Skip if GCD is not ready
    if not API.IsGCDReady() then
        return false
    end
    
    -- Skip offensive cooldowns if not in burst mode
    if not burstModeActive then
        return false
    end
    
    -- Use Avatar with Colossus Smash
    if talents.hasAvatar and
       settings.offensiveSettings.useAvatar and
       settings.abilityControls.avatar.enabled and
       API.CanCast(spells.AVATAR) then
        
        -- If we want to align with Colossus Smash and it's active, or we don't care about alignment
        if not settings.abilityControls.avatar.useWithColossusSmash or colossusSmashActive then
            API.CastSpell(spells.AVATAR)
            return true
        end
    end
    
    -- Use Colossus Smash or Warbreaker
    if settings.offensiveSettings.useColossusSmash and
       settings.abilityControls.colossusSmash.enabled and
       not colossusSmashActive then
        
        -- Use Warbreaker if talented
        if talents.hasWarbreaker and API.CanCast(spells.WARBREAKER) then
            API.CastSpell(spells.WARBREAKER)
            return true
        -- Otherwise use Colossus Smash
        elseif API.CanCast(spells.COLOSSUS_SMASH) then
            API.CastSpell(spells.COLOSSUS_SMASH)
            return true
        end
    end
    
    -- Use Deadly Calm
    if talents.hasDeadlyCalm and
       settings.offensiveSettings.useDeadlyCalm and
       not deadlyCalm and
       API.CanCast(spells.DEADLY_CALM) then
        API.CastSpell(spells.DEADLY_CALM)
        return true
    end
    
    -- Use Sweeping Strikes for AoE
    if talents.hasSweepingStrikes and
       settings.abilityControls.sweepingStrikes.enabled and
       currentAoETargets >= settings.abilityControls.sweepingStrikes.minEnemies and
       not sweepingStrikesActive and
       API.CanCast(spells.SWEEPING_STRIKES) then
        
        -- Check if we want to use with Bladestorm
        if not settings.abilityControls.sweepingStrikes.useWithBladestorm or
           currentAoETargets >= settings.offensiveSettings.bladestormTargets then
            API.CastSpell(spells.SWEEPING_STRIKES)
            return true
        end
    end
    
    -- Use Bladestorm for AoE
    if settings.offensiveSettings.useBladestorm and
       currentAoETargets >= settings.offensiveSettings.bladestormTargets and
       API.CanCast(spells.BLADESTORM) then
        API.CastSpell(spells.BLADESTORM)
        return true
    end
    
    -- Use covenant abilities
    if self:HandleCovenantAbilities(settings) then
        return true
    end
    
    return false
end

-- Handle covenant abilities
function Arms:HandleCovenantAbilities(settings)
    -- Use Condemn (Venthyr) - replaces Execute
    if settings.covenantSettings.useCondemn and
       API.CanCast(spells.CONDEMN) and 
       settings.rotationSettings.useExecute then
        
        -- Use in execute phase or with Sudden Death proc
        if executionPhase or suddenDeathProc then
            API.CastSpell(spells.CONDEMN)
            return true
        end
    end
    
    -- Use Spear of Bastion (Kyrian)
    if settings.covenantSettings.useSpearOfBastion and
       API.CanCast(spells.SPEAR_OF_BASTION) then
        API.CastSpellAtCursor(spells.SPEAR_OF_BASTION)
        return true
    end
    
    -- Use Ancient Aftershock (Night Fae)
    if settings.covenantSettings.useAncientAftershock and
       API.CanCast(spells.ANCIENT_AFTERSHOCK) then
        API.CastSpellAtCursor(spells.ANCIENT_AFTERSHOCK)
        return true
    end
    
    -- Use Conqueror's Banner (Necrolord)
    if settings.covenantSettings.useConquerorsBanner and
       API.CanCast(spells.CONQUERORS_BANNER) then
        API.CastSpell(spells.CONQUERORS_BANNER)
        return true
    end
    
    return false
end

-- Handle AoE rotation
function Arms:HandleAoERotation(settings)
    -- Apply Rend if talented and enabled
    if talents.hasRend and
       settings.rotationSettings.useRend and
       API.CanCast(spells.REND) then
        
        -- Apply Rend if not present or about to expire
        if not rendActive or (rendExpiration - GetTime() < settings.advancedSettings.rendRefreshThreshold) then
            API.CastSpell(spells.REND)
            return true
        end
    end
    
    -- Execute during execute phase or with Sudden Death proc
    if settings.rotationSettings.useExecute and API.CanCast(spells.EXECUTE) then
        if (executionPhase or suddenDeathProc) and currentRage >= 20 then
            API.CastSpell(spells.EXECUTE)
            return true
        end
    end
    
    -- Cleave based on settings
    if talents.hasCleave and API.CanCast(spells.CLEAVE) and
       settings.advancedSettings.useCleave ~= "Never" then
        
        if settings.advancedSettings.useCleave == "On Cooldown" or
           (settings.advancedSettings.useCleave == "Before Whirlwind" and not cleaveActive) then
            API.CastSpell(spells.CLEAVE)
            return true
        end
    end
    
    -- Whirlwind for AoE damage
    if API.CanCast(spells.WHIRLWIND) then
        if settings.advancedSettings.useCleave ~= "After Whirlwind" or cleaveActive then
            API.CastSpell(spells.WHIRLWIND)
            return true
        end
    end
    
    -- Mortal Strike to apply Deep Wounds
    if API.CanCast(spells.MORTAL_STRIKE) and
       currentRage >= settings.rotationSettings.mortalStrikeMinRage and
       (not deepWoundsActive or deepWoundsExpiration - GetTime() < 4) then
        API.CastSpell(spells.MORTAL_STRIKE)
        return true
    end
    
    -- Overpower for rage generation
    if settings.advancedSettings.prioritizeOverpower and
       API.CanCast(spells.OVERPOWER) then
        API.CastSpell(spells.OVERPOWER)
        return true
    end
    
    -- Skullsplitter for rage generation
    if talents.hasSkullsplitter and
       settings.offensiveSettings.useSkullsplitter and
       currentRage <= settings.offensiveSettings.skullsplitterRageThreshold and
       API.CanCast(spells.SKULLSPLITTER) then
        API.CastSpell(spells.SKULLSPLITTER)
        return true
    end
    
    -- Slam as filler if configured
    if settings.rotationSettings.slamPriority == "High Priority" and
       currentRage >= 20 and
       API.CanCast(spells.SLAM) then
        API.CastSpell(spells.SLAM)
        return true
    end
    
    -- Use Whirlwind as a filler
    if API.CanCast(spells.WHIRLWIND) then
        API.CastSpell(spells.WHIRLWIND)
        return true
    end
    
    -- Slam as low priority filler
    if (settings.rotationSettings.slamPriority == "Low Priority" or 
        settings.rotationSettings.slamPriority == "Rage Dump Only") and
       currentRage >= 20 and
       API.CanCast(spells.SLAM) then
        API.CastSpell(spells.SLAM)
        return true
    end
    
    return false
end

-- Handle Single Target rotation
function Arms:HandleSingleTargetRotation(settings)
    -- Apply Rend if talented and enabled
    if talents.hasRend and
       settings.rotationSettings.useRend and
       API.CanCast(spells.REND) then
        
        -- Apply Rend if not present or about to expire
        if not rendActive or (rendExpiration - GetTime() < settings.advancedSettings.rendRefreshThreshold) then
            API.CastSpell(spells.REND)
            return true
        end
    end
    
    -- Execute during execute phase or with Sudden Death proc
    if settings.rotationSettings.useExecute and API.CanCast(spells.EXECUTE) then
        if (executionPhase or suddenDeathProc) and currentRage >= 20 then
            API.CastSpell(spells.EXECUTE)
            return true
        end
    end
    
    -- Mortal Strike
    if API.CanCast(spells.MORTAL_STRIKE) and
       currentRage >= settings.rotationSettings.mortalStrikeMinRage then
        API.CastSpell(spells.MORTAL_STRIKE)
        return true
    end
    
    -- Skullsplitter for rage generation
    if talents.hasSkullsplitter and
       settings.offensiveSettings.useSkullsplitter and
       currentRage <= settings.offensiveSettings.skullsplitterRageThreshold and
       API.CanCast(spells.SKULLSPLITTER) then
        API.CastSpell(spells.SKULLSPLITTER)
        return true
    end
    
    -- Overpower for rage generation and procs
    if API.CanCast(spells.OVERPOWER) then
        API.CastSpell(spells.OVERPOWER)
        return true
    end
    
    -- Slam as filler based on priority setting
    if settings.rotationSettings.slamPriority ~= "Rage Dump Only" and
       currentRage >= 20 and
       API.CanCast(spells.SLAM) then
        API.CastSpell(spells.SLAM)
        return true
    end
    
    -- Whirlwind as filler with Fervor of Battle
    if talents.hasFervorOfBattle and
       currentRage >= 30 and
       API.CanCast(spells.WHIRLWIND) then
        API.CastSpell(spells.WHIRLWIND)
        return true
    end
    
    -- Slam as rage dump
    if settings.rotationSettings.slamPriority == "Rage Dump Only" and
       currentRage >= 50 and
       API.CanCast(spells.SLAM) then
        API.CastSpell(spells.SLAM)
        return true
    end
    
    return false
end

-- Handle specialization change
function Arms:OnSpecializationChanged()
    -- Update talent information
    self:UpdateTalentInfo()
    
    -- Reset state variables
    nextCastOverride = nil
    burstModeActive = false
    currentRage = API.GetPlayerPower()
    maxRage = 100
    rendActive = false
    rendExpiration = 0
    deepWoundsActive = false
    deepWoundsExpiration = 0
    executionPhase = false
    sweepingStrikesActive = false
    colossusSmashActive = false
    colossusSmashExpiration = 0
    suddenDeathProc = false
    deadlyCalm = false
    deadlyCalmExpiration = 0
    bladestormChanneling = false
    inForTheKill = false
    ravagerActive = false
    ravagerExpiration = 0
    spearOfBastionActive = false
    conquerersBanner = false
    conqueringDraught = 0
    testOfMight = false
    skullsplitter = false
    fervorOfBattle = false
    strengthOfArms = false
    cleaveActive = false
    tidyProcActive = false
    warbreaker = false
    shatteredDefenses = false
    battlelord = false
    defensiveStance = false
    dieByTheSword = false
    overlordsProcActive = false
    
    API.PrintDebug("Arms Warrior state reset on spec change")
    
    return true
end

-- Return the module for loading
return Arms