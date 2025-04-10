local addonName, WR = ...

-- ClassHUD module for specialized class displays
local ClassHUD = {}
WR.UI = WR.UI or {}
WR.UI.ClassHUD = ClassHUD

-- UI constants
local HUD_WIDTH = 250
local HUD_HEIGHT = 150
local ICON_SIZE = 32
local ICON_SPACING = 5
local CLASSBAR_HEIGHT = 8
local AURA_HEIGHT = 20
local AURA_WIDTH = 150
local MAX_AURAS = 6
local MAX_PROC_ICONS = 5
local MAX_COOLDOWN_ICONS = 5
local PROC_FRAME_HEIGHT = 50
local COOLDOWN_FRAME_HEIGHT = 50
local RESOURCE_BAR_HEIGHT = 12

-- Frame references
local mainFrame, classBarFrame, auraFrame, procFrame, cooldownFrame, resourceFrame
local auraDisplays = {}
local procIcons = {}
local cooldownIcons = {}
local resourceBars = {}
local classHealththresholds = {}

-- Theme and styling
local THEME = {
    background = {r = 0.1, g = 0.1, b = 0.1, a = 0.6},
    border = {r = 0.4, g = 0.4, b = 0.4, a = 0.6},
    text = {r = 1, g = 1, b = 1, a = 1},
    textShadow = {r = 0, g = 0, b = 0, a = 1},
    barBackground = {r = 0.2, g = 0.2, b = 0.2, a = 0.6},
    procHighlight = {r = 0.9, g = 0.8, b = 0.1, a = 1},
    cooldownReady = {r = 0.1, g = 0.9, b = 0.1, a = 1},
    cooldownNotReady = {r = 0.5, g = 0.5, b = 0.5, a = 1}
}

-- Class-specific resources and displays
local CLASS_RESOURCES = {
    WARRIOR = {
        primary = {
            type = "rage",
            color = {r = 0.78, g = 0.25, b = 0.25},
            max = 100
        }
    },
    PALADIN = {
        primary = {
            type = "holypower",
            color = {r = 0.95, g = 0.90, b = 0.60},
            max = 5,
            segments = true
        }
    },
    HUNTER = {
        primary = {
            type = "focus",
            color = {r = 0.65, g = 0.83, b = 0.45},
            max = 100
        }
    },
    ROGUE = {
        primary = {
            type = "energy",
            color = {r = 1.00, g = 0.96, b = 0.41},
            max = 100
        },
        secondary = {
            type = "combopoints",
            color = {r = 0.9, g = 0.3, b = 0.3},
            max = 5,
            segments = true
        }
    },
    PRIEST = {
        primary = {
            type = "mana",
            color = {r = 0.41, g = 0.80, b = 0.94},
            max = 100
        },
        secondary = {
            type = "insanity",
            color = {r = 0.70, g = 0.4, b = 0.9},
            max = 100,
            spec = 3 -- Shadow spec
        }
    },
    DEATHKNIGHT = {
        primary = {
            type = "runicpower",
            color = {r = 0.0, g = 0.82, b = 1.0},
            max = 100
        },
        secondary = {
            type = "runes",
            color = {r = 0.77, g = 0.12, b = 0.23},
            max = 6,
            segments = true
        }
    },
    SHAMAN = {
        primary = {
            type = "mana",
            color = {r = 0.00, g = 0.44, b = 0.87},
            max = 100
        },
        secondary = {
            type = "maelstrom",
            color = {r = 0.00, g = 0.50, b = 1.00},
            max = 100,
            spec = {1, 2} -- Elemental, Enhancement specs
        }
    },
    MAGE = {
        primary = {
            type = "mana",
            color = {r = 0.41, g = 0.80, b = 0.94},
            max = 100
        },
        secondary = {
            type = "arcanecharges",
            color = {r = 0.1, g = 0.1, b = 0.98},
            max = 4,
            segments = true,
            spec = 1 -- Arcane spec
        }
    },
    WARLOCK = {
        primary = {
            type = "mana",
            color = {r = 0.58, g = 0.51, b = 0.79},
            max = 100
        },
        secondary = {
            type = "soulshards",
            color = {r = 0.50, g = 0.32, b = 0.55},
            max = 5,
            segments = true
        }
    },
    MONK = {
        primary = {
            type = "energy",
            color = {r = 0.00, g = 1.00, b = 0.59},
            max = 100,
            spec = {1, 2} -- Brewmaster, Windwalker specs
        },
        secondary = {
            type = "chi",
            color = {r = 0.71, g = 1.0, b = 0.92},
            max = 5,
            segments = true,
            spec = {1, 2} -- Brewmaster, Windwalker specs
        }
    },
    DRUID = {
        primary = {
            type = "mana",
            color = {r = 0.0, g = 0.44, b = 0.87},
            max = 100,
            spec = {1, 4} -- Balance, Restoration specs
        },
        secondary = {
            type = "energy",
            color = {r = 1.00, g = 0.96, b = 0.41},
            max = 100,
            spec = {2, 3} -- Feral, Guardian specs
        },
        tertiary = {
            type = "combopoints",
            color = {r = 0.9, g = 0.3, b = 0.3},
            max = 5,
            segments = true,
            spec = 2 -- Feral spec
        }
    },
    DEMONHUNTER = {
        primary = {
            type = "fury",
            color = {r = 0.64, g = 0.19, b = 0.79},
            max = 100,
            spec = 1 -- Havoc spec
        },
        secondary = {
            type = "pain",
            color = {r = 0.64, g = 0.19, b = 0.79},
            max = 100,
            spec = 2 -- Vengeance spec
        }
    },
    EVOKER = {
        primary = {
            type = "mana",
            color = {r = 0.20, g = 0.58, b = 0.50},
            max = 100
        },
        secondary = {
            type = "essence",
            color = {r = 0.0, g = 0.75, b = 0.65},
            max = 5,
            segments = true
        }
    }
}

