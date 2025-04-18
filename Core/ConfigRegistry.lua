------------------------------------------
-- WindrunnerRotations - Config Registry
-- Author: VortexQ8
-- The War Within Season 2
------------------------------------------

local addonName, WR = ...
local ConfigRegistry = {}
WR.ConfigRegistry = ConfigRegistry

-- Local variables
local settingsRegistry = {}
local defaultSettings = {}
local characterSettings = {}
local profileSettings = {}
local activeProfile = "Default"
local globalProfiles = {}
local savedVariablesLoaded = false
local pendingSettings = {}
local configCallbacks = {}
local configValidators = {}
local MAX_PROFILES = 10
local settingsVersion = 1
local isDirty = false
local lastSaveTime = 0
local saveInterval = 5 -- Save settings every 5 seconds if dirty
local configOptionDefaults = {
    type = "string",
    default = "",
    min = nil,
    max = nil,
    step = nil,
    options = nil,
    dependsOn = nil,
    description = "",
    displayName = "",
    isAdvanced = false,
    isHidden = false,
    category = "General",
    order = 100,
    width = "full",
    validate = nil
}
local SAVED_VARIABLES_NAME = "WindrunnerRotationsDB"
local GLOBAL_SAVED_VARIABLES_NAME = "WindrunnerRotationsGlobalDB"
local savedVariablesRegistered = false

-- Initialize ConfigRegistry
function ConfigRegistry:Initialize()
    -- Register events for saved variables loading
    self:RegisterEvents()
    
    -- Initialize empty settings
    self:InitializeDefaultSettings()
    
    -- Set up config option validation
    self:SetupValidation()
    
    -- Create config frame for periodic saving
    self:CreateConfigFrame()
    
    WR.API.PrintDebug("ConfigRegistry initialized")
    return true
end

-- Register events for saved variables loading
function ConfigRegistry:RegisterEvents()
    -- Register for ADDON_LOADED event
    WR.API.RegisterEvent("ADDON_LOADED", function(loadedAddonName)
        if loadedAddonName == addonName then
            self:OnAddonLoaded()
        end
    end)
    
    -- Register for PLAYER_LOGOUT event
    WR.API.RegisterEvent("PLAYER_LOGOUT", function()
        self:SaveSettings()
    end)
    
    -- Register for PLAYER_ENTERING_WORLD event to finalize loading
    WR.API.RegisterEvent("PLAYER_ENTERING_WORLD", function()
        self:FinalizeSettingsLoading()
    end)
end

-- Initialize default settings
function ConfigRegistry:InitializeDefaultSettings()
    -- Initialize the settings for empty defaults
    characterSettings = {}
    defaultSettings = {}
    profileSettings = {}
end

-- Setup validation
function ConfigRegistry:SetupValidation()
    -- Set up validators for different setting types
    configValidators = {
        string = function(value, option)
            -- String validation
            if type(value) ~= "string" then
                return false, "Value must be a string"
            end
            return true, nil
        end,
        number = function(value, option)
            -- Number validation with min/max
            if type(value) ~= "number" then
                return false, "Value must be a number"
            end
            if option.min and value < option.min then
                return false, "Value must be at least " .. option.min
            end
            if option.max and value > option.max then
                return false, "Value must not exceed " .. option.max
            end
            return true, nil
        end,
        boolean = function(value, option)
            -- Boolean validation
            if type(value) ~= "boolean" then
                return false, "Value must be true or false"
            end
            return true, nil
        end,
        toggle = function(value, option)
            -- Toggle validation (same as boolean)
            if type(value) ~= "boolean" then
                return false, "Value must be true or false"
            end
            return true, nil
        end,
        slider = function(value, option)
            -- Slider validation (same as number with min/max)
            if type(value) ~= "number" then
                return false, "Value must be a number"
            end
            if option.min and value < option.min then
                return false, "Value must be at least " .. option.min
            end
            if option.max and value > option.max then
                return false, "Value must not exceed " .. option.max
            end
            return true, nil
        end,
        dropdown = function(value, option)
            -- Dropdown validation (value must be in options)
            if not option.options then
                return true, nil -- No options to validate against
            end
            for _, opt in ipairs(option.options) do
                if opt == value then
                    return true, nil
                end
            end
            return false, "Value must be one of the available options"
        end,
        color = function(value, option)
            -- Color validation
            if type(value) ~= "table" then
                return false, "Color must be a table"
            end
            if value.r == nil or value.g == nil or value.b == nil then
                return false, "Color must have r, g, and b components"
            end
            if type(value.r) ~= "number" or type(value.g) ~= "number" or type(value.b) ~= "number" then
                return false, "Color components must be numbers"
            end
            return true, nil
        end,
        multiselect = function(value, option)
            -- Multiselect validation
            if type(value) ~= "table" then
                return false, "Value must be a table"
            end
            return true, nil
        end,
        header = function(value, option)
            -- Headers don't have values to validate
            return true, nil
        end,
        description = function(value, option)
            -- Descriptions don't have values to validate
            return true, nil
        end
    }
}

