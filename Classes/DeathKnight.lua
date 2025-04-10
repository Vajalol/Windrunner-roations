local addonName, WR = ...

-- Death Knight Class module
local DeathKnight = {}
WR.Classes = WR.Classes or {}
WR.Classes.DEATHKNIGHT = DeathKnight

-- Inherit from BaseClass
setmetatable(DeathKnight, {__index = WR.BaseClass})

-- Resource type for Death Knights (Runes and Runic Power)
DeathKnight.resourceType = Enum.PowerType.RunicPower
DeathKnight.secondaryResourceType = Enum.PowerType.Runes

-- Define spec IDs
local SPEC_BLOOD = 250
local SPEC_FROST = 251
local SPEC_UNHOLY = 252

-- Class initialization
function DeathKnight:Initialize()
    -- Inherit base initialization
    WR.BaseClass.Initialize(self)
    
    -- Register Specializations
    self:RegisterSpec(SPEC_BLOOD, "Blood")
    self:RegisterSpec(SPEC_FROST, "Frost")
    self:RegisterSpec(SPEC_UNHOLY, "Unholy")
    
    -- Shared spell IDs across all DK specs
    self.spells = {
        -- Common Death Knight abilities
        DEATH_STRIKE = 49998,
        DEATH_COIL = 47541,
        DEATH_GRIP = 49576,
        MIND_FREEZE = 47528,
        ANTI_MAGIC_SHELL = 48707,
        ICEBOUND_FORTITUDE = 48792,
        DEATH_AND_DECAY = 43265,
        RAISE_DEAD = 46584,
        LICHBORNE = 49039,
        DEATH_GATE = 50977,
        CONTROL_UNDEAD = 111673,
        PATH_OF_FROST = 3714,
        WRAITH_WALK = 212552,
        CHAINS_OF_ICE = 45524,
        DARK_COMMAND = 56222,
        DEATHS_ADVANCE = 48265,
        RAISE_ALLY = 61999,
        
        -- Covenant abilities
        DEATHS_DUE = 324128,      -- Night Fae
        SWARMING_MIST = 311648,   -- Venthyr
        SHACKLE_THE_UNWORTHY = 312202, -- Kyrian
        ABOMINATION_LIMB = 315443 -- Necrolord
    }
    
    -- Load shared Death Knight data
    self:LoadSharedDeathKnightData()
    
    WR:Debug("Death Knight module initialized")
end

-- Load shared spell and mechanics data for all DK specs
function DeathKnight:LoadSharedDeathKnightData()
    -- Register important buffs
    WR.Auras:RegisterImportantAura(self.spells.ANTI_MAGIC_SHELL, 90, true, false)
    WR.Auras:RegisterImportantAura(self.spells.ICEBOUND_FORTITUDE, 90, true, false)
    WR.Auras:RegisterImportantAura(self.spells.PATH_OF_FROST, 60, true, false)
    WR.Auras:RegisterImportantAura(self.spells.DEATHS_ADVANCE, 70, true, false)
    WR.Auras:RegisterImportantAura(self.spells.WRAITH_WALK, 70, true, false)
    
    -- Setup cooldown tracking
    WR.Cooldown:StartTracking(self.spells.DEATH_STRIKE)
    WR.Cooldown:StartTracking(self.spells.DEATH_GRIP)
    WR.Cooldown:StartTracking(self.spells.MIND_FREEZE)
    WR.Cooldown:StartTracking(self.spells.ANTI_MAGIC_SHELL)
    WR.Cooldown:StartTracking(self.spells.ICEBOUND_FORTITUDE)
    WR.Cooldown:StartTracking(self.spells.DEATH_AND_DECAY)
    WR.Cooldown:StartTracking(self.spells.RAISE_DEAD)
    WR.Cooldown:StartTracking(self.spells.LICHBORNE)
    WR.Cooldown:StartTracking(self.spells.WRAITH_WALK)
    WR.Cooldown:StartTracking(self.spells.CHAINS_OF_ICE)
    WR.Cooldown:StartTracking(self.spells.DARK_COMMAND)
    WR.Cooldown:StartTracking(self.spells.DEATHS_ADVANCE)
    
    -- Set up the interrupt spell
    self.interruptRotation = {
        { spell = self.spells.MIND_FREEZE }
    }
    
    -- Set up defensive rotation (shared by all specs)
    self.defensiveRotation = {
        { spell = self.spells.ICEBOUND_FORTITUDE, threshold = 40 },
        { spell = self.spells.ANTI_MAGIC_SHELL, threshold = 70 }
    }
end

-- Load a specific specialization
function DeathKnight:LoadSpec(specId)
    -- Call the base class method to set up common components
    WR.BaseClass.LoadSpec(self, specId)
    
    -- Set the resource type based on spec
    self.resourceType = Enum.PowerType.RunicPower
    self.secondaryResourceType = Enum.PowerType.Runes
    
    -- Load specific spec data
    if specId == SPEC_BLOOD then
        self:LoadBloodSpec()
    elseif specId == SPEC_FROST then
        self:LoadFrostSpec()
    elseif specId == SPEC_UNHOLY then
        self:LoadUnholySpec()
    end
    
    WR:Debug("Loaded Death Knight spec:", self.specData.name)
    return true
end

