------------------------------------------
-- WindrunnerRotations - Shaman Class Module
-- Author: VortexQ8
-- The War Within Season 2
------------------------------------------

local addonName, WR = ...
local ShamanModule = {}
WR.Shaman = ShamanModule

-- Dependencies
local API = WR.API
local ConfigRegistry = WR.ConfigRegistry
local RotationManager = WR.RotationManager
local ErrorHandler = WR.ErrorHandler
local CombatAnalysis = WR.CombatAnalysis
local AntiDetectionSystem = WR.AntiDetectionSystem
local PvPManager = WR.PvPManager

-- Shaman constants
local CLASS_ID = 7 -- Shaman class ID
local SPEC_ELEMENTAL = 262
local SPEC_ENHANCEMENT = 263
local SPEC_RESTORATION = 264

-- Current player data
local playerSpec = 0
local isEnabled = true
local inCombat = false

-- Spell IDs for Elemental Shaman (The War Within, Season 2)
local ELEMENTAL_SPELLS = {
    -- Core abilities
    LIGHTNING_BOLT = 188196,
    CHAIN_LIGHTNING = 188443,
    LAVA_BURST = 51505,
    FLAME_SHOCK = 188389,
    EARTH_SHOCK = 8042,
    EARTHQUAKE = 61882,
    FIRE_ELEMENTAL = 198067,
    EARTH_ELEMENTAL = 198103,
    STORM_ELEMENTAL = 192249,
    ELEMENTAL_BLAST = 117014,
    FROST_SHOCK = 196840,
    ICEFURY = 210714,
    LIQUID_MAGMA_TOTEM = 192222,
    PRIMAL_ELEMENTALIST = 117013,
    
    -- Defensive & utility
    ASTRAL_SHIFT = 108271,
    WIND_SHEAR = 57994,
    SPIRITWALKER'S_GRACE = 79206,
    THUNDERSTORM = 51490,
    CAPACITOR_TOTEM = 192058,
    EARTHBIND_TOTEM = 2484,
    WIND_RUSH_TOTEM = 192077,
    
    -- Talents
    ASCENDANCE = 114050,
    ECHO_OF_THE_ELEMENTS = 333919,
    MASTER_OF_THE_ELEMENTS = 16166,
    SURGE_OF_POWER = 262303,
    STORMKEEPER = 191634,
    PRIMORDIAL_WAVE = 375982,
    
    -- Misc
    BLOODLUST = 2825,
    HEROISM = 32182,
    PURGE = 370,
    EARTHEN_SPIKE = 188089,
    ANCESTRAL_GUIDANCE = 108281,
    HEALING_STREAM_TOTEM = 5394,
    GHOST_WOLF = 2645,
    PURIFY_SPIRIT = 77130
}

-- Spell IDs for Enhancement Shaman
local ENHANCEMENT_SPELLS = {
    -- Core abilities
    STORMSTRIKE = 17364,
    LAVA_LASH = 60103,
    CRASH_LIGHTNING = 187874,
    WINDFURY_TOTEM = 8512,
    FERAL_SPIRIT = 51533,
    LIGHTNING_BOLT = 188196,
    FLAME_SHOCK = 188389,
    FROST_SHOCK = 196840,
    WINDFURY_WEAPON = 33757,
    FLAMETONGUE_WEAPON = 318038,
    FROSTBRAND_WEAPON = 196834,
    CHAIN_LIGHTNING = 188443,
    MAELSTROM_WEAPON = 187880,
    ELEMENTAL_BLAST = 117014,
    SUNDERING = 197214,
    
    -- Defensive & utility
    ASTRAL_SHIFT = 108271,
    WIND_SHEAR = 57994,
    SPIRITWALKER'S_GRACE = 79206,
    CAPACITOR_TOTEM = 192058,
    EARTHBIND_TOTEM = 2484,
    WIND_RUSH_TOTEM = 192077,
    
    -- Talents
    ASCENDANCE = 114051,
    HOT_HAND = 201900,
    ICE_STRIKE = 342240,
    ELEMENTAL_ASSAULT = 210853,
    HAILSTORM = 334195,
    STORMFLURRY = 344357,
    
    -- Misc
    BLOODLUST = 2825,
    HEROISM = 32182,
    PURGE = 370,
    HEALING_STREAM_TOTEM = 5394,
    GHOST_WOLF = 2645,
    PURIFY_SPIRIT = 77130
}

-- Spell IDs for Restoration Shaman
local RESTORATION_SPELLS = {
    -- Core abilities
    HEALING_WAVE = 77472,
    HEALING_SURGE = 8004,
    RIPTIDE = 61295,
    CHAIN_HEAL = 1064,
    HEALING_RAIN = 73920,
    HEALING_STREAM_TOTEM = 5394,
    HEALING_TIDE_TOTEM = 108280,
    SPIRIT_LINK_TOTEM = 98008,
    MANA_TIDE_TOTEM = 16191,
    EARTH_SHIELD = 974,
    WATER_SHIELD = 52127,
    CLOUDBURST_TOTEM = 157153,
    WELLSPRING = 197995,
    DOWNPOUR = 207778,
    
    -- Defensive & utility
    ASTRAL_SHIFT = 108271,
    WIND_SHEAR = 57994,
    SPIRITWALKER'S_GRACE = 79206,
    CAPACITOR_TOTEM = 192058,
    EARTHBIND_TOTEM = 2484,
    WIND_RUSH_TOTEM = 192077,
    EARTHEN_WALL_TOTEM = 198838,
    
    -- Talents
    ASCENDANCE = 114052,
    UNLEASH_LIFE = 73685,
    DELUGE = 200076,
    TORRENT = 200072,
    HIGH_TIDE = 157154,
    PRIMORDIAL_WAVE = 375982,
    
    -- Misc
    BLOODLUST = 2825,
    HEROISM = 32182,
    PURGE = 370,
    LIGHTNING_BOLT = 188196,
    GHOST_WOLF = 2645,
    PURIFY_SPIRIT = 77130,
    FLAME_SHOCK = 188389,
    LAVA_BURST = 51505
}

-- Important buffs to track
local BUFFS = {
    -- Elemental
    MASTER_OF_THE_ELEMENTS = 260734,
    ICEFURY = 210714,
    SURGE_OF_POWER = 285514,
    ASCENDANCE_ELEMENTAL = 114050,
    STORMKEEPER = 191634,
    SPIRITWALKER'S_GRACE = 79206,
    
    -- Enhancement
    CRASH_LIGHTNING = 187878,
    HOT_HAND = 215785,
    ASCENDANCE_ENHANCEMENT = 114051,
    FERAL_SPIRIT = 51533,
    WINDFURY_TOTEM = 327942,
    FROSTBRAND = 196834,
    MAELSTROM_WEAPON = 344179,
    
    -- Restoration
    RIPTIDE = 61295,
    TIDAL_WAVES = 53390,
    EARTHEN_WALL_TOTEM = 201633,
    HIGH_TIDE = 288675,
    UNLEASH_LIFE = 73685,
    ASCENDANCE_RESTORATION = 114052,
    
    -- Shared
    ASTRAL_SHIFT = 108271,
    GHOST_WOLF = 2645,
    WATER_SHIELD = 52127,
    EARTH_SHIELD = 974
}

-- Important debuffs to track
local DEBUFFS = {
    -- Elemental
    FLAME_SHOCK = 188389,
    FROST_SHOCK = 196840,
    
    -- Enhancement
    FLAME_SHOCK = 188389,
    FROST_SHOCK = 196840,
    
    -- Restoration
    FLAME_SHOCK = 188389
}

-- Initialize the Shaman module
function ShamanModule:Initialize()
    -- Register settings
    self:RegisterSettings()
    
    -- Register events
    self:RegisterEvents()
    
    -- Register rotations
    self:RegisterRotations()
    
    API.PrintDebug("Shaman module initialized")
    return true
end

