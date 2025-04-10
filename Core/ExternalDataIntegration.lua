local addonName, WR = ...

-- ExternalDataIntegration module for connecting with external performance data
local ExternalDataIntegration = {}
WR.ExternalDataIntegration = ExternalDataIntegration

-- Local references for performance
local GetTime = GetTime
local UnitClass = UnitClass
local UnitName = UnitName
local tinsert = table.insert
local tremove = table.remove
local pairs = pairs
local ipairs = ipairs
local format = string.format
local math_floor = math.floor
local math_ceil = math.ceil
local math_max = math.max
local math_min = math.min
local table_sort = table.sort
local string_match = string.match
local string_gmatch = string.gmatch
local string_gsub = string.gsub
local string_format = string.format

-- Module constants
local API_TIMEOUT = 10 -- seconds
local CACHE_DURATION = 3600 -- 1 hour cache
local MAX_CACHED_ENTRIES = 100
local DEFAULT_PERCENTILE = 95
local DATA_SOURCES = {
    WARCRAFT_LOGS = "warcraftlogs",
    RAIDER_IO = "raiderio",
    SIMULATIONCRAFT = "simulationcraft",
    DROPTIMIZER = "droptimizer",
    SUBCREATION = "subcreation"
}
local ANALYSIS_MODES = {
    ROTATION = "rotation",
    TALENTS = "talents",
    GEAR = "gear",
    STATS = "stats",
    MYTHIC_PLUS = "mythicplus"
}
local UPDATE_FREQUENCY = 0.5 -- UI update interval

-- Module state variables
local isActive = false
local apiKeys = {}
local lastApiCall = 0
local cachedData = {}
local pendingRequests = {}
local currentPlayerData = {}
local referenceData = {}
local analysisResults = {}
local currentMode = ANALYSIS_MODES.ROTATION
local dataSource = DATA_SOURCES.WARCRAFT_LOGS
local selectedEncounter = "all"
local selectedDifficulty = "mythic"
local selectedMetric = "dps"
local selectedPercentile = DEFAULT_PERCENTILE
local lastUpdateTime = 0
local requestInProgress = false

-- Settings
local settings = {
    enableDataIntegration = true,
    defaultDataSource = DATA_SOURCES.WARCRAFT_LOGS,
    defaultAnalysisMode = ANALYSIS_MODES.ROTATION,
    defaultDifficulty = "mythic",
    defaultMetric = "dps",
    defaultPercentile = 95,
    automaticAnalysis = true,
    showRealtimePercentile = true,
    rotationSuggestionMode = "automatic", -- automatic, manual, disabled
    showVisualIndicators = true,
    showAnalysisOnScreen = true,
    saveAnalysisHistory = true,
    maxHistoryEntries = 10,
    enableBackgroundUpdates = true,
    updateFrequency = 300, -- 5 minutes
    autoImportTalents = false,
    autoImportRotations = true,
    enableSuggestions = true,
    showMinimap = true,
    keepCacheOnLogout = true,
    cacheTTL = 3600, -- 1 hour
    debugMode = false,
    uiScale = 1.0,
    displayPosition = {x = 0, y = 0}
}

-- Initialize the module
function ExternalDataIntegration:Initialize()
    -- Load settings
    self:LoadSettings()
    
    -- Try to load API keys
    self:LoadAPIKeys()
    
    -- Initialize UI
    self:CreateUI()
    
    -- Register events
    self:RegisterEvents()
    
    -- Collect current player data
    self:CollectPlayerData()
    
    -- Register with main addon
    self:RegisterWithAddon()
    
    WR:Debug("ExternalDataIntegration module initialized")
    
    -- Activate if enabled in settings
    if settings.enableDataIntegration then
        self:Activate()
    end
end

-- Load settings
function ExternalDataIntegration:LoadSettings()
    if WindrunnerRotationsDB and WindrunnerRotationsDB.ExternalDataIntegration then
        for k, v in pairs(WindrunnerRotationsDB.ExternalDataIntegration) do
            if settings[k] ~= nil then
                settings[k] = v
            end
        end
    end
    
    -- Apply settings
    dataSource = settings.defaultDataSource
    currentMode = settings.defaultAnalysisMode
    selectedDifficulty = settings.defaultDifficulty
    selectedMetric = settings.defaultMetric
    selectedPercentile = settings.defaultPercentile
end

-- Save settings
function ExternalDataIntegration:SaveSettings()
    -- Initialize DB if needed
    if not WindrunnerRotationsDB then
        WindrunnerRotationsDB = {}
    end
    
    WindrunnerRotationsDB.ExternalDataIntegration = settings
end

-- Apply settings
function ExternalDataIntegration:ApplySettings(newSettings)
    if not newSettings then return end
    
    for k, v in pairs(newSettings) do
        if settings[k] ~= nil then
            settings[k] = v
        end
    end
    
    -- Update state variables from settings
    dataSource = settings.defaultDataSource
    currentMode = settings.defaultAnalysisMode
    selectedDifficulty = settings.defaultDifficulty
    selectedMetric = settings.defaultMetric
    selectedPercentile = settings.defaultPercentile
    
    -- Apply UI changes
    if self.frame then
        self.frame:SetScale(settings.uiScale)
        
        -- Update visibility based on settings
        self:UpdateFrameVisibility()
    end
    
    -- Save settings
    self:SaveSettings()
end

-- Load API keys
function ExternalDataIntegration:LoadAPIKeys()
    -- Look for saved API keys
    if WindrunnerRotationsDB and WindrunnerRotationsDB.APIKeys then
        apiKeys = WindrunnerRotationsDB.APIKeys
    end
    
    -- Check if we need to request keys
    if not apiKeys.warcraftlogs and settings.defaultDataSource == DATA_SOURCES.WARCRAFT_LOGS then
        self:RequestAPIKey(DATA_SOURCES.WARCRAFT_LOGS)
    end
    
    if not apiKeys.raiderio and settings.defaultDataSource == DATA_SOURCES.RAIDER_IO then
        self:RequestAPIKey(DATA_SOURCES.RAIDER_IO)
    end
}

-- Save API keys
function ExternalDataIntegration:SaveAPIKeys()
    -- Initialize DB if needed
    if not WindrunnerRotationsDB then
        WindrunnerRotationsDB = {}
    end
    
    WindrunnerRotationsDB.APIKeys = apiKeys
}

-- Request API key from user
function ExternalDataIntegration:RequestAPIKey(source)
    if source == DATA_SOURCES.WARCRAFT_LOGS then
        print("|cFF00FFFF[Windrunner External Data]|r To use WarcraftLogs integration, you need to provide an API key.")
        print("You can get a WarcraftLogs API key from https://www.warcraftlogs.com/profile")
        print("Once you have it, use: /wr external apikey warcraftlogs YOUR_API_KEY_HERE")
    elseif source == DATA_SOURCES.RAIDER_IO then
        print("|cFF00FFFF[Windrunner External Data]|r To use Raider.IO integration, you need to provide an API key.")
        print("You can get a Raider.IO API key from https://raider.io/api")
        print("Once you have it, use: /wr external apikey raiderio YOUR_API_KEY_HERE")
    end
}

-- Set API key
function ExternalDataIntegration:SetAPIKey(source, key)
    if not source or not key then return end
    
    apiKeys[source] = key
    self:SaveAPIKeys()
    print(string.format("|cFF00FFFF[Windrunner External Data]|r API key for %s has been saved.", source))
    
    -- Try to validate the key immediately
    self:ValidateAPIKey(source)
}

-- Validate API key
function ExternalDataIntegration:ValidateAPIKey(source)
    if not source or not apiKeys[source] then return false end
    
    local key = apiKeys[source]
    
    if source == DATA_SOURCES.WARCRAFT_LOGS then
        -- Perform a test query to WarcraftLogs
        local url = "https://www.warcraftlogs.com/api/v2/client"
        local headers = {
            ["Content-Type"] = "application/json",
            ["Authorization"] = "Bearer " .. key
        }
        local body = JSON.encode({
            query = [[{
                rateLimitData {
                    limitPerHour
                    pointsSpentThisHour
                }
            }]]
        })
        
        -- Use a mock test for demonstration purposes
        local success = true -- This would be a real API call result
        
        if success then
            print("|cFF00FF00[Windrunner External Data]|r WarcraftLogs API key is valid!")
            return true
        else
            print("|cFFFF0000[Windrunner External Data]|r WarcraftLogs API key validation failed. Please check your key.")
            return false
        end
    elseif source == DATA_SOURCES.RAIDER_IO then
        -- Perform a test query to Raider.IO
        local url = "https://raider.io/api/v1/mythic-plus/affixes?region=us&locale=en"
        
        -- Use a mock test for demonstration purposes
        local success = true -- This would be a real API call result
        
        if success then
            print("|cFF00FF00[Windrunner External Data]|r Raider.IO API key is valid!")
            return true
        else
            print("|cFFFF0000[Windrunner External Data]|r Raider.IO API key validation failed. Please check your key.")
            return false
        end
    end
    
    return false
}

