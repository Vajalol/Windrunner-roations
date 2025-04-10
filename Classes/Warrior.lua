local addonName, WR = ...

-- Warrior Class module
local Warrior = {}
WR.Classes = WR.Classes or {}
WR.Classes.WARRIOR = Warrior

-- Inherit from BaseClass
setmetatable(Warrior, {__index = WR.BaseClass})

-- Resource type for warriors
Warrior.resourceType = Enum.PowerType.Rage

-- Define spec IDs
local SPEC_ARMS = 71
local SPEC_FURY = 72
local SPEC_PROTECTION = 73

-- Class initialization
function Warrior:Initialize()
    -- Inherit base initialization
    WR.BaseClass.Initialize(self)
    
    -- Register Specializations
    self:RegisterSpec(SPEC_ARMS, "Arms")
    self:RegisterSpec(SPEC_FURY, "Fury")
    self:RegisterSpec(SPEC_PROTECTION, "Protection")
    
    -- Shared spell IDs across all warrior specs
    self.spells = {
        -- Common warrior abilities
        BATTLE_SHOUT = 6673,
        CHARGE = 100,
        EXECUTE = 163201,
        HAMSTRING = 1715,
        HEROIC_LEAP = 6544,
        INTIMIDATING_SHOUT = 5246,
        PUMMEL = 6552,
        RALLYING_CRY = 97462,
        SLAM = 1464,
        VICTORY_RUSH = 34428,
        IGNORE_PAIN = 190456,
        BERSERKER_RAGE = 18499,
        INTERVENE = 3411,
        SPELL_REFLECTION = 23920,
        SHATTERING_THROW = 64382,
        HEROIC_THROW = 57755,
        COMMANDING_SHOUT = 97463,
        STORM_BOLT = 107570,
        IMPENDING_VICTORY = 202168,
        
        -- Covenant abilities
        CONDEMN = 317349,         -- Venthyr alternative to Execute
        SPEAR_OF_BASTION = 307865, -- Kyrian
        CONQUERORS_BANNER = 324143, -- Necrolord
        ANCIENT_AFTERSHOCK = 325886, -- Night Fae
    }
    
    -- Load shared warrior data
    self:LoadSharedWarriorData()
    
    WR:Debug("Warrior module initialized")
end

-- Load shared spell and mechanics data for all warrior specs
function Warrior:LoadSharedWarriorData()
    -- Register important buffs
    WR.Auras:RegisterImportantAura(self.spells.BATTLE_SHOUT, 60, true, false)
    WR.Auras:RegisterImportantAura(self.spells.RALLYING_CRY, 85, true, false)
    WR.Auras:RegisterImportantAura(self.spells.IGNORE_PAIN, 70, true, false)
    WR.Auras:RegisterImportantAura(self.spells.COMMANDING_SHOUT, 75, true, false)
    
    -- Setup cooldown tracking
    WR.Cooldown:StartTracking(self.spells.PUMMEL)
    WR.Cooldown:StartTracking(self.spells.CHARGE)
    WR.Cooldown:StartTracking(self.spells.HEROIC_LEAP)
    WR.Cooldown:StartTracking(self.spells.RALLYING_CRY)
    WR.Cooldown:StartTracking(self.spells.SPELL_REFLECTION)
    WR.Cooldown:StartTracking(self.spells.BERSERKER_RAGE)
    
    -- Set up interrupt rotation (shared by all specs)
    self.interruptRotation = {
        { spell = self.spells.PUMMEL }
    }
    
    -- Set up defensive rotation (shared by all specs)
    self.defensiveRotation = {
        { spell = self.spells.RALLYING_CRY, threshold = 30 },
        { 
            spell = self.spells.IGNORE_PAIN, 
            condition = function(self)
                return IsSpellKnown(self.spells.IGNORE_PAIN) and
                       self:GetResource() >= 40
            end
        },
        { 
            spell = self.spells.VICTORY_RUSH, 
            condition = function(self)
                return self:HasBuff(32216) -- Victorious buff
            end
        },
        {
            spell = self.spells.IMPENDING_VICTORY,
            condition = function(self)
                return IsSpellKnown(self.spells.IMPENDING_VICTORY)
            end
        }
    }
end

-- Load a specific specialization
function Warrior:LoadSpec(specId)
    -- Call the base class method to set up common components
    WR.BaseClass.LoadSpec(self, specId)
    
    -- Load specific spec data
    if specId == SPEC_ARMS then
        self:LoadArmsSpec()
    elseif specId == SPEC_FURY then
        self:LoadFurySpec()
    elseif specId == SPEC_PROTECTION then
        self:LoadProtectionSpec()
    end
    
    WR:Debug("Loaded warrior spec:", self.specData.name)
    return true
