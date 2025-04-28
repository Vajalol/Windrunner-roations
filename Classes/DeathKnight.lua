------------------------------------------
-- WindrunnerRotations - Death Knight Class Module
-- Author: VortexQ8
-- The War Within Season 2
------------------------------------------

local addonName, WR = ...
local DeathKnightModule = {}
WR.DeathKnight = DeathKnightModule

-- Dependencies
local API = WR.API
local ConfigRegistry = WR.ConfigRegistry
local RotationManager = WR.RotationManager
local ErrorHandler = WR.ErrorHandler
local CombatAnalysis = WR.CombatAnalysis
local AntiDetectionSystem = WR.AntiDetectionSystem
local PvPManager = WR.PvPManager

-- Death Knight constants
local CLASS_ID = 6 -- Death Knight class ID
local SPEC_BLOOD = 250
local SPEC_FROST = 251
local SPEC_UNHOLY = 252

-- Current player data
local playerSpec = 0
local isEnabled = true
local inCombat = false

-- Spell IDs for Blood Death Knight (The War Within, Season 2)
local BLOOD_SPELLS = {
    -- Core abilities
    HEART_STRIKE = 206930,
    DEATH_STRIKE = 49998,
    MARROWREND = 195182,
    BLOOD_BOIL = 50842,
    DEATH_AND_DECAY = 43265,
    DANCING_RUNE_WEAPON = 49028,
    VAMPIRIC_BLOOD = 55233,
    BLOOD_TAP = 221699,
    CONSUMPTION = 274156,
    
    -- Defensive & utility
    ANTI_MAGIC_SHELL = 48707,
    ICEBOUND_FORTITUDE = 48792,
    DEATH_GRIP = 49576,
    GOREFIEND'S_GRASP = 108199,
    WRAITH_WALK = 212552,
    RAISE_ALLY = 61999,
    CONTROL_UNDEAD = 111673,
    
    -- Talents (TWW Season 2)
    TOMBSTONE = 219809,
    RED_THIRST = 205723,
    BLOODDRINKER = 206931,
    BONESTORM = 194844,
    MARK_OF_BLOOD = 206940,
    BLOOD_TAP = 221699,
    HEMOSTASIS = 273946,
    RUNE_TAP = 194679,
    ABOMINATION_LIMB = 383269, -- New in TWW Season 2
    INSATIABLE_BLADE = 377637, -- Important in Season 2
    AFTERLIFE = 388902, -- New talent option
    SANGUINE_BOND = 374027, -- Important for TWW S2
    OSSUARY = 219786, -- Key talent for resource management
    COAGULOPATHY = 391477, -- New in Season 2
    BLOOD_FEAST = 391386, -- New in Season 2
    HEARTBLOOD = 377656, -- New talent in Tree
    
    -- Misc
    PATH_OF_FROST = 3714,
    DEATH_GATE = 50977,
    RAISE_DEAD = 46585,
    DARK_COMMAND = 56222
}

-- Spell IDs for Frost Death Knight (The War Within, Season 2)
local FROST_SPELLS = {
    -- Core abilities
    OBLITERATE = 49020,
    FROST_STRIKE = 49143,
    HOWLING_BLAST = 49184,
    REMORSELESS_WINTER = 196770,
    EMPOWER_RUNE_WEAPON = 47568,
    PILLAR_OF_FROST = 51271,
    FROSTWYRM'S_FURY = 279302,
    BREATH_OF_SINDRAGOSA = 152279,
    
    -- Defensive & utility
    ANTI_MAGIC_SHELL = 48707,
    ICEBOUND_FORTITUDE = 48792,
    DEATH_GRIP = 49576,
    WRAITH_WALK = 212552,
    RAISE_ALLY = 61999,
    CONTROL_UNDEAD = 111673,
    
    -- Talents (TWW Season 2)
    OBLITERATION = 281238,
    GLACIAL_ADVANCE = 194913,
    HORN_OF_WINTER = 57330,
    FROSTSCYTHE = 207230,
    ICECAP = 207126,
    MURDEROUS_EFFICIENCY = 207061,
    GATHERING_STORM = 194912,
    AVALANCHE = 207142,
    ABOMINATION_LIMB = 383269, -- New in TWW Season 2
    OBLITERATE_CLEAVE = 376905, -- New in TWW Season 2
    CHILL_STREAK = 305392, -- Important talent for Season 2
    IMPROVED_OBLITERATE = 377351, -- Key talent in Season 2
    FATAL_FIXATION = 405166, -- New ability in Season 2
    EVERFROST = 376938, -- New in Season 2
    AVALANCHE_TALENT = 207142, -- Updated for Season 2
    PIERCING_CHILL = 377351, -- Important for TWW
    CLEAVING_STRIKES = 316916, -- Enhanced in Season 2
    ABSOLUTE_ZERO = 377047, -- Key for Frost Mastery
    
    -- Misc
    PATH_OF_FROST = 3714,
    DEATH_GATE = 50977,
    RAISE_DEAD = 46585,
    DARK_COMMAND = 56222
}

-- Spell IDs for Unholy Death Knight (The War Within, Season 2)
local UNHOLY_SPELLS = {
    -- Core abilities
    SCOURGE_STRIKE = 55090,
    FESTERING_STRIKE = 85948,
    DEATH_COIL = 47541,
    APOCALYPSE = 275699,
    ARMY_OF_THE_DEAD = 42650,
    DARK_TRANSFORMATION = 63560,
    OUTBREAK = 77575,
    EPIDEMIC = 207317,
    
    -- Defensive & utility
    ANTI_MAGIC_SHELL = 48707,
    ICEBOUND_FORTITUDE = 48792,
    DEATH_GRIP = 49576,
    WRAITH_WALK = 212552,
    RAISE_ALLY = 61999,
    CONTROL_UNDEAD = 111673,
    
    -- Talents (TWW Season 2)
    UNHOLY_BLIGHT = 115989,
    DEFILE = 152280,
    SOUL_REAPER = 343294,
    SUMMON_GARGOYLE = 49206,
    EBON_FEVER = 207269,
    INFECTED_CLAWS = 207272,
    CLAWING_SHADOWS = 207311,
    UNHOLY_PACT = 319230,
    ABOMINATION_LIMB = 383269, -- New in TWW Season 2
    VILE_CONTAGION = 390279, -- New in TWW Season 2
    GHOULISH_FRENZY = 377587, -- Important for Season 2
    MORBIDITY = 377592, -- Enhanced in Season 2
    FESTERMIGHT = 377590, -- Key for damage scaling
    PLAGUEBRINGER = 390175, -- Important debuff ability
    SUPERSTRAIN = 390234, -- New powerful talent for TWW S2
    IMPROVED_DEATH_COIL = 377580, -- Enhanced for Season 2
    PANDEMIC = 377541, -- New cleave ability
    COIL_OF_DEVASTATION = 390270, -- Powerful new cooldown
    
    -- Misc
    PATH_OF_FROST = 3714,
    DEATH_GATE = 50977,
    RAISE_DEAD = 46585,
    DARK_COMMAND = 56222
}

