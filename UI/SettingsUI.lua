local addonName, WR = ...

-- SettingsUI module for advanced configuration
local SettingsUI = {}
WR.UI = WR.UI or {}
WR.UI.SettingsUI = SettingsUI

-- UI constants
local FRAME_WIDTH = 650
local FRAME_HEIGHT = 500
local TAB_HEIGHT = 30
local CATEGORY_WIDTH = 160
local CATEGORY_HEIGHT = 28
local CONTENT_PADDING = 16
local PANEL_BACKDROP = {
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
}
local PANEL_INSET_BACKDROP = {
    bgFile = "Interface\\FrameGeneral\\UI-Background-Marble",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
}

-- Frame references
local mainFrame, tabFrame, contentFrame, categoryFrame, configFrame
local tabs = {}
local categoryButtons = {}
local currentTab = 1
local currentCategory = 1
local configPanels = {}

-- Categories for each tab
local tabCategories = {
    -- General tab
    {
        { name = "General", title = "General Settings" },
        { name = "Interface", title = "Interface Settings" },
        { name = "Keybinds", title = "Key Bindings" },
        { name = "Advanced", title = "Advanced Settings" }
    },
    -- Rotation tab
    {
        { name = "General", title = "Rotation Settings" },
        { name = "Interrupts", title = "Interrupt Settings" },
        { name = "Cooldowns", title = "Cooldown Settings" },
        { name = "Defensives", title = "Defensive Settings" },
        { name = "AoE", title = "AoE Settings" }
    },
    -- Class tab
    {
        { name = "ClassGeneral", title = "Class Settings" },
        { name = "Spec1", title = "Specialization 1" },
        { name = "Spec2", title = "Specialization 2" },
        { name = "Spec3", title = "Specialization 3" },
        { name = "Spec4", title = "Specialization 4" }
    },
    -- Dungeon tab
    {
        { name = "DungeonGeneral", title = "Dungeon Settings" },
        { name = "MythicPlus", title = "Mythic+ Settings" },
        { name = "Targeting", title = "Targeting Settings" },
        { name = "Awareness", title = "Dungeon Awareness" }
    }
}

-- Initialize the Settings UI
function SettingsUI:Initialize()
    -- Create main frame
    self:CreateMainFrame()
    
    -- Create tab frame
    self:CreateTabFrame()
    
    -- Create content frame 
    self:CreateContentFrame()
    
    -- Create category frame
    self:CreateCategoryFrame()
    
    -- Create config frame
    self:CreateConfigFrame()
    
    -- Create all configuration panels
    self:CreateConfigPanels()
    
    -- Set initial state
    self:SelectTab(1)
    
    -- Hide initially
    mainFrame:Hide()
    
    WR:Debug("SettingsUI module initialized")
end

-- Create the main frame
function SettingsUI:CreateMainFrame()
    -- Create main frame
    mainFrame = CreateFrame("Frame", "WindrunnerRotationsSettingsFrame", UIParent, "BackdropTemplate")
    mainFrame:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
    mainFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    mainFrame:SetFrameStrata("HIGH")
    mainFrame:SetFrameLevel(10)
    mainFrame:SetClampedToScreen(true)
    mainFrame:SetMovable(true)
    mainFrame:EnableMouse(true)
    mainFrame:RegisterForDrag("LeftButton")
    mainFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    mainFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    
    -- Set backdrop
    mainFrame:SetBackdrop(PANEL_BACKDROP)
    
    -- Create title text
    local titleText = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleText:SetPoint("TOP", mainFrame, "TOP", 0, -16)
    titleText:SetText("Windrunner Rotations - Settings")
    
    -- Create close button
    local closeButton = CreateFrame("Button", nil, mainFrame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -5, -5)
    closeButton:SetScript("OnClick", function() mainFrame:Hide() end)
    
    -- Store references
    self.mainFrame = mainFrame
    self.titleText = titleText
    self.closeButton = closeButton
end

-- Create tab frame
function SettingsUI:CreateTabFrame()
    -- Create tab frame
    tabFrame = CreateFrame("Frame", nil, mainFrame)
    tabFrame:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 20, -35)
    tabFrame:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -20, -35)
    tabFrame:SetHeight(TAB_HEIGHT)
    
    -- Create tabs
    local tabNames = {"General", "Rotation", "Class", "Dungeon"}
    local tabWidth = (tabFrame:GetWidth() / #tabNames) - 10
    
    for i, name in ipairs(tabNames) do
        local tab = CreateFrame("Button", "WindrunnerRotationsSettingsTab"..i, tabFrame, "CharacterFrameTabButtonTemplate")
        tab:SetID(i)
        tab:SetText(name)
        tab:SetSize(tabWidth, TAB_HEIGHT)
        
        if i == 1 then
            tab:SetPoint("TOPLEFT", tabFrame, "TOPLEFT", 0, 0)
        else
            tab:SetPoint("TOPLEFT", tabs[i-1], "TOPRIGHT", -15, 0)
        end
        
        tab:SetScript("OnClick", function(self)
            SettingsUI:SelectTab(self:GetID())
            PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB)
        end)
        
        tabs[i] = tab
    end
    
    -- Store reference
    self.tabFrame = tabFrame
    self.tabs = tabs
end

-- Create content frame
function SettingsUI:CreateContentFrame()
    -- Create content frame
    contentFrame = CreateFrame("Frame", nil, mainFrame)
    contentFrame:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 20, -65)
    contentFrame:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -20, 20)
    
    -- Store reference
    self.contentFrame = contentFrame
end

-- Create category frame
function SettingsUI:CreateCategoryFrame()
    -- Create category frame
    categoryFrame = CreateFrame("Frame", nil, contentFrame, "BackdropTemplate")
    categoryFrame:SetSize(CATEGORY_WIDTH, contentFrame:GetHeight())
    categoryFrame:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 0, 0)
    categoryFrame:SetBackdrop(PANEL_INSET_BACKDROP)
    
    -- Store reference
    self.categoryFrame = categoryFrame
end

-- Create config frame
function SettingsUI:CreateConfigFrame()
    -- Create config frame
    configFrame = CreateFrame("Frame", nil, contentFrame, "BackdropTemplate")
    configFrame:SetPoint("TOPLEFT", categoryFrame, "TOPRIGHT", 5, 0)
    configFrame:SetPoint("BOTTOMRIGHT", contentFrame, "BOTTOMRIGHT", 0, 0)
    configFrame:SetBackdrop(PANEL_INSET_BACKDROP)
    
    -- Store reference
    self.configFrame = configFrame
end

-- Create configuration panels for all tabs and categories
function SettingsUI:CreateConfigPanels()
    -- Tab 1: General
    self:CreateGeneralPanels()
    
    -- Tab 2: Rotation
    self:CreateRotationPanels()
    
    -- Tab 3: Class
    self:CreateClassPanels()
    
    -- Tab 4: Dungeon
    self:CreateDungeonPanels()
