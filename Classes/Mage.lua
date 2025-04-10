local addonName, WR = ...

-- Mage Class module
local Mage = {}
WR.Classes = WR.Classes or {}
WR.Classes.MAGE = Mage

-- Inherit from BaseClass
setmetatable(Mage, {__index = WR.BaseClass})

-- Resource type for mages (mana)
Mage.resourceType = Enum.PowerType.Mana

-- Define spec IDs
local SPEC_ARCANE = 62
local SPEC_FIRE = 63
local SPEC_FROST = 64

-- Class initialization
function Mage:Initialize()
    -- Inherit base initialization
    WR.BaseClass.Initialize(self)
    
    -- Register Specializations
    self:RegisterSpec(SPEC_ARCANE, "Arcane")
    self:RegisterSpec(SPEC_FIRE, "Fire")
    self:RegisterSpec(SPEC_FROST, "Frost")
    
    -- Shared spell IDs across all mage specs
    self.spells = {
        -- Common mage abilities
        ARCANE_INTELLECT = 1459,
        COUNTERSPELL = 2139,
        BLINK = 1953,
        ICE_BLOCK = 45438,
        MIRROR_IMAGE = 55342,
        FROST_NOVA = 122,
        REMOVE_CURSE = 475,
        SPELLSTEAL = 30449,
        TIME_WARP = 80353,
        INVISIBILITY = 66,
        SLOW_FALL = 130,
        CONJURE_REFRESHMENT = 116136,
        FOCUS_MAGIC = 321358,
        
        -- Covenant abilities
        RADIANT_SPARK = 307443,  -- Kyrian
        DEATHBORNE = 324220,     -- Necrolord
        MIRRORS_OF_TORMENT = 314793, -- Venthyr
        SHIFTING_POWER = 314791, -- Night Fae
    }
    
    -- Load shared mage data
    self:LoadSharedMageData()
    
    WR:Debug("Mage module initialized")
end

-- Load shared spell and mechanics data for all mage specs
function Mage:LoadSharedMageData()
    -- Register important buffs
    WR.Auras:RegisterImportantAura(self.spells.ARCANE_INTELLECT, 30, true, false)
    WR.Auras:RegisterImportantAura(self.spells.FOCUS_MAGIC, 40, true, false)
    
    -- Setup cooldown tracking
    WR.Cooldown:StartTracking(self.spells.COUNTERSPELL)
    WR.Cooldown:StartTracking(self.spells.BLINK)
    WR.Cooldown:StartTracking(self.spells.ICE_BLOCK)
    WR.Cooldown:StartTracking(self.spells.MIRROR_IMAGE)
    
    -- Time Warp triggers Temporal Displacement
    WR.Cooldown:RegisterCooldownTrigger(self.spells.TIME_WARP, 80354, 600)
    
    -- Set up interrupt rotation (shared by all specs)
    self.interruptRotation = {
        { spell = self.spells.COUNTERSPELL }
    }
    
    -- Set up defensive rotation (shared by all specs)
    self.defensiveRotation = {
        { spell = self.spells.ICE_BLOCK, threshold = 15 } -- Use Ice Block at very low health
    }
end

-- Load a specific specialization
function Mage:LoadSpec(specId)
    -- Call the base class method to set up common components
    WR.BaseClass.LoadSpec(self, specId)
    
    -- Load specific spec data
    if specId == SPEC_ARCANE then
        self:LoadArcaneSpec()
    elseif specId == SPEC_FIRE then
        self:LoadFireSpec()
    elseif specId == SPEC_FROST then
        self:LoadFrostSpec()
    end
    
    WR:Debug("Loaded mage spec:", self.specData.name)
    return true
end

