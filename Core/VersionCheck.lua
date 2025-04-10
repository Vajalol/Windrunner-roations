local addonName, WR = ...

-- VersionCheck module for update notifications and version management
local VersionCheck = {}
WR.VersionCheck = VersionCheck

-- Version information
local currentVersion = WR.version or "1.0.0"
local buildNumber = WR.buildNumber or 1
local lastChecked = 0
local checkInterval = 86400 -- Once per day
local updateAvailable = false
local latestVersion = nil
local changelogData = nil

-- Configuration
local config = {
    checkForUpdates = true,
    notificationsEnabled = true,
    autoCheckFrequency = 86400, -- Daily
    lastVersionSeen = currentVersion
}

-- Initialize the version check module
function VersionCheck:Initialize()
    -- Load saved settings
    if WindrunnerRotationsDB and WindrunnerRotationsDB.VersionCheck then
        local savedConfig = WindrunnerRotationsDB.VersionCheck
        for k, v in pairs(savedConfig) do
            if config[k] ~= nil then
                config[k] = v
            end
        end
    end
    
    -- Register events
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("PLAYER_LOGOUT")
    
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "PLAYER_ENTERING_WORLD" then
            -- Schedule version check
            C_Timer.After(10, function()
                if config.checkForUpdates then
                    VersionCheck:CheckForUpdates()
                end
            end)
        elseif event == "PLAYER_LOGOUT" then
            VersionCheck:SaveSettings()
        end
    end)
    
    WR:Debug("VersionCheck module initialized")
    self.initialized = true
end

-- Save settings
function VersionCheck:SaveSettings()
    -- Initialize storage if needed
    WindrunnerRotationsDB = WindrunnerRotationsDB or {}
    WindrunnerRotationsDB.VersionCheck = config
end

-- Check for updates
function VersionCheck:CheckForUpdates()
    -- Don't check too frequently
    local currentTime = GetTime()
    if currentTime - lastChecked < checkInterval then return end
    
    lastChecked = currentTime
    
    -- In a real implementation, this would make an API call or check a version file
    -- For this demonstration, we'll simulate an update check
    self:SimulateUpdateCheck()
end

-- Process update data
function VersionCheck:ProcessUpdateData(versionData)
    if not versionData then return end
    
    latestVersion = versionData.version
    local latestBuild = versionData.buildNumber or 0
    
    -- Compare versions
    if self:CompareVersions(latestVersion, currentVersion) > 0 or 
       (latestVersion == currentVersion and latestBuild > buildNumber) then
        updateAvailable = true
        changelogData = versionData.changelog
        
        -- Notify if enabled and this is a new version
        if config.notificationsEnabled and latestVersion ~= config.lastVersionSeen then
            self:NotifyUpdateAvailable()
        end
    else
        updateAvailable = false
    end
    
    -- Update last checked timestamp
    config.lastChecked = GetServerTime()
    
    WR:Debug("Version check complete. Latest:", latestVersion, "Current:", currentVersion, "Update available:", updateAvailable)
end

-- Compare version strings (semver-like)
function VersionCheck:CompareVersions(version1, version2)
    if not version1 or not version2 then return 0 end
    
    local v1parts = {}
    local v2parts = {}
    
    for part in version1:gmatch("([^%.]+)") do
        table.insert(v1parts, tonumber(part) or 0)
    end
    
    for part in version2:gmatch("([^%.]+)") do
        table.insert(v2parts, tonumber(part) or 0)
    end
    
    -- Ensure both arrays have same length
    while #v1parts < #v2parts do
        table.insert(v1parts, 0)
    end
    
    while #v2parts < #v1parts do
        table.insert(v2parts, 0)
    end
    
    -- Compare each part
    for i = 1, #v1parts do
        if v1parts[i] > v2parts[i] then
            return 1
        elseif v1parts[i] < v2parts[i] then
            return -1
        end
    end
    
    return 0
end

