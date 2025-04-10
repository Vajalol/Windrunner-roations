local addonName, WR = ...

-- PerformanceOptimizer module for advanced performance optimization
local PerformanceOptimizer = {}
WR.PerformanceOptimizer = PerformanceOptimizer

-- Constants
local UPDATE_FREQUENCY = 0.1 -- Default update frequency (seconds)
local COMBAT_UPDATE_FREQUENCY = 0.05 -- Combat update frequency
local THRESHOLD_MS = 5 -- Performance threshold in milliseconds
local MEMORY_CHECK_INTERVAL = 60 -- Check memory usage every 60 seconds
local AUTOMATIC_GC_THRESHOLD = 20 -- MB of memory growth before automatic collection

-- Performance metrics storage
local performanceData = {
    cpuTime = {},
    memoryUsage = {},
    updateTimes = {},
    functionMetrics = {},
    lastGC = 0,
    baselineMemory = 0,
    baselineCPU = 0,
    initialized = false,
    bottlenecks = {},
    optimizationApplied = {},
    framerate = {},
    framerateSamples = 0,
    modulePerformance = {},
    lastMemoryCheck = 0,
    lastMemoryUsage = 0,
    adaptiveMode = false
}

-- Configuration
local config = {
    enabled = true,
    aggressiveOptimization = false,
    monitorModules = true,
    adaptiveUpdateFrequency = true,
    limitProcessingTime = true,
    maxProcessingTime = 8, -- Maximum milliseconds per frame
    throttleInBackground = true,
    automaticGC = true,
    logPerformanceIssues = true,
    performanceLevel = 2, -- 1-3, higher means more performance optimizations
    disableAnimationsInCombat = false,
    lowLatencyMode = false,
    smartResourceTracking = true,
    cacheExpiry = 5, -- Seconds before cache expires
    highPerformanceThreshold = 60, -- FPS
    lowPerformanceThreshold = 30, -- FPS
    customUpdateFrequency = nil
}

-- Initialize the PerformanceOptimizer
function PerformanceOptimizer:Initialize()
    -- Load saved settings
    if WindrunnerRotationsDB and WindrunnerRotationsDB.PerformanceOptimizer then
        local savedConfig = WindrunnerRotationsDB.PerformanceOptimizer
        for k, v in pairs(savedConfig) do
            if config[k] ~= nil then
                config[k] = v
            end
        end
    end
    
    -- Register for events
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("PLAYER_LOGOUT")
    eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED") -- Entering combat
    eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED") -- Leaving combat
    eventFrame:RegisterEvent("ADDON_LOADED")
    
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "PLAYER_ENTERING_WORLD" then
            -- Establish baselines after a short delay
            C_Timer.After(5, function()
                PerformanceOptimizer:EstablishBaselines()
            end)
            
            -- Set up periodic performance monitoring
            C_Timer.NewTicker(5, function() 
                if config.enabled then
                    PerformanceOptimizer:MonitorPerformance()
                end
            end)
        elseif event == "PLAYER_LOGOUT" then
            PerformanceOptimizer:SaveSettings()
        elseif event == "PLAYER_REGEN_DISABLED" then
            -- Entering combat
            PerformanceOptimizer:EnterCombatMode()
        elseif event == "PLAYER_REGEN_ENABLED" then
            -- Leaving combat
            PerformanceOptimizer:LeaveCombatMode()
        elseif event == "ADDON_LOADED" and ... == addonName then
            -- Addon loaded, initialize
            PerformanceOptimizer:EstablishBaselines()
        end
    end)
    
    -- Create a frame for OnUpdate handling
    local updateFrame = CreateFrame("Frame")
    updateFrame:SetScript("OnUpdate", function(self, elapsed)
        if not config.enabled then return end
        
        self.elapsed = (self.elapsed or 0) + elapsed
        local updateFrequency = PerformanceOptimizer:GetUpdateFrequency()
        
        if self.elapsed >= updateFrequency then
            self.elapsed = 0
            PerformanceOptimizer:OnPerformanceUpdate(elapsed)
        end
    end)
    
    -- Initialize throttling system
    self:InitializeThrottling()
    
    -- Register performance hooks
    self:RegisterPerformanceHooks()
    
    -- Apply initial optimizations
    self:ApplyBaseOptimizations()
    
    WR:Debug("PerformanceOptimizer initialized")
    performanceData.initialized = true
}

-- Save settings
function PerformanceOptimizer:SaveSettings()
    -- Initialize storage if needed
    WindrunnerRotationsDB = WindrunnerRotationsDB or {}
    WindrunnerRotationsDB.PerformanceOptimizer = CopyTable(config)
}

-- Get appropriate update frequency
function PerformanceOptimizer:GetUpdateFrequency()
    -- If custom frequency is set, use that
    if config.customUpdateFrequency then
        return config.customUpdateFrequency
    end
    
    -- If in combat, use combat frequency
    if InCombatLockdown() then
        return COMBAT_UPDATE_FREQUENCY
    end
    
    -- If adaptive mode is enabled, adjust based on performance
    if config.adaptiveUpdateFrequency and performanceData.adaptiveMode then
        local avgFPS = self:GetAverageFPS()
        
        if avgFPS < config.lowPerformanceThreshold then
            -- Low performance, reduce update frequency
            return UPDATE_FREQUENCY * 2
        elseif avgFPS > config.highPerformanceThreshold then
            -- High performance, increase update frequency
            return UPDATE_FREQUENCY * 0.75
        end
    end
    
    -- Default case
    return UPDATE_FREQUENCY
end

-- Record framerate for adaptive mode
function PerformanceOptimizer:RecordFramerate()
    local currentFPS = GetFramerate()
    
    -- Maintain a limited sample size
    if #performanceData.framerate >= 20 then
        table.remove(performanceData.framerate, 1)
    end
    
    table.insert(performanceData.framerate, currentFPS)
    performanceData.framerateSamples = performanceData.framerateSamples + 1
    
    -- After enough samples, decide if we should enter adaptive mode
    if performanceData.framerateSamples >= 100 then
        local avgFPS = self:GetAverageFPS()
        
        if avgFPS < 40 then
            performanceData.adaptiveMode = true
            WR:Debug("Entering adaptive performance mode due to low framerate:", avgFPS)
        else
            performanceData.adaptiveMode = false
        end
        
        -- Reset sample counter
        performanceData.framerateSamples = 0
    end
}

-- Get average FPS
function PerformanceOptimizer:GetAverageFPS()
    if #performanceData.framerate == 0 then
        return GetFramerate()
    end
    
    local sum = 0
    for _, fps in ipairs(performanceData.framerate) do
        sum = sum + fps
    end
    
    return sum / #performanceData.framerate
}

-- OnUpdate handler for performance monitoring
function PerformanceOptimizer:OnPerformanceUpdate(elapsed)
    -- Record current performance metrics
    self:RecordPerformanceMetrics()
    
    -- Check if optimization is needed
    if self:ShouldOptimize() then
        self:OptimizePerformance()
    end
    
    -- Record framerate for adaptive mode
    self:RecordFramerate()
    
    -- Check memory usage periodically
    self:CheckMemoryUsage()
}

-- Check if memory usage is growing significantly
function PerformanceOptimizer:CheckMemoryUsage()
    local currentTime = GetTime()
    
    -- Only check periodically
    if currentTime - performanceData.lastMemoryCheck < MEMORY_CHECK_INTERVAL then
        return
    end
    
    performanceData.lastMemoryCheck = currentTime
    local currentMemory = self:GetMemoryUsage()
    
    -- If we've established a last usage, check growth
    if performanceData.lastMemoryUsage > 0 then
        local growth = currentMemory - performanceData.lastMemoryUsage
        
        -- If memory has grown significantly and automatic GC is enabled
        if growth > AUTOMATIC_GC_THRESHOLD and config.automaticGC then
            WR:Debug("Memory usage grown by", string.format("%.2f", growth), "MB - running garbage collection")
            collectgarbage("collect")
            performanceData.lastGC = currentTime
        end
    end
    
    -- Update last memory usage
    performanceData.lastMemoryUsage = currentMemory
}

-- Establish performance baselines
function PerformanceOptimizer:EstablishBaselines()
    -- Measure CPU usage baseline
    local startCPU = debugprofilestop()
    -- Do some standard operations to measure
    for i = 1, 1000 do
        local x = i * 3.14159
    end
    local endCPU = debugprofilestop()
    performanceData.baselineCPU = endCPU - startCPU
    
    -- Measure memory usage baseline
    performanceData.baselineMemory = self:GetMemoryUsage()
    
    -- Initialize function metrics
    performanceData.functionMetrics = {}
    
    WR:Debug("Performance baselines established - CPU:", 
             string.format("%.2f", performanceData.baselineCPU), 
             "ms, Memory:", 
             string.format("%.2f", performanceData.baselineMemory), "MB")
}

-- Record current performance metrics
function PerformanceOptimizer:RecordPerformanceMetrics()
    -- Record CPU time
    local cpuTime = debugprofilestop()
    
    -- If we have more than 60 samples (5 minutes at default update frequency)
    -- remove the oldest
    if #performanceData.cpuTime >= 60 then
        table.remove(performanceData.cpuTime, 1)
    end
    
    table.insert(performanceData.cpuTime, cpuTime)
    
    -- Record memory usage
    local memoryUsage = self:GetMemoryUsage()
    
    -- Keep only 10 memory samples
    if #performanceData.memoryUsage >= 10 then
        table.remove(performanceData.memoryUsage, 1)
    end
    
    table.insert(performanceData.memoryUsage, memoryUsage)
    
    -- If module monitoring is enabled
    if config.monitorModules then
        self:MonitorModulePerformance()
    end
}

