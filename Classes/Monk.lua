local addonName, WR = ...

-- Monk Class module
local Monk = {}
WR.Classes = WR.Classes or {}
WR.Classes.MONK = Monk

-- Inherit from BaseClass
setmetatable(Monk, {__index = WR.BaseClass})

-- Resource type for Monks (Energy/Mana/Chi/Brew)
Monk.resourceType = Enum.PowerType.Energy
Monk.secondaryResourceType = Enum.PowerType.Chi

-- Define spec IDs
local SPEC_BREWMASTER = 268
local SPEC_MISTWEAVER = 270
local SPEC_WINDWALKER = 269

-- Class initialization
function Monk:Initialize()
    -- Inherit base initialization
    WR.BaseClass.Initialize(self)
    
    -- Register Specializations
    self:RegisterSpec(SPEC_BREWMASTER, "Brewmaster")
    self:RegisterSpec(SPEC_MISTWEAVER, "Mistweaver")
    self:RegisterSpec(SPEC_WINDWALKER, "Windwalker")
    
    -- Shared spell IDs across all monk specs
    self.spells = {
        -- Core monk abilities
        TIGER_PALM = 100780,
        BLACKOUT_KICK = 100784,
        RISING_SUN_KICK = 107428,
        SPINNING_CRANE_KICK = 101546,
        ROLL = 109132,
        CHI_WAVE = 115098,
        TOUCH_OF_DEATH = 115080,
        RESUSCITATE = 115178,
        LEG_SWEEP = 119381,
        PARALYSIS = 115078,
        VIVIFY = 116670,
        DETOX = 218164,
        CRACKLING_JADE_LIGHTNING = 117952,
        ZEN_PILGRIMAGE = 126892,
        TRANSCENDENCE = 101643,
        TRANSCENDENCE_TRANSFER = 119996,
        FLYING_SERPENT_KICK = 101545,
        MYSTIC_TOUCH = 8647,
        FORTIFYING_BREW = 115203,
        CHI_TORPEDO = 115008,
        RING_OF_PEACE = 116844,
        
        -- Covenant abilities
        WEAPONS_OF_ORDER = 310454,    -- Kyrian
        FALLEN_ORDER = 326860,        -- Venthyr
        FAELINE_STOMP = 327104,       -- Night Fae
        BONEDUST_BREW = 325216        -- Necrolord
    }
    
    -- Load shared monk data
    self:LoadSharedMonkData()
    
    WR:Debug("Monk module initialized")
end

-- Load shared spell and mechanics data for all monk specs
function Monk:LoadSharedMonkData()
    -- Register important buffs
    WR.Auras:RegisterImportantAura(self.spells.FORTIFYING_BREW, 90, true, false)
    WR.Auras:RegisterImportantAura(self.spells.MYSTIC_TOUCH, 60, false, true)
    
    -- Setup cooldown tracking
    WR.Cooldown:StartTracking(self.spells.RISING_SUN_KICK)
    WR.Cooldown:StartTracking(self.spells.TOUCH_OF_DEATH)
    WR.Cooldown:StartTracking(self.spells.FORTIFYING_BREW)
    WR.Cooldown:StartTracking(self.spells.ROLL)
    WR.Cooldown:StartTracking(self.spells.CHI_TORPEDO)
    WR.Cooldown:StartTracking(self.spells.LEG_SWEEP)
    WR.Cooldown:StartTracking(self.spells.PARALYSIS)
    WR.Cooldown:StartTracking(self.spells.RING_OF_PEACE)
    WR.Cooldown:StartTracking(self.spells.TRANSCENDENCE)
    WR.Cooldown:StartTracking(self.spells.TRANSCENDENCE_TRANSFER)
    
    -- Set up defensive rotation (shared by all specs)
    self.defensiveRotation = {
        { spell = self.spells.FORTIFYING_BREW, threshold = 35 }
    }
end

-- Load a specific specialization
function Monk:LoadSpec(specId)
    -- Call the base class method to set up common components
    WR.BaseClass.LoadSpec(self, specId)
    
    -- Set the resource type based on spec
    if specId == SPEC_BREWMASTER then
        self.resourceType = Enum.PowerType.Energy
        self.secondaryResourceType = Enum.PowerType.Chi
    elseif specId == SPEC_MISTWEAVER then
        self.resourceType = Enum.PowerType.Mana
        self.secondaryResourceType = nil
    elseif specId == SPEC_WINDWALKER then
        self.resourceType = Enum.PowerType.Energy
        self.secondaryResourceType = Enum.PowerType.Chi
    end
    
    -- Load specific spec data
    if specId == SPEC_BREWMASTER then
        self:LoadBrewmasterSpec()
    elseif specId == SPEC_MISTWEAVER then
        self:LoadMistweaverSpec()
    elseif specId == SPEC_WINDWALKER then
        self:LoadWindwalkerSpec()
    end
    
    WR:Debug("Loaded monk spec:", self.specData.name)
    return true
end

