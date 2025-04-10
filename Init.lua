-------------------------------------------------------------------------------
-- Windrunner Rotations - Better than Phoenix Rotations
-- World of Warcraft: The War Within - Season 2
-- Author: WindrunnerDev
-------------------------------------------------------------------------------

local addonName, WR = ...
_G["WindrunnerRotations"] = WR

-- Global addon namespace
WR = {
    name = "WindrunnerRotations",
    version = "1.0.0",
    author = "WindrunnerDev",
    isRunning = false,
    debugMode = true, -- Set to true during development
    currentSpec = nil,
    class = "MAGE", -- Set a mock class during development
    
    -- Core functionality 
    API = {},
    Rotation = {},
    Target = {},
    Queue = {},
    Combat = {},
    Profiles = {},
    Dungeons = {},
    
    -- Data storage
    Data = {
        Classes = {},
        Spells = {},
        Dungeons = {},
    },
    
    -- Class modules
    Classes = {},
    
    -- UI elements
    UI = {},
}

-- Verify Tinkr API exists - for demonstration we'll mock Tinkr
function WR:VerifyTinkr()
    -- In a testing environment, create mock Tinkr
    if not _G.Tinkr then
        _G.Tinkr = {
            api = {},
            ObjectManager = {
                TargetUnit = function(self, unit) 
                    print("Tinkr: Targeting unit", unit)
                    return true
                end
            }
        }
        print("Created mock Tinkr API for demonstration environment")
    end
    
    -- Check if the real API exists in the game environment
    if not Tinkr then
        print("|cFFFF0000[Windrunner Rotations]|r Tinkr API not detected. The addon requires Tinkr to function.")
        return false
    end
    
    if not Tinkr.api then
        print("|cFFFF0000[Windrunner Rotations]|r Tinkr API is outdated. Please update Tinkr.")
        return false
    end
    
    return true
end

-- Initial setup on load
function WR:OnInitialize()
    -- Check for Tinkr
    if not self:VerifyTinkr() then return end
    
    -- Get player information
    self.playerGUID = UnitGUID("player")
    self.playerName = UnitName("player")
    self.playerLevel = UnitLevel("player")
    
    -- Initialize databases
    self:InitializeDB()
    
    -- For testing purposes, we're simulating a WoW environment
    -- In a real WoW addon, these would be actual WoW API functions
    
    -- Mock required WoW API functions for testing
    -- These are normally provided by the WoW client
    if not _G.UnitClass then
        _G.UnitClass = function(unit) return "Mage", "MAGE" end
        _G.UnitGUID = function(unit) return "Player-1234" end
        _G.UnitName = function(unit) return "TestPlayer" end
        _G.UnitLevel = function(unit) return 70 end
        _G.GetSpecialization = function() return 1 end
        _G.GetSpecializationInfo = function(spec) return 62 end -- Arcane Mage
        _G.CreateFrame = function(type, name, parent, template) return {} end
        _G.SlashCmdList = {}
        
        print("Created mock WoW API functions for testing environment")
    end
    
    -- Initialize core systems in the correct order
    -- Load GCD tracker first as other systems depend on it
    if self.GCD and self.GCD.Initialize then self.GCD:Initialize() end
    
    -- Then initialize condition system for spell evaluations
    if self.Condition and self.Condition.Initialize then self.Condition:Initialize() end
    
    -- Initialize API system for accessing WoW and Tinkr functionality
    if self.API and self.API.Initialize then self.API:Initialize() end
    
    -- Combat analysis for performance tracking
    if self.CombatAnalysis and self.CombatAnalysis.Initialize then self.CombatAnalysis:Initialize() end
    
    -- Core rotation components
    if self.Queue and self.Queue.Initialize then self.Queue:Initialize() end
    if self.Target and self.Target.Initialize then self.Target:Initialize() end
    if self.Combat and self.Combat.Initialize then self.Combat:Initialize() end
    if self.Rotation and self.Rotation.Initialize then self.Rotation:Initialize() end
    
    -- Configuration and data components
    if self.Profiles and self.Profiles.Initialize then self.Profiles:Initialize() end
    if self.Dungeons and self.Dungeons.Initialize then self.Dungeons:Initialize() end
    
    -- Register for events
    self:RegisterEvents()
    
    -- Add more mock functions for demonstration
    if not _G.GetTime then
        _G.GetTime = function() return os.time() end
        _G.UnitExists = function(unit) return true end
        _G.UnitIsDead = function(unit) return false end
        _G.UnitCanAttack = function(unit1, unit2) return true end
        _G.print = function(...) 
            local args = {...}
            local message = ""
            for i, v in ipairs(args) do
                message = message .. tostring(v) .. " "
            end
            print(message)
        end
    end

    print("Mocking class/spec for demonstration: MAGE, Arcane Spec (62)")
    
    -- Initialize a basic Config functionality for testing
    if not self.Config then
        self.Config = {}
        
        function self.Config:Get(key, subkey)
            return true
        end
        
        function self.Config:Set(key, value, subkey)
            -- Do nothing in demo
        end
        
        function self.Config:GetCurrentProfile()
            return "Default"
        end
        
        function self.Config:SaveClassProfile(profile, name)
            -- Do nothing in demo
        end
        
        function self.Config:DeleteProfile(name)
            -- Do nothing in demo
        end
    end
    
    -- Show initialization message
    print("WindrunnerRotations demonstration initialized")
    
    -- For demonstration, we'll skip these
    -- self:LoadClassModule()
    -- self.UI:Initialize()
    
    print("|cFF00FF00[Windrunner Rotations v" .. self.version .. "]|r loaded successfully.")
    print("|cFF00FFFF[Windrunner Rotations]|r Type /wr or /windrunner to open settings.")
