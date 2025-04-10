local addonName, WR = ...

-- AdvancedSettingsUI module for comprehensive customization options
local AdvancedSettingsUI = {}
WR.UI.AdvancedSettingsUI = AdvancedSettingsUI

-- Local references for performance
local CreateFrame = CreateFrame
local GetTime = GetTime
local UnitClass = UnitClass
local tinsert = table.insert
local tremove = table.remove
local pairs = pairs
local ipairs = ipairs
local math_floor = math.floor
local math_min = math.min
local math_max = math.max
local string_format = string.format
local LibDeflate = nil  -- Will be loaded if available for settings compression

-- Module state variables
local frame
local tabButtons = {}
local tabFrames = {}
local currentTab = nil
local playerClass, playerSpec
local editModeActive = false
local dragElement = nil
local previewActive = false
local previewOriginalSettings = {}
local defaultColors = {
    text = {r = 1, g = 1, b = 1, a = 1},
    background = {r = 0.1, g = 0.1, b = 0.1, a = 0.8},
    border = {r = 0.4, g = 0.4, b = 0.4, a = 0.8},
    highlight = {r = 0.7, g = 0.7, b = 0.1, a = 0.9},
    header = {r = 0.9, g = 0.8, b = 0, a = 1},
    button = {r = 0.4, g = 0.4, b = 0.4, a = 1},
    buttonHighlight = {r = 0.6, g = 0.6, b = 0.6, a = 1},
    slider = {r = 0.7, g = 0.7, b = 0.7, a = 0.8},
    checkbox = {r = 0.8, g = 0.8, b = 0.8, a = 0.8},
    dropdown = {r = 0.3, g = 0.3, b = 0.3, a = 1},
    disabled = {r = 0.3, g = 0.3, b = 0.3, a = 0.5}
}
local classColors = {
    WARRIOR     = {r = 0.78, g = 0.61, b = 0.43},
    PALADIN     = {r = 0.96, g = 0.55, b = 0.73},
    HUNTER      = {r = 0.67, g = 0.83, b = 0.45},
    ROGUE       = {r = 1.00, g = 0.96, b = 0.41},
    PRIEST      = {r = 1.00, g = 1.00, b = 1.00},
    DEATHKNIGHT = {r = 0.77, g = 0.12, b = 0.23},
    SHAMAN      = {r = 0.00, g = 0.44, b = 0.87},
    MAGE        = {r = 0.25, g = 0.78, b = 0.92},
    WARLOCK     = {r = 0.53, g = 0.53, b = 0.93},
    MONK        = {r = 0.00, g = 1.00, b = 0.59},
    DRUID       = {r = 1.00, g = 0.49, b = 0.04},
    DEMONHUNTER = {r = 0.64, g = 0.19, b = 0.79},
    EVOKER      = {r = 0.20, g = 0.58, b = 0.50}
}

-- Default configuration settings
local defaultConfiguration = {
    general = {
        enabled = true,
        showMinimapIcon = true,
        lockMainUI = false,
        showTooltips = true,
        fontSize = 12,
        scale = 1.0,
        transparency = 0.9,
        useClassColors = true,
        theme = "Default", -- Default, Dark, Light, Minimalist, Class
        soundEffects = true,
        soundChannel = "SFX", -- Master, SFX, Music, Ambience
        audioFeedback = true,
        debugMode = false
    },
    
    rotationSettings = {
        enableInterrupts = true,
        enableDefensives = true,
        enableCooldowns = true,
        enableMovementAbilities = true,
        enablePotions = false,
        enableTrinkets = true,
        enableRacials = true,
        targetSwitchingEnabled = true,
        focusTargetEnabled = true,
        aoeThreshold = 3, -- Number of targets to switch to AOE rotation
        applyDotAtHealth = 30, -- Percentage of health to apply DOTs
        targetMaxDistance = 30, -- Max distance for targeting
        outOfCombatHealing = true,
        tankProtection = true,
    },
    
    classUI = {
        enabled = true,
        resourceDisplayStyle = "Default", -- Default, Compact, Detailed, Minimalist
        showDotTracker = true,
        showProcDisplay = true,
        showAPMMeter = true,
        showSpellQueue = true,
        glowEffects = true,
        animations = true,
        animationSpeed = 1.0,
        scale = 1.0,
        position = {x = 0, y = -200},
        transparency = 0.9,
        showAdvancedInfo = false,
        lockPosition = false,
    },
    
    resourceForecast = {
        enabled = true,
        forecastWindow = 10, -- seconds
        showHistory = true,
        graphHeight = 100,
        graphWidth = 300,
        position = {x = 400, y = 0},
        scale = 1.0,
        transparency = 0.9,
        showAbilityIcons = true,
        showLegend = true,
        advancedPrediction = true,
        displayMode = "overlay", -- overlay, window
        graphStyle = "line", -- line, bar, text
        updateFrequency = 0.25,
        lockPosition = false,
    },
    
    machineLearning = {
        enabled = true,
        dataCollection = true,
        shareAnonymousData = false,
        learningRate = 0.1, -- How quickly to adapt (0.01 - 0.5)
        modelPriority = 0.5, -- Balance between global and personal (0-1)
        minimumSampleSize = 10,
        adaptationSpeed = 3, -- 1-5 scale (slow to fast)
        includeMetrics = {
            dps = true,
            survivalTime = true,
            resourceEfficiency = true,
            mechanicHandling = true,
            apm = true,
        },
        storageLimit = 100, -- Maximum combat sessions to store
    },
    
    pvp = {
        enabled = true,
        prioritizeHealers = true,
        autoDefensiveUsage = true,
        showEnemyCooldowns = true,
        showDiminishingReturns = true,
        autoInterrupt = true,
        enableBurstDetection = true,
        targetSwitchSuggestions = true,
        focusTargetTracking = true,
        showPvPTeamDisplay = true,
        defensiveThreshold = 2, -- 1-3 scale of when to suggest defensives
        enemyFrameScale = 1.0,
        enemyFramePosition = {x = -400, y = 0},
        alwaysShowCCTimer = true,
    },
    
    advanced = {
        enableLuaSnippets = false,
        customConditions = {},
        enableWeakAurasIntegration = false,
        enableExternalAPIs = false,
        performanceTuning = 2, -- 1-5 scale (performance to accuracy)
        asyncProcessing = true,
        eventFiltering = true,
        customHotkeys = {},
        globalCooldownAdjustment = 0, -- ms adjustment to GCD detection
        showDebugConsole = false,
        logLevel = 1, -- 1-3 error/warning/info
    },
    
    profiles = {
        active = "Default",
        list = {
            ["Default"] = {}
        },
        contexts = { -- Context-specific profile overrides
            ["raid"] = "",
            ["dungeon"] = "",
            ["pvp"] = "",
            ["world"] = ""
        }
    }
}

-- Saved configuration (initialized from default)
local configuration = {}

-- Initialize the module
function AdvancedSettingsUI:Initialize()
    -- Get player class and spec
    playerClass = select(2, UnitClass("player"))
    playerSpec = GetSpecialization()
    
    -- Load saved configuration
    self:LoadConfiguration()
    
    -- Check for LibDeflate for settings compression
    if LibStub then
        pcall(function() LibDeflate = LibStub:GetLibrary("LibDeflate") end)
    end
    
    -- Create UI elements
    self:CreateMainFrame()
    
    -- Create tabs
    self:CreateTabs()
    
    -- Register with the main addon
    self:RegisterWithAddon()
    
    WR:Debug("AdvancedSettingsUI module initialized")
end

-- Load saved configuration
function AdvancedSettingsUI:LoadConfiguration()
    if not WindrunnerRotationsDB or not WindrunnerRotationsDB.AdvancedSettings then
        -- Initialize with defaults
        configuration = self:DeepCopy(defaultConfiguration)
        return
    end
    
    -- Load saved settings
    configuration = self:DeepCopy(WindrunnerRotationsDB.AdvancedSettings)
    
    -- Fill in any missing values with defaults
    self:MergeDefaults(configuration, defaultConfiguration)
end

-- Recursive function to merge default values for missing settings
function AdvancedSettingsUI:MergeDefaults(target, source)
    for k, v in pairs(source) do
        if type(v) == "table" then
            if type(target[k]) ~= "table" then
                target[k] = {}
            end
            self:MergeDefaults(target[k], v)
        else
            if target[k] == nil then
                target[k] = v
            end
        end
    end
end

-- Save configuration
function AdvancedSettingsUI:SaveConfiguration()
    -- Initialize DB if needed
    if not WindrunnerRotationsDB then
        WindrunnerRotationsDB = {}
    end
    
    -- Save settings
    WindrunnerRotationsDB.AdvancedSettings = self:DeepCopy(configuration)
    
    -- Apply settings to other modules
    self:ApplySettingsToModules()
    
    WR:Debug("AdvancedSettingsUI configuration saved")
end

-- Apply settings to all relevant modules
function AdvancedSettingsUI:ApplySettingsToModules()
    -- Apply Class UI settings
    if WR.UI.ClassSpecificUI then
        WR.UI.ClassSpecificUI:ApplySettings(configuration.classUI)
    end
    
    -- Apply Resource Forecast settings
    if WR.UI.ResourceForecast then
        WR.UI.ResourceForecast:ApplySettings(configuration.resourceForecast)
    end
    
    -- Apply Machine Learning settings
    if WR.MachineLearning then
        WR.MachineLearning:ApplySettings(configuration.machineLearning)
    end
    
    -- Apply PvP System settings
    if WR.PvPSystem then
        WR.PvPSystem:ApplySettings(configuration.pvp)
    end
    
    -- Apply general rotation settings
    if WR.Rotation then
        WR.Rotation:ApplySettings(configuration.rotationSettings)
    end
    
    -- Apply general UI settings
    if WR.UI then
        local generalUI = {
            scale = configuration.general.scale,
            transparency = configuration.general.transparency,
            theme = configuration.general.theme,
            useClassColors = configuration.general.useClassColors,
            fontSize = configuration.general.fontSize,
            soundEffects = configuration.general.soundEffects,
            soundChannel = configuration.general.soundChannel,
            lockMainUI = configuration.general.lockMainUI
        }
        
        WR.UI:ApplySettings(generalUI)
    end
}

