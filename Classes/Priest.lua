local addonName, WR = ...

-- Priest Class module
local Priest = {}
WR.Classes = WR.Classes or {}
WR.Classes.PRIEST = Priest

-- Inherit from BaseClass
setmetatable(Priest, {__index = WR.BaseClass})

-- Resource type for priests (mana primary, insanity for shadow)
Priest.resourceType = Enum.PowerType.Mana
Priest.secondaryResourceType = Enum.PowerType.Insanity

-- Define spec IDs
local SPEC_DISCIPLINE = 256
local SPEC_HOLY = 257
local SPEC_SHADOW = 258

-- Class initialization
function Priest:Initialize()
    -- Inherit base initialization
    WR.BaseClass.Initialize(self)
    
    -- Register Specializations
    self:RegisterSpec(SPEC_DISCIPLINE, "Discipline")
    self:RegisterSpec(SPEC_HOLY, "Holy")
    self:RegisterSpec(SPEC_SHADOW, "Shadow")
    
    -- Shared spell IDs across all priest specs
    self.spells = {
        -- Common priest abilities
        POWER_WORD_SHIELD = 17,
        POWER_WORD_FORTITUDE = 21562,
        DESPERATE_PRAYER = 19236,
        FLASH_HEAL = 2061,
        SHADOW_WORD_DEATH = 32379,
        FADE = 586,
        DISPEL_MAGIC = 528,
        MASS_DISPEL = 32375,
        PURIFY = 527,
        SHADOW_WORD_PAIN = 589,
        MIND_BLAST = 8092,
        PSYCHIC_SCREAM = 8122,
        LEAP_OF_FAITH = 73325,
        PAIN_SUPPRESSION = 33206,
        DIVINE_HYMN = 64843,
        GUARDIAN_SPIRIT = 47788,
        VAMPIRIC_EMBRACE = 15286,
        SHADOWFIEND = 34433,
        MINDBENDER = 123040,
        SHACKLE_UNDEAD = 9484,
        HOLY_NOVA = 132157,
        MASS_RESURRECTION = 212036,
        
        -- Covenant abilities
        UNHOLY_NOVA = 324724,      -- Necrolord
        MINDGAMES = 323673,        -- Venthyr
        FAE_GUARDIANS = 327661,    -- Night Fae
        BOON_OF_THE_ASCENDED = 325013, -- Kyrian
    }
    
    -- Load shared priest data
    self:LoadSharedPriestData()
    
    WR:Debug("Priest module initialized")
end

-- Load shared spell and mechanics data for all priest specs
function Priest:LoadSharedPriestData()
    -- Register important buffs
    WR.Auras:RegisterImportantAura(self.spells.POWER_WORD_FORTITUDE, 60, true, false)
    WR.Auras:RegisterImportantAura(self.spells.POWER_WORD_SHIELD, 85, true, false)
    WR.Auras:RegisterImportantAura(self.spells.SHADOW_WORD_PAIN, 75, false, true)
    
    -- Setup cooldown tracking
    WR.Cooldown:StartTracking(self.spells.DESPERATE_PRAYER)
    WR.Cooldown:StartTracking(self.spells.FADE)
    WR.Cooldown:StartTracking(self.spells.DISPEL_MAGIC)
    WR.Cooldown:StartTracking(self.spells.MASS_DISPEL)
    WR.Cooldown:StartTracking(self.spells.PURIFY)
    WR.Cooldown:StartTracking(self.spells.PSYCHIC_SCREAM)
    WR.Cooldown:StartTracking(self.spells.LEAP_OF_FAITH)
    WR.Cooldown:StartTracking(self.spells.PAIN_SUPPRESSION)
    WR.Cooldown:StartTracking(self.spells.DIVINE_HYMN)
    WR.Cooldown:StartTracking(self.spells.GUARDIAN_SPIRIT)
    WR.Cooldown:StartTracking(self.spells.VAMPIRIC_EMBRACE)
    WR.Cooldown:StartTracking(self.spells.SHADOWFIEND)
    WR.Cooldown:StartTracking(self.spells.MINDBENDER)
    
    -- Set up defensive rotation (shared by all specs)
    self.defensiveRotation = {
        { spell = self.spells.DESPERATE_PRAYER, threshold = 40 },
        { spell = self.spells.FADE, threshold = 50 }
    }
