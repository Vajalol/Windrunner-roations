------------------------------------------
-- WindrunnerRotations - Demon Hunter Class Module
-- Author: VortexQ8
-- The War Within Season 2
------------------------------------------

local addonName, WR = ...
local DemonHunterModule = {}
WR.DemonHunter = DemonHunterModule

-- Dependencies
local API = WR.API
local ConfigRegistry = WR.ConfigRegistry
local RotationManager = WR.RotationManager
local ErrorHandler = WR.ErrorHandler
local CombatAnalysis = WR.CombatAnalysis
local AntiDetectionSystem = WR.AntiDetectionSystem
local PvPManager = WR.PvPManager

-- Demon Hunter constants
local CLASS_ID = 12 -- Demon Hunter class ID
local SPEC_HAVOC = 577
local SPEC_VENGEANCE = 581

-- Current player data
local playerSpec = 0
local isEnabled = true
local inCombat = false

-- Spell IDs for Havoc Demon Hunter (The War Within, Season 2)
local HAVOC_SPELLS = {
    -- Core abilities
    DEMONS_BITE = 162243,
    CHAOS_STRIKE = 162794,
    BLADE_DANCE = 188499,
    DEATH_SWEEP = 210152,
    EYE_BEAM = 198013,
    GLAIVE_TEMPEST = 342817,
    FEL_RUSH = 195072,
    VENGEFUL_RETREAT = 198793,
    THROW_GLAIVE = 185123,
    METAMORPHOSIS = 191427,
    CHAOS_NOVA = 179057,
    FEL_ERUPTION = 211881,
    
    -- Defensive & utility
    BLUR = 198589,
    DARKNESS = 196718,
    NETHERWALK = 196555,
    SPECTRAL_SIGHT = 188501,
    CONSUME_MAGIC = 278326,
    DISRUPT = 183752,
    IMPRISON = 217832,
    
    -- Talents
    FIRST_BLOOD = 206416,
    UNBOUND_CHAOS = 347461,
    CYCLE_OF_HATRED = 258887,
    ESSENCE_BREAK = 258860,
    DEMON_BLADES = 203555,
    MOMENTUM = 206476,
    FELBLADE = 232893,
    DEMONIC = 213410,
    TRAIL_OF_RUIN = 258881,
    IMMOLATION_AURA = 258920,
    
    -- Misc
    GLIDE = 131347,
    FEL_DEVASTATION = 212084,
    CONSUME_SOUL = 228532,
    DOUBLE_JUMP = 198736
}

-- Spell IDs for Vengeance Demon Hunter
local VENGEANCE_SPELLS = {
    -- Core abilities
    SHEAR = 203782,
    FRACTURE = 263642,
    SOUL_CLEAVE = 228477,
    FIERY_BRAND = 204021,
    SIGIL_OF_FLAME = 204596,
    SIGIL_OF_SILENCE = 202137,
    SIGIL_OF_CHAINS = 202138,
    SIGIL_OF_MISERY = 207684,
    IMMOLATION_AURA = 258920,
    INFERNAL_STRIKE = 189110,
    THROW_GLAIVE = 204157,
    METAMORPHOSIS = 187827,
    
    -- Defensive & utility
    DEMON_SPIKES = 203720,
    SOUL_BARRIER = 263648,
    SPECTRAL_SIGHT = 188501,
    CONSUME_MAGIC = 278326,
    DISRUPT = 183752,
    IMPRISON = 217832,
    
    -- Talents
    CHARRED_FLESH = 336639,
    ABYSSAL_STRIKE = 207550,
    AGONIZING_FLAMES = 207548,
    FALLOUT = 227174,
    CONCENTRATED_SIGILS = 207666,
    QUICKENED_SIGILS = 209281,
    SPIRIT_BOMB = 247454,
    VOID_REAVER = 268175,
    FEED_THE_DEMON = 218612,
    FIERY_DEMISE = 212817,
    BULK_EXTRACTION = 320341,
    
    -- Misc
    GLIDE = 131347,
    FEL_DEVASTATION = 212084,
    CONSUME_SOUL = 228532,
    DOUBLE_JUMP = 198736
}

