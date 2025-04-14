------------------------------------------
-- WindrunnerRotations - Enhanced Configuration UI
-- Author: VortexQ8
-- The War Within Season 2
------------------------------------------

local addonName, WR = ...
local EnhancedConfigUI = {}
WR.EnhancedConfigUI = EnhancedConfigUI

-- Dependencies
local API = WR.API
local ConfigRegistry = WR.ConfigRegistry
local ModuleManager = WR.ModuleManager

-- UI elements
local configFrame = nil
local classButtons = {}
local specTabs = {}
local settingsSections = {}
local activeClassID = nil
local activeSpecID = nil
local statusBar = nil
local tabFrames = {}
local headerFont = nil
local normalFont = nil
local smallFont = nil
local backdropTemplate = nil

-- Constants
local WINDOW_WIDTH = 650
local WINDOW_HEIGHT = 500
local CLASS_BUTTON_SIZE = 40
local SECTION_PADDING = 10
local ELEMENT_SPACING = 8
local HEADER_HEIGHT = 24

-- Enhanced UI sections
local sectionModules = {
    "general",
    "cooldowns",
    "defensives",
    "rotation",
    "machine_learning",
    "combat_analysis",
    "boss_strategies",
    "player_skill"
}

-- Color scheme
local COLORS = {
    BACKGROUND = {0.1, 0.1, 0.1, 0.95},
    HEADER = {0.12, 0.12, 0.14, 0.95},
    BORDER = {0.5, 0.5, 0.5, 0.8},
    ACCENT = {0.4, 0.6, 0.9, 1.0}, -- Windrunner blue
    TEXT = {1.0, 1.0, 1.0, 1.0},
    TEXT_DISABLED = {0.5, 0.5, 0.5, 1.0},
    HIGHLIGHT = {0.4, 0.6, 0.9, 0.3}, -- Highlight with windrunner blue
    ERROR = {0.9, 0.3, 0.3, 1.0}
}

-- Class colors
local CLASS_COLORS = {
    [1] = {0.78, 0.61, 0.43}, -- Warrior
    [2] = {0.96, 0.55, 0.73}, -- Paladin
    [3] = {0.67, 0.83, 0.45}, -- Hunter
    [4] = {1.00, 0.96, 0.41}, -- Rogue
    [5] = {1.00, 1.00, 1.00}, -- Priest
    [6] = {0.77, 0.12, 0.23}, -- Death Knight
    [7] = {0.00, 0.44, 0.87}, -- Shaman
    [8] = {0.41, 0.80, 0.94}, -- Mage
    [9] = {0.58, 0.51, 0.79}, -- Warlock
    [10] = {0.00, 1.00, 0.59}, -- Monk
    [11] = {1.00, 0.49, 0.04}, -- Druid
    [12] = {0.64, 0.19, 0.79}, -- Demon Hunter
    [13] = {0.20, 0.58, 0.50}  -- Evoker
}

-- Initialize the Enhanced Configuration UI
function EnhancedConfigUI:Initialize()
    -- Register slash command
    SLASH_WRUI1 = "/wrui"
    SLASH_WRUI2 = "/wr"
    SlashCmdList["WRUI"] = function(msg)
        self:HandleSlashCommand(msg)
    end
    
    -- Create backdrop template
    backdropTemplate = {
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        tile = true,
        tileSize = 16,
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    }
    
    -- Create fonts
    headerFont = CreateFont("WindrunnerHeaderFont")
    headerFont:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    headerFont:SetTextColor(1, 1, 1, 1)
    
    normalFont = CreateFont("WindrunnerNormalFont")
    normalFont:SetFont("Fonts\\FRIZQT__.TTF", 12)
    normalFont:SetTextColor(1, 1, 1, 1)
    
    smallFont = CreateFont("WindrunnerSmallFont")
    smallFont:SetFont("Fonts\\FRIZQT__.TTF", 10)
    smallFont:SetTextColor(0.9, 0.9, 0.9, 1)
    
    -- Create UI elements
    self:CreateMainFrame()
    
    API.PrintDebug("Enhanced Configuration UI initialized")
    return true
end

-- Create the main configuration frame
function EnhancedConfigUI:CreateMainFrame()
    -- Create the main frame
    configFrame = CreateFrame("Frame", "WindrunnerConfigFrame", UIParent, "BackdropTemplate")
    configFrame:SetSize(WINDOW_WIDTH, WINDOW_HEIGHT)
    configFrame:SetPoint("CENTER", 0, 0)
    configFrame:SetBackdrop(backdropTemplate)
    configFrame:SetBackdropColor(unpack(COLORS.BACKGROUND))
    configFrame:SetBackdropBorderColor(unpack(COLORS.BORDER))
    configFrame:SetFrameStrata("HIGH")
    configFrame:SetClampedToScreen(true)
    configFrame:EnableMouse(true)
    configFrame:SetMovable(true)
    configFrame:RegisterForDrag("LeftButton")
    configFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    configFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    configFrame:Hide()
    
    -- Add title bar
    local titleBar = CreateFrame("Frame", nil, configFrame, "BackdropTemplate")
    titleBar:SetPoint("TOPLEFT", 0, 0)
    titleBar:SetPoint("TOPRIGHT", 0, 0)
    titleBar:SetHeight(30)
    titleBar:SetBackdrop(backdropTemplate)
    titleBar:SetBackdropColor(unpack(COLORS.HEADER))
    titleBar:SetBackdropBorderColor(unpack(COLORS.BORDER))
    
    -- Add title
    local title = titleBar:CreateFontString(nil, "OVERLAY")
    title:SetFont(headerFont:GetFont())
    title:SetPoint("LEFT", titleBar, "LEFT", 10, 0)
    title:SetText("WindrunnerRotations")
    
    -- Add close button
    local closeButton = CreateFrame("Button", nil, titleBar, "UIPanelCloseButton")
    closeButton:SetPoint("RIGHT", titleBar, "RIGHT", -5, 0)
    closeButton:SetSize(20, 20)
    closeButton:SetScript("OnClick", function() configFrame:Hide() end)
    
    -- Add version text
    local versionText = titleBar:CreateFontString(nil, "OVERLAY")
    versionText:SetFont(smallFont:GetFont())
    versionText:SetPoint("RIGHT", closeButton, "LEFT", -5, 0)
    versionText:SetText("v1.0.0")
    
    -- Create class selection sidebar
    self:CreateClassSelectionSidebar()
    
    -- Create spec tabs
    self:CreateSpecTabs()
    
    -- Create settings area
    self:CreateSettingsArea()
    
    -- Create status bar
    self:CreateStatusBar()
