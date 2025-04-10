local addonName, WR = ...

-- Evoker Class module
local Evoker = {}
WR.Classes = WR.Classes or {}
WR.Classes.EVOKER = Evoker

-- Inherit from BaseClass
setmetatable(Evoker, {__index = WR.BaseClass})

-- Resource type for Evokers (mana primary, essence secondary)
Evoker.resourceType = Enum.PowerType.Mana
Evoker.secondaryResourceType = Enum.PowerType.Essence

-- Define spec IDs
local SPEC_DEVASTATION = 1467
local SPEC_PRESERVATION = 1468
local SPEC_AUGMENTATION = 1473

-- Class initialization
function Evoker:Initialize()
    -- Inherit base initialization
    WR.BaseClass.Initialize(self)
    
    -- Register Specializations
    self:RegisterSpec(SPEC_DEVASTATION, "Devastation")
    self:RegisterSpec(SPEC_PRESERVATION, "Preservation")
    self:RegisterSpec(SPEC_AUGMENTATION, "Augmentation")
    
    -- Shared spell IDs across all Evoker specs
    self.spells = {
        -- Shared Core Abilities
        FIRE_BREATH = 357208,
        LIVING_FLAME = 361469,
        AZURE_STRIKE = 362969,
        DISINTEGRATE = 356995,
        TAIL_SWIPE = 368970,
        WING_BUFFET = 357214,
        HOVER = 358267,
        
        -- Shared Defensive Abilities
        OBSIDIAN_SCALES = 363916,
        RENEWING_BLAZE = 374348,
        RESCUE = 370665,
        ZEPHYR = 374227,
        
        -- Shared Utility
        BLESSING_OF_THE_BRONZE = 364342,
        DEEP_BREATH = 357210,
        EMERALD_BLOSSOM = 355913,
        SOURCE_OF_MAGIC = 369459,
        SURGE_FORWARD = 370553,
        TIP_THE_SCALES = 370553,
        
        -- Shared Crowd Control
        SLEEP_WALK = 360806,
        
        -- Raid Buff
        BLESSING_OF_THE_BRONZE = 364342,
        
        -- Covenant Abilities
        RESONATING_SPHERE = 411154,
    }
    
    -- Load shared Evoker data
    self:LoadSharedEvokerData()
    
    WR:Debug("Evoker module initialized")
end

-- Load shared spell and mechanics data for all Evoker specs
function Evoker:LoadSharedEvokerData()
    -- Register important buffs
    WR.Auras:RegisterImportantAura(self.spells.BLESSING_OF_THE_BRONZE, 60, true, false)
    WR.Auras:RegisterImportantAura(self.spells.OBSIDIAN_SCALES, 90, true, false)
    
    -- Setup cooldown tracking
    WR.Cooldown:StartTracking(self.spells.FIRE_BREATH)
    WR.Cooldown:StartTracking(self.spells.DISINTEGRATE)
    WR.Cooldown:StartTracking(self.spells.OBSIDIAN_SCALES)
    WR.Cooldown:StartTracking(self.spells.RENEWING_BLAZE)
    WR.Cooldown:StartTracking(self.spells.ZEPHYR)
    WR.Cooldown:StartTracking(self.spells.DEEP_BREATH)
    WR.Cooldown:StartTracking(self.spells.SLEEP_WALK)
    WR.Cooldown:StartTracking(self.spells.BLESSING_OF_THE_BRONZE)
    WR.Cooldown:StartTracking(self.spells.TIP_THE_SCALES)
    WR.Cooldown:StartTracking(self.spells.SURGE_FORWARD)
    
    -- Set up defensive rotation (shared by all specs)
    self.defensiveRotation = {
        { spell = self.spells.OBSIDIAN_SCALES, threshold = 50 },
        { spell = self.spells.RENEWING_BLAZE, threshold = 60 },
        { spell = self.spells.ZEPHYR, threshold = 30 }
    }
end

