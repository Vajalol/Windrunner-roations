local addonName, WR = ...

-- ProfileUI module for profile management interface
local ProfileUI = {}
WR.UI = WR.UI or {}
WR.UI.Profile = ProfileUI

-- Local variables
local activeProfile = nil
local profileDropdown = nil
local profileFrame = nil
local exportEditBox = nil
local importEditBox = nil

-- Initialize the Profile UI
function ProfileUI:Initialize()
    self:CreateProfileFrame()
    WR:Debug("ProfileUI module initialized")
end

-- Create the main profile frame
function ProfileUI:CreateProfileFrame()
    -- Create the main frame
    profileFrame = CreateFrame("Frame", "WindrunnerRotationsProfileFrame", UIParent, "BackdropTemplate")
    profileFrame:SetSize(500, 400)
    profileFrame:SetPoint("CENTER")
    profileFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 8, right = 8, top = 8, bottom = 8 }
    })
    profileFrame:SetBackdropColor(0, 0, 0, 0.9)
    profileFrame:SetMovable(true)
    profileFrame:EnableMouse(true)
    profileFrame:RegisterForDrag("LeftButton")
    profileFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    profileFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    profileFrame:Hide()
    
    -- Add a title
    local title = profileFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -15)
    title:SetText("Windrunner Rotations - Profile Manager")
    
    -- Create close button
    local closeButton = CreateFrame("Button", nil, profileFrame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", -5, -5)
    
    -- Create profile selection dropdown
    self:CreateProfileDropdown()
    
    -- Create profile action buttons
    self:CreateProfileActionButtons()
    
    -- Create profile tabs
    self:CreateProfileTabs()
    
    -- Create initial tab content
    self:CreateGeneralSettingsTab()
    self:CreateClassSettingsTab()
    self:CreateDungeonSettingsTab()
    self:CreateImportExportTab()
    
    -- Initialize with the default profile
    self:UpdateProfileDisplay()
end

-- Create profile selection dropdown
function ProfileUI:CreateProfileDropdown()
    local dropdown = CreateFrame("Frame", "WindrunnerRotationsProfileDropdown", profileFrame, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPLEFT", 15, -40)
    
    local dropdownLabel = dropdown:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    dropdownLabel:SetPoint("BOTTOMLEFT", dropdown, "TOPLEFT", 20, 0)
    dropdownLabel:SetText("Select Profile:")
    
    UIDropDownMenu_SetWidth(dropdown, 200)
    UIDropDownMenu_SetText(dropdown, "Loading profiles...")
    
    UIDropDownMenu_Initialize(dropdown, function(self, level)
        local profiles = WR.ProfileManager:GetProfileList()
        
        -- Sort profiles by name
        table.sort(profiles, function(a, b) return a.name < b.name end)
        
        local info = UIDropDownMenu_CreateInfo()
        for _, profile in ipairs(profiles) do
            info.text = profile.name
            info.arg1 = profile.id
            info.checked = (activeProfile and activeProfile.id == profile.id)
            info.func = function(_, profileId)
                WR.ProfileManager:SwitchProfile(profileId)
                ProfileUI:UpdateProfileDisplay()
            end
            UIDropDownMenu_AddButton(info)
        end
    end)
    
    profileDropdown = dropdown
end

-- Create profile action buttons
function ProfileUI:CreateProfileActionButtons()
    -- Create new profile button
    local newButton = CreateFrame("Button", nil, profileFrame, "UIPanelButtonTemplate")
    newButton:SetSize(90, 22)
    newButton:SetPoint("TOPLEFT", profileDropdown, "BOTTOMLEFT", -10, -10)
    newButton:SetText("New")
    newButton:SetScript("OnClick", function()
        StaticPopupDialogs["WR_NEW_PROFILE"] = {
            text = "Enter a name for the new profile:",
            button1 = "Create",
            button2 = "Cancel",
            hasEditBox = true,
            maxLetters = 32,
            OnAccept = function(self)
                local name = self.editBox:GetText()
                if name and name ~= "" then
                    local newProfileId = WR.ProfileManager:CreateProfile(name)
                    if newProfileId then
                        WR.ProfileManager:SwitchProfile(newProfileId)
                        ProfileUI:UpdateProfileDisplay()
                    end
                end
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3
        }
        StaticPopup_Show("WR_NEW_PROFILE")
    end)
    
    -- Create copy profile button
    local copyButton = CreateFrame("Button", nil, profileFrame, "UIPanelButtonTemplate")
    copyButton:SetSize(90, 22)
    copyButton:SetPoint("LEFT", newButton, "RIGHT", 5, 0)
    copyButton:SetText("Copy")
    copyButton:SetScript("OnClick", function()
        StaticPopupDialogs["WR_COPY_PROFILE"] = {
            text = "Enter a name for the copied profile:",
            button1 = "Copy",
            button2 = "Cancel",
            hasEditBox = true,
            maxLetters = 32,
            OnAccept = function(self)
                local name = self.editBox:GetText()
                if name and name ~= "" then
                    local newProfileId = WR.ProfileManager:CreateProfile(name, activeProfile.id)
                    if newProfileId then
                        WR.ProfileManager:SwitchProfile(newProfileId)
                        ProfileUI:UpdateProfileDisplay()
                    end
                end
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3
        }
        StaticPopup_Show("WR_COPY_PROFILE")
    end)
    
    -- Create delete profile button
    local deleteButton = CreateFrame("Button", nil, profileFrame, "UIPanelButtonTemplate")
    deleteButton:SetSize(90, 22)
    deleteButton:SetPoint("LEFT", copyButton, "RIGHT", 5, 0)
    deleteButton:SetText("Delete")
    deleteButton:SetScript("OnClick", function()
        if activeProfile.id:match("^default") then
            WR:Message("Cannot delete default profiles")
            return
        end
        
        StaticPopupDialogs["WR_DELETE_PROFILE"] = {
            text = "Are you sure you want to delete the profile '" .. activeProfile.name .. "'?",
            button1 = "Delete",
            button2 = "Cancel",
            OnAccept = function()
                WR.ProfileManager:DeleteProfile(activeProfile.id)
                ProfileUI:UpdateProfileDisplay()
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3
        }
        StaticPopup_Show("WR_DELETE_PROFILE")
    end)
    
    -- Create save profile button
    local saveButton = CreateFrame("Button", nil, profileFrame, "UIPanelButtonTemplate")
    saveButton:SetSize(90, 22)
    saveButton:SetPoint("LEFT", deleteButton, "RIGHT", 5, 0)
    saveButton:SetText("Save")
    saveButton:SetScript("OnClick", function()
        WR.ProfileManager:SaveProfile()
        WR:Message("Profile saved")
    end)
end

-- Create profile tabs
function ProfileUI:CreateProfileTabs()
    local tabs = {}
    local tabNames = {"General", "Class", "Dungeon", "Import/Export"}
    local tabFrames = {}
    
    for i, name in ipairs(tabNames) do
        -- Create tab button
        local tab = CreateFrame("Button", "WindrunnerRotationsProfileTab" .. i, profileFrame, "CharacterFrameTabButtonTemplate")
        tab:SetID(i)
        tab:SetText(name)
        
        if i == 1 then
            tab:SetPoint("BOTTOMLEFT", profileFrame, "TOPLEFT", 20, -25)
        else
            tab:SetPoint("LEFT", tabs[i-1], "RIGHT", -10, 0)
        end
        
        -- Create tab content frame
        local tabFrame = CreateFrame("Frame", "WindrunnerRotationsProfileTabFrame" .. i, profileFrame)
        tabFrame:SetPoint("TOPLEFT", 20, -80)
        tabFrame:SetPoint("BOTTOMRIGHT", -20, 20)
        tabFrame:Hide()
        
        -- Set active tab
        if i == 1 then
            tab:SetNormalFontObject(GameFontHighlightSmall)
            PanelTemplates_SetTab(profileFrame, 1)
            tabFrame:Show()
        else
            tab:SetNormalFontObject(GameFontNormalSmall)
        end
        
        -- Handle tab clicks
        tab:SetScript("OnClick", function()
            PanelTemplates_SetTab(profileFrame, i)
            for j, frame in ipairs(tabFrames) do
                if j == i then
                    frame:Show()
                else
                    frame:Hide()
                end
            end
        end)
        
        table.insert(tabs, tab)
        table.insert(tabFrames, tabFrame)
    end
    
    profileFrame.tabs = tabs
    profileFrame.tabFrames = tabFrames
    profileFrame.numTabs = #tabs
    
    -- Update tab sizing
    PanelTemplates_UpdateTabs(profileFrame)
end

-- Create the general settings tab
function ProfileUI:CreateGeneralSettingsTab()
    local tabFrame = profileFrame.tabFrames[1]
    
    -- Create scrollframe for settings
    local scrollFrame = CreateFrame("ScrollFrame", "WindrunnerRotationsGeneralScrollFrame", tabFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 0, 0)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 0)
    
    local scrollChild = CreateFrame("Frame")
    scrollFrame:SetScrollChild(scrollChild)
    scrollChild:SetSize(430, 600)
    
    -- Helper function to create setting checkboxes
    local yOffset = 0
    local function CreateCheckbox(label, settingPath)
        local checkbox = CreateFrame("CheckButton", nil, scrollChild, "UICheckButtonTemplate")
        checkbox:SetPoint("TOPLEFT", 10, -yOffset)
        checkbox.text:SetText(label)
        checkbox.settingPath = settingPath
        
        checkbox:SetScript("OnClick", function(self)
            local checked = self:GetChecked()
            WR.ProfileManager:UpdateSetting(self.settingPath, checked)
        end)
        
        yOffset = yOffset + 25
        return checkbox
    end
    
    -- Helper function to create setting sliders
    local function CreateSlider(label, settingPath, min, max, step)
        local sliderLabel = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        sliderLabel:SetPoint("TOPLEFT", 10, -yOffset)
        sliderLabel:SetText(label)
        
        yOffset = yOffset + 20
        
        local slider = CreateFrame("Slider", nil, scrollChild, "OptionsSliderTemplate")
        slider:SetPoint("TOPLEFT", 20, -yOffset)
        slider:SetWidth(380)
        slider:SetMinMaxValues(min, max)
        slider:SetValueStep(step)
        slider.settingPath = settingPath
        
        slider.Low:SetText(min)
        slider.High:SetText(max)
        
        slider:SetScript("OnValueChanged", function(self, value)
            -- Round to step if needed
            value = math.floor(value / step + 0.5) * step
            WR.ProfileManager:UpdateSetting(self.settingPath, value)
            slider.Current:SetText(value)
        end)
        
        slider.Current = slider:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        slider.Current:SetPoint("TOP", slider, "BOTTOM", 0, 0)
        
        yOffset = yOffset + 40
        return slider
    end
    
    -- Create category header
    local header = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    header:SetPoint("TOPLEFT", 0, 0)
    header:SetText("General Settings")
    yOffset = 30
    
    -- Create general settings
    local enabledCB = CreateCheckbox("Enable Addon", "general.enabled")
    local autoSwapCB = CreateCheckbox("Auto-Swap in Combat", "general.autoSwapInCombat")
    local autoEnableDungeonsCB = CreateCheckbox("Auto-Enable in Dungeons", "general.autoEnableInDungeons")
    local autoEnableRaidsCB = CreateCheckbox("Auto-Enable in Raids", "general.autoEnableInRaids")
    local showMinimapCB = CreateCheckbox("Show Minimap Button", "general.showMinimap")
    local debugModeCB = CreateCheckbox("Debug Mode", "general.debugMode")
    local smartTargetingCB = CreateCheckbox("Use Smart Targeting", "general.useSmartTargeting")
    local combatOnlyCB = CreateCheckbox("Combat Only", "general.combatOnly")
    
    -- Create throttle slider
    local throttleSlider = CreateSlider("Throttle Rate", "general.throttleRate", 0.05, 0.5, 0.05)
    
    -- Rotation category header
    yOffset = yOffset + 20
    local rotationHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    rotationHeader:SetPoint("TOPLEFT", 0, -yOffset)
    rotationHeader:SetText("Rotation Settings")
    yOffset = yOffset + 30
    
    -- Create rotation settings
    local useAOERotationCB = CreateCheckbox("Use AoE Rotation", "rotation.useAOERotation")
    local aoeThresholdSlider = CreateSlider("AoE Threshold", "rotation.aoeThreshold", 2, 10, 1)
    
    -- Interrupt category
    yOffset = yOffset + 20
    local interruptHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    interruptHeader:SetPoint("TOPLEFT", 10, -yOffset)
    interruptHeader:SetText("Interrupt Settings")
    yOffset = yOffset + 20
    
    local interruptEnabledCB = CreateCheckbox("Enable Interrupts", "rotation.interrupt.enabled")
    local priorityOnlyCB = CreateCheckbox("Priority Interrupts Only", "rotation.interrupt.priorityOnly")
    local randomDelayCB = CreateCheckbox("Random Interrupt Delay", "rotation.interrupt.randomDelay")
    local interruptDelaySlider = CreateSlider("Interrupt Delay", "rotation.interrupt.delay", 0, 1, 0.1)
    
    -- Defensive category
    yOffset = yOffset + 20
    local defensiveHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    defensiveHeader:SetPoint("TOPLEFT", 10, -yOffset)
    defensiveHeader:SetText("Defensive Settings")
    yOffset = yOffset + 20
    
    local defensivesEnabledCB = CreateCheckbox("Enable Defensives", "rotation.defensives.enabled")
    local autoHealthstoneCB = CreateCheckbox("Auto Use Healthstone", "rotation.defensives.autoUseHealthstone")
    local healthstoneThresholdSlider = CreateSlider("Healthstone Threshold", "rotation.defensives.healthstoneThreshold", 10, 80, 5)
    
    -- Store all controls for updating
    tabFrame.controls = {
        enabledCB = enabledCB,
        autoSwapCB = autoSwapCB,
        autoEnableDungeonsCB = autoEnableDungeonsCB,
        autoEnableRaidsCB = autoEnableRaidsCB,
        showMinimapCB = showMinimapCB,
        debugModeCB = debugModeCB,
        smartTargetingCB = smartTargetingCB,
        combatOnlyCB = combatOnlyCB,
        throttleSlider = throttleSlider,
        useAOERotationCB = useAOERotationCB,
        aoeThresholdSlider = aoeThresholdSlider,
        interruptEnabledCB = interruptEnabledCB,
        priorityOnlyCB = priorityOnlyCB,
        randomDelayCB = randomDelayCB,
        interruptDelaySlider = interruptDelaySlider,
        defensivesEnabledCB = defensivesEnabledCB,
        autoHealthstoneCB = autoHealthstoneCB,
        healthstoneThresholdSlider = healthstoneThresholdSlider
    }
end

-- Create the class settings tab
function ProfileUI:CreateClassSettingsTab()
    local tabFrame = profileFrame.tabFrames[2]
    
    -- Create scrollframe for settings
    local scrollFrame = CreateFrame("ScrollFrame", "WindrunnerRotationsClassScrollFrame", tabFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 0, 0)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 0)
    
    local scrollChild = CreateFrame("Frame")
    scrollFrame:SetScrollChild(scrollChild)
    scrollChild:SetSize(430, 600)
    
    -- Create class label
    local classLabel = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    classLabel:SetPoint("TOPLEFT", 0, 0)
    classLabel:SetText("Class Settings")
    
    -- Create spec selection dropdown
    local specDropdown = CreateFrame("Frame", "WindrunnerRotationsSpecDropdown", scrollChild, "UIDropDownMenuTemplate")
    specDropdown:SetPoint("TOPLEFT", 10, -40)
    
    local specLabel = specDropdown:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    specLabel:SetPoint("BOTTOMLEFT", specDropdown, "TOPLEFT", 20, 0)
    specLabel:SetText("Specialization:")
    
    UIDropDownMenu_SetWidth(specDropdown, 200)
    UIDropDownMenu_SetText(specDropdown, "Select Spec")
    
    -- Store for updating later
    tabFrame.specDropdown = specDropdown
    tabFrame.classLabel = classLabel
    
    -- Create placeholder for class-specific settings
    local classSettingsFrame = CreateFrame("Frame", nil, scrollChild)
    classSettingsFrame:SetPoint("TOPLEFT", 10, -80)
    classSettingsFrame:SetSize(410, 500)
    
    tabFrame.classSettingsFrame = classSettingsFrame
