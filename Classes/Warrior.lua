------------------------------------------
-- WindrunnerRotations - Warrior Class Module
-- Author: VortexQ8
-- The War Within Season 2
------------------------------------------

local addonName, WR = ...
local WarriorModule = {}
WR.Warrior = WarriorModule

-- Dependencies
local API = WR.API
local ConfigRegistry = WR.ConfigRegistry
local RotationManager = WR.RotationManager
local ErrorHandler = WR.ErrorHandler
local CombatAnalysis = WR.CombatAnalysis
local AntiDetectionSystem = WR.AntiDetectionSystem
local PvPManager = WR.PvPManager

-- Warrior constants
local CLASS_ID = 1 -- Warrior class ID
local SPEC_ARMS = 71
local SPEC_FURY = 72
local SPEC_PROT = 73

-- Current player data
local playerSpec = 0
local isEnabled = true
local inCombat = false

-- Spell IDs for Arms Warrior (The War Within, Season 2)
local ARMS_SPELLS = {
    -- Core abilities
    MORTAL_STRIKE = 12294,
    OVERPOWER = 7384,
    SLAM = 1464,
    EXECUTE = 163201,
    CLEAVE = 845,
    WHIRLWIND = 1680,
    BLADESTORM = 227847,
    COLOSSUS_SMASH = 167105,
    WARBREAKER = 262161,
    
    -- Defensive & utility
    DEFENSIVE_STANCE = 386164,
    DIE_BY_THE_SWORD = 118038,
    RALLYING_CRY = 97462,
    IGNORE_PAIN = 190456,
    VICTORY_RUSH = 34428,
    SPELL_REFLECTION = 23920,
    INTIMIDATING_SHOUT = 5246,
    INTERVENE = 3411,
    PIERCING_HOWL = 12323,
    CHARGE = 100,
    HEROIC_LEAP = 6544,
    
    -- Talents
    REND = 772,
    STORM_BOLT = 107570,
    AVATAR = 107574,
    SWEEPING_STRIKES = 260708,
    SPEAR_OF_BASTION = 376080,
    RAVAGER = 152277,
    SKULLSPLITTER = 260643,
    DEADLY_CALM = 262228,
    DREADNAUGHT = 262150,
    
    -- Rage generators
    CHARGE_RAGE = 100,
    CONQUERORS_BANNER = 324143,
    
    -- Misc
    BATTLE_STANCE = 386164,
    BATTLE_SHOUT = 6673,
    BERSERKER_RAGE = 18499,
    HAMSTRING = 1715,
    SHATTERING_THROW = 64382,
    HEROIC_THROW = 57755
}

-- Spell IDs for Fury Warrior
local FURY_SPELLS = {
    -- Core abilities
    BLOODTHIRST = 23881,
    RAGING_BLOW = 85288,
    RAMPAGE = 184367,
    EXECUTE_FURY = 5308,
    WHIRLWIND = 190411,
    ONSLAUGHT = 315720,
    CRUSHING_BLOW = 335097,
    
    -- Defensive & utility
    ENRAGED_REGENERATION = 184364,
    RALLYING_CRY = 97462,
    VICTORY_RUSH = 34428,
    SPELL_REFLECTION = 23920,
    INTIMIDATING_SHOUT = 5246,
    PIERCING_HOWL = 12323,
    CHARGE = 100,
    HEROIC_LEAP = 6544,
    
    -- Talents
    SUDDEN_DEATH = 280721,
    STORM_BOLT = 107570,
    AVATAR = 107574,
    SPEAR_OF_BASTION = 376080,
    RAVAGER = 228920,
    BLADESTORM_FURY = 46924,
    RECKLESSNESS = 1719,
    SIEGEBREAKER = 280772,
    MEAT_CLEAVER = 280392,
    
    -- Rage generators
    CHARGE_RAGE = 100,
    CONQUERORS_BANNER = 324143,
    
    -- Misc
    BATTLE_STANCE = 386164,
    BATTLE_SHOUT = 6673,
    BERSERKER_RAGE = 18499,
    HAMSTRING = 1715,
    SHATTERING_THROW = 64382,
    HEROIC_THROW = 57755
}

