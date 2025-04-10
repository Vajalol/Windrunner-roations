local addonName, WR = ...

-- Main UI module
WR.UI = WR.UI or {}

-- UI constants
local UI_SCALE = 1.0
local HEADER_HEIGHT = 24
local BUTTON_HEIGHT = 30
local BUTTON_WIDTH = 100
local ICON_SIZE = 24
local SPACING = 5
local MAIN_WIDTH = 300
local MAIN_HEIGHT = 400
local CLASS_COLORS = {
    MAGE = "69CCF0",
    HUNTER = "ABD473",
    WARRIOR = "C79C6E",
    DEMONHUNTER = "A330C9",
    DEFAULT = "FFFFFF"
}

-- Frame references
local mainFrame, headerFrame, contentFrame, footerFrame
local toggleButton, settingsButton, profileButton
local actionButtons = {}
local statusText, versionText

-- Initialize the UI
function WR.UI:Initialize()
    -- Create the main UI container
    self:CreateMainFrame()
    
    -- Create the header section
    self:CreateHeader()
    
    -- Create the content area
    self:CreateContent()
    
    -- Create the footer
    self:CreateFooter()
    
    -- Create the settings panel
    self:CreateSettings()
    
    -- Create the profiles panel
    self:CreateProfiles()
    
    -- Create action buttons
    self:CreateActionButtons()
    
    -- Setup class-specific styling
    self:ApplyClassStyling()
    
    -- Register for events
    self:RegisterEvents()
    
    -- Apply saved position and visibility
    self:LoadPosition()
    
    -- Initially hide the main window
    mainFrame:Hide()
    
    WR:Debug("UI initialized")
end

-- Create the main frame container
function WR.UI:CreateMainFrame()
    -- Create main frame
    mainFrame = CreateFrame("Frame", "WindrunnerRotationsFrame", UIParent, "BackdropTemplate")
    mainFrame:SetSize(MAIN_WIDTH, MAIN_HEIGHT)
    mainFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    mainFrame:SetFrameStrata("MEDIUM")
    mainFrame:SetFrameLevel(10)
    mainFrame:SetClampedToScreen(true)
    mainFrame:SetMovable(true)
    mainFrame:EnableMouse(true)
    mainFrame:RegisterForDrag("LeftButton")
    mainFrame:SetScript("OnDragStart", mainFrame.StartMoving)
    mainFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relativePoint, xOfs, yOfs = self:GetPoint()
        WR.Config:Set("UI", {
            point = point,
            relativePoint = relativePoint,
            x = xOfs,
            y = yOfs
        }, "position")
    end)
    
    -- Set backdrop
    mainFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    
    -- Store reference
    self.mainFrame = mainFrame
end

-- Create the header section
function WR.UI:CreateHeader()
    -- Create header frame
    headerFrame = CreateFrame("Frame", nil, mainFrame)
    headerFrame:SetSize(MAIN_WIDTH - 22, HEADER_HEIGHT)
    headerFrame:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 11, -12)
    
    -- Title text
    local titleText = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleText:SetPoint("LEFT", headerFrame, "LEFT", 5, 0)
    titleText:SetText("Windrunner Rotations")
    
    -- Close button
    local closeButton = CreateFrame("Button", nil, headerFrame, "UIPanelCloseButton")
    closeButton:SetPoint("RIGHT", headerFrame, "RIGHT", 5, 0)
    closeButton:SetScript("OnClick", function() mainFrame:Hide() end)
    
    -- Store references
    self.headerFrame = headerFrame
    self.titleText = titleText
end