-- Create config frame for periodic saving
function ConfigRegistry:CreateConfigFrame()
    -- Create a frame for periodic saving
    local frame = CreateFrame("Frame", "WindrunnerRotationsConfigFrame")
    frame:Hide()
    
    -- Set up OnUpdate handler
    local lastUpdate = 0
    frame:SetScript("OnUpdate", function(self, elapsed)
        lastUpdate = lastUpdate + elapsed
        
        -- Only save periodically
        if lastUpdate >= saveInterval then
            lastUpdate = 0
            
            -- Check if settings are dirty
            if isDirty and GetTime() - lastSaveTime > saveInterval then
                ConfigRegistry:SaveSettings()
                isDirty = false
                lastSaveTime = GetTime()
            end
        end
    end)
    
    -- Show the frame to enable updates
    frame:Show()
end

-- On addon loaded event
function ConfigRegistry:OnAddonLoaded()
    -- Load saved variables
    self:LoadSavedVariables()
    
    -- Mark as loaded
    savedVariablesLoaded = true
    
    -- Register addon for saved variables if not already done
    if not savedVariablesRegistered then
        -- This is normally done in the TOC file
        -- Here we're simulating that the saved variables are registered
        _G[SAVED_VARIABLES_NAME] = _G[SAVED_VARIABLES_NAME] or {}
        _G[GLOBAL_SAVED_VARIABLES_NAME] = _G[GLOBAL_SAVED_VARIABLES_NAME] or {}
        savedVariablesRegistered = true
    end
    
    -- Apply any pending settings
    self:ApplyPendingSettings()
}

-- Finalize settings loading
function ConfigRegistry:FinalizeSettingsLoading()
    -- Final processing after all settings are loaded
    
    -- Trigger callbacks for initial values
    for module, _ in pairs(settingsRegistry) do
        self:TriggerCallbacks(module)
    end
    
    WR.API.PrintDebug("Settings finalized")
}

-- Load saved variables
function ConfigRegistry:LoadSavedVariables()
    -- Get saved variables
    local savedVars = _G[SAVED_VARIABLES_NAME] or {}
    local globalSavedVars = _G[GLOBAL_SAVED_VARIABLES_NAME] or {}
    
    -- Load character-specific settings
    characterSettings = savedVars.characterSettings or {}
    
    -- Load global profiles
    globalProfiles = globalSavedVars.profiles or {}
    
    -- Load active profile
    activeProfile = savedVars.activeProfile or "Default"
    
    -- Create default profile if it doesn't exist
    if not globalProfiles[activeProfile] then
        globalProfiles[activeProfile] = {}
    end
    
    -- Load profile settings
    profileSettings = globalProfiles[activeProfile] or {}
    
    -- Version check
    local savedVersion = globalSavedVars.version or 0
    if savedVersion < settingsVersion then
        self:MigrateSettings(savedVersion, settingsVersion)
    end
    
    WR.API.PrintDebug("Saved variables loaded, active profile: " .. activeProfile)
end