end

-- Create the dungeon settings tab
function ProfileUI:CreateDungeonSettingsTab()
    local tabFrame = profileFrame.tabFrames[3]
    
    -- Create scrollframe for settings
    local scrollFrame = CreateFrame("ScrollFrame", "WindrunnerRotationsDungeonScrollFrame", tabFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 0, 0)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 0)
    
    local scrollChild = CreateFrame("Frame")
    scrollFrame:SetScrollChild(scrollChild)
    scrollChild:SetSize(430, 600)
    
    -- Create dungeon header
    local header = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    header:SetPoint("TOPLEFT", 0, 0)
    header:SetText("Dungeon Intelligence Settings")
    
    -- Helper function to create setting checkboxes
    local yOffset = 30
    local function CreateCheckbox(label, settingPath)
        local checkbox = CreateFrame("CheckButton", nil, scrollChild, "UICheckButtonTemplate")
        checkbox:SetPoint("TOPLEFT", 10, -yOffset)
        checkbox.text:SetText(label)
        checkbox.settingPath = settingPath
        
        checkbox:SetScript("OnClick", function(self)
            local checked = self:GetChecked()
            WR.ProfileManager:UpdateSetting(self.settingPath, checked)
        end)
        
        yOffset = yOffset + 25
        return checkbox
    end
    
    -- Create dungeon settings
    local useDungeonIntelligenceCB = CreateCheckbox("Use Dungeon Intelligence", "dungeons.useDungeonIntelligence")
    local priorityInterruptsCB = CreateCheckbox("Prioritize Important Interrupts", "dungeons.priorityInterrupts")
    local autoTargetPriorityCB = CreateCheckbox("Auto-Target Priority Enemies", "dungeons.autoTargetPriority")
    local optimizePullsCB = CreateCheckbox("Optimize Pulls", "dungeons.optimizePulls")
    local adaptToAffixesCB = CreateCheckbox("Adapt to M+ Affixes", "dungeons.adaptToAffixes")
    
    -- Create subheader for affixes
    yOffset = yOffset + 20
    local affixesHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    affixesHeader:SetPoint("TOPLEFT", 0, -yOffset)
    affixesHeader:SetText("Affix-Specific Settings")
    yOffset = yOffset + 30
    
    -- Create checkboxes for specific affixes
    local tyranBurstCB = CreateCheckbox("Save burst CDs for bosses on Tyrannical", "dungeons.tyranicalBurstMode")
    local fortifiedBurstCB = CreateCheckbox("Use burst CDs on trash on Fortified", "dungeons.fortifiedBurstMode")
    local explosiveTargetingCB = CreateCheckbox("Auto-target Explosive Orbs", "dungeons.explosiveTargeting")
    local necroticKitingCB = CreateCheckbox("Kite at high Necrotic stacks", "dungeons.necroticKiting")
    
    -- Store controls for updating
    tabFrame.controls = {
        useDungeonIntelligenceCB = useDungeonIntelligenceCB,
        priorityInterruptsCB = priorityInterruptsCB,
        autoTargetPriorityCB = autoTargetPriorityCB,
        optimizePullsCB = optimizePullsCB,
        adaptToAffixesCB = adaptToAffixesCB,
        tyranBurstCB = tyranBurstCB,
        fortifiedBurstCB = fortifiedBurstCB,
        explosiveTargetingCB = explosiveTargetingCB,
        necroticKitingCB = necroticKitingCB
    }