-- Important buffs to track
local BUFFS = {
    IMMOLATION_AURA = 258920,
    METAMORPHOSIS_HAVOC = 162264,
    METAMORPHOSIS_VENGEANCE = 187827,
    CHAOS_BLADES = 247938,
    BLADE_DANCE = 188499,
    DEMON_SPIKES = 203819,
    BLUR = 212800,
    MOMENTUM = 208628,
    PREPARED = 203650,
    DEMONIC = 213410,
    SOUL_FRAGMENTS = 203981,
    FIERY_BRAND = 207771,
    GLUTTONY = 227330,
    NETHERWALK = 196555,
    DARKNESS = 196718,
    UNBOUND_CHAOS = 347462,
    SOUL_BARRIER = 263648
}

-- Important debuffs to track
local DEBUFFS = {
    SIGIL_OF_FLAME = 204598,
    FIERY_BRAND = 207744,
    ESSENCE_BREAK = 320338,
    FRAILTY = 247456,
    VOID_REAVER = 268178,
    FIERY_DEMISE = 212818,
    IMPRISON = 217832
}

-- Initialize the Demon Hunter module
function DemonHunterModule:Initialize()
    -- Register settings
    self:RegisterSettings()
    
    -- Register events
    self:RegisterEvents()
    
    -- Register rotations
    self:RegisterRotations()
    
    API.PrintDebug("Demon Hunter module initialized")
    return true
end