-- Important buffs to track (The War Within, Season 2)
local BUFFS = {
    -- Blood buffs
    BONE_SHIELD = 195181,
    DANCING_RUNE_WEAPON = 81256,
    VAMPIRIC_BLOOD = 55233,
    HEMOSTASIS = 273947,
    CRIMSON_SCOURGE = 81141,
    BLOOD_SHIELD = 77535,
    OSSUARY = 219786, -- Important for Season 2
    INSATIABLE_BLADE = 377638, -- New in TWW S2
    BLOOD_FEAST = 391476, -- New in Season 2
    COAGULOPATHY = 391477, -- New Season 2 buff
    HEARTBLOOD = 377656, -- New for Blood DKs
    
    -- Frost buffs
    PILLAR_OF_FROST = 51271,
    EMPOWER_RUNE_WEAPON = 47568,
    KILLING_MACHINE = 51124,
    RIME = 59052,
    BREATH_OF_SINDRAGOSA = 152279,
    ABSOLUTE_ZERO = 377048, -- New buff in Season 2
    CLEAVING_STRIKES = 316916, -- Enhanced in Season 2
    EVERFROST = 376938, -- New in Season 2
    PIERCING_CHILL = 378460, -- Important new TWW buff
    FATAL_FIXATION = 405166, -- New ability in Season 2
    
    -- Unholy buffs
    DARK_TRANSFORMATION = 63560,
    SUDDEN_DOOM = 81340,
    RUNIC_CORRUPTION = 51460,
    UNHOLY_FRENZY = 207289,
    FESTERMIGHT = 377591, -- New buff in Season 2
    GHOULISH_FRENZY = 377588, -- Important for Season 2
    MORBIDITY = 377592, -- Enhanced in Season 2
    PANDEMIC = 377542, -- New cleave ability buff
    COIL_OF_DEVASTATION = 390271, -- New cooldown buff
    
    -- Shared buffs
    ANTI_MAGIC_SHELL = 48707,
    ICEBOUND_FORTITUDE = 48792,
    WRAITH_WALK = 212552,
    ABOMINATION_LIMB = 383313 -- New shared buff in TWW S2
}

-- Important debuffs to track (The War Within, Season 2)
local DEBUFFS = {
    -- Blood debuffs
    BLOOD_PLAGUE = 55078,
    MARK_OF_BLOOD = 206940,
    BLOOD_TAP = 221699,
    SANGUINE_BOND = 374028, -- New in Season 2
    
    -- Frost debuffs
    FROST_FEVER = 55095,
    RAZORICE = 51714,
    CHILL_STREAK = 305392, -- Important for Season 2
    
    -- Unholy debuffs
    VIRULENT_PLAGUE = 191587,
    FESTERING_WOUND = 194310,
    UNHOLY_BLIGHT = 115994,
    SOUL_REAPER = 343294,
    VILE_CONTAGION = 390279, -- New in TWW Season 2
    PLAGUEBRINGER = 390178, -- Important new debuff
    SUPERSTRAIN = 390275, -- Powerful Season 2 talent debuff
    
    -- Shared debuffs
    ABOMINATION_LIMB_DEBUFF = 383276 -- New shared debuff in TWW S2
}

-- Initialize the Death Knight module
function DeathKnightModule:Initialize()
    -- Register settings
    self:RegisterSettings()
    
    -- Register events
    self:RegisterEvents()
    
    -- Register rotations
    self:RegisterRotations()
    
    API.PrintDebug("Death Knight module initialized")
    return true
end

