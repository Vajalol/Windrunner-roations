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
local UI_WIDTH = 800
local UI_HEIGHT = 600
local PANEL_SPACING = 16
local SECTION_PADDING = 10
local ITEM_HEIGHT = 30
local ITEM_SPACING = 5
local CATEGORY_WIDTH = 180
local HEADER_HEIGHT = 40
local FOOTER_HEIGHT = 40
local SCROLLBAR_WIDTH = 16

-- UI references
local mainFrame, categoryFrame, configFrame, tabFrame
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
    background = {r = 0.1, g = 0.1, b = 0.1, a = 0.9},
    border = {r = 0.4, g = 0.4, b = 0.4, a = 0.9},
    header = {r = 0.15, g = 0.15, b = 0.15, a = 0.9},
    highlight = {r = 0.3, g = 0.5, b = 0.8, a = 1.0},
    button = {
        normal = {r = 0.2, g = 0.2, b = 0.2, a = 0.9},
        hover = {r = 0.25, g = 0.25, b = 0.25, a = 0.9},
        pushed = {r = 0.15, g = 0.15, b = 0.15, a = 0.9},
        disabled = {r = 0.1, g = 0.1, b = 0.1, a = 0.9}
    },
    text = {
        normal = {r = 1.0, g = 1.0, b = 1.0, a = 1.0},
        header = {r = 1.0, g = 0.9, b = 0.8, a = 1.0},
        disabled = {r = 0.5, g = 0.5, b = 0.5, a = 1.0},
        highlight = {r = 0.9, g = 0.8, b = 0.0, a = 1.0}
    },
    category = {
        normal = {r = 0.2, g = 0.2, b = 0.2, a = 0.8},
        selected = {r = 0.25, g = 0.35, b = 0.5, a = 0.9},
        hover = {r = 0.25, g = 0.25, b = 0.3, a = 0.9}
    },
    slider = {
        bg = {r = 0.15, g = 0.15, b = 0.15, a = 0.9},
        fill = {r = 0.3, g = 0.5, b = 0.8, a = 0.9}
    },
    checkbox = {
        bg = {r = 0.1, g = 0.1, b = 0.1, a = 0.8},
        checked = {r = 0.3, g = 0.5, b = 0.8, a = 1.0}
    }
}

local textures = {
    background = "Interface\\DialogFrame\\UI-DialogBox-Background",
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
    closeButton = "Interface\\Buttons\\UI-Panel-MinimizeButton"
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
    {name = "General", displayName = "General Settings", icon = "Interface\\Icons\\INV_Misc_Gear_01"},
    {name = "Rotations", displayName = "Rotation Settings", icon = "Interface\\Icons\\Ability_Warrior_BattleShout"},
    {name = "Class", displayName = "Class Settings", icon = "Interface\\Icons\\ClassIcon_Warrior"},
    {name = "UI", displayName = "UI Settings", icon = "Interface\\Icons\\INV_Misc_Note_06"},
    {name = "Advanced", displayName = "Advanced Settings", icon = "Interface\\Icons\\Spell_Arcane_Arcane03"}
}

-- Module category order
local MODULE_ORDER = {
    "General",
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
    "UI",
    "Performance",
    "Advanced"
}