-- Spell IDs for Protection Warrior
local PROT_SPELLS = {
    -- Core abilities
    SHIELD_SLAM = 23922,
    THUNDER_CLAP = 6343,
    REVENGE = 6572,
    EXECUTE_PROT = 163201,
    DEVASTATE = 20243,
    IGNORE_PAIN = 190456,
    SHIELD_BLOCK = 2565,
    DEMORALIZING_SHOUT = 1160,
    SHIELD_WALL = 871,
    LAST_STAND = 12975,
    
    -- Defensive & utility
    SPELL_REFLECTION = 23920,
    RALLYING_CRY = 97462,
    VICTORY_RUSH = 34428,
    INTIMIDATING_SHOUT = 5246,
    INTERVENE = 3411,
    PIERCING_HOWL = 12323,
    CHARGE = 100,
    HEROIC_LEAP = 6544,
    
    -- Talents
    STORM_BOLT = 107570,
    AVATAR = 107574,
    SPEAR_OF_BASTION = 376080,
    RAVAGER = 228920,
    SHOCKWAVE = 46968,
    BOLSTER = 280001,
    UNSTOPPABLE_FORCE = 275336,
    BOOMING_VOICE = 202743,
    
    -- Rage generators
    CHARGE_RAGE = 100,
    CONQUERORS_BANNER = 324143,
    
    -- Misc
    BATTLE_STANCE = 386164,
    BATTLE_SHOUT = 6673,
    BERSERKER_RAGE = 18499,
    HAMSTRING = 1715,
    SHATTERING_THROW = 64382,
    HEROIC_THROW = 57755
}

-- Important buffs to track
local BUFFS = {
    SUDDEN_DEATH = 52437,
    OVERPOWER = 7384,
    CRUSHING_BLOW = 335097,
    VICTORIOUS = 32216,
    SLAM = 1464,
    AVATAR = 107574,
    RECKLESSNESS = 1719,
    ENRAGE = 184362,
    SHIELD_BLOCK = 132404,
    LAST_STAND = 12975,
    SPELL_REFLECTION = 23920,
    DEFENSIVE_STANCE = 386164,
    DIE_BY_THE_SWORD = 118038,
    SWEEPING_STRIKES = 260708,
    DEADLY_CALM = 262228,
    RALLYING_CRY = 97462,
    RAVAGER = 152277
}

-- Important debuffs to track
local DEBUFFS = {
    COLOSSUS_SMASH = 208086,
    DEEP_WOUNDS = 262115,
    REND = 772,
    SIEGEBREAKER = 280773,
    HAMSTRING = 1715,
    DEMORALIZING_SHOUT = 1160,
    THUNDER_CLAP = 6343
}

-- Initialize the Warrior module
function WarriorModule:Initialize()
    -- Register settings
    self:RegisterSettings()
    
    -- Register events
    self:RegisterEvents()
    
    -- Register rotations
    self:RegisterRotations()
    
    API.PrintDebug("Warrior module initialized")
    return true
end

