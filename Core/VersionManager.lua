------------------------------------------
-- WindrunnerRotations - Version Manager
-- Author: VortexQ8
-- The War Within Season 2
------------------------------------------

local addonName, WR = ...
local VersionManager = {}
WR.VersionManager = VersionManager

-- Dependencies
local API = WR.API
local ConfigRegistry = WR.ConfigRegistry
local ModuleManager = WR.ModuleManager

-- Version data
local CURRENT_VERSION = "1.0.0"
local CURRENT_CODENAME = "WindrunnerRotations"
local BUILD_NUMBER = 10010 -- Format: 1.00.10 = 10010
local DATABASE_VERSION = 3 -- Incremented when database format changes
local MINIMUM_WOW_VERSION = 100200 -- 10.2.0
local COMPATIBLE_WOW_VERSIONS = {
    [100200] = true, -- 10.2.0
    [100205] = true, -- 10.2.5
    [100300] = true  -- 10.3.0
}
local CURRENT_WOW_VARIANT = "retail" -- "retail", "wrath", "vanilla", "cataclysm"
local moduleVersions = {}
local requiredModuleVersions = {}
local versionFrame = nil
local isVersionCheckActive = false
local lastVersionCheck = 0
local checkInterval = 86400 -- Check for new version every 24 hours
local updateAvailable = false
local latestVersion = nil
local updateURL = "https://github.com/VortexQ8/WindrunnerRotations/releases"
local moduleUpdateRequired = {}
local RELEASE_TYPE = "release" -- "alpha", "beta", "release"
local versionHistory = {
    ["1.0.0"] = {
        releaseDate = "2023-11-10",
        releaseType = "release",
        wowVersions = {100200, 100205},
        changes = {
            "Initial release",
            "Support for all classes and specializations",
            "Basic rotation functionality"
        }
    },
    ["0.9.5"] = {
        releaseDate = "2023-10-15",
        releaseType = "beta",
        wowVersions = {100200},
        changes = {
            "Final beta release",
            "Bug fixes and performance improvements",
            "Added missing rotations"
        }
    },
    ["0.9.0"] = {
        releaseDate = "2023-09-20",
        releaseType = "beta",
        wowVersions = {100200},
        changes = {
            "First beta release",
            "Added advanced settings panel",
            "Initial rotation implementations"
        }
    },
    ["0.5.0"] = {
        releaseDate = "2023-08-05",
        releaseType = "alpha",
        wowVersions = {100200},
        changes = {
            "Alpha preview release",
            "Basic framework implementation",
            "Testing rotation system"
        }
    }
}
local knownCompatibilityIssues = {
    -- Format: [addonName] = {minVersion = "x.y.z", issues = "description"}
    ["ElvUI"] = {
        minVersion = "13.0",
        issues = "Frame positioning may be incorrect with older versions"
    },
    ["WeakAuras"] = {
        minVersion = "3.7.0",
        issues = "Potential conflicts with rotation auras"
    },
    ["Plater"] = {
        minVersion = "v9.0",
        issues = "Nameplate scanning may conflict with older versions"
    }
}
local FEATURE_VERSIONS = {
    INTERRUPT_MANAGEMENT = "0.7.0",
    COOLDOWN_TRACKING = "0.8.0",
    AUTO_TARGETING = "0.8.5",
    ML_ADAPTION = "0.9.0",
    MOUSEOVER_INTEGRATION = "0.9.0",
    PVP_ROTATIONS = "0.9.2",
    COVENANT_INTEGRATION = "0.9.5",
    ONE_BUTTON_MODE = "0.9.5",
    PROFILE_SHARING = "0.9.8",
    GROUP_ROLE_DETECTION = "1.0.0",
    TRINKET_OPTIMIZATION = "1.0.0",
    CUSTOM_KEYBINDS = "1.0.0",
    CC_CHAIN_ASSIST = "1.0.0",
    PERFORMANCE_MANAGER = "1.0.0",
    ERROR_HANDLER = "1.0.0",
    ANTI_DETECTION = "1.0.0",
    VERSION_MANAGER = "1.0.0"
}
local installDate = nil
local lastUpdateDate = nil
local deprecationWarnings = {}
local apiChanges = {}
local pendingMigrations = {}
local migrationStatus = {}

