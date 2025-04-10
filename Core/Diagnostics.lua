local addonName, WR = ...

-- Diagnostics module for troubleshooting and self-repair
local Diagnostics = {}
WR.Diagnostics = Diagnostics

-- Constants
local MAX_ERROR_HISTORY = 50
local MAX_DIAGNOSTIC_LEVEL = 3
local TELEMETRY_INTERVAL = 300  -- 5 minutes between telemetry updates

-- Storage for diagnostic data
local diagnosticData = {
    errors = {},
    warnings = {},
    performance = {},
    environment = {},
    rotationHistory = {},
    lastChecks = {},
    systemInfo = {}
}

-- System health indicators
local systemHealth = {
    overall = 100,           -- Overall health score (0-100)
    components = {
        core = 100,          -- Core API health
        rotation = 100,      -- Rotation system health
        ui = 100,            -- UI system health
        profiles = 100,      -- Profile system health
        memory = 100,        -- Memory usage health
        performance = 100    -- Performance health
    }
}

-- Configuration
local config = {
    enabled = true,
    detectionLevel = 2,          -- 1-3, higher means more aggressive detection
    autoRepair = true,           -- Attempt to automatically fix issues
    collectTelemetry = true,     -- Collect anonymous usage data
    showWarnings = true,         -- Show warnings to the user
    debugMode = false,           -- Enable additional debugging output
    errorThreshold = 3,          -- Number of errors before taking action
    performanceLogging = true    -- Log performance data
}

-- Initialize the diagnostics module
function Diagnostics:Initialize()
    -- Create event frame
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("ADDON_LOADED")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("PLAYER_LEAVING_WORLD")
    
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "ADDON_LOADED" and ... == addonName then
            -- Addon initialization complete, collect system info
            C_Timer.After(2, function() Diagnostics:CollectSystemInfo() end)
        elseif event == "PLAYER_ENTERING_WORLD" then
            -- Perform initial diagnostics
            C_Timer.After(5, function() Diagnostics:RunDiagnostics() end)
            
            -- Set up periodic checks
            C_Timer.NewTicker(60, function() Diagnostics:PeriodicCheck() end)
            
            -- Set up telemetry if enabled
            if config.collectTelemetry then
                C_Timer.NewTicker(TELEMETRY_INTERVAL, function() Diagnostics:CollectTelemetry() end)
            end
        end
    end)
    
    -- Hook error handler
    self:HookErrorHandler()
    
    WR:Debug("Diagnostics module initialized")
end

-- Collect system information
function Diagnostics:CollectSystemInfo()
    local systemInfo = diagnosticData.systemInfo
    
    -- WoW client info
    systemInfo.version = GetBuildInfo()
    systemInfo.locale = GetLocale()
    systemInfo.realm = GetRealmName()
    
    -- Addon info
    systemInfo.addonVersion = WR.version
    systemInfo.addonBuild = WR.buildNumber or 0
    
    -- Character info
    local _, class = UnitClass("player")
    local spec = GetSpecialization()
    local specID = spec and GetSpecializationInfo(spec) or 0
    
    systemInfo.class = class
    systemInfo.spec = specID
    systemInfo.level = UnitLevel("player")
    
    -- System info
    systemInfo.memory = collectgarbage("count")
    systemInfo.framerate = GetFramerate()
    systemInfo.latency = select(4, GetNetStats())
    
    -- Addon dependencies
    systemInfo.dependencies = {}
    
    -- Check for critical dependencies
    if IsAddOnLoaded("Tinkr") then
        systemInfo.dependencies.Tinkr = { loaded = true, version = self:GetAddOnVersion("Tinkr") }
    else
        systemInfo.dependencies.Tinkr = { loaded = false }
    end
    
    -- Record initialization time
    systemInfo.initTime = GetTime()
    
    WR:Debug("System information collected")
end

-- Run full diagnostics
function Diagnostics:RunDiagnostics(level)
    if not config.enabled then return end
    
    level = level or config.detectionLevel
    
    -- Only run if we haven't recently run a full diagnostic
    local currentTime = GetTime()
    if diagnosticData.lastChecks.fullDiagnostic and 
       currentTime - diagnosticData.lastChecks.fullDiagnostic < 300 then -- 5 minutes
        return
    end
    
    WR:Debug("Running diagnostics at level", level)
    
    -- Record diagnostic time
    diagnosticData.lastChecks.fullDiagnostic = currentTime
    
    -- System diagnostics
    self:CheckSystemHealth(level)
    
    -- Core API diagnostics
    self:CheckCoreAPI(level)
    
    -- Profile system diagnostics
    self:CheckProfileSystem(level)
    
    -- UI diagnostics
    self:CheckUI(level)
    
    -- Rotation system diagnostics
    self:CheckRotationSystem(level)
    
    -- Performance diagnostics
    self:CheckPerformance(level)
    
    -- Report results
    self:UpdateSystemHealth()
    
    -- Alert user if needed
    if systemHealth.overall < 70 then
        self:AlertUser("System health is below optimal levels. Run '/wr diagnose' for more information.")
    end
    
    -- Attempt auto-repair if enabled
    if config.autoRepair and systemHealth.overall < 50 then
        self:AttemptRepair()
    end
    
    WR:Debug("Diagnostics complete, system health:", systemHealth.overall)
end

-- Perform a quick check
function Diagnostics:QuickCheck()
    if not config.enabled then return true end
    
    -- Check critical systems only
    local critical = self:CheckCriticalSystems()
    
    -- Update overall health
    self:UpdateSystemHealth()
    
    return critical
end

-- Periodic check
function Diagnostics:PeriodicCheck()
    if not config.enabled then return end
    
    -- Only perform a quick check most of the time
    local currentTime = GetTime()
    local lastCheck = diagnosticData.lastChecks.periodicCheck or 0
    
    diagnosticData.lastChecks.periodicCheck = currentTime
    
    -- Quick check every time
    local critical = self:QuickCheck()
    
    -- Full diagnostic less frequently
    if currentTime - lastCheck > 1800 then  -- 30 minutes
        self:RunDiagnostics(1)  -- Level 1 (light) diagnostics
    end
    
    -- Check for memory issues
    self:CheckMemoryUsage()
    
    -- If critical systems failed, alert the user
    if not critical then
        self:AlertUser("Critical system check failed. Your addon may not function correctly.")
    end
end

-- Check critical systems
function Diagnostics:CheckCriticalSystems()
    local criticalFunctions = {
        "API",
        "Config",
        "ClassBase"
    }
    
    local allPassed = true
    
    -- Check that critical components exist
    for _, funcName in ipairs(criticalFunctions) do
        if not WR[funcName] then
            self:LogError("Critical component missing: " .. funcName)
            allPassed = false
        end
    end
    
    -- Check that we can detect player class and spec
    local _, class = UnitClass("player")
    local spec = GetSpecialization()
    
    if not class or not spec then
        self:LogError("Failed to detect player class or specialization")
        allPassed = false
    end
    
    -- Check for active class module
    if class and not WR.ActiveClassModule then
        self:LogWarning("No active class module detected for " .. class)
    end
    
    return allPassed