-- Create the content area
function WR.UI:CreateContent()
    -- Create content frame
    contentFrame = CreateFrame("Frame", nil, mainFrame)
    contentFrame:SetSize(MAIN_WIDTH - 22, MAIN_HEIGHT - HEADER_HEIGHT - 40)
    contentFrame:SetPoint("TOPLEFT", headerFrame, "BOTTOMLEFT", 0, -5)
    
    -- Class and spec info
    local classIcon = contentFrame:CreateTexture(nil, "ARTWORK")
    classIcon:SetSize(ICON_SIZE, ICON_SIZE)
    classIcon:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 5, -5)
    
    local classText = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    classText:SetPoint("LEFT", classIcon, "RIGHT", 5, 0)
    classText:SetText("Class: Unknown")
    
    local specIcon = contentFrame:CreateTexture(nil, "ARTWORK")
    specIcon:SetSize(ICON_SIZE, ICON_SIZE)
    specIcon:SetPoint("TOPLEFT", classIcon, "BOTTOMLEFT", 0, -5)
    
    local specText = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    specText:SetPoint("LEFT", specIcon, "RIGHT", 5, 0)
    specText:SetText("Spec: Unknown")
    
    -- Status section
    local statusLabel = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    statusLabel:SetPoint("TOPLEFT", specIcon, "BOTTOMLEFT", 0, -10)
    statusLabel:SetText("Status:")
    
    statusText = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    statusText:SetPoint("LEFT", statusLabel, "RIGHT", 5, 0)
    statusText:SetText("|cFFFF0000Disabled|r")
    
    -- Create divider
    local divider = contentFrame:CreateTexture(nil, "ARTWORK")
    divider:SetSize(MAIN_WIDTH - 30, 1)
    divider:SetPoint("TOPLEFT", statusLabel, "BOTTOMLEFT", 0, -5)
    divider:SetColorTexture(0.6, 0.6, 0.6, 0.8)
    
    -- Store references
    self.contentFrame = contentFrame
    self.classIcon = classIcon
    self.classText = classText
    self.specIcon = specIcon
    self.specText = specText
    self.statusText = statusText
    self.divider = divider
    
    -- Update class and spec info
    self:UpdateClassSpecInfo()
end

-- Create the footer area
function WR.UI:CreateFooter()
    -- Create footer frame
    footerFrame = CreateFrame("Frame", nil, mainFrame)
    footerFrame:SetSize(MAIN_WIDTH - 22, 30)
    footerFrame:SetPoint("BOTTOMLEFT", mainFrame, "BOTTOMLEFT", 11, 11)
    
    -- Version text
    versionText = footerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    versionText:SetPoint("LEFT", footerFrame, "LEFT", 5, 0)
    versionText:SetText("v" .. WR.version)
    
    -- Store references
    self.footerFrame = footerFrame
    self.versionText = versionText
end

-- Create action buttons
function WR.UI:CreateActionButtons()
    -- Container for toggle buttons
    local buttonContainer = CreateFrame("Frame", nil, contentFrame)
    buttonContainer:SetSize(MAIN_WIDTH - 30, BUTTON_HEIGHT)
    buttonContainer:SetPoint("TOPLEFT", self.divider, "BOTTOMLEFT", 0, -10)
    
    -- Toggle rotation button
    local toggleButton = CreateFrame("Button", nil, buttonContainer, "UIPanelButtonTemplate")
    toggleButton:SetSize(BUTTON_WIDTH, BUTTON_HEIGHT)
    toggleButton:SetPoint("LEFT", buttonContainer, "LEFT", 0, 0)
    toggleButton:SetText("Enable")
    toggleButton:SetScript("OnClick", function()
        if WR.isRunning then
            WR:StopRotation()
            toggleButton:SetText("Enable")
            self:UpdateStatus()
        else
            WR:StartRotation()
            toggleButton:SetText("Disable")
            self:UpdateStatus()
        end
    end)
    
    -- Settings button
    local settingsButton = CreateFrame("Button", nil, buttonContainer, "UIPanelButtonTemplate")
    settingsButton:SetSize(BUTTON_WIDTH, BUTTON_HEIGHT)
    settingsButton:SetPoint("LEFT", toggleButton, "RIGHT", SPACING, 0)
    settingsButton:SetText("Settings")
    settingsButton:SetScript("OnClick", function()
        self:ToggleSettings()
    end)
    
    -- Profiles button
    local profileButton = CreateFrame("Button", nil, buttonContainer, "UIPanelButtonTemplate")
    profileButton:SetSize(BUTTON_WIDTH, BUTTON_HEIGHT)
    profileButton:SetPoint("TOP", toggleButton, "BOTTOM", 0, -SPACING)
    profileButton:SetText("Profiles")
    profileButton:SetScript("OnClick", function()
        self:ToggleProfiles()
    end)
    
    -- Create toggle buttons
    local toggleContainer = CreateFrame("Frame", nil, contentFrame)
    toggleContainer:SetSize(MAIN_WIDTH - 30, 120)
    toggleContainer:SetPoint("TOPLEFT", buttonContainer, "BOTTOMLEFT", 0, -50)
    
    local function CreateToggleButton(name, text, configKey, parent, anchorFrame, anchorPoint, relativePoint, x, y)
        local button = CreateFrame("CheckButton", "WindrunnerRotationsToggle" .. name, parent, "UICheckButtonTemplate")
        button:SetPoint(anchorPoint, anchorFrame, relativePoint, x, y)
        button.text:SetText(text)
        button:SetChecked(WR.Config:Get(configKey))
        button:SetScript("OnClick", function(self)
            local checked = self:GetChecked()
            WR.Config:Set(configKey, checked)
            WR:Debug(configKey .. " set to " .. tostring(checked))
        end)
        
        actionButtons[configKey] = button
        return button
    end
    
    -- Interrupts toggle
    local interruptButton = CreateToggleButton("Interrupts", "Interrupts", "enableInterrupts", 
        toggleContainer, toggleContainer, "TOPLEFT", "TOPLEFT", 0, 0)
    
    -- Cooldowns toggle
    local cooldownsButton = CreateToggleButton("Cooldowns", "Cooldowns", "enableCooldowns", 
        toggleContainer, interruptButton, "TOPLEFT", "BOTTOMLEFT", 0, -5)
    
    -- AoE toggle
    local aoeButton = CreateToggleButton("AoE", "AoE", "enableAOE", 
        toggleContainer, cooldownsButton, "TOPLEFT", "BOTTOMLEFT", 0, -5)
    
    -- Defensives toggle
    local defensivesButton = CreateToggleButton("Defensives", "Defensives", "enableDefensives", 
        toggleContainer, interruptButton, "TOPRIGHT", "TOPLEFT", 100, 0)
    
    -- Auto-targeting toggle
    local targetingButton = CreateToggleButton("AutoTarget", "Auto Target", "enableAutoTargeting", 
        toggleContainer, defensivesButton, "TOPLEFT", "BOTTOMLEFT", 0, -5)
    
    -- Dungeon awareness toggle
    local awarenessButton = CreateToggleButton("DungeonAwareness", "Dungeon Aware", "enableDungeonAwareness", 
        toggleContainer, targetingButton, "TOPLEFT", "BOTTOMLEFT", 0, -5)
    
    -- Store references
    self.toggleButton = toggleButton
    self.settingsButton = settingsButton
    self.profileButton = profileButton
}

