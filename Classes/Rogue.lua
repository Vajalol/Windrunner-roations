local addonName, WR = ...

-- Rogue Class module
local Rogue = {}
WR.Classes = WR.Classes or {}
WR.Classes.ROGUE = Rogue

-- Inherit from BaseClass
setmetatable(Rogue, {__index = WR.BaseClass})

-- Resource type for Rogues (Energy and Combo Points)
Rogue.resourceType = Enum.PowerType.Energy
Rogue.secondaryResourceType = Enum.PowerType.ComboPoints

-- Define spec IDs
local SPEC_ASSASSINATION = 259
local SPEC_OUTLAW = 260
local SPEC_SUBTLETY = 261

-- Class initialization
function Rogue:Initialize()
    -- Inherit base initialization
    WR.BaseClass.Initialize(self)
    
    -- Register Specializations
    self:RegisterSpec(SPEC_ASSASSINATION, "Assassination")
    self:RegisterSpec(SPEC_OUTLAW, "Outlaw")
    self:RegisterSpec(SPEC_SUBTLETY, "Subtlety")
    
    -- Shared spell IDs across all rogue specs
    self.spells = {
        -- Core rogue abilities
        STEALTH = 1784,
        SINISTER_STRIKE = 193315,
        EVISCERATE = 196819,
        SLICE_AND_DICE = 315496,
        CRIMSON_VIAL = 185311,
        KICK = 1766,
        FEINT = 1966,
        CLOAK_OF_SHADOWS = 31224,
        VANISH = 1856,
        EVASION = 5277,
        BLIND = 2094,
        CHEAP_SHOT = 1833,
        SAP = 6770,
        KIDNEY_SHOT = 408,
        DISTRACT = 1725,
        PICK_POCKET = 921,
        PICK_LOCK = 1804,
        TRICKS_OF_THE_TRADE = 57934,
        SPRINT = 2983,
        SHADOWSTEP = 36554,
        SHIV = 5938,
        GOUGE = 1776,
        SHROUD_OF_CONCEALMENT = 114018,
        MARKED_FOR_DEATH = 137619,
        GRAPPLING_HOOK = 195457,
        FLEET_FOOTED = 31209,
        DEADLY_POISON = 2823,
        WOUND_POISON = 8679,
        CRIPPLING_POISON = 3408,
        NUMBING_POISON = 5761,
        FEINT = 1966,
        
        -- Covenant abilities
        FLAGELLATION = 323654,        -- Venthyr
        SERRATED_BONE_SPIKE = 328547, -- Necrolord
        SEPSIS = 328305,              -- Night Fae
        ECHOING_REPRIMAND = 323547    -- Kyrian
    }
    
    -- Load shared rogue data
    self:LoadSharedRogueData()
    
    WR:Debug("Rogue module initialized")
end

-- Load shared spell and mechanics data for all rogue specs
function Rogue:LoadSharedRogueData()
    -- Register important buffs
    WR.Auras:RegisterImportantAura(self.spells.STEALTH, 95, true, false)
    WR.Auras:RegisterImportantAura(self.spells.SLICE_AND_DICE, 90, true, false)
    WR.Auras:RegisterImportantAura(self.spells.FLEET_FOOTED, 70, true, false)
    WR.Auras:RegisterImportantAura(self.spells.DEADLY_POISON, 80, false, true)
    WR.Auras:RegisterImportantAura(self.spells.SHROUD_OF_CONCEALMENT, 95, true, false)
    
    -- Setup cooldown tracking
    WR.Cooldown:StartTracking(self.spells.CRIMSON_VIAL)
    WR.Cooldown:StartTracking(self.spells.KICK)
    WR.Cooldown:StartTracking(self.spells.FEINT)
    WR.Cooldown:StartTracking(self.spells.CLOAK_OF_SHADOWS)
    WR.Cooldown:StartTracking(self.spells.VANISH)
    WR.Cooldown:StartTracking(self.spells.EVASION)
    WR.Cooldown:StartTracking(self.spells.BLIND)
    WR.Cooldown:StartTracking(self.spells.SAP)
    WR.Cooldown:StartTracking(self.spells.DISTRACT)
    WR.Cooldown:StartTracking(self.spells.TRICKS_OF_THE_TRADE)
    WR.Cooldown:StartTracking(self.spells.SPRINT)
    WR.Cooldown:StartTracking(self.spells.SHADOWSTEP)
    WR.Cooldown:StartTracking(self.spells.SHIV)
    WR.Cooldown:StartTracking(self.spells.GOUGE)
    WR.Cooldown:StartTracking(self.spells.SHROUD_OF_CONCEALMENT)
    WR.Cooldown:StartTracking(self.spells.MARKED_FOR_DEATH)
    WR.Cooldown:StartTracking(self.spells.GRAPPLING_HOOK)
    
    -- Set up the interrupt spell
    self.interruptRotation = {
        { spell = self.spells.KICK }
    }
    
    -- Set up defensive rotation (shared by all specs)
    self.defensiveRotation = {
        { spell = self.spells.CLOAK_OF_SHADOWS, threshold = 30 },
        { spell = self.spells.EVASION, threshold = 50 },
        { spell = self.spells.FEINT, threshold = 70 },
        { spell = self.spells.VANISH, threshold = 15 },
        { spell = self.spells.CRIMSON_VIAL, threshold = 60 }
    }
end

