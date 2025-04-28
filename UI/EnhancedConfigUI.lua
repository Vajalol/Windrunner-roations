------------------------------------------
-- WindrunnerRotations - Enhanced Configuration UI
-- Author: VortexQ8
-- The War Within Season 2
------------------------------------------

local addonName, WR = ...
local EnhancedConfigUI = {}
WR.UI = WR.UI or {}
WR.UI.EnhancedConfig = EnhancedConfigUI

-- Dependencies
local API = WR.API
local ConfigRegistry = WR.ConfigRegistry

-- Constants
local MEDIA_PATH = "Interface\\AddOns\\WindrunnerRotations\\Media\\"
local UI_WIDTH = 900
local UI_HEIGHT = 660
local PANEL_SPACING = 16
local SECTION_PADDING = 10
local ITEM_HEIGHT = 30
local ITEM_SPACING = 5
local CATEGORY_WIDTH = 200
local HEADER_HEIGHT = 44
local FOOTER_HEIGHT = 44
local SCROLLBAR_WIDTH = 16
local LOGO_SIZE = 64

-- UI references
local mainFrame, categoryFrame, configFrame, tabFrame, statusFrame
local categoryScrollFrame, configScrollFrame 
local categoryButtons = {}
local configWidgets = {}
local tabButtons = {}
local currentTab = "General"
local currentModule = nil
local currentCategory = nil
local initialized = false

-- Colors and textures
local THEME = {
    background = {r = 0.08, g = 0.08, b = 0.08, a = 0.95},
    border = {r = 0.4, g = 0.4, b = 0.4, a = 0.9},
    header = {r = 0.12, g = 0.12, b = 0.12, a = 0.95},
    highlight = {r = 0.3, g = 0.5, b = 0.8, a = 1.0},
    button = {
        normal = {r = 0.18, g = 0.18, b = 0.18, a = 0.95},
        hover = {r = 0.22, g = 0.22, b = 0.22, a = 0.95},
        pushed = {r = 0.15, g = 0.15, b = 0.15, a = 0.95},
        disabled = {r = 0.1, g = 0.1, b = 0.1, a = 0.95}
    },
    text = {
        normal = {r = 1.0, g = 1.0, b = 1.0, a = 1.0},
        header = {r = 1.0, g = 0.9, b = 0.8, a = 1.0},
        disabled = {r = 0.5, g = 0.5, b = 0.5, a = 1.0},
        highlight = {r = 0.9, g = 0.8, b = 0.0, a = 1.0}
    },
    category = {
        normal = {r = 0.18, g = 0.18, b = 0.18, a = 0.9},
        selected = {r = 0.25, g = 0.35, b = 0.5, a = 0.95},
        hover = {r = 0.22, g = 0.22, b = 0.26, a = 0.95}
    },
    slider = {
        bg = {r = 0.15, g = 0.15, b = 0.15, a = 0.95},
        fill = {r = 0.3, g = 0.5, b = 0.8, a = 0.95}
    },
    checkbox = {
        bg = {r = 0.1, g = 0.1, b = 0.1, a = 0.9},
        checked = {r = 0.3, g = 0.5, b = 0.8, a = 1.0}
    },
    status = {
        active = {r = 0.0, g = 0.8, b = 0.0, a = 1.0},
        inactive = {r = 0.8, g = 0.0, b = 0.0, a = 1.0},
        warning = {r = 0.8, g = 0.8, b = 0.0, a = 1.0}
    }
}

local textures = {
    background = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
    border = "Interface\\DialogFrame\\UI-DialogBox-Border",
    checkmark = "Interface\\Buttons\\UI-CheckBox-Check",
    checkbox = "Interface\\Buttons\\UI-CheckBox-Up",
    checkboxChecked = "Interface\\Buttons\\UI-CheckBox-Down",
    dropdown = "Interface\\Buttons\\UI-ScrollBar-Button-Down",
    slider = "Interface\\Buttons\\UI-SliderBar-Button-Horizontal",
    sliderBG = "Interface\\Buttons\\UI-SliderBar-Background",
    buttonUp = "Interface\\Buttons\\UI-Panel-Button-Up",
    buttonDown = "Interface\\Buttons\\UI-Panel-Button-Down",
    buttonHighlight = "Interface\\Buttons\\UI-Panel-Button-Highlight",
    closeButton = "Interface\\Buttons\\UI-Panel-MinimizeButton",
    logo = MEDIA_PATH.."WindrunnerLogo.blp" -- Will need to create this logo
}

-- Class colors for styling
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

-- Tab definitions
local TABS = {
    {name = "General", displayName = "General", icon = "Interface\\Icons\\INV_Misc_Gear_01"},
    {name = "Combat", displayName = "Combat", icon = "Interface\\Icons\\Ability_Warrior_BattleShout"},
    {name = "Class", displayName = "Class", icon = "Interface\\Icons\\ClassIcon_Warrior"},
    {name = "Defensives", displayName = "Defensives", icon = "Interface\\Icons\\Ability_Warrior_DefensiveStance"},
    {name = "Interrupts", displayName = "Interrupts", icon = "Interface\\Icons\\Ability_Kick"},
    {name = "Targeting", displayName = "Targeting", icon = "Interface\\Icons\\Ability_Hunter_MasterMarksman"},
    {name = "Healing", displayName = "Healing", icon = "Interface\\Icons\\Spell_Holy_HolyBolt"},
    {name = "Consumables", displayName = "Consumables", icon = "Interface\\Icons\\INV_Potion_92"},
    {name = "Movement", displayName = "Movement", icon = "Interface\\Icons\\Ability_Druid_LunarGuidance"},
    {name = "Debug", displayName = "Debug", icon = "Interface\\Icons\\Spell_Arcane_Arcane03"},
    {name = "Advanced", displayName = "Advanced", icon = "Interface\\Icons\\Ability_Warrior_Challange"}
}

-- Module category order
local MODULE_ORDER = {
    "General",
    "Combat",
    "DeathKnight",
    "DemonHunter",
    "Druid",
    "Evoker",
    "Hunter",
    "Mage",
    "Monk",
    "Paladin",
    "Priest",
    "Rogue",
    "Shaman",
    "Warlock",
    "Warrior",
    "Defensives",
    "Interrupts",
    "Targeting",
    "Healing",
    "Consumables",
    "Movement",
    "UI",
    "Performance",
    "Debug",
    "Advanced"
}

-- Tab config filter - determine which module settings appear in which tab
local TAB_FILTERS = {
    General = {
        modules = {"General"},
        categories = {"generalSettings", "addonSettings"}
    },
    Combat = {
        modules = {"Combat"},
        categories = {"combatSettings", "rotationSettings", "aoeSettings"}
    },
    Class = {
        modules = {"DeathKnight", "DemonHunter", "Druid", "Evoker", "Hunter", "Mage", "Monk", "Paladin", "Priest", "Rogue", "Shaman", "Warlock", "Warrior"},
        categories = {"classSettings", "specSettings", "talentSettings"}
    },
    Defensives = {
        modules = {"Defensives"},
        categories = {"defensiveSettings", "selfHealSettings", "cooldownSettings"}
    },
    Interrupts = {
        modules = {"Interrupts"},
        categories = {"interruptSettings", "ccSettings"}
    },
    Targeting = {
        modules = {"Targeting"},
        categories = {"targetingSettings", "enemySettings", "prioritySettings"}
    },
    Healing = {
        modules = {"Healing"},
        categories = {"healingSettings", "dispelSettings", "partyHealingSettings"}
    },
    Consumables = {
        modules = {"Consumables"},
        categories = {"consumableSettings", "potionSettings", "itemSettings"}
    },
    Movement = {
        modules = {"Movement"},
        categories = {"movementSettings", "positioningSettings", "avoidanceSettings"}
    },
    Debug = {
        modules = {"Debug"},
        categories = {"debugSettings", "loggingSettings", "testingSettings"}
    },
    Advanced = {
        modules = {"Advanced", "Performance"},
        categories = {"advancedSettings", "experimentalSettings", "performanceSettings"}
    }
}

-- Initialize the config UI
function EnhancedConfigUI:Initialize()
    if initialized then
        return
    end
    
    -- Create main frame
    self:CreateMainFrame()
    
    -- Create tab frame (across top)
    self:CreateTabFrame()
    
    -- Create category frame (left side)
    self:CreateCategoryFrame()
    
    -- Create config frame (right side)
    self:CreateConfigFrame()
    
    -- Register slash commands
    self:RegisterSlashCommands()
    
    -- Hide initially
    mainFrame:Hide()
    
    -- Mark as initialized
    initialized = true
    
    API.PrintDebug("Enhanced Config UI initialized")
    return true
end

-- Create the main frame
function EnhancedConfigUI:CreateMainFrame()
    -- Create main frame
    mainFrame = CreateFrame("Frame", "WindrunnerRotationsConfigUI", UIParent, "BackdropTemplate")
    mainFrame:SetSize(UI_WIDTH, UI_HEIGHT)
    mainFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    mainFrame:SetClampedToScreen(true)
    mainFrame:SetMovable(true)
    mainFrame:SetResizable(false)
    mainFrame:EnableMouse(true)
    mainFrame:SetFrameStrata("DIALOG")
    mainFrame:SetFrameLevel(100)
    
    -- Set backdrop
    mainFrame:SetBackdrop({
        bgFile = textures.background,
        edgeFile = textures.border,
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = {left = 11, right = 12, top = 12, bottom = 11}
    })
    mainFrame:SetBackdropColor(THEME.background.r, THEME.background.g, THEME.background.b, THEME.background.a)
    mainFrame:SetBackdropBorderColor(THEME.border.r, THEME.border.g, THEME.border.b, THEME.border.a)
    
    -- Make draggable
    mainFrame:RegisterForDrag("LeftButton")
    mainFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    mainFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    
    -- Add logo
    local logo = mainFrame:CreateTexture(nil, "ARTWORK")
    logo:SetSize(LOGO_SIZE, LOGO_SIZE)
    logo:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 24, -16)
    
    -- Use class icon if logo doesn't exist yet
    local _, class = UnitClass("player")
    local classIcon = "Interface\\Icons\\ClassIcon_" .. (class or "Warrior")
    
    -- Try to use our logo if it exists, otherwise use class icon
    logo:SetTexture(textures.logo)
    logo:SetTexCoord(0, 1, 0, 1)
    
    -- Add title text
    local titleText = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleText:SetPoint("TOP", mainFrame, "TOP", 0, -24)
    titleText:SetPoint("LEFT", logo, "RIGHT", 20, 0)
    titleText:SetText("Windrunner Rotations")
    titleText:SetTextColor(THEME.text.header.r, THEME.text.header.g, THEME.text.header.b, THEME.text.header.a)
    
    -- Add version text
    local version = GetAddOnMetadata("WindrunnerRotations", "Version") or "1.3.0"
    local versionText = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    versionText:SetPoint("TOPLEFT", titleText, "BOTTOMLEFT", 0, -2)
    versionText:SetText("Version " .. version)
    versionText:SetTextColor(0.7, 0.7, 0.7, 1.0)
    
    -- Add close button
    local closeButton = CreateFrame("Button", nil, mainFrame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -10, -10)
    closeButton:SetScript("OnClick", function() 
        -- Save settings when closing
        ConfigRegistry:SaveSettings()
        mainFrame:Hide() 
    end)
    
    -- Add class color bar
    local classBar = mainFrame:CreateTexture(nil, "ARTWORK")
    classBar:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 12, -1)
    classBar:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -12, -1)
    classBar:SetHeight(4)
    
    -- Set class color
    if class and CLASS_COLORS[class] then
        local color = CLASS_COLORS[class]
        classBar:SetColorTexture(color.r, color.g, color.b, 0.9)
    else
        classBar:SetColorTexture(0.4, 0.5, 0.8, 0.9)
    end
    
    -- Create status frame at the bottom
    self:CreateStatusFrame()
    
    -- Store references
    self.mainFrame = mainFrame
    self.titleText = titleText
    self.versionText = versionText
    self.closeButton = closeButton
    self.classBar = classBar
    self.logo = logo
