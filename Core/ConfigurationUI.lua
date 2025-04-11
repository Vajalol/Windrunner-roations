------------------------------------------
-- WindrunnerRotations - Configuration UI
-- Author: VortexQ8
-- The War Within Season 2
------------------------------------------

local addonName, WR = ...
local ConfigurationUI = {}
WR.ConfigurationUI = ConfigurationUI

-- Dependencies
local API = WR.API
local ConfigRegistry = WR.ConfigRegistry
local ModuleManager = WR.ModuleManager

-- UI references
local mainFrame
local tabGroup
local pages = {}
local currentModule = nil
local currentSpec = nil
local hasChanges = false
local pendingChanges = {}
local profilesList = {}
local activeProfile = "Default"

-- Default sizes and positions
local MAIN_FRAME_WIDTH = 900
local MAIN_FRAME_HEIGHT = 700
local CONTENT_PADDING = 15
local CATEGORY_SPACING = 25
local BUTTON_HEIGHT = 22
local SIDEBAR_WIDTH = 220

-- Initialize Configuration UI
function ConfigurationUI:Initialize()
    -- Register settings
    self:RegisterSettings()
    
    -- Register slash command
    SLASH_WRCONFIG1 = "/wrconfig"
    SLASH_WRCONFIG2 = "/wrcfg"
    SlashCmdList["WRCONFIG"] = function(msg)
        self:ToggleUI()
    end
    
    -- Hook into ConfigRegistry
    ConfigRegistry.OpenSettings = function(moduleName)
        self:OpenModuleSettings(moduleName)
    end
    
    API.PrintDebug("Configuration UI initialized")
    return true
end

-- Register Configuration UI settings
function ConfigurationUI:RegisterSettings()
    ConfigRegistry:RegisterSettings("ConfigurationUI", {
        uiSettings = {
            rememberFramePosition = {
                displayName = "Remember Frame Position",
                description = "Remember position of the configuration window",
                type = "toggle",
                default = true
            },
            frameScale = {
                displayName = "UI Scale",
                description = "Scale of the configuration UI",
                type = "slider",
                min = 0.5,
                max = 2.0,
                step = 0.05,
                default = 1.0
            },
            colorTheme = {
                displayName = "Color Theme",
                description = "Color theme for the UI",
                type = "dropdown",
                options = {"Classic", "Dark", "Light", "Custom"},
                default = "Classic"
            },
            customAccentColor = {
                displayName = "Custom Accent Color",
                description = "Accent color for custom theme",
                type = "color",
                default = {r = 0.2, g = 0.4, b = 0.8, a = 1.0}
            },
            showTooltips = {
                displayName = "Show Tooltips",
                description = "Show tooltips with additional information",
                type = "toggle",
                default = true
            },
            autoOpenOnStartup = {
                displayName = "Auto-Open on Startup",
                description = "Automatically open configuration UI on addon startup",
                type = "toggle",
                default = false
            }
        },
        profileSettings = {
            currentProfile = {
                displayName = "Current Profile",
                description = "Currently active configuration profile",
                type = "dropdown",
                options = {"Default"},
                default = "Default"
            },
            autoUpdateProfiles = {
                displayName = "Auto-Update for Specializations",
                description = "Automatically switch profiles when changing specializations",
                type = "toggle",
                default = false
            }
        }
    })
}

-- Create main configuration UI
function ConfigurationUI:CreateMainFrame()
    -- Check if frame already exists
    if mainFrame then
        return mainFrame
    end
    
    -- Get settings
    local settings = ConfigRegistry:GetSettings("ConfigurationUI")
    local scale = settings.uiSettings.frameScale or 1.0
    
    -- Create main frame
    local frame = CreateFrame("Frame", "WindrunnerConfigFrame", UIParent, "BackdropTemplate")
    frame:SetSize(MAIN_FRAME_WIDTH, MAIN_FRAME_HEIGHT)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetScale(scale)
    frame:SetFrameStrata("DIALOG")
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = {left = 8, right = 8, top = 8, bottom = 8}
    })
    frame:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:Hide()
    
    -- Create header
    local header = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    header:SetSize(MAIN_FRAME_WIDTH - 20, 40)
    header:SetPoint("TOP", frame, "TOP", 0, -10)
    header:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Header",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = {left = 5, right = 5, top = 5, bottom = 5}
    })
    
    -- Title
    frame.title = header:CreateFontString(nil, "OVERLAY")
    frame.title:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    frame.title:SetPoint("TOP", header, "TOP", 0, -10)
    frame.title:SetText("WindrunnerRotations Configuration")
    
    -- Version text
    frame.version = frame:CreateFontString(nil, "OVERLAY")
    frame.version:SetFont("Fonts\\FRIZQT__.TTF", 10)
    frame.version:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -20, -20)
    frame.version:SetText("Version: " .. (GetAddOnMetadata(addonName, "Version") or "Unknown"))
    
    -- Create close button
    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    closeButton:SetScript("OnClick", function()
        self:OnCloseUI()
    end)
    
    -- Create sidebar
    local sidebar = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    sidebar:SetSize(SIDEBAR_WIDTH, MAIN_FRAME_HEIGHT - 80)
    sidebar:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -60)
    sidebar:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    sidebar:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
    frame.sidebar = sidebar
    
    -- Create tab buttons container
    local tabContainer = CreateFrame("Frame", nil, sidebar)
    tabContainer:SetSize(SIDEBAR_WIDTH - 20, MAIN_FRAME_HEIGHT - 150)
    tabContainer:SetPoint("TOP", sidebar, "TOP", 0, -10)
    frame.tabContainer = tabContainer
    
    -- Create content frame
    local contentFrame = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    contentFrame:SetSize(MAIN_FRAME_WIDTH - SIDEBAR_WIDTH - 30, MAIN_FRAME_HEIGHT - 80)
    contentFrame:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", 10, 0)
    contentFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    contentFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
    frame.contentFrame = contentFrame
    
    -- Create scrollframe for content
    frame.scrollFrame = CreateFrame("ScrollFrame", nil, contentFrame, "UIPanelScrollFrameTemplate")
    frame.scrollFrame:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 8, -8)
    frame.scrollFrame:SetPoint("BOTTOMRIGHT", contentFrame, "BOTTOMRIGHT", -26, 8)
    
    -- Create content child
    frame.scrollChild = CreateFrame("Frame")
    frame.scrollFrame:SetScrollChild(frame.scrollChild)
    frame.scrollChild:SetSize(contentFrame:GetWidth() - 16, contentFrame:GetHeight() * 2)
    
    -- Create profile selector at the bottom of sidebar
    local profileHeader = sidebar:CreateFontString(nil, "OVERLAY")
    profileHeader:SetFont("Fonts\\FRIZQT__.TTF", 12)
    profileHeader:SetPoint("BOTTOMLEFT", sidebar, "BOTTOMLEFT", 10, 60)
    profileHeader:SetText("Profiles")
    
    -- Profile dropdown
    local profileDropdown = CreateFrame("Frame", "WindrunnerConfigProfileDropdown", sidebar, "UIDropDownMenuTemplate")
    profileDropdown:SetPoint("TOPLEFT", profileHeader, "BOTTOMLEFT", -15, -5)
    UIDropDownMenu_SetWidth(profileDropdown, SIDEBAR_WIDTH - 40)
    
    -- Profile buttons
    local newProfileButton = CreateFrame("Button", nil, sidebar, "UIPanelButtonTemplate")
    newProfileButton:SetSize(80, BUTTON_HEIGHT)
    newProfileButton:SetPoint("TOPLEFT", profileDropdown, "BOTTOMLEFT", 15, -5)
    newProfileButton:SetText("New")
    newProfileButton:SetScript("OnClick", function()
        self:ShowNewProfileDialog()
    end)
    
    local deleteProfileButton = CreateFrame("Button", nil, sidebar, "UIPanelButtonTemplate")
    deleteProfileButton:SetSize(80, BUTTON_HEIGHT)
    deleteProfileButton:SetPoint("LEFT", newProfileButton, "RIGHT", 5, 0)
    deleteProfileButton:SetText("Delete")
    deleteProfileButton:SetScript("OnClick", function()
        self:ShowDeleteProfileDialog()
    end)
    
    -- Initialize profile dropdown
    UIDropDownMenu_Initialize(profileDropdown, function(self, level)
        local info = UIDropDownMenu_CreateInfo()
        for i, profileName in ipairs(profilesList) do
            info.text = profileName
            info.value = profileName
            info.checked = (profileName == activeProfile)
            info.func = function()
                ConfigurationUI:SelectProfile(profileName)
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    
    frame.profileDropdown = profileDropdown
    
    -- Bottom buttons
    local saveButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    saveButton:SetSize(100, BUTTON_HEIGHT)
    saveButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -20, 15)
    saveButton:SetText("Save & Close")
    saveButton:SetScript("OnClick", function()
        self:SaveChanges()
        self:HideUI()
    end)
    
    local cancelButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    cancelButton:SetSize(80, BUTTON_HEIGHT)
    cancelButton:SetPoint("RIGHT", saveButton, "LEFT", -10, 0)
    cancelButton:SetText("Cancel")
    cancelButton:SetScript("OnClick", function()
        self:RevertChanges()
        self:HideUI()
    end)
    
    local applyButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    applyButton:SetSize(80, BUTTON_HEIGHT)
    applyButton:SetPoint("RIGHT", cancelButton, "LEFT", -10, 0)
    applyButton:SetText("Apply")
    applyButton:Enable(false)
    applyButton:SetScript("OnClick", function()
        self:SaveChanges()
    end)
    
    frame.applyButton = applyButton
    
    mainFrame = frame
    return mainFrame
