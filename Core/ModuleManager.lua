------------------------------------------
-- WindrunnerRotations - Module Manager
-- Author: VortexQ8
-- The War Within Season 2
------------------------------------------

local addonName, WR = ...
local ModuleManager = {}
WR.ModuleManager = ModuleManager

-- Dependencies
local API = WR.API
local ConfigRegistry = WR.ConfigRegistry

-- Module data
local modules = {}
local loadedModules = {}
local requiredModules = {}
local moduleLoadStatus = {}
local moduleLoadOrder = {}
local dependencyGraph = {}
local moduleInitializationCount = 0
local moduleLoadEvents = {}
local moduleEnabled = {}
local CLASS_MODULES_PATH = "Classes"
local CORE_MODULES_PATH = "Core"
local TESTS_MODULES_PATH = "Tests"
local DATA_MODULES_PATH = "Data"
local UI_MODULES_PATH = "UI"
local isInitializing = false
local initializationComplete = false
local pendingModules = {}
local MAX_INITIALIZATION_ATTEMPTS = 3
local moduleErrorCount = {}
local MAX_MODULE_ERRORS = 10
local moduleCategories = {
    "CORE",
    "CLASS",
    "UI",
    "UTILITY",
    "DATA",
    "TEST"
}
local modulePriorities = {
    -- Core systems load first
    ["API"] = 1000,
    ["ConfigRegistry"] = 900,
    ["ErrorHandler"] = 800,
    ["PerformanceManager"] = 700,
    ["VersionManager"] = 600,
    ["CombatAnalysis"] = 500,
    ["MachineLearning"] = 450,
    ["KeybindManager"] = 400,
    ["AntiDetectionSystem"] = 300,
    ["PvPManager"] = 200,
    
    -- Class modules load next
    ["DeathKnight"] = 0,
    ["DemonHunter"] = 0,
    ["Druid"] = 0,
    ["Evoker"] = 0,
    ["Hunter"] = 0,
    ["Mage"] = 0,
    ["Monk"] = 0,
    ["Paladin"] = 0,
    ["Priest"] = 0,
    ["Rogue"] = 0,
    ["Shaman"] = 0,
    ["Warlock"] = 0,
    ["Warrior"] = 0,
    
    -- UI modules load late
    ["EnhancedConfigUI"] = -100,
    ["MinimapButton"] = -200,
    
    -- Other modules have middle priorities unless specified
    ["AutoTargeting"] = 100,
    ["GroupRoleManager"] = 100,
    ["TrinketManager"] = 100,
    ["CCChainAssist"] = 100,
    ["InterruptManager"] = 150,
    ["OneButtonMode"] = 150,
    ["RotationManager"] = 150,
    
    -- Testing modules load last
    ["_TEST"] = -1000
}
local moduleLoadErrors = {}
local moduleCategorizationRules = {
    -- Rules to categorize modules
    ["^Core/"] = "CORE",
    ["^Classes/"] = "CLASS",
    ["^UI/"] = "UI",
    ["^Data/"] = "DATA",
    ["^Tests/"] = "TEST",
    ["_Test$"] = "TEST",
    ["Config"] = "UI",
    ["Button$"] = "UI",
    ["Panel$"] = "UI",
    ["Frame$"] = "UI",
    ["Tooltip$"] = "UI"
}

-- Initialize ModuleManager
function ModuleManager:Initialize()
    -- Register for events
    self:RegisterEvents()
    
    -- Register settings
    self:RegisterSettings()
    
    -- Build module list
    self:BuildModuleList()
    
    -- Build dependency graph
    self:BuildDependencyGraph()
    
    -- Determine load order
    self:DetermineLoadOrder()
    
    API.PrintDebug("ModuleManager initialized")
    return true
end