-- Create main settings frame
function AdvancedSettingsUI:CreateMainFrame()
    -- Main frame
    frame = CreateFrame("Frame", "WRAdvancedSettingsFrame", UIParent, "BackdropTemplate")
    frame:SetSize(800, 600)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("HIGH")
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    frame:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    frame:SetClampedToScreen(true)
    frame:Hide()
    
    -- Header
    local header = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    header:SetPoint("TOP", frame, "TOP", 0, -20)
    header:SetText("Windrunner Rotations - Advanced Settings")
    
    -- Apply class color to header if enabled
    if configuration.general.useClassColors and classColors[playerClass] then
        local color = classColors[playerClass]
        header:SetTextColor(color.r, color.g, color.b, 1)
    end
    
    -- Close button
    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    
    -- Save button
    local saveButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    saveButton:SetSize(100, 25)
    saveButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -20, 20)
    saveButton:SetText("Save & Close")
    saveButton:SetScript("OnClick", function()
        self:SaveConfiguration()
        frame:Hide()
        if previewActive then
            self:EndPreview(true) -- Apply changes
        end
    end)
    
    -- Cancel button
    local cancelButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    cancelButton:SetSize(100, 25)
    cancelButton:SetPoint("RIGHT", saveButton, "LEFT", -10, 0)
    cancelButton:SetText("Cancel")
    cancelButton:SetScript("OnClick", function()
        frame:Hide()
        if previewActive then
            self:EndPreview(false) -- Discard changes
        end
    end)
    
    -- Reset tab button
    local resetTabButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    resetTabButton:SetSize(100, 25)
    resetTabButton:SetPoint("RIGHT", cancelButton, "LEFT", -10, 0)
    resetTabButton:SetText("Reset Tab")
    resetTabButton:SetScript("OnClick", function()
        if currentTab then
            StaticPopupDialogs["WR_RESET_TAB_CONFIRM"] = {
                text = "Are you sure you want to reset all settings in the " .. currentTab .. " tab to defaults?",
                button1 = "Yes",
                button2 = "No",
                OnAccept = function()
                    self:ResetTabSettings(currentTab)
                end,
                timeout = 0,
                whileDead = true,
                hideOnEscape = true,
                preferredIndex = 3,
            }
            StaticPopup_Show("WR_RESET_TAB_CONFIRM")
        end
    end)
    
    -- Preview button
    local previewButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    previewButton:SetSize(100, 25)
    previewButton:SetPoint("RIGHT", resetTabButton, "LEFT", -10, 0)
    previewButton:SetText(previewActive and "End Preview" or "Preview")
    previewButton:SetScript("OnClick", function()
        if previewActive then
            self:EndPreview(false) -- Discard changes
            previewButton:SetText("Preview")
        else
            self:StartPreview()
            previewButton:SetText("End Preview")
        end
    end)
    
    -- Import/Export button
    local importExportButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    importExportButton:SetSize(120, 25)
    importExportButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 20, 20)
    importExportButton:SetText("Import/Export")
    importExportButton:SetScript("OnClick", function()
        self:ShowImportExportDialog()
    end)
    
    -- Edit Mode button
    local editModeButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    editModeButton:SetSize(100, 25)
    editModeButton:SetPoint("LEFT", importExportButton, "RIGHT", 10, 0)
    editModeButton:SetText(editModeActive and "Exit Edit Mode" or "Edit Mode")
    editModeButton:SetScript("OnClick", function()
        editModeActive = not editModeActive
        editModeButton:SetText(editModeActive and "Exit Edit Mode" or "Edit Mode")
        self:ToggleEditMode(editModeActive)
    end)
    
    -- Store references
    self.frame = frame
    self.header = header
    self.closeButton = closeButton
    self.saveButton = saveButton
    self.cancelButton = cancelButton
    self.resetTabButton = resetTabButton
    self.previewButton = previewButton
    self.importExportButton = importExportButton
    self.editModeButton = editModeButton
end

-- Create tabs
function AdvancedSettingsUI:CreateTabs()
    -- Tab list
    local tabs = {
        "General",
        "Rotation",
        "Class UI",
        "Forecasting",
        "Machine Learning",
        "PvP",
        "Advanced",
        "Profiles"
    }
    
    -- Create tab container
    local tabContainer = CreateFrame("Frame", nil, self.frame)
    tabContainer:SetSize(self.frame:GetWidth() - 40, 30)
    tabContainer:SetPoint("TOP", self.header, "BOTTOM", 0, -10)
    
    -- Create tab buttons
    for i, tabName in ipairs(tabs) do
        local button = CreateFrame("Button", nil, tabContainer, "PanelTabButtonTemplate")
        button:SetSize(100, 30)
        button:SetPoint("TOPLEFT", tabContainer, "TOPLEFT", (i-1) * 100, 0)
        button:SetText(tabName)
        button.tabName = tabName:gsub(" ", ""):lower() -- Convert to internal name format
        
        button:SetScript("OnClick", function(self)
            AdvancedSettingsUI:SelectTab(self.tabName)
        end)
        
        tabButtons[button.tabName] = button
    end
    
    -- Create tab content frames
    local contentFrame = CreateFrame("Frame", nil, self.frame)
    contentFrame:SetSize(self.frame:GetWidth() - 40, self.frame:GetHeight() - 140)
    contentFrame:SetPoint("TOP", tabContainer, "BOTTOM", 0, -10)
    
    -- Create each tab's content
    self:CreateGeneralTab(contentFrame)
    self:CreateRotationTab(contentFrame)
    self:CreateClassUITab(contentFrame)
    self:CreateForecastingTab(contentFrame)
    self:CreateMachineLearningTab(contentFrame)
    self:CreatePvPTab(contentFrame)
    self:CreateAdvancedTab(contentFrame)
    self:CreateProfilesTab(contentFrame)
    
    -- Select first tab by default
    self:SelectTab("general")
    
    -- Store container reference
    self.tabContainer = tabContainer
    self.contentFrame = contentFrame
}

-- Select a tab
function AdvancedSettingsUI:SelectTab(tabName)
    -- Hide all tab frames
    for name, frame in pairs(tabFrames) do
        frame:Hide()
    end
    
    -- Unhighlight all tab buttons
    for name, button in pairs(tabButtons) do
        button:SetButtonState("NORMAL")
    end
    
    -- Show selected tab and highlight its button
    if tabFrames[tabName] then
        tabFrames[tabName]:Show()
        currentTab = tabName
        
        if tabButtons[tabName] then
            tabButtons[tabName]:SetButtonState("PUSHED", 1)
            tabButtons[tabName]:Disable()
            
            -- Re-enable other tabs
            for name, button in pairs(tabButtons) do
                if name ~= tabName then
                    button:Enable()
                end
            end
        end
    end
end

-- Create General tab
function AdvancedSettingsUI:CreateGeneralTab(parent)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(parent:GetWidth(), parent:GetHeight())
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT")
    frame:Hide()
    
    -- Create scrollframe for content
    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetSize(frame:GetWidth() - 30, frame:GetHeight())
    scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    
    local scrollChild = CreateFrame("Frame")
    scrollFrame:SetScrollChild(scrollChild)
    scrollChild:SetSize(scrollFrame:GetWidth() - 20, scrollFrame:GetHeight() * 2) -- Extra height for content
    
    -- Appearance header
    local appearanceHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    appearanceHeader:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, -10)
    appearanceHeader:SetText("Appearance")
    
    -- Enable addon
    local enableCheckbox = self:CreateCheckbox(scrollChild, "Enable Windrunner Rotations", configuration.general.enabled)
    enableCheckbox:SetPoint("TOPLEFT", appearanceHeader, "BOTTOMLEFT", 0, -20)
    enableCheckbox.callback = function(checked)
        configuration.general.enabled = checked
    end
    
    -- Show minimap icon
    local minimapCheckbox = self:CreateCheckbox(scrollChild, "Show Minimap Icon", configuration.general.showMinimapIcon)
    minimapCheckbox:SetPoint("TOPLEFT", enableCheckbox, "BOTTOMLEFT", 0, -10)
    minimapCheckbox.callback = function(checked)
        configuration.general.showMinimapIcon = checked
    end
    
    -- Lock main UI
    local lockUICheckbox = self:CreateCheckbox(scrollChild, "Lock Main UI Position", configuration.general.lockMainUI)
    lockUICheckbox:SetPoint("TOPLEFT", minimapCheckbox, "BOTTOMLEFT", 0, -10)
    lockUICheckbox.callback = function(checked)
        configuration.general.lockMainUI = checked
    end
    
    -- Show tooltips
    local tooltipCheckbox = self:CreateCheckbox(scrollChild, "Show Tooltips", configuration.general.showTooltips)
    tooltipCheckbox:SetPoint("TOPLEFT", lockUICheckbox, "BOTTOMLEFT", 0, -10)
    tooltipCheckbox.callback = function(checked)
        configuration.general.showTooltips = checked
    end
    
    -- Scale slider
    local scaleSlider = self:CreateSlider(scrollChild, "UI Scale", 0.5, 2.0, 0.05, configuration.general.scale)
    scaleSlider:SetPoint("TOPLEFT", tooltipCheckbox, "BOTTOMLEFT", 0, -30)
    scaleSlider:SetWidth(280)
    scaleSlider.callback = function(value)
        configuration.general.scale = value
    end
    
    -- Transparency slider
    local transparencySlider = self:CreateSlider(scrollChild, "UI Transparency", 0.1, 1.0, 0.05, configuration.general.transparency)
    transparencySlider:SetPoint("TOPLEFT", scaleSlider, "BOTTOMLEFT", 0, -30)
    transparencySlider:SetWidth(280)
    transparencySlider.callback = function(value)
        configuration.general.transparency = value
    end
    
    -- Font size slider
    local fontSizeSlider = self:CreateSlider(scrollChild, "Font Size", 8, 18, 1, configuration.general.fontSize)
    fontSizeSlider:SetPoint("TOPLEFT", transparencySlider, "BOTTOMLEFT", 0, -30)
    fontSizeSlider:SetWidth(280)
    fontSizeSlider.callback = function(value)
        configuration.general.fontSize = value
    end
    
    -- Theme dropdown
    local themeOptions = {
        {text = "Default", value = "Default"},
        {text = "Dark", value = "Dark"},
        {text = "Light", value = "Light"},
        {text = "Minimalist", value = "Minimalist"},
        {text = "Class Theme", value = "Class"}
    }
    local themeDropdown = self:CreateDropdown(scrollChild, "Theme", themeOptions, configuration.general.theme)
    themeDropdown:SetPoint("TOPLEFT", fontSizeSlider, "BOTTOMLEFT", 0, -30)
    themeDropdown:SetWidth(280)
    themeDropdown.callback = function(value)
        configuration.general.theme = value
    end
    
    -- Use class colors
    local classColorsCheckbox = self:CreateCheckbox(scrollChild, "Use Class Colors", configuration.general.useClassColors)
    classColorsCheckbox:SetPoint("TOPLEFT", themeDropdown, "BOTTOMLEFT", 0, -20)
    classColorsCheckbox.callback = function(checked)
        configuration.general.useClassColors = checked
    end
    
    -- Sound effects header
    local soundHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    soundHeader:SetPoint("TOPLEFT", classColorsCheckbox, "BOTTOMLEFT", 0, -30)
    soundHeader:SetText("Sound")
    
    -- Enable sound effects
    local soundCheckbox = self:CreateCheckbox(scrollChild, "Enable Sound Effects", configuration.general.soundEffects)
    soundCheckbox:SetPoint("TOPLEFT", soundHeader, "BOTTOMLEFT", 0, -20)
    soundCheckbox.callback = function(checked)
        configuration.general.soundEffects = checked
    end
    
    -- Sound channel dropdown
    local channelOptions = {
        {text = "Master", value = "Master"},
        {text = "Sound Effects", value = "SFX"},
        {text = "Music", value = "Music"},
        {text = "Ambience", value = "Ambience"}
    }
    local channelDropdown = self:CreateDropdown(scrollChild, "Sound Channel", channelOptions, configuration.general.soundChannel)
    channelDropdown:SetPoint("TOPLEFT", soundCheckbox, "BOTTOMLEFT", 0, -30)
    channelDropdown:SetWidth(280)
    channelDropdown.callback = function(value)
        configuration.general.soundChannel = value
    end
    
    -- Enable audio feedback
    local audioFeedbackCheckbox = self:CreateCheckbox(scrollChild, "Enable Audio Feedback", configuration.general.audioFeedback)
    audioFeedbackCheckbox:SetPoint("TOPLEFT", channelDropdown, "BOTTOMLEFT", 0, -20)
    audioFeedbackCheckbox.callback = function(checked)
        configuration.general.audioFeedback = checked
    end
    
    -- Developer options header
    local devHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    devHeader:SetPoint("TOPLEFT", audioFeedbackCheckbox, "BOTTOMLEFT", 0, -30)
    devHeader:SetText("Developer Options")
    
    -- Debug mode
    local debugCheckbox = self:CreateCheckbox(scrollChild, "Enable Debug Mode", configuration.general.debugMode)
    debugCheckbox:SetPoint("TOPLEFT", devHeader, "BOTTOMLEFT", 0, -20)
    debugCheckbox.callback = function(checked)
        configuration.general.debugMode = checked
    end
    
    -- Store tab frame
    tabFrames.general = frame
}

