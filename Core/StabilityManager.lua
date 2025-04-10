local addonName, WR = ...

-- StabilityManager module for error prevention, recovery, and stability
local StabilityManager = {}
WR.StabilityManager = StabilityManager

-- Constants
local ERROR_HISTORY_LIMIT = 100
local RECOVERY_ATTEMPT_LIMIT = 3
local SAFETY_CHECK_INTERVAL = 1 -- seconds
local WATCHDOG_TIMEOUT = 5 -- seconds
local ADDON_STALLED_THRESHOLD = 10 -- seconds
local MAX_ERROR_RATE = 5 -- errors per minute

-- Error information storage
local errorData = {
    errors = {},
    warningCount = 0,
    criticalCount = 0,
    lastErrorTime = 0,
    errorRate = 0,
    errorRateStartTime = 0,
    errorsSinceRateStart = 0,
    knownIssues = {},
    recoveryAttempts = {},
    moduleStates = {},
    watchdogLastPing = 0,
    safetyChecks = {},
    protectedFunctions = {},
    inRecoveryMode = false,
    recoveryStartTime = 0,
    lastSafetyCheck = 0,
    moduleFailures = {},
    backupStates = {},
    stallDetectionStarted = false,
    stallDetectionLastUpdate = 0,
    functionPerformance = {}
}

-- Configuration
local config = {
    enabled = true,
    autoRecover = true,
    preventRecursiveErrors = true,
    useWatchdog = true,
    monitorFramerate = true,
    errorNotifications = true,
    recoveryNotifications = true,
    logLevel = 2, -- 0-3, higher is more detailed logging
    safetyChecksEnabled = true,
    protectCriticalFunctions = true,
    autoRestartFailedModules = true,
    stallDetection = true,
    backupInterval = 300, -- 5 minutes between state backups
    useSafeModeOnCritical = true,
    isolateProblematicModules = true,
    detailedErrorReporting = true
}

-- Initialize the stability manager
function StabilityManager:Initialize()
    -- Load saved settings
    if WindrunnerRotationsDB and WindrunnerRotationsDB.StabilityManager then
        local savedConfig = WindrunnerRotationsDB.StabilityManager
        for k, v in pairs(savedConfig) do
            if config[k] ~= nil then
                config[k] = v
            end
        end
    end
    
    -- Set up error handler
    self:SetupErrorHandler()
    
    -- Register events
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("PLAYER_LOGOUT")
    eventFrame:RegisterEvent("ADDON_LOADED")
    
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "PLAYER_ENTERING_WORLD" then
            -- Start stability monitoring
            C_Timer.After(5, function()
                StabilityManager:StartMonitoring()
            end)
        elseif event == "PLAYER_LOGOUT" then
            StabilityManager:SaveSettings()
        elseif event == "ADDON_LOADED" and ... == addonName then
            -- Addon loaded, initialize safety checks
            StabilityManager:InitializeSafetyChecks()
        end
    end)
    
    -- Create a frame for update handling
    local updateFrame = CreateFrame("Frame")
    updateFrame:SetScript("OnUpdate", function(self, elapsed)
        if not config.enabled then return end
        
        self.elapsed = (self.elapsed or 0) + elapsed
        
        if self.elapsed >= SAFETY_CHECK_INTERVAL then
            self.elapsed = 0
            StabilityManager:PerformSafetyChecks()
            
            -- Update watchdog
            if config.useWatchdog then
                StabilityManager:PingWatchdog()
            end
            
            -- Check for stalls
            if config.stallDetection then
                StabilityManager:CheckForStalls()
            end
        end
    end)
    
    -- Apply function protection
    if config.protectCriticalFunctions then
        self:ProtectCriticalFunctions()
    end
    
    -- Create backup of initial state
    self:BackupModuleStates()
    
    WR:Debug("StabilityManager initialized")
}

-- Save settings
function StabilityManager:SaveSettings()
    -- Initialize storage if needed
    WindrunnerRotationsDB = WindrunnerRotationsDB or {}
    WindrunnerRotationsDB.StabilityManager = CopyTable(config)
}

-- Set up custom error handler
function StabilityManager:SetupErrorHandler()
    -- Store original error handler
    self.originalErrorHandler = geterrorhandler()
    
    -- Create our custom handler
    local function customErrorHandler(msg, frame, stack, etype, ...)
        -- Check if we're in a recursive error
        if errorData.inRecoveryMode then
            -- If already in recovery mode for too long, use original handler
            if GetTime() - errorData.recoveryStartTime > 5 then
                errorData.inRecoveryMode = false
                return self.originalErrorHandler(msg, frame, stack, etype, ...)
            end
            
            -- Try to avoid infinite loops of errors
            return
        end
        
        -- Set recovery mode
        errorData.inRecoveryMode = true
        errorData.recoveryStartTime = GetTime()
        
        -- Record error
        self:RecordError(msg, stack, etype or "error")
        
        -- Try to recover
        if config.autoRecover then
            local recovered = self:AttemptRecovery(msg, stack)
            if recovered then
                -- Successfully recovered, continue
                errorData.inRecoveryMode = false
                return
            end
        end
        
        -- Attempt failed or recovery disabled, use original handler
        errorData.inRecoveryMode = false
        return self.originalErrorHandler(msg, frame, stack, etype, ...)
    end
    
    -- Set our custom handler
    seterrorhandler(customErrorHandler)
}

-- Record an error
function StabilityManager:RecordError(message, stack, errorType)
    -- Create error entry
    local errorEntry = {
        message = message,
        stack = stack,
        type = errorType or "error",
        time = GetTime(),
        count = 1,
        module = self:GetModuleFromStack(stack),
        function = self:GetFunctionFromStack(stack),
        recovered = false
    }
    
    -- Check for duplicate error
    local isDuplicate = false
    for i, existingError in ipairs(errorData.errors) do
        if existingError.message == message then
            -- Update existing error
            existingError.count = existingError.count + 1
            existingError.time = GetTime()
            isDuplicate = true
            break
        end
    end
    
    -- Add new error if not a duplicate
    if not isDuplicate then
        -- Limit error history size
        if #errorData.errors >= ERROR_HISTORY_LIMIT then
            table.remove(errorData.errors, 1)
        end
        
        table.insert(errorData.errors, errorEntry)
    end
    
    -- Update error counters
    if errorEntry.type == "warning" then
        errorData.warningCount = errorData.warningCount + 1
    else
        errorData.criticalCount = errorData.criticalCount + 1
    end
    
    -- Update error rate calculation
    local currentTime = GetTime()
    
    -- Reset rate tracking after 60 seconds
    if currentTime - errorData.errorRateStartTime > 60 then
        errorData.errorRateStartTime = currentTime
        errorData.errorsSinceRateStart = 1
    else
        errorData.errorsSinceRateStart = errorData.errorsSinceRateStart + 1
    end
    
    -- Calculate errors per minute
    errorData.errorRate = errorData.errorsSinceRateStart / 
                        ((currentTime - errorData.errorRateStartTime) / 60)
    
    -- Log error
    self:LogError(errorEntry)
    
    -- If error rate is too high, enter safe mode
    if config.useSafeModeOnCritical and errorData.errorRate > MAX_ERROR_RATE then
        self:EnterSafeMode()
    end
    
    -- Update last error time
    errorData.lastErrorTime = currentTime
    
    return errorEntry
}

-- Log an error
function StabilityManager:LogError(errorEntry)
    if config.logLevel <= 0 then return end
    
    -- Format basic error info
    local errorInfo = errorEntry.type:upper() .. ": " .. errorEntry.message
    
    -- Add module and function info if available
    if errorEntry.module then
        errorInfo = errorInfo .. " in " .. errorEntry.module
        
        if errorEntry.function then
            errorInfo = errorInfo .. ":" .. errorEntry.function
        end
    end
    
    -- Add occurrence count for duplicates
    if errorEntry.count > 1 then
        errorInfo = errorInfo .. " (occurred " .. errorEntry.count .. " times)"
    end
    
    -- Log based on level
    if config.logLevel >= 3 and errorEntry.stack then
        -- Include stack trace for detailed logging
        WR:Debug(errorInfo .. "\nStack: " .. errorEntry.stack)
    else
        WR:Debug(errorInfo)
    end
    
    -- Show notification if enabled
    if config.errorNotifications then
        if errorEntry.count == 1 then -- Only notify on first occurrence
            local notificationText = errorEntry.type:upper() .. ": " .. errorEntry.message
            
            if WR.UI and WR.UI.ShowNotification then
                WR.UI:ShowNotification(notificationText, "error")
            else
                WR:Print(notificationText)
            end
        end
    end
}

-- Get module name from stack trace
function StabilityManager:GetModuleFromStack(stack)
    if not stack then return nil end
    
    -- Try to match a module name in the stack
    for moduleName, _ in pairs(WR) do
        if stack:match(moduleName) then
            return moduleName
        end
    end
    
    -- Look for addon name in the stack
    if stack:match(addonName) then
        -- Try to extract function path
        local path = stack:match("([%w%.]+):")
        if path then
            -- Get the first part of the path
            local module = path:match("([%w]+)%.")
            if module then
                return module
            end
        end
    end
    
    return nil
}

