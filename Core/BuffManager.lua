-- BuffManager.lua
-- Handles automatic buff tracking and casting
local addonName, WR = ...
local BuffManager = {}
WR.BuffManager = BuffManager

-- Dependencies
local API = WR.API
local ErrorHandler = WR.ErrorHandler
local ConfigRegistry = WR.ConfigRegistry

-- Local state
local trackGroupBuffs = true
local lastBuffCastTime = 0
local MIN_BUFF_CAST_INTERVAL = 5.0  -- Minimum seconds between buff checks
local groupBuffsLastUpdated = 0
local GROUP_BUFFS_UPDATE_INTERVAL = 10.0 -- Update group buffs every 10 seconds
local missingBuffs = {}  -- Tracks which buffs are missing on which units
local partyMembers = {}  -- Tracks party/raid members for buff checking

-- Class-specific buffs
local classBuffs = {
    -- Priest buffs
    ["PRIEST"] = {
        {id = 21562, name = "Power Word: Fortitude", target = "group", priority = 1},
        {id = 390677, name = "Shadowform", target = "self", priority = 2, specId = 3}  -- Shadow spec only
    },
    
    -- Mage buffs
    ["MAGE"] = {
        {id = 1459, name = "Arcane Intellect", target = "group", priority = 1},
    },
    
    -- Warrior buffs
    ["WARRIOR"] = {
        {id = 6673, name = "Battle Shout", target = "group", priority = 1},
    },
    
    -- Druid buffs
    ["DRUID"] = {
        {id = 1126, name = "Mark of the Wild", target = "group", priority = 1}
    },
    
    -- Warlock buffs
    ["WARLOCK"] = {
        {id = 20707, name = "Soulstone", target = "healer", priority = 2}
    },
    
    -- Paladin buffs
    ["PALADIN"] = {
        {id = 203538, name = "Greater Blessing of Kings", target = "group", priority = 1},
        {id = 203539, name = "Greater Blessing of Wisdom", target = "healer", priority = 2}
    },
    
    -- More class buffs could be added as needed for other classes
}

-- Initialize module
function BuffManager:Initialize()
    -- Register settings
    self:RegisterSettings()
    
    -- Register for events
    API.RegisterEvent("GROUP_ROSTER_UPDATE", function()
        self:UpdatePartyMembers()
    end)
    
    API.RegisterEvent("PLAYER_ENTERING_WORLD", function()
        self:UpdatePartyMembers()
    end)
    
    -- Initial update of party members
    self:UpdatePartyMembers()
    
    API.PrintDebug("Buff Manager initialized")
    return true
end

-- Register settings
function BuffManager:RegisterSettings()
    ConfigRegistry:RegisterSettings("BuffManager", {
        buffSettings = {
            trackGroupBuffs = {
                displayName = "Track Group Buffs",
                description = "Automatically track and cast missing buffs",
                type = "toggle",
                default = true
            },
            prioritizeGroupBuffs = {
                displayName = "Prioritize Group Buffs",
                description = "Prioritize group buffs over regular rotation",
                type = "toggle",
                default = true
            },
            includeRaidBuffs = {
                displayName = "Include Raid Buffs",
                description = "Track and cast raid-wide buffs",
                type = "toggle",
                default = true
            },
            outOfCombatOnly = {
                displayName = "Out of Combat Only",
                description = "Only cast buffs when out of combat",
                type = "toggle",
                default = false
            }
        }
    })
    
    -- Add callback for settings changes
    ConfigRegistry:RegisterCallback("BuffManager", function(settings)
        self:ApplySettings(settings)
    end)
end

-- Apply settings
function BuffManager:ApplySettings(settings)
    -- Apply buff settings
    trackGroupBuffs = settings.buffSettings.trackGroupBuffs
    prioritizeGroupBuffs = settings.buffSettings.prioritizeGroupBuffs
    includeRaidBuffs = settings.buffSettings.includeRaidBuffs
    outOfCombatOnly = settings.buffSettings.outOfCombatOnly
    
    API.PrintDebug("Buff Manager settings applied")
end

-- Update settings from external source
function BuffManager.UpdateSettings(newSettings)
    -- This is called from RotationManager
    if newSettings.trackGroupBuffs ~= nil then
        trackGroupBuffs = newSettings.trackGroupBuffs
    end