-- Load a specific specialization
function Rogue:LoadSpec(specId)
    -- Call the base class method to set up common components
    WR.BaseClass.LoadSpec(self, specId)
    
    -- Set the resource type based on spec (same for all rogue specs)
    self.resourceType = Enum.PowerType.Energy
    self.secondaryResourceType = Enum.PowerType.ComboPoints
    
    -- Load specific spec data
    if specId == SPEC_ASSASSINATION then
        self:LoadAssassinationSpec()
    elseif specId == SPEC_OUTLAW then
        self:LoadOutlawSpec()
    elseif specId == SPEC_SUBTLETY then
        self:LoadSubtletySpec()
    end
    
    WR:Debug("Loaded rogue spec:", self.specData.name)
    return true
end

-- Load Assassination specialization
function Rogue:LoadAssassinationSpec()
    -- Assassination-specific spells
    self.spells.GARROTE = 703
    self.spells.RUPTURE = 1943
    self.spells.MUTILATE = 1329
    self.spells.ENVENOM = 32645
    self.spells.FAN_OF_KNIVES = 51723
    self.spells.VENDETTA = 79140
    self.spells.EXSANGUINATE = 200806
    self.spells.TOXIC_BLADE = 245388
    self.spells.BLINDSIDE = 328085
    self.spells.CRIMSON_TEMPEST = 121411
    self.spells.INTERNAL_BLEEDING = 154904
    self.spells.MASTER_ASSASSIN = 255989
    self.spells.POISON_BOMB = 255544
    self.spells.VENOMOUS_WOUNDS = 79134
    self.spells.ELABORATE_PLANNING = 193640
    self.spells.MASTER_POISONER = 196864
    self.spells.IMPROVED_POISONS = 14117
    self.spells.DEADLY_POISON = 2823
    self.spells.CUT_TO_THE_CHASE = 51667
    self.spells.SHIV = 5938
    self.spells.GARROTE_SILENCE = 1330
    self.spells.IMPROVED_GARROTE = 381632
    self.spells.DEADLY_BREW = 381637
    self.spells.AMBUSH = 8676
    
    -- Setup cooldown and aura tracking for Assassination
    WR.Cooldown:StartTracking(self.spells.GARROTE)
    WR.Cooldown:StartTracking(self.spells.VENDETTA)
    WR.Cooldown:StartTracking(self.spells.EXSANGUINATE)
    WR.Cooldown:StartTracking(self.spells.TOXIC_BLADE)
    WR.Cooldown:StartTracking(self.spells.BLINDSIDE)
    WR.Cooldown:StartTracking(self.spells.AMBUSH)
    
    -- Track important buffs/debuffs
    WR.Auras:RegisterImportantAura(self.spells.GARROTE, 90, false, true)
    WR.Auras:RegisterImportantAura(self.spells.RUPTURE, 95, false, true)
    WR.Auras:RegisterImportantAura(self.spells.DEADLY_POISON, 85, false, true)
    WR.Auras:RegisterImportantAura(self.spells.VENDETTA, 90, true, false)
    WR.Auras:RegisterImportantAura(self.spells.ELABORATE_PLANNING, 80, true, false)
    WR.Auras:RegisterImportantAura(self.spells.MASTER_ASSASSIN, 85, true, false)
    WR.Auras:RegisterImportantAura(self.spells.BLINDSIDE, 80, true, false)
    WR.Auras:RegisterImportantAura(self.spells.CRIMSON_TEMPEST, 80, false, true)
    
    -- Define Assassination single target rotation
    self.singleTargetRotation = {
        -- Maintain Slice and Dice
        {
            spell = self.spells.SLICE_AND_DICE,
            condition = function(self)
                return not self:HasBuff(self.spells.SLICE_AND_DICE) or
                       self:GetBuffRemaining(self.spells.SLICE_AND_DICE) < 5 and
                       self:GetComboPoints() >= 1
            end
        },
        
        -- Apply and maintain poisons
        {
            spell = self.spells.DEADLY_POISON,
            condition = function(self)
                return not self:HasWeaponPoison("mainhand")
            end
        },
        
        -- Maintain Garrote
        {
            spell = self.spells.GARROTE,
            condition = function(self)
                return not self:HasDebuff(self.spells.GARROTE) or
                       self:GetDebuffRemaining(self.spells.GARROTE) < 5.4
            end
        },
        
        -- Maintain Rupture
        {
            spell = self.spells.RUPTURE,
            condition = function(self)
                return (not self:HasDebuff(self.spells.RUPTURE) or
                        self:GetDebuffRemaining(self.spells.RUPTURE) < 7.2) and
                       self:GetComboPoints() >= 4
            end
        },
        
        -- Use vendetta on cooldown
        {
            spell = self.spells.VENDETTA,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.VENDETTA)
            end
        },
        
        -- Use covenant abilities
        { 
            spell = self.spells.FLAGELLATION,
            condition = function(self) 
                return IsSpellKnown(self.spells.FLAGELLATION) and
                       self:GetComboPoints() >= 5
            end
        },
        { 
            spell = self.spells.SERRATED_BONE_SPIKE,
            condition = function(self) return IsSpellKnown(self.spells.SERRATED_BONE_SPIKE) end
        },
        { 
            spell = self.spells.SEPSIS,
            condition = function(self) return IsSpellKnown(self.spells.SEPSIS) end
        },
        { 
            spell = self.spells.ECHOING_REPRIMAND,
            condition = function(self) return IsSpellKnown(self.spells.ECHOING_REPRIMAND) end
        },
        
        -- Use Toxic Blade if talented
        {
            spell = self.spells.TOXIC_BLADE,
            condition = function(self)
                return IsSpellKnown(self.spells.TOXIC_BLADE) and
                       not self:SpellOnCooldown(self.spells.TOXIC_BLADE)
            end
        },
        
        -- Use Exsanguinate if talented, when DoTs are up
        {
            spell = self.spells.EXSANGUINATE,
            condition = function(self)
                return IsSpellKnown(self.spells.EXSANGUINATE) and
                       not self:SpellOnCooldown(self.spells.EXSANGUINATE) and
                       self:HasDebuff(self.spells.GARROTE) and
                       self:HasDebuff(self.spells.RUPTURE) and
                       self:GetDebuffRemaining(self.spells.RUPTURE) > 20
            end
        },
        
        -- Use Ambush with Blindside proc
        {
            spell = self.spells.AMBUSH,
            condition = function(self)
                return self:HasBuff(self.spells.BLINDSIDE)
            end
        },
        
        -- Use Envenom at 4+ combo points
        {
            spell = self.spells.ENVENOM,
            condition = function(self)
                return self:GetComboPoints() >= 4 and
                       self:HasBuff(self.spells.SLICE_AND_DICE) and
                       self:GetBuffRemaining(self.spells.SLICE_AND_DICE) > 10 and
                       self:HasDebuff(self.spells.RUPTURE) and
                       self:GetDebuffRemaining(self.spells.RUPTURE) > 10
            end
        },
        
        -- Use Mutilate to build combo points
        { spell = self.spells.MUTILATE }
    }
    
    -- AoE rotation for Assassination
    self.aoeRotation = {
        -- Maintain Slice and Dice
        {
            spell = self.spells.SLICE_AND_DICE,
            condition = function(self)
                return not self:HasBuff(self.spells.SLICE_AND_DICE) or
                       self:GetBuffRemaining(self.spells.SLICE_AND_DICE) < 5 and
                       self:GetComboPoints() >= 1
            end
        },
        
        -- Apply Garrote on primary target
        {
            spell = self.spells.GARROTE,
            condition = function(self)
                return not self:HasDebuff(self.spells.GARROTE) or
                       self:GetDebuffRemaining(self.spells.GARROTE) < 5.4
            end
        },
        
        -- Use covenant abilities
        { 
            spell = self.spells.FLAGELLATION,
            condition = function(self) 
                return IsSpellKnown(self.spells.FLAGELLATION) and
                       self:GetComboPoints() >= 5
            end
        },
        { 
            spell = self.spells.SERRATED_BONE_SPIKE,
            condition = function(self) return IsSpellKnown(self.spells.SERRATED_BONE_SPIKE) end
        },
        
        -- Use Crimson Tempest for AoE
        {
            spell = self.spells.CRIMSON_TEMPEST,
            condition = function(self)
                return self:GetEnemyCount(10) >= 3 and
                       self:GetComboPoints() >= 4 and
                       (not self:HasDebuff(self.spells.CRIMSON_TEMPEST) or
                        self:GetDebuffRemaining(self.spells.CRIMSON_TEMPEST) < 3)
            end
        },
        
        -- AoE with Fan of Knives
        {
            spell = self.spells.FAN_OF_KNIVES,
            condition = function(self)
                return self:GetEnemyCount(10) >= 3 or
                       (self:GetEnemyCount(10) >= 2 and not self:HasBuff(self.spells.DEADLY_POISON))
            end
        },
        
        -- Envenom at high combo points
        {
            spell = self.spells.ENVENOM,
            condition = function(self)
                return self:GetComboPoints() >= 4
            end
        },
        
        -- Mutilate to build combo points
        { spell = self.spells.MUTILATE }
    }
    
    -- Define burst rotation
    self.burstRotation = {
        { spell = self.spells.VENDETTA },
        { 
            spell = self.spells.SEPSIS,
            condition = function(self) return IsSpellKnown(self.spells.SEPSIS) end
        },
        { 
            spell = self.spells.FLAGELLATION,
            condition = function(self) return IsSpellKnown(self.spells.FLAGELLATION) end
        },
        {
            spell = self.spells.TOXIC_BLADE,
            condition = function(self) return IsSpellKnown(self.spells.TOXIC_BLADE) end
        },
        {
            spell = self.spells.EXSANGUINATE,
            condition = function(self) return IsSpellKnown(self.spells.EXSANGUINATE) end
        },
        { spell = self.spells.ENVENOM }
    }
