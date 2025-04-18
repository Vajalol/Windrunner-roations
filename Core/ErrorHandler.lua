------------------------------------------
-- WindrunnerRotations - Error Handler
-- Author: VortexQ8
-- The War Within Season 2
------------------------------------------

local addonName, WR = ...
local ErrorHandler = {}
WR.ErrorHandler = ErrorHandler

-- Dependencies
local API = WR.API
local ConfigRegistry = WR.ConfigRegistry
local ModuleManager = WR.ModuleManager

-- Error data
local errorHistory = {}
local protectedFunctions = {}
local errorStates = {}
local lastErrorTime = 0
local lastErrorMessage = ""
local consecutiveErrors = 0
local maxConsecutiveErrors = 5
local resetErrorCountTimer = 10 -- seconds
local errorDataFrame = nil
local MAX_ERROR_HISTORY = 100
local isInRecoveryMode = false
local recoveryStartTime = 0
local RECOVERY_DURATION = 5 -- seconds
local moduleErrorCount = {}
local criticalModules = {
    "RotationManager",
    "API",
    "ConfigRegistry",
    "InterruptManager",
    "AutoTargeting"
}
local hardErrorLimit = 20 -- Errors per module before disabling
local softErrorLimit = 5 -- Errors before warning
local errorListeners = {}
local actionTransaction = nil
local lastTransaction = nil
local systemState = {}
local fallbackValues = {}
local errorSeverity = {
    INFO = 1,
    WARNING = 2,
    ERROR = 3,
    CRITICAL = 4,
    FATAL = 5
}
local errorCategories = {
    API_ERROR = "API Error",
    ADDON_ERROR = "Addon Error",
    ROTATION_ERROR = "Rotation Error",
    CONFIG_ERROR = "Configuration Error",
    COMBAT_ERROR = "Combat Error",
    MEMORY_ERROR = "Memory Error",
    INTERFACE_ERROR = "Interface Error",
    NETWORK_ERROR = "Network Error",
    UNKNOWN_ERROR = "Unknown Error"
}
local telemetryEnabled = false

-- Initialize the Error Handler
function ErrorHandler:Initialize()
    -- Register settings
    self:RegisterSettings()
    
    -- Create error data frame
    self:CreateErrorFrame()
    
    -- Register events
    self:RegisterEvents()
    
    -- Set up script error handler
    self:SetupScriptErrorHandler()
    
    -- Register critical modules
    self:RegisterCriticalModules()
    
    API.PrintDebug("Error Handler initialized")
    return true
end

-- Register settings
function ErrorHandler:RegisterSettings()
    ConfigRegistry:RegisterSettings("ErrorHandler", {
        generalSettings = {
            enableErrorRecovery = {
                displayName = "Enable Error Recovery",
                description = "Try to recover from errors automatically",
                type = "toggle",
                default = true
            },
            showErrorMessages = {
                displayName = "Show Error Messages",
                description = "Display error messages in chat",
                type = "toggle",
                default = true
            },
            errorAlertLevel = {
                displayName = "Error Alert Level",
                description = "Minimum severity level for error alerts",
                type = "dropdown",
                options = {"All", "Warning", "Error", "Critical", "Fatal"},
                default = "Warning"
            },
            maxConsecutiveErrors = {
                displayName = "Max Consecutive Errors",
                description = "Maximum number of consecutive errors before entering recovery mode",
                type = "slider",
                min = 1,
                max = 10,
                step = 1,
                default = 5
            }
        },
        recoverySettings = {
            autoResetOnZoneChange = {
                displayName = "Auto Reset on Zone Change",
                description = "Reset error state when changing zones",
                type = "toggle",
                default = true
            },
            disableModuleOnError = {
                displayName = "Disable Module on Error",
                description = "Disable modules that cause too many errors",
                type = "toggle",
                default = true
            },
            recoveryMethod = {
                displayName = "Recovery Method",
                description = "Method to use for error recovery",
                type = "dropdown",
                options = {"Full Reset", "Partial Reset", "Minimal Reset", "Custom"},
                default = "Partial Reset"
            },
            recoveryDuration = {
                displayName = "Recovery Duration",
                description = "How long to stay in recovery mode (seconds)",
                type = "slider",
                min = 1,
                max = 30,
                step = 1,
                default = 5
            }
        },
        debugSettings = {
            enableErrorLogging = {
                displayName = "Enable Error Logging",
                description = "Log errors to a file",
                type = "toggle",
                default = true
            },
            saveErrorHistory = {
                displayName = "Save Error History",
                description = "Save error history between sessions",
                type = "toggle",
                default = true
            },
            enableTelemetry = {
                displayName = "Enable Telemetry",
                description = "Send anonymous error reports to improve the addon",
                type = "toggle",
                default = false
            },
            detailedErrorInfo = {
                displayName = "Detailed Error Info",
                description = "Show detailed error information",
                type = "toggle",
                default = false
            }
        }
    })
}