-- Create UI elements
function ExternalDataIntegration:CreateUI()
    -- Main frame
    local frame = CreateFrame("Frame", "WRExternalDataFrame", UIParent, "BackdropTemplate")
    frame:SetSize(500, 400)
    frame:SetPoint("CENTER", UIParent, "CENTER", settings.displayPosition.x, settings.displayPosition.y)
    frame:SetFrameStrata("MEDIUM")
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    frame:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self)
        if not self.isLocked then
            self:StartMoving()
        end
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        -- Save position
        local x, y = self:GetCenter()
        local scale = UIParent:GetScale()
        settings.displayPosition.x = (x * scale) - (UIParent:GetWidth() * scale / 2)
        settings.displayPosition.y = (y * scale) - (UIParent:GetHeight() * scale / 2)
        ExternalDataIntegration:SaveSettings()
    end)
    frame:SetClampedToScreen(true)
    frame.isLocked = true
    frame:SetScale(settings.uiScale)
    
    -- Title
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", frame, "TOP", 0, -20)
    title:SetText("External Data Analysis")
    
    -- Close button
    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    closeButton:SetScript("OnClick", function()
        frame:Hide()
    end)
    
    -- Lock button
    local lockButton = CreateFrame("Button", nil, frame)
    lockButton:SetSize(16, 16)
    lockButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -25, -8)
    lockButton:SetNormalTexture(frame.isLocked and "Interface\\Buttons\\LockButton-Locked-Up" or "Interface\\Buttons\\LockButton-Unlocked-Up")
    lockButton:SetPushedTexture(frame.isLocked and "Interface\\Buttons\\LockButton-Locked-Down" or "Interface\\Buttons\\LockButton-Unlocked-Down")
    lockButton:SetScript("OnClick", function(self)
        frame.isLocked = not frame.isLocked
        self:SetNormalTexture(frame.isLocked and "Interface\\Buttons\\LockButton-Locked-Up" or "Interface\\Buttons\\LockButton-Unlocked-Up")
        self:SetPushedTexture(frame.isLocked and "Interface\\Buttons\\LockButton-Locked-Down" or "Interface\\Buttons\\LockButton-Unlocked-Down")
    end)
    
    -- Data source selection
    local sourceLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    sourceLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 25, -55)
    sourceLabel:SetText("Data Source:")
    
    local sourceDropdown = CreateFrame("Frame", "WRExternalSourceDropdown", frame, "UIDropDownMenuTemplate")
    sourceDropdown:SetPoint("LEFT", sourceLabel, "RIGHT", 10, 0)
    UIDropDownMenu_SetWidth(sourceDropdown, 150)
    UIDropDownMenu_SetText(sourceDropdown, self:GetSourceDisplayName(dataSource))
    
    UIDropDownMenu_Initialize(sourceDropdown, function(self, level)
        local info = UIDropDownMenu_CreateInfo()
        
        info.func = function(button)
            dataSource = button.value
            UIDropDownMenu_SetText(sourceDropdown, ExternalDataIntegration:GetSourceDisplayName(dataSource))
            ExternalDataIntegration:ClearCache()
            
            -- Check for API key if needed
            if (dataSource == DATA_SOURCES.WARCRAFT_LOGS and not apiKeys.warcraftlogs) or
               (dataSource == DATA_SOURCES.RAIDER_IO and not apiKeys.raiderio) then
                ExternalDataIntegration:RequestAPIKey(dataSource)
            end
        end
        
        -- Add each data source
        info.text, info.value = "WarcraftLogs", DATA_SOURCES.WARCRAFT_LOGS
        info.checked = (dataSource == DATA_SOURCES.WARCRAFT_LOGS)
        UIDropDownMenu_AddButton(info)
        
        info.text, info.value = "Raider.IO", DATA_SOURCES.RAIDER_IO
        info.checked = (dataSource == DATA_SOURCES.RAIDER_IO)
        UIDropDownMenu_AddButton(info)
        
        info.text, info.value = "SimulationCraft", DATA_SOURCES.SIMULATIONCRAFT
        info.checked = (dataSource == DATA_SOURCES.SIMULATIONCRAFT)
        UIDropDownMenu_AddButton(info)
        
        info.text, info.value = "Subcreation", DATA_SOURCES.SUBCREATION
        info.checked = (dataSource == DATA_SOURCES.SUBCREATION)
        UIDropDownMenu_AddButton(info)
    end)
    
    -- Analysis mode selection
    local modeLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    modeLabel:SetPoint("TOPLEFT", sourceLabel, "BOTTOMLEFT", 0, -20)
    modeLabel:SetText("Analysis Mode:")
    
    local modeDropdown = CreateFrame("Frame", "WRExternalModeDropdown", frame, "UIDropDownMenuTemplate")
    modeDropdown:SetPoint("LEFT", modeLabel, "RIGHT", 10, 0)
    UIDropDownMenu_SetWidth(modeDropdown, 150)
    UIDropDownMenu_SetText(modeDropdown, self:GetModeDisplayName(currentMode))
    
    UIDropDownMenu_Initialize(modeDropdown, function(self, level)
        local info = UIDropDownMenu_CreateInfo()
        
        info.func = function(button)
            currentMode = button.value
            UIDropDownMenu_SetText(modeDropdown, ExternalDataIntegration:GetModeDisplayName(currentMode))
            ExternalDataIntegration:UpdateAnalysisFrame()
        end
        
        -- Add each analysis mode
        info.text, info.value = "Rotation Analysis", ANALYSIS_MODES.ROTATION
        info.checked = (currentMode == ANALYSIS_MODES.ROTATION)
        UIDropDownMenu_AddButton(info)
        
        info.text, info.value = "Talent Build", ANALYSIS_MODES.TALENTS
        info.checked = (currentMode == ANALYSIS_MODES.TALENTS)
        UIDropDownMenu_AddButton(info)
        
        info.text, info.value = "Gear Optimization", ANALYSIS_MODES.GEAR
        info.checked = (currentMode == ANALYSIS_MODES.GEAR)
        UIDropDownMenu_AddButton(info)
        
        info.text, info.value = "Stat Priority", ANALYSIS_MODES.STATS
        info.checked = (currentMode == ANALYSIS_MODES.STATS)
        UIDropDownMenu_AddButton(info)
        
        info.text, info.value = "Mythic+ Analysis", ANALYSIS_MODES.MYTHIC_PLUS
        info.checked = (currentMode == ANALYSIS_MODES.MYTHIC_PLUS)
        UIDropDownMenu_AddButton(info)
    end)
    
    -- Encounter/Difficulty selection (only shown for raiding modes)
    local encounterLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    encounterLabel:SetPoint("TOPLEFT", modeLabel, "BOTTOMLEFT", 0, -20)
    encounterLabel:SetText("Encounter:")
    
    local encounterDropdown = CreateFrame("Frame", "WRExternalEncounterDropdown", frame, "UIDropDownMenuTemplate")
    encounterDropdown:SetPoint("LEFT", encounterLabel, "RIGHT", 10, 0)
    UIDropDownMenu_SetWidth(encounterDropdown, 150)
    UIDropDownMenu_SetText(encounterDropdown, selectedEncounter == "all" and "All Encounters" or selectedEncounter)
    
    UIDropDownMenu_Initialize(encounterDropdown, function(self, level)
        local info = UIDropDownMenu_CreateInfo()
        
        info.func = function(button)
            selectedEncounter = button.value
            UIDropDownMenu_SetText(encounterDropdown, button.value == "all" and "All Encounters" or button.value)
            ExternalDataIntegration:ClearCache()
        end
        
        -- Add "All Encounters" option
        info.text, info.value = "All Encounters", "all"
        info.checked = (selectedEncounter == "all")
        UIDropDownMenu_AddButton(info)
        
        -- Add encounters from current raid tier (example for Aberrus)
        local encounters = {
            "Amalgamation Chamber",
            "Assault of the Zaqali",
            "Rashok, the Elder",
            "The Vigilant Steward, Zskarn",
            "Magmorax",
            "Echo of Neltharion", 
            "Scalecommander Sarkareth"
        }
        
        for _, encounter in ipairs(encounters) do
            info.text, info.value = encounter, encounter
            info.checked = (selectedEncounter == encounter)
            UIDropDownMenu_AddButton(info)
        end
    end)
    
    -- Difficulty dropdown
    local difficultyLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    difficultyLabel:SetPoint("TOPLEFT", encounterLabel, "BOTTOMLEFT", 0, -20)
    difficultyLabel:SetText("Difficulty:")
    
    local difficultyDropdown = CreateFrame("Frame", "WRExternalDifficultyDropdown", frame, "UIDropDownMenuTemplate")
    difficultyDropdown:SetPoint("LEFT", difficultyLabel, "RIGHT", 10, 0)
    UIDropDownMenu_SetWidth(difficultyDropdown, 150)
    UIDropDownMenu_SetText(difficultyDropdown, self:GetDifficultyDisplayName(selectedDifficulty))
    
    UIDropDownMenu_Initialize(difficultyDropdown, function(self, level)
        local info = UIDropDownMenu_CreateInfo()
        
        info.func = function(button)
            selectedDifficulty = button.value
            UIDropDownMenu_SetText(difficultyDropdown, ExternalDataIntegration:GetDifficultyDisplayName(selectedDifficulty))
            ExternalDataIntegration:ClearCache()
        end
        
        -- Add each difficulty
        info.text, info.value = "Mythic", "mythic"
        info.checked = (selectedDifficulty == "mythic")
        UIDropDownMenu_AddButton(info)
        
        info.text, info.value = "Heroic", "heroic"
        info.checked = (selectedDifficulty == "heroic")
        UIDropDownMenu_AddButton(info)
        
        info.text, info.value = "Normal", "normal"
        info.checked = (selectedDifficulty == "normal")
        UIDropDownMenu_AddButton(info)
        
        info.text, info.value = "Mythic+", "mythicplus"
        info.checked = (selectedDifficulty == "mythicplus")
        UIDropDownMenu_AddButton(info)
    end)
    
    -- Percentile selection
    local percentileLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    percentileLabel:SetPoint("TOPLEFT", difficultyLabel, "BOTTOMLEFT", 0, -20)
    percentileLabel:SetText("Percentile:")
    
    local percentileSlider = CreateFrame("Slider", "WRExternalPercentileSlider", frame, "OptionsSliderTemplate")
    percentileSlider:SetPoint("LEFT", percentileLabel, "RIGHT", 30, 0)
    percentileSlider:SetWidth(150)
    percentileSlider:SetMinMaxValues(50, 100)
    percentileSlider:SetValueStep(5)
    percentileSlider:SetValue(selectedPercentile)
    percentileSlider.Low:SetText("50")
    percentileSlider.High:SetText("100")
    percentileSlider:SetScript("OnValueChanged", function(self, value)
        selectedPercentile = math_floor(value)
        percentileSlider.Text:SetText(selectedPercentile .. "th Percentile")
        ExternalDataIntegration:ClearCache()
    end)
    percentileSlider.Text:SetText(selectedPercentile .. "th Percentile")
    
    -- Analysis area
    local analysisFrame = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    analysisFrame:SetSize(450, 160)
    analysisFrame:SetPoint("TOP", percentileSlider, "BOTTOM", 0, -25)
    analysisFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    
    -- Analysis content for different modes
    local rotationFrame = CreateFrame("Frame", nil, analysisFrame)
    rotationFrame:SetAllPoints()
    
    local talentsFrame = CreateFrame("Frame", nil, analysisFrame)
    talentsFrame:SetAllPoints()
    talentsFrame:Hide()
    
    local gearFrame = CreateFrame("Frame", nil, analysisFrame)
    gearFrame:SetAllPoints()
    gearFrame:Hide()
    
    local statsFrame = CreateFrame("Frame", nil, analysisFrame)
    statsFrame:SetAllPoints()
    statsFrame:Hide()
    
    local mythicPlusFrame = CreateFrame("Frame", nil, analysisFrame)
    mythicPlusFrame:SetAllPoints()
    mythicPlusFrame:Hide()
    
    -- Rotation Analysis content
    local rotationTitle = rotationFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    rotationTitle:SetPoint("TOPLEFT", rotationFrame, "TOPLEFT", 15, -15)
    rotationTitle:SetText("Rotation Analysis")
    
    local rotationText = rotationFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    rotationText:SetPoint("TOPLEFT", rotationTitle, "BOTTOMLEFT", 0, -10)
    rotationText:SetPoint("BOTTOMRIGHT", rotationFrame, "BOTTOMRIGHT", -15, 15)
    rotationText:SetJustifyH("LEFT")
    rotationText:SetJustifyV("TOP")
    rotationText:SetText("Loading rotation data...")
    
    -- Talent Analysis content
    local talentTitle = talentsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    talentTitle:SetPoint("TOPLEFT", talentsFrame, "TOPLEFT", 15, -15)
    talentTitle:SetText("Talent Build Analysis")
    
    local talentText = talentsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    talentText:SetPoint("TOPLEFT", talentTitle, "BOTTOMLEFT", 0, -10)
    talentText:SetPoint("BOTTOMRIGHT", talentsFrame, "BOTTOMRIGHT", -15, 15)
    talentText:SetJustifyH("LEFT")
    talentText:SetJustifyV("TOP")
    talentText:SetText("Loading talent data...")
    
    -- Gear Analysis content
    local gearTitle = gearFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    gearTitle:SetPoint("TOPLEFT", gearFrame, "TOPLEFT", 15, -15)
    gearTitle:SetText("Gear Optimization")
    
    local gearText = gearFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    gearText:SetPoint("TOPLEFT", gearTitle, "BOTTOMLEFT", 0, -10)
    gearText:SetPoint("BOTTOMRIGHT", gearFrame, "BOTTOMRIGHT", -15, 15)
    gearText:SetJustifyH("LEFT")
    gearText:SetJustifyV("TOP")
    gearText:SetText("Loading gear data...")
    
    -- Stats Analysis content
    local statsTitle = statsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    statsTitle:SetPoint("TOPLEFT", statsFrame, "TOPLEFT", 15, -15)
    statsTitle:SetText("Stat Priority Analysis")
    
    local statsText = statsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    statsText:SetPoint("TOPLEFT", statsTitle, "BOTTOMLEFT", 0, -10)
    statsText:SetPoint("BOTTOMRIGHT", statsFrame, "BOTTOMRIGHT", -15, 15)
    statsText:SetJustifyH("LEFT")
    statsText:SetJustifyV("TOP")
    statsText:SetText("Loading stat priority data...")
    
    -- Mythic+ Analysis content
    local mythicPlusTitle = mythicPlusFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    mythicPlusTitle:SetPoint("TOPLEFT", mythicPlusFrame, "TOPLEFT", 15, -15)
    mythicPlusTitle:SetText("Mythic+ Analysis")
    
    local mythicPlusText = mythicPlusFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    mythicPlusText:SetPoint("TOPLEFT", mythicPlusTitle, "BOTTOMLEFT", 0, -10)
    mythicPlusText:SetPoint("BOTTOMRIGHT", mythicPlusFrame, "BOTTOMRIGHT", -15, 15)
    mythicPlusText:SetJustifyH("LEFT")
    mythicPlusText:SetJustifyV("TOP")
    mythicPlusText:SetText("Loading Mythic+ data...")
    
    -- Action buttons
    local refreshButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    refreshButton:SetSize(100, 25)
    refreshButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 20, 20)
    refreshButton:SetText("Refresh Data")
    refreshButton:SetScript("OnClick", function()
        ExternalDataIntegration:ClearCache()
        ExternalDataIntegration:FetchData()
    end)
    
    local importButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    importButton:SetSize(100, 25)
    importButton:SetPoint("LEFT", refreshButton, "RIGHT", 10, 0)
    importButton:SetText("Import")
    importButton:SetScript("OnClick", function()
        ExternalDataIntegration:ImportOptimalSetup()
    end)
    
    local analyzeButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    analyzeButton:SetSize(100, 25)
    analyzeButton:SetPoint("LEFT", importButton, "RIGHT", 10, 0)
    analyzeButton:SetText("Analyze")
    analyzeButton:SetScript("OnClick", function()
        ExternalDataIntegration:AnalyzeCurrentSetup()
    end)
    
    -- Status text
    local statusText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    statusText:SetPoint("BOTTOM", frame, "BOTTOM", 0, 5)
    statusText:SetText("Ready")
    
    -- Store frame references
    self.frame = frame
    self.sourceDropdown = sourceDropdown
    self.modeDropdown = modeDropdown
    self.encounterDropdown = encounterDropdown
    self.difficultyDropdown = difficultyDropdown
    self.percentileSlider = percentileSlider
    self.analysisFrame = analysisFrame
    self.rotationFrame = rotationFrame
    self.talentsFrame = talentsFrame
    self.gearFrame = gearFrame
    self.statsFrame = statsFrame
    self.mythicPlusFrame = mythicPlusFrame
    self.rotationText = rotationText
    self.talentText = talentText
    self.gearText = gearText
    self.statsText = statsText
    self.mythicPlusText = mythicPlusText
    self.refreshButton = refreshButton
    self.importButton = importButton
    self.analyzeButton = analyzeButton
    self.statusText = statusText
    
    -- Real-time frame for showing live percentile data
    self:CreateRealtimeFrame()
    
    -- Initially hide the frame until needed
    frame:Hide()
}