-- Class defensive thresholds
local CLASS_DEFENSIVES = {
    WARRIOR = {
        -- Shield Wall, Last Stand, etc.
        {spellId = 871, threshold = 30, name = "Shield Wall"},
        {spellId = 12975, threshold = 40, name = "Last Stand"},
        {spellId = 97462, threshold = 35, name = "Rallying Cry"}
    },
    PALADIN = {
        -- Divine Shield, Lay on Hands, etc.
        {spellId = 642, threshold = 20, name = "Divine Shield"},
        {spellId = 633, threshold = 25, name = "Lay on Hands"},
        {spellId = 498, threshold = 40, name = "Divine Protection"}
    },
    HUNTER = {
        -- Exhilaration, Aspect of the Turtle, etc.
        {spellId = 109304, threshold = 40, name = "Exhilaration"},
        {spellId = 186265, threshold = 30, name = "Aspect of the Turtle"}
    },
    ROGUE = {
        -- Cloak of Shadows, Evasion, etc.
        {spellId = 31224, threshold = 30, name = "Cloak of Shadows"},
        {spellId = 5277, threshold = 35, name = "Evasion"},
        {spellId = 1966, threshold = 45, name = "Feint"}
    },
    PRIEST = {
        -- Desperate Prayer, etc.
        {spellId = 19236, threshold = 40, name = "Desperate Prayer"},
        {spellId = 47788, threshold = 30, name = "Guardian Spirit"},
        {spellId = 33206, threshold = 25, name = "Pain Suppression"}
    },
    DEATHKNIGHT = {
        -- Icebound Fortitude, etc.
        {spellId = 48792, threshold = 40, name = "Icebound Fortitude"},
        {spellId = 55233, threshold = 35, name = "Vampiric Blood"},
        {spellId = 49028, threshold = 30, name = "Dancing Rune Weapon"}
    },
    SHAMAN = {
        -- Astral Shift, etc.
        {spellId = 108271, threshold = 40, name = "Astral Shift"},
        {spellId = 198838, threshold = 45, name = "Earthen Wall Totem"}
    },
    MAGE = {
        -- Ice Block, etc.
        {spellId = 45438, threshold = 25, name = "Ice Block"},
        {spellId = 55342, threshold = 40, name = "Mirror Image"},
        {spellId = 235450, threshold = 35, name = "Prismatic Barrier"}
    },
    WARLOCK = {
        -- Unending Resolve, etc.
        {spellId = 104773, threshold = 35, name = "Unending Resolve"},
        {spellId = 108416, threshold = 40, name = "Dark Pact"}
    },
    MONK = {
        -- Fortifying Brew, etc.
        {spellId = 115203, threshold = 35, name = "Fortifying Brew"},
        {spellId = 122470, threshold = 40, name = "Touch of Karma"},
        {spellId = 122278, threshold = 30, name = "Dampen Harm"}
    },
    DRUID = {
        -- Survival Instincts, Barkskin, etc.
        {spellId = 61336, threshold = 35, name = "Survival Instincts"},
        {spellId = 22812, threshold = 40, name = "Barkskin"},
        {spellId = 22842, threshold = 45, name = "Frenzied Regeneration"}
    },
    DEMONHUNTER = {
        -- Blur, Metamorphosis, etc.
        {spellId = 198589, threshold = 40, name = "Blur"},
        {spellId = 187827, threshold = 30, name = "Metamorphosis"},
        {spellId = 204021, threshold = 35, name = "Fiery Brand"}
    },
    EVOKER = {
        -- Obsidian Scales, etc.
        {spellId = 363916, threshold = 35, name = "Obsidian Scales"},
        {spellId = 370665, threshold = 30, name = "Rescue"}
    }
}

-- Initialize the ClassHUD module
function ClassHUD:Initialize()
    -- Create main frame
    self:CreateMainFrame()
    
    -- Create class bar frame
    self:CreateClassBarFrame()
    
    -- Create aura frame
    self:CreateAuraFrame()
    
    -- Create proc frame
    self:CreateProcFrame()
    
    -- Create cooldown frame
    self:CreateCooldownFrame()
    
    -- Create resource frame
    self:CreateResourceFrame()
    
    -- Register events
    self:RegisterEvents()
    
    -- Set up class-specific displays
    self:SetupClassDisplays()
    
    -- Initialize animations
    self:InitializeAnimations()
    
    -- Hide frame initially
    mainFrame:Hide()
    
    WR:Debug("ClassHUD module initialized")