-- Load Brewmaster specialization
function Monk:LoadBrewmasterSpec()
    -- Brewmaster-specific spells
    self.spells.KEG_SMASH = 121253
    self.spells.BREATH_OF_FIRE = 115181
    self.spells.PURIFYING_BREW = 119582
    self.spells.CELESTIAL_BREW = 322507
    self.spells.RUSHING_JADE_WIND = 116847
    self.spells.INVOKE_NIUZAO = 132578
    self.spells.ZEN_MEDITATION = 115176
    self.spells.GUARD = 115295
    self.spells.STAGGER = 115069
    self.spells.IRONSKIN_BREW = 115308
    self.spells.EXPEL_HARM = 322101
    self.spells.PROVOKE = 115546
    self.spells.SPEAR_HAND_STRIKE = 116705
    self.spells.BLACK_OX_BREW = 115399
    self.spells.SPECIAL_DELIVERY = 196730
    self.spells.HIGH_TOLERANCE = 196737
    self.spells.CELESTIAL_FORTUNE = 216519
    self.spells.SHUFFLE = 215479
    self.spells.LIGHT_BREWING = 196721
    self.spells.GIFT_OF_THE_OX = 124503
    self.spells.EXPLODING_KEG = 325153
    self.spells.CLASH = 324312
    
    -- Setup cooldown and aura tracking for Brewmaster
    WR.Cooldown:StartTracking(self.spells.KEG_SMASH)
    WR.Cooldown:StartTracking(self.spells.BREATH_OF_FIRE)
    WR.Cooldown:StartTracking(self.spells.PURIFYING_BREW)
    WR.Cooldown:StartTracking(self.spells.CELESTIAL_BREW)
    WR.Cooldown:StartTracking(self.spells.RUSHING_JADE_WIND)
    WR.Cooldown:StartTracking(self.spells.INVOKE_NIUZAO)
    WR.Cooldown:StartTracking(self.spells.ZEN_MEDITATION)
    WR.Cooldown:StartTracking(self.spells.EXPEL_HARM)
    WR.Cooldown:StartTracking(self.spells.PROVOKE)
    WR.Cooldown:StartTracking(self.spells.SPEAR_HAND_STRIKE)
    WR.Cooldown:StartTracking(self.spells.BLACK_OX_BREW)
    WR.Cooldown:StartTracking(self.spells.EXPLODING_KEG)
    WR.Cooldown:StartTracking(self.spells.CLASH)
    
    -- Track important buffs/debuffs
    WR.Auras:RegisterImportantAura(self.spells.SHUFFLE, 95, true, false)
    WR.Auras:RegisterImportantAura(self.spells.CELESTIAL_BREW, 90, true, false)
    WR.Auras:RegisterImportantAura(self.spells.BREATH_OF_FIRE, 85, false, true)
    WR.Auras:RegisterImportantAura(self.spells.RUSHING_JADE_WIND, 80, true, false)
    WR.Auras:RegisterImportantAura(self.spells.STAGGER, 90, true, false)
    
    -- Set interrupt ability
    self.interruptRotation = {
        { spell = self.spells.SPEAR_HAND_STRIKE }
    }
    
    -- Define Brewmaster single target rotation
    self.singleTargetRotation = {
        -- Use Purifying Brew when stagger is high
        {
            spell = self.spells.PURIFYING_BREW,
            condition = function(self)
                return self:GetStaggerPercent() > 60
            end
        },
        
        -- Use Celestial Brew for mitigation
        {
            spell = self.spells.CELESTIAL_BREW,
            condition = function(self)
                return not self:HasBuff(self.spells.CELESTIAL_BREW) and
                       self:GetHealthPct() < 80
            end
        },
        
        -- Use covenant abilities
        { 
            spell = self.spells.WEAPONS_OF_ORDER,
            condition = function(self) return IsSpellKnown(self.spells.WEAPONS_OF_ORDER) end
        },
        { 
            spell = self.spells.FALLEN_ORDER,
            condition = function(self) return IsSpellKnown(self.spells.FALLEN_ORDER) end
        },
        { 
            spell = self.spells.FAELINE_STOMP,
            condition = function(self) return IsSpellKnown(self.spells.FAELINE_STOMP) end
        },
        { 
            spell = self.spells.BONEDUST_BREW,
            condition = function(self) return IsSpellKnown(self.spells.BONEDUST_BREW) end
        },
        
        -- Use Keg Smash on cooldown
        {
            spell = self.spells.KEG_SMASH,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.KEG_SMASH)
            end
        },
        
        -- Use Breath of Fire when available
        {
            spell = self.spells.BREATH_OF_FIRE,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.BREATH_OF_FIRE)
            end
        },
        
        -- Use Black Ox Brew when low on brews
        {
            spell = self.spells.BLACK_OX_BREW,
            condition = function(self)
                return IsSpellKnown(self.spells.BLACK_OX_BREW) and
                       not self:SpellOnCooldown(self.spells.BLACK_OX_BREW) and
                       self:GetBrewStacks() < 1
            end
        },
        
        -- Use Rushing Jade Wind if talented
        {
            spell = self.spells.RUSHING_JADE_WIND,
            condition = function(self)
                return IsSpellKnown(self.spells.RUSHING_JADE_WIND) and
                       not self:HasBuff(self.spells.RUSHING_JADE_WIND)
            end
        },
        
        -- Use Expel Harm for healing
        {
            spell = self.spells.EXPEL_HARM,
            condition = function(self)
                return self:GetHealthPct() < 85 and
                       self:GetOrbCount() > 0
            end
        },
        
        -- Use Tiger Palm as filler
        {
            spell = self.spells.TIGER_PALM,
            condition = function(self)
                return self:GetEnergy() > 50
            end
        },
        
        -- Use Blackout Kick as Chi spender
        {
            spell = self.spells.BLACKOUT_KICK,
            condition = function(self)
                return self:GetChi() >= 1
            end
        },
        
        -- Use Touch of Death when target is low
        {
            spell = self.spells.TOUCH_OF_DEATH,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.TOUCH_OF_DEATH) and
                       self:IsTargetExecatable()
            end
        },
        
        -- Use Spinning Crane Kick for additional AoE
        {
            spell = self.spells.SPINNING_CRANE_KICK,
            condition = function(self)
                return self:GetEnemyCount(8) >= 3 and
                       self:GetEnergy() >= 40
            end
        }
    }
    
    -- AoE rotation for Brewmaster
    self.aoeRotation = {
        -- Use covenant abilities for AoE
        { 
            spell = self.spells.WEAPONS_OF_ORDER,
            condition = function(self) return IsSpellKnown(self.spells.WEAPONS_OF_ORDER) end
        },
        { 
            spell = self.spells.FALLEN_ORDER,
            condition = function(self) return IsSpellKnown(self.spells.FALLEN_ORDER) end
        },
        { 
            spell = self.spells.FAELINE_STOMP,
            condition = function(self) return IsSpellKnown(self.spells.FAELINE_STOMP) end
        },
        { 
            spell = self.spells.BONEDUST_BREW,
            condition = function(self) return IsSpellKnown(self.spells.BONEDUST_BREW) end
        },
        
        -- Use Exploding Keg for AoE threat and damage reduction
        {
            spell = self.spells.EXPLODING_KEG,
            condition = function(self)
                return IsSpellKnown(self.spells.EXPLODING_KEG) and
                       not self:SpellOnCooldown(self.spells.EXPLODING_KEG)
            end
        },
        
        -- Use Keg Smash for AoE threat and damage
        {
            spell = self.spells.KEG_SMASH,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.KEG_SMASH)
            end
        },
        
        -- Use Breath of Fire after Keg Smash
        {
            spell = self.spells.BREATH_OF_FIRE,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.BREATH_OF_FIRE)
            end
        },
        
        -- Use Rushing Jade Wind for AoE
        {
            spell = self.spells.RUSHING_JADE_WIND,
            condition = function(self)
                return IsSpellKnown(self.spells.RUSHING_JADE_WIND) and
                       not self:HasBuff(self.spells.RUSHING_JADE_WIND)
            end
        },
        
        -- Use Purifying Brew when stagger is high
        {
            spell = self.spells.PURIFYING_BREW,
            condition = function(self)
                return self:GetStaggerPercent() > 50
            end
        },
        
        -- Use Celestial Brew for mitigation
        {
            spell = self.spells.CELESTIAL_BREW,
            condition = function(self)
                return not self:HasBuff(self.spells.CELESTIAL_BREW) and
                       self:GetHealthPct() < 80
            end
        },
        
        -- Use Spinning Crane Kick for AoE damage
        {
            spell = self.spells.SPINNING_CRANE_KICK,
            condition = function(self)
                return self:GetEnergy() >= 40
            end
        },
        
        -- Use Black Ox Brew to refill brews
        {
            spell = self.spells.BLACK_OX_BREW,
            condition = function(self)
                return IsSpellKnown(self.spells.BLACK_OX_BREW) and
                       not self:SpellOnCooldown(self.spells.BLACK_OX_BREW) and
                       self:GetBrewStacks() < 1
            end
        },
        
        -- Use Tiger Palm as filler
        {
            spell = self.spells.TIGER_PALM,
            condition = function(self)
                return self:GetEnergy() > 65
            end
        },
        
        -- Use Blackout Kick as Chi spender
        {
            spell = self.spells.BLACKOUT_KICK,
            condition = function(self)
                return self:GetChi() >= 1
            end
        }
    }
    
    -- Define burst rotation
    self.burstRotation = {
        { spell = self.spells.INVOKE_NIUZAO },
        { 
            spell = self.spells.WEAPONS_OF_ORDER,
            condition = function(self) return IsSpellKnown(self.spells.WEAPONS_OF_ORDER) end
        },
        { 
            spell = self.spells.BONEDUST_BREW,
            condition = function(self) return IsSpellKnown(self.spells.BONEDUST_BREW) end
        },
        { spell = self.spells.KEG_SMASH },
        { spell = self.spells.BREATH_OF_FIRE },
        {
            spell = self.spells.EXPLODING_KEG,
            condition = function(self) return IsSpellKnown(self.spells.EXPLODING_KEG) end
        }
    }
    
    -- Add Brewmaster-specific defensive abilities
    table.insert(self.defensiveRotation, {
        spell = self.spells.ZEN_MEDITATION,
        threshold = 35,
        condition = function(self)
            -- Only cast when not actively fighting (as it breaks on attack)
            return not self:IsActivelyTanking()
        end
    })
    
    table.insert(self.defensiveRotation, {
        spell = self.spells.PURIFYING_BREW,
        threshold = 90,
        condition = function(self)
            return self:GetStaggerPercent() > 70
        end
    })
    
    table.insert(self.defensiveRotation, {
        spell = self.spells.CELESTIAL_BREW,
        threshold = 75
    })
