local addonName, WR = ...

-- Warlock Class module
local Warlock = {}
WR.Classes = WR.Classes or {}
WR.Classes.WARLOCK = Warlock

-- Inherit from BaseClass
setmetatable(Warlock, {__index = WR.BaseClass})

-- Resource type for Warlocks (Mana with Soul Shards)
Warlock.resourceType = Enum.PowerType.Mana
Warlock.secondaryResourceType = Enum.PowerType.SoulShards

-- Define spec IDs
local SPEC_AFFLICTION = 265
local SPEC_DEMONOLOGY = 266
local SPEC_DESTRUCTION = 267

-- Class initialization
function Warlock:Initialize()
    -- Inherit base initialization
    WR.BaseClass.Initialize(self)
    
    -- Register Specializations
    self:RegisterSpec(SPEC_AFFLICTION, "Affliction")
    self:RegisterSpec(SPEC_DEMONOLOGY, "Demonology")
    self:RegisterSpec(SPEC_DESTRUCTION, "Destruction")
    
    -- Shared spell IDs across all warlock specs
    self.spells = {
        -- Core warlock spells
        SHADOW_BOLT = 686,
        CORRUPTION = 172,
        FEAR = 5782,
        DRAIN_LIFE = 234153,
        UNENDING_RESOLVE = 104773,
        DARK_PACT = 108416,
        HEALTHSTONE = 6262,
        CREATE_HEALTHSTONE = 6201,
        DEMONIC_CIRCLE = 48018,
        DEMONIC_CIRCLE_TELEPORT = 48020,
        DEMONIC_GATEWAY = 111771,
        SUMMON_IMP = 688,
        SUMMON_VOIDWALKER = 697,
        SUMMON_FELHUNTER = 691,
        SUMMON_SUCCUBUS = 712,
        SUMMON_FELGUARD = 30146,
        BANISH = 710,
        SHADOWFURY = 30283,
        SOUL_STONE = 20707,
        BURNING_RUSH = 111400,
        DARK_PACT = 108416,
        SOULWELL = 29893,
        RITUAL_OF_SUMMONING = 698,
        COMMAND_DEMON = 119898,
        SUBJUGATE_DEMON = 1098,
        GRIMOIRE_OF_SACRIFICE = 108503,
        LIFE_TAP = 1454,
        HAVOC = 80240,
        
        -- Covenant abilities
        SCOURING_TITHE = 312321,    -- Kyrian
        IMPENDING_CATASTROPHE = 321792,  -- Venthyr
        SOUL_ROT = 325640,          -- Night Fae
        DECIMATING_BOLT = 325289    -- Necrolord
    }
    
    -- Load shared warlock data
    self:LoadSharedWarlockData()
    
    WR:Debug("Warlock module initialized")
end

-- Load shared spell and mechanics data for all warlock specs
function Warlock:LoadSharedWarlockData()
    -- Register important buffs
    WR.Auras:RegisterImportantAura(self.spells.CORRUPTION, 80, false, true)
    WR.Auras:RegisterImportantAura(self.spells.UNENDING_RESOLVE, 90, true, false)
    WR.Auras:RegisterImportantAura(self.spells.DARK_PACT, 85, true, false)
    WR.Auras:RegisterImportantAura(self.spells.BURNING_RUSH, 70, true, false)
    
    -- Setup cooldown tracking
    WR.Cooldown:StartTracking(self.spells.FEAR)
    WR.Cooldown:StartTracking(self.spells.UNENDING_RESOLVE)
    WR.Cooldown:StartTracking(self.spells.DARK_PACT)
    WR.Cooldown:StartTracking(self.spells.DEMONIC_CIRCLE)
    WR.Cooldown:StartTracking(self.spells.DEMONIC_CIRCLE_TELEPORT)
    WR.Cooldown:StartTracking(self.spells.DEMONIC_GATEWAY)
    WR.Cooldown:StartTracking(self.spells.SHADOWFURY)
    WR.Cooldown:StartTracking(self.spells.SOUL_STONE)
    WR.Cooldown:StartTracking(self.spells.BURNING_RUSH)
    WR.Cooldown:StartTracking(self.spells.HAVOC)
    
    -- Set up defensive rotation (shared by all specs)
    self.defensiveRotation = {
        { spell = self.spells.UNENDING_RESOLVE, threshold = 35 },
        {
            spell = self.spells.DARK_PACT,
            threshold = 60,
            condition = function(self)
                return IsSpellKnown(self.spells.DARK_PACT)
            end
        },
        {
            spell = self.spells.DRAIN_LIFE,
            threshold = 40,
            condition = function(self)
                return self:GetHealthPct() < 40 and
                       self:GetMana() >= 10000
            end
        },
        {
            spell = self.spells.HEALTHSTONE,
            threshold = 30,
            condition = function(self)
                return GetItemCount(5512) > 0
            end
        }
    }
end

-- Load a specific specialization
function Warlock:LoadSpec(specId)
    -- Call the base class method to set up common components
    WR.BaseClass.LoadSpec(self, specId)
    
    -- Set the resource type based on spec
    if specId == SPEC_AFFLICTION then
        self.resourceType = Enum.PowerType.Mana
        self.secondaryResourceType = Enum.PowerType.SoulShards
    elseif specId == SPEC_DEMONOLOGY then
        self.resourceType = Enum.PowerType.Mana
        self.secondaryResourceType = Enum.PowerType.SoulShards
    elseif specId == SPEC_DESTRUCTION then
        self.resourceType = Enum.PowerType.Mana
        self.secondaryResourceType = Enum.PowerType.SoulShards
    end
    
    -- Load specific spec data
    if specId == SPEC_AFFLICTION then
        self:LoadAfflictionSpec()
    elseif specId == SPEC_DEMONOLOGY then
        self:LoadDemonologySpec()
    elseif specId == SPEC_DESTRUCTION then
        self:LoadDestructionSpec()
    end
    
    WR:Debug("Loaded warlock spec:", self.specData.name)
    return true