end

-- Load a specific specialization
function Priest:LoadSpec(specId)
    -- Call the base class method to set up common components
    WR.BaseClass.LoadSpec(self, specId)
    
    -- Set the resource type based on spec
    if specId == SPEC_SHADOW then
        self.resourceType = Enum.PowerType.Insanity
        self.secondaryResourceType = nil
    else
        self.resourceType = Enum.PowerType.Mana
        self.secondaryResourceType = nil
    end
    
    -- Load specific spec data
    if specId == SPEC_DISCIPLINE then
        self:LoadDisciplineSpec()
    elseif specId == SPEC_HOLY then
        self:LoadHolySpec()
    elseif specId == SPEC_SHADOW then
        self:LoadShadowSpec()
    end
    
    WR:Debug("Loaded priest spec:", self.specData.name)
    return true
end

-- Load Discipline specialization
function Priest:LoadDisciplineSpec()
    -- Discipline-specific spells
    self.spells.PENANCE = 47540
    self.spells.POWER_WORD_RADIANCE = 194509
    self.spells.RAPTURE = 47536
    self.spells.SHADOW_MEND = 186263
    self.spells.SCHISM = 214621
    self.spells.EVANGELISM = 246287
    self.spells.SPIRIT_SHELL = 109964
    self.spells.LUMINOUS_BARRIER = 271466
    self.spells.POWER_WORD_BARRIER = 62618
    self.spells.POWER_WORD_SOLACE = 129250
    self.spells.SMITE = 585
    self.spells.MIND_CONTROL = 605
    self.spells.ATONEMENT = 194384
    self.spells.DIVINE_STAR = 110744
    self.spells.HALO = 120517
    self.spells.SHADOWFIEND = 34433
    self.spells.LIGHTS_WRATH = 373178
    self.spells.SHADOW_COVENANT = 314867
    
    -- Setup cooldown and aura tracking for Discipline
    WR.Cooldown:StartTracking(self.spells.PENANCE)
    WR.Cooldown:StartTracking(self.spells.POWER_WORD_RADIANCE)
    WR.Cooldown:StartTracking(self.spells.RAPTURE)
    WR.Cooldown:StartTracking(self.spells.SCHISM)
    WR.Cooldown:StartTracking(self.spells.EVANGELISM)
    WR.Cooldown:StartTracking(self.spells.SPIRIT_SHELL)
    WR.Cooldown:StartTracking(self.spells.POWER_WORD_BARRIER)
    WR.Cooldown:StartTracking(self.spells.POWER_WORD_SOLACE)
    
    -- Track important buffs/debuffs
    WR.Auras:RegisterImportantAura(self.spells.ATONEMENT, 90, true, false)
    WR.Auras:RegisterImportantAura(self.spells.SCHISM, 80, false, true)
    WR.Auras:RegisterImportantAura(self.spells.RAPTURE, 85, true, false)
    WR.Auras:RegisterImportantAura(self.spells.SPIRIT_SHELL, 90, true, false)
    
    -- Define Discipline healer rotation
    -- Note: Since Discipline is primarily a healer, actual implementation would focus on healing logic
    -- For combat/damage situations, we'll create a simple DPS rotation for solo content
    
    self.singleTargetRotation = {
        -- Apply Schism for increased damage (and healing via Atonement)
        {
            spell = self.spells.SCHISM,
            condition = function(self)
                return IsSpellKnown(self.spells.SCHISM) and
                       not self:HasDebuff(self.spells.SCHISM)
            end
        },
        
        -- Apply Shadow Word: Pain for DoT damage
        {
            spell = self.spells.SHADOW_WORD_PAIN,
            condition = function(self)
                return not self:HasDebuff(self.spells.SHADOW_WORD_PAIN)
            end
        },
        
        -- Use covenant abilities
        { 
            spell = self.spells.MINDGAMES,
            condition = function(self) return IsSpellKnown(self.spells.MINDGAMES) end
        },
        { 
            spell = self.spells.UNHOLY_NOVA,
            condition = function(self) return IsSpellKnown(self.spells.UNHOLY_NOVA) end
        },
        { 
            spell = self.spells.FAE_GUARDIANS,
            condition = function(self) return IsSpellKnown(self.spells.FAE_GUARDIANS) end
        },
        { 
            spell = self.spells.BOON_OF_THE_ASCENDED,
            condition = function(self) return IsSpellKnown(self.spells.BOON_OF_THE_ASCENDED) end
        },
        
        -- Use Shadowfiend/Mindbender for damage and mana
        {
            spell = self.spells.MINDBENDER,
            condition = function(self)
                return IsSpellKnown(self.spells.MINDBENDER)
            end
        },
        {
            spell = self.spells.SHADOWFIEND,
            condition = function(self)
                return not IsSpellKnown(self.spells.MINDBENDER)
            end
        },
        
        -- Use Power Word: Solace for damage and mana
        {
            spell = self.spells.POWER_WORD_SOLACE,
            condition = function(self)
                return IsSpellKnown(self.spells.POWER_WORD_SOLACE)
            end
        },
        
        -- Use Shadow Word: Death as a finisher in execute range
        {
            spell = self.spells.SHADOW_WORD_DEATH,
            condition = function(self)
                return self:TargetInExecuteRange()
            end
        },
        
        -- Use Light's Wrath for burst damage
        {
            spell = self.spells.LIGHTS_WRATH,
            condition = function(self)
                return IsSpellKnown(self.spells.LIGHTS_WRATH)
            end
        },
        
        -- Use Penance for damage
        { spell = self.spells.PENANCE },
        
        -- Use Divine Star if talented
        {
            spell = self.spells.DIVINE_STAR,
            condition = function(self)
                return IsSpellKnown(self.spells.DIVINE_STAR)
            end
        },
        
        -- Use Halo if talented
        {
            spell = self.spells.HALO,
            condition = function(self)
                return IsSpellKnown(self.spells.HALO)
            end
        },
        
        -- Use Smite as filler
        { spell = self.spells.SMITE }
    }
    
    -- AoE rotation for Discipline
    self.aoeRotation = {
        -- Apply Shadow Word: Pain to multiple targets if possible
        {
            spell = self.spells.SHADOW_WORD_PAIN,
            condition = function(self)
                return not self:HasDebuff(self.spells.SHADOW_WORD_PAIN)
            end
        },
        
        -- Use covenant abilities
        { 
            spell = self.spells.UNHOLY_NOVA,
            condition = function(self) return IsSpellKnown(self.spells.UNHOLY_NOVA) end
        },
        { 
            spell = self.spells.BOON_OF_THE_ASCENDED,
            condition = function(self) return IsSpellKnown(self.spells.BOON_OF_THE_ASCENDED) end
        },
        
        -- Use Divine Star for AoE damage
        {
            spell = self.spells.DIVINE_STAR,
            condition = function(self)
                return IsSpellKnown(self.spells.DIVINE_STAR)
            end
        },
        
        -- Use Halo for AoE damage
        {
            spell = self.spells.HALO,
            condition = function(self)
                return IsSpellKnown(self.spells.HALO)
            end
        },
        
        -- Use Holy Nova for AoE damage
        { spell = self.spells.HOLY_NOVA },
        
        -- Use Power Word: Solace for single target damage and mana
        {
            spell = self.spells.POWER_WORD_SOLACE,
            condition = function(self)
                return IsSpellKnown(self.spells.POWER_WORD_SOLACE)
            end
        },
        
        -- Use Penance for damage
        { spell = self.spells.PENANCE }
    }
    
    -- Define burst rotation
    self.burstRotation = {
        {
            spell = self.spells.SCHISM,
            condition = function(self) return IsSpellKnown(self.spells.SCHISM) end
        },
        { 
            spell = self.spells.MINDGAMES,
            condition = function(self) return IsSpellKnown(self.spells.MINDGAMES) end
        },
        { 
            spell = self.spells.UNHOLY_NOVA,
            condition = function(self) return IsSpellKnown(self.spells.UNHOLY_NOVA) end
        },
        { 
            spell = self.spells.BOON_OF_THE_ASCENDED,
            condition = function(self) return IsSpellKnown(self.spells.BOON_OF_THE_ASCENDED) end
        },
        {
            spell = self.spells.MINDBENDER,
            condition = function(self) return IsSpellKnown(self.spells.MINDBENDER) end
        },
        {
            spell = self.spells.SHADOWFIEND,
            condition = function(self) return not IsSpellKnown(self.spells.MINDBENDER) end
        },
        {
            spell = self.spells.LIGHTS_WRATH,
            condition = function(self) return IsSpellKnown(self.spells.LIGHTS_WRATH) end
        }
    }
    
    -- Add Discipline-specific defensive abilities
    table.insert(self.defensiveRotation, {
        spell = self.spells.PAIN_SUPPRESSION,
        threshold = 25
    })
    
    table.insert(self.defensiveRotation, {
        spell = self.spells.POWER_WORD_BARRIER,
        condition = function(self)
            -- In a real setting, this would check for group damage scenarios
            return self:GetHealthPct() < 35
        end
    })