-- Initialize the Version Manager
function VersionManager:Initialize()
    -- Register settings
    self:RegisterSettings()
    
    -- Create version frame
    self:CreateVersionFrame()
    
    -- Register events
    self:RegisterEvents()
    
    -- Register module versions
    self:RegisterModuleVersions()
    
    -- Check compatibility
    self:CheckCompatibility()
    
    -- Register version with core
    API.SetAddonVersion(CURRENT_VERSION, BUILD_NUMBER)
    
    -- Set up automatic version check
    self:SetupVersionCheck()
    
    -- Check for pending migrations
    self:CheckForMigrations()
    
    API.PrintDebug("Version Manager initialized")
    return true
end

-- Register settings
function VersionManager:RegisterSettings()
    ConfigRegistry:RegisterSettings("VersionManager", {
        generalSettings = {
            enableVersionCheck = {
                displayName = "Enable Version Check",
                description = "Automatically check for new versions",
                type = "toggle",
                default = true
            },
            checkInterval = {
                displayName = "Check Interval",
                description = "How often to check for updates (hours)",
                type = "slider",
                min = 1,
                max = 168, -- 1 week
                step = 1,
                default = 24
            },
            notifyOnUpdate = {
                displayName = "Notify On Update",
                description = "Show notification when update is available",
                type = "toggle",
                default = true
            },
            betaUpdates = {
                displayName = "Check Beta Updates",
                description = "Check for beta versions as well as releases",
                type = "toggle",
                default = false
            }
        },
        compatibilitySettings = {
            enableCompatibilityCheck = {
                displayName = "Enable Compatibility Check",
                description = "Check for compatibility issues with other addons",
                type = "toggle",
                default = true
            },
            strictVersionCheck = {
                displayName = "Strict Version Check",
                description = "Show warning if WoW version is not explicitly compatible",
                type = "toggle",
                default = false
            },
            allowDeprecatedAPI = {
                displayName = "Allow Deprecated API",
                description = "Allow use of deprecated API functions (may cause errors)",
                type = "toggle",
                default = false
            }
        },
        migrationSettings = {
            autoMigration = {
                displayName = "Automatic Migration",
                description = "Automatically migrate settings between versions",
                type = "toggle",
                default = true
            },
            backupBeforeMigration = {
                displayName = "Backup Before Migration",
                description = "Create backup of settings before migration",
                type = "toggle",
                default = true
            },
            keepMigrationHistory = {
                displayName = "Keep Migration History",
                description = "Save history of completed migrations",
                type = "toggle",
                default = true
            }
        }
    })
}

-- Create version frame
function VersionManager:CreateVersionFrame()
    versionFrame = CreateFrame("Frame", "WindrunnerRotationsVersionFrame")
    versionFrame:Hide()
    
    -- Set up OnUpdate handler for version check
    versionFrame:SetScript("OnUpdate", function(self, elapsed)
        VersionManager:ProcessVersionCheck(elapsed)
    end)
}

-- Register events
function VersionManager:RegisterEvents()
    -- Register for addon loaded to finalize version setup
    API.RegisterEvent("ADDON_LOADED", function(loadedAddonName)
        if loadedAddonName == "WindrunnerRotations" then
            VersionManager:OnAddonLoaded()
        end
    end)
    
    -- Register for player login to check for updates
    API.RegisterEvent("PLAYER_LOGIN", function()
        VersionManager:OnPlayerLogin()
    end)
    
    -- Register for compatibility checks with other addons
    API.RegisterEvent("ADDON_LOADED", function(loadedAddonName)
        VersionManager:CheckAddonCompatibility(loadedAddonName)
    end)
}

