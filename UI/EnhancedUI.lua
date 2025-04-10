local addonName, WR = ...

-- EnhancedUI module
local EnhancedUI = {}
WR.UI = WR.UI or {}
WR.UI.Enhanced = EnhancedUI

-- UI constants and settings
local MEDIA_PATH = "Interface\\AddOns\\WindrunnerRotations\\Media\\"
local THEME = {
    background = {r = 0.1, g = 0.1, b = 0.1, a = 0.85},
    border = {r = 0.4, g = 0.4, b = 0.4, a = 0.9},
    header = {r = 0.15, g = 0.15, b = 0.15, a = 0.9},
    highlight = {r = 0.3, g = 0.5, b = 0.8, a = 1},
    text = {r = 1, g = 1, b = 1, a = 1},
    textDisabled = {r = 0.5, g = 0.5, b = 0.5, a = 1},
    success = {r = 0.2, g = 0.8, b = 0.2, a = 1},
    warning = {r = 0.8, g = 0.8, b = 0.2, a = 1},
    error = {r = 0.8, g = 0.2, b = 0.2, a = 1},
    button = {
        normal = {r = 0.2, g = 0.2, b = 0.2, a = 0.9},
        hover = {r = 0.25, g = 0.25, b = 0.25, a = 0.9},
        pressed = {r = 0.15, g = 0.15, b = 0.15, a = 0.9},
        disabled = {r = 0.1, g = 0.1, b = 0.1, a = 0.9}
    }
}

-- Frame references
local mainContainer, mainFrame, topBar, contentFrame, statusBar
local rotationDisplay, abilityQueue, statusDisplay, buttonPanel
local classIconFrame, specIconFrame, settingsButton, profileButton, toggleButton
local classColorBackground
local CLASSBAR_HEIGHT = 4

-- Frame dimensions
local UI_WIDTH = 350
local UI_HEIGHT = 450
local TOP_BAR_HEIGHT = 30
local ICON_SIZE = 24
local BORDER_PADDING = 8
local CONTENT_PADDING = 10
local STATUS_HEIGHT = 25
local BUTTON_HEIGHT = 28
local ROTATION_HEIGHT = 200

-- Icons and textures
local textures = {
    background = "Interface\\DialogFrame\\UI-DialogBox-Background",
    border = "Interface\\DialogFrame\\UI-DialogBox-Border",
    statusBar = "Interface\\TargetingFrame\\UI-StatusBar",
    buttonNormal = "Interface\\Buttons\\UI-Panel-Button-Up",
    buttonPushed = "Interface\\Buttons\\UI-Panel-Button-Down",
    buttonHighlight = "Interface\\Buttons\\UI-Panel-Button-Highlight",
    abilityBorder = "Interface\\Buttons\\UI-Quickslot2",
    abilityOverlay = "Interface\\Buttons\\CheckButtonHilight"
}

-- Class color lookup
local CLASS_COLORS = {
    WARRIOR = {r = 0.78, g = 0.61, b = 0.43},
    PALADIN = {r = 0.96, g = 0.55, b = 0.73},
    HUNTER = {r = 0.67, g = 0.83, b = 0.45},
    ROGUE = {r = 1.00, g = 0.96, b = 0.41},
    PRIEST = {r = 1.00, g = 1.00, b = 1.00},
    DEATHKNIGHT = {r = 0.77, g = 0.12, b = 0.23},
    SHAMAN = {r = 0.00, g = 0.44, b = 0.87},
    MAGE = {r = 0.41, g = 0.80, b = 0.94},
    WARLOCK = {r = 0.58, g = 0.51, b = 0.79},
    MONK = {r = 0.00, g = 1.00, b = 0.59},
    DRUID = {r = 1.00, g = 0.49, b = 0.04},
    DEMONHUNTER = {r = 0.64, g = 0.19, b = 0.79},
    EVOKER = {r = 0.20, g = 0.58, b = 0.50}
}

-- Ability queue visual elements
local abilityFrames = {}
local MAX_ABILITY_ICONS = 5

-- Animation group for UI elements
local animationGroups = {}