end

-- Create the import/export tab
function ProfileUI:CreateImportExportTab()
    local tabFrame = profileFrame.tabFrames[4]
    
    -- Create export header
    local exportHeader = tabFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    exportHeader:SetPoint("TOPLEFT", 10, -10)
    exportHeader:SetText("Export Profile")
    
    -- Create export button
    local exportButton = CreateFrame("Button", nil, tabFrame, "UIPanelButtonTemplate")
    exportButton:SetSize(100, 22)
    exportButton:SetPoint("TOPLEFT", 10, -30)
    exportButton:SetText("Export")
    exportButton:SetScript("OnClick", function()
        if activeProfile then
            local exportString = WR.ProfileManager:ExportProfile(activeProfile.id)
            exportEditBox:SetText(exportString or "")
            exportEditBox:HighlightText()
            exportEditBox:SetFocus()
        end
    end)
    
    -- Create export editbox
    exportEditBox = CreateFrame("EditBox", nil, tabFrame, "InputBoxTemplate")
    exportEditBox:SetPoint("TOPLEFT", 10, -60)
    exportEditBox:SetPoint("RIGHT", -10, 0)
    exportEditBox:SetHeight(100)
    exportEditBox:SetMultiLine(true)
    exportEditBox:SetAutoFocus(false)
    exportEditBox:SetFontObject("ChatFontNormal")
    exportEditBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    
    -- Create export backdrop and scroll frame
    local exportBackdrop = CreateFrame("Frame", nil, tabFrame, "BackdropTemplate")
    exportBackdrop:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    exportBackdrop:SetPoint("TOPLEFT", exportEditBox, -10, 10)
    exportBackdrop:SetPoint("BOTTOMRIGHT", exportEditBox, 10, -10)
    exportEditBox:SetParent(exportBackdrop)
    
    -- Create import header
    local importHeader = tabFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    importHeader:SetPoint("TOPLEFT", 10, -180)
    importHeader:SetText("Import Profile")
    
    -- Create import editbox
    importEditBox = CreateFrame("EditBox", nil, tabFrame, "InputBoxTemplate")
    importEditBox:SetPoint("TOPLEFT", 10, -210)
    importEditBox:SetPoint("RIGHT", -10, 0)
    importEditBox:SetHeight(100)
    importEditBox:SetMultiLine(true)
    importEditBox:SetAutoFocus(false)
    importEditBox:SetFontObject("ChatFontNormal")
    importEditBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    
    -- Create import backdrop
    local importBackdrop = CreateFrame("Frame", nil, tabFrame, "BackdropTemplate")
    importBackdrop:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    importBackdrop:SetPoint("TOPLEFT", importEditBox, -10, 10)
    importBackdrop:SetPoint("BOTTOMRIGHT", importEditBox, 10, -10)
    importEditBox:SetParent(importBackdrop)
    
    -- Create import button
    local importButton = CreateFrame("Button", nil, tabFrame, "UIPanelButtonTemplate")
    importButton:SetSize(100, 22)
    importButton:SetPoint("TOPLEFT", 10, -320)
    importButton:SetText("Import")
    importButton:SetScript("OnClick", function()
        local importString = importEditBox:GetText()
        if importString and importString ~= "" then
            local success, profileId = WR.ProfileManager:ImportProfile(importString)
            if success and profileId then
                WR.ProfileManager:SwitchProfile(profileId)
                ProfileUI:UpdateProfileDisplay()
                WR:Message("Profile imported successfully")
                importEditBox:SetText("")
            else
                WR:Message("Failed to import profile: " .. (profileId or "Invalid format"))
            end
        else
            WR:Message("No import string provided")
        end
    end)