end

-- Load Holy specialization
function Priest:LoadHolySpec()
    -- Holy-specific spells
    self.spells.HEAL = 2060
    self.spells.PRAYER_OF_HEALING = 596
    self.spells.PRAYER_OF_MENDING = 33076
    self.spells.RENEW = 139
    self.spells.HOLY_WORD_SERENITY = 2050
    self.spells.HOLY_WORD_SANCTIFY = 34861
    self.spells.HOLY_WORD_CHASTISE = 88625
    self.spells.HOLY_WORD_SALVATION = 265202
    self.spells.HOLY_FIRE = 14914
    self.spells.SMITE = 585
    self.spells.CIRCLE_OF_HEALING = 204883
    self.spells.DIVINE_HYMN = 64843
    self.spells.SYMBOL_OF_HOPE = 64901
    self.spells.APOTHEOSIS = 200183
    self.spells.DIVINE_STAR = 110744
    self.spells.HALO = 120517
    self.spells.GUARDIAN_SPIRIT = 47788
    self.spells.BENEDICTION = 193157
    self.spells.SURGE_OF_LIGHT = 114255
    
    -- Setup cooldown and aura tracking for Holy
    WR.Cooldown:StartTracking(self.spells.HOLY_WORD_SERENITY)
    WR.Cooldown:StartTracking(self.spells.HOLY_WORD_SANCTIFY)
    WR.Cooldown:StartTracking(self.spells.HOLY_WORD_CHASTISE)
    WR.Cooldown:StartTracking(self.spells.HOLY_WORD_SALVATION)
    WR.Cooldown:StartTracking(self.spells.HOLY_FIRE)
    WR.Cooldown:StartTracking(self.spells.PRAYER_OF_MENDING)
    WR.Cooldown:StartTracking(self.spells.CIRCLE_OF_HEALING)
    WR.Cooldown:StartTracking(self.spells.DIVINE_HYMN)
    WR.Cooldown:StartTracking(self.spells.SYMBOL_OF_HOPE)
    WR.Cooldown:StartTracking(self.spells.APOTHEOSIS)
    WR.Cooldown:StartTracking(self.spells.GUARDIAN_SPIRIT)
    
    -- Track important buffs/debuffs
    WR.Auras:RegisterImportantAura(self.spells.RENEW, 80, true, false)
    WR.Auras:RegisterImportantAura(self.spells.PRAYER_OF_MENDING, 85, true, false)
    WR.Auras:RegisterImportantAura(self.spells.APOTHEOSIS, 90, true, false)
    WR.Auras:RegisterImportantAura(self.spells.SURGE_OF_LIGHT, 75, true, false)
    
    -- Define Holy DPS rotation (for solo content)
    self.singleTargetRotation = {
        -- Apply Holy Fire for DoT damage
        {
            spell = self.spells.HOLY_FIRE,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.HOLY_FIRE)
            end
        },
        
        -- Apply Shadow Word: Pain for additional DoT damage
        {
            spell = self.spells.SHADOW_WORD_PAIN,
            condition = function(self)
                return not self:HasDebuff(self.spells.SHADOW_WORD_PAIN)
            end
        },
        
        -- Use covenant abilities
        { 
            spell = self.spells.MINDGAMES,
            condition = function(self) return IsSpellKnown(self.spells.MINDGAMES) end
        },
        { 
            spell = self.spells.UNHOLY_NOVA,
            condition = function(self) return IsSpellKnown(self.spells.UNHOLY_NOVA) end
        },
        { 
            spell = self.spells.FAE_GUARDIANS,
            condition = function(self) return IsSpellKnown(self.spells.FAE_GUARDIANS) end
        },
        { 
            spell = self.spells.BOON_OF_THE_ASCENDED,
            condition = function(self) return IsSpellKnown(self.spells.BOON_OF_THE_ASCENDED) end
        },
        
        -- Use Holy Word: Chastise for damage and stun
        { spell = self.spells.HOLY_WORD_CHASTISE },
        
        -- Use Shadow Word: Death as a finisher in execute range
        {
            spell = self.spells.SHADOW_WORD_DEATH,
            condition = function(self)
                return self:TargetInExecuteRange()
            end
        },
        
        -- Use Divine Star if talented
        {
            spell = self.spells.DIVINE_STAR,
            condition = function(self)
                return IsSpellKnown(self.spells.DIVINE_STAR)
            end
        },
        
        -- Use Halo if talented
        {
            spell = self.spells.HALO,
            condition = function(self)
                return IsSpellKnown(self.spells.HALO)
            end
        },
        
        -- Use Smite as filler
        { spell = self.spells.SMITE }
    }
    
    -- AoE rotation for Holy
    self.aoeRotation = {
        -- Apply Holy Fire for primary target DoT damage
        {
            spell = self.spells.HOLY_FIRE,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.HOLY_FIRE)
            end
        },
        
        -- Apply Shadow Word: Pain to multiple targets if possible
        {
            spell = self.spells.SHADOW_WORD_PAIN,
            condition = function(self)
                return not self:HasDebuff(self.spells.SHADOW_WORD_PAIN)
            end
        },
        
        -- Use covenant abilities
        { 
            spell = self.spells.UNHOLY_NOVA,
            condition = function(self) return IsSpellKnown(self.spells.UNHOLY_NOVA) end
        },
        { 
            spell = self.spells.BOON_OF_THE_ASCENDED,
            condition = function(self) return IsSpellKnown(self.spells.BOON_OF_THE_ASCENDED) end
        },
        
        -- Use Divine Star for AoE damage
        {
            spell = self.spells.DIVINE_STAR,
            condition = function(self)
                return IsSpellKnown(self.spells.DIVINE_STAR)
            end
        },
        
        -- Use Halo for AoE damage
        {
            spell = self.spells.HALO,
            condition = function(self)
                return IsSpellKnown(self.spells.HALO)
            end
        },
        
        -- Use Holy Nova for AoE damage
        { spell = self.spells.HOLY_NOVA },
        
        -- Use Holy Word: Chastise for single target damage
        { spell = self.spells.HOLY_WORD_CHASTISE }
    }
    
    -- Define burst rotation
    self.burstRotation = {
        {
            spell = self.spells.APOTHEOSIS,
            condition = function(self) return IsSpellKnown(self.spells.APOTHEOSIS) end
        },
        { 
            spell = self.spells.MINDGAMES,
            condition = function(self) return IsSpellKnown(self.spells.MINDGAMES) end
        },
        { 
            spell = self.spells.UNHOLY_NOVA,
            condition = function(self) return IsSpellKnown(self.spells.UNHOLY_NOVA) end
        },
        { 
            spell = self.spells.BOON_OF_THE_ASCENDED,
            condition = function(self) return IsSpellKnown(self.spells.BOON_OF_THE_ASCENDED) end
        },
        { spell = self.spells.HOLY_WORD_CHASTISE }
    }
    
    -- Add Holy-specific defensive abilities
    table.insert(self.defensiveRotation, {
        spell = self.spells.GUARDIAN_SPIRIT,
        threshold = 20
    })
    
    table.insert(self.defensiveRotation, {
        spell = self.spells.DIVINE_HYMN,
        condition = function(self)
            -- In a real setting, this would check for group damage scenarios
            return self:GetHealthPct() < 30
        end
    })