-- Get memory usage in MB
function PerformanceOptimizer:GetMemoryUsage()
    return collectgarbage("count") / 1024
}

-- Check if optimization is needed
function PerformanceOptimizer:ShouldOptimize()
    -- If we're in aggressive mode, always return true
    if config.aggressiveOptimization then
        return true
    end
    
    -- Check framerate
    local currentFPS = GetFramerate()
    if currentFPS < config.lowPerformanceThreshold then
        return true
    end
    
    -- Check if any update times are too high
    for _, time in ipairs(performanceData.updateTimes) do
        if time > THRESHOLD_MS then
            return true
        end
    end
    
    -- Check memory growth
    if #performanceData.memoryUsage >= 2 then
        local latestMemory = performanceData.memoryUsage[#performanceData.memoryUsage]
        local previousMemory = performanceData.memoryUsage[#performanceData.memoryUsage - 1]
        
        -- If memory has grown by more than 10MB in a short time
        if latestMemory - previousMemory > 10 then
            return true
        end
    end
    
    return false
}

-- Apply performance optimizations
function PerformanceOptimizer:OptimizePerformance()
    -- Identify performance bottlenecks
    local bottlenecks = self:IdentifyBottlenecks()
    
    -- Apply optimizations based on bottlenecks
    for _, bottleneck in ipairs(bottlenecks) do
        self:ApplyOptimizationFor(bottleneck)
    end
    
    -- Consider garbage collection if memory is a concern
    local currentTime = GetTime()
    local latestMemory = performanceData.memoryUsage[#performanceData.memoryUsage]
    
    if latestMemory > performanceData.baselineMemory * 1.5 and 
       currentTime - performanceData.lastGC > 300 then -- No GC in last 5 minutes
        collectgarbage("collect")
        performanceData.lastGC = currentTime
        WR:Debug("Performed garbage collection due to high memory usage")
    end
    
    -- Check update frequency
    self:OptimizeUpdateFrequency()
}

-- Identify performance bottlenecks
function PerformanceOptimizer:IdentifyBottlenecks()
    local bottlenecks = {}
    
    -- Check CPU usage in functions
    for funcName, metrics in pairs(performanceData.functionMetrics) do
        if metrics.totalTime / metrics.calls > THRESHOLD_MS then
            table.insert(bottlenecks, {
                type = "function",
                name = funcName,
                averageTime = metrics.totalTime / metrics.calls,
                priority = (metrics.totalTime / metrics.calls) / THRESHOLD_MS
            })
        end
    end
    
    -- Check module performance
    for moduleName, metrics in pairs(performanceData.modulePerformance) do
        if metrics.updateTime > THRESHOLD_MS then
            table.insert(bottlenecks, {
                type = "module",
                name = moduleName,
                averageTime = metrics.updateTime,
                priority = metrics.updateTime / THRESHOLD_MS
            })
        end
    end
    
    -- Sort bottlenecks by priority (highest first)
    table.sort(bottlenecks, function(a, b)
        return a.priority > b.priority
    end)
    
    return bottlenecks
end

-- Apply optimization for a specific bottleneck
function PerformanceOptimizer:ApplyOptimizationFor(bottleneck)
    -- Check if we've already optimized this
    if performanceData.optimizationApplied[bottleneck.name] then
        -- Only re-optimize if it's a severe bottleneck
        if bottleneck.priority < 3 then
            return
        end
    end
    
    WR:Debug("Applying optimization for", bottleneck.type, bottleneck.name, 
             "with priority", string.format("%.2f", bottleneck.priority))
    
    if bottleneck.type == "function" then
        -- Function optimizations
        self:OptimizeFunction(bottleneck.name)
    elseif bottleneck.type == "module" then
        -- Module optimizations
        self:OptimizeModule(bottleneck.name)
    end
    
    -- Mark as optimized
    performanceData.optimizationApplied[bottleneck.name] = true
}

-- Optimize a specific function
function PerformanceOptimizer:OptimizeFunction(funcName)
    -- Determine which module the function belongs to
    local moduleName = funcName:match("^([^:]+):")
    
    if not moduleName then
        WR:Debug("Could not determine module for function", funcName)
        return
    end
    
    -- Get the module
    local module = WR[moduleName]
    
    if not module then
        WR:Debug("Module not found for function", funcName)
        return
    end
    
    -- Function-specific optimizations
    local funcBaseName = funcName:match(":([^:]+)$")
    
    if not funcBaseName then
        WR:Debug("Could not determine base function name for", funcName)
        return
    end
    
    -- Check if the function has a cached version or can be optimized
    if funcBaseName:match("^Get") or funcBaseName:match("^Calculate") or funcBaseName:match("^Compute") then
        -- These functions are good candidates for caching
        self:ApplyCaching(module, funcBaseName)
    elseif funcBaseName:match("^Update") or funcBaseName:match("^Refresh") then
        -- These functions are good candidates for throttling
        self:ApplyThrottling(module, funcBaseName)
    elseif funcBaseName:match("^Process") or funcBaseName:match("^Handle") then
        -- These functions are good candidates for optimization
        self:ApplyProcessingLimit(module, funcBaseName)
    end
}

-- Apply caching to a function
function PerformanceOptimizer:ApplyCaching(module, funcName)
    -- Don't reapply if already cached
    if module["_cached_" .. funcName] then
        return
    end
    
    -- Store original function
    module["_original_" .. funcName] = module[funcName]
    
    -- Create cache table
    module["_cache_" .. funcName] = {}
    
    -- Replace with cached version
    module["_cached_" .. funcName] = true
    
    module[funcName] = function(self, ...)
        -- Create cache key from arguments
        local args = {...}
        local cacheKey = ""
        
        for i, arg in ipairs(args) do
            if type(arg) == "table" then
                -- Tables can't be directly used as keys, so use a representation
                cacheKey = cacheKey .. tostring(arg) .. ";"
            else
                cacheKey = cacheKey .. tostring(arg) .. ";"
            end
        end
        
        -- Check if we have a cached result
        local cache = module["_cache_" .. funcName]
        if cache[cacheKey] and cache[cacheKey].time > GetTime() - config.cacheExpiry then
            return unpack(cache[cacheKey].result)
        end
        
        -- Call original function
        local startTime = debugprofilestop()
        local results = {module["_original_" .. funcName](self, ...)}
        local endTime = debugprofilestop()
        
        -- Cache result
        cache[cacheKey] = {
            result = results,
            time = GetTime()
        }
        
        -- Track performance
        local metrics = performanceData.functionMetrics[module._name .. ":" .. funcName] or 
                       {totalTime = 0, calls = 0}
        metrics.totalTime = metrics.totalTime + (endTime - startTime)
        metrics.calls = metrics.calls + 1
        performanceData.functionMetrics[module._name .. ":" .. funcName] = metrics
        
        -- Clean cache if it gets too large
        local count = 0
        for _ in pairs(cache) do
            count = count + 1
        end
        
        if count > 1000 then
            self:CleanCache(module, funcName)
        end
        
        return unpack(results)
    end
    
    WR:Debug("Applied caching to", module._name .. ":" .. funcName)
}

-- Clean a function's cache
function PerformanceOptimizer:CleanCache(module, funcName)
    local cache = module["_cache_" .. funcName]
    if not cache then return end
    
    local currentTime = GetTime()
    local newCache = {}
    
    -- Keep only recent entries
    for key, entry in pairs(cache) do
        if currentTime - entry.time < config.cacheExpiry then
            newCache[key] = entry
        end
    end
    
    module["_cache_" .. funcName] = newCache
}

-- Apply throttling to a function
function PerformanceOptimizer:ApplyThrottling(module, funcName)
    -- Don't reapply if already throttled
    if module["_throttled_" .. funcName] then
        return
    end
    
    -- Store original function
    module["_original_" .. funcName] = module[funcName]
    
    -- Create throttle data
    module["_throttle_" .. funcName] = {
        lastCall = 0,
        throttleTime = UPDATE_FREQUENCY * 2
    }
    
    -- Replace with throttled version
    module["_throttled_" .. funcName] = true
    
    module[funcName] = function(self, ...)
        local throttleData = module["_throttle_" .. funcName]
        local currentTime = GetTime()
        
        -- If called too frequently, skip
        if currentTime - throttleData.lastCall < throttleData.throttleTime then
            return
        end
        
        -- Update last call time
        throttleData.lastCall = currentTime
        
        -- Call original function
        local startTime = debugprofilestop()
        local results = {module["_original_" .. funcName](self, ...)}
        local endTime = debugprofilestop()
        
        -- Track performance
        local metrics = performanceData.functionMetrics[module._name .. ":" .. funcName] or 
                       {totalTime = 0, calls = 0}
        metrics.totalTime = metrics.totalTime + (endTime - startTime)
        metrics.calls = metrics.calls + 1
        performanceData.functionMetrics[module._name .. ":" .. funcName] = metrics
        
        -- Adjust throttle time based on execution time
        local execTime = endTime - startTime
        if execTime > THRESHOLD_MS * 2 then
            -- If execution is very slow, increase throttle time
            throttleData.throttleTime = math.min(throttleData.throttleTime * 1.5, UPDATE_FREQUENCY * 10)
        elseif execTime < THRESHOLD_MS / 2 then
            -- If execution is fast, decrease throttle time
            throttleData.throttleTime = math.max(throttleData.throttleTime * 0.8, UPDATE_FREQUENCY)
        end
        
        return unpack(results)
    end
    
    WR:Debug("Applied throttling to", module._name .. ":" .. funcName)
}

