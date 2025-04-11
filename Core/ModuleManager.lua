------------------------------------------
-- WindrunnerRotations - Module Manager
-- Author: VortexQ8
-- Handles class/spec module registration and loading
------------------------------------------

local addonName, addon = ...
addon.Core = addon.Core or {}
addon.Core.ModuleManager = {}

local ModuleManager = addon.Core.ModuleManager
local API = addon.API
local loadedModules = {}
local availableClasses = {}
local activeClass = nil
local classModulesRegistered = false

-- Initialize the module system
function ModuleManager:Initialize()
    -- Create global container for class modules
    addon.Classes = addon.Classes or {}
    
    -- Register events for module management
    API.RegisterEvent("PLAYER_ENTERING_WORLD", function() 
        self:InitializePlayerClass()
    end)
    
    API.RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", function()
        self:OnSpecializationChanged()
    end)
    
    -- Signal initialization complete
    API.PrintDebug("Module Manager initialized")
    
    return true
end

-- Register a class module
function ModuleManager:RegisterClass(className, classModule)
    if not className or not classModule then
        API.PrintError("Invalid class registration")
        return false
    end
    
    -- Store the class in available classes table
    availableClasses[className] = classModule
    API.PrintDebug("Registered class module: " .. className)
    
    -- Mark that at least one class has been registered
    classModulesRegistered = true
    
    return true
end

-- Initialize player's class module
function ModuleManager:InitializePlayerClass()
    if not classModulesRegistered then
        -- No classes have been registered yet, likely still loading
        API.PrintDebug("No class modules registered yet, will retry initialization")
        C_Timer.After(2, function() self:InitializePlayerClass() end)
        return false
    end
    
    -- Get player's class
    local playerClass = API.GetPlayerClass()
    local className = select(2, GetClassInfo(playerClass))
    
    if not className then
        API.PrintError("Unable to determine player class")
        return false
    end
    
    -- Check if this class is supported
    if not availableClasses[className] then
        API.PrintDebug("Class not supported: " .. className)
        return false
    end
    
    -- Load the class module
    activeClass = availableClasses[className]
    
    -- Initialize the class module
    if activeClass and activeClass.Initialize then
        local success, errorMsg = pcall(function()
            activeClass:Initialize()
        end)
        
        if not success then
            API.PrintError("Failed to initialize class module: " .. tostring(errorMsg))
            return false
        end
        
        API.PrintDebug("Successfully initialized class module: " .. className)
    else
        API.PrintError("Invalid class module structure")
        return false
    end
    
    return true
end

-- Handle specialization changes
function ModuleManager:OnSpecializationChanged()
    if activeClass and activeClass.OnSpecializationChanged then
        activeClass:OnSpecializationChanged()
    end
end

-- Load a module by path
function ModuleManager:RequireModule(modulePath)
    -- Check if already loaded
    if loadedModules[modulePath] then
        return loadedModules[modulePath]
    end
    
    -- Attempt to load the module
    local success, module = pcall(function()
        local module = {}
        local path = modulePath:gsub("%.", "/")
        local file = "Interface/AddOns/" .. addonName .. "/" .. path .. ".lua"
        
        -- Attempt to execute the file in the context of the module
        local chunk, err = loadfile(file)
        if chunk then
            setfenv(chunk, setmetatable({}, {
                __index = function(t, k)
                    if k == "addon" then
                        return addon
                    elseif k == "self" then
                        return module
                    else
                        return _G[k]
                    end
                end
            }))
            chunk()
        else
            error("Error loading module: " .. tostring(err))
        end
        
        return module
    end)
    
    if success then
        loadedModules[modulePath] = module
        API.PrintDebug("Loaded module: " .. modulePath)
        return module
    else
        API.PrintError("Failed to load module " .. modulePath .. ": " .. tostring(module))
        return nil
    end
end

-- Get the active class module
function ModuleManager:GetActiveClass()
    return activeClass
end

-- Run the rotation for the current class/spec
function ModuleManager:RunRotation()
    if activeClass and activeClass.RunRotation then
        return activeClass:RunRotation()
    end
    return false
end

-- Hook up the require function to the addon
addon.RequireModule = function(self, modulePath)
    return ModuleManager:RequireModule(modulePath)
end

-- Register the class function to the addon
addon.RegisterClass = function(self, className, classModule)
    return ModuleManager:RegisterClass(className, classModule)
end

-- Export the module
return ModuleManager