end

-- Create general tab panels
function SettingsUI:CreateGeneralPanels()
    -- General Settings panel
    local generalPanel = self:CreateConfigPanel(1, 1, "General Settings")
    self:AddPanelTitle(generalPanel, "General Settings")
    
    -- Enable addon checkbox
    local enableAddon = self:CreateCheckbox(generalPanel, "Enable Addon", "general.enabled",
        "Enable or disable the entire addon", 20, -40)
    
    -- Auto-enable in dungeons checkbox
    local autoEnableDungeons = self:CreateCheckbox(generalPanel, "Auto-Enable in Dungeons", "general.autoEnableInDungeons",
        "Automatically enable the rotation when entering a dungeon", 20, -70)
    
    -- Auto-enable in raids checkbox
    local autoEnableRaids = self:CreateCheckbox(generalPanel, "Auto-Enable in Raids", "general.autoEnableInRaids",
        "Automatically enable the rotation when entering a raid", 20, -100)
    
    -- Combat only checkbox
    local combatOnly = self:CreateCheckbox(generalPanel, "Combat Only", "general.combatOnly",
        "Only run the rotation while in combat", 20, -130)
    
    -- Debug mode checkbox
    local debugMode = self:CreateCheckbox(generalPanel, "Debug Mode", "general.debugMode",
        "Enable debug messages in the chat frame", 20, -160)
    
    -- Rotation speed slider
    local rotationSpeed = self:CreateSlider(generalPanel, "Rotation Speed (ms)", "rotationSpeed",
        "Adjust how frequently the rotation checks for actions (lower = faster)", 
        20, -210, 10, 200, 10)
    
    -- Interface Settings panel
    local interfacePanel = self:CreateConfigPanel(1, 2, "Interface Settings")
    self:AddPanelTitle(interfacePanel, "Interface Settings")
    
    -- Show minimap checkbox
    local showMinimap = self:CreateCheckbox(interfacePanel, "Show Minimap Button", "general.showMinimap",
        "Show or hide the minimap button", 20, -40)
    
    -- Lock UI checkbox
    local lockUI = self:CreateCheckbox(interfacePanel, "Lock UI", "UI.locked",
        "Prevent the UI from being moved", 20, -70)
    
    -- Auto-hide in combat checkbox
    local autoHideInCombat = self:CreateCheckbox(interfacePanel, "Auto-Hide in Combat", "UI.autoHideInCombat",
        "Automatically hide the UI when entering combat", 20, -100)
    
    -- Auto-show out of combat checkbox
    local autoShowOutOfCombat = self:CreateCheckbox(interfacePanel, "Auto-Show out of Combat", "UI.autoShowOutOfCombat",
        "Automatically show the UI when leaving combat", 20, -130)
    
    -- UI scale slider
    local uiScale = self:CreateSlider(interfacePanel, "UI Scale", "UI.scale",
        "Adjust the size of the rotation UI", 
        20, -180, 0.5, 2.0, 0.05)
    
    -- UI Alpha slider
    local uiAlpha = self:CreateSlider(interfacePanel, "UI Transparency", "UI.alpha",
        "Adjust the transparency of the rotation UI", 
        20, -250, 0.1, 1.0, 0.05)
    
    -- Key Bindings panel
    local keybindsPanel = self:CreateConfigPanel(1, 3, "Key Bindings")
    self:AddPanelTitle(keybindsPanel, "Key Bindings")
    
    -- Toggle rotation binding
    local toggleBinding = self:CreateBindingButton(keybindsPanel, "Toggle Rotation", "keybinds.toggle",
        "Key to toggle the rotation on/off", 20, -40)
    
    -- Toggle AoE binding
    local aoeBinding = self:CreateBindingButton(keybindsPanel, "Toggle AoE Mode", "keybinds.aoe",
        "Key to toggle between single target and AoE mode", 20, -80)
    
    -- Toggle cooldowns binding
    local cooldownsBinding = self:CreateBindingButton(keybindsPanel, "Toggle Cooldowns", "keybinds.cooldowns",
        "Key to toggle cooldown usage on/off", 20, -120)
    
    -- Toggle interrupts binding
    local interruptsBinding = self:CreateBindingButton(keybindsPanel, "Toggle Interrupts", "keybinds.interrupts",
        "Key to toggle automatic interrupts on/off", 20, -160)
    
    -- Advanced Settings panel
    local advancedPanel = self:CreateConfigPanel(1, 4, "Advanced Settings")
    self:AddPanelTitle(advancedPanel, "Advanced Settings")
    
    -- Smart targeting checkbox
    local smartTargeting = self:CreateCheckbox(advancedPanel, "Use Smart Targeting", "general.useSmartTargeting",
        "Intelligently choose the best target based on context", 20, -40)
    
    -- Reset all settings button
    local resetButton = self:CreateButton(advancedPanel, "Reset All Settings", 
        "Reset all settings to default values", 20, -100, 200, 30)
    
    resetButton:SetScript("OnClick", function()
        StaticPopupDialogs["WR_RESET_SETTINGS"] = {
            text = "Are you sure you want to reset all settings to default?",
            button1 = "Reset",
            button2 = "Cancel",
            OnAccept = function()
                WR.Config:ResetAll()
                ReloadUI()
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3
        }
        StaticPopup_Show("WR_RESET_SETTINGS")
    end)
end

