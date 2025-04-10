local addonName, WR = ...

-- Paladin Class module
local Paladin = {}
WR.Classes = WR.Classes or {}
WR.Classes.PALADIN = Paladin

-- Inherit from BaseClass
setmetatable(Paladin, {__index = WR.BaseClass})

-- Resource type for paladins (mana primary, holy power secondary)
Paladin.resourceType = Enum.PowerType.Mana
Paladin.secondaryResourceType = Enum.PowerType.HolyPower

-- Define spec IDs
local SPEC_HOLY = 65
local SPEC_PROTECTION = 66
local SPEC_RETRIBUTION = 70

-- Class initialization
function Paladin:Initialize()
    -- Inherit base initialization
    WR.BaseClass.Initialize(self)
    
    -- Register Specializations
    self:RegisterSpec(SPEC_HOLY, "Holy")
    self:RegisterSpec(SPEC_PROTECTION, "Protection")
    self:RegisterSpec(SPEC_RETRIBUTION, "Retribution")
    
    -- Shared spell IDs across all paladin specs
    self.spells = {
        -- Common paladin abilities
        DIVINE_SHIELD = 642,
        BLESSING_OF_FREEDOM = 1044,
        BLESSING_OF_PROTECTION = 1022,
        BLESSING_OF_SACRIFICE = 6940,
        HAMMER_OF_JUSTICE = 853,
        REDEMPTION = 7328,
        FLASH_OF_LIGHT = 19750,
        LAY_ON_HANDS = 633,
        CLEANSE = 4987,
        REBUKE = 96231,
        DIVINE_STEED = 190784,
        WORD_OF_GLORY = 85673,
        DEVOTION_AURA = 465,
        RETRIBUTION_AURA = 183435,
        CONCENTRATION_AURA = 317920,
        CRUSADER_AURA = 32223,
        
        -- Covenant abilities
        DIVINE_TOLL = 304971,      -- Kyrian
        VANQUISHERS_HAMMER = 328204, -- Necrolord
        ASHEN_HALLOW = 316958,     -- Venthyr
        BLESSING_OF_SEASONS = 328278, -- Night Fae
    }
    
    -- Load shared paladin data
    self:LoadSharedPaladinData()
    
    WR:Debug("Paladin module initialized")
end

-- Load shared spell and mechanics data for all paladin specs
function Paladin:LoadSharedPaladinData()
    -- Register important buffs
    WR.Auras:RegisterImportantAura(self.spells.DIVINE_SHIELD, 90, true, false)
    WR.Auras:RegisterImportantAura(self.spells.BLESSING_OF_PROTECTION, 80, true, false)
    WR.Auras:RegisterImportantAura(self.spells.BLESSING_OF_FREEDOM, 70, true, false)
    WR.Auras:RegisterImportantAura(self.spells.DIVINE_STEED, 75, true, false)
    
    -- Setup cooldown tracking
    WR.Cooldown:StartTracking(self.spells.DIVINE_SHIELD)
    WR.Cooldown:StartTracking(self.spells.BLESSING_OF_PROTECTION)
    WR.Cooldown:StartTracking(self.spells.BLESSING_OF_FREEDOM)
    WR.Cooldown:StartTracking(self.spells.HAMMER_OF_JUSTICE)
    WR.Cooldown:StartTracking(self.spells.REBUKE)
    WR.Cooldown:StartTracking(self.spells.LAY_ON_HANDS)
    WR.Cooldown:StartTracking(self.spells.DIVINE_STEED)
    
    -- Set up interrupt rotation (shared by all specs)
    self.interruptRotation = {
        { spell = self.spells.REBUKE }
    }
    
    -- Set up defensive rotation (shared by all specs)
    self.defensiveRotation = {
        { spell = self.spells.DIVINE_SHIELD, threshold = 20 },
        { spell = self.spells.LAY_ON_HANDS, threshold = 10 },
        { 
            spell = self.spells.WORD_OF_GLORY, 
            condition = function(self)
                local holyPower = UnitPower("player", Enum.PowerType.HolyPower)
                return self:GetHealthPct() < 50 and holyPower >= 3
            end
        },
    }
end