-- Initialize the Enhanced UI module
function EnhancedUI:Initialize()
    -- Create UI frames
    self:CreateMainContainer()
    self:CreateTopBar()
    self:CreateContentFrame()
    self:CreateRotationDisplay()
    self:CreateAbilityQueue()
    self:CreateStatusBar()
    self:CreateButtonPanel()
    
    -- Apply class-specific styling
    self:ApplyClassStyling()
    
    -- Initialize animations
    self:InitializeAnimations()
    
    -- Register events
    self:RegisterEvents()
    
    -- Hide the frame initially
    mainContainer:Hide()
    
    WR:Debug("Enhanced UI initialized")
end

-- Register for UI-related events
function EnhancedUI:RegisterEvents()
    -- Create event frame
    local eventFrame = CreateFrame("Frame")
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_SPECIALIZATION_CHANGED" then
            EnhancedUI:ApplyClassStyling()
        elseif event == "PLAYER_REGEN_DISABLED" then
            -- Combat started
            if WR.Config:Get("UI", "autoHideInCombat") then
                mainContainer:Hide()
            end
        elseif event == "PLAYER_REGEN_ENABLED" then
            -- Combat ended
            if WR.Config:Get("UI", "autoShowOutOfCombat") then
                mainContainer:Show()
            end
        end
    end)
    
    -- Register for relevant events
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
    eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    
    self.eventFrame = eventFrame
end

-- Create main container frame
function EnhancedUI:CreateMainContainer()
    -- Create the outer container
    mainContainer = CreateFrame("Frame", "WindrunnerRotationsEnhancedUI", UIParent, "BackdropTemplate")
    mainContainer:SetSize(UI_WIDTH, UI_HEIGHT)
    mainContainer:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    mainContainer:SetFrameStrata("MEDIUM")
    mainContainer:SetFrameLevel(10)
    mainContainer:SetClampedToScreen(true)
    mainContainer:SetMovable(true)
    mainContainer:EnableMouse(true)
    mainContainer:RegisterForDrag("LeftButton")
    mainContainer:SetScript("OnDragStart", function(self) 
        if not WR.Config:Get("UI", "locked") then
            self:StartMoving() 
        end
    end)
    mainContainer:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relativePoint, xOfs, yOfs = self:GetPoint()
        WR.Config:Set("UI", {
            point = point,
            relativePoint = relativePoint,
            x = xOfs,
            y = yOfs
        }, "enhancedPosition")
    end)
    
    -- Add backdrop
    mainContainer:SetBackdrop({
        bgFile = textures.background,
        edgeFile = textures.border,
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    mainContainer:SetBackdropColor(THEME.background.r, THEME.background.g, THEME.background.b, THEME.background.a)
    mainContainer:SetBackdropBorderColor(THEME.border.r, THEME.border.g, THEME.border.b, THEME.border.a)
    
    -- Create inner frame
    mainFrame = CreateFrame("Frame", nil, mainContainer)
    mainFrame:SetPoint("TOPLEFT", mainContainer, "TOPLEFT", BORDER_PADDING, -BORDER_PADDING)
    mainFrame:SetPoint("BOTTOMRIGHT", mainContainer, "BOTTOMRIGHT", -BORDER_PADDING, BORDER_PADDING)
    
    -- Create class color background bar
    classColorBackground = mainFrame:CreateTexture(nil, "BACKGROUND")
    classColorBackground:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 0, 0)
    classColorBackground:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", 0, 0)
    classColorBackground:SetHeight(CLASSBAR_HEIGHT)
    classColorBackground:SetColorTexture(0.4, 0.4, 0.8, 1.0) -- Default color, will be updated with class color
    
    -- Store references
    self.mainContainer = mainContainer
    self.mainFrame = mainFrame
    self.classColorBackground = classColorBackground
    
    -- Apply saved position if available
    self:LoadPosition()
end

-- Create top bar with title and controls
function EnhancedUI:CreateTopBar()
    -- Create top bar frame
    topBar = CreateFrame("Frame", nil, mainFrame, "BackdropTemplate")
    topBar:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 0, -CLASSBAR_HEIGHT)
    topBar:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", 0, -CLASSBAR_HEIGHT)
    topBar:SetHeight(TOP_BAR_HEIGHT)
    topBar:SetBackdrop({
        bgFile = textures.background,
        edgeFile = nil,
        tile = true,
        tileSize = 16,
        edgeSize = 0,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    topBar:SetBackdropColor(THEME.header.r, THEME.header.g, THEME.header.b, THEME.header.a)
    
    -- Add title text
    local titleText = topBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleText:SetPoint("LEFT", topBar, "LEFT", 8, 0)
    titleText:SetText("Windrunner Rotations")
    titleText:SetTextColor(THEME.text.r, THEME.text.g, THEME.text.b, THEME.text.a)
    
    -- Add class and spec icons
    classIconFrame = CreateFrame("Frame", nil, topBar)
    classIconFrame:SetSize(ICON_SIZE, ICON_SIZE)
    classIconFrame:SetPoint("RIGHT", topBar, "RIGHT", -28, 0)
    
    local classIcon = classIconFrame:CreateTexture(nil, "ARTWORK")
    classIcon:SetAllPoints(classIconFrame)
    classIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92) -- Trim the icon borders
    
    specIconFrame = CreateFrame("Frame", nil, topBar)
    specIconFrame:SetSize(ICON_SIZE, ICON_SIZE)
    specIconFrame:SetPoint("RIGHT", classIconFrame, "LEFT", -4, 0)
    
    local specIcon = specIconFrame:CreateTexture(nil, "ARTWORK")
    specIcon:SetAllPoints(specIconFrame)
    specIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92) -- Trim the icon borders
    
    -- Add close button
    local closeButton = CreateFrame("Button", nil, topBar)
    closeButton:SetSize(16, 16)
    closeButton:SetPoint("RIGHT", topBar, "RIGHT", -4, 0)
    closeButton:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
    closeButton:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
    closeButton:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight", "ADD")
    closeButton:SetScript("OnClick", function() mainContainer:Hide() end)
    
    -- Store references
    self.topBar = topBar
    self.titleText = titleText
    self.classIcon = classIcon
    self.specIcon = specIcon
    self.closeButton = closeButton