-- Create rotation tab panels
function SettingsUI:CreateRotationPanels()
    -- Rotation General panel
    local rotationGeneralPanel = self:CreateConfigPanel(2, 1, "Rotation Settings")
    self:AddPanelTitle(rotationGeneralPanel, "Rotation Settings")
    
    -- Use AoE rotation checkbox
    local useAOERotation = self:CreateCheckbox(rotationGeneralPanel, "Use AoE Rotation", "rotation.useAOERotation",
        "Use area of effect rotation when multiple enemies are present", 20, -40)
    
    -- AoE threshold slider
    local aoeThreshold = self:CreateSlider(rotationGeneralPanel, "AoE Threshold", "rotation.aoeThreshold",
        "Number of enemies required to switch to AoE rotation", 
        20, -90, 2, 10, 1)
    
    -- Save burst for bosses checkbox
    local saveBurst = self:CreateCheckbox(rotationGeneralPanel, "Save Burst for Bosses", "rotation.bursting.saveForBosses",
        "Save major cooldowns for boss encounters", 20, -150)
    
    -- Use trinkets checkbox
    local useTrinkets = self:CreateCheckbox(rotationGeneralPanel, "Use Trinkets", "rotation.bursting.useTrinkets",
        "Automatically use trinkets during burst phases", 20, -180)
    
    -- Use racials checkbox
    local useRacials = self:CreateCheckbox(rotationGeneralPanel, "Use Racial Abilities", "rotation.bursting.useRacials",
        "Automatically use racial abilities during burst phases", 20, -210)
    
    -- Interrupts panel
    local interruptsPanel = self:CreateConfigPanel(2, 2, "Interrupt Settings")
    self:AddPanelTitle(interruptsPanel, "Interrupt Settings")
    
    -- Enable interrupts checkbox
    local enableInterrupts = self:CreateCheckbox(interruptsPanel, "Enable Interrupts", "rotation.interrupt.enabled",
        "Automatically interrupt enemy spell casts", 20, -40)
    
    -- Priority only checkbox
    local priorityOnly = self:CreateCheckbox(interruptsPanel, "Priority Interrupts Only", "rotation.interrupt.priorityOnly",
        "Only interrupt high-priority spells", 20, -70)
    
    -- Random delay checkbox
    local randomDelay = self:CreateCheckbox(interruptsPanel, "Random Interrupt Delay", "rotation.interrupt.randomDelay",
        "Add a random delay before interrupting (anti-bot measure)", 20, -100)
    
    -- Interrupt delay slider
    local interruptDelay = self:CreateSlider(interruptsPanel, "Interrupt Delay (s)", "rotation.interrupt.delay",
        "Base delay before interrupting", 
        20, -150, 0, 1, 0.1)
    
    -- Min interrupt delay slider (only if random delay is enabled)
    local minInterruptDelay = self:CreateSlider(interruptsPanel, "Min Delay (s)", "rotation.interrupt.minDelay",
        "Minimum random delay before interrupting", 
        20, -210, 0, 0.5, 0.05)
    
    -- Max interrupt delay slider (only if random delay is enabled)
    local maxInterruptDelay = self:CreateSlider(interruptsPanel, "Max Delay (s)", "rotation.interrupt.maxDelay",
        "Maximum random delay before interrupting", 
        20, -270, 0.1, 1, 0.05)
    
    -- Show/hide random delay sliders based on checkbox state
    randomDelay:HookScript("OnClick", function(self)
        local checked = self:GetChecked()
        if checked then
            minInterruptDelay:Show()
            maxInterruptDelay:Show()
        else
            minInterruptDelay:Hide()
            maxInterruptDelay:Hide()
        end
    end)
    
    -- Initialize visibility
    if WR.Config:Get("rotation.interrupt.randomDelay") then
        minInterruptDelay:Show()
        maxInterruptDelay:Show()
    else
        minInterruptDelay:Hide()
        maxInterruptDelay:Hide()
    end
    
    -- Cooldowns panel
    local cooldownsPanel = self:CreateConfigPanel(2, 3, "Cooldown Settings")
    self:AddPanelTitle(cooldownsPanel, "Cooldown Settings")
    
    -- Enable cooldowns checkbox
    local enableCooldowns = self:CreateCheckbox(cooldownsPanel, "Enable Cooldowns", "rotation.bursting.enabled",
        "Automatically use cooldowns during combat", 20, -40)
    
    -- Cooldown usage dropdown
    local cooldownUsage = self:CreateDropdown(cooldownsPanel, "Cooldown Usage", "rotation.cooldownUsage",
        "When to use cooldown abilities", 20, -90, 200, 
        {
            { text = "On Cooldown", value = "onCooldown", tooltip = "Use cooldowns as soon as they are available" },
            { text = "With Burst", value = "withBurst", tooltip = "Use cooldowns together with burst abilities" },
            { text = "Boss Only", value = "bossOnly", tooltip = "Only use cooldowns on boss encounters" },
            { text = "Manual Only", value = "manualOnly", tooltip = "Only use cooldowns when manually triggered" }
        })
    
    -- Defensives panel
    local defensivesPanel = self:CreateConfigPanel(2, 4, "Defensive Settings")
    self:AddPanelTitle(defensivesPanel, "Defensive Settings")
    
    -- Enable defensives checkbox
    local enableDefensives = self:CreateCheckbox(defensivesPanel, "Enable Defensives", "rotation.defensives.enabled",
        "Automatically use defensive abilities when in danger", 20, -40)
    
    -- Auto use healthstone checkbox
    local autoUseHealthstone = self:CreateCheckbox(defensivesPanel, "Auto Use Healthstone", "rotation.defensives.autoUseHealthstone",
        "Automatically use healthstone when health is low", 20, -70)
    
    -- Healthstone threshold slider
    local healthstoneThreshold = self:CreateSlider(defensivesPanel, "Healthstone Threshold (%)", "rotation.defensives.healthstoneThreshold",
        "Health percentage to use healthstone", 
        20, -120, 10, 60, 5)
    
    -- Auto cancel channeling checkbox
    local autoCancelChanneling = self:CreateCheckbox(defensivesPanel, "Auto Cancel Channeling", "rotation.defensives.autoCancelChanneling",
        "Automatically cancel channeling to use a defensive if needed", 20, -180)
    
    -- AoE panel
    local aoePanel = self:CreateConfigPanel(2, 5, "AoE Settings")
    self:AddPanelTitle(aoePanel, "AoE Settings")
    
    -- AoE detection method dropdown
    local aoeDetection = self:CreateDropdown(aoePanel, "AoE Detection Method", "rotation.aoeDetectionMethod",
        "How to detect multiple enemies for AoE rotation", 20, -60, 200, 
        {
            { text = "Enemy Count", value = "enemyCount", tooltip = "Count visible enemies within range" },
            { text = "Dynamic", value = "dynamic", tooltip = "Dynamically adjust based on current targets and combat situation" },
            { text = "Manual Only", value = "manualOnly", tooltip = "Only use AoE rotation when manually toggled" }
        })
    
    -- Enemy count range slider
    local enemyCountRange = self:CreateSlider(aoePanel, "Detection Range (yards)", "rotation.aoeDetectionRange",
        "Maximum range to count enemies for AoE", 
        20, -130, 5, 40, 5)
    
    -- Max enemies to consider slider
    local maxEnemies = self:CreateSlider(aoePanel, "Max Enemies to Consider", "rotation.maxEnemies",
        "Maximum number of enemies to consider for rotational decisions", 
        20, -190, 3, 20, 1)
    
    -- AoE priority dropdown
    local aoePriority = self:CreateDropdown(aoePanel, "AoE Priority", "rotation.aoePriority",
        "What to prioritize during AoE situations", 20, -250, 200, 
        {
            { text = "Balanced", value = "balanced", tooltip = "Balance between AoE damage and target priority" },
            { text = "Maximum AoE", value = "maxAoe", tooltip = "Focus entirely on maximum AoE damage" },
            { text = "Priority Targets", value = "priority", tooltip = "Focus on priority targets even in AoE situations" }
        })
end

