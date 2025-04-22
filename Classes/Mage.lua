------------------------------------------
-- WindrunnerRotations - Mage Class Module
-- Author: VortexQ8
-- The War Within Season 2
------------------------------------------

local addonName, WR = ...
local MageModule = {}
WR.Mage = MageModule

-- Dependencies
local API = WR.API
local ConfigRegistry = WR.ConfigRegistry
local RotationManager = WR.RotationManager
local ErrorHandler = WR.ErrorHandler
local CombatAnalysis = WR.CombatAnalysis
local AntiDetectionSystem = WR.AntiDetectionSystem
local PvPManager = WR.PvPManager

-- Mage constants
local CLASS_ID = 8 -- Mage class ID
local SPEC_ARCANE = 62
local SPEC_FIRE = 63
local SPEC_FROST = 64

-- Current player data
local playerSpec = 0
local isEnabled = true
local inCombat = false

-- Spell IDs for Arcane Mage (The War Within, Season 2)
local ARCANE_SPELLS = {
    -- Core abilities
    ARCANE_BLAST = 30451,
    ARCANE_MISSILES = 5143,
    ARCANE_BARRAGE = 44425,
    ARCANE_EXPLOSION = 1449,
    TOUCH_OF_THE_MAGI = 321507,
    ARCANE_ORB = 153626,
    RADIANT_SPARK = 376103,
    ARCANE_HARMONY = 384452,
    
    -- Defensive & utility
    ICE_BLOCK = 45438,
    MIRROR_IMAGE = 55342,
    ALTER_TIME = 342245,
    PRISMATIC_BARRIER = 235450,
    INVISIBILITY = 66,
    MASS_INVISIBILITY = 414660,
    FROST_NOVA = 122,
    SLOW = 31589,
    BLINK = 1953,
    SHIMMER = 212653,
    TIME_WARP = 80353,
    
    -- Talents
    ARCANE_FAMILIAR = 205022,
    PRESENCE_OF_MIND = 205025,
    EVOCATION = 12051,
    ARCANE_POWER = 12042,
    SUPERNOVA = 157980,
    DISPLACEMENT = 195676,
    NETHER_TEMPEST = 114923,
    ENLIGHTENED = 321387,
    
    -- Misc
    ARCANE_INTELLECT = 1459,
    CONJURE_REFRESHMENT = 190336,
    POLYMORPH = 118,
    REMOVE_CURSE = 475
}

-- Spell IDs for Fire Mage
local FIRE_SPELLS = {
    -- Core abilities
    FIREBALL = 133,
    PYROBLAST = 11366,
    FIRE_BLAST = 108853,
    FLAMESTRIKE = 2120,
    PHOENIX_FLAMES = 257541,
    DRAGONS_BREATH = 31661,
    LIVING_BOMB = 44457,
    COMBUSTION = 190319,
    
    -- Defensive & utility
    ICE_BLOCK = 45438,
    MIRROR_IMAGE = 55342,
    BLAZING_BARRIER = 235313,
    INVISIBILITY = 66,
    MASS_INVISIBILITY = 414660,
    FROST_NOVA = 122,
    BLINK = 1953,
    SHIMMER = 212653,
    TIME_WARP = 80353,
    
    -- Talents
    SCORCH = 2948,
    METEOR = 153561,
    RUNE_OF_POWER = 116011,
    HOT_STREAK = 195283,
    HEATING_UP = 48107,
    FIREBLOOD = 265221,
    BLAST_WAVE = 157981,
    KINDLING = 155148,
    CONFLAGRATION = 205023,
    
    -- Misc
    ARCANE_INTELLECT = 1459,
    CONJURE_REFRESHMENT = 190336,
    POLYMORPH = 118,
    REMOVE_CURSE = 475
}

-- Spell IDs for Frost Mage
local FROST_SPELLS = {
    -- Core abilities
    FROSTBOLT = 116,
    ICE_LANCE = 30455,
    FLURRY = 44614,
    BLIZZARD = 190356,
    FROZEN_ORB = 84714,
    CONE_OF_COLD = 120,
    COMET_STORM = 153595,
    EBONBOLT = 257537,
    
    -- Defensive & utility
    ICE_BLOCK = 45438,
    MIRROR_IMAGE = 55342,
    ICE_BARRIER = 11426,
    INVISIBILITY = 66,
    MASS_INVISIBILITY = 414660,
    FROST_NOVA = 122,
    BLINK = 1953,
    SHIMMER = 212653,
    TIME_WARP = 80353,
    
    -- Talents
    ICY_VEINS = 12472,
    RAY_OF_FROST = 205021,
    GLACIAL_SPIKE = 199786,
    FOCUS_MAGIC = 321358,
    COLD_SNAP = 235219,
    BRAIN_FREEZE = 190447,
    FINGERS_OF_FROST = 44544,
    SUMMON_WATER_ELEMENTAL = 31687,
    
    -- Misc
    ARCANE_INTELLECT = 1459,
    CONJURE_REFRESHMENT = 190336,
    POLYMORPH = 118,
    REMOVE_CURSE = 475
}