end

-- Create class selection sidebar
function EnhancedConfigUI:CreateClassSelectionSidebar()
    -- Create sidebar frame
    local sidebar = CreateFrame("Frame", nil, configFrame, "BackdropTemplate")
    sidebar:SetWidth(CLASS_BUTTON_SIZE + 15)
    sidebar:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 1, -30)
    sidebar:SetPoint("BOTTOMLEFT", configFrame, "BOTTOMLEFT", 1, 1)
    sidebar:SetBackdrop(backdropTemplate)
    sidebar:SetBackdropColor(unpack(COLORS.HEADER))
    sidebar:SetBackdropBorderColor(0, 0, 0, 0)
    
    -- Create class buttons
    local classIDs = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13}
    local classNames = {
        "Warrior", "Paladin", "Hunter", "Rogue", "Priest",
        "Death Knight", "Shaman", "Mage", "Warlock", "Monk",
        "Druid", "Demon Hunter", "Evoker"
    }
    
    for i, classID in ipairs(classIDs) do
        -- Create button
        local button = CreateFrame("Button", nil, sidebar, "BackdropTemplate")
        button:SetSize(CLASS_BUTTON_SIZE, CLASS_BUTTON_SIZE)
        button:SetPoint("TOP", sidebar, "TOP", 0, -10 - (i-1) * (CLASS_BUTTON_SIZE + 5))
        button:SetBackdrop(backdropTemplate)
        button:SetBackdropColor(0.15, 0.15, 0.15, 0.8)
        button:SetBackdropBorderColor(0, 0, 0, 0)
        
        -- Add class icon
        local icon = button:CreateTexture(nil, "ARTWORK")
        icon:SetAllPoints()
        icon:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES")
        
        -- Set class icon texture coordinates
        local coords = CLASS_ICON_TCOORDS[classNames[i]:upper()]
        if coords then
            icon:SetTexCoord(unpack(coords))
        end
        
        -- Add highlight
        local highlight = button:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetAllPoints()
        highlight:SetTexture("Interface\\Buttons\\CheckButtonHilight")
        highlight:SetBlendMode("ADD")
        highlight:SetAlpha(0.6)
        
        -- Add class color border on active
        button:SetScript("OnClick", function()
            self:SelectClass(classID)
        end)
        
        classButtons[classID] = button
    end
end

-- Create spec tabs
function EnhancedConfigUI:CreateSpecTabs()
    -- Create tab area
    local tabArea = CreateFrame("Frame", nil, configFrame, "BackdropTemplate")
    tabArea:SetPoint("TOPLEFT", configFrame, "TOPLEFT", CLASS_BUTTON_SIZE + 15, -30)
    tabArea:SetPoint("TOPRIGHT", configFrame, "TOPRIGHT", -1, -30)
    tabArea:SetHeight(30)
    tabArea:SetBackdrop(backdropTemplate)
    tabArea:SetBackdropColor(unpack(COLORS.HEADER))
    tabArea:SetBackdropBorderColor(0, 0, 0, 0)
    
    -- Tab frames will be created dynamically when a class is selected
    specTabs = {}
end

