------------------------------------------
-- WindrunnerRotations - Configuration Registry
-- Author: VortexQ8
-- Centralized settings management system
------------------------------------------

local addonName, addon = ...
addon.Core = addon.Core or {}
addon.Core.ConfigRegistry = {}

local ConfigRegistry = addon.Core.ConfigRegistry
local API = addon.API
local registeredSettings = {}
local savedVariables = {}
local defaultPresets = {}

-- Get settings for a module
function ConfigRegistry:GetSettings(moduleName)
    if not moduleName or not registeredSettings[moduleName] then
        API.PrintError("Attempted to access nonexistent settings module: " .. tostring(moduleName))
        return {}
    end
    
    -- Initialize this module in savedVariables if it doesn't exist
    if not savedVariables[moduleName] then
        savedVariables[moduleName] = {}
    end
    
    -- Create a combined settings table with defaults for missing values
    local combinedSettings = {}
    
    for categoryName, categorySettings in pairs(registeredSettings[moduleName]) do
        combinedSettings[categoryName] = combinedSettings[categoryName] or {}
        
        for settingName, settingInfo in pairs(categorySettings) do
            -- Get the value from saved variables or use default
            if savedVariables[moduleName][categoryName] and
               savedVariables[moduleName][categoryName][settingName] ~= nil then
                combinedSettings[categoryName][settingName] = savedVariables[moduleName][categoryName][settingName]
            else
                combinedSettings[categoryName][settingName] = settingInfo.default
            end
        end
    end
    
    return combinedSettings
end

-- Register settings for a module
function ConfigRegistry:RegisterSettings(moduleName, settingsTable)
    if not moduleName or not settingsTable then
        API.PrintError("Invalid settings registration")
        return false
    end
    
    -- Store the settings schema
    registeredSettings[moduleName] = settingsTable
    
    -- Initialize saved variables for this module
    if not savedVariables[moduleName] then
        savedVariables[moduleName] = {}
    end
    
    API.PrintDebug("Registered settings for module: " .. moduleName)
    return true
end

-- Update a setting value
function ConfigRegistry:UpdateSetting(moduleName, categoryName, settingName, value)
    if not moduleName or not categoryName or not settingName then
        API.PrintError("Invalid setting update parameters")
        return false
    end
    
    -- Check if module exists
    if not registeredSettings[moduleName] then
        API.PrintError("Attempted to update setting for nonexistent module: " .. tostring(moduleName))
        return false
    end
    
    -- Check if category exists
    if not registeredSettings[moduleName][categoryName] then
        API.PrintError("Attempted to update setting for nonexistent category: " .. tostring(categoryName))
        return false
    end
    
    -- Check if setting exists
    if not registeredSettings[moduleName][categoryName][settingName] then
        API.PrintError("Attempted to update nonexistent setting: " .. tostring(settingName))
        return false
    end
    
    -- Initialize category in saved variables if needed
    if not savedVariables[moduleName][categoryName] then
        savedVariables[moduleName][categoryName] = {}
    end
    
    -- Update the setting
    savedVariables[moduleName][categoryName][settingName] = value
    
    API.PrintDebug("Updated setting: " .. moduleName .. "." .. categoryName .. "." .. settingName .. " = " .. tostring(value))
    return true
end

-- Reset a module's settings to defaults
function ConfigRegistry:ResetModuleToDefaults(moduleName)
    if not moduleName or not registeredSettings[moduleName] then
        API.PrintError("Attempted to reset nonexistent module: " .. tostring(moduleName))
        return false
    end
    
    -- Clear saved variables for this module
    savedVariables[moduleName] = {}
    
    API.PrintDebug("Reset module to defaults: " .. moduleName)
    return true
end

-- Register a preset
function ConfigRegistry:RegisterPreset(presetName, moduleName, presetData)
    if not presetName or not moduleName or not presetData then
        API.PrintError("Invalid preset registration")
        return false
    end
    
    -- Initialize presets for this module if needed
    if not defaultPresets[moduleName] then
        defaultPresets[moduleName] = {}
    end
    
    -- Store the preset
    defaultPresets[moduleName][presetName] = presetData
    
    API.PrintDebug("Registered preset: " .. presetName .. " for module: " .. moduleName)
    return true
end

-- Apply a preset
function ConfigRegistry:ApplyPreset(presetName, moduleName)
    if not presetName or not moduleName then
        API.PrintError("Invalid preset application parameters")
        return false
    end
    
    -- Check if module exists
    if not registeredSettings[moduleName] then
        API.PrintError("Attempted to apply preset to nonexistent module: " .. tostring(moduleName))
        return false
    end
    
    -- Check if preset exists
    if not defaultPresets[moduleName] or not defaultPresets[moduleName][presetName] then
        API.PrintError("Attempted to apply nonexistent preset: " .. tostring(presetName))
        return false
    end
    
    -- Apply the preset
    local presetData = defaultPresets[moduleName][presetName]
    
    for categoryName, categorySettings in pairs(presetData) do
        for settingName, value in pairs(categorySettings) do
            self:UpdateSetting(moduleName, categoryName, settingName, value)
        end
    end
    
    API.PrintDebug("Applied preset: " .. presetName .. " to module: " .. moduleName)
    return true
end

-- Save settings to disk
function ConfigRegistry:SaveSettings()
    -- In a real implementation, this would save to WoW's saved variables
    WindrunnerRotationsDB = savedVariables
    API.PrintDebug("Settings saved to disk")
    return true
end

-- Load settings from disk
function ConfigRegistry:LoadSettings()
    -- In a real implementation, this would load from WoW's saved variables
    if WindrunnerRotationsDB then
        savedVariables = WindrunnerRotationsDB
        API.PrintDebug("Settings loaded from disk")
    else
        API.PrintDebug("No saved settings found, using defaults")
    end
    return true
end

-- Export settings as string
function ConfigRegistry:ExportSettings(moduleName)
    if not moduleName or not savedVariables[moduleName] then
        API.PrintError("Attempted to export nonexistent module: " .. tostring(moduleName))
        return nil
    end
    
    -- Serialize the settings
    local serialized = "WindrunnerRotations:" .. moduleName .. ":"
    
    -- In a real implementation, this would use proper serialization
    -- For now, just a simple placeholder
    serialized = serialized .. "SettingsData"
    
    return serialized
end

-- Import settings from string
function ConfigRegistry:ImportSettings(importString)
    if not importString or type(importString) ~= "string" then
        API.PrintError("Invalid import string")
        return false
    end
    
    -- Parse the import string
    local prefix, moduleName, data = importString:match("^(WindrunnerRotations):([^:]+):(.+)$")
    
    if not prefix or not moduleName or not data then
        API.PrintError("Invalid import string format")
        return false
    end
    
    -- Check if module exists
    if not registeredSettings[moduleName] then
        API.PrintError("Attempted to import settings for nonexistent module: " .. moduleName)
        return false
    end
    
    -- In a real implementation, this would parse the data into settings
    -- For now, just a placeholder
    API.PrintDebug("Imported settings for module: " .. moduleName)
    
    return true
end

-- Initialize the ConfigRegistry
function ConfigRegistry:Initialize()
    -- Load settings from disk
    self:LoadSettings()
    
    -- Register for PLAYER_LOGOUT to save settings
    API.RegisterEvent("PLAYER_LOGOUT", function()
        self:SaveSettings()
    end)
    
    API.PrintDebug("ConfigRegistry initialized")
    
    return true
end

-- Export the ConfigRegistry module
return ConfigRegistry