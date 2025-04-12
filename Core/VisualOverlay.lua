------------------------------------------
-- WindrunnerRotations - Visual Overlay System
-- Author: VortexQ8
-- The War Within Season 2
------------------------------------------

local addonName, WR = ...
local VisualOverlay = {}
WR.VisualOverlay = VisualOverlay

-- Dependencies
local API = WR.API
local ConfigRegistry = WR.ConfigRegistry

-- Frame references
local mainFrame = nil
local abilityIcons = {}
local cooldownText = {}
local resourceBars = {}
local statusTexts = {}
local notificationFrame = nil
local rotationModeText = nil
local performanceDisplay = nil

-- Constants
local MAX_ABILITY_DISPLAY = 6
local UPDATE_INTERVAL = 0.03
local FADE_DURATION = 0.5
local NOTIFICATION_DURATION = 3
local ICON_SIZE = 40
local ICON_SPACING = 5
local BAR_HEIGHT = 15
local BACKDROP = {
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
}

-- State tracking
local isOverlayShown = false
local currentRecommendedSpells = {}
local currentResourceValues = {}
local pendingNotifications = {}
local currentRotationMode = "auto"
local lastGCDTime = 0
local isLocked = true
local colorTable = {}

-- Initialize the Visual Overlay System
function VisualOverlay:Initialize()
    -- Register settings
    self:RegisterSettings()
    
    -- Create frames
    self:CreateFrames()
    
    -- Register for events
    API.RegisterEvent("PLAYER_ENTERING_WORLD", function()
        self:UpdateOverlayVisibility()
    end)
    
    API.RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", function()
        self:UpdateOverlayVisibility()
        self:RefreshLayout()
    end)
    
    -- Register slash command
    SLASH_WROVERLAY1 = "/wroverlay"
    SlashCmdList["WROVERLAY"] = function(msg)
        self:HandleSlashCommand(msg)
    end
    
    -- Start update timer
    self:StartUpdateTimer()
    
    -- Initialize colors
    self:InitializeColors()
    
    API.PrintDebug("Visual Overlay system initialized")
    return true
end

-- Register settings for the Visual Overlay
function VisualOverlay:RegisterSettings()
    ConfigRegistry:RegisterSettings("VisualOverlay", {
        generalSettings = {
            enableOverlay = {
                displayName = "Enable Visual Overlay",
                description = "Enable the visual overlay system",
                type = "toggle",
                default = true
            },
            showOnlyInCombat = {
                displayName = "Show Only in Combat",
                description = "Show the overlay only when in combat",
                type = "toggle",
                default = false
            },
            lockOverlay = {
                displayName = "Lock Overlay",
                description = "Lock the overlay position",
                type = "toggle",
                default = true
            },
            scale = {
                displayName = "Overlay Scale",
                description = "Scale of the overlay",
                type = "slider",
                min = 0.5,
                max = 2.0,
                step = 0.1,
                default = 1.0
            }
        },
        abilityDisplay = {
            showRecommendedAbilities = {
                displayName = "Show Recommended Abilities",
                description = "Show icons for recommended abilities",
                type = "toggle",
                default = true
            },
            maxAbilities = {
                displayName = "Maximum Abilities",
                description = "Maximum number of recommended abilities to show",
                type = "slider",
                min = 1,
                max = 8,
                step = 1,
                default = 4
            },
            iconSize = {
                displayName = "Icon Size",
                description = "Size of ability icons",
                type = "slider",
                min = 20,
                max = 80,
                step = 5,
                default = 40
            },
            showCooldownText = {
                displayName = "Show Cooldown Text",
                description = "Show numerical cooldown values on icons",
                type = "toggle",
                default = true
            },
            showGCD = {
                displayName = "Show GCD",
                description = "Show GCD indicator",
                type = "toggle",
                default = true
            },
            horizontalAlignment = {
                displayName = "Horizontal Alignment",
                description = "Horizontal alignment of ability icons",
                type = "dropdown",
                options = { "left", "center", "right" },
                default = "center"
            },
            verticalAlignment = {
                displayName = "Vertical Alignment",
                description = "Vertical alignment of ability icons",
                type = "dropdown",
                options = { "top", "middle", "bottom" },
                default = "middle"
            }
        },
        resourceDisplay = {
            showResourceBars = {
                displayName = "Show Resource Bars",
                description = "Show bars for resources like mana, energy, rage, etc.",
                type = "toggle",
                default = true
            },
            barWidth = {
                displayName = "Bar Width",
                description = "Width of resource bars",
                type = "slider",
                min = 50,
                max = 300,
                step = 10,
                default = 150
            },
            barHeight = {
                displayName = "Bar Height",
                description = "Height of resource bars",
                type = "slider",
                min = 5,
                max = 30,
                step = 1,
                default = 15
            },
            showText = {
                displayName = "Show Text",
                description = "Show numerical values on resource bars",
                type = "toggle",
                default = true
            },
            usePrimaryResourceOnly = {
                displayName = "Primary Resource Only",
                description = "Show only the primary resource for the current spec",
                type = "toggle",
                default = false
            }
        },
        statusDisplay = {
            showRotationStatus = {
                displayName = "Show Rotation Status",
                description = "Show current rotation status (enabled/disabled)",
                type = "toggle",
                default = true
            },
            showRotationMode = {
                displayName = "Show Rotation Mode",
                description = "Show current rotation mode (auto, AoE, ST)",
                type = "toggle",
                default = true
            },
            showPerformanceMetrics = {
                displayName = "Show Performance Metrics",
                description = "Show performance metrics like DPS/HPS",
                type = "toggle",
                default = true
            },
            textSize = {
                displayName = "Text Size",
                description = "Size of status text",
                type = "slider",
                min = 8,
                max = 18,
                step = 1,
                default = 12
            }
        },
        notifications = {
            enableNotifications = {
                displayName = "Enable Notifications",
                description = "Enable notification messages",
                type = "toggle",
                default = true
            },
            duration = {
                displayName = "Duration",
                description = "Duration of notifications in seconds",
                type = "slider",
                min = 1,
                max = 10,
                step = 1,
                default = 3
            },
            fontSize = {
                displayName = "Font Size",
                description = "Font size for notifications",
                type = "slider",
                min = 10,
                max = 24,
                step = 1,
                default = 16
            },
            showImportant = {
                displayName = "Show Important Only",
                description = "Show only important notifications",
                type = "toggle",
                default = false
            }
        },
        appearance = {
            backgroundColor = {
                displayName = "Background Color",
                description = "Background color of the overlay",
                type = "color",
                default = { r = 0, g = 0, b = 0, a = 0.5 }
            },
            borderColor = {
                displayName = "Border Color",
                description = "Border color of the overlay",
                type = "color",
                default = { r = 0.5, g = 0.5, b = 0.5, a = 0.7 }
            },
            textColor = {
                displayName = "Text Color",
                description = "Default text color",
                type = "color",
                default = { r = 1, g = 1, b = 1, a = 1 }
            },
            useClassColors = {
                displayName = "Use Class Colors",
                description = "Use class colors for elements",
                type = "toggle",
                default = true
            }
        }
    })