-- Create the settings panel
function WR.UI:CreateSettings()
    -- Create settings frame
    local settingsFrame = CreateFrame("Frame", "WindrunnerRotationsSettingsFrame", UIParent, "BackdropTemplate")
    settingsFrame:SetSize(MAIN_WIDTH, MAIN_HEIGHT)
    settingsFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    settingsFrame:SetFrameStrata("MEDIUM")
    settingsFrame:SetFrameLevel(20)
    settingsFrame:SetClampedToScreen(true)
    settingsFrame:SetMovable(true)
    settingsFrame:EnableMouse(true)
    settingsFrame:RegisterForDrag("LeftButton")
    settingsFrame:SetScript("OnDragStart", settingsFrame.StartMoving)
    settingsFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
    end)
    
    -- Set backdrop
    settingsFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    
    -- Create header
    local settingsHeader = CreateFrame("Frame", nil, settingsFrame)
    settingsHeader:SetSize(MAIN_WIDTH - 22, HEADER_HEIGHT)
    settingsHeader:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 11, -12)
    
    -- Title text
    local settingsTitleText = settingsHeader:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    settingsTitleText:SetPoint("LEFT", settingsHeader, "LEFT", 5, 0)
    settingsTitleText:SetText("Settings")
    
    -- Close button
    local settingsCloseButton = CreateFrame("Button", nil, settingsHeader, "UIPanelCloseButton")
    settingsCloseButton:SetPoint("RIGHT", settingsHeader, "RIGHT", 5, 0)
    settingsCloseButton:SetScript("OnClick", function() settingsFrame:Hide() end)
    
    -- Content area
    local settingsContent = CreateFrame("Frame", nil, settingsFrame)
    settingsContent:SetSize(MAIN_WIDTH - 40, MAIN_HEIGHT - 60)
    settingsContent:SetPoint("TOP", settingsHeader, "BOTTOM", 0, -10)
    
    -- Rotation Speed slider
    local speedLabel = settingsContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    speedLabel:SetPoint("TOPLEFT", settingsContent, "TOPLEFT", 10, -10)
    speedLabel:SetText("Rotation Speed (ms):")
    
    local speedSlider = CreateFrame("Slider", "WindrunnerRotationsSpeedSlider", settingsContent, "OptionsSliderTemplate")
    speedSlider:SetWidth(MAIN_WIDTH - 80)
    speedSlider:SetHeight(16)
    speedSlider:SetPoint("TOP", speedLabel, "BOTTOM", 0, -15)
    speedSlider:SetOrientation("HORIZONTAL")
    speedSlider:SetMinMaxValues(10, 200)
    speedSlider:SetValue(WR.Config:Get("rotationSpeed") or 100)
    speedSlider:SetValueStep(5)
    speedSlider:SetObeyStepOnDrag(true)
    
    WindrunnerRotationsSpeedSliderLow:SetText("10")
    WindrunnerRotationsSpeedSliderHigh:SetText("200")
    WindrunnerRotationsSpeedSliderText:SetText(WR.Config:Get("rotationSpeed") or "100")
    
    speedSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value)
        WindrunnerRotationsSpeedSliderText:SetText(value)
        WR.Config:Set("rotationSpeed", value)
        WR.Rotation:SetRotationInterval(value / 1000)
    end)
    
    -- UI Scale slider
    local scaleLabel = settingsContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    scaleLabel:SetPoint("TOPLEFT", speedSlider, "BOTTOMLEFT", 0, -25)
    scaleLabel:SetText("UI Scale:")
    
    local scaleSlider = CreateFrame("Slider", "WindrunnerRotationsScaleSlider", settingsContent, "OptionsSliderTemplate")
    scaleSlider:SetWidth(MAIN_WIDTH - 80)
    scaleSlider:SetHeight(16)
    scaleSlider:SetPoint("TOP", scaleLabel, "BOTTOM", 0, -15)
    scaleSlider:SetOrientation("HORIZONTAL")
    scaleSlider:SetMinMaxValues(0.5, 2.0)
    scaleSlider:SetValue(WR.Config:Get("UI", "scale") or 1.0)
    scaleSlider:SetValueStep(0.05)
    scaleSlider:SetObeyStepOnDrag(true)
    
    WindrunnerRotationsScaleSliderLow:SetText("0.5")
    WindrunnerRotationsScaleSliderHigh:SetText("2.0")
    WindrunnerRotationsScaleSliderText:SetText(WR.Config:Get("UI", "scale") or "1.0")
    
    scaleSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value * 100) / 100 -- Round to 2 decimal places
        WindrunnerRotationsScaleSliderText:SetText(string.format("%.2f", value))
        WR.Config:Set("UI", value, "scale")
        WR.UI.mainFrame:SetScale(value)
    end)
    
    -- Key Bindings section
    local bindingsLabel = settingsContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    bindingsLabel:SetPoint("TOPLEFT", scaleSlider, "BOTTOMLEFT", 0, -25)
    bindingsLabel:SetText("Key Bindings:")
    
    -- Toggle rotation binding
    local toggleBindingLabel = settingsContent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    toggleBindingLabel:SetPoint("TOPLEFT", bindingsLabel, "BOTTOMLEFT", 10, -10)
    toggleBindingLabel:SetText("Toggle Rotation:")
    
    local toggleBindingButton = CreateFrame("Button", "WindrunnerRotationsToggleBinding", settingsContent, "UIPanelButtonTemplate")
    toggleBindingButton:SetSize(100, 22)
    toggleBindingButton:SetPoint("LEFT", toggleBindingLabel, "RIGHT", 10, 0)
    toggleBindingButton:SetText(WR.Config:Get("keybinds", "toggle") or "Not Set")
    toggleBindingButton:SetScript("OnClick", function(self)
        self:SetText("Press a key...")
        self:EnableKeyboard(true)
        self:SetScript("OnKeyDown", function(self, key)
            WR.Config:Set("keybinds", key, "toggle")
            self:SetText(key)
            self:EnableKeyboard(false)
            self:SetScript("OnKeyDown", nil)
        end)
    end)
    
    -- Cooldowns binding
    local cooldownsBindingLabel = settingsContent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    cooldownsBindingLabel:SetPoint("TOPLEFT", toggleBindingLabel, "BOTTOMLEFT", 0, -10)
    cooldownsBindingLabel:SetText("Toggle Cooldowns:")
    
    local cooldownsBindingButton = CreateFrame("Button", "WindrunnerRotationsCooldownsBinding", settingsContent, "UIPanelButtonTemplate")
    cooldownsBindingButton:SetSize(100, 22)
    cooldownsBindingButton:SetPoint("LEFT", cooldownsBindingLabel, "RIGHT", 10, 0)
    cooldownsBindingButton:SetText(WR.Config:Get("keybinds", "cooldowns") or "Not Set")
    cooldownsBindingButton:SetScript("OnClick", function(self)
        self:SetText("Press a key...")
        self:EnableKeyboard(true)
        self:SetScript("OnKeyDown", function(self, key)
            WR.Config:Set("keybinds", key, "cooldowns")
            self:SetText(key)
            self:EnableKeyboard(false)
            self:SetScript("OnKeyDown", nil)
        end)
    end)
    
    -- AOE binding
    local aoeBindingLabel = settingsContent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    aoeBindingLabel:SetPoint("TOPLEFT", cooldownsBindingLabel, "BOTTOMLEFT", 0, -10)
    aoeBindingLabel:SetText("Toggle AoE:")
    
    local aoeBindingButton = CreateFrame("Button", "WindrunnerRotationsAOEBinding", settingsContent, "UIPanelButtonTemplate")
    aoeBindingButton:SetSize(100, 22)
    aoeBindingButton:SetPoint("LEFT", aoeBindingLabel, "RIGHT", 10, 0)
    aoeBindingButton:SetText(WR.Config:Get("keybinds", "aoe") or "Not Set")
    aoeBindingButton:SetScript("OnClick", function(self)
        self:SetText("Press a key...")
        self:EnableKeyboard(true)
        self:SetScript("OnKeyDown", function(self, key)
            WR.Config:Set("keybinds", key, "aoe")
            self:SetText(key)
            self:EnableKeyboard(false)
            self:SetScript("OnKeyDown", nil)
        end)
    end)
    
    -- Footer with buttons
    local settingsFooter = CreateFrame("Frame", nil, settingsFrame)
    settingsFooter:SetSize(MAIN_WIDTH - 22, 30)
    settingsFooter:SetPoint("BOTTOM", settingsFrame, "BOTTOM", 0, 15)
    
    -- Reset button
    local resetButton = CreateFrame("Button", nil, settingsFooter, "UIPanelButtonTemplate")
    resetButton:SetSize(BUTTON_WIDTH, BUTTON_HEIGHT)
    resetButton:SetPoint("BOTTOMLEFT", settingsFooter, "BOTTOMLEFT", 5, 0)
    resetButton:SetText("Reset")
    resetButton:SetScript("OnClick", function()
        -- Reset settings to defaults
        WR.Config:Set("rotationSpeed", 100)
        WR.Config:Set("UI", 1.0, "scale")
        WR.Config:Set("keybinds", nil, "toggle")
        WR.Config:Set("keybinds", nil, "cooldowns")
        WR.Config:Set("keybinds", nil, "aoe")
        
        -- Update UI
        speedSlider:SetValue(100)
        scaleSlider:SetValue(1.0)
        toggleBindingButton:SetText("Not Set")
        cooldownsBindingButton:SetText("Not Set")
        aoeBindingButton:SetText("Not Set")
        WR.UI.mainFrame:SetScale(1.0)
        WR.Rotation:SetRotationInterval(0.1)
    end)
    
    -- Save button
    local saveButton = CreateFrame("Button", nil, settingsFooter, "UIPanelButtonTemplate")
    saveButton:SetSize(BUTTON_WIDTH, BUTTON_HEIGHT)
    saveButton:SetPoint("BOTTOMRIGHT", settingsFooter, "BOTTOMRIGHT", -5, 0)
    saveButton:SetText("Save")
    saveButton:SetScript("OnClick", function()
        settingsFrame:Hide()
    end)
    
    -- Hide initially
    settingsFrame:Hide()
    
    -- Store reference
    self.settingsFrame = settingsFrame
