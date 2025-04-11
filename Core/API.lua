------------------------------------------
-- WindrunnerRotations - API Module
-- Author: VortexQ8
-- Core API functions for all class modules
------------------------------------------

local addonName, addon = ...
addon.API = {}

local API = addon.API
local registeredSpells = {}
local registeredEvents = {}
local debugMode = true

-- Print debug messages
function API.PrintDebug(message)
    if debugMode and message then
        print("|cFF69CCF0[WindrunnerRotations]|r " .. tostring(message))
    end
end

-- Print error messages
function API.PrintError(message)
    print("|cFFFF0000[WindrunnerRotations] ERROR:|r " .. tostring(message))
end

-- Register a spell for tracking
function API.RegisterSpell(spellID)
    if not spellID or type(spellID) ~= "number" then
        API.PrintError("Invalid spell ID: " .. tostring(spellID))
        return false
    end
    
    registeredSpells[spellID] = true
    return true
end

-- Register event handler
function API.RegisterEvent(event, handler)
    if not event or not handler then
        API.PrintError("Invalid event registration")
        return false
    end
    
    if not registeredEvents[event] then
        registeredEvents[event] = {}
    end
    
    table.insert(registeredEvents[event], handler)
    return true
end

-- Get player class ID
function API.GetPlayerClass()
    local _, _, classID = UnitClass("player")
    return classID
end

-- Get active specialization ID
function API.GetActiveSpecID()
    return GetSpecialization() and GetSpecializationInfo(GetSpecialization()) or 0
end

-- Check if player has a specific talent
function API.HasTalent(talentID)
    -- This would need implementation specific to WoW's talent API
    return IsPlayerSpellKnown(talentID)
end

-- Check if player has a specific legendary effect
function API.HasLegendaryEffect(effectID)
    -- This would need implementation specific to WoW's item API
    return false -- Placeholder
end

-- Cast spell
function API.CastSpell(spellID)
    if not spellID then return false end
    
    -- This would call into Tinkr API for actual execution
    TinkrCast(spellID) -- Placeholder function for Tinkr integration
    return true
end

-- Cast spell on unit
function API.CastSpellOnUnit(spellID, unit)
    if not spellID or not unit then return false end
    
    -- This would call into Tinkr API for actual execution
    TinkrCastOnUnit(spellID, unit) -- Placeholder function for Tinkr integration
    return true
end

-- Cast spell at cursor position
function API.CastSpellAtCursor(spellID)
    if not spellID then return false end
    
    -- This would call into Tinkr API for actual execution
    TinkrCastAtCursor(spellID) -- Placeholder function for Tinkr integration
    return true
end

-- Cast spell at best enemy clump
function API.CastSpellAtBestClump(spellID, radius)
    if not spellID or not radius then return false end
    
    -- This would call into Tinkr API for actual execution
    TinkrCastAtBestClump(spellID, radius) -- Placeholder function for Tinkr integration
    return true
end

-- Check if spell is ready to cast
function API.CanCast(spellID)
    if not spellID then return false end
    
    -- This would call into Tinkr API for actual checks
    return TinkrCanCast(spellID) -- Placeholder function for Tinkr integration
end

-- Check if GCD is ready
function API.IsGCDReady()
    -- This would call into Tinkr API for GCD status
    return TinkrIsGCDReady() -- Placeholder function for Tinkr integration
end

-- Check if player is casting
function API.IsPlayerCasting()
    -- This would call into Tinkr API
    return TinkrIsPlayerCasting() -- Placeholder function for Tinkr integration
end

-- Check if player is channeling
function API.IsPlayerChanneling()
    -- This would call into Tinkr API
    return TinkrIsPlayerChanneling() -- Placeholder function for Tinkr integration
end

-- Check if spell is on cooldown
function API.IsSpellOnCooldown(spellID)
    if not spellID then return true end
    
    -- This would call into Tinkr API
    return TinkrIsSpellOnCooldown(spellID) -- Placeholder function for Tinkr integration
end

-- Get spell cooldown remaining
function API.GetSpellCooldownRemaining(spellID)
    if not spellID then return 999 end
    
    -- This would call into Tinkr API
    return TinkrGetSpellCooldownRemaining(spellID) -- Placeholder function for Tinkr integration