end

-- Initialize color tables
function VisualOverlay:InitializeColors()
    -- Class colors
    colorTable = {
        DEATHKNIGHT = { r = 0.77, g = 0.12, b = 0.23 },
        DEMONHUNTER = { r = 0.64, g = 0.19, b = 0.79 },
        DRUID = { r = 1.00, g = 0.49, b = 0.04 },
        EVOKER = { r = 0.20, g = 0.58, b = 0.50 },
        HUNTER = { r = 0.67, g = 0.83, b = 0.45 },
        MAGE = { r = 0.41, g = 0.80, b = 0.94 },
        MONK = { r = 0.00, g = 1.00, b = 0.59 },
        PALADIN = { r = 0.96, g = 0.55, b = 0.73 },
        PRIEST = { r = 1.00, g = 1.00, b = 1.00 },
        ROGUE = { r = 1.00, g = 0.96, b = 0.41 },
        SHAMAN = { r = 0.00, g = 0.44, b = 0.87 },
        WARLOCK = { r = 0.58, g = 0.51, b = 0.79 },
        WARRIOR = { r = 0.78, g = 0.61, b = 0.43 }
    }
    
    -- Resource colors
    colorTable.resources = {
        mana = { r = 0.25, g = 0.50, b = 1.00 },
        rage = { r = 1.00, g = 0.00, b = 0.00 },
        focus = { r = 0.65, g = 0.63, b = 0.35 },
        energy = { r = 1.00, g = 1.00, b = 0.00 },
        runic = { r = 0.00, g = 0.82, b = 1.00 },
        combo_points = { r = 1.00, g = 0.82, b = 0.00 },
        soul_shards = { r = 0.50, g = 0.32, b = 0.55 },
        holy_power = { r = 0.95, g = 0.90, b = 0.60 },
        astral_power = { r = 0.00, g = 0.44, b = 0.87 },
        essence = { r = 0.00, g = 0.80, b = 0.60 },
        chi = { r = 0.71, g = 1.00, b = 0.92 }
    }
    
    -- Status colors
    colorTable.status = {
        enabled = { r = 0.00, g = 1.00, b = 0.00 },
        disabled = { r = 1.00, g = 0.00, b = 0.00 },
        warning = { r = 1.00, g = 0.60, b = 0.00 },
        normal = { r = 1.00, g = 1.00, b = 1.00 }
    }
    
    -- Notification types
    colorTable.notifications = {
        normal = { r = 1.00, g = 1.00, b = 1.00 },
        warning = { r = 1.00, g = 0.60, b = 0.00 },
        error = { r = 1.00, g = 0.00, b = 0.00 },
        success = { r = 0.00, g = 1.00, b = 0.00 },
        cooldown = { r = 0.00, g = 0.70, b = 1.00 }
    }