-- Create Rotation tab
function AdvancedSettingsUI:CreateRotationTab(parent)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(parent:GetWidth(), parent:GetHeight())
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT")
    frame:Hide()
    
    -- Create scrollframe for content
    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetSize(frame:GetWidth() - 30, frame:GetHeight())
    scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    
    local scrollChild = CreateFrame("Frame")
    scrollFrame:SetScrollChild(scrollChild)
    scrollChild:SetSize(scrollFrame:GetWidth() - 20, scrollFrame:GetHeight() * 2) -- Extra height for content
    
    -- General rotation settings header
    local generalHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    generalHeader:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, -10)
    generalHeader:SetText("General Rotation Settings")
    
    -- Enable interrupts
    local interruptCheckbox = self:CreateCheckbox(scrollChild, "Enable Interrupts", configuration.rotationSettings.enableInterrupts)
    interruptCheckbox:SetPoint("TOPLEFT", generalHeader, "BOTTOMLEFT", 0, -20)
    interruptCheckbox.callback = function(checked)
        configuration.rotationSettings.enableInterrupts = checked
    end
    
    -- Enable defensives
    local defensivesCheckbox = self:CreateCheckbox(scrollChild, "Enable Defensive Abilities", configuration.rotationSettings.enableDefensives)
    defensivesCheckbox:SetPoint("TOPLEFT", interruptCheckbox, "BOTTOMLEFT", 0, -10)
    defensivesCheckbox.callback = function(checked)
        configuration.rotationSettings.enableDefensives = checked
    end
    
    -- Enable cooldowns
    local cooldownsCheckbox = self:CreateCheckbox(scrollChild, "Enable Cooldowns", configuration.rotationSettings.enableCooldowns)
    cooldownsCheckbox:SetPoint("TOPLEFT", defensivesCheckbox, "BOTTOMLEFT", 0, -10)
    cooldownsCheckbox.callback = function(checked)
        configuration.rotationSettings.enableCooldowns = checked
    end
    
    -- Enable movement abilities
    local movementCheckbox = self:CreateCheckbox(scrollChild, "Enable Movement Abilities", configuration.rotationSettings.enableMovementAbilities)
    movementCheckbox:SetPoint("TOPLEFT", cooldownsCheckbox, "BOTTOMLEFT", 0, -10)
    movementCheckbox.callback = function(checked)
        configuration.rotationSettings.enableMovementAbilities = checked
    end
    
    -- Enable potions
    local potionsCheckbox = self:CreateCheckbox(scrollChild, "Enable Potion Usage", configuration.rotationSettings.enablePotions)
    potionsCheckbox:SetPoint("TOPLEFT", movementCheckbox, "BOTTOMLEFT", 0, -10)
    potionsCheckbox.callback = function(checked)
        configuration.rotationSettings.enablePotions = checked
    end
    
    -- Enable trinkets
    local trinketsCheckbox = self:CreateCheckbox(scrollChild, "Enable Trinket Usage", configuration.rotationSettings.enableTrinkets)
    trinketsCheckbox:SetPoint("TOPLEFT", potionsCheckbox, "BOTTOMLEFT", 0, -10)
    trinketsCheckbox.callback = function(checked)
        configuration.rotationSettings.enableTrinkets = checked
    end
    
    -- Enable racials
    local racialsCheckbox = self:CreateCheckbox(scrollChild, "Enable Racial Abilities", configuration.rotationSettings.enableRacials)
    racialsCheckbox:SetPoint("TOPLEFT", trinketsCheckbox, "BOTTOMLEFT", 0, -10)
    racialsCheckbox.callback = function(checked)
        configuration.rotationSettings.enableRacials = checked
    end
    
    -- Target settings header
    local targetHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    targetHeader:SetPoint("TOPLEFT", racialsCheckbox, "BOTTOMLEFT", 0, -30)
    targetHeader:SetText("Target Settings")
    
    -- Enable target switching
    local targetSwitchCheckbox = self:CreateCheckbox(scrollChild, "Enable Target Switching", configuration.rotationSettings.targetSwitchingEnabled)
    targetSwitchCheckbox:SetPoint("TOPLEFT", targetHeader, "BOTTOMLEFT", 0, -20)
    targetSwitchCheckbox.callback = function(checked)
        configuration.rotationSettings.targetSwitchingEnabled = checked
    end
    
    -- Enable focus target
    local focusTargetCheckbox = self:CreateCheckbox(scrollChild, "Enable Focus Target Support", configuration.rotationSettings.focusTargetEnabled)
    focusTargetCheckbox:SetPoint("TOPLEFT", targetSwitchCheckbox, "BOTTOMLEFT", 0, -10)
    focusTargetCheckbox.callback = function(checked)
        configuration.rotationSettings.focusTargetEnabled = checked
    end
    
    -- AOE threshold slider
    local aoeSlider = self:CreateSlider(scrollChild, "AOE Threshold", 2, 8, 1, configuration.rotationSettings.aoeThreshold)
    aoeSlider:SetPoint("TOPLEFT", focusTargetCheckbox, "BOTTOMLEFT", 0, -30)
    aoeSlider:SetWidth(280)
    aoeSlider.callback = function(value)
        configuration.rotationSettings.aoeThreshold = value
    end
    
    -- DoT health threshold slider
    local dotSlider = self:CreateSlider(scrollChild, "Apply DoTs Above Health %", 0, 100, 5, configuration.rotationSettings.applyDotAtHealth)
    dotSlider:SetPoint("TOPLEFT", aoeSlider, "BOTTOMLEFT", 0, -30)
    dotSlider:SetWidth(280)
    dotSlider.callback = function(value)
        configuration.rotationSettings.applyDotAtHealth = value
    end
    
    -- Target max distance slider
    local distanceSlider = self:CreateSlider(scrollChild, "Max Target Distance", 5, 40, 5, configuration.rotationSettings.targetMaxDistance)
    distanceSlider:SetPoint("TOPLEFT", dotSlider, "BOTTOMLEFT", 0, -30)
    distanceSlider:SetWidth(280)
    distanceSlider.callback = function(value)
        configuration.rotationSettings.targetMaxDistance = value
    end
    
    -- Protection settings header
    local protectionHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    protectionHeader:SetPoint("TOPLEFT", distanceSlider, "BOTTOMLEFT", 0, -30)
    protectionHeader:SetText("Protection Settings")
    
    -- Out of combat healing
    local healingCheckbox = self:CreateCheckbox(scrollChild, "Enable Out of Combat Healing", configuration.rotationSettings.outOfCombatHealing)
    healingCheckbox:SetPoint("TOPLEFT", protectionHeader, "BOTTOMLEFT", 0, -20)
    healingCheckbox.callback = function(checked)
        configuration.rotationSettings.outOfCombatHealing = checked
    end
    
    -- Tank protection
    local tankProtectionCheckbox = self:CreateCheckbox(scrollChild, "Enable Tank Protection", configuration.rotationSettings.tankProtection)
    tankProtectionCheckbox:SetPoint("TOPLEFT", healingCheckbox, "BOTTOMLEFT", 0, -10)
    tankProtectionCheckbox.callback = function(checked)
        configuration.rotationSettings.tankProtection = checked
    end
    
    -- Store tab frame
    tabFrames.rotation = frame
}

-- Create Class UI tab
function AdvancedSettingsUI:CreateClassUITab(parent)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(parent:GetWidth(), parent:GetHeight())
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT")
    frame:Hide()
    
    -- Create scrollframe for content
    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetSize(frame:GetWidth() - 30, frame:GetHeight())
    scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    
    local scrollChild = CreateFrame("Frame")
    scrollFrame:SetScrollChild(scrollChild)
    scrollChild:SetSize(scrollFrame:GetWidth() - 20, scrollFrame:GetHeight() * 2) -- Extra height for content
    
    -- Class UI settings header
    local classUIHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    classUIHeader:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, -10)
    classUIHeader:SetText("Class UI Settings")
    
    -- Enable Class UI
    local enableCheckbox = self:CreateCheckbox(scrollChild, "Enable Class UI", configuration.classUI.enabled)
    enableCheckbox:SetPoint("TOPLEFT", classUIHeader, "BOTTOMLEFT", 0, -20)
    enableCheckbox.callback = function(checked)
        configuration.classUI.enabled = checked
    end
    
    -- Resource display style dropdown
    local styleOptions = {
        {text = "Default", value = "Default"},
        {text = "Compact", value = "Compact"},
        {text = "Detailed", value = "Detailed"},
        {text = "Minimalist", value = "Minimalist"}
    }
    local styleDropdown = self:CreateDropdown(scrollChild, "Resource Display Style", styleOptions, configuration.classUI.resourceDisplayStyle)
    styleDropdown:SetPoint("TOPLEFT", enableCheckbox, "BOTTOMLEFT", 0, -30)
    styleDropdown:SetWidth(280)
    styleDropdown.callback = function(value)
        configuration.classUI.resourceDisplayStyle = value
    end
    
    -- Display elements header
    local elementsHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    elementsHeader:SetPoint("TOPLEFT", styleDropdown, "BOTTOMLEFT", 0, -20)
    elementsHeader:SetText("Display Elements")
    
    -- DoT tracker
    local dotTrackerCheckbox = self:CreateCheckbox(scrollChild, "Show DoT/HoT Tracker", configuration.classUI.showDotTracker)
    dotTrackerCheckbox:SetPoint("TOPLEFT", elementsHeader, "BOTTOMLEFT", 0, -20)
    dotTrackerCheckbox.callback = function(checked)
        configuration.classUI.showDotTracker = checked
    end
    
    -- Proc display
    local procDisplayCheckbox = self:CreateCheckbox(scrollChild, "Show Proc Display", configuration.classUI.showProcDisplay)
    procDisplayCheckbox:SetPoint("TOPLEFT", dotTrackerCheckbox, "BOTTOMLEFT", 0, -10)
    procDisplayCheckbox.callback = function(checked)
        configuration.classUI.showProcDisplay = checked
    end
    
    -- APM meter
    local apmMeterCheckbox = self:CreateCheckbox(scrollChild, "Show APM Meter", configuration.classUI.showAPMMeter)
    apmMeterCheckbox:SetPoint("TOPLEFT", procDisplayCheckbox, "BOTTOMLEFT", 0, -10)
    apmMeterCheckbox.callback = function(checked)
        configuration.classUI.showAPMMeter = checked
    end
    
    -- Spell queue
    local spellQueueCheckbox = self:CreateCheckbox(scrollChild, "Show Spell Queue", configuration.classUI.showSpellQueue)
    spellQueueCheckbox:SetPoint("TOPLEFT", apmMeterCheckbox, "BOTTOMLEFT", 0, -10)
    spellQueueCheckbox.callback = function(checked)
        configuration.classUI.showSpellQueue = checked
    end
    
    -- Visual effects header
    local effectsHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    effectsHeader:SetPoint("TOPLEFT", spellQueueCheckbox, "BOTTOMLEFT", 0, -20)
    effectsHeader:SetText("Visual Effects")
    
    -- Glow effects
    local glowEffectsCheckbox = self:CreateCheckbox(scrollChild, "Enable Glow Effects", configuration.classUI.glowEffects)
    glowEffectsCheckbox:SetPoint("TOPLEFT", effectsHeader, "BOTTOMLEFT", 0, -20)
    glowEffectsCheckbox.callback = function(checked)
        configuration.classUI.glowEffects = checked
    end
    
    -- Animations
    local animationsCheckbox = self:CreateCheckbox(scrollChild, "Enable Animations", configuration.classUI.animations)
    animationsCheckbox:SetPoint("TOPLEFT", glowEffectsCheckbox, "BOTTOMLEFT", 0, -10)
    animationsCheckbox.callback = function(checked)
        configuration.classUI.animations = checked
    end
    
    -- Animation speed slider
    local animSpeedSlider = self:CreateSlider(scrollChild, "Animation Speed", 0.5, 2.0, 0.1, configuration.classUI.animationSpeed)
    animSpeedSlider:SetPoint("TOPLEFT", animationsCheckbox, "BOTTOMLEFT", 0, -30)
    animSpeedSlider:SetWidth(280)
    animSpeedSlider.callback = function(value)
        configuration.classUI.animationSpeed = value
    end
    
    -- Layout settings header
    local layoutHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    layoutHeader:SetPoint("TOPLEFT", animSpeedSlider, "BOTTOMLEFT", 0, -20)
    layoutHeader:SetText("Layout Settings")
    
    -- Scale slider
    local scaleSlider = self:CreateSlider(scrollChild, "Scale", 0.5, 2.0, 0.1, configuration.classUI.scale)
    scaleSlider:SetPoint("TOPLEFT", layoutHeader, "BOTTOMLEFT", 0, -30)
    scaleSlider:SetWidth(280)
    scaleSlider.callback = function(value)
        configuration.classUI.scale = value
    end
    
    -- Transparency slider
    local transparencySlider = self:CreateSlider(scrollChild, "Transparency", 0.1, 1.0, 0.1, configuration.classUI.transparency)
    transparencySlider:SetPoint("TOPLEFT", scaleSlider, "BOTTOMLEFT", 0, -30)
    transparencySlider:SetWidth(280)
    transparencySlider.callback = function(value)
        configuration.classUI.transparency = value
    end
    
    -- Position X/Y display
    local positionText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    positionText:SetPoint("TOPLEFT", transparencySlider, "BOTTOMLEFT", 0, -20)
    positionText:SetText("Position: X: " .. configuration.classUI.position.x .. ", Y: " .. configuration.classUI.position.y)
    
    -- Reset position button
    local resetPosButton = CreateFrame("Button", nil, scrollChild, "UIPanelButtonTemplate")
    resetPosButton:SetSize(120, 25)
    resetPosButton:SetPoint("TOPLEFT", positionText, "BOTTOMLEFT", 0, -10)
    resetPosButton:SetText("Reset Position")
    resetPosButton:SetScript("OnClick", function()
        configuration.classUI.position = {x = 0, y = -200}
        positionText:SetText("Position: X: " .. configuration.classUI.position.x .. ", Y: " .. configuration.classUI.position.y)
    end)
    
    -- Lock position
    local lockPosCheckbox = self:CreateCheckbox(scrollChild, "Lock Position", configuration.classUI.lockPosition)
    lockPosCheckbox:SetPoint("TOPLEFT", resetPosButton, "BOTTOMLEFT", 0, -10)
    lockPosCheckbox.callback = function(checked)
        configuration.classUI.lockPosition = checked
    end
    
    -- Advanced settings
    local advancedCheckbox = self:CreateCheckbox(scrollChild, "Show Advanced Information", configuration.classUI.showAdvancedInfo)
    advancedCheckbox:SetPoint("TOPLEFT", lockPosCheckbox, "BOTTOMLEFT", 0, -10)
    advancedCheckbox.callback = function(checked)
        configuration.classUI.showAdvancedInfo = checked
    end
    
    -- Store tab frame
    tabFrames.classui = frame
}

