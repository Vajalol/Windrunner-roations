local addonName, WR = ...

-- ClassSpecificUI module for specialized UI elements based on character class
local ClassSpecificUI = {}
WR.UI.ClassSpecificUI = ClassSpecificUI

-- Local references for performance
local CreateFrame = CreateFrame
local GetTime = GetTime
local UnitClass = UnitClass
local UnitPower = UnitPower
local UnitPowerMax = UnitPowerMax
local UnitAura = UnitAura
local UnitExists = UnitExists
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax
local math_min = math.min
local math_max = math.max
local math_floor = math.floor
local tinsert = table.insert
local tremove = table.remove

-- Module state variables
local classDisplays = {}
local classPanels = {}
local playerClass, playerSpec
local spellQueueDisplay
local dotTracker
local procDisplay
local apmMeter
local resourceForecast
local cooldownTracker
local activeDisplays = {}
local displayConfig = {}
local classColors = {
    WARRIOR     = {r = 0.78, g = 0.61, b = 0.43},
    PALADIN     = {r = 0.96, g = 0.55, b = 0.73},
    HUNTER      = {r = 0.67, g = 0.83, b = 0.45},
    ROGUE       = {r = 1.00, g = 0.96, b = 0.41},
    PRIEST      = {r = 1.00, g = 1.00, b = 1.00},
    DEATHKNIGHT = {r = 0.77, g = 0.12, b = 0.23},
    SHAMAN      = {r = 0.00, g = 0.44, b = 0.87},
    MAGE        = {r = 0.25, g = 0.78, b = 0.92},
    WARLOCK     = {r = 0.53, g = 0.53, b = 0.93},
    MONK        = {r = 0.00, g = 1.00, b = 0.59},
    DRUID       = {r = 1.00, g = 0.49, b = 0.04},
    DEMONHUNTER = {r = 0.64, g = 0.19, b = 0.79},
    EVOKER      = {r = 0.20, g = 0.58, b = 0.50}
}

-- Default configuration
local defaultConfig = {
    scale = 1.0,
    position = {
        x = 0,
        y = -200
    },
    locked = false,
    enabled = true,
    resourceDisplay = true,
    spellQueue = true,
    dotTracker = true,
    procDisplay = true,
    apmMeter = true,
    resourceForecast = true,
    cooldownTracker = true,
    glowEffects = true,
    audioFeedback = true,
    actionButtonIntegration = false,
    alpha = 0.9,
    colorizeByClass = true,
    advanced = false
}

-- Initialize module
function ClassSpecificUI:Initialize()
    -- Get player class and spec
    self:UpdatePlayerInfo()
    
    -- Load saved configuration
    self:LoadConfig()
    
    -- Create base frame
    self:CreateBaseFrame()
    
    -- Create appropriate class displays
    self:CreateClassDisplays()
    
    -- Register events
    self:RegisterEvents()
    
    -- Setup update routine
    self:SetupUpdates()
    
    WR:Debug("ClassSpecificUI module initialized")
end

-- Update player information
function ClassSpecificUI:UpdatePlayerInfo()
    playerClass = select(2, UnitClass("player"))
    playerSpec = GetSpecialization()
end

-- Load saved configuration
function ClassSpecificUI:LoadConfig()
    if not WindrunnerRotationsDB or not WindrunnerRotationsDB.ClassSpecificUI then
        displayConfig = CopyTable(defaultConfig)
        return
    end
    
    displayConfig = CopyTable(WindrunnerRotationsDB.ClassSpecificUI)
    
    -- Fill in any missing values with defaults
    for key, value in pairs(defaultConfig) do
        if displayConfig[key] == nil then
            displayConfig[key] = value
        end
    end
end

-- Save configuration
function ClassSpecificUI:SaveConfig()
    if not WindrunnerRotationsDB then
        WindrunnerRotationsDB = {}
    end
    
    WindrunnerRotationsDB.ClassSpecificUI = CopyTable(displayConfig)
end

-- Register events
function ClassSpecificUI:RegisterEvents()
    local frame = CreateFrame("Frame")
    frame.obj = self
    
    -- Register events
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    frame:RegisterEvent("UNIT_POWER_FREQUENT")
    frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    frame:RegisterEvent("UNIT_AURA")
    frame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    
    -- Set script handler
    frame:SetScript("OnEvent", function(self, event, ...)
        local obj = self.obj
        if event == "PLAYER_ENTERING_WORLD" then
            obj:UpdatePlayerInfo()
            obj:RefreshDisplays()
        elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
            obj:UpdatePlayerInfo()
            obj:RefreshDisplays()
        elseif event == "UNIT_POWER_FREQUENT" then
            local unit = ...
            if unit == "player" then
                obj:UpdateResourceDisplays()
            end
        elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
            local unit, _, spellID = ...
            if unit == "player" then
                obj:ProcessPlayerCast(spellID)
            end
        elseif event == "UNIT_AURA" then
            local unit = ...
            if unit == "player" then
                obj:UpdateAuraDisplays()
            elseif unit == "target" then
                obj:UpdateTargetAuraDisplays()
            end
        elseif event == "SPELL_UPDATE_COOLDOWN" then
            obj:UpdateCooldownDisplay()
        end
    end)
    
    self.eventFrame = frame
end

-- Create base frame
function ClassSpecificUI:CreateBaseFrame()
    -- Main container frame
    local frame = CreateFrame("Frame", "WRClassSpecificUI", UIParent)
    frame:SetSize(300, 150)
    frame:SetPoint("CENTER", UIParent, "CENTER", displayConfig.position.x, displayConfig.position.y)
    frame:SetScale(displayConfig.scale)
    frame:SetAlpha(displayConfig.alpha)
    frame:SetFrameStrata("MEDIUM")
    
    -- Make it movable
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(not displayConfig.locked)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        
        -- Update position in config
        local scale = self:GetScale()
        local x, y = self:GetCenter()
        x = x * scale - GetScreenWidth()/2
        y = y * scale - GetScreenHeight()/2
        
        displayConfig.position.x = math_floor(x + 0.5)
        displayConfig.position.y = math_floor(y + 0.5)
        
        ClassSpecificUI:SaveConfig()
    end)
    
    -- Background
    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.5)
    
    -- Border
    frame:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    
    -- Apply class color to border if enabled
    if displayConfig.colorizeByClass and classColors[playerClass] then
        local color = classColors[playerClass]
        frame:SetBackdropBorderColor(color.r, color.g, color.b, 1)
    else
        frame:SetBackdropBorderColor(0.8, 0.8, 0.8, 0.8)
    end
    
    -- Title text
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", frame, "TOP", 0, -5)
    title:SetText(playerClass)
    
    -- Close button
    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    closeButton:SetScript("OnClick", function() frame:Hide() end)
    
    -- Show/hide based on config
    if not displayConfig.enabled then
        frame:Hide()
    end
    
    self.mainFrame = frame
    
    -- Create container for class-specific displays
    local displayContainer = CreateFrame("Frame", nil, frame)
    displayContainer:SetPoint("TOP", title, "BOTTOM", 0, -5)
    displayContainer:SetPoint("LEFT", frame, "LEFT", 10, 0)
    displayContainer:SetPoint("RIGHT", frame, "RIGHT", -10, 0)
    displayContainer:SetPoint("BOTTOM", frame, "BOTTOM", 0, 10)
    
    self.displayContainer = displayContainer
end

-- Create appropriate class displays based on player class
function ClassSpecificUI:CreateClassDisplays()
    -- Clear existing displays
    for _, display in pairs(activeDisplays) do
        display:Hide()
    end
    activeDisplays = {}
    
    -- Create resource display appropriate for class
    self:CreateResourceDisplay()
    
    -- Create DoT/HoT tracker if applicable for this class/spec
    if self:ClassUsesDots() and displayConfig.dotTracker then
        self:CreateDotTracker()
    end
    
    -- Create proc display
    if displayConfig.procDisplay then
        self:CreateProcDisplay()
    end
    
    -- Create APM meter
    if displayConfig.apmMeter then
        self:CreateAPMMeter()
    end
    
    -- Create spell queue display
    if displayConfig.spellQueue then
        self:CreateSpellQueueDisplay()
    end
    
    -- Create resource forecast
    if displayConfig.resourceForecast then
        self:CreateResourceForecast()
    end
    
    -- Create cooldown tracker
    if displayConfig.cooldownTracker then
        self:CreateCooldownTracker()
    end
    
    -- Layout all displays
    self:LayoutDisplays()
}

-- Create resource display for current class
function ClassSpecificUI:CreateResourceDisplay()
    -- Get primary and secondary resource types for this class/spec
    local primaryType, secondaryType = self:GetResourceTypes()
    
    -- Create container frame
    local frame = CreateFrame("Frame", nil, self.displayContainer)
    frame:SetSize(280, 40)
    
    -- Style based on class
    if playerClass == "ROGUE" or (playerClass == "DRUID" and playerSpec == 2) then
        -- Combo points
        self:CreateComboPointDisplay(frame)
    elseif playerClass == "WARLOCK" then
        -- Soul shards
        self:CreateSoulShardDisplay(frame)
    elseif playerClass == "DEATHKNIGHT" then
        -- Runes
        self:CreateRuneDisplay(frame)
    elseif playerClass == "MONK" and playerSpec == 3 then
        -- Chi
        self:CreateChiDisplay(frame)
    elseif playerClass == "PALADIN" then
        -- Holy Power
        self:CreateHolyPowerDisplay(frame)
    else
        -- Generic resource bar for other classes
        self:CreateGenericResourceDisplay(frame, primaryType, secondaryType)
    end
    
    -- Store reference
    classDisplays.resource = frame
    table.insert(activeDisplays, frame)
}