-- Create class tab panels
function SettingsUI:CreateClassPanels()
    -- Get class information
    local _, class = UnitClass("player")
    local classColor = RAID_CLASS_COLORS[class] or RAID_CLASS_COLORS["WARRIOR"]
    local specs = {}
    
    -- Get spec information
    for i = 1, GetNumSpecializations() do
        local id, name, description, icon = GetSpecializationInfo(i)
        if id then
            specs[i] = { id = id, name = name, icon = icon }
            
            -- Update tab categories with actual spec names
            tabCategories[3][i+1].title = name .. " Settings"
        end
    end
    
    -- Class General panel
    local classPanel = self:CreateConfigPanel(3, 1, class .. " Settings")
    self:AddPanelTitle(classPanel, class .. " Settings", classColor.r, classColor.g, classColor.b)
    
    -- Class-specific settings based on the player's class
    self:CreateClassSpecificSettings(classPanel, class)
    
    -- Create spec panels
    for i, spec in ipairs(specs) do
        if spec and spec.id then
            local specPanel = self:CreateConfigPanel(3, i+1, spec.name .. " Settings")
            self:AddPanelTitle(specPanel, spec.name .. " Settings", classColor.r, classColor.g, classColor.b)
            
            -- Add spec icon
            local specIcon = specPanel:CreateTexture(nil, "ARTWORK")
            specIcon:SetSize(32, 32)
            specIcon:SetPoint("TOPRIGHT", specPanel, "TOPRIGHT", -20, -20)
            specIcon:SetTexture(spec.icon)
            
            -- Create spec-specific settings
            self:CreateSpecSpecificSettings(specPanel, class, spec.id, spec.name)
        end
    end
end

-- Create class-specific settings
function SettingsUI:CreateClassSpecificSettings(panel, class)
    -- Yoffset for positioning
    local yOffset = -40
    
    if class == "WARRIOR" then
        -- Warrior settings
        self:CreateCheckbox(panel, "Use Heroic Leap", "class.useHeroicLeap",
            "Automatically use Heroic Leap for mobility", 20, yOffset)
        yOffset = yOffset - 30
        
        self:CreateCheckbox(panel, "Prioritize Rage", "class.prioritizeRage",
            "Prioritize rage generation in the rotation", 20, yOffset)
        
    elseif class == "PALADIN" then
        -- Paladin settings
        self:CreateCheckbox(panel, "Use Blessings", "class.useBlessing",
            "Automatically use Blessings on self and allies", 20, yOffset)
        yOffset = yOffset - 30
        
        self:CreateCheckbox(panel, "Use Lay on Hands", "class.useLayOnHands",
            "Automatically use Lay on Hands in emergencies", 20, yOffset)
        
    elseif class == "HUNTER" then
        -- Hunter settings
        self:CreateCheckbox(panel, "Auto Pet Summon", "class.autoPetSummon",
            "Automatically summon pet if missing", 20, yOffset)
        yOffset = yOffset - 30
        
        self:CreateCheckbox(panel, "Auto Pet Mend", "class.autoPetMend",
            "Automatically use Mend Pet when pet is injured", 20, yOffset)
        yOffset = yOffset - 30
        
        self:CreateCheckbox(panel, "Use Misdirection", "class.useMisdirection",
            "Automatically use Misdirection on tank", 20, yOffset)
        
    elseif class == "ROGUE" then
        -- Rogue settings
        self:CreateCheckbox(panel, "Use Poisons", "class.usePoisons",
            "Automatically apply poisons when missing", 20, yOffset)
        yOffset = yOffset - 30
        
        self:CreateCheckbox(panel, "Use Tricks of Trade", "class.useTricksOfTrade",
            "Automatically use Tricks of Trade on tank", 20, yOffset)
        
    elseif class == "PRIEST" then
        -- Priest settings
        self:CreateCheckbox(panel, "Use Desperate Prayer", "class.useDesperatePrayer",
            "Automatically use Desperate Prayer when low on health", 20, yOffset)
        yOffset = yOffset - 30
        
        self:CreateCheckbox(panel, "Use Fade", "class.useFade",
            "Automatically use Fade when targeted by enemies", 20, yOffset)
        
    elseif class == "DEATHKNIGHT" then
        -- Death Knight settings
        self:CreateCheckbox(panel, "Use Death Grip", "class.useDeathGrip",
            "Automatically use Death Grip on distant enemies", 20, yOffset)
        yOffset = yOffset - 30
        
        self:CreateCheckbox(panel, "Prioritize Runic Power", "class.prioritizeRunicPower",
            "Prioritize runic power generation in the rotation", 20, yOffset)
        
    elseif class == "SHAMAN" then
        -- Shaman settings
        self:CreateCheckbox(panel, "Use Earth Shield", "class.useEarthShield",
            "Automatically use Earth Shield when missing", 20, yOffset)
        yOffset = yOffset - 30
        
        self:CreateCheckbox(panel, "Use Elementals", "class.useElementals",
            "Automatically summon elementals during combat", 20, yOffset)
        
    elseif class == "MAGE" then
        -- Mage settings
        self:CreateCheckbox(panel, "Use Ice Block", "class.useIceBlock",
            "Automatically use Ice Block in emergencies", 20, yOffset)
        yOffset = yOffset - 30
        
        self:CreateCheckbox(panel, "Prioritize Procs", "class.prioritizeProcs",
            "Prioritize using abilities with active procs", 20, yOffset)
        
    elseif class == "WARLOCK" then
        -- Warlock settings
        self:CreateCheckbox(panel, "Auto Pet Summon", "class.autoPetSummon",
            "Automatically summon demon if missing", 20, yOffset)
        yOffset = yOffset - 30
        
        self:CreateCheckbox(panel, "Use Health Funnel", "class.useHealthFunnel",
            "Automatically use Health Funnel when pet is low", 20, yOffset)
        yOffset = yOffset - 30
        
        self:CreateCheckbox(panel, "Use Soulstone", "class.useSoulstone",
            "Automatically use Soulstone on tanks or healers", 20, yOffset)
        
    elseif class == "MONK" then
        -- Monk settings
        self:CreateCheckbox(panel, "Use Touch of Karma", "class.useTouchOfKarma",
            "Automatically use Touch of Karma when taking damage", 20, yOffset)
        yOffset = yOffset - 30
        
        self:CreateCheckbox(panel, "Prioritize Chi", "class.prioritizeChi",
            "Prioritize chi generation in the rotation", 20, yOffset)
        
    elseif class == "DRUID" then
        -- Druid settings
        self:CreateCheckbox(panel, "Use Shapeshift Travel", "class.useShapeshiftTravel",
            "Automatically use Travel Form when out of combat", 20, yOffset)
        yOffset = yOffset - 30
        
        self:CreateCheckbox(panel, "Use Rebirth", "class.useRebirth",
            "Automatically use Rebirth on dead party members", 20, yOffset)
        
    elseif class == "DEMONHUNTER" then
        -- Demon Hunter settings
        self:CreateCheckbox(panel, "Use Chaos Nova", "class.useChaosNova",
            "Automatically use Chaos Nova when surrounded", 20, yOffset)
        yOffset = yOffset - 30
        
        self:CreateCheckbox(panel, "Prioritize Fury", "class.prioritizeFury",
            "Prioritize fury generation in the rotation", 20, yOffset)
        
    elseif class == "EVOKER" then
        -- Evoker settings
        self:CreateCheckbox(panel, "Use Hover", "class.useHover",
            "Automatically use Hover to avoid fall damage", 20, yOffset)
        yOffset = yOffset - 30
        
        self:CreateCheckbox(panel, "Prioritize Essence", "class.prioritizeEssence",
            "Prioritize essence generation in the rotation", 20, yOffset)
    end
    
    -- Add advanced class settings section
    yOffset = yOffset - 50
    local advancedClassTitle = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    advancedClassTitle:SetPoint("TOPLEFT", panel, "TOPLEFT", 20, yOffset)
    advancedClassTitle:SetText("Advanced Class Settings")
    
    -- Add more class-specific advanced settings
    yOffset = yOffset - 30
    self:CreateCheckbox(panel, "Detailed Logging", "class.advanced.detailedLogging",
        "Enable detailed logging of class-specific events", 20, yOffset)
    
    -- Add talent build selection
    yOffset = yOffset - 50
    local talentTitle = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    talentTitle:SetPoint("TOPLEFT", panel, "TOPLEFT", 20, yOffset)
    talentTitle:SetText("Talent Build")
    
    yOffset = yOffset - 30
    self:CreateDropdown(panel, "Talent Profile", "class.talentProfile",
        "Select a talent profile for rotation recommendations", 20, yOffset, 200, 
        {
            { text = "Auto-Detect", value = "autoDetect", tooltip = "Automatically detect your current talents" },
            { text = "Recommended", value = "recommended", tooltip = "Use recommended talents for optimal rotation" },
            { text = "Custom", value = "custom", tooltip = "Use custom talent settings" }
        })