end

-- Create the UI frames
function VisualOverlay:CreateFrames()
    -- Create main frame
    mainFrame = CreateFrame("Frame", "WindrunnerRotationsOverlay", UIParent, "BackdropTemplate")
    mainFrame:SetFrameStrata("MEDIUM")
    mainFrame:SetPoint("CENTER", 0, 0)
    mainFrame:SetSize(300, 200)
    mainFrame:SetBackdrop(BACKDROP)
    mainFrame:SetBackdropColor(0, 0, 0, 0.5)
    mainFrame:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.7)
    mainFrame:EnableMouse(true)
    mainFrame:SetMovable(true)
    mainFrame:RegisterForDrag("LeftButton")
    mainFrame:SetScript("OnDragStart", function(self)
        if not isLocked then
            self:StartMoving()
        end
    end)
    mainFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        self:SetUserPlaced(true)
    end)
    mainFrame:SetClampedToScreen(true)
    
    -- Create title bar
    local titleBar = CreateFrame("Frame", nil, mainFrame)
    titleBar:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 0, 0)
    titleBar:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", 0, 0)
    titleBar:SetHeight(20)
    
    local titleText = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    titleText:SetPoint("CENTER", titleBar, "CENTER", 0, 0)
    titleText:SetText("WindrunnerRotations")
    
    -- Create ability icons
    for i = 1, MAX_ABILITY_DISPLAY do
        local frame = CreateFrame("Frame", "WindrunnerAbilityIcon" .. i, mainFrame)
        frame:SetSize(ICON_SIZE, ICON_SIZE)
        
        local icon = frame:CreateTexture(nil, "ARTWORK")
        icon:SetAllPoints(frame)
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) -- Trim icon borders
        
        local cooldown = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate")
        cooldown:SetAllPoints(frame)
        cooldown:SetDrawEdge(false)
        cooldown:SetDrawBling(false)
        
        local cdText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        cdText:SetPoint("CENTER", frame, "CENTER", 0, 0)
        
        -- Shadow effect for better visibility
        local shadow = frame:CreateTexture(nil, "BACKGROUND")
        shadow:SetAllPoints(frame)
        shadow:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
        shadow:SetVertexColor(0, 0, 0, 0.5)
        
        -- Border for current ability
        local border = frame:CreateTexture(nil, "OVERLAY")
        border:SetPoint("TOPLEFT", frame, "TOPLEFT", -2, 2)
        border:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 2, -2)
        border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
        border:SetBlendMode("ADD")
        border:SetAlpha(0)
        
        -- Store references
        abilityIcons[i] = {
            frame = frame,
            icon = icon,
            cooldown = cooldown,
            cdText = cdText,
            shadow = shadow,
            border = border,
            spellID = nil
        }
        
        -- Hide initially
        frame:Hide()
    end
    
    -- Create resource bars
    local resourceTypes = { "primary", "secondary", "extra1", "extra2" }
    for i, resourceType in ipairs(resourceTypes) do
        local frame = CreateFrame("Frame", "WindrunnerResourceBar" .. resourceType, mainFrame)
        frame:SetSize(150, BAR_HEIGHT)
        
        local bg = frame:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(frame)
        bg:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
        bg:SetVertexColor(0.3, 0.3, 0.3, 0.8)
        
        local bar = frame:CreateTexture(nil, "ARTWORK")
        bar:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
        bar:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
        bar:SetWidth(0) -- Will be updated
        bar:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
        bar:SetVertexColor(1, 1, 1, 1) -- Will be updated
        
        local text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        text:SetPoint("CENTER", frame, "CENTER", 0, 0)
        
        resourceBars[resourceType] = {
            frame = frame,
            bg = bg,
            bar = bar,
            text = text,
            resourceType = nil, -- Will be set based on class/spec
            max = 100,
            current = 0
        }
        
        -- Hide initially
        frame:Hide()
    end
    
    -- Create status texts
    local statusTypes = { "rotationStatus", "rotationMode", "performance" }
    for i, statusType in ipairs(statusTypes) do
        local text = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        
        statusTexts[statusType] = {
            text = text,
            value = ""
        }
    end
    
    -- Position status texts
    statusTexts.rotationStatus.text:SetPoint("BOTTOMLEFT", mainFrame, "BOTTOMLEFT", 10, 10)
    statusTexts.rotationMode.text:SetPoint("BOTTOM", mainFrame, "BOTTOM", 0, 10)
    statusTexts.performance.text:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -10, 10)
    
    -- Create notification frame
    notificationFrame = CreateFrame("Frame", "WindrunnerNotificationFrame", UIParent)
    notificationFrame:SetPoint("TOP", 0, -100)
    notificationFrame:SetSize(400, 30)
    notificationFrame:SetFrameStrata("HIGH")
    
    local notificationText = notificationFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    notificationText:SetPoint("CENTER", notificationFrame, "CENTER", 0, 0)
    notificationFrame.text = notificationText
    
    -- Hide initially
    notificationFrame:Hide()
    
    -- Set initial visibility
    self:UpdateOverlayVisibility()