end

-- Register events
function ClassHUD:RegisterEvents()
    -- Create event frame
    local eventFrame = CreateFrame("Frame")
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_SPECIALIZATION_CHANGED" then
            ClassHUD:SetupClassDisplays()
        elseif event == "UNIT_HEALTH" then
            local unit = ...
            if unit == "player" then
                ClassHUD:UpdateDefensiveThresholds()
            end
        elseif event == "UNIT_AURA" then
            local unit = ...
            if unit == "player" or unit == "target" then
                ClassHUD:UpdateAuras()
            end
        elseif event == "PLAYER_TARGET_CHANGED" then
            ClassHUD:UpdateAuras()
        end
    end)
    
    -- Register for events
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    eventFrame:RegisterEvent("UNIT_HEALTH")
    eventFrame:RegisterEvent("UNIT_AURA")
    eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    
    self.eventFrame = eventFrame
end

-- Create main frame
function ClassHUD:CreateMainFrame()
    -- Create main container
    mainFrame = CreateFrame("Frame", "WindrunnerRotationsClassHUD", UIParent, "BackdropTemplate")
    mainFrame:SetSize(HUD_WIDTH, HUD_HEIGHT)
    mainFrame:SetPoint("CENTER", UIParent, "CENTER", 0, -200)
    mainFrame:SetFrameStrata("MEDIUM")
    mainFrame:SetFrameLevel(10)
    mainFrame:SetClampedToScreen(true)
    mainFrame:SetMovable(true)
    mainFrame:EnableMouse(true)
    mainFrame:RegisterForDrag("LeftButton")
    mainFrame:SetScript("OnDragStart", function(self) 
        if not WR.Config:Get("UI", "locked") then
            self:StartMoving() 
        end
    end)
    mainFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relativePoint, xOfs, yOfs = self:GetPoint()
        WR.Config:Set("UI", {
            point = point,
            relativePoint = relativePoint,
            x = xOfs,
            y = yOfs
        }, "classHUDPosition")
    end)
    
    -- Set backdrop
    mainFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    mainFrame:SetBackdropColor(THEME.background.r, THEME.background.g, THEME.background.b, THEME.background.a)
    mainFrame:SetBackdropBorderColor(THEME.border.r, THEME.border.g, THEME.border.b, THEME.border.a)
    
    -- Store reference
    self.mainFrame = mainFrame
    
    -- Apply saved position if available
    self:LoadPosition()
end

-- Create class bar frame at top
function ClassHUD:CreateClassBarFrame()
    -- Create class bar frame
    classBarFrame = CreateFrame("Frame", nil, mainFrame)
    classBarFrame:SetSize(HUD_WIDTH, CLASSBAR_HEIGHT)
    classBarFrame:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 0, 0)
    classBarFrame:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", 0, 0)
    
    -- Create color bar
    local classBar = classBarFrame:CreateTexture(nil, "BACKGROUND")
    classBar:SetAllPoints(classBarFrame)
    
    -- Store references
    self.classBarFrame = classBarFrame
    self.classBar = classBar
end

-- Create aura frame for buff/debuff tracking
function ClassHUD:CreateAuraFrame()
    -- Create aura frame
    auraFrame = CreateFrame("Frame", nil, mainFrame)
    auraFrame:SetSize(HUD_WIDTH, AURA_HEIGHT * MAX_AURAS)
    auraFrame:SetPoint("TOPLEFT", classBarFrame, "BOTTOMLEFT", 0, -5)
    auraFrame:SetPoint("TOPRIGHT", classBarFrame, "BOTTOMRIGHT", 0, -5)
    
    -- Create aura displays
    for i = 1, MAX_AURAS do
        local aura = CreateFrame("Frame", nil, auraFrame)
        aura:SetSize(AURA_WIDTH, AURA_HEIGHT)
        aura:SetPoint("TOPLEFT", auraFrame, "TOPLEFT", 0, -(i-1) * (AURA_HEIGHT + 2))
        
        -- Create aura icon
        local icon = aura:CreateTexture(nil, "ARTWORK")
        icon:SetSize(AURA_HEIGHT, AURA_HEIGHT)
        icon:SetPoint("LEFT", aura, "LEFT", 0, 0)
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) -- Trim the icon borders
        
        -- Create aura name text
        local name = aura:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        name:SetPoint("LEFT", icon, "RIGHT", 5, 0)
        name:SetText("")
        
        -- Create aura time text
        local time = aura:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        time:SetPoint("RIGHT", aura, "RIGHT", -5, 0)
        time:SetText("")
        
        -- Create aura bar
        local bar = CreateFrame("StatusBar", nil, aura)
        bar:SetPoint("TOPLEFT", icon, "TOPRIGHT", 5, 0)
        bar:SetPoint("BOTTOMRIGHT", aura, "BOTTOMRIGHT", 0, 0)
        bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
        
        local barBG = bar:CreateTexture(nil, "BACKGROUND")
        barBG:SetAllPoints(bar)
        barBG:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
        barBG:SetVertexColor(THEME.barBackground.r, THEME.barBackground.g, THEME.barBackground.b, THEME.barBackground.a)
        
        -- Store references
        auraDisplays[i] = {
            frame = aura,
            icon = icon,
            name = name,
            time = time,
            bar = bar,
            barBG = barBG,
            active = false
        }
        
        -- Hide by default
        aura:Hide()
    end
    
    -- Store reference
    self.auraFrame = auraFrame
    self.auraDisplays = auraDisplays
