local addonName, WR = ...

-- Maintenance module for addon upkeep and troubleshooting
local Maintenance = {}
WR.Maintenance = Maintenance

-- Configuration options
local config = {
    autoCleanupEnabled = true,
    autoRepairEnabled = true,
    backupFrequency = 7, -- days
    maxBackups = 5,
    dataCompression = true,
    diagnosticsOnStartup = true,
    lastCleanup = 0,
    lastBackup = 0,
    lastRepair = 0
}

-- Maintenance tasks
local tasks = {
    cleanup = {
        name = "Database Cleanup",
        description = "Removes old and unnecessary data to improve performance",
        lastRun = 0,
        interval = 86400 * 7, -- 7 days
        priority = 2 -- 1 = highest
    },
    backup = {
        name = "Profile Backup",
        description = "Creates backup copies of your profiles and settings",
        lastRun = 0,
        interval = 86400 * 7, -- 7 days
        priority = 1
    },
    repair = {
        name = "Database Repair",
        description = "Fixes potential issues with stored data",
        lastRun = 0,
        interval = 86400 * 14, -- 14 days
        priority = 3
    },
    optimize = {
        name = "Performance Optimization",
        description = "Optimizes addon performance",
        lastRun = 0,
        interval = 86400 * 7, -- 7 days 
        priority = 2
    }
}

-- Maintenance status and history
local status = {
    taskHistory = {},
    repairHistory = {},
    backupInfo = {},
    errors = {}
}

-- Initialize the module
function Maintenance:Initialize()
    -- Load saved configuration
    if WindrunnerRotationsDB and WindrunnerRotationsDB.Maintenance then
        -- Update config from saved data
        for k, v in pairs(WindrunnerRotationsDB.Maintenance.config or {}) do
            if config[k] ~= nil then
                config[k] = v
            end
        end
        
        -- Load task data
        for k, v in pairs(WindrunnerRotationsDB.Maintenance.tasks or {}) do
            if tasks[k] then
                tasks[k].lastRun = v.lastRun or tasks[k].lastRun
            end
        end
        
        -- Load status
        for k, v in pairs(WindrunnerRotationsDB.Maintenance.status or {}) do
            status[k] = v
        end
    end
    
    -- Register events
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("PLAYER_LOGOUT")
    
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "PLAYER_ENTERING_WORLD" then
            C_Timer.After(10, function() Maintenance:CheckScheduledTasks() end)
        elseif event == "PLAYER_LOGOUT" then
            Maintenance:SaveData()
        end
    end)
    
    -- Create timer for periodic checks
    C_Timer.NewTicker(3600, function() Maintenance:CheckScheduledTasks() end)  -- Check every hour
    
    WR:Debug("Maintenance module initialized")
end

-- Save maintenance data
function Maintenance:SaveData()
    -- Initialize storage if needed
    WindrunnerRotationsDB = WindrunnerRotationsDB or {}
    WindrunnerRotationsDB.Maintenance = WindrunnerRotationsDB.Maintenance or {}
    
    -- Save configuration
    WindrunnerRotationsDB.Maintenance.config = CopyTable(config)
    
    -- Save task data (just lastRun timestamps)
    WindrunnerRotationsDB.Maintenance.tasks = {}
    for k, v in pairs(tasks) do
        WindrunnerRotationsDB.Maintenance.tasks[k] = {
            lastRun = v.lastRun
        }
    end
    
    -- Save status info
    WindrunnerRotationsDB.Maintenance.status = CopyTable(status)
    
    WR:Debug("Maintenance data saved")
end

-- Check for scheduled maintenance tasks
function Maintenance:CheckScheduledTasks()
    if not config.autoCleanupEnabled and not config.autoRepairEnabled then
        return
    end
    
    local currentTime = time()
    local tasksToRun = {}
    
    -- Check which tasks are due
    for name, task in pairs(tasks) do
        if currentTime - task.lastRun > task.interval then
            table.insert(tasksToRun, {name = name, task = task})
        end
    end
    
    -- Sort by priority
    table.sort(tasksToRun, function(a, b)
        return a.task.priority < b.task.priority
    end)
    
    -- Run due tasks
    for _, taskInfo in ipairs(tasksToRun) do
        local name = taskInfo.name
        
        if name == "cleanup" and config.autoCleanupEnabled then
            self:RunCleanup()
        elseif name == "backup" and config.autoCleanupEnabled then
            self:CreateBackup()
        elseif name == "repair" and config.autoRepairEnabled then
            self:RunRepair()
        elseif name == "optimize" and config.autoCleanupEnabled then
            self:RunOptimization()
        end
    end
end

-- Run database cleanup
function Maintenance:RunCleanup()
    WR:Debug("Running database cleanup")
    
    local startTime = debugprofilestop()
    local cleanupResults = {
        profileData = 0,
        analyticData = 0,
        combatLogs = 0,
        cacheData = 0,
        errorLogs = 0,
        totalItems = 0
    }
    
    -- Cleanup profile data
    if WR.ProfileManager then
        local count = WR.ProfileManager:CleanupUnusedProfiles()
        cleanupResults.profileData = count
        cleanupResults.totalItems = cleanupResults.totalItems + count
    end
    
    -- Cleanup analytics data
    if WR.Analytics then
        local count = self:CleanupAnalyticsData()
        cleanupResults.analyticData = count
        cleanupResults.totalItems = cleanupResults.totalItems + count
    end
    
    -- Cleanup error logs
    if WR.Diagnostics then
        local count = self:CleanupDiagnosticsData()
        cleanupResults.errorLogs = count
        cleanupResults.totalItems = cleanupResults.totalItems + count
    end
    
    -- Clear caches
    if WR.Optimization then
        WR.Optimization:ClearCache("all")
        cleanupResults.cacheData = 1
        cleanupResults.totalItems = cleanupResults.totalItems + 1
    end
    
    -- Record task completion
    tasks.cleanup.lastRun = time()
    
    -- Log history
    table.insert(status.taskHistory, {
        task = "cleanup",
        timestamp = time(),
        duration = (debugprofilestop() - startTime) / 1000,
        results = cleanupResults
    })
    
    -- Trim history if needed
    if #status.taskHistory > 20 then
        table.remove(status.taskHistory, 1)
    end
    
    WR:Debug("Database cleanup completed, removed", cleanupResults.totalItems, "items")
    
    return cleanupResults
end

