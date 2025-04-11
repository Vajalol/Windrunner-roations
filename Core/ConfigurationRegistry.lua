local addonName, WR = ...

-- Configuration Registry Module
-- Centralized system for registering and managing module configurations
local ConfigurationRegistry = {}
WR.ConfigurationRegistry = ConfigurationRegistry

-- Local references for performance
local pairs = pairs
local ipairs = ipairs
local type = type
local tinsert = table.insert
local tremove = table.remove

-- Registry storage
local registeredModules = {}
local registeredPanels = {}
local registeredCommands = {}

-- Initialize the registry
function ConfigurationRegistry:Initialize()
    -- Make sure the container tables exist
    if not WR.UI then WR.UI = {} end
    
    -- Create default categories
    self:RegisterCategory("General", "General settings for the addon")
    self:RegisterCategory("Rotation", "Configure your combat rotation settings")
    self:RegisterCategory("UI", "Configure the user interface")
    self:RegisterCategory("Advanced", "Advanced configuration options")
    
    -- Register with any existing settings UI
    if WR.UI and WR.UI.AdvancedSettingsUI and WR.UI.AdvancedSettingsUI.SetConfigRegistry then
        -- Connect registry to UI system
        WR.UI.AdvancedSettingsUI:SetConfigRegistry(self)
    end
    
    -- Create connection function if it doesn't exist yet
    if not self.uiConnected then
        -- Add a function to update configuration when UI systems are initialized later
        self.ConnectToUI = function()
            if WR.UI and WR.UI.AdvancedSettingsUI and WR.UI.AdvancedSettingsUI.SetConfigRegistry then
                WR.UI.AdvancedSettingsUI:SetConfigRegistry(self)
                self.uiConnected = true
                return true
            end
            return false
        end
        
        -- Set up a repeating check to connect when UI becomes available
        local connectFrame = CreateFrame("Frame")
        connectFrame:SetScript("OnUpdate", function(self, elapsed)
            if ConfigurationRegistry.uiConnected then
                self:SetScript("OnUpdate", nil)
                return
            end
            
            -- Try to connect every second
            self.elapsed = (self.elapsed or 0) + elapsed
            if self.elapsed > 1 then
                if ConfigurationRegistry:ConnectToUI() then
                    self:SetScript("OnUpdate", nil)
                end
                self.elapsed = 0
            end
        end)
        
        -- Set initial state
        self.uiConnected = false
    end
    
    print("|cFF00FFFF[Configuration Registry]|r Initialized")
end

-- Register a module with the configuration system
function ConfigurationRegistry:RegisterModule(moduleId, moduleName, moduleDesc, moduleIcon, category)
    if not moduleId or not moduleName then
        print("|cFFFF0000[Configuration Registry]|r Error: Missing required parameters for module registration")
        return false
    end
    
    -- Default to Advanced category if none specified
    category = category or "Advanced"
    
    -- Create module entry if it doesn't exist
    if not registeredModules[moduleId] then
        registeredModules[moduleId] = {
            id = moduleId,
            name = moduleName,
            description = moduleDesc,
            icon = moduleIcon,
            category = category,
            settings = {},
            panels = {},
            commands = {},
            enabled = true
        }
        
        print("|cFF00FFFF[Configuration Registry]|r Registered module: " .. moduleName)
        return true
    else
        print("|cFFFF0000[Configuration Registry]|r Error: Module already registered: " .. moduleId)
        return false
    end
end

-- Register a category for organization
function ConfigurationRegistry:RegisterCategory(categoryId, description, parentCategory)
    if not registeredPanels[categoryId] then
        registeredPanels[categoryId] = {
            id = categoryId,
            name = categoryId,
            description = description,
            parent = parentCategory,
            modules = {}
        }
        return true
    end
    return false
end

-- Register a settings panel for a module
function ConfigurationRegistry:RegisterPanel(moduleId, panelId, panelName, renderFunction, displayOrder)
    if not moduleId or not panelId or not renderFunction then
        print("|cFFFF0000[Configuration Registry]|r Error: Missing required parameters for panel registration")
        return false
    end
    
    -- Check if module exists
    if not registeredModules[moduleId] then
        print("|cFFFF0000[Configuration Registry]|r Error: Cannot register panel for unknown module: " .. moduleId)
        return false
    end
    
    -- Add panel to module
    if not registeredModules[moduleId].panels[panelId] then
        registeredModules[moduleId].panels[panelId] = {
            id = panelId,
            name = panelName or panelId,
            render = renderFunction,
            order = displayOrder or 100
        }
        
        -- If this is connected to a UI system, refresh it
        if WR.UI and WR.UI.AdvancedSettingsUI then
            WR.UI.AdvancedSettingsUI:RefreshPanels()
        end
        
        return true
    else
        print("|cFFFF0000[Configuration Registry]|r Error: Panel already registered: " .. panelId .. " for module " .. moduleId)
        return false
    end