-- Create settings area
function EnhancedConfigUI:CreateSettingsArea()
    -- Create settings area
    local settingsArea = CreateFrame("Frame", nil, configFrame, "BackdropTemplate")
    settingsArea:SetPoint("TOPLEFT", configFrame, "TOPLEFT", CLASS_BUTTON_SIZE + 15, -60)
    settingsArea:SetPoint("BOTTOMRIGHT", configFrame, "BOTTOMRIGHT", -1, 20)
    settingsArea:SetBackdrop(backdropTemplate)
    settingsArea:SetBackdropColor(unpack(COLORS.BACKGROUND))
    settingsArea:SetBackdropBorderColor(0, 0, 0, 0)
    
    -- Create scroll frame for settings
    local scrollFrame = CreateFrame("ScrollFrame", "WindrunnerScrollFrame", settingsArea, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", settingsArea, "TOPLEFT", 5, -5)
    scrollFrame:SetPoint("BOTTOMRIGHT", settingsArea, "BOTTOMRIGHT", -25, 5)
    
    -- Create content frame
    local contentFrame = CreateFrame("Frame", nil, scrollFrame)
    contentFrame:SetSize(scrollFrame:GetWidth(), 1000) -- Height will adjust dynamically
    scrollFrame:SetScrollChild(contentFrame)
    
    -- Store reference
    configFrame.settingsArea = settingsArea
    configFrame.contentFrame = contentFrame
end

-- Create status bar
function EnhancedConfigUI:CreateStatusBar()
    -- Create status bar
    statusBar = CreateFrame("Frame", nil, configFrame, "BackdropTemplate")
    statusBar:SetPoint("BOTTOMLEFT", configFrame, "BOTTOMLEFT", 1, 1)
    statusBar:SetPoint("BOTTOMRIGHT", configFrame, "BOTTOMRIGHT", -1, 1)
    statusBar:SetHeight(20)
    statusBar:SetBackdrop(backdropTemplate)
    statusBar:SetBackdropColor(unpack(COLORS.HEADER))
    statusBar:SetBackdropBorderColor(0, 0, 0, 0)
    
    -- Add status text
    local statusText = statusBar:CreateFontString(nil, "OVERLAY")
    statusText:SetFont(smallFont:GetFont())
    statusText:SetPoint("LEFT", statusBar, "LEFT", 10, 0)
    statusText:SetText("Status: Ready")
    
    -- Add toggle button
    local toggleButton = CreateFrame("Button", nil, statusBar, "BackdropTemplate")
    toggleButton:SetSize(80, 16)
    toggleButton:SetPoint("RIGHT", statusBar, "RIGHT", -10, 0)
    toggleButton:SetBackdrop(backdropTemplate)
    toggleButton:SetBackdropColor(0.2, 0.2, 0.2, 0.8)
    toggleButton:SetBackdropBorderColor(unpack(COLORS.BORDER))
    
    local toggleText = toggleButton:CreateFontString(nil, "OVERLAY")
    toggleText:SetFont(smallFont:GetFont())
    toggleText:SetPoint("CENTER", toggleButton, "CENTER", 0, 0)
    toggleText:SetText("Enabled")
    
    local isEnabled = true
    toggleButton:SetScript("OnClick", function()
        isEnabled = not isEnabled
        toggleText:SetText(isEnabled and "Enabled" or "Disabled")
        
        -- Set color based on state
        if isEnabled then
            toggleButton:SetBackdropColor(0.2, 0.6, 0.2, 0.8)
            toggleText:SetTextColor(0.8, 1.0, 0.8, 1.0)
        else
            toggleButton:SetBackdropColor(0.6, 0.2, 0.2, 0.8)
            toggleText:SetTextColor(1.0, 0.8, 0.8, 1.0)
        end
        
        -- Call toggle function if it exists
        if WR.ToggleRotation then
            WR.ToggleRotation(isEnabled)
        end
    end)
    
    -- Set initial color
    toggleButton:SetBackdropColor(0.2, 0.6, 0.2, 0.8)
    toggleText:SetTextColor(0.8, 1.0, 0.8, 1.0)
    
    -- Store references
    statusBar.statusText = statusText
    statusBar.toggleButton = toggleButton
end

-- Select a class
function EnhancedConfigUI:SelectClass(classID)
    -- Highlight the selected class
    for id, button in pairs(classButtons) do
        local color
        local borderWidth = 1
        
        if id == classID then
            -- Selected class - use class color
            color = CLASS_COLORS[id] or COLORS.ACCENT
            borderWidth = 2
            activeClassID = classID
        else
            -- Unselected - use default border
            color = COLORS.BORDER
        end
        
        button:SetBackdropBorderColor(color[1], color[2], color[3], 1.0)
        button:SetBackdropBorderColor(unpack(color))
    end
    
    -- Create spec tabs for this class
    self:CreateSpecTabsForClass(classID)
    
    -- Select the first spec
    local firstSpecID = self:GetSpecsForClass(classID)[1]
    if firstSpecID then
        self:SelectSpec(firstSpecID)
    end
end

-- Create spec tabs for a class
function EnhancedConfigUI:CreateSpecTabsForClass(classID)
    -- Clear existing tabs
    for _, tab in pairs(specTabs) do
        tab:Hide()
    end
    specTabs = {}
    
    -- Get specs for this class
    local specs = self:GetSpecsForClass(classID)
    
    -- Create tab for each spec
    local tabWidth = (WINDOW_WIDTH - CLASS_BUTTON_SIZE - 15) / #specs
    for i, specID in ipairs(specs) do
        local specName = self:GetSpecName(classID, specID)
        
        -- Create tab
        local tab = CreateFrame("Button", nil, configFrame, "BackdropTemplate")
        tab:SetSize(tabWidth, 30)
        tab:SetPoint("TOPLEFT", configFrame, "TOPLEFT", CLASS_BUTTON_SIZE + 15 + (i-1) * tabWidth, -30)
        tab:SetBackdrop(backdropTemplate)
        tab:SetBackdropColor(0.15, 0.15, 0.15, 0.8)
        tab:SetBackdropBorderColor(0, 0, 0, 0)
        
        -- Add spec name
        local text = tab:CreateFontString(nil, "OVERLAY")
        text:SetFont(normalFont:GetFont())
        text:SetPoint("CENTER", tab, "CENTER", 0, 0)
        text:SetText(specName)
        
        -- Add spec icon
        local icon = tab:CreateTexture(nil, "ARTWORK")
        icon:SetSize(16, 16)
        icon:SetPoint("LEFT", tab, "LEFT", 5, 0)
        
        -- Set spec icon
        icon:SetTexture(self:GetSpecIcon(classID, specID))
        
        -- Add highlight
        local highlight = tab:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetAllPoints()
        highlight:SetTexture("Interface\\Buttons\\UI-Silver-Button-Select")
        highlight:SetBlendMode("ADD")
        highlight:SetAlpha(0.5)
        
        -- Add click handler
        tab:SetScript("OnClick", function()
            self:SelectSpec(specID)
        end)
        
        -- Store reference
        specTabs[specID] = tab
    end
end

-- Select a spec
function EnhancedConfigUI:SelectSpec(specID)
    -- Highlight the selected spec
    for id, tab in pairs(specTabs) do
        if id == specID then
            -- Selected spec
            tab:SetBackdropColor(unpack(COLORS.ACCENT))
            tab:GetFontString():SetTextColor(1, 1, 1, 1)
            activeSpecID = specID
        else
            -- Unselected
            tab:SetBackdropColor(0.15, 0.15, 0.15, 0.8)
            tab:GetFontString():SetTextColor(0.8, 0.8, 0.8, 1)
        end
    end
    
    -- Create settings for this spec
    self:CreateSettingsForSpec(activeClassID, specID)
end

-- Create settings for a spec
function EnhancedConfigUI:CreateSettingsForSpec(classID, specID)
    local contentFrame = configFrame.contentFrame
    
    -- Clear content frame
    for _, frame in pairs(settingsSections) do
        frame:Hide()
    end
    settingsSections = {}
    
    -- Initialize height tracking
    local yOffset = 0
    
    -- Create main sections
    for _, module in ipairs(sectionModules) do
        local section = self:CreateSection(contentFrame, self:GetSectionName(module), module)
        section:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 0, -yOffset)
        section:SetPoint("TOPRIGHT", contentFrame, "TOPRIGHT", 0, -yOffset)
        
        -- Add content based on module
        self:PopulateSectionContent(section, module, classID, specID)
        
        -- Update offset for next section
        yOffset = yOffset + section:GetHeight() + SECTION_PADDING
        
        -- Store reference
        settingsSections[module] = section
    end
    
    -- Update content frame height
    contentFrame:SetHeight(yOffset)
end