end

-- Load Shadow specialization
function Priest:LoadShadowSpec()
    -- Shadow-specific spells
    self.spells.MIND_FLAY = 15407
    self.spells.MIND_SEAR = 48045
    self.spells.MIND_BLAST = 8092
    self.spells.VOID_ERUPTION = 228260
    self.spells.VOID_BOLT = 205448
    self.spells.DEVOURING_PLAGUE = 335467
    self.spells.SHADOW_CRASH = 205385
    self.spells.VAMPIRIC_TOUCH = 34914
    self.spells.DISPERSION = 47585
    self.spells.SILENCE = 15487
    self.spells.PSYCHIC_HORROR = 64044
    self.spells.SEARING_NIGHTMARE = 341385
    self.spells.DARK_ASCENSION = 391109
    self.spells.DARK_VOID = 263346
    self.spells.SHADOWFORM = 232698
    self.spells.VOIDFORM = 194249
    self.spells.DESPERATE_PRAYER = 19236
    self.spells.VOID_ERUPTION = 228260
    self.spells.DARK_THOUGHT = 341207
    self.spells.SHADOWY_APPARITION = 78203
    
    -- Setup cooldown and aura tracking for Shadow
    WR.Cooldown:StartTracking(self.spells.MIND_BLAST)
    WR.Cooldown:StartTracking(self.spells.VOID_ERUPTION)
    WR.Cooldown:StartTracking(self.spells.SHADOW_CRASH)
    WR.Cooldown:StartTracking(self.spells.DISPERSION)
    WR.Cooldown:StartTracking(self.spells.SILENCE)
    WR.Cooldown:StartTracking(self.spells.PSYCHIC_HORROR)
    WR.Cooldown:StartTracking(self.spells.DARK_ASCENSION)
    WR.Cooldown:StartTracking(self.spells.DARK_VOID)
    
    -- Track important buffs/debuffs
    WR.Auras:RegisterImportantAura(self.spells.SHADOWFORM, 90, true, false)
    WR.Auras:RegisterImportantAura(self.spells.VOIDFORM, 95, true, false)
    WR.Auras:RegisterImportantAura(self.spells.VAMPIRIC_TOUCH, 85, false, true)
    WR.Auras:RegisterImportantAura(self.spells.SHADOW_WORD_PAIN, 80, false, true)
    WR.Auras:RegisterImportantAura(self.spells.DEVOURING_PLAGUE, 90, false, true)
    WR.Auras:RegisterImportantAura(self.spells.DARK_THOUGHT, 75, true, false)
    
    -- Set interrupt ability
    self.interruptRotation = {
        { spell = self.spells.SILENCE }
    }
    
    -- Define Shadow single target rotation
    self.singleTargetRotation = {
        -- Maintain Shadowform
        {
            spell = self.spells.SHADOWFORM,
            condition = function(self)
                return not self:HasBuff(self.spells.SHADOWFORM) and 
                       not self:HasBuff(self.spells.VOIDFORM)
            end
        },
        
        -- Use Void Eruption to enter Voidform
        {
            spell = self.spells.VOID_ERUPTION,
            condition = function(self)
                return self:GetResource() >= 50
            end
        },
        
        -- Use Dark Ascension if talented
        {
            spell = self.spells.DARK_ASCENSION,
            condition = function(self)
                return IsSpellKnown(self.spells.DARK_ASCENSION) and
                       self:GetResource() >= 30
            end
        },
        
        -- Apply DoTs with pandemic refresh
        {
            spell = self.spells.SHADOW_WORD_PAIN,
            condition = function(self)
                return not self:HasDebuff(self.spells.SHADOW_WORD_PAIN) or
                       self:GetDebuffRemaining(self.spells.SHADOW_WORD_PAIN) < 4.5
            end
        },
        {
            spell = self.spells.VAMPIRIC_TOUCH,
            condition = function(self)
                return not self:HasDebuff(self.spells.VAMPIRIC_TOUCH) or
                       self:GetDebuffRemaining(self.spells.VAMPIRIC_TOUCH) < 6.3
            end
        },
        
        -- Use covenant abilities
        { 
            spell = self.spells.MINDGAMES,
            condition = function(self) return IsSpellKnown(self.spells.MINDGAMES) end
        },
        { 
            spell = self.spells.UNHOLY_NOVA,
            condition = function(self) return IsSpellKnown(self.spells.UNHOLY_NOVA) end
        },
        { 
            spell = self.spells.FAE_GUARDIANS,
            condition = function(self) return IsSpellKnown(self.spells.FAE_GUARDIANS) end
        },
        { 
            spell = self.spells.BOON_OF_THE_ASCENDED,
            condition = function(self) return IsSpellKnown(self.spells.BOON_OF_THE_ASCENDED) end
        },
        
        -- Use Void Bolt in Voidform
        {
            spell = self.spells.VOID_BOLT,
            condition = function(self)
                return self:HasBuff(self.spells.VOIDFORM)
            end
        },
        
        -- Use Devouring Plague to spend Insanity
        {
            spell = self.spells.DEVOURING_PLAGUE,
            condition = function(self)
                return self:GetResource() >= 50 and
                       (not self:HasDebuff(self.spells.DEVOURING_PLAGUE) or
                        self:GetDebuffRemaining(self.spells.DEVOURING_PLAGUE) < 1.5)
            end
        },
        
        -- Use Shadow Word: Death in execute range
        {
            spell = self.spells.SHADOW_WORD_DEATH,
            condition = function(self)
                return self:TargetInExecuteRange()
            end
        },
        
        -- Use Mind Blast on cooldown
        {
            spell = self.spells.MIND_BLAST,
            condition = function(self)
                local darkThought = self:HasBuff(self.spells.DARK_THOUGHT)
                return not self:SpellOnCooldown(self.spells.MIND_BLAST) or darkThought
            end
        },
        
        -- Use Shadow Crash if talented
        {
            spell = self.spells.SHADOW_CRASH,
            condition = function(self)
                return IsSpellKnown(self.spells.SHADOW_CRASH)
            end
        },
        
        -- Use Shadowfiend/Mindbender for damage and insanity
        {
            spell = self.spells.MINDBENDER,
            condition = function(self)
                return IsSpellKnown(self.spells.MINDBENDER)
            end
        },
        {
            spell = self.spells.SHADOWFIEND,
            condition = function(self)
                return not IsSpellKnown(self.spells.MINDBENDER)
            end
        },
        
        -- Use Mind Flay as filler
        { spell = self.spells.MIND_FLAY }
    }
    
    -- AoE rotation for Shadow
    self.aoeRotation = {
        -- Maintain Shadowform
        {
            spell = self.spells.SHADOWFORM,
            condition = function(self)
                return not self:HasBuff(self.spells.SHADOWFORM) and 
                       not self:HasBuff(self.spells.VOIDFORM)
            end
        },
        
        -- Use Void Eruption to enter Voidform
        {
            spell = self.spells.VOID_ERUPTION,
            condition = function(self)
                return self:GetResource() >= 50
            end
        },
        
        -- Use Dark Void if talented
        {
            spell = self.spells.DARK_VOID,
            condition = function(self)
                return IsSpellKnown(self.spells.DARK_VOID)
            end
        },
        
        -- Apply Vampiric Touch to primary target
        {
            spell = self.spells.VAMPIRIC_TOUCH,
            condition = function(self)
                return not self:HasDebuff(self.spells.VAMPIRIC_TOUCH) or
                       self:GetDebuffRemaining(self.spells.VAMPIRIC_TOUCH) < 6.3
            end
        },
        
        -- Use covenant abilities
        { 
            spell = self.spells.UNHOLY_NOVA,
            condition = function(self) return IsSpellKnown(self.spells.UNHOLY_NOVA) end
        },
        { 
            spell = self.spells.BOON_OF_THE_ASCENDED,
            condition = function(self) return IsSpellKnown(self.spells.BOON_OF_THE_ASCENDED) end
        },
        
        -- Use Void Bolt in Voidform
        {
            spell = self.spells.VOID_BOLT,
            condition = function(self)
                return self:HasBuff(self.spells.VOIDFORM)
            end
        },
        
        -- Use Shadow Crash for AoE
        {
            spell = self.spells.SHADOW_CRASH,
            condition = function(self)
                return IsSpellKnown(self.spells.SHADOW_CRASH)
            end
        },
        
        -- Use Searing Nightmare with Mind Sear for AoE
        {
            spell = self.spells.SEARING_NIGHTMARE,
            condition = function(self)
                return IsSpellKnown(self.spells.SEARING_NIGHTMARE) and
                       self:GetResource() >= 30 and
                       self:GetEnemyCount(8) >= 3
            end
        },
        
        -- Use Devouring Plague in priority target
        {
            spell = self.spells.DEVOURING_PLAGUE,
            condition = function(self)
                return self:GetResource() >= 50
            end
        },
        
        -- Use Mind Sear as AoE filler
        {
            spell = self.spells.MIND_SEAR,
            condition = function(self)
                return self:GetEnemyCount(8) >= 3
            end
        },
        
        -- Fallback to single target rotation
        {
            spell = self.spells.MIND_BLAST,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.MIND_BLAST)
            end
        },
        
        -- Use Mind Flay as filler for lower AoE
        { spell = self.spells.MIND_FLAY }
    }
    
    -- Define burst rotation
    self.burstRotation = {
        {
            spell = self.spells.SHADOWFORM,
            condition = function(self)
                return not self:HasBuff(self.spells.SHADOWFORM) and 
                       not self:HasBuff(self.spells.VOIDFORM)
            end
        },
        {
            spell = self.spells.VOID_ERUPTION,
            condition = function(self) return self:GetResource() >= 50 end
        },
        {
            spell = self.spells.DARK_ASCENSION,
            condition = function(self) 
                return IsSpellKnown(self.spells.DARK_ASCENSION) and
                       self:GetResource() >= 30
            end
        },
        { 
            spell = self.spells.MINDGAMES,
            condition = function(self) return IsSpellKnown(self.spells.MINDGAMES) end
        },
        { 
            spell = self.spells.UNHOLY_NOVA,
            condition = function(self) return IsSpellKnown(self.spells.UNHOLY_NOVA) end
        },
        { 
            spell = self.spells.BOON_OF_THE_ASCENDED,
            condition = function(self) return IsSpellKnown(self.spells.BOON_OF_THE_ASCENDED) end
        },
        {
            spell = self.spells.MINDBENDER,
            condition = function(self) return IsSpellKnown(self.spells.MINDBENDER) end
        },
        {
            spell = self.spells.SHADOWFIEND,
            condition = function(self) return not IsSpellKnown(self.spells.MINDBENDER) end
        }
    }
    
    -- Add Shadow-specific defensive abilities
    table.insert(self.defensiveRotation, {
        spell = self.spells.DISPERSION,
        threshold = 15
    })
    
    table.insert(self.defensiveRotation, {
        spell = self.spells.VAMPIRIC_EMBRACE,
        condition = function(self)
            return self:GetHealthPct() < 50
        end
    })