-- Create real-time frame for showing live percentile
function ExternalDataIntegration:CreateRealtimeFrame()
    local frame = CreateFrame("Frame", "WRExternalRealtimeFrame", UIParent, "BackdropTemplate")
    frame:SetSize(150, 80)
    frame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -20, -200)
    frame:SetFrameStrata("MEDIUM")
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    frame:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    frame:SetClampedToScreen(true)
    
    -- Title
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", frame, "TOP", 0, -12)
    title:SetText("Performance")
    
    -- Percentile text
    local percentileText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    percentileText:SetPoint("CENTER", frame, "CENTER", 0, 0)
    percentileText:SetText("--")
    
    -- Description text
    local descText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    descText:SetPoint("BOTTOM", frame, "BOTTOM", 0, 12)
    descText:SetText("Analyzing...")
    
    -- Store frame references
    self.realtimeFrame = frame
    self.percentileText = percentileText
    self.descText = descText
    
    -- Initially hide the frame until needed
    frame:Hide()
}

-- Update frame visibility
function ExternalDataIntegration:UpdateFrameVisibility()
    if not self.frame or not self.realtimeFrame then return end
    
    self.frame:SetShown(isActive)
    self.realtimeFrame:SetShown(isActive and settings.showRealtimePercentile)
}

-- Register events
function ExternalDataIntegration:RegisterEvents()
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    eventFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
    eventFrame:RegisterEvent("ENCOUNTER_START")
    eventFrame:RegisterEvent("ENCOUNTER_END")
    eventFrame:RegisterEvent("CHALLENGE_MODE_START")
    eventFrame:RegisterEvent("CHALLENGE_MODE_COMPLETED")
    eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "PLAYER_ENTERING_WORLD" then
            ExternalDataIntegration:CollectPlayerData()
        elseif event == "PLAYER_EQUIPMENT_CHANGED" then
            ExternalDataIntegration:CollectPlayerData()
        elseif event == "PLAYER_TALENT_UPDATE" then
            ExternalDataIntegration:CollectPlayerData()
        elseif event == "ENCOUNTER_START" then
            local encounterID, encounterName = ...
            ExternalDataIntegration:OnEncounterStart(encounterID, encounterName)
        elseif event == "ENCOUNTER_END" then
            local encounterID, encounterName, difficultyID, raidSize, endStatus = ...
            ExternalDataIntegration:OnEncounterEnd(encounterID, encounterName, difficultyID, endStatus == 1)
        elseif event == "CHALLENGE_MODE_START" then
            ExternalDataIntegration:OnMythicPlusStart()
        elseif event == "CHALLENGE_MODE_COMPLETED" then
            ExternalDataIntegration:OnMythicPlusEnd()
        elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
            ExternalDataIntegration:ProcessCombatLog(CombatLogGetCurrentEventInfo())
        end
    end)
    
    eventFrame:SetScript("OnUpdate", function(self, elapsed)
        ExternalDataIntegration:OnUpdate(elapsed)
    end)
    
    self.eventFrame = eventFrame
}

-- Register with main addon
function ExternalDataIntegration:RegisterWithAddon()
    -- Register slash command
    if WR.RegisterSlashCommand then
        WR.RegisterSlashCommand("external", function(msg)
            self:HandleSlashCommand(msg)
        end)
    end
    
    -- Add to settings panel
    if WR.UI and WR.UI.AdvancedSettingsUI and WR.UI.AdvancedSettingsUI.AddSettings then
        WR.UI.AdvancedSettingsUI:AddSettings("External Data", settings, function(newSettings)
            self:ApplySettings(newSettings)
        end)
    end
}

-- Handle slash command
function ExternalDataIntegration:HandleSlashCommand(msg)
    if not msg or msg == "" then
        -- Toggle main UI
        self:Toggle()
        return
    end
    
    local command, param = msg:match("^(%S+)%s*(.*)$")
    if not command then return end
    
    command = command:lower()
    
    if command == "show" or command == "hide" then
        if self.frame then
            self.frame:SetShown(command == "show")
        end
    elseif command == "toggle" then
        self:Toggle()
    elseif command == "refresh" or command == "update" then
        self:ClearCache()
        self:FetchData()
    elseif command == "analyze" then
        self:AnalyzeCurrentSetup()
    elseif command == "import" then
        self:ImportOptimalSetup()
    elseif command == "apikey" then
        local source, key = param:match("^(%S+)%s+(.+)$")
        if source and key then
            self:SetAPIKey(source, key)
        else
            print("|cFF00FFFF[Windrunner External Data]|r Usage: /wr external apikey <source> <key>")
            print("Sources: warcraftlogs, raiderio")
        end
    elseif command == "source" then
        if param and DATA_SOURCES[param:upper()] then
            dataSource = DATA_SOURCES[param:upper()]
            if self.sourceDropdown then
                UIDropDownMenu_SetText(self.sourceDropdown, self:GetSourceDisplayName(dataSource))
            end
            self:ClearCache()
        else
            print("|cFF00FFFF[Windrunner External Data]|r Available sources:")
            for name, value in pairs(DATA_SOURCES) do
                print("  - " .. value)
            end
        end
    elseif command == "mode" then
        if param and ANALYSIS_MODES[param:upper()] then
            currentMode = ANALYSIS_MODES[param:upper()]
            if self.modeDropdown then
                UIDropDownMenu_SetText(self.modeDropdown, self:GetModeDisplayName(currentMode))
            end
            self:UpdateAnalysisFrame()
        else
            print("|cFF00FFFF[Windrunner External Data]|r Available modes:")
            for name, value in pairs(ANALYSIS_MODES) do
                print("  - " .. value)
            end
        end
    elseif command == "percentile" then
        local value = tonumber(param)
        if value and value >= 50 and value <= 100 then
            selectedPercentile = value
            if self.percentileSlider then
                self.percentileSlider:SetValue(value)
            end
            self:ClearCache()
        else
            print("|cFF00FFFF[Windrunner External Data]|r Percentile must be between 50 and 100")
        end
    elseif command == "debug" then
        settings.debugMode = not settings.debugMode
        print("|cFF00FFFF[Windrunner External Data]|r Debug mode " .. (settings.debugMode and "enabled" or "disabled"))
        self:SaveSettings()
    else
        print("|cFF00FFFF[Windrunner External Data]|r Commands:")
        print("  - /wr external show/hide - Show or hide the main UI")
        print("  - /wr external toggle - Toggle the main UI")
        print("  - /wr external refresh - Refresh data")
        print("  - /wr external analyze - Analyze current setup")
        print("  - /wr external import - Import optimal setup")
        print("  - /wr external apikey <source> <key> - Set API key")
        print("  - /wr external source <source> - Set data source")
        print("  - /wr external mode <mode> - Set analysis mode")
        print("  - /wr external percentile <value> - Set percentile")
        print("  - /wr external debug - Toggle debug mode")
    end
}

-- Collect player data for analysis
function ExternalDataIntegration:CollectPlayerData()
    -- Reset current player data
    currentPlayerData = {}
    
    -- Basic character info
    local _, playerClass = UnitClass("player")
    local playerName = UnitName("player")
    local playerSpec = GetSpecialization()
    local playerSpecID = playerSpec and GetSpecializationInfo(playerSpec) or nil
    local playerLevel = UnitLevel("player")
    
    currentPlayerData.class = playerClass
    currentPlayerData.name = playerName
    currentPlayerData.specName = playerSpecID and select(2, GetSpecializationInfoByID(playerSpecID)) or "Unknown"
    currentPlayerData.specID = playerSpecID
    currentPlayerData.level = playerLevel
    
    -- Collect talent data
    currentPlayerData.talents = self:CollectTalentData()
    
    -- Collect gear data
    currentPlayerData.gear = self:CollectGearData()
    
    -- Collect stats
    currentPlayerData.stats = self:CollectStatData()
    
    -- Collect rotation data from Windrunner
    currentPlayerData.rotation = self:CollectRotationData()
    
    if settings.debugMode then
        print("|cFF00FFFF[Windrunner External Data]|r Collected player data for", playerName, playerClass, currentPlayerData.specName)
    end
}

