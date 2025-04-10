local addonName, WR = ...

-- Shaman Class module
local Shaman = {}
WR.Classes = WR.Classes or {}
WR.Classes.SHAMAN = Shaman

-- Inherit from BaseClass
setmetatable(Shaman, {__index = WR.BaseClass})

-- Resource type for Shamans (Mana/Maelstrom)
Shaman.resourceType = Enum.PowerType.Mana
Shaman.secondaryResourceType = nil

-- Define spec IDs
local SPEC_ELEMENTAL = 262
local SPEC_ENHANCEMENT = 263
local SPEC_RESTORATION = 264

-- Class initialization
function Shaman:Initialize()
    -- Inherit base initialization
    WR.BaseClass.Initialize(self)
    
    -- Register Specializations
    self:RegisterSpec(SPEC_ELEMENTAL, "Elemental")
    self:RegisterSpec(SPEC_ENHANCEMENT, "Enhancement")
    self:RegisterSpec(SPEC_RESTORATION, "Restoration")
    
    -- Shared spell IDs across all shaman specs
    self.spells = {
        -- Core shaman abilities
        FLAME_SHOCK = 188389,
        LIGHTNING_BOLT = 188196,
        GHOST_WOLF = 2645,
        PURGE = 370,
        WIND_SHEAR = 57994,
        ASTRAL_SHIFT = 108271,
        LIGHTNING_SHIELD = 192106,
        EARTH_SHIELD = 974,
        WATER_SHIELD = 52127,
        EARTH_ELEMENTAL = 198103,
        TREMOR_TOTEM = 8143,
        CAPACITOR_TOTEM = 192058,
        EARTHBIND_TOTEM = 2484,
        ANCESTRAL_SPIRIT = 2008,
        CLEANSE_SPIRIT = 51886,
        PURIFY_SPIRIT = 77130,
        FROST_SHOCK = 196840,
        EARTH_SHOCK = 8042,
        CHAIN_LIGHTNING = 188443,
        CHAIN_HEAL = 1064,
        HEALING_SURGE = 8004,
        WATER_WALKING = 546,
        FAR_SIGHT = 6196,
        HEALING_STREAM_TOTEM = 5394,
        BLOODLUST = 2825,
        HEROISM = 32182,
        PRIMAL_STRIKE = 73899,
        HEX = 51514,
        
        -- Covenant abilities
        VESPER_TOTEM = 324386,     -- Kyrian
        PRIMORDIAL_WAVE = 326059,  -- Necrolord
        FAE_TRANSFUSION = 328923,  -- Night Fae
        CHAIN_HARVEST = 320674     -- Venthyr
    }
    
    -- Load shared shaman data
    self:LoadSharedShamanData()
    
    WR:Debug("Shaman module initialized")
end

-- Load shared spell and mechanics data for all shaman specs
function Shaman:LoadSharedShamanData()
    -- Register important buffs
    WR.Auras:RegisterImportantAura(self.spells.LIGHTNING_SHIELD, 75, true, false)
    WR.Auras:RegisterImportantAura(self.spells.EARTH_SHIELD, 80, true, false)
    WR.Auras:RegisterImportantAura(self.spells.WATER_SHIELD, 75, true, false)
    WR.Auras:RegisterImportantAura(self.spells.GHOST_WOLF, 70, true, false)
    WR.Auras:RegisterImportantAura(self.spells.FLAME_SHOCK, 90, false, true)
    WR.Auras:RegisterImportantAura(self.spells.BLOODLUST, 99, true, false)
    WR.Auras:RegisterImportantAura(self.spells.HEROISM, 99, true, false)
    
    -- Setup cooldown tracking
    WR.Cooldown:StartTracking(self.spells.ASTRAL_SHIFT)
    WR.Cooldown:StartTracking(self.spells.CAPACITOR_TOTEM)
    WR.Cooldown:StartTracking(self.spells.EARTHBIND_TOTEM)
    WR.Cooldown:StartTracking(self.spells.EARTH_ELEMENTAL)
    WR.Cooldown:StartTracking(self.spells.TREMOR_TOTEM)
    WR.Cooldown:StartTracking(self.spells.WIND_SHEAR)
    WR.Cooldown:StartTracking(self.spells.BLOODLUST)
    WR.Cooldown:StartTracking(self.spells.HEROISM)
    WR.Cooldown:StartTracking(self.spells.HEX)
    
    -- Set up the interrupt spell
    self.interruptRotation = {
        { spell = self.spells.WIND_SHEAR }
    }
    
    -- Set up defensive rotation (shared by all specs)
    self.defensiveRotation = {
        { spell = self.spells.ASTRAL_SHIFT, threshold = 40 },
        {
            spell = self.spells.EARTH_ELEMENTAL,
            threshold = 30,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.EARTH_ELEMENTAL)
            end
        }
    }
end