end

-- Check if spell is in range of target
function API.IsSpellInRange(spellID)
    if not spellID then return false end
    
    -- This would call into Tinkr API
    return TinkrIsSpellInRange(spellID) -- Placeholder function for Tinkr integration
end

-- Check if spell is ready (off cooldown)
function API.IsSpellReady(spellID)
    if not spellID then return false end
    
    -- This would call into Tinkr API
    return not TinkrIsSpellOnCooldown(spellID) -- Placeholder function for Tinkr integration
end

-- Get player health percentage
function API.GetPlayerHealthPercent()
    return UnitHealth("player") / UnitHealthMax("player") * 100
end

-- Get target health percentage
function API.GetTargetHealthPercent()
    if not UnitExists("target") then return 0 end
    return UnitHealth("target") / UnitHealthMax("target") * 100
end

-- Get unit health percentage
function API.GetUnitHealthPercent(unit)
    if not UnitExists(unit) then return 0 end
    return UnitHealth(unit) / UnitHealthMax(unit) * 100
end

-- Get player power (rage, energy, mana, holy power, etc.)
function API.GetPlayerPower()
    -- This would call into Tinkr API
    return TinkrGetPlayerPower() -- Placeholder function for Tinkr integration
end

-- Check if player has a buff
function API.PlayerHasBuff(buffID)
    -- This would call into Tinkr API
    return TinkrPlayerHasBuff(buffID) -- Placeholder function for Tinkr integration
end

-- Get player buff time remaining
function API.GetPlayerBuffTimeRemaining(buffID)
    -- This would call into Tinkr API
    return TinkrGetPlayerBuffTimeRemaining(buffID) -- Placeholder function for Tinkr integration
end

-- Get player buff stacks
function API.GetPlayerBuffStacks(buffID)
    -- This would call into Tinkr API
    return TinkrGetPlayerBuffStacks(buffID) -- Placeholder function for Tinkr integration
end

-- Check if unit has a buff
function API.UnitHasBuff(unit, buffID)
    -- This would call into Tinkr API
    return TinkrUnitHasBuff(unit, buffID) -- Placeholder function for Tinkr integration
end

-- Get debuff info on a unit
function API.GetDebuffInfo(unitGUID, debuffID)
    -- This would call into Tinkr API to get debuff details
    return TinkrGetDebuffInfo(unitGUID, debuffID) -- Placeholder function for Tinkr integration
end

-- Check if player is moving
function API.IsPlayerMoving()
    return GetUnitSpeed("player") > 0
end

-- Get player GUID
function API.GetPlayerGUID()
    return UnitGUID("player")
end

-- Get target GUID
function API.GetTargetGUID()
    return UnitGUID("target")
end

-- Get number of nearby enemies
function API.GetNearbyEnemiesCount(radius)
    -- This would call into Tinkr API
    return TinkrGetNearbyEnemiesCount(radius) -- Placeholder function for Tinkr integration
end

-- Check if target is casting
function API.IsTargetCasting()
    -- This would call into Tinkr API
    return TinkrIsTargetCasting() -- Placeholder function for Tinkr integration
end

-- Get target distance
function API.GetTargetDistance()
    -- This would call into Tinkr API
    return TinkrGetTargetDistance() -- Placeholder function for Tinkr integration
end

-- Get unit distance
function API.GetUnitDistance(unit)
    -- This would call into Tinkr API
    return TinkrGetUnitDistance(unit) -- Placeholder function for Tinkr integration
end

-- Check if target is in range
function API.IsTargetInRange(range)
    -- This would call into Tinkr API
    return TinkrIsTargetInRange(range) -- Placeholder function for Tinkr integration
end

-- Get party members in range
function API.GetPartyMembersInRange(range)
    -- This would call into Tinkr API
    return TinkrGetPartyMembersInRange(range) -- Placeholder function for Tinkr integration
end

-- Check if we should use burst cooldowns
function API.ShouldUseBurst()
    -- This would be implemented with logic for detecting boss fights, etc.
    return TinkrShouldUseBurst() -- Placeholder function for Tinkr integration
end

-- Get time in combat
function API.GetInCombatTime()
    -- This would call into Tinkr API
    return TinkrGetInCombatTime() -- Placeholder function for Tinkr integration