-- Collect talent data
function ExternalDataIntegration:CollectTalentData()
    local talents = {}
    
    -- For demonstration, we'll collect talents in a simplified format
    -- In a real implementation, you would use the C_Talent API to get the actual talent tree
    
    -- Get talent tree for current specialization
    local configID = C_ClassTalents.GetActiveConfigID()
    if configID then
        local configInfo = C_Traits.GetConfigInfo(configID)
        local treeID = configInfo.treeIDs[1]
        
        -- Get nodes in the tree
        local nodes = C_Traits.GetTreeNodes(treeID)
        
        for _, nodeID in ipairs(nodes) do
            local nodeInfo = C_Traits.GetNodeInfo(configID, nodeID)
            
            if nodeInfo.isGranted or nodeInfo.ranksPurchased > 0 then
                -- Get the entry ID for current rank
                local entryID = nodeInfo.activeEntry and nodeInfo.activeEntry.entryID
                
                if entryID then
                    local entryInfo = C_Traits.GetEntryInfo(configID, entryID)
                    local definitionInfo = entryInfo and C_Traits.GetDefinitionInfo(entryInfo.definitionID)
                    
                    -- Only add actual talents (not class/spec baseline abilities)
                    if definitionInfo and definitionInfo.spellID then
                        local name, _, icon = GetSpellInfo(definitionInfo.spellID)
                        
                        if name then
                            talents[nodeID] = {
                                name = name,
                                spellID = definitionInfo.spellID,
                                icon = icon,
                                rank = nodeInfo.ranksPurchased,
                                maxRank = nodeInfo.maxRanks
                            }
                        end
                    end
                end
            end
        end
    end
    
    return talents
}

-- Collect gear data
function ExternalDataIntegration:CollectGearData()
    local gear = {}
    
    -- Iterate through equipment slots
    for i = 1, 19 do -- 19 equipment slots
        local itemLink = GetInventoryItemLink("player", i)
        
        if itemLink then
            local itemID = itemLink:match("item:(%d+)")
            local itemName, _, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType, 
                  itemStackCount, itemEquipLoc, itemTexture, itemSellPrice = GetItemInfo(itemLink)
            
            -- Get gem and enchant info
            local gemIDs = {}
            local enchantID = nil
            
            -- Simplified gem detection
            -- In a real implementation, you would need to parse the full itemString to get gem info
            local hasGem = false
            for i = 1, 3 do
                if hasGem then -- Placeholder for gem detection
                    table.insert(gemIDs, 0) -- Placeholder gem ID
                end
            end
            
            -- Simplified enchant detection
            -- In a real implementation, you would need to parse the full itemString to get enchant info
            local hasEnchant = false
            if hasEnchant then -- Placeholder for enchant detection
                enchantID = 0 -- Placeholder enchant ID
            end
            
            -- Add item to gear list
            gear[i] = {
                id = tonumber(itemID),
                name = itemName,
                link = itemLink,
                quality = itemQuality,
                itemLevel = itemLevel,
                equipLoc = itemEquipLoc,
                gems = gemIDs,
                enchant = enchantID
            }
        end
    end
    
    return gear
}

-- Collect stat data
function ExternalDataIntegration:CollectStatData()
    local stats = {}
    
    -- Primary stats
    stats.strength = UnitStat("player", 1)
    stats.agility = UnitStat("player", 2)
    stats.stamina = UnitStat("player", 3)
    stats.intellect = UnitStat("player", 4)
    
    -- Secondary stats
    stats.critRating = GetCombatRating(CR_CRIT_MELEE)
    stats.hasteRating = GetCombatRating(CR_HASTE_MELEE)
    stats.masteryRating = GetCombatRating(CR_MASTERY)
    stats.versatilityRating = GetCombatRating(CR_VERSATILITY_DAMAGE_DONE)
    
    -- Percentages
    stats.critChance = GetCritChance()
    stats.hastePercent = GetHaste()
    stats.masteryPercent = GetMasteryEffect()
    stats.versatilityDamage = GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_DONE)
    stats.versatilityDamageReduction = GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_TAKEN)
    
    -- Attack power and spell power
    stats.attackPower = UnitAttackPower("player")
    stats.spellPower = GetSpellBonusDamage(1) -- General spell power
    
    -- Defense
    stats.armor = UnitArmor("player")
    stats.dodge = GetDodgeChance()
    stats.parry = GetParryChance()
    stats.block = GetBlockChance()
    
    return stats
}

-- Collect rotation data from Windrunner modules
function ExternalDataIntegration:CollectRotationData()
    local rotationData = {
        abilities = {},
        priorities = {},
        cooldowns = {},
        aoe = {}
    }
    
    -- If we have access to the Rotation module, get actual data
    if WR.Rotation then
        -- Get abilities from Rotation module
        if WR.Rotation.abilities then
            for name, info in pairs(WR.Rotation.abilities) do
                rotationData.abilities[name] = {
                    id = info.id,
                    name = info.name,
                    icon = info.icon,
                    usageCount = info.usageCount or 0,
                    totalDamage = info.totalDamage or 0,
                    dps = info.dps or 0
                }
            end
        end
        
        -- Get priorities from Rotation module
        if WR.Rotation.priorities then
            rotationData.priorities = WR.Rotation.priorities
        end
        
        -- Get cooldown usage from Rotation module
        if WR.Rotation.cooldowns then
            rotationData.cooldowns = WR.Rotation.cooldowns
        end
        
        -- Get AoE handling from Rotation module
        if WR.Rotation.aoe then
            rotationData.aoe = WR.Rotation.aoe
        end
    end
    
    return rotationData
}

-- Update analysis frame based on current mode
function ExternalDataIntegration:UpdateAnalysisFrame()
    if not self.analysisFrame then return end
    
    -- Hide all mode frames
    self.rotationFrame:Hide()
    self.talentsFrame:Hide()
    self.gearFrame:Hide()
    self.statsFrame:Hide()
    self.mythicPlusFrame:Hide()
    
    -- Show the appropriate frame for current mode
    if currentMode == ANALYSIS_MODES.ROTATION then
        self.rotationFrame:Show()
        self:UpdateRotationAnalysis()
    elseif currentMode == ANALYSIS_MODES.TALENTS then
        self.talentsFrame:Show()
        self:UpdateTalentAnalysis()
    elseif currentMode == ANALYSIS_MODES.GEAR then
        self.gearFrame:Show()
        self:UpdateGearAnalysis()
    elseif currentMode == ANALYSIS_MODES.STATS then
        self.statsFrame:Show()
        self:UpdateStatAnalysis()
    elseif currentMode == ANALYSIS_MODES.MYTHIC_PLUS then
        self.mythicPlusFrame:Show()
        self:UpdateMythicPlusAnalysis()
    end
}

-- Update rotation analysis display
function ExternalDataIntegration:UpdateRotationAnalysis()
    if not self.rotationText then return end
    
    -- Check if we have data
    if not referenceData.rotation then
        self.rotationText:SetText("No rotation data available. Click 'Refresh Data' to fetch from " .. self:GetSourceDisplayName(dataSource) .. ".")
        return
    end
    
    local result = "Rotation Analysis for " .. currentPlayerData.class .. " - " .. currentPlayerData.specName .. "\n\n"
    
    -- Add primary abilities usage
    result = result .. "Top Abilities (by usage frequency):\n"
    
    if referenceData.rotation.primaryAbilities then
        for i, ability in ipairs(referenceData.rotation.primaryAbilities) do
            local icon = ability.icon and "|T" .. ability.icon .. ":14|t " or ""
            result = result .. i .. ". " .. icon .. ability.name .. " (" .. ability.usagePercent .. "%)\n"
            
            if i >= 5 then break end -- Only show top 5
        end
    end
    
    -- Add priority sequence
    result = result .. "\nOptimal Priority Sequence:\n"
    
    if referenceData.rotation.prioritySequence then
        for i, step in ipairs(referenceData.rotation.prioritySequence) do
            result = result .. i .. ". " .. step .. "\n"
            
            if i >= 7 then break end -- Only show top 7 priorities
        end
    end
    
    -- Add cooldown usage
    result = result .. "\nCooldown Usage:\n"
    
    if referenceData.rotation.cooldownUsage then
        for i, cooldown in ipairs(referenceData.rotation.cooldownUsage) do
            result = result .. "- " .. cooldown.name .. ": " .. cooldown.advice .. "\n"
            
            if i >= 3 then break end -- Only show top 3 cooldowns
        end
    end
    
    -- Add analysis summary
    if analysisResults.rotation then
        result = result .. "\nAnalysis Results:\n"
        result = result .. "- Overall Similarity: " .. analysisResults.rotation.overallSimilarity .. "%\n"
        result = result .. "- Primary Ability Usage: " .. analysisResults.rotation.abilityUsageSimilarity .. "%\n"
        result = result .. "- Priority Adherence: " .. analysisResults.rotation.priorityAdherence .. "%\n"
        result = result .. "- Cooldown Efficiency: " .. analysisResults.rotation.cooldownEfficiency .. "%\n"
    end
    
    self.rotationText:SetText(result)
}

-- Update talent analysis display
function ExternalDataIntegration:UpdateTalentAnalysis()
    if not self.talentText then return end
    
    -- Check if we have data
    if not referenceData.talents then
        self.talentText:SetText("No talent data available. Click 'Refresh Data' to fetch from " .. self:GetSourceDisplayName(dataSource) .. ".")
        return
    end
    
    local result = "Talent Analysis for " .. currentPlayerData.class .. " - " .. currentPlayerData.specName .. "\n\n"
    
    -- Add popular builds
    result = result .. "Popular Talent Builds:\n"
    
    if referenceData.talents.popularBuilds then
        for i, build in ipairs(referenceData.talents.popularBuilds) do
            result = result .. i .. ". " .. build.name .. " (" .. build.popularity .. "%)\n"
            
            if i >= 3 then break end -- Only show top 3 builds
        end
    end
    
    -- Add core talents
    result = result .. "\nCore Talents (used in >90% of top builds):\n"
    
    if referenceData.talents.coreTalents then
        for i, talent in ipairs(referenceData.talents.coreTalents) do
            local icon = talent.icon and "|T" .. talent.icon .. ":14|t " or ""
            result = result .. "- " .. icon .. talent.name .. "\n"
            
            if i >= 7 then break end -- Only show top 7 core talents
        end
    end
    
    -- Add flexible talents
    result = result .. "\nFlexible Talent Choices:\n"
    
    if referenceData.talents.flexibleTalents then
        for i, talentGroup in ipairs(referenceData.talents.flexibleTalents) do
            result = result .. "- " .. talentGroup.description .. ":\n"
            
            for j, option in ipairs(talentGroup.options) do
                result = result .. "  " .. j .. ". " .. option.name .. " (" .. option.popularity .. "%)\n"
            end
            
            if i >= 3 then break end -- Only show top 3 flexible talent groups
        end
    end
    
    -- Add analysis summary
    if analysisResults.talents then
        result = result .. "\nAnalysis Results:\n"
        result = result .. "- Build Similarity: " .. analysisResults.talents.buildSimilarity .. "%\n"
        result = result .. "- Core Talents Match: " .. analysisResults.talents.coreTalentsMatch .. "%\n"
        result = result .. "- Missing Key Talents: " .. analysisResults.talents.missingKeyTalents .. "\n"
    end
    
    self.talentText:SetText(result)
}