-- Register events
function ModuleManager:RegisterEvents()
    -- Register for addon loaded
    API.RegisterEvent("ADDON_LOADED", function(loadedAddonName)
        if loadedAddonName == addonName then
            self:OnAddonLoaded()
        end
    end)
    
    -- Register for player entering world to initialize modules
    API.RegisterEvent("PLAYER_ENTERING_WORLD", function()
        self:InitializeModules()
    end)
    
    -- Register for player specialization changed
    API.RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", function(unit)
        if unit == "player" then
            self:OnPlayerSpecChanged()
        end
    end)
    
    -- Register for player logout to save data
    API.RegisterEvent("PLAYER_LOGOUT", function()
        self:OnPlayerLogout()
    end)
end

-- Register settings
function ModuleManager:RegisterSettings()
    -- Register settings
    ConfigRegistry:RegisterSettings("ModuleManager", {
        generalSettings = {
            enableAllModules = {
                displayName = "Enable All Modules",
                description = "Enable all modules by default",
                type = "toggle",
                default = true
            },
            autoloadClassModules = {
                displayName = "Auto-load Class Modules",
                description = "Automatically load modules for your current class",
                type = "toggle",
                default = true
            },
            enableDebugMode = {
                displayName = "Debug Mode",
                description = "Enable debug mode for additional logging",
                type = "toggle",
                default = false
            },
            maxInitializationAttempts = {
                displayName = "Max Initialization Attempts",
                description = "Maximum number of attempts to initialize modules",
                type = "slider",
                min = 1,
                max = 5,
                step = 1,
                default = 3
            }
        },
        moduleSettings = {
            -- This will be populated with module-specific settings
        }
    })
    
    -- Initially populate module settings
    for moduleName, _ in pairs(modules) do
        self:AddModuleSettings(moduleName)
    end
end

-- Add module settings
function ModuleManager:AddModuleSettings(moduleName)
    -- Don't add settings for modules that don't exist
    if not modules[moduleName] then
        return
    end
    
    -- Check if module settings already exist
    local settings = ConfigRegistry:GetSettings("ModuleManager")
    if settings.moduleSettings and settings.moduleSettings[moduleName .. "Enabled"] then
        return
    end
    
    -- Add module-specific settings
    local moduleSettings = {
        [moduleName .. "Enabled"] = {
            displayName = moduleName .. " Module",
            description = "Enable the " .. moduleName .. " module",
            type = "toggle",
            default = true
        }
    }
    
    -- Register settings (this keeps existing settings)
    local existingSettings = ConfigRegistry:GetSettings("ModuleManager")
    if existingSettings and existingSettings.moduleSettings then
        for key, value in pairs(moduleSettings) do
            existingSettings.moduleSettings[key] = value
        end
        ConfigRegistry:RegisterSettings("ModuleManager", existingSettings)
    end
end

-- Build module list
function ModuleManager:BuildModuleList()
    -- In a real addon, this would scan files
    -- Since we don't have Filesystem access in a live WoW addon, we'll hard-code modules
    
    -- Core modules (already in WR table)
    for moduleName, module in pairs(WR) do
        if type(module) == "table" and not modules[moduleName] then
            modules[moduleName] = {
                name = moduleName,
                path = "Core/" .. moduleName .. ".lua",
                category = "CORE",
                priority = modulePriorities[moduleName] or 0,
                isCore = true,
                dependencies = module.DEPENDENCIES or {},
                object = module
            }
            
            -- Mark as loaded since it's already in WR table
            loadedModules[moduleName] = true
        end
    end
    
    -- Process module paths to figure out module categories
    for moduleName, module in pairs(modules) do
        module.category = self:DetermineModuleCategory(module.path, moduleName)
    end
    
    -- Required modules
    requiredModules = {
        "API",
        "ConfigRegistry",
        "ModuleManager",
        "ErrorHandler",
        "PerformanceManager"
    }
    
    API.PrintDebug("Found " .. self:GetModuleCount() .. " modules")
end