-- Create combo point display (Rogue, Feral Druid)
function ClassSpecificUI:CreateComboPointDisplay(frame)
    -- Store references for updates
    local comboPoints = {}
    
    -- Get maximum possible combo points (base 5, but some specs can have more)
    local maxPoints = 8
    
    -- Create points
    for i = 1, maxPoints do
        local point = frame:CreateTexture(nil, "ARTWORK")
        point:SetSize(30, 30)
        point:SetPoint("TOPLEFT", frame, "TOPLEFT", (i-1)*35, 0)
        point:SetTexture("Interface\\ComboFrame\\ComboPoint")
        point:SetTexCoord(0.15, 0.85, 0.15, 0.85)
        point:SetDesaturated(true)
        point:SetAlpha(0.3)
        
        -- Animation for activation
        local animGroup = point:CreateAnimationGroup()
        local scale = animGroup:CreateAnimation("Scale")
        scale:SetScale(1.5, 1.5)
        scale:SetDuration(0.2)
        scale:SetSmoothing("OUT")
        
        -- Animation for deactivation
        local deactivateGroup = point:CreateAnimationGroup()
        local descale = deactivateGroup:CreateAnimation("Scale")
        descale:SetScale(0.5, 0.5)
        descale:SetDuration(0.2)
        descale:SetSmoothing("IN")
        
        comboPoints[i] = {
            texture = point,
            activateAnim = animGroup,
            deactivateAnim = deactivateGroup,
            active = false
        }
    end
    
    -- Update function
    frame.Update = function(self)
        local points = UnitPower("player", Enum.PowerType.ComboPoints)
        
        for i = 1, maxPoints do
            local isActive = i <= points
            
            if isActive ~= comboPoints[i].active then
                comboPoints[i].active = isActive
                
                if isActive then
                    comboPoints[i].activateAnim:Play()
                    comboPoints[i].texture:SetDesaturated(false)
                    comboPoints[i].texture:SetAlpha(1)
                    
                    -- Apply class color to active point
                    if displayConfig.colorizeByClass and classColors[playerClass] then
                        local color = classColors[playerClass]
                        comboPoints[i].texture:SetVertexColor(color.r, color.g, color.b, 1)
                    else
                        comboPoints[i].texture:SetVertexColor(1, 1, 1, 1)
                    end
                else
                    comboPoints[i].deactivateAnim:Play()
                    comboPoints[i].texture:SetDesaturated(true)
                    comboPoints[i].texture:SetAlpha(0.3)
                    comboPoints[i].texture:SetVertexColor(0.5, 0.5, 0.5, 0.5)
                end
            end
        end
    end
    
    -- Run initial update
    frame:Update()
}

-- Create soul shard display (Warlock)
function ClassSpecificUI:CreateSoulShardDisplay(frame)
    -- Store references for updates
    local shards = {}
    
    -- Get maximum possible shards
    local maxShards = 6
    
    -- Create shards
    for i = 1, maxShards do
        local shard = frame:CreateTexture(nil, "ARTWORK")
        shard:SetSize(40, 40)
        shard:SetPoint("TOPLEFT", frame, "TOPLEFT", (i-1)*45, 0)
        shard:SetTexture("Interface\\Icons\\Spell_Shadow_SoulGem")
        shard:SetTexCoord(0.1, 0.9, 0.1, 0.9)
        shard:SetDesaturated(true)
        shard:SetAlpha(0.3)
        
        -- Animation for activation
        local animGroup = shard:CreateAnimationGroup()
        local scale = animGroup:CreateAnimation("Scale")
        scale:SetScale(1.5, 1.5)
        scale:SetDuration(0.3)
        scale:SetSmoothing("OUT")
        
        -- Glow effect overlay
        local glow = frame:CreateTexture(nil, "OVERLAY")
        glow:SetSize(50, 50)
        glow:SetPoint("CENTER", shard, "CENTER")
        glow:SetTexture("Interface\\SpellActivationOverlay\\IconAlert")
        glow:SetTexCoord(0.00781250, 0.50781250, 0.53515625, 0.78515625)
        glow:SetBlendMode("ADD")
        glow:SetAlpha(0)
        
        -- Glow animation
        local glowAnim = glow:CreateAnimationGroup()
        glowAnim:SetLooping("REPEAT")
        
        local fadeIn = glowAnim:CreateAnimation("Alpha")
        fadeIn:SetFromAlpha(0)
        fadeIn:SetToAlpha(1)
        fadeIn:SetDuration(0.5)
        fadeIn:SetOrder(1)
        
        local fadeOut = glowAnim:CreateAnimation("Alpha")
        fadeOut:SetFromAlpha(1)
        fadeOut:SetToAlpha(0)
        fadeOut:SetDuration(0.5)
        fadeOut:SetOrder(2)
        
        shards[i] = {
            texture = shard,
            activateAnim = animGroup,
            glow = glow,
            glowAnim = glowAnim,
            active = false
        }
    end
    
    -- Update function
    frame.Update = function(self)
        local count = UnitPower("player", Enum.PowerType.SoulShards)
        local whole = math_floor(count)
        local partial = count - whole
        
        for i = 1, maxShards do
            local isActive = i <= whole
            local isPartial = i == whole + 1 and partial > 0
            
            if isActive ~= shards[i].active or isPartial then
                shards[i].active = isActive or isPartial
                
                if isActive then
                    shards[i].activateAnim:Play()
                    shards[i].texture:SetDesaturated(false)
                    shards[i].texture:SetAlpha(1)
                    
                    -- Apply class color to active shard
                    shards[i].texture:SetVertexColor(0.5, 0.32, 0.55, 1)
                    
                    -- Show glow for a newly activated shard
                    if not shards[i].wasActive then
                        shards[i].glowAnim:Play()
                    end
                    shards[i].wasActive = true
                elseif isPartial then
                    shards[i].texture:SetDesaturated(false)
                    shards[i].texture:SetAlpha(partial)
                    shards[i].texture:SetVertexColor(0.3, 0.18, 0.33, partial)
                    shards[i].wasActive = false
                else
                    shards[i].texture:SetDesaturated(true)
                    shards[i].texture:SetAlpha(0.3)
                    shards[i].texture:SetVertexColor(0.3, 0.3, 0.3, 0.3)
                    shards[i].glowAnim:Stop()
                    shards[i].wasActive = false
                end
            end
        end
    end
    
    -- Run initial update
    frame:Update()
}

-- Create rune display (Death Knight)
function ClassSpecificUI:CreateRuneDisplay(frame)
    -- Store references for updates
    local runes = {}
    
    -- Get information about runes
    local numRunes = 6
    
    -- Create runes
    for i = 1, numRunes do
        local rune = frame:CreateTexture(nil, "ARTWORK")
        rune:SetSize(35, 35)
        rune:SetPoint("TOPLEFT", frame, "TOPLEFT", (i-1)*40, 0)
        rune:SetTexture("Interface\\PlayerFrame\\UI-PlayerFrame-Deathknight-SingleRune")
        rune:SetAlpha(0.8)
        
        -- Cooldown overlay
        local cooldown = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate")
        cooldown:SetSize(35, 35)
        cooldown:SetPoint("CENTER", rune, "CENTER")
        cooldown:SetSwipeColor(0, 0, 0, 0.8)
        cooldown:SetDrawEdge(false)
        cooldown:SetHideCountdownNumbers(true)
        
        -- Rune color based on spec
        local runeColor = {r = 1, g = 0, b = 0} -- Default to blood
        if playerSpec == 2 then
            runeColor = {r = 0, g = 0.8, b = 1} -- Frost
        elseif playerSpec == 3 then
            runeColor = {r = 0.33, g = 0.74, b = 0.27} -- Unholy
        end
        
        -- Apply color
        rune:SetVertexColor(runeColor.r, runeColor.g, runeColor.b, 1)
        
        runes[i] = {
            texture = rune,
            cooldown = cooldown,
            runeId = i,
            active = true
        }
    end
    
    -- Update function
    frame.Update = function(self)
        for i = 1, numRunes do
            local startTime, duration, runeReady = select(1, GetRuneCooldown(i))
            
            if not runeReady and startTime and duration then
                runes[i].cooldown:SetCooldown(startTime, duration)
                runes[i].texture:SetAlpha(0.4)
                runes[i].active = false
            else
                runes[i].cooldown:Clear()
                runes[i].texture:SetAlpha(1)
                runes[i].active = true
            end
        end
    end
    
    -- Run initial update
    frame:Update()
}

-- Create Chi display (Windwalker Monk)
function ClassSpecificUI:CreateChiDisplay(frame)
    -- Store references for updates
    local chiOrbs = {}
    
    -- Get maximum possible Chi
    local maxChi = 6
    
    -- Create Chi orbs
    for i = 1, maxChi do
        local orb = frame:CreateTexture(nil, "ARTWORK")
        orb:SetSize(30, 30)
        orb:SetPoint("TOPLEFT", frame, "TOPLEFT", (i-1)*35, 0)
        orb:SetTexture("Interface\\PlayerFrame\\MonkUI")
        orb:SetTexCoord(0.00390625, 0.12890625, 0.01562500, 0.26562500)
        orb:SetDesaturated(true)
        orb:SetAlpha(0.3)
        
        -- Animation for activation
        local animGroup = orb:CreateAnimationGroup()
        local scale = animGroup:CreateAnimation("Scale")
        scale:SetScale(1.5, 1.5)
        scale:SetDuration(0.2)
        scale:SetSmoothing("OUT")
        
        chiOrbs[i] = {
            texture = orb,
            activateAnim = animGroup,
            active = false
        }
    end
    
    -- Update function
    frame.Update = function(self)
        local chi = UnitPower("player", Enum.PowerType.Chi)
        
        for i = 1, maxChi do
            local isActive = i <= chi
            
            if isActive ~= chiOrbs[i].active then
                chiOrbs[i].active = isActive
                
                if isActive then
                    chiOrbs[i].activateAnim:Play()
                    chiOrbs[i].texture:SetDesaturated(false)
                    chiOrbs[i].texture:SetAlpha(1)
                    
                    -- Apply color to active orb
                    chiOrbs[i].texture:SetVertexColor(0, 0.8, 0.6, 1)
                else
                    chiOrbs[i].texture:SetDesaturated(true)
                    chiOrbs[i].texture:SetAlpha(0.3)
                    chiOrbs[i].texture:SetVertexColor(0.5, 0.5, 0.5, 0.5)
                end
            end
        end
    end
    
    -- Run initial update
    frame:Update()
}

-- Create Holy Power display (Paladin)
function ClassSpecificUI:CreateHolyPowerDisplay(frame)
    -- Store references for updates
    local holyPower = {}
    
    -- Get maximum possible Holy Power
    local maxHolyPower = 5
    
    -- Create Holy Power points
    for i = 1, maxHolyPower do
        local point = frame:CreateTexture(nil, "ARTWORK")
        point:SetSize(30, 30)
        point:SetPoint("TOPLEFT", frame, "TOPLEFT", (i-1)*35, 0)
        point:SetTexture("Interface\\PlayerFrame\\PaladinPowerTextures")
        point:SetTexCoord(0.00390625, 0.12890625, 0.01562500, 0.26562500)
        point:SetDesaturated(true)
        point:SetAlpha(0.3)
        
        -- Animation for activation
        local animGroup = point:CreateAnimationGroup()
        local scale = animGroup:CreateAnimation("Scale")
        scale:SetScale(1.5, 1.5)
        scale:SetDuration(0.2)
        scale:SetSmoothing("OUT")
        
        holyPower[i] = {
            texture = point,
            activateAnim = animGroup,
            active = false
        }
    end
    
    -- Update function
    frame.Update = function(self)
        local power = UnitPower("player", Enum.PowerType.HolyPower)
        
        for i = 1, maxHolyPower do
            local isActive = i <= power
            
            if isActive ~= holyPower[i].active then
                holyPower[i].active = isActive
                
                if isActive then
                    holyPower[i].activateAnim:Play()
                    holyPower[i].texture:SetDesaturated(false)
                    holyPower[i].texture:SetAlpha(1)
                    
                    -- Apply color to active point
                    holyPower[i].texture:SetVertexColor(1, 0.9, 0.2, 1)
                else
                    holyPower[i].texture:SetDesaturated(true)
                    holyPower[i].texture:SetAlpha(0.3)
                    holyPower[i].texture:SetVertexColor(0.5, 0.5, 0.5, 0.5)
                end
            end
        end
    end
    
    -- Run initial update
    frame:Update()
}

