local addonName, WR = ...

-- Hunter Class module
local Hunter = {}
WR.Classes = WR.Classes or {}
WR.Classes.HUNTER = Hunter

-- Inherit from BaseClass
setmetatable(Hunter, {__index = WR.BaseClass})

-- Resource type for hunters (focus)
Hunter.resourceType = Enum.PowerType.Focus

-- Define spec IDs
local SPEC_BEAST_MASTERY = 253
local SPEC_MARKSMANSHIP = 254
local SPEC_SURVIVAL = 255

-- Class initialization
function Hunter:Initialize()
    -- Inherit base initialization
    WR.BaseClass.Initialize(self)
    
    -- Register Specializations
    self:RegisterSpec(SPEC_BEAST_MASTERY, "Beast Mastery")
    self:RegisterSpec(SPEC_MARKSMANSHIP, "Marksmanship")
    self:RegisterSpec(SPEC_SURVIVAL, "Survival")
    
    -- Shared spell IDs across all hunter specs
    self.spells = {
        -- Common hunter abilities
        ASPECT_OF_THE_WILD = 193530,
        ASPECT_OF_THE_TURTLE = 186265,
        ASPECT_OF_THE_CHEETAH = 186257,
        EXHILARATION = 109304,
        FREEZING_TRAP = 187650,
        TAR_TRAP = 187698,
        CONCUSSIVE_SHOT = 5116,
        HUNTERS_MARK = 257284,
        MISDIRECTION = 34477,
        FEIGN_DEATH = 5384,
        COUNTER_SHOT = 147362,
        MEND_PET = 136,
        INTIMIDATION = 19577,
        TRANQUILIZING_SHOT = 19801,
        CALL_PET_1 = 883,
        DISMISS_PET = 2641,
        FETCH = 125050,
        DISENGAGE = 781,
        BINDING_SHOT = 109248,
        CAMOUFLAGE = 199483,
        ASPECT_OF_THE_EAGLE = 186289,
        
        -- Covenant abilities
        WILD_SPIRITS = 328231,       -- Night Fae
        RESONATING_ARROW = 308491,   -- Kyrian
        DEATH_CHAKRAM = 325028,      -- Necrolord
        FLAYED_SHOT = 324149,        -- Venthyr
    }
    
    -- Load shared hunter data
    self:LoadSharedHunterData()
    
    WR:Debug("Hunter module initialized")
end

-- Load shared spell and mechanics data for all hunter specs
function Hunter:LoadSharedHunterData()
    -- Register important buffs
    WR.Auras:RegisterImportantAura(self.spells.ASPECT_OF_THE_WILD, 80, true, false)
    WR.Auras:RegisterImportantAura(self.spells.ASPECT_OF_THE_TURTLE, 90, true, false)
    WR.Auras:RegisterImportantAura(self.spells.ASPECT_OF_THE_EAGLE, 85, true, false)
    
    -- Setup cooldown tracking
    WR.Cooldown:StartTracking(self.spells.COUNTER_SHOT)
    WR.Cooldown:StartTracking(self.spells.ASPECT_OF_THE_WILD)
    WR.Cooldown:StartTracking(self.spells.ASPECT_OF_THE_TURTLE)
    WR.Cooldown:StartTracking(self.spells.FREEZING_TRAP)
    WR.Cooldown:StartTracking(self.spells.EXHILARATION)
    WR.Cooldown:StartTracking(self.spells.DISENGAGE)
    WR.Cooldown:StartTracking(self.spells.BINDING_SHOT)
    
    -- Set up interrupt rotation (shared by all specs)
    self.interruptRotation = {
        { spell = self.spells.COUNTER_SHOT }
    }
    
    -- Set up defensive rotation (shared by all specs)
    self.defensiveRotation = {
        { spell = self.spells.ASPECT_OF_THE_TURTLE, threshold = 20 }, -- Use Turtle at very low health
        { spell = self.spells.EXHILARATION, threshold = 40 } -- Use Exhilaration at moderate health
    }
end

-- Load a specific specialization
function Hunter:LoadSpec(specId)
    -- Call the base class method to set up common components
    WR.BaseClass.LoadSpec(self, specId)
    
    -- Load specific spec data
    if specId == SPEC_BEAST_MASTERY then
        self:LoadBeastMasterySpec()
    elseif specId == SPEC_MARKSMANSHIP then
        self:LoadMarksmanshipSpec()
    elseif specId == SPEC_SURVIVAL then
        self:LoadSurvivalSpec()
    end
    
    WR:Debug("Loaded hunter spec:", self.specData.name)
    return true
