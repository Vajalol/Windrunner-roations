-- LineOfSightManager.lua
-- Handles line of sight and targeting verification for abilities
local addonName, WR = ...
local LineOfSightManager = {}
WR.LineOfSightManager = LineOfSightManager

-- Dependencies
local API = WR.API
local ErrorHandler = WR.ErrorHandler
local ConfigRegistry = WR.ConfigRegistry

-- Local state
local enableLOSChecking = true
local lastLOSCheck = 0
local LOS_CHECK_INTERVAL = 0.2  -- Check LOS every 0.2 seconds
local cachedLOSResults = {}
local losCheckRequests = {}
local MAX_CACHE_SIZE = 50
local lastOutOfRangeWarning = 0
local lastLOSWarning = 0
local MIN_WARNING_INTERVAL = 5.0  -- Minimum seconds between warnings

-- Initialize module
function LineOfSightManager:Initialize()
    -- Register settings
    self:RegisterSettings()
    
    -- Register events for cache invalidation
    API.RegisterEvent("PLAYER_STARTED_MOVING", function()
        self:InvalidateCache()
    end)
    
    API.RegisterEvent("PLAYER_STOPPED_MOVING", function()
        self:InvalidateCache()
    end)
    
    API.RegisterEvent("UNIT_TARGET", function(unit)
        if unit == "player" or unit == "target" then
            self:InvalidateCache()
        end
    end)
    
    API.RegisterEvent("UNIT_SPELLCAST_FAILED", function(unitTarget, castGUID, spellID)
        if unitTarget == "player" then
            self:HandleCastFailure(spellID, castGUID)
        end
    end)
    
    API.PrintDebug("Line of Sight Manager initialized")
    return true
end

-- Register settings
function LineOfSightManager:RegisterSettings()
    ConfigRegistry:RegisterSettings("LineOfSightManager", {
        losSettings = {
            enableLOSChecking = {
                displayName = "Enable Line of Sight Checking",
                description = "Verify line of sight before suggesting abilities",
                type = "toggle",
                default = true
            },
            showRangeWarnings = {
                displayName = "Show Range Warnings",
                description = "Show warnings when targets are out of range",
                type = "toggle",
                default = true
            },
            showLOSWarnings = {
                displayName = "Show LOS Warnings",
                description = "Show warnings when targets are not in line of sight",
                type = "toggle",
                default = true
            },
            prioritizeRangeSpells = {
                displayName = "Prioritize In-Range Abilities",
                description = "Prioritize abilities that are in range over optimal rotation",
                type = "toggle",
                default = true
            },
            losCheckFrequency = {
                displayName = "LOS Check Frequency",
                description = "How often to check line of sight (seconds)",
                type = "slider",
                min = 0.1,
                max = 1.0,
                step = 0.1,
                default = 0.2
            }
        }
    })
    
    -- Add callback for settings changes
    ConfigRegistry:RegisterCallback("LineOfSightManager", function(settings)
        self:ApplySettings(settings)
    end)
end

-- Apply settings
function LineOfSightManager:ApplySettings(settings)
    -- Apply LOS settings
    enableLOSChecking = settings.losSettings.enableLOSChecking
    showRangeWarnings = settings.losSettings.showRangeWarnings
    showLOSWarnings = settings.losSettings.showLOSWarnings
    prioritizeRangeSpells = settings.losSettings.prioritizeRangeSpells
    LOS_CHECK_INTERVAL = settings.losSettings.losCheckFrequency
    
    API.PrintDebug("Line of Sight Manager settings applied")
end

-- Update settings from external source
function LineOfSightManager.UpdateSettings(newSettings)
    -- This is called from RotationManager
    if newSettings.enableLOSChecking ~= nil then
        enableLOSChecking = newSettings.enableLOSChecking
    end
end

-- Invalidate the line of sight cache
function LineOfSightManager:InvalidateCache()
    cachedLOSResults = {}
    API.PrintDebug("LOS cache invalidated")
end