-- Create error frame
function ErrorHandler:CreateErrorFrame()
    errorDataFrame = CreateFrame("Frame", "WindrunnerRotationsErrorFrame")
    errorDataFrame:Hide()
    
    -- Create OnUpdate handler for recovery mode
    errorDataFrame:SetScript("OnUpdate", function(self, elapsed)
        if isInRecoveryMode then
            ErrorHandler:UpdateRecoveryMode(elapsed)
        end
    end)
end

-- Register events
function ErrorHandler:RegisterEvents()
    -- Register for addon loaded to setup error recovery
    API.RegisterEvent("ADDON_LOADED", function(loadedAddonName)
        if loadedAddonName == "WindrunnerRotations" then
            ErrorHandler:SetupErrorCapture()
        end
    end)
    
    -- Register for zone changes to reset error state
    API.RegisterEvent("PLAYER_ENTERING_WORLD", function()
        local settings = ConfigRegistry:GetSettings("ErrorHandler")
        if settings.recoverySettings.autoResetOnZoneChange then
            ErrorHandler:ResetErrorState()
        end
    end)
    
    -- Register for logout to save error history
    API.RegisterEvent("PLAYER_LOGOUT", function()
        local settings = ConfigRegistry:GetSettings("ErrorHandler")
        if settings.debugSettings.saveErrorHistory then
            ErrorHandler:SaveErrorHistory()
        end
    end)
}

-- Setup script error handler
function ErrorHandler:SetupScriptErrorHandler()
    -- Save original error handler
    self.originalErrorHandler = _G.geterrorhandler()
    
    -- Set up our error handler
    _G.seterrorhandler(function(msg)
        -- Process error
        local handled = ErrorHandler:ProcessError(msg)
        
        -- If we didn't handle it, pass to original handler
        if not handled and ErrorHandler.originalErrorHandler then
            return ErrorHandler.originalErrorHandler(msg)
        end
    end)
}

-- Setup error capture
function ErrorHandler:SetupErrorCapture()
    -- Load settings
    local settings = ConfigRegistry:GetSettings("ErrorHandler")
    maxConsecutiveErrors = settings.generalSettings.maxConsecutiveErrors
    telemetryEnabled = settings.debugSettings.enableTelemetry
    RECOVERY_DURATION = settings.recoverySettings.recoveryDuration
    
    -- Register critical modules
    self:RegisterCriticalModules()
    
    -- Set up protected call wrapper
    self:SetupProtectedCallWrapper()
    
    -- Initialize system state tracking
    self:InitializeSystemState()
    
    -- Set up fallback values
    self:SetupFallbackValues()
}

-- Register critical modules
function ErrorHandler:RegisterCriticalModules()
    -- Clear existing data
    moduleErrorCount = {}
    
    -- Initialize error count for all modules
    for moduleName, _ in pairs(WR) do
        moduleErrorCount[moduleName] = 0
    end
    
    -- Mark critical modules
    for _, moduleName in ipairs(criticalModules) do
        if WR[moduleName] then
            WR[moduleName].isCritical = true
        end
    end
}

-- Setup protected call wrapper
function ErrorHandler:SetupProtectedCallWrapper()
    -- Replace critical functions with protected versions
    for moduleName, module in pairs(WR) do
        if type(module) == "table" then
            for funcName, func in pairs(module) do
                if type(func) == "function" and not protectedFunctions[moduleName .. "." .. funcName] then
                    -- Skip the error handler itself to avoid infinite recursion
                    if moduleName ~= "ErrorHandler" then
                        -- Create protected version of function
                        protectedFunctions[moduleName .. "." .. funcName] = func
                        
                        -- Replace with protected version
                        module[funcName] = function(...)
                            return ErrorHandler:SafeExecute(moduleName, funcName, func, ...)
                        end
                    end
                end
            end
        end
    end
}