-- Create generic resource display for classes without special resources
function ClassSpecificUI:CreateGenericResourceDisplay(frame, primaryType, secondaryType)
    -- Create primary resource bar
    local primaryBar = CreateFrame("StatusBar", nil, frame)
    primaryBar:SetSize(280, 20)
    primaryBar:SetPoint("TOP", frame, "TOP", 0, 0)
    primaryBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    primaryBar:SetMinMaxValues(0, 1)
    primaryBar:SetValue(1)
    
    -- Set color based on resource type
    if primaryType == Enum.PowerType.Mana then
        primaryBar:SetStatusBarColor(0, 0, 0.8, 1)
    elseif primaryType == Enum.PowerType.Rage then
        primaryBar:SetStatusBarColor(0.8, 0, 0, 1)
    elseif primaryType == Enum.PowerType.Energy then
        primaryBar:SetStatusBarColor(1, 0.9, 0, 1)
    elseif primaryType == Enum.PowerType.Focus then
        primaryBar:SetStatusBarColor(0.8, 0.4, 0, 1)
    elseif primaryType == Enum.PowerType.RunicPower then
        primaryBar:SetStatusBarColor(0, 0.8, 1, 1)
    else
        primaryBar:SetStatusBarColor(0.7, 0.7, 0.7, 1)
    end
    
    -- Create border around bar
    primaryBar.border = CreateFrame("Frame", nil, primaryBar, "BackdropTemplate")
    primaryBar.border:SetAllPoints()
    primaryBar.border:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 8,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    primaryBar.border:SetBackdropBorderColor(0.7, 0.7, 0.7, 0.7)
    
    -- Text for current/max value
    primaryBar.text = primaryBar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    primaryBar.text:SetPoint("CENTER", primaryBar, "CENTER", 0, 0)
    primaryBar.text:SetText("100%")
    
    -- Secondary resource bar if needed
    local secondaryBar
    if secondaryType then
        secondaryBar = CreateFrame("StatusBar", nil, frame)
        secondaryBar:SetSize(280, 15)
        secondaryBar:SetPoint("TOP", primaryBar, "BOTTOM", 0, -5)
        secondaryBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
        secondaryBar:SetMinMaxValues(0, 1)
        secondaryBar:SetValue(1)
        
        -- Set color based on secondary resource type
        if secondaryType == Enum.PowerType.Mana then
            secondaryBar:SetStatusBarColor(0, 0, 0.8, 1)
        elseif secondaryType == Enum.PowerType.Rage then
            secondaryBar:SetStatusBarColor(0.8, 0, 0, 1)
        elseif secondaryType == Enum.PowerType.Energy then
            secondaryBar:SetStatusBarColor(1, 0.9, 0, 1)
        elseif secondaryType == Enum.PowerType.RunicPower then
            secondaryBar:SetStatusBarColor(0, 0.8, 1, 1)
        else
            secondaryBar:SetStatusBarColor(0.7, 0.7, 0.7, 1)
        end
        
        -- Create border around bar
        secondaryBar.border = CreateFrame("Frame", nil, secondaryBar, "BackdropTemplate")
        secondaryBar.border:SetAllPoints()
        secondaryBar.border:SetBackdrop({
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 8,
            insets = { left = 1, right = 1, top = 1, bottom = 1 }
        })
        secondaryBar.border:SetBackdropBorderColor(0.7, 0.7, 0.7, 0.7)
        
        -- Text for current/max value
        secondaryBar.text = secondaryBar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        secondaryBar.text:SetPoint("CENTER", secondaryBar, "CENTER", 0, 0)
        secondaryBar.text:SetText("100%")
    end
    
    -- Store references
    frame.primaryBar = primaryBar
    frame.secondaryBar = secondaryBar
    frame.primaryType = primaryType
    frame.secondaryType = secondaryType
    
    -- Update function
    frame.Update = function(self)
        -- Update primary resource
        local primaryCurrent = UnitPower("player", self.primaryType)
        local primaryMax = UnitPowerMax("player", self.primaryType)
        
        if primaryMax > 0 then
            self.primaryBar:SetMinMaxValues(0, primaryMax)
            self.primaryBar:SetValue(primaryCurrent)
            self.primaryBar.text:SetText(primaryCurrent .. " / " .. primaryMax)
        end
        
        -- Update secondary resource if present
        if self.secondaryBar and self.secondaryType then
            local secondaryCurrent = UnitPower("player", self.secondaryType)
            local secondaryMax = UnitPowerMax("player", self.secondaryType)
            
            if secondaryMax > 0 then
                self.secondaryBar:SetMinMaxValues(0, secondaryMax)
                self.secondaryBar:SetValue(secondaryCurrent)
                self.secondaryBar.text:SetText(secondaryCurrent .. " / " .. secondaryMax)
            end
        end
    end
    
    -- Run initial update
    frame:Update()
}

-- Create DoT/HoT tracker
function ClassSpecificUI:CreateDotTracker()
    -- Create frame
    local frame = CreateFrame("Frame", nil, self.displayContainer)
    frame:SetSize(280, 50)
    
    -- Title text
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    title:SetText("DoT/HoT Tracker")
    
    -- Container for dot trackers
    local container = CreateFrame("Frame", nil, frame)
    container:SetSize(280, 40)
    container:SetPoint("TOP", title, "BOTTOM", 0, -5)
    
    -- Get DoTs/HoTs for current class/spec
    local dotSpells = self:GetDotSpells()
    local dotBars = {}
    
    -- Create bars for each DoT
    for i, spell in ipairs(dotSpells) do
        local bar = CreateFrame("StatusBar", nil, container)
        bar:SetSize(280, 18)
        bar:SetPoint("TOP", container, "TOP", 0, -20 * (i-1))
        bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
        bar:SetStatusBarColor(spell.color.r, spell.color.g, spell.color.b, 0.7)
        bar:SetMinMaxValues(0, 1)
        bar:SetValue(0)
        
        -- Background
        local bg = bar:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
        bg:SetVertexColor(spell.color.r * 0.3, spell.color.g * 0.3, spell.color.b * 0.3, 0.5)
        
        -- Border
        bar.border = CreateFrame("Frame", nil, bar, "BackdropTemplate")
        bar.border:SetAllPoints()
        bar.border:SetBackdrop({
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 8,
            insets = { left = 1, right = 1, top = 1, bottom = 1 }
        })
        bar.border:SetBackdropBorderColor(0.7, 0.7, 0.7, 0.7)
        
        -- Spell icon
        local icon = bar:CreateTexture(nil, "OVERLAY")
        icon:SetSize(18, 18)
        icon:SetPoint("RIGHT", bar, "LEFT", -2, 0)
        icon:SetTexture(spell.icon)
        icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
        
        -- Icon border
        local iconBorder = CreateFrame("Frame", nil, bar, "BackdropTemplate")
        iconBorder:SetSize(20, 20)
        iconBorder:SetPoint("CENTER", icon, "CENTER")
        iconBorder:SetBackdrop({
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 8,
            insets = { left = 1, right = 1, top = 1, bottom = 1 }
        })
        iconBorder:SetBackdropBorderColor(0.7, 0.7, 0.7, 0.7)
        
        -- Text for time remaining
        local text = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        text:SetPoint("RIGHT", bar, "RIGHT", -5, 0)
        text:SetText("")
        
        -- Spell name
        local nameText = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        nameText:SetPoint("LEFT", bar, "LEFT", 5, 0)
        nameText:SetText(spell.name)
        
        -- Pandemic indicator (20% window where refreshing is optimal)
        local pandemic = bar:CreateTexture(nil, "OVERLAY")
        pandemic:SetSize(3, 18)
        pandemic:SetPoint("RIGHT", bar, "RIGHT", -56, 0)
        pandemic:SetColorTexture(1, 1, 1, 0.7)
        pandemic:Hide()
        
        -- Store data
        dotBars[spell.id] = {
            bar = bar,
            icon = icon,
            iconBorder = iconBorder,
            text = text,
            nameText = nameText,
            pandemic = pandemic,
            spellData = spell,
            active = false,
            expirationTime = 0,
            duration = 0,
            target = "target", -- Default to target
            stacks = 0
        }
    end
    
    -- Store references
    frame.dotBars = dotBars
    frame.container = container
    
    -- Update function
    frame.Update = function(self)
        for spellId, barData in pairs(self.dotBars) do
            -- Check for aura on target (or player for buffs)
            local unit = barData.spellData.onSelf and "player" or "target"
            
            -- Check if aura is present
            local name, icon, count, _, duration, expirationTime = self:FindAuraById(unit, spellId)
            
            if name and duration and duration > 0 and expirationTime then
                -- Aura is present
                barData.active = true
                barData.expirationTime = expirationTime
                barData.duration = duration
                barData.stacks = count or 1
                
                -- Update bar
                local remaining = expirationTime - GetTime()
                local value = remaining / duration
                barData.bar:SetMinMaxValues(0, 1)
                barData.bar:SetValue(value)
                
                -- Format time text (red when < 3s)
                local timeText
                if remaining < 3 then
                    timeText = "|cFFFF0000" .. FormatTime(remaining) .. "|r"
                else
                    timeText = FormatTime(remaining)
                end
                
                -- Add stacks if present
                if count and count > 1 then
                    timeText = timeText .. " (" .. count .. ")"
                end
                
                barData.text:SetText(timeText)
                
                -- Show/color pandemic window (last 30% of duration)
                local pandemicThreshold = duration * 0.7
                if remaining < duration * 0.3 then
                    barData.pandemic:Show()
                    
                    -- Change bar color for pandemic window
                    if remaining < 3 then
                        -- About to expire
                        barData.bar:SetStatusBarColor(1, 0, 0, 0.7)
                    else
                        -- In pandemic window
                        barData.bar:SetStatusBarColor(
                            barData.spellData.color.r * 1.3, 
                            barData.spellData.color.g * 1.3, 
                            barData.spellData.color.b * 0.7, 
                            0.7
                        )
                    end
                else
                    barData.pandemic:Hide()
                    barData.bar:SetStatusBarColor(
                        barData.spellData.color.r, 
                        barData.spellData.color.g, 
                        barData.spellData.color.b, 
                        0.7
                    )
                end
                
                -- Show the bar
                barData.bar:Show()
            else
                -- Aura not present
                barData.active = false
                barData.bar:SetValue(0)
                barData.text:SetText("Not active")
                barData.pandemic:Hide()
                
                -- Reset color
                barData.bar:SetStatusBarColor(
                    barData.spellData.color.r * 0.5, 
                    barData.spellData.color.g * 0.5, 
                    barData.spellData.color.b * 0.5, 
                    0.5
                )
            end
        end
    end
    
    -- Helper to format time text
    function FormatTime(seconds)
        seconds = math_max(0, seconds)
        if seconds < 10 then
            return string.format("%.1f", seconds)
        elseif seconds < 60 then
            return string.format("%d", seconds)
        else
            local minutes = math_floor(seconds / 60)
            seconds = seconds % 60
            return string.format("%d:%02d", minutes, seconds)
        end
    end
    
    -- Run initial update
    frame:Update()
    
    dotTracker = frame
    table.insert(activeDisplays, frame)
}