-- Important buffs to track
local BUFFS = {
    ARCANE_POWER = 12042,
    ARCANE_FAMILIAR = 210126,
    PRESENCE_OF_MIND = 205025,
    ARCANE_HARMONY = 384455,
    EVOCATION = 12051,
    COMBUSTION = 190319,
    HOT_STREAK = 48108,
    HEATING_UP = 48107,
    RUNE_OF_POWER = 116014,
    ICY_VEINS = 12472,
    BRAIN_FREEZE = 190446,
    FINGERS_OF_FROST = 44544,
    ICE_BARRIER = 11426,
    BLAZING_BARRIER = 235313,
    PRISMATIC_BARRIER = 235450,
    ARCANE_INTELLECT = 1459,
    MIRROR_IMAGE = 55342,
    TEMPORAL_DISPLACEMENT = 80354,
    TIME_WARP = 80353,
    CLEARCASTING = 263725
}

-- Important debuffs to track
local DEBUFFS = {
    TOUCH_OF_THE_MAGI = 210824,
    NETHER_TEMPEST = 114923,
    RADIANT_SPARK = 376103,
    IGNITE = 12654,
    LIVING_BOMB = 217694,
    FROST_NOVA = 122,
    WINTERS_CHILL = 228358,
    POLYMORPH = 118
}

-- Initialize the Mage module
function MageModule:Initialize()
    -- Register settings
    self:RegisterSettings()
    
    -- Register events
    self:RegisterEvents()
    
    -- Register rotations
    self:RegisterRotations()
    
    API.PrintDebug("Mage module initialized")
    return true
end

-- Register settings
function MageModule:RegisterSettings()
    ConfigRegistry:RegisterSettings("Mage", {
        generalSettings = {
            enabled = {
                displayName = "Enable Mage Module",
                description = "Enable the Mage module for all specs",
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
            intelligenceCheck = {
                displayName = "Arcane Intellect Check",
                description = "Check for Arcane Intellect buff",
                type = "toggle",
                default = true
            },
            useTimeWarp = {
                displayName = "Use Time Warp",
                description = "Automatically use Time Warp in combat",
                type = "toggle",
                default = false
            }
        },
        arcaneSettings = {
            conserveManaThreshold = {
                displayName = "Conserve Mana Threshold",
                description = "Mana percentage to start conserving",
                type = "slider",
                min = 10,
                max = 50,
                step = 5,
                default = 35
            },
            arcanePowerWithTotM = {
                displayName = "Arcane Power with Touch of the Magi",
                description = "Only use Arcane Power with Touch of the Magi",
                type = "toggle",
                default = true
            },
            aoeThreshold = {
                displayName = "AoE Threshold",
                description = "Number of targets to switch to AoE rotation",
                type = "slider",
                min = 2,
                max = 6,
                step = 1,
                default = 3
            },
            useArcaneFamiliar = {
                displayName = "Use Arcane Familiar",
                description = "Keep Arcane Familiar active",
                type = "toggle",
                default = true
            },
            usePresenceOfMind = {
                displayName = "Use Presence of Mind",
                description = "Use Presence of Mind in rotation",
                type = "toggle",
                default = true
            },
            evocationHealthThreshold = {
                displayName = "Evocation Health Threshold",
                description = "Health percentage to use Evocation for Chronomatic Aegis healing",
                type = "slider",
                min = 10,
                max = 60,
                step = 5,
                default = 30
            }
        },
        fireSettings = {
            combustionThreshold = {
                displayName = "Combustion Usage",
                description = "How to use Combustion",
                type = "dropdown",
                options = {"With Cooldowns", "On Cooldown", "Manual Only"},
                default = "With Cooldowns"
            },
            hotStreakDelayMS = {
                displayName = "Hot Streak Delay",
                description = "Milliseconds to delay Hot Streak usage for Hardcasting",
                type = "slider",
                min = 0,
                max = 400,
                step = 20,
                default = 100
            },
            aoeThreshold = {
                displayName = "AoE Threshold",
                description = "Number of targets to switch to AoE rotation",
                type = "slider",
                min = 2,
                max = 6,
                step = 1,
                default = 3
            },
            useBlazingBarrier = {
                displayName = "Use Blazing Barrier",
                description = "Keep Blazing Barrier active",
                type = "toggle",
                default = true
            },
            blazingBarrierThreshold = {
                displayName = "Blazing Barrier Health Threshold",
                description = "Health percentage to refresh Blazing Barrier",
                type = "slider",
                min = 70,
                max = 100,
                step = 5,
                default = 90
            },
            useMeteor = {
                displayName = "Use Meteor",
                description = "Use Meteor in combat",
                type = "toggle",
                default = true
            }
        },
        frostSettings = {
            iceBlockThreshold = {
                displayName = "Ice Block Health Threshold",
                description = "Health percentage to use Ice Block",
                type = "slider",
                min = 10,
                max = 30,
                step = 5,
                default = 15
            },
            iceBarrierThreshold = {
                displayName = "Ice Barrier Health Threshold",
                description = "Health percentage to refresh Ice Barrier",
                type = "slider",
                min = 80,
                max = 100,
                step = 5,
                default = 95
            },
            aoeThreshold = {
                displayName = "AoE Threshold",
                description = "Number of targets to switch to AoE rotation",
                type = "slider",
                min = 2,
                max = 6,
                step = 1,
                default = 3
            },
            useIcyVeins = {
                displayName = "Use Icy Veins",
                description = "Use Icy Veins in combat",
                type = "toggle",
                default = true
            },
            useCometStorm = {
                displayName = "Use Comet Storm",
                description = "Use Comet Storm in combat",
                type = "toggle",
                default = true
            },
            useGlacialSpike = {
                displayName = "Use Glacial Spike",
                description = "Use Glacial Spike in combat",
                type = "toggle",
                default = true
            },
            glacialSpikeWithBrainFreeze = {
                displayName = "Glacial Spike with Brain Freeze",
                description = "Only use Glacial Spike with Brain Freeze",
                type = "toggle",
                default = true
            }
        }
    })
    
    -- Add callback for settings changes
    ConfigRegistry:RegisterCallback("Mage", function(settings)
        self:ApplySettings(settings)
    end)
}