-- Get function name from stack trace
function StabilityManager:GetFunctionFromStack(stack)
    if not stack then return nil end
    
    -- Try to match function name in various formats
    local func = stack:match("in function '([%w_:%.]+)'")
    if not func then
        func = stack:match("in function <([%w_:%.]+)>")
    end
    if not func then
        func = stack:match("([%w_:%.]+):")
    end
    
    return func
}

-- Attempt to recover from an error
function StabilityManager:AttemptRecovery(message, stack)
    -- Get module from stack trace
    local moduleName = self:GetModuleFromStack(stack)
    local functionName = self:GetFunctionFromStack(stack)
    
    -- Create a key for tracking recovery attempts
    local recoveryKey = moduleName or "unknown"
    if functionName then
        recoveryKey = recoveryKey .. ":" .. functionName
    end
    
    -- Initialize recovery attempts counter
    errorData.recoveryAttempts[recoveryKey] = errorData.recoveryAttempts[recoveryKey] or 0
    
    -- Check if we've tried too many times
    if errorData.recoveryAttempts[recoveryKey] >= RECOVERY_ATTEMPT_LIMIT then
        -- Too many attempts, stop trying to recover this issue
        WR:Debug("Exceeded recovery attempt limit for", recoveryKey)
        
        -- Mark this as a known issue
        errorData.knownIssues[recoveryKey] = {
            message = message,
            stack = stack,
            time = GetTime(),
            attempts = errorData.recoveryAttempts[recoveryKey]
        }
        
        -- If we know which module is failing, try isolating it
        if config.isolateProblematicModules and moduleName and WR[moduleName] then
            self:IsolateModule(moduleName)
        end
        
        return false
    end
    
    -- Increment recovery attempts
    errorData.recoveryAttempts[recoveryKey] = errorData.recoveryAttempts[recoveryKey] + 1
    
    WR:Debug("Attempting recovery for", recoveryKey, 
             "(Attempt", errorData.recoveryAttempts[recoveryKey], "of", RECOVERY_ATTEMPT_LIMIT, ")")
    
    -- Try different recovery strategies based on the module
    local recovered = false
    
    if moduleName then
        -- Get the module
        local module = WR[moduleName]
        
        if module then
            recovered = self:RecoverModule(module, moduleName, functionName, message)
        end
    end
    
    -- If no specific module recovery worked, try general recovery
    if not recovered then
        recovered = self:PerformGeneralRecovery(message)
    end
    
    -- Log recovery result
    if recovered then
        WR:Debug("Successfully recovered from error in", recoveryKey)
        
        -- Show notification if enabled
        if config.recoveryNotifications then
            local notificationText = "Recovered from error in " .. (moduleName or "unknown module")
            
            if WR.UI and WR.UI.ShowNotification then
                WR.UI:ShowNotification(notificationText, "info")
            else
                WR:Print(notificationText)
            end
        end
        
        -- Mark the most recent error as recovered
        if #errorData.errors > 0 then
            errorData.errors[#errorData.errors].recovered = true
        end
    else
        WR:Debug("Failed to recover from error in", recoveryKey)
    end
    
    return recovered
end

-- Recover a specific module
function StabilityManager:RecoverModule(module, moduleName, functionName, errorMessage)
    -- Check if the module has its own recovery function
    if module.RecoverFromError and type(module.RecoverFromError) == "function" then
        -- Let the module handle its own recovery
        local success, result = pcall(function()
            return module:RecoverFromError(functionName, errorMessage)
        end)
        
        if success and result then
            return true
        end
    end
    
    -- Check if we have a backup state for this module
    if errorData.backupStates[moduleName] then
        -- Try to restore from backup
        local success = self:RestoreModuleFromBackup(moduleName)
        if success then
            return true
        end
    end
    
    -- Try to restart the module
    if config.autoRestartFailedModules and module.Initialize and type(module.Initialize) == "function" then
        local success, result = pcall(function()
            -- Check if there's a special Re-Initialize function
            if module.ReInitialize and type(module.ReInitialize) == "function" then
                module:ReInitialize()
            else
                module:Initialize()
            end
            return true
        end)
        
        if success and result then
            WR:Debug("Reinitialized module", moduleName)
            
            -- Record module restart
            errorData.moduleFailures[moduleName] = errorData.moduleFailures[moduleName] or {
                restarts = 0,
                lastRestart = 0
            }
            
            errorData.moduleFailures[moduleName].restarts = errorData.moduleFailures[moduleName].restarts + 1
            errorData.moduleFailures[moduleName].lastRestart = GetTime()
            
            return true
        end
    end
    
    -- If module has a Reset function, try that
    if module.Reset and type(module.Reset) == "function" then
        local success, result = pcall(function()
            module:Reset()
            return true
        end)
        
        if success and result then
            WR:Debug("Reset module", moduleName)
            return true
        end
    end
    
    -- No specific recovery method worked
    return false
end

-- Perform general recovery
function StabilityManager:PerformGeneralRecovery(errorMessage)
    -- Check for common error patterns and apply specific fixes
    
    -- Table index errors
    if errorMessage:match("attempt to index") or errorMessage:match("bad argument") then
        -- Force GC to clear any invalid references
        collectgarbage("collect")
        return true
    end
    
    -- Frame-related errors
    if errorMessage:match("InterfaceOptionsFrame") or errorMessage:match("Frame") then
        -- Hide and recreate problematic frames
        return self:FixFrameErrors()
    end
    
    -- Combat-related errors
    if InCombatLockdown() and (errorMessage:match("secure") or errorMessage:match("combat")) then
        -- Can't fix secure elements in combat
        WR:Debug("Can't fix secure UI elements in combat, will retry after combat")
        
        -- Schedule post-combat recovery
        local combatFrame = CreateFrame("Frame")
        combatFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
        combatFrame:SetScript("OnEvent", function(self, event)
            -- Try recovery again after combat
            StabilityManager:PerformGeneralRecovery(errorMessage)
            combatFrame:UnregisterAllEvents()
        end)
        
        return false -- Not recovered yet, but scheduled
    end
    
    -- Try a generic approach - restart all modules
    if not self.hasTriedRestartingModules then
        self.hasTriedRestartingModules = true
        return self:RestartAllModules()
    end
    
    self.hasTriedRestartingModules = false
    return false
}

-- Fix frame-related errors
function StabilityManager:FixFrameErrors()
    -- Try to identify and fix problematic frames
    if WR.UI then
        -- If UI module exists, try resetting it
        if WR.UI.ResetFrames and type(WR.UI.ResetFrames) == "function" then
            local success = pcall(function()
                WR.UI:ResetFrames()
            end)
            
            if success then
                return true
            end
        end
    end
    
    return false
}

-- Restart all modules
function StabilityManager:RestartAllModules()
    local anySuccess = false
    
    -- Try to restart each module
    for moduleName, module in pairs(WR) do
        if type(module) == "table" and module.Initialize and type(module.Initialize) == "function" then
            -- Skip self to avoid infinite recursion
            if moduleName ~= "StabilityManager" then
                local success = pcall(function()
                    module:Initialize()
                end)
                
                if success then
                    anySuccess = true
                    WR:Debug("Reinitialized module", moduleName, "during error recovery")
                end
            end
        end
    end
    
    return anySuccess
}

-- Initialize safety checks
function StabilityManager:InitializeSafetyChecks()
    if not config.safetyChecksEnabled then return end
    
    -- Define safety checks
    errorData.safetyChecks = {
        -- Check if critical modules are functional
        {
            name = "CriticalModules",
            interval = 5,
            lastCheck = 0,
            check = function()
                local criticalModules = {"API", "Combat", "Rotation", "UI"}
                
                for _, moduleName in ipairs(criticalModules) do
                    local module = WR[moduleName]
                    if not module then
                        return false, "Missing critical module: " .. moduleName
                    end
                end
                
                return true
            end,
            recover = function()
                -- Try to recreate missing modules
                return self:RestartAllModules()
            end
        },
        
        -- Check for memory leaks
        {
            name = "MemoryUsage",
            interval = 60,
            lastCheck = 0,
            check = function()
                local currentMemory = collectgarbage("count") / 1024 -- MB
                
                if not errorData.lastMemoryCheck then
                    errorData.lastMemoryCheck = currentMemory
                    return true
                end
                
                -- Check if memory usage has grown significantly
                local memoryGrowth = currentMemory - errorData.lastMemoryCheck
                errorData.lastMemoryCheck = currentMemory
                
                if memoryGrowth > 20 then -- 20MB growth in a minute is suspicious
                    return false, "Possible memory leak detected: " .. string.format("%.2f", memoryGrowth) .. "MB growth"
                end
                
                return true
            end,
            recover = function()
                -- Force garbage collection
                collectgarbage("collect")
                return true
            end
        },
        
        -- Check for high CPU usage functions
        {
            name = "CPUUsage",
            interval = 30,
            lastCheck = 0,
            check = function()
                -- This would need a more sophisticated monitoring system
                -- For now, just check if any functions have been recorded as problematic
                if errorData.functionPerformance and next(errorData.functionPerformance) then
                    for funcName, perf in pairs(errorData.functionPerformance) do
                        if perf.avgTime > 100 then -- 100ms is very slow
                            return false, "High CPU usage in function: " .. funcName
                        end
                    end
                end
                
                return true
            end,
            recover = function()
                -- No specific recovery action for high CPU usage
                return false
            end
        },
        
        -- Check for UI errors
        {
            name = "UIState",
            interval = 10,
            lastCheck = 0,
            check = function()
                if not WR.UI then return true end
                
                -- Check if UI is in a valid state
                if WR.UI.IsValid and type(WR.UI.IsValid) == "function" then
                    local valid = pcall(function() return WR.UI:IsValid() end)
                    if not valid then
                        return false, "UI is in an invalid state"
                    end
                end
                
                return true
            end,
            recover = function()
                if not WR.UI then return false end
                
                -- Try to reset UI
                if WR.UI.Reset and type(WR.UI.Reset) == "function" then
                    local success = pcall(function() WR.UI:Reset() end)
                    return success
                end
                
                return false
            end
        }
    }
    
    -- Start watchdog if enabled
    if config.useWatchdog then
        self:StartWatchdog()
    end
    
    -- Start stall detection if enabled
    if config.stallDetection then
        self:StartStallDetection()
    end
    
    WR:Debug("Safety checks initialized")
}