-- Create proc display
function ClassSpecificUI:CreateProcDisplay()
    -- Create frame
    local frame = CreateFrame("Frame", nil, self.displayContainer)
    frame:SetSize(280, 60)
    
    -- Title text
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    title:SetText("Proc Tracker")
    
    -- Container for proc displays
    local container = CreateFrame("Frame", nil, frame)
    container:SetSize(280, 50)
    container:SetPoint("TOP", title, "BOTTOM", 0, -5)
    
    -- Get proc spells for current class/spec
    local procSpells = self:GetProcSpells()
    local procIcons = {}
    
    -- Create icons for each proc
    local iconsPerRow = 6
    local iconSize = 40
    local spacing = 5
    
    for i, spell in ipairs(procSpells) do
        local row = math_floor((i-1) / iconsPerRow)
        local col = (i-1) % iconsPerRow
        
        local frame = CreateFrame("Frame", nil, container)
        frame:SetSize(iconSize, iconSize)
        frame:SetPoint("TOPLEFT", container, "TOPLEFT", col * (iconSize + spacing), -row * (iconSize + spacing))
        
        -- Icon
        local icon = frame:CreateTexture(nil, "ARTWORK")
        icon:SetAllPoints()
        icon:SetTexture(spell.icon)
        icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
        icon:SetDesaturated(true)
        icon:SetAlpha(0.3)
        
        -- Border
        local border = CreateFrame("Frame", nil, frame, "BackdropTemplate")
        border:SetAllPoints()
        border:SetBackdrop({
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 8,
            insets = { left = 1, right = 1, top = 1, bottom = 1 }
        })
        border:SetBackdropBorderColor(0.7, 0.7, 0.7, 0.3)
        
        -- Cooldown frame for duration
        local cooldown = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate")
        cooldown:SetAllPoints()
        cooldown:SetDrawEdge(false)
        cooldown:SetHideCountdownNumbers(false)
        cooldown:SetSwipeColor(0, 0, 0, 0.8)
        
        -- Glow effect for active procs
        local glow = frame:CreateTexture(nil, "OVERLAY")
        glow:SetSize(iconSize * 1.5, iconSize * 1.5)
        glow:SetPoint("CENTER", frame, "CENTER")
        glow:SetTexture("Interface\\SpellActivationOverlay\\IconAlert")
        glow:SetTexCoord(0.00781250, 0.50781250, 0.53515625, 0.78515625)
        glow:SetBlendMode("ADD")
        glow:SetAlpha(0)
        
        -- Glow animation
        local glowAnim = glow:CreateAnimationGroup()
        glowAnim:SetLooping("REPEAT")
        
        local fadeIn = glowAnim:CreateAnimation("Alpha")
        fadeIn:SetFromAlpha(0)
        fadeIn:SetToAlpha(1)
        fadeIn:SetDuration(0.5)
        fadeIn:SetOrder(1)
        
        local fadeOut = glowAnim:CreateAnimation("Alpha")
        fadeOut:SetFromAlpha(1)
        fadeOut:SetToAlpha(0)
        fadeOut:SetDuration(0.5)
        fadeOut:SetOrder(2)
        
        -- Tooltip
        frame:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetSpellByID(spell.id)
            GameTooltip:Show()
        end)
        
        frame:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
        end)
        
        -- Store data
        procIcons[spell.id] = {
            frame = frame,
            icon = icon,
            border = border,
            cooldown = cooldown,
            glow = glow,
            glowAnim = glowAnim,
            spellData = spell,
            active = false,
            expirationTime = 0,
            duration = 0,
            stacks = 0
        }
    end
    
    -- Store references
    frame.procIcons = procIcons
    frame.container = container
    
    -- Update function
    frame.Update = function(self)
        for spellId, iconData in pairs(self.procIcons) do
            -- Check for aura on player (procs are always buffs on self)
            local name, icon, count, _, duration, expirationTime = self:FindAuraById("player", spellId)
            
            if name and expirationTime then
                -- Only play activation effect if this is a new proc
                if not iconData.active then
                    iconData.glowAnim:Play()
                    
                    -- Add sound if enabled
                    if displayConfig.audioFeedback then
                        PlaySound(SOUNDKIT.RAID_WARNING)
                    end
                end
                
                -- Proc is active
                iconData.active = true
                iconData.expirationTime = expirationTime
                iconData.duration = duration or 0
                iconData.stacks = count or 1
                
                -- Update visuals
                iconData.icon:SetDesaturated(false)
                iconData.icon:SetAlpha(1)
                
                -- Apply proc-specific color if available
                if iconData.spellData.color then
                    iconData.icon:SetVertexColor(
                        iconData.spellData.color.r,
                        iconData.spellData.color.g,
                        iconData.spellData.color.b,
                        1
                    )
                else
                    iconData.icon:SetVertexColor(1, 1, 1, 1)
                end
                
                -- Update border color
                iconData.border:SetBackdropBorderColor(0.7, 0.7, 0.7, 1)
                
                -- Show cooldown if this buff has a duration
                if duration and duration > 0 then
                    iconData.cooldown:SetCooldown(expirationTime - duration, duration)
                    iconData.cooldown:Show()
                else
                    iconData.cooldown:Hide()
                end
            else
                -- Proc not active
                if iconData.active then
                    iconData.glowAnim:Stop()
                    iconData.glow:SetAlpha(0)
                end
                
                iconData.active = false
                iconData.icon:SetDesaturated(true)
                iconData.icon:SetAlpha(0.3)
                iconData.icon:SetVertexColor(0.5, 0.5, 0.5, 1)
                iconData.border:SetBackdropBorderColor(0.7, 0.7, 0.7, 0.3)
                iconData.cooldown:Hide()
            end
        end
    end
    
    -- Run initial update
    frame:Update()
    
    procDisplay = frame
    table.insert(activeDisplays, frame)
}

-- Create APM (Actions Per Minute) meter
function ClassSpecificUI:CreateAPMMeter()
    -- Create frame
    local frame = CreateFrame("Frame", nil, self.displayContainer)
    frame:SetSize(280, 40)
    
    -- Title text
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    title:SetText("Actions Per Minute")
    
    -- Progress bar
    local bar = CreateFrame("StatusBar", nil, frame)
    bar:SetSize(280, 20)
    bar:SetPoint("TOP", title, "BOTTOM", 0, -5)
    bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    bar:SetStatusBarColor(0.3, 0.7, 0.3, 0.8)
    bar:SetMinMaxValues(0, 60) -- Typical APM range
    bar:SetValue(0)
    
    -- Background
    local bg = bar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
    bg:SetVertexColor(0.1, 0.2, 0.1, 0.5)
    
    -- Border
    bar.border = CreateFrame("Frame", nil, bar, "BackdropTemplate")
    bar.border:SetAllPoints()
    bar.border:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 8,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    bar.border:SetBackdropBorderColor(0.7, 0.7, 0.7, 0.7)
    
    -- Text
    local text = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetPoint("CENTER", bar, "CENTER", 0, 0)
    text:SetText("0 APM")
    
    -- APM tracking variables
    local actionTimes = {}
    local lastUpdateTime = GetTime()
    local currentAPM = 0
    
    -- Store references
    frame.bar = bar
    frame.text = text
    frame.actionTimes = actionTimes
    frame.lastUpdateTime = lastUpdateTime
    frame.currentAPM = currentAPM
    
    -- Record an action
    frame.RecordAction = function(self)
        tinsert(self.actionTimes, GetTime())
        
        -- Remove old actions (older than 60 seconds)
        local cutoffTime = GetTime() - 60
        while self.actionTimes[1] and self.actionTimes[1] < cutoffTime do
            tremove(self.actionTimes, 1)
        end
    end
    
    -- Update function
    frame.Update = function(self)
        local now = GetTime()
        
        -- Only update display every 1 second
        if now - self.lastUpdateTime < 1 then
            return
        end
        
        self.lastUpdateTime = now
        
        -- Remove old actions
        local cutoffTime = now - 60
        while self.actionTimes[1] and self.actionTimes[1] < cutoffTime do
            tremove(self.actionTimes, 1)
        end
        
        -- Calculate current APM
        self.currentAPM = #self.actionTimes
        
        -- Update display
        self.bar:SetValue(self.currentAPM)
        
        -- Color based on class benchmark
        local benchmark = self:GetClassAPMBenchmark()
        local color
        
        if self.currentAPM < benchmark * 0.7 then
            -- Below 70% of benchmark - red
            color = {r = 0.8, g = 0.1, b = 0.1}
        elseif self.currentAPM < benchmark * 0.9 then
            -- 70-90% - yellow
            color = {r = 0.8, g = 0.8, b = 0.1}
        else
            -- 90%+ - green
            color = {r = 0.1, g = 0.8, b = 0.1}
        end
        
        self.bar:SetStatusBarColor(color.r, color.g, color.b, 0.8)
        self.text:SetText(self.currentAPM .. " APM")
    end
    
    -- Get APM benchmark for current class/spec
    frame.GetClassAPMBenchmark = function(self)
        -- This would be expanded with proper benchmarks for each class/spec
        local benchmarks = {
            WARRIOR = 40,
            PALADIN = 35,
            HUNTER = 45,
            ROGUE = 55,
            PRIEST = 30,
            DEATHKNIGHT = 38,
            SHAMAN = 35,
            MAGE = 42,
            WARLOCK = 35,
            MONK = 50,
            DRUID = 40,
            DEMONHUNTER = 45,
            EVOKER = 38
        }
        
        return benchmarks[playerClass] or 40
    end
    
    -- Run initial update
    frame:Update()
    
    apmMeter = frame
    table.insert(activeDisplays, frame)
}

