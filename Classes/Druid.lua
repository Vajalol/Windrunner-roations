------------------------------------------
-- WindrunnerRotations - Druid Class Module
-- Author: VortexQ8
-- The War Within Season 2
------------------------------------------

local addonName, WR = ...
local DruidModule = {}
WR.Druid = DruidModule

-- Dependencies
local API = WR.API
local ConfigRegistry = WR.ConfigRegistry
local RotationManager = WR.RotationManager
local ErrorHandler = WR.ErrorHandler
local CombatAnalysis = WR.CombatAnalysis
local AntiDetectionSystem = WR.AntiDetectionSystem
local PvPManager = WR.PvPManager

-- Druid constants
local CLASS_ID = 11 -- Druid class ID
local SPEC_BALANCE = 102
local SPEC_FERAL = 103
local SPEC_GUARDIAN = 104
local SPEC_RESTORATION = 105

-- Current player data
local playerSpec = 0
local isEnabled = true
local inCombat = false

-- Spell IDs for Balance Druid (The War Within, Season 2)
local BALANCE_SPELLS = {
    -- Core abilities
    MOONFIRE = 8921,
    SUNFIRE = 93402,
    STARSURGE = 78674,
    STARFALL = 191034,
    WRATH = 190984,
    STARFIRE = 194153,
    CELESTIAL_ALIGNMENT = 194223,
    INCARNATION_CHOSEN_OF_ELUNE = 102560,
    SOLAR_BEAM = 78675,
    
    -- Defensive & utility
    BARKSKIN = 22812,
    RENEWAL = 108238,
    WILD_CHARGE = 102401,
    TYPHOON = 132469,
    MIGHTY_BASH = 5211,
    MASS_ENTANGLEMENT = 102359,
    CYCLONE = 33786,
    INNERVATE = 29166,
    REBIRTH = 20484,
    
    -- Talents
    STELLAR_FLARE = 202347,
    FURY_OF_ELUNE = 202770,
    NEW_MOON = 202767,
    HALF_MOON = 202768,
    FULL_MOON = 202771,
    FORCE_OF_NATURE = 205636,
    NATURES_BALANCE = 202430,
    WARRIOR_OF_ELUNE = 202425,
    SOUL_OF_THE_FOREST = 114107,
    
    -- Forms
    MOONKIN_FORM = 24858,
    TRAVEL_FORM = 783,
    CAT_FORM = 768,
    BEAR_FORM = 5487,
    AQUATIC_FORM = 1066,
    FLIGHT_FORM = 165962,
    
    -- Misc
    SHADOWMELD = 58984,
    REGROWTH = 8936,
    MARK_OF_THE_WILD = 1126,
    HIBERNATE = 2637,
    SOOTHE = 2908
}

-- Spell IDs for Feral Druid
local FERAL_SPELLS = {
    -- Core abilities
    RAKE = 1822,
    RIP = 1079,
    FEROCIOUS_BITE = 22568,
    SHRED = 5221,
    SWIPE = 213764,
    THRASH = 106830,
    TIGERS_FURY = 5217,
    BERSERK = 106951,
    INCARNATION_KING_OF_THE_JUNGLE = 102543,
    
    -- Defensive & utility
    SURVIVAL_INSTINCTS = 61336,
    REGROWTH = 8936,
    DASH = 1850,
    WILD_CHARGE = 102401,
    SKULL_BASH = 106839,
    MAIM = 22570,
    REBIRTH = 20484,
    
    -- Talents
    BLOODTALONS = 145152,
    SAVAGE_ROAR = 52610,
    BRUTAL_SLASH = 202028,
    LUNAR_INSPIRATION = 155580,
    SOUL_OF_THE_FOREST = 158476,
    MOMENT_OF_CLARITY = 236068,
    PRIMAL_WRATH = 285381,
    FERAL_FRENZY = 274837,
    
    -- Forms
    CAT_FORM = 768,
    BEAR_FORM = 5487,
    TRAVEL_FORM = 783,
    MOONKIN_FORM = 197625,
    AQUATIC_FORM = 1066,
    FLIGHT_FORM = 165962,
    
    -- Misc
    SHADOWMELD = 58984,
    PROWL = 5215,
    ENTANGLING_ROOTS = 339,
    MARK_OF_THE_WILD = 1126,
    SOOTHE = 2908
}

-- Spell IDs for Guardian Druid
local GUARDIAN_SPELLS = {
    -- Core abilities
    THRASH = 77758,
    MANGLE = 33917,
    SWIPE = 213771,
    MAUL = 6807,
    IRONFUR = 192081,
    FRENZIED_REGENERATION = 22842,
    BARKSKIN = 22812,
    SURVIVAL_INSTINCTS = 61336,
    BERSERK = 50334,
    INCARNATION_GUARDIAN_OF_URSOC = 102558,
    
    -- Defensive & utility
    INCAPACITATING_ROAR = 99,
    WILD_CHARGE = 102401,
    SKULL_BASH = 106839,
    REBIRTH = 20484,
    
    -- Talents
    PULVERIZE = 80313,
    BRISTLING_FUR = 155835,
    GALACTIC_GUARDIAN = 203964,
    SOUL_OF_THE_FOREST = 158477,
    GUARDIAN_OF_ELUNE = 155578,
    EARTHWARDEN = 203974,
    SURVIVAL_OF_THE_FITTEST = 203965,
    REND_AND_TEAR = 204053,
    
    -- Forms
    BEAR_FORM = 5487,
    CAT_FORM = 768,
    TRAVEL_FORM = 783,
    MOONKIN_FORM = 197625,
    AQUATIC_FORM = 1066,
    FLIGHT_FORM = 165962,
    
    -- Misc
    SHADOWMELD = 58984,
    GROWL = 6795,
    ENTANGLING_ROOTS = 339,
    MARK_OF_THE_WILD = 1126,
    SOOTHE = 2908
}

-- Spell IDs for Restoration Druid
local RESTORATION_SPELLS = {
    -- Core abilities
    REJUVENATION = 774,
    REGROWTH = 8936,
    WILD_GROWTH = 48438,
    LIFEBLOOM = 33763,
    SWIFTMEND = 18562,
    EFFLORESCENCE = 145205,
    TRANQUILITY = 740,
    IRONBARK = 102342,
    FLOURISH = 197721,
    
    -- Defensive & utility
    BARKSKIN = 22812,
    INNERVATE = 29166,
    WILD_CHARGE = 102401,
    NATURE'S_CURE = 88423,
    REBIRTH = 20484,
    
    -- Talents
    CULTIVATION = 200390,
    CENARION_WARD = 102351,
    TREE_OF_LIFE = 33891,
    GERMINATION = 155675,
    SPRING_BLOSSOMS = 207385,
    PHOTOSYNTHESIS = 274902,
    SOUL_OF_THE_FOREST = 158478,
    INCARNATION_TREE_OF_LIFE = 33891,
    
    -- Forms
    BEAR_FORM = 5487,
    CAT_FORM = 768,
    TRAVEL_FORM = 783,
    MOONKIN_FORM = 197625,
    AQUATIC_FORM = 1066,
    FLIGHT_FORM = 165962,
    
    -- Misc
    SHADOWMELD = 58984,
    ENTANGLING_ROOTS = 339,
    MARK_OF_THE_WILD = 1126,
    SOOTHE = 2908
}