-- Initialize system state
function ErrorHandler:InitializeSystemState()
    -- Track critical system state for recovery
    systemState = {
        currentRotation = nil,
        targetGUID = nil,
        combatStatus = nil,
        moduleStatus = {},
        configValues = {}
    }
    
    -- Initialize module status
    for moduleName, module in pairs(WR) do
        systemState.moduleStatus[moduleName] = {
            enabled = (module.IsEnabled and module:IsEnabled()) or true,
            state = (module.GetState and module:GetState()) or {}
        }
    end
    
    -- Capture initial config values
    if WR.ConfigRegistry then
        local configModules = WR.ConfigRegistry:GetAllSettings()
        for moduleName, settings in pairs(configModules) do
            systemState.configValues[moduleName] = self:DeepCopy(settings)
        end
    end
}

-- Setup fallback values
function ErrorHandler:SetupFallbackValues()
    -- Define fallback values for common functions
    fallbackValues = {
        ["RotationManager.ExecuteRotation"] = false,
        ["RotationManager.GetActiveRotation"] = nil,
        ["AutoTargeting.FindAndSetTarget"] = false,
        ["AutoTargeting.GetBestTarget"] = nil,
        ["InterruptManager.ShouldInterrupt"] = false,
        ["InterruptManager.CanInterrupt"] = false,
        ["API.GetUnitDistance"] = 30, -- Default distance
        ["API.IsUnitInRange"] = false,
        ["API.GetPlayerInfo"] = {health = 100, mana = 100, level = 70}
    }
}

-- Process error
function ErrorHandler:ProcessError(errorMsg)
    -- Skip if already in recovery mode
    if isInRecoveryMode then
        return true
    end
    
    -- Get settings
    local settings = ConfigRegistry:GetSettings("ErrorHandler")
    
    -- Check if error recovery is enabled
    if not settings.generalSettings.enableErrorRecovery then
        return false
    end
    
    -- Parse error message to determine source
    local moduleName, funcName, errorDetails = self:ParseErrorMessage(errorMsg)
    
    -- Record error
    local errorInfo = self:RecordError(moduleName, funcName, errorMsg)
    
    -- Display error message if enabled
    if settings.generalSettings.showErrorMessages then
        self:DisplayErrorMessage(errorInfo)
    end
    
    -- Check if we need to enter recovery mode
    if self:ShouldEnterRecoveryMode(moduleName) then
        self:EnterRecoveryMode()
    end
    
    -- Return true to indicate we've handled the error
    return true
end

-- Parse error message
function ErrorHandler:ParseErrorMessage(errorMsg)
    -- Default values
    local moduleName = "Unknown"
    local funcName = "Unknown"
    local errorDetails = errorMsg
    
    -- Try to extract module and function name from error message
    local pattern = "WindrunnerRotations\\(.-):(%d+): (.*)"
    local file, line, details = errorMsg:match(pattern)
    
    if file and line and details then
        -- Extract module name from file path
        moduleName = file:match("Core/([^%.]+)%.lua") or 
                    file:match("Classes/([^%.]+)%.lua") or
                    "Unknown"
                    
        -- Extract function name from details if possible
        funcName = details:match("in function '(.-)'") or "Unknown"
        
        -- Clean up error details
        errorDetails = details:gsub("in function '.-'", ""):trim()
    else
        -- Alternative pattern for addon errors
        pattern = "...ns/WindrunnerRotations/(.-):(%d+): (.*)"
        file, line, details = errorMsg:match(pattern)
        
        if file and line and details then
            -- Extract module name from file path
            moduleName = file:match("Core/([^%.]+)%.lua") or 
                        file:match("Classes/([^%.]+)%.lua") or
                        "Unknown"
                        
            -- Extract function name from details if possible
            funcName = details:match("in function '(.-)'") or "Unknown"
            
            -- Clean up error details
            errorDetails = details:gsub("in function '.-'", ""):trim()
        end
    end
    
    return moduleName, funcName, errorDetails
end