-- Perform safety checks
function StabilityManager:PerformSafetyChecks()
    if not config.safetyChecksEnabled or not errorData.safetyChecks then return end
    
    local currentTime = GetTime()
    errorData.lastSafetyCheck = currentTime
    
    -- Run each safety check at its interval
    for _, check in ipairs(errorData.safetyChecks) do
        if currentTime - (check.lastCheck or 0) >= check.interval then
            check.lastCheck = currentTime
            
            -- Run the check
            local success, errorMessage = check.check()
            
            if not success then
                -- Safety check failed
                WR:Debug("Safety check failed:", check.name, "-", errorMessage)
                
                -- Record as an error
                self:RecordError(errorMessage, nil, "warning")
                
                -- Try to recover
                if check.recover and config.autoRecover then
                    local recovered = check.recover()
                    
                    if recovered then
                        WR:Debug("Successfully recovered from", check.name, "failure")
                    else
                        WR:Debug("Failed to recover from", check.name, "failure")
                    end
                end
            end
        end
    end
}

-- Protect critical functions from errors
function StabilityManager:ProtectCriticalFunctions()
    -- Find critical functions to protect
    local criticalFunctions = {
        {"Rotation", "GetNextAbility"},
        {"Combat", "ProcessCombatEvent"},
        {"API", "Cast"},
        {"UI", "Update"},
        -- Add more critical functions as needed
    }
    
    -- Set up protection for each function
    for _, funcInfo in ipairs(criticalFunctions) do
        local moduleName, funcName = unpack(funcInfo)
        local module = WR[moduleName]
        
        if module and module[funcName] and type(module[funcName]) == "function" then
            -- Store original function
            errorData.protectedFunctions[moduleName .. "." .. funcName] = module[funcName]
            
            -- Replace with protected version
            module[funcName] = function(...)
                local success, result = pcall(function()
                    return errorData.protectedFunctions[moduleName .. "." .. funcName](...)
                end)
                
                if not success then
                    -- Function failed
                    WR:Debug("Protected function", moduleName .. "." .. funcName, "failed:", result)
                    
                    -- Record error
                    self:RecordError("Protected function failed: " .. result, nil, "warning")
                    
                    -- Try to return a safe default value
                    return self:GetSafeDefaultFor(moduleName, funcName)
                end
                
                return result
            end
            
            WR:Debug("Protected critical function", moduleName .. "." .. funcName)
        end
    end
}

-- Get a safe default value for a function
function StabilityManager:GetSafeDefaultFor(moduleName, funcName)
    -- Provide safe default returns for known critical functions
    if moduleName == "Rotation" and funcName == "GetNextAbility" then
        return nil -- No ability to cast
    elseif moduleName == "Combat" and funcName == "ProcessCombatEvent" then
        return false -- Event not processed
    elseif moduleName == "API" and funcName == "Cast" then
        return false -- Cast failed
    elseif moduleName == "UI" and funcName == "Update" then
        return -- No return value needed
    end
    
    -- Generic case
    return nil
}

-- Start monitoring for stability
function StabilityManager:StartMonitoring()
    -- Create backup of module states
    self:BackupModuleStates()
    
    -- Set initial module states
    for moduleName, module in pairs(WR) do
        if type(module) == "table" then
            errorData.moduleStates[moduleName] = {
                active = true,
                lastError = 0,
                errorCount = 0
            }
        end
    end
    
    -- Start watchdog if enabled
    if config.useWatchdog then
        self:StartWatchdog()
    end
    
    -- Start stall detection if enabled
    if config.stallDetection then
        self:StartStallDetection()
    end
    
    -- Set up periodic state backups
    C_Timer.NewTicker(config.backupInterval, function()
        self:BackupModuleStates()
    end)
    
    WR:Debug("Stability monitoring started")
}

-- Backup current state of modules
function StabilityManager:BackupModuleStates()
    -- Create backups of module states
    for moduleName, module in pairs(WR) do
        if type(module) == "table" then
            -- Skip utility tables and self
            if moduleName ~= "StabilityManager" and not moduleName:match("^_") then
                -- Try to create a backup
                local backup = self:CreateModuleBackup(module, moduleName)
                
                if backup then
                    errorData.backupStates[moduleName] = backup
                end
            end
        end
    end
    
    WR:Debug("Module states backed up")
}

-- Create a backup of a module
function StabilityManager:CreateModuleBackup(module, moduleName)
    -- Check if module has its own backup method
    if module.CreateBackup and type(module.CreateBackup) == "function" then
        local success, result = pcall(function()
            return module:CreateBackup()
        end)
        
        if success and result then
            return result
        end
    end
    
    -- Default backup method - simple shallow copy
    local backup = {
        _lastBackup = GetTime(),
        _version = 1
    }
    
    -- Only backup non-function, non-table properties
    for k, v in pairs(module) do
        if type(v) ~= "function" and type(v) ~= "table" and not k:match("^_") then
            backup[k] = v
        end
    end
    
    return backup
}

-- Restore a module from backup
function StabilityManager:RestoreModuleFromBackup(moduleName)
    local backup = errorData.backupStates[moduleName]
    if not backup then return false end
    
    local module = WR[moduleName]
    if not module then return false end
    
    -- Check if module has its own restore method
    if module.RestoreFromBackup and type(module.RestoreFromBackup) == "function" then
        local success, result = pcall(function()
            return module:RestoreFromBackup(backup)
        end)
        
        if success and result then
            return true
        end
    end
    
    -- Default restore method
    local success = pcall(function()
        for k, v in pairs(backup) do
            if not k:match("^_") then
                module[k] = v
            end
        end
    end)
    
    return success
}

-- Start watchdog timer
function StabilityManager:StartWatchdog()
    if not config.useWatchdog then return end
    
    -- Set initial ping
    errorData.watchdogLastPing = GetTime()
    
    -- Create watchdog ticker
    C_Timer.NewTicker(WATCHDOG_TIMEOUT / 2, function()
        self:CheckWatchdog()
    end)
    
    WR:Debug("Watchdog timer started")
}

-- Ping the watchdog
function StabilityManager:PingWatchdog()
    errorData.watchdogLastPing = GetTime()
}

-- Check if watchdog has timed out
function StabilityManager:CheckWatchdog()
    if not config.useWatchdog then return end
    
    local currentTime = GetTime()
    local timeSinceLastPing = currentTime - errorData.watchdogLastPing
    
    if timeSinceLastPing > WATCHDOG_TIMEOUT then
        -- Watchdog timeout - addon may be stalled
        WR:Debug("Watchdog timeout detected - addon may be stalled")
        
        -- Record as an error
        self:RecordError("Watchdog timeout - addon may be stalled", nil, "warning")
        
        -- Try to recover
        if config.autoRecover then
            -- Reset watchdog timer
            errorData.watchdogLastPing = currentTime
            
            -- Attempt recovery
            self:RecoverFromStall()
        end
    end
}

-- Start stall detection
function StabilityManager:StartStallDetection()
    if not config.stallDetection or errorData.stallDetectionStarted then return end
    
    -- Mark as started
    errorData.stallDetectionStarted = true
    errorData.stallDetectionLastUpdate = GetTime()
    
    -- Hook OnUpdate to detect stalls
    local updateFrame = CreateFrame("Frame")
    updateFrame:SetScript("OnUpdate", function(self, elapsed)
        errorData.stallDetectionLastUpdate = GetTime()
    end)
    
    -- Create checker ticker
    C_Timer.NewTicker(ADDON_STALLED_THRESHOLD / 2, function()
        self:CheckForStalls()
    end)
    
    WR:Debug("Stall detection started")
}

-- Check for UI stalls
function StabilityManager:CheckForStalls()
    if not config.stallDetection or not errorData.stallDetectionStarted then return end
    
    local currentTime = GetTime()
    local timeSinceLastUpdate = currentTime - errorData.stallDetectionLastUpdate
    
    if timeSinceLastUpdate > ADDON_STALLED_THRESHOLD then
        -- UI may be stalled
        WR:Debug("UI stall detected - ", timeSinceLastUpdate, "seconds since last update")
        
        -- Record as an error
        self:RecordError("UI stall detected - " .. string.format("%.1f", timeSinceLastUpdate) .. 
                      "s since last update", nil, "warning")
        
        -- Try to recover
        if config.autoRecover then
            -- Update timestamp to prevent multiple recoveries
            errorData.stallDetectionLastUpdate = currentTime
            
            -- Attempt recovery
            self:RecoverFromStall()
        end
    end
}