-- Determine module category
function ModuleManager:DetermineModuleCategory(path, moduleName)
    -- Check categorization rules
    for pattern, category in pairs(moduleCategorizationRules) do
        if path:match(pattern) or moduleName:match(pattern) then
            return category
        end
    end
    
    -- Default to UTILITY
    return "UTILITY"
end

-- Build dependency graph
function ModuleManager:BuildDependencyGraph()
    dependencyGraph = {}
    
    -- Build dependency graph for each module
    for moduleName, module in pairs(modules) do
        dependencyGraph[moduleName] = {}
        
        -- Add direct dependencies
        if module.dependencies then
            for _, dependency in ipairs(module.dependencies) do
                dependencyGraph[moduleName][dependency] = true
            end
        end
        
        -- All modules implicitly depend on API and ModuleManager
        if moduleName ~= "API" then
            dependencyGraph[moduleName]["API"] = true
        end
        
        if moduleName ~= "ModuleManager" then
            dependencyGraph[moduleName]["ModuleManager"] = true
        end
        
        -- If module is registered with ConfigRegistry, add that dependency
        if moduleName ~= "ConfigRegistry" and module.object and 
           module.object.RegisterSettings and ConfigRegistry:HasSetting(moduleName, "enabled") then
            dependencyGraph[moduleName]["ConfigRegistry"] = true
        end
    end
    
    API.PrintDebug("Dependency graph built")
end

-- Determine load order
function ModuleManager:DetermineLoadOrder()
    moduleLoadOrder = {}
    local visited = {}
    local visiting = {}
    
    -- Topological sort function
    local function visit(moduleName)
        if visiting[moduleName] then
            API.PrintError("Circular dependency detected involving module: " .. moduleName)
            return false
        end
        
        if visited[moduleName] then
            return true
        end
        
        visiting[moduleName] = true
        
        if dependencyGraph[moduleName] then
            for dependency, _ in pairs(dependencyGraph[moduleName]) do
                if modules[dependency] then
                    if not visit(dependency) then
                        return false
                    end
                else
                    API.PrintDebug("Missing dependency: " .. dependency .. " for module " .. moduleName)
                end
            end
        end
        
        visiting[moduleName] = nil
        visited[moduleName] = true
        table.insert(moduleLoadOrder, moduleName)
        return true
    end
    
    -- Sort by priority to try high-priority modules first
    local sortedModuleNames = {}
    for moduleName, module in pairs(modules) do
        table.insert(sortedModuleNames, {
            name = moduleName,
            priority = module.priority or modulePriorities[moduleName] or 0
        })
    end
    
    table.sort(sortedModuleNames, function(a, b)
        return a.priority > b.priority -- Higher priority first
    end)
    
    -- Visit all modules in priority order
    for _, moduleInfo in ipairs(sortedModuleNames) do
        visit(moduleInfo.name)
    end
    
    -- Print load order
    local loadOrderString = "Module load order: "
    for i, moduleName in ipairs(moduleLoadOrder) do
        loadOrderString = loadOrderString .. moduleName
        if i < #moduleLoadOrder then
            loadOrderString = loadOrderString .. ", "
        end
    end
    API.PrintDebug(loadOrderString)
end

-- On addon loaded
function ModuleManager:OnAddonLoaded()
    -- Build module list
    self:BuildModuleList()
    
    -- Build dependency graph
    self:BuildDependencyGraph()
    
    -- Determine load order
    self:DetermineLoadOrder()
    
    -- Check module enabled states
    self:LoadModuleStates()
    
    API.PrintDebug("ModuleManager addon loaded")
}

-- On player spec changed
function ModuleManager:OnPlayerSpecChanged()
    -- Update class modules
    self:UpdateClassModules()
    
    API.PrintDebug("Updated class modules for spec change")
end

-- On player logout
function ModuleManager:OnPlayerLogout()
    -- Save module states
    self:SaveModuleStates()
    
    API.PrintDebug("Saved module states")
}