end

-- Check system health
function Diagnostics:CheckSystemHealth(level)
    level = level or 1
    
    -- Basic checks performed at all levels
    local addonMemory = collectgarbage("count")
    local framerate = GetFramerate()
    local latency = select(4, GetNetStats())
    
    diagnosticData.environment.memory = addonMemory
    diagnosticData.environment.framerate = framerate
    diagnosticData.environment.latency = latency
    
    -- Check for performance issues
    if framerate < 20 then
        self:LogWarning("Low framerate detected: " .. framerate .. " FPS")
        systemHealth.performance = math.min(systemHealth.performance, 60)
    end
    
    if latency > 300 then
        self:LogWarning("High latency detected: " .. latency .. " ms")
    end
    
    -- More detailed checks at higher levels
    if level >= 2 then
        -- Check addon dependencies
        if not IsAddOnLoaded("Tinkr") then
            self:LogError("Required dependency 'Tinkr' not loaded")
            systemHealth.core = math.min(systemHealth.core, 50)
        end
        
        -- Check for missing files or corrupted data
        self:CheckFileIntegrity()
        
        -- Check for addon conflicts
        self:CheckAddonConflicts()
    end
    
    -- Most detailed checks at highest level
    if level >= 3 then
        -- Advanced system checks
        self:CheckAuraSystem()
        self:CheckTargetingSystem()
    end
end

-- Check core API
function Diagnostics:CheckCoreAPI(level)
    level = level or 1
    
    -- Basic checks
    if not WR.API then
        self:LogError("Core API module missing")
        systemHealth.core = 0
        return
    end
    
    -- Check essential API functions
    local essentialFunctions = {
        "Cast",
        "CanCast",
        "GetCooldown",
        "UnitAura",
        "UnitHP"
    }
    
    for _, funcName in ipairs(essentialFunctions) do
        if not WR.API[funcName] then
            self:LogError("Essential API function missing: " .. funcName)
            systemHealth.core = math.min(systemHealth.core, 70)
        end
    end
    
    -- More detailed checks at higher levels
    if level >= 2 then
        -- Test API functionality
        if WR.API.UnitHP then
            local playerHealth = WR.API.UnitHP("player")
            if not playerHealth or playerHealth <= 0 or playerHealth > 100 then
                self:LogWarning("API.UnitHP returning unexpected value: " .. tostring(playerHealth))
                systemHealth.core = math.min(systemHealth.core, 80)
            end
        end
        
        -- Check for deprecated API usage
        self:CheckDeprecatedAPIUsage()
    end
    
    -- Most detailed checks at highest level
    if level >= 3 then
        -- Test API performance
        self:BenchmarkAPI()
    end
end

-- Check profile system
function Diagnostics:CheckProfileSystem(level)
    level = level or 1
    
    -- Basic checks
    if not WR.ProfileManager then
        self:LogWarning("Profile Manager module missing")
        systemHealth.profiles = 0
        return
    end
    
    -- Check for essential functions
    local essentialFunctions = {
        "GetCurrentProfile",
        "SaveProfile",
        "LoadProfile"
    }
    
    for _, funcName in ipairs(essentialFunctions) do
        if not WR.ProfileManager[funcName] then
            self:LogError("Essential Profile function missing: " .. funcName)
            systemHealth.profiles = math.min(systemHealth.profiles, 70)
        end
    end
    
    -- Check if current profile exists
    if WR.ProfileManager.GetCurrentProfile and 
       not WR.ProfileManager:GetCurrentProfile() then
        self:LogWarning("No active profile detected")
        systemHealth.profiles = math.min(systemHealth.profiles, 90)
    end
    
    -- More detailed checks at higher levels
    if level >= 2 then
        -- Check profile data integrity
        if WR.ProfileManager.Profiles then
            for name, profile in pairs(WR.ProfileManager.Profiles) do
                if not profile or type(profile) ~= "table" then
                    self:LogWarning("Invalid profile data found: " .. name)
                    systemHealth.profiles = math.min(systemHealth.profiles, 80)
                end
            end
        end
    end
end

-- Check UI system
function Diagnostics:CheckUI(level)
    level = level or 1
    
    -- Basic checks
    local uiModules = {
        "Enhanced",
        "ClassHUD",
        "SettingsUI"
    }
    
    for _, moduleName in ipairs(uiModules) do
        if not WR.UI or not WR.UI[moduleName] then
            self:LogWarning("UI module missing: " .. moduleName)
            systemHealth.ui = math.min(systemHealth.ui, 80)
        end
    end
    
    -- Check if main frame exists and is properly configured
    if WR.UI and WR.UI.Enhanced and WR.UI.Enhanced.mainContainer then
        local mainContainer = WR.UI.Enhanced.mainContainer
        if not mainContainer:GetWidth() or not mainContainer:GetHeight() then
            self:LogWarning("UI container has invalid dimensions")
            systemHealth.ui = math.min(systemHealth.ui, 70)
        end
    else
        self:LogWarning("Main UI container not found")
        systemHealth.ui = math.min(systemHealth.ui, 60)
    end
    
    -- More detailed checks at higher levels
    if level >= 2 then
        -- Check class-specific UI elements
        if WR.UI and WR.UI.ClassHUD then
            local _, class = UnitClass("player")
            
            -- Check if class resources are set up
            if WR.UI.ClassHUD.resourceBars then
                local primaryResource = WR.UI.ClassHUD.resourceBars.primary
                if not primaryResource or not primaryResource.frame then
                    self:LogWarning("Class HUD resource bars not properly configured")
                    systemHealth.ui = math.min(systemHealth.ui, 75)
                end
            end
        end
    end
    
    -- Most detailed checks at highest level
    if level >= 3 then
        -- Check all UI frames for proper scaling and positioning
        self:CheckUIFrames()
    end
end

-- Check rotation system
function Diagnostics:CheckRotationSystem(level)
    level = level or 1
    
    -- Basic checks
    local _, class = UnitClass("player")
    local spec = GetSpecialization()
    
    if not class or not spec then
        self:LogError("Cannot detect player class or specialization")
        systemHealth.rotation = 0
        return
    end
    
    -- Check for class module
    if not WR.ActiveClassModule then
        self:LogError("No active class module detected for " .. class)
        systemHealth.rotation = 0
        return
    end
    
    -- Check for rotation function
    if not WR.ActiveClassModule.RunRotation then
        self:LogError("RunRotation function missing from class module")
        systemHealth.rotation = math.min(systemHealth.rotation, 50)
    end
    
    -- Check rotation history
    local rotationHistory = diagnosticData.rotationHistory
    if #rotationHistory > 0 then
        local errorCount = 0
        
        for _, entry in ipairs(rotationHistory) do
            if entry.error then
                errorCount = errorCount + 1
            end
        end
        
        if errorCount > 0 then
            local errorRate = errorCount / #rotationHistory
            self:LogWarning("Rotation errors detected: " .. errorCount .. " (" .. math.floor(errorRate * 100) .. "%)")
            
            -- Adjust health based on error rate
            if errorRate > 0.5 then
                systemHealth.rotation = math.min(systemHealth.rotation, 30)
            elseif errorRate > 0.2 then
                systemHealth.rotation = math.min(systemHealth.rotation, 60)
            else
                systemHealth.rotation = math.min(systemHealth.rotation, 80)
            end
        end
    end
    
    -- More detailed checks at higher levels
    if level >= 2 then
        -- Check for class-specific issues
        self:CheckClassSpecificIssues(class, spec)
    end
    
    -- Most detailed checks at highest level
    if level >= 3 then
        -- Check rotation logic
        self:AnalyzeRotationLogic()
    end