end

-- Load Arms specialization
function Warrior:LoadArmsSpec()
    -- Arms-specific spells
    self.spells.MORTAL_STRIKE = 12294
    self.spells.OVERPOWER = 7384
    self.spells.BLADESTORM = 227847
    self.spells.SWEEPING_STRIKES = 260708
    self.spells.COLOSSUS_SMASH = 167105
    self.spells.WARBREAKER = 262161
    self.spells.CLEAVE = 845
    self.spells.REND = 772
    self.spells.SKULLSPLITTER = 260643
    self.spells.AVATAR = 107574
    self.spells.DEADLY_CALM = 262228
    self.spells.SHARPEN_BLADE = 198817
    self.spells.DIE_BY_THE_SWORD = 118038
    self.spells.DEFENSIVE_STANCE = 197690
    self.spells.COLLATERAL_DAMAGE = 334783
    self.spells.DREADNAUGHT = 262150
    self.spells.RAVAGER = 152277
    
    -- Setup cooldown and aura tracking for Arms
    WR.Cooldown:StartTracking(self.spells.MORTAL_STRIKE)
    WR.Cooldown:StartTracking(self.spells.OVERPOWER)
    WR.Cooldown:StartTracking(self.spells.BLADESTORM)
    WR.Cooldown:StartTracking(self.spells.COLOSSUS_SMASH)
    WR.Cooldown:StartTracking(self.spells.WARBREAKER)
    WR.Cooldown:StartTracking(self.spells.SKULLSPLITTER)
    WR.Cooldown:StartTracking(self.spells.AVATAR)
    WR.Cooldown:StartTracking(self.spells.DIE_BY_THE_SWORD)
    
    -- Track important buffs/debuffs
    WR.Auras:RegisterImportantAura(self.spells.SWEEPING_STRIKES, 80, true, false)
    WR.Auras:RegisterImportantAura(self.spells.AVATAR, 90, true, false)
    WR.Auras:RegisterImportantAura(self.spells.DEADLY_CALM, 70, true, false)
    WR.Auras:RegisterImportantAura(self.spells.DEFENSIVE_STANCE, 75, true, false)
    WR.Auras:RegisterImportantAura(self.spells.DIE_BY_THE_SWORD, 85, true, false)
    WR.Auras:RegisterImportantAura(7384, 60, true, false) -- Overpower proc
    WR.Auras:RegisterImportantAura(self.spells.REND, 70, false, true) -- Rend debuff
    WR.Auras:RegisterImportantAura(208086, 90, false, true) -- Colossus Smash debuff
    
    -- Define Arms rotation, prioritizing abilities in order
    self.singleTargetRotation = {
        -- Use Avatar for burst damage
        { spell = self.spells.AVATAR },
        
        -- Use covenant abilities
        { 
            spell = self.spells.SPEAR_OF_BASTION,
            condition = function(self) return IsSpellKnown(self.spells.SPEAR_OF_BASTION) end
        },
        { 
            spell = self.spells.CONQUERORS_BANNER,
            condition = function(self) return IsSpellKnown(self.spells.CONQUERORS_BANNER) end
        },
        { 
            spell = self.spells.ANCIENT_AFTERSHOCK,
            condition = function(self) return IsSpellKnown(self.spells.ANCIENT_AFTERSHOCK) end
        },
        
        -- Use Deadly Calm for burst window
        {
            spell = self.spells.DEADLY_CALM,
            condition = function(self)
                return IsSpellKnown(self.spells.DEADLY_CALM)
            end
        },
        
        -- Apply Colossus Smash / Warbreaker debuff
        {
            spell = self.spells.WARBREAKER,
            condition = function(self)
                return IsSpellKnown(self.spells.WARBREAKER) and
                       not self:HasDebuff(208086) -- Colossus Smash debuff
            end
        },
        {
            spell = self.spells.COLOSSUS_SMASH,
            condition = function(self)
                return not IsSpellKnown(self.spells.WARBREAKER) and
                       not self:HasDebuff(208086) -- Colossus Smash debuff
            end
        },
        
        -- Apply Rend if talented and not active
        {
            spell = self.spells.REND,
            condition = function(self)
                return IsSpellKnown(self.spells.REND) and
                       not self:HasDebuff(self.spells.REND) and
                       self:GetResource() >= 30
            end
        },
        
        -- Use Ravager if talented
        {
            spell = self.spells.RAVAGER,
            condition = function(self)
                return IsSpellKnown(self.spells.RAVAGER)
            end
        },
        
        -- Use Bladestorm for single target during Colossus Smash window
        {
            spell = self.spells.BLADESTORM,
            condition = function(self)
                return self:HasDebuff(208086) and -- Colossus Smash debuff
                       self:GetEnemyCount(8) <= 1 -- Only in single target
            end
        },
        
        -- Use Skullsplitter to generate rage when low
        {
            spell = self.spells.SKULLSPLITTER,
            condition = function(self)
                return IsSpellKnown(self.spells.SKULLSPLITTER) and
                       self:GetResourcePct() < 40
            end
        },
        
        -- Use Execute in execute phase
        {
            spell = self.spells.CONDEMN,
            condition = function(self)
                return IsSpellKnown(self.spells.CONDEMN) and
                       (self:TargetInExecuteRange() or self:GetTargetHealthPct() > 80) and
                       self:GetResource() >= 20
            end
        },
        {
            spell = self.spells.EXECUTE,
            condition = function(self)
                return self:TargetInExecuteRange() and
                       not IsSpellKnown(self.spells.CONDEMN) and
                       self:GetResource() >= 20
            end
        },
        
        -- Use Overpower on cooldown
        { 
            spell = self.spells.OVERPOWER,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.OVERPOWER)
            end
        },
        
        -- Use Mortal Strike on cooldown
        {
            spell = self.spells.MORTAL_STRIKE,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.MORTAL_STRIKE) and
                       self:GetResource() >= 30
            end
        },
        
        -- Use Slam as filler when high on rage and not in execute phase
        {
            spell = self.spells.SLAM,
            condition = function(self)
                return not self:TargetInExecuteRange() and
                       self:GetResource() >= 20
            end
        }
    }
    
    -- Define AoE rotation for Arms
    self.aoeRotation = {
        -- Apply Sweeping Strikes for cleave
        { spell = self.spells.SWEEPING_STRIKES },
        
        -- Use Avatar for burst damage
        { spell = self.spells.AVATAR },
        
        -- Use covenant abilities
        { 
            spell = self.spells.SPEAR_OF_BASTION,
            condition = function(self) return IsSpellKnown(self.spells.SPEAR_OF_BASTION) end
        },
        { 
            spell = self.spells.CONQUERORS_BANNER,
            condition = function(self) return IsSpellKnown(self.spells.CONQUERORS_BANNER) end
        },
        { 
            spell = self.spells.ANCIENT_AFTERSHOCK,
            condition = function(self) return IsSpellKnown(self.spells.ANCIENT_AFTERSHOCK) end
        },
        
        -- Apply Colossus Smash / Warbreaker debuff
        {
            spell = self.spells.WARBREAKER,
            condition = function(self)
                return IsSpellKnown(self.spells.WARBREAKER)
            end
        },
        {
            spell = self.spells.COLOSSUS_SMASH,
            condition = function(self)
                return not IsSpellKnown(self.spells.WARBREAKER) and
                       not self:HasDebuff(208086) -- Colossus Smash debuff
            end
        },
        
        -- Use Bladestorm for AoE
        { spell = self.spells.BLADESTORM },
        
        -- Use Ravager if talented
        {
            spell = self.spells.RAVAGER,
            condition = function(self)
                return IsSpellKnown(self.spells.RAVAGER)
            end
        },
        
        -- Use Cleave for AoE
        {
            spell = self.spells.CLEAVE,
            condition = function(self)
                return self:GetResource() >= 20
            end
        },
        
        -- Apply Rend to multiple targets if talented
        {
            spell = self.spells.REND,
            condition = function(self)
                return IsSpellKnown(self.spells.REND) and
                       not self:HasDebuff(self.spells.REND) and
                       self:GetResource() >= 30
            end
        },
        
        -- Use Skullsplitter to generate rage when low
        {
            spell = self.spells.SKULLSPLITTER,
            condition = function(self)
                return IsSpellKnown(self.spells.SKULLSPLITTER) and
                       self:GetResourcePct() < 40
            end
        },
        
        -- Use Execute in execute phase
        {
            spell = self.spells.CONDEMN,
            condition = function(self)
                return IsSpellKnown(self.spells.CONDEMN) and
                       (self:TargetInExecuteRange() or self:GetTargetHealthPct() > 80) and
                       self:GetResource() >= 20
            end
        },
        {
            spell = self.spells.EXECUTE,
            condition = function(self)
                return self:TargetInExecuteRange() and
                       not IsSpellKnown(self.spells.CONDEMN) and
                       self:GetResource() >= 20
            end
        },
        
        -- Use Overpower on cooldown
        { 
            spell = self.spells.OVERPOWER,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.OVERPOWER)
            end
        },
        
        -- Use Mortal Strike on cooldown
        {
            spell = self.spells.MORTAL_STRIKE,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.MORTAL_STRIKE) and
                       self:GetResource() >= 30
            end
        },
        
        -- Use Whirlwind as filler in AoE
        {
            spell = 1680, -- Whirlwind
            condition = function(self)
                return self:GetResource() >= 30
            end
        }
    }
    
    -- Define burst rotation
    self.burstRotation = {
        { spell = self.spells.AVATAR },
        { 
            spell = self.spells.DEADLY_CALM,
            condition = function(self) return IsSpellKnown(self.spells.DEADLY_CALM) end
        },
        {
            spell = self.spells.WARBREAKER,
            condition = function(self) return IsSpellKnown(self.spells.WARBREAKER) end
        },
        {
            spell = self.spells.COLOSSUS_SMASH,
            condition = function(self) return not IsSpellKnown(self.spells.WARBREAKER) end
        },
        { 
            spell = self.spells.SPEAR_OF_BASTION,
            condition = function(self) return IsSpellKnown(self.spells.SPEAR_OF_BASTION) end
        },
        { 
            spell = self.spells.CONQUERORS_BANNER,
            condition = function(self) return IsSpellKnown(self.spells.CONQUERORS_BANNER) end
        },
        { 
            spell = self.spells.ANCIENT_AFTERSHOCK,
            condition = function(self) return IsSpellKnown(self.spells.ANCIENT_AFTERSHOCK) end
        },
        {
            spell = self.spells.RAVAGER,
            condition = function(self) return IsSpellKnown(self.spells.RAVAGER) end
        }
    }
    
    -- Add Arms-specific defensive abilities
    table.insert(self.defensiveRotation, { 
        spell = self.spells.DIE_BY_THE_SWORD, 
        threshold = 30 
    })
    
    table.insert(self.defensiveRotation, {
        spell = self.spells.DEFENSIVE_STANCE,
        condition = function(self)
            return IsSpellKnown(self.spells.DEFENSIVE_STANCE) and
                   not self:HasBuff(self.spells.DEFENSIVE_STANCE) and
                   self:GetHealthPct() < 70
        end
    })