end

-- Initialize the UI tabs and content
function ConfigurationUI:InitializeTabs()
    if not mainFrame then return end
    
    -- Create tabs based on available modules
    tabGroup = {
        tabs = {},
        selectedTab = nil
    }
    
    -- Always add general settings tab
    self:AddTab("General", function(container)
        self:CreateGeneralSettings(container)
    end)
    
    -- Add tabs for each available class/spec module
    local classModules = ModuleManager:GetClassModules()
    for className, classData in pairs(classModules) do
        if classData.specs and #classData.specs > 0 then
            self:AddTab(className, function(container)
                self:CreateClassSettings(container, className, classData)
            end)
        end
    end
    
    -- Add Combat Simulator tab
    self:AddTab("Combat Simulator", function(container)
        self:CreateSimulatorSettings(container)
    end)
    
    -- Add Performance tab
    self:AddTab("Performance", function(container)
        self:CreatePerformanceSettings(container)
    end)
    
    -- Add Profiles tab
    self:AddTab("Profiles", function(container)
        self:CreateProfileSettings(container)
    end)
    
    -- Select first tab by default
    if #tabGroup.tabs > 0 then
        self:SelectTab(tabGroup.tabs[1].name)
    end
    
    -- Load profiles
    self:LoadProfiles()
}

-- Add a tab to the UI
function ConfigurationUI:AddTab(name, contentFunc)
    if not mainFrame or not tabGroup then return end
    
    -- Create button for this tab
    local index = #tabGroup.tabs + 1
    local button = CreateFrame("Button", nil, mainFrame.tabContainer)
    button:SetSize(SIDEBAR_WIDTH - 30, 30)
    button:SetPoint("TOPLEFT", mainFrame.tabContainer, "TOPLEFT", 10, -10 - (index-1) * 35)
    button:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
    
    -- Button background when selected
    button.bg = button:CreateTexture(nil, "BACKGROUND")
    button.bg:SetAllPoints()
    button.bg:SetColorTexture(0.3, 0.3, 0.3, 0.5)
    button.bg:Hide()
    
    -- Button text
    button.text = button:CreateFontString(nil, "OVERLAY")
    button.text:SetFont("Fonts\\FRIZQT__.TTF", 12)
    button.text:SetPoint("LEFT", button, "LEFT", 10, 0)
    button.text:SetJustifyH("LEFT")
    button.text:SetText(name)
    
    -- Button click handler
    button:SetScript("OnClick", function()
        self:SelectTab(name)
    end)
    
    -- Store tab data
    table.insert(tabGroup.tabs, {
        name = name,
        button = button,
        contentFunc = contentFunc,
        initialized = false
    })
}

-- Select a tab and show its content
function ConfigurationUI:SelectTab(tabName)
    if not mainFrame or not tabGroup then return end
    
    -- Find the tab
    local selectedTab = nil
    for _, tab in ipairs(tabGroup.tabs) do
        if tab.name == tabName then
            selectedTab = tab
            break
        end
    end
    
    if not selectedTab then return end
    
    -- Update buttons
    for _, tab in ipairs(tabGroup.tabs) do
        if tab == selectedTab then
            tab.button.bg:Show()
            tab.button.text:SetTextColor(1, 1, 1)
        else
            tab.button.bg:Hide()
            tab.button.text:SetTextColor(0.8, 0.8, 0.8)
        end
    end
    
    -- Clear current content
    mainFrame.scrollChild:SetSize(mainFrame.scrollFrame:GetWidth(), mainFrame.scrollFrame:GetHeight() * 2)
    for _, child in ipairs({mainFrame.scrollChild:GetChildren()}) do
        child:Hide()
    end
    
    -- Create page if not initialized
    if not selectedTab.initialized then
        selectedTab.contentFunc(mainFrame.scrollChild)
        selectedTab.initialized = true
    end
    
    -- Show the page
    if pages[tabName] then
        pages[tabName]:Show()
        mainFrame.scrollFrame:SetVerticalScroll(0)
    end
    
    tabGroup.selectedTab = selectedTab
}