-- Load a specific specialization
function Paladin:LoadSpec(specId)
    -- Call the base class method to set up common components
    WR.BaseClass.LoadSpec(self, specId)
    
    -- Load specific spec data
    if specId == SPEC_HOLY then
        self:LoadHolySpec()
    elseif specId == SPEC_PROTECTION then
        self:LoadProtectionSpec()
    elseif specId == SPEC_RETRIBUTION then
        self:LoadRetributionSpec()
    end
    
    WR:Debug("Loaded paladin spec:", self.specData.name)
    return true
end

-- Load Holy specialization
function Paladin:LoadHolySpec()
    -- Holy-specific spells
    self.spells.HOLY_SHOCK = 20473
    self.spells.HOLY_LIGHT = 82326
    self.spells.LIGHT_OF_DAWN = 85222
    self.spells.AVENGING_WRATH = 31884
    self.spells.HOLY_PRISM = 114165
    self.spells.LIGHT_OF_THE_MARTYR = 183998
    self.spells.BEACON_OF_LIGHT = 53563
    self.spells.BEACON_OF_FAITH = 156910
    self.spells.BEACON_OF_VIRTUE = 200025
    self.spells.RULE_OF_LAW = 214202
    self.spells.DIVINE_PROTECTION = 498
    self.spells.AURA_MASTERY = 31821
    self.spells.WINGS_OF_LIBERTY = 317929
    self.spells.JUDGMENT = 275773 -- Holy's version of Judgment
    self.spells.HAMMER_OF_WRATH = 24275
    self.spells.CONSECRATION = 26573
    self.spells.CRUSADER_STRIKE = 35395
    self.spells.HOLY_AVENGER = 105809
    self.spells.HOLY_POWER = 9
    
    -- Setup cooldown and aura tracking for Holy
    WR.Cooldown:StartTracking(self.spells.HOLY_SHOCK)
    WR.Cooldown:StartTracking(self.spells.AVENGING_WRATH)
    WR.Cooldown:StartTracking(self.spells.HOLY_PRISM)
    WR.Cooldown:StartTracking(self.spells.RULE_OF_LAW)
    WR.Cooldown:StartTracking(self.spells.DIVINE_PROTECTION)
    WR.Cooldown:StartTracking(self.spells.AURA_MASTERY)
    WR.Cooldown:StartTracking(self.spells.JUDGMENT)
    WR.Cooldown:StartTracking(self.spells.CRUSADER_STRIKE)
    
    -- Track important buffs/debuffs
    WR.Auras:RegisterImportantAura(self.spells.AVENGING_WRATH, 90, true, false)
    WR.Auras:RegisterImportantAura(self.spells.RULE_OF_LAW, 80, true, false)
    WR.Auras:RegisterImportantAura(self.spells.DIVINE_PROTECTION, 85, true, false)
    WR.Auras:RegisterImportantAura(self.spells.HOLY_AVENGER, 85, true, false)
    
    -- Define Holy healer rotation
    -- Note: Since Holy is primarily a healer, actual implementation would focus on healing logic
    -- For combat/damage situations, we'll create a simple DPS rotation for solo content
    
    self.singleTargetRotation = {
        -- Use Avenging Wrath for throughput increase
        { spell = self.spells.AVENGING_WRATH },
        
        -- Use covenant abilities
        { 
            spell = self.spells.DIVINE_TOLL,
            condition = function(self) return IsSpellKnown(self.spells.DIVINE_TOLL) end
        },
        { 
            spell = self.spells.VANQUISHERS_HAMMER,
            condition = function(self) return IsSpellKnown(self.spells.VANQUISHERS_HAMMER) end
        },
        { 
            spell = self.spells.ASHEN_HALLOW,
            condition = function(self) return IsSpellKnown(self.spells.ASHEN_HALLOW) end
        },
        { 
            spell = self.spells.BLESSING_OF_SEASONS,
            condition = function(self) return IsSpellKnown(self.spells.BLESSING_OF_SEASONS) end
        },
        
        -- Use Hammer of Wrath in execute range
        {
            spell = self.spells.HAMMER_OF_WRATH,
            condition = function(self)
                return self:TargetInExecuteRange() or self:HasBuff(self.spells.AVENGING_WRATH)
            end
        },
        
        -- Use Holy Shock as primary damage spell
        { spell = self.spells.HOLY_SHOCK },
        
        -- Use Judgment to generate Holy Power
        { spell = self.spells.JUDGMENT },
        
        -- Use Holy Prism if talented
        {
            spell = self.spells.HOLY_PRISM,
            condition = function(self)
                return IsSpellKnown(self.spells.HOLY_PRISM)
            end
        },
        
        -- Use Crusader Strike to generate Holy Power
        { spell = self.spells.CRUSADER_STRIKE },
        
        -- Use Consecration for AoE damage
        { spell = self.spells.CONSECRATION },
        
        -- Use Holy Light as filler
        { spell = self.spells.HOLY_LIGHT }
    }
    
    -- AoE rotation for Holy
    self.aoeRotation = {
        -- Use Avenging Wrath for throughput increase
        { spell = self.spells.AVENGING_WRATH },
        
        -- Use covenant abilities
        { 
            spell = self.spells.DIVINE_TOLL,
            condition = function(self) return IsSpellKnown(self.spells.DIVINE_TOLL) end
        },
        { 
            spell = self.spells.ASHEN_HALLOW,
            condition = function(self) return IsSpellKnown(self.spells.ASHEN_HALLOW) end
        },
        
        -- Use Consecration for AoE damage
        { spell = self.spells.CONSECRATION },
        
        -- Use Holy Prism if talented
        {
            spell = self.spells.HOLY_PRISM,
            condition = function(self)
                return IsSpellKnown(self.spells.HOLY_PRISM)
            end
        },
        
        -- Use Holy Shock as primary damage spell
        { spell = self.spells.HOLY_SHOCK },
        
        -- Use Judgment to generate Holy Power
        { spell = self.spells.JUDGMENT },
        
        -- Use Crusader Strike to generate Holy Power
        { spell = self.spells.CRUSADER_STRIKE }
    }
    
    -- Define burst rotation
    self.burstRotation = {
        { spell = self.spells.AVENGING_WRATH },
        {
            spell = self.spells.HOLY_AVENGER,
            condition = function(self) return IsSpellKnown(self.spells.HOLY_AVENGER) end
        },
        { 
            spell = self.spells.DIVINE_TOLL,
            condition = function(self) return IsSpellKnown(self.spells.DIVINE_TOLL) end
        },
        { 
            spell = self.spells.ASHEN_HALLOW,
            condition = function(self) return IsSpellKnown(self.spells.ASHEN_HALLOW) end
        }
    }
    
    -- Add Holy-specific defensive abilities
    table.insert(self.defensiveRotation, { 
        spell = self.spells.DIVINE_PROTECTION, 
        threshold = 60 
    })
    
    table.insert(self.defensiveRotation, {
        spell = self.spells.AURA_MASTERY,
        condition = function(self)
            -- In a real setting, this would check for group damage scenarios
            return self:GetHealthPct() < 40
        end
    })