-- Record error
function ErrorHandler:RecordError(moduleName, funcName, errorMsg)
    -- Create error info
    local errorInfo = {
        moduleName = moduleName,
        funcName = funcName,
        message = errorMsg,
        timestamp = GetTime(),
        count = 1,
        category = self:DetermineErrorCategory(moduleName, errorMsg),
        severity = self:DetermineErrorSeverity(moduleName, errorMsg),
        source = debugstack(2, 20, 0)
    }
    
    -- Check if it's a repeat of the last error
    if lastErrorMessage == errorMsg and GetTime() - lastErrorTime < resetErrorCountTimer then
        -- Increment consecutive error count
        consecutiveErrors = consecutiveErrors + 1
        errorInfo.count = consecutiveErrors
    else
        -- Reset consecutive error count
        consecutiveErrors = 1
    end
    
    -- Update last error info
    lastErrorMessage = errorMsg
    lastErrorTime = GetTime()
    
    -- Add to history
    table.insert(errorHistory, errorInfo)
    
    -- Trim history if needed
    while #errorHistory > MAX_ERROR_HISTORY do
        table.remove(errorHistory, 1)
    end
    
    -- Track module error count
    moduleErrorCount[moduleName] = (moduleErrorCount[moduleName] or 0) + 1
    
    -- Check if module is exceeding error limits
    local settings = ConfigRegistry:GetSettings("ErrorHandler")
    if moduleErrorCount[moduleName] >= hardErrorLimit and settings.recoverySettings.disableModuleOnError then
        -- Disable module
        self:DisableModule(moduleName)
    elseif moduleErrorCount[moduleName] >= softErrorLimit then
        -- Warn about module
        API.PrintMessage("WARNING: Module " .. moduleName .. " has generated multiple errors")
    end
    
    -- Notify error listeners
    self:NotifyErrorListeners(errorInfo)
    
    -- Send telemetry if enabled
    if telemetryEnabled then
        self:SendErrorTelemetry(errorInfo)
    end
    
    return errorInfo
end

-- Determine error category
function ErrorHandler:DetermineErrorCategory(moduleName, errorMsg)
    -- Check for common error patterns
    if errorMsg:match("attempt to index") or errorMsg:match("attempt to call") then
        return errorCategories.API_ERROR
    elseif errorMsg:match("stack overflow") or errorMsg:match("out of memory") then
        return errorCategories.MEMORY_ERROR
    elseif moduleName == "RotationManager" or errorMsg:match("rotation") then
        return errorCategories.ROTATION_ERROR
    elseif moduleName == "ConfigRegistry" or errorMsg:match("config") or errorMsg:match("settings") then
        return errorCategories.CONFIG_ERROR
    elseif errorMsg:match("combat") or errorMsg:match("in combat") then
        return errorCategories.COMBAT_ERROR
    elseif errorMsg:match("interface") or errorMsg:match("UI") or errorMsg:match("frame") then
        return errorCategories.INTERFACE_ERROR
    elseif errorMsg:match("network") or errorMsg:match("server") or errorMsg:match("timeout") then
        return errorCategories.NETWORK_ERROR
    else
        return errorCategories.ADDON_ERROR
    end
end

-- Determine error severity
function ErrorHandler:DetermineErrorSeverity(moduleName, errorMsg)
    -- Check if it's a critical module
    local isCriticalModule = false
    for _, criticalModule in ipairs(criticalModules) do
        if moduleName == criticalModule then
            isCriticalModule = true
            break
        end
    end
    
    -- Determine severity based on module and error pattern
    if errorMsg:match("stack overflow") or errorMsg:match("out of memory") then
        return errorSeverity.FATAL
    elseif isCriticalModule and (errorMsg:match("attempt to index") or errorMsg:match("attempt to call")) then
        return errorSeverity.CRITICAL
    elseif isCriticalModule then
        return errorSeverity.ERROR
    elseif errorMsg:match("attempt to index") or errorMsg:match("attempt to call") then
        return errorSeverity.ERROR
    else
        return errorSeverity.WARNING
    end
end

-- Display error message
function ErrorHandler:DisplayErrorMessage(errorInfo)
    -- Get settings
    local settings = ConfigRegistry:GetSettings("ErrorHandler")
    
    -- Determine minimum severity to display
    local minSeverity = errorSeverity.WARNING
    local alertLevel = settings.generalSettings.errorAlertLevel
    
    if alertLevel == "All" then
        minSeverity = errorSeverity.INFO
    elseif alertLevel == "Warning" then
        minSeverity = errorSeverity.WARNING
    elseif alertLevel == "Error" then
        minSeverity = errorSeverity.ERROR
    elseif alertLevel == "Critical" then
        minSeverity = errorSeverity.CRITICAL
    elseif alertLevel == "Fatal" then
        minSeverity = errorSeverity.FATAL
    end
    
    -- Check if error is severe enough to display
    if errorInfo.severity < minSeverity then
        return
    end
    
    -- Format message
    local message = "WindrunnerRotations Error: "
    
    -- Add severity prefix
    if errorInfo.severity == errorSeverity.FATAL then
        message = "|cffff0000FATAL: " .. message
    elseif errorInfo.severity == errorSeverity.CRITICAL then
        message = "|cffff0000CRITICAL: " .. message
    elseif errorInfo.severity == errorSeverity.ERROR then
        message = "|cffff6600ERROR: " .. message
    elseif errorInfo.severity == errorSeverity.WARNING then
        message = "|cffffff00WARNING: " .. message
    end
    
    -- Add module and function info
    message = message .. "[" .. errorInfo.moduleName
    
    if errorInfo.funcName ~= "Unknown" then
        message = message .. "." .. errorInfo.funcName
    end
    
    message = message .. "] "
    
    -- Add error message
    if settings.debugSettings.detailedErrorInfo then
        message = message .. errorInfo.message
    else
        -- Simplified message
        local simplified = errorInfo.message:gsub("WindrunnerRotations\\.-: ", "")
        simplified = simplified:gsub("in function '.-'", "")
        message = message .. simplified
    end
    
    -- Print message
    API.PrintMessage(message)
    
    -- If it's a repeat error, show count
    if errorInfo.count > 1 then
        API.PrintMessage("This error has occurred " .. errorInfo.count .. " times in a row")
    end
}

