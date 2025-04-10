local addonName, WR = ...

-- Community module for sharing, collaboration, and community features
local Community = {}
WR.Community = Community

-- Constants
local API_ENDPOINT = "https://api.windrunnerrotations.com" -- Simulated API endpoint
local DISCORD_INVITE = "https://discord.gg/windrunnerrotations" -- Simulated Discord invite
local WEBSITE_URL = "https://windrunnerrotations.com" -- Simulated website URL
local GITHUB_URL = "https://github.com/windrunnerdev/windrunnerrotations" -- Simulated GitHub repository
local REPORT_ISSUE_URL = GITHUB_URL .. "/issues/new" -- Issue reporting URL

-- Community data
local communityData = {
    featuredProfiles = {},
    topContributors = {},
    announcements = {},
    guides = {},
    leaderboards = {},
    reportQueue = {},
    marketplaceItems = {},
    userProfile = nil,
    connectionStatus = "offline",
    lastSyncTime = 0
}

-- Configuration
local config = {
    enabled = true,
    autoSync = false,
    syncFrequency = 3600, -- Once per hour
    shareAnalytics = false,
    showcaseProfile = false,
    featuredProfileId = nil,
    communityRank = "Member",
    displayName = nil,
    lastLogin = 0,
    privacy = {
        shareProfile = false,
        shareStats = false,
        allowMessages = false,
        showOnline = false
    }
}

-- Initialize the community module
function Community:Initialize()
    -- Load saved settings
    if WindrunnerRotationsDB and WindrunnerRotationsDB.Community then
        local savedConfig = WindrunnerRotationsDB.Community
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
            -- Schedule community data sync
            C_Timer.After(15, function()
                if config.enabled and config.autoSync then
                    Community:SyncCommunityData()
                end
            end)
            
            -- Set up periodic sync
            if config.enabled and config.autoSync then
                C_Timer.NewTicker(config.syncFrequency, function() 
                    Community:SyncCommunityData()
                end)
            end
        elseif event == "PLAYER_LOGOUT" then
            Community:SaveSettings()
        end
    end)
    
    -- Set default display name if not set
    if not config.displayName then
        config.displayName = UnitName("player") .. "-" .. GetRealmName()
    end
    
    -- Record login time
    config.lastLogin = time()
    
    WR:Debug("Community module initialized")
end

-- Save settings
function Community:SaveSettings()
    -- Initialize storage if needed
    WindrunnerRotationsDB = WindrunnerRotationsDB or {}
    WindrunnerRotationsDB.Community = CopyTable(config)
}

-- Sync community data with server
function Community:SyncCommunityData()
    if not config.enabled then return end
    
    WR:Debug("Syncing community data")
    
    -- Simulate API call
    self:SimulateCommunitySync()
    
    -- Update last sync time
    communityData.lastSyncTime = time()
    config.lastSyncTime = communityData.lastSyncTime
}

-- Get featured profiles
function Community:GetFeaturedProfiles()
    return communityData.featuredProfiles
}

-- Get community announcements
function Community:GetAnnouncements()
    return communityData.announcements
}

-- Get community guides
function Community:GetGuides()
    return communityData.guides
}

-- Get leaderboards
function Community:GetLeaderboards(category)
    if category and communityData.leaderboards[category] then
        return communityData.leaderboards[category]
    end
    
    return communityData.leaderboards
}

-- Get top contributors
function Community:GetTopContributors()
    return communityData.topContributors
}

-- Get user profile
function Community:GetUserProfile()
    return communityData.userProfile
}

-- Report an issue
function Community:ReportIssue(issueData)
    if not issueData or not issueData.title or not issueData.description then
        return false, "Missing required issue information"
    end
    
    -- Add additional metadata
    issueData.reporter = config.displayName
    issueData.timestamp = time()
    issueData.version = WR.version or "Unknown"
    issueData.buildNumber = WR.buildNumber or 0
    
    -- Add to report queue
    table.insert(communityData.reportQueue, issueData)
    
    -- In a real implementation, this would submit to the API
    -- For now, just provide instructions to the user
    
    WR:Print("Thank you for your report. For fastest response, please submit this issue on our GitHub:")
    WR:Print(REPORT_ISSUE_URL)
    
    -- Return issue ID (just the timestamp for this simulation)
    return true, issueData.timestamp
}

-- Share a profile with the community
function Community:ShareProfile(profileId, isPublic)
    if not profileId or not WR.ProfileManager then
        return false, "Invalid profile or profile manager not available"
    end
    
    local profile = WR.ProfileManager:GetProfile(profileId)
    if not profile then
        return false, "Profile not found: " .. profileId
    end
    
    -- Add sharing metadata
    profile.shared = {
        by = config.displayName,
        at = time(),
        public = isPublic or false,
        version = WR.version
    }
    
    -- In a real implementation, this would upload to the API
    -- For now, generate an export string
    
    local serialized = "WR_PROFILE:" .. profileId
    -- In reality, this would be a proper serialization of the profile data
    
    WR:Print("Profile " .. profileId .. " prepared for sharing.")
    WR:Print("You can share this profile with others using this export string:")
    WR:Print(serialized)
    
    -- Update config
    config.showcaseProfile = true
    config.featuredProfileId = profileId
    self:SaveSettings()
    
    -- Return success and the serialized profile
    return true, serialized
}