end

-- Create status frame (bottom of main frame)
function EnhancedConfigUI:CreateStatusFrame()
    -- Create the status panel
    statusFrame = CreateFrame("Frame", nil, mainFrame, "BackdropTemplate")
    statusFrame:SetSize(UI_WIDTH - 40, 36)
    statusFrame:SetPoint("BOTTOM", mainFrame, "BOTTOM", 0, 20)
    statusFrame:SetBackdrop({
        bgFile = textures.background,
        edgeFile = textures.border,
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    statusFrame:SetBackdropColor(THEME.header.r, THEME.header.g, THEME.header.b, THEME.header.a)
    
    -- Create status indicator
    local statusIndicator = statusFrame:CreateTexture(nil, "ARTWORK")
    statusIndicator:SetSize(16, 16)
    statusIndicator:SetPoint("LEFT", statusFrame, "LEFT", 12, 0)
    statusIndicator:SetTexture("Interface\\COMMON\\Indicator-Green")
    
    -- Create status text
    local statusText = statusFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    statusText:SetPoint("LEFT", statusIndicator, "RIGHT", 8, 0)
    statusText:SetText("Rotation Active")
    statusText:SetTextColor(THEME.status.active.r, THEME.status.active.g, THEME.status.active.b, THEME.status.active.a)
    
    -- Create toggle button
    local toggleButton = CreateFrame("Button", nil, statusFrame, "UIPanelButtonTemplate")
    toggleButton:SetSize(100, 24)
    toggleButton:SetPoint("RIGHT", statusFrame, "RIGHT", -12, 0)
    toggleButton:SetText("Enable")
    
    -- Style the button based on state
    local function UpdateToggleButton()
        local isRunning = WR.RotationManager and WR.RotationManager:IsRunning()
        if isRunning then
            toggleButton:SetText("Disable")
            statusIndicator:SetTexture("Interface\\COMMON\\Indicator-Green")
            statusText:SetText("Rotation Active")
            statusText:SetTextColor(THEME.status.active.r, THEME.status.active.g, THEME.status.active.b, THEME.status.active.a)
        else
            toggleButton:SetText("Enable")
            statusIndicator:SetTexture("Interface\\COMMON\\Indicator-Red")
            statusText:SetText("Rotation Inactive")
            statusText:SetTextColor(THEME.status.inactive.r, THEME.status.inactive.g, THEME.status.inactive.b, THEME.status.inactive.a)
        end
    end
    
    -- Set initial state
    UpdateToggleButton()
    
    -- Toggle button click handler
    toggleButton:SetScript("OnClick", function() 
        -- Toggle rotation status
        if WR.RotationManager then
            if WR.RotationManager:IsRunning() then
                WR.RotationManager:StopRotation()
            else
                WR.RotationManager:StartRotation()
            end
            
            -- Update button and status indicator appearance
            UpdateToggleButton()
        end
    end)
    
    -- Register events to update toggle button
    local toggleButtonEvents = CreateFrame("Frame")
    toggleButtonEvents:RegisterEvent("PLAYER_ENTERING_WORLD")
    toggleButtonEvents:RegisterEvent("ADDON_LOADED")
    toggleButtonEvents:SetScript("OnEvent", function(self, event, arg1)
        if event == "ADDON_LOADED" and arg1 == "WindrunnerRotations" then
            C_Timer.After(1, UpdateToggleButton)
        elseif event == "PLAYER_ENTERING_WORLD" then
            C_Timer.After(1, UpdateToggleButton)
        end
    end)
    
    -- Create mode dropdown
    local modeLabel = statusFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    modeLabel:SetPoint("RIGHT", toggleButton, "LEFT", -60, 0)
    modeLabel:SetText("Mode:")
    
    local modeDropdown = CreateFrame("Frame", "WindrunnerRotationsModeDropdown", statusFrame, "UIDropDownMenuTemplate")
    modeDropdown:SetPoint("RIGHT", toggleButton, "LEFT", -10, 0)
    UIDropDownMenu_SetWidth(modeDropdown, 80)
    
    -- Initialize the dropdown menu
    UIDropDownMenu_Initialize(modeDropdown, function(self, level)
        local info = UIDropDownMenu_CreateInfo()
        
        -- Auto mode
        info.text = "Auto"
        info.value = "auto"
        info.func = function()
            if WR.RotationManager then
                WR.RotationManager:SetMode("auto")
                UIDropDownMenu_SetText(modeDropdown, "Auto")
            end
        end
        info.checked = WR.RotationManager and WR.RotationManager:GetMode() == "auto"
        UIDropDownMenu_AddButton(info, level)
        
        -- Single mode
        info.text = "Single"
        info.value = "single"
        info.func = function()
            if WR.RotationManager then
                WR.RotationManager:SetMode("single")
                UIDropDownMenu_SetText(modeDropdown, "Single")
            end
        end
        info.checked = WR.RotationManager and WR.RotationManager:GetMode() == "single"
        UIDropDownMenu_AddButton(info, level)
        
        -- Manual mode
        info.text = "Manual"
        info.value = "manual"
        info.func = function()
            if WR.RotationManager then
                WR.RotationManager:SetMode("manual")
                UIDropDownMenu_SetText(modeDropdown, "Manual")
            end
        end
        info.checked = WR.RotationManager and WR.RotationManager:GetMode() == "manual"
        UIDropDownMenu_AddButton(info, level)
    end)
    
    -- Set the initial text
    if WR.RotationManager then
        UIDropDownMenu_SetText(modeDropdown, WR.RotationManager:GetMode():gsub("^%l", string.upper))
    else
        UIDropDownMenu_SetText(modeDropdown, "Auto")
    end
    
    -- Store references
    self.statusFrame = statusFrame
    self.statusIndicator = statusIndicator
    self.statusText = statusText
    self.toggleButton = toggleButton
    self.modeDropdown = modeDropdown
    
    -- Update status display
    C_Timer.After(0.1, function() self:UpdateStatusDisplay() end)
end

-- Update status display based on rotation manager state
function EnhancedConfigUI:UpdateStatusDisplay()
    if not self.statusIndicator or not self.statusText or not self.toggleButton then
        return
    end
    
    if WR.RotationManager and WR.RotationManager:IsRunning() then
        self.toggleButton:SetText("Disable")
        self.statusIndicator:SetTexture("Interface\\COMMON\\Indicator-Green")
        self.statusText:SetText("Rotation Active")
        self.statusText:SetTextColor(THEME.status.active.r, THEME.status.active.g, THEME.status.active.b, THEME.status.active.a)
    else
        self.toggleButton:SetText("Enable")
        self.statusIndicator:SetTexture("Interface\\COMMON\\Indicator-Red")
        self.statusText:SetText("Rotation Inactive")
        self.statusText:SetTextColor(THEME.status.inactive.r, THEME.status.inactive.g, THEME.status.inactive.b, THEME.status.inactive.a)
    end
    
    -- Update mode dropdown
    if WR.RotationManager and self.modeDropdown then
        UIDropDownMenu_SetText(self.modeDropdown, WR.RotationManager:GetMode():gsub("^%l", string.upper))
    end
end

-- Create tab frame at the top
function EnhancedConfigUI:CreateTabFrame()
    -- Create tab frame
    tabFrame = CreateFrame("Frame", nil, mainFrame, "BackdropTemplate")
    tabFrame:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 20, -90)
    tabFrame:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -20, -90)
    tabFrame:SetHeight(36)
    tabFrame:SetBackdrop({
        bgFile = textures.background,
        edgeFile = textures.border,
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    tabFrame:SetBackdropColor(THEME.header.r, THEME.header.g, THEME.header.b, THEME.header.a)
    
    -- Add tab scroll
    local tabScrollFrame = CreateFrame("ScrollFrame", "WindrunnerRotationsTabScroll", tabFrame)
    tabScrollFrame:SetPoint("TOPLEFT", tabFrame, "TOPLEFT", 4, -4)
    tabScrollFrame:SetPoint("BOTTOMRIGHT", tabFrame, "BOTTOMRIGHT", -4, 4)
    
    -- Create tab scroll child
    local tabScrollChild = CreateFrame("Frame", nil, tabScrollFrame)
    
    -- Determine total width needed for all tabs
    local totalTabsWidth = (#TABS * 100) + (#TABS * 5)
    tabScrollChild:SetSize(totalTabsWidth, tabScrollFrame:GetHeight())
    tabScrollFrame:SetScrollChild(tabScrollChild)
    
    -- Enable horizontal scrolling with mousewheel
    tabScrollFrame:EnableMouseWheel(true)
    tabScrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local scrollAmount = 40
        local newPosition = self:GetHorizontalScroll() - (delta * scrollAmount)
        local maxScrollRange = tabScrollChild:GetWidth() - self:GetWidth()
        
        if newPosition < 0 then
            newPosition = 0
        elseif newPosition > maxScrollRange then
            newPosition = maxScrollRange
        end
        
        self:SetHorizontalScroll(newPosition)
    end)
    
    -- Add left/right scroll buttons if needed
    if totalTabsWidth > tabScrollFrame:GetWidth() then
        -- Left scroll button
        local leftScrollButton = CreateFrame("Button", nil, tabFrame)
        leftScrollButton:SetSize(24, 24)
        leftScrollButton:SetPoint("LEFT", tabFrame, "LEFT", 5, 0)
        leftScrollButton:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up")
        leftScrollButton:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Down")
        leftScrollButton:SetDisabledTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Disabled")
        leftScrollButton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
        
        leftScrollButton:SetScript("OnClick", function()
            local scrollAmount = 100
            local newPosition = tabScrollFrame:GetHorizontalScroll() - scrollAmount
            if newPosition < 0 then
                newPosition = 0
            end
            tabScrollFrame:SetHorizontalScroll(newPosition)
        end)
        
        -- Right scroll button
        local rightScrollButton = CreateFrame("Button", nil, tabFrame)
        rightScrollButton:SetSize(24, 24)
        rightScrollButton:SetPoint("RIGHT", tabFrame, "RIGHT", -5, 0)
        rightScrollButton:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
        rightScrollButton:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Down")
        rightScrollButton:SetDisabledTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Disabled")
        rightScrollButton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
        
        rightScrollButton:SetScript("OnClick", function()
            local scrollAmount = 100
            local maxScrollRange = tabScrollChild:GetWidth() - tabScrollFrame:GetWidth()
            local newPosition = tabScrollFrame:GetHorizontalScroll() + scrollAmount
            if newPosition > maxScrollRange then
                newPosition = maxScrollRange
            end
            tabScrollFrame:SetHorizontalScroll(newPosition)
        end)
        
        -- Adjust tab scroll frame width
        tabScrollFrame:SetPoint("TOPLEFT", tabFrame, "TOPLEFT", 30, -4)
        tabScrollFrame:SetPoint("BOTTOMRIGHT", tabFrame, "BOTTOMRIGHT", -30, 4)
        
        -- Store reference
        self.leftScrollButton = leftScrollButton
        self.rightScrollButton = rightScrollButton
    end
    
    -- Create tabs
    for i, tabInfo in ipairs(TABS) do
        local tab = CreateFrame("Button", "WindrunnerRotationsTab"..i, tabScrollChild, "BackdropTemplate")
        tab:SetSize(96, 28)
        tab:SetPoint("TOPLEFT", tabScrollChild, "TOPLEFT", (i-1) * 100 + 4, -4)
        
        -- Set backdrop
        tab:SetBackdrop({
            bgFile = textures.background,
            edgeFile = textures.border,
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = {left = 3, right = 3, top = 3, bottom = 3}
        })
        
        -- Set initial appearance
        if tabInfo.name == currentTab then
            tab:SetBackdropColor(THEME.category.selected.r, THEME.category.selected.g, THEME.category.selected.b, THEME.category.selected.a)
        else
            tab:SetBackdropColor(THEME.category.normal.r, THEME.category.normal.g, THEME.category.normal.b, THEME.category.normal.a)
        end
        
        -- Create tab icon
        local tabIcon = tab:CreateTexture(nil, "ARTWORK")
        tabIcon:SetSize(16, 16)
        tabIcon:SetPoint("LEFT", tab, "LEFT", 6, 0)
        tabIcon:SetTexture(tabInfo.icon)
        
        -- Create tab text
        local tabText = tab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        tabText:SetPoint("LEFT", tabIcon, "RIGHT", 4, 0)
        tabText:SetText(tabInfo.displayName)
        tabText:SetFont(tabText:GetFont(), 10, "OUTLINE")
        tabText:SetTextColor(THEME.text.normal.r, THEME.text.normal.g, THEME.text.normal.b, THEME.text.normal.a)
        
        -- Highlight on hover
        tab:SetScript("OnEnter", function(self)
            if tabInfo.name ~= currentTab then
                self:SetBackdropColor(THEME.category.hover.r, THEME.category.hover.g, THEME.category.hover.b, THEME.category.hover.a)
                tabText:SetTextColor(THEME.text.highlight.r, THEME.text.highlight.g, THEME.text.highlight.b, THEME.text.highlight.a)
            end
        end)
        
        tab:SetScript("OnLeave", function(self)
            if tabInfo.name ~= currentTab then
                self:SetBackdropColor(THEME.category.normal.r, THEME.category.normal.g, THEME.category.normal.b, THEME.category.normal.a)
                tabText:SetTextColor(THEME.text.normal.r, THEME.text.normal.g, THEME.text.normal.b, THEME.text.normal.a)
            end
        end)
        
        -- Handle click
        tab:SetScript("OnClick", function(self)
            -- Update tab appearance
            for j, btn in ipairs(tabButtons) do
                local tabBtn = btn.button or btn -- Handle button wrapper if exists
                local tabBtnText = btn.text or btn:GetChildren()[2] -- Get text element
                
                if TABS[j].name == tabInfo.name then
                    tabBtn:SetBackdropColor(THEME.category.selected.r, THEME.category.selected.g, THEME.category.selected.b, THEME.category.selected.a)
                    if tabBtnText then
                        tabBtnText:SetTextColor(THEME.text.highlight.r, THEME.text.highlight.g, THEME.text.highlight.b, THEME.text.highlight.a)
                    end
                else
                    tabBtn:SetBackdropColor(THEME.category.normal.r, THEME.category.normal.g, THEME.category.normal.b, THEME.category.normal.a)
                    if tabBtnText then
                        tabBtnText:SetTextColor(THEME.text.normal.r, THEME.text.normal.g, THEME.text.normal.b, THEME.text.normal.a)
                    end
                end
            end
            
            -- Update current tab
            currentTab = tabInfo.name
            
            -- Refresh category frame
            EnhancedConfigUI:RefreshCategoryFrame()
            
            -- Reset selected category
            currentModule = nil
            currentCategory = nil
            
            -- Clear config frame
            EnhancedConfigUI:ClearConfigFrame()
        end)
        
        -- Store tab button with its components
        tabButtons[i] = {
            button = tab,
            icon = tabIcon,
            text = tabText
        }
    end
    
    -- Store references
    self.tabFrame = tabFrame
    self.tabScrollFrame = tabScrollFrame
    self.tabScrollChild = tabScrollChild
end

-- Create category frame (left panel)
function EnhancedConfigUI:CreateCategoryFrame()
    -- Create the category panel (positioned below the tab frame)
    categoryFrame = CreateFrame("Frame", nil, mainFrame, "BackdropTemplate")
    categoryFrame:SetSize(CATEGORY_WIDTH, UI_HEIGHT - 190)
    categoryFrame:SetPoint("TOPLEFT", tabFrame, "BOTTOMLEFT", 0, -10)
    categoryFrame:SetBackdrop({
        bgFile = textures.background,
        edgeFile = textures.border,
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    categoryFrame:SetBackdropColor(THEME.background.r, THEME.background.g, THEME.background.b, THEME.background.a)
    categoryFrame:SetBackdropBorderColor(THEME.border.r, THEME.border.g, THEME.border.b, THEME.border.a)
    
    -- Add category header
    local categoryHeader = CreateFrame("Frame", nil, categoryFrame, "BackdropTemplate")
    categoryHeader:SetHeight(28)
    categoryHeader:SetPoint("TOPLEFT", categoryFrame, "TOPLEFT", 0, 0)
    categoryHeader:SetPoint("TOPRIGHT", categoryFrame, "TOPRIGHT", 0, 0)
    categoryHeader:SetBackdrop({
        bgFile = textures.background,
        edgeFile = textures.border,
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    categoryHeader:SetBackdropColor(THEME.header.r, THEME.header.g, THEME.header.b, THEME.header.a)
    
    -- Add header text
    local headerText = categoryHeader:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    headerText:SetPoint("CENTER", categoryHeader, "CENTER", 0, 0)
    headerText:SetText("Categories")
    headerText:SetTextColor(THEME.text.header.r, THEME.text.header.g, THEME.text.header.b, THEME.text.header.a)
    
    -- Create scrollframe for categories
    categoryScrollFrame = CreateFrame("ScrollFrame", "WindrunnerRotationsCategoryScroll", categoryFrame, "UIPanelScrollFrameTemplate")
    categoryScrollFrame:SetPoint("TOPLEFT", categoryHeader, "BOTTOMLEFT", 8, -2)
    categoryScrollFrame:SetPoint("BOTTOMRIGHT", categoryFrame, "BOTTOMRIGHT", -30, 8)
    
    -- Create scroll child
    local categoryScrollChild = CreateFrame("Frame", nil, categoryScrollFrame)
    categoryScrollChild:SetSize(CATEGORY_WIDTH - 30, 1000)  -- Height will adjust dynamically
    categoryScrollFrame:SetScrollChild(categoryScrollChild)
    
    -- Create search label
    local searchLabel = categoryHeader:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    searchLabel:SetPoint("BOTTOMLEFT", categoryHeader, "BOTTOMLEFT", 10, 8)
    searchLabel:SetText("Search:")
    searchLabel:SetTextColor(THEME.text.header.r, THEME.text.header.g, THEME.text.header.b, THEME.text.header.a)
    
    -- Create search box
    local searchBox = CreateFrame("EditBox", "WindrunnerRotationsSearchBox", categoryHeader, "SearchBoxTemplate")
    searchBox:SetSize(CATEGORY_WIDTH - 70, 20)
    searchBox:SetPoint("LEFT", searchLabel, "RIGHT", 5, 0)
    searchBox:SetAutoFocus(false)
    searchBox:SetMaxLetters(50)
    searchBox:SetFont(searchBox:GetFont(), 12, "")
    
    -- Create clear button
    local clearButton = CreateFrame("Button", nil, searchBox, "UIPanelButtonTemplate")
    clearButton:SetSize(16, 16)
    clearButton:SetPoint("RIGHT", searchBox, "RIGHT", -2, 0)
    clearButton:SetText("×")
    clearButton:SetNormalFontObject("GameFontNormalSmall")
    clearButton:SetHighlightFontObject("GameFontHighlightSmall")
    clearButton:Hide()
    
    -- Search functionality
    searchBox:SetScript("OnTextChanged", function(self, userInput)
        local text = self:GetText()
        
        -- Show/hide clear button
        if text and text ~= "" then
            clearButton:Show()
        else
            clearButton:Hide()
        end
        
        -- Filter categories and get match count
        local matchCount = EnhancedConfigUI:FilterCategories(text)
        
        -- Apply visual feedback based on search results
        if text ~= "" then
            if matchCount > 0 then
                -- Found results, use normal color
                self:SetTextColor(1, 1, 1)
            else
                -- No results, use red tint
                self:SetTextColor(1, 0.5, 0.5)
            end
        else
            -- Empty search, use normal color
            self:SetTextColor(1, 1, 1)
        end
    end)
    
    searchBox:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
    end)
    
    searchBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
        self:SetText("")
        EnhancedConfigUI:FilterCategories("")
    end)
    
    -- Clear button functionality
    clearButton:SetScript("OnClick", function()
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        searchBox:SetText("")
        searchBox:ClearFocus()
        EnhancedConfigUI:FilterCategories("")
        clearButton:Hide()
    end)
    
    -- Store references
    self.categoryFrame = categoryFrame
    self.categoryHeader = categoryHeader
    self.categoryScrollFrame = categoryScrollFrame
    self.categoryScrollChild = categoryScrollChild
    self.searchBox = searchBox
    
    -- Initial population
    self:RefreshCategoryFrame()
end

-- Filter categories based on search text
function EnhancedConfigUI:FilterCategories(searchText)
    if not searchText or searchText == "" then
        -- Show all categories
        for _, button in ipairs(categoryButtons) do
            button:Show()
        end
        
        -- Hide no results message if it exists
        if self.noResultsMessage then
            self.noResultsMessage:Hide()
        end
        if self.noResultsFrame then
            self.noResultsFrame:Hide()
        end
        
        -- Update scroll child height
        self:UpdateCategoryScrollHeight()
        return 0
    end
    
    searchText = string.lower(searchText)
    local matchCount = 0
    
    -- Filter buttons based on their text matching the search
    for _, button in ipairs(categoryButtons) do
        local buttonText = button.text and button.text:GetText() or ""
        if string.find(string.lower(buttonText), searchText) then
            button:Show()
            matchCount = matchCount + 1
        else
            button:Hide()
        end
    end
    
    -- Show or hide the no results message
    if matchCount == 0 then
        -- Create message if it doesn't exist
        if not self.noResultsMessage then
            self.noResultsMessage = self.categoryScrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            self.noResultsMessage:SetPoint("CENTER", self.categoryScrollChild, "CENTER", 0, 0)
            self.noResultsMessage:SetText("No results found")
            self.noResultsMessage:SetTextColor(0.7, 0.7, 0.7, 1)
            
            -- Create a frame around the message for better visibility
            self.noResultsFrame = CreateFrame("Frame", nil, self.categoryScrollChild, "BackdropTemplate")
            self.noResultsFrame:SetBackdrop({
                bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile = true,
                tileSize = 16,
                edgeSize = 16,
                insets = {left = 4, right = 4, top = 4, bottom = 4}
            })
            self.noResultsFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.7)
            self.noResultsFrame:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)
            self.noResultsFrame:SetPoint("CENTER", self.noResultsMessage, "CENTER", 0, 0)
            self.noResultsFrame:SetSize(150, 30)
        end
        
        self.noResultsMessage:Show()
        self.noResultsFrame:Show()
    else 
        if self.noResultsMessage then
            self.noResultsMessage:Hide()
            self.noResultsFrame:Hide()
        end
    end
    
    -- Update scroll child height
    self:UpdateCategoryScrollHeight()
    
    return matchCount
end

-- Update category scroll child height based on visible buttons
function EnhancedConfigUI:UpdateCategoryScrollHeight()
    if not self.categoryScrollChild then return end
    
    local height = 0
    local visibleCount = 0
    
    for _, button in ipairs(categoryButtons) do
        if button:IsShown() then
            height = height + button:GetHeight() + 2 -- Add spacing
            visibleCount = visibleCount + 1
        end
    end
    
    -- Set minimum height
    if height < 100 then height = 100 end
    
    self.categoryScrollChild:SetHeight(height)
end

-- Create config frame (right panel)
function EnhancedConfigUI:CreateConfigFrame()
    -- Create the config panel
    configFrame = CreateFrame("Frame", nil, mainFrame, "BackdropTemplate")
    configFrame:SetSize(UI_WIDTH - CATEGORY_WIDTH - PANEL_SPACING - 40, UI_HEIGHT - 190)
    configFrame:SetPoint("TOPLEFT", categoryFrame, "TOPRIGHT", PANEL_SPACING, 0)
    configFrame:SetBackdrop({
        bgFile = textures.background,
        edgeFile = textures.border,
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    configFrame:SetBackdropColor(THEME.background.r, THEME.background.g, THEME.background.b, THEME.background.a)
    configFrame:SetBackdropBorderColor(THEME.border.r, THEME.border.g, THEME.border.b, THEME.border.a)
    
    -- Add config header
    local configHeader = CreateFrame("Frame", nil, configFrame, "BackdropTemplate")
    configHeader:SetHeight(28)
    configHeader:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 0, 0)
    configHeader:SetPoint("TOPRIGHT", configFrame, "TOPRIGHT", 0, 0)
    configHeader:SetBackdrop({
        bgFile = textures.background,
        edgeFile = textures.border,
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    configHeader:SetBackdropColor(THEME.header.r, THEME.header.g, THEME.header.b, THEME.header.a)
    
    -- Add header text (dynamic - will be updated when category is selected)
    local configTitle = configHeader:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    configTitle:SetPoint("LEFT", configHeader, "LEFT", 15, 0)
    configTitle:SetText("Settings")
    configTitle:SetTextColor(THEME.text.header.r, THEME.text.header.g, THEME.text.header.b, THEME.text.header.a)
    
    -- Create description for config section
    local configDesc = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    configDesc:SetPoint("TOPLEFT", configHeader, "BOTTOMLEFT", 15, -10)
    configDesc:SetPoint("RIGHT", configFrame, "RIGHT", -15, 0)
    configDesc:SetJustifyH("LEFT")
    configDesc:SetJustifyV("TOP")
    configDesc:SetText("Select a category from the left panel to configure settings.")
    configDesc:SetHeight(30)
    configDesc:SetTextColor(THEME.text.normal.r, THEME.text.normal.g, THEME.text.normal.b, THEME.text.normal.a)
    
    -- Create scrollframe for config options
    configScrollFrame = CreateFrame("ScrollFrame", "WindrunnerRotationsConfigScroll", configFrame, "UIPanelScrollFrameTemplate")
    configScrollFrame:SetPoint("TOPLEFT", configDesc, "BOTTOMLEFT", -5, -5)
    configScrollFrame:SetPoint("BOTTOMRIGHT", configFrame, "BOTTOMRIGHT", -30, 40)
    
    -- Create scroll child
    local configScrollChild = CreateFrame("Frame", nil, configScrollFrame)
    configScrollChild:SetSize(configScrollFrame:GetWidth() - SCROLLBAR_WIDTH, 1000)  -- Height will adjust
    configScrollFrame:SetScrollChild(configScrollChild)
    
    -- Add action buttons container
    local actionButtonsFrame = CreateFrame("Frame", nil, configFrame, "BackdropTemplate")
    actionButtonsFrame:SetHeight(30)
    actionButtonsFrame:SetPoint("BOTTOMLEFT", configFrame, "BOTTOMLEFT", 10, 8)
    actionButtonsFrame:SetPoint("BOTTOMRIGHT", configFrame, "BOTTOMRIGHT", -10, 8)
    
    -- Create reset button
    local resetButton = CreateFrame("Button", nil, actionButtonsFrame, "UIPanelButtonTemplate")
    resetButton:SetSize(100, 22)
    resetButton:SetPoint("RIGHT", actionButtonsFrame, "RIGHT", -5, 0)
    resetButton:SetText("Reset")
    resetButton:SetScript("OnClick", function()
        if currentModule and currentCategory then
            StaticPopup_Show("WINDRUNNER_RESET_CONFIRM", currentModule)
        end
    end)
    resetButton:Hide() -- Hide until a category is selected
    
    -- Create profile buttons
    local saveProfileButton = CreateFrame("Button", nil, actionButtonsFrame, "UIPanelButtonTemplate")
    saveProfileButton:SetSize(120, 22)
    saveProfileButton:SetPoint("LEFT", actionButtonsFrame, "LEFT", 5, 0)
    saveProfileButton:SetText("Save Profile")
    saveProfileButton:SetScript("OnClick", function()
        StaticPopup_Show("WINDRUNNER_SAVE_PROFILE")
    end)
    
    local loadProfileButton = CreateFrame("Button", nil, actionButtonsFrame, "UIPanelButtonTemplate")
    loadProfileButton:SetSize(120, 22)
    loadProfileButton:SetPoint("LEFT", saveProfileButton, "RIGHT", 5, 0)
    loadProfileButton:SetText("Load Profile")
    loadProfileButton:SetScript("OnClick", function()
        EnhancedConfigUI:ShowProfilesMenu()
    end)
    
    -- Create confirmation dialog for reset
    StaticPopupDialogs["WINDRUNNER_RESET_CONFIRM"] = {
        text = "Reset %s settings to default values?",
        button1 = "Yes",
        button2 = "No",
        OnAccept = function()
            if currentModule and currentCategory then
                -- Reset settings for this module
                ConfigRegistry:ResetSettings(currentModule)
                
                -- Refresh config display
                EnhancedConfigUI:BuildConfigOptions(currentModule, currentCategory)
            end
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3
    }
    
    -- Create save profile dialog
    StaticPopupDialogs["WINDRUNNER_SAVE_PROFILE"] = {
        text = "Enter a name for this profile:",
        button1 = "Save",
        button2 = "Cancel",
        hasEditBox = true,
        OnAccept = function(self)
            local profileName = self.editBox:GetText()
            if profileName and profileName ~= "" then
                ConfigRegistry:SaveProfile(profileName)
                print("|cFF00CCFFWindrunner Rotations:|r Profile '" .. profileName .. "' saved.")
            end
        end,
        OnShow = function(self)
            self.editBox:SetText("Profile " .. date("%m-%d-%y %H:%M"))
            self.editBox:HighlightText()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3
    }
    
    -- Store references
    self.configFrame = configFrame
    self.configHeader = configHeader
    self.configTitle = configTitle
    self.configDesc = configDesc
    self.configScrollFrame = configScrollFrame
    self.configScrollChild = configScrollChild
    self.actionButtonsFrame = actionButtonsFrame
    self.resetButton = resetButton
    self.saveProfileButton = saveProfileButton
    self.loadProfileButton = loadProfileButton
end

-- Show profiles dropdown menu
function EnhancedConfigUI:ShowProfilesMenu()
    -- Create or get the dropdown frame
    if not self.profilesDropdown then
        self.profilesDropdown = CreateFrame("Frame", "WindrunnerRotationsProfilesDropdown", UIParent, "UIDropDownMenuTemplate")
    end
    
    -- Get saved profiles
    local profiles = ConfigRegistry:GetProfiles() or {}
    
    -- Initialize the dropdown menu
    UIDropDownMenu_Initialize(self.profilesDropdown, function(self, level)
        local info = UIDropDownMenu_CreateInfo()
        
        info.text = "Select Profile to Load"
        info.isTitle = true
        info.notCheckable = true
        UIDropDownMenu_AddButton(info, level)
        
        info.isTitle = false
        info.disabled = false
        info.notCheckable = false
        
        for profileName, _ in pairs(profiles) do
            info.text = profileName
            info.func = function()
                ConfigRegistry:LoadProfile(profileName)
                print("|cFF00CCFFWindrunner Rotations:|r Profile '" .. profileName .. "' loaded.")
                
                -- Refresh UI if a category is selected
                if currentModule and currentCategory then
                    EnhancedConfigUI:BuildConfigOptions(currentModule, currentCategory)
                end
            end
            info.checked = false
            UIDropDownMenu_AddButton(info, level)
        end
        
        if next(profiles) == nil then
            info.text = "No saved profiles"
            info.func = nil
            info.disabled = true
            info.notCheckable = true
            UIDropDownMenu_AddButton(info, level)
        end
        
        -- Add delete option
        info.disabled = false
        info.notCheckable = true
        info.text = "Delete Profile..."
        info.func = function()
            EnhancedConfigUI:ShowDeleteProfileMenu()
        end
        UIDropDownMenu_AddButton(info, level)
    end)
    
    -- Show the dropdown
    ToggleDropDownMenu(1, nil, self.profilesDropdown, "cursor", 0, 0)
end

-- Show delete profile dropdown menu
function EnhancedConfigUI:ShowDeleteProfileMenu()
    -- Create or get the dropdown frame
    if not self.deleteProfileDropdown then
        self.deleteProfileDropdown = CreateFrame("Frame", "WindrunnerRotationsDeleteProfileDropdown", UIParent, "UIDropDownMenuTemplate")
    end
    
    -- Get saved profiles
    local profiles = ConfigRegistry:GetProfiles() or {}
    
    -- Initialize the dropdown menu
    UIDropDownMenu_Initialize(self.deleteProfileDropdown, function(self, level)
        local info = UIDropDownMenu_CreateInfo()
        
        info.text = "Select Profile to Delete"
        info.isTitle = true
        info.notCheckable = true
        UIDropDownMenu_AddButton(info, level)
        
        info.isTitle = false
        info.disabled = false
        info.notCheckable = true
        
        for profileName, _ in pairs(profiles) do
            info.text = profileName
            info.func = function()
                StaticPopup_Show("WINDRUNNER_DELETE_PROFILE_CONFIRM", profileName)
            end
            UIDropDownMenu_AddButton(info, level)
        end
        
        if next(profiles) == nil then
            info.text = "No saved profiles"
            info.func = nil
            info.disabled = true
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    
    -- Create delete profile confirmation dialog
    StaticPopupDialogs["WINDRUNNER_DELETE_PROFILE_CONFIRM"] = {
        text = "Delete profile '%s'?",
        button1 = "Yes",
        button2 = "No",
        OnAccept = function(self, data)
            ConfigRegistry:DeleteProfile(data)
            print("|cFF00CCFFWindrunner Rotations:|r Profile '" .. data .. "' deleted.")
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3
    }
    
    -- Show the dropdown
    ToggleDropDownMenu(1, nil, self.deleteProfileDropdown, "cursor", 0, 0)
end

-- Register slash commands
function EnhancedConfigUI:RegisterSlashCommands()
    -- Register /wr and /windrunner
    SLASH_WINDRUNNERROTATIONS1 = "/wr"
    SLASH_WINDRUNNERROTATIONS2 = "/windrunner"
    SlashCmdList["WINDRUNNERROTATIONS"] = function(msg)
        if msg == "config" or msg == "" then
            -- Toggle config UI
            if mainFrame:IsShown() then
                mainFrame:Hide()
            else
                mainFrame:Show()
            end
        elseif msg == "debug" then
            -- Toggle debug mode
            local debugMode = not ConfigRegistry:GetSetting("General", "debugMode")
            ConfigRegistry:SetSetting("General", "debugMode", debugMode)
            if debugMode then
                print("|cFF00CCFFWR:|r Debug mode enabled")
            else
                print("|cFF00CCFFWR:|r Debug mode disabled")
            end
        elseif msg == "reset" then
            -- Reset all settings
            ConfigRegistry:ResetAllSettings()
            print("|cFF00CCFFWR:|r All settings have been reset to defaults")
        elseif msg:match("^version") then
            -- Show version info
            local version = WR.Version or "Unknown"
            print("|cFF00CCFFWindrunner Rotations:|r Version " .. version)
        elseif msg:match("^help") then
            -- Show help
            print("|cFF00CCFFWindrunner Rotations:|r Command Help")
            print("/wr or /windrunner - Toggle configuration UI")
            print("/wr config - Open configuration UI")
            print("/wr debug - Toggle debug mode")
            print("/wr reset - Reset all settings to defaults")
            print("/wr version - Show addon version")
            print("/wr help - Show this help message")
        else
            -- Invalid command
            print("|cFF00CCFFWR:|r Unknown command. Type '/wr help' for a list of commands.")
        end
    end
end

-- Refresh the category frame based on current tab
function EnhancedConfigUI:RefreshCategoryFrame()
    -- Clear existing category buttons
    for _, button in pairs(categoryButtons) do
        button:Hide()
    end
    categoryButtons = {}
    
    -- Get modules for current tab
    local tabModules = TAB_FILTERS[currentTab].modules
    if not tabModules then return end
    
    -- Sort modules by predefined order
    local sortedModules = {}
    for _, moduleName in ipairs(MODULE_ORDER) do
        if tContains(tabModules, moduleName) then
            tinsert(sortedModules, moduleName)
        end
    end
    
    -- Add any missing modules at the end
    for _, moduleName in ipairs(tabModules) do
        if not tContains(sortedModules, moduleName) then
            tinsert(sortedModules, moduleName)
        end
    end
    
    -- First create module headers
    local yOffset = 5
    local headerHeight = 24
    local buttonHeight = 30
    local moduleButtons = {}
    local lastModuleType = nil
    
    -- Function to create header
    local function CreateHeader(headerText)
        local header = CreateFrame("Frame", nil, self.categoryScrollChild, "BackdropTemplate")
        header:SetSize(self.categoryScrollChild:GetWidth() - 10, headerHeight)
        header:SetPoint("TOPLEFT", self.categoryScrollChild, "TOPLEFT", 5, -yOffset)
        
        -- Set backdrop
        header:SetBackdrop({
            bgFile = textures.background,
            edgeFile = nil,
            tile = true,
            tileSize = 16,
            insets = {left = 2, right = 2, top = 2, bottom = 2}
        })
        header:SetBackdropColor(THEME.header.r, THEME.header.g, THEME.header.b, THEME.header.a)
        
        -- Create header text
        local text = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("LEFT", header, "LEFT", 8, 0)
        text:SetText(headerText)
        text:SetTextColor(THEME.text.header.r, THEME.text.header.g, THEME.text.header.b, THEME.text.header.a)
        
        -- Add a thin line at the bottom
        local bottomLine = header:CreateTexture(nil, "BACKGROUND")
        bottomLine:SetPoint("BOTTOMLEFT", header, "BOTTOMLEFT", 0, 0)
        bottomLine:SetPoint("BOTTOMRIGHT", header, "BOTTOMRIGHT", 0, 0)
        bottomLine:SetHeight(1)
        bottomLine:SetColorTexture(THEME.border.r, THEME.border.g, THEME.border.b, 0.6)
        
        yOffset = yOffset + headerHeight + 2
        return header
    end
    
    -- Group modules by type
    local moduleGroups = {
        General = {},
        Classes = {},
        Features = {},
        Advanced = {}
    }
    
    -- Sort modules into groups
    for _, moduleName in ipairs(sortedModules) do
        if moduleName == "General" or moduleName == "Combat" then
            table.insert(moduleGroups.General, moduleName)
        elseif moduleName == "Debug" or moduleName == "Advanced" or moduleName == "Performance" then
            table.insert(moduleGroups.Advanced, moduleName)
        elseif moduleName == "DeathKnight" or moduleName == "DemonHunter" or moduleName == "Druid" 
            or moduleName == "Evoker" or moduleName == "Hunter" or moduleName == "Mage" 
            or moduleName == "Monk" or moduleName == "Paladin" or moduleName == "Priest" 
            or moduleName == "Rogue" or moduleName == "Shaman" or moduleName == "Warlock" 
            or moduleName == "Warrior" then
            table.insert(moduleGroups.Classes, moduleName)
        else
            table.insert(moduleGroups.Features, moduleName)
        end
    end
    
    -- Create headers and buttons for each group
    local groupOrder = {"General", "Classes", "Features", "Advanced"}
    
    for _, groupName in ipairs(groupOrder) do
        local group = moduleGroups[groupName]
        if #group > 0 then
            -- Create header
            CreateHeader(groupName)
            
            -- Create buttons for each module in this group
            for i, moduleName in ipairs(group) do
                -- Create button
                local button = CreateFrame("Button", "WindrunnerRotationsCategory"..moduleName, self.categoryScrollChild, "BackdropTemplate")
                button:SetSize(self.categoryScrollChild:GetWidth() - 16, buttonHeight)
                button:SetPoint("TOPLEFT", self.categoryScrollChild, "TOPLEFT", 8, -yOffset)
                
                -- Set backdrop
                button:SetBackdrop({
                    bgFile = textures.background,
                    edgeFile = nil,
                    tile = true,
                    tileSize = 16,
                    insets = {left = 4, right = 4, top = 4, bottom = 4}
                })
                button:SetBackdropColor(THEME.category.normal.r, THEME.category.normal.g, THEME.category.normal.b, THEME.category.normal.a)
                
                -- Create icon
                local icon
                if groupName == "Classes" then
                    -- Use class icon for class modules
                    icon = button:CreateTexture(nil, "ARTWORK")
                    icon:SetSize(20, 20)
                    icon:SetPoint("LEFT", button, "LEFT", 6, 0)
                    icon:SetTexture("Interface\\Icons\\ClassIcon_" .. moduleName)
                    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)  -- Trim icon borders
                elseif moduleName == "Combat" then
                    icon = button:CreateTexture(nil, "ARTWORK")
                    icon:SetSize(20, 20)
                    icon:SetPoint("LEFT", button, "LEFT", 6, 0)
                    icon:SetTexture("Interface\\Icons\\Ability_DualWield")
                    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                elseif moduleName == "Defensives" then
                    icon = button:CreateTexture(nil, "ARTWORK")
                    icon:SetSize(20, 20)
                    icon:SetPoint("LEFT", button, "LEFT", 6, 0)
                    icon:SetTexture("Interface\\Icons\\Ability_Warrior_DefensiveStance")
                    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                elseif moduleName == "Interrupts" then
                    icon = button:CreateTexture(nil, "ARTWORK")
                    icon:SetSize(20, 20)
                    icon:SetPoint("LEFT", button, "LEFT", 6, 0)
                    icon:SetTexture("Interface\\Icons\\Ability_Kick")
                    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                else
                    -- Use generic icon for other modules
                    icon = button:CreateTexture(nil, "ARTWORK")
                    icon:SetSize(20, 20)
                    icon:SetPoint("LEFT", button, "LEFT", 6, 0)
                    icon:SetTexture("Interface\\Icons\\INV_Misc_Gear_01")
                    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                end
                
                -- Create text
                local text = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                text:SetPoint("LEFT", icon, "RIGHT", 6, 0)
                text:SetText(moduleName)
                text:SetTextColor(THEME.text.normal.r, THEME.text.normal.g, THEME.text.normal.b, THEME.text.normal.a)
                
                -- Highlight on hover
                button:SetScript("OnEnter", function(self)
                    self:SetBackdropColor(THEME.category.hover.r, THEME.category.hover.g, THEME.category.hover.b, THEME.category.hover.a)
                    text:SetTextColor(THEME.text.highlight.r, THEME.text.highlight.g, THEME.text.highlight.b, THEME.text.highlight.a)
                end)
                
                button:SetScript("OnLeave", function(self)
                    if currentModule ~= moduleName then
                        self:SetBackdropColor(THEME.category.normal.r, THEME.category.normal.g, THEME.category.normal.b, THEME.category.normal.a)
                        text:SetTextColor(THEME.text.normal.r, THEME.text.normal.g, THEME.text.normal.b, THEME.text.normal.a)
                    end
                end)
                
                -- Set tooltip based on module type
                local tooltipText = ""
                if groupName == "Classes" then
                    -- Set class-specific tooltip
                    tooltipText = "Configure " .. moduleName .. " settings"
                elseif moduleName == "Combat" then
                    tooltipText = "Configure general combat settings for all classes"
                elseif moduleName == "Defensives" then
                    tooltipText = "Configure defensive ability usage and thresholds"
                elseif moduleName == "Interrupts" then
                    tooltipText = "Configure interrupt spell priorities and settings"
                else
                    tooltipText = "Configure " .. moduleName .. " settings"
                end
                
                -- Add tooltip functionality
                button:SetScript("OnEnter", function(self)
                    -- Change appearance
                    self:SetBackdropColor(THEME.category.hover.r, THEME.category.hover.g, THEME.category.hover.b, THEME.category.hover.a)
                    text:SetTextColor(THEME.text.highlight.r, THEME.text.highlight.g, THEME.text.highlight.b, THEME.text.highlight.a)
                    
                    -- Show tooltip
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:SetText(tooltipText, 1, 1, 1)
                    GameTooltip:Show()
                end)
                
                button:SetScript("OnLeave", function(self)
                    -- Reset appearance if not selected
                    if currentModule ~= moduleName then
                        self:SetBackdropColor(THEME.category.normal.r, THEME.category.normal.g, THEME.category.normal.b, THEME.category.normal.a)
                        text:SetTextColor(THEME.text.normal.r, THEME.text.normal.g, THEME.text.normal.b, THEME.text.normal.a)
                    end
                    
                    -- Hide tooltip
                    GameTooltip:Hide()
                end)
                
                -- Handle click
                button:SetScript("OnClick", function(self)
                    -- Play sound
                    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
                    
                    -- Reset previously selected button
                    for j, btn in ipairs(categoryButtons) do
                        btn:SetBackdropColor(THEME.category.normal.r, THEME.category.normal.g, THEME.category.normal.b, THEME.category.normal.a)
                        btn.text:SetTextColor(THEME.text.normal.r, THEME.text.normal.g, THEME.text.normal.b, THEME.text.normal.a)
                    end
                    
                    -- Highlight current button
                    self:SetBackdropColor(THEME.category.selected.r, THEME.category.selected.g, THEME.category.selected.b, THEME.category.selected.a)
                    text:SetTextColor(THEME.text.highlight.r, THEME.text.highlight.g, THEME.text.highlight.b, THEME.text.highlight.a)
                    
                    -- Set current module
                    currentModule = moduleName
                    
                    -- Get first category for this module
                    local categories = ConfigRegistry:GetCategoriesForModule(moduleName)
                    if categories and #categories > 0 then
                        currentCategory = categories[1]
                        -- Build config options
                        EnhancedConfigUI:BuildConfigOptions(moduleName, currentCategory)
                    else
                        -- No categories, display message
                        EnhancedConfigUI:ClearConfigFrame()
                        EnhancedConfigUI.configTitle:SetText("No Categories")
                        EnhancedConfigUI.configDesc:SetText("No categories found for module: " .. moduleName)
                    end
                end)
                
                -- Store references
                button.text = text
                button.icon = icon
                table.insert(categoryButtons, button)
                
                -- Update y offset
                yOffset = yOffset + buttonHeight + 2
            end
            
            -- Add spacer after each group
            yOffset = yOffset + 5
        end
    end
    
    -- Update scroll child height
    self.categoryScrollChild:SetHeight(math.max(yOffset + 5, self.categoryScrollFrame:GetHeight()))
    
    -- Apply any active search filter
    if self.searchBox and self.searchBox:GetText() and self.searchBox:GetText() ~= "" then
        self:FilterCategories(self.searchBox:GetText())
    end
end

-- Build category buttons for a module
function EnhancedConfigUI:BuildCategoryButtons(moduleName)
    -- Clear existing subcategory buttons
    for _, button in pairs(categoryButtons) do
        if button.isSubCategory then
            button:Hide()
        end
    end
    
    -- Get settings for this module
    local settings = ConfigRegistry:GetRegisteredSettings(moduleName)
    if not settings then
        -- Update config frame
        self.configTitle:SetText("No Settings Available")
        self.configDesc:SetText("This module has no configurable settings.")
        self:ClearConfigFrame()
        return
    end
    
    -- Get allowed categories for current tab
    local tabCategories = TAB_FILTERS[currentTab].categories
    
    -- Filter categories that match the current tab
    local filteredCategories = {}
    for categoryName, _ in pairs(settings) do
        if tContains(tabCategories, categoryName) then
            tinsert(filteredCategories, categoryName)
        end
    end
    
    -- Sort categories
    table.sort(filteredCategories)
    
    -- Calculate starting y position based on parent button
    local parentButton = categoryButtons[moduleName]
    local yOffset = select(5, parentButton:GetPoint()) * -1 + 35
    
    -- Create buttons for each category
    for i, categoryName in ipairs(filteredCategories) do
        -- Create button if it doesn't exist
        local buttonName = "WindrunnerRotationsSubCategory"..moduleName..categoryName
        local button = CreateFrame("Button", buttonName, self.categoryScrollChild, "BackdropTemplate")
        button:SetSize(self.categoryScrollChild:GetWidth() - 20, 25)
        button:SetPoint("TOPLEFT", self.categoryScrollChild, "TOPLEFT", 15, -yOffset)
        
        -- Set backdrop
        button:SetBackdrop({
            bgFile = textures.background,
            edgeFile = nil,
            tile = true,
            tileSize = 16,
            insets = {left = 2, right = 2, top = 2, bottom = 2}
        })
        button:SetBackdropColor(THEME.category.normal.r, THEME.category.normal.g, THEME.category.normal.b, THEME.category.normal.a)
        
        -- Create text
        local text = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        text:SetPoint("LEFT", button, "LEFT", 10, 0)
        text:SetText(self:FormatCategoryName(categoryName))
        text:SetTextColor(THEME.text.normal.r, THEME.text.normal.g, THEME.text.normal.b, THEME.text.normal.a)
        
        -- Mark as subcategory
        button.isSubCategory = true
        
        -- Create tooltip text based on category
        local tooltipText = "Configure " .. self:FormatCategoryName(categoryName) .. " settings for " .. moduleName
        
        -- Highlight on hover
        button:SetScript("OnEnter", function(self)
            if currentCategory ~= categoryName then
                self:SetBackdropColor(THEME.category.hover.r, THEME.category.hover.g, THEME.category.hover.b, THEME.category.hover.a)
            end
            
            -- Show tooltip
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(tooltipText, 1, 1, 1)
            GameTooltip:Show()
        end)
        
        button:SetScript("OnLeave", function(self)
            if currentCategory ~= categoryName then
                self:SetBackdropColor(THEME.category.normal.r, THEME.category.normal.g, THEME.category.normal.b, THEME.category.normal.a)
            end
            
            -- Hide tooltip
            GameTooltip:Hide()
        end)
        
        -- Click handler
        button:SetScript("OnClick", function(self)
            -- Play sound
            PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
            
            -- Update currently selected category
            currentCategory = categoryName
            
            -- Update button appearances
            for _, btn in pairs(categoryButtons) do
                if btn.isSubCategory then
                    btn:SetBackdropColor(THEME.category.normal.r, THEME.category.normal.g, THEME.category.normal.b, THEME.category.normal.a)
                end
            end
            self:SetBackdropColor(THEME.category.selected.r, THEME.category.selected.g, THEME.category.selected.b, THEME.category.selected.a)
            
            -- Build config options
            EnhancedConfigUI:BuildConfigOptions(moduleName, categoryName)
        end)
        
        -- Store the button
        local btnKey = moduleName .. "_" .. categoryName
        categoryButtons[btnKey] = button
        
        -- Update y offset for next button
        yOffset = yOffset + 30
    end
    
    -- Update scroll child height
    self.categoryScrollChild:SetHeight(math.max(500, yOffset + 5))
end

-- Filter categories by search text
function EnhancedConfigUI:FilterCategories(searchText)
    if not searchText or searchText == "" then
        -- Show all categories
        for _, button in ipairs(categoryButtons) do
            button:Show()
        end
        return
    end
    
    searchText = string.lower(searchText)
    local matchCount = 0
    
    -- Check each button for a match
    for _, button in ipairs(categoryButtons) do
        local buttonText = string.lower(button.text:GetText() or "")
        if string.find(buttonText, searchText) then
            button:Show()
            matchCount = matchCount + 1
        else
            button:Hide()
        end
    end
    
    -- Update scroll child height based on visible buttons
    local visibleHeight = 0
    for _, button in ipairs(categoryButtons) do
        if button:IsShown() then
            visibleHeight = visibleHeight + button:GetHeight() + 2
        end
    end
    
    -- Add padding
    visibleHeight = visibleHeight + 10
    
    -- Update scroll child height
    self.categoryScrollChild:SetHeight(math.max(visibleHeight, self.categoryScrollFrame:GetHeight()))
    
    return matchCount
end

-- Format category name for display
function EnhancedConfigUI:FormatCategoryName(categoryName)
    -- Convert camelCase to Title Case with spaces
    local result = categoryName:gsub("([A-Z])", " %1"):gsub("^%s", "")
    
    -- Remove "Settings" suffix if present
    result = result:gsub(" Settings$", "")
    
    -- Capitalize first letter
    result = result:gsub("^%l", string.upper)
    
    return result
end

-- Clear the config frame
function EnhancedConfigUI:ClearConfigFrame()
    -- Hide all widget frames
    for _, widget in pairs(configWidgets) do
        widget:Hide()
    end
    
    -- Reset configWidgets
    configWidgets = {}
    
    -- Hide reset button
    self.resetButton:Hide()
end

-- Build config options for a module and category
function EnhancedConfigUI:BuildConfigOptions(moduleName, categoryName)
    -- Clear existing options
    self:ClearConfigFrame()
    
    -- Get settings for this module
    local settings = ConfigRegistry:GetRegisteredSettings(moduleName)
    if not settings or not settings[categoryName] then
        self.configTitle:SetText("No Settings")
        self.configDesc:SetText("No settings found for this category.")
        return
    end
    
    -- Update title and description
    self.configTitle:SetText(moduleName)
    self.configDesc:SetText("Configure settings for " .. self:FormatCategoryName(categoryName))
    
    -- Show reset button
    self.resetButton:Show()
    
    -- Store current module and category
    currentModule = moduleName
    currentCategory = categoryName
    
    -- Get the category settings
    local categorySettings = settings[categoryName]
    
    -- Sort options by display order
    local sortedOptions = {}
    for optionName, optionInfo in pairs(categorySettings) do
        tinsert(sortedOptions, {name = optionName, info = optionInfo})
    end
    table.sort(sortedOptions, function(a, b)
        local orderA = a.info.order or 100
        local orderB = b.info.order or 100
        if orderA == orderB then
            return a.name < b.name
        end
        return orderA < orderB
    end)
    
    -- Get current values
    local currentValues = ConfigRegistry:GetSettings(moduleName)
    
    -- Build widgets for each option
    local yOffset = 5
    for i, option in ipairs(sortedOptions) do
        local optionName = option.name
        local optionInfo = option.info
        local optionValue = currentValues[optionName]
        
        -- Default to option's default value if nil
        if optionValue == nil then
            optionValue = optionInfo.default
        end
        
        -- Create option frame
        local optionFrame = CreateFrame("Frame", nil, self.configScrollChild)
        optionFrame:SetSize(self.configScrollChild:GetWidth() - 20, ITEM_HEIGHT)
        optionFrame:SetPoint("TOPLEFT", self.configScrollChild, "TOPLEFT", 10, -yOffset)
        
        -- Create option label
        local optionLabel = optionFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        optionLabel:SetPoint("TOPLEFT", optionFrame, "TOPLEFT", 0, 0)
        optionLabel:SetPoint("TOPRIGHT", optionFrame, "TOPRIGHT", -200, 0)
        optionLabel:SetJustifyH("LEFT")
        optionLabel:SetText(optionInfo.displayName or optionName)
        optionLabel:SetTextColor(THEME.text.normal.r, THEME.text.normal.g, THEME.text.normal.b, THEME.text.normal.a)
        
        -- Create widget based on option type
        local widget, height = self:CreateOptionWidget(optionFrame, moduleName, optionName, optionInfo, optionValue)
        
        -- Adjust frame height if needed
        if height and height > ITEM_HEIGHT then
            optionFrame:SetHeight(height)
        end
        
        -- Add tooltip/help text if available
        if optionInfo.description and optionInfo.description ~= "" then
            optionFrame:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(optionInfo.displayName or optionName, 1, 1, 1)
                GameTooltip:AddLine(optionInfo.description, nil, nil, nil, true)
                GameTooltip:Show()
            end)
            
            optionFrame:SetScript("OnLeave", function(self)
                GameTooltip:Hide()
            end)
        end
        
        -- Store widget
        configWidgets[optionName] = optionFrame
        
        -- Update y offset for next option
        yOffset = yOffset + optionFrame:GetHeight() + ITEM_SPACING
    end
    
    -- Update scroll child height
    self.configScrollChild:SetHeight(math.max(600, yOffset + 5))
    
    -- Show reset button
    self.resetButton:Show()
end

-- Create widget for an option based on its type
function EnhancedConfigUI:CreateOptionWidget(parent, moduleName, optionName, optionInfo, currentValue)
    local widgetType = optionInfo.type or "string"
    local widget
    local height = ITEM_HEIGHT
    
    if widgetType == "toggle" or widgetType == "boolean" then
        -- Create checkbox
        widget = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
        widget:SetSize(26, 26)
        widget:SetPoint("RIGHT", parent, "RIGHT", -10, 0)
        widget:SetChecked(currentValue)
        
        widget:SetScript("OnClick", function(self)
            local newValue = self:GetChecked()
            ConfigRegistry:SetSetting(moduleName, optionName, newValue)
        end)
        
    elseif widgetType == "slider" or widgetType == "number" then
        -- Create slider
        widget = CreateFrame("Slider", nil, parent, "OptionsSliderTemplate")
        widget:SetWidth(180)
        widget:SetPoint("RIGHT", parent, "RIGHT", -10, 0)
        
        -- Set up slider properties
        local minValue = optionInfo.min or 0
        local maxValue = optionInfo.max or 100
        local step = optionInfo.step or 1
        
        widget:SetMinMaxValues(minValue, maxValue)
        widget:SetValueStep(step)
        widget:SetObeyStepOnDrag(true)
        widget:SetValue(currentValue)
        
        -- Update slider text
        widget.Low:SetText(minValue)
        widget.High:SetText(maxValue)
        widget.Text:SetText(currentValue)
        
        -- Handle value changes
        widget:SetScript("OnValueChanged", function(self, value)
            -- Round to nearest step if needed
            if step > 0 then
                value = math.floor(value / step + 0.5) * step
            end
            
            -- Update text
            self.Text:SetText(value)
            
            -- Update in config registry (but only if released to prevent spam)
            if self:IsMouseDown() then return end
            
            ConfigRegistry:SetSetting(moduleName, optionName, value)
        end)
        
    elseif widgetType == "dropdown" or widgetType == "select" then
        -- Create dropdown (using LibUIDropDownMenu if available)
        if LibStub and LibStub:GetLibrary("LibUIDropDownMenu-4.0", true) then
            local LibDD = LibStub:GetLibrary("LibUIDropDownMenu-4.0")
            widget = LibDD:Create_UIDropDownMenu(nil, parent)
        else
            widget = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")
        end
        
        widget:SetPoint("RIGHT", parent, "RIGHT", -10, 0)
        UIDropDownMenu_SetWidth(widget, 180)
        
        local options = optionInfo.options or {}
        local function OnClick(self)
            UIDropDownMenu_SetSelectedValue(widget, self.value)
            ConfigRegistry:SetSetting(moduleName, optionName, self.value)
        end
        
        -- Initialize the dropdown
        UIDropDownMenu_Initialize(widget, function()
            local info = UIDropDownMenu_CreateInfo()
            for i, option in ipairs(options) do
                info.text = option
                info.value = option
                info.func = OnClick
                info.checked = (option == currentValue)
                UIDropDownMenu_AddButton(info)
            end
        end)
        
        -- Set initial value
        if currentValue and tContains(options, currentValue) then
            UIDropDownMenu_SetSelectedValue(widget, currentValue)
        else
            UIDropDownMenu_SetText(widget, "Select an option")
        end
        
    elseif widgetType == "color" then
        -- Create color picker button
        widget = CreateFrame("Button", nil, parent)
        widget:SetSize(20, 20)
        widget:SetPoint("RIGHT", parent, "RIGHT", -10, 0)
        
        -- Create color swatch
        local color = currentValue or {r = 1, g = 1, b = 1, a = 1}
        local swatch = widget:CreateTexture(nil, "OVERLAY")
        swatch:SetAllPoints(widget)
        swatch:SetColorTexture(color.r, color.g, color.b, color.a)
        
        -- Create border
        local border = widget:CreateTexture(nil, "BACKGROUND")
        border:SetPoint("TOPLEFT", widget, "TOPLEFT", -1, 1)
        border:SetPoint("BOTTOMRIGHT", widget, "BOTTOMRIGHT", 1, -1)
        border:SetColorTexture(0.3, 0.3, 0.3, 1)
        
        widget:SetScript("OnClick", function(self)
            -- Store references for callback
            local function ColorPickerCallback(restore)
                local newR, newG, newB, newA
                if restore then
                    -- User canceled, restore previous
                    newR, newG, newB, newA = unpack(restore)
                else
                    -- Get new color values
                    newA, newR, newG, newB = OpacitySliderFrame:GetValue(), ColorPickerFrame:GetColorRGB()
                end
                
                -- Update swatch
                swatch:SetColorTexture(newR, newG, newB, newA)
                
                -- Update setting
                ConfigRegistry:SetSetting(moduleName, optionName, {r = newR, g = newG, b = newB, a = newA})
            end
            
            -- Open color picker
            ColorPickerFrame.hasOpacity = true
            ColorPickerFrame.opacity = color.a
            ColorPickerFrame.previousValues = {color.r, color.g, color.b, color.a}
            ColorPickerFrame.func = ColorPickerCallback
            ColorPickerFrame.opacityFunc = ColorPickerCallback
            ColorPickerFrame.cancelFunc = ColorPickerCallback
            
            ColorPickerFrame:SetColorRGB(color.r, color.g, color.b)
            ColorPickerFrame:Hide() -- Need to hide first to ensure OnShow fires
            ColorPickerFrame:Show()
        end)
        
    elseif widgetType == "string" or widgetType == "text" then
        -- Create edit box
        widget = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
        widget:SetSize(180, 20)
        widget:SetPoint("RIGHT", parent, "RIGHT", -10, 0)
        widget:SetAutoFocus(false)
        widget:SetText(currentValue or "")
        
        widget:SetScript("OnEnterPressed", function(self)
            local newValue = self:GetText()
            ConfigRegistry:SetSetting(moduleName, optionName, newValue)
            self:ClearFocus()
        end)
        
        widget:SetScript("OnEscapePressed", function(self)
            self:SetText(currentValue or "")
            self:ClearFocus()
        end)
        
    elseif widgetType == "multiselect" then
        -- Create multiselect checkboxes
        widget = CreateFrame("Frame", nil, parent)
        widget:SetSize(180, 20 * #(optionInfo.options or {}))
        widget:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -10, 0)
        
        local options = optionInfo.options or {}
        local checkboxes = {}
        
        for i, option in ipairs(options) do
            local checkbox = CreateFrame("CheckButton", nil, widget, "UICheckButtonTemplate")
            checkbox:SetSize(24, 24)
            checkbox:SetPoint("TOPLEFT", widget, "TOPLEFT", 0, -20 * (i-1))
            checkbox:SetChecked(currentValue and currentValue[option])
            
            local checkboxText = checkbox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            checkboxText:SetPoint("LEFT", checkbox, "RIGHT", 2, 0)
            checkboxText:SetText(option)
            
            checkbox:SetScript("OnClick", function(self)
                -- Initialize value as table if needed
                if type(currentValue) ~= "table" then
                    currentValue = {}
                end
                
                -- Update value
                currentValue[option] = self:GetChecked()
                
                -- Save to config
                ConfigRegistry:SetSetting(moduleName, optionName, currentValue)
            end)
            
            checkboxes[i] = checkbox
        end
        
        -- Set a minimum height for the parent frame
        height = math.max(ITEM_HEIGHT, 20 * #options + 10)
        
    elseif widgetType == "header" then
        -- Create section header
        widget = CreateFrame("Frame", nil, parent)
        widget:SetSize(parent:GetWidth(), 30)
        
        local headerText = widget:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        headerText:SetPoint("TOPLEFT", widget, "TOPLEFT", 0, 0)
        headerText:SetText(optionInfo.displayName or optionName)
        headerText:SetTextColor(THEME.text.header.r, THEME.text.header.g, THEME.text.header.b, THEME.text.header.a)
        
        -- Add line below header
        local headerLine = widget:CreateTexture(nil, "ARTWORK")
        headerLine:SetHeight(1)
        headerLine:SetPoint("BOTTOMLEFT", widget, "BOTTOMLEFT", 0, 5)
        headerLine:SetPoint("BOTTOMRIGHT", widget, "BOTTOMRIGHT", 0, 5)
        headerLine:SetColorTexture(0.5, 0.5, 0.5, 0.5)
        
        height = 30
        
    elseif widgetType == "description" then
        -- Create description text
        widget = CreateFrame("Frame", nil, parent)
        widget:SetSize(parent:GetWidth() - 20, 20) -- Initial height, will adjust
        
        local descText = widget:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        descText:SetPoint("TOPLEFT", widget, "TOPLEFT", 0, 0)
        descText:SetPoint("TOPRIGHT", widget, "TOPRIGHT", 0, 0)
        descText:SetJustifyH("LEFT")
        descText:SetJustifyV("TOP")
        descText:SetText(optionInfo.text or optionInfo.displayName or "")
        descText:SetTextColor(THEME.text.normal.r, THEME.text.normal.g, THEME.text.normal.b, THEME.text.normal.a)
        
        -- Adjust height based on text
        height = descText:GetStringHeight() + 10
        widget:SetHeight(height)
    end
    
    return widget, height
end

-- Show the configuration UI
function EnhancedConfigUI:Show()
    if not initialized then
        self:Initialize()
    end
    
    mainFrame:Show()
    PlaySound(SOUNDKIT.IG_CHARACTER_INFO_OPEN)
end

-- Hide the configuration UI
function EnhancedConfigUI:Hide()
    if mainFrame then
        -- Save settings when closing
        if ConfigRegistry then
            ConfigRegistry:SaveSettings()
        end
        
        mainFrame:Hide()
        PlaySound(SOUNDKIT.IG_CHARACTER_INFO_CLOSE)
    end
end

-- Toggle the configuration UI
function EnhancedConfigUI:Toggle()
    if not initialized then
        self:Initialize()
    end
    
    if mainFrame:IsShown() then
        self:Hide()
    else
        self:Show()
    end
end

-- Open the config UI (alias for Show for compatibility)
function EnhancedConfigUI:OpenConfigUI()
    self:Show()
end

-- Close the config UI (alias for Hide for compatibility)
function EnhancedConfigUI:CloseConfigUI()
    self:Hide()
end

-- Render specific widget types
function EnhancedConfigUI:CreateCheckbox(parent, label, tooltip, value, callback)
    local checkbox = CreateFrame("CheckButton", nil, parent, "ChatConfigCheckButtonTemplate")
    checkbox:SetSize(24, 24)
    
    -- Set label
    local text = checkbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("LEFT", checkbox, "RIGHT", 2, 0)
    text:SetText(label)
    text:SetTextColor(THEME.text.normal.r, THEME.text.normal.g, THEME.text.normal.b, THEME.text.normal.a)
    
    -- Set initial value
    checkbox:SetChecked(value)
    
    -- Set callback
    checkbox:SetScript("OnClick", function(self)
        local isChecked = self:GetChecked()
        if callback then
            callback(isChecked)
        end
        PlaySound(isChecked and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
    end)
    
    -- Set tooltip
    if tooltip then
        checkbox.tooltipText = tooltip
        checkbox:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(self.tooltipText, nil, nil, nil, nil, true)
            GameTooltip:Show()
        end)
        checkbox:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end
    
    return checkbox
end

function EnhancedConfigUI:CreateSlider(parent, label, tooltip, value, min, max, step, callback)
    local sliderFrame = CreateFrame("Frame", nil, parent)
    sliderFrame:SetSize(300, 50)
    
    -- Create label
    local text = sliderFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("TOPLEFT", sliderFrame, "TOPLEFT", 0, 0)
    text:SetText(label)
    text:SetTextColor(THEME.text.normal.r, THEME.text.normal.g, THEME.text.normal.b, THEME.text.normal.a)
    
    -- Create slider
    local slider = CreateFrame("Slider", nil, sliderFrame, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", text, "BOTTOMLEFT", 0, -5)
    slider:SetSize(300, 16)
    slider:SetMinMaxValues(min, max)
    slider:SetValue(value)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)
    
    -- Set labels
    _G[slider:GetName() .. "Low"]:SetText(min)
    _G[slider:GetName() .. "High"]:SetText(max)
    _G[slider:GetName() .. "Text"]:SetText(value)
    
    -- Set callback
    slider:SetScript("OnValueChanged", function(self, newValue)
        _G[self:GetName() .. "Text"]:SetText(string.format("%.1f", newValue))
        if callback then
            callback(newValue)
        end
    end)
    
    -- Set tooltip
    if tooltip then
        slider.tooltipText = tooltip
        slider:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(self.tooltipText, nil, nil, nil, nil, true)
            GameTooltip:Show()
        end)
        slider:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end
    
    return sliderFrame
end

function EnhancedConfigUI:CreateDropdown(parent, label, tooltip, value, options, callback)
    local dropdownFrame = CreateFrame("Frame", nil, parent)
    dropdownFrame:SetSize(300, 50)
    
    -- Create label
    local text = dropdownFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("TOPLEFT", dropdownFrame, "TOPLEFT", 0, 0)
    text:SetText(label)
    text:SetTextColor(THEME.text.normal.r, THEME.text.normal.g, THEME.text.normal.b, THEME.text.normal.a)
    
    -- Create dropdown
    local dropdown = CreateFrame("Frame", "WindrunnerDropdown" .. math.random(1, 1000), dropdownFrame, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPLEFT", text, "BOTTOMLEFT", -16, -2)
    UIDropDownMenu_SetWidth(dropdown, 200)
    
    -- Initialize the dropdown menu
    UIDropDownMenu_Initialize(dropdown, function(self, level)
        local info = UIDropDownMenu_CreateInfo()
        
        for i, option in ipairs(options) do
            info.text = option.text
            info.value = option.value
            info.func = function()
                UIDropDownMenu_SetText(dropdown, option.text)
                if callback then
                    callback(option.value)
                end
            end
            info.checked = (value == option.value)
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    
    -- Set initial text
    for i, option in ipairs(options) do
        if option.value == value then
            UIDropDownMenu_SetText(dropdown, option.text)
            break
        end
    end
    
    -- Set tooltip
    if tooltip then
        dropdownFrame.tooltipText = tooltip
        dropdown:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(dropdownFrame.tooltipText, nil, nil, nil, nil, true)
            GameTooltip:Show()
        end)
        dropdown:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end
    
    return dropdownFrame
end

function EnhancedConfigUI:CreateButton(parent, label, tooltip, callback)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(150, 24)
    button:SetText(label)
    
    -- Set callback
    button:SetScript("OnClick", function()
        if callback then
            callback()
        end
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
    end)
    
    -- Set tooltip
    if tooltip then
        button.tooltipText = tooltip
        button:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(self.tooltipText, nil, nil, nil, nil, true)
            GameTooltip:Show()
        end)
        button:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end
    
    return button
end

function EnhancedConfigUI:CreateColorPicker(parent, label, tooltip, r, g, b, a, callback)
    local colorPickerFrame = CreateFrame("Frame", nil, parent)
    colorPickerFrame:SetSize(300, 30)
    
    -- Create label
    local text = colorPickerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("LEFT", colorPickerFrame, "LEFT", 0, 0)
    text:SetText(label)
    text:SetTextColor(THEME.text.normal.r, THEME.text.normal.g, THEME.text.normal.b, THEME.text.normal.a)
    
    -- Create color swatch
    local colorSwatch = CreateFrame("Button", nil, colorPickerFrame)
    colorSwatch:SetPoint("LEFT", text, "RIGHT", 10, 0)
    colorSwatch:SetSize(24, 24)
    colorSwatch:SetNormalTexture("Interface\\ChatFrame\\ChatFrameColorSwatch")
    
    -- Create color preview texture
    local texture = colorSwatch:GetNormalTexture()
    texture:SetVertexColor(r, g, b, a or 1)
    
    -- Create checkerboard background
    local background = colorSwatch:CreateTexture(nil, "BACKGROUND")
    background:SetSize(16, 16)
    background:SetPoint("CENTER")
    background:SetTexture("Tileset\\Generic\\Checkers")
    background:SetTexCoord(.25, 0, 0.5, .25)
    background:SetDesaturated(true)
    background:SetVertexColor(1, 1, 1, 0.75)
    
    -- Store color values
    colorSwatch.r, colorSwatch.g, colorSwatch.b, colorSwatch.a = r, g, b, a or 1
    
    -- Set callback
    colorSwatch:SetScript("OnClick", function(self)
        local function colorPickerCallback(restore)
            local newR, newG, newB, newA
            
            if restore then
                -- User clicked cancel, use the original color
                newR, newG, newB, newA = unpack(restore)
            else
                -- Get the new color
                newA, newR, newG, newB = OpacitySliderFrame:GetValue(), ColorPickerFrame:GetColorRGB()
            end
            
            -- Update the color swatch
            texture:SetVertexColor(newR, newG, newB, newA)
            self.r, self.g, self.b, self.a = newR, newG, newB, newA
            
            -- Call the callback with the new color
            if callback then
                callback(newR, newG, newB, newA)
            end
        end
        
        -- Store the current color for the cancel button
        local currentColor = {self.r, self.g, self.b, self.a}
        
        -- Open the color picker
        ColorPickerFrame.func = colorPickerCallback
        ColorPickerFrame.opacityFunc = colorPickerCallback
        ColorPickerFrame.cancelFunc = function() colorPickerCallback(currentColor) end
        
        -- Set initial color
        ColorPickerFrame:SetColorRGB(self.r, self.g, self.b)
        ColorPickerFrame.hasOpacity = true
        ColorPickerFrame.opacity = self.a
        
        -- Show the color picker
        ColorPickerFrame:Hide() -- Sometimes needed to fix bugs
        ColorPickerFrame:Show()
    end)
    
    -- Set tooltip
    if tooltip then
        colorSwatch.tooltipText = tooltip
        colorSwatch:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(self.tooltipText, nil, nil, nil, nil, true)
            GameTooltip:Show()
        end)
        colorSwatch:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end
    
    return colorPickerFrame
end

function EnhancedConfigUI:CreateEditBox(parent, label, tooltip, value, width, callback)
    local editBoxFrame = CreateFrame("Frame", nil, parent)
    editBoxFrame:SetSize(width or 300, 50)
    
    -- Create label
    local text = editBoxFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("TOPLEFT", editBoxFrame, "TOPLEFT", 0, 0)
    text:SetText(label)
    text:SetTextColor(THEME.text.normal.r, THEME.text.normal.g, THEME.text.normal.b, THEME.text.normal.a)
    
    -- Create edit box
    local editBox = CreateFrame("EditBox", nil, editBoxFrame, "InputBoxTemplate")
    editBox:SetPoint("TOPLEFT", text, "BOTTOMLEFT", 5, -2)
    editBox:SetSize(width or 290, 20)
    editBox:SetAutoFocus(false)
    editBox:SetText(value or "")
    
    -- Set callbacks
    editBox:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
        if callback then
            callback(self:GetText())
        end
    end)
    
    editBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
        self:SetText(value or "")
    end)
    
    -- Set tooltip
    if tooltip then
        editBox.tooltipText = tooltip
        editBox:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(self.tooltipText, nil, nil, nil, nil, true)
            GameTooltip:Show()
        end)
        editBox:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end
    
    return editBoxFrame