-- Create a collapsible section
function EnhancedConfigUI:CreateSection(parent, title, key)
    local section = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    section:SetSize(parent:GetWidth() - 10, 30) -- Initial height, will expand
    section:SetBackdrop(backdropTemplate)
    section:SetBackdropColor(unpack(COLORS.HEADER))
    section:SetBackdropBorderColor(unpack(COLORS.BORDER))
    
    -- Add header
    local header = CreateFrame("Button", nil, section)
    header:SetPoint("TOPLEFT", section, "TOPLEFT", 0, 0)
    header:SetPoint("TOPRIGHT", section, "TOPRIGHT", 0, 0)
    header:SetHeight(HEADER_HEIGHT)
    
    -- Add title text
    local titleText = header:CreateFontString(nil, "OVERLAY")
    titleText:SetFont(headerFont:GetFont())
    titleText:SetPoint("LEFT", header, "LEFT", 10, 0)
    titleText:SetText(title)
    
    -- Add collapse/expand indicator
    local indicator = header:CreateFontString(nil, "OVERLAY")
    indicator:SetFont(normalFont:GetFont())
    indicator:SetPoint("RIGHT", header, "RIGHT", -10, 0)
    indicator:SetText("+")
    
    -- Add content area
    local content = CreateFrame("Frame", nil, section)
    content:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, 0)
    content:SetPoint("TOPRIGHT", header, "BOTTOMRIGHT", 0, 0)
    content:SetHeight(10) -- Will be adjusted when populated
    
    -- Toggle collapse/expand
    local isCollapsed = false
    header:SetScript("OnClick", function()
        isCollapsed = not isCollapsed
        
        if isCollapsed then
            content:Hide()
            indicator:SetText("+")
            section:SetHeight(HEADER_HEIGHT)
        else
            content:Show()
            indicator:SetText("-")
            section:SetHeight(HEADER_HEIGHT + content:GetHeight())
        end
    end)
    
    -- Store references
    section.header = header
    section.content = content
    section.isCollapsed = isCollapsed
    section.key = key
    
    return section
end

-- Populate a section with content
function EnhancedConfigUI:PopulateSectionContent(section, module, classID, specID)
    local content = section.content
    
    -- Track height for dynamic sizing
    local contentHeight = 10 -- Initial padding
    
    -- Add different controls based on module
    if module == "general" then
        -- General settings
        contentHeight = contentHeight + self:AddGeneralSettings(content, contentHeight)
    elseif module == "cooldowns" then
        -- Cooldown settings
        contentHeight = contentHeight + self:AddCooldownSettings(content, contentHeight, classID, specID)
    elseif module == "defensives" then
        -- Defensive settings
        contentHeight = contentHeight + self:AddDefensiveSettings(content, contentHeight, classID, specID)
    elseif module == "rotation" then
        -- Rotation settings
        contentHeight = contentHeight + self:AddRotationSettings(content, contentHeight, classID, specID)
    elseif module == "machine_learning" then
        -- Machine Learning settings
        contentHeight = contentHeight + self:AddMachineLearningSettings(content, contentHeight)
    elseif module == "combat_analysis" then
        -- Combat Analysis settings
        contentHeight = contentHeight + self:AddCombatAnalysisSettings(content, contentHeight)
    elseif module == "boss_strategies" then
        -- Boss Strategies settings
        contentHeight = contentHeight + self:AddBossStrategiesSettings(content, contentHeight)
    elseif module == "player_skill" then
        -- Player Skill settings
        contentHeight = contentHeight + self:AddPlayerSkillSettings(content, contentHeight)
    end
    
    -- Update content height
    content:SetHeight(contentHeight)
    
    -- Update section height
    if not section.isCollapsed then
        section:SetHeight(HEADER_HEIGHT + contentHeight)
    end
end

-- Add general settings
function EnhancedConfigUI:AddGeneralSettings(parent, yOffset)
    local height = 0
    
    -- Add global enable checkbox
    height = height + self:AddCheckbox(parent, "Enable WindrunnerRotations", "enableAddon", true, yOffset + height)
    
    -- Add global cooldown detection
    height = height + self:AddCheckbox(parent, "Use Global Cooldown Detection", "useGCD", true, yOffset + height)
    
    -- Add multithreading toggle
    height = height + self:AddCheckbox(parent, "Use Advanced Optimization", "useOptimization", true, yOffset + height)
    
    -- Add latency compensation slider
    height = height + self:AddSlider(parent, "Latency Compensation", "latencyCompensation", 0, 400, 50, 100, "ms", yOffset + height)
    
    -- Add toggle key dropdown
    local toggleOptions = {"Left Alt", "Right Alt", "Left Control", "Right Control", "Left Shift", "Right Shift", "None"}
    height = height + self:AddDropdown(parent, "Toggle Key", "toggleKey", toggleOptions, 7, yOffset + height)
    
    return height
end

-- Add cooldown settings
function EnhancedConfigUI:AddCooldownSettings(parent, yOffset, classID, specID)
    local height = 0
    
    -- Add cooldown usage mode
    local usageOptions = {"On Cooldown", "With Conditions", "Manual Only", "Bosses Only"}
    height = height + self:AddDropdown(parent, "Cooldown Usage", "cooldownUsage", usageOptions, 2, yOffset + height)
    
    -- Add cooldown overlap checkbox
    height = height + self:AddCheckbox(parent, "Allow Cooldown Overlap", "allowCooldownOverlap", true, yOffset + height)
    
    -- Add class-specific cooldowns
    local cooldowns = self:GetClassCooldowns(classID, specID)
    for _, cooldown in ipairs(cooldowns) do
        height = height + self:AddCheckbox(parent, cooldown.name, "cooldown_" .. cooldown.id, cooldown.defaultEnabled, yOffset + height)
    end
    
    -- Add cooldown threshold slider
    height = height + self:AddSlider(parent, "Boss Health Threshold", "cooldownThreshold", 0, 100, 5, 30, "%", yOffset + height)
    
    return height
end

-- Add defensive settings
function EnhancedConfigUI:AddDefensiveSettings(parent, yOffset, classID, specID)
    local height = 0
    
    -- Add defensive usage mode
    local usageOptions = {"Automatic", "Dangerous Only", "Manual Only"}
    height = height + self:AddDropdown(parent, "Defensive Usage", "defensiveUsage", usageOptions, 1, yOffset + height)
    
    -- Add health threshold slider
    height = height + self:AddSlider(parent, "Health Threshold", "healthThreshold", 0, 100, 5, 40, "%", yOffset + height)
    
    -- Add class-specific defensives
    local defensives = self:GetClassDefensives(classID, specID)
    for _, defensive in ipairs(defensives) do
        height = height + self:AddCheckbox(parent, defensive.name, "defensive_" .. defensive.id, defensive.defaultEnabled, yOffset + height)
    end
    
    return height