end

-- Create proc frame for proc tracking
function ClassHUD:CreateProcFrame()
    -- Create proc frame
    procFrame = CreateFrame("Frame", nil, mainFrame)
    procFrame:SetSize(HUD_WIDTH, PROC_FRAME_HEIGHT)
    procFrame:SetPoint("TOPLEFT", auraFrame, "BOTTOMLEFT", 0, -5)
    procFrame:SetPoint("TOPRIGHT", auraFrame, "BOTTOMRIGHT", 0, -5)
    
    -- Create proc label
    local procLabel = procFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    procLabel:SetPoint("TOPLEFT", procFrame, "TOPLEFT", 5, 0)
    procLabel:SetText("Active Procs:")
    
    -- Create proc icons
    local iconSize = PROC_FRAME_HEIGHT - 10
    local totalWidth = (iconSize + ICON_SPACING) * MAX_PROC_ICONS - ICON_SPACING
    local startX = (HUD_WIDTH - totalWidth) / 2
    
    for i = 1, MAX_PROC_ICONS do
        local icon = CreateFrame("Frame", nil, procFrame)
        icon:SetSize(iconSize, iconSize)
        icon:SetPoint("TOPLEFT", procFrame, "TOPLEFT", startX + (i-1) * (iconSize + ICON_SPACING), -10)
        
        -- Create icon texture
        local texture = icon:CreateTexture(nil, "ARTWORK")
        texture:SetAllPoints(icon)
        texture:SetTexCoord(0.08, 0.92, 0.08, 0.92) -- Trim the icon borders
        
        -- Create border
        local border = icon:CreateTexture(nil, "OVERLAY")
        border:SetPoint("TOPLEFT", texture, "TOPLEFT", -2, 2)
        border:SetPoint("BOTTOMRIGHT", texture, "BOTTOMRIGHT", 2, -2)
        border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
        border:SetBlendMode("ADD")
        border:SetVertexColor(THEME.procHighlight.r, THEME.procHighlight.g, THEME.procHighlight.b, THEME.procHighlight.a)
        
        -- Store references
        procIcons[i] = {
            frame = icon,
            texture = texture,
            border = border,
            spellId = nil,
            active = false
        }
        
        -- Hide by default
        icon:Hide()
    end
    
    -- Store reference
    self.procFrame = procFrame
    self.procIcons = procIcons
    self.procLabel = procLabel
end

-- Create cooldown frame for cooldown tracking
function ClassHUD:CreateCooldownFrame()
    -- Create cooldown frame
    cooldownFrame = CreateFrame("Frame", nil, mainFrame)
    cooldownFrame:SetSize(HUD_WIDTH, COOLDOWN_FRAME_HEIGHT)
    cooldownFrame:SetPoint("TOPLEFT", procFrame, "BOTTOMLEFT", 0, -5)
    cooldownFrame:SetPoint("TOPRIGHT", procFrame, "BOTTOMRIGHT", 0, -5)
    
    -- Create cooldown label
    local cooldownLabel = cooldownFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    cooldownLabel:SetPoint("TOPLEFT", cooldownFrame, "TOPLEFT", 5, 0)
    cooldownLabel:SetText("Cooldowns:")
    
    -- Create cooldown icons
    local iconSize = COOLDOWN_FRAME_HEIGHT - 10
    local totalWidth = (iconSize + ICON_SPACING) * MAX_COOLDOWN_ICONS - ICON_SPACING
    local startX = (HUD_WIDTH - totalWidth) / 2
    
    for i = 1, MAX_COOLDOWN_ICONS do
        local icon = CreateFrame("Frame", nil, cooldownFrame)
        icon:SetSize(iconSize, iconSize)
        icon:SetPoint("TOPLEFT", cooldownFrame, "TOPLEFT", startX + (i-1) * (iconSize + ICON_SPACING), -10)
        
        -- Create icon texture
        local texture = icon:CreateTexture(nil, "ARTWORK")
        texture:SetAllPoints(icon)
        texture:SetTexCoord(0.08, 0.92, 0.08, 0.92) -- Trim the icon borders
        
        -- Create cooldown overlay
        local cooldown = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate")
        cooldown:SetAllPoints(icon)
        cooldown:SetDrawEdge(false)
        cooldown:SetDrawSwipe(true)
        cooldown:SetSwipeColor(0, 0, 0, 0.8)
        
        -- Create cooldown text
        local cooldownText = icon:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        cooldownText:SetPoint("CENTER", icon, "CENTER", 0, 0)
        cooldownText:SetText("")
        
        -- Store references
        cooldownIcons[i] = {
            frame = icon,
            texture = texture,
            cooldown = cooldown,
            text = cooldownText,
            spellId = nil,
            active = false
        }
        
        -- Hide by default
        icon:Hide()
    end
    
    -- Store reference
    self.cooldownFrame = cooldownFrame
    self.cooldownIcons = cooldownIcons
    self.cooldownLabel = cooldownLabel