-- Create spell queue display
function ClassSpecificUI:CreateSpellQueueDisplay()
    -- Create frame
    local frame = CreateFrame("Frame", nil, self.displayContainer)
    frame:SetSize(280, 70)
    
    -- Title text
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    title:SetText("Next Abilities")
    
    -- Container for ability icons
    local container = CreateFrame("Frame", nil, frame)
    container:SetSize(280, 50)
    container:SetPoint("TOP", title, "BOTTOM", 0, -5)
    
    -- Create icons for next 3 suggested abilities
    local abilityIcons = {}
    local iconSize = 40
    local spacing = 10
    
    for i = 1, 3 do
        local iconFrame = CreateFrame("Frame", nil, container)
        iconFrame:SetSize(iconSize, iconSize)
        iconFrame:SetPoint("LEFT", container, "LEFT", (i-1) * (iconSize + spacing), 0)
        
        -- Icon
        local icon = iconFrame:CreateTexture(nil, "ARTWORK")
        icon:SetAllPoints()
        icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
        
        -- Border
        local border = CreateFrame("Frame", nil, iconFrame, "BackdropTemplate")
        border:SetAllPoints()
        border:SetBackdrop({
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 8,
            insets = { left = 1, right = 1, top = 1, bottom = 1 }
        })
        border:SetBackdropBorderColor(0.7, 0.7, 0.7, 0.7)
        
        -- Number
        local number = iconFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        number:SetPoint("BOTTOMRIGHT", iconFrame, "BOTTOMRIGHT", -2, 2)
        number:SetText(i)
        
        -- Highlight for current suggested ability
        local highlight = iconFrame:CreateTexture(nil, "OVERLAY")
        highlight:SetAllPoints()
        highlight:SetTexture("Interface\\Buttons\\CheckButtonHilight")
        highlight:SetBlendMode("ADD")
        highlight:SetAlpha(0)
        
        -- Tooltip
        iconFrame:SetScript("OnEnter", function(self)
            if abilityIcons[i].spellId then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetSpellByID(abilityIcons[i].spellId)
                GameTooltip:Show()
            end
        end)
        
        iconFrame:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
        end)
        
        abilityIcons[i] = {
            frame = iconFrame,
            icon = icon,
            border = border,
            number = number,
            highlight = highlight,
            spellId = nil,
            name = "Unknown"
        }
    end
    
    -- Store references
    frame.abilityIcons = abilityIcons
    frame.container = container
    
    -- Update function
    frame.Update = function(self, abilities)
        if not abilities or #abilities == 0 then
            -- Clear icons if no abilities provided
            for i = 1, #self.abilityIcons do
                self.abilityIcons[i].icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
                self.abilityIcons[i].highlight:SetAlpha(0)
                self.abilityIcons[i].spellId = nil
                self.abilityIcons[i].name = "Unknown"
            end
            return
        end
        
        -- Update with provided abilities
        for i = 1, #self.abilityIcons do
            if abilities[i] then
                -- Get icon texture
                local texture = select(3, GetSpellInfo(abilities[i].id))
                
                -- Update icon
                self.abilityIcons[i].icon:SetTexture(texture or "Interface\\Icons\\INV_Misc_QuestionMark")
                self.abilityIcons[i].spellId = abilities[i].id
                self.abilityIcons[i].name = abilities[i].name or "Unknown"
                
                -- Highlight first (current) ability
                if i == 1 then
                    self.abilityIcons[i].highlight:SetAlpha(0.5)
                    
                    -- Apply colored border based on ability type
                    if abilities[i].type == "offensive" then
                        self.abilityIcons[i].border:SetBackdropBorderColor(0.8, 0.1, 0.1, 1)
                    elseif abilities[i].type == "defensive" then
                        self.abilityIcons[i].border:SetBackdropBorderColor(0.1, 0.5, 0.8, 1)
                    elseif abilities[i].type == "movement" then
                        self.abilityIcons[i].border:SetBackdropBorderColor(0.1, 0.8, 0.1, 1)
                    elseif abilities[i].type == "utility" then
                        self.abilityIcons[i].border:SetBackdropBorderColor(0.8, 0.8, 0.1, 1)
                    else
                        self.abilityIcons[i].border:SetBackdropBorderColor(0.7, 0.7, 0.7, 1)
                    end
                else
                    self.abilityIcons[i].highlight:SetAlpha(0)
                    self.abilityIcons[i].border:SetBackdropBorderColor(0.7, 0.7, 0.7, 0.5)
                end
            else
                -- No ability in this slot
                self.abilityIcons[i].icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
                self.abilityIcons[i].highlight:SetAlpha(0)
                self.abilityIcons[i].spellId = nil
                self.abilityIcons[i].name = "Unknown"
                self.abilityIcons[i].border:SetBackdropBorderColor(0.7, 0.7, 0.7, 0.3)
            end
        end
    end
    
    spellQueueDisplay = frame
    table.insert(activeDisplays, frame)
}

-- Create resource forecast
function ClassSpecificUI:CreateResourceForecast()
    -- Create frame
    local frame = CreateFrame("Frame", nil, self.displayContainer)
    frame:SetSize(280, 100)
    
    -- Title text
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    title:SetText("Resource Forecast")
    
    -- Get resource type for current class/spec
    local resourceType, resourceName = self:GetPrimaryResourceType()
    title:SetText(resourceName .. " Forecast")
    
    -- Container for the graph
    local container = CreateFrame("Frame", nil, frame)
    container:SetSize(280, 80)
    container:SetPoint("TOP", title, "BOTTOM", 0, -5)
    
    -- Background grid
    for i = 0, 4 do -- Horizontal lines
        local line = container:CreateTexture(nil, "BACKGROUND")
        line:SetSize(280, 1)
        line:SetPoint("LEFT", container, "BOTTOMLEFT", 0, i * 20)
        line:SetColorTexture(0.3, 0.3, 0.3, 0.3)
    end
    
    for i = 0, 6 do -- Vertical lines (every 1 second)
        local line = container:CreateTexture(nil, "BACKGROUND")
        line:SetSize(1, 80)
        line:SetPoint("BOTTOM", container, "BOTTOMLEFT", i * 40, 0)
        line:SetColorTexture(0.3, 0.3, 0.3, 0.3)
    end
    
    -- Current resource level indicator
    local currentMarker = container:CreateTexture(nil, "ARTWORK")
    currentMarker:SetSize(3, 80)
    currentMarker:SetPoint("BOTTOMLEFT", container, "BOTTOMLEFT", 0, 0)
    currentMarker:SetColorTexture(1, 1, 1, 0.7)
    
    -- Graph elements
    local graphPoints = {}
    local maxPoints = 24 -- Forecast 6 seconds ahead, 4 points per second
    
    -- Create points for the line
    for i = 1, maxPoints do
        local point = container:CreateTexture(nil, "ARTWORK")
        point:SetSize(4, 4)
        point:SetTexture("Interface\\Buttons\\WHITE8x8")
        point:SetTexCoord(0, 1, 0, 1)
        point:SetVertexColor(0.7, 0.7, 0.7, 1)
        point:Hide()
        
        graphPoints[i] = point
    end
    
    -- Lines connecting points
    local graphLines = {}
    for i = 1, maxPoints - 1 do
        local line = container:CreateTexture(nil, "ARTWORK")
        line:SetTexture("Interface\\Buttons\\WHITE8x8")
        line:SetVertexColor(0.7, 0.7, 0.7, 0.7)
        line:Hide()
        
        graphLines[i] = line
    end
    
    -- Ability markers showing when abilities will be used
    local abilityMarkers = {}
    local maxAbilities = a5
    
    for i = 1, maxAbilities do
        local marker = CreateFrame("Frame", nil, container)
        marker:SetSize(20, 20)
        marker:Hide()
        
        -- Icon
        local icon = marker:CreateTexture(nil, "ARTWORK")
        icon:SetAllPoints()
        icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
        
        -- Border
        local border = CreateFrame("Frame", nil, marker, "BackdropTemplate")
        border:SetAllPoints()
        border:SetBackdrop({
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 8,
            insets = { left = 1, right = 1, top = 1, bottom = 1 }
        })
        border:SetBackdropBorderColor(0.7, 0.7, 0.7, 0.7)
        
        -- Store reference
        abilityMarkers[i] = {
            frame = marker,
            icon = icon,
            border = border,
            spellId = nil,
            time = 0,
            resource = 0
        }
        
        -- Tooltip
        marker:SetScript("OnEnter", function(self)
            if abilityMarkers[i].spellId then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetSpellByID(abilityMarkers[i].spellId)
                GameTooltip:AddLine("Resource: " .. abilityMarkers[i].resource)
                GameTooltip:AddLine("Time: +" .. string.format("%.1f", abilityMarkers[i].time) .. "s")
                GameTooltip:Show()
            end
        end)
        
        marker:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
        end)
    end
    
    -- Store data for updates
    frame.currentValue = 0
    frame.maxValue = 100
    frame.resourceType = resourceType
    frame.resourceName = resourceName
    frame.container = container
    frame.currentMarker = currentMarker
    frame.graphPoints = graphPoints
    frame.graphLines = graphLines
    frame.abilityMarkers = abilityMarkers
    frame.predictions = {}
    
    -- Update function
    frame.Update = function(self, predictions, abilities)
        predictions = predictions or {}
        abilities = abilities or {}
        
        -- Get current resource value
        local current = UnitPower("player", self.resourceType)
        local max = UnitPowerMax("player", self.resourceType)
        
        self.currentValue = current
        self.maxValue = max
        
        -- Update graph based on predictions
        local pointCount = #predictions
        
        -- Scale factors
        local timeScale = 280 / 6 -- 6 seconds across 280px
        local valueScale = 80 / max -- Scale resource to fit in 80px height
        
        -- Position current marker
        self.currentMarker:SetHeight(80)
        self.currentMarker:SetPoint("BOTTOMLEFT", self.container, "BOTTOMLEFT", 0, 0)
        
        -- Update or hide points
        for i = 1, #self.graphPoints do
            if i <= pointCount then
                local x = predictions[i].time * timeScale
                local y = predictions[i].value * valueScale
                
                self.graphPoints[i]:ClearAllPoints()
                self.graphPoints[i]:SetPoint("BOTTOMLEFT", self.container, "BOTTOMLEFT", x, y)
                self.graphPoints[i]:Show()
                
                -- Color points based on value relative to current
                if predictions[i].value > current * 1.2 then
                    -- Resource increasing - green
                    self.graphPoints[i]:SetVertexColor(0.1, 0.8, 0.1, 1)
                elseif predictions[i].value < current * 0.8 then
                    -- Resource decreasing - red
                    self.graphPoints[i]:SetVertexColor(0.8, 0.1, 0.1, 1)
                else
                    -- Stable - white
                    self.graphPoints[i]:SetVertexColor(0.7, 0.7, 0.7, 1)
                end
            else
                self.graphPoints[i]:Hide()
            end
        end
        
        -- Update lines
        for i = 1, #self.graphLines do
            if i < pointCount then
                local x1 = predictions[i].time * timeScale
                local y1 = predictions[i].value * valueScale
                local x2 = predictions[i+1].time * timeScale
                local y2 = predictions[i+1].value * valueScale
                
                -- Calculate line position and dimensions
                local length = math.sqrt((x2-x1)^2 + (y2-y1)^2)
                local angle = math.atan2(y2-y1, x2-x1)
                
                self.graphLines[i]:ClearAllPoints()
                self.graphLines[i]:SetPoint("BOTTOMLEFT", self.container, "BOTTOMLEFT", x1, y1)
                self.graphLines[i]:SetSize(length, 2)
                self.graphLines[i]:SetRotation(angle)
                self.graphLines[i]:Show()
                
                -- Color line based on trend
                if predictions[i+1].value > predictions[i].value then
                    -- Increasing - green
                    self.graphLines[i]:SetVertexColor(0.1, 0.8, 0.1, 0.5)
                elseif predictions[i+1].value < predictions[i].value then
                    -- Decreasing - red
                    self.graphLines[i]:SetVertexColor(0.8, 0.1, 0.1, 0.5)
                else
                    -- Stable - white
                    self.graphLines[i]:SetVertexColor(0.7, 0.7, 0.7, 0.5)
                end
            else
                self.graphLines[i]:Hide()
            end
        end
        
        -- Update ability markers
        for i = 1, #self.abilityMarkers do
            if i <= #abilities then
                local ability = abilities[i]
                local x = ability.time * timeScale
                local y = ability.resourceAfter * valueScale
                
                -- Get icon texture
                local texture = select(3, GetSpellInfo(ability.id))
                
                self.abilityMarkers[i].frame:ClearAllPoints()
                self.abilityMarkers[i].frame:SetPoint("CENTER", self.container, "BOTTOMLEFT", x, y)
                self.abilityMarkers[i].icon:SetTexture(texture or "Interface\\Icons\\INV_Misc_QuestionMark")
                self.abilityMarkers[i].frame:Show()
                
                -- Store data for tooltip
                self.abilityMarkers[i].spellId = ability.id
                self.abilityMarkers[i].time = ability.time
                self.abilityMarkers[i].resource = ability.resourceAfter
                
                -- Color border based on resource change
                if ability.resourceAfter > ability.resourceBefore then
                    -- Generates resource - green
                    self.abilityMarkers[i].border:SetBackdropBorderColor(0.1, 0.8, 0.1, 1)
                elseif ability.resourceAfter < ability.resourceBefore then
                    -- Spends resource - red
                    self.abilityMarkers[i].border:SetBackdropBorderColor(0.8, 0.1, 0.1, 1)
                else
                    -- No change - white
                    self.abilityMarkers[i].border:SetBackdropBorderColor(0.7, 0.7, 0.7, 1)
                end
            else
                self.abilityMarkers[i].frame:Hide()
            end
        end
    end
    
    -- Calculate resource predictions
    frame.PredictResources = function(self, abilities)
        -- Reset predictions
        self.predictions = {}
        
        -- Get current resource value and regen rate
        local current = UnitPower("player", self.resourceType)
        local regenRate = 0
        
        -- Add passive regeneration based on resource type
        if self.resourceType == Enum.PowerType.Mana or 
           self.resourceType == Enum.PowerType.Energy then
            -- Calculate regen rate
            regenRate = GetPowerRegenForPowerType(self.resourceType)
        end
        
        -- Start with current value
        tinsert(self.predictions, {time = 0, value = current})
        
        -- If no abilities provided, just predict based on regen
        if not abilities or #abilities == 0 then
            -- Predict resource for the next 6 seconds
            for i = 1, 24 do -- 4 points per second for 6 seconds
                local time = i * 0.25
                local predicted = math_min(self.maxValue, current + regenRate * time)
                tinsert(self.predictions, {time = time, value = predicted})
            end
            return self.predictions
        end
        
        -- Process each ability in the provided sequence
        local timeOffset = 0
        local currentResource = current
        
        for i, ability in ipairs(abilities) do
            if not ability.time then
                -- If ability doesn't specify a time, estimate based on GCD
                ability.time = timeOffset + (i == 1 and 0 or 1.5)
            end
            
            -- Predict passive regen until this ability
            if ability.time > timeOffset then
                local regenAmount = regenRate * (ability.time - timeOffset)
                currentResource = math_min(self.maxValue, currentResource + regenAmount)
            end
            
            -- Store pre-ability resource level
            ability.resourceBefore = currentResource
            
            -- Apply resource change from this ability
            local resourceChange = ability.resourceChange or 0
            currentResource = math_max(0, math_min(self.maxValue, currentResource + resourceChange))
            
            -- Store post-ability resource level
            ability.resourceAfter = currentResource
            
            -- Add to prediction points
            tinsert(self.predictions, {time = ability.time, value = currentResource})
            
            -- Update time offset
            timeOffset = ability.time
        end
        
        -- Fill in the rest of the prediction with passive regen
        local lastTime = timeOffset
        while lastTime < a6 do
            lastTime = lastTime + 0.25
            local predicted = math_min(self.maxValue, currentResource + regenRate * (lastTime - timeOffset))
            tinsert(self.predictions, {time = lastTime, value = predicted})
        end
        
        return self.predictions
    end
    
    resourceForecast = frame
    table.insert(activeDisplays, frame)
}