-- Load Blood specialization
function DeathKnight:LoadBloodSpec()
    -- Blood-specific spells
    self.spells.BLOOD_BOIL = 50842
    self.spells.HEART_STRIKE = 206930
    self.spells.MARROWREND = 195182
    self.spells.VAMPIRIC_BLOOD = 55233
    self.spells.DANCING_RUNE_WEAPON = 49028
    self.spells.BLOOD_TAP = 221699
    self.spells.TOMBSTONE = 219809
    self.spells.BONESTORM = 194844
    self.spells.CONSUMPTION = 274156
    self.spells.MARK_OF_BLOOD = 206940
    self.spells.RUNE_TAP = 194679
    self.spells.BLOOD_SHIELD = 77535
    self.spells.OSSUARY = 219786
    self.spells.HEMOSTASIS = 273946
    self.spells.BLOODDRINKER = 206931
    self.spells.GOREFIENDS_GRASP = 108199
    self.spells.RAISE_DEAD = 46585
    self.spells.SACRIFICIAL_PACT = 327574
    self.spells.BONE_SHIELD = 195181
    self.spells.RED_THIRST = 205723
    
    -- Setup cooldown and aura tracking for Blood
    WR.Cooldown:StartTracking(self.spells.BLOOD_BOIL)
    WR.Cooldown:StartTracking(self.spells.MARROWREND)
    WR.Cooldown:StartTracking(self.spells.VAMPIRIC_BLOOD)
    WR.Cooldown:StartTracking(self.spells.DANCING_RUNE_WEAPON)
    WR.Cooldown:StartTracking(self.spells.BLOODDRINKER)
    WR.Cooldown:StartTracking(self.spells.BONESTORM)
    WR.Cooldown:StartTracking(self.spells.CONSUMPTION)
    WR.Cooldown:StartTracking(self.spells.RUNE_TAP)
    WR.Cooldown:StartTracking(self.spells.GOREFIENDS_GRASP)
    
    -- Track important buffs/debuffs
    WR.Auras:RegisterImportantAura(self.spells.BONE_SHIELD, 95, true, false)
    WR.Auras:RegisterImportantAura(self.spells.VAMPIRIC_BLOOD, 90, true, false)
    WR.Auras:RegisterImportantAura(self.spells.DANCING_RUNE_WEAPON, 90, true, false)
    WR.Auras:RegisterImportantAura(self.spells.BLOOD_SHIELD, 85, true, false)
    WR.Auras:RegisterImportantAura(self.spells.OSSUARY, 80, true, false)
    WR.Auras:RegisterImportantAura(self.spells.HEMOSTASIS, 80, true, false)
    WR.Auras:RegisterImportantAura(self.spells.MARK_OF_BLOOD, 75, false, true)
    
    -- Define Blood tank rotation
    self.singleTargetRotation = {
        -- Maintain Bone Shield
        {
            spell = self.spells.MARROWREND,
            condition = function(self)
                local stacks = self:GetBuffStacks(self.spells.BONE_SHIELD)
                return stacks < 5 or self:GetBuffRemaining(self.spells.BONE_SHIELD) < 6
            end
        },
        
        -- Use Blooddrinker if talented
        {
            spell = self.spells.BLOODDRINKER,
            condition = function(self)
                return IsSpellKnown(self.spells.BLOODDRINKER) and
                       not self:SpellOnCooldown(self.spells.BLOODDRINKER) and
                       self:GetHealthPct() < 85
            end
        },
        
        -- Use covenant abilities
        { 
            spell = self.spells.DEATHS_DUE,
            condition = function(self) return IsSpellKnown(self.spells.DEATHS_DUE) end
        },
        { 
            spell = self.spells.SWARMING_MIST,
            condition = function(self) return IsSpellKnown(self.spells.SWARMING_MIST) end
        },
        { 
            spell = self.spells.SHACKLE_THE_UNWORTHY,
            condition = function(self) return IsSpellKnown(self.spells.SHACKLE_THE_UNWORTHY) end
        },
        { 
            spell = self.spells.ABOMINATION_LIMB,
            condition = function(self) return IsSpellKnown(self.spells.ABOMINATION_LIMB) end
        },
        
        -- Use Dancing Rune Weapon for threat and damage
        {
            spell = self.spells.DANCING_RUNE_WEAPON,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.DANCING_RUNE_WEAPON)
            end
        },
        
        -- Use Death and Decay when available
        {
            spell = self.spells.DEATH_AND_DECAY,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.DEATH_AND_DECAY)
            end
        },
        
        -- Use Consumption if talented for damage and healing
        {
            spell = self.spells.CONSUMPTION,
            condition = function(self)
                return IsSpellKnown(self.spells.CONSUMPTION) and
                       not self:SpellOnCooldown(self.spells.CONSUMPTION)
            end
        },
        
        -- Use Blood Boil to apply Blood Plague
        {
            spell = self.spells.BLOOD_BOIL,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.BLOOD_BOIL)
            end
        },
        
        -- Use Death Strike for healing
        {
            spell = self.spells.DEATH_STRIKE,
            condition = function(self)
                return self:GetRunicPower() >= 45 and
                       (self:GetHealthPct() < 80 or
                        self:GetBuffStacks(self.spells.HEMOSTASIS) > 0)
            end
        },
        
        -- Use Heart Strike as main Rune spender
        { spell = self.spells.HEART_STRIKE }
    }
    
    -- AoE rotation for Blood
    self.aoeRotation = {
        -- Maintain Bone Shield
        {
            spell = self.spells.MARROWREND,
            condition = function(self)
                local stacks = self:GetBuffStacks(self.spells.BONE_SHIELD)
                return stacks < 5 or self:GetBuffRemaining(self.spells.BONE_SHIELD) < 6
            end
        },
        
        -- Use Bonestorm if talented
        {
            spell = self.spells.BONESTORM,
            condition = function(self)
                return IsSpellKnown(self.spells.BONESTORM) and
                       not self:SpellOnCooldown(self.spells.BONESTORM) and
                       self:GetRunicPower() >= 90
            end
        },
        
        -- Use Gorefiend's Grasp for adds
        {
            spell = self.spells.GOREFIENDS_GRASP,
            condition = function(self)
                return self:GetEnemyCount(15) >= 3 and
                       not self:SpellOnCooldown(self.spells.GOREFIENDS_GRASP)
            end
        },
        
        -- Use covenant abilities
        { 
            spell = self.spells.DEATHS_DUE,
            condition = function(self) return IsSpellKnown(self.spells.DEATHS_DUE) end
        },
        { 
            spell = self.spells.SWARMING_MIST,
            condition = function(self) return IsSpellKnown(self.spells.SWARMING_MIST) end
        },
        { 
            spell = self.spells.ABOMINATION_LIMB,
            condition = function(self) return IsSpellKnown(self.spells.ABOMINATION_LIMB) end
        },
        
        -- Use Death and Decay for Heart Strike cleave
        {
            spell = self.spells.DEATH_AND_DECAY,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.DEATH_AND_DECAY)
            end
        },
        
        -- Use Dancing Rune Weapon for AoE threat and damage
        {
            spell = self.spells.DANCING_RUNE_WEAPON,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.DANCING_RUNE_WEAPON)
            end
        },
        
        -- Use Consumption for AoE damage and healing
        {
            spell = self.spells.CONSUMPTION,
            condition = function(self)
                return IsSpellKnown(self.spells.CONSUMPTION) and
                       not self:SpellOnCooldown(self.spells.CONSUMPTION)
            end
        },
        
        -- Use Blood Boil for AoE damage
        {
            spell = self.spells.BLOOD_BOIL,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.BLOOD_BOIL)
            end
        },
        
        -- Use Death Strike for healing
        {
            spell = self.spells.DEATH_STRIKE,
            condition = function(self)
                return self:GetRunicPower() >= 85 or self:GetHealthPct() < 70
            end
        },
        
        -- Use Heart Strike as main Rune spender
        { spell = self.spells.HEART_STRIKE }
    }
    
    -- Define burst rotation
    self.burstRotation = {
        {
            spell = self.spells.DANCING_RUNE_WEAPON,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.DANCING_RUNE_WEAPON)
            end
        },
        { 
            spell = self.spells.ABOMINATION_LIMB,
            condition = function(self) return IsSpellKnown(self.spells.ABOMINATION_LIMB) end
        },
        { 
            spell = self.spells.SWARMING_MIST,
            condition = function(self) return IsSpellKnown(self.spells.SWARMING_MIST) end
        },
        {
            spell = self.spells.DEATH_AND_DECAY,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.DEATH_AND_DECAY)
            end
        },
        {
            spell = self.spells.CONSUMPTION,
            condition = function(self) return IsSpellKnown(self.spells.CONSUMPTION) end
        }
    }
    
    -- Add Blood-specific defensive abilities
    table.insert(self.defensiveRotation, {
        spell = self.spells.VAMPIRIC_BLOOD,
        threshold = 60
    })
    
    table.insert(self.defensiveRotation, {
        spell = self.spells.RUNE_TAP,
        threshold = 70
    })
    
    table.insert(self.defensiveRotation, {
        spell = self.spells.TOMBSTONE,
        condition = function(self)
            return IsSpellKnown(self.spells.TOMBSTONE) and
                   self:GetBuffStacks(self.spells.BONE_SHIELD) >= 5 and
                   self:GetHealthPct() < 50
        end
    })