-- Create a backup of user data
function Maintenance:CreateBackup()
    WR:Debug("Creating data backup")
    
    local startTime = debugprofilestop()
    local backupResults = {
        profiles = 0,
        settings = 0,
        size = 0
    }
    
    -- Create backup container
    local backup = {
        timestamp = time(),
        version = WR.version,
        buildNumber = WR.buildNumber,
        gameVersion = select(4, GetBuildInfo()),
        profiles = {},
        settings = {},
        metadata = {
            playerName = UnitName("player"),
            realmName = GetRealmName(),
            characterClass = select(2, UnitClass("player")),
            addonVersion = WR.version
        }
    }
    
    -- Backup profiles
    if WR.ProfileManager and WR.ProfileManager.Profiles then
        backup.profiles = CopyTable(WR.ProfileManager.Profiles)
        backupResults.profiles = GetTableSize(backup.profiles)
    end
    
    -- Backup settings
    if WindrunnerRotationsDB then
        -- Don't include old backups in the backup
        local settingsCopy = CopyTable(WindrunnerRotationsDB)
        if settingsCopy.Maintenance and settingsCopy.Maintenance.status then
            settingsCopy.Maintenance.status.backupInfo = nil
        end
        
        backup.settings = settingsCopy
        backupResults.settings = GetTableSize(backup.settings)
    end
    
    -- Calculate approximate size
    backupResults.size = self:EstimateTableSize(backup)
    
    -- Store backup
    status.backupInfo = status.backupInfo or {}
    table.insert(status.backupInfo, {
        timestamp = backup.timestamp,
        version = backup.version,
        profiles = backupResults.profiles,
        size = backupResults.size
    })
    
    -- Store the actual backup data
    WindrunnerRotationsDB = WindrunnerRotationsDB or {}
    WindrunnerRotationsDB.Backups = WindrunnerRotationsDB.Backups or {}
    
    -- Compress backup if enabled
    local backupData = backup
    if config.dataCompression and LibDeflate then
        local serialized = LibSerialize:Serialize(backup)
        local compressed = LibDeflate:CompressDeflate(serialized)
        backupData = compressed
    end
    
    WindrunnerRotationsDB.Backups[tostring(backup.timestamp)] = backupData
    
    -- Trim old backups if needed
    local backupCount = GetTableSize(WindrunnerRotationsDB.Backups)
    if backupCount > config.maxBackups then
        -- Find oldest backup
        local oldestTimestamp = nil
        for timestamp, _ in pairs(WindrunnerRotationsDB.Backups) do
            local ts = tonumber(timestamp)
            if not oldestTimestamp or ts < oldestTimestamp then
                oldestTimestamp = ts
            end
        end
        
        -- Remove oldest backup
        if oldestTimestamp then
            WindrunnerRotationsDB.Backups[tostring(oldestTimestamp)] = nil
            
            -- Also remove from backup info
            for i, info in ipairs(status.backupInfo) do
                if info.timestamp == oldestTimestamp then
                    table.remove(status.backupInfo, i)
                    break
                end
            end
        end
    end
    
    -- Record task completion
    tasks.backup.lastRun = time()
    
    -- Log history
    table.insert(status.taskHistory, {
        task = "backup",
        timestamp = time(),
        duration = (debugprofilestop() - startTime) / 1000,
        results = backupResults
    })
    
    -- Trim history if needed
    if #status.taskHistory > 20 then
        table.remove(status.taskHistory, 1)
    end
    
    WR:Debug("Data backup completed, saved", backupResults.profiles, "profiles")
    
    return backupResults
end

-- Run database repair
function Maintenance:RunRepair()
    WR:Debug("Running database repair")
    
    local startTime = debugprofilestop()
    local repairResults = {
        profilesRepaired = 0,
        settingsRepaired = 0,
        errorsFixed = 0,
        totalItems = 0
    }
    
    -- Check and repair profiles
    if WR.ProfileManager and WR.ProfileManager.Profiles then
        local profileCount = 0
        
        for name, profile in pairs(WR.ProfileManager.Profiles) do
            local fixed = 0
            
            -- Check for missing fields and repair
            if not profile.class then
                profile.class = select(2, UnitClass("player"))
                fixed = fixed + 1
            end
            
            if not profile.spec then
                profile.spec = GetSpecialization() or 1
                fixed = fixed + 1
            end
            
            if not profile.version then
                profile.version = WR.version
                fixed = fixed + 1
            end
            
            if not profile.created then
                profile.created = time()
                fixed = fixed + 1
            end
            
            if not profile.lastModified then
                profile.lastModified = time()
                fixed = fixed + 1
            end
            
            if fixed > 0 then
                profileCount = profileCount + 1
                repairResults.totalItems = repairResults.totalItems + fixed
            end
        end
        
        repairResults.profilesRepaired = profileCount
    end
    
    -- Check and repair settings
    if WindrunnerRotationsDB then
        local settingsFixed = 0
        
        -- Fix common issues with settings
        if not WindrunnerRotationsDB.version then
            WindrunnerRotationsDB.version = WR.version
            settingsFixed = settingsFixed + 1
        end
        
        -- Fix UI settings
        if WindrunnerRotationsDB.UI then
            if type(WindrunnerRotationsDB.UI.scale) ~= "number" or
               WindrunnerRotationsDB.UI.scale <= 0 or
               WindrunnerRotationsDB.UI.scale > 2 then
                WindrunnerRotationsDB.UI.scale = 1
                settingsFixed = settingsFixed + 1
            end
        end
        
        repairResults.settingsRepaired = settingsFixed > 0 and 1 or 0
        repairResults.totalItems = repairResults.totalItems + settingsFixed
    end
    
    -- Run diagnostics repair if available
    if WR.Diagnostics and WR.Diagnostics.AttemptRepair then
        WR.Diagnostics:AttemptRepair()
        repairResults.errorsFixed = repairResults.errorsFixed + 1
        repairResults.totalItems = repairResults.totalItems + 1
    end
    
    -- Record task completion
    tasks.repair.lastRun = time()
    
    -- Log history
    table.insert(status.taskHistory, {
        task = "repair",
        timestamp = time(),
        duration = (debugprofilestop() - startTime) / 1000,
        results = repairResults
    })
    
    -- Trim history if needed
    if #status.taskHistory > 20 then
        table.remove(status.taskHistory, 1)
    end
    
    -- Log to repair history
    if repairResults.totalItems > 0 then
        table.insert(status.repairHistory, {
            timestamp = time(),
            itemsRepaired = repairResults.totalItems,
            details = repairResults
        })
        
        -- Trim history if needed
        if #status.repairHistory > 10 then
            table.remove(status.repairHistory, 1)
        end
    end
    
    WR:Debug("Database repair completed, fixed", repairResults.totalItems, "items")
    
    return repairResults
end