-- Load module states
function ModuleManager:LoadModuleStates()
    -- Get settings
    local settings = ConfigRegistry:GetSettings("ModuleManager")
    
    -- Default state
    local defaultEnabled = settings.generalSettings.enableAllModules
    
    -- Load module states
    for moduleName, _ in pairs(modules) do
        -- Check if module has a specific setting
        local settingName = moduleName .. "Enabled"
        if settings.moduleSettings and settings.moduleSettings[settingName] ~= nil then
            moduleEnabled[moduleName] = settings.moduleSettings[settingName]
        else
            -- Use default state
            moduleEnabled[moduleName] = defaultEnabled
            
            -- Required modules are always enabled
            if self:IsRequiredModule(moduleName) then
                moduleEnabled[moduleName] = true
            end
        end
    end
    
    API.PrintDebug("Module states loaded")
end

-- Save module states
function ModuleManager:SaveModuleStates()
    -- Get settings
    local settings = ConfigRegistry:GetSettings("ModuleManager")
    
    -- Save module states
    for moduleName, enabled in pairs(moduleEnabled) do
        -- Don't set for required modules
        if not self:IsRequiredModule(moduleName) then
            local settingName = moduleName .. "Enabled"
            if settings.moduleSettings then
                settings.moduleSettings[settingName] = enabled
            end
        end
    end
    
    -- Note: The actual save to disk is handled by ConfigRegistry
    API.PrintDebug("Module states saved to settings")
}

-- Initialize modules
function ModuleManager:InitializeModules()
    -- Skip if already initializing or complete
    if isInitializing or initializationComplete then
        return
    end
    
    isInitializing = true
    API.PrintDebug("Beginning module initialization")
    
    -- Update player info
    local playerInfo = API.GetPlayerInfo()
    
    -- Get settings
    local settings = ConfigRegistry:GetSettings("ModuleManager")
    
    -- Update class modules based on current class
    if settings.generalSettings.autoloadClassModules then
        self:UpdateClassModules()
    end
    
    -- Initialize modules in load order
    for _, moduleName in ipairs(moduleLoadOrder) do
        self:InitializeModule(moduleName)
    end
    
    -- Process any pending modules
    self:ProcessPendingModules()
    
    isInitializing = false
    initializationComplete = true
    
    API.PrintDebug("Module initialization completed")
    
    -- Trigger load events
    self:TriggerModuleLoadEvents("ALL")
end

-- Initialize module
function ModuleManager:InitializeModule(moduleName)
    -- Skip if already loaded
    if moduleLoadStatus[moduleName] == "loaded" then
        return true
    end
    
    -- Skip if disabled
    if not moduleEnabled[moduleName] then
        moduleLoadStatus[moduleName] = "disabled"
        API.PrintDebug("Module " .. moduleName .. " is disabled, skipping")
        return false
    end
    
    -- Check dependencies
    if not self:CheckDependencies(moduleName) then
        -- Queue for later initialization
        pendingModules[moduleName] = (pendingModules[moduleName] or 0) + 1
        
        if pendingModules[moduleName] > MAX_INITIALIZATION_ATTEMPTS then
            moduleLoadStatus[moduleName] = "failed"
            moduleLoadErrors[moduleName] = "Failed to load dependencies after " .. MAX_INITIALIZATION_ATTEMPTS .. " attempts"
            API.PrintError("Failed to load module " .. moduleName .. " after " .. MAX_INITIALIZATION_ATTEMPTS .. " attempts.")
            return false
        end
        
        API.PrintDebug("Module " .. moduleName .. " waiting for dependencies, attempt " .. pendingModules[moduleName])
        return false
    end
    
    -- Get module
    local module = self:GetModule(moduleName)
    if not module then
        moduleLoadStatus[moduleName] = "missing"
        moduleLoadErrors[moduleName] = "Module object not found"
        API.PrintError("Module " .. moduleName .. " not found.")
        return false
    end
    
    -- Initialize module
    local success = false
    
    -- Use pcall to catch errors
    if module.object and module.object.Initialize then
        -- Try to initialize
        local status, result = pcall(function()
            return module.object:Initialize()
        end)
        
        if not status then
            -- Initialization failed with error
            moduleLoadStatus[moduleName] = "error"
            moduleLoadErrors[moduleName] = result
            moduleErrorCount[moduleName] = (moduleErrorCount[moduleName] or 0) + 1
            
            -- If too many errors, disable module
            if moduleErrorCount[moduleName] >= MAX_MODULE_ERRORS then
                moduleEnabled[moduleName] = false
                API.PrintError("Module " .. moduleName .. " disabled due to too many errors.")
            end
            
            API.PrintError("Error initializing module " .. moduleName .. ": " .. tostring(result))
            return false
        else
            -- Check initialization result
            if result == true then
                success = true
            else
                moduleLoadStatus[moduleName] = "failed"
                moduleLoadErrors[moduleName] = "Module returned false from Initialize"
                API.PrintError("Module " .. moduleName .. " initialization returned false.")
                return false
            end
        end
    else
        -- Module doesn't have Initialize method, just mark as loaded
        success = true
    end
    
    if success then
        moduleLoadStatus[moduleName] = "loaded"
        loadedModules[moduleName] = true
        
        -- Trigger load events
        self:TriggerModuleLoadEvents(moduleName)
        
        API.PrintDebug("Module " .. moduleName .. " initialized successfully")
    end
    
    return success