-- Important buffs to track
local BUFFS = {
    MOONKIN_FORM = 24858,
    ECLIPSE_SOLAR = 48517,
    ECLIPSE_LUNAR = 48518,
    STARLORD = 279709,
    CELESTIAL_ALIGNMENT = 194223,
    INCARNATION_CHOSEN_OF_ELUNE = 102560,
    WARRIOR_OF_ELUNE = 202425,
    OWLKIN_FRENZY = 157228,
    
    CAT_FORM = 768,
    PROWL = 5215,
    PREDATORY_SWIFTNESS = 69369,
    TIGERS_FURY = 5217,
    SAVAGE_ROAR = 52610,
    BERSERK = 106951,
    INCARNATION_KING_OF_THE_JUNGLE = 102543,
    BLOODTALONS = 145152,
    CLEARCASTING = 135700,
    
    BEAR_FORM = 5487,
    IRONFUR = 192081,
    FRENZIED_REGENERATION = 22842,
    BARKSKIN = 22812,
    SURVIVAL_INSTINCTS = 61336,
    GORE = 93622,
    GALACTIC_GUARDIAN = 213708,
    GUARDIAN_OF_ELUNE = 213680,
    INCARNATION_GUARDIAN_OF_URSOC = 102558,
    
    REJUVENATION = 774,
    GERMINATION = 155777,
    LIFEBLOOM = 33763,
    REGROWTH = 8936,
    WILD_GROWTH = 48438,
    IRONBARK = 102342,
    TRANQUILITY = 157982,
    TREE_OF_LIFE = 33891,
    SOUL_OF_THE_FOREST = 114108,
    MARK_OF_THE_WILD = 1126
}

-- Important debuffs to track
local DEBUFFS = {
    MOONFIRE = 164812,
    SUNFIRE = 164815,
    STELLAR_FLARE = 202347,
    
    RAKE = 155722,
    RIP = 1079,
    THRASH_BEAR = 192090,
    THRASH_CAT = 106830,
    ENTANGLING_ROOTS = 339,
    HIBERNATE = 2637
}

-- Initialize the Druid module
function DruidModule:Initialize()
    -- Register settings
    self:RegisterSettings()
    
    -- Register events
    self:RegisterEvents()
    
    -- Register rotations
    self:RegisterRotations()
    
    API.PrintDebug("Druid module initialized")
    return true
end

