local addonName, WR = ...

-- Druid Class module
local Druid = {}
WR.Classes = WR.Classes or {}
WR.Classes.DRUID = Druid

-- Inherit from BaseClass
setmetatable(Druid, {__index = WR.BaseClass})

-- Resource type for druids (mana/energy/rage depending on form)
Druid.resourceType = Enum.PowerType.Mana

-- Define spec IDs
local SPEC_BALANCE = 102
local SPEC_FERAL = 103
local SPEC_GUARDIAN = 104
local SPEC_RESTORATION = 105

-- Class initialization
function Druid:Initialize()
    -- Inherit base initialization
    WR.BaseClass.Initialize(self)
    
    -- Register Specializations
    self:RegisterSpec(SPEC_BALANCE, "Balance")
    self:RegisterSpec(SPEC_FERAL, "Feral")
    self:RegisterSpec(SPEC_GUARDIAN, "Guardian")
    self:RegisterSpec(SPEC_RESTORATION, "Restoration")
    
    -- Shared spell IDs across all druid specs
    self.spells = {
        -- Forms
        CAT_FORM = 768,
        BEAR_FORM = 5487,
        TRAVEL_FORM = 783,
        MOONKIN_FORM = 24858,
        AQUATIC_FORM = 783, -- shared with Travel Form in recent expansions
        FLIGHT_FORM = 783, -- shared with Travel Form in recent expansions
        
        -- Common druid abilities
        MARK_OF_THE_WILD = 1126,
        REGROWTH = 8936,
        REJUVENATION = 774,
        SWIFTMEND = 18562,
        WILD_GROWTH = 48438,
        MOONFIRE = 8921,
        SUNFIRE = 93402,
        STARFIRE = 197628,
        WRATH = 5176,
        ENTANGLING_ROOTS = 339,
        CYCLONE = 33786,
        HIBERNATE = 2637,
        REBIRTH = 20484,
        BARKSKIN = 22812,
        PROWL = 5215,
        DASH = 1850,
        TYPHOON = 132469,
        URSOL'S_VORTEX = 102793,
        INNERVATE = 29166,
        RENEWAL = 108238,
        SOOTHE = 2908,
        REMOVE_CORRUPTION = 2782,
        GROWL = 6795,
        IRONFUR = 192081,
        FRENZIED_REGENERATION = 22842,
        MAUL = 6807,
        THRASH_BEAR = 77758,
        MANGLE = 33917,
        WILD_CHARGE = 102401,
        SURVIVAL_INSTINCTS = 61336,
        STAMPEDING_ROAR = 106898,
        INCAPACITATING_ROAR = 99,
        
        -- Covenant abilities
        RAVENOUS_FRENZY = 323546,      -- Venthyr
        CONVOKE_THE_SPIRITS = 323764,  -- Night Fae  
        KINDRED_SPIRITS = 326434,      -- Kyrian
        ADAPTIVE_SWARM = 325727,       -- Necrolord
    }
    
    -- Load shared druid data
    self:LoadSharedDruidData()
    
    WR:Debug("Druid module initialized")
end

-- Load shared spell and mechanics data for all druid specs
function Druid:LoadSharedDruidData()
    -- Register important buffs
    WR.Auras:RegisterImportantAura(self.spells.MARK_OF_THE_WILD, 60, true, false)
    WR.Auras:RegisterImportantAura(self.spells.BARKSKIN, 90, true, false)
    WR.Auras:RegisterImportantAura(self.spells.MOONFIRE, 80, false, true)
    WR.Auras:RegisterImportantAura(self.spells.SUNFIRE, 80, false, true)
    WR.Auras:RegisterImportantAura(self.spells.REGROWTH, 75, true, false)
    WR.Auras:RegisterImportantAura(self.spells.REJUVENATION, 75, true, false)
    WR.Auras:RegisterImportantAura(self.spells.IRONFUR, 85, true, false)
    WR.Auras:RegisterImportantAura(self.spells.FRENZIED_REGENERATION, 90, true, false)
    
    -- Setup cooldown tracking
    WR.Cooldown:StartTracking(self.spells.BARKSKIN)
    WR.Cooldown:StartTracking(self.spells.RENEWAL)
    WR.Cooldown:StartTracking(self.spells.DASH)
    WR.Cooldown:StartTracking(self.spells.TYPHOON)
    WR.Cooldown:StartTracking(self.spells.WILD_CHARGE)
    WR.Cooldown:StartTracking(self.spells.SURVIVAL_INSTINCTS)
    WR.Cooldown:StartTracking(self.spells.STAMPEDING_ROAR)
    WR.Cooldown:StartTracking(self.spells.INCAPACITATING_ROAR)
    
    -- Set up defensive rotation (shared by all specs)
    self.defensiveRotation = {
        { spell = self.spells.SURVIVAL_INSTINCTS, threshold = 30 },
        { spell = self.spells.BARKSKIN, threshold = 60 },
        { spell = self.spells.RENEWAL, threshold = 50 }
    }
end

-- Load a specific specialization
function Druid:LoadSpec(specId)
    -- Call the base class method to set up common components
    WR.BaseClass.LoadSpec(self, specId)
    
    -- Set the resource type based on spec
    if specId == SPEC_BALANCE then
        self.resourceType = Enum.PowerType.LunarPower
        self.secondaryResourceType = Enum.PowerType.Mana
    elseif specId == SPEC_FERAL then
        self.resourceType = Enum.PowerType.Energy
        self.secondaryResourceType = Enum.PowerType.ComboPoints
    elseif specId == SPEC_GUARDIAN then
        self.resourceType = Enum.PowerType.Rage
        self.secondaryResourceType = nil
    elseif specId == SPEC_RESTORATION then
        self.resourceType = Enum.PowerType.Mana
        self.secondaryResourceType = nil
    end
    
    -- Load specific spec data
    if specId == SPEC_BALANCE then
        self:LoadBalanceSpec()
    elseif specId == SPEC_FERAL then
        self:LoadFeralSpec()
    elseif specId == SPEC_GUARDIAN then
        self:LoadGuardianSpec()
    elseif specId == SPEC_RESTORATION then
        self:LoadRestorationSpec()
    end
    
    WR:Debug("Loaded druid spec:", self.specData.name)
    return true
end