end

-- Load Outlaw specialization
function Rogue:LoadOutlawSpec()
    -- Outlaw-specific spells
    self.spells.PISTOL_SHOT = 185763
    self.spells.BETWEEN_THE_EYES = 315341
    self.spells.BLADE_FLURRY = 13877
    self.spells.ROLL_THE_BONES = 315508
    self.spells.ADRENALINE_RUSH = 13750
    self.spells.BLADE_RUSH = 271877
    self.spells.KILLING_SPREE = 51690
    self.spells.DREADBLADES = 343142
    self.spells.GHOSTLY_STRIKE = 196937
    self.spells.DISPATCH = 2098
    self.spells.GRAND_MELEE = 193358
    self.spells.SKULL_AND_CROSSBONES = 199603
    self.spells.RUTHLESS_PRECISION = 193357
    self.spells.TRUE_BEARING = 193359
    self.spells.BURIED_TREASURE = 199600
    self.spells.BROADSIDE = 193356
    self.spells.ALACRITY = 193539
    self.spells.OPPORTUNITY = 195627
    self.spells.RESTLESS_BLADES = 79096
    self.spells.COMBAT_POTENCY = 61329
    self.spells.LOADED_DICE = 256170
    self.spells.ACE_UP_YOUR_SLEEVE = 278676
    self.spells.KEEP_IT_ROLLING = 381989
    self.spells.AMBUSH = 8676
    
    -- Setup cooldown and aura tracking for Outlaw
    WR.Cooldown:StartTracking(self.spells.PISTOL_SHOT)
    WR.Cooldown:StartTracking(self.spells.BETWEEN_THE_EYES)
    WR.Cooldown:StartTracking(self.spells.BLADE_FLURRY)
    WR.Cooldown:StartTracking(self.spells.ROLL_THE_BONES)
    WR.Cooldown:StartTracking(self.spells.ADRENALINE_RUSH)
    WR.Cooldown:StartTracking(self.spells.BLADE_RUSH)
    WR.Cooldown:StartTracking(self.spells.KILLING_SPREE)
    WR.Cooldown:StartTracking(self.spells.DREADBLADES)
    WR.Cooldown:StartTracking(self.spells.GHOSTLY_STRIKE)
    WR.Cooldown:StartTracking(self.spells.KEEP_IT_ROLLING)
    WR.Cooldown:StartTracking(self.spells.AMBUSH)
    
    -- Track important buffs/debuffs
    WR.Auras:RegisterImportantAura(self.spells.BLADE_FLURRY, 90, true, false)
    WR.Auras:RegisterImportantAura(self.spells.ADRENALINE_RUSH, 90, true, false)
    WR.Auras:RegisterImportantAura(self.spells.OPPORTUNITY, 85, true, false)
    WR.Auras:RegisterImportantAura(self.spells.GRAND_MELEE, 85, true, false)
    WR.Auras:RegisterImportantAura(self.spells.SKULL_AND_CROSSBONES, 85, true, false)
    WR.Auras:RegisterImportantAura(self.spells.RUTHLESS_PRECISION, 85, true, false)
    WR.Auras:RegisterImportantAura(self.spells.TRUE_BEARING, 85, true, false)
    WR.Auras:RegisterImportantAura(self.spells.BURIED_TREASURE, 85, true, false)
    WR.Auras:RegisterImportantAura(self.spells.BROADSIDE, 85, true, false)
    WR.Auras:RegisterImportantAura(self.spells.LOADED_DICE, 80, true, false)
    WR.Auras:RegisterImportantAura(self.spells.DREADBLADES, 90, true, false)
    WR.Auras:RegisterImportantAura(self.spells.ALACRITY, 80, true, false)
    
    -- Define Outlaw single target rotation
    self.singleTargetRotation = {
        -- Maintain Slice and Dice if Roll the Bones not available
        {
            spell = self.spells.SLICE_AND_DICE,
            condition = function(self)
                return not IsSpellKnown(self.spells.ROLL_THE_BONES) and
                       (not self:HasBuff(self.spells.SLICE_AND_DICE) or
                        self:GetBuffRemaining(self.spells.SLICE_AND_DICE) < 5) and
                       self:GetComboPoints() >= 1
            end
        },
        
        -- Maintain Roll the Bones
        {
            spell = self.spells.ROLL_THE_BONES,
            condition = function(self)
                return IsSpellKnown(self.spells.ROLL_THE_BONES) and
                       (not self:HasRollTheBonesBuffs() or
                        (self:GetRollTheBonesCounts() < 2 and 
                         not self:HasBuff(self.spells.TRUE_BEARING) and
                         not self:HasBuff(self.spells.BURIED_TREASURE)) or
                        self:GetRollTheBonesRemaining() < 5) and
                       self:GetComboPoints() >= 1
            end
        },
        
        -- Keep It Rolling to extend RtB buffs
        {
            spell = self.spells.KEEP_IT_ROLLING,
            condition = function(self)
                return IsSpellKnown(self.spells.KEEP_IT_ROLLING) and
                       not self:SpellOnCooldown(self.spells.KEEP_IT_ROLLING) and
                       self:GetRollTheBonesCounts() >= 2
            end
        },
        
        -- Use Adrenaline Rush on cooldown
        {
            spell = self.spells.ADRENALINE_RUSH,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.ADRENALINE_RUSH)
            end
        },
        
        -- Use covenant abilities
        { 
            spell = self.spells.FLAGELLATION,
            condition = function(self) 
                return IsSpellKnown(self.spells.FLAGELLATION) and
                       self:GetComboPoints() >= 5
            end
        },
        { 
            spell = self.spells.SERRATED_BONE_SPIKE,
            condition = function(self) return IsSpellKnown(self.spells.SERRATED_BONE_SPIKE) end
        },
        { 
            spell = self.spells.SEPSIS,
            condition = function(self) return IsSpellKnown(self.spells.SEPSIS) end
        },
        { 
            spell = self.spells.ECHOING_REPRIMAND,
            condition = function(self) return IsSpellKnown(self.spells.ECHOING_REPRIMAND) end
        },
        
        -- Between the Eyes - high priority for Crit buff
        {
            spell = self.spells.BETWEEN_THE_EYES,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.BETWEEN_THE_EYES) and
                       self:GetComboPoints() >= 4
            end
        },
        
        -- Use Ghostly Strike if talented
        {
            spell = self.spells.GHOSTLY_STRIKE,
            condition = function(self)
                return IsSpellKnown(self.spells.GHOSTLY_STRIKE) and
                       not self:SpellOnCooldown(self.spells.GHOSTLY_STRIKE)
            end
        },
        
        -- Use Blade Rush if talented
        {
            spell = self.spells.BLADE_RUSH,
            condition = function(self)
                return IsSpellKnown(self.spells.BLADE_RUSH) and
                       not self:SpellOnCooldown(self.spells.BLADE_RUSH)
            end
        },
        
        -- Use Killing Spree if talented
        {
            spell = self.spells.KILLING_SPREE,
            condition = function(self)
                return IsSpellKnown(self.spells.KILLING_SPREE) and
                       not self:SpellOnCooldown(self.spells.KILLING_SPREE) and
                       self:GetEnergyDeficit() > 60
            end
        },
        
        -- Use Dreadblades if talented
        {
            spell = self.spells.DREADBLADES,
            condition = function(self)
                return IsSpellKnown(self.spells.DREADBLADES) and
                       not self:SpellOnCooldown(self.spells.DREADBLADES) and
                       self:GetComboPoints() <= 2
            end
        },
        
        -- Use Pistol Shot with Opportunity proc
        {
            spell = self.spells.PISTOL_SHOT,
            condition = function(self)
                return self:HasBuff(self.spells.OPPORTUNITY) and
                       self:GetComboPoints() < 5
            end
        },
        
        -- Use Dispatch as finisher
        {
            spell = self.spells.DISPATCH,
            condition = function(self)
                return self:GetComboPoints() >= 5
            end
        },
        
        -- Use Sinister Strike as main combo builder
        { spell = self.spells.SINISTER_STRIKE }
    }
    
    -- AoE rotation for Outlaw
    self.aoeRotation = {
        -- Maintain Blade Flurry for AoE
        {
            spell = self.spells.BLADE_FLURRY,
            condition = function(self)
                return self:GetEnemyCount(10) >= 2 and
                       not self:HasBuff(self.spells.BLADE_FLURRY)
            end
        },
        
        -- Maintain Roll the Bones
        {
            spell = self.spells.ROLL_THE_BONES,
            condition = function(self)
                return IsSpellKnown(self.spells.ROLL_THE_BONES) and
                       (not self:HasRollTheBonesBuffs() or
                        (self:GetRollTheBonesCounts() < 2 and 
                         not self:HasBuff(self.spells.TRUE_BEARING) and
                         not self:HasBuff(self.spells.BURIED_TREASURE)) or
                        self:GetRollTheBonesRemaining() < 5) and
                       self:GetComboPoints() >= 1
            end
        },
        
        -- Use Keep It Rolling
        {
            spell = self.spells.KEEP_IT_ROLLING,
            condition = function(self)
                return IsSpellKnown(self.spells.KEEP_IT_ROLLING) and
                       not self:SpellOnCooldown(self.spells.KEEP_IT_ROLLING) and
                       self:GetRollTheBonesCounts() >= 2
            end
        },
        
        -- Use Adrenaline Rush
        {
            spell = self.spells.ADRENALINE_RUSH,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.ADRENALINE_RUSH) and
                       self:GetEnemyCount(10) >= 2
            end
        },
        
        -- Use covenant abilities
        { 
            spell = self.spells.FLAGELLATION,
            condition = function(self) 
                return IsSpellKnown(self.spells.FLAGELLATION) and
                       self:GetComboPoints() >= 5
            end
        },
        { 
            spell = self.spells.SERRATED_BONE_SPIKE,
            condition = function(self) return IsSpellKnown(self.spells.SERRATED_BONE_SPIKE) end
        },
        
        -- Use Blade Rush for AoE
        {
            spell = self.spells.BLADE_RUSH,
            condition = function(self)
                return IsSpellKnown(self.spells.BLADE_RUSH) and
                       not self:SpellOnCooldown(self.spells.BLADE_RUSH) and
                       self:GetEnemyCount(10) >= 2
            end
        },
        
        -- Use Between the Eyes
        {
            spell = self.spells.BETWEEN_THE_EYES,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.BETWEEN_THE_EYES) and
                       self:GetComboPoints() >= 4
            end
        },
        
        -- Use Dispatch as finisher
        {
            spell = self.spells.DISPATCH,
            condition = function(self)
                return self:GetComboPoints() >= 5
            end
        },
        
        -- Use Pistol Shot with Opportunity proc
        {
            spell = self.spells.PISTOL_SHOT,
            condition = function(self)
                return self:HasBuff(self.spells.OPPORTUNITY) and
                       self:GetComboPoints() < 5
            end
        },
        
        -- Use Sinister Strike as main combo builder
        { spell = self.spells.SINISTER_STRIKE }
    }
    
    -- Define burst rotation
    self.burstRotation = {
        { spell = self.spells.ADRENALINE_RUSH },
        {
            spell = self.spells.LOADED_DICE,
            condition = function(self) return self:HasTalent(self.spells.LOADED_DICE) end
        },
        { spell = self.spells.ROLL_THE_BONES },
        { 
            spell = self.spells.FLAGELLATION,
            condition = function(self) return IsSpellKnown(self.spells.FLAGELLATION) end
        },
        {
            spell = self.spells.BLADE_RUSH,
            condition = function(self) return IsSpellKnown(self.spells.BLADE_RUSH) end
        },
        {
            spell = self.spells.KILLING_SPREE,
            condition = function(self) return IsSpellKnown(self.spells.KILLING_SPREE) end
        },
        {
            spell = self.spells.DREADBLADES,
            condition = function(self) return IsSpellKnown(self.spells.DREADBLADES) end
        },
        { spell = self.spells.BETWEEN_THE_EYES }
    }