end

-- Create spec-specific settings
function SettingsUI:CreateSpecSpecificSettings(panel, class, specID, specName)
    -- Yoffset for positioning
    local yOffset = -60
    
    -- Get role for this spec (TANK, HEALER, DAMAGER)
    local role = GetSpecializationRole(GetSpecialization())
    
    -- Add basic spec rotation options
    local rotationTitle = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    rotationTitle:SetPoint("TOPLEFT", panel, "TOPLEFT", 20, yOffset)
    rotationTitle:SetText("Rotation Options")
    
    yOffset = yOffset - 30
    self:CreateDropdown(panel, "Rotation Mode", "specs." .. specID .. ".rotationMode",
        "Choose the default rotation mode for this spec", 20, yOffset, 200, 
        {
            { text = "Optimal", value = "optimal", tooltip = "Automatically adjust rotation based on situation" },
            { text = "Maximum DPS", value = "maxDps", tooltip = "Focus on maximum damage output" },
            { text = "Balanced", value = "balanced", tooltip = "Balance between damage, utility, and survivability" },
            { text = "Custom", value = "custom", tooltip = "Use custom rotation settings" }
        })
    
    -- Add role-specific settings
    yOffset = yOffset - 60
    local roleTitle = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    roleTitle:SetPoint("TOPLEFT", panel, "TOPLEFT", 20, yOffset)
    roleTitle:SetText(role .. " Settings")
    
    yOffset = yOffset - 30
    
    if role == "TANK" then
        -- Tank settings
        self:CreateCheckbox(panel, "Prioritize Threat", "specs." .. specID .. ".prioritizeThreat",
            "Prioritize threat generation over damage", 20, yOffset)
        yOffset = yOffset - 30
        
        self:CreateCheckbox(panel, "Active Mitigation", "specs." .. specID .. ".activeMitigation",
            "Automatically use active mitigation abilities", 20, yOffset)
        yOffset = yOffset - 30
        
        self:CreateSlider(panel, "Defensive Threshold (%)", "specs." .. specID .. ".defensiveThreshold",
            "Health percentage to use defensive cooldowns", 
            20, yOffset - 30, 20, 80, 5)
        
    elseif role == "HEALER" then
        -- Healer settings
        self:CreateCheckbox(panel, "DPS When Healing Not Needed", "specs." .. specID .. ".dpsWhenHealing",
            "Deal damage when healing is not needed", 20, yOffset)
        yOffset = yOffset - 30
        
        self:CreateSlider(panel, "Mana Reservation (%)", "specs." .. specID .. ".manaReservation",
            "Percentage of mana to reserve for emergencies", 
            20, yOffset - 30, 0, 50, 5)
        
    elseif role == "DAMAGER" then
        -- DPS settings
        self:CreateCheckbox(panel, "Use Movement Abilities", "specs." .. specID .. ".useMovementAbilities",
            "Automatically use movement abilities to maintain uptime", 20, yOffset)
        yOffset = yOffset - 30
        
        self:CreateCheckbox(panel, "Optimize AoE Damage", "specs." .. specID .. ".optimizeAoe",
            "Optimize rotation for area of effect damage", 20, yOffset)
        yOffset = yOffset - 30
        
        self:CreateCheckbox(panel, "Execute Priority", "specs." .. specID .. ".executePriority",
            "Prioritize execute-phase abilities", 20, yOffset)
    end
    
    -- Add spec-specific spell settings
    yOffset = yOffset - 60
    local spellsTitle = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    spellsTitle:SetPoint("TOPLEFT", panel, "TOPLEFT", 20, yOffset)
    spellsTitle:SetText("Ability Settings")
    
    -- Create scrollframe for spec abilities
    local spellScrollFrame = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    spellScrollFrame:SetPoint("TOPLEFT", spellsTitle, "BOTTOMLEFT", 0, -10)
    spellScrollFrame:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -30, 20)
    
    local spellScrollChild = CreateFrame("Frame")
    spellScrollFrame:SetScrollChild(spellScrollChild)
    spellScrollChild:SetSize(panel:GetWidth() - 40, 400) -- Taller than visible area to allow scrolling
    
    -- Would add spec-specific spell toggles here, customized for each spec
    -- This would be dynamically generated based on the class and spec
    local spellYOffset = 0
    
    -- This is a placeholder for where we would add spec-specific spell settings
    local placeholder = spellScrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    placeholder:SetPoint("TOPLEFT", spellScrollChild, "TOPLEFT", 0, spellYOffset)
    placeholder:SetText("Ability settings would be generated specifically for " .. specName)
end