end

-- Create resource frame for class resources
function ClassHUD:CreateResourceFrame()
    -- Create resource frame
    resourceFrame = CreateFrame("Frame", nil, mainFrame)
    resourceFrame:SetSize(HUD_WIDTH, RESOURCE_BAR_HEIGHT * 2) -- Enough space for two resource bars
    resourceFrame:SetPoint("TOPLEFT", cooldownFrame, "BOTTOMLEFT", 0, -5)
    resourceFrame:SetPoint("TOPRIGHT", cooldownFrame, "BOTTOMRIGHT", 0, -5)
    
    -- Create placeholders for resource bars
    resourceBars.primary = self:CreateResourceBar(resourceFrame, "TOPLEFT", 0, 0)
    resourceBars.secondary = self:CreateResourceBar(resourceFrame, "TOPLEFT", 0, -(RESOURCE_BAR_HEIGHT + 2))
    resourceBars.tertiary = self:CreateResourceBar(resourceFrame, "BOTTOMLEFT", 0, 0)
    
    -- Hide by default
    resourceBars.primary.frame:Hide()
    resourceBars.secondary.frame:Hide()
    resourceBars.tertiary.frame:Hide()
    
    -- Store reference
    self.resourceFrame = resourceFrame
    self.resourceBars = resourceBars
end

-- Helper function to create a resource bar
function ClassHUD:CreateResourceBar(parent, point, x, y)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(HUD_WIDTH, RESOURCE_BAR_HEIGHT)
    frame:SetPoint(point, parent, point, x, y)
    
    -- Create bar label
    local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("LEFT", frame, "LEFT", 5, 0)
    label:SetText("")
    
    -- Create status bar
    local bar = CreateFrame("StatusBar", nil, frame)
    bar:SetPoint("LEFT", label, "RIGHT", 5, 0)
    bar:SetPoint("RIGHT", frame, "RIGHT", -5, 0)
    bar:SetPoint("TOP", frame, "TOP", 0, 0)
    bar:SetPoint("BOTTOM", frame, "BOTTOM", 0, 0)
    bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    
    local barBG = bar:CreateTexture(nil, "BACKGROUND")
    barBG:SetAllPoints(bar)
    barBG:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
    barBG:SetVertexColor(THEME.barBackground.r, THEME.barBackground.g, THEME.barBackground.b, THEME.barBackground.a)
    
    -- Create value text
    local valueText = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    valueText:SetPoint("CENTER", bar, "CENTER", 0, 0)
    valueText:SetText("")
    
    -- Create segment frames for resources with segments (combo points, runes, etc.)
    local segments = {}
    local segmentWidth = 20
    local maxSegments = 10 -- Maximum reasonable number of segments
    
    for i = 1, maxSegments do
        local segment = CreateFrame("Frame", nil, bar)
        segment:SetSize(segmentWidth, RESOURCE_BAR_HEIGHT - 2)
        segment:SetPoint("LEFT", bar, "LEFT", (i-1) * (segmentWidth + 2), 0)
        
        local segmentTexture = segment:CreateTexture(nil, "ARTWORK")
        segmentTexture:SetAllPoints(segment)
        segmentTexture:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
        
        segments[i] = {
            frame = segment,
            texture = segmentTexture
        }
        
        segment:Hide()
    end
    
    return {
        frame = frame,
        label = label,
        bar = bar,
        valueText = valueText,
        segments = segments
    }
end

-- Initialize animations
function ClassHUD:InitializeAnimations()
    -- Animation groups for proc highlighting
    for i, proc in ipairs(procIcons) do
        local pulseGroup = proc.frame:CreateAnimationGroup()
        pulseGroup:SetLooping("BOUNCE")
        
        local pulse = pulseGroup:CreateAnimation("Scale")
        pulse:SetScaleFrom(1, 1)
        pulse:SetScaleTo(1.1, 1.1)
        pulse:SetDuration(0.5)
        pulse:SetSmoothing("IN_OUT")
        
        proc.animation = pulseGroup
    end
end

-- Load saved position
function ClassHUD:LoadPosition()
    local position = WR.Config:Get("UI", "classHUDPosition")
    if position then
        mainFrame:ClearAllPoints()
        mainFrame:SetPoint(position.point or "CENTER", UIParent, position.relativePoint or "CENTER", position.x or 0, position.y or 0)
    end
    
    -- Apply saved scale
    local scale = WR.Config:Get("UI", "scale") or 1.0
    mainFrame:SetScale(scale)
end