-- Handle cast failure
function LineOfSightManager:HandleCastFailure(spellID, castGUID)
    -- Get fail reason from the game
    local failReason = nil
    
    -- In a real addon, we would get the actual fail reason
    -- For now, this is a simplified placeholder
    
    -- Update cache based on failure
    if failReason == "outOfRange" then
        self:CacheResult(spellID, "target", false, "RANGE")
        
        -- Show warning if enabled
        if showRangeWarnings and GetTime() - lastOutOfRangeWarning > MIN_WARNING_INTERVAL then
            local spellName = GetSpellInfo(spellID) or "Ability"
            API.PrintWarning(spellName .. " failed: Target is out of range")
            lastOutOfRangeWarning = GetTime()
        end
    elseif failReason == "notInLOS" then
        self:CacheResult(spellID, "target", false, "LOS")
        
        -- Show warning if enabled
        if showLOSWarnings and GetTime() - lastLOSWarning > MIN_WARNING_INTERVAL then
            local spellName = GetSpellInfo(spellID) or "Ability"
            API.PrintWarning(spellName .. " failed: Target is not in line of sight")
            lastLOSWarning = GetTime()
        end
    end
}

-- Cache a line of sight check result
function LineOfSightManager:CacheResult(spellID, unit, result, reason)
    -- Create cache key
    local cacheKey = spellID .. "_" .. unit
    
    -- Store result
    cachedLOSResults[cacheKey] = {
        result = result,
        reason = reason,
        time = GetTime()
    }
    
    -- Trim cache if it gets too large
    local cacheSize = 0
    local oldestKey = nil
    local oldestTime = GetTime()
    
    for key, entry in pairs(cachedLOSResults) do
        cacheSize = cacheSize + 1
        
        if entry.time < oldestTime then
            oldestTime = entry.time
            oldestKey = key
        end
    end
    
    if cacheSize > MAX_CACHE_SIZE and oldestKey then
        cachedLOSResults[oldestKey] = nil
    end
}

-- Check if a spell is usable on a unit
function LineOfSightManager:IsUsableOnUnit(spellID, unit)
    -- Skip if disabled
    if not enableLOSChecking then
        return true
    end
    
    -- Default unit to target
    unit = unit or "target"
    
    -- Skip check if unit doesn't exist
    if not UnitExists(unit) then
        return false
    end
    
    -- Check cache first
    local cacheKey = spellID .. "_" .. unit
    if cachedLOSResults[cacheKey] then
        local entry = cachedLOSResults[cacheKey]
        
        -- Return cached result if recent enough
        if GetTime() - entry.time < LOS_CHECK_INTERVAL then
            return entry.result
        end
    end
    
    -- Check if spell is known and usable
    if not API.IsSpellKnown(spellID) or not API.IsSpellUsable(spellID) then
        self:CacheResult(spellID, unit, false, "NOT_USABLE")
        return false
    end
    
    -- Check if target is in range
    local inRange = IsSpellInRange(spellID, unit)
    if inRange == 0 then
        self:CacheResult(spellID, unit, false, "RANGE")
        return false
    end
    
    -- Check line of sight
    local hasLOS = true  -- Assume true by default
    
    -- In a real addon, we would check actual LOS
    -- This would require the use of protected API calls via Tinkr
    -- For now, this is a simplified placeholder
    
    -- Cache and return result
    self:CacheResult(spellID, unit, hasLOS, hasLOS and "OK" or "LOS")
    return hasLOS
}

-- Request a line of sight check
function LineOfSightManager:RequestLOSCheck(spellID, unit)
    -- Skip if disabled
    if not enableLOSChecking then
        return
    end
    
    -- Create request
    table.insert(losCheckRequests, {
        spellID = spellID,
        unit = unit,
        time = GetTime()
    })
}

-- Process line of sight checks
function LineOfSightManager:ProcessRequests()
    -- Skip if disabled
    if not enableLOSChecking then
        return
    end
    
    -- Skip if too soon since last check
    if GetTime() - lastLOSCheck < LOS_CHECK_INTERVAL then
        return
    end
    
    -- Update last check time
    lastLOSCheck = GetTime()
    
    -- Process requests
    for i, request in ipairs(losCheckRequests) do
        self:IsUsableOnUnit(request.spellID, request.unit)
    end
    
    -- Clear processed requests
    losCheckRequests = {}
}

-- Check if any ability in a list is usable on a unit
function LineOfSightManager:GetUsableAbilities(abilities, unit)
    -- Skip if disabled
    if not enableLOSChecking then
        return abilities
    end
    
    -- Default unit to target
    unit = unit or "target"
    
    -- Check each ability
    local usableAbilities = {}
    
    for _, ability in ipairs(abilities) do
        if self:IsUsableOnUnit(ability.id, unit) then
            table.insert(usableAbilities, ability)
        end
    end
    
    return usableAbilities
}

-- Return module
return LineOfSightManager