-- Create Forecasting tab
function AdvancedSettingsUI:CreateForecastingTab(parent)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(parent:GetWidth(), parent:GetHeight())
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT")
    frame:Hide()
    
    -- Create scrollframe for content
    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetSize(frame:GetWidth() - 30, frame:GetHeight())
    scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    
    local scrollChild = CreateFrame("Frame")
    scrollFrame:SetScrollChild(scrollChild)
    scrollChild:SetSize(scrollFrame:GetWidth() - 20, scrollFrame:GetHeight() * 2) -- Extra height for content
    
    -- Resource Forecast settings header
    local forecastHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    forecastHeader:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, -10)
    forecastHeader:SetText("Resource Forecast Settings")
    
    -- Enable Resource Forecast
    local enableCheckbox = self:CreateCheckbox(scrollChild, "Enable Resource Forecast", configuration.resourceForecast.enabled)
    enableCheckbox:SetPoint("TOPLEFT", forecastHeader, "BOTTOMLEFT", 0, -20)
    enableCheckbox.callback = function(checked)
        configuration.resourceForecast.enabled = checked
    end
    
    -- Forecast window slider
    local windowSlider = self:CreateSlider(scrollChild, "Forecast Window (seconds)", 5, 20, 1, configuration.resourceForecast.forecastWindow)
    windowSlider:SetPoint("TOPLEFT", enableCheckbox, "BOTTOMLEFT", 0, -30)
    windowSlider:SetWidth(280)
    windowSlider.callback = function(value)
        configuration.resourceForecast.forecastWindow = value
    end
    
    -- Show history
    local historyCheckbox = self:CreateCheckbox(scrollChild, "Show Resource History", configuration.resourceForecast.showHistory)
    historyCheckbox:SetPoint("TOPLEFT", windowSlider, "BOTTOMLEFT", 0, -20)
    historyCheckbox.callback = function(checked)
        configuration.resourceForecast.showHistory = checked
    end
    
    -- Display mode dropdown
    local modeOptions = {
        {text = "Overlay", value = "overlay"},
        {text = "Window", value = "window"}
    }
    local modeDropdown = self:CreateDropdown(scrollChild, "Display Mode", modeOptions, configuration.resourceForecast.displayMode)
    modeDropdown:SetPoint("TOPLEFT", historyCheckbox, "BOTTOMLEFT", 0, -30)
    modeDropdown:SetWidth(280)
    modeDropdown.callback = function(value)
        configuration.resourceForecast.displayMode = value
    end
    
    -- Graph style dropdown
    local styleOptions = {
        {text = "Line Graph", value = "line"},
        {text = "Bar Graph", value = "bar"},
        {text = "Text Only", value = "text"}
    }
    local styleDropdown = self:CreateDropdown(scrollChild, "Graph Style", styleOptions, configuration.resourceForecast.graphStyle)
    styleDropdown:SetPoint("TOPLEFT", modeDropdown, "BOTTOMLEFT", 0, -30)
    styleDropdown:SetWidth(280)
    styleDropdown.callback = function(value)
        configuration.resourceForecast.graphStyle = value
    end
    
    -- Graph dimensions header
    local dimensionsHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    dimensionsHeader:SetPoint("TOPLEFT", styleDropdown, "BOTTOMLEFT", 0, -20)
    dimensionsHeader:SetText("Graph Dimensions")
    
    -- Graph width slider
    local widthSlider = self:CreateSlider(scrollChild, "Width", 100, 500, 10, configuration.resourceForecast.graphWidth)
    widthSlider:SetPoint("TOPLEFT", dimensionsHeader, "BOTTOMLEFT", 0, -30)
    widthSlider:SetWidth(280)
    widthSlider.callback = function(value)
        configuration.resourceForecast.graphWidth = value
    end
    
    -- Graph height slider
    local heightSlider = self:CreateSlider(scrollChild, "Height", 50, 300, 10, configuration.resourceForecast.graphHeight)
    heightSlider:SetPoint("TOPLEFT", widthSlider, "BOTTOMLEFT", 0, -30)
    heightSlider:SetWidth(280)
    heightSlider.callback = function(value)
        configuration.resourceForecast.graphHeight = value
    end
    
    -- Display elements header
    local elementsHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    elementsHeader:SetPoint("TOPLEFT", heightSlider, "BOTTOMLEFT", 0, -20)
    elementsHeader:SetText("Display Elements")
    
    -- Show ability icons
    local iconsCheckbox = self:CreateCheckbox(scrollChild, "Show Ability Icons", configuration.resourceForecast.showAbilityIcons)
    iconsCheckbox:SetPoint("TOPLEFT", elementsHeader, "BOTTOMLEFT", 0, -20)
    iconsCheckbox.callback = function(checked)
        configuration.resourceForecast.showAbilityIcons = checked
    end
    
    -- Show legend
    local legendCheckbox = self:CreateCheckbox(scrollChild, "Show Legend", configuration.resourceForecast.showLegend)
    legendCheckbox:SetPoint("TOPLEFT", iconsCheckbox, "BOTTOMLEFT", 0, -10)
    legendCheckbox.callback = function(checked)
        configuration.resourceForecast.showLegend = checked
    end
    
    -- Advanced prediction
    local advPredictionCheckbox = self:CreateCheckbox(scrollChild, "Use Advanced Prediction", configuration.resourceForecast.advancedPrediction)
    advPredictionCheckbox:SetPoint("TOPLEFT", legendCheckbox, "BOTTOMLEFT", 0, -10)
    advPredictionCheckbox.callback = function(checked)
        configuration.resourceForecast.advancedPrediction = checked
    end
    
    -- Update frequency slider
    local updateSlider = self:CreateSlider(scrollChild, "Update Frequency (seconds)", 0.1, 1.0, 0.05, configuration.resourceForecast.updateFrequency)
    updateSlider:SetPoint("TOPLEFT", advPredictionCheckbox, "BOTTOMLEFT", 0, -30)
    updateSlider:SetWidth(280)
    updateSlider.callback = function(value)
        configuration.resourceForecast.updateFrequency = value
    end
    
    -- Position and scale header
    local positionHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    positionHeader:SetPoint("TOPLEFT", updateSlider, "BOTTOMLEFT", 0, -20)
    positionHeader:SetText("Position and Scale")
    
    -- Scale slider
    local scaleSlider = self:CreateSlider(scrollChild, "Scale", 0.5, 2.0, 0.1, configuration.resourceForecast.scale)
    scaleSlider:SetPoint("TOPLEFT", positionHeader, "BOTTOMLEFT", 0, -30)
    scaleSlider:SetWidth(280)
    scaleSlider.callback = function(value)
        configuration.resourceForecast.scale = value
    end
    
    -- Transparency slider
    local transparencySlider = self:CreateSlider(scrollChild, "Transparency", 0.1, 1.0, 0.1, configuration.resourceForecast.transparency)
    transparencySlider:SetPoint("TOPLEFT", scaleSlider, "BOTTOMLEFT", 0, -30)
    transparencySlider:SetWidth(280)
    transparencySlider.callback = function(value)
        configuration.resourceForecast.transparency = value
    end
    
    -- Position X/Y display
    local positionText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    positionText:SetPoint("TOPLEFT", transparencySlider, "BOTTOMLEFT", 0, -20)
    positionText:SetText("Position: X: " .. configuration.resourceForecast.position.x .. ", Y: " .. configuration.resourceForecast.position.y)
    
    -- Reset position button
    local resetPosButton = CreateFrame("Button", nil, scrollChild, "UIPanelButtonTemplate")
    resetPosButton:SetSize(120, 25)
    resetPosButton:SetPoint("TOPLEFT", positionText, "BOTTOMLEFT", 0, -10)
    resetPosButton:SetText("Reset Position")
    resetPosButton:SetScript("OnClick", function()
        configuration.resourceForecast.position = {x = 400, y = 0}
        positionText:SetText("Position: X: " .. configuration.resourceForecast.position.x .. ", Y: " .. configuration.resourceForecast.position.y)
    end)
    
    -- Lock position
    local lockPosCheckbox = self:CreateCheckbox(scrollChild, "Lock Position", configuration.resourceForecast.lockPosition)
    lockPosCheckbox:SetPoint("TOPLEFT", resetPosButton, "BOTTOMLEFT", 0, -10)
    lockPosCheckbox.callback = function(checked)
        configuration.resourceForecast.lockPosition = checked
    end
    
    -- Store tab frame
    tabFrames.forecasting = frame
}