end

-- Load Affliction specialization
function Warlock:LoadAfflictionSpec()
    -- Affliction-specific spells
    self.spells.AGONY = 980
    self.spells.UNSTABLE_AFFLICTION = 316099
    self.spells.SUMMON_DARKGLARE = 205180
    self.spells.MALEFIC_RAPTURE = 324536
    self.spells.PHANTOM_SINGULARITY = 205179
    self.spells.VILE_TAINT = 278350
    self.spells.SEED_OF_CORRUPTION = 27243
    self.spells.HAUNT = 48181
    self.spells.DRAIN_SOUL = 198590
    self.spells.DARK_SOUL_MISERY = 113860
    self.spells.SIPHON_LIFE = 63106
    self.spells.ABSOLUTE_CORRUPTION = 196103
    self.spells.CREEPING_DEATH = 264000
    self.spells.SHADOW_EMBRACE = 32388
    self.spells.SIPHON_LIFE = 63106
    self.spells.INEVITABLE_DEMISE = 334319
    self.spells.NIGHTFALL = 108558
    self.spells.WRITHE_IN_AGONY = 196102
    self.spells.SHADOW_EMBRACE = 32388
    self.spells.DEMONIC_STRENGTH = 267171
    self.spells.DOOM = 603
    
    -- Setup cooldown and aura tracking for Affliction
    WR.Cooldown:StartTracking(self.spells.SUMMON_DARKGLARE)
    WR.Cooldown:StartTracking(self.spells.PHANTOM_SINGULARITY)
    WR.Cooldown:StartTracking(self.spells.VILE_TAINT)
    WR.Cooldown:StartTracking(self.spells.HAUNT)
    WR.Cooldown:StartTracking(self.spells.DARK_SOUL_MISERY)
    
    -- Track important buffs/debuffs
    WR.Auras:RegisterImportantAura(self.spells.AGONY, 95, false, true)
    WR.Auras:RegisterImportantAura(self.spells.CORRUPTION, 90, false, true)
    WR.Auras:RegisterImportantAura(self.spells.UNSTABLE_AFFLICTION, 95, false, true)
    WR.Auras:RegisterImportantAura(self.spells.PHANTOM_SINGULARITY, 85, false, true)
    WR.Auras:RegisterImportantAura(self.spells.VILE_TAINT, 85, false, true)
    WR.Auras:RegisterImportantAura(self.spells.HAUNT, 85, false, true)
    WR.Auras:RegisterImportantAura(self.spells.SHADOW_EMBRACE, 80, false, true)
    WR.Auras:RegisterImportantAura(self.spells.SIPHON_LIFE, 85, false, true)
    WR.Auras:RegisterImportantAura(self.spells.DARK_SOUL_MISERY, 90, true, false)
    WR.Auras:RegisterImportantAura(self.spells.INEVITABLE_DEMISE, 85, true, false)
    WR.Auras:RegisterImportantAura(self.spells.NIGHTFALL, 80, true, false)
    
    -- Set interrupt ability
    self.interruptRotation = {
        {
            spell = self.spells.COMMAND_DEMON,
            condition = function(self)
                return self:HasActivePet() and self:GetPetType() == "felhunter"
            end
        }
    }
    
    -- Define Affliction single target rotation
    self.singleTargetRotation = {
        -- Maintain DoTs - Agony
        {
            spell = self.spells.AGONY,
            condition = function(self)
                return not self:HasDebuff(self.spells.AGONY) or
                       self:GetDebuffRemaining(self.spells.AGONY) < 5
            end
        },
        
        -- Maintain DoTs - Corruption (unless Absolute Corruption talented)
        {
            spell = self.spells.CORRUPTION,
            condition = function(self)
                return (not self:HasDebuff(self.spells.CORRUPTION) or
                        self:GetDebuffRemaining(self.spells.CORRUPTION) < 5) and
                       not IsSpellKnown(self.spells.ABSOLUTE_CORRUPTION)
            end
        },
        
        -- Maintain DoTs - Unstable Affliction
        {
            spell = self.spells.UNSTABLE_AFFLICTION,
            condition = function(self)
                return not self:HasDebuff(self.spells.UNSTABLE_AFFLICTION) or
                       self:GetDebuffRemaining(self.spells.UNSTABLE_AFFLICTION) < 5
            end
        },
        
        -- Maintain DoTs - Siphon Life if talented
        {
            spell = self.spells.SIPHON_LIFE,
            condition = function(self)
                return IsSpellKnown(self.spells.SIPHON_LIFE) and
                       (not self:HasDebuff(self.spells.SIPHON_LIFE) or
                        self:GetDebuffRemaining(self.spells.SIPHON_LIFE) < 5)
            end
        },
        
        -- Use Dark Soul: Misery for major cooldown
        {
            spell = self.spells.DARK_SOUL_MISERY,
            condition = function(self)
                return IsSpellKnown(self.spells.DARK_SOUL_MISERY) and
                       not self:SpellOnCooldown(self.spells.DARK_SOUL_MISERY)
            end
        },
        
        -- Use Summon Darkglare with Dark Soul and fully dotted target
        {
            spell = self.spells.SUMMON_DARKGLARE,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.SUMMON_DARKGLARE) and
                       self:HasDebuff(self.spells.AGONY) and
                       self:HasDebuff(self.spells.CORRUPTION) and
                       self:HasDebuff(self.spells.UNSTABLE_AFFLICTION) and
                       (self:HasBuff(self.spells.DARK_SOUL_MISERY) or
                        self:SpellOnCooldown(self.spells.DARK_SOUL_MISERY))
            end
        },
        
        -- Use covenant abilities
        { 
            spell = self.spells.SOUL_ROT,
            condition = function(self) return IsSpellKnown(self.spells.SOUL_ROT) end
        },
        { 
            spell = self.spells.SCOURING_TITHE,
            condition = function(self) return IsSpellKnown(self.spells.SCOURING_TITHE) end
        },
        { 
            spell = self.spells.IMPENDING_CATASTROPHE,
            condition = function(self) return IsSpellKnown(self.spells.IMPENDING_CATASTROPHE) end
        },
        { 
            spell = self.spells.DECIMATING_BOLT,
            condition = function(self) return IsSpellKnown(self.spells.DECIMATING_BOLT) end
        },
        
        -- Use Phantom Singularity if talented
        {
            spell = self.spells.PHANTOM_SINGULARITY,
            condition = function(self)
                return IsSpellKnown(self.spells.PHANTOM_SINGULARITY) and
                       not self:SpellOnCooldown(self.spells.PHANTOM_SINGULARITY)
            end
        },
        
        -- Use Vile Taint if talented
        {
            spell = self.spells.VILE_TAINT,
            condition = function(self)
                return IsSpellKnown(self.spells.VILE_TAINT) and
                       not self:SpellOnCooldown(self.spells.VILE_TAINT) and
                       self:GetSoulShards() >= 1
            end
        },
        
        -- Use Haunt if talented
        {
            spell = self.spells.HAUNT,
            condition = function(self)
                return IsSpellKnown(self.spells.HAUNT) and
                       not self:SpellOnCooldown(self.spells.HAUNT) and
                       self:GetSoulShards() >= 1
            end
        },
        
        -- Use Malefic Rapture as Soul Shard spender
        {
            spell = self.spells.MALEFIC_RAPTURE,
            condition = function(self)
                return self:GetSoulShards() >= 1 and
                       self:HasDebuff(self.spells.AGONY) and
                       self:HasDebuff(self.spells.CORRUPTION) and
                       self:HasDebuff(self.spells.UNSTABLE_AFFLICTION)
            end
        },
        
        -- Use Drain Soul as filler (also generates Soul Shards)
        {
            spell = self.spells.DRAIN_SOUL,
            condition = function(self)
                return IsSpellKnown(self.spells.DRAIN_SOUL)
            end
        },
        
        -- Use Shadow Bolt as filler if Drain Soul not available
        {
            spell = self.spells.SHADOW_BOLT,
            condition = function(self)
                return not IsSpellKnown(self.spells.DRAIN_SOUL)
            end
        }
    }
    
    -- AoE rotation for Affliction
    self.aoeRotation = {
        -- Use Seed of Corruption for AoE
        {
            spell = self.spells.SEED_OF_CORRUPTION,
            condition = function(self)
                return self:GetEnemyCount(10) >= 3 and
                       self:GetSoulShards() >= 1 and
                       not self:HasDebuff(self.spells.SEED_OF_CORRUPTION)
            end
        },
        
        -- Apply Agony to multiple targets
        {
            spell = self.spells.AGONY,
            condition = function(self)
                return not self:HasDebuff(self.spells.AGONY) or
                       self:GetDebuffRemaining(self.spells.AGONY) < 5
            end
        },
        
        -- Apply Corruption to multiple targets (unless Absolute Corruption talented)
        {
            spell = self.spells.CORRUPTION,
            condition = function(self)
                return (not self:HasDebuff(self.spells.CORRUPTION) or
                        self:GetDebuffRemaining(self.spells.CORRUPTION) < 5) and
                       not IsSpellKnown(self.spells.ABSOLUTE_CORRUPTION)
            end
        },
        
        -- Use covenant abilities for AoE
        { 
            spell = self.spells.SOUL_ROT,
            condition = function(self) return IsSpellKnown(self.spells.SOUL_ROT) end
        },
        { 
            spell = self.spells.IMPENDING_CATASTROPHE,
            condition = function(self) return IsSpellKnown(self.spells.IMPENDING_CATASTROPHE) end
        },
        
        -- Use Dark Soul: Misery for cooldown
        {
            spell = self.spells.DARK_SOUL_MISERY,
            condition = function(self)
                return IsSpellKnown(self.spells.DARK_SOUL_MISERY) and
                       not self:SpellOnCooldown(self.spells.DARK_SOUL_MISERY) and
                       self:GetEnemyCount(10) >= 3
            end
        },
        
        -- Use Summon Darkglare with Dark Soul for AoE burst
        {
            spell = self.spells.SUMMON_DARKGLARE,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.SUMMON_DARKGLARE) and
                       (self:HasBuff(self.spells.DARK_SOUL_MISERY) or
                        self:SpellOnCooldown(self.spells.DARK_SOUL_MISERY))
            end
        },
        
        -- Use Phantom Singularity for AoE
        {
            spell = self.spells.PHANTOM_SINGULARITY,
            condition = function(self)
                return IsSpellKnown(self.spells.PHANTOM_SINGULARITY) and
                       not self:SpellOnCooldown(self.spells.PHANTOM_SINGULARITY)
            end
        },
        
        -- Use Vile Taint for AoE if talented
        {
            spell = self.spells.VILE_TAINT,
            condition = function(self)
                return IsSpellKnown(self.spells.VILE_TAINT) and
                       not self:SpellOnCooldown(self.spells.VILE_TAINT) and
                       self:GetSoulShards() >= 1
            end
        },
        
        -- Use Malefic Rapture as Soul Shard spender for AoE
        {
            spell = self.spells.MALEFIC_RAPTURE,
            condition = function(self)
                return self:GetSoulShards() >= 1 and
                       self:GetEnemyCount(10) >= 3
            end
        },
        
        -- Use Drain Soul as filler on priority target
        {
            spell = self.spells.DRAIN_SOUL,
            condition = function(self)
                return IsSpellKnown(self.spells.DRAIN_SOUL)
            end
        },
        
        -- Fallback to Shadow Bolt
        { spell = self.spells.SHADOW_BOLT }
    }
    
    -- Define burst rotation
    self.burstRotation = {
        {
            spell = self.spells.DARK_SOUL_MISERY,
            condition = function(self) return IsSpellKnown(self.spells.DARK_SOUL_MISERY) end
        },
        { spell = self.spells.SUMMON_DARKGLARE },
        { 
            spell = self.spells.SOUL_ROT,
            condition = function(self) return IsSpellKnown(self.spells.SOUL_ROT) end
        },
        { 
            spell = self.spells.IMPENDING_CATASTROPHE,
            condition = function(self) return IsSpellKnown(self.spells.IMPENDING_CATASTROPHE) end
        },
        {
            spell = self.spells.PHANTOM_SINGULARITY,
            condition = function(self) return IsSpellKnown(self.spells.PHANTOM_SINGULARITY) end
        },
        {
            spell = self.spells.VILE_TAINT,
            condition = function(self) return IsSpellKnown(self.spells.VILE_TAINT) end
        },
        {
            spell = self.spells.HAUNT,
            condition = function(self) return IsSpellKnown(self.spells.HAUNT) end
        }
    }