end

-- Start the update timer
function VisualOverlay:StartUpdateTimer()
    local elapsed = 0
    mainFrame:SetScript("OnUpdate", function(self, elap)
        elapsed = elapsed + elap
        
        if elapsed >= UPDATE_INTERVAL then
            VisualOverlay:OnUpdate(elapsed)
            elapsed = 0
        end
    end)
end

-- Update function
function VisualOverlay:OnUpdate(elapsed)
    -- Skip if not shown
    if not isOverlayShown then
        return
    end
    
    -- Update ability icons
    self:UpdateAbilityIcons()
    
    -- Update resource bars
    self:UpdateResourceBars()
    
    -- Update status texts
    self:UpdateStatusTexts()
    
    -- Process pending notifications
    self:ProcessNotifications()
end

-- Update ability icons
function VisualOverlay:UpdateAbilityIcons()
    local settings = ConfigRegistry:GetSettings("VisualOverlay")
    if not settings.abilityDisplay.showRecommendedAbilities then
        for i = 1, MAX_ABILITY_DISPLAY do
            abilityIcons[i].frame:Hide()
        end
        return
    end
    
    local maxAbilities = math.min(settings.abilityDisplay.maxAbilities, MAX_ABILITY_DISPLAY)
    
    for i = 1, maxAbilities do
        local icon = abilityIcons[i]
        
        if i <= #currentRecommendedSpells then
            local spell = currentRecommendedSpells[i]
            
            -- Update the icon if spell changed
            if icon.spellID ~= spell.id then
                local texture = GetSpellTexture(spell.id)
                icon.icon:SetTexture(texture)
                icon.spellID = spell.id
            end
            
            -- Update cooldown
            if spell.cooldown and spell.cooldown > 0 then
                icon.cooldown:SetCooldown(GetTime() - spell.cooldown, spell.duration or 0)
                
                if settings.abilityDisplay.showCooldownText then
                    icon.cdText:SetText(math.ceil(spell.cooldown))
                    icon.cdText:Show()
                else
                    icon.cdText:Hide()
                end
            else
                icon.cooldown:Clear()
                icon.cdText:Hide()
            end
            
            -- Handle GCD
            if settings.abilityDisplay.showGCD and API.GetGlobalCooldown() > 0 then
                if i == 1 then -- Only show on first ability
                    lastGCDTime = GetTime()
                    icon.cooldown:SetCooldown(lastGCDTime, API.GetGlobalCooldown())
                end
            end
            
            -- Update border for primary ability
            if i == 1 then
                icon.border:SetAlpha(1)
            else
                icon.border:SetAlpha(0)
            end
            
            icon.frame:Show()
        else
            icon.frame:Hide()
        end
    end
    
    -- Position the icons
    self:PositionAbilityIcons()
end

-- Position ability icons based on settings
function VisualOverlay:PositionAbilityIcons()
    local settings = ConfigRegistry:GetSettings("VisualOverlay")
    local maxAbilities = math.min(settings.abilityDisplay.maxAbilities, MAX_ABILITY_DISPLAY)
    local iconSize = settings.abilityDisplay.iconSize
    local spacing = ICON_SPACING
    
    -- Update size
    for i = 1, maxAbilities do
        abilityIcons[i].frame:SetSize(iconSize, iconSize)
    end
    
    -- Calculate total width
    local totalWidth = (maxAbilities * iconSize) + ((maxAbilities - 1) * spacing)
    
    -- Set positions based on alignment
    local xOffset = 0
    local yOffset = 0
    
    if settings.abilityDisplay.horizontalAlignment == "left" then
        xOffset = 10
    elseif settings.abilityDisplay.horizontalAlignment == "center" then
        xOffset = (mainFrame:GetWidth() - totalWidth) / 2
    elseif settings.abilityDisplay.horizontalAlignment == "right" then
        xOffset = mainFrame:GetWidth() - totalWidth - 10
    end
    
    if settings.abilityDisplay.verticalAlignment == "top" then
        yOffset = -30 -- Below title bar
    elseif settings.abilityDisplay.verticalAlignment == "middle" then
        yOffset = -((mainFrame:GetHeight() - 40) / 2) -- Center of frame minus title bar
    elseif settings.abilityDisplay.verticalAlignment == "bottom" then
        yOffset = -(mainFrame:GetHeight() - 40 - iconSize) -- Bottom of frame with padding
    end
    
    -- Position each icon
    for i = 1, maxAbilities do
        local xPos = xOffset + ((i - 1) * (iconSize + spacing))
        abilityIcons[i].frame:ClearAllPoints()
        abilityIcons[i].frame:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", xPos, yOffset)
    end