-- Get community metrics
function Community:GetCommunityMetrics()
    -- Simulate community metrics
    return {
        totalUsers = 12500,
        activeUsers = 8750,
        totalProfiles = 28900,
        totalShares = 15600,
        totalContributions = 4200,
        yourRank = config.communityRank,
        yourContributions = 5
    }
}

-- Join community Discord
function Community:JoinDiscord()
    WR:Print("Opening Discord invite link. If it doesn't open automatically, please visit:")
    WR:Print(DISCORD_INVITE)
    
    -- In a real implementation, this would open the URL in the default browser
    -- For this simulation, just print instructions
    WR:Print("You can copy and paste this link into your browser to join our Discord community.")
}

-- Visit website
function Community:VisitWebsite()
    WR:Print("Opening website. If it doesn't open automatically, please visit:")
    WR:Print(WEBSITE_URL)
    
    -- In a real implementation, this would open the URL in the default browser
    -- For this simulation, just print instructions
    WR:Print("You can copy and paste this link into your browser to visit our website.")
}

-- Get configuration
function Community:GetConfig()
    return config
}

-- Set configuration
function Community:SetConfig(newConfig)
    if not newConfig then return end
    
    for k, v in pairs(newConfig) do
        if config[k] ~= nil then
            config[k] = v
        end
    end
    
    -- Save immediately
    self:SaveSettings()
    
    -- Update privacy settings
    if newConfig.privacy then
        for k, v in pairs(newConfig.privacy) do
            if config.privacy[k] ~= nil then
                config.privacy[k] = v
            end
        end
    end
    
    -- Check if we need to sync after config change
    if config.enabled and config.autoSync and 
       (newConfig.enabled ~= nil or newConfig.autoSync ~= nil) then
        C_Timer.After(1, function() Community:SyncCommunityData() end)
    end
}

-- Handle community commands
function Community:HandleCommand(args)
    if not args or args == "" then
        -- Show community interface
        self:ShowCommunityUI()
        return
    end
    
    local command, parameter = args:match("^(%S+)%s*(.*)$")
    command = command and command:lower() or args:lower()
    
    if command == "discord" then
        -- Join Discord
        self:JoinDiscord()
    elseif command == "website" or command == "web" then
        -- Visit website
        self:VisitWebsite()
    elseif command == "report" then
        -- Report issue
        self:ShowReportUI()
    elseif command == "share" then
        -- Share profile
        if not parameter or parameter == "" then
            WR:Print("Usage: /wr community share <profileName>")
            return
        end
        
        local success, result = self:ShareProfile(parameter)
        if not success then
            WR:Print("Error sharing profile: " .. result)
        end
    elseif command == "sync" then
        -- Force sync
        WR:Print("Syncing community data...")
        self:SyncCommunityData()
        WR:Print("Sync complete.")
    elseif command == "leaderboard" or command == "leaderboards" then
        -- Show leaderboards
        self:ShowLeaderboardUI()
    elseif command == "guides" then
        -- Show guides
        self:ShowGuidesUI()
    elseif command == "profiles" then
        -- Show community profiles
        self:ShowProfilesUI()
    else
        -- Unknown command
        WR:Print("Unknown community command: " .. command)
        WR:Print("Available commands: discord, website, report, share, sync, leaderboard, guides, profiles")
    end
}

-- Show community UI
function Community:ShowCommunityUI()
    -- Create UI if it doesn't exist
    if not self.ui then
        self.ui = self:CreateCommunityUI(UIParent)
    end
    
    -- Show UI
    self.ui:Show()
}

-- Show report UI
function Community:ShowReportUI()
    -- Create UI if it doesn't exist
    if not self.reportUI then
        self.reportUI = self:CreateReportUI(UIParent)
    end
    
    -- Show UI
    self.reportUI:Show()
}

-- Show leaderboard UI
function Community:ShowLeaderboardUI()
    -- Create UI if it doesn't exist
    if not self.leaderboardUI then
        self.leaderboardUI = self:CreateLeaderboardUI(UIParent)
    end
    
    -- Show UI
    self.leaderboardUI:Show()
}

-- Show guides UI
function Community:ShowGuidesUI()
    -- Create UI if it doesn't exist
    if not self.guidesUI then
        self.guidesUI = self:CreateGuidesUI(UIParent)
    end
    
    -- Show UI
    self.guidesUI:Show()
}

-- Show profiles UI
function Community:ShowProfilesUI()
    -- Create UI if it doesn't exist
    if not self.profilesUI then
        self.profilesUI = self:CreateProfilesUI(UIParent)
    end
    
    -- Show UI
    self.profilesUI:Show()
}