-- Load a specific specialization
function Shaman:LoadSpec(specId)
    -- Call the base class method to set up common components
    WR.BaseClass.LoadSpec(self, specId)
    
    -- Set the resource type based on spec
    if specId == SPEC_ELEMENTAL then
        self.resourceType = Enum.PowerType.Maelstrom
        self.secondaryResourceType = nil
    elseif specId == SPEC_ENHANCEMENT then
        self.resourceType = Enum.PowerType.Maelstrom
        self.secondaryResourceType = nil
    elseif specId == SPEC_RESTORATION then
        self.resourceType = Enum.PowerType.Mana
        self.secondaryResourceType = nil
    end
    
    -- Load specific spec data
    if specId == SPEC_ELEMENTAL then
        self:LoadElementalSpec()
    elseif specId == SPEC_ENHANCEMENT then
        self:LoadEnhancementSpec()
    elseif specId == SPEC_RESTORATION then
        self:LoadRestorationSpec()
    end
    
    WR:Debug("Loaded shaman spec:", self.specData.name)
    return true
end

-- Load Elemental specialization
function Shaman:LoadElementalSpec()
    -- Elemental-specific spells
    self.spells.LAVA_BURST = 51505
    self.spells.ELEMENTAL_BLAST = 117014
    self.spells.EARTHQUAKE = 61882
    self.spells.FIRE_ELEMENTAL = 198067
    self.spells.STORM_ELEMENTAL = 192249
    self.spells.ICEFURY = 210714
    self.spells.LIQUID_MAGMA_TOTEM = 192222
    self.spells.ECHOING_SHOCK = 320125
    self.spells.STORMKEEPER = 191634
    self.spells.MASTER_OF_THE_ELEMENTS = 16166
    self.spells.SURGE_OF_POWER = 262303
    self.spells.AFTERSHOCK = 273221
    self.spells.ASCENDANCE = 114050
    self.spells.UNLIMITED_POWER = 260895
    self.spells.LAVA_SURGE = 77756
    self.spells.ECHO_OF_THE_ELEMENTS = 333919
    self.spells.STATIC_DISCHARGE = 342243
    self.spells.ECHOES_OF_GREAT_SUNDERING = 336215
    self.spells.ANCESTRAL_GUIDANCE = 108281
    
    -- Setup cooldown and aura tracking for Elemental
    WR.Cooldown:StartTracking(self.spells.LAVA_BURST)
    WR.Cooldown:StartTracking(self.spells.ELEMENTAL_BLAST)
    WR.Cooldown:StartTracking(self.spells.FIRE_ELEMENTAL)
    WR.Cooldown:StartTracking(self.spells.STORM_ELEMENTAL)
    WR.Cooldown:StartTracking(self.spells.LIQUID_MAGMA_TOTEM)
    WR.Cooldown:StartTracking(self.spells.ICEFURY)
    WR.Cooldown:StartTracking(self.spells.ECHOING_SHOCK)
    WR.Cooldown:StartTracking(self.spells.STORMKEEPER)
    WR.Cooldown:StartTracking(self.spells.ASCENDANCE)
    WR.Cooldown:StartTracking(self.spells.STATIC_DISCHARGE)
    WR.Cooldown:StartTracking(self.spells.ANCESTRAL_GUIDANCE)
    
    -- Track important buffs/debuffs
    WR.Auras:RegisterImportantAura(self.spells.LAVA_SURGE, 80, true, false)
    WR.Auras:RegisterImportantAura(self.spells.MASTER_OF_THE_ELEMENTS, 85, true, false)
    WR.Auras:RegisterImportantAura(self.spells.ASCENDANCE, 90, true, false)
    WR.Auras:RegisterImportantAura(self.spells.STORMKEEPER, 90, true, false)
    WR.Auras:RegisterImportantAura(self.spells.ICEFURY, 85, true, false)
    WR.Auras:RegisterImportantAura(self.spells.UNLIMITED_POWER, 80, true, false)
    WR.Auras:RegisterImportantAura(self.spells.ECHOES_OF_GREAT_SUNDERING, 80, true, false)
    
    -- Define Elemental single target rotation
    self.singleTargetRotation = {
        -- Maintain Flame Shock
        {
            spell = self.spells.FLAME_SHOCK,
            condition = function(self)
                return not self:HasDebuff(self.spells.FLAME_SHOCK) or
                       self:GetDebuffRemaining(self.spells.FLAME_SHOCK) < 5.4
            end
        },
        
        -- Use Fire/Storm Elemental
        {
            spell = self.spells.STORM_ELEMENTAL,
            condition = function(self)
                return IsSpellKnown(self.spells.STORM_ELEMENTAL) and
                       not self:SpellOnCooldown(self.spells.STORM_ELEMENTAL)
            end
        },
        {
            spell = self.spells.FIRE_ELEMENTAL,
            condition = function(self)
                return not IsSpellKnown(self.spells.STORM_ELEMENTAL) and
                       not self:SpellOnCooldown(self.spells.FIRE_ELEMENTAL)
            end
        },
        
        -- Use Ascendance if talented
        {
            spell = self.spells.ASCENDANCE,
            condition = function(self)
                return IsSpellKnown(self.spells.ASCENDANCE) and
                       not self:SpellOnCooldown(self.spells.ASCENDANCE)
            end
        },
        
        -- Use covenant abilities
        { 
            spell = self.spells.VESPER_TOTEM,
            condition = function(self) return IsSpellKnown(self.spells.VESPER_TOTEM) end
        },
        { 
            spell = self.spells.PRIMORDIAL_WAVE,
            condition = function(self) return IsSpellKnown(self.spells.PRIMORDIAL_WAVE) end
        },
        { 
            spell = self.spells.FAE_TRANSFUSION,
            condition = function(self) return IsSpellKnown(self.spells.FAE_TRANSFUSION) end
        },
        { 
            spell = self.spells.CHAIN_HARVEST,
            condition = function(self) return IsSpellKnown(self.spells.CHAIN_HARVEST) end
        },
        
        -- Use Stormkeeper for burst
        {
            spell = self.spells.STORMKEEPER,
            condition = function(self)
                return IsSpellKnown(self.spells.STORMKEEPER) and
                       not self:SpellOnCooldown(self.spells.STORMKEEPER)
            end
        },
        
        -- Use Liquid Magma Totem if talented
        {
            spell = self.spells.LIQUID_MAGMA_TOTEM,
            condition = function(self)
                return IsSpellKnown(self.spells.LIQUID_MAGMA_TOTEM) and
                       not self:SpellOnCooldown(self.spells.LIQUID_MAGMA_TOTEM)
            end
        },
        
        -- Use Echoing Shock if talented
        {
            spell = self.spells.ECHOING_SHOCK,
            condition = function(self)
                return IsSpellKnown(self.spells.ECHOING_SHOCK) and
                       not self:SpellOnCooldown(self.spells.ECHOING_SHOCK)
            end
        },
        
        -- Use Lava Burst with Lava Surge proc or on cooldown
        {
            spell = self.spells.LAVA_BURST,
            condition = function(self)
                return self:HasBuff(self.spells.LAVA_SURGE) or
                       not self:SpellOnCooldown(self.spells.LAVA_BURST)
            end
        },
        
        -- Use Elemental Blast if talented
        {
            spell = self.spells.ELEMENTAL_BLAST,
            condition = function(self)
                return IsSpellKnown(self.spells.ELEMENTAL_BLAST) and
                       not self:SpellOnCooldown(self.spells.ELEMENTAL_BLAST)
            end
        },
        
        -- Use Icefury if talented
        {
            spell = self.spells.ICEFURY,
            condition = function(self)
                return IsSpellKnown(self.spells.ICEFURY) and
                       not self:SpellOnCooldown(self.spells.ICEFURY)
            end
        },
        
        -- Use Frost Shock with Icefury buff
        {
            spell = self.spells.FROST_SHOCK,
            condition = function(self)
                return self:HasBuff(self.spells.ICEFURY)
            end
        },
        
        -- Use Earth Shock with enough Maelstrom
        {
            spell = self.spells.EARTH_SHOCK,
            condition = function(self)
                return self:GetMaelstrom() >= 60 and
                       not IsSpellKnown(self.spells.ELEMENTAL_BLAST)
            end
        },
        
        -- Use Static Discharge if talented
        {
            spell = self.spells.STATIC_DISCHARGE,
            condition = function(self)
                return IsSpellKnown(self.spells.STATIC_DISCHARGE) and
                       not self:SpellOnCooldown(self.spells.STATIC_DISCHARGE)
            end
        },
        
        -- Use Lightning Bolt as filler
        { spell = self.spells.LIGHTNING_BOLT }
    }
    
    -- AoE rotation for Elemental
    self.aoeRotation = {
        -- Maintain Flame Shock on multiple targets
        {
            spell = self.spells.FLAME_SHOCK,
            condition = function(self)
                return not self:HasDebuff(self.spells.FLAME_SHOCK) or
                       self:GetDebuffRemaining(self.spells.FLAME_SHOCK) < 5.4
            end
        },
        
        -- Use Fire/Storm Elemental for AoE
        {
            spell = self.spells.STORM_ELEMENTAL,
            condition = function(self)
                return IsSpellKnown(self.spells.STORM_ELEMENTAL) and
                       not self:SpellOnCooldown(self.spells.STORM_ELEMENTAL) and
                       self:GetEnemyCount(10) >= 3
            end
        },
        {
            spell = self.spells.FIRE_ELEMENTAL,
            condition = function(self)
                return not IsSpellKnown(self.spells.STORM_ELEMENTAL) and
                       not self:SpellOnCooldown(self.spells.FIRE_ELEMENTAL) and
                       self:GetEnemyCount(10) >= 3
            end
        },
        
        -- Use covenant abilities for AoE
        { 
            spell = self.spells.VESPER_TOTEM,
            condition = function(self) return IsSpellKnown(self.spells.VESPER_TOTEM) end
        },
        { 
            spell = self.spells.CHAIN_HARVEST,
            condition = function(self) return IsSpellKnown(self.spells.CHAIN_HARVEST) end
        },
        
        -- Use Stormkeeper for AoE burst
        {
            spell = self.spells.STORMKEEPER,
            condition = function(self)
                return IsSpellKnown(self.spells.STORMKEEPER) and
                       not self:SpellOnCooldown(self.spells.STORMKEEPER) and
                       self:GetEnemyCount(10) >= 3
            end
        },
        
        -- Use Liquid Magma Totem for AoE
        {
            spell = self.spells.LIQUID_MAGMA_TOTEM,
            condition = function(self)
                return IsSpellKnown(self.spells.LIQUID_MAGMA_TOTEM) and
                       not self:SpellOnCooldown(self.spells.LIQUID_MAGMA_TOTEM) and
                       self:GetEnemyCount(10) >= 3
            end
        },
        
        -- Use Earthquake with enough Maelstrom
        {
            spell = self.spells.EARTHQUAKE,
            condition = function(self)
                return self:GetEnemyCount(10) >= 3 and
                       self:GetMaelstrom() >= 60
            end
        },
        
        -- Use Chain Lightning for AoE
        {
            spell = self.spells.CHAIN_LIGHTNING,
            condition = function(self)
                return self:GetEnemyCount(10) >= 2
            end
        },
        
        -- Fallback to single target rotation
        {
            spell = self.spells.LAVA_BURST,
            condition = function(self)
                return self:HasBuff(self.spells.LAVA_SURGE) or
                       not self:SpellOnCooldown(self.spells.LAVA_BURST)
            end
        },
        
        -- Use Lightning Bolt as filler
        { spell = self.spells.LIGHTNING_BOLT }
    }
    
    -- Define burst rotation
    self.burstRotation = {
        {
            spell = self.spells.STORM_ELEMENTAL,
            condition = function(self) return IsSpellKnown(self.spells.STORM_ELEMENTAL) end
        },
        {
            spell = self.spells.FIRE_ELEMENTAL,
            condition = function(self) return not IsSpellKnown(self.spells.STORM_ELEMENTAL) end
        },
        {
            spell = self.spells.ASCENDANCE,
            condition = function(self) return IsSpellKnown(self.spells.ASCENDANCE) end
        },
        { spell = self.spells.STORMKEEPER },
        { 
            spell = self.spells.VESPER_TOTEM,
            condition = function(self) return IsSpellKnown(self.spells.VESPER_TOTEM) end
        },
        { 
            spell = self.spells.CHAIN_HARVEST,
            condition = function(self) return IsSpellKnown(self.spells.CHAIN_HARVEST) end
        }
    }
    
    -- Add Elemental-specific defensive abilities
    table.insert(self.defensiveRotation, {
        spell = self.spells.ANCESTRAL_GUIDANCE,
        threshold = 60,
        condition = function(self)
            return IsSpellKnown(self.spells.ANCESTRAL_GUIDANCE)
        end
    })