-- Set up class-specific displays
function ClassHUD:SetupClassDisplays()
    local _, class = UnitClass("player")
    local classColor = RAID_CLASS_COLORS[class] or RAID_CLASS_COLORS["WARRIOR"]
    
    -- Set class color bar
    self.classBar:SetColorTexture(classColor.r, classColor.g, classColor.b, 0.8)
    
    -- Get current specialization
    local currentSpec = GetSpecialization()
    local currentSpecID = currentSpec and GetSpecializationInfo(currentSpec)
    
    -- Set up defensive thresholds
    classHealththresholds = CLASS_DEFENSIVES[class] or {}
    
    -- Set up class resources
    self:SetupClassResources(class, currentSpecID)
    
    -- Set up class auras
    self:SetupClassAuras(class, currentSpecID)
    
    -- Set up class procs
    self:SetupClassProcs(class, currentSpecID)
    
    -- Set up class cooldowns
    self:SetupClassCooldowns(class, currentSpecID)
    
    -- Update displays
    self:UpdateDefensiveThresholds()
    self:UpdateAuras()
    self:UpdateResources()
end

-- Set up class resources based on class and spec
function ClassHUD:SetupClassResources(class, specID)
    local resources = CLASS_RESOURCES[class]
    if not resources then return end
    
    -- Reset all resource bars
    resourceBars.primary.frame:Hide()
    resourceBars.secondary.frame:Hide()
    resourceBars.tertiary.frame:Hide()
    
    -- Primary resource
    if resources.primary then
        local primary = resources.primary
        local specCheck = primary.spec
        
        -- Check if this resource applies to the current spec
        local applyPrimary = true
        if specCheck then
            applyPrimary = false
            if type(specCheck) == "number" and GetSpecialization() == specCheck then
                applyPrimary = true
            elseif type(specCheck) == "table" then
                for _, spec in ipairs(specCheck) do
                    if GetSpecialization() == spec then
                        applyPrimary = true
                        break
                    end
                end
            end
        end
        
        if applyPrimary then
            -- Set up primary resource
            resourceBars.primary.label:SetText(self:FormatResourceName(primary.type))
            resourceBars.primary.bar:SetStatusBarColor(primary.color.r, primary.color.g, primary.color.b, 0.8)
            
            if primary.segments then
                -- Use segments display
                resourceBars.primary.bar:Hide()
                local segmentCount = primary.max or 5
                
                for i = 1, segmentCount do
                    resourceBars.primary.segments[i].frame:Show()
                    resourceBars.primary.segments[i].texture:SetVertexColor(primary.color.r, primary.color.g, primary.color.b, 0.4)
                end
                
                for i = segmentCount + 1, #resourceBars.primary.segments do
                    resourceBars.primary.segments[i].frame:Hide()
                end
            else
                -- Use standard bar display
                resourceBars.primary.bar:Show()
                for _, segment in ipairs(resourceBars.primary.segments) do
                    segment.frame:Hide()
                end
            end
            
            resourceBars.primary.type = primary.type
            resourceBars.primary.max = primary.max
            resourceBars.primary.useSegments = primary.segments
            resourceBars.primary.frame:Show()
        end
    end
    
    -- Secondary resource
    if resources.secondary then
        local secondary = resources.secondary
        local specCheck = secondary.spec
        
        -- Check if this resource applies to the current spec
        local applySecondary = true
        if specCheck then
            applySecondary = false
            if type(specCheck) == "number" and GetSpecialization() == specCheck then
                applySecondary = true
            elseif type(specCheck) == "table" then
                for _, spec in ipairs(specCheck) do
                    if GetSpecialization() == spec then
                        applySecondary = true
                        break
                    end
                end
            end
        end
        
        if applySecondary then
            -- Set up secondary resource
            resourceBars.secondary.label:SetText(self:FormatResourceName(secondary.type))
            resourceBars.secondary.bar:SetStatusBarColor(secondary.color.r, secondary.color.g, secondary.color.b, 0.8)
            
            if secondary.segments then
                -- Use segments display
                resourceBars.secondary.bar:Hide()
                local segmentCount = secondary.max or 5
                
                for i = 1, segmentCount do
                    resourceBars.secondary.segments[i].frame:Show()
                    resourceBars.secondary.segments[i].texture:SetVertexColor(secondary.color.r, secondary.color.g, secondary.color.b, 0.4)
                end
                
                for i = segmentCount + 1, #resourceBars.secondary.segments do
                    resourceBars.secondary.segments[i].frame:Hide()
                end
            else
                -- Use standard bar display
                resourceBars.secondary.bar:Show()
                for _, segment in ipairs(resourceBars.secondary.segments) do
                    segment.frame:Hide()
                end
            end
            
            resourceBars.secondary.type = secondary.type
            resourceBars.secondary.max = secondary.max
            resourceBars.secondary.useSegments = secondary.segments
            resourceBars.secondary.frame:Show()
        end
    end
    
    -- Tertiary resource (rare, mainly for druids)
    if resources.tertiary then
        local tertiary = resources.tertiary
        local specCheck = tertiary.spec
        
        -- Check if this resource applies to the current spec
        local applyTertiary = true
        if specCheck then
            applyTertiary = false
            if type(specCheck) == "number" and GetSpecialization() == specCheck then
                applyTertiary = true
            elseif type(specCheck) == "table" then
                for _, spec in ipairs(specCheck) do
                    if GetSpecialization() == spec then
                        applyTertiary = true
                        break
                    end
                end
            end
        end
        
        if applyTertiary then
            -- Set up tertiary resource
            resourceBars.tertiary.label:SetText(self:FormatResourceName(tertiary.type))
            resourceBars.tertiary.bar:SetStatusBarColor(tertiary.color.r, tertiary.color.g, tertiary.color.b, 0.8)
            
            if tertiary.segments then
                -- Use segments display
                resourceBars.tertiary.bar:Hide()
                local segmentCount = tertiary.max or 5
                
                for i = 1, segmentCount do
                    resourceBars.tertiary.segments[i].frame:Show()
                    resourceBars.tertiary.segments[i].texture:SetVertexColor(tertiary.color.r, tertiary.color.g, tertiary.color.b, 0.4)
                end
                
                for i = segmentCount + 1, #resourceBars.tertiary.segments do
                    resourceBars.tertiary.segments[i].frame:Hide()
                end
            else
                -- Use standard bar display
                resourceBars.tertiary.bar:Show()
                for _, segment in ipairs(resourceBars.tertiary.segments) do
                    segment.frame:Hide()
                end
            end
            
            resourceBars.tertiary.type = tertiary.type
            resourceBars.tertiary.max = tertiary.max
            resourceBars.tertiary.useSegments = tertiary.segments
            resourceBars.tertiary.frame:Show()
        end
    end
