local addonName, WR = ...

-- Optimization module for performance improvements
local Optimization = {}
WR.Optimization = Optimization

-- Performance stats tracking
local performanceStats = {
    rotationTime = {},
    frameTime = {},
    memoryUsage = {},
    functionCalls = {},
    processingTime = {}
}

-- Configuration options
local config = {
    enabled = true,
    throttleUpdateInterval = 0.1,  -- Time between non-essential updates
    adaptiveThrottling = true,     -- Dynamically adjust throttling based on performance
    cacheResults = true,           -- Cache results of expensive operations
    intelligentUpdates = true,     -- Only update what needs updating
    optimizationLevel = 2          -- 1-3, higher is more aggressive optimization
}

-- Cache tables
local auraCache = {}
local cooldownCache = {}
local unitCache = {}
local spellCache = {}

-- Timers
local lastUpdateTime = 0
local frameTimes = {}
local maxFrameTimeHistory = 20

-- Frequency limiters for expensive operations
local updateFrequencies = {
    unitData = 0.2,           -- How often to update non-essential unit data
    environmentalData = 0.5,  -- How often to check environmental conditions
    auraData = 0.1,           -- How often to update aura data for non-critical targets
    combatLogProcessing = 0,  -- How often to process combat log (0 = every frame)
    targetScanning = 0.1      -- How often to scan for new targets
}

-- Tracking the last update times
local lastUpdates = {}

-- Throttled function queue
local throttledFunctions = {}

-- Initialize the optimization module
function Optimization:Initialize()
    -- Register events for memory usage tracking
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("PLAYER_LEAVING_WORLD")
    eventFrame:RegisterEvent("ADDON_LOADED")
    
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "PLAYER_ENTERING_WORLD" then
            -- Start performance monitoring
            self:RegisterEvent("UPDATE_PERFORMANCE")
            C_Timer.After(5, function() Optimization:CollectMemoryUsage() end)
        elseif event == "UPDATE_PERFORMANCE" then
            -- Record frame times
            local frameTime = GetFramerate()
            table.insert(frameTimes, frameTime)
            if #frameTimes > maxFrameTimeHistory then
                table.remove(frameTimes, 1)
            end
            
            -- Adjust throttling if needed
            if config.adaptiveThrottling then
                Optimization:AdjustThrottling()
            end
        end
    end)
    
    -- Initialize timers
    for operation, _ in pairs(updateFrequencies) do
        lastUpdates[operation] = 0
    end
    
    WR:Debug("Optimization module initialized")
    
    -- Start collection timer
    C_Timer.NewTicker(10, function() Optimization:CollectPerformanceStats() end)
end

-- Check if an operation should be run based on frequency limiting
function Optimization:ShouldRun(operation)
    if not config.enabled then return true end
    
    local currentTime = GetTime()
    local frequency = updateFrequencies[operation] or 0
    
    if currentTime - (lastUpdates[operation] or 0) >= frequency then
        lastUpdates[operation] = currentTime
        return true
    end
    
    return false
end

-- Cache unit data to reduce API calls
function Optimization:CacheUnitData(unit)
    if not unit or not UnitExists(unit) then return nil end
    
    if not unitCache[unit] then
        unitCache[unit] = {}
    end
    
    local cache = unitCache[unit]
    local currentTime = GetTime()
    
    -- Only update if not recently updated
    if not cache.lastUpdate or currentTime - cache.lastUpdate > updateFrequencies.unitData then
        cache.health = UnitHealth(unit)
        cache.maxHealth = UnitHealthMax(unit)
        cache.healthPercent = cache.health / cache.maxHealth * 100
        cache.power = UnitPower(unit)
        cache.maxPower = UnitPowerMax(unit)
        cache.powerPercent = cache.maxPower > 0 and (cache.power / cache.maxPower * 100) or 0
        cache.level = UnitLevel(unit)
        cache.exists = true
        cache.lastUpdate = currentTime
        
        -- Don't need to update these as frequently
        if not cache.class or not cache.name or currentTime - (cache.detailUpdate or 0) > 1 then
            cache.name = UnitName(unit)
            cache.class = select(2, UnitClass(unit))
            cache.isPlayer = UnitIsPlayer(unit)
            cache.detailUpdate = currentTime
        end
    end
    
    return cache
end

