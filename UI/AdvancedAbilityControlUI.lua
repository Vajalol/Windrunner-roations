local addonName, WR = ...

-- Advanced Ability Control Settings UI
local AdvancedAbilityControlUI = {}
WR.UI.AdvancedAbilityControlUI = AdvancedAbilityControlUI

-- Local references
local CreateFrame = CreateFrame
local UIParent = UIParent
local pairs = pairs
local ipairs = ipairs
local tinsert = table.insert
local tremove = table.remove
local sort = table.sort
local min = math.min
local max = math.max
local floor = math.floor
local tonumber = tonumber
local tostring = tostring
local format = string.format

-- Module references
local AAC = WR.AdvancedAbilityControl
local ABILITY_TYPES = {
    INTERRUPT = "interrupt",
    DISPEL = "dispel",
    CC = "cc"
}

local TIMING_MODES = {
    INSTANT = "instant",
    HUMAN = "human",
    RANDOM = "random",
    VARIABLE = "variable",
    PERCENTAGE = "percentage"
}

-- Initialize
function AdvancedAbilityControlUI:Initialize()
    -- Create frames when settings UI is opened
    if WR.UI and WR.UI.AdvancedSettingsUI then
        WR.UI.AdvancedSettingsUI:RegisterPanel("Ability Control", function(container)
            self:CreateSettingsPanel(container)
        end)
    end
end

-- Create main settings panel
function AdvancedAbilityControlUI:CreateSettingsPanel(container)
    -- Cache reference to container
    self.container = container
    
    -- Create tabbed interface
    self:CreateTabbedInterface(container)
    
    -- Create tabs content
    self:CreateGeneralTab(self.tabFrames["General"])
    self:CreateInterruptsTab(self.tabFrames["Interrupts"])
    self:CreateDispelsTab(self.tabFrames["Dispels"])
    self:CreateCrowdControlTab(self.tabFrames["CrowdControl"])
    self:CreateSpellListsTab(self.tabFrames["SpellLists"])
    self:CreateAdvancedTab(self.tabFrames["Advanced"])
    
    -- Select first tab by default
    self:SelectTab("General")
end