end

-- Create main content frame
function EnhancedUI:CreateContentFrame()
    -- Create content frame
    contentFrame = CreateFrame("Frame", nil, mainFrame)
    contentFrame:SetPoint("TOPLEFT", topBar, "BOTTOMLEFT", 0, 0)
    contentFrame:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", 0, 0)
    
    -- Store reference
    self.contentFrame = contentFrame
end

-- Create rotation display (current spell being cast, etc.)
function EnhancedUI:CreateRotationDisplay()
    -- Create rotation display frame
    rotationDisplay = CreateFrame("Frame", nil, contentFrame, "BackdropTemplate")
    rotationDisplay:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", CONTENT_PADDING, -CONTENT_PADDING)
    rotationDisplay:SetPoint("TOPRIGHT", contentFrame, "TOPRIGHT", -CONTENT_PADDING, -CONTENT_PADDING)
    rotationDisplay:SetHeight(ROTATION_HEIGHT)
    rotationDisplay:SetBackdrop({
        bgFile = textures.background,
        edgeFile = nil,
        tile = true,
        tileSize = 16,
        edgeSize = 0,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    rotationDisplay:SetBackdropColor(THEME.background.r+0.05, THEME.background.g+0.05, THEME.background.b+0.05, THEME.background.a)
    
    -- Create current spell display
    local currentSpellFrame = CreateFrame("Frame", nil, rotationDisplay)
    currentSpellFrame:SetPoint("TOP", rotationDisplay, "TOP", 0, -CONTENT_PADDING)
    currentSpellFrame:SetSize(64, 64)
    
    -- Create spell icon
    local spellIcon = currentSpellFrame:CreateTexture(nil, "ARTWORK")
    spellIcon:SetSize(48, 48)
    spellIcon:SetPoint("CENTER", currentSpellFrame, "CENTER", 0, 0)
    spellIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    spellIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92) -- Trim the icon borders
    
    -- Create spell border
    local spellBorder = currentSpellFrame:CreateTexture(nil, "OVERLAY")
    spellBorder:SetSize(64, 64)
    spellBorder:SetPoint("CENTER", spellIcon, "CENTER", 0, 0)
    spellBorder:SetTexture(textures.abilityBorder)
    
    -- Create spell name text
    local spellNameText = rotationDisplay:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    spellNameText:SetPoint("TOP", spellIcon, "BOTTOM", 0, -5)
    spellNameText:SetText("No Spell")
    spellNameText:SetTextColor(THEME.text.r, THEME.text.g, THEME.text.b, THEME.text.a)
    
    -- Create rotation type indicator
    local rotationTypeFrame = CreateFrame("Frame", nil, rotationDisplay)
    rotationTypeFrame:SetPoint("TOPLEFT", rotationDisplay, "TOPLEFT", CONTENT_PADDING, -CONTENT_PADDING)
    rotationTypeFrame:SetSize(100, 24)
    
    local rotationTypeText = rotationTypeFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    rotationTypeText:SetPoint("LEFT", rotationTypeFrame, "LEFT", 0, 0)
    rotationTypeText:SetText("Single Target")
    rotationTypeText:SetTextColor(THEME.text.r, THEME.text.g, THEME.text.b, THEME.text.a)
    
    -- Create cast bar
    local castBar = CreateFrame("StatusBar", nil, rotationDisplay)
    castBar:SetPoint("BOTTOM", rotationDisplay, "BOTTOM", 0, CONTENT_PADDING)
    castBar:SetSize(rotationDisplay:GetWidth() - (CONTENT_PADDING * 2), 16)
    castBar:SetStatusBarTexture(textures.statusBar)
    castBar:SetStatusBarColor(0.4, 0.4, 0.8, 0.8)
    castBar:SetMinMaxValues(0, 1)
    castBar:SetValue(0)
    
    local castBarBG = castBar:CreateTexture(nil, "BACKGROUND")
    castBarBG:SetAllPoints(castBar)
    castBarBG:SetTexture(textures.statusBar)
    castBarBG:SetVertexColor(0.2, 0.2, 0.2, 0.8)
    
    local castBarText = castBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    castBarText:SetPoint("CENTER", castBar, "CENTER", 0, 0)
    castBarText:SetText("Cast Time: 0.0s")
    
    -- Store references
    self.rotationDisplay = rotationDisplay
    self.currentSpellFrame = currentSpellFrame
    self.spellIcon = spellIcon
    self.spellBorder = spellBorder
    self.spellNameText = spellNameText
    self.rotationTypeFrame = rotationTypeFrame
    self.rotationTypeText = rotationTypeText
    self.castBar = castBar
    self.castBarText = castBarText
end

-- Create ability queue display
function EnhancedUI:CreateAbilityQueue()
    -- Create ability queue frame
    abilityQueue = CreateFrame("Frame", nil, contentFrame, "BackdropTemplate")
    abilityQueue:SetPoint("TOPLEFT", rotationDisplay, "BOTTOMLEFT", 0, -CONTENT_PADDING)
    abilityQueue:SetPoint("TOPRIGHT", rotationDisplay, "BOTTOMRIGHT", 0, -CONTENT_PADDING)
    abilityQueue:SetHeight(60)
    abilityQueue:SetBackdrop({
        bgFile = textures.background,
        edgeFile = nil,
        tile = true,
        tileSize = 16,
        edgeSize = 0,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    abilityQueue:SetBackdropColor(THEME.background.r+0.05, THEME.background.g+0.05, THEME.background.b+0.05, THEME.background.a)
    
    -- Create queue label
    local queueLabel = abilityQueue:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    queueLabel:SetPoint("TOPLEFT", abilityQueue, "TOPLEFT", CONTENT_PADDING, -5)
    queueLabel:SetText("Next Actions:")
    queueLabel:SetTextColor(THEME.text.r, THEME.text.g, THEME.text.b, THEME.text.a)
    
    -- Create ability icons
    local iconSize = 36
    local spacing = 8
    local startX = (abilityQueue:GetWidth() - ((iconSize + spacing) * MAX_ABILITY_ICONS - spacing)) / 2
    
    for i = 1, MAX_ABILITY_ICONS do
        local abilityFrame = CreateFrame("Frame", "WindrunnerRotationsAbilityFrame"..i, abilityQueue)
        abilityFrame:SetSize(iconSize, iconSize)
        abilityFrame:SetPoint("TOPLEFT", abilityQueue, "TOPLEFT", startX + (i-1) * (iconSize + spacing), -20)
        
        local abilityIcon = abilityFrame:CreateTexture(nil, "ARTWORK")
        abilityIcon:SetAllPoints(abilityFrame)
        abilityIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        abilityIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92) -- Trim the icon borders
        
        local abilityBorder = abilityFrame:CreateTexture(nil, "OVERLAY")
        abilityBorder:SetAllPoints(abilityFrame)
        abilityBorder:SetTexture(textures.abilityBorder)
        
        -- Store in table for updating later
        abilityFrames[i] = {
            frame = abilityFrame,
            icon = abilityIcon,
            border = abilityBorder
        }
    end
    
    -- Store reference
    self.abilityQueue = abilityQueue
    self.abilityFrames = abilityFrames
end

-- Create status bar with rotation info
function EnhancedUI:CreateStatusBar()
    -- Create status bar frame
    statusBar = CreateFrame("Frame", nil, contentFrame, "BackdropTemplate")
    statusBar:SetPoint("TOPLEFT", abilityQueue, "BOTTOMLEFT", 0, -CONTENT_PADDING)
    statusBar:SetPoint("TOPRIGHT", abilityQueue, "BOTTOMRIGHT", 0, -CONTENT_PADDING)
    statusBar:SetHeight(STATUS_HEIGHT)
    statusBar:SetBackdrop({
        bgFile = textures.background,
        edgeFile = nil,
        tile = true,
        tileSize = 16,
        edgeSize = 0,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    statusBar:SetBackdropColor(THEME.header.r, THEME.header.g, THEME.header.b, THEME.header.a)
    
    -- Create status display
    statusDisplay = CreateFrame("Frame", nil, statusBar)
    statusDisplay:SetPoint("TOPLEFT", statusBar, "TOPLEFT", 0, 0)
    statusDisplay:SetPoint("BOTTOMRIGHT", statusBar, "BOTTOMRIGHT", 0, 0)
    
    -- Status text 
    local statusText = statusDisplay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    statusText:SetPoint("LEFT", statusDisplay, "LEFT", CONTENT_PADDING, 0)
    statusText:SetText("Status: |cFFFF0000Disabled|r")
    
    -- Rotation speed text
    local speedText = statusDisplay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    speedText:SetPoint("RIGHT", statusDisplay, "RIGHT", -CONTENT_PADDING, 0)
    speedText:SetText("Speed: 100ms")
    
    -- Store references
    self.statusBar = statusBar
    self.statusDisplay = statusDisplay
    self.statusText = statusText
    self.speedText = speedText
end

-- Create button panel
function EnhancedUI:CreateButtonPanel()
    -- Create button panel
    buttonPanel = CreateFrame("Frame", nil, contentFrame)
    buttonPanel:SetPoint("TOPLEFT", statusBar, "BOTTOMLEFT", 0, -CONTENT_PADDING)
    buttonPanel:SetPoint("BOTTOMRIGHT", contentFrame, "BOTTOMRIGHT", 0, CONTENT_PADDING)
    
    -- Helper function to create buttons
    local function CreateButton(name, parent, width, height, point, relativeTo, relativePoint, x, y, text)
        local button = CreateFrame("Button", "WindrunnerRotationsButton"..name, parent, "BackdropTemplate")
        button:SetSize(width, height)
        button:SetPoint(point, relativeTo, relativePoint, x, y)
        
        -- Set backdrop
        button:SetBackdrop({
            bgFile = textures.background,
            edgeFile = textures.border,
            tile = true,
            tileSize = 16,
            edgeSize = 8,
            insets = { left = 2, right = 2, top = 2, bottom = 2 }
        })
        button:SetBackdropColor(THEME.button.normal.r, THEME.button.normal.g, THEME.button.normal.b, THEME.button.normal.a)
        button:SetBackdropBorderColor(THEME.border.r, THEME.border.g, THEME.border.b, THEME.border.a)
        
        -- Text
        local buttonText = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        buttonText:SetPoint("CENTER", button, "CENTER", 0, 0)
        buttonText:SetText(text)
        buttonText:SetTextColor(THEME.text.r, THEME.text.g, THEME.text.b, THEME.text.a)
        
        -- Button scripts
        button:SetScript("OnEnter", function(self)
            self:SetBackdropColor(THEME.button.hover.r, THEME.button.hover.g, THEME.button.hover.b, THEME.button.hover.a)
        end)
        
        button:SetScript("OnLeave", function(self)
            self:SetBackdropColor(THEME.button.normal.r, THEME.button.normal.g, THEME.button.normal.b, THEME.button.normal.a)
        end)
        
        button:SetScript("OnMouseDown", function(self)
            self:SetBackdropColor(THEME.button.pressed.r, THEME.button.pressed.g, THEME.button.pressed.b, THEME.button.pressed.a)
        end)
        
        button:SetScript("OnMouseUp", function(self)
            self:SetBackdropColor(THEME.button.hover.r, THEME.button.hover.g, THEME.button.hover.b, THEME.button.hover.a)
        end)
        
        return button, buttonText
    end
    
    -- Calculate button sizes and positioning
    local buttonWidth = (buttonPanel:GetWidth() - (CONTENT_PADDING * 3)) / 2
    local buttonHeight = BUTTON_HEIGHT
    
    -- Create toggle button
    toggleButton, toggleButtonText = CreateButton("Toggle", buttonPanel, buttonWidth, buttonHeight, 
        "TOPLEFT", buttonPanel, "TOPLEFT", CONTENT_PADDING, 0, "Enable")
    
    toggleButton:SetScript("OnClick", function()
        if WR.isRunning then
            WR:StopRotation()
            toggleButtonText:SetText("Enable")
            EnhancedUI:UpdateStatus(false)
        else
            WR:StartRotation()
            toggleButtonText:SetText("Disable")
            EnhancedUI:UpdateStatus(true)
        end
    end)
    
    -- Create settings button
    settingsButton, settingsButtonText = CreateButton("Settings", buttonPanel, buttonWidth, buttonHeight, 
        "TOPRIGHT", buttonPanel, "TOPRIGHT", -CONTENT_PADDING, 0, "Settings")
    
    settingsButton:SetScript("OnClick", function()
        -- Toggle settings panel
        if WR.UI.SettingsUI then
            WR.UI.SettingsUI:Toggle()
        end
    end)
    
    -- Create profile button
    profileButton, profileButtonText = CreateButton("Profile", buttonPanel, buttonWidth, buttonHeight, 
        "TOPLEFT", toggleButton, "BOTTOMLEFT", 0, -CONTENT_PADDING, "Profiles")
    
    profileButton:SetScript("OnClick", function()
        -- Toggle profile panel
        if WR.UI.Profile then
            WR.UI.Profile:Toggle()
        end
    end)
    
    -- Create mode button
    modeButton, modeButtonText = CreateButton("Mode", buttonPanel, buttonWidth, buttonHeight, 
        "TOPRIGHT", settingsButton, "BOTTOMRIGHT", 0, -CONTENT_PADDING, "Single Target")
    
    modeButton:SetScript("OnClick", function()
        -- Toggle between rotation modes
        if modeButtonText:GetText() == "Single Target" then
            modeButtonText:SetText("AoE")
            rotationTypeText:SetText("Area of Effect")
            WR.Config:Set("rotationMode", "aoe")
        else
            modeButtonText:SetText("Single Target")
            rotationTypeText:SetText("Single Target")
            WR.Config:Set("rotationMode", "single")
        end
    end)
    
    -- Create quick toggle checkboxes
    local function CreateToggleCheck(name, parent, point, relativeTo, relativePoint, x, y, label, configKey)
        local check = CreateFrame("CheckButton", "WindrunnerRotationsCheck"..name, parent, "ChatConfigCheckButtonTemplate")
        check:SetPoint(point, relativeTo, relativePoint, x, y)
        getglobal(check:GetName().."Text"):SetText(label)
        
        check:SetChecked(WR.Config:Get(configKey))
        check:SetScript("OnClick", function(self)
            local checked = self:GetChecked()
            WR.Config:Set(configKey, checked)
        end)
        
        return check
    end
    
    -- Calculate positions for checkboxes
    local checkY = -CONTENT_PADDING * 2 - BUTTON_HEIGHT * 2
    
    -- Create toggle checkboxes
    local interruptCheck = CreateToggleCheck("Interrupts", buttonPanel, "TOPLEFT", buttonPanel, "TOPLEFT", 
        CONTENT_PADDING, checkY, "Interrupts", "enableInterrupts")
    
    local cooldownsCheck = CreateToggleCheck("Cooldowns", buttonPanel, "TOPLEFT", interruptCheck, "TOPRIGHT", 
        buttonWidth / 2, 0, "Cooldowns", "enableCooldowns")
    
    local defensivesCheck = CreateToggleCheck("Defensives", buttonPanel, "TOPLEFT", buttonPanel, "TOPLEFT", 
        CONTENT_PADDING, checkY - 25, "Defensives", "enableDefensives")
    
    local awarenessCheck = CreateToggleCheck("Awareness", buttonPanel, "TOPLEFT", defensivesCheck, "TOPRIGHT", 
        buttonWidth / 2, 0, "M+ Awareness", "enableDungeonAwareness")
    
    -- Store references
    self.buttonPanel = buttonPanel
    self.toggleButton = toggleButton
    self.toggleButtonText = toggleButtonText
    self.settingsButton = settingsButton
    self.profileButton = profileButton
    self.modeButton = modeButton
    self.modeButtonText = modeButtonText
    self.interruptCheck = interruptCheck
    self.cooldownsCheck = cooldownsCheck
    self.defensivesCheck = defensivesCheck
    self.awarenessCheck = awarenessCheck
end

-- Apply class-specific styling
function EnhancedUI:ApplyClassStyling()
    local _, className = UnitClass("player")
    local classColor = CLASS_COLORS[className] or CLASS_COLORS.DEFAULT
    
    -- Update class color bar
    classColorBackground:SetColorTexture(classColor.r, classColor.g, classColor.b, 1.0)
    
    -- Update class icon
    local classCoords = CLASS_ICON_TCOORDS[className]
    self.classIcon:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES")
    if classCoords then
        self.classIcon:SetTexCoord(unpack(classCoords))
    else
        self.classIcon:SetTexCoord(0, 1, 0, 1)
    end
    
    -- Update spec icon
    local currentSpec = GetSpecialization()
    if currentSpec then
        local _, name, description, icon = GetSpecializationInfo(currentSpec)
        if icon then
            self.specIcon:SetTexture(icon)
        end
    end
    
    -- Update cast bar color to match class
    self.castBar:SetStatusBarColor(classColor.r, classColor.g, classColor.b, 0.8)
end

-- Initialize animations
function EnhancedUI:InitializeAnimations()
    -- Main container fade in animation
    local fadeIn = mainContainer:CreateAnimationGroup()
    local alpha1 = fadeIn:CreateAnimation("Alpha")
    alpha1:SetFromAlpha(0)
    alpha1:SetToAlpha(1)
    alpha1:SetDuration(0.3)
    alpha1:SetSmoothing("OUT")
    
    -- Main container fade out animation
    local fadeOut = mainContainer:CreateAnimationGroup()
    local alpha2 = fadeOut:CreateAnimation("Alpha")
    alpha2:SetFromAlpha(1)
    alpha2:SetToAlpha(0)
    alpha2:SetDuration(0.3)
    alpha2:SetSmoothing("IN")
    fadeOut:SetScript("OnFinished", function() mainContainer:Hide() end)
    
    -- Current spell highlight animation
    local spellHighlight = self.currentSpellFrame:CreateAnimationGroup()
    spellHighlight:SetLooping("BOUNCE")
    
    local scale1 = spellHighlight:CreateAnimation("Scale")
    scale1:SetScaleFrom(1, 1)
    scale1:SetScaleTo(1.05, 1.05)
    scale1:SetDuration(0.5)
    scale1:SetSmoothing("IN_OUT")
    
    -- Store animation groups
    animationGroups.fadeIn = fadeIn
    animationGroups.fadeOut = fadeOut
    animationGroups.spellHighlight = spellHighlight
    
    -- Start appropriate animations
    spellHighlight:Play()
end

-- Load saved position
function EnhancedUI:LoadPosition()
    local position = WR.Config:Get("UI", "enhancedPosition")
    if position then
        mainContainer:ClearAllPoints()
        mainContainer:SetPoint(position.point or "CENTER", UIParent, position.relativePoint or "CENTER", position.x or 0, position.y or 0)
    end
    
    -- Apply saved scale
    local scale = WR.Config:Get("UI", "scale") or 1.0
    mainContainer:SetScale(scale)
end

-- Update queue display
function EnhancedUI:UpdateQueueDisplay(queue)
    if not queue then return end
    
    for i = 1, MAX_ABILITY_ICONS do
        local frame = abilityFrames[i]
        local spellID = queue[i]
        
        if spellID then
            local name, _, icon = GetSpellInfo(spellID)
            if icon then
                frame.icon:SetTexture(icon)
                frame.frame:Show()
            else
                frame.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
                frame.frame:Show()
            end
        else
            frame.frame:Hide()
        end
    end
end

-- Update current spell display
function EnhancedUI:UpdateCurrentSpell(spellID)
    if not spellID then
        self.spellIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        self.spellNameText:SetText("No Spell")
        self.castBar:SetValue(0)
        self.castBarText:SetText("Cast Time: 0.0s")
        return
    end
    
    local name, _, icon, castTime = GetSpellInfo(spellID)
    if icon then
        self.spellIcon:SetTexture(icon)
    else
        self.spellIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    end
    
    if name then
        self.spellNameText:SetText(name)
    else
        self.spellNameText:SetText("Unknown Spell")
    end
    
    -- Update cast bar
    if castTime and castTime > 0 then
        -- For instant casts or channeled spells, show GCD instead
        local gcdStart, gcdDuration = GetSpellCooldown(61304) -- GCD spell ID
        local timeLeft = 0
        
        if gcdStart > 0 and gcdDuration > 0 then
            timeLeft = gcdStart + gcdDuration - GetTime()
            timeLeft = math.max(0, math.min(gcdDuration, timeLeft))
            self.castBar:SetMinMaxValues(0, gcdDuration)
            self.castBar:SetValue(timeLeft)
            self.castBarText:SetText(string.format("GCD: %.1fs", timeLeft))
        else
            self.castBar:SetValue(0)
            self.castBarText:SetText("Ready")
        end
    else
        self.castBar:SetValue(0)
        self.castBarText:SetText("Instant")
    end
end

-- Update status display
function EnhancedUI:UpdateStatus(isRunning)
    if isRunning then
        self.statusText:SetText("Status: |cFF00FF00Running|r")
    else
        self.statusText:SetText("Status: |cFFFF0000Disabled|r")
    end
    
    -- Update rotation speed display
    local speed = WR.Config:Get("rotationSpeed") or 100
    self.speedText:SetText(string.format("Speed: %dms", speed))
end

-- Update rotation mode display
function EnhancedUI:UpdateRotationMode(mode)
    if mode == "aoe" then
        self.rotationTypeText:SetText("Area of Effect")
        self.modeButtonText:SetText("AoE")
    else
        self.rotationTypeText:SetText("Single Target")
        self.modeButtonText:SetText("Single Target")
    end
end

-- Show the enhanced UI
function EnhancedUI:Show()
    mainContainer:SetAlpha(0)
    mainContainer:Show()
    animationGroups.fadeIn:Play()
    
    self:UpdateStatus(WR.isRunning)
    
    if WR.isRunning then
        self.toggleButtonText:SetText("Disable")
    else
        self.toggleButtonText:SetText("Enable")
    end
    
    -- Update rotation mode
    local mode = WR.Config:Get("rotationMode") or "single"
    self:UpdateRotationMode(mode)
    
    -- Update checkbox states
    self.interruptCheck:SetChecked(WR.Config:Get("enableInterrupts"))
    self.cooldownsCheck:SetChecked(WR.Config:Get("enableCooldowns"))
    self.defensivesCheck:SetChecked(WR.Config:Get("enableDefensives"))
    self.awarenessCheck:SetChecked(WR.Config:Get("enableDungeonAwareness"))
end

-- Hide the enhanced UI
function EnhancedUI:Hide()
    animationGroups.fadeOut:Play()
end

-- Toggle the enhanced UI visibility
function EnhancedUI:Toggle()
    if mainContainer:IsShown() then
        self:Hide()
    else
        self:Show()
    end
end

-- Register for rotation updates
function EnhancedUI:OnRotationUpdate(currentSpellID, queue)
    self:UpdateCurrentSpell(currentSpellID)
    self:UpdateQueueDisplay(queue)
end

-- Initialize when addon loads
EnhancedUI:Initialize()

return EnhancedUI