-- Create cooldown tracker
function ClassSpecificUI:CreateCooldownTracker()
    -- Create frame
    local frame = CreateFrame("Frame", nil, self.displayContainer)
    frame:SetSize(280, 80)
    
    -- Title text
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    title:SetText("Cooldown Tracker")
    
    -- Container for cooldown icons
    local container = CreateFrame("Frame", nil, frame)
    container:SetSize(280, 70)
    container:SetPoint("TOP", title, "BOTTOM", 0, -5)
    
    -- Get important cooldowns for current class/spec
    local cooldownSpells = self:GetImportantCooldowns()
    local cooldownIcons = {}
    
    -- Create icons for each cooldown
    local iconsPerRow = 6
    local iconSize = 36
    local spacing = 5
    
    for i, spell in ipairs(cooldownSpells) do
        local row = math_floor((i-1) / iconsPerRow)
        local col = (i-1) % iconsPerRow
        
        local frame = CreateFrame("Frame", nil, container)
        frame:SetSize(iconSize, iconSize)
        frame:SetPoint("TOPLEFT", container, "TOPLEFT", col * (iconSize + spacing), -row * (iconSize + spacing))
        
        -- Icon
        local icon = frame:CreateTexture(nil, "ARTWORK")
        icon:SetAllPoints()
        icon:SetTexture(spell.icon)
        icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
        
        -- Border
        local border = CreateFrame("Frame", nil, frame, "BackdropTemplate")
        border:SetAllPoints()
        border:SetBackdrop({
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 8,
            insets = { left = 1, right = 1, top = 1, bottom = 1 }
        })
        
        -- Border color based on cooldown type
        if spell.type == "offensive" then
            border:SetBackdropBorderColor(0.8, 0.1, 0.1, 0.7)
        elseif spell.type == "defensive" then
            border:SetBackdropBorderColor(0.1, 0.5, 0.8, 0.7)
        elseif spell.type == "utility" then
            border:SetBackdropBorderColor(0.8, 0.8, 0.1, 0.7)
        else
            border:SetBackdropBorderColor(0.7, 0.7, 0.7, 0.7)
        end
        
        -- Cooldown overlay
        local cooldown = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate")
        cooldown:SetAllPoints()
        cooldown:SetDrawEdge(false)
        cooldown:SetHideCountdownNumbers(false)
        cooldown:SetSwipeColor(0, 0, 0, 0.8)
        
        -- Unavailable overlay (e.g. wrong spec or talent)
        local unavailableTexture = frame:CreateTexture(nil, "OVERLAY")
        unavailableTexture:SetAllPoints()
        unavailableTexture:SetColorTexture(0, 0, 0, 0.7)
        unavailableTexture:Hide()
        
        local unavailableIcon = frame:CreateTexture(nil, "OVERLAY")
        unavailableIcon:SetSize(iconSize * 0.6, iconSize * 0.6)
        unavailableIcon:SetPoint("CENTER", frame, "CENTER")
        unavailableIcon:SetTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
        unavailableIcon:Hide()
        
        -- Tooltip
        frame:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetSpellByID(spell.id)
            GameTooltip:Show()
        end)
        
        frame:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
        end)
        
        -- Store data
        cooldownIcons[spell.id] = {
            frame = frame,
            icon = icon,
            border = border,
            cooldown = cooldown,
            unavailableTexture = unavailableTexture,
            unavailableIcon = unavailableIcon,
            spellData = spell,
            isAvailable = true,
            startTime = 0,
            duration = 0
        }
    end
    
    -- Store references
    frame.cooldownIcons = cooldownIcons
    frame.container = container
    
    -- Update function
    frame.Update = function(self)
        for spellId, iconData in pairs(self.cooldownIcons) do
            -- Check if spell is available (e.g. right spec, has talent)
            local isAvailable = IsSpellKnown(spellId)
            
            if isAvailable ~= iconData.isAvailable then
                iconData.isAvailable = isAvailable
                
                if isAvailable then
                    iconData.unavailableTexture:Hide()
                    iconData.unavailableIcon:Hide()
                    iconData.icon:SetDesaturated(false)
                else
                    iconData.unavailableTexture:Show()
                    iconData.unavailableIcon:Show()
                    iconData.icon:SetDesaturated(true)
                end
            end
            
            -- Only update cooldown for available spells
            if isAvailable then
                local start, duration, enabled = GetSpellCooldown(spellId)
                
                if start and duration then
                    if start > 0 and duration > 0 then
                        iconData.cooldown:SetCooldown(start, duration)
                        iconData.startTime = start
                        iconData.duration = duration
                        iconData.icon:SetDesaturated(true)
                        iconData.icon:SetAlpha(0.7)
                    else
                        iconData.cooldown:Clear()
                        iconData.icon:SetDesaturated(false)
                        iconData.icon:SetAlpha(1)
                    end
                end
            end
        end
    end
    
    cooldownTracker = frame
    table.insert(activeDisplays, frame)
}

-- Layout all active displays
function ClassSpecificUI:LayoutDisplays()
    -- Position displays vertically
    local yOffset = 0
    
    for i, display in ipairs(activeDisplays) do
        display:ClearAllPoints()
        display:SetPoint("TOP", self.displayContainer, "TOP", 0, -yOffset)
        yOffset = yOffset + display:GetHeight() + 10
    end
    
    -- Resize main frame to fit all displays
    self.mainFrame:SetHeight(math.max(100, yOffset + 30))
}

