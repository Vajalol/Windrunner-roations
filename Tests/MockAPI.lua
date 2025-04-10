-- MockAPI.lua - Mock implementation of WoW API functions for testing
local MockAPI = {}

-- Basic WoW functions
_G.UnitClass = function() return "Mage", "MAGE" end
_G.GetSpecialization = function() return 1 end
_G.GetSpecializationInfo = function() return 62 end -- Arcane Mage spec ID
_G.UnitGUID = function(unit) return unit == "player" and "Player-1234" or "Target-5678" end
_G.UnitName = function(unit) return unit == "player" and "TestPlayer" or "TestTarget" end
_G.UnitLevel = function() return 70 end
_G.GetTime = function() return os.time() end
_G.GetHaste = function() return 20 end -- 20% haste
_G.GetCritChance = function() return 25 end -- 25% crit
_G.GetMastery = function() return 30 end -- 30% mastery
_G.GetVersatility = function() return 10 end -- 10% versatility
_G.UnitHealthMax = function(unit) return 100 end
_G.UnitHealth = function(unit) return 80 end -- 80% health
_G.UnitPowerMax = function(unit, powerType) return 100 end
_G.UnitPower = function(unit, powerType) return 75 end -- 75% mana/power
_G.UnitInRaid = function(unit) return false end
_G.UnitInParty = function(unit) return false end
_G.GetNumGroupMembers = function() return 1 end
_G.IsInRaid = function() return false end
_G.IsInGroup = function() return false end
_G.InCombatLockdown = function() return false end
_G.UnitIsDeadOrGhost = function(unit) return false end
_G.UnitIsDead = function(unit) return false end
_G.UnitCanAttack = function(unit1, unit2) return unit2 ~= "player" end
_G.UnitExists = function(unit) return true end
_G.UnitCastingInfo = function(unit) return nil end -- Not casting
_G.UnitChannelInfo = function(unit) return nil end -- Not channeling
_G.GetSpellCooldown = function(spellID) 
    -- Return start time and duration (0 means no cooldown)
    return 0, 0
end
_G.IsSpellInRange = function(spellID, unit) return true end -- Spell in range
_G.IsUsableSpell = function(spellID) return true, false end -- Usable and no resource shortage
_G.GetCVar = function(cvar) return cvar == "SpellQueueWindow" and "400" or "0" end
_G.SetCVar = function(cvar, value) return end
_G.UnitReaction = function(unit1, unit2) return 2 end -- Hostile
_G.UnitAffectingCombat = function(unit) return unit ~= "player" end -- Target in combat
_G.UnitIsEnemy = function(unit1, unit2) return unit2 ~= "player" end -- Target is enemy
_G.IsMounted = function() return false end
_G.InCinematic = function() return false end
_G.IsInInstance = function() return false, "none" end -- Not in instance

-- Frame functions
_G.CreateFrame = function(type, name, parent, template) 
    local frame = {
        Show = function() end,
        Hide = function() end,
        RegisterEvent = function() end,
        UnregisterEvent = function() end,
        SetScript = function() end,
        GetName = function() return name or "MockFrame" end,
        IsShown = function() return false end
    }
    return frame
end

-- Global frames
_G.MovieFrame = { IsShown = function() return false end }
_G.StaticPopup1 = { IsShown = function() return false end }

-- WoW API functions
_G.CombatLogGetCurrentEventInfo = function() 
    -- Return mock combat log information
    return os.time(), "SPELL_CAST_SUCCESS", nil, 
           "Player-1234", "TestPlayer", 0x511, 0x0, 
           "Target-5678", "TestTarget", 0x10a48, 0x0, 
           1449, "Arcane Explosion", 0x40 
end

_G.GetSpellInfo = function(spellID)
    local spells = {
        [1449] = {"Arcane Explosion", nil, "Interface\\Icons\\Spell_Nature_WispSplode", 1.5},
        [30451] = {"Arcane Blast", nil, "Interface\\Icons\\Spell_Arcane_Blast", 2.25},
        [5143] = {"Arcane Missiles", nil, "Interface\\Icons\\Spell_Nature_StarFall", 2.5},
        [44425] = {"Arcane Barrage", nil, "Interface\\Icons\\Ability_Mage_ArcaneBarrage", 1.5},
        [12051] = {"Evocation", nil, "Interface\\Icons\\Spell_Nature_Purge", 6},
        [2139] = {"Counterspell", nil, "Interface\\Icons\\Spell_Frost_IceShock", 0.5},
    }
    
    if spells[spellID] then
        return unpack(spells[spellID])
    else
        return "Unknown Spell " .. spellID, nil, "Interface\\Icons\\INV_Misc_QuestionMark", 1.5
    end
end

-- Slash command handling
_G.SlashCmdList = {}

-- Add functions to the MockAPI object for use in test scripts
function MockAPI.InitializeWR()
    -- Create the WR table if it doesn't exist
    if not WR then
        WR = {}
    end
    
    -- Initialize the minimal required WR fields
    WR.version = "1.0.0"
    WR.debugMode = true
    
    -- Debug print function
    WR.Debug = function(self, ...)
        if self.debugMode then
            print("[DEBUG]", ...)
        end
    end
    
    -- Empty mock API handler
    WR.API = {
        Initialize = function() end,
        GetUnit = function(unit) 
            return {
                Exists = function() return true end,
                IsDead = function() return false end,
                IsEnemy = function() return true end,
                GetDistance = function() return 5 end, -- 5 yards
                HealthPercent = function() return 80 end, -- 80% health
                GetToken = function() return "target" end,
                GetTarget = function() return "Player-1234" end,
                GetClassification = function() return "normal" end,
                IsCasting = function() return false end,
                IsCastingInterruptible = function() return false end,
                CastingInfo = function() return nil end
            }
        end,
        GetUnits = function() 
            return {
                [1] = WR.API:GetUnit("target"),
                [2] = WR.API:GetUnit("targettarget")
            }
        end,
        UnitDistance = function(unit) return 5 end,
        UnitHealthPercent = function(unit) return 80 end,
        UnitPowerPercent = function(unit, powerType) return 75 end,
        UnitHasAura = function(unit, auraName, filter) return false end,
        UnitAura = function(unit, auraName, filter) return nil end,
        IsMoving = function() return false end,
        InCombat = function() return false end,
        IsSpellCastable = function(spellID, unit) return true end,
        CastSpell = function(spellID, unit) 
            print("[CAST]", GetSpellInfo(spellID), "on", unit or "no target")
            return true
        end,
        UpdateUnitCache = function() end,
        ClearUnitCache = function() end,
        GetSpellCooldown = function(spellID) return 0 end
    }
    
    -- Create basic config
    WR.Config = {
        Get = function(self, key) return true end,
        Set = function(self, key, value) end
    }
    
    return WR
end

-- Function to load the mocked WoW environment
function MockAPI.Initialize()
    print("Initializing mock WoW API environment")
    
    return MockAPI.InitializeWR()
end

return MockAPI