-- Create Machine Learning tab
function AdvancedSettingsUI:CreateMachineLearningTab(parent)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(parent:GetWidth(), parent:GetHeight())
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT")
    frame:Hide()
    
    -- Create scrollframe for content
    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetSize(frame:GetWidth() - 30, frame:GetHeight())
    scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    
    local scrollChild = CreateFrame("Frame")
    scrollFrame:SetScrollChild(scrollChild)
    scrollChild:SetSize(scrollFrame:GetWidth() - 20, scrollFrame:GetHeight() * 2) -- Extra height for content
    
    -- Machine Learning settings header
    local mlHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    mlHeader:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, -10)
    mlHeader:SetText("Machine Learning Settings")
    
    -- Enable Machine Learning
    local enableCheckbox = self:CreateCheckbox(scrollChild, "Enable Machine Learning", configuration.machineLearning.enabled)
    enableCheckbox:SetPoint("TOPLEFT", mlHeader, "BOTTOMLEFT", 0, -20)
    enableCheckbox.callback = function(checked)
        configuration.machineLearning.enabled = checked
    end
    
    -- Data collection settings header
    local dataHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    dataHeader:SetPoint("TOPLEFT", enableCheckbox, "BOTTOMLEFT", 0, -20)
    dataHeader:SetText("Data Collection")
    
    -- Enable data collection
    local dataCollectionCheckbox = self:CreateCheckbox(scrollChild, "Enable Data Collection", configuration.machineLearning.dataCollection)
    dataCollectionCheckbox:SetPoint("TOPLEFT", dataHeader, "BOTTOMLEFT", 0, -20)
    dataCollectionCheckbox.callback = function(checked)
        configuration.machineLearning.dataCollection = checked
    end
    
    -- Share anonymous data
    local shareDataCheckbox = self:CreateCheckbox(scrollChild, "Share Anonymous Data", configuration.machineLearning.shareAnonymousData)
    shareDataCheckbox:SetPoint("TOPLEFT", dataCollectionCheckbox, "BOTTOMLEFT", 0, -10)
    shareDataCheckbox.callback = function(checked)
        configuration.machineLearning.shareAnonymousData = checked
    end
    
    -- Storage limit slider
    local storageSlider = self:CreateSlider(scrollChild, "Storage Limit (combats)", 10, 500, 10, configuration.machineLearning.storageLimit)
    storageSlider:SetPoint("TOPLEFT", shareDataCheckbox, "BOTTOMLEFT", 0, -30)
    storageSlider:SetWidth(280)
    storageSlider.callback = function(value)
        configuration.machineLearning.storageLimit = value
    end
    
    -- Learning settings header
    local learningHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    learningHeader:SetPoint("TOPLEFT", storageSlider, "BOTTOMLEFT", 0, -20)
    learningHeader:SetText("Learning Settings")
    
    -- Learning rate slider
    local learningRateSlider = self:CreateSlider(scrollChild, "Learning Rate", 0.01, 0.5, 0.01, configuration.machineLearning.learningRate)
    learningRateSlider:SetPoint("TOPLEFT", learningHeader, "BOTTOMLEFT", 0, -30)
    learningRateSlider:SetWidth(280)
    learningRateSlider.callback = function(value)
        configuration.machineLearning.learningRate = value
    end
    
    -- Model priority slider
    local prioritySlider = self:CreateSlider(scrollChild, "Global vs. Personal Balance", 0, 1, 0.05, configuration.machineLearning.modelPriority)
    prioritySlider:SetPoint("TOPLEFT", learningRateSlider, "BOTTOMLEFT", 0, -30)
    prioritySlider:SetWidth(280)
    prioritySlider.callback = function(value)
        configuration.machineLearning.modelPriority = value
    end
    prioritySlider.lowText:SetText("Personal")
    prioritySlider.highText:SetText("Global")
    
    -- Minimum sample size slider
    local sampleSlider = self:CreateSlider(scrollChild, "Minimum Sample Size", 1, 50, 1, configuration.machineLearning.minimumSampleSize)
    sampleSlider:SetPoint("TOPLEFT", prioritySlider, "BOTTOMLEFT", 0, -30)
    sampleSlider:SetWidth(280)
    sampleSlider.callback = function(value)
        configuration.machineLearning.minimumSampleSize = value
    end
    
    -- Adaptation speed slider
    local adaptationSlider = self:CreateSlider(scrollChild, "Adaptation Speed", 1, 5, 1, configuration.machineLearning.adaptationSpeed)
    adaptationSlider:SetPoint("TOPLEFT", sampleSlider, "BOTTOMLEFT", 0, -30)
    adaptationSlider:SetWidth(280)
    adaptationSlider.callback = function(value)
        configuration.machineLearning.adaptationSpeed = value
    end
    adaptationSlider.lowText:SetText("Slow")
    adaptationSlider.highText:SetText("Fast")
    
    -- Performance metrics header
    local metricsHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    metricsHeader:SetPoint("TOPLEFT", adaptationSlider, "BOTTOMLEFT", 0, -20)
    metricsHeader:SetText("Performance Metrics")
    
    -- DPS/HPS metric
    local dpsCheckbox = self:CreateCheckbox(scrollChild, "Include DPS/HPS", configuration.machineLearning.includeMetrics.dps)
    dpsCheckbox:SetPoint("TOPLEFT", metricsHeader, "BOTTOMLEFT", 0, -20)
    dpsCheckbox.callback = function(checked)
        configuration.machineLearning.includeMetrics.dps = checked
    end
    
    -- Survival time metric
    local survivalCheckbox = self:CreateCheckbox(scrollChild, "Include Survival Time", configuration.machineLearning.includeMetrics.survivalTime)
    survivalCheckbox:SetPoint("TOPLEFT", dpsCheckbox, "BOTTOMLEFT", 0, -10)
    survivalCheckbox.callback = function(checked)
        configuration.machineLearning.includeMetrics.survivalTime = checked
    end
    
    -- Resource efficiency metric
    local resourceCheckbox = self:CreateCheckbox(scrollChild, "Include Resource Efficiency", configuration.machineLearning.includeMetrics.resourceEfficiency)
    resourceCheckbox:SetPoint("TOPLEFT", survivalCheckbox, "BOTTOMLEFT", 0, -10)
    resourceCheckbox.callback = function(checked)
        configuration.machineLearning.includeMetrics.resourceEfficiency = checked
    end
    
    -- Mechanic handling metric
    local mechanicCheckbox = self:CreateCheckbox(scrollChild, "Include Mechanic Handling", configuration.machineLearning.includeMetrics.mechanicHandling)
    mechanicCheckbox:SetPoint("TOPLEFT", resourceCheckbox, "BOTTOMLEFT", 0, -10)
    mechanicCheckbox.callback = function(checked)
        configuration.machineLearning.includeMetrics.mechanicHandling = checked
    end
    
    -- APM metric
    local apmCheckbox = self:CreateCheckbox(scrollChild, "Include APM", configuration.machineLearning.includeMetrics.apm)
    apmCheckbox:SetPoint("TOPLEFT", mechanicCheckbox, "BOTTOMLEFT", 0, -10)
    apmCheckbox.callback = function(checked)
        configuration.machineLearning.includeMetrics.apm = checked
    end
    
    -- Store tab frame
    tabFrames.machinelearning = frame
}

-- Create PvP tab
function AdvancedSettingsUI:CreatePvPTab(parent)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(parent:GetWidth(), parent:GetHeight())
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT")
    frame:Hide()
    
    -- Create scrollframe for content
    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetSize(frame:GetWidth() - 30, frame:GetHeight())
    scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    
    local scrollChild = CreateFrame("Frame")
    scrollFrame:SetScrollChild(scrollChild)
    scrollChild:SetSize(scrollFrame:GetWidth() - 20, scrollFrame:GetHeight() * 2) -- Extra height for content
    
    -- PvP settings header
    local pvpHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    pvpHeader:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, -10)
    pvpHeader:SetText("PvP System Settings")
    
    -- Enable PvP optimization
    local enableCheckbox = self:CreateCheckbox(scrollChild, "Enable PvP Optimization", configuration.pvp.enabled)
    enableCheckbox:SetPoint("TOPLEFT", pvpHeader, "BOTTOMLEFT", 0, -20)
    enableCheckbox.callback = function(checked)
        configuration.pvp.enabled = checked
    end
    
    -- Target settings header
    local targetHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    targetHeader:SetPoint("TOPLEFT", enableCheckbox, "BOTTOMLEFT", 0, -20)
    targetHeader:SetText("Target Settings")
    
    -- Prioritize healers
    local healersCheckbox = self:CreateCheckbox(scrollChild, "Prioritize Enemy Healers", configuration.pvp.prioritizeHealers)
    healersCheckbox:SetPoint("TOPLEFT", targetHeader, "BOTTOMLEFT", 0, -20)
    healersCheckbox.callback = function(checked)
        configuration.pvp.prioritizeHealers = checked
    end
    
    -- Target switch suggestions
    local switchCheckbox = self:CreateCheckbox(scrollChild, "Enable Target Switch Suggestions", configuration.pvp.targetSwitchSuggestions)
    switchCheckbox:SetPoint("TOPLEFT", healersCheckbox, "BOTTOMLEFT", 0, -10)
    switchCheckbox.callback = function(checked)
        configuration.pvp.targetSwitchSuggestions = checked
    end
    
    -- Focus target tracking
    local focusCheckbox = self:CreateCheckbox(scrollChild, "Enable Focus Target Tracking", configuration.pvp.focusTargetTracking)
    focusCheckbox:SetPoint("TOPLEFT", switchCheckbox, "BOTTOMLEFT", 0, -10)
    focusCheckbox.callback = function(checked)
        configuration.pvp.focusTargetTracking = checked
    end
    
    -- Combat abilities header
    local combatHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    combatHeader:SetPoint("TOPLEFT", focusCheckbox, "BOTTOMLEFT", 0, -20)
    combatHeader:SetText("Combat Abilities")
    
    -- Auto defensive usage
    local defensiveCheckbox = self:CreateCheckbox(scrollChild, "Auto Defensive Usage", configuration.pvp.autoDefensiveUsage)
    defensiveCheckbox:SetPoint("TOPLEFT", combatHeader, "BOTTOMLEFT", 0, -20)
    defensiveCheckbox.callback = function(checked)
        configuration.pvp.autoDefensiveUsage = checked
    end
    
    -- Auto interrupt
    local interruptCheckbox = self:CreateCheckbox(scrollChild, "Auto Interrupt Important Spells", configuration.pvp.autoInterrupt)
    interruptCheckbox:SetPoint("TOPLEFT", defensiveCheckbox, "BOTTOMLEFT", 0, -10)
    interruptCheckbox.callback = function(checked)
        configuration.pvp.autoInterrupt = checked
    end
    
    -- Enable burst detection
    local burstCheckbox = self:CreateCheckbox(scrollChild, "Enable Burst Detection", configuration.pvp.enableBurstDetection)
    burstCheckbox:SetPoint("TOPLEFT", interruptCheckbox, "BOTTOMLEFT", 0, -10)
    burstCheckbox.callback = function(checked)
        configuration.pvp.enableBurstDetection = checked
    end
    
    -- Defensive threshold slider
    local thresholdSlider = self:CreateSlider(scrollChild, "Defensive Threshold", 1, 3, 1, configuration.pvp.defensiveThreshold)
    thresholdSlider:SetPoint("TOPLEFT", burstCheckbox, "BOTTOMLEFT", 0, -30)
    thresholdSlider:SetWidth(280)
    thresholdSlider.callback = function(value)
        configuration.pvp.defensiveThreshold = value
    end
    thresholdSlider.lowText:SetText("Conservative")
    thresholdSlider.highText:SetText("Aggressive")
    
    -- Display settings header
    local displayHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    displayHeader:SetPoint("TOPLEFT", thresholdSlider, "BOTTOMLEFT", 0, -20)
    displayHeader:SetText("Display Settings")
    
    -- Show enemy cooldowns
    local cooldownsCheckbox = self:CreateCheckbox(scrollChild, "Show Enemy Cooldowns", configuration.pvp.showEnemyCooldowns)
    cooldownsCheckbox:SetPoint("TOPLEFT", displayHeader, "BOTTOMLEFT", 0, -20)
    cooldownsCheckbox.callback = function(checked)
        configuration.pvp.showEnemyCooldowns = checked
    end
    
    -- Show diminishing returns
    local drCheckbox = self:CreateCheckbox(scrollChild, "Show Diminishing Returns", configuration.pvp.showDiminishingReturns)
    drCheckbox:SetPoint("TOPLEFT", cooldownsCheckbox, "BOTTOMLEFT", 0, -10)
    drCheckbox.callback = function(checked)
        configuration.pvp.showDiminishingReturns = checked
    end
    
    -- Show PvP team display
    local teamDisplayCheckbox = self:CreateCheckbox(scrollChild, "Show PvP Team Display", configuration.pvp.showPvPTeamDisplay)
    teamDisplayCheckbox:SetPoint("TOPLEFT", drCheckbox, "BOTTOMLEFT", 0, -10)
    teamDisplayCheckbox.callback = function(checked)
        configuration.pvp.showPvPTeamDisplay = checked
    end
    
    -- Always show CC timer
    local ccTimerCheckbox = self:CreateCheckbox(scrollChild, "Always Show CC Timer", configuration.pvp.alwaysShowCCTimer)
    ccTimerCheckbox:SetPoint("TOPLEFT", teamDisplayCheckbox, "BOTTOMLEFT", 0, -10)
    ccTimerCheckbox.callback = function(checked)
        configuration.pvp.alwaysShowCCTimer = checked
    end
    
    -- Enemy frame scale slider
    local scaleSlider = self:CreateSlider(scrollChild, "Enemy Frame Scale", 0.5, 2.0, 0.1, configuration.pvp.enemyFrameScale)
    scaleSlider:SetPoint("TOPLEFT", ccTimerCheckbox, "BOTTOMLEFT", 0, -30)
    scaleSlider:SetWidth(280)
    scaleSlider.callback = function(value)
        configuration.pvp.enemyFrameScale = value
    end
    
    -- Position X/Y display
    local positionText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    positionText:SetPoint("TOPLEFT", scaleSlider, "BOTTOMLEFT", 0, -20)
    positionText:SetText("Enemy Frame Position: X: " .. configuration.pvp.enemyFramePosition.x .. ", Y: " .. configuration.pvp.enemyFramePosition.y)
    
    -- Reset position button
    local resetPosButton = CreateFrame("Button", nil, scrollChild, "UIPanelButtonTemplate")
    resetPosButton:SetSize(120, 25)
    resetPosButton:SetPoint("TOPLEFT", positionText, "BOTTOMLEFT", 0, -10)
    resetPosButton:SetText("Reset Position")
    resetPosButton:SetScript("OnClick", function()
        configuration.pvp.enemyFramePosition = {x = -400, y = 0}
        positionText:SetText("Enemy Frame Position: X: " .. configuration.pvp.enemyFramePosition.x .. ", Y: " .. configuration.pvp.enemyFramePosition.y)
    end)
    
    -- Store tab frame
    tabFrames.pvp = frame
}