end

-- Load Subtlety specialization
function Rogue:LoadSubtletySpec()
    -- Subtlety-specific spells
    self.spells.BACKSTAB = 53
    self.spells.SHADOWSTRIKE = 185438
    self.spells.SYMBOLS_OF_DEATH = 212283
    self.spells.SHADOW_DANCE = 185313
    self.spells.SHADOW_BLADES = 121471
    self.spells.BLACK_POWDER = 319175
    self.spells.RUPTURE = 1943
    self.spells.SHURIKEN_STORM = 197835
    self.spells.SHURIKEN_TORNADO = 277925
    self.spells.SECRET_TECHNIQUE = 280719
    self.spells.SHADOW_FOCUS = 108209
    self.spells.SUBTERFUGE = 108208
    self.spells.GLOOMBLADE = 200758
    self.spells.MASTER_OF_SHADOWS = 196976
    self.spells.FIND_WEAKNESS = 91023
    self.spells.NIGHTBLADE = 195452
    self.spells.DARK_SHADOW = 245687
    self.spells.NIGHTSTALKER = 14062
    self.spells.PREMEDITATION = 343160
    self.spells.DEEPER_DAGGERS = 198675
    self.spells.THE_ROTTEN = 382015
    self.spells.IMPROVED_SHADOW_DANCE = 393972
    self.spells.EVISCERATE = 196819
    self.spells.AMBUSH = 8676
    
    -- Setup cooldown and aura tracking for Subtlety
    WR.Cooldown:StartTracking(self.spells.SYMBOLS_OF_DEATH)
    WR.Cooldown:StartTracking(self.spells.SHADOW_DANCE)
    WR.Cooldown:StartTracking(self.spells.SHADOW_BLADES)
    WR.Cooldown:StartTracking(self.spells.SHURIKEN_TORNADO)
    WR.Cooldown:StartTracking(self.spells.SECRET_TECHNIQUE)
    WR.Cooldown:StartTracking(self.spells.AMBUSH)
    
    -- Track important buffs/debuffs
    WR.Auras:RegisterImportantAura(self.spells.SYMBOLS_OF_DEATH, 90, true, false)
    WR.Auras:RegisterImportantAura(self.spells.SHADOW_DANCE, 95, true, false)
    WR.Auras:RegisterImportantAura(self.spells.SHADOW_BLADES, 90, true, false)
    WR.Auras:RegisterImportantAura(self.spells.RUPTURE, 95, false, true)
    WR.Auras:RegisterImportantAura(self.spells.FIND_WEAKNESS, 85, false, true)
    WR.Auras:RegisterImportantAura(self.spells.MASTER_OF_SHADOWS, 80, true, false)
    WR.Auras:RegisterImportantAura(self.spells.SUBTERFUGE, 85, true, false)
    WR.Auras:RegisterImportantAura(self.spells.NIGHTSTALKER, 80, true, false)
    WR.Auras:RegisterImportantAura(self.spells.PREMEDITATION, 85, true, false)
    WR.Auras:RegisterImportantAura(self.spells.DEEPER_DAGGERS, 85, true, false)
    WR.Auras:RegisterImportantAura(self.spells.THE_ROTTEN, 85, true, false)
    
    -- Define Subtlety single target rotation
    self.singleTargetRotation = {
        -- Maintain Slice and Dice
        {
            spell = self.spells.SLICE_AND_DICE,
            condition = function(self)
                return (not self:HasBuff(self.spells.SLICE_AND_DICE) or
                        self:GetBuffRemaining(self.spells.SLICE_AND_DICE) < 5) and
                       self:GetComboPoints() >= 1
            end
        },
        
        -- Use Symbols of Death on cooldown
        {
            spell = self.spells.SYMBOLS_OF_DEATH,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.SYMBOLS_OF_DEATH)
            end
        },
        
        -- Use Shadow Blades on cooldown
        {
            spell = self.spells.SHADOW_BLADES,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.SHADOW_BLADES)
            end
        },
        
        -- Use covenant abilities
        { 
            spell = self.spells.FLAGELLATION,
            condition = function(self) 
                return IsSpellKnown(self.spells.FLAGELLATION) and
                       self:GetComboPoints() >= 5
            end
        },
        { 
            spell = self.spells.SERRATED_BONE_SPIKE,
            condition = function(self) return IsSpellKnown(self.spells.SERRATED_BONE_SPIKE) end
        },
        { 
            spell = self.spells.SEPSIS,
            condition = function(self) return IsSpellKnown(self.spells.SEPSIS) end
        },
        { 
            spell = self.spells.ECHOING_REPRIMAND,
            condition = function(self) return IsSpellKnown(self.spells.ECHOING_REPRIMAND) end
        },
        
        -- Maintain Rupture
        {
            spell = self.spells.RUPTURE,
            condition = function(self)
                return (not self:HasDebuff(self.spells.RUPTURE) or
                        self:GetDebuffRemaining(self.spells.RUPTURE) < 7.2) and
                       self:GetComboPoints() >= 4
            end
        },
        
        -- Use Shadow Dance for burst damage
        {
            spell = self.spells.SHADOW_DANCE,
            condition = function(self)
                return not self:HasBuff(self.spells.SHADOW_DANCE) and
                       not self:SpellOnCooldown(self.spells.SHADOW_DANCE) and
                       self:GetComboPoints() <= 3
            end
        },
        
        -- Use Secret Technique if talented
        {
            spell = self.spells.SECRET_TECHNIQUE,
            condition = function(self)
                return IsSpellKnown(self.spells.SECRET_TECHNIQUE) and
                       not self:SpellOnCooldown(self.spells.SECRET_TECHNIQUE) and
                       self:GetComboPoints() >= 4
            end
        },
        
        -- Use Shuriken Tornado if talented
        {
            spell = self.spells.SHURIKEN_TORNADO,
            condition = function(self)
                return IsSpellKnown(self.spells.SHURIKEN_TORNADO) and
                       not self:SpellOnCooldown(self.spells.SHURIKEN_TORNADO)
            end
        },
        
        -- Use Shadowstrike during Shadow Dance
        {
            spell = self.spells.SHADOWSTRIKE,
            condition = function(self)
                return (self:HasBuff(self.spells.SHADOW_DANCE) or 
                        self:HasBuff(self.spells.SUBTERFUGE) or 
                        self:IsStealth()) and
                       self:GetComboPoints() < 5
            end
        },
        
        -- Use Eviscerate as finisher
        {
            spell = self.spells.EVISCERATE,
            condition = function(self)
                return self:GetComboPoints() >= 5 and
                       self:HasBuff(self.spells.SLICE_AND_DICE) and
                       self:GetBuffRemaining(self.spells.SLICE_AND_DICE) > 10 and
                       self:HasDebuff(self.spells.RUPTURE) and
                       self:GetDebuffRemaining(self.spells.RUPTURE) > 10
            end
        },
        
        -- Use Gloomblade if talented
        {
            spell = self.spells.GLOOMBLADE,
            condition = function(self)
                return IsSpellKnown(self.spells.GLOOMBLADE) and
                       self:GetComboPoints() < 5
            end
        },
        
        -- Use Backstab as main combo builder
        {
            spell = self.spells.BACKSTAB,
            condition = function(self)
                return not IsSpellKnown(self.spells.GLOOMBLADE) and
                       self:GetComboPoints() < 5
            end
        }
    }
    
    -- AoE rotation for Subtlety
    self.aoeRotation = {
        -- Maintain Slice and Dice
        {
            spell = self.spells.SLICE_AND_DICE,
            condition = function(self)
                return (not self:HasBuff(self.spells.SLICE_AND_DICE) or
                        self:GetBuffRemaining(self.spells.SLICE_AND_DICE) < 5) and
                       self:GetComboPoints() >= 1
            end
        },
        
        -- Use Symbols of Death on cooldown
        {
            spell = self.spells.SYMBOLS_OF_DEATH,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.SYMBOLS_OF_DEATH)
            end
        },
        
        -- Use Shadow Blades on cooldown
        {
            spell = self.spells.SHADOW_BLADES,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.SHADOW_BLADES)
            end
        },
        
        -- Use covenant abilities
        { 
            spell = self.spells.FLAGELLATION,
            condition = function(self) 
                return IsSpellKnown(self.spells.FLAGELLATION) and
                       self:GetComboPoints() >= 5
            end
        },
        { 
            spell = self.spells.SERRATED_BONE_SPIKE,
            condition = function(self) return IsSpellKnown(self.spells.SERRATED_BONE_SPIKE) end
        },
        
        -- Use Shuriken Tornado for AoE if talented
        {
            spell = self.spells.SHURIKEN_TORNADO,
            condition = function(self)
                return IsSpellKnown(self.spells.SHURIKEN_TORNADO) and
                       not self:SpellOnCooldown(self.spells.SHURIKEN_TORNADO) and
                       self:GetEnemyCount(10) >= 3
            end
        },
        
        -- Use Shadow Dance for burst damage
        {
            spell = self.spells.SHADOW_DANCE,
            condition = function(self)
                return not self:HasBuff(self.spells.SHADOW_DANCE) and
                       not self:SpellOnCooldown(self.spells.SHADOW_DANCE) and
                       self:GetComboPoints() <= 3
            end
        },
        
        -- Use Shuriken Storm for AoE combo generation
        {
            spell = self.spells.SHURIKEN_STORM,
            condition = function(self)
                return self:GetEnemyCount(10) >= 2 and
                       self:GetComboPoints() < 5
            end
        },
        
        -- Use Shadowstrike during Shadow Dance
        {
            spell = self.spells.SHADOWSTRIKE,
            condition = function(self)
                return (self:HasBuff(self.spells.SHADOW_DANCE) or 
                        self:HasBuff(self.spells.SUBTERFUGE) or 
                        self:IsStealth()) and
                       self:GetComboPoints() < 5 and
                       self:GetEnemyCount(10) < 3
            end
        },
        
        -- Use Black Powder for AoE finisher
        {
            spell = self.spells.BLACK_POWDER,
            condition = function(self)
                return self:GetEnemyCount(10) >= 3 and
                       self:GetComboPoints() >= 4
            end
        },
        
        -- Use Secret Technique for AoE if talented
        {
            spell = self.spells.SECRET_TECHNIQUE,
            condition = function(self)
                return IsSpellKnown(self.spells.SECRET_TECHNIQUE) and
                       not self:SpellOnCooldown(self.spells.SECRET_TECHNIQUE) and
                       self:GetComboPoints() >= 4 and
                       self:GetEnemyCount(10) >= 3
            end
        },
        
        -- Use Eviscerate as finisher for priority target
        {
            spell = self.spells.EVISCERATE,
            condition = function(self)
                return self:GetEnemyCount(10) < 3 and
                       self:GetComboPoints() >= 5
            end
        },
        
        -- Use Backstab for single target combo generation
        {
            spell = self.spells.BACKSTAB,
            condition = function(self)
                return not IsSpellKnown(self.spells.GLOOMBLADE) and
                       self:GetComboPoints() < 5 and
                       self:GetEnemyCount(10) < 2
            end
        },
        
        -- Use Gloomblade if talented for single target
        {
            spell = self.spells.GLOOMBLADE,
            condition = function(self)
                return IsSpellKnown(self.spells.GLOOMBLADE) and
                       self:GetComboPoints() < 5 and
                       self:GetEnemyCount(10) < 2
            end
        }
    }
    
    -- Define burst rotation
    self.burstRotation = {
        { spell = self.spells.SYMBOLS_OF_DEATH },
        { spell = self.spells.SHADOW_BLADES },
        { spell = self.spells.SHADOW_DANCE },
        { 
            spell = self.spells.SEPSIS,
            condition = function(self) return IsSpellKnown(self.spells.SEPSIS) end
        },
        { 
            spell = self.spells.FLAGELLATION,
            condition = function(self) return IsSpellKnown(self.spells.FLAGELLATION) end
        },
        {
            spell = self.spells.SHURIKEN_TORNADO,
            condition = function(self) return IsSpellKnown(self.spells.SHURIKEN_TORNADO) end
        },
        {
            spell = self.spells.SECRET_TECHNIQUE,
            condition = function(self) return IsSpellKnown(self.spells.SECRET_TECHNIQUE) end
        }
    }