end

-- Update resource bars
function VisualOverlay:UpdateResourceBars()
    local settings = ConfigRegistry:GetSettings("VisualOverlay")
    if not settings.resourceDisplay.showResourceBars then
        for _, bar in pairs(resourceBars) do
            bar.frame:Hide()
        end
        return
    end
    
    -- Check which resources to show based on class/spec
    local classID = API.GetPlayerClassID()
    local specID = API.GetActiveSpecID()
    
    if not classID or not specID then
        return
    end
    
    -- Update resource values
    self:UpdateResourceValues()
    
    -- Show/update appropriate resource bars
    local barCount = 0
    
    -- Primary resource (always shown)
    local primaryBar = resourceBars.primary
    if currentResourceValues.primary then
        local resource = currentResourceValues.primary
        
        -- Update bar
        primaryBar.resourceType = resource.type
        primaryBar.max = resource.max
        primaryBar.current = resource.current
        
        -- Set color
        local color = colorTable.resources[resource.type] or colorTable.status.normal
        primaryBar.bar:SetVertexColor(color.r, color.g, color.b, 1)
        
        -- Update width
        local width = settings.resourceDisplay.barWidth
        local height = settings.resourceDisplay.barHeight
        primaryBar.frame:SetSize(width, height)
        
        -- Update fill
        local fillWidth = (resource.current / resource.max) * width
        primaryBar.bar:SetWidth(fillWidth)
        
        -- Update text
        if settings.resourceDisplay.showText then
            primaryBar.text:SetText(string.format("%d / %d", resource.current, resource.max))
            primaryBar.text:Show()
        else
            primaryBar.text:Hide()
        end
        
        primaryBar.frame:Show()
        barCount = barCount + 1
    else
        primaryBar.frame:Hide()
    end
    
    -- Secondary resources (if not using primary only)
    if not settings.resourceDisplay.usePrimaryResourceOnly then
        -- Secondary resource
        if currentResourceValues.secondary then
            local resource = currentResourceValues.secondary
            local bar = resourceBars.secondary
            
            -- Update bar
            bar.resourceType = resource.type
            bar.max = resource.max
            bar.current = resource.current
            
            -- Set color
            local color = colorTable.resources[resource.type] or colorTable.status.normal
            bar.bar:SetVertexColor(color.r, color.g, color.b, 1)
            
            -- Update width
            local width = settings.resourceDisplay.barWidth
            local height = settings.resourceDisplay.barHeight
            bar.frame:SetSize(width, height)
            
            -- Update fill
            local fillWidth = (resource.current / resource.max) * width
            bar.bar:SetWidth(fillWidth)
            
            -- Update text
            if settings.resourceDisplay.showText then
                bar.text:SetText(string.format("%d / %d", resource.current, resource.max))
                bar.text:Show()
            else
                bar.text:Hide()
            end
            
            bar.frame:Show()
            barCount = barCount + 1
        else
            resourceBars.secondary.frame:Hide()
        end
        
        -- Extra resources
        for i = 1, 2 do
            local resourceKey = "extra" .. i
            local barKey = "extra" .. i
            
            if currentResourceValues[resourceKey] then
                local resource = currentResourceValues[resourceKey]
                local bar = resourceBars[barKey]
                
                -- Update bar
                bar.resourceType = resource.type
                bar.max = resource.max
                bar.current = resource.current
                
                -- Set color
                local color = colorTable.resources[resource.type] or colorTable.status.normal
                bar.bar:SetVertexColor(color.r, color.g, color.b, 1)
                
                -- Update width
                local width = settings.resourceDisplay.barWidth
                local height = settings.resourceDisplay.barHeight
                bar.frame:SetSize(width, height)
                
                -- Update fill
                local fillWidth = (resource.current / resource.max) * width
                bar.bar:SetWidth(fillWidth)
                
                -- Update text
                if settings.resourceDisplay.showText then
                    bar.text:SetText(string.format("%d", resource.current))
                    bar.text:Show()
                else
                    bar.text:Hide()
                end
                
                bar.frame:Show()
                barCount = barCount + 1
            else
                resourceBars[barKey].frame:Hide()
            end
        end
    else
        resourceBars.secondary.frame:Hide()
        resourceBars.extra1.frame:Hide()
        resourceBars.extra2.frame:Hide()
    end
    
    -- Position the bars
    self:PositionResourceBars(barCount)
end

-- Position resource bars
function VisualOverlay:PositionResourceBars(barCount)
    if barCount == 0 then
        return
    end
    
    local settings = ConfigRegistry:GetSettings("VisualOverlay")
    local barHeight = settings.resourceDisplay.barHeight
    local spacing = 5
    
    -- Start position below ability icons
    local yOffset = -((mainFrame:GetHeight() / 2) + 10)
    
    -- Position each visible bar
    local visibleBars = {}
    for _, key in ipairs({ "primary", "secondary", "extra1", "extra2" }) do
        if resourceBars[key].frame:IsShown() then
            table.insert(visibleBars, resourceBars[key])
        end
    end
    
    for i, bar in ipairs(visibleBars) do
        bar.frame:ClearAllPoints()
        bar.frame:SetPoint("TOPLEFT", mainFrame, "CENTER", -(settings.resourceDisplay.barWidth / 2), yOffset - ((i - 1) * (barHeight + spacing)))
    end