end

-- Add rotation settings
function EnhancedConfigUI:AddRotationSettings(parent, yOffset, classID, specID)
    local height = 0
    
    -- Add AoE mode dropdown
    local aoeOptions = {"Automatic", "Single Target", "AoE", "Cleave"}
    height = height + self:AddDropdown(parent, "AoE Mode", "aoeMode", aoeOptions, 1, yOffset + height)
    
    -- Add AoE threshold slider
    height = height + self:AddSlider(parent, "AoE Threshold", "aoeThreshold", 2, 10, 1, 3, "targets", yOffset + height)
    
    -- Add class/spec specific settings
    height = height + self:AddClassSpecificSettings(parent, yOffset + height, classID, specID)
    
    -- Add APL mode checkbox
    height = height + self:AddCheckbox(parent, "Use Action Priority List", "useAPL", true, yOffset + height)
    
    -- If APL is used, add APL editor button
    height = height + self:AddButton(parent, "Open APL Editor", function() self:OpenAPLEditor() end, yOffset + height)
    
    return height
end

-- Add class-specific settings
function EnhancedConfigUI:AddClassSpecificSettings(parent, yOffset, classID, specID)
    local height = 0
    
    -- Get class-specific settings
    local settings = self:GetClassSpecificSettings(classID, specID)
    
    -- Add each setting
    for _, setting in ipairs(settings) do
        if setting.type == "checkbox" then
            height = height + self:AddCheckbox(parent, setting.name, setting.key, setting.default, yOffset + height)
        elseif setting.type == "slider" then
            height = height + self:AddSlider(parent, setting.name, setting.key, setting.min, setting.max, setting.step, setting.default, setting.suffix, yOffset + height)
        elseif setting.type == "dropdown" then
            height = height + self:AddDropdown(parent, setting.name, setting.key, setting.options, setting.default, yOffset + height)
        end
    end
    
    return height
end

-- Add Machine Learning settings
function EnhancedConfigUI:AddMachineLearningSettings(parent, yOffset)
    local height = 0
    
    -- Add ML enable checkbox
    height = height + self:AddCheckbox(parent, "Enable Machine Learning", "enableML", true, yOffset + height)
    
    -- Add data collection level
    local collectionOptions = {"Minimal", "Standard", "Extensive"}
    height = height + self:AddDropdown(parent, "Data Collection Level", "dataCollectionLevel", collectionOptions, 2, yOffset + height)
    
    -- Add adaptation rate slider
    height = height + self:AddSlider(parent, "Adaptation Rate", "adaptationRate", 1, 10, 1, 5, "", yOffset + height)
    
    -- Add anonymous data sharing
    height = height + self:AddCheckbox(parent, "Allow Anonymous Data Sharing", "allowDataSharing", false, yOffset + height)
    
    -- Add confidence threshold
    height = height + self:AddSlider(parent, "Minimum Confidence", "confidenceThreshold", 50, 95, 5, 75, "%", yOffset + height)
    
    -- Add ML status display
    local statusText = parent:CreateFontString(nil, "OVERLAY")
    statusText:SetFont(smallFont:GetFont())
    statusText:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, -(yOffset + height))
    statusText:SetText("ML Status: Initializing...")
    height = height + 20
    
    -- Add reset ML data button
    height = height + self:AddButton(parent, "Reset ML Data", function() self:ResetMLData() end, yOffset + height)
    
    return height
end

-- Add Combat Analysis settings
function EnhancedConfigUI:AddCombatAnalysisSettings(parent, yOffset)
    local height = 0
    
    -- Add Combat Analysis enable checkbox
    height = height + self:AddCheckbox(parent, "Enable Combat Analysis", "enableAnalysis", true, yOffset + height)
    
    -- Add analysis detail dropdown
    local detailOptions = {"Basic", "Standard", "Comprehensive"}
    height = height + self:AddDropdown(parent, "Analysis Detail", "analysisDetail", detailOptions, 2, yOffset + height)
    
    -- Add automatic reporting dropdown
    local reportOptions = {"Never", "Major Combat", "All Combat"}
    height = height + self:AddDropdown(parent, "Automatic Reporting", "autoReporting", reportOptions, 2, yOffset + height)
    
    -- Add include options
    height = height + self:AddCheckbox(parent, "Include Rotation Analysis", "includeRotation", true, yOffset + height)
    height = height + self:AddCheckbox(parent, "Include Resource Analysis", "includeResource", true, yOffset + height)
    height = height + self:AddCheckbox(parent, "Include Improvement Suggestions", "includeSuggestions", true, yOffset + height)
    
    -- Add view recent button
    height = height + self:AddButton(parent, "View Recent Reports", function() self:ViewRecentReports() end, yOffset + height)
    
    return height
end

-- Add Boss Strategies settings
function EnhancedConfigUI:AddBossStrategiesSettings(parent, yOffset)
    local height = 0
    
    -- Add Boss Strategies enable checkbox
    height = height + self:AddCheckbox(parent, "Enable Boss Strategies", "enableBossStrats", true, yOffset + height)
    
    -- Add detection dropdown
    local detectionOptions = {"Automatic", "Manual", "Boss Only", "All Encounters"}
    height = height + self:AddDropdown(parent, "Boss Detection", "bossDetection", detectionOptions, 1, yOffset + height)
    
    -- Add strategy priority dropdown
    local priorityOptions = {"Balanced", "Damage", "Survival", "Utility"}
    height = height + self:AddDropdown(parent, "Strategy Priority", "stratPriority", priorityOptions, 1, yOffset + height)
    
    -- Add mechanic detection options
    height = height + self:AddCheckbox(parent, "Enable Mechanic Detection", "enableMechanicDetection", true, yOffset + height)
    height = height + self:AddCheckbox(parent, "Enable Movement Handling", "enableMovementHandling", true, yOffset + height)
    height = height + self:AddCheckbox(parent, "Enable Interrupt Priority", "enableInterruptPriority", true, yOffset + height)
    height = height + self:AddCheckbox(parent, "Enable Cooldown Optimization", "enableCooldownOpt", true, yOffset + height)
    
    -- Add boss strategy browser button
    height = height + self:AddButton(parent, "Browse Boss Strategies", function() self:OpenBossStrategiesBrowser() end, yOffset + height)
    
    return height