-- Recover from a stall
function StabilityManager:RecoverFromStall()
    WR:Debug("Attempting to recover from stall")
    
    -- Force garbage collection
    collectgarbage("collect")
    
    -- Try to restart critical modules
    local criticalModules = {"UI", "Rotation", "Combat", "API"}
    local anySuccess = false
    
    for _, moduleName in ipairs(criticalModules) do
        local module = WR[moduleName]
        
        if module and module.Initialize and type(module.Initialize) == "function" then
            local success = pcall(function()
                module:Initialize()
            end)
            
            if success then
                anySuccess = true
                WR:Debug("Reinitialized module", moduleName, "during stall recovery")
            end
        end
    end
    
    -- If reinitializing didn't work, try safer approaches
    if not anySuccess then
        self:EnterSafeMode()
    end
    
    return anySuccess
}

-- Isolate a problematic module
function StabilityManager:IsolateModule(moduleName)
    if not config.isolateProblematicModules then return end
    
    local module = WR[moduleName]
    if not module then return end
    
    WR:Debug("Isolating problematic module:", moduleName)
    
    -- Mark module as inactive
    errorData.moduleStates[moduleName] = errorData.moduleStates[moduleName] or {}
    errorData.moduleStates[moduleName].active = false
    
    -- Attempt to safely disable the module
    if module.Disable and type(module.Disable) == "function" then
        pcall(function() module:Disable() end)
    end
    
    -- Replace critical functions with safe versions
    for funcName, func in pairs(module) do
        if type(func) == "function" and not funcName:match("^_") then
            -- Skip initialization and recovery functions
            if funcName ~= "Initialize" and funcName ~= "RecoverFromError" and 
               funcName ~= "Reset" and funcName ~= "ReInitialize" then
                
                -- Replace with safe version
                module[funcName] = function(...)
                    -- Log call to disabled module
                    if config.logLevel >= 3 then
                        WR:Debug("Call to isolated module:", moduleName .. "." .. funcName)
                    end
                    
                    -- Return safe default
                    return self:GetSafeDefaultFor(moduleName, funcName)
                end
            end
        end
    end
    
    -- Add isolation notification
    if config.recoveryNotifications then
        local notificationText = "Module " .. moduleName .. " has been isolated due to errors"
        
        if WR.UI and WR.UI.ShowNotification then
            WR.UI:ShowNotification(notificationText, "warning")
        else
            WR:Print(notificationText)
        end
    end
}

-- Enter safe mode
function StabilityManager:EnterSafeMode()
    if not config.useSafeModeOnCritical then return end
    
    WR:Debug("Entering safe mode due to critical errors")
    
    -- Show notification
    local notificationText = "Entering safe mode due to critical errors"
    
    if WR.UI and WR.UI.ShowNotification then
        WR.UI:ShowNotification(notificationText, "error")
    else
        WR:Print(notificationText)
    end
    
    -- Disable non-critical modules
    local criticalModules = {
        StabilityManager = true,
        API = true, 
        UI = true
    }
    
    for moduleName, module in pairs(WR) do
        if type(module) == "table" and not criticalModules[moduleName] then
            -- Try to safely disable the module
            if module.Disable and type(module.Disable) == "function" then
                pcall(function() module:Disable() end)
            end
            
            -- Mark as inactive
            errorData.moduleStates[moduleName] = errorData.moduleStates[moduleName] or {}
            errorData.moduleStates[moduleName].active = false
        end
    end
    
    -- Simplify UI if possible
    if WR.UI and WR.UI.EnterSimpleMode and type(WR.UI.EnterSimpleMode) == "function" then
        pcall(function() WR.UI:EnterSimpleMode() end)
    end
    
    -- Force garbage collection
    collectgarbage("collect")
    
    -- Create recovery button if UI is available
    if WR.UI and WR.UI.CreateRecoveryButton and type(WR.UI.CreateRecoveryButton) == "function" then
        pcall(function()
            WR.UI:CreateRecoveryButton(function()
                -- Button click handler
                StabilityManager:ExitSafeMode()
            end)
        end)
    end
}

-- Exit safe mode
function StabilityManager:ExitSafeMode()
    WR:Debug("Exiting safe mode")
    
    -- Show notification
    local notificationText = "Exiting safe mode - attempting to restore normal operation"
    
    if WR.UI and WR.UI.ShowNotification then
        WR.UI:ShowNotification(notificationText, "info")
    else
        WR:Print(notificationText)
    end
    
    -- Try to restart all modules
    self:RestartAllModules()
    
    -- Reset module states
    for moduleName, state in pairs(errorData.moduleStates) do
        state.active = true
    end
    
    -- Reset error counters
    errorData.warningCount = 0
    errorData.criticalCount = 0
    errorData.errorRate = 0
    errorData.errorsSinceRateStart = 0
    errorData.errorRateStartTime = GetTime()
    
    -- Return UI to normal mode if possible
    if WR.UI and WR.UI.ExitSimpleMode and type(WR.UI.ExitSimpleMode) == "function" then
        pcall(function() WR.UI:ExitSimpleMode() end)
    end
    
    -- Update backup states
    self:BackupModuleStates()
}

-- Get a list of recent errors
function StabilityManager:GetRecentErrors(count)
    count = count or 10
    
    local result = {}
    local startIdx = math.max(1, #errorData.errors - count + 1)
    
    for i = startIdx, #errorData.errors do
        table.insert(result, errorData.errors[i])
    end
    
    return result
}

-- Get error statistics
function StabilityManager:GetErrorStatistics()
    return {
        total = #errorData.errors,
        warnings = errorData.warningCount,
        critical = errorData.criticalCount,
        rate = errorData.errorRate,
        lastError = errorData.lastErrorTime > 0 and 
                   (GetTime() - errorData.lastErrorTime) or nil,
        knownIssues = self:TableSize(errorData.knownIssues),
        moduleFailures = self:TableSize(errorData.moduleFailures),
        recoveryAttempts = self:TableSize(errorData.recoveryAttempts)
    }
}

-- Get configuration
function StabilityManager:GetConfig()
    return config
}

-- Set configuration
function StabilityManager:SetConfig(newConfig)
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
            WR:Debug("Stability management enabled")
            self:StartMonitoring()
        else
            WR:Debug("Stability management disabled")
        end
    end
    
    if oldConfig.useWatchdog ~= config.useWatchdog then
        if config.useWatchdog then
            self:StartWatchdog()
        end
    end
    
    if oldConfig.stallDetection ~= config.stallDetection then
        if config.stallDetection then
            self:StartStallDetection()
        end
    end
    
    if oldConfig.protectCriticalFunctions ~= config.protectCriticalFunctions then
        if config.protectCriticalFunctions then
            self:ProtectCriticalFunctions()
        end
    end
    
    -- Save configuration
    self:SaveSettings()
}

-- Handle stability commands
function StabilityManager:HandleCommand(args)
    if not args or args == "" then
        -- Show stability report
        self:ShowStabilityReport()
        return
    end
    
    local command, parameter = args:match("^(%S+)%s*(.*)$")
    command = command and command:lower() or args:lower()
    
    if command == "errors" or command == "error" then
        -- Show recent errors
        self:ShowRecentErrors()
    elseif command == "stats" or command == "statistics" then
        -- Show error statistics
        self:ShowErrorStatistics()
    elseif command == "modules" or command == "module" then
        -- Show module status
        self:ShowModuleStatus()
    elseif command == "reset" then
        -- Reset error data
        self:ResetErrorData()
    elseif command == "backup" then
        -- Create backups
        self:BackupModuleStates()
        WR:Print("Created backups of all module states")
    elseif command == "restore" then
        -- Restore from backups
        if parameter == "" then
            -- Show restorable modules
            self:ShowRestorableModules()
        else
            -- Restore specific module
            local moduleName = parameter
            local success = self:RestoreModuleFromBackup(moduleName)
            
            if success then
                WR:Print("Successfully restored module:", moduleName)
            else
                WR:Print("Failed to restore module:", moduleName)
            end
        end
    elseif command == "safemode" then
        if parameter == "enter" then
            self:EnterSafeMode()
        elseif parameter == "exit" then
            self:ExitSafeMode()
        else
            WR:Print("Usage: /wr stability safemode enter|exit")
        end
    elseif command == "isolate" then
        -- Isolate problematic module
        if parameter == "" then
            WR:Print("Usage: /wr stability isolate <moduleName>")
        else
            self:IsolateModule(parameter)
            WR:Print("Isolated module:", parameter)
        end
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
                
                -- Apply changes if needed
                if setting == "useWatchdog" and config.useWatchdog then
                    self:StartWatchdog()
                elseif setting == "stallDetection" and config.stallDetection then
                    self:StartStallDetection()
                elseif setting == "protectCriticalFunctions" and config.protectCriticalFunctions then
                    self:ProtectCriticalFunctions()
                end
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
        WR:Print("Unknown stability command:", command)
        WR:Print("Available commands: errors, stats, modules, reset, backup, restore, safemode, isolate, config")
    end
end