-- Create general settings page
function ConfigurationUI:CreateGeneralSettings(container)
    -- Create content page
    local page = CreateFrame("Frame", nil, container)
    page:SetSize(container:GetWidth(), container:GetHeight())
    page:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)
    pages["General"] = page
    
    -- Title
    local title = page:CreateFontString(nil, "OVERLAY")
    title:SetFont("Fonts\\FRIZQT__.TTF", 16)
    title:SetPoint("TOPLEFT", page, "TOPLEFT", CONTENT_PADDING, -CONTENT_PADDING)
    title:SetText("General Settings")
    
    -- Description
    local description = page:CreateFontString(nil, "OVERLAY")
    description:SetFont("Fonts\\FRIZQT__.TTF", 12)
    description:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -5)
    description:SetText("Configure general addon settings")
    description:SetTextColor(0.8, 0.8, 0.8)
    
    local currentY = -CONTENT_PADDING - 50
    
    -- Get settings
    local settings = ConfigRegistry:GetSettings("General")
    
    -- Create UI elements for each setting
    self:CreateCategory(page, "Addon Settings", currentY)
    currentY = currentY - 30
    
    if settings.addonEnabled ~= nil then
        self:CreateToggle(page, "Enable WindrunnerRotations", settings.addonEnabled, function(value)
            self:StoreChangedSetting("General", "addonEnabled", value)
        end, "Enable or disable the entire addon", currentY)
        currentY = currentY - 30
    end
    
    if settings.debugMode ~= nil then
        self:CreateToggle(page, "Debug Mode", settings.debugMode, function(value)
            self:StoreChangedSetting("General", "debugMode", value)
        end, "Enable debug logging and additional information", currentY)
        currentY = currentY - 30
    end
    
    -- UI Settings section
    self:CreateCategory(page, "UI Settings", currentY)
    currentY = currentY - 30
    
    -- Get UI settings
    local uiSettings = ConfigRegistry:GetSettings("ConfigurationUI").uiSettings
    
    self:CreateToggle(page, "Remember Frame Position", uiSettings.rememberFramePosition, function(value)
        self:StoreChangedSetting("ConfigurationUI", "uiSettings.rememberFramePosition", value)
    end, "Remember the position of the configuration window", currentY)
    currentY = currentY - 30
    
    self:CreateSlider(page, "UI Scale", uiSettings.frameScale, 0.5, 2.0, 0.05, function(value)
        self:StoreChangedSetting("ConfigurationUI", "uiSettings.frameScale", value)
    end, "Scale of the configuration UI", currentY)
    currentY = currentY - 50
    
    self:CreateDropdown(page, "Color Theme", uiSettings.colorTheme, {"Classic", "Dark", "Light", "Custom"}, function(value)
        self:StoreChangedSetting("ConfigurationUI", "uiSettings.colorTheme", value)
    end, "Color theme for the UI", currentY)
    currentY = currentY - 50
    
    self:CreateToggle(page, "Show Tooltips", uiSettings.showTooltips, function(value)
        self:StoreChangedSetting("ConfigurationUI", "uiSettings.showTooltips", value)
    end, "Show tooltips with additional information", currentY)
    currentY = currentY - 30
    
    self:CreateToggle(page, "Auto-Open on Startup", uiSettings.autoOpenOnStartup, function(value)
        self:StoreChangedSetting("ConfigurationUI", "uiSettings.autoOpenOnStartup", value)
    end, "Automatically open configuration UI on addon startup", currentY)
    currentY = currentY - 30
    
    -- Notification settings
    self:CreateCategory(page, "Notification Settings", currentY)
    currentY = currentY - 30
    
    if settings.showRotationStartedMsg ~= nil then
        self:CreateToggle(page, "Show Rotation Started Message", settings.showRotationStartedMsg, function(value)
            self:StoreChangedSetting("General", "showRotationStartedMsg", value)
        end, "Show a message when rotation starts", currentY)
        currentY = currentY - 30
    end
    
    if settings.showRotationStoppedMsg ~= nil then
        self:CreateToggle(page, "Show Rotation Stopped Message", settings.showRotationStoppedMsg, function(value)
            self:StoreChangedSetting("General", "showRotationStoppedMsg", value)
        end, "Show a message when rotation stops", currentY)
        currentY = currentY - 30
    end
    
    -- Key Bindings section
    self:CreateCategory(page, "Key Bindings", currentY)
    currentY = currentY - 30
    
    -- Key binding information
    local keyBindInfo = page:CreateFontString(nil, "OVERLAY")
    keyBindInfo:SetFont("Fonts\\FRIZQT__.TTF", 12)
    keyBindInfo:SetPoint("TOPLEFT", page, "TOPLEFT", CONTENT_PADDING, currentY)
    keyBindInfo:SetWidth(page:GetWidth() - CONTENT_PADDING * 2)
    keyBindInfo:SetJustifyH("LEFT")
    keyBindInfo:SetText("Key bindings can be configured in WoW's standard Key Bindings menu under the 'AddOns' section.")
    keyBindInfo:SetTextColor(0.8, 0.8, 0.8)
    
    currentY = currentY - 40
    
    -- Open Key Bindings button
    local keyBindButton = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
    keyBindButton:SetSize(150, BUTTON_HEIGHT)
    keyBindButton:SetPoint("TOPLEFT", page, "TOPLEFT", CONTENT_PADDING, currentY)
    keyBindButton:SetText("Open Key Bindings")
    keyBindButton:SetScript("OnClick", function()
        -- Open WoW's key binding UI
        if OpenBindingUI then
            OpenBindingUI()
        else
            API.Print("Key binding UI not available in this version.")
        end
    end)
}

-- Create class-specific settings page
function ConfigurationUI:CreateClassSettings(container, className, classData)
    -- Create content page
    local page = CreateFrame("Frame", nil, container)
    page:SetSize(container:GetWidth(), container:GetHeight())
    page:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)
    pages[className] = page
    
    -- Title
    local title = page:CreateFontString(nil, "OVERLAY")
    title:SetFont("Fonts\\FRIZQT__.TTF", 16)
    title:SetPoint("TOPLEFT", page, "TOPLEFT", CONTENT_PADDING, -CONTENT_PADDING)
    title:SetText(className .. " Settings")
    
    -- Description
    local description = page:CreateFontString(nil, "OVERLAY")
    description:SetFont("Fonts\\FRIZQT__.TTF", 12)
    description:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -5)
    description:SetText("Configure rotation settings for " .. className .. " specializations")
    description:SetTextColor(0.8, 0.8, 0.8)
    
    local currentY = -CONTENT_PADDING - 50
    
    -- Create spec selector
    self:CreateCategory(page, "Specialization", currentY)
    currentY = currentY - 30
    
    -- Create spec buttons
    local specButtons = {}
    local buttonWidth = (page:GetWidth() - CONTENT_PADDING * 2) / #classData.specs
    
    for i, spec in ipairs(classData.specs) do
        local button = CreateFrame("Button", nil, page)
        button:SetSize(buttonWidth - 10, 30)
        button:SetPoint("TOPLEFT", page, "TOPLEFT", CONTENT_PADDING + (i-1) * buttonWidth, currentY)
        button:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
        
        button.bg = button:CreateTexture(nil, "BACKGROUND")
        button.bg:SetAllPoints()
        button.bg:SetColorTexture(0.3, 0.3, 0.3, 0.5)
        button.bg:Hide()
        
        button.text = button:CreateFontString(nil, "OVERLAY")
        button.text:SetFont("Fonts\\FRIZQT__.TTF", 12)
        button.text:SetPoint("CENTER", button, "CENTER", 0, 0)
        button.text:SetText(spec.name)
        
        button:SetScript("OnClick", function()
            self:SelectSpec(className, spec)
        end)
        
        table.insert(specButtons, {button = button, spec = spec})
    end
    
    page.specButtons = specButtons
    
    currentY = currentY - 40
    
    -- Create container for spec settings
    local specSettingsContainer = CreateFrame("Frame", nil, page)
    specSettingsContainer:SetSize(page:GetWidth() - CONTENT_PADDING * 2, page:GetHeight() - currentY - 50)
    specSettingsContainer:SetPoint("TOPLEFT", page, "TOPLEFT", CONTENT_PADDING, currentY)
    page.specSettingsContainer = specSettingsContainer
    
    -- Select first spec by default
    if #classData.specs > 0 then
        self:SelectSpec(className, classData.specs[1])
    end
}

-- Select and load a spec's settings
function ConfigurationUI:SelectSpec(className, spec)
    if not mainFrame or not pages[className] then return end
    
    local page = pages[className]
    
    -- Update spec buttons
    for _, specButton in ipairs(page.specButtons) do
        if specButton.spec.id == spec.id then
            specButton.button.bg:Show()
            specButton.button.text:SetTextColor(1, 1, 1)
        else
            specButton.button.bg:Hide()
            specButton.button.text:SetTextColor(0.8, 0.8, 0.8)
        end
    end
    
    -- Clear spec settings container
    for _, child in ipairs({page.specSettingsContainer:GetChildren()}) do
        child:Hide()
    end
    
    -- Store current spec
    currentModule = spec.moduleKey
    currentSpec = spec.id
    
    -- Create settings for this spec
    self:CreateSpecSettings(page.specSettingsContainer, className, spec)
}

-- Create settings for a specific specialization
function ConfigurationUI:CreateSpecSettings(container, className, spec)
    -- Create scrollframe for settings
    local scrollFrame = CreateFrame("ScrollFrame", nil, container, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)
    scrollFrame:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", -18, 0)
    
    local scrollChild = CreateFrame("Frame")
    scrollFrame:SetScrollChild(scrollChild)
    scrollChild:SetSize(container:GetWidth() - 18, container:GetHeight() * 2)
    
    -- Fetch settings for this spec
    local moduleSettings = ConfigRegistry:GetSettings(spec.moduleKey)
    if not moduleSettings then
        local noSettings = scrollChild:CreateFontString(nil, "OVERLAY")
        noSettings:SetFont("Fonts\\FRIZQT__.TTF", 14)
        noSettings:SetPoint("CENTER", scrollChild, "CENTER", 0, 0)
        noSettings:SetText("No settings available for " .. spec.name .. " " .. className)
        return
    end
    
    local currentY = 0
    
    -- Create UI for each settings category
    for categoryName, categorySettings in pairs(moduleSettings) do
        if type(categorySettings) == "table" then
            self:CreateCategory(scrollChild, self:FormatCategoryName(categoryName), currentY)
            currentY = currentY - 30
            
            currentY = self:CreateSettingsControls(scrollChild, spec.moduleKey, categoryName, categorySettings, currentY)
            
            currentY = currentY - CATEGORY_SPACING
        end
    end
}