end

-- Load Fury specialization
function Warrior:LoadFurySpec()
    -- Fury-specific spells
    self.spells.ENRAGE = 184361
    self.spells.RAGING_BLOW = 85288
    self.spells.RAMPAGE = 184367
    self.spells.BLOODTHIRST = 23881
    self.spells.WHIRLWIND = 190411
    self.spells.BLOODBATH = 335096
    self.spells.ONSLAUGHT = 315720
    self.spells.RECKLESSNESS = 1719
    self.spells.BLADESTORM = 46924
    self.spells.SIEGEBREAKER = 280772
    self.spells.CRUSHING_BLOW = 335097
    self.spells.DRAGON_ROAR = 118000
    self.spells.FRENZY = 335077
    self.spells.MEAT_CLEAVER = 85739
    self.spells.SUDDEN_DEATH = 280776
    self.spells.ENRAGED_REGENERATION = 184364
    
    -- Setup cooldown and aura tracking for Fury
    WR.Cooldown:StartTracking(self.spells.RAGING_BLOW)
    WR.Cooldown:StartTracking(self.spells.BLOODTHIRST)
    WR.Cooldown:StartTracking(self.spells.RECKLESSNESS)
    WR.Cooldown:StartTracking(self.spells.BLADESTORM)
    WR.Cooldown:StartTracking(self.spells.DRAGON_ROAR)
    WR.Cooldown:StartTracking(self.spells.ENRAGED_REGENERATION)
    
    -- Track important buffs/debuffs
    WR.Auras:RegisterImportantAura(self.spells.ENRAGE, 90, true, false)
    WR.Auras:RegisterImportantAura(self.spells.MEAT_CLEAVER, 75, true, false)
    WR.Auras:RegisterImportantAura(self.spells.RECKLESSNESS, 85, true, false)
    WR.Auras:RegisterImportantAura(self.spells.ENRAGED_REGENERATION, 80, true, false)
    WR.Auras:RegisterImportantAura(self.spells.SUDDEN_DEATH, 70, true, false) -- Sudden Death proc
    WR.Auras:RegisterImportantAura(self.spells.FRENZY, 75, true, false) -- Frenzy stacks
    WR.Auras:RegisterImportantAura(self.spells.SIEGEBREAKER, 80, false, true) -- Siegebreaker debuff
    
    -- Define Fury rotation, prioritizing abilities in order
    self.singleTargetRotation = {
        -- Use Recklessness for burst damage
        { spell = self.spells.RECKLESSNESS },
        
        -- Use covenant abilities
        { 
            spell = self.spells.SPEAR_OF_BASTION,
            condition = function(self) return IsSpellKnown(self.spells.SPEAR_OF_BASTION) end
        },
        { 
            spell = self.spells.CONQUERORS_BANNER,
            condition = function(self) return IsSpellKnown(self.spells.CONQUERORS_BANNER) end
        },
        { 
            spell = self.spells.ANCIENT_AFTERSHOCK,
            condition = function(self) return IsSpellKnown(self.spells.ANCIENT_AFTERSHOCK) end
        },
        
        -- Apply Siegebreaker debuff if talented
        {
            spell = self.spells.SIEGEBREAKER,
            condition = function(self)
                return IsSpellKnown(self.spells.SIEGEBREAKER)
            end
        },
        
        -- Use Dragon Roar if talented
        {
            spell = self.spells.DRAGON_ROAR,
            condition = function(self)
                return IsSpellKnown(self.spells.DRAGON_ROAR)
            end
        },
        
        -- Use Execute in execute phase
        {
            spell = self.spells.CONDEMN,
            condition = function(self)
                return IsSpellKnown(self.spells.CONDEMN) and
                       (self:TargetInExecuteRange() or self:GetTargetHealthPct() > 80) and
                       (self:HasBuff(self.spells.SUDDEN_DEATH) or 
                        self:GetResource() >= 20)
            end
        },
        {
            spell = self.spells.EXECUTE,
            condition = function(self)
                return self:TargetInExecuteRange() and
                       not IsSpellKnown(self.spells.CONDEMN) and
                       (self:HasBuff(self.spells.SUDDEN_DEATH) or 
                        self:GetResource() >= 20)
            end
        },
        
        -- Use Rampage when at 80+ rage or to refresh Enrage
        {
            spell = self.spells.RAMPAGE,
            condition = function(self)
                return self:GetResource() >= 80 or 
                       not self:HasBuff(self.spells.ENRAGE)
            end
        },
        
        -- Use Onslaught if talented
        {
            spell = self.spells.ONSLAUGHT,
            condition = function(self)
                return IsSpellKnown(self.spells.ONSLAUGHT)
            end
        },
        
        -- Use Bloodthirst to try to proc Enrage
        {
            spell = self.spells.BLOODTHIRST,
            condition = function(self)
                return not self:HasBuff(self.spells.ENRAGE)
            end
        },
        
        -- Use Crushing Blow if talented
        {
            spell = self.spells.CRUSHING_BLOW,
            condition = function(self)
                return IsSpellKnown(self.spells.CRUSHING_BLOW) and
                       self:HasBuff(self.spells.ENRAGE)
            end
        },
        
        -- Use Raging Blow 
        {
            spell = self.spells.RAGING_BLOW,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.RAGING_BLOW)
            end
        },
        
        -- Use Bloodthirst on cooldown
        { 
            spell = self.spells.BLOODTHIRST,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.BLOODTHIRST)
            end
        },
        
        -- Use Whirlwind as a filler
        { spell = self.spells.WHIRLWIND }
    }
    
    -- Define AoE rotation for Fury
    self.aoeRotation = {
        -- Use Recklessness for burst damage
        { spell = self.spells.RECKLESSNESS },
        
        -- Use covenant abilities
        { 
            spell = self.spells.SPEAR_OF_BASTION,
            condition = function(self) return IsSpellKnown(self.spells.SPEAR_OF_BASTION) end
        },
        { 
            spell = self.spells.CONQUERORS_BANNER,
            condition = function(self) return IsSpellKnown(self.spells.CONQUERORS_BANNER) end
        },
        { 
            spell = self.spells.ANCIENT_AFTERSHOCK,
            condition = function(self) return IsSpellKnown(self.spells.ANCIENT_AFTERSHOCK) end
        },
        
        -- Use Bladestorm for AoE
        { spell = self.spells.BLADESTORM },
        
        -- Apply Siegebreaker debuff if talented
        {
            spell = self.spells.SIEGEBREAKER,
            condition = function(self)
                return IsSpellKnown(self.spells.SIEGEBREAKER)
            end
        },
        
        -- Use Dragon Roar if talented
        {
            spell = self.spells.DRAGON_ROAR,
            condition = function(self)
                return IsSpellKnown(self.spells.DRAGON_ROAR)
            end
        },
        
        -- Use Whirlwind to apply meat cleaver buff
        {
            spell = self.spells.WHIRLWIND,
            condition = function(self)
                return not self:HasBuff(self.spells.MEAT_CLEAVER)
            end
        },
        
        -- Use Rampage when at 80+ rage or to refresh Enrage
        {
            spell = self.spells.RAMPAGE,
            condition = function(self)
                return self:GetResource() >= 80 or 
                       not self:HasBuff(self.spells.ENRAGE)
            end
        },
        
        -- Use Bloodthirst to try to proc Enrage
        {
            spell = self.spells.BLOODTHIRST,
            condition = function(self)
                return not self:HasBuff(self.spells.ENRAGE)
            end
        },
        
        -- Use Execute in execute phase
        {
            spell = self.spells.CONDEMN,
            condition = function(self)
                return IsSpellKnown(self.spells.CONDEMN) and
                       (self:TargetInExecuteRange() or self:GetTargetHealthPct() > 80) and
                       self:HasBuff(self.spells.MEAT_CLEAVER) and
                       (self:HasBuff(self.spells.SUDDEN_DEATH) or 
                        self:GetResource() >= 20)
            end
        },
        {
            spell = self.spells.EXECUTE,
            condition = function(self)
                return self:TargetInExecuteRange() and
                       not IsSpellKnown(self.spells.CONDEMN) and
                       self:HasBuff(self.spells.MEAT_CLEAVER) and
                       (self:HasBuff(self.spells.SUDDEN_DEATH) or 
                        self:GetResource() >= 20)
            end
        },
        
        -- Use Raging Blow with Meat Cleaver
        {
            spell = self.spells.RAGING_BLOW,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.RAGING_BLOW) and
                       self:HasBuff(self.spells.MEAT_CLEAVER)
            end
        },
        
        -- Use Bloodthirst on cooldown
        { 
            spell = self.spells.BLOODTHIRST,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.BLOODTHIRST)
            end
        },
        
        -- Use Whirlwind as a filler
        { spell = self.spells.WHIRLWIND }
    }
    
    -- Define burst rotation
    self.burstRotation = {
        { spell = self.spells.RECKLESSNESS },
        {
            spell = self.spells.SIEGEBREAKER,
            condition = function(self) return IsSpellKnown(self.spells.SIEGEBREAKER) end
        },
        { 
            spell = self.spells.SPEAR_OF_BASTION,
            condition = function(self) return IsSpellKnown(self.spells.SPEAR_OF_BASTION) end
        },
        { 
            spell = self.spells.CONQUERORS_BANNER,
            condition = function(self) return IsSpellKnown(self.spells.CONQUERORS_BANNER) end
        },
        { 
            spell = self.spells.ANCIENT_AFTERSHOCK,
            condition = function(self) return IsSpellKnown(self.spells.ANCIENT_AFTERSHOCK) end
        },
        {
            spell = self.spells.DRAGON_ROAR,
            condition = function(self) return IsSpellKnown(self.spells.DRAGON_ROAR) end
        },
        {
            spell = self.spells.BLADESTORM,
            condition = function(self) return self:GetEnemyCount(8) >= 3 end
        }
    }
    
    -- Add Fury-specific defensive abilities
    table.insert(self.defensiveRotation, { 
        spell = self.spells.ENRAGED_REGENERATION, 
        threshold = 40 
    })