-- Load Arcane specialization
function Mage:LoadArcaneSpec()
    -- Arcane-specific spells
    self.spells.ARCANE_BLAST = 30451
    self.spells.ARCANE_BARRAGE = 44425
    self.spells.ARCANE_MISSILES = 5143
    self.spells.ARCANE_EXPLOSION = 1449
    self.spells.ARCANE_POWER = 12042
    self.spells.EVOCATION = 12051
    self.spells.PRESENCE_OF_MIND = 205025
    self.spells.TOUCH_OF_THE_MAGI = 321507
    self.spells.ARCANE_FAMILIAR = 205022
    self.spells.PRISMATIC_BARRIER = 235450
    self.spells.RUNE_OF_POWER = 116011
    self.spells.ARCANE_ORB = 153626
    self.spells.NETHER_TEMPEST = 114923
    self.spells.SUPERNOVA = 157980
    
    -- Setup cooldown and aura tracking for Arcane
    WR.Cooldown:StartTracking(self.spells.ARCANE_POWER)
    WR.Cooldown:StartTracking(self.spells.EVOCATION)
    WR.Cooldown:StartTracking(self.spells.PRESENCE_OF_MIND)
    WR.Cooldown:StartTracking(self.spells.TOUCH_OF_THE_MAGI)
    
    -- Check for Arcane Familiar and track if necessary
    if IsSpellKnown(self.spells.ARCANE_FAMILIAR) then
        WR.Auras:RegisterImportantAura(self.spells.ARCANE_FAMILIAR, 80, true, false)
    end
    
    -- Define Arcane rotation, prioritizing abilities in order
    self.singleTargetRotation = {
        -- Maintain Arcane Familiar buff if we have it
        { 
            spell = self.spells.ARCANE_FAMILIAR, 
            condition = function(self) 
                return IsSpellKnown(self.spells.ARCANE_FAMILIAR) and 
                       not self:HasBuff(self.spells.ARCANE_FAMILIAR) 
            end 
        },
        
        -- Use Touch of the Magi on cooldown, preferably with Arcane Power coming up
        { 
            spell = self.spells.TOUCH_OF_THE_MAGI, 
            condition = function(self) 
                local apCD = self:GetSpellCooldown(self.spells.ARCANE_POWER)
                return apCD < 5 or apCD > 25
            end 
        },
        
        -- Use Arcane Power for burst damage
        { 
            spell = self.spells.ARCANE_POWER,
            condition = function(self)
                return self:HasBuff(self.spells.TOUCH_OF_THE_MAGI) or
                       self:GetSpellCooldown(self.spells.TOUCH_OF_THE_MAGI) > 25
            end
        },
        
        -- Use Presence of Mind with Arcane Blast during burst
        { 
            spell = self.spells.PRESENCE_OF_MIND,
            condition = function(self)
                return self:HasBuff(self.spells.ARCANE_POWER)
            end
        },
        
        -- Use Rune of Power before burst or when idle with high mana
        { 
            spell = self.spells.RUNE_OF_POWER,
            condition = function(self)
                local apCD = self:GetSpellCooldown(self.spells.ARCANE_POWER)
                local totmCD = self:GetSpellCooldown(self.spells.TOUCH_OF_THE_MAGI)
                return (apCD < 5 or totmCD < 5) or 
                       (apCD > 15 and totmCD > 15 and self:GetResourcePct() > 80)
            end
        },
        
        -- Use Arcane Orb when below 4 Arcane Charges
        { 
            spell = self.spells.ARCANE_ORB,
            condition = function(self)
                local charges = UnitPower("player", Enum.PowerType.ArcaneCharges)
                return charges < 4
            end
        },
        
        -- Use Evocation when low on mana
        { 
            spell = self.spells.EVOCATION,
            condition = function(self)
                return self:GetResourcePct() < 20 and
                       not self:HasBuff(self.spells.ARCANE_POWER)
            end
        },
        
        -- Use Arcane Missiles when proc is available and high mana
        { 
            spell = self.spells.ARCANE_MISSILES,
            condition = function(self)
                return self:HasBuff(203128) and -- Clearcasting proc
                       (self:GetResourcePct() > 40 or self:HasBuff(self.spells.ARCANE_POWER))
            end
        },
        
        -- Dump Arcane charges with Arcane Barrage when mana is low
        { 
            spell = self.spells.ARCANE_BARRAGE,
            condition = function(self)
                local charges = UnitPower("player", Enum.PowerType.ArcaneCharges)
                return (charges >= 4 and self:GetResourcePct() < 40) or
                       (self:GetResourcePct() < 20)
            end
        },
        
        -- Use Arcane Blast as filler when we have enough mana
        { 
            spell = self.spells.ARCANE_BLAST,
            condition = function(self)
                return self:GetResourcePct() > 30 or 
                       self:HasBuff(self.spells.ARCANE_POWER)
            end
        },
        
        -- Use Arcane Barrage as fallback
        { spell = self.spells.ARCANE_BARRAGE }
    }
    
    -- Define AoE rotation for Arcane
    self.aoeRotation = {
        -- Maintain Arcane Familiar buff if we have it
        { 
            spell = self.spells.ARCANE_FAMILIAR, 
            condition = function(self) 
                return IsSpellKnown(self.spells.ARCANE_FAMILIAR) and 
                       not self:HasBuff(self.spells.ARCANE_FAMILIAR) 
            end 
        },
        
        -- Use Touch of the Magi on cooldown in AoE
        { spell = self.spells.TOUCH_OF_THE_MAGI },
        
        -- Use Arcane Power for burst AoE damage
        { spell = self.spells.ARCANE_POWER },
        
        -- Use Arcane Orb for AoE damage and charges
        { spell = self.spells.ARCANE_ORB },
        
        -- Use Supernova if available
        { spell = self.spells.SUPERNOVA },
        
        -- Use Nether Tempest if talented
        { 
            spell = self.spells.NETHER_TEMPEST,
            condition = function(self)
                local charges = UnitPower("player", Enum.PowerType.ArcaneCharges)
                return charges >= 3 and not self:HasDebuff(self.spells.NETHER_TEMPEST)
            end
        },
        
        -- Spend Arcane Charges with Arcane Explosion
        { 
            spell = self.spells.ARCANE_EXPLOSION,
            condition = function(self)
                return self:GetResourcePct() > 30 or self:HasBuff(self.spells.ARCANE_POWER)
            end
        },
        
        -- Use Evocation when low on mana
        { 
            spell = self.spells.EVOCATION,
            condition = function(self)
                return self:GetResourcePct() < 20 and not self:HasBuff(self.spells.ARCANE_POWER)
            end
        },
        
        -- Use Arcane Barrage to dump charges when low on mana
        { 
            spell = self.spells.ARCANE_BARRAGE,
            condition = function(self)
                local charges = UnitPower("player", Enum.PowerType.ArcaneCharges)
                return charges >= 4 and self:GetResourcePct() < 40
            end
        }
    }
    
    -- Define burst rotation
    self.burstRotation = {
        { spell = self.spells.TOUCH_OF_THE_MAGI },
        { spell = self.spells.RUNE_OF_POWER },
        { spell = self.spells.ARCANE_POWER },
        { spell = self.spells.PRESENCE_OF_MIND },
        
        -- Use covenant abilities during burst if available
        { 
            spell = self.spells.RADIANT_SPARK,
            condition = function(self) return IsSpellKnown(self.spells.RADIANT_SPARK) end
        },
        { 
            spell = self.spells.DEATHBORNE,
            condition = function(self) return IsSpellKnown(self.spells.DEATHBORNE) end
        },
        { 
            spell = self.spells.MIRRORS_OF_TORMENT,
            condition = function(self) return IsSpellKnown(self.spells.MIRRORS_OF_TORMENT) end
        },
        { 
            spell = self.spells.SHIFTING_POWER,
            condition = function(self) return IsSpellKnown(self.spells.SHIFTING_POWER) end
        }
    }