end

-- Load Demonology specialization
function Warlock:LoadDemonologySpec()
    -- Demonology-specific spells
    self.spells.CALL_DREADSTALKERS = 104316
    self.spells.HAND_OF_GULDAN = 105174
    self.spells.DEMONBOLT = 264178
    self.spells.SUMMON_DEMONIC_TYRANT = 265187
    self.spells.DOOM = 603
    self.spells.DEMONIC_STRENGTH = 267171
    self.spells.BILESCOURGE_BOMBERS = 267211
    self.spells.POWER_SIPHON = 264130
    self.spells.SOUL_STRIKE = 264057
    self.spells.SUMMON_VILEFIEND = 264119
    self.spells.NETHER_PORTAL = 267217
    self.spells.GRIMOIRE_FELGUARD = 111898
    self.spells.IMPLOSION = 196277
    self.spells.FROM_THE_SHADOWS = 267170
    self.spells.DEMONIC_CALLING = 205145
    self.spells.INNER_DEMONS = 267216
    self.spells.NETHERWARD = 212295
    self.spells.DEMONIC_CORE = 267102
    self.spells.SHADOW_BOLT = 686
    self.spells.DEMONBOLT = 264178
    self.spells.DEMONIC_TYRANT = 265187
    self.spells.SOUL_CONDUIT = 215941
    
    -- Setup cooldown and aura tracking for Demonology
    WR.Cooldown:StartTracking(self.spells.CALL_DREADSTALKERS)
    WR.Cooldown:StartTracking(self.spells.SUMMON_DEMONIC_TYRANT)
    WR.Cooldown:StartTracking(self.spells.DEMONIC_STRENGTH)
    WR.Cooldown:StartTracking(self.spells.BILESCOURGE_BOMBERS)
    WR.Cooldown:StartTracking(self.spells.POWER_SIPHON)
    WR.Cooldown:StartTracking(self.spells.SOUL_STRIKE)
    WR.Cooldown:StartTracking(self.spells.SUMMON_VILEFIEND)
    WR.Cooldown:StartTracking(self.spells.NETHER_PORTAL)
    WR.Cooldown:StartTracking(self.spells.GRIMOIRE_FELGUARD)
    
    -- Track important buffs/debuffs
    WR.Auras:RegisterImportantAura(self.spells.DEMONIC_CORE, 90, true, false)
    WR.Auras:RegisterImportantAura(self.spells.NETHER_PORTAL, 95, true, false)
    WR.Auras:RegisterImportantAura(self.spells.DEMONIC_CALLING, 80, true, false)
    WR.Auras:RegisterImportantAura(self.spells.DOOM, 85, false, true)
    WR.Auras:RegisterImportantAura(self.spells.FROM_THE_SHADOWS, 80, false, true)
    
    -- Set interrupt ability
    self.interruptRotation = {
        {
            spell = self.spells.COMMAND_DEMON,
            condition = function(self)
                return self:HasActivePet() and
                       (self:GetPetType() == "felhunter" or self:GetPetType() == "felguard")
            end
        }
    }
    
    -- Define Demonology single target rotation
    self.singleTargetRotation = {
        -- Apply Doom if talented
        {
            spell = self.spells.DOOM,
            condition = function(self)
                return IsSpellKnown(self.spells.DOOM) and
                       (not self:HasDebuff(self.spells.DOOM) or
                        self:GetDebuffRemaining(self.spells.DOOM) < 5)
            end
        },
        
        -- Use Summon Demonic Tyrant when we have demons active
        {
            spell = self.spells.SUMMON_DEMONIC_TYRANT,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.SUMMON_DEMONIC_TYRANT) and
                       not self:SpellOnCooldown(self.spells.CALL_DREADSTALKERS) and
                       self:GetActiveDemonCount() >= 3
            end
        },
        
        -- Use covenant abilities
        { 
            spell = self.spells.SOUL_ROT,
            condition = function(self) return IsSpellKnown(self.spells.SOUL_ROT) end
        },
        { 
            spell = self.spells.SCOURING_TITHE,
            condition = function(self) return IsSpellKnown(self.spells.SCOURING_TITHE) end
        },
        { 
            spell = self.spells.IMPENDING_CATASTROPHE,
            condition = function(self) return IsSpellKnown(self.spells.IMPENDING_CATASTROPHE) end
        },
        { 
            spell = self.spells.DECIMATING_BOLT,
            condition = function(self) return IsSpellKnown(self.spells.DECIMATING_BOLT) end
        },
        
        -- Use Grimoire: Felguard if talented
        {
            spell = self.spells.GRIMOIRE_FELGUARD,
            condition = function(self)
                return IsSpellKnown(self.spells.GRIMOIRE_FELGUARD) and
                       not self:SpellOnCooldown(self.spells.GRIMOIRE_FELGUARD)
            end
        },
        
        -- Use Summon Vilefiend if talented
        {
            spell = self.spells.SUMMON_VILEFIEND,
            condition = function(self)
                return IsSpellKnown(self.spells.SUMMON_VILEFIEND) and
                       not self:SpellOnCooldown(self.spells.SUMMON_VILEFIEND) and
                       self:GetSoulShards() >= 1
            end
        },
        
        -- Use Nether Portal if talented
        {
            spell = self.spells.NETHER_PORTAL,
            condition = function(self)
                return IsSpellKnown(self.spells.NETHER_PORTAL) and
                       not self:SpellOnCooldown(self.spells.NETHER_PORTAL) and
                       self:GetSoulShards() >= 1
            end
        },
        
        -- Call Dreadstalkers
        {
            spell = self.spells.CALL_DREADSTALKERS,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.CALL_DREADSTALKERS) and
                       self:GetSoulShards() >= 2
            end
        },
        
        -- Use Demonic Strength if talented
        {
            spell = self.spells.DEMONIC_STRENGTH,
            condition = function(self)
                return IsSpellKnown(self.spells.DEMONIC_STRENGTH) and
                       not self:SpellOnCooldown(self.spells.DEMONIC_STRENGTH) and
                       self:GetPetType() == "felguard"
            end
        },
        
        -- Use Bilescourge Bombers if talented
        {
            spell = self.spells.BILESCOURGE_BOMBERS,
            condition = function(self)
                return IsSpellKnown(self.spells.BILESCOURGE_BOMBERS) and
                       not self:SpellOnCooldown(self.spells.BILESCOURGE_BOMBERS) and
                       self:GetSoulShards() >= 2
            end
        },
        
        -- Use Power Siphon if talented and we need Demonic Core
        {
            spell = self.spells.POWER_SIPHON,
            condition = function(self)
                return IsSpellKnown(self.spells.POWER_SIPHON) and
                       not self:SpellOnCooldown(self.spells.POWER_SIPHON) and
                       not self:HasBuff(self.spells.DEMONIC_CORE) and
                       self:GetWildImpCount() >= 2
            end
        },
        
        -- Use Soul Strike if talented
        {
            spell = self.spells.SOUL_STRIKE,
            condition = function(self)
                return IsSpellKnown(self.spells.SOUL_STRIKE) and
                       not self:SpellOnCooldown(self.spells.SOUL_STRIKE)
            end
        },
        
        -- Use Hand of Gul'dan to spend Soul Shards
        {
            spell = self.spells.HAND_OF_GULDAN,
            condition = function(self)
                return self:GetSoulShards() >= 3
            end
        },
        
        -- Use Demonbolt with Demonic Core proc
        {
            spell = self.spells.DEMONBOLT,
            condition = function(self)
                return IsSpellKnown(self.spells.DEMONBOLT) and
                       self:HasBuff(self.spells.DEMONIC_CORE)
            end
        },
        
        -- Use Shadow Bolt as filler
        { spell = self.spells.SHADOW_BOLT }
    }
    
    -- AoE rotation for Demonology
    self.aoeRotation = {
        -- Use Summon Demonic Tyrant when we have demons active
        {
            spell = self.spells.SUMMON_DEMONIC_TYRANT,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.SUMMON_DEMONIC_TYRANT) and
                       not self:SpellOnCooldown(self.spells.CALL_DREADSTALKERS) and
                       self:GetActiveDemonCount() >= 3
            end
        },
        
        -- Use covenant abilities for AoE
        { 
            spell = self.spells.SOUL_ROT,
            condition = function(self) return IsSpellKnown(self.spells.SOUL_ROT) end
        },
        { 
            spell = self.spells.IMPENDING_CATASTROPHE,
            condition = function(self) return IsSpellKnown(self.spells.IMPENDING_CATASTROPHE) end
        },
        
        -- Use Bilescourge Bombers for AoE if talented
        {
            spell = self.spells.BILESCOURGE_BOMBERS,
            condition = function(self)
                return IsSpellKnown(self.spells.BILESCOURGE_BOMBERS) and
                       not self:SpellOnCooldown(self.spells.BILESCOURGE_BOMBERS) and
                       self:GetSoulShards() >= 2 and
                       self:GetEnemyCount(10) >= 3
            end
        },
        
        -- Use Call Dreadstalkers
        {
            spell = self.spells.CALL_DREADSTALKERS,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.CALL_DREADSTALKERS) and
                       self:GetSoulShards() >= 2
            end
        },
        
        -- Use Hand of Gul'dan for AoE
        {
            spell = self.spells.HAND_OF_GULDAN,
            condition = function(self)
                return self:GetSoulShards() >= 3
            end
        },
        
        -- Use Implosion for AoE when we have at least 4 wild imps
        {
            spell = self.spells.IMPLOSION,
            condition = function(self)
                return self:GetEnemyCount(10) >= 3 and
                       self:GetWildImpCount() >= 4
            end
        },
        
        -- Use Demonic Strength for AoE if talented
        {
            spell = self.spells.DEMONIC_STRENGTH,
            condition = function(self)
                return IsSpellKnown(self.spells.DEMONIC_STRENGTH) and
                       not self:SpellOnCooldown(self.spells.DEMONIC_STRENGTH) and
                       self:GetPetType() == "felguard" and
                       self:GetEnemyCount(10) >= 3
            end
        },
        
        -- Use Demonbolt with Demonic Core proc
        {
            spell = self.spells.DEMONBOLT,
            condition = function(self)
                return IsSpellKnown(self.spells.DEMONBOLT) and
                       self:HasBuff(self.spells.DEMONIC_CORE)
            end
        },
        
        -- Use Shadow Bolt as filler
        { spell = self.spells.SHADOW_BOLT }
    }
    
    -- Define burst rotation
    self.burstRotation = {
        {
            spell = self.spells.NETHER_PORTAL,
            condition = function(self) return IsSpellKnown(self.spells.NETHER_PORTAL) end
        },
        {
            spell = self.spells.GRIMOIRE_FELGUARD,
            condition = function(self) return IsSpellKnown(self.spells.GRIMOIRE_FELGUARD) end
        },
        {
            spell = self.spells.SUMMON_VILEFIEND,
            condition = function(self) return IsSpellKnown(self.spells.SUMMON_VILEFIEND) end
        },
        { spell = self.spells.CALL_DREADSTALKERS },
        { spell = self.spells.HAND_OF_GULDAN },
        { 
            spell = self.spells.SOUL_ROT,
            condition = function(self) return IsSpellKnown(self.spells.SOUL_ROT) end
        },
        { spell = self.spells.SUMMON_DEMONIC_TYRANT }
    }