-- Create tabbed interface
function AdvancedAbilityControlUI:CreateTabbedInterface(container)
    -- Create tab container
    local tabContainer = CreateFrame("Frame", nil, container)
    tabContainer:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)
    tabContainer:SetPoint("BOTTOMRIGHT", container, "TOPRIGHT", 0, -30)
    
    -- Create tab buttons
    self.tabs = {}
    self.tabFrames = {}
    
    local tabNames = {"General", "Interrupts", "Dispels", "CrowdControl", "SpellLists", "Advanced"}
    local tabTitles = {"General", "Interrupts", "Dispels", "Crowd Control", "Spell Lists", "Advanced"}
    
    local tabWidth = floor(container:GetWidth() / #tabNames)
    
    for i, name in ipairs(tabNames) do
        -- Create tab button
        local tab = CreateFrame("Button", nil, tabContainer)
        tab:SetSize(tabWidth, 30)
        tab:SetPoint("TOPLEFT", tabContainer, "TOPLEFT", (i-1) * tabWidth, 0)
        
        -- Create background and text
        tab.bg = tab:CreateTexture(nil, "BACKGROUND")
        tab.bg:SetAllPoints()
        tab.bg:SetColorTexture(0.2, 0.2, 0.2, 0.8)
        
        tab.text = tab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        tab.text:SetPoint("CENTER", tab, "CENTER", 0, 0)
        tab.text:SetText(tabTitles[i])
        
        -- Create highlight
        tab.highlight = tab:CreateTexture(nil, "HIGHLIGHT")
        tab.highlight:SetAllPoints()
        tab.highlight:SetColorTexture(0.3, 0.3, 0.3, 0.5)
        
        -- Create selected indicator
        tab.selected = tab:CreateTexture(nil, "OVERLAY")
        tab.selected:SetPoint("BOTTOMLEFT", tab, "BOTTOMLEFT", 0, 0)
        tab.selected:SetPoint("BOTTOMRIGHT", tab, "BOTTOMRIGHT", 0, 0)
        tab.selected:SetHeight(3)
        tab.selected:SetColorTexture(0.9, 0.7, 0, 1)
        tab.selected:Hide()
        
        -- Set click handler
        tab:SetScript("OnClick", function()
            self:SelectTab(name)
        end)
        
        -- Store reference
        self.tabs[name] = tab
        
        -- Create content frame for this tab
        local contentFrame = CreateFrame("Frame", nil, container)
        contentFrame:SetPoint("TOPLEFT", container, "TOPLEFT", 0, -30)
        contentFrame:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", 0, 0)
        contentFrame:Hide()
        
        -- Create scrollframe for this tab
        local scrollFrame = CreateFrame("ScrollFrame", nil, contentFrame, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 0, 0)
        scrollFrame:SetPoint("BOTTOMRIGHT", contentFrame, "BOTTOMRIGHT", -20, 0)
        
        local scrollChild = CreateFrame("Frame")
        scrollFrame:SetScrollChild(scrollChild)
        scrollChild:SetWidth(contentFrame:GetWidth() - 20)
        scrollChild:SetHeight(contentFrame:GetHeight() * 2) -- Extra space for content
        
        -- Store references
        self.tabFrames[name] = {
            container = contentFrame,
            scrollFrame = scrollFrame,
            scrollChild = scrollChild
        }
    end
end

-- Select tab
function AdvancedAbilityControlUI:SelectTab(tabName)
    -- Hide all tab content and deselect all tabs
    for name, tab in pairs(self.tabs) do
        tab.selected:Hide()
        self.tabFrames[name].container:Hide()
    end
    
    -- Show selected tab content and select tab
    self.tabs[tabName].selected:Show()
    self.tabFrames[tabName].container:Show()
    
    -- Store current tab
    self.currentTab = tabName
end

-- Create general settings tab
function AdvancedAbilityControlUI:CreateGeneralTab(tabFrames)
    local container = tabFrames.scrollChild
    local yOffset = -20
    
    -- Title
    local title = container:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", container, "TOPLEFT", 20, yOffset)
    title:SetText("Advanced Ability Control")
    yOffset = yOffset - 30
    
    -- Description
    local desc = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    desc:SetPoint("TOPLEFT", container, "TOPLEFT", 20, yOffset)
    desc:SetWidth(container:GetWidth() - 40)
    desc:SetJustifyH("LEFT")
    desc:SetText("Configure how interrupts, dispels, and crowd control abilities are automatically used. You can customize delays, priorities, and behavior for each ability type.")
    yOffset = yOffset - 40
    
    -- Module enable/disable checkbox
    local enableCheckbox = self:CreateCheckBox(container, "Enable Advanced Ability Control", 
                                              "Enables or disables the entire module", 20, yOffset)
    enableCheckbox:SetChecked(AAC.settings.enabled)
    enableCheckbox:SetScript("OnClick", function(self)
        AAC.settings.enabled = self:GetChecked()
        AAC:SaveSettings()
    end)
    yOffset = yOffset - 30
    
    -- Debug mode checkbox
    local debugCheckbox = self:CreateCheckBox(container, "Debug Mode", 
                                             "Enables or disables debug mode for troubleshooting", 20, yOffset)
    debugCheckbox:SetChecked(AAC.settings.debugMode)
    debugCheckbox:SetScript("OnClick", function(self)
        AAC.settings.debugMode = self:GetChecked()
        AAC.debugMode = self:GetChecked()
        AAC:SaveSettings()
    end)
    yOffset = yOffset - 40
    
    -- Section: Ability Types
    local abilityTitle = container:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    abilityTitle:SetPoint("TOPLEFT", container, "TOPLEFT", 20, yOffset)
    abilityTitle:SetText("Ability Types")
    yOffset = yOffset - 25
    
    -- Interrupts checkbox
    local interruptCheckbox = self:CreateCheckBox(container, "Enable Interrupts", 
                                                "Enables or disables automatic interrupting", 20, yOffset)
    interruptCheckbox:SetChecked(AAC.settings.global.interrupts.enabled)
    interruptCheckbox:SetScript("OnClick", function(self)
        AAC.settings.global.interrupts.enabled = self:GetChecked()
        AAC:SaveSettings()
    end)
    yOffset = yOffset - 25
    
    -- Dispels checkbox
    local dispelCheckbox = self:CreateCheckBox(container, "Enable Dispels", 
                                              "Enables or disables automatic dispelling", 20, yOffset)
    dispelCheckbox:SetChecked(AAC.settings.global.dispels.enabled)
    dispelCheckbox:SetScript("OnClick", function(self)
        AAC.settings.global.dispels.enabled = self:GetChecked()
        AAC:SaveSettings()
    end)
    yOffset = yOffset - 25
    
    -- Crowd Control checkbox
    local ccCheckbox = self:CreateCheckBox(container, "Enable Crowd Control", 
                                          "Enables or disables automatic crowd control", 20, yOffset)
    ccCheckbox:SetChecked(AAC.settings.global.crowdControl.enabled)
    ccCheckbox:SetScript("OnClick", function(self)
        AAC.settings.global.crowdControl.enabled = self:GetChecked()
        AAC:SaveSettings()
    end)
    yOffset = yOffset - 40
    
    -- Section: Quick Settings
    local quickTitle = container:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    quickTitle:SetPoint("TOPLEFT", container, "TOPLEFT", 20, yOffset)
    quickTitle:SetText("Quick Settings")
    yOffset = yOffset - 30
    
    -- Quick presets for delay times
    local presetTitle = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    presetTitle:SetPoint("TOPLEFT", container, "TOPLEFT", 20, yOffset)
    presetTitle:SetText("Delay Presets:")
    yOffset = yOffset - 25
    
    -- Instant (0 delay) preset
    local instantButton = CreateFrame("Button", nil, container, "UIPanelButtonTemplate")
    instantButton:SetSize(100, 22)
    instantButton:SetPoint("TOPLEFT", container, "TOPLEFT", 40, yOffset)
    instantButton:SetText("Instant")
    instantButton:SetScript("OnClick", function()
        -- Set all delay modes to instant
        AAC.settings.global.interrupts.timingMode = "instant"
        AAC.settings.global.dispels.timingMode = "instant"
        AAC.settings.global.crowdControl.timingMode = "instant"
        AAC:SaveSettings()
        
        -- Update UI
        self:UpdateAllTabs()
    end)
    
    -- Quick (0.1-0.3s) preset
    local quickButton = CreateFrame("Button", nil, container, "UIPanelButtonTemplate")
    quickButton:SetSize(100, 22)
    quickButton:SetPoint("LEFT", instantButton, "RIGHT", 10, 0)
    quickButton:SetText("Quick")
    quickButton:SetScript("OnClick", function()
        -- Set all delay modes to human with quick timing
        AAC.settings.global.interrupts.timingMode = "human"
        AAC.settings.global.interrupts.minDelay = 0.1
        AAC.settings.global.interrupts.maxDelay = 0.3
        
        AAC.settings.global.dispels.timingMode = "human"
        AAC.settings.global.dispels.minDelay = 0.1
        AAC.settings.global.dispels.maxDelay = 0.3
        
        AAC.settings.global.crowdControl.timingMode = "human"
        AAC.settings.global.crowdControl.minDelay = 0.1
        AAC.settings.global.crowdControl.maxDelay = 0.3
        
        AAC:SaveSettings()
        
        -- Update UI
        self:UpdateAllTabs()
    end)
    
    -- Human (0.3-0.8s) preset
    local humanButton = CreateFrame("Button", nil, container, "UIPanelButtonTemplate")
    humanButton:SetSize(100, 22)
    humanButton:SetPoint("LEFT", quickButton, "RIGHT", 10, 0)
    humanButton:SetText("Human")
    humanButton:SetScript("OnClick", function()
        -- Set all delay modes to human with natural timing
        AAC.settings.global.interrupts.timingMode = "human"
        AAC.settings.global.interrupts.minDelay = 0.3
        AAC.settings.global.interrupts.maxDelay = 0.8
        
        AAC.settings.global.dispels.timingMode = "human"
        AAC.settings.global.dispels.minDelay = 0.3
        AAC.settings.global.dispels.maxDelay = 0.8
        
        AAC.settings.global.crowdControl.timingMode = "human"
        AAC.settings.global.crowdControl.minDelay = 0.3
        AAC.settings.global.crowdControl.maxDelay = 0.8
        
        AAC:SaveSettings()
        
        -- Update UI
        self:UpdateAllTabs()
    end)
    
    -- Slow (0.5-1.5s) preset
    local slowButton = CreateFrame("Button", nil, container, "UIPanelButtonTemplate")
    slowButton:SetSize(100, 22)
    slowButton:SetPoint("LEFT", humanButton, "RIGHT", 10, 0)
    slowButton:SetText("Slow")
    slowButton:SetScript("OnClick", function()
        -- Set all delay modes to human with slow timing
        AAC.settings.global.interrupts.timingMode = "human"
        AAC.settings.global.interrupts.minDelay = 0.5
        AAC.settings.global.interrupts.maxDelay = 1.5
        
        AAC.settings.global.dispels.timingMode = "human"
        AAC.settings.global.dispels.minDelay = 0.5
        AAC.settings.global.dispels.maxDelay = 1.5
        
        AAC.settings.global.crowdControl.timingMode = "human"
        AAC.settings.global.crowdControl.minDelay = 0.5
        AAC.settings.global.crowdControl.maxDelay = 1.5
        
        AAC:SaveSettings()
        
        -- Update UI
        self:UpdateAllTabs()
    end)
    
    yOffset = yOffset - 40
    
    -- Restore defaults button
    local defaultsButton = CreateFrame("Button", nil, container, "UIPanelButtonTemplate")
    defaultsButton:SetSize(150, 22)
    defaultsButton:SetPoint("TOPLEFT", container, "TOPLEFT", 20, yOffset)
    defaultsButton:SetText("Restore Defaults")
    defaultsButton:SetScript("OnClick", function()
        -- Ask for confirmation
        StaticPopupDialogs["WINDRUNNER_RESTORE_AAC_DEFAULTS"] = {
            text = "Are you sure you want to restore all Advanced Ability Control settings to their defaults? This cannot be undone.",
            button1 = "Yes",
            button2 = "No",
            OnAccept = function()
                -- Reset settings to defaults
                AAC.settings = AAC:DeepCopy(AAC.defaultSettings)
                AAC:SaveSettings()
                
                -- Reload UI
                self:UpdateAllTabs()
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true
        }
        StaticPopup_Show("WINDRUNNER_RESTORE_AAC_DEFAULTS")
    end)
    
    -- Status button
    local statusButton = CreateFrame("Button", nil, container, "UIPanelButtonTemplate")
    statusButton:SetSize(150, 22)
    statusButton:SetPoint("LEFT", defaultsButton, "RIGHT", 20, 0)
    statusButton:SetText("Show Status")
    statusButton:SetScript("OnClick", function()
        AAC:PrintStatus()
    end)
    
    -- Rescan abilities button
    local rescanButton = CreateFrame("Button", nil, container, "UIPanelButtonTemplate")
    rescanButton:SetSize(150, 22)
    rescanButton:SetPoint("LEFT", statusButton, "RIGHT", 20, 0)
    rescanButton:SetText("Rescan Abilities")
    rescanButton:SetScript("OnClick", function()
        AAC:ScanPlayerAbilities()
        print("|cFF00FFFF[Advanced Ability Control]|r Rescanned player abilities")
        print("Found " .. #AAC.abilityRegistry.interrupts .. " interrupts")
        print("Found " .. #AAC.abilityRegistry.dispels .. " dispels")
        print("Found " .. #AAC.abilityRegistry.crowdControl .. " crowd control abilities")
    end)
    
    yOffset = yOffset - 50
    
    -- Available abilities section
    local abilitiesTitle = container:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    abilitiesTitle:SetPoint("TOPLEFT", container, "TOPLEFT", 20, yOffset)
    abilitiesTitle:SetText("Available Abilities")
    yOffset = yOffset - 30
    
    -- Function to add ability list
    local function AddAbilityList(title, abilities, yPos)
        local listTitle = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        listTitle:SetPoint("TOPLEFT", container, "TOPLEFT", 40, yPos)
        listTitle:SetText(title .. ":")
        yPos = yPos - 20
        
        if #abilities == 0 then
            local noAbilities = container:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            noAbilities:SetPoint("TOPLEFT", container, "TOPLEFT", 60, yPos)
            noAbilities:SetText("None found")
            yPos = yPos - 20
        else
            for i, ability in ipairs(abilities) do
                local icon = container:CreateTexture(nil, "ARTWORK")
                icon:SetSize(16, 16)
                icon:SetPoint("TOPLEFT", container, "TOPLEFT", 60, yPos)
                icon:SetTexture(ability.icon)
                
                local name = container:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                name:SetPoint("TOPLEFT", container, "TOPLEFT", 80, yPos)
                name:SetText(ability.name)
                
                yPos = yPos - 20
                
                -- Only show first 5 abilities to save space
                if i >= 5 then
                    local more = container:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                    more:SetPoint("TOPLEFT", container, "TOPLEFT", 80, yPos)
                    more:SetText("... and " .. (#abilities - 5) .. " more")
                    yPos = yPos - 20
                    break
                end
            end
        end
        
        return yPos
    end
    
    -- Add lists of available abilities
    yOffset = AddAbilityList("Interrupts", AAC.abilityRegistry.interrupts or {}, yOffset)
    yOffset = yOffset - 10
    yOffset = AddAbilityList("Dispels", AAC.abilityRegistry.dispels or {}, yOffset)
    yOffset = yOffset - 10
    yOffset = AddAbilityList("Crowd Control", AAC.abilityRegistry.crowdControl or {}, yOffset)
end

-- Create interrupts tab
function AdvancedAbilityControlUI:CreateInterruptsTab(tabFrames)
    local container = tabFrames.scrollChild
    local yOffset = -20
    
    -- Title
    local title = container:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", container, "TOPLEFT", 20, yOffset)
    title:SetText("Interrupt Settings")
    yOffset = yOffset - 30
    
    -- Enable interrupts checkbox
    local enableCheckbox = self:CreateCheckBox(container, "Enable Interrupts", 
                                               "Enables or disables automatic interrupting", 20, yOffset)
    enableCheckbox:SetChecked(AAC.settings.global.interrupts.enabled)
    enableCheckbox:SetScript("OnClick", function(self)
        AAC.settings.global.interrupts.enabled = self:GetChecked()
        AAC:SaveSettings()
    end)
    yOffset = yOffset - 30
    
    -- Section: Timing
    local timingTitle = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    timingTitle:SetPoint("TOPLEFT", container, "TOPLEFT", 20, yOffset)
    timingTitle:SetText("Interrupt Timing:")
    yOffset = yOffset - 25
    
    -- Timing mode dropdown
    local timingLabel = container:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    timingLabel:SetPoint("TOPLEFT", container, "TOPLEFT", 40, yOffset)
    timingLabel:SetText("Timing Mode:")
    
    local timingDropdown = CreateFrame("Frame", "WRInterruptTimingDropdown", container, "UIDropDownMenuTemplate")
    timingDropdown:SetPoint("TOPLEFT", timingLabel, "TOPRIGHT", 10, 0)
    
    local timingModes = {
        {text = "Instant (0 delay)", value = "instant"},
        {text = "Human-like (randomized middle)", value = "human"},
        {text = "Random (fully random)", value = "random"},
        {text = "Variable (based on priority)", value = "variable"},
        {text = "Percentage (cast % based)", value = "percentage"}
    }
    
    local function TimingDropdown_OnClick(self)
        UIDropDownMenu_SetSelectedValue(timingDropdown, self.value)
        AAC.settings.global.interrupts.timingMode = self.value
        AAC:SaveSettings()
    end
    
    local function TimingDropdown_Initialize(self, level)
        local info = UIDropDownMenu_CreateInfo()
        for _, mode in ipairs(timingModes) do
            info.text = mode.text
            info.value = mode.value
            info.checked = mode.value == AAC.settings.global.interrupts.timingMode
            info.func = TimingDropdown_OnClick
            UIDropDownMenu_AddButton(info, level)
        end
    end
    
    UIDropDownMenu_Initialize(timingDropdown, TimingDropdown_Initialize)
    UIDropDownMenu_SetWidth(timingDropdown, 200)
    UIDropDownMenu_SetButtonWidth(timingDropdown, 224)
    UIDropDownMenu_SetSelectedValue(timingDropdown, AAC.settings.global.interrupts.timingMode)
    UIDropDownMenu_JustifyText(timingDropdown, "LEFT")
    
    yOffset = yOffset - 30
    
    -- Min delay slider
    local minDelayLabel = container:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    minDelayLabel:SetPoint("TOPLEFT", container, "TOPLEFT", 40, yOffset)
    minDelayLabel:SetText("Minimum Delay (seconds):")
    
    local minDelaySlider = CreateFrame("Slider", "WRInterruptMinDelaySlider", container, "OptionsSliderTemplate")
    minDelaySlider:SetPoint("TOPLEFT", minDelayLabel, "BOTTOMLEFT", 0, -10)
    minDelaySlider:SetWidth(300)
    minDelaySlider:SetMinMaxValues(0, 2)
    minDelaySlider:SetValueStep(0.05)
    minDelaySlider:SetObeyStepOnDrag(true)
    minDelaySlider:SetValue(AAC.settings.global.interrupts.minDelay)
    
    minDelaySlider.Low:SetText("0")
    minDelaySlider.High:SetText("2")
    minDelaySlider.Text:SetText(format("%.2f", AAC.settings.global.interrupts.minDelay))
    
    minDelaySlider:SetScript("OnValueChanged", function(self, value)
        value = floor(value * 100) / 100 -- Round to 2 decimal places
        self.Text:SetText(format("%.2f", value))
        AAC.settings.global.interrupts.minDelay = value
        
        -- Ensure max is not less than min
        if value > AAC.settings.global.interrupts.maxDelay then
            AAC.settings.global.interrupts.maxDelay = value
            maxDelaySlider:SetValue(value)
        end
        
        AAC:SaveSettings()
    end)
    
    yOffset = yOffset - 50
    
    -- Max delay slider
    local maxDelayLabel = container:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    maxDelayLabel:SetPoint("TOPLEFT", container, "TOPLEFT", 40, yOffset)
    maxDelayLabel:SetText("Maximum Delay (seconds):")
    
    local maxDelaySlider = CreateFrame("Slider", "WRInterruptMaxDelaySlider", container, "OptionsSliderTemplate")
    maxDelaySlider:SetPoint("TOPLEFT", maxDelayLabel, "BOTTOMLEFT", 0, -10)
    maxDelaySlider:SetWidth(300)
    maxDelaySlider:SetMinMaxValues(0, 3)
    maxDelaySlider:SetValueStep(0.05)
    maxDelaySlider:SetObeyStepOnDrag(true)
    maxDelaySlider:SetValue(AAC.settings.global.interrupts.maxDelay)
    
    maxDelaySlider.Low:SetText("0")
    maxDelaySlider.High:SetText("3")
    maxDelaySlider.Text:SetText(format("%.2f", AAC.settings.global.interrupts.maxDelay))
    
    maxDelaySlider:SetScript("OnValueChanged", function(self, value)
        value = floor(value * 100) / 100 -- Round to 2 decimal places
        self.Text:SetText(format("%.2f", value))
        AAC.settings.global.interrupts.maxDelay = value
        
        -- Ensure min is not greater than max
        if value < AAC.settings.global.interrupts.minDelay then
            AAC.settings.global.interrupts.minDelay = value
            minDelaySlider:SetValue(value)
        end
        
        AAC:SaveSettings()
    end)
    
    yOffset = yOffset - 50
    
    -- Cast percentage slider for percentage mode
    local castPctLabel = container:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    castPctLabel:SetPoint("TOPLEFT", container, "TOPLEFT", 40, yOffset)
    castPctLabel:SetText("Target Cast Percentage (%):")
    
    local castPctSlider = CreateFrame("Slider", "WRInterruptCastPctSlider", container, "OptionsSliderTemplate")
    castPctSlider:SetPoint("TOPLEFT", castPctLabel, "BOTTOMLEFT", 0, -10)
    castPctSlider:SetWidth(300)
    castPctSlider:SetMinMaxValues(1, 99)
    castPctSlider:SetValueStep(1)
    castPctSlider:SetObeyStepOnDrag(true)
    castPctSlider:SetValue(AAC.settings.global.interrupts.targetPercentage)
    
    castPctSlider.Low:SetText("1%")
    castPctSlider.High:SetText("99%")
    castPctSlider.Text:SetText(AAC.settings.global.interrupts.targetPercentage .. "%")
    
    castPctSlider:SetScript("OnValueChanged", function(self, value)
        value = floor(value)
        self.Text:SetText(value .. "%")
        AAC.settings.global.interrupts.targetPercentage = value
        AAC:SaveSettings()
    end)
    
    yOffset = yOffset - 70
    
    -- Section: Behavior Options
    local behaviorTitle = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    behaviorTitle:SetPoint("TOPLEFT", container, "TOPLEFT", 20, yOffset)
    behaviorTitle:SetText("Behavior Options:")
    yOffset = yOffset - 25
    
    -- Ignore unknown spells
    local ignoreUnknownCheckbox = self:CreateCheckBox(container, "Ignore Unknown Spells", 
                                                     "Don't interrupt spells not in the database", 40, yOffset)
    ignoreUnknownCheckbox:SetChecked(AAC.settings.global.interrupts.ignoreUnknownSpells)
    ignoreUnknownCheckbox:SetScript("OnClick", function(self)
        AAC.settings.global.interrupts.ignoreUnknownSpells = self:GetChecked()
        AAC:SaveSettings()
    end)
    yOffset = yOffset - 25
    
    -- Save for priority
    local saveForPriorityCheckbox = self:CreateCheckBox(container, "Save Interrupt for High Priority Spells",
                                                       "Saves interrupt cooldown for more important spells", 40, yOffset)
    saveForPriorityCheckbox:SetChecked(AAC.settings.global.interrupts.saveForPriority)
    saveForPriorityCheckbox:SetScript("OnClick", function(self)
        AAC.settings.global.interrupts.saveForPriority = self:GetChecked()
        AAC:SaveSettings()
    end)
    yOffset = yOffset - 25
    
    -- Rotate with party
    local rotateWithPartyCheckbox = self:CreateCheckBox(container, "Coordinate with Party Members",
                                                       "Takes turns interrupting with other party members", 40, yOffset)
    rotateWithPartyCheckbox:SetChecked(AAC.settings.global.interrupts.rotateWithParty)
    rotateWithPartyCheckbox:SetScript("OnClick", function(self)
        AAC.settings.global.interrupts.rotateWithParty = self:GetChecked()
        AAC:SaveSettings()
    end)
    yOffset = yOffset - 25
    
    -- Prioritize casters
    local prioritizeCastersCheckbox = self:CreateCheckBox(container, "Prioritize Caster Enemies",
                                                         "Focus on interrupting caster enemies first", 40, yOffset)
    prioritizeCastersCheckbox:SetChecked(AAC.settings.global.interrupts.prioritizeCasters)
    prioritizeCastersCheckbox:SetScript("OnClick", function(self)
        AAC.settings.global.interrupts.prioritizeCasters = self:GetChecked()
        AAC:SaveSettings()
    end)
    yOffset = yOffset - 25
    
    -- Prioritize lockouts
    local prioritizeLockoutsCheckbox = self:CreateCheckBox(container, "Prioritize School Lockouts",
                                                          "Prefer interrupts that lock spell schools", 40, yOffset)
    prioritizeLockoutsCheckbox:SetChecked(AAC.settings.global.interrupts.prioritizeLockouts)
    prioritizeLockoutsCheckbox:SetScript("OnClick", function(self)
        AAC.settings.global.interrupts.prioritizeLockouts = self:GetChecked()
        AAC:SaveSettings()
    end)
    yOffset = yOffset - 25
    
    -- Allow moving to interrupt
    local allowMovingCheckbox = self:CreateCheckBox(container, "Move to Interrupt When Needed",
                                                   "Move into range to interrupt important spells", 40, yOffset)
    allowMovingCheckbox:SetChecked(AAC.settings.global.interrupts.allowMovingToInterrupt)
    allowMovingCheckbox:SetScript("OnClick", function(self)
        AAC.settings.global.interrupts.allowMovingToInterrupt = self:GetChecked()
        AAC:SaveSettings()
    end)
    yOffset = yOffset - 40
    
    -- Section: Priority Threshold
    local priorityTitle = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    priorityTitle:SetPoint("TOPLEFT", container, "TOPLEFT", 20, yOffset)
    priorityTitle:SetText("Priority Threshold:")
    yOffset = yOffset - 25
    
    -- Priority threshold dropdown
    local priorityLabel = container:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    priorityLabel:SetPoint("TOPLEFT", container, "TOPLEFT", 40, yOffset)
    priorityLabel:SetText("Minimum Priority Level:")
    
    local priorityDropdown = CreateFrame("Frame", "WRInterruptPriorityDropdown", container, "UIDropDownMenuTemplate")
    priorityDropdown:SetPoint("TOPLEFT", priorityLabel, "TOPRIGHT", 10, 0)
    
    local priorityLevels = {
        {text = "Ignored (Level 0)", value = 0},
        {text = "Low (Level 1)", value = 1},
        {text = "Medium (Level 2)", value = 2},
        {text = "High (Level 3)", value = 3},
        {text = "Critical (Level 4)", value = 4}
    }
    
    local function PriorityDropdown_OnClick(self)
        UIDropDownMenu_SetSelectedValue(priorityDropdown, self.value)
        AAC.settings.global.interrupts.priorityThreshold = self.value
        AAC:SaveSettings()
    end
    
    local function PriorityDropdown_Initialize(self, level)
        local info = UIDropDownMenu_CreateInfo()
        for _, priority in ipairs(priorityLevels) do
            info.text = priority.text
            info.value = priority.value
            info.checked = priority.value == AAC.settings.global.interrupts.priorityThreshold
            info.func = PriorityDropdown_OnClick
            UIDropDownMenu_AddButton(info, level)
        end
    end
    
    UIDropDownMenu_Initialize(priorityDropdown, PriorityDropdown_Initialize)
    UIDropDownMenu_SetWidth(priorityDropdown, 200)
    UIDropDownMenu_SetButtonWidth(priorityDropdown, 224)
    UIDropDownMenu_SetSelectedValue(priorityDropdown, AAC.settings.global.interrupts.priorityThreshold)
    UIDropDownMenu_JustifyText(priorityDropdown, "LEFT")
    
    yOffset = yOffset - 40
    
    -- Help text
    local helpText = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    helpText:SetPoint("TOPLEFT", container, "TOPLEFT", 20, yOffset)
    helpText:SetWidth(container:GetWidth() - 40)
    helpText:SetJustifyH("LEFT")
    helpText:SetText("Priority levels determine which spells are interrupted:\n\n" ..
                    "- Critical: Always interrupt, regardless of other settings\n" ..
                    "- High: Important spells that should usually be interrupted\n" ..
                    "- Medium: Normal spells that should be interrupted when possible\n" ..
                    "- Low: Less important spells that can be ignored if needed\n" ..
                    "- Ignored: Never interrupt these spells\n\n" ..
                    "You can set specific spell priorities in the Spell Lists tab.")
end

-- Create dispels tab
function AdvancedAbilityControlUI:CreateDispelsTab(tabFrames)
    local container = tabFrames.scrollChild
    local yOffset = -20
    
    -- Title
    local title = container:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", container, "TOPLEFT", 20, yOffset)
    title:SetText("Dispel Settings")
    yOffset = yOffset - 30
    
    -- Enable dispels checkbox
    local enableCheckbox = self:CreateCheckBox(container, "Enable Dispels", 
                                               "Enables or disables automatic dispelling", 20, yOffset)
    enableCheckbox:SetChecked(AAC.settings.global.dispels.enabled)
    enableCheckbox:SetScript("OnClick", function(self)
        AAC.settings.global.dispels.enabled = self:GetChecked()
        AAC:SaveSettings()
    end)
    yOffset = yOffset - 30
    
    -- Section: Timing
    local timingTitle = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    timingTitle:SetPoint("TOPLEFT", container, "TOPLEFT", 20, yOffset)
    timingTitle:SetText("Dispel Timing:")
    yOffset = yOffset - 25
    
    -- Timing mode dropdown
    local timingLabel = container:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    timingLabel:SetPoint("TOPLEFT", container, "TOPLEFT", 40, yOffset)
    timingLabel:SetText("Timing Mode:")
    
    local timingDropdown = CreateFrame("Frame", "WRDispelTimingDropdown", container, "UIDropDownMenuTemplate")
    timingDropdown:SetPoint("TOPLEFT", timingLabel, "TOPRIGHT", 10, 0)
    
    local timingModes = {
        {text = "Instant (0 delay)", value = "instant"},
        {text = "Human-like (randomized middle)", value = "human"},
        {text = "Random (fully random)", value = "random"},
        {text = "Variable (based on priority)", value = "variable"}
    }
    
    local function TimingDropdown_OnClick(self)
        UIDropDownMenu_SetSelectedValue(timingDropdown, self.value)
        AAC.settings.global.dispels.timingMode = self.value
        AAC:SaveSettings()
    end
    
    local function TimingDropdown_Initialize(self, level)
        local info = UIDropDownMenu_CreateInfo()
        for _, mode in ipairs(timingModes) do
            info.text = mode.text
            info.value = mode.value
            info.checked = mode.value == AAC.settings.global.dispels.timingMode
            info.func = TimingDropdown_OnClick
            UIDropDownMenu_AddButton(info, level)
        end
    end
    
    UIDropDownMenu_Initialize(timingDropdown, TimingDropdown_Initialize)
    UIDropDownMenu_SetWidth(timingDropdown, 200)
    UIDropDownMenu_SetButtonWidth(timingDropdown, 224)
    UIDropDownMenu_SetSelectedValue(timingDropdown, AAC.settings.global.dispels.timingMode)
    UIDropDownMenu_JustifyText(timingDropdown, "LEFT")
    
    yOffset = yOffset - 30
    
    -- Min delay slider
    local minDelayLabel = container:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    minDelayLabel:SetPoint("TOPLEFT", container, "TOPLEFT", 40, yOffset)
    minDelayLabel:SetText("Minimum Delay (seconds):")
    
    local minDelaySlider = CreateFrame("Slider", "WRDispelMinDelaySlider", container, "OptionsSliderTemplate")
    minDelaySlider:SetPoint("TOPLEFT", minDelayLabel, "BOTTOMLEFT", 0, -10)
    minDelaySlider:SetWidth(300)
    minDelaySlider:SetMinMaxValues(0, 2)
    minDelaySlider:SetValueStep(0.05)
    minDelaySlider:SetObeyStepOnDrag(true)
    minDelaySlider:SetValue(AAC.settings.global.dispels.minDelay)
    
    minDelaySlider.Low:SetText("0")
    minDelaySlider.High:SetText("2")
    minDelaySlider.Text:SetText(format("%.2f", AAC.settings.global.dispels.minDelay))
    
    minDelaySlider:SetScript("OnValueChanged", function(self, value)
        value = floor(value * 100) / 100 -- Round to 2 decimal places
        self.Text:SetText(format("%.2f", value))
        AAC.settings.global.dispels.minDelay = value
        
        -- Ensure max is not less than min
        if value > AAC.settings.global.dispels.maxDelay then
            AAC.settings.global.dispels.maxDelay = value
            maxDelaySlider:SetValue(value)
        end
        
        AAC:SaveSettings()
    end)
    
    yOffset = yOffset - 50
    
    -- Max delay slider
    local maxDelayLabel = container:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    maxDelayLabel:SetPoint("TOPLEFT", container, "TOPLEFT", 40, yOffset)
    maxDelayLabel:SetText("Maximum Delay (seconds):")
    
    local maxDelaySlider = CreateFrame("Slider", "WRDispelMaxDelaySlider", container, "OptionsSliderTemplate")
    maxDelaySlider:SetPoint("TOPLEFT", maxDelayLabel, "BOTTOMLEFT", 0, -10)
    maxDelaySlider:SetWidth(300)
    maxDelaySlider:SetMinMaxValues(0, 3)
    maxDelaySlider:SetValueStep(0.05)
    maxDelaySlider:SetObeyStepOnDrag(true)
    maxDelaySlider:SetValue(AAC.settings.global.dispels.maxDelay)
    
    maxDelaySlider.Low:SetText("0")
    maxDelaySlider.High:SetText("3")
    maxDelaySlider.Text:SetText(format("%.2f", AAC.settings.global.dispels.maxDelay))
    
    maxDelaySlider:SetScript("OnValueChanged", function(self, value)
        value = floor(value * 100) / 100 -- Round to 2 decimal places
        self.Text:SetText(format("%.2f", value))
        AAC.settings.global.dispels.maxDelay = value
        
        -- Ensure min is not greater than max
        if value < AAC.settings.global.dispels.minDelay then
            AAC.settings.global.dispels.minDelay = value
            minDelaySlider:SetValue(value)
        end
        
        AAC:SaveSettings()
    end)
    
    yOffset = yOffset - 50
    
    -- Section: Dispel Options
    local optionsTitle = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    optionsTitle:SetPoint("TOPLEFT", container, "TOPLEFT", 20, yOffset)
    optionsTitle:SetText("Dispel Options:")
    yOffset = yOffset - 25
    
    -- Safety health threshold slider
    local healthThresholdLabel = container:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    healthThresholdLabel:SetPoint("TOPLEFT", container, "TOPLEFT", 40, yOffset)
    healthThresholdLabel:SetText("Safety Health Threshold (%):")
    
    local healthThresholdSlider = CreateFrame("Slider", "WRDispelHealthThresholdSlider", container, "OptionsSliderTemplate")
    healthThresholdSlider:SetPoint("TOPLEFT", healthThresholdLabel, "BOTTOMLEFT", 0, -10)
    healthThresholdSlider:SetWidth(300)
    healthThresholdSlider:SetMinMaxValues(0, 1)
    healthThresholdSlider:SetValueStep(0.05)
    healthThresholdSlider:SetObeyStepOnDrag(true)
    healthThresholdSlider:SetValue(AAC.settings.global.dispels.safetyHealthThreshold)
    
    healthThresholdSlider.Low:SetText("0%")
    healthThresholdSlider.High:SetText("100%")
    healthThresholdSlider.Text:SetText(format("%.0f%%", AAC.settings.global.dispels.safetyHealthThreshold * 100))
    
    healthThresholdSlider:SetScript("OnValueChanged", function(self, value)
        value = floor(value * 20) / 20 -- Round to nearest 5%
        self.Text:SetText(format("%.0f%%", value * 100))
        AAC.settings.global.dispels.safetyHealthThreshold = value
        AAC:SaveSettings()
    end)
    
    yOffset = yOffset - 50
    
    -- Minimum debuff duration slider
    local minDurationLabel = container:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    minDurationLabel:SetPoint("TOPLEFT", container, "TOPLEFT", 40, yOffset)
    minDurationLabel:SetText("Minimum Debuff Duration (seconds):")
    
    local minDurationSlider = CreateFrame("Slider", "WRDispelMinDurationSlider", container, "OptionsSliderTemplate")
    minDurationSlider:SetPoint("TOPLEFT", minDurationLabel, "BOTTOMLEFT", 0, -10)
    minDurationSlider:SetWidth(300)
    minDurationSlider:SetMinMaxValues(0, 10)
    minDurationSlider:SetValueStep(0.5)
    minDurationSlider:SetObeyStepOnDrag(true)
    minDurationSlider:SetValue(AAC.settings.global.dispels.minDebuffDuration)
    
    minDurationSlider.Low:SetText("0s")
    minDurationSlider.High:SetText("10s")
    minDurationSlider.Text:SetText(format("%.1fs", AAC.settings.global.dispels.minDebuffDuration))
    
    minDurationSlider:SetScript("OnValueChanged", function(self, value)
        value = floor(value * 10) / 10 -- Round to 1 decimal place
        self.Text:SetText(format("%.1fs", value))
        AAC.settings.global.dispels.minDebuffDuration = value
        AAC:SaveSettings()
    end)
    
    yOffset = yOffset - 50
    
    -- Stack threshold slider
    local stackThresholdLabel = container:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    stackThresholdLabel:SetPoint("TOPLEFT", container, "TOPLEFT", 40, yOffset)
    stackThresholdLabel:SetText("Stack Threshold:")
    
    local stackThresholdSlider = CreateFrame("Slider", "WRDispelStackThresholdSlider", container, "OptionsSliderTemplate")
    stackThresholdSlider:SetPoint("TOPLEFT", stackThresholdLabel, "BOTTOMLEFT", 0, -10)
    stackThresholdSlider:SetWidth(300)
    stackThresholdSlider:SetMinMaxValues(1, 10)
    stackThresholdSlider:SetValueStep(1)
    stackThresholdSlider:SetObeyStepOnDrag(true)
    stackThresholdSlider:SetValue(AAC.settings.global.dispels.stackThreshold)
    
    stackThresholdSlider.Low:SetText("1")
    stackThresholdSlider.High:SetText("10")
    stackThresholdSlider.Text:SetText(AAC.settings.global.dispels.stackThreshold)
    
    stackThresholdSlider:SetScript("OnValueChanged", function(self, value)
        value = floor(value)
        self.Text:SetText(value)
        AAC.settings.global.dispels.stackThreshold = value
        AAC:SaveSettings()
    end)
    
    yOffset = yOffset - 50
    
    -- Section: Dispel Type Priorities
    local typeTitle = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    typeTitle:SetPoint("TOPLEFT", container, "TOPLEFT", 20, yOffset)
    typeTitle:SetText("Dispel Type Priorities:")
    yOffset = yOffset - 25
    
    -- Create dropdown for each dispel type
    local dispelTypes = {
        {name = "Magic", key = "Magic"},
        {name = "Curse", key = "Curse"},
        {name = "Disease", key = "Disease"},
        {name = "Poison", key = "Poison"},
        {name = "Enrage", key = "Enrage"}
    }
    
    for i, dispelType in ipairs(dispelTypes) do
        local typeLabel = container:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        typeLabel:SetPoint("TOPLEFT", container, "TOPLEFT", 40, yOffset)
        typeLabel:SetText(dispelType.name .. ":")
        
        local typeDropdown = CreateFrame("Frame", "WRDispelType" .. dispelType.key .. "Dropdown", container, "UIDropDownMenuTemplate")
        typeDropdown:SetPoint("TOPLEFT", typeLabel, "TOPRIGHT", 10, 0)
        
        local function TypeDropdown_OnClick(self)
            UIDropDownMenu_SetSelectedValue(typeDropdown, self.value)
            AAC.settings.global.dispels.typePriorities[dispelType.key] = self.value
            AAC:SaveSettings()
        end
        
        local function TypeDropdown_Initialize(self, level)
            local info = UIDropDownMenu_CreateInfo()
            for _, priority in ipairs(priorityLevels) do
                info.text = priority.text
                info.value = priority.value
                info.checked = priority.value == AAC.settings.global.dispels.typePriorities[dispelType.key]
                info.func = TypeDropdown_OnClick
                UIDropDownMenu_AddButton(info, level)
            end
        end
        
        UIDropDownMenu_Initialize(typeDropdown, TypeDropdown_Initialize)
        UIDropDownMenu_SetWidth(typeDropdown, 150)
        UIDropDownMenu_SetButtonWidth(typeDropdown, 174)
        UIDropDownMenu_SetSelectedValue(typeDropdown, AAC.settings.global.dispels.typePriorities[dispelType.key])
        UIDropDownMenu_JustifyText(typeDropdown, "LEFT")
        
        yOffset = yOffset - 30
    end
    
    yOffset = yOffset - 10
    
    -- Section: Behavior Options
    local behaviorTitle = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    behaviorTitle:SetPoint("TOPLEFT", container, "TOPLEFT", 20, yOffset)
    behaviorTitle:SetText("Behavior Options:")
    yOffset = yOffset - 25
    
    -- Allow expensive dispels
    local expensiveCheckbox = self:CreateCheckBox(container, "Allow Expensive Dispels",
                                                "Use high-cost dispels like Mass Dispel", 40, yOffset)
    expensiveCheckbox:SetChecked(AAC.settings.global.dispels.allowExpensiveDispels)
    expensiveCheckbox:SetScript("OnClick", function(self)
        AAC.settings.global.dispels.allowExpensiveDispels = self:GetChecked()
        AAC:SaveSettings()
    end)
    yOffset = yOffset - 25
    
    -- Healer priority
    local healerPriorityCheckbox = self:CreateCheckBox(container, "Healer Priority",
                                                      "Let healers handle dispels when possible", 40, yOffset)
    healerPriorityCheckbox:SetChecked(AAC.settings.global.dispels.healerPriority)
    healerPriorityCheckbox:SetScript("OnClick", function(self)
        AAC.settings.global.dispels.healerPriority = self:GetChecked()
        AAC:SaveSettings()
    end)
    yOffset = yOffset - 25
    
    -- Auto dispel on self
    local autoSelfCheckbox = self:CreateCheckBox(container, "Auto-Dispel Self",
                                                "Always dispel harmful effects on yourself", 40, yOffset)
    autoSelfCheckbox:SetChecked(AAC.settings.global.dispels.autoDispelOnSelf)
    autoSelfCheckbox:SetScript("OnClick", function(self)
        AAC.settings.global.dispels.autoDispelOnSelf = self:GetChecked()
        AAC:SaveSettings()
    end)
end

-- Create crowd control tab
function AdvancedAbilityControlUI:CreateCrowdControlTab(tabFrames)
    local container = tabFrames.scrollChild
    local yOffset = -20
    
    -- Title
    local title = container:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", container, "TOPLEFT", 20, yOffset)
    title:SetText("Crowd Control Settings")
    yOffset = yOffset - 30
    
    -- Enable CC checkbox
    local enableCheckbox = self:CreateCheckBox(container, "Enable Crowd Control", 
                                              "Enables or disables automatic crowd control", 20, yOffset)
    enableCheckbox:SetChecked(AAC.settings.global.crowdControl.enabled)
    enableCheckbox:SetScript("OnClick", function(self)
        AAC.settings.global.crowdControl.enabled = self:GetChecked()
        AAC:SaveSettings()
    end)
    yOffset = yOffset - 30
    
    -- Section: Timing
    local timingTitle = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    timingTitle:SetPoint("TOPLEFT", container, "TOPLEFT", 20, yOffset)
    timingTitle:SetText("Crowd Control Timing:")
    yOffset = yOffset - 25
    
    -- Timing mode dropdown
    local timingLabel = container:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    timingLabel:SetPoint("TOPLEFT", container, "TOPLEFT", 40, yOffset)
    timingLabel:SetText("Timing Mode:")
    
    local timingDropdown = CreateFrame("Frame", "WRCCTimingDropdown", container, "UIDropDownMenuTemplate")
    timingDropdown:SetPoint("TOPLEFT", timingLabel, "TOPRIGHT", 10, 0)
    
    local timingModes = {
        {text = "Instant (0 delay)", value = "instant"},
        {text = "Human-like (randomized middle)", value = "human"},
        {text = "Random (fully random)", value = "random"},
        {text = "Variable (based on CC type)", value = "variable"}
    }
    
    local function TimingDropdown_OnClick(self)
        UIDropDownMenu_SetSelectedValue(timingDropdown, self.value)
        AAC.settings.global.crowdControl.timingMode = self.value
        AAC:SaveSettings()
    end
    
    local function TimingDropdown_Initialize(self, level)
        local info = UIDropDownMenu_CreateInfo()
        for _, mode in ipairs(timingModes) do
            info.text = mode.text
            info.value = mode.value
            info.checked = mode.value == AAC.settings.global.crowdControl.timingMode
            info.func = TimingDropdown_OnClick
            UIDropDownMenu_AddButton(info, level)
        end
    end
    
    UIDropDownMenu_Initialize(timingDropdown, TimingDropdown_Initialize)
    UIDropDownMenu_SetWidth(timingDropdown, 200)
    UIDropDownMenu_SetButtonWidth(timingDropdown, 224)
    UIDropDownMenu_SetSelectedValue(timingDropdown, AAC.settings.global.crowdControl.timingMode)
    UIDropDownMenu_JustifyText(timingDropdown, "LEFT")
    
    yOffset = yOffset - 30
    
    -- Min delay slider
    local minDelayLabel = container:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    minDelayLabel:SetPoint("TOPLEFT", container, "TOPLEFT", 40, yOffset)
    minDelayLabel:SetText("Minimum Delay (seconds):")
    
    local minDelaySlider = CreateFrame("Slider", "WRCCMinDelaySlider", container, "OptionsSliderTemplate")
    minDelaySlider:SetPoint("TOPLEFT", minDelayLabel, "BOTTOMLEFT", 0, -10)
    minDelaySlider:SetWidth(300)
    minDelaySlider:SetMinMaxValues(0, 2)
    minDelaySlider:SetValueStep(0.05)
    minDelaySlider:SetObeyStepOnDrag(true)
    minDelaySlider:SetValue(AAC.settings.global.crowdControl.minDelay)
    
    minDelaySlider.Low:SetText("0")
    minDelaySlider.High:SetText("2")
    minDelaySlider.Text:SetText(format("%.2f", AAC.settings.global.crowdControl.minDelay))
    
    minDelaySlider:SetScript("OnValueChanged", function(self, value)
        value = floor(value * 100) / 100 -- Round to 2 decimal places
        self.Text:SetText(format("%.2f", value))
        AAC.settings.global.crowdControl.minDelay = value
        
        -- Ensure max is not less than min
        if value > AAC.settings.global.crowdControl.maxDelay then
            AAC.settings.global.crowdControl.maxDelay = value
            maxDelaySlider:SetValue(value)
        end
        
        AAC:SaveSettings()
    end)
    
    yOffset = yOffset - 50
    
    -- Max delay slider
    local maxDelayLabel = container:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    maxDelayLabel:SetPoint("TOPLEFT", container, "TOPLEFT", 40, yOffset)
    maxDelayLabel:SetText("Maximum Delay (seconds):")
    
    local maxDelaySlider = CreateFrame("Slider", "WRCCMaxDelaySlider", container, "OptionsSliderTemplate")
    maxDelaySlider:SetPoint("TOPLEFT", maxDelayLabel, "BOTTOMLEFT", 0, -10)
    maxDelaySlider:SetWidth(300)
    maxDelaySlider:SetMinMaxValues(0, 3)
    maxDelaySlider:SetValueStep(0.05)
    maxDelaySlider:SetObeyStepOnDrag(true)
    maxDelaySlider:SetValue(AAC.settings.global.crowdControl.maxDelay)
    
    maxDelaySlider.Low:SetText("0")
    maxDelaySlider.High:SetText("3")
    maxDelaySlider.Text:SetText(format("%.2f", AAC.settings.global.crowdControl.maxDelay))
    
    maxDelaySlider:SetScript("OnValueChanged", function(self, value)
        value = floor(value * 100) / 100 -- Round to 2 decimal places
        self.Text:SetText(format("%.2f", value))
        AAC.settings.global.crowdControl.maxDelay = value
        
        -- Ensure min is not greater than max
        if value < AAC.settings.global.crowdControl.minDelay then
            AAC.settings.global.crowdControl.minDelay = value
            minDelaySlider:SetValue(value)
        end
        
        AAC:SaveSettings()
    end)
    
    yOffset = yOffset - 50
    
    -- Section: Priority
    local priorityTitle = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    priorityTitle:SetPoint("TOPLEFT", container, "TOPLEFT", 20, yOffset)
    priorityTitle:SetText("Priority Settings:")
    yOffset = yOffset - 25
    
    -- Priority threshold dropdown
    local priorityLabel = container:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    priorityLabel:SetPoint("TOPLEFT", container, "TOPLEFT", 40, yOffset)
    priorityLabel:SetText("Minimum Priority Level:")
    
    local priorityDropdown = CreateFrame("Frame", "WRCCPriorityDropdown", container, "UIDropDownMenuTemplate")
    priorityDropdown:SetPoint("TOPLEFT", priorityLabel, "TOPRIGHT", 10, 0)
    
    local priorityLevels = {
        {text = "Ignored (Level 0)", value = 0},
        {text = "Low (Level 1)", value = 1},
        {text = "Medium (Level 2)", value = 2},
        {text = "High (Level 3)", value = 3},
        {text = "Critical (Level 4)", value = 4}
    }
    
    local function PriorityDropdown_OnClick(self)
        UIDropDownMenu_SetSelectedValue(priorityDropdown, self.value)
        AAC.settings.global.crowdControl.priorityThreshold = self.value
        AAC:SaveSettings()
    end
    
    local function PriorityDropdown_Initialize(self, level)
        local info = UIDropDownMenu_CreateInfo()
        for _, priority in ipairs(priorityLevels) do
            info.text = priority.text
            info.value = priority.value
            info.checked = priority.value == AAC.settings.global.crowdControl.priorityThreshold
            info.func = PriorityDropdown_OnClick
            UIDropDownMenu_AddButton(info, level)
        end
    end
    
    UIDropDownMenu_Initialize(priorityDropdown, PriorityDropdown_Initialize)
    UIDropDownMenu_SetWidth(priorityDropdown, 200)
    UIDropDownMenu_SetButtonWidth(priorityDropdown, 224)
    UIDropDownMenu_SetSelectedValue(priorityDropdown, AAC.settings.global.crowdControl.priorityThreshold)
    UIDropDownMenu_JustifyText(priorityDropdown, "LEFT")
    
    yOffset = yOffset - 40
    
    -- Section: Behavior Options
    local behaviorTitle = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    behaviorTitle:SetPoint("TOPLEFT", container, "TOPLEFT", 20, yOffset)
    behaviorTitle:SetText("Behavior Options:")
    yOffset = yOffset - 25
    
    -- Avoid DR checkbox
    local avoidDRCheckbox = self:CreateCheckBox(container, "Avoid Diminishing Returns",
                                               "Don't use CC when diminishing returns would reduce effectiveness", 40, yOffset)
    avoidDRCheckbox:SetChecked(AAC.settings.global.crowdControl.avoidDiminishingReturns)
    avoidDRCheckbox:SetScript("OnClick", function(self)
        AAC.settings.global.crowdControl.avoidDiminishingReturns = self:GetChecked()
        AAC:SaveSettings()
    end)
    yOffset = yOffset - 25
    
    -- Chain CC checkbox
    local chainCCCheckbox = self:CreateCheckBox(container, "Chain Crowd Control",
                                              "Coordinate CC with party members to maximize uptime", 40, yOffset)
    chainCCCheckbox:SetChecked(AAC.settings.global.crowdControl.chainCC)
    chainCCCheckbox:SetScript("OnClick", function(self)
        AAC.settings.global.crowdControl.chainCC = self:GetChecked()
        AAC:SaveSettings()
    end)
    yOffset = yOffset - 25
    
    -- Break on damage checkbox
    local breakOnDamageCheckbox = self:CreateCheckBox(container, "Break CC if Target Takes Damage",
                                                    "Don't waste CC on targets likely to break out due to damage", 40, yOffset)
    breakOnDamageCheckbox:SetChecked(AAC.settings.global.crowdControl.breakOnDamage)
    breakOnDamageCheckbox:SetScript("OnClick", function(self)
        AAC.settings.global.crowdControl.breakOnDamage = self:GetChecked()
        AAC:SaveSettings()
    end)
    yOffset = yOffset - 25
    
    -- CC priority targets checkbox
    local priorityTargetsCheckbox = self:CreateCheckBox(container, "CC Priority Targets First",
                                                      "Focus CC on healing targets and dangerous enemies first", 40, yOffset)
    priorityTargetsCheckbox:SetChecked(AAC.settings.global.crowdControl.ccPriorityTargets)
    priorityTargetsCheckbox:SetScript("OnClick", function(self)
        AAC.settings.global.crowdControl.ccPriorityTargets = self:GetChecked()
        AAC:SaveSettings()
    end)
    yOffset = yOffset - 40
    
    -- Section: Enabled CC Types
    local typesTitle = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    typesTitle:SetPoint("TOPLEFT", container, "TOPLEFT", 20, yOffset)
    typesTitle:SetText("Enabled CC Types:")
    yOffset = yOffset - 25
    
    -- Create checkboxes for each CC type
    local ccTypes = {
        {name = "Stun", key = "stun"},
        {name = "Root", key = "root"},
        {name = "Silence", key = "silence"},
        {name = "Incapacitate", key = "incapacitate"},
        {name = "Disorient", key = "disorient"},
        {name = "Fear", key = "fear"},
        {name = "Sleep", key = "sleep"},
        {name = "Cyclone", key = "cyclone"},
        {name = "Banish", key = "banish"},
        {name = "Horror", key = "horror"},
        {name = "Taunt", key = "taunt"}
    }
    
    -- Create columns for CC types
    local column1YOffset = yOffset
    local column2YOffset = yOffset
    
    for i, ccType in ipairs(ccTypes) do
        local checkbox
        
        if i <= 6 then
            -- First column
            checkbox = self:CreateCheckBox(container, ccType.name,
                                          "Enable " .. ccType.name .. " crowd control effects", 40, column1YOffset)
            column1YOffset = column1YOffset - 25
        else
            -- Second column
            checkbox = self:CreateCheckBox(container, ccType.name,
                                          "Enable " .. ccType.name .. " crowd control effects", 240, column2YOffset)
            column2YOffset = column2YOffset - 25
        end
        
        checkbox:SetChecked(AAC.settings.global.crowdControl.enabledTypes[ccType.key])
        checkbox:SetScript("OnClick", function(self)
            AAC.settings.global.crowdControl.enabledTypes[ccType.key] = self:GetChecked()
            AAC:SaveSettings()
        end)
    end
    
    -- Use whichever column went further
    yOffset = min(column1YOffset, column2YOffset) - 15
    
    -- Help text
    local helpText = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    helpText:SetPoint("TOPLEFT", container, "TOPLEFT", 20, yOffset)
    helpText:SetWidth(container:GetWidth() - 40)
    helpText:SetJustifyH("LEFT")
    helpText:SetText("Note: Different classes have access to different types of crowd control abilities. Enabling a type that your class doesn't have access to will have no effect.")
end

-- Create spell lists tab
function AdvancedAbilityControlUI:CreateSpellListsTab(tabFrames)
    local container = tabFrames.scrollChild
    local yOffset = -20
    
    -- Title
    local title = container:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", container, "TOPLEFT", 20, yOffset)
    title:SetText("Spell Lists")
    yOffset = yOffset - 30
    
    -- Description
    local desc = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    desc:SetPoint("TOPLEFT", container, "TOPLEFT", 20, yOffset)
    desc:SetWidth(container:GetWidth() - 40)
    desc:SetJustifyH("LEFT")
    desc:SetText("Configure which spells should always be interrupted, dispelled, or ignored. You can add spells to the whitelist (always use) or blacklist (never use).")
    yOffset = yOffset - 50
    
    -- Create tab buttons for different ability types
    local listTabWidth = 120
    local listTabHeight = 30
    local listTabContainer = CreateFrame("Frame", nil, container)
    listTabContainer:SetSize(listTabWidth * 3, listTabHeight)
    listTabContainer:SetPoint("TOPLEFT", container, "TOPLEFT", 20, yOffset)
    
    -- Create tab buttons and content frames
    local listTabs = {}
    local listContentFrames = {}
    local tabNames = {"Interrupts", "Dispels", "CC"}
    
    for i, name in ipairs(tabNames) do
        -- Create tab button
        local tab = CreateFrame("Button", nil, listTabContainer)
        tab:SetSize(listTabWidth, listTabHeight)
        tab:SetPoint("TOPLEFT", listTabContainer, "TOPLEFT", (i-1) * listTabWidth, 0)
        
        -- Create background and text
        tab.bg = tab:CreateTexture(nil, "BACKGROUND")
        tab.bg:SetAllPoints()
        tab.bg:SetColorTexture(0.2, 0.2, 0.2, 0.8)
        
        tab.text = tab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        tab.text:SetPoint("CENTER", tab, "CENTER", 0, 0)
        tab.text:SetText(name)
        
        -- Create highlight
        tab.highlight = tab:CreateTexture(nil, "HIGHLIGHT")
        tab.highlight:SetAllPoints()
        tab.highlight:SetColorTexture(0.3, 0.3, 0.3, 0.5)
        
        -- Create selected indicator
        tab.selected = tab:CreateTexture(nil, "OVERLAY")
        tab.selected:SetPoint("BOTTOMLEFT", tab, "BOTTOMLEFT", 0, 0)
        tab.selected:SetPoint("BOTTOMRIGHT", tab, "BOTTOMRIGHT", 0, 0)
        tab.selected:SetHeight(3)
        tab.selected:SetColorTexture(0.9, 0.7, 0, 1)
        tab.selected:Hide()
        
        -- Store reference
        listTabs[name] = tab
        
        -- Create content frame
        local contentFrame = CreateFrame("Frame", nil, container)
        contentFrame:SetPoint("TOPLEFT", listTabContainer, "BOTTOMLEFT", 0, -10)
        contentFrame:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", -20, 0)
        contentFrame:Hide()
        
        -- Store reference
        listContentFrames[name] = contentFrame
        
        -- Set click handler
        tab:SetScript("OnClick", function()
            -- Hide all content frames and deselect all tabs
            for tabName, tabObj in pairs(listTabs) do
                tabObj.selected:Hide()
                listContentFrames[tabName]:Hide()
            end
            
            -- Show this content frame and select this tab
            tab.selected:Show()
            contentFrame:Show()
        end)
    end
    
    -- Function to create spell list content
    local function CreateSpellListContent(frame, abilityType)
        local listYOffset = 10
        
        -- Add spell input section
        local addTitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        addTitle:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -listYOffset)
        addTitle:SetText("Add Spell")
        listYOffset = listYOffset + 25
        
        -- Spell ID input
        local spellIdLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        spellIdLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -listYOffset)
        spellIdLabel:SetText("Spell ID:")
        
        local spellIdEditBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
        spellIdEditBox:SetSize(100, 25)
        spellIdEditBox:SetPoint("TOPLEFT", spellIdLabel, "TOPRIGHT", 10, 0)
        spellIdEditBox:SetAutoFocus(false)
        spellIdEditBox:SetNumeric(true)
        
        -- Spell name display (after ID is entered)
        local spellNameDisplay = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        spellNameDisplay:SetPoint("TOPLEFT", spellIdEditBox, "TOPRIGHT", 10, 0)
        spellNameDisplay:SetText("")
        
        -- Update spell name when ID changes
        spellIdEditBox:SetScript("OnTextChanged", function(self)
            local spellId = tonumber(self:GetText())
            if spellId then
                local name = GetSpellInfo(spellId)
                if name then
                    spellNameDisplay:SetText(name)
                    spellNameDisplay:SetTextColor(1, 1, 1)
                else
                    spellNameDisplay:SetText("Unknown spell")
                    spellNameDisplay:SetTextColor(1, 0.3, 0.3)
                end
            else
                spellNameDisplay:SetText("")
            end
        end)
        
        listYOffset = listYOffset + 30
        
        -- Add to whitelist button
        local whitelistButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        whitelistButton:SetSize(120, 22)
        whitelistButton:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -listYOffset)
        whitelistButton:SetText("Add to Whitelist")
        whitelistButton:SetScript("OnClick", function()
            local spellId = tonumber(spellIdEditBox:GetText())
            if not spellId then return end
            
            local spellName = GetSpellInfo(spellId)
            if not spellName then
                print("|cFFFF0000[Advanced Ability Control]|r Unknown spell ID")
                return
            end
            
            -- Add to the appropriate whitelist
            if abilityType == "Interrupts" then
                AAC.inclusionLists.interrupts[spellId] = true
                AAC.settings.spellLists.interrupts.alwaysInclude[tostring(spellId)] = true
            elseif abilityType == "Dispels" then
                AAC.inclusionLists.dispels[spellId] = true
                AAC.settings.spellLists.dispels.alwaysInclude[tostring(spellId)] = true
            elseif abilityType == "CC" then
                AAC.inclusionLists.crowdControl[spellId] = true
                AAC.settings.spellLists.crowdControl.alwaysInclude[tostring(spellId)] = true
            end
            
            -- Save settings
            AAC:SaveSettings()
            
            -- Clear input
            spellIdEditBox:SetText("")
            spellNameDisplay:SetText("")
            
            -- Update the list
            self:UpdateSpellList(frame, abilityType)
            
            -- Notify
            print(string.format("|cFF00FFFF[Advanced Ability Control]|r Added %s (ID: %d) to %s whitelist", spellName, spellId, abilityType))
        end)
        
        -- Add to blacklist button
        local blacklistButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        blacklistButton:SetSize(120, 22)
        blacklistButton:SetPoint("LEFT", whitelistButton, "RIGHT", 10, 0)
        blacklistButton:SetText("Add to Blacklist")
        blacklistButton:SetScript("OnClick", function()
            local spellId = tonumber(spellIdEditBox:GetText())
            if not spellId then return end
            
            local spellName = GetSpellInfo(spellId)
            if not spellName then
                print("|cFFFF0000[Advanced Ability Control]|r Unknown spell ID")
                return
            end
            
            -- Add to the appropriate blacklist
            if abilityType == "Interrupts" then
                AAC.exclusionLists.interrupts[spellId] = true
                AAC.settings.spellLists.interrupts.alwaysExclude[tostring(spellId)] = true
            elseif abilityType == "Dispels" then
                AAC.exclusionLists.dispels[spellId] = true
                AAC.settings.spellLists.dispels.alwaysExclude[tostring(spellId)] = true
            elseif abilityType == "CC" then
                AAC.exclusionLists.crowdControl[spellId] = true
                AAC.settings.spellLists.crowdControl.alwaysExclude[tostring(spellId)] = true
            end
            
            -- Save settings
            AAC:SaveSettings()
            
            -- Clear input
            spellIdEditBox:SetText("")
            spellNameDisplay:SetText("")
            
            -- Update the list
            self:UpdateSpellList(frame, abilityType)
            
            -- Notify
            print(string.format("|cFF00FFFF[Advanced Ability Control]|r Added %s (ID: %d) to %s blacklist", spellName, spellId, abilityType))
        end)
        
        listYOffset = listYOffset + 40
        
        -- Whitelist section
        local whitelistTitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        whitelistTitle:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -listYOffset)
        whitelistTitle:SetText("Whitelist (Always Use)")
        listYOffset = listYOffset + 25
        
        -- Create whitelist scroll frame
        local whitelistScroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
        whitelistScroll:SetSize(250, 150)
        whitelistScroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -listYOffset)
        
        local whitelistScrollChild = CreateFrame("Frame")
        whitelistScroll:SetScrollChild(whitelistScrollChild)
        whitelistScrollChild:SetSize(230, 600) -- Height will adjust as needed
        
        -- Blacklist section
        local blacklistTitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        blacklistTitle:SetPoint("TOPLEFT", frame, "TOPLEFT", 300, -listYOffset + 25)
        blacklistTitle:SetText("Blacklist (Never Use)")
        
        -- Create blacklist scroll frame
        local blacklistScroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
        blacklistScroll:SetSize(250, 150)
        blacklistScroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 300, -listYOffset)
        
        local blacklistScrollChild = CreateFrame("Frame")
        blacklistScroll:SetScrollChild(blacklistScrollChild)
        blacklistScrollChild:SetSize(230, 600) -- Height will adjust as needed
        
        -- Store references
        frame.spellIdEditBox = spellIdEditBox
        frame.spellNameDisplay = spellNameDisplay
        frame.whitelistScrollChild = whitelistScrollChild
        frame.blacklistScrollChild = blacklistScrollChild
        frame.abilityType = abilityType
        
        -- Initialize the lists
        self:UpdateSpellList(frame, abilityType)
    end
    
    -- Create content for each tab
    CreateSpellListContent(listContentFrames["Interrupts"], "Interrupts")
    CreateSpellListContent(listContentFrames["Dispels"], "Dispels")
    CreateSpellListContent(listContentFrames["CC"], "CC")
    
    -- Select first tab by default
    listTabs["Interrupts"]:Click()
    
    -- Function to refresh spell lists when shown
    tabFrames.container:SetScript("OnShow", function()
        -- Check if any lists are visible and update them
        for name, frame in pairs(listContentFrames) do
            if frame:IsVisible() then
                self:UpdateSpellList(frame, frame.abilityType)
                break
            end
        end
    end)