-- Register settings
function WarriorModule:RegisterSettings()
    ConfigRegistry:RegisterSettings("Warrior", {
        generalSettings = {
            enabled = {
                displayName = "Enable Warrior Module",
                description = "Enable the Warrior module for all specs",
                type = "toggle",
                default = true
            },
            useDefensives = {
                displayName = "Use Defensive Abilities",
                description = "Automatically use defensive abilities when appropriate",
                type = "toggle",
                default = true
            },
            useInterrupts = {
                displayName = "Use Interrupts",
                description = "Automatically interrupt enemy casts when appropriate",
                type = "toggle",
                default = true
            },
            useMovementAbilities = {
                displayName = "Use Movement Abilities",
                description = "Use movement abilities like Charge and Heroic Leap",
                type = "toggle",
                default = true
            }
        },
        armsSettings = {
            useRend = {
                displayName = "Use Rend",
                description = "Maintain Rend on targets",
                type = "toggle",
                default = true
            },
            cleaveThreshold = {
                displayName = "Cleave Threshold",
                description = "Number of targets to use Cleave/Whirlwind",
                type = "slider",
                min = 2,
                max = 5,
                step = 1,
                default = 2
            },
            useSweepingStrikes = {
                displayName = "Use Sweeping Strikes",
                description = "Use Sweeping Strikes for AoE situations",
                type = "toggle",
                default = true
            },
            useBladestorm = {
                displayName = "Use Bladestorm",
                description = "Use Bladestorm in combat",
                type = "toggle",
                default = true
            },
            bladestormThreshold = {
                displayName = "Bladestorm Threshold",
                description = "Minimum number of targets to use Bladestorm",
                type = "slider",
                min = 1,
                max = 5,
                step = 1,
                default = 3
            },
            useAvatar = {
                displayName = "Use Avatar",
                description = "Use Avatar in combat",
                type = "toggle",
                default = true
            },
            avatarWithColossusSmash = {
                displayName = "Avatar with Colossus Smash",
                description = "Only use Avatar with Colossus Smash",
                type = "toggle",
                default = true
            }
        },
        furySettings = {
            enrageMinimum = {
                displayName = "Enrage Uptime Goal",
                description = "Minimum enrage uptime percentage to aim for",
                type = "slider",
                min = 70,
                max = 100,
                step = 5,
                default = 85
            },
            whirlwindThreshold = {
                displayName = "Whirlwind Threshold",
                description = "Number of targets to prioritize Whirlwind",
                type = "slider",
                min = 2,
                max = 5,
                step = 1,
                default = 3
            },
            useRecklessness = {
                displayName = "Use Recklessness",
                description = "Use Recklessness in combat",
                type = "toggle",
                default = true
            },
            useBladestorm = {
                displayName = "Use Bladestorm",
                description = "Use Bladestorm in combat",
                type = "toggle",
                default = true
            },
            bladestormThreshold = {
                displayName = "Bladestorm Threshold",
                description = "Minimum number of targets to use Bladestorm",
                type = "slider",
                min = 1,
                max = 5,
                step = 1,
                default = 3
            }
        },
        protSettings = {
            ignoreThreshold = {
                displayName = "Ignore Pain Threshold",
                description = "Health percentage to use Ignore Pain",
                type = "slider",
                min = 30,
                max = 90,
                step = 5,
                default = 70
            },
            shieldBlockUptime = {
                displayName = "Shield Block Uptime Goal",
                description = "Minimum Shield Block uptime percentage",
                type = "slider",
                min = 50,
                max = 100,
                step = 5,
                default = 80
            },
            lastStandThreshold = {
                displayName = "Last Stand Threshold",
                description = "Health percentage to use Last Stand",
                type = "slider",
                min = 10,
                max = 50,
                step = 5,
                default = 30
            },
            shieldWallThreshold = {
                displayName = "Shield Wall Threshold",
                description = "Health percentage to use Shield Wall",
                type = "slider",
                min = 10,
                max = 40,
                step = 5,
                default = 25
            },
            useShockwave = {
                displayName = "Use Shockwave",
                description = "Use Shockwave for AoE stun",
                type = "toggle",
                default = true
            },
            shockwaveThreshold = {
                displayName = "Shockwave Threshold",
                description = "Minimum number of targets to use Shockwave",
                type = "slider",
                min = 1,
                max = 5,
                step = 1,
                default = 2
            },
            useAvatar = {
                displayName = "Use Avatar",
                description = "Use Avatar in combat",
                type = "toggle",
                default = true
            }
        }
    })
    
    -- Add callback for settings changes
    ConfigRegistry:RegisterCallback("Warrior", function(settings)
        self:ApplySettings(settings)
    end)
}

-- Apply settings
function WarriorModule:ApplySettings(settings)
    -- Apply general settings
    isEnabled = settings.generalSettings.enabled
}

-- Register events
function WarriorModule:RegisterEvents()
    -- Register for specialization changed event
    API.RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", function(unit)
        if unit == "player" then
            self:OnSpecializationChanged()
        end
    end)
    
    -- Register for entering combat event
    API.RegisterEvent("PLAYER_REGEN_DISABLED", function()
        inCombat = true
    end)
    
    -- Register for leaving combat event
    API.RegisterEvent("PLAYER_REGEN_ENABLED", function()
        inCombat = false
    end)
    
    -- Update specialization on initialization
    self:OnSpecializationChanged()
}