-- Get resource types for current class/spec
function ClassSpecificUI:GetResourceTypes()
    local primaryType, secondaryType
    
    -- Primary resource type
    if playerClass == "WARRIOR" then
        primaryType = Enum.PowerType.Rage
    elseif playerClass == "PALADIN" then
        primaryType = Enum.PowerType.Mana
        secondaryType = Enum.PowerType.HolyPower
    elseif playerClass == "HUNTER" then
        primaryType = Enum.PowerType.Focus
    elseif playerClass == "ROGUE" then
        primaryType = Enum.PowerType.Energy
        secondaryType = Enum.PowerType.ComboPoints
    elseif playerClass == "PRIEST" then
        primaryType = Enum.PowerType.Mana
    elseif playerClass == "DEATHKNIGHT" then
        primaryType = Enum.PowerType.RunicPower
    elseif playerClass == "SHAMAN" then
        primaryType = Enum.PowerType.Mana
    elseif playerClass == "MAGE" then
        primaryType = Enum.PowerType.Mana
    elseif playerClass == "WARLOCK" then
        primaryType = Enum.PowerType.Mana
        secondaryType = Enum.PowerType.SoulShards
    elseif playerClass == "MONK" then
        if playerSpec == 3 then -- Windwalker
            primaryType = Enum.PowerType.Energy
            secondaryType = Enum.PowerType.Chi
        else
            primaryType = Enum.PowerType.Mana
        end
    elseif playerClass == "DRUID" then
        if playerSpec == 2 then -- Feral
            primaryType = Enum.PowerType.Energy
            secondaryType = Enum.PowerType.ComboPoints
        elseif playerSpec == 3 then -- Guardian
            primaryType = Enum.PowerType.Rage
        else
            primaryType = Enum.PowerType.Mana
        end
    elseif playerClass == "DEMONHUNTER" then
        primaryType = Enum.PowerType.Fury
    elseif playerClass == "EVOKER" then
        primaryType = Enum.PowerType.Mana
    end
    
    return primaryType, secondaryType
}

-- Get primary resource type name
function ClassSpecificUI:GetPrimaryResourceType()
    local resourceType, resourceName
    
    if playerClass == "WARRIOR" then
        resourceType = Enum.PowerType.Rage
        resourceName = "Rage"
    elseif playerClass == "PALADIN" then
        resourceType = Enum.PowerType.Mana
        resourceName = "Mana"
    elseif playerClass == "HUNTER" then
        resourceType = Enum.PowerType.Focus
        resourceName = "Focus"
    elseif playerClass == "ROGUE" then
        resourceType = Enum.PowerType.Energy
        resourceName = "Energy"
    elseif playerClass == "PRIEST" then
        resourceType = Enum.PowerType.Mana
        resourceName = "Mana"
    elseif playerClass == "DEATHKNIGHT" then
        resourceType = Enum.PowerType.RunicPower
        resourceName = "Runic Power"
    elseif playerClass == "SHAMAN" then
        resourceType = Enum.PowerType.Mana
        resourceName = "Mana"
    elseif playerClass == "MAGE" then
        resourceType = Enum.PowerType.Mana
        resourceName = "Mana"
    elseif playerClass == "WARLOCK" then
        resourceType = Enum.PowerType.Mana
        resourceName = "Mana"
    elseif playerClass == "MONK" then
        if playerSpec == 3 then -- Windwalker
            resourceType = Enum.PowerType.Energy
            resourceName = "Energy"
        else
            resourceType = Enum.PowerType.Mana
            resourceName = "Mana"
        end
    elseif playerClass == "DRUID" then
        if playerSpec == 2 then -- Feral
            resourceType = Enum.PowerType.Energy
            resourceName = "Energy"
        elseif playerSpec == 3 then -- Guardian
            resourceType = Enum.PowerType.Rage
            resourceName = "Rage"
        else
            resourceType = Enum.PowerType.Mana
            resourceName = "Mana"
        end
    elseif playerClass == "DEMONHUNTER" then
        resourceType = Enum.PowerType.Fury
        resourceName = "Fury"
    elseif playerClass == "EVOKER" then
        resourceType = Enum.PowerType.Mana
        resourceName = "Mana"
    end
    
    return resourceType, resourceName
}

-- Check if current class/spec uses DoTs/HoTs
function ClassSpecificUI:ClassUsesDots()
    if playerClass == "WARLOCK" then
        return true -- All warlock specs use DoTs
    elseif playerClass == "PRIEST" and (playerSpec == 3 or playerSpec == 1) then
        return true -- Shadow and Discipline priests use DoTs
    elseif playerClass == "DRUID" then
        return true -- All druid specs have some form of DoT/HoT
    elseif playerClass == "ROGUE" and playerSpec == 1 then
        return true -- Assassination rogues use DoTs
    elseif playerClass == "SHAMAN" and playerSpec == 2 then
        return true -- Enhancement shamans have flame shock
    elseif playerClass == "MAGE" and playerSpec == 2 then
        return true -- Fire mages have living bomb, ignite
    elseif playerClass == "HUNTER" and (playerSpec == 1 or playerSpec == 3) then
        return true -- Marksmanship and Survival hunters have some DoTs
    elseif playerClass == "DEATHKNIGHT" then
        return true -- All death knight specs use diseases
    elseif playerClass == "MONK" and playerSpec == 2 then
        return true -- Mistweaver monks use HoTs
    else
        return false
    end
end

-- Get DoT/HoT spells for current class/spec
function ClassSpecificUI:GetDotSpells()
    local dots = {}
    
    if playerClass == "WARLOCK" then
        if playerSpec == 1 then -- Affliction
            table.insert(dots, {id = 980, name = "Agony", icon = select(3, GetSpellInfo(980)), onSelf = false, color = {r = 0.7, g = 0.3, b = 0.7}})
            table.insert(dots, {id = 316099, name = "Unstable Affliction", icon = select(3, GetSpellInfo(316099)), onSelf = false, color = {r = 0.5, g = 0.0, b = 0.7}})
            table.insert(dots, {id = 27243, name = "Corruption", icon = select(3, GetSpellInfo(27243)), onSelf = false, color = {r = 0.3, g = 0.3, b = 0.7}})
        elseif playerSpec == 2 then -- Demonology
            table.insert(dots, {id = 603, name = "Doom", icon = select(3, GetSpellInfo(603)), onSelf = false, color = {r = 0.7, g = 0.0, b = 0.0}})
        elseif playerSpec == 3 then -- Destruction
            table.insert(dots, {id = 348, name = "Immolate", icon = select(3, GetSpellInfo(348)), onSelf = false, color = {r = 0.9, g = 0.5, b = 0.0}})
        end
    elseif playerClass == "PRIEST" then
        if playerSpec == 3 then -- Shadow
            table.insert(dots, {id = 589, name = "Shadow Word: Pain", icon = select(3, GetSpellInfo(589)), onSelf = false, color = {r = 0.7, g = 0.0, b = 0.7}})
            table.insert(dots, {id = 34914, name = "Vampiric Touch", icon = select(3, GetSpellInfo(34914)), onSelf = false, color = {r = 0.4, g = 0.0, b = 0.8}})
        end
    elseif playerClass == "DRUID" then
        if playerSpec == 1 then -- Balance
            table.insert(dots, {id = 164812, name = "Moonfire", icon = select(3, GetSpellInfo(164812)), onSelf = false, color = {r = 0.3, g = 0.3, b = 1.0}})
            table.insert(dots, {id = 164815, name = "Sunfire", icon = select(3, GetSpellInfo(164815)), onSelf = false, color = {r = 1.0, g = 0.8, b = 0.0}})
        elseif playerSpec == 2 then -- Feral
            table.insert(dots, {id = 155625, name = "Moonfire", icon = select(3, GetSpellInfo(155625)), onSelf = false, color = {r = 0.3, g = 0.3, b = 1.0}})
            table.insert(dots, {id = 1079, name = "Rip", icon = select(3, GetSpellInfo(1079)), onSelf = false, color = {r = 1.0, g = 0.0, b = 0.0}})
            table.insert(dots, {id = 1822, name = "Rake", icon = select(3, GetSpellInfo(1822)), onSelf = false, color = {r = 0.8, g = 0.3, b = 0.0}})
        elseif playerSpec == 4 then -- Restoration
            table.insert(dots, {id = 8936, name = "Regrowth", icon = select(3, GetSpellInfo(8936)), onSelf = false, color = {r = 0.0, g = 0.8, b = 0.0}})
            table.insert(dots, {id = 774, name = "Rejuvenation", icon = select(3, GetSpellInfo(774)), onSelf = false, color = {r = 0.0, g = 0.5, b = 0.2}})
            table.insert(dots, {id = 155777, name = "Germination", icon = select(3, GetSpellInfo(155777)), onSelf = false, color = {r = 0.0, g = 0.7, b = 0.4}})
        end
    end
    
    -- This would be expanded with a complete list of DoTs for all classes
    
    return dots
end

-- Get proc spells for current class/spec
function ClassSpecificUI:GetProcSpells()
    local procs = {}
    
    if playerClass == "WARRIOR" then
        if playerSpec == 1 then -- Arms
            table.insert(procs, {id = 32216, name = "Victory Rush", icon = select(3, GetSpellInfo(32216))})
            table.insert(procs, {id = 7384, name = "Overpower", icon = select(3, GetSpellInfo(7384))})
        elseif playerSpec == 2 then -- Fury
            table.insert(procs, {id = 32216, name = "Victory Rush", icon = select(3, GetSpellInfo(32216))})
            table.insert(procs, {id = 46917, name = "Titanstrike", icon = select(3, GetSpellInfo(46917))})
        end
    elseif playerClass == "PALADIN" then
        if playerSpec == 3 then -- Retribution
            table.insert(procs, {id = 203538, name = "Greater Blessing of Kings", icon = select(3, GetSpellInfo(203538))})
            table.insert(procs, {id = 203539, name = "Greater Blessing of Wisdom", icon = select(3, GetSpellInfo(203539))})
        end
    end
    
    -- This would be expanded with a complete list of procs for all classes
    
    return procs
}