-- Create Advanced tab
function AdvancedSettingsUI:CreateAdvancedTab(parent)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(parent:GetWidth(), parent:GetHeight())
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT")
    frame:Hide()
    
    -- Create scrollframe for content
    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetSize(frame:GetWidth() - 30, frame:GetHeight())
    scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    
    local scrollChild = CreateFrame("Frame")
    scrollFrame:SetScrollChild(scrollChild)
    scrollChild:SetSize(scrollFrame:GetWidth() - 20, scrollFrame:GetHeight() * 2) -- Extra height for content
    
    -- Advanced settings header
    local advancedHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    advancedHeader:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, -10)
    advancedHeader:SetText("Advanced Settings")
    
    -- Warning text
    local warningText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    warningText:SetPoint("TOPLEFT", advancedHeader, "BOTTOMLEFT", 0, -10)
    warningText:SetText("|cFFFF0000Warning: These settings are for advanced users. Incorrect configuration may cause errors or reduced performance.|r")
    warningText:SetWidth(scrollChild:GetWidth() - 20)
    
    -- Lua snippets header
    local snippetsHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    snippetsHeader:SetPoint("TOPLEFT", warningText, "BOTTOMLEFT", 0, -20)
    snippetsHeader:SetText("Lua Snippets")
    
    -- Enable Lua snippets
    local snippetsCheckbox = self:CreateCheckbox(scrollChild, "Enable Lua Snippets", configuration.advanced.enableLuaSnippets)
    snippetsCheckbox:SetPoint("TOPLEFT", snippetsHeader, "BOTTOMLEFT", 0, -20)
    snippetsCheckbox.callback = function(checked)
        configuration.advanced.enableLuaSnippets = checked
    end
    
    -- Integration header
    local integrationHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    integrationHeader:SetPoint("TOPLEFT", snippetsCheckbox, "BOTTOMLEFT", 0, -20)
    integrationHeader:SetText("External Integration")
    
    -- WeakAuras integration
    local weakAurasCheckbox = self:CreateCheckbox(scrollChild, "Enable WeakAuras Integration", configuration.advanced.enableWeakAurasIntegration)
    weakAurasCheckbox:SetPoint("TOPLEFT", integrationHeader, "BOTTOMLEFT", 0, -20)
    weakAurasCheckbox.callback = function(checked)
        configuration.advanced.enableWeakAurasIntegration = checked
    end
    
    -- External APIs
    local externalAPIsCheckbox = self:CreateCheckbox(scrollChild, "Enable External API Integration", configuration.advanced.enableExternalAPIs)
    externalAPIsCheckbox:SetPoint("TOPLEFT", weakAurasCheckbox, "BOTTOMLEFT", 0, -10)
    externalAPIsCheckbox.callback = function(checked)
        configuration.advanced.enableExternalAPIs = checked
    end
    
    -- Performance header
    local performanceHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    performanceHeader:SetPoint("TOPLEFT", externalAPIsCheckbox, "BOTTOMLEFT", 0, -20)
    performanceHeader:SetText("Performance Tuning")
    
    -- Performance tuning slider
    local performanceSlider = self:CreateSlider(scrollChild, "Performance vs. Accuracy", 1, 5, 1, configuration.advanced.performanceTuning)
    performanceSlider:SetPoint("TOPLEFT", performanceHeader, "BOTTOMLEFT", 0, -30)
    performanceSlider:SetWidth(280)
    performanceSlider.callback = function(value)
        configuration.advanced.performanceTuning = value
    end
    performanceSlider.lowText:SetText("Performance")
    performanceSlider.highText:SetText("Accuracy")
    
    -- Async processing
    local asyncCheckbox = self:CreateCheckbox(scrollChild, "Enable Asynchronous Processing", configuration.advanced.asyncProcessing)
    asyncCheckbox:SetPoint("TOPLEFT", performanceSlider, "BOTTOMLEFT", 0, -20)
    asyncCheckbox.callback = function(checked)
        configuration.advanced.asyncProcessing = checked
    end
    
    -- Event filtering
    local eventFilteringCheckbox = self:CreateCheckbox(scrollChild, "Enable Event Filtering", configuration.advanced.eventFiltering)
    eventFilteringCheckbox:SetPoint("TOPLEFT", asyncCheckbox, "BOTTOMLEFT", 0, -10)
    eventFilteringCheckbox.callback = function(checked)
        configuration.advanced.eventFiltering = checked
    end
    
    -- GCD adjustment slider
    local gcdSlider = self:CreateSlider(scrollChild, "GCD Detection Adjustment (ms)", -50, 50, 5, configuration.advanced.globalCooldownAdjustment)
    gcdSlider:SetPoint("TOPLEFT", eventFilteringCheckbox, "BOTTOMLEFT", 0, -30)
    gcdSlider:SetWidth(280)
    gcdSlider.callback = function(value)
        configuration.advanced.globalCooldownAdjustment = value
    end
    
    -- Debug header
    local debugHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    debugHeader:SetPoint("TOPLEFT", gcdSlider, "BOTTOMLEFT", 0, -20)
    debugHeader:SetText("Debugging")
    
    -- Show debug console
    local consoleCheckbox = self:CreateCheckbox(scrollChild, "Show Debug Console", configuration.advanced.showDebugConsole)
    consoleCheckbox:SetPoint("TOPLEFT", debugHeader, "BOTTOMLEFT", 0, -20)
    consoleCheckbox.callback = function(checked)
        configuration.advanced.showDebugConsole = checked
    end
    
    -- Log level slider
    local logSlider = self:CreateSlider(scrollChild, "Log Level", 1, 3, 1, configuration.advanced.logLevel)
    logSlider:SetPoint("TOPLEFT", consoleCheckbox, "BOTTOMLEFT", 0, -30)
    logSlider:SetWidth(280)
    logSlider.callback = function(value)
        configuration.advanced.logLevel = value
    end
    logSlider.lowText:SetText("Errors")
    logSlider.highText:SetText("Verbose")
    
    -- Custom hotkeys header
    local hotkeysHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    hotkeysHeader:SetPoint("TOPLEFT", logSlider, "BOTTOMLEFT", 0, -20)
    hotkeysHeader:SetText("Custom Hotkeys")
    
    -- Custom hotkeys button
    local hotkeysButton = CreateFrame("Button", nil, scrollChild, "UIPanelButtonTemplate")
    hotkeysButton:SetSize(200, 25)
    hotkeysButton:SetPoint("TOPLEFT", hotkeysHeader, "BOTTOMLEFT", 0, -20)
    hotkeysButton:SetText("Configure Custom Hotkeys")
    hotkeysButton:SetScript("OnClick", function()
        -- Would open a custom hotkey configuration dialog
        print("Custom hotkey configuration would open here")
    end)
    
    -- Custom conditions button
    local conditionsButton = CreateFrame("Button", nil, scrollChild, "UIPanelButtonTemplate")
    conditionsButton:SetSize(200, 25)
    conditionsButton:SetPoint("TOPLEFT", hotkeysButton, "BOTTOMLEFT", 0, -20)
    conditionsButton:SetText("Configure Custom Conditions")
    conditionsButton:SetScript("OnClick", function()
        -- Would open a custom conditions editor
        print("Custom conditions editor would open here")
    end)
    
    -- Reset advanced settings button
    local resetButton = CreateFrame("Button", nil, scrollChild, "UIPanelButtonTemplate")
    resetButton:SetSize(200, 25)
    resetButton:SetPoint("TOPLEFT", conditionsButton, "BOTTOMLEFT", 0, -30)
    resetButton:SetText("Reset All Advanced Settings")
    resetButton:SetScript("OnClick", function()
        StaticPopupDialogs["WR_RESET_ADVANCED_CONFIRM"] = {
            text = "Are you sure you want to reset all advanced settings to defaults? This cannot be undone.",
            button1 = "Yes",
            button2 = "No",
            OnAccept = function()
                -- Reset advanced settings to defaults
                configuration.advanced = self:DeepCopy(defaultConfiguration.advanced)
                
                -- Refresh tab
                self:SelectTab("advanced")
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        }
        StaticPopup_Show("WR_RESET_ADVANCED_CONFIRM")
    end)
    
    -- Store tab frame
    tabFrames.advanced = frame
}