end

-- Update the profile display with the current active profile
function ProfileUI:UpdateProfileDisplay()
    activeProfile = WR.ProfileManager:GetActiveProfile()
    
    if not activeProfile then
        WR:Debug("No active profile to display")
        return
    end
    
    -- Update dropdown text
    UIDropDownMenu_SetText(profileDropdown, activeProfile.name)
    
    -- Update general settings tab
    self:UpdateGeneralSettingsTab()
    
    -- Update class settings tab
    self:UpdateClassSettingsTab()
    
    -- Update dungeon settings tab
    self:UpdateDungeonSettingsTab()
    
    WR:Debug("Updated profile display for", activeProfile.name)
end

-- Update general settings tab with current profile values
function ProfileUI:UpdateGeneralSettingsTab()
    local tabFrame = profileFrame.tabFrames[1]
    if not tabFrame or not tabFrame.controls then return end
    
    -- Update checkbox states
    local controls = tabFrame.controls
    controls.enabledCB:SetChecked(activeProfile.settings.general.enabled)
    controls.autoSwapCB:SetChecked(activeProfile.settings.general.autoSwapInCombat)
    controls.autoEnableDungeonsCB:SetChecked(activeProfile.settings.general.autoEnableInDungeons)
    controls.autoEnableRaidsCB:SetChecked(activeProfile.settings.general.autoEnableInRaids)
    controls.showMinimapCB:SetChecked(activeProfile.settings.general.showMinimap)
    controls.debugModeCB:SetChecked(activeProfile.settings.general.debugMode)
    controls.smartTargetingCB:SetChecked(activeProfile.settings.general.useSmartTargeting)
    controls.combatOnlyCB:SetChecked(activeProfile.settings.general.combatOnly)
    
    -- Update slider values
    controls.throttleSlider:SetValue(activeProfile.settings.general.throttleRate)
    controls.throttleSlider.Current:SetText(activeProfile.settings.general.throttleRate)
    
    -- Update rotation settings
    controls.useAOERotationCB:SetChecked(activeProfile.settings.rotation.useAOERotation)
    controls.aoeThresholdSlider:SetValue(activeProfile.settings.rotation.aoeThreshold)
    controls.aoeThresholdSlider.Current:SetText(activeProfile.settings.rotation.aoeThreshold)
    
    -- Update interrupt settings
    controls.interruptEnabledCB:SetChecked(activeProfile.settings.rotation.interrupt.enabled)
    controls.priorityOnlyCB:SetChecked(activeProfile.settings.rotation.interrupt.priorityOnly)
    controls.randomDelayCB:SetChecked(activeProfile.settings.rotation.interrupt.randomDelay)
    controls.interruptDelaySlider:SetValue(activeProfile.settings.rotation.interrupt.delay)
    controls.interruptDelaySlider.Current:SetText(activeProfile.settings.rotation.interrupt.delay)
    
    -- Update defensive settings
    controls.defensivesEnabledCB:SetChecked(activeProfile.settings.rotation.defensives.enabled)
    controls.autoHealthstoneCB:SetChecked(activeProfile.settings.rotation.defensives.autoUseHealthstone)
    controls.healthstoneThresholdSlider:SetValue(activeProfile.settings.rotation.defensives.healthstoneThreshold)
    controls.healthstoneThresholdSlider.Current:SetText(activeProfile.settings.rotation.defensives.healthstoneThreshold)