-- Should enter recovery mode
function ErrorHandler:ShouldEnterRecoveryMode(moduleName)
    -- Check consecutive errors
    if consecutiveErrors >= maxConsecutiveErrors then
        return true
    end
    
    -- Check if a critical module is failing
    if self:IsCriticalModule(moduleName) and moduleErrorCount[moduleName] >= softErrorLimit then
        return true
    end
    
    return false
end

-- Is critical module
function ErrorHandler:IsCriticalModule(moduleName)
    for _, criticalModule in ipairs(criticalModules) do
        if moduleName == criticalModule then
            return true
        end
    end
    
    return false
end

-- Enter recovery mode
function ErrorHandler:EnterRecoveryMode()
    -- Skip if already in recovery mode
    if isInRecoveryMode then
        return
    end
    
    API.PrintMessage("Entering recovery mode to prevent further errors...")
    
    -- Set recovery mode
    isInRecoveryMode = true
    recoveryStartTime = GetTime()
    
    -- Show error frame to track recovery progress
    errorDataFrame:Show()
    
    -- Perform immediate recovery actions
    self:PerformRecoveryActions()
}

-- Update recovery mode
function ErrorHandler:UpdateRecoveryMode(elapsed)
    -- Check if recovery time has elapsed
    if GetTime() - recoveryStartTime >= RECOVERY_DURATION then
        self:ExitRecoveryMode()
    end
}

-- Exit recovery mode
function ErrorHandler:ExitRecoveryMode()
    -- Skip if not in recovery mode
    if not isInRecoveryMode then
        return
    end
    
    API.PrintMessage("Exiting recovery mode")
    
    -- Reset recovery state
    isInRecoveryMode = false
    
    -- Hide error frame
    errorDataFrame:Hide()
    
    -- Reset consecutive errors
    consecutiveErrors = 0
    
    -- Reset error tracking for modules
    for moduleName, _ in pairs(moduleErrorCount) do
        moduleErrorCount[moduleName] = 0
    end
    
    -- Re-enable any disabled modules
    self:ReenableModules()
}

-- Perform recovery actions
function ErrorHandler:PerformRecoveryActions()
    -- Get settings
    local settings = ConfigRegistry:GetSettings("ErrorHandler")
    local recoveryMethod = settings.recoverySettings.recoveryMethod
    
    -- Perform different actions based on recovery method
    if recoveryMethod == "Full Reset" then
        -- Reset everything
        self:PerformFullReset()
    elseif recoveryMethod == "Partial Reset" then
        -- Reset problematic modules
        self:PerformPartialReset()
    elseif recoveryMethod == "Minimal Reset" then
        -- Just reset critical modules
        self:PerformMinimalReset()
    else -- Custom
        -- Reset based on error patterns
        self:PerformCustomReset()
    end
}

-- Perform full reset
function ErrorHandler:PerformFullReset()
    -- Reset all modules
    for moduleName, module in pairs(WR) do
        if type(module) == "table" and module.Reset then
            API.PrintDebug("Resetting module: " .. moduleName)
            self:SafeCall(function() module:Reset() end)
        end
    end
    
    -- Clear all caches
    self:ClearCaches()
    
    -- Reset system state
    self:ResetSystemState()
    
    -- Force a GC run
    collectgarbage("collect")
}