-- Get cached unit data
function Optimization:GetUnitData(unit, field)
    if not unit or not UnitExists(unit) then return nil end
    
    -- Ensure cache exists and is up-to-date
    local cache = self:CacheUnitData(unit)
    if not cache then return nil end
    
    return field and cache[field] or cache
end

-- Cache aura data to reduce API calls
function Optimization:CacheAuras(unit)
    if not unit or not UnitExists(unit) then return nil end
    
    if not auraCache[unit] then
        auraCache[unit] = {
            buffs = {},
            debuffs = {},
            lastUpdate = 0
        }
    end
    
    local cache = auraCache[unit]
    local currentTime = GetTime()
    
    -- Only update if not recently updated
    if currentTime - cache.lastUpdate > updateFrequencies.auraData then
        -- Clear previous data
        for k in pairs(cache.buffs) do cache.buffs[k] = nil end
        for k in pairs(cache.debuffs) do cache.debuffs[k] = nil end
        
        -- Cache buffs
        for i = 1, 40 do
            local name, icon, count, debuffType, duration, expirationTime, source, 
                  isStealable, nameplateShowPersonal, spellId = UnitBuff(unit, i)
            
            if not name then break end
            
            cache.buffs[spellId] = {
                name = name,
                icon = icon,
                count = count,
                duration = duration,
                expirationTime = expirationTime,
                source = source,
                spellId = spellId
            }
        end
        
        -- Cache debuffs
        for i = 1, 40 do
            local name, icon, count, debuffType, duration, expirationTime, source, 
                  isStealable, nameplateShowPersonal, spellId = UnitDebuff(unit, i)
            
            if not name then break end
            
            cache.debuffs[spellId] = {
                name = name,
                icon = icon,
                count = count,
                debuffType = debuffType,
                duration = duration,
                expirationTime = expirationTime,
                source = source,
                spellId = spellId
            }
        end
        
        cache.lastUpdate = currentTime
    end
    
    return cache
end

-- Check if unit has a specific aura (buff or debuff)
function Optimization:UnitHasAura(unit, spellId, filter)
    if not unit or not UnitExists(unit) or not spellId then return false end
    
    -- Ensure cache exists and is up-to-date
    local cache = self:CacheAuras(unit)
    if not cache then return false end
    
    if filter == "BUFF" or filter == "HELPFUL" then
        return cache.buffs[spellId] ~= nil
    elseif filter == "DEBUFF" or filter == "HARMFUL" then
        return cache.debuffs[spellId] ~= nil
    else
        return cache.buffs[spellId] ~= nil or cache.debuffs[spellId] ~= nil
    end
end

-- Get aura information
function Optimization:GetAuraInfo(unit, spellId, filter)
    if not unit or not UnitExists(unit) or not spellId then return nil end
    
    -- Ensure cache exists and is up-to-date
    local cache = self:CacheAuras(unit)
    if not cache then return nil end
    
    if filter == "BUFF" or filter == "HELPFUL" then
        return cache.buffs[spellId]
    elseif filter == "DEBUFF" or filter == "HARMFUL" then
        return cache.debuffs[spellId]
    else
        return cache.buffs[spellId] or cache.debuffs[spellId]
    end
end

-- Cache spell cooldown information
function Optimization:CacheSpellCooldown(spellId)
    if not spellId then return nil end
    
    if not cooldownCache[spellId] then
        cooldownCache[spellId] = {
            start = 0,
            duration = 0,
            lastUpdate = 0
        }
    end
    
    local cache = cooldownCache[spellId]
    local currentTime = GetTime()
    
    -- Only update if not recently updated
    if currentTime - cache.lastUpdate > 0.1 then
        local start, duration, enabled = GetSpellCooldown(spellId)
        
        cache.start = start
        cache.duration = duration
        cache.enabled = enabled
        cache.lastUpdate = currentTime
    end
    
    return cache
end

-- Get spell cooldown information
function Optimization:GetSpellCooldown(spellId)
    if not spellId then return 0, 0, nil end
    
    -- Ensure cache exists and is up-to-date
    local cache = self:CacheSpellCooldown(spellId)
    if not cache then return 0, 0, nil end
    
    return cache.start, cache.duration, cache.enabled
end