-- Create simulator settings page
function ConfigurationUI:CreateSimulatorSettings(container)
    -- Create content page
    local page = CreateFrame("Frame", nil, container)
    page:SetSize(container:GetWidth(), container:GetHeight())
    page:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)
    pages["Combat Simulator"] = page
    
    -- Title
    local title = page:CreateFontString(nil, "OVERLAY")
    title:SetFont("Fonts\\FRIZQT__.TTF", 16)
    title:SetPoint("TOPLEFT", page, "TOPLEFT", CONTENT_PADDING, -CONTENT_PADDING)
    title:SetText("Combat Simulator Settings")
    
    -- Description
    local description = page:CreateFontString(nil, "OVERLAY")
    description:SetFont("Fonts\\FRIZQT__.TTF", 12)
    description:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -5)
    description:SetText("Configure and run combat simulation for your rotations")
    description:SetTextColor(0.8, 0.8, 0.8)
    
    local currentY = -CONTENT_PADDING - 50
    
    -- Fetch settings
    local simSettings = ConfigRegistry:GetSettings("RotationSimulator")
    if not simSettings then
        local noSettings = page:CreateFontString(nil, "OVERLAY")
        noSettings:SetFont("Fonts\\FRIZQT__.TTF", 14)
        noSettings:SetPoint("CENTER", page, "CENTER", 0, 0)
        noSettings:SetText("Rotation Simulator not available")
        return
    end
    
    -- Create settings controls
    for categoryName, categorySettings in pairs(simSettings) do
        if type(categorySettings) == "table" then
            self:CreateCategory(page, self:FormatCategoryName(categoryName), currentY)
            currentY = currentY - 30
            
            currentY = self:CreateSettingsControls(page, "RotationSimulator", categoryName, categorySettings, currentY)
            
            currentY = currentY - CATEGORY_SPACING
        end
    end
    
    -- Add simulation controls
    self:CreateCategory(page, "Run Simulation", currentY)
    currentY = currentY - 30
    
    -- Class/spec selector
    local classNames = {}
    local classModules = ModuleManager:GetClassModules()
    for className, _ in pairs(classModules) do
        table.insert(classNames, className)
    end
    table.sort(classNames)
    
    local selectedClass = classNames[1]
    local selectedSpec = nil
    
    -- Class dropdown
    local classLabel = page:CreateFontString(nil, "OVERLAY")
    classLabel:SetFont("Fonts\\FRIZQT__.TTF", 12)
    classLabel:SetPoint("TOPLEFT", page, "TOPLEFT", CONTENT_PADDING, currentY)
    classLabel:SetText("Class:")
    
    local classDropdown = CreateFrame("Frame", "WindrunnerSimClassDropdown", page, "UIDropDownMenuTemplate")
    classDropdown:SetPoint("TOPLEFT", classLabel, "TOPRIGHT", 10, 0)
    UIDropDownMenu_SetWidth(classDropdown, 150)
    
    -- Spec dropdown
    local specLabel = page:CreateFontString(nil, "OVERLAY")
    specLabel:SetFont("Fonts\\FRIZQT__.TTF", 12)
    specLabel:SetPoint("TOPLEFT", classLabel, "TOPLEFT", 250, 0)
    specLabel:SetText("Specialization:")
    
    local specDropdown = CreateFrame("Frame", "WindrunnerSimSpecDropdown", page, "UIDropDownMenuTemplate")
    specDropdown:SetPoint("TOPLEFT", specLabel, "TOPRIGHT", 10, 0)
    UIDropDownMenu_SetWidth(specDropdown, 150)
    
    -- Update spec dropdown based on selected class
    local function UpdateSpecDropdown()
        if not selectedClass then return end
        
        local specs = {}
        if classModules[selectedClass] and classModules[selectedClass].specs then
            for _, spec in ipairs(classModules[selectedClass].specs) do
                table.insert(specs, {name = spec.name, id = spec.id, moduleKey = spec.moduleKey})
            end
        end
        
        selectedSpec = specs[1] and specs[1].moduleKey or nil
        
        UIDropDownMenu_Initialize(specDropdown, function(self, level)
            local info = UIDropDownMenu_CreateInfo()
            for i, spec in ipairs(specs) do
                info.text = spec.name
                info.value = spec.moduleKey
                info.checked = (spec.moduleKey == selectedSpec)
                info.func = function()
                    selectedSpec = spec.moduleKey
                    UIDropDownMenu_SetText(specDropdown, spec.name)
                end
                UIDropDownMenu_AddButton(info, level)
            end
        end)
        
        if specs[1] then
            UIDropDownMenu_SetText(specDropdown, specs[1].name)
        else
            UIDropDownMenu_SetText(specDropdown, "None")
        end
    end
    
    -- Initialize class dropdown
    UIDropDownMenu_Initialize(classDropdown, function(self, level)
        local info = UIDropDownMenu_CreateInfo()
        for i, className in ipairs(classNames) do
            info.text = className
            info.value = className
            info.checked = (className == selectedClass)
            info.func = function()
                selectedClass = className
                UIDropDownMenu_SetText(classDropdown, className)
                UpdateSpecDropdown()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    
    if classNames[1] then
        UIDropDownMenu_SetText(classDropdown, classNames[1])
        UpdateSpecDropdown()
    end
    
    currentY = currentY - 50
    
    -- Duration slider
    self:CreateSlider(page, "Simulation Duration (seconds)", 300, 30, 600, 30, function(value)
        simulationDuration = value
    end, "Duration of the simulation in seconds", currentY)
    
    currentY = currentY - 50
    
    -- Start button
    local startButton = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
    startButton:SetSize(150, BUTTON_HEIGHT)
    startButton:SetPoint("TOPLEFT", page, "TOPLEFT", CONTENT_PADDING, currentY)
    startButton:SetText("Start Simulation")
    startButton:SetScript("OnClick", function()
        if selectedSpec then
            -- Start simulation for the selected spec
            if WR.RotationSimulator and WR.RotationSimulator.StartSimulation then
                -- Get the module
                local module = ModuleManager:GetModule(selectedSpec)
                if module then
                    WR.RotationSimulator:SetupSimulationForModule(module)
                    WR.RotationSimulator:StartSimulation(simulationDuration)
                else
                    API.Print("Module not found: " .. selectedSpec)
                end
            else
                API.Print("Rotation Simulator not available")
            end
        else
            API.Print("Please select a specialization first")
        end
    end)
    
    -- Report button
    local reportButton = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
    reportButton:SetSize(150, BUTTON_HEIGHT)
    reportButton:SetPoint("LEFT", startButton, "RIGHT", 20, 0)
    reportButton:SetText("Show Last Report")
    reportButton:SetScript("OnClick", function()
        if WR.RotationSimulator and WR.RotationSimulator.HandleSlashCommand then
            WR.RotationSimulator:HandleSlashCommand("report")
        else
            API.Print("Rotation Simulator not available")
        end
    end)
}