-- Notify user about available update
function VersionCheck:NotifyUpdateAvailable()
    if not updateAvailable or not latestVersion then return end
    
    -- Format message
    local message = string.format(
        "A new version of Windrunner Rotations is available! (v%s)\n" ..
        "You're currently using v%s.\n" ..
        "Type '/wr update' for more information.",
        latestVersion,
        currentVersion
    )
    
    -- Print notification
    WR:Print(message)
    
    -- Show UI alert if main UI is available
    if WR.UI and WR.UI.Enhanced and WR.UI.Enhanced.ShowAlert then
        WR.UI.Enhanced:ShowAlert("Update Available: v" .. latestVersion)
    end
end

-- Get update status
function VersionCheck:GetUpdateStatus()
    return {
        currentVersion = currentVersion,
        buildNumber = buildNumber,
        updateAvailable = updateAvailable,
        latestVersion = latestVersion,
        lastChecked = lastChecked,
        changelog = changelogData
    }
end

-- Mark version as seen
function VersionCheck:MarkVersionSeen(version)
    if not version then version = latestVersion end
    if not version then return end
    
    config.lastVersionSeen = version
    self:SaveSettings()
end

-- Get configuration
function VersionCheck:GetConfig()
    return config
end

-- Set configuration
function VersionCheck:SetConfig(newConfig)
    if not newConfig then return end
    
    for k, v in pairs(newConfig) do
        if config[k] ~= nil then
            config[k] = v
        end
    end
    
    self:SaveSettings()
    
    -- Check for updates if enabled
    if config.checkForUpdates and not updateAvailable then
        self:CheckForUpdates()
    end
end

-- Handle update commands
function VersionCheck:HandleUpdateCommand(args)
    if not args or args == "" then
        -- Show update status
        self:ShowUpdateStatus()
        return
    end
    
    if args == "check" then
        -- Force update check
        WR:Print("Checking for updates...")
        self:CheckForUpdates(true)
        C_Timer.After(1, function() self:ShowUpdateStatus() end)
    elseif args == "changelog" then
        -- Show changelog
        self:ShowChangelog()
    elseif args == "enable" then
        -- Enable update checks
        config.checkForUpdates = true
        self:SaveSettings()
        WR:Print("Update checks enabled")
    elseif args == "disable" then
        -- Disable update checks
        config.checkForUpdates = false
        self:SaveSettings()
        WR:Print("Update checks disabled")
    else
        -- Unknown command
        WR:Print("Unknown update command: " .. args)
        WR:Print("Available commands: check, changelog, enable, disable")
    end
end

-- Show update status
function VersionCheck:ShowUpdateStatus()
    WR:Print("Windrunner Rotations Version Information")
    WR:Print("Current Version: v" .. currentVersion .. " (Build " .. buildNumber .. ")")
    
    if latestVersion then
        WR:Print("Latest Version: v" .. latestVersion)
        
        if updateAvailable then
            WR:Print("Status: Update available! Type '/wr update changelog' to see what's new.")
        else
            WR:Print("Status: Up to date")
        end
    else
        WR:Print("Status: Version check not completed")
    end
    
    if lastChecked > 0 then
        local timeAgo = GetTime() - lastChecked
        local timeString = self:FormatTimeAgo(timeAgo)
        WR:Print("Last checked: " .. timeString .. " ago")
    end
    
    WR:Print("Update checks: " .. (config.checkForUpdates and "Enabled" or "Disabled"))
}

-- Show changelog
function VersionCheck:ShowChangelog()
    if not changelogData then
        WR:Print("No changelog data available")
        return
    end
    
    WR:Print("Changelog for v" .. latestVersion .. ":")
    
    for _, entry in ipairs(changelogData) do
        if entry.version then
            WR:Print(" ")
            WR:Print("Version " .. entry.version .. ":")
        end
        
        if entry.changes then
            for _, change in ipairs(entry.changes) do
                WR:Print("• " .. change)
            end
        end
    end
    
    -- Mark as seen
    self:MarkVersionSeen(latestVersion)
}