end

-- Check performance
function Diagnostics:CheckPerformance(level)
    level = level or 1
    
    -- Basic checks
    if WR.Optimization then
        local stats = WR.Optimization:GetPerformanceStats()
        
        -- Check rotation execution time
        if stats.rotationTime and #stats.rotationTime > 0 then
            local total = 0
            local maxTime = 0
            
            for _, entry in ipairs(stats.rotationTime) do
                total = total + entry.time
                maxTime = math.max(maxTime, entry.time)
            end
            
            local avgTime = total / #stats.rotationTime
            
            diagnosticData.performance.rotationAvgTime = avgTime
            diagnosticData.performance.rotationMaxTime = maxTime
            
            if avgTime > 10 then
                self:LogWarning("Rotation execution time is high: " .. string.format("%.2f", avgTime) .. "ms average")
                systemHealth.performance = math.min(systemHealth.performance, 70)
            end
            
            if maxTime > 50 then
                self:LogWarning("Rotation max execution time is very high: " .. string.format("%.2f", maxTime) .. "ms")
                systemHealth.performance = math.min(systemHealth.performance, 50)
            end
        end
        
        -- Check memory usage
        if stats.memoryUsage and #stats.memoryUsage > 0 then
            local currentMemory = stats.memoryUsage[#stats.memoryUsage].memory
            diagnosticData.performance.memoryUsage = currentMemory
            
            if currentMemory > 10000 then
                self:LogWarning("Memory usage is high: " .. string.format("%.2f", currentMemory / 1024) .. "MB")
                systemHealth.memory = math.min(systemHealth.memory, 60)
            end
        end
    else
        self:LogWarning("Optimization module not available for performance checks")
        systemHealth.performance = math.min(systemHealth.performance, 80)
    end
    
    -- More detailed checks at higher levels
    if level >= 2 then
        -- Check function call counts and times
        if WR.Optimization and WR.Optimization:GetPerformanceStats().functionCalls then
            local functionCalls = WR.Optimization:GetPerformanceStats().functionCalls
            
            for name, stats in pairs(functionCalls) do
                if stats.calls > 0 then
                    local avgTime = stats.totalTime / stats.calls
                    
                    if avgTime > 5 and stats.calls > 100 then
                        self:LogWarning("Function performance issue detected: " .. name .. 
                                      " called " .. stats.calls .. " times, avg " .. 
                                      string.format("%.2f", avgTime) .. "ms")
                        systemHealth.performance = math.min(systemHealth.performance, 70)
                    end
                    
                    if stats.maxTime > 50 then
                        self:LogWarning("Function max execution time is high: " .. name .. 
                                      " max " .. string.format("%.2f", stats.maxTime) .. "ms")
                    end
                end
            end
        end
    end
    
    -- Most detailed checks at highest level
    if level >= 3 then
        -- Run performance benchmarks
        self:BenchmarkPerformance()
    end
end

-- Check file integrity
function Diagnostics:CheckFileIntegrity()
    -- Check for essential files
    local essentialFiles = {
        "Core\\API.lua",
        "Core\\Config.lua",
        "Classes\\Base.lua"
    }
    
    local classFile = "Classes\\" .. select(2, UnitClass("player")) .. ".lua"
    table.insert(essentialFiles, classFile)
    
    -- This is just a conceptual implementation since we can't directly check file existence
    -- In practice, this would check global objects that should be defined by these files
    
    local missingFiles = {}
    
    if not WR.API then
        table.insert(missingFiles, "Core\\API.lua")
    end
    
    if not WR.Config then
        table.insert(missingFiles, "Core\\Config.lua")
    end
    
    if not WR.ClassBase then
        table.insert(missingFiles, "Classes\\Base.lua")
    end
    
    if not WR.ActiveClassModule then
        table.insert(missingFiles, classFile)
    end
    
    if #missingFiles > 0 then
        for _, file in ipairs(missingFiles) do
            self:LogError("Essential file appears to be missing or corrupted: " .. file)
        end
        
        systemHealth.core = math.min(systemHealth.core, 40)
    end
end

-- Check for addon conflicts
function Diagnostics:CheckAddonConflicts()
    local knownConflicts = {
        "SuperDuper_Rotations",   -- Fictional example
        "RotationMaster",         -- Fictional example
        "AutoButton"              -- Fictional example
    }
    
    local foundConflicts = {}
    
    for _, conflict in ipairs(knownConflicts) do
        if IsAddOnLoaded(conflict) then
            table.insert(foundConflicts, conflict)
        end
    end
    
    if #foundConflicts > 0 then
        for _, conflict in ipairs(foundConflicts) do
            self:LogWarning("Potential addon conflict detected: " .. conflict)
        end
        
        self:AlertUser("Potential addon conflicts detected. Some features may not work correctly.")
    end
end

-- Check aura system
function Diagnostics:CheckAuraSystem()
    if not WR.API or not WR.API.UnitAura then
        self:LogWarning("Aura tracking system not available")
        return
    end
    
    -- Test aura detection on player
    local testPassed = false
    
    -- Get all player buffs
    for i = 1, 40 do
        local name = UnitBuff("player", i)
        if name then
            -- If we can detect any buff, the system is working
            testPassed = true
            break
        end
    end
    
    if not testPassed then
        -- Player might truly have no buffs, so this is just a warning
        self:LogWarning("Aura detection test inconclusive - no player buffs detected")
    end
end

-- Check targeting system
function Diagnostics:CheckTargetingSystem()
    if not WR.API then
        self:LogWarning("API not available for targeting system check")
        return
    end
    
    -- Check if targeting functions exist
    if not WR.API.UnitExists or not WR.API.UnitIsEnemy then
        self:LogWarning("Targeting system functions missing")
        systemHealth.core = math.min(systemHealth.core, 80)
    end
    
    -- Test targeting on player and target
    if WR.API.UnitExists then
        if not WR.API.UnitExists("player") then
            self:LogError("Targeting system failed to detect player")
            systemHealth.core = math.min(systemHealth.core, 60)
        end
        
        if UnitExists("target") and not WR.API.UnitExists("target") then
            self:LogWarning("Targeting system failed to detect current target")
            systemHealth.core = math.min(systemHealth.core, 70)
        end
    end
end

-- Check for deprecated API usage
function Diagnostics:CheckDeprecatedAPIUsage()
    -- List of deprecated functions
    local deprecatedFunctions = {
        "OldFunction1",  -- Fictional example
        "OldFunction2"   -- Fictional example
    }
    
    -- Check if any modules are using deprecated functions
    -- This is conceptual since we can't easily hook into function calls retrospectively
    -- In a real implementation, we'd use logging or hooks set up during initialization
    
    local usedDeprecated = {}
    
    -- In real implementation, this would check against logged function calls
    if #usedDeprecated > 0 then
        for _, func in ipairs(usedDeprecated) do
            self:LogWarning("Deprecated API usage detected: " .. func)
        end
    end
}