end

-- Load Enhancement specialization
function Shaman:LoadEnhancementSpec()
    -- Enhancement-specific spells
    self.spells.STORMSTRIKE = 17364
    self.spells.LAVA_LASH = 60103
    self.spells.CRASH_LIGHTNING = 187874
    self.spells.FERAL_SPIRIT = 51533
    self.spells.WINDFURY_TOTEM = 8512
    self.spells.WINDFURY_WEAPON = 33757
    self.spells.FLAMETONGUE_WEAPON = 318038
    self.spells.FROSTBRAND_WEAPON = 196834
    self.spells.ASCENDANCE = 114051
    self.spells.SUNDERING = 197214
    self.spells.SPIRIT_WALK = 58875
    self.spells.STORMFLURRY = 344357
    self.spells.HOT_HAND = 201900
    self.spells.WIND_STRIKE = 115356
    self.spells.FORCEFUL_WINDS = 262647
    self.spells.HAILSTORM = 334195
    self.spells.ELEMENTAL_ASSAULT = 210853
    self.spells.EARTHEN_SPIKE = 188089
    self.spells.FERAL_LUNGE = 196884
    self.spells.LIGHTNING_SHIELD = 192106
    self.spells.ALPHA_WOLF = 198434
    self.spells.CRACKLING_SURGE = 224127
    
    -- Setup cooldown and aura tracking for Enhancement
    WR.Cooldown:StartTracking(self.spells.STORMSTRIKE)
    WR.Cooldown:StartTracking(self.spells.LAVA_LASH)
    WR.Cooldown:StartTracking(self.spells.CRASH_LIGHTNING)
    WR.Cooldown:StartTracking(self.spells.FERAL_SPIRIT)
    WR.Cooldown:StartTracking(self.spells.WINDFURY_TOTEM)
    WR.Cooldown:StartTracking(self.spells.ASCENDANCE)
    WR.Cooldown:StartTracking(self.spells.SUNDERING)
    WR.Cooldown:StartTracking(self.spells.SPIRIT_WALK)
    WR.Cooldown:StartTracking(self.spells.FERAL_LUNGE)
    WR.Cooldown:StartTracking(self.spells.EARTHEN_SPIKE)
    
    -- Track important buffs/debuffs
    WR.Auras:RegisterImportantAura(self.spells.WINDFURY_WEAPON, 95, true, false)
    WR.Auras:RegisterImportantAura(self.spells.FLAMETONGUE_WEAPON, 95, true, false)
    WR.Auras:RegisterImportantAura(self.spells.FROSTBRAND_WEAPON, 85, true, false)
    WR.Auras:RegisterImportantAura(self.spells.WINDFURY_TOTEM, 90, true, false)
    WR.Auras:RegisterImportantAura(self.spells.HOT_HAND, 80, true, false)
    WR.Auras:RegisterImportantAura(self.spells.ASCENDANCE, 90, true, false)
    WR.Auras:RegisterImportantAura(self.spells.STORMFLURRY, 80, true, false)
    WR.Auras:RegisterImportantAura(self.spells.CRASH_LIGHTNING, 80, true, false)
    WR.Auras:RegisterImportantAura(self.spells.LIGHTNING_SHIELD, 80, true, false)
    WR.Auras:RegisterImportantAura(self.spells.ALPHA_WOLF, 80, true, false)
    
    -- Define Enhancement single target rotation
    self.singleTargetRotation = {
        -- Maintain weapon enchants
        {
            spell = self.spells.WINDFURY_WEAPON,
            condition = function(self)
                return not self:HasBuff(self.spells.WINDFURY_WEAPON, "mainhand")
            end
        },
        {
            spell = self.spells.FLAMETONGUE_WEAPON,
            condition = function(self)
                return not self:HasBuff(self.spells.FLAMETONGUE_WEAPON, "offhand")
            end
        },
        {
            spell = self.spells.FROSTBRAND_WEAPON,
            condition = function(self)
                return IsSpellKnown(self.spells.HAILSTORM) and
                       not self:HasBuff(self.spells.FROSTBRAND_WEAPON)
            end
        },
        
        -- Maintain Windfury Totem
        {
            spell = self.spells.WINDFURY_TOTEM,
            condition = function(self)
                return not self:HasBuff(self.spells.WINDFURY_TOTEM)
            end
        },
        
        -- Maintain Flame Shock if not in AoE situation
        {
            spell = self.spells.FLAME_SHOCK,
            condition = function(self)
                return (not self:HasDebuff(self.spells.FLAME_SHOCK) or
                        self:GetDebuffRemaining(self.spells.FLAME_SHOCK) < 5.4) and
                       self:GetEnemyCount(8) < 3
            end
        },
        
        -- Use Feral Spirit on cooldown
        {
            spell = self.spells.FERAL_SPIRIT,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.FERAL_SPIRIT)
            end
        },
        
        -- Use covenant abilities
        { 
            spell = self.spells.VESPER_TOTEM,
            condition = function(self) return IsSpellKnown(self.spells.VESPER_TOTEM) end
        },
        { 
            spell = self.spells.PRIMORDIAL_WAVE,
            condition = function(self) return IsSpellKnown(self.spells.PRIMORDIAL_WAVE) end
        },
        { 
            spell = self.spells.FAE_TRANSFUSION,
            condition = function(self) return IsSpellKnown(self.spells.FAE_TRANSFUSION) end
        },
        { 
            spell = self.spells.CHAIN_HARVEST,
            condition = function(self) return IsSpellKnown(self.spells.CHAIN_HARVEST) end
        },
        
        -- Use Ascendance if talented
        {
            spell = self.spells.ASCENDANCE,
            condition = function(self)
                return IsSpellKnown(self.spells.ASCENDANCE) and
                       not self:SpellOnCooldown(self.spells.ASCENDANCE)
            end
        },
        
        -- Use Earthen Spike if talented
        {
            spell = self.spells.EARTHEN_SPIKE,
            condition = function(self)
                return IsSpellKnown(self.spells.EARTHEN_SPIKE) and
                       not self:SpellOnCooldown(self.spells.EARTHEN_SPIKE)
            end
        },
        
        -- Use Sundering if talented
        {
            spell = self.spells.SUNDERING,
            condition = function(self)
                return IsSpellKnown(self.spells.SUNDERING) and
                       not self:SpellOnCooldown(self.spells.SUNDERING)
            end
        },
        
        -- Use Stormstrike / Windstrike
        {
            spell = self.spells.WIND_STRIKE,
            condition = function(self)
                return self:HasBuff(self.spells.ASCENDANCE) and
                       not self:SpellOnCooldown(self.spells.STORMSTRIKE)
            end
        },
        {
            spell = self.spells.STORMSTRIKE,
            condition = function(self)
                return not self:HasBuff(self.spells.ASCENDANCE) and
                       not self:SpellOnCooldown(self.spells.STORMSTRIKE)
            end
        },
        
        -- Use Lava Lash, especially with Hot Hand proc
        {
            spell = self.spells.LAVA_LASH,
            condition = function(self)
                return self:HasBuff(self.spells.HOT_HAND) or
                       not self:SpellOnCooldown(self.spells.LAVA_LASH)
            end
        },
        
        -- Use Crash Lightning to buff Stormstrike
        {
            spell = self.spells.CRASH_LIGHTNING,
            condition = function(self)
                return not self:HasBuff(self.spells.CRASH_LIGHTNING) and
                       not self:SpellOnCooldown(self.spells.CRASH_LIGHTNING)
            end
        },
        
        -- Use Frost Shock with Frostbrand active
        {
            spell = self.spells.FROST_SHOCK,
            condition = function(self)
                return IsSpellKnown(self.spells.HAILSTORM) and
                       self:HasBuff(self.spells.FROSTBRAND_WEAPON) and
                       self:GetMaelstrom() >= 20
            end
        },
        
        -- Use Flame Shock for Maelstrom spending
        {
            spell = self.spells.FLAME_SHOCK,
            condition = function(self)
                return self:GetMaelstrom() >= 20 and
                       not IsSpellKnown(self.spells.HAILSTORM)
            end
        },
        
        -- Use Lightning Bolt with active Maelstrom Weapon stacks
        {
            spell = self.spells.LIGHTNING_BOLT,
            condition = function(self)
                return self:GetMaelstromWeaponStacks() >= 5
            end
        },
        
        -- Use Crash Lightning as filler
        {
            spell = self.spells.CRASH_LIGHTNING,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.CRASH_LIGHTNING)
            end
        },
        
        -- Use Frost Shock as filler
        { spell = self.spells.FROST_SHOCK }
    }
    
    -- AoE rotation for Enhancement
    self.aoeRotation = {
        -- Maintain weapon enchants
        {
            spell = self.spells.WINDFURY_WEAPON,
            condition = function(self)
                return not self:HasBuff(self.spells.WINDFURY_WEAPON, "mainhand")
            end
        },
        {
            spell = self.spells.FLAMETONGUE_WEAPON,
            condition = function(self)
                return not self:HasBuff(self.spells.FLAMETONGUE_WEAPON, "offhand")
            end
        },
        
        -- Maintain Windfury Totem
        {
            spell = self.spells.WINDFURY_TOTEM,
            condition = function(self)
                return not self:HasBuff(self.spells.WINDFURY_TOTEM)
            end
        },
        
        -- Use Feral Spirit for AoE
        {
            spell = self.spells.FERAL_SPIRIT,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.FERAL_SPIRIT) and
                       self:GetEnemyCount(8) >= 3
            end
        },
        
        -- Use covenant abilities for AoE
        { 
            spell = self.spells.VESPER_TOTEM,
            condition = function(self) return IsSpellKnown(self.spells.VESPER_TOTEM) end
        },
        { 
            spell = self.spells.CHAIN_HARVEST,
            condition = function(self) return IsSpellKnown(self.spells.CHAIN_HARVEST) end
        },
        
        -- Use Sundering for AoE
        {
            spell = self.spells.SUNDERING,
            condition = function(self)
                return IsSpellKnown(self.spells.SUNDERING) and
                       not self:SpellOnCooldown(self.spells.SUNDERING) and
                       self:GetEnemyCount(8) >= 3
            end
        },
        
        -- Use Crash Lightning for AoE
        {
            spell = self.spells.CRASH_LIGHTNING,
            condition = function(self)
                return self:GetEnemyCount(8) >= 2 and
                       not self:SpellOnCooldown(self.spells.CRASH_LIGHTNING)
            end
        },
        
        -- Use Lava Lash for AoE spread
        {
            spell = self.spells.LAVA_LASH,
            condition = function(self)
                return self:HasDebuff(self.spells.FLAME_SHOCK) and
                       self:GetEnemyCount(8) >= 3
            end
        },
        
        -- Use Stormstrike / Windstrike in AoE
        {
            spell = self.spells.WIND_STRIKE,
            condition = function(self)
                return self:HasBuff(self.spells.ASCENDANCE) and
                       not self:SpellOnCooldown(self.spells.STORMSTRIKE)
            end
        },
        {
            spell = self.spells.STORMSTRIKE,
            condition = function(self)
                return not self:HasBuff(self.spells.ASCENDANCE) and
                       not self:SpellOnCooldown(self.spells.STORMSTRIKE)
            end
        },
        
        -- Use Flame Shock to spread for AoE
        {
            spell = self.spells.FLAME_SHOCK,
            condition = function(self)
                return (not self:HasDebuff(self.spells.FLAME_SHOCK) or
                        self:GetDebuffRemaining(self.spells.FLAME_SHOCK) < 5.4) and
                       self:GetMaelstrom() >= 20
            end
        },
        
        -- Use Lightning Bolt with active Maelstrom Weapon stacks
        {
            spell = self.spells.CHAIN_LIGHTNING,
            condition = function(self)
                return self:GetMaelstromWeaponStacks() >= 5 and
                       self:GetEnemyCount(8) >= 2
            end
        },
        
        -- Use Frost Shock as filler
        { spell = self.spells.FROST_SHOCK }
    }
    
    -- Define burst rotation
    self.burstRotation = {
        {
            spell = self.spells.ASCENDANCE,
            condition = function(self) return IsSpellKnown(self.spells.ASCENDANCE) end
        },
        { spell = self.spells.FERAL_SPIRIT },
        { 
            spell = self.spells.VESPER_TOTEM,
            condition = function(self) return IsSpellKnown(self.spells.VESPER_TOTEM) end
        },
        { 
            spell = self.spells.CHAIN_HARVEST,
            condition = function(self) return IsSpellKnown(self.spells.CHAIN_HARVEST) end
        },
        {
            spell = self.spells.EARTHEN_SPIKE,
            condition = function(self) return IsSpellKnown(self.spells.EARTHEN_SPIKE) end
        },
        { spell = self.spells.CRASH_LIGHTNING },
        { spell = self.spells.STORMSTRIKE }
    }
    
    -- Add Enhancement-specific defensive abilities
    table.insert(self.defensiveRotation, {
        spell = self.spells.SPIRIT_WALK,
        threshold = 50,
        condition = function(self)
            return IsSpellKnown(self.spells.SPIRIT_WALK)
        end
    })