end

-- Add Player Skill settings
function EnhancedConfigUI:AddPlayerSkillSettings(parent, yOffset)
    local height = 0
    
    -- Add Player Skill enable checkbox
    height = height + self:AddCheckbox(parent, "Enable Skill Scaling", "enableSkillScaling", true, yOffset + height)
    
    -- Add skill level dropdown
    local skillOptions = {"Beginner", "Novice", "Intermediate", "Advanced", "Expert"}
    height = height + self:AddDropdown(parent, "Skill Level", "skillLevel", skillOptions, 3, yOffset + height)
    
    -- Add adaptation options
    height = height + self:AddCheckbox(parent, "Automatic Skill Assessment", "autoAssessment", true, yOffset + height)
    height = height + self:AddCheckbox(parent, "Allow Skill Progression", "allowProgression", true, yOffset + height)
    
    -- Add tutorial options
    height = height + self:AddCheckbox(parent, "Enable Tutorials", "enableTutorials", true, yOffset + height)
    height = height + self:AddCheckbox(parent, "Show Ability Help", "showAbilityHelp", true, yOffset + height)
    
    -- Add aspect adaptation
    height = height + self:AddCheckbox(parent, "Adapt Cooldown Usage", "adaptCooldowns", true, yOffset + height)
    height = height + self:AddCheckbox(parent, "Adapt Resource Management", "adaptResource", true, yOffset + height)
    height = height + self:AddCheckbox(parent, "Adapt AoE Handling", "adaptAoE", true, yOffset + height)
    
    -- Add skill assessment button
    height = height + self:AddButton(parent, "Perform Skill Assessment", function() self:PerformSkillAssessment() end, yOffset + height)
    
    return height
end

-- Add a checkbox
function EnhancedConfigUI:AddCheckbox(parent, label, key, defaultChecked, yOffset)
    local height = 25
    
    -- Create checkbox
    local checkbox = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    checkbox:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -yOffset)
    checkbox:SetChecked(defaultChecked)
    
    -- Set label
    checkbox.Text:SetText(label)
    checkbox.key = key
    
    -- Set handler
    checkbox:SetScript("OnClick", function(self)
        -- Save setting
        if ConfigRegistry then
            ConfigRegistry:SetSettingValue(key, self:GetChecked())
        end
    end)
    
    return height
end

-- Add a slider
function EnhancedConfigUI:AddSlider(parent, label, key, min, max, step, defaultValue, suffix, yOffset)
    local height = 45
    
    -- Create label
    local text = parent:CreateFontString(nil, "OVERLAY")
    text:SetFont(normalFont:GetFont())
    text:SetPoint("TOPLEFT", parent, "TOPLEFT", 15, -yOffset)
    text:SetText(label)
    
    -- Create slider
    local slider = CreateFrame("Slider", nil, parent, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", parent, "TOPLEFT", 15, -(yOffset + 15))
    slider:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -15, -(yOffset + 15))
    slider:SetMinMaxValues(min, max)
    slider:SetValueStep(step)
    slider:SetValue(defaultValue)
    slider:SetObeyStepOnDrag(true)
    slider.key = key
    
    -- Set labels
    slider.Low:SetText(min)
    slider.High:SetText(max)
    
    -- Create value text
    local valueText = slider:CreateFontString(nil, "OVERLAY")
    valueText:SetFont(smallFont:GetFont())
    valueText:SetPoint("TOP", slider, "BOTTOM", 0, 0)
    valueText:SetText(defaultValue .. (suffix or ""))
    
    -- Set handler
    slider:SetScript("OnValueChanged", function(self, value)
        -- Update text
        valueText:SetText(value .. (suffix or ""))
        
        -- Save setting
        if ConfigRegistry then
            ConfigRegistry:SetSettingValue(key, value)
        end
    end)
    
    return height
end

-- Add a dropdown
function EnhancedConfigUI:AddDropdown(parent, label, key, options, defaultValue, yOffset)
    local height = 45
    
    -- Create label
    local text = parent:CreateFontString(nil, "OVERLAY")
    text:SetFont(normalFont:GetFont())
    text:SetPoint("TOPLEFT", parent, "TOPLEFT", 15, -yOffset)
    text:SetText(label)
    
    -- Create dropdown frame
    local dropdown = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -(yOffset + 15))
    dropdown.key = key
    
    -- Initialize dropdown
    UIDropDownMenu_SetWidth(dropdown, 150)
    UIDropDownMenu_SetText(dropdown, options[defaultValue])
    
    -- Set handler
    UIDropDownMenu_Initialize(dropdown, function(frame, level, menuList)
        local info = UIDropDownMenu_CreateInfo()
        
        for i, option in ipairs(options) do
            info.text = option
            info.value = i
            info.checked = (i == defaultValue)
            info.func = function(self)
                UIDropDownMenu_SetSelectedValue(dropdown, self.value)
                UIDropDownMenu_SetText(dropdown, self.text)
                
                -- Save setting
                if ConfigRegistry then
                    ConfigRegistry:SetSettingValue(key, self.value)
                end
            end
            UIDropDownMenu_AddButton(info)
        end
    end)
    
    return height
end

-- Add a button
function EnhancedConfigUI:AddButton(parent, label, callback, yOffset)
    local height = 30
    
    -- Create button
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", 15, -yOffset)
    button:SetSize(150, 22)
    button:SetText(label)
    
    -- Set handler
    button:SetScript("OnClick", callback)
    
    return height
end

-- Open the main configuration panel
function EnhancedConfigUI:OpenConfigPanel()
    -- Create if it doesn't exist
    if not configFrame then
        self:CreateMainFrame()
    end
    
    -- Show the frame
    configFrame:Show()
    
    -- Select player's class/spec by default
    local playerClass = API.GetPlayerClassID()
    if playerClass then
        self:SelectClass(playerClass)
        
        local playerSpec = API.GetActiveSpecID()
        if playerSpec then
            self:SelectSpec(playerSpec)
        end
    end
end

-- Open configuration for a specific module
function EnhancedConfigUI:OpenConfigForModule(moduleName)
    self:OpenConfigPanel()
    
    -- Expand the section for this module
    for moduleKey, section in pairs(settingsSections) do
        if moduleKey == moduleName then
            -- Expand the section
            section.isCollapsed = true
            section.header:Click()
        end
    end