end

-- Load Destruction specialization
function Warlock:LoadDestructionSpec()
    -- Destruction-specific spells
    self.spells.CHAOS_BOLT = 116858
    self.spells.INCINERATE = 29722
    self.spells.IMMOLATE = 348
    self.spells.CONFLAGRATE = 17962
    self.spells.RAIN_OF_FIRE = 5740
    self.spells.HAVOC = 80240
    self.spells.CHANNEL_DEMONFIRE = 196447
    self.spells.SOUL_FIRE = 6353
    self.spells.SUMMON_INFERNAL = 1122
    self.spells.DARK_SOUL_INSTABILITY = 113858
    self.spells.SHADOWBURN = 17877
    self.spells.CATACLYSM = 152108
    self.spells.FIRE_AND_BRIMSTONE = 196408
    self.spells.ERADICATION = 196412
    self.spells.INTERNAL_COMBUSTION = 266134
    self.spells.SOUL_CONDUIT = 215941
    self.spells.REVERSE_ENTROPY = 205148
    self.spells.GRIMOIRE_OF_SACRIFICE = 108503
    self.spells.BACKDRAFT = 196406
    self.spells.SHADOWBURN = 17877
    self.spells.ROARING_BLAZE = 205184
    self.spells.GRIMOIRE_OF_SUPREMACY = 266086
    
    -- Setup cooldown and aura tracking for Destruction
    WR.Cooldown:StartTracking(self.spells.CHAOS_BOLT)
    WR.Cooldown:StartTracking(self.spells.CONFLAGRATE)
    WR.Cooldown:StartTracking(self.spells.CHANNEL_DEMONFIRE)
    WR.Cooldown:StartTracking(self.spells.SOUL_FIRE)
    WR.Cooldown:StartTracking(self.spells.SUMMON_INFERNAL)
    WR.Cooldown:StartTracking(self.spells.DARK_SOUL_INSTABILITY)
    WR.Cooldown:StartTracking(self.spells.SHADOWBURN)
    WR.Cooldown:StartTracking(self.spells.CATACLYSM)
    WR.Cooldown:StartTracking(self.spells.HAVOC)
    
    -- Track important buffs/debuffs
    WR.Auras:RegisterImportantAura(self.spells.IMMOLATE, 95, false, true)
    WR.Auras:RegisterImportantAura(self.spells.BACKDRAFT, 85, true, false)
    WR.Auras:RegisterImportantAura(self.spells.DARK_SOUL_INSTABILITY, 90, true, false)
    WR.Auras:RegisterImportantAura(self.spells.ERADICATION, 85, false, true)
    WR.Auras:RegisterImportantAura(self.spells.GRIMOIRE_OF_SUPREMACY, 85, true, false)
    WR.Auras:RegisterImportantAura(self.spells.HAVOC, 85, false, true)
    
    -- Set interrupt ability
    self.interruptRotation = {
        {
            spell = self.spells.COMMAND_DEMON,
            condition = function(self)
                return self:HasActivePet() and self:GetPetType() == "felhunter"
            end
        }
    }
    
    -- Define Destruction single target rotation
    self.singleTargetRotation = {
        -- Maintain Immolate
        {
            spell = self.spells.IMMOLATE,
            condition = function(self)
                return not self:HasDebuff(self.spells.IMMOLATE) or
                       self:GetDebuffRemaining(self.spells.IMMOLATE) < 5
            end
        },
        
        -- Use Dark Soul: Instability for burst
        {
            spell = self.spells.DARK_SOUL_INSTABILITY,
            condition = function(self)
                return IsSpellKnown(self.spells.DARK_SOUL_INSTABILITY) and
                       not self:SpellOnCooldown(self.spells.DARK_SOUL_INSTABILITY)
            end
        },
        
        -- Use Summon Infernal for major cooldown
        {
            spell = self.spells.SUMMON_INFERNAL,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.SUMMON_INFERNAL) and
                       (self:HasBuff(self.spells.DARK_SOUL_INSTABILITY) or
                        self:SpellOnCooldown(self.spells.DARK_SOUL_INSTABILITY))
            end
        },
        
        -- Use covenant abilities
        { 
            spell = self.spells.SOUL_ROT,
            condition = function(self) return IsSpellKnown(self.spells.SOUL_ROT) end
        },
        { 
            spell = self.spells.SCOURING_TITHE,
            condition = function(self) return IsSpellKnown(self.spells.SCOURING_TITHE) end
        },
        { 
            spell = self.spells.IMPENDING_CATASTROPHE,
            condition = function(self) return IsSpellKnown(self.spells.IMPENDING_CATASTROPHE) end
        },
        { 
            spell = self.spells.DECIMATING_BOLT,
            condition = function(self) return IsSpellKnown(self.spells.DECIMATING_BOLT) end
        },
        
        -- Use Cataclysm if talented
        {
            spell = self.spells.CATACLYSM,
            condition = function(self)
                return IsSpellKnown(self.spells.CATACLYSM) and
                       not self:SpellOnCooldown(self.spells.CATACLYSM)
            end
        },
        
        -- Use Channel Demonfire if talented
        {
            spell = self.spells.CHANNEL_DEMONFIRE,
            condition = function(self)
                return IsSpellKnown(self.spells.CHANNEL_DEMONFIRE) and
                       not self:SpellOnCooldown(self.spells.CHANNEL_DEMONFIRE) and
                       self:HasDebuff(self.spells.IMMOLATE)
            end
        },
        
        -- Use Soul Fire if talented
        {
            spell = self.spells.SOUL_FIRE,
            condition = function(self)
                return IsSpellKnown(self.spells.SOUL_FIRE) and
                       not self:SpellOnCooldown(self.spells.SOUL_FIRE)
            end
        },
        
        -- Use Conflagrate to generate Soul Shards
        {
            spell = self.spells.CONFLAGRATE,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.CONFLAGRATE)
            end
        },
        
        -- Use Shadowburn if talented and target is in execute range
        {
            spell = self.spells.SHADOWBURN,
            condition = function(self)
                return IsSpellKnown(self.spells.SHADOWBURN) and
                       not self:SpellOnCooldown(self.spells.SHADOWBURN) and
                       self:IsTargetExecutable()
            end
        },
        
        -- Use Chaos Bolt to spend Soul Shards
        {
            spell = self.spells.CHAOS_BOLT,
            condition = function(self)
                return self:GetSoulShards() >= 2 or
                       (self:HasBuff(self.spells.DARK_SOUL_INSTABILITY) and
                        self:GetSoulShards() >= 1)
            end
        },
        
        -- Use Incinerate as filler
        { spell = self.spells.INCINERATE }
    }
    
    -- AoE rotation for Destruction
    self.aoeRotation = {
        -- Maintain Immolate on multiple targets
        {
            spell = self.spells.IMMOLATE,
            condition = function(self)
                return not self:HasDebuff(self.spells.IMMOLATE) or
                       self:GetDebuffRemaining(self.spells.IMMOLATE) < 5
            end
        },
        
        -- Use Cataclysm for AoE if talented
        {
            spell = self.spells.CATACLYSM,
            condition = function(self)
                return IsSpellKnown(self.spells.CATACLYSM) and
                       not self:SpellOnCooldown(self.spells.CATACLYSM) and
                       self:GetEnemyCount(10) >= 3
            end
        },
        
        -- Use covenant abilities for AoE
        { 
            spell = self.spells.SOUL_ROT,
            condition = function(self) return IsSpellKnown(self.spells.SOUL_ROT) end
        },
        { 
            spell = self.spells.IMPENDING_CATASTROPHE,
            condition = function(self) return IsSpellKnown(self.spells.IMPENDING_CATASTROPHE) end
        },
        
        -- Use Dark Soul: Instability for AoE burst
        {
            spell = self.spells.DARK_SOUL_INSTABILITY,
            condition = function(self)
                return IsSpellKnown(self.spells.DARK_SOUL_INSTABILITY) and
                       not self:SpellOnCooldown(self.spells.DARK_SOUL_INSTABILITY) and
                       self:GetEnemyCount(10) >= 3
            end
        },
        
        -- Use Summon Infernal for AoE
        {
            spell = self.spells.SUMMON_INFERNAL,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.SUMMON_INFERNAL) and
                       self:GetEnemyCount(10) >= 3
            end
        },
        
        -- Use Havoc for cleave
        {
            spell = self.spells.HAVOC,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.HAVOC) and
                       self:GetEnemyCount(10) >= 2
            end
        },
        
        -- Use Rain of Fire for AoE
        {
            spell = self.spells.RAIN_OF_FIRE,
            condition = function(self)
                return self:GetEnemyCount(10) >= 3 and
                       self:GetSoulShards() >= 3
            end
        },
        
        -- Use Channel Demonfire for cleave if talented
        {
            spell = self.spells.CHANNEL_DEMONFIRE,
            condition = function(self)
                return IsSpellKnown(self.spells.CHANNEL_DEMONFIRE) and
                       not self:SpellOnCooldown(self.spells.CHANNEL_DEMONFIRE) and
                       self:GetEnemyCount(10) >= 2
            end
        },
        
        -- Use Conflagrate to generate Soul Shards
        {
            spell = self.spells.CONFLAGRATE,
            condition = function(self)
                return not self:SpellOnCooldown(self.spells.CONFLAGRATE)
            end
        },
        
        -- Use Chaos Bolt for priority target or with Havoc
        {
            spell = self.spells.CHAOS_BOLT,
            condition = function(self)
                return self:GetSoulShards() >= 4 or
                       self:TargetHasDebuff(self.spells.HAVOC, "mouseover")
            end
        },
        
        -- Use Incinerate as filler
        { spell = self.spells.INCINERATE }
    }
    
    -- Define burst rotation
    self.burstRotation = {
        { spell = self.spells.DARK_SOUL_INSTABILITY },
        { spell = self.spells.SUMMON_INFERNAL },
        { 
            spell = self.spells.SOUL_ROT,
            condition = function(self) return IsSpellKnown(self.spells.SOUL_ROT) end
        },
        { 
            spell = self.spells.IMPENDING_CATASTROPHE,
            condition = function(self) return IsSpellKnown(self.spells.IMPENDING_CATASTROPHE) end
        },
        {
            spell = self.spells.CATACLYSM,
            condition = function(self) return IsSpellKnown(self.spells.CATACLYSM) end
        },
        { spell = self.spells.HAVOC },
        { spell = self.spells.CHAOS_BOLT }
    }