-- On specialization changed
function WarriorModule:OnSpecializationChanged()
    -- Get current spec ID
    playerSpec = API.GetActiveSpecID()
    
    API.PrintDebug("Warrior specialization changed: " .. playerSpec)
    
    -- Ensure correct rotation is registered
    if playerSpec == SPEC_ARMS then
        self:RegisterArmsRotation()
    elseif playerSpec == SPEC_FURY then
        self:RegisterFuryRotation()
    elseif playerSpec == SPEC_PROT then
        self:RegisterProtRotation()
    end
}

-- Register rotations
function WarriorModule:RegisterRotations()
    -- Register spec-specific rotations
    self:RegisterArmsRotation()
    self:RegisterFuryRotation()
    self:RegisterProtRotation()
}

-- Register Arms rotation
function WarriorModule:RegisterArmsRotation()
    RotationManager:RegisterRotation("WarriorArms", {
        id = "WarriorArms",
        name = "Warrior - Arms",
        class = "WARRIOR",
        spec = SPEC_ARMS,
        level = 10,
        description = "Arms Warrior rotation for The War Within Season 2",
        author = "WindrunnerRotations",
        version = "1.0.0",
        rotation = function()
            return self:ArmsRotation()
        end
    })
}

-- Register Fury rotation
function WarriorModule:RegisterFuryRotation()
    RotationManager:RegisterRotation("WarriorFury", {
        id = "WarriorFury",
        name = "Warrior - Fury",
        class = "WARRIOR",
        spec = SPEC_FURY,
        level = 10,
        description = "Fury Warrior rotation for The War Within Season 2",
        author = "WindrunnerRotations",
        version = "1.0.0",
        rotation = function()
            return self:FuryRotation()
        end
    })
}

-- Register Protection rotation
function WarriorModule:RegisterProtRotation()
    RotationManager:RegisterRotation("WarriorProt", {
        id = "WarriorProt",
        name = "Warrior - Protection",
        class = "WARRIOR",
        spec = SPEC_PROT,
        level = 10,
        description = "Protection Warrior rotation for The War Within Season 2",
        author = "WindrunnerRotations",
        version = "1.0.0",
        rotation = function()
            return self:ProtRotation()
        end
    })
}