-- Apply processing limits to a function
function PerformanceOptimizer:ApplyProcessingLimit(module, funcName)
    -- Don't reapply if already limited
    if module["_limited_" .. funcName] then
        return
    end
    
    -- Only apply if limitProcessingTime is enabled
    if not config.limitProcessingTime then
        return
    end
    
    -- Store original function
    module["_original_" .. funcName] = module[funcName]
    
    -- Replace with limited version
    module["_limited_" .. funcName] = true
    
    module[funcName] = function(self, ...)
        -- Track start time
        local startTime = debugprofilestop()
        
        -- Set up time check
        local function checkTime()
            local currentTime = debugprofilestop()
            return (currentTime - startTime) > config.maxProcessingTime
        end
        
        -- Add time check to any loops in the function
        -- This is complex and would need special handling for each function
        -- Here's a simple version that just bails out if it takes too long
        
        -- Call original with timeout
        local results
        local success = xpcall(function()
            -- Set up a timer to bail out if it takes too long
            local bailoutTimer = C_Timer.NewTimer(config.maxProcessingTime / 1000, function()
                error("Processing time limit exceeded")
            end)
            
            results = {module["_original_" .. funcName](self, ...)}
            
            -- Cancel timer if we finish in time
            bailoutTimer:Cancel()
        end, function(err)
            WR:Debug("Processing limit triggered for", module._name .. ":" .. funcName)
            -- Just return empty results on error
            results = {}
        end)
        
        local endTime = debugprofilestop()
        
        -- Track performance
        local metrics = performanceData.functionMetrics[module._name .. ":" .. funcName] or 
                       {totalTime = 0, calls = 0}
        metrics.totalTime = metrics.totalTime + (endTime - startTime)
        metrics.calls = metrics.calls + 1
        performanceData.functionMetrics[module._name .. ":" .. funcName] = metrics
        
        return unpack(results or {})
    end
    
    WR:Debug("Applied processing limits to", module._name .. ":" .. funcName)
}

-- Optimize a specific module
function PerformanceOptimizer:OptimizeModule(moduleName)
    local module = WR[moduleName]
    
    if not module then
        WR:Debug("Module not found:", moduleName)
        return
    end
    
    -- Check if the module has an optimizer
    if module.OptimizePerformance and type(module.OptimizePerformance) == "function" then
        -- Let the module handle its own optimization
        module:OptimizePerformance(config.performanceLevel)
        WR:Debug("Applied module-specific optimizations to", moduleName)
        return
    end
    
    -- Apply general optimizations based on module type
    if moduleName == "UI" or moduleName:match("UI$") then
        -- UI module optimizations
        self:OptimizeUIModule(module, moduleName)
    elseif moduleName == "Rotation" or moduleName:match("Rotation$") then
        -- Rotation module optimizations
        self:OptimizeRotationModule(module, moduleName)
    elseif moduleName == "Combat" or moduleName:match("Combat$") then
        -- Combat module optimizations
        self:OptimizeCombatModule(module, moduleName)
    elseif moduleName == "Analytics" or moduleName:match("Analytics$") then
        -- Analytics module optimizations
        self:OptimizeAnalyticsModule(module, moduleName)
    elseif moduleName == "LearningSystem" then
        -- Learning system optimizations
        self:OptimizeLearningSystem(module)
    end
    
    WR:Debug("Applied general optimizations to", moduleName)
}

-- Optimize UI modules
function PerformanceOptimizer:OptimizeUIModule(module, moduleName)
    -- Reduce update frequency for UI elements
    if module.SetUpdateFrequency and type(module.SetUpdateFrequency) == "function" then
        local frequency = InCombatLockdown() and 0.1 or 0.2
        module:SetUpdateFrequency(frequency)
    end
    
    -- Disable animations in combat if configured
    if config.disableAnimationsInCombat and InCombatLockdown() then
        if module.DisableAnimations and type(module.DisableAnimations) == "function" then
            module:DisableAnimations()
        end
    end
    
    -- Reduce UI complexity if in a low-performance state
    if performanceData.adaptiveMode then
        if module.SetPerformanceMode and type(module.SetPerformanceMode) == "function" then
            module:SetPerformanceMode("low")
        end
    end
}

-- Optimize rotation modules
function PerformanceOptimizer:OptimizeRotationModule(module, moduleName)
    -- Reduce number of abilities considered in low performance mode
    if performanceData.adaptiveMode then
        if module.SetMaxAbilities and type(module.SetMaxAbilities) == "function" then
            module:SetMaxAbilities(3) -- Only consider top 3 abilities
        end
    end
    
    -- Increase threshold for recalculation
    if module.SetRecalculationThreshold and type(module.SetRecalculationThreshold) == "function" then
        module:SetRecalculationThreshold(0.5) -- Recalculate only every 0.5 seconds
    end
    
    -- Simplify calculations in combat
    if InCombatLockdown() then
        if module.SetCalculationMode and type(module.SetCalculationMode) == "function" then
            module:SetCalculationMode("simple")
        end
    end
}

-- Optimize combat modules
function PerformanceOptimizer:OptimizeCombatModule(module, moduleName)
    -- Reduce aura scanning frequency
    if module.SetAuraScanFrequency and type(module.SetAuraScanFrequency) == "function" then
        local frequency = InCombatLockdown() and 0.2 or 0.5
        module:SetAuraScanFrequency(frequency)
    end
    
    -- Optimize target scanning
    if module.SetTargetScanMode and type(module.SetTargetScanMode) == "function" then
        local mode = performanceData.adaptiveMode and "efficient" or "normal"
        module:SetTargetScanMode(mode)
    end
    
    -- Limit number of targets tracked
    if performanceData.adaptiveMode and module.SetMaxTargets and type(module.SetMaxTargets) == "function" then
        module:SetMaxTargets(5) -- Only track 5 targets max
    end
}

-- Optimize analytics modules
function PerformanceOptimizer:OptimizeAnalyticsModule(module, moduleName)
    -- Disable detailed analytics in combat
    if InCombatLockdown() and module.SetDetailLevel and type(module.SetDetailLevel) == "function" then
        module:SetDetailLevel("low")
    end
    
    -- Reduce data collection frequency
    if module.SetDataCollectionFrequency and type(module.SetDataCollectionFrequency) == "function" then
        local frequency = performanceData.adaptiveMode and 5 or 1
        module:SetDataCollectionFrequency(frequency)
    end
    
    -- Batch analytics operations
    if module.EnableBatching and type(module.EnableBatching) == "function" then
        module:EnableBatching(true)
    end
}

-- Optimize learning system
function PerformanceOptimizer:OptimizeLearningSystem(module)
    -- Adjust learning cycle frequency
    if module.SetLearningCycleFrequency and type(module.SetLearningCycleFrequency) == "function" then
        local frequency = performanceData.adaptiveMode and 600 or 300
        module:SetLearningCycleFrequency(frequency)
    end
    
    -- Reduce sample size in combat
    if InCombatLockdown() and module.SetMaxSamples and type(module.SetMaxSamples) == "function" then
        module:SetMaxSamples(200) -- Reduce to 200 samples in combat
    end
    
    -- Simplify learning in low performance mode
    if performanceData.adaptiveMode and module.SetLearningComplexity and type(module.SetLearningComplexity) == "function" then
        module:SetLearningComplexity("low")
    end
}

-- Optimize update frequency
function PerformanceOptimizer:OptimizeUpdateFrequency()
    if not config.adaptiveUpdateFrequency then
        return
    end
    
    local avgFPS = self:GetAverageFPS()
    
    -- Adjust update frequency based on FPS
    if avgFPS < config.lowPerformanceThreshold then
        -- Low FPS, reduce update frequency
        config.customUpdateFrequency = UPDATE_FREQUENCY * 2
        WR:Debug("Reducing update frequency due to low FPS:", avgFPS)
    elseif avgFPS > config.highPerformanceThreshold then
        -- High FPS, increase update frequency
        config.customUpdateFrequency = UPDATE_FREQUENCY * 0.75
        WR:Debug("Increasing update frequency due to high FPS:", avgFPS)
    else
        -- Normal FPS, use default
        config.customUpdateFrequency = nil
    end
}

-- Enter combat performance mode
function PerformanceOptimizer:EnterCombatMode()
    WR:Debug("Entering combat performance mode")
    
    -- Store pre-combat settings
    performanceData.preCombatSettings = {
        updateFrequency = config.customUpdateFrequency,
        aggressiveOptimization = config.aggressiveOptimization
    }
    
    -- Apply combat-specific optimizations
    if config.disableAnimationsInCombat then
        self:DisableAnimations()
    end
    
    -- Adjust update frequency for combat
    config.customUpdateFrequency = COMBAT_UPDATE_FREQUENCY
    
    -- Apply more aggressive optimizations in combat
    config.aggressiveOptimization = true
    
    -- Perform immediate garbage collection before intense activity
    if config.automaticGC then
        collectgarbage("collect")
        performanceData.lastGC = GetTime()
    end
    
    -- Apply module-specific combat optimizations
    for moduleName, module in pairs(WR) do
        if type(module) == "table" and module.EnterCombatMode and type(module.EnterCombatMode) == "function" then
            module:EnterCombatMode()
        end
    end
}