-- Register settings
function DruidModule:RegisterSettings()
    ConfigRegistry:RegisterSettings("Druid", {
        generalSettings = {
            enabled = {
                displayName = "Enable Druid Module",
                description = "Enable the Druid module for all specs",
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
            useMark = {
                displayName = "Use Mark of the Wild",
                description = "Automatically cast Mark of the Wild if missing",
                type = "toggle",
                default = true
            },
            autoForm = {
                displayName = "Auto Form Change",
                description = "Automatically change forms based on spec and situation",
                type = "toggle",
                default = true
            },
            useSelf = {
                displayName = "Use Self Heal",
                description = "Use self healing abilities when low on health",
                type = "toggle",
                default = true
            },
            selfHealThreshold = {
                displayName = "Self Heal Threshold",
                description = "Health percentage to use self healing",
                type = "slider",
                min = 10,
                max = 60,
                step = 5,
                default = 40
            }
        },
        balanceSettings = {
            useCelestialAlignment = {
                displayName = "Use Celestial Alignment",
                description = "Use Celestial Alignment or Incarnation on cooldown",
                type = "toggle",
                default = true
            },
            useStarfall = {
                displayName = "Use Starfall for AoE",
                description = "Use Starfall instead of Starsurge for AoE",
                type = "toggle",
                default = true
            },
            starfallTargets = {
                displayName = "Starfall Targets",
                description = "Minimum targets to use Starfall instead of Starsurge",
                type = "slider",
                min = 2,
                max = 6,
                step = 1,
                default = 3
            },
            useFuryOfElune = {
                displayName = "Use Fury of Elune",
                description = "Use Fury of Elune when available",
                type = "toggle",
                default = true
            },
            useBarkskin = {
                displayName = "Use Barkskin",
                description = "Use Barkskin when taking damage",
                type = "toggle",
                default = true
            },
            barkskinThreshold = {
                displayName = "Barkskin Health Threshold",
                description = "Health percentage to use Barkskin",
                type = "slider",
                min = 20,
                max = 80,
                step = 5,
                default = 60
            },
            useStellarFlare = {
                displayName = "Use Stellar Flare",
                description = "Maintain Stellar Flare on target if talented",
                type = "toggle",
                default = true
            }
        },
        feralSettings = {
            useTigersFury = {
                displayName = "Use Tiger's Fury",
                description = "Use Tiger's Fury on cooldown",
                type = "toggle",
                default = true
            },
            useBerserk = {
                displayName = "Use Berserk/Incarnation",
                description = "Use Berserk or Incarnation on cooldown",
                type = "toggle",
                default = true
            },
            useBloodtalons = {
                displayName = "Use Bloodtalons",
                description = "Optimize for Bloodtalons procs if talented",
                type = "toggle",
                default = true
            },
            useSavageRoar = {
                displayName = "Use Savage Roar",
                description = "Maintain Savage Roar if talented",
                type = "toggle",
                default = true
            },
            conserveEnergy = {
                displayName = "Conserve Energy",
                description = "Pool energy for more efficient usage",
                type = "toggle",
                default = true
            },
            useSurvivalInstincts = {
                displayName = "Use Survival Instincts",
                description = "Use Survival Instincts at low health",
                type = "toggle",
                default = true
            },
            survivalInstinctsThreshold = {
                displayName = "Survival Instincts Health Threshold",
                description = "Health percentage to use Survival Instincts",
                type = "slider",
                min = 10,
                max = 50,
                step = 5,
                default = 30
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
        guardianSettings = {
            useIronfur = {
                displayName = "Use Ironfur",
                description = "Use Ironfur for active mitigation",
                type = "toggle",
                default = true
            },
            ironfurThreshold = {
                displayName = "Ironfur Health Threshold",
                description = "Health percentage to prioritize Ironfur",
                type = "slider",
                min = 40,
                max = 100,
                step = 5,
                default = 80
            },
            useFrenziedRegeneration = {
                displayName = "Use Frenzied Regeneration",
                description = "Use Frenzied Regeneration at low health",
                type = "toggle",
                default = true
            },
            frenziedRegenThreshold = {
                displayName = "Frenzied Regeneration Health Threshold",
                description = "Health percentage to use Frenzied Regeneration",
                type = "slider",
                min = 10,
                max = 70,
                step = 5,
                default = 50
            },
            useBarkskin = {
                displayName = "Use Barkskin",
                description = "Use Barkskin in combat",
                type = "toggle",
                default = true
            },
            barkskinThreshold = {
                displayName = "Barkskin Health Threshold",
                description = "Health percentage to use Barkskin",
                type = "slider",
                min = 20,
                max = 80,
                step = 5,
                default = 60
            },
            useSurvivalInstincts = {
                displayName = "Use Survival Instincts",
                description = "Use Survival Instincts at critical health",
                type = "toggle",
                default = true
            },
            survivalInstinctsThreshold = {
                displayName = "Survival Instincts Health Threshold",
                description = "Health percentage to use Survival Instincts",
                type = "slider",
                min = 10,
                max = 40,
                step = 5,
                default = 25
            },
            useBerserk = {
                displayName = "Use Berserk/Incarnation",
                description = "Use Berserk or Incarnation on cooldown",
                type = "toggle",
                default = true
            },
            aoeThreshold = {
                displayName = "AoE Threshold",
                description = "Number of targets to prioritize AoE abilities",
                type = "slider",
                min = 2,
                max = 6,
                step = 1,
                default = 3
            }
        },
        restorationSettings = {
            useRejuvenation = {
                displayName = "Use Rejuvenation",
                description = "Automatically apply Rejuvenation to targets",
                type = "toggle",
                default = true
            },
            useWildGrowth = {
                displayName = "Use Wild Growth",
                description = "Use Wild Growth for group healing",
                type = "toggle",
                default = true
            },
            wildGrowthThreshold = {
                displayName = "Wild Growth Injured Count",
                description = "Minimum injured party members to use Wild Growth",
                type = "slider",
                min = 2,
                max = 6,
                step = 1,
                default = 3
            },
            useSwiftmend = {
                displayName = "Use Swiftmend",
                description = "Use Swiftmend for emergency healing",
                type = "toggle",
                default = true
            },
            swiftmendThreshold = {
                displayName = "Swiftmend Health Threshold",
                description = "Health percentage to use Swiftmend",
                type = "slider",
                min = 10,
                max = 70,
                step = 5,
                default = 40
            },
            useIronbark = {
                displayName = "Use Ironbark",
                description = "Use Ironbark on low health targets",
                type = "toggle",
                default = true
            },
            ironbarkThreshold = {
                displayName = "Ironbark Health Threshold",
                description = "Health percentage to use Ironbark",
                type = "slider",
                min = 10,
                max = 50,
                step = 5,
                default = 30
            },
            useBarkskin = {
                displayName = "Use Barkskin",
                description = "Use Barkskin when taking damage",
                type = "toggle",
                default = true
            },
            barkskinThreshold = {
                displayName = "Barkskin Health Threshold",
                description = "Health percentage to use Barkskin",
                type = "slider",
                min = 20,
                max = 80,
                step = 5,
                default = 60
            },
            useTranquility = {
                displayName = "Use Tranquility",
                description = "Use Tranquility for major group healing",
                type = "toggle",
                default = true
            },
            tranquilityThreshold = {
                displayName = "Tranquility Group Health Threshold",
                description = "Average group health percentage to use Tranquility",
                type = "slider",
                min = 10,
                max = 80,
                step = 5,
                default = 40
            }
        }
    })
    
    -- Add callback for settings changes
    ConfigRegistry:RegisterCallback("Druid", function(settings)
        self:ApplySettings(settings)
    end)
end

-- Apply settings
function DruidModule:ApplySettings(settings)
    -- Apply general settings
    isEnabled = settings.generalSettings.enabled
end

-- Register events
function DruidModule:RegisterEvents()
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
function DruidModule:OnSpecializationChanged()
    -- Get current spec ID
    playerSpec = API.GetActiveSpecID()
    
    API.PrintDebug("Druid specialization changed: " .. playerSpec)
    
    -- Ensure correct rotation is registered
    if playerSpec == SPEC_BALANCE then
        self:RegisterBalanceRotation()
    elseif playerSpec == SPEC_FERAL then
        self:RegisterFeralRotation()
    elseif playerSpec == SPEC_GUARDIAN then
        self:RegisterGuardianRotation()
    elseif playerSpec == SPEC_RESTORATION then
        self:RegisterRestorationRotation()
    end
end

-- Register rotations
function DruidModule:RegisterRotations()
    -- Register spec-specific rotations
    self:RegisterBalanceRotation()
    self:RegisterFeralRotation()
    self:RegisterGuardianRotation()
    self:RegisterRestorationRotation()
end

-- Register Balance rotation
function DruidModule:RegisterBalanceRotation()
    RotationManager:RegisterRotation("DruidBalance", {
        id = "DruidBalance",
        name = "Druid - Balance",
        class = "DRUID",
        spec = SPEC_BALANCE,
        level = 10,
        description = "Balance Druid rotation for The War Within Season 2",
        author = "WindrunnerRotations",
        version = "1.0.0",
        rotation = function()
            return self:BalanceRotation()
        end
    })
end

-- Register Feral rotation
function DruidModule:RegisterFeralRotation()
    RotationManager:RegisterRotation("DruidFeral", {
        id = "DruidFeral",
        name = "Druid - Feral",
        class = "DRUID",
        spec = SPEC_FERAL,
        level = 10,
        description = "Feral Druid rotation for The War Within Season 2",
        author = "WindrunnerRotations",
        version = "1.0.0",
        rotation = function()
            return self:FeralRotation()
        end
    })
end

-- Register Guardian rotation
function DruidModule:RegisterGuardianRotation()
    RotationManager:RegisterRotation("DruidGuardian", {
        id = "DruidGuardian",
        name = "Druid - Guardian",
        class = "DRUID",
        spec = SPEC_GUARDIAN,
        level = 10,
        description = "Guardian Druid rotation for The War Within Season 2",
        author = "WindrunnerRotations",
        version = "1.0.0",
        rotation = function()
            return self:GuardianRotation()
        end
    })
end

-- Register Restoration rotation
function DruidModule:RegisterRestorationRotation()
    RotationManager:RegisterRotation("DruidRestoration", {
        id = "DruidRestoration",
        name = "Druid - Restoration",
        class = "DRUID",
        spec = SPEC_RESTORATION,
        level = 10,
        description = "Restoration Druid rotation for The War Within Season 2",
        author = "WindrunnerRotations",
        version = "1.0.0",
        rotation = function()
            return self:RestorationRotation()
        end
    })
end

-- Balance rotation
function DruidModule:BalanceRotation()
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
    local settings = ConfigRegistry:GetSettings("Druid")
    
    -- Common Combat Variables
    local health, maxHealth, healthPercent = API.GetUnitHealth(player)
    local targetHealth, targetMaxHealth, targetHealthPercent = API.GetUnitHealth(target)
    local mana, maxMana, manaPercent = API.GetUnitPower(player, Enum.PowerType.Mana)
    local astralPower = API.GetUnitPower(player, Enum.PowerType.LunarPower)
    local enemies = API.GetEnemyCount(8)
    local inMoonkinForm = API.UnitHasBuff(player, BUFFS.MOONKIN_FORM)
    local hasSolarEclipse = API.UnitHasBuff(player, BUFFS.ECLIPSE_SOLAR)
    local hasLunarEclipse = API.UnitHasBuff(player, BUFFS.ECLIPSE_LUNAR)
    local hasCelestialAlignment = API.UnitHasBuff(player, BUFFS.CELESTIAL_ALIGNMENT)
    local hasIncarnation = API.UnitHasBuff(player, BUFFS.INCARNATION_CHOSEN_OF_ELUNE)
    local hasStarlord = API.UnitHasBuff(player, BUFFS.STARLORD)
    local moonfire = API.UnitHasDebuff(target, DEBUFFS.MOONFIRE)
    local sunfire = API.UnitHasDebuff(target, DEBUFFS.SUNFIRE)
    local stellarFlare = API.UnitHasDebuff(target, DEBUFFS.STELLAR_FLARE)
    
    -- Mark of the Wild
    if settings.generalSettings.useMark and not API.UnitHasBuff(player, BUFFS.MARK_OF_THE_WILD) then
        if API.IsSpellKnown(BALANCE_SPELLS.MARK_OF_THE_WILD) and API.IsSpellUsable(BALANCE_SPELLS.MARK_OF_THE_WILD) then
            return {
                type = "spell",
                id = BALANCE_SPELLS.MARK_OF_THE_WILD,
                target = player
            }
        end
    end
    
    -- Enter Moonkin Form if not in it and setting enabled
    if settings.generalSettings.autoForm and not inMoonkinForm then
        if API.IsSpellKnown(BALANCE_SPELLS.MOONKIN_FORM) and API.IsSpellUsable(BALANCE_SPELLS.MOONKIN_FORM) then
            return {
                type = "spell",
                id = BALANCE_SPELLS.MOONKIN_FORM,
                target = player
            }
        end
    end
    
    -- Defensive abilities
    if settings.generalSettings.useDefensives then
        -- Barkskin
        if settings.balanceSettings.useBarkskin and
           healthPercent <= settings.balanceSettings.barkskinThreshold and
           API.IsSpellKnown(BALANCE_SPELLS.BARKSKIN) and 
           API.IsSpellUsable(BALANCE_SPELLS.BARKSKIN) then
            return {
                type = "spell",
                id = BALANCE_SPELLS.BARKSKIN,
                target = player
            }
        end
        
        -- Self-healing with Regrowth
        if settings.generalSettings.useSelf and
           healthPercent <= settings.generalSettings.selfHealThreshold and
           API.IsSpellKnown(BALANCE_SPELLS.REGROWTH) and 
           API.IsSpellUsable(BALANCE_SPELLS.REGROWTH) then
            return {
                type = "spell",
                id = BALANCE_SPELLS.REGROWTH,
                target = player
            }
        end
        
        -- Renewal if talented
        if healthPercent <= settings.generalSettings.selfHealThreshold and
           API.IsSpellKnown(BALANCE_SPELLS.RENEWAL) and 
           API.IsSpellUsable(BALANCE_SPELLS.RENEWAL) then
            return {
                type = "spell",
                id = BALANCE_SPELLS.RENEWAL,
                target = player
            }
        end
    end
    
    -- Apply DoTs
    -- Moonfire if not applied
    if not moonfire and
       API.IsSpellKnown(BALANCE_SPELLS.MOONFIRE) and 
       API.IsSpellUsable(BALANCE_SPELLS.MOONFIRE) then
        return {
            type = "spell",
            id = BALANCE_SPELLS.MOONFIRE,
            target = target
        }
    end
    
    -- Sunfire if not applied
    if not sunfire and
       API.IsSpellKnown(BALANCE_SPELLS.SUNFIRE) and 
       API.IsSpellUsable(BALANCE_SPELLS.SUNFIRE) then
        return {
            type = "spell",
            id = BALANCE_SPELLS.SUNFIRE,
            target = target
        }
    end
    
    -- Stellar Flare if talented and setting enabled
    if settings.balanceSettings.useStellarFlare and
       not stellarFlare and
       API.IsSpellKnown(BALANCE_SPELLS.STELLAR_FLARE) and 
       API.IsSpellUsable(BALANCE_SPELLS.STELLAR_FLARE) then
        return {
            type = "spell",
            id = BALANCE_SPELLS.STELLAR_FLARE,
            target = target
        }
    end
    
    -- Offensive cooldowns
    if inCombat then
        -- Celestial Alignment / Incarnation
        if settings.balanceSettings.useCelestialAlignment and
           not hasCelestialAlignment and not hasIncarnation then
            if API.IsSpellKnown(BALANCE_SPELLS.INCARNATION_CHOSEN_OF_ELUNE) and 
               API.IsSpellUsable(BALANCE_SPELLS.INCARNATION_CHOSEN_OF_ELUNE) then
                return {
                    type = "spell",
                    id = BALANCE_SPELLS.INCARNATION_CHOSEN_OF_ELUNE,
                    target = player
                }
            elseif API.IsSpellKnown(BALANCE_SPELLS.CELESTIAL_ALIGNMENT) and 
                   API.IsSpellUsable(BALANCE_SPELLS.CELESTIAL_ALIGNMENT) then
                return {
                    type = "spell",
                    id = BALANCE_SPELLS.CELESTIAL_ALIGNMENT,
                    target = player
                }
            end
        end
        
        -- Fury of Elune if talented and setting enabled
        if settings.balanceSettings.useFuryOfElune and
           API.IsSpellKnown(BALANCE_SPELLS.FURY_OF_ELUNE) and 
           API.IsSpellUsable(BALANCE_SPELLS.FURY_OF_ELUNE) then
            return {
                type = "spell",
                id = BALANCE_SPELLS.FURY_OF_ELUNE,
                target = target
            }
        end
        
        -- Force of Nature if talented
        if API.IsSpellKnown(BALANCE_SPELLS.FORCE_OF_NATURE) and 
           API.IsSpellUsable(BALANCE_SPELLS.FORCE_OF_NATURE) then
            return {
                type = "spell",
                id = BALANCE_SPELLS.FORCE_OF_NATURE,
                target = target
            }
        end
        
        -- Warrior of Elune if talented
        if API.IsSpellKnown(BALANCE_SPELLS.WARRIOR_OF_ELUNE) and 
           API.IsSpellUsable(BALANCE_SPELLS.WARRIOR_OF_ELUNE) then
            return {
                type = "spell",
                id = BALANCE_SPELLS.WARRIOR_OF_ELUNE,
                target = player
            }
        end
    end
    
    -- AoE rotation
    if settings.balanceSettings.useStarfall and enemies >= settings.balanceSettings.starfallTargets then
        -- Starfall for AoE
        if astralPower >= 50 and
           API.IsSpellKnown(BALANCE_SPELLS.STARFALL) and 
           API.IsSpellUsable(BALANCE_SPELLS.STARFALL) then
            return {
                type = "spell",
                id = BALANCE_SPELLS.STARFALL,
                target = player
            }
        end
    end
    
    -- Core rotation
    -- Starsurge to spend Astral Power
    if astralPower >= 30 and
       (enemies < settings.balanceSettings.starfallTargets or not settings.balanceSettings.useStarfall) and
       API.IsSpellKnown(BALANCE_SPELLS.STARSURGE) and 
       API.IsSpellUsable(BALANCE_SPELLS.STARSURGE) then
        return {
            type = "spell",
            id = BALANCE_SPELLS.STARSURGE,
            target = target
        }
    end
    
    -- Eclipse phase - prioritize appropriate spell
    if hasLunarEclipse and
       API.IsSpellKnown(BALANCE_SPELLS.STARFIRE) and 
       API.IsSpellUsable(BALANCE_SPELLS.STARFIRE) then
        return {
            type = "spell",
            id = BALANCE_SPELLS.STARFIRE,
            target = target
        }
    end
    
    if hasSolarEclipse and
       API.IsSpellKnown(BALANCE_SPELLS.WRATH) and 
       API.IsSpellUsable(BALANCE_SPELLS.WRATH) then
        return {
            type = "spell",
            id = BALANCE_SPELLS.WRATH,
            target = target
        }
    end
    
    -- New Moon cycle if talented
    if API.IsSpellKnown(BALANCE_SPELLS.NEW_MOON) and 
       API.IsSpellUsable(BALANCE_SPELLS.NEW_MOON) then
        return {
            type = "spell",
            id = BALANCE_SPELLS.NEW_MOON,
            target = target
        }
    end
    
    if API.IsSpellKnown(BALANCE_SPELLS.HALF_MOON) and 
       API.IsSpellUsable(BALANCE_SPELLS.HALF_MOON) then
        return {
            type = "spell",
            id = BALANCE_SPELLS.HALF_MOON,
            target = target
        }
    end
    
    if API.IsSpellKnown(BALANCE_SPELLS.FULL_MOON) and 
       API.IsSpellUsable(BALANCE_SPELLS.FULL_MOON) then
        return {
            type = "spell",
            id = BALANCE_SPELLS.FULL_MOON,
            target = target
        }
    end
    
    -- Default filler: Wrath (Solar) or Starfire (AoE or Lunar)
    if enemies > 1 or hasLunarEclipse then
        if API.IsSpellKnown(BALANCE_SPELLS.STARFIRE) and 
           API.IsSpellUsable(BALANCE_SPELLS.STARFIRE) then
            return {
                type = "spell",
                id = BALANCE_SPELLS.STARFIRE,
                target = target
            }
        end
    else
        if API.IsSpellKnown(BALANCE_SPELLS.WRATH) and 
           API.IsSpellUsable(BALANCE_SPELLS.WRATH) then
            return {
                type = "spell",
                id = BALANCE_SPELLS.WRATH,
                target = target
            }
        end
    end
    
    return nil
end

-- Feral rotation
function DruidModule:FeralRotation()
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
    local settings = ConfigRegistry:GetSettings("Druid")
    
    -- Common Combat Variables
    local health, maxHealth, healthPercent = API.GetUnitHealth(player)
    local targetHealth, targetMaxHealth, targetHealthPercent = API.GetUnitHealth(target)
    local energy = API.GetUnitPower(player, Enum.PowerType.Energy)
    local comboPoints = API.GetUnitPower(player, Enum.PowerType.ComboPoints)
    local enemies = API.GetEnemyCount(8)
    local aoeEnabled = settings.feralSettings.aoeThreshold <= enemies
    local inCatForm = API.UnitHasBuff(player, BUFFS.CAT_FORM)
    local inProwl = API.UnitHasBuff(player, BUFFS.PROWL)
    local hasTigersFury = API.UnitHasBuff(player, BUFFS.TIGERS_FURY)
    local hasBerserk = API.UnitHasBuff(player, BUFFS.BERSERK)
    local hasIncarnation = API.UnitHasBuff(player, BUFFS.INCARNATION_KING_OF_THE_JUNGLE)
    local hasClearcasting = API.UnitHasBuff(player, BUFFS.CLEARCASTING)
    local hasPredatorySwiftness = API.UnitHasBuff(player, BUFFS.PREDATORY_SWIFTNESS)
    local hasBloodtalons = API.UnitHasBuff(player, BUFFS.BLOODTALONS)
    local hasSavageRoar = API.UnitHasBuff(player, BUFFS.SAVAGE_ROAR)
    local rake = API.UnitHasDebuff(target, DEBUFFS.RAKE)
    local rip = API.UnitHasDebuff(target, DEBUFFS.RIP)
    
    -- Mark of the Wild
    if settings.generalSettings.useMark and not API.UnitHasBuff(player, BUFFS.MARK_OF_THE_WILD) then
        if API.IsSpellKnown(FERAL_SPELLS.MARK_OF_THE_WILD) and API.IsSpellUsable(FERAL_SPELLS.MARK_OF_THE_WILD) then
            return {
                type = "spell",
                id = FERAL_SPELLS.MARK_OF_THE_WILD,
                target = player
            }
        end
    end
    
    -- Enter Cat Form if not in it and setting enabled
    if settings.generalSettings.autoForm and not inCatForm then
        if API.IsSpellKnown(FERAL_SPELLS.CAT_FORM) and API.IsSpellUsable(FERAL_SPELLS.CAT_FORM) then
            return {
                type = "spell",
                id = FERAL_SPELLS.CAT_FORM,
                target = player
            }
        end
    end
    
    -- Defensive abilities
    if settings.generalSettings.useDefensives then
        -- Survival Instincts
        if settings.feralSettings.useSurvivalInstincts and
           healthPercent <= settings.feralSettings.survivalInstinctsThreshold and
           API.IsSpellKnown(FERAL_SPELLS.SURVIVAL_INSTINCTS) and 
           API.IsSpellUsable(FERAL_SPELLS.SURVIVAL_INSTINCTS) then
            return {
                type = "spell",
                id = FERAL_SPELLS.SURVIVAL_INSTINCTS,
                target = player
            }
        end
        
        -- Self-healing with Regrowth (when Predatory Swiftness is up)
        if settings.generalSettings.useSelf and
           hasPredatorySwiftness and
           healthPercent <= settings.generalSettings.selfHealThreshold and
           API.IsSpellKnown(FERAL_SPELLS.REGROWTH) and 
           API.IsSpellUsable(FERAL_SPELLS.REGROWTH) then
            return {
                type = "spell",
                id = FERAL_SPELLS.REGROWTH,
                target = player
            }
        end
        
        -- Renewal if talented
        if healthPercent <= settings.generalSettings.selfHealThreshold and
           API.IsSpellKnown(FERAL_SPELLS.RENEWAL) and 
           API.IsSpellUsable(FERAL_SPELLS.RENEWAL) then
            return {
                type = "spell",
                id = FERAL_SPELLS.RENEWAL,
                target = player
            }
        end
    end
    
    -- Opener from stealth
    if inProwl then
        -- Rake from stealth for enhanced damage
        if API.IsSpellKnown(FERAL_SPELLS.RAKE) and 
           API.IsSpellUsable(FERAL_SPELLS.RAKE) then
            return {
                type = "spell",
                id = FERAL_SPELLS.RAKE,
                target = target
            }
        end
    end
    
    -- Offensive cooldowns
    if inCombat then
        -- Tiger's Fury
        if settings.feralSettings.useTigersFury and
           not hasTigersFury and
           energy < 50 and
           API.IsSpellKnown(FERAL_SPELLS.TIGERS_FURY) and 
           API.IsSpellUsable(FERAL_SPELLS.TIGERS_FURY) then
            return {
                type = "spell",
                id = FERAL_SPELLS.TIGERS_FURY,
                target = player
            }
        end
        
        -- Berserk / Incarnation
        if settings.feralSettings.useBerserk and
           not hasBerserk and not hasIncarnation then
            if API.IsSpellKnown(FERAL_SPELLS.INCARNATION_KING_OF_THE_JUNGLE) and 
               API.IsSpellUsable(FERAL_SPELLS.INCARNATION_KING_OF_THE_JUNGLE) then
                return {
                    type = "spell",
                    id = FERAL_SPELLS.INCARNATION_KING_OF_THE_JUNGLE,
                    target = player
                }
            elseif API.IsSpellKnown(FERAL_SPELLS.BERSERK) and 
                   API.IsSpellUsable(FERAL_SPELLS.BERSERK) then
                return {
                    type = "spell",
                    id = FERAL_SPELLS.BERSERK,
                    target = player
                }
            end
        end
        
        -- Feral Frenzy if talented
        if comboPoints <= 2 and
           API.IsSpellKnown(FERAL_SPELLS.FERAL_FRENZY) and 
           API.IsSpellUsable(FERAL_SPELLS.FERAL_FRENZY) then
            return {
                type = "spell",
                id = FERAL_SPELLS.FERAL_FRENZY,
                target = target
            }
        end
    end
    
    -- Bloodtalons setup if talented and not already have buff
    if settings.feralSettings.useBloodtalons and
       not hasBloodtalons and
       API.IsSpellKnown(FERAL_SPELLS.BLOODTALONS) then
        -- Different abilities can be used to proc Bloodtalons depending on the current patch's mechanics
        -- Just an example here - would need to be updated for the current implementation
        if API.IsSpellKnown(FERAL_SPELLS.SHRED) and 
           API.IsSpellUsable(FERAL_SPELLS.SHRED) and
           energy >= 40 then
            return {
                type = "spell",
                id = FERAL_SPELLS.SHRED,
                target = target
            }
        end
    end
    
    -- Maintain Savage Roar
    if settings.feralSettings.useSavageRoar and
       comboPoints >= 1 and
       (not hasSavageRoar or API.GetBuffRemaining(player, BUFFS.SAVAGE_ROAR) < 3) and
       API.IsSpellKnown(FERAL_SPELLS.SAVAGE_ROAR) and 
       API.IsSpellUsable(FERAL_SPELLS.SAVAGE_ROAR) then
        return {
            type = "spell",
            id = FERAL_SPELLS.SAVAGE_ROAR,
            target = player
        }
    end
    
    -- AoE rotation
    if aoeEnabled and enemies >= 3 then
        -- Primal Wrath for AoE finisher
        if comboPoints >= 4 and
           API.IsSpellKnown(FERAL_SPELLS.PRIMAL_WRATH) and 
           API.IsSpellUsable(FERAL_SPELLS.PRIMAL_WRATH) then
            return {
                type = "spell",
                id = FERAL_SPELLS.PRIMAL_WRATH,
                target = target
            }
        end
        
        -- Brutal Slash if talented
        if API.IsSpellKnown(FERAL_SPELLS.BRUTAL_SLASH) and 
           API.IsSpellUsable(FERAL_SPELLS.BRUTAL_SLASH) and
           energy >= 25 then
            return {
                type = "spell",
                id = FERAL_SPELLS.BRUTAL_SLASH,
                target = target
            }
        end
        
        -- Thrash for AoE
        if API.IsSpellKnown(FERAL_SPELLS.THRASH) and 
           API.IsSpellUsable(FERAL_SPELLS.THRASH) and
           energy >= 40 then
            return {
                type = "spell",
                id = FERAL_SPELLS.THRASH,
                target = target
            }
        end
        
        -- Swipe for AoE filler
        if API.IsSpellKnown(FERAL_SPELLS.SWIPE) and 
           API.IsSpellUsable(FERAL_SPELLS.SWIPE) and
           energy >= 35 then
            return {
                type = "spell",
                id = FERAL_SPELLS.SWIPE,
                target = target
            }
        end
    end
    
    -- Core rotation
    -- Maintain Rake
    if not rake and
       API.IsSpellKnown(FERAL_SPELLS.RAKE) and 
       API.IsSpellUsable(FERAL_SPELLS.RAKE) and
       energy >= 35 then
        return {
            type = "spell",
            id = FERAL_SPELLS.RAKE,
            target = target
        }
    end
    
    -- Maintain Rip at high combo points
    if not rip and comboPoints >= 4 and
       API.IsSpellKnown(FERAL_SPELLS.RIP) and 
       API.IsSpellUsable(FERAL_SPELLS.RIP) and
       energy >= 30 then
        return {
            type = "spell",
            id = FERAL_SPELLS.RIP,
            target = target
        }
    end
    
    -- Ferocious Bite at max combo points or to refresh Rip
    if comboPoints >= 5 and energy >= 50 and
       API.IsSpellKnown(FERAL_SPELLS.FEROCIOUS_BITE) and 
       API.IsSpellUsable(FERAL_SPELLS.FEROCIOUS_BITE) then
        return {
            type = "spell",
            id = FERAL_SPELLS.FEROCIOUS_BITE,
            target = target
        }
    end
    
    -- Shred as filler if energy is high enough or during Clearcasting
    if (energy >= 40 or hasClearcasting) and
       API.IsSpellKnown(FERAL_SPELLS.SHRED) and 
       API.IsSpellUsable(FERAL_SPELLS.SHRED) then
        return {
            type = "spell",
            id = FERAL_SPELLS.SHRED,
            target = target
        }
    end
    
    return nil
end

-- Guardian rotation
function DruidModule:GuardianRotation()
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
    local settings = ConfigRegistry:GetSettings("Druid")
    
    -- Common Combat Variables
    local health, maxHealth, healthPercent = API.GetUnitHealth(player)
    local targetHealth, targetMaxHealth, targetHealthPercent = API.GetUnitHealth(target)
    local rage = API.GetUnitPower(player, Enum.PowerType.Rage)
    local enemies = API.GetEnemyCount(8)
    local aoeEnabled = settings.guardianSettings.aoeThreshold <= enemies
    local inBearForm = API.UnitHasBuff(player, BUFFS.BEAR_FORM)
    local hasIronfur = API.UnitHasBuff(player, BUFFS.IRONFUR)
    local ironfurStacks = API.GetBuffStacks(player, BUFFS.IRONFUR)
    local hasFrenziedRegeneration = API.UnitHasBuff(player, BUFFS.FRENZIED_REGENERATION)
    local hasBarkskin = API.UnitHasBuff(player, BUFFS.BARKSKIN)
    local hasSurvivalInstincts = API.UnitHasBuff(player, BUFFS.SURVIVAL_INSTINCTS)
    local hasBerserk = API.UnitHasBuff(player, BUFFS.BERSERK)
    local hasIncarnation = API.UnitHasBuff(player, BUFFS.INCARNATION_GUARDIAN_OF_URSOC)
    local hasGalacticGuardian = API.UnitHasBuff(player, BUFFS.GALACTIC_GUARDIAN)
    local hasGore = API.UnitHasBuff(player, BUFFS.GORE)
    local thrashDebuff = API.UnitHasDebuff(target, DEBUFFS.THRASH_BEAR)
    
    -- Mark of the Wild
    if settings.generalSettings.useMark and not API.UnitHasBuff(player, BUFFS.MARK_OF_THE_WILD) then
        if API.IsSpellKnown(GUARDIAN_SPELLS.MARK_OF_THE_WILD) and API.IsSpellUsable(GUARDIAN_SPELLS.MARK_OF_THE_WILD) then
            return {
                type = "spell",
                id = GUARDIAN_SPELLS.MARK_OF_THE_WILD,
                target = player
            }
        end
    end
    
    -- Enter Bear Form if not in it and setting enabled
    if settings.generalSettings.autoForm and not inBearForm then
        if API.IsSpellKnown(GUARDIAN_SPELLS.BEAR_FORM) and API.IsSpellUsable(GUARDIAN_SPELLS.BEAR_FORM) then
            return {
                type = "spell",
                id = GUARDIAN_SPELLS.BEAR_FORM,
                target = player
            }
        end
    end
    
    -- Defensive abilities (highest priority)
    if settings.generalSettings.useDefensives then
        -- Frenzied Regeneration
        if settings.guardianSettings.useFrenziedRegeneration and
           not hasFrenziedRegeneration and
           healthPercent <= settings.guardianSettings.frenziedRegenThreshold and
           API.IsSpellKnown(GUARDIAN_SPELLS.FRENZIED_REGENERATION) and 
           API.IsSpellUsable(GUARDIAN_SPELLS.FRENZIED_REGENERATION) then
            return {
                type = "spell",
                id = GUARDIAN_SPELLS.FRENZIED_REGENERATION,
                target = player
            }
        end
        
        -- Survival Instincts at critical health
        if settings.guardianSettings.useSurvivalInstincts and
           healthPercent <= settings.guardianSettings.survivalInstinctsThreshold and
           API.IsSpellKnown(GUARDIAN_SPELLS.SURVIVAL_INSTINCTS) and 
           API.IsSpellUsable(GUARDIAN_SPELLS.SURVIVAL_INSTINCTS) then
            return {
                type = "spell",
                id = GUARDIAN_SPELLS.SURVIVAL_INSTINCTS,
                target = player
            }
        end
        
        -- Barkskin
        if settings.guardianSettings.useBarkskin and
           healthPercent <= settings.guardianSettings.barkskinThreshold and
           API.IsSpellKnown(GUARDIAN_SPELLS.BARKSKIN) and 
           API.IsSpellUsable(GUARDIAN_SPELLS.BARKSKIN) then
            return {
                type = "spell",
                id = GUARDIAN_SPELLS.BARKSKIN,
                target = player
            }
        end
        
        -- Ironfur for physical damage mitigation
        if settings.guardianSettings.useIronfur and
           (ironfurStacks < 2 or healthPercent <= settings.guardianSettings.ironfurThreshold) and
           rage >= 40 and
           API.IsSpellKnown(GUARDIAN_SPELLS.IRONFUR) and 
           API.IsSpellUsable(GUARDIAN_SPELLS.IRONFUR) then
            return {
                type = "spell",
                id = GUARDIAN_SPELLS.IRONFUR,
                target = player
            }
        end
    end
    
    -- Offensive cooldowns
    if inCombat then
        -- Berserk / Incarnation
        if settings.guardianSettings.useBerserk and
           not hasBerserk and not hasIncarnation then
            if API.IsSpellKnown(GUARDIAN_SPELLS.INCARNATION_GUARDIAN_OF_URSOC) and 
               API.IsSpellUsable(GUARDIAN_SPELLS.INCARNATION_GUARDIAN_OF_URSOC) then
                return {
                    type = "spell",
                    id = GUARDIAN_SPELLS.INCARNATION_GUARDIAN_OF_URSOC,
                    target = player
                }
            elseif API.IsSpellKnown(GUARDIAN_SPELLS.BERSERK) and 
                   API.IsSpellUsable(GUARDIAN_SPELLS.BERSERK) then
                return {
                    type = "spell",
                    id = GUARDIAN_SPELLS.BERSERK,
                    target = player
                }
            end
        end
    end
    
    -- Core rotation
    -- Mangle during Gore proc
    if hasGore and
       API.IsSpellKnown(GUARDIAN_SPELLS.MANGLE) and 
       API.IsSpellUsable(GUARDIAN_SPELLS.MANGLE) then
        return {
            type = "spell",
            id = GUARDIAN_SPELLS.MANGLE,
            target = target
        }
    end
    
    -- Thrash to maintain the debuff or for AoE
    if (aoeEnabled or not thrashDebuff) and
       API.IsSpellKnown(GUARDIAN_SPELLS.THRASH) and 
       API.IsSpellUsable(GUARDIAN_SPELLS.THRASH) then
        return {
            type = "spell",
            id = GUARDIAN_SPELLS.THRASH,
            target = target
        }
    end
    
    -- Mangle as the main rage generator
    if API.IsSpellKnown(GUARDIAN_SPELLS.MANGLE) and 
       API.IsSpellUsable(GUARDIAN_SPELLS.MANGLE) then
        return {
            type = "spell",
            id = GUARDIAN_SPELLS.MANGLE,
            target = target
        }
    end
    
    -- Pulverize if talented and have 2+ Thrash stacks
    if API.IsSpellKnown(GUARDIAN_SPELLS.PULVERIZE) and 
       API.IsSpellUsable(GUARDIAN_SPELLS.PULVERIZE) and
       API.GetDebuffStacks(target, DEBUFFS.THRASH_BEAR) >= 2 then
        return {
            type = "spell",
            id = GUARDIAN_SPELLS.PULVERIZE,
            target = target
        }
    end
    
    -- Swipe for AoE damage
    if aoeEnabled and
       API.IsSpellKnown(GUARDIAN_SPELLS.SWIPE) and 
       API.IsSpellUsable(GUARDIAN_SPELLS.SWIPE) then
        return {
            type = "spell",
            id = GUARDIAN_SPELLS.SWIPE,
            target = target
        }
    end
    
    -- Maul to spend rage when not actively mitigating
    if rage >= 40 and healthPercent > 80 and
       API.IsSpellKnown(GUARDIAN_SPELLS.MAUL) and 
       API.IsSpellUsable(GUARDIAN_SPELLS.MAUL) then
        return {
            type = "spell",
            id = GUARDIAN_SPELLS.MAUL,
            target = target
        }
    end
    
    -- Swipe as filler
    if API.IsSpellKnown(GUARDIAN_SPELLS.SWIPE) and 
       API.IsSpellUsable(GUARDIAN_SPELLS.SWIPE) then
        return {
            type = "spell",
            id = GUARDIAN_SPELLS.SWIPE,
            target = target
        }
    end
    
    return nil
end

-- Restoration rotation
function DruidModule:RestorationRotation()
    -- Check if we should execute
    if not self:ShouldExecuteRotation() then
        return nil
    end
    
    -- Get player and target
    local player = "player"
    local target = "target"
    local lowestAlly = self:GetLowestHealthAlly()
    
    -- Get settings
    local settings = ConfigRegistry:GetSettings("Druid")
    
    -- Common Combat Variables
    local health, maxHealth, healthPercent = API.GetUnitHealth(player)
    local targetHealth, targetMaxHealth, targetHealthPercent = 100, 100, 100
    if UnitExists(target) then
        targetHealth, targetMaxHealth, targetHealthPercent = API.GetUnitHealth(target)
    end
    
    local lowestAllyHealth, lowestAllyMaxHealth, lowestAllyHealthPercent = 100, 100, 100
    if lowestAlly and UnitExists(lowestAlly) then
        lowestAllyHealth, lowestAllyMaxHealth, lowestAllyHealthPercent = API.GetUnitHealth(lowestAlly)
    end
    
    local mana, maxMana, manaPercent = API.GetUnitPower(player, Enum.PowerType.Mana)
    local injuredAllies = self:GetInjuredAlliesCount(80)
    local hasRejuvenation = lowestAlly and API.UnitHasBuff(lowestAlly, BUFFS.REJUVENATION)
    local hasGermination = lowestAlly and API.UnitHasBuff(lowestAlly, BUFFS.GERMINATION)
    local hasRegrowth = lowestAlly and API.UnitHasBuff(lowestAlly, BUFFS.REGROWTH)
    local hasLifebloom = lowestAlly and API.UnitHasBuff(lowestAlly, BUFFS.LIFEBLOOM)
    local hasWildGrowth = lowestAlly and API.UnitHasBuff(lowestAlly, BUFFS.WILD_GROWTH)
    local hasTranquility = API.UnitHasBuff(player, BUFFS.TRANQUILITY)
    local hasTreeOfLife = API.UnitHasBuff(player, BUFFS.TREE_OF_LIFE)
    
    -- Mark of the Wild
    if settings.generalSettings.useMark and not API.UnitHasBuff(player, BUFFS.MARK_OF_THE_WILD) then
        if API.IsSpellKnown(RESTORATION_SPELLS.MARK_OF_THE_WILD) and API.IsSpellUsable(RESTORATION_SPELLS.MARK_OF_THE_WILD) then
            return {
                type = "spell",
                id = RESTORATION_SPELLS.MARK_OF_THE_WILD,
                target = player
            }
        end
    end
    
    -- Choose healing target
    local healTarget = lowestAlly or player
    
    -- Emergency healing for critical targets
    if lowestAllyHealthPercent < settings.restorationSettings.swiftmendThreshold and
       settings.restorationSettings.useSwiftmend and
       API.IsSpellKnown(RESTORATION_SPELLS.SWIFTMEND) and 
       API.IsSpellUsable(RESTORATION_SPELLS.SWIFTMEND) then
        return {
            type = "spell",
            id = RESTORATION_SPELLS.SWIFTMEND,
            target = healTarget
        }
    end
    
    -- Defensive abilities
    if settings.generalSettings.useDefensives then
        -- Ironbark for ally protection
        if settings.restorationSettings.useIronbark and
           lowestAllyHealthPercent <= settings.restorationSettings.ironbarkThreshold and
           API.IsSpellKnown(RESTORATION_SPELLS.IRONBARK) and 
           API.IsSpellUsable(RESTORATION_SPELLS.IRONBARK) then
            return {
                type = "spell",
                id = RESTORATION_SPELLS.IRONBARK,
                target = healTarget
            }
        end
        
        -- Barkskin for self-protection
        if settings.restorationSettings.useBarkskin and
           healthPercent <= settings.restorationSettings.barkskinThreshold and
           API.IsSpellKnown(RESTORATION_SPELLS.BARKSKIN) and 
           API.IsSpellUsable(RESTORATION_SPELLS.BARKSKIN) then
            return {
                type = "spell",
                id = RESTORATION_SPELLS.BARKSKIN,
                target = player
            }
        end
    end
    
    -- Major cooldowns for heavy healing
    if inCombat then
        -- Tranquility for group healing
        if settings.restorationSettings.useTranquility and
           injuredAllies >= 3 and
           self:GetAverageGroupHealth() <= settings.restorationSettings.tranquilityThreshold and
           API.IsSpellKnown(RESTORATION_SPELLS.TRANQUILITY) and 
           API.IsSpellUsable(RESTORATION_SPELLS.TRANQUILITY) then
            return {
                type = "spell",
                id = RESTORATION_SPELLS.TRANQUILITY,
                target = player
            }
        end
        
        -- Incarnation: Tree of Life
        if API.IsSpellKnown(RESTORATION_SPELLS.INCARNATION_TREE_OF_LIFE) and 
           API.IsSpellUsable(RESTORATION_SPELLS.INCARNATION_TREE_OF_LIFE) and
           injuredAllies >= 3 then
            return {
                type = "spell",
                id = RESTORATION_SPELLS.INCARNATION_TREE_OF_LIFE,
                target = player
            }
        end
        
        -- Flourish if talented
        if API.IsSpellKnown(RESTORATION_SPELLS.FLOURISH) and 
           API.IsSpellUsable(RESTORATION_SPELLS.FLOURISH) and
           injuredAllies >= 3 then
            return {
                type = "spell",
                id = RESTORATION_SPELLS.FLOURISH,
                target = player
            }
        end
    end
    
    -- Group healing
    if settings.restorationSettings.useWildGrowth and
       injuredAllies >= settings.restorationSettings.wildGrowthThreshold and
       API.IsSpellKnown(RESTORATION_SPELLS.WILD_GROWTH) and 
       API.IsSpellUsable(RESTORATION_SPELLS.WILD_GROWTH) then
        return {
            type = "spell",
            id = RESTORATION_SPELLS.WILD_GROWTH,
            target = healTarget
        }
    end
    
    -- Core healing rotation
    -- Lifebloom uptime on tank
    if not hasLifebloom and
       API.IsSpellKnown(RESTORATION_SPELLS.LIFEBLOOM) and 
       API.IsSpellUsable(RESTORATION_SPELLS.LIFEBLOOM) then
        local tank = self:GetTank()
        if tank then
            return {
                type = "spell",
                id = RESTORATION_SPELLS.LIFEBLOOM,
                target = tank
            }
        end
    end
    
    -- Cenarion Ward if talented
    if API.IsSpellKnown(RESTORATION_SPELLS.CENARION_WARD) and 
       API.IsSpellUsable(RESTORATION_SPELLS.CENARION_WARD) and
       lowestAllyHealthPercent < 85 then
        return {
            type = "spell",
            id = RESTORATION_SPELLS.CENARION_WARD,
            target = healTarget
        }
    end
    
    -- Rejuvenation
    if settings.restorationSettings.useRejuvenation and
       not hasRejuvenation and lowestAllyHealthPercent < 90 and
       API.IsSpellKnown(RESTORATION_SPELLS.REJUVENATION) and 
       API.IsSpellUsable(RESTORATION_SPELLS.REJUVENATION) then
        return {
            type = "spell",
            id = RESTORATION_SPELLS.REJUVENATION,
            target = healTarget
        }
    end
    
    -- Germination (second Rejuvenation if talented)
    if settings.restorationSettings.useRejuvenation and
       hasRejuvenation and not hasGermination and lowestAllyHealthPercent < 80 and
       API.IsSpellKnown(RESTORATION_SPELLS.GERMINATION) and 
       API.IsSpellUsable(RESTORATION_SPELLS.REJUVENATION) then
        return {
            type = "spell",
            id = RESTORATION_SPELLS.REJUVENATION,
            target = healTarget
        }
    end
    
    -- Regrowth for direct healing
    if not hasRegrowth and lowestAllyHealthPercent < 70 and
       API.IsSpellKnown(RESTORATION_SPELLS.REGROWTH) and 
       API.IsSpellUsable(RESTORATION_SPELLS.REGROWTH) then
        return {
            type = "spell",
            id = RESTORATION_SPELLS.REGROWTH,
            target = healTarget
        }
    end
    
    -- Efflorescence placement
    if API.IsSpellKnown(RESTORATION_SPELLS.EFFLORESCENCE) and 
       API.IsSpellUsable(RESTORATION_SPELLS.EFFLORESCENCE) then
        return {
            type = "spell",
            id = RESTORATION_SPELLS.EFFLORESCENCE,
            target = player
        }
    end
    
    return nil
end

-- Get lowest health ally
function DruidModule:GetLowestHealthAlly()
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

-- Get tank (simple implementation)
function DruidModule:GetTank()
    for i = 1, 4 do
        local unit = "party" .. i
        if UnitExists(unit) and not UnitIsDead(unit) and UnitGroupRolesAssigned(unit) == "TANK" then
            return unit
        end
    end
    
    -- If no tank found, try to find a melee DPS or return self
    for i = 1, 4 do
        local unit = "party" .. i
        if UnitExists(unit) and not UnitIsDead(unit) and UnitGroupRolesAssigned(unit) == "DAMAGER" then
            -- Simple check for melee classes
            local _, class = UnitClass(unit)
            if class == "WARRIOR" or class == "ROGUE" or class == "DEATHKNIGHT" or class == "MONK" or class == "DEMONHUNTER" then
                return unit
            end
        end
    end
    
    return "player"
end

-- Get injured allies count
function DruidModule:GetInjuredAlliesCount(threshold)
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
function DruidModule:GetAverageGroupHealth()
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

-- Get buff stacks
function API.GetBuffStacks(unit, buff)
    -- Try to use Tinkr's API if available
    if API.IsTinkrLoaded() and Tinkr.Unit then
        return Tinkr.Unit[unit]:Buff(buff):Stacks() or 0
    end
    
    -- Fallback to WoW API
    local name, _, count = API.UnitHasBuff(unit, buff)
    if name then
        return count or 0
    end
    
    return 0
end

-- Get buff remaining
function API.GetBuffRemaining(unit, buff)
    -- Try to use Tinkr's API if available
    if API.IsTinkrLoaded() and Tinkr.Unit then
        return Tinkr.Unit[unit]:Buff(buff):Remains() or 0
    end
    
    -- Fallback to WoW API
    local name, _, _, expires = API.UnitHasBuff(unit, buff)
    if name and expires then
        local remaining = expires - GetTime()
        return remaining > 0 and remaining or 0
    end
    
    return 0
end

-- Should execute rotation
function DruidModule:ShouldExecuteRotation()
    if not isEnabled then
        return false
    end
    
    -- Check if player matches class
    local playerInfo = API.GetPlayerInfo()
    if playerInfo.class ~= "DRUID" then
        return false
    end
    
    return true
end

-- Register for export
WR.Druid = DruidModule

return DruidModule