end

-- Load Fire specialization
function Mage:LoadFireSpec()
    -- Fire-specific spells
    self.spells.FIREBALL = 133
    self.spells.PYROBLAST = 11366
    self.spells.FIRE_BLAST = 108853
    self.spells.PHOENIX_FLAMES = 257541
    self.spells.DRAGONS_BREATH = 31661
    self.spells.FLAMESTRIKE = 2120
    self.spells.LIVING_BOMB = 44457
    self.spells.COMBUSTION = 190319
    self.spells.BLAST_WAVE = 157981
    self.spells.METEOR = 153561
    self.spells.FLAME_PATCH = 205037
    self.spells.PYROCLASM = 269650
    self.spells.RUNE_OF_POWER = 116011
    self.spells.BLAZING_BARRIER = 235313
    
    -- Setup cooldown and aura tracking for Fire
    WR.Cooldown:StartTracking(self.spells.COMBUSTION)
    WR.Cooldown:StartTracking(self.spells.FIRE_BLAST)
    WR.Cooldown:StartTracking(self.spells.PHOENIX_FLAMES)
    WR.Cooldown:StartTracking(self.spells.DRAGONS_BREATH)
    WR.Cooldown:StartTracking(self.spells.METEOR)
    
    -- Track Hot Streak and Heating Up procs
    WR.Auras:RegisterImportantAura(48108, 90, true, false) -- Hot Streak
    WR.Auras:RegisterImportantAura(48107, 80, true, false) -- Heating Up
    
    -- Define Fire rotation, prioritizing abilities in order
    self.singleTargetRotation = {
        -- Maintain Blazing Barrier
        { 
            spell = self.spells.BLAZING_BARRIER, 
            condition = function(self) 
                return not self:HasBuff(self.spells.BLAZING_BARRIER) 
            end 
        },
        
        -- Use Rune of Power before Combustion or when available
        { 
            spell = self.spells.RUNE_OF_POWER,
            condition = function(self)
                local combustionCD = self:GetSpellCooldown(self.spells.COMBUSTION)
                return combustionCD < 5 or
                       (combustionCD > 20 and not self:SpellOnCooldown(self.spells.RUNE_OF_POWER))
            end
        },
        
        -- Use Combustion for burst
        { spell = self.spells.COMBUSTION },
        
        -- Use Meteor with Combustion or on cooldown
        { 
            spell = self.spells.METEOR,
            condition = function(self)
                return self:HasBuff(self.spells.COMBUSTION) or
                       not self:SpellOnCooldown(self.spells.METEOR)
            end
        },
        
        -- Use Pyroblast with Hot Streak
        { 
            spell = self.spells.PYROBLAST,
            condition = function(self)
                return self:HasBuff(48108) -- Hot Streak
            end
        },
        
        -- Use Fire Blast with Heating Up to get Hot Streak
        { 
            spell = self.spells.FIRE_BLAST,
            condition = function(self)
                return self:HasBuff(48107) and -- Heating Up
                       not self:HasBuff(48108) and -- Not Hot Streak
                       self:SpellHasCharges(self.spells.FIRE_BLAST)
            end
        },
        
        -- Use Phoenix Flames with Heating Up when Fire Blast charges are depleted
        { 
            spell = self.spells.PHOENIX_FLAMES,
            condition = function(self)
                return self:HasBuff(48107) and -- Heating Up
                       not self:HasBuff(48108) and -- Not Hot Streak
                       not self:SpellHasCharges(self.spells.FIRE_BLAST) and
                       self:SpellHasCharges(self.spells.PHOENIX_FLAMES)
            end
        },
        
        -- Use Phoenix Flames to generate Heating Up during Combustion
        { 
            spell = self.spells.PHOENIX_FLAMES,
            condition = function(self)
                return self:HasBuff(self.spells.COMBUSTION) and
                       self:SpellHasCharges(self.spells.PHOENIX_FLAMES)
            end
        },
        
        -- Use Pyroblast with Pyroclasm proc
        { 
            spell = self.spells.PYROBLAST,
            condition = function(self)
                return self:HasBuff(self.spells.PYROCLASM)
            end
        },
        
        -- Use Dragon's Breath when close
        { 
            spell = self.spells.DRAGONS_BREATH,
            condition = function(self)
                return WR.API:UnitDistance("target") <= 8
            end
        },
        
        -- Use Living Bomb if talented
        { 
            spell = self.spells.LIVING_BOMB,
            condition = function(self)
                return IsSpellKnown(self.spells.LIVING_BOMB) and
                       not self:HasDebuff(self.spells.LIVING_BOMB)
            end
        },
        
        -- Use Fireball as filler
        { spell = self.spells.FIREBALL }
    }
    
    -- Define AoE rotation for Fire
    self.aoeRotation = {
        -- Maintain Blazing Barrier
        { 
            spell = self.spells.BLAZING_BARRIER, 
            condition = function(self) 
                return not self:HasBuff(self.spells.BLAZING_BARRIER) 
            end 
        },
        
        -- Use Combustion for burst AoE
        { spell = self.spells.COMBUSTION },
        
        -- Use Rune of Power before Combustion
        { 
            spell = self.spells.RUNE_OF_POWER,
            condition = function(self)
                return self:HasBuff(self.spells.COMBUSTION) or
                       self:GetSpellCooldown(self.spells.COMBUSTION) < 5
            end
        },
        
        -- Use Meteor for AoE
        { spell = self.spells.METEOR },
        
        -- Use Flamestrike with Hot Streak in AoE
        { 
            spell = self.spells.FLAMESTRIKE,
            condition = function(self)
                return self:HasBuff(48108) -- Hot Streak
            end
        },
        
        -- Use Fire Blast with Heating Up to get Hot Streak
        { 
            spell = self.spells.FIRE_BLAST,
            condition = function(self)
                return self:HasBuff(48107) and -- Heating Up
                       not self:HasBuff(48108) and -- Not Hot Streak
                       self:SpellHasCharges(self.spells.FIRE_BLAST)
            end
        },
        
        -- Use Phoenix Flames for AoE damage
        { 
            spell = self.spells.PHOENIX_FLAMES,
            condition = function(self)
                return self:SpellHasCharges(self.spells.PHOENIX_FLAMES)
            end
        },
        
        -- Use Living Bomb for AoE
        {
            spell = self.spells.LIVING_BOMB,
            condition = function(self)
                return IsSpellKnown(self.spells.LIVING_BOMB)
            end
        },
        
        -- Use Blast Wave for AoE if talented
        { 
            spell = self.spells.BLAST_WAVE,
            condition = function(self)
                return IsSpellKnown(self.spells.BLAST_WAVE)
            end
        },
        
        -- Use Dragon's Breath for AoE
        { spell = self.spells.DRAGONS_BREATH },
        
        -- Use Flamestrike as filler in AoE
        { spell = self.spells.FLAMESTRIKE }
    }
    
    -- Define burst rotation
    self.burstRotation = {
        { spell = self.spells.RUNE_OF_POWER },
        { spell = self.spells.COMBUSTION },
        
        -- Use covenant abilities during burst
        { 
            spell = self.spells.RADIANT_SPARK,
            condition = function(self) return IsSpellKnown(self.spells.RADIANT_SPARK) end
        },
        { 
            spell = self.spells.DEATHBORNE,
            condition = function(self) return IsSpellKnown(self.spells.DEATHBORNE) end
        },
        { 
            spell = self.spells.MIRRORS_OF_TORMENT,
            condition = function(self) return IsSpellKnown(self.spells.MIRRORS_OF_TORMENT) end
        },
        { 
            spell = self.spells.SHIFTING_POWER,
            condition = function(self) return IsSpellKnown(self.spells.SHIFTING_POWER) end
        }
    }