-- Create Profiles tab
function AdvancedSettingsUI:CreateProfilesTab(parent)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(parent:GetWidth(), parent:GetHeight())
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT")
    frame:Hide()
    
    -- Create scrollframe for content
    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetSize(frame:GetWidth() - 30, frame:GetHeight())
    scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    
    local scrollChild = CreateFrame("Frame")
    scrollFrame:SetScrollChild(scrollChild)
    scrollChild:SetSize(scrollFrame:GetWidth() - 20, scrollFrame:GetHeight() * 2) -- Extra height for content
    
    -- Profiles header
    local profilesHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    profilesHeader:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, -10)
    profilesHeader:SetText("Profile Management")
    
    -- Current profile text
    local currentProfileText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    currentProfileText:SetPoint("TOPLEFT", profilesHeader, "BOTTOMLEFT", 0, -20)
    currentProfileText:SetText("Current Profile: " .. configuration.profiles.active)
    
    -- Available profiles header
    local availableHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    availableHeader:SetPoint("TOPLEFT", currentProfileText, "BOTTOMLEFT", 0, -20)
    availableHeader:SetText("Available Profiles:")
    
    -- Profiles list frame
    local listFrame = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
    listFrame:SetSize(300, 150)
    listFrame:SetPoint("TOPLEFT", availableHeader, "BOTTOMLEFT", 0, -10)
    listFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 16,
        insets = { left = 5, right = 5, top = 5, bottom = 5 }
    })
    
    -- Create profile buttons
    local profileButtons = {}
    local buttonHeight = 25
    local offset = 10
    
    for name, _ in pairs(configuration.profiles.list) do
        local button = CreateFrame("Button", nil, listFrame, "UIPanelButtonTemplate")
        button:SetSize(250, buttonHeight)
        button:SetPoint("TOPLEFT", listFrame, "TOPLEFT", 20, -offset)
        button:SetText(name)
        
        -- Highlight active profile
        if name == configuration.profiles.active then
            button:SetBackdropColor(0.1, 0.5, 0.1, 0.5)
        end
        
        button:SetScript("OnClick", function()
            -- Set as active profile
            configuration.profiles.active = name
            currentProfileText:SetText("Current Profile: " .. name)
            
            -- Highlight only this button
            for _, btn in ipairs(profileButtons) do
                btn:SetBackdropColor(0, 0, 0, 0)
            end
            button:SetBackdropColor(0.1, 0.5, 0.1, 0.5)
        end)
        
        table.insert(profileButtons, button)
        offset = offset + buttonHeight + 5
    end
    
    -- Profile actions header
    local actionsHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    actionsHeader:SetPoint("TOPLEFT", listFrame, "BOTTOMLEFT", 0, -20)
    actionsHeader:SetText("Profile Actions:")
    
    -- New profile button
    local newButton = CreateFrame("Button", nil, scrollChild, "UIPanelButtonTemplate")
    newButton:SetSize(120, 25)
    newButton:SetPoint("TOPLEFT", actionsHeader, "BOTTOMLEFT", 0, -10)
    newButton:SetText("New Profile")
    newButton:SetScript("OnClick", function()
        -- Open new profile dialog
        StaticPopupDialogs["WR_NEW_PROFILE"] = {
            text = "Enter name for new profile:",
            button1 = "Create",
            button2 = "Cancel",
            OnAccept = function(self)
                local name = self.editBox:GetText()
                if name and name ~= "" then
                    -- Check if profile already exists
                    if configuration.profiles.list[name] then
                        print("Profile '" .. name .. "' already exists.")
                        return
                    end
                    
                    -- Create new profile
                    configuration.profiles.list[name] = self:DeepCopy(configuration)
                    
                    -- Switch to it
                    configuration.profiles.active = name
                    
                    -- Refresh tab
                    self:SelectTab("profiles")
                end
            end,
            OnCancel = function()
                -- Do nothing
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            hasEditBox = true,
            preferredIndex = 3,
        }
        StaticPopup_Show("WR_NEW_PROFILE")
    end)
    
    -- Copy profile button
    local copyButton = CreateFrame("Button", nil, scrollChild, "UIPanelButtonTemplate")
    copyButton:SetSize(120, 25)
    copyButton:SetPoint("LEFT", newButton, "RIGHT", 10, 0)
    copyButton:SetText("Copy Profile")
    copyButton:SetScript("OnClick", function()
        -- Open copy profile dialog
        StaticPopupDialogs["WR_COPY_PROFILE"] = {
            text = "Enter name for profile copy:",
            button1 = "Copy",
            button2 = "Cancel",
            OnAccept = function(self)
                local name = self.editBox:GetText()
                if name and name ~= "" and name ~= configuration.profiles.active then
                    -- Check if profile already exists
                    if configuration.profiles.list[name] then
                        print("Profile '" .. name .. "' already exists.")
                        return
                    end
                    
                    -- Copy current profile
                    configuration.profiles.list[name] = self:DeepCopy(configuration)
                    
                    -- Refresh tab
                    self:SelectTab("profiles")
                end
            end,
            OnCancel = function()
                -- Do nothing
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            hasEditBox = true,
            preferredIndex = 3,
        }
        StaticPopup_Show("WR_COPY_PROFILE")
    end)
    
    -- Delete profile button
    local deleteButton = CreateFrame("Button", nil, scrollChild, "UIPanelButtonTemplate")
    deleteButton:SetSize(120, 25)
    deleteButton:SetPoint("TOPLEFT", newButton, "BOTTOMLEFT", 0, -10)
    deleteButton:SetText("Delete Profile")
    deleteButton:SetScript("OnClick", function()
        -- Prevent deleting Default profile
        if configuration.profiles.active == "Default" then
            print("Cannot delete the Default profile.")
            return
        end
        
        -- Confirm deletion
        StaticPopupDialogs["WR_DELETE_PROFILE"] = {
            text = "Are you sure you want to delete profile '" .. configuration.profiles.active .. "'?",
            button1 = "Delete",
            button2 = "Cancel",
            OnAccept = function()
                local currentProfile = configuration.profiles.active
                
                -- Switch to Default profile
                configuration.profiles.active = "Default"
                
                -- Delete the profile
                configuration.profiles.list[currentProfile] = nil
                
                -- Refresh tab
                self:SelectTab("profiles")
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        }
        StaticPopup_Show("WR_DELETE_PROFILE")
    end)
    
    -- Reset profile button
    local resetButton = CreateFrame("Button", nil, scrollChild, "UIPanelButtonTemplate")
    resetButton:SetSize(120, 25)
    resetButton:SetPoint("LEFT", deleteButton, "RIGHT", 10, 0)
    resetButton:SetText("Reset Profile")
    resetButton:SetScript("OnClick", function()
        -- Confirm reset
        StaticPopupDialogs["WR_RESET_PROFILE"] = {
            text = "Are you sure you want to reset profile '" .. configuration.profiles.active .. "' to defaults?",
            button1 = "Reset",
            button2 = "Cancel",
            OnAccept = function()
                -- Reset current profile to defaults
                configuration.profiles.list[configuration.profiles.active] = self:DeepCopy(defaultConfiguration)
                
                -- Refresh tab
                self:SelectTab("profiles")
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        }
        StaticPopup_Show("WR_RESET_PROFILE")
    end)
    
    -- Context-specific profiles header
    local contextHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    contextHeader:SetPoint("TOPLEFT", deleteButton, "BOTTOMLEFT", 0, -30)
    contextHeader:SetText("Context-Specific Profiles:")
    
    -- Raid profile dropdown
    local raidOptions = {
        {text = "-- None --", value = ""},
    }
    for name, _ in pairs(configuration.profiles.list) do
        table.insert(raidOptions, {text = name, value = name})
    end
    local raidDropdown = self:CreateDropdown(scrollChild, "Raid", raidOptions, configuration.profiles.contexts.raid)
    raidDropdown:SetPoint("TOPLEFT", contextHeader, "BOTTOMLEFT", 0, -30)
    raidDropdown:SetWidth(200)
    raidDropdown.callback = function(value)
        configuration.profiles.contexts.raid = value
    end
    
    -- Dungeon profile dropdown
    local dungeonDropdown = self:CreateDropdown(scrollChild, "Dungeon", raidOptions, configuration.profiles.contexts.dungeon)
    dungeonDropdown:SetPoint("TOPLEFT", raidDropdown, "BOTTOMLEFT", 0, -30)
    dungeonDropdown:SetWidth(200)
    dungeonDropdown.callback = function(value)
        configuration.profiles.contexts.dungeon = value
    end
    
    -- PvP profile dropdown
    local pvpDropdown = self:CreateDropdown(scrollChild, "PvP", raidOptions, configuration.profiles.contexts.pvp)
    pvpDropdown:SetPoint("TOPLEFT", dungeonDropdown, "BOTTOMLEFT", 0, -30)
    pvpDropdown:SetWidth(200)
    pvpDropdown.callback = function(value)
        configuration.profiles.contexts.pvp = value
    end
    
    -- World profile dropdown
    local worldDropdown = self:CreateDropdown(scrollChild, "World", raidOptions, configuration.profiles.contexts.world)
    worldDropdown:SetPoint("TOPLEFT", pvpDropdown, "BOTTOMLEFT", 0, -30)
    worldDropdown:SetWidth(200)
    worldDropdown.callback = function(value)
        configuration.profiles.contexts.world = value
    end
    
    -- Store tab frame
    tabFrames.profiles = frame
}