-- Apply settings
function MageModule:ApplySettings(settings)
    -- Apply general settings
    isEnabled = settings.generalSettings.enabled
}

-- Register events
function MageModule:RegisterEvents()
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
function MageModule:OnSpecializationChanged()
    -- Get current spec ID
    playerSpec = API.GetActiveSpecID()
    
    API.PrintDebug("Mage specialization changed: " .. playerSpec)
    
    -- Ensure correct rotation is registered
    if playerSpec == SPEC_ARCANE then
        self:RegisterArcaneRotation()
    elseif playerSpec == SPEC_FIRE then
        self:RegisterFireRotation()
    elseif playerSpec == SPEC_FROST then
        self:RegisterFrostRotation()
    end
}

-- Register rotations
function MageModule:RegisterRotations()
    -- Register spec-specific rotations
    self:RegisterArcaneRotation()
    self:RegisterFireRotation()
    self:RegisterFrostRotation()
}

-- Register Arcane rotation
function MageModule:RegisterArcaneRotation()
    RotationManager:RegisterRotation("MageArcane", {
        id = "MageArcane",
        name = "Mage - Arcane",
        class = "MAGE",
        spec = SPEC_ARCANE,
        level = 10,
        description = "Arcane Mage rotation for The War Within Season 2",
        author = "WindrunnerRotations",
        version = "1.0.0",
        rotation = function()
            return self:ArcaneRotation()
        end
    })
}

-- Register Fire rotation
function MageModule:RegisterFireRotation()
    RotationManager:RegisterRotation("MageFire", {
        id = "MageFire",
        name = "Mage - Fire",
        class = "MAGE",
        spec = SPEC_FIRE,
        level = 10,
        description = "Fire Mage rotation for The War Within Season 2",
        author = "WindrunnerRotations",
        version = "1.0.0",
        rotation = function()
            return self:FireRotation()
        end
    })
}

-- Register Frost rotation
function MageModule:RegisterFrostRotation()
    RotationManager:RegisterRotation("MageFrost", {
        id = "MageFrost",
        name = "Mage - Frost",
        class = "MAGE",
        spec = SPEC_FROST,
        level = 10,
        description = "Frost Mage rotation for The War Within Season 2",
        author = "WindrunnerRotations",
        version = "1.0.0",
        rotation = function()
            return self:FrostRotation()
        end
    })
}