end

-- Load Mistweaver specialization
function Monk:LoadMistweaverSpec()
    -- Mistweaver-specific spells
    self.spells.RENEWING_MIST = 115151
    self.spells.SOOTHING_MIST = 115175
    self.spells.ENVELOPING_MIST = 124682
    self.spells.THUNDER_FOCUS_TEA = 116680
    self.spells.LIFE_COCOON = 116849
    self.spells.REVIVAL = 115310
    self.spells.ESSENCE_FONT = 191837
    self.spells.INVOKE_YULON = 322118
    self.spells.INVOKE_CHI_JI = 325197
    self.spells.REFRESHING_JADE_WIND = 196725
    self.spells.MANA_TEA = 197908
    self.spells.CHI_BURST = 123986
    self.spells.MIST_WRAP = 197900
    self.spells.SUMMON_JADE_SERPENT_STATUE = 115313
    self.spells.DIFFUSE_MAGIC = 122783
    self.spells.DAMPEN_HARM = 122278
    self.spells.HEALING_ELIXIR = 122281
    self.spells.LIFECYCLES = 197915
    self.spells.SPIRIT_OF_THE_CRANE = 210802
    self.spells.MIST_WRAP = 197900
    self.spells.UPWELLING = 274963
    self.spells.RISING_MIST = 274909
    self.spells.FOCUSED_THUNDER = 197895
    
    -- Setup cooldown and aura tracking for Mistweaver
    WR.Cooldown:StartTracking(self.spells.RENEWING_MIST)
    WR.Cooldown:StartTracking(self.spells.ENVELOPING_MIST)
    WR.Cooldown:StartTracking(self.spells.THUNDER_FOCUS_TEA)
    WR.Cooldown:StartTracking(self.spells.LIFE_COCOON)
    WR.Cooldown:StartTracking(self.spells.REVIVAL)
    WR.Cooldown:StartTracking(self.spells.ESSENCE_FONT)
    WR.Cooldown:StartTracking(self.spells.INVOKE_YULON)
    WR.Cooldown:StartTracking(self.spells.INVOKE_CHI_JI)
    WR.Cooldown:StartTracking(self.spells.REFRESHING_JADE_WIND)
    WR.Cooldown:StartTracking(self.spells.MANA_TEA)
    WR.Cooldown:StartTracking(self.spells.CHI_BURST)
    WR.Cooldown:StartTracking(self.spells.DIFFUSE_MAGIC)
    WR.Cooldown:StartTracking(self.spells.DAMPEN_HARM)
    WR.Cooldown:StartTracking(self.spells.HEALING_ELIXIR)
    
    -- Track important buffs/debuffs
    WR.Auras:RegisterImportantAura(self.spells.RENEWING_MIST, 85, true, false)
    WR.Auras:RegisterImportantAura(self.spells.ENVELOPING_MIST, 90, true, false)
    WR.Auras:RegisterImportantAura(self.spells.THUNDER_FOCUS_TEA, 90, true, false)
    WR.Auras:RegisterImportantAura(self.spells.MANA_TEA, 85, true, false)
    WR.Auras:RegisterImportantAura(self.spells.LIFECYCLES, 80, true, false)
    WR.Auras:RegisterImportantAura(self.spells.SOOTHING_MIST, 80, true, false)
    
    -- Define Mistweaver DPS rotation (for solo content)
    -- Note: Since Mistweaver is primarily a healer, actual implementation would focus on healing logic
    -- For combat/damage situations, we'll create a simple DPS rotation for solo content
    
    self.singleTargetRotation = {
        -- Use Touch of Death when target is low
        {
            spell = self.spells.TOUCH_OF_DEATH,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.TOUCH_OF_DEATH) and
                       self:IsTargetExecatable()
            end
        },
        
        -- Use Rising Sun Kick on cooldown
        {
            spell = self.spells.RISING_SUN_KICK,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.RISING_SUN_KICK)
            end
        },
        
        -- Use covenant abilities
        { 
            spell = self.spells.WEAPONS_OF_ORDER,
            condition = function(self) return IsSpellKnown(self.spells.WEAPONS_OF_ORDER) end
        },
        { 
            spell = self.spells.FAELINE_STOMP,
            condition = function(self) return IsSpellKnown(self.spells.FAELINE_STOMP) end
        },
        { 
            spell = self.spells.FALLEN_ORDER,
            condition = function(self) return IsSpellKnown(self.spells.FALLEN_ORDER) end
        },
        { 
            spell = self.spells.BONEDUST_BREW,
            condition = function(self) return IsSpellKnown(self.spells.BONEDUST_BREW) end
        },
        
        -- Self-heal if needed
        {
            spell = self.spells.VIVIFY,
            condition = function(self)
                return self:GetHealthPct() < 80
            end
        },
        {
            spell = self.spells.ENVELOPING_MIST,
            condition = function(self)
                return self:GetHealthPct() < 60
            end
        },
        {
            spell = self.spells.HEALING_ELIXIR,
            condition = function(self)
                return IsSpellKnown(self.spells.HEALING_ELIXIR) and
                       self:GetHealthPct() < 65 and
                       not self:SpellOnCooldown(self.spells.HEALING_ELIXIR)
            end
        },
        
        -- Use Blackout Kick
        { spell = self.spells.BLACKOUT_KICK },
        
        -- Use Tiger Palm as filler
        { spell = self.spells.TIGER_PALM }
    }
    
    -- AoE rotation for Mistweaver
    self.aoeRotation = {
        -- Use Touch of Death when target is low
        {
            spell = self.spells.TOUCH_OF_DEATH,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.TOUCH_OF_DEATH) and
                       self:IsTargetExecatable()
            end
        },
        
        -- Use covenant abilities for AoE
        { 
            spell = self.spells.WEAPONS_OF_ORDER,
            condition = function(self) return IsSpellKnown(self.spells.WEAPONS_OF_ORDER) end
        },
        { 
            spell = self.spells.FAELINE_STOMP,
            condition = function(self) return IsSpellKnown(self.spells.FAELINE_STOMP) end
        },
        { 
            spell = self.spells.FALLEN_ORDER,
            condition = function(self) return IsSpellKnown(self.spells.FALLEN_ORDER) end
        },
        { 
            spell = self.spells.BONEDUST_BREW,
            condition = function(self) return IsSpellKnown(self.spells.BONEDUST_BREW) end
        },
        
        -- Use Rising Sun Kick on cooldown
        {
            spell = self.spells.RISING_SUN_KICK,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.RISING_SUN_KICK)
            end
        },
        
        -- Use Chi Burst for AoE
        {
            spell = self.spells.CHI_BURST,
            condition = function(self)
                return IsSpellKnown(self.spells.CHI_BURST) and
                       not self:SpellOnCooldown(self.spells.CHI_BURST)
            end
        },
        
        -- Use Refreshing Jade Wind for AoE if talented
        {
            spell = self.spells.REFRESHING_JADE_WIND,
            condition = function(self)
                return IsSpellKnown(self.spells.REFRESHING_JADE_WIND) and
                       not self:SpellOnCooldown(self.spells.REFRESHING_JADE_WIND)
            end
        },
        
        -- Use Spinning Crane Kick for AoE
        {
            spell = self.spells.SPINNING_CRANE_KICK,
            condition = function(self)
                return self:GetEnemyCount(8) >= 3 and
                       self:GetMana() > 15
            end
        },
        
        -- Use Tiger Palm as filler
        { spell = self.spells.TIGER_PALM }
    }
    
    -- Define burst rotation
    self.burstRotation = {
        {
            spell = self.spells.INVOKE_YULON,
            condition = function(self) return not IsSpellKnown(self.spells.INVOKE_CHI_JI) end
        },
        {
            spell = self.spells.INVOKE_CHI_JI,
            condition = function(self) return IsSpellKnown(self.spells.INVOKE_CHI_JI) end
        },
        { spell = self.spells.THUNDER_FOCUS_TEA },
        { 
            spell = self.spells.WEAPONS_OF_ORDER,
            condition = function(self) return IsSpellKnown(self.spells.WEAPONS_OF_ORDER) end
        },
        { 
            spell = self.spells.FALLEN_ORDER,
            condition = function(self) return IsSpellKnown(self.spells.FALLEN_ORDER) end
        },
        { spell = self.spells.RISING_SUN_KICK }
    }
    
    -- Add Mistweaver-specific defensive abilities
    table.insert(self.defensiveRotation, {
        spell = self.spells.LIFE_COCOON,
        threshold = 30,
        targets = { "player" }
    })
    
    table.insert(self.defensiveRotation, {
        spell = self.spells.DIFFUSE_MAGIC,
        threshold = 40,
        condition = function(self)
            return IsSpellKnown(self.spells.DIFFUSE_MAGIC) and
                   self:IsMagicDamageHigh()
        end
    })
    
    table.insert(self.defensiveRotation, {
        spell = self.spells.DAMPEN_HARM,
        threshold = 40,
        condition = function(self)
            return IsSpellKnown(self.spells.DAMPEN_HARM)
        end
    })