-- Create community UI
function Community:CreateCommunityUI(parent)
    if not parent then return end
    
    -- Create main frame
    local frame = CreateFrame("Frame", "WindrunnerRotationsCommunity", parent, "BackdropTemplate")
    frame:SetSize(800, 600)
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
    title:SetText("Windrunner Rotations Community")
    
    -- Create close button
    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    
    -- Create tab system
    local tabWidth = 120
    local tabHeight = 24
    local tabs = {}
    local tabContents = {}
    
    local tabNames = {"Home", "Profiles", "Guides", "Leaderboards", "Resources", "Settings"}
    
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
        
        -- Create selected texture
        local selectedTexture = tab:CreateTexture(nil, "BACKGROUND")
        selectedTexture:SetAllPoints()
        selectedTexture:SetColorTexture(0.2, 0.4, 0.8, 0.2)
        selectedTexture:Hide()
        tab.selectedTexture = selectedTexture
        
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
                tabButton.selectedTexture:Hide()
            end
            
            tab.selectedTexture:Show()
        end)
        
        tabs[i] = tab
        tabContents[i] = content
    end
    
    -- Populate Home tab
    local homeContent = tabContents[1]
    
    -- Create welcome message
    local welcomeFrame = CreateFrame("Frame", nil, homeContent, "BackdropTemplate")
    welcomeFrame:SetSize(homeContent:GetWidth(), 100)
    welcomeFrame:SetPoint("TOP", homeContent, "TOP", 0, 0)
    welcomeFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    welcomeFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
    
    local welcomeText = welcomeFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    welcomeText:SetPoint("TOP", welcomeFrame, "TOP", 0, -15)
    welcomeText:SetText("Welcome to the Windrunner Rotations Community")
    
    local statusText = welcomeFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    statusText:SetPoint("TOP", welcomeText, "BOTTOM", 0, -10)
    statusText:SetText("Status: " .. communityData.connectionStatus:gsub("^%l", string.upper))
    
    local userText = welcomeFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    userText:SetPoint("TOP", statusText, "BOTTOM", 0, -10)
    userText:SetText("User: " .. config.displayName .. " (" .. config.communityRank .. ")")
    
    -- Create announcements
    local announcementsFrame = CreateFrame("Frame", nil, homeContent, "BackdropTemplate")
    announcementsFrame:SetSize(homeContent:GetWidth() / 2 - 5, 200)
    announcementsFrame:SetPoint("TOPLEFT", welcomeFrame, "BOTTOMLEFT", 0, -10)
    announcementsFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    announcementsFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
    
    local announcementsTitle = announcementsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    announcementsTitle:SetPoint("TOPLEFT", announcementsFrame, "TOPLEFT", 15, -15)
    announcementsTitle:SetText("Announcements")
    
    -- Create announcements scroll frame
    local announcementsScroll = CreateFrame("ScrollFrame", nil, announcementsFrame, "UIPanelScrollFrameTemplate")
    announcementsScroll:SetSize(announcementsFrame:GetWidth() - 30, announcementsFrame:GetHeight() - 40)
    announcementsScroll:SetPoint("TOPLEFT", announcementsTitle, "BOTTOMLEFT", 0, -5)
    
    local announcementsScrollChild = CreateFrame("Frame", nil, announcementsScroll)
    announcementsScrollChild:SetSize(announcementsScroll:GetWidth(), 1)
    announcementsScroll:SetScrollChild(announcementsScrollChild)
    
    -- Create featured profiles
    local featuredFrame = CreateFrame("Frame", nil, homeContent, "BackdropTemplate")
    featuredFrame:SetSize(homeContent:GetWidth() / 2 - 5, 200)
    featuredFrame:SetPoint("TOPRIGHT", welcomeFrame, "BOTTOMRIGHT", 0, -10)
    featuredFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    featuredFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
    
    local featuredTitle = featuredFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    featuredTitle:SetPoint("TOPLEFT", featuredFrame, "TOPLEFT", 15, -15)
    featuredTitle:SetText("Featured Profiles")
    
    -- Create featured profiles scroll frame
    local featuredScroll = CreateFrame("ScrollFrame", nil, featuredFrame, "UIPanelScrollFrameTemplate")
    featuredScroll:SetSize(featuredFrame:GetWidth() - 30, featuredFrame:GetHeight() - 40)
    featuredScroll:SetPoint("TOPLEFT", featuredTitle, "BOTTOMLEFT", 0, -5)
    
    local featuredScrollChild = CreateFrame("Frame", nil, featuredScroll)
    featuredScrollChild:SetSize(featuredScroll:GetWidth(), 1)
    featuredScroll:SetScrollChild(featuredScrollChild)
    
    -- Create statistics frame
    local statsFrame = CreateFrame("Frame", nil, homeContent, "BackdropTemplate")
    statsFrame:SetSize(homeContent:GetWidth(), 150)
    statsFrame:SetPoint("BOTTOM", homeContent, "BOTTOM", 0, 0)
    statsFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    statsFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
    
    local statsTitle = statsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    statsTitle:SetPoint("TOPLEFT", statsFrame, "TOPLEFT", 15, -15)
    statsTitle:SetText("Community Statistics")
    
    local statsContainer = CreateFrame("Frame", nil, statsFrame)
    statsContainer:SetSize(statsFrame:GetWidth() - 30, statsFrame:GetHeight() - 40)
    statsContainer:SetPoint("TOPLEFT", statsTitle, "BOTTOMLEFT", 0, -10)
    
    -- Create action buttons
    local discordButton = CreateFrame("Button", nil, homeContent, "UIPanelButtonTemplate")
    discordButton:SetSize(150, 30)
    discordButton:SetPoint("BOTTOMLEFT", announcementsFrame, "BOTTOMLEFT", 10, 10)
    discordButton:SetText("Join Discord")
    discordButton:SetScript("OnClick", function() Community:JoinDiscord() end)
    
    local websiteButton = CreateFrame("Button", nil, homeContent, "UIPanelButtonTemplate")
    websiteButton:SetSize(150, 30)
    websiteButton:SetPoint("BOTTOMRIGHT", featuredFrame, "BOTTOMRIGHT", -10, 10)
    websiteButton:SetText("Visit Website")
    websiteButton:SetScript("OnClick", function() Community:VisitWebsite() end)
    
    local syncButton = CreateFrame("Button", nil, homeContent, "UIPanelButtonTemplate")
    syncButton:SetSize(150, 30)
    syncButton:SetPoint("TOP", discordButton, "TOP", 0, 0)
    syncButton:SetPoint("RIGHT", websiteButton, "LEFT", -20, 0)
    syncButton:SetText("Sync Now")
    syncButton:SetScript("OnClick", function()
        WR:Print("Syncing community data...")
        Community:SyncCommunityData()
        WR:Print("Sync complete.")
        
        -- Update status display
        statusText:SetText("Status: " .. communityData.connectionStatus:gsub("^%l", string.upper))
        
        -- Update announcements and featured profiles
        Community:UpdateHomeTab()
    end)
    
    -- Populate settings tab
    local settingsContent = tabContents[6]
    
    -- Create settings frame
    local settingsFrame = CreateFrame("Frame", nil, settingsContent, "BackdropTemplate")
    settingsFrame:SetSize(settingsContent:GetWidth(), settingsContent:GetHeight() - 50)
    settingsFrame:SetPoint("TOP", settingsContent, "TOP", 0, 0)
    settingsFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    settingsFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
    
    local settingsTitle = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    settingsTitle:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 15, -15)
    settingsTitle:SetText("Community Settings")
    
    -- Create checkboxes for various settings
    local checkboxes = {}
    local checkY = -50
    local checkboxLabels = {
        enabledCheckbox = "Enable community features",
        autoSyncCheckbox = "Automatically sync community data",
        shareAnalyticsCheckbox = "Share anonymous usage analytics",
        showcaseProfileCheckbox = "Showcase my profile publicly",
    }
    
    local i = 0
    for name, label in pairs(checkboxLabels) do
        local checkbox = CreateFrame("CheckButton", nil, settingsFrame, "UICheckButtonTemplate")
        checkbox:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 30, checkY - (i * 30))
        
        local text = checkbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
        text:SetText(label)
        
        checkboxes[name] = checkbox
        i = i + 1
    end
    
    -- Set initial values
    checkboxes.enabledCheckbox:SetChecked(config.enabled)
    checkboxes.autoSyncCheckbox:SetChecked(config.autoSync)
    checkboxes.shareAnalyticsCheckbox:SetChecked(config.shareAnalytics)
    checkboxes.showcaseProfileCheckbox:SetChecked(config.showcaseProfile)
    
    -- Create privacy settings
    local privacyTitle = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    privacyTitle:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 15, checkY - (i * 30) - 20)
    privacyTitle:SetText("Privacy Settings")
    
    -- Create privacy checkboxes
    local privacyCheckboxes = {}
    local privacyLabels = {
        shareProfileCheckbox = "Allow others to view my profiles",
        shareStatsCheckbox = "Share my performance statistics",
        allowMessagesCheckbox = "Allow direct messages from other users",
        showOnlineCheckbox = "Show when I'm online",
    }
    
    i = 0
    local privacyY = checkY - (#checkboxLabels * 30) - 50
    for name, label in pairs(privacyLabels) do
        local checkbox = CreateFrame("CheckButton", nil, settingsFrame, "UICheckButtonTemplate")
        checkbox:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 30, privacyY - (i * 30))
        
        local text = checkbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
        text:SetText(label)
        
        privacyCheckboxes[name] = checkbox
        i = i + 1
    end
    
    -- Set initial privacy values
    privacyCheckboxes.shareProfileCheckbox:SetChecked(config.privacy.shareProfile)
    privacyCheckboxes.shareStatsCheckbox:SetChecked(config.privacy.shareStats)
    privacyCheckboxes.allowMessagesCheckbox:SetChecked(config.privacy.allowMessages)
    privacyCheckboxes.showOnlineCheckbox:SetChecked(config.privacy.showOnline)
    
    -- Create display name field
    local displayNameLabel = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    displayNameLabel:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 30, privacyY - (#privacyLabels * 30) - 30)
    displayNameLabel:SetText("Display Name:")
    
    local displayNameEdit = CreateFrame("EditBox", nil, settingsFrame, "InputBoxTemplate")
    displayNameEdit:SetSize(200, 20)
    displayNameEdit:SetPoint("LEFT", displayNameLabel, "RIGHT", 10, 0)
    displayNameEdit:SetText(config.displayName or UnitName("player"))
    displayNameEdit:SetAutoFocus(false)
    
    -- Create save and reset buttons
    local saveButton = CreateFrame("Button", nil, settingsContent, "UIPanelButtonTemplate")
    saveButton:SetSize(100, 30)
    saveButton:SetPoint("BOTTOMRIGHT", settingsContent, "BOTTOMRIGHT", -10, 10)
    saveButton:SetText("Save")
    saveButton:SetScript("OnClick", function()
        -- Update config
        config.enabled = checkboxes.enabledCheckbox:GetChecked()
        config.autoSync = checkboxes.autoSyncCheckbox:GetChecked()
        config.shareAnalytics = checkboxes.shareAnalyticsCheckbox:GetChecked()
        config.showcaseProfile = checkboxes.showcaseProfileCheckbox:GetChecked()
        
        -- Update privacy settings
        config.privacy.shareProfile = privacyCheckboxes.shareProfileCheckbox:GetChecked()
        config.privacy.shareStats = privacyCheckboxes.shareStatsCheckbox:GetChecked()
        config.privacy.allowMessages = privacyCheckboxes.allowMessagesCheckbox:GetChecked()
        config.privacy.showOnline = privacyCheckboxes.showOnlineCheckbox:GetChecked()
        
        -- Update display name
        config.displayName = displayNameEdit:GetText()
        
        -- Save settings
        Community:SaveSettings()
        
        -- Update user display
        userText:SetText("User: " .. config.displayName .. " (" .. config.communityRank .. ")")
        
        WR:Print("Community settings saved")
    end)
    
    local resetButton = CreateFrame("Button", nil, settingsContent, "UIPanelButtonTemplate")
    resetButton:SetSize(100, 30)
    resetButton:SetPoint("RIGHT", saveButton, "LEFT", -10, 0)
    resetButton:SetText("Reset")
    resetButton:SetScript("OnClick", function()
        -- Reset checkboxes to default values
        checkboxes.enabledCheckbox:SetChecked(true)
        checkboxes.autoSyncCheckbox:SetChecked(false)
        checkboxes.shareAnalyticsCheckbox:SetChecked(false)
        checkboxes.showcaseProfileCheckbox:SetChecked(false)
        
        -- Reset privacy checkboxes
        privacyCheckboxes.shareProfileCheckbox:SetChecked(false)
        privacyCheckboxes.shareStatsCheckbox:SetChecked(false)
        privacyCheckboxes.allowMessagesCheckbox:SetChecked(false)
        privacyCheckboxes.showOnlineCheckbox:SetChecked(false)
        
        -- Reset display name
        displayNameEdit:SetText(UnitName("player") .. "-" .. GetRealmName())
    end)
    
    -- Update method for home tab
    function Community:UpdateHomeTab()
        -- Clear announcements
        for i = announcementsScrollChild:GetNumChildren(), 1, -1 do
            local child = select(i, announcementsScrollChild:GetChildren())
            child:Hide()
            child:SetParent(nil)
        end
        
        -- Clear featured profiles
        for i = featuredScrollChild:GetNumChildren(), 1, -1 do
            local child = select(i, featuredScrollChild:GetChildren())
            child:Hide()
            child:SetParent(nil)
        end
        
        -- Add announcements
        if #communityData.announcements == 0 then
            local noAnnouncements = announcementsScrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            noAnnouncements:SetPoint("TOP", announcementsScrollChild, "TOP", 0, -10)
            noAnnouncements:SetText("No announcements available")
            
            announcementsScrollChild:SetHeight(30)
        else
            local currentY = -10
            
            for i, announcement in ipairs(communityData.announcements) do
                local announcementFrame = CreateFrame("Frame", nil, announcementsScrollChild, "BackdropTemplate")
                announcementFrame:SetSize(announcementsScrollChild:GetWidth() - 10, 80)
                announcementFrame:SetPoint("TOPLEFT", announcementsScrollChild, "TOPLEFT", 5, currentY)
                announcementFrame:SetBackdrop({
                    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
                    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                    tile = true,
                    tileSize = 16,
                    edgeSize = 16,
                    insets = { left = 4, right = 4, top = 4, bottom = 4 }
                })
                announcementFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
                
                local titleText = announcementFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                titleText:SetPoint("TOPLEFT", announcementFrame, "TOPLEFT", 10, -10)
                titleText:SetText(announcement.title)
                
                local dateText = announcementFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                dateText:SetPoint("TOPRIGHT", announcementFrame, "TOPRIGHT", -10, -10)
                dateText:SetText(date("%Y-%m-%d", announcement.date))
                
                local messageText = announcementFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                messageText:SetPoint("TOPLEFT", titleText, "BOTTOMLEFT", 0, -5)
                messageText:SetPoint("RIGHT", announcementFrame, "RIGHT", -10, 0)
                messageText:SetJustifyH("LEFT")
                messageText:SetText(announcement.message)
                messageText:SetWordWrap(true)
                
                local messageHeight = messageText:GetStringHeight()
                if messageHeight > 35 then
                    announcementFrame:SetHeight(messageHeight + 45)
                end
                
                currentY = currentY - announcementFrame:GetHeight() - 10
            end
            
            announcementsScrollChild:SetHeight(math.abs(currentY) + 10)
        end
        
        -- Add featured profiles
        if #communityData.featuredProfiles == 0 then
            local noProfiles = featuredScrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            noProfiles:SetPoint("TOP", featuredScrollChild, "TOP", 0, -10)
            noProfiles:SetText("No featured profiles available")
            
            featuredScrollChild:SetHeight(30)
        else
            local currentY = -10
            
            for i, profile in ipairs(communityData.featuredProfiles) do
                local profileFrame = CreateFrame("Frame", nil, featuredScrollChild, "BackdropTemplate")
                profileFrame:SetSize(featuredScrollChild:GetWidth() - 10, 60)
                profileFrame:SetPoint("TOPLEFT", featuredScrollChild, "TOPLEFT", 5, currentY)
                profileFrame:SetBackdrop({
                    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
                    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                    tile = true,
                    tileSize = 16,
                    edgeSize = 16,
                    insets = { left = 4, right = 4, top = 4, bottom = 4 }
                })
                profileFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
                
                local nameText = profileFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                nameText:SetPoint("TOPLEFT", profileFrame, "TOPLEFT", 10, -10)
                nameText:SetText(profile.name)
                
                local authorText = profileFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                authorText:SetPoint("TOPLEFT", nameText, "BOTTOMLEFT", 0, -5)
                authorText:SetText("By: " .. profile.author)
                
                local classText = profileFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                classText:SetPoint("TOPRIGHT", profileFrame, "TOPRIGHT", -10, -10)
                classText:SetText(profile.class .. " - " .. profile.spec)
                
                local ratingText = profileFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                ratingText:SetPoint("TOPRIGHT", classText, "BOTTOMRIGHT", 0, -5)
                ratingText:SetText("Rating: " .. profile.rating .. "/5")
                
                local importButton = CreateFrame("Button", nil, profileFrame, "UIPanelButtonTemplate")
                importButton:SetSize(80, 22)
                importButton:SetPoint("BOTTOMRIGHT", profileFrame, "BOTTOMRIGHT", -10, 5)
                importButton:SetText("Import")
                importButton:SetScript("OnClick", function()
                    WR:Print("Importing profile: " .. profile.name)
                    
                    -- In a real implementation, this would get the profile data from the server
                    -- For this simulation, just show a success message
                    
                    WR:Print("Profile imported successfully!")
                end)
                
                currentY = currentY - profileFrame:GetHeight() - 10
            end
            
            featuredScrollChild:SetHeight(math.abs(currentY) + 10)
        end
        
        -- Update statistics
        local stats = self:GetCommunityMetrics()
        local statsX = 30
        local statsY = -10
        
        -- Clear existing stats
        for i = statsContainer:GetNumChildren(), 1, -1 do
            local child = select(i, statsContainer:GetChildren())
            child:Hide()
            child:SetParent(nil)
        end
        
        -- Display statistics in a grid (2x3)
        local statsList = {
            {name = "Total Users", value = stats.totalUsers},
            {name = "Active Users", value = stats.activeUsers},
            {name = "Total Profiles", value = stats.totalProfiles},
            {name = "Total Shares", value = stats.totalShares},
            {name = "Your Rank", value = stats.yourRank},
            {name = "Your Contributions", value = stats.yourContributions}
        }
        
        for i, stat in ipairs(statsList) do
            local col = (i - 1) % 3
            local row = math.floor((i - 1) / 3)
            
            local statFrame = CreateFrame("Frame", nil, statsContainer)
            statFrame:SetSize(statsContainer:GetWidth() / 3 - 20, 40)
            statFrame:SetPoint("TOPLEFT", statsContainer, "TOPLEFT", 
                statsX + col * (statsContainer:GetWidth() / 3), 
                statsY - row * 50)
            
            local nameText = statFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            nameText:SetPoint("TOP", statFrame, "TOP", 0, 0)
            nameText:SetText(stat.name)
            
            local valueText = statFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            valueText:SetPoint("TOP", nameText, "BOTTOM", 0, -5)
            valueText:SetText(stat.value)
        end
    end
    
    -- Function to simulate community sync
    function Community:SimulateCommunitySync()
        -- Simulate connection
        communityData.connectionStatus = "online"
        
        -- Generate announcements
        communityData.announcements = {
            {
                title = "Version 1.5.0 Released",
                date = time() - 86400 * 2,
                message = "We've released version 1.5.0 with major improvements to all class rotations and a completely revamped UI. Update now!"
            },
            {
                title = "New Discord Events",
                date = time() - 86400 * 5,
                message = "Join us on Discord for weekly community events, discussions, and live Q&A sessions with the developers."
            },
            {
                title = "Community Contributors Wanted",
                date = time() - 86400 * 10,
                message = "We're looking for community members to help with class rotation testing, documentation, and guide creation."
            }
        }
        
        -- Generate featured profiles
        communityData.featuredProfiles = {
            {
                name = "Mythic+ Havoc",
                author = "DemonSlayer",
                class = "Demon Hunter",
                spec = "Havoc",
                rating = 4.9,
                id = "mythic_havoc_123"
            },
            {
                name = "Raid Frost",
                author = "Winterchill",
                class = "Mage",
                spec = "Frost",
                rating = 4.8,
                id = "raid_frost_456"
            },
            {
                name = "PvP Shadow",
                author = "VoidMaster",
                class = "Priest",
                spec = "Shadow",
                rating = 4.7,
                id = "pvp_shadow_789"
            }
        }
        
        -- Generate top contributors
        communityData.topContributors = {
            {
                name = "RotationGuru",
                contributions = 256,
                rank = "Developer"
            },
            {
                name = "ClassMaster",
                contributions = 187,
                rank = "Theorycrafter"
            },
            {
                name = "UIWizard",
                contributions = 142,
                rank = "Designer"
            }
        }
        
        -- Generate guides
        communityData.guides = {
            {
                title = "Getting Started with Windrunner Rotations",
                author = "RotationGuru",
                category = "General",
                rating = 4.9,
                views = 15243
            },
            {
                title = "Advanced Frost Mage Guide",
                author = "Winterchill",
                category = "Class Guides",
                rating = 4.8,
                views = 8721
            },
            {
                title = "Mythic+ Dungeon Strategies",
                author = "KeyMaster",
                category = "PvE",
                rating = 4.7,
                views = 7359
            }
        }
        
        -- Generate leaderboards
        communityData.leaderboards = {
            dps = {
                {
                    name = "FireLord",
                    class = "Mage",
                    spec = "Fire",
                    value = 123456,
                    rank = 1
                },
                {
                    name = "ChaosBringer",
                    class = "Demon Hunter",
                    spec = "Havoc",
                    value = 123000,
                    rank = 2
                },
                {
                    name = "ShadowMaster",
                    class = "Priest",
                    spec = "Shadow",
                    value = 120500,
                    rank = 3
                }
            },
            healing = {
                {
                    name = "LifeGiver",
                    class = "Druid",
                    spec = "Restoration",
                    value = 87654,
                    rank = 1
                },
                {
                    name = "HolyLight",
                    class = "Paladin",
                    spec = "Holy",
                    value = 85432,
                    rank = 2
                },
                {
                    name = "MistWeaver",
                    class = "Monk",
                    spec = "Mistweaver",
                    value = 84321,
                    rank = 3
                }
            },
            contributions = {
                {
                    name = "RotationGuru",
                    class = "Mage",
                    contributions = 256,
                    rank = 1
                },
                {
                    name = "ClassMaster",
                    class = "Warrior",
                    contributions = 187,
                    rank = 2
                },
                {
                    name = "UIWizard",
                    class = "Druid",
                    contributions = 142,
                    rank = 3
                }
            }
        }
        
        -- Simulate user profile
        communityData.userProfile = {
            name = config.displayName,
            rank = config.communityRank,
            contributions = 5,
            joined = time() - 86400 * 30, -- Joined 30 days ago
            lastActive = time(),
            profiles = 3,
            ratings = 12,
            badges = {
                "Early Adopter",
                "Bug Hunter"
            }
        }
        
        -- Update UI to reflect new data
        self:UpdateHomeTab()
    }
    
    -- Run initial update
    Community:UpdateHomeTab()
    
    -- Select home tab by default
    tabs[1].selectedTexture:Show()
    tabContents[1]:Show()
    
    -- Hide by default
    frame:Hide()
    
    return frame
}