-- Reset error data
function StabilityManager:ResetErrorData()
    errorData.errors = {}
    errorData.warningCount = 0
    errorData.criticalCount = 0
    errorData.lastErrorTime = 0
    errorData.errorRate = 0
    errorData.errorRateStartTime = GetTime()
    errorData.errorsSinceRateStart = 0
    errorData.knownIssues = {}
    errorData.recoveryAttempts = {}
    
    WR:Print("Error data has been reset")
}

-- Show stability report
function StabilityManager:ShowStabilityReport()
    WR:Print("Stability Report:")
    
    -- Error statistics
    local stats = self:GetErrorStatistics()
    WR:Print("Errors:", stats.total, "(", stats.warnings, "warnings,", stats.critical, "critical )")
    WR:Print("Error Rate:", string.format("%.1f", stats.rate), "errors per minute")
    
    if stats.lastError then
        WR:Print("Last Error:", string.format("%.1f", stats.lastError), "seconds ago")
    else
        WR:Print("Last Error: None")
    end
    
    WR:Print("Known Issues:", stats.knownIssues)
    WR:Print("Module Failures:", stats.moduleFailures)
    WR:Print("Recovery Attempts:", stats.recoveryAttempts)
    
    -- Problematic modules
    WR:Print("")
    WR:Print("Problematic Modules:")
    
    local foundProblematic = false
    for moduleName, failures in pairs(errorData.moduleFailures) do
        WR:Print(moduleName, "- Restarts:", failures.restarts)
        foundProblematic = true
    end
    
    if not foundProblematic then
        WR:Print("None detected")
    end
    
    -- Safety checks
    WR:Print("")
    WR:Print("Safety Checks:", config.safetyChecksEnabled and "Enabled" or "Disabled")
    WR:Print("Last Check:", errorData.lastSafetyCheck > 0 and 
           string.format("%.1f", GetTime() - errorData.lastSafetyCheck) .. "s ago" or "Never")
}

-- Show recent errors
function StabilityManager:ShowRecentErrors()
    local recentErrors = self:GetRecentErrors(10)
    
    WR:Print("Recent Errors:")
    
    if #recentErrors == 0 then
        WR:Print("No errors recorded")
        return
    end
    
    for i, error in ipairs(recentErrors) do
        local timeAgo = GetTime() - error.time
        local timeStr = string.format("%.1f", timeAgo) .. "s ago"
        
        WR:Print(i .. ".", error.type:upper() .. ":", error.message, "(" .. timeStr .. ")")
        
        if error.module then
            WR:Print("   Module:", error.module)
        end
        
        if error.recovered then
            WR:Print("   [Recovered]")
        end
    end
}

-- Show error statistics
function StabilityManager:ShowErrorStatistics()
    local stats = self:GetErrorStatistics()
    
    WR:Print("Error Statistics:")
    WR:Print("Total Errors:", stats.total)
    WR:Print("Warnings:", stats.warnings)
    WR:Print("Critical Errors:", stats.critical)
    WR:Print("Error Rate:", string.format("%.1f", stats.rate), "errors per minute")
    
    if stats.lastError then
        WR:Print("Last Error:", string.format("%.1f", stats.lastError), "seconds ago")
    else
        WR:Print("Last Error: None")
    end
    
    -- Show known issues
    WR:Print("")
    WR:Print("Known Issues:", stats.knownIssues)
    
    local i = 0
    for key, issue in pairs(errorData.knownIssues) do
        i = i + 1
        if i > 5 then 
            WR:Print("   (and", stats.knownIssues - 5, "more...)")
            break
        end
        
        WR:Print("   " .. i .. ".", issue.message)
    end
    
    -- Show recovery attempts
    WR:Print("")
    WR:Print("Recovery Attempts:", stats.recoveryAttempts)
    
    local i = 0
    for key, attempts in pairs(errorData.recoveryAttempts) do
        i = i + 1
        if i > 5 then 
            WR:Print("   (and", stats.recoveryAttempts - 5, "more...)")
            break
        end
        
        WR:Print("   " .. i .. ".", key, "-", attempts, "attempts")
    end
}

-- Show module status
function StabilityManager:ShowModuleStatus()
    WR:Print("Module Status:")
    
    -- Sort modules by error count
    local moduleList = {}
    for moduleName, state in pairs(errorData.moduleStates) do
        table.insert(moduleList, {
            name = moduleName,
            active = state.active,
            errorCount = state.errorCount or 0,
            lastError = state.lastError or 0,
            hasBackup = errorData.backupStates[moduleName] ~= nil,
            restarts = errorData.moduleFailures[moduleName] and errorData.moduleFailures[moduleName].restarts or 0
        })
    end
    
    table.sort(moduleList, function(a, b)
        return a.errorCount > b.errorCount
    end)
    
    -- Show modules
    for _, module in ipairs(moduleList) do
        local status = module.active and "Active" or "Inactive"
        local backupStatus = module.hasBackup and "[Backup available]" or ""
        
        WR:Print(module.name, "-", status, backupStatus)
        
        if module.errorCount > 0 then
            local timeAgo = GetTime() - module.lastError
            WR:Print("   Errors:", module.errorCount, "Last:", string.format("%.1f", timeAgo), "seconds ago")
        end
        
        if module.restarts > 0 then
            WR:Print("   Restarts:", module.restarts)
        end
    end
}

-- Show restorable modules
function StabilityManager:ShowRestorableModules()
    WR:Print("Modules with backups available:")
    
    local found = false
    for moduleName, backup in pairs(errorData.backupStates) do
        local age = GetTime() - (backup._lastBackup or 0)
        WR:Print(moduleName, "- Age:", string.format("%.1f", age / 60), "minutes")
        found = true
    end
    
    if not found then
        WR:Print("No module backups available")
    end
    
    WR:Print("")
    WR:Print("To restore a module: /wr stability restore <moduleName>")
}

-- Show configuration
function StabilityManager:ShowConfig()
    WR:Print("Stability Manager Configuration:")
    
    for k, v in pairs(config) do
        WR:Print(k .. ":", tostring(v))
    end
    
    WR:Print("")
    WR:Print("To change a setting, use: /wr stability config setting value")
    WR:Print("Example: /wr stability config autoRecover false")
}