end

-- Load Beast Mastery specialization
function Hunter:LoadBeastMasterySpec()
    -- Beast Mastery-specific spells
    self.spells.KILL_COMMAND = 34026
    self.spells.BESTIAL_WRATH = 19574
    self.spells.BARBED_SHOT = 217200
    self.spells.COBRA_SHOT = 193455
    self.spells.MULTISHOT = 2643
    self.spells.DIRE_BEAST = 120679
    self.spells.KILL_SHOT = 53351
    self.spells.A_MURDER_OF_CROWS = 131894
    self.spells.CHIMAERA_SHOT = 53209
    self.spells.STAMPEDE = 201430
    self.spells.DIRE_BEAST_BASILISK = 205691
    self.spells.BARRAGE = 120360
    self.spells.SPITTING_COBRA = 194407
    self.spells.BEAST_CLEAVE = 115939
    self.spells.BESTIAL_WRATH = 19574
    self.spells.BLOODSHED = 321530
    
    -- Setup cooldown and aura tracking for Beast Mastery
    WR.Cooldown:StartTracking(self.spells.KILL_COMMAND)
    WR.Cooldown:StartTracking(self.spells.BESTIAL_WRATH)
    WR.Cooldown:StartTracking(self.spells.DIRE_BEAST)
    WR.Cooldown:StartTracking(self.spells.A_MURDER_OF_CROWS)
    WR.Cooldown:StartTracking(self.spells.BARRAGE)
    WR.Cooldown:StartTracking(self.spells.STAMPEDE)
    
    -- Track important buffs/debuffs
    WR.Auras:RegisterImportantAura(self.spells.BESTIAL_WRATH, 90, true, false)
    WR.Auras:RegisterImportantAura(self.spells.BEAST_CLEAVE, 80, true, false)
    WR.Auras:RegisterImportantAura(268877, 85, true, false) -- Beast Cleave buff (pet)
    WR.Auras:RegisterImportantAura(272790, 70, true, false) -- Frenzy buff
    
    -- Define Beast Mastery rotation, prioritizing abilities in order
    self.singleTargetRotation = {
        -- Use Bestial Wrath on cooldown
        { spell = self.spells.BESTIAL_WRATH },
        
        -- Use Aspect of the Wild with Bestial Wrath
        { 
            spell = self.spells.ASPECT_OF_THE_WILD,
            condition = function(self)
                return self:HasBuff(self.spells.BESTIAL_WRATH) or
                       self:GetSpellCooldown(self.spells.BESTIAL_WRATH) < 3
            end
        },
        
        -- Use covenant abilities
        { 
            spell = self.spells.WILD_SPIRITS,
            condition = function(self) return IsSpellKnown(self.spells.WILD_SPIRITS) end
        },
        { 
            spell = self.spells.RESONATING_ARROW,
            condition = function(self) return IsSpellKnown(self.spells.RESONATING_ARROW) end
        },
        { 
            spell = self.spells.DEATH_CHAKRAM,
            condition = function(self) return IsSpellKnown(self.spells.DEATH_CHAKRAM) end
        },
        { 
            spell = self.spells.FLAYED_SHOT,
            condition = function(self) return IsSpellKnown(self.spells.FLAYED_SHOT) end
        },
        
        -- Use Bloodshed if talented
        { 
            spell = self.spells.BLOODSHED,
            condition = function(self) return IsSpellKnown(self.spells.BLOODSHED) end
        },
        
        -- Use Kill Shot on targets below 20% health
        {
            spell = self.spells.KILL_SHOT,
            condition = function(self) 
                return self:TargetInExecuteRange() and 
                       IsSpellKnown(self.spells.KILL_SHOT)
            end
        },
        
        -- Use Barbed Shot to maintain Frenzy stacks or when charges are about to cap
        { 
            spell = self.spells.BARBED_SHOT,
            condition = function(self)
                local charges, maxCharges = self:GetSpellCharges(self.spells.BARBED_SHOT)
                local frenzyRemaining = self:GetBuffRemaining(272790, "pet") -- Frenzy buff on pet
                
                return charges >= maxCharges - 0.5 or 
                       (frenzyRemaining > 0 and frenzyRemaining < 2)
            end
        },
        
        -- Use Kill Command on cooldown
        {
            spell = self.spells.KILL_COMMAND,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.KILL_COMMAND)
            end
        },
        
        -- Use Chimaera Shot if talented
        {
            spell = self.spells.CHIMAERA_SHOT,
            condition = function(self)
                return IsSpellKnown(self.spells.CHIMAERA_SHOT)
            end
        },
        
        -- Use A Murder of Crows if talented
        {
            spell = self.spells.A_MURDER_OF_CROWS,
            condition = function(self)
                return IsSpellKnown(self.spells.A_MURDER_OF_CROWS)
            end
        },
        
        -- Use Dire Beast if talented
        {
            spell = self.spells.DIRE_BEAST,
            condition = function(self)
                return IsSpellKnown(self.spells.DIRE_BEAST)
            end
        },
        
        -- Use Stampede if talented
        {
            spell = self.spells.STAMPEDE,
            condition = function(self)
                return IsSpellKnown(self.spells.STAMPEDE) and
                       self:HasBuff(self.spells.ASPECT_OF_THE_WILD)
            end
        },
        
        -- Use Barrage if talented and facing multiple targets
        {
            spell = self.spells.BARRAGE,
            condition = function(self)
                return IsSpellKnown(self.spells.BARRAGE) and
                       self:GetEnemyCount(15) >= 2
            end
        },
        
        -- Use another Barbed Shot if focus is high
        {
            spell = self.spells.BARBED_SHOT,
            condition = function(self)
                local charges = self:GetSpellCharges(self.spells.BARBED_SHOT)
                return charges > 0 and self:GetResourcePct() > 70
            end
        },
        
        -- Use Cobra Shot as filler if enough focus and Kill Command isn't coming off cooldown soon
        { 
            spell = self.spells.COBRA_SHOT,
            condition = function(self)
                local kcCD = self:GetSpellCooldown(self.spells.KILL_COMMAND)
                return self:GetResource() >= 35 and kcCD > 1.5
            end
        }
    }
    
    -- Define AoE rotation for Beast Mastery
    self.aoeRotation = {
        -- Use Bestial Wrath on cooldown
        { spell = self.spells.BESTIAL_WRATH },
        
        -- Use Aspect of the Wild with Bestial Wrath
        { 
            spell = self.spells.ASPECT_OF_THE_WILD,
            condition = function(self)
                return self:HasBuff(self.spells.BESTIAL_WRATH) or
                       self:GetSpellCooldown(self.spells.BESTIAL_WRATH) < 3
            end
        },
        
        -- Use covenant abilities
        { 
            spell = self.spells.WILD_SPIRITS,
            condition = function(self) return IsSpellKnown(self.spells.WILD_SPIRITS) end
        },
        { 
            spell = self.spells.RESONATING_ARROW,
            condition = function(self) return IsSpellKnown(self.spells.RESONATING_ARROW) end
        },
        { 
            spell = self.spells.DEATH_CHAKRAM,
            condition = function(self) return IsSpellKnown(self.spells.DEATH_CHAKRAM) end
        },
        { 
            spell = self.spells.FLAYED_SHOT,
            condition = function(self) return IsSpellKnown(self.spells.FLAYED_SHOT) end
        },
        
        -- Use Bloodshed if talented
        { 
            spell = self.spells.BLOODSHED,
            condition = function(self) return IsSpellKnown(self.spells.BLOODSHED) end
        },
        
        -- Use Stampede if talented
        {
            spell = self.spells.STAMPEDE,
            condition = function(self)
                return IsSpellKnown(self.spells.STAMPEDE)
            end
        },
        
        -- Use Barrage if talented
        {
            spell = self.spells.BARRAGE,
            condition = function(self)
                return IsSpellKnown(self.spells.BARRAGE)
            end
        },
        
        -- Use Multishot to maintain Beast Cleave
        {
            spell = self.spells.MULTISHOT,
            condition = function(self)
                local beastCleaveRemaining = self:GetBuffRemaining(self.spells.BEAST_CLEAVE, "pet")
                return beastCleaveRemaining < 1.5
            end
        },
        
        -- Use Barbed Shot to maintain Frenzy stacks or when charges are about to cap
        { 
            spell = self.spells.BARBED_SHOT,
            condition = function(self)
                local charges, maxCharges = self:GetSpellCharges(self.spells.BARBED_SHOT)
                local frenzyRemaining = self:GetBuffRemaining(272790, "pet") -- Frenzy buff on pet
                
                return charges >= maxCharges - 0.5 or 
                       (frenzyRemaining > 0 and frenzyRemaining < 2)
            end
        },
        
        -- Use Kill Command on cooldown
        {
            spell = self.spells.KILL_COMMAND,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.KILL_COMMAND)
            end
        },
        
        -- Use A Murder of Crows if talented
        {
            spell = self.spells.A_MURDER_OF_CROWS,
            condition = function(self)
                return IsSpellKnown(self.spells.A_MURDER_OF_CROWS)
            end
        },
        
        -- Use Dire Beast if talented
        {
            spell = self.spells.DIRE_BEAST,
            condition = function(self)
                return IsSpellKnown(self.spells.DIRE_BEAST)
            end
        },
        
        -- Use another Barbed Shot if focus is high
        {
            spell = self.spells.BARBED_SHOT,
            condition = function(self)
                local charges = self:GetSpellCharges(self.spells.BARBED_SHOT)
                return charges > 0 and self:GetResourcePct() > 70
            end
        },
        
        -- Use Multishot as a filler in AoE
        {
            spell = self.spells.MULTISHOT,
            condition = function(self)
                return self:GetResource() >= 40
            end
        },
        
        -- Use Cobra Shot as a filler if nothing else is available
        {
            spell = self.spells.COBRA_SHOT,
            condition = function(self)
                local kcCD = self:GetSpellCooldown(self.spells.KILL_COMMAND)
                return self:GetResource() >= 50 and kcCD > 1.5
            end
        }
    }
    
    -- Define burst rotation
    self.burstRotation = {
        { spell = self.spells.ASPECT_OF_THE_WILD },
        { spell = self.spells.BESTIAL_WRATH },
        { 
            spell = self.spells.WILD_SPIRITS,
            condition = function(self) return IsSpellKnown(self.spells.WILD_SPIRITS) end
        },
        { 
            spell = self.spells.RESONATING_ARROW,
            condition = function(self) return IsSpellKnown(self.spells.RESONATING_ARROW) end
        },
        { 
            spell = self.spells.DEATH_CHAKRAM,
            condition = function(self) return IsSpellKnown(self.spells.DEATH_CHAKRAM) end
        },
        { 
            spell = self.spells.FLAYED_SHOT,
            condition = function(self) return IsSpellKnown(self.spells.FLAYED_SHOT) end
        },
        { 
            spell = self.spells.STAMPEDE,
            condition = function(self) return IsSpellKnown(self.spells.STAMPEDE) end
        }
    }