end

-- Load Frost specialization
function DeathKnight:LoadFrostSpec()
    -- Frost-specific spells
    self.spells.OBLITERATE = 49020
    self.spells.FROST_STRIKE = 49143
    self.spells.HOWLING_BLAST = 49184
    self.spells.REMORSELESS_WINTER = 196770
    self.spells.EMPOWER_RUNE_WEAPON = 47568
    self.spells.PILLAR_OF_FROST = 51271
    self.spells.BREATH_OF_SINDRAGOSA = 152279
    self.spells.FROSTWYRMS_FURY = 279302
    self.spells.GLACIAL_ADVANCE = 194913
    self.spells.HORN_OF_WINTER = 57330
    self.spells.FROST_FEVER = 55095
    self.spells.KILLING_MACHINE = 51124
    self.spells.CHILL_STREAK = 305392
    self.spells.COLD_HEART = 281208
    self.spells.RAZORICE = 51714
    self.spells.RIME = 59052
    self.spells.MURDEROUS_EFFICIENCY = 207061
    self.spells.BLINDING_SLEET = 207167
    self.spells.FROSTSCYTHE = 207230
    self.spells.FROZEN_PULSE = 194909
    self.spells.ICECAP = 207126
    
    -- Setup cooldown and aura tracking for Frost
    WR.Cooldown:StartTracking(self.spells.OBLITERATE)
    WR.Cooldown:StartTracking(self.spells.HOWLING_BLAST)
    WR.Cooldown:StartTracking(self.spells.REMORSELESS_WINTER)
    WR.Cooldown:StartTracking(self.spells.EMPOWER_RUNE_WEAPON)
    WR.Cooldown:StartTracking(self.spells.PILLAR_OF_FROST)
    WR.Cooldown:StartTracking(self.spells.BREATH_OF_SINDRAGOSA)
    WR.Cooldown:StartTracking(self.spells.FROSTWYRMS_FURY)
    WR.Cooldown:StartTracking(self.spells.GLACIAL_ADVANCE)
    WR.Cooldown:StartTracking(self.spells.HORN_OF_WINTER)
    WR.Cooldown:StartTracking(self.spells.CHILL_STREAK)
    WR.Cooldown:StartTracking(self.spells.BLINDING_SLEET)
    
    -- Track important buffs/debuffs
    WR.Auras:RegisterImportantAura(self.spells.PILLAR_OF_FROST, 90, true, false)
    WR.Auras:RegisterImportantAura(self.spells.KILLING_MACHINE, 90, true, false)
    WR.Auras:RegisterImportantAura(self.spells.FROST_FEVER, 85, false, true)
    WR.Auras:RegisterImportantAura(self.spells.COLD_HEART, 80, true, false)
    WR.Auras:RegisterImportantAura(self.spells.RIME, 80, true, false)
    WR.Auras:RegisterImportantAura(self.spells.BREATH_OF_SINDRAGOSA, 95, true, false)
    WR.Auras:RegisterImportantAura(self.spells.REMORSELESS_WINTER, 85, true, false)
    
    -- Define Frost single target rotation
    self.singleTargetRotation = {
        -- Apply Frost Fever
        {
            spell = self.spells.HOWLING_BLAST,
            condition = function(self)
                return not self:HasDebuff(self.spells.FROST_FEVER) or
                       self:GetDebuffRemaining(self.spells.FROST_FEVER) < 4
            end
        },
        
        -- Use Pillar of Frost and other cooldowns together
        {
            spell = self.spells.PILLAR_OF_FROST,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.PILLAR_OF_FROST)
            end
        },
        
        -- Use Empower Rune Weapon during Pillar of Frost
        {
            spell = self.spells.EMPOWER_RUNE_WEAPON,
            condition = function(self)
                return self:HasBuff(self.spells.PILLAR_OF_FROST) and
                       not self:SpellOnCooldown(self.spells.EMPOWER_RUNE_WEAPON)
            end
        },
        
        -- Use covenant abilities during cooldowns
        { 
            spell = self.spells.SWARMING_MIST,
            condition = function(self) 
                return IsSpellKnown(self.spells.SWARMING_MIST) and
                       self:HasBuff(self.spells.PILLAR_OF_FROST)
            end
        },
        { 
            spell = self.spells.DEATHS_DUE,
            condition = function(self) return IsSpellKnown(self.spells.DEATHS_DUE) end
        },
        { 
            spell = self.spells.SHACKLE_THE_UNWORTHY,
            condition = function(self) return IsSpellKnown(self.spells.SHACKLE_THE_UNWORTHY) end
        },
        { 
            spell = self.spells.ABOMINATION_LIMB,
            condition = function(self) return IsSpellKnown(self.spells.ABOMINATION_LIMB) end
        },
        
        -- Use Breath of Sindragosa during Pillar of Frost
        {
            spell = self.spells.BREATH_OF_SINDRAGOSA,
            condition = function(self)
                return IsSpellKnown(self.spells.BREATH_OF_SINDRAGOSA) and
                       self:HasBuff(self.spells.PILLAR_OF_FROST) and
                       not self:SpellOnCooldown(self.spells.BREATH_OF_SINDRAGOSA) and
                       self:GetRunicPower() >= 60
            end
        },
        
        -- Use Frostwyrm's Fury during Pillar of Frost
        {
            spell = self.spells.FROSTWYRMS_FURY,
            condition = function(self)
                return self:HasBuff(self.spells.PILLAR_OF_FROST) and
                       not self:SpellOnCooldown(self.spells.FROSTWYRMS_FURY)
            end
        },
        
        -- Use Cold Heart during Pillar of Frost at max stacks
        {
            spell = self.spells.CHAINS_OF_ICE,
            condition = function(self)
                return IsSpellKnown(self.spells.COLD_HEART) and
                       self:HasBuff(self.spells.PILLAR_OF_FROST) and
                       self:GetBuffStacks(self.spells.COLD_HEART) >= 15
            end
        },
        
        -- Use Remorseless Winter on cooldown
        {
            spell = self.spells.REMORSELESS_WINTER,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.REMORSELESS_WINTER)
            end
        },
        
        -- Use Howling Blast with Rime proc
        {
            spell = self.spells.HOWLING_BLAST,
            condition = function(self)
                return self:HasBuff(self.spells.RIME)
            end
        },
        
        -- Use Frostscythe with Killing Machine (if talented)
        {
            spell = self.spells.FROSTSCYTHE,
            condition = function(self)
                return IsSpellKnown(self.spells.FROSTSCYTHE) and
                       self:HasBuff(self.spells.KILLING_MACHINE)
            end
        },
        
        -- Use Obliterate with Killing Machine
        {
            spell = self.spells.OBLITERATE,
            condition = function(self)
                return self:HasBuff(self.spells.KILLING_MACHINE)
            end
        },
        
        -- Use Horn of Winter for resources
        {
            spell = self.spells.HORN_OF_WINTER,
            condition = function(self)
                return IsSpellKnown(self.spells.HORN_OF_WINTER) and
                       not self:SpellOnCooldown(self.spells.HORN_OF_WINTER) and
                       self:GetRuneCount() < 2
            end
        },
        
        -- Use Obliterate when runes are available
        {
            spell = self.spells.OBLITERATE,
            condition = function(self)
                return self:GetRuneCount() >= 2 and
                       (not IsSpellKnown(self.spells.BREATH_OF_SINDRAGOSA) or
                        not self:HasBuff(self.spells.BREATH_OF_SINDRAGOSA) or
                        self:GetRunicPower() >= 50)
            end
        },
        
        -- Use Frost Strike to spend Runic Power
        {
            spell = self.spells.FROST_STRIKE,
            condition = function(self)
                return (not IsSpellKnown(self.spells.BREATH_OF_SINDRAGOSA) or
                        not self:HasBuff(self.spells.BREATH_OF_SINDRAGOSA)) and
                       self:GetRunicPower() >= 30
            end
        }
    }
    
    -- AoE rotation for Frost
    self.aoeRotation = {
        -- Apply Frost Fever with Howling Blast
        {
            spell = self.spells.HOWLING_BLAST,
            condition = function(self)
                return not self:HasDebuff(self.spells.FROST_FEVER) or
                       self:GetDebuffRemaining(self.spells.FROST_FEVER) < 4
            end
        },
        
        -- Use Pillar of Frost
        {
            spell = self.spells.PILLAR_OF_FROST,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.PILLAR_OF_FROST)
            end
        },
        
        -- Use Empower Rune Weapon during Pillar of Frost
        {
            spell = self.spells.EMPOWER_RUNE_WEAPON,
            condition = function(self)
                return self:HasBuff(self.spells.PILLAR_OF_FROST) and
                       not self:SpellOnCooldown(self.spells.EMPOWER_RUNE_WEAPON)
            end
        },
        
        -- Use covenant abilities
        { 
            spell = self.spells.SWARMING_MIST,
            condition = function(self) 
                return IsSpellKnown(self.spells.SWARMING_MIST) and
                       self:GetEnemyCount(8) >= 3
            end
        },
        { 
            spell = self.spells.DEATHS_DUE,
            condition = function(self) return IsSpellKnown(self.spells.DEATHS_DUE) end
        },
        { 
            spell = self.spells.ABOMINATION_LIMB,
            condition = function(self) return IsSpellKnown(self.spells.ABOMINATION_LIMB) end
        },
        
        -- Use Frostwyrm's Fury for AoE burst
        {
            spell = self.spells.FROSTWYRMS_FURY,
            condition = function(self)
                return self:GetEnemyCount(12) >= 3 and
                       not self:SpellOnCooldown(self.spells.FROSTWYRMS_FURY)
            end
        },
        
        -- Use Chill Streak for PvP AoE (if talented)
        {
            spell = self.spells.CHILL_STREAK,
            condition = function(self)
                return IsSpellKnown(self.spells.CHILL_STREAK) and
                       self:GetEnemyCount(10) >= 2 and
                       not self:SpellOnCooldown(self.spells.CHILL_STREAK)
            end
        },
        
        -- Use Remorseless Winter for AoE damage and slow
        {
            spell = self.spells.REMORSELESS_WINTER,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.REMORSELESS_WINTER)
            end
        },
        
        -- Use Glacial Advance for AoE
        {
            spell = self.spells.GLACIAL_ADVANCE,
            condition = function(self)
                return IsSpellKnown(self.spells.GLACIAL_ADVANCE) and
                       self:GetEnemyCount(8) >= 3 and
                       self:GetRunicPower() >= 30
            end
        },
        
        -- Use Frostscythe for AoE if talented
        {
            spell = self.spells.FROSTSCYTHE,
            condition = function(self)
                return IsSpellKnown(self.spells.FROSTSCYTHE) and
                       self:GetEnemyCount(8) >= 3 and
                       (self:HasBuff(self.spells.KILLING_MACHINE) or
                        self:GetRuneCount() >= 1)
            end
        },
        
        -- Use Howling Blast with Rime proc
        {
            spell = self.spells.HOWLING_BLAST,
            condition = function(self)
                return self:HasBuff(self.spells.RIME)
            end
        },
        
        -- Use Howling Blast for AoE
        {
            spell = self.spells.HOWLING_BLAST,
            condition = function(self)
                return self:GetEnemyCount(8) >= 3 and
                       self:GetRuneCount() >= 1
            end
        },
        
        -- Use Death and Decay for AoE
        {
            spell = self.spells.DEATH_AND_DECAY,
            condition = function(self)
                return self:GetEnemyCount(8) >= 3 and
                       not self:SpellOnCooldown(self.spells.DEATH_AND_DECAY)
            end
        },
        
        -- Use Horn of Winter for resources
        {
            spell = self.spells.HORN_OF_WINTER,
            condition = function(self)
                return IsSpellKnown(self.spells.HORN_OF_WINTER) and
                       not self:SpellOnCooldown(self.spells.HORN_OF_WINTER) and
                       self:GetRuneCount() < 2
            end
        },
        
        -- Use Frost Strike to spend Runic Power
        {
            spell = self.spells.FROST_STRIKE,
            condition = function(self)
                return self:GetRunicPower() >= 80
            end
        },
        
        -- Use Obliterate when runes are available
        {
            spell = self.spells.OBLITERATE,
            condition = function(self)
                return self:GetRuneCount() >= 2
            end
        }
    }
    
    -- Define burst rotation
    self.burstRotation = {
        { spell = self.spells.PILLAR_OF_FROST },
        { spell = self.spells.EMPOWER_RUNE_WEAPON },
        { 
            spell = self.spells.SWARMING_MIST,
            condition = function(self) return IsSpellKnown(self.spells.SWARMING_MIST) end
        },
        {
            spell = self.spells.BREATH_OF_SINDRAGOSA,
            condition = function(self) return IsSpellKnown(self.spells.BREATH_OF_SINDRAGOSA) end
        },
        { spell = self.spells.FROSTWYRMS_FURY }
    }