-- Load a specific specialization
function Evoker:LoadSpec(specId)
    -- Call the base class method to set up common components
    WR.BaseClass.LoadSpec(self, specId)
    
    -- Set the resource type based on spec
    if specId == SPEC_DEVASTATION then
        self.resourceType = Enum.PowerType.Mana
        self.secondaryResourceType = Enum.PowerType.Essence
    elseif specId == SPEC_PRESERVATION then
        self.resourceType = Enum.PowerType.Mana
        self.secondaryResourceType = Enum.PowerType.Essence
    elseif specId == SPEC_AUGMENTATION then
        self.resourceType = Enum.PowerType.Mana
        self.secondaryResourceType = Enum.PowerType.Essence
    end
    
    -- Load specific spec data
    if specId == SPEC_DEVASTATION then
        self:LoadDevastationSpec()
    elseif specId == SPEC_PRESERVATION then
        self:LoadPreservationSpec()
    elseif specId == SPEC_AUGMENTATION then
        self:LoadAugmentationSpec()
    end
    
    WR:Debug("Loaded Evoker spec:", self.specData.name)
    return true
end

-- Load Devastation specialization
function Evoker:LoadDevastationSpec()
    -- Devastation-specific spells
    self.spells.ETERNITY_SURGE = 359073
    self.spells.FIRESTORM = 368847
    self.spells.PYRE = 357211
    self.spells.DRAGONRAGE = 375087
    self.spells.SCINTILLATION = 370452
    self.spells.DREAM_BREATH = 355941
    self.spells.BURNOUT = 375801
    self.spells.IRIDESCENCE_BLUE = 386344
    self.spells.IRIDESCENCE_RED = 386342
    self.spells.SHATTERING_STAR = 370452
    self.spells.CAUTERIZING_FLAME = 374251
    self.spells.UNRAVEL = 368432
    self.spells.LANDSLIDE = 358385
    self.spells.QUELL = 351338
    self.spells.VERDANT_EMBRACE = 360995
    self.spells.TIME_SPIRAL = 374968
    self.spells.ETERNAL_GUARDIAN = 366155
    
    -- Setup cooldown and aura tracking for Devastation
    WR.Cooldown:StartTracking(self.spells.DRAGONRAGE)
    WR.Cooldown:StartTracking(self.spells.ETERNITY_SURGE)
    WR.Cooldown:StartTracking(self.spells.FIRESTORM)
    WR.Cooldown:StartTracking(self.spells.PYRE)
    WR.Cooldown:StartTracking(self.spells.SHATTERING_STAR)
    
    -- Track important buffs/debuffs
    WR.Auras:RegisterImportantAura(self.spells.DRAGONRAGE, 95, true, false)
    WR.Auras:RegisterImportantAura(self.spells.BURNOUT, 80, true, false)
    WR.Auras:RegisterImportantAura(self.spells.IRIDESCENCE_BLUE, 85, true, false)
    WR.Auras:RegisterImportantAura(self.spells.IRIDESCENCE_RED, 85, true, false)
    WR.Auras:RegisterImportantAura(self.spells.SCINTILLATION, 85, true, false)
    
    -- Define Devastation single target rotation
    self.singleTargetRotation = {
        -- Use Dragonrage on cooldown or at start of combat
        {
            spell = self.spells.DRAGONRAGE,
            condition = function(self)
                -- Use Dragonrage at the start of the fight or on cooldown
                return not self:SpellOnCooldown(self.spells.DRAGONRAGE)
            end
        },
        
        -- Use Tip the Scales during Dragonrage for powerful Fire Breath
        {
            spell = self.spells.TIP_THE_SCALES,
            condition = function(self)
                return self:HasBuff(self.spells.DRAGONRAGE) and
                       not self:SpellOnCooldown(self.spells.FIRE_BREATH)
            end
        },
        
        -- Use Fire Breath during Dragonrage if Tip the Scales is ready
        {
            spell = self.spells.FIRE_BREATH,
            condition = function(self)
                return self:HasBuff(self.spells.DRAGONRAGE) and
                       (self:HasBuff(self.spells.TIP_THE_SCALES) or 
                        self:SpellOnCooldown(self.spells.TIP_THE_SCALES))
            end
        },
        
        -- Use covenant ability
        { 
            spell = self.spells.RESONATING_SPHERE,
            condition = function(self) 
                return IsSpellKnown(self.spells.RESONATING_SPHERE) and
                       (self:HasBuff(self.spells.DRAGONRAGE) or 
                        self:SpellOnCooldown(self.spells.DRAGONRAGE))
            end
        },
        
        -- Use Eternity Surge during Dragonrage (empowered spell)
        {
            spell = self.spells.ETERNITY_SURGE,
            condition = function(self)
                return self:HasBuff(self.spells.DRAGONRAGE) or
                       self:GetEssence() >= 2
            end
        },
        
        -- Use Fire Breath on cooldown (this is an empowered ability)
        {
            spell = self.spells.FIRE_BREATH,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.FIRE_BREATH) and
                       self:GetEssence() >= 1
            end
        },
        
        -- Use Shattering Star if available
        {
            spell = self.spells.SHATTERING_STAR,
            condition = function(self)
                return IsSpellKnown(self.spells.SHATTERING_STAR) and
                       not self:SpellOnCooldown(self.spells.SHATTERING_STAR)
            end
        },
        
        -- Use Disintegrate to spend extra Essence
        {
            spell = self.spells.DISINTEGRATE,
            condition = function(self)
                return self:GetEssence() >= 3
            end
        },
        
        -- Use Living Flame for Burnout
        {
            spell = self.spells.LIVING_FLAME,
            condition = function(self)
                return self:HasBuff(self.spells.BURNOUT)
            end
        },
        
        -- Use Azure Strike as main filler
        { spell = self.spells.AZURE_STRIKE }
    }
    
    -- AoE rotation for Devastation
    self.aoeRotation = {
        -- Use Dragonrage on cooldown or at start of combat
        {
            spell = self.spells.DRAGONRAGE,
            condition = function(self)
                -- Use Dragonrage at the start of the fight or on cooldown
                return not self:SpellOnCooldown(self.spells.DRAGONRAGE)
            end
        },
        
        -- Use Tip the Scales during Dragonrage for powerful Fire Breath
        {
            spell = self.spells.TIP_THE_SCALES,
            condition = function(self)
                return self:HasBuff(self.spells.DRAGONRAGE) and
                       not self:SpellOnCooldown(self.spells.FIRE_BREATH)
            end
        },
        
        -- Use Deep Breath for AoE (this is the ultimate AoE ability)
        {
            spell = self.spells.DEEP_BREATH,
            condition = function(self)
                return self:GetEnemyCount(10) >= 3 and
                       not self:SpellOnCooldown(self.spells.DEEP_BREATH)
            end
        },
        
        -- Use covenant ability
        { 
            spell = self.spells.RESONATING_SPHERE,
            condition = function(self) 
                return IsSpellKnown(self.spells.RESONATING_SPHERE) and
                       (self:HasBuff(self.spells.DRAGONRAGE) or 
                        self:SpellOnCooldown(self.spells.DRAGONRAGE))
            end
        },
        
        -- Use Fire Breath on cooldown (this is an empowered ability)
        {
            spell = self.spells.FIRE_BREATH,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.FIRE_BREATH) and
                       self:GetEssence() >= 1
            end
        },
        
        -- Use Firestorm for AoE
        {
            spell = self.spells.FIRESTORM,
            condition = function(self)
                return self:GetEnemyCount(10) >= 3 and
                       not self:SpellOnCooldown(self.spells.FIRESTORM)
            end
        },
        
        -- Use Eternity Surge (empowered spell)
        {
            spell = self.spells.ETERNITY_SURGE,
            condition = function(self)
                return self:GetEssence() >= 2
            end
        },
        
        -- Use Disintegrate to spend extra Essence
        {
            spell = self.spells.DISINTEGRATE,
            condition = function(self)
                return self:GetEssence() >= 3
            end
        },
        
        -- Use Pyre for AoE damage
        {
            spell = self.spells.PYRE,
            condition = function(self)
                return self:GetEnemyCount(10) >= 2 and IsSpellKnown(self.spells.PYRE)
            end
        },
        
        -- Use Living Flame for Burnout
        {
            spell = self.spells.LIVING_FLAME,
            condition = function(self)
                return self:HasBuff(self.spells.BURNOUT)
            end
        },
        
        -- Use Azure Strike as main AoE filler
        { spell = self.spells.AZURE_STRIKE }
    }
    
    -- Define burst rotation
    self.burstRotation = {
        { spell = self.spells.DRAGONRAGE },
        { spell = self.spells.TIP_THE_SCALES },
        { spell = self.spells.FIRE_BREATH },
        { 
            spell = self.spells.RESONATING_SPHERE,
            condition = function(self) return IsSpellKnown(self.spells.RESONATING_SPHERE) end
        },
        { spell = self.spells.ETERNITY_SURGE },
        {
            spell = self.spells.SHATTERING_STAR,
            condition = function(self) return IsSpellKnown(self.spells.SHATTERING_STAR) end
        }
    }
    
    -- Set interrupt ability
    self.interruptRotation = {
        { spell = self.spells.QUELL }
    }