end

-- Get number of active demons
function Warlock:GetActiveDemonCount()
    -- In a real addon, this would query the active demons
    -- Here we'll return a simulated value
    return math.random(1, 5)
end

-- Get number of wild imps
function Warlock:GetWildImpCount()
    -- In a real addon, this would count the wild imps
    -- Here we'll return a simulated value
    return math.random(0, 8)
end

-- Get current pet type
function Warlock:GetPetType()
    -- In a real addon, this would return the actual pet type
    -- Here we'll return a generic value based on spec
    if self.currentSpec == SPEC_AFFLICTION then
        return "imp"
    elseif self.currentSpec == SPEC_DEMONOLOGY then
        return "felguard"
    elseif self.currentSpec == SPEC_DESTRUCTION then
        return "imp"
    end
    return "imp"
end

-- Check if the target can be executed with Shadowburn
function Warlock:IsTargetExecutable()
    -- In a real addon, this would check target HP threshold
    -- Here we'll return a simulated value
    return UnitExists("target") and UnitHealth("target") / UnitHealthMax("target") < 0.2
end

-- Check if the target has a specific debuff
function Warlock:TargetHasDebuff(spellId, targetUnit)
    -- In a real addon, this would check for the debuff on the target
    -- Here we'll assume a 50% chance for simplicity
    return math.random() > 0.5