-- Register module versions
function VersionManager:RegisterModuleVersions()
    -- Define required versions for each module
    requiredModuleVersions = {
        ["API"] = "1.0.0",
        ["ConfigRegistry"] = "1.0.0",
        ["ModuleManager"] = "1.0.0",
        ["RotationManager"] = "1.0.0",
        ["InterruptManager"] = "1.0.0",
        ["OneButtonMode"] = "1.0.0",
        ["PvPManager"] = "1.0.0",
        ["GroupRoleManager"] = "1.0.0",
        ["TrinketManager"] = "1.0.0",
        ["KeybindManager"] = "1.0.0",
        ["CCChainAssist"] = "1.0.0",
        ["PerformanceManager"] = "1.0.0",
        ["ErrorHandler"] = "1.0.0",
        ["AntiDetectionSystem"] = "1.0.0"
    }
    
    -- Register versions for each module as they're loaded
    for moduleName, module in pairs(WR) do
        if type(module) == "table" then
            -- Use module's version if available, otherwise use addon version
            local moduleVersion = module.VERSION or CURRENT_VERSION
            self:RegisterModuleVersion(moduleName, moduleVersion)
        end
    end
}

-- Register module version
function VersionManager:RegisterModuleVersion(moduleName, version)
    moduleVersions[moduleName] = version
    
    -- Check if this module requires migration
    if requiredModuleVersions[moduleName] and self:CompareVersions(version, requiredModuleVersions[moduleName]) < 0 then
        moduleUpdateRequired[moduleName] = true
        API.PrintDebug("Module " .. moduleName .. " needs update. Current: " .. version .. ", Required: " .. requiredModuleVersions[moduleName])
    end
}

-- Check compatibility
function VersionManager:CheckCompatibility()
    -- Check WoW version compatibility
    local wowVersion, wowBuild = self:GetWoWVersion()
    
    -- Convert to numeric format
    local numericWowVersion = self:ConvertWoWVersionToNumeric(wowVersion)
    
    -- Check if WoW version is compatible
    local isCompatible = COMPATIBLE_WOW_VERSIONS[numericWowVersion] or false
    local isMinimumMet = numericWowVersion >= MINIMUM_WOW_VERSION
    
    -- Get settings
    local settings = ConfigRegistry:GetSettings("VersionManager")
    local strictCheck = settings.compatibilitySettings.strictVersionCheck
    
    -- Warning if incompatible
    if not isCompatible and strictCheck then
        API.PrintMessage("WARNING: WindrunnerRotations has not been tested with your version of WoW (" .. wowVersion .. ").")
        API.PrintMessage("Minimum supported version: " .. self:ConvertNumericToWoWVersion(MINIMUM_WOW_VERSION))
    elseif not isMinimumMet then
        API.PrintMessage("WARNING: Your WoW version (" .. wowVersion .. ") is below the minimum required version for WindrunnerRotations.")
        API.PrintMessage("Minimum required version: " .. self:ConvertNumericToWoWVersion(MINIMUM_WOW_VERSION))
        API.PrintMessage("Some features may not work correctly.")
    end
    
    -- Check module compatibility
    for moduleName, requiredVersion in pairs(requiredModuleVersions) do
        if WR[moduleName] then
            local moduleVersion = moduleVersions[moduleName] or "0.0.0"
            
            if self:CompareVersions(moduleVersion, requiredVersion) < 0 then
                API.PrintMessage("WARNING: Module " .. moduleName .. " is outdated. Current: " .. moduleVersion .. ", Required: " .. requiredVersion)
            end
        else
            API.PrintMessage("WARNING: Required module " .. moduleName .. " is missing.")
        end
    end
}

-- Check addon compatibility
function VersionManager:CheckAddonCompatibility(addonName)
    -- Skip if not a known addon with compatibility issues
    if not knownCompatibilityIssues[addonName] then
        return
    end
    
    -- Check if compatibility checks are enabled
    local settings = ConfigRegistry:GetSettings("VersionManager")
    if not settings.compatibilitySettings.enableCompatibilityCheck then
        return
    end
    
    -- Get addon version
    local addonVersion = self:GetAddonVersion(addonName)
    
    -- Check if version is available
    if not addonVersion then
        return
    end
    
    -- Check against known compatibility issues
    local compatibility = knownCompatibilityIssues[addonName]
    
    if self:CompareVersions(addonVersion, compatibility.minVersion) < 0 then
        API.PrintMessage("WARNING: Compatibility issue detected with " .. addonName .. " version " .. addonVersion)
        API.PrintMessage("Minimum recommended version: " .. compatibility.minVersion)
        API.PrintMessage("Issue: " .. compatibility.issues)
    end
end