-- Create report UI
function Community:CreateReportUI(parent)
    if not parent then return end
    
    -- Create report frame
    local frame = CreateFrame("Frame", "WindrunnerRotationsReportFrame", parent, "BackdropTemplate")
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
    title:SetText("Report an Issue")
    
    -- Create close button
    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    
    -- Create report form
    local reportForm = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    reportForm:SetSize(frame:GetWidth() - 40, frame:GetHeight() - 60)
    reportForm:SetPoint("TOP", title, "BOTTOM", 0, -10)
    reportForm:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    reportForm:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
    
    -- Create form fields
    local titleLabel = reportForm:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleLabel:SetPoint("TOPLEFT", reportForm, "TOPLEFT", 15, -15)
    titleLabel:SetText("Issue Title:")
    
    local titleEdit = CreateFrame("EditBox", nil, reportForm, "InputBoxTemplate")
    titleEdit:SetSize(reportForm:GetWidth() - 30, 20)
    titleEdit:SetPoint("TOPLEFT", titleLabel, "BOTTOMLEFT", 5, -5)
    titleEdit:SetAutoFocus(false)
    
    local categoryLabel = reportForm:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    categoryLabel:SetPoint("TOPLEFT", titleEdit, "BOTTOMLEFT", -5, -15)
    categoryLabel:SetText("Category:")
    
    -- Create dropdown for categories
    local categoryDropdown = CreateFrame("Frame", "WindrunnerReportCategoryDropdown", reportForm, "UIDropDownMenuTemplate")
    categoryDropdown:SetPoint("TOPLEFT", categoryLabel, "BOTTOMLEFT", -5, -5)
    
    local selectedCategory = "Bug"
    
    UIDropDownMenu_SetWidth(categoryDropdown, 150)
    UIDropDownMenu_SetText(categoryDropdown, selectedCategory)
    
    UIDropDownMenu_Initialize(categoryDropdown, function(self, level, menuList)
        local categories = {"Bug", "Feature Request", "Performance Issue", "UI Problem", "Documentation", "Other"}
        
        local info = UIDropDownMenu_CreateInfo()
        for _, category in ipairs(categories) do
            info.text = category
            info.value = category
            info.checked = (selectedCategory == category)
            info.func = function(self)
                selectedCategory = self.value
                UIDropDownMenu_SetText(categoryDropdown, selectedCategory)
                CloseDropDownMenus()
            end
            UIDropDownMenu_AddButton(info)
        end
    end)
    
    local descLabel = reportForm:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    descLabel:SetPoint("TOPLEFT", categoryDropdown, "BOTTOMLEFT", 5, -15)
    descLabel:SetText("Description:")
    
    -- Create scrollable edit box for description
    local descScrollFrame = CreateFrame("ScrollFrame", nil, reportForm, "UIPanelScrollFrameTemplate")
    descScrollFrame:SetSize(reportForm:GetWidth() - 40, 120)
    descScrollFrame:SetPoint("TOPLEFT", descLabel, "BOTTOMLEFT", 5, -5)
    
    local descEdit = CreateFrame("EditBox", nil, descScrollFrame)
    descEdit:SetMultiLine(true)
    descEdit:SetSize(descScrollFrame:GetWidth(), 400)  -- Make it tall enough for scrolling
    descEdit:SetPoint("TOPLEFT", descScrollFrame, "TOPLEFT", 0, 0)
    descEdit:SetPoint("BOTTOMRIGHT", descScrollFrame, "BOTTOMRIGHT", 0, 0)
    descEdit:SetFontObject("ChatFontNormal")
    descEdit:SetAutoFocus(false)
    descEdit:SetScript("OnEscapePressed", function() descEdit:ClearFocus() end)
    descEdit:SetScript("OnTabPressed", function() descEdit:ClearFocus() end)
    
    descScrollFrame:SetScrollChild(descEdit)
    
    -- Create frame for data collection options
    local dataFrame = CreateFrame("Frame", nil, reportForm)
    dataFrame:SetSize(reportForm:GetWidth() - 30, 50)
    dataFrame:SetPoint("BOTTOM", reportForm, "BOTTOM", 0, 50)
    
    local includeSpecCheckbox = CreateFrame("CheckButton", nil, dataFrame, "UICheckButtonTemplate")
    includeSpecCheckbox:SetPoint("TOPLEFT", dataFrame, "TOPLEFT", 0, 0)
    includeSpecCheckbox:SetChecked(true)
    
    local includeSpecLabel = dataFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    includeSpecLabel:SetPoint("LEFT", includeSpecCheckbox, "RIGHT", 5, 0)
    includeSpecLabel:SetText("Include specialization data")
    
    local includeSettingsCheckbox = CreateFrame("CheckButton", nil, dataFrame, "UICheckButtonTemplate")
    includeSettingsCheckbox:SetPoint("TOPLEFT", includeSpecCheckbox, "BOTTOMLEFT", 0, -5)
    includeSettingsCheckbox:SetChecked(true)
    
    local includeSettingsLabel = dataFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    includeSettingsLabel:SetPoint("LEFT", includeSettingsCheckbox, "RIGHT", 5, 0)
    includeSettingsLabel:SetText("Include settings data")
    
    local includeDiagnosticsCheckbox = CreateFrame("CheckButton", nil, dataFrame, "UICheckButtonTemplate")
    includeDiagnosticsCheckbox:SetPoint("LEFT", includeSpecLabel, "RIGHT", 30, 0)
    includeDiagnosticsCheckbox:SetChecked(true)
    
    local includeDiagnosticsLabel = dataFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    includeDiagnosticsLabel:SetPoint("LEFT", includeDiagnosticsCheckbox, "RIGHT", 5, 0)
    includeDiagnosticsLabel:SetText("Include diagnostic data")
    
    local includeLogsCheckbox = CreateFrame("CheckButton", nil, dataFrame, "UICheckButtonTemplate")
    includeLogsCheckbox:SetPoint("LEFT", includeSettingsLabel, "RIGHT", 30, 0)
    includeLogsCheckbox:SetChecked(true)
    
    local includeLogsLabel = dataFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    includeLogsLabel:SetPoint("LEFT", includeLogsCheckbox, "RIGHT", 5, 0)
    includeLogsLabel:SetText("Include error logs")
    
    -- Create submit button
    local submitButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    submitButton:SetSize(100, 30)
    submitButton:SetPoint("BOTTOM", frame, "BOTTOM", 0, 15)
    submitButton:SetText("Submit")
    submitButton:SetScript("OnClick", function()
        -- Validate form
        if titleEdit:GetText() == "" then
            WR:Print("Please enter an issue title")
            return
        end
        
        if descEdit:GetText() == "" then
            WR:Print("Please enter a description")
            return
        end
        
        -- Create issue data
        local issueData = {
            title = titleEdit:GetText(),
            category = selectedCategory,
            description = descEdit:GetText(),
            includeSpec = includeSpecCheckbox:GetChecked(),
            includeSettings = includeSettingsCheckbox:GetChecked(),
            includeDiagnostics = includeDiagnosticsCheckbox:GetChecked(),
            includeLogs = includeLogsCheckbox:GetChecked()
        }
        
        -- Submit report
        local success, result = Community:ReportIssue(issueData)
        if success then
            WR:Print("Issue reported successfully. Thank you for your feedback!")
            
            -- Close the form
            frame:Hide()
            
            -- Clear the form
            titleEdit:SetText("")
            descEdit:SetText("")
        else
            WR:Print("Error reporting issue: " .. result)
        end
    end)
    
    -- Hide by default
    frame:Hide()
    
    return frame
}