-- Get important cooldowns for current class/spec
function ClassSpecificUI:GetImportantCooldowns()
    local cooldowns = {}
    
    if playerClass == "WARRIOR" then
        table.insert(cooldowns, {id = 1719, name = "Recklessness", icon = select(3, GetSpellInfo(1719)), type = "offensive"})
        table.insert(cooldowns, {id = 871, name = "Shield Wall", icon = select(3, GetSpellInfo(871)), type = "defensive"})
        table.insert(cooldowns, {id = 12975, name = "Last Stand", icon = select(3, GetSpellInfo(12975)), type = "defensive"})
        table.insert(cooldowns, {id = 107574, name = "Avatar", icon = select(3, GetSpellInfo(107574)), type = "offensive"})
    elseif playerClass == "PALADIN" then
        table.insert(cooldowns, {id = 31884, name = "Avenging Wrath", icon = select(3, GetSpellInfo(31884)), type = "offensive"})
        table.insert(cooldowns, {id = 642, name = "Divine Shield", icon = select(3, GetSpellInfo(642)), type = "defensive"})
        table.insert(cooldowns, {id = 633, name = "Lay on Hands", icon = select(3, GetSpellInfo(633)), type = "defensive"})
    elseif playerClass == "HUNTER" then
        table.insert(cooldowns, {id = 19574, name = "Bestial Wrath", icon = select(3, GetSpellInfo(19574)), type = "offensive"})
        table.insert(cooldowns, {id = 186265, name = "Aspect of the Turtle", icon = select(3, GetSpellInfo(186265)), type = "defensive"})
        table.insert(cooldowns, {id = 34477, name = "Misdirection", icon = select(3, GetSpellInfo(34477)), type = "utility"})
    end
    
    -- This would be expanded with a complete list of important cooldowns for all classes
    
    return cooldowns
}

-- Find an aura by spell ID
function ClassSpecificUI:FindAuraById(unit, spellId)
    -- Check buffs
    local i = 1
    while true do
        local name, icon, count, debuffType, duration, expirationTime, source, isStealable, 
              nameplateShowPersonal, id = UnitBuff(unit, i)
        
        if not name then break end
        
        if id == spellId then
            return name, icon, count, debuffType, duration, expirationTime, source, isStealable, 
                   nameplateShowPersonal, id
        end
        
        i = i + 1
    end
    
    -- Check debuffs
    i = 1
    while true do
        local name, icon, count, debuffType, duration, expirationTime, source, isStealable, 
              nameplateShowPersonal, id = UnitDebuff(unit, i)
        
        if not name then break end
        
        if id == spellId then
            return name, icon, count, debuffType, duration, expirationTime, source, isStealable, 
                   nameplateShowPersonal, id
        end
        
        i = i + 1
    end
    
    return nil
end

-- Process a player spell cast for APM tracking
function ClassSpecificUI:ProcessPlayerCast(spellID)
    -- Record action for APM meter
    if apmMeter then
        apmMeter:RecordAction()
    end
}

-- Update resource displays
function ClassSpecificUI:UpdateResourceDisplays()
    if classDisplays.resource then
        classDisplays.resource:Update()
    end
}

-- Update aura displays
function ClassSpecificUI:UpdateAuraDisplays()
    if dotTracker then
        dotTracker:Update()
    end
    
    if procDisplay then
        procDisplay:Update()
    end
}

-- Update target aura displays
function ClassSpecificUI:UpdateTargetAuraDisplays()
    if dotTracker then
        dotTracker:Update()
    end
}

-- Update cooldown display
function ClassSpecificUI:UpdateCooldownDisplay()
    if cooldownTracker then
        cooldownTracker:Update()
    end
}

-- Set up regular updates
function ClassSpecificUI:SetupUpdates()
    -- Create update timer
    local lastUpdate = 0
    local updateInterval = 0.1 -- Update up to 10 times per second
    
    self.mainFrame:SetScript("OnUpdate", function(self, elapsed)
        lastUpdate = lastUpdate + elapsed
        
        if lastUpdate >= updateInterval then
            -- Update all displays that need frequent updates
            ClassSpecificUI:UpdateFrame()
            lastUpdate = 0
        end
    end)
}

-- Update frame with latest data
function ClassSpecificUI:UpdateFrame()
    -- Skip updates if frame is hidden
    if not self.mainFrame:IsVisible() then
        return
    end
    
    -- Update resource display
    if classDisplays.resource then
        classDisplays.resource:Update()
    end
    
    -- Update DoT/HoT tracker
    if dotTracker then
        dotTracker:Update()
    end
    
    -- Update proc display
    if procDisplay then
        procDisplay:Update()
    end
    
    -- Update APM meter
    if apmMeter then
        apmMeter:Update()
    end
    
    -- Update spell queue
    if spellQueueDisplay and WR.Rotation then
        local abilities = WR.Rotation:GetUpcomingAbilities(3)
        spellQueueDisplay:Update(abilities)
    end
    
    -- Update resource forecast
    if resourceForecast and WR.Rotation then
        local abilities = WR.Rotation:GetUpcomingAbilities(5)
        local predictions = resourceForecast:PredictResources(abilities)
        resourceForecast:Update(predictions, abilities)
    end
    
    -- Update cooldown tracker
    if cooldownTracker then
        cooldownTracker:Update()
    end
}

-- Refresh all displays (e.g. when spec changes)
function ClassSpecificUI:RefreshDisplays()
    -- Clear existing displays
    for _, display in pairs(activeDisplays) do
        display:Hide()
    end
    activeDisplays = {}
    
    -- Recreate class displays
    self:CreateClassDisplays()
    
    -- Update border color to match class
    if displayConfig.colorizeByClass and classColors[playerClass] then
        local color = classColors[playerClass]
        self.mainFrame:SetBackdropBorderColor(color.r, color.g, color.b, 1)
    else
        self.mainFrame:SetBackdropBorderColor(0.8, 0.8, 0.8, 0.8)
    end
    
    -- Update title
    local title = self.mainFrame:GetChildren()[1]
    if title and title:IsObjectType("FontString") then
        local _, englishClass = UnitClass("player")
        
        if playerSpec then
            local specName = select(2, GetSpecializationInfo(playerSpec))
            if specName then
                title:SetText(specName .. " " .. englishClass)
            else
                title:SetText(englishClass)
            end
        else
            title:SetText(englishClass)
        end
    end
}

-- Toggle display visibility
function ClassSpecificUI:Toggle()
    if self.mainFrame:IsVisible() then
        self.mainFrame:Hide()
        displayConfig.enabled = false
    else
        self.mainFrame:Show()
        displayConfig.enabled = true
    end
    
    self:SaveConfig()
end

-- Set display scale
function ClassSpecificUI:SetScale(scale)
    scale = math_min(2.0, math_max(0.5, scale))
    
    self.mainFrame:SetScale(scale)
    displayConfig.scale = scale
    
    self:SaveConfig()
end

-- Set display opacity
function ClassSpecificUI:SetAlpha(alpha)
    alpha = math_min(1.0, math_max(0.1, alpha))
    
    self.mainFrame:SetAlpha(alpha)
    displayConfig.alpha = alpha
    
    self:SaveConfig()
}

-- Lock/unlock frame for moving
function ClassSpecificUI:SetLocked(locked)
    displayConfig.locked = locked
    
    -- Enable/disable mouse and dragging
    self.mainFrame:EnableMouse(not locked)
    
    self:SaveConfig()
}

-- Set display features enabled/disabled
function ClassSpecificUI:SetFeatureEnabled(feature, enabled)
    if displayConfig[feature] ~= nil then
        displayConfig[feature] = enabled
        self:SaveConfig()
        self:RefreshDisplays()
    end
}

-- Handle slash command
function ClassSpecificUI:HandleCommand(msg)
    if not msg or msg == "" then
        self:Toggle()
        return
    end
    
    local command, param = msg:match("^(%S+)%s*(.*)$")
    command = command:lower()
    
    if command == "scale" then
        local scale = tonumber(param)
        if scale then
            self:SetScale(scale)
            WR:Print("Class UI scale set to " .. scale)
        else
            WR:Print("Current scale: " .. displayConfig.scale)
            WR:Print("Usage: /wr classui scale <0.5-2.0>")
        end
    elseif command == "alpha" then
        local alpha = tonumber(param)
        if alpha then
            self:SetAlpha(alpha)
            WR:Print("Class UI opacity set to " .. alpha)
        else
            WR:Print("Current opacity: " .. displayConfig.alpha)
            WR:Print("Usage: /wr classui alpha <0.1-1.0>")
        end
    elseif command == "lock" then
        self:SetLocked(true)
        WR:Print("Class UI locked")
    elseif command == "unlock" then
        self:SetLocked(false)
        WR:Print("Class UI unlocked")
    elseif command == "reset" then
        -- Reset position
        displayConfig.position = {x = 0, y = -200}
        self.mainFrame:ClearAllPoints()
        self.mainFrame:SetPoint("CENTER", UIParent, "CENTER", displayConfig.position.x, displayConfig.position.y)
        WR:Print("Class UI position reset")
        self:SaveConfig()
    elseif command == "feature" then
        local feature, value = param:match("^(%S+)%s+(%S+)$")
        if feature and value and displayConfig[feature] ~= nil then
            local enabled = (value == "on" or value == "true" or value == "1")
            self:SetFeatureEnabled(feature, enabled)
            WR:Print("Class UI feature " .. feature .. " " .. (enabled and "enabled" or "disabled"))
        else
            WR:Print("Available features:")
            for feature, value in pairs(displayConfig) do
                if type(value) == "boolean" then
                    WR:Print("  " .. feature .. ": " .. (value and "on" or "off"))
                end
            end
            WR:Print("Usage: /wr classui feature <name> <on|off>")
        end
    else
        WR:Print("Class UI Commands:")
        WR:Print("  /wr classui - Toggle visibility")
        WR:Print("  /wr classui scale <0.5-2.0> - Set scale")
        WR:Print("  /wr classui alpha <0.1-1.0> - Set opacity")
        WR:Print("  /wr classui lock - Lock position")
        WR:Print("  /wr classui unlock - Unlock position")
        WR:Print("  /wr classui reset - Reset position")
        WR:Print("  /wr classui feature <name> <on|off> - Toggle features")
    end
}

-- Register with the main addon
function ClassSpecificUI:RegisterWithAddon()
    -- Add slash command handler
    if WR.RegisterSlashCommand then
        WR.RegisterSlashCommand("classui", function(msg) ClassSpecificUI:HandleCommand(msg) end)
    end
    
    -- Add command to settings UI if it exists
    if WR.UI and WR.UI.AddSettingsTab then
        WR.UI.AddSettingsTab("Class UI", function(container)
            -- Create settings UI elements
            self:CreateSettingsUI(container)
        end)
    end
}

-- Create settings UI
function ClassSpecificUI:CreateSettingsUI(container)
    -- This would create settings UI controls
    -- Simplified for demonstration
}

-- Helper function for development
function ClassSpecificUI:Debug(msg)
    if WR.debugMode then
        WR:Debug("ClassUI: " .. tostring(msg))
    end
}

-- Initialize module
ClassSpecificUI:Initialize()

return ClassSpecificUI