end

-- Load Frost specialization
function Mage:LoadFrostSpec()
    -- Frost-specific spells
    self.spells.FROSTBOLT = 116
    self.spells.ICE_LANCE = 30455
    self.spells.FLURRY = 44614
    self.spells.FROZEN_ORB = 84714
    self.spells.BLIZZARD = 190356
    self.spells.CONE_OF_COLD = 120
    self.spells.ICY_VEINS = 12472
    self.spells.RAY_OF_FROST = 205021
    self.spells.GLACIAL_SPIKE = 199786
    self.spells.COMET_STORM = 153595
    self.spells.ICE_FORM = 198144
    self.spells.ICE_BARRIER = 11426
    self.spells.EBONBOLT = 257537
    self.spells.RUNE_OF_POWER = 116011
    
    -- Setup cooldown and aura tracking for Frost
    WR.Cooldown:StartTracking(self.spells.ICY_VEINS)
    WR.Cooldown:StartTracking(self.spells.FROZEN_ORB)
    WR.Cooldown:StartTracking(self.spells.BLIZZARD)
    WR.Cooldown:StartTracking(self.spells.COMET_STORM)
    WR.Cooldown:StartTracking(self.spells.EBONBOLT)
    
    -- Track Brain Freeze and Fingers of Frost procs
    WR.Auras:RegisterImportantAura(190446, 90, true, false) -- Brain Freeze
    WR.Auras:RegisterImportantAura(44544, 80, true, false) -- Fingers of Frost
    
    -- Define Frost rotation, prioritizing abilities in order
    self.singleTargetRotation = {
        -- Maintain Ice Barrier
        { 
            spell = self.spells.ICE_BARRIER, 
            condition = function(self) 
                return not self:HasBuff(self.spells.ICE_BARRIER) 
            end 
        },
        
        -- Use Rune of Power before Icy Veins or when available
        { 
            spell = self.spells.RUNE_OF_POWER,
            condition = function(self)
                local ivCD = self:GetSpellCooldown(self.spells.ICY_VEINS)
                return ivCD < 5 or (ivCD > 20 and not self:SpellOnCooldown(self.spells.RUNE_OF_POWER))
            end
        },
        
        -- Use Icy Veins for burst
        { spell = self.spells.ICY_VEINS },
        
        -- Use Frozen Orb on cooldown
        { spell = self.spells.FROZEN_ORB },
        
        -- Use Ebonbolt to gain Brain Freeze when we don't have it
        { 
            spell = self.spells.EBONBOLT,
            condition = function(self)
                return not self:HasBuff(190446) -- Brain Freeze
            end
        },
        
        -- Use Glacial Spike if available and we have Brain Freeze
        { 
            spell = self.spells.GLACIAL_SPIKE,
            condition = function(self)
                return self:HasBuff(190446) -- Brain Freeze
            end
        },
        
        -- Use Flurry with Brain Freeze proc
        { 
            spell = self.spells.FLURRY,
            condition = function(self)
                return self:HasBuff(190446) -- Brain Freeze
            end
        },
        
        -- Use Ice Lance with Fingers of Frost proc
        { 
            spell = self.spells.ICE_LANCE,
            condition = function(self)
                return self:HasBuff(44544) -- Fingers of Frost
            end
        },
        
        -- Use Comet Storm if talented
        { 
            spell = self.spells.COMET_STORM,
            condition = function(self)
                return IsSpellKnown(self.spells.COMET_STORM)
            end
        },
        
        -- Use Ray of Frost if talented
        { 
            spell = self.spells.RAY_OF_FROST,
            condition = function(self)
                return IsSpellKnown(self.spells.RAY_OF_FROST)
            end
        },
        
        -- Use Glacial Spike at 5 icicles when not waiting for Brain Freeze
        { 
            spell = self.spells.GLACIAL_SPIKE,
            condition = function(self)
                return not IsSpellKnown(self.spells.EBONBOLT) or
                       self:SpellOnCooldown(self.spells.EBONBOLT)
            end
        },
        
        -- Use Cone of Cold when close
        { 
            spell = self.spells.CONE_OF_COLD,
            condition = function(self)
                return WR.API:UnitDistance("target") <= 8
            end
        },
        
        -- Use Frostbolt as filler
        { spell = self.spells.FROSTBOLT }
    }
    
    -- Define AoE rotation for Frost
    self.aoeRotation = {
        -- Maintain Ice Barrier
        { 
            spell = self.spells.ICE_BARRIER, 
            condition = function(self) 
                return not self:HasBuff(self.spells.ICE_BARRIER) 
            end 
        },
        
        -- Use Icy Veins for burst AoE
        { spell = self.spells.ICY_VEINS },
        
        -- Use Rune of Power before Icy Veins
        { 
            spell = self.spells.RUNE_OF_POWER,
            condition = function(self)
                return self:HasBuff(self.spells.ICY_VEINS) or
                       self:GetSpellCooldown(self.spells.ICY_VEINS) < 5
            end
        },
        
        -- Use Frozen Orb for AoE and procs
        { spell = self.spells.FROZEN_ORB },
        
        -- Use Blizzard for AoE damage
        { spell = self.spells.BLIZZARD },
        
        -- Use Comet Storm for AoE
        { 
            spell = self.spells.COMET_STORM,
            condition = function(self)
                return IsSpellKnown(self.spells.COMET_STORM)
            end
        },
        
        -- Use Cone of Cold for AoE
        { spell = self.spells.CONE_OF_COLD },
        
        -- Use Ice Lance with Fingers of Frost procs in AoE
        { 
            spell = self.spells.ICE_LANCE,
            condition = function(self)
                return self:HasBuff(44544) -- Fingers of Frost
            end
        },
        
        -- Use Ebonbolt to gain Brain Freeze
        { spell = self.spells.EBONBOLT },
        
        -- Use Flurry with Brain Freeze proc
        { 
            spell = self.spells.FLURRY,
            condition = function(self)
                return self:HasBuff(190446) -- Brain Freeze
            end
        },
        
        -- Use Glacial Spike at 5 icicles or with Brain Freeze
        { 
            spell = self.spells.GLACIAL_SPIKE,
            condition = function(self)
                return self:HasBuff(190446) -- Brain Freeze
            end
        },
        
        -- Use Frostbolt to generate icicles and procs
        { spell = self.spells.FROSTBOLT }
    }
    
    -- Define burst rotation
    self.burstRotation = {
        { spell = self.spells.RUNE_OF_POWER },
        { spell = self.spells.ICY_VEINS },
        { spell = self.spells.FROZEN_ORB },
        
        -- Use covenant abilities during burst
        { 
            spell = self.spells.RADIANT_SPARK,
            condition = function(self) return IsSpellKnown(self.spells.RADIANT_SPARK) end
        },
        { 
            spell = self.spells.DEATHBORNE,
            condition = function(self) return IsSpellKnown(self.spells.DEATHBORNE) end
        },
        { 
            spell = self.spells.MIRRORS_OF_TORMENT,
            condition = function(self) return IsSpellKnown(self.spells.MIRRORS_OF_TORMENT) end
        },
        { 
            spell = self.spells.SHIFTING_POWER,
            condition = function(self) return IsSpellKnown(self.spells.SHIFTING_POWER) end
        }
    }