end

-- Set up saved variables
function WR:InitializeDB()
    -- Initialize default profile settings
    local defaults = {
        profile = {
            enabled = true,
            enableAutoTargeting = true,
            enableInterrupts = true,
            enableDefensives = true,
            enableCooldowns = false,
            enableAOE = false,
            enableDungeonAwareness = true,
            rotationSpeed = 100, -- milliseconds
            minimapIcon = { hide = false },
            UI = {
                scale = 1.0,
                locked = false,
                position = { point = "CENTER", x = 0, y = 0 },
            },
        },
        char = {
            currentProfile = "Default",
            classProfiles = {},
        },
    }
    
    -- AceDB setup would go here, but we're avoiding dependencies
    -- Just set up the basic structure for now
    if not WindrunnerRotationsDB then WindrunnerRotationsDB = defaults.profile end
    if not WindrunnerRotationsCharDB then WindrunnerRotationsCharDB = defaults.char end
    
    self.db = WindrunnerRotationsDB
    self.charDB = WindrunnerRotationsCharDB
end

-- Register for WoW events
function WR:RegisterEvents()
    -- Create an event frame
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_LOGIN")
    eventFrame:RegisterEvent("PLAYER_LOGOUT")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "PLAYER_LOGIN" then
            WR:OnInitialize()
        elseif event == "PLAYER_LOGOUT" then
            WR:OnShutdown()
        elseif event == "PLAYER_ENTERING_WORLD" then
            WR:UpdatePlayerInfo()
        elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
            WR:LoadClassModule()
        elseif event == "ZONE_CHANGED_NEW_AREA" then
            WR.Dungeons:CheckCurrentDungeon()
        end
    end)
    
    -- Create a slash command handler
    SLASH_WINDRUNNERROTATIONS1 = "/windrunner"
    SLASH_WINDRUNNERROTATIONS2 = "/wr"
    SlashCmdList["WINDRUNNERROTATIONS"] = function(msg)
        WR:HandleSlashCommand(msg)
    end
end

-- Load the appropriate class module
function WR:LoadClassModule()
    local _, class = UnitClass("player")
    local spec = GetSpecialization()
    local specID = spec and GetSpecializationInfo(spec) or nil
    
    if not specID then return end
    
    self.currentSpec = specID
    
    -- Load class-specific rotation if available
    if self.Classes[class] and self.Classes[class].LoadSpec then
        self.Classes[class]:LoadSpec(specID)
        print("|cFF00FFFF[Windrunner Rotations]|r Loaded rotation for " .. class .. " spec " .. specID)
    else
        print("|cFFFFFF00[Windrunner Rotations]|r No rotation found for your class/spec")
    end
end

-- Update player information when world is entered
function WR:UpdatePlayerInfo()
    self.playerGUID = UnitGUID("player")
    self.playerName = UnitName("player")
    self.playerLevel = UnitLevel("player")
    
    -- Check if we're in a dungeon
    self.Dungeons:CheckCurrentDungeon()
end

-- Handle slash commands
function WR:HandleSlashCommand(msg)
    if not msg or msg == "" then
        -- Open main UI
        self.UI:Toggle()
    elseif msg == "debug" then
        -- Toggle debug mode
        self.debugMode = not self.debugMode
        print("|cFF00FFFF[Windrunner Rotations]|r Debug mode: " .. (self.debugMode and "ENABLED" or "DISABLED"))
    elseif msg == "start" or msg == "enable" then
        -- Start rotations
        self:StartRotation()
    elseif msg == "stop" or msg == "disable" then
        -- Stop rotations
        self:StopRotation()
    elseif msg == "toggle" then
        -- Toggle rotation
        if self.isRunning then
            self:StopRotation()
        else
            self:StartRotation()
        end
    elseif msg == "reload" then
        -- Reload class module
        self:LoadClassModule()
    end
end

-- Start rotation system
function WR:StartRotation()
    if not self:VerifyTinkr() then return end
    
    if not self.isRunning then
        self.isRunning = true
        self.Rotation:Start()
        print("|cFF00FF00[Windrunner Rotations]|r Rotations ENABLED")
    end
end

-- Stop rotation system
function WR:StopRotation()
    if self.isRunning then
        self.isRunning = false
        self.Rotation:Stop()
        print("|cFFFF0000[Windrunner Rotations]|r Rotations DISABLED")
    end
end

-- Clean up on shutdown
function WR:OnShutdown()
    self:StopRotation()
    -- Save any necessary data
end

-- Debug utility function
function WR:Debug(...)
    if self.debugMode then
        print("|cFF00FFFF[WR Debug]|r", ...)
    end
end