-- Leave combat performance mode
function PerformanceOptimizer:LeaveCombatMode()
    WR:Debug("Leaving combat performance mode")
    
    -- Restore pre-combat settings
    if performanceData.preCombatSettings then
        config.customUpdateFrequency = performanceData.preCombatSettings.updateFrequency
        config.aggressiveOptimization = performanceData.preCombatSettings.aggressiveOptimization
    else
        config.customUpdateFrequency = nil
        config.aggressiveOptimization = false
    end
    
    -- Re-enable animations if they were disabled
    if config.disableAnimationsInCombat then
        self:EnableAnimations()
    end
    
    -- Apply module-specific post-combat optimizations
    for moduleName, module in pairs(WR) do
        if type(module) == "table" and module.LeaveCombatMode and type(module.LeaveCombatMode) == "function" then
            module:LeaveCombatMode()
        end
    end
    
    -- Perform garbage collection after combat
    if config.automaticGC then
        collectgarbage("collect")
        performanceData.lastGC = GetTime()
    end
}

-- Disable animations for performance
function PerformanceOptimizer:DisableAnimations()
    -- Find UI modules with animations
    for moduleName, module in pairs(WR) do
        if type(module) == "table" and (moduleName:match("UI$") or moduleName:match("Animation")) then
            if module.DisableAnimations and type(module.DisableAnimations) == "function" then
                module:DisableAnimations()
            end
        end
    end
}

-- Enable animations
function PerformanceOptimizer:EnableAnimations()
    -- Find UI modules with animations
    for moduleName, module in pairs(WR) do
        if type(module) == "table" and (moduleName:match("UI$") or moduleName:match("Animation")) then
            if module.EnableAnimations and type(module.EnableAnimations) == "function" then
                module:EnableAnimations()
            end
        end
    end
}

-- Apply base optimizations that are always active
function PerformanceOptimizer:ApplyBaseOptimizations()
    -- Set up table optimizations
    self:OptimizeTableFunctions()
    
    -- Set up string optimizations
    self:OptimizeStringFunctions()
    
    -- Apply Lua optimizations
    self:ApplyLuaOptimizations()
    
    -- Apply rendering optimizations
    self:ApplyRenderingOptimizations()
    
    -- Apply caching system
    self:InitializeCacheSystem()
    
    WR:Debug("Applied base optimizations")
}

-- Optimize common table functions
function PerformanceOptimizer:OptimizeTableFunctions()
    -- Cache common table functions
    local table_insert = table.insert
    local table_remove = table.remove
    local table_sort = table.sort
    
    -- Optimize table.insert
    table.insert = function(t, ...)
        if not t then return end
        return table_insert(t, ...)
    end
    
    -- Optimize table.remove
    table.remove = function(t, pos)
        if not t or #t == 0 then return nil end
        return table_remove(t, pos)
    end
    
    -- Optimize table.sort
    table.sort = function(t, comp)
        if not t or #t <= 1 then return end
        return table_sort(t, comp)
    end
    
    -- Add fast version of table.wipe
    if not table.wipe then
        table.wipe = function(t)
            if not t then return end
            for k in pairs(t) do
                t[k] = nil
            end
            return t
        end
    end
}

-- Optimize string functions
function PerformanceOptimizer:OptimizeStringFunctions()
    -- Cache common string functions
    local string_format = string.format
    local string_match = string.match
    local string_gsub = string.gsub
    local string_lower = string.lower
    local string_upper = string.upper
    
    -- Create string matching cache
    local matchCache = {}
    string.match = function(s, pattern, init)
        if not s or not pattern then return string_match(s, pattern, init) end
        
        local cacheKey = s .. ":" .. pattern .. ":" .. (init or "")
        if matchCache[cacheKey] then return unpack(matchCache[cacheKey]) end
        
        local results = {string_match(s, pattern, init)}
        matchCache[cacheKey] = results
        
        -- Limit cache size
        local count = 0
        for _ in pairs(matchCache) do
            count = count + 1
        end
        
        if count > 1000 then
            -- Clear oldest cache entries
            local oldestKeys = {}
            local i = 0
            for k in pairs(matchCache) do
                i = i + 1
                oldestKeys[i] = k
                if i >= 500 then break end
            end
            
            for j = 1, #oldestKeys do
                matchCache[oldestKeys[j]] = nil
            end
        end
        
        return unpack(results)
    end
}

-- Apply general Lua optimizations
function PerformanceOptimizer:ApplyLuaOptimizations()
    -- Set up faster local references for frequently used globals
    _G.GetTime = GetTime
    _G.tinsert = table.insert
    _G.tremove = table.remove
    _G.UnitGUID = UnitGUID
    _G.UnitHealth = UnitHealth
    _G.UnitHealthMax = UnitHealthMax
    _G.UnitExists = UnitExists
    _G.UnitPower = UnitPower
    _G.UnitPowerMax = UnitPowerMax
    _G.GetSpellInfo = GetSpellInfo
    _G.InCombatLockdown = InCombatLockdown
    
    -- Set up optimized versions of expensive operations
    _G.GetHealthPercent = function(unit)
        if not UnitExists(unit) then return 0 end
        return UnitHealth(unit) / UnitHealthMax(unit) * 100
    end
    
    _G.GetResourcePercent = function(unit, resourceType)
        if not UnitExists(unit) then return 0 end
        return UnitPower(unit, resourceType or 0) / UnitPowerMax(unit, resourceType or 0) * 100
    end
}

-- Apply rendering optimizations
function PerformanceOptimizer:ApplyRenderingOptimizations()
    -- Find rendering related modules
    for moduleName, module in pairs(WR) do
        if type(module) == "table" and (moduleName:match("UI$") or moduleName:match("Render")) then
            -- Apply rendering settings
            if module.SetRenderQuality and type(module.SetRenderQuality) == "function" then
                local quality = "medium"
                if performanceData.adaptiveMode then
                    quality = "low"
                elseif GetFramerate() > 60 then
                    quality = "high"
                end
                
                module:SetRenderQuality(quality)
            end
            
            -- Optimize update frequency
            if module.SetUpdateFrequency and type(module.SetUpdateFrequency) == "function" then
                local frequency = performanceData.adaptiveMode and 0.2 or 0.1
                module:SetUpdateFrequency(frequency)
            end
        end
    end
}

-- Initialize caching system
function PerformanceOptimizer:InitializeCacheSystem()
    -- Create global cache container
    WR.Cache = WR.Cache or {}
    
    -- Set up cache management functions
    WR.Cache.Get = function(category, key)
        if not WR.Cache[category] then return nil end
        
        local entry = WR.Cache[category][key]
        if not entry then return nil end
        
        -- Check expiry
        if entry.expires and entry.expires < GetTime() then
            WR.Cache[category][key] = nil
            return nil
        end
        
        return entry.data
    end
    
    WR.Cache.Set = function(category, key, data, ttl)
        WR.Cache[category] = WR.Cache[category] or {}
        
        WR.Cache[category][key] = {
            data = data,
            expires = ttl and (GetTime() + ttl) or nil
        }
    end
    
    WR.Cache.Clear = function(category)
        if category then
            WR.Cache[category] = {}
        else
            for cat in pairs(WR.Cache) do
                if type(WR.Cache[cat]) == "table" then
                    WR.Cache[cat] = {}
                end
            end
        end
    end
    
    -- Set up automatic cache cleaning
    C_Timer.NewTicker(60, function()
        -- Clean expired cache entries
        for category, entries in pairs(WR.Cache) do
            if type(entries) == "table" then
                for key, entry in pairs(entries) do
                    if entry.expires and entry.expires < GetTime() then
                        entries[key] = nil
                    end
                end
            end
        end
    end)
}

-- Initialize throttling system
function PerformanceOptimizer:InitializeThrottling()
    -- Create throttle function
    WR.Throttle = function(func, interval)
        local lastCall = 0
        
        return function(...)
            local currentTime = GetTime()
            if currentTime - lastCall < interval then
                return
            end
            
            lastCall = currentTime
            return func(...)
        end
    end
    
    -- Create debounce function
    WR.Debounce = function(func, wait)
        local timer
        
        return function(...)
            local args = {...}
            
            if timer then
                timer:Cancel()
            end
            
            timer = C_Timer.NewTimer(wait, function()
                func(unpack(args))
                timer = nil
            end)
        end
    end
}

-- Register performance hooks
function PerformanceOptimizer:RegisterPerformanceHooks()
    -- Hook into modules to monitor performance
    for moduleName, module in pairs(WR) do
        if type(module) == "table" and module.Initialize then
            -- Skip if already hooked
            if module._performance_hooked then
                goto continue
            end
            
            -- Store original functions
            module._original_functions = module._original_functions or {}
            
            -- Hook important functions
            for funcName, func in pairs(module) do
                if type(func) == "function" and not funcName:match("^_") then
                    module._original_functions[funcName] = func
                    
                    module[funcName] = function(self, ...)
                        -- Skip performance tracking for the optimizer itself
                        if moduleName == "PerformanceOptimizer" then
                            return module._original_functions[funcName](self, ...)
                        end
                        
                        local startTime = debugprofilestop()
                        local results = {module._original_functions[funcName](self, ...)}
                        local endTime = debugprofilestop()
                        
                        -- Track function performance
                        local funcKey = moduleName .. ":" .. funcName
                        performanceData.functionMetrics[funcKey] = performanceData.functionMetrics[funcKey] or {totalTime = 0, calls = 0}
                        performanceData.functionMetrics[funcKey].totalTime = performanceData.functionMetrics[funcKey].totalTime + (endTime - startTime)
                        performanceData.functionMetrics[funcKey].calls = performanceData.functionMetrics[funcKey].calls + 1
                        
                        -- Check if this is an update function
                        if funcName:match("^Update") or funcName:match("^Refresh") or funcName:match("^Draw") then
                            -- Track update times
                            if #performanceData.updateTimes >= 50 then
                                table.remove(performanceData.updateTimes, 1)
                            end
                            
                            table.insert(performanceData.updateTimes, endTime - startTime)
                        end
                        
                        return unpack(results)
                    end
                end
            end
            
            -- Mark as hooked
            module._performance_hooked = true
            
            -- Store module name for reference
            module._name = moduleName
            
            ::continue::
        end
    end
}