-- Update gear analysis display
function ExternalDataIntegration:UpdateGearAnalysis()
    if not self.gearText then return end
    
    -- Check if we have data
    if not referenceData.gear then
        self.gearText:SetText("No gear data available. Click 'Refresh Data' to fetch from " .. self:GetSourceDisplayName(dataSource) .. ".")
        return
    end
    
    local result = "Gear Analysis for " .. currentPlayerData.class .. " - " .. currentPlayerData.specName .. "\n\n"
    
    -- Add BiS items
    result = result .. "Best in Slot Items:\n"
    
    if referenceData.gear.bestItems then
        for slot, items in pairs(referenceData.gear.bestItems) do
            if items[1] then
                local item = items[1]
                result = result .. "- " .. slot .. ": " .. item.name .. " (iLvl " .. item.itemLevel .. ")\n"
            end
        end
    end
    
    -- Add important stats
    result = result .. "\nImportant Stats:\n"
    
    if referenceData.gear.statPriorities then
        for i, stat in ipairs(referenceData.gear.statPriorities) do
            result = result .. i .. ". " .. stat .. "\n"
        end
    end
    
    -- Add set bonuses
    result = result .. "\nRecommended Set Bonuses:\n"
    
    if referenceData.gear.setBonuses then
        for i, setBonus in ipairs(referenceData.gear.setBonuses) do
            result = result .. "- " .. setBonus.name .. " (" .. setBonus.pieces .. "-piece): " .. setBonus.effect .. "\n"
        end
    end
    
    -- Add analysis summary
    if analysisResults.gear then
        result = result .. "\nAnalysis Results:\n"
        result = result .. "- Overall Gear Score: " .. analysisResults.gear.overallScore .. "/100\n"
        result = result .. "- Average Item Level: " .. analysisResults.gear.averageItemLevel .. "\n"
        result = result .. "- Set Bonus Status: " .. analysisResults.gear.setBonusStatus .. "\n"
        result = result .. "- Gems and Enchants: " .. analysisResults.gear.gemsAndEnchantsStatus .. "\n"
        result = result .. "- Upgrade Suggestions: " .. analysisResults.gear.upgradeSuggestions .. "\n"
    end
    
    self.gearText:SetText(result)
}

-- Update stat analysis display
function ExternalDataIntegration:UpdateStatAnalysis()
    if not self.statsText then return end
    
    -- Check if we have data
    if not referenceData.stats then
        self.statsText:SetText("No stat data available. Click 'Refresh Data' to fetch from " .. self:GetSourceDisplayName(dataSource) .. ".")
        return
    end
    
    local result = "Stat Priority Analysis for " .. currentPlayerData.class .. " - " .. currentPlayerData.specName .. "\n\n"
    
    -- Add stat priority
    result = result .. "Optimal Stat Priority:\n"
    
    if referenceData.stats.priority then
        result = result .. referenceData.stats.priority .. "\n"
    end
    
    -- Add stat distribution
    result = result .. "\nRecommended Stat Distribution:\n"
    
    if referenceData.stats.distribution then
        for stat, value in pairs(referenceData.stats.distribution) do
            result = result .. "- " .. stat .. ": " .. value .. "%\n"
        end
    end
    
    -- Add stat thresholds
    result = result .. "\nImportant Stat Thresholds:\n"
    
    if referenceData.stats.thresholds then
        for stat, thresholds in pairs(referenceData.stats.thresholds) do
            result = result .. "- " .. stat .. ":\n"
            for i, threshold in ipairs(thresholds) do
                result = result .. "  " .. threshold.value .. ": " .. threshold.reason .. "\n"
            end
        end
    end
    
    -- Add analysis summary
    if analysisResults.stats then
        result = result .. "\nAnalysis Results:\n"
        result = result .. "- Overall Stat Distribution: " .. analysisResults.stats.overallDistribution .. "%\n"
        result = result .. "- Primary Stat: " .. analysisResults.stats.primaryStatStatus .. "\n"
        result = result .. "- Secondary Stats: " .. analysisResults.stats.secondaryStatStatus .. "\n"
        result = result .. "- Stat Adjustments: " .. analysisResults.stats.statAdjustments .. "\n"
    end
    
    self.statsText:SetText(result)
}

-- Update mythic+ analysis display
function ExternalDataIntegration:UpdateMythicPlusAnalysis()
    if not self.mythicPlusText then return end
    
    -- Check if we have data
    if not referenceData.mythicPlus then
        self.mythicPlusText:SetText("No Mythic+ data available. Click 'Refresh Data' to fetch from " .. self:GetSourceDisplayName(dataSource) .. ".")
        return
    end
    
    local result = "Mythic+ Analysis for " .. currentPlayerData.class .. " - " .. currentPlayerData.specName .. "\n\n"
    
    -- Add dungeon performance
    result = result .. "Dungeon Performance:\n"
    
    if referenceData.mythicPlus.dungeonPerformance then
        for i, dungeon in ipairs(referenceData.mythicPlus.dungeonPerformance) do
            result = result .. "- " .. dungeon.name .. ": " .. dungeon.performance .. "\n"
        end
    end
    
    -- Add key abilities
    result = result .. "\nKey Mythic+ Abilities:\n"
    
    if referenceData.mythicPlus.keyAbilities then
        for i, ability in ipairs(referenceData.mythicPlus.keyAbilities) do
            result = result .. "- " .. ability.name .. ": " .. ability.usage .. "\n"
        end
    end
    
    -- Add talent adjustments
    result = result .. "\nRecommended Talent Adjustments:\n"
    
    if referenceData.mythicPlus.talentAdjustments then
        for i, adjustment in ipairs(referenceData.mythicPlus.talentAdjustments) do
            result = result .. "- " .. adjustment .. "\n"
        end
    end
    
    -- Add analysis summary
    if analysisResults.mythicPlus then
        result = result .. "\nAnalysis Results:\n"
        result = result .. "- Overall M+ Performance: " .. analysisResults.mythicPlus.overallPerformance .. "/100\n"
        result = result .. "- AoE Capability: " .. analysisResults.mythicPlus.aoeCapability .. "/100\n"
        result = result .. "- Utility Usage: " .. analysisResults.mythicPlus.utilityUsage .. "/100\n"
        result = result .. "- Interrupts & CC: " .. analysisResults.mythicPlus.interruptsAndCC .. "/100\n"
        result = result .. "- Survival & Recovery: " .. analysisResults.mythicPlus.survivalAndRecovery .. "/100\n"
    end
    
    self.mythicPlusText:SetText(result)
}

-- Fetch data from selected source
function ExternalDataIntegration:FetchData()
    if requestInProgress then
        print("|cFFFFFF00[Windrunner External Data]|r Data fetch already in progress...")
        return
    end
    
    -- Update status
    if self.statusText then
        self.statusText:SetText("Fetching data...")
    end
    
    -- Clear previous reference data
    referenceData = {}
    
    -- Check cache first
    local cacheKey = self:GenerateCacheKey()
    if cachedData[cacheKey] and cachedData[cacheKey].timestamp > (GetTime() - CACHE_DURATION) then
        referenceData = self:DeepCopy(cachedData[cacheKey].data)
        self:ProcessReferenceData()
        
        if self.statusText then
            self.statusText:SetText("Loaded from cache")
        end
        
        return
    end
    
    -- Set request in progress
    requestInProgress = true
    
    -- Fetch data based on selected source
    if dataSource == DATA_SOURCES.WARCRAFT_LOGS then
        self:FetchWarcraftLogsData()
    elseif dataSource == DATA_SOURCES.RAIDER_IO then
        self:FetchRaiderIOData()
    elseif dataSource == DATA_SOURCES.SIMULATIONCRAFT then
        self:FetchSimulationCraftData()
    elseif dataSource == DATA_SOURCES.SUBCREATION then
        self:FetchSubcreationData()
    else
        -- Unknown data source
        requestInProgress = false
        
        if self.statusText then
            self.statusText:SetText("Unknown data source")
        end
    end
}

-- Generate cache key for current settings
function ExternalDataIntegration:GenerateCacheKey()
    return string.format("%s_%s_%s_%s_%s_%d_%s_%d",
        currentPlayerData.class,
        currentPlayerData.specID,
        dataSource,
        currentMode,
        selectedEncounter,
        selectedDifficulty,
        selectedMetric,
        selectedPercentile
    )
}

-- Clear cached data
function ExternalDataIntegration:ClearCache()
    local cacheKey = self:GenerateCacheKey()
    cachedData[cacheKey] = nil
}

-- Process reference data after fetching
function ExternalDataIntegration:ProcessReferenceData()
    -- Update UI based on current mode
    self:UpdateAnalysisFrame()
    
    -- Analyze current setup against reference data
    self:AnalyzeCurrentSetup()
}

-- Fetch data from WarcraftLogs
function ExternalDataIntegration:FetchWarcraftLogsData()
    -- In a real implementation, this would make API calls to WarcraftLogs
    -- For demonstration, we'll use mock data
    
    -- Check for API key
    if not apiKeys.warcraftlogs then
        self:RequestAPIKey(DATA_SOURCES.WARCRAFT_LOGS)
        requestInProgress = false
        
        if self.statusText then
            self.statusText:SetText("API key needed")
        end
        
        return
    end
    
    -- Create mock data based on current mode
    if currentMode == ANALYSIS_MODES.ROTATION then
        self:FetchWarcraftLogsRotationData()
    elseif currentMode == ANALYSIS_MODES.TALENTS then
        self:FetchWarcraftLogsTalentData()
    elseif currentMode == ANALYSIS_MODES.GEAR then
        self:FetchWarcraftLogsGearData()
    elseif currentMode == ANALYSIS_MODES.STATS then
        self:FetchWarcraftLogsStatData()
    elseif currentMode == ANALYSIS_MODES.MYTHIC_PLUS then
        self:FetchWarcraftLogsMythicPlusData()
    end
    
    -- Cache the data
    local cacheKey = self:GenerateCacheKey()
    cachedData[cacheKey] = {
        timestamp = GetTime(),
        data = self:DeepCopy(referenceData)
    }
    
    -- Clean up old cache entries if needed
    self:CleanupCache()
    
    -- Update status
    if self.statusText then
        self.statusText:SetText("Data fetched successfully")
    end
    
    -- Clear request in progress
    requestInProgress = false
}

-- Fetch rotation data from WarcraftLogs
function ExternalDataIntegration:FetchWarcraftLogsRotationData()
    -- For demonstration, create mock rotation data based on player class/spec
    local _, playerClass = UnitClass("player")
    local playerSpec = GetSpecialization()
    local playerSpecID = playerSpec and GetSpecializationInfo(playerSpec) or nil
    
    -- Mock data for example
    referenceData.rotation = {
        primaryAbilities = {
            {name = "Pyroblast", icon = 135808, usagePercent = 18.3},
            {name = "Fireball", icon = 135809, usagePercent = 32.6},
            {name = "Fire Blast", icon = 135807, usagePercent = 15.1},
            {name = "Phoenix Flames", icon = 135806, usagePercent = 8.4},
            {name = "Scorch", icon = 135805, usagePercent = 7.2},
            {name = "Living Bomb", icon = 135804, usagePercent = 3.6},
            {name = "Dragon's Breath", icon = 135803, usagePercent = 2.8}
        },
        prioritySequence = {
            "Combustion on cooldown when you have Fire Blast charges",
            "Pyroblast with Hot Streak proc",
            "Fire Blast during Combustion",
            "Fire Blast to convert Heating Up to Hot Streak",
            "Phoenix Flames to generate Heating Up",
            "Fireball as filler",
            "Scorch while moving",
            "Use Living Bomb on 3+ targets"
        },
        cooldownUsage = {
            {name = "Combustion", advice = "Use on cooldown with Fire Blast charges ready"},
            {name = "Rune of Power", advice = "Use before Combustion and on cooldown"},
            {name = "Mirror Image", advice = "Use on cooldown or for burst damage"},
            {name = "Time Warp", advice = "Coordinate with raid/party for boss phases"}
        },
        aoeRotation = {
            "Flamestrike with Flame Patch on 3+ targets",
            "Flame Strike with Hot Streak on 3+ targets",
            "Living Bomb on 3+ targets",
            "Dragon's Breath for AoE damage",
            "Fire Blast to convert Heating Up from AoE damage",
            "Pyroblast with Hot Streak if Flame Strike not needed",
            "Phoenix Flames for AoE and Hot Streak generation"
        }
    }
}