-- Tab config filter - determine which module settings appear in which tab
local TAB_FILTERS = {
    General = {
        modules = {"General", "Performance", "Advanced"},
        categories = {"generalSettings", "performanceSettings", "advancedSettings"}
    },
    Rotations = {
        modules = {"General", "DeathKnight", "DemonHunter", "Druid", "Evoker", "Hunter", "Mage", "Monk", "Paladin", "Priest", "Rogue", "Shaman", "Warlock", "Warrior"},
        categories = {"rotationSettings"}
    },
    Class = {
        modules = {"DeathKnight", "DemonHunter", "Druid", "Evoker", "Hunter", "Mage", "Monk", "Paladin", "Priest", "Rogue", "Shaman", "Warlock", "Warrior"},
        categories = {"classSettings", "specSettings"}
    },
    UI = {
        modules = {"UI", "General"},
        categories = {"uiSettings", "interfaceSettings", "visualSettings"}
    },
    Advanced = {
        modules = {"Advanced", "Performance", "General", "UI"},
        categories = {"advancedSettings", "debugSettings", "experimentalSettings", "performanceSettings"}
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
    
    -- Add title text
    local titleText = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleText:SetPoint("TOP", mainFrame, "TOP", 0, -20)
    titleText:SetText("Windrunner Rotations Settings")
    titleText:SetTextColor(THEME.text.header.r, THEME.text.header.g, THEME.text.header.b, THEME.text.header.a)
    
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
    local _, class = UnitClass("player")
    if class and CLASS_COLORS[class] then
        local color = CLASS_COLORS[class]
        classBar:SetColorTexture(color.r, color.g, color.b, 0.9)
    else
        classBar:SetColorTexture(0.4, 0.5, 0.8, 0.9)
    end
    
    -- Store references
    self.mainFrame = mainFrame
    self.titleText = titleText
    self.closeButton = closeButton
    self.classBar = classBar
end

-- Create tab frame at the top
function EnhancedConfigUI:CreateTabFrame()
    -- Create tab frame
    tabFrame = CreateFrame("Frame", nil, mainFrame)
    tabFrame:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 20, -40)
    tabFrame:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -20, -40)
    tabFrame:SetHeight(30)
    
    -- Create tabs
    local tabWidth = (tabFrame:GetWidth() / #TABS) - 5
    
    for i, tabInfo in ipairs(TABS) do
        local tab = CreateFrame("Button", "WindrunnerRotationsTab"..i, tabFrame, "BackdropTemplate")
        tab:SetSize(tabWidth, 30)
        tab:SetPoint("TOPLEFT", tabFrame, "TOPLEFT", (i-1) * (tabWidth + 5), 0)
        
        -- Set backdrop
        tab:SetBackdrop({
            bgFile = textures.background,
            edgeFile = textures.border,
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = {left = 4, right = 4, top = 4, bottom = 4}
        })
        
        -- Set initial appearance
        if tabInfo.name == currentTab then
            tab:SetBackdropColor(THEME.category.selected.r, THEME.category.selected.g, THEME.category.selected.b, THEME.category.selected.a)
        else
            tab:SetBackdropColor(THEME.category.normal.r, THEME.category.normal.g, THEME.category.normal.b, THEME.category.normal.a)
        end
        
        -- Create tab icon
        local tabIcon = tab:CreateTexture(nil, "ARTWORK")
        tabIcon:SetSize(20, 20)
        tabIcon:SetPoint("LEFT", tab, "LEFT", 8, 0)
        tabIcon:SetTexture(tabInfo.icon)
        
        -- Create tab text
        local tabText = tab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        tabText:SetPoint("LEFT", tabIcon, "RIGHT", 5, 0)
        tabText:SetText(tabInfo.displayName)
        tabText:SetTextColor(THEME.text.normal.r, THEME.text.normal.g, THEME.text.normal.b, THEME.text.normal.a)
        
        -- Highlight on hover
        tab:SetScript("OnEnter", function(self)
            if tabInfo.name ~= currentTab then
                self:SetBackdropColor(THEME.category.hover.r, THEME.category.hover.g, THEME.category.hover.b, THEME.category.hover.a)
            end
        end)
        
        tab:SetScript("OnLeave", function(self)
            if tabInfo.name ~= currentTab then
                self:SetBackdropColor(THEME.category.normal.r, THEME.category.normal.g, THEME.category.normal.b, THEME.category.normal.a)
            end
        end)
        
        -- Handle click
        tab:SetScript("OnClick", function(self)
            -- Update tab appearance
            for j, btn in ipairs(tabButtons) do
                if TABS[j].name == tabInfo.name then
                    btn:SetBackdropColor(THEME.category.selected.r, THEME.category.selected.g, THEME.category.selected.b, THEME.category.selected.a)
                else
                    btn:SetBackdropColor(THEME.category.normal.r, THEME.category.normal.g, THEME.category.normal.b, THEME.category.normal.a)
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
        
        -- Store tab button
        tabButtons[i] = tab
    end
    
    -- Store reference
    self.tabFrame = tabFrame
end

-- Create category frame (left panel)
function EnhancedConfigUI:CreateCategoryFrame()
    -- Create the category panel
    categoryFrame = CreateFrame("Frame", nil, mainFrame, "BackdropTemplate")
    categoryFrame:SetSize(CATEGORY_WIDTH, UI_HEIGHT - HEADER_HEIGHT - FOOTER_HEIGHT - 50)
    categoryFrame:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 20, -80)
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
    
    -- Create scrollframe for categories
    categoryScrollFrame = CreateFrame("ScrollFrame", "WindrunnerRotationsCategoryScroll", categoryFrame, "UIPanelScrollFrameTemplate")
    categoryScrollFrame:SetPoint("TOPLEFT", categoryFrame, "TOPLEFT", 8, -8)
    categoryScrollFrame:SetPoint("BOTTOMRIGHT", categoryFrame, "BOTTOMRIGHT", -30, 8)
    
    -- Create scroll child
    local categoryScrollChild = CreateFrame("Frame", nil, categoryScrollFrame)
    categoryScrollChild:SetSize(CATEGORY_WIDTH - 30, 500)  -- Height will adjust as needed
    categoryScrollFrame:SetScrollChild(categoryScrollChild)
    
    -- Store references
    self.categoryFrame = categoryFrame
    self.categoryScrollFrame = categoryScrollFrame
    self.categoryScrollChild = categoryScrollChild
    
    -- Initial population
    self:RefreshCategoryFrame()
end

-- Create config frame (right panel)
function EnhancedConfigUI:CreateConfigFrame()
    -- Create the config panel
    configFrame = CreateFrame("Frame", nil, mainFrame, "BackdropTemplate")
    configFrame:SetSize(UI_WIDTH - CATEGORY_WIDTH - PANEL_SPACING - 40, UI_HEIGHT - HEADER_HEIGHT - FOOTER_HEIGHT - 50)
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
    
    -- Create title for config section
    local configTitle = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    configTitle:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 15, -15)
    configTitle:SetText("Select a category")
    configTitle:SetTextColor(THEME.text.header.r, THEME.text.header.g, THEME.text.header.b, THEME.text.header.a)
    
    -- Create description for config section
    local configDesc = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    configDesc:SetPoint("TOPLEFT", configTitle, "BOTTOMLEFT", 0, -5)
    configDesc:SetPoint("RIGHT", configFrame, "RIGHT", -15, 0)
    configDesc:SetJustifyH("LEFT")
    configDesc:SetJustifyV("TOP")
    configDesc:SetText("Select a category from the left panel to configure settings.")
    configDesc:SetTextColor(THEME.text.normal.r, THEME.text.normal.g, THEME.text.normal.b, THEME.text.normal.a)
    
    -- Create scrollframe for config options
    configScrollFrame = CreateFrame("ScrollFrame", "WindrunnerRotationsConfigScroll", configFrame, "UIPanelScrollFrameTemplate")
    configScrollFrame:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 8, -50)
    configScrollFrame:SetPoint("BOTTOMRIGHT", configFrame, "BOTTOMRIGHT", -30, 8)
    
    -- Create scroll child
    local configScrollChild = CreateFrame("Frame", nil, configScrollFrame)
    configScrollChild:SetSize(configScrollFrame:GetWidth() - SCROLLBAR_WIDTH, 800)  -- Height will adjust
    configScrollFrame:SetScrollChild(configScrollChild)
    
    -- Create reset button
    local resetButton = CreateFrame("Button", nil, configFrame, "UIPanelButtonTemplate")
    resetButton:SetSize(100, 22)
    resetButton:SetPoint("BOTTOMRIGHT", configFrame, "BOTTOMRIGHT", -15, 15)
    resetButton:SetText("Reset")
    resetButton:SetScript("OnClick", function()
        if currentModule and currentCategory then
            -- Reset settings for this module
            ConfigRegistry:ResetSettings(currentModule)
            
            -- Refresh config display
            EnhancedConfigUI:BuildConfigOptions(currentModule, currentCategory)
        end
    end)
    resetButton:Hide() -- Hide until a category is selected
    
    -- Store references
    self.configFrame = configFrame
    self.configTitle = configTitle
    self.configDesc = configDesc
    self.configScrollFrame = configScrollFrame
    self.configScrollChild = configScrollChild
    self.resetButton = resetButton
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
    
    -- Create buttons for each module
    local yOffset = 5
    for i, moduleName in ipairs(sortedModules) do
        -- Create button if it doesn't exist
        local button = CreateFrame("Button", "WindrunnerRotationsCategory"..i, self.categoryScrollChild, "BackdropTemplate")
        button:SetSize(self.categoryScrollChild:GetWidth() - 10, 30)
        button:SetPoint("TOPLEFT", self.categoryScrollChild, "TOPLEFT", 5, -yOffset)
        
        -- Set backdrop
        button:SetBackdrop({
            bgFile = textures.background,
            edgeFile = nil,
            tile = true,
            tileSize = 16,
            insets = {left = 4, right = 4, top = 4, bottom = 4}
        })
        button:SetBackdropColor(THEME.category.normal.r, THEME.category.normal.g, THEME.category.normal.b, THEME.category.normal.a)
        
        -- Create text
        local text = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("LEFT", button, "LEFT", 10, 0)
        text:SetText(moduleName)
        text:SetTextColor(THEME.text.normal.r, THEME.text.normal.g, THEME.text.normal.b, THEME.text.normal.a)
        
        -- Highlight on hover
        button:SetScript("OnEnter", function(self)
            if currentModule ~= moduleName then
                self:SetBackdropColor(THEME.category.hover.r, THEME.category.hover.g, THEME.category.hover.b, THEME.category.hover.a)
            end
        end)
        
        button:SetScript("OnLeave", function(self)
            if currentModule ~= moduleName then
                self:SetBackdropColor(THEME.category.normal.r, THEME.category.normal.g, THEME.category.normal.b, THEME.category.normal.a)
            end
        end)
        
        -- Click handler
        button:SetScript("OnClick", function(self)
            -- Update currently selected module
            currentModule = moduleName
            
            -- Reset currently selected category
            currentCategory = nil
            
            -- Update button appearances
            for _, btn in pairs(categoryButtons) do
                btn:SetBackdropColor(THEME.category.normal.r, THEME.category.normal.g, THEME.category.normal.b, THEME.category.normal.a)
            end
            self:SetBackdropColor(THEME.category.selected.r, THEME.category.selected.g, THEME.category.selected.b, THEME.category.selected.a)
            
            -- Build category buttons
            EnhancedConfigUI:BuildCategoryButtons(moduleName)
        end)
        
        -- Store the button
        categoryButtons[moduleName] = button
        
        -- Update y offset for next button
        yOffset = yOffset + 35
    end
    
    -- Update scroll child height
    self.categoryScrollChild:SetHeight(math.max(500, yOffset + 5))
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
        
        -- Highlight on hover
        button:SetScript("OnEnter", function(self)
            if currentCategory ~= categoryName then
                self:SetBackdropColor(THEME.category.hover.r, THEME.category.hover.g, THEME.category.hover.b, THEME.category.hover.a)
            end
        end)
        
        button:SetScript("OnLeave", function(self)
            if currentCategory ~= categoryName then
                self:SetBackdropColor(THEME.category.normal.r, THEME.category.normal.g, THEME.category.normal.b, THEME.category.normal.a)
            end
        end)
        
        -- Click handler
        button:SetScript("OnClick", function(self)
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
    self.configTitle:SetText(moduleName .. " - " .. self:FormatCategoryName(categoryName))
    self.configDesc:SetText("Configure settings for " .. self:FormatCategoryName(categoryName))
    
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
end

-- Hide the configuration UI
function EnhancedConfigUI:Hide()
    if mainFrame then
        mainFrame:Hide()
    end
end

-- Toggle the configuration UI
function EnhancedConfigUI:Toggle()
    if not initialized then
        self:Initialize()
    end
    
    if mainFrame:IsShown() then
        mainFrame:Hide()
    else
        mainFrame:Show()
    end
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