end

-- Create the profiles panel
function WR.UI:CreateProfiles()
    -- Create profiles frame
    local profilesFrame = CreateFrame("Frame", "WindrunnerRotationsProfilesFrame", UIParent, "BackdropTemplate")
    profilesFrame:SetSize(MAIN_WIDTH, MAIN_HEIGHT)
    profilesFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    profilesFrame:SetFrameStrata("MEDIUM")
    profilesFrame:SetFrameLevel(20)
    profilesFrame:SetClampedToScreen(true)
    profilesFrame:SetMovable(true)
    profilesFrame:EnableMouse(true)
    profilesFrame:RegisterForDrag("LeftButton")
    profilesFrame:SetScript("OnDragStart", profilesFrame.StartMoving)
    profilesFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
    end)
    
    -- Set backdrop
    profilesFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    
    -- Create header
    local profilesHeader = CreateFrame("Frame", nil, profilesFrame)
    profilesHeader:SetSize(MAIN_WIDTH - 22, HEADER_HEIGHT)
    profilesHeader:SetPoint("TOPLEFT", profilesFrame, "TOPLEFT", 11, -12)
    
    -- Title text
    local profilesTitleText = profilesHeader:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    profilesTitleText:SetPoint("LEFT", profilesHeader, "LEFT", 5, 0)
    profilesTitleText:SetText("Rotation Profiles")
    
    -- Close button
    local profilesCloseButton = CreateFrame("Button", nil, profilesHeader, "UIPanelCloseButton")
    profilesCloseButton:SetPoint("RIGHT", profilesHeader, "RIGHT", 5, 0)
    profilesCloseButton:SetScript("OnClick", function() profilesFrame:Hide() end)
    
    -- Content area
    local profilesContent = CreateFrame("Frame", nil, profilesFrame)
    profilesContent:SetSize(MAIN_WIDTH - 40, MAIN_HEIGHT - 60)
    profilesContent:SetPoint("TOP", profilesHeader, "BOTTOM", 0, -10)
    
    -- Profile dropdown label
    local profileLabel = profilesContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    profileLabel:SetPoint("TOPLEFT", profilesContent, "TOPLEFT", 10, -10)
    profileLabel:SetText("Current Profile:")
    
    -- Profile dropdown
    local profileDropdown = CreateFrame("Frame", "WindrunnerRotationsProfileDropdown", profilesContent, "UIDropDownMenuTemplate")
    profileDropdown:SetPoint("TOPLEFT", profileLabel, "BOTTOMLEFT", -15, -5)
    
    local function UpdateProfileDropdown()
        local profiles = WR.Profiles:GetAllProfiles()
        local currentProfile = WR.Profiles:GetActiveProfile()
        local currentProfileName = currentProfile and currentProfile.name or "Default"
        
        UIDropDownMenu_SetWidth(profileDropdown, 150)
        UIDropDownMenu_SetText(profileDropdown, currentProfileName)
        
        UIDropDownMenu_Initialize(profileDropdown, function(self, level)
            local info = UIDropDownMenu_CreateInfo()
            
            for profileName, profileData in pairs(profiles) do
                info.text = profileName
                info.value = profileName
                info.func = function(self)
                    WR.Profiles:ActivateProfile(self.value)
                    UIDropDownMenu_SetText(profileDropdown, self.value)
                end
                info.checked = (profileName == currentProfileName)
                UIDropDownMenu_AddButton(info, level)
            end
        end)
    end
    
    UpdateProfileDropdown()
    
    -- Profile management buttons
    local newProfileButton = CreateFrame("Button", nil, profilesContent, "UIPanelButtonTemplate")
    newProfileButton:SetSize(BUTTON_WIDTH, BUTTON_HEIGHT)
    newProfileButton:SetPoint("TOPLEFT", profileDropdown, "BOTTOMLEFT", 15, -10)
    newProfileButton:SetText("New")
    newProfileButton:SetScript("OnClick", function()
        StaticPopupDialogs["WINDRUNNER_NEW_PROFILE"] = {
            text = "Enter a name for the new profile:",
            button1 = "Create",
            button2 = "Cancel",
            hasEditBox = 1,
            maxLetters = 32,
            OnAccept = function(self)
                local profileName = self.editBox:GetText()
                if profileName and profileName ~= "" then
                    WR.Profiles:CreateProfile(profileName)
                    UpdateProfileDropdown()
                end
            end,
            EditBoxOnEnterPressed = function(self)
                local profileName = self:GetText()
                if profileName and profileName ~= "" then
                    WR.Profiles:CreateProfile(profileName)
                    UpdateProfileDropdown()
                end
                self:GetParent():Hide()
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        }
        StaticPopup_Show("WINDRUNNER_NEW_PROFILE")
    end)
    
    local deleteProfileButton = CreateFrame("Button", nil, profilesContent, "UIPanelButtonTemplate")
    deleteProfileButton:SetSize(BUTTON_WIDTH, BUTTON_HEIGHT)
    deleteProfileButton:SetPoint("LEFT", newProfileButton, "RIGHT", SPACING, 0)
    deleteProfileButton:SetText("Delete")
    deleteProfileButton:SetScript("OnClick", function()
        local currentProfile = WR.Profiles:GetActiveProfile()
        local currentProfileName = currentProfile and currentProfile.name or "Default"
        
        if currentProfileName == "Default" then
            WR:Debug("Cannot delete the Default profile")
            return
        end
        
        StaticPopupDialogs["WINDRUNNER_DELETE_PROFILE"] = {
            text = "Are you sure you want to delete profile '" .. currentProfileName .. "'?",
            button1 = "Delete",
            button2 = "Cancel",
            OnAccept = function()
                WR.Profiles:DeleteProfile(currentProfileName)
                UpdateProfileDropdown()
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        }
        StaticPopup_Show("WINDRUNNER_DELETE_PROFILE")
    end)
    
    -- Export/Import buttons
    local exportProfileButton = CreateFrame("Button", nil, profilesContent, "UIPanelButtonTemplate")
    exportProfileButton:SetSize(BUTTON_WIDTH, BUTTON_HEIGHT)
    exportProfileButton:SetPoint("TOPLEFT", newProfileButton, "BOTTOMLEFT", 0, -10)
    exportProfileButton:SetText("Export")
    exportProfileButton:SetScript("OnClick", function()
        local currentProfile = WR.Profiles:GetActiveProfile()
        local currentProfileName = currentProfile and currentProfile.name or "Default"
        local exportString = WR.Profiles:ExportProfile(currentProfileName)
        
        if exportString then
            StaticPopupDialogs["WINDRUNNER_EXPORT_PROFILE"] = {
                text = "Copy the profile string below:",
                button1 = "Close",
                hasEditBox = 1,
                editBoxWidth = 350,
                OnShow = function(self)
                    self.editBox:SetText(exportString)
                    self.editBox:HighlightText()
                end,
                EditBoxOnEscapePressed = function(self)
                    self:GetParent():Hide()
                end,
                timeout = 0,
                whileDead = true,
                hideOnEscape = true,
                preferredIndex = 3,
            }
            StaticPopup_Show("WINDRUNNER_EXPORT_PROFILE")
        end
    end)
    
    local importProfileButton = CreateFrame("Button", nil, profilesContent, "UIPanelButtonTemplate")
    importProfileButton:SetSize(BUTTON_WIDTH, BUTTON_HEIGHT)
    importProfileButton:SetPoint("LEFT", exportProfileButton, "RIGHT", SPACING, 0)
    importProfileButton:SetText("Import")
    importProfileButton:SetScript("OnClick", function()
        StaticPopupDialogs["WINDRUNNER_IMPORT_PROFILE"] = {
            text = "Paste the profile string below:",
            button1 = "Import",
            button2 = "Cancel",
            hasEditBox = 1,
            editBoxWidth = 350,
            OnAccept = function(self)
                local importString = self.editBox:GetText()
                if importString and importString ~= "" then
                    local success, profileName = WR.Profiles:ImportProfile(importString)
                    if success then
                        WR:Debug("Successfully imported profile: " .. profileName)
                        UpdateProfileDropdown()
                    else
                        WR:Debug("Failed to import profile: " .. (profileName or "Unknown error"))
                    end
                end
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        }
        StaticPopup_Show("WINDRUNNER_IMPORT_PROFILE")
    end)
    
    -- Profile settings section
    local settingsTitle = profilesContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    settingsTitle:SetPoint("TOPLEFT", exportProfileButton, "BOTTOMLEFT", 0, -20)
    settingsTitle:SetText("Profile Settings")
    
    -- Hide initially
    profilesFrame:Hide()
    
    -- Store reference
    self.profilesFrame = profilesFrame
    self.updateProfileDropdown = UpdateProfileDropdown