end

function EnhancedConfigUI:CreateHeader(parent, text)
    local headerFrame = CreateFrame("Frame", nil, parent)
    headerFrame:SetSize(parent:GetWidth() - 40, 30)
    
    -- Create header bar
    local headerBar = headerFrame:CreateTexture(nil, "BACKGROUND")
    headerBar:SetPoint("TOPLEFT", headerFrame, "TOPLEFT", 0, 0)
    headerBar:SetPoint("BOTTOMRIGHT", headerFrame, "BOTTOMRIGHT", 0, 0)
    headerBar:SetColorTexture(THEME.header.r, THEME.header.g, THEME.header.b, THEME.header.a)
    
    -- Create header text
    local headerText = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    headerText:SetPoint("LEFT", headerFrame, "LEFT", 10, 0)
    headerText:SetText(text)
    headerText:SetTextColor(THEME.text.header.r, THEME.text.header.g, THEME.text.header.b, THEME.text.header.a)
    
    -- Add a thin line at the bottom
    local bottomLine = headerFrame:CreateTexture(nil, "BACKGROUND")
    bottomLine:SetPoint("BOTTOMLEFT", headerFrame, "BOTTOMLEFT", 0, 0)
    bottomLine:SetPoint("BOTTOMRIGHT", headerFrame, "BOTTOMRIGHT", 0, 0)
    bottomLine:SetHeight(1)
    bottomLine:SetColorTexture(THEME.border.r, THEME.border.g, THEME.border.b, THEME.border.a)
    
    return headerFrame