end

-- Update class settings tab with current profile values
function ProfileUI:UpdateClassSettingsTab()
    local tabFrame = profileFrame.tabFrames[2]
    if not tabFrame then return end
    
    -- Get player class
    local _, class = UnitClass("player")
    
    -- Update class label
    tabFrame.classLabel:SetText(class .. " Settings")
    
    -- Update spec dropdown
    UIDropDownMenu_Initialize(tabFrame.specDropdown, function(self, level)
        local info = UIDropDownMenu_CreateInfo()
        
        -- Get current spec ID
        local currentSpecID = GetSpecialization() and GetSpecializationInfo(GetSpecialization()) or nil
        
        -- Get the specs for this class
        local specs = WR.ProfileManager:GetSpecsForClass(class)
        
        for specID, specName in pairs(specs) do
            info.text = specName
            info.arg1 = specID
            info.checked = (currentSpecID == specID)
            info.func = function(_, specID)
                -- Switch to this spec's settings
                WR:Debug("Selected spec:", specID)
                -- This would normally update the display with spec-specific settings
            end
            UIDropDownMenu_AddButton(info)
        end
    end)
    
    -- Set dropdown text to current spec
    local currentSpecID = GetSpecialization() and GetSpecializationInfo(GetSpecialization()) or nil
    local specs = WR.ProfileManager:GetSpecsForClass(class)
    if currentSpecID and specs[currentSpecID] then
        UIDropDownMenu_SetText(tabFrame.specDropdown, specs[currentSpecID])
    else
        UIDropDownMenu_SetText(tabFrame.specDropdown, "Select Spec")
    end
    
    -- Clear the class settings frame
    for _, child in pairs({tabFrame.classSettingsFrame:GetChildren()}) do
        child:Hide()
    end
    
    -- Add class-specific settings based on the active profile
    -- This would be customized based on class and spec
    local yOffset = 0
    local header = tabFrame.classSettingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    header:SetPoint("TOPLEFT", 0, -yOffset)
    header:SetText("Class-Specific Settings")
    header:Show()
    
    -- Just a placeholder for now - would be populated with actual class settings
    local placeholder = tabFrame.classSettingsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    placeholder:SetPoint("TOPLEFT", 0, -30)
    placeholder:SetText("Class-specific settings would be displayed here based on profile data")
    placeholder:Show()