-- Create performance settings page
function ConfigurationUI:CreatePerformanceSettings(container)
    -- Create content page
    local page = CreateFrame("Frame", nil, container)
    page:SetSize(container:GetWidth(), container:GetHeight())
    page:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)
    pages["Performance"] = page
    
    -- Title
    local title = page:CreateFontString(nil, "OVERLAY")
    title:SetFont("Fonts\\FRIZQT__.TTF", 16)
    title:SetPoint("TOPLEFT", page, "TOPLEFT", CONTENT_PADDING, -CONTENT_PADDING)
    title:SetText("Performance Tracker Settings")
    
    -- Description
    local description = page:CreateFontString(nil, "OVERLAY")
    description:SetFont("Fonts\\FRIZQT__.TTF", 12)
    description:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -5)
    description:SetText("Configure performance tracking and analysis")
    description:SetTextColor(0.8, 0.8, 0.8)
    
    local currentY = -CONTENT_PADDING - 50
    
    -- Fetch settings
    local perfSettings = ConfigRegistry:GetSettings("PerformanceTracker")
    if not perfSettings then
        local noSettings = page:CreateFontString(nil, "OVERLAY")
        noSettings:SetFont("Fonts\\FRIZQT__.TTF", 14)
        noSettings:SetPoint("CENTER", page, "CENTER", 0, 0)
        noSettings:SetText("Performance Tracker not available")
        return
    end
    
    -- Create settings controls
    for categoryName, categorySettings in pairs(perfSettings) do
        if type(categorySettings) == "table" then
            self:CreateCategory(page, self:FormatCategoryName(categoryName), currentY)
            currentY = currentY - 30
            
            currentY = self:CreateSettingsControls(page, "PerformanceTracker", categoryName, categorySettings, currentY)
            
            currentY = currentY - CATEGORY_SPACING
        end
    end
    
    -- Performance tracker controls
    self:CreateCategory(page, "Performance Tracker Controls", currentY)
    currentY = currentY - 30
    
    -- Show/Hide button
    local showButton = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
    showButton:SetSize(150, BUTTON_HEIGHT)
    showButton:SetPoint("TOPLEFT", page, "TOPLEFT", CONTENT_PADDING, currentY)
    showButton:SetText("Show Tracker")
    showButton:SetScript("OnClick", function()
        if WR.PerformanceTracker and WR.PerformanceTracker.HandleSlashCommand then
            WR.PerformanceTracker:HandleSlashCommand("show")
        else
            API.Print("Performance Tracker not available")
        end
    end)
    
    -- Hide button
    local hideButton = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
    hideButton:SetSize(150, BUTTON_HEIGHT)
    hideButton:SetPoint("LEFT", showButton, "RIGHT", 20, 0)
    hideButton:SetText("Hide Tracker")
    hideButton:SetScript("OnClick", function()
        if WR.PerformanceTracker and WR.PerformanceTracker.HandleSlashCommand then
            WR.PerformanceTracker:HandleSlashCommand("hide")
        else
            API.Print("Performance Tracker not available")
        end
    end)
    
    currentY = currentY - 40
    
    -- Reset Button
    local resetButton = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
    resetButton:SetSize(150, BUTTON_HEIGHT)
    resetButton:SetPoint("TOPLEFT", page, "TOPLEFT", CONTENT_PADDING, currentY)
    resetButton:SetText("Reset Tracking Data")
    resetButton:SetScript("OnClick", function()
        if WR.PerformanceTracker and WR.PerformanceTracker.HandleSlashCommand then
            StaticPopup_Show("WINDRUNNER_RESET_PERF_DATA")
        else
            API.Print("Performance Tracker not available")
        end
    end)
    
    -- Report button
    local reportButton = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
    reportButton:SetSize(150, BUTTON_HEIGHT)
    reportButton:SetPoint("LEFT", resetButton, "RIGHT", 20, 0)
    reportButton:SetText("Show Last Report")
    reportButton:SetScript("OnClick", function()
        if WR.PerformanceTracker and WR.PerformanceTracker.HandleSlashCommand then
            WR.PerformanceTracker:HandleSlashCommand("report")
        else
            API.Print("Performance Tracker not available")
        end
    end)
    
    -- Register confirmation dialog
    StaticPopupDialogs["WINDRUNNER_RESET_PERF_DATA"] = {
        text = "Are you sure you want to reset all performance tracking data?",
        button1 = "Yes",
        button2 = "No",
        OnAccept = function()
            if WR.PerformanceTracker and WR.PerformanceTracker.HandleSlashCommand then
                WR.PerformanceTracker:HandleSlashCommand("reset")
            end
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3
    }
}

-- Create profiles settings page
function ConfigurationUI:CreateProfileSettings(container)
    -- Create content page
    local page = CreateFrame("Frame", nil, container)
    page:SetSize(container:GetWidth(), container:GetHeight())
    page:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)
    pages["Profiles"] = page
    
    -- Title
    local title = page:CreateFontString(nil, "OVERLAY")
    title:SetFont("Fonts\\FRIZQT__.TTF", 16)
    title:SetPoint("TOPLEFT", page, "TOPLEFT", CONTENT_PADDING, -CONTENT_PADDING)
    title:SetText("Profiles")
    
    -- Description
    local description = page:CreateFontString(nil, "OVERLAY")
    description:SetFont("Fonts\\FRIZQT__.TTF", 12)
    description:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -5)
    description:SetText("Manage configuration profiles for different characters or situations")
    description:SetTextColor(0.8, 0.8, 0.8)
    
    local currentY = -CONTENT_PADDING - 50
    
    -- Current profile
    local profileSettings = ConfigRegistry:GetSettings("ConfigurationUI").profileSettings
    
    -- Profiles list
    self:CreateCategory(page, "Available Profiles", currentY)
    currentY = currentY - 30
    
    -- Create profile listbox
    local profileList = CreateFrame("Frame", nil, page, "BackdropTemplate")
    profileList:SetSize(300, 200)
    profileList:SetPoint("TOPLEFT", page, "TOPLEFT", CONTENT_PADDING, currentY)
    profileList:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    
    -- Create scrollframe for profiles
    local scrollFrame = CreateFrame("ScrollFrame", nil, profileList, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", profileList, "TOPLEFT", 8, -8)
    scrollFrame:SetPoint("BOTTOMRIGHT", profileList, "BOTTOMRIGHT", -26, 8)
    
    local scrollChild = CreateFrame("Frame")
    scrollFrame:SetScrollChild(scrollChild)
    scrollChild:SetSize(profileList:GetWidth() - 16, profileList:GetHeight() * 2)
    
    -- Will be populated when LoadProfiles is called
    page.profileScrollChild = scrollChild
    
    currentY = currentY - 220
    
    -- Profile actions
    self:CreateCategory(page, "Profile Actions", currentY)
    currentY = currentY - 30
    
    -- Create New Profile button
    local newProfileButton = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
    newProfileButton:SetSize(150, BUTTON_HEIGHT)
    newProfileButton:SetPoint("TOPLEFT", page, "TOPLEFT", CONTENT_PADDING, currentY)
    newProfileButton:SetText("Create New Profile")
    newProfileButton:SetScript("OnClick", function()
        self:ShowNewProfileDialog()
    end)
    
    -- Delete Profile button
    local deleteProfileButton = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
    deleteProfileButton:SetSize(150, BUTTON_HEIGHT)
    deleteProfileButton:SetPoint("LEFT", newProfileButton, "RIGHT", 20, 0)
    deleteProfileButton:SetText("Delete Profile")
    deleteProfileButton:SetScript("OnClick", function()
        self:ShowDeleteProfileDialog()
    end)
    
    currentY = currentY - 40
    
    -- Copy Profile Button
    local copyProfileButton = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
    copyProfileButton:SetSize(150, BUTTON_HEIGHT)
    copyProfileButton:SetPoint("TOPLEFT", page, "TOPLEFT", CONTENT_PADDING, currentY)
    copyProfileButton:SetText("Copy Profile")
    copyProfileButton:SetScript("OnClick", function()
        self:ShowCopyProfileDialog()
    end)
    
    -- Reset Profile Button
    local resetProfileButton = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
    resetProfileButton:SetSize(150, BUTTON_HEIGHT)
    resetProfileButton:SetPoint("LEFT", copyProfileButton, "RIGHT", 20, 0)
    resetProfileButton:SetText("Reset Profile")
    resetProfileButton:SetScript("OnClick", function()
        StaticPopup_Show("WINDRUNNER_RESET_PROFILE")
    end)
    
    currentY = currentY - 50
    
    -- Auto-switch settings
    self:CreateToggle(page, "Auto-Switch for Specializations", profileSettings.autoUpdateProfiles, function(value)
        self:StoreChangedSetting("ConfigurationUI", "profileSettings.autoUpdateProfiles", value)
    end, "Automatically switch profiles when changing specializations", currentY)
    
    -- Register confirmation dialogs
    StaticPopupDialogs["WINDRUNNER_RESET_PROFILE"] = {
        text = "Are you sure you want to reset the current profile to default settings?",
        button1 = "Yes",
        button2 = "No",
        OnAccept = function()
            ConfigRegistry:ResetProfile(activeProfile)
            API.Print("Profile '" .. activeProfile .. "' has been reset to defaults.")
            -- Reload UI to reflect changes
            self:ReloadUI()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3
    }
}

