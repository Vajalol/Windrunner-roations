------------------------------------------
-- WindrunnerRotations - Main Initialization
-- Author: VortexQ8
-- The War Within Season 2
------------------------------------------

-- Set up addon namespace
local addonName, WR = ...

-- Version information
local ADDON_VERSION = "1.0.0"
local ADDON_BUILD = 10010
local WOW_EXPECTED_VERSION = 100205 -- 10.2.5
local TINKR_EXPECTED_VERSION = "3.0"

-- Initialization tracking
local isInitialized = false
local initStartTime = 0
local initErrors = {}
local modulesInitialized = {}
local initializationOrder = {
    "API",
    "ConfigRegistry",
    "ModuleManager",
    "ErrorHandler",
    "PerformanceManager",
    "VersionManager",
    "CombatAnalysis",
    "AntiDetectionSystem",
    "PvPManager",
    "RotationManager"
}

-- Forward declarations for core modules
WR.API = WR.API or {}
WR.ModuleManager = WR.ModuleManager or {}
WR.ConfigRegistry = WR.ConfigRegistry or {}
WR.ErrorHandler = WR.ErrorHandler or {}
WR.PerformanceManager = WR.PerformanceManager or {}

----------------------------------------
-- INITIALIZATION FUNCTIONS
----------------------------------------

-- Main initialization function
local function InitializeAddon()
    -- Skip if already initialized
    if isInitialized then
        return
    end
    
    -- Set initialization start time
    initStartTime = GetTime()
    
    -- Print initialization message
    print("|cFF00FF00WindrunnerRotations|r: Initializing...")
    
    -- Initialize modules in order
    InitializeModules()
    
    -- Register slash commands
    RegisterSlashCommands()
    
    -- Mark as initialized
    isInitialized = true
    
    -- Print initialization complete message
    local initTime = GetTime() - initStartTime
    print(string.format("|cFF00FF00WindrunnerRotations|r: Initialization complete (%.2f seconds)", initTime))
end

-- Initialize modules in the correct order
local function InitializeModules()
    for _, moduleName in ipairs(initializationOrder) do
        InitializeModule(moduleName)
    end
end

-- Initialize a specific module
local function InitializeModule(moduleName)
    -- Skip if already initialized
    if modulesInitialized[moduleName] then
        return true
    end
    
    -- Check if module exists
    if not WR[moduleName] then
        table.insert(initErrors, "Module not found: " .. moduleName)
        print("|cFF00FF00WindrunnerRotations|r: |cFFFF0000Error:|r Module not found: " .. moduleName)
        return false
    end
    
    -- Initialize module using pcall to catch errors
    local success, result = pcall(function()
        if WR[moduleName].Initialize then
            return WR[moduleName]:Initialize()
        else
            return true -- Module has no Initialize method
        end
    end)
    
    if not success then
        -- Initialization failed with error
        table.insert(initErrors, "Failed to initialize " .. moduleName .. ": " .. tostring(result))
        print("|cFF00FF00WindrunnerRotations|r: |cFFFF0000Error:|r Failed to initialize " .. moduleName .. ": " .. tostring(result))
        return false
    elseif result ~= true then
        -- Module returned false from Initialize
        table.insert(initErrors, "Module " .. moduleName .. " initialization returned false")
        print("|cFF00FF00WindrunnerRotations|r: |cFFFF0000Error:|r Module " .. moduleName .. " initialization returned false")
        return false
    end
    
    -- Mark as initialized
    modulesInitialized[moduleName] = true
    print("|cFF00FF00WindrunnerRotations|r: Module initialized: " .. moduleName)
    return true
end

-- Register slash commands
local function RegisterSlashCommands()
    -- Register /wr command if not already registered by RotationManager
    if not SlashCmdList["WINDRUNNERROTATIONS"] then
        SLASH_WINDRUNNERROTATIONS1 = "/wr"
        SlashCmdList["WINDRUNNERROTATIONS"] = function(msg)
            HandleSlashCommand(msg)
        end
    end
    
    -- Register /wrr command for reloading
    SLASH_WINDRUNNERRELOAD1 = "/wrr"
    SlashCmdList["WINDRUNNERRELOAD"] = function(msg)
        ReloadUI()
    end
end

-- Handle slash commands
local function HandleSlashCommand(msg)
    -- If RotationManager is initialized, let it handle commands
    if WR.RotationManager and modulesInitialized["RotationManager"] then
        -- RotationManager handles commands
    else
        -- Handle basic commands
        local command, args = strsplit(" ", msg, 2)
        command = strlower(command or "")
        
        if command == "init" or command == "initialize" then
            -- Re-initialize addon
            InitializeAddon()
        elseif command == "version" then
            -- Show version info
            print("|cFF00FF00WindrunnerRotations|r: Version " .. ADDON_VERSION .. " (Build " .. ADDON_BUILD .. ")")
        elseif command == "debug" then
            -- Toggle debug mode
            if WR.API and WR.API.EnableDebugMode then
                WR.API.EnableDebugMode(not WR.API.IsDebugMode())
            end
        else
            -- Show help
            PrintHelp()
        end
    end
end

-- Print help information
local function PrintHelp()
    print("|cFF00FF00WindrunnerRotations|r: Commands:")
    print("  /wr init - Re-initialize addon")
    print("  /wr version - Show version information")
    print("  /wr debug - Toggle debug mode")
    print("  /wrr - Reload UI")
    
    -- If RotationManager is initialized, show its commands too
    if WR.RotationManager and modulesInitialized["RotationManager"] then
        print("  /wr start - Start rotation")
        print("  /wr stop - Stop rotation")
        print("  /wr toggle - Toggle rotation")
        print("  /wr mode [auto|semi|one|manual] - Set or show rotation mode")
        print("  /wr status - Show rotation status")
        print("  /wr aoe - Toggle AoE abilities")
        print("  /wr cooldowns - Toggle cooldown usage")
    end
}

----------------------------------------
-- EVENT HANDLING
----------------------------------------

-- Create the event frame
local eventFrame = CreateFrame("Frame")

-- Register events
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")

-- Event handler
eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" and ... == addonName then
        -- Addon loaded, initialize on next frame to ensure all files are loaded
        C_Timer.After(0, InitializeAddon)
    elseif event == "PLAYER_LOGIN" then
        -- Player login, make sure we're initialized
        if not isInitialized then
            InitializeAddon()
        end
    end
end)

-- Make initialization functions available in WR namespace
WR.InitializeAddon = InitializeAddon
WR.InitializeModule = InitializeModule
WR.PrintHelp = PrintHelp

-- Return the WR table
return WR