------------------------------------------
-- WindrunnerRotations - Initialization
-- Author: VortexQ8
------------------------------------------

-- Setup addon structure
local addonName, addon = ...
addon.version = "1.0.0"
addon.Classes = {}
addon.Core = {}

-- Local variables
local initialized = false
local debugMode = true
local combatData = {}

-- Get a local reference to API once available
local API = nil

-- Main initialization function
local function Initialize()
    if initialized then
        return
    end
    
    -- Initialize API first
    if addon.API and addon.API.Initialize then
        addon.API.Initialize()
        API = addon.API
        API.PrintDebug("API loaded")
    else
        print("|cFFFF0000[WindrunnerRotations] ERROR:|r API module not found!")
        return
    end
    
    -- Verify Tinkr is loaded
    if not API.VerifyTinkr() then
        API.PrintError("Tinkr verification failed. Please make sure Tinkr is running and up to date.")
        -- Continue initialization but warn user
    end
    
    -- Initialize core modules
    local coreModules = {
        "ConfigRegistry",
        "AdvancedAbilityControl",
        "ModuleManager"
    }
    
    for _, moduleName in ipairs(coreModules) do
        if addon.Core[moduleName] and addon.Core[moduleName].Initialize then
            local success = addon.Core[moduleName].Initialize()
            if success then
                API.PrintDebug(moduleName .. " initialized successfully")
            else
                API.PrintError("Failed to initialize " .. moduleName)
                return
            end
        else
            API.PrintError(moduleName .. " module not found!")
            return
        end
    end
    
    -- Create main frame for OnUpdate and events
    local frame = CreateFrame("Frame")
    
    -- Register events
    frame:RegisterEvent("ADDON_LOADED")
    frame:RegisterEvent("PLAYER_LOGIN")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    
    -- Event handler
    frame:SetScript("OnEvent", function(self, event, ...)
        HandleEvent(event, ...)
    end)
    
    -- OnUpdate handler for rotation execution
    frame:SetScript("OnUpdate", function(self, elapsed)
        OnUpdate(elapsed)
    end)
    
    -- Set initialized flag
    initialized = true
    API.PrintDebug("WindrunnerRotations v" .. addon.version .. " initialized")
end

-- Event handler
local function HandleEvent(event, ...)
    if not API then
        -- API not initialized yet, store events for later
        return
    end
    
    -- Pass event to API for distribution to listeners
    API.HandleEvent(event, ...)
    
    -- Special handling for specific events
    if event == "ADDON_LOADED" then
        local loadedAddon = ...
        if loadedAddon == addonName then
            API.PrintDebug("Addon loaded")
        end
    elseif event == "PLAYER_LOGIN" then
        -- Delayed initialization to ensure other addons are loaded
        C_Timer.After(1, function()
            -- Finalize initialization here
        end)
    end
end

-- OnUpdate handler
local function OnUpdate(elapsed)
    if not initialized or not API then
        return
    end
    
    -- Only run rotation in combat
    if not InCombatLockdown() then
        return
    end
    
    -- Run rotation through Module Manager
    if addon.Core.ModuleManager and addon.Core.ModuleManager.RunRotation then
        addon.Core.ModuleManager:RunRotation()
    end
end

-- Start initialization
Initialize()

-- Helper function to toggle the addon
function addon:Toggle()
    if initialized then
        -- Toggle enabled state
        enabled = not enabled
        API.PrintDebug("WindrunnerRotations " .. (enabled and "enabled" or "disabled"))
    else
        API.PrintError("WindrunnerRotations not initialized")
    end
end

-- Helper function to get version
function addon:GetVersion()
    return addon.version
end

-- Create slash commands
SLASH_WINDRUNNERROTATIONS1 = "/wr"
SLASH_WINDRUNNERROTATIONS2 = "/windrunner"

SlashCmdList["WINDRUNNERROTATIONS"] = function(msg)
    if not initialized or not API then
        print("|cFFFF0000[WindrunnerRotations]|r Not initialized yet")
        return
    end
    
    local command, args = msg:match("^(%S+)%s*(.*)$")
    command = command and command:lower() or "help"
    
    if command == "toggle" or command == "enable" or command == "disable" then
        addon:Toggle()
    elseif command == "version" or command == "ver" then
        API.PrintDebug("WindrunnerRotations v" .. addon.version)
    elseif command == "settings" or command == "config" then
        -- Open settings panel (would be implemented elsewhere)
        API.PrintDebug("Settings panel not implemented yet")
    elseif command == "help" or command == "?" then
        print("|cFF69CCF0WindrunnerRotations Commands:|r")
        print("/wr toggle - Toggle rotation on/off")
        print("/wr version - Show version information")
        print("/wr settings - Open settings panel")
        print("/wr help - Show this help message")
    else
        API.PrintDebug("Unknown command: " .. command)
        print("|cFF69CCF0Type /wr help for available commands|r")
    end
end

-- Return the addon table
return addon