-- Perform partial reset
function ErrorHandler:PerformPartialReset()
    -- Reset problematic modules
    for moduleName, errorCount in pairs(moduleErrorCount) do
        if errorCount > 0 and WR[moduleName] and type(WR[moduleName]) == "table" and WR[moduleName].Reset then
            API.PrintDebug("Resetting problematic module: " .. moduleName)
            self:SafeCall(function() WR[moduleName]:Reset() end)
        end
    end
    
    -- Reset core modules that might be affected
    for _, criticalModule in ipairs(criticalModules) do
        if WR[criticalModule] and type(WR[criticalModule]) == "table" and WR[criticalModule].Reset then
            API.PrintDebug("Resetting critical module: " .. criticalModule)
            self:SafeCall(function() WR[criticalModule]:Reset() end)
        end
    end
    
    -- Partially clear caches
    self:ClearCaches(true)
}

-- Perform minimal reset
function ErrorHandler:PerformMinimalReset()
    -- Only reset critical modules
    for _, criticalModule in ipairs(criticalModules) do
        if WR[criticalModule] and type(WR[criticalModule]) == "table" and WR[criticalModule].Reset then
            API.PrintDebug("Resetting critical module: " .. criticalModule)
            self:SafeCall(function() WR[criticalModule]:Reset() end)
        end
    end
}

-- Perform custom reset
function ErrorHandler:PerformCustomReset()
    -- Analyze error patterns
    local errorModules = {}
    local errorTypes = {}
    
    -- Check last few errors
    for i = #errorHistory, math.max(1, #errorHistory - 10), -1 do
        local error = errorHistory[i]
        errorModules[error.moduleName] = (errorModules[error.moduleName] or 0) + 1
        errorTypes[error.category] = (errorTypes[error.category] or 0) + 1
    end
    
    -- Find most common error module
    local mostErrorModule = nil
    local mostErrors = 0
    
    for moduleName, count in pairs(errorModules) do
        if count > mostErrors then
            mostErrors = count
            mostErrorModule = moduleName
        end
    end
    
    -- Find most common error type
    local mostErrorType = nil
    local mostErrorTypeCount = 0
    
    for errorType, count in pairs(errorTypes) do
        if count > mostErrorTypeCount then
            mostErrorTypeCount = count
            mostErrorType = errorType
        end
    end
    
    -- Perform targeted reset
    if mostErrorModule and WR[mostErrorModule] and type(WR[mostErrorModule]) == "table" and WR[mostErrorModule].Reset then
        API.PrintDebug("Resetting error source module: " .. mostErrorModule)
        self:SafeCall(function() WR[mostErrorModule]:Reset() end)
    end
    
    -- Reset related modules based on error type
    if mostErrorType == errorCategories.ROTATION_ERROR then
        if WR.RotationManager and WR.RotationManager.Reset then
            self:SafeCall(function() WR.RotationManager:Reset() end)
        end
    elseif mostErrorType == errorCategories.CONFIG_ERROR then
        if WR.ConfigRegistry and WR.ConfigRegistry.Reset then
            self:SafeCall(function() WR.ConfigRegistry:Reset() end)
        end
    elseif mostErrorType == errorCategories.COMBAT_ERROR then
        if WR.CombatAnalysis and WR.CombatAnalysis.Reset then
            self:SafeCall(function() WR.CombatAnalysis:Reset() end)
        end
    elseif mostErrorType == errorCategories.INTERFACE_ERROR then
        -- Reset UI elements
        if WR.EnhancedConfigUI and WR.EnhancedConfigUI.Reset then
            self:SafeCall(function() WR.EnhancedConfigUI:Reset() end)
        end
    end
}

-- Clear caches
function ErrorHandler:ClearCaches(partialOnly)
    -- Clear various caches throughout the addon
    
    -- Target cache
    if WR.AutoTargeting and WR.AutoTargeting.ClearCache then
        self:SafeCall(function() WR.AutoTargeting:ClearCache() end)
    end
    
    -- Spell cache
    if WR.API and WR.API.ClearSpellCache then
        self:SafeCall(function() WR.API:ClearSpellCache() end)
    end
    
    -- Unit cache
    if WR.API and WR.API.ClearUnitCache then
        self:SafeCall(function() WR.API:ClearUnitCache() end)
    end
    
    -- Only clear additional caches if doing a full clear
    if not partialOnly then
        -- Config cache
        if WR.ConfigRegistry and WR.ConfigRegistry.InvalidateCache then
            self:SafeCall(function() WR.ConfigRegistry:InvalidateCache() end)
        end
        
        -- Combat cache
        if WR.CombatAnalysis and WR.CombatAnalysis.ClearCache then
            self:SafeCall(function() WR.CombatAnalysis:ClearCache() end)
        end
        
        -- Profile cache
        if WR.ProfileManager and WR.ProfileManager.InvalidateCache then
            self:SafeCall(function() WR.ProfileManager:InvalidateCache() end)
        end
    end
}