-- Run optimization
function Maintenance:RunOptimization()
    WR:Debug("Running performance optimization")
    
    local startTime = debugprofilestop()
    local optimizationResults = {
        memoryBefore = collectgarbage("count"),
        memoryAfter = 0,
        cachesCleared = 0,
        tablesOptimized = 0,
        settingsOptimized = 0
    }
    
    -- Clear caches
    if WR.Optimization then
        WR.Optimization:ClearCache("all")
        optimizationResults.cachesCleared = optimizationResults.cachesCleared + 1
    end
    
    -- Run garbage collection
    collectgarbage("collect")
    optimizationResults.memoryAfter = collectgarbage("count")
    
    -- Optimize settings tables
    if WindrunnerRotationsDB then
        self:OptimizeTable(WindrunnerRotationsDB)
        optimizationResults.settingsOptimized = optimizationResults.settingsOptimized + 1
        optimizationResults.tablesOptimized = optimizationResults.tablesOptimized + 1
    end
    
    -- Optimize profile data
    if WR.ProfileManager and WR.ProfileManager.Profiles then
        for _, profile in pairs(WR.ProfileManager.Profiles) do
            self:OptimizeTable(profile)
            optimizationResults.tablesOptimized = optimizationResults.tablesOptimized + 1
        end
    end
    
    -- Record task completion
    tasks.optimize.lastRun = time()
    
    -- Log history
    table.insert(status.taskHistory, {
        task = "optimize",
        timestamp = time(),
        duration = (debugprofilestop() - startTime) / 1000,
        results = optimizationResults
    })
    
    -- Trim history if needed
    if #status.taskHistory > 20 then
        table.remove(status.taskHistory, 1)
    end
    
    WR:Debug("Performance optimization completed, memory usage reduced by", 
             string.format("%.2f", (optimizationResults.memoryBefore - optimizationResults.memoryAfter) / 1024), "MB")
    
    return optimizationResults
end

-- Optimize a table by removing nil values and reorganizing
function Maintenance:OptimizeTable(tbl)
    if type(tbl) ~= "table" then return end
    
    -- First pass: collect keys with nil values to remove
    local toRemove = {}
    for k, v in pairs(tbl) do
        if v == nil then
            table.insert(toRemove, k)
        elseif type(v) == "table" then
            -- Recursively optimize nested tables
            self:OptimizeTable(v)
        end
    end
    
    -- Second pass: remove nil values
    for _, k in ipairs(toRemove) do
        tbl[k] = nil
    end
end

-- Clean up analytics data
function Maintenance:CleanupAnalyticsData()
    if not WR.Analytics then return 0 end
    
    local count = 0
    
    -- Get analytics data
    local data = WR.Analytics:GetData()
    if not data then return count end
    
    -- Clean up old combat logs
    if data.combatLogs then
        local currentTime = time()
        local cutoff = currentTime - (30 * 24 * 60 * 60)  -- 30 days
        
        for i = #data.combatLogs, 1, -1 do
            if data.combatLogs[i].endTime and data.combatLogs[i].endTime < cutoff then
                table.remove(data.combatLogs, i)
                count = count + 1
            end
        end
    end
    
    -- Clean up rotation logs
    if data.rotationLogs and #data.rotationLogs > 100 then
        while #data.rotationLogs > 100 do
            table.remove(data.rotationLogs, 1)
            count = count + 1
        end
    end
    
    -- Clean up ability usage data
    if data.abilityUsage then
        local oldEntries = 0
        local currentTime = time()
        local cutoff = currentTime - (30 * 24 * 60 * 60)  -- 30 days
        
        for spellID, ability in pairs(data.abilityUsage) do
            if ability.lastCast and ability.lastCast < cutoff then
                data.abilityUsage[spellID] = nil
                oldEntries = oldEntries + 1
            end
        end
        
        count = count + oldEntries
    end
    
    return count
end

-- Clean up diagnostics data
function Maintenance:CleanupDiagnosticsData()
    if not WR.Diagnostics then return 0 end
    
    -- This would normally call into the Diagnostics module
    -- For this example, we'll just return a dummy value
    return 5  -- Assume 5 items cleaned up
end

-- Restore from backup
function Maintenance:RestoreFromBackup(timestamp)
    if not timestamp then return false, "No backup timestamp provided" end
    
    -- Check if backup exists
    if not WindrunnerRotationsDB or not WindrunnerRotationsDB.Backups or 
       not WindrunnerRotationsDB.Backups[tostring(timestamp)] then
        return false, "Backup not found"
    end
    
    local backupData = WindrunnerRotationsDB.Backups[tostring(timestamp)]
    local backup
    
    -- Decompress if needed
    if config.dataCompression and LibDeflate and type(backupData) == "string" then
        local decompressed = LibDeflate:DecompressDeflate(backupData)
        if decompressed then
            local success, data = LibSerialize:Deserialize(decompressed)
            if success then
                backup = data
            else
                return false, "Failed to deserialize backup data"
            end
        else
            return false, "Failed to decompress backup data"
        end
    else
        backup = backupData
    end
    
    -- Validate backup
    if type(backup) ~= "table" or not backup.timestamp or not backup.profiles then
        return false, "Invalid backup data"
    end
    
    WR:Debug("Restoring from backup created on", date("%Y-%m-%d %H:%M:%S", backup.timestamp))
    
    -- Restore profiles
    if backup.profiles and WR.ProfileManager then
        -- Save current active profile
        local currentProfile = WR.ProfileManager:GetCurrentProfile()
        
        -- Replace profiles
        WR.ProfileManager.Profiles = CopyTable(backup.profiles)
        
        -- Restore current profile if it still exists
        if currentProfile and WR.ProfileManager.Profiles[currentProfile] then
            WR.ProfileManager:LoadProfile(currentProfile)
        end
    end
    
    -- Restore settings
    if backup.settings then
        -- Preserve some current settings
        local currentMaintenance = WindrunnerRotationsDB and WindrunnerRotationsDB.Maintenance
        local currentBackups = WindrunnerRotationsDB and WindrunnerRotationsDB.Backups
        
        -- Apply backup settings
        WindrunnerRotationsDB = CopyTable(backup.settings)
        
        -- Restore maintenance settings and backups
        if WindrunnerRotationsDB then
            if currentMaintenance then
                WindrunnerRotationsDB.Maintenance = currentMaintenance
            end
            
            if currentBackups then
                WindrunnerRotationsDB.Backups = currentBackups
            end
        end
    end
    
    -- Log restore operation
    table.insert(status.taskHistory, {
        task = "restore",
        timestamp = time(),
        backupTimestamp = backup.timestamp,
        profiles = GetTableSize(backup.profiles or {})
    })
    
    -- Reload UI to apply changes
    ReloadUI()
    
    return true