-- Arcane rotation
function MageModule:ArcaneRotation()
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
    local settings = ConfigRegistry:GetSettings("Mage")
    
    -- Common Combat Variables
    local health, maxHealth, healthPercent = API.GetUnitHealth(player)
    local targetHealth, targetMaxHealth, targetHealthPercent = API.GetUnitHealth(target)
    local mana, maxMana, manaPercent = API.GetUnitPower(player, Enum.PowerType.Mana)
    local enemies = API.GetEnemyCount(8)
    local aoeEnabled = settings.arcaneSettings.aoeThreshold <= enemies
    local conserveMana = manaPercent <= settings.arcaneSettings.conserveManaThreshold
    local hasArcanePower = API.UnitHasBuff(player, BUFFS.ARCANE_POWER)
    local hasTouchOfTheMagi = API.UnitHasDebuff(target, DEBUFFS.TOUCH_OF_THE_MAGI)
    local hasClearcasting = API.UnitHasBuff(player, BUFFS.CLEARCASTING)
    
    -- Arcane Intellect
    if settings.generalSettings.intelligenceCheck and not API.UnitHasBuff(player, BUFFS.ARCANE_INTELLECT) then
        return {
            type = "spell",
            id = ARCANE_SPELLS.ARCANE_INTELLECT,
            target = player
        }
    end
    
    -- Arcane Familiar
    if settings.arcaneSettings.useArcaneFamiliar and 
       API.IsSpellKnown(ARCANE_SPELLS.ARCANE_FAMILIAR) and 
       API.IsSpellUsable(ARCANE_SPELLS.ARCANE_FAMILIAR) and
       not API.UnitHasBuff(player, BUFFS.ARCANE_FAMILIAR) then
        return {
            type = "spell",
            id = ARCANE_SPELLS.ARCANE_FAMILIAR,
            target = player
        }
    end
    
    -- Defensive abilities
    if settings.generalSettings.useDefensives then
        -- Prismatic Barrier
        if API.IsSpellKnown(ARCANE_SPELLS.PRISMATIC_BARRIER) and 
           API.IsSpellUsable(ARCANE_SPELLS.PRISMATIC_BARRIER) and
           not API.UnitHasBuff(player, BUFFS.PRISMATIC_BARRIER) and
           healthPercent < 95 then
            return {
                type = "spell",
                id = ARCANE_SPELLS.PRISMATIC_BARRIER,
                target = player
            }
        end
        
        -- Ice Block at critical health
        if healthPercent < 15 and 
           API.IsSpellKnown(ARCANE_SPELLS.ICE_BLOCK) and 
           API.IsSpellUsable(ARCANE_SPELLS.ICE_BLOCK) then
            return {
                type = "spell",
                id = ARCANE_SPELLS.ICE_BLOCK,
                target = player
            }
        end
        
        -- Evocation at low health with Chronomatic Aegis talent
        if healthPercent < settings.arcaneSettings.evocationHealthThreshold and
           API.IsSpellKnown(ARCANE_SPELLS.EVOCATION) and 
           API.IsSpellUsable(ARCANE_SPELLS.EVOCATION) then
            return {
                type = "spell",
                id = ARCANE_SPELLS.EVOCATION,
                target = player
            }
        end
    end
    
    -- Offensive cooldowns
    if inCombat then
        -- Touch of the Magi on cooldown if talented
        if API.IsSpellKnown(ARCANE_SPELLS.TOUCH_OF_THE_MAGI) and 
           API.IsSpellUsable(ARCANE_SPELLS.TOUCH_OF_THE_MAGI) then
            return {
                type = "spell",
                id = ARCANE_SPELLS.TOUCH_OF_THE_MAGI,
                target = target
            }
        end
        
        -- Arcane Power with Touch of the Magi if setting enabled
        if API.IsSpellKnown(ARCANE_SPELLS.ARCANE_POWER) and 
           API.IsSpellUsable(ARCANE_SPELLS.ARCANE_POWER) then
            if not settings.arcaneSettings.arcanePowerWithTotM or hasTouchOfTheMagi then
                return {
                    type = "spell",
                    id = ARCANE_SPELLS.ARCANE_POWER,
                    target = player
                }
            end
        end
        
        -- Presence of Mind on cooldown if setting enabled
        if settings.arcaneSettings.usePresenceOfMind and
           API.IsSpellKnown(ARCANE_SPELLS.PRESENCE_OF_MIND) and 
           API.IsSpellUsable(ARCANE_SPELLS.PRESENCE_OF_MIND) then
            return {
                type = "spell",
                id = ARCANE_SPELLS.PRESENCE_OF_MIND,
                target = player
            }
        end
        
        -- Radiant Spark if talented
        if API.IsSpellKnown(ARCANE_SPELLS.RADIANT_SPARK) and 
           API.IsSpellUsable(ARCANE_SPELLS.RADIANT_SPARK) and
           not API.UnitHasDebuff(target, DEBUFFS.RADIANT_SPARK) then
            return {
                type = "spell",
                id = ARCANE_SPELLS.RADIANT_SPARK,
                target = target
            }
        end
    end
    
    -- AoE rotation
    if aoeEnabled and enemies >= 3 then
        -- Arcane Orb if talented
        if API.IsSpellKnown(ARCANE_SPELLS.ARCANE_ORB) and 
           API.IsSpellUsable(ARCANE_SPELLS.ARCANE_ORB) then
            return {
                type = "spell",
                id = ARCANE_SPELLS.ARCANE_ORB,
                target = target
            }
        end
        
        -- Arcane Explosion as main AoE
        if API.IsSpellKnown(ARCANE_SPELLS.ARCANE_EXPLOSION) and 
           API.IsSpellUsable(ARCANE_SPELLS.ARCANE_EXPLOSION) then
            return {
                type = "spell",
                id = ARCANE_SPELLS.ARCANE_EXPLOSION,
                target = player
            }
        end
    end
    
    -- Core rotation
    -- Use Nether Tempest if talented and not already applied
    if API.IsSpellKnown(ARCANE_SPELLS.NETHER_TEMPEST) and 
       API.IsSpellUsable(ARCANE_SPELLS.NETHER_TEMPEST) and
       not API.UnitHasDebuff(target, DEBUFFS.NETHER_TEMPEST) then
        return {
            type = "spell",
            id = ARCANE_SPELLS.NETHER_TEMPEST,
            target = target
        }
    end
    
    -- Use Arcane Missiles with Clearcasting proc
    if hasClearcasting and
       API.IsSpellKnown(ARCANE_SPELLS.ARCANE_MISSILES) and 
       API.IsSpellUsable(ARCANE_SPELLS.ARCANE_MISSILES) then
        return {
            type = "spell",
            id = ARCANE_SPELLS.ARCANE_MISSILES,
            target = target
        }
    end
    
    -- Arcane Blast in burn phase (with Arcane Power or high mana)
    if (hasArcanePower or manaPercent > 50) and
       API.IsSpellKnown(ARCANE_SPELLS.ARCANE_BLAST) and 
       API.IsSpellUsable(ARCANE_SPELLS.ARCANE_BLAST) then
        return {
            type = "spell",
            id = ARCANE_SPELLS.ARCANE_BLAST,
            target = target
        }
    end
    
    -- Arcane Barrage to conserve mana or at 4 Arcane Charges
    if conserveMana and
       API.IsSpellKnown(ARCANE_SPELLS.ARCANE_BARRAGE) and 
       API.IsSpellUsable(ARCANE_SPELLS.ARCANE_BARRAGE) then
        return {
            type = "spell",
            id = ARCANE_SPELLS.ARCANE_BARRAGE,
            target = target
        }
    end
    
    -- Arcane Blast as filler
    if API.IsSpellKnown(ARCANE_SPELLS.ARCANE_BLAST) and 
       API.IsSpellUsable(ARCANE_SPELLS.ARCANE_BLAST) then
        return {
            type = "spell",
            id = ARCANE_SPELLS.ARCANE_BLAST,
            target = target
        }
    end
    
    return nil
}