-- Load Balance specialization
function Druid:LoadBalanceSpec()
    -- Balance-specific spells
    self.spells.ECLIPSE_SOLAR = 164545
    self.spells.ECLIPSE_LUNAR = 164547
    self.spells.STARSURGE = 78674
    self.spells.STARFALL = 191034
    self.spells.CELESTIAL_ALIGNMENT = 194223
    self.spells.FURY_OF_ELUNE = 202770
    self.spells.FORCE_OF_NATURE = 205636
    self.spells.NEW_MOON = 274281
    self.spells.HALF_MOON = 274282
    self.spells.FULL_MOON = 274283
    self.spells.STELLAR_FLARE = 202347
    self.spells.WARRIOR_OF_ELUNE = 202425
    self.spells.INCARNATION_CHOSEN_OF_ELUNE = 102560
    self.spells.SOUL_OF_THE_FOREST = 114107
    self.spells.MASS_ENTANGLEMENT = 102359
    self.spells.STELLAR_DRIFT = 202354
    self.spells.STARLORD = 202345
    self.spells.TWIN_MOONS = 279620
    self.spells.SHOOTING_STARS = 202342
    self.spells.SOLSTICE = 343648
    
    -- Setup cooldown and aura tracking for Balance
    WR.Cooldown:StartTracking(self.spells.CELESTIAL_ALIGNMENT)
    WR.Cooldown:StartTracking(self.spells.INCARNATION_CHOSEN_OF_ELUNE)
    WR.Cooldown:StartTracking(self.spells.FURY_OF_ELUNE)
    WR.Cooldown:StartTracking(self.spells.FORCE_OF_NATURE)
    WR.Cooldown:StartTracking(self.spells.NEW_MOON)
    
    -- Track important buffs/debuffs
    WR.Auras:RegisterImportantAura(self.spells.MOONKIN_FORM, 90, true, false)
    WR.Auras:RegisterImportantAura(self.spells.ECLIPSE_SOLAR, 95, true, false)
    WR.Auras:RegisterImportantAura(self.spells.ECLIPSE_LUNAR, 95, true, false)
    WR.Auras:RegisterImportantAura(self.spells.CELESTIAL_ALIGNMENT, 98, true, false)
    WR.Auras:RegisterImportantAura(self.spells.INCARNATION_CHOSEN_OF_ELUNE, 99, true, false)
    WR.Auras:RegisterImportantAura(self.spells.WARRIOR_OF_ELUNE, 80, true, false)
    WR.Auras:RegisterImportantAura(self.spells.STELLAR_FLARE, 85, false, true)
    
    -- Define Balance single target rotation
    self.singleTargetRotation = {
        -- Maintain Moonkin Form
        {
            spell = self.spells.MOONKIN_FORM,
            condition = function(self)
                return not self:HasBuff(self.spells.MOONKIN_FORM)
            end
        },
        
        -- Apply DoTs with pandemic refresh
        {
            spell = self.spells.MOONFIRE,
            condition = function(self)
                return not self:HasDebuff(self.spells.MOONFIRE) or
                       self:GetDebuffRemaining(self.spells.MOONFIRE) < 4.5
            end
        },
        {
            spell = self.spells.SUNFIRE,
            condition = function(self)
                return not self:HasDebuff(self.spells.SUNFIRE) or
                       self:GetDebuffRemaining(self.spells.SUNFIRE) < 4.5
            end
        },
        {
            spell = self.spells.STELLAR_FLARE,
            condition = function(self)
                return IsSpellKnown(self.spells.STELLAR_FLARE) and
                       (not self:HasDebuff(self.spells.STELLAR_FLARE) or
                        self:GetDebuffRemaining(self.spells.STELLAR_FLARE) < 4.5)
            end
        },
        
        -- Use covenant abilities
        { 
            spell = self.spells.CONVOKE_THE_SPIRITS,
            condition = function(self) 
                return IsSpellKnown(self.spells.CONVOKE_THE_SPIRITS) and
                       (self:HasBuff(self.spells.CELESTIAL_ALIGNMENT) or 
                        self:HasBuff(self.spells.INCARNATION_CHOSEN_OF_ELUNE))
            end
        },
        { 
            spell = self.spells.RAVENOUS_FRENZY,
            condition = function(self) 
                return IsSpellKnown(self.spells.RAVENOUS_FRENZY) and
                       (self:HasBuff(self.spells.CELESTIAL_ALIGNMENT) or 
                        self:HasBuff(self.spells.INCARNATION_CHOSEN_OF_ELUNE))
            end
        },
        { 
            spell = self.spells.KINDRED_SPIRITS,
            condition = function(self) return IsSpellKnown(self.spells.KINDRED_SPIRITS) end
        },
        { 
            spell = self.spells.ADAPTIVE_SWARM,
            condition = function(self) return IsSpellKnown(self.spells.ADAPTIVE_SWARM) end
        },
        
        -- Use Celestial Alignment / Incarnation
        {
            spell = self.spells.INCARNATION_CHOSEN_OF_ELUNE,
            condition = function(self)
                return IsSpellKnown(self.spells.INCARNATION_CHOSEN_OF_ELUNE) and
                       not self:SpellOnCooldown(self.spells.INCARNATION_CHOSEN_OF_ELUNE)
            end
        },
        {
            spell = self.spells.CELESTIAL_ALIGNMENT,
            condition = function(self)
                return not IsSpellKnown(self.spells.INCARNATION_CHOSEN_OF_ELUNE) and
                       not self:SpellOnCooldown(self.spells.CELESTIAL_ALIGNMENT)
            end
        },
        
        -- Use main DPS cooldowns
        {
            spell = self.spells.FURY_OF_ELUNE,
            condition = function(self)
                return IsSpellKnown(self.spells.FURY_OF_ELUNE) and
                       (self:HasBuff(self.spells.ECLIPSE_LUNAR) or
                        self:HasBuff(self.spells.CELESTIAL_ALIGNMENT) or
                        self:HasBuff(self.spells.INCARNATION_CHOSEN_OF_ELUNE))
            end
        },
        {
            spell = self.spells.FORCE_OF_NATURE,
            condition = function(self)
                return IsSpellKnown(self.spells.FORCE_OF_NATURE)
            end
        },
        
        -- Use Warrior of Elune if available
        {
            spell = self.spells.WARRIOR_OF_ELUNE,
            condition = function(self)
                return IsSpellKnown(self.spells.WARRIOR_OF_ELUNE) and
                       (self:HasBuff(self.spells.ECLIPSE_LUNAR) or
                        self:HasBuff(self.spells.CELESTIAL_ALIGNMENT) or
                        self:HasBuff(self.spells.INCARNATION_CHOSEN_OF_ELUNE))
            end
        },
        
        -- Use Starsurge during Eclipse/CA/Incarnation
        {
            spell = self.spells.STARSURGE,
            condition = function(self)
                return self:GetResource() >= 30 and
                       (self:HasBuff(self.spells.ECLIPSE_SOLAR) or
                        self:HasBuff(self.spells.ECLIPSE_LUNAR) or
                        self:HasBuff(self.spells.CELESTIAL_ALIGNMENT) or
                        self:HasBuff(self.spells.INCARNATION_CHOSEN_OF_ELUNE))
            end
        },
        
        -- Use Moon spells if talented
        {
            spell = self.spells.FULL_MOON,
            condition = function(self)
                return IsSpellKnown(self.spells.FULL_MOON) and
                       not self:SpellOnCooldown(self.spells.FULL_MOON)
            end
        },
        {
            spell = self.spells.HALF_MOON,
            condition = function(self)
                return IsSpellKnown(self.spells.HALF_MOON) and
                       not self:SpellOnCooldown(self.spells.HALF_MOON)
            end
        },
        {
            spell = self.spells.NEW_MOON,
            condition = function(self)
                return IsSpellKnown(self.spells.NEW_MOON) and
                       not self:SpellOnCooldown(self.spells.NEW_MOON)
            end
        },
        
        -- Eclipse generation
        {
            spell = self.spells.STARFIRE,
            condition = function(self)
                return self:HasBuff(self.spells.ECLIPSE_LUNAR) or
                       self:HasBuff(self.spells.WARRIOR_OF_ELUNE) or
                       self:HasBuff(self.spells.CELESTIAL_ALIGNMENT) or
                       self:HasBuff(self.spells.INCARNATION_CHOSEN_OF_ELUNE)
            end
        },
        {
            spell = self.spells.WRATH,
            condition = function(self)
                return self:HasBuff(self.spells.ECLIPSE_SOLAR) or
                       self:HasBuff(self.spells.CELESTIAL_ALIGNMENT) or
                       self:HasBuff(self.spells.INCARNATION_CHOSEN_OF_ELUNE)
            end
        },
        
        -- Default Eclipse generation
        {
            spell = self.spells.WRATH,
            condition = function(self)
                -- Eclipse logic would be more complex in the real addon
                -- This is a simplified version
                return not self:HasBuff(self.spells.ECLIPSE_LUNAR) and
                       not self:HasBuff(self.spells.ECLIPSE_SOLAR)
            end
        }
    }
    
    -- AoE rotation for Balance
    self.aoeRotation = {
        -- Maintain Moonkin Form
        {
            spell = self.spells.MOONKIN_FORM,
            condition = function(self)
                return not self:HasBuff(self.spells.MOONKIN_FORM)
            end
        },
        
        -- Apply DoTs
        {
            spell = self.spells.SUNFIRE,
            condition = function(self)
                return not self:HasDebuff(self.spells.SUNFIRE) or
                       self:GetDebuffRemaining(self.spells.SUNFIRE) < 4.5
            end
        },
        {
            spell = self.spells.MOONFIRE,
            condition = function(self)
                return (IsSpellKnown(self.spells.TWIN_MOONS) or self:GetEnemyCount(8) <= 3) and
                       (not self:HasDebuff(self.spells.MOONFIRE) or
                        self:GetDebuffRemaining(self.spells.MOONFIRE) < 4.5)
            end
        },
        
        -- Use covenant abilities
        { 
            spell = self.spells.CONVOKE_THE_SPIRITS,
            condition = function(self) 
                return IsSpellKnown(self.spells.CONVOKE_THE_SPIRITS) and
                       (self:HasBuff(self.spells.CELESTIAL_ALIGNMENT) or 
                        self:HasBuff(self.spells.INCARNATION_CHOSEN_OF_ELUNE))
            end
        },
        { 
            spell = self.spells.RAVENOUS_FRENZY,
            condition = function(self) 
                return IsSpellKnown(self.spells.RAVENOUS_FRENZY) and
                       (self:HasBuff(self.spells.CELESTIAL_ALIGNMENT) or 
                        self:HasBuff(self.spells.INCARNATION_CHOSEN_OF_ELUNE))
            end
        },
        
        -- Use Celestial Alignment / Incarnation
        {
            spell = self.spells.INCARNATION_CHOSEN_OF_ELUNE,
            condition = function(self)
                return IsSpellKnown(self.spells.INCARNATION_CHOSEN_OF_ELUNE)
            end
        },
        {
            spell = self.spells.CELESTIAL_ALIGNMENT,
            condition = function(self)
                return not IsSpellKnown(self.spells.INCARNATION_CHOSEN_OF_ELUNE)
            end
        },
        
        -- Use Starfall for AoE
        {
            spell = self.spells.STARFALL,
            condition = function(self)
                return self:GetResource() >= 50 and
                       self:GetEnemyCount(8) >= 3 and
                       (not self:HasBuff(self.spells.STARFALL) or
                        self:GetBuffRemaining(self.spells.STARFALL) < 2)
            end
        },
        
        -- Use Fury of Elune if talented
        {
            spell = self.spells.FURY_OF_ELUNE,
            condition = function(self)
                return IsSpellKnown(self.spells.FURY_OF_ELUNE)
            end
        },
        
        -- Use Force of Nature if talented
        {
            spell = self.spells.FORCE_OF_NATURE,
            condition = function(self)
                return IsSpellKnown(self.spells.FORCE_OF_NATURE)
            end
        },
        
        -- Use Starsurge for single target damage
        {
            spell = self.spells.STARSURGE,
            condition = function(self)
                return self:GetEnemyCount(8) <= 2 and self:GetResource() >= 30
            end
        },
        
        -- Use Moon spells if talented
        {
            spell = self.spells.FULL_MOON,
            condition = function(self)
                return IsSpellKnown(self.spells.FULL_MOON)
            end
        },
        {
            spell = self.spells.HALF_MOON,
            condition = function(self)
                return IsSpellKnown(self.spells.HALF_MOON)
            end
        },
        {
            spell = self.spells.NEW_MOON,
            condition = function(self)
                return IsSpellKnown(self.spells.NEW_MOON)
            end
        },
        
        -- AoE Eclipse generation
        {
            spell = self.spells.STARFIRE,
            condition = function(self)
                return (self:HasBuff(self.spells.ECLIPSE_LUNAR) or
                       self:HasBuff(self.spells.CELESTIAL_ALIGNMENT) or
                       self:HasBuff(self.spells.INCARNATION_CHOSEN_OF_ELUNE)) or
                       -- Eclipse generation
                       (not self:HasBuff(self.spells.ECLIPSE_LUNAR) and
                        not self:HasBuff(self.spells.ECLIPSE_SOLAR))
            end
        },
        
        -- Fallback
        { spell = self.spells.WRATH }
    }
    
    -- Define burst rotation
    self.burstRotation = {
        {
            spell = self.spells.MOONKIN_FORM,
            condition = function(self)
                return not self:HasBuff(self.spells.MOONKIN_FORM)
            end
        },
        {
            spell = self.spells.INCARNATION_CHOSEN_OF_ELUNE,
            condition = function(self)
                return IsSpellKnown(self.spells.INCARNATION_CHOSEN_OF_ELUNE)
            end
        },
        {
            spell = self.spells.CELESTIAL_ALIGNMENT,
            condition = function(self)
                return not IsSpellKnown(self.spells.INCARNATION_CHOSEN_OF_ELUNE)
            end
        },
        { 
            spell = self.spells.CONVOKE_THE_SPIRITS,
            condition = function(self) return IsSpellKnown(self.spells.CONVOKE_THE_SPIRITS) end
        },
        { 
            spell = self.spells.RAVENOUS_FRENZY,
            condition = function(self) return IsSpellKnown(self.spells.RAVENOUS_FRENZY) end
        },
        {
            spell = self.spells.FURY_OF_ELUNE,
            condition = function(self) return IsSpellKnown(self.spells.FURY_OF_ELUNE) end
        },
        {
            spell = self.spells.FORCE_OF_NATURE,
            condition = function(self) return IsSpellKnown(self.spells.FORCE_OF_NATURE) end
        }
    }