-- Arms rotation
function WarriorModule:ArmsRotation()
    -- Check if we should execute
    if not self:ShouldExecuteRotation() then
        return nil
    end
    
    -- Get player and target
    local player = "player"
    local target = "target"
    
    -- Check if we have a target
    if not UnitExists(target) or not UnitCanAttack(player, target) or UnitIsDead(target) then
        return nil
    end
    
    -- Get settings
    local settings = ConfigRegistry:GetSettings("Warrior")
    
    -- Common Combat Variables
    local health, maxHealth, healthPercent = API.GetUnitHealth(player)
    local targetHealth, targetMaxHealth, targetHealthPercent = API.GetUnitHealth(target)
    local rage, maxRage, ragePercent = API.GetUnitPower(player, Enum.PowerType.Rage)
    local inExecutePhase = targetHealthPercent <= 20
    local enemies = API.GetEnemyCount(8)
    local aoeEnabled = settings.armsSettings.cleaveThreshold <= enemies
    
    -- Battle Stance
    if not API.UnitHasBuff(player, BUFFS.BATTLE_STANCE) and not API.UnitHasBuff(player, BUFFS.DEFENSIVE_STANCE) then
        return {
            type = "spell",
            id = ARMS_SPELLS.BATTLE_STANCE,
            target = player
        }
    end
    
    -- Battle Shout
    if not API.UnitHasBuff(player, BUFFS.BATTLE_SHOUT) then
        return {
            type = "spell",
            id = ARMS_SPELLS.BATTLE_SHOUT,
            target = player
        }
    end
    
    -- Defensive abilities
    if settings.generalSettings.useDefensives then
        -- Die by the Sword at low health
        if healthPercent < 35 and API.IsSpellKnown(ARMS_SPELLS.DIE_BY_THE_SWORD) and API.IsSpellUsable(ARMS_SPELLS.DIE_BY_THE_SWORD) then
            return {
                type = "spell",
                id = ARMS_SPELLS.DIE_BY_THE_SWORD,
                target = player
            }
        end
        
        -- Victory Rush when available and needed
        if healthPercent < 80 and API.UnitHasBuff(player, BUFFS.VICTORIOUS) and 
           API.IsSpellKnown(ARMS_SPELLS.VICTORY_RUSH) and API.IsSpellUsable(ARMS_SPELLS.VICTORY_RUSH) then
            return {
                type = "spell",
                id = ARMS_SPELLS.VICTORY_RUSH,
                target = target
            }
        end
        
        -- Defensive Stance at low health
        if healthPercent < 40 and not API.UnitHasBuff(player, BUFFS.DEFENSIVE_STANCE) and 
           API.IsSpellKnown(ARMS_SPELLS.DEFENSIVE_STANCE) and API.IsSpellUsable(ARMS_SPELLS.DEFENSIVE_STANCE) then
            return {
                type = "spell",
                id = ARMS_SPELLS.DEFENSIVE_STANCE,
                target = player
            }
        end
    end
    
    -- Offensive cooldowns
    if inCombat then
        -- Avatar with Colossus Smash
        if settings.armsSettings.useAvatar and 
           API.IsSpellKnown(ARMS_SPELLS.AVATAR) and API.IsSpellUsable(ARMS_SPELLS.AVATAR) then
            if not settings.armsSettings.avatarWithColossusSmash or API.UnitHasDebuff(target, DEBUFFS.COLOSSUS_SMASH) then
                return {
                    type = "spell",
                    id = ARMS_SPELLS.AVATAR,
                    target = player
                }
            end
        end
        
        -- Sweeping Strikes for AoE
        if settings.armsSettings.useSweepingStrikes and enemies >= 2 and 
           API.IsSpellKnown(ARMS_SPELLS.SWEEPING_STRIKES) and API.IsSpellUsable(ARMS_SPELLS.SWEEPING_STRIKES) and
           not API.UnitHasBuff(player, BUFFS.SWEEPING_STRIKES) then
            return {
                type = "spell",
                id = ARMS_SPELLS.SWEEPING_STRIKES,
                target = player
            }
        end
        
        -- Bladestorm for AoE
        if settings.armsSettings.useBladestorm and enemies >= settings.armsSettings.bladestormThreshold and
           API.IsSpellKnown(ARMS_SPELLS.BLADESTORM) and API.IsSpellUsable(ARMS_SPELLS.BLADESTORM) then
            return {
                type = "spell",
                id = ARMS_SPELLS.BLADESTORM,
                target = player
            }
        end
        
        -- Warbreaker/Colossus Smash for debuff
        if API.IsSpellKnown(ARMS_SPELLS.WARBREAKER) and API.IsSpellUsable(ARMS_SPELLS.WARBREAKER) then
            return {
                type = "spell",
                id = ARMS_SPELLS.WARBREAKER,
                target = target
            }
        elseif API.IsSpellKnown(ARMS_SPELLS.COLOSSUS_SMASH) and API.IsSpellUsable(ARMS_SPELLS.COLOSSUS_SMASH) and
               not API.UnitHasDebuff(target, DEBUFFS.COLOSSUS_SMASH) then
            return {
                type = "spell",
                id = ARMS_SPELLS.COLOSSUS_SMASH,
                target = target
            }
        end
    end
    
    -- Core rotation
    if inExecutePhase and API.IsSpellKnown(ARMS_SPELLS.EXECUTE) and API.IsSpellUsable(ARMS_SPELLS.EXECUTE) then
        -- Execute during execute phase
        return {
            type = "spell",
            id = ARMS_SPELLS.EXECUTE,
            target = target
        }
    elseif API.IsSpellKnown(ARMS_SPELLS.MORTAL_STRIKE) and API.IsSpellUsable(ARMS_SPELLS.MORTAL_STRIKE) then
        -- Mortal Strike on cooldown
        return {
            type = "spell",
            id = ARMS_SPELLS.MORTAL_STRIKE,
            target = target
        }
    elseif settings.armsSettings.useRend and API.IsSpellKnown(ARMS_SPELLS.REND) and API.IsSpellUsable(ARMS_SPELLS.REND) and
           not API.UnitHasDebuff(target, DEBUFFS.REND) then
        -- Maintain Rend
        return {
            type = "spell",
            id = ARMS_SPELLS.REND,
            target = target
        }
    elseif API.IsSpellKnown(ARMS_SPELLS.OVERPOWER) and API.IsSpellUsable(ARMS_SPELLS.OVERPOWER) then
        -- Overpower to build stacks and generate rage
        return {
            type = "spell",
            id = ARMS_SPELLS.OVERPOWER,
            target = target
        }
    elseif aoeEnabled and enemies >= 3 and API.IsSpellKnown(ARMS_SPELLS.CLEAVE) and API.IsSpellUsable(ARMS_SPELLS.CLEAVE) then
        -- Cleave for AoE
        return {
            type = "spell",
            id = ARMS_SPELLS.CLEAVE,
            target = target
        }
    elseif aoeEnabled and enemies >= 4 and API.IsSpellKnown(ARMS_SPELLS.WHIRLWIND) and API.IsSpellUsable(ARMS_SPELLS.WHIRLWIND) then
        -- Whirlwind for larger AoE
        return {
            type = "spell",
            id = ARMS_SPELLS.WHIRLWIND,
            target = target
        }
    elseif API.IsSpellKnown(ARMS_SPELLS.SLAM) and API.IsSpellUsable(ARMS_SPELLS.SLAM) and rage >= 20 then
        -- Slam as rage dump
        return {
            type = "spell",
            id = ARMS_SPELLS.SLAM,
            target = target
        }
    end
    
    return nil
}