-- Cache spell information
function Optimization:CacheSpellInfo(spellId)
    if not spellId then return nil end
    
    if not spellCache[spellId] then
        spellCache[spellId] = {}
    end
    
    local cache = spellCache[spellId]
    
    if not cache.name then
        local name, rank, icon, castTime, minRange, maxRange, spellId = GetSpellInfo(spellId)
        
        cache.name = name
        cache.rank = rank
        cache.icon = icon
        cache.castTime = castTime
        cache.minRange = minRange
        cache.maxRange = maxRange
        cache.spellId = spellId
    end
    
    return cache
end

-- Get spell information
function Optimization:GetSpellInfo(spellId, field)
    if not spellId then return nil end
    
    -- Ensure cache exists
    local cache = self:CacheSpellInfo(spellId)
    if not cache then return nil end
    
    return field and cache[field] or cache
end

-- Throttle a function call to reduce frequency
function Optimization:ThrottleFunction(func, key, delay)
    if not func or not key then return end
    
    delay = delay or updateFrequencies.unitData
    local currentTime = GetTime()
    
    if not throttledFunctions[key] then
        throttledFunctions[key] = {
            func = func,
            lastRun = 0
        }
    end
    
    local throttle = throttledFunctions[key]
    
    if currentTime - throttle.lastRun >= delay then
        throttle.lastRun = currentTime
        func()
        return true
    end
    
    return false
end

-- Run a function with performance tracking
function Optimization:TrackPerformance(func, name)
    if not func or not name then return end
    
    -- Initialize tracking for this function if needed
    if not performanceStats.functionCalls[name] then
        performanceStats.functionCalls[name] = {
            calls = 0,
            totalTime = 0,
            maxTime = 0
        }
    end
    
    local tracking = performanceStats.functionCalls[name]
    local startTime = debugprofilestop()
    
    -- Execute the function
    local result = func()
    
    -- Record performance
    local elapsed = debugprofilestop() - startTime
    tracking.calls = tracking.calls + 1
    tracking.totalTime = tracking.totalTime + elapsed
    tracking.maxTime = math.max(tracking.maxTime, elapsed)
    
    return result
end

-- Adjust throttling based on performance
function Optimization:AdjustThrottling()
    local avgFramerate = 0
    
    -- Calculate average framerate
    if #frameTimes > 0 then
        local sum = 0
        for _, fps in ipairs(frameTimes) do
            sum = sum + fps
        end
        avgFramerate = sum / #frameTimes
    end
    
    -- Adjust throttling based on framerate
    local adjustFactor = 1
    
    if avgFramerate < 20 then
        -- Very low FPS, increase throttling significantly
        adjustFactor = 2
    elseif avgFramerate < 30 then
        -- Low FPS, increase throttling moderately
        adjustFactor = 1.5
    elseif avgFramerate > 60 then
        -- High FPS, decrease throttling
        adjustFactor = 0.75
    end
    
    -- Apply adjustments
    for operation, frequency in pairs(updateFrequencies) do
        if frequency > 0 then
            updateFrequencies[operation] = math.max(0.05, frequency * adjustFactor)
        end
    end
end

-- Collect memory usage statistics
function Optimization:CollectMemoryUsage()
    local currentMemory = collectgarbage("count")
    
    -- Record memory usage
    table.insert(performanceStats.memoryUsage, {
        time = GetTime(),
        memory = currentMemory
    })
    
    -- Keep only the last 60 points
    if #performanceStats.memoryUsage > 60 then
        table.remove(performanceStats.memoryUsage, 1)
    end
end

-- Collect performance statistics
function Optimization:CollectPerformanceStats()
    -- Already done in other functions, just make sure garbage collection runs periodically
    if config.optimizationLevel >= 2 then
        -- Request garbage collection every few minutes
        collectgarbage("collect")
    end
    
    -- Record current stats
    self:CollectMemoryUsage()
end

-- Clear cached data
function Optimization:ClearCache(cacheType)
    if cacheType == "aura" or cacheType == "all" then
        wipe(auraCache)
    end
    
    if cacheType == "unit" or cacheType == "all" then
        wipe(unitCache)
    end
    
    if cacheType == "cooldown" or cacheType == "all" then
        wipe(cooldownCache)
    end
    
    if cacheType == "spell" or cacheType == "all" then
        -- Don't wipe spell cache, it rarely changes
        if cacheType == "all" then
            wipe(spellCache)
        end
    end
    
    WR:Debug("Cleared cache:", cacheType or "all")
end