end

-- Load Feral specialization
function Druid:LoadFeralSpec()
    -- Feral-specific spells
    self.spells.RAKE = 1822
    self.spells.RIP = 1079
    self.spells.SHRED = 5221
    self.spells.FEROCIOUS_BITE = 22568
    self.spells.TIGER'S_FURY = 5217
    self.spells.BERSERK = 106951
    self.spells.SAVAGE_ROAR = 52610
    self.spells.INCARNATION_KING_OF_THE_JUNGLE = 102543
    self.spells.FERAL_FRENZY = 274837
    self.spells.BLOODTALONS = 145152
    self.spells.SABERTOOTH = 202031
    self.spells.PRIMAL_WRATH = 285381
    self.spells.BRUTAL_SLASH = 202028
    self.spells.THRASH_CAT = 106830
    self.spells.MAIM = 22570
    self.spells.SWIPE_CAT = 213764
    self.spells.PREDATORY_SWIFTNESS = 69369
    self.spells.APEX_PREDATOR = 255984
    self.spells.MOMENT_OF_CLARITY = 236068
    self.spells.FERAL_CHARGE = 49376
    self.spells.SKULL_BASH = 106839
    
    -- Setup cooldown and aura tracking for Feral
    WR.Cooldown:StartTracking(self.spells.TIGER'S_FURY)
    WR.Cooldown:StartTracking(self.spells.BERSERK)
    WR.Cooldown:StartTracking(self.spells.INCARNATION_KING_OF_THE_JUNGLE)
    WR.Cooldown:StartTracking(self.spells.FERAL_FRENZY)
    WR.Cooldown:StartTracking(self.spells.MAIM)
    WR.Cooldown:StartTracking(self.spells.SKULL_BASH)
    
    -- Track important buffs/debuffs
    WR.Auras:RegisterImportantAura(self.spells.CAT_FORM, 90, true, false)
    WR.Auras:RegisterImportantAura(self.spells.RAKE, 85, false, true)
    WR.Auras:RegisterImportantAura(self.spells.RIP, 90, false, true)
    WR.Auras:RegisterImportantAura(self.spells.TIGER'S_FURY, 80, true, false)
    WR.Auras:RegisterImportantAura(self.spells.BERSERK, 85, true, false)
    WR.Auras:RegisterImportantAura(self.spells.INCARNATION_KING_OF_THE_JUNGLE, 85, true, false)
    WR.Auras:RegisterImportantAura(self.spells.SAVAGE_ROAR, 80, true, false)
    WR.Auras:RegisterImportantAura(self.spells.BLOODTALONS, 75, true, false)
    WR.Auras:RegisterImportantAura(self.spells.PREDATORY_SWIFTNESS, 75, true, false)
    WR.Auras:RegisterImportantAura(self.spells.THRASH_CAT, 75, false, true)
    WR.Auras:RegisterImportantAura(self.spells.PROWL, 90, true, false)
    
    -- Set interrupt ability
    self.interruptRotation = {
        { spell = self.spells.SKULL_BASH }
    }
    
    -- Define Feral single target rotation
    self.singleTargetRotation = {
        -- Maintain Cat Form
        {
            spell = self.spells.CAT_FORM,
            condition = function(self)
                return not self:HasBuff(self.spells.CAT_FORM)
            end
        },
        
        -- Use Tiger's Fury for energy and damage
        {
            spell = self.spells.TIGER'S_FURY,
            condition = function(self)
                return self:GetResourcePct() < 30
            end
        },
        
        -- Use Berserk/Incarnation
        {
            spell = self.spells.INCARNATION_KING_OF_THE_JUNGLE,
            condition = function(self)
                return IsSpellKnown(self.spells.INCARNATION_KING_OF_THE_JUNGLE)
            end
        },
        {
            spell = self.spells.BERSERK,
            condition = function(self)
                return not IsSpellKnown(self.spells.INCARNATION_KING_OF_THE_JUNGLE)
            end
        },
        
        -- Use covenant abilities
        { 
            spell = self.spells.CONVOKE_THE_SPIRITS,
            condition = function(self) 
                return IsSpellKnown(self.spells.CONVOKE_THE_SPIRITS) and
                       (self:HasBuff(self.spells.BERSERK) or 
                        self:HasBuff(self.spells.INCARNATION_KING_OF_THE_JUNGLE) or
                        self:HasBuff(self.spells.TIGER'S_FURY))
            end
        },
        { 
            spell = self.spells.RAVENOUS_FRENZY,
            condition = function(self) 
                return IsSpellKnown(self.spells.RAVENOUS_FRENZY) and
                       (self:HasBuff(self.spells.BERSERK) or 
                        self:HasBuff(self.spells.INCARNATION_KING_OF_THE_JUNGLE))
            end
        },
        { 
            spell = self.spells.KINDRED_SPIRITS,
            condition = function(self) return IsSpellKnown(self.spells.KINDRED_SPIRITS) end
        },
        { 
            spell = self.spells.ADAPTIVE_SWARM,
            condition = function(self) return IsSpellKnown(self.spells.ADAPTIVE_SWARM) end
        },
        
        -- Feral Frenzy if talented
        {
            spell = self.spells.FERAL_FRENZY,
            condition = function(self)
                return IsSpellKnown(self.spells.FERAL_FRENZY) and
                       self:GetComboPoints() <= 2
            end
        },
        
        -- Maintain Savage Roar if talented
        {
            spell = self.spells.SAVAGE_ROAR,
            condition = function(self)
                return IsSpellKnown(self.spells.SAVAGE_ROAR) and
                       (not self:HasBuff(self.spells.SAVAGE_ROAR) or
                        self:GetBuffRemaining(self.spells.SAVAGE_ROAR) < 6) and
                       self:GetComboPoints() >= 1
            end
        },
        
        -- Apply/refresh Rake
        {
            spell = self.spells.RAKE,
            condition = function(self)
                return not self:HasDebuff(self.spells.RAKE) or
                       self:GetDebuffRemaining(self.spells.RAKE) < 4.5 or
                       (self:HasBuff(self.spells.BLOODTALONS) and
                        self:GetDebuffRemaining(self.spells.RAKE) < 7.2)
            end
        },
        
        -- Apply/refresh Moonfire (if Balance Affinity is taken)
        {
            spell = self.spells.MOONFIRE,
            condition = function(self)
                return IsSpellKnown(self.spells.MOONFIRE) and
                       (not self:HasDebuff(self.spells.MOONFIRE) or
                        self:GetDebuffRemaining(self.spells.MOONFIRE) < 4.5)
            end
        },
        
        -- Apply/refresh Rip
        {
            spell = self.spells.RIP,
            condition = function(self)
                return self:GetComboPoints() >= 5 and
                       (not self:HasDebuff(self.spells.RIP) or
                        self:GetDebuffRemaining(self.spells.RIP) < 7.2 or
                        (self:HasBuff(self.spells.BLOODTALONS) and
                         self:GetDebuffRemaining(self.spells.RIP) < 9.9))
            end
        },
        
        -- Use Ferocious Bite
        {
            spell = self.spells.FEROCIOUS_BITE,
            condition = function(self)
                return self:GetComboPoints() >= 5 and
                       (self:HasDebuff(self.spells.RIP) and self:GetDebuffRemaining(self.spells.RIP) > 7.2) and
                       (not IsSpellKnown(self.spells.SAVAGE_ROAR) or
                        self:HasBuff(self.spells.SAVAGE_ROAR) and self:GetBuffRemaining(self.spells.SAVAGE_ROAR) > 6)
            end
        },
        
        -- Regrowth if Predatory Swiftness is active (or free Bloodtalons)
        {
            spell = self.spells.REGROWTH,
            condition = function(self)
                return IsSpellKnown(self.spells.BLOODTALONS) and
                       self:HasBuff(self.spells.PREDATORY_SWIFTNESS) and
                       not self:HasBuff(self.spells.BLOODTALONS)
            end
        },
        
        -- Use Brutal Slash if talented
        {
            spell = self.spells.BRUTAL_SLASH,
            condition = function(self)
                return IsSpellKnown(self.spells.BRUTAL_SLASH)
            end
        },
        
        -- Thrash for Bloodtalons or if talented
        {
            spell = self.spells.THRASH_CAT,
            condition = function(self)
                return (IsSpellKnown(self.spells.BLOODTALONS) and not self:HasBuff(self.spells.BLOODTALONS)) or
                       (not self:HasDebuff(self.spells.THRASH_CAT) or
                        self:GetDebuffRemaining(self.spells.THRASH_CAT) < 4.5)
            end
        },
        
        -- Shred as main combo point generator
        { spell = self.spells.SHRED }
    }
    
    -- AoE rotation for Feral
    self.aoeRotation = {
        -- Maintain Cat Form
        {
            spell = self.spells.CAT_FORM,
            condition = function(self)
                return not self:HasBuff(self.spells.CAT_FORM)
            end
        },
        
        -- Use Tiger's Fury for energy and damage
        {
            spell = self.spells.TIGER'S_FURY,
            condition = function(self)
                return self:GetResourcePct() < 30
            end
        },
        
        -- Use Berserk/Incarnation
        {
            spell = self.spells.INCARNATION_KING_OF_THE_JUNGLE,
            condition = function(self)
                return IsSpellKnown(self.spells.INCARNATION_KING_OF_THE_JUNGLE)
            end
        },
        {
            spell = self.spells.BERSERK,
            condition = function(self)
                return not IsSpellKnown(self.spells.INCARNATION_KING_OF_THE_JUNGLE)
            end
        },
        
        -- Use covenant abilities
        { 
            spell = self.spells.CONVOKE_THE_SPIRITS,
            condition = function(self) 
                return IsSpellKnown(self.spells.CONVOKE_THE_SPIRITS) and
                       (self:HasBuff(self.spells.BERSERK) or 
                        self:HasBuff(self.spells.INCARNATION_KING_OF_THE_JUNGLE) or
                        self:HasBuff(self.spells.TIGER'S_FURY))
            end
        },
        { 
            spell = self.spells.RAVENOUS_FRENZY,
            condition = function(self) 
                return IsSpellKnown(self.spells.RAVENOUS_FRENZY) and
                       (self:HasBuff(self.spells.BERSERK) or 
                        self:HasBuff(self.spells.INCARNATION_KING_OF_THE_JUNGLE))
            end
        },
        
        -- Maintain Savage Roar if talented
        {
            spell = self.spells.SAVAGE_ROAR,
            condition = function(self)
                return IsSpellKnown(self.spells.SAVAGE_ROAR) and
                       (not self:HasBuff(self.spells.SAVAGE_ROAR) or
                        self:GetBuffRemaining(self.spells.SAVAGE_ROAR) < 6) and
                       self:GetComboPoints() >= 1
            end
        },
        
        -- Apply/refresh Thrash for AoE
        {
            spell = self.spells.THRASH_CAT,
            condition = function(self)
                return not self:HasDebuff(self.spells.THRASH_CAT) or
                       self:GetDebuffRemaining(self.spells.THRASH_CAT) < 4.5
            end
        },
        
        -- Use Primal Wrath for AoE finisher if talented
        {
            spell = self.spells.PRIMAL_WRATH,
            condition = function(self)
                return IsSpellKnown(self.spells.PRIMAL_WRATH) and
                       self:GetComboPoints() >= 5 and
                       self:GetEnemyCount(8) >= 3
            end
        },
        
        -- Use Brutal Slash for AoE if talented
        {
            spell = self.spells.BRUTAL_SLASH,
            condition = function(self)
                return IsSpellKnown(self.spells.BRUTAL_SLASH)
            end
        },
        
        -- Apply Rake to primary target
        {
            spell = self.spells.RAKE,
            condition = function(self)
                return not self:HasDebuff(self.spells.RAKE) or
                       self:GetDebuffRemaining(self.spells.RAKE) < 4.5
            end
        },
        
        -- Use Swipe for AoE
        { 
            spell = self.spells.SWIPE_CAT,
            condition = function(self)
                return self:GetEnemyCount(8) >= 3
            end
        },
        
        -- Fallback to Shred for combo points
        { spell = self.spells.SHRED }
    }
    
    -- Define burst rotation
    self.burstRotation = {
        {
            spell = self.spells.CAT_FORM,
            condition = function(self)
                return not self:HasBuff(self.spells.CAT_FORM)
            end
        },
        { spell = self.spells.TIGER'S_FURY },
        {
            spell = self.spells.INCARNATION_KING_OF_THE_JUNGLE,
            condition = function(self)
                return IsSpellKnown(self.spells.INCARNATION_KING_OF_THE_JUNGLE)
            end
        },
        {
            spell = self.spells.BERSERK,
            condition = function(self)
                return not IsSpellKnown(self.spells.INCARNATION_KING_OF_THE_JUNGLE)
            end
        },
        { 
            spell = self.spells.CONVOKE_THE_SPIRITS,
            condition = function(self) return IsSpellKnown(self.spells.CONVOKE_THE_SPIRITS) end
        },
        { 
            spell = self.spells.RAVENOUS_FRENZY,
            condition = function(self) return IsSpellKnown(self.spells.RAVENOUS_FRENZY) end
        },
        {
            spell = self.spells.FERAL_FRENZY,
            condition = function(self) return IsSpellKnown(self.spells.FERAL_FRENZY) end
        }
    }
    
    -- Add Feral-specific defensive abilities
    table.insert(self.defensiveRotation, {
        spell = self.spells.SURVIVAL_INSTINCTS,
        threshold = 25
    })
end

-- Load Guardian specialization
function Druid:LoadGuardianSpec()
    -- Guardian-specific spells
    self.spells.IRONFUR = 192081
    self.spells.FRENZIED_REGENERATION = 22842
    self.spells.BRISTLING_FUR = 155835
    self.spells.PULVERIZE = 80313
    self.spells.INCARNATION_GUARDIAN_OF_URSOC = 102558
    self.spells.LUNAR_BEAM = 204066
    self.spells.THRASH_BEAR = 77758
    self.spells.MANGLE = 33917
    self.spells.MAUL = 6807
    self.spells.SWIPE_BEAR = 213771
    self.spells.SURVIVAL_INSTINCTS = 61336
    self.spells.GUARDIAN_OF_ELUNE = 155578
    self.spells.GALACTIC_GUARDIAN = 203964
    self.spells.SOUL_OF_THE_FOREST = 158477
    self.spells.EARTHWARDEN = 203974
    self.spells.SURVIVAL_OF_THE_FITTEST = 203965
    self.spells.GORE = 210706
    self.spells.TOOTH_AND_CLAW = 135286
    self.spells.BERSERK_BEAR = 50334
    self.spells.SKULL_BASH = 106839
    self.spells.BERSERK_UNCHECKED_AGGRESSION = 50334
    
    -- Setup cooldown and aura tracking for Guardian
    WR.Cooldown:StartTracking(self.spells.IRONFUR)
    WR.Cooldown:StartTracking(self.spells.FRENZIED_REGENERATION)
    WR.Cooldown:StartTracking(self.spells.BRISTLING_FUR)
    WR.Cooldown:StartTracking(self.spells.INCARNATION_GUARDIAN_OF_URSOC)
    WR.Cooldown:StartTracking(self.spells.LUNAR_BEAM)
    WR.Cooldown:StartTracking(self.spells.THRASH_BEAR)
    WR.Cooldown:StartTracking(self.spells.MANGLE)
    WR.Cooldown:StartTracking(self.spells.MAUL)
    WR.Cooldown:StartTracking(self.spells.BERSERK_BEAR)
    WR.Cooldown:StartTracking(self.spells.SKULL_BASH)
    
    -- Track important buffs/debuffs
    WR.Auras:RegisterImportantAura(self.spells.BEAR_FORM, 90, true, false)
    WR.Auras:RegisterImportantAura(self.spells.IRONFUR, 95, true, false)
    WR.Auras:RegisterImportantAura(self.spells.FRENZIED_REGENERATION, 95, true, false)
    WR.Auras:RegisterImportantAura(self.spells.INCARNATION_GUARDIAN_OF_URSOC, 85, true, false)
    WR.Auras:RegisterImportantAura(self.spells.GUARDIAN_OF_ELUNE, 80, true, false)
    WR.Auras:RegisterImportantAura(self.spells.GALACTIC_GUARDIAN, 75, true, false)
    WR.Auras:RegisterImportantAura(self.spells.THRASH_BEAR, 85, false, true)
    WR.Auras:RegisterImportantAura(self.spells.TOOTH_AND_CLAW, 80, true, false)
    WR.Auras:RegisterImportantAura(self.spells.BERSERK_BEAR, 90, true, false)
    
    -- Set interrupt ability
    self.interruptRotation = {
        { spell = self.spells.SKULL_BASH }
    }
    
    -- Define Guardian single target rotation
    self.singleTargetRotation = {
        -- Maintain Bear Form
        {
            spell = self.spells.BEAR_FORM,
            condition = function(self)
                return not self:HasBuff(self.spells.BEAR_FORM)
            end
        },
        
        -- Defensive rotations are prioritized in Guardian spec
        -- Use Ironfur for physical damage reduction
        {
            spell = self.spells.IRONFUR,
            condition = function(self)
                return not self:HasBuff(self.spells.IRONFUR) or
                       (self:GetBuffRemaining(self.spells.IRONFUR) < 3 and self:GetResource() >= 45)
            end
        },
        
        -- Use Frenzied Regeneration for healing
        {
            spell = self.spells.FRENZIED_REGENERATION,
            condition = function(self)
                return self:GetHealthPct() < 70 and
                       not self:SpellOnCooldown(self.spells.FRENZIED_REGENERATION)
            end
        },
        
        -- Use Bristling Fur for rage generation if talented
        {
            spell = self.spells.BRISTLING_FUR,
            condition = function(self)
                return IsSpellKnown(self.spells.BRISTLING_FUR) and
                       self:GetResourcePct() < 30
            end
        },
        
        -- Use Berserk/Incarnation
        {
            spell = self.spells.INCARNATION_GUARDIAN_OF_URSOC,
            condition = function(self)
                return IsSpellKnown(self.spells.INCARNATION_GUARDIAN_OF_URSOC)
            end
        },
        {
            spell = self.spells.BERSERK_BEAR,
            condition = function(self)
                return not IsSpellKnown(self.spells.INCARNATION_GUARDIAN_OF_URSOC)
            end
        },
        
        -- Use covenant abilities
        { 
            spell = self.spells.CONVOKE_THE_SPIRITS,
            condition = function(self) 
                return IsSpellKnown(self.spells.CONVOKE_THE_SPIRITS) and
                       (self:HasBuff(self.spells.BERSERK_BEAR) or 
                        self:HasBuff(self.spells.INCARNATION_GUARDIAN_OF_URSOC))
            end
        },
        { 
            spell = self.spells.RAVENOUS_FRENZY,
            condition = function(self) 
                return IsSpellKnown(self.spells.RAVENOUS_FRENZY) and
                       (self:HasBuff(self.spells.BERSERK_BEAR) or 
                        self:HasBuff(self.spells.INCARNATION_GUARDIAN_OF_URSOC))
            end
        },
        { 
            spell = self.spells.KINDRED_SPIRITS,
            condition = function(self) return IsSpellKnown(self.spells.KINDRED_SPIRITS) end
        },
        { 
            spell = self.spells.ADAPTIVE_SWARM,
            condition = function(self) return IsSpellKnown(self.spells.ADAPTIVE_SWARM) end
        },
        
        -- Use Lunar Beam if talented
        {
            spell = self.spells.LUNAR_BEAM,
            condition = function(self)
                return IsSpellKnown(self.spells.LUNAR_BEAM)
            end
        },
        
        -- Apply Moonfire if Galactic Guardian procs or for Balance Affinity
        {
            spell = self.spells.MOONFIRE,
            condition = function(self)
                return (self:HasBuff(self.spells.GALACTIC_GUARDIAN) or IsSpellKnown(self.spells.MOONFIRE)) and 
                       (not self:HasDebuff(self.spells.MOONFIRE) or
                        self:GetDebuffRemaining(self.spells.MOONFIRE) < 4.5)
            end
        },
        
        -- Apply/refresh Thrash for DoT and for Pulverize
        {
            spell = self.spells.THRASH_BEAR,
            condition = function(self)
                return not self:HasDebuff(self.spells.THRASH_BEAR) or
                       self:GetDebuffRemaining(self.spells.THRASH_BEAR) < 4.5
            end
        },
        
        -- Use Pulverize if talented
        {
            spell = self.spells.PULVERIZE,
            condition = function(self)
                return IsSpellKnown(self.spells.PULVERIZE) and
                       self:GetDebuffStacks(self.spells.THRASH_BEAR) >= 3
            end
        },
        
        -- Use Mangle on cooldown (primary rage generator)
        {
            spell = self.spells.MANGLE,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.MANGLE) or
                       self:HasBuff(self.spells.GORE)
            end
        },
        
        -- Use Maul for damage if we have excess rage
        {
            spell = self.spells.MAUL,
            condition = function(self)
                return self:GetResource() >= 70 and
                       self:HasBuff(self.spells.IRONFUR) and
                       self:GetHealthPct() > 70
            end
        },
        
        -- Fallback: Thrash for AoE
        {
            spell = self.spells.THRASH_BEAR,
            condition = function(self)
                return self:GetEnemyCount(8) > 1
            end
        },
        
        -- Fallback: Swipe for AoE
        {
            spell = self.spells.SWIPE_BEAR,
            condition = function(self)
                return self:GetEnemyCount(8) > 1
            end
        },
        
        -- Fallback: Moonfire if available
        {
            spell = self.spells.MOONFIRE,
            condition = function(self)
                return IsSpellKnown(self.spells.MOONFIRE)
            end
        },
        
        -- Fallback: Swipe as filler
        { spell = self.spells.SWIPE_BEAR }
    }
    
    -- AoE rotation for Guardian
    self.aoeRotation = {
        -- Maintain Bear Form
        {
            spell = self.spells.BEAR_FORM,
            condition = function(self)
                return not self:HasBuff(self.spells.BEAR_FORM)
            end
        },
        
        -- Use Ironfur for physical damage reduction
        {
            spell = self.spells.IRONFUR,
            condition = function(self)
                return not self:HasBuff(self.spells.IRONFUR) or
                       (self:GetBuffRemaining(self.spells.IRONFUR) < 3 and self:GetResource() >= 45)
            end
        },
        
        -- Use Frenzied Regeneration for healing
        {
            spell = self.spells.FRENZIED_REGENERATION,
            condition = function(self)
                return self:GetHealthPct() < 70 and
                       not self:SpellOnCooldown(self.spells.FRENZIED_REGENERATION)
            end
        },
        
        -- Use Berserk/Incarnation
        {
            spell = self.spells.INCARNATION_GUARDIAN_OF_URSOC,
            condition = function(self)
                return IsSpellKnown(self.spells.INCARNATION_GUARDIAN_OF_URSOC)
            end
        },
        {
            spell = self.spells.BERSERK_BEAR,
            condition = function(self)
                return not IsSpellKnown(self.spells.INCARNATION_GUARDIAN_OF_URSOC)
            end
        },
        
        -- Use covenant abilities
        { 
            spell = self.spells.CONVOKE_THE_SPIRITS,
            condition = function(self) 
                return IsSpellKnown(self.spells.CONVOKE_THE_SPIRITS) and
                       (self:HasBuff(self.spells.BERSERK_BEAR) or 
                        self:HasBuff(self.spells.INCARNATION_GUARDIAN_OF_URSOC))
            end
        },
        { 
            spell = self.spells.RAVENOUS_FRENZY,
            condition = function(self) 
                return IsSpellKnown(self.spells.RAVENOUS_FRENZY) and
                       (self:HasBuff(self.spells.BERSERK_BEAR) or 
                        self:HasBuff(self.spells.INCARNATION_GUARDIAN_OF_URSOC))
            end
        },
        
        -- Use Lunar Beam if talented
        {
            spell = self.spells.LUNAR_BEAM,
            condition = function(self)
                return IsSpellKnown(self.spells.LUNAR_BEAM)
            end
        },
        
        -- Apply/refresh Thrash for DoT
        { spell = self.spells.THRASH_BEAR },
        
        -- Use Mangle on cooldown
        {
            spell = self.spells.MANGLE,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.MANGLE) or
                       self:HasBuff(self.spells.GORE)
            end
        },
        
        -- AoE with Swipe
        { spell = self.spells.SWIPE_BEAR }
    }
    
    -- Define burst rotation
    self.burstRotation = {
        {
            spell = self.spells.BEAR_FORM,
            condition = function(self)
                return not self:HasBuff(self.spells.BEAR_FORM)
            end
        },
        {
            spell = self.spells.INCARNATION_GUARDIAN_OF_URSOC,
            condition = function(self)
                return IsSpellKnown(self.spells.INCARNATION_GUARDIAN_OF_URSOC)
            end
        },
        {
            spell = self.spells.BERSERK_BEAR,
            condition = function(self)
                return not IsSpellKnown(self.spells.INCARNATION_GUARDIAN_OF_URSOC)
            end
        },
        { 
            spell = self.spells.CONVOKE_THE_SPIRITS,
            condition = function(self) return IsSpellKnown(self.spells.CONVOKE_THE_SPIRITS) end
        },
        { 
            spell = self.spells.RAVENOUS_FRENZY,
            condition = function(self) return IsSpellKnown(self.spells.RAVENOUS_FRENZY) end
        },
        {
            spell = self.spells.LUNAR_BEAM,
            condition = function(self) return IsSpellKnown(self.spells.LUNAR_BEAM) end
        }
    }
    
    -- Add Guardian-specific defensive abilities
    table.insert(self.defensiveRotation, {
        spell = self.spells.IRONFUR,
        threshold = 80
    })
    
    table.insert(self.defensiveRotation, {
        spell = self.spells.FRENZIED_REGENERATION,
        threshold = 60
    })
    
    table.insert(self.defensiveRotation, {
        spell = self.spells.SURVIVAL_INSTINCTS,
        threshold = 40
    })
end

-- Load Restoration specialization
function Druid:LoadRestorationSpec()
    -- Restoration-specific spells
    self.spells.REGROWTH = 8936
    self.spells.REJUVENATION = 774
    self.spells.LIFEBLOOM = 33763
    self.spells.WILD_GROWTH = 48438
    self.spells.SWIFTMEND = 18562
    self.spells.TRANQUILITY = 740
    self.spells.IRONBARK = 102342
    self.spells.FLOURISH = 197721
    self.spells.EFFLORESCENCE = 145205
    self.spells.CENARION_WARD = 102351
    self.spells.OVERGROWTH = 203651
    self.spells.RENEWAL = 108238
    self.spells.INNERVATE = 29166
    self.spells.NATURES_SWIFTNESS = 132158
    self.spells.NATURE'S_CURE = 88423
    self.spells.GERMINATION = 155675
    self.spells.CULTIVATION = 200390
    self.spells.INCARNATION_TREE_OF_LIFE = 33891
    self.spells.SOUL_OF_THE_FOREST = 158478
    self.spells.SPRING_BLOSSOMS = 207385
    self.spells.ABUNDANCE = 207383
    self.spells.NOURISH = 50464
    self.spells.PHOTOSYNTHESIS = 274902
    self.spells.GROVE_TENDING = 279793
    self.spells.RESTORATION_AFFINITY = 197492
    
    -- Setup cooldown and aura tracking for Restoration
    WR.Cooldown:StartTracking(self.spells.SWIFTMEND)
    WR.Cooldown:StartTracking(self.spells.TRANQUILITY)
    WR.Cooldown:StartTracking(self.spells.IRONBARK)
    WR.Cooldown:StartTracking(self.spells.FLOURISH)
    WR.Cooldown:StartTracking(self.spells.CENARION_WARD)
    WR.Cooldown:StartTracking(self.spells.NATURE'S_CURE)
    WR.Cooldown:StartTracking(self.spells.NATURES_SWIFTNESS)
    WR.Cooldown:StartTracking(self.spells.INNERVATE)
    WR.Cooldown:StartTracking(self.spells.INCARNATION_TREE_OF_LIFE)
    
    -- Track important buffs/debuffs
    WR.Auras:RegisterImportantAura(self.spells.REJUVENATION, 85, true, false)
    WR.Auras:RegisterImportantAura(self.spells.REGROWTH, 80, true, false)
    WR.Auras:RegisterImportantAura(self.spells.LIFEBLOOM, 90, true, false)
    WR.Auras:RegisterImportantAura(self.spells.WILD_GROWTH, 85, true, false)
    WR.Auras:RegisterImportantAura(self.spells.CENARION_WARD, 80, true, false)
    WR.Auras:RegisterImportantAura(self.spells.INCARNATION_TREE_OF_LIFE, 95, true, false)
    WR.Auras:RegisterImportantAura(self.spells.EFFLORESCENCE, 80, true, false)
    
    -- Define Restoration combat rotation (for solo content)
    -- Note: Since Restoration is primarily a healer, actual implementation would focus on healing logic
    -- For combat/damage situations, we'll create a simple DPS rotation for solo content
    
    self.singleTargetRotation = {
        -- Apply DoTs
        {
            spell = self.spells.MOONFIRE,
            condition = function(self)
                return not self:HasDebuff(self.spells.MOONFIRE) or
                       self:GetDebuffRemaining(self.spells.MOONFIRE) < 4.5
            end
        },
        {
            spell = self.spells.SUNFIRE,
            condition = function(self)
                return not self:HasDebuff(self.spells.SUNFIRE) or
                       self:GetDebuffRemaining(self.spells.SUNFIRE) < 4.5
            end
        },
        
        -- Use covenant abilities
        { 
            spell = self.spells.CONVOKE_THE_SPIRITS,
            condition = function(self) return IsSpellKnown(self.spells.CONVOKE_THE_SPIRITS) end
        },
        { 
            spell = self.spells.ADAPTIVE_SWARM,
            condition = function(self) return IsSpellKnown(self.spells.ADAPTIVE_SWARM) end
        },
        
        -- Use Incarnation: Tree of Life (though primarily for healing)
        {
            spell = self.spells.INCARNATION_TREE_OF_LIFE,
            condition = function(self)
                return IsSpellKnown(self.spells.INCARNATION_TREE_OF_LIFE) and
                       self:GetHealthPct() < 50
            end
        },
        
        -- Self-heal if needed
        {
            spell = self.spells.SWIFTMEND,
            condition = function(self)
                return self:GetHealthPct() < 60 and
                       (self:HasBuff(self.spells.REGROWTH) or self:HasBuff(self.spells.REJUVENATION))
            end
        },
        {
            spell = self.spells.REGROWTH,
            condition = function(self)
                return self:GetHealthPct() < 70
            end
        },
        {
            spell = self.spells.CENARION_WARD,
            condition = function(self)
                return IsSpellKnown(self.spells.CENARION_WARD) and
                       self:GetHealthPct() < 90
            end
        },
        
        -- Use Wrath as main damage spell
        { spell = self.spells.WRATH }
    }
    
    -- AoE rotation for Restoration
    self.aoeRotation = {
        -- Apply DoTs to primary target
        {
            spell = self.spells.MOONFIRE,
            condition = function(self)
                return not self:HasDebuff(self.spells.MOONFIRE) or
                       self:GetDebuffRemaining(self.spells.MOONFIRE) < 4.5
            end
        },
        {
            spell = self.spells.SUNFIRE,
            condition = function(self)
                return not self:HasDebuff(self.spells.SUNFIRE) or
                       self:GetDebuffRemaining(self.spells.SUNFIRE) < 4.5
            end
        },
        
        -- Use covenant abilities
        { 
            spell = self.spells.CONVOKE_THE_SPIRITS,
            condition = function(self) return IsSpellKnown(self.spells.CONVOKE_THE_SPIRITS) end
        },
        { 
            spell = self.spells.ADAPTIVE_SWARM,
            condition = function(self) return IsSpellKnown(self.spells.ADAPTIVE_SWARM) end
        },
        
        -- Self-heal if needed
        {
            spell = self.spells.WILD_GROWTH,
            condition = function(self)
                return self:GetHealthPct() < 75
            end
        },
        {
            spell = self.spells.SWIFTMEND,
            condition = function(self)
                return self:GetHealthPct() < 50 and
                       (self:HasBuff(self.spells.REGROWTH) or self:HasBuff(self.spells.REJUVENATION))
            end
        },
        
        -- Use Starfall for AoE if Balance Affinity
        {
            spell = self.spells.STARFALL,
            condition = function(self)
                return IsSpellKnown(self.spells.STARFALL) and
                       self:GetEnemyCount(8) >= 3
            end
        },
        
        -- Use Sunfire for AoE
        { spell = self.spells.SUNFIRE },
        
        -- Use Wrath as filler
        { spell = self.spells.WRATH }
    }
    
    -- Define Restoration burst rotation
    self.burstRotation = {
        {
            spell = self.spells.INCARNATION_TREE_OF_LIFE,
            condition = function(self)
                return IsSpellKnown(self.spells.INCARNATION_TREE_OF_LIFE)
            end
        },
        { 
            spell = self.spells.CONVOKE_THE_SPIRITS,
            condition = function(self) return IsSpellKnown(self.spells.CONVOKE_THE_SPIRITS) end
        },
        { 
            spell = self.spells.RAVENOUS_FRENZY,
            condition = function(self) return IsSpellKnown(self.spells.RAVENOUS_FRENZY) end
        },
        {
            spell = self.spells.CELESTIAL_ALIGNMENT,
            condition = function(self) return IsSpellKnown(self.spells.CELESTIAL_ALIGNMENT) end
        }
    }
    
    -- Add Restoration-specific defensive abilities
    table.insert(self.defensiveRotation, {
        spell = self.spells.BARKSKIN,
        threshold = 70
    })
    
    table.insert(self.defensiveRotation, {
        spell = self.spells.IRONBARK,
        threshold = 40,
        targets = { "player" } -- In a real setting, this could target other party members
    })
end

-- Class-specific pre-rotation checks
function Druid:ClassSpecificChecks()
    -- Check for class-specific conditions
    
    -- Check for Mark of the Wild buff
    if not self:HasBuff(self.spells.MARK_OF_THE_WILD) and 
       not self:SpellOnCooldown(self.spells.MARK_OF_THE_WILD) then
        WR.Queue:Add(self.spells.MARK_OF_THE_WILD)
        return false
    end
    
    -- For Balance, ensure Moonkin Form is active
    if self.currentSpec == SPEC_BALANCE and 
       not self:HasBuff(self.spells.MOONKIN_FORM) and
       not self:SpellOnCooldown(self.spells.MOONKIN_FORM) then
        WR.Queue:Add(self.spells.MOONKIN_FORM)
        return false
    end
    
    -- For Feral, ensure Cat Form is active
    if self.currentSpec == SPEC_FERAL and 
       not self:HasBuff(self.spells.CAT_FORM) and
       not self:SpellOnCooldown(self.spells.CAT_FORM) then
        WR.Queue:Add(self.spells.CAT_FORM)
        return false
    end
    
    -- For Guardian, ensure Bear Form is active
    if self.currentSpec == SPEC_GUARDIAN and 
       not self:HasBuff(self.spells.BEAR_FORM) and
       not self:SpellOnCooldown(self.spells.BEAR_FORM) then
        WR.Queue:Add(self.spells.BEAR_FORM)
        return false
    end
    
    return true
end

-- Get default action when nothing else is available
function Druid:GetDefaultAction()
    if self.currentSpec == SPEC_BALANCE then
        return self.spells.WRATH
    elseif self.currentSpec == SPEC_FERAL then
        return self.spells.SHRED
    elseif self.currentSpec == SPEC_GUARDIAN then
        return self.spells.SWIPE_BEAR
    elseif self.currentSpec == SPEC_RESTORATION then
        return self.spells.WRATH
    end
    
    return nil
end

-- Initialize the module
Druid:Initialize()

return Druid