-- Format time ago string
function VersionCheck:FormatTimeAgo(seconds)
    if seconds < 60 then
        return math.floor(seconds) .. " seconds"
    elseif seconds < 3600 then
        return math.floor(seconds / 60) .. " minutes"
    elseif seconds < 86400 then
        return math.floor(seconds / 3600) .. " hours"
    else
        return math.floor(seconds / 86400) .. " days"
    end
end

-- Create update UI
function VersionCheck:CreateUpdateUI(parent)
    if not parent then return end
    
    -- Create the update frame
    local frame = CreateFrame("Frame", "WindrunnerRotationsUpdateFrame", parent, "BackdropTemplate")
    frame:SetSize(500, 400)
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
    title:SetText("Windrunner Rotations Update")
    
    -- Create close button
    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    
    -- Create version info
    local currentVersionText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    currentVersionText:SetPoint("TOP", title, "BOTTOM", 0, -20)
    currentVersionText:SetText("Current Version: v" .. currentVersion)
    
    local latestVersionText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    latestVersionText:SetPoint("TOP", currentVersionText, "BOTTOM", 0, -10)
    latestVersionText:SetText("Latest Version: " .. (latestVersion or "Unknown"))
    
    -- Create update status
    local statusFrame = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    statusFrame:SetSize(460, 60)
    statusFrame:SetPoint("TOP", latestVersionText, "BOTTOM", 0, -10)
    statusFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    statusFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
    
    local statusText = statusFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    statusText:SetPoint("CENTER", statusFrame, "CENTER", 0, 10)
    
    if updateAvailable then
        statusText:SetText("An update is available!")
        statusText:SetTextColor(0, 1, 0)
    else
        statusText:SetText("Your addon is up to date")
        statusText:SetTextColor(0, 1, 0)
    end
    
    local lastCheckedText = statusFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lastCheckedText:SetPoint("CENTER", statusFrame, "CENTER", 0, -10)
    
    if lastChecked > 0 then
        local timeAgo = GetTime() - lastChecked
        local timeString = self:FormatTimeAgo(timeAgo)
        lastCheckedText:SetText("Last checked: " .. timeString .. " ago")
    else
        lastCheckedText:SetText("Last checked: Never")
    end
    
    -- Create changelog frame
    local changelogFrame = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    changelogFrame:SetSize(460, 170)
    changelogFrame:SetPoint("TOP", statusFrame, "BOTTOM", 0, -10)
    changelogFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    changelogFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
    
    local changelogTitle = changelogFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    changelogTitle:SetPoint("TOPLEFT", changelogFrame, "TOPLEFT", 15, -15)
    changelogTitle:SetText("Changelog:")
    
    -- Create changelog scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", nil, changelogFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetSize(420, 120)
    scrollFrame:SetPoint("TOPLEFT", changelogTitle, "BOTTOMLEFT", 0, -5)
    
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(scrollFrame:GetWidth(), 1) -- Height will be set dynamically
    scrollFrame:SetScrollChild(scrollChild)
    
    -- Fill changelog
    local function UpdateChangelog()
        -- Clear existing entries
        for i = scrollChild:GetNumChildren(), 1, -1 do
            local child = select(i, scrollChild:GetChildren())
            child:Hide()
            child:SetParent(nil)
        end
        
        if not changelogData or #changelogData == 0 then
            local noChangelog = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            noChangelog:SetPoint("TOP", scrollChild, "TOP", 0, -10)
            noChangelog:SetText("No changelog data available")
            
            scrollChild:SetHeight(30)
            return
        end
        
        local currentY = -10
        
        for _, entry in ipairs(changelogData) do
            if entry.version then
                local versionText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
                versionText:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 5, currentY)
                versionText:SetText("Version " .. entry.version)
                
                currentY = currentY - versionText:GetStringHeight() - 5
            end
            
            if entry.changes then
                for _, change in ipairs(entry.changes) do
                    local changeText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                    changeText:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 15, currentY)
                    changeText:SetPoint("RIGHT", scrollChild, "RIGHT", -5, 0)
                    changeText:SetJustifyH("LEFT")
                    changeText:SetText("• " .. change)
                    
                    currentY = currentY - changeText:GetStringHeight() - 5
                end
            end
            
            -- Add some space between versions
            currentY = currentY - 10
        end
        
        scrollChild:SetHeight(math.abs(currentY) + 10)
    end
    
    UpdateChangelog()
    
    -- Create buttons
    local checkButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    checkButton:SetSize(120, 25)
    checkButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 20, 15)
    checkButton:SetText("Check Now")
    checkButton:SetScript("OnClick", function()
        WR:Print("Checking for updates...")
        VersionCheck:CheckForUpdates(true)
        
        -- Update UI after a short delay
        C_Timer.After(1, function()
            latestVersionText:SetText("Latest Version: " .. (latestVersion or "Unknown"))
            
            if updateAvailable then
                statusText:SetText("An update is available!")
                statusText:SetTextColor(0, 1, 0)
            else
                statusText:SetText("Your addon is up to date")
                statusText:SetTextColor(0, 1, 0)
            end
            
            local timeAgo = GetTime() - lastChecked
            local timeString = VersionCheck:FormatTimeAgo(timeAgo)
            lastCheckedText:SetText("Last checked: " .. timeString .. " ago")
            
            UpdateChangelog()
        end)
    end)
    
    local settingsButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    settingsButton:SetSize(120, 25)
    settingsButton:SetPoint("LEFT", checkButton, "RIGHT", 10, 0)
    settingsButton:SetText("Settings")
    
    local autoCheckCheckbox = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
    autoCheckCheckbox:SetPoint("BOTTOMLEFT", checkButton, "TOPLEFT", 0, 10)
    autoCheckCheckbox:SetChecked(config.checkForUpdates)
    
    local autoCheckLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    autoCheckLabel:SetPoint("LEFT", autoCheckCheckbox, "RIGHT", 5, 0)
    autoCheckLabel:SetText("Check for updates automatically")
    
    settingsButton:SetScript("OnClick", function()
        config.checkForUpdates = autoCheckCheckbox:GetChecked()
        VersionCheck:SaveSettings()
        WR:Print("Update settings saved.")
    end)
    
    -- Mark version as seen when viewing update UI
    if updateAvailable and latestVersion then
        self:MarkVersionSeen(latestVersion)
    end
    
    -- Hide by default
    frame:Hide()
    
    return frame
}