-- Get performance statistics
function Optimization:GetPerformanceStats()
    return performanceStats
end

-- Get configuration
function Optimization:GetConfig()
    return config
end

-- Set configuration
function Optimization:SetConfig(newConfig)
    if not newConfig then return end
    
    for k, v in pairs(newConfig) do
        if config[k] ~= nil then  -- Only update existing settings
            config[k] = v
        end
    end
    
    WR:Debug("Updated optimization config")
    
    -- Apply changes immediately if needed
    if not config.enabled then
        -- Clear all caches if optimization is disabled
        self:ClearCache("all")
    end
end

-- Create optimized iteration functions
function Optimization:CreateOptimizedIterator(tbl, filterFunc)
    if not tbl then return function() return nil end end
    
    local i, v
    local iter = function()
        repeat
            i, v = next(tbl, i)
            if not i then return nil end
        until not filterFunc or filterFunc(v, i)
        return i, v
    end
    
    return iter
end

-- Provide hooks for common WoW API functions
local ApiHooks = {
    UnitHealth = function(unit)
        local cache = Optimization:GetUnitData(unit)
        return cache and cache.health or UnitHealth(unit)
    end,
    
    UnitHealthMax = function(unit)
        local cache = Optimization:GetUnitData(unit)
        return cache and cache.maxHealth or UnitHealthMax(unit)
    end,
    
    UnitHealthPercent = function(unit)
        local cache = Optimization:GetUnitData(unit)
        return cache and cache.healthPercent or (UnitHealth(unit) / UnitHealthMax(unit) * 100)
    end,
    
    UnitExists = function(unit)
        if unit == "player" or unit == "target" or unit == "focus" then
            return UnitExists(unit)  -- These are checked frequently and it's faster to call directly
        end
        
        local cache = unitCache[unit]
        if cache and GetTime() - (cache.lastUpdate or 0) < 0.2 then
            return cache.exists
        end
        
        return UnitExists(unit)
    end,
    
    GetSpellCooldown = function(spellId)
        return Optimization:GetSpellCooldown(spellId)
    end,
    
    UnitAura = function(unit, index, filter)
        if type(index) == "number" then
            -- We can't optimize the numeric index version as easily
            return UnitAura(unit, index, filter)
        else
            -- Assume it's a name/id lookup
            local spellId = tonumber(index) or 0
            local auraInfo = Optimization:GetAuraInfo(unit, spellId, filter)
            
            if auraInfo then
                return auraInfo.name, auraInfo.icon, auraInfo.count, auraInfo.debuffType,
                       auraInfo.duration, auraInfo.expirationTime, auraInfo.source,
                       false, false, auraInfo.spellId
            end
            
            return UnitAura(unit, index, filter)
        end
    end,
    
    UnitBuff = function(unit, index, filter)
        if type(index) == "number" then
            return UnitBuff(unit, index, filter)
        else
            local spellId = tonumber(index) or 0
            local auraInfo = Optimization:GetAuraInfo(unit, spellId, "BUFF")
            
            if auraInfo then
                return auraInfo.name, auraInfo.icon, auraInfo.count, auraInfo.debuffType,
                       auraInfo.duration, auraInfo.expirationTime, auraInfo.source,
                       false, false, auraInfo.spellId
            end
            
            return UnitBuff(unit, index, filter)
        end
    end,
    
    UnitDebuff = function(unit, index, filter)
        if type(index) == "number" then
            return UnitDebuff(unit, index, filter)
        else
            local spellId = tonumber(index) or 0
            local auraInfo = Optimization:GetAuraInfo(unit, spellId, "DEBUFF")
            
            if auraInfo then
                return auraInfo.name, auraInfo.icon, auraInfo.count, auraInfo.debuffType,
                       auraInfo.duration, auraInfo.expirationTime, auraInfo.source,
                       false, false, auraInfo.spellId
            end
            
            return UnitDebuff(unit, index, filter)
        end
    end,
    
    GetSpellInfo = function(spellId)
        local cache = Optimization:GetSpellInfo(spellId)
        
        if cache then
            return cache.name, cache.rank, cache.icon, cache.castTime,
                   cache.minRange, cache.maxRange, cache.spellId
        end
        
        return GetSpellInfo(spellId)
    end
}

-- Expose API hooks
Optimization.API = ApiHooks

-- Initialize module
Optimization:Initialize()

return Optimization