end

-- Load Unholy specialization
function DeathKnight:LoadUnholySpec()
    -- Unholy-specific spells
    self.spells.SCOURGE_STRIKE = 55090
    self.spells.FESTERING_STRIKE = 85948
    self.spells.DEATH_COIL = 47541
    self.spells.DARK_TRANSFORMATION = 63560
    self.spells.APOCALYPSE = 275699
    self.spells.ARMY_OF_THE_DEAD = 42650
    self.spells.OUTBREAK = 77575
    self.spells.UNHOLY_BLIGHT = 115989
    self.spells.SOUL_REAPER = 343294
    self.spells.EPIDEMIC = 207317
    self.spells.SUMMON_GARGOYLE = 49206
    self.spells.UNHOLY_ASSAULT = 207289
    self.spells.FESTERING_WOUND = 194310
    self.spells.VIRULENT_PLAGUE = 191587
    self.spells.SUDDEN_DOOM = 81340
    self.spells.RUNIC_CORRUPTION = 51460
    self.spells.DARK_SUCCOR = 101568
    self.spells.DARK_ARBITER = 207349
    self.spells.DEFILE = 152280
    self.spells.CLAWING_SHADOWS = 207311
    self.spells.BURSTING_SORES = 207264
    self.spells.EBON_FEVER = 207269
    self.spells.INFECTED_CLAWS = 207272
    self.spells.CORPSE_SHIELD = 207319
    self.spells.UNHOLY_PACT = 319230
    
    -- Setup cooldown and aura tracking for Unholy
    WR.Cooldown:StartTracking(self.spells.SCOURGE_STRIKE)
    WR.Cooldown:StartTracking(self.spells.FESTERING_STRIKE)
    WR.Cooldown:StartTracking(self.spells.DARK_TRANSFORMATION)
    WR.Cooldown:StartTracking(self.spells.APOCALYPSE)
    WR.Cooldown:StartTracking(self.spells.ARMY_OF_THE_DEAD)
    WR.Cooldown:StartTracking(self.spells.SOUL_REAPER)
    WR.Cooldown:StartTracking(self.spells.SUMMON_GARGOYLE)
    WR.Cooldown:StartTracking(self.spells.UNHOLY_ASSAULT)
    WR.Cooldown:StartTracking(self.spells.UNHOLY_BLIGHT)
    WR.Cooldown:StartTracking(self.spells.DEFILE)
    
    -- Track important buffs/debuffs
    WR.Auras:RegisterImportantAura(self.spells.VIRULENT_PLAGUE, 90, false, true)
    WR.Auras:RegisterImportantAura(self.spells.FESTERING_WOUND, 85, false, true)
    WR.Auras:RegisterImportantAura(self.spells.DARK_TRANSFORMATION, 90, true, false)
    WR.Auras:RegisterImportantAura(self.spells.SUDDEN_DOOM, 80, true, false)
    WR.Auras:RegisterImportantAura(self.spells.RUNIC_CORRUPTION, 80, true, false)
    WR.Auras:RegisterImportantAura(self.spells.SOUL_REAPER, 85, false, true)
    WR.Auras:RegisterImportantAura(self.spells.UNHOLY_PACT, 85, true, false)
    
    -- Define Unholy single target rotation
    self.singleTargetRotation = {
        -- Apply Virulent Plague
        {
            spell = self.spells.OUTBREAK,
            condition = function(self)
                return not self:HasDebuff(self.spells.VIRULENT_PLAGUE) or
                       self:GetDebuffRemaining(self.spells.VIRULENT_PLAGUE) < 4
            end
        },
        
        -- Use Unholy Blight if talented (replaces Outbreak)
        {
            spell = self.spells.UNHOLY_BLIGHT,
            condition = function(self)
                return IsSpellKnown(self.spells.UNHOLY_BLIGHT) and
                       not self:SpellOnCooldown(self.spells.UNHOLY_BLIGHT) and
                       (not self:HasDebuff(self.spells.VIRULENT_PLAGUE) or
                        self:GetDebuffRemaining(self.spells.VIRULENT_PLAGUE) < 4)
            end
        },
        
        -- Use Army of the Dead on cooldown
        {
            spell = self.spells.ARMY_OF_THE_DEAD,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.ARMY_OF_THE_DEAD) and
                       not self:IsMoving() -- Requires standing still to cast
            end
        },
        
        -- Use covenant abilities
        { 
            spell = self.spells.SHACKLE_THE_UNWORTHY,
            condition = function(self) return IsSpellKnown(self.spells.SHACKLE_THE_UNWORTHY) end
        },
        { 
            spell = self.spells.SWARMING_MIST,
            condition = function(self) return IsSpellKnown(self.spells.SWARMING_MIST) end
        },
        { 
            spell = self.spells.ABOMINATION_LIMB,
            condition = function(self) return IsSpellKnown(self.spells.ABOMINATION_LIMB) end
        },
        { 
            spell = self.spells.DEATHS_DUE,
            condition = function(self) return IsSpellKnown(self.spells.DEATHS_DUE) end
        },
        
        -- Use Dark Transformation on cooldown
        {
            spell = self.spells.DARK_TRANSFORMATION,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.DARK_TRANSFORMATION)
            end
        },
        
        -- Stack Festering Wounds
        {
            spell = self.spells.FESTERING_STRIKE,
            condition = function(self)
                return self:GetDebuffStacks(self.spells.FESTERING_WOUND) < 4
            end
        },
        
        -- Use Apocalypse with at least 4 Festering Wounds
        {
            spell = self.spells.APOCALYPSE,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.APOCALYPSE) and
                       self:GetDebuffStacks(self.spells.FESTERING_WOUND) >= 4
            end
        },
        
        -- Use Unholy Assault as a burst cooldown
        {
            spell = self.spells.UNHOLY_ASSAULT,
            condition = function(self)
                return IsSpellKnown(self.spells.UNHOLY_ASSAULT) and
                       not self:SpellOnCooldown(self.spells.UNHOLY_ASSAULT) and
                       self:HasBuff(self.spells.DARK_TRANSFORMATION)
            end
        },
        
        -- Use Soul Reaper if talented
        {
            spell = self.spells.SOUL_REAPER,
            condition = function(self)
                return IsSpellKnown(self.spells.SOUL_REAPER) and
                       not self:SpellOnCooldown(self.spells.SOUL_REAPER) and
                       self:GetTargetHealthPct() < 35
            end
        },
        
        -- Use Summon Gargoyle if talented
        {
            spell = self.spells.SUMMON_GARGOYLE,
            condition = function(self)
                return IsSpellKnown(self.spells.SUMMON_GARGOYLE) and
                       not self:SpellOnCooldown(self.spells.SUMMON_GARGOYLE)
            end
        },
        
        -- Use Defile if talented
        {
            spell = self.spells.DEFILE,
            condition = function(self)
                return IsSpellKnown(self.spells.DEFILE) and
                       not self:SpellOnCooldown(self.spells.DEFILE)
            end
        },
        
        -- Use Death and Decay for AoE or if Death and Decay talent is used
        {
            spell = self.spells.DEATH_AND_DECAY,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.DEATH_AND_DECAY)
            end
        },
        
        -- Use Scourge Strike or Clawing Shadows to pop Festering Wounds
        {
            spell = self.spells.CLAWING_SHADOWS,
            condition = function(self)
                return IsSpellKnown(self.spells.CLAWING_SHADOWS) and
                       self:GetDebuffStacks(self.spells.FESTERING_WOUND) > 0
            end
        },
        {
            spell = self.spells.SCOURGE_STRIKE,
            condition = function(self)
                return not IsSpellKnown(self.spells.CLAWING_SHADOWS) and
                       self:GetDebuffStacks(self.spells.FESTERING_WOUND) > 0
            end
        },
        
        -- Use Death Coil with Sudden Doom proc
        {
            spell = self.spells.DEATH_COIL,
            condition = function(self)
                return self:HasBuff(self.spells.SUDDEN_DOOM)
            end
        },
        
        -- Use Death Coil to avoid capping Runic Power
        {
            spell = self.spells.DEATH_COIL,
            condition = function(self)
                return self:GetRunicPower() >= 80
            end
        },
        
        -- Generate more Festering Wounds
        { spell = self.spells.FESTERING_STRIKE }
    }
    
    -- AoE rotation for Unholy
    self.aoeRotation = {
        -- Apply Virulent Plague
        {
            spell = self.spells.OUTBREAK,
            condition = function(self)
                return not self:HasDebuff(self.spells.VIRULENT_PLAGUE) or
                       self:GetDebuffRemaining(self.spells.VIRULENT_PLAGUE) < 4
            end
        },
        
        -- Use Unholy Blight if talented for AoE
        {
            spell = self.spells.UNHOLY_BLIGHT,
            condition = function(self)
                return IsSpellKnown(self.spells.UNHOLY_BLIGHT) and
                       not self:SpellOnCooldown(self.spells.UNHOLY_BLIGHT) and
                       self:GetEnemyCount(10) >= 3
            end
        },
        
        -- Use Army of the Dead for big pulls
        {
            spell = self.spells.ARMY_OF_THE_DEAD,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.ARMY_OF_THE_DEAD) and
                       self:GetEnemyCount(10) >= 4 and
                       not self:IsMoving() -- Requires standing still to cast
            end
        },
        
        -- Use covenant abilities for AoE
        { 
            spell = self.spells.ABOMINATION_LIMB,
            condition = function(self) 
                return IsSpellKnown(self.spells.ABOMINATION_LIMB) and
                       self:GetEnemyCount(8) >= 3
            end
        },
        { 
            spell = self.spells.SWARMING_MIST,
            condition = function(self) 
                return IsSpellKnown(self.spells.SWARMING_MIST) and
                       self:GetEnemyCount(8) >= 3
            end
        },
        { 
            spell = self.spells.DEATHS_DUE,
            condition = function(self) return IsSpellKnown(self.spells.DEATHS_DUE) end
        },
        
        -- Use Dark Transformation on cooldown
        {
            spell = self.spells.DARK_TRANSFORMATION,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.DARK_TRANSFORMATION)
            end
        },
        
        -- Stack Festering Wounds for AoE
        {
            spell = self.spells.FESTERING_STRIKE,
            condition = function(self)
                return self:GetDebuffStacks(self.spells.FESTERING_WOUND) < 3
            end
        },
        
        -- Use Apocalypse for AoE adds
        {
            spell = self.spells.APOCALYPSE,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.APOCALYPSE) and
                       self:GetDebuffStacks(self.spells.FESTERING_WOUND) >= 4 and
                       self:GetEnemyCount(10) >= 3
            end
        },
        
        -- Use Death and Decay for AoE
        {
            spell = self.spells.DEATH_AND_DECAY,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.DEATH_AND_DECAY) and
                       self:GetEnemyCount(10) >= 2
            end
        },
        
        -- Use Defile instead of Death and Decay if talented
        {
            spell = self.spells.DEFILE,
            condition = function(self)
                return IsSpellKnown(self.spells.DEFILE) and
                       not self:SpellOnCooldown(self.spells.DEFILE) and
                       self:GetEnemyCount(10) >= 2
            end
        },
        
        -- Use Epidemic for AoE damage
        {
            spell = self.spells.EPIDEMIC,
            condition = function(self)
                return IsSpellKnown(self.spells.EPIDEMIC) and
                       self:GetEnemyCount(10) >= 3 and
                       self:GetRunicPower() >= 30
            end
        },
        
        -- Use Scourge Strike inside Death and Decay for AoE
        {
            spell = self.spells.SCOURGE_STRIKE,
            condition = function(self)
                return self:GetDebuffStacks(self.spells.FESTERING_WOUND) > 0 and
                       self:IsStandingInDND() and
                       not IsSpellKnown(self.spells.CLAWING_SHADOWS)
            end
        },
        
        -- Use Clawing Shadows if talented
        {
            spell = self.spells.CLAWING_SHADOWS,
            condition = function(self)
                return IsSpellKnown(self.spells.CLAWING_SHADOWS) and
                       self:GetDebuffStacks(self.spells.FESTERING_WOUND) > 0
            end
        },
        
        -- Use Death Coil to spend Runic Power if not using Epidemic
        {
            spell = self.spells.DEATH_COIL,
            condition = function(self)
                return (not IsSpellKnown(self.spells.EPIDEMIC) or
                        self:GetEnemyCount(10) < 3) and
                       self:GetRunicPower() >= 80
            end
        },
        
        -- Generate more Festering Wounds with Festering Strike
        { spell = self.spells.FESTERING_STRIKE }
    }
    
    -- Define burst rotation
    self.burstRotation = {
        { spell = self.spells.DARK_TRANSFORMATION },
        {
            spell = self.spells.UNHOLY_ASSAULT,
            condition = function(self) return IsSpellKnown(self.spells.UNHOLY_ASSAULT) end
        },
        { spell = self.spells.APOCALYPSE },
        {
            spell = self.spells.SUMMON_GARGOYLE,
            condition = function(self) return IsSpellKnown(self.spells.SUMMON_GARGOYLE) end
        },
        { 
            spell = self.spells.ABOMINATION_LIMB,
            condition = function(self) return IsSpellKnown(self.spells.ABOMINATION_LIMB) end
        },
        { 
            spell = self.spells.SWARMING_MIST,
            condition = function(self) return IsSpellKnown(self.spells.SWARMING_MIST) end
        },
        {
            spell = self.spells.DEATH_AND_DECAY,
            condition = function(self) return not IsSpellKnown(self.spells.DEFILE) end
        },
        {
            spell = self.spells.DEFILE,
            condition = function(self) return IsSpellKnown(self.spells.DEFILE) end
        }
    }