end

-- Format resource name to be more readable
function ClassHUD:FormatResourceName(resourceType)
    if not resourceType then return "" end
    
    local resourceNames = {
        rage = "Rage",
        energy = "Energy",
        mana = "Mana",
        focus = "Focus",
        runicpower = "Runic Power",
        holypower = "Holy Power",
        soulshards = "Soul Shards",
        combopoints = "Combo Points",
        chi = "Chi",
        maelstrom = "Maelstrom",
        fury = "Fury",
        pain = "Pain",
        insanity = "Insanity",
        arcanecharges = "Arcane Charges",
        runes = "Runes",
        essence = "Essence"
    }
    
    return resourceNames[resourceType] or resourceType
end

-- Set up class-specific auras to track
function ClassHUD:SetupClassAuras(class, specID)
    -- This would normally be populated with class-specific auras to track
    -- For demonstration purposes, we'll leave it empty
    
    -- Reset all aura displays
    for _, aura in ipairs(auraDisplays) do
        aura.frame:Hide()
        aura.active = false
    end
end

-- Set up class-specific ability procs to track
function ClassHUD:SetupClassProcs(class, specID)
    -- This would normally be populated with class-specific procs to track
    -- For demonstration purposes, we'll leave it empty
    
    -- Reset all proc icons
    for _, proc in ipairs(procIcons) do
        proc.frame:Hide()
        proc.spellId = nil
        proc.active = false
    end
end

-- Set up class-specific cooldowns to track
function ClassHUD:SetupClassCooldowns(class, specID)
    -- This would normally be populated with class-specific cooldowns to track
    -- For demonstration purposes, we'll leave it empty
    
    -- Reset all cooldown icons
    for _, cooldown in ipairs(cooldownIcons) do
        cooldown.frame:Hide()
        cooldown.spellId = nil
        cooldown.active = false
    end
end

-- Update resource displays
function ClassHUD:UpdateResources()
    -- Update primary resource
    if resourceBars.primary.frame:IsShown() then
        local resourceType = resourceBars.primary.type
        local value = self:GetResourceValue(resourceType)
        local max = resourceBars.primary.max or 100
        
        if resourceBars.primary.useSegments then
            -- Update segments
            for i = 1, max do
                local segment = resourceBars.primary.segments[i]
                if i <= value then
                    segment.texture:SetAlpha(1.0)
                else
                    segment.texture:SetAlpha(0.4)
                end
            end
            resourceBars.primary.valueText:SetText(value .. " / " .. max)
        else
            -- Update bar
            resourceBars.primary.bar:SetMinMaxValues(0, max)
            resourceBars.primary.bar:SetValue(value)
            resourceBars.primary.valueText:SetText(value .. " / " .. max)
        end
    end
    
    -- Update secondary resource
    if resourceBars.secondary.frame:IsShown() then
        local resourceType = resourceBars.secondary.type
        local value = self:GetResourceValue(resourceType)
        local max = resourceBars.secondary.max or 100
        
        if resourceBars.secondary.useSegments then
            -- Update segments
            for i = 1, max do
                local segment = resourceBars.secondary.segments[i]
                if i <= value then
                    segment.texture:SetAlpha(1.0)
                else
                    segment.texture:SetAlpha(0.4)
                end
            end
            resourceBars.secondary.valueText:SetText(value .. " / " .. max)
        else
            -- Update bar
            resourceBars.secondary.bar:SetMinMaxValues(0, max)
            resourceBars.secondary.bar:SetValue(value)
            resourceBars.secondary.valueText:SetText(value .. " / " .. max)
        end
    end
    
    -- Update tertiary resource
    if resourceBars.tertiary.frame:IsShown() then
        local resourceType = resourceBars.tertiary.type
        local value = self:GetResourceValue(resourceType)
        local max = resourceBars.tertiary.max or 100
        
        if resourceBars.tertiary.useSegments then
            -- Update segments
            for i = 1, max do
                local segment = resourceBars.tertiary.segments[i]
                if i <= value then
                    segment.texture:SetAlpha(1.0)
                else
                    segment.texture:SetAlpha(0.4)
                end
            end
            resourceBars.tertiary.valueText:SetText(value .. " / " .. max)
        else
            -- Update bar
            resourceBars.tertiary.bar:SetMinMaxValues(0, max)
            resourceBars.tertiary.bar:SetValue(value)
            resourceBars.tertiary.valueText:SetText(value .. " / " .. max)
        end
    end