-- Simulate an update check (for demonstration)
function VersionCheck:SimulateUpdateCheck()
    -- In a real implementation, this would be an API call
    -- For demonstration, we'll simulate a newer version
    
    -- Extract current version parts
    local major, minor, patch = currentVersion:match("(%d+)%.(%d+)%.(%d+)")
    major, minor, patch = tonumber(major) or 1, tonumber(minor) or 0, tonumber(patch) or 0
    
    -- Simulate a newer version
    local latestMajor, latestMinor, latestPatch = major, minor, patch + 1
    
    -- Create simulated update data
    local updateData = {
        version = string.format("%d.%d.%d", latestMajor, latestMinor, latestPatch),
        buildNumber = buildNumber + 5,
        changelog = {
            {
                version = string.format("%d.%d.%d", latestMajor, latestMinor, latestPatch),
                changes = {
                    "Added new optimizations for all class rotations",
                    "Improved UI responsiveness during combat",
                    "Fixed issue with resource tracking for certain specs",
                    "Updated dungeon strategies for latest raid tier",
                    "Added enhanced documentation system"
                }
            },
            {
                version = currentVersion,
                changes = {
                    "Current version changelog entry",
                    "Implemented basic rotation functionality",
                    "Added profile system",
                    "Created user interface"
                }
            }
        }
    }
    
    -- Process the update data
    self:ProcessUpdateData(updateData)
}

-- Initialize the module
VersionCheck:Initialize()

return VersionCheck