end

-- Open APL editor
function EnhancedConfigUI:OpenAPLEditor()
    if WR.APLSystem and WR.APLSystem.OpenEditor then
        WR.APLSystem:OpenEditor()
    else
        API.Print("APL Editor is not available")
    end
end

-- Reset ML data
function EnhancedConfigUI:ResetMLData()
    if WR.MachineLearning then
        -- Ask for confirmation
        StaticPopupDialogs["WINDRUNNER_RESET_ML"] = {
            text = "Are you sure you want to reset all machine learning data? This cannot be undone.",
            button1 = "Yes",
            button2 = "No",
            OnAccept = function()
                if WR.MachineLearning.ResetData then
                    WR.MachineLearning:ResetData()
                    API.Print("Machine Learning data has been reset")
                end
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        }
        StaticPopup_Show("WINDRUNNER_RESET_ML")
    end
end

-- View recent reports
function EnhancedConfigUI:ViewRecentReports()
    if WR.CombatAnalysis and WR.CombatAnalysis.ShowRecentReports then
        WR.CombatAnalysis:ShowRecentReports()
    else
        API.Print("Combat Analysis reports are not available")
    end
end

-- Open boss strategies browser
function EnhancedConfigUI:OpenBossStrategiesBrowser()
    if WR.BossStrategies and WR.BossStrategies.OpenBrowser then
        WR.BossStrategies:OpenBrowser()
    else
        API.Print("Boss Strategies browser is not available")
    end
end

-- Perform skill assessment
function EnhancedConfigUI:PerformSkillAssessment()
    if WR.PlayerSkillSystem and WR.PlayerSkillSystem.AssessPlayerSkill then
        -- Perform assessment
        local assessment = WR.PlayerSkillSystem:AssessPlayerSkill()
        
        -- Show results
        if assessment then
            API.Print("Skill Assessment: " .. string.format("%.1f", assessment.overallScore * 100) .. "%")
            API.Print("Skill Level: " .. assessment.skillLevel)
        else
            API.Print("Not enough data for skill assessment")
        end
    else
        API.Print("Skill Assessment is not available")
    end
end

-- Get specs for a class
function EnhancedConfigUI:GetSpecsForClass(classID)
    -- This would return specs based on class ID
    -- For implementation simplicity, we'll use a static mapping
    local specs = {
        [1] = {1, 2, 3}, -- Warrior: Arms, Fury, Protection
        [2] = {1, 2, 3}, -- Paladin: Holy, Protection, Retribution
        [3] = {1, 2, 3}, -- Hunter: Beast Mastery, Marksmanship, Survival
        [4] = {1, 2, 3}, -- Rogue: Assassination, Outlaw, Subtlety
        [5] = {1, 2, 3}, -- Priest: Discipline, Holy, Shadow
        [6] = {1, 2, 3}, -- Death Knight: Blood, Frost, Unholy
        [7] = {1, 2, 3}, -- Shaman: Elemental, Enhancement, Restoration
        [8] = {1, 2, 3}, -- Mage: Arcane, Fire, Frost
        [9] = {1, 2, 3}, -- Warlock: Affliction, Demonology, Destruction
        [10] = {1, 2, 3}, -- Monk: Brewmaster, Mistweaver, Windwalker
        [11] = {1, 2, 3, 4}, -- Druid: Balance, Feral, Guardian, Restoration
        [12] = {1, 2}, -- Demon Hunter: Havoc, Vengeance
        [13] = {1, 2, 3} -- Evoker: Devastation, Preservation, Augmentation
    }
    
    return specs[classID] or {}
end

-- Get spec name
function EnhancedConfigUI:GetSpecName(classID, specID)
    -- This would return spec name based on class ID and spec ID
    -- For implementation simplicity, we'll use a static mapping
    local specNames = {
        [1] = {
            [1] = "Arms",
            [2] = "Fury",
            [3] = "Protection"
        },
        [2] = {
            [1] = "Holy",
            [2] = "Protection",
            [3] = "Retribution"
        },
        [3] = {
            [1] = "Beast Mastery",
            [2] = "Marksmanship",
            [3] = "Survival"
        },
        [4] = {
            [1] = "Assassination",
            [2] = "Outlaw",
            [3] = "Subtlety"
        },
        [5] = {
            [1] = "Discipline",
            [2] = "Holy",
            [3] = "Shadow"
        },
        [6] = {
            [1] = "Blood",
            [2] = "Frost",
            [3] = "Unholy"
        },
        [7] = {
            [1] = "Elemental",
            [2] = "Enhancement",
            [3] = "Restoration"
        },
        [8] = {
            [1] = "Arcane",
            [2] = "Fire",
            [3] = "Frost"
        },
        [9] = {
            [1] = "Affliction",
            [2] = "Demonology",
            [3] = "Destruction"
        },
        [10] = {
            [1] = "Brewmaster",
            [2] = "Mistweaver",
            [3] = "Windwalker"
        },
        [11] = {
            [1] = "Balance",
            [2] = "Feral",
            [3] = "Guardian",
            [4] = "Restoration"
        },
        [12] = {
            [1] = "Havoc",
            [2] = "Vengeance"
        },
        [13] = {
            [1] = "Devastation",
            [2] = "Preservation",
            [3] = "Augmentation"
        }
    }
    
    return specNames[classID] and specNames[classID][specID] or "Unknown"
end

-- Get spec icon
function EnhancedConfigUI:GetSpecIcon(classID, specID)
    -- This would return spec icon based on class ID and spec ID
    -- For implementation simplicity, we'll use a placeholder
    return "Interface\\Icons\\ClassIcon_" .. self:GetSpecName(classID, specID)
end

-- Get section name
function EnhancedConfigUI:GetSectionName(module)
    local names = {
        general = "General Settings",
        cooldowns = "Cooldown Management",
        defensives = "Defensive Abilities",
        rotation = "Rotation Settings",
        machine_learning = "Machine Learning",
        combat_analysis = "Combat Analysis",
        boss_strategies = "Boss Strategies",
        player_skill = "Player Skill System"
    }
    
    return names[module] or module
end