end

-- Class-specific pre-rotation checks
function Warlock:ClassSpecificChecks()
    -- Check if we have an active pet
    if not self:HasActivePet() then
        -- Summon the appropriate pet based on spec
        if self.currentSpec == SPEC_AFFLICTION then
            WR.Queue:Add(self.spells.SUMMON_IMP)
        elseif self.currentSpec == SPEC_DEMONOLOGY then
            WR.Queue:Add(self.spells.SUMMON_FELGUARD)
        elseif self.currentSpec == SPEC_DESTRUCTION then
            WR.Queue:Add(self.spells.SUMMON_IMP)
        end
        return false
    end
    
    -- Check if we have a Healthstone
    if GetItemCount(5512) == 0 and not self:SpellOnCooldown(self.spells.CREATE_HEALTHSTONE) then
        WR.Queue:Add(self.spells.CREATE_HEALTHSTONE)
        return false
    end
    
    return true
end

-- Check if the warlock has an active pet
function Warlock:HasActivePet()
    -- In a real addon, would use UnitExists("pet")
    -- For our mock implementation, just return true to avoid endless pet summons
    return true
end

-- Get default action when nothing else is available
function Warlock:GetDefaultAction()
    if self.currentSpec == SPEC_AFFLICTION then
        return self.spells.SHADOW_BOLT
    elseif self.currentSpec == SPEC_DEMONOLOGY then
        return self.spells.SHADOW_BOLT
    elseif self.currentSpec == SPEC_DESTRUCTION then
        return self.spells.INCINERATE
    end
    
    return nil
end

-- Initialize the module
Warlock:Initialize()

return Warlock