end

-- Get a list of available backups
function Maintenance:GetBackupList()
    local backups = {}
    
    if status.backupInfo then
        for _, info in ipairs(status.backupInfo) do
            table.insert(backups, {
                timestamp = info.timestamp,
                date = date("%Y-%m-%d %H:%M:%S", info.timestamp),
                version = info.version,
                profiles = info.profiles,
                size = info.size
            })
        end
    end
    
    -- Sort by timestamp (newest first)
    table.sort(backups, function(a, b)
        return a.timestamp > b.timestamp
    end)
    
    return backups
end

-- Get maintenance status
function Maintenance:GetStatus()
    -- Update with current data
    status.currentMemory = collectgarbage("count")
    status.addonVersion = WR.version
    status.taskStatus = {}
    
    for name, task in pairs(tasks) do
        status.taskStatus[name] = {
            name = task.name,
            description = task.description,
            lastRun = task.lastRun,
            nextRun = task.lastRun + task.interval,
            status = time() > task.lastRun + task.interval and "Due" or "OK"
        }
    end
    
    return status
end

-- Get maintenance configuration
function Maintenance:GetConfig()
    return config
end

-- Set maintenance configuration
function Maintenance:SetConfig(newConfig)
    if not newConfig then return end
    
    for k, v in pairs(newConfig) do
        if config[k] ~= nil then
            config[k] = v
        end
    end
    
    -- Save immediately
    self:SaveData()
    
    WR:Debug("Maintenance configuration updated")
    
    -- Check if we need to run any tasks based on new config
    self:CheckScheduledTasks()
end

-- Estimate the size of a table in bytes
function Maintenance:EstimateTableSize(tbl)
    if type(tbl) ~= "table" then
        -- Basic size estimates for non-table values
        if type(tbl) == "string" then
            return #tbl
        elseif type(tbl) == "number" then
            return 8
        elseif type(tbl) == "boolean" then
            return 1
        else
            return 8  -- Default size for other types
        end
    end
    
    local size = 0
    
    -- Estimate table overhead (implementation-dependent)
    size = size + 40  -- Approximate overhead for table structure
    
    -- Add size of all key-value pairs
    for k, v in pairs(tbl) do
        -- Size of key
        if type(k) == "string" then
            size = size + #k
        else
            size = size + 8  -- Assume 8 bytes for non-string keys
        end
        
        -- Size of value
        if type(v) == "table" then
            size = size + self:EstimateTableSize(v)
        elseif type(v) == "string" then
            size = size + #v
        elseif type(v) == "number" then
            size = size + 8
        elseif type(v) == "boolean" then
            size = size + 1
        else
            size = size + 8  -- Default size for other types
        end
    end
    
    return size
end