-- Fire rotation
function MageModule:FireRotation()
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
    local settings = ConfigRegistry:GetSettings("Mage")
    
    -- Common Combat Variables
    local health, maxHealth, healthPercent = API.GetUnitHealth(player)
    local targetHealth, targetMaxHealth, targetHealthPercent = API.GetUnitHealth(target)
    local mana, maxMana, manaPercent = API.GetUnitPower(player, Enum.PowerType.Mana)
    local enemies = API.GetEnemyCount(8)
    local aoeEnabled = settings.fireSettings.aoeThreshold <= enemies
    local hasCombustion = API.UnitHasBuff(player, BUFFS.COMBUSTION)
    local hasHotStreak = API.UnitHasBuff(player, BUFFS.HOT_STREAK)
    local hasHeatingUp = API.UnitHasBuff(player, BUFFS.HEATING_UP)
    
    -- Arcane Intellect
    if settings.generalSettings.intelligenceCheck and not API.UnitHasBuff(player, BUFFS.ARCANE_INTELLECT) then
        return {
            type = "spell",
            id = FIRE_SPELLS.ARCANE_INTELLECT,
            target = player
        }
    end
    
    -- Blazing Barrier
    if settings.fireSettings.useBlazingBarrier and 
       healthPercent < settings.fireSettings.blazingBarrierThreshold and
       API.IsSpellKnown(FIRE_SPELLS.BLAZING_BARRIER) and 
       API.IsSpellUsable(FIRE_SPELLS.BLAZING_BARRIER) and
       not API.UnitHasBuff(player, BUFFS.BLAZING_BARRIER) then
        return {
            type = "spell",
            id = FIRE_SPELLS.BLAZING_BARRIER,
            target = player
        }
    end
    
    -- Defensive abilities
    if settings.generalSettings.useDefensives then
        -- Ice Block at critical health
        if healthPercent < 15 and 
           API.IsSpellKnown(FIRE_SPELLS.ICE_BLOCK) and 
           API.IsSpellUsable(FIRE_SPELLS.ICE_BLOCK) then
            return {
                type = "spell",
                id = FIRE_SPELLS.ICE_BLOCK,
                target = player
            }
        end
        
        -- Dragons Breath for defense/crowd control
        if healthPercent < 50 and 
           API.IsSpellKnown(FIRE_SPELLS.DRAGONS_BREATH) and 
           API.IsSpellUsable(FIRE_SPELLS.DRAGONS_BREATH) and
           enemies >= 1 then
            return {
                type = "spell",
                id = FIRE_SPELLS.DRAGONS_BREATH,
                target = player
            }
        end
    end
    
    -- Offensive cooldowns
    if inCombat then
        -- Combustion with Hot Streak ideally
        if settings.fireSettings.combustionThreshold ~= "Manual Only" and
           API.IsSpellKnown(FIRE_SPELLS.COMBUSTION) and 
           API.IsSpellUsable(FIRE_SPELLS.COMBUSTION) and
           (hasHotStreak or settings.fireSettings.combustionThreshold == "On Cooldown") then
            return {
                type = "spell",
                id = FIRE_SPELLS.COMBUSTION,
                target = player
            }
        end
        
        -- Meteor if talented
        if settings.fireSettings.useMeteor and
           API.IsSpellKnown(FIRE_SPELLS.METEOR) and 
           API.IsSpellUsable(FIRE_SPELLS.METEOR) then
            return {
                type = "spell",
                id = FIRE_SPELLS.METEOR,
                target = target
            }
        end
        
        -- Rune of Power if talented
        if API.IsSpellKnown(FIRE_SPELLS.RUNE_OF_POWER) and 
           API.IsSpellUsable(FIRE_SPELLS.RUNE_OF_POWER) and
           not API.UnitHasBuff(player, BUFFS.RUNE_OF_POWER) then
            return {
                type = "spell",
                id = FIRE_SPELLS.RUNE_OF_POWER,
                target = player
            }
        end
    end
    
    -- AoE rotation
    if aoeEnabled and enemies >= 3 then
        -- Flamestrike with Hot Streak
        if hasHotStreak and
           API.IsSpellKnown(FIRE_SPELLS.FLAMESTRIKE) and 
           API.IsSpellUsable(FIRE_SPELLS.FLAMESTRIKE) then
            return {
                type = "spell",
                id = FIRE_SPELLS.FLAMESTRIKE,
                target = target
            }
        end
        
        -- Living Bomb if talented and not already applied
        if API.IsSpellKnown(FIRE_SPELLS.LIVING_BOMB) and 
           API.IsSpellUsable(FIRE_SPELLS.LIVING_BOMB) and
           not API.UnitHasDebuff(target, DEBUFFS.LIVING_BOMB) then
            return {
                type = "spell",
                id = FIRE_SPELLS.LIVING_BOMB,
                target = target
            }
        end
    end
    
    -- Core rotation
    -- Pyroblast with Hot Streak
    if hasHotStreak and
       API.IsSpellKnown(FIRE_SPELLS.PYROBLAST) and 
       API.IsSpellUsable(FIRE_SPELLS.PYROBLAST) then
        return {
            type = "spell",
            id = FIRE_SPELLS.PYROBLAST,
            target = target
        }
    end
    
    -- Fire Blast with Heating Up (to generate Hot Streak)
    if hasHeatingUp and not hasHotStreak and
       API.IsSpellKnown(FIRE_SPELLS.FIRE_BLAST) and 
       API.IsSpellUsable(FIRE_SPELLS.FIRE_BLAST) then
        return {
            type = "spell",
            id = FIRE_SPELLS.FIRE_BLAST,
            target = target
        }
    end
    
    -- Phoenix Flames to generate Heating Up
    if not hasHeatingUp and not hasHotStreak and
       API.IsSpellKnown(FIRE_SPELLS.PHOENIX_FLAMES) and 
       API.IsSpellUsable(FIRE_SPELLS.PHOENIX_FLAMES) then
        return {
            type = "spell",
            id = FIRE_SPELLS.PHOENIX_FLAMES,
            target = target
        }
    end
    
    -- Scorch while moving or on low health targets
    if targetHealthPercent < 30 or IsPlayerMoving() and
       API.IsSpellKnown(FIRE_SPELLS.SCORCH) and 
       API.IsSpellUsable(FIRE_SPELLS.SCORCH) then
        return {
            type = "spell",
            id = FIRE_SPELLS.SCORCH,
            target = target
        }
    end
    
    -- Fireball as filler
    if API.IsSpellKnown(FIRE_SPELLS.FIREBALL) and 
       API.IsSpellUsable(FIRE_SPELLS.FIREBALL) then
        return {
            type = "spell",
            id = FIRE_SPELLS.FIREBALL,
            target = target
        }
    end
    
    return nil
}