-- Load and display available profiles
function ConfigurationUI:LoadProfiles()
    -- Get profiles from ConfigRegistry
    profilesList = ConfigRegistry:GetProfiles() or {"Default"}
    if #profilesList == 0 then
        table.insert(profilesList, "Default")
    end
    
    -- Get active profile
    activeProfile = ConfigRegistry:GetSettings("ConfigurationUI").profileSettings.currentProfile or "Default"
    if not tContains(profilesList, activeProfile) then
        activeProfile = profilesList[1]
    end
    
    -- Update UI
    if mainFrame and mainFrame.profileDropdown then
        UIDropDownMenu_SetText(mainFrame.profileDropdown, activeProfile)
        UIDropDownMenu_Initialize(mainFrame.profileDropdown, function(self, level)
            local info = UIDropDownMenu_CreateInfo()
            for i, profileName in ipairs(profilesList) do
                info.text = profileName
                info.value = profileName
                info.checked = (profileName == activeProfile)
                info.func = function()
                    ConfigurationUI:SelectProfile(profileName)
                end
                UIDropDownMenu_AddButton(info, level)
            end
        end)
    end
    
    -- Update profiles list page if open
    if pages["Profiles"] and pages["Profiles"].profileScrollChild then
        local scrollChild = pages["Profiles"].profileScrollChild
        
        -- Clear existing buttons
        for _, child in ipairs({scrollChild:GetChildren()}) do
            child:Hide()
        end
        
        -- Create profile buttons
        for i, profileName in ipairs(profilesList) do
            local button = CreateFrame("Button", nil, scrollChild)
            button:SetSize(scrollChild:GetWidth() - 20, 24)
            button:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, -10 - (i-1) * 26)
            button:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
            
            -- Button text
            button.text = button:CreateFontString(nil, "OVERLAY")
            button.text:SetFont("Fonts\\FRIZQT__.TTF", 12)
            button.text:SetPoint("LEFT", button, "LEFT", 10, 0)
            button.text:SetText(profileName)
            
            -- Active profile indicator
            if profileName == activeProfile then
                button.active = button:CreateFontString(nil, "OVERLAY")
                button.active:SetFont("Fonts\\FRIZQT__.TTF", 10)
                button.active:SetPoint("RIGHT", button, "RIGHT", -10, 0)
                button.active:SetText("(Active)")
                button.active:SetTextColor(0, 1, 0)
            end
            
            -- Click handler
            button:SetScript("OnClick", function()
                self:SelectProfile(profileName)
            end)
        end
    end
}

-- Select a profile
function ConfigurationUI:SelectProfile(profileName)
    if not profileName or not tContains(profilesList, profileName) then return end
    
    -- Apply profile changes
    ConfigRegistry:SetActiveProfile(profileName)
    activeProfile = profileName
    
    -- Update UI to reflect the new profile
    UIDropDownMenu_SetText(mainFrame.profileDropdown, profileName)
    
    -- Update settings
    self:StoreChangedSetting("ConfigurationUI", "profileSettings.currentProfile", profileName)
    
    -- Reload UI to reflect new profile
    self:ReloadUI()
    
    API.Print("Profile '" .. profileName .. "' activated.")
}

-- Show dialog to create a new profile
function ConfigurationUI:ShowNewProfileDialog()
    StaticPopupDialogs["WINDRUNNER_NEW_PROFILE"] = {
        text = "Enter name for the new profile:",
        button1 = "Create",
        button2 = "Cancel",
        hasEditBox = true,
        maxLetters = 32,
        OnAccept = function(self)
            local profileName = self.editBox:GetText()
            if profileName and profileName ~= "" then
                -- Check if profile already exists
                if tContains(profilesList, profileName) then
                    API.Print("Profile '" .. profileName .. "' already exists.")
                    return
                end
                
                -- Create new profile
                ConfigRegistry:CreateProfile(profileName)
                
                -- Reload profiles list
                self:LoadProfiles()
                
                API.Print("Profile '" .. profileName .. "' created.")
            end
        end,
        OnShow = function(self)
            self.editBox:SetFocus()
        end,
        OnHide = function(self)
            self.editBox:SetText("")
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3
    }
    
    StaticPopup_Show("WINDRUNNER_NEW_PROFILE")
}

-- Show dialog to delete a profile
function ConfigurationUI:ShowDeleteProfileDialog()
    -- Can't delete the Default profile
    if activeProfile == "Default" then
        API.Print("Cannot delete the Default profile.")
        return
    end
    
    StaticPopupDialogs["WINDRUNNER_DELETE_PROFILE"] = {
        text = "Are you sure you want to delete the profile '" .. activeProfile .. "'?",
        button1 = "Delete",
        button2 = "Cancel",
        OnAccept = function()
            -- Delete profile
            ConfigRegistry:DeleteProfile(activeProfile)
            
            -- Switch to Default profile
            self:SelectProfile("Default")
            
            -- Reload profiles list
            self:LoadProfiles()
            
            API.Print("Profile '" .. activeProfile .. "' deleted.")
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3
    }
    
    StaticPopup_Show("WINDRUNNER_DELETE_PROFILE")
}

-- Show dialog to copy a profile
function ConfigurationUI:ShowCopyProfileDialog()
    -- Create dropdown options
    local options = {}
    for _, profileName in ipairs(profilesList) do
        if profileName ~= activeProfile then
            table.insert(options, profileName)
        end
    end
    
    if #options == 0 then
        API.Print("No other profiles to copy from.")
        return
    end
    
    local selectedProfile = options[1]
    
    StaticPopupDialogs["WINDRUNNER_COPY_PROFILE"] = {
        text = "Copy settings from which profile?",
        button1 = "Copy",
        button2 = "Cancel",
        hasEditBox = false,
        OnShow = function(self)
            -- Create dropdown
            if not self.dropdown then
                self.dropdown = CreateFrame("Frame", "WindrunnerCopyProfileDropdown", self, "UIDropDownMenuTemplate")
                self.dropdown:SetPoint("CENTER", self, "CENTER", 0, 0)
                UIDropDownMenu_SetWidth(self.dropdown, 200)
                
                UIDropDownMenu_Initialize(self.dropdown, function(dropdown, level)
                    local info = UIDropDownMenu_CreateInfo()
                    for i, profileName in ipairs(options) do
                        info.text = profileName
                        info.value = profileName
                        info.checked = (profileName == selectedProfile)
                        info.func = function()
                            selectedProfile = profileName
                            UIDropDownMenu_SetText(self.dropdown, profileName)
                        end
                        UIDropDownMenu_AddButton(info, level)
                    end
                end)
                
                UIDropDownMenu_SetText(self.dropdown, selectedProfile)
            end
        end,
        OnAccept = function(self)
            -- Copy profile
            ConfigRegistry:CopyProfile(selectedProfile, activeProfile)
            
            API.Print("Copied settings from '" .. selectedProfile .. "' to '" .. activeProfile .. "'.")
            
            -- Reload UI to reflect changes
            self:ReloadUI()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3
    }
    
    StaticPopup_Show("WINDRUNNER_COPY_PROFILE")
}