-- Create a checkbox widget
function AdvancedSettingsUI:CreateCheckbox(parent, label, initialValue)
    local checkbox = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    checkbox.Text:SetText(label)
    checkbox:SetChecked(initialValue)
    
    checkbox:SetScript("OnClick", function(self)
        local checked = self:GetChecked()
        PlaySound(checked and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
        
        if checkbox.callback then
            checkbox.callback(checked)
        end
    end)
    
    return checkbox
end

-- Create a slider widget
function AdvancedSettingsUI:CreateSlider(parent, label, min, max, step, initialValue)
    local slider = CreateFrame("Slider", nil, parent, "OptionsSliderTemplate")
    slider:SetMinMaxValues(min, max)
    slider:SetValueStep(step)
    slider:SetValue(initialValue)
    slider:SetObeyStepOnDrag(true)
    
    slider.Text:SetText(label)
    slider.Low:SetText(min)
    slider.High:SetText(max)
    
    -- Add value text
    slider.Value = slider:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    slider.Value:SetPoint("TOP", slider, "BOTTOM", 0, 0)
    slider.Value:SetText(initialValue)
    
    slider:SetScript("OnValueChanged", function(self, value)
        -- Round to nearest step
        value = math.floor(value / step + 0.5) * step
        
        -- Format value based on step precision
        local formatStr = step >= 1 and "%d" or "%.2f"
        self.Value:SetText(string.format(formatStr, value))
        
        if slider.callback then
            slider.callback(value)
        end
    end)
    
    -- Store references to text elements for later customization
    slider.lowText = slider.Low
    slider.highText = slider.High
    
    return slider
end

-- Create a dropdown widget
function AdvancedSettingsUI:CreateDropdown(parent, label, options, initialValue)
    -- Create label
    local dropdownLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    dropdownLabel:SetText(label)
    
    -- Create dropdown frame
    local dropdown = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPLEFT", dropdownLabel, "BOTTOMLEFT", -15, -5)
    
    -- Initialize dropdown
    UIDropDownMenu_SetWidth(dropdown, 180)
    UIDropDownMenu_SetText(dropdown, "")
    
    -- Set initial value
    for _, option in ipairs(options) do
        if option.value == initialValue then
            UIDropDownMenu_SetText(dropdown, option.text)
            break
        end
    end
    
    -- Initialize menu
    UIDropDownMenu_Initialize(dropdown, function(self, level)
        local info = UIDropDownMenu_CreateInfo()
        
        for _, option in ipairs(options) do
            info.text = option.text
            info.value = option.value
            info.func = function(self)
                UIDropDownMenu_SetText(dropdown, self.value)
                
                if dropdown.callback then
                    dropdown.callback(self.value)
                end
            end
            
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    
    -- Store label reference
    dropdown.label = dropdownLabel
    
    return dropdown
end

-- Show import/export dialog
function AdvancedSettingsUI:ShowImportExportDialog()
    -- Create dialog frame if it doesn't exist
    if not self.importExportFrame then
        local dialog = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
        dialog:SetSize(500, 400)
        dialog:SetPoint("CENTER")
        dialog:SetFrameStrata("DIALOG")
        dialog:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true,
            tileSize = 32,
            edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 }
        })
        dialog:EnableMouse(true)
        dialog:SetMovable(true)
        dialog:RegisterForDrag("LeftButton")
        dialog:SetScript("OnDragStart", function(self) self:StartMoving() end)
        dialog:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
        dialog:SetClampedToScreen(true)
        
        -- Header
        local header = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        header:SetPoint("TOP", dialog, "TOP", 0, -20)
        header:SetText("Import/Export Settings")
        
        -- Close button
        local closeButton = CreateFrame("Button", nil, dialog, "UIPanelCloseButton")
        closeButton:SetPoint("TOPRIGHT", dialog, "TOPRIGHT", -5, -5)
        
        -- Import/Export tabs
        local importButton = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
        importButton:SetSize(100, 25)
        importButton:SetPoint("TOPLEFT", dialog, "TOPLEFT", 20, -50)
        importButton:SetText("Import")
        
        local exportButton = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
        exportButton:SetSize(100, 25)
        exportButton:SetPoint("LEFT", importButton, "RIGHT", 10, 0)
        exportButton:SetText("Export")
        
        -- Text area
        local scrollFrame = CreateFrame("ScrollFrame", nil, dialog, "UIPanelScrollFrameTemplate")
        scrollFrame:SetSize(450, 250)
        scrollFrame:SetPoint("TOP", header, "BOTTOM", 0, -60)
        
        local editBox = CreateFrame("EditBox", nil, scrollFrame)
        editBox:SetMultiLine(true)
        editBox:SetFontObject(ChatFontNormal)
        editBox:SetWidth(450)
        editBox:SetAutoFocus(false)
        editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
        
        scrollFrame:SetScrollChild(editBox)
        
        -- Import/Export buttons
        local actionButton = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
        actionButton:SetSize(120, 25)
        actionButton:SetPoint("BOTTOM", dialog, "BOTTOM", 0, 20)
        actionButton:SetText("Import")
        
        -- Default to export mode
        local currentMode = "export"
        actionButton:SetText("Copy String")
        
        -- Set up tab functionality
        importButton:SetScript("OnClick", function()
            currentMode = "import"
            actionButton:SetText("Import")
            editBox:SetText("")
            editBox:SetFocus()
        end)
        
        exportButton:SetScript("OnClick", function()
            currentMode = "export"
            actionButton:SetText("Copy String")
            
            -- Generate export string
            local exportString = self:ExportSettings()
            editBox:SetText(exportString)
            editBox:SetFocus()
            editBox:HighlightText()
        end)
        
        -- Set up action button
        actionButton:SetScript("OnClick", function()
            if currentMode == "export" then
                -- Copy to clipboard
                editBox:SetFocus()
                editBox:HighlightText()
            else
                -- Import settings
                local importString = editBox:GetText()
                local success = self:ImportSettings(importString)
                
                if success then
                    dialog:Hide()
                    -- Refresh UI
                    self:SelectTab(currentTab)
                else
                    -- Show error
                    editBox:SetText("Error: Invalid import string. Please check the format and try again.")
                    editBox:SetFocus()
                    editBox:HighlightText()
                end
            end
        end)
        
        -- Store references
        self.importExportFrame = dialog
        self.importExportEditBox = editBox
        self.importExportActionButton = actionButton
        self.importButton = importButton
        self.exportButton = exportButton
    end
    
    -- Show dialog in export mode by default
    self.exportButton:Click()
    self.importExportFrame:Show()
}

-- Export settings to string
function AdvancedSettingsUI:ExportSettings()
    -- Create a copy of the current configuration
    local exportTable = self:DeepCopy(configuration)
    
    -- Convert to string
    local serialized = self:Serialize(exportTable)
    
    -- Compress and encode
    if LibDeflate then
        local compressed = LibDeflate:CompressDeflate(serialized)
        return LibDeflate:EncodeForPrint(compressed)
    else
        -- Fallback to simpler encoding if LibDeflate isn't available
        return self:SimpleEncode(serialized)
    end
end

-- Import settings from string
function AdvancedSettingsUI:ImportSettings(importString)
    if not importString or importString == "" then
        return false
    end
    
    local decoded
    
    -- Decompress and decode
    if LibDeflate then
        local compressed = LibDeflate:DecodeForPrint(importString)
        if not compressed then
            return false
        end
        
        decoded = LibDeflate:DecompressDeflate(compressed)
    else
        -- Fallback to simpler decoding
        decoded = self:SimpleDecode(importString)
    end
    
    if not decoded then
        return false
    end
    
    -- Deserialize
    local success, importedSettings = pcall(function() return self:Deserialize(decoded) end)
    
    if not success or type(importedSettings) ~= "table" then
        return false
    end
    
    -- Merge imported settings with defaults to ensure all required fields exist
    self:MergeDefaults(importedSettings, defaultConfiguration)
    
    -- Apply imported settings
    configuration = importedSettings
    
    -- Save configuration
    self:SaveConfiguration()
    
    return true
}

-- Serialize a table to string
function AdvancedSettingsUI:Serialize(t)
    local lua = ""
    local indent = 0
    
    local function doIndent()
        return string.rep("  ", indent)
    end
    
    local function serializeTable(tbl)
        indent = indent + 1
        lua = lua .. "{\n"
        
        for k, v in pairs(tbl) do
            lua = lua .. doIndent()
            
            if type(k) == "number" then
                lua = lua .. "[" .. k .. "] = "
            elseif type(k) == "string" then
                lua = lua .. "[\"" .. k .. "\"] = "
            end
            
            if type(v) == "table" then
                serializeTable(v)
            elseif type(v) == "string" then
                lua = lua .. "\"" .. v:gsub("\\", "\\\\"):gsub("\"", "\\\"") .. "\""
            elseif type(v) == "number" or type(v) == "boolean" then
                lua = lua .. tostring(v)
            else
                lua = lua .. "nil"
            end
            
            lua = lua .. ",\n"
        end
        
        indent = indent - 1
        lua = lua .. doIndent() .. "}"
    end
    
    serializeTable(t)
    return lua
}

-- Deserialize a string to table
function AdvancedSettingsUI:Deserialize(str)
    local func, err = loadstring("return " .. str)
    if not func then
        return nil
    end
    
    setfenv(func, {})
    return func()
}

-- Simple encode for fallback
function AdvancedSettingsUI:SimpleEncode(str)
    return str:gsub(".", function(c)
        return string.format("%02x", string.byte(c))
    end)
end

-- Simple decode for fallback
function AdvancedSettingsUI:SimpleDecode(str)
    return str:gsub("(%x%x)", function(hex)
        return string.char(tonumber(hex, 16))
    end)
end

-- Reset tab settings to defaults
function AdvancedSettingsUI:ResetTabSettings(tabName)
    if not tabName or not defaultConfiguration[tabName] then
        return
    end
    
    -- Reset configuration for this tab
    configuration[tabName] = self:DeepCopy(defaultConfiguration[tabName])
    
    -- Refresh the tab
    self:SelectTab(tabName)
}

-- Start settings preview
function AdvancedSettingsUI:StartPreview()
    -- Store original settings
    previewOriginalSettings = self:DeepCopy(configuration)
    
    -- Apply current settings to preview
    self:ApplySettingsToModules()
    
    previewActive = true
}

-- End settings preview
function AdvancedSettingsUI:EndPreview(apply)
    if not previewActive then
        return
    end
    
    if not apply and previewOriginalSettings then
        -- Restore original settings
        configuration = self:DeepCopy(previewOriginalSettings)
        
        -- Apply original settings
        self:ApplySettingsToModules()
    end
    
    previewOriginalSettings = nil
    previewActive = false
}

-- Toggle edit mode
function AdvancedSettingsUI:ToggleEditMode(enable)
    if enable then
        -- Enable edit mode
        print("Edit mode enabled. Drag UI elements to reposition them.")
        
        -- Make all Windrunner frames draggable
        if WR.UI and WR.UI.ClassSpecificUI then
            WR.UI.ClassSpecificUI:SetLocked(false)
        end
        
        if WR.UI and WR.UI.ResourceForecast then
            WR.UI.ResourceForecast:SetLocked(false)
        end
    else
        -- Disable edit mode
        print("Edit mode disabled. UI element positions saved.")
        
        -- Lock all frames
        if WR.UI and WR.UI.ClassSpecificUI then
            WR.UI.ClassSpecificUI:SetLocked(true)
        end
        
        if WR.UI and WR.UI.ResourceForecast then
            WR.UI.ResourceForecast:SetLocked(true)
        end
    end
}

-- Deep copy a table
function AdvancedSettingsUI:DeepCopy(src)
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

-- Toggle visibility
function AdvancedSettingsUI:Toggle()
    if self.frame:IsShown() then
        self.frame:Hide()
        
        if previewActive then
            self:EndPreview(false) -- Discard changes
        end
    else
        self.frame:Show()
    end
}

-- Register with main addon
function AdvancedSettingsUI:RegisterWithAddon()
    -- Add to main UI
    if WR.UI and WR.UI.AddButton then
        WR.UI:AddButton("Settings", function()
            self:Toggle()
        end)
    end
    
    -- Register slash command
    if WR.RegisterSlashCommand then
        WR.RegisterSlashCommand("settings", function(msg)
            self:HandleSlashCommand(msg)
        end)
    end
}

-- Handle slash command
function AdvancedSettingsUI:HandleSlashCommand(msg)
    if not msg or msg == "" then
        self:Toggle()
        return
    end
    
    local command, param = msg:match("^(%S+)%s*(.*)$")
    if not command then
        self:Toggle()
        return
    end
    
    command = command:lower()
    
    if command == "reset" then
        -- Reset all settings
        StaticPopupDialogs["WR_RESET_ALL_CONFIRM"] = {
            text = "Are you sure you want to reset ALL settings to default? This cannot be undone.",
            button1 = "Yes",
            button2 = "No",
            OnAccept = function()
                configuration = self:DeepCopy(defaultConfiguration)
                self:SaveConfiguration()
                
                print("All settings have been reset to defaults.")
                
                -- Refresh current tab if settings are open
                if self.frame:IsShown() and currentTab then
                    self:SelectTab(currentTab)
                end
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        }
        StaticPopup_Show("WR_RESET_ALL_CONFIRM")
    elseif command == "export" then
        -- Show export dialog
        self.importExportFrame = nil -- Force recreation
        self:ShowImportExportDialog()
        self.exportButton:Click()
    elseif command == "import" then
        -- Show import dialog
        self.importExportFrame = nil -- Force recreation
        self:ShowImportExportDialog()
        self.importButton:Click()
    elseif command == "edit" then
        -- Toggle edit mode
        editModeActive = not editModeActive
        self:ToggleEditMode(editModeActive)
    else
        -- Open specific tab
        self:Toggle()
        
        -- Try to match tab name
        for name, _ in pairs(tabFrames) do
            if name:lower() == command:lower() then
                self:SelectTab(name)
                return
            end
        end
    end
end

-- Initialize module
AdvancedSettingsUI:Initialize()

return AdvancedSettingsUI