-- Create stability UI
function StabilityManager:CreateStabilityUI(parent)
    if not parent then return end
    
    -- Create the frame
    local frame = CreateFrame("Frame", "WindrunnerRotationsStabilityUI", parent, "BackdropTemplate")
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
    title:SetText("Windrunner Rotations Stability")
    
    -- Create close button
    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    
    -- Create tab buttons
    local tabWidth = 120
    local tabHeight = 24
    local tabs = {}
    local tabContents = {}
    
    local tabNames = {"Overview", "Errors", "Modules", "Settings"}
    
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
                StabilityManager:UpdateOverviewTab(content)
            elseif tabName == "Errors" then
                StabilityManager:UpdateErrorsTab(content)
            elseif tabName == "Modules" then
                StabilityManager:UpdateModulesTab(content)
            end
        end)
        
        tabs[i] = tab
        tabContents[i] = content
    end
    
    -- Populate Overview tab
    local overviewContent = tabContents[1]
    
    -- Function to update overview tab
    function StabilityManager:UpdateOverviewTab(content)
        -- Clear existing content
        for i = content:GetNumChildren(), 1, -1 do
            local child = select(i, content:GetChildren())
            if child:GetName() ~= "StatusFrame" and 
               child:GetName() ~= "StatsFrame" and
               child:GetName() ~= "ActionsFrame" then
                child:Hide()
                child:SetParent(nil)
            end
        end
        
        -- Create or get status frame
        local statusFrame = _G["StatusFrame"] or CreateFrame("Frame", "StatusFrame", content, "BackdropTemplate")
        statusFrame:SetSize(content:GetWidth(), 100)
        statusFrame:SetPoint("TOP", content, "TOP", 0, 0)
        statusFrame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        statusFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
        
        -- Get error statistics
        local stats = self:GetErrorStatistics()
        
        -- Create or update status panel
        local statusTitle = statusFrame.title or statusFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        statusTitle:SetPoint("TOPLEFT", statusFrame, "TOPLEFT", 15, -15)
        statusTitle:SetText("Stability Status")
        statusFrame.title = statusTitle
        
        local statusText = statusFrame.status or statusFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        statusText:SetPoint("TOPLEFT", statusTitle, "BOTTOMLEFT", 5, -5)
        
        -- Determine status text and color
        local statusColor
        local statusMessage
        
        if errorData.inRecoveryMode then
            statusMessage = "Recovering from Error"
            statusColor = {1, 0.5, 0}
        elseif stats.total == 0 then
            statusMessage = "Healthy - No Errors"
            statusColor = {0, 1, 0}
        elseif stats.critical > 10 then
            statusMessage = "Critical - Multiple Errors"
            statusColor = {1, 0, 0}
        elseif stats.rate > MAX_ERROR_RATE then
            statusMessage = "Warning - High Error Rate"
            statusColor = {1, 0.5, 0}
        elseif stats.lastError and stats.lastError < 60 then
            statusMessage = "Warning - Recent Error"
            statusColor = {1, 0.5, 0}
        else
            statusMessage = "Stable - Occasional Errors"
            statusColor = {0, 0.7, 0}
        end
        
        statusText:SetText("Current Status: " .. statusMessage)
        statusText:SetTextColor(unpack(statusColor))
        statusFrame.status = statusText
        
        local enabledText = statusFrame.enabled or statusFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        enabledText:SetPoint("TOPLEFT", statusText, "BOTTOMLEFT", 0, -5)
        enabledText:SetText("Stability Management: " .. (config.enabled and "Enabled" or "Disabled"))
        statusFrame.enabled = enabledText
        
        local recoveryText = statusFrame.recovery or statusFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        recoveryText:SetPoint("TOPLEFT", enabledText, "BOTTOMLEFT", 0, -5)
        recoveryText:SetText("Auto-Recovery: " .. (config.autoRecover and "Enabled" or "Disabled"))
        statusFrame.recovery = recoveryText
        
        -- Create or update stats frame
        local statsFrame = _G["StatsFrame"] or CreateFrame("Frame", "StatsFrame", content, "BackdropTemplate")
        statsFrame:SetSize(content:GetWidth(), 140)
        statsFrame:SetPoint("TOP", statusFrame, "BOTTOM", 0, -10)
        statsFrame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        statsFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
        
        local statsTitle = statsFrame.title or statsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        statsTitle:SetPoint("TOPLEFT", statsFrame, "TOPLEFT", 15, -15)
        statsTitle:SetText("Error Statistics")
        statsFrame.title = statsTitle
        
        -- Create a grid of stats
        local statsData = {
            {name = "Total Errors", value = stats.total},
            {name = "Warning Errors", value = stats.warnings},
            {name = "Critical Errors", value = stats.critical},
            {name = "Error Rate", value = string.format("%.1f", stats.rate) .. " per minute"},
            {name = "Last Error", value = stats.lastError and (string.format("%.1f", stats.lastError) .. "s ago") or "Never"},
            {name = "Known Issues", value = stats.knownIssues},
            {name = "Recovery Attempts", value = stats.recoveryAttempts},
            {name = "Module Failures", value = stats.moduleFailures}
        }
        
        -- Clear existing stats
        if statsFrame.items then
            for _, item in ipairs(statsFrame.items) do
                item.name:Hide()
                item.value:Hide()
            end
        end
        
        -- Create or update stats items
        statsFrame.items = statsFrame.items or {}
        
        local columns = 4
        local rows = math.ceil(#statsData / columns)
        local itemWidth = (statsFrame:GetWidth() - 30) / columns
        local itemHeight = 30
        
        for i, stat in ipairs(statsData) do
            local col = (i - 1) % columns
            local row = math.floor((i - 1) / columns)
            
            statsFrame.items[i] = statsFrame.items[i] or {}
            
            local nameText = statsFrame.items[i].name or statsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            nameText:SetPoint("TOPLEFT", statsFrame, "TOPLEFT", 15 + col * itemWidth, -40 - row * itemHeight)
            nameText:SetText(stat.name .. ":")
            statsFrame.items[i].name = nameText
            
            local valueText = statsFrame.items[i].value or statsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            valueText:SetPoint("TOPLEFT", nameText, "BOTTOMLEFT", 5, -2)
            valueText:SetText(stat.value)
            statsFrame.items[i].value = valueText
            
            nameText:Show()
            valueText:Show()
        end
        
        -- Create or update actions frame
        local actionsFrame = _G["ActionsFrame"] or CreateFrame("Frame", "ActionsFrame", content, "BackdropTemplate")
        actionsFrame:SetSize(content:GetWidth(), 100)
        actionsFrame:SetPoint("TOP", statsFrame, "BOTTOM", 0, -10)
        actionsFrame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        actionsFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
        
        local actionsTitle = actionsFrame.title or actionsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        actionsTitle:SetPoint("TOPLEFT", actionsFrame, "TOPLEFT", 15, -15)
        actionsTitle:SetText("Actions")
        actionsFrame.title = actionsTitle
        
        -- Create action buttons
        local buttonWidth = 120
        local buttonHeight = 30
        local buttonSpacing = 10
        local totalButtonWidth = 4 * buttonWidth + 3 * buttonSpacing
        local startX = (actionsFrame:GetWidth() - totalButtonWidth) / 2
        
        -- Reset Button
        local resetButton = actionsFrame.resetButton or CreateFrame("Button", nil, actionsFrame, "UIPanelButtonTemplate")
        resetButton:SetSize(buttonWidth, buttonHeight)
        resetButton:SetPoint("BOTTOMLEFT", actionsFrame, "BOTTOMLEFT", startX, 15)
        resetButton:SetText("Reset Error Data")
        resetButton:SetScript("OnClick", function()
            self:ResetErrorData()
            self:UpdateOverviewTab(content)
        end)
        actionsFrame.resetButton = resetButton
        
        -- Backup Button
        local backupButton = actionsFrame.backupButton or CreateFrame("Button", nil, actionsFrame, "UIPanelButtonTemplate")
        backupButton:SetSize(buttonWidth, buttonHeight)
        backupButton:SetPoint("LEFT", resetButton, "RIGHT", buttonSpacing, 0)
        backupButton:SetText("Backup States")
        backupButton:SetScript("OnClick", function()
            self:BackupModuleStates()
            WR:Print("Created backups of all module states")
        end)
        actionsFrame.backupButton = backupButton
        
        -- Safe Mode Button
        local safeModeButton = actionsFrame.safeModeButton or CreateFrame("Button", nil, actionsFrame, "UIPanelButtonTemplate")
        safeModeButton:SetSize(buttonWidth, buttonHeight)
        safeModeButton:SetPoint("LEFT", backupButton, "RIGHT", buttonSpacing, 0)
        
        if errorData.inSafeMode then
            safeModeButton:SetText("Exit Safe Mode")
            safeModeButton:SetScript("OnClick", function()
                self:ExitSafeMode()
                self:UpdateOverviewTab(content)
            end)
        else
            safeModeButton:SetText("Enter Safe Mode")
            safeModeButton:SetScript("OnClick", function()
                self:EnterSafeMode()
                self:UpdateOverviewTab(content)
            end)
        end
        
        actionsFrame.safeModeButton = safeModeButton
        
        -- Restart Button
        local restartButton = actionsFrame.restartButton or CreateFrame("Button", nil, actionsFrame, "UIPanelButtonTemplate")
        restartButton:SetSize(buttonWidth, buttonHeight)
        restartButton:SetPoint("LEFT", safeModeButton, "RIGHT", buttonSpacing, 0)
        restartButton:SetText("Restart Modules")
        restartButton:SetScript("OnClick", function()
            self:RestartAllModules()
            WR:Print("Restarted all modules")
            self:UpdateOverviewTab(content)
        end)
        actionsFrame.restartButton = restartButton
    end
    
    -- Populate Errors tab
    local errorsContent = tabContents[2]
    
    -- Function to update errors tab
    function StabilityManager:UpdateErrorsTab(content)
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
        headerTitle:SetText("Recent Errors")
        
        local countText = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        countText:SetPoint("TOPRIGHT", headerFrame, "TOPRIGHT", -15, -15)
        countText:SetText("Total Errors: " .. #errorData.errors)
        
        -- Create scroll frame for errors
        local scrollFrame = CreateFrame("ScrollFrame", nil, content, "UIPanelScrollFrameTemplate")
        scrollFrame:SetSize(content:GetWidth() - 30, content:GetHeight() - 120)
        scrollFrame:SetPoint("TOP", headerFrame, "BOTTOM", 0, -5)
        
        local scrollChild = CreateFrame("Frame", nil, scrollFrame)
        scrollChild:SetSize(scrollFrame:GetWidth(), 1) -- Height will be set dynamically
        scrollFrame:SetScrollChild(scrollChild)
        
        -- Get recent errors
        local recentErrors = self:GetRecentErrors(20)
        
        -- Display errors
        local yOffset = 10
        for i, error in ipairs(recentErrors) do
            local errorFrame = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
            errorFrame:SetSize(scrollChild:GetWidth() - 20, 70)
            errorFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, -yOffset)
            errorFrame:SetBackdrop({
                bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile = true,
                tileSize = 16,
                edgeSize = 16,
                insets = { left = 4, right = 4, top = 4, bottom = 4 }
            })
            errorFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
            
            -- Set border color based on error type
            local r, g, b = 0.7, 0.7, 0.7 -- Default gray
            if error.type == "warning" then
                r, g, b = 1, 0.8, 0 -- Yellow for warnings
            elseif error.type == "error" then
                r, g, b = 1, 0, 0 -- Red for errors
            end
            
            errorFrame:SetBackdropBorderColor(r, g, b)
            
            -- Error number and type
            local typeText = errorFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            typeText:SetPoint("TOPLEFT", errorFrame, "TOPLEFT", 15, -10)
            typeText:SetText(i .. ". " .. error.type:upper())
            typeText:SetTextColor(r, g, b)
            
            -- Time ago
            local timeAgo = GetTime() - error.time
            local timeText = errorFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            timeText:SetPoint("TOPRIGHT", errorFrame, "TOPRIGHT", -15, -10)
            timeText:SetText(string.format("%.1f", timeAgo) .. "s ago")
            
            -- Error message
            local messageText = errorFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            messageText:SetPoint("TOPLEFT", typeText, "BOTTOMLEFT", 0, -5)
            messageText:SetPoint("RIGHT", errorFrame, "RIGHT", -15, 0)
            messageText:SetText(error.message)
            messageText:SetJustifyH("LEFT")
            
            -- Module and function info
            local locationText = errorFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            locationText:SetPoint("TOPLEFT", messageText, "BOTTOMLEFT", 0, -5)
            
            local location = ""
            if error.module then
                location = "Module: " .. error.module
                
                if error.function then
                    location = location .. " | Function: " .. error.function
                end
            end
            
            locationText:SetText(location)
            
            -- Recovered status
            if error.recovered then
                local recoveredText = errorFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                recoveredText:SetPoint("BOTTOMRIGHT", errorFrame, "BOTTOMRIGHT", -15, 5)
                recoveredText:SetText("[Recovered]")
                recoveredText:SetTextColor(0, 1, 0)
            end
            
            -- Adjust height based on content
            local minHeight = 70
            local textHeight = 20 + messageText:GetStringHeight() + 5 + locationText:GetStringHeight() + 10
            errorFrame:SetHeight(math.max(minHeight, textHeight))
            
            yOffset = yOffset + errorFrame:GetHeight() + 5
        end
        
        -- Handle empty list
        if #recentErrors == 0 then
            local noErrors = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            noErrors:SetPoint("CENTER", scrollChild, "CENTER", 0, 0)
            noErrors:SetText("No errors recorded")
            
            yOffset = 100
        end
        
        scrollChild:SetHeight(math.max(yOffset, scrollFrame:GetHeight()))
        
        -- Create action buttons
        local resetButton = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
        resetButton:SetSize(120, 30)
        resetButton:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -10, 10)
        resetButton:SetText("Reset Errors")
        resetButton:SetScript("OnClick", function()
            self:ResetErrorData()
            self:UpdateErrorsTab(content)
        end)
        
        local refreshButton = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
        refreshButton:SetSize(120, 30)
        refreshButton:SetPoint("RIGHT", resetButton, "LEFT", -10, 0)
        refreshButton:SetText("Refresh")
        refreshButton:SetScript("OnClick", function()
            self:UpdateErrorsTab(content)
        end)
    end
    
    -- Populate Modules tab
    local modulesContent = tabContents[3]
    
    -- Function to update modules tab
    function StabilityManager:UpdateModulesTab(content)
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
        headerTitle:SetText("Module Status")
        
        -- Create scroll frame for modules
        local scrollFrame = CreateFrame("ScrollFrame", nil, content, "UIPanelScrollFrameTemplate")
        scrollFrame:SetSize(content:GetWidth() - 30, content:GetHeight() - 120)
        scrollFrame:SetPoint("TOP", headerFrame, "BOTTOM", 0, -5)
        
        local scrollChild = CreateFrame("Frame", nil, scrollFrame)
        scrollChild:SetSize(scrollFrame:GetWidth(), 1) -- Height will be set dynamically
        scrollFrame:SetScrollChild(scrollChild)
        
        -- Get modules
        local moduleList = {}
        for moduleName, state in pairs(errorData.moduleStates) do
            table.insert(moduleList, {
                name = moduleName,
                active = state.active,
                errorCount = state.errorCount or 0,
                lastError = state.lastError or 0,
                hasBackup = errorData.backupStates[moduleName] ~= nil,
                restarts = errorData.moduleFailures[moduleName] and errorData.moduleFailures[moduleName].restarts or 0
            })
        end
        
        -- Sort by error count, then by name
        table.sort(moduleList, function(a, b)
            if a.errorCount == b.errorCount then
                return a.name < b.name
            end
            return a.errorCount > b.errorCount
        end)
        
        -- Display modules
        local yOffset = 10
        for i, module in ipairs(moduleList) do
            local moduleFrame = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
            moduleFrame:SetSize(scrollChild:GetWidth() - 20, 80)
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
            
            -- Set border color based on status
            local r, g, b = 0.7, 0.7, 0.7 -- Default gray
            if not module.active then
                r, g, b = 1, 0, 0 -- Red for inactive modules
            elseif module.errorCount > 0 then
                r, g, b = 1, 0.5, 0 -- Orange for modules with errors
            elseif module.hasBackup then
                r, g, b = 0, 0.7, 0 -- Green for healthy modules with backups
            end
            
            moduleFrame:SetBackdropBorderColor(r, g, b)
            
            -- Module name
            local nameText = moduleFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            nameText:SetPoint("TOPLEFT", moduleFrame, "TOPLEFT", 15, -15)
            nameText:SetText(module.name)
            
            -- Status
            local statusText = moduleFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            statusText:SetPoint("LEFT", nameText, "RIGHT", 10, 0)
            local status = module.active and "Active" or "Inactive"
            statusText:SetText("[" .. status .. "]")
            
            if module.active then
                statusText:SetTextColor(0, 0.7, 0)
            else
                statusText:SetTextColor(1, 0, 0)
            end
            
            -- Error info
            local errorInfoText = moduleFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            errorInfoText:SetPoint("TOPLEFT", nameText, "BOTTOMLEFT", 0, -5)
            
            local errorInfo = "Errors: " .. module.errorCount
            
            if module.errorCount > 0 then
                local timeAgo = GetTime() - module.lastError
                errorInfo = errorInfo .. " | Last: " .. string.format("%.1f", timeAgo) .. "s ago"
            end
            
            if module.restarts > 0 then
                errorInfo = errorInfo .. " | Restarts: " .. module.restarts
            end
            
            errorInfoText:SetText(errorInfo)
            
            -- Backup status
            local backupText = moduleFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            backupText:SetPoint("TOPLEFT", errorInfoText, "BOTTOMLEFT", 0, -5)
            
            if module.hasBackup then
                local backupAge = GetTime() - (errorData.backupStates[module.name]._lastBackup or 0)
                backupText:SetText("Backup available | Age: " .. string.format("%.1f", backupAge / 60) .. " minutes")
                backupText:SetTextColor(0, 0.7, 0)
            else
                backupText:SetText("No backup available")
                backupText:SetTextColor(0.7, 0.7, 0.7)
            end
            
            -- Action buttons
            if module.hasBackup then
                local restoreButton = CreateFrame("Button", nil, moduleFrame, "UIPanelButtonTemplate")
                restoreButton:SetSize(80, 22)
                restoreButton:SetPoint("BOTTOMRIGHT", moduleFrame, "BOTTOMRIGHT", -15, 10)
                restoreButton:SetText("Restore")
                restoreButton:SetScript("OnClick", function()
                    local success = self:RestoreModuleFromBackup(module.name)
                    
                    if success then
                        WR:Print("Successfully restored module:", module.name)
                    else
                        WR:Print("Failed to restore module:", module.name)
                    end
                    
                    self:UpdateModulesTab(content)
                end)
            end
            
            local restartButton = CreateFrame("Button", nil, moduleFrame, "UIPanelButtonTemplate")
            restartButton:SetSize(80, 22)
            restartButton:SetPoint("BOTTOMRIGHT", moduleFrame, "BOTTOMRIGHT", module.hasBackup and -105 or -15, 10)
            restartButton:SetText("Restart")
            restartButton:SetScript("OnClick", function()
                local moduleObj = WR[module.name]
                
                if moduleObj and moduleObj.Initialize and type(moduleObj.Initialize) == "function" then
                    local success = pcall(function()
                        moduleObj:Initialize()
                    end)
                    
                    if success then
                        WR:Print("Reinitialized module:", module.name)
                    else
                        WR:Print("Failed to reinitialize module:", module.name)
                    end
                else
                    WR:Print("Module cannot be restarted:", module.name)
                end
                
                self:UpdateModulesTab(content)
            end)
            
            if not module.active then
                local isolateButton = CreateFrame("Button", nil, moduleFrame, "UIPanelButtonTemplate")
                isolateButton:SetSize(80, 22)
                isolateButton:SetPoint("BOTTOMLEFT", moduleFrame, "BOTTOMLEFT", 15, 10)
                isolateButton:SetText("Isolate")
                isolateButton:SetScript("OnClick", function()
                    self:IsolateModule(module.name)
                    WR:Print("Isolated module:", module.name)
                    self:UpdateModulesTab(content)
                end)
            end
            
            yOffset = yOffset + moduleFrame:GetHeight() + 10
        end
        
        -- Handle empty list
        if #moduleList == 0 then
            local noModules = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            noModules:SetPoint("CENTER", scrollChild, "CENTER", 0, 0)
            noModules:SetText("No module data available")
            
            yOffset = 100
        end
        
        scrollChild:SetHeight(math.max(yOffset, scrollFrame:GetHeight()))
        
        -- Create action buttons
        local backupButton = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
        backupButton:SetSize(120, 30)
        backupButton:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -10, 10)
        backupButton:SetText("Backup All")
        backupButton:SetScript("OnClick", function()
            self:BackupModuleStates()
            WR:Print("Created backups of all module states")
            self:UpdateModulesTab(content)
        end)
        
        local refreshButton = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
        refreshButton:SetSize(120, 30)
        refreshButton:SetPoint("RIGHT", backupButton, "LEFT", -10, 0)
        refreshButton:SetText("Refresh")
        refreshButton:SetScript("OnClick", function()
            self:UpdateModulesTab(content)
        end)
        
        local restartAllButton = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
        restartAllButton:SetSize(120, 30)
        restartAllButton:SetPoint("RIGHT", refreshButton, "LEFT", -10, 0)
        restartAllButton:SetText("Restart All")
        restartAllButton:SetScript("OnClick", function()
            self:RestartAllModules()
            WR:Print("Restarted all modules")
            self:UpdateModulesTab(content)
        end)
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
    settingsTitle:SetText("Stability Settings")
    
    -- Create checkboxes for various settings
    local checkboxes = {}
    local checkY = -50
    local checkboxLabels = {
        enabledCheckbox = "Enable stability management",
        autoRecoverCheckbox = "Automatically recover from errors",
        preventRecursiveErrorsCheckbox = "Prevent recursive errors",
        useWatchdogCheckbox = "Use watchdog timer",
        monitorFramerateCheckbox = "Monitor framerate",
        errorNotificationsCheckbox = "Show error notifications",
        recoveryNotificationsCheckbox = "Show recovery notifications",
        safetyChecksEnabledCheckbox = "Enable safety checks",
        protectCriticalFunctionsCheckbox = "Protect critical functions",
        autoRestartFailedModulesCheckbox = "Auto-restart failed modules",
        stallDetectionCheckbox = "Enable stall detection",
        useSafeModeOnCriticalCheckbox = "Use safe mode for critical errors",
        isolateProblematicModulesCheckbox = "Isolate problematic modules",
        detailedErrorReportingCheckbox = "Detailed error reporting"
    }
    
    local i = 0
    for name, label in pairs(checkboxLabels) do
        local checkbox = CreateFrame("CheckButton", nil, settingsFrame, "UICheckButtonTemplate")
        checkbox:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 30, checkY - (i * 25))
        
        local text = checkbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
        text:SetText(label)
        
        checkboxes[name] = checkbox
        i = i + 1
    end
    
    -- Set initial values
    checkboxes.enabledCheckbox:SetChecked(config.enabled)
    checkboxes.autoRecoverCheckbox:SetChecked(config.autoRecover)
    checkboxes.preventRecursiveErrorsCheckbox:SetChecked(config.preventRecursiveErrors)
    checkboxes.useWatchdogCheckbox:SetChecked(config.useWatchdog)
    checkboxes.monitorFramerateCheckbox:SetChecked(config.monitorFramerate)
    checkboxes.errorNotificationsCheckbox:SetChecked(config.errorNotifications)
    checkboxes.recoveryNotificationsCheckbox:SetChecked(config.recoveryNotifications)
    checkboxes.safetyChecksEnabledCheckbox:SetChecked(config.safetyChecksEnabled)
    checkboxes.protectCriticalFunctionsCheckbox:SetChecked(config.protectCriticalFunctions)
    checkboxes.autoRestartFailedModulesCheckbox:SetChecked(config.autoRestartFailedModules)
    checkboxes.stallDetectionCheckbox:SetChecked(config.stallDetection)
    checkboxes.useSafeModeOnCriticalCheckbox:SetChecked(config.useSafeModeOnCritical)
    checkboxes.isolateProblematicModulesCheckbox:SetChecked(config.isolateProblematicModules)
    checkboxes.detailedErrorReportingCheckbox:SetChecked(config.detailedErrorReporting)
    
    -- Logging level slider
    local levelLabel = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    levelLabel:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 30, checkY - (i * 25) - 20)
    levelLabel:SetText("Logging Level:")
    
    local levelSlider = CreateFrame("Slider", nil, settingsFrame, "OptionsSliderTemplate")
    levelSlider:SetPoint("TOPLEFT", levelLabel, "BOTTOMLEFT", 20, -10)
    levelSlider:SetWidth(200)
    levelSlider:SetHeight(16)
    levelSlider:SetMinMaxValues(0, 3)
    levelSlider:SetValue(config.logLevel)
    levelSlider:SetValueStep(1)
    levelSlider:SetObeyStepOnDrag(true)
    
    -- Set labels
    _G[levelSlider:GetName() .. "Low"]:SetText("None")
    _G[levelSlider:GetName() .. "High"]:SetText("Debug")
    _G[levelSlider:GetName() .. "Text"]:SetText(config.logLevel)
    
    -- Backup interval slider
    local backupLabel = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    backupLabel:SetPoint("TOPLEFT", levelSlider, "BOTTOMLEFT", -20, -20)
    backupLabel:SetText("Backup Interval (minutes):")
    
    local backupSlider = CreateFrame("Slider", nil, settingsFrame, "OptionsSliderTemplate")
    backupSlider:SetPoint("TOPLEFT", backupLabel, "BOTTOMLEFT", 20, -10)
    backupSlider:SetWidth(200)
    backupSlider:SetHeight(16)
    backupSlider:SetMinMaxValues(1, 30)
    backupSlider:SetValue(config.backupInterval / 60)
    backupSlider:SetValueStep(1)
    backupSlider:SetObeyStepOnDrag(true)
    
    -- Set labels
    _G[backupSlider:GetName() .. "Low"]:SetText("1m")
    _G[backupSlider:GetName() .. "High"]:SetText("30m")
    _G[backupSlider:GetName() .. "Text"]:SetText(config.backupInterval / 60)
    
    -- Set up slider behavior
    levelSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value)
        _G[self:GetName() .. "Text"]:SetText(value)
    end)
    
    backupSlider:SetScript("OnValueChanged", function(self, value)
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
        config.autoRecover = checkboxes.autoRecoverCheckbox:GetChecked()
        config.preventRecursiveErrors = checkboxes.preventRecursiveErrorsCheckbox:GetChecked()
        config.useWatchdog = checkboxes.useWatchdogCheckbox:GetChecked()
        config.monitorFramerate = checkboxes.monitorFramerateCheckbox:GetChecked()
        config.errorNotifications = checkboxes.errorNotificationsCheckbox:GetChecked()
        config.recoveryNotifications = checkboxes.recoveryNotificationsCheckbox:GetChecked()
        config.safetyChecksEnabled = checkboxes.safetyChecksEnabledCheckbox:GetChecked()
        config.protectCriticalFunctions = checkboxes.protectCriticalFunctionsCheckbox:GetChecked()
        config.autoRestartFailedModules = checkboxes.autoRestartFailedModulesCheckbox:GetChecked()
        config.stallDetection = checkboxes.stallDetectionCheckbox:GetChecked()
        config.useSafeModeOnCritical = checkboxes.useSafeModeOnCriticalCheckbox:GetChecked()
        config.isolateProblematicModules = checkboxes.isolateProblematicModulesCheckbox:GetChecked()
        config.detailedErrorReporting = checkboxes.detailedErrorReportingCheckbox:GetChecked()
        
        config.logLevel = levelSlider:GetValue()
        config.backupInterval = backupSlider:GetValue() * 60
        
        -- Save configuration
        StabilityManager:SaveSettings()
        
        -- Apply changes if needed
        if config.useWatchdog then
            StabilityManager:StartWatchdog()
        end
        
        if config.stallDetection then
            StabilityManager:StartStallDetection()
        end
        
        if config.protectCriticalFunctions then
            StabilityManager:ProtectCriticalFunctions()
        end
        
        WR:Print("Stability settings saved")
    end)
    
    local resetButton = CreateFrame("Button", nil, settingsContent, "UIPanelButtonTemplate")
    resetButton:SetSize(100, 30)
    resetButton:SetPoint("RIGHT", saveButton, "LEFT", -10, 0)
    resetButton:SetText("Reset")
    resetButton:SetScript("OnClick", function()
        -- Reset checkboxes to default values
        checkboxes.enabledCheckbox:SetChecked(true)
        checkboxes.autoRecoverCheckbox:SetChecked(true)
        checkboxes.preventRecursiveErrorsCheckbox:SetChecked(true)
        checkboxes.useWatchdogCheckbox:SetChecked(true)
        checkboxes.monitorFramerateCheckbox:SetChecked(true)
        checkboxes.errorNotificationsCheckbox:SetChecked(true)
        checkboxes.recoveryNotificationsCheckbox:SetChecked(true)
        checkboxes.safetyChecksEnabledCheckbox:SetChecked(true)
        checkboxes.protectCriticalFunctionsCheckbox:SetChecked(true)
        checkboxes.autoRestartFailedModulesCheckbox:SetChecked(true)
        checkboxes.stallDetectionCheckbox:SetChecked(true)
        checkboxes.useSafeModeOnCriticalCheckbox:SetChecked(true)
        checkboxes.isolateProblematicModulesCheckbox:SetChecked(true)
        checkboxes.detailedErrorReportingCheckbox:SetChecked(true)
        
        -- Reset sliders
        levelSlider:SetValue(2)
        backupSlider:SetValue(5)
    end)
    
    -- Select first tab by default
    tabs[1].selectedTexture:Show()
    tabContents[1]:Show()
    
    -- Update first tab content
    StabilityManager:UpdateOverviewTab(tabContents[1])
    
    -- Hide by default
    frame:Hide()
    
    return frame
}

-- Helper function: Get table size
function StabilityManager:TableSize(tbl)
    local count = 0
    if tbl then
        for _ in pairs(tbl) do
            count = count + 1
        end
    end
    return count
end

-- Initialize the module
StabilityManager:Initialize()

return StabilityManager