end

-- Load Windwalker specialization
function Monk:LoadWindwalkerSpec()
    -- Windwalker-specific spells
    self.spells.FISTS_OF_FURY = 113656
    self.spells.STORM_EARTH_AND_FIRE = 137639
    self.spells.WHIRLING_DRAGON_PUNCH = 152175
    self.spells.TOUCH_OF_KARMA = 122470
    self.spells.INVOKE_XUEN = 123904
    self.spells.SERENITY = 152173
    self.spells.ENERGIZING_ELIXIR = 115288
    self.spells.FIST_OF_THE_WHITE_TIGER = 261947
    self.spells.CHI_BURST = 123986
    self.spells.DIFFUSE_MAGIC = 122783
    self.spells.DAMPEN_HARM = 122278
    self.spells.TIGER_PALM = 100780
    self.spells.COMBO_BREAKER = 116768
    self.spells.DANCE_OF_CHIJI = 325201
    self.spells.MARK_OF_THE_CRANE = 228287
    self.spells.STRIKE_OF_THE_WINDLORD = 392983
    self.spells.HIT_COMBO = 196740
    self.spells.FLYING_SERPENT_KICK = 101545
    self.spells.DISABLE = 116095
    self.spells.PRESSURE_POINT = 337482
    
    -- Setup cooldown and aura tracking for Windwalker
    WR.Cooldown:StartTracking(self.spells.FISTS_OF_FURY)
    WR.Cooldown:StartTracking(self.spells.RISING_SUN_KICK)
    WR.Cooldown:StartTracking(self.spells.STORM_EARTH_AND_FIRE)
    WR.Cooldown:StartTracking(self.spells.WHIRLING_DRAGON_PUNCH)
    WR.Cooldown:StartTracking(self.spells.TOUCH_OF_KARMA)
    WR.Cooldown:StartTracking(self.spells.INVOKE_XUEN)
    WR.Cooldown:StartTracking(self.spells.SERENITY)
    WR.Cooldown:StartTracking(self.spells.ENERGIZING_ELIXIR)
    WR.Cooldown:StartTracking(self.spells.FIST_OF_THE_WHITE_TIGER)
    WR.Cooldown:StartTracking(self.spells.CHI_BURST)
    WR.Cooldown:StartTracking(self.spells.DIFFUSE_MAGIC)
    WR.Cooldown:StartTracking(self.spells.DAMPEN_HARM)
    WR.Cooldown:StartTracking(self.spells.STRIKE_OF_THE_WINDLORD)
    WR.Cooldown:StartTracking(self.spells.DISABLE)
    
    -- Track important buffs/debuffs
    WR.Auras:RegisterImportantAura(self.spells.STORM_EARTH_AND_FIRE, 90, true, false)
    WR.Auras:RegisterImportantAura(self.spells.SERENITY, 95, true, false)
    WR.Auras:RegisterImportantAura(self.spells.TOUCH_OF_KARMA, 85, true, false)
    WR.Auras:RegisterImportantAura(self.spells.COMBO_BREAKER, 80, true, false)
    WR.Auras:RegisterImportantAura(self.spells.DANCE_OF_CHIJI, 85, true, false)
    WR.Auras:RegisterImportantAura(self.spells.MARK_OF_THE_CRANE, 80, false, true)
    WR.Auras:RegisterImportantAura(self.spells.HIT_COMBO, 85, true, false)
    WR.Auras:RegisterImportantAura(self.spells.PRESSURE_POINT, 90, true, false)
    
    -- Set interrupt ability
    self.interruptRotation = {
        { spell = self.spells.SPEAR_HAND_STRIKE }
    }
    
    -- Define Windwalker single target rotation
    self.singleTargetRotation = {
        -- Use Invoke Xuen for burst
        {
            spell = self.spells.INVOKE_XUEN,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.INVOKE_XUEN)
            end
        },
        
        -- Use Storm, Earth, and Fire for burst (if not using Serenity)
        {
            spell = self.spells.STORM_EARTH_AND_FIRE,
            condition = function(self)
                return not IsSpellKnown(self.spells.SERENITY) and
                       not self:SpellOnCooldown(self.spells.STORM_EARTH_AND_FIRE) and
                       not self:HasBuff(self.spells.STORM_EARTH_AND_FIRE)
            end
        },
        
        -- Use Serenity for burst (if talented)
        {
            spell = self.spells.SERENITY,
            condition = function(self)
                return IsSpellKnown(self.spells.SERENITY) and
                       not self:SpellOnCooldown(self.spells.SERENITY)
            end
        },
        
        -- Use Touch of Death when target is low
        {
            spell = self.spells.TOUCH_OF_DEATH,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.TOUCH_OF_DEATH) and
                       self:IsTargetExecatable()
            end
        },
        
        -- Use covenant abilities
        { 
            spell = self.spells.WEAPONS_OF_ORDER,
            condition = function(self) return IsSpellKnown(self.spells.WEAPONS_OF_ORDER) end
        },
        { 
            spell = self.spells.FAELINE_STOMP,
            condition = function(self) return IsSpellKnown(self.spells.FAELINE_STOMP) end
        },
        { 
            spell = self.spells.FALLEN_ORDER,
            condition = function(self) return IsSpellKnown(self.spells.FALLEN_ORDER) end
        },
        { 
            spell = self.spells.BONEDUST_BREW,
            condition = function(self) return IsSpellKnown(self.spells.BONEDUST_BREW) end
        },
        
        -- Use Strike of the Windlord
        {
            spell = self.spells.STRIKE_OF_THE_WINDLORD,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.STRIKE_OF_THE_WINDLORD)
            end
        },
        
        -- Use Fists of Fury
        {
            spell = self.spells.FISTS_OF_FURY,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.FISTS_OF_FURY) and
                       self:GetChi() >= 3
            end
        },
        
        -- Use Whirling Dragon Punch if talented
        {
            spell = self.spells.WHIRLING_DRAGON_PUNCH,
            condition = function(self)
                return IsSpellKnown(self.spells.WHIRLING_DRAGON_PUNCH) and
                       not self:SpellOnCooldown(self.spells.WHIRLING_DRAGON_PUNCH) and
                       self:SpellOnCooldown(self.spells.FISTS_OF_FURY) and
                       self:SpellOnCooldown(self.spells.RISING_SUN_KICK)
            end
        },
        
        -- Use Rising Sun Kick on cooldown
        {
            spell = self.spells.RISING_SUN_KICK,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.RISING_SUN_KICK) and
                       self:GetChi() >= 2
            end
        },
        
        -- Use Spinning Crane Kick with Dance of Chi-Ji proc
        {
            spell = self.spells.SPINNING_CRANE_KICK,
            condition = function(self)
                return self:HasBuff(self.spells.DANCE_OF_CHIJI) and
                       self:GetChi() >= 2
            end
        },
        
        -- Use Energizing Elixir when low on energy and chi
        {
            spell = self.spells.ENERGIZING_ELIXIR,
            condition = function(self)
                return IsSpellKnown(self.spells.ENERGIZING_ELIXIR) and
                       not self:SpellOnCooldown(self.spells.ENERGIZING_ELIXIR) and
                       self:GetEnergyPct() < 50 and
                       self:GetChi() < 2
            end
        },
        
        -- Use Fist of the White Tiger as Chi generator
        {
            spell = self.spells.FIST_OF_THE_WHITE_TIGER,
            condition = function(self)
                return IsSpellKnown(self.spells.FIST_OF_THE_WHITE_TIGER) and
                       not self:SpellOnCooldown(self.spells.FIST_OF_THE_WHITE_TIGER) and
                       self:GetChi() <= 3
            end
        },
        
        -- Use Chi Burst if talented
        {
            spell = self.spells.CHI_BURST,
            condition = function(self)
                return IsSpellKnown(self.spells.CHI_BURST) and
                       not self:SpellOnCooldown(self.spells.CHI_BURST)
            end
        },
        
        -- Use Blackout Kick with Combo Breaker proc
        {
            spell = self.spells.BLACKOUT_KICK,
            condition = function(self)
                return self:HasBuff(self.spells.COMBO_BREAKER)
            end
        },
        
        -- Use Blackout Kick as a Chi spender
        {
            spell = self.spells.BLACKOUT_KICK,
            condition = function(self)
                return self:GetChi() >= 1
            end
        },
        
        -- Use Tiger Palm as Chi generator
        {
            spell = self.spells.TIGER_PALM,
            condition = function(self)
                return self:GetChi() < 5 and self:GetEnergy() >= 50
            end
        }
    }
    
    -- AoE rotation for Windwalker
    self.aoeRotation = {
        -- Use Invoke Xuen for burst
        {
            spell = self.spells.INVOKE_XUEN,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.INVOKE_XUEN)
            end
        },
        
        -- Use Storm, Earth, and Fire for burst (if not using Serenity)
        {
            spell = self.spells.STORM_EARTH_AND_FIRE,
            condition = function(self)
                return not IsSpellKnown(self.spells.SERENITY) and
                       not self:SpellOnCooldown(self.spells.STORM_EARTH_AND_FIRE) and
                       not self:HasBuff(self.spells.STORM_EARTH_AND_FIRE)
            end
        },
        
        -- Use Serenity for burst (if talented)
        {
            spell = self.spells.SERENITY,
            condition = function(self)
                return IsSpellKnown(self.spells.SERENITY) and
                       not self:SpellOnCooldown(self.spells.SERENITY)
            end
        },
        
        -- Use covenant abilities for AoE
        { 
            spell = self.spells.WEAPONS_OF_ORDER,
            condition = function(self) return IsSpellKnown(self.spells.WEAPONS_OF_ORDER) end
        },
        { 
            spell = self.spells.FAELINE_STOMP,
            condition = function(self) return IsSpellKnown(self.spells.FAELINE_STOMP) end
        },
        { 
            spell = self.spells.FALLEN_ORDER,
            condition = function(self) return IsSpellKnown(self.spells.FALLEN_ORDER) end
        },
        { 
            spell = self.spells.BONEDUST_BREW,
            condition = function(self) return IsSpellKnown(self.spells.BONEDUST_BREW) end
        },
        
        -- Use Strike of the Windlord
        {
            spell = self.spells.STRIKE_OF_THE_WINDLORD,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.STRIKE_OF_THE_WINDLORD)
            end
        },
        
        -- Use Fists of Fury for AoE
        {
            spell = self.spells.FISTS_OF_FURY,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.FISTS_OF_FURY) and
                       self:GetChi() >= 3
            end
        },
        
        -- Use Whirling Dragon Punch if talented
        {
            spell = self.spells.WHIRLING_DRAGON_PUNCH,
            condition = function(self)
                return IsSpellKnown(self.spells.WHIRLING_DRAGON_PUNCH) and
                       not self:SpellOnCooldown(self.spells.WHIRLING_DRAGON_PUNCH) and
                       self:SpellOnCooldown(self.spells.FISTS_OF_FURY) and
                       self:SpellOnCooldown(self.spells.RISING_SUN_KICK)
            end
        },
        
        -- Use Spinning Crane Kick for AoE
        {
            spell = self.spells.SPINNING_CRANE_KICK,
            condition = function(self)
                return (self:HasBuff(self.spells.DANCE_OF_CHIJI) or
                        self:GetEnemyCount(8) >= 3) and
                       self:GetChi() >= 2
            end
        },
        
        -- Use Rising Sun Kick to maintain Mark of the Crane stacks
        {
            spell = self.spells.RISING_SUN_KICK,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.RISING_SUN_KICK) and
                       self:GetChi() >= 2
            end
        },
        
        -- Use Chi Burst for AoE
        {
            spell = self.spells.CHI_BURST,
            condition = function(self)
                return IsSpellKnown(self.spells.CHI_BURST) and
                       not self:SpellOnCooldown(self.spells.CHI_BURST)
            end
        },
        
        -- Use Energizing Elixir when low on energy and chi
        {
            spell = self.spells.ENERGIZING_ELIXIR,
            condition = function(self)
                return IsSpellKnown(self.spells.ENERGIZING_ELIXIR) and
                       not self:SpellOnCooldown(self.spells.ENERGIZING_ELIXIR) and
                       self:GetEnergyPct() < 50 and
                       self:GetChi() < 2
            end
        },
        
        -- Use Fist of the White Tiger as Chi generator
        {
            spell = self.spells.FIST_OF_THE_WHITE_TIGER,
            condition = function(self)
                return IsSpellKnown(self.spells.FIST_OF_THE_WHITE_TIGER) and
                       not self:SpellOnCooldown(self.spells.FIST_OF_THE_WHITE_TIGER) and
                       self:GetChi() <= 3
            end
        },
        
        -- Use Blackout Kick with Combo Breaker proc
        {
            spell = self.spells.BLACKOUT_KICK,
            condition = function(self)
                return self:HasBuff(self.spells.COMBO_BREAKER)
            end
        },
        
        -- Use Tiger Palm as Chi generator
        {
            spell = self.spells.TIGER_PALM,
            condition = function(self)
                return self:GetChi() < 5 and self:GetEnergy() >= 50
            end
        }
    }
    
    -- Define burst rotation
    self.burstRotation = {
        { spell = self.spells.INVOKE_XUEN },
        {
            spell = self.spells.STORM_EARTH_AND_FIRE,
            condition = function(self)
                return not IsSpellKnown(self.spells.SERENITY)
            end
        },
        {
            spell = self.spells.SERENITY,
            condition = function(self) return IsSpellKnown(self.spells.SERENITY) end
        },
        { 
            spell = self.spells.WEAPONS_OF_ORDER,
            condition = function(self) return IsSpellKnown(self.spells.WEAPONS_OF_ORDER) end
        },
        { 
            spell = self.spells.FALLEN_ORDER,
            condition = function(self) return IsSpellKnown(self.spells.FALLEN_ORDER) end
        },
        { spell = self.spells.STRIKE_OF_THE_WINDLORD },
        { spell = self.spells.FISTS_OF_FURY }
    }
    
    -- Add Windwalker-specific defensive abilities
    table.insert(self.defensiveRotation, {
        spell = self.spells.TOUCH_OF_KARMA,
        threshold = 70
    })
    
    table.insert(self.defensiveRotation, {
        spell = self.spells.DIFFUSE_MAGIC,
        threshold = 50,
        condition = function(self)
            return IsSpellKnown(self.spells.DIFFUSE_MAGIC) and
                   self:IsMagicDamageHigh()
        end
    })
    
    table.insert(self.defensiveRotation, {
        spell = self.spells.DAMPEN_HARM,
        threshold = 50,
        condition = function(self)
            return IsSpellKnown(self.spells.DAMPEN_HARM)
        end
    })