end

-- Register a configuration setting
function ConfigurationRegistry:RegisterSetting(moduleId, settingId, settingType, defaultValue, displayName, description, options)
    if not moduleId or not settingId or not settingType then
        print("|cFFFF0000[Configuration Registry]|r Error: Missing required parameters for setting registration")
        return false
    end
    
    -- Check if module exists
    if not registeredModules[moduleId] then
        print("|cFFFF0000[Configuration Registry]|r Error: Cannot register setting for unknown module: " .. moduleId)
        return false
    end
    
    -- Define the setting
    if not registeredModules[moduleId].settings[settingId] then
        registeredModules[moduleId].settings[settingId] = {
            id = settingId,
            type = settingType,
            default = defaultValue,
            value = defaultValue, -- Initialize with default
            name = displayName or settingId,
            desc = description or "",
            options = options or {}
        }
        
        -- If saved variables exist, load the value
        if WindrunnerRotationsDB and 
           WindrunnerRotationsDB.ModuleSettings and 
           WindrunnerRotationsDB.ModuleSettings[moduleId] and
           WindrunnerRotationsDB.ModuleSettings[moduleId][settingId] ~= nil then
            registeredModules[moduleId].settings[settingId].value = WindrunnerRotationsDB.ModuleSettings[moduleId][settingId]
        end
        
        return true
    else
        -- Update existing setting if needed
        local setting = registeredModules[moduleId].settings[settingId]
        setting.type = settingType
        setting.name = displayName or setting.name
        setting.desc = description or setting.desc
        setting.options = options or setting.options
        
        -- Don't override the value if it exists already
        if setting.value == nil then
            setting.value = defaultValue
        end
        
        return true
    end
end

-- Register a slash command handler
function ConfigurationRegistry:RegisterCommand(moduleId, command, handler, description)
    if not moduleId or not command or not handler then
        print("|cFFFF0000[Configuration Registry]|r Error: Missing required parameters for command registration")
        return false
    end
    
    -- Check if module exists
    if not registeredModules[moduleId] then
        print("|cFFFF0000[Configuration Registry]|r Error: Cannot register command for unknown module: " .. moduleId)
        return false
    end
    
    -- Add command to module
    if not registeredModules[moduleId].commands[command] then
        registeredModules[moduleId].commands[command] = {
            command = command,
            handler = handler,
            description = description or "No description available"
        }
        
        -- Add to global command registry
        registeredCommands[command] = {
            moduleId = moduleId,
            handler = handler
        }
        
        return true
    else
        print("|cFFFF0000[Configuration Registry]|r Error: Command already registered: " .. command .. " for module " .. moduleId)
        return false
    end
end

-- Get module information
function ConfigurationRegistry:GetModule(moduleId)
    return registeredModules[moduleId]
end

-- Get a list of all registered modules
function ConfigurationRegistry:GetAllModules()
    local result = {}
    for id, module in pairs(registeredModules) do
        tinsert(result, module)
    end
    return result
end

-- Get a list of all registered categories
function ConfigurationRegistry:GetAllCategories()
    local result = {}
    for id, category in pairs(registeredPanels) do
        tinsert(result, category)
    end
    return result
end

-- Get a setting value
function ConfigurationRegistry:GetSetting(moduleId, settingId)
    if not moduleId or not settingId then return nil end
    
    if registeredModules[moduleId] and registeredModules[moduleId].settings[settingId] then
        return registeredModules[moduleId].settings[settingId].value
    end
    
    return nil
end

-- Set a setting value
function ConfigurationRegistry:SetSetting(moduleId, settingId, value)
    if not moduleId or not settingId then return false end
    
    if registeredModules[moduleId] and registeredModules[moduleId].settings[settingId] then
        registeredModules[moduleId].settings[settingId].value = value
        
        -- Save to persistent storage
        if not WindrunnerRotationsDB then WindrunnerRotationsDB = {} end
        if not WindrunnerRotationsDB.ModuleSettings then WindrunnerRotationsDB.ModuleSettings = {} end
        if not WindrunnerRotationsDB.ModuleSettings[moduleId] then WindrunnerRotationsDB.ModuleSettings[moduleId] = {} end
        
        WindrunnerRotationsDB.ModuleSettings[moduleId][settingId] = value
        
        return true
    end
    
    return false
end