-- Save settings
function ConfigRegistry:SaveSettings()
    if not savedVariablesLoaded then
        -- Queue settings to be saved when variables are loaded
        isDirty = true
        return
    end
    
    -- Prepare saved variables structure
    local savedVars = _G[SAVED_VARIABLES_NAME] or {}
    local globalSavedVars = _G[GLOBAL_SAVED_VARIABLES_NAME] or {}
    
    -- Update character settings
    savedVars.characterSettings = characterSettings
    savedVars.activeProfile = activeProfile
    
    -- Update global profiles
    globalProfiles[activeProfile] = profileSettings
    globalSavedVars.profiles = globalProfiles
    globalSavedVars.version = settingsVersion
    
    -- Save back to global variables
    _G[SAVED_VARIABLES_NAME] = savedVars
    _G[GLOBAL_SAVED_VARIABLES_NAME] = globalSavedVars
    
    WR.API.PrintDebug("Settings saved")
    lastSaveTime = GetTime()
    isDirty = false
end

-- Apply pending settings
function ConfigRegistry:ApplyPendingSettings()
    -- Process any settings that were registered before saved variables loaded
    for module, options in pairs(pendingSettings) do
        self:RegisterModuleSettings(module, options)
    end
    
    -- Clear pending settings
    pendingSettings = {}
}

-- Register settings for a module
function ConfigRegistry:RegisterSettings(module, options)
    -- If saved variables aren't loaded yet, queue for later
    if not savedVariablesLoaded then
        pendingSettings[module] = options
        return
    end
    
    -- Register the module's settings
    return self:RegisterModuleSettings(module, options)
end

-- Register module settings
function ConfigRegistry:RegisterModuleSettings(module, options)
    -- Store the settings registry
    settingsRegistry[module] = options
    
    -- Initialize default settings for this module
    defaultSettings[module] = {}
    
    -- Initialize profile settings for this module if it doesn't exist
    if not profileSettings[module] then
        profileSettings[module] = {}
    end
    
    -- Initialize character settings for this module if it doesn't exist
    if not characterSettings[module] then
        characterSettings[module] = {}
    end
    
    -- Process and validate all options
    for category, categoryOptions in pairs(options) do
        for optionName, optionSettings in pairs(categoryOptions) do
            -- Set up default values
            self:SetupDefaultValues(module, category, optionName, optionSettings)
        end
    end
    
    -- Mark settings as dirty so they will be saved
    isDirty = true
    
    WR.API.PrintDebug("Settings registered for module: " .. module)
    return true
end

-- Setup default values
function ConfigRegistry:SetupDefaultValues(module, category, optionName, optionSettings)
    -- Merge with defaults
    for key, defaultValue in pairs(configOptionDefaults) do
        if optionSettings[key] == nil then
            optionSettings[key] = defaultValue
        end
    end
    
    -- Store the default value
    defaultSettings[module][optionName] = optionSettings.default
    
    -- If the setting doesn't exist in the profile, initialize it
    if profileSettings[module][optionName] == nil then
        profileSettings[module][optionName] = optionSettings.default
    end
    
    -- Validate the current value
    local valid, errorMsg = self:ValidateValue(profileSettings[module][optionName], optionSettings)
    if not valid then
        -- If invalid, reset to default
        WR.API.PrintDebug("Invalid setting value for " .. module .. "." .. optionName .. ": " .. errorMsg)
        profileSettings[module][optionName] = optionSettings.default
    end
}

-- Validate a value against option settings
function ConfigRegistry:ValidateValue(value, optionSettings)
    -- Get the validator for this type
    local validator = configValidators[optionSettings.type]
    if not validator then
        -- No validator for this type, assume valid
        return true, nil
    end
    
    -- Run the validator
    return validator(value, optionSettings)
end

-- Get settings for a module
function ConfigRegistry:GetSettings(module)
    if not profileSettings[module] then
        return {}
    end
    
    return profileSettings[module]
end

-- Get a specific setting
function ConfigRegistry:GetSetting(module, setting)
    if not profileSettings[module] then
        return nil
    end
    
    return profileSettings[module][setting]
end