end

function EnhancedConfigUI:CreateDivider(parent, width)
    local divider = parent:CreateTexture(nil, "BACKGROUND")
    divider:SetHeight(1)
    divider:SetWidth(width or parent:GetWidth() - 40)
    divider:SetColorTexture(THEME.border.r, THEME.border.g, THEME.border.b, 0.6)
    return divider
end

function EnhancedConfigUI:CreateSection(parent, title)
    local section = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    section:SetSize(parent:GetWidth() - 40, 30) -- Height will be adjusted dynamically
    
    -- Set backdrop
    section:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    section:SetBackdropColor(THEME.background.r + 0.05, THEME.background.g + 0.05, THEME.background.b + 0.05, 0.9)
    section:SetBackdropBorderColor(THEME.border.r, THEME.border.g, THEME.border.b, 0.8)
    
    -- Create title background
    local titleBg = section:CreateTexture(nil, "BACKGROUND")
    titleBg:SetPoint("TOPLEFT", section, "TOPLEFT", 4, -4)
    titleBg:SetPoint("TOPRIGHT", section, "TOPRIGHT", -4, -4)
    titleBg:SetHeight(20)
    titleBg:SetColorTexture(THEME.header.r, THEME.header.g, THEME.header.b, 0.7)
    
    -- Create title
    local titleText = section:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleText:SetPoint("TOPLEFT", section, "TOPLEFT", 10, -12)
    titleText:SetText(title)
    titleText:SetTextColor(THEME.text.header.r, THEME.text.header.g, THEME.text.header.b, THEME.text.header.a)
    
    -- Add a thin line below the title
    local titleLine = section:CreateTexture(nil, "BACKGROUND")
    titleLine:SetPoint("TOPLEFT", titleBg, "BOTTOMLEFT", 0, 0)
    titleLine:SetPoint("TOPRIGHT", titleBg, "BOTTOMRIGHT", 0, 0)
    titleLine:SetHeight(1)
    titleLine:SetColorTexture(THEME.border.r, THEME.border.g, THEME.border.b, 0.6)
    
    -- Store content frame and its current Y offset
    section.content = CreateFrame("Frame", nil, section)
    section.content:SetPoint("TOPLEFT", titleBg, "BOTTOMLEFT", 6, -5)
    section.content:SetPoint("TOPRIGHT", titleBg, "BOTTOMRIGHT", -6, -5)
    section.contentY = 0
    
    -- Store references
    section.titleBg = titleBg
    section.titleText = titleText
    section.titleLine = titleLine
    
    -- Function to add widgets
    function section:AddWidget(widget, leftOffset, topOffset)
        leftOffset = leftOffset or 0
        topOffset = topOffset or 0
        
        widget:SetParent(self.content)
        widget:SetPoint("TOPLEFT", self.content, "TOPLEFT", leftOffset, -(self.contentY + topOffset))
        
        -- Update content Y position
        self.contentY = self.contentY + widget:GetHeight() + 10
        
        -- Adjust section height
        self:SetHeight(self.contentY + 40)
        
        return widget
    end
    
    -- Function to add spacers
    function section:AddSpacer(height)
        self.contentY = self.contentY + (height or 10)
        self:SetHeight(self.contentY + 40)
    end
    
    -- Function to add a divider
    function section:AddDivider()
        local divider = EnhancedConfigUI:CreateDivider(self.content, self.content:GetWidth() - 10)
        divider:SetPoint("TOPLEFT", self.content, "TOPLEFT", 5, -(self.contentY + 5))
        
        -- Update content Y position
        self.contentY = self.contentY + 10
        
        -- Adjust section height
        self:SetHeight(self.contentY + 40)
        
        return divider
    end
    
    return section
end

-- Get registered settings for a module
function ConfigRegistry:GetRegisteredSettings(module)
    if not module or not settingsRegistry[module] then
        return nil
    end
    
    return settingsRegistry[module]
end

-- Reset all settings
function ConfigRegistry:ResetAllSettings()
    for module, _ in pairs(defaultSettings) do
        self:ResetSettings(module)
    end
    
    return true
end

-- Initialize the module
EnhancedConfigUI:Initialize()