-- Reset system state
function ErrorHandler:ResetSystemState()
    -- Revert to last known good state
    
    -- Reset module status
    for moduleName, status in pairs(systemState.moduleStatus) do
        if WR[moduleName] then
            -- Set enabled state
            if WR[moduleName].SetEnabled then
                self:SafeCall(function() WR[moduleName]:SetEnabled(status.enabled) end)
            end
            
            -- Restore state if possible
            if WR[moduleName].RestoreState then
                self:SafeCall(function() WR[moduleName]:RestoreState(status.state) end)
            end
        end
    end
    
    -- Reset configuration
    if WR.ConfigRegistry then
        for moduleName, settings in pairs(systemState.configValues) do
            if WR.ConfigRegistry.RestoreSettings then
                self:SafeCall(function() WR.ConfigRegistry:RestoreSettings(moduleName, settings) end)
            end
        end
    end
}

-- Safe call
function ErrorHandler:SafeCall(func)
    local success, result = pcall(func)
    
    if not success then
        API.PrintDebug("Error during recovery: " .. tostring(result))
    end
    
    return success, result
end

-- Safe execute
function ErrorHandler:SafeExecute(moduleName, funcName, func, ...)
    -- Skip if in recovery mode
    if isInRecoveryMode then
        -- Return fallback value
        return self:GetFallbackValue(moduleName, funcName)
    end
    
    -- Check if we're currently in a transaction
    if actionTransaction then
        -- Add this call to the transaction
        table.insert(actionTransaction.calls, {
            moduleName = moduleName,
            funcName = funcName,
            args = {...}
        })
    end
    
    -- Capture system state before execution for critical functions
    if self:IsCriticalFunction(moduleName, funcName) then
        self:CaptureSystemState()
    end
    
    -- Execute with pcall
    local success, result = pcall(func, ...)
    
    if not success then
        -- Function failed, record error
        local errorMsg = tostring(result)
        local fullFuncName = moduleName .. "." .. funcName
        
        -- Process the error
        self:ProcessError(fullFuncName .. ": " .. errorMsg)
        
        -- If we're in a transaction, mark it as failed
        if actionTransaction then
            actionTransaction.success = false
            actionTransaction.error = errorMsg
        end
        
        -- Return fallback value
        return self:GetFallbackValue(moduleName, funcName)
    end
    
    -- Function succeeded, return result
    return result
end

-- Is critical function
function ErrorHandler:IsCriticalFunction(moduleName, funcName)
    -- Check if this is a critical module
    return self:IsCriticalModule(moduleName)
end

-- Capture system state
function ErrorHandler:CaptureSystemState()
    -- Capture current rotation
    if WR.RotationManager and WR.RotationManager.GetActiveRotation then
        systemState.currentRotation = self:SafeCall(function() return WR.RotationManager:GetActiveRotation() end)
    end
    
    -- Capture target GUID
    if UnitExists("target") then
        systemState.targetGUID = UnitGUID("target")
    end
    
    -- Capture combat status
    systemState.combatStatus = UnitAffectingCombat("player")
    
    -- Capture module status
    for moduleName, module in pairs(WR) do
        if type(module) == "table" then
            systemState.moduleStatus[moduleName] = {
                enabled = (module.IsEnabled and self:SafeCall(function() return module:IsEnabled() end)) or true,
                state = (module.GetState and self:SafeCall(function() return module:GetState() end)) or {}
            }
        end
    end
}

-- Get fallback value
function ErrorHandler:GetFallbackValue(moduleName, funcName)
    local fullFuncName = moduleName .. "." .. funcName
    
    -- Return specific fallback value if defined
    if fallbackValues[fullFuncName] ~= nil then
        return fallbackValues[fullFuncName]
    end
    
    -- Default fallback values based on function name pattern
    if funcName:match("^Get") then
        return nil
    elseif funcName:match("^Is") or funcName:match("^Has") or funcName:match("^Can") then
        return false
    elseif funcName:match("^Find") or funcName:match("^Create") or funcName:match("^Add") then
        return nil
    else
        return nil
    end
end

-- Begin transaction
function ErrorHandler:BeginTransaction(name)
    -- Skip if already in a transaction
    if actionTransaction then
        return false
    end
    
    -- Start new transaction
    actionTransaction = {
        name = name,
        startTime = GetTime(),
        calls = {},
        success = true,
        error = nil
    }
    
    return true