-- Frost rotation
function MageModule:FrostRotation()
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
    local settings = ConfigRegistry:GetSettings("Mage")
    
    -- Common Combat Variables
    local health, maxHealth, healthPercent = API.GetUnitHealth(player)
    local targetHealth, targetMaxHealth, targetHealthPercent = API.GetUnitHealth(target)
    local mana, maxMana, manaPercent = API.GetUnitPower(player, Enum.PowerType.Mana)
    local enemies = API.GetEnemyCount(8)
    local aoeEnabled = settings.frostSettings.aoeThreshold <= enemies
    local hasBrainFreeze = API.UnitHasBuff(player, BUFFS.BRAIN_FREEZE)
    local hasFingersOfFrost = API.UnitHasBuff(player, BUFFS.FINGERS_OF_FROST)
    local hasWintersChill = API.UnitHasDebuff(target, DEBUFFS.WINTERS_CHILL)
    local hasIcyVeins = API.UnitHasBuff(player, BUFFS.ICY_VEINS)
    
    -- Arcane Intellect
    if settings.generalSettings.intelligenceCheck and not API.UnitHasBuff(player, BUFFS.ARCANE_INTELLECT) then
        return {
            type = "spell",
            id = FROST_SPELLS.ARCANE_INTELLECT,
            target = player
        }
    end
    
    -- Ice Barrier
    if healthPercent < settings.frostSettings.iceBarrierThreshold and
       API.IsSpellKnown(FROST_SPELLS.ICE_BARRIER) and 
       API.IsSpellUsable(FROST_SPELLS.ICE_BARRIER) and
       not API.UnitHasBuff(player, BUFFS.ICE_BARRIER) then
        return {
            type = "spell",
            id = FROST_SPELLS.ICE_BARRIER,
            target = player
        }
    end
    
    -- Defensive abilities
    if settings.generalSettings.useDefensives then
        -- Ice Block at critical health
        if healthPercent < settings.frostSettings.iceBlockThreshold and 
           API.IsSpellKnown(FROST_SPELLS.ICE_BLOCK) and 
           API.IsSpellUsable(FROST_SPELLS.ICE_BLOCK) then
            return {
                type = "spell",
                id = FROST_SPELLS.ICE_BLOCK,
                target = player
            }
        end
        
        -- Frost Nova for defense/crowd control
        if healthPercent < 50 and 
           API.IsSpellKnown(FROST_SPELLS.FROST_NOVA) and 
           API.IsSpellUsable(FROST_SPELLS.FROST_NOVA) and
           enemies >= 1 then
            return {
                type = "spell",
                id = FROST_SPELLS.FROST_NOVA,
                target = player
            }
        end
    end
    
    -- Offensive cooldowns
    if inCombat then
        -- Icy Veins
        if settings.frostSettings.useIcyVeins and
           API.IsSpellKnown(FROST_SPELLS.ICY_VEINS) and 
           API.IsSpellUsable(FROST_SPELLS.ICY_VEINS) then
            return {
                type = "spell",
                id = FROST_SPELLS.ICY_VEINS,
                target = player
            }
        end
        
        -- Summon Water Elemental if missing
        if API.IsSpellKnown(FROST_SPELLS.SUMMON_WATER_ELEMENTAL) and 
           API.IsSpellUsable(FROST_SPELLS.SUMMON_WATER_ELEMENTAL) then
            return {
                type = "spell",
                id = FROST_SPELLS.SUMMON_WATER_ELEMENTAL,
                target = player
            }
        end
        
        -- Time Warp on boss fights if enabled
        if settings.generalSettings.useTimeWarp and
           API.IsSpellKnown(FROST_SPELLS.TIME_WARP) and 
           API.IsSpellUsable(FROST_SPELLS.TIME_WARP) and
           not API.UnitHasBuff(player, BUFFS.TEMPORAL_DISPLACEMENT) and
           not API.UnitHasBuff(player, BUFFS.TIME_WARP) then
            return {
                type = "spell",
                id = FROST_SPELLS.TIME_WARP,
                target = player
            }
        end
    end
    
    -- AoE rotation
    if aoeEnabled and enemies >= 3 then
        -- Frozen Orb
        if API.IsSpellKnown(FROST_SPELLS.FROZEN_ORB) and 
           API.IsSpellUsable(FROST_SPELLS.FROZEN_ORB) then
            return {
                type = "spell",
                id = FROST_SPELLS.FROZEN_ORB,
                target = target
            }
        end
        
        -- Comet Storm if talented
        if settings.frostSettings.useCometStorm and
           API.IsSpellKnown(FROST_SPELLS.COMET_STORM) and 
           API.IsSpellUsable(FROST_SPELLS.COMET_STORM) then
            return {
                type = "spell",
                id = FROST_SPELLS.COMET_STORM,
                target = target
            }
        end
        
        -- Blizzard
        if API.IsSpellKnown(FROST_SPELLS.BLIZZARD) and 
           API.IsSpellUsable(FROST_SPELLS.BLIZZARD) then
            return {
                type = "spell",
                id = FROST_SPELLS.BLIZZARD,
                target = target
            }
        end
    end
    
    -- Core rotation
    -- Flurry with Brain Freeze proc
    if hasBrainFreeze and
       API.IsSpellKnown(FROST_SPELLS.FLURRY) and 
       API.IsSpellUsable(FROST_SPELLS.FLURRY) then
        return {
            type = "spell",
            id = FROST_SPELLS.FLURRY,
            target = target
        }
    end
    
    -- Ice Lance with Fingers of Frost proc or Winter's Chill debuff
    if (hasFingersOfFrost or hasWintersChill) and
       API.IsSpellKnown(FROST_SPELLS.ICE_LANCE) and 
       API.IsSpellUsable(FROST_SPELLS.ICE_LANCE) then
        return {
            type = "spell",
            id = FROST_SPELLS.ICE_LANCE,
            target = target
        }
    end
    
    -- Glacial Spike if talented
    if settings.frostSettings.useGlacialSpike and
       API.IsSpellKnown(FROST_SPELLS.GLACIAL_SPIKE) and 
       API.IsSpellUsable(FROST_SPELLS.GLACIAL_SPIKE) then
        -- Only cast with Brain Freeze if the setting is enabled
        if not settings.frostSettings.glacialSpikeWithBrainFreeze or hasBrainFreeze then
            return {
                type = "spell",
                id = FROST_SPELLS.GLACIAL_SPIKE,
                target = target
            }
        end
    end
    
    -- Ebonbolt to generate Brain Freeze
    if API.IsSpellKnown(FROST_SPELLS.EBONBOLT) and 
       API.IsSpellUsable(FROST_SPELLS.EBONBOLT) then
        return {
            type = "spell",
            id = FROST_SPELLS.EBONBOLT,
            target = target
        }
    end
    
    -- Ray of Frost if talented
    if API.IsSpellKnown(FROST_SPELLS.RAY_OF_FROST) and 
       API.IsSpellUsable(FROST_SPELLS.RAY_OF_FROST) then
        return {
            type = "spell",
            id = FROST_SPELLS.RAY_OF_FROST,
            target = target
        }
    end
    
    -- Frostbolt as filler
    if API.IsSpellKnown(FROST_SPELLS.FROSTBOLT) and 
       API.IsSpellUsable(FROST_SPELLS.FROSTBOLT) then
        return {
            type = "spell",
            id = FROST_SPELLS.FROSTBOLT,
            target = target
        }
    end
    
    return nil
}

-- Should execute rotation
function MageModule:ShouldExecuteRotation()
    if not isEnabled then
        return false
    end
    
    -- Check if player matches class
    local playerInfo = API.GetPlayerInfo()
    if playerInfo.class ~= "MAGE" then
        return false
    end
    
    return true
}

-- Register for export
WR.Mage = MageModule

return MageModule