-- Create settings controls for a category
function ConfigurationUI:CreateSettingsControls(container, moduleName, categoryName, settings, startY)
    local currentY = startY
    
    for settingName, settingInfo in pairs(settings) do
        if type(settingInfo) == "table" and settingInfo.type and settingInfo.displayName then
            -- Skip nested groups for now (will handle them recursively)
            if settingInfo.type ~= "group" then
                local value = ConfigRegistry:GetSettingValue(moduleName, categoryName .. "." .. settingName)
                
                if settingInfo.type == "toggle" then
                    self:CreateToggle(container, settingInfo.displayName, value, function(newValue)
                        self:StoreChangedSetting(moduleName, categoryName .. "." .. settingName, newValue)
                    end, settingInfo.description, currentY)
                    currentY = currentY - 30
                elseif settingInfo.type == "slider" then
                    self:CreateSlider(container, settingInfo.displayName, value, settingInfo.min, settingInfo.max, settingInfo.step, function(newValue)
                        self:StoreChangedSetting(moduleName, categoryName .. "." .. settingName, newValue)
                    end, settingInfo.description, currentY)
                    currentY = currentY - 50
                elseif settingInfo.type == "dropdown" then
                    self:CreateDropdown(container, settingInfo.displayName, value, settingInfo.options, function(newValue)
                        self:StoreChangedSetting(moduleName, categoryName .. "." .. settingName, newValue)
                    end, settingInfo.description, currentY)
                    currentY = currentY - 50
                elseif settingInfo.type == "color" then
                    self:CreateColorPicker(container, settingInfo.displayName, value, function(newValue)
                        self:StoreChangedSetting(moduleName, categoryName .. "." .. settingName, newValue)
                    end, settingInfo.description, currentY)
                    currentY = currentY - 50
                elseif settingInfo.type == "number" then
                    self:CreateNumberInput(container, settingInfo.displayName, value, function(newValue)
                        self:StoreChangedSetting(moduleName, categoryName .. "." .. settingName, newValue)
                    end, settingInfo.description, currentY)
                    currentY = currentY - 30
                elseif settingInfo.type == "string" then
                    self:CreateTextInput(container, settingInfo.displayName, value, function(newValue)
                        self:StoreChangedSetting(moduleName, categoryName .. "." .. settingName, newValue)
                    end, settingInfo.description, currentY)
                    currentY = currentY - 30
                end
            else if settingInfo.type == "group" and settingInfo.settings then
                -- Create a subgroup
                self:CreateSubcategory(container, settingInfo.displayName, currentY)
                currentY = currentY - 20
                
                -- Recursively create controls for the subgroup
                currentY = self:CreateSettingsControls(container, moduleName, 
                    categoryName .. "." .. settingName, settingInfo.settings, currentY)
                
                currentY = currentY - 10
            end
        end
    end
    
    return currentY
}

-- Store a changed setting in the pending changes table
function ConfigurationUI:StoreChangedSetting(moduleName, settingPath, value)
    if not pendingChanges[moduleName] then
        pendingChanges[moduleName] = {}
    end
    
    pendingChanges[moduleName][settingPath] = value
    hasChanges = true
    
    -- Enable apply button
    if mainFrame and mainFrame.applyButton then
        mainFrame.applyButton:Enable(true)
    end
}

-- Save all pending changes
function ConfigurationUI:SaveChanges()
    if not hasChanges then return end
    
    for moduleName, changes in pairs(pendingChanges) do
        for settingPath, value in pairs(changes) do
            ConfigRegistry:SetSettingValue(moduleName, settingPath, value)
        end
    end
    
    -- Clear pending changes
    pendingChanges = {}
    hasChanges = false
    
    -- Disable apply button
    if mainFrame and mainFrame.applyButton then
        mainFrame.applyButton:Enable(false)
    end
    
    API.Print("Settings saved")
}

-- Revert all pending changes
function ConfigurationUI:RevertChanges()
    pendingChanges = {}
    hasChanges = false
    
    -- Disable apply button
    if mainFrame and mainFrame.applyButton then
        mainFrame.applyButton:Enable(false)
    end
}

-- Reload the UI to reflect changes
function ConfigurationUI:ReloadUI()
    -- Destroy existing tabs
    if tabGroup and tabGroup.tabs then
        for _, tab in ipairs(tabGroup.tabs) do
            tab.initialized = false
            if tab.button then
                tab.button:Hide()
            end
        end
    end
    
    -- Clear pages
    pages = {}
    
    -- Recreate tabs and content
    self:InitializeTabs()
}

-- Format category name for display
function ConfigurationUI:FormatCategoryName(name)
    if not name then return "Settings" end
    
    -- Convert camelCase to Title Case With Spaces
    local formatted = name:gsub("([A-Z])", " %1"):gsub("^%s", "")
    
    -- Capitalize first letter
    return formatted:gsub("^%l", string.upper)
}

-- Create a category header
function ConfigurationUI:CreateCategory(parent, name, posY)
    local category = parent:CreateFontString(nil, "OVERLAY")
    category:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    category:SetPoint("TOPLEFT", parent, "TOPLEFT", CONTENT_PADDING, posY)
    category:SetText(name)
    
    -- Add a line underneath
    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetHeight(2)
    line:SetPoint("TOPLEFT", category, "BOTTOMLEFT", 0, -2)
    line:SetPoint("RIGHT", parent, "RIGHT", -CONTENT_PADDING, 0)
    line:SetColorTexture(0.5, 0.5, 0.5, 0.6)
    
    return category
}

-- Create a subcategory header
function ConfigurationUI:CreateSubcategory(parent, name, posY)
    local subcategory = parent:CreateFontString(nil, "OVERLAY")
    subcategory:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    subcategory:SetPoint("TOPLEFT", parent, "TOPLEFT", CONTENT_PADDING + 10, posY)
    subcategory:SetText(name)
    
    return subcategory
}

-- Create a toggle (checkbox)
function ConfigurationUI:CreateToggle(parent, name, value, callback, tooltip, posY)
    local checkbox = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    checkbox:SetPoint("TOPLEFT", parent, "TOPLEFT", CONTENT_PADDING, posY)
    checkbox:SetChecked(value)
    checkbox.Text:SetText(name)
    checkbox.Text:SetFontObject("GameFontNormal")
    
    checkbox:SetScript("OnClick", function(self)
        callback(self:GetChecked())
    end)
    
    if tooltip then
        checkbox.tooltipText = tooltip
        checkbox:SetScript("OnEnter", function(self)
            if ConfigRegistry:GetSettings("ConfigurationUI").uiSettings.showTooltips then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(name, 1, 1, 1)
                GameTooltip:AddLine(tooltip, nil, nil, nil, true)
                GameTooltip:Show()
            end
        end)
        checkbox:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end
    
    return checkbox
}

-- Create a slider
function ConfigurationUI:CreateSlider(parent, name, value, min, max, step, callback, tooltip, posY)
    local sliderName = parent:CreateFontString(nil, "OVERLAY")
    sliderName:SetFont("Fonts\\FRIZQT__.TTF", 12)
    sliderName:SetPoint("TOPLEFT", parent, "TOPLEFT", CONTENT_PADDING, posY)
    sliderName:SetText(name)
    
    step = step or 1
    
    local slider = CreateFrame("Slider", nil, parent, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", sliderName, "BOTTOMLEFT", 0, -5)
    slider:SetWidth(parent:GetWidth() - CONTENT_PADDING * 2 - 50)
    slider:SetMinMaxValues(min, max)
    slider:SetValueStep(step)
    slider:SetValue(value or min)
    slider:SetObeyStepOnDrag(true)
    getglobal(slider:GetName() .. "Low"):SetText(min)
    getglobal(slider:GetName() .. "High"):SetText(max)
    
    local valueText = slider:CreateFontString(nil, "OVERLAY")
    valueText:SetFont("Fonts\\FRIZQT__.TTF", 10)
    valueText:SetPoint("LEFT", slider, "RIGHT", 10, 0)
    valueText:SetText(value)
    slider.valueText = valueText
    
    slider:SetScript("OnValueChanged", function(self, val)
        local displayValue = math.floor(val / step + 0.5) * step
        self.valueText:SetText(displayValue)
        callback(displayValue)
    end)
    
    if tooltip then
        slider.tooltipText = tooltip
        slider:SetScript("OnEnter", function(self)
            if ConfigRegistry:GetSettings("ConfigurationUI").uiSettings.showTooltips then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(name, 1, 1, 1)
                GameTooltip:AddLine(tooltip, nil, nil, nil, true)
                GameTooltip:Show()
            end
        end)
        slider:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end
    
    return slider
}