-- Set a specific setting
function ConfigRegistry:SetSetting(module, setting, value)
    -- Ensure module settings exist
    if not profileSettings[module] then
        profileSettings[module] = {}
    end
    
    -- Validate the value if we have option settings
    if settingsRegistry[module] then
        -- Find the option settings for this setting
        local optionSettings
        for category, categoryOptions in pairs(settingsRegistry[module]) do
            if categoryOptions[setting] then
                optionSettings = categoryOptions[setting]
                break
            end
        end
        
        if optionSettings then
            local valid, errorMsg = self:ValidateValue(value, optionSettings)
            if not valid then
                WR.API.PrintMessage("Invalid setting value for " .. module .. "." .. setting .. ": " .. errorMsg)
                return false
            end
        end
    end
    
    -- Set the value
    local oldValue = profileSettings[module][setting]
    profileSettings[module][setting] = value
    
    -- Mark settings as dirty
    isDirty = true
    
    -- Trigger callbacks if value changed
    if oldValue ~= value then
        self:TriggerCallbacks(module)
    end
    
    return true
end

-- Get all settings
function ConfigRegistry:GetAllSettings()
    return profileSettings
end

-- Reset settings for a module
function ConfigRegistry:ResetSettings(module)
    if not defaultSettings[module] then
        return false
    end
    
    -- Reset to defaults
    profileSettings[module] = {}
    for setting, defaultValue in pairs(defaultSettings[module]) do
        profileSettings[module][setting] = defaultValue
    end
    
    -- Mark settings as dirty
    isDirty = true
    
    -- Trigger callbacks
    self:TriggerCallbacks(module)
    
    return true
end

-- Register a callback for settings changes
function ConfigRegistry:RegisterCallback(module, callback)
    if not configCallbacks[module] then
        configCallbacks[module] = {}
    end
    
    table.insert(configCallbacks[module], callback)
    return #configCallbacks[module]
end

-- Unregister a callback
function ConfigRegistry:UnregisterCallback(module, callbackID)
    if not configCallbacks[module] then
        return false
    end
    
    configCallbacks[module][callbackID] = nil
    return true
end

-- Trigger callbacks for a module
function ConfigRegistry:TriggerCallbacks(module)
    if not configCallbacks[module] then
        return
    end
    
    local settings = self:GetSettings(module)
    for _, callback in pairs(configCallbacks[module]) do
        if type(callback) == "function" then
            pcall(callback, settings)
        end
    end
end

-- Get profiles list
function ConfigRegistry:GetProfiles()
    local profiles = {}
    for profileName, _ in pairs(globalProfiles) do
        table.insert(profiles, profileName)
    end
    return profiles
end

-- Get active profile
function ConfigRegistry:GetActiveProfile()
    return activeProfile
end

-- Set active profile
function ConfigRegistry:SetActiveProfile(profileName)
    -- Check if profile exists
    if not globalProfiles[profileName] then
        -- Create new profile
        globalProfiles[profileName] = {}
    end
    
    -- Save current settings
    globalProfiles[activeProfile] = profileSettings
    
    -- Switch profile
    activeProfile = profileName
    profileSettings = globalProfiles[profileName]
    
    -- Fill in any missing settings with defaults
    for module, defaults in pairs(defaultSettings) do
        if not profileSettings[module] then
            profileSettings[module] = {}
        end
        
        for setting, defaultValue in pairs(defaults) do
            if profileSettings[module][setting] == nil then
                profileSettings[module][setting] = defaultValue
            end
        end
    end
    
    -- Mark settings as dirty
    isDirty = true
    
    -- Trigger callbacks for all modules
    for module, _ in pairs(settingsRegistry) do
        self:TriggerCallbacks(module)
    end
    
    return true
end