-- Create dungeon tab panels
function SettingsUI:CreateDungeonPanels()
    -- Dungeon General panel
    local dungeonGeneralPanel = self:CreateConfigPanel(4, 1, "Dungeon Settings")
    self:AddPanelTitle(dungeonGeneralPanel, "Dungeon Settings")
    
    -- Enable dungeon intelligence checkbox
    local useDungeonIntelligence = self:CreateCheckbox(dungeonGeneralPanel, "Use Dungeon Intelligence", "dungeons.useDungeonIntelligence",
        "Enable advanced dungeon mechanics awareness", 20, -40)
    
    -- Auto-target priority checkbox
    local autoTargetPriority = self:CreateCheckbox(dungeonGeneralPanel, "Auto-Target Priority Enemies", "dungeons.autoTargetPriority",
        "Automatically target priority enemies in dungeons", 20, -70)
    
    -- Optimize pulls checkbox
    local optimizePulls = self:CreateCheckbox(dungeonGeneralPanel, "Optimize Pulls", "dungeons.optimizePulls",
        "Optimize rotation based on current dungeon pull", 20, -100)
    
    -- Enhance on boss encounters checkbox
    local enhanceOnBoss = self:CreateCheckbox(dungeonGeneralPanel, "Enhance on Boss Encounters", "dungeons.enhanceOnBoss",
        "Enhance rotation optimization during boss encounters", 20, -130)
    
    -- Boss awareness level dropdown
    local bossAwarenessLevel = self:CreateDropdown(dungeonGeneralPanel, "Boss Awareness Level", "dungeons.bossAwarenessLevel",
        "How detailed the boss mechanics awareness should be", 20, -180, 200, 
        {
            { text = "Basic", value = "basic", tooltip = "Basic awareness of boss abilities" },
            { text = "Standard", value = "standard", tooltip = "Standard level of boss mechanics understanding" },
            { text = "Advanced", value = "advanced", tooltip = "Advanced understanding of boss mechanics and phases" }
        })
    
    -- Mythic+ panel
    local mythicPlusPanel = self:CreateConfigPanel(4, 2, "Mythic+ Settings")
    self:AddPanelTitle(mythicPlusPanel, "Mythic+ Settings")
    
    -- Adapt to affixes checkbox
    local adaptToAffixes = self:CreateCheckbox(mythicPlusPanel, "Adapt to M+ Affixes", "dungeons.adaptToAffixes",
        "Adapt rotation based on active Mythic+ affixes", 20, -40)
    
    -- Affix-specific settings
    local affixTitle = mythicPlusPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    affixTitle:SetPoint("TOPLEFT", mythicPlusPanel, "TOPLEFT", 20, -80)
    affixTitle:SetText("Affix-Specific Settings")
    
    -- Fortified burst mode
    self:CreateCheckbox(mythicPlusPanel, "Use Burst on Trash (Fortified)", "dungeons.fortifiedBurstMode",
        "Use burst cooldowns on trash packs during Fortified weeks", 20, -110)
    
    -- Tyrannical burst mode
    self:CreateCheckbox(mythicPlusPanel, "Save Burst for Bosses (Tyrannical)", "dungeons.tyranicalBurstMode",
        "Save burst cooldowns for bosses during Tyrannical weeks", 20, -140)
    
    -- Explosive targeting
    self:CreateCheckbox(mythicPlusPanel, "Auto-target Explosive Orbs", "dungeons.explosiveTargeting",
        "Automatically target and destroy Explosive affix orbs", 20, -170)
    
    -- Necrotic kiting
    self:CreateCheckbox(mythicPlusPanel, "Kite at High Necrotic Stacks", "dungeons.necroticKiting",
        "Adjust rotation to facilitate kiting at high Necrotic stacks", 20, -200)
    
    -- Sanguine movement
    self:CreateCheckbox(mythicPlusPanel, "Avoid Sanguine Pools", "dungeons.sanguineMovement",
        "Adjust positioning to avoid Sanguine pools", 20, -230)
    
    -- Prideful burst
    self:CreateCheckbox(mythicPlusPanel, "Maximize Prideful Damage", "dungeons.pridefulBurst",
        "Optimize damage during Prideful manifestations", 20, -260)
    
    -- Targeting panel
    local targetingPanel = self:CreateConfigPanel(4, 3, "Targeting Settings")
    self:AddPanelTitle(targetingPanel, "Targeting Settings")
    
    -- Target priority dropdown
    local targetPriority = self:CreateDropdown(targetingPanel, "Target Priority", "dungeons.targetPriority",
        "How to prioritize targets in dungeons", 20, -60, 200, 
        {
            { text = "Tank's Target", value = "tankTarget", tooltip = "Prioritize the tank's current target" },
            { text = "Lowest Health", value = "lowestHealth", tooltip = "Prioritize the target with lowest health" },
            { text = "Highest Threat", value = "highestThreat", tooltip = "Prioritize the target with highest threat" },
            { text = "Priority List", value = "priorityList", tooltip = "Follow the priority target list for each dungeon" }
        })
    
    -- Auto tab targeting checkbox
    local autoTabTargeting = self:CreateCheckbox(targetingPanel, "Auto Tab Targeting", "dungeons.autoTabTargeting",
        "Automatically tab target between enemies", 20, -110)
    
    -- Auto focus casters checkbox
    local autoFocusCasters = self:CreateCheckbox(targetingPanel, "Auto Focus Casters", "dungeons.autoFocusCasters",
        "Automatically focus important enemy casters", 20, -140)
    
    -- Target threshold slider
    local targetingThreshold = self:CreateSlider(targetingPanel, "Targeting Threshold (%)", "dungeons.targetingThreshold",
        "Health percentage to switch targets", 
        20, -190, 0, 100, 5)
    
    -- Awareness panel
    local awarenessPanel = self:CreateConfigPanel(4, 4, "Dungeon Awareness")
    self:AddPanelTitle(awarenessPanel, "Dungeon Awareness")
    
    -- Route awareness checkbox
    local routeAwareness = self:CreateCheckbox(awarenessPanel, "Route Awareness", "dungeons.routeAwareness",
        "Adjust targeting based on optimal M+ routes", 20, -40)
    
    -- Prideful planning checkbox
    local pridefulPlanning = self:CreateCheckbox(awarenessPanel, "Prideful Planning", "dungeons.pridefulPlanning",
        "Adjust rotation to prepare for upcoming Prideful spawns", 20, -70)
    
    -- Pack awareness checkbox
    local packAwareness = self:CreateCheckbox(awarenessPanel, "Pack Awareness", "dungeons.packAwareness",
        "Understand enemy pack composition and adjust accordingly", 20, -100)
    
    -- Use spell avoidance checkbox
    local spellAvoidance = self:CreateCheckbox(awarenessPanel, "Spell Avoidance", "dungeons.spellAvoidance",
        "Recommend movement to avoid dangerous enemy spells", 20, -130)
    
    -- Pathing recommendation checkbox
    local pathingRecommendation = self:CreateCheckbox(awarenessPanel, "Pathing Recommendation", "dungeons.pathingRecommendation",
        "Recommend optimal pathing through dungeons", 20, -160)
    
    -- Mechanic warning level dropdown
    local mechanicWarningLevel = self:CreateDropdown(awarenessPanel, "Mechanic Warning Level", "dungeons.mechanicWarningLevel",
        "How to warn about upcoming mechanics", 20, -210, 200, 
        {
            { text = "Minimal", value = "minimal", tooltip = "Minimal notifications about mechanics" },
            { text = "Standard", value = "standard", tooltip = "Standard level of mechanic warnings" },
            { text = "Detailed", value = "detailed", tooltip = "Detailed explanations and warnings about mechanics" }
        })
    
    -- Create visualization settings
    local visualTitle = awarenessPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    visualTitle:SetPoint("TOPLEFT", awarenessPanel, "TOPLEFT", 20, -260)
    visualTitle:SetText("Visualization Settings")
    
    -- Show visual warnings checkbox
    local showVisualWarnings = self:CreateCheckbox(awarenessPanel, "Show Visual Warnings", "dungeons.showVisualWarnings",
        "Display visual warnings for dangerous mechanics", 20, -290)
    
    -- Show minimap icons checkbox
    local showMinimapIcons = self:CreateCheckbox(awarenessPanel, "Show Minimap Icons", "dungeons.showMinimapIcons",
        "Show important enemies and objectives on the minimap", 20, -320)