end

-- Commit transaction
function ErrorHandler:CommitTransaction()
    -- Skip if not in a transaction
    if not actionTransaction then
        return false
    end
    
    -- Store completed transaction
    lastTransaction = actionTransaction
    actionTransaction = nil
    
    return lastTransaction.success
end

-- Rollback transaction
function ErrorHandler:RollbackTransaction()
    -- Skip if not in a transaction
    if not actionTransaction then
        return false
    end
    
    -- Mark transaction as rolled back
    actionTransaction.rolledBack = true
    
    -- Store transaction
    lastTransaction = actionTransaction
    actionTransaction = nil
    
    return true
end

-- Disable module
function ErrorHandler:DisableModule(moduleName)
    -- Skip if module doesn't exist
    if not WR[moduleName] then
        return false
    end
    
    -- Skip if it's a critical module that can't be disabled
    if self:IsCriticalModule(moduleName) and not WR[moduleName].canDisable then
        API.PrintMessage("Critical module " .. moduleName .. " has generated too many errors but cannot be disabled")
        return false
    end
    
    -- Disable module
    if WR[moduleName].SetEnabled then
        self:SafeCall(function() WR[moduleName]:SetEnabled(false) end)
    end
    
    API.PrintMessage("Module " .. moduleName .. " has been temporarily disabled due to errors")
    
    -- Store disabled state
    systemState.moduleStatus[moduleName] = systemState.moduleStatus[moduleName] or {}
    systemState.moduleStatus[moduleName].enabled = false
    
    return true
}

-- Reenable modules
function ErrorHandler:ReenableModules()
    -- Re-enable any disabled modules
    for moduleName, status in pairs(systemState.moduleStatus) do
        if status.enabled == false and WR[moduleName] and WR[moduleName].SetEnabled then
            API.PrintDebug("Re-enabling module: " .. moduleName)
            self:SafeCall(function() WR[moduleName]:SetEnabled(true) end)
            systemState.moduleStatus[moduleName].enabled = true
        end
    end
}

-- Reset error state
function ErrorHandler:ResetErrorState()
    -- Reset error tracking
    consecutiveErrors = 0
    lastErrorTime = 0
    lastErrorMessage = ""
    
    -- Reset module error counts
    for moduleName, _ in pairs(moduleErrorCount) do
        moduleErrorCount[moduleName] = 0
    end
    
    -- Clear recovery mode if active
    if isInRecoveryMode then
        self:ExitRecoveryMode()
    end
    
    API.PrintDebug("Error state reset")
}

-- Save error history
function ErrorHandler:SaveErrorHistory()
    -- This would save error history to SavedVariables
    -- For now, we'll just log the action
    API.PrintDebug("Saving error history (" .. #errorHistory .. " entries)")
}

-- Register error listener
function ErrorHandler:RegisterErrorListener(listener)
    if type(listener) == "function" then
        table.insert(errorListeners, listener)
        return true
    end
    return false
end

-- Notify error listeners
function ErrorHandler:NotifyErrorListeners(errorInfo)
    for _, listener in ipairs(errorListeners) do
        self:SafeCall(function() listener(errorInfo) end)
    end
end

-- Send error telemetry
function ErrorHandler:SendErrorTelemetry(errorInfo)
    -- Skip if telemetry is disabled
    if not telemetryEnabled then
        return
    end
    
    -- In a real addon, this would send error data to a telemetry server
    -- For now, we'll just log the action
    API.PrintDebug("Sending error telemetry for " .. errorInfo.moduleName .. "." .. errorInfo.funcName)
}

-- Get error history
function ErrorHandler:GetErrorHistory()
    return errorHistory
end

-- Get module error counts
function ErrorHandler:GetModuleErrorCounts()
    return moduleErrorCount
end

-- Is in recovery mode
function ErrorHandler:IsInRecoveryMode()
    return isInRecoveryMode
end

-- Deep copy
function ErrorHandler:DeepCopy(tbl)
    if type(tbl) ~= "table" then return tbl end
    
    local copy = {}
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            copy[k] = self:DeepCopy(v)
        else
            copy[k] = v
        end
    end
    
    return copy
end

-- Toggle telemetry
function ErrorHandler:ToggleTelemetry(enabled)
    telemetryEnabled = enabled
    
    -- Update settings
    local settings = ConfigRegistry:GetSettings("ErrorHandler")
    settings.debugSettings.enableTelemetry = enabled
    
    return telemetryEnabled
end

-- Return the module
return ErrorHandler