-- Create a dropdown
function ConfigurationUI:CreateDropdown(parent, name, value, options, callback, tooltip, posY)
    local dropdownName = parent:CreateFontString(nil, "OVERLAY")
    dropdownName:SetFont("Fonts\\FRIZQT__.TTF", 12)
    dropdownName:SetPoint("TOPLEFT", parent, "TOPLEFT", CONTENT_PADDING, posY)
    dropdownName:SetText(name)
    
    local dropdown = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPLEFT", dropdownName, "BOTTOMLEFT", -15, -5)
    UIDropDownMenu_SetWidth(dropdown, 200)
    
    -- Initialize dropdown
    UIDropDownMenu_Initialize(dropdown, function(self, level)
        local info = UIDropDownMenu_CreateInfo()
        for i, optionValue in ipairs(options) do
            info.text = optionValue
            info.value = optionValue
            info.checked = (optionValue == value)
            info.func = function()
                UIDropDownMenu_SetText(dropdown, optionValue)
                callback(optionValue)
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    
    UIDropDownMenu_SetText(dropdown, value)
    
    if tooltip then
        dropdown.tooltipText = tooltip
        dropdown:SetScript("OnEnter", function(self)
            if ConfigRegistry:GetSettings("ConfigurationUI").uiSettings.showTooltips then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(name, 1, 1, 1)
                GameTooltip:AddLine(tooltip, nil, nil, nil, true)
                GameTooltip:Show()
            end
        end)
        dropdown:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end
    
    return dropdown
}

-- Create a color picker
function ConfigurationUI:CreateColorPicker(parent, name, value, callback, tooltip, posY)
    local colorName = parent:CreateFontString(nil, "OVERLAY")
    colorName:SetFont("Fonts\\FRIZQT__.TTF", 12)
    colorName:SetPoint("TOPLEFT", parent, "TOPLEFT", CONTENT_PADDING, posY)
    colorName:SetText(name)
    
    local colorSwatch = CreateFrame("Button", nil, parent)
    colorSwatch:SetSize(24, 24)
    colorSwatch:SetPoint("TOPLEFT", colorName, "BOTTOMLEFT", 0, -5)
    
    local colorTexture = colorSwatch:CreateTexture(nil, "OVERLAY")
    colorTexture:SetAllPoints()
    colorTexture:SetColorTexture(value.r or 1, value.g or 1, value.b or 1, value.a or 1)
    
    local function UpdateColor(r, g, b, a)
        colorTexture:SetColorTexture(r, g, b, a or 1)
        callback({r = r, g = g, b = b, a = a or 1})
    end
    
    colorSwatch:SetScript("OnClick", function()
        local r, g, b, a = value.r or 1, value.g or 1, value.b or 1, value.a or 1
        ColorPickerFrame.func = function()
            local r, g, b = ColorPickerFrame:GetColorRGB()
            local a = 1 - OpacitySliderFrame:GetValue()
            UpdateColor(r, g, b, a)
        end
        
        ColorPickerFrame.opacityFunc = function()
            local r, g, b = ColorPickerFrame:GetColorRGB()
            local a = 1 - OpacitySliderFrame:GetValue()
            UpdateColor(r, g, b, a)
        end
        
        ColorPickerFrame.cancelFunc = function()
            UpdateColor(r, g, b, a)
        end
        
        ColorPickerFrame.hasOpacity = true
        ColorPickerFrame.opacity = 1 - a
        
        ColorPickerFrame:SetColorRGB(r, g, b)
        ColorPickerFrame:Show()
    end)
    
    if tooltip then
        colorSwatch.tooltipText = tooltip
        colorSwatch:SetScript("OnEnter", function(self)
            if ConfigRegistry:GetSettings("ConfigurationUI").uiSettings.showTooltips then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(name, 1, 1, 1)
                GameTooltip:AddLine(tooltip, nil, nil, nil, true)
                GameTooltip:Show()
            end
        end)
        colorSwatch:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end
    
    return colorSwatch
}

-- Create a number input field
function ConfigurationUI:CreateNumberInput(parent, name, value, callback, tooltip, posY)
    local inputName = parent:CreateFontString(nil, "OVERLAY")
    inputName:SetFont("Fonts\\FRIZQT__.TTF", 12)
    inputName:SetPoint("TOPLEFT", parent, "TOPLEFT", CONTENT_PADDING, posY)
    inputName:SetText(name)
    
    local inputBox = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    inputBox:SetSize(100, 20)
    inputBox:SetPoint("TOPLEFT", inputName, "BOTTOMLEFT", 0, -5)
    inputBox:SetAutoFocus(false)
    inputBox:SetText(tostring(value or 0))
    
    inputBox:SetScript("OnEnterPressed", function(self)
        local val = tonumber(self:GetText()) or 0
        callback(val)
        self:ClearFocus()
    end)
    
    inputBox:SetScript("OnEscapePressed", function(self)
        self:SetText(tostring(value or 0))
        self:ClearFocus()
    end)
    
    if tooltip then
        inputBox.tooltipText = tooltip
        inputBox:SetScript("OnEnter", function(self)
            if ConfigRegistry:GetSettings("ConfigurationUI").uiSettings.showTooltips then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(name, 1, 1, 1)
                GameTooltip:AddLine(tooltip, nil, nil, nil, true)
                GameTooltip:Show()
            end
        end)
        inputBox:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end
    
    return inputBox
}

-- Create a text input field
function ConfigurationUI:CreateTextInput(parent, name, value, callback, tooltip, posY)
    local inputName = parent:CreateFontString(nil, "OVERLAY")
    inputName:SetFont("Fonts\\FRIZQT__.TTF", 12)
    inputName:SetPoint("TOPLEFT", parent, "TOPLEFT", CONTENT_PADDING, posY)
    inputName:SetText(name)
    
    local inputBox = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    inputBox:SetSize(200, 20)
    inputBox:SetPoint("TOPLEFT", inputName, "BOTTOMLEFT", 0, -5)
    inputBox:SetAutoFocus(false)
    inputBox:SetText(value or "")
    
    inputBox:SetScript("OnEnterPressed", function(self)
        callback(self:GetText())
        self:ClearFocus()
    end)
    
    inputBox:SetScript("OnEscapePressed", function(self)
        self:SetText(value or "")
        self:ClearFocus()
    end)
    
    if tooltip then
        inputBox.tooltipText = tooltip
        inputBox:SetScript("OnEnter", function(self)
            if ConfigRegistry:GetSettings("ConfigurationUI").uiSettings.showTooltips then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(name, 1, 1, 1)
                GameTooltip:AddLine(tooltip, nil, nil, nil, true)
                GameTooltip:Show()
            end
        end)
        inputBox:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end
    
    return inputBox
}

-- Open a specific module's settings
function ConfigurationUI:OpenModuleSettings(moduleName)
    self:ShowUI()
    
    -- Find the appropriate tab
    for _, classModule in pairs(ModuleManager:GetClassModules()) do
        for _, spec in ipairs(classModule.specs or {}) do
            if spec.moduleKey == moduleName then
                -- First select the class tab
                self:SelectTab(classModule.className)
                
                -- Then select the spec
                self:SelectSpec(classModule.className, spec)
                return
            end
        end
    end
    
    -- If not found in class modules, check for core modules
    if moduleName == "RotationSimulator" then
        self:SelectTab("Combat Simulator")
    elseif moduleName == "PerformanceTracker" then
        self:SelectTab("Performance")
    else
        self:SelectTab("General")
    end
}

-- Toggle the UI visibility
function ConfigurationUI:ToggleUI()
    if mainFrame and mainFrame:IsShown() then
        self:HideUI()
    else
        self:ShowUI()
    end
}

-- Show the configuration UI
function ConfigurationUI:ShowUI()
    if not mainFrame then
        self:CreateMainFrame()
        self:InitializeTabs()
    end
    
    mainFrame:Show()
}

-- Hide the configuration UI
function ConfigurationUI:HideUI()
    if mainFrame then
        mainFrame:Hide()
        
        -- If there are unsaved changes, ask the user
        if hasChanges then
            StaticPopupDialogs["WINDRUNNER_UNSAVED_CHANGES"] = {
                text = "You have unsaved changes. Save them?",
                button1 = "Yes",
                button2 = "No",
                OnAccept = function()
                    self:SaveChanges()
                end,
                OnCancel = function()
                    self:RevertChanges()
                end,
                timeout = 0,
                whileDead = true,
                hideOnEscape = true,
                preferredIndex = 3
            }
            
            StaticPopup_Show("WINDRUNNER_UNSAVED_CHANGES")
        end
    end
}

-- Called when UI is closed
function ConfigurationUI:OnCloseUI()
    self:HideUI()
}

-- Return the module for loading
return ConfigurationUI