end

-- Update resource values
function VisualOverlay:UpdateResourceValues()
    local classID = API.GetPlayerClassID()
    local specID = API.GetActiveSpecID()
    
    if not classID or not specID then
        return
    end
    
    -- Reset current values
    currentResourceValues = {}
    
    -- Different handling based on class/spec
    if classID == 1 then -- Warrior
        -- Primary: Rage
        currentResourceValues.primary = {
            type = "rage",
            current = API.GetPowerResource("rage") or 0,
            max = 100
        }
    elseif classID == 2 then -- Paladin
        -- Primary: Mana or Holy Power depending on spec
        if specID == 1 or specID == 2 then -- Holy or Protection
            currentResourceValues.primary = {
                type = "mana",
                current = API.GetPlayerManaPercent() or 0,
                max = 100
            }
        else -- Retribution
            currentResourceValues.primary = {
                type = "holy_power",
                current = API.GetPowerResource("holypower") or 0,
                max = 5
            }
        end
    elseif classID == 3 then -- Hunter
        -- Primary: Focus
        currentResourceValues.primary = {
            type = "focus",
            current = API.GetPowerResource("focus") or 0,
            max = 100
        }
    elseif classID == 4 then -- Rogue
        -- Primary: Energy
        currentResourceValues.primary = {
            type = "energy",
            current = API.GetPowerResource("energy") or 0,
            max = 100
        }
        
        -- Secondary: Combo Points
        currentResourceValues.secondary = {
            type = "combo_points",
            current = API.GetComboPoints("player", "target") or 0,
            max = 5
        }
    elseif classID == 5 then -- Priest
        -- Primary: Mana
        currentResourceValues.primary = {
            type = "mana",
            current = API.GetPlayerManaPercent() or 0,
            max = 100
        }
        
        -- Shadow: Insanity
        if specID == 3 then -- Shadow
            currentResourceValues.secondary = {
                type = "insanity",
                current = API.GetPowerResource("insanity") or 0,
                max = 100
            }
        end
    elseif classID == 6 then -- Death Knight
        -- Primary: Runic Power
        currentResourceValues.primary = {
            type = "runic",
            current = API.GetPowerResource("runicpower") or 0,
            max = 100
        }
        
        -- Secondary: Runes
        currentResourceValues.secondary = {
            type = "runes",
            current = API.GetRuneCount() or 0,
            max = 6
        }
    elseif classID == 7 then -- Shaman
        -- Primary: Mana
        currentResourceValues.primary = {
            type = "mana",
            current = API.GetPlayerManaPercent() or 0,
            max = 100
        }
        
        -- Enhancement: Maelstrom Weapon
        if specID == 2 then -- Enhancement
            -- Custom handling for Enhancement
        end
    elseif classID == 8 then -- Mage
        -- Primary: Mana
        currentResourceValues.primary = {
            type = "mana",
            current = API.GetPlayerManaPercent() or 0,
            max = 100
        }
        
        -- Arcane: Arcane Charges
        if specID == 1 then -- Arcane
            currentResourceValues.secondary = {
                type = "arcane_charges",
                current = API.GetArcaneCharges() or 0,
                max = 4
            }
        end
    elseif classID == 9 then -- Warlock
        -- Primary: Mana
        currentResourceValues.primary = {
            type = "mana",
            current = API.GetPlayerManaPercent() or 0,
            max = 100
        }
        
        -- Secondary: Soul Shards
        currentResourceValues.secondary = {
            type = "soul_shards",
            current = API.GetPowerResource("soulshards") or 0,
            max = 5
        }
    elseif classID == 10 then -- Monk
        -- Primary: Energy
        currentResourceValues.primary = {
            type = "energy",
            current = API.GetPowerResource("energy") or 0,
            max = 100
        }
        
        -- Secondary: Chi
        currentResourceValues.secondary = {
            type = "chi",
            current = API.GetPowerResource("chi") or 0,
            max = 5
        }
    elseif classID == 11 then -- Druid
        -- Different by spec
        if specID == 1 then -- Balance
            currentResourceValues.primary = {
                type = "astral_power",
                current = API.GetPowerResource("lunarpower") or 0,
                max = 100
            }
        elseif specID == 2 then -- Feral
            currentResourceValues.primary = {
                type = "energy",
                current = API.GetPowerResource("energy") or 0,
                max = 100
            }
            
            currentResourceValues.secondary = {
                type = "combo_points",
                current = API.GetComboPoints("player", "target") or 0,
                max = 5
            }
        elseif specID == 3 then -- Guardian
            currentResourceValues.primary = {
                type = "rage",
                current = API.GetPowerResource("rage") or 0,
                max = 100
            }
        elseif specID == 4 then -- Restoration
            currentResourceValues.primary = {
                type = "mana",
                current = API.GetPlayerManaPercent() or 0,
                max = 100
            }
        end
    elseif classID == 12 then -- Demon Hunter
        -- Primary: Fury
        if specID == 1 then -- Havoc
            currentResourceValues.primary = {
                type = "fury",
                current = API.GetPowerResource("fury") or 0,
                max = 120
            }
        else -- Vengeance
            currentResourceValues.primary = {
                type = "fury",
                current = API.GetPowerResource("fury") or 0,
                max = 100
            }
        end
    elseif classID == 13 then -- Evoker
        -- Primary: Essence
        currentResourceValues.primary = {
            type = "essence",
            current = API.GetPowerResource("essence") or 0,
            max = 6
        }
        
        -- Mana for healers
        if specID == 2 then -- Preservation
            currentResourceValues.secondary = {
                type = "mana",
                current = API.GetPlayerManaPercent() or 0,
                max = 100
            }
        end
    end