-- Check class-specific issues
function Diagnostics:CheckClassSpecificIssues(class, spec)
    if not class then return end
    
    class = class:upper()
    
    -- Check for class-specific issues
    local classIssues = {
        WARRIOR = function()
            -- Check warrior-specific functionality
            if spec == 1 then  -- Arms
                -- Arms-specific checks
            elseif spec == 2 then  -- Fury
                -- Fury-specific checks
            elseif spec == 3 then  -- Protection
                -- Protection-specific checks
            end
        end,
        
        PALADIN = function()
            -- Check paladin-specific functionality
            if spec == 1 then  -- Holy
                -- Holy-specific checks
            elseif spec == 2 then  -- Protection
                -- Protection-specific checks
            elseif spec == 3 then  -- Retribution
                -- Retribution-specific checks
            end
        end,
        
        -- Add other classes as needed
    }
    
    -- Run class-specific checks if available
    if classIssues[class] then
        classIssues[class]()
    end
}

-- Analyze rotation logic
function Diagnostics:AnalyzeRotationLogic()
    -- Check for proper rotation pattern
    if not WR.ActiveClassModule or not WR.ActiveClassModule.RunRotation then
        self:LogWarning("Cannot analyze rotation logic - no active rotation found")
        return
    end
    
    -- This would be a complex analysis in practice
    -- For this demonstration, we'll just check if the rotation has been executed successfully
    
    if #diagnosticData.rotationHistory > 0 then
        local lastRun = diagnosticData.rotationHistory[#diagnosticData.rotationHistory]
        
        if lastRun.error then
            self:LogWarning("Last rotation execution failed: " .. lastRun.error)
            systemHealth.rotation = math.min(systemHealth.rotation, 60)
        end
    end
}

-- Benchmark API performance
function Diagnostics:BenchmarkAPI()
    if not WR.API then
        self:LogWarning("API not available for benchmarking")
        return
    end
    
    -- Test common API functions
    local functions = {
        "UnitHP",
        "GetCooldown",
        "UnitAura",
        "CanCast"
    }
    
    local results = {}
    
    for _, funcName in ipairs(functions) do
        local func = WR.API[funcName]
        
        if func then
            local start = debugprofilestop()
            local iterations = 1000
            
            if funcName == "UnitHP" then
                for i = 1, iterations do
                    func("player")
                end
            elseif funcName == "GetCooldown" then
                for i = 1, iterations do
                    func(1)  -- Just use a dummy spell ID
                end
            elseif funcName == "UnitAura" then
                for i = 1, iterations do
                    func("player", 1)
                end
            elseif funcName == "CanCast" then
                for i = 1, iterations do
                    func(1)  -- Just use a dummy spell ID
                end
            end
            
            local elapsed = debugprofilestop() - start
            local avgTime = elapsed / iterations
            
            results[funcName] = avgTime
            
            if avgTime > 0.1 then
                self:LogWarning("API function " .. funcName .. " is slow: " .. string.format("%.3f", avgTime) .. "ms per call")
                systemHealth.performance = math.min(systemHealth.performance, 80)
            end
        end
    end
    
    diagnosticData.performance.apiBenchmark = results
}

-- Benchmark overall performance
function Diagnostics:BenchmarkPerformance()
    -- Test rotation execution
    if WR.ActiveClassModule and WR.ActiveClassModule.RunRotation then
        local totalTime = 0
        local iterations = 10
        
        for i = 1, iterations do
            local start = debugprofilestop()
            
            -- Execute rotation without actually casting spells
            local success, result = pcall(function()
                return WR.ActiveClassModule:RunRotation(true)  -- Pass true to indicate this is a simulation
            end)
            
            local elapsed = debugprofilestop() - start
            totalTime = totalTime + elapsed
            
            if not success then
                self:LogError("Rotation benchmark failed: " .. tostring(result))
                systemHealth.rotation = math.min(systemHealth.rotation, 50)
                break
            end
        end
        
        local avgTime = totalTime / iterations
        diagnosticData.performance.rotationBenchmark = avgTime
        
        if avgTime > 20 then
            self:LogWarning("Rotation execution is slow: " .. string.format("%.2f", avgTime) .. "ms average")
            systemHealth.performance = math.min(systemHealth.performance, 70)
        end
    end
    
    -- Test UI rendering
    if WR.UI and WR.UI.Enhanced then
        -- Basic UI performance test
        local start = debugprofilestop()
        local iterations = 10
        
        for i = 1, iterations do
            -- Simulate UI update cycle
            if WR.UI.Enhanced.Update then
                WR.UI.Enhanced:Update(0.016)  -- Simulate 60fps
            end
            
            if WR.UI.ClassHUD and WR.UI.ClassHUD.Update then
                WR.UI.ClassHUD:Update(0.016)
            end
        end
        
        local elapsed = debugprofilestop() - start
        local avgTime = elapsed / iterations
        
        diagnosticData.performance.uiBenchmark = avgTime
        
        if avgTime > 10 then
            self:LogWarning("UI rendering is slow: " .. string.format("%.2f", avgTime) .. "ms average")
            systemHealth.performance = math.min(systemHealth.performance, 75)
        end
    end
}

-- Check UI frames
function Diagnostics:CheckUIFrames()
    if not WR.UI then return end
    
    -- Check main UI frames
    local mainFrames = {
        Enhanced = WR.UI.Enhanced and WR.UI.Enhanced.mainContainer,
        ClassHUD = WR.UI.ClassHUD and WR.UI.ClassHUD.mainFrame,
        Settings = WR.UI.SettingsUI and WR.UI.SettingsUI.mainFrame
    }
    
    local screenWidth, screenHeight = GetPhysicalScreenSize()
    
    for name, frame in pairs(mainFrames) do
        if frame then
            -- Check if frame has valid dimensions
            local width, height = frame:GetWidth(), frame:GetHeight()
            if width <= 0 or height <= 0 then
                self:LogWarning(name .. " frame has invalid dimensions")
                systemHealth.ui = math.min(systemHealth.ui, 70)
            end
            
            -- Check if frame is within screen bounds
            local scale = frame:GetScale() or 1
            local effectiveWidth = width * scale
            local effectiveHeight = height * scale
            
            local point, _, _, xOfs, yOfs = frame:GetPoint()
            
            if not point then
                self:LogWarning(name .. " frame has no position set")
            else
                -- Rough check if frame might be off-screen
                if xOfs < -effectiveWidth or xOfs > screenWidth or 
                   yOfs < -effectiveHeight or yOfs > screenHeight then
                    self:LogWarning(name .. " frame may be positioned off-screen")
                    systemHealth.ui = math.min(systemHealth.ui, 85)
                end
            end
        end
    end
}