-- Register settings
function ShamanModule:RegisterSettings()
    ConfigRegistry:RegisterSettings("Shaman", {
        generalSettings = {
            enabled = {
                displayName = "Enable Shaman Module",
                description = "Enable the Shaman module for all specs",
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
            useHeroism = {
                displayName = "Use Heroism/Bloodlust",
                description = "Automatically use Heroism/Bloodlust in combat",
                type = "toggle",
                default = false
            },
            useGhostWolf = {
                displayName = "Use Ghost Wolf",
                description = "Automatically use Ghost Wolf when moving",
                type = "toggle",
                default = true
            },
            usePurge = {
                displayName = "Use Purge",
                description = "Automatically Purge enemy buffs",
                type = "toggle",
                default = true
            },
            astralShiftThreshold = {
                displayName = "Astral Shift Health Threshold",
                description = "Health percentage to use Astral Shift",
                type = "slider",
                min = 10,
                max = 80,
                step = 5,
                default = 50
            }
        },
        elementalSettings = {
            useFireElemental = {
                displayName = "Use Fire Elemental",
                description = "Use Fire Elemental on cooldown",
                type = "toggle",
                default = true
            },
            useEarthElemental = {
                displayName = "Use Earth Elemental",
                description = "Use Earth Elemental for defensive purposes",
                type = "toggle",
                default = true
            },
            useStormElemental = {
                displayName = "Use Storm Elemental",
                description = "Use Storm Elemental if talented",
                type = "toggle",
                default = true
            },
            useAscendance = {
                displayName = "Use Ascendance",
                description = "Use Ascendance on cooldown if talented",
                type = "toggle",
                default = true
            },
            flameShockUptime = {
                displayName = "Flame Shock Uptime",
                description = "Maintain Flame Shock on targets",
                type = "toggle",
                default = true
            },
            useIcefury = {
                displayName = "Use Icefury",
                description = "Use Icefury rotation if talented",
                type = "toggle",
                default = true
            },
            useElementalBlast = {
                displayName = "Use Elemental Blast",
                description = "Use Elemental Blast if talented",
                type = "toggle",
                default = true
            },
            useStormkeeper = {
                displayName = "Use Stormkeeper",
                description = "Use Stormkeeper on cooldown if talented",
                type = "toggle",
                default = true
            },
            usePrimordialWave = {
                displayName = "Use Primordial Wave",
                description = "Use Primordial Wave on cooldown if talented",
                type = "toggle",
                default = true
            },
            useSurgeOfPower = {
                displayName = "Use Surge of Power",
                description = "Use optimal Surge of Power rotation if talented",
                type = "toggle",
                default = true
            },
            useLiquidMagmaTotem = {
                displayName = "Use Liquid Magma Totem",
                description = "Use Liquid Magma Totem for AoE if talented",
                type = "toggle",
                default = true
            },
            poolMaelstrom = {
                displayName = "Pool Maelstrom",
                description = "Pool Maelstrom for burst phases",
                type = "toggle",
                default = false
            },
            maelstromPoolThreshold = {
                displayName = "Maelstrom Pool Threshold",
                description = "Amount of Maelstrom to pool before spending",
                type = "slider",
                min = 60,
                max = 150,
                step = 10,
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
            }
        },
        enhancementSettings = {
            useFeralSpirit = {
                displayName = "Use Feral Spirit",
                description = "Use Feral Spirit on cooldown",
                type = "toggle",
                default = true
            },
            useAscendance = {
                displayName = "Use Ascendance",
                description = "Use Ascendance on cooldown if talented",
                type = "toggle",
                default = true
            },
            useWindfuryTotem = {
                displayName = "Use Windfury Totem",
                description = "Use Windfury Totem to buff party",
                type = "toggle",
                default = true
            },
            flameShockUptime = {
                displayName = "Flame Shock Uptime",
                description = "Maintain Flame Shock on targets",
                type = "toggle",
                default = true
            },
            frostbrandUptime = {
                displayName = "Frostbrand Uptime",
                description = "Maintain Frostbrand uptime if talented",
                type = "toggle",
                default = true
            },
            priorityRotation = {
                displayName = "Priority Rotation Type",
                description = "Prioritize different rotations based on talents",
                type = "dropdown",
                options = {"Standard", "Hot Hand", "Ice Strike", "Elemental Assault"},
                default = "Standard"
            },
            useElementalBlast = {
                displayName = "Use Elemental Blast",
                description = "Use Elemental Blast if talented",
                type = "toggle",
                default = true
            },
            useSundering = {
                displayName = "Use Sundering",
                description = "Use Sundering for AoE if talented",
                type = "toggle",
                default = true
            },
            useChainLightning = {
                displayName = "Use Chain Lightning",
                description = "Use Chain Lightning for AoE with Maelstrom stacks",
                type = "toggle",
                default = true
            },
            useCrashLightning = {
                displayName = "Use Crash Lightning",
                description = "Use Crash Lightning in single target rotation",
                type = "toggle",
                default = true
            },
            maelstromThreshold = {
                displayName = "Maelstrom Weapon Threshold",
                description = "Minimum Maelstrom Weapon stacks to cast spells",
                type = "slider",
                min = 1,
                max = 10,
                step = 1,
                default = 5
            },
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
        restorationSettings = {
            waterShield = {
                displayName = "Use Water Shield",
                description = "Keep Water Shield active",
                type = "toggle",
                default = true
            },
            useHealingStreamTotem = {
                displayName = "Use Healing Stream Totem",
                description = "Use Healing Stream Totem on cooldown",
                type = "toggle",
                default = true
            },
            useCloudburstTotem = {
                displayName = "Use Cloudburst Totem",
                description = "Use Cloudburst Totem if talented",
                type = "toggle",
                default = true
            },
            useSpiritLinkTotem = {
                displayName = "Use Spirit Link Totem",
                description = "Use Spirit Link Totem during high group damage",
                type = "toggle",
                default = true
            },
            useHealingTideTotem = {
                displayName = "Use Healing Tide Totem",
                description = "Use Healing Tide Totem during high group damage",
                type = "toggle",
                default = true
            },
            useEarthenWallTotem = {
                displayName = "Use Earthen Wall Totem",
                description = "Use Earthen Wall Totem to protect group members",
                type = "toggle",
                default = true
            },
            useManaTideTotem = {
                displayName = "Use Mana Tide Totem",
                description = "Use Mana Tide Totem when mana is low",
                type = "toggle",
                default = true
            },
            useAscendance = {
                displayName = "Use Ascendance",
                description = "Use Ascendance during high group damage if talented",
                type = "toggle",
                default = true
            },
            riptideUptime = {
                displayName = "Riptide Uptime",
                description = "Maintain Riptide on party members",
                type = "toggle",
                default = true
            },
            earthShieldTarget = {
                displayName = "Earth Shield Target",
                description = "Who to cast Earth Shield on",
                type = "dropdown",
                options = {"Tank", "Self", "Smart"},
                default = "Tank"
            },
            useDownpour = {
                displayName = "Use Downpour",
                description = "Use Downpour for group healing if talented",
                type = "toggle",
                default = true
            },
            useWellspring = {
                displayName = "Use Wellspring",
                description = "Use Wellspring for group healing if talented",
                type = "toggle",
                default = true
            },
            useUnleashLife = {
                displayName = "Use Unleash Life",
                description = "Use Unleash Life to boost healing if talented",
                type = "toggle",
                default = true
            },
            usePrimordialWave = {
                displayName = "Use Primordial Wave",
                description = "Use Primordial Wave on cooldown if talented",
                type = "toggle",
                default = true
            },
            healingMode = {
                displayName = "Healing Priority",
                description = "Healing style priority",
                type = "dropdown",
                options = {"Efficient", "Quick", "Balanced"},
                default = "Balanced"
            },
            manaSavingThreshold = {
                displayName = "Mana Saving Threshold",
                description = "Mana percentage to start using more efficient heals",
                type = "slider",
                min = 10,
                max = 50,
                step = 5,
                default = 30
            },
            healingTideThreshold = {
                displayName = "Healing Tide Threshold",
                description = "Average group health percentage to use Healing Tide Totem",
                type = "slider",
                min = 10,
                max = 60,
                step = 5,
                default = 40
            },
            ascendanceThreshold = {
                displayName = "Ascendance Threshold",
                description = "Average group health percentage to use Ascendance",
                type = "slider",
                min = 10,
                max = 60,
                step = 5,
                default = 35
            }
        }
    })
    
    -- Add callback for settings changes
    ConfigRegistry:RegisterCallback("Shaman", function(settings)
        self:ApplySettings(settings)
    end)
end

-- Apply settings
function ShamanModule:ApplySettings(settings)
    -- Apply general settings
    isEnabled = settings.generalSettings.enabled
end

-- Register events
function ShamanModule:RegisterEvents()
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
function ShamanModule:OnSpecializationChanged()
    -- Get current spec ID
    playerSpec = API.GetActiveSpecID()
    
    API.PrintDebug("Shaman specialization changed: " .. playerSpec)
    
    -- Ensure correct rotation is registered
    if playerSpec == SPEC_ELEMENTAL then
        self:RegisterElementalRotation()
    elseif playerSpec == SPEC_ENHANCEMENT then
        self:RegisterEnhancementRotation()
    elseif playerSpec == SPEC_RESTORATION then
        self:RegisterRestorationRotation()
    end
end

-- Register rotations
function ShamanModule:RegisterRotations()
    -- Register spec-specific rotations
    self:RegisterElementalRotation()
    self:RegisterEnhancementRotation()
    self:RegisterRestorationRotation()
end

-- Register Elemental rotation
function ShamanModule:RegisterElementalRotation()
    RotationManager:RegisterRotation("ShamanElemental", {
        id = "ShamanElemental",
        name = "Shaman - Elemental",
        class = "SHAMAN",
        spec = SPEC_ELEMENTAL,
        level = 10,
        description = "Elemental Shaman rotation for The War Within Season 2",
        author = "WindrunnerRotations",
        version = "1.0.0",
        rotation = function()
            return self:ElementalRotation()
        end
    })
end

-- Register Enhancement rotation
function ShamanModule:RegisterEnhancementRotation()
    RotationManager:RegisterRotation("ShamanEnhancement", {
        id = "ShamanEnhancement",
        name = "Shaman - Enhancement",
        class = "SHAMAN",
        spec = SPEC_ENHANCEMENT,
        level = 10,
        description = "Enhancement Shaman rotation for The War Within Season 2",
        author = "WindrunnerRotations",
        version = "1.0.0",
        rotation = function()
            return self:EnhancementRotation()
        end
    })
end

-- Register Restoration rotation
function ShamanModule:RegisterRestorationRotation()
    RotationManager:RegisterRotation("ShamanRestoration", {
        id = "ShamanRestoration",
        name = "Shaman - Restoration",
        class = "SHAMAN",
        spec = SPEC_RESTORATION,
        level = 10,
        description = "Restoration Shaman rotation for The War Within Season 2",
        author = "WindrunnerRotations",
        version = "1.0.0",
        rotation = function()
            return self:RestorationRotation()
        end
    })
end

-- Elemental rotation
function ShamanModule:ElementalRotation()
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
    local settings = ConfigRegistry:GetSettings("Shaman")
    
    -- Common Combat Variables
    local health, maxHealth, healthPercent = API.GetUnitHealth(player)
    local targetHealth, targetMaxHealth, targetHealthPercent = API.GetUnitHealth(target)
    local maelstrom = API.GetUnitPower(player, Enum.PowerType.Maelstrom)
    local enemies = API.GetEnemyCount(8)
    local aoeEnabled = settings.elementalSettings.aoeThreshold <= enemies
    
    -- Buff tracking
    local hasMasterOfTheElements = API.UnitHasBuff(player, BUFFS.MASTER_OF_THE_ELEMENTS)
    local hasIcefury = API.UnitHasBuff(player, BUFFS.ICEFURY)
    local hasSurgeOfPower = API.UnitHasBuff(player, BUFFS.SURGE_OF_POWER)
    local hasAscendance = API.UnitHasBuff(player, BUFFS.ASCENDANCE_ELEMENTAL)
    local hasStormkeeper = API.UnitHasBuff(player, BUFFS.STORMKEEPER)
    
    -- Debuff tracking
    local flameShockRemaining = API.GetDebuffRemaining(target, DEBUFFS.FLAME_SHOCK)
    
    -- Spell CD tracking
    local fireElementalCD = API.GetSpellCooldown(ELEMENTAL_SPELLS.FIRE_ELEMENTAL)
    local stormElementalCD = API.GetSpellCooldown(ELEMENTAL_SPELLS.STORM_ELEMENTAL)
    local earthElementalCD = API.GetSpellCooldown(ELEMENTAL_SPELLS.EARTH_ELEMENTAL)
    local ascendanceCD = API.GetSpellCooldown(ELEMENTAL_SPELLS.ASCENDANCE)
    local icefuryCD = API.GetSpellCooldown(ELEMENTAL_SPELLS.ICEFURY)
    local stormkeeperCD = API.GetSpellCooldown(ELEMENTAL_SPELLS.STORMKEEPER)
    
    -- Lava Burst charges
    local lavaBurstCharges, lavaBurstMaxCharges, lavaBurstCooldown = API.GetSpellCharges(ELEMENTAL_SPELLS.LAVA_BURST)
    
    -- Interrupt if needed
    if settings.generalSettings.useInterrupts and
       API.IsSpellKnown(ELEMENTAL_SPELLS.WIND_SHEAR) and 
       API.IsSpellUsable(ELEMENTAL_SPELLS.WIND_SHEAR) and
       API.ShouldInterrupt(target) then
        return {
            type = "spell",
            id = ELEMENTAL_SPELLS.WIND_SHEAR,
            target = target
        }
    end
    
    -- Defensive abilities
    if settings.generalSettings.useDefensives then
        -- Use Astral Shift
        if healthPercent < settings.generalSettings.astralShiftThreshold and
           API.IsSpellKnown(ELEMENTAL_SPELLS.ASTRAL_SHIFT) and 
           API.IsSpellUsable(ELEMENTAL_SPELLS.ASTRAL_SHIFT) then
            return {
                type = "spell",
                id = ELEMENTAL_SPELLS.ASTRAL_SHIFT,
                target = player
            }
        end
        
        -- Use Earth Elemental defensively
        if settings.elementalSettings.useEarthElemental and
           healthPercent < 40 and
           API.IsSpellKnown(ELEMENTAL_SPELLS.EARTH_ELEMENTAL) and 
           API.IsSpellUsable(ELEMENTAL_SPELLS.EARTH_ELEMENTAL) then
            return {
                type = "spell",
                id = ELEMENTAL_SPELLS.EARTH_ELEMENTAL,
                target = player
            }
        end
    end
    
    -- Use Purge on enemies with buffs
    if settings.generalSettings.usePurge and
       API.HasPurgableBuffs(target) and
       API.IsSpellKnown(ELEMENTAL_SPELLS.PURGE) and 
       API.IsSpellUsable(ELEMENTAL_SPELLS.PURGE) then
        return {
            type = "spell",
            id = ELEMENTAL_SPELLS.PURGE,
            target = target
        }
    end
    
    -- Use Heroism/Bloodlust if enabled
    if settings.generalSettings.useHeroism and inCombat and
       not API.HasExhaustionDebuff() and
       (API.IsSpellKnown(ELEMENTAL_SPELLS.BLOODLUST) and API.IsSpellUsable(ELEMENTAL_SPELLS.BLOODLUST)) then
        return {
            type = "spell",
            id = ELEMENTAL_SPELLS.BLOODLUST,
            target = player
        }
    elseif settings.generalSettings.useHeroism and inCombat and
           not API.HasExhaustionDebuff() and
           (API.IsSpellKnown(ELEMENTAL_SPELLS.HEROISM) and API.IsSpellUsable(ELEMENTAL_SPELLS.HEROISM)) then
        return {
            type = "spell",
            id = ELEMENTAL_SPELLS.HEROISM,
            target = player
        }
    end
    
    -- Core rotation
    -- Keep Flame Shock up
    if settings.elementalSettings.flameShockUptime and
       flameShockRemaining < 6 and
       API.IsSpellKnown(ELEMENTAL_SPELLS.FLAME_SHOCK) and 
       API.IsSpellUsable(ELEMENTAL_SPELLS.FLAME_SHOCK) then
        return {
            type = "spell",
            id = ELEMENTAL_SPELLS.FLAME_SHOCK,
            target = target
        }
    end
    
    -- Cooldowns
    if inCombat then
        -- Use Fire/Storm Elemental
        if settings.elementalSettings.useFireElemental and
           API.IsSpellKnown(ELEMENTAL_SPELLS.FIRE_ELEMENTAL) and 
           API.IsSpellUsable(ELEMENTAL_SPELLS.FIRE_ELEMENTAL) and
           not API.IsSpellKnown(ELEMENTAL_SPELLS.STORM_ELEMENTAL) then
            return {
                type = "spell",
                id = ELEMENTAL_SPELLS.FIRE_ELEMENTAL,
                target = player
            }
        end
        
        if settings.elementalSettings.useStormElemental and
           API.IsSpellKnown(ELEMENTAL_SPELLS.STORM_ELEMENTAL) and 
           API.IsSpellUsable(ELEMENTAL_SPELLS.STORM_ELEMENTAL) then
            return {
                type = "spell",
                id = ELEMENTAL_SPELLS.STORM_ELEMENTAL,
                target = player
            }
        end
        
        -- Use Ascendance
        if settings.elementalSettings.useAscendance and
           API.IsSpellKnown(ELEMENTAL_SPELLS.ASCENDANCE) and 
           API.IsSpellUsable(ELEMENTAL_SPELLS.ASCENDANCE) then
            return {
                type = "spell",
                id = ELEMENTAL_SPELLS.ASCENDANCE,
                target = player
            }
        end
        
        -- Use Stormkeeper
        if settings.elementalSettings.useStormkeeper and
           API.IsSpellKnown(ELEMENTAL_SPELLS.STORMKEEPER) and 
           API.IsSpellUsable(ELEMENTAL_SPELLS.STORMKEEPER) then
            return {
                type = "spell",
                id = ELEMENTAL_SPELLS.STORMKEEPER,
                target = player
            }
        end
        
        -- Use Primordial Wave
        if settings.elementalSettings.usePrimordialWave and
           API.IsSpellKnown(ELEMENTAL_SPELLS.PRIMORDIAL_WAVE) and 
           API.IsSpellUsable(ELEMENTAL_SPELLS.PRIMORDIAL_WAVE) then
            return {
                type = "spell",
                id = ELEMENTAL_SPELLS.PRIMORDIAL_WAVE,
                target = target
            }
        end
        
        -- Use Liquid Magma Totem for AoE
        if settings.elementalSettings.useLiquidMagmaTotem and aoeEnabled and
           API.IsSpellKnown(ELEMENTAL_SPELLS.LIQUID_MAGMA_TOTEM) and 
           API.IsSpellUsable(ELEMENTAL_SPELLS.LIQUID_MAGMA_TOTEM) then
            return {
                type = "spell",
                id = ELEMENTAL_SPELLS.LIQUID_MAGMA_TOTEM,
                target = player
            }
        end
    end
    
    -- Use Icefury
    if settings.elementalSettings.useIcefury and
       API.IsSpellKnown(ELEMENTAL_SPELLS.ICEFURY) and 
       API.IsSpellUsable(ELEMENTAL_SPELLS.ICEFURY) and
       not hasIcefury then
        return {
            type = "spell",
            id = ELEMENTAL_SPELLS.ICEFURY,
            target = target
        }
    end
    
    -- Optimal spell usage with Icefury buff
    if hasIcefury and
       API.IsSpellKnown(ELEMENTAL_SPELLS.FROST_SHOCK) and 
       API.IsSpellUsable(ELEMENTAL_SPELLS.FROST_SHOCK) then
        return {
            type = "spell",
            id = ELEMENTAL_SPELLS.FROST_SHOCK,
            target = target
        }
    end
    
    -- Spend Maelstrom for AoE with Earthquake
    if aoeEnabled and
       maelstrom >= 60 and
       API.IsSpellKnown(ELEMENTAL_SPELLS.EARTHQUAKE) and 
       API.IsSpellUsable(ELEMENTAL_SPELLS.EARTHQUAKE) then
        return {
            type = "spell",
            id = ELEMENTAL_SPELLS.EARTHQUAKE,
            target = player
        }
    end
    
    -- Spend Maelstrom for single target with Earth Shock
    if not aoeEnabled and
       (maelstrom >= 60 and not settings.elementalSettings.poolMaelstrom or 
        maelstrom >= settings.elementalSettings.maelstromPoolThreshold) and
       API.IsSpellKnown(ELEMENTAL_SPELLS.EARTH_SHOCK) and 
       API.IsSpellUsable(ELEMENTAL_SPELLS.EARTH_SHOCK) then
        return {
            type = "spell",
            id = ELEMENTAL_SPELLS.EARTH_SHOCK,
            target = target
        }
    end
    
    -- Use Elemental Blast
    if settings.elementalSettings.useElementalBlast and
       API.IsSpellKnown(ELEMENTAL_SPELLS.ELEMENTAL_BLAST) and 
       API.IsSpellUsable(ELEMENTAL_SPELLS.ELEMENTAL_BLAST) then
        return {
            type = "spell",
            id = ELEMENTAL_SPELLS.ELEMENTAL_BLAST,
            target = target
        }
    end
    
    -- Use Lava Burst with Master of Elements or Surge of Power
    if (hasMasterOfTheElements or hasSurgeOfPower) and
       (lavaBurstCharges > 0 or API.CanCastLavaBurstWithoutCooldown()) and
       API.IsSpellKnown(ELEMENTAL_SPELLS.LAVA_BURST) and 
       API.IsSpellUsable(ELEMENTAL_SPELLS.LAVA_BURST) then
        return {
            type = "spell",
            id = ELEMENTAL_SPELLS.LAVA_BURST,
            target = target
        }
    end
    
    -- Use Lightning Bolt with Stormkeeper for single target
    if hasStormkeeper and not aoeEnabled and
       API.IsSpellKnown(ELEMENTAL_SPELLS.LIGHTNING_BOLT) and 
       API.IsSpellUsable(ELEMENTAL_SPELLS.LIGHTNING_BOLT) then
        return {
            type = "spell",
            id = ELEMENTAL_SPELLS.LIGHTNING_BOLT,
            target = target
        }
    end
    
    -- Use Chain Lightning with Stormkeeper for AoE
    if hasStormkeeper and aoeEnabled and
       API.IsSpellKnown(ELEMENTAL_SPELLS.CHAIN_LIGHTNING) and 
       API.IsSpellUsable(ELEMENTAL_SPELLS.CHAIN_LIGHTNING) then
        return {
            type = "spell",
            id = ELEMENTAL_SPELLS.CHAIN_LIGHTNING,
            target = target
        }
    end
    
    -- Use Lava Burst
    if (lavaBurstCharges > 0 or API.CanCastLavaBurstWithoutCooldown()) and
       API.IsSpellKnown(ELEMENTAL_SPELLS.LAVA_BURST) and 
       API.IsSpellUsable(ELEMENTAL_SPELLS.LAVA_BURST) then
        return {
            type = "spell",
            id = ELEMENTAL_SPELLS.LAVA_BURST,
            target = target
        }
    end
    
    -- Use Chain Lightning for AoE
    if aoeEnabled and
       API.IsSpellKnown(ELEMENTAL_SPELLS.CHAIN_LIGHTNING) and 
       API.IsSpellUsable(ELEMENTAL_SPELLS.CHAIN_LIGHTNING) then
        return {
            type = "spell",
            id = ELEMENTAL_SPELLS.CHAIN_LIGHTNING,
            target = target
        }
    end
    
    -- Use Lightning Bolt for single target
    if not aoeEnabled and
       API.IsSpellKnown(ELEMENTAL_SPELLS.LIGHTNING_BOLT) and 
       API.IsSpellUsable(ELEMENTAL_SPELLS.LIGHTNING_BOLT) then
        return {
            type = "spell",
            id = ELEMENTAL_SPELLS.LIGHTNING_BOLT,
            target = target
        }
    end
    
    return nil
end

-- Enhancement rotation
function ShamanModule:EnhancementRotation()
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
    local settings = ConfigRegistry:GetSettings("Shaman")
    
    -- Common Combat Variables
    local health, maxHealth, healthPercent = API.GetUnitHealth(player)
    local targetHealth, targetMaxHealth, targetHealthPercent = API.GetUnitHealth(target)
    local enemies = API.GetEnemyCount(8)
    local aoeEnabled = settings.enhancementSettings.aoeThreshold <= enemies
    
    -- Get maelstrom weapon stacks
    local maelstromWeaponStacks = API.GetBuffStacks(player, BUFFS.MAELSTROM_WEAPON)
    
    -- Check weapon enchants
    local hasWindfuryWeapon = API.HasWeaponEnchant(1, ENHANCEMENT_SPELLS.WINDFURY_WEAPON)
    local hasFlametongueWeapon = API.HasWeaponEnchant(2, ENHANCEMENT_SPELLS.FLAMETONGUE_WEAPON)
    local hasFrostbrandWeapon = API.HasWeaponEnchant(1, ENHANCEMENT_SPELLS.FROSTBRAND_WEAPON)
    
    -- Buff tracking
    local hasHotHand = API.UnitHasBuff(player, BUFFS.HOT_HAND)
    local hasCrashLightning = API.UnitHasBuff(player, BUFFS.CRASH_LIGHTNING)
    local hasAscendance = API.UnitHasBuff(player, BUFFS.ASCENDANCE_ENHANCEMENT)
    local hasFeralSpirit = API.UnitHasBuff(player, BUFFS.FERAL_SPIRIT)
    local hasWindfuryTotem = API.UnitHasBuff(player, BUFFS.WINDFURY_TOTEM)
    local hasFrostbrand = API.UnitHasBuff(player, BUFFS.FROSTBRAND)
    
    -- Debuff tracking
    local flameShockRemaining = API.GetDebuffRemaining(target, DEBUFFS.FLAME_SHOCK)
    local frostShockRemaining = API.GetDebuffRemaining(target, DEBUFFS.FROST_SHOCK)
    
    -- Priority logic based on talents
    local usesHotHand = settings.enhancementSettings.priorityRotation == "Hot Hand"
    local usesIceStrike = settings.enhancementSettings.priorityRotation == "Ice Strike"
    local usesElementalAssault = settings.enhancementSettings.priorityRotation == "Elemental Assault"
    
    -- Interrupt if needed
    if settings.generalSettings.useInterrupts and
       API.IsSpellKnown(ENHANCEMENT_SPELLS.WIND_SHEAR) and 
       API.IsSpellUsable(ENHANCEMENT_SPELLS.WIND_SHEAR) and
       API.ShouldInterrupt(target) then
        return {
            type = "spell",
            id = ENHANCEMENT_SPELLS.WIND_SHEAR,
            target = target
        }
    end
    
    -- Defensive abilities
    if settings.generalSettings.useDefensives then
        -- Use Astral Shift
        if healthPercent < settings.generalSettings.astralShiftThreshold and
           API.IsSpellKnown(ENHANCEMENT_SPELLS.ASTRAL_SHIFT) and 
           API.IsSpellUsable(ENHANCEMENT_SPELLS.ASTRAL_SHIFT) then
            return {
                type = "spell",
                id = ENHANCEMENT_SPELLS.ASTRAL_SHIFT,
                target = player
            }
        end
    end
    
    -- Use Purge on enemies with buffs
    if settings.generalSettings.usePurge and
       API.HasPurgableBuffs(target) and
       API.IsSpellKnown(ENHANCEMENT_SPELLS.PURGE) and 
       API.IsSpellUsable(ENHANCEMENT_SPELLS.PURGE) then
        return {
            type = "spell",
            id = ENHANCEMENT_SPELLS.PURGE,
            target = target
        }
    end
    
    -- Apply weapon enchants if missing
    if not hasWindfuryWeapon and
       API.IsSpellKnown(ENHANCEMENT_SPELLS.WINDFURY_WEAPON) and 
       API.IsSpellUsable(ENHANCEMENT_SPELLS.WINDFURY_WEAPON) then
        return {
            type = "spell",
            id = ENHANCEMENT_SPELLS.WINDFURY_WEAPON,
            target = player
        }
    end
    
    if not hasFlametongueWeapon and
       API.IsSpellKnown(ENHANCEMENT_SPELLS.FLAMETONGUE_WEAPON) and 
       API.IsSpellUsable(ENHANCEMENT_SPELLS.FLAMETONGUE_WEAPON) then
        return {
            type = "spell",
            id = ENHANCEMENT_SPELLS.FLAMETONGUE_WEAPON,
            target = player
        }
    end
    
    if usesIceStrike and not hasFrostbrandWeapon and
       API.IsSpellKnown(ENHANCEMENT_SPELLS.FROSTBRAND_WEAPON) and 
       API.IsSpellUsable(ENHANCEMENT_SPELLS.FROSTBRAND_WEAPON) then
        return {
            type = "spell",
            id = ENHANCEMENT_SPELLS.FROSTBRAND_WEAPON,
            target = player
        }
    end
    
    -- Use Windfury Totem if missing
    if settings.enhancementSettings.useWindfuryTotem and
       not hasWindfuryTotem and
       API.IsSpellKnown(ENHANCEMENT_SPELLS.WINDFURY_TOTEM) and 
       API.IsSpellUsable(ENHANCEMENT_SPELLS.WINDFURY_TOTEM) then
        return {
            type = "spell",
            id = ENHANCEMENT_SPELLS.WINDFURY_TOTEM,
            target = player
        }
    end
    
    -- Use Heroism/Bloodlust if enabled
    if settings.generalSettings.useHeroism and inCombat and
       not API.HasExhaustionDebuff() and
       (API.IsSpellKnown(ENHANCEMENT_SPELLS.BLOODLUST) and API.IsSpellUsable(ENHANCEMENT_SPELLS.BLOODLUST)) then
        return {
            type = "spell",
            id = ENHANCEMENT_SPELLS.BLOODLUST,
            target = player
        }
    elseif settings.generalSettings.useHeroism and inCombat and
           not API.HasExhaustionDebuff() and
           (API.IsSpellKnown(ENHANCEMENT_SPELLS.HEROISM) and API.IsSpellUsable(ENHANCEMENT_SPELLS.HEROISM)) then
        return {
            type = "spell",
            id = ENHANCEMENT_SPELLS.HEROISM,
            target = player
        }
    end
    
    -- Core rotation
    -- Keep Flame Shock up
    if settings.enhancementSettings.flameShockUptime and
       flameShockRemaining < 6 and
       API.IsSpellKnown(ENHANCEMENT_SPELLS.FLAME_SHOCK) and 
       API.IsSpellUsable(ENHANCEMENT_SPELLS.FLAME_SHOCK) then
        return {
            type = "spell",
            id = ENHANCEMENT_SPELLS.FLAME_SHOCK,
            target = target
        }
    end
    
    -- Keep Frostbrand up if using Ice Strike build
    if usesIceStrike and settings.enhancementSettings.frostbrandUptime and
       not hasFrostbrand and
       API.IsSpellKnown(ENHANCEMENT_SPELLS.FROSTBRAND_WEAPON) and 
       API.IsSpellUsable(ENHANCEMENT_SPELLS.FROSTBRAND_WEAPON) then
        return {
            type = "spell",
            id = ENHANCEMENT_SPELLS.FROSTBRAND_WEAPON,
            target = player
        }
    end
    
    -- Cooldowns
    if inCombat then
        -- Use Feral Spirit
        if settings.enhancementSettings.useFeralSpirit and
           API.IsSpellKnown(ENHANCEMENT_SPELLS.FERAL_SPIRIT) and 
           API.IsSpellUsable(ENHANCEMENT_SPELLS.FERAL_SPIRIT) then
            return {
                type = "spell",
                id = ENHANCEMENT_SPELLS.FERAL_SPIRIT,
                target = player
            }
        end
        
        -- Use Ascendance
        if settings.enhancementSettings.useAscendance and
           API.IsSpellKnown(ENHANCEMENT_SPELLS.ASCENDANCE) and 
           API.IsSpellUsable(ENHANCEMENT_SPELLS.ASCENDANCE) then
            return {
                type = "spell",
                id = ENHANCEMENT_SPELLS.ASCENDANCE,
                target = player
            }
        end
        
        -- Use Sundering for AoE
        if settings.enhancementSettings.useSundering and aoeEnabled and
           API.IsSpellKnown(ENHANCEMENT_SPELLS.SUNDERING) and 
           API.IsSpellUsable(ENHANCEMENT_SPELLS.SUNDERING) then
            return {
                type = "spell",
                id = ENHANCEMENT_SPELLS.SUNDERING,
                target = target
            }
        end
    end
    
    -- AoE priority
    if aoeEnabled then
        -- Use Crash Lightning to buff AoE
        if not hasCrashLightning and
           API.IsSpellKnown(ENHANCEMENT_SPELLS.CRASH_LIGHTNING) and 
           API.IsSpellUsable(ENHANCEMENT_SPELLS.CRASH_LIGHTNING) then
            return {
                type = "spell",
                id = ENHANCEMENT_SPELLS.CRASH_LIGHTNING,
                target = target
            }
        end
        
        -- Use Chain Lightning with Maelstrom stacks
        if settings.enhancementSettings.useChainLightning and
           maelstromWeaponStacks >= settings.enhancementSettings.maelstromThreshold and
           API.IsSpellKnown(ENHANCEMENT_SPELLS.CHAIN_LIGHTNING) and 
           API.IsSpellUsable(ENHANCEMENT_SPELLS.CHAIN_LIGHTNING) then
            return {
                type = "spell",
                id = ENHANCEMENT_SPELLS.CHAIN_LIGHTNING,
                target = target
            }
        end
        
        -- Continue with Crash Lightning for AoE
        if API.IsSpellKnown(ENHANCEMENT_SPELLS.CRASH_LIGHTNING) and 
           API.IsSpellUsable(ENHANCEMENT_SPELLS.CRASH_LIGHTNING) then
            return {
                type = "spell",
                id = ENHANCEMENT_SPELLS.CRASH_LIGHTNING,
                target = target
            }
        end
    end
    
    -- Use Elemental Blast if talented
    if settings.enhancementSettings.useElementalBlast and
       maelstromWeaponStacks >= settings.enhancementSettings.maelstromThreshold and
       API.IsSpellKnown(ENHANCEMENT_SPELLS.ELEMENTAL_BLAST) and 
       API.IsSpellUsable(ENHANCEMENT_SPELLS.ELEMENTAL_BLAST) then
        return {
            type = "spell",
            id = ENHANCEMENT_SPELLS.ELEMENTAL_BLAST,
            target = target
        }
    end
    
    -- Ice Strike build priority
    if usesIceStrike then
        -- Use Ice Strike when available
        if API.IsSpellKnown(ENHANCEMENT_SPELLS.ICE_STRIKE) and 
           API.IsSpellUsable(ENHANCEMENT_SPELLS.ICE_STRIKE) then
            return {
                type = "spell",
                id = ENHANCEMENT_SPELLS.ICE_STRIKE,
                target = target
            }
        end
        
        -- Use Frost Shock to maintain debuff
        if frostShockRemaining < 4 and
           API.IsSpellKnown(ENHANCEMENT_SPELLS.FROST_SHOCK) and 
           API.IsSpellUsable(ENHANCEMENT_SPELLS.FROST_SHOCK) then
            return {
                type = "spell",
                id = ENHANCEMENT_SPELLS.FROST_SHOCK,
                target = target
            }
        end
    end
    
    -- Hot Hand build priority
    if usesHotHand and hasHotHand then
        -- Prioritize Lava Lash with Hot Hand proc
        if API.IsSpellKnown(ENHANCEMENT_SPELLS.LAVA_LASH) and 
           API.IsSpellUsable(ENHANCEMENT_SPELLS.LAVA_LASH) then
            return {
                type = "spell",
                id = ENHANCEMENT_SPELLS.LAVA_LASH,
                target = target
            }
        end
    end
    
    -- Standard priority for core rotational abilities
    
    -- Stormstrike
    if API.IsSpellKnown(ENHANCEMENT_SPELLS.STORMSTRIKE) and 
       API.IsSpellUsable(ENHANCEMENT_SPELLS.STORMSTRIKE) then
        return {
            type = "spell",
            id = ENHANCEMENT_SPELLS.STORMSTRIKE,
            target = target
        }
    end
    
    -- Lava Lash
    if API.IsSpellKnown(ENHANCEMENT_SPELLS.LAVA_LASH) and 
       API.IsSpellUsable(ENHANCEMENT_SPELLS.LAVA_LASH) then
        return {
            type = "spell",
            id = ENHANCEMENT_SPELLS.LAVA_LASH,
            target = target
        }
    end
    
    -- Crash Lightning in single target if enabled
    if not aoeEnabled and settings.enhancementSettings.useCrashLightning and
       API.IsSpellKnown(ENHANCEMENT_SPELLS.CRASH_LIGHTNING) and 
       API.IsSpellUsable(ENHANCEMENT_SPELLS.CRASH_LIGHTNING) then
        return {
            type = "spell",
            id = ENHANCEMENT_SPELLS.CRASH_LIGHTNING,
            target = target
        }
    end
    
    -- Lightning Bolt with Maelstrom stacks if nothing else is available
    if maelstromWeaponStacks >= settings.enhancementSettings.maelstromThreshold and
       API.IsSpellKnown(ENHANCEMENT_SPELLS.LIGHTNING_BOLT) and 
       API.IsSpellUsable(ENHANCEMENT_SPELLS.LIGHTNING_BOLT) then
        return {
            type = "spell",
            id = ENHANCEMENT_SPELLS.LIGHTNING_BOLT,
            target = target
        }
    end
    
    -- Frost Shock filler
    if API.IsSpellKnown(ENHANCEMENT_SPELLS.FROST_SHOCK) and 
       API.IsSpellUsable(ENHANCEMENT_SPELLS.FROST_SHOCK) then
        return {
            type = "spell",
            id = ENHANCEMENT_SPELLS.FROST_SHOCK,
            target = target
        }
    end
    
    return nil
end

-- Restoration rotation
function ShamanModule:RestorationRotation()
    -- Check if we should execute
    if not self:ShouldExecuteRotation() then
        return nil
    end
    
    -- Get player and target
    local player = "player"
    local target = "target"
    local lowestAlly = self:GetLowestHealthAlly()
    
    -- Get settings
    local settings = ConfigRegistry:GetSettings("Shaman")
    
    -- Common Combat Variables
    local health, maxHealth, healthPercent = API.GetUnitHealth(player)
    local mana, maxMana, manaPercent = API.GetUnitPower(player, Enum.PowerType.Mana)
    local injuredAllies = self:GetInjuredAlliesCount(80)
    local averageGroupHealth = self:GetAverageGroupHealth()
    
    -- Target specific variables
    local lowestAllyHealth, lowestAllyMaxHealth, lowestAllyHealthPercent = 100, 100, 100
    
    if lowestAlly and UnitExists(lowestAlly) then
        lowestAllyHealth, lowestAllyMaxHealth, lowestAllyHealthPercent = API.GetUnitHealth(lowestAlly)
    end
    
    -- Buff tracking
    local hasWaterShield = API.UnitHasBuff(player, BUFFS.WATER_SHIELD)
    local hasTidalWaves = API.UnitHasBuff(player, BUFFS.TIDAL_WAVES)
    local hasUnleashLife = API.UnitHasBuff(player, BUFFS.UNLEASH_LIFE)
    
    -- Riptide and Earth Shield tracking
    local targetWithRiptide = self:GetAlliesWithBuff(BUFFS.RIPTIDE)
    local targetWithEarthShield = self:GetAlliesWithBuff(BUFFS.EARTH_SHIELD)
    
    -- CD tracking
    local cloudburstTotemCD = API.GetSpellCooldown(RESTORATION_SPELLS.CLOUDBURST_TOTEM)
    local healingTideTotemCD = API.GetSpellCooldown(RESTORATION_SPELLS.HEALING_TIDE_TOTEM)
    local spiritLinkTotemCD = API.GetSpellCooldown(RESTORATION_SPELLS.SPIRIT_LINK_TOTEM)
    local manaTideTotemCD = API.GetSpellCooldown(RESTORATION_SPELLS.MANA_TIDE_TOTEM)
    local ascendanceCD = API.GetSpellCooldown(RESTORATION_SPELLS.ASCENDANCE)
    
    -- Totem tracking
    local hasHealingStreamTotem = API.HasActiveTotem(RESTORATION_SPELLS.HEALING_STREAM_TOTEM)
    local hasCloudburstTotem = API.HasActiveTotem(RESTORATION_SPELLS.CLOUDBURST_TOTEM)
    local hasEarthenWallTotem = API.HasActiveTotem(RESTORATION_SPELLS.EARTHEN_WALL_TOTEM)
    
    -- Interrupt if needed and we have a hostile target
    if UnitExists(target) and UnitCanAttack(player, target) and not UnitIsDead(target) and
       settings.generalSettings.useInterrupts and
       API.IsSpellKnown(RESTORATION_SPELLS.WIND_SHEAR) and 
       API.IsSpellUsable(RESTORATION_SPELLS.WIND_SHEAR) and
       API.ShouldInterrupt(target) then
        return {
            type = "spell",
            id = RESTORATION_SPELLS.WIND_SHEAR,
            target = target
        }
    end
    
    -- Defensive abilities
    if settings.generalSettings.useDefensives then
        -- Use Astral Shift
        if healthPercent < settings.generalSettings.astralShiftThreshold and
           API.IsSpellKnown(RESTORATION_SPELLS.ASTRAL_SHIFT) and 
           API.IsSpellUsable(RESTORATION_SPELLS.ASTRAL_SHIFT) then
            return {
                type = "spell",
                id = RESTORATION_SPELLS.ASTRAL_SHIFT,
                target = player
            }
        end
    end
    
    -- Use Purge on enemies with buffs if we have a hostile target
    if UnitExists(target) and UnitCanAttack(player, target) and not UnitIsDead(target) and
       settings.generalSettings.usePurge and
       API.HasPurgableBuffs(target) and
       API.IsSpellKnown(RESTORATION_SPELLS.PURGE) and 
       API.IsSpellUsable(RESTORATION_SPELLS.PURGE) then
        return {
            type = "spell",
            id = RESTORATION_SPELLS.PURGE,
            target = target
        }
    end
    
    -- Apply Water Shield if missing
    if settings.restorationSettings.waterShield and
       not hasWaterShield and
       API.IsSpellKnown(RESTORATION_SPELLS.WATER_SHIELD) and 
       API.IsSpellUsable(RESTORATION_SPELLS.WATER_SHIELD) then
        return {
            type = "spell",
            id = RESTORATION_SPELLS.WATER_SHIELD,
            target = player
        }
    end
    
    -- Apply Earth Shield to appropriate target if missing
    if #targetWithEarthShield == 0 and
       API.IsSpellKnown(RESTORATION_SPELLS.EARTH_SHIELD) and 
       API.IsSpellUsable(RESTORATION_SPELLS.EARTH_SHIELD) then
        local earthShieldTarget = self:GetEarthShieldTarget(settings.restorationSettings.earthShieldTarget)
        if earthShieldTarget then
            return {
                type = "spell",
                id = RESTORATION_SPELLS.EARTH_SHIELD,
                target = earthShieldTarget
            }
        end
    end
    
    -- Use Heroism/Bloodlust if enabled
    if settings.generalSettings.useHeroism and inCombat and
       not API.HasExhaustionDebuff() and
       (API.IsSpellKnown(RESTORATION_SPELLS.BLOODLUST) and API.IsSpellUsable(RESTORATION_SPELLS.BLOODLUST)) then
        return {
            type = "spell",
            id = RESTORATION_SPELLS.BLOODLUST,
            target = player
        }
    elseif settings.generalSettings.useHeroism and inCombat and
           not API.HasExhaustionDebuff() and
           (API.IsSpellKnown(RESTORATION_SPELLS.HEROISM) and API.IsSpellUsable(RESTORATION_SPELLS.HEROISM)) then
        return {
            type = "spell",
            id = RESTORATION_SPELLS.HEROISM,
            target = player
        }
    end
    
    -- Emergency cooldowns
    if inCombat then
        -- Healing Tide Totem for group healing
        if settings.restorationSettings.useHealingTideTotem and
           averageGroupHealth <= settings.restorationSettings.healingTideThreshold and
           API.IsSpellKnown(RESTORATION_SPELLS.HEALING_TIDE_TOTEM) and 
           API.IsSpellUsable(RESTORATION_SPELLS.HEALING_TIDE_TOTEM) then
            return {
                type = "spell",
                id = RESTORATION_SPELLS.HEALING_TIDE_TOTEM,
                target = player
            }
        end
        
        -- Spirit Link Totem for group damage redistribution
        if settings.restorationSettings.useSpiritLinkTotem and
           averageGroupHealth < 60 and injuredAllies >= 3 and
           API.IsSpellKnown(RESTORATION_SPELLS.SPIRIT_LINK_TOTEM) and 
           API.IsSpellUsable(RESTORATION_SPELLS.SPIRIT_LINK_TOTEM) then
            return {
                type = "spell",
                id = RESTORATION_SPELLS.SPIRIT_LINK_TOTEM,
                target = player
            }
        end
        
        -- Ascendance for burst healing
        if settings.restorationSettings.useAscendance and
           averageGroupHealth <= settings.restorationSettings.ascendanceThreshold and
           API.IsSpellKnown(RESTORATION_SPELLS.ASCENDANCE) and 
           API.IsSpellUsable(RESTORATION_SPELLS.ASCENDANCE) then
            return {
                type = "spell",
                id = RESTORATION_SPELLS.ASCENDANCE,
                target = player
            }
        end
        
        -- Mana Tide Totem when low on mana
        if settings.restorationSettings.useManaTideTotem and
           manaPercent <= settings.restorationSettings.manaSavingThreshold and
           API.IsSpellKnown(RESTORATION_SPELLS.MANA_TIDE_TOTEM) and 
           API.IsSpellUsable(RESTORATION_SPELLS.MANA_TIDE_TOTEM) then
            return {
                type = "spell",
                id = RESTORATION_SPELLS.MANA_TIDE_TOTEM,
                target = player
            }
        end
        
        -- Earthen Wall Totem for damage reduction
        if settings.restorationSettings.useEarthenWallTotem and
           not hasEarthenWallTotem and
           (lowestAllyHealthPercent < 50 or averageGroupHealth < 70) and
           API.IsSpellKnown(RESTORATION_SPELLS.EARTHEN_WALL_TOTEM) and 
           API.IsSpellUsable(RESTORATION_SPELLS.EARTHEN_WALL_TOTEM) then
            return {
                type = "spell",
                id = RESTORATION_SPELLS.EARTHEN_WALL_TOTEM,
                target = player
            }
        end
    end
    
    -- Maintain totems
    -- Healing Stream Totem
    if settings.restorationSettings.useHealingStreamTotem and
       not hasHealingStreamTotem and
       API.IsSpellKnown(RESTORATION_SPELLS.HEALING_STREAM_TOTEM) and 
       API.IsSpellUsable(RESTORATION_SPELLS.HEALING_STREAM_TOTEM) then
        return {
            type = "spell",
            id = RESTORATION_SPELLS.HEALING_STREAM_TOTEM,
            target = player
        }
    end
    
    -- Cloudburst Totem
    if settings.restorationSettings.useCloudburstTotem and
       not hasCloudburstTotem and
       API.IsSpellKnown(RESTORATION_SPELLS.CLOUDBURST_TOTEM) and 
       API.IsSpellUsable(RESTORATION_SPELLS.CLOUDBURST_TOTEM) then
        return {
            type = "spell",
            id = RESTORATION_SPELLS.CLOUDBURST_TOTEM,
            target = player
        }
    end
    
    -- Group healing abilities
    -- Unleash Life to buff healing
    if settings.restorationSettings.useUnleashLife and
       lowestAlly and lowestAllyHealthPercent < 80 and
       API.IsSpellKnown(RESTORATION_SPELLS.UNLEASH_LIFE) and 
       API.IsSpellUsable(RESTORATION_SPELLS.UNLEASH_LIFE) then
        return {
            type = "spell",
            id = RESTORATION_SPELLS.UNLEASH_LIFE,
            target = lowestAlly
        }
    end
    
    -- Primordial Wave
    if settings.restorationSettings.usePrimordialWave and
       lowestAlly and lowestAllyHealthPercent < 75 and
       API.IsSpellKnown(RESTORATION_SPELLS.PRIMORDIAL_WAVE) and 
       API.IsSpellUsable(RESTORATION_SPELLS.PRIMORDIAL_WAVE) then
        return {
            type = "spell",
            id = RESTORATION_SPELLS.PRIMORDIAL_WAVE,
            target = lowestAlly
        }
    end
    
    -- Healing Rain for group healing
    if injuredAllies >= 3 and
       API.IsSpellKnown(RESTORATION_SPELLS.HEALING_RAIN) and 
       API.IsSpellUsable(RESTORATION_SPELLS.HEALING_RAIN) then
        return {
            type = "spell",
            id = RESTORATION_SPELLS.HEALING_RAIN,
            target = player
        }
    end
    
    -- Wellspring for directional group healing
    if settings.restorationSettings.useWellspring and
       injuredAllies >= 3 and
       API.IsSpellKnown(RESTORATION_SPELLS.WELLSPRING) and 
       API.IsSpellUsable(RESTORATION_SPELLS.WELLSPRING) then
        return {
            type = "spell",
            id = RESTORATION_SPELLS.WELLSPRING,
            target = player
        }
    end
    
    -- Downpour for targeted group healing
    if settings.restorationSettings.useDownpour and
       injuredAllies >= 3 and
       API.IsSpellKnown(RESTORATION_SPELLS.DOWNPOUR) and 
       API.IsSpellUsable(RESTORATION_SPELLS.DOWNPOUR) then
        return {
            type = "spell",
            id = RESTORATION_SPELLS.DOWNPOUR,
            target = player
        }
    end
    
    -- Maintain Riptide on targets
    if settings.restorationSettings.riptideUptime and
       #targetWithRiptide < 3 and
       API.IsSpellKnown(RESTORATION_SPELLS.RIPTIDE) and 
       API.IsSpellUsable(RESTORATION_SPELLS.RIPTIDE) then
        local riptideTarget = self:GetRiptideTarget()
        if riptideTarget then
            return {
                type = "spell",
                id = RESTORATION_SPELLS.RIPTIDE,
                target = riptideTarget
            }
        end
    end
    
    -- Direct healing based on priority
    if lowestAlly then
        -- Use Chain Heal for group healing
        if injuredAllies >= 3 and
           API.IsSpellKnown(RESTORATION_SPELLS.CHAIN_HEAL) and 
           API.IsSpellUsable(RESTORATION_SPELLS.CHAIN_HEAL) then
            return {
                type = "spell",
                id = RESTORATION_SPELLS.CHAIN_HEAL,
                target = lowestAlly
            }
        end
        
        -- Healing Surge for emergency healing
        if lowestAllyHealthPercent < 40 and
           (hasTidalWaves or hasUnleashLife) and
           API.IsSpellKnown(RESTORATION_SPELLS.HEALING_SURGE) and 
           API.IsSpellUsable(RESTORATION_SPELLS.HEALING_SURGE) then
            return {
                type = "spell",
                id = RESTORATION_SPELLS.HEALING_SURGE,
                target = lowestAlly
            }
        end
        
        -- Healing Wave for efficient healing with Tidal Waves
        if hasTidalWaves and
           (lowestAllyHealthPercent < 85 or settings.restorationSettings.healingMode == "Efficient") and
           API.IsSpellKnown(RESTORATION_SPELLS.HEALING_WAVE) and 
           API.IsSpellUsable(RESTORATION_SPELLS.HEALING_WAVE) then
            return {
                type = "spell",
                id = RESTORATION_SPELLS.HEALING_WAVE,
                target = lowestAlly
            }
        end
        
        -- Healing Surge for quick healing
        if lowestAllyHealthPercent < 60 or settings.restorationSettings.healingMode == "Quick" and
           API.IsSpellKnown(RESTORATION_SPELLS.HEALING_SURGE) and 
           API.IsSpellUsable(RESTORATION_SPELLS.HEALING_SURGE) then
            return {
                type = "spell",
                id = RESTORATION_SPELLS.HEALING_SURGE,
                target = lowestAlly
            }
        end
        
        -- Healing Wave as a filler
        if lowestAllyHealthPercent < 95 and
           API.IsSpellKnown(RESTORATION_SPELLS.HEALING_WAVE) and 
           API.IsSpellUsable(RESTORATION_SPELLS.HEALING_WAVE) then
            return {
                type = "spell",
                id = RESTORATION_SPELLS.HEALING_WAVE,
                target = lowestAlly
            }
        end
    end
    
    -- DPS if everything is fine
    if UnitExists(target) and UnitCanAttack(player, target) and not UnitIsDead(target) and 
       (not lowestAlly or lowestAllyHealthPercent > 90) then
        
        -- Flame Shock for DPS
        if API.IsSpellKnown(RESTORATION_SPELLS.FLAME_SHOCK) and 
           API.IsSpellUsable(RESTORATION_SPELLS.FLAME_SHOCK) and
           API.GetDebuffRemaining(target, DEBUFFS.FLAME_SHOCK) < 3 then
            return {
                type = "spell",
                id = RESTORATION_SPELLS.FLAME_SHOCK,
                target = target
            }
        end
        
        -- Lava Burst if Flame Shock is up
        if API.IsSpellKnown(RESTORATION_SPELLS.LAVA_BURST) and 
           API.IsSpellUsable(RESTORATION_SPELLS.LAVA_BURST) and
           API.UnitHasDebuff(target, DEBUFFS.FLAME_SHOCK) then
            return {
                type = "spell",
                id = RESTORATION_SPELLS.LAVA_BURST,
                target = target
            }
        end
        
        -- Lightning Bolt as filler
        if API.IsSpellKnown(RESTORATION_SPELLS.LIGHTNING_BOLT) and 
           API.IsSpellUsable(RESTORATION_SPELLS.LIGHTNING_BOLT) then
            return {
                type = "spell",
                id = RESTORATION_SPELLS.LIGHTNING_BOLT,
                target = target
            }
        end
    end
    
    return nil
end

-- Get lowest health ally
function ShamanModule:GetLowestHealthAlly()
    local lowestUnit = nil
    local lowestHealth = 100
    
    -- Check party members
    for i = 1, 4 do
        local unit = "party" .. i
        if UnitExists(unit) and not UnitIsDead(unit) then
            local health, maxHealth, healthPercent = API.GetUnitHealth(unit)
            if healthPercent < lowestHealth then
                lowestHealth = healthPercent
                lowestUnit = unit
            end
        end
    end
    
    -- Check player
    local playerHealth, playerMaxHealth, playerHealthPercent = API.GetUnitHealth("player")
    if playerHealthPercent < lowestHealth then
        lowestHealth = playerHealthPercent
        lowestUnit = "player"
    end
    
    return lowestUnit
end

-- Get injured allies count
function ShamanModule:GetInjuredAlliesCount(threshold)
    local count = 0
    
    for i = 1, 4 do
        local unit = "party" .. i
        if UnitExists(unit) and not UnitIsDead(unit) then
            local health, maxHealth, healthPercent = API.GetUnitHealth(unit)
            if healthPercent < threshold then
                count = count + 1
            end
        end
    end
    
    -- Include player
    local playerHealth, playerMaxHealth, playerHealthPercent = API.GetUnitHealth("player")
    if playerHealthPercent < threshold then
        count = count + 1
    end
    
    return count
end

-- Get average group health
function ShamanModule:GetAverageGroupHealth()
    local totalHealth = 0
    local count = 0
    
    for i = 1, 4 do
        local unit = "party" .. i
        if UnitExists(unit) and not UnitIsDead(unit) then
            local health, maxHealth, healthPercent = API.GetUnitHealth(unit)
            totalHealth = totalHealth + healthPercent
            count = count + 1
        end
    end
    
    -- Include player
    local playerHealth, playerMaxHealth, playerHealthPercent = API.GetUnitHealth("player")
    totalHealth = totalHealth + playerHealthPercent
    count = count + 1
    
    return count > 0 and (totalHealth / count) or 100
end

-- Get Earth Shield target
function ShamanModule:GetEarthShieldTarget(strategy)
    if strategy == "Tank" then
        -- Find a tank in the party
        for i = 1, 4 do
            local unit = "party" .. i
            if UnitExists(unit) and not UnitIsDead(unit) and API.UnitIsTank(unit) then
                return unit
            end
        end
        -- No tank found, return nil
        return nil
    elseif strategy == "Self" then
        return "player"
    elseif strategy == "Smart" then
        -- Try to find tank first, then fallback to lowest health
        for i = 1, 4 do
            local unit = "party" .. i
            if UnitExists(unit) and not UnitIsDead(unit) and API.UnitIsTank(unit) then
                return unit
            end
        end
        return self:GetLowestHealthAlly()
    end
    
    -- Default to player if no valid target found
    return "player"
end

-- Get allies with a specific buff
function ShamanModule:GetAlliesWithBuff(buffID)
    local units = {}
    
    -- Check party members
    for i = 1, 4 do
        local unit = "party" .. i
        if UnitExists(unit) and not UnitIsDead(unit) and API.UnitHasBuff(unit, buffID) then
            table.insert(units, unit)
        end
    end
    
    -- Check player
    if API.UnitHasBuff("player", buffID) then
        table.insert(units, "player")
    end
    
    return units
end

-- Get best target for Riptide
function ShamanModule:GetRiptideTarget()
    -- Check party members first (prioritize them)
    for i = 1, 4 do
        local unit = "party" .. i
        if UnitExists(unit) and not UnitIsDead(unit) and not API.UnitHasBuff(unit, BUFFS.RIPTIDE) then
            return unit
        end
    end
    
    -- Check player as a last resort
    if not API.UnitHasBuff("player", BUFFS.RIPTIDE) then
        return "player"
    end
    
    -- All targets have Riptide already, return nil
    return nil
end

-- Helper functions
-- Check if we can cast Lava Burst without cooldown due to Flame Shock being active
function API.CanCastLavaBurstWithoutCooldown()
    -- In a real implementation, this would check if the target has Flame Shock
    -- and if the Lava Surge proc is active
    return false
end

-- Check if a unit has purgable buffs
function API.HasPurgableBuffs(unit)
    -- In a real implementation, this would check for dispellable buffs
    return false
end

-- Check if player has an exhaustion debuff (from Bloodlust/Heroism)
function API.HasExhaustionDebuff()
    -- In a real implementation, this would check for the exhaustion debuff
    return false
end

-- Check if a specific totem is active
function API.HasActiveTotem(totemSpellID)
    -- In a real implementation, this would check for active totems
    return false
end

-- Check if unit is a tank
function API.UnitIsTank(unit)
    -- In a real implementation, this would check the unit's role
    -- For our mock implementation, we'll just check the role
    return UnitGroupRolesAssigned(unit) == "TANK"
end

-- Check if unit has a weapon enchant
function API.HasWeaponEnchant(weaponSlot, enchantSpellID)
    -- In a real implementation, this would check for weapon enchants
    return false
end

-- Should execute rotation
function ShamanModule:ShouldExecuteRotation()
    if not isEnabled then
        return false
    end
    
    -- Check if player matches class
    local playerInfo = API.GetPlayerInfo()
    if playerInfo.class ~= "SHAMAN" then
        return false
    end
    
    return true
end

-- Replace ' with _
function ShamanModule:FixSpellNames()
    ELEMENTAL_SPELLS.SPIRITWALKERS_GRACE = ELEMENTAL_SPELLS["SPIRITWALKER'S_GRACE"]
    ELEMENTAL_SPELLS["SPIRITWALKER'S_GRACE"] = nil
    
    ENHANCEMENT_SPELLS.SPIRITWALKERS_GRACE = ENHANCEMENT_SPELLS["SPIRITWALKER'S_GRACE"]
    ENHANCEMENT_SPELLS["SPIRITWALKER'S_GRACE"] = nil
    
    RESTORATION_SPELLS.SPIRITWALKERS_GRACE = RESTORATION_SPELLS["SPIRITWALKER'S_GRACE"]
    RESTORATION_SPELLS["SPIRITWALKER'S_GRACE"] = nil
    
    BUFFS.SPIRITWALKERS_GRACE = BUFFS["SPIRITWALKER'S_GRACE"]
    BUFFS["SPIRITWALKER'S_GRACE"] = nil
end

-- Fix spell names during initialization
ShamanModule:FixSpellNames()

-- Register for export
WR.Shaman = ShamanModule

return ShamanModule