end

-- Class-specific pre-rotation checks
function Priest:ClassSpecificChecks()
    -- Check for class-specific conditions
    
    -- Check for Power Word: Fortitude buff
    if not self:HasBuff(self.spells.POWER_WORD_FORTITUDE) and 
       not self:SpellOnCooldown(self.spells.POWER_WORD_FORTITUDE) then
        WR.Queue:Add(self.spells.POWER_WORD_FORTITUDE)
        return false
    end
    
    -- For Shadow, ensure Shadowform is active
    if self.currentSpec == SPEC_SHADOW and 
       not self:HasBuff(self.spells.SHADOWFORM) and 
       not self:HasBuff(self.spells.VOIDFORM) and
       not self:SpellOnCooldown(self.spells.SHADOWFORM) then
        WR.Queue:Add(self.spells.SHADOWFORM)
        return false
    end
    
    -- For healing specs, ensure Power Word: Shield is used for protection
    if (self.currentSpec == SPEC_DISCIPLINE or self.currentSpec == SPEC_HOLY) and
       not self:HasBuff(self.spells.POWER_WORD_SHIELD) and
       not self:SpellOnCooldown(self.spells.POWER_WORD_SHIELD) then
        WR.Queue:Add(self.spells.POWER_WORD_SHIELD)
        return false
    end
    
    return true
end

-- Get default action when nothing else is available
function Priest:GetDefaultAction()
    if self.currentSpec == SPEC_DISCIPLINE then
        return self.spells.SMITE
    elseif self.currentSpec == SPEC_HOLY then
        return self.spells.SMITE
    elseif self.currentSpec == SPEC_SHADOW then
        return self.spells.MIND_FLAY
    end
    
    return nil
end

-- Initialize the module
Priest:Initialize()

return Priest