-- Monitor module performance
function PerformanceOptimizer:MonitorModulePerformance()
    -- Loop through modules
    for moduleName, module in pairs(WR) do
        if type(module) == "table" and module._performance_hooked then
            -- Calculate total time spent in this module
            local totalTime = 0
            local totalCalls = 0
            
            -- Find all functions belonging to this module
            for funcKey, metrics in pairs(performanceData.functionMetrics) do
                if funcKey:match("^" .. moduleName .. ":") then
                    totalTime = totalTime + metrics.totalTime
                    totalCalls = totalCalls + metrics.calls
                end
            end
            
            -- Store module performance data
            performanceData.modulePerformance[moduleName] = {
                totalTime = totalTime,
                calls = totalCalls,
                updateTime = totalTime / math.max(1, totalCalls)
            }
        end
    end
}

-- Get performance analysis
function PerformanceOptimizer:GetPerformanceAnalysis()
    local analysis = {
        cpuUsage = 0,
        memoryUsage = 0,
        framerate = GetFramerate(),
        bottlenecks = {},
        moduleUsage = {},
        optimizations = {}
    }
    
    -- Calculate CPU usage
    if #performanceData.cpuTime >= 2 then
        analysis.cpuUsage = (performanceData.cpuTime[#performanceData.cpuTime] - performanceData.cpuTime[1]) / 
                          (#performanceData.cpuTime * UPDATE_FREQUENCY)
    end
    
    -- Get memory usage
    analysis.memoryUsage = self:GetMemoryUsage()
    
    -- Get top bottlenecks
    analysis.bottlenecks = self:IdentifyBottlenecks()
    
    -- Get module usage
    for moduleName, metrics in pairs(performanceData.modulePerformance) do
        analysis.moduleUsage[moduleName] = {
            time = metrics.updateTime,
            calls = metrics.calls,
            percentage = (metrics.totalTime / math.max(1, analysis.cpuUsage)) * 100
        }
    end
    
    -- Get applied optimizations
    for name in pairs(performanceData.optimizationApplied) do
        table.insert(analysis.optimizations, name)
    end
    
    return analysis
}

-- Get configuration
function PerformanceOptimizer:GetConfig()
    return config
}

-- Set configuration
function PerformanceOptimizer:SetConfig(newConfig)
    if not newConfig then return end
    
    -- Store old config for reference
    local oldConfig = CopyTable(config)
    
    -- Update config
    for k, v in pairs(newConfig) do
        if config[k] ~= nil then  -- Only update existing settings
            config[k] = v
        end
    end
    
    -- Handle specific config changes
    if oldConfig.enabled ~= config.enabled then
        if config.enabled then
            WR:Debug("Performance optimization enabled")
            self:ApplyBaseOptimizations()
        else
            WR:Debug("Performance optimization disabled")
        end
    end
    
    -- Save configuration
    self:SaveSettings()
}

-- Handle performance commands
function PerformanceOptimizer:HandleCommand(args)
    if not args or args == "" then
        -- Show performance analysis
        self:ShowPerformanceAnalysis()
        return
    end
    
    local command, parameter = args:match("^(%S+)%s*(.*)$")
    command = command and command:lower() or args:lower()
    
    if command == "analyze" or command == "analysis" then
        -- Show detailed analysis
        self:ShowPerformanceAnalysis(true)
    elseif command == "gc" or command == "collect" then
        -- Force garbage collection
        collectgarbage("collect")
        WR:Print("Performed garbage collection")
    elseif command == "optimize" then
        -- Force optimization
        WR:Print("Applying performance optimizations...")
        self:OptimizePerformance()
        WR:Print("Optimizations applied")
    elseif command == "reset" then
        -- Reset optimization data
        performanceData.optimizationApplied = {}
        performanceData.bottlenecks = {}
        WR:Print("Reset optimization data")
    elseif command == "bottlenecks" then
        -- Show bottlenecks
        self:ShowBottlenecks()
    elseif command == "modules" then
        -- Show module performance
        self:ShowModulePerformance()
    elseif command == "config" then
        -- Show/set configuration
        if parameter == "" then
            -- Show configuration
            self:ShowConfig()
        else
            -- Parse configuration setting
            local setting, value = parameter:match("^(%S+)%s+(.+)$")
            
            if setting and value and config[setting] ~= nil then
                -- Convert value based on setting type
                if type(config[setting]) == "boolean" then
                    value = value:lower()
                    config[setting] = (value == "true" or value == "yes" or value == "1" or value == "on")
                elseif type(config[setting]) == "number" then
                    config[setting] = tonumber(value) or config[setting]
                else
                    config[setting] = value
                end
                
                -- Save configuration
                self:SaveSettings()
                
                WR:Print("Set", setting, "to", tostring(config[setting]))
            else
                WR:Print("Unknown setting:", setting)
                WR:Print("Available settings:")
                
                for k, v in pairs(config) do
                    WR:Print("  -", k, "=", tostring(v), "(", type(v), ")")
                end
            end
        end
    else
        -- Unknown command
        WR:Print("Unknown performance command:", command)
        WR:Print("Available commands: analyze, gc, optimize, reset, bottlenecks, modules, config")
    end
}

-- Show performance analysis
function PerformanceOptimizer:ShowPerformanceAnalysis(detailed)
    local analysis = self:GetPerformanceAnalysis()
    
    WR:Print("Performance Analysis:")
    WR:Print("FPS:", string.format("%.1f", analysis.framerate))
    WR:Print("Memory Usage:", string.format("%.2f", analysis.memoryUsage), "MB")
    
    if detailed then
        WR:Print("")
        WR:Print("Top Bottlenecks:")
        
        for i, bottleneck in ipairs(analysis.bottlenecks) do
            if i > 5 then break end
            
            WR:Print(i .. ".", bottleneck.type, bottleneck.name, 
                     "- Avg Time:", string.format("%.2f", bottleneck.averageTime), "ms")
        end
        
        WR:Print("")
        WR:Print("Top Module Usage:")
        
        local sortedModules = {}
        for moduleName, usage in pairs(analysis.moduleUsage) do
            table.insert(sortedModules, {
                name = moduleName,
                time = usage.time,
                percentage = usage.percentage
            })
        end
        
        table.sort(sortedModules, function(a, b)
            return a.time > b.time
        end)
        
        for i, moduleData in ipairs(sortedModules) do
            if i > 5 then break end
            
            WR:Print(i .. ".", moduleData.name,
                     "- Avg Time:", string.format("%.2f", moduleData.time), "ms",
                     "(", string.format("%.1f", moduleData.percentage), "%)")
        end
        
        WR:Print("")
        WR:Print("Applied Optimizations:", #analysis.optimizations)
    end
}

-- Show bottlenecks
function PerformanceOptimizer:ShowBottlenecks()
    local bottlenecks = self:IdentifyBottlenecks()
    
    WR:Print("Performance Bottlenecks:")
    
    if #bottlenecks == 0 then
        WR:Print("No significant bottlenecks detected")
        return
    end
    
    for i, bottleneck in ipairs(bottlenecks) do
        WR:Print(i .. ".", bottleneck.type, bottleneck.name,
                 "- Time:", string.format("%.2f", bottleneck.averageTime), "ms",
                 "- Priority:", string.format("%.1f", bottleneck.priority))
    end
}

-- Show module performance
function PerformanceOptimizer:ShowModulePerformance()
    WR:Print("Module Performance:")
    
    local sortedModules = {}
    for moduleName, metrics in pairs(performanceData.modulePerformance) do
        table.insert(sortedModules, {
            name = moduleName,
            updateTime = metrics.updateTime,
            calls = metrics.calls,
            totalTime = metrics.totalTime
        })
    end
    
    table.sort(sortedModules, function(a, b)
        return a.updateTime > b.updateTime
    end)
    
    for i, module in ipairs(sortedModules) do
        WR:Print(i .. ".", module.name,
                 "- Avg Time:", string.format("%.2f", module.updateTime), "ms",
                 "- Calls:", module.calls,
                 "- Total:", string.format("%.2f", module.totalTime), "ms")
    end
}

-- Show configuration
function PerformanceOptimizer:ShowConfig()
    WR:Print("Performance Optimizer Configuration:")
    
    for k, v in pairs(config) do
        WR:Print(k .. ":", tostring(v))
    end
    
    WR:Print("")
    WR:Print("To change a setting, use: /wr performance config setting value")
    WR:Print("Example: /wr performance config performanceLevel 3")
}