-- Register settings
function DemonHunterModule:RegisterSettings()
    ConfigRegistry:RegisterSettings("DemonHunter", {
        generalSettings = {
            enabled = {
                displayName = "Enable Demon Hunter Module",
                description = "Enable the Demon Hunter module for all specs",
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
            useConsumeMagic = {
                displayName = "Use Consume Magic",
                description = "Automatically dispel buffs from enemies",
                type = "toggle",
                default = true
            },
            useImprison = {
                displayName = "Use Imprison",
                description = "Automatically crowd control targets",
                type = "toggle",
                default = false
            },
            useMovementAbilities = {
                displayName = "Use Movement Abilities",
                description = "Automatically use movement abilities during combat",
                type = "toggle",
                default = true
            }
        },
        havocSettings = {
            useMetamorphosis = {
                displayName = "Use Metamorphosis",
                description = "Use Metamorphosis in combat",
                type = "toggle",
                default = true
            },
            metamorphosisMode = {
                displayName = "Metamorphosis Usage",
                description = "How to use Metamorphosis",
                type = "dropdown",
                options = {"With Cooldowns", "On Cooldown", "Manual Only"},
                default = "With Cooldowns"
            },
            useBlur = {
                displayName = "Use Blur",
                description = "Use Blur at low health",
                type = "toggle",
                default = true
            },
            blurThreshold = {
                displayName = "Blur Health Threshold",
                description = "Health percentage to use Blur",
                type = "slider",
                min = 10,
                max = 60,
                step = 5,
                default = 40
            },
            useDarkness = {
                displayName = "Use Darkness",
                description = "Use Darkness in dangerous situations",
                type = "toggle",
                default = true
            },
            darknessThreshold = {
                displayName = "Darkness Health Threshold",
                description = "Health percentage to use Darkness",
                type = "slider",
                min = 10,
                max = 40,
                step = 5,
                default = 25
            },
            useDemonBlades = {
                displayName = "Use Demon Blades",
                description = "Optimize rotation for Demon Blades talent",
                type = "toggle",
                default = true
            },
            useDemonic = {
                displayName = "Use Demonic",
                description = "Optimize rotation for Demonic talent",
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
                default = 2
            },
            furyCap = {
                displayName = "Fury Cap",
                description = "Fury level to avoid overcapping",
                type = "slider",
                min = 80,
                max = 120,
                step = 5,
                default = 90
            }
        },
        vengeanceSettings = {
            useDemonSpikes = {
                displayName = "Use Demon Spikes",
                description = "Use Demon Spikes for active mitigation",
                type = "toggle",
                default = true
            },
            demonSpikesThreshold = {
                displayName = "Demon Spikes Health Threshold",
                description = "Health percentage to prioritize Demon Spikes",
                type = "slider",
                min = 50,
                max = 95,
                step = 5,
                default = 85
            },
            useFieryBrand = {
                displayName = "Use Fiery Brand",
                description = "Use Fiery Brand at low health",
                type = "toggle",
                default = true
            },
            fieryBrandThreshold = {
                displayName = "Fiery Brand Health Threshold",
                description = "Health percentage to use Fiery Brand",
                type = "slider",
                min = 10,
                max = 70,
                step = 5,
                default = 50
            },
            useMetamorphosis = {
                displayName = "Use Metamorphosis",
                description = "Use Metamorphosis at low health",
                type = "toggle",
                default = true
            },
            metamorphosisThreshold = {
                displayName = "Metamorphosis Health Threshold",
                description = "Health percentage to use Metamorphosis",
                type = "slider",
                min = 10,
                max = 50,
                step = 5,
                default = 30
            },
            useSpiritBomb = {
                displayName = "Use Spirit Bomb",
                description = "Use Spirit Bomb when available",
                type = "toggle",
                default = true
            },
            spiritBombSouls = {
                displayName = "Spirit Bomb Soul Fragments",
                description = "Minimum Soul Fragments to use Spirit Bomb",
                type = "slider",
                min = 1,
                max = 5,
                step = 1,
                default = 4
            },
            soulCleavePriority = {
                displayName = "Soul Cleave Priority",
                description = "Priority for using Soul Cleave",
                type = "dropdown",
                options = {"Damage", "Healing", "Balanced"},
                default = "Balanced"
            },
            aoeThreshold = {
                displayName = "AoE Threshold",
                description = "Number of targets to switch to AoE abilities",
                type = "slider",
                min = 2,
                max = 6,
                step = 1,
                default = 3
            }
        }
    })
    
    -- Add callback for settings changes
    ConfigRegistry:RegisterCallback("DemonHunter", function(settings)
        self:ApplySettings(settings)
    end)
end

-- Apply settings
function DemonHunterModule:ApplySettings(settings)
    -- Apply general settings
    isEnabled = settings.generalSettings.enabled
end

-- Register events
function DemonHunterModule:RegisterEvents()
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
function DemonHunterModule:OnSpecializationChanged()
    -- Get current spec ID
    playerSpec = API.GetActiveSpecID()
    
    API.PrintDebug("Demon Hunter specialization changed: " .. playerSpec)
    
    -- Ensure correct rotation is registered
    if playerSpec == SPEC_HAVOC then
        self:RegisterHavocRotation()
    elseif playerSpec == SPEC_VENGEANCE then
        self:RegisterVengeanceRotation()
    end
end

-- Register rotations
function DemonHunterModule:RegisterRotations()
    -- Register spec-specific rotations
    self:RegisterHavocRotation()
    self:RegisterVengeanceRotation()
end

-- Register Havoc rotation
function DemonHunterModule:RegisterHavocRotation()
    RotationManager:RegisterRotation("DemonHunterHavoc", {
        id = "DemonHunterHavoc",
        name = "Demon Hunter - Havoc",
        class = "DEMONHUNTER",
        spec = SPEC_HAVOC,
        level = 10,
        description = "Havoc Demon Hunter rotation for The War Within Season 2",
        author = "WindrunnerRotations",
        version = "1.0.0",
        rotation = function()
            return self:HavocRotation()
        end
    })
end

-- Register Vengeance rotation
function DemonHunterModule:RegisterVengeanceRotation()
    RotationManager:RegisterRotation("DemonHunterVengeance", {
        id = "DemonHunterVengeance",
        name = "Demon Hunter - Vengeance",
        class = "DEMONHUNTER",
        spec = SPEC_VENGEANCE,
        level = 10,
        description = "Vengeance Demon Hunter rotation for The War Within Season 2",
        author = "WindrunnerRotations",
        version = "1.0.0",
        rotation = function()
            return self:VengeanceRotation()
        end
    })
end

-- Havoc rotation
function DemonHunterModule:HavocRotation()
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
    local settings = ConfigRegistry:GetSettings("DemonHunter")
    
    -- Common Combat Variables
    local health, maxHealth, healthPercent = API.GetUnitHealth(player)
    local targetHealth, targetMaxHealth, targetHealthPercent = API.GetUnitHealth(target)
    local fury = API.GetUnitPower(player, Enum.PowerType.Fury)
    local enemies = API.GetEnemyCount(8)
    local aoeEnabled = settings.havocSettings.aoeThreshold <= enemies
    local hasMeta = API.UnitHasBuff(player, BUFFS.METAMORPHOSIS_HAVOC)
    local hasBlur = API.UnitHasBuff(player, BUFFS.BLUR)
    local hasDarkness = API.UnitHasBuff(player, BUFFS.DARKNESS)
    local hasMomentum = API.UnitHasBuff(player, BUFFS.MOMENTUM)
    local hasPrepared = API.UnitHasBuff(player, BUFFS.PREPARED)
    local hasDemonic = API.UnitHasBuff(player, BUFFS.DEMONIC)
    local hasUnboundChaos = API.UnitHasBuff(player, BUFFS.UNBOUND_CHAOS)
    local hasImmolationAura = API.UnitHasBuff(player, BUFFS.IMMOLATION_AURA)
    local hasEssenceBreak = API.UnitHasDebuff(target, DEBUFFS.ESSENCE_BREAK)
    
    -- Defensive abilities
    if settings.generalSettings.useDefensives then
        -- Blur
        if settings.havocSettings.useBlur and
           healthPercent <= settings.havocSettings.blurThreshold and
           API.IsSpellKnown(HAVOC_SPELLS.BLUR) and 
           API.IsSpellUsable(HAVOC_SPELLS.BLUR) then
            return {
                type = "spell",
                id = HAVOC_SPELLS.BLUR,
                target = player
            }
        end
        
        -- Darkness
        if settings.havocSettings.useDarkness and
           healthPercent <= settings.havocSettings.darknessThreshold and
           API.IsSpellKnown(HAVOC_SPELLS.DARKNESS) and 
           API.IsSpellUsable(HAVOC_SPELLS.DARKNESS) then
            return {
                type = "spell",
                id = HAVOC_SPELLS.DARKNESS,
                target = player
            }
        end
        
        -- Netherwalk at critical health
        if healthPercent < 20 and
           API.IsSpellKnown(HAVOC_SPELLS.NETHERWALK) and 
           API.IsSpellUsable(HAVOC_SPELLS.NETHERWALK) then
            return {
                type = "spell",
                id = HAVOC_SPELLS.NETHERWALK,
                target = player
            }
        end
    end
    
    -- Interrupt if needed
    if settings.generalSettings.useInterrupts and
       API.IsSpellKnown(HAVOC_SPELLS.DISRUPT) and 
       API.IsSpellUsable(HAVOC_SPELLS.DISRUPT) and
       API.ShouldInterrupt(target) then
        return {
            type = "spell",
            id = HAVOC_SPELLS.DISRUPT,
            target = target
        }
    end
    
    -- Dispel if needed
    if settings.generalSettings.useConsumeMagic and
       API.IsSpellKnown(HAVOC_SPELLS.CONSUME_MAGIC) and 
       API.IsSpellUsable(HAVOC_SPELLS.CONSUME_MAGIC) and
       API.ShouldDispel(target) then
        return {
            type = "spell",
            id = HAVOC_SPELLS.CONSUME_MAGIC,
            target = target
        }
    end
    
    -- Offensive cooldowns
    if inCombat then
        -- Metamorphosis
        if settings.havocSettings.useMetamorphosis and
           not hasMeta and not hasDemonic and
           API.IsSpellKnown(HAVOC_SPELLS.METAMORPHOSIS) and 
           API.IsSpellUsable(HAVOC_SPELLS.METAMORPHOSIS) and
           settings.havocSettings.metamorphosisMode ~= "Manual Only" then
            
            local useMeta = false
            if settings.havocSettings.metamorphosisMode == "On Cooldown" then
                useMeta = true
            elseif settings.havocSettings.metamorphosisMode == "With Cooldowns" then
                -- Use with other cooldowns like Essence Break if available
                if API.GetSpellCooldown(HAVOC_SPELLS.ESSENCE_BREAK) < 5 or
                   API.GetSpellCooldown(HAVOC_SPELLS.EYE_BEAM) < 5 then
                    useMeta = true
                end
            end
            
            if useMeta then
                return {
                    type = "spell",
                    id = HAVOC_SPELLS.METAMORPHOSIS,
                    target = player
                }
            end
        end
        
        -- Essence Break if talented
        if API.IsSpellKnown(HAVOC_SPELLS.ESSENCE_BREAK) and 
           API.IsSpellUsable(HAVOC_SPELLS.ESSENCE_BREAK) and
           fury >= 30 then
            return {
                type = "spell",
                id = HAVOC_SPELLS.ESSENCE_BREAK,
                target = target
            }
        end
        
        -- Immolation Aura
        if API.IsSpellKnown(HAVOC_SPELLS.IMMOLATION_AURA) and 
           API.IsSpellUsable(HAVOC_SPELLS.IMMOLATION_AURA) then
            return {
                type = "spell",
                id = HAVOC_SPELLS.IMMOLATION_AURA,
                target = player
            }
        end
        
        -- Eye Beam - triggers Demonic if talented
        if API.IsSpellKnown(HAVOC_SPELLS.EYE_BEAM) and 
           API.IsSpellUsable(HAVOC_SPELLS.EYE_BEAM) and
           fury >= 30 and 
           (enemies >= 2 or settings.havocSettings.useDemonic) then
            return {
                type = "spell",
                id = HAVOC_SPELLS.EYE_BEAM,
                target = target
            }
        end
    end
    
    -- Movement abilities based on settings
    if settings.generalSettings.useMovementAbilities then
        -- Fel Rush with Unbound Chaos buff
        if hasUnboundChaos and
           API.IsSpellKnown(HAVOC_SPELLS.FEL_RUSH) and 
           API.IsSpellUsable(HAVOC_SPELLS.FEL_RUSH) then
            return {
                type = "spell",
                id = HAVOC_SPELLS.FEL_RUSH,
                target = player
            }
        end
        
        -- Vengeful Retreat to activate Prepared/Momentum if talented
        if API.IsSpellKnown(HAVOC_SPELLS.VENGEFUL_RETREAT) and 
           API.IsSpellUsable(HAVOC_SPELLS.VENGEFUL_RETREAT) and
           (not hasMomentum or not hasPrepared) and
           API.IsSpellKnown(HAVOC_SPELLS.MOMENTUM) then
            return {
                type = "spell",
                id = HAVOC_SPELLS.VENGEFUL_RETREAT,
                target = player
            }
        end
        
        -- Fel Rush to maintain Momentum
        if API.IsSpellKnown(HAVOC_SPELLS.MOMENTUM) and
           not hasMomentum and
           API.IsSpellKnown(HAVOC_SPELLS.FEL_RUSH) and 
           API.IsSpellUsable(HAVOC_SPELLS.FEL_RUSH) then
            return {
                type = "spell",
                id = HAVOC_SPELLS.FEL_RUSH,
                target = player
            }
        end
    end
    
    -- AoE rotation
    if aoeEnabled and enemies >= settings.havocSettings.aoeThreshold then
        -- Glaive Tempest
        if API.IsSpellKnown(HAVOC_SPELLS.GLAIVE_TEMPEST) and 
           API.IsSpellUsable(HAVOC_SPELLS.GLAIVE_TEMPEST) and
           fury >= 30 then
            return {
                type = "spell",
                id = HAVOC_SPELLS.GLAIVE_TEMPEST,
                target = target
            }
        end
        
        -- Blade Dance / Death Sweep
        if (hasMeta and API.IsSpellKnown(HAVOC_SPELLS.DEATH_SWEEP) and API.IsSpellUsable(HAVOC_SPELLS.DEATH_SWEEP)) or
           (not hasMeta and API.IsSpellKnown(HAVOC_SPELLS.BLADE_DANCE) and API.IsSpellUsable(HAVOC_SPELLS.BLADE_DANCE)) then
            local spellId = hasMeta and HAVOC_SPELLS.DEATH_SWEEP or HAVOC_SPELLS.BLADE_DANCE
            if fury >= 35 then
                return {
                    type = "spell",
                    id = spellId,
                    target = player
                }
            end
        end
        
        -- Throw Glaive for AoE
        if API.IsSpellKnown(HAVOC_SPELLS.THROW_GLAIVE) and 
           API.IsSpellUsable(HAVOC_SPELLS.THROW_GLAIVE) and
           enemies >= 3 then
            return {
                type = "spell",
                id = HAVOC_SPELLS.THROW_GLAIVE,
                target = target
            }
        end
    end
    
    -- Core single target rotation
    -- Chaos Strike / Annihilation
    if fury >= 40 or fury >= settings.havocSettings.furyCap then
        if API.IsSpellKnown(HAVOC_SPELLS.CHAOS_STRIKE) and 
           API.IsSpellUsable(HAVOC_SPELLS.CHAOS_STRIKE) then
            return {
                type = "spell",
                id = HAVOC_SPELLS.CHAOS_STRIKE,
                target = target
            }
        end
    end
    
    -- Blade Dance / Death Sweep during Essence Break or First Blood
    if hasEssenceBreak or API.IsSpellKnown(HAVOC_SPELLS.FIRST_BLOOD) then
        if (hasMeta and API.IsSpellKnown(HAVOC_SPELLS.DEATH_SWEEP) and API.IsSpellUsable(HAVOC_SPELLS.DEATH_SWEEP)) or
           (not hasMeta and API.IsSpellKnown(HAVOC_SPELLS.BLADE_DANCE) and API.IsSpellUsable(HAVOC_SPELLS.BLADE_DANCE)) then
            local spellId = hasMeta and HAVOC_SPELLS.DEATH_SWEEP or HAVOC_SPELLS.BLADE_DANCE
            if fury >= 35 then
                return {
                    type = "spell",
                    id = spellId,
                    target = player
                }
            end
        end
    end
    
    -- Felblade for fury generation
    if fury < 70 and
       API.IsSpellKnown(HAVOC_SPELLS.FELBLADE) and 
       API.IsSpellUsable(HAVOC_SPELLS.FELBLADE) then
        return {
            type = "spell",
            id = HAVOC_SPELLS.FELBLADE,
            target = target
        }
    end
    
    -- Demon's Bite as filler (if not using Demon Blades)
    if not settings.havocSettings.useDemonBlades or not API.IsSpellKnown(HAVOC_SPELLS.DEMON_BLADES) then
        if API.IsSpellKnown(HAVOC_SPELLS.DEMONS_BITE) and 
           API.IsSpellUsable(HAVOC_SPELLS.DEMONS_BITE) then
            return {
                type = "spell",
                id = HAVOC_SPELLS.DEMONS_BITE,
                target = target
            }
        end
    end
    
    -- Throw Glaive as ranged filler
    if API.IsSpellKnown(HAVOC_SPELLS.THROW_GLAIVE) and 
       API.IsSpellUsable(HAVOC_SPELLS.THROW_GLAIVE) then
        return {
            type = "spell",
            id = HAVOC_SPELLS.THROW_GLAIVE,
            target = target
        }
    end
    
    return nil
end

-- Vengeance rotation
function DemonHunterModule:VengeanceRotation()
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
    local settings = ConfigRegistry:GetSettings("DemonHunter")
    
    -- Common Combat Variables
    local health, maxHealth, healthPercent = API.GetUnitHealth(player)
    local targetHealth, targetMaxHealth, targetHealthPercent = API.GetUnitHealth(target)
    local fury = API.GetUnitPower(player, Enum.PowerType.Fury)
    local enemies = API.GetEnemyCount(8)
    local aoeEnabled = settings.vengeanceSettings.aoeThreshold <= enemies
    local hasDemonSpikes = API.UnitHasBuff(player, BUFFS.DEMON_SPIKES)
    local hasMeta = API.UnitHasBuff(player, BUFFS.METAMORPHOSIS_VENGEANCE)
    local hasFieryBrand = API.UnitHasBuff(player, BUFFS.FIERY_BRAND)
    local targetHasFieryBrand = API.UnitHasDebuff(target, DEBUFFS.FIERY_BRAND)
    local hasSoulBarrier = API.UnitHasBuff(player, BUFFS.SOUL_BARRIER)
    local soulFragments = API.GetBuffStacks(player, BUFFS.SOUL_FRAGMENTS)
    local targetHasSigilOfFlame = API.UnitHasDebuff(target, DEBUFFS.SIGIL_OF_FLAME)
    local targetHasFrailty = API.UnitHasDebuff(target, DEBUFFS.FRAILTY)
    
    -- Interrupt if needed
    if settings.generalSettings.useInterrupts and
       API.IsSpellKnown(VENGEANCE_SPELLS.DISRUPT) and 
       API.IsSpellUsable(VENGEANCE_SPELLS.DISRUPT) and
       API.ShouldInterrupt(target) then
        return {
            type = "spell",
            id = VENGEANCE_SPELLS.DISRUPT,
            target = target
        }
    end
    
    -- Dispel if needed
    if settings.generalSettings.useConsumeMagic and
       API.IsSpellKnown(VENGEANCE_SPELLS.CONSUME_MAGIC) and 
       API.IsSpellUsable(VENGEANCE_SPELLS.CONSUME_MAGIC) and
       API.ShouldDispel(target) then
        return {
            type = "spell",
            id = VENGEANCE_SPELLS.CONSUME_MAGIC,
            target = target
        }
    end
    
    -- Defensive abilities
    if settings.generalSettings.useDefensives then
        -- Critical health Metamorphosis
        if settings.vengeanceSettings.useMetamorphosis and
           healthPercent <= settings.vengeanceSettings.metamorphosisThreshold and
           API.IsSpellKnown(VENGEANCE_SPELLS.METAMORPHOSIS) and 
           API.IsSpellUsable(VENGEANCE_SPELLS.METAMORPHOSIS) then
            return {
                type = "spell",
                id = VENGEANCE_SPELLS.METAMORPHOSIS,
                target = player
            }
        end
        
        -- Fiery Brand for damage reduction
        if settings.vengeanceSettings.useFieryBrand and
           healthPercent <= settings.vengeanceSettings.fieryBrandThreshold and
           not hasFieryBrand and
           API.IsSpellKnown(VENGEANCE_SPELLS.FIERY_BRAND) and 
           API.IsSpellUsable(VENGEANCE_SPELLS.FIERY_BRAND) then
            return {
                type = "spell",
                id = VENGEANCE_SPELLS.FIERY_BRAND,
                target = target
            }
        end
        
        -- Demon Spikes for physical damage mitigation
        if settings.vengeanceSettings.useDemonSpikes and
           healthPercent <= settings.vengeanceSettings.demonSpikesThreshold and
           not hasDemonSpikes and
           API.IsSpellKnown(VENGEANCE_SPELLS.DEMON_SPIKES) and 
           API.IsSpellUsable(VENGEANCE_SPELLS.DEMON_SPIKES) then
            return {
                type = "spell",
                id = VENGEANCE_SPELLS.DEMON_SPIKES,
                target = player
            }
        end
        
        -- Soul Barrier if available
        if healthPercent < 70 and soulFragments >= 2 and
           API.IsSpellKnown(VENGEANCE_SPELLS.SOUL_BARRIER) and 
           API.IsSpellUsable(VENGEANCE_SPELLS.SOUL_BARRIER) then
            return {
                type = "spell",
                id = VENGEANCE_SPELLS.SOUL_BARRIER,
                target = player
            }
        end
    end
    
    -- Maintain Sigil of Flame
    if not targetHasSigilOfFlame and
       API.IsSpellKnown(VENGEANCE_SPELLS.SIGIL_OF_FLAME) and 
       API.IsSpellUsable(VENGEANCE_SPELLS.SIGIL_OF_FLAME) then
        return {
            type = "spell",
            id = VENGEANCE_SPELLS.SIGIL_OF_FLAME,
            target = player
        }
    end
    
    -- Immolation Aura
    if API.IsSpellKnown(VENGEANCE_SPELLS.IMMOLATION_AURA) and 
       API.IsSpellUsable(VENGEANCE_SPELLS.IMMOLATION_AURA) then
        return {
            type = "spell",
            id = VENGEANCE_SPELLS.IMMOLATION_AURA,
            target = player
        }
    end
    
    -- Spirit Bomb if available and we have enough Soul Fragments
    if settings.vengeanceSettings.useSpiritBomb and
       API.IsSpellKnown(VENGEANCE_SPELLS.SPIRIT_BOMB) and 
       API.IsSpellUsable(VENGEANCE_SPELLS.SPIRIT_BOMB) and
       soulFragments >= settings.vengeanceSettings.spiritBombSouls then
        return {
            type = "spell",
            id = VENGEANCE_SPELLS.SPIRIT_BOMB,
            target = target
        }
    end
    
    -- Soul Cleave for healing or spending Fury
    if (fury >= 30 and health < maxHealth) and
       API.IsSpellKnown(VENGEANCE_SPELLS.SOUL_CLEAVE) and 
       API.IsSpellUsable(VENGEANCE_SPELLS.SOUL_CLEAVE) then
        -- Low health prioritizes healing
        local shouldCleave = false
        
        if settings.vengeanceSettings.soulCleavePriority == "Healing" and healthPercent < 70 then
            shouldCleave = true
        elseif settings.vengeanceSettings.soulCleavePriority == "Damage" and fury > 50 then
            shouldCleave = true
        elseif settings.vengeanceSettings.soulCleavePriority == "Balanced" then
            shouldCleave = (healthPercent < 85 or fury > 70)
        end
        
        if shouldCleave then
            return {
                type = "spell",
                id = VENGEANCE_SPELLS.SOUL_CLEAVE,
                target = target
            }
        end
    end
    
    -- Bulk Extraction if talented and we need Soul Fragments
    if API.IsSpellKnown(VENGEANCE_SPELLS.BULK_EXTRACTION) and 
       API.IsSpellUsable(VENGEANCE_SPELLS.BULK_EXTRACTION) and
       soulFragments <= 1 then
        return {
            type = "spell",
            id = VENGEANCE_SPELLS.BULK_EXTRACTION,
            target = player
        }
    end
    
    -- Infernal Strike for mobility and damage
    if settings.generalSettings.useMovementAbilities and
       API.IsSpellKnown(VENGEANCE_SPELLS.INFERNAL_STRIKE) and 
       API.IsSpellUsable(VENGEANCE_SPELLS.INFERNAL_STRIKE) then
        return {
            type = "spell",
            id = VENGEANCE_SPELLS.INFERNAL_STRIKE,
            target = player
        }
    end
    
    -- AoE rotation
    if aoeEnabled and enemies >= settings.vengeanceSettings.aoeThreshold then
        -- Sigil of Chains if multiple enemies
        if API.IsSpellKnown(VENGEANCE_SPELLS.SIGIL_OF_CHAINS) and 
           API.IsSpellUsable(VENGEANCE_SPELLS.SIGIL_OF_CHAINS) and
           enemies >= 3 then
            return {
                type = "spell",
                id = VENGEANCE_SPELLS.SIGIL_OF_CHAINS,
                target = player
            }
        end
    end
    
    -- Fel Devastation for AoE damage and healing
    if API.IsSpellKnown(VENGEANCE_SPELLS.FEL_DEVASTATION) and 
       API.IsSpellUsable(VENGEANCE_SPELLS.FEL_DEVASTATION) and
       fury >= 50 then
        return {
            type = "spell",
            id = VENGEANCE_SPELLS.FEL_DEVASTATION,
            target = player
        }
    end
    
    -- Core single target rotation
    -- Fracture to generate Soul Fragments and Fury
    if API.IsSpellKnown(VENGEANCE_SPELLS.FRACTURE) and 
       API.IsSpellUsable(VENGEANCE_SPELLS.FRACTURE) then
        return {
            type = "spell",
            id = VENGEANCE_SPELLS.FRACTURE,
            target = target
        }
    end
    
    -- Shear as filler (if not using Fracture)
    if not API.IsSpellKnown(VENGEANCE_SPELLS.FRACTURE) and
       API.IsSpellKnown(VENGEANCE_SPELLS.SHEAR) and 
       API.IsSpellUsable(VENGEANCE_SPELLS.SHEAR) then
        return {
            type = "spell",
            id = VENGEANCE_SPELLS.SHEAR,
            target = target
        }
    end
    
    -- Throw Glaive as ranged filler
    if API.IsSpellKnown(VENGEANCE_SPELLS.THROW_GLAIVE) and 
       API.IsSpellUsable(VENGEANCE_SPELLS.THROW_GLAIVE) then
        return {
            type = "spell",
            id = VENGEANCE_SPELLS.THROW_GLAIVE,
            target = target
        }
    end
    
    return nil
end

-- Should execute rotation
function DemonHunterModule:ShouldExecuteRotation()
    if not isEnabled then
        return false
    end
    
    -- Check if player matches class
    local playerInfo = API.GetPlayerInfo()
    if playerInfo.class ~= "DEMONHUNTER" then
        return false
    end
    
    return true
end

-- Should interrupt
function API.ShouldInterrupt(unit)
    -- This would be implemented with proper spell checking
    -- For now, we'll just check if unit is casting
    if API.IsTinkrLoaded() and Tinkr.Unit then
        return Tinkr.Unit[unit]:IsCasting() and Tinkr.Unit[unit]:CastTimeRemaining() > 0.1
    end
    
    -- Basic check if unit is casting something interruptible
    local _, _, _, _, _, _, _, notInterruptible = UnitCastingInfo(unit)
    return UnitCastingInfo(unit) and not notInterruptible
end

-- Should dispel
function API.ShouldDispel(unit)
    -- This would be implemented with proper buff checking
    -- For now, we'll just return false
    return false
end

-- Register for export
WR.DemonHunter = DemonHunterModule

return DemonHunterModule