end

-- Load Protection specialization
function Paladin:LoadProtectionSpec()
    -- Protection-specific spells
    self.spells.AVENGERS_SHIELD = 31935
    self.spells.SHIELD_OF_THE_RIGHTEOUS = 53600
    self.spells.JUDGMENT = 275779 -- Prot version
    self.spells.CONSECRATION = 26573
    self.spells.HAMMER_OF_THE_RIGHTEOUS = 53595
    self.spells.BLESSED_HAMMER = 204019
    self.spells.AVENGERS_VALOR = 197561
    self.spells.GUARDIAN_OF_ANCIENT_KINGS = 86659
    self.spells.ARDENT_DEFENDER = 31850
    self.spells.HAND_OF_THE_PROTECTOR = 213652
    self.spells.LIGHT_OF_THE_PROTECTOR = 184092
    self.spells.SERAPHIM = 152262
    self.spells.HAMMER_OF_WRATH = 24275
    self.spells.AVENGING_WRATH = 31884
    self.spells.MOMENT_OF_GLORY = 327193
    self.spells.RIGHTEOUS_PROTECTOR = 204074
    self.spells.REDOUBT = 280373
    self.spells.BULWARK_OF_ORDER = 209389
    
    -- Setup cooldown and aura tracking for Protection
    WR.Cooldown:StartTracking(self.spells.AVENGERS_SHIELD)
    WR.Cooldown:StartTracking(self.spells.JUDGMENT)
    WR.Cooldown:StartTracking(self.spells.HAMMER_OF_THE_RIGHTEOUS)
    WR.Cooldown:StartTracking(self.spells.BLESSED_HAMMER)
    WR.Cooldown:StartTracking(self.spells.GUARDIAN_OF_ANCIENT_KINGS)
    WR.Cooldown:StartTracking(self.spells.ARDENT_DEFENDER)
    WR.Cooldown:StartTracking(self.spells.AVENGING_WRATH)
    WR.Cooldown:StartTracking(self.spells.SHIELD_OF_THE_RIGHTEOUS)
    
    -- Track important buffs/debuffs
    WR.Auras:RegisterImportantAura(self.spells.SHIELD_OF_THE_RIGHTEOUS, 90, true, false)
    WR.Auras:RegisterImportantAura(self.spells.GUARDIAN_OF_ANCIENT_KINGS, 95, true, false)
    WR.Auras:RegisterImportantAura(self.spells.ARDENT_DEFENDER, 90, true, false)
    WR.Auras:RegisterImportantAura(self.spells.AVENGERS_VALOR, 80, true, false)
    WR.Auras:RegisterImportantAura(self.spells.SERAPHIM, 85, true, false)
    WR.Auras:RegisterImportantAura(self.spells.AVENGING_WRATH, 85, true, false)
    WR.Auras:RegisterImportantAura(self.spells.CONSECRATION, 70, true, false)
    
    -- Define Protection rotation for tanking
    self.singleTargetRotation = {
        -- Maintain Shield of the Righteous uptime for active mitigation
        {
            spell = self.spells.SHIELD_OF_THE_RIGHTEOUS,
            condition = function(self)
                local holyPower = UnitPower("player", Enum.PowerType.HolyPower)
                return holyPower >= 3 and not self:HasBuff(self.spells.SHIELD_OF_THE_RIGHTEOUS)
            end
        },
        
        -- Use Seraphim for burst if talented
        {
            spell = self.spells.SERAPHIM,
            condition = function(self)
                local holyPower = UnitPower("player", Enum.PowerType.HolyPower)
                return IsSpellKnown(self.spells.SERAPHIM) and holyPower >= 3
            end
        },
        
        -- Use Avenging Wrath for increased damage and healing
        { spell = self.spells.AVENGING_WRATH },
        
        -- Use covenant abilities
        { 
            spell = self.spells.DIVINE_TOLL,
            condition = function(self) return IsSpellKnown(self.spells.DIVINE_TOLL) end
        },
        { 
            spell = self.spells.VANQUISHERS_HAMMER,
            condition = function(self) return IsSpellKnown(self.spells.VANQUISHERS_HAMMER) end
        },
        { 
            spell = self.spells.ASHEN_HALLOW,
            condition = function(self) return IsSpellKnown(self.spells.ASHEN_HALLOW) end
        },
        { 
            spell = self.spells.BLESSING_OF_SEASONS,
            condition = function(self) return IsSpellKnown(self.spells.BLESSING_OF_SEASONS) end
        },
        
        -- Maintain Consecration uptime
        {
            spell = self.spells.CONSECRATION,
            condition = function(self)
                return not self:HasBuff(self.spells.CONSECRATION)
            end
        },
        
        -- Use Avenger's Shield on cooldown (priority ability)
        { spell = self.spells.AVENGERS_SHIELD },
        
        -- Use Hammer of Wrath in execute range or during Avenging Wrath
        {
            spell = self.spells.HAMMER_OF_WRATH,
            condition = function(self)
                return self:TargetInExecuteRange() or self:HasBuff(self.spells.AVENGING_WRATH)
            end
        },
        
        -- Use Judgment to generate Holy Power
        { spell = self.spells.JUDGMENT },
        
        -- Use Blessed Hammer if talented, otherwise Hammer of the Righteous
        {
            spell = self.spells.BLESSED_HAMMER,
            condition = function(self)
                return IsSpellKnown(self.spells.BLESSED_HAMMER)
            end
        },
        {
            spell = self.spells.HAMMER_OF_THE_RIGHTEOUS,
            condition = function(self)
                return not IsSpellKnown(self.spells.BLESSED_HAMMER)
            end
        },
        
        -- Use Word of Glory for self-healing when needed
        {
            spell = self.spells.WORD_OF_GLORY,
            condition = function(self)
                local holyPower = UnitPower("player", Enum.PowerType.HolyPower)
                return holyPower >= 3 and self:GetHealthPct() < 65
            end
        },
        
        -- Use Consecration if it's about to expire or not active
        { spell = self.spells.CONSECRATION }
    }
    
    -- AoE rotation for Protection
    self.aoeRotation = {
        -- Maintain Shield of the Righteous uptime for active mitigation
        {
            spell = self.spells.SHIELD_OF_THE_RIGHTEOUS,
            condition = function(self)
                local holyPower = UnitPower("player", Enum.PowerType.HolyPower)
                return holyPower >= 3 and not self:HasBuff(self.spells.SHIELD_OF_THE_RIGHTEOUS)
            end
        },
        
        -- Use Avenging Wrath for increased damage and healing
        { spell = self.spells.AVENGING_WRATH },
        
        -- Use covenant abilities
        { 
            spell = self.spells.DIVINE_TOLL,
            condition = function(self) return IsSpellKnown(self.spells.DIVINE_TOLL) end
        },
        { 
            spell = self.spells.ASHEN_HALLOW,
            condition = function(self) return IsSpellKnown(self.spells.ASHEN_HALLOW) end
        },
        
        -- Maintain Consecration uptime for AoE damage
        {
            spell = self.spells.CONSECRATION,
            condition = function(self)
                return not self:HasBuff(self.spells.CONSECRATION)
            end
        },
        
        -- Use Avenger's Shield for AoE threat and damage
        { spell = self.spells.AVENGERS_SHIELD },
        
        -- Use Judgment to generate Holy Power
        { spell = self.spells.JUDGMENT },
        
        -- Use Blessed Hammer if talented (good for AoE), otherwise Hammer of the Righteous
        {
            spell = self.spells.BLESSED_HAMMER,
            condition = function(self)
                return IsSpellKnown(self.spells.BLESSED_HAMMER)
            end
        },
        {
            spell = self.spells.HAMMER_OF_THE_RIGHTEOUS,
            condition = function(self)
                return not IsSpellKnown(self.spells.BLESSED_HAMMER)
            end
        },
        
        -- Use Consecration for AoE damage
        { spell = self.spells.CONSECRATION }
    }
    
    -- Define burst rotation
    self.burstRotation = {
        { spell = self.spells.AVENGING_WRATH },
        {
            spell = self.spells.MOMENT_OF_GLORY,
            condition = function(self) return IsSpellKnown(self.spells.MOMENT_OF_GLORY) end
        },
        { 
            spell = self.spells.DIVINE_TOLL,
            condition = function(self) return IsSpellKnown(self.spells.DIVINE_TOLL) end
        },
        { 
            spell = self.spells.ASHEN_HALLOW,
            condition = function(self) return IsSpellKnown(self.spells.ASHEN_HALLOW) end
        },
        {
            spell = self.spells.SERAPHIM,
            condition = function(self) 
                return IsSpellKnown(self.spells.SERAPHIM) and 
                       UnitPower("player", Enum.PowerType.HolyPower) >= 3
            end
        }
    }
    
    -- Add Protection-specific defensive abilities
    table.insert(self.defensiveRotation, 1, { -- High priority
        spell = self.spells.SHIELD_OF_THE_RIGHTEOUS,
        condition = function(self)
            local holyPower = UnitPower("player", Enum.PowerType.HolyPower)
            return holyPower >= 3 and not self:HasBuff(self.spells.SHIELD_OF_THE_RIGHTEOUS)
        end
    })
    
    table.insert(self.defensiveRotation, { 
        spell = self.spells.GUARDIAN_OF_ANCIENT_KINGS, 
        threshold = 35 
    })
    
    table.insert(self.defensiveRotation, { 
        spell = self.spells.ARDENT_DEFENDER, 
        threshold = 25 
    })
    
    table.insert(self.defensiveRotation, {
        spell = self.spells.WORD_OF_GLORY,
        condition = function(self)
            local holyPower = UnitPower("player", Enum.PowerType.HolyPower)
            return holyPower >= 3 and self:GetHealthPct() < 55
        end
    })