end

-- Class-specific pre-rotation checks
function Mage:ClassSpecificChecks()
    -- Check for class-specific conditions
    
    -- Check if we need to apply Arcane Intellect
    if not self:HasBuff(self.spells.ARCANE_INTELLECT) and 
       not self:SpellOnCooldown(self.spells.ARCANE_INTELLECT) then
        WR.Queue:Add(self.spells.ARCANE_INTELLECT)
        return false
    end
    
    -- Add class-specific barriers based on spec
    local barrierSpell = nil
    if self.currentSpec == SPEC_ARCANE then
        barrierSpell = self.spells.PRISMATIC_BARRIER
    elseif self.currentSpec == SPEC_FIRE then
        barrierSpell = self.spells.BLAZING_BARRIER
    elseif self.currentSpec == SPEC_FROST then
        barrierSpell = self.spells.ICE_BARRIER
    end
    
    -- Apply barrier if we don't have it
    if barrierSpell and not self:InCombat() and
       not self:HasBuff(barrierSpell) and 
       not self:SpellOnCooldown(barrierSpell) then
        WR.Queue:Add(barrierSpell)
        return false
    end
    
    return true
end

-- Get default action when nothing else is available
function Mage:GetDefaultAction()
    if self.currentSpec == SPEC_ARCANE then
        return self.spells.ARCANE_BLAST
    elseif self.currentSpec == SPEC_FIRE then
        return self.spells.FIREBALL
    elseif self.currentSpec == SPEC_FROST then
        return self.spells.FROSTBOLT
    end
    
    return nil
end

-- Initialize the module
Mage:Initialize()

return Mage