end

-- Register for events
function WR.UI:RegisterEvents()
    -- Create an event frame
    local eventFrame = CreateFrame("Frame")
    
    -- Register for events
    eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    
    -- Process events
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "PLAYER_SPECIALIZATION_CHANGED" or event == "PLAYER_ENTERING_WORLD" then
            WR.UI:UpdateClassSpecInfo()
            WR.UI:UpdateStatus()
        end
    end)
}

-- Apply class-specific styling
function WR.UI:ApplyClassStyling()
    local _, className = UnitClass("player")
    local classColor = CLASS_COLORS[className] or CLASS_COLORS.DEFAULT
    
    -- Style the title text
    if self.titleText then
        self.titleText:SetText("|cFF" .. classColor .. "Windrunner Rotations|r")
    end
}

-- Update class and spec information
function WR.UI:UpdateClassSpecInfo()
    local _, className, classId = UnitClass("player")
    local specIndex = GetSpecialization()
    local specId, specName, _, specIcon = nil, "Unknown", nil, nil
    
    if specIndex then
        specId, specName, _, specIcon = GetSpecializationInfo(specIndex)
    end
    
    -- Get class icon
    local classIcon = WR.UI.ClassIcons.GetIconForClass(className)
    if classIcon then
        self.classIcon:SetTexture(classIcon)
    end
    
    -- Update class text
    local classColor = CLASS_COLORS[className] or CLASS_COLORS.DEFAULT
    self.classText:SetText("|cFF" .. classColor .. className .. "|r")
    
    -- Update spec icon and text
    if specIcon then
        self.specIcon:SetTexture(specIcon)
    end
    
    if specName then
        self.specText:SetText("Spec: " .. specName)
    end
}