end

-- Process pending modules
function ModuleManager:ProcessPendingModules()
    -- Try to initialize pending modules
    local pendingCount = 0
    for moduleName, attempts in pairs(pendingModules) do
        if moduleLoadStatus[moduleName] ~= "loaded" and moduleLoadStatus[moduleName] ~= "failed" then
            self:InitializeModule(moduleName)
            pendingCount = pendingCount + 1
        end
    end
    
    -- If we still have pending modules and haven't hit the retry limit, schedule another attempt
    if pendingCount > 0 then
        C_Timer.After(0.5, function()
            self:ProcessPendingModules()
        end)
    end
}

-- Check dependencies
function ModuleManager:CheckDependencies(moduleName)
    -- Check if all dependencies are loaded
    if not dependencyGraph[moduleName] then
        return true
    end
    
    for dependency, _ in pairs(dependencyGraph[moduleName]) do
        if not loadedModules[dependency] then
            API.PrintDebug("Module " .. moduleName .. " waiting for dependency: " .. dependency)
            return false
        end
    end
    
    return true
end

-- Update class modules
function ModuleManager:UpdateClassModules()
    -- Get player class
    local playerInfo = API.GetPlayerInfo()
    local playerClass = playerInfo.class
    
    if not playerClass then
        return
    end
    
    -- Enable modules for current class
    for moduleName, module in pairs(modules) do
        if module.category == "CLASS" then
            -- Check if this is for the current class
            if moduleName == playerClass or moduleName:match("^" .. playerClass) then
                moduleEnabled[moduleName] = true
            else
                -- Disable other class modules
                moduleEnabled[moduleName] = false
            end
        end
    end
    
    API.PrintDebug("Updated class modules for " .. playerClass)
}

-- Register module load event
function ModuleManager:RegisterModuleLoadEvent(moduleName, callback)
    if not moduleLoadEvents[moduleName] then
        moduleLoadEvents[moduleName] = {}
    end
    
    table.insert(moduleLoadEvents[moduleName], callback)
    
    -- If module is already loaded, trigger callback immediately
    if loadedModules[moduleName] then
        callback(modules[moduleName].object)
    end
    
    return #moduleLoadEvents[moduleName]
}