end

-- Load Protection specialization
function Warrior:LoadProtectionSpec()
    -- Protection-specific spells
    self.spells.SHIELD_SLAM = 23922
    self.spells.THUNDER_CLAP = 6343
    self.spells.REVENGE = 6572
    self.spells.DEVASTATE = 20243
    self.spells.SHIELD_BLOCK = 2565
    self.spells.SHIELD_WALL = 871
    self.spells.LAST_STAND = 12975
    self.spells.DEMORALIZING_SHOUT = 1160
    self.spells.SHOCKWAVE = 46968
    self.spells.RAVAGER = 228920
    self.spells.DRAGON_ROAR = 118000
    self.spells.AVATAR = 107574
    self.spells.UNSTOPPABLE_FORCE = 275336
    self.spells.BOLSTER = 280001
    self.spells.BOOMING_VOICE = 202743
    self.spells.HEAVY_REPERCUSSIONS = 203177
    self.spells.SHIELD_BASH = 198912
    
    -- Setup cooldown and aura tracking for Protection
    WR.Cooldown:StartTracking(self.spells.SHIELD_SLAM)
    WR.Cooldown:StartTracking(self.spells.THUNDER_CLAP)
    WR.Cooldown:StartTracking(self.spells.SHIELD_BLOCK)
    WR.Cooldown:StartTracking(self.spells.SHIELD_WALL)
    WR.Cooldown:StartTracking(self.spells.LAST_STAND)
    WR.Cooldown:StartTracking(self.spells.DEMORALIZING_SHOUT)
    WR.Cooldown:StartTracking(self.spells.SHOCKWAVE)
    WR.Cooldown:StartTracking(self.spells.AVATAR)
    
    -- Track important buffs/debuffs
    WR.Auras:RegisterImportantAura(self.spells.SHIELD_BLOCK, 90, true, false)
    WR.Auras:RegisterImportantAura(self.spells.SHIELD_WALL, 95, true, false)
    WR.Auras:RegisterImportantAura(self.spells.LAST_STAND, 85, true, false)
    WR.Auras:RegisterImportantAura(self.spells.AVATAR, 80, true, false)
    WR.Auras:RegisterImportantAura(self.spells.DEMORALIZING_SHOUT, 70, false, true) -- Debuff on enemies
    WR.Auras:RegisterImportantAura(132404, 65, true, false) -- Shield Block buff
    
    -- Define Protection rotation, prioritizing abilities in order
    self.singleTargetRotation = {
        -- Use Shield Block to maintain active mitigation
        {
            spell = self.spells.SHIELD_BLOCK,
            condition = function(self)
                return not self:HasBuff(132404) and -- Shield Block buff
                       self:SpellHasCharges(self.spells.SHIELD_BLOCK) and
                       self:GetResource() >= 30
            end
        },
        
        -- Use Avatar for increased damage and survivability
        { spell = self.spells.AVATAR },
        
        -- Use covenant abilities
        { 
            spell = self.spells.SPEAR_OF_BASTION,
            condition = function(self) return IsSpellKnown(self.spells.SPEAR_OF_BASTION) end
        },
        { 
            spell = self.spells.CONQUERORS_BANNER,
            condition = function(self) return IsSpellKnown(self.spells.CONQUERORS_BANNER) end
        },
        { 
            spell = self.spells.ANCIENT_AFTERSHOCK,
            condition = function(self) return IsSpellKnown(self.spells.ANCIENT_AFTERSHOCK) end
        },
        
        -- Use Demoralizing Shout to reduce enemy damage
        {
            spell = self.spells.DEMORALIZING_SHOUT,
            condition = function(self)
                return not self:HasDebuff(self.spells.DEMORALIZING_SHOUT, "target") and
                       self:GetResource() >= 10
            end
        },
        
        -- Use Dragon Roar if talented
        {
            spell = self.spells.DRAGON_ROAR,
            condition = function(self)
                return IsSpellKnown(self.spells.DRAGON_ROAR)
            end
        },
        
        -- Use Shield Slam on cooldown (high priority)
        { 
            spell = self.spells.SHIELD_SLAM,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.SHIELD_SLAM)
            end
        },
        
        -- Use Thunder Clap to maintain debuff
        {
            spell = self.spells.THUNDER_CLAP,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.THUNDER_CLAP) and
                       self:GetResource() >= 20
            end
        },
        
        -- Use Revenge when it's free or high rage
        {
            spell = self.spells.REVENGE,
            condition = function(self)
                -- Check for Revenge proc or high rage
                local hasFreeRevengeProc = false
                -- In actual implementation, we would check for the free Revenge proc
                -- For now, we'll use high rage as an indicator
                
                return (hasFreeRevengeProc or self:GetResource() >= 70) and
                       self:GetResource() >= 20
            end
        },
        
        -- Use Execute in execute phase
        {
            spell = self.spells.CONDEMN,
            condition = function(self)
                return IsSpellKnown(self.spells.CONDEMN) and
                       (self:TargetInExecuteRange() or self:GetTargetHealthPct() > 80) and
                       self:GetResource() >= 20
            end
        },
        {
            spell = self.spells.EXECUTE,
            condition = function(self)
                return self:TargetInExecuteRange() and
                       not IsSpellKnown(self.spells.CONDEMN) and
                       self:GetResource() >= 20
            end
        },
        
        -- Use Devastate as filler
        { spell = self.spells.DEVASTATE }
    }
    
    -- Define AoE rotation for Protection
    self.aoeRotation = {
        -- Use Shield Block to maintain active mitigation
        {
            spell = self.spells.SHIELD_BLOCK,
            condition = function(self)
                return not self:HasBuff(132404) and -- Shield Block buff
                       self:SpellHasCharges(self.spells.SHIELD_BLOCK) and
                       self:GetResource() >= 30
            end
        },
        
        -- Use Avatar for increased damage and survivability
        { spell = self.spells.AVATAR },
        
        -- Use covenant abilities
        { 
            spell = self.spells.SPEAR_OF_BASTION,
            condition = function(self) return IsSpellKnown(self.spells.SPEAR_OF_BASTION) end
        },
        { 
            spell = self.spells.CONQUERORS_BANNER,
            condition = function(self) return IsSpellKnown(self.spells.CONQUERORS_BANNER) end
        },
        { 
            spell = self.spells.ANCIENT_AFTERSHOCK,
            condition = function(self) return IsSpellKnown(self.spells.ANCIENT_AFTERSHOCK) end
        },
        
        -- Use Demoralizing Shout to reduce enemy damage
        { spell = self.spells.DEMORALIZING_SHOUT },
        
        -- Use Ravager if talented
        {
            spell = self.spells.RAVAGER,
            condition = function(self)
                return IsSpellKnown(self.spells.RAVAGER)
            end
        },
        
        -- Use Shockwave for AoE stun
        { spell = self.spells.SHOCKWAVE },
        
        -- Use Dragon Roar if talented
        {
            spell = self.spells.DRAGON_ROAR,
            condition = function(self)
                return IsSpellKnown(self.spells.DRAGON_ROAR)
            end
        },
        
        -- Use Thunder Clap for AoE threat and damage
        {
            spell = self.spells.THUNDER_CLAP,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.THUNDER_CLAP) and
                       self:GetResource() >= 20
            end
        },
        
        -- Use Revenge for AoE damage
        {
            spell = self.spells.REVENGE,
            condition = function(self)
                return self:GetResource() >= 20
            end
        },
        
        -- Use Shield Slam on cooldown
        { 
            spell = self.spells.SHIELD_SLAM,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.SHIELD_SLAM)
            end
        },
        
        -- Use Devastate as filler
        { spell = self.spells.DEVASTATE }
    }
    
    -- Define burst rotation
    self.burstRotation = {
        { spell = self.spells.AVATAR },
        { 
            spell = self.spells.SPEAR_OF_BASTION,
            condition = function(self) return IsSpellKnown(self.spells.SPEAR_OF_BASTION) end
        },
        { 
            spell = self.spells.CONQUERORS_BANNER,
            condition = function(self) return IsSpellKnown(self.spells.CONQUERORS_BANNER) end
        },
        { 
            spell = self.spells.ANCIENT_AFTERSHOCK,
            condition = function(self) return IsSpellKnown(self.spells.ANCIENT_AFTERSHOCK) end
        },
        { spell = self.spells.DEMORALIZING_SHOUT },
        {
            spell = self.spells.RAVAGER,
            condition = function(self) return IsSpellKnown(self.spells.RAVAGER) end
        },
        {
            spell = self.spells.DRAGON_ROAR,
            condition = function(self) return IsSpellKnown(self.spells.DRAGON_ROAR) end
        }
    }
    
    -- Add Protection-specific defensive abilities
    table.insert(self.defensiveRotation, 1, { -- High priority
        spell = self.spells.SHIELD_BLOCK,
        condition = function(self)
            return not self:HasBuff(132404) and
                   self:SpellHasCharges(self.spells.SHIELD_BLOCK) and
                   self:GetResource() >= 30
        end
    })
    
    table.insert(self.defensiveRotation, { 
        spell = self.spells.SHIELD_WALL, 
        threshold = 25 
    })
    
    table.insert(self.defensiveRotation, { 
        spell = self.spells.LAST_STAND, 
        threshold = 30 
    })
    
    table.insert(self.defensiveRotation, { 
        spell = self.spells.DEMORALIZING_SHOUT, 
        threshold = 60 
    })
end

-- Class-specific pre-rotation checks
function Warrior:ClassSpecificChecks()
    -- Check for class-specific conditions
    
    -- Maintain Battle Shout
    if not self:HasBuff(self.spells.BATTLE_SHOUT) and 
       not self:SpellOnCooldown(self.spells.BATTLE_SHOUT) then
        WR.Queue:Add(self.spells.BATTLE_SHOUT)
        return false
    end
    
    return true
end

-- Get default action when nothing else is available
function Warrior:GetDefaultAction()
    if self.currentSpec == SPEC_ARMS then
        return self.spells.SLAM
    elseif self.currentSpec == SPEC_FURY then
        return self.spells.WHIRLWIND
    elseif self.currentSpec == SPEC_PROTECTION then
        return self.spells.DEVASTATE
    end
    
    return nil
end

-- Initialize the module
Warrior:Initialize()

return Warrior