-- Check memory usage
function Diagnostics:CheckMemoryUsage()
    local memoryUsage = collectgarbage("count")
    local previousMemory = diagnosticData.environment.memory or memoryUsage
    
    -- Record current memory usage
    diagnosticData.environment.memory = memoryUsage
    
    -- Check for memory leaks
    if memoryUsage > previousMemory * 1.5 and memoryUsage > 5000 then
        self:LogWarning("Potential memory leak detected. Memory usage increased from " .. 
                      math.floor(previousMemory / 1024) .. "MB to " .. 
                      math.floor(memoryUsage / 1024) .. "MB")
        
        systemHealth.memory = math.min(systemHealth.memory, 60)
        
        -- Try to recover memory
        if config.autoRepair then
            collectgarbage("collect")
            
            -- Clear caches if available
            if WR.Optimization then
                WR.Optimization:ClearCache("all")
            end
            
            local newMemory = collectgarbage("count")
            self:LogInfo("Memory cleanup performed. Usage reduced from " .. 
                       math.floor(memoryUsage / 1024) .. "MB to " .. 
                       math.floor(newMemory / 1024) .. "MB")
        end
    end
}

-- Update system health
function Diagnostics:UpdateSystemHealth()
    -- Update overall health based on component health
    local total = 0
    local count = 0
    
    for component, health in pairs(systemHealth.components) do
        total = total + health
        count = count + 1
    end
    
    -- Calculate overall health
    systemHealth.overall = math.floor(total / count)
    
    -- Record the health status
    diagnosticData.environment.systemHealth = systemHealth.overall
    
    return systemHealth.overall
}

-- Attempt to repair issues
function Diagnostics:AttemptRepair()
    if not config.autoRepair then return end
    
    local repairCount = 0
    
    -- Try to fix memory issues first
    if systemHealth.memory < 70 then
        collectgarbage("collect")
        
        -- Clear caches if available
        if WR.Optimization then
            WR.Optimization:ClearCache("all")
        end
        
        repairCount = repairCount + 1
    end
    
    -- Try to reset UI if it's problematic
    if systemHealth.ui < 60 then
        -- Reset UI frames to default positions
        if WR.UI then
            if WR.UI.Enhanced and WR.UI.Enhanced.ResetPosition then
                WR.UI.Enhanced:ResetPosition()
                repairCount = repairCount + 1
            end
            
            if WR.UI.ClassHUD and WR.UI.ClassHUD.ResetPosition then
                WR.UI.ClassHUD:ResetPosition()
                repairCount = repairCount + 1
            end
        end
    end
    
    -- Try to fix profile issues
    if systemHealth.profiles < 60 and WR.ProfileManager then
        -- Reset to default profile
        if WR.ProfileManager.LoadDefaultProfile then
            WR.ProfileManager:LoadDefaultProfile()
            repairCount = repairCount + 1
        end
    end
    
    -- Try to reload class module if rotation is broken
    if systemHealth.rotation < 50 then
        -- Reload class module
        local _, class = UnitClass("player")
        
        if class and WR.LoadClassModule then
            WR.LoadClassModule(class)
            repairCount = repairCount + 1
        end
    end
    
    if repairCount > 0 then
        self:LogInfo("Auto-repair attempted " .. repairCount .. " fixes")
        self:RunDiagnostics(1)  -- Run a quick diagnostic after repairs
    end
}

-- Log an error
function Diagnostics:LogError(message)
    if not message then return end
    
    -- Add timestamp
    local entry = {
        timestamp = GetTime(),
        message = message,
        type = "error"
    }
    
    -- Add to error log
    table.insert(diagnosticData.errors, entry)
    
    -- Trim if needed
    if #diagnosticData.errors > MAX_ERROR_HISTORY then
        table.remove(diagnosticData.errors, 1)
    end
    
    -- Print to chat if in debug mode
    if config.debugMode then
        WR:Print("|cFFFF0000Error:|r " .. message)
    end
    
    -- Print to debug log
    WR:Debug("ERROR: " .. message)
}

-- Log a warning
function Diagnostics:LogWarning(message)
    if not message then return end
    
    -- Add timestamp
    local entry = {
        timestamp = GetTime(),
        message = message,
        type = "warning"
    }
    
    -- Add to warning log
    table.insert(diagnosticData.warnings, entry)
    
    -- Trim if needed
    if #diagnosticData.warnings > MAX_ERROR_HISTORY then
        table.remove(diagnosticData.warnings, 1)
    end
    
    -- Print to chat if enabled
    if config.showWarnings and config.debugMode then
        WR:Print("|cFFFFFF00Warning:|r " .. message)
    end
    
    -- Print to debug log
    WR:Debug("WARNING: " .. message)
}

-- Log an info message
function Diagnostics:LogInfo(message)
    if not message then return end
    
    -- Print to debug log
    WR:Debug("INFO: " .. message)
    
    -- Print to chat if in debug mode
    if config.debugMode then
        WR:Print("|cFF00FFFF" .. message .. "|r")
    end
}

-- Alert the user about an issue
function Diagnostics:AlertUser(message)
    if not message then return end
    
    -- Print to chat
    WR:Print("|cFFFF9900WindrunnerRotations:|r " .. message)
    
    -- Maybe show a UI alert if we have UI components
    if WR.UI and WR.UI.Enhanced and WR.UI.Enhanced.ShowAlert then
        WR.UI.Enhanced:ShowAlert(message)
    end
}

-- Record a rotation execution
function Diagnostics:RecordRotationExecution(success, result, executionTime)
    if not config.enabled or not config.performanceLogging then return end
    
    local entry = {
        timestamp = GetTime(),
        success = success,
        result = result,
        executionTime = executionTime,
        error = not success and result or nil
    }
    
    -- Add to rotation history
    table.insert(diagnosticData.rotationHistory, entry)
    
    -- Trim if needed
    if #diagnosticData.rotationHistory > MAX_ERROR_HISTORY then
        table.remove(diagnosticData.rotationHistory, 1)
    end
    
    -- Track consecutive errors
    if not success then
        local errorCount = 0
        
        -- Count recent errors
        for i = #diagnosticData.rotationHistory, 1, -1 do
            local record = diagnosticData.rotationHistory[i]
            if record.error then
                errorCount = errorCount + 1
            else
                break
            end
            
            -- Only check the last few rotations
            if errorCount >= config.errorThreshold or i <= #diagnosticData.rotationHistory - 5 then
                break
            end
        end
        
        -- If we have too many consecutive errors, run diagnostics
        if errorCount >= config.errorThreshold then
            self:LogWarning(errorCount .. " consecutive rotation errors detected")
            systemHealth.rotation = math.min(systemHealth.rotation, 40)
            
            -- Run diagnostics
            self:RunDiagnostics(2)
            
            -- Alert the user
            self:AlertUser("Rotation system is experiencing issues. Type '/wr diagnose' for details.")
        end
    end
}