end

-- Check if the player has Roll the Bones buffs
function Rogue:HasRollTheBonesBuffs()
    -- In a real addon, this would check for any RtB buffs
    -- Here we'll simulate it
    return self:HasBuff(self.spells.GRAND_MELEE) or
           self:HasBuff(self.spells.SKULL_AND_CROSSBONES) or
           self:HasBuff(self.spells.RUTHLESS_PRECISION) or
           self:HasBuff(self.spells.TRUE_BEARING) or
           self:HasBuff(self.spells.BURIED_TREASURE) or
           self:HasBuff(self.spells.BROADSIDE)
end

-- Get number of Roll the Bones buffs
function Rogue:GetRollTheBonesCounts()
    -- In a real addon, this would count the number of RtB buffs
    -- Here we'll return a simulated value
    return math.random(0, 6)
end

-- Get remaining time on Roll the Bones
function Rogue:GetRollTheBonesRemaining()
    -- In a real addon, this would return the time remaining on RtB buffs
    -- Here we'll return a simulated value
    return math.random(0, 30)
end

-- Check if in stealth
function Rogue:IsStealth()
    -- In a real addon, this would check for stealth status
    -- Here we'll check for the buff
    return self:HasBuff(self.spells.STEALTH)
end

-- Get energy deficit
function Rogue:GetEnergyDeficit()
    -- In a real addon, this would calculate energy deficit
    -- Here we'll return a simulated value
    return math.random(0, 100)
