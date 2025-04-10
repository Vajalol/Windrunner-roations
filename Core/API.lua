local addonName, WR = ...

-- API module - provides interface to Tinkr and core functions
local API = {}
WR.API = API

-- Initialization
function API:Initialize()
    if not WR:VerifyTinkr() then
        return false
    end
    
    -- Store references to frequently used API functions
    self.ObjectManager = Tinkr.api.ObjectManager
    self.Spell = Tinkr.api.Spell
    self.Cast = Tinkr.api.Cast
    self.UnitCachingEnabled = false
    
    -- Initialize unit cache
    self:InitializeUnitCache()
    
    return true
end

-- Unit caching to improve performance
function API:InitializeUnitCache()
    self.UnitCache = {
        player = nil,
        target = nil,
        focus = nil,
        pet = nil,
        mouseover = nil,
        units = {},
        lastUpdate = 0,
        updateInterval = 0.1, -- 100ms cache
    }
end

-- Enable/disable unit caching
function API:SetUnitCaching(enabled)
    self.UnitCachingEnabled = enabled
end

-- Update the unit cache 
function API:UpdateUnitCache()
    if not self.UnitCachingEnabled then return end
    
    local now = GetTime()
    if now - self.UnitCache.lastUpdate < self.UnitCache.updateInterval then
        return -- Cache is still valid
    end
    
    -- Update common units
    self.UnitCache.player = self:GetUnit("player")
    self.UnitCache.target = self:GetUnit("target")
    self.UnitCache.focus = self:GetUnit("focus")
    self.UnitCache.pet = self:GetUnit("pet")
    self.UnitCache.mouseover = self:GetUnit("mouseover")
    
    -- Clear the units table to prevent memory leaks
    wipe(self.UnitCache.units)
    
    -- Update timestamp
    self.UnitCache.lastUpdate = now
end

-- Clear the unit cache
function API:ClearUnitCache()
    if not self.UnitCachingEnabled then return end
    wipe(self.UnitCache.units)
    self.UnitCache.player = nil
    self.UnitCache.target = nil
    self.UnitCache.focus = nil
    self.UnitCache.pet = nil
    self.UnitCache.mouseover = nil
    self.UnitCache.lastUpdate = 0
end

-- Get a unit from Tinkr API or cache
function API:GetUnit(unit)
    if not self.UnitCachingEnabled then
        return self.ObjectManager:GetUnit(unit)
    end
    
    -- Common units are cached separately for frequent access
    if unit == "player" then
        if not self.UnitCache.player then
            self.UnitCache.player = self.ObjectManager:GetUnit(unit)
        end
        return self.UnitCache.player
    elseif unit == "target" then
        if not self.UnitCache.target then
            self.UnitCache.target = self.ObjectManager:GetUnit(unit)
        end
        return self.UnitCache.target
    elseif unit == "focus" then
        if not self.UnitCache.focus then
            self.UnitCache.focus = self.ObjectManager:GetUnit(unit)
        end
        return self.UnitCache.focus
    elseif unit == "pet" then
        if not self.UnitCache.pet then
            self.UnitCache.pet = self.ObjectManager:GetUnit(unit)
        end
        return self.UnitCache.pet
    elseif unit == "mouseover" then
        if not self.UnitCache.mouseover then
            self.UnitCache.mouseover = self.ObjectManager:GetUnit(unit)
        end
        return self.UnitCache.mouseover
    end
    
    -- Other units go in the general cache
    if not self.UnitCache.units[unit] then
        self.UnitCache.units[unit] = self.ObjectManager:GetUnit(unit)
    end
    
    return self.UnitCache.units[unit]
end

-- Get all units from Tinkr API
function API:GetUnits()
    return self.ObjectManager:GetUnits()
end

-- Check if a unit exists and is valid
function API:UnitExists(unit)
    local u = self:GetUnit(unit)
    return u ~= nil and u:Exists()
end

-- Check if a unit is dead
function API:UnitIsDead(unit)
    local u = self:GetUnit(unit)
    return u ~= nil and u:Exists() and u:IsDead()
end

-- Get unit health percentage
function API:UnitHealthPercent(unit)
    local u = self:GetUnit(unit)
    if u and u:Exists() and not u:IsDead() then
        return u:HealthPercent()
    end
    return 0
end

-- Get unit power percentage (mana, energy, rage, etc.)
function API:UnitPowerPercent(unit, powerType)
    local u = self:GetUnit(unit)
    if u and u:Exists() and not u:IsDead() then
        if powerType then
            return u:PowerPercent(powerType)
        else
            return u:PowerPercent()
        end
    end
    return 0
end

-- Get unit power amount
function API:UnitPower(unit, powerType)
    local u = self:GetUnit(unit)
    if u and u:Exists() and not u:IsDead() then
        if powerType then
            return u:Power(powerType)
        else
            return u:Power()
        end
    end
    return 0
