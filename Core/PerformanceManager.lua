------------------------------------------
-- WindrunnerRotations - Performance Manager
-- Author: VortexQ8
-- The War Within Season 2
------------------------------------------

local addonName, WR = ...
local PerformanceManager = {}
WR.PerformanceManager = PerformanceManager

-- Dependencies
local API = WR.API
local ConfigRegistry = WR.ConfigRegistry
local ModuleManager = WR.ModuleManager

-- Performance data
local isEnabled = true
local performanceFrame = nil
local updateFrequency = 0.1 -- How often to update performance metrics (seconds)
local lastUpdate = 0
local baselinePerformance = nil
local currentPerformance = nil
local performanceHistory = {}
local MAX_HISTORY_SIZE = 50
local throttledModules = {}
local throttleLevel = 0 -- 0 = No throttling, 10 = Maximum throttling
local currentFPS = 0
local averageFPS = 0
local fpsHistory = {}
local memoryUsage = 0
local memoryGrowth = 0
local lastMemoryCheck = 0
local memoryCheckInterval = 5 -- Check memory every 5 seconds
local optimizationsMade = {}
local isHighStressMode = false
local inCombat = false
local combatIntensity = 0 -- 0-10 scale of combat intensity
local playerHealth = 100
local THROTTLE_THRESHOLD_FPS = 30 -- FPS below this triggers throttling
local AUTO_OPTIMIZE_THRESHOLD = 20 -- FPS below this triggers emergency optimizations
local MIN_HEALTH_THROTTLE = 40 -- Health percentage below which throttling is relaxed
local COMBAT_PRIORITY_BOOST = 2 -- Reduce throttling in combat
local MEMORY_WARNING_THRESHOLD = 50 -- MB
local CPU_USAGE_WARNING = 60 -- ms per frame
local throttleMethods = {}
local optimizationQueue = {}
local moduleUpdateFrequencies = {}
local defaultUpdateFrequencies = {}
local frameProfileData = {}
local FRAME_PROFILE_SAMPLES = 10
local lastGC = 0
local GC_INTERVAL = 60 -- Garbage collect every 60 seconds
local optimizationThresholds = {
    combat = {
        minimal = 60, -- FPS above this gets minimal optimization
        moderate = 40, -- FPS above this gets moderate optimization
        aggressive = 25 -- FPS below this gets aggressive optimization
    },
    outOfCombat = {
        minimal = 40, -- FPS above this gets minimal optimization
        moderate = 30, -- FPS above this gets moderate optimization
        aggressive = 20 -- FPS below this gets aggressive optimization
    }
}
local resourceUsage = {
    cpu = {
        total = 0,
        perModule = {}
    },
    memory = {
        total = 0,
        perModule = {}
    },
    time = {
        total = 0,
        perModule = {}
    }
}

-- Initialize the Performance Manager
function PerformanceManager:Initialize()
    -- Register settings
    self:RegisterSettings()
    
    -- Create performance frame
    self:CreatePerformanceFrame()
    
    -- Register events
    self:RegisterEvents()
    
    -- Set up throttle methods
    self:SetupThrottleMethods()
    
    -- Register default module frequencies
    self:RegisterDefaultFrequencies()
    
    -- Collect initial performance baseline
    self:CollectPerformanceBaseline()
    
    API.PrintDebug("Performance Manager initialized")
    return true
end

-- Register settings
function PerformanceManager:RegisterSettings()
    ConfigRegistry:RegisterSettings("PerformanceManager", {
        generalSettings = {
            enablePerformanceManager = {
                displayName = "Enable Performance Management",
                description = "Automatically optimize addon performance",
                type = "toggle",
                default = true
            },
            optimizationLevel = {
                displayName = "Optimization Level",
                description = "How aggressively to optimize performance",
                type = "dropdown",
                options = {"Minimal", "Balanced", "Aggressive", "Maximum"},
                default = "Balanced"
            },
            fpsThreshold = {
                displayName = "FPS Threshold",
                description = "FPS below this will trigger performance optimizations",
                type = "slider",
                min = 10,
                max = 60,
                step = 5,
                default = 30
            },
            prioritizeCombat = {
                displayName = "Prioritize Combat",
                description = "Reduce optimizations during combat for better responsiveness",
                type = "toggle",
                default = true
            }
        },
        advancedSettings = {
            adaptiveThrottling = {
                displayName = "Adaptive Throttling",
                description = "Dynamically adjust module update frequencies based on performance",
                type = "toggle",
                default = true
            },
            throttleOutOfCombat = {
                displayName = "Throttle Out of Combat",
                description = "Apply heavier throttling when out of combat",
                type = "toggle",
                default = true
            },
            memoryManagement = {
                displayName = "Memory Management",
                description = "Actively manage memory usage",
                type = "toggle",
                default = true
            },
            agressiveGC = {
                displayName = "Aggressive Garbage Collection",
                description = "Force garbage collection more often",
                type = "toggle",
                default = false
            },
            gcInterval = {
                displayName = "Garbage Collection Interval",
                description = "Time between forced garbage collections (seconds)",
                type = "slider",
                min = 30,
                max = 300,
                step = 30,
                default = 60
            }
        },
        moduleSettings = {
            moduleSpecificThrottling = {
                displayName = "Module-Specific Throttling",
                description = "Apply different throttling levels to different modules",
                type = "toggle",
                default = true
            },
            lowHealthMode = {
                displayName = "Low Health Mode",
                description = "Reduce throttling when player health is low",
                type = "toggle",
                default = true
            },
            lowHealthThreshold = {
                displayName = "Low Health Threshold",
                description = "Health percentage considered 'low'",
                type = "slider",
                min = 10,
                max = 50,
                step = 5,
                default = 40
            }
        },
        uiSettings = {
            showPerformanceMetrics = {
                displayName = "Show Performance Metrics",
                description = "Display current performance metrics in the UI",
                type = "toggle",
                default = false
            },
            showThrottleIndicator = {
                displayName = "Show Throttle Indicator",
                description = "Display visual indicator when throttling is active",
                type = "toggle",
                default = true
            },
            showOptimizationTips = {
                displayName = "Show Optimization Tips",
                description = "Show tips to improve performance",
                type = "toggle",
                default = true
            }
        }
    })
}

-- Create performance frame
function PerformanceManager:CreatePerformanceFrame()
    performanceFrame = CreateFrame("Frame", "WindrunnerRotationsPerformanceFrame")
    
    -- Set up OnUpdate handler
    performanceFrame:SetScript("OnUpdate", function(self, elapsed)
        PerformanceManager:OnUpdate(elapsed)
    end)
}

-- Register events
function PerformanceManager:RegisterEvents()
    -- Register for combat state changes
    API.RegisterEvent("PLAYER_REGEN_DISABLED", function()
        PerformanceManager:OnEnterCombat()
    end)
    
    API.RegisterEvent("PLAYER_REGEN_ENABLED", function()
        PerformanceManager:OnLeaveCombat()
    end)
    
    -- Register for player health changes
    API.RegisterEvent("UNIT_HEALTH", function(unit)
        if unit == "player" then
            PerformanceManager:OnHealthChanged()
        end
    end)
    
    -- Register for entering world to reset baseline
    API.RegisterEvent("PLAYER_ENTERING_WORLD", function()
        PerformanceManager:ResetPerformanceBaseline()
    end)
}

-- Set up throttle methods
function PerformanceManager:SetupThrottleMethods()
    -- Define throttle methods for different modules
    throttleMethods = {
        -- Reduce update frequency
        updateFrequency = function(module, level)
            if not moduleUpdateFrequencies[module] then
                return false
            end
            
            -- Adjust frequency based on throttle level
            local baseFrequency = defaultUpdateFrequencies[module] or 0.1
            local newFrequency = baseFrequency * (1 + (level * 0.2))
            
            -- Cap at reasonable values
            newFrequency = math.min(newFrequency, 1.0)
            
            -- Apply new frequency
            moduleUpdateFrequencies[module] = newFrequency
            
            return true
        end,
        
        -- Skip non-essential processing
        skipNonEssential = function(module, level)
            -- Mark module for skipping non-essential processing
            if level >= 5 then
                throttledModules[module] = throttledModules[module] or {}
                throttledModules[module].skipNonEssential = true
            else
                if throttledModules[module] then
                    throttledModules[module].skipNonEssential = false
                end
            end
            
            return true
        end,
        
        -- Reduce processing detail
        reduceDetail = function(module, level)
            -- Mark module for reduced processing detail
            if level >= 3 then
                throttledModules[module] = throttledModules[module] or {}
                throttledModules[module].detailLevel = math.max(1, 10 - level)
            else
                if throttledModules[module] then
                    throttledModules[module].detailLevel = 10
                end
            end
            
            return true
        end,
        
        -- Disable completely
        disable = function(module, level)
            -- Only disable modules at maximum throttle level and if they're not critical
            if level >= 9 and not self:IsModuleCritical(module) then
                throttledModules[module] = throttledModules[module] or {}
                throttledModules[module].disabled = true
                
                -- Disable the module if it has an Enable method
                if WR[module] and WR[module].SetEnabled then
                    WR[module]:SetEnabled(false)
                end
                
                return true
            else
                if throttledModules[module] and throttledModules[module].disabled then
                    throttledModules[module].disabled = false
                    
                    -- Re-enable the module
                    if WR[module] and WR[module].SetEnabled then
                        WR[module]:SetEnabled(true)
                    end
                end
                
                return false
            end
        end
    }
}

-- Register default frequencies
function PerformanceManager:RegisterDefaultFrequencies()
    -- Define default update frequencies for different modules
    defaultUpdateFrequencies = {
        RotationManager = 0.05,      -- Fast updates for rotation logic
        InterruptManager = 0.1,      -- Regular updates for interrupt checking
        AutoTargeting = 0.2,         -- Slower updates for target selection
        CombatAnalysis = 0.1,        -- Regular updates for combat analysis
        GroupRoleManager = 1.0,      -- Slow updates for role detection
        TrinketManager = 0.5,        -- Medium updates for trinket usage
        MachineLearning = 1.0,       -- Slow updates for ML calculations
        KeybindManager = 0.1,        -- Regular updates for keybind handling
        CCChainAssist = 0.2,         -- Slower updates for CC suggestions
        EnhancedConfigUI = 0.5,      -- Medium updates for UI elements
        DynamicLearning = 1.0,       -- Slow updates for learning system
        CastSuggestion = 0.1,        -- Regular updates for cast suggestions
        EncounterSpecific = 0.2      -- Slower updates for encounter logic
    }
    
    -- Initialize current frequencies to defaults
    moduleUpdateFrequencies = {}
    for module, frequency in pairs(defaultUpdateFrequencies) do
        moduleUpdateFrequencies[module] = frequency
    end
}

-- OnUpdate handler
function PerformanceManager:OnUpdate(elapsed)
    -- Skip if disabled
    if not isEnabled then
        return
    end
    
    -- Update time tracking
    lastUpdate = lastUpdate + elapsed
    
    -- Only update at the specified frequency
    if lastUpdate < updateFrequency then
        return
    end
    
    -- Reset update timer
    lastUpdate = 0
    
    -- Update performance metrics
    self:UpdatePerformanceMetrics()
    
    -- Check if throttling is needed
    self:EvaluateThrottling()
    
    -- Check memory usage periodically
    if GetTime() - lastMemoryCheck > memoryCheckInterval then
        self:CheckMemoryUsage()
        lastMemoryCheck = GetTime()
    end
    
    -- Run garbage collection if needed
    if GetTime() - lastGC > GC_INTERVAL then
        self:RunGarbageCollection()
        lastGC = GetTime()
    end
    
    -- Process any queued optimizations
    self:ProcessOptimizationQueue()
}

-- Update performance metrics
function PerformanceManager:UpdatePerformanceMetrics()
    -- Get current FPS
    local newFPS = GetFramerate() or 0
    
    -- Update FPS history
    table.insert(fpsHistory, newFPS)
    if #fpsHistory > 10 then
        table.remove(fpsHistory, 1)
    end
    
    -- Calculate average FPS
    local fpsSum = 0
    for _, fps in ipairs(fpsHistory) do
        fpsSum = fpsSum + fps
    end
    averageFPS = fpsSum / #fpsHistory
    currentFPS = newFPS
    
    -- Update current performance data
    currentPerformance = {
        fps = currentFPS,
        memoryUsage = memoryUsage,
        memoryGrowth = memoryGrowth,
        throttleLevel = throttleLevel,
        timestamp = GetTime(),
        cpuUsage = self:EstimateCPUUsage(),
        moduleLoad = self:GetModuleLoadDistribution()
    }
    
    -- Add to history
    table.insert(performanceHistory, currentPerformance)
    
    -- Trim history if needed
    while #performanceHistory > MAX_HISTORY_SIZE do
        table.remove(performanceHistory, 1)
    end
    
    -- Profile frame execution times
    self:ProfileFrameExecution()
}

-- Evaluate throttling
function PerformanceManager:EvaluateThrottling()
    local settings = ConfigRegistry:GetSettings("PerformanceManager")
    
    -- Calculate desired throttle level
    local desiredThrottle = 0
    local fpsThreshold = settings.generalSettings.fpsThreshold
    
    -- Adjust based on FPS
    if currentFPS < fpsThreshold then
        -- Calculate how far below threshold we are
        local fpsDelta = fpsThreshold - currentFPS
        local maxDelta = fpsThreshold - 5 -- At 5 FPS, we're at max throttle
        
        -- Scale to 0-10 range
        desiredThrottle = math.min(10, math.max(0, (fpsDelta / maxDelta) * 10))
    end
    
    -- Adjust for combat
    if inCombat and settings.generalSettings.prioritizeCombat then
        desiredThrottle = math.max(0, desiredThrottle - COMBAT_PRIORITY_BOOST)
    end
    
    -- Adjust for low health
    if settings.moduleSettings.lowHealthMode and playerHealth < settings.moduleSettings.lowHealthThreshold then
        -- Reduce throttling when health is low for better responsiveness
        desiredThrottle = math.max(0, desiredThrottle - 3)
    end
    
    -- Special case: Out of combat more aggressive throttling
    if not inCombat and settings.advancedSettings.throttleOutOfCombat then
        desiredThrottle = desiredThrottle + 2
    end
    
    -- Gradually adjust current throttle level towards desired
    if desiredThrottle > throttleLevel then
        throttleLevel = math.min(10, throttleLevel + 1)
    elseif desiredThrottle < throttleLevel then
        throttleLevel = math.max(0, throttleLevel - 1)
    end
    
    -- Apply throttling to modules
    if throttleLevel > 0 and settings.advancedSettings.adaptiveThrottling then
        self:ApplyThrottling()
    else
        -- Remove throttling if it was previously applied
        self:RemoveThrottling()
    end
}

-- Apply throttling
function PerformanceManager:ApplyThrottling()
    local settings = ConfigRegistry:GetSettings("PerformanceManager")
    
    -- Get module-specific settings
    local moduleSpecific = settings.moduleSettings.moduleSpecificThrottling
    
    -- Apply throttling to each module
    for module, defaultFrequency in pairs(defaultUpdateFrequencies) do
        -- Skip modules that don't exist
        if not WR[module] then
            goto continue
        end
        
        -- Determine throttle level for this module
        local moduleThrottle = throttleLevel
        
        -- Adjust based on module priority
        if moduleSpecific then
            if self:IsModuleCritical(module) then
                -- Critical modules get less throttling
                moduleThrottle = math.max(0, moduleThrottle - 3)
            elseif self:IsModuleLowPriority(module) then
                -- Low priority modules get more throttling
                moduleThrottle = math.min(10, moduleThrottle + 2)
            end
        end
        
        -- Apply appropriate throttle methods
        if moduleThrottle >= 1 then
            -- Always adjust update frequency
            throttleMethods.updateFrequency(module, moduleThrottle)
        end
        
        if moduleThrottle >= 3 then
            -- Reduce detail at moderate throttling
            throttleMethods.reduceDetail(module, moduleThrottle)
        end
        
        if moduleThrottle >= 5 then
            -- Skip non-essential processing at high throttling
            throttleMethods.skipNonEssential(module, moduleThrottle)
        end
        
        if moduleThrottle >= 9 then
            -- Only disable at extreme throttling and for non-critical modules
            throttleMethods.disable(module, moduleThrottle)
        end
        
        ::continue::
    end
    
    -- Debug output if throttling changed significantly
    if throttleLevel >= 5 and not optimizationsMade.throttlingReported then
        API.PrintDebug("Performance throttling active (level " .. math.floor(throttleLevel) .. "/10)")
        optimizationsMade.throttlingReported = true
    elseif throttleLevel < 3 and optimizationsMade.throttlingReported then
        API.PrintDebug("Performance throttling reduced")
        optimizationsMade.throttlingReported = false
    end
}

-- Remove throttling
function PerformanceManager:RemoveThrottling()
    -- Reset all modules to default state
    for module, _ in pairs(defaultUpdateFrequencies) do
        -- Skip modules that don't exist
        if not WR[module] then
            goto continue
        end
        
        -- Reset update frequency
        moduleUpdateFrequencies[module] = defaultUpdateFrequencies[module]
        
        -- Clear throttle flags
        if throttledModules[module] then
            throttledModules[module].skipNonEssential = false
            throttledModules[module].detailLevel = 10
            
            -- Re-enable if disabled
            if throttledModules[module].disabled then
                throttledModules[module].disabled = false
                
                -- Re-enable the module
                if WR[module] and WR[module].SetEnabled then
                    WR[module]:SetEnabled(true)
                end
            end
        end
        
        ::continue::
    end
    
    -- Clear throttling marker
    if optimizationsMade.throttlingReported then
        API.PrintDebug("Performance throttling disabled")
        optimizationsMade.throttlingReported = false
    end
}

-- Check memory usage
function PerformanceManager:CheckMemoryUsage()
    local settings = ConfigRegistry:GetSettings("PerformanceManager")
    
    -- Skip if memory management is disabled
    if not settings.advancedSettings.memoryManagement then
        return
    end
    
    -- Get current memory usage
    local currentMemory = collectgarbage("count") / 1024 -- Convert KB to MB
    
    -- Calculate memory growth
    if memoryUsage > 0 then
        memoryGrowth = currentMemory - memoryUsage
    end
    
    -- Update current usage
    memoryUsage = currentMemory
    
    -- Check if memory usage is too high
    if memoryUsage > MEMORY_WARNING_THRESHOLD then
        -- Queue memory optimizations
        self:QueueOptimization("memory", function()
            self:OptimizeMemory()
        end)
    end
    
    -- Track per-module memory usage
    self:TrackModuleMemoryUsage()
}

-- Run garbage collection
function PerformanceManager:RunGarbageCollection()
    local settings = ConfigRegistry:GetSettings("PerformanceManager")
    
    -- Skip if aggressive GC is disabled
    if not settings.advancedSettings.agressiveGC then
        return
    end
    
    -- Only run GC if we're not in combat or memory pressure is high
    if not inCombat or memoryUsage > MEMORY_WARNING_THRESHOLD then
        API.PrintDebug("Running garbage collection")
        collectgarbage("collect")
    end
}

-- Optimize memory
function PerformanceManager:OptimizeMemory()
    -- This method applies memory optimizations
    
    -- Clear caches
    self:ClearCaches()
    
    -- Run garbage collection
    collectgarbage("collect")
    
    -- Debug output
    local newMemory = collectgarbage("count") / 1024
    API.PrintDebug(string.format("Memory optimized: %.2f MB -> %.2f MB (saved %.2f MB)", 
                  memoryUsage, newMemory, memoryUsage - newMemory))
    
    -- Update memory usage
    memoryUsage = newMemory
}

-- Clear caches
function PerformanceManager:ClearCaches()
    -- Clear various module caches
    
    -- Clear API cache if available
    if WR.API and WR.API.ClearCache then
        WR.API:ClearCache()
    end
    
    -- Clear rotation cache if available
    if WR.RotationManager and WR.RotationManager.ClearCache then
        WR.RotationManager:ClearCache()
    end
    
    -- Clear combat analysis cache if available
    if WR.CombatAnalysis and WR.CombatAnalysis.ClearCache then
        WR.CombatAnalysis:ClearCache()
    end
    
    -- Clear UI cache if available
    if WR.EnhancedConfigUI and WR.EnhancedConfigUI.ClearCache then
        WR.EnhancedConfigUI:ClearCache()
    end
    
    -- Clear other module caches
    for module, _ in pairs(WR) do
        if type(WR[module]) == "table" and WR[module].ClearCache then
            if module ~= "API" and module ~= "RotationManager" and module ~= "CombatAnalysis" and module ~= "EnhancedConfigUI" then
                WR[module]:ClearCache()
            end
        end
    end
}

-- Profile frame execution
function PerformanceManager:ProfileFrameExecution()
    -- Measure execution time of various frames
    
    -- Set up profiling if not already done
    if not frameProfileData.startTime then
        frameProfileData.startTime = GetTime()
        frameProfileData.samples = 0
        frameProfileData.modules = {}
        return
    end
    
    -- Increment sample count
    frameProfileData.samples = frameProfileData.samples + 1
    
    -- Profile modules with OnUpdate handlers
    for module, _ in pairs(WR) do
        if type(WR[module]) == "table" and WR[module].OnUpdate then
            -- Use protected call to measure execution time
            local startTime = debugprofilestop()
            pcall(WR[module].OnUpdate, WR[module], updateFrequency)
            local endTime = debugprofilestop()
            
            -- Record execution time
            if not frameProfileData.modules[module] then
                frameProfileData.modules[module] = {
                    totalTime = 0,
                    samples = 0,
                    avgTime = 0,
                    maxTime = 0
                }
            end
            
            local execTime = endTime - startTime
            frameProfileData.modules[module].totalTime = frameProfileData.modules[module].totalTime + execTime
            frameProfileData.modules[module].samples = frameProfileData.modules[module].samples + 1
            frameProfileData.modules[module].avgTime = frameProfileData.modules[module].totalTime / frameProfileData.modules[module].samples
            
            if execTime > frameProfileData.modules[module].maxTime then
                frameProfileData.modules[module].maxTime = execTime
            end
        end
    end
    
    -- Reset if we have enough samples
    if frameProfileData.samples >= FRAME_PROFILE_SAMPLES then
        -- Update resource usage based on profiling
        for module, data in pairs(frameProfileData.modules) do
            resourceUsage.time.perModule[module] = data.avgTime
        end
        
        -- Reset profiling
        frameProfileData.startTime = GetTime()
        frameProfileData.samples = 0
    end
}

-- Track module memory usage
function PerformanceManager:TrackModuleMemoryUsage()
    -- This would ideally use debug tools to track per-module memory
    -- For the implementation, we'll estimate based on module complexity
    
    -- Estimate memory for known modules
    resourceUsage.memory.perModule = {
        RotationManager = 1.5,      -- Complex state tracking
        CombatAnalysis = 3.0,       -- Lots of history data
        InterruptManager = 0.5,     -- Simpler state tracking
        AutoTargeting = 0.8,        -- Moderate state tracking
        API = 1.0,                  -- API caching
        EnhancedConfigUI = 2.0,     -- UI elements use more memory
        MachineLearning = 4.0,      -- ML models are memory intensive
        GroupRoleManager = 0.3,     -- Simple state tracking
        TrinketManager = 0.5,       -- Simple item tracking
        KeybindManager = 0.4,       -- Keybind state tracking
        CCChainAssist = 0.7,        -- CC tracking state
        PerformanceManager = 0.5,   -- Performance history
        ErrorHandler = 0.5,         -- Error history
        AntiDetectionSystem = 0.6   -- Action history
    }
    
    -- Update total memory usage estimate
    local totalEstimated = 0
    for _, usage in pairs(resourceUsage.memory.perModule) do
        totalEstimated = totalEstimated + usage
    end
    
    resourceUsage.memory.total = totalEstimated
}

-- Get module load distribution
function PerformanceManager:GetModuleLoadDistribution()
    -- Return normalized distribution of load across modules
    local distribution = {}
    local totalLoad = 0
    
    -- Combine time and memory metrics
    for module, timeUsage in pairs(resourceUsage.time.perModule) do
        local memUsage = resourceUsage.memory.perModule[module] or 0
        local combinedLoad = (timeUsage * 0.7) + (memUsage * 0.3) -- Weight time higher than memory
        
        distribution[module] = combinedLoad
        totalLoad = totalLoad + combinedLoad
    end
    
    -- Normalize to percentages
    if totalLoad > 0 then
        for module, load in pairs(distribution) do
            distribution[module] = (load / totalLoad) * 100
        end
    end
    
    return distribution
end

-- Estimate CPU usage
function PerformanceManager:EstimateCPUUsage()
    -- We can't directly measure CPU, but we can estimate from frame times
    local totalExecTime = 0
    
    for module, data in pairs(resourceUsage.time.perModule) do
        totalExecTime = totalExecTime + data
    end
    
    return totalExecTime
}

-- Queue optimization
function PerformanceManager:QueueOptimization(type, func)
    -- Add to queue
    table.insert(optimizationQueue, {
        type = type,
        func = func,
        priority = type == "memory" and 1 or 2 -- Memory optimizations are lower priority
    })
    
    -- Sort by priority (higher numbers = higher priority)
    table.sort(optimizationQueue, function(a, b)
        return a.priority > b.priority
    end)
}

-- Process optimization queue
function PerformanceManager:ProcessOptimizationQueue()
    -- Only process one optimization per update to avoid stuttering
    if #optimizationQueue > 0 then
        local optimization = table.remove(optimizationQueue, 1)
        
        -- Execute the optimization
        optimization.func()
    end
}

-- On enter combat
function PerformanceManager:OnEnterCombat()
    -- Update combat state
    inCombat = true
    
    -- Reset combat intensity
    combatIntensity = 0
    
    -- Adjust update frequency in combat
    updateFrequency = 0.1
    
    -- Reset throttling to account for combat
    throttleLevel = math.max(0, throttleLevel - COMBAT_PRIORITY_BOOST)
    
    API.PrintDebug("Performance Manager: Entering combat mode")
}

-- On leave combat
function PerformanceManager:OnLeaveCombat()
    -- Update combat state
    inCombat = false
    
    -- Reset combat intensity
    combatIntensity = 0
    
    -- Adjust update frequency out of combat
    updateFrequency = 0.2
    
    API.PrintDebug("Performance Manager: Leaving combat mode")
}

-- On health changed
function PerformanceManager:OnHealthChanged()
    -- Update player health percentage
    local maxHealth = UnitHealthMax("player")
    if maxHealth > 0 then
        playerHealth = UnitHealth("player") / maxHealth * 100
    else
        playerHealth = 100
    end
    
    -- Adjust throttling immediately if health is low
    local settings = ConfigRegistry:GetSettings("PerformanceManager")
    if settings.moduleSettings.lowHealthMode and playerHealth < settings.moduleSettings.lowHealthThreshold then
        throttleLevel = math.max(0, throttleLevel - 3)
    end
}

-- Collect performance baseline
function PerformanceManager:CollectPerformanceBaseline()
    -- Collect baseline performance metrics
    baselinePerformance = {
        fps = GetFramerate() or 60,
        memoryUsage = collectgarbage("count") / 1024, -- Convert KB to MB
        timestamp = GetTime(),
        moduleCount = self:CountActiveModules()
    }
    
    API.PrintDebug(string.format("Performance baseline: %.1f FPS, %.2f MB memory", 
                  baselinePerformance.fps, baselinePerformance.memoryUsage))
}

-- Reset performance baseline
function PerformanceManager:ResetPerformanceBaseline()
    -- Wait a moment for things to stabilize
    C_Timer.After(5, function()
        self:CollectPerformanceBaseline()
    end)
}

-- Count active modules
function PerformanceManager:CountActiveModules()
    local count = 0
    
    for module, _ in pairs(WR) do
        if type(WR[module]) == "table" and (not WR[module].IsEnabled or WR[module]:IsEnabled()) then
            count = count + 1
        end
    end
    
    return count
}

-- Is module critical
function PerformanceManager:IsModuleCritical(moduleName)
    -- Define critical modules that should never be heavily throttled
    local criticalModules = {
        "RotationManager",     -- Core rotation logic
        "API",                 -- Core API functions
        "InterruptManager",    -- Interrupt handling is important
        "ErrorHandler",        -- Error handling is important
        "PerformanceManager"   -- Don't throttle ourselves
    }
    
    return tContains(criticalModules, moduleName)
end

-- Is module low priority
function PerformanceManager:IsModuleLowPriority(moduleName)
    -- Define low priority modules that can be heavily throttled
    local lowPriorityModules = {
        "EnhancedConfigUI",    -- UI updates can be slow
        "MachineLearning",     -- ML calculations can be delayed
        "GroupRoleManager",    -- Role updates are infrequent
        "CombatAnalysis",      -- Analysis can be delayed
        "DynamicLearning"      -- Learning can be delayed
    }
    
    return tContains(lowPriorityModules, moduleName)
end

-- Get update frequency for module
function PerformanceManager:GetUpdateFrequency(moduleName)
    return moduleUpdateFrequencies[moduleName] or defaultUpdateFrequencies[moduleName] or 0.1
end

-- Should skip non-essential processing
function PerformanceManager:ShouldSkipNonEssential(moduleName)
    return throttledModules[moduleName] and throttledModules[moduleName].skipNonEssential or false
end

-- Get detail level for module
function PerformanceManager:GetDetailLevel(moduleName)
    return throttledModules[moduleName] and throttledModules[moduleName].detailLevel or 10
end

-- Is module disabled by throttling
function PerformanceManager:IsModuleThrottleDisabled(moduleName)
    return throttledModules[moduleName] and throttledModules[moduleName].disabled or false
end

-- Is in high stress mode
function PerformanceManager:IsInHighStressMode()
    return isHighStressMode or throttleLevel >= 7
end

-- Toggle enabled state
function PerformanceManager:Toggle()
    isEnabled = not isEnabled
    
    if isEnabled then
        -- Reset baseline
        self:CollectPerformanceBaseline()
    else
        -- Remove any throttling
        self:RemoveThrottling()
    end
    
    return isEnabled
}

-- Is enabled
function PerformanceManager:IsEnabled()
    return isEnabled
end

-- Get current performance
function PerformanceManager:GetCurrentPerformance()
    return currentPerformance
end

-- Get baseline performance
function PerformanceManager:GetBaselinePerformance()
    return baselinePerformance
end

-- Get throttle level
function PerformanceManager:GetThrottleLevel()
    return throttleLevel
end

-- Get resource usage
function PerformanceManager:GetResourceUsage()
    return resourceUsage
end

-- Get module throttle status
function PerformanceManager:GetModuleThrottleStatus(moduleName)
    return throttledModules[moduleName] or {
        skipNonEssential = false,
        detailLevel = 10,
        disabled = false
    }
end

-- Get memory usage
function PerformanceManager:GetMemoryUsage()
    return memoryUsage
end

-- Get FPS
function PerformanceManager:GetFPS()
    return currentFPS
end

-- Force optimization
function PerformanceManager:ForceOptimization()
    self:OptimizeMemory()
    return true
end

-- Return the module
return PerformanceManager