-- Create performance UI
function PerformanceOptimizer:CreatePerformanceUI(parent)
    if not parent then return end
    
    -- Create the frame
    local frame = CreateFrame("Frame", "WindrunnerRotationsPerformanceUI", parent, "BackdropTemplate")
    frame:SetSize(700, 500)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    frame:SetBackdropColor(0.1, 0.1, 0.1, 1)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    
    -- Create title
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", frame, "TOP", 0, -15)
    title:SetText("Windrunner Rotations Performance")
    
    -- Create close button
    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    
    -- Create tab buttons
    local tabWidth = 120
    local tabHeight = 24
    local tabs = {}
    local tabContents = {}
    
    local tabNames = {"Overview", "Bottlenecks", "Modules", "Settings"}
    
    for i, tabName in ipairs(tabNames) do
        -- Create tab button
        local tab = CreateFrame("Button", nil, frame)
        tab:SetSize(tabWidth, tabHeight)
        tab:SetPoint("TOPLEFT", frame, "TOPLEFT", 20 + (i-1) * (tabWidth + 5), -40)
        
        local tabText = tab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        tabText:SetPoint("CENTER", tab, "CENTER", 0, 0)
        tabText:SetText(tabName)
        
        -- Create highlight texture
        local highlightTexture = tab:CreateTexture(nil, "HIGHLIGHT")
        highlightTexture:SetAllPoints()
        highlightTexture:SetColorTexture(1, 1, 1, 0.2)
        
        -- Create selected texture
        local selectedTexture = tab:CreateTexture(nil, "BACKGROUND")
        selectedTexture:SetAllPoints()
        selectedTexture:SetColorTexture(0.2, 0.4, 0.8, 0.2)
        selectedTexture:Hide()
        tab.selectedTexture = selectedTexture
        
        -- Create tab content frame
        local content = CreateFrame("Frame", nil, frame)
        content:SetSize(frame:GetWidth() - 40, frame:GetHeight() - 80)
        content:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -70)
        content:Hide()
        
        -- Set up tab behavior
        tab:SetScript("OnClick", function()
            -- Hide all contents
            for _, contentFrame in ipairs(tabContents) do
                contentFrame:Hide()
            end
            
            -- Show this content
            content:Show()
            
            -- Update tab appearance
            for _, tabButton in ipairs(tabs) do
                tabButton.selectedTexture:Hide()
            end
            
            tab.selectedTexture:Show()
            
            -- Update content
            if tabName == "Overview" then
                PerformanceOptimizer:UpdateOverviewTab(content)
            elseif tabName == "Bottlenecks" then
                PerformanceOptimizer:UpdateBottlenecksTab(content)
            elseif tabName == "Modules" then
                PerformanceOptimizer:UpdateModulesTab(content)
            end
        end)
        
        tabs[i] = tab
        tabContents[i] = content
    end
    
    -- Populate Overview tab
    local overviewContent = tabContents[1]
    
    -- Function to update overview tab
    function PerformanceOptimizer:UpdateOverviewTab(content)
        -- Clear existing content
        for i = content:GetNumChildren(), 1, -1 do
            local child = select(i, content:GetChildren())
            if child:GetName() ~= "OverviewFrame" and 
               child:GetName() ~= "MemoryFrame" and
               child:GetName() ~= "OptimizationsFrame" then
                child:Hide()
                child:SetParent(nil)
            end
        end
        
        -- Create or get performance stats frame
        local statsFrame = _G["OverviewFrame"] or CreateFrame("Frame", "OverviewFrame", content, "BackdropTemplate")
        statsFrame:SetSize(content:GetWidth(), 100)
        statsFrame:SetPoint("TOP", content, "TOP", 0, 0)
        statsFrame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        statsFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
        
        -- Get performance analysis
        local analysis = self:GetPerformanceAnalysis()
        
        -- Create or update stats
        local fpsText = statsFrame.fpsText or statsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        fpsText:SetPoint("TOPLEFT", statsFrame, "TOPLEFT", 20, -20)
        fpsText:SetText("FPS: " .. string.format("%.1f", analysis.framerate))
        statsFrame.fpsText = fpsText
        
        local memoryText = statsFrame.memoryText or statsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        memoryText:SetPoint("TOPLEFT", fpsText, "BOTTOMLEFT", 0, -10)
        memoryText:SetText("Memory: " .. string.format("%.2f", analysis.memoryUsage) .. " MB")
        statsFrame.memoryText = memoryText
        
        local statusText = statsFrame.statusText or statsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        statusText:SetPoint("TOPRIGHT", statsFrame, "TOPRIGHT", -20, -20)
        
        local status = "Normal"
        if performanceData.adaptiveMode then
            status = "Adaptive Mode"
        elseif InCombatLockdown() then
            status = "Combat Mode"
        end
        
        statusText:SetText("Status: " .. status)
        statsFrame.statusText = statusText
        
        local optimizationsText = statsFrame.optimizationsText or statsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        optimizationsText:SetPoint("TOPRIGHT", statusText, "BOTTOMRIGHT", 0, -10)
        optimizationsText:SetText("Optimizations: " .. #analysis.optimizations)
        statsFrame.optimizationsText = optimizationsText
        
        -- Create or update memory graph
        local memoryFrame = _G["MemoryFrame"] or CreateFrame("Frame", "MemoryFrame", content, "BackdropTemplate")
        memoryFrame:SetSize(content:GetWidth() / 2 - 5, 150)
        memoryFrame:SetPoint("TOPLEFT", statsFrame, "BOTTOMLEFT", 0, -10)
        memoryFrame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        memoryFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
        
        local memoryTitle = memoryFrame.title or memoryFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        memoryTitle:SetPoint("TOPLEFT", memoryFrame, "TOPLEFT", 15, -15)
        memoryTitle:SetText("Memory Usage")
        memoryFrame.title = memoryTitle
        
        -- Create memory graph
        if not memoryFrame.graph then
            memoryFrame.graph = CreateFrame("Frame", nil, memoryFrame)
            memoryFrame.graph:SetSize(memoryFrame:GetWidth() - 40, memoryFrame:GetHeight() - 50)
            memoryFrame.graph:SetPoint("BOTTOM", memoryFrame, "BOTTOM", 0, 15)
            
            -- Create graph lines
            for i = 1, 10 do
                local line = memoryFrame.graph:CreateTexture(nil, "ARTWORK")
                line:SetSize(2, memoryFrame.graph:GetHeight())
                line:SetPoint("TOPLEFT", memoryFrame.graph, "TOPLEFT", (i-1) * (memoryFrame.graph:GetWidth() / 9), 0)
                line:SetColorTexture(0.3, 0.3, 0.3, 0.5)
            end
            
            -- Create graph points
            memoryFrame.graph.points = {}
            for i = 1, 10 do
                local point = memoryFrame.graph:CreateTexture(nil, "OVERLAY")
                point:SetSize(4, 4)
                point:SetColorTexture(0, 0.7, 1, 1)
                memoryFrame.graph.points[i] = point
            end
        end
        
        -- Update memory graph
        local memoryData = performanceData.memoryUsage
        if #memoryData > 0 then
            -- Find min/max for scaling
            local minMemory = memoryData[1]
            local maxMemory = memoryData[1]
            
            for i = 2, #memoryData do
                minMemory = math.min(minMemory, memoryData[i])
                maxMemory = math.max(maxMemory, memoryData[i])
            end
            
            -- Ensure some range
            if maxMemory - minMemory < 1 then
                maxMemory = minMemory + 1
            end
            
            -- Update points
            local graphWidth = memoryFrame.graph:GetWidth()
            local graphHeight = memoryFrame.graph:GetHeight()
            
            for i = 1, math.min(10, #memoryData) do
                local xPos = (i-1) * (graphWidth / 9)
                local value = memoryData[math.max(1, #memoryData - 10 + i)]
                local yPercent = 1 - ((value - minMemory) / (maxMemory - minMemory))
                local yPos = yPercent * graphHeight
                
                memoryFrame.graph.points[i]:ClearAllPoints()
                memoryFrame.graph.points[i]:SetPoint("CENTER", memoryFrame.graph, "TOPLEFT", xPos, -yPos)
            end
            
            -- Hide unused points
            for i = #memoryData + 1, 10 do
                memoryFrame.graph.points[i]:Hide()
            end
        end
        
        -- Create or update optimizations list
        local optimizationsFrame = _G["OptimizationsFrame"] or CreateFrame("Frame", "OptimizationsFrame", content, "BackdropTemplate")
        optimizationsFrame:SetSize(content:GetWidth() / 2 - 5, 150)
        optimizationsFrame:SetPoint("TOPRIGHT", statsFrame, "BOTTOMRIGHT", 0, -10)
        optimizationsFrame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        optimizationsFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
        
        local optimizationsTitle = optimizationsFrame.title or optimizationsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        optimizationsTitle:SetPoint("TOPLEFT", optimizationsFrame, "TOPLEFT", 15, -15)
        optimizationsTitle:SetText("Recent Optimizations")
        optimizationsFrame.title = optimizationsTitle
        
        -- Create scroll frame for optimizations
        if not optimizationsFrame.scrollFrame then
            local scrollFrame = CreateFrame("ScrollFrame", nil, optimizationsFrame, "UIPanelScrollFrameTemplate")
            scrollFrame:SetSize(optimizationsFrame:GetWidth() - 40, optimizationsFrame:GetHeight() - 50)
            scrollFrame:SetPoint("TOPLEFT", optimizationsTitle, "BOTTOMLEFT", 0, -5)
            
            local scrollChild = CreateFrame("Frame", nil, scrollFrame)
            scrollChild:SetSize(scrollFrame:GetWidth(), 1) -- Height will be set dynamically
            scrollFrame:SetScrollChild(scrollChild)
            
            optimizationsFrame.scrollFrame = scrollFrame
            optimizationsFrame.scrollChild = scrollChild
        end
        
        -- Update optimizations list
        local scrollChild = optimizationsFrame.scrollChild
        
        -- Clear existing entries
        for i = scrollChild:GetNumChildren(), 1, -1 do
            local child = select(i, scrollChild:GetChildren())
            child:Hide()
            child:SetParent(nil)
        end
        
        -- Show optimizations
        local yOffset = 5
        for i, name in ipairs(analysis.optimizations) do
            local optText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            optText:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 5, -yOffset)
            optText:SetText(i .. ". " .. name)
            
            yOffset = yOffset + optText:GetHeight() + 5
        end
        
        scrollChild:SetHeight(math.max(yOffset, optimizationsFrame.scrollFrame:GetHeight()))
        
        -- Create buttons
        local optimizeButton = _G["OptimizeButton"] or CreateFrame("Button", "OptimizeButton", content, "UIPanelButtonTemplate")
        optimizeButton:SetSize(120, 30)
        optimizeButton:SetPoint("BOTTOMLEFT", content, "BOTTOMLEFT", 20, 20)
        optimizeButton:SetText("Optimize Now")
        optimizeButton:SetScript("OnClick", function()
            WR:Print("Applying performance optimizations...")
            PerformanceOptimizer:OptimizePerformance()
            WR:Print("Optimizations applied")
            
            -- Update the display after a short delay
            C_Timer.After(0.5, function()
                PerformanceOptimizer:UpdateOverviewTab(content)
            end)
        end)
        
        local gcButton = _G["GCButton"] or CreateFrame("Button", "GCButton", content, "UIPanelButtonTemplate")
        gcButton:SetSize(120, 30)
        gcButton:SetPoint("LEFT", optimizeButton, "RIGHT", 10, 0)
        gcButton:SetText("Garbage Collect")
        gcButton:SetScript("OnClick", function()
            collectgarbage("collect")
            WR:Print("Performed garbage collection")
            
            -- Update the display after a short delay
            C_Timer.After(0.5, function()
                PerformanceOptimizer:UpdateOverviewTab(content)
            end)
        end)
        
        local resetButton = _G["ResetButton"] or CreateFrame("Button", "ResetButton", content, "UIPanelButtonTemplate")
        resetButton:SetSize(120, 30)
        resetButton:SetPoint("LEFT", gcButton, "RIGHT", 10, 0)
        resetButton:SetText("Reset Data")
        resetButton:SetScript("OnClick", function()
            performanceData.optimizationApplied = {}
            performanceData.bottlenecks = {}
            WR:Print("Reset optimization data")
            
            -- Update the display after a short delay
            C_Timer.After(0.5, function()
                PerformanceOptimizer:UpdateOverviewTab(content)
            end)
        end)
    end
    
    -- Populate Bottlenecks tab
    local bottlenecksContent = tabContents[2]
    
    -- Function to update bottlenecks tab
    function PerformanceOptimizer:UpdateBottlenecksTab(content)
        -- Clear existing content
        for i = content:GetNumChildren(), 1, -1 do
            local child = select(i, content:GetChildren())
            child:Hide()
            child:SetParent(nil)
        end
        
        -- Create header
        local headerFrame = CreateFrame("Frame", nil, content, "BackdropTemplate")
        headerFrame:SetSize(content:GetWidth(), 50)
        headerFrame:SetPoint("TOP", content, "TOP", 0, 0)
        headerFrame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        headerFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
        
        local headerTitle = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        headerTitle:SetPoint("TOPLEFT", headerFrame, "TOPLEFT", 15, -15)
        headerTitle:SetText("Performance Bottlenecks")
        
        -- Create scroll frame for bottlenecks
        local scrollFrame = CreateFrame("ScrollFrame", nil, content, "UIPanelScrollFrameTemplate")
        scrollFrame:SetSize(content:GetWidth() - 30, content:GetHeight() - 60)
        scrollFrame:SetPoint("TOP", headerFrame, "BOTTOM", 0, -5)
        
        local scrollChild = CreateFrame("Frame", nil, scrollFrame)
        scrollChild:SetSize(scrollFrame:GetWidth(), 1) -- Height will be set dynamically
        scrollFrame:SetScrollChild(scrollChild)
        
        -- Get bottlenecks
        local bottlenecks = self:IdentifyBottlenecks()
        
        -- Display bottlenecks
        local yOffset = 10
        for i, bottleneck in ipairs(bottlenecks) do
            local bottleneckFrame = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
            bottleneckFrame:SetSize(scrollChild:GetWidth() - 20, 60)
            bottleneckFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, -yOffset)
            bottleneckFrame:SetBackdrop({
                bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile = true,
                tileSize = 16,
                edgeSize = 16,
                insets = { left = 4, right = 4, top = 4, bottom = 4 }
            })
            bottleneckFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
            
            local nameText = bottleneckFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            nameText:SetPoint("TOPLEFT", bottleneckFrame, "TOPLEFT", 15, -15)
            nameText:SetText(i .. ". " .. bottleneck.type .. ": " .. bottleneck.name)
            
            local timeText = bottleneckFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            timeText:SetPoint("TOPLEFT", nameText, "BOTTOMLEFT", 0, -5)
            timeText:SetText("Average Time: " .. string.format("%.2f", bottleneck.averageTime) .. " ms")
            
            local priorityText = bottleneckFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            priorityText:SetPoint("TOPLEFT", timeText, "BOTTOMLEFT", 0, -5)
            priorityText:SetText("Priority: " .. string.format("%.1f", bottleneck.priority))
            
            -- Optimize button
            local optimizeButton = CreateFrame("Button", nil, bottleneckFrame, "UIPanelButtonTemplate")
            optimizeButton:SetSize(80, 22)
            optimizeButton:SetPoint("TOPRIGHT", bottleneckFrame, "TOPRIGHT", -15, -15)
            optimizeButton:SetText("Optimize")
            optimizeButton:SetScript("OnClick", function()
                PerformanceOptimizer:ApplyOptimizationFor(bottleneck)
                WR:Print("Applied optimization for", bottleneck.type, bottleneck.name)
                
                -- Update the display after a short delay
                C_Timer.After(0.5, function()
                    PerformanceOptimizer:UpdateBottlenecksTab(content)
                end)
            end)
            
            yOffset = yOffset + bottleneckFrame:GetHeight() + 10
        end
        
        -- Handle empty list
        if #bottlenecks == 0 then
            local noBottlenecks = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            noBottlenecks:SetPoint("TOP", scrollChild, "TOP", 0, -50)
            noBottlenecks:SetText("No significant bottlenecks detected")
            
            yOffset = 100
        end
        
        scrollChild:SetHeight(math.max(yOffset, scrollFrame:GetHeight()))
    end
    
    -- Populate Modules tab
    local modulesContent = tabContents[3]
    
    -- Function to update modules tab
    function PerformanceOptimizer:UpdateModulesTab(content)
        -- Clear existing content
        for i = content:GetNumChildren(), 1, -1 do
            local child = select(i, content:GetChildren())
            child:Hide()
            child:SetParent(nil)
        end
        
        -- Create header
        local headerFrame = CreateFrame("Frame", nil, content, "BackdropTemplate")
        headerFrame:SetSize(content:GetWidth(), 50)
        headerFrame:SetPoint("TOP", content, "TOP", 0, 0)
        headerFrame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        headerFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
        
        local headerTitle = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        headerTitle:SetPoint("TOPLEFT", headerFrame, "TOPLEFT", 15, -15)
        headerTitle:SetText("Module Performance")
        
        -- Create scroll frame for modules
        local scrollFrame = CreateFrame("ScrollFrame", nil, content, "UIPanelScrollFrameTemplate")
        scrollFrame:SetSize(content:GetWidth() - 30, content:GetHeight() - 60)
        scrollFrame:SetPoint("TOP", headerFrame, "BOTTOM", 0, -5)
        
        local scrollChild = CreateFrame("Frame", nil, scrollFrame)
        scrollChild:SetSize(scrollFrame:GetWidth(), 1) -- Height will be set dynamically
        scrollFrame:SetScrollChild(scrollChild)
        
        -- Get module data
        local moduleData = {}
        for moduleName, metrics in pairs(performanceData.modulePerformance) do
            table.insert(moduleData, {
                name = moduleName,
                updateTime = metrics.updateTime,
                calls = metrics.calls,
                totalTime = metrics.totalTime
            })
        end
        
        -- Sort by update time
        table.sort(moduleData, function(a, b)
            return a.updateTime > b.updateTime
        end)
        
        -- Display modules
        local yOffset = 10
        for i, module in ipairs(moduleData) do
            local moduleFrame = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
            moduleFrame:SetSize(scrollChild:GetWidth() - 20, 60)
            moduleFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, -yOffset)
            moduleFrame:SetBackdrop({
                bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile = true,
                tileSize = 16,
                edgeSize = 16,
                insets = { left = 4, right = 4, top = 4, bottom = 4 }
            })
            moduleFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
            
            local nameText = moduleFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            nameText:SetPoint("TOPLEFT", moduleFrame, "TOPLEFT", 15, -15)
            nameText:SetText(i .. ". " .. module.name)
            
            local timeText = moduleFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            timeText:SetPoint("TOPLEFT", nameText, "BOTTOMLEFT", 0, -5)
            timeText:SetText("Average Time: " .. string.format("%.2f", module.updateTime) .. " ms")
            
            local callsText = moduleFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            callsText:SetPoint("TOPLEFT", timeText, "BOTTOMLEFT", 0, -5)
            callsText:SetText("Calls: " .. module.calls .. " | Total: " .. string.format("%.2f", module.totalTime) .. " ms")
            
            -- Optimize button
            local optimizeButton = CreateFrame("Button", nil, moduleFrame, "UIPanelButtonTemplate")
            optimizeButton:SetSize(80, 22)
            optimizeButton:SetPoint("TOPRIGHT", moduleFrame, "TOPRIGHT", -15, -15)
            optimizeButton:SetText("Optimize")
            optimizeButton:SetScript("OnClick", function()
                PerformanceOptimizer:OptimizeModule(module.name)
                WR:Print("Applied optimization for module", module.name)
                
                -- Update the display after a short delay
                C_Timer.After(0.5, function()
                    PerformanceOptimizer:UpdateModulesTab(content)
                end)
            end)
            
            yOffset = yOffset + moduleFrame:GetHeight() + 10
        end
        
        -- Handle empty list
        if #moduleData == 0 then
            local noModules = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            noModules:SetPoint("TOP", scrollChild, "TOP", 0, -50)
            noModules:SetText("No module performance data available")
            
            yOffset = 100
        end
        
        scrollChild:SetHeight(math.max(yOffset, scrollFrame:GetHeight()))
    end
    
    -- Populate Settings tab
    local settingsContent = tabContents[4]
    
    -- Create settings frame
    local settingsFrame = CreateFrame("Frame", nil, settingsContent, "BackdropTemplate")
    settingsFrame:SetSize(settingsContent:GetWidth(), settingsContent:GetHeight() - 50)
    settingsFrame:SetPoint("TOP", settingsContent, "TOP", 0, 0)
    settingsFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    settingsFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
    
    local settingsTitle = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    settingsTitle:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 15, -15)
    settingsTitle:SetText("Performance Settings")
    
    -- Create checkboxes for various settings
    local checkboxes = {}
    local checkY = -50
    local checkboxLabels = {
        enabledCheckbox = "Enable performance optimization",
        aggressiveOptimizationCheckbox = "Use aggressive optimization",
        monitorModulesCheckbox = "Monitor module performance",
        adaptiveUpdateFrequencyCheckbox = "Adapt update frequency automatically",
        limitProcessingTimeCheckbox = "Limit processing time per frame",
        throttleInBackgroundCheckbox = "Throttle when WoW is in background",
        automaticGCCheckbox = "Perform automatic garbage collection",
        logPerformanceIssuesCheckbox = "Log performance issues",
        disableAnimationsInCombatCheckbox = "Disable animations in combat",
        lowLatencyModeCheckbox = "Low latency mode",
        smartResourceTrackingCheckbox = "Smart resource tracking"
    }
    
    local i = 0
    for name, label in pairs(checkboxLabels) do
        local checkbox = CreateFrame("CheckButton", nil, settingsFrame, "UICheckButtonTemplate")
        checkbox:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 30, checkY - (i * 30))
        
        local text = checkbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
        text:SetText(label)
        
        checkboxes[name] = checkbox
        i = i + 1
    end
    
    -- Set initial values
    checkboxes.enabledCheckbox:SetChecked(config.enabled)
    checkboxes.aggressiveOptimizationCheckbox:SetChecked(config.aggressiveOptimization)
    checkboxes.monitorModulesCheckbox:SetChecked(config.monitorModules)
    checkboxes.adaptiveUpdateFrequencyCheckbox:SetChecked(config.adaptiveUpdateFrequency)
    checkboxes.limitProcessingTimeCheckbox:SetChecked(config.limitProcessingTime)
    checkboxes.throttleInBackgroundCheckbox:SetChecked(config.throttleInBackground)
    checkboxes.automaticGCCheckbox:SetChecked(config.automaticGC)
    checkboxes.logPerformanceIssuesCheckbox:SetChecked(config.logPerformanceIssues)
    checkboxes.disableAnimationsInCombatCheckbox:SetChecked(config.disableAnimationsInCombat)
    checkboxes.lowLatencyModeCheckbox:SetChecked(config.lowLatencyMode)
    checkboxes.smartResourceTrackingCheckbox:SetChecked(config.smartResourceTracking)
    
    -- Performance level slider
    local levelLabel = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    levelLabel:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 30, checkY - (i * 30) - 20)
    levelLabel:SetText("Performance Level:")
    
    local levelSlider = CreateFrame("Slider", nil, settingsFrame, "OptionsSliderTemplate")
    levelSlider:SetPoint("TOPLEFT", levelLabel, "BOTTOMLEFT", 20, -10)
    levelSlider:SetWidth(200)
    levelSlider:SetHeight(16)
    levelSlider:SetMinMaxValues(1, 3)
    levelSlider:SetValue(config.performanceLevel)
    levelSlider:SetValueStep(1)
    levelSlider:SetObeyStepOnDrag(true)
    
    -- Set labels
    _G[levelSlider:GetName() .. "Low"]:SetText("Low")
    _G[levelSlider:GetName() .. "High"]:SetText("High")
    _G[levelSlider:GetName() .. "Text"]:SetText(config.performanceLevel)
    
    -- Processing time slider
    local processingLabel = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    processingLabel:SetPoint("TOPLEFT", levelSlider, "BOTTOMLEFT", -20, -20)
    processingLabel:SetText("Max Processing Time (ms):")
    
    local processingSlider = CreateFrame("Slider", nil, settingsFrame, "OptionsSliderTemplate")
    processingSlider:SetPoint("TOPLEFT", processingLabel, "BOTTOMLEFT", 20, -10)
    processingSlider:SetWidth(200)
    processingSlider:SetHeight(16)
    processingSlider:SetMinMaxValues(1, 20)
    processingSlider:SetValue(config.maxProcessingTime)
    processingSlider:SetValueStep(1)
    processingSlider:SetObeyStepOnDrag(true)
    
    -- Set labels
    _G[processingSlider:GetName() .. "Low"]:SetText("1")
    _G[processingSlider:GetName() .. "High"]:SetText("20")
    _G[processingSlider:GetName() .. "Text"]:SetText(config.maxProcessingTime)
    
    -- Set up slider behavior
    levelSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value)
        _G[self:GetName() .. "Text"]:SetText(value)
    end)
    
    processingSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value)
        _G[self:GetName() .. "Text"]:SetText(value)
    end)
    
    -- Create save and reset buttons
    local saveButton = CreateFrame("Button", nil, settingsContent, "UIPanelButtonTemplate")
    saveButton:SetSize(100, 30)
    saveButton:SetPoint("BOTTOMRIGHT", settingsContent, "BOTTOMRIGHT", -10, 10)
    saveButton:SetText("Save")
    saveButton:SetScript("OnClick", function()
        -- Update config
        config.enabled = checkboxes.enabledCheckbox:GetChecked()
        config.aggressiveOptimization = checkboxes.aggressiveOptimizationCheckbox:GetChecked()
        config.monitorModules = checkboxes.monitorModulesCheckbox:GetChecked()
        config.adaptiveUpdateFrequency = checkboxes.adaptiveUpdateFrequencyCheckbox:GetChecked()
        config.limitProcessingTime = checkboxes.limitProcessingTimeCheckbox:GetChecked()
        config.throttleInBackground = checkboxes.throttleInBackgroundCheckbox:GetChecked()
        config.automaticGC = checkboxes.automaticGCCheckbox:GetChecked()
        config.logPerformanceIssues = checkboxes.logPerformanceIssuesCheckbox:GetChecked()
        config.disableAnimationsInCombat = checkboxes.disableAnimationsInCombatCheckbox:GetChecked()
        config.lowLatencyMode = checkboxes.lowLatencyModeCheckbox:GetChecked()
        config.smartResourceTracking = checkboxes.smartResourceTrackingCheckbox:GetChecked()
        
        config.performanceLevel = levelSlider:GetValue()
        config.maxProcessingTime = processingSlider:GetValue()
        
        -- Save configuration
        PerformanceOptimizer:SaveSettings()
        
        -- Apply changes
        if config.enabled then
            PerformanceOptimizer:ApplyBaseOptimizations()
        end
        
        WR:Print("Performance settings saved")
    end)
    
    local resetButton = CreateFrame("Button", nil, settingsContent, "UIPanelButtonTemplate")
    resetButton:SetSize(100, 30)
    resetButton:SetPoint("RIGHT", saveButton, "LEFT", -10, 0)
    resetButton:SetText("Reset")
    resetButton:SetScript("OnClick", function()
        -- Reset checkboxes to default values
        checkboxes.enabledCheckbox:SetChecked(true)
        checkboxes.aggressiveOptimizationCheckbox:SetChecked(false)
        checkboxes.monitorModulesCheckbox:SetChecked(true)
        checkboxes.adaptiveUpdateFrequencyCheckbox:SetChecked(true)
        checkboxes.limitProcessingTimeCheckbox:SetChecked(true)
        checkboxes.throttleInBackgroundCheckbox:SetChecked(true)
        checkboxes.automaticGCCheckbox:SetChecked(true)
        checkboxes.logPerformanceIssuesCheckbox:SetChecked(true)
        checkboxes.disableAnimationsInCombatCheckbox:SetChecked(false)
        checkboxes.lowLatencyModeCheckbox:SetChecked(false)
        checkboxes.smartResourceTrackingCheckbox:SetChecked(true)
        
        -- Reset sliders
        levelSlider:SetValue(2)
        processingSlider:SetValue(8)
    end)
    
    -- Select first tab by default
    tabs[1].selectedTexture:Show()
    tabContents[1]:Show()
    
    -- Update first tab content
    PerformanceOptimizer:UpdateOverviewTab(tabContents[1])
    
    -- Hide by default
    frame:Hide()
    
    return frame
}

-- Initialize the module
PerformanceOptimizer:Initialize()

return PerformanceOptimizer