end

-- Load Marksmanship specialization
function Hunter:LoadMarksmanshipSpec()
    -- Marksmanship-specific spells
    self.spells.AIMED_SHOT = 19434
    self.spells.RAPID_FIRE = 257044
    self.spells.STEADY_SHOT = 56641
    self.spells.MULTISHOT = 2643
    self.spells.ARCANE_SHOT = 185358
    self.spells.TRUESHOT = 288613
    self.spells.BURSTING_SHOT = 186387
    self.spells.KILL_SHOT = 53351
    self.spells.VOLLEY = 260243
    self.spells.EXPLOSIVE_SHOT = 212431
    self.spells.PIERCING_SHOT = 198670
    self.spells.SERPENT_STING = 271788
    self.spells.DOUBLE_TAP = 260402
    self.spells.CHIMAERA_SHOT = 342049
    self.spells.BARRAGE = 120360
    self.spells.TRICK_SHOTS = 257622
    
    -- Setup cooldown and aura tracking for Marksmanship
    WR.Cooldown:StartTracking(self.spells.AIMED_SHOT)
    WR.Cooldown:StartTracking(self.spells.RAPID_FIRE)
    WR.Cooldown:StartTracking(self.spells.TRUESHOT)
    WR.Cooldown:StartTracking(self.spells.BURSTING_SHOT)
    WR.Cooldown:StartTracking(self.spells.VOLLEY)
    WR.Cooldown:StartTracking(self.spells.DOUBLE_TAP)
    
    -- Track important buffs/debuffs
    WR.Auras:RegisterImportantAura(self.spells.TRUESHOT, 90, true, false)
    WR.Auras:RegisterImportantAura(self.spells.TRICK_SHOTS, 80, true, false)
    WR.Auras:RegisterImportantAura(260395, 85, true, false) -- Precise Shots buff
    WR.Auras:RegisterImportantAura(194594, 70, true, false) -- Lock and Load buff
    
    -- Define Marksmanship rotation, prioritizing abilities in order
    self.singleTargetRotation = {
        -- Use Trueshot on cooldown
        { spell = self.spells.TRUESHOT },
        
        -- Use Double Tap if talented
        { 
            spell = self.spells.DOUBLE_TAP,
            condition = function(self)
                return IsSpellKnown(self.spells.DOUBLE_TAP)
            end
        },
        
        -- Use covenant abilities
        { 
            spell = self.spells.WILD_SPIRITS,
            condition = function(self) return IsSpellKnown(self.spells.WILD_SPIRITS) end
        },
        { 
            spell = self.spells.RESONATING_ARROW,
            condition = function(self) return IsSpellKnown(self.spells.RESONATING_ARROW) end
        },
        { 
            spell = self.spells.DEATH_CHAKRAM,
            condition = function(self) return IsSpellKnown(self.spells.DEATH_CHAKRAM) end
        },
        { 
            spell = self.spells.FLAYED_SHOT,
            condition = function(self) return IsSpellKnown(self.spells.FLAYED_SHOT) end
        },
        
        -- Use Kill Shot on targets below 20% health
        {
            spell = self.spells.KILL_SHOT,
            condition = function(self) 
                return self:TargetInExecuteRange() and 
                       IsSpellKnown(self.spells.KILL_SHOT)
            end
        },
        
        -- Use Aimed Shot with Lock and Load proc
        {
            spell = self.spells.AIMED_SHOT,
            condition = function(self)
                return self:HasBuff(194594) -- Lock and Load proc
            end
        },
        
        -- Use Aimed Shot when not moving
        {
            spell = self.spells.AIMED_SHOT,
            condition = function(self)
                return not WR.API:IsPlayerMoving() and
                       not self:HasBuff(260395) -- Don't cast if we have Precise Shots
            end
        },
        
        -- Use Rapid Fire
        { spell = self.spells.RAPID_FIRE },
        
        -- Use Chimaera Shot if talented
        {
            spell = self.spells.CHIMAERA_SHOT,
            condition = function(self)
                return IsSpellKnown(self.spells.CHIMAERA_SHOT)
            end
        },
        
        -- Use Arcane Shot with Precise Shots buff
        {
            spell = self.spells.ARCANE_SHOT,
            condition = function(self)
                return self:HasBuff(260395) -- Precise Shots buff
            end
        },
        
        -- Use Serpent Sting if talented and not already applied
        {
            spell = self.spells.SERPENT_STING,
            condition = function(self)
                return IsSpellKnown(self.spells.SERPENT_STING) and
                       not self:HasDebuff(self.spells.SERPENT_STING)
            end
        },
        
        -- Use Explosive Shot if talented
        {
            spell = self.spells.EXPLOSIVE_SHOT,
            condition = function(self)
                return IsSpellKnown(self.spells.EXPLOSIVE_SHOT)
            end
        },
        
        -- Use Barrage if talented
        {
            spell = self.spells.BARRAGE,
            condition = function(self)
                return IsSpellKnown(self.spells.BARRAGE)
            end
        },
        
        -- Use Arcane Shot as filler
        { spell = self.spells.ARCANE_SHOT },
        
        -- Use Steady Shot if low on focus or moving
        {
            spell = self.spells.STEADY_SHOT,
            condition = function(self)
                return self:GetResourcePct() < 30 or WR.API:IsPlayerMoving()
            end
        }
    }
    
    -- Define AoE rotation for Marksmanship
    self.aoeRotation = {
        -- Use Trueshot on cooldown
        { spell = self.spells.TRUESHOT },
        
        -- Use Double Tap if talented
        { 
            spell = self.spells.DOUBLE_TAP,
            condition = function(self)
                return IsSpellKnown(self.spells.DOUBLE_TAP)
            end
        },
        
        -- Use covenant abilities
        { 
            spell = self.spells.WILD_SPIRITS,
            condition = function(self) return IsSpellKnown(self.spells.WILD_SPIRITS) end
        },
        { 
            spell = self.spells.RESONATING_ARROW,
            condition = function(self) return IsSpellKnown(self.spells.RESONATING_ARROW) end
        },
        { 
            spell = self.spells.DEATH_CHAKRAM,
            condition = function(self) return IsSpellKnown(self.spells.DEATH_CHAKRAM) end
        },
        { 
            spell = self.spells.FLAYED_SHOT,
            condition = function(self) return IsSpellKnown(self.spells.FLAYED_SHOT) end
        },
        
        -- Use Volley if talented
        {
            spell = self.spells.VOLLEY,
            condition = function(self)
                return IsSpellKnown(self.spells.VOLLEY)
            end
        },
        
        -- Use Explosive Shot if talented
        {
            spell = self.spells.EXPLOSIVE_SHOT,
            condition = function(self)
                return IsSpellKnown(self.spells.EXPLOSIVE_SHOT)
            end
        },
        
        -- Use Barrage if talented
        {
            spell = self.spells.BARRAGE,
            condition = function(self)
                return IsSpellKnown(self.spells.BARRAGE)
            end
        },
        
        -- Use Multishot to activate Trick Shots if not active
        {
            spell = self.spells.MULTISHOT,
            condition = function(self)
                return not self:HasBuff(self.spells.TRICK_SHOTS) and
                       self:GetResourcePct() >= 20
            end
        },
        
        -- Use Aimed Shot with Trick Shots active
        {
            spell = self.spells.AIMED_SHOT,
            condition = function(self)
                return self:HasBuff(self.spells.TRICK_SHOTS) and
                       not WR.API:IsPlayerMoving()
            end
        },
        
        -- Use Rapid Fire with Trick Shots active
        {
            spell = self.spells.RAPID_FIRE,
            condition = function(self)
                return self:HasBuff(self.spells.TRICK_SHOTS)
            end
        },
        
        -- Use Bursting Shot for CC in AoE
        { spell = self.spells.BURSTING_SHOT },
        
        -- Use Multishot as filler in AoE
        {
            spell = self.spells.MULTISHOT,
            condition = function(self)
                return self:GetResourcePct() >= 20
            end
        },
        
        -- Use Steady Shot if low on focus
        {
            spell = self.spells.STEADY_SHOT,
            condition = function(self)
                return self:GetResourcePct() < 30
            end
        }
    }
    
    -- Define burst rotation
    self.burstRotation = {
        { spell = self.spells.TRUESHOT },
        { 
            spell = self.spells.DOUBLE_TAP,
            condition = function(self) return IsSpellKnown(self.spells.DOUBLE_TAP) end
        },
        { 
            spell = self.spells.WILD_SPIRITS,
            condition = function(self) return IsSpellKnown(self.spells.WILD_SPIRITS) end
        },
        { 
            spell = self.spells.RESONATING_ARROW,
            condition = function(self) return IsSpellKnown(self.spells.RESONATING_ARROW) end
        },
        { 
            spell = self.spells.VOLLEY,
            condition = function(self) return IsSpellKnown(self.spells.VOLLEY) end
        }
    }