end

-- Update status texts
function VisualOverlay:UpdateStatusTexts()
    local settings = ConfigRegistry:GetSettings("VisualOverlay")
    
    -- Rotation status
    if settings.statusDisplay.showRotationStatus then
        local rotationEnabled = WR.IsEnabled and WR.IsEnabled() or false
        local text = rotationEnabled and "Rotation: |cFF00FF00Enabled|r" or "Rotation: |cFFFF0000Disabled|r"
        statusTexts.rotationStatus.text:SetText(text)
        statusTexts.rotationStatus.text:Show()
    else
        statusTexts.rotationStatus.text:Hide()
    end
    
    -- Rotation mode
    if settings.statusDisplay.showRotationMode then
        local modeText = "Mode: "
        if currentRotationMode == "auto" then
            modeText = modeText .. "|cFFFFFFFFAuto|r"
        elseif currentRotationMode == "aoe" then
            modeText = modeText .. "|cFF00FFFFAoE|r"
        elseif currentRotationMode == "st" then
            modeText = modeText .. "|cFFFFFF00ST|r"
        end
        
        statusTexts.rotationMode.text:SetText(modeText)
        statusTexts.rotationMode.text:Show()
    else
        statusTexts.rotationMode.text:Hide()
    end
    
    -- Performance metrics
    if settings.statusDisplay.showPerformanceMetrics and WR.PerformanceTracker then
        local dps = WR.PerformanceTracker:GetCurrentDPS() or 0
        local metricText = string.format("DPS: |cFFFFFF00%.1fk|r", dps / 1000)
        
        statusTexts.performance.text:SetText(metricText)
        statusTexts.performance.text:Show()
    else
        statusTexts.performance.text:Hide()
    end
end

-- Process notifications
function VisualOverlay:ProcessNotifications()
    local settings = ConfigRegistry:GetSettings("VisualOverlay")
    if not settings.notifications.enableNotifications or #pendingNotifications == 0 then
        if notificationFrame:IsShown() and GetTime() > notificationFrame.endTime then
            notificationFrame:Hide()
        end
        return
    end
    
    -- Check if we need to show the next notification
    if not notificationFrame:IsShown() or GetTime() > notificationFrame.endTime then
        local notification = table.remove(pendingNotifications, 1)
        
        -- Show only important notifications if setting enabled
        if settings.notifications.showImportant and not notification.important then
            return
        end
        
        -- Set the notification
        notificationFrame.text:SetText(notification.text)
        
        -- Set color
        local color = colorTable.notifications[notification.type] or colorTable.notifications.normal
        notificationFrame.text:SetTextColor(color.r, color.g, color.b, 1)
        
        -- Set font size
        notificationFrame.text:SetFont(notificationFrame.text:GetFont(), settings.notifications.fontSize, "OUTLINE")
        
        -- Show and set end time
        notificationFrame:Show()
        notificationFrame.endTime = GetTime() + (notification.duration or settings.notifications.duration)
        
        -- Animate (fade in)
        notificationFrame:SetAlpha(0)
        notificationFrame:SetScript("OnUpdate", function(self, elapsed)
            local currentAlpha = self:GetAlpha()
            if currentAlpha < 1 then
                self:SetAlpha(math.min(currentAlpha + (elapsed / FADE_DURATION), 1))
            elseif GetTime() > self.endTime - FADE_DURATION then
                -- Start fading out
                self:SetAlpha(math.max(currentAlpha - (elapsed / FADE_DURATION), 0))
            end
        end)
    end
end