end

-- Helper function to create a config panel
function SettingsUI:CreateConfigPanel(tabIndex, categoryIndex, title)
    local panelName = "WindrunnerRotationsConfigPanel_" .. tabIndex .. "_" .. categoryIndex
    local panel = CreateFrame("Frame", panelName, configFrame)
    panel:SetAllPoints(configFrame)
    panel:Hide()
    
    -- Create a scrollframe for the panel content
    local scrollFrame = CreateFrame("ScrollFrame", panelName .. "ScrollFrame", panel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -10)
    scrollFrame:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -30, 10)
    
    local scrollChild = CreateFrame("Frame")
    scrollFrame:SetScrollChild(scrollChild)
    scrollChild:SetSize(panel:GetWidth() - 30, panel:GetHeight() * 1.5) -- Make taller than visible area to allow scrolling
    
    -- Store the panel
    configPanels[tabIndex] = configPanels[tabIndex] or {}
    configPanels[tabIndex][categoryIndex] = { 
        panel = panel, 
        scrollFrame = scrollFrame, 
        scrollChild = scrollChild
    }
    
    return scrollChild
end

-- Helper function to add a panel title
function SettingsUI:AddPanelTitle(panel, text, r, g, b)
    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, 0)
    title:SetText(text)
    
    if r and g and b then
        title:SetTextColor(r, g, b)
    end
    
    return title
end

-- Helper function to create a checkbox
function SettingsUI:CreateCheckbox(panel, label, settingPath, tooltip, x, y)
    local checkbox = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    checkbox:SetPoint("TOPLEFT", panel, "TOPLEFT", x, y)
    checkbox.text:SetText(label)
    checkbox.settingPath = settingPath
    checkbox.tooltipText = tooltip
    
    -- Set initial state
    local checked = self:GetSettingValue(settingPath)
    checkbox:SetChecked(checked)
    
    -- Hook scripts
    checkbox:HookScript("OnEnter", function(self)
        if self.tooltipText then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(self.tooltipText, nil, nil, nil, nil, true)
            GameTooltip:Show()
        end
    end)
    
    checkbox:HookScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    
    checkbox:SetScript("OnClick", function(self)
        local checked = self:GetChecked()
        SettingsUI:SetSettingValue(self.settingPath, checked)
    end)
    
    return checkbox
end

-- Helper function to create a slider
function SettingsUI:CreateSlider(panel, label, settingPath, tooltip, x, y, min, max, step)
    -- Create label
    local labelText = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    labelText:SetPoint("TOPLEFT", panel, "TOPLEFT", x, y)
    labelText:SetText(label)
    
    -- Create slider
    local slider = CreateFrame("Slider", nil, panel, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", labelText, "BOTTOMLEFT", 0, -10)
    slider:SetWidth(240)
    slider:SetHeight(16)
    slider:SetMinMaxValues(min, max)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)
    slider.settingPath = settingPath
    slider.tooltipText = tooltip
    
    -- Set labels
    _G[slider:GetName() .. "Low"]:SetText(min)
    _G[slider:GetName() .. "High"]:SetText(max)
    
    -- Set initial value
    local value = self:GetSettingValue(settingPath) or (min + (max - min) / 2)
    slider:SetValue(value)
    _G[slider:GetName() .. "Text"]:SetText(value)
    
    -- Hook scripts
    slider:HookScript("OnEnter", function(self)
        if self.tooltipText then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(self.tooltipText, nil, nil, nil, nil, true)
            GameTooltip:Show()
        end
    end)
    
    slider:HookScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    
    slider:SetScript("OnValueChanged", function(self, value)
        -- Round to step precision
        value = math.floor(value / step + 0.5) * step
        if step < 1 then
            -- Format to appropriate decimal places
            local decimals = math.max(0, -math.floor(math.log10(step)))
            local format = "%." .. decimals .. "f"
            _G[self:GetName() .. "Text"]:SetText(string.format(format, value))
        else
            _G[self:GetName() .. "Text"]:SetText(math.floor(value + 0.5))
        end
        SettingsUI:SetSettingValue(self.settingPath, value)
    end)
    
    return slider
end