end

-- Check if player has a specific talent
function Rogue:HasTalent(spellId)
    -- In a real addon, this would check the talent tree
    -- Here we'll use a simpler check
    return IsSpellKnown(spellId)
end

-- Check weapon poison
function Rogue:HasWeaponPoison(slot)
    -- In a real addon, this would check weapon poisons
    -- For our purposes, we'll return true to avoid endless reapplication
    return true
end

-- Class-specific pre-rotation checks
function Rogue:ClassSpecificChecks()
    -- Apply weapon poison if needed
    if self.currentSpec == SPEC_ASSASSINATION then
        -- Apply Deadly Poison to main hand
        if not self:HasWeaponPoison("mainhand") then
            WR.Queue:Add(self.spells.DEADLY_POISON)
            return false
        end
    end
    
    -- Maintain Slice and Dice outside of combat
    if not UnitAffectingCombat("player") and 
       not self:HasBuff(self.spells.SLICE_AND_DICE) and
       self:GetComboPoints() >= 1 then
        WR.Queue:Add(self.spells.SLICE_AND_DICE)
        return false
    end
    
    return true
end

-- Get default action when nothing else is available
function Rogue:GetDefaultAction()
    if self.currentSpec == SPEC_ASSASSINATION then
        return self.spells.MUTILATE
    elseif self.currentSpec == SPEC_OUTLAW then
        return self.spells.SINISTER_STRIKE
    elseif self.currentSpec == SPEC_SUBTLETY then
        return self.spells.BACKSTAB
    end
    
    return nil
end

-- Initialize the module
Rogue:Initialize()

return Rogue