-- Get addon version
function VersionManager:GetAddonVersion(addonName)
    -- This will vary depending on the addon, as different addons store version info differently
    -- This is a simplified implementation
    
    local addonTable = _G[addonName]
    if not addonTable then return nil end
    
    -- Check common version patterns
    if addonTable.version then
        return tostring(addonTable.version)
    elseif addonTable.Version then
        return tostring(addonTable.Version)
    elseif addonTable.VERSION then
        return tostring(addonTable.VERSION)
    end
    
    -- Try to get version from TOC
    local version = GetAddOnMetadata(addonName, "Version")
    if version then
        return version
    end
    
    return nil
end

-- Get WoW version
function VersionManager:GetWoWVersion()
    local version, build, date, tocversion = GetBuildInfo()
    return version, build
end

-- Convert WoW version to numeric
function VersionManager:ConvertWoWVersionToNumeric(version)
    local major, minor, patch = version:match("(%d+)%.(%d+)%.(%d+)")
    
    if major and minor and patch then
        return major * 10000 + minor * 100 + patch
    else
        -- Fallback for other formats
        major, minor = version:match("(%d+)%.(%d+)")
        if major and minor then
            return major * 10000 + minor * 100
        end
    end
    
    return 0
end

-- Convert numeric to WoW version
function VersionManager:ConvertNumericToWoWVersion(numeric)
    local major = math.floor(numeric / 10000)
    local minor = math.floor((numeric - major * 10000) / 100)
    local patch = numeric - major * 10000 - minor * 100
    
    return major .. "." .. minor .. "." .. patch
end

-- On addon loaded
function VersionManager:OnAddonLoaded()
    -- Setup install/update dates
    if not installDate then
        -- First time installation
        installDate = time()
        lastUpdateDate = installDate
    end
    
    -- Check for updates/upgrades
    local previousVersion = self:GetSavedVersion()
    
    if previousVersion and self:CompareVersions(CURRENT_VERSION, previousVersion) > 0 then
        -- Version has been updated
        API.PrintMessage("WindrunnerRotations updated from " .. previousVersion .. " to " .. CURRENT_VERSION)
        lastUpdateDate = time()
        
        -- Check for migrations from previous version
        self:CheckMigrationFromVersion(previousVersion)
    end
    
    -- Save current version
    self:SaveCurrentVersion()
    
    -- Register this version with API
    API.SetAddonVersion(CURRENT_VERSION, BUILD_NUMBER)
}

-- On player login
function VersionManager:OnPlayerLogin()
    -- Check for updates
    local settings = ConfigRegistry:GetSettings("VersionManager")
    
    if settings.generalSettings.enableVersionCheck then
        -- Schedule version check
        self:ScheduleVersionCheck()
    end
    
    -- Print version info
    API.PrintMessage(CURRENT_CODENAME .. " version " .. CURRENT_VERSION .. " loaded.")
    
    -- Print any pending migrations
    if #pendingMigrations > 0 then
        API.PrintMessage("Settings migration required. Type /wr migrate to start migration.")
    end
}

-- Setup version check
function VersionManager:SetupVersionCheck()
    -- Set check interval from settings
    local settings = ConfigRegistry:GetSettings("VersionManager")
    checkInterval = settings.generalSettings.checkInterval * 3600 -- Convert hours to seconds
}

-- Schedule version check
function VersionManager:ScheduleVersionCheck()
    -- Skip if already active
    if isVersionCheckActive then
        return
    end
    
    -- Get time since last check
    local timeSinceCheck = time() - lastVersionCheck
    
    -- Check if it's time to check
    if timeSinceCheck >= checkInterval then
        -- Start version check
        isVersionCheckActive = true
        versionFrame:Show()
        
        -- Debug message
        API.PrintDebug("Starting version check")
    else
        -- Schedule for later
        local timeToCheck = checkInterval - timeSinceCheck
        C_Timer.After(timeToCheck, function()
            VersionManager:ScheduleVersionCheck()
        end)
        
        -- Debug message
        API.PrintDebug("Version check scheduled in " .. math.floor(timeToCheck / 60) .. " minutes")
    end
}