end

-- Load Preservation specialization
function Evoker:LoadPreservationSpec()
    -- Preservation-specific spells
    self.spells.ECHO = 364343
    self.spells.REVERSION = 366155
    self.spells.DREAM_BREATH = 355936
    self.spells.REWIND = 363534
    self.spells.SPIRITBLOOM = 367226
    self.spells.VERDANT_EMBRACE = 360995
    self.spells.DREAM_FLIGHT = 359816
    self.spells.EMERALD_COMMUNION = 370960
    self.spells.ECHO_INFUSION = 414582
    self.spells.UNRAVEL = 406732
    self.spells.LANDSLIDE = 406732
    self.spells.LIFE_SPIRAL = 406785
    self.spells.TEMPORAL_ANOMALY = 373861
    self.spells.STASIS = 370537
    
    -- Setup cooldown and aura tracking for Preservation
    WR.Cooldown:StartTracking(self.spells.DREAM_BREATH)
    WR.Cooldown:StartTracking(self.spells.REWIND)
    WR.Cooldown:StartTracking(self.spells.SPIRITBLOOM)
    WR.Cooldown:StartTracking(self.spells.VERDANT_EMBRACE)
    WR.Cooldown:StartTracking(self.spells.DREAM_FLIGHT)
    WR.Cooldown:StartTracking(self.spells.EMERALD_COMMUNION)
    
    -- Track important buffs/debuffs
    WR.Auras:RegisterImportantAura(self.spells.ECHO, 85, true, false)
    WR.Auras:RegisterImportantAura(self.spells.REVERSION, 80, true, false)
    WR.Auras:RegisterImportantAura(self.spells.LIFE_SPIRAL, 80, true, false)
    WR.Auras:RegisterImportantAura(self.spells.ECHO_INFUSION, 85, true, false)
    
    -- Define Preservation healer rotation
    -- Note: Since Preservation is primarily a healer, actual implementation would focus on healing logic
    -- For combat/damage situations, we'll create a simple DPS rotation for solo content
    
    self.singleTargetRotation = {
        -- Use Living Flame for damage
        { spell = self.spells.LIVING_FLAME },
        
        -- Use Fire Breath on cooldown (this is an empowered ability)
        {
            spell = self.spells.FIRE_BREATH,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.FIRE_BREATH) and
                       self:GetEssence() >= 1
            end
        },
        
        -- Use covenant ability
        { 
            spell = self.spells.RESONATING_SPHERE,
            condition = function(self) return IsSpellKnown(self.spells.RESONATING_SPHERE) end
        },
        
        -- Use Azure Strike as filler
        { spell = self.spells.AZURE_STRIKE }
    }
    
    -- AoE rotation for Preservation
    self.aoeRotation = {
        -- Use Deep Breath for AoE (this is the ultimate AoE ability)
        {
            spell = self.spells.DEEP_BREATH,
            condition = function(self)
                return self:GetEnemyCount(10) >= 3 and
                       not self:SpellOnCooldown(self.spells.DEEP_BREATH)
            end
        },
        
        -- Use Fire Breath on cooldown (this is an empowered ability)
        {
            spell = self.spells.FIRE_BREATH,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.FIRE_BREATH) and
                       self:GetEssence() >= 1
            end
        },
        
        -- Use covenant ability
        { 
            spell = self.spells.RESONATING_SPHERE,
            condition = function(self) return IsSpellKnown(self.spells.RESONATING_SPHERE) end
        },
        
        -- Use Azure Strike as main AoE filler
        { spell = self.spells.AZURE_STRIKE }
    }
    
    -- Define burst rotation
    self.burstRotation = {
        { spell = self.spells.TIP_THE_SCALES },
        { spell = self.spells.FIRE_BREATH },
        { 
            spell = self.spells.RESONATING_SPHERE,
            condition = function(self) return IsSpellKnown(self.spells.RESONATING_SPHERE) end
        }
    }
    
    -- Set interrupt ability
    self.interruptRotation = {
        { spell = self.spells.QUELL }
    }
    
    -- Add Preservation-specific defensive abilities
    table.insert(self.defensiveRotation, {
        spell = self.spells.EMERALD_COMMUNION,
        threshold = 40
    })
    
    table.insert(self.defensiveRotation, {
        spell = self.spells.VERDANT_EMBRACE,
        threshold = 60
    })