end

-- Load Survival specialization
function Hunter:LoadSurvivalSpec()
    -- Survival-specific spells
    self.spells.CARVE = 187708
    self.spells.WILDFIRE_BOMB = 259495
    self.spells.RAPTOR_STRIKE = 186270
    self.spells.KILL_COMMAND = 259489
    self.spells.MONGOOSE_BITE = 259387
    self.spells.FLANKING_STRIKE = 269751
    self.spells.COORDINATED_ASSAULT = 266779
    self.spells.BUTCHERY = 212436
    self.spells.SERPENT_STING = 259491
    self.spells.STEEL_TRAP = 162488
    self.spells.WING_CLIP = 195645
    self.spells.CHAKRAMS = 259391
    self.spells.BIRDS_OF_PREY = 260331
    self.spells.HARPOON = 190925
    self.spells.TERMS_OF_ENGAGEMENT = 265895
    self.spells.TIP_OF_THE_SPEAR = 260286
    self.spells.WILDFIRE_INFUSION = 271014
    self.spells.ASPECT_OF_THE_EAGLE = 186289
    self.spells.KILL_SHOT = 320976
    self.spells.MUZZLE = 187707
    
    -- Setup cooldown and aura tracking for Survival
    WR.Cooldown:StartTracking(self.spells.WILDFIRE_BOMB)
    WR.Cooldown:StartTracking(self.spells.KILL_COMMAND)
    WR.Cooldown:StartTracking(self.spells.COORDINATED_ASSAULT)
    WR.Cooldown:StartTracking(self.spells.BUTCHERY)
    WR.Cooldown:StartTracking(self.spells.FLANKING_STRIKE)
    WR.Cooldown:StartTracking(self.spells.ASPECT_OF_THE_EAGLE)
    WR.Cooldown:StartTracking(self.spells.HARPOON)
    
    -- Track important buffs/debuffs
    WR.Auras:RegisterImportantAura(self.spells.COORDINATED_ASSAULT, 90, true, false)
    WR.Auras:RegisterImportantAura(self.spells.TIP_OF_THE_SPEAR, 70, true, false)
    WR.Auras:RegisterImportantAura(self.spells.TERMS_OF_ENGAGEMENT, 60, true, false)
    WR.Auras:RegisterImportantAura(259388, 85, true, false) -- Mongoose Fury buff
    
    -- Set up interrupt rotation specific to Survival
    self.interruptRotation = {
        { spell = self.spells.MUZZLE }
    }
    
    -- Define Survival rotation, prioritizing abilities in order
    self.singleTargetRotation = {
        -- Use Coordinated Assault on cooldown
        { spell = self.spells.COORDINATED_ASSAULT },
        
        -- Use Aspect of the Eagle for burst
        { 
            spell = self.spells.ASPECT_OF_THE_EAGLE,
            condition = function(self)
                return self:HasBuff(self.spells.COORDINATED_ASSAULT)
            end
        },
        
        -- Use covenant abilities
        { 
            spell = self.spells.WILD_SPIRITS,
            condition = function(self) return IsSpellKnown(self.spells.WILD_SPIRITS) end
        },
        { 
            spell = self.spells.RESONATING_ARROW,
            condition = function(self) return IsSpellKnown(self.spells.RESONATING_ARROW) end
        },
        { 
            spell = self.spells.DEATH_CHAKRAM,
            condition = function(self) return IsSpellKnown(self.spells.DEATH_CHAKRAM) end
        },
        { 
            spell = self.spells.FLAYED_SHOT,
            condition = function(self) return IsSpellKnown(self.spells.FLAYED_SHOT) end
        },
        
        -- Use Kill Shot on targets below 20% health
        {
            spell = self.spells.KILL_SHOT,
            condition = function(self) 
                return self:TargetInExecuteRange() and 
                       IsSpellKnown(self.spells.KILL_SHOT)
            end
        },
        
        -- Apply Serpent Sting if not active
        {
            spell = self.spells.SERPENT_STING,
            condition = function(self)
                return not self:HasDebuff(self.spells.SERPENT_STING)
            end
        },
        
        -- Use Wildfire Bomb on cooldown
        { spell = self.spells.WILDFIRE_BOMB },
        
        -- Use Kill Command on cooldown
        { 
            spell = self.spells.KILL_COMMAND,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.KILL_COMMAND) and
                       self:GetResource() >= 30
            end
        },
        
        -- Use Flanking Strike if talented
        {
            spell = self.spells.FLANKING_STRIKE,
            condition = function(self)
                return IsSpellKnown(self.spells.FLANKING_STRIKE)
            end
        },
        
        -- Use Steel Trap if talented
        {
            spell = self.spells.STEEL_TRAP,
            condition = function(self)
                return IsSpellKnown(self.spells.STEEL_TRAP)
            end
        },
        
        -- Use Chakrams if talented
        {
            spell = self.spells.CHAKRAMS,
            condition = function(self)
                return IsSpellKnown(self.spells.CHAKRAMS)
            end
        },
        
        -- Use Mongoose Bite if talented
        {
            spell = self.spells.MONGOOSE_BITE,
            condition = function(self)
                return IsSpellKnown(self.spells.MONGOOSE_BITE) and self:GetResource() >= 30
            end
        },
        
        -- Use Raptor Strike as filler
        {
            spell = self.spells.RAPTOR_STRIKE,
            condition = function(self)
                return not IsSpellKnown(self.spells.MONGOOSE_BITE) and self:GetResource() >= 30
            end
        }
    }
    
    -- Define AoE rotation for Survival
    self.aoeRotation = {
        -- Use Coordinated Assault on cooldown
        { spell = self.spells.COORDINATED_ASSAULT },
        
        -- Use covenant abilities
        { 
            spell = self.spells.WILD_SPIRITS,
            condition = function(self) return IsSpellKnown(self.spells.WILD_SPIRITS) end
        },
        { 
            spell = self.spells.RESONATING_ARROW,
            condition = function(self) return IsSpellKnown(self.spells.RESONATING_ARROW) end
        },
        { 
            spell = self.spells.DEATH_CHAKRAM,
            condition = function(self) return IsSpellKnown(self.spells.DEATH_CHAKRAM) end
        },
        { 
            spell = self.spells.FLAYED_SHOT,
            condition = function(self) return IsSpellKnown(self.spells.FLAYED_SHOT) end
        },
        
        -- Use Wildfire Bomb on cooldown
        { spell = self.spells.WILDFIRE_BOMB },
        
        -- Use Butchery if talented
        {
            spell = self.spells.BUTCHERY,
            condition = function(self)
                return IsSpellKnown(self.spells.BUTCHERY) and self:GetResource() >= 30
            end
        },
        
        -- Use Chakrams if talented
        {
            spell = self.spells.CHAKRAMS,
            condition = function(self)
                return IsSpellKnown(self.spells.CHAKRAMS)
            end
        },
        
        -- Use Carve for AoE
        {
            spell = self.spells.CARVE,
            condition = function(self)
                return not IsSpellKnown(self.spells.BUTCHERY) and self:GetResource() >= 30
            end
        },
        
        -- Use Kill Command on cooldown
        { 
            spell = self.spells.KILL_COMMAND,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.KILL_COMMAND) and
                       self:GetResource() >= 30
            end
        },
        
        -- Apply Serpent Sting if not active
        {
            spell = self.spells.SERPENT_STING,
            condition = function(self)
                return not self:HasDebuff(self.spells.SERPENT_STING) and
                       not IsSpellKnown(self.spells.BUTCHERY) -- Skip if we have Butchery
            end
        },
        
        -- Use Mongoose Bite if talented and Mongoose Fury is active
        {
            spell = self.spells.MONGOOSE_BITE,
            condition = function(self)
                return IsSpellKnown(self.spells.MONGOOSE_BITE) and 
                       self:HasBuff(259388) and -- Mongoose Fury
                       self:GetResource() >= 30
            end
        }
    }
    
    -- Define burst rotation
    self.burstRotation = {
        { spell = self.spells.COORDINATED_ASSAULT },
        { spell = self.spells.ASPECT_OF_THE_EAGLE },
        { 
            spell = self.spells.WILD_SPIRITS,
            condition = function(self) return IsSpellKnown(self.spells.WILD_SPIRITS) end
        },
        { 
            spell = self.spells.RESONATING_ARROW,
            condition = function(self) return IsSpellKnown(self.spells.RESONATING_ARROW) end
        },
        { 
            spell = self.spells.DEATH_CHAKRAM,
            condition = function(self) return IsSpellKnown(self.spells.DEATH_CHAKRAM) end
        },
        { 
            spell = self.spells.FLAYED_SHOT,
            condition = function(self) return IsSpellKnown(self.spells.FLAYED_SHOT) end
        },
        { spell = self.spells.WILDFIRE_BOMB }
    }