-- Fury rotation
function WarriorModule:FuryRotation()
    -- Check if we should execute
    if not self:ShouldExecuteRotation() then
        return nil
    end
    
    -- Get player and target
    local player = "player"
    local target = "target"
    
    -- Check if we have a target
    if not UnitExists(target) or not UnitCanAttack(player, target) or UnitIsDead(target) then
        return nil
    end
    
    -- Get settings
    local settings = ConfigRegistry:GetSettings("Warrior")
    
    -- Common Combat Variables
    local health, maxHealth, healthPercent = API.GetUnitHealth(player)
    local targetHealth, targetMaxHealth, targetHealthPercent = API.GetUnitHealth(target)
    local rage, maxRage, ragePercent = API.GetUnitPower(player, Enum.PowerType.Rage)
    local inExecutePhase = targetHealthPercent <= 20
    local enemies = API.GetEnemyCount(8)
    local aoeEnabled = enemies >= settings.furySettings.whirlwindThreshold
    local isEnraged = API.UnitHasBuff(player, BUFFS.ENRAGE)
    
    -- Battle Shout
    if not API.UnitHasBuff(player, BUFFS.BATTLE_SHOUT) then
        return {
            type = "spell",
            id = FURY_SPELLS.BATTLE_SHOUT,
            target = player
        }
    end
    
    -- Defensive abilities
    if settings.generalSettings.useDefensives then
        -- Enraged Regeneration at low health
        if healthPercent < 40 and API.IsSpellKnown(FURY_SPELLS.ENRAGED_REGENERATION) and API.IsSpellUsable(FURY_SPELLS.ENRAGED_REGENERATION) then
            return {
                type = "spell",
                id = FURY_SPELLS.ENRAGED_REGENERATION,
                target = player
            }
        end
        
        -- Victory Rush when available and needed
        if healthPercent < 80 and API.UnitHasBuff(player, BUFFS.VICTORIOUS) and 
           API.IsSpellKnown(FURY_SPELLS.VICTORY_RUSH) and API.IsSpellUsable(FURY_SPELLS.VICTORY_RUSH) then
            return {
                type = "spell",
                id = FURY_SPELLS.VICTORY_RUSH,
                target = target
            }
        end
    end
    
    -- Offensive cooldowns
    if inCombat then
        -- Recklessness
        if settings.furySettings.useRecklessness and 
           API.IsSpellKnown(FURY_SPELLS.RECKLESSNESS) and API.IsSpellUsable(FURY_SPELLS.RECKLESSNESS) then
            return {
                type = "spell",
                id = FURY_SPELLS.RECKLESSNESS,
                target = player
            }
        end
        
        -- Bladestorm for AoE
        if settings.furySettings.useBladestorm and enemies >= settings.furySettings.bladestormThreshold and
           API.IsSpellKnown(FURY_SPELLS.BLADESTORM_FURY) and API.IsSpellUsable(FURY_SPELLS.BLADESTORM_FURY) then
            return {
                type = "spell",
                id = FURY_SPELLS.BLADESTORM_FURY,
                target = player
            }
        end
        
        -- Whirlwind for AoE buff
        if aoeEnabled and API.IsSpellKnown(FURY_SPELLS.WHIRLWIND) and API.IsSpellUsable(FURY_SPELLS.WHIRLWIND) then
            return {
                type = "spell",
                id = FURY_SPELLS.WHIRLWIND,
                target = target
            }
        end
    end
    
    -- Core rotation
    if rage >= 80 and API.IsSpellKnown(FURY_SPELLS.RAMPAGE) and API.IsSpellUsable(FURY_SPELLS.RAMPAGE) then
        -- Rampage to spend rage and get enrage
        return {
            type = "spell",
            id = FURY_SPELLS.RAMPAGE,
            target = target
        }
    elseif inExecutePhase and API.IsSpellKnown(FURY_SPELLS.EXECUTE_FURY) and API.IsSpellUsable(FURY_SPELLS.EXECUTE_FURY) then
        -- Execute during execute phase
        return {
            type = "spell",
            id = FURY_SPELLS.EXECUTE_FURY,
            target = target
        }
    elseif API.IsSpellKnown(FURY_SPELLS.BLOODTHIRST) and API.IsSpellUsable(FURY_SPELLS.BLOODTHIRST) then
        -- Bloodthirst for rage and enrage
        return {
            type = "spell",
            id = FURY_SPELLS.BLOODTHIRST,
            target = target
        }
    elseif API.IsSpellKnown(FURY_SPELLS.RAGING_BLOW) and API.IsSpellUsable(FURY_SPELLS.RAGING_BLOW) then
        -- Raging Blow for damage and rage
        return {
            type = "spell",
            id = FURY_SPELLS.RAGING_BLOW,
            target = target
        }
    end
    
    return nil
}