end

-- Load Augmentation specialization
function Evoker:LoadAugmentationSpec()
    -- Augmentation-specific spells
    self.spells.EBON_MIGHT = 395152
    self.spells.PRESCIENCE = 409311
    self.spells.BREATH_OF_EONS = 403631
    self.spells.SPATIAL_PARADOX = 406732
    self.spells.ESSENCE_BURST = 392268
    self.spells.BLISTERING_SCALES = 360827
    self.spells.ERUPTION = 395160
    self.spells.UPHEAVAL = 396286
    self.spells.TIME_SKIP = 404977
    self.spells.DREAM_PROJECTION = 410263
    self.spells.BLACK_ATTUNEMENT = 403264
    self.spells.BRONZE_ATTUNEMENT = 403284
    self.spells.TEMPORAL_WOUND = 406767
    self.spells.EXTEND_LIFE = 406789
    self.spells.SPIRITBLOOM = 367226
    self.spells.HOVER = 358267
    self.spells.QUELL = 351338
    
    -- Setup cooldown and aura tracking for Augmentation
    WR.Cooldown:StartTracking(self.spells.BREATH_OF_EONS)
    WR.Cooldown:StartTracking(self.spells.EBON_MIGHT)
    WR.Cooldown:StartTracking(self.spells.PRESCIENCE)
    WR.Cooldown:StartTracking(self.spells.TIME_SKIP)
    WR.Cooldown:StartTracking(self.spells.ERUPTION)
    WR.Cooldown:StartTracking(self.spells.UPHEAVAL)
    WR.Cooldown:StartTracking(self.spells.SPATIAL_PARADOX)
    
    -- Track important buffs/debuffs
    WR.Auras:RegisterImportantAura(self.spells.EBON_MIGHT, 90, true, false)
    WR.Auras:RegisterImportantAura(self.spells.PRESCIENCE, 85, true, false)
    WR.Auras:RegisterImportantAura(self.spells.ESSENCE_BURST, 80, true, false)
    WR.Auras:RegisterImportantAura(self.spells.BLISTERING_SCALES, 80, true, false)
    WR.Auras:RegisterImportantAura(self.spells.BLACK_ATTUNEMENT, 85, true, false)
    WR.Auras:RegisterImportantAura(self.spells.BRONZE_ATTUNEMENT, 85, true, false)
    WR.Auras:RegisterImportantAura(self.spells.TEMPORAL_WOUND, 85, false, true)
    
    -- Define Augmentation single target rotation
    self.singleTargetRotation = {
        -- Use Ebon Might to buff the party/raid
        {
            spell = self.spells.EBON_MIGHT,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.EBON_MIGHT) and
                       IsInGroup()
            end
        },
        
        -- Use Prescience to buff a target
        {
            spell = self.spells.PRESCIENCE,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.PRESCIENCE) and
                       IsInGroup()
            end
        },
        
        -- Use Breath of Eons for burst phase and increasing raid buffs
        {
            spell = self.spells.BREATH_OF_EONS,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.BREATH_OF_EONS) and
                       IsInGroup()
            end
        },
        
        -- Use Time Skip to reduce ally cooldowns
        {
            spell = self.spells.TIME_SKIP,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.TIME_SKIP) and
                       IsInGroup()
            end
        },
        
        -- Use Fire Breath on cooldown (this is an empowered ability)
        {
            spell = self.spells.FIRE_BREATH,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.FIRE_BREATH) and
                       self:GetEssence() >= 1
            end
        },
        
        -- Use covenant ability
        { 
            spell = self.spells.RESONATING_SPHERE,
            condition = function(self) return IsSpellKnown(self.spells.RESONATING_SPHERE) end
        },
        
        -- Use Upheaval if talented
        {
            spell = self.spells.UPHEAVAL,
            condition = function(self)
                return IsSpellKnown(self.spells.UPHEAVAL) and
                       not self:SpellOnCooldown(self.spells.UPHEAVAL)
            end
        },
        
        -- Use Disintegrate to spend extra Essence
        {
            spell = self.spells.DISINTEGRATE,
            condition = function(self)
                return self:GetEssence() >= 3
            end
        },
        
        -- Use Living Flame for Essence Burst and Black Attunement
        {
            spell = self.spells.LIVING_FLAME,
            condition = function(self)
                return self:HasBuff(self.spells.ESSENCE_BURST) or
                       self:HasBuff(self.spells.BLACK_ATTUNEMENT)
            end
        },
        
        -- Use Azure Strike as main filler
        { spell = self.spells.AZURE_STRIKE }
    }
    
    -- AoE rotation for Augmentation
    self.aoeRotation = {
        -- Use Ebon Might to buff the party/raid
        {
            spell = self.spells.EBON_MIGHT,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.EBON_MIGHT) and
                       IsInGroup()
            end
        },
        
        -- Use Deep Breath for AoE (this is the ultimate AoE ability)
        {
            spell = self.spells.DEEP_BREATH,
            condition = function(self)
                return self:GetEnemyCount(10) >= 3 and
                       not self:SpellOnCooldown(self.spells.DEEP_BREATH)
            end
        },
        
        -- Use Fire Breath on cooldown (this is an empowered ability)
        {
            spell = self.spells.FIRE_BREATH,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.FIRE_BREATH) and
                       self:GetEssence() >= 1
            end
        },
        
        -- Use covenant ability
        { 
            spell = self.spells.RESONATING_SPHERE,
            condition = function(self) return IsSpellKnown(self.spells.RESONATING_SPHERE) end
        },
        
        -- Use Eruption for AoE damage
        {
            spell = self.spells.ERUPTION,
            condition = function(self)
                return self:GetEnemyCount(8) >= 3 and
                       not self:SpellOnCooldown(self.spells.ERUPTION)
            end
        },
        
        -- Use Disintegrate to spend extra Essence
        {
            spell = self.spells.DISINTEGRATE,
            condition = function(self)
                return self:GetEssence() >= 3
            end
        },
        
        -- Use Azure Strike as main AoE filler
        { spell = self.spells.AZURE_STRIKE }
    }
    
    -- Define burst rotation
    self.burstRotation = {
        { spell = self.spells.BREATH_OF_EONS },
        { spell = self.spells.EBON_MIGHT },
        { spell = self.spells.PRESCIENCE },
        { spell = self.spells.TIP_THE_SCALES },
        { spell = self.spells.FIRE_BREATH },
        { 
            spell = self.spells.RESONATING_SPHERE,
            condition = function(self) return IsSpellKnown(self.spells.RESONATING_SPHERE) end
        },
        { spell = self.spells.TIME_SKIP }
    }
    
    -- Set interrupt ability
    self.interruptRotation = {
        { spell = self.spells.QUELL }
    }
    
    -- Add Augmentation-specific defensive abilities
    table.insert(self.defensiveRotation, {
        spell = self.spells.EXTEND_LIFE,
        threshold = 40
    })
end

-- Class-specific pre-rotation checks
function Evoker:ClassSpecificChecks()
    -- Check for class-specific conditions
    
    -- Check for Blessing of the Bronze buff
    if not self:HasBuff(self.spells.BLESSING_OF_THE_BRONZE) and 
       not self:SpellOnCooldown(self.spells.BLESSING_OF_THE_BRONZE) then
        WR.Queue:Add(self.spells.BLESSING_OF_THE_BRONZE)
        return false
    end
    
    return true
end

-- Get default action when nothing else is available
function Evoker:GetDefaultAction()
    if self.currentSpec == SPEC_DEVASTATION then
        return self.spells.AZURE_STRIKE
    elseif self.currentSpec == SPEC_PRESERVATION then
        return self.spells.LIVING_FLAME
    elseif self.currentSpec == SPEC_AUGMENTATION then
        return self.spells.AZURE_STRIKE
    end
    
    return nil
end

-- Initialize the module
Evoker:Initialize()

return Evoker