end

-- Create advanced tab
function AdvancedAbilityControlUI:CreateAdvancedTab(tabFrames)
    local container = tabFrames.scrollChild
    local yOffset = -20
    
    -- Title
    local title = container:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", container, "TOPLEFT", 20, yOffset)
    title:SetText("Advanced Settings")
    yOffset = yOffset - 30
    
    -- Section: Tracking
    local trackingTitle = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    trackingTitle:SetPoint("TOPLEFT", container, "TOPLEFT", 20, yOffset)
    trackingTitle:SetText("Performance Tracking:")
    yOffset = yOffset - 25
    
    -- Enable tracking checkbox
    local trackingCheckbox = self:CreateCheckBox(container, "Enable Tracking", 
                                                "Track success rates and timing statistics", 40, yOffset)
    trackingCheckbox:SetChecked(AAC.settings.tracking.enabled)
    trackingCheckbox:SetScript("OnClick", function(self)
        AAC.settings.tracking.enabled = self:GetChecked()
        AAC:SaveSettings()
    end)
    yOffset = yOffset - 25
    
    -- Track success rate checkbox
    local successRateCheckbox = self:CreateCheckBox(container, "Track Success Rate", 
                                                  "Record success/failure statistics for each ability", 40, yOffset)
    successRateCheckbox:SetChecked(AAC.settings.tracking.trackSuccessRate)
    successRateCheckbox:SetScript("OnClick", function(self)
        AAC.settings.tracking.trackSuccessRate = self:GetChecked()
        AAC:SaveSettings()
    end)
    yOffset = yOffset - 25
    
    -- Track timing distribution checkbox
    local timingDistCheckbox = self:CreateCheckBox(container, "Track Timing Distribution", 
                                                 "Record timing statistics for ability usage", 40, yOffset)
    timingDistCheckbox:SetChecked(AAC.settings.tracking.trackTimingDistribution)
    timingDistCheckbox:SetScript("OnClick", function(self)
        AAC.settings.tracking.trackTimingDistribution = self:GetChecked()
        AAC:SaveSettings()
    end)
    yOffset = yOffset - 25
    
    -- Auto adjust priorities checkbox
    local autoAdjustCheckbox = self:CreateCheckBox(container, "Auto-Adjust Priorities", 
                                                 "Automatically adjust spell priorities based on success rate", 40, yOffset)
    autoAdjustCheckbox:SetChecked(AAC.settings.tracking.autoAdjustPriorities)
    autoAdjustCheckbox:SetScript("OnClick", function(self)
        AAC.settings.tracking.autoAdjustPriorities = self:GetChecked()
        AAC:SaveSettings()
    end)
    yOffset = yOffset - 40
    
    -- History entries slider
    local historyLabel = container:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    historyLabel:SetPoint("TOPLEFT", container, "TOPLEFT", 40, yOffset)
    historyLabel:SetText("Maximum History Entries:")
    
    local historySlider = CreateFrame("Slider", "WRHistoryEntriesSlider", container, "OptionsSliderTemplate")
    historySlider:SetPoint("TOPLEFT", historyLabel, "BOTTOMLEFT", 0, -10)
    historySlider:SetWidth(300)
    historySlider:SetMinMaxValues(10, 500)
    historySlider:SetValueStep(10)
    historySlider:SetObeyStepOnDrag(true)
    historySlider:SetValue(AAC.settings.tracking.maxHistoryEntries)
    
    historySlider.Low:SetText("10")
    historySlider.High:SetText("500")
    historySlider.Text:SetText(AAC.settings.tracking.maxHistoryEntries)
    
    historySlider:SetScript("OnValueChanged", function(self, value)
        value = floor(value / 10) * 10 -- Round to nearest 10
        self.Text:SetText(value)
        AAC.settings.tracking.maxHistoryEntries = value
        AAC:SaveSettings()
    end)
    
    yOffset = yOffset - 70
    
    -- Section: Advanced Controls
    local advTitle = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    advTitle:SetPoint("TOPLEFT", container, "TOPLEFT", 20, yOffset)
    advTitle:SetText("Advanced Controls:")
    yOffset = yOffset - 25
    
    -- Reset statistics button
    local resetStatsButton = CreateFrame("Button", nil, container, "UIPanelButtonTemplate")
    resetStatsButton:SetSize(180, 22)
    resetStatsButton:SetPoint("TOPLEFT", container, "TOPLEFT", 40, yOffset)
    resetStatsButton:SetText("Reset Usage Statistics")
    resetStatsButton:SetScript("OnClick", function()
        -- Ask for confirmation
        StaticPopupDialogs["WINDRUNNER_RESET_AAC_STATS"] = {
            text = "Are you sure you want to reset all usage statistics? This cannot be undone.",
            button1 = "Yes",
            button2 = "No",
            OnAccept = function()
                -- Reset statistics in all registries
                for _, interrupt in ipairs(AAC.abilityRegistry.interrupts) do
                    interrupt.successRate = 100
                    interrupt.totalUses = 0
                    interrupt.successfulUses = 0
                end
                
                for _, dispel in ipairs(AAC.abilityRegistry.dispels) do
                    dispel.successRate = 100
                    dispel.totalUses = 0
                    dispel.successfulUses = 0
                end
                
                for _, cc in ipairs(AAC.abilityRegistry.crowdControl) do
                    cc.successRate = 100
                    cc.totalUses = 0
                    cc.successfulUses = 0
                end
                
                print("|cFF00FFFF[Advanced Ability Control]|r Usage statistics reset")
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true
        }
        StaticPopup_Show("WINDRUNNER_RESET_AAC_STATS")
    end)
    yOffset = yOffset - 30
    
    -- Clear exclusion lists button
    local clearListsButton = CreateFrame("Button", nil, container, "UIPanelButtonTemplate")
    clearListsButton:SetSize(180, 22)
    clearListsButton:SetPoint("TOPLEFT", container, "TOPLEFT", 40, yOffset)
    clearListsButton:SetText("Clear All Spell Lists")
    clearListsButton:SetScript("OnClick", function()
        -- Ask for confirmation
        StaticPopupDialogs["WINDRUNNER_CLEAR_AAC_LISTS"] = {
            text = "Are you sure you want to clear all spell inclusion and exclusion lists? This cannot be undone.",
            button1 = "Yes",
            button2 = "No",
            OnAccept = function()
                -- Clear all spell lists
                AAC.exclusionLists = {
                    interrupts = {},
                    dispels = {},
                    crowdControl = {}
                }
                
                AAC.inclusionLists = {
                    interrupts = {},
                    dispels = {},
                    crowdControl = {}
                }
                
                -- Clear settings
                AAC.settings.spellLists.interrupts.alwaysExclude = {}
                AAC.settings.spellLists.dispels.alwaysExclude = {}
                AAC.settings.spellLists.crowdControl.alwaysExclude = {}
                
                AAC.settings.spellLists.interrupts.alwaysInclude = {}
                AAC.settings.spellLists.dispels.alwaysInclude = {}
                AAC.settings.spellLists.crowdControl.alwaysInclude = {}
                
                -- Save settings
                AAC:SaveSettings()
                
                -- Update UI
                self:UpdateAllTabs()
                
                print("|cFF00FFFF[Advanced Ability Control]|r All spell lists cleared")
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true
        }
        StaticPopup_Show("WINDRUNNER_CLEAR_AAC_LISTS")
    end)
    yOffset = yOffset - 30
    
    -- Export settings button
    local exportButton = CreateFrame("Button", nil, container, "UIPanelButtonTemplate")
    exportButton:SetSize(180, 22)
    exportButton:SetPoint("TOPLEFT", container, "TOPLEFT", 40, yOffset)
    exportButton:SetText("Export Settings")
    exportButton:SetScript("OnClick", function()
        -- Create export string
        local exportData = {
            version = 1,
            interrupts = AAC.settings.global.interrupts,
            dispels = AAC.settings.global.dispels,
            crowdControl = AAC.settings.global.crowdControl,
            spellLists = AAC.settings.spellLists
        }
        
        -- Convert to JSON-like string (simplified for demonstration)
        local exportString = "WR_AAC_EXPORT:" .. self:SerializeTable(exportData)
        
        -- Show export dialog
        StaticPopupDialogs["WINDRUNNER_EXPORT_AAC"] = {
            text = "Copy the text below to share your settings:",
            button1 = "Done",
            hasEditBox = true,
            editBoxWidth = 350,
            maxLetters = 10000,
            OnShow = function(dialog)
                dialog.editBox:SetText(exportString)
                dialog.editBox:HighlightText()
                dialog.editBox:SetFocus()
            end,
            EditBoxOnEscapePressed = function(editBox)
                editBox:GetParent():Hide()
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true
        }
        StaticPopup_Show("WINDRUNNER_EXPORT_AAC")
    end)
    yOffset = yOffset - 30
    
    -- Import settings button
    local importButton = CreateFrame("Button", nil, container, "UIPanelButtonTemplate")
    importButton:SetSize(180, 22)
    importButton:SetPoint("TOPLEFT", container, "TOPLEFT", 40, yOffset)
    importButton:SetText("Import Settings")
    importButton:SetScript("OnClick", function()
        -- Show import dialog
        StaticPopupDialogs["WINDRUNNER_IMPORT_AAC"] = {
            text = "Paste the exported settings text below:",
            button1 = "Import",
            button2 = "Cancel",
            hasEditBox = true,
            editBoxWidth = 350,
            maxLetters = 10000,
            OnAccept = function(dialog)
                local importString = dialog.editBox:GetText()
                if importString:sub(1, 14) ~= "WR_AAC_EXPORT:" then
                    print("|cFFFF0000[Advanced Ability Control]|r Invalid import string")
                    return
                end
                
                -- Remove prefix
                importString = importString:sub(15)
                
                -- Deserialize
                local success, importData = self:DeserializeTable(importString)
                if not success then
                    print("|cFFFF0000[Advanced Ability Control]|r Invalid import data")
                    return
                end
                
                -- Validate version
                if not importData.version or importData.version ~= 1 then
                    print("|cFFFF0000[Advanced Ability Control]|r Unsupported import version")
                    return
                end
                
                -- Apply settings
                AAC.settings.global.interrupts = importData.interrupts
                AAC.settings.global.dispels = importData.dispels
                AAC.settings.global.crowdControl = importData.crowdControl
                AAC.settings.spellLists = importData.spellLists
                
                -- Update exclusion and inclusion lists
                AAC.exclusionLists = {
                    interrupts = {},
                    dispels = {},
                    crowdControl = {}
                }
                
                AAC.inclusionLists = {
                    interrupts = {},
                    dispels = {},
                    crowdControl = {}
                }
                
                for spellID, _ in pairs(importData.spellLists.interrupts.alwaysExclude) do
                    AAC.exclusionLists.interrupts[tonumber(spellID)] = true
                end
                
                for spellID, _ in pairs(importData.spellLists.dispels.alwaysExclude) do
                    AAC.exclusionLists.dispels[tonumber(spellID)] = true
                end
                
                for spellID, _ in pairs(importData.spellLists.crowdControl.alwaysExclude) do
                    AAC.exclusionLists.crowdControl[tonumber(spellID)] = true
                end
                
                for spellID, _ in pairs(importData.spellLists.interrupts.alwaysInclude) do
                    AAC.inclusionLists.interrupts[tonumber(spellID)] = true
                end
                
                for spellID, _ in pairs(importData.spellLists.dispels.alwaysInclude) do
                    AAC.inclusionLists.dispels[tonumber(spellID)] = true
                end
                
                for spellID, _ in pairs(importData.spellLists.crowdControl.alwaysInclude) do
                    AAC.inclusionLists.crowdControl[tonumber(spellID)] = true
                end
                
                -- Save settings
                AAC:SaveSettings()
                
                -- Update UI
                self:UpdateAllTabs()
                
                print("|cFF00FFFF[Advanced Ability Control]|r Settings imported successfully")
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true
        }
        StaticPopup_Show("WINDRUNNER_IMPORT_AAC")
    end)
    
    yOffset = yOffset - 50
    
    -- Advanced help text
    local helpText = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    helpText:SetPoint("TOPLEFT", container, "TOPLEFT", 20, yOffset)
    helpText:SetWidth(container:GetWidth() - 40)
    helpText:SetJustifyH("LEFT")
    helpText:SetText("Advanced Tips:\n\n" ..
                    "1. You can use slash commands to quickly configure advanced ability control:\n" ..
                    "   /abilitycontrol interrupt delay 0.2 0.7\n" ..
                    "   /abilitycontrol exclude interrupt 12345\n" ..
                    "   /abilitycontrol cc type stun enable\n\n" ..
                    "2. Reset statistics after making major changes to see accurate success rates.\n\n" ..
                    "3. Exported settings can be shared with other players using Windrunner Rotations.")