-- Register settings
function DeathKnightModule:RegisterSettings()
    ConfigRegistry:RegisterSettings("DeathKnight", {
        generalSettings = {
            enabled = {
                displayName = "Enable Death Knight Module",
                description = "Enable the Death Knight module for all specs",
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
            autoRaiseDead = {
                displayName = "Auto Raise Dead",
                description = "Automatically raise your ghoul if missing",
                type = "toggle",
                default = true
            },
            useIceboundFortitude = {
                displayName = "Use Icebound Fortitude",
                description = "Automatically use Icebound Fortitude at low health",
                type = "toggle",
                default = true
            },
            iceboundThreshold = {
                displayName = "Icebound Health Threshold",
                description = "Health percentage to use Icebound Fortitude",
                type = "slider",
                min = 10,
                max = 50,
                step = 5,
                default = 30
            },
            useAntiMagicShell = {
                displayName = "Use Anti-Magic Shell",
                description = "Automatically use Anti-Magic Shell when taking magic damage",
                type = "toggle",
                default = true
            }
        },
        bloodSettings = {
            -- Core mechanics
            maintainBoneShield = {
                displayName = "Maintain Bone Shield",
                description = "Prioritize maintaining Bone Shield stacks",
                type = "toggle",
                default = true
            },
            boneShieldMinStacks = {
                displayName = "Minimum Bone Shield Stacks",
                description = "Minimum Bone Shield stacks before refreshing",
                type = "slider",
                min = 3,
                max = 8,
                step = 1,
                default = 5
            },
            maintainOssuary = {
                displayName = "Maintain Ossuary",
                description = "Prioritize maintaining Ossuary buff (TWW Season 2)",
                type = "toggle",
                default = true
            },
            
            -- Defensive abilities
            useVampiricBlood = {
                displayName = "Use Vampiric Blood",
                description = "Automatically use Vampiric Blood at low health",
                type = "toggle",
                default = true
            },
            vampiricBloodThreshold = {
                displayName = "Vampiric Blood Health Threshold",
                description = "Health percentage to use Vampiric Blood",
                type = "slider",
                min = 20,
                max = 70,
                step = 5,
                default = 40
            },
            useDancingRuneWeapon = {
                displayName = "Use Dancing Rune Weapon",
                description = "Use Dancing Rune Weapon in combat",
                type = "toggle",
                default = true
            },
            
            -- Health management
            deathStrikeThreshold = {
                displayName = "Death Strike Health Threshold",
                description = "Health percentage to prioritize Death Strike",
                type = "slider",
                min = 20,
                max = 90,
                step = 5,
                default = 65
            },
            
            -- Season 2 abilities
            useAbominationLimb = {
                displayName = "Use Abomination Limb",
                description = "Use Abomination Limb on cooldown (TWW Season 2)",
                type = "toggle",
                default = true
            },
            useInsatiableBlade = {
                displayName = "Use Insatiable Blade",
                description = "Optimize rotation for Insatiable Blade talent (TWW Season 2)",
                type = "toggle",
                default = true
            },
            useBloodFeast = {
                displayName = "Use Blood Feast",
                description = "Use Blood Feast when available (TWW Season 2)",
                type = "toggle",
                default = true
            },
            useCoagulopathy = {
                displayName = "Use Coagulopathy",
                description = "Optimize rotation for Coagulopathy talent (TWW Season 2)",
                type = "toggle",
                default = true
            },
            
            -- AoE settings
            aoeThreshold = {
                displayName = "AoE Threshold",
                description = "Number of targets to switch to AoE rotation",
                type = "slider",
                min = 2,
                max = 6,
                step = 1,
                default = 3
            }
        },
        frostSettings = {
            -- Core offensive cooldowns
            usePillarOfFrost = {
                displayName = "Use Pillar of Frost",
                description = "Use Pillar of Frost on cooldown",
                type = "toggle",
                default = true
            },
            useEmpowerRuneWeapon = {
                displayName = "Use Empower Rune Weapon",
                description = "Use Empower Rune Weapon on cooldown",
                type = "toggle",
                default = true
            },
            useSindragosa = {
                displayName = "Use Breath of Sindragosa",
                description = "Use Breath of Sindragosa when available",
                type = "toggle",
                default = true
            },
            sindragosaRPThreshold = {
                displayName = "Sindragosa Runic Power Threshold",
                description = "Minimum Runic Power to maintain Breath of Sindragosa",
                type = "slider",
                min = 40,
                max = 80,
                step = 5,
                default = 50
            },
            poolRPForSindragosa = {
                displayName = "Pool RP for Sindragosa",
                description = "Pool Runic Power before Breath of Sindragosa",
                type = "toggle",
                default = true
            },
            
            -- Core abilities
            useHowlingBlastWithRime = {
                displayName = "Use Howling Blast with Rime",
                description = "Prioritize Howling Blast when Rime proc is active",
                type = "toggle",
                default = true
            },
            
            -- TWW Season 2 abilities
            useAbominationLimb = {
                displayName = "Use Abomination Limb",
                description = "Use Abomination Limb on cooldown (TWW Season 2)",
                type = "toggle",
                default = true
            },
            useObliterateCleave = {
                displayName = "Use Obliterate Cleave",
                description = "Optimize for Obliterate Cleave talent (TWW Season 2)",
                type = "toggle",
                default = true
            },
            useChillStreak = {
                displayName = "Use Chill Streak",
                description = "Use Chill Streak when available (TWW Season 2)",
                type = "toggle",
                default = true
            },
            useFatalFixation = {
                displayName = "Use Fatal Fixation",
                description = "Use Fatal Fixation ability when available (TWW Season 2)",
                type = "toggle",
                default = true
            },
            useEverfrost = {
                displayName = "Use Everfrost",
                description = "Optimize rotation for Everfrost talent (TWW Season 2)",
                type = "toggle",
                default = true
            },
            
            -- AoE settings
            aoeThreshold = {
                displayName = "AoE Threshold",
                description = "Number of targets to switch to AoE rotation",
                type = "slider",
                min = 2,
                max = 6,
                step = 1,
                default = 3
            }
        },
        unholySettings = {
            -- Core offensive cooldowns
            useApocalypse = {
                displayName = "Use Apocalypse",
                description = "Use Apocalypse on cooldown",
                type = "toggle",
                default = true
            },
            apocalypseFestWoundThreshold = {
                displayName = "Minimum Festering Wounds for Apocalypse",
                description = "Minimum Festering Wounds on target before using Apocalypse",
                type = "slider",
                min = 3,
                max = 6,
                step = 1,
                default = 4
            },
            useArmyOfTheDead = {
                displayName = "Use Army of the Dead",
                description = "Use Army of the Dead on cooldown",
                type = "toggle",
                default = true
            },
            useDarkTransformation = {
                displayName = "Use Dark Transformation",
                description = "Use Dark Transformation on cooldown",
                type = "toggle",
                default = true
            },
            useUnholyBlight = {
                displayName = "Use Unholy Blight",
                description = "Use Unholy Blight on cooldown",
                type = "toggle",
                default = true
            },
            
            -- Core debuff management
            maintainVirulentPlague = {
                displayName = "Maintain Virulent Plague",
                description = "Prioritize maintaining Virulent Plague on targets",
                type = "toggle",
                default = true
            },
            
            -- TWW Season 2 abilities
            useAbominationLimb = {
                displayName = "Use Abomination Limb",
                description = "Use Abomination Limb on cooldown (TWW Season 2)",
                type = "toggle",
                default = true
            },
            useVileContagion = {
                displayName = "Use Vile Contagion",
                description = "Use Vile Contagion when available (TWW Season 2)",
                type = "toggle",
                default = true
            },
            useGhoulishFrenzy = {
                displayName = "Use Ghoulish Frenzy",
                description = "Prioritize rotation for Ghoulish Frenzy (TWW Season 2)",
                type = "toggle",
                default = true
            },
            useFestermight = {
                displayName = "Use Festermight",
                description = "Optimize for Festermight stacks (TWW Season 2)",
                type = "toggle",
                default = true
            },
            useSuperstrain = {
                displayName = "Use Superstrain",
                description = "Optimize debuff application for Superstrain (TWW Season 2)",
                type = "toggle",
                default = true
            },
            usePandemic = {
                displayName = "Use Pandemic",
                description = "Use Pandemic cleave when available (TWW Season 2)",
                type = "toggle",
                default = true
            },
            useCoilOfDevastation = {
                displayName = "Use Coil of Devastation",
                description = "Use Coil of Devastation when available (TWW Season 2)",
                type = "toggle",
                default = true
            },
            
            -- AoE settings
            aoeThreshold = {
                displayName = "AoE Threshold",
                description = "Number of targets to switch to AoE rotation",
                type = "slider",
                min = 2,
                max = 6,
                step = 1,
                default = 3
            }
        }
    })
    
    -- Add callback for settings changes
    ConfigRegistry:RegisterCallback("DeathKnight", function(settings)
        self:ApplySettings(settings)
    end)
end

-- Apply settings
function DeathKnightModule:ApplySettings(settings)
    -- Apply general settings
    isEnabled = settings.generalSettings.enabled
end

-- Register events
function DeathKnightModule:RegisterEvents()
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
end

-- On specialization changed
function DeathKnightModule:OnSpecializationChanged()
    -- Get current spec ID
    playerSpec = API.GetActiveSpecID()
    
    API.PrintDebug("Death Knight specialization changed: " .. playerSpec)
    
    -- Ensure correct rotation is registered
    if playerSpec == SPEC_BLOOD then
        self:RegisterBloodRotation()
    elseif playerSpec == SPEC_FROST then
        self:RegisterFrostRotation()
    elseif playerSpec == SPEC_UNHOLY then
        self:RegisterUnholyRotation()
    end
end

-- Register rotations
function DeathKnightModule:RegisterRotations()
    -- Register spec-specific rotations
    self:RegisterBloodRotation()
    self:RegisterFrostRotation()
    self:RegisterUnholyRotation()
end

-- Register Blood rotation
function DeathKnightModule:RegisterBloodRotation()
    RotationManager:RegisterRotation("DeathKnightBlood", {
        id = "DeathKnightBlood",
        name = "Death Knight - Blood",
        class = "DEATHKNIGHT",
        spec = SPEC_BLOOD,
        level = 10,
        description = "Blood Death Knight rotation for The War Within Season 2",
        author = "WindrunnerRotations",
        version = "1.0.0",
        rotation = function()
            return self:BloodRotation()
        end
    })
end

-- Register Frost rotation
function DeathKnightModule:RegisterFrostRotation()
    RotationManager:RegisterRotation("DeathKnightFrost", {
        id = "DeathKnightFrost",
        name = "Death Knight - Frost",
        class = "DEATHKNIGHT",
        spec = SPEC_FROST,
        level = 10,
        description = "Frost Death Knight rotation for The War Within Season 2",
        author = "WindrunnerRotations",
        version = "1.0.0",
        rotation = function()
            return self:FrostRotation()
        end
    })
end

-- Register Unholy rotation
function DeathKnightModule:RegisterUnholyRotation()
    RotationManager:RegisterRotation("DeathKnightUnholy", {
        id = "DeathKnightUnholy",
        name = "Death Knight - Unholy",
        class = "DEATHKNIGHT",
        spec = SPEC_UNHOLY,
        level = 10,
        description = "Unholy Death Knight rotation for The War Within Season 2",
        author = "WindrunnerRotations",
        version = "1.0.0",
        rotation = function()
            return self:UnholyRotation()
        end
    })
end

-- Blood rotation
function DeathKnightModule:BloodRotation()
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
    local settings = ConfigRegistry:GetSettings("DeathKnight")
    
    -- Common Combat Variables
    local health, maxHealth, healthPercent = API.GetUnitHealth(player)
    local targetHealth, targetMaxHealth, targetHealthPercent = API.GetUnitHealth(target)
    local runicPower = API.GetUnitPower(player, Enum.PowerType.RunicPower)
    local runes = API.GetRuneCount()
    local enemies = API.GetEnemyCount(8)
    local aoeEnabled = settings.bloodSettings.aoeThreshold <= enemies
    local hasBoneShield, boneShieldStacks = API.UnitHasBuff(player, BUFFS.BONE_SHIELD)
    local hasDancingRuneWeapon = API.UnitHasBuff(player, BUFFS.DANCING_RUNE_WEAPON)
    local hasVampiricBlood = API.UnitHasBuff(player, BUFFS.VAMPIRIC_BLOOD)
    local hasCrimsonScourge = API.UnitHasBuff(player, BUFFS.CRIMSON_SCOURGE)
    local hasBloodPlague = API.UnitHasDebuff(target, DEBUFFS.BLOOD_PLAGUE)
    
    -- TWW Season 2 specific buffs/debuffs
    local hasOssuary = API.UnitHasBuff(player, BUFFS.OSSUARY)
    local hasInsatiableBlade = API.UnitHasBuff(player, BUFFS.INSATIABLE_BLADE)
    local hasBloodFeast = API.UnitHasBuff(player, BUFFS.BLOOD_FEAST)
    local hasCoagulopathy = API.UnitHasBuff(player, BUFFS.COAGULOPATHY)
    local hasHeartblood = API.UnitHasBuff(player, BUFFS.HEARTBLOOD)
    local hasSanguineBond = API.UnitHasDebuff(target, DEBUFFS.SANGUINE_BOND)
    local hasAbominationLimb = API.UnitHasBuff(player, BUFFS.ABOMINATION_LIMB)
    
    -- Check for ghoul
    if settings.generalSettings.autoRaiseDead and not UnitExists("pet") then
        if API.IsSpellKnown(BLOOD_SPELLS.RAISE_DEAD) and API.IsSpellUsable(BLOOD_SPELLS.RAISE_DEAD) then
            return {
                type = "spell",
                id = BLOOD_SPELLS.RAISE_DEAD,
                target = player
            }
        end
    end
    
    -- Interrupt handling
    if settings.generalSettings.useInterrupts and 
       API.CanInterruptTarget(target) and
       API.IsSpellKnown(BLOOD_SPELLS.MIND_FREEZE) and 
       API.IsSpellUsable(BLOOD_SPELLS.MIND_FREEZE) then
        return {
            type = "spell",
            id = BLOOD_SPELLS.MIND_FREEZE,
            target = target
        }
    end
    
    -- Defensive abilities
    if settings.generalSettings.useDefensives then
        -- Anti-Magic Shell against magic damage
        if settings.generalSettings.useAntiMagicShell and
           API.IsSpellKnown(BLOOD_SPELLS.ANTI_MAGIC_SHELL) and 
           API.IsSpellUsable(BLOOD_SPELLS.ANTI_MAGIC_SHELL) and
           API.IsTakingMagicDamage() then
            return {
                type = "spell",
                id = BLOOD_SPELLS.ANTI_MAGIC_SHELL,
                target = player
            }
        end
        
        -- Icebound Fortitude at low health
        if settings.generalSettings.useIceboundFortitude and
           healthPercent <= settings.generalSettings.iceboundThreshold and
           API.IsSpellKnown(BLOOD_SPELLS.ICEBOUND_FORTITUDE) and 
           API.IsSpellUsable(BLOOD_SPELLS.ICEBOUND_FORTITUDE) then
            return {
                type = "spell",
                id = BLOOD_SPELLS.ICEBOUND_FORTITUDE,
                target = player
            }
        end
        
        -- Vampiric Blood at low health
        if settings.bloodSettings.useVampiricBlood and
           healthPercent <= settings.bloodSettings.vampiricBloodThreshold and
           API.IsSpellKnown(BLOOD_SPELLS.VAMPIRIC_BLOOD) and 
           API.IsSpellUsable(BLOOD_SPELLS.VAMPIRIC_BLOOD) then
            return {
                type = "spell",
                id = BLOOD_SPELLS.VAMPIRIC_BLOOD,
                target = player
            }
        end
        
        -- Death Strike at low health
        if healthPercent <= settings.bloodSettings.deathStrikeThreshold and
           runicPower >= 45 and
           API.IsSpellKnown(BLOOD_SPELLS.DEATH_STRIKE) and 
           API.IsSpellUsable(BLOOD_SPELLS.DEATH_STRIKE) then
            return {
                type = "spell",
                id = BLOOD_SPELLS.DEATH_STRIKE,
                target = target
            }
        end
    end
    
    -- Marrowrend to maintain Bone Shield if needed
    if settings.bloodSettings.maintainBoneShield and
       (not hasBoneShield or boneShieldStacks < settings.bloodSettings.boneShieldMinStacks) and
       API.IsSpellKnown(BLOOD_SPELLS.MARROWREND) and 
       API.IsSpellUsable(BLOOD_SPELLS.MARROWREND) and
       runes >= 2 then
        return {
            type = "spell",
            id = BLOOD_SPELLS.MARROWREND,
            target = target
        }
    end
    
    -- Maintain Ossuary (TWW Season 2)
    if settings.bloodSettings.maintainOssuary and
       API.IsSpellKnown(BLOOD_SPELLS.OSSUARY) and
       hasBoneShield and boneShieldStacks < 7 and
       API.IsSpellKnown(BLOOD_SPELLS.MARROWREND) and 
       API.IsSpellUsable(BLOOD_SPELLS.MARROWREND) and
       runes >= 2 then
        return {
            type = "spell",
            id = BLOOD_SPELLS.MARROWREND,
            target = target
        }
    end
    
    -- Offensive cooldowns
    if inCombat then
        -- Dancing Rune Weapon
        if settings.bloodSettings.useDancingRuneWeapon and
           API.IsSpellKnown(BLOOD_SPELLS.DANCING_RUNE_WEAPON) and 
           API.IsSpellUsable(BLOOD_SPELLS.DANCING_RUNE_WEAPON) then
            return {
                type = "spell",
                id = BLOOD_SPELLS.DANCING_RUNE_WEAPON,
                target = player
            }
        end
        
        -- Abomination Limb (TWW Season 2)
        if settings.bloodSettings.useAbominationLimb and
           API.IsSpellKnown(BLOOD_SPELLS.ABOMINATION_LIMB) and 
           API.IsSpellUsable(BLOOD_SPELLS.ABOMINATION_LIMB) and
           enemies >= 2 then
            return {
                type = "spell",
                id = BLOOD_SPELLS.ABOMINATION_LIMB,
                target = player
            }
        end
        
        -- Blood Feast (TWW Season 2)
        if settings.bloodSettings.useBloodFeast and
           API.IsSpellKnown(BLOOD_SPELLS.BLOOD_FEAST) and 
           API.IsSpellUsable(BLOOD_SPELLS.BLOOD_FEAST) and
           healthPercent < 70 then
            return {
                type = "spell",
                id = BLOOD_SPELLS.BLOOD_FEAST,
                target = target
            }
        end
        
        -- Blood tap to get more runes
        if runes <= 2 and
           API.IsSpellKnown(BLOOD_SPELLS.BLOOD_TAP) and 
           API.IsSpellUsable(BLOOD_SPELLS.BLOOD_TAP) then
            return {
                type = "spell",
                id = BLOOD_SPELLS.BLOOD_TAP,
                target = player
            }
        end
        
        -- Consumption for damage and healing
        if API.IsSpellKnown(BLOOD_SPELLS.CONSUMPTION) and 
           API.IsSpellUsable(BLOOD_SPELLS.CONSUMPTION) then
            return {
                type = "spell",
                id = BLOOD_SPELLS.CONSUMPTION,
                target = target
            }
        end
        
        -- Blooddrinker if talented
        if API.IsSpellKnown(BLOOD_SPELLS.BLOODDRINKER) and 
           API.IsSpellUsable(BLOOD_SPELLS.BLOODDRINKER) and
           runes < 3 then
            return {
                type = "spell",
                id = BLOOD_SPELLS.BLOODDRINKER,
                target = target
            }
        end
    end
    
    -- AoE rotation
    if aoeEnabled and enemies >= 3 then
        -- Death and Decay with Crimson Scourge proc
        if hasCrimsonScourge and
           API.IsSpellKnown(BLOOD_SPELLS.DEATH_AND_DECAY) and 
           API.IsSpellUsable(BLOOD_SPELLS.DEATH_AND_DECAY) then
            return {
                type = "spell",
                id = BLOOD_SPELLS.DEATH_AND_DECAY,
                target = player
            }
        end
        
        -- Death and Decay normally
        if runes >= 1 and
           API.IsSpellKnown(BLOOD_SPELLS.DEATH_AND_DECAY) and 
           API.IsSpellUsable(BLOOD_SPELLS.DEATH_AND_DECAY) then
            return {
                type = "spell",
                id = BLOOD_SPELLS.DEATH_AND_DECAY,
                target = player
            }
        end
        
        -- Blood Boil for AoE Blood Plague
        if not hasBloodPlague and
           API.IsSpellKnown(BLOOD_SPELLS.BLOOD_BOIL) and 
           API.IsSpellUsable(BLOOD_SPELLS.BLOOD_BOIL) then
            return {
                type = "spell",
                id = BLOOD_SPELLS.BLOOD_BOIL,
                target = target
            }
        end
        
        -- Blood Feast (TWW Season 2) for AoE situations
        if settings.bloodSettings.useBloodFeast and
           API.IsSpellKnown(BLOOD_SPELLS.BLOOD_FEAST) and 
           API.IsSpellUsable(BLOOD_SPELLS.BLOOD_FEAST) then
            return {
                type = "spell",
                id = BLOOD_SPELLS.BLOOD_FEAST,
                target = target
            }
        end
        
        -- Bonestorm if talented and high runic power
        if runicPower >= 90 and
           API.IsSpellKnown(BLOOD_SPELLS.BONESTORM) and 
           API.IsSpellUsable(BLOOD_SPELLS.BONESTORM) then
            return {
                type = "spell",
                id = BLOOD_SPELLS.BONESTORM,
                target = player
            }
        end
    end
    
    -- Sanguine Bond application (TWW Season 2)
    if settings.bloodSettings.useInsatiableBlade and
       API.IsSpellKnown(BLOOD_SPELLS.INSATIABLE_BLADE) and
       not hasSanguineBond and
       runicPower >= 45 and
       API.IsSpellKnown(BLOOD_SPELLS.DEATH_STRIKE) and 
       API.IsSpellUsable(BLOOD_SPELLS.DEATH_STRIKE) then
        return {
            type = "spell",
            id = BLOOD_SPELLS.DEATH_STRIKE,
            target = target
        }
    end
    
    -- Core rotation
    -- Blood Boil to apply/refresh Blood Plague
    if (not hasBloodPlague or API.GetSpellCharges(BLOOD_SPELLS.BLOOD_BOIL) > 1.5) and
       API.IsSpellKnown(BLOOD_SPELLS.BLOOD_BOIL) and 
       API.IsSpellUsable(BLOOD_SPELLS.BLOOD_BOIL) then
        return {
            type = "spell",
            id = BLOOD_SPELLS.BLOOD_BOIL,
            target = target
        }
    end
    
    -- Coagulopathy optimization (TWW Season 2)
    if settings.bloodSettings.useCoagulopathy and
       API.IsSpellKnown(BLOOD_SPELLS.COAGULOPATHY) and
       hasCoagulopathy and
       API.IsSpellKnown(BLOOD_SPELLS.DEATH_AND_DECAY) and 
       API.IsSpellUsable(BLOOD_SPELLS.DEATH_AND_DECAY) and
       runes >= 1 then
        return {
            type = "spell",
            id = BLOOD_SPELLS.DEATH_AND_DECAY,
            target = player
        }
    end
    
    -- Heart Strike to generate runic power
    if runes >= 1 and
       API.IsSpellKnown(BLOOD_SPELLS.HEART_STRIKE) and 
       API.IsSpellUsable(BLOOD_SPELLS.HEART_STRIKE) then
        return {
            type = "spell",
            id = BLOOD_SPELLS.HEART_STRIKE,
            target = target
        }
    end
    
    -- Death Strike with Insatiable Blade proc (TWW Season 2)
    if hasInsatiableBlade and
       runicPower >= 45 and
       API.IsSpellKnown(BLOOD_SPELLS.DEATH_STRIKE) and 
       API.IsSpellUsable(BLOOD_SPELLS.DEATH_STRIKE) then
        return {
            type = "spell",
            id = BLOOD_SPELLS.DEATH_STRIKE,
            target = target
        }
    end
    
    -- Death Strike to spend runic power
    if runicPower >= 45 and
       API.IsSpellKnown(BLOOD_SPELLS.DEATH_STRIKE) and 
       API.IsSpellUsable(BLOOD_SPELLS.DEATH_STRIKE) then
        return {
            type = "spell",
            id = BLOOD_SPELLS.DEATH_STRIKE,
            target = target
        }
    end
    
    return nil
end

-- Frost rotation
function DeathKnightModule:FrostRotation()
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
    local settings = ConfigRegistry:GetSettings("DeathKnight")
    
    -- Common Combat Variables
    local health, maxHealth, healthPercent = API.GetUnitHealth(player)
    local targetHealth, targetMaxHealth, targetHealthPercent = API.GetUnitHealth(target)
    local runicPower = API.GetUnitPower(player, Enum.PowerType.RunicPower)
    local runes = API.GetRuneCount()
    local enemies = API.GetEnemyCount(8)
    local aoeEnabled = settings.frostSettings.aoeThreshold <= enemies
    local hasPillarOfFrost = API.UnitHasBuff(player, BUFFS.PILLAR_OF_FROST)
    local hasEmpowerRuneWeapon = API.UnitHasBuff(player, BUFFS.EMPOWER_RUNE_WEAPON)
    local hasKillingMachine = API.UnitHasBuff(player, BUFFS.KILLING_MACHINE)
    local hasRime = API.UnitHasBuff(player, BUFFS.RIME)
    local hasBreathOfSindragosa = API.UnitHasBuff(player, BUFFS.BREATH_OF_SINDRAGOSA)
    local hasFrostFever = API.UnitHasDebuff(target, DEBUFFS.FROST_FEVER)
    
    -- Check for ghoul
    if settings.generalSettings.autoRaiseDead and not UnitExists("pet") then
        if API.IsSpellKnown(FROST_SPELLS.RAISE_DEAD) and API.IsSpellUsable(FROST_SPELLS.RAISE_DEAD) then
            return {
                type = "spell",
                id = FROST_SPELLS.RAISE_DEAD,
                target = player
            }
        end
    end
    
    -- Defensive abilities
    if settings.generalSettings.useDefensives then
        -- Anti-Magic Shell against magic damage
        if settings.generalSettings.useAntiMagicShell and
           API.IsSpellKnown(FROST_SPELLS.ANTI_MAGIC_SHELL) and 
           API.IsSpellUsable(FROST_SPELLS.ANTI_MAGIC_SHELL) and
           API.IsTakingMagicDamage() then
            return {
                type = "spell",
                id = FROST_SPELLS.ANTI_MAGIC_SHELL,
                target = player
            }
        end
        
        -- Icebound Fortitude at low health
        if settings.generalSettings.useIceboundFortitude and
           healthPercent <= settings.generalSettings.iceboundThreshold and
           API.IsSpellKnown(FROST_SPELLS.ICEBOUND_FORTITUDE) and 
           API.IsSpellUsable(FROST_SPELLS.ICEBOUND_FORTITUDE) then
            return {
                type = "spell",
                id = FROST_SPELLS.ICEBOUND_FORTITUDE,
                target = player
            }
        end
    end
    
    -- Howling Blast to apply Frost Fever
    if not hasFrostFever and
       API.IsSpellKnown(FROST_SPELLS.HOWLING_BLAST) and 
       API.IsSpellUsable(FROST_SPELLS.HOWLING_BLAST) and
       runes >= 1 then
        return {
            type = "spell",
            id = FROST_SPELLS.HOWLING_BLAST,
            target = target
        }
    end
    
    -- Offensive cooldowns
    if inCombat then
        -- Pillar of Frost
        if settings.frostSettings.usePillarOfFrost and
           API.IsSpellKnown(FROST_SPELLS.PILLAR_OF_FROST) and 
           API.IsSpellUsable(FROST_SPELLS.PILLAR_OF_FROST) then
            return {
                type = "spell",
                id = FROST_SPELLS.PILLAR_OF_FROST,
                target = player
            }
        end
        
        -- Empower Rune Weapon
        if settings.frostSettings.useEmpowerRuneWeapon and
           API.IsSpellKnown(FROST_SPELLS.EMPOWER_RUNE_WEAPON) and 
           API.IsSpellUsable(FROST_SPELLS.EMPOWER_RUNE_WEAPON) and
           (hasPillarOfFrost or runes <= 2) then
            return {
                type = "spell",
                id = FROST_SPELLS.EMPOWER_RUNE_WEAPON,
                target = player
            }
        end
        
        -- Breath of Sindragosa
        if settings.frostSettings.useSindragosa and
           not hasBreathOfSindragosa and
           runicPower >= 80 and 
           hasPillarOfFrost and
           API.IsSpellKnown(FROST_SPELLS.BREATH_OF_SINDRAGOSA) and 
           API.IsSpellUsable(FROST_SPELLS.BREATH_OF_SINDRAGOSA) then
            return {
                type = "spell",
                id = FROST_SPELLS.BREATH_OF_SINDRAGOSA,
                target = target
            }
        end
        
        -- Frostwyrm's Fury with Pillar of Frost
        if hasPillarOfFrost and
           API.IsSpellKnown(FROST_SPELLS.FROSTWYRM'S_FURY) and 
           API.IsSpellUsable(FROST_SPELLS.FROSTWYRM'S_FURY) then
            return {
                type = "spell",
                id = FROST_SPELLS.FROSTWYRM'S_FURY,
                target = target
            }
        end
        
        -- Horn of Winter for runic power and runes
        if API.IsSpellKnown(FROST_SPELLS.HORN_OF_WINTER) and 
           API.IsSpellUsable(FROST_SPELLS.HORN_OF_WINTER) and
           (runes <= 3 or runicPower <= 70) then
            return {
                type = "spell",
                id = FROST_SPELLS.HORN_OF_WINTER,
                target = player
            }
        end
    end
    
    -- Maintain Breath of Sindragosa by avoiding runic power drops
    if hasBreathOfSindragosa and runicPower <= settings.frostSettings.sindragosaRPThreshold then
        -- Avoid using runic power until enough to keep Breath up
        -- Only use rune abilities
    else
        -- AoE rotation
        if aoeEnabled and enemies >= 3 then
            -- Frostscythe with Killing Machine
            if hasKillingMachine and
               API.IsSpellKnown(FROST_SPELLS.FROSTSCYTHE) and 
               API.IsSpellUsable(FROST_SPELLS.FROSTSCYTHE) and
               runes >= 1 then
                return {
                    type = "spell",
                    id = FROST_SPELLS.FROSTSCYTHE,
                    target = target
                }
            end
            
            -- Glacial Advance for AoE
            if API.IsSpellKnown(FROST_SPELLS.GLACIAL_ADVANCE) and 
               API.IsSpellUsable(FROST_SPELLS.GLACIAL_ADVANCE) and
               runicPower >= 30 then
                return {
                    type = "spell",
                    id = FROST_SPELLS.GLACIAL_ADVANCE,
                    target = target
                }
            end
            
            -- Remorseless Winter for AoE
            if API.IsSpellKnown(FROST_SPELLS.REMORSELESS_WINTER) and 
               API.IsSpellUsable(FROST_SPELLS.REMORSELESS_WINTER) and
               runes >= 1 then
                return {
                    type = "spell",
                    id = FROST_SPELLS.REMORSELESS_WINTER,
                    target = player
                }
            end
            
            -- Howling Blast for AoE
            if API.IsSpellKnown(FROST_SPELLS.HOWLING_BLAST) and 
               API.IsSpellUsable(FROST_SPELLS.HOWLING_BLAST) and
               runes >= 1 then
                return {
                    type = "spell",
                    id = FROST_SPELLS.HOWLING_BLAST,
                    target = target
                }
            end
        end
    }
    
    -- Core rotation
    -- Howling Blast with Rime proc
    if settings.frostSettings.useHowlingBlastWithRime and
       hasRime and
       API.IsSpellKnown(FROST_SPELLS.HOWLING_BLAST) and 
       API.IsSpellUsable(FROST_SPELLS.HOWLING_BLAST) then
        return {
            type = "spell",
            id = FROST_SPELLS.HOWLING_BLAST,
            target = target
        }
    end
    
    -- Obliterate with Killing Machine
    if hasKillingMachine and
       API.IsSpellKnown(FROST_SPELLS.OBLITERATE) and 
       API.IsSpellUsable(FROST_SPELLS.OBLITERATE) and
       runes >= 2 then
        return {
            type = "spell",
            id = FROST_SPELLS.OBLITERATE,
            target = target
        }
    end
    
    -- Remorseless Winter on cooldown
    if API.IsSpellKnown(FROST_SPELLS.REMORSELESS_WINTER) and 
       API.IsSpellUsable(FROST_SPELLS.REMORSELESS_WINTER) and
       runes >= 1 then
        return {
            type = "spell",
            id = FROST_SPELLS.REMORSELESS_WINTER,
            target = player
        }
    end
    
    -- Obliterate to spend runes
    if runes >= 2 and
       API.IsSpellKnown(FROST_SPELLS.OBLITERATE) and 
       API.IsSpellUsable(FROST_SPELLS.OBLITERATE) then
        return {
            type = "spell",
            id = FROST_SPELLS.OBLITERATE,
            target = target
        }
    end
    
    -- Frost Strike to spend runic power
    if (runicPower >= 30 and not hasBreathOfSindragosa) or 
       (runicPower >= 70 and not settings.frostSettings.poolRPForSindragosa) and
       API.IsSpellKnown(FROST_SPELLS.FROST_STRIKE) and 
       API.IsSpellUsable(FROST_SPELLS.FROST_STRIKE) then
        return {
            type = "spell",
            id = FROST_SPELLS.FROST_STRIKE,
            target = target
        }
    end
    
    return nil
end

-- Unholy rotation
function DeathKnightModule:UnholyRotation()
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
    local settings = ConfigRegistry:GetSettings("DeathKnight")
    
    -- Common Combat Variables
    local health, maxHealth, healthPercent = API.GetUnitHealth(player)
    local targetHealth, targetMaxHealth, targetHealthPercent = API.GetUnitHealth(target)
    local runicPower = API.GetUnitPower(player, Enum.PowerType.RunicPower)
    local runes = API.GetRuneCount()
    local enemies = API.GetEnemyCount(8)
    local aoeEnabled = settings.unholySettings.aoeThreshold <= enemies
    local hasVirulentPlague = API.UnitHasDebuff(target, DEBUFFS.VIRULENT_PLAGUE)
    local festWoundCount = API.GetDebuffStacks(target, DEBUFFS.FESTERING_WOUND)
    local hasDarkTransformation = API.UnitHasBuff("pet", BUFFS.DARK_TRANSFORMATION)
    local hasSuddenDoom = API.UnitHasBuff(player, BUFFS.SUDDEN_DOOM)
    local hasRunicCorruption = API.UnitHasBuff(player, BUFFS.RUNIC_CORRUPTION)
    
    -- Check for ghoul
    if settings.generalSettings.autoRaiseDead and not UnitExists("pet") then
        if API.IsSpellKnown(UNHOLY_SPELLS.RAISE_DEAD) and API.IsSpellUsable(UNHOLY_SPELLS.RAISE_DEAD) then
            return {
                type = "spell",
                id = UNHOLY_SPELLS.RAISE_DEAD,
                target = player
            }
        end
    end
    
    -- Defensive abilities
    if settings.generalSettings.useDefensives then
        -- Anti-Magic Shell against magic damage
        if settings.generalSettings.useAntiMagicShell and
           API.IsSpellKnown(UNHOLY_SPELLS.ANTI_MAGIC_SHELL) and 
           API.IsSpellUsable(UNHOLY_SPELLS.ANTI_MAGIC_SHELL) and
           API.IsTakingMagicDamage() then
            return {
                type = "spell",
                id = UNHOLY_SPELLS.ANTI_MAGIC_SHELL,
                target = player
            }
        end
        
        -- Icebound Fortitude at low health
        if settings.generalSettings.useIceboundFortitude and
           healthPercent <= settings.generalSettings.iceboundThreshold and
           API.IsSpellKnown(UNHOLY_SPELLS.ICEBOUND_FORTITUDE) and 
           API.IsSpellUsable(UNHOLY_SPELLS.ICEBOUND_FORTITUDE) then
            return {
                type = "spell",
                id = UNHOLY_SPELLS.ICEBOUND_FORTITUDE,
                target = player
            }
        end
    end
    
    -- Apply or refresh Virulent Plague
    if settings.unholySettings.maintainVirulentPlague and not hasVirulentPlague and
       API.IsSpellKnown(UNHOLY_SPELLS.OUTBREAK) and 
       API.IsSpellUsable(UNHOLY_SPELLS.OUTBREAK) then
        return {
            type = "spell",
            id = UNHOLY_SPELLS.OUTBREAK,
            target = target
        }
    end
    
    -- Offensive cooldowns
    if inCombat then
        -- Army of the Dead
        if settings.unholySettings.useArmyOfTheDead and
           API.IsSpellKnown(UNHOLY_SPELLS.ARMY_OF_THE_DEAD) and 
           API.IsSpellUsable(UNHOLY_SPELLS.ARMY_OF_THE_DEAD) then
            return {
                type = "spell",
                id = UNHOLY_SPELLS.ARMY_OF_THE_DEAD,
                target = player
            }
        end
        
        -- Dark Transformation when pet is active
        if settings.unholySettings.useDarkTransformation and
           UnitExists("pet") and not hasDarkTransformation and
           API.IsSpellKnown(UNHOLY_SPELLS.DARK_TRANSFORMATION) and 
           API.IsSpellUsable(UNHOLY_SPELLS.DARK_TRANSFORMATION) then
            return {
                type = "spell",
                id = UNHOLY_SPELLS.DARK_TRANSFORMATION,
                target = player
            }
        end
        
        -- Unholy Blight
        if settings.unholySettings.useUnholyBlight and
           API.IsSpellKnown(UNHOLY_SPELLS.UNHOLY_BLIGHT) and 
           API.IsSpellUsable(UNHOLY_SPELLS.UNHOLY_BLIGHT) then
            return {
                type = "spell",
                id = UNHOLY_SPELLS.UNHOLY_BLIGHT,
                target = player
            }
        end
        
        -- Summon Gargoyle if talented
        if API.IsSpellKnown(UNHOLY_SPELLS.SUMMON_GARGOYLE) and 
           API.IsSpellUsable(UNHOLY_SPELLS.SUMMON_GARGOYLE) then
            return {
                type = "spell",
                id = UNHOLY_SPELLS.SUMMON_GARGOYLE,
                target = target
            }
        end
        
        -- Apocalypse with enough wounds
        if settings.unholySettings.useApocalypse and
           festWoundCount >= settings.unholySettings.apocalypseFestWoundThreshold and
           API.IsSpellKnown(UNHOLY_SPELLS.APOCALYPSE) and 
           API.IsSpellUsable(UNHOLY_SPELLS.APOCALYPSE) then
            return {
                type = "spell",
                id = UNHOLY_SPELLS.APOCALYPSE,
                target = target
            }
        end
        
        -- Soul Reaper if talented
        if targetHealthPercent < 35 and
           API.IsSpellKnown(UNHOLY_SPELLS.SOUL_REAPER) and 
           API.IsSpellUsable(UNHOLY_SPELLS.SOUL_REAPER) then
            return {
                type = "spell",
                id = UNHOLY_SPELLS.SOUL_REAPER,
                target = target
            }
        end
    end
    
    -- AoE rotation
    if aoeEnabled and enemies >= 3 then
        -- Defile if talented
        if API.IsSpellKnown(UNHOLY_SPELLS.DEFILE) and 
           API.IsSpellUsable(UNHOLY_SPELLS.DEFILE) then
            return {
                type = "spell",
                id = UNHOLY_SPELLS.DEFILE,
                target = target
            }
        end
        
        -- Death and Decay
        if API.IsSpellKnown(UNHOLY_SPELLS.DEATH_AND_DECAY) and 
           API.IsSpellUsable(UNHOLY_SPELLS.DEATH_AND_DECAY) and
           runes >= 1 then
            return {
                type = "spell",
                id = UNHOLY_SPELLS.DEATH_AND_DECAY,
                target = player
            }
        end
        
        -- Epidemic for AoE
        if API.IsSpellKnown(UNHOLY_SPELLS.EPIDEMIC) and 
           API.IsSpellUsable(UNHOLY_SPELLS.EPIDEMIC) and
           runicPower >= 30 then
            return {
                type = "spell",
                id = UNHOLY_SPELLS.EPIDEMIC,
                target = target
            }
        end
    end
    
    -- Core rotation
    -- Festering Strike to apply wounds
    if festWoundCount < 4 and
       API.IsSpellKnown(UNHOLY_SPELLS.FESTERING_STRIKE) and 
       API.IsSpellUsable(UNHOLY_SPELLS.FESTERING_STRIKE) and
       runes >= 2 then
        return {
            type = "spell",
            id = UNHOLY_SPELLS.FESTERING_STRIKE,
            target = target
        }
    end
    
    -- Death Coil with Sudden Doom proc
    if hasSuddenDoom and
       API.IsSpellKnown(UNHOLY_SPELLS.DEATH_COIL) and 
       API.IsSpellUsable(UNHOLY_SPELLS.DEATH_COIL) then
        return {
            type = "spell",
            id = UNHOLY_SPELLS.DEATH_COIL,
            target = target
        }
    end
    
    -- Scourge Strike / Clawing Shadows to pop wounds
    if festWoundCount >= 1 then
        -- Use Clawing Shadows if talented
        if API.IsSpellKnown(UNHOLY_SPELLS.CLAWING_SHADOWS) and 
           API.IsSpellUsable(UNHOLY_SPELLS.CLAWING_SHADOWS) and
           runes >= 1 then
            return {
                type = "spell",
                id = UNHOLY_SPELLS.CLAWING_SHADOWS,
                target = target
            }
        -- Otherwise use Scourge Strike
        elseif API.IsSpellKnown(UNHOLY_SPELLS.SCOURGE_STRIKE) and 
               API.IsSpellUsable(UNHOLY_SPELLS.SCOURGE_STRIKE) and
               runes >= 1 then
            return {
                type = "spell",
                id = UNHOLY_SPELLS.SCOURGE_STRIKE,
                target = target
            }
        end
    end
    
    -- Death Coil to spend runic power
    if runicPower >= 40 and
       API.IsSpellKnown(UNHOLY_SPELLS.DEATH_COIL) and 
       API.IsSpellUsable(UNHOLY_SPELLS.DEATH_COIL) then
        return {
            type = "spell",
            id = UNHOLY_SPELLS.DEATH_COIL,
            target = target
        }
    end
    
    -- Festering Strike as filler
    if runes >= 2 and
       API.IsSpellKnown(UNHOLY_SPELLS.FESTERING_STRIKE) and 
       API.IsSpellUsable(UNHOLY_SPELLS.FESTERING_STRIKE) then
        return {
            type = "spell",
            id = UNHOLY_SPELLS.FESTERING_STRIKE,
            target = target
        }
    end
    
    return nil
end

-- Should execute rotation
function DeathKnightModule:ShouldExecuteRotation()
    if not isEnabled then
        return false
    end
    
    -- Check if player matches class
    local playerInfo = API.GetPlayerInfo()
    if playerInfo.class ~= "DEATHKNIGHT" then
        return false
    end
    
    return true
end

-- Get rune count
function API.GetRuneCount()
    -- Try to use Tinkr's API if available
    if API.IsTinkrLoaded() and Tinkr.Util then
        return Tinkr.Util:Runes() or 0
    end
    
    -- Fallback to WoW API
    local count = 0
    for i = 1, 6 do
        local start, duration, runeReady = GetRuneCooldown(i)
        if runeReady then
            count = count + 1
        end
    end
    
    return count
end

-- Check if taking magic damage
function API.IsTakingMagicDamage()
    -- This would need to be implemented with proper combat log parsing
    -- For now, we'll just return a simple approximation based on recent damage
    local damage = API.GetRecentMagicDamage(3) -- Last 3 seconds
    return damage > 0
end

-- Get recent magic damage
function API.GetRecentMagicDamage(seconds)
    -- This would need to be implemented with proper combat log parsing
    -- For now, just return a placeholder
    return 0
end

-- Get debuff stacks
function API.GetDebuffStacks(unit, debuff)
    -- Try to use Tinkr's API if available
    if API.IsTinkrLoaded() and Tinkr.Unit then
        return Tinkr.Unit[unit]:Debuff(debuff, "player"):Stacks() or 0
    end
    
    -- Fallback to WoW API
    local name, _, count = API.UnitHasDebuff(unit, debuff)
    if name then
        return count or 0
    end
    
    return 0
end

-- Register for export
WR.DeathKnight = DeathKnightModule

return DeathKnightModule