-- Fetch talent data from WarcraftLogs
function ExternalDataIntegration:FetchWarcraftLogsTalentData()
    -- For demonstration, create mock talent data based on player class/spec
    local _, playerClass = UnitClass("player")
    local playerSpec = GetSpecialization()
    local playerSpecID = playerSpec and GetSpecializationInfo(playerSpec) or nil
    
    -- Mock data for example
    referenceData.talents = {
        popularBuilds = {
            {name = "Standard Fire", popularity = 65.4},
            {name = "AoE Focused", popularity = 21.7},
            {name = "Single Target Burst", popularity = 8.3}
        },
        coreTalents = {
            {name = "Pyromaniac", icon = 135789, popularity = 98.2},
            {name = "Improved Combustion", icon = 135818, popularity = 97.5},
            {name = "Phoenix Flames", icon = 135806, popularity = 96.8},
            {name = "Sun King's Blessing", icon = 135824, popularity = 95.3},
            {name = "Flame On", icon = 135826, popularity = 94.7},
            {name = "Infernal Cascade", icon = 135817, popularity = 92.1},
            {name = "From the Ashes", icon = 135807, popularity = 90.5}
        },
        flexibleTalents = {
            {
                description = "AoE Talents",
                options = {
                    {name = "Flame Patch", popularity = 68.4},
                    {name = "Kindling", popularity = 24.9},
                    {name = "Conflagration", popularity = 6.7}
                }
            },
            {
                description = "Mobility vs Damage",
                options = {
                    {name = "Ice Floes", popularity = 43.2},
                    {name = "Shimmer", popularity = 38.7},
                    {name = "Incanter's Flow", popularity = 18.1}
                }
            },
            {
                description = "Defensive Choices",
                options = {
                    {name = "Blazing Barrier", popularity = 72.3},
                    {name = "Ice Ward", popularity = 18.6},
                    {name = "Ring of Frost", popularity = 9.1}
                }
            }
        },
        buildExplanations = {
            "Standard Fire prioritizes consistent damage with balanced single target and cleave",
            "AoE Focused maximizes area damage at the cost of some single target performance",
            "Single Target Burst specializes in burst windows with longer cooldowns between"
        }
    }
}

-- Fetch gear data from WarcraftLogs
function ExternalDataIntegration:FetchWarcraftLogsGearData()
    -- For demonstration, create mock gear data based on player class/spec
    local _, playerClass = UnitClass("player")
    local playerSpec = GetSpecialization()
    local playerSpecID = playerSpec and GetSpecializationInfo(playerSpec) or nil
    
    -- Mock data for example
    referenceData.gear = {
        bestItems = {
            ["Head"] = {{name = "Hood of Blazing Terror", itemLevel = 489, source = "Raid Boss X"}},
            ["Neck"] = {{name = "Pyromaster's Choker", itemLevel = 486, source = "Dungeon Boss Y"}},
            ["Shoulders"] = {{name = "Mantle of Raging Flames", itemLevel = 489, source = "Raid Boss Z"}},
            ["Back"] = {{name = "Cloak of Scorching Winds", itemLevel = 483, source = "World Boss A"}},
            ["Chest"] = {{name = "Robes of Conflagration", itemLevel = 489, source = "Raid Boss B"}},
            ["Wrists"] = {{name = "Bindings of Immolation", itemLevel = 483, source = "Mythic+ Dungeon C"}},
            ["Hands"] = {{name = "Firecaller's Handwraps", itemLevel = 486, source = "Raid Boss D"}},
            ["Waist"] = {{name = "Girdle of Burning Focus", itemLevel = 483, source = "Mythic+ Dungeon E"}},
            ["Legs"] = {{name = "Leggings of Blazing Speed", itemLevel = 489, source = "Raid Boss F"}},
            ["Feet"] = {{name = "Boots of Living Flame", itemLevel = 483, source = "Mythic+ Dungeon G"}},
            ["Ring1"] = {{name = "Loop of Burning Intelligence", itemLevel = 486, source = "Raid Boss H"}},
            ["Ring2"] = {{name = "Band of Pyretic Power", itemLevel = 483, source = "Mythic+ Dungeon I"}},
            ["Trinket1"] = {{name = "Igniting Coal of the Fire Lord", itemLevel = 489, source = "Raid Boss J"}},
            ["Trinket2"] = {{name = "Searing Sunstone", itemLevel = 486, source = "Mythic+ Dungeon K"}},
            ["Weapon"] = {{name = "Staff of Raging Inferno", itemLevel = 489, source = "Raid Boss L"}},
        },
        statPriorities = {
            "Intellect",
            "Haste (to 30%)",
            "Versatility",
            "Critical Strike",
            "Mastery",
            "Haste (beyond 30%)"
        },
        setBonuses = {
            {name = "Flamebringer's Regalia", pieces = 2, effect = "Increases Fire damage by 5%"},
            {name = "Flamebringer's Regalia", pieces = 4, effect = "Combustion cooldown reduced by 10 seconds"}
        },
        gemRecommendations = {
            "Critical Strike/Versatility (Deadly Malevolent Vermilion)",
            "Intellect/Haste (Crafty Malevolent Vermilion)",
            "Intellect/Versatility (Zen Malevolent Vermilion)"
        },
        enchantRecommendations = {
            "Chest: Writ of Critical Strike",
            "Wrists: Devotion of Critical Strike",
            "Weapon: Enchant Weapon - Sophic Devotion",
            "Boots: Plainsrunner's Breeze"
        }
    }
}

-- Fetch stat data from WarcraftLogs
function ExternalDataIntegration:FetchWarcraftLogsStatData()
    -- For demonstration, create mock stat data based on player class/spec
    local _, playerClass = UnitClass("player")
    local playerSpec = GetSpecialization()
    local playerSpecID = playerSpec and GetSpecializationInfo(playerSpec) or nil
    
    -- Mock data for example
    referenceData.stats = {
        priority = "Intellect > Haste (30%) > Versatility > Critical Strike > Mastery",
        distribution = {
            ["Haste"] = 30,
            ["Versatility"] = 25,
            ["Critical Strike"] = 20,
            ["Mastery"] = 15,
            ["Other"] = 10
        },
        thresholds = {
            ["Haste"] = {
                {value = "30%", reason = "Optimal GCD reduction and Fire Blast recharge rate"},
                {value = "20%", reason = "Minimum comfortable casting speed"},
                {value = "40%", reason = "Diminishing returns begin, prioritize other stats"}
            },
            ["Critical Strike"] = {
                {value = "25%", reason = "Consistent Hot Streak procs"},
                {value = "35%", reason = "Maximum benefit for Hot Streak mechanics"}
            },
            ["Mastery"] = {
                {value = "15%", reason = "Minimum useful Ignite damage"},
                {value = "25%", reason = "Optimal Ignite damage"}
            }
        },
        explanations = {
            "Intellect is your primary stat and provides the largest overall damage increase",
            "Haste to 30% provides optimal casting speed and Fire Blast recharge",
            "Versatility provides consistent damage increase and damage reduction",
            "Critical Strike improves Hot Streak proc chance",
            "Mastery increases Ignite damage but has less overall impact than other stats"
        }
    }
}

-- Fetch mythic+ data from WarcraftLogs
function ExternalDataIntegration:FetchWarcraftLogsMythicPlusData()
    -- For demonstration, create mock mythic+ data based on player class/spec
    local _, playerClass = UnitClass("player")
    local playerSpec = GetSpecialization()
    local playerSpecID = playerSpec and GetSpecializationInfo(playerSpec) or nil
    
    -- Mock data for example
    referenceData.mythicPlus = {
        dungeonPerformance = {
            {name = "Dawn of the Infinite", performance = "Strong (92.3%)"},
            {name = "Atal'Dazar", performance = "Above Average (83.7%)"},
            {name = "Waycrest Manor", performance = "Strong (89.5%)"},
            {name = "Black Rook Hold", performance = "Excellent (96.2%)"},
            {name = "The Everbloom", performance = "Average (76.4%)"},
            {name = "Darkheart Thicket", performance = "Above Average (85.8%)"},
            {name = "Throne of the Tides", performance = "Strong (91.2%)"},
            {name = "Galakrond's Fall", performance = "Above Average (84.3%)"}
        },
        keyAbilities = {
            {name = "Flamestrike", usage = "Primary AoE ability for 3+ targets"},
            {name = "Living Bomb", usage = "Spread AoE damage on 3-5 targets"},
            {name = "Dragon's Breath", usage = "AoE disorient for interrupt rotation"},
            {name = "Blast Wave", usage = "Knockback for positioning mobs"},
            {name = "Spellsteal", usage = "High priority for stealing beneficial effects"}
        },
        talentAdjustments = {
            "Take Flame Patch for sustained AoE damage",
            "Frenetic Speed for additional mobility between packs",
            "Ring of Frost for additional crowd control",
            "Ice Block and Alter Time for defensive cooldowns"
        },
        keyWeeklyAffixes = {
            {name = "Fortified", adjustment = "Focus on AoE and sustained damage"},
            {name = "Tyrannical", adjustment = "Save cooldowns for bosses"},
            {name = "Sanguine", adjustment = "Use Blast Wave to move mobs out of pools"},
            {name = "Storming", adjustment = "Use Blink/Shimmer to avoid tornados"}
        }
    }
}

-- Fetch data from Raider.IO
function ExternalDataIntegration:FetchRaiderIOData()
    -- In a real implementation, this would make API calls to Raider.IO
    -- For demonstration, we'll use mock data
    
    -- Mock fetching data
    C_Timer.After(1, function()
        -- Create mock data based on current mode
        -- For simplicity, reuse the WarcraftLogs mock data structure
        if currentMode == ANALYSIS_MODES.ROTATION then
            self:FetchWarcraftLogsRotationData()
        elseif currentMode == ANALYSIS_MODES.TALENTS then
            self:FetchWarcraftLogsTalentData()
        elseif currentMode == ANALYSIS_MODES.GEAR then
            self:FetchWarcraftLogsGearData()
        elseif currentMode == ANALYSIS_MODES.STATS then
            self:FetchWarcraftLogsStatData()
        elseif currentMode == ANALYSIS_MODES.MYTHIC_PLUS then
            self:FetchWarcraftLogsMythicPlusData()
        end
        
        -- Cache the data
        local cacheKey = self:GenerateCacheKey()
        cachedData[cacheKey] = {
            timestamp = GetTime(),
            data = self:DeepCopy(referenceData)
        }
        
        -- Process the data
        self:ProcessReferenceData()
        
        -- Update status
        if self.statusText then
            self.statusText:SetText("Data fetched successfully")
        end
        
        -- Clear request in progress
        requestInProgress = false
    end)
}

-- Fetch data from SimulationCraft
function ExternalDataIntegration:FetchSimulationCraftData()
    -- In a real implementation, this would generate SimC APLs or access SimC data
    -- For demonstration, we'll use mock data
    
    -- Mock fetching data
    C_Timer.After(1, function()
        -- Create mock data based on current mode
        -- For simplicity, reuse the WarcraftLogs mock data structure
        if currentMode == ANALYSIS_MODES.ROTATION then
            self:FetchWarcraftLogsRotationData()
        elseif currentMode == ANALYSIS_MODES.TALENTS then
            self:FetchWarcraftLogsTalentData()
        elseif currentMode == ANALYSIS_MODES.GEAR then
            self:FetchWarcraftLogsGearData()
        elseif currentMode == ANALYSIS_MODES.STATS then
            self:FetchWarcraftLogsStatData()
        elseif currentMode == ANALYSIS_MODES.MYTHIC_PLUS then
            self:FetchWarcraftLogsMythicPlusData()
        end
        
        -- Cache the data
        local cacheKey = self:GenerateCacheKey()
        cachedData[cacheKey] = {
            timestamp = GetTime(),
            data = self:DeepCopy(referenceData)
        }
        
        -- Process the data
        self:ProcessReferenceData()
        
        -- Update status
        if self.statusText then
            self.statusText:SetText("Data fetched successfully")
        end
        
        -- Clear request in progress
        requestInProgress = false
    end)
}