end

-- Load Retribution specialization
function Paladin:LoadRetributionSpec()
    -- Retribution-specific spells
    self.spells.CRUSADER_STRIKE = 35395
    self.spells.BLADE_OF_JUSTICE = 184575
    self.spells.JUDGMENT = 275773
    self.spells.DIVINE_STORM = 53385
    self.spells.TEMPLAR_STRIKE = 255937
    self.spells.TEMPLARS_VERDICT = 85256
    self.spells.AVENGING_WRATH = 31884
    self.spells.CONSECRATION = 26573
    self.spells.WAKE_OF_ASHES = 255937
    self.spells.HAMMER_OF_WRATH = 24275
    self.spells.SHIELD_OF_VENGEANCE = 184662
    self.spells.EXECUTION_SENTENCE = 343527
    self.spells.FINAL_RECKONING = 343721
    self.spells.DIVINE_PURPOSE = 223817
    self.spells.ART_OF_WAR = 267344
    self.spells.EMPYREAN_POWER = 326732
    self.spells.FINAL_VERDICT = 336872
    self.spells.CRUSADE = 231895
    
    -- Setup cooldown and aura tracking for Retribution
    WR.Cooldown:StartTracking(self.spells.CRUSADER_STRIKE)
    WR.Cooldown:StartTracking(self.spells.BLADE_OF_JUSTICE)
    WR.Cooldown:StartTracking(self.spells.JUDGMENT)
    WR.Cooldown:StartTracking(self.spells.AVENGING_WRATH)
    WR.Cooldown:StartTracking(self.spells.WAKE_OF_ASHES)
    WR.Cooldown:StartTracking(self.spells.HAMMER_OF_WRATH)
    WR.Cooldown:StartTracking(self.spells.SHIELD_OF_VENGEANCE)
    WR.Cooldown:StartTracking(self.spells.EXECUTION_SENTENCE)
    WR.Cooldown:StartTracking(self.spells.FINAL_RECKONING)
    
    -- Track important buffs/debuffs
    WR.Auras:RegisterImportantAura(self.spells.AVENGING_WRATH, 90, true, false)
    WR.Auras:RegisterImportantAura(self.spells.SHIELD_OF_VENGEANCE, 85, true, false)
    WR.Auras:RegisterImportantAura(self.spells.DIVINE_PURPOSE, 80, true, false)
    WR.Auras:RegisterImportantAura(self.spells.ART_OF_WAR, 75, true, false)
    WR.Auras:RegisterImportantAura(self.spells.EMPYREAN_POWER, 80, true, false)
    WR.Auras:RegisterImportantAura(197277, 90, false, true) -- Judgment debuff
    WR.Auras:RegisterImportantAura(self.spells.CRUSADE, 90, true, false)
    
    -- Define Retribution rotation for melee DPS
    self.singleTargetRotation = {
        -- Use Avenging Wrath or Crusade for burst
        {
            spell = self.spells.CRUSADE,
            condition = function(self)
                return IsSpellKnown(self.spells.CRUSADE)
            end
        },
        {
            spell = self.spells.AVENGING_WRATH,
            condition = function(self)
                return not IsSpellKnown(self.spells.CRUSADE)
            end
        },
        
        -- Use covenant abilities
        { 
            spell = self.spells.DIVINE_TOLL,
            condition = function(self) return IsSpellKnown(self.spells.DIVINE_TOLL) end
        },
        { 
            spell = self.spells.VANQUISHERS_HAMMER,
            condition = function(self) return IsSpellKnown(self.spells.VANQUISHERS_HAMMER) end
        },
        { 
            spell = self.spells.ASHEN_HALLOW,
            condition = function(self) return IsSpellKnown(self.spells.ASHEN_HALLOW) end
        },
        { 
            spell = self.spells.BLESSING_OF_SEASONS,
            condition = function(self) return IsSpellKnown(self.spells.BLESSING_OF_SEASONS) end
        },
        
        -- Use Execution Sentence if talented
        {
            spell = self.spells.EXECUTION_SENTENCE,
            condition = function(self)
                return IsSpellKnown(self.spells.EXECUTION_SENTENCE)
            end
        },
        
        -- Use Final Reckoning if talented
        {
            spell = self.spells.FINAL_RECKONING,
            condition = function(self)
                return IsSpellKnown(self.spells.FINAL_RECKONING)
            end
        },
        
        -- Use Hammer of Wrath in execute range or during Avenging Wrath/Crusade
        {
            spell = self.spells.HAMMER_OF_WRATH,
            condition = function(self)
                return self:TargetInExecuteRange() or 
                       self:HasBuff(self.spells.AVENGING_WRATH) or
                       self:HasBuff(self.spells.CRUSADE)
            end
        },
        
        -- Use Wake of Ashes for Holy Power generation
        {
            spell = self.spells.WAKE_OF_ASHES,
            condition = function(self)
                local holyPower = UnitPower("player", Enum.PowerType.HolyPower)
                return IsSpellKnown(self.spells.WAKE_OF_ASHES) and holyPower <= 2
            end
        },
        
        -- Use Blade of Justice for Holy Power generation
        { 
            spell = self.spells.BLADE_OF_JUSTICE,
            condition = function(self)
                local holyPower = UnitPower("player", Enum.PowerType.HolyPower)
                return holyPower <= 3
            end
        },
        
        -- Use Judgment to apply debuff and generate Holy Power
        {
            spell = self.spells.JUDGMENT,
            condition = function(self)
                return not self:HasDebuff(197277) -- Judgment debuff
            end
        },
        
        -- Use Templar's Verdict with Divine Purpose proc
        {
            spell = self.spells.TEMPLARS_VERDICT,
            condition = function(self)
                return self:HasBuff(self.spells.DIVINE_PURPOSE)
            end
        },
        
        -- Use Divine Storm with Empyrean Power proc
        {
            spell = self.spells.DIVINE_STORM,
            condition = function(self)
                return self:HasBuff(self.spells.EMPYREAN_POWER)
            end
        },
        
        -- Use Final Verdict if talented and enough Holy Power
        {
            spell = self.spells.FINAL_VERDICT,
            condition = function(self)
                local holyPower = UnitPower("player", Enum.PowerType.HolyPower)
                return IsSpellKnown(self.spells.FINAL_VERDICT) and holyPower >= 3
            end
        },
        
        -- Use Templar's Verdict as Holy Power spender
        {
            spell = self.spells.TEMPLARS_VERDICT,
            condition = function(self)
                local holyPower = UnitPower("player", Enum.PowerType.HolyPower)
                return holyPower >= 3
            end
        },
        
        -- Use Crusader Strike to generate Holy Power
        { 
            spell = self.spells.CRUSADER_STRIKE,
            condition = function(self)
                local holyPower = UnitPower("player", Enum.PowerType.HolyPower)
                return holyPower <= 4
            end
        },
        
        -- Use Consecration as filler
        { spell = self.spells.CONSECRATION }
    }
    
    -- AoE rotation for Retribution
    self.aoeRotation = {
        -- Use Avenging Wrath or Crusade for burst
        {
            spell = self.spells.CRUSADE,
            condition = function(self)
                return IsSpellKnown(self.spells.CRUSADE)
            end
        },
        {
            spell = self.spells.AVENGING_WRATH,
            condition = function(self)
                return not IsSpellKnown(self.spells.CRUSADE)
            end
        },
        
        -- Use covenant abilities
        { 
            spell = self.spells.DIVINE_TOLL,
            condition = function(self) return IsSpellKnown(self.spells.DIVINE_TOLL) end
        },
        { 
            spell = self.spells.ASHEN_HALLOW,
            condition = function(self) return IsSpellKnown(self.spells.ASHEN_HALLOW) end
        },
        
        -- Use Final Reckoning if talented
        {
            spell = self.spells.FINAL_RECKONING,
            condition = function(self)
                return IsSpellKnown(self.spells.FINAL_RECKONING)
            end
        },
        
        -- Use Wake of Ashes for AoE damage and Holy Power
        {
            spell = self.spells.WAKE_OF_ASHES,
            condition = function(self)
                return IsSpellKnown(self.spells.WAKE_OF_ASHES)
            end
        },
        
        -- Use Consecration for AoE damage
        { spell = self.spells.CONSECRATION },
        
        -- Use Blade of Justice for Holy Power generation
        { spell = self.spells.BLADE_OF_JUSTICE },
        
        -- Use Judgment to apply debuff and generate Holy Power
        { spell = self.spells.JUDGMENT },
        
        -- Use Divine Storm with Empyrean Power proc or as Holy Power spender
        {
            spell = self.spells.DIVINE_STORM,
            condition = function(self)
                local holyPower = UnitPower("player", Enum.PowerType.HolyPower)
                return self:HasBuff(self.spells.EMPYREAN_POWER) or holyPower >= 3
            end
        },
        
        -- Use Crusader Strike to generate Holy Power
        { spell = self.spells.CRUSADER_STRIKE }
    }
    
    -- Define burst rotation
    self.burstRotation = {
        {
            spell = self.spells.CRUSADE,
            condition = function(self)
                return IsSpellKnown(self.spells.CRUSADE)
            end
        },
        {
            spell = self.spells.AVENGING_WRATH,
            condition = function(self)
                return not IsSpellKnown(self.spells.CRUSADE)
            end
        },
        { 
            spell = self.spells.DIVINE_TOLL,
            condition = function(self) return IsSpellKnown(self.spells.DIVINE_TOLL) end
        },
        {
            spell = self.spells.FINAL_RECKONING,
            condition = function(self) return IsSpellKnown(self.spells.FINAL_RECKONING) end
        },
        {
            spell = self.spells.EXECUTION_SENTENCE,
            condition = function(self) return IsSpellKnown(self.spells.EXECUTION_SENTENCE) end
        },
        { 
            spell = self.spells.ASHEN_HALLOW,
            condition = function(self) return IsSpellKnown(self.spells.ASHEN_HALLOW) end
        }
    }
    
    -- Add Retribution-specific defensive abilities
    table.insert(self.defensiveRotation, { 
        spell = self.spells.SHIELD_OF_VENGEANCE, 
        threshold = 75 
    })
    
    table.insert(self.defensiveRotation, {
        spell = self.spells.WORD_OF_GLORY,
        condition = function(self)
            local holyPower = UnitPower("player", Enum.PowerType.HolyPower)
            return holyPower >= 3 and self:GetHealthPct() < 60
        end
    })