end

-- Update spell list
function AdvancedAbilityControlUI:UpdateSpellList(frame, abilityType)
    -- Clear existing entries
    local whitelistChild = frame.whitelistScrollChild
    local blacklistChild = frame.blacklistScrollChild
    
    for i = whitelistChild:GetNumChildren(), 1, -1 do
        local child = select(i, whitelistChild:GetChildren())
        child:Hide()
        child:SetParent(nil)
        child:ClearAllPoints()
    end
    
    for i = blacklistChild:GetNumChildren(), 1, -1 do
        local child = select(i, blacklistChild:GetChildren())
        child:Hide()
        child:SetParent(nil)
        child:ClearAllPoints()
    end
    
    -- Get spell lists
    local whitelistSpells = {}
    local blacklistSpells = {}
    
    if abilityType == "Interrupts" then
        for spellId in pairs(AAC.settings.spellLists.interrupts.alwaysInclude) do
            tinsert(whitelistSpells, tonumber(spellId))
        end
        
        for spellId in pairs(AAC.settings.spellLists.interrupts.alwaysExclude) do
            tinsert(blacklistSpells, tonumber(spellId))
        end
    elseif abilityType == "Dispels" then
        for spellId in pairs(AAC.settings.spellLists.dispels.alwaysInclude) do
            tinsert(whitelistSpells, tonumber(spellId))
        end
        
        for spellId in pairs(AAC.settings.spellLists.dispels.alwaysExclude) do
            tinsert(blacklistSpells, tonumber(spellId))
        end
    elseif abilityType == "CC" then
        for spellId in pairs(AAC.settings.spellLists.crowdControl.alwaysInclude) do
            tinsert(whitelistSpells, tonumber(spellId))
        end
        
        for spellId in pairs(AAC.settings.spellLists.crowdControl.alwaysExclude) do
            tinsert(blacklistSpells, tonumber(spellId))
        end
    end
    
    -- Sort by spell ID
    sort(whitelistSpells)
    sort(blacklistSpells)
    
    -- Create whitelist entries
    local whitelistYOffset = 5
    for i, spellId in ipairs(whitelistSpells) do
        local name = GetSpellInfo(spellId) or "Unknown Spell"
        
        local entry = CreateFrame("Frame", nil, whitelistChild)
        entry:SetSize(230, 25)
        entry:SetPoint("TOPLEFT", whitelistChild, "TOPLEFT", 5, -whitelistYOffset)
        
        -- Spell name
        local spellName = entry:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        spellName:SetPoint("LEFT", entry, "LEFT", 0, 0)
        spellName:SetText(name .. " (" .. spellId .. ")")
        
        -- Remove button
        local removeButton = CreateFrame("Button", nil, entry)
        removeButton:SetSize(16, 16)
        removeButton:SetPoint("RIGHT", entry, "RIGHT", -5, 0)
        removeButton:SetNormalTexture("Interface\\Buttons\\UI-StopButton")
        removeButton:SetHighlightTexture("Interface\\Buttons\\UI-StopButton", "ADD")
        
        removeButton:SetScript("OnClick", function()
            -- Remove from the appropriate whitelist
            if abilityType == "Interrupts" then
                AAC.inclusionLists.interrupts[spellId] = nil
                AAC.settings.spellLists.interrupts.alwaysInclude[tostring(spellId)] = nil
            elseif abilityType == "Dispels" then
                AAC.inclusionLists.dispels[spellId] = nil
                AAC.settings.spellLists.dispels.alwaysInclude[tostring(spellId)] = nil
            elseif abilityType == "CC" then
                AAC.inclusionLists.crowdControl[spellId] = nil
                AAC.settings.spellLists.crowdControl.alwaysInclude[tostring(spellId)] = nil
            end
            
            -- Save settings
            AAC:SaveSettings()
            
            -- Update the list
            self:UpdateSpellList(frame, abilityType)
            
            -- Notify
            print(string.format("|cFF00FFFF[Advanced Ability Control]|r Removed %s (ID: %d) from %s whitelist", name, spellId, abilityType))
        end)
        
        whitelistYOffset = whitelistYOffset + 25
    end
    
    -- Create blacklist entries
    local blacklistYOffset = 5
    for i, spellId in ipairs(blacklistSpells) do
        local name = GetSpellInfo(spellId) or "Unknown Spell"
        
        local entry = CreateFrame("Frame", nil, blacklistChild)
        entry:SetSize(230, 25)
        entry:SetPoint("TOPLEFT", blacklistChild, "TOPLEFT", 5, -blacklistYOffset)
        
        -- Spell name
        local spellName = entry:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        spellName:SetPoint("LEFT", entry, "LEFT", 0, 0)
        spellName:SetText(name .. " (" .. spellId .. ")")
        
        -- Remove button
        local removeButton = CreateFrame("Button", nil, entry)
        removeButton:SetSize(16, 16)
        removeButton:SetPoint("RIGHT", entry, "RIGHT", -5, 0)
        removeButton:SetNormalTexture("Interface\\Buttons\\UI-StopButton")
        removeButton:SetHighlightTexture("Interface\\Buttons\\UI-StopButton", "ADD")
        
        removeButton:SetScript("OnClick", function()
            -- Remove from the appropriate blacklist
            if abilityType == "Interrupts" then
                AAC.exclusionLists.interrupts[spellId] = nil
                AAC.settings.spellLists.interrupts.alwaysExclude[tostring(spellId)] = nil
            elseif abilityType == "Dispels" then
                AAC.exclusionLists.dispels[spellId] = nil
                AAC.settings.spellLists.dispels.alwaysExclude[tostring(spellId)] = nil
            elseif abilityType == "CC" then
                AAC.exclusionLists.crowdControl[spellId] = nil
                AAC.settings.spellLists.crowdControl.alwaysExclude[tostring(spellId)] = nil
            end
            
            -- Save settings
            AAC:SaveSettings()
            
            -- Update the list
            self:UpdateSpellList(frame, abilityType)
            
            -- Notify
            print(string.format("|cFF00FFFF[Advanced Ability Control]|r Removed %s (ID: %d) from %s blacklist", name, spellId, abilityType))
        end)
        
        blacklistYOffset = blacklistYOffset + 25
    end
    
    -- Update scroll child height
    whitelistChild:SetHeight(max(300, whitelistYOffset + 10))
    blacklistChild:SetHeight(max(300, blacklistYOffset + 10))
    
    -- Create placeholders if lists are empty
    if #whitelistSpells == 0 then
        local placeholder = whitelistChild:CreateFontString(nil, "OVERLAY", "GameFontDisable")
        placeholder:SetPoint("CENTER", whitelistChild, "CENTER", 0, 0)
        placeholder:SetText("No spells in whitelist")
    end
    
    if #blacklistSpells == 0 then
        local placeholder = blacklistChild:CreateFontString(nil, "OVERLAY", "GameFontDisable")
        placeholder:SetPoint("CENTER", blacklistChild, "CENTER", 0, 0)
        placeholder:SetText("No spells in blacklist")
    end