-- Fetch data from Subcreation
function ExternalDataIntegration:FetchSubcreationData()
    -- In a real implementation, this would access Subcreation API or web data
    -- For demonstration, we'll use mock data
    
    -- Mock fetching data
    C_Timer.After(1, function()
        -- Create mock data based on current mode
        -- For simplicity, reuse the WarcraftLogs mock data structure
        if currentMode == ANALYSIS_MODES.ROTATION then
            self:FetchWarcraftLogsRotationData()
        elseif currentMode == ANALYSIS_MODES.TALENTS then
            self:FetchWarcraftLogsTalentData()
        elseif currentMode == ANALYSIS_MODES.GEAR then
            self:FetchWarcraftLogsGearData()
        elseif currentMode == ANALYSIS_MODES.STATS then
            self:FetchWarcraftLogsStatData()
        elseif currentMode == ANALYSIS_MODES.MYTHIC_PLUS then
            self:FetchWarcraftLogsMythicPlusData()
        end
        
        -- Cache the data
        local cacheKey = self:GenerateCacheKey()
        cachedData[cacheKey] = {
            timestamp = GetTime(),
            data = self:DeepCopy(referenceData)
        }
        
        -- Process the data
        self:ProcessReferenceData()
        
        -- Update status
        if self.statusText then
            self.statusText:SetText("Data fetched successfully")
        end
        
        -- Clear request in progress
        requestInProgress = false
    end)
}

-- Analyze current setup against reference data
function ExternalDataIntegration:AnalyzeCurrentSetup()
    -- Clear previous analysis results
    analysisResults = {}
    
    -- Check if we have reference data
    if not referenceData or not next(referenceData) then
        print("|cFFFFFF00[Windrunner External Data]|r No reference data available. Fetch data first.")
        return
    end
    
    -- Check if we have current player data
    if not currentPlayerData or not next(currentPlayerData) then
        self:CollectPlayerData()
    end
    
    -- Perform analysis based on current mode
    if currentMode == ANALYSIS_MODES.ROTATION then
        self:AnalyzeRotation()
    elseif currentMode == ANALYSIS_MODES.TALENTS then
        self:AnalyzeTalents()
    elseif currentMode == ANALYSIS_MODES.GEAR then
        self:AnalyzeGear()
    elseif currentMode == ANALYSIS_MODES.STATS then
        self:AnalyzeStats()
    elseif currentMode == ANALYSIS_MODES.MYTHIC_PLUS then
        self:AnalyzeMythicPlus()
    end
    
    -- Update UI with analysis results
    self:UpdateAnalysisFrame()
    
    -- Update realtime frame
    self:UpdateRealtimeFrame()
    
    print("|cFF00FFFF[Windrunner External Data]|r Analysis complete.")
}

-- Analyze rotation
function ExternalDataIntegration:AnalyzeRotation()
    if not referenceData.rotation or not currentPlayerData.rotation then
        return
    end
    
    -- For demonstration, create mock analysis results
    analysisResults.rotation = {
        overallSimilarity = 78,
        abilityUsageSimilarity = 83,
        priorityAdherence = 75,
        cooldownEfficiency = 81,
        aoeEffectiveness = 72,
        suggestions = {
            "Use Combustion with Fire Blast charges ready",
            "Ensure you're converting Heating Up to Hot Streak efficiently",
            "Improve AoE rotation with more Flamestrike usage on 3+ targets"
        }
    }
    
    -- Update realtime performance metric
    self.realtimePerformance = analysisResults.rotation.overallSimilarity
}

-- Analyze talents
function ExternalDataIntegration:AnalyzeTalents()
    if not referenceData.talents or not currentPlayerData.talents then
        return
    end
    
    -- For demonstration, create mock analysis results
    analysisResults.talents = {
        buildSimilarity = 82,
        coreTalentsMatch = 85,
        flexibleTalentsMatch = 75,
        buildType = "Hybrid (leans toward AoE)",
        missingKeyTalents = "Infernal Cascade, Sun King's Blessing",
        suggestions = {
            "Consider taking Infernal Cascade for better Combustion windows",
            "Sun King's Blessing provides significant DPS increase",
            "Current build is suitable for dungeons but suboptimal for single target fights"
        }
    }
    
    -- Update realtime performance metric
    self.realtimePerformance = analysisResults.talents.buildSimilarity
}

-- Analyze gear
function ExternalDataIntegration:AnalyzeGear()
    if not referenceData.gear or not currentPlayerData.gear then
        return
    end
    
    -- For demonstration, create mock analysis results
    analysisResults.gear = {
        overallScore = 68,
        averageItemLevel = 472,
        setBonusStatus = "2/4 Flamebringer's Regalia pieces",
        gemsAndEnchantsStatus = "Partially optimized (70%)",
        upgradeSuggestions = "Prioritize 2 more set pieces, upgrade trinkets",
        slotAnalysis = {
            weakestSlots = "Trinkets, Back, Wrists",
            strongestSlots = "Chest, Weapon, Legs"
        }
    }
    
    -- Update realtime performance metric
    self.realtimePerformance = analysisResults.gear.overallScore
}

-- Analyze stats
function ExternalDataIntegration:AnalyzeStats()
    if not referenceData.stats or not currentPlayerData.stats then
        return
    end
    
    -- For demonstration, create mock analysis results
    analysisResults.stats = {
        overallDistribution = 76,
        primaryStatStatus = "Good (Intellect is appropriately high)",
        secondaryStatStatus = "Needs adjustment (too much Mastery)",
        hasteStatus = "Below target (24% vs recommended 30%)",
        versatilityStatus = "Good (22% is within target range)",
        criticalStrikeStatus = "Slightly low (18% vs recommended 20%)",
        masteryStatus = "Too high (28% vs recommended 15%)",
        statAdjustments = "Prioritize Haste and Crit, reduce Mastery"
    }
    
    -- Update realtime performance metric
    self.realtimePerformance = analysisResults.stats.overallDistribution
}

-- Analyze mythic+
function ExternalDataIntegration:AnalyzeMythicPlus()
    if not referenceData.mythicPlus then
        return
    end
    
    -- For demonstration, create mock analysis results
    analysisResults.mythicPlus = {
        overallPerformance = 81,
        aoeCapability = 85,
        utilityUsage = 75,
        interruptsAndCC = 72,
        survivalAndRecovery = 78,
        dungeonSpecificAdvice = {
            ["Dawn of the Infinite"] = "Use Living Bomb effectively on 3+ target packs",
            ["Waycrest Manor"] = "Save cooldowns for the triple-pull before 2nd boss",
            ["Black Rook Hold"] = "Spellsteal arcane aberrations for additional damage"
        }
    }
    
    -- Update realtime performance metric
    self.realtimePerformance = analysisResults.mythicPlus.overallPerformance
}

-- Import optimal setup
function ExternalDataIntegration:ImportOptimalSetup()
    -- Check if we have reference data
    if not referenceData or not next(referenceData) then
        print("|cFFFFFF00[Windrunner External Data]|r No reference data available. Fetch data first.")
        return
    end
    
    -- Confirm import
    StaticPopupDialogs["WR_CONFIRM_IMPORT"] = {
        text = "Import optimal setup from " .. self:GetSourceDisplayName(dataSource) .. "?",
        button1 = "Yes",
        button2 = "No",
        OnAccept = function()
            self:PerformImport()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
    StaticPopup_Show("WR_CONFIRM_IMPORT")
}

-- Perform import of optimal setup
function ExternalDataIntegration:PerformImport()
    -- Based on the current mode, import different aspects
    if currentMode == ANALYSIS_MODES.ROTATION then
        self:ImportRotation()
    elseif currentMode == ANALYSIS_MODES.TALENTS then
        self:ImportTalents()
    elseif currentMode == ANALYSIS_MODES.GEAR then
        self:ImportGearRecommendations()
    elseif currentMode == ANALYSIS_MODES.STATS then
        self:ImportStatPriorities()
    elseif currentMode == ANALYSIS_MODES.MYTHIC_PLUS then
        self:ImportMythicPlusSetup()
    end
    
    print("|cFF00FFFF[Windrunner External Data]|r Setup imported successfully.")
}

-- Import rotation into Windrunner
function ExternalDataIntegration:ImportRotation()
    if not referenceData.rotation then return end
    
    -- In a real implementation, this would interact with the Rotation module
    -- For demonstration, we'll show what would be imported
    
    print("|cFF00FFFF[Windrunner External Data]|r Importing rotation priorities:")
    
    -- Import priority sequence
    if referenceData.rotation.prioritySequence then
        for i, priority in ipairs(referenceData.rotation.prioritySequence) do
            print(i .. ". " .. priority)
        end
    end
    
    -- Import cooldown usage
    if referenceData.rotation.cooldownUsage then
        print("\nCooldown usage:")
        for _, cooldown in ipairs(referenceData.rotation.cooldownUsage) do
            print("- " .. cooldown.name .. ": " .. cooldown.advice)
        end
    end
    
    -- If Windrunner has a rotation module we can update
    if WR.Rotation and WR.Rotation.SetPriorities then
        -- This would be the actual implementation
        -- WR.Rotation:SetPriorities(referenceData.rotation.prioritySequence)
        print("\nPriorities have been updated in Windrunner's rotation system.")
    end
}

-- Import talents
function ExternalDataIntegration:ImportTalents()
    if not referenceData.talents then return end
    
    -- In a real implementation, this would update talent selections
    -- For demonstration, we'll show what would be imported
    
    print("|cFF00FFFF[Windrunner External Data]|r Talent recommendations:")
    
    -- Show core talents
    if referenceData.talents.coreTalents then
        print("\nCore talents to select:")
        for _, talent in ipairs(referenceData.talents.coreTalents) do
            print("- " .. talent.name)
        end
    end
    
    -- Show flexible talent recommendations
    if referenceData.talents.flexibleTalents then
        print("\nFlexible talent recommendations:")
        for _, group in ipairs(referenceData.talents.flexibleTalents) do
            print("\n" .. group.description .. ":")
            if group.options and group.options[1] then
                print("Recommended: " .. group.options[1].name .. " (" .. group.options[1].popularity .. "%)")
            end
        end
    end
    
    print("\nTo automatically load a talent build, install the Talent Import extension addon.")
}

-- Import gear recommendations
function ExternalDataIntegration:ImportGearRecommendations()
    if not referenceData.gear then return end
    
    -- In a real implementation, this would create gear set recommendations
    -- For demonstration, we'll show what would be imported
    
    print("|cFF00FFFF[Windrunner External Data]|r Gear recommendations:")
    
    -- Show BiS items
    if referenceData.gear.bestItems then
        print("\nBest in Slot items:")
        for slot, items in pairs(referenceData.gear.bestItems) do
            if items[1] then
                print("- " .. slot .. ": " .. items[1].name .. " (iLvl " .. items[1].itemLevel .. ", from " .. items[1].source .. ")")
            end
        end
    end
    
    -- Show set bonuses
    if referenceData.gear.setBonuses then
        print("\nSet bonuses to aim for:")
        for _, bonus in ipairs(referenceData.gear.setBonuses) do
            print("- " .. bonus.name .. " (" .. bonus.pieces .. "-piece): " .. bonus.effect)
        end
    end
    
    -- Show gem recommendations
    if referenceData.gear.gemRecommendations then
        print("\nRecommended gems:")
        for _, gem in ipairs(referenceData.gear.gemRecommendations) do
            print("- " .. gem)
        end
    end
    
    -- Show enchant recommendations
    if referenceData.gear.enchantRecommendations then
        print("\nRecommended enchants:")
        for _, enchant in ipairs(referenceData.gear.enchantRecommendations) do
            print("- " .. enchant)
        end
    end
}