end

-- Load Restoration specialization
function Shaman:LoadRestorationSpec()
    -- Restoration-specific spells
    self.spells.RIPTIDE = 61295
    self.spells.HEALING_RAIN = 73920
    self.spells.HEALING_TIDE_TOTEM = 108280
    self.spells.SPIRIT_LINK_TOTEM = 98008
    self.spells.HEALING_STREAM_TOTEM = 5394
    self.spells.MANA_TIDE_TOTEM = 16191
    self.spells.CLOUDBURST_TOTEM = 157153
    self.spells.ASCENDANCE = 114052
    self.spells.WELLSPRING = 197995
    self.spells.EARTHEN_WALL_TOTEM = 198838
    self.spells.EARTH_SHIELD = 974
    self.spells.DOWNPOUR = 207778
    self.spells.HIGH_TIDE = 157154
    self.spells.DELUGE = 200076
    self.spells.UNLEASH_LIFE = 73685
    self.spells.ECHO_OF_THE_ELEMENTS = 108283
    self.spells.HEALING_WAVE = 77472
    self.spells.TIDAL_WAVES = 53390
    self.spells.UNDULATION = 200071
    self.spells.SURGE_OF_EARTH = 320746
    
    -- Setup cooldown and aura tracking for Restoration
    WR.Cooldown:StartTracking(self.spells.RIPTIDE)
    WR.Cooldown:StartTracking(self.spells.HEALING_RAIN)
    WR.Cooldown:StartTracking(self.spells.HEALING_TIDE_TOTEM)
    WR.Cooldown:StartTracking(self.spells.SPIRIT_LINK_TOTEM)
    WR.Cooldown:StartTracking(self.spells.HEALING_STREAM_TOTEM)
    WR.Cooldown:StartTracking(self.spells.MANA_TIDE_TOTEM)
    WR.Cooldown:StartTracking(self.spells.CLOUDBURST_TOTEM)
    WR.Cooldown:StartTracking(self.spells.ASCENDANCE)
    WR.Cooldown:StartTracking(self.spells.WELLSPRING)
    WR.Cooldown:StartTracking(self.spells.EARTHEN_WALL_TOTEM)
    WR.Cooldown:StartTracking(self.spells.DOWNPOUR)
    WR.Cooldown:StartTracking(self.spells.UNLEASH_LIFE)
    
    -- Track important buffs/debuffs
    WR.Auras:RegisterImportantAura(self.spells.EARTH_SHIELD, 90, true, false)
    WR.Auras:RegisterImportantAura(self.spells.RIPTIDE, 85, true, false)
    WR.Auras:RegisterImportantAura(self.spells.TIDAL_WAVES, 80, true, false)
    WR.Auras:RegisterImportantAura(self.spells.ASCENDANCE, 90, true, false)
    WR.Auras:RegisterImportantAura(self.spells.UNLEASH_LIFE, 80, true, false)
    WR.Auras:RegisterImportantAura(self.spells.DELUGE, 75, true, false)
    WR.Auras:RegisterImportantAura(self.spells.SURGE_OF_EARTH, 80, true, false)
    
    -- Define Restoration DPS rotation (for solo content)
    -- Note: Since Restoration is primarily a healer, actual implementation would focus on healing logic
    -- For combat/damage situations, we'll create a simple DPS rotation for solo content
    
    self.singleTargetRotation = {
        -- Maintain Flame Shock for DPS
        {
            spell = self.spells.FLAME_SHOCK,
            condition = function(self)
                return not self:HasDebuff(self.spells.FLAME_SHOCK) or
                       self:GetDebuffRemaining(self.spells.FLAME_SHOCK) < 5.4
            end
        },
        
        -- Use covenant abilities
        { 
            spell = self.spells.VESPER_TOTEM,
            condition = function(self) return IsSpellKnown(self.spells.VESPER_TOTEM) end
        },
        { 
            spell = self.spells.PRIMORDIAL_WAVE,
            condition = function(self) return IsSpellKnown(self.spells.PRIMORDIAL_WAVE) end
        },
        { 
            spell = self.spells.FAE_TRANSFUSION,
            condition = function(self) return IsSpellKnown(self.spells.FAE_TRANSFUSION) end
        },
        { 
            spell = self.spells.CHAIN_HARVEST,
            condition = function(self) return IsSpellKnown(self.spells.CHAIN_HARVEST) end
        },
        
        -- Self-heal if needed
        {
            spell = self.spells.RIPTIDE,
            condition = function(self)
                return not self:HasBuff(self.spells.RIPTIDE) and
                       self:GetHealthPct() < 90
            end
        },
        {
            spell = self.spells.HEALING_SURGE,
            condition = function(self)
                return self:GetHealthPct() < 70
            end
        },
        
        -- Use Lava Burst on cooldown
        {
            spell = self.spells.LAVA_BURST,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.LAVA_BURST)
            end
        },
        
        -- Use Earth Shock for burst damage
        {
            spell = self.spells.EARTH_SHOCK,
            condition = function(self)
                return self:GetMaelstrom() >= 60
            end
        },
        
        -- Use Lightning Bolt as filler
        { spell = self.spells.LIGHTNING_BOLT }
    }
    
    -- AoE rotation for Restoration
    self.aoeRotation = {
        -- Maintain Flame Shock for DPS
        {
            spell = self.spells.FLAME_SHOCK,
            condition = function(self)
                return not self:HasDebuff(self.spells.FLAME_SHOCK) or
                       self:GetDebuffRemaining(self.spells.FLAME_SHOCK) < 5.4
            end
        },
        
        -- Use covenant abilities
        { 
            spell = self.spells.VESPER_TOTEM,
            condition = function(self) return IsSpellKnown(self.spells.VESPER_TOTEM) end
        },
        { 
            spell = self.spells.CHAIN_HARVEST,
            condition = function(self) return IsSpellKnown(self.spells.CHAIN_HARVEST) end
        },
        
        -- Self-heal if needed with AoE
        {
            spell = self.spells.HEALING_RAIN,
            condition = function(self)
                return self:GetHealthPct() < 80 and
                       not self:SpellOnCooldown(self.spells.HEALING_RAIN)
            end
        },
        
        -- Use Chain Lightning for AoE
        {
            spell = self.spells.CHAIN_LIGHTNING,
            condition = function(self)
                return self:GetEnemyCount(8) >= 2
            end
        },
        
        -- Use Lightning Bolt as filler
        { spell = self.spells.LIGHTNING_BOLT }
    }
    
    -- Define burst rotation
    self.burstRotation = {
        {
            spell = self.spells.ASCENDANCE,
            condition = function(self) return IsSpellKnown(self.spells.ASCENDANCE) end
        },
        { 
            spell = self.spells.VESPER_TOTEM,
            condition = function(self) return IsSpellKnown(self.spells.VESPER_TOTEM) end
        },
        { 
            spell = self.spells.CHAIN_HARVEST,
            condition = function(self) return IsSpellKnown(self.spells.CHAIN_HARVEST) end
        },
        { spell = self.spells.LAVA_BURST }
    }
    
    -- Add Restoration-specific defensive abilities
    table.insert(self.defensiveRotation, {
        spell = self.spells.HEALING_STREAM_TOTEM,
        threshold = 85
    })
    
    table.insert(self.defensiveRotation, {
        spell = self.spells.HEALING_TIDE_TOTEM,
        threshold = 50
    })
    
    table.insert(self.defensiveRotation, {
        spell = self.spells.EARTHEN_WALL_TOTEM,
        threshold = 70,
        condition = function(self)
            return IsSpellKnown(self.spells.EARTHEN_WALL_TOTEM)
        end
    })