-- Process version check
function VersionManager:ProcessVersionCheck(elapsed)
    -- This would normally send a network request to check for updates
    -- For simplicity, we'll simulate finding an update
    
    -- Update is "found"
    isVersionCheckActive = false
    versionFrame:Hide()
    
    -- Update last check time
    lastVersionCheck = time()
    
    -- Simulate finding a new version
    if self:SimulateVersionCheck() then
        -- Show update notification
        self:ShowUpdateNotification()
    end
}

-- Simulate version check
function VersionManager:SimulateVersionCheck()
    -- Simulate finding a newer version
    -- In a real implementation, this would check an API endpoint
    
    -- Get settings
    local settings = ConfigRegistry:GetSettings("VersionManager")
    
    -- Check beta updates if enabled
    local includeBeta = settings.generalSettings.betaUpdates
    
    -- For simulation purposes, we'll just use a newer version than current
    latestVersion = "1.1.0"
    
    -- Check if this is newer than current
    if self:CompareVersions(latestVersion, CURRENT_VERSION) > 0 then
        updateAvailable = true
        return true
    end
    
    return false
}

-- Show update notification
function VersionManager:ShowUpdateNotification()
    -- Get settings
    local settings = ConfigRegistry:GetSettings("VersionManager")
    
    -- Skip if notifications are disabled
    if not settings.generalSettings.notifyOnUpdate then
        return
    end
    
    -- Show notification
    API.PrintMessage("A new version of WindrunnerRotations is available: " .. latestVersion)
    API.PrintMessage("You are currently using version " .. CURRENT_VERSION)
    API.PrintMessage("Visit " .. updateURL .. " to update")
}

-- Compare versions
function VersionManager:CompareVersions(version1, version2)
    -- Parse version strings (expects format like "1.2.3")
    local major1, minor1, patch1 = version1:match("(%d+)%.(%d+)%.(%d+)")
    local major2, minor2, patch2 = version2:match("(%d+)%.(%d+)%.(%d+)")
    
    -- Handle different formats
    if not major1 then
        major1, minor1 = version1:match("(%d+)%.(%d+)")
        patch1 = 0
    end
    
    if not major2 then
        major2, minor2 = version2:match("(%d+)%.(%d+)")
        patch2 = 0
    end
    
    -- Convert to numbers
    major1, minor1, patch1 = tonumber(major1) or 0, tonumber(minor1) or 0, tonumber(patch1) or 0
    major2, minor2, patch2 = tonumber(major2) or 0, tonumber(minor2) or 0, tonumber(patch2) or 0
    
    -- Compare major version
    if major1 > major2 then
        return 1
    elseif major1 < major2 then
        return -1
    end
    
    -- Compare minor version
    if minor1 > minor2 then
        return 1
    elseif minor1 < minor2 then
        return -1
    end
    
    -- Compare patch version
    if patch1 > patch2 then
        return 1
    elseif patch1 < patch2 then
        return -1
    end
    
    -- Versions are equal
    return 0
end

-- Get saved version
function VersionManager:GetSavedVersion()
    -- In a real addon, this would come from SavedVariables
    -- For implementation simplicity, we'll return a simulated previous version
    return "0.9.5"
end

-- Save current version
function VersionManager:SaveCurrentVersion()
    -- In a real addon, this would save to SavedVariables
    -- Not needed for this implementation
}

-- Check for migrations
function VersionManager:CheckForMigrations()
    -- Define migrations
    pendingMigrations = {
        {
            fromVersion = "0.9.0",
            toVersion = "0.9.5",
            description = "Update interrupt profiles",
            migrationFunction = function()
                -- Migration code would go here
                return true
            end
        },
        {
            fromVersion = "0.9.5",
            toVersion = "1.0.0",
            description = "Migrate settings to new format",
            migrationFunction = function()
                -- Migration code would go here
                return true
            end
        }
    }
    
    -- Check if any migrations are needed
    local previousVersion = self:GetSavedVersion()
    local pendingCount = 0
    
    for _, migration in ipairs(pendingMigrations) do
        if self:CompareVersions(previousVersion, migration.fromVersion) >= 0 and 
           self:CompareVersions(previousVersion, migration.toVersion) < 0 and
           self:CompareVersions(CURRENT_VERSION, migration.toVersion) >= 0 then
            -- This migration is pending
            pendingCount = pendingCount + 1
        end
    end
    
    -- Log pending migrations
    if pendingCount > 0 then
        API.PrintDebug(pendingCount .. " migrations are pending")
    end
}