end

-- Check if player is in combat
function API.IsInCombat()
    return UnitAffectingCombat("player")
end

-- Cancel harmful debuffs (e.g., when using Divine Shield)
function API.CancelHarmfulDebuffs()
    -- This would call into Tinkr API
    TinkrCancelHarmfulDebuffs() -- Placeholder function for Tinkr integration
end

-- Get player moving time
function API.GetPlayerMovingTime()
    -- This would call into Tinkr API
    return TinkrGetPlayerMovingTime() -- Placeholder function for Tinkr integration
end

-- Get group size
function API.GetGroupSize()
    return IsInRaid() and GetNumGroupMembers() or IsInGroup() and GetNumGroupMembers() or 1
end

-- Get group unit ID
function API.GetGroupUnitID(index)
    if index == 1 and not IsInGroup() then
        return "player"
    end
    
    return IsInRaid() and "raid"..index or "party"..index
end

-- Get unit name
function API.GetUnitName(unit)
    return UnitName(unit)
end

-- Get unit role
function API.GetUnitRole(unit)
    return UnitGroupRolesAssigned(unit)
end

-- Check if unit is main tank
function API.IsMainTank(unit)
    -- This would call into Tinkr API or use WoW's built-in tank detection
    return UnitGroupRolesAssigned(unit) == "TANK" and true or false -- Simplified placeholder
end

-- Check if unit is off-tank
function API.IsOffTank(unit)
    -- This would require more complex logic in a real implementation
    return UnitGroupRolesAssigned(unit) == "TANK" and not API.IsMainTank(unit)
end

-- Convert GUID to UnitID
function API.GUIDToUnitID(guid)
    -- This would search through group members to find a match
    if UnitGUID("player") == guid then
        return "player"
    end
    
    for i = 1, API.GetGroupSize() do
        local unitID = API.GetGroupUnitID(i)
        if UnitGUID(unitID) == guid then
            return unitID
        end
    end
    
    return nil
end

-- Check if unit is rooted
function API.IsUnitRooted(unit)
    -- This would check for root effects
    -- Simplified placeholder
    return false
end

-- Check if unit is slowed
function API.IsUnitSlowed(unit)
    -- This would check for slow effects
    -- Simplified placeholder
    return false
end

-- Get target reaction (friendly/hostile)
function API.GetTargetReaction()
    return UnitReaction("player", "target") >= 4 and "friendly" or "hostile"
end

-- Get relative unit angle
function API.GetRelativeUnitAngle(unit)
    -- This would call into Tinkr API
    return TinkrGetRelativeUnitAngle(unit) -- Placeholder function for Tinkr integration
end

-- Set player facing direction
function API.SetPlayerFacing(angle)
    -- This would call into Tinkr API
    TinkrSetPlayerFacing(angle) -- Placeholder function for Tinkr integration
end

-- Verify Tinkr is running and compatible
function API.VerifyTinkr()
    -- Check if Tinkr global exists
    if not _G.Tinkr then
        API.PrintError("Tinkr is not loaded. Please make sure Tinkr is running before using WindrunnerRotations.")
        return false
    end
    
    -- Check Tinkr version
    local minVersion = "1.0.0" -- Minimum required version
    local currentVersion = _G.Tinkr.GetVersion and _G.Tinkr:GetVersion() or "0.0.0"
    
    -- Simple version check (would need more robust checking in practice)
    if currentVersion < minVersion then
        API.PrintError("Tinkr version " .. currentVersion .. " is outdated. WindrunnerRotations requires version " .. minVersion .. " or higher.")
        return false
    end
    
    API.PrintDebug("Tinkr verified: v" .. currentVersion)
    return true
end

-- Handle an event
function API.HandleEvent(event, ...)
    if registeredEvents[event] then
        for _, handler in ipairs(registeredEvents[event]) do
            handler(...)
        end
    end
end

-- Initialize the API
function API.Initialize()
    -- Create frame for event handling
    local eventFrame = CreateFrame("Frame")
    
    -- Register for events
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        API.HandleEvent(event, ...)
    end)
    
    -- Print initialization message
    API.PrintDebug("API initialized")
    
    return true
end

-- Export the API module
return API