-- Update the status text
function WR.UI:UpdateStatus()
    if WR.isRunning then
        self.statusText:SetText("|cFF00FF00Enabled|r")
        self.toggleButton:SetText("Disable")
    else
        self.statusText:SetText("|cFFFF0000Disabled|r")
        self.toggleButton:SetText("Enable")
    end
    
    -- Also update any configuration toggles
    for configKey, button in pairs(actionButtons) do
        button:SetChecked(WR.Config:Get(configKey))
    end
}

-- Toggle the settings panel
function WR.UI:ToggleSettings()
    if self.settingsFrame:IsShown() then
        self.settingsFrame:Hide()
    else
        self.settingsFrame:Show()
        if self.profilesFrame:IsShown() then
            self.profilesFrame:Hide()
        end
    end
}

-- Toggle the profiles panel
function WR.UI:ToggleProfiles()
    if self.profilesFrame:IsShown() then
        self.profilesFrame:Hide()
    else
        self.profilesFrame:Show()
        self.updateProfileDropdown()
        if self.settingsFrame:IsShown() then
            self.settingsFrame:Hide()
        end
    end
}

-- Toggle the main UI
function WR.UI:Toggle()
    if self.mainFrame:IsShown() then
        self.mainFrame:Hide()
    else
        self.mainFrame:Show()
        self:UpdateClassSpecInfo()
        self:UpdateStatus()
    end
}