end

-- Get resource value for a specific resource type
function ClassHUD:GetResourceValue(resourceType)
    if not resourceType then return 0 end
    
    if resourceType == "rage" then
        return UnitPower("player", Enum.PowerType.Rage) / 10
    elseif resourceType == "energy" then
        return UnitPower("player", Enum.PowerType.Energy)
    elseif resourceType == "mana" then
        return UnitPower("player", Enum.PowerType.Mana) / UnitPowerMax("player", Enum.PowerType.Mana) * 100
    elseif resourceType == "focus" then
        return UnitPower("player", Enum.PowerType.Focus)
    elseif resourceType == "runicpower" then
        return UnitPower("player", Enum.PowerType.RunicPower) / 10
    elseif resourceType == "holypower" then
        return UnitPower("player", Enum.PowerType.HolyPower)
    elseif resourceType == "soulshards" then
        return UnitPower("player", Enum.PowerType.SoulShards)
    elseif resourceType == "combopoints" then
        return UnitPower("player", Enum.PowerType.ComboPoints)
    elseif resourceType == "chi" then
        return UnitPower("player", Enum.PowerType.Chi)
    elseif resourceType == "maelstrom" then
        return UnitPower("player", Enum.PowerType.Maelstrom)
    elseif resourceType == "fury" then
        return UnitPower("player", Enum.PowerType.Fury) / 10
    elseif resourceType == "pain" then
        return UnitPower("player", Enum.PowerType.Pain) / 10
    elseif resourceType == "insanity" then
        return UnitPower("player", Enum.PowerType.Insanity)
    elseif resourceType == "arcanecharges" then
        return UnitPower("player", Enum.PowerType.ArcaneCharges)
    elseif resourceType == "runes" then
        -- Count available runes
        local runeCount = 0
        for i = 1, 6 do
            local start, duration, runeReady = GetRuneCooldown(i)
            if runeReady then
                runeCount = runeCount + 1
            end
        end
        return runeCount
    elseif resourceType == "essence" then
        return UnitPower("player", Enum.PowerType.Essence)
    end
    
    return 0
end

-- Update defensive thresholds based on player health
function ClassHUD:UpdateDefensiveThresholds()
    local health = UnitHealth("player")
    local maxHealth = UnitHealthMax("player")
    local healthPct = health / maxHealth * 100
    
    local recommendedDefensives = {}
    
    -- Check if any defensive abilities should be used
    for _, defensive in ipairs(classHealththresholds) do
        if healthPct <= defensive.threshold then
            -- Check if the ability is available
            local start, duration = GetSpellCooldown(defensive.spellId)
            local isAvailable = start == 0
            
            if isAvailable then
                table.insert(recommendedDefensives, defensive)
            end
        end
    end
    
    -- Signal to rotation about recommended defensives
    WR.recommendedDefensives = recommendedDefensives
    
    -- Highlight defensive cooldowns if low health
    if healthPct < 40 then
        for i, cooldown in ipairs(cooldownIcons) do
            if cooldown.active and cooldown.isDefensive then
                -- Highlight defensive cooldowns
                local start, duration = GetSpellCooldown(cooldown.spellId)
                if start == 0 then
                    -- Available - highlight
                    cooldown.frame:SetAlpha(1.0)
                end
            end
        end
    end
end

-- Update aura displays
function ClassHUD:UpdateAuras()
    -- This would track player and target auras and update the displays
    -- For demonstration purposes, we'll leave it empty
end

-- Update proc displays
function ClassHUD:UpdateProcs()
    -- This would update the proc displays based on active procs
    -- For demonstration purposes, we'll leave it empty
end

-- Update cooldown displays
function ClassHUD:UpdateCooldowns()
    -- This would update the cooldown displays based on ability cooldowns
    -- For demonstration purposes, we'll leave it empty
end

-- Main update function called from the rotation
function ClassHUD:Update(elapsed)
    -- Update resources
    self:UpdateResources()
    
    -- Update auras
    self:UpdateAuras()
    
    -- Update procs
    self:UpdateProcs()
    
    -- Update cooldowns
    self:UpdateCooldowns()
end

-- Show the class HUD
function ClassHUD:Show()
    mainFrame:Show()
end

-- Hide the class HUD
function ClassHUD:Hide()
    mainFrame:Hide()
end

-- Toggle the class HUD
function ClassHUD:Toggle()
    if mainFrame:IsShown() then
        self:Hide()
    else
        self:Show()
    end
end

-- Initialize the module
ClassHUD:Initialize()

return ClassHUD