-- Helper function to create a dropdown
function SettingsUI:CreateDropdown(panel, label, settingPath, tooltip, x, y, width, options)
    -- Create label
    local labelText = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    labelText:SetPoint("TOPLEFT", panel, "TOPLEFT", x, y)
    labelText:SetText(label)
    
    -- Create dropdown
    local dropdown = CreateFrame("Frame", nil, panel, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPLEFT", labelText, "BOTTOMLEFT", -15, -5)
    UIDropDownMenu_SetWidth(dropdown, width)
    dropdown.settingPath = settingPath
    dropdown.tooltipText = tooltip
    dropdown.options = options
    
    -- Set initial value
    local value = self:GetSettingValue(settingPath) or (options[1] and options[1].value)
    local displayText = value
    
    -- Find display text from options
    for _, option in ipairs(options) do
        if option.value == value then
            displayText = option.text
            break
        end
    end
    
    UIDropDownMenu_SetText(dropdown, displayText)
    
    -- Initialize dropdown menu
    UIDropDownMenu_Initialize(dropdown, function(self, level)
        local info = UIDropDownMenu_CreateInfo()
        
        for _, option in ipairs(self.options) do
            info.text = option.text
            info.value = option.value
            info.tooltipTitle = option.text
            info.tooltipText = option.tooltip
            info.checked = (option.value == SettingsUI:GetSettingValue(self.settingPath))
            info.func = function(entry)
                UIDropDownMenu_SetText(self, entry.text)
                SettingsUI:SetSettingValue(self.settingPath, entry.value)
                CloseDropDownMenus()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    
    -- Hook scripts
    dropdown:HookScript("OnEnter", function(self)
        if self.tooltipText then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(self.tooltipText, nil, nil, nil, nil, true)
            GameTooltip:Show()
        end
    end)
    
    dropdown:HookScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    
    return dropdown
end

-- Helper function to create a button
function SettingsUI:CreateButton(panel, text, tooltip, x, y, width, height)
    local button = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    button:SetPoint("TOPLEFT", panel, "TOPLEFT", x, y)
    button:SetSize(width, height)
    button:SetText(text)
    button.tooltipText = tooltip
    
    -- Hook scripts
    button:HookScript("OnEnter", function(self)
        if self.tooltipText then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(self.tooltipText, nil, nil, nil, nil, true)
            GameTooltip:Show()
        end
    end)
    
    button:HookScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    
    return button
end

-- Helper function to create a keybinding button
function SettingsUI:CreateBindingButton(panel, label, settingPath, tooltip, x, y)
    -- Create label
    local labelText = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    labelText:SetPoint("TOPLEFT", panel, "TOPLEFT", x, y)
    labelText:SetText(label)
    
    -- Create binding button
    local button = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    button:SetPoint("TOPLEFT", labelText, "TOPRIGHT", 30, 0)
    button:SetSize(140, 22)
    button:SetText(self:GetSettingValue(settingPath) or "Not Bound")
    button.settingPath = settingPath
    button.tooltipText = tooltip
    button.waiting = false
    
    -- Hook scripts
    button:HookScript("OnEnter", function(self)
        if self.tooltipText and not self.waiting then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(self.tooltipText, nil, nil, nil, nil, true)
            GameTooltip:Show()
        end
    end)
    
    button:HookScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    
    button:SetScript("OnClick", function(self)
        if self.waiting then return end
        
        self.waiting = true
        self:SetText("Press a key...")
        self:EnableKeyboard(true)
        
        -- Show tooltip with instructions
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Press a key to bind, or ESC to cancel", nil, nil, nil, nil, true)
        GameTooltip:Show()
        
        self:SetScript("OnKeyDown", function(self, key)
            self:EnableKeyboard(false)
            self.waiting = false
            
            -- Escape cancels binding
            if key == "ESCAPE" then
                self:SetText(SettingsUI:GetSettingValue(self.settingPath) or "Not Bound")
                GameTooltip:Hide()
                self:SetScript("OnKeyDown", nil)
                return
            end
            
            -- Set binding
            SettingsUI:SetSettingValue(self.settingPath, key)
            self:SetText(key)
            GameTooltip:Hide()
            self:SetScript("OnKeyDown", nil)
        end)
    end)
    
    return button
end

-- Get a setting value from the config
function SettingsUI:GetSettingValue(path)
    if not path then return nil end
    
    -- Parse the path
    local parts = {}
    for part in string.gmatch(path, "([^%.]+)") do
        table.insert(parts, part)
    end
    
    -- Navigate to the setting
    local currentTable = WR.Config:GetAll()
    
    for i = 1, #parts - 1 do
        currentTable = currentTable[parts[i]]
        if not currentTable then return nil end
    end
    
    -- Return the value
    return currentTable[parts[#parts]]
end

-- Set a setting value in the config
function SettingsUI:SetSettingValue(path, value)
    if not path then return end
    
    -- Split the path into parts
    local parts = {}
    for part in string.gmatch(path, "([^%.]+)") do
        table.insert(parts, part)
    end
    
    if #parts == 1 then
        -- Top level setting
        WR.Config:Set(parts[1], value)
    elseif #parts == 2 then
        -- Two level setting
        WR.Config:Set(parts[1], value, parts[2])
    else
        -- Deep nested setting
        -- This could be enhanced to handle any depth
        WR.Config:Set(parts[1], value, table.concat(parts, ".", 2))
    end
    
    -- Notify modules of setting change
    if WR.Events then
        WR.Events:TriggerEvent("SETTINGS_CHANGED", path, value)
    end
end

-- Select a tab
function SettingsUI:SelectTab(index)
    if not index or not tabs[index] then return end
    
    -- Hide all category buttons
    for _, button in pairs(categoryButtons) do
        button:Hide()
    end
    
    -- Hide all panels
    for tab, categories in pairs(configPanels) do
        for _, panelData in pairs(categories) do
            panelData.panel:Hide()
        end
    end
    
    -- Deselect all tabs
    for i, tab in ipairs(tabs) do
        if i == index then
            PanelTemplates_SelectTab(tab)
        else
            PanelTemplates_DeselectTab(tab)
        end
    end
    
    -- Create category buttons for this tab
    self:CreateCategoryButtons(index)
    
    -- Show first category panel
    if configPanels[index] and configPanels[index][1] then
        configPanels[index][1].panel:Show()
    end
    
    -- Update current tab
    currentTab = index
    currentCategory = 1
end

-- Create category buttons for the selected tab
function SettingsUI:CreateCategoryButtons(tabIndex)
    local categories = tabCategories[tabIndex]
    if not categories then return end
    
    -- Clear existing buttons
    categoryButtons = {}
    
    for i, category in ipairs(categories) do
        local button = CreateFrame("Button", "WindrunnerRotationsCategoryButton"..i, categoryFrame)
        button:SetSize(CATEGORY_WIDTH - 20, CATEGORY_HEIGHT)
        button:SetPoint("TOPLEFT", categoryFrame, "TOPLEFT", 10, -10 - (i-1) * (CATEGORY_HEIGHT + 5))
        button:SetScript("OnClick", function()
            SettingsUI:SelectCategory(tabIndex, i)
        end)
        
        -- Button text
        local text = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("LEFT", button, "LEFT", 10, 0)
        text:SetText(category.name)
        
        -- Button highlight
        button:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
        
        -- Select first category by default
        if i == 1 then
            button:LockHighlight()
        end
        
        categoryButtons[i] = button
    end
end

-- Select a category
function SettingsUI:SelectCategory(tabIndex, categoryIndex)
    if not tabIndex or not categoryIndex then return end
    if not configPanels[tabIndex] or not configPanels[tabIndex][categoryIndex] then return end
    
    -- Hide all panels
    for tab, categories in pairs(configPanels) do
        for _, panelData in pairs(categories) do
            panelData.panel:Hide()
        end
    end
    
    -- Show selected panel
    configPanels[tabIndex][categoryIndex].panel:Show()
    
    -- Update button highlights
    for i, button in pairs(categoryButtons) do
        if i == categoryIndex then
            button:LockHighlight()
        else
            button:UnlockHighlight()
        end
    end
    
    -- Update current category
    currentCategory = categoryIndex
end

-- Show the settings UI
function SettingsUI:Show()
    mainFrame:Show()
    self:SelectTab(currentTab)
    self:SelectCategory(currentTab, currentCategory)
end

-- Hide the settings UI
function SettingsUI:Hide()
    mainFrame:Hide()
end

-- Toggle the settings UI
function SettingsUI:Toggle()
    if mainFrame:IsShown() then
        self:Hide()
    else
        self:Show()
    end
end

-- Initialize the module
SettingsUI:Initialize()

return SettingsUI