end

-- Update dungeon settings tab with current profile values
function ProfileUI:UpdateDungeonSettingsTab()
    local tabFrame = profileFrame.tabFrames[3]
    if not tabFrame or not tabFrame.controls then return end
    
    -- Update checkbox states
    local controls = tabFrame.controls
    controls.useDungeonIntelligenceCB:SetChecked(activeProfile.settings.dungeons.useDungeonIntelligence)
    controls.priorityInterruptsCB:SetChecked(activeProfile.settings.dungeons.priorityInterrupts)
    controls.autoTargetPriorityCB:SetChecked(activeProfile.settings.dungeons.autoTargetPriority)
    controls.optimizePullsCB:SetChecked(activeProfile.settings.dungeons.optimizePulls)
    controls.adaptToAffixesCB:SetChecked(activeProfile.settings.dungeons.adaptToAffixes)
    
    -- These are example settings that might not exist in profile yet
    if activeProfile.settings.dungeons.tyranicalBurstMode ~= nil then
        controls.tyranBurstCB:SetChecked(activeProfile.settings.dungeons.tyranicalBurstMode)
    end
    
    if activeProfile.settings.dungeons.fortifiedBurstMode ~= nil then
        controls.fortifiedBurstCB:SetChecked(activeProfile.settings.dungeons.fortifiedBurstMode)
    end
    
    if activeProfile.settings.dungeons.explosiveTargeting ~= nil then
        controls.explosiveTargetingCB:SetChecked(activeProfile.settings.dungeons.explosiveTargeting)
    end
    
    if activeProfile.settings.dungeons.necroticKiting ~= nil then
        controls.necroticKitingCB:SetChecked(activeProfile.settings.dungeons.necroticKiting)
    end
end

-- Show the profile UI
function ProfileUI:Show()
    profileFrame:Show()
    self:UpdateProfileDisplay()
end

-- Hide the profile UI
function ProfileUI:Hide()
    profileFrame:Hide()
end

-- Toggle the profile UI
function ProfileUI:Toggle()
    if profileFrame:IsShown() then
        self:Hide()
    else
        self:Show()
    end
end

-- Initialize the module when the addon loads
ProfileUI:Initialize()

return ProfileUI