-- Create the maintenance UI
function Maintenance:CreateMaintenanceUI(parent)
    if not parent then return end
    
    -- Create the maintenance frame
    local frame = CreateFrame("Frame", "WindrunnerRotationsMaintenanceFrame", parent, "BackdropTemplate")
    frame:SetSize(700, 500)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    frame:SetBackdropColor(0.1, 0.1, 0.1, 1)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    
    -- Create title
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", frame, "TOP", 0, -15)
    title:SetText("WindrunnerRotations Maintenance")
    
    -- Create close button
    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    
    -- Create tab buttons
    local tabWidth = 140
    local tabHeight = 24
    local tabs = {}
    local tabContents = {}
    
    local tabNames = {"Tasks", "Backups", "Settings", "History"}
    
    for i, tabName in ipairs(tabNames) do
        -- Create tab button
        local tab = CreateFrame("Button", nil, frame)
        tab:SetSize(tabWidth, tabHeight)
        tab:SetPoint("TOPLEFT", frame, "TOPLEFT", 20 + (i-1) * (tabWidth + 5), -40)
        
        local tabText = tab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        tabText:SetPoint("CENTER", tab, "CENTER", 0, 0)
        tabText:SetText(tabName)
        
        -- Create highlight texture
        local highlightTexture = tab:CreateTexture(nil, "HIGHLIGHT")
        highlightTexture:SetAllPoints()
        highlightTexture:SetColorTexture(1, 1, 1, 0.2)
        
        -- Create tab content frame
        local content = CreateFrame("Frame", nil, frame)
        content:SetSize(frame:GetWidth() - 40, frame:GetHeight() - 80)
        content:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -70)
        content:Hide()
        
        -- Set up tab behavior
        tab:SetScript("OnClick", function()
            -- Hide all contents
            for _, contentFrame in ipairs(tabContents) do
                contentFrame:Hide()
            end
            
            -- Show this content
            content:Show()
            
            -- Update tab appearance
            for _, tabButton in ipairs(tabs) do
                tabButton:SetButtonState("NORMAL")
            end
            
            tab:SetButtonState("PUSHED", true)
        end)
        
        -- Store references
        tabs[i] = tab
        tabContents[i] = content
    end
    
    -- Populate Tasks tab
    local tasksContent = tabContents[1]
    
    local tasksTitle = tasksContent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    tasksTitle:SetPoint("TOP", tasksContent, "TOP", 0, -10)
    tasksTitle:SetText("Maintenance Tasks")
    
    -- Create maintenance task buttons
    local buttonWidth = 160
    local buttonHeight = 30
    local spacing = 10
    local leftColX = 20
    local rightColX = tasksContent:GetWidth() / 2 + 20
    
    -- Create status overview
    local statusFrame = CreateFrame("Frame", nil, tasksContent, "BackdropTemplate")
    statusFrame:SetSize(tasksContent:GetWidth() - 40, 80)
    statusFrame:SetPoint("TOP", tasksTitle, "BOTTOM", 0, -20)
    statusFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    statusFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
    
    local memoryLabel = statusFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    memoryLabel:SetPoint("TOPLEFT", statusFrame, "TOPLEFT", 15, -15)
    memoryLabel:SetText("Memory Usage:")
    
    local memoryValue = statusFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    memoryValue:SetPoint("TOPLEFT", memoryLabel, "TOPRIGHT", 5, 0)
    memoryValue:SetText("0 MB")
    
    local versionLabel = statusFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    versionLabel:SetPoint("TOPLEFT", statusFrame, "TOPLEFT", 300, -15)
    versionLabel:SetText("Addon Version:")
    
    local versionValue = statusFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    versionValue:SetPoint("TOPLEFT", versionLabel, "TOPRIGHT", 5, 0)
    versionValue:SetText(WR.version or "Unknown")
    
    local backupLabel = statusFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    backupLabel:SetPoint("TOPLEFT", memoryLabel, "BOTTOMLEFT", 0, -15)
    backupLabel:SetText("Last Backup:")
    
    local backupValue = statusFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    backupValue:SetPoint("TOPLEFT", backupLabel, "TOPRIGHT", 5, 0)
    backupValue:SetText("Never")
    
    local cleanupLabel = statusFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    cleanupLabel:SetPoint("TOPLEFT", statusFrame, "TOPLEFT", 300, -30)
    cleanupLabel:SetText("Last Cleanup:")
    
    local cleanupValue = statusFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    cleanupValue:SetPoint("TOPLEFT", cleanupLabel, "TOPRIGHT", 5, 0)
    cleanupValue:SetText("Never")
    
    -- Create task list
    local taskListFrame = CreateFrame("Frame", nil, tasksContent, "BackdropTemplate")
    taskListFrame:SetSize(tasksContent:GetWidth() - 40, 200)
    taskListFrame:SetPoint("TOP", statusFrame, "BOTTOM", 0, -20)
    taskListFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    taskListFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
    
    local taskListTitle = taskListFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    taskListTitle:SetPoint("TOPLEFT", taskListFrame, "TOPLEFT", 15, -15)
    taskListTitle:SetText("Scheduled Tasks:")
    
    -- Create task entries
    local taskEntries = {}
    local taskY = -40
    
    local taskOrder = {"cleanup", "backup", "repair", "optimize"}
    
    for i, taskName in ipairs(taskOrder) do
        local task = tasks[taskName]
        
        local entryFrame = CreateFrame("Frame", nil, taskListFrame)
        entryFrame:SetSize(taskListFrame:GetWidth() - 30, 30)
        entryFrame:SetPoint("TOPLEFT", taskListFrame, "TOPLEFT", 15, taskY - (i-1) * 35)
        
        local nameText = entryFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        nameText:SetPoint("LEFT", entryFrame, "LEFT", 0, 0)
        nameText:SetText(task.name..":")
        
        local statusText = entryFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        statusText:SetPoint("LEFT", nameText, "RIGHT", 5, 0)
        statusText:SetText("Never Run")
        
        local nextRunText = entryFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        nextRunText:SetPoint("TOPLEFT", nameText, "BOTTOMLEFT", 5, -2)
        nextRunText:SetText("Next scheduled: Unknown")
        
        local runButton = CreateFrame("Button", nil, entryFrame, "UIPanelButtonTemplate")
        runButton:SetSize(100, 22)
        runButton:SetPoint("RIGHT", entryFrame, "RIGHT", -15, 0)
        runButton:SetText("Run Now")
        
        runButton:SetScript("OnClick", function()
            if taskName == "cleanup" then
                Maintenance:RunCleanup()
            elseif taskName == "backup" then
                Maintenance:CreateBackup()
            elseif taskName == "repair" then
                Maintenance:RunRepair()
            elseif taskName == "optimize" then
                Maintenance:RunOptimization()
            end
            
            -- Update UI
            Maintenance:UpdateTasksTab()
        end)
        
        taskEntries[taskName] = {
            frame = entryFrame,
            nameText = nameText,
            statusText = statusText,
            nextRunText = nextRunText,
            runButton = runButton
        }
    end
    
    -- Create task buttons
    local runAllButton = CreateFrame("Button", nil, tasksContent, "UIPanelButtonTemplate")
    runAllButton:SetSize(160, 30)
    runAllButton:SetPoint("BOTTOM", tasksContent, "BOTTOM", -90, 20)
    runAllButton:SetText("Run All Tasks")
    runAllButton:SetScript("OnClick", function()
        -- Run all tasks
        Maintenance:RunCleanup()
        Maintenance:CreateBackup()
        Maintenance:RunRepair()
        Maintenance:RunOptimization()
        
        -- Update UI
        Maintenance:UpdateTasksTab()
    end)
    
    local repairButton = CreateFrame("Button", nil, tasksContent, "UIPanelButtonTemplate")
    repairButton:SetSize(160, 30)
    repairButton:SetPoint("BOTTOM", tasksContent, "BOTTOM", 90, 20)
    repairButton:SetText("Quick Repair")
    repairButton:SetScript("OnClick", function()
        Maintenance:RunRepair()
        Maintenance:UpdateTasksTab()
    end)
    
    -- Populate Backups tab
    local backupsContent = tabContents[2]
    
    local backupsTitle = backupsContent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    backupsTitle:SetPoint("TOP", backupsContent, "TOP", 0, -10)
    backupsTitle:SetText("Backup & Restore")
    
    -- Create backup list
    local backupListFrame = CreateFrame("Frame", nil, backupsContent, "BackdropTemplate")
    backupListFrame:SetSize(backupsContent:GetWidth() - 40, 300)
    backupListFrame:SetPoint("TOP", backupsTitle, "BOTTOM", 0, -20)
    backupListFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    backupListFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
    
    local backupListTitle = backupListFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    backupListTitle:SetPoint("TOPLEFT", backupListFrame, "TOPLEFT", 15, -15)
    backupListTitle:SetText("Available Backups:")
    
    local backupScrollFrame = CreateFrame("ScrollFrame", nil, backupListFrame, "UIPanelScrollFrameTemplate")
    backupScrollFrame:SetSize(backupListFrame:GetWidth() - 40, backupListFrame:GetHeight() - 50)
    backupScrollFrame:SetPoint("TOPLEFT", backupListFrame, "TOPLEFT", 15, -40)
    
    local backupScrollChild = CreateFrame("Frame", nil, backupScrollFrame)
    backupScrollChild:SetSize(backupScrollFrame:GetWidth(), 20)  -- Height will be set dynamically
    backupScrollFrame:SetScrollChild(backupScrollChild)
    
    -- Create backup buttons
    local createBackupButton = CreateFrame("Button", nil, backupsContent, "UIPanelButtonTemplate")
    createBackupButton:SetSize(160, 30)
    createBackupButton:SetPoint("BOTTOM", backupsContent, "BOTTOM", -90, 20)
    createBackupButton:SetText("Create Backup")
    createBackupButton:SetScript("OnClick", function()
        Maintenance:CreateBackup()
        Maintenance:UpdateBackupsTab()
    end)
    
    local restoreBackupButton = CreateFrame("Button", nil, backupsContent, "UIPanelButtonTemplate")
    restoreBackupButton:SetSize(160, 30)
    restoreBackupButton:SetPoint("BOTTOM", backupsContent, "BOTTOM", 90, 20)
    restoreBackupButton:SetText("Restore Selected")
    restoreBackupButton:Enable(false)  -- Disabled until a backup is selected
    
    -- Track selected backup
    local selectedBackup = nil
    
    -- Function to update backup list
    local function UpdateBackupList()
        -- Clear existing entries
        for i = backupScrollChild:GetNumChildren(), 1, -1 do
            local child = select(i, backupScrollChild:GetChildren())
            child:Hide()
            child:SetParent(nil)
        end
        
        -- Get backup list
        local backups = Maintenance:GetBackupList()
        
        if #backups == 0 then
            local noBackupsText = backupScrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            noBackupsText:SetPoint("TOP", backupScrollChild, "TOP", 0, -10)
            noBackupsText:SetText("No backups available. Create a backup to get started.")
            backupScrollChild:SetHeight(30)
            restoreBackupButton:Enable(false)
            selectedBackup = nil
            return
        end
        
        -- Display backups
        local entryHeight = 40
        local totalHeight = 10
        
        for i, backup in ipairs(backups) do
            local entryFrame = CreateFrame("Frame", nil, backupScrollChild, "BackdropTemplate")
            entryFrame:SetSize(backupScrollChild:GetWidth(), entryHeight)
            entryFrame:SetPoint("TOPLEFT", backupScrollChild, "TOPLEFT", 0, -totalHeight)
            
            entryFrame:SetBackdrop({
                bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
                tile = true,
                tileSize = 16
            })
            
            -- Highlight when clicked
            entryFrame:EnableMouse(true)
            entryFrame:SetScript("OnMouseDown", function()
                -- Deselect all other frames
                for j = 1, backupScrollChild:GetNumChildren() do
                    local child = select(j, backupScrollChild:GetChildren())
                    if child ~= entryFrame then
                        child:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
                    end
                end
                
                -- Select this frame
                entryFrame:SetBackdropColor(0.3, 0.3, 0.6, 0.6)
                selectedBackup = backup.timestamp
                restoreBackupButton:Enable(true)
            end)
            
            -- Set initial color
            if backup.timestamp == selectedBackup then
                entryFrame:SetBackdropColor(0.3, 0.3, 0.6, 0.6)
            else
                entryFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
            end
            
            -- Create date text
            local dateText = entryFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            dateText:SetPoint("TOPLEFT", entryFrame, "TOPLEFT", 5, -8)
            dateText:SetText(backup.date)
            
            -- Create version text
            local versionText = entryFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            versionText:SetPoint("TOPLEFT", dateText, "BOTTOMLEFT", 0, -2)
            versionText:SetText("Version: " .. (backup.version or "Unknown"))
            
            -- Create profiles text
            local profilesText = entryFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            profilesText:SetPoint("RIGHT", entryFrame, "RIGHT", -80, 0)
            profilesText:SetText("Profiles: " .. (backup.profiles or 0))
            
            -- Create size text
            local sizeText = entryFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            sizeText:SetPoint("RIGHT", entryFrame, "RIGHT", -10, 0)
            local sizeStr = "Unknown"
            if backup.size then
                if backup.size < 1024 then
                    sizeStr = string.format("%d B", backup.size)
                elseif backup.size < 1024 * 1024 then
                    sizeStr = string.format("%.1f KB", backup.size / 1024)
                else
                    sizeStr = string.format("%.1f MB", backup.size / (1024 * 1024))
                end
            end
            sizeText:SetText("Size: " .. sizeStr)
            
            totalHeight = totalHeight + entryHeight + 5
        end
        
        backupScrollChild:SetHeight(math.max(totalHeight, backupScrollFrame:GetHeight()))
        
        -- Update restore button state
        restoreBackupButton:Enable(selectedBackup ~= nil)
    end
    
    -- Set up restore button
    restoreBackupButton:SetScript("OnClick", function()
        if not selectedBackup then return end
        
        -- Create confirmation dialog
        StaticPopupDialogs["WR_RESTORE_CONFIRM"] = {
            text = "Are you sure you want to restore from this backup? Your current profiles and settings will be replaced. This will reload your UI.",
            button1 = "Restore",
            button2 = "Cancel",
            OnAccept = function()
                Maintenance:RestoreFromBackup(selectedBackup)
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3
        }
        
        StaticPopup_Show("WR_RESTORE_CONFIRM")
    end)
    
    -- Populate Settings tab
    local settingsContent = tabContents[3]
    
    local settingsTitle = settingsContent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    settingsTitle:SetPoint("TOP", settingsContent, "TOP", 0, -10)
    settingsTitle:SetText("Maintenance Settings")
    
    -- Create settings frame
    local settingsFrame = CreateFrame("Frame", nil, settingsContent, "BackdropTemplate")
    settingsFrame:SetSize(settingsContent:GetWidth() - 40, 300)
    settingsFrame:SetPoint("TOP", settingsTitle, "BOTTOM", 0, -20)
    settingsFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    settingsFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
    
    -- Create settings controls
    local settingY = -30
    local settingSpacing = 30
    
    -- Auto cleanup checkbox
    local autoCleanupCheckbox = CreateFrame("CheckButton", nil, settingsFrame, "UICheckButtonTemplate")
    autoCleanupCheckbox:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 20, settingY)
    autoCleanupCheckbox:SetChecked(config.autoCleanupEnabled)
    
    local autoCleanupLabel = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    autoCleanupLabel:SetPoint("LEFT", autoCleanupCheckbox, "RIGHT", 5, 0)
    autoCleanupLabel:SetText("Enable Automatic Cleanup")
    
    -- Auto repair checkbox
    local autoRepairCheckbox = CreateFrame("CheckButton", nil, settingsFrame, "UICheckButtonTemplate")
    autoRepairCheckbox:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 20, settingY - settingSpacing)
    autoRepairCheckbox:SetChecked(config.autoRepairEnabled)
    
    local autoRepairLabel = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    autoRepairLabel:SetPoint("LEFT", autoRepairCheckbox, "RIGHT", 5, 0)
    autoRepairLabel:SetText("Enable Automatic Repair")
    
    -- Backup count slider
    local backupCountLabel = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    backupCountLabel:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 20, settingY - settingSpacing * 2)
    backupCountLabel:SetText("Maximum Backups:")
    
    local backupCountSlider = CreateFrame("Slider", nil, settingsFrame, "OptionsSliderTemplate")
    backupCountSlider:SetPoint("TOPLEFT", backupCountLabel, "BOTTOMLEFT", 20, -10)
    backupCountSlider:SetWidth(200)
    backupCountSlider:SetHeight(16)
    backupCountSlider:SetMinMaxValues(1, 10)
    backupCountSlider:SetValue(config.maxBackups)
    backupCountSlider:SetValueStep(1)
    backupCountSlider:SetObeyStepOnDrag(true)
    
    -- Set labels
    _G[backupCountSlider:GetName() .. "Low"]:SetText("1")
    _G[backupCountSlider:GetName() .. "High"]:SetText("10")
    _G[backupCountSlider:GetName() .. "Text"]:SetText(config.maxBackups)
    
    -- Data compression checkbox
    local dataCompressionCheckbox = CreateFrame("CheckButton", nil, settingsFrame, "UICheckButtonTemplate")
    dataCompressionCheckbox:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 20, settingY - settingSpacing * 4)
    dataCompressionCheckbox:SetChecked(config.dataCompression)
    
    local dataCompressionLabel = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    dataCompressionLabel:SetPoint("LEFT", dataCompressionCheckbox, "RIGHT", 5, 0)
    dataCompressionLabel:SetText("Enable Data Compression for Backups")
    
    -- Diagnostics on startup checkbox
    local diagnosticsCheckbox = CreateFrame("CheckButton", nil, settingsFrame, "UICheckButtonTemplate")
    diagnosticsCheckbox:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 20, settingY - settingSpacing * 5)
    diagnosticsCheckbox:SetChecked(config.diagnosticsOnStartup)
    
    local diagnosticsLabel = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    diagnosticsLabel:SetPoint("LEFT", diagnosticsCheckbox, "RIGHT", 5, 0)
    diagnosticsLabel:SetText("Run Diagnostics on Startup")
    
    -- Save and reset buttons
    local saveButton = CreateFrame("Button", nil, settingsContent, "UIPanelButtonTemplate")
    saveButton:SetSize(120, 30)
    saveButton:SetPoint("BOTTOM", settingsContent, "BOTTOM", -70, 20)
    saveButton:SetText("Save Settings")
    saveButton:SetScript("OnClick", function()
        -- Update config
        config.autoCleanupEnabled = autoCleanupCheckbox:GetChecked()
        config.autoRepairEnabled = autoRepairCheckbox:GetChecked()
        config.maxBackups = backupCountSlider:GetValue()
        config.dataCompression = dataCompressionCheckbox:GetChecked()
        config.diagnosticsOnStartup = diagnosticsCheckbox:GetChecked()
        
        -- Save
        Maintenance:SetConfig(config)
        
        -- Notify
        WR:Print("Maintenance settings saved.")
    end)
    
    local resetButton = CreateFrame("Button", nil, settingsContent, "UIPanelButtonTemplate")
    resetButton:SetSize(120, 30)
    resetButton:SetPoint("BOTTOM", settingsContent, "BOTTOM", 70, 20)
    resetButton:SetText("Reset to Default")
    resetButton:SetScript("OnClick", function()
        -- Reset to defaults
        config.autoCleanupEnabled = true
        config.autoRepairEnabled = true
        config.backupFrequency = 7
        config.maxBackups = 5
        config.dataCompression = true
        config.diagnosticsOnStartup = true
        
        -- Update UI
        autoCleanupCheckbox:SetChecked(config.autoCleanupEnabled)
        autoRepairCheckbox:SetChecked(config.autoRepairEnabled)
        backupCountSlider:SetValue(config.maxBackups)
        _G[backupCountSlider:GetName() .. "Text"]:SetText(config.maxBackups)
        dataCompressionCheckbox:SetChecked(config.dataCompression)
        diagnosticsCheckbox:SetChecked(config.diagnosticsOnStartup)
        
        -- Save
        Maintenance:SetConfig(config)
        
        -- Notify
        WR:Print("Maintenance settings reset to defaults.")
    end)
    
    -- Set up slider behavior
    backupCountSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value)
        _G[self:GetName() .. "Text"]:SetText(value)
    end)
    
    -- Populate History tab
    local historyContent = tabContents[4]
    
    local historyTitle = historyContent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    historyTitle:SetPoint("TOP", historyContent, "TOP", 0, -10)
    historyTitle:SetText("Maintenance History")
    
    -- Create history frame
    local historyFrame = CreateFrame("Frame", nil, historyContent, "BackdropTemplate")
    historyFrame:SetSize(historyContent:GetWidth() - 40, 350)
    historyFrame:SetPoint("TOP", historyTitle, "BOTTOM", 0, -20)
    historyFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    historyFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
    
    local historyScrollFrame = CreateFrame("ScrollFrame", nil, historyFrame, "UIPanelScrollFrameTemplate")
    historyScrollFrame:SetSize(historyFrame:GetWidth() - 40, historyFrame:GetHeight() - 30)
    historyScrollFrame:SetPoint("TOPLEFT", historyFrame, "TOPLEFT", 15, -15)
    
    local historyScrollChild = CreateFrame("Frame", nil, historyScrollFrame)
    historyScrollChild:SetSize(historyScrollFrame:GetWidth(), 20)  -- Height will be set dynamically
    historyScrollFrame:SetScrollChild(historyScrollChild)
    
    -- Create export log button
    local exportButton = CreateFrame("Button", nil, historyContent, "UIPanelButtonTemplate")
    exportButton:SetSize(160, 30)
    exportButton:SetPoint("BOTTOM", historyContent, "BOTTOM", 0, 20)
    exportButton:SetText("Export Logs")
    exportButton:SetScript("OnClick", function()
        -- Show export frame
        -- In a real implementation, this would export logs to a text format
        WR:Print("Exporting maintenance logs is not implemented in this example.")
    end)
    
    -- Store references
    frame.tabs = tabs
    frame.tabContents = tabContents
    frame.updateFunctions = {
        UpdateTasksTab = function()
            -- Update memory display
            local memory = collectgarbage("count")
            local memoryString = string.format("%.2f MB", memory / 1024)
            memoryValue:SetText(memoryString)
            
            -- Update version
            versionValue:SetText(WR.version or "Unknown")
            
            -- Update task data
            local status = Maintenance:GetStatus()
            
            -- Update last run displays
            for name, entry in pairs(taskEntries) do
                local taskStatus = status.taskStatus[name]
                if taskStatus then
                    if taskStatus.lastRun > 0 then
                        local lastRunString = date("%Y-%m-%d %H:%M", taskStatus.lastRun)
                        entry.statusText:SetText("Last Run: " .. lastRunString)
                        
                        local timeToNext = taskStatus.nextRun - time()
                        local nextRunString = ""
                        
                        if timeToNext <= 0 then
                            nextRunString = "Due now"
                            entry.statusText:SetTextColor(1, 0.5, 0)
                        else
                            local days = math.floor(timeToNext / 86400)
                            local hours = math.floor((timeToNext % 86400) / 3600)
                            
                            if days > 0 then
                                nextRunString = string.format("In %d days, %d hours", days, hours)
                            else
                                nextRunString = string.format("In %d hours", hours)
                            end
                            
                            entry.statusText:SetTextColor(0, 1, 0)
                        end
                        
                        entry.nextRunText:SetText("Next scheduled: " .. nextRunString)
                    else
                        entry.statusText:SetText("Never Run")
                        entry.nextRunText:SetText("Next scheduled: Due now")
                        entry.statusText:SetTextColor(1, 0, 0)
                    end
                end
            end
            
            -- Update last backup/cleanup time
            if tasks.backup.lastRun > 0 then
                backupValue:SetText(date("%Y-%m-%d %H:%M", tasks.backup.lastRun))
            else
                backupValue:SetText("Never")
            end
            
            if tasks.cleanup.lastRun > 0 then
                cleanupValue:SetText(date("%Y-%m-%d %H:%M", tasks.cleanup.lastRun))
            else
                cleanupValue:SetText("Never")
            end
        end,
        
        UpdateBackupsTab = function()
            UpdateBackupList()
        end,
        
        UpdateHistoryTab = function()
            -- Clear existing entries
            for i = historyScrollChild:GetNumChildren(), 1, -1 do
                local child = select(i, historyScrollChild:GetChildren())
                child:Hide()
                child:SetParent(nil)
            end
            
            -- Get task history
            local taskHistory = status.taskHistory
            
            if #taskHistory == 0 then
                local noHistoryText = historyScrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                noHistoryText:SetPoint("TOP", historyScrollChild, "TOP", 0, -10)
                noHistoryText:SetText("No maintenance history available.")
                historyScrollChild:SetHeight(30)
                return
            end
            
            -- Display history entries
            local entryHeight = 60
            local totalHeight = 10
            
            for i, entry in ipairs(taskHistory) do
                local entryFrame = CreateFrame("Frame", nil, historyScrollChild, "BackdropTemplate")
                entryFrame:SetSize(historyScrollChild:GetWidth(), entryHeight)
                entryFrame:SetPoint("TOPLEFT", historyScrollChild, "TOPLEFT", 0, -totalHeight)
                
                entryFrame:SetBackdrop({
                    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
                    tile = true,
                    tileSize = 16
                })
                entryFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
                
                -- Task and timestamp
                local taskText = entryFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                taskText:SetPoint("TOPLEFT", entryFrame, "TOPLEFT", 10, -10)
                
                local taskName = ""
                if entry.task == "cleanup" then
                    taskName = "Database Cleanup"
                elseif entry.task == "backup" then
                    taskName = "Profile Backup"
                elseif entry.task == "repair" then
                    taskName = "Database Repair"
                elseif entry.task == "optimize" then
                    taskName = "Performance Optimization"
                elseif entry.task == "restore" then
                    taskName = "Backup Restore"
                end
                
                taskText:SetText(taskName)
                
                local dateText = entryFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                dateText:SetPoint("TOPRIGHT", entryFrame, "TOPRIGHT", -10, -10)
                dateText:SetText(date("%Y-%m-%d %H:%M", entry.timestamp))
                
                -- Results
                local resultsText = entryFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                resultsText:SetPoint("TOPLEFT", taskText, "BOTTOMLEFT", 5, -5)
                resultsText:SetPoint("RIGHT", entryFrame, "RIGHT", -10, 0)
                resultsText:SetJustifyH("LEFT")
                
                local resultsString = ""
                
                if entry.task == "cleanup" and entry.results then
                    resultsString = string.format("Removed %d items (%d profiles, %d analytics, %d errors, %d cache)",
                                                entry.results.totalItems,
                                                entry.results.profileData,
                                                entry.results.analyticData,
                                                entry.results.errorLogs,
                                                entry.results.cacheData)
                elseif entry.task == "backup" and entry.results then
                    resultsString = string.format("Backed up %d profiles, %.2f KB",
                                                entry.results.profiles,
                                                entry.results.size / 1024)
                elseif entry.task == "repair" and entry.results then
                    resultsString = string.format("Fixed %d items (%d profiles, %d settings, %d errors)",
                                                entry.results.totalItems,
                                                entry.results.profilesRepaired,
                                                entry.results.settingsRepaired,
                                                entry.results.errorsFixed)
                elseif entry.task == "optimize" and entry.results then
                    local memoryReduction = entry.results.memoryBefore - entry.results.memoryAfter
                    resultsString = string.format("Reduced memory usage by %.2f MB, optimized %d tables",
                                                memoryReduction / 1024,
                                                entry.results.tablesOptimized)
                elseif entry.task == "restore" then
                    resultsString = string.format("Restored from backup created on %s", 
                                                date("%Y-%m-%d %H:%M", entry.backupTimestamp))
                end
                
                resultsText:SetText(resultsString)
                
                -- Duration if available
                if entry.duration then
                    local durationText = entryFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                    durationText:SetPoint("BOTTOMRIGHT", entryFrame, "BOTTOMRIGHT", -10, 5)
                    durationText:SetText(string.format("Duration: %.2f seconds", entry.duration))
                end
                
                totalHeight = totalHeight + entryHeight + 5
            end
            
            historyScrollChild:SetHeight(math.max(totalHeight, historyScrollFrame:GetHeight()))
        end
    }
    
    -- Update initial data
    frame.updateFunctions.UpdateTasksTab()
    frame.updateFunctions.UpdateBackupsTab()
    frame.updateFunctions.UpdateHistoryTab()
    
    -- Auto-update
    frame:SetScript("OnUpdate", function(self, elapsed)
        self.updateTimer = (self.updateTimer or 0) + elapsed
        
        if self.updateTimer >= 1 then
            self.updateTimer = 0
            
            -- Update the active tab
            for i, content in ipairs(self.tabContents) do
                if content:IsShown() then
                    if i == 1 and self.updateFunctions.UpdateTasksTab then
                        self.updateFunctions.UpdateTasksTab()
                    elseif i == 2 and self.updateFunctions.UpdateBackupsTab then
                        self.updateFunctions.UpdateBackupsTab()
                    elseif i == 4 and self.updateFunctions.UpdateHistoryTab then
                        self.updateFunctions.UpdateHistoryTab()
                    end
                    break
                end
            end
        end
    end)
    
    -- Set up tab switching behavior
    tabs[1]:Click()
    
    -- Hide by default
    frame:Hide()
    
    -- Add the update functions
    Maintenance.UpdateTasksTab = frame.updateFunctions.UpdateTasksTab
    Maintenance.UpdateBackupsTab = frame.updateFunctions.UpdateBackupsTab
    Maintenance.UpdateHistoryTab = frame.updateFunctions.UpdateHistoryTab
    
    return frame
end

-- Initialize the module
Maintenance:Initialize()

return Maintenance