-- Collect telemetry data
function Diagnostics:CollectTelemetry()
    if not config.collectTelemetry then return end
    
    -- Collect anonymous usage data
    local telemetry = {
        timestamp = GetTime(),
        systemHealth = systemHealth,
        performance = {
            memory = collectgarbage("count"),
            framerate = GetFramerate(),
            latency = select(4, GetNetStats())
        },
        environment = {
            class = select(2, UnitClass("player")),
            spec = GetSpecialization(),
            level = UnitLevel("player"),
            inInstance = IsInInstance(),
            addonVersion = WR.version
        }
    }
    
    -- In a real implementation, this would be sent to a secure server
    -- For this demonstration, we just store it locally
    diagnosticData.telemetry = diagnosticData.telemetry or {}
    table.insert(diagnosticData.telemetry, telemetry)
    
    -- Limit storage
    if #diagnosticData.telemetry > 10 then
        table.remove(diagnosticData.telemetry, 1)
    end
    
    WR:Debug("Telemetry data collected")
}

-- Hook the error handler
function Diagnostics:HookErrorHandler()
    -- Store the original error handler
    local originalHandler = geterrorhandler()
    
    -- Set a custom error handler
    seterrorhandler(function(err)
        -- Record the error
        self:LogError("Lua Error: " .. tostring(err))
        
        -- Update system health
        systemHealth.overall = math.min(systemHealth.overall, 80)
        
        -- Call the original handler
        if originalHandler then
            return originalHandler(err)
        end
    end)
    
    WR:Debug("Error handler hooked")
}

-- Get the addon version
function Diagnostics:GetAddOnVersion(addonName)
    if not addonName or not IsAddOnLoaded(addonName) then return nil end
    
    -- Try to find version in various ways
    local version
    
    -- Method 1: Check for a global version variable
    local globalTable = _G[addonName]
    if globalTable and globalTable.version then
        version = globalTable.version
    end
    
    -- Method 2: Check GetAddOnMetadata
    if not version and GetAddOnMetadata then
        version = GetAddOnMetadata(addonName, "Version")
    end
    
    return version or "Unknown"
}

-- Get diagnostic information for UI display
function Diagnostics:GetDiagnosticInfo()
    return {
        systemHealth = systemHealth,
        errors = diagnosticData.errors,
        warnings = diagnosticData.warnings,
        performance = diagnosticData.performance,
        environment = diagnosticData.environment
    }
}