-- Create a new profile
function ConfigRegistry:CreateProfile(profileName)
    -- Check if profile already exists
    if globalProfiles[profileName] then
        return false
    end
    
    -- Check if we have too many profiles
    local profileCount = 0
    for _ in pairs(globalProfiles) do
        profileCount = profileCount + 1
    end
    
    if profileCount >= MAX_PROFILES then
        return false
    end
    
    -- Create new profile
    globalProfiles[profileName] = {}
    
    -- Initialize with defaults
    for module, defaults in pairs(defaultSettings) do
        globalProfiles[profileName][module] = {}
        for setting, defaultValue in pairs(defaults) do
            globalProfiles[profileName][module][setting] = defaultValue
        end
    end
    
    -- Mark settings as dirty
    isDirty = true
    
    return true
end

-- Delete a profile
function ConfigRegistry:DeleteProfile(profileName)
    -- Don't allow deleting the active profile
    if profileName == activeProfile then
        return false
    end
    
    -- Don't allow deleting the default profile
    if profileName == "Default" then
        return false
    end
    
    -- Remove the profile
    globalProfiles[profileName] = nil
    
    -- Mark settings as dirty
    isDirty = true
    
    return true
end

-- Copy profile
function ConfigRegistry:CopyProfile(sourceProfile, targetProfile)
    -- Check if source profile exists
    if not globalProfiles[sourceProfile] then
        return false
    end
    
    -- Create new target profile if it doesn't exist
    if not globalProfiles[targetProfile] then
        self:CreateProfile(targetProfile)
    end
    
    -- Copy settings
    for module, settings in pairs(globalProfiles[sourceProfile]) do
        globalProfiles[targetProfile][module] = {}
        for setting, value in pairs(settings) do
            globalProfiles[targetProfile][module][setting] = value
        end
    end
    
    -- Mark settings as dirty
    isDirty = true
    
    return true
end

-- Import profile
function ConfigRegistry:ImportProfile(profileData, profileName)
    -- Validate profile data
    if type(profileData) ~= "string" then
        return false, "Invalid profile data"
    end
    
    -- Try to decode the profile data
    local success, decodedData = pcall(function()
        return self:DecodeProfileData(profileData)
    end)
    
    if not success or not decodedData then
        return false, "Invalid profile data format"
    end
    
    -- Create new profile
    if not globalProfiles[profileName] then
        self:CreateProfile(profileName)
    end
    
    -- Import settings
    for module, settings in pairs(decodedData) do
        globalProfiles[profileName][module] = {}
        for setting, value in pairs(settings) do
            globalProfiles[profileName][module][setting] = value
        end
    end
    
    -- Mark settings as dirty
    isDirty = true
    
    return true
end

-- Export profile
function ConfigRegistry:ExportProfile(profileName)
    -- Check if profile exists
    if not globalProfiles[profileName] then
        return nil
    end
    
    -- Encode the profile data
    return self:EncodeProfileData(globalProfiles[profileName])
end

-- Encode profile data
function ConfigRegistry:EncodeProfileData(profileData)
    -- Convert the profile data to a serialized string
    -- In a real addon, this would use a proper serialization library
    -- For this implementation, we'll use a simple JSON-like format
    
    -- Convert to string
    local serialized = "WR_PROFILE:" .. self:SerializeTable(profileData)
    
    -- Apply simple encoding
    local encoded = self:EncodeString(serialized)
    
    return encoded
end

-- Decode profile data
function ConfigRegistry:DecodeProfileData(encodedData)
    -- Decode the string
    local serialized = self:DecodeString(encodedData)
    
    -- Check prefix
    if not serialized:match("^WR_PROFILE:") then
        return nil
    end
    
    -- Remove prefix
    serialized = serialized:sub(12)
    
    -- Deserialize
    return self:DeserializeTable(serialized)
end

-- Serialize table
function ConfigRegistry:SerializeTable(tbl)
    if type(tbl) ~= "table" then
        if type(tbl) == "string" then
            return string.format("%q", tbl)
        else
            return tostring(tbl)
        end
    end
    
    local result = "{"
    for k, v in pairs(tbl) do
        local key
        if type(k) == "string" then
            key = string.format("[%q]", k)
        else
            key = "[" .. tostring(k) .. "]"
        end
        
        result = result .. key .. "=" .. self:SerializeTable(v) .. ","
    end
    result = result .. "}"
    return result