end

-- Get unit max power
function API:UnitPowerMax(unit, powerType)
    local u = self:GetUnit(unit)
    if u and u:Exists() and not u:IsDead() then
        if powerType then
            return u:PowerMax(powerType)
        else
            return u:PowerMax()
        end
    end
    return 0
end

-- Check if a unit has an aura
function API:UnitHasAura(unit, auraName, filter)
    local u = self:GetUnit(unit)
    if u and u:Exists() and not u:IsDead() then
        return u:HasAura(auraName, filter)
    end
    return false
end

-- Get an aura on a unit
function API:UnitAura(unit, auraName, filter)
    local u = self:GetUnit(unit)
    if u and u:Exists() and not u:IsDead() then
        return u:GetAura(auraName, filter)
    end
    return nil
end

-- Get all auras on a unit
function API:UnitAuras(unit, filter)
    local u = self:GetUnit(unit)
    if u and u:Exists() and not u:IsDead() then
        return u:GetAuras(filter)
    end
    return {}
end

-- Get distance to a unit
function API:UnitDistance(unit)
    local player = self:GetUnit("player")
    local target = self:GetUnit(unit)
    
    if player and target and player:Exists() and target:Exists() then
        return player:GetDistance(target)
    end
    
    return 9999 -- Return a large value if distance can't be calculated
end

-- Check if player is in combat
function API:InCombat()
    return UnitAffectingCombat("player")
end

-- Check if unit is in combat
function API:UnitInCombat(unit)
    return UnitAffectingCombat(unit)
end

-- Get current talent tier selections
function API:GetTalents()
    local talents = {}
    
    -- Implementation depends on WoW version
    -- For retail, this needs to query the loadout API
    
    return talents
end

-- Create a spell object
function API:CreateSpell(spellId)
    return self.Spell:New(spellId)
end

-- Cast a spell
function API:CastSpell(spellId, unit)
    local spell = self:CreateSpell(spellId)
    if unit then
        return spell:Cast(unit)
    else
        return spell:Cast()
    end
end

-- Check if a spell is castable
function API:IsSpellCastable(spellId, unit)
    local spell = self:CreateSpell(spellId)
    if unit then
        return spell:IsReady(unit)
    else
        return spell:IsReady()
    end
end

-- Get the cooldown of a spell
function API:GetSpellCooldown(spellId)
    local spell = self:CreateSpell(spellId)
    return spell:Cooldown()
end

-- Check if player is moving
function API:IsMoving()
    return GetUnitSpeed("player") > 0
end

-- Check if a unit is hostile
function API:IsHostile(unit)
    local u = self:GetUnit(unit)
    if u and u:Exists() then
        return u:IsEnemy()
    end
    return false
end

-- Check if a unit is friendly
function API:IsFriendly(unit)
    local u = self:GetUnit(unit)
    if u and u:Exists() then
        return u:IsFriend()
    end
    return false
end

-- Check if a spell is in range of a unit
function API:IsSpellInRange(spellId, unit)
    local spell = self:CreateSpell(spellId)
    if unit then
        return spell:IsInRange(unit)
    end
    return false
end

-- Data serialization/deserialization functions
function API:Serialize(data)
    if type(data) ~= "table" then
        return tostring(data)
    end
    
    -- Simple table serialization
    local result = "{"
    for k, v in pairs(data) do
        local key = type(k) == "string" and string.format("[%q]", k) or string.format("[%s]", tostring(k))
        local value = type(v) == "table" and self:Serialize(v) or 
                      type(v) == "string" and string.format("%q", v) or tostring(v)
        result = result .. key .. "=" .. value .. ","
    end
    result = result .. "}"
    return result
end

function API:Deserialize(str)
    -- This is a simplified deserializer and not secure for production
    -- A real implementation would use a proper serialization library
    local func, err = loadstring("return " .. str)
    if not func then
        return nil, err
    end
    
    setfenv(func, {}) -- Sandbox environment
    local success, result = pcall(func)
    if not success then
        return nil, result
    end
    
    return result
end

-- Compression/decompression functions (simplified)
function API:Compress(str)
    -- In a real implementation, you would use a compression library
    -- This is just a placeholder
    return str
end

function API:Decompress(str)
    -- In a real implementation, you would use a compression library
    -- This is just a placeholder
    return str
end

-- Base64 encoding/decoding (simplified)
function API:Encode(str)
    -- In a real implementation, you would use a proper base64 library
    -- This is just a placeholder
    return str
end

function API:Decode(str)
    -- In a real implementation, you would use a proper base64 library
    -- This is just a placeholder
    return str
end

-- Initialize the API module
API:Initialize()