end

-- Update party member list
function BuffManager:UpdatePartyMembers()
    -- Clear current party members
    partyMembers = {}
    
    -- Add player
    table.insert(partyMembers, {
        unit = "player",
        name = UnitName("player"),
        class = select(2, UnitClass("player")),
        role = self:GetUnitRole("player"),
        isHealer = self:IsUnitHealer("player")
    })
    
    -- Check if in a group
    if IsInGroup() then
        local numMembers = GetNumGroupMembers()
        local prefix = IsInRaid() and "raid" or "party"
        
        for i = 1, numMembers do
            local unit = prefix .. i
            if UnitExists(unit) and not UnitIsUnit(unit, "player") then
                table.insert(partyMembers, {
                    unit = unit,
                    name = UnitName(unit),
                    class = select(2, UnitClass(unit)),
                    role = self:GetUnitRole(unit),
                    isHealer = self:IsUnitHealer(unit)
                })
            end
        end
    end
    
    -- Reset buff tracking
    missingBuffs = {}
    groupBuffsLastUpdated = 0
    
    API.PrintDebug("Updated party members: " .. #partyMembers)
end

-- Check if unit is a healer
function BuffManager:IsUnitHealer(unit)
    local role = self:GetUnitRole(unit)
    if role == "HEALER" then return true end
    
    -- Check class and spec if role assignment doesn't work
    local className = select(2, UnitClass(unit))
    if not unit or not className then return false end
    
    -- TODO: This would need to check spec IDs for specific healing specs
    -- For now, simplistic approach focusing only on clear healing classes/specs
    local healingSpecs = {
        ["PRIEST"] = {1, 2},  -- Discipline and Holy
        ["DRUID"] = {4},      -- Restoration
        ["PALADIN"] = {1},    -- Holy
        ["SHAMAN"] = {3},     -- Restoration
        ["MONK"] = {2}        -- Mistweaver
    }
    
    if healingSpecs[className] then
        -- If it's a main healing class, assume it might be a healer
        return true
    end
    
    return false
end

-- Get unit's assigned role
function BuffManager:GetUnitRole(unit)
    if not unit then return "NONE" end
    
    local role = UnitGroupRolesAssigned(unit)
    if role and role ~= "NONE" then
        return role
    end
    
    -- Fallback logic if role isn't assigned
    local className = select(2, UnitClass(unit))
    if not className then return "NONE" end
    
    -- Very simplified role assignment, would be improved in a real implementation
    if className == "WARRIOR" or className == "DEATHKNIGHT" or className == "PALADIN" or className == "DRUID" then
        return "TANK"  -- Could be a tank
    elseif className == "PRIEST" or className == "PALADIN" or className == "DRUID" or className == "MONK" or className == "SHAMAN" then
        return "HEALER"  -- Could be a healer
    else
        return "DAMAGER"  -- Assume DPS
    end
end

-- Check for missing buffs on a specific unit
function BuffManager:CheckMissingBuffsOnUnit(unit, playerClass)
    local buffs = classBuffs[playerClass]
    if not buffs then return {} end
    
    local missing = {}
    
    -- Check each buff for the given class
    for _, buff in ipairs(buffs) do
        -- Handle "self" buffs only for the player
        if buff.target == "self" and not UnitIsUnit(unit, "player") then
            -- Skip self-only buffs for other players
        elseif buff.target == "healer" and not self:IsUnitHealer(unit) then
            -- Skip healer-only buffs for non-healers
        else
            -- Check if the unit is missing this buff
            if not self:HasBuff(unit, buff.id) then
                table.insert(missing, buff)
            end
        end
    end
    
    return missing
end

-- Check if a unit has a specific buff
function BuffManager:HasBuff(unit, buffId)
    if not unit or not buffId then return false end
    
    local i = 1
    while true do
        local name, _, _, _, _, _, _, _, _, spellId = UnitBuff(unit, i)
        if not name then break end
        
        if spellId == buffId then
            return true
        end
        
        i = i + 1
    end
    
    return false
end

-- Check which buffs the player can cast that are missing
function BuffManager:UpdateMissingBuffs()
    -- Skip if disabled
    if not trackGroupBuffs then
        missingBuffs = {}
        return
    end
    
    -- Get the player's class
    local playerClass = select(2, UnitClass("player"))
    if not playerClass then return end
    
    -- Get the buffs this class can provide
    local availableBuffs = classBuffs[playerClass]
    if not availableBuffs then
        missingBuffs = {}
        return
    end
    
    -- Check which buffs we can actually cast (known and not on cooldown)
    local castableBuffs = {}
    for _, buff in ipairs(availableBuffs) do
        if API.IsSpellKnown(buff.id) and API.IsSpellUsable(buff.id) then
            -- Check if spec-restricted
            if not buff.specId or GetSpecialization() == buff.specId then
                table.insert(castableBuffs, buff)
            end
        end
    end
    
    -- Reset missing buffs
    missingBuffs = {}
    
    -- Check each party member for missing buffs
    for _, member in ipairs(partyMembers) do
        local unitMissingBuffs = {}
        
        for _, buff in ipairs(castableBuffs) do
            -- Handle different buff types
            if buff.target == "self" then
                -- Self buffs: Only check for player
                if UnitIsUnit(member.unit, "player") and not self:HasBuff("player", buff.id) then
                    table.insert(unitMissingBuffs, buff)
                end
            elseif buff.target == "group" then
                -- Group buffs: Check for everyone
                if not self:HasBuff(member.unit, buff.id) then
                    table.insert(unitMissingBuffs, buff)
                end
            elseif buff.target == "healer" then
                -- Healer buffs: Only check healers
                if self:IsUnitHealer(member.unit) and not self:HasBuff(member.unit, buff.id) then
                    table.insert(unitMissingBuffs, buff)
                end
            end
        end
        
        if #unitMissingBuffs > 0 then
            -- Sort by priority
            table.sort(unitMissingBuffs, function(a, b) return a.priority < b.priority end)
            
            missingBuffs[member.unit] = unitMissingBuffs
        end
    end
    
    -- Update timestamp
    groupBuffsLastUpdated = GetTime()
end

-- Process buffs based on combat state
function BuffManager.ProcessBuffs(combatState)
    -- Skip if disabled
    if not trackGroupBuffs then
        return nil
    end
    
    -- Skip if we recently cast a buff
    if GetTime() - lastBuffCastTime < MIN_BUFF_CAST_INTERVAL then
        return nil
    end
    
    -- Skip if we should only cast buffs out of combat and we're in combat
    local settings = ConfigRegistry.GetSettings("BuffManager") or { buffSettings = {} }
    local outOfCombatOnly = settings.buffSettings.outOfCombatOnly
    if outOfCombatOnly and combatState.inCombat then
        return nil
    end
    
    -- Update missing buffs if needed
    if GetTime() - groupBuffsLastUpdated > GROUP_BUFFS_UPDATE_INTERVAL then
        BuffManager:UpdateMissingBuffs()
    end
    
    -- Find the highest priority missing buff to cast
    local buffToCast = nil
    local targetUnit = nil
    
    -- First pass: Look for self buffs
    for unit, unitBuffs in pairs(missingBuffs) do
        if UnitIsUnit(unit, "player") then
            for _, buff in ipairs(unitBuffs) do
                if buff.target == "self" then
                    buffToCast = buff
                    targetUnit = unit
                    break
                end
            end
        end
        if buffToCast then break end
    end
    
    -- Second pass: Look for group buffs
    if not buffToCast then
        for unit, unitBuffs in pairs(missingBuffs) do
            for _, buff in ipairs(unitBuffs) do
                if buff.target == "group" then
                    buffToCast = buff
                    targetUnit = unit
                    break
                end
            end
            if buffToCast then break end
        end
    end
    
    -- Third pass: Look for healer buffs
    if not buffToCast then
        for unit, unitBuffs in pairs(missingBuffs) do
            if BuffManager:IsUnitHealer(unit) then
                for _, buff in ipairs(unitBuffs) do
                    if buff.target == "healer" then
                        buffToCast = buff
                        targetUnit = unit
                        break
                    end
                end
            end
            if buffToCast then break end
        end
    end
    
    -- If we found a buff to cast, return it
    if buffToCast and targetUnit then
        lastBuffCastTime = GetTime()
        
        return {
            id = buffToCast.id,
            target = targetUnit
        }
    end
    
    return nil
end

-- Return module
return BuffManager