end

-- Class-specific pre-rotation checks
function Hunter:ClassSpecificChecks()
    -- Check for class-specific conditions
    
    -- Summon pet if we don't have one (except for Lone Wolf Marksmanship)
    if not UnitExists("pet") and 
       (self.currentSpec ~= SPEC_MARKSMANSHIP or
        (self.currentSpec == SPEC_MARKSMANSHIP and not self:HasTalent("Lone Wolf"))) then
        WR.Queue:Add(self.spells.CALL_PET_1)
        return false
    end
    
    -- Use Mend Pet if pet is below 50% health and in combat
    if UnitExists("pet") and self:InCombat() and 
       (UnitHealth("pet") / UnitHealthMax("pet") * 100) < 50 and
       not self:SpellOnCooldown(self.spells.MEND_PET) then
        WR.Queue:Add(self.spells.MEND_PET)
        return false
    end
    
    return true
end

-- Get default action when nothing else is available
function Hunter:GetDefaultAction()
    if self.currentSpec == SPEC_BEAST_MASTERY then
        return self.spells.COBRA_SHOT
    elseif self.currentSpec == SPEC_MARKSMANSHIP then
        return self.spells.STEADY_SHOT
    elseif self.currentSpec == SPEC_SURVIVAL then
        return self.spells.RAPTOR_STRIKE
    end
    
    return nil
end

-- Initialize the module
Hunter:Initialize()

return Hunter