-- Get class cooldowns
function EnhancedConfigUI:GetClassCooldowns(classID, specID)
    -- This would return cooldowns based on class ID and spec ID
    -- For implementation simplicity, we'll use a placeholder
    
    -- For Mage Arcane
    if classID == 8 and specID == 1 then
        return {
            {id = "arcane_power", name = "Arcane Power", defaultEnabled = true},
            {id = "touch_of_the_magi", name = "Touch of the Magi", defaultEnabled = true},
            {id = "radiant_spark", name = "Radiant Spark", defaultEnabled = true},
            {id = "presence_of_mind", name = "Presence of Mind", defaultEnabled = true},
        }
    -- For Evoker Devastation
    elseif classID == 13 and specID == 1 then
        return {
            {id = "dragonrage", name = "Dragonrage", defaultEnabled = true},
            {id = "eternity_surge", name = "Eternity Surge", defaultEnabled = true},
            {id = "fire_breath", name = "Fire Breath", defaultEnabled = true},
        }
    end
    
    -- Default
    return {
        {id = "cooldown1", name = "Major Cooldown 1", defaultEnabled = true},
        {id = "cooldown2", name = "Major Cooldown 2", defaultEnabled = true},
        {id = "cooldown3", name = "Major Cooldown 3", defaultEnabled = false},
    }
end

-- Get class defensives
function EnhancedConfigUI:GetClassDefensives(classID, specID)
    -- This would return defensives based on class ID and spec ID
    -- For implementation simplicity, we'll use a placeholder
    
    -- For Mage
    if classID == 8 then
        return {
            {id = "ice_block", name = "Ice Block", defaultEnabled = true},
            {id = "mirror_image", name = "Mirror Image", defaultEnabled = true},
            {id = "alter_time", name = "Alter Time", defaultEnabled = true},
        }
    -- For Evoker
    elseif classID == 13 then
        return {
            {id = "obsidian_scales", name = "Obsidian Scales", defaultEnabled = true},
            {id = "renewing_blaze", name = "Renewing Blaze", defaultEnabled = true},
            {id = "temporal_anomaly", name = "Temporal Anomaly", defaultEnabled = false},
        }
    end
    
    -- Default
    return {
        {id = "defensive1", name = "Defensive Ability 1", defaultEnabled = true},
        {id = "defensive2", name = "Defensive Ability 2", defaultEnabled = true},
        {id = "defensive3", name = "Defensive Ability 3", defaultEnabled = false},
    }
end

-- Get class-specific settings
function EnhancedConfigUI:GetClassSpecificSettings(classID, specID)
    -- This would return class-specific settings based on class ID and spec ID
    -- For implementation simplicity, we'll use a placeholder
    
    -- For Mage Arcane
    if classID == 8 and specID == 1 then
        return {
            {type = "slider", name = "Mana Burn Threshold", key = "manaBurnThreshold", min = 30, max = 100, step = 5, default = 50, suffix = "%"},
            {type = "slider", name = "Mana Conserve Threshold", key = "manaConserveThreshold", min = 0, max = 50, step = 5, default = 30, suffix = "%"},
            {type = "checkbox", name = "Advanced Mana Management", key = "advancedManaManagement", default = true},
            {type = "checkbox", name = "Use Touch of the Magi on Cooldown", key = "touchOfTheMagiOnCD", default = true},
            {type = "dropdown", name = "Arcane Barrage Strategy", key = "arcaneBarrageStrategy", options = {"Conservative", "Balanced", "Aggressive"}, default = 2},
        }
    -- For Evoker Devastation
    elseif classID == 13 and specID == 1 then
        return {
            {type = "slider", name = "Essence Management Threshold", key = "essenceThreshold", min = 1, max = 6, step = 1, default = 3, suffix = ""},
            {type = "dropdown", name = "Fire Breath Empower Level", key = "fireBreathLevel", options = {"Level 1", "Level 2", "Level 3", "Situational"}, default = 4},
            {type = "checkbox", name = "Optimize for Cleave", key = "optimizeCleave", default = true},
            {type = "checkbox", name = "Use Living Flame as Filler", key = "useLivingFlameFiller", default = true},
        }
    end
    
    -- Default
    return {
        {type = "slider", name = "Resource Threshold", key = "resourceThreshold", min = 0, max = 100, step = 5, default = 50, suffix = "%"},
        {type = "checkbox", name = "Use Advanced Features", key = "useAdvancedFeatures", default = true},
        {type = "dropdown", name = "Rotation Mode", key = "rotationMode", options = {"Conservative", "Balanced", "Aggressive"}, default = 2},
    }
end

-- Handle slash command
function EnhancedConfigUI:HandleSlashCommand(msg)
    if not msg or msg == "" then
        -- Open main config panel
        self:OpenConfigPanel()
        return
    end
    
    local args = {}
    for arg in string.gmatch(msg, "%S+") do
        table.insert(args, arg)
    end
    
    local command = args[1]
    
    if command == "config" or command == "options" then
        -- Open main config panel
        self:OpenConfigPanel()
    elseif command == "ml" or command == "ml" then
        -- Open Machine Learning config
        self:OpenConfigForModule("machine_learning")
    elseif command == "combat" or command == "analysis" then
        -- Open Combat Analysis config
        self:OpenConfigForModule("combat_analysis")
    elseif command == "boss" or command == "strategies" then
        -- Open Boss Strategies config
        self:OpenConfigForModule("boss_strategies")
    elseif command == "skill" then
        -- Open Player Skill config
        self:OpenConfigForModule("player_skill")
    elseif command == "apl" then
        -- Open APL editor
        self:OpenAPLEditor()
    elseif command == "toggle" then
        -- Toggle rotation
        if WR.ToggleRotation then
            local newState = not (WR.IsEnabled and WR.IsEnabled())
            WR.ToggleRotation(newState)
            API.Print("WindrunnerRotations " .. (newState and "enabled" or "disabled"))
        end
    else
        -- Show help
        API.Print("WindrunnerRotations Commands:")
        API.Print("/wr - Open configuration panel")
        API.Print("/wr toggle - Toggle rotation on/off")
        API.Print("/wr ml - Open Machine Learning settings")
        API.Print("/wr combat - Open Combat Analysis settings")
        API.Print("/wr boss - Open Boss Strategies settings")
        API.Print("/wr skill - Open Player Skill settings")
        API.Print("/wr apl - Open APL editor")
    end
end

-- Return the module for loading
return EnhancedConfigUI