-- Update the overlay visibility
function VisualOverlay:UpdateOverlayVisibility()
    local settings = ConfigRegistry:GetSettings("VisualOverlay")
    
    -- Check if overlay is enabled
    if not settings.generalSettings.enableOverlay then
        isOverlayShown = false
        mainFrame:Hide()
        return
    end
    
    -- Check if we should only show in combat
    if settings.generalSettings.showOnlyInCombat and not API.IsPlayerInCombat() then
        isOverlayShown = false
        mainFrame:Hide()
        return
    end
    
    -- Update locked state
    isLocked = settings.generalSettings.lockOverlay
    
    -- Update scale
    mainFrame:SetScale(settings.generalSettings.scale)
    
    -- Update appearance
    local bgColor = settings.appearance.backgroundColor
    local borderColor = settings.appearance.borderColor
    
    mainFrame:SetBackdropColor(bgColor.r, bgColor.g, bgColor.b, bgColor.a)
    mainFrame:SetBackdropBorderColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a)
    
    -- Show the overlay
    isOverlayShown = true
    mainFrame:Show()
    
    -- Refresh layout
    self:RefreshLayout()
end

-- Refresh the overlay layout
function VisualOverlay:RefreshLayout()
    if not isOverlayShown then
        return
    end
    
    -- Position ability icons
    self:PositionAbilityIcons()
    
    -- Position resource bars
    local barCount = 0
    for _, bar in pairs(resourceBars) do
        if bar.frame:IsShown() then
            barCount = barCount + 1
        end
    end
    self:PositionResourceBars(barCount)
    
    -- Update status texts
    self:UpdateStatusTexts()
end

-- Set the recommended spell list
function VisualOverlay:SetRecommendedSpells(spells)
    if not spells or type(spells) ~= "table" then
        return
    end
    
    currentRecommendedSpells = spells
end

-- Set the rotation mode
function VisualOverlay:SetRotationMode(mode)
    if mode == "auto" or mode == "aoe" or mode == "st" then
        currentRotationMode = mode
    end
end

-- Add a notification
function VisualOverlay:AddNotification(text, type, duration, important)
    if not text then
        return
    end
    
    table.insert(pendingNotifications, {
        text = text,
        type = type or "normal",
        duration = duration,
        important = important or false
    })
    
    -- Limit notification queue
    if #pendingNotifications > 10 then
        table.remove(pendingNotifications, 1)
    end
end

-- Handle slash command
function VisualOverlay:HandleSlashCommand(msg)
    if not msg or msg == "" then
        -- Show help
        API.Print("WindrunnerRotations Visual Overlay Commands:")
        API.Print("/wroverlay show - Show the overlay")
        API.Print("/wroverlay hide - Hide the overlay")
        API.Print("/wroverlay toggle - Toggle the overlay")
        API.Print("/wroverlay lock - Lock the overlay position")
        API.Print("/wroverlay unlock - Unlock the overlay position")
        API.Print("/wroverlay reset - Reset overlay position")
        API.Print("/wroverlay config - Open configuration panel")
        return
    end
    
    local command = msg
    
    if command == "show" then
        -- Show overlay
        local settings = ConfigRegistry:GetSettings("VisualOverlay")
        ConfigRegistry:SetSettingValue("VisualOverlay", "generalSettings.enableOverlay", true)
        self:UpdateOverlayVisibility()
        API.Print("Visual overlay shown")
    elseif command == "hide" then
        -- Hide overlay
        ConfigRegistry:SetSettingValue("VisualOverlay", "generalSettings.enableOverlay", false)
        self:UpdateOverlayVisibility()
        API.Print("Visual overlay hidden")
    elseif command == "toggle" then
        -- Toggle overlay
        local settings = ConfigRegistry:GetSettings("VisualOverlay")
        local newValue = not settings.generalSettings.enableOverlay
        ConfigRegistry:SetSettingValue("VisualOverlay", "generalSettings.enableOverlay", newValue)
        self:UpdateOverlayVisibility()
        API.Print("Visual overlay " .. (newValue and "shown" or "hidden"))
    elseif command == "lock" then
        -- Lock overlay
        ConfigRegistry:SetSettingValue("VisualOverlay", "generalSettings.lockOverlay", true)
        isLocked = true
        API.Print("Visual overlay locked")
    elseif command == "unlock" then
        -- Unlock overlay
        ConfigRegistry:SetSettingValue("VisualOverlay", "generalSettings.lockOverlay", false)
        isLocked = false
        API.Print("Visual overlay unlocked")
    elseif command == "reset" then
        -- Reset position
        mainFrame:ClearAllPoints()
        mainFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        API.Print("Visual overlay position reset")
    elseif command == "config" then
        -- Open configuration panel
        if WR.ConfigurationUI and WR.ConfigurationUI.OpenPage then
            WR.ConfigurationUI:OpenPage("VisualOverlay")
        else
            API.Print("Configuration UI not available")
        end
    else
        API.Print("Unknown command. Type /wroverlay for help.")
    end
end

-- Return the module for loading
return VisualOverlay