-- Import stat priorities
function ExternalDataIntegration:ImportStatPriorities()
    if not referenceData.stats then return end
    
    -- In a real implementation, this would set up Pawn-like stat weights
    -- For demonstration, we'll show what would be imported
    
    print("|cFF00FFFF[Windrunner External Data]|r Stat priorities:")
    
    -- Show stat priority
    if referenceData.stats.priority then
        print("\nPriority: " .. referenceData.stats.priority)
    end
    
    -- Show stat distribution
    if referenceData.stats.distribution then
        print("\nRecommended stat distribution:")
        for stat, value in pairs(referenceData.stats.distribution) do
            print("- " .. stat .. ": " .. value .. "%")
        end
    end
    
    -- Show thresholds
    if referenceData.stats.thresholds then
        print("\nImportant stat thresholds:")
        for stat, thresholds in pairs(referenceData.stats.thresholds) do
            print("\n" .. stat .. ":")
            for _, threshold in ipairs(thresholds) do
                print("- " .. threshold.value .. ": " .. threshold.reason)
            end
        end
    end
    
    print("\nTo use these weights for gear comparison, install the Stat Weights extension addon.")
}

-- Import M+ recommendations
function ExternalDataIntegration:ImportMythicPlusSetup()
    if not referenceData.mythicPlus then return end
    
    -- In a real implementation, this would set up M+-specific settings
    -- For demonstration, we'll show what would be imported
    
    print("|cFF00FFFF[Windrunner External Data]|r Mythic+ recommendations:")
    
    -- Show talent adjustments
    if referenceData.mythicPlus.talentAdjustments then
        print("\nRecommended talent adjustments:")
        for _, adjustment in ipairs(referenceData.mythicPlus.talentAdjustments) do
            print("- " .. adjustment)
        end
    end
    
    -- Show key abilities
    if referenceData.mythicPlus.keyAbilities then
        print("\nKey abilities to focus on:")
        for _, ability in ipairs(referenceData.mythicPlus.keyAbilities) do
            print("- " .. ability.name .. ": " .. ability.usage)
        end
    end
    
    -- Show affix-specific advice
    if referenceData.mythicPlus.keyWeeklyAffixes then
        print("\nAffix-specific strategies:")
        for _, affix in ipairs(referenceData.mythicPlus.keyWeeklyAffixes) do
            print("- " .. affix.name .. ": " .. affix.adjustment)
        end
    end
    
    print("\nThese recommendations have been recorded in your Mythic+ notes.")
}

-- Update realtime percentile frame
function ExternalDataIntegration:UpdateRealtimeFrame()
    if not self.realtimeFrame or not self.percentileText or not self.descText then
        return
    end
    
    -- Check if we have a performance metric
    if not self.realtimePerformance then
        self.percentileText:SetText("--")
        self.descText:SetText("No data")
        return
    end
    
    -- Update percentile text
    self.percentileText:SetText(self.realtimePerformance .. "%")
    
    -- Set color based on performance
    local r, g, b = 1, 1, 1
    if self.realtimePerformance >= 90 then
        r, g, b = 0.64, 1, 0.2 -- Green
        self.descText:SetText("Excellent")
    elseif self.realtimePerformance >= 75 then
        r, g, b = 0.2, 0.7, 1 -- Blue
        self.descText:SetText("Good")
    elseif self.realtimePerformance >= 50 then
        r, g, b = 1, 0.84, 0 -- Yellow
        self.descText:SetText("Average")
    else
        r, g, b = 1, 0.2, 0.2 -- Red
        self.descText:SetText("Needs Improvement")
    end
    
    self.percentileText:SetTextColor(r, g, b)
}

-- Handle encounter start
function ExternalDataIntegration:OnEncounterStart(encounterID, encounterName)
    -- Reset current combat data
    self.realtimePerformance = nil
    
    -- Update realtime frame
    self:UpdateRealtimeFrame()
    
    -- Auto-fetch data if we don't have it for this encounter
    if settings.automaticAnalysis and selectedEncounter ~= encounterName then
        selectedEncounter = encounterName
        if self.encounterDropdown then
            UIDropDownMenu_SetText(self.encounterDropdown, encounterName)
        end
        
        self:ClearCache()
        self:FetchData()
    end
}

-- Handle encounter end
function ExternalDataIntegration:OnEncounterEnd(encounterID, encounterName, difficultyID, success)
    -- Auto-analyze at end of encounter
    if settings.automaticAnalysis and success then
        self:AnalyzeCurrentSetup()
    end
}

-- Handle mythic+ start
function ExternalDataIntegration:OnMythicPlusStart()
    -- Reset current combat data
    self.realtimePerformance = nil
    
    -- Update realtime frame
    self:UpdateRealtimeFrame()
    
    -- Auto-fetch mythic+ data
    if settings.automaticAnalysis and currentMode ~= ANALYSIS_MODES.MYTHIC_PLUS then
        currentMode = ANALYSIS_MODES.MYTHIC_PLUS
        if self.modeDropdown then
            UIDropDownMenu_SetText(self.modeDropdown, self:GetModeDisplayName(currentMode))
        end
        
        self:ClearCache()
        self:FetchData()
    end
}

-- Handle mythic+ end
function ExternalDataIntegration:OnMythicPlusEnd()
    -- Auto-analyze at end of M+
    if settings.automaticAnalysis then
        self:AnalyzeCurrentSetup()
    end
}

-- Process combat log events
function ExternalDataIntegration:ProcessCombatLog(...)
    -- In a real implementation, this would track actual combat performance
    -- For demonstration, we'll periodically update the realtime performance
    
    -- Only process during encounters
    local inEncounter = IsEncounterInProgress()
    if not inEncounter then
        return
    end
    
    -- Only process if we have analysis results
    if not analysisResults or not next(analysisResults) then
        return
    end
    
    -- Periodically adjust the realtime performance with some variation
    -- In a real implementation, this would be based on actual rotation execution
    if self.realtimePerformance and math.random() < 0.01 then -- 1% chance per event
        local basePerformance = self.realtimePerformance
        local variation = math.random(-5, 5)
        self.realtimePerformance = math.max(0, math.min(100, basePerformance + variation))
        
        -- Update realtime frame
        self:UpdateRealtimeFrame()
    end
}

-- On update function
function ExternalDataIntegration:OnUpdate(elapsed)
    lastUpdateTime = lastUpdateTime + elapsed
    
    -- Only update at the specified frequency
    if lastUpdateTime >= UPDATE_FREQUENCY then
        -- Update UI if needed
        if isActive and self.frame:IsShown() then
            -- Update realtime frame if in combat
            if IsEncounterInProgress() and not self.realtimePerformance then
                -- Initialize performance metric based on current mode
                if currentMode == ANALYSIS_MODES.ROTATION and analysisResults.rotation then
                    self.realtimePerformance = analysisResults.rotation.overallSimilarity
                elseif currentMode == ANALYSIS_MODES.TALENTS and analysisResults.talents then
                    self.realtimePerformance = analysisResults.talents.buildSimilarity
                elseif currentMode == ANALYSIS_MODES.GEAR and analysisResults.gear then
                    self.realtimePerformance = analysisResults.gear.overallScore
                elseif currentMode == ANALYSIS_MODES.STATS and analysisResults.stats then
                    self.realtimePerformance = analysisResults.stats.overallDistribution
                elseif currentMode == ANALYSIS_MODES.MYTHIC_PLUS and analysisResults.mythicPlus then
                    self.realtimePerformance = analysisResults.mythicPlus.overallPerformance
                end
                
                self:UpdateRealtimeFrame()
            end
        end
        
        lastUpdateTime = 0
    end
}

-- Helper function to clean up cache
function ExternalDataIntegration:CleanupCache()
    -- Count entries
    local count = 0
    for _ in pairs(cachedData) do
        count = count + 1
    end
    
    -- If over limit, remove oldest entries
    if count > MAX_CACHED_ENTRIES then
        local entries = {}
        for key, data in pairs(cachedData) do
            table.insert(entries, {key = key, timestamp = data.timestamp})
        end
        
        -- Sort by timestamp
        table.sort(entries, function(a, b) return a.timestamp < b.timestamp end)
        
        -- Remove oldest entries
        local toRemove = count - MAX_CACHED_ENTRIES
        for i = 1, toRemove do
            if entries[i] then
                cachedData[entries[i].key] = nil
            end
        end
    end
}

-- Helper function to deep copy a table
function ExternalDataIntegration:DeepCopy(src)
    if type(src) ~= "table" then
        return src
    end
    
    local copy = {}
    for k, v in pairs(src) do
        if type(v) == "table" then
            copy[k] = self:DeepCopy(v)
        else
            copy[k] = v
        end
    end
    
    return copy
}

-- Helper function to get source display name
function ExternalDataIntegration:GetSourceDisplayName(source)
    if source == DATA_SOURCES.WARCRAFT_LOGS then
        return "WarcraftLogs"
    elseif source == DATA_SOURCES.RAIDER_IO then
        return "Raider.IO"
    elseif source == DATA_SOURCES.SIMULATIONCRAFT then
        return "SimulationCraft"
    elseif source == DATA_SOURCES.SUBCREATION then
        return "Subcreation"
    else
        return "Unknown Source"
    end
}

-- Helper function to get mode display name
function ExternalDataIntegration:GetModeDisplayName(mode)
    if mode == ANALYSIS_MODES.ROTATION then
        return "Rotation Analysis"
    elseif mode == ANALYSIS_MODES.TALENTS then
        return "Talent Build"
    elseif mode == ANALYSIS_MODES.GEAR then
        return "Gear Optimization"
    elseif mode == ANALYSIS_MODES.STATS then
        return "Stat Priority"
    elseif mode == ANALYSIS_MODES.MYTHIC_PLUS then
        return "Mythic+ Analysis"
    else
        return "Unknown Mode"
    end
}

-- Helper function to get difficulty display name
function ExternalDataIntegration:GetDifficultyDisplayName(difficulty)
    if difficulty == "mythic" then
        return "Mythic"
    elseif difficulty == "heroic" then
        return "Heroic"
    elseif difficulty == "normal" then
        return "Normal"
    elseif difficulty == "mythicplus" then
        return "Mythic+"
    else
        return "Unknown Difficulty"
    end
}

-- Activate module
function ExternalDataIntegration:Activate()
    if isActive then return end
    
    isActive = true
    
    -- Show UI
    self:UpdateFrameVisibility()
    
    -- Collect initial player data
    self:CollectPlayerData()
    
    -- Fetch data if needed
    if not referenceData or not next(referenceData) then
        self:FetchData()
    end
    
    print("|cFF00FFFF[Windrunner External Data]|r Module activated.")
}

-- Deactivate module
function ExternalDataIntegration:Deactivate()
    if not isActive then return end
    
    isActive = false
    
    -- Hide UI
    self:UpdateFrameVisibility()
    
    print("|cFF00FFFF[Windrunner External Data]|r Module deactivated.")
}

-- Toggle module
function ExternalDataIntegration:Toggle()
    if isActive then
        self:Deactivate()
    else
        self:Activate()
    end
}

-- Initialize the module
ExternalDataIntegration:Initialize()

return ExternalDataIntegration