end

-- Check if the player is actively tanking
function Monk:IsActivelyTanking()
    -- In a real addon, this would check for active tanking
    -- Here we'll return a simplified check
    return self.currentSpec == SPEC_BREWMASTER and 
           UnitExists("target") and 
           UnitAffectingCombat("player")
end

-- Get the current stagger percentage
function Monk:GetStaggerPercent()
    -- In a real addon, this would use UnitStagger API
    -- Here we'll return a simulated value
    if self.currentSpec == SPEC_BREWMASTER then
        return math.random(0, 100)
    end
    return 0
end

-- Get the current number of healing orbs
function Monk:GetOrbCount()
    -- In a real addon, this would count the number of orbs
    -- Here we'll return a simulated value
    if self.currentSpec == SPEC_BREWMASTER then
        return math.random(0, 5)
    end
    return 0
end

-- Get the current brew charges
function Monk:GetBrewStacks()
    -- In a real addon, this would use GetSpellCharges
    -- Here we'll return a simulated value
    if self.currentSpec == SPEC_BREWMASTER then
        return math.random(0, 3)
    end
    return 0
end

-- Check if the target can be executed with Touch of Death
function Monk:IsTargetExecatable()
    -- In a real addon, this would check target HP threshold
    -- Here we'll return a simulated value
    return UnitExists("target") and math.random() > 0.7
end

-- Check if the player is taking high magic damage
function Monk:IsMagicDamageHigh()
    -- In a real addon, this would analyze recent damage types
    -- Here we'll return a simulated value
    return math.random() > 0.5
end

-- Class-specific pre-rotation checks
function Monk:ClassSpecificChecks()
    -- Check if we have enough resources to cast spells
    if self.currentSpec == SPEC_WINDWALKER and self:GetChi() < 1 and self:GetEnergy() < 40 then
        -- Try to generate Chi
        WR.Queue:Add(self.spells.TIGER_PALM)
        return false
    end
    
    return true
end

-- Get default action when nothing else is available
function Monk:GetDefaultAction()
    if self.currentSpec == SPEC_BREWMASTER then
        return self.spells.TIGER_PALM
    elseif self.currentSpec == SPEC_MISTWEAVER then
        return self.spells.TIGER_PALM
    elseif self.currentSpec == SPEC_WINDWALKER then
        return self.spells.TIGER_PALM
    end
    
    return nil
end

-- Initialize the module
Monk:Initialize()

return Monk