end

-- Get current Maelstrom
function Shaman:GetMaelstrom()
    -- In a real addon, this would use UnitPower with the appropriate power type
    -- Here we'll return a simulated value
    if self.currentSpec == SPEC_ELEMENTAL then
        return math.random(0, 100)
    elseif self.currentSpec == SPEC_ENHANCEMENT then
        return math.random(0, 100)
    else
        return 0
    end
end

-- Get current Maelstrom Weapon stacks
function Shaman:GetMaelstromWeaponStacks()
    -- In a real addon, this would check for the buff and its stacks
    -- Here we'll return a simulated value
    if self.currentSpec == SPEC_ENHANCEMENT then
        return math.random(0, 10)
    else
        return 0
    end
end

-- Class-specific pre-rotation checks
function Shaman:ClassSpecificChecks()
    -- Check for shield buffs
    if self.currentSpec == SPEC_ELEMENTAL and not self:HasBuff(self.spells.LIGHTNING_SHIELD) then
        WR.Queue:Add(self.spells.LIGHTNING_SHIELD)
        return false
    elseif self.currentSpec == SPEC_ENHANCEMENT and not self:HasBuff(self.spells.LIGHTNING_SHIELD) then
        WR.Queue:Add(self.spells.LIGHTNING_SHIELD)
        return false
    elseif self.currentSpec == SPEC_RESTORATION and not self:HasBuff(self.spells.WATER_SHIELD) then
        WR.Queue:Add(self.spells.WATER_SHIELD)
        return false
    end
    
    -- For Enhancement, check weapon enchants
    if self.currentSpec == SPEC_ENHANCEMENT then
        if not self:HasBuff(self.spells.WINDFURY_WEAPON, "mainhand") then
            WR.Queue:Add(self.spells.WINDFURY_WEAPON)
            return false
        end
        
        if not self:HasBuff(self.spells.FLAMETONGUE_WEAPON, "offhand") then
            WR.Queue:Add(self.spells.FLAMETONGUE_WEAPON)
            return false
        end
    end
    
    return true
end

-- Check if the target has a specific buff on a specific weapon slot
function Shaman:HasBuff(spellId, weaponSlot)
    -- In a real addon, this would check the specific weapon slot
    if weaponSlot then
        -- For our mock implementation, just return true to avoid endless enchant applications
        return true
    else
        -- Use the standard HasBuff implementation from the base class
        return WR.BaseClass.HasBuff(self, spellId)
    end
end

-- Get default action when nothing else is available
function Shaman:GetDefaultAction()
    if self.currentSpec == SPEC_ELEMENTAL then
        return self.spells.LIGHTNING_BOLT
    elseif self.currentSpec == SPEC_ENHANCEMENT then
        return self.spells.FROST_SHOCK
    elseif self.currentSpec == SPEC_RESTORATION then
        return self.spells.LIGHTNING_BOLT
    end
    
    return nil
end

-- Initialize the module
Shaman:Initialize()

return Shaman