-- Check migration from version
function VersionManager:CheckMigrationFromVersion(fromVersion)
    -- Get settings
    local settings = ConfigRegistry:GetSettings("VersionManager")
    
    -- Skip if auto migration is disabled
    if not settings.migrationSettings.autoMigration then
        return
    end
    
    -- Find applicable migrations
    local applicableMigrations = {}
    
    for _, migration in ipairs(pendingMigrations) do
        if self:CompareVersions(fromVersion, migration.fromVersion) >= 0 and 
           self:CompareVersions(fromVersion, migration.toVersion) < 0 and
           self:CompareVersions(CURRENT_VERSION, migration.toVersion) >= 0 then
            table.insert(applicableMigrations, migration)
        end
    end
    
    -- Run migrations if any are found
    if #applicableMigrations > 0 then
        API.PrintMessage("Migrating settings from version " .. fromVersion .. " to " .. CURRENT_VERSION)
        
        -- Create backup if enabled
        if settings.migrationSettings.backupBeforeMigration then
            self:CreateMigrationBackup(fromVersion)
        end
        
        -- Run migrations
        for _, migration in ipairs(applicableMigrations) do
            self:ExecuteMigration(migration)
        end
    end
}

-- Create migration backup
function VersionManager:CreateMigrationBackup(fromVersion)
    -- In a real addon, this would create a backup of settings
    -- For our implementation, we'll just log the action
    API.PrintDebug("Creating settings backup before migration from " .. fromVersion)
}

-- Execute migration
function VersionManager:ExecuteMigration(migration)
    -- Log start
    API.PrintDebug("Executing migration: " .. migration.description)
    
    -- Execute migration function
    local success = migration.migrationFunction()
    
    -- Log result
    if success then
        API.PrintDebug("Migration successful")
        
        -- Record in migration status
        migrationStatus[migration.fromVersion .. "-" .. migration.toVersion] = {
            completed = true,
            timestamp = time(),
            description = migration.description
        }
    else
        API.PrintDebug("Migration failed")
        
        -- Record in migration status
        migrationStatus[migration.fromVersion .. "-" .. migration.toVersion] = {
            completed = false,
            timestamp = time(),
            description = migration.description
        }
    end
}

-- Check feature availability
function VersionManager:IsFeatureAvailable(featureName)
    -- Check if the feature has a version requirement
    local requiredVersion = FEATURE_VERSIONS[featureName]
    
    if not requiredVersion then
        return true -- No requirement specified, assume available
    end
    
    -- Check if current version meets requirement
    return self:CompareVersions(CURRENT_VERSION, requiredVersion) >= 0
end

-- Get current version
function VersionManager:GetCurrentVersion()
    return CURRENT_VERSION
end

-- Get build number
function VersionManager:GetBuildNumber()
    return BUILD_NUMBER
end

-- Get release type
function VersionManager:GetReleaseType()
    return RELEASE_TYPE
end

-- Get module versions
function VersionManager:GetModuleVersions()
    return moduleVersions
end

-- Is update available
function VersionManager:IsUpdateAvailable()
    return updateAvailable
end

-- Get latest version
function VersionManager:GetLatestVersion()
    return latestVersion
end

-- Get version history
function VersionManager:GetVersionHistory()
    return versionHistory
end

-- Get pending migrations
function VersionManager:GetPendingMigrations()
    return pendingMigrations
end

-- Get migration status
function VersionManager:GetMigrationStatus()
    return migrationStatus
end

-- Force version check
function VersionManager:ForceVersionCheck()
    -- Force immediate version check
    isVersionCheckActive = true
    versionFrame:Show()
    
    -- Log action
    API.PrintMessage("Checking for updates...")
    
    return true
}

-- Update module version
function VersionManager:UpdateModuleVersion(moduleName, version)
    if not moduleVersions[moduleName] or self:CompareVersions(version, moduleVersions[moduleName]) > 0 then
        moduleVersions[moduleName] = version
        return true
    end
    
    return false
}

-- Return the module
return VersionManager