end

-- Update all tabs
function AdvancedAbilityControlUI:UpdateAllTabs()
    -- Update based on current tab
    if self.currentTab == "General" then
        self:CreateGeneralTab(self.tabFrames["General"])
    elseif self.currentTab == "Interrupts" then
        self:CreateInterruptsTab(self.tabFrames["Interrupts"])
    elseif self.currentTab == "Dispels" then
        self:CreateDispelsTab(self.tabFrames["Dispels"])
    elseif self.currentTab == "CrowdControl" then
        self:CreateCrowdControlTab(self.tabFrames["CrowdControl"])
    elseif self.currentTab == "SpellLists" then
        -- Update any visible spell lists
        for _, frame in pairs(self.tabFrames["SpellLists"].container:GetChildren()) do
            if frame:IsVisible() and frame.abilityType then
                self:UpdateSpellList(frame, frame.abilityType)
            end
        end
    elseif self.currentTab == "Advanced" then
        self:CreateAdvancedTab(self.tabFrames["Advanced"])
    end
end

-- Create checkbox helper
function AdvancedAbilityControlUI:CreateCheckBox(parent, label, tooltip, x, y)
    local checkbox = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    checkbox:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    
    checkbox.Text:SetText(label)
    checkbox.tooltipText = tooltip
    
    return checkbox
end

-- Serialize table to string (simplified version)
function AdvancedAbilityControlUI:SerializeTable(tbl)
    if type(tbl) ~= "table" then
        if type(tbl) == "string" then
            return string.format("%q", tbl)
        else
            return tostring(tbl)
        end
    end
    
    local str = "{"
    for k, v in pairs(tbl) do
        local keyStr
        if type(k) == "number" then
            keyStr = "[" .. k .. "]"
        else
            keyStr = "[" .. string.format("%q", k) .. "]"
        end
        
        str = str .. keyStr .. "=" .. self:SerializeTable(v) .. ","
    end
    str = str .. "}"
    
    return str
end

-- Deserialize string to table (simplified version)
function AdvancedAbilityControlUI:DeserializeTable(str)
    local func, err = loadstring("return " .. str)
    if not func then
        return false, err
    end
    
    -- Set safe environment
    setfenv(func, {})
    
    local success, result = pcall(func)
    if not success then
        return false, result
    end
    
    return true, result
end

-- Initialize the UI
AdvancedAbilityControlUI:Initialize()

return AdvancedAbilityControlUI