-- Protection rotation
function WarriorModule:ProtRotation()
    -- Check if we should execute
    if not self:ShouldExecuteRotation() then
        return nil
    end
    
    -- Get player and target
    local player = "player"
    local target = "target"
    
    -- Check if we have a target
    if not UnitExists(target) or not UnitCanAttack(player, target) or UnitIsDead(target) then
        return nil
    end
    
    -- Get settings
    local settings = ConfigRegistry:GetSettings("Warrior")
    
    -- Common Combat Variables
    local health, maxHealth, healthPercent = API.GetUnitHealth(player)
    local targetHealth, targetMaxHealth, targetHealthPercent = API.GetUnitHealth(target)
    local rage, maxRage, ragePercent = API.GetUnitPower(player, Enum.PowerType.Rage)
    local inExecutePhase = targetHealthPercent <= 20
    local enemies = API.GetEnemyCount(8)
    
    -- Battle Shout
    if not API.UnitHasBuff(player, BUFFS.BATTLE_SHOUT) then
        return {
            type = "spell",
            id = PROT_SPELLS.BATTLE_SHOUT,
            target = player
        }
    end
    
    -- Defensive abilities
    if settings.generalSettings.useDefensives then
        -- Shield Block if not active
        if not API.UnitHasBuff(player, BUFFS.SHIELD_BLOCK) and 
           API.IsSpellKnown(PROT_SPELLS.SHIELD_BLOCK) and API.IsSpellUsable(PROT_SPELLS.SHIELD_BLOCK) and
           rage >= 30 then
            return {
                type = "spell",
                id = PROT_SPELLS.SHIELD_BLOCK,
                target = player
            }
        end
        
        -- Ignore Pain when taking damage
        if healthPercent < settings.protSettings.ignoreThreshold and
           API.IsSpellKnown(PROT_SPELLS.IGNORE_PAIN) and API.IsSpellUsable(PROT_SPELLS.IGNORE_PAIN) and
           rage >= 40 then
            return {
                type = "spell",
                id = PROT_SPELLS.IGNORE_PAIN,
                target = player
            }
        end
        
        -- Last Stand at low health
        if healthPercent < settings.protSettings.lastStandThreshold and 
           API.IsSpellKnown(PROT_SPELLS.LAST_STAND) and API.IsSpellUsable(PROT_SPELLS.LAST_STAND) then
            return {
                type = "spell",
                id = PROT_SPELLS.LAST_STAND,
                target = player
            }
        end
        
        -- Shield Wall at critical health
        if healthPercent < settings.protSettings.shieldWallThreshold and 
           API.IsSpellKnown(PROT_SPELLS.SHIELD_WALL) and API.IsSpellUsable(PROT_SPELLS.SHIELD_WALL) then
            return {
                type = "spell",
                id = PROT_SPELLS.SHIELD_WALL,
                target = player
            }
        end
    end
    
    -- Offensive cooldowns
    if inCombat then
        -- Avatar
        if settings.protSettings.useAvatar and 
           API.IsSpellKnown(PROT_SPELLS.AVATAR) and API.IsSpellUsable(PROT_SPELLS.AVATAR) then
            return {
                type = "spell",
                id = PROT_SPELLS.AVATAR,
                target = player
            }
        end
        
        -- Demoralizing Shout
        if API.IsSpellKnown(PROT_SPELLS.DEMORALIZING_SHOUT) and API.IsSpellUsable(PROT_SPELLS.DEMORALIZING_SHOUT) and
           not API.UnitHasDebuff(target, DEBUFFS.DEMORALIZING_SHOUT) then
            return {
                type = "spell",
                id = PROT_SPELLS.DEMORALIZING_SHOUT,
                target = target
            }
        end
        
        -- Shockwave for AoE stun
        if settings.protSettings.useShockwave and enemies >= settings.protSettings.shockwaveThreshold and
           API.IsSpellKnown(PROT_SPELLS.SHOCKWAVE) and API.IsSpellUsable(PROT_SPELLS.SHOCKWAVE) then
            return {
                type = "spell",
                id = PROT_SPELLS.SHOCKWAVE,
                target = target
            }
        end
    end
    
    -- Core rotation
    if API.IsSpellKnown(PROT_SPELLS.SHIELD_SLAM) and API.IsSpellUsable(PROT_SPELLS.SHIELD_SLAM) then
        -- Shield Slam on cooldown
        return {
            type = "spell",
            id = PROT_SPELLS.SHIELD_SLAM,
            target = target
        }
    elseif enemies >= 2 and API.IsSpellKnown(PROT_SPELLS.THUNDER_CLAP) and API.IsSpellUsable(PROT_SPELLS.THUNDER_CLAP) then
        -- Thunder Clap for AoE threat and slow
        return {
            type = "spell",
            id = PROT_SPELLS.THUNDER_CLAP,
            target = target
        }
    elseif API.IsSpellKnown(PROT_SPELLS.REVENGE) and API.IsSpellUsable(PROT_SPELLS.REVENGE) and rage >= 20 then
        -- Revenge for damage and threat
        return {
            type = "spell",
            id = PROT_SPELLS.REVENGE,
            target = target
        }
    elseif inExecutePhase and API.IsSpellKnown(PROT_SPELLS.EXECUTE_PROT) and API.IsSpellUsable(PROT_SPELLS.EXECUTE_PROT) then
        -- Execute during execute phase
        return {
            type = "spell",
            id = PROT_SPELLS.EXECUTE_PROT,
            target = target
        }
    elseif API.IsSpellKnown(PROT_SPELLS.DEVASTATE) and API.IsSpellUsable(PROT_SPELLS.DEVASTATE) then
        -- Devastate as filler
        return {
            type = "spell",
            id = PROT_SPELLS.DEVASTATE,
            target = target
        }
    end
    
    return nil
}

-- Should execute rotation
function WarriorModule:ShouldExecuteRotation()
    if not isEnabled then
        return false
    end
    
    -- Check if player matches class
    local playerInfo = API.GetPlayerInfo()
    if playerInfo.class ~= "WARRIOR" then
        return false
    end
    
    return true
}

-- Register for export
WR.Warrior = WarriorModule

return WarriorModule