-- Trigger module load events
function ModuleManager:TriggerModuleLoadEvents(moduleName)
    -- Trigger specific module events
    if moduleLoadEvents[moduleName] then
        for _, callback in ipairs(moduleLoadEvents[moduleName]) do
            if type(callback) == "function" then
                pcall(callback, modules[moduleName].object)
            end
        end
    end
    
    -- Trigger "ALL" events if a specific module was loaded
    if moduleName ~= "ALL" and moduleLoadEvents["ALL"] then
        for _, callback in ipairs(moduleLoadEvents["ALL"]) do
            if type(callback) == "function" then
                pcall(callback, moduleName, modules[moduleName].object)
            end
        end
    end
}

-- Get module
function ModuleManager:GetModule(moduleName)
    return modules[moduleName]
end

-- Get module count
function ModuleManager:GetModuleCount()
    local count = 0
    for _ in pairs(modules) do
        count = count + 1
    end
    return count
end

-- Get loaded module count
function ModuleManager:GetLoadedModuleCount()
    local count = 0
    for _ in pairs(loadedModules) do
        count = count + 1
    end
    return count
end

-- Get modules by category
function ModuleManager:GetModulesByCategory(category)
    local result = {}
    
    for moduleName, module in pairs(modules) do
        if module.category == category then
            table.insert(result, moduleName)
        end
    end
    
    return result
end

-- Is module loaded
function ModuleManager:IsModuleLoaded(moduleName)
    return loadedModules[moduleName] or false
end

-- Is module enabled
function ModuleManager:IsModuleEnabled(moduleName)
    return moduleEnabled[moduleName] or false
end

-- Enable module
function ModuleManager:EnableModule(moduleName)
    -- Skip if already enabled
    if moduleEnabled[moduleName] then
        return true
    end
    
    moduleEnabled[moduleName] = true
    
    -- If we're already initialized, try to initialize this module now
    if initializationComplete then
        local result = self:InitializeModule(moduleName)
        
        -- Save the state change
        self:SaveModuleStates()
        
        return result
    else
        return true
    end
end

-- Disable module
function ModuleManager:DisableModule(moduleName)
    -- Can't disable required modules
    if self:IsRequiredModule(moduleName) then
        API.PrintError("Cannot disable required module: " .. moduleName)
        return false
    end
    
    moduleEnabled[moduleName] = false
    
    -- If module has Disable method, call it
    local module = self:GetModule(moduleName)
    if module and module.object and module.object.Disable then
        pcall(function() module.object:Disable() end)
    end
    
    -- Update load status
    moduleLoadStatus[moduleName] = "disabled"
    
    -- Save the state change
    self:SaveModuleStates()
    
    return true
end

-- Is required module
function ModuleManager:IsRequiredModule(moduleName)
    for _, required in ipairs(requiredModules) do
        if required == moduleName then
            return true
        end
    end
    
    return false
end

-- Get module load status
function ModuleManager:GetModuleLoadStatus(moduleName)
    return moduleLoadStatus[moduleName] or "unknown"
end

-- Get module load error
function ModuleManager:GetModuleLoadError(moduleName)
    return moduleLoadErrors[moduleName]
end

-- Get all module statuses
function ModuleManager:GetAllModuleStatuses()
    local statuses = {}
    
    for moduleName, _ in pairs(modules) do
        statuses[moduleName] = {
            status = self:GetModuleLoadStatus(moduleName),
            enabled = self:IsModuleEnabled(moduleName),
            error = self:GetModuleLoadError(moduleName),
            required = self:IsRequiredModule(moduleName),
            category = modules[moduleName].category
        }
    end
    
    return statuses
end

-- Get module categories
function ModuleManager:GetModuleCategories()
    return moduleCategories
end

-- Reset
function ModuleManager:Reset()
    -- Reset modules that have a Reset method
    for moduleName, loaded in pairs(loadedModules) do
        if loaded then
            local module = self:GetModule(moduleName)
            if module and module.object and module.object.Reset then
                pcall(function() module.object:Reset() end)
            end
        end
    end
    
    return true
end

-- Register for export
WR.ModuleManager = ModuleManager

return ModuleManager