-- Load position from saved variables
function WR.UI:LoadPosition()
    local position = WR.Config:Get("UI", "position")
    if position then
        self.mainFrame:ClearAllPoints()
        self.mainFrame:SetPoint(position.point or "CENTER", UIParent, position.relativePoint or "CENTER", position.x or 0, position.y or 0)
    end
    
    local scale = WR.Config:Get("UI", "scale") or 1.0
    self.mainFrame:SetScale(scale)
}

-- Get the keybind for a function
function WR.UI:GetKeybind(bindType)
    return WR.Config:Get("keybinds", bindType)
}

-- Process keybinds
function WR.UI:ProcessKeybinds(key)
    local toggle = self:GetKeybind("toggle")
    local cooldowns = self:GetKeybind("cooldowns")
    local aoe = self:GetKeybind("aoe")
    
    if key == toggle then
        if WR.isRunning then
            WR:StopRotation()
        else
            WR:StartRotation()
        end
        self:UpdateStatus()
        return true
    elseif key == cooldowns then
        local current = WR.Config:Get("enableCooldowns")
        WR.Config:Set("enableCooldowns", not current)
        if actionButtons["enableCooldowns"] then
            actionButtons["enableCooldowns"]:SetChecked(not current)
        end
        return true
    elseif key == aoe then
        local current = WR.Config:Get("enableAOE")
        WR.Config:Set("enableAOE", not current)
        if actionButtons["enableAOE"] then
            actionButtons["enableAOE"]:SetChecked(not current)
        end
        return true
    end
    
    return false
end

-- Create a frame to capture key presses for keybinds
local keyBindingFrame = CreateFrame("Frame", nil, UIParent)
keyBindingFrame:EnableKeyboard(true)
keyBindingFrame:SetPropagateKeyboardInput(true)
keyBindingFrame:SetScript("OnKeyDown", function(self, key)
    if WR.UI:ProcessKeybinds(key) then
        -- If we handled the keybind, don't propagate
        self:SetPropagateKeyboardInput(false)
    else
        -- Otherwise, let it go through
        self:SetPropagateKeyboardInput(true)
    end
end)
keyBindingFrame:SetScript("OnKeyUp", function(self)
    self:SetPropagateKeyboardInput(true)
end)