end

-- Deserialize table
function ConfigRegistry:DeserializeTable(str)
    -- This is a very simplified deserializer that doesn't handle all cases
    -- In a real addon, you would use a proper serialization library
    local func, err = loadstring("return " .. str)
    if not func then
        return nil
    end
    return func()
end

-- Encode string
function ConfigRegistry:EncodeString(str)
    -- Simple base64-like encoding
    local encoded = ""
    for i = 1, #str do
        encoded = encoded .. string.format("%02x", string.byte(str, i))
    end
    return encoded
end

-- Decode string
function ConfigRegistry:DecodeString(encoded)
    -- Simple base64-like decoding
    local decoded = ""
    for i = 1, #encoded, 2 do
        local hex = encoded:sub(i, i+1)
        decoded = decoded .. string.char(tonumber(hex, 16))
    end
    return decoded
end

-- Migrate settings
function ConfigRegistry:MigrateSettings(fromVersion, toVersion)
    WR.API.PrintDebug("Migrating settings from version " .. fromVersion .. " to " .. toVersion)
    
    -- Implement version-specific migrations here
    if fromVersion < 1 and toVersion >= 1 then
        -- Migrate from pre-1.0 to 1.0 format
        self:MigrateToV1()
    end
    
    -- Update version
    settingsVersion = toVersion
    
    -- Mark settings as dirty
    isDirty = true
end

-- Migrate to V1
function ConfigRegistry:MigrateToV1()
    -- Example migration from legacy to v1 format
    WR.API.PrintDebug("Migrating settings to v1 format")
    
    -- This would implement specific migration logic
    -- For now, just ensure the profile exists
    if not globalProfiles["Default"] then
        globalProfiles["Default"] = {}
    end
end

-- Backup settings
function ConfigRegistry:BackupSettings()
    -- Create a backup of current settings
    local backup = {
        profileSettings = self:DeepCopy(profileSettings),
        activeProfile = activeProfile,
        globalProfiles = self:DeepCopy(globalProfiles)
    }
    
    -- Return the backup
    return backup
end

-- Restore settings from backup
function ConfigRegistry:RestoreSettings(backup)
    if not backup then
        return false
    end
    
    -- Restore from backup
    profileSettings = self:DeepCopy(backup.profileSettings)
    activeProfile = backup.activeProfile
    globalProfiles = self:DeepCopy(backup.globalProfiles)
    
    -- Mark settings as dirty
    isDirty = true
    
    -- Trigger callbacks for all modules
    for module, _ in pairs(settingsRegistry) do
        self:TriggerCallbacks(module)
    end
    
    return true
end

-- Restore specific module settings
function ConfigRegistry:RestoreSettings(module, settings)
    if not module or not settings then
        return false
    end
    
    -- Restore module settings
    profileSettings[module] = self:DeepCopy(settings)
    
    -- Mark settings as dirty
    isDirty = true
    
    -- Trigger callbacks
    self:TriggerCallbacks(module)
    
    return true
end

-- Deep copy a table
function ConfigRegistry:DeepCopy(orig)
    local copy
    if type(orig) == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[self:DeepCopy(orig_key)] = self:DeepCopy(orig_value)
        end
        setmetatable(copy, self:DeepCopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

-- Check if setting exists
function ConfigRegistry:HasSetting(module, setting)
    if not profileSettings[module] then
        return false
    end
    
    return profileSettings[module][setting] ~= nil
end

-- Invalidate cache
function ConfigRegistry:InvalidateCache()
    -- Force reload of settings
    isDirty = true
    self:SaveSettings()
    
    -- Re-trigger all callbacks
    for module, _ in pairs(settingsRegistry) do
        self:TriggerCallbacks(module)
    end
end

-- Reset
function ConfigRegistry:Reset()
    -- Reset to default settings
    for module, _ in pairs(settingsRegistry) do
        self:ResetSettings(module)
    end
    
    -- Mark settings as dirty
    isDirty = true
    
    return true
end

-- Register for export
WR.ConfigRegistry = ConfigRegistry

return ConfigRegistry