-- Reset a module's settings to defaults
function ConfigurationRegistry:ResetModuleSettings(moduleId)
    if not moduleId then return false end
    
    if registeredModules[moduleId] then
        for settingId, setting in pairs(registeredModules[moduleId].settings) do
            setting.value = setting.default
            
            -- Update persistent storage
            if WindrunnerRotationsDB and 
               WindrunnerRotationsDB.ModuleSettings and 
               WindrunnerRotationsDB.ModuleSettings[moduleId] then
                WindrunnerRotationsDB.ModuleSettings[moduleId][settingId] = setting.default
            end
        end
        
        return true
    end
    
    return false
end

-- Handle a slash command
function ConfigurationRegistry:HandleCommand(command, args)
    if registeredCommands[command] then
        local handler = registeredCommands[command].handler
        if type(handler) == "function" then
            handler(args)
            return true
        end
    end
    
    return false
end

-- Export a module's settings
function ConfigurationRegistry:ExportModuleSettings(moduleId)
    if not moduleId or not registeredModules[moduleId] then
        return nil
    end
    
    local exportData = {}
    
    for settingId, setting in pairs(registeredModules[moduleId].settings) do
        exportData[settingId] = setting.value
    end
    
    -- Convert to serialized string (simple implementation)
    local serialized = "WR_CONFIG_EXPORT:" .. moduleId .. ":" .. self:SerializeTable(exportData)
    
    return serialized
end

-- Import module settings
function ConfigurationRegistry:ImportModuleSettings(importString)
    if not importString or type(importString) ~= "string" then
        return false, "Invalid import string"
    end
    
    -- Validate format (simple implementation)
    if not importString:match("^WR_CONFIG_EXPORT:") then
        return false, "Invalid format"
    end
    
    local moduleId, dataString = importString:match("^WR_CONFIG_EXPORT:([^:]+):(.+)$")
    
    if not moduleId or not dataString then
        return false, "Invalid format: missing module ID or data"
    end
    
    if not registeredModules[moduleId] then
        return false, "Unknown module: " .. moduleId
    end
    
    -- Deserialize
    local success, importData = self:DeserializeTable(dataString)
    if not success or type(importData) ~= "table" then
        return false, "Failed to parse settings data"
    end
    
    -- Apply imported settings
    for settingId, value in pairs(importData) do
        if registeredModules[moduleId].settings[settingId] then
            self:SetSetting(moduleId, settingId, value)
        end
    end
    
    return true, "Settings imported successfully for " .. moduleId
end

-- Serialize a table to string (simple implementation)
function ConfigurationRegistry:SerializeTable(tbl)
    if type(tbl) ~= "table" then
        if type(tbl) == "string" then
            return string.format("%q", tbl)
        else
            return tostring(tbl)
        end
    end
    
    local result = "{"
    for k, v in pairs(tbl) do
        local key = type(k) == "number" and "[" .. k .. "]" or "[" .. string.format("%q", k) .. "]"
        result = result .. key .. "=" .. self:SerializeTable(v) .. ","
    end
    result = result .. "}"
    
    return result
end

-- Deserialize a string to table (simple implementation)
function ConfigurationRegistry:DeserializeTable(str)
    local fn, err = loadstring("return " .. str)
    if not fn then
        return false, err
    end
    
    -- Execute in a safe environment
    setfenv(fn, {})
    
    local success, result = pcall(fn)
    if not success then
        return false, result
    end
    
    return true, result
end

-- Register built-in modules
function ConfigurationRegistry:RegisterBuiltInModules()
    -- Register core modules
    self:RegisterModule("Core", "Core Settings", "Basic settings for the addon", nil, "General")
    
    -- Register each module (these would typically be registered by the modules themselves)
    if WR.AdvancedAbilityControl then
        self:RegisterModule("AdvancedAbilityControl", "Advanced Ability Control", 
            "Configure interrupts, dispels, and crowd control", nil, "Advanced")
    end
    
    if WR.MachineLearning then
        self:RegisterModule("MachineLearning", "Machine Learning System", 
            "Configure rotation learning and adaptation", nil, "Advanced")
    end
    
    if WR.PvPSystem then
        self:RegisterModule("PvPSystem", "PvP System", 
            "Configure PvP-specific behaviors", nil, "Advanced")
    end
    
    if WR.PartySynergy then
        self:RegisterModule("PartySynergy", "Party Synergy", 
            "Configure group coordination features", nil, "Advanced")
    end
    
    if WR.ExternalDataIntegration then
        self:RegisterModule("ExternalDataIntegration", "External Data Integration", 
            "Configure integration with external services", nil, "Advanced")
    end
end

return ConfigurationRegistry