-- Additional UI creator functions (stubbed for brevity)
function Community:CreateLeaderboardUI(parent)
    if not parent then return end
    
    -- Create a simple placeholder frame
    local frame = CreateFrame("Frame", "WindrunnerRotationsLeaderboardFrame", parent, "BackdropTemplate")
    frame:SetSize(600, 400)
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
    title:SetText("Windrunner Rotations Leaderboards")
    
    -- Create close button
    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    
    -- Add placeholder message
    local placeholder = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    placeholder:SetPoint("CENTER", frame, "CENTER", 0, 0)
    placeholder:SetText("Leaderboard data would be displayed here in the full implementation")
    
    -- Hide by default
    frame:Hide()
    
    return frame
}

function Community:CreateGuidesUI(parent)
    -- Similar stub implementation as CreateLeaderboardUI
    local frame = CreateFrame("Frame", "WindrunnerRotationsGuidesFrame", parent, "BackdropTemplate")
    frame:SetSize(600, 400)
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
    
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", frame, "TOP", 0, -15)
    title:SetText("Windrunner Rotations Guides")
    
    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    
    local placeholder = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    placeholder:SetPoint("CENTER", frame, "CENTER", 0, 0)
    placeholder:SetText("Community guides would be displayed here in the full implementation")
    
    frame:Hide()
    return frame
}

function Community:CreateProfilesUI(parent)
    -- Similar stub implementation as CreateLeaderboardUI
    local frame = CreateFrame("Frame", "WindrunnerRotationsProfilesFrame", parent, "BackdropTemplate")
    frame:SetSize(600, 400)
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
    
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", frame, "TOP", 0, -15)
    title:SetText("Windrunner Rotations Community Profiles")
    
    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    
    local placeholder = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    placeholder:SetPoint("CENTER", frame, "CENTER", 0, 0)
    placeholder:SetText("Community profiles would be displayed here in the full implementation")
    
    frame:Hide()
    return frame
}

-- Initialize the module
Community:Initialize()

return Community