end

-- Class-specific pre-rotation checks
function Paladin:ClassSpecificChecks()
    -- Check for class-specific conditions
    
    -- Set appropriate Aura if none is active
    local hasAura = self:HasBuff(self.spells.DEVOTION_AURA) or
                    self:HasBuff(self.spells.RETRIBUTION_AURA) or
                    self:HasBuff(self.spells.CONCENTRATION_AURA) or
                    self:HasBuff(self.spells.CRUSADER_AURA)
    
    if not hasAura then
        -- Default aura based on spec
        if self.currentSpec == SPEC_HOLY then
            WR.Queue:Add(self.spells.DEVOTION_AURA)
            return false
        elseif self.currentSpec == SPEC_PROTECTION then
            WR.Queue:Add(self.spells.DEVOTION_AURA)
            return false
        elseif self.currentSpec == SPEC_RETRIBUTION then
            WR.Queue:Add(self.spells.RETRIBUTION_AURA)
            return false
        end
    end
    
    return true
end

-- Get default action when nothing else is available
function Paladin:GetDefaultAction()
    if self.currentSpec == SPEC_HOLY then
        return self.spells.HOLY_SHOCK
    elseif self.currentSpec == SPEC_PROTECTION then
        return self.spells.AVENGERS_SHIELD
    elseif self.currentSpec == SPEC_RETRIBUTION then
        return self.spells.CRUSADER_STRIKE
    end
    
    return nil
end

-- Initialize the module
Paladin:Initialize()

return Paladin