end

-- Check if player is standing in Death and Decay
function DeathKnight:IsStandingInDND()
    -- This would use actual zone checks in the real addon
    -- For our purposes, we'll just check if the spell is on cooldown
    return self:SpellOnCooldown(self.spells.DEATH_AND_DECAY) or
           (IsSpellKnown(self.spells.DEFILE) and self:SpellOnCooldown(self.spells.DEFILE))
end

-- Get current rune count
function DeathKnight:GetRuneCount()
    -- In a real addon, this would use GetRuneCooldown() API
    -- For our purposes, we'll simulate a random rune count
    return math.random(0, 6)
end

-- Class-specific pre-rotation checks
function DeathKnight:ClassSpecificChecks()
    -- Check for class-specific conditions
    
    -- Check for active pet/raise dead if it's an Unholy DK
    if self.currentSpec == SPEC_UNHOLY and
       not self:HasActivePet() and
       not self:SpellOnCooldown(self.spells.RAISE_DEAD) then
        WR.Queue:Add(self.spells.RAISE_DEAD)
        return false
    end
    
    return true
end

-- Check if the player has an active pet
function DeathKnight:HasActivePet()
    -- In a real addon, would use UnitExists("pet")
    -- For our mock implementation, just return true to avoid endless pet summons
    return true
end

-- Get default action when nothing else is available
function DeathKnight:GetDefaultAction()
    if self.currentSpec == SPEC_BLOOD then
        return self.spells.HEART_STRIKE
    elseif self.currentSpec == SPEC_FROST then
        return self.spells.FROST_STRIKE
    elseif self.currentSpec == SPEC_UNHOLY then
        return self.spells.SCOURGE_STRIKE
    end
    
    return nil
end

-- Initialize the module
DeathKnight:Initialize()

return DeathKnight