-- Handle slash command
function Diagnostics:HandleCommand(args)
    if not args or args == "" or args == "help" then
        -- Show help
        WR:Print("Diagnostics Commands:")
        WR:Print("/wr diagnose - Run diagnostics and show results")
        WR:Print("/wr diagnose full - Run detailed diagnostics")
        WR:Print("/wr diagnose repair - Attempt to repair issues")
        WR:Print("/wr diagnose health - Show system health")
        return
    end
    
    if args == "diagnose" then
        -- Run diagnostics
        self:RunDiagnostics(2)
        
        -- Show results
        WR:Print("Diagnostic Results:")
        WR:Print("System Health: " .. systemHealth.overall .. "%")
        WR:Print("- Core System: " .. systemHealth.components.core .. "%")
        WR:Print("- Rotation System: " .. systemHealth.components.rotation .. "%")
        WR:Print("- UI System: " .. systemHealth.components.ui .. "%")
        WR:Print("- Profile System: " .. systemHealth.components.profiles .. "%")
        WR:Print("- Memory Usage: " .. systemHealth.components.memory .. "%")
        WR:Print("- Performance: " .. systemHealth.components.performance .. "%")
        
        -- Show any errors
        if #diagnosticData.errors > 0 then
            WR:Print("Recent Errors:")
            for i = math.max(1, #diagnosticData.errors - 3), #diagnosticData.errors do
                WR:Print("- " .. diagnosticData.errors[i].message)
            end
        end
        
        -- Show any warnings
        if #diagnosticData.warnings > 0 then
            WR:Print("Recent Warnings:")
            for i = math.max(1, #diagnosticData.warnings - 3), #diagnosticData.warnings do
                WR:Print("- " .. diagnosticData.warnings[i].message)
            end
        end
        
        return
    end
    
    if args == "diagnose full" then
        -- Run full diagnostics
        self:RunDiagnostics(3)
        WR:Print("Full diagnostics completed. Use '/wr diagnose' to see results.")
        return
    end
    
    if args == "diagnose repair" then
        -- Attempt repair
        WR:Print("Attempting to repair issues...")
        self:AttemptRepair()
        WR:Print("Repair attempts completed.")
        return
    end
    
    if args == "diagnose health" then
        -- Show health
        WR:Print("System Health: " .. systemHealth.overall .. "%")
        return
    end
    
    if args == "diagnose performance" then
        -- Show performance info
        local memoryUsage = collectgarbage("count")
        WR:Print("Memory Usage: " .. string.format("%.2f", memoryUsage / 1024) .. "MB")
        
        if diagnosticData.performance.rotationAvgTime then
            WR:Print("Rotation Avg Time: " .. string.format("%.2f", diagnosticData.performance.rotationAvgTime) .. "ms")
        end
        
        if diagnosticData.performance.rotationMaxTime then
            WR:Print("Rotation Max Time: " .. string.format("%.2f", diagnosticData.performance.rotationMaxTime) .. "ms")
        end
        
        WR:Print("Framerate: " .. math.floor(GetFramerate()) .. " FPS")
        WR:Print("Latency: " .. select(4, GetNetStats()) .. "ms")
        return
    end
    
    WR:Print("Unknown diagnostics command. Type '/wr diagnose help' for commands.")
end

-- Create a diagnostic UI
function Diagnostics:CreateDiagnosticUI(parent)
    if not parent then return end
    
    -- Create the diagnostic frame
    local frame = CreateFrame("Frame", "WindrunnerRotationsDiagnosticFrame", parent, "BackdropTemplate")
    frame:SetSize(600, 400)
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
    title:SetText("WindrunnerRotations Diagnostics")
    
    -- Create close button
    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    
    -- Create tab buttons
    local tabWidth = 120
    local tabHeight = 24
    local tabs = {}
    local tabContents = {}
    
    local tabNames = {"System Health", "Errors", "Performance", "Repair"}
    
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
                tabButton:SetButtonState("NORMAL")
            end
            
            tab:SetButtonState("PUSHED", true)
        end)
        
        -- Store references
        tabs[i] = tab
        tabContents[i] = content
    end
    
    -- Set up the first tab as active
    tabs[1]:Click()
    
    -- Populate system health tab
    local healthContent = tabContents[1]
    
    local healthStatusText = healthContent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    healthStatusText:SetPoint("TOP", healthContent, "TOP", 0, -10)
    healthStatusText:SetText("System Health: " .. systemHealth.overall .. "%")
    
    -- Create health bars for each component
    local barWidth = 300
    local barHeight = 20
    local barSpacing = 25
    local barStartY = -50
    
    local healthBars = {}
    local healthComponents = {
        {name = "Core System", key = "core"},
        {name = "Rotation System", key = "rotation"},
        {name = "UI System", key = "ui"},
        {name = "Profile System", key = "profiles"},
        {name = "Memory Usage", key = "memory"},
        {name = "Performance", key = "performance"}
    }
    
    for i, component in ipairs(healthComponents) do
        -- Create label
        local label = healthContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("TOPLEFT", healthContent, "TOPLEFT", 20, barStartY - (i-1) * barSpacing)
        label:SetText(component.name .. ":")
        
        -- Create bar background
        local barBg = healthContent:CreateTexture(nil, "BACKGROUND")
        barBg:SetSize(barWidth, barHeight)
        barBg:SetPoint("TOPLEFT", label, "TOPRIGHT", 10, 0)
        barBg:SetColorTexture(0.2, 0.2, 0.2, 0.8)
        
        -- Create bar
        local bar = healthContent:CreateTexture(nil, "ARTWORK")
        bar:SetSize(barWidth * (systemHealth.components[component.key] / 100), barHeight)
        bar:SetPoint("TOPLEFT", barBg, "TOPLEFT", 0, 0)
        
        -- Set color based on health
        local health = systemHealth.components[component.key]
        local r, g, b = 1, 0, 0
        
        if health >= 80 then
            r, g, b = 0, 1, 0
        elseif health >= 60 then
            r, g, b = 1, 1, 0
        elseif health >= 40 then
            r, g, b = 1, 0.5, 0
        end
        
        bar:SetColorTexture(r, g, b, 0.8)
        
        -- Create text
        local valueText = healthContent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        valueText:SetPoint("CENTER", barBg, "CENTER", 0, 0)
        valueText:SetText(health .. "%")
        
        -- Store for updates
        healthBars[component.key] = {
            bar = bar,
            text = valueText
        }
    end
    
    -- Populate errors tab
    local errorsContent = tabContents[2]
    
    local errorScroll = CreateFrame("ScrollFrame", nil, errorsContent, "UIPanelScrollFrameTemplate")
    errorScroll:SetSize(errorsContent:GetWidth() - 30, errorsContent:GetHeight() - 20)
    errorScroll:SetPoint("TOPLEFT", errorsContent, "TOPLEFT", 5, -5)
    
    local errorScrollChild = CreateFrame("Frame", nil, errorScroll)
    errorScrollChild:SetSize(errorScroll:GetWidth(), 1)  -- Height will be set dynamically
    errorScroll:SetScrollChild(errorScrollChild)
    
    -- Function to refresh errors
    local function RefreshErrors()
        -- Clear previous elements
        for i = errorScrollChild:GetNumChildren(), 1, -1 do
            local child = select(i, errorScrollChild:GetChildren())
            child:Hide()
            child:SetParent(nil)
        end
        
        -- Add errors and warnings
        local entries = {}
        
        for _, error in ipairs(diagnosticData.errors) do
            table.insert(entries, {
                type = "Error",
                message = error.message,
                timestamp = error.timestamp,
                color = {r = 1, g = 0, b = 0}
            })
        end
        
        for _, warning in ipairs(diagnosticData.warnings) do
            table.insert(entries, {
                type = "Warning",
                message = warning.message,
                timestamp = warning.timestamp,
                color = {r = 1, g = 0.7, b = 0}
            })
        end
        
        -- Sort by timestamp (newest first)
        table.sort(entries, function(a, b) return a.timestamp > b.timestamp end)
        
        -- Create entry frames
        local entryHeight = 40
        local totalHeight = 10
        
        for i, entry in ipairs(entries) do
            local entryFrame = CreateFrame("Frame", nil, errorScrollChild, "BackdropTemplate")
            entryFrame:SetSize(errorScrollChild:GetWidth() - 20, entryHeight)
            entryFrame:SetPoint("TOPLEFT", errorScrollChild, "TOPLEFT", 10, -totalHeight)
            entryFrame:SetBackdrop({
                bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
                edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
                tile = true,
                tileSize = 16,
                edgeSize = 16,
                insets = { left = 4, right = 4, top = 4, bottom = 4 }
            })
            entryFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
            
            -- Create entry type text
            local typeText = entryFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            typeText:SetPoint("TOPLEFT", entryFrame, "TOPLEFT", 8, -8)
            typeText:SetText(entry.type .. ":")
            typeText:SetTextColor(entry.color.r, entry.color.g, entry.color.b)
            
            -- Create entry message text
            local messageText = entryFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            messageText:SetPoint("TOPLEFT", typeText, "BOTTOMLEFT", 0, -2)
            messageText:SetWidth(entryFrame:GetWidth() - 16)
            messageText:SetJustifyH("LEFT")
            messageText:SetText(entry.message)
            
            -- Adjust height if needed
            local textHeight = messageText:GetStringHeight() + 20
            if textHeight > entryHeight then
                entryFrame:SetHeight(textHeight)
                entryHeight = textHeight
            end
            
            totalHeight = totalHeight + entryHeight + 5
        end
        
        errorScrollChild:SetHeight(math.max(totalHeight, errorScroll:GetHeight()))
    end
    
    -- Populate performance tab
    local performanceContent = tabContents[3]
    
    local performanceText = performanceContent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    performanceText:SetPoint("TOP", performanceContent, "TOP", 0, -10)
    performanceText:SetText("Performance Metrics")
    
    -- Create memory usage graph
    local memoryGraph = CreateFrame("Frame", nil, performanceContent, "BackdropTemplate")
    memoryGraph:SetSize(300, 100)
    memoryGraph:SetPoint("TOPLEFT", performanceContent, "TOPLEFT", 20, -50)
    memoryGraph:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    memoryGraph:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
    
    local memoryTitle = memoryGraph:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    memoryTitle:SetPoint("BOTTOM", memoryGraph, "TOP", 0, 5)
    memoryTitle:SetText("Memory Usage (MB)")
    
    -- Create rotation time graph
    local rotationGraph = CreateFrame("Frame", nil, performanceContent, "BackdropTemplate")
    rotationGraph:SetSize(300, 100)
    rotationGraph:SetPoint("TOPLEFT", memoryGraph, "BOTTOMLEFT", 0, -40)
    rotationGraph:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    rotationGraph:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
    
    local rotationTitle = rotationGraph:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    rotationTitle:SetPoint("BOTTOM", rotationGraph, "TOP", 0, 5)
    rotationTitle:SetText("Rotation Execution Time (ms)")
    
    -- Create current metrics
    local metricsFrame = CreateFrame("Frame", nil, performanceContent, "BackdropTemplate")
    metricsFrame:SetSize(200, 200)
    metricsFrame:SetPoint("TOPLEFT", memoryGraph, "TOPRIGHT", 20, 0)
    metricsFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    metricsFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
    
    local metricsTitle = metricsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    metricsTitle:SetPoint("BOTTOM", metricsFrame, "TOP", 0, 5)
    metricsTitle:SetText("Current Metrics")
    
    local metrics = {
        {name = "Memory Usage", value = function() return string.format("%.2f MB", collectgarbage("count") / 1024) end},
        {name = "Framerate", value = function() return string.format("%.1f FPS", GetFramerate()) end},
        {name = "Latency", value = function() return string.format("%d ms", select(4, GetNetStats())) end},
        {name = "Rotation Avg", value = function() 
            return diagnosticData.performance.rotationAvgTime and 
                   string.format("%.2f ms", diagnosticData.performance.rotationAvgTime) or "N/A" 
        end},
        {name = "Rotation Max", value = function()
            return diagnosticData.performance.rotationMaxTime and 
                   string.format("%.2f ms", diagnosticData.performance.rotationMaxTime) or "N/A"
        end}
    }
    
    local metricLabels = {}
    local metricValues = {}
    
    for i, metric in ipairs(metrics) do
        local label = metricsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("TOPLEFT", metricsFrame, "TOPLEFT", 15, -20 - (i-1) * 25)
        label:SetText(metric.name .. ":")
        
        local value = metricsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        value:SetPoint("TOPRIGHT", metricsFrame, "TOPRIGHT", -15, -20 - (i-1) * 25)
        value:SetText(metric.value())
        
        metricLabels[i] = label
        metricValues[i] = {
            text = value,
            getValue = metric.value
        }
    end
    
    -- Populate repair tab
    local repairContent = tabContents[4]
    
    local repairText = repairContent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    repairText:SetPoint("TOP", repairContent, "TOP", 0, -10)
    repairText:SetText("Repair & Maintenance")
    
    local repairDesc = repairContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    repairDesc:SetPoint("TOP", repairText, "BOTTOM", 0, -10)
    repairDesc:SetWidth(repairContent:GetWidth() - 40)
    repairDesc:SetText("Use these options to troubleshoot and repair issues with WindrunnerRotations.")
    
    -- Create repair buttons
    local buttonWidth = 200
    local buttonHeight = 30
    local buttonSpacing = 10
    local buttonStartY = -60
    
    local repairButtons = {
        {name = "Run Quick Diagnostic", func = function() 
            self:RunDiagnostics(1)
            RefreshDiagnosticUI()
            WR:Print("Quick diagnostic completed")
        end},
        {name = "Run Full Diagnostic", func = function() 
            self:RunDiagnostics(3)
            RefreshDiagnosticUI()
            WR:Print("Full diagnostic completed")
        end},
        {name = "Repair Issues", func = function() 
            self:AttemptRepair()
            RefreshDiagnosticUI()
            WR:Print("Repair attempts completed")
        end},
        {name = "Clear Cache", func = function() 
            if WR.Optimization then
                WR.Optimization:ClearCache("all")
            end
            collectgarbage("collect")
            RefreshDiagnosticUI()
            WR:Print("Caches cleared")
        end},
        {name = "Reset UI Positions", func = function() 
            if WR.UI and WR.UI.Enhanced and WR.UI.Enhanced.ResetPosition then
                WR.UI.Enhanced:ResetPosition()
            end
            
            if WR.UI and WR.UI.ClassHUD and WR.UI.ClassHUD.ResetPosition then
                WR.UI.ClassHUD:ResetPosition()
            end
            
            RefreshDiagnosticUI()
            WR:Print("UI positions reset")
        end},
        {name = "Reset All Settings", func = function() 
            StaticPopupDialogs["WR_RESET_CONFIRM"] = {
                text = "Are you sure you want to reset all WindrunnerRotations settings? This cannot be undone.",
                button1 = "Yes",
                button2 = "No",
                OnAccept = function()
                    if WR.Config and WR.Config.ResetToDefaults then
                        WR.Config:ResetToDefaults()
                    end
                    
                    if WR.ProfileManager and WR.ProfileManager.ResetProfiles then
                        WR.ProfileManager:ResetProfiles()
                    end
                    
                    RefreshDiagnosticUI()
                    WR:Print("All settings have been reset to defaults")
                end,
                timeout = 0,
                whileDead = true,
                hideOnEscape = true,
                preferredIndex = 3
            }
            StaticPopup_Show("WR_RESET_CONFIRM")
        end}
    }
    
    for i, btnInfo in ipairs(repairButtons) do
        local button = CreateFrame("Button", nil, repairContent, "UIPanelButtonTemplate")
        button:SetSize(buttonWidth, buttonHeight)
        button:SetPoint("TOP", repairContent, "TOP", 0, buttonStartY - (i-1) * (buttonHeight + buttonSpacing))
        button:SetText(btnInfo.name)
        button:SetScript("OnClick", btnInfo.func)
    end
    
    -- Function to refresh all data
    function RefreshDiagnosticUI()
        -- Update health status
        healthStatusText:SetText("System Health: " .. systemHealth.overall .. "%")
        
        -- Update health bars
        for key, components in pairs(healthBars) do
            local health = systemHealth.components[key]
            
            -- Update bar size
            components.bar:SetWidth(barWidth * (health / 100))
            
            -- Update text
            components.text:SetText(health .. "%")
            
            -- Update color
            local r, g, b = 1, 0, 0
            
            if health >= 80 then
                r, g, b = 0, 1, 0
            elseif health >= 60 then
                r, g, b = 1, 1, 0
            elseif health >= 40 then
                r, g, b = 1, 0.5, 0
            end
            
            components.bar:SetColorTexture(r, g, b, 0.8)
        end
        
        -- Refresh errors
        RefreshErrors()
        
        -- Update metrics
        for i, metric in ipairs(metricValues) do
            metric.text:SetText(metric.getValue())
        end
        
        -- Draw memory graph
        if diagnosticData.environment.memory then
            -- Implementation would draw the memory graph here
        end
        
        -- Draw rotation time graph
        if diagnosticData.performance.rotationAvgTime then
            -- Implementation would draw the rotation time graph here
        end
    end
    
    -- Set up update timer
    frame:SetScript("OnUpdate", function(self, elapsed)
        self.updateTimer = (self.updateTimer or 0) + elapsed
        
        if self.updateTimer >= 1 then
            self.updateTimer = 0
            
            if frame:IsShown() then
                RefreshDiagnosticUI()
            end
        end
    end)
    
    -- Initial refresh
    RefreshDiagnosticUI()
    
    -- Hide